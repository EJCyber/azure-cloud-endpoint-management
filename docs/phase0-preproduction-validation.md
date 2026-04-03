# Phase 0 — Pre-Production Validation

## Purpose

Before any production standards were defined or documented, a dedicated validation phase was completed to test whether the environment could support the intended cloud endpoint management workflow from end to end.

This phase was intentionally exploratory. The goal was not to build something polished. The goal was to discover what the environment actually required, identify dependencies that were not obvious upfront, and validate enrollment behavior before any process was locked in.

The pre-production phase is the reason the production workflow is reliable rather than improvised.

## What Was Tested

A Windows 11 Azure virtual machine was deployed within the Project 2 network infrastructure, joined to Microsoft Entra ID, and brought through the Intune enrollment process. Each stage was tested without assumptions, and the results were documented as findings rather than failures.

## Key Findings

### Licensing dependency

Microsoft 365 Business Premium licensing had to be assigned to the deployment account before Intune enrollment would behave as expected. The tenant having Intune visible in the admin center did not automatically mean a user or device could enroll. This was one of the most important discoveries of the validation phase because it directly affects the order of operations for any future deployment.

### MDM scope configuration

The Intune MDM user scope had to be explicitly set to All in the tenant mobility settings before devices could enroll automatically. Without this configuration, a device could complete a Microsoft Entra join successfully and still not trigger Intune enrollment.

### Internal account requirement for Entra join

The Entra join process required an internal tenant member account rather than a personal Microsoft account or an external guest identity. The primary Azure tenant account used for initial setup was a personal Microsoft account linked to the tenant, which Windows rejected during the Join this device to Microsoft Entra ID flow. A proper internal cloud-only account had to be used instead.

### NSG rules and administrative location

Administrative access to the virtual machine was initially configured to allow RDP only from the administrator's home public IP address. When administrative work moved to a different network location, both RDP access and Intune policy sync were disrupted until the NSG inbound rule was updated to include the new source IP. This finding directly informed the production standard, which now includes an explicit NSG check as part of every deployment.

### Manual enrollment fallback

When a device was joined to Entra ID before the MDM scope and licensing were fully configured, automatic Intune enrollment did not trigger. The manual enrollment path through Settings, Accounts, Access work or school, Enroll only in device management was validated as the correct fallback. This path is now documented as an expected step in the production workflow when automatic enrollment does not complete.

### Graph authentication context

When running Microsoft Graph PowerShell from a machine where both personal and work identities were present, the Windows Authentication Manager silently picked up the personal Microsoft account context. The Intune managed devices API rejected that context. Specifying the tenant ID and context scope explicitly in the Connect-MgGraph command resolved the issue and is now part of the standard Graph connection process.

## Outcome

Each finding from the pre-production phase was carried forward into the production standard. The validation phase confirmed that the environment could support the intended workflow and produced a clear set of prerequisites that must be in place before any production deployment begins.

The pre-production work also validated both enrollment paths, confirmed the compliance reporting pipeline through Microsoft Graph, and identified the operational constraints that shape the repeatable production workflow documented in this project.
