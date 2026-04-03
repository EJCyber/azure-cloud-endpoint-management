# Repeatable Production Workflow

## Purpose

This document defines the approved step-by-step workflow for deploying a new Azure-hosted Windows endpoint in the organization's cloud-first environment. It is based on the production standard and the lessons learned from the pre-production validation phase.

Every new endpoint should follow this workflow in the order shown.

## Prerequisites

Before beginning a new endpoint deployment, confirm the following are already in place.

Microsoft 365 Business Premium is active in the tenant. The deployment account has the Business Premium license assigned. Intune MDM user scope is set to All. The SG-Cloud-Endpoint-Pilot group exists. The CP-Windows-CloudEndpoint-Baseline compliance policy exists. The UR-Windows-CloudEndpoint-Baseline update ring exists. The approved network infrastructure exists in the target region.

## Step 1 — Run the provisioning script

Run New-CloudEndpointVM.ps1 from the PowerShell Scripts folder using the approved admin account credentials for the Azure subscription.
```powershell
$pw = Read-Host "Enter local admin password" -AsSecureString
.\New-CloudEndpointVM.ps1 -AdminPassword $pw
```

The script will validate the existing network infrastructure, detect any previously deployed endpoints, assign the next available name in the sequence, create the public IP address, network interface, and virtual machine, configure auto-shutdown, and output a deployment summary with next steps.

Confirm the output shows the correct VM name, resource group, region, and network placement before proceeding.

## Step 2 — Confirm NSG administrative access

Check the current public IP address being used for this deployment session. Open the NSG nsg-p2-endpoint in the Azure portal and confirm that an inbound TCP rule allows RDP access from that IP address on port 3389.

If the administrator's network location has changed since the last deployment, add a new inbound rule for the current source IP before proceeding. Do not leave RDP open from previous locations that are no longer in use.

## Step 3 — Connect to the VM and complete initial validation

RDP to the new VM using the public IP from the script output. Log in with the labadmin account and the password set during provisioning.

Inside the VM, confirm internet connectivity by opening Edge and verifying that both the Azure portal and the Intune admin center load successfully. Confirm the system time is correct.

## Step 4 — Update Defender signatures

Before joining the device to Entra ID, update the Microsoft Defender security intelligence definitions to ensure the device will pass the security intelligence compliance check on first evaluation.

Open PowerShell as Administrator inside the VM and run:
```powershell
& "C:\Program Files\Windows Defender\MpCmdRun.exe" -SignatureUpdate
```

Wait for the update to complete and confirm success before proceeding.

## Step 5 — Join the device to Microsoft Entra ID

Open Settings, go to Accounts, and click Access work or school. Click Connect, then select Join this device to Microsoft Entra ID from the alternate actions section at the bottom of the dialog.

Sign in with the approved internal admin account:
In my case it was - adm-manny@mannylabsacctgmail.onmicrosoft.com

Complete the MFA prompt and confirm the join completes successfully. The device will prompt to confirm the organization before finalizing.

## Step 6 — Confirm Intune enrollment

After the Entra join completes, return to Settings, Accounts, Access work or school. Confirm that the connected entry now shows both the Entra ID connection and the Managed by Default Directory MDM connection.

If only the Entra ID connection is present and the MDM connection is missing, click the connected entry to expand it and select Enroll only in device management. Sign in with the same internal admin account and complete the enrollment.

Confirm a successful sync has occurred by clicking Info next to the MDM connection and reviewing the Device sync status section.

## Step 7 — Add the device to the pilot assignment scope

In Microsoft Entra admin center, navigate to Groups and open SG-Cloud-Endpoint-Pilot. Add the new device as a member of the group.

This ensures the device will receive the CP-Windows-CloudEndpoint-Baseline compliance policy and the UR-Windows-CloudEndpoint-Baseline update ring.

## Step 8 — Force sync and validate compliance

Return to the VM and go to Settings, Accounts, Access work or school. Click the MDM connection entry, select Info, and click Sync. Wait for the sync to complete.

In the Intune admin center, navigate to Devices, All devices, and open the new device. Confirm the compliance state shows Compliant. Open the Device compliance section and confirm the CP-Windows-CloudEndpoint-Baseline policy evaluates successfully with all settings passing.

If the Defender security intelligence check shows Not Compliant, run the signature update command again and force another sync. Allow a few minutes for the compliance evaluation to reconcile.

## Step 9 — Update primary user and device ownership

In the Intune admin center, navigate to the device properties. Confirm that Device ownership is set to Corporate. If it shows Personal, change it to Corporate.

Click Change primary user and assign the intended standard user who will be using this endpoint. This reflects the company endpoint handoff model and completes the device ownership record.

## Step 10 — Validate through Graph reporting

From the PowerShell Scripts folder, run the reporting script to confirm the device is visible in Intune through the Microsoft Graph API.
```powershell
.\Get-CloudEndpointStatus.ps1
```

Confirm the new device appears in the output with the correct primary user, company ownership, and managed status.

## Step 11 — Record the device as production-ready

Document the completed deployment including the device name, primary user, deployment date, compliance state, and any notes relevant to the deployment session. The device is now considered production-ready.
