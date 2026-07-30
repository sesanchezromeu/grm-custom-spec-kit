# GRM Custom Spec Kit - Bootstrap Installation Guide

Document Version: 1.0  
Last Updated: 2026-07-30  
Status: Release Candidate  
Scope: Automated and unattended installation using the GRM bootstrap installer

## 1. Purpose

This guide describes the official bootstrap installer used to create, validate, update and reproduce GRM Custom Spec Kit environments.

The bootstrap installer provides a repeatable, Git-first and governance-aligned mechanism for preparing a workspace with:

- Standard Spec Kit runtime.
- GRM Custom Spec Kit customization.
- Corporate governance controls.
- Corporate workflows.
- Runtime synchronization.
- Installation evidence.

This document complements, but does not replace:

```text
docs/installation-guide.md
```

The installation guide remains the reference document describing the manual installation model.

---

## 2. Bootstrap Assets

The installer consists of:

```text
resources/bootstrap/
├── README.md
├── bootstrap-grm-e2e.bat
├── bootstrap-grm-e2e.ps1
└── bootstrap-installation-guide.md
```

### bootstrap-grm-e2e.ps1

Primary implementation.

Responsibilities:

- Workspace creation.
- Installation mode enforcement.
- Spec Kit initialization.
- Repository download.
- Runtime synchronization.
- Workflow deployment.
- Runtime validation.
- Installation reporting.

### bootstrap-grm-e2e.bat

Convenience wrapper.

Responsibilities:

- Invoke PowerShell safely.
- Apply ExecutionPolicy Bypass only to the launched process.
- Forward all installer parameters.

---

## 3. Design Goals

The bootstrap installer was designed to satisfy the following principles:

### Repeatability

The same inputs must produce the same validated result.

### Governance Preservation

GRM governance controls must remain active after installation.

### No Fork Strategy

The installer must preserve compatibility with standard Spec Kit.

### Runtime Preservation

Native Spec Kit runtime assets must not be removed unnecessarily.

### Workflow Preservation

Native workflows must be preserved.

### Traceability

Every installation must generate verifiable evidence.

---

## 4. Installation Modes

### FailIfExists (Default)

Safe execution mode.

If the target directory already exists, the installer stops.

Example:

```powershell
.ootstrap-grm-e2e.bat -TargetName e2e-demo-01
```

Expected result:

```text
FAILED
Target directory already exists
```

Purpose:

- Prevent accidental deletion.
- Prevent unintended overwrites.
- Require explicit operator intent.

### CleanInstall

Creates a clean workspace.

If the destination exists, `-Force` is mandatory.

Example:

```powershell
.ootstrap-grm-e2e.bat `
  -TargetName e2e-demo-01 `
  -InstallMode CleanInstall `
  -Force
```

Validated behavior:

- Deletes existing target only when explicitly authorized.
- Creates clean workspace.
- Executes deterministic Spec Kit initialization.
- Deploys GRM customization.
- Performs runtime validation.

### UpdateExisting

Performs non-destructive update.

Example:

```powershell
.ootstrap-grm-e2e.bat `
  -TargetName e2e-demo-01 `
  -InstallMode UpdateExisting
