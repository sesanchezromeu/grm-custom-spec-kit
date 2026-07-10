# /corp.assess

Corporate PBI assessment gate for GRM Custom Spec Kit.

This command evaluates whether the active PBI is ready for technical planning.

It must be executed after:

`/corp.load`

and before:

`/corp.plan`

## Core principle

No plan without assessment.

A PBI must not move into technical planning until its completeness, consistency and readiness have been assessed.

## Source of truth

The only functional source of truth is:

`.specify/memory/active-pbi.md`

Read this file before doing anything else.

If the file does not exist, stop and respond:

`No active PBI found. Run /corp.load --file <path-to-pbi-markdown> before using /corp.assess.`

## Read-only contract

This command is always read-only.

You must not create, modify, overwrite, rename or delete files.

You must not generate planning artifacts.

You must not modify the PBI.

You must not modify acceptance criteria.

You must not add functional requirements.

You must not infer or complete missing business behavior.

There is no `--apply` mode for `/corp.assess`.

If the user asks to apply changes, explain that `/corp.assess` only produces an assessment in chat.

## Purpose

Assess whether the currently active PBI is ready to proceed to technical planning.

The assessment must help determine whether the next valid command is:

- `/corp.plan`
- additional Product Owner clarification
- PBI refinement before continuing

## Required output

Produce a structured assessment with the following sections.

---

## 1. Active PBI summary

Summarize only what is explicitly available in the PBI:

- PBI ID
- Title
- Objective
- Business context
- Acceptance criteria
- Constraints
- Dependencies
- Out of scope items, if stated

If a field is missing, write:

`Not specified in the PBI.`

Do not invent missing information.

---

## 2. Assessment checklist

Use the following checklist.

Use these symbols:

- ✅ Passed
- ⚠️ Partial / risk detected
- ❌ Missing / blocking issue
- N/A Not applicable or not enough evidence

### Functional readiness

- Business objective is clearly stated
- Functional scope is clear
- Acceptance criteria are present
- Acceptance criteria are testable
- Expected user/system behavior is clear
- Error or exception scenarios are described, if relevant
- Out of scope is defined, if relevant
- Functional dependencies are identified, if relevant

Guidance:

A missing "out of scope" section is not automatically a blocking issue.

If the business objective, scope and acceptance criteria are sufficiently clear, classify missing out-of-scope information as:

⚠️ Partial / risk detected

instead of:

❌ Missing / blocking issue

Only treat missing out-of-scope information as blocking when it creates real ambiguity about the functional boundaries of the feature and would force the developer or AI to make functional decisions.

### Technical readiness

- Affected system or component can be identified
- Integration points can be identified, if relevant
- Data impact can be inferred from explicit PBI content
- API impact can be inferred from explicit PBI content
- Security or permissions impact is mentioned, if relevant
- Performance, volume or scalability constraints are mentioned, if relevant
- Migration or backward compatibility needs are mentioned, if relevant

### Planning readiness

- The PBI contains enough information to estimate technical approach
- The PBI contains enough information to identify likely implementation areas
- The PBI contains enough information to derive technical tasks later
- The PBI contains enough information to define applicable testing levels
- There are no blocking functional ambiguities

## Blocking issue definition

An item is BLOCKING only if technical planning cannot continue safely without resolving it.

An item must NOT be classified as BLOCKING if:

- planning can continue safely,
- the uncertainty can be tracked as a risk,
- the uncertainty can be tracked as a technical assumption,
- the uncertainty can be clarified later without changing the core implementation approach.

Examples of NON_BLOCKING items:

- Missing explicit out-of-scope section
- Additional business scenarios requiring confirmation
- Security rules requiring validation
- Additional document types requiring clarification
- External dependency details still pending

When uncertain between:

BLOCKING

and

NON_BLOCKING

prefer:

NON_BLOCKING.

---

## 3. Functional gaps or ambiguities

List any missing or unclear functional information.

Classify each item as:

- BLOCKING
- NON_BLOCKING
- INFORMATIONAL

For each item include:

- Description
- Why it matters
- Who should clarify it

