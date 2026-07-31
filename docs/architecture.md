# GRM Custom Spec Kit - Architecture Guide

Version: 1.0
Last Updated: 2026-07-22
Status: Release Candidate

## 1. Overview

GRM Custom Spec Kit is a corporate customization of Spec Kit that introduces governance, Product Driven Development (PDD) and controlled adoption of Spec Driven Development (SDD) without maintaining a fork of the upstream product.

The architecture has been intentionally designed to:

- Preserve native Spec Kit capabilities.
- Enforce GRM governance.
- Keep Product Owners accountable for functional scope.
- Maintain complete traceability from approved PBI to implementation.
- Minimize future maintenance and upgrade effort.

---

# 2. Architectural Principles

## AP01 - PBI First

All delivery work must originate from an approved Product Backlog Item (PBI).

The PBI is the functional source of truth throughout the delivery lifecycle.

```text
Approved PBI
        ↓
Planning
        ↓
Implementation
        ↓
Delivery Documentation
```

---

## AP02 - No Fork Strategy

GRM Custom Spec Kit extends Spec Kit without modifying the Spec Kit core.

Benefits:

- Simplified upgrades.
- Reduced maintenance cost.
- Better compatibility with future Spec Kit releases.
- Maximum reuse of native capabilities.

---

## AP03 - Source of Truth vs Runtime

A fundamental architectural principle is the separation between customization definition and execution runtime.

### Source of Truth

```text
extensions/
presets/
```

These directories contain the authoritative definition of the GRM customization.

Responsibilities:

- Corporate workflow definition
- Governance rules
- Corporate commands
- Agents
- Prompts
- Guardrails

### Runtime

```text
.github/
.specify/
```

These directories contain executable runtime artifacts.

Responsibilities:

- Copilot execution runtime
- Spec Kit runtime assets
- Generated planning artifacts
- Execution state
- Temporary workflow artifacts

### Architectural Flow

```text
Source of Truth
        ↓
Runtime Generation
        ↓
Execution
```

The customization layer defines behavior.

The runtime layer executes behavior.

---

## AP04 - Bootstrap Pattern

GRM intentionally preserves native Spec Kit planning.

`corp.plan` does not replace `speckit.plan`.

Instead, it creates a compliant bootstrap specification that allows native planning to execute within governance boundaries.

```text
Approved PBI
        ↓
corp.plan
        ↓
Bootstrap Specification
        ↓
speckit.plan
```

Benefits:

- Reuse of proven Spec Kit planning.
- Preservation of corporate traceability.
- Reduced customization complexity.
- Lower maintenance burden.

---

# 3. Reference Architecture

```text
Product Owner
      ↓
Approved PBI
      ↓
corp.erase
      ↓
corp.load
      ↓
active-pbi.md
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
      ↓
delivery-doc.md
```

Governance principle:

```text
No Plan Without Assessment
```

---

# 4. Governance Architecture

## Allowed Commands

```text
corp.erase
corp.load
corp.assess
corp.plan
speckit.plan
speckit.tasks
speckit.implement
corp.doc
```

## Blocked Commands

```text
speckit.specify
speckit.clarify
```

### Why speckit.specify Is Blocked

The standard command allows creation of functional specifications outside the approved PBI lifecycle.

This conflicts with the GRM operating model where Product Owners own functional scope.

### Why speckit.clarify Is Blocked

Functional clarification must occur before PBI approval.

Allowing uncontrolled clarification during delivery may introduce scope changes that bypass governance controls.

### Why speckit.plan Remains Available

Planning is a native Spec Kit capability that GRM intentionally preserves.

The command remains available but is protected by a corporate bootstrap guard.

---

# 5. Corporate Guard Design

## Objective

Prevent execution of native planning before the mandatory corporate workflow has been completed.

## Conceptual Flow

```text
corp.plan
        ↓
Bootstrap Validation
        ↓
Corporate Guard
        ↓
speckit.plan
```

## Validation Responsibilities

