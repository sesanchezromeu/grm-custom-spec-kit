---
name: grm-pbi-source-markdown
description: Read a Product Backlog Item from a local Markdown file and load it into the corporate active PBI context. Use this skill when a PBI reference is a local file path, when the corporate workflow is invoked with the --file flag, when loading a PBI from disk, from the samples folder, from a repository path or from an exported Markdown backlog item, or whenever a corporate command needs the content of a PBI that lives in a Markdown file rather than in a remote backlog.
---

# PBI source adapter - local Markdown file

Three commands, in order. You run them and report what they return.

## Four rules that override everything else

1. **You do not write the active PBI.** The scripts read, route, assemble and
   verify. Never create or edit `.specify/memory/active-pbi.md`, the payload or
   the fragments by hand, not even to fix something that looks wrong.
2. **You never author PBI content.** Do not summarise, rephrase, reorder,
   reindent or normalise punctuation. Straight quotes are not an improvement
   over typographic ones, and three spaces of indentation are not an error to
   be corrected.
3. **Stop on the first failure.** Any command that does not return its success
   line ends the load. Do not retry with a different path, do not substitute a
   similar file, do not continue to `/corp.assess`.
4. **Never invent, never reconstruct.** A fabricated PBI is worse than a failed
   load. Report the failure as printed.

This skill carries no governance: readiness is assessed by `/corp.assess`.

## Procedure

Copy each command character for character and substitute only the path. Do not
rebuild the paths, and do not invoke the scripts directly: the execution policy
will refuse them. The host has Windows PowerShell 5.1 and no `pwsh`.

### 1. Read

```
powershell -NoProfile -ExecutionPolicy Bypass -File .github\skills\grm-pbi-source-markdown\scripts\Read-PbiMarkdown.ps1 -Reference "<path>"
```

The path is whatever the user provided, unchanged. Do not absolutise it, do not
convert its separators, do not strip its directories. The script echoes it into
the envelope exactly as received.

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

Read these four files and transcribe them. Do not compute anything.

- `.specify/memory/.grm-pbi-sections/source.md` -> `Source envelope`
- `.specify/memory/.grm-pbi-sections/missing_optional.md` -> `Missing obvious metadata`
- `.specify/memory/.grm-pbi-sections/warnings.md` -> `Source warnings`
- `.specify/memory/.grm-pbi-sections/verification.md` -> `Completeness verification`

Then state that the active PBI was written and verified, and stop. The calling
command decides what happens next. Do not restate the PBI content in your reply:
it is in the file.

## Reference material

Consult only when something is unclear. Not required reading.

- `references/section-routing.md` - the heading table and what is appended after Notes
