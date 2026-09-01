#Requires -Version 5.1
<#
    Sync-GrmSkills.ps1  (v4 - espejo verificado del subarbol de skills)

    Puente temporal de desarrollo: replica el subarbol de skills desde la
    Source of Truth (el clon del repositorio de la personalizacion) al
    runtime de pruebas (una instalacion de Spec Kit desechable), emulando
    la funcion Install-CorporateSkills que se implementara en P2.

    Este script NO es el instalador. Existe para cerrar el bucle de
    validacion mientras el instalador aun no despliega skills. Su
    comportamiento observado es la especificacion de P2.

    Cambio de v2 a v3 (D-P16b-05, opcion a): antes se hacia un robocopy
    /MIR por cada skill declarada en extension.yml, de modo que una
    carpeta del subarbol que no fuera una skill declarada no se copiaba
    nunca. Eso dejo el runtime sin skills\_shared\scripts, con los dos
    SKILL.md invocando scripts inexistentes. Ahora se espeja el subarbol
    completo con una sola invocacion.

    Cambio de v3 a v4 (P2b): hasta v3 el resultado no se comprobaba. Se
    imprimia una linea OK por skill declarada con independencia de lo que
    hubiera ocurrido, derivada de la plantilla y no del resultado. El
    unico control era el codigo de salida de robocopy. Ahora el subarbol
    origen y el destino se comparan fichero a fichero por huella SHA-256
    despues de copiar, y las lineas OK se emiten a partir de esa
    comparacion. Una discrepancia aborta.

    La validacion del manifiesto se conserva intacta como puerta previa:
    toda skill declarada debe existir con su SKILL.md antes de copiar
    nada. Lo que cambia es que ya no es tambien la lista de lo que se
    copia. Las dos cosas eran distintas y estaban confundidas.

    Alcance de purga: /MIR sobre el subarbol borra en destino todo lo que
    no exista en origen, incluidas carpetas enteras. El destino pasa a ser
    un espejo exacto de skills\, no un union de skills declaradas. Es mas
    agresivo que v2 y es deliberado: una skill retirada del origen debe
    desaparecer del runtime.

    Alcance no cubierto: agents\ y prompts\ quedan fuera. Sus cambios no
    llegan al runtime por esta via y hay que propagarlos a mano.

    Uso:
      powershell -NoProfile -ExecutionPolicy Bypass -File .\Sync-GrmSkills.ps1 `
          -SourceRoot C:\dev\proys\grm-custom-spec-kit `
          -TargetRoot C:\dev\proys\grm-custom-spec-kit-20260824

      Listado de lo que se desplegaria, sin copiar nada:

      powershell -NoProfile -ExecutionPolicy Bypass -File .\Sync-GrmSkills.ps1 `
          -SourceRoot C:\dev\proys\grm-custom-spec-kit `
          -TargetRoot C:\dev\proys\grm-custom-spec-kit-20260824 -WhatIfList

      -TargetRoot es opcional en la firma y necesario en la practica. Su
      valor por defecto es el directorio actual, de modo que omitirlo
      estando dentro de la Source of Truth hace abortar la salvaguarda.
#>

[CmdletBinding()]
param(
    # Clon del repositorio de la personalizacion. Source of Truth.
    [Parameter(Mandatory = $true)]
    [string]$SourceRoot,

    # Instalacion de Spec Kit sobre la que se prueba. Desechable.
    [string]$TargetRoot = (Get-Location).Path,

    [string]$SkillsRuntimeDir = ".github/skills",

    # Enumera lo que se desplegaria, sin copiar nada.
    [switch]$WhatIfList
)

$ErrorActionPreference = "Stop"

