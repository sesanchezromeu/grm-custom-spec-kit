#Requires -Version 5.1
<#
    Test-ActivePbiAssertion.ps1

    Arnes de pruebas para Assert-ActivePbi.ps1 (P23b). Versionado en
    resources/tools/ por el mismo motivo que Test-SkillShape.ps1 y
    Test-InstallationReport.ps1: herramienta de mantenedor, no artefacto
    desplegable.

    A diferencia de esos dos arneses, Assert-ActivePbi.ps1 acepta rutas por
    parametro: no hace falta extraer funciones del AST de un instalador
    monolitico. Cada escenario escribe una carpeta de fragmentos y un
    active-pbi.md desechables bajo %TEMP%, invoca el script bajo prueba como
    proceso real, y comprueba su codigo de salida y su salida por consola,
    que es su contrato (D-P16-XX, mismo principio que L-04: el mensaje de
    exito se deriva del resultado o no vale nada).

    Cobertura (L-20: cada negativa apunta a un mecanismo nombrado):
      1. positiva-completa               camino feliz, origen fichero
      2. positiva-backlog-con-estado     camino feliz, con Source work item state
      3. preambulo-con-intrusa           OBS-P23-01
      4. cola-tras-governance-notes      OBS-P22-09 (regresion de F3, P22b)
      5. encabezado-duplicado            OBS-P23-02
      6. orden-alterado                  OBS-P23-03
      7. intrusa-en-seccion-comparada    regresion del comparador (F3b, P22b)

    Uso:
      powershell -NoProfile -ExecutionPolicy Bypass -File resources\tools\Test-ActivePbiAssertion.ps1

    Salida: una linea PASS o FAIL por escenario, y "TEST HARNESS: OK" o
    "TEST HARNESS: FAILED (n)" al final. Codigo de salida 0 si todo pasa,
    1 en caso contrario.
#>

param(
    [string]$ScriptPath = (Join-Path $PSScriptRoot "..\..\extensions\grm-corporate-workflow\skills\_shared\scripts\Assert-ActivePbi.ps1")
)

$ErrorActionPreference = "Stop"

$resolvedScript = (Resolve-Path -LiteralPath $ScriptPath).ProviderPath
$enc = New-Object System.Text.UTF8Encoding($false)
$results = [System.Collections.Generic.List[pscustomobject]]::new()

function New-Fixture {
    param([string]$Root)
    $sections = Join-Path $Root "sections"
    New-Item -ItemType Directory -Path $sections -Force | Out-Null

    $fragments = [ordered]@{
        'source.md'             = "- Type: Markdown file`n- Reference: fixture.md"
        'verbatim.md'           = "Fixture description.`n`n---`n`n**Acceptance Criteria**`n`nAC-01. Fixture criterion."
        'pbi_id.md'             = "FIXTURE-01"
        'title.md'              = "Fixture title"
        'description.md'        = "Fixture description."
        'business_context.md'   = "Fixture context."
        'acceptance_criteria.md'= "AC-01. Fixture criterion."
        'constraints.md'        = "Fixture constraint."
        'dependencies.md'       = "None."
        'out_of_scope.md'       = "Fixture out of scope."
        'notes.md'              = "Fixture note."
        'governance_notes.md'   = "- This PBI is the functional source of truth for the current Spec Kit workflow."
    }
    foreach ($name in $fragments.Keys) {
        [System.IO.File]::WriteAllText((Join-Path $sections $name), [string]$fragments[$name], $enc)
    }
    return [pscustomobject]@{ Root = $Root; Sections = $sections; Fragments = $fragments }
}

function New-BaselineBody {
    param($Fixture, [switch]$WithWorkItemState)
    $f = $Fixture.Fragments
    $order = @(
        @{ h = 'Source'; k = 'source.md' }
        @{ h = 'Original PBI Content (Verbatim)'; k = 'verbatim.md' }
        @{ h = 'PBI ID'; k = 'pbi_id.md' }
        @{ h = 'Title'; k = 'title.md' }
        @{ h = 'Description'; k = 'description.md' }
        @{ h = 'Business Context'; k = 'business_context.md' }
        @{ h = 'Acceptance Criteria'; k = 'acceptance_criteria.md' }
        @{ h = 'Constraints'; k = 'constraints.md' }
        @{ h = 'Dependencies'; k = 'dependencies.md' }
        @{ h = 'Out of Scope'; k = 'out_of_scope.md' }
        @{ h = 'Notes'; k = 'notes.md' }
        @{ h = 'Governance Notes'; k = 'governance_notes.md' }
    )
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add('# Active PBI') | Out-Null
    $lines.Add('') | Out-Null
    foreach ($item in $order) {
        $lines.Add('## ' + $item.h) | Out-Null
        $lines.Add($f[$item.k]) | Out-Null
        $lines.Add('') | Out-Null
    }
    if ($WithWorkItemState) {
        $stateText = "- State: Closed`n- Reason: Fixed"
        [System.IO.File]::WriteAllText((Join-Path $Fixture.Sections 'source_work_item_state.md'), $stateText, $enc)
        $lines.Add('## Source work item state') | Out-Null
        $lines.Add($stateText) | Out-Null
        $lines.Add('') | Out-Null
    }
    return ($lines -join "`r`n")
}