```

Validated behavior:

- Preserves workspace.
- Does not execute `specify init`.
- Updates Source of Truth assets.
- Updates runtime.
- Updates workflows.
- Revalidates installation.

---

## 5. Installation Flow

### Phase 1 - Pre-Flight Validation

The installer validates:

```text
git
specify
installation mode
target workspace
```

### Phase 2 - Repository Acquisition

The installer clones:

```text
https://github.com/sesanchezromeu/grm-custom-spec-kit.git
```

into a temporary cache.

### Phase 3 - Spec Kit Initialization

Executed only during:

```text
CleanInstall
```

Command:

```powershell
specify init --here --integration copilot --script ps --force
```

### Phase 4 - Source of Truth Deployment

Installs:

```text
extensions/grm-corporate-workflow
presets/grm-corporate-governance
```

### Phase 5 - Runtime Synchronization

Updates:

```text
.github/agents
.github/prompts
```

while preserving native runtime content.

### Phase 6 - Workflow Deployment

Deploys:

```text
presets/grm-corporate-governance/workflows
```

into:

```text
.specify/workflows
```

### Phase 7 - Registry Merge

Synchronizes:

```text
.specify/workflows/workflow-registry.json
```

using additive merge logic.

### Phase 8 - Supporting Assets

Installs:

```text
docs/
samples/
.specify/memory/constitution.md
```

### Phase 9 - Validation

Performs runtime validation.

### Phase 10 - Reporting

Generates:

```text
installation-report.md
```

---

## 6. Workflow Deployment Model

### Source of Truth

```text
presets/grm-corporate-governance/workflows
```

### Runtime

```text
.specify/workflows
```

### Expected Result

```text
.specify/workflows
├── speckit
│   └── workflow.yml
├── grm
│   └── workflow.yml
└── workflow-registry.json
```

### Governance Requirement

The installer must:

- Preserve `speckit`.
- Deploy `grm`.
- Preserve future native workflows.

---

## 7. Workflow Registry Merge Strategy

The registry merge is additive.

### Preserved

```text
speckit
future native workflows
```

### Added or Updated

```text
grm
```

### Expected Registry Structure

```text
schema_version
workflows
 ├─ speckit
 └─ grm
```

A registry replacement strategy is not permitted because it could remove native workflows introduced by future Spec Kit releases.

---

## 8. Installation Report

Generated file:

```text
installation-report.md
```

Generated for:

- Successful executions.
- Failed executions.

### Included Information

- Status.
- Installation mode.
- Repository.
- Branch.
- Commit.
- Git version.
- Spec Kit version.
- Agents.
- Prompts.
- Workflows.
- Warnings.
- Errors.
- Missing items.

### Typical Success Indicators

```text
Status: SUCCESS
Missing Items: none
Warnings: none
Error Details: none
```

---

## 9. Validation Scenarios

### Scenario 1 - Clean Installation

Command:

```powershell
-InstallMode CleanInstall -Force
```

Expected:

```text
SUCCESS
```

### Scenario 2 - Non-Destructive Update

Command:

```powershell
-InstallMode UpdateExisting
```

Expected:

```text
SUCCESS
```

### Scenario 3 - Existing Directory Without Explicit Mode

Command:

```powershell
-TargetName existing-folder
```

Expected:

```text
FAILED
Target directory already exists
```

---

## 10. Runtime Validation

Validation confirms:

```text
.github
.specify
extensions
presets
workflow registry
workflow deployment
```

### Workflow Validation

Required:

```text
speckit workflow present
grm workflow present
registry contains speckit
registry contains grm
```

---

## 11. Troubleshooting

### Directory Already Exists

Use:

```text
UpdateExisting
```

or

```text
CleanInstall -Force
```

### Workflow Registry Validation Failure

Verify:

```text
workflow-registry.json
```

contains:

```text
speckit
grm
```

### Runtime Validation Failure

Review:

```text
installation-report.md
```

### Spec Kit Not Found

Validate:

```powershell
specify --version
```

### Git Not Found

Validate:

```powershell
git --version
```

---

## 12. Acceptance Criteria

The bootstrap installation is considered successful only when:

- Runtime validation passes.
- GRM workflow is deployed.
- Spec Kit workflow is preserved.
- Registry merge succeeds.
- Documentation is installed.
- Samples are installed.
- Constitution is installed.
- Installation report is generated.
- No blocking warnings remain.

---

## 13. Summary

The bootstrap installer provides:

```text
Safe installation
        ↓
Deterministic runtime creation
        ↓
GRM deployment
        ↓
Workflow synchronization
        ↓
Registry merge
        ↓
Runtime validation
        ↓
Installation evidence
```

The validated installation result must remain functionally equivalent to the manual installation model described in `docs/installation-guide.md`.
