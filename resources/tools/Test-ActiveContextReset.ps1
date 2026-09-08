#Requires -Version 5.1
<#
    Test-ActiveContextReset.ps1

    Arnes de pruebas acotado para los dos borrados que U3a anade a
    Reset-ActiveContext.ps1 (OBS-P23-04). Versionado en resources/tools/ por
    el mismo motivo que Test-ActivePbiAssertion.ps1: herramienta de
    mantenedor, no artefacto desplegable.

    A diferencia de Assert-ActivePbi.ps1, el script bajo prueba no acepta
    rutas por parametro (D-P25-06): resuelve cuatro rutas fijas contra el
    directorio de trabajo. Cada escenario crea un espacio de trabajo
    desechable bajo %TEMP% con .specify/memory/ y features/, se situa en el
    con Push-Location, invoca el script como proceso real y comprueba su
    codigo de salida y su salida por consola, que es su contrato.

    Cada escenario comprueba ademas el estado en disco dentro de su propio
    espacio de trabajo. No es redundancia: si el directorio de trabajo no se
    propagase al proceso hijo, el informe podria salir correcto describiendo
    ficheros de otro sitio, y esa comprobacion es la que lo detecta (L-14).

    Alcance (D-P25-03): solo los dos borrados nuevos y sus dos ramas de
    fallo. El stub, features/ y el puntero no reciben cobertura retroactiva
    aqui; siguen en OBS-P24-03.

    Cobertura (L-20: cada negativa apunta a un mecanismo nombrado):
      1. ambos-presentes        camino feliz, done + absent en los dos
      2. ninguno-presente       skipped no penaliza $ok
      3. fragmentos-bloqueados  rama de fallo del directorio, con enumeracion
      4. payload-bloqueado      rama de fallo del fichero, sin enumeracion

    Los escenarios 3 y 4 abren un handle con FileShare::None sobre el
    artefacto y lo mantienen mientras corre el script: Remove-Item falla con
    acceso denegado, que es la rama que hay que ver fallar antes de cerrar la
    unidad que la introduce (L-03, L-15, L-20). El handle se libera siempre
    en el finally del escenario.

    Uso:
      powershell -NoProfile -ExecutionPolicy Bypass -File resources\tools\Test-ActiveContextReset.ps1

    Salida: una linea PASS o FAIL por escenario, y "TEST HARNESS: OK" o
    "TEST HARNESS: FAILED (n)" al final. Codigo de salida 0 si todo pasa,
    1 en caso contrario.
#>

param(
    [string]$ScriptPath = (Join-Path $PSScriptRoot "..\..\extensions\grm-corporate-workflow\skills\_shared\scripts\Reset-ActiveContext.ps1")
)

$ErrorActionPreference = "Stop"

$resolvedScript = (Resolve-Path -LiteralPath $ScriptPath).ProviderPath
$enc     = New-Object System.Text.UTF8Encoding($false)
$results = [System.Collections.Generic.List[pscustomobject]]::new()

$SECTIONS_REL = '.specify\memory\.grm-pbi-sections'
$PAYLOAD_REL  = '.specify\memory\.grm-pbi-payload.json'

function New-Workspace {
    param([string]$Root, [switch]$WithArtifacts)
    New-Item -ItemType Directory -Path (Join-Path $Root '.specify\memory') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $Root 'features') -Force | Out-Null
    if ($WithArtifacts) {
        $sections = Join-Path $Root $SECTIONS_REL
        New-Item -ItemType Directory -Path $sections -Force | Out-Null
        [System.IO.File]::WriteAllText((Join-Path $sections 'source.md'), "- Type: Markdown file", $enc)
        [System.IO.File]::WriteAllText((Join-Path $sections 'title.md'), "Fixture title", $enc)
        [System.IO.File]::WriteAllText((Join-Path $Root $PAYLOAD_REL), '{ "fixture": true }', $enc)
    }
    return $Root
}

