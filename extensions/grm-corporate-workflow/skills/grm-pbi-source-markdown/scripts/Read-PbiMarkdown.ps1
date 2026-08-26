#Requires -Version 5.1
<#
    Read-PbiMarkdown.ps1

    Read a Product Backlog Item from a local Markdown file and write a
    normalized payload and section fragments for the corporate load command.

    Sibling of Get-WorkItem.ps1. Same output contract, same fragment names, so
    Build-ActivePbi.ps1 and Assert-ActivePbi.ps1 serve both sources unchanged in
    substance. The --file path is no longer written by the agent (P16b).

    Why (D-P16b-00): a --file load observed in P16 reproduced the verbatim block
    correctly and then lost every accent while retyping the canonical sections,
    invented tab indentation, and was repaired twice by the agent until its own
    check turned green. The check and the repair were performed by the same
    actor, so the check verified nothing. Reading is therefore mechanical.

    Fidelity: the file is copied, never reformatted. Indentation, line endings,
    trailing whitespace and the presence or absence of a final newline are
    properties of the source and are not normalized.

    Section routing (D-P16b-01, option b): an explicit table, not a heuristic.
    A source heading absent from the table is appended after ## Notes keeping
    its original heading text, which is what the Canonical section rule of
    corp.load.agent.md requires. Nothing is dropped and nothing is guessed.

    Exit codes: 0 success, 1 failure. On failure the payload file is still
    written, with status "error" and a populated errors array.

    Usage:
      powershell -NoProfile -ExecutionPolicy Bypass -File .github\skills\grm-pbi-source-markdown\scripts\Read-PbiMarkdown.ps1 -Reference "samples\PBI-POC-01-calculadora-iva.md"
#>

[CmdletBinding()]
param(
    # Path to the Markdown PBI, exactly as the user provided it. It is echoed
    # into the envelope unchanged: it is a copy, not a derivation.
    [Parameter(Mandatory = $true)]
    [string]$Reference,

    [string]$PayloadPath = ".specify/memory/.grm-pbi-payload.json",

    [string]$SectionsPath = ".specify/memory/.grm-pbi-sections"
)

$ErrorActionPreference = "Stop"

$ABSENT = 'Not specified in the source PBI'
$SCHEMA = 'grm-pbi-source-markdown/normalized-pbi@1'

$script:Warnings = [System.Collections.Generic.List[string]]::new()

# ---------------------------------------------------------------------------
# Payload writing and failure
# ---------------------------------------------------------------------------

function Write-Payload {
    param([hashtable]$Payload, [string]$Path)

    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    $json = $Payload | ConvertTo-Json -Depth 8
    # UTF-8 without BOM, written explicitly: Out-File in 5.1 would use the
    # console encoding and lose accented characters.
    [System.IO.File]::WriteAllText(
        [System.IO.Path]::Combine((Get-Location).Path, $Path),
        $json,
        (New-Object System.Text.UTF8Encoding($false)))
}

function Stop-WithError {
    param([string]$Message)

    # Fragments from an earlier load survive a failed one and are
    # indistinguishable from fresh ones: Build-ActivePbi.ps1 would happily
    # assemble the previous PBI from them. Discard them before reporting.
    try {
        $stale = [System.IO.Path]::Combine((Get-Location).Path, $SectionsPath)
        if (Test-Path -LiteralPath $stale) {
            Remove-Item -LiteralPath $stale -Recurse -Force
        }
    }
    catch {
        [Console]::Error.WriteLine("Stale section fragments could not be removed from '$SectionsPath': $_")
    }

    $payload = @{
        schema   = $SCHEMA
        status   = 'error'
        errors   = @($Message)
        warnings = @($script:Warnings.ToArray())
    }
    try   { Write-Payload -Payload $payload -Path $PayloadPath }
    catch { Write-Error "Payload could not be written to '$PayloadPath': $_" }

    [Console]::Error.WriteLine($Message)
    Write-Output ("status=error payload={0}" -f $PayloadPath)
    exit 1
}

# ---------------------------------------------------------------------------
# Text helpers
# ---------------------------------------------------------------------------

