# GRM Custom Spec Kit - Release Checklist

Document Version: 1.0
Last Updated: 2026-07-22
Status: Release Candidate

---

# Purpose

This checklist provides a concise and repeatable process for validating a GRM Custom Spec Kit release.

It is intended to be used by maintainers before publishing a new version, release tag or repository handover.

This document does not replace the Maintenance Guide.

Instead, it acts as an operational summary of the activities required to confirm release readiness.

---

# Release Readiness Checklist

## 1. Source of Truth Validation

Verify the authoritative customization definition is complete and up to date.

### Extensions

- [ ] All changes committed to `extensions/grm-corporate-workflow`
- [ ] README updated
- [ ] CHANGELOG updated
- [ ] Agents validated
- [ ] Prompts validated

### Presets

- [ ] All changes committed to `presets/grm-corporate-governance`
- [ ] README updated
- [ ] CHANGELOG updated
- [ ] Governance rules validated

---

## 2. Runtime Synchronization Validation

Verify the runtime reflects the current Source of Truth.

- [ ] Runtime synchronized from Extensions
- [ ] Runtime synchronized from Presets
- [ ] Corporate commands available
- [ ] Governance guards available
- [ ] No known Source of Truth / Runtime drift

Verify:

```text
extensions + presets
        ↓
      runtime
```

---

## 3. Bootstrap Validation

### Installer Assets

- [ ] resources/bootstrap/bootstrap-grm-e2e.ps1
- [ ] resources/bootstrap/bootstrap-grm-e2e.bat
- [ ] resources/bootstrap/README.md

### Bootstrap Execution

- [ ] Clean installation executed
- [ ] Git-first clone successful
- [ ] Runtime validation passed
- [ ] installation-report.md generated

### Supporting Assets

- [ ] samples copied
- [ ] docs copied
- [ ] docs/sessions not distributed

---

## 4. Governance Validation

Verify governance controls remain effective.

### Blocked Commands

- [ ] speckit.specify blocked
- [ ] speckit.clarify blocked

### Protected Commands

- [ ] speckit.plan protected
- [ ] Bootstrap validation enforced

### Governance Principles

- [ ] PBI-first delivery preserved
- [ ] Product ownership preserved
- [ ] Traceability preserved
- [ ] No governance regressions detected

---

## 5. Functional Validation

Validate the complete workflow.

### Corporate Commands

- [ ] corp.erase validated
- [ ] corp.load validated
- [ ] corp.assess validated
- [ ] corp.plan validated
- [ ] corp.doc validated

### Native Commands

- [ ] speckit.plan validated
- [ ] speckit.tasks validated
- [ ] speckit.implement validated

---

## 6. End-to-End Validation

Execute a complete validation scenario.

Recommended sequence:

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

Validation results:

- [ ] Workflow completed successfully
- [ ] No unexpected failures detected
- [ ] Governance behavior verified
- [ ] Documentation generated successfully

Expected artifacts:

- [ ] active-pbi.md generated
- [ ] spec.md generated
- [ ] delivery-doc.md generated

---

## 7. Documentation Validation

Verify documentation remains aligned with implementation.

### Core Documentation

- [ ] README updated
- [ ] Architecture Guide updated
- [ ] Installation Guide updated
- [ ] User Guide updated
- [ ] Governance Guide updated
- [ ] Maintenance Guide updated

### Component Documentation

- [ ] Extension README updated
- [ ] Preset README updated

### Consistency Review

- [ ] Terminology consistent
- [ ] Source of Truth vs Runtime documented
- [ ] Governance model documented
- [ ] Documentation map verified

---

## 8. Repository Validation

Verify repository structure.

- [ ] Repository structure reviewed
- [ ] Obsolete files removed
- [ ] Samples reviewed
- [ ] Sessions archived appropriately
- [ ] Runtime structure verified

Expected structure:

```text
.github/
.specify/
docs/
extensions/
presets/
samples/
README.md
```

---

## 9. Versioning Validation

- [ ] Version assigned
- [ ] CHANGELOG updated
- [ ] Release scope agreed
- [ ] Release notes prepared

Recommended format:

```text
v0.x  Experimental
v1.x  Stable
v2.x  Major Evolution
```

---

## 10. Handover Validation

Applicable when ownership is transferred.

- [ ] Documentation complete
- [ ] Maintenance Guide reviewed
- [ ] Open issues documented
- [ ] Known limitations documented
- [ ] Future roadmap documented
- [ ] New maintainer identified

---

## 11. Release Approval

Release can be approved when all previous sections are complete.

Approval Summary:

- [ ] Source of Truth validated
- [ ] Runtime synchronized
- [ ] Governance validated
- [ ] Functional validation completed
- [ ] Documentation validated
- [ ] Version assigned
- [ ] Release approved

---

# Release Decision

| Area | Status |
|--------|--------|
| Source of Truth | ☐ Pass ☐ Fail |
| Runtime | ☐ Pass ☐ Fail |
| Governance | ☐ Pass ☐ Fail |
| Functional Validation | ☐ Pass ☐ Fail |
| Documentation | ☐ Pass ☐ Fail |
| Release Packaging | ☐ Pass ☐ Fail |

Final Result:

```text
☐ RELEASE APPROVED
☐ RELEASE REJECTED
```

---

# Summary

A release is considered ready when:

```text
Source of Truth
        ↓
Runtime
        ↓
Governance
        ↓
Validation
        ↓
Documentation
        ↓
Release
```

All stages must be completed successfully before approval.
