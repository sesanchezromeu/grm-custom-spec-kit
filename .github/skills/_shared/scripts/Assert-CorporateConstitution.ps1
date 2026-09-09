#Requires -Version 5.1
<#
    Assert-CorporateConstitution.ps1

    PA-02: no corp.* agent read .specify/memory/constitution.md. The
    constitution was installed (installation-guide.md, Step 9) and
    documented (architecture.md) but never consumed -- real governance
    gap, not a missing file.

    This script closes the gap the way every other behavioural guarantee
    in this repository is closed (L-02, foundational): by running code
    that produces the guarantee, not by asking the agent to remember to
    open a file. It prints the constitution's full content to stdout, so
    the text enters the agent's working context as the output of a
    command it was told to run, the same mechanism corp.load already uses
    for Reset-ActiveContext.ps1. An agent instruction to "read the file"
    would be exactly the class of prose guarantee L-02 documents as
    unreliable.

    Fixed path, no parameter (D-P29-09): the only path this script
    honours is the one installation-guide.md documents as the expected
    runtime location. Every corp.* agent that calls this script expects
    that exact path in its own text; a parameter would let the checked
    path and the reported path drift apart, same rationale as
    Reset-ActiveContext.ps1's fixed paths.

    "Non-empty" (D-P29-06: b) means non-zero length after Trim() on both
    ends, not only TrimEnd("`n") on one end -- a file containing only
    whitespace or tabs is not a constitution and must not pass silently.

    Line count uses ($norm -split "`n").Count on content normalised
    CRLF->LF, per project convention -- never wc -l or a raw line-reading
    cmdlet.

    The banner and verification wording below is authoritative here for
    now; the five corp.*.agent.md files that call this script in P29b
    quote it verbatim, same rule as $DEFAULT_GOVERNANCE in
    Build-ActivePbi.ps1 and the Completion contract copy in
    Reset-ActiveContext.ps1.

    Exit codes: 0 present and non-empty (constitution=ok), 1 otherwise
    (constitution=failed).

    Usage:
      powershell -NoProfile -ExecutionPolicy Bypass -File .github\skills\_shared\scripts\Assert-CorporateConstitution.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$CONSTITUTION = '.specify/memory/constitution.md'

$exists    = Test-Path -LiteralPath $CONSTITUTION -PathType Leaf
$nonEmpty  = $false
$content   = $null
$lineCount = 0

if ($exists) {
    try {
        $abs  = (Resolve-Path -LiteralPath $CONSTITUTION).ProviderPath
        $raw  = [System.IO.File]::ReadAllText($abs, [System.Text.Encoding]::UTF8)
        $norm = $raw -replace "`r`n", "`n"
        $nonEmpty = ($norm.Trim().Length -gt 0)
        if ($nonEmpty) {
            $content   = $raw
            $lineCount = ($norm.TrimEnd("`n") -split "`n").Count
        }
    }
    catch {
        $exists = $false
        [Console]::Error.WriteLine("Corporate constitution could not be read: $_")
    }
}

$ok = $exists -and $nonEmpty

if ($ok) {
    Write-Output 'Corporate constitution loaded.'
    Write-Output '---'
    Write-Output $content
    Write-Output '---'
}
else {
    Write-Output 'Corporate constitution NOT loaded.'
}

Write-Output 'Verification:'
Write-Output ("- {0} exists: {1}" -f $CONSTITUTION, $(if ($exists) { 'yes' } else { 'no' }))
Write-Output ("- {0} non-empty: {1}" -f $CONSTITUTION, $(if ($exists) { $(if ($nonEmpty) { 'yes' } else { 'no' }) } else { 'n/a' }))
if ($ok) {
    Write-Output ("- lines: {0}" -f $lineCount)
}

if (-not $ok) {
    Write-Output 'constitution=failed'
    exit 1
}

Write-Output 'constitution=ok'
exit 0
