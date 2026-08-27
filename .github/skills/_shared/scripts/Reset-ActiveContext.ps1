#Requires -Version 5.1
<#
    Reset-ActiveContext.ps1

    Reset the GRM corporate execution context: the active PBI stub, the
    features/ directory and the active feature pointer.

    Why a script does this (D-P16-CIERRE): across T-03 to T-07 the agent
    improvised this reset five times and produced three different mechanisms
    and encodings for the same two-line file. From T-06 on it stopped
    computing the four verification conditions and asserted them from a file
    read instead, including the preservation of features/, which cannot be
    established without comparing before and after. The PBI content is
    already mechanical; this stub was the last artifact on the load path
    still written by agent judgement.

    /corp.erase runs this command and reads the result. /corp.load runs the
    same command instead of restating the procedure. Neither writes these
    files itself.

    The reporting block below is a copy. The authority for its labels and
    wording is agents/corp.erase.agent.md, Completion contract. Same rule as
    $DEFAULT_GOVERNANCE in Build-ActivePbi.ps1 (D-P14b-03).

    One deliberate departure from that copy (D-P16f-06): on failure the first
    line reads 'Corporate context erase failed.' The contract's own opening
    line asserts that the context was erased, which sat directly above a
    'reset: failed' action line in the observed failure path. The success
    path prints the contract verbatim.

    Paths are fixed rather than parameters: the report prints them literally
    and corp.erase.agent.md forbids shortening or renaming them, so an
    override would desynchronise what is done from what is reported.

    Exit codes: 0 reset and verified, 1 failure.

    Usage:
      powershell -NoProfile -ExecutionPolicy Bypass -File .github\skills\_shared\scripts\Reset-ActiveContext.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$MEMORY_DIR   = '.specify/memory'
$ACTIVE_PBI   = '.specify/memory/active-pbi.md'
$FEATURES_DIR = 'features'
$POINTER      = '.specify/feature.json'

# The empty-state content required by corp.erase.agent.md, Expected final
# state. UTF-8 with BOM and CRLF, matching Build-ActivePbi.ps1, so the stub
# and a real active-pbi.md are written the same way.
$EMPTY_STATE = "# Active PBI`r`nNo PBI loaded.`r`n"

# Relative path plus size for every entry under features/. Sizes are included
# so that a truncated file counts as lost, not preserved.
function Get-FeatureSnapshot {
    if (-not (Test-Path -LiteralPath $FEATURES_DIR)) { return @() }
    $root = (Resolve-Path -LiteralPath $FEATURES_DIR).Path
    return @(
        Get-ChildItem -LiteralPath $root -Recurse -Force |
            ForEach-Object {
                $rel = $_.FullName.Substring($root.Length).TrimStart('\', '/')
                if ($_.PSIsContainer) { "D  $rel" } else { "F  $rel  $($_.Length)" }
            } | Sort-Object
    )
}

# ---------------------------------------------------------------------------
# 1. Snapshot before touching anything. Preservation is a comparison, not an
#    assertion, and it cannot be made after the fact.
# ---------------------------------------------------------------------------

$before = Get-FeatureSnapshot

# ---------------------------------------------------------------------------
# 2. Active PBI stub
# ---------------------------------------------------------------------------

$resetAction = 'done'
try {
    if (-not (Test-Path -LiteralPath $MEMORY_DIR)) {
        New-Item -ItemType Directory -Path $MEMORY_DIR -Force | Out-Null
    }
    # Combine with the session location: .NET resolves relative paths against
    # the process working directory, not the PowerShell one (HZ-06).
    [System.IO.File]::WriteAllText(
        [System.IO.Path]::Combine((Get-Location).Path, $ACTIVE_PBI),
        $EMPTY_STATE,
        (New-Object System.Text.UTF8Encoding($true)))
}
catch {
    $resetAction = 'failed'
    [Console]::Error.WriteLine("Active PBI stub could not be written to '$ACTIVE_PBI': $_")
}

# ---------------------------------------------------------------------------
# 3. features/ must exist. Its contents are never touched.
# ---------------------------------------------------------------------------

try {
    if (-not (Test-Path -LiteralPath $FEATURES_DIR)) {
        New-Item -ItemType Directory -Path $FEATURES_DIR -Force | Out-Null
    }
}
catch {
    [Console]::Error.WriteLine("features/ could not be created: $_")
}

# ---------------------------------------------------------------------------
# 4. Active feature pointer
# ---------------------------------------------------------------------------

$pointerAction = 'skipped'
if (Test-Path -LiteralPath $POINTER) {
    try {
        Remove-Item -LiteralPath $POINTER -Force
        $pointerAction = 'done'
    }
    catch {
        $pointerAction = 'failed'
        [Console]::Error.WriteLine("Active feature pointer could not be removed: $_")
    }
}

# ---------------------------------------------------------------------------
# 5. Verification. Every line below is computed here and nowhere else.
# ---------------------------------------------------------------------------

$activeReady = $false
if (Test-Path -LiteralPath $ACTIVE_PBI -PathType Leaf) {
    $abs  = (Resolve-Path -LiteralPath $ACTIVE_PBI).Path
    $text = ([System.IO.File]::ReadAllText($abs, [System.Text.Encoding]::UTF8) -replace "`r`n", "`n").TrimEnd("`n")
    $activeReady = ($text -ceq "# Active PBI`nNo PBI loaded.")
}

$featuresExists = Test-Path -LiteralPath $FEATURES_DIR -PathType Container

# Only disappearance counts. Anything added while the command ran belongs to
# whoever added it and is not this command's business.
$after     = Get-FeatureSnapshot
$preserved = $true
if ($before.Count -gt 0) {
    $lost = @($before | Where-Object { $after -notcontains $_ })
    $preserved = ($lost.Count -eq 0)
    foreach ($entry in $lost) {
        [Console]::Error.WriteLine("Historical feature artifact no longer present: $entry")
    }
}

$pointerAbsent  = -not (Test-Path -LiteralPath $POINTER)
$featuresAction = if ($featuresExists -and $preserved) { 'done' } else { 'failed' }

$ok = ($resetAction -eq 'done') -and
      ($featuresAction -eq 'done') -and
      ($pointerAction -ne 'failed') -and
      $activeReady -and $featuresExists -and $preserved -and $pointerAbsent

# ---------------------------------------------------------------------------
# 6. Report. Copy of the Completion contract; authority is corp.erase.agent.md.
# ---------------------------------------------------------------------------

if ($ok) { Write-Output 'Corporate context erased.' }
else     { Write-Output 'Corporate context erase failed.' }
Write-Output 'Actions:'
Write-Output ("- .specify/memory/active-pbi.md reset: {0}" -f $resetAction)
Write-Output ("- features/ preserved: {0}" -f $featuresAction)
Write-Output ("- .specify/feature.json removed: {0}" -f $pointerAction)
Write-Output 'Verification:'
Write-Output ("- .specify/memory/active-pbi.md ready: {0}" -f $(if ($activeReady) { 'yes' } else { 'no' }))
Write-Output ("- features/ exists: {0}" -f $(if ($featuresExists) { 'yes' } else { 'no' }))
Write-Output ("- historical feature artifacts preserved: {0}" -f $(if ($preserved) { 'yes' } else { 'no' }))
Write-Output ("- .specify/feature.json absent: {0}" -f $(if ($pointerAbsent) { 'yes' } else { 'no' }))

if (-not $ok) {
    Write-Output 'reset=failed'
    exit 1
}

Write-Output 'Status:'
Write-Output 'Clean active context ready for /corp.load'
Write-Output 'reset=ok'
exit 0