# --- Salvaguarda: origen y destino no pueden solaparse ----------------------
# /MIR borra en destino todo lo que no exista en origen. Comprobar solo la
# igualdad de rutas dejaba pasar el anidamiento en cualquiera de los dos
# sentidos, que es el caso en el que la purga alcanza a la Source of Truth.
$srcFull = (Resolve-Path -Path $SourceRoot).Path.TrimEnd('\')
$tgtFull = (Resolve-Path -Path $TargetRoot).Path.TrimEnd('\')

$srcPrefix = $srcFull + '\'
$tgtPrefix = $tgtFull + '\'
$ic        = [System.StringComparison]::OrdinalIgnoreCase

if ($srcFull -eq $tgtFull) {
    throw "SourceRoot y TargetRoot apuntan al mismo directorio ($srcFull). " +
          "La Source of Truth y el runtime de pruebas deben estar separados."
}
if ($tgtPrefix.StartsWith($srcPrefix, $ic)) {
    throw "TargetRoot ($tgtFull) esta dentro de SourceRoot ($srcFull). " +
          "La purga de /MIR alcanzaria a la Source of Truth."
}
if ($srcPrefix.StartsWith($tgtPrefix, $ic)) {
    throw "SourceRoot ($srcFull) esta dentro de TargetRoot ($tgtFull). " +
          "Los dos arboles deben estar separados."
}

$extYml    = Join-Path $srcFull "extensions\grm-corporate-workflow\extension.yml"
$sotSkills = Join-Path $srcFull "extensions\grm-corporate-workflow\skills"
$runtime   = Join-Path $tgtFull $SkillsRuntimeDir

if (-not (Test-Path $extYml)) {
    throw "extension.yml no encontrado en la Source of Truth: $extYml"
}
if (-not (Test-Path $sotSkills)) {
    throw "Subarbol de skills no encontrado en la Source of Truth: $sotSkills"
}

Write-Host "Source of Truth : $srcFull" -ForegroundColor DarkGray
Write-Host "Runtime destino : $tgtFull" -ForegroundColor DarkGray

# --- Lectura del manifiesto -------------------------------------------------
# Port reducido de Read-YamlStringList (bootstrap-grm-e2e.ps1, L142).
# En P2 se usara la funcion real del instalador, no esta copia.
function Read-SkillList {
    param([string]$Path)

    $result    = [System.Collections.Generic.List[string]]::new()
    $inTop     = $false
    $topIndent = -1

    foreach ($raw in (Get-Content -Path $Path)) {
        $line = $raw -replace "`t", '    '
        if ($line -match '^\s*#') { continue }
        if ([string]::IsNullOrWhiteSpace($line)) { continue }

        $indent  = ($line -replace '^(\s*).*$', '$1').Length
        $trimmed = $line.Trim()

        if (-not $inTop) {
            if ($trimmed -match '^skills:') { $inTop = $true; $topIndent = $indent }
            continue
        }
        if ($indent -le $topIndent -and $trimmed -notmatch '^-') { break }
        if ($trimmed -match '^-\s*(.+)$') {
            $item = $Matches[1].Trim()
            $item = ($item -replace '\s+#.*$', '').Trim().Trim('"').Trim("'")
            if ($item) { $result.Add($item) | Out-Null }
        }
    }
    return $result.ToArray()
}

# --- Huella de un subarbol --------------------------------------------------
# Ruta relativa -> SHA-256 del contenido. La tabla hash de PowerShell compara
# claves sin distinguir mayusculas, que es la semantica correcta para rutas
# de Windows. Se compara el byte, no el texto normalizado: robocopy copia
# bytes y cualquier diferencia es un fallo de copia, no una variante de
# terminadores de linea.
function Get-SubtreeSnapshot {
    param([string]$Root)

    $snapshot = @{}
    $prefix   = (Resolve-Path -Path $Root).Path.TrimEnd('\') + '\'

    foreach ($file in (Get-ChildItem -Path $Root -Recurse -File -Force)) {
        $relative = $file.FullName.Substring($prefix.Length)
        $snapshot[$relative] = (Get-FileHash -Path $file.FullName -Algorithm SHA256).Hash
    }
    return $snapshot
}

$skills = Read-SkillList -Path $extYml
Write-Host "Skills declaradas en el manifiesto: $($skills.Count)" -ForegroundColor Cyan

if ($skills.Count -eq 0) {
    Write-Host "Nada que sincronizar." -ForegroundColor Yellow
    return
}

# --- Comprobacion previa: toda skill declarada existe en la SoT -------------
# Semantica de fallo duro, coherente con Copy-ManifestFile y con CA-01.
# Se verifica el conjunto completo ANTES de copiar nada, para no dejar el
# runtime a medio desplegar.
#
# Es una puerta, no un inventario. Lo declarado debe existir; lo existente no
# tiene por que estar declarado. skills\_shared no es una skill, no se declara
# y no lleva SKILL.md, y aun asi se despliega porque forma parte del subarbol.
$missing = [System.Collections.Generic.List[string]]::new()
foreach ($skill in $skills) {
    $from = Join-Path $sotSkills $skill
    if (-not (Test-Path $from)) { $missing.Add($skill) | Out-Null }
    if (-not (Test-Path (Join-Path $from "SKILL.md"))) {
        if (-not $missing.Contains($skill)) { $missing.Add("$skill (sin SKILL.md)") | Out-Null }
    }
}
if ($missing.Count -gt 0) {
    throw "Skills declaradas en el manifiesto pero ausentes o incompletas en la " +
          "Source of Truth: $($missing -join ', '). No se ha copiado nada."
}

# --- Inventario del subarbol ------------------------------------------------
# Solo informativo: lo que se copia es el subarbol entero, no esta lista.
$folders = @(Get-ChildItem -Path $sotSkills -Directory -Force |
             Select-Object -ExpandProperty Name)
$shared  = @($folders | Where-Object { $skills -notcontains $_ })

if ($WhatIfList) {
    Write-Host ""
    Write-Host ("  {0}  ->  {1}" -f $sotSkills, $runtime)
    Write-Host ""
    foreach ($skill in $skills) { Write-Host ("    skill      {0}" -f $skill) }
    foreach ($f in $shared)     { Write-Host ("    compartida {0}" -f $f) }
    Write-Host ""
    Write-Host "Modo listado. No se ha copiado nada." -ForegroundColor Yellow
    return
}

# --- Sincronizacion ---------------------------------------------------------
if (-not (Test-Path $runtime)) {
    New-Item -ItemType Directory -Path $runtime -Force | Out-Null
}

# Una sola invocacion. /MIR espeja el subarbol completo (skills declaradas,
# carpetas compartidas, references\, scripts\, assets\) y elimina en destino
# todo lo que ya no exista en origen.
$null = robocopy $sotSkills $runtime /MIR /NFL /NDL /NJH /NJS /NP
if ($LASTEXITCODE -ge 8) {
    throw "robocopy fallo con codigo $LASTEXITCODE al espejar '$sotSkills'"
}

# --- Verificacion del resultado ---------------------------------------------
# El codigo de salida de robocopy dice si la herramienta fallo, no si el
# destino quedo igual que el origen. Se compara el conjunto de ficheros y su
# contenido. Las lineas OK de mas abajo se emiten a partir de esta
# comparacion; hasta v3 se imprimian sin comprobar nada.
$sourceSnapshot = Get-SubtreeSnapshot -Root $sotSkills
$targetSnapshot = Get-SubtreeSnapshot -Root $runtime

$absent  = @($sourceSnapshot.Keys | Where-Object { -not $targetSnapshot.ContainsKey($_) } | Sort-Object)
$extra   = @($targetSnapshot.Keys | Where-Object { -not $sourceSnapshot.ContainsKey($_) } | Sort-Object)
$differ  = @($sourceSnapshot.Keys |
             Where-Object { $targetSnapshot.ContainsKey($_) -and
                            $targetSnapshot[$_] -ne $sourceSnapshot[$_] } | Sort-Object)

if ($absent.Count -gt 0 -or $extra.Count -gt 0 -or $differ.Count -gt 0) {
    $detail = [System.Collections.Generic.List[string]]::new()
    foreach ($f in $absent) { $detail.Add("ausente en destino: $f") | Out-Null }
    foreach ($f in $extra)  { $detail.Add("sobra en destino  : $f") | Out-Null }
    foreach ($f in $differ) { $detail.Add("contenido distinto: $f") | Out-Null }
    throw "El destino no es un espejo del origen despues de copiar. " +
          "$($absent.Count) ausente(s), $($extra.Count) sobrante(s), " +
          "$($differ.Count) con contenido distinto:`n  " + ($detail -join "`n  ")
}

$discrepancies = $absent.Count + $extra.Count + $differ.Count

Write-Host ""
Write-Host ("Verificados {0} fichero(s) por SHA-256, {1} discrepancia(s)." -f `
            $sourceSnapshot.Count, $discrepancies) -ForegroundColor Cyan

foreach ($folder in $folders) {
    $count = @($sourceSnapshot.Keys |
               Where-Object { $_.StartsWith($folder + '\', $ic) }).Count
    $kind  = if ($skills -contains $folder) { "skill      " } else { "compartida " }
    Write-Host ("  OK  {0} {1}  ({2} fichero(s) verificado(s))" -f `
                $kind, $folder, $count) -ForegroundColor Green
}

# El gotcha del manifiesto, medido en PowerShell 5.1.26100.8875:
#   una List<string> vacia evalua como falsy, porque PowerShell convierte a
#   booleano las colecciones por su recuento;
#   $null -ne sobre una lista recien construida es siempre cierto, porque la
#   lista existe aunque no tenga elementos.
# Las dos cosas son ciertas y ninguna sirve aqui: lo que hay que distinguir es
# cero carpetas de varias, no lista nula de lista vacia. Por eso se comprueba
# el recuento. El plan seccion 7, P2, advierte de lo primero y sigue vigente.
if ($folders.Count -gt 0) {
    Write-Host ""
    Write-Host ("Desplegadas {0} carpeta(s) en {1}: {2} skill(s), {3} compartida(s)" -f `
                $folders.Count, $runtime, $skills.Count, $shared.Count) -ForegroundColor Cyan
}
else {
    Write-Host ""
    Write-Host "El subarbol de skills de la Source of Truth esta vacio." -ForegroundColor Yellow
}

$global:LASTEXITCODE = 0
