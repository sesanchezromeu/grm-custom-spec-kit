#Requires -Version 5.1
<#
    Get-WorkItem.ps1

    Retrieve a Product Backlog Item from Azure DevOps and write a normalized
    payload for the corporate load command.

    Normative specification:
      references/fidelity-contract.md   envelope, mapping, rules F-01..F-10
      references/configuration.md       catalogue, credential, environment

    The credential is read from the AZDO_PAT environment variable and is never
    accepted as a parameter: a parameter would persist in the shell history.

    Output contract (D-P12-04, a documented deviation from plan section 5.5):
    the JSON payload is written to disk in UTF-8, and stdout carries a single
    status line. Emitting JSON through stdout in Windows PowerShell 5.1 encodes
    it in the console code page, which silently mangles accented characters.

    Exit codes: 0 success, 1 failure. On failure the payload file is still
    written, with status "error" and a populated errors array.

    Usage:
      powershell -NoProfile -ExecutionPolicy Bypass -File .github\skills\grm-azure-devops-pbi\scripts\Get-WorkItem.ps1 -Reference "JWM:126924"
#>

[CmdletBinding()]
param(
    # Work item URL, or <key>:<id> resolved against the catalogue.
    [Parameter(Mandatory = $true)]
    [string]$Reference,

    [string]$CatalogPath = ".specify/grm-backlog.yml",

    [string]$PayloadPath = ".specify/memory/.grm-pbi-payload.json",

    [string]$SectionsPath = ".specify/memory/.grm-pbi-sections"
)

$ErrorActionPreference = "Stop"

$ACCEPTED_TYPES = @('Product Backlog Item', 'User Story')
$ABSENT          = 'Not specified in the source PBI'
$SCHEMA          = 'grm-azure-devops-pbi/normalized-pbi@1'

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
        $Path, $json, (New-Object System.Text.UTF8Encoding($false)))
}

function Write-Sections {
    param([hashtable]$Payload, [string]$Path)

    # Rewritten from scratch on every successful run: a fragment left over from
    # an earlier load would be indistinguishable from a current one.
    if (Test-Path $Path) { Remove-Item -Path $Path -Recurse -Force }
    New-Item -ItemType Directory -Path $Path -Force | Out-Null

    $enc = New-Object System.Text.UTF8Encoding($false)
    $e   = $Payload.envelope
    $s   = $Payload.sections

    $source = @(
        "- Type: $($e.type)",
        "- Reference: $($e.reference)",
        "- Organization: $($e.organization)",
        "- Project: $($e.project)",
        "- Work item ID: $($e.work_item_id)",
        "- Work item type: $($e.work_item_type)",
        "- Revision: $($e.revision)",
        "- Changed at: $($e.changed_at)",
        "- Retrieved via: $($e.retrieved_via)",
        "- Loaded at: $($e.loaded_at)"
    ) -join "`n"

    # D-P14b-01. Bold labels, not headings: a '## ' line inside a fragment
    # would break the section boundaries the verifier relies on.
    $verbatim = $s.description + "`n`n---`n`n**Acceptance Criteria**`n`n" + $s.acceptance_criteria

    $warnings = 'None detected.'
    if (@($Payload.warnings).Count -gt 0) {
        $warnings = ((@($Payload.warnings) | ForEach-Object { "- $_" }) -join "`n")
    }

    $v = $Payload.verification
    $verification = @(
        "- Source tokens: $($v.text_completeness.source_tokens)",
        "- Payload tokens: $($v.text_completeness.payload_tokens)",
        "- Source list items: $(@($v.depth_profile.source).Count)",
        "- Payload list items: $(@($v.depth_profile.payload).Count)"
    ) -join "`n"

    $fragments = [ordered]@{
        'source.md'                 = $source
        'verbatim.md'               = $verbatim
        'pbi_id.md'                 = "$($e.work_item_id)"
        'title.md'                  = $s.title
        'description.md'            = $s.description
        'business_context.md'       = $s.business_context
        'acceptance_criteria.md'    = $s.acceptance_criteria
        'constraints.md'            = $s.constraints
        'dependencies.md'           = $s.dependencies
        'out_of_scope.md'           = $s.out_of_scope
        'notes.md'                  = $s.notes
        'source_work_item_state.md' = $s.governance_notes
        'warnings.md'               = $warnings
        'verification.md'           = $verification
    }

    foreach ($name in $fragments.Keys) {
        [System.IO.File]::WriteAllText((Join-Path $Path $name), [string]$fragments[$name], $enc)
    }
}

