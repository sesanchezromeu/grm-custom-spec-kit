# GRM Custom Spec Kit - User Guide

## 1. Purpose

This guide explains how to use GRM Custom Spec Kit to deliver work from an approved Product Backlog Item (PBI) to implementation and authoritative delivery documentation.

It is intended for users who execute the delivery workflow on a day-to-day basis.

This document focuses on operational usage only.

For installation, architecture, governance rationale or long-term maintenance, refer to:

- `docs/installation-guide.md`
- `docs/architecture.md`
- `docs/governance.md`
- `docs/maintenance.md`

---

## 2. When to Use This Framework

Use GRM Custom Spec Kit when delivery work must originate from an approved PBI and must remain traceable through planning, implementation and documentation.

### Suitable Use Cases

Use this framework for:

- Approved Product Backlog Items.
- New functional features.
- Functional changes with clear acceptance criteria.
- Controlled technical implementation from approved scope.
- PBI-based validation scenarios.
- Delivery flows requiring traceable as-built documentation.

### Unsuitable Use Cases

Do not use this framework for:

- Initial product discovery.
- Unapproved ideas.
- Exploratory requirement definition.
- Ad-hoc functional clarification.
- Direct creation of specifications outside an approved PBI.
- Work that has not passed the required product governance process.

### Key Rule

```text
No approved PBI, no delivery workflow.
```

---

## 3. Delivery Lifecycle Overview

GRM Custom Spec Kit enforces a controlled delivery lifecycle.

```text
Approved PBI
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
        ↓
delivery-doc.md
```

The approved PBI is the functional source of truth.

The implementation is the source of reality for final delivery documentation.

The final expected output is:

```text
features/<feature>/delivery-doc.md
```

This file is the authoritative delivery record for the implemented feature.

---

## 4. Core Operating Principles

## 4.1 PBI First

All delivery work starts from an approved PBI.

Developers must not create functional scope directly through standard Spec Kit specification commands.

## 4.2 No Plan Without Assessment

Planning must not start until the PBI has been assessed.

```text
corp.assess
        ↓
corp.plan
        ↓
speckit.plan
```

## 4.3 Native Spec Kit Reuse

GRM Custom Spec Kit preserves native Spec Kit planning, task generation and implementation commands.

Corporate commands prepare and protect the workflow.

## 4.4 Explicit Context Management

Each PBI execution must use a clean context.

`corp.load` automatically resets the active context before loading a new PBI.

`corp.erase` can also be executed manually when troubleshooting or resetting a workspace.

## 4.5 Delivery Documentation as Closure

The workflow is not complete until `corp.doc` has generated the delivery documentation.

---

## 5. Roles and Responsibilities

| Role | Main Responsibilities |
|------|------------------------|
| Product Owner | Owns the PBI, acceptance criteria and functional decisions |
| Developer | Executes the workflow and implements the solution |
| Project Manager | Ensures governance, traceability and delivery coordination |
| Technical Lead | Supports implementation quality and technical decision-making |
| Maintainer | Owns installation, runtime synchronization and framework evolution |

---

## 6. Quick Start

Use this sequence for a standard approved PBI.

### Step 1 - Load the Approved PBI

```text
/corp.load --file samples/PBI-POC-01-calculadora-iva.md
```

Or, when the approved PBI lives in the Azure DevOps backlog:

```text
/corp.load --backlog CDA:108047
```

Expected result:

```text
.specify/memory/active-pbi.md
```

The active PBI context is created and previous execution state is cleaned.

---

### Step 2 - Assess the PBI

```text
/corp.assess
```

Expected result:

```text
READY
READY_WITH_RISKS
NOT_READY
```

Continue only if the result is `READY` or if `READY_WITH_RISKS` has been explicitly accepted.

---

### Step 3 - Generate Corporate Bootstrap Specification

```text
/corp.plan
```

Expected result:

```text
features/<feature>/spec.md
```

This creates the controlled bootstrap specification required for native Spec Kit planning.

---

