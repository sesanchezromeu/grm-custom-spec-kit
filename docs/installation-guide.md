# GRM Custom Spec Kit - Installation Guide

## 1. Purpose

This guide explains how to install, validate, update and troubleshoot **GRM Custom Spec Kit** in a Spec Kit project.

It is intended for maintainers, technical leads or project owners responsible for preparing a repository before delivery teams execute the GRM corporate workflow.

This document covers installation and preparation only. Day-to-day execution of PBIs is documented in `docs/user-guide.md`.

Two installation approaches are supported:

1. **Manual installation**, which remains the reference process and the main troubleshooting model.
2. **Portable bootstrap installation**, available under `resources/bootstrap`, which automates the validated Git-first installation process.

Both approaches must produce the same repository structure, runtime behavior and governance controls.

---

## 2. Scope

This guide covers:

- Preparing a clean Spec Kit repository.
- Applying the GRM customization.
- Understanding Source of Truth vs Runtime.
- Validating the installed structure.
- Verifying corporate commands and governance guards.
- Using the portable bootstrap installer where appropriate.
- Updating the customization safely.
- Troubleshooting installation and runtime issues.

This guide does not cover:

- Functional PBI execution.
- Delivery workflow operation.
- Implementation guidance.
- Corporate governance rationale in depth.
- Internal architecture decisions.

Refer to:

- `docs/user-guide.md` for daily usage.
- `docs/architecture.md` for design and architectural principles.
- `docs/governance.md` for governance rules and rationale.
- `docs/maintenance.md` for long-term evolution and ownership.
- `docs/release-checklist.md` for release readiness validation.

---

## 3. Target Audience

| Audience | Responsibility |
|---|---|
| Maintainer | Install, validate and update the customization |
| Technical Lead | Ensure the repository is ready for project usage |
| Project Manager | Confirm the framework supports the agreed delivery process |
| Developer | Consume the installed workflow, not normally install it |
| Product Owner | Provide approved PBIs, not normally install the framework |

---

## 4. Installation Model

GRM Custom Spec Kit is installed on top of a standard Spec Kit project.

The customization does not modify Spec Kit core files directly. Instead, it extends and constrains Spec Kit through corporate extensions, presets and runtime artifacts.

### High-Level Model

```text
Standard Spec Kit Project
        ↓
Apply GRM Customization
        ↓
Validate Runtime
        ↓
Validate Governance
        ↓
Execute Corporate Workflow
```

### Supported Installation Paths

```text
Manual installation
        ↓
Reference process, useful for maintainers and troubleshooting

Portable bootstrap installation
        ↓
Automated Git-first setup for repeatable validation and onboarding
```

The bootstrap installer is not a replacement for understanding the installation model. It automates the same installation logic described in this guide.

---

## 5. Source of Truth vs Runtime

A correct installation requires understanding the difference between customization definition and execution runtime.

### Source of Truth

The authoritative definition of the GRM customization is stored in:

```text
extensions/
presets/
```

These directories define:

- Corporate commands.
- Corporate prompts.
- Corporate agents.
- Governance presets.
- Guardrails for standard Spec Kit commands.

### Runtime

Execution occurs through:

```text
.github/
.specify/
```

These directories contain:

- GitHub Copilot runtime files.
- Spec Kit runtime assets.
- Generated workflow state.
- Planning and implementation artifacts.

### Current Synchronization Model

At the current release stage, synchronization between Source of Truth and Runtime remains explicit and traceable.

```text
extensions + presets
        ↓
runtime synchronization
        ↓
.github + .specify
```

The portable bootstrap automates this synchronization during installation. The manual process remains documented because it improves transparency, validation and troubleshooting.

Future versions may further automate this model, but the architectural distinction between Source of Truth and Runtime must remain clear.

---

## 6. Prerequisites

Before installing GRM Custom Spec Kit, verify the following prerequisites.

### Required

- A clean repository prepared for Spec Kit usage.
- Spec Kit available in the local environment.
- Git available in the local environment.
- GitHub Copilot or compatible Copilot agent execution environment.
- Access to the GRM Custom Spec Kit Git repository.

### Recommended

- A clean working tree before applying the customization.
- A dedicated branch for installation or packaging updates.
- A known-good PBI sample for validation.
- Permission to update repository files.
- PowerShell available where the bootstrap installer is used.