# Fold accents and case so the routing table can stay pure ASCII. Windows
# PowerShell 5.1 reads a .ps1 without BOM as ANSI, so a literal accented
# character in this file would be reinterpreted in CP1252 (HZ-05). The table
# below therefore holds ASCII keys and the source heading is folded to match.
function ConvertTo-FoldedKey {
    param([string]$Text)

    if ($null -eq $Text) { return '' }

    $decomposed = $Text.Normalize([System.Text.NormalizationForm]::FormD)
    $sb = New-Object System.Text.StringBuilder
    foreach ($ch in $decomposed.ToCharArray()) {
        $cat = [System.Globalization.CharUnicodeInfo]::GetUnicodeCategory($ch)
        if ($cat -ne [System.Globalization.UnicodeCategory]::NonSpacingMark) {
            [void]$sb.Append($ch)
        }
    }
    return ($sb.ToString().ToLowerInvariant().Trim() -replace '\s+', ' ')
}

function Get-Tokens {
    param([string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) { return @() }
    return @($Text -split '\s+' | Where-Object { $_ -ne '' })
}

function Join-Lines {
    param([string[]]$Lines)

    if ($null -eq $Lines -or $Lines.Count -eq 0) { return '' }
    return (($Lines -join "`n").Trim("`n"))
}

# ---------------------------------------------------------------------------
# Routing table (D-P16b-01, option b)
# ---------------------------------------------------------------------------

$ROUTES = [ordered]@{
    'descripcion'           = 'description'
    'description'           = 'description'
    'objetivo'              = 'business_context'
    'objective'             = 'business_context'
    'contexto de negocio'   = 'business_context'
    'business context'      = 'business_context'
    'criterios de aceptacion' = 'acceptance_criteria'
    'acceptance criteria'   = 'acceptance_criteria'
    'restricciones tecnicas' = 'constraints'
    'restricciones'         = 'constraints'
    'constraints'           = 'constraints'
    'dependencias'          = 'dependencies'
    'dependencies'          = 'dependencies'
    'fuera de alcance'      = 'out_of_scope'
    'out of scope'          = 'out_of_scope'
    'notas'                 = 'notes'
    'notes'                 = 'notes'
}

$CANONICAL = @(
    'description', 'business_context', 'acceptance_criteria',
    'constraints', 'dependencies', 'out_of_scope', 'notes'
)

$LABELS = @{
    'description'         = 'Description'
    'business_context'    = 'Business Context'
    'acceptance_criteria' = 'Acceptance Criteria'
    'constraints'         = 'Constraints'
    'dependencies'        = 'Dependencies'
    'out_of_scope'        = 'Out of Scope'
    'notes'               = 'Notes'
}

# ---------------------------------------------------------------------------
# Resolve and read
# ---------------------------------------------------------------------------

if ([string]::IsNullOrWhiteSpace($Reference)) {
    Stop-WithError "Missing input file."
}

if (-not (Test-Path -LiteralPath $Reference)) {
    Stop-WithError ("PBI Markdown file not found: {0}" -f $Reference)
}
if (Test-Path -LiteralPath $Reference -PathType Container) {
    Stop-WithError ("Path is a directory, not a PBI file: {0}" -f $Reference)
}
if ([System.IO.Path]::GetExtension($Reference).ToLowerInvariant() -ne '.md') {
    Stop-WithError ("Source file is not a Markdown file: {0}" -f $Reference)
}

# Resolve-Path first: .NET methods resolve relative paths against the process
# working directory, not the PowerShell location (HZ-06).
$absolute = (Resolve-Path -LiteralPath $Reference).Path
$item     = Get-Item -LiteralPath $absolute

# ReadAllText detects and strips a byte order mark if one is present, and
# leaves every other byte alone.
$sourceText = [System.IO.File]::ReadAllText($absolute, [System.Text.Encoding]::UTF8)

if ([string]::IsNullOrWhiteSpace($sourceText)) {
    Stop-WithError ("The PBI Markdown file is empty: {0}" -f $Reference)
}

$lines = @($sourceText -split "`r`n|`n|`r")

# ---------------------------------------------------------------------------
# Locate the title heading and the section heading level
# ---------------------------------------------------------------------------

$headings = @()
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^(#{1,6})\s+(.*?)\s*$') {
        $headings += [PSCustomObject]@{
            Index = $i
            Level = $Matches[1].Length
            Text  = $Matches[2]
        }
    }
}

if ($headings.Count -eq 0) {
    Stop-WithError ("No Markdown heading found in {0}. The file does not appear to represent a PBI." -f $Reference)
}

