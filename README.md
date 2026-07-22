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
- Maximum reuse of native Spec Kit capabilities
- Zero modification of the Spec Kit core

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

## 1. Create a Clean Spec Kit Project

```bash
specify init --here
```

## 2. Apply GRM Customization

Copy the GRM customization into the repository.

## 3. Load an Approved PBI

```text
/corp.load --file <pbi.md>
```

## 4. Assess Readiness

```text
/corp.assess
```

## 5. Generate Bootstrap Specification

```text
/corp.plan
```

## 6. Execute Native Planning

```text
/speckit.plan
```

## 7. Generate Tasks

```text
/speckit.tasks
```

## 8. Implement

```text
/speckit.implement
```

## 9. Generate Delivery Documentation

```text
/corp.doc
```

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
.vscode/
docs/
extensions/
presets/
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
└── docs/maintenance.md
```

Recommended reading order:

1. README.md
2. Installation Guide
3. User Guide
4. Architecture Guide
5. Governance Guide
6. Maintenance Guide

---

## Release Status

Current Status: Release Candidate

Validated:
- Governance model
- Corporate workflow
- Documentation
- Packaging

Pending:
- Community adoption
- Future automation improvements
