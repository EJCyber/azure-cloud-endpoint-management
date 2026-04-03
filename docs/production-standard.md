# Production Standard

## Purpose

This document defines the approved production standard for deploying and managing Azure-hosted Windows endpoints in the organization's cloud-first environment. It is based on the findings from the pre-production validation phase and reflects the decisions made during the production implementation phase of Project 2.

## Licensing Requirements

Every managed endpoint deployment requires the following licensing to be in place before the process begins.

Microsoft 365 Business Premium must be active in the tenant. The deployment account used to join and enroll the device must have the Business Premium license assigned. Intune MDM user scope must be configured to All in the tenant mobility settings.

These are not optional prerequisites. Attempting to complete Intune enrollment without them in place will result in incomplete or failed enrollment behavior.

## Identity Requirements

All deployment and administrative activity must use an approved internal tenant account. Personal Microsoft accounts and external guest identities are not supported for device join or enrollment operations.

The deployment account must be a cloud-only member account in the tenant with sufficient permissions to perform Entra join and Intune enrollment operations.

Administrative accounts must remain separate from standard user accounts, consistent with the identity separation model established in Project 1.

## Network and Infrastructure Standard

All endpoints are deployed within the approved Azure network infrastructure.

The resource group for endpoint resources is rg-p2-infra-endpoint-westus2. The virtual network is vnet-p2-core. The endpoint subnet is snet-endpoint. The network security group is nsg-p2-endpoint.

All virtual machines are deployed in the West US 2 region based on tested availability for the approved VM size. The approved VM size is Standard B2s v2.

Auto-shutdown must be enabled on all virtual machines at deployment time. The approved shutdown time is 2300 Eastern Standard Time.

## Naming Convention

All endpoints follow the company naming convention using the prefix vm-p2-winclient followed by a two-digit sequential number. The provisioning script automatically detects existing endpoints and assigns the next available number to maintain consistency.

Azure resource names follow the full naming convention. The Windows computer name uses a shortened format of winclient followed by the two-digit number to comply with the 15-character Windows hostname limit.

Supporting resources including the network interface and public IP address follow the same naming pattern as the virtual machine with the appropriate suffix.

## Administrative Access

Remote desktop access is restricted to the current approved administrator public IP address at all times. The NSG inbound rule must be reviewed and updated before each deployment session if the administrator's network location has changed.

Broad or open RDP access is not permitted under any circumstances.

## Enrollment Standard

Devices are enrolled in Microsoft Intune following Microsoft Entra join. Automatic enrollment is the preferred path and will complete when licensing and MDM scope are properly configured.

If automatic enrollment does not complete, the manual enrollment path through Settings, Accounts, Access work or school, Enroll only in device management is the approved fallback.

Enrollment is considered complete when the device shows both the Entra ID connection and the MDM connection in the Access work or school settings page, and when a successful sync has been confirmed.

## Device Ownership and Handoff

All company-deployed endpoints must be marked as Corporate-owned in Intune. Personal ownership is not appropriate for company-provisioned devices.

After the endpoint has been joined, enrolled, validated for compliance, and confirmed as production-ready, the primary user must be updated from the deployment admin account to the intended standard user. This reflects the company's endpoint handoff model and ensures that device ownership records accurately represent who the endpoint serves.

## Pilot Scope

All production baseline policies are assigned through the SG-Cloud-Endpoint-Pilot group. New endpoints must be added to this group before compliance and update policies will evaluate against them.

This controlled assignment model allows the organization to validate policy behavior before expanding the scope of deployment.
