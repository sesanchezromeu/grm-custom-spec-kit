#Requires -Version 5.1
<#
    Test-ActivePbiLayout.ps1

    Arnes de pruebas para Get-ActivePbiLayout.ps1 (P26b, OBS-P25-03).
    Versionado en resources/tools/ por el mismo motivo que los otros tres
    arneses: herramienta de mantenedor, no artefacto desplegable.

    Cobertura:
      1. positiva-poc01           camino real, Read-PbiMarkdown.ps1 +
                                   Build-ActivePbi.ps1 sobre
                                   samples/PBI-POC-01-calculadora-iva.md
                                   (8 encabezados '## ' propios en el
                                   verbatim). El layout no debe confundirlos
                                   con encabezados canonicos: exactamente 13
                                   filas en el informe, ninguna con
                                   'AUSENTE' salvo la opcional esperada.
      2. positiva-poc02           mismo camino real sobre
                                   samples/PBI-POC-02-conversion-moneda.md
                                   (1 encabezado propio). Misma comprobacion:
                                   13 filas, la diferencia de encabezados
                                   propios entre los dos PBI no debe alterar
                                   el numero de secciones del layout.

                                   Anadido en P27 (OBS-P25-02, opcion B): los
                                   dos escenarios anteriores leen ademas el
                                   fragmento source.md directamente y exigen
                                   que ya no contenga 'Changed at' ni
                                   'Loaded at', y que haya quedado en 8
                                   lineas, no 10. Es el fragmento que
                                   Read-PbiMarkdown.ps1 escribe; la
                                   comprobacion apunta al mismo fichero que
                                   la unidad modifico, no al informe agregado
                                   del layout (L-20).
      3. map-renombrado            copia de Assert-ActivePbi.ps1 con $MAP
                                   renombrado a $SECTIONS. La herramienta
                                   debe fallar de forma ruidosa
                                   (D-P26-06, contraparte de L-18), nunca
                                   devolver un informe vacio con exit 0.
      4. map-vacio                 copia de Assert-ActivePbi.ps1 con $MAP
                                   asignado a un hashtable ordenado vacio.
                                   Misma exigencia: fallo ruidoso, no un
                                   informe de cero secciones como si fuera
                                   valido.
      5. seccion-opcional-ausente  fragmentos sin 'source_work_item_state.md'.
                                   Debe reportar 'omitida', exit 0, sin
                                   contarla como fallo.
      6. seccion-obligatoria-ausente  fragmentos sin 'description.md'.
                                   Debe reportar 'AUSENTE' y advertir en la
                                   cola, pero sigue siendo exit 0: esta
                                   herramienta es diagnostico, no
                                   verificacion (esa es Assert-ActivePbi.ps1).

    Uso:
      powershell -NoProfile -ExecutionPolicy Bypass -File resources\tools\Test-ActivePbiLayout.ps1

    Salida: una linea PASS o FAIL por escenario, y "TEST HARNESS: OK" o
    "TEST HARNESS: FAILED (n)" al final. Codigo de salida 0 si todo pasa,
    1 en caso contrario.
#>

param(
    [string]$LayoutScriptPath = (Join-Path $PSScriptRoot "Get-ActivePbiLayout.ps1"),
    [string]$AssertScriptPath = (Join-Path $PSScriptRoot "..\..\extensions\grm-corporate-workflow\skills\_shared\scripts\Assert-ActivePbi.ps1"),
    [string]$ReadMarkdownScriptPath = (Join-Path $PSScriptRoot "..\..\extensions\grm-corporate-workflow\skills\grm-pbi-source-markdown\scripts\Read-PbiMarkdown.ps1"),
    [string]$BuildScriptPath = (Join-Path $PSScriptRoot "..\..\extensions\grm-corporate-workflow\skills\_shared\scripts\Build-ActivePbi.ps1"),
    [string]$SamplesPath = (Join-Path $PSScriptRoot "..\..\samples")
)

$results = [System.Collections.Generic.List[string]]::new()
$failCount = 0

function Add-Result {
    param([string]$Name, [bool]$Passed, [string]$Detail)
    $status = if ($Passed) { "PASS" } else { "FAIL" }
    if (-not $Passed) { $script:failCount++ }
    $script:results.Add(("{0}  {1}  ({2})" -f $status, $Name, $Detail)) | Out-Null
}

function New-Sandbox {
    $root = Join-Path ([System.IO.Path]::GetTempPath()) ("grm-layout-" + [System.Guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $root -Force -ErrorAction Stop | Out-Null
    return (Resolve-Path $root -ErrorAction Stop).ProviderPath
}

function Invoke-Real {
    param([string]$Sandbox, [string]$PbiFile)
    $sectionsPath = Join-Path $Sandbox ".specify/memory/.grm-pbi-sections"
    $activePbiPath = Join-Path $Sandbox ".specify/memory/active-pbi.md"
    $payloadPath = Join-Path $Sandbox ".specify/memory/.grm-pbi-payload.json"

    Push-Location $Sandbox
    try {
        & powershell -NoProfile -ExecutionPolicy Bypass -File $ReadMarkdownScriptPath `
            -Reference $PbiFile -PayloadPath $payloadPath -SectionsPath $sectionsPath | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "Read-PbiMarkdown.ps1 fallo con exit $LASTEXITCODE" }

        & powershell -NoProfile -ExecutionPolicy Bypass -File $BuildScriptPath `
            -SectionsPath $sectionsPath -ActivePbiPath $activePbiPath | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "Build-ActivePbi.ps1 fallo con exit $LASTEXITCODE" }
    }
    finally {
        Pop-Location
    }
    return $sectionsPath
}

# ---------------------------------------------------------------------------
# 1-2. Camino real sobre los dos PBI de muestra.
# ---------------------------------------------------------------------------

foreach ($case in @(
    @{ Name = "positiva-poc01"; File = "PBI-POC-01-calculadora-iva.md" },
    @{ Name = "positiva-poc02"; File = "PBI-POC-02-conversion-moneda.md" }
)) {
    $sandbox = New-Sandbox
    try {
        $pbiFile = (Resolve-Path (Join-Path $SamplesPath $case.File) -ErrorAction Stop).ProviderPath
        $sectionsPath = Invoke-Real -Sandbox $sandbox -PbiFile $pbiFile

        $output = & powershell -NoProfile -ExecutionPolicy Bypass -File $LayoutScriptPath `
            -SectionsPath $sectionsPath -AssertScriptPath $AssertScriptPath 2>&1
        $exit = $LASTEXITCODE
        $joined = ($output -join "`n")

        $headerLine = $output | Where-Object { $_ -match '^layout=ok headings=(\d+)' } | Select-Object -First 1
        $headingCount = if ($headerLine -and $headerLine -match 'headings=(\d+)') { [int]$Matches[1] } else { -1 }

        # P27, OBS-P25-02: leer el fragmento source.md directamente, no el
        # informe agregado del layout. El mecanismo que cambio es este
        # fichero (L-20).
        $sourceFragmentPath = Join-Path $sectionsPath "source.md"
        $sourceContent = [System.IO.File]::ReadAllText($sourceFragmentPath, [System.Text.Encoding]::UTF8)
        $sourceLineCount = @($sourceContent -split "`r?`n" | Where-Object { $_ -ne '' }).Count
        $noTimestamps = ($sourceContent -notmatch 'Changed at') -and ($sourceContent -notmatch 'Loaded at')
        $sourceLineOk = ($sourceLineCount -eq 8)

        $ok = ($exit -eq 0) -and ($headingCount -eq 13) -and ($joined -cnotmatch 'AUSENTE') -and ($joined -match 'omitida') -and $noTimestamps -and $sourceLineOk
        Add-Result $case.Name $ok ("exit={0} headings={1} source_lines={2} sin_timestamps={3}" -f $exit, $headingCount, $sourceLineCount, $noTimestamps)
    }
    catch {
        Add-Result $case.Name $false $_.Exception.Message
    }
    finally {
        Remove-Item -Path $sandbox -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# ---------------------------------------------------------------------------
# 3. $MAP renombrado: debe fallar de forma ruidosa, no vacia.
# ---------------------------------------------------------------------------

$sandbox = New-Sandbox
try {
    $tamperedAssert = Join-Path $sandbox "Assert-Tampered.ps1"
    $original = [System.IO.File]::ReadAllText((Resolve-Path $AssertScriptPath -ErrorAction Stop).Path, [System.Text.Encoding]::UTF8)
    $tampered = $original -replace '\$MAP\b', '$SECTIONS'
    if ($tampered -eq $original) { throw "la sustitucion de `$MAP no cambio nada; el fixture no prueba lo que dice probar" }
    [System.IO.File]::WriteAllText($tamperedAssert, $tampered, (New-Object System.Text.UTF8Encoding($false)))

    # Fragmentos minimos para que solo falle la extraccion, no la lectura.
    $sectionsPath = Join-Path $sandbox ".specify/memory/.grm-pbi-sections"
    New-Item -ItemType Directory -Path $sectionsPath -Force -ErrorAction Stop | Out-Null
    "x" | Out-File -FilePath (Join-Path $sectionsPath "source.md") -Encoding utf8 -NoNewline

    $output = & powershell -NoProfile -ExecutionPolicy Bypass -File $LayoutScriptPath `
        -SectionsPath $sectionsPath -AssertScriptPath $tamperedAssert 2>&1
    $exit = $LASTEXITCODE
    $joined = ($output -join "`n")

    $ok = ($exit -eq 1) -and ($joined -match 'layout=failed') -and ($joined -match "MAP")
    Add-Result "map-renombrado" $ok ("exit={0}" -f $exit)
}
catch {
    Add-Result "map-renombrado" $false $_.Exception.Message
}
finally {
    Remove-Item -Path $sandbox -Recurse -Force -ErrorAction SilentlyContinue
}

# ---------------------------------------------------------------------------
# 4. $MAP vacio: debe fallar de forma ruidosa, no informar cero secciones.
# ---------------------------------------------------------------------------

$sandbox = New-Sandbox
try {
    $tamperedAssert = Join-Path $sandbox "Assert-Empty.ps1"
    $original = [System.IO.File]::ReadAllText((Resolve-Path $AssertScriptPath -ErrorAction Stop).Path, [System.Text.Encoding]::UTF8)

    if ($original -notmatch '(?s)\$MAP\s*=\s*\[ordered\]@\{.*?\n\}') {
        throw "no se pudo localizar el bloque `$MAP = [ordered]@{ ... } para sustituirlo; el fixture no aplica"
    }
    $tampered = $original -replace '(?s)\$MAP\s*=\s*\[ordered\]@\{.*?\n\}', '$MAP = [ordered]@{}'
    [System.IO.File]::WriteAllText($tamperedAssert, $tampered, (New-Object System.Text.UTF8Encoding($false)))

    $sectionsPath = Join-Path $sandbox ".specify/memory/.grm-pbi-sections"
    New-Item -ItemType Directory -Path $sectionsPath -Force -ErrorAction Stop | Out-Null
    "x" | Out-File -FilePath (Join-Path $sectionsPath "source.md") -Encoding utf8 -NoNewline

    $output = & powershell -NoProfile -ExecutionPolicy Bypass -File $LayoutScriptPath `
        -SectionsPath $sectionsPath -AssertScriptPath $tamperedAssert 2>&1
    $exit = $LASTEXITCODE
    $joined = ($output -join "`n")

    $ok = ($exit -eq 1) -and ($joined -match 'layout=failed') -and ($joined -match 'zero entries')
    Add-Result "map-vacio" $ok ("exit={0}" -f $exit)
}
catch {
    Add-Result "map-vacio" $false $_.Exception.Message
}
finally {
    Remove-Item -Path $sandbox -Recurse -Force -ErrorAction SilentlyContinue
}

# ---------------------------------------------------------------------------
# 5. Seccion opcional ausente: 'omitida', no fallo.
# ---------------------------------------------------------------------------

$sandbox = New-Sandbox
try {
    $pbiFile = (Resolve-Path (Join-Path $SamplesPath "PBI-POC-01-calculadora-iva.md") -ErrorAction Stop).ProviderPath
    $sectionsPath = Invoke-Real -Sandbox $sandbox -PbiFile $pbiFile
    # source_work_item_state.md nunca lo escribe Read-PbiMarkdown.ps1 (D-P16b-02):
    # ya deberia estar ausente sin tocar nada.
    $swiPath = Join-Path $sectionsPath "source_work_item_state.md"
    if (Test-Path $swiPath) { Remove-Item $swiPath -Force }

    $output = & powershell -NoProfile -ExecutionPolicy Bypass -File $LayoutScriptPath `
        -SectionsPath $sectionsPath -AssertScriptPath $AssertScriptPath 2>&1
    $exit = $LASTEXITCODE
    $joined = ($output -join "`n")

    $ok = ($exit -eq 0) -and ($joined -match 'Source work item state\s+omitida') -and ($joined -cnotmatch 'AUSENTE')
    Add-Result "seccion-opcional-ausente" $ok ("exit={0}" -f $exit)
}
catch {
    Add-Result "seccion-opcional-ausente" $false $_.Exception.Message
}
finally {
    Remove-Item -Path $sandbox -Recurse -Force -ErrorAction SilentlyContinue
}

# ---------------------------------------------------------------------------
# 6. Seccion obligatoria ausente: 'AUSENTE' y aviso, pero exit 0 (diagnostico).
# ---------------------------------------------------------------------------

$sandbox = New-Sandbox
try {
    $pbiFile = (Resolve-Path (Join-Path $SamplesPath "PBI-POC-01-calculadora-iva.md") -ErrorAction Stop).ProviderPath
    $sectionsPath = Invoke-Real -Sandbox $sandbox -PbiFile $pbiFile
    Remove-Item (Join-Path $sectionsPath "description.md") -Force -ErrorAction Stop

    $output = & powershell -NoProfile -ExecutionPolicy Bypass -File $LayoutScriptPath `
        -SectionsPath $sectionsPath -AssertScriptPath $AssertScriptPath 2>&1
    $exit = $LASTEXITCODE
    $joined = ($output -join "`n")

    $ok = ($exit -eq 0) -and ($joined -cmatch 'Description\s+AUSENTE') -and ($joined -match '1 seccion')
    Add-Result "seccion-obligatoria-ausente" $ok ("exit={0}" -f $exit)
}
catch {
    Add-Result "seccion-obligatoria-ausente" $false $_.Exception.Message
}
finally {
    Remove-Item -Path $sandbox -Recurse -Force -ErrorAction SilentlyContinue
}

# ---------------------------------------------------------------------------

foreach ($r in $results) { Write-Output $r }

if ($failCount -gt 0) {
    Write-Output ("TEST HARNESS: FAILED ({0})" -f $failCount)
    exit 1
}
Write-Output ("TEST HARNESS: OK ({0} escenarios)" -f $results.Count)
exit 0
