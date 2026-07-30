# Bootstrap Installer

## Purpose

Portable Git-first installer for **GRM Custom Spec Kit**.

The bootstrap installer provides a repeatable, validated and governance-aligned mechanism to create or update a Spec Kit workspace with the GRM corporate customization applied.

The installer is designed to:

- Preserve compatibility with standard Spec Kit.
- Avoid maintaining a fork of Spec Kit.
- Keep a clear separation between Source of Truth and Runtime.
- Support both clean installations and non-destructive updates.
- Prevent accidental deletion of existing workspaces.
- Generate installation evidence through `installation-report.md`.

---

## Files

```text
bootstrap-grm-e2e.ps1
bootstrap-grm-e2e.bat
```

The BAT file is a lightweight wrapper that invokes the PowerShell script with the appropriate execution policy.

---

## Installation Modes

### FailIfExists (Default)

Safe mode.

If the target directory already exists, the installation is aborted.

Purpose:

- Prevent accidental data loss.
- Prevent unintended overwrites.
- Force the installer operator to make an explicit decision.

Example:

```powershell
.\bootstrap-grm-e2e.bat \
  -TargetName e2e-demo-01
```

Expected result if the directory already exists:

```text
FAILED
Target directory already exists...
```

---

### CleanInstall

Creates a clean workspace.

If the destination already exists, `-Force` is required.

Example:

```powershell
.\bootstrap-grm-e2e.bat \
  -TargetName e2e-demo-01 \
  -InstallMode CleanInstall \
  -Force
```

Behavior:

- Creates a fresh workspace.
- Initializes Spec Kit.
- Initializes Git.
- Applies GRM customization.
- Validates the resulting runtime.

---

### UpdateExisting

Updates an existing installation without recreating the workspace.

Example:

```powershell
.\bootstrap-grm-e2e.bat \
  -TargetName e2e-demo-01 \
  -InstallMode UpdateExisting
```

Behavior:

- Preserves the existing workspace.
- Does not execute `specify init`.
- Updates GRM source-of-truth assets.
- Updates runtime artifacts.
- Updates workflows.
- Revalidates the installation.

---

## Recommended Usage

### Clean Installation

```powershell
.\bootstrap-grm-e2e.bat \
  -TargetName e2e-demo-01 \
  -InstallMode CleanInstall \
  -Force
```

### Non-Destructive Update

```powershell
.\bootstrap-grm-e2e.bat \
  -TargetName e2e-demo-01 \
  -InstallMode UpdateExisting
```

### PowerShell Direct Execution

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\bootstrap-grm-e2e.ps1 \
  -TargetName e2e-demo-01 \
  -InstallMode CleanInstall \
  -Force
```

---

## What The Installer Does

### 1. Pre-Flight Validation

Validates:

- Git availability.
- Spec Kit availability.
- Target workspace policy.
- Installation mode.

---

### 2. Download Customization Source

The installer clones the GRM Custom Spec Kit repository.

Source repository:

```text
https://github.com/sesanchezromeu/grm-custom-spec-kit.git
```

---

### 3. Initialize Runtime (Clean Install Only)

Executes deterministic Spec Kit initialization:

```powershell
specify init --here --integration copilot --script ps --force
```

This avoids interactive menus and guarantees reproducible installations.

---

### 4. Apply Source of Truth Assets

Installs:

```text
extensions/grm-corporate-workflow
presets/grm-corporate-governance
```

These directories remain the authoritative definition of the customization.

---

### 5. Synchronize Copilot Runtime

Updates:

```text
.github/agents
.github/prompts
```

The installer performs a merge rather than replacing the runtime.

This preserves native Spec Kit capabilities introduced by future versions.

---

### 6. Install Corporate Workflows

Source:

```text
presets/grm-corporate-governance/workflows
```

Runtime destination:

```text
.specify/workflows
```

Installed workflows:

```text
speckit
grm
```

The installer:

- Copies corporate workflows.
- Preserves native workflows.
- Validates workflow deployment.

---

### 7. Merge Workflow Registry

The installer performs an additive merge of:

```text
.specify/workflows/workflow-registry.json
```

Goals:

- Preserve standard Spec Kit workflows.
- Add GRM workflows.
- Support future workflow additions.
- Avoid destructive registry replacement.

---

### 8. Install Supporting Assets

Installed assets:

```text
samples/
docs/
```

Also installs:

```text
.specify/memory/constitution.md
```

---

### 9. Runtime Validation

The installer validates:

```text
.github
.specify
extensions
presets
workflow-registry.json
workflow.yml files
```

Validation failures stop the installation.

---

### 10. Generate Installation Report

Output:

```text
installation-report.md
```

The report is generated for:

- Successful installations.
- Failed installations.

This ensures complete operational traceability.

---

## Source of Truth vs Runtime

### Source of Truth

```text
extensions/
presets/
```

Defines:

- Governance.
- Corporate commands.
- Corporate workflows.
- Prompts.
- Agents.

### Runtime

```text
.github/
.specify/
```

Contains executable artifacts used by Copilot and Spec Kit.

The installer synchronizes Source of Truth into Runtime.

---

## Expected Result

A successful installation should end with:

```text
[OK] Runtime validation passed
[OK] Installation report generated
[OK] Bootstrap completed
```

The generated workspace should contain:

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

## Troubleshooting

### Directory Already Exists

Use one of:

```powershell
-InstallMode UpdateExisting
```

or

```powershell
-InstallMode CleanInstall -Force
```

---

### Runtime Validation Failure

Review:

```text
installation-report.md
```

Check:

- Missing items.
- Warnings.
- Error details.

---

### Spec Kit Not Found

Ensure:

```powershell
specify --version
```

returns a valid version.

---

### Git Not Found

Ensure:

```powershell
git --version
```

returns a valid version.

---

## Notes

- Manual installation remains the reference installation model.
- Bootstrap automates the same validated process.
- Clean installation and update installation are both supported.
- The installer preserves standard Spec Kit behavior whenever possible.
- Workflow deployment is automated.
- Registry synchronization is additive and non-destructive.
- Installation evidence is captured in `installation-report.md`.
