# Changelog

Version: 1.1
Last Updated: 2026-09-01
Status: Release Candidate

All notable changes to the GRM Corporate Workflow Extension are documented in this file.

---

## [1.1.0] - 2026-09-01

### Status

Release Candidate

### Overview

This release makes the PBI source pluggable and moves the guarantee that the loaded PBI matches its source from agent instructions to scripts.

`/corp.load` no longer knows how to reach a PBI. It selects a source adapter from its flag, and the retrieved content is assembled and verified mechanically before it becomes the active context.

### Added

#### PBI Source Skills

- Added `grm-pbi-source-markdown`, the source adapter for markdown PBIs held in the repository.
- Added `grm-azure-devops-pbi`, the source adapter for Azure DevOps work items.
- Added the `--backlog` flag on `/corp.load`, accepting a work item URL or a `<KEY>:<id>` pair. Corporate proxy hosts and their query parameters are normalized before use.
- Added the backlog catalogue template `config/grm-backlog.example.yml`. The credential is read from the `AZDO_PAT` environment variable and is never stored in a repository file.

#### Shared Scripts

- Added `Reset-ActiveContext.ps1`, which performs the context reset and verifies its own result.
- Added `Build-ActivePbi.ps1`, which assembles `.specify/memory/active-pbi.md` from the fragments a source adapter produced.
- Added `Assert-ActivePbi.ps1`, which verifies the assembled file against those fragments and fails rather than repairing it.

### Changed

- `/corp.load` selects a source skill from its flag. The `--file` route keeps its previous behavior and its previous syntax.
- Skills retrieve and report. They no longer transcribe PBI content, and they never write the active context artifacts.
- The pre-load context reset is executed and verified by a script instead of being described to the agent.
- Runtime synchronization documentation now states which asset classes are mirrored by tooling and which are copied by hand.
- Maintenance documentation classifies skill changes and records the debt of the framework itself.

### Fixed

- `/corp.erase` was documented as removing generated features. It does not. Feature folders and delivery artifacts under `features/` are preserved; only `.specify/feature.json` is removed.
- The documented extension structure omitted most of the extension, including every skill and four of the five prompts.
- The installation commands in the repository README and in the bootstrap installation guide contained control bytes introduced by escape interpretation and could not be copied. The paths have been restored.

### Known Limitations

- Comments, child work items, attachments and artifact links are not loaded from a work item. Their presence is reported.
- A work item without a description, or without acceptance criteria, is rejected. It is never loaded partially.
- The runtime synchronization helper for `skills/` is not versioned with the framework.

### Compatibility

Spec Kit: Current supported version.
Governance Preset: grm-corporate-governance v1.0.0.

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
