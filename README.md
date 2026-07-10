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
/corp.load --file <pbi.md>
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

---

# Repository Structure

```text
.github/
├── agents/
└── prompts/

docs/
├── architecture.md
├── discovery-log.md
├── session-resume-20260708.md
├── session-resume-20260708-parte1.md
├── session-resume-20260708-parte2.md
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

- /corp.load
- /corp.assess