$title        = $headings[0]
$deeper       = @($headings | Where-Object { $_.Level -gt $title.Level })
$sectionLevel = if ($deeper.Count -gt 0) { ($deeper | Measure-Object -Property Level -Minimum).Minimum } else { 0 }

# PBI ID and title text. '<ID> - <Title>' is split; anything else is a title
# with no identifier, reported as absent rather than invented.
$pbiId     = $ABSENT
$titleText = $title.Text
if ($title.Text -match '^(?<id>[A-Za-z0-9][A-Za-z0-9._-]*)\s+-\s+(?<rest>.+)$') {
    $pbiId     = $Matches['id']
    $titleText = $Matches['rest']
}

# ---------------------------------------------------------------------------
# Split into sections and route them
# ---------------------------------------------------------------------------

$bodies  = @{}
foreach ($key in $CANONICAL) { $bodies[$key] = $null }

$extras          = [System.Collections.Generic.List[string]]::new()
$sourceSections  = 0
$mappedSections  = 0
$appendedSections = 0

$currentKey     = $null
$currentHeading = $null
$buffer         = [System.Collections.Generic.List[string]]::new()
$preamble       = [System.Collections.Generic.List[string]]::new()

function Complete-Section {
    param(
        [string]$Key,
        [string]$HeadingLine,
        [string[]]$Buffer
    )

    $body = Join-Lines -Lines $Buffer

    if ($Key -and (-not $script:bodies[$Key])) {
        $script:bodies[$Key] = $body
        $script:mappedSections++
        return
    }

    if ($Key) {
        # A second source section routing to an occupied canonical slot is not
        # merged: merging would fuse two source sections into one and hide it.
        $script:Warnings.Add(("Duplicate route for '{0}': the section was appended after Notes instead of merged." -f $HeadingLine)) | Out-Null
    }

    $script:extras.Add($HeadingLine) | Out-Null
    $script:extras.Add('') | Out-Null
    foreach ($line in ($body -split "`n")) { $script:extras.Add($line) | Out-Null }
    $script:extras.Add('') | Out-Null
    $script:appendedSections++
}

for ($i = 0; $i -lt $lines.Count; $i++) {

    if ($i -eq $title.Index) { continue }

    $isSectionHeading = $false
    $headingText      = $null
    if ($sectionLevel -gt 0 -and $lines[$i] -match '^(#{1,6})\s+(.*?)\s*$') {
        if ($Matches[1].Length -eq $sectionLevel) {
            $isSectionHeading = $true
            # Captured now: any -match executed further down would clobber
            # $Matches before it could be read.
            $headingText = $Matches[2]
        }
    }

    if ($isSectionHeading) {
        if ($null -ne $currentHeading) {
            Complete-Section -Key $currentKey -HeadingLine $currentHeading -Buffer $buffer.ToArray()
        }
        $currentHeading = $lines[$i]
        $folded         = ConvertTo-FoldedKey -Text $headingText
        $currentKey     = if ($ROUTES.Contains($folded)) { $ROUTES[$folded] } else { $null }
        $buffer         = [System.Collections.Generic.List[string]]::new()
        $sourceSections++
        continue
    }

    if ($null -eq $currentHeading) { $preamble.Add($lines[$i]) | Out-Null }
    else                           { $buffer.Add($lines[$i])   | Out-Null }
}

if ($null -ne $currentHeading) {
    Complete-Section -Key $currentKey -HeadingLine $currentHeading -Buffer $buffer.ToArray()
}

# Text between the title and the first section belongs to no section. It is
# kept, unlabelled, rather than silently discarded.
$preambleText = Join-Lines -Lines $preamble.ToArray()
if (-not [string]::IsNullOrWhiteSpace($preambleText)) {
    $extras.Insert(0, '')
    $ordered = @($preambleText -split "`n")
    for ($k = $ordered.Count - 1; $k -ge 0; $k--) { $extras.Insert(0, $ordered[$k]) }
    $script:Warnings.Add("Text found between the title and the first section; it was appended after Notes without a heading.") | Out-Null
}

# ---------------------------------------------------------------------------
# Minimum loadability
# ---------------------------------------------------------------------------