function Invoke-Reset {
    param([string]$WorkingDirectory)
    # $ErrorActionPreference = "Stop" rige tambien sobre el proceso hijo: al
    # capturar su stderr con 2>&1, cada linea llega como ErrorRecord, y con
    # "Stop" vigente escribirla al pipeline aborta el arnes en vez de
    # guardarla. Se relaja localmente solo para esta llamada.
    $prevEap = $ErrorActionPreference
    Push-Location -LiteralPath $WorkingDirectory
    try {
        $ErrorActionPreference = "Continue"
        $raw = & powershell -NoProfile -ExecutionPolicy Bypass -File $resolvedScript 2>&1
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

$work = Join-Path ([System.IO.Path]::GetTempPath()) ("grm-reset-context-" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $work -Force | Out-Null

try {
    # 1. ambos-presentes
    $r = New-Workspace -Root (Join-Path $work "s1") -WithArtifacts
    $res = Invoke-Reset -WorkingDirectory $r
    $sectionsGone = -not (Test-Path -LiteralPath (Join-Path $r $SECTIONS_REL))
    $payloadGone  = -not (Test-Path -LiteralPath (Join-Path $r $PAYLOAD_REL))
    $stubWritten  = Test-Path -LiteralPath (Join-Path $r '.specify\memory\active-pbi.md')
    Add-Result "ambos-presentes" `
        ($res.ExitCode -eq 0 `
         -and $res.Output.Contains("- .specify/memory/.grm-pbi-sections/ removed: done") `
         -and $res.Output.Contains("- .specify/memory/.grm-pbi-payload.json removed: done") `
         -and $res.Output.Contains("- .specify/memory/.grm-pbi-sections/ absent: yes") `
         -and $res.Output.Contains("- .specify/memory/.grm-pbi-payload.json absent: yes") `
         -and $res.Output.Contains("reset=ok") `
         -and $sectionsGone -and $payloadGone -and $stubWritten) $res.Output

    # 2. ninguno-presente
    $r = New-Workspace -Root (Join-Path $work "s2")
    $res = Invoke-Reset -WorkingDirectory $r
    $stubWritten = Test-Path -LiteralPath (Join-Path $r '.specify\memory\active-pbi.md')
    Add-Result "ninguno-presente" `
        ($res.ExitCode -eq 0 `
         -and $res.Output.Contains("- .specify/memory/.grm-pbi-sections/ removed: skipped") `
         -and $res.Output.Contains("- .specify/memory/.grm-pbi-payload.json removed: skipped") `
         -and $res.Output.Contains("- .specify/memory/.grm-pbi-sections/ absent: yes") `
         -and $res.Output.Contains("- .specify/memory/.grm-pbi-payload.json absent: yes") `
         -and $res.Output.Contains("reset=ok") `
         -and $stubWritten) $res.Output

    # 3. fragmentos-bloqueados
    $r = New-Workspace -Root (Join-Path $work "s3") -WithArtifacts
    $locked = Join-Path (Join-Path $r $SECTIONS_REL) 'source.md'
    $handle = [System.IO.File]::Open($locked, [System.IO.FileMode]::Open,
                                     [System.IO.FileAccess]::Read,
                                     [System.IO.FileShare]::None)
    try {
        $res = Invoke-Reset -WorkingDirectory $r
    }
    finally {
        $handle.Close()
        $handle.Dispose()
    }
    $sectionsStill = Test-Path -LiteralPath (Join-Path $r $SECTIONS_REL)
    Add-Result "fragmentos-bloqueados" `
        ($res.ExitCode -ne 0 `
         -and $res.Output.Contains("Corporate context erase failed.") `
         -and $res.Output.Contains("- .specify/memory/.grm-pbi-sections/ removed: failed") `
         -and $res.Output.Contains("- .specify/memory/.grm-pbi-sections/ absent: no") `
         -and $res.Output.Contains("Section fragments could not be removed") `
         -and $res.Output.Contains("Section fragment still present") `
         -and $res.Output.Contains("reset=failed") `
         -and (-not $res.Output.Contains("reset=ok")) `
         -and $sectionsStill) $res.Output

    # 4. payload-bloqueado
    $r = New-Workspace -Root (Join-Path $work "s4") -WithArtifacts
    $locked = Join-Path $r $PAYLOAD_REL
    $handle = [System.IO.File]::Open($locked, [System.IO.FileMode]::Open,
                                     [System.IO.FileAccess]::Read,
                                     [System.IO.FileShare]::None)
    try {
        $res = Invoke-Reset -WorkingDirectory $r
    }
    finally {
        $handle.Close()
        $handle.Dispose()
    }
    $payloadStill = Test-Path -LiteralPath (Join-Path $r $PAYLOAD_REL)
    Add-Result "payload-bloqueado" `
        ($res.ExitCode -ne 0 `
         -and $res.Output.Contains("Corporate context erase failed.") `
         -and $res.Output.Contains("- .specify/memory/.grm-pbi-payload.json removed: failed") `
         -and $res.Output.Contains("- .specify/memory/.grm-pbi-payload.json absent: no") `
         -and $res.Output.Contains("Retrieval payload could not be removed") `
         -and $res.Output.Contains("- .specify/memory/.grm-pbi-sections/ removed: done") `
         -and $res.Output.Contains("reset=failed") `
         -and (-not $res.Output.Contains("reset=ok")) `
         -and $payloadStill) $res.Output
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
