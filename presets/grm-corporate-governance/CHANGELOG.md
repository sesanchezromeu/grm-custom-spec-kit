# Changelog

Version: 1.0
Last Updated: 2026-07-22
Status: Release Candidate

---

## [1.0.0] - 2026-07-22

### Release Summary

First release-ready version of the GRM Corporate Governance Preset.

This release establishes the governance framework that adapts Spec Kit to the GRM PBI-first operating model. The preset enforces approved governance controls, protects planning activities and ensures alignment between Product Owners, Architects and Development Teams.

### Added

#### Governance Controls

- Added governance protection for `speckit.plan`.
- Added governance overrides for `speckit.specify`.
- Added governance overrides for `speckit.clarify`.
- Established the GRM command governance model.

#### PBI-First Operating Model

- Formalized the approved PBI-driven workflow.
- Prevented direct specification generation outside the corporate process.
- Enforced use of approved corporate workflow commands before planning activities.

#### Corporate Bootstrap Guard

- Introduced prerequisite validation before planning execution.
- Defined the approved preparation sequence:

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
```

- Protected planning activities from bypassing governance controls.

#### Governance Architecture

- Aligned governance behavior with the Source of Truth vs Runtime architecture.
- Established presets as the authoritative source for governance customization.
- Defined synchronization expectations between Source of Truth and Runtime assets.

#### Documentation

- Added governance documentation.
- Added architecture alignment guidance.
- Added maintenance guidance.
- Added release and validation guidance.
- Added component-level documentation for future maintainers.

### Governance Decisions Implemented

#### Blocked Commands

- `speckit.specify`
- `speckit.clarify`

#### Protected Commands

- `speckit.plan`

### Compliance Expectations

To remain compliant with the GRM governance framework, planning activities must originate from an approved Product Backlog Item and follow the published corporate workflow.

### Release Notes

This release is considered suitable for:

- Internal organizational adoption.
- Controlled deployment.
- Repository handover.
- Knowledge transfer.
- Future maintenance by third-party teams.

### Compatibility

- Spec Kit: Current supported version.
- GRM Corporate Workflow Extension: v1.0.0.

---