### Step 4 - Run Native Spec Kit Planning

```text
/speckit.plan
```

Expected result:

Technical planning artifacts are generated using the corporate bootstrap specification.

---

### Step 5 - Generate Implementation Tasks

```text
/speckit.tasks
```

Expected result:

Implementation tasks are generated from the planning artifacts.

---

### Step 6 - Implement

```text
/speckit.implement
```

Expected result:

The implementation is generated or updated according to the planned tasks.

---

### Step 7 - Generate Delivery Documentation

```text
/corp.doc
```

Expected result:

```text
features/<feature>/delivery-doc.md
```

This document consolidates implemented behavior, validation evidence, deviations, technical debt and improvement candidates.

---

## 7. Corporate Workflow

## 7.1 Standard Flow

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

## 7.2 Mandatory Steps

The following steps are mandatory for a normal PBI delivery cycle:

```text
corp.load
corp.assess
corp.plan
speckit.plan
speckit.tasks
speckit.implement
corp.doc
```

## 7.3 Optional Step

`corp.erase` is optional because `corp.load` already performs corporate cleanup.

Use `corp.erase` manually when:

- Troubleshooting.
- Resetting a validation scenario.
- Cleaning a contaminated context.
- Preparing a repeatable test.

---

## 8. Command Reference

## 8.1 corp.erase

### Purpose

Reset the active execution context.

### Use When

- Starting a clean validation scenario.
- Troubleshooting context issues.
- Removing previous feature state.
- Ensuring no cross-PBI contamination exists.

### Main Actions

- Resets active PBI context.
- Ensures `features/` exists and preserves everything already under it.
- Removes feature execution state (`.specify/feature.json`).

### Expected Outcome

The workspace is ready for a clean PBI load.

---

## 8.2 corp.load

### Purpose

Load an approved PBI and initialize a clean execution context.

### Syntax

```text
/corp.load --file <path-to-pbi-markdown>
/corp.load --backlog <work-item-url-or-key:id>
```

Provide exactly one source flag.

### Input

`--file` takes a markdown PBI file:

```text
samples/PBI-POC-01-calculadora-iva.md
```

`--backlog` takes an Azure DevOps work item, given either as a full URL or as a `<KEY>:<id>` pair resolved against the backlog catalogue:

```text
https://dev.azure.com/<organization>/<project>/_workitems/edit/<id>
CDA:108047
```

A URL copied from the browser may carry the corporate proxy host and its query parameters. Paste it unchanged: it is normalized before use.

### Main Actions

- Resets the active execution context, preserving everything under `features/`.
- Retrieves the PBI from the source named by the flag.
- Assembles the active PBI context and verifies it against what was retrieved.

### Expected Output

```text
.specify/memory/active-pbi.md
```

A load that fails writes nothing. There is no partial context to clean up.

### Important Rule

Do not edit `active-pbi.md` manually. If the PBI is incorrect, update the source PBI and reload it.

On the `--backlog` path the rule reaches further. The file is assembled and verified mechanically against the retrieved work item, so an edit breaks that correspondence and no later verification will restore it.

### Backlog Catalogue

`--backlog` resolves a `<KEY>:<id>` reference against `.specify/grm-backlog.yml`. Copy `.specify/grm-backlog.example.yml`, rename it and fill in one entry per backlog:

```yaml
provider: azure-devops

backlogs:
  <KEY>:
    organization_url: https://dev.azure.com/<organization>
    project: <project>
```

Keys are chosen by the project. There is no default backlog by design: a reference that does not name its backlog can resolve silently against the wrong one.

The credential is never stored in this file. A token written into it must be considered compromised.

Whichever form the reference takes, the project reported by Azure DevOps is checked after retrieval. A mismatch stops the load, so a work item is never taken from a project other than the intended one.

### Personal Access Token

Retrieval authenticates with a personal access token read from the `AZDO_PAT` environment variable. It is never passed as an argument, never written to a repository file and never echoed.