function Stop-WithError {
    param([string]$Message)

    $payload = @{
        schema  = $SCHEMA
        status  = 'error'
        errors  = @($Message)
        warnings = @($script:Warnings.ToArray())
    }
    try   { Write-Payload -Payload $payload -Path $PayloadPath }
    catch { Write-Error "Payload could not be written to '$PayloadPath': $_" }

    [Console]::Error.WriteLine($Message)
    Write-Output ("status=error payload={0}" -f $PayloadPath)
    exit 1
}

# ---------------------------------------------------------------------------
# Catalogue: minimal parser for the exact shape of configuration.md section 2.
# Anything outside that shape is an explicit error, never a tolerant reading.
# ---------------------------------------------------------------------------

function Read-BacklogCatalog {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        Stop-WithError "Backlog catalogue not found at $Path."
    }

    $lines    = Get-Content -Path $Path -Encoding UTF8
    $provider = $null
    $backlogs = @{}
    $current  = $null
    $inBacklogs   = $false
    $backlogIndent = -1
    $entryIndent   = -1
    $lineNo = 0

    foreach ($raw in $lines) {
        $lineNo++
        $line = $raw -replace "`t", '    '
        if ($line -match '^\s*#') { continue }
        if ([string]::IsNullOrWhiteSpace($line)) { continue }

        $indent  = ($line -replace '^(\s*).*$', '$1').Length
        $trimmed = ($line -replace '\s+#.*$', '').Trim()

        if ($indent -eq 0) {
            $inBacklogs = $false
            $current    = $null

            if ($trimmed -match '^provider:\s*(.*)$') {
                $provider = $Matches[1].Trim().Trim('"').Trim("'")
                continue
            }
            if ($trimmed -match '^backlogs:\s*$') {
                $inBacklogs    = $true
                $backlogIndent = 0
                $entryIndent   = -1
                continue
            }
            Stop-WithError ("Backlog catalogue is malformed at line {0}: unexpected top-level entry '{1}'. Expected 'provider:' or 'backlogs:'." -f $lineNo, $trimmed)
        }

        if (-not $inBacklogs) {
            Stop-WithError ("Backlog catalogue is malformed at line {0}: indented content outside 'backlogs:'." -f $lineNo)
        }

        if ($entryIndent -lt 0) { $entryIndent = $indent }

        if ($indent -eq $entryIndent) {
            if ($trimmed -notmatch '^([A-Za-z0-9_.<>-]+):\s*$') {
                Stop-WithError ("Backlog catalogue is malformed at line {0}: expected a backlog key, found '{1}'." -f $lineNo, $trimmed)
            }
            $current = $Matches[1]
            if ($current -match '[<>]') {
                Stop-WithError "Backlog catalogue still contains the template placeholders. Edit $Path and declare at least one real backlog."
            }
            if ($backlogs.ContainsKey($current)) {
                Stop-WithError ("Backlog catalogue declares key '{0}' more than once." -f $current)
            }
            $backlogs[$current] = @{ organization_url = $null; project = $null }
            continue
        }

        if ($indent -gt $entryIndent) {
            if (-not $current) {
                Stop-WithError ("Backlog catalogue is malformed at line {0}: value without a backlog key." -f $lineNo)
            }
            if ($trimmed -notmatch '^(organization_url|project):\s*(.+)$') {
                Stop-WithError ("Backlog catalogue is malformed at line {0}: '{1}'. Only 'organization_url' and 'project' are accepted." -f $lineNo, $trimmed)
            }
            $backlogs[$current][$Matches[1]] = $Matches[2].Trim().Trim('"').Trim("'")
            continue
        }

        Stop-WithError ("Backlog catalogue is malformed at line {0}: inconsistent indentation." -f $lineNo)
    }

    if (-not $provider) {
        Stop-WithError "Backlog catalogue does not declare 'provider'. Without it the --backlog abstraction is decorative."
    }
    if ($provider -ne 'azure-devops') {
        Stop-WithError ("Backlog provider '{0}' is not handled by this skill. Expected 'azure-devops'." -f $provider)
    }
    if ($backlogs.Count -eq 0) {
        Stop-WithError "Backlog catalogue declares no backlogs."
    }
    foreach ($k in $backlogs.Keys) {
        if (-not $backlogs[$k].organization_url -or -not $backlogs[$k].project) {
            Stop-WithError ("Backlog '{0}' is incomplete: both 'organization_url' and 'project' are required." -f $k)
        }
    }

    return $backlogs
}

