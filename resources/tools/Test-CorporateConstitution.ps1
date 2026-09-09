#Requires -Version 5.1
<#
    Test-CorporateConstitution.ps1

    Arnes de pruebas para Assert-CorporateConstitution.ps1 (PA-02, D-P29-08:
    a). Versionado en resources/tools/ por el mismo motivo que
    Test-ActivePbiAssertion.ps1 y Test-ActiveContextReset.ps1: herramienta
    de mantenedor, no artefacto desplegable.

    El script bajo prueba no acepta la ruta por parametro (D-P29-09):
    resuelve una ruta fija contra el directorio de trabajo. Cada escenario
    crea un espacio de trabajo desechable bajo %TEMP%, se situa en el con
    Push-Location, invoca el script como proceso real y comprueba su
    codigo de salida y su salida por consola, que es su contrato.

    Cobertura (L-20: cada negativa apunta a un mecanismo nombrado):
      1. ausente        no existe .specify/memory/constitution.md (ni el
                         arbol .specify/ en absoluto)
      2. vacio           el fichero existe con longitud cero
      3. solo-espacios   el fichero existe pero solo contiene espacios,
                         tabs y saltos de linea (D-P29-06: b, Trim() en vez
                         de TrimEnd solo del salto final)
      4. valido          camino feliz -- ademas de exit=0 y
                         constitution=ok, comprueba que el contenido
                         impreso reproduce el fixture de forma verbatim,
                         no solo que aparezca la palabra "ok"

    Uso:
      powershell -NoProfile -ExecutionPolicy Bypass -File resources\tools\Test-CorporateConstitution.ps1

    Salida: una linea PASS o FAIL por escenario, y "TEST HARNESS: OK" o
    "TEST HARNESS: FAILED (n)" al final. Codigo de salida 0 si todo pasa,
    1 en caso contrario.
#>

param(
    [string]$ScriptPath = (Join-Path $PSScriptRoot "..\..\extensions\grm-corporate-workflow\skills\_shared\scripts\Assert-CorporateConstitution.ps1")
)

$ErrorActionPreference = "Stop"

$resolvedScript = (Resolve-Path -LiteralPath $ScriptPath).ProviderPath
$enc            = New-Object System.Text.UTF8Encoding($false)
$results        = [System.Collections.Generic.List[pscustomobject]]::new()

$CONSTITUTION_REL = '.specify\memory\constitution.md'

function New-Workspace {
    param([string]$Root, [string]$Content, [switch]$NoSpecifyTree)
    # $Root se crea siempre: Push-Location necesita el directorio de trabajo
    # aunque el escenario "ausente" no quiera ningun arbol .specify/ dentro.
    New-Item -ItemType Directory -Path $Root -Force | Out-Null
    if (-not $NoSpecifyTree) {
        New-Item -ItemType Directory -Path (Join-Path $Root '.specify\memory') -Force | Out-Null
        if ($null -ne $Content) {
            [System.IO.File]::WriteAllText((Join-Path $Root $CONSTITUTION_REL), $Content, $enc)
        }
    }
    return $Root
}

function Invoke-Assert {
    param([string]$WorkingDirectory)
    # Mismo motivo que Test-ActiveContextReset.ps1: "Stop" tambien rige el
    # proceso hijo al capturar stderr con 2>&1, y con "Stop" vigente
    # escribir una linea de stderr al pipeline aborta el arnes en vez de
    # guardarla. Se relaja localmente solo para esta llamada.
    $prevEap = $ErrorActionPreference
    Push-Location -LiteralPath $WorkingDirectory
    try {
        $ErrorActionPreference = "Continue"
        $raw  = & powershell -NoProfile -ExecutionPolicy Bypass -File $resolvedScript 2>&1
        $code = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $prevEap
        Pop-Location
    }
    $lines = @($raw | ForEach-Object {
        if ($_ -is [System.Management.Automation.ErrorRecord]) { $_.Exception.Message } else { [string]$_ }
    })
    return [pscustomobject]@{ Output = ($lines -join "`n"); ExitCode = $code }
}

function Add-Result {
    param([string]$Name, [bool]$Pass, [string]$Detail)
    $results.Add([pscustomobject]@{ Name = $Name; Pass = $Pass }) | Out-Null
    "{0}  {1}  ({2})" -f $(if ($Pass) { "PASS" } else { "FAIL" }), $Name, $Detail
}

$work = Join-Path ([System.IO.Path]::GetTempPath()) ("grm-assert-constitution-" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $work -Force | Out-Null

try {
    # 1. ausente -- ni el arbol .specify/ existe
    $r   = New-Workspace -Root (Join-Path $work "s1") -NoSpecifyTree
    $res = Invoke-Assert -WorkingDirectory $r
    Add-Result "ausente" `
        ($res.ExitCode -ne 0 `
         -and $res.Output.Contains("Corporate constitution NOT loaded.") `
         -and $res.Output.Contains("- .specify/memory/constitution.md exists: no") `
         -and $res.Output.Contains("- .specify/memory/constitution.md non-empty: n/a") `
         -and $res.Output.Contains("constitution=failed") `
         -and (-not $res.Output.Contains("constitution=ok"))) $res.Output

    # 2. vacio -- longitud cero
    $r   = New-Workspace -Root (Join-Path $work "s2") -Content ""
    $res = Invoke-Assert -WorkingDirectory $r
    Add-Result "vacio" `
        ($res.ExitCode -ne 0 `
         -and $res.Output.Contains("Corporate constitution NOT loaded.") `
         -and $res.Output.Contains("- .specify/memory/constitution.md exists: yes") `
         -and $res.Output.Contains("- .specify/memory/constitution.md non-empty: no") `
         -and $res.Output.Contains("constitution=failed") `
         -and (-not $res.Output.Contains("constitution=ok"))) $res.Output

    # 3. solo-espacios -- D-P29-06: b, Trim() de ambos lados, no solo TrimEnd
    #    del salto final
    $r   = New-Workspace -Root (Join-Path $work "s3") -Content "   `r`n`t `r`n  `r`n"
    $res = Invoke-Assert -WorkingDirectory $r
    Add-Result "solo-espacios" `
        ($res.ExitCode -ne 0 `
         -and $res.Output.Contains("Corporate constitution NOT loaded.") `
         -and $res.Output.Contains("- .specify/memory/constitution.md exists: yes") `
         -and $res.Output.Contains("- .specify/memory/constitution.md non-empty: no") `
         -and $res.Output.Contains("constitution=failed") `
         -and (-not $res.Output.Contains("constitution=ok"))) $res.Output

    # 4. valido -- camino feliz. Fixture con 4 lineas reales; se comprueba
    #    que el contenido impreso reproduce el fixture de forma verbatim,
    #    no solo que aparezca "ok" (L-20).
    $fixture = "# Test Constitution`r`n`r`nRule 1: keep it short.`r`nRule 2: keep it testable.`r`n"
    $r   = New-Workspace -Root (Join-Path $work "s4") -Content $fixture
    $res = Invoke-Assert -WorkingDirectory $r
    Add-Result "valido" `
        ($res.ExitCode -eq 0 `
         -and $res.Output.Contains("Corporate constitution loaded.") `
         -and $res.Output.Contains("- .specify/memory/constitution.md exists: yes") `
         -and $res.Output.Contains("- .specify/memory/constitution.md non-empty: yes") `
         -and $res.Output.Contains("- lines: 4") `
         -and $res.Output.Contains("# Test Constitution") `
         -and $res.Output.Contains("Rule 1: keep it short.") `
         -and $res.Output.Contains("Rule 2: keep it testable.") `
         -and $res.Output.Contains("constitution=ok") `
         -and (-not $res.Output.Contains("constitution=failed"))) $res.Output
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
