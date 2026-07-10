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
/corp.load
      ↓
active-pbi.md
      ↓
/corp.assess
      ↓
/corp.plan
      ↓
/speckit.plan
      ↓
/speckit.tasks
      ↓
/speckit.implement
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

### /corp.load

Purpose:

- Load approved PBI.
- Generate active context.

Output:

```text
.specify/memory/active-pbi.md
```

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

---

## 7. Governance Model

### Allowed

```text
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
specify init --here
        ↓
Apply GRM customization
        ↓
corp.load
        ↓
corp.assess
        ↓
corp.plan
        ↓
speckit.plan
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
