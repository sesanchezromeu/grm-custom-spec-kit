# GRM Corporate Workflow Extension

## Purpose

The GRM Corporate Workflow Extension extends Spec Kit with corporate workflow capabilities designed to support a Product Backlog Item (PBI) driven delivery model.

Its purpose is to bridge approved business requirements with native Spec Kit planning and implementation capabilities while preserving governance, traceability and Product Ownership.

The extension adds workflow behavior.

It does not replace Spec Kit core capabilities.

---

# Problem Statement

Standard Spec Kit allows specification generation directly from user intent.

GRM requires a controlled operating model where delivery work must originate from an approved Product Backlog Item.

```text
Approved PBI
        ↓
Governed Delivery Workflow
        ↓
Implementation
        ↓
Delivery Documentation
```

The extension exists to enforce this workflow while maximizing reuse of native Spec Kit functionality.

---

# Objectives

The extension was designed to:

- Preserve Product Ownership.
- Ensure PBI-first delivery.
- Enforce delivery governance.
- Maintain end-to-end traceability.
- Reuse native Spec Kit planning.
- Prevent context contamination.
- Generate authoritative delivery documentation.
- Avoid maintaining a Spec Kit fork.

---

# Extension Responsibilities

The extension is responsible for:

- Context lifecycle management.
- Approved PBI loading.
- Readiness assessment.
- Corporate bootstrap generation.
- Delivery documentation generation.

The extension is not responsible for:

- Native planning execution.
- Native task generation.
- Native implementation execution.

Those responsibilities remain with Spec Kit.

---

# Position Within the Architecture

```text
Approved PBI
        ↓
GRM Corporate Workflow Extension
        ↓
speckit.plan
        ↓
speckit.tasks
        ↓
speckit.implement
        ↓
Delivery Documentation
```

The extension acts as the operational bridge between approved business scope and native Spec Kit execution.

---

# Corporate Workflow

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

Expected final output:

```text
features/<feature>/delivery-doc.md
```

Governance principle:

```text
No Plan Without Assessment
```

---

# Corporate Commands

## corp.erase

### Purpose

Reset the active execution context.

### Responsibilities

- Remove active PBI state.
- Remove feature execution state.
- Preserve historical feature folders and delivery artifacts.
- Prevent cross-PBI contamination.
- Support clean retest scenarios.

### Managed Artifacts

```text
.specify/memory/active-pbi.md    reset
.specify/feature.json            removed
features/                        ensured to exist, contents preserved
```

### Typical Usage

```text
/corp.erase
```

---

## corp.load

### Purpose

Load an approved PBI and initialize a clean execution context.

### Input

```text
/corp.load --file <path-to-pbi-markdown>
/corp.load --backlog <work-item-url-or-key:id>
```

Exactly one source flag. The flag selects the skill that retrieves the PBI.
Everything after retrieval is identical for both sources.

### Output

```text
.specify/memory/active-pbi.md
```

### Responsibilities

- Reset the active execution context, preserving everything under `features/`.
- Retrieve the approved PBI through the skill named by the source flag.
- Assemble the active execution context and verify it against what was retrieved.
- Establish functional baseline.

### Design Principle

PBI as Functional Source of Truth.

---

## corp.assess

### Purpose

Evaluate PBI readiness before planning.

### Characteristics

- Read-only.
- Governance gate.
- No implementation artifacts generated.
- No modification of approved scope.

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

### Expected Usage

```text
/corp.load
/corp.assess
```

before:

```text
/corp.plan
```

---

## corp.plan

### Purpose

Generate the corporate bootstrap specification required by native Spec Kit planning.

### Output

```text
features/<feature>/spec.md
```

### Responsibilities

- Preserve traceability.
- Respect approved scope.
- Create planning input.
- Create governance bootstrap.

### Important Clarification

`corp.plan` does not replace `speckit.plan`.

Instead:

```text
Approved PBI
        ↓
corp.plan
        ↓
Bootstrap Specification
        ↓
speckit.plan
```

This pattern allows reuse of native planning while maintaining governance.

---

## corp.doc

### Purpose

Generate authoritative as-built delivery documentation.

### Output

```text
features/<feature>/delivery-doc.md
```

### Responsibilities

- Compare intended versus implemented behavior.
- Consolidate validation evidence.
- Detect deviations.
- Detect validation gaps.
- Identify technical debt.
- Generate improvement backlog candidates.

### Possible Outcomes

```text
COMPLIANT
COMPLIANT_WITH_FINDINGS
NON_COMPLIANT
```

### Governance Value

The delivery document acts as the authoritative delivery record for the feature.

---

# PBI Source Skills

`corp.load` does not know how to reach a PBI. It selects a skill by the source
flag and delegates retrieval to it.

