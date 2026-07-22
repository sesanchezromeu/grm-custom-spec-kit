# GRM Custom Spec Kit - Governance Guide

Version: 1.0
Last Updated: 2026-07-22
Status: Release Candidate

## 1. Purpose

This document defines the governance model, operating principles, roles, controls and compliance criteria that govern the use of GRM Custom Spec Kit.

Its purpose is to ensure that delivery work remains aligned with approved business intent, preserves Product Ownership, maintains traceability and prevents uncontrolled scope creation.

This document explains why the framework operates the way it does.

---

# 2. Governance Objectives

GRM Custom Spec Kit was created to achieve the following objectives:

- Ensure all delivery work originates from an approved Product Backlog Item (PBI).
- Preserve Product Owner accountability for functional scope.
- Prevent uncontrolled requirement creation.
- Maintain end-to-end traceability.
- Reuse native Spec Kit capabilities safely.
- Enforce governance without maintaining a Spec Kit fork.
- Generate authoritative delivery documentation.

---

# 3. Operating Model

The GRM delivery model follows a PBI-first approach.

```text
Product Owner
        ↓
Approved PBI
        ↓
GRM Corporate Workflow
        ↓
Implementation
        ↓
Delivery Documentation
```

Governance starts before implementation.

The approved PBI is the authorization to start delivery activities.

No approved PBI means no delivery workflow.

---

# 4. Governance Principles

## GP01 - PBI as Functional Source of Truth

The approved PBI defines the allowed functional scope.

Developers may implement scope.

They may not create new scope.

---

## GP02 - Product Ownership

Functional ownership remains with the Product Owner.

Functional decisions belong to product governance, not delivery execution.

---

## GP03 - No Plan Without Assessment

Planning must be preceded by readiness assessment.

```text
corp.assess
        ↓
corp.plan
        ↓
speckit.plan
```

---

## GP04 - Controlled Planning

Native planning remains available.

However, planning must execute within governance boundaries.

---

## GP05 - End-to-End Traceability

Every delivery artifact must be traceable back to the originating PBI.

---

## GP06 - Documentation as Evidence

Delivery documentation is a governance artifact.

It provides evidence of what was actually implemented.

---

# 5. Roles and Responsibilities

| Role | Governance Responsibility |
|------|---------------------------|
| Product Owner | Approves functional scope and acceptance criteria |
| Developer | Executes the approved workflow |
| Project Manager | Ensures governance compliance and traceability |
| Technical Lead | Ensures technical quality and alignment |
| Maintainer | Maintains framework integrity and runtime alignment |

---

# 6. Source of Truth Model

The governance model relies on a clear ownership structure.

## Functional Source of Truth

```text
Approved PBI
```

Defines:

- Scope
- Business intent
- Acceptance criteria

## Customization Source of Truth

```text
extensions/
presets/
```

Defines:

- Corporate commands
- Governance controls
- Guardrails
- Execution policies

## Runtime

```text
.github/
.specify/
```

Executes the approved governance model.

---

# 7. Approved Workflow

The only approved delivery workflow is:

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

Expected outcome:

```text
features/<feature>/delivery-doc.md
```

---

# 8. Command Governance Matrix

| Command | Governance Status |
|----------|------------------|
| corp.erase | Allowed |
| corp.load | Allowed |
| corp.assess | Allowed |
| corp.plan | Allowed |
| speckit.plan | Protected |
| speckit.tasks | Allowed |
| speckit.implement | Allowed |
| corp.doc | Allowed |
| speckit.specify | Blocked |
| speckit.clarify | Blocked |

---

# 9. Why speckit.specify Is Blocked

The standard `speckit.specify` command allows creation of functional specifications directly from user intent.

This conflicts with the GRM operating model.

GRM requires:

```text
Approved PBI
        ↓
Delivery
```

not:

```text
User Intent
        ↓
Specification
        ↓
Delivery
```

Risks avoided:

- Shadow requirements.
- Unauthorized scope creation.
- Product ownership erosion.
- Loss of traceability.
- Governance bypass.

Corporate policy:

Functional scope must originate from an approved PBI.

---

# 10. Why speckit.clarify Is Blocked

The purpose of clarification is functional refinement.

Under the GRM operating model, refinement occurs before approval.

Therefore:

```text
Refinement
        ↓
Approval
        ↓
Delivery
```

Allowing clarification during delivery may introduce:

- Unapproved requirements.
- Informal scope changes.
- Decision drift.
- Reduced auditability.

Corporate policy:

Functional clarification belongs to backlog refinement, not delivery execution.

