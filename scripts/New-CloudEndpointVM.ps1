param(
    [Parameter(Mandatory = $false)]
    [string]$SubscriptionName = "Azure subscription 1",

    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName = "rg-p2-infra-endpoint-westus2",

    [Parameter(Mandatory = $false)]
    [string]$Region = "westus2",

    [Parameter(Mandatory = $false)]
    [string]$VmNamePrefix = "vm-p2-winclient",

    [Parameter(Mandatory = $false)]
    [string]$VmSize = "Standard_B2s_v2",

    [Parameter(Mandatory = $false)]
    [string]$VirtualNetworkName = "vnet-p2-core",

    [Parameter(Mandatory = $false)]
    [string]$SubnetName = "snet-endpoint",

    [Parameter(Mandatory = $false)]
    [string]$NsgName = "nsg-p2-endpoint",

    [Parameter(Mandatory = $false)]
    [string]$AdminUsername = "labadmin",

    [Parameter(Mandatory = $true)]
    [securestring]$AdminPassword,

    [Parameter(Mandatory = $false)]
    [string]$ImagePublisher = "MicrosoftWindowsDesktop",

    [Parameter(Mandatory = $false)]
    [string]$ImageOffer = "windows-11",

    [Parameter(Mandatory = $false)]
    [string]$ImageSku = "win11-25h2-pro",

    [Parameter(Mandatory = $false)]
    [string]$ImageVersion = "latest",

    [Parameter(Mandatory = $false)]
    [string]$ShutdownTime = "2300",

    [Parameter(Mandatory = $false)]
    [string]$TimeZone = "Eastern Standard Time",

    [Parameter(Mandatory = $false)]
    [string]$ProjectTag = "Project2",

    [Parameter(Mandatory = $false)]
    [string]$EnvironmentTag = "ProductionPilot"
)

$ErrorActionPreference = "Stop"

function Get-NextVmName {
    param(
        [string]$ResourceGroupName,
        [string]$VmNamePrefix
    )

    $existingVms = Get-AzVM -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like "$VmNamePrefix*" }

    if (-not $existingVms) {
        return ($VmNamePrefix + "01")
    }

    $maxNumber = 0
    foreach ($vm in $existingVms) {
        $result = [regex]::Match($vm.Name, "^$([regex]::Escape($VmNamePrefix))(\d+)$")
        if ($result.Success) {
            $num = [int]::Parse($result.Groups[1].Value)
            if ($num -gt $maxNumber) {
                $maxNumber = $num
            }
        }
    }

    if ($maxNumber -eq 0) {
        return ($VmNamePrefix + "01")
    }

    $nextNumber = $maxNumber + 1
    $paddedNumber = $nextNumber.ToString().PadLeft(2, '0')
    return ($VmNamePrefix + $paddedNumber)
}

