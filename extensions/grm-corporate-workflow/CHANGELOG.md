# Changelog

Version: 1.0
Last Updated: 2026-07-22
Status: Release Candidate

All notable changes to the GRM Corporate Workflow Extension are documented in this file.

---

## [1.0.0] - 2026-07-22

### Status

Release Candidate

### Overview

First release-ready version of the GRM Corporate Workflow Extension.

This release establishes the approved GRM PBI-first operating model for Spec Kit and provides a controlled corporate workflow that guides delivery teams from approved Product Backlog Items through planning, implementation and delivery documentation.

### Added

#### Corporate Workflow Commands

- Added `/corp.erase` for controlled workspace preparation and context reset.
- Added `/corp.load` for loading approved PBI information and business context.
- Added `/corp.assess` for readiness, dependency and governance assessment.
- Added `/corp.plan` for preparation of the planning context required by Spec Kit.
- Added `/corp.doc` for generation and maintenance of delivery documentation.

#### Governance Alignment

- Formalized the GRM PBI-first operating model.
- Aligned workflow execution with governance requirements defined by the GRM Corporate Governance Preset.
- Established traceability between approved PBIs, planning activities and delivery outputs.

#### Architecture

- Adopted the Source of Truth vs Runtime architecture model.
- Defined extension assets as authoritative sources for workflow customization.
- Documented synchronization expectations for runtime deployment.

#### Documentation

- Added extension operational documentation.
- Added architecture guidance.
- Added governance alignment references.
- Added maintenance guidance for future repository owners.

### Validated Workflow

```text
corp.erase
↓
corp.load
↓
corp.assess
↓
corp.plan
↓
speckit.plan
↓
speckit.tasks
↓
speckit.implement
↓
corp.doc
```
``

### Release Notes

This release is considered the first release candidate suitable for:

- Controlled organizational adoption.
- Internal deployment.
- Knowledge transfer and repository handover.
- Future maintenance by third-party teams.


### Compatibility

Spec Kit: Current supported version.
Governance Preset: grm-corporate-governance v1.0.0.

---
