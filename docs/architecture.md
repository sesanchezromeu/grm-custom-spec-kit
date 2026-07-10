# GRM Custom Spec Kit - Architecture Guide

## 1. Overview

GRM Custom Spec Kit is a corporate customization of Spec Kit that introduces governance, Product Driven Development and controlled adoption of Spec Driven Development without maintaining a fork of the upstream product.

Design principle:

```text
Customize around Spec Kit
Never modify Spec Kit core
```

---

## 2. Architecture

```text
+----------------+
|  Product Owner |
+--------+-------+
         |
         v
+----------------+
| PBI Markdown   |
+--------+-------+
         |
         v
+----------------+
| /corp.load     |
+--------+-------+
         |
         v
+----------------+
| active-pbi.md  |
+--------+-------+
         |
         v
+----------------+
| /corp.assess   |
+--------+-------+
         |
         v
+----------------+
| /corp.plan     |
+--------+-------+
         |
         v
+----------------+
| /speckit.plan  |
+--------+-------+
         |
         v
+----------------+
| /speckit.tasks |
+--------+-------+
         |
         v
+----------------+
|/speckit.implement|
+----------------+
```

---

## 3. Repository Structure

```text
.github/
├── agents/
├── prompts/

docs/
extensions/
presets/
pilots/
samples/
```

### Agents

Contain command behavior.

### Prompts

Contain command invocation definitions.

### Docs

Project knowledge base.

---

## 4. Corporate Commands

### corp.load

Purpose:

- Load approved PBI.
- Create active context.

Output:

```text
.specify/memory/active-pbi.md
```

### corp.assess

Purpose:

- Readiness assessment.
- Governance gate.

Characteristics:

- Read only.
- No artifacts generated.

### corp.plan

Purpose:

- Corporate bootstrap.

Output:

```text
features/<feature>/spec.md
```

### Corporate Guard

Implemented in:

```text
speckit.plan.agent.md
```

Blocks execution if the mandatory corporate flow has not been followed.

---

## 5. Design Decisions

### D01 - No Fork

Reason:

- Easier upgrades.
- Lower maintenance.
- Better compatibility.

### D02 - PBI as Source of Truth

Reason:

- Traceability.
- Alignment with Product Ownership.

### D03 - Read-Only Analysis

Applied to:

```text
corp.assess
```

Reason:

Prevent uncontrolled modifications.

### D04 - Bootstrap Pattern

Applied to:

```text
corp.plan
```

Reason:

Reuse native Spec Kit planning capabilities.

---

## 6. Governance Model

Allowed:

```text
corp.load
corp.assess
corp.plan
speckit.plan
speckit.tasks
speckit.implement
```

Blocked:

```text
speckit.specify
speckit.clarify
```

---

## 7. Key Findings from POC

- Custom commands are viable.
- GitHub Copilot agents can enforce workflow rules.
- No fork is required.
- PBI-driven workflow is feasible.
- Native planning can be reused.
- Governance can be applied using extensions and prompts.

---

## 8. Technical Debt

Current limitations:

- Local markdown PBIs only.
- No Azure DevOps integration.
- No MCP integration.
- Manual validation activities remain.

---

## 9. Future Evolution

### Phase 2

- Azure DevOps integration.
- MCP integration.
- Improved reporting.

### Phase 3

- corp.doc command.
- Delivery report generation.
- Delta management support.

### Phase 4

- Enterprise rollout.
- Training materials.
- Governance dashboards.
