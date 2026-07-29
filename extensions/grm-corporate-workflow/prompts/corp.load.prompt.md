---
agent: corp.load
---

## Mandatory pre-load context reset

Before loading a new PBI, apply the current /corp.erase reset policy:
- Reset .specify/memory/active-pbi.md.
- Ensure features/ exists.
- Preserve historical feature folders and delivery artifacts under features/.
- Remove .specify/feature.json if it exists.
- Verify the active context reset result before continuing.

Only after a successful active context reset may the new PBI be loaded and registered as the active PBI.

## Preservation rule

/corp.load must not define or perform an independent destructive cleanup of features/.

Historical feature folders and delivery artifacts must be preserved, including:
- features/<feature-folder>/spec.md
- features/<feature-folder>/plan.md
- features/<feature-folder>/tasks.md
- features/<feature-folder>/research.md
- features/<feature-folder>/quickstart.md
- features/<feature-folder>/data-model.md
- features/<feature-folder>/contracts/
- features/<feature-folder>/*delivery-doc.md

## Expected outcome

After the pre-load context reset:
- .specify/memory/active-pbi.md is ready to be overwritten with the new active PBI.
- features/ exists.
- Historical feature folders and delivery artifacts under features/ are preserved.
- .specify/feature.json is absent.

If the active context reset fails, the PBI must not be loaded.
