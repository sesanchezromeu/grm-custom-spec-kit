# /corp.erase

Erase the current GRM corporate execution context.

## Objective

Clean the active PBI context and generated feature artifacts so that the next execution starts from a clean state.

This command prevents contamination between different PBI executions.

## Cleanup scope

The command must clean only:

```text
.specify/memory/active-pbi.md
features/
.specify/feature.json
```

## Required actions

### 1. Reset active PBI memory

Ensure this directory exists:

```text
.specify/memory/
```

Ensure this file exists:

```text
.specify/memory/active-pbi.md
```

Overwrite `.specify/memory/active-pbi.md` with exactly this logical content:

```md
# Active PBI

No PBI loaded.
```

Minor newline differences at end of file are acceptable.

### 2. Clean generated features

Ensure this directory exists:

```text
features/
```

Delete all files and subdirectories inside:

```text
features/
```

Do not permanently delete the `features/` directory. If the directory is removed during cleanup, recreate it.

### 3. Remove active feature pointer

If this file exists:

```text
.specify/feature.json
```

delete it.

If it does not exist, report it as skipped.

## Execution guidance for Windows / VS Code

When running in PowerShell, use native PowerShell commands.

Do not use Python heredoc commands such as:

```text
python - <<'PY'
```

Do not use multiline `python -c` commands.

The preferred implementation is a simple PowerShell cleanup sequence using:

- `New-Item`
- `Set-Content`
- `Get-ChildItem`
- `Remove-Item`
- `Test-Path`

This avoids shell quoting issues and prevents the command from blocking.

## Verification

After cleanup, verify that:

- `.specify/memory/active-pbi.md` exists.
- `.specify/memory/active-pbi.md` contains `No PBI loaded.`
- `features/` exists.
- `features/` is empty.
- `.specify/feature.json` does not exist.

## Mandatory output format

The final response is not free-form text. It is a strict command report. Copy the template exactly and only replace the placeholder values.

Only replace the placeholders `<done|failed>`, `<done|skipped|failed>` and `<yes|no>` with the actual values.

Do not change, shorten, translate, rename, summarize, or paraphrase any label.

The path labels must appear exactly as written.

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

## Reporting constraints

The following labels are not allowed in the final response:

```text
active-pbi.md reset
features cleaned
The active feature pointer file removed
The active feature pointer file absent
```

Always use the full repository-relative labels from the mandatory output format.

## Constraints

Do not modify:

```text
.github/
.specify/templates/
.specify/scripts/
docs/
extensions/
presets/
samples/
resources/
README.md
LICENSE
```

Do not continue silently if a required cleanup action fails. Report the failure clearly.

Do not report success unless all verification checks pass.