$missingRequired = [System.Collections.Generic.List[string]]::new()
if ([string]::IsNullOrWhiteSpace($titleText))          { $missingRequired.Add('title') | Out-Null }
if ([string]::IsNullOrWhiteSpace($bodies['description'])) { $missingRequired.Add('description or objective') | Out-Null }
if ([string]::IsNullOrWhiteSpace($bodies['acceptance_criteria'])) { $missingRequired.Add('acceptance criteria') | Out-Null }

if ($missingRequired.Count -gt 0) {
    Stop-WithError ("The file does not appear to represent a PBI. Missing: {0}." -f ($missingRequired -join ', '))
}

$missingOptional = [System.Collections.Generic.List[string]]::new()
foreach ($key in $CANONICAL) {
    if ([string]::IsNullOrWhiteSpace($bodies[$key])) {
        $bodies[$key] = $ABSENT
        if ($key -ne 'description' -and $key -ne 'acceptance_criteria') {
            $missingOptional.Add($LABELS[$key]) | Out-Null
        }
    }
}

# ---------------------------------------------------------------------------
# Coverage verification: every source token reaches a destination
# ---------------------------------------------------------------------------

$sourceBodyLines = @()
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($i -eq $title.Index) { continue }
    if ($sectionLevel -gt 0 -and $lines[$i] -match '^(#{1,6})\s+') {
        if ($Matches[1].Length -eq $sectionLevel) { continue }
    }
    $sourceBodyLines += $lines[$i]
}

$extrasText = Join-Lines -Lines $extras.ToArray()

$routedParts = [System.Collections.Generic.List[string]]::new()
foreach ($key in $CANONICAL) {
    if ($bodies[$key] -ne $ABSENT) { $routedParts.Add($bodies[$key]) | Out-Null }
}
if (-not [string]::IsNullOrWhiteSpace($extrasText)) {
    foreach ($line in ($extrasText -split "`n")) {
        if ($sectionLevel -gt 0 -and $line -match '^(#{1,6})\s+') {
            if ($Matches[1].Length -eq $sectionLevel) { continue }
        }
        $routedParts.Add($line) | Out-Null
    }
}

$sourceTokens = Get-Tokens -Text ($sourceBodyLines -join "`n")
$routedTokens = Get-Tokens -Text (($routedParts.ToArray()) -join "`n")

# Multiset, not sequence. Routing reorders by construction: the canonical
# sections come out in canonical order and the unmapped ones are appended after
# Notes, so the routed sequence is a permutation of the source sequence even
# when nothing is lost. What must hold is that no token disappears and none is
# invented; order is not evidence of either.
$sourceSorted = @($sourceTokens | Sort-Object -CaseSensitive)
$routedSorted = @($routedTokens | Sort-Object -CaseSensitive)

$coverageOk = ($sourceSorted.Count -eq $routedSorted.Count)
if ($coverageOk) {
    for ($i = 0; $i -lt $sourceSorted.Count; $i++) {
        if ($sourceSorted[$i] -cne $routedSorted[$i]) { $coverageOk = $false; break }
    }
}

if (-not $coverageOk) {
    if ($sourceTokens.Count -ne $routedTokens.Count) {
        Stop-WithError ("Section routing lost content: {0} source tokens against {1} routed. The PBI was not loaded." -f $sourceTokens.Count, $routedTokens.Count)
    }
    Stop-WithError ("Section routing altered content: {0} tokens on both sides but they are not the same tokens. The PBI was not loaded." -f $sourceTokens.Count)
}

$headingCounts = @()
for ($level = 1; $level -le 6; $level++) {
    $count = @($headings | Where-Object { $_.Level -eq $level }).Count
    if ($count -gt 0) { $headingCounts += ("h{0}={1}" -f $level, $count) }
}

$listItems = @($lines | Where-Object { $_ -match '^\s*([-*+]|\d+\.)\s+' }).Count

# ---------------------------------------------------------------------------
# Fragments and payload
# ---------------------------------------------------------------------------

$changedAt = 'Not recorded'
try   { $changedAt = $item.LastWriteTimeUtc.ToString('yyyy-MM-ddTHH:mm:ss.fffZ') }
catch { $changedAt = 'Not recorded' }

$envelope = [ordered]@{
    type           = 'Markdown file'
    reference      = $Reference
    organization   = 'Not applicable'
    project        = 'Not applicable'
    work_item_id   = 'Not applicable'
    work_item_type = 'Not applicable'
    revision       = 'Not applicable'
    changed_at     = $changedAt
    retrieved_via  = 'Local file read'
    loaded_at      = (Get-Date).ToString('o')
}

