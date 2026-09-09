#Requires -Version 5.1
<#
    Get-ActivePbiLayout.ps1

    Descompone active-pbi.md por seccion, siguiendo el mismo layout que
    Assert-ActivePbi.ps1 usa para verificar (OBS-P25-03).

    Por que existe: un barrido ingenuo de '^## ' sobre el ensamblado mezcla
    encabezados canonicos del layout con encabezados propios del contenido
    original, porque 'Original PBI Content (Verbatim)' incluye el fichero de
    origen completo y '<extra>' se copia en crudo con sus propios '## '. Sobre
    los dos PBI de muestra del repositorio eso da 23 encabezados en uno y 13
    en otro, una diferencia que no describe ningun defecto: describe cuantos
    encabezados propios trae cada PBI de origen. Assert-ActivePbi.ps1 ya
    particiona esto correctamente para detectar una divergencia; esta
    herramienta hace la misma particion visible para diagnosticarla.

    D-P26-06 (opcion B): el layout no se declara aqui por segunda vez. Se
    extrae del AST de Assert-ActivePbi.ps1, leyendo el hashtable ordenado
    asignado a $MAP. Una tercera declaracion propia envejeceria en silencio
    en cuanto una seccion se anadiera o renombrara alli (L-17). El acoplamiento
    es al nombre de la variable $MAP en ese fichero: si se renombra, esta
    herramienta debe fallar de forma ruidosa, nunca devolver una lista vacia
    sin avisar (L-18, contraparte del riesgo aceptado en D-P26-06).

    Que hace, para cada seccion del layout, en el orden declarado:
      - si el fragmento existe: lineas, bytes (D-P26-07 opcion B) y hash
        normalizado (CRLF->LF, TrimEnd de saltos finales, SHA-256) del
        contenido tal como Assert-ActivePbi.ps1 lo comparia (con Notes
        fusionando notes.md y extra_sections.md, igual que el propio $MAP)
      - si el fragmento esta ausente y la seccion es opcional: 'omitida'
      - si el fragmento esta ausente y la seccion es obligatoria: 'AUSENTE'
        (esto es informativo; no sustituye a Assert-ActivePbi.ps1, que es
        quien falla la unidad de trabajo)

    Exit codes: 0 informe emitido, 1 no se pudo extraer el layout o faltan
    entradas de fichero.

    Uso:
      powershell -NoProfile -ExecutionPolicy Bypass -File resources\tools\Get-ActivePbiLayout.ps1 -SectionsPath ".specify/memory/.grm-pbi-sections"
#>

param(
    [string]$SectionsPath = ".specify/memory/.grm-pbi-sections",

    [string]$AssertScriptPath = (Join-Path $PSScriptRoot "..\..\extensions\grm-corporate-workflow\skills\_shared\scripts\Assert-ActivePbi.ps1")
)

$ErrorActionPreference = "Stop"

function Stop-Layout {
    param([string]$Message)
    [Console]::Error.WriteLine($Message)
    Write-Output "layout=failed"
    exit 1
}

if (-not (Test-Path $AssertScriptPath)) {
    Stop-Layout "Assert-ActivePbi.ps1 not found at $AssertScriptPath. Cannot extract layout."
}
if (-not (Test-Path $SectionsPath)) {
    Stop-Layout "Section fragments not found at $SectionsPath. Run the load chain first."
}

# ---------------------------------------------------------------------------
# Extraccion del layout desde el AST de Assert-ActivePbi.ps1 (D-P26-06 B).
# Se busca la asignacion '$MAP = [ordered]@{ ... }' y se recorren sus
# entradas en el orden textual en que aparecen, que es el orden del layout
# (el propio Assert-ActivePbi.ps1 depende de esa propiedad de [ordered]).
# ---------------------------------------------------------------------------

$abs = (Resolve-Path $AssertScriptPath).Path
$tokens = $null
$parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($abs, [ref]$tokens, [ref]$parseErrors)

if ($parseErrors -and $parseErrors.Count -gt 0) {
    Stop-Layout "Assert-ActivePbi.ps1 did not parse cleanly; cannot trust the extracted layout."
}

$mapAssignment = $ast.Find({
    param($node)
    $node -is [System.Management.Automation.Language.AssignmentStatementAst] -and
    $node.Left -is [System.Management.Automation.Language.VariableExpressionAst] -and
    $node.Left.VariablePath.UserPath -eq 'MAP'
}, $true)

if (-not $mapAssignment) {
    Stop-Layout "Could not find a `$MAP assignment in Assert-ActivePbi.ps1. The layout extraction depends on that exact variable name (D-P26-06); it may have been renamed."
}

$hashAst = $mapAssignment.Right.Find({
    param($node) $node -is [System.Management.Automation.Language.HashtableAst]
}, $true)

if (-not $hashAst -or $hashAst.KeyValuePairs.Count -eq 0) {
    Stop-Layout "`$MAP was found but produced zero entries. Refusing to report an empty layout as if it were valid (L-18)."
}

$layout = [ordered]@{}
foreach ($pair in $hashAst.KeyValuePairs) {
    $headingName = $pair.Item1.SafeGetValue()
    $entryHash = $pair.Item2.SafeGetValue()

    $files = @()
    if ($entryHash -is [hashtable] -and $entryHash.ContainsKey('files')) {
        $files = @($entryHash['files'])
    }
    $optional = ($entryHash -is [hashtable]) -and $entryHash.ContainsKey('optional') -and $entryHash['optional']

    $layout[$headingName] = @{ files = $files; optional = $optional }
}

if ($layout.Count -eq 0) {
    Stop-Layout "Layout extraction produced zero headings. Refusing to report an empty layout as if it were valid (L-18)."
}

# ---------------------------------------------------------------------------
# Medicion por seccion.
# ---------------------------------------------------------------------------

function Get-ComparableLines {
    param([string]$Text)
    if ($null -eq $Text) { return ,@() }
    $lines = @($Text -split "`r?`n" | ForEach-Object { $_.TrimEnd() })
    $start = 0
    while ($start -lt $lines.Count -and $lines[$start] -eq '') { $start++ }
    $end = $lines.Count - 1
    while ($end -ge $start -and $lines[$end] -eq '') { $end-- }
    if ($end -lt $start) { return ,@() }
    return ,@($lines[$start..$end])
}

function Get-NormalizedHash {
    param([string]$Text)
    $joined = ($Text -split "`n" | ForEach-Object { $_ }) -join "`n"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($joined)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $hashBytes = $sha.ComputeHash($bytes)
    return (($hashBytes | ForEach-Object { $_.ToString("X2") }) -join ""), $bytes.Length
}

$rows = [System.Collections.Generic.List[string]]::new()
$missingMandatory = 0

foreach ($heading in $layout.Keys) {

    $spec = $layout[$heading]
    $parts = [System.Collections.Generic.List[string]]::new()
    $anyFound = $false
    $anyMissing = $false

    foreach ($file in $spec.files) {
        $fragmentPath = Join-Path $SectionsPath $file
        if (Test-Path $fragmentPath) {
            $anyFound = $true
            $fabs = (Resolve-Path $fragmentPath).Path
            $parts.Add(([System.IO.File]::ReadAllText($fabs, [System.Text.Encoding]::UTF8)).TrimEnd()) | Out-Null
        }
        else {
            $anyMissing = $true
        }
    }

    if (-not $anyFound) {
        if ($spec.optional) {
            $rows.Add(("{0,-34} omitida (seccion opcional sin fragmento correspondiente)" -f $heading)) | Out-Null
        }
        else {
            $rows.Add(("{0,-34} AUSENTE (fragmento obligatorio no encontrado)" -f $heading)) | Out-Null
            $missingMandatory++
        }
        continue
    }

    $joined = ($parts.ToArray()) -join "`n`n"
    $comparable = (Get-ComparableLines $joined) -join "`n"
    $hash, $byteLength = Get-NormalizedHash $comparable
    $lineCount = if ($comparable -eq '') { 0 } else { (Get-ComparableLines $joined).Count }

    $flag = if ($anyMissing) { " [fragmento parcial: falta uno de {0}]" -f ($spec.files -join ', ') } else { "" }

    $rows.Add(("{0,-34} lineas={1,-5} bytes={2,-6} hash={3}{4}" -f $heading, $lineCount, $byteLength, $hash, $flag)) | Out-Null
}

Write-Output ("layout=ok headings={0} source={1}" -f $layout.Count, $AssertScriptPath)
Write-Output ""
foreach ($r in $rows) { Write-Output $r }

if ($missingMandatory -gt 0) {
    Write-Output ""
    Write-Output ("{0} seccion(es) obligatoria(s) sin fragmento. Esto no es una verificacion de fidelidad: para eso esta Assert-ActivePbi.ps1." -f $missingMandatory)
}

exit 0
