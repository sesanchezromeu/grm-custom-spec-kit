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

### Required actions

#### 1. Reset active PBI memory

Ensure this directory exists:
.specify/memory/

Ensure this file exists:
.specify/memory/active-pbi.md

Overwrite .specify/memory/active-pbi.md with exactly this logical content:

# Active PBI
No PBI loaded.

#### 2. Preserve historical features

Ensure this directory exists:
features/

Do not delete files or subdirectories inside features/.

Do not delete historical feature folders such as:
features/<feature-folder>/

Do not delete historical delivery artifacts such as:
- spec.md
- plan.md
- tasks.md
- research.md
- quickstart.md
- data-model.md
- contracts/
- delivery documentation files

If the features/ directory does not exist, recreate it.

#### 3. Remove active feature pointer

If this file exists:
.specify/feature.json

delete it.

If it does not exist, report it as skipped.

### Verification

After cleanup, verify that:
- .specify/memory/active-pbi.md exists.
- .specify/memory/active-pbi.md contains No PBI loaded.
- features/ exists.
- Historical feature folders and artifacts under features/ were not deleted.
- .specify/feature.json does not exist.

### Mandatory output format

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
