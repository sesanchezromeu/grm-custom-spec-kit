---
name: grm-pbi-source-markdown
description: Resolve and read a Product Backlog Item from a local Markdown file and return it as a normalized PBI payload for the corporate load command. Use this skill when a PBI reference is a local file path, when the corporate workflow is invoked with the --file flag, when loading a PBI from disk, from the samples folder, from a repository path or from an exported Markdown backlog item, or whenever a corporate command needs the content of a PBI that lives in a Markdown file rather than in a remote backlog.
---

# PBI source adapter — local Markdown file

Resolve a local Markdown path, read it, return a normalized PBI payload.
Read this whole file before acting. It is short by design.

## Five rules that override everything else

1. **Read only.** Never write, move, rename or delete any file. Never write
   `.specify/memory/active-pbi.md`, `.specify/feature.json` or anything under
   `features/`. Writing the active PBI belongs to the calling command.
2. **No shell.** Never invoke a terminal, script or command to obtain any field.
   This skill reads files; it does not execute anything.
3. **`Reference` is a path, never a file name.** Emit the complete resolved path.
   Emitting only the file name is an error, not an abbreviation.
4. **Never invent.** Absent information is reported as absent, never inferred.
5. **Four-part report, always.** Envelope, body, missing sections, verification.
   Omitting part 3 or 4 is an incomplete response, not a concise one.

No governance rules here: this skill does not judge readiness, gate the workflow
or recommend a next command. Readiness is assessed by `/corp.assess`.

## Rule 3 in detail

Two PBIs in different folders can share a file name, so a bare name does not
identify the source. Never shorten, prettify or strip directories:

- `samples/PBI-POC-02-conversion-moneda.md` → emit it whole, **not** `PBI-POC-02-conversion-moneda.md`
- `C:\proj\samples\pbi-01.md` → emit it whole, **not** `pbi-01.md`
- `../backlog/pbi-07.md` → emit it whole, **not** `pbi-07.md`

## Procedure

### 1. Resolve the path — and record it now

Accept the path as provided; resolve relative paths against the workspace root.

**First action, before reading anything:** copy the path string you were given,
character for character, and hold it as `Reference`. A copy, not a derivation —
you are echoing the input, not naming the file. Deciding it later, while
formatting the envelope, is how the directories get lost.
Stop and report, without substituting a similar file or creating one:

- no path given → `Missing input file.`
- does not exist → `PBI Markdown file not found: <path>`
- is a directory → `Path is a directory, not a PBI file: <path>`
- not `.md` → `Source file is not a Markdown file: <path>`

### 2. Read the file in full — do not read a fragment and extrapolate

### 3. Minimum loadability check

Locate a title, a description or objective, and acceptance criteria; if none can be
found, stop and report which are missing. Missing *optional* sections — out of scope,
dependencies, constraints, notes — are reported, not fatal.

### 4. Envelope

Fields that do not apply are emitted literally as `Not applicable`: never blank, never omitted, never guessed.

| Field | Value |
|---|---|
| Type | `Markdown file` |
| Reference | the string recorded in step 1, unchanged — see rule 3 |
| Organization / Project / Work item ID / Work item type / Revision | `Not applicable` |
| Changed at | last-modified timestamp if the host exposes it, else `Not recorded` |
| Retrieved via | `Local file read` |

A blocked or unavailable timestamp is `Not recorded` and the load continues — never a reason to reach for a shell, never a reason to stop.

### 5. Return the body verbatim

Byte for byte. Never summarise, restructure, rewrite, normalise, reorder, translate,
compress or reflow. Preserve every heading and its level, every list and its nesting
depth, every table, code block and emphasis, and the original language. Preserve
**every finite list of allowed values** — a set of tax rates such as `0 %`, `4 %`,
`10 %`, `21 %` is a business rule, and dropping one item changes the specification.

### 6. Verify no omission

1. Count headings per level in source and payload. **State the actual counts**
   (e.g. 1 at level 2, 9 at level 3, 5 at level 4). Never report an uncounted total.
2. Every source list item appears at the same nesting depth.
3. The payload contains no text absent from the source.

Failure → stop and report. Never return a partial payload: it looks complete and silently narrows scope.

## Report

1. `Source envelope` — all nine fields.
2. `Verbatim body` — heading levels unchanged.
3. `Missing optional sections` — or `None detected.`
4. `Completeness verification` — the counts from step 6.

Then stop; the calling command decides what happens next.
