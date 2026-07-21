# GRM Corporate Workflow Extension

This extension adds GRM corporate governance commands to a Spec Kit project.

The objective is to enforce a Product Backlog Item (PBI) driven workflow where approved business requirements become the functional source of truth throughout the delivery lifecycle.

---

# Overview

The extension introduces GRM corporate commands without modifying the Spec Kit core.

Key principles:

- Product Driven Development.
- Spec Driven Development.
- PBI as the source of truth.
- Corporate governance.
- Controlled planning and implementation.
- End-to-end traceability.
- No fork of Spec Kit.

---

# Corporate Commands

## /corp.erase

### Purpose

- Reset the active execution context.
- Prevent cross-PBI contamination.
- Ensure repeatable workflow execution.

### Actions

- Reset `.specify/memory/active-pbi.md`
- Clean `features/`
- Remove `.specify/feature.json`

### Characteristics

- Can be executed manually.
- Executed automatically by `/corp.load`.

---

## /corp.load

### Purpose

- Load an approved PBI.
- Initialize a clean execution context.

### Input

```text
/corp.load --file <pbi.md>
```

### Output

```text
.specify/memory/active-pbi.md
```

### Characteristics

- Automatically performs corporate cleanup.
- Extracts and prepares the active PBI context.
- Establishes the functional baseline for the feature.

---

## /corp.assess

### Purpose

Evaluate PBI readiness before planning.

### Characteristics

- Read-only command.
- Does not modify artifacts.
- Performs governance validation.

### Possible Outcomes

```text
READY
READY_WITH_RISKS
NOT_READY
```

### Governance Principle

```text
No Plan Without Assessment
```

---

## /corp.plan

### Purpose

Generate the corporate bootstrap specification required by Spec Kit.

### Output

```text
features/<feature>/spec.md
```

### Characteristics

- Preserves PBI traceability.
- Does not expand scope.
- Does not invent requirements.
- Creates the bridge between the approved PBI and Spec Kit planning.

---

## /corp.doc

### Purpose

Generate authoritative as-built documentation for the implemented feature.

### Output

```text
features/<feature>/delivery-doc.md
```

### Characteristics

- Documentation-only command.
- Does not modify implementation artifacts.
- Uses implementation as the source of truth.
- Compares expected behavior against implemented behavior.
- Consolidates validation evidence.
- Documents deviations, validation gaps and technical debt.
- Generates improvement backlog candidates.

### Possible Outcomes

```text
COMPLIANT
COMPLIANT_WITH_FINDINGS
NON_COMPLIANT
```

---

# Corporate Workflow

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

### Result

```text
Authoritative As-Built Documentation
```

---

# Governance Model

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

### Rationale

Prevent uncontrolled specification creation outside the approved PBI workflow.

---

# Validated Capabilities

The extension has been validated through an end-to-end Proof of Concept covering:

```text
PBI
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

### Validated Outcomes

- Corporate governance enforcement.
- Context isolation between PBIs.
- Specification bootstrap generation.
- Spec Kit planning integration.
- Task generation.
- Real implementation generation.
- Validation evidence execution.
- As-built documentation generation.
- Technical debt identification.
- Validation gap identification.
- Improvement backlog generation.

---

# Design Principles

## PBI as Source of Truth

The approved PBI remains the functional baseline throughout the workflow.

## Implementation as Source of Reality

Generated documentation reflects what was actually implemented, not only what was planned.

## Explicit Context Management

Each execution starts from a clean context to avoid contamination from previous PBIs.

## As-Built Documentation

The final delivery documentation remains synchronized with implementation and provides a reliable basis for future PBIs.

---

# Extension Structure

```text
grm-corporate-workflow/
├── agents/
│   ├── corp.erase.agent.md
│   ├── corp.load.agent.md
│   ├── corp.assess.agent.md
│   ├── corp.plan.agent.md
│   └── corp.doc.agent.md
│
└── prompts/
    └── corp.doc.prompt.md
```

---

# Current Status

## Status

```text
VALIDATED
```

The GRM Corporate Workflow Extension has successfully validated the complete corporate workflow from approved PBI to implementation and authoritative as-built documentation.
