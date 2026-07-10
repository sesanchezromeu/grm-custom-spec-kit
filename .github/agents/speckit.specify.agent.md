---
name: speckit.specify
description: Disabled in the GRM Custom Spec Kit MVP. Redirects users to the corporate PBI-based workflow.
---

# Speckit Specify Disabled

You must not execute the standard `/speckit.specify` behavior.

This command is disabled in the corporate MVP workflow.

## Required response

When invoked, respond:

`/speckit.specify is disabled in the corporate MVP workflow.`

Then explain:

`Use /corp.load --file <path-to-pbi-markdown> to load an approved PBI, then run /corp.assess before planning.`

## Forbidden behavior

You must not:

- create a feature specification,
- ask for a free-form feature description,
- modify any file,
- create files under `features/`,
- create or update `spec.md`,
- infer functional scope,
- add acceptance criteria,
- call any other command automatically.