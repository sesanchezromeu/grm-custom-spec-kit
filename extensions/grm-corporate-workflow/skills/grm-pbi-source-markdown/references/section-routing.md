# Section routing - Markdown source

Normative for `Read-PbiMarkdown.ps1`. Decided as D-P16b-01, option b: an
explicit table, never a heuristic. The table lives in the script; this file
explains it and records why it is shaped the way it is.

## Heading levels

The first Markdown heading in the file is the title, whatever its level. The
section level is the shallowest level deeper than the title. So a file whose
title is `#` has `##` sections, and a file whose title is `##` has `###`
sections. Both shapes exist in `samples/`, which is why the level is detected
rather than assumed.

Headings deeper than the section level are content and stay inside their
section, untouched.

## Title and PBI ID

A title of the form `<id> - <text>` is split: the first token becomes the PBI
ID, the rest becomes the title. A title in any other shape is the title, and
the PBI ID is reported as absent. It is never derived from the file name: a
file name is a property of the disk, not of the PBI.

## Routing table

Matching folds accents and case, so `Descripcion` and `Descripción` are the
same key. The script itself is pure ASCII (HZ-05), which is why the table holds
folded keys and the source heading is folded to meet it.

| Source heading | Canonical section |
|---|---|
| Descripcion, Description | Description |
| Objetivo, Objective, Contexto de negocio, Business context | Business Context |
| Criterios de aceptacion, Acceptance criteria | Acceptance Criteria |
| Restricciones tecnicas, Restricciones, Constraints | Constraints |
| Dependencias, Dependencies | Dependencies |
| Fuera de alcance, Out of scope | Out of Scope |
| Notas, Notes | Notes |

## Everything else

A heading absent from the table is appended after `## Notes`, keeping its
original heading text and level. This is what the Canonical section rule of
`corp.load.agent.md` requires of a source section with no canonical
counterpart. In the sample PBIs this covers `Alcance funcional`, `Reglas de
negocio` and `Evidencias esperadas`.

Two source sections routing to the same canonical slot are not merged: the
first fills the slot, the second is appended after Notes and a warning is
emitted. Merging would fuse two source sections into one and leave no trace.

Text between the title and the first section is appended after Notes without a
heading, with a warning. It belongs to no section and is not discarded.

## Coverage check

Before writing anything, the script compares the token sequence of the source
body against the token sequence of everything routed. A mismatch aborts the
read and no file is written. This is what makes the table safe: if a future
heading falls through both the table and the append path, the load fails
loudly instead of quietly narrowing the PBI.

## What the script does not do

It does not reindent, does not normalise line endings, does not add or remove a
final newline, and does not touch quotation marks. Those are properties of the
source file. A `--file` load observed in P16 lost every accent in the canonical
sections, invented tab indentation and was then repaired twice by the agent
until its own check turned green. That is the failure this adapter exists to
make impossible.