---

## 7. Recommended Branching Strategy

Use a controlled branch when installing or updating the customization.

Example:

```powershell
git checkout -b chore/install-grm-custom-spec-kit
```

Recommended practices:

- Avoid installing directly on the main branch unless the repository is intentionally prepared as a validation workspace.
- Commit the clean Spec Kit baseline separately if needed.
- Commit the GRM customization separately.
- Commit validation fixes separately.
- Keep bootstrap or packaging changes separate from runtime behavior changes where possible.

This improves traceability and rollback capability.

---

## 8. Installation Approaches

### 8.1 Manual Installation

Manual installation is the reference process. It is useful when:

- validating how the framework is assembled;
- troubleshooting runtime issues;
- understanding the relationship between source and runtime;
- applying partial updates;
- preparing maintenance documentation.

The complete manual procedure is described in Section 9.

### 8.2 Portable Bootstrap Installation

A portable installer is available under:

```text
resources/bootstrap/
├── bootstrap-grm-e2e.bat
└── bootstrap-grm-e2e.ps1
```

The bootstrap installer:

- creates a clean validation or installation workspace;
- initializes Spec Kit in deterministic mode;
- pulls the GRM customization from the official Git repository;
- applies the corporate extension and governance preset;
- merges GRM runtime files into the generated Spec Kit runtime;
- preserves additional runtime files generated by the installed Spec Kit version;
- copies supporting assets such as `samples/` and `docs/`;
- applies the corporate constitution;
- validates the installed runtime;
- generates `installation-report.md`.

The bootstrap follows the same process as the manual installation. The expected result must be equivalent.

### 8.3 Bootstrap Usage

From the directory containing the bootstrap files:

```powershell
.\bootstrap-grm-e2e.bat -TargetName e2e-demo-01 -Force
```

Or using PowerShell directly:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\bootstrap-grm-e2e.ps1 -TargetName e2e-demo-01 -Force
```

If executed from the repository path where the bootstrap is versioned:

```powershell
.\resources\bootstrap\bootstrap-grm-e2e.bat -TargetName e2e-demo-01 -Force
```

The BAT wrapper is recommended for Windows environments because it can invoke PowerShell with `-ExecutionPolicy Bypass` for the current process only.

### 8.4 Bootstrap Parameters

| Parameter | Purpose |
|---|---|
| `-Root` | Root directory where the target workspace will be created |
| `-TargetName` | Name of the target workspace |
| `-SourceRepoUrl` | Git repository containing GRM Custom Spec Kit |
| `-Branch` | Branch to install from |
| `-Integration` | Spec Kit integration, normally `copilot` |
| `-ScriptType` | Script type, normally `ps` |
| `-Force` | Recreate target directory if it already exists |
| `-KeepSourceCache` | Preserve temporary Git cache for diagnostics |
| `-SkipGitInit` | Skip Git initialization in the target workspace |
| `-CreateBranch` | Create a branch in the target workspace |
| `-BranchName` | Branch name used when `-CreateBranch` is enabled |

### 8.5 Bootstrap Output

A successful bootstrap should produce messages equivalent to:

```text
[OK] Spec Kit initialized with integration=copilot and script=ps
[OK] Git repository initialized
[OK] GRM corporate workflow extension copied/merged
[OK] GRM corporate governance preset copied/merged
[OK] GRM runtime agents copied/merged
[OK] GRM governance override agents copied/merged
[OK] GRM runtime prompts copied/merged
[OK] GRM samples copied/merged
[OK] GRM docs copied/merged
[OK] GRM corporate constitution copied
[OK] Runtime validation passed
[OK] Installation report generated
[OK] Bootstrap completed
```

The target workspace should include an `installation-report.md` file.

---

## 9. Manual Installation Procedure

### Step 1 - Prepare a Clean Repository

Start from a repository where the Spec Kit installation can be initialized safely.

Verify repository status:

```powershell
git status
```

Expected result:

```text
nothing to commit, working tree clean
```

If starting from a completely empty directory, a Git repository may not yet exist and `git status` will fail. In that case either initialize Git first:

```powershell
git init
```

or proceed directly with Spec Kit initialization:

```powershell
specify init --here
```

If the repository is not clean, commit or stash local changes before continuing.

### Step 2 - Initialize Spec Kit

Create or initialize the Spec Kit structure:

```powershell
specify init --here --integration copilot --script ps --force
```

For manual exploratory installation, this may also be performed with:

```powershell
specify init --here
```

However, deterministic installation should explicitly provide integration and script type to avoid interactive selection.

After initialization, the repository should contain Spec Kit runtime assets.

Minimum expected structure:

```text
.specify/
```

Observed structure in validated installations:

```text
.github/
.specify/
.vscode/
```

Additional runtime assets may include:

```text
.specify/integrations/
.specify/scripts/
.specify/templates/
.specify/workflows/
.github/agents/
.github/prompts/
```

The exact runtime structure may evolve between Spec Kit versions.

### Step 3 - Apply GRM Customization Source of Truth

Copy the formal GRM customization into the repository.

Required directories:

```text
extensions/grm-corporate-workflow/
presets/grm-corporate-governance/
```

These directories are the source of truth for the GRM customization.

Do not treat `.github` as the long-term authoring location for corporate customization. `.github` is runtime.

### Step 4 - Apply Runtime Files

Copy or synchronize the validated runtime files into:

```text
.github/
```

The runtime must include the corporate commands and governance overrides required by Copilot execution.

Expected runtime categories:

```text
.github/agents/
.github/prompts/
```

Exact structure may evolve as Spec Kit and Copilot conventions evolve, but the installed runtime must expose the required corporate commands.

Runtime synchronization should follow the Runtime Merge Strategy defined in Section 14.

### Step 5 - Preserve Spec Kit Runtime

Do not delete `.github` or `.specify` after initialization.

`.specify` is required by native Spec Kit commands such as:

```text
speckit.plan
speckit.tasks
speckit.implement
```

GRM Custom Spec Kit extends native Spec Kit behavior. It does not replace the Spec Kit runtime.

### Step 6 - Add Documentation and Samples

Install official documentation:

```text
docs/
├── architecture.md
├── governance.md
├── installation-guide.md
├── maintenance.md
├── release-checklist.md
└── user-guide.md
```

Install validation samples:

```text
samples/
└── PBI-POC-01-calculadora-iva.md
```

Samples are validation assets. They are not part of the runtime.

Session history and working logs must not be distributed as part of the product installation. If a local `docs/sessions/` folder exists, it should remain local and excluded from the Git repository.

---

## 10. Expected Repository Structure

A correctly prepared repository should contain:

```text
.github/
.specify/
.vscode/
docs/
extensions/
presets/
samples/
README.md
```

### Directory Responsibilities

| Directory | Responsibility |
|---|---|
| `.github/` | Copilot runtime |
| `.specify/` | Spec Kit runtime and execution state |
| `.vscode/` | Local editor recommendations and settings |
| `docs/` | Official product documentation |
| `extensions/` | Corporate workflow source of truth |
| `presets/` | Governance source of truth |
| `samples/` | Validation examples |
| `resources/bootstrap/` | Optional portable bootstrap installer in the source repository |

The `resources/bootstrap/` directory is part of the GRM Custom Spec Kit source repository. It is not necessarily required in every installed delivery workspace unless the installer itself is being distributed with that workspace.

---

## 11. Installation Validation Checklist

Run this checklist after installation.

### Repository Structure

| Check | Expected Result |
|---|---|
| `.github/` exists | Yes |
| `.specify/` exists | Yes |
| `extensions/grm-corporate-workflow/` exists | Yes |
| `presets/grm-corporate-governance/` exists | Yes |
| `docs/` exists | Yes |
| `samples/` exists | Yes |
| `docs/sessions/` absent from installed workspace | Yes |

### Documentation Files

| Check | Expected Result |
|---|---|
| `docs/architecture.md` exists | Yes |
| `docs/governance.md` exists | Yes |
| `docs/installation-guide.md` exists | Yes |
| `docs/maintenance.md` exists | Yes |
| `docs/release-checklist.md` exists | Yes |
| `docs/user-guide.md` exists | Yes |

### Corporate Commands

The following corporate commands must be available in the Copilot execution environment:

```text
corp.erase
corp.load
corp.assess
corp.plan
corp.doc
```

### Protected or Blocked Spec Kit Commands

The following behavior must be enforced:

| Command | Expected Behavior |
|---|---|
| `speckit.specify` | Blocked |
| `speckit.clarify` | Blocked |
| `speckit.plan` | Allowed only after corporate bootstrap |
| `speckit.tasks` | Allowed after planning |
| `speckit.implement` | Allowed after tasks |

---

## 12. Functional Smoke Test

After installation, before executing the functional smoke test, perform governance validation:

```text
/speckit.specify
/speckit.clarify
/speckit.plan
```

Expected results:

- `speckit.specify` blocked.
- `speckit.clarify` blocked.
- `speckit.plan` blocked until corporate bootstrap exists.

Only continue with the smoke test after governance controls have been validated successfully.

Run a minimal validation using a sample PBI.

Recommended validation flow:

```text
/corp.erase
/corp.load --file samples/PBI-POC-01-calculadora-iva.md
/corp.assess
/corp.plan
/speckit.plan
/speckit.tasks
/speckit.implement
/corp.doc
```

Expected result:

```text
END-TO-END VALIDATED
```

Expected artifacts:

```text
.specify/memory/active-pbi.md
features/<feature>/spec.md
features/<feature>/delivery-doc.md
```

Depending on the selected constitution and implementation flow, additional artifacts may be generated, such as:

```text
features/<feature>/plan.md
features/<feature>/research.md
features/<feature>/data-model.md
features/<feature>/quickstart.md
features/<feature>/tasks.md
frontend/
frontend/evidence.md
```

If the validation fails, do not continue with real PBIs until the issue is resolved.

---

## 13. Governance Validation

Installation is not complete until governance behavior is validated.

### Validate `speckit.specify` Block

Try to execute:

```text
/speckit.specify
```

Expected result:

```text
Blocked by corporate governance
```

### Validate `speckit.clarify` Block

Try to execute:

```text
/speckit.clarify
```

Expected result:

```text
Blocked by corporate governance
```

### Validate `speckit.plan` Guard

Try to execute `speckit.plan` before `corp.plan`.

Expected result:

```text
Planning blocked because corporate bootstrap is missing
```

Then execute:

```text
/corp.load --file samples/PBI-POC-01-calculadora-iva.md
/corp.assess
/corp.plan
/speckit.plan
```

Expected result:

```text
Planning allowed
```

---

## 14. Runtime Synchronization Validation

Because Source of Truth and Runtime are synchronized explicitly, every installation or update must verify alignment.

### Runtime Merge Strategy

When applying the GRM customization, do not replace the entire `.github` runtime generated by Spec Kit.

Recommended process:

1. Execute:

```powershell
specify init --here --integration copilot --script ps --force
```

2. Preserve the runtime generated by Spec Kit.
3. Copy GRM corporate runtime files:

```text
corp.assess
corp.doc
corp.erase
corp.load
corp.plan
```

4. Apply governed Spec Kit command behavior:

```text
speckit.specify
speckit.clarify
speckit.plan
speckit.tasks
speckit.implement
```

5. Preserve any additional native commands provided by the installed Spec Kit version.

Example native commands observed in previous Spec Kit versions:

```text
speckit.analyze
speckit.checklist
speckit.converge
speckit.taskstoissues
```

A full replacement of `.github` may remove native functionality introduced in newer versions of Spec Kit.

### Source and Runtime Alignment

Validate that corporate command definitions are consistent between:

```text
extensions/grm-corporate-workflow/
.github/
```

Validate that governance presets are reflected in runtime behavior:

```text
presets/grm-corporate-governance/
.github/
```

Minimum expected alignment:

| Source of Truth | Runtime Expectation |
|---|---|
| `corp.erase` extension | Runtime command available |
| `corp.load` extension | Runtime command available |
| `corp.assess` extension | Runtime command available |
| `corp.plan` extension | Runtime command available |
| `corp.doc` extension | Runtime command available |
| Governance preset | `speckit.specify` blocked |
| Governance preset | `speckit.clarify` blocked |
| Governance preset | `speckit.plan` guarded |

---

## 15. Installation Report

When using the portable bootstrap, an `installation-report.md` file is generated in the target workspace.

The report should include:

- execution status;
- Git and Spec Kit versions where available;
- initialization command;
- GRM Custom Spec Kit source repository;
- branch;
- installed commit;
- runtime agents;
- runtime prompts;
- supporting assets;
- copied constitution;
- missing items;
- warnings.

Expected supporting assets:

| Asset | Expected Result |
|---|---|
| `samples` | Copied |
| `docs` | Copied |

If the report identifies missing items, warnings or failed validation, do not approve the installation until reviewed.

---

## 16. Upgrade Procedure

Use this procedure when updating GRM Custom Spec Kit in an existing repository.

### Step 1 - Create Upgrade Branch

```powershell
git checkout -b chore/update-grm-custom-spec-kit
```

### Step 2 - Backup Local Changes

Review local status:

```powershell
git status
```

Commit or stash local changes before replacing customization files.

### Step 3 - Update Source of Truth

Update:

```text
extensions/grm-corporate-workflow/
presets/grm-corporate-governance/
```

### Step 4 - Synchronize Runtime

Update corresponding runtime files in:

```text
.github/
```

### Step 5 - Update Supporting Assets

Update official documentation and samples where applicable:

```text
docs/
samples/
```

Do not distribute local session history or non-product working logs.

### Step 6 - Validate Governance

Re-run blocked and guarded command tests:

```text
speckit.specify blocked
speckit.clarify blocked
speckit.plan guarded
```

### Step 7 - Execute Smoke Test

Run the complete validation flow with a sample PBI.

### Step 8 - Commit Changes

Recommended commit sequence:

```powershell
git add .
git commit -m "chore: update GRM Custom Spec Kit packaging"
```

---

## 17. Rollback Procedure

If installation or upgrade fails, rollback should be explicit and controlled.

### Option 1 - Revert Working Tree Changes

If changes are not committed:

```powershell
git restore .
```

### Option 2 - Revert Commit

If changes were committed:

```powershell
git revert <commit-sha>
```

### Option 3 - Restore Last Known Good Branch

If validation cannot be recovered quickly, return to the last known valid branch.

Do not continue with real PBIs on a partially validated installation.

---

## 18. Troubleshooting

### PowerShell Script Cannot Be Executed Because It Is Not Signed

Possible cause:

- Local execution policy requires signed scripts, for example `AllSigned`.

Validate with:

```powershell
Get-ExecutionPolicy -List
```

Recommended action:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\bootstrap-grm-e2e.ps1 -TargetName e2e-demo-01 -Force
```

or use the BAT wrapper:

```powershell
.\bootstrap-grm-e2e.bat -TargetName e2e-demo-01 -Force
```

The bypass applies to the launched PowerShell process only.

### Corporate Commands Not Available

Possible causes:

- Runtime files not copied to `.github`.
- Copilot environment not refreshed.
- Wrong repository opened in the editor.
- Command file naming mismatch.

Recommended actions:

- Verify `.github` structure.
- Verify agent and prompt files exist.
- Restart the Copilot or editor session.
- Re-run installation validation.

### `speckit.specify` or `speckit.clarify` Not Blocked

Possible causes:

- Governance preset not synchronized to runtime.
- Runtime still contains standard behavior.
- Wrong command file loaded by Copilot.

Recommended actions:

- Verify `presets/grm-corporate-governance` exists.
- Verify runtime contains blocking behavior.
- Compare preset source with runtime command behavior.
- Do not approve installation until the block is effective.

### `speckit.plan` Runs Without `corp.plan`

This is a critical governance failure.

Possible causes:

- Corporate guard missing.
- Runtime agent not updated.
- Bootstrap validation markers not checked.

Recommended actions:

- Stop validation.
- Verify `speckit.plan` runtime guard.
- Verify preset source definition.
- Re-synchronize runtime.
- Re-test before continuing.

### `corp.load` Does Not Create `active-pbi.md`

Possible causes:

- Invalid PBI path.
- Missing write permissions.
- Runtime cleanup failed.
- File format issue.

Recommended actions:

- Verify file exists.
- Verify path is relative to repository root.
- Verify `.specify/memory/` exists or can be created.
- Re-run `corp.erase` and then `corp.load`.

### `corp.plan` Does Not Generate `spec.md`

Possible causes:

- `corp.load` was not executed successfully.
- `active-pbi.md` missing.
- PBI incomplete or not assessable.
- Governance sequence not respected.

Recommended actions:

- Verify `.specify/memory/active-pbi.md`.
- Run `corp.assess`.
- Resolve readiness issues.
- Re-run `corp.plan`.

### `delivery-doc.md` Not Generated During Smoke Test

Possible causes:

- Implementation flow incomplete.
- Feature folder not generated.
- `corp.doc` runtime missing or outdated.
- Validation artifacts unavailable.

Recommended actions:

- Verify `speckit.implement` completed.
- Verify `features/<feature>/` exists.
- Verify `corp.doc` is available.
- Re-run `corp.doc`.

### Runtime Appears Outdated

Possible causes:

- Source of Truth updated but runtime not synchronized.
- Duplicate files exist in multiple locations.
- Editor session cached previous commands.

Recommended actions:

- Compare `extensions/` and `.github/`.
- Compare `presets/` and runtime behavior.
- Restart Copilot or editor session.
- Re-run governance validation.

### Documentation Folder Missing

Possible causes:

- Manual installation did not copy `docs/`.
- Bootstrap source repository does not contain official docs.
- Installation used an outdated branch.

Recommended actions:

- Verify the source repository contains:

```text
docs/architecture.md
docs/governance.md
docs/installation-guide.md
docs/maintenance.md
docs/release-checklist.md
docs/user-guide.md
```

- Verify the bootstrap report shows `docs` copied.
- Re-run installation from the expected branch.

---

## 19. Installation Acceptance Criteria

An installation can be accepted only when all the following criteria are met.

| Area | Acceptance Criteria |
|---|---|
| Structure | Required directories exist |
| Runtime | Corporate commands are available |
| Governance | Blocked commands are blocked |
| Guard | `speckit.plan` requires `corp.plan` |
| Workflow | Smoke test completes successfully |
| Documentation | Official documentation is installed and README map is updated |
| Samples | Validation samples are installed |
| Git | Changes are committed in a controlled branch where applicable |
| Report | Bootstrap installations generate `installation-report.md` |

---

## 20. Handover Checklist

Before handing the repository to delivery teams, confirm:

- Installation validation completed.
- Smoke test completed.
- Governance validation completed.
- Known limitations communicated.
- README documentation map updated.
- User Guide available.
- Architecture Guide available.
- Governance Guide available.
- Maintenance Guide available.
- Release Checklist available.
- Samples available.
- Maintainer identified.
- Installation branch merged or ready for review.

---

## 21. Known Limitations

Current limitations:

- Runtime synchronization remains an explicit architectural concern and must be validated after changes.
- PBI source is currently markdown-based.
- Azure DevOps integration is not yet available.
- MCP integration is not yet available.
- Additional Spec Kit commands may require future governance review.
- Copilot UI may display internal execution progress messages.
- Copilot and Spec Kit runtime conventions may evolve in future versions.

Current installation capabilities:

- Manual installation remains available and documented as the reference process.
- Portable Git-first bootstrap installation is available under `resources/bootstrap`.
- The bootstrap installer is primarily intended for repeatable validation, onboarding and controlled workspace preparation.
- The bootstrap installer does not eliminate the need to understand the manual process for maintenance and troubleshooting.

---

## 22. Recommended Next Steps After Installation

Once installation is validated:

1. Read `docs/user-guide.md`.
2. Execute the workflow with a known sample PBI.
3. Review `docs/governance.md` before onboarding users.
4. Review `docs/maintenance.md` before modifying prompts, agents, presets or runtime files.
5. Review `docs/architecture.md` before changing the Source of Truth vs Runtime model.
6. Use `docs/release-checklist.md` before publishing a validated baseline.
7. Create a release or tag for the validated installation baseline.

---

## 23. Summary

GRM Custom Spec Kit installation is successful when:

- The repository contains both Source of Truth and Runtime layers.
- Corporate commands are available.
- Blocked commands are actually blocked.
- `speckit.plan` is protected by the corporate bootstrap guard.
- Official documentation is available locally.
- Validation samples are available locally.
- The complete validation workflow runs successfully.
- The repository is ready for iterative PBI-driven delivery.

The installation model is considered aligned when manual installation and portable bootstrap installation produce equivalent structure, behavior and governance controls.