Create it in Azure DevOps under User settings - Personal access tokens - New Token, granting read access to work items. **Scope it to a single organization.** Tokens scoped to all accessible organizations are withdrawn by Azure DevOps from 1 December 2026; this is a requirement, not a recommendation. The value is shown once.

Set the variable for the user:

```powershell
[Environment]::SetEnvironmentVariable('AZDO_PAT', '<token>', 'User')
```

A persistent variable is not visible in sessions that are already open. Restart the terminal, and VS Code with it, or the load will report a missing credential while the variable exists.

An expired token cannot be extended. Renewal means issuing a new one and updating the variable.

The complete requirements, including maximum expiry and the exact scopes, are in `references/configuration.md` in the `grm-azure-devops-pbi` skill.

---

## 8.3 corp.assess

### Purpose

Evaluate PBI readiness before planning.

### Characteristics

- Read-only command.
- Does not generate implementation artifacts.
- Does not modify functional scope.
- Acts as a governance gate.

### Possible Outcomes

```text
READY
READY_WITH_RISKS
NOT_READY
```

### Expected Usage

Run `corp.assess` after `corp.load` and before `corp.plan`.

```text
/corp.load --file <pbi.md>
/corp.assess
```

---

## 8.4 corp.plan

### Purpose

Generate the controlled bootstrap specification required by native Spec Kit planning.

### Expected Output

```text
features/<feature>/spec.md
```

### What corp.plan Does

- Reads the approved active PBI.
- Preserves PBI traceability.
- Creates a compliant bootstrap specification.
- Prepares the context for `speckit.plan`.

### What corp.plan Does Not Do

- It does not replace `speckit.plan`.
- It does not invent requirements.
- It does not expand functional scope.
- It does not bypass assessment.

---

## 8.5 speckit.plan

### Purpose

Generate native Spec Kit planning artifacts.

### Governance Constraint

`speckit.plan` is allowed only after `corp.plan` has created the required corporate bootstrap.

If executed too early, it must be blocked by the corporate guard.

---

## 8.6 speckit.tasks

### Purpose

Generate implementation tasks from the planning artifacts.

### Expected Usage

Run after successful planning.

```text
/speckit.plan
/speckit.tasks
```

---

## 8.7 speckit.implement

### Purpose

Execute implementation based on generated tasks.

### Expected Usage

Run after task generation.

```text
/speckit.tasks
/speckit.implement
```

---

## 8.8 corp.doc

### Purpose

Generate authoritative as-built delivery documentation.

### Expected Output

```text
features/<feature>/delivery-doc.md
```

### What corp.doc Does

- Reviews the implemented result.
- Compares intended behavior against implemented behavior.
- Consolidates validation evidence where available.
- Detects deviations.
- Identifies validation gaps.
- Identifies technical debt.
- Generates improvement backlog candidates.

### What corp.doc Does Not Do

- It does not change source code.
- It does not modify the approved PBI.
- It does not replace formal product acceptance.

---

## 9. Understanding Assessment Results

## 9.1 READY

Meaning:

The PBI has enough information to proceed.

Recommended action:

```text
Continue with corp.plan
```

## 9.2 READY_WITH_RISKS

Meaning:

The PBI can proceed, but known risks or gaps exist.

Recommended action:

1. Review the identified risks.
2. Confirm whether they are acceptable.
3. Document mitigation or assumptions.
4. Continue only if the delivery owner accepts the risk.

Typical examples:

- Minor ambiguity.
- Non-blocking dependency.
- Validation criteria present but incomplete.
- Technical uncertainty that can be resolved during implementation.

## 9.3 NOT_READY

Meaning:

The PBI is not ready for planning.

Recommended action:

```text
Stop the workflow
```

Then:

1. Return the PBI to refinement.
2. Resolve missing information.
3. Clarify acceptance criteria.
4. Reload the updated PBI.
5. Run `corp.assess` again.

Do not execute `corp.plan` when the result is `NOT_READY`.

---

## 10. Understanding Delivery Documentation

## 10.1 Purpose of delivery-doc.md

