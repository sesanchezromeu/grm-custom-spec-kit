---
name: grm-azure-devops-pbi
description: Retrieve a Product Backlog Item from the Azure DevOps product backlog and load it into the corporate active PBI context. Use this skill when a PBI reference points at the product backlog, when the corporate workflow is invoked with the --backlog flag, when the reference is an Azure DevOps work item URL or a <key>:<id> pair such as CDA:108047, when loading a PBI from Azure DevOps, from the backlog, from a work item, from a ticket or from a sprint item, or whenever a corporate command needs the content of a PBI that lives in a remote backlog rather than in a local Markdown file.
---

# PBI source adapter - Azure DevOps backlog

Three commands, in order. You run them and report what they return.

## Four rules that override everything else

1. **You do not write the active PBI.** The scripts retrieve, convert, assemble
   and verify. Never create or edit `.specify/memory/active-pbi.md`, the payload
   or the fragments by hand, not even to fix something that looks wrong.
2. **You never author PBI content.** Do not convert, summarise, rephrase,
   reorder or normalise punctuation. Straight quotes are not an improvement over
   typographic ones.
3. **Stop on the first failure.** Any command that does not return its success
   line ends the load. Do not retry with a different reference, do not fall back
   to another retrieval method, do not continue to `/corp.assess`.
4. **Never invent, never reconstruct.** A fabricated PBI is worse than a failed
   load. Report the failure as printed.

This skill carries no governance: readiness is assessed by `/corp.assess`.

## Procedure

Copy each command character for character and substitute only the reference. Do
not rebuild the paths, and do not invoke the scripts directly: the execution
policy will refuse them. The host has Windows PowerShell 5.1 and no `pwsh`.

### 1. Retrieve

```
powershell -NoProfile -ExecutionPolicy Bypass -File .github\skills\grm-azure-devops-pbi\scripts\Get-WorkItem.ps1 -Reference "<reference>"
```

The reference is whatever the user provided, unchanged: a work item URL, proxy
parameters and all, or a `<key>:<id>` pair. The script normalises it.

The credential comes from the `AZDO_PAT` environment variable. Never ask for it,
never pass it as an argument, never echo it.

Success is a line reading `status=ok payload=<path> sections=<path>`. Anything
else is a failure: report the message the script printed and stop.

### 2. Assemble

```
powershell -NoProfile -ExecutionPolicy Bypass -File .github\skills\_shared\scripts\Build-ActivePbi.ps1
```

Success is `build=ok`. This writes `.specify/memory/active-pbi.md` from the
fragments produced in step 1.

### 3. Verify

```
powershell -NoProfile -ExecutionPolicy Bypass -File .github\skills\_shared\scripts\Assert-ActivePbi.ps1
```

Success is `verification=ok`. On `verification=failed`, the load has failed:
report the difference the verifier printed, verbatim, and stop. Do not correct
the file. Repairing the artifact until the check passes is not verification.

## Report

Read these three files and transcribe them. Do not compute anything.

- `.specify/memory/.grm-pbi-sections/source.md` -> `Source envelope`
- `.specify/memory/.grm-pbi-sections/warnings.md` -> `Source warnings`
- `.specify/memory/.grm-pbi-sections/verification.md` -> `Completeness verification`

Then state that the active PBI was written and verified, and stop. The calling
command decides what happens next. Do not restate the PBI content in your reply:
it is in the file.

## Reference material

Consult only when something is unclear. Not required reading.

- `references/fidelity-contract.md` - envelope, mapping, rules F-01 to F-10
- `references/configuration.md` - catalogue, PAT, environment constraints