try {
    Write-Host "Checking Azure login context..." -ForegroundColor Cyan
    $context = Get-AzContext -ErrorAction SilentlyContinue
    if (-not $context) {
        Connect-AzAccount -TenantId "baa870a4-7f68-4b55-876e-af7080f2c56f" | Out-Null
    }

    Write-Host "Selecting subscription: $SubscriptionName" -ForegroundColor Cyan
    Set-AzContext -Subscription $SubscriptionName | Out-Null

    Write-Host "Validating resource group..." -ForegroundColor Cyan
    $null = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction Stop

    Write-Host "Validating virtual network..." -ForegroundColor Cyan
    $vnet = Get-AzVirtualNetwork -Name $VirtualNetworkName -ResourceGroupName $ResourceGroupName -ErrorAction Stop

    $subnet = $vnet.Subnets | Where-Object { $_.Name -eq $SubnetName }
    if (-not $subnet) {
        throw "Subnet '$SubnetName' was not found in virtual network '$VirtualNetworkName'."
    }

    Write-Host "Validating network security group..." -ForegroundColor Cyan
    $null = Get-AzNetworkSecurityGroup -Name $NsgName -ResourceGroupName $ResourceGroupName -ErrorAction Stop

    Write-Host "Determining next available VM name..." -ForegroundColor Cyan
    $VmName = Get-NextVmName -ResourceGroupName $ResourceGroupName -VmNamePrefix $VmNamePrefix
    $PublicIpName = $VmName + "-ip"
    $NicName = $VmName + "-nic"

    Write-Host "Next VM name selected: $VmName" -ForegroundColor Green

    Write-Host "Creating public IP..." -ForegroundColor Cyan
    $publicIp = New-AzPublicIpAddress `
        -Name $PublicIpName `
        -ResourceGroupName $ResourceGroupName `
        -Location $Region `
        -AllocationMethod Static `
        -Sku Standard `
        -Tag @{ Project = $ProjectTag; Environment = $EnvironmentTag }

    Write-Host "Creating network interface..." -ForegroundColor Cyan
    $nic = New-AzNetworkInterface `
        -Name $NicName `
        -ResourceGroupName $ResourceGroupName `
        -Location $Region `
        -SubnetId $subnet.Id `
        -PublicIpAddressId $publicIp.Id `
        -Tag @{ Project = $ProjectTag; Environment = $EnvironmentTag }

    Write-Host "Building VM configuration..." -ForegroundColor Cyan
    $cred = New-Object System.Management.Automation.PSCredential($AdminUsername, $AdminPassword)

    $computerName = "winclient" + $VmName.Substring($VmName.Length - 2)
$vmConfig = New-AzVMConfig -VMName $VmName -VMSize $VmSize
$vmConfig = Set-AzVMOperatingSystem `
    -VM $vmConfig `
    -Windows `
    -ComputerName $computerName `
    -Credential $cred `
    -ProvisionVMAgent `
    -EnableAutoUpdate
    $vmConfig = Set-AzVMSourceImage `
        -VM $vmConfig `
        -PublisherName $ImagePublisher `
        -Offer $ImageOffer `
        -Skus $ImageSku `
        -Version $ImageVersion
    $vmConfig = Add-AzVMNetworkInterface -VM $vmConfig -Id $nic.Id
    $vmConfig = Set-AzVMBootDiagnostic -VM $vmConfig -Enable

    Write-Host "Creating VM '$VmName'... (this takes a few minutes)" -ForegroundColor Cyan
    New-AzVM `
        -ResourceGroupName $ResourceGroupName `
        -Location $Region `
        -VM $vmConfig `
        -Tag @{ Project = $ProjectTag; Environment = $EnvironmentTag } | Out-Null

    Write-Host "Configuring auto-shutdown..." -ForegroundColor Cyan
    $subscriptionId = (Get-AzContext).Subscription.Id
    $shutdownResourceId = "/subscriptions/$subscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.DevTestLab/schedules/shutdown-computevm-$VmName"
    $shutdownProperties = @{
        status          = "Enabled"
        taskType        = "ComputeVmShutdownTask"
        dailyRecurrence = @{ time = $ShutdownTime }
        timeZoneId      = $TimeZone
        targetResourceId = "/subscriptions/$subscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Compute/virtualMachines/$VmName"
    }
    New-AzResource -ResourceId $shutdownResourceId -Location $Region -Properties $shutdownProperties -Force | Out-Null

    Start-Sleep -Seconds 10

    $publicIpRefresh = Get-AzPublicIpAddress -Name $PublicIpName -ResourceGroupName $ResourceGroupName
    $nicRefresh = Get-AzNetworkInterface -Name $NicName -ResourceGroupName $ResourceGroupName
    $privateIp = $nicRefresh.IpConfigurations[0].PrivateIpAddress

    Write-Host ""
    Write-Host "Cloud endpoint VM created successfully." -ForegroundColor Green
    Write-Host "------------------------------------------------------------"
    Write-Host "VM Name:        $VmName"
    Write-Host "Resource Group: $ResourceGroupName"
    Write-Host "Region:         $Region"
    Write-Host "VM Size:        $VmSize"
    Write-Host "Public IP:      $($publicIpRefresh.IpAddress)"
    Write-Host "Private IP:     $privateIp"
    Write-Host "Admin Username: $AdminUsername"
    Write-Host "vNet:           $VirtualNetworkName"
    Write-Host "Subnet:         $SubnetName"
    Write-Host "NSG:            $NsgName"
    Write-Host "Auto-shutdown:  Enabled at $ShutdownTime ($TimeZone)"
    Write-Host "------------------------------------------------------------"
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Confirm NSG allows RDP only from the current approved admin public IP."
    Write-Host "2. RDP to the VM and complete initial Windows validation."
    Write-Host "3. Join the VM to Microsoft Entra ID using the approved internal admin account."
    Write-Host "4. Enroll the device into Microsoft Intune."
    Write-Host "5. Associate the device with the intended standard user after validation."
    Write-Host "6. Confirm compliance baseline and update ring are applied successfully."
    Write-Host "7. Record the endpoint as production-ready."
}
catch {
    Write-Error "Script failed: $($_.Exception.Message)"
    throw
}