# GRM Custom Spec Kit - Installation Guide

## 1. Purpose

This guide explains how to install, validate, update and troubleshoot GRM Custom Spec Kit in a Spec Kit project.

It is intended for maintainers, technical leads or project owners responsible for preparing a repository before delivery teams execute the GRM corporate workflow.

This document covers installation and preparation only. Day-to-day execution of PBIs is documented in `docs/user-guide.md`.

---

## 2. Scope

This guide covers:

- Preparing a clean Spec Kit repository.
- Applying the GRM customization.
- Understanding Source of Truth vs Runtime.
- Validating the installed structure.
- Verifying corporate commands and governance guards.
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

---

## 3. Target Audience

| Audience | Responsibility |
|----------|----------------|
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
Execute Corporate Workflow
```

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

At the current release stage, synchronization between Source of Truth and Runtime is manual.

```text
extensions + presets
        ↓
manual synchronization
        ↓
.github + .specify
```

This is intentional for the current release because it improves transparency, validation and troubleshooting.

Future versions may automate this process.

---

## 6. Prerequisites

Before installing GRM Custom Spec Kit, verify the following prerequisites.

### Required

- A clean repository prepared for Spec Kit usage.
- Spec Kit available in the local environment.
- Git available in the local environment.
- GitHub Copilot or compatible Copilot agent execution environment.
- Access to the GRM Custom Spec Kit repository contents.

### Recommended

- A clean working tree before applying the customization.
- A dedicated branch for installation or packaging updates.
- A known-good PBI sample for validation.
- Permission to update repository files.

---

## 7. Recommended Branching Strategy

Use a controlled branch when installing or updating the customization.

Example:

```bash
git checkout -b chore/install-grm-custom-spec-kit
```

Recommended practices:

- Avoid installing directly on the main branch.
- Commit the clean Spec Kit baseline separately if needed.
- Commit the GRM customization separately.
- Commit validation fixes separately.

This improves traceability and rollback capability.

---

## 8. Installation Procedure

## Step 1 - Prepare a Clean Repository

Start from a repository where the Spec Kit installation can be initialized safely.

Verify the repository status.

If the directory already contains a Git repository:

```bash
git status
```

Expected result:

```text
nothing to commit, working tree clean
```

If starting from a completely empty directory, a Git repository may not yet exist and git status will fail. In that case either:

```bash
git init
```

or proceed directly with:

```bash
specify init --here
```

and continue with the installation process.
If the repository is not clean, commit or stash local changes before continuing.


---

## Step 2 - Initialize Spec Kit

Create or initialize the Spec Kit structure.

```bash
specify init --here
```

After initialization, the repository should contain Spec Kit runtime assets.

Minimum expected structure:

```text
.specify/
```

Observed structure in Spec Kit 0.13.4:

.github/
.specify/
.vscode/

Additional runtime assets may include:

.specify/integrations/
.specify/scripts/
.specify/templates/
.specify/workflows/
.github/agents/
.github/prompts/

The exact runtime structure may evolve between Spec Kit versions.

---

## Step 3 - Apply GRM Customization Source of Truth

Copy the formal GRM customization into the repository.

Required directories:

```text
extensions/grm-corporate-workflow/
presets/grm-corporate-governance/
```

These directories are the source of truth for the GRM customization.

Do not treat `.github` as the long-term authoring location for corporate customization. `.github` is runtime.

---

## Step 4 - Apply Runtime Files

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

Runtime synchronization should follow the Runtime Merge Strategy defined in Section 13.

---

## Step 5 - Preserve Spec Kit Runtime

Do not delete `.specify` after initialization.

`.specify` is required by native Spec Kit commands such as:

```text
speckit.plan
speckit.tasks
speckit.implement
```

GRM Custom Spec Kit extends native Spec Kit behavior. It does not replace the Spec Kit runtime.

---

## Step 6 - Add Documentation and Samples

Recommended documentation structure:

```text
docs/
├── installation-guide.md
├── user-guide.md
├── architecture.md
├── governance.md
└── maintenance.md
```

Recommended sample structure:

```text
samples/
└── PBI-POC-01-calculadora-iva.md
```

Samples are validation assets. They are not part of the runtime.

---

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

### Directory Responsibilities

| Directory | Responsibility |
|----------|----------------|
| `.github/` | Copilot runtime |
| `.specify/` | Spec Kit runtime and execution state |
| `.vscode/` | Local editor recommendations and settings |
| `docs/` | Documentation |
| `extensions/` | Corporate workflow source of truth |
| `presets/` | Governance source of truth |
| `samples/` | Validation examples |

---

## 10. Installation Validation Checklist

Run this checklist after installation.

### Repository Structure

| Check | Expected Result |
|------|-----------------|
| `.github/` exists | Yes |
| `.specify/` exists | Yes |
| `extensions/grm-corporate-workflow/` exists | Yes |
| `presets/grm-corporate-governance/` exists | Yes |
| `docs/` exists | Yes |
| `samples/` exists | Yes |

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
|---------|-------------------|
| `speckit.specify` | Blocked |
| `speckit.clarify` | Blocked |
| `speckit.plan` | Allowed only after corporate bootstrap |
| `speckit.tasks` | Allowed after planning |
| `speckit.implement` | Allowed after tasks |

---

## 11. Functional Smoke Test

After installation, before executing the functional smoke test, perform governance validation:

/speckit.specify
/speckit.clarify
/speckit.plan

Expected results:

- speckit.specify blocked
- speckit.clarify blocked
- speckit.plan blocked until corporate bootstrap exists

Only continue with the smoke test after governance controls have been validated successfully.

Run a minimal validation using a sample PBI. Recommended validation flow:

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

If the validation fails, do not continue with real PBIs until the issue is resolved.

---

## 12. Governance Validation

Installation is not complete until governance behavior is validated.

### Validate speckit.specify Block

Try to execute:

```text
/speckit.specify
```

Expected result:

```text
Blocked by corporate governance
```

### Validate speckit.clarify Block

Try to execute:

```text
/speckit.clarify
```

Expected result:

```text
Blocked by corporate governance
```

### Validate speckit.plan Guard

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

## 13. Runtime Synchronization Validation

Because Source of Truth and Runtime are currently synchronized manually, every installation or update must verify alignment.

### Runtime Merge Strategy

When applying the GRM customization, do not replace the entire .github runtime generated by Spec Kit.

Recommended process:

1. Execute:

specify init --here

2. Preserve the runtime generated by Spec Kit.

3. Copy GRM corporate runtime files:

corp.assess
corp.doc
corp.erase
corp.load
corp.plan

4. Replace only governed Spec Kit commands:

speckit.specify
speckit.clarify
speckit.plan
speckit.tasks
speckit.implement

5. Preserve any additional native commands provided by the installed Spec Kit version.

Example observed in Spec Kit 0.13.4:

speckit.analyze
speckit.checklist
speckit.converge
speckit.taskstoissues

A full replacement of .github may remove native functionality introduced in newer versions of Spec Kit.

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
|-----------------|---------------------|
| `corp.erase` extension | Runtime command available |
| `corp.load` extension | Runtime command available |
| `corp.assess` extension | Runtime command available |
| `corp.plan` extension | Runtime command available |
| `corp.doc` extension | Runtime command available |
| Governance preset | `speckit.specify` blocked |
| Governance preset | `speckit.clarify` blocked |
| Governance preset | `speckit.plan` guarded |

---

## 14. Upgrade Procedure

Use this procedure when updating GRM Custom Spec Kit in an existing repository.

### Step 1 - Create Upgrade Branch

```bash
git checkout -b chore/update-grm-custom-spec-kit
```

### Step 2 - Backup Local Changes

Review local status:

```bash
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

