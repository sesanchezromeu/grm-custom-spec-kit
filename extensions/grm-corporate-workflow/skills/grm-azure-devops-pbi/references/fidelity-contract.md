# Fidelity contract — Azure DevOps backlog source

Normative for `Get-WorkItem.ps1` (P12) and `ConvertTo-MarkdownFromHtml.ps1` (P13).
Derived from `GRM-SCK_Plan_Backlog_Azure_DevOps_v1.md` §5.

## 0. Division of labour

Every rule in this document is enforced **by the scripts**, not by the agent.
The scripts return a normalized JSON payload (§5) whose values are final strings.
The agent copies them into `active-pbi.md`; it never maps fields, never converts
HTML, never decides a fallback value and never judges whether a load is complete.

This is a deliberate constraint. An agent asked to apply a mapping table
reconstructs identifiers instead of copying them, and collapses structured
content into prose. Both failure modes are silent. A script either produces the
value or exits with a non-zero code.

## 1. Envelope

| Field | Value |
|---|---|
| Type | `Azure DevOps work item` |
| Reference | normalized URL, or `<key>:<id>` exactly as provided |
| Organization | organization segment |
| Project | `System.TeamProject`, after F-01 |
| Work item ID | `System.Id` |
| Work item type | `System.WorkItemType` |
| Revision | `rev` — mandatory, never `Not applicable` |
| Changed at | `System.ChangedDate` |
| Retrieved via | `REST API v7.1` |
| Loaded at | ISO 8601 timestamp of retrieval |

A file is immutable; a work item is not. Without `Revision`, traceability breaks
at the first edit made after the load.

Fields that do not apply are the literal string `Not applicable`. Never blank,
never omitted, never guessed.

## 2. Field mapping

| Source | Destination section | Note |
|---|---|---|
| `System.Title` | `title` | |
| `System.Description` | `description` | Converted per §3. Absent → error |
| `Microsoft.VSTS.Common.AcceptanceCriteria` | `acceptance_criteria` | Idem. Absent → error |
| `System.State`, `System.Reason` | `governance_notes` | Informative |
| `Microsoft.VSTS.Scheduling.Effort` | `notes` | |
| `Custom.*` | `constraints` or `notes` | Labelled with the field name |
| `System.Parent`, `Hierarchy-Reverse` | `dependencies` | Reference only, not retrieved |
| `Hierarchy-Forward` | `notes` | ID list, not retrieved |
| `WEF_*` | — | Always discarded |
| `System.BoardColumn*`, `Watermark`, `PersonId`, `AreaId`, `NodeName`, `AreaLevel*`, `IterationLevel*` | — | Discarded |

An absent field is not an empty field: Azure DevOps omits fields with no value,
so absence cannot be distinguished from a query error by inspection. Absence of
a mandatory field is a load failure, not an empty section.

## 3. Content conversion

`multilineFieldsFormat` declares the real format per field.

- Declared `markdown` → copied literally. Zero conversion, zero loss.
- Declared `html` → converted by `ConvertTo-MarkdownFromHtml.ps1`.

The HTML observed in this organization originates in an external tool and is not
clean Azure DevOps markup.

| Pattern | Treatment |
|---|---|
| `style`, `class` attributes | Discard |
| Empty nodes (`<div><br></div>`) | Discard before converting |
| Entities (`&nbsp;`, `&quot;`) | Decode |
| Typographic quotes | Preserve literally |
| `<br>` inside `<li>` | Line continuation, **not** a new bullet |

Conversion walks the DOM. Regular expressions are not an acceptable
implementation: they do not preserve depth reliably, and depth carries meaning.

Parsing uses `New-Object -ComObject HTMLFile`, verified to preserve nesting in
the target environment. Two properties of that parser are load-bearing:
tag names are normalized to upper case, so comparisons must be case-insensitive;
and optional closing tags are omitted, so the tree must be walked, never scanned.

## 4. Rules

| ID | Rule |
|---|---|
| F-01 | Cross-validation: `System.TeamProject` different from the project configured for the key → error, no load |
| F-02 | Accepted types: `Product Backlog Item`, `User Story`. Any other → error |
| F-03 | Comments are not incorporated. `System.CommentCount > 0` → warning |
| F-04 | Child work items are not retrieved. They are implementation tasks and would contaminate functional scope |
| F-05 | Attachments are referenced by URL, never downloaded |
| F-06 | Identities: `displayName` only. Never e-mail, `descriptor` or `uniqueName` |
| F-07 | Textual completeness verification (§4.1) after conversion. Failure → error, never a partial load |
| F-08 | Nesting depth is preserved with two-space indentation per level. The bullet character is discarded |
| F-09 | `ArtifactLink` relations are discarded from the payload; their presence is reported as a warning |
| F-10 | The PAT must be scoped to a single organization. A requirement, not a recommendation |