`delivery-doc.md` is the authoritative delivery record for the implemented feature.

It captures what was actually delivered, not only what was originally planned.

## 10.2 Expected Content

A complete delivery document should include:

- PBI reference.
- Implemented behavior.
- Validation evidence.
- Deviations from expected behavior.
- Validation gaps.
- Technical debt.
- Improvement backlog candidates.
- Final compliance status.

## 10.3 Possible Status Values

```text
COMPLIANT
COMPLIANT_WITH_FINDINGS
NON_COMPLIANT
```

## 10.4 How to Use delivery-doc.md

Use the delivery document to:

- Support delivery review.
- Inform Product Owner acceptance.
- Capture technical findings.
- Create follow-up PBIs.
- Improve future planning.
- Preserve end-to-end traceability.

## 10.5 Important Rule

The workflow is not complete until `delivery-doc.md` exists and has been reviewed.

---

## 11. Governance Rules for Users

## 11.1 Blocked Commands

The following standard Spec Kit commands are blocked by corporate governance:

```text
speckit.specify
speckit.clarify
```

### Why speckit.specify Is Blocked

Functional specifications must originate from an approved PBI.

Users must not create new functional scope directly from the delivery environment.

### Why speckit.clarify Is Blocked

Functional clarification belongs to product refinement before PBI approval.

Clarifying scope during delivery may bypass product governance.

## 11.2 Protected Command

```text
speckit.plan
```

`speckit.plan` remains available because GRM reuses native Spec Kit planning.

It is protected because planning must only run after:

```text
corp.load
corp.assess
corp.plan
```

---

## 12. Common Scenarios

## 12.1 Scenario 1 - New Approved PBI

Use when starting a new feature from an approved PBI.

```text
/corp.load --file <pbi.md>
/corp.assess
/corp.plan
/speckit.plan
/speckit.tasks
/speckit.implement
/corp.doc
```

Expected outcome:

```text
delivery-doc.md generated
```

---

## 12.2 Scenario 2 - PBI Assessment Returns READY_WITH_RISKS

Use when the PBI can proceed but contains manageable risks.

Recommended flow:

```text
/corp.load --file <pbi.md>
/corp.assess
```

If result is `READY_WITH_RISKS`:

1. Review risks.
2. Confirm acceptance with the delivery owner.
3. Continue with:

```text
/corp.plan
/speckit.plan
```

Do not ignore the risks. They should remain visible in planning or delivery documentation.

---

## 12.3 Scenario 3 - PBI Assessment Returns NOT_READY

Use when the PBI is incomplete or not suitable for planning.

Recommended flow:

```text
/corp.load --file <pbi.md>
/corp.assess
```

If result is `NOT_READY`:

```text
Stop
```

Then:

- Return the PBI to refinement.
- Update the source PBI.
- Reload it.
- Re-run assessment.

Do not continue to planning.

---

## 12.4 Scenario 4 - Clean Retest of the Same PBI

Use when repeating validation from a clean state.

```text
/corp.erase
/corp.load --file <pbi.md>
/corp.assess
/corp.plan
```

Optional continuation:

```text
/speckit.plan
/speckit.tasks
/speckit.implement
/corp.doc
```

---

## 12.5 Scenario 5 - Suspected Context Contamination

Use when artifacts from a previous PBI appear to affect the current workflow.

Recommended action:

```text
/corp.erase
/corp.load --file <pbi.md>
```

Then continue with:

```text
/corp.assess
```

---

## 12.6 Scenario 6 - Re-run Delivery Documentation

Use when implementation has changed or validation evidence has been added.

```text
/corp.doc
```

Expected outcome:

`delivery-doc.md` reflects the latest implementation state.

---

## 13. Best Practices

- Use approved PBIs only.
- Keep PBIs small and focused.
- Use measurable acceptance criteria.
- Run `corp.assess` before planning.
- Stop when assessment returns `NOT_READY`.
- Treat `READY_WITH_RISKS` as a managed exception, not as a normal success.
- Do not manually edit generated runtime context files.
- Use `corp.erase` when troubleshooting.
- Generate `corp.doc` after implementation.
- Review `delivery-doc.md` before closing the work.
- Preserve traceability between PBI, plan, tasks, implementation and documentation.