# ---------------------------------------------------------------------------
# Reference resolution (configuration.md section 3)
# ---------------------------------------------------------------------------

function Resolve-Reference {
    param([string]$Reference, [string]$CatalogPath)

    $ref = $Reference.Trim().Trim('"').Trim("'")

    if ($ref -match '^https?://') {
        try   { $uri = [System.Uri]$ref }
        catch { Stop-WithError "Invalid backlog reference. Use a work item URL or <key>:<id>." }

        # H-03: the MCAS proxy host works in a browser only. Normalize to the
        # canonical host and drop the proxy query parameters.
        $host_ = $uri.Host -replace '\.mcas\.ms$', ''
        if ($host_ -notmatch '(^|\.)dev\.azure\.com$' -and $host_ -notmatch '\.visualstudio\.com$') {
            Stop-WithError ("Unrecognized Azure DevOps host '{0}'. Expected dev.azure.com." -f $uri.Host)
        }

        $segments = @($uri.AbsolutePath.Trim('/') -split '/' | Where-Object { $_ -ne '' })
        $id = $null; $org = $null; $project = $null

        # Azure DevOps hands out several URL shapes for the same work item:
        # /_workitems/edit/<id> from the item, /_backlogs/... ?workitem=<id>
        # from the board, /_boards/... likewise. The area segment is whatever
        # starts with an underscore; the project is the segment before it.
        for ($i = 0; $i -lt $segments.Count; $i++) {
            if ($segments[$i] -like '_*') {
                if ($i -ge 2) { $org = $segments[0]; $project = $segments[$i - 1] }
                break
            }
        }

        if ($segments.Count -gt 0 -and $segments[-1] -match '^\d+$') { $id = $segments[-1] }

        if (-not $id -and $uri.Query) {
            foreach ($pair in @($uri.Query.TrimStart('?') -split '&')) {
                $kv = $pair -split '=', 2
                if ($kv.Count -eq 2 -and $kv[0].ToLowerInvariant() -eq 'workitem' -and $kv[1] -match '^\d+$') {
                    $id = $kv[1]
                    break
                }
            }
        }

        if (-not $org -or -not $project -or -not $id) {
            Stop-WithError "Invalid backlog reference. Use a work item URL or <key>:<id>."
        }

        return @{
            organization_url = "https://dev.azure.com/$org"
            organization     = $org
            project          = $project
            id               = $id
            # The normalized URL, not the string the user pasted.
            reference        = "https://dev.azure.com/$org/$project/_workitems/edit/$id"
            source           = 'url'
            key              = $null
        }
    }

    if ($ref -match '^([^:]+):(\d+)$') {
        $key = $Matches[1].Trim()
        $id  = $Matches[2]

        $catalog = Read-BacklogCatalog -Path $CatalogPath
        if (-not $catalog.ContainsKey($key)) {
            $available = ($catalog.Keys | Sort-Object) -join ', '
            Stop-WithError ("Backlog key '{0}' not found. Available keys: {1}." -f $key, $available)
        }

        $orgUrl = $catalog[$key].organization_url.TrimEnd('/')
        return @{
            organization_url = $orgUrl
            organization     = ($orgUrl -split '/')[-1]
            project          = $catalog[$key].project
            id               = $id
            reference        = "${key}:${id}"
            source           = 'key'
            key              = $key
        }
    }

    Stop-WithError "Invalid backlog reference. Use a work item URL or <key>:<id>."
}

# ---------------------------------------------------------------------------
# Retrieval
# ---------------------------------------------------------------------------

