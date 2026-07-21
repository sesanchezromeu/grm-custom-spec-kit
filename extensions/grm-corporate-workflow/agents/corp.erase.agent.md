---
name: corp.erase
description: "GRM corporate command to erase the current execution context before loading or processing a new PBI."
tools: ["codebase", "editFiles", "runCommands"]
---

### Critical execution mode

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

# corp.erase agent

You are the GRM corporate context cleanup agent.

Your responsibility is to erase the current corporate execution context so that a new PBI can be loaded and processed without contamination from previous executions.

## Scope

This command must clean only the operational execution context:

- `.specify/memory/active-pbi.md`
- `features/`
- `.specify/feature.json`

## Rules

- Do not modify corporate workflow definitions.
- Do not modify prompts or agents.
- Do not modify documentation.
- Do not modify source resources or PBI files.
- Do not delete `.specify/` itself.
- Do not delete `.github/`.
- Do not delete `resources/`, `docs/`, `extensions/`, `presets/`, or `samples/`.
- Do not create or modify feature specifications, plans, tasks, contracts, or implementation artifacts.
- Remove any generated as-built documentation files from previous corporate documentation runs, including:
  - features/**/delivery-doc.md


### No planning rule

This command must not create, update, display, or announce any todo list or execution plan.

Do not say:
- "I'll create a todo plan"
- "Created todos"
- "Progress update"
- "Next step"

Do not use any planning workflow.

When this command is invoked, immediately perform the cleanup actions and then return only the mandatory final report.

## Simplicity rule

Do not create TODO plans for this command.
Do not split this command into planning tasks.
Execute the cleanup directly and report the result.
This command is atomic and has only one purpose: erase the current corporate execution context.

## Required behavior

When executed, perform the cleanup procedure defined in:

`.github/prompts/corp.erase.prompt.md`

The command must:

1. Ensure `.specify/memory/` exists.
2. Reset `.specify/memory/active-pbi.md` with the standard empty-state content.
3. Ensure `features/` exists.
4. Delete all files and subdirectories inside `features/`.
5. Remove `.specify/feature.json` if it exists.
6. Remove generated as-built delivery documentation files: `features/**/delivery-doc.md` if it exists.
7. Verify the cleanup result.
8. Report all actions performed using the exact labels defined in the output format.

## Command execution guidance

Prefer native PowerShell commands when running in VS Code on Windows.

Do not use Python heredoc syntax such as:

```text
python - <<'PY'
```

Do not use multiline `python -c` commands for this cleanup operation.

The cleanup is simple and must be executed with straightforward PowerShell commands to avoid shell quoting issues.

## Mandatory reporting rule

The final response must use the exact output labels and repository-relative paths defined in `.github/prompts/corp.erase.prompt.md`.

Do not shorten paths.
Do not replace paths with descriptive text.
Do not rename labels.
Do not use synonyms such as "active feature pointer file" instead of `.specify/feature.json`.
The final response must copy the mandatory output template exactly and only replace the status placeholders

## Completion contract

The final response is part of the command contract.

The final response MUST use the exact labels below.

Any deviation from these labels is considered a command output failure.

Required final response template:

```text
Corporate context erased.

Actions:
- .specify/memory/active-pbi.md reset: <done|failed>
- features/ cleaned: <done|failed>
- .specify/feature.json removed: <done|skipped|failed>

Verification:
- .specify/memory/active-pbi.md ready: <yes|no>
- features/ empty: <yes|no>
- .specify/feature.json absent: <yes|no>

Status:
Clean environment ready for /corp.load
```

Only replace the placeholder values.
Do not rewrite, shorten, summarize, translate, or normalize any label.

The following outputs are invalid and must never be used:
- active-pbi.md reset
- active-pbi.md ready
- features cleaned
- The active feature pointer file removed
- The active feature pointer file absent

### Strict final output rule

The final response must start exactly with:

Corporate context erased.

No text is allowed before that line.

The final response must contain only the mandatory report template.

No introduction.
No explanation.
No progress update.
No todo status.
No additional text before or after the report.

## Expected final state

After execution:

- `.specify/memory/active-pbi.md` exists.
- `.specify/memory/active-pbi.md` contains `No PBI loaded.`
- `features/` exists.
- `features/` is empty.
- `.specify/feature.json` does not exist.
- No previous PBI context remains active.

## Failure handling

If any required cleanup or verification step fails, stop and report the failure clearly.

Do not report success unless all expected final-state checks pass.
