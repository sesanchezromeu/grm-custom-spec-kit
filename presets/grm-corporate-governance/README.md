# GRM Corporate Governance Preset

This preset customizes the standard Spec Kit behavior to enforce the GRM corporate workflow.

## Protected Commands

- `/speckit.specify`
- `/speckit.clarify`
- `/speckit.plan`

## Purpose

The preset prevents developers from bypassing the approved PBI workflow.

## Governance Rules

- Specifications must originate from an approved PBI.
- `/speckit.specify` is disabled.
- `/speckit.clarify` is disabled.
- `/speckit.plan` requires a previous `/corp.plan` bootstrap.