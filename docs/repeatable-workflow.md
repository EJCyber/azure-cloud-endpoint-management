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