Functional gaps must be assigned to the Product Owner.

Do not resolve them yourself.

---

## 4. Technical readiness observations

List observations that may affect technical planning.

Examples:

- likely impacted components,
- possible dependencies,
- integration considerations,
- data considerations,
- API considerations,
- testability considerations,
- documentation considerations.

Clearly distinguish:

- explicitly stated information,
- technical inference,
- assumption requiring validation.

---

## 5. Risks

List risks using this format:

### R-XX — Risk title

- Description:
- Impact:
- Severity: High / Medium / Low
- Owner: Product Owner / Tech Lead / Developer / Architecture / QA
- Requires resolution before `/corp.plan`: Yes / No

Do not assign functional decisions to the Developer.

---

## 6. Questions for the Product Owner

List only the questions that require Product Owner clarification.

Use this format:

### Q-XX

Question:

Reason:

Blocks `/corp.plan`: Yes / No

If there are no Product Owner questions, write:

`No Product Owner clarification required based on the available PBI content.`

---

## 7. Technical assumptions

List technical assumptions that may be acceptable for planning.

Use this format:

### A-XX

Assumption:

Basis:

Validation owner:

Impact if wrong:

Clearly state that assumptions do not modify the functional scope.

If there are no technical assumptions, write:

`No technical assumptions identified.`

---

## 8. Assessment score

Calculate an indicative readiness score.

### Functional readiness
0-40 points

### Technical readiness
0-35 points

### Planning readiness
0-25 points

Total:
0-100 points

Provide a brief explanation of the score.

Scores are indicative only and do not overrule governance decisions.

A PBI may score high and still be NOT_READY if blocking functional ambiguity exists.

---

## 9. Final verdict

Classify the PBI as exactly one of:

- READY
- READY_WITH_RISKS
- NOT_READY

Use the following decision rules.

### READY

Use when:

- acceptance criteria are present and testable,
- functional scope is sufficiently clear,
- no blocking Product Owner clarification is needed,
- enough information exists to proceed to `/corp.plan`.

### READY_WITH_RISKS

Use when:

- the PBI can proceed to `/corp.plan`,
- there are non-blocking risks, dependencies or technical assumptions,
- functional scope remains sufficiently clear.

Examples that normally lead to READY_WITH_RISKS:

- Missing explicit out-of-scope section
- Undefined authorization details
- Additional business scenarios requiring confirmation
- Additional document types requiring confirmation
- External system assumptions
- Technical dependencies still under investigation
- Error scenarios not fully documented

These situations normally do not block technical planning.

### NOT_READY

Use only when one or more of the following conditions exist:

- acceptance criteria are missing,
- acceptance criteria are not testable,
- functional scope cannot be determined,
- the business objective is unclear,
- requirements are contradictory,
- planning would require inventing business rules,
- planning would require inventing user behaviour,
- planning would require inventing acceptance criteria,
- planning would require redefining functional scope.

NOT_READY should be considered exceptional.

When uncertain between:

READY_WITH_RISKS

and

NOT_READY

prefer:

READY_WITH_RISKS.


---

## 10. Recommended next command

Recommend exactly one of:

- `/corp.plan`
- return to Product Owner for clarification
- refine PBI before continuing
- rerun `/corp.load` with an updated PBI

If the verdict is READY:

Recommend:

`/corp.plan`

If the verdict is READY_WITH_RISKS:

Recommend:

`/corp.plan`, with risks tracked.

If the verdict is NOT_READY:

Do not recommend `/corp.plan`.

Recommend Product Owner clarification or PBI refinement.

## Absolute restrictions

You must not:

- create files,
- edit files,
- overwrite files,
- delete files,
- generate `spec.md`,
- generate `plan.md`,
- generate `tasks.md`,
- generate `research.md`,
- generate `data-model.md`,
- generate `quickstart.md`,
- create or update anything under `features/`,
- update `.specify/memory/active-pbi.md`,
- call or suggest `/speckit.specify`,
- create a functional specification,
- add acceptance criteria,
- change acceptance criteria,
- invent missing behavior,
- convert assumptions into requirements.

This command produces analysis only.