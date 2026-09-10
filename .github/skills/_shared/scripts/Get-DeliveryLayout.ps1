#Requires -Version 5.1
<#
    Get-DeliveryLayout.ps1

    D-E2E-04: el flujo dejaba codigo entregable dentro de features/,
    mezclado con la documentacion de proceso SDD. La regla existia ya en
    la constitucion (OBS-P32-01) y se cumplio en una ejecucion y no en la
    siguiente: una regla en prosa no gobierna el comportamiento (L-02).
    Este script produce la garantia ejecutando codigo.

    Un unico script con dos consumidores (D-P32-10: a): corp.plan lo
    invoca para conocer el estado del producto antes de planificar, y
    corp.doc lo invoca como puerta antes de generar el delivery-doc. El
    veredicto no depende de quien llama; la salida es siempre la misma y
    cada agente decide que hace con ella. Un solo script evita que la
    lista de extensiones y el criterio de delivery-doc queden escritos
    dos veces y envejezcan por separado (L-17, L-28).

    OBS-P32-02: code-roots-detected se retiro tras la verificacion. En un
    runtime consumidor el instalador despliega extensions/, presets/ y
    resources/, que la heuristica contaba como codigo de producto,
    mientras el codigo real bajo features/ no aparecia. La clave decia lo
    contrario de la verdad (L-03). La existencia de producto previo la
    responde delivered-pbis, que no depende de heuristica.

    Alcance de la garantia (D-P32-11: a): solo se verifica el invariante
    -bajo features/ no hay ficheros de codigo-. La raiz de codigo se
    observa y se reporta, pero NO se exige: la constitucion es prosa
    libre y extraer de ella la raiz obligaria a interpretar texto, con lo
    que el fallo pasaria a ser silencioso (L-03). La raiz queda
    gobernada por declaracion en spec.md.

    Tres estados (D-P32-12: b2): ok, failed y error. "No pude recorrer el
    arbol" no es lo mismo que "hay codigo mal colocado"; el consumidor se
    detiene en ambos casos pero el mensaje al operador difiere.

    La rama de fallo emite el inventario completo, no solo el error: lo
    que hace falta en ese momento es saber que ficheros mover (L-03).

    features/ ausente no es fallo: corp.plan corre antes de que exista.

    Extensiones permitidas bajo features/ (D-P32-09: b2): .md mas
    imagenes, porque la evidencia de validacion puede incluir capturas.
    Un fichero sin extension NO esta permitido.

    Ruta fija, sin parametro, misma razon que
    Assert-CorporateConstitution.ps1 (D-P29-09): el agente que lo invoca
    nombra esa ruta en su propio texto, y un parametro dejaria que la
    ruta comprobada y la reportada divergieran.

    El bloque de salida de abajo es autoritativo: los agentes que
    invocan este script citan sus claves literalmente.

    Exit codes: 0 layout=ok, 1 layout=failed, 2 layout=error.

    Usage:
      powershell -NoProfile -ExecutionPolicy Bypass -File .github\skills\_shared\scripts\Get-DeliveryLayout.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$FEATURES = 'features'

# Extensiones admitidas bajo features/. Comparacion en minusculas.
$ALLOWED = @('.md', '.png', '.jpg', '.jpeg', '.gif', '.webp')

function Write-Fatal {
    param([string]$Message)
    [Console]::Error.WriteLine($Message)
    Write-Output 'Delivery layout NOT inventoried.'
    Write-Output ("Reason: {0}" -f $Message)
    Write-Output 'layout=error'
    exit 2
}

$featuresPresent   = $false
$featuresFiles     = @()
$disallowed        = @()
$srcPresent        = $false
$srcSubdirectories = @()
$deliveredPbis     = @()

try {
    $featuresPresent = Test-Path -LiteralPath $FEATURES -PathType Container

    if ($featuresPresent) {
        $featuresFiles = @(Get-ChildItem -LiteralPath $FEATURES -Recurse -File -Force)

        foreach ($file in $featuresFiles) {
            $ext = $file.Extension
            if ([string]::IsNullOrEmpty($ext) -or ($ALLOWED -notcontains $ext.ToLowerInvariant())) {
                $relative = $file.FullName.Substring((Get-Item -LiteralPath '.').FullName.Length).TrimStart('\', '/')
                $disallowed += ($relative -replace '\\', '/')
            }
        }

        # delivery-doc: nombre impuesto por corp.doc, <PBI-ID>-delivery-doc.md
        foreach ($file in $featuresFiles) {
            if ($file.Name -match '^(.+)-delivery-doc\.md$') {
                $deliveredPbis += $Matches[1]
            }
        }
    }

    $srcPresent = Test-Path -LiteralPath 'src' -PathType Container
    if ($srcPresent) {
        $srcSubdirectories = @(Get-ChildItem -LiteralPath 'src' -Directory -Force | ForEach-Object { $_.Name })
    }
}
catch {
    Write-Fatal "Delivery layout could not be inventoried: $_"
}

$disallowed        = @($disallowed | Sort-Object -Unique)
$deliveredPbis     = @($deliveredPbis | Sort-Object -Unique)
$srcSubdirectories = @($srcSubdirectories | Sort-Object -Unique)

function Format-List {
    param([string[]]$Items)
    if ($Items.Count -gt 0) { return ($Items -join ', ') }
    return 'none'
}

Write-Output 'Delivery layout inventory.'
Write-Output '---'
Write-Output ("features-root-present: {0}" -f $(if ($featuresPresent) { 'yes' } else { 'no' }))
Write-Output ("features-files-total: {0}" -f $featuresFiles.Count)
Write-Output ("features-files-disallowed: {0}" -f $disallowed.Count)
Write-Output ("src-present: {0}" -f $(if ($srcPresent) { 'yes' } else { 'no' }))
Write-Output ("src-subdirectories: {0}" -f (Format-List -Items $srcSubdirectories))
Write-Output ("delivered-pbis: {0}" -f (Format-List -Items $deliveredPbis))
Write-Output '---'

if ($disallowed.Count -gt 0) {
    Write-Output 'Disallowed files under features/:'
    foreach ($item in $disallowed) {
        Write-Output ("- {0}" -f $item)
    }
}

Write-Output 'Verification:'
Write-Output ("- allowed extensions under features/: {0}" -f ($ALLOWED -join ', '))
Write-Output ("- features/ scanned: {0}" -f $(if ($featuresPresent) { 'yes' } else { 'no' }))

if ($disallowed.Count -gt 0) {
    Write-Output 'layout=failed'
    exit 1
}

Write-Output 'layout=ok'
exit 0