---

## 14. Anti-Patterns

Avoid the following behaviors:

- Starting work without an approved PBI.
- Skipping `corp.assess`.
- Running `speckit.plan` before `corp.plan`.
- Using `speckit.specify`.
- Using `speckit.clarify`.
- Editing `active-pbi.md` manually.
- Expanding scope during planning.
- Treating `READY_WITH_RISKS` as risk-free.
- Closing a PBI without generating `delivery-doc.md`.
- Reusing a contaminated workspace across PBIs.

---

## 15. Troubleshooting

## 15.1 corp.load Fails

Possible causes on `--file`:

- Invalid file path.
- PBI file does not exist.
- File is not accessible.
- Repository is not opened at the expected root.
- Write permissions are missing.

Possible causes on `--backlog`:

- The token has expired. Expiry and a permissions problem both surface as HTTP 401, and expiry is the more likely of the two.
- `AZDO_PAT` is not visible in the session, usually because the terminal was opened before the variable was set.
- The key in a `<KEY>:<id>` reference is not present in `.specify/grm-backlog.yml`.
- The work item belongs to a project other than the one configured for that key.
- The work item is not of an accepted type.
- The work item has no description, or no acceptance criteria.
- The completeness check found a difference between the retrieved content and the assembled file.

Recommended actions:

1. Verify the file path on `--file`, or the reference on `--backlog`.
2. Confirm the source exists and is reachable.
3. Use a path relative to the repository root.
4. On HTTP 401, reissue the token and restart the terminal before investigating permissions.
5. Verify write permissions.
6. Re-run `corp.load`.

A failed load leaves the previous context reset and nothing written in its place.

---

## 15.2 active-pbi.md Missing

Possible causes:

- `corp.load` failed.
- Context was erased after loading.
- Runtime path is incorrect.

Recommended actions:

```text
/corp.erase
/corp.load --file <pbi.md>
```

Then verify:

```text
.specify/memory/active-pbi.md
```

---

## 15.3 corp.assess Returns NOT_READY

This is not a technical failure.

It means the PBI is not ready for planning.

Recommended actions:

1. Review findings.
2. Return the PBI to refinement.
3. Update missing information.
4. Reload the PBI.
5. Re-run `corp.assess`.

Do not continue with `corp.plan` until the PBI is ready.

---

## 15.4 corp.plan Does Not Generate spec.md

Possible causes:

- `corp.load` was not executed.
- `active-pbi.md` is missing.
- Assessment result was not acceptable.
- Runtime command failed.

Recommended actions:

1. Verify `active-pbi.md` exists.
2. Re-run `corp.assess`.
3. Confirm the PBI is `READY` or accepted as `READY_WITH_RISKS`.
4. Re-run `corp.plan`.

Expected output:

```text
features/<feature>/spec.md
```

---

## 15.5 speckit.plan Is Blocked

This is expected if corporate bootstrap has not been completed.

Verify:

- `corp.load` executed successfully.
- `corp.assess` completed.
- `corp.plan` generated `spec.md`.
- Corporate bootstrap markers exist.

Recommended sequence:

```text
/corp.load --file <pbi.md>
/corp.assess
/corp.plan
/speckit.plan
```

---

## 15.6 speckit.specify or speckit.clarify Is Blocked

This is expected behavior.

These commands are intentionally disabled by corporate governance.

Use the corporate workflow instead:

```text
/corp.load
/corp.assess
/corp.plan
```

---

## 15.7 speckit.tasks Fails

Possible causes:

- Planning did not complete.
- Required planning artifacts are missing.
- `speckit.plan` was blocked or interrupted.

Recommended actions:

1. Verify `speckit.plan` completed successfully.
2. Verify planning artifacts exist.
3. Re-run `speckit.plan` if needed.
4. Re-run `speckit.tasks`.

