@echo off
setlocal

REM Wrapper for bootstrap-grm-e2e.ps1
REM Usage:
REM   bootstrap-grm-e2e.bat -TargetName e2e-demo-01
REM   bootstrap-grm-e2e.bat -TargetName e2e-demo-01 -InstallMode CleanInstall -Force
REM   bootstrap-grm-e2e.bat -TargetName e2e-demo-01 -InstallMode UpdateExisting

set "SCRIPT_DIR=%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%bootstrap-grm-e2e.ps1" %*

endlocal