The guard verifies that the required corporate preparation has been completed before planning proceeds.

Typical verification points include:

- Active PBI context exists.
- Bootstrap specification exists.
- Corporate workflow markers exist.
- Mandatory governance sequence has been respected.

## Architectural Benefit

The guard enables safe reuse of native Spec Kit planning while protecting governance integrity.

---

# 6. Repository Architecture

```text
.github/        Runtime (corporate artifacts only)
.specify/       Runtime (corporate artifacts only)
.vscode/        Local tooling

docs/           Documentation
extensions/     Source of Truth
presets/        Source of Truth
samples/        Demonstration artifacts
```

## Runtime Layer

The repository's `.github/` and `.specify/` directories contain **only corporate artifacts** with a declared origin in the Source of Truth (`extensions/`, `presets/`). Native Spec Kit artifacts are **not** stored in the repository: they are provided by `specify init` on the target machine during installation. This eliminates the inherited-runtime fossilization previously present (see GRM-SCK_Plan_Adaptacion_Instalador_v1, P6).

### .github

Contains only the corporate agents and prompts (`corp.*`) and the preset overrides declared in `preset.yml`. Native agents and prompts are installed by `specify init` on the target and are never versioned here.

### .specify

Contains only the corporate workflow (`workflows/grm/`) and the constitution variants under `memory/`. Native Spec Kit runtime (scripts, templates, installation state, native workflow, derived registry) is generated at install time and is not versioned here.

---

## Source of Truth Layer

### extensions

Contains formal definitions of corporate workflow commands.

### presets

Contains governance overrides and behavioral guardrails.

---

## Documentation Layer

### docs

Contains user-facing and maintainer-facing documentation.

---

# 7. Runtime Strategy

The current implementation intentionally maintains separation between customization definitions and executable runtime.

```text
extensions + presets
          ↓
      Runtime
```

## Why Duplication Exists Today

The current release prioritizes validation, transparency and troubleshooting.

Keeping runtime artifacts visible allows:

- Easier validation.
- Simpler troubleshooting.
- Explicit comparison between source and runtime.
- Reduced implementation risk during framework evolution.

## Future Direction

A future synchronization mechanism may automate runtime generation.

```text
extensions/
presets/
        ↓
Runtime Generation
        ↓
.github/
```

This would eliminate manual synchronization activities while preserving the same architecture.

---

# 8. Design Decisions

## D01 - No Fork Strategy

Preserve compatibility with upstream Spec Kit.

## D02 - PBI as Source of Truth

Ensure product ownership and functional traceability.

## D03 - Read-Only Assessment

Applied to:

```text
corp.assess
```

Assessment must not modify delivery artifacts.

## D04 - Bootstrap Pattern

Applied to:

```text
corp.plan
```

Creates a controlled bridge between approved business requirements and native planning.

## D05 - Explicit Context Management

Applied to:

```text
corp.erase
corp.load
```

Prevents cross-PBI contamination.

## D06 - As-Built Documentation

Applied to:

```text
corp.doc
```

Uses implementation as the source of reality.

Objectives:

- Detect implementation drift.
- Capture technical debt.
- Capture validation gaps.
- Improve future PBIs.

---

# 9. Validation Status

Validated workflow:

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

Validated outcomes:

- Governance enforcement.
- Context isolation.
- Controlled planning bootstrap.
- Native planning reuse.
- Implementation execution.
- Validation evidence consolidation.
- As-built documentation generation.

---

# 10. Technical Debt

Current limitations:

- Markdown PBI source only.
- No Azure DevOps integration.
- No MCP integration.
- Runtime synchronization not yet automated.
- Additional Spec Kit commands not yet governed.

---

# 11. Roadmap

## v0.2

- Installation model refinement.
- Runtime synchronization.

## v0.3

- Azure DevOps integration.
- MCP integration.

## v0.4

- Governance documentation.
- Maintenance documentation.
- Packaging automation.

## v1.0

- Enterprise-ready framework.
- Governance dashboards.
- Training materials.
