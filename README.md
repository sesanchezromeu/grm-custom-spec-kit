# GRM Custom Spec Kit

Version: 1.1
Last Updated: 2026-07-30
Status: Release Candidate

## Overview

GRM Custom Spec Kit is a corporate customization of Spec Kit that enforces GRM governance while preserving native Spec Kit capabilities.

Objectives:

- PBI-first delivery model.
- Product ownership preservation.
- Governance enforcement.
- End-to-end traceability.
- Workflow standardization.
- Maximum Spec Kit reuse.
- No-fork maintenance strategy.

## Core Principle

All delivery activity begins with an approved Product Backlog Item (PBI).

```text
Approved PBI
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

## Why This Customization Exists

Standard Spec Kit allows specifications to originate directly from user intent.

GRM requires:

- Approved backlog ownership.
- Controlled scope management.
- Traceable planning.
- Controlled implementation.
- Governance checkpoints.

The customization bridges approved PBIs with the native Spec Kit delivery workflow.

## Governance Model

### Blocked Commands

```text
speckit.specify
speckit.clarify
```

### Guarded Commands

```text
speckit.plan
```

Available only after successful corporate bootstrap.

### Preserved Native Commands

```text
speckit.plan
speckit.tasks
speckit.implement
```

## Architecture

### Source of Truth

```text
extensions/
presets/
```

Defines:

- Corporate commands.
- Governance rules.
- Agents.
- Prompts.
- Corporate workflows.

### Runtime

```text
.github/
.specify/
```

Contains executable artifacts used by Copilot and Spec Kit.

### Workflow Model

Source:

```text
presets/grm-corporate-governance/workflows
```

Runtime:

```text
.specify/workflows
```

Installed workflows:

```text
speckit
grm
```

Registry strategy:

```text
Additive merge
```

Native workflows are preserved.

## Installation Options

### Option A - Bootstrap Installation (Recommended)

```powershell
.
esourcesootstrapootstrap-grm-e2e.bat `
  -TargetName e2e-demo-01 `
  -InstallMode CleanInstall `
  -Force
```

Supported modes:

- FailIfExists
- CleanInstall
- UpdateExisting

Bootstrap capabilities:

- Deterministic Spec Kit initialization.
- Runtime synchronization.
- Workflow deployment.
- Registry merge.
- Runtime validation.
- Installation report generation.

### Option B - Manual Installation

Follow:

```text
docs/installation-guide.md
```

Manual installation remains the reference model.

## Corporate Commands

| Command | Purpose |
|---|---|
| corp.erase | Reset execution context |
| corp.load | Load approved PBI |
| corp.assess | Assess readiness and risks |
| corp.plan | Generate bootstrap specification |
| corp.doc | Generate authoritative documentation |

## Repository Structure

```text
.github/
.specify/
docs/
extensions/
presets/
resources/
└── bootstrap/
samples/
README.md
```

## Documentation Map

### Core Documentation

```text
docs/installation-guide.md
docs/user-guide.md
docs/architecture.md
docs/governance.md
docs/maintenance.md
docs/release-checklist.md
```

### Bootstrap Documentation

```text
resources/bootstrap/README.md
resources/bootstrap/bootstrap-installation-guide.md
```

Recommended reading order:

1. README.md
2. Installation Guide
3. User Guide
4. Architecture Guide
5. Governance Guide
6. Maintenance Guide
7. Release Checklist

## Validation Status

Validated:

- Governance enforcement.
- Corporate workflow.
- Runtime synchronization.
- Workflow deployment.
- Workflow registry merge.
- Clean installation.
- Non-destructive update.
- Safe installation mode.
- Bootstrap installer.
- Documentation packaging.
- End-to-end validation.

## Release Readiness

Current Status:

```text
Release Candidate
```

Release approval requires:

- Release checklist completion.
- Governance validation.
- Workflow validation.
- Runtime validation.
- Bootstrap validation.
- End-to-end validation.

## Key Design Decisions

### PBI-First

No delivery work starts without an approved PBI.

### No Fork Strategy

Spec Kit is extended, not replaced.

### Source of Truth Separation

Authoring and execution layers remain separated.

### Workflow Preservation

Native Spec Kit workflows remain available.

### Traceability

Every implementation remains traceable to its originating PBI.

## Summary

GRM Custom Spec Kit combines:

```text
Governance
    +
Approved PBI
    +
Native Spec Kit
    +
Workflow Control
    +
Traceability
```

while preserving compatibility with future Spec Kit evolution.
