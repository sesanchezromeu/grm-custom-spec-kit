# GRM Custom Spec Kit

Corporate customization of Spec Kit based on Presets and Extensions.

## Overview

GRM Custom Spec Kit is a Proof of Concept (POC) that extends and governs the standard Spec Kit workflow without modifying the Spec Kit core.

The objective is to enforce a Product Backlog Item (PBI) driven workflow, where approved business requirements become the single functional source of truth throughout the software delivery lifecycle.

Key principles:

- Product Driven Development
- Spec Driven Development
- PBI as the source of truth
- Corporate governance
- Maximum reuse of standard Spec Kit capabilities
- No fork of Spec Kit

---

# Objectives

The POC validates that it is possible to:

- Introduce corporate commands without modifying Spec Kit core.
- Govern the development lifecycle through approved PBIs.
- Prevent uncontrolled specification creation.
- Reuse the native planning and implementation workflow.
- Maintain compatibility with future Spec Kit releases.

---

# Corporate Workflow

```text
/corp.erase (optional manual execution)
        ↓
/corp.load --file <pbi.md>
        ↓
(corporate cleanup executed automatically)
        ↓
/corp.assess
        ↓
/corp.plan
        ↓
/speckit.plan
        ↓
/speckit.tasks
        ↓
/speckit.implement
```

Governance principle:

```text
No Plan Without Assessment
```

## Context Management

To avoid contamination between different PBI executions, the GRM workflow introduces an explicit context management mechanism.

### /corp.erase

Purpose:

- Reset `.specify/memory/active-pbi.md`
- Clean `features/`
- Remove `.specify/feature.json`

This command can be executed manually when required.

### Automatic cleanup

`/corp.load` automatically performs the same cleanup procedure before loading a new PBI.

This guarantees:

- Clean execution context
- No residual active feature references
- No previous PBI contamination
- Repeatable execution results

---

# Repository Structure

```text
.github/
├── agents/
└── prompts/

docs/
├── architecture.md
├── discovery-log.md
└── user-guide.md

extensions/
└── grm-corporate-workflow/

presets/
└── grm-corporate-governance/

samples/
```

---

# Architecture

The solution is composed of two customization layers.

## Extension

Location:

```text
extensions/grm-corporate-workflow
```

Provides new corporate commands:

- /corp.erase
- /corp.load
- /corp.assess
- /corp.plan
