# Bootstrap Installer

## Purpose

Portable Git-first installer for GRM Custom Spec Kit.

## Files

```text
bootstrap-grm-e2e.ps1
bootstrap-grm-e2e.bat
```

## Recommended Usage

```powershell
.\bootstrap-grm-e2e.bat -TargetName e2e-demo-01 -Force
```

## PowerShell Usage

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\bootstrap-grm-e2e.ps1 -TargetName e2e-demo-01 -Force
```

## What It Does

1. Creates a clean workspace.
2. Initializes Spec Kit.
3. Initializes Git.
4. Downloads GRM Custom Spec Kit from GitHub.
5. Applies extensions and presets.
6. Synchronizes runtime.
7. Copies samples.
8. Copies official documentation.
9. Installs constitution.
10. Generates installation-report.md.
11. Validates runtime.

## Expected Result

```text
Runtime validation passed
Installation report generated
Bootstrap completed
```

## Notes

- Manual installation remains the reference installation model.
- Bootstrap automates the same validated process.
- Both methods must produce equivalent results.
