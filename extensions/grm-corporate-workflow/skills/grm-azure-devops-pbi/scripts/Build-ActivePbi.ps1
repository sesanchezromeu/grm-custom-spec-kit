#Requires -Version 5.1
<#
    Build-ActivePbi.ps1

    Assemble active-pbi.md from the fragments written by Get-WorkItem.ps1.

    Why a script writes this file (D-P14b-02): in an observed run the agent
    produced a well written active-pbi.md that added a third dialog option, a
    modal requirement and a localisation requirement absent from the work item,
    dropped an informational message and a traceability rule present in it, and
    normalised typographic quotes to straight ones. Instructing the agent not
    to do that did not prevent it. Assembly is therefore mechanical.

    The agent runs this command and reads the result. It writes nothing.

    Exit codes: 0 written, 1 failure.

    Usage:
      powershell -NoProfile -ExecutionPolicy Bypass -File .github\skills\grm-azure-devops-pbi\scripts\Build-ActivePbi.ps1
#>

[CmdletBinding()]
param(
    [string]$SectionsPath = ".specify/memory/.grm-pbi-sections",

    [string]$ActivePbiPath = ".specify/memory/active-pbi.md",

    # Optional override. The authority for this text is corp.load.agent.md;
    # the copy below is a copy and is declared as such (D-P14b-03).
    [string]$GovernanceNotesPath
)

$ErrorActionPreference = "Stop"

$DEFAULT_GOVERNANCE = @(
    '- This PBI is the functional source of truth for the current Spec Kit workflow.',
    '- The developer must not change functional scope.',
    '- The developer must not invent acceptance criteria.',
    '- Missing or unclear functional information must be escalated to the Product Owner.',
    '- Technical assumptions may be identified later by /corp.assess.',
    '- No free-form functional specification has been generated.'
) -join "`r`n"

# Heading -> fragment. Order is the order of the file.
$LAYOUT = [ordered]@{
    'Source'                          = 'source.md'
    'Original PBI Content (Verbatim)' = 'verbatim.md'
    'PBI ID'                          = 'pbi_id.md'
    'Title'                           = 'title.md'
    'Description'                     = 'description.md'
    'Business Context'                = 'business_context.md'
    'Acceptance Criteria'             = 'acceptance_criteria.md'
    'Constraints'                     = 'constraints.md'
    'Dependencies'                    = 'dependencies.md'
    'Out of Scope'                    = 'out_of_scope.md'
    'Notes'                           = 'notes.md'
    'Governance Notes'                = $null            # fixed text, not from source
    'Source work item state'          = 'source_work_item_state.md'
}

function Stop-Build {
    param([string]$Message)
    [Console]::Error.WriteLine($Message)
    Write-Output "build=failed"
    exit 1
}

if (-not (Test-Path $SectionsPath)) {
    Stop-Build "Section fragments not found at $SectionsPath. Run Get-WorkItem.ps1 first."
}

$governance = $DEFAULT_GOVERNANCE
if ($GovernanceNotesPath) {
    if (-not (Test-Path $GovernanceNotesPath)) {
        Stop-Build "Governance notes not found at $GovernanceNotesPath."
    }
    $abs = (Resolve-Path $GovernanceNotesPath).Path
    $governance = ([System.IO.File]::ReadAllText($abs, [System.Text.Encoding]::UTF8)).TrimEnd()
}

$out = [System.Collections.Generic.List[string]]::new()
$out.Add('# Active PBI') | Out-Null

foreach ($heading in $LAYOUT.Keys) {

    $body = $null

    if ($null -eq $LAYOUT[$heading]) {
        $body = $governance
    }
    else {
        $fragment = Join-Path $SectionsPath $LAYOUT[$heading]
        if (-not (Test-Path $fragment)) {
            Stop-Build ("Fragment missing: {0}. The retrieval is incomplete; nothing was written." -f $LAYOUT[$heading])
        }
        # Resolve-Path first: .NET methods resolve relative paths against the
        # process working directory, not the PowerShell location.
        $abs  = (Resolve-Path $fragment).Path
        $body = ([System.IO.File]::ReadAllText($abs, [System.Text.Encoding]::UTF8)).TrimEnd()
    }

    if ([string]::IsNullOrWhiteSpace($body)) {
        Stop-Build ("Section '{0}' resolved to empty content. Nothing was written." -f $heading)
    }

    $out.Add('') | Out-Null
    $out.Add('## ' + $heading) | Out-Null
    foreach ($line in ($body -split "`r?`n")) { $out.Add($line) | Out-Null }
}

$dir = Split-Path -Parent $ActivePbiPath
if ($dir -and -not (Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}

# UTF-8 with BOM and CRLF, matching what corp.load.agent.md mandates and what
# the non-regression baselines were captured with.
$text = ($out -join "`r`n") + "`r`n"
[System.IO.File]::WriteAllText(
    [System.IO.Path]::Combine((Get-Location).Path, $ActivePbiPath),
    $text,
    (New-Object System.Text.UTF8Encoding($true)))

Write-Output ("build=ok active_pbi={0} sections={1}" -f $ActivePbiPath, ($LAYOUT.Count))
exit 0