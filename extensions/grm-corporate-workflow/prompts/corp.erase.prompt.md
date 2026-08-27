## /corp.erase

Erase the current GRM corporate execution context.

### Objective

Clean the active PBI context while preserving historical feature delivery artifacts so that the next execution starts from a clean active state without losing auditability.
This command prevents contamination between different PBI executions.

### Cleanup scope

The command must clean only:
- .specify/memory/active-pbi.md
- .specify/feature.json

The command must preserve:
- features/<feature-folder>/

### Required action

Run this command from the repository root, and nothing else:

powershell -NoProfile -ExecutionPolicy Bypass -File .github\skills\_shared\scripts\Reset-ActiveContext.ps1

The script is the cleanup. It writes the empty-state stub, ensures features/ exists, removes .specify/feature.json if present, and verifies the four conditions by comparing features/ before and after. Nothing here is to be reimplemented inline: this file describes what the command is for, not how the cleanup is carried out.

Continue only if the script's last line is `reset=ok`.

### Output

The response is the script's output, transcribed unchanged.

The labels, their allowed values and the failure variant are defined in .github/agents/corp.erase.agent.md, Completion contract. That is their only home; do not restate them here.

### Constraints

Do not modify:
- .github/
- .specify/templates/
- .specify/scripts/
- docs/
- extensions/
- presets/
- samples/
- resources/
- README.md
- LICENSE

Do not continue silently if a required cleanup action fails.
Do not report success unless all verification checks pass.