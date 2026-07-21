# GRM Custom Spec Kit - Architecture Guide

## 1. Overview

GRM Custom Spec Kit is a corporate customization of Spec Kit that introduces governance, Product Driven Development and controlled adoption of Spec Driven Development without maintaining a fork of the upstream product.

Design principles:

- Customize around Spec Kit.
- Never modify Spec Kit core.
- PBI as the functional source of truth.
- Maximum reuse of native Spec Kit capabilities.

---

## 2. Reference Architecture

```text
Product Owner
      ↓
PBI Markdown
      ↓
corp.erase
      ↓
corp.load
      ↓
active-pbi.md
      ↓
corp.assess
      ↓
corp.plan
      ↓
speckit.plan
      ↓
speckit.tasks
      ↓
speckit.implement
      ↓
corp.doc
      ↓
delivery-doc.md
```

Governance principle:

```text
No Plan Without Assessment
```

---

## 3. Repository Structure

```text
.github/        ← Validated Copilot runtime
.specify/       ← Spec Kit runtime
.vscode/

docs/
extensions/
presets/
samples/
```

### .github

Contains the validated GitHub Copilot runtime used during execution.

### .specify

Contains Spec Kit runtime artifacts:

- integrations
- scripts
- templates
- workflows
- constitution

### docs

Knowledge base and project documentation.

### extensions

Formal definition of GRM custom commands.

### presets

Formal definition of governance overrides.

---

## 4. Runtime Strategy

Current POC intentionally maintains two layers.

### Runtime Layer

```text
.github/
```

Contains the validated runtime currently executed by GitHub Copilot.

### Customization Layer

```text
extensions/
presets/
```

Contains the formal source structure of the GRM customization.

### Future Evolution

A future installation or synchronization mechanism should make:

```text
extensions + presets
        ↓
      .github
```

eliminating manual duplication.

---

## 5. Corporate Commands

### /corp.erase

Purpose:

- Clean execution context
- Prevent cross-PBI contamination
- Ensure reproducible workflow execution

Managed artifacts:

- `.specify/memory/active-pbi.md`
- `features/`
- `.specify/feature.json`

### /corp.load

Purpose:

- Ensure clean execution context
- Load approved PBI
- Generate active context

Output:

.specify/memory/active-pbi.md

Additional behavior:

- Automatically performs the equivalent cleanup of `/corp.erase`
- Verifies active context before reporting success

### /corp.assess

Purpose:

- Readiness assessment.
- Governance gate.

Characteristics:

- Read-only.
- No artifact generation.

### /corp.plan

Purpose:

- Generate corporate bootstrap.

Output:

```text
features/<feature>/spec.md
```

### corp.doc

Purpose:
Generate authoritative as-built documentation.

Output:

```text
features/<feature>/delivery-doc.md
```

Characteristics:
- Documentation only
- No source code modification
- Executes available validations when possible
- Uses implementation as source of truth
- Compares expected vs implemented behavior

### Corporate Guard

Implemented in:

```text
speckit.plan.agent.md
```

Blocks planning if the mandatory corporate workflow has not been followed.

---

## 6. Design Decisions

### D01 - No Fork

- Easier upgrades.
- Lower maintenance.
- Better compatibility.

### D02 - PBI as Source of Truth

- Product ownership alignment.
- Full traceability.

### D03 - Read-Only Assessment

Applied to:

```text
corp.assess
```

### D04 - Bootstrap Pattern

Applied to:

```text
corp.plan
```

Allows reuse of native Spec Kit planning.

### D05 - Explicit Context Management

### D05 - Explicit Context Management
- corp.erase
- corp.load

### D06 - As-Built Documentation

Applied to:
- corp.doc

Rationale:
- Keep documentation synchronized with implementation
- Detect implementation drift
- Capture technical debt
- Capture validation gaps
- Support future PBI creation

---

## 7. Governance Model

### Allowed

```text
corp.erase
corp.load
corp.assess
corp.plan
speckit.plan
speckit.tasks
speckit.implement
```

### Blocked

```text
speckit.specify
speckit.clarify
```

---

## 8. Validated Scenarios

Validated successfully:

```text
corp.erase
↓
corp.load
↓
corp.assess
↓
corp.plan
↓
speckit.plan
↓
speckit.tasks
↓
speckit.implement
↓
corp.doc
```

Result:

```text
END-TO-END VALIDATED
```

Validation performed using multiple PBIs and a clean Spec Kit installation.

---

## 9. Key Findings

- Custom commands are viable.
- Governance can be enforced through Copilot agents.
- No fork is required.
- PBI-driven workflows are feasible.
- Native planning can be reused.
- The solution is portable and reproducible.
- Context contamination can be eliminated through automated cleanup.
- Runtime context management improves repeatability of PBI-driven workflows.

---

## 10. Technical Debt

Current limitations:

- Markdown PBI source only.
- No Azure DevOps integration.
- No MCP integration.
- Runtime/customization duplication.
- Additional Spec Kit commands not yet governed.

---

## 11. Roadmap

### v0.2

- Installation model refinement.
- Runtime synchronization.

### v0.3

- Azure DevOps integration.
- MCP integration.

### v0.4

- corp.doc.
- Delivery reporting.

### v1.0

- Enterprise-ready framework.
- Governance dashboards.
- Training materials.
