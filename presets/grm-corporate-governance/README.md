# GRM Corporate Governance Preset

## Purpose

The GRM Corporate Governance Preset defines the governance rules, command restrictions and execution guardrails required to enforce the GRM delivery model.

Its purpose is to ensure that native Spec Kit capabilities operate within a controlled, traceable and Product Owner-driven workflow.

The preset implements governance policy.

It does not implement workflow behavior.

Workflow behavior is implemented by:

```text
extensions/grm-corporate-workflow
```

---

# Governance Scope

The preset is responsible for:

- Command governance.
- Workflow protection.
- Corporate guardrails.
- Scope protection.
- Traceability protection.
- Delivery policy enforcement.

The preset is not responsible for:

- Loading PBIs.
- Assessing readiness.
- Bootstrap generation.
- Delivery documentation.

Those functions belong to the GRM Corporate Workflow Extension.

---

# Governance Objectives

The preset exists to achieve the following objectives:

- Preserve Product Ownership.
- Prevent uncontrolled scope creation.
- Ensure delivery starts from approved business intent.
- Protect native planning from governance bypass.
- Maintain end-to-end traceability.
- Prevent workflow shortcuts.
- Enable controlled reuse of Spec Kit.

---

# Operating Model

GRM adopts a PBI-first delivery model.

```text
Approved PBI
        ↓
Corporate Workflow
        ↓
Planning
        ↓
Implementation
        ↓
Delivery Documentation
```

The preset ensures this sequence cannot be bypassed through standard Spec Kit commands.

---

# Governance Principles

## GP01 - Approved Scope Required

All delivery activity must originate from an approved Product Backlog Item.

## GP02 - Product Ownership Preservation

Functional scope remains owned by Product Management.

## GP03 - No Plan Without Assessment

Planning requires prior readiness assessment.

## GP04 - Controlled Planning

Planning remains available but must operate within governance boundaries.

## GP05 - End-to-End Traceability

All delivery artifacts must remain traceable to the originating PBI.

---

# Managed Commands

## Allowed Commands

```text
corp.erase
corp.load
corp.assess
corp.plan
speckit.tasks
speckit.implement
corp.doc
```

## Protected Command

```text
speckit.plan
```

## Blocked Commands

```text
speckit.specify
speckit.clarify
```

---

# Why speckit.specify Is Blocked

The standard Spec Kit specification flow allows functional specifications to be generated directly from user intent.

This conflicts with the GRM operating model.

GRM requires:

```text
Approved PBI
        ↓
Delivery
```

rather than:

```text
User Intent
        ↓
Specification
        ↓
Delivery
```

Risks avoided:

- Unauthorized scope creation.
- Shadow requirements.
- Scope creep.
- Product ownership erosion.
- Traceability loss.

Governance Policy:

```text
Functional scope must originate from an approved PBI.
```

---

# Why speckit.clarify Is Blocked

Functional clarification belongs to backlog refinement.

Under the GRM model:

```text
Refinement
        ↓
Approval
        ↓
Delivery
```

Allowing clarification during delivery introduces risk of:

- Unapproved requirements.
- Informal scope changes.
- Governance bypass.
- Auditability reduction.

Governance Policy:

```text
Functional clarification must occur before delivery begins.
```

---

# Why speckit.plan Remains Available

GRM intentionally preserves native Spec Kit planning.

The objective is governance, not replacement.

Therefore:

```text
speckit.plan
```

remains available.

However, planning must execute only after the corporate bootstrap has been generated.

---

# Corporate Planning Guard

## Objective

Prevent planning from starting before mandatory governance steps have completed.

## Protected Flow

```text
corp.load
        ↓
corp.assess
        ↓
corp.plan
        ↓
speckit.plan
```

## Expected Validation

Before planning is allowed:

- Active PBI must exist.
- Assessment must have completed.
- Corporate bootstrap must exist.
- Governance sequence must be respected.

## Governance Benefit

Native planning can be reused safely without compromising delivery governance.

---

# Relationship with the Workflow Extension

The architecture intentionally separates:

## Workflow Layer

```text
extensions/grm-corporate-workflow
```

Responsibilities:

- Workflow execution.
- Command behavior.
- Artifact generation.

## Governance Layer

```text
presets/grm-corporate-governance
```

Responsibilities:

- Rules.
- Restrictions.
- Guardrails.
- Compliance controls.

This separation improves maintainability and governance transparency.

---

# Governance Gates

## Gate 1 - Approved PBI

Required before delivery starts.

## Gate 2 - Readiness Assessment

Required before planning.

## Gate 3 - Bootstrap Generation

Required before native planning.

## Gate 4 - Delivery Documentation

Required before delivery closure.

---

# Compliance Expectations

A delivery is governance compliant when:

- Approved PBI exists.
- Corporate workflow is followed.
- Blocked commands are not used.
- Protected planning sequence is respected.
- Traceability is preserved.
- Delivery documentation exists.

---

# Validation Requirements

The preset is considered valid when:

```text
speckit.specify = blocked
speckit.clarify = blocked
speckit.plan = protected
```

and the complete workflow executes successfully.

---

# Maintainer Guidance

When modifying the preset:

1. Review governance rationale.
2. Update Source of Truth first.
3. Synchronize runtime.
4. Validate command behavior.
5. Execute governance tests.
6. Execute end-to-end validation.
7. Update documentation.

Changes to governance rules should be treated as high-risk modifications.

---

# Related Documentation

```text
README.md
Architecture Guide
Installation Guide
User Guide
Governance Guide
Maintenance Guide
extensions/grm-corporate-workflow
```

Recommended reading order:

1. README
2. Governance Guide
3. Architecture Guide
4. Workflow Extension README
5. Maintenance Guide

---

# Summary

The GRM Corporate Governance Preset exists to enforce a simple principle:

```text
Approved Business Intent
        ↓
Controlled Workflow
        ↓
Controlled Planning
        ↓
Traceable Delivery
```

The preset protects the operating model by blocking unauthorized specification creation, preventing uncontrolled clarification and ensuring that planning occurs only after the mandatory governance workflow has been completed.
