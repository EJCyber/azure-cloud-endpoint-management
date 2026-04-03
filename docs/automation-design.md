# Automation Design

## Purpose

This document explains the design and intent behind the two PowerShell scripts developed for Project 2. Both scripts were built to support the production workflow rather than to demonstrate scripting for its own sake.

## Design Principles

Automation in this project was introduced where it reduces inconsistency, not just where it reduces effort. Manual deployment steps that must be performed the same way every time are strong candidates for automation. Steps that require judgment, validation, or contextual decision-making are better left as documented manual steps.

The result is a hybrid workflow where the repeatable Azure provisioning side is automated and the identity, enrollment, and compliance validation steps remain manual and explicitly documented.

## New-CloudEndpointVM.ps1

### Purpose

This script standardizes the Azure side of endpoint provisioning. It ensures that every deployment produces a consistently named, correctly placed, and properly configured virtual machine without requiring the administrator to manually navigate the Azure portal for each resource.

### What it does

The script begins by validating that all required network infrastructure exists before creating any resources. This prevents partial deployments where a virtual machine might be created but placed incorrectly. It validates the resource group, virtual network, subnet, and network security group in sequence before proceeding.

It then detects any existing virtual machines in the resource group that follow the company naming convention and automatically selects the next available sequential number. This ensures naming consistency across the endpoint fleet without manual tracking.

The script creates the public IP address and network interface before configuring the virtual machine, which allows it to apply the correct network placement from the start. The virtual machine is created with the approved image, size, and configuration including boot diagnostics.

After the virtual machine is created, the script configures auto-shutdown at the approved time and outputs a deployment summary including the VM name, IP addresses, network placement, and the next steps in the onboarding workflow.

### Why the Windows computer name is shortened

Azure resource names support up to a certain length, but Windows enforces a 15-character limit on computer names. The full naming convention vm-p2-winclient02 exceeds that limit. The script uses a shortened Windows computer name of winclient02 during OS configuration while preserving the full name in the Azure resource layer. This was identified as a required constraint during the pre-production validation phase and is documented here so future modifications to the naming convention account for it.

### Why the script requires an admin password at runtime

The local administrator password for the new virtual machine is required at script execution rather than being stored in the script itself. Storing credentials in a script file that lives in a repository is a security anti-pattern regardless of who has access to the repository. Prompting at runtime keeps the credential out of the codebase entirely.

### What the script does not do

The script does not perform Entra join, Intune enrollment, or policy assignment. Those steps require interactive authentication and validation that are not appropriate to automate in the current environment. The script's next steps output explicitly directs the administrator to complete those steps manually following the repeatable workflow documentation.

## Get-CloudEndpointStatus.ps1

### Purpose

This script provides a programmatic validation layer for the managed endpoint fleet. It connects to Microsoft Graph and queries Intune for device management data, allowing the administrator to confirm device state through the API rather than relying solely on portal visibility.

### What it does

The script connects to Microsoft Graph using delegated authentication scoped to the correct tenant. It retrieves all managed devices from Intune and filters for devices matching the company endpoint naming prefix. For each matching device it returns the device name, primary user, ownership type, management state, compliance state, operating system, OS version, last sync time, and Azure AD device ID.

Results are displayed in the console by default and can optionally be exported to CSV for record-keeping or operational reporting.

### Why Graph authentication requires explicit tenant scoping

In environments where both personal Microsoft accounts and work accounts are present on the same machine, the Windows Authentication Manager can silently authenticate using the personal account context. The Intune managed devices API does not support personal Microsoft accounts and will return an error if that context is used. The script specifies the tenant ID and context scope explicitly in the connection command to prevent this.

### Why this script matters operationally

Portal-based verification confirms what is visible on screen at a point in time. Graph-based verification confirms what the platform has actually recorded about the device, including compliance state, ownership, and management status as data rather than as UI display. For operational validation after deployment, the script provides a repeatable and exportable confirmation that does not depend on a specific portal view or browser session.

### How to run it

Basic console output:
```powershell
.\Get-CloudEndpointStatus.ps1
```

With CSV export:
```powershell
.\Get-CloudEndpointStatus.ps1 -ExportPath "C:\Reports\CloudEndpointStatus.csv"
```