| Flag | Skill | Source |
|---|---|---|
| `--file` | `grm-pbi-source-markdown` | A markdown PBI in the repository |
| `--backlog` | `grm-azure-devops-pbi` | An Azure DevOps work item |

Skills are declared under `skills:` in `extension.yml`. A skill directory that is
not declared there does not exist as far as the framework is concerned.

## Division of Responsibility

A skill retrieves and reports. It never writes `.specify/memory/active-pbi.md`,
`.specify/feature.json` or anything under `features/`, and it never authors,
summarizes, reorders or normalizes PBI content.

Those artifacts are written and verified by scripts under
`skills/_shared/scripts/`, which assemble the active PBI from the fragments a
source skill produced and then verify the result against them. `_shared` is a
script library, not a skill, and is deliberately absent from `extension.yml`.

The split is empirical rather than stylistic. Instruction-based copying was
tried and failed in both directions: content absent from the source appeared in
the loaded PBI, content present in it was dropped, and typographic characters
were normalized. Mechanical assembly and verification exist because the
prohibition on its own did not hold.

## Adding a Source

A new source is a new skill plus a new flag on `corp.load`. The retrieval and
reporting contract belongs to the skill; assembly, verification and the context
lifecycle stay in `_shared` and in the command. See `Type 5 - Skill Change` in
`docs/maintenance.md`.

---

# Relationship with Native Spec Kit

The extension intentionally preserves native Spec Kit capabilities.

## Reused Commands

```text
speckit.plan
speckit.tasks
speckit.implement
```

## Strategy

```text
GRM governs planning
GRM does not replace planning
```

Benefits:

- Lower maintenance cost.
- Better compatibility.
- Easier upgrades.
- Increased reuse of upstream capabilities.

---

# Governance Relationship

The extension implements workflow behavior.

Governance restrictions are defined separately through:

```text
presets/grm-corporate-governance
```

Examples:

- speckit.specify blocked.
- speckit.clarify blocked.
- speckit.plan protected by bootstrap validation.

This separation keeps workflow implementation and governance policy independent.

---

# Design Principles

## PBI First

Approved PBIs define functional scope.

## Product Ownership

Functional ownership remains with the Product Owner.

## Controlled Planning

Planning requires readiness assessment and bootstrap generation.

## Explicit Context Management

Every workflow starts from a known execution state.

## End-to-End Traceability

All delivery artifacts can be traced back to the approved PBI.

## As-Built Documentation

Documentation reflects implemented reality, not only planned intent.

---

# Traceability Model

```text
Approved PBI
        ↓
active-pbi.md
        ↓
spec.md
        ↓
Planning
        ↓
Tasks
        ↓
Implementation
        ↓
delivery-doc.md
```

The extension is responsible for preserving this traceability chain.

---

# Extension Structure

```text
grm-corporate-workflow/
├── extension.yml
├── README.md
├── CHANGELOG.md
│
├── agents/
│   ├── corp.erase.agent.md
│   ├── corp.load.agent.md
│   ├── corp.assess.agent.md
│   ├── corp.plan.agent.md
│   └── corp.doc.agent.md
│
├── prompts/
│   ├── corp.erase.prompt.md
│   ├── corp.load.prompt.md
│   ├── corp.assess.prompt.md
│   ├── corp.plan.prompt.md
│   └── corp.doc.prompt.md
│
├── skills/
│   ├── _shared/
│   │   └── scripts/
│   │       ├── Reset-ActiveContext.ps1
│   │       ├── Build-ActivePbi.ps1
│   │       └── Assert-ActivePbi.ps1
│   │
│   ├── grm-pbi-source-markdown/
│   │   ├── SKILL.md
│   │   ├── references/
│   │   └── scripts/
│   │
│   └── grm-azure-devops-pbi/
│       ├── SKILL.md
│       ├── references/
│       └── scripts/
│
└── config/
    └── grm-backlog.example.yml
```

---

# Validation Status

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
- PBI-driven execution.
- Bootstrap generation.
- Native planning reuse.
- Task generation.
- Implementation execution.
- Delivery documentation generation.
- Technical debt identification.
- Validation gap identification.
- Improvement backlog generation.

---

# Maintainer Notes

When modifying this extension:

1. Update Source of Truth first.
2. Synchronize runtime.
3. Revalidate governance.
4. Execute end-to-end validation.
5. Update documentation.

Refer to:

```text
docs/maintenance.md
```

for the complete maintenance process.

---

# Related Documentation

```text
README.md
Installation Guide
User Guide
Architecture Guide
Governance Guide
Maintenance Guide
```

Recommended reading order:

1. README
2. Governance Guide
3. Architecture Guide
4. User Guide
5. Maintenance Guide