### Step 5 - Validate Governance

Re-run blocked and guarded command tests:

```text
speckit.specify blocked
speckit.clarify blocked
speckit.plan guarded
```

### Step 6 - Execute Smoke Test

Run the complete validation flow with a sample PBI.

### Step 7 - Commit Changes

Recommended commit message:

```bash
git add .
git commit -m "chore: update GRM Custom Spec Kit packaging"
```

---

## 15. Rollback Procedure

If installation or upgrade fails, rollback should be explicit and controlled.

### Option 1 - Revert Working Tree Changes

If changes are not committed:

```bash
git restore .
```

### Option 2 - Revert Commit

If changes were committed:

```bash
git revert <commit-sha>
```

### Option 3 - Restore Last Known Good Branch

If validation cannot be recovered quickly, return to the last known valid branch.

Do not continue with real PBIs on a partially validated installation.

---

## 16. Troubleshooting

## Corporate Commands Not Available

Possible causes:

- Runtime files not copied to `.github`.
- Copilot environment not refreshed.
- Wrong repository opened in the editor.
- Command file naming mismatch.

Recommended actions:

1. Verify `.github` structure.
2. Verify agent and prompt files exist.
3. Restart the Copilot or editor session.
4. Re-run installation validation.

---

## speckit.specify or speckit.clarify Not Blocked

