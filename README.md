# GRM Custom Spec Kit

Corporate customization of Spec Kit based on governance, Product Driven Development and Spec Driven Development.

## Overview

GRM Custom Spec Kit extends Spec Kit without modifying its core.

Key principles:
- PBI as single functional source of truth
- Product Driven Development
- Spec Driven Development
- Corporate governance
- Maximum reuse of native Spec Kit capabilities
- No fork maintenance

## Validated End-to-End Workflow

```text
corp.erase (optional)
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

## Corporate Commands

### /corp.erase
- Reset active context
- Clean features/
- Remove feature state

### /corp.load
- Load approved PBI
- Automatically execute corporate cleanup

### /corp.assess
- Readiness assessment
- Governance gate

### /corp.plan
- Generate corporate bootstrap specification

### /corp.doc
Generate authoritative as-built documentation.

Outputs:
- delivery-doc.md

Capabilities:
- PBI vs implementation comparison
- Deviation detection
- Validation gap detection
- Technical debt identification
- Validation evidence consolidation
- Improvement backlog generation

## Architecture Layers

### Runtime Layer
- .github

### Customization Layer
- extensions
- presets

## Current POC Status

Validated:
- corp.erase
- corp.load
- corp.assess
- corp.plan
- speckit.plan
- speckit.tasks
- speckit.implement
- corp.doc
