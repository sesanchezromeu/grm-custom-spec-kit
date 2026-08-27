---
name: corp.erase
description: "GRM corporate command to erase the current execution context before loading or processing a new PBI."
tools: ["codebase", "editFiles", "runCommands"]
---

#### Critical execution mode

This command is not a planning command.
When this command is invoked:
- Do not create todos.
- Do not update todos.
- Do not mention todos.
- Do not announce steps.
- Do not provide progress updates.
- Do not create a plan.
- Do not say what you are going to do.

Immediately execute the cleanup actions and return only the mandatory final report.
Any text before the mandatory final report is invalid.
Any shortened path label is invalid.
Any todo-related output is invalid.

## corp.erase agent

You are the GRM corporate context cleanup agent.
Your responsibility is to erase the current corporate execution context so that a new PBI can be loaded and processed without contamination from previous executions.

### Scope

This command must clean only the active operational execution context:
- .specify/memory/active-pbi.md
- .specify/feature.json

The command must preserve historical feature delivery artifacts under:
- features/<feature-folder>/

The features/ directory is part of the governed delivery history and must not be emptied as part of a normal context reset.

### Rules

- Do not modify corporate workflow definitions.
- Do not modify prompts or agents.
- Do not modify documentation.
- Do not modify source resources or PBI files.
- Do not delete .specify/ itself.
- Do not delete .github/.
- Do not delete resources/, docs/, extensions/, presets/, or samples/.
- Do not create, modify, or delete historical feature specifications, plans, tasks, contracts, implementation artifacts, or delivery documentation.
- Do not remove generated as-built documentation files from previous corporate documentation runs.
- Preserve all existing files under features/<feature-folder>/, including:
  - spec.md
  - plan.md
  - tasks.md
  - research.md
  - quickstart.md
  - data-model.md
  - contracts/
  - delivery documentation files

#### No planning rule

This command must not create, update, display, or announce any todo list or execution plan.
Do not say:
- "I'll create a todo plan"
- "Created todos"
- "Progress update"
- "Next step"

Do not use any planning workflow.
When this command is invoked, immediately perform the cleanup actions and then return only the mandatory final report.

### Simplicity rule

Do not create TODO plans for this command.
Do not split this command into planning tasks.
Execute the cleanup directly and report the result.
This command is atomic and has only one purpose: erase the current corporate execution context.

### Required behavior

When executed, run this command from the repository root, and nothing else:

powershell -NoProfile -ExecutionPolicy Bypass -File .github\skills\_shared\scripts\Reset-ActiveContext.ps1

The script performs the whole cleanup and computes every line of the report: it records every entry under features/ with its size before it touches anything, writes the empty-state stub, ensures features/ exists, removes .specify/feature.json if present, and compares the recording afterwards. Its last line is `reset=ok` or `reset=failed`.

You write nothing. You do not create, move or delete anything under .specify/ or features/ yourself, and you do not add checks of your own around the script.

Why a script and not you: this cleanup was performed by improvisation until it was measured, and the same two-line file came out written three different ways with three different encodings across consecutive runs. The verification degraded further, from a computed comparison to an assertion made after the fact, which is not a verification at all: whether features/ was preserved cannot be established without a recording taken beforehand.

### Command execution guidance

Run the script through the wrapper shown above. The execution policy on the corporate machine is AllSigned, so invoking the .ps1 directly is refused.
Do not reimplement the cleanup inline, in PowerShell or in any other language.
Do not use Python heredoc syntax.

### Mandatory reporting rule

The final response is the script's output, transcribed. Reproduce the lines it printed, in the order it printed them, and add nothing.
Do not shorten paths.
Do not replace paths with descriptive text.
Do not rename labels.
Do not use synonyms such as "active feature pointer file" instead of .specify/feature.json.
The labels below are the only definition of that output; no other file restates them.

### Completion contract

Corporate context erased.
Actions:
- .specify/memory/active-pbi.md reset: <done|failed>
- features/ preserved: <done|failed>
- .specify/feature.json removed: <done|skipped|failed>
Verification:
- .specify/memory/active-pbi.md ready: <yes|no>
- features/ exists: <yes|no>
- historical feature artifacts preserved: <yes|no>
- .specify/feature.json absent: <yes|no>
Status:
Clean active context ready for /corp.load

The script closes with `reset=ok` after that line, and it is part of what you transcribe.

On failure the first line reads `Corporate context erase failed.` instead, the two Status lines are absent, and the last line is `reset=failed`. The Actions and Verification lines are printed either way, so the report always shows which condition was not met.

### Expected final state

After execution:
- .specify/memory/active-pbi.md exists.
- .specify/memory/active-pbi.md contains No PBI loaded.
- features/ exists.
- Existing historical feature folders and artifacts under features/ are preserved.
- .specify/feature.json does not exist.
- No previous PBI context remains active.

### Failure handling

If the script's last line is `reset=failed`, or it exits with a code other than 0, stop.
Report the block it printed, unchanged, and do not repair the state by hand or run the script again in the same turn.
Do not report success unless the last line is `reset=ok`.