---

## 15.8 speckit.implement Fails

Possible causes:

- Task generation incomplete.
- Implementation dependencies missing.
- Repository state inconsistent.

Recommended actions:

1. Verify tasks were generated.
2. Review implementation errors.
3. Resolve missing dependencies or conflicts.
4. Re-run `speckit.implement`.

---

## 15.9 delivery-doc.md Not Generated

Possible causes:

- Implementation not completed.
- Feature folder missing.
- `corp.doc` failed.
- Validation artifacts unavailable.

Recommended actions:

1. Verify implementation completed.
2. Verify `features/<feature>/` exists.
3. Re-run `corp.doc`.
4. Review generated findings.

---

## 15.10 Context Contamination Suspected

Symptoms:

- Current PBI appears mixed with a previous one.
- Generated artifacts refer to old requirements.
- Feature state does not match the active PBI.

Recommended action:

```text
/corp.erase
/corp.load --file <pbi.md>
```

Then continue from assessment.

---

## 16. Known Limitations

Current limitations:

- PBI input is a markdown file or an Azure DevOps work item. No other source is supported.
- MCP integration is not yet available.
- Runtime synchronization is currently manual.
- Some additional standard Spec Kit commands may require future governance review.
- Copilot UI may display internal execution progress messages.
- File links may appear shortened in the UI although they reference repository paths.

Limitations specific to `--backlog`:

- Comments on the work item are not loaded. Their presence is reported as a warning.
- Child work items are not retrieved.
- Attachments are referenced by their URL and never downloaded.
- Artifact links are reported and then discarded.
- A work item without a description, or without acceptance criteria, is rejected. It is never loaded partially.

---

## 17. Operational Checklist

## 17.1 Before Starting

Verify:

- Approved PBI exists.
- PBI file is available in the repository.
- Repository is ready for execution.
- GRM Custom Spec Kit installation has been validated.
- Required corporate commands are available.

## 17.2 Before Planning

Verify:

- `corp.load` completed successfully.
- `active-pbi.md` exists.
- `corp.assess` completed.
- Assessment result is `READY` or accepted `READY_WITH_RISKS`.

## 17.3 Before Implementation

Verify:

- `corp.plan` completed successfully.
- `spec.md` exists.
- `speckit.plan` completed successfully.
- `speckit.tasks` completed successfully.

## 17.4 Before Closing

Verify:

- `speckit.implement` completed.
- `corp.doc` executed.
- `delivery-doc.md` generated.
- Deviations reviewed.
- Validation gaps reviewed.
- Technical debt reviewed.
- Improvement backlog candidates reviewed.

---

## 18. Success Criteria

A PBI delivery cycle is considered successfully completed when:

- The approved PBI was loaded.
- Readiness assessment was executed.
- Planning bootstrap was generated.
- Native Spec Kit planning completed.
- Tasks were generated.
- Implementation was completed.
- Delivery documentation was generated.
- Traceability from PBI to implementation was preserved.
- Findings, deviations and technical debt were documented.

Expected final artifact:

```text
features/<feature>/delivery-doc.md
```

---

## 19. Recommended Closure Review

Before closing the PBI, review:

| Review Area | Question |
|-------------|----------|
| Scope | Was the approved PBI implemented? |
| Acceptance Criteria | Are acceptance criteria covered? |
| Validation | Is evidence available? |
| Deviations | Are deviations documented? |
| Technical Debt | Is debt identified and actionable? |
| Follow-up | Are improvement candidates captured? |
| Traceability | Can delivery be traced back to the PBI? |

---

## 20. Summary

Use GRM Custom Spec Kit as an operational workflow for controlled PBI-based delivery.

The essential rule is:

```text
Approved PBI
        ↓
Assessment
        ↓
Controlled Planning
        ↓
Implementation
        ↓
As-Built Documentation
```

The workflow is successful when the implemented feature is traceable, validated and documented through `delivery-doc.md`.
