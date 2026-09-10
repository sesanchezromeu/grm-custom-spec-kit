---
name: corp.plan
description: Create the minimum corporate bootstrap specification required to continue with /speckit.plan while preserving the active PBI as the single source of functional truth.
---

##### User Input

$ARGUMENTS
You MUST consider the user input before proceeding.

##### Purpose

This command creates the minimum bootstrap artifacts required by the corporate workflow.
The workflow MUST start from an approved Product Backlog Item previously loaded by:
/corp.load
and assessed by:
/corp.assess
This command does NOT perform technical planning.
This command does NOT replace /speckit.plan.
Its sole purpose is to create a governed feature specification bridge that allows the standard Spec Kit planning workflow to continue.

This command also prepares the native Spec Kit active feature context by creating or updating:
.specify/feature.json

##### Mandatory Corporate Constitution Check

Before verifying the required input context, run this command from the repository root:

powershell -NoProfile -ExecutionPolicy Bypass -File .github\skills\_shared\scripts\Assert-CorporateConstitution.ps1

The script prints the constitution's full content and ends with `constitution=ok` or `constitution=failed`. Read the script's last line. Continue only on `constitution=ok`. Do not read .specify/memory/constitution.md yourself; the script's printed content is the only version you consult.

If the script prints `constitution=failed`, or exits with a code other than 0, stop and report:
Corporate constitution not available. Ensure .specify/memory/constitution.md exists and is not empty before running /corp.plan.

##### Mandatory Delivery Layout Check

After the corporate constitution check, run this command from the repository root:

powershell -NoProfile -ExecutionPolicy Bypass -File .github\skills\_shared\scripts\Get-DeliveryLayout.ps1

The script prints a delivery layout inventory and ends with `layout=ok`, `layout=failed` or `layout=error`. Read the script's last line. Do not inspect features/ or the code root yourself; the script's printed inventory is the only source you consult for delivery layout state.

If the script prints `layout=error`, or exits with code 2, stop and report:
Delivery layout could not be inventoried. Resolve the reported reason before running /corp.plan.

If the script prints `layout=failed`, do NOT stop. Continue, and record the reported disallowed files in the Delivery Layout section of spec.md. /corp.plan does not move files and does not fix the layout; the layout gate is enforced by /corp.doc before delivery.

Use the printed values of `src-present`, `src-subdirectories` and `delivered-pbis` to fill the Delivery Layout section of spec.md. Do not infer any of them from any other source.

##### Required Input Context

Before proceeding, verify that the following file exists:
.specify/memory/active-pbi.md

If the file does not exist, stop and report:
No active PBI found.
Run:
/corp.load --file <path-to-pbi.md>
before running:
/corp.plan

##### Governance Rules

The active PBI is the only source of functional scope.
Do not invent requirements.
Do not invent acceptance criteria.
Do not modify acceptance criteria.
Do not expand business scope.
Do not redefine business intent.
Do not create technical plans.
Do not create implementation tasks.
Do not create design decisions.
Do not resolve Product Owner clarifications on behalf of the Product Owner.

If ambiguities are detected:
- Functional ambiguities must be reported as Product Owner clarifications.
- Technical ambiguities must be reported as Technical Clarifications.

The generated specification MUST preserve traceability to:
.specify/memory/active-pbi.md

##### Feature Directory Resolution

Resolve a feature directory using the active PBI.

Preferred rules:
- Use PBI ID when available.
- Use a normalized kebab-case title.
- Use lowercase.
- Remove special characters.
- Keep the resulting path deterministic and readable.

Example:
features/pbi-1234-download-shipment-documents

If the features directory does not exist, create it.
Create the feature directory if required.

##### Required Artifacts

Create only:
- features/<feature>/spec.md
- .specify/feature.json

Do not create:
- plan.md
- research.md
- data-model.md
- quickstart.md
- contracts/
- openapi.yaml
- tasks.md
- delivery-doc.md

Those artifacts belong to later workflow steps:
- /speckit.plan
- /speckit.tasks
- /speckit.implement
- /corp.doc

##### Native Spec Kit Feature Context

Create or update:
.specify/feature.json

The file MUST point to the resolved feature directory and MUST use this structure:

```json
{
  "feature_directory": "features/<feature>"
}
```

The feature_directory value MUST match the generated feature directory exactly.
Use a repository-relative path.
Do not use an absolute local filesystem path.
Do not include trailing slashes.

##### spec.md Requirements

Generate the following structure.

## Feature Specification Bridge: [PBI Title]

### Corporate Bootstrap

Generated by: /corp.plan
Source of truth:
.specify/memory/active-pbi.md
Purpose:
Enable /speckit.plan while preserving the approved PBI as the functional authority.

### Source PBI
- PBI ID: [PBI ID]
- Title: [Title]

### Business Purpose

[Short purpose derived from the active PBI]

### Scope Governance
- The active PBI is the source of functional scope.
- Acceptance criteria are owned by the active PBI.
- This document does not redefine scope.
- This document does not introduce requirements.
- Any scope change must be handled through the Product Owner process.
- This document exists solely to bootstrap the standard Spec Kit planning workflow.

### Delivery Layout

- Code root: [directory declared by the corporate constitution; if the constitution declares no code directory structure, use src/]
- Process documentation root: features/<feature>/
- Existing product: [yes if delivered-pbis is not none, otherwise no]
- Previously delivered PBIs: [value of delivered-pbis]
- Code root state: [value of src-present, and src-subdirectories when present]
- Layout status at planning time: [layout=ok, or layout=failed followed by the reported disallowed files]

Rules:
- No implementation file may be created or modified under features/. features/ holds process documentation only.
- Implementation files belong under the code root, in subdirectories named after their nature, for example frontend/, backend/, api/, db/, tests/.
- If the product already exists, modify existing files in place under the code root. Do not duplicate, re-create or re-implement existing artifacts in a new location.
- All code paths written in this document are repository-relative and canonical, never relative to the feature folder.

This section reports observed repository state and the corporate layout rules. It does not define scope and does not introduce requirements.

### Description

[Description copied from active-pbi.md]

### Business Context

[Business Context copied when available]

### Acceptance Criteria

[Copy acceptance criteria from active-pbi.md without modification]

### Constraints

[Constraints copied when available]

### Dependencies

[Dependencies copied when available]

### Out of Scope

[Out of Scope copied when available]

### Product Owner Clarifications Required

[List functional ambiguities]

If none:
None identified.

### Technical Clarifications Required

[List technical ambiguities]

If none:
None identified.

### Explicit business catalogs and value sets

If the approved PBI contains an explicit finite list of allowed values, options, rates, statuses, document types, categories, operation types, countries, currencies or similar business catalogs, the complete list must be preserved in spec.md exactly as defined in the source PBI.

The command must not reduce, rewrite, simplify or reinterpret the catalog based only on acceptance criteria examples.

Acceptance criteria demonstrate expected behavior.
They do not replace or restrict an explicitly defined business catalog.

Examples:
- VAT rates
- Status values
- Document types
- Categories
- Countries
- Currencies

When a finite catalog exists, spec.md must contain an explicit section:

#### Allowed Values

The complete catalog must be copied from the approved PBI.

This information must remain available for downstream commands:
- speckit.plan
- speckit.tasks
- speckit.implement
- corp.doc

Failure to preserve explicitly approved business catalogs is considered a scope-loss defect.

##### Validation

Before reporting completion verify:
- active-pbi.md was successfully read
- feature directory exists
- spec.md exists
- .specify/feature.json exists
- .specify/feature.json points to the resolved feature directory
- traceability to active-pbi.md is present
- acceptance criteria were preserved
- no functional scope was added
- no technical planning content was generated
- no additional planning, task, implementation, or delivery artifacts were generated

Specifically confirm that the following artifacts were NOT generated by /corp.plan:
- plan.md
- research.md
- data-model.md
- quickstart.md
- contracts/
- openapi.yaml
- tasks.md
- delivery-doc.md

##### Completion Report

Report:
- Active PBI path
- Feature directory path
- spec.md path
- .specify/feature.json path
- Traceability status
- Product Owner clarifications
- Technical clarifications
- Validation checks passed

Recommended next command:
/speckit.plan

##### Done When

- .specify/memory/active-pbi.md has been read
- feature directory exists
- spec.md exists
- .specify/feature.json exists and points to the generated feature directory
- acceptance criteria traceability is present
- no additional planning artifacts have been generated
- completion report has been produced
