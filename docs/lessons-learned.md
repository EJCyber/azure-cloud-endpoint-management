# Lessons Learned

## Purpose

This document captures the operational findings from Project 2 in detail. These are not theoretical observations. Each lesson came from something that actually happened during the pre-production validation or production implementation phases of this project.

## Licensing must precede enrollment expectations

The most impactful discovery of the project was that having Intune visible in the admin center does not mean enrollment will work. Microsoft 365 Business Premium licensing had to be assigned to the deployment account before the Intune enrollment workflow behaved as intended.

This matters because it affects the order of operations for every future deployment. Licensing is not something to configure after the device is already in Azure. It is a prerequisite that must be confirmed before the deployment session begins.

## Azure RBAC and Microsoft Entra administrative roles are separate systems

Being a Global Administrator in Microsoft Entra ID does not grant permission to create or manage Azure resources. When the provisioning script was first run, it failed with a 403 authorization error because the deployment account did not have an Azure role assignment on the subscription despite having full tenant admin rights in Entra.

The deployment account required an explicit Contributor role assignment on the Azure subscription before the script could execute. This is a fundamental architectural distinction between the Microsoft identity plane and the Azure resource plane that affects anyone building automation across both systems.

## NSG rules must account for where administration actually happens

The initial NSG configuration allowed RDP access only from the administrator's home public IP address. This was correct at the time it was configured but became a problem when administrative work moved to a different network location. Both RDP connectivity and Intune policy sync were disrupted until the NSG was updated.

This finding produced a concrete change to the production workflow. Confirming that the NSG allows access from the current administrator network location is now an explicit step that must be completed before beginning any deployment session.

## Azure VM resource naming and Windows hostname limits are different constraints

Azure resource names can be longer than 15 characters, but Windows enforces a strict 15-character limit on computer names. The full company naming convention vm-p2-winclient02 is 18 characters and caused a deployment failure with a clear error message about the computer name limit.

The provisioning script was updated to use a shortened Windows computer name of winclient02 during OS configuration while preserving the full naming convention in the Azure resource layer. This is now documented as a permanent design constraint that must be considered if the naming convention changes in the future.

## Intune compliance evaluation requires an active, reachable device and a successful sync

Creating a compliance policy and assigning it to a group does not immediately produce a compliance result on a device. The device must be online, able to reach the Intune service, and complete a successful check-in before policies evaluate. This is expected behavior but caused confusion during the project when compliance results did not appear immediately after policy assignment.

Newly enrolled devices should be allowed a reasonable window for compliance checks to reconcile, and a forced sync should be performed after adding the device to the pilot assignment group rather than waiting for the next scheduled check-in.

## Freshly deployed VMs may fail the Defender security intelligence check on first evaluation

A newly provisioned Azure virtual machine may have outdated Defender signature definitions even if the image is current. The CP-Windows-CloudEndpoint-Baseline compliance policy includes a check for Defender security intelligence currency, and a fresh VM failed this check immediately after enrollment.

Running the Defender signature update command before joining the device to Entra ID resolved the issue on subsequent deployments. This step was added to the production workflow as a required pre-enrollment action.

## Microsoft Graph authentication context must be explicitly scoped in mixed-identity environments

On a machine where both personal Microsoft accounts and work accounts are present, the Windows Authentication Manager can silently pick up the personal account context when connecting to Microsoft Graph. The Intune managed devices API does not support personal Microsoft account contexts and returns a 400 Bad Request error with a message about MSA accounts not being supported.

The fix is to specify the tenant ID and context scope explicitly in the Connect-MgGraph command. This is now standard practice for all Graph PowerShell sessions in this environment.

## Controlled pilot rollout is worth the extra setup

Creating a dedicated pilot assignment group rather than assigning policies directly to all devices added a small amount of upfront work. That work paid off during the project because it allowed compliance policy behavior to be validated on a single device before any broader assignment, and it made troubleshooting significantly easier when the second device initially showed as noncompliant.

For any organization rolling out endpoint management policies for the first time, a controlled pilot scope is a practical operational choice, not just a best-practice checkbox.

## Pilot validation produces a more reliable production standard than direct production deployment

The pre-production validation phase existed specifically to discover what the environment required before any production standard was written. Without it, the production workflow would have been based on assumptions rather than tested behavior, and several of the dependencies documented above would have been discovered as failures during actual deployments rather than as findings during a controlled exploration.

The cost of running a pre-production validation phase is low. The cost of discovering these dependencies during a production deployment is significantly higher.