---

# 11. Why speckit.plan Remains Available

GRM does not replace Spec Kit planning.

GRM governs planning.

Planning is considered a valuable native capability that should be reused.

Therefore:

```text
speckit.plan
```

remains available.

However, planning is permitted only after the corporate bootstrap has been completed.

---

# 12. Corporate Bootstrap Model

The bootstrap model bridges product governance and native planning.

```text
Approved PBI
        ↓
corp.plan
        ↓
Bootstrap Specification
        ↓
speckit.plan
```

Responsibilities of `corp.plan`:

- Preserve traceability.
- Respect approved scope.
- Create planning input.
- Prepare governance markers.

Responsibilities of `speckit.plan`:

- Generate planning artifacts.
- Reuse native Spec Kit capabilities.

This model allows governance and reuse simultaneously.

---

# 13. Governance Gates

## Gate 1 - Approved PBI Required

Entry criterion:

```text
Approved PBI exists
```

Without it, work must not start.

---

## Gate 2 - Assessment Required

Entry criterion:

```text
corp.assess completed
```

Planning is prohibited otherwise.

---

## Gate 3 - Bootstrap Required

Entry criterion:

```text
corp.plan completed
```

Native planning must not execute before bootstrap generation.

---

## Gate 4 - Delivery Documentation Required

Entry criterion:

```text
corp.doc completed
```

Work is not considered fully governed until delivery documentation exists.

---

# 14. Traceability Model

Governance traceability follows the chain below:

```text
Approved PBI
        ↓
active-pbi.md
        ↓
spec.md
        ↓
Planning Artifacts
        ↓
Tasks
        ↓
Implementation
        ↓
delivery-doc.md
```

Every stage should be explainable through the previous stage.

---

# 15. Governance Anti-Patterns

The following behaviors violate the governance model:

- Using unapproved requirements.
- Executing work without a PBI.
- Skipping assessment.
- Executing planning before bootstrap generation.
- Using blocked commands.
- Expanding scope during implementation.
- Closing work without delivery documentation.
- Breaking traceability between artifacts.

---

# 16. Governance Risks

## Risk 1 - Workflow Bypass

Description:

Executing delivery work outside the approved workflow.

Impact:

Loss of traceability and governance integrity.

---

## Risk 2 - Unauthorized Scope Creation

Description:

Creating scope through blocked commands or informal decisions.

Impact:

Misalignment between business approval and implementation.

---

## Risk 3 - Planning Without Assessment

Description:

Starting planning before readiness has been validated.

Impact:

Increased delivery risk and rework.

---

## Risk 4 - Missing Delivery Documentation

Description:

Completing implementation without delivery evidence.

Impact:

Reduced auditability and knowledge transfer.

---

## Risk 5 - Traceability Loss

Description:

Artifacts cannot be linked back to the originating PBI.

Impact:

Compliance and governance failure.

---

# 17. Compliance Criteria

A delivery is considered governance compliant when:

- An approved PBI exists.
- The PBI was loaded correctly.
- Readiness assessment was executed.
- Bootstrap specification was generated.
- Planning was executed through the approved process.
- Implementation completed successfully.
- Delivery documentation exists.
- Traceability was preserved.

---

# 18. Governance Audit Checklist

Before accepting a delivery, verify:

```text
□ Approved PBI exists
□ corp.load executed
□ corp.assess executed
□ corp.plan executed
□ speckit.plan executed after bootstrap
□ speckit.specify not used
□ speckit.clarify not used
□ Tasks generated
□ Implementation completed
□ delivery-doc.md generated
□ Traceability preserved
```

---

# 19. Compliance Outcomes

## COMPLIANT

All governance controls satisfied.

## COMPLIANT_WITH_FINDINGS

Delivery completed with documented findings that do not invalidate compliance.

## NON_COMPLIANT

One or more mandatory governance controls were violated.

Corrective action is required.

---

# 20. Governance Success Criteria

The governance model is successful when:

- Product Ownership is preserved.
- Approved scope remains controlled.
- Delivery work is traceable.
- Native Spec Kit capabilities are reused safely.
- Delivery documentation exists.
- Governance risks remain visible and manageable.

---

# 21. Summary

GRM Custom Spec Kit is based on a simple governance principle:

```text
Approved Business Intent
        ↓
Controlled Delivery Process
        ↓
Traceable Implementation
        ↓
Authoritative Delivery Documentation
```

The framework does not aim to replace native Spec Kit capabilities.

Its purpose is to ensure those capabilities operate within a controlled, auditable and product-driven delivery model.
