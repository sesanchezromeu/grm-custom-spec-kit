# GRM Corporate Workflow Extension

This extension adds GRM corporate commands to a Spec Kit project.

## Commands

- `/corp.erase`
- `/corp.load`
- `/corp.assess`
- `/corp.plan`

## Purpose

The extension enforces a Product Backlog Item driven workflow where the approved PBI becomes the functional source of truth.

## Flow

/corp.erase (optional manual execution)
        ↓
/corp.load --file <pbi.md>
        ↓
(corporate cleanup executed automatically)
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