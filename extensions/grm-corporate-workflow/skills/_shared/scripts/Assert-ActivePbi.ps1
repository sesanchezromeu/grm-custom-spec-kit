#Requires -Version 5.1
<#
    Assert-ActivePbi.ps1

    Verify that active-pbi.md reproduces, without alteration, the fragments
    Build-ActivePbi.ps1 assembled it from.

    Build-ActivePbi.ps1 already assembles the file mechanically (D-P14b-02):
    the risk this script defends against today is not the agent composing the
    file by hand, but the file being touched after assembly, deliberately or
    by a repair attempt. Both source-adapter SKILL.md files say so: "Repairing
    the artifact until the check passes is not verification."

    P23b (OBS-P22-09, OBS-P23-01, OBS-P23-02, OBS-P23-03): earlier versions of
    this script compared only the sections it expected, in the order it
    expected them, and treated '## Governance Notes' as present-or-absent
    rather than as content with a fragment behind it. That left four regions
    unchecked: anything before the first known heading, a known heading
    repeated or out of sequence, and the tail of the file once the last
    section had opened. This version partitions the whole file and requires
    every known heading exactly once, in the declared order, nothing left
    over.

    An assertion made in prose by the agent is not a verification. This script
    compares text.

    P23c (OBS-P22-03, OBS-P22-04, OBS-P22-05): on success this script also
    prints the two report fields the agent shortened in four loads out of
    four, already formed. corp.load.agent.md used to ask it to copy the
    envelope's Reference "with its directory" and to write the context path in
    full; both instructions carried the exact mistake to avoid, in writing,
    and both were ignored every time. Deriving a value is where the agent
    fails; transcribing a printed line is not. The figures come from the
    script now, and the command transcribes them.

    Exit codes: 0 verified, 1 mismatch or missing input.

    Usage:
      powershell -NoProfile -ExecutionPolicy Bypass -File .github\skills\_shared\scripts\Assert-ActivePbi.ps1
#>

[CmdletBinding()]
param(
    [string]$ActivePbiPath = ".specify/memory/active-pbi.md",

    [string]$SectionsPath  = ".specify/memory/.grm-pbi-sections"
)

$ErrorActionPreference = "Stop"

# Heading in active-pbi.md -> fragment written by Get-WorkItem.ps1.
# '## Governance Notes' is deliberately absent: that block belongs to the
# calling command and has no counterpart in the source work item.
#
# 'Notes' carries two fragments (D-P16b-02): the notes body and, for a
# Markdown source, the sections the router could not map, appended after it
# with their original headings. They are compared together because the file
# has no known heading between them to split on.
#
# Optional fragments exist on one source and not the other. A fragment that is
# absent along with its section is skipped; either one alone is a failure.
$MAP = [ordered]@{
    'Source'                          = @{ files = @('source.md') }
    'Original PBI Content (Verbatim)' = @{ files = @('verbatim.md') }
    'PBI ID'                          = @{ files = @('pbi_id.md') }
    'Title'                           = @{ files = @('title.md') }
    'Description'                     = @{ files = @('description.md') }
    'Business Context'                = @{ files = @('business_context.md') }
    'Acceptance Criteria'             = @{ files = @('acceptance_criteria.md') }
    'Constraints'                     = @{ files = @('constraints.md') }
    'Dependencies'                    = @{ files = @('dependencies.md') }
    'Out of Scope'                    = @{ files = @('out_of_scope.md') }
    'Notes'                           = @{ files = @('notes.md', 'extra_sections.md') }
    'Governance Notes'                = @{ files = @('governance_notes.md') }
    'Source work item state'          = @{ files = @('source_work_item_state.md'); optional = $true }
}

# Fragments that legitimately exist on one source only.
$OPTIONAL_FRAGMENTS = @('extra_sections.md', 'source_work_item_state.md')

function Stop-Verification {
    param([string]$Message)
    [Console]::Error.WriteLine($Message)
    Write-Output "verification=failed"
    exit 1
}

function Get-ComparableLines {
    param([string]$Text)
    # The unary comma forces every return to leave this function as a single
    # array object. Without it, PowerShell unwraps a one-element array (or an
    # empty one) into a bare scalar (or $null) at the caller: $result[0] on a
    # bare string then indexes its first character, not its first line.
    if ($null -eq $Text) { return ,@() }
    $lines = @($Text -split "`r?`n" | ForEach-Object { $_.TrimEnd() })
    # Leading and trailing blank lines are layout, not content.
    $start = 0
    while ($start -lt $lines.Count -and $lines[$start] -eq '') { $start++ }
    $end = $lines.Count - 1
    while ($end -ge $start -and $lines[$end] -eq '') { $end-- }
    if ($end -lt $start) { return ,@() }
    return ,@($lines[$start..$end])
}

# ---------------------------------------------------------------------------

if (-not (Test-Path $ActivePbiPath)) {
    Stop-Verification "Active PBI not found at $ActivePbiPath."
}
if (-not (Test-Path $SectionsPath)) {
    Stop-Verification "Section fragments not found at $SectionsPath. Run Get-WorkItem.ps1 first."
}

$fileLines = @(Get-Content -Path $ActivePbiPath -Encoding UTF8)

# Split the file into sections on the known headings only. An unrecognised
# '## ' line is treated as content, because a converted work item may legally
# contain Markdown headings of its own.
$known    = @($MAP.Keys)

# Orden declarado de cada encabezado conocido (P23b, OBS-P23-02/-03). $MAP es
# un hashtable ordenado: el orden de sus claves es el orden del layout.
$orderIndex = @{}
$idx = 0
foreach ($k in $MAP.Keys) { $orderIndex[$k] = $idx; $idx++ }

$failures = [System.Collections.Generic.List[string]]::new()

$sections      = [ordered]@{}
$preamble      = [System.Collections.Generic.List[string]]::new()
$current       = $null
$buffer        = [System.Collections.Generic.List[string]]::new()
$lastSeenIndex = -1

foreach ($line in $fileLines) {
    $isHeading = $false
    if ($line -match '^##\s+(.+?)\s*$') {
        $name = $Matches[1]
        if ($known -contains $name) {
            $isHeading = $true
            if ($orderIndex[$name] -le $lastSeenIndex) {
                $failures.Add(("section '## {0}' appears out of order or more than once" -f $name)) | Out-Null
            } else {
                $lastSeenIndex = $orderIndex[$name]
            }
            if ($current) { $sections[$current] = ($buffer -join "`n") }
            $current = $name
            $buffer  = [System.Collections.Generic.List[string]]::new()
        }
    }
    if (-not $isHeading) {
        if ($current) { $buffer.Add($line) | Out-Null } else { $preamble.Add($line) | Out-Null }
    }
}
if ($current) { $sections[$current] = ($buffer -join "`n") }

# OBS-P23-01: todo lo anterior al primer encabezado conocido es maquetacion,
# no una seccion con fragmento propio. Lo unico que Build-ActivePbi.ps1 pone
# ahi es la linea de titulo.
$preambleText = (Get-ComparableLines ($preamble -join "`n")) -join "`n"
if ($preambleText -ne '# Active PBI') {
    $shown = if ($preambleText -eq '') { '<empty>' } else { $preambleText }
    $failures.Add(("content before the first section does not match the expected title. Found: {0}" -f $shown)) | Out-Null
}

$verified = 0

foreach ($heading in $MAP.Keys) {

    $spec  = $MAP[$heading]
    $parts = [System.Collections.Generic.List[string]]::new()
    $any   = $false

    foreach ($file in $spec.files) {
        $fragmentPath = Join-Path $SectionsPath $file
        if (-not (Test-Path $fragmentPath)) {
            if ($OPTIONAL_FRAGMENTS -contains $file) { continue }
            $failures.Add("fragment missing: $file") | Out-Null
            continue
        }
        $any = $true
        # Resolve-Path first: .NET methods resolve relative paths against the
        # process working directory, not the PowerShell location.
        $abs = (Resolve-Path $fragmentPath).Path
        $parts.Add(([System.IO.File]::ReadAllText($abs, [System.Text.Encoding]::UTF8)).TrimEnd()) | Out-Null
    }

    if (-not $any) {
        if ($spec.optional -and -not $sections.Contains($heading)) { continue }
        if ($spec.optional) {
            $failures.Add("section '## $heading' is present but its fragment was not produced") | Out-Null
        }
        continue
    }

    if (-not $sections.Contains($heading)) {
        $failures.Add("section '## $heading' is absent from the active PBI") | Out-Null
        continue
    }

    $expected = Get-ComparableLines (($parts.ToArray()) -join "`n`n")
    $actual   = Get-ComparableLines $sections[$heading]
    $verified++

    $max = [Math]::Max($expected.Count, $actual.Count)
    for ($i = 0; $i -lt $max; $i++) {
        $e = if ($i -lt $expected.Count) { $expected[$i] } else { '<missing>' }
        $a = if ($i -lt $actual.Count)   { $actual[$i]   } else { '<missing>' }
        if ($e -cne $a) {
            $failures.Add(("section '{0}', line {1}:{2}  expected: {3}{2}  found:    {4}" -f `
                $heading, ($i + 1), "`n", $e, $a)) | Out-Null
            break
        }
    }
}

if ($failures.Count -gt 0) {
    [Console]::Error.WriteLine("Active PBI does not reproduce the retrieved work item.")
    [Console]::Error.WriteLine("")
    foreach ($f in $failures) { [Console]::Error.WriteLine($f); [Console]::Error.WriteLine("") }
    Write-Output "verification=failed"
    exit 1
}

# P23c. The report fields the command must transcribe, already formed. Read
# from the fragment rather than from the parsed file: the fragment is the
# source the file was built from, and any divergence between the two would
# have failed the comparison above before reaching this line.
#
# Extracted before anything is printed: a script that announces
# verification=ok and then aborts leaves the agent a success line to report
# from, which is the contradiction this whole command exists to prevent.
$sourceFragment = (Resolve-Path (Join-Path $SectionsPath 'source.md')).Path
$reference = $null
foreach ($line in (([System.IO.File]::ReadAllText($sourceFragment, [System.Text.Encoding]::UTF8)) -split "`r?`n")) {
    if ($line -match '^-\s+Reference:\s*(.+?)\s*$') { $reference = $Matches[1]; break }
}
if (-not $reference) {
    [Console]::Error.WriteLine("source.md carries no Reference field. The report cannot be formed.")
    Write-Output "verification=failed"
    exit 1
}

# The count is of sections compared against a fragment. '## Governance Notes'
# is included since P23b (D-P23-02): the corporate boilerplate now has a
# recorded fragment to compare against, closing OBS-P22-09.
Write-Output ("verification=ok sections={0}" -f $verified)
Write-Output ("report_source: {0}" -f $reference)
Write-Output ("report_active_pbi_context: {0}" -f $ActivePbiPath)
exit 0
