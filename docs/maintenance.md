# GRM Custom Spec Kit - Maintenance Guide

Version: 1.0
Last Updated: 2026-07-22
Status: Release Candidate

## 1. Purpose

This guide defines how to maintain, evolve, validate and release GRM Custom Spec Kit.

It is intended for maintainers, architects, technical leads and governance owners responsible for the framework lifecycle.

The objective is to ensure that future changes preserve governance, traceability and compatibility with the validated operating model.

---

# 2. Maintenance Objectives

Maintenance activities must ensure:

- Governance integrity is preserved.
- Source of Truth remains authoritative.
- Runtime remains synchronized.
- Corporate workflow remains operational.
- Documentation remains accurate.
- Releases remain reproducible.
- Future enhancements do not bypass governance controls.

---

# 3. Ownership Model

## Product Owner

Owns:

- Business objectives.
- Operating model evolution.
- Governance requirements.

## Architect

Owns:

- Architectural consistency.
- Runtime strategy.
- Extension and preset design.

## Maintainer

Owns:

- Source of Truth updates.
- Runtime synchronization.
- Packaging.
- Validation.
- Releases.

## Project Manager

Owns:

- Adoption planning.
- Communication.
- Training coordination.

---

# 4. Maintenance Scope

## In Scope

```text
extensions/
presets/
.github/
docs/
samples/
.vscode/
```

## Out of Scope

```text
Spec Kit core
Upstream project internals
```

The framework extends Spec Kit.

It does not modify Spec Kit core behavior.

---

# 5. Source of Truth Policy

The authoritative customization definition is:

```text
extensions/
presets/
```

Maintenance Rule:

```text
Edit Source of Truth first.
Never treat runtime as the primary authoring location.
```

Responsibilities:

### extensions/

Contains:

- Corporate commands.
- Agents.
- Prompts.
- Workflow behavior.
- Skills, under `skills/`.
- Shared scripts, under `skills/_shared/scripts/`.
- Configuration templates, under `config/`.

### presets/

Contains:

- Governance policies.
- Command guardrails.
- Behavioral restrictions.

---

# 6. Runtime Management Policy

Runtime consists of:

```text
.github/
.specify/
```

Runtime exists to execute behavior.

Source of Truth exists to define behavior.

`.specify/` also holds project configuration that is not propagated from the
Source of Truth, such as the backlog catalogue. Deployed templates are the
starting point for those files, never their authority.

## Current Model

```text
extensions + presets
        ↓
manual synchronization
        ↓
.github
```

Synchronization is not uniform. `skills/` is mirrored as a whole subtree.
`agents/` and `prompts/` are copied file by file, by hand. Nothing detects a
file that was left behind, so a runtime can execute an agent that no longer
matches the one under `extensions/` while every command still appears to work.

## Maintenance Rule

After every Source of Truth change:

1. Update runtime.
2. Validate runtime alignment by comparing content, not by inspection.
3. Execute governance validation.
4. Execute smoke test.

Comparing content means a hash of each file on both sides, computed after
normalizing line endings and trailing newlines. A file that looks right in an
editor and differs by one character is the failure mode this step exists to
catch.

---

# 7. Change Classification

## Type 1 - Documentation Change

Examples:

- README updates.
- User guide updates.
- Architecture clarifications.

Required validation:

```text
Documentation review only.
```

---

## Type 2 - Prompt Change

Examples:

- corp.doc prompt updates.
- Command wording updates.

Required validation:

```text
Runtime synchronization
Smoke test
```

---

## Type 3 - Agent Change

Examples:

- corp.load behavior.
- corp.plan behavior.
- guard logic.

Required validation:

```text
Runtime synchronization
Governance validation
End-to-end validation
```

---

## Type 4 - Governance Change

Examples:

- Command restrictions.
- Preset behavior.
- Workflow gates.

Required validation:

```text
Architecture review
Governance review
Full workflow validation
```

---

## Type 5 - Skill Change

Examples:

- A new PBI source adapter.
- Changes to `SKILL.md`, to a reference document or to a script.
- Changes to the shared scripts under `skills/_shared/scripts/`.

A skill is a directory under `extensions/grm-corporate-workflow/skills/`
containing `SKILL.md`, optional `references/` and optional `scripts/`. A skill
that is not listed under `skills:` in `extension.yml` does not exist as far as
the framework is concerned.

`_shared` is not a skill. It is a script library invoked by skills and by
agents, and it is deliberately absent from `extension.yml`.

Architectural invariant: a skill never writes `.specify/memory/active-pbi.md`,
`.specify/feature.json` or anything under `features/`. Those artifacts are
written and verified by the shared scripts, which is the whole reason the
library exists. A new skill retrieves and reports; it does not author, repair or
normalize the artifacts it feeds.

Lifecycle of a new skill:

1. Create the directory and `SKILL.md` under the Source of Truth.
2. Add reference documents and scripts. Scripts are ASCII only, target Windows
   PowerShell 5.1, and are parsed before use.
3. Declare the skill under `skills:` in `extension.yml`.
4. Synchronize the runtime and verify by content.
5. Exercise the skill end to end against a real source.

Required validation:

```text
Runtime synchronization
Content verification of every skill file
End-to-end validation against a real source
```

---

# 8. Adding a New Corporate Command

Follow this process.

## Step 1

Define objective.

Questions:

- What governance problem is solved?
- Why is a new command required?
- Why can't existing commands solve it?

## Step 2

Update Source of Truth.

```text
extensions/
```

## Step 3

Create:

```text
agent
prompt
README updates
```

## Step 4

Synchronize runtime.

## Step 5

Validate complete workflow.

## Step 6

Update documentation.

Required:

- User Guide
- Architecture Guide
- Governance Guide
- Maintenance Guide

---

# 9. Modifying Governance Rules

Governance modifications are high-risk changes.

Examples:

- Unblocking commands.
- Changing workflow order.
- Modifying guards.
- Altering traceability requirements.

Required reviews:

- Product review.
- Architecture review.
- Governance review.

Never modify governance behavior without documenting the rationale.

---

# 10. Runtime Synchronization Procedure

After any Source of Truth modification:

## Step 1

Update:

```text
extensions/
presets/
```

## Step 2

Update the corresponding runtime assets under `.github/`, by class:

```text
skills/            mirrored as a subtree
agents/            copied file by file
prompts/           copied file by file
```

Only `skills/` has tooling. A local helper script exists for that subtree, but
it is not versioned with the framework, so it cannot be assumed present after a
clone. Copying by hand and verifying afterwards is the procedure of record;
tooling is an optimization on top of it, never a substitute for the check.

## Step 3

Verify alignment by comparing content.

For every file touched, compute a hash on both sides after normalizing line
endings and trailing newlines, and compare. Reading the file and judging it
aligned is not verification.

Minimum validation:

```text
Command availability
Prompt alignment
Agent alignment
Skill alignment
Governance alignment
```

## Step 4

Execute smoke test.

---

# 11. Validation Strategy

## Governance Validation

Verify:

```text
speckit.specify blocked
speckit.clarify blocked
speckit.plan protected
```

## Functional Validation

Verify:

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

## Documentation Validation

Verify:

- Guides updated.
- Examples updated.
- Documentation map updated.

---

# 12. Release Process

## Phase 1 - Prepare

- Review changes.
- Complete documentation.
- Synchronize runtime.

## Phase 2 - Validate

- Governance validation.
- Smoke test.
- End-to-end workflow test.

## Phase 3 - Package

Verify repository structure.

```text
README.md
docs/
extensions/
presets/
.github/
```

## Phase 4 - Release

Create controlled release tag.

---

# 13. Recommended Versioning

```text
v0.x  Experimental
v1.x  Stable
v2.x  Major evolution
```

Examples:

```text
v0.9.0
v1.0.0
v1.1.0
v1.2.0
```

---

# 14. Documentation Maintenance Policy

Whenever behavior changes:

Update:

```text
README
Installation Guide
User Guide
Architecture Guide
Governance Guide
Maintenance Guide
```

Documentation must never lag behind implementation.

---

# 15. Technical Debt Management

Capture debt in:

```text
delivery-doc.md
```

Classify debt:

- Governance debt.
- Documentation debt.
- Runtime debt.
- Automation debt.
- Functional debt.

Track debt through follow-up PBIs.

## Framework Debt

Debt in the framework itself does not belong in any `delivery-doc.md`. Record it
here, named, so that it survives the session that found it.

Currently open:

- The runtime synchronization helper for `skills/` is not versioned with the
  framework, and the usage example inside the script itself shows an invocation
  form that does not work.
- `Get-DepthProfile` is defined twice across the shared scripts. Both copies
  behave identically today, which is exactly what makes a future divergence
  hard to notice.
- `.github/skills/` is versioned in part: it carries the shared scripts needed
  to run corporate commands in this repository, but not the skills themselves.

---

# 16. Maintenance Risks

## Risk 1

Source of Truth and Runtime diverge.

This has occurred. Tooling covered `skills/` only, agent changes never reached
the runtime, and the divergence surfaced as inconsistent behavior during
testing rather than as a synchronization error.

Mitigation:

Mandatory synchronization validation, by content comparison, covering every
class of runtime asset and not only the ones with tooling.

## Risk 2

Governance rules modified without review.

Mitigation:

Formal review process.

## Risk 3

Documentation becomes outdated.

Mitigation:

Documentation update required for every release.

## Risk 4

New commands bypass operating model.

Mitigation:

Architecture and governance review before approval.

---

# 17. Release Readiness Checklist

Before release verify:

```text
□ Source of Truth updated
□ Runtime synchronized
□ Governance validated
□ Smoke test completed
□ End-to-end workflow validated
□ Documentation updated
□ Samples validated
□ Version assigned
□ Release notes prepared
```

---

# 18. Maintainer Checklist

For every change:

```text
□ Update extensions or presets
□ Synchronize runtime
□ Validate governance
□ Execute smoke test
□ Update documentation
□ Commit changes
□ Create release evidence
```

---

# 19. Future Evolution Areas

Planned areas of improvement:

- Runtime automation.
- Packaging automation.
- Azure DevOps integration.
- MCP integration.
- Governance dashboards.
- Automated validation suites.
- Release automation.

---

# 20. Summary

The maintenance strategy is based on a single principle:

```text
Source of Truth
        ↓
Runtime Synchronization
        ↓
Validation
        ↓
Release
```

A change is complete only when:

- Source of Truth is updated.
- Runtime is synchronized.
- Governance is validated.
- Documentation is updated.
- The workflow remains end-to-end operational.
