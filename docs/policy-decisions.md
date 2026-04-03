# Policy Decisions

## Purpose

This document explains the reasoning behind the compliance and update policy choices made during Project 2. Understanding why decisions were made is as important as knowing what was configured.

## Compliance Policy — CP-Windows-CloudEndpoint-Baseline

### Why a compliance policy was created

A compliance policy is the mechanism through which Intune evaluates whether a device meets the organization's minimum security standard. Without a compliance policy, a device is marked compliant by default, which provides no meaningful governance signal.

Creating a compliance policy was a required step in establishing real endpoint governance rather than just endpoint enrollment.

### Why the baseline was kept intentionally limited

The first production compliance policy was designed as a stable, supportable starting point rather than an aggressive hardening standard. Several settings that are common in mature enterprise environments were intentionally excluded from the first baseline.

Settings excluded from the initial baseline include BitLocker encryption requirements, Secure Boot requirements, TPM requirements, OS version minimum enforcement, and Defender for Endpoint machine risk score integration.

These exclusions were deliberate. A first production baseline should be something every device in scope can reasonably pass without significant remediation effort. Over-configuring the first baseline risks marking many devices noncompliant immediately, creating operational noise before the organization has established confidence in the management platform itself.

The appropriate time to add these controls is after the baseline has been validated across the environment and the organization has gained operational experience with Intune-driven compliance.

### Why specific settings were included

Firewall, antivirus, antispyware, Microsoft Defender Antimalware, real-time protection, and security intelligence currency were included because they represent foundational endpoint security controls that every managed Windows device should have active. These settings are practical, enforceable, and directly relevant to the organization's security posture without introducing deployment complexity.

### Why the noncompliance action was set to immediate

The compliance policy marks devices noncompliant immediately upon evaluation failure rather than after a grace period. This was a deliberate choice to ensure the compliance signal in Intune accurately reflects device state at all times. Grace periods can obscure real compliance issues in a small environment where immediate visibility is more valuable than reduced operational friction.

### Why the policy was assigned through a group rather than directly

Assigning the policy through SG-Cloud-Endpoint-Pilot rather than directly to all devices supports the controlled rollout model. It allows the organization to validate compliance behavior on a limited set of devices before expanding the assignment scope. This approach reflects real-world deployment practice where broad policy enforcement is preceded by pilot validation.

## Update Policy — UR-Windows-CloudEndpoint-Baseline

### Why an update ring was created

Unmanaged Windows Update behavior on company devices introduces risk. Without a defined update ring, devices may update at unpredictable times, restart during business hours, or defer updates indefinitely. A Windows update ring gives the organization control over when updates install and how devices handle restarts.

### Why the General Availability servicing channel was used

The General Availability channel was selected because it provides access to fully released Windows feature updates without early access complexity. For a small organization in the early stages of endpoint management, stability and predictability are more important than early feature access.

### Why deferral periods were set to zero

Both quality update and feature update deferral periods were set to zero days for the initial baseline. This reflects the organization's current maturity level with endpoint management. In a more mature environment with a larger fleet and established update testing practices, deferral periods would be introduced to allow testing before broad deployment. For the initial baseline, zero deferral prioritizes security currency over update staging.

### Why the active hours window was set to business hours

Active hours were configured from 8 AM to 5 PM to prevent forced restarts during the core working day. This is a practical operational consideration that balances update timeliness with user experience.

## Pilot Group Model

### Why a dedicated pilot group was used instead of all users or all devices

Assigning policies to all users or all devices immediately would be appropriate in a mature environment with well-tested policies and a large support team. In a first production deployment, a controlled pilot scope reduces risk, allows compliance behavior to be validated before broad rollout, and makes troubleshooting significantly easier.

The SG-Cloud-Endpoint-Pilot group was created as the single assignment target for all production baseline policies. This means that expanding the policy scope in the future requires only adding new devices or users to that group rather than reconfiguring the policies themselves. That design supports scale without policy sprawl.