$sourceFragment = @(
    "- Type: $($envelope.type)",
    "- Reference: $($envelope.reference)",
    "- Organization: $($envelope.organization)",
    "- Project: $($envelope.project)",
    "- Work item ID: $($envelope.work_item_id)",
    "- Work item type: $($envelope.work_item_type)",
    "- Revision: $($envelope.revision)",
    "- Changed at: $($envelope.changed_at)",
    "- Retrieved via: $($envelope.retrieved_via)",
    "- Loaded at: $($envelope.loaded_at)"
) -join "`n"

$warningsFragment = 'None detected.'
if ($script:Warnings.Count -gt 0) {
    $warningsFragment = ((@($script:Warnings.ToArray()) | ForEach-Object { "- $_" }) -join "`n")
}

$missingFragment = 'None detected.'
if ($missingOptional.Count -gt 0) {
    $missingFragment = ((@($missingOptional.ToArray()) | ForEach-Object { "- $_" }) -join "`n")
}

$verificationFragment = @(
    "- Source tokens: $($sourceTokens.Count)",
    "- Routed tokens: $($routedTokens.Count)",
    "- Source sections: $sourceSections",
    "- Mapped to canonical: $mappedSections",
    "- Appended after Notes: $appendedSections",
    "- Heading counts: $($headingCounts -join ', ')",
    "- Source list items: $listItems"
) -join "`n"

# The verbatim fragment is the file, unchanged. Nothing is reindented and no
# final newline is added or removed: those are properties of the source.
$fragments = [ordered]@{
    'source.md'              = $sourceFragment
    'verbatim.md'            = $sourceText
    'pbi_id.md'              = $pbiId
    'title.md'               = $titleText
    'description.md'         = $bodies['description']
    'business_context.md'    = $bodies['business_context']
    'acceptance_criteria.md' = $bodies['acceptance_criteria']
    'constraints.md'         = $bodies['constraints']
    'dependencies.md'        = $bodies['dependencies']
    'out_of_scope.md'        = $bodies['out_of_scope']
    'notes.md'               = $bodies['notes']
    'warnings.md'            = $warningsFragment
    'missing_optional.md'    = $missingFragment
    'verification.md'        = $verificationFragment
}

if (-not [string]::IsNullOrWhiteSpace($extrasText)) {
    $fragments['extra_sections.md'] = $extrasText
}

# Rewritten from scratch on every successful run: a fragment left over from an
# earlier load would be indistinguishable from a current one.
$sectionsAbsolute = [System.IO.Path]::Combine((Get-Location).Path, $SectionsPath)
if (Test-Path -LiteralPath $sectionsAbsolute) {
    Remove-Item -LiteralPath $sectionsAbsolute -Recurse -Force
}
New-Item -ItemType Directory -Path $sectionsAbsolute -Force | Out-Null

$enc = New-Object System.Text.UTF8Encoding($false)
foreach ($name in $fragments.Keys) {
    [System.IO.File]::WriteAllText(
        (Join-Path $sectionsAbsolute $name), [string]$fragments[$name], $enc)
}

$payload = @{
    schema   = $SCHEMA
    status   = 'ok'
    envelope = $envelope
    sections = @{
        title               = $titleText
        description         = $bodies['description']
        business_context    = $bodies['business_context']
        acceptance_criteria = $bodies['acceptance_criteria']
        constraints         = $bodies['constraints']
        dependencies        = $bodies['dependencies']
        out_of_scope        = $bodies['out_of_scope']
        notes               = $bodies['notes']
        extra_sections      = $extrasText
    }
    verification = @{
        coverage = @{
            passed        = $true
            source_tokens = $sourceTokens.Count
            routed_tokens = $routedTokens.Count
        }
        source_sections   = $sourceSections
        mapped_sections   = $mappedSections
        appended_sections = $appendedSections
        heading_counts    = ($headingCounts -join ', ')
        list_items        = $listItems
    }
    missing_optional = @($missingOptional.ToArray())
    warnings         = @($script:Warnings.ToArray())
    errors           = @()
}

Write-Payload -Payload $payload -Path $PayloadPath
Write-Output ("status=ok payload={0} sections={1}" -f $PayloadPath, $SectionsPath)
exit 0