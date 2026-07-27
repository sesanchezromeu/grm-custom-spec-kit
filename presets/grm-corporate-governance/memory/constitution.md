# GRM E2E Demo Constitution

**Version**: 1.0.0-demo  
**Status**: Proposed for next E2E validation  
**Date**: 2026-07-27  
**Purpose**: Enable an end-to-end demonstrable validation of GRM Custom Spec Kit using a minimal, executable, browser-based application.

---

## 1. Scope and Intent

This constitution applies only to **E2E demo validations** of GRM Custom Spec Kit.

Its purpose is not to define a production technical stack. Its purpose is to ensure that each E2E validation produces a result that can be:

- opened in a browser,
- demonstrated to a stakeholder,
- manually validated against acceptance criteria,
- documented from PBI to delivery evidence.

This constitution deliberately prioritizes **demonstrability, simplicity and traceability** over corporate frontend architecture fidelity.

---

## 2. Core Principle

### I. Specification before code

The workflow remains PBI-driven.

Mandatory sequence:

```text
PBI -> corp.load -> corp.assess -> corp.plan -> speckit.plan -> speckit.tasks -> speckit.implement -> corp.doc
```

Rules:

- The approved PBI is the source of truth.
- Acceptance criteria must be preserved through all generated artifacts.
- No functionality outside the PBI may be introduced silently.
- Any gap, deviation or improvement must be recorded in the delivery documentation.

---

### II. Demonstrable output is mandatory

A PBI is not considered implemented for E2E demo purposes unless it produces a runnable user-facing result.

Minimum required output:

```text
frontend/
├── index.html
├── styles.css
├── app.js
├── README.md
└── evidence.md
```

The delivered application must be executable by opening `index.html` directly in a browser or by running a simple local static server.

A solution consisting only of services, tests, classes, components or documentation is not sufficient for this constitution.

---

### III. Technology stack for E2E demo

The default technology stack is intentionally simple:

| Layer | Required technology |
|---|---|
| UI | HTML5 |
| Styling | CSS3 |
| Logic | JavaScript ES Modules or plain JavaScript |
| Runtime | Browser |
| Backend | Not allowed |
| Database | Not allowed |
| Build step | Not required |
| Package manager | Optional, but discouraged |
| Frameworks | Not allowed unless explicitly approved |

This stack is selected to minimize setup risk and maximize demo reliability.

---

### IV. Complete vertical slice per PBI

Each PBI must deliver one complete, demonstrable user flow.

A valid implementation must include:

- visible UI,
- input controls,
- user-triggered action,
- result or feedback,
- validation messages,
- empty/default state,
- error/invalid state where applicable.

Partial technical layers are not valid deliverables for this constitution.

Invalid examples:

- only domain services,
- only tests,
- only templates without executable wiring,
- only documentation,
- only generated component files without browser runtime.

---

### V. Manual validation is mandatory

Every E2E demo must include manual validation evidence.

At minimum, `evidence.md` must contain:

| Field | Required |
|---|---|
| Browser used | Yes |
| How to run | Yes |
| Acceptance criteria validated | Yes |
| Inputs used | Yes |
| Expected result | Yes |
| Actual result | Yes |
| Pass/fail | Yes |
| Observations | Yes |

Automated tests may be generated, but they do not replace manual evidence for E2E demo validation.

---

## 3. Quality Gates

### Gate 1. PBI loaded

The workflow may continue only if:

- the PBI is loaded into `active-pbi.md`,
- acceptance criteria are identified,
- out-of-scope items are preserved or explicitly marked.

---

### Gate 2. Plan generated

The plan must explicitly state:

- that the output is a browser-executable demo,
- that no backend/database/build pipeline is required,
- how the user will run the application,
- which files will be generated.

---

### Gate 3. Tasks generated

Tasks must include explicit implementation of:

- `index.html`,
- `styles.css`,
- `app.js`,
- browser interaction wiring,
- acceptance criteria validation,
- `README.md`,
- `evidence.md`.

A task plan that only creates models, services or tests is incomplete.

---

### Gate 4. Implementation generated

The implementation passes only if:

- `index.html` exists,
- the application opens in a browser,
- the main user flow can be executed manually,
- validation errors are visible to the user,
- acceptance criteria can be checked from the UI.

---

### Gate 5. Delivery documentation generated

`delivery-doc.md` must classify the result as one of:

| Status | Meaning |
|---|---|
| COMPLIANT | Runnable and acceptance criteria validated |
| COMPLIANT_WITH_FINDINGS | Runnable, with non-blocking findings |
| PARTIAL | Logic exists but demo is incomplete |
| NON_COMPLIANT | Not runnable or acceptance criteria cannot be validated |

For demo E2E, any implementation without a browser-runnable UI must be classified at most as `PARTIAL`.

---

## 4. Acceptance Criteria for E2E Demo PBIs

Each PBI must define acceptance criteria that can be validated manually in the browser.

Preferred format:

```text
Given <initial state>
When <user action>
Then <visible result>
```

Acceptance criteria that cannot produce a visible or inspectable outcome should be rejected or clarified before implementation.

---

## 5. Documentation Rules

Generated documentation must remain inside the feature folder unless the PBI explicitly requests a framework documentation change.

Expected feature artifacts:

```text
features/<feature-id>/
├── spec.md
├── plan.md
├── tasks.md
├── evidence.md
└── delivery-doc.md
```

Protected corporate documentation must not be modified by feature implementation activities.

---

## 6. Explicit Non-Goals

This constitution does not validate:

- Angular readiness,
- corporate frontend template compliance,
- production architecture,
- CI/CD,
- deployment,
- authentication,
- persistence,
- backend integration,
- full accessibility certification,
- enterprise design system compliance.

Those concerns belong to a production or corporate-stack constitution, not to this E2E demo constitution.

---

## 7. Rationale

The previous frontend-lite validation produced a coherent TypeScript feature with tests and documentation, but it did not produce a browser-executable application. That result was useful for validating workflow mechanics, but insufficient for demonstration purposes.

This constitution corrects that gap by making the runnable browser demo a non-negotiable outcome.

---

## 8. Recommended Use

Use this constitution when the objective is to validate:

- full workflow continuity,
- PBI-to-code traceability,
- generated documentation quality,
- demonstrable functional output,
- onboarding simplicity for non-maintainer reviewers.

Do not use this constitution to validate a real corporate application stack.