function Get-AzureDevOpsWorkItem {
    param([hashtable]$Target)

    $pat = $env:AZDO_PAT
    if ([string]::IsNullOrWhiteSpace($pat)) {
        Stop-WithError "AZDO_PAT is not set in the environment."
    }

    # 5.1 may negotiate TLS 1.0 by default; Azure DevOps rejects it.
    [System.Net.ServicePointManager]::SecurityProtocol =
        [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

    $auth = [Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$pat"))
    $headers = @{ Authorization = "Basic $auth"; Accept = 'application/json' }

    # $expand is single-quoted: it would interpolate inside double quotes.
    $url = "{0}/{1}/_apis/wit/workitems/{2}" -f `
        $Target.organization_url, $Target.project, $Target.id
    $url += '?$expand=all&api-version=7.1'

    try {
        $resp = Invoke-WebRequest -Uri $url -Headers $headers -Method Get -UseBasicParsing
    }
    catch {
        $status = $null
        if ($_.Exception.Response) {
            try { $status = [int]$_.Exception.Response.StatusCode } catch { }
        }
        switch ($status) {
            401 { Stop-WithError "Authentication failed. The most likely cause is an expired PAT; check its expiry date before investigating scopes or permissions." }
            203 { Stop-WithError "Authentication failed. The most likely cause is an expired PAT; check its expiry date before investigating scopes or permissions." }
            403 { Stop-WithError ("Access denied to organization {0}. The PAT lacks the Work Items (Read) scope, or it is not scoped to this organization." -f $Target.organization) }
            404 { Stop-WithError ("Work item {0} not found in organization {1}." -f $Target.id, $Target.organization) }
            default {
                if ($status) { Stop-WithError ("Azure DevOps returned HTTP {0} for work item {1}." -f $status, $Target.id) }
                else         { Stop-WithError ("Azure DevOps could not be reached: {0}" -f $_.Exception.Message) }
            }
        }
    }

    # A 203 with an HTML sign-in page is how an expired PAT often surfaces.
    if ($resp.Headers['Content-Type'] -and $resp.Headers['Content-Type'] -notmatch 'application/json') {
        Stop-WithError "Authentication failed. The most likely cause is an expired PAT; check its expiry date before investigating scopes or permissions."
    }

    # Decode explicitly as UTF-8: relying on the response charset detection of
    # 5.1 corrupts accented characters in Spanish PBIs.
    $bytes = $resp.RawContentStream.ToArray()
    $text  = [System.Text.Encoding]::UTF8.GetString($bytes)

    try   { return $text | ConvertFrom-Json }
    catch { Stop-WithError "Azure DevOps returned a response that is not valid JSON." }
}

# ---------------------------------------------------------------------------
# Field access and content conversion
# ---------------------------------------------------------------------------

function Get-Prop {
    param($Object, [string]$Name)
    if ($null -eq $Object) { return $null }
    $p = $Object.PSObject.Properties[$Name]
    if ($null -eq $p) { return $null }
    return $p.Value
}

function Get-FieldFormat {
    param($WorkItem, [string]$FieldName)
    $formats = Get-Prop $WorkItem 'multilineFieldsFormat'
    $value   = Get-Prop $formats $FieldName
    if ($value) { return $value.ToString().ToLowerInvariant() }
    return 'html'
}

function Convert-FieldContent {
    param($WorkItem, [string]$FieldName, [string]$Html)

    $format = Get-FieldFormat -WorkItem $WorkItem -FieldName $FieldName

    if ($format -eq 'markdown') {
        # H-04: already Markdown. Copied literally, zero conversion, zero loss.
        return @{
            markdown      = $Html
            source_tokens = (Get-TextTokens $Html).Count
            payload_tokens = (Get-TextTokens $Html).Count
            source_depths = (Get-DepthProfile $Html)
            payload_depths = (Get-DepthProfile $Html)
            passed        = $true
        }
    }

    $converter = Join-Path $PSScriptRoot 'ConvertTo-MarkdownFromHtml.ps1'
    if (-not (Test-Path $converter)) {
        Stop-WithError ("Field '{0}' is declared as HTML and the HTML converter is not available yet (unit P13). The PBI was not loaded." -f $FieldName)
    }

    # Dot-sourced, not launched as a child process: piping Markdown between two
    # 5.1 processes is where the encoding breaks.
    . $converter
    $result = ConvertTo-MarkdownFromHtml -Html $Html
    foreach ($w in @($result.warnings)) {
        $script:Warnings.Add(("{0}: {1}" -f $FieldName, $w)) | Out-Null
    }
    if (-not $result.passed) {
        Stop-WithError ("Conversion verification failed for field '{0}': {1}. The PBI was not loaded." -f $FieldName, $result.detail)
    }
    return $result
}

function Get-TextTokens {
    param([string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return @() }
    $stripped = $Text -replace '(?m)^\s*([-*+]|\d+\.)\s+', ''
    $stripped = $stripped -replace '\s+', ' '
    return @($stripped.Trim() -split ' ' | Where-Object { $_ -ne '' })
}

function Get-DepthProfile {
    param([string]$Markdown)
    $depths = [System.Collections.Generic.List[int]]::new()
    if ([string]::IsNullOrWhiteSpace($Markdown)) { return @() }
    foreach ($line in ($Markdown -split "`r?`n")) {
        if ($line -match '^(\s*)([-*+]|\d+\.)\s+\S') {
            $depths.Add([int]([math]::Floor($Matches[1].Length / 2))) | Out-Null
        }
    }
    return @($depths.ToArray())
}

function Get-HeadingCounts {
    param([string]$Markdown)
    $counts = @{}
    if ([string]::IsNullOrWhiteSpace($Markdown)) { return $counts }
    foreach ($line in ($Markdown -split "`r?`n")) {
        if ($line -match '^(#{1,6})\s+\S') {
            $level = "h" + $Matches[1].Length
            if ($counts.ContainsKey($level)) { $counts[$level]++ } else { $counts[$level] = 1 }
        }
    }
    return $counts
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

$target = Resolve-Reference -Reference $Reference -CatalogPath $CatalogPath
$wi     = Get-AzureDevOpsWorkItem -Target $target
$f      = Get-Prop $wi 'fields'

# --- F-02 ------------------------------------------------------------------
$type = Get-Prop $f 'System.WorkItemType'
if ($ACCEPTED_TYPES -notcontains $type) {
    Stop-WithError ("Work item type '{0}' is not accepted. Expected Product Backlog Item or User Story." -f $type)
}

# --- F-01 ------------------------------------------------------------------
# Work item identifiers are unique per organization, not per project: a query
# naming the wrong project returns the work item anyway, with no error.
$actualProject = Get-Prop $f 'System.TeamProject'
if ($actualProject -and ($actualProject -ne $target.project)) {
    $configuredFor = if ($target.key) { "key '$($target.key)'" } else { "the reference" }
    Stop-WithError ("Project mismatch: work item {0} belongs to '{1}', but {2} is configured for '{3}'. Not loaded." -f `
        $target.id, $actualProject, $configuredFor, $target.project)
}

# --- Mandatory content (H-01) ----------------------------------------------
$descriptionRaw = Get-Prop $f 'System.Description'
$criteriaRaw    = Get-Prop $f 'Microsoft.VSTS.Common.AcceptanceCriteria'

if ([string]::IsNullOrWhiteSpace($descriptionRaw)) {
    Stop-WithError ("Work item {0} has no System.Description. It cannot be loaded as a PBI." -f $target.id)
}
if ([string]::IsNullOrWhiteSpace($criteriaRaw)) {
    Stop-WithError ("Work item {0} has no Microsoft.VSTS.Common.AcceptanceCriteria. It cannot be loaded as a PBI." -f $target.id)
}

$description = Convert-FieldContent -WorkItem $wi -FieldName 'System.Description' -Html $descriptionRaw
$criteria    = Convert-FieldContent -WorkItem $wi -FieldName 'Microsoft.VSTS.Common.AcceptanceCriteria' -Html $criteriaRaw

# --- Relations (F-04, F-05, F-09) ------------------------------------------
$dependencies = [System.Collections.Generic.List[string]]::new()
$children     = [System.Collections.Generic.List[string]]::new()
$attachments  = [System.Collections.Generic.List[string]]::new()
$artifactLinks = 0

$parentId = Get-Prop $f 'System.Parent'
if ($parentId) { $dependencies.Add("Parent work item: $parentId") | Out-Null }

foreach ($rel in @(Get-Prop $wi 'relations')) {
    if ($null -eq $rel) { continue }
    $relType = Get-Prop $rel 'rel'
    $relUrl  = Get-Prop $rel 'url'
    switch -Regex ($relType) {
        'Hierarchy-Reverse' {
            $rid = ($relUrl -split '/')[-1]
            if ($parentId -and "$rid" -eq "$parentId") { break }
            $dependencies.Add("Parent work item: $rid") | Out-Null
        }
        'Hierarchy-Forward' {
            $children.Add((($relUrl -split '/')[-1])) | Out-Null
        }
        'AttachedFile' {
            $name = Get-Prop (Get-Prop $rel 'attributes') 'name'
            if (-not $name) { $name = 'attachment' }
            $attachments.Add("$name - $relUrl") | Out-Null
        }
        'ArtifactLink' {
            $artifactLinks++
        }
    }
}

if ($artifactLinks -gt 0) {
    $script:Warnings.Add(("F-09: {0} artifact link(s) detected and discarded from the payload. Their presence indicates prior implementation of this PBI." -f $artifactLinks)) | Out-Null
}
$commentCount = Get-Prop $f 'System.CommentCount'
if ($commentCount -and [int]$commentCount -gt 0) {
    $script:Warnings.Add(("F-03: the work item has {0} comment(s). Comments are not incorporated into the payload." -f $commentCount)) | Out-Null
}
if ($children.Count -gt 0) {
    $script:Warnings.Add(("F-04: {0} child work item(s) exist and were not retrieved." -f $children.Count)) | Out-Null
}
if ($attachments.Count -gt 0) {
    $script:Warnings.Add(("F-05: {0} attachment(s) referenced by URL, not downloaded." -f $attachments.Count)) | Out-Null
}

# --- Notes and custom fields ------------------------------------------------
$notes = [System.Collections.Generic.List[string]]::new()

$effort = Get-Prop $f 'Microsoft.VSTS.Scheduling.Effort'
if ($null -ne $effort) { $notes.Add("Effort: $effort") | Out-Null }

if ($children.Count -gt 0) {
    $notes.Add("Child work items (not retrieved): " + ($children -join ', ')) | Out-Null
}
foreach ($a in $attachments) { $notes.Add("Attachment: $a") | Out-Null }

foreach ($prop in $f.PSObject.Properties) {
    if ($prop.Name -like 'WEF_*') { continue }
    if ($prop.Name -notlike 'Custom.*') { continue }
    if ($null -eq $prop.Value -or [string]::IsNullOrWhiteSpace([string]$prop.Value)) { continue }
    $notes.Add(("{0}: {1}" -f $prop.Name, $prop.Value)) | Out-Null
}

$governance = [System.Collections.Generic.List[string]]::new()
$state  = Get-Prop $f 'System.State'
$reason = Get-Prop $f 'System.Reason'
if ($state)  { $governance.Add("State: $state")   | Out-Null }
if ($reason) { $governance.Add("Reason: $reason") | Out-Null }

function Join-OrAbsent {
    param([System.Collections.Generic.List[string]]$Items)
    if ($Items.Count -eq 0) { return $ABSENT }
    return (($Items | ForEach-Object { "- $_" }) -join "`n")
}

# --- Payload ----------------------------------------------------------------
$headings = @{}
$headings['description']         = Get-HeadingCounts $description.markdown
$headings['acceptance_criteria'] = Get-HeadingCounts $criteria.markdown

$payload = @{
    schema = $SCHEMA
    status = 'ok'
    envelope = @{
        type           = 'Azure DevOps work item'
        reference      = $target.reference
        organization   = $target.organization
        project        = $actualProject
        work_item_id   = "$($target.id)"
        work_item_type = "$type"
        revision       = "$(Get-Prop $wi 'rev')"
        changed_at     = "$(Get-Prop $f 'System.ChangedDate')"
        retrieved_via  = 'REST API v7.1'
        loaded_at      = (Get-Date).ToString('o')
    }
    sections = @{
        title               = "$(Get-Prop $f 'System.Title')"
        description         = $description.markdown
        business_context    = $ABSENT
        acceptance_criteria = $criteria.markdown
        constraints         = $ABSENT
        dependencies        = (Join-OrAbsent $dependencies)
        out_of_scope        = $ABSENT
        notes               = (Join-OrAbsent $notes)
        governance_notes    = (Join-OrAbsent $governance)
    }
    verification = @{
        text_completeness = @{
            passed         = ($description.passed -and $criteria.passed)
            source_tokens  = ($description.source_tokens  + $criteria.source_tokens)
            payload_tokens = ($description.payload_tokens + $criteria.payload_tokens)
        }
        depth_profile = @{
            passed  = ($description.passed -and $criteria.passed)
            source  = @($description.source_depths  + $criteria.source_depths)
            payload = @($description.payload_depths + $criteria.payload_depths)
        }
        heading_counts = $headings
    }
    warnings = @($script:Warnings.ToArray())
    errors   = @()
}

if (-not $payload.verification.text_completeness.passed) {
    Stop-WithError "Conversion verification failed: token sequences differ between source and payload. The PBI was not loaded."
}

Write-Payload  -Payload $payload -Path $PayloadPath
Write-Sections -Payload $payload -Path $SectionsPath
Write-Output ("status=ok payload={0} sections={1}" -f $PayloadPath, $SectionsPath)
exit 0