Possible causes:

- Governance preset not synchronized to runtime.
- Runtime still contains standard behavior.
- Wrong command file loaded by Copilot.

Recommended actions:

1. Verify `presets/grm-corporate-governance` exists.
2. Verify runtime contains blocking behavior.
3. Compare preset source with runtime command behavior.
4. Do not approve installation until the block is effective.

---

## speckit.plan Runs Without corp.plan

This is a critical governance failure.

Possible causes:

- Corporate guard missing.
- Runtime agent not updated.
- Bootstrap validation markers not checked.

Recommended actions:

1. Stop validation.
2. Verify `speckit.plan` runtime guard.
3. Verify preset source definition.
4. Re-synchronize runtime.
5. Re-test before continuing.

---

## corp.load Does Not Create active-pbi.md

Possible causes:

- Invalid PBI path.
- Missing write permissions.
- Runtime cleanup failed.
- File format issue.

Recommended actions:

1. Verify file exists.
2. Verify path is relative to repository root.
3. Verify `.specify/memory/` exists or can be created.
4. Re-run `corp.erase` and then `corp.load`.

---

## corp.plan Does Not Generate spec.md

Possible causes:

- `corp.load` was not executed successfully.
- `active-pbi.md` missing.
- PBI incomplete or not assessable.
- Governance sequence not respected.

Recommended actions:

1. Verify `.specify/memory/active-pbi.md`.
2. Run `corp.assess`.
3. Resolve readiness issues.
4. Re-run `corp.plan`.

---

## delivery-doc.md Not Generated During Smoke Test

Possible causes:

- Implementation flow incomplete.
- Feature folder not generated.
- `corp.doc` runtime missing or outdated.
- Validation artifacts unavailable.

Recommended actions:

1. Verify `speckit.implement` completed.
2. Verify `features/<feature>/` exists.
3. Verify `corp.doc` is available.
4. Re-run `corp.doc`.

---

## Runtime Appears Outdated

Possible causes:

- Source of Truth updated but runtime not synchronized.
- Duplicate files exist in multiple locations.
- Editor session cached previous commands.

Recommended actions:

1. Compare `extensions/` and `.github/`.
2. Compare `presets/` and runtime behavior.
3. Restart Copilot or editor session.
4. Re-run governance validation.

---

## 17. Installation Acceptance Criteria

An installation can be accepted only when all the following criteria are met.

| Area | Acceptance Criteria |
|------|---------------------|
| Structure | Required directories exist |
| Runtime | Corporate commands are available |
| Governance | Blocked commands are blocked |
| Guard | `speckit.plan` requires `corp.plan` |
| Workflow | Smoke test completes successfully |
| Documentation | README and docs map are updated |
| Git | Changes are committed in a controlled branch |

---

## 18. Handover Checklist

Before handing the repository to delivery teams, confirm:

- Installation validation completed.
- Smoke test completed.
- Governance validation completed.
- Known limitations communicated.
- README documentation map updated.
- User Guide available.
- Architecture Guide available.
- Maintainer identified.
- Installation branch merged or ready for review.

---

## 19. Known Limitations

Current limitations:

- Runtime synchronization is currently manual.
- PBI source is currently markdown-based.
- Azure DevOps integration is not yet available.
- MCP integration is not yet available.
- Additional Spec Kit commands may require future governance review.
- Copilot UI may display internal execution progress messages.
- Installation currently requires manual deployment and runtime synchronization.
- No automated installation or bootstrap mechanism is currently provided.

---

## 20. Recommended Next Steps After Installation

Once installation is validated:

1. Read `docs/user-guide.md`.
2. Execute the workflow with a known sample PBI.
3. Review `docs/governance.md` before onboarding users.
4. Review `docs/maintenance.md` before modifying prompts, agents, presets or runtime files.
5. Create a release or tag for the validated installation baseline.

---

## 21. Summary

GRM Custom Spec Kit installation is successful when:

- The repository contains both Source of Truth and Runtime layers.
- Corporate commands are available.
- Blocked commands are actually blocked.
- `speckit.plan` is protected by the corporate bootstrap guard.
- The complete validation workflow runs successfully.
- The repository is ready for iterative PBI-driven delivery.