function Invoke-Assertion {
    param([string]$ActivePbiPath, [string]$SectionsPath)
    # $ErrorActionPreference = "Stop" rige tambien sobre el proceso hijo: al
    # capturar su stderr con 2>&1, cada linea llega como ErrorRecord, y con
    # "Stop" vigente escribirla al pipeline aborta el arnes en vez de
    # guardarla. Se relaja localmente solo para esta llamada.
    $prevEap = $ErrorActionPreference
    try {
        $ErrorActionPreference = "Continue"
        $raw = & powershell -NoProfile -ExecutionPolicy Bypass -File $resolvedScript `
            -ActivePbiPath $ActivePbiPath -SectionsPath $SectionsPath 2>&1
    }
    finally {
        $ErrorActionPreference = $prevEap
    }
    $lines = @($raw | ForEach-Object {
        if ($_ -is [System.Management.Automation.ErrorRecord]) { $_.Exception.Message } else { [string]$_ }
    })
    return [pscustomobject]@{ Output = ($lines -join "`n"); ExitCode = $LASTEXITCODE }
}

function Add-Result {
    param([string]$Name, [bool]$Pass, [string]$Detail)
    $results.Add([pscustomobject]@{ Name = $Name; Pass = $Pass }) | Out-Null
    "{0}  {1}  ({2})" -f $(if ($Pass) { "PASS" } else { "FAIL" }), $Name, $Detail
}

$work = Join-Path ([System.IO.Path]::GetTempPath()) ("grm-assert-pbi-" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $work -Force | Out-Null

try {
    # 1. positiva-completa
    $r = Join-Path $work "s1"; New-Item -ItemType Directory -Path $r -Force | Out-Null
    $fx = New-Fixture -Root $r
    $pbi = Join-Path $r "active-pbi.md"
    [System.IO.File]::WriteAllText($pbi, (New-BaselineBody -Fixture $fx), (New-Object System.Text.UTF8Encoding($true)))
    $res = Invoke-Assertion -ActivePbiPath $pbi -SectionsPath $fx.Sections
    Add-Result "positiva-completa" `
        ($res.ExitCode -eq 0 -and $res.Output -match 'verification=ok sections=12') $res.Output

    # 2. positiva-backlog-con-estado
    $r = Join-Path $work "s2"; New-Item -ItemType Directory -Path $r -Force | Out-Null
    $fx = New-Fixture -Root $r
    $pbi = Join-Path $r "active-pbi.md"
    [System.IO.File]::WriteAllText($pbi, (New-BaselineBody -Fixture $fx -WithWorkItemState), (New-Object System.Text.UTF8Encoding($true)))
    $res = Invoke-Assertion -ActivePbiPath $pbi -SectionsPath $fx.Sections
    Add-Result "positiva-backlog-con-estado" `
        ($res.ExitCode -eq 0 -and $res.Output -match 'verification=ok sections=13') $res.Output

    # 3. preambulo-con-intrusa (OBS-P23-01)
    $r = Join-Path $work "s3"; New-Item -ItemType Directory -Path $r -Force | Out-Null
    $fx = New-Fixture -Root $r
    $body = (New-BaselineBody -Fixture $fx) -replace [regex]::Escape("# Active PBI`r`n"), "# Active PBI`r`nIntrusive preamble line.`r`n"
    $pbi = Join-Path $r "active-pbi.md"
    [System.IO.File]::WriteAllText($pbi, $body, (New-Object System.Text.UTF8Encoding($true)))
    $res = Invoke-Assertion -ActivePbiPath $pbi -SectionsPath $fx.Sections
    Add-Result "preambulo-con-intrusa" `
        ($res.ExitCode -ne 0 -and $res.Output -match 'verification=failed' -and $res.Output -match 'before the first section') $res.Output

    # 4. cola-tras-governance-notes (OBS-P22-09)
    $r = Join-Path $work "s4"; New-Item -ItemType Directory -Path $r -Force | Out-Null
    $fx = New-Fixture -Root $r
    $body = (New-BaselineBody -Fixture $fx) + "`r`nIntrusive trailing line.`r`n"
    $pbi = Join-Path $r "active-pbi.md"
    [System.IO.File]::WriteAllText($pbi, $body, (New-Object System.Text.UTF8Encoding($true)))
    $res = Invoke-Assertion -ActivePbiPath $pbi -SectionsPath $fx.Sections
    Add-Result "cola-tras-governance-notes" `
        ($res.ExitCode -ne 0 -and $res.Output -match 'verification=failed' -and $res.Output -match "'Governance Notes'") $res.Output

    # 5. encabezado-duplicado (OBS-P23-02)
    $r = Join-Path $work "s5"; New-Item -ItemType Directory -Path $r -Force | Out-Null
    $fx = New-Fixture -Root $r
    $needle = "## Notes`r`n" + $fx.Fragments['notes.md']
    $body = (New-BaselineBody -Fixture $fx) -replace [regex]::Escape($needle), `
        ($needle + "`r`n`r`n## Description`r`nDuplicated section.")
    $pbi = Join-Path $r "active-pbi.md"
    [System.IO.File]::WriteAllText($pbi, $body, (New-Object System.Text.UTF8Encoding($true)))
    $res = Invoke-Assertion -ActivePbiPath $pbi -SectionsPath $fx.Sections
    Add-Result "encabezado-duplicado" `
        ($res.ExitCode -ne 0 -and $res.Output -match 'out of order or more than once') $res.Output

    # 6. orden-alterado (OBS-P23-03)
    $r = Join-Path $work "s6"; New-Item -ItemType Directory -Path $r -Force | Out-Null
    $fx = New-Fixture -Root $r
    $needle = "## PBI ID`r`n" + $fx.Fragments['pbi_id.md'] + "`r`n`r`n## Title`r`n" + $fx.Fragments['title.md']
    $swap = "## Title`r`n" + $fx.Fragments['title.md'] + "`r`n`r`n## PBI ID`r`n" + $fx.Fragments['pbi_id.md']
    $body = (New-BaselineBody -Fixture $fx) -replace [regex]::Escape($needle), $swap
    $pbi = Join-Path $r "active-pbi.md"
    [System.IO.File]::WriteAllText($pbi, $body, (New-Object System.Text.UTF8Encoding($true)))
    $res = Invoke-Assertion -ActivePbiPath $pbi -SectionsPath $fx.Sections
    Add-Result "orden-alterado" `
        ($res.ExitCode -ne 0 -and $res.Output -match 'out of order or more than once') $res.Output

    # 7. intrusa-en-seccion-comparada (regresion F3b)
    $r = Join-Path $work "s7"; New-Item -ItemType Directory -Path $r -Force | Out-Null
    $fx = New-Fixture -Root $r
    $needle = "## Description`r`n" + $fx.Fragments['description.md']
    $body = (New-BaselineBody -Fixture $fx) -replace [regex]::Escape($needle), `
        ($needle + "`r`nIntrusive line inside a compared section.")
    $pbi = Join-Path $r "active-pbi.md"
    [System.IO.File]::WriteAllText($pbi, $body, (New-Object System.Text.UTF8Encoding($true)))
    $res = Invoke-Assertion -ActivePbiPath $pbi -SectionsPath $fx.Sections
    Add-Result "intrusa-en-seccion-comparada" `
        ($res.ExitCode -ne 0 -and $res.Output -match "section 'Description'") $res.Output

    # 8. titulo-de-una-linea-alterado (defecto de Get-ComparableLines)
    $r = Join-Path $work "s8"; New-Item -ItemType Directory -Path $r -Force | Out-Null
    $fx = New-Fixture -Root $r
    $needle = "## Title`r`n" + $fx.Fragments['title.md']
    $body = (New-BaselineBody -Fixture $fx) -replace [regex]::Escape($needle), "## Title`r`nFixture TAMPERED"
    $pbi = Join-Path $r "active-pbi.md"
    [System.IO.File]::WriteAllText($pbi, $body, (New-Object System.Text.UTF8Encoding($true)))
    $res = Invoke-Assertion -ActivePbiPath $pbi -SectionsPath $fx.Sections
    Add-Result "titulo-de-una-linea-alterado" `
        ($res.ExitCode -ne 0 -and $res.Output -match "section 'Title'") $res.Output
}
finally {
    Remove-Item -Path $work -Recurse -Force -ErrorAction SilentlyContinue
}

$failed = @($results | Where-Object { -not $_.Pass })
if ($failed.Count -gt 0) {
    Write-Output ("TEST HARNESS: FAILED ({0}/{1} escenarios)" -f $failed.Count, $results.Count)
    exit 1
}
Write-Output ("TEST HARNESS: OK ({0} escenarios)" -f $results.Count)
exit 0