F-01 exists because work item identifiers are unique per **organization**, not
per project: a query naming the wrong project returns the work item anyway,
with no error. Without the cross-check, `<key>:<id>` silently loads a PBI from
another project.

### 4.1 Completeness verification

1. From the source HTML: strip tags, decode entities, collapse whitespace → token sequence `S`
2. From the generated Markdown: strip list markers and indentation → sequence `M`
3. Assert `S == M`. Any difference → load failure

Structure preservation is verified separately, by comparing the depth profile of
the source tree against the depth profile of the generated Markdown.

Both verifications are performed by the script and their counts are returned in
the payload. A verification asserted in prose by the agent is not a verification:
in observed runs the agent reported nine headings where there were fifteen.

## 5. Normalized output contract

`Get-WorkItem.ps1` writes one JSON object to stdout and nothing else. Diagnostics
go to stderr.

```json
{
  "schema": "grm-azure-devops-pbi/normalized-pbi@1",
  "status": "ok",
  "envelope": {
    "type": "Azure DevOps work item",
    "reference": "https://dev.azure.com/<org>/<project>/_workitems/edit/<id>",
    "organization": "<org>",
    "project": "<project>",
    "work_item_id": "<id>",
    "work_item_type": "Product Backlog Item",
    "revision": "<rev>",
    "changed_at": "<ISO 8601>",
    "retrieved_via": "REST API v7.1",
    "loaded_at": "<ISO 8601>"
  },
  "sections": {
    "title": "<string>",
    "description": "<markdown>",
    "business_context": "<markdown or literal fallback>",
    "acceptance_criteria": "<markdown>",
    "constraints": "<markdown or literal fallback>",
    "dependencies": "<markdown or literal fallback>",
    "out_of_scope": "<markdown or literal fallback>",
    "notes": "<markdown or literal fallback>",
    "governance_notes": "<markdown>"
  },
  "verification": {
    "text_completeness": { "passed": true, "source_tokens": 0, "payload_tokens": 0 },
    "depth_profile": { "passed": true, "source": [0], "payload": [0] },
    "heading_counts": { "source": {}, "payload": {} }
  },
  "warnings": [],
  "errors": []
}
```

Contract rules, all of them consequences of failure modes observed in this
repository:

- Every `envelope` and `sections` value is a **string**, always present, never
  `null`. A section with no source content carries the literal
  `Not specified in the source PBI`. The agent must never choose a fallback.
- `reference` is produced by the script from its own input. The agent does not
  restate it and does not derive it from the URL it was shown.
- `status` is `ok` or `error`. On `error`, `sections` is absent, `errors` is
  populated and the exit code is non-zero.
- Any verification with `passed: false` forces `status: error`. A payload that
  fails verification is never returned as loadable.
- Section values are Markdown fragments **without** their `##` heading. The
  heading belongs to the `active-pbi.md` template owned by `corp.load`.

## 6. Error catalogue

Exit code is non-zero for all of them.

| Condition | Message |
|---|---|
| Reference syntax not recognized | `Invalid backlog reference. Use a work item URL or <key>:<id>.` |
| Key absent from catalogue | `Backlog key '<key>' not found. Available keys: <list>.` |
| Catalogue file missing | `Backlog catalogue not found at .specify/grm-backlog.yml.` |
| `AZDO_PAT` not set | `AZDO_PAT is not set in the environment.` |
| HTTP 401 | `Authentication failed. The most likely cause is an expired PAT; check its expiry date before investigating scopes or permissions.` |
| HTTP 404 | `Work item <id> not found in organization <org>.` |
| F-01 violation | `Project mismatch: work item <id> belongs to '<actual>', but key '<key>' is configured for '<configured>'. Not loaded.` |
| F-02 violation | `Work item type '<type>' is not accepted. Expected Product Backlog Item or User Story.` |
| Mandatory field absent | `Work item <id> has no <field>. It cannot be loaded as a PBI.` |
| F-07 failure | `Conversion verification failed: <detail>. The PBI was not loaded.` |

The 401 message names expiry first on purpose. Diagnosed as a permissions
problem, an expired PAT costs an afternoon.