# GRM Corporate Workflow Extension

This extension adds GRM corporate commands to a Spec Kit project.

## Commands

- `/corp.load`
- `/corp.assess`
- `/corp.plan`

## Purpose

The extension enforces a Product Backlog Item driven workflow where the approved PBI becomes the functional source of truth.

## Flow

```text
/corp.load --file <pbi.md>
        ↓
/corp.assess
        ↓
/corp.plan
        ↓
/speckit.plan
