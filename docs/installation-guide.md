# GRM Custom Spec Kit - Installation Guide

Document Version: 1.1  
Last Updated: 2026-07-30  
Status: Release Candidate  
Scope: Manual installation and installation validation reference

## 1. Purpose

This guide explains how to install, validate, update and troubleshoot **GRM Custom Spec Kit** in a Spec Kit project using the **manual reference process**.

It is intended for maintainers, technical leads, architects or project owners responsible for preparing a repository before delivery teams execute the GRM corporate workflow.

This document focuses on:

- Preparing a clean Spec Kit repository.
- Applying the GRM customization manually.
- Understanding Source of Truth vs Runtime.
- Preserving compatibility with standard Spec Kit.
- Synchronizing runtime artifacts safely.
- Installing corporate workflows.
- Validating governance behavior.
- Troubleshooting installation and runtime issues.
- Supporting controlled upgrades and handover.

Automated or unattended installation using the portable bootstrap installer is documented separately in:

```text
resources/bootstrap/bootstrap-installation-guide.md
```

The bootstrap installer automates the same validated installation model described here, but it is not the source of architectural truth. This manual guide remains the reference for understanding, troubleshooting and maintaining the installation model.

## 2. Scope

### 2.1 Covered By This Guide

This guide covers:

- Preparing a clean repository for Spec Kit usage.
- Initializing the Spec Kit runtime.
- Applying GRM Custom Spec Kit Source of Truth assets.
- Synchronizing Copilot runtime files.
- Deploying GRM corporate workflows.
- Preserving native Spec Kit runtime assets.
- Validating installed repository structure.
- Verifying corporate commands.
- Verifying governance guards.
- Running a functional smoke test.
- Updating an existing installation safely.
- Rolling back failed installations or upgrades.
- Troubleshooting common installation and runtime issues.

### 2.2 Not Covered By This Guide

This guide does not cover:

- Day-to-day PBI execution.
- Functional delivery flow operation.
- Detailed implementation guidance.
- Corporate governance rationale in depth.
- Internal architecture evolution decisions.
- Automated bootstrap command reference.
- Installer parameter reference.

Refer to:

```text
docs/user-guide.md
docs/architecture.md
docs/governance.md
docs/maintenance.md
docs/release-checklist.md
resources/bootstrap/bootstrap-installation-guide.md
```

## 3. Target Audience

| Audience | Responsibility |
|---|---|
| Maintainer | Install, validate, update and troubleshoot the customization. |
| Technical Lead | Ensure the repository is correctly prepared before team usage. |
| Architect | Validate architectural alignment, governance and compatibility with Spec Kit. |
| Project Manager | Confirm the framework supports the agreed delivery process. |
| Developer | Consume the installed workflow, normally not install it. |
| Product Owner | Provide approved PBIs, normally not install the framework. |

## 4. Installation Model

GRM Custom Spec Kit is installed on top of a standard Spec Kit project.

The customization does **not** modify Spec Kit core files directly. Instead, it extends and constrains Spec Kit through:

- Corporate workflow extensions.
- Governance presets.
- Copilot agent and prompt runtime files.
- Spec Kit workflow definitions.
- Runtime guardrails.

### 4.1 High-Level Model

```text
Standard Spec Kit Project
        ↓
Apply GRM Customization
        ↓
Synchronize Runtime
        ↓
Install Corporate Workflows
        ↓
Validate Runtime
        ↓
Validate Governance
        ↓
Execute Corporate Workflow
```

### 4.2 Reference Installation Principle

Manual installation is the reference process because it makes the relationship between Source of Truth, Runtime and validation explicit.

Automated installation must remain functionally equivalent to the manual process.

## 5. Source of Truth vs Runtime

A correct installation requires understanding the difference between customization definition and execution runtime.

### 5.1 Source of Truth

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
- Corporate workflow definitions.
- Corporate workflow registry contributions.

Source of Truth files should be treated as the formal maintainable definition of the GRM customization.

### 5.2 Runtime

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
- Runtime workflow definitions.
- Runtime workflow registry.

Runtime files are necessary for execution, but they should not be treated as the only long-term authoring location for corporate customization.

### 5.3 Synchronization Model

At the current release stage, synchronization between Source of Truth and Runtime remains explicit and traceable.

```text
extensions + presets
        ↓
runtime synchronization
        ↓
.github + .specify
```

The architectural distinction between Source of Truth and Runtime must remain clear even if synchronization is automated by tooling.

## 6. Prerequisites

Before installing GRM Custom Spec Kit, verify the following prerequisites.

### 6.1 Required

- A clean repository prepared for Spec Kit usage.
- Spec Kit available in the local environment.
- Git available in the local environment.
- GitHub Copilot or compatible Copilot agent execution environment.
- Access to the GRM Custom Spec Kit source repository or package.
- Permission to update repository files.

### 6.2 Recommended

- A clean working tree before applying the customization.
- A dedicated branch for installation or packaging updates.
- A known-good PBI sample for validation.
- A controlled validation workspace before updating a real delivery repository.
- Access to the release checklist.
- Agreement on the target Spec Kit version being validated.

## 7. Recommended Branching Strategy

Use a controlled branch when installing or updating the customization.

Example:

```powershell
git checkout -b chore/install-grm-custom-spec-kit
```

Recommended practices:

- Avoid installing directly on `main` unless the repository is intentionally prepared as a validation workspace.
- Commit the clean Spec Kit baseline separately if needed.
- Commit the GRM customization separately.
- Commit validation fixes separately.
- Keep packaging changes separate from runtime behavior changes where possible.
- Keep documentation updates traceable to installation or release changes.

This improves reviewability, traceability and rollback capability.

## 8. Manual Installation Procedure

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

If starting from a completely empty directory, a Git repository may not yet exist and `git status` may fail. In that case either initialize Git first:

```powershell
git init
```

or proceed directly with Spec Kit initialization if that is the intended flow.

If the repository is not clean, commit or stash local changes before continuing.

### Step 2 - Initialize Spec Kit

Create or initialize the Spec Kit structure:

```powershell
specify init --here --integration copilot --script ps --force
```

For exploratory manual installation, this may also be performed with:

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

These directories are the Source of Truth for the GRM customization.

Do not treat `.github` as the long-term authoring location for corporate customization. `.github` is runtime.

### Step 4 - Apply Copilot Runtime Files

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

The installed runtime must expose the required corporate commands and governed Spec Kit commands.

Runtime synchronization must follow the merge strategy defined in this guide.

### Step 5 - Preserve Spec Kit Runtime

Do not delete `.github` or `.specify` after initialization.

`.specify` is required by native Spec Kit commands such as:

```text
speckit.plan
speckit.tasks
speckit.implement
```

GRM Custom Spec Kit extends native Spec Kit behavior. It does not replace the Spec Kit runtime.

### Step 6 - Install Corporate Workflows

Install corporate workflows from:

```text
presets/grm-corporate-governance/workflows/
```

to:

```text
.specify/workflows/
```

Expected corporate workflow path:

```text
.specify/workflows/grm/workflow.yml
```

The standard Spec Kit workflow must remain available:

```text
.specify/workflows/speckit/workflow.yml
```

Do not overwrite the entire `.specify/workflows` directory with only corporate assets. The correct behavior is additive.

### Step 7 - Merge Workflow Registry

Synchronize the workflow registry:

```text
.specify/workflows/workflow-registry.json
```

Expected logical result:

```text
workflow-registry.json
└── workflows
    ├── speckit
    └── grm
```

The merge must preserve native Spec Kit workflows and add or update GRM workflows.

If future Spec Kit versions introduce additional workflows, they must not be removed by the GRM installation process.

### Step 8 - Add Documentation and Samples

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

Samples are validation assets. They are not part of the execution runtime.

Session history and working logs must not be distributed as part of the product installation. If a local `docs/sessions/` folder exists, it should remain local and excluded from the public repository.

### Step 9 - Install Corporate Constitution

Ensure the corporate constitution is available in runtime memory.

Expected runtime path:

```text
.specify/memory/constitution.md
```

The constitution must reflect the approved GRM governance model for the target release.

### Step 10 - Validate Installation

After all assets are copied and synchronized, execute the validation checklist described later in this guide.

Do not approve the installation until structure, runtime, workflows and governance behavior are validated.

## 9. Expected Repository Structure

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

The source repository may also contain:

```text
resources/bootstrap/
```

This directory contains the portable installer and supporting bootstrap documentation. It is part of the GRM Custom Spec Kit source repository, but it is not necessarily required in every installed delivery workspace unless the installer itself is being distributed with that workspace.

### 9.1 Directory Responsibilities

| Directory | Responsibility |
|---|---|
| `.github/` | Copilot runtime. |
| `.specify/` | Spec Kit runtime and execution state. |
| `.vscode/` | Local editor recommendations and settings. |
| `docs/` | Official product documentation. |
| `extensions/` | Corporate workflow source of truth. |
| `presets/` | Governance and workflow source of truth. |
| `samples/` | Validation examples. |
| `resources/bootstrap/` | Optional portable bootstrap installer in the source repository. |

## 10. Installation Validation Checklist

Run this checklist after installation.

### 10.1 Repository Structure

| Check | Expected Result |
|---|---|
| `.github/` exists | Yes |
| `.specify/` exists | Yes |
| `extensions/grm-corporate-workflow/` exists | Yes |
| `presets/grm-corporate-governance/` exists | Yes |
| `presets/grm-corporate-governance/workflows/` exists | Yes |
| `.specify/workflows/` exists | Yes |
| `.specify/workflows/speckit/workflow.yml` exists | Yes |
| `.specify/workflows/grm/workflow.yml` exists | Yes |
| `.specify/workflows/workflow-registry.json` exists | Yes |
| `docs/` exists | Yes |
| `samples/` exists | Yes |
| `docs/sessions/` absent from installed workspace | Yes |

### 10.2 Documentation Files

| Check | Expected Result |
|---|---|
| `docs/architecture.md` exists | Yes |
| `docs/governance.md` exists | Yes |
| `docs/installation-guide.md` exists | Yes |
| `docs/maintenance.md` exists | Yes |
| `docs/release-checklist.md` exists | Yes |
| `docs/user-guide.md` exists | Yes |

### 10.3 Runtime Commands

The following corporate commands must be available in the Copilot execution environment:

```text
corp.erase
corp.load
corp.assess
corp.plan
corp.doc
```

The following native Spec Kit commands may remain available, governed or preserved according to GRM rules:

```text
speckit.plan
speckit.tasks
speckit.implement
```

Additional native commands introduced by Spec Kit may also exist and should not be removed without governance review.

### 10.4 Protected or Blocked Spec Kit Commands

| Command | Expected Behavior |
|---|---|
| `speckit.specify` | Blocked. |
| `speckit.clarify` | Blocked. |
| `speckit.plan` | Allowed only after corporate bootstrap is available. |
| `speckit.tasks` | Allowed after planning. |
| `speckit.implement` | Allowed after tasks. |

### 10.5 Workflow Registry Validation

Open:

```text
.specify/workflows/workflow-registry.json
```

Validate that it contains:

```text
speckit
grm
```

Expected logical structure:

```text
schema_version
workflows
  speckit
  grm
```

If `speckit` is missing, native workflow preservation has failed.

If `grm` is missing, corporate workflow deployment has failed.

## 11. Functional Smoke Test

After installation, before executing the functional smoke test, perform governance validation.

Governance validation commands:

```text
/speckit.specify
/speckit.clarify
/speckit.plan
```

Expected results:

- `speckit.specify` is blocked.
- `speckit.clarify` is blocked.
- `speckit.plan` is blocked until the corporate bootstrap exists.

Only continue with the smoke test after governance controls have been validated successfully.

### 11.1 Recommended Smoke Test Flow

Run a minimal validation using a known-good sample PBI.

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

### 11.2 Expected Artifacts

Minimum expected artifacts:

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

## 12. Governance Validation

Installation is not complete until governance behavior is validated.

### 12.1 Validate `speckit.specify` Block

Try to execute:

```text
/speckit.specify
```

Expected result:

```text
Blocked by corporate governance
```

### 12.2 Validate `speckit.clarify` Block

Try to execute:

```text
/speckit.clarify
```

Expected result:

```text
Blocked by corporate governance
```

### 12.3 Validate `speckit.plan` Guard

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

## 13. Runtime Synchronization Validation

Because Source of Truth and Runtime are synchronized explicitly, every installation or update must verify alignment.

### 13.1 Runtime Merge Strategy

When applying the GRM customization, do not replace the entire `.github` runtime generated by Spec Kit.

Recommended process:

1. Execute Spec Kit initialization.
2. Preserve the runtime generated by Spec Kit.
3. Copy or merge GRM corporate runtime files.
4. Apply governed Spec Kit command behavior.
5. Preserve any additional native commands provided by the installed Spec Kit version.

Corporate runtime commands expected:

```text
corp.assess
corp.doc
corp.erase
corp.load
corp.plan
```

Governed Spec Kit command behavior expected:

```text
speckit.specify
speckit.clarify
speckit.plan
speckit.tasks
speckit.implement
```

Example native commands observed in previous Spec Kit versions:

```text
speckit.analyze
speckit.checklist
speckit.converge
speckit.taskstoissues
```

A full replacement of `.github` may remove native functionality introduced in newer versions of Spec Kit.

### 13.2 Workflow Runtime Merge Strategy

When applying GRM workflows, do not replace the entire `.specify/workflows` directory.

Recommended process:

1. Preserve `.specify/workflows/speckit/workflow.yml`.
2. Copy `.specify/workflows/grm/workflow.yml` from the GRM preset.
3. Merge `workflow-registry.json` additively.
4. Validate both `speckit` and `grm` exist in the registry.

Expected model:

```text
presets/grm-corporate-governance/workflows
        ↓
manual workflow synchronization
        ↓
.specify/workflows
```

### 13.3 Source and Runtime Alignment

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

Validate that workflow definitions are reflected in runtime:

```text
presets/grm-corporate-governance/workflows/
.specify/workflows/
```

Minimum expected alignment:

| Source of Truth | Runtime Expectation |
|---|---|
| `corp.erase` extension | Runtime command available. |
| `corp.load` extension | Runtime command available. |
| `corp.assess` extension | Runtime command available. |
| `corp.plan` extension | Runtime command available. |
| `corp.doc` extension | Runtime command available. |
| Governance preset | `speckit.specify` blocked. |
| Governance preset | `speckit.clarify` blocked. |
| Governance preset | `speckit.plan` guarded. |
| GRM workflow preset | `grm` workflow installed. |
| Spec Kit runtime | `speckit` workflow preserved. |

## 14. Installation Evidence

Manual installations should leave explicit evidence of validation.

Recommended evidence:

- Installation branch name.
- Source commit or package version installed.
- Spec Kit version.
- Validation date.
- Runtime structure validation result.
- Workflow registry validation result.
- Governance validation result.
- Smoke test result.
- Known warnings or limitations.

When using automated installation, `installation-report.md` captures this information automatically. For manual installation, maintainers should capture equivalent evidence in the relevant validation notes or release checklist.

## 15. Upgrade Procedure

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

### Step 4 - Synchronize Copilot Runtime

Update corresponding runtime files in:

```text
.github/
```

Preserve native Spec Kit runtime files unless a governance decision explicitly requires a change.

### Step 5 - Synchronize Workflows

Update corporate workflow runtime files in:

```text
.specify/workflows/grm/
```

Merge registry updates into:

```text
.specify/workflows/workflow-registry.json
```

Validate that `speckit` is preserved and `grm` is present.

### Step 6 - Update Supporting Assets

Update official documentation and samples where applicable:

```text
docs/
samples/
```

Do not distribute local session history or non-product working logs.

### Step 7 - Validate Governance

Re-run blocked and guarded command tests:

```text
speckit.specify blocked
speckit.clarify blocked
speckit.plan guarded
```

### Step 8 - Execute Smoke Test

Run the complete validation flow with a sample PBI.

### Step 9 - Commit Changes

Recommended commit sequence:

```powershell
git add .
git commit -m "chore: update GRM Custom Spec Kit packaging"
```

## 16. Rollback Procedure

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

## 17. Troubleshooting

### 17.1 Corporate Commands Not Available

Possible causes:

- Runtime files not copied to `.github`.
- Copilot environment not refreshed.
- Wrong repository opened in the editor.
- Command file naming mismatch.

Recommended actions:

- Verify `.github/agents/` exists.
- Verify `.github/prompts/` exists.
- Verify corporate agent and prompt files exist.
- Restart the Copilot or editor session.
- Re-run installation validation.

### 17.2 `speckit.specify` or `speckit.clarify` Not Blocked

Possible causes:

- Governance preset not synchronized to runtime.
- Runtime still contains standard behavior.
- Wrong command file loaded by Copilot.

Recommended actions:

- Verify `presets/grm-corporate-governance/` exists.
- Verify runtime contains blocking behavior.
- Compare preset source with runtime command behavior.
- Do not approve installation until the block is effective.

### 17.3 `speckit.plan` Runs Without `corp.plan`

This is a critical governance failure.

Possible causes:

- Corporate guard missing.
- Runtime agent not updated.
- Corporate bootstrap validation markers not checked.

Recommended actions:

- Stop validation.
- Verify `speckit.plan` runtime guard.
- Verify preset source definition.
- Re-synchronize runtime.
- Re-test before continuing.

### 17.4 `corp.load` Does Not Create `active-pbi.md`

Possible causes:

- Invalid PBI path.
- Missing write permissions.
- Runtime cleanup failed.
- File format issue.

Recommended actions:

- Verify the PBI file exists.
- Verify the path is relative to repository root.
- Verify `.specify/memory/` exists or can be created.
- Re-run `corp.erase` and then `corp.load`.

### 17.5 `corp.plan` Does Not Generate `spec.md`

Possible causes:

- `corp.load` was not executed successfully.
- `active-pbi.md` is missing.
- PBI is incomplete or not assessable.
- Governance sequence was not respected.

Recommended actions:

- Verify `.specify/memory/active-pbi.md`.
- Run `corp.assess`.
- Resolve readiness issues.
- Re-run `corp.plan`.

### 17.6 `delivery-doc.md` Not Generated During Smoke Test

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

### 17.7 Runtime Appears Outdated

Possible causes:

- Source of Truth updated but runtime not synchronized.
- Duplicate files exist in multiple locations.
- Editor session cached previous commands.

Recommended actions:

- Compare `extensions/` and `.github/`.
- Compare `presets/` and runtime behavior.
- Compare `presets/grm-corporate-governance/workflows/` and `.specify/workflows/`.
- Restart Copilot or the editor session.
- Re-run governance validation.

### 17.8 Documentation Folder Missing

Possible causes:

- Manual installation did not copy `docs/`.
- Source repository or package does not contain official docs.
- Installation used an outdated branch or package.

Recommended actions:

Verify the source repository contains:

```text
docs/architecture.md
docs/governance.md
docs/installation-guide.md
docs/maintenance.md
docs/release-checklist.md
docs/user-guide.md
```

Then re-copy documentation from the expected source.

### 17.9 GRM Workflow Missing From Runtime

Possible causes:

- Workflow folder was not copied.
- Registry was not merged.
- Wrong preset version was installed.

Recommended actions:

- Verify `presets/grm-corporate-governance/workflows/grm/workflow.yml`.
- Verify `.specify/workflows/grm/workflow.yml`.
- Verify `.specify/workflows/workflow-registry.json` contains `grm`.
- Re-synchronize workflows.

### 17.10 `speckit` Workflow Missing From Registry

This is a compatibility failure.

Possible causes:

- Registry was overwritten instead of merged.
- `.specify/workflows` was replaced destructively.
- Spec Kit runtime was not initialized before applying GRM customization.

Recommended actions:

- Restore the Spec Kit runtime workflow registry.
- Re-apply GRM workflow registry using additive merge.
- Validate both `speckit` and `grm`.
- Do not approve installation until `speckit` is preserved.

## 18. Installation Acceptance Criteria

An installation can be accepted only when all the following criteria are met.

| Area | Acceptance Criteria |
|---|---|
| Structure | Required directories exist. |
| Runtime | Corporate commands are available. |
| Governance | Blocked commands are blocked. |
| Guard | `speckit.plan` requires corporate bootstrap. |
| Workflows | `speckit` is preserved and `grm` is installed. |
| Registry | `workflow-registry.json` contains both `speckit` and `grm`. |
| Functional Validation | Smoke test completes successfully. |
| Documentation | Official documentation is installed and README map is updated. |
| Samples | Validation samples are installed. |
| Git | Changes are committed in a controlled branch where applicable. |
| Evidence | Manual or automated validation evidence exists. |

## 19. Handover Checklist

Before handing the repository to delivery teams, confirm:

- Installation validation completed.
- Smoke test completed.
- Governance validation completed.
- Workflow registry validation completed.
- Known limitations communicated.
- README documentation map updated.
- User Guide available.
- Architecture Guide available.
- Governance Guide available.
- Maintenance Guide available.
- Release Checklist available.
- Bootstrap documentation available where installer is distributed.
- Samples available.
- Maintainer identified.
- Installation branch merged or ready for review.

## 20. Known Limitations

Current limitations:

- Runtime synchronization remains an explicit architectural concern and must be validated after changes.
- PBI source is currently markdown-based.
- Azure DevOps integration is not yet available.
- MCP integration is not yet available.
- Additional Spec Kit commands may require future governance review.
- Copilot UI may display internal execution progress messages.
- Copilot and Spec Kit runtime conventions may evolve in future versions.
- Future Spec Kit workflow registry changes may require validation of the merge strategy.

Current installation capabilities:

- Manual installation remains available and documented as the reference process.
- Portable Git-first bootstrap installation is available under `resources/bootstrap` and documented separately.
- Clean installation and non-destructive update are supported by the bootstrap installer.
- Manual installation remains important for maintenance, understanding and troubleshooting.

## 21. Recommended Next Steps After Installation

Once installation is validated:

- Read `docs/user-guide.md`.
- Execute the workflow with a known sample PBI.
- Review `docs/governance.md` before onboarding users.
- Review `docs/maintenance.md` before modifying prompts, agents, presets, workflows or runtime files.
- Review `docs/architecture.md` before changing the Source of Truth vs Runtime model.
- Use `docs/release-checklist.md` before publishing a validated baseline.
- Review `resources/bootstrap/bootstrap-installation-guide.md` if automated installation or update is required.
- Create a release or tag for the validated installation baseline.

## 22. Summary

GRM Custom Spec Kit installation is successful when:

- The repository contains both Source of Truth and Runtime layers.
- Corporate commands are available.
- Blocked commands are actually blocked.
- `speckit.plan` is protected by the corporate bootstrap guard.
- The native Spec Kit workflow is preserved.
- The GRM workflow is installed.
- The workflow registry contains both `speckit` and `grm`.
- Official documentation is available locally.
- Validation samples are available locally.
- The complete validation workflow runs successfully.
- The repository is ready for iterative PBI-driven delivery.

The installation model is considered aligned when manual installation and automated bootstrap installation produce equivalent structure, behavior, governance controls and workflow registry state.
