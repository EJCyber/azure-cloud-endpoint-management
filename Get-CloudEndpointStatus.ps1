param(
    [Parameter(Mandatory = $false)]
    [string]$DeviceName = "vm-p2-winclient",

    [Parameter(Mandatory = $false)]
    [string]$ExportPath = ""
)

$ErrorActionPreference = "Stop"

Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All","Device.Read.All" -TenantId "baa870a4-7f68-4b55-876e-af7080f2c56f" -ContextScope Process | Out-Null

Write-Host "Retrieving managed devices from Intune..." -ForegroundColor Cyan
$devices = Get-MgDeviceManagementManagedDevice -All

$targetDevices = $devices | Where-Object { $_.DeviceName -like "*$DeviceName*" }

if (-not $targetDevices) {
    Write-Warning "No managed devices found matching '$DeviceName'."
    return
}

$results = $targetDevices | Select-Object `
    DeviceName,
    UserPrincipalName,
    ManagedDeviceOwnerType,
    ManagementState,
    ComplianceState,
    OperatingSystem,
    OsVersion,
    LastSyncDateTime,
    AzureADDeviceId

Write-Host ""
Write-Host "Managed device status:" -ForegroundColor Green
$results | Format-Table -AutoSize

if (-not [string]::IsNullOrWhiteSpace($ExportPath)) {
    $results | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8
    Write-Host ""
    Write-Host "Results exported to: $ExportPath" -ForegroundColor Yellow
}