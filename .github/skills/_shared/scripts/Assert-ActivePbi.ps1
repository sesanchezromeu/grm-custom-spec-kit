#Requires -Version 5.1
<#
    Assert-ActivePbi.ps1

    Verify that active-pbi.md reproduces the retrieved PBI without alteration.

    This closes the last unverified stretch of the load. Get-WorkItem.ps1
    guarantees fidelity from the Azure DevOps API to the payload; nothing
    guaranteed fidelity from the payload to the file the agent writes. In an
    observed run the agent produced a well written, plausible active-pbi.md
    containing a third dialog option, a modal requirement and a localisation
    requirement that appear nowhere in the work item, while dropping an
    informational message and a traceability rule that do appear in it.

    An assertion made in prose by the agent is not a verification. This script
    compares text.

    Exit codes: 0 verified, 1 mismatch or missing input.

    Usage:
      powershell -NoProfile -ExecutionPolicy Bypass -File .github\skills\grm-azure-devops-pbi\scripts\Assert-ActivePbi.ps1
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
    if ($null -eq $Text) { return @() }
    $lines = @($Text -split "`r?`n" | ForEach-Object { $_.TrimEnd() })
    # Leading and trailing blank lines are layout, not content.
    $start = 0
    while ($start -lt $lines.Count -and $lines[$start] -eq '') { $start++ }
    $end = $lines.Count - 1
    while ($end -ge $start -and $lines[$end] -eq '') { $end-- }
    if ($end -lt $start) { return @() }
    return @($lines[$start..$end])
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
$known    = @($MAP.Keys) + @('Governance Notes')
$sections = [ordered]@{}
$current  = $null
$buffer   = [System.Collections.Generic.List[string]]::new()

foreach ($line in $fileLines) {
    $isHeading = $false
    if ($line -match '^##\s+(.+?)\s*$') {
        $name = $Matches[1]
        if ($known -contains $name) {
            $isHeading = $true
            if ($current) { $sections[$current] = ($buffer -join "`n") }
            $current = $name
            $buffer  = [System.Collections.Generic.List[string]]::new()
        }
    }
    if (-not $isHeading -and $current) { $buffer.Add($line) | Out-Null }
}
if ($current) { $sections[$current] = ($buffer -join "`n") }

$failures = [System.Collections.Generic.List[string]]::new()

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

if (-not $sections.Contains('Governance Notes')) {
    $failures.Add("section '## Governance Notes' is absent from the active PBI") | Out-Null
}

if ($failures.Count -gt 0) {
    [Console]::Error.WriteLine("Active PBI does not reproduce the retrieved work item.")
    [Console]::Error.WriteLine("")
    foreach ($f in $failures) { [Console]::Error.WriteLine($f); [Console]::Error.WriteLine("") }
    Write-Output "verification=failed"
    exit 1
}

# The count is of sections compared against a fragment. '## Governance Notes'
# is checked for presence only and is not included: it has no counterpart in
# the source, so there is nothing to compare it with.
Write-Output ("verification=ok sections={0}" -f $verified)
exit 0