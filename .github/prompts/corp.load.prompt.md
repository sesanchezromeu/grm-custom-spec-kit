---
agent: corp.load
---

## Mandatory pre-load cleanup

Before loading a new PBI, perform the following cleanup:

- Reset `.specify/memory/active-pbi.md`
- Clean all contents inside `features/`
- Remove `.specify/feature.json` if it exists
- Verify the cleanup result before continuing.

Only after a successful cleanup may the new PBI be loaded and registered as the active PBI.