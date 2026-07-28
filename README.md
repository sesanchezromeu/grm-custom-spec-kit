# GRM Custom Spec Kit

Version: 1.0
Last Updated: 2026-07-22
Status: Release Candidate

Corporate customization of Spec Kit that enforces GRM governance while preserving the native Spec Kit workflow and avoiding maintenance of a fork.

---

# Overview

GRM Custom Spec Kit extends Spec Kit through Extensions and Presets.

The objective is to combine:

- Product Driven Development (PDD)
- Spec Driven Development (SDD)
- Corporate governance
- End-to-end traceability
- Git-first installation
- Maximum reuse of native Spec Kit capabilities

The framework ensures that all delivery work originates from an approved Product Backlog Item (PBI), preserving ownership, traceability and governance throughout the entire lifecycle.

---

# Why GRM Custom Spec Kit Exists

Standard Spec Kit assumes that specifications may be created directly from user intent.

GRM requires a different operating model:

- Functional scope must originate from an approved PBI.
- Product Owners remain accountable for requirements.
- Developers must not create new scope outside approved backlog items.
- Planning and implementation must remain traceable to business intent.

GRM Custom Spec Kit introduces governance controls that bridge approved PBIs with the native Spec Kit planning workflow.

---

# Key Principles

## PBI as Functional Source of Truth

The approved Product Backlog Item defines the functional scope.

## Product Ownership

Functional decisions belong to Product Owners.

## Controlled Planning

Planning may only start after governance validation.

## End-to-End Traceability

Every implementation can be traced back to its originating PBI.

## No Fork Strategy

Spec Kit is extended, not modified.

This minimizes maintenance effort and simplifies future upgrades.

---

# Governance Model

## Approved Workflow

```text
corp.erase (optional)
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

Governance Principle:

```text
No Plan Without Assessment
```

## Why speckit.specify Is Blocked

GRM does not allow developers to create functional specifications directly.

Functional scope must originate from an approved PBI.

## Why speckit.clarify Is Blocked

Clarification and functional refinement occur before approval of the PBI.

Allowing ad-hoc clarification during delivery could alter approved scope and reduce traceability.

## Why speckit.plan Remains Available

GRM intentionally preserves the native Spec Kit planning capability.

The role of `corp.plan` is not to replace `speckit.plan`.

Instead, it generates the controlled bootstrap specification required to execute native planning safely.

```text
Approved PBI
        ↓
corp.plan
        ↓
Bootstrap Specification
        ↓
speckit.plan
```

This approach maximizes reuse of Spec Kit while preserving governance.

---

# Architecture Overview

## Source of Truth

The customization is formally defined in:

```text
extensions/
presets/
```

Responsibilities:

- Corporate workflow definition
- Governance rules
- Command definitions
- Corporate prompts and agents

## Runtime

Execution occurs through:

```text
.github/
.specify/
```

Responsibilities:

- Copilot execution runtime
- Spec Kit runtime artifacts
- Generated execution state
- Planning and implementation artifacts

## Documentation Layer

```text
docs/
```

Provides architecture, governance, usage and maintenance guidance.

---

# Quick Start

## Option A - Portable Bootstrap (Recommended)

```powershell
.\resources\bootstrap\bootstrap-grm-e2e.bat -TargetName e2e-demo-01 -Force
```

The bootstrap installer:

- Creates a clean workspace
- Executes deterministic Spec Kit initialization
- Downloads the customization from Git
- Applies runtime synchronization
- Copies samples and documentation
- Generates installation-report.md
- Validates the runtime

## Option B - Manual Installation

Follow:

```text
docs/installation-guide.md
```

Manual and bootstrap installations must produce the same validated result.

---

# Corporate Commands Summary

| Command | Purpose |
|----------|----------|
| corp.erase | Reset execution context |
| corp.load | Load approved PBI |
| corp.assess | Assess readiness and risks |
| corp.plan | Generate controlled bootstrap specification |
| speckit.plan | Generate technical planning artifacts |
| speckit.tasks | Generate implementation tasks |
| speckit.implement | Execute implementation workflow |
| corp.doc | Generate authoritative as-built documentation |

---

# Validation Status

Validated capabilities:

- corp.erase
- corp.load
- corp.assess
- corp.plan
- speckit.plan
- speckit.tasks
- speckit.implement
- corp.doc

Validated outcomes:

- Governance enforcement
- Context isolation between PBIs
- Corporate planning bootstrap
- Native Spec Kit planning integration
- Task generation
- Implementation execution
- Validation evidence consolidation
- As-built documentation generation
- Technical debt identification
- Validation gap identification
- Improvement backlog generation

---

# Repository Structure

```text
.github/
.specify/
docs/
extensions/
presets/
resources/
├── bootstrap/
│   ├── bootstrap-grm-e2e.bat
│   ├── bootstrap-grm-e2e.ps1
│   └── README.md
samples/
```

---

## Documentation Map

```text
README.md
├── docs/installation-guide.md
├── docs/user-guide.md
├── docs/architecture.md
├── docs/governance.md
├── docs/maintenance.md
└── docs/release-checklist.md
```

Recommended reading order:

1. README.md
2. Installation Guide
3. User Guide
4. Architecture Guide
5. Governance Guide
6. Maintenance Guide

---

## Validation Status

Validated:

- Governance enforcement
- Corporate workflow
- Runtime synchronization
- Git-first installer
- Documentation packaging
- End-to-end validation

---

## Release Status


Current Status: Release Candidate

Release readiness requires successful completion of:

- Release checklist
- Bootstrap validation
- Governance validation
- End-to-end validation

