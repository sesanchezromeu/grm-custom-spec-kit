# GRM Custom Spec Kit - Release Checklist

Document Version: 1.1
Last Updated: 2026-07-30
Status: Release Candidate

## Purpose

This checklist provides the mandatory validation activities required before approving a GRM Custom Spec Kit release, handover, package publication or release tag.

The objective is to verify:

- Source of Truth integrity.
- Runtime synchronization.
- Governance enforcement.
- Workflow deployment.
- Bootstrap readiness.
- Documentation quality.
- End-to-end operability.

A release must not be approved until all applicable sections are completed successfully.

---

## 1. Source of Truth Validation

### Extensions

- [ ] Changes committed to `extensions/grm-corporate-workflow`
- [ ] README updated
- [ ] CHANGELOG updated
- [ ] Corporate agents reviewed
- [ ] Corporate prompts reviewed
- [ ] Governance behavior validated

### Presets

- [ ] Changes committed to `presets/grm-corporate-governance`
- [ ] README updated
- [ ] CHANGELOG updated
- [ ] Governance rules validated
- [ ] Corporate workflows validated

### Workflow Source of Truth

- [ ] `presets/grm-corporate-governance/workflows/grm/workflow.yml` reviewed
- [ ] `presets/grm-corporate-governance/workflows/workflow-registry.json` reviewed
- [ ] Workflow version aligned with release scope

---

## 2. Runtime Synchronization Validation

### Copilot Runtime

- [ ] Runtime synchronized from extensions
- [ ] Runtime synchronized from presets
- [ ] Corporate commands available
- [ ] Governance guards available
- [ ] No known runtime drift

### Workflow Runtime

- [ ] `.specify/workflows/grm/workflow.yml` deployed
- [ ] `.specify/workflows/speckit/workflow.yml` preserved
- [ ] `workflow-registry.json` synchronized
- [ ] Registry merge validated
- [ ] No workflow regression detected

### Registry Validation

Expected logical structure:

```text
schema_version
workflows
 ├─ speckit
 └─ grm
```

Checklist:

- [ ] Registry contains `speckit`
- [ ] Registry contains `grm`
- [ ] Native workflow preserved
- [ ] Additive merge validated

---

## 3. Bootstrap Validation

### Installer Assets

- [ ] bootstrap-grm-e2e.ps1 updated
- [ ] bootstrap-grm-e2e.bat updated
- [ ] bootstrap README updated
- [ ] bootstrap installation guide updated

### Installation Modes

- [ ] FailIfExists validated
- [ ] CleanInstall validated
- [ ] UpdateExisting validated

### Clean Installation Validation

- [ ] Clean workspace created
- [ ] Spec Kit initialized
- [ ] Runtime synchronized
- [ ] Workflows deployed
- [ ] Validation passed
- [ ] installation-report.md generated

### Update Validation

- [ ] Existing workspace preserved
- [ ] Spec Kit init not executed
- [ ] Runtime updated
- [ ] Workflows updated
- [ ] Validation passed
- [ ] installation-report.md generated

### Safety Validation

- [ ] Existing directory without explicit mode fails safely
- [ ] No unintended deletion detected
- [ ] Error message is actionable

---

## 4. Governance Validation

### Blocked Commands

- [ ] speckit.specify blocked
- [ ] speckit.clarify blocked

### Guarded Commands

- [ ] speckit.plan requires corporate bootstrap
- [ ] Governance sequence enforced

### Governance Principles

- [ ] PBI-first preserved
- [ ] Product ownership preserved
- [ ] Traceability preserved
- [ ] No governance regressions detected

---

## 5. Functional Validation

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

## 6. Workflow Validation

Expected workflow:

```text
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

Checklist:

- [ ] Workflow GRM executable
- [ ] Workflow SPECKIT executable
- [ ] Runtime workflow aligned with Source of Truth
- [ ] Registry aligned with runtime

---

## 7. End-to-End Validation

Recommended scenario:

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

## 8. Documentation Validation

### Core Documentation

- [ ] README updated
- [ ] Installation Guide updated
- [ ] User Guide updated
- [ ] Architecture Guide updated
- [ ] Governance Guide updated
- [ ] Maintenance Guide updated
- [ ] Release Checklist updated

### Bootstrap Documentation

- [ ] resources/bootstrap/README.md updated
- [ ] bootstrap-installation-guide.md updated

### Consistency Review

- [ ] Terminology consistent
- [ ] Source of Truth documented
- [ ] Runtime documented
- [ ] Workflow model documented
- [ ] Bootstrap model documented

---

## 9. Repository Validation

Expected structure:

```text
.github/
.specify/
docs/
extensions/
presets/
resources/
samples/
README.md
```

Checklist:

- [ ] Repository structure reviewed
- [ ] Obsolete files removed
- [ ] Samples reviewed
- [ ] Sessions excluded from distribution
- [ ] Workflow structure verified

---

## 10. Versioning Validation

- [ ] Version assigned
- [ ] CHANGELOG updated
- [ ] Release scope agreed
- [ ] Release notes prepared

Recommended:

```text
v0.x Experimental
v1.x Stable
v2.x Major Evolution
```

---

## 11. Handover Validation

- [ ] Documentation complete
- [ ] Maintenance guide reviewed
- [ ] Known limitations documented
- [ ] Open issues documented
- [ ] Roadmap documented
- [ ] New maintainer identified

---

## 12. Release Decision Matrix

| Area | Status |
|---|---|
| Source of Truth | ☐ Pass ☐ Fail |
| Runtime | ☐ Pass ☐ Fail |
| Workflows | ☐ Pass ☐ Fail |
| Governance | ☐ Pass ☐ Fail |
| Functional Validation | ☐ Pass ☐ Fail |
| Bootstrap Validation | ☐ Pass ☐ Fail |
| Documentation | ☐ Pass ☐ Fail |
| Release Packaging | ☐ Pass ☐ Fail |

---

## Release Approval

Final Result:

```text
☐ RELEASE APPROVED
☒ RELEASE REJECTED
```

A release may be approved only when:

```text
Source of Truth
        ↓
Runtime
        ↓
Workflows
        ↓
Governance
        ↓
Validation
        ↓
Documentation
        ↓
Release
```

All applicable stages must be completed successfully.
