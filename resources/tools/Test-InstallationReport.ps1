#Requires -Version 5.1
<#
    Test-InstallationReport.ps1

    Arnes de pruebas para las funciones que alimentan el informe de
    instalacion (P5, D-P21-06b). Versionado en resources/tools/ por el
    mismo motivo que Test-SkillShape.ps1 (D-P20-06) y Sync-GrmSkills.ps1
    (D-P19-05): herramienta de mantenedor, no artefacto desplegable.

    Extrae las funciones bajo prueba del AST de
    resources/bootstrap/bootstrap-grm-e2e.ps1 sin ejecutar el instalador
    completo. Esa es la unica via posible: el instalador clona desde
    GitHub en cada ejecucion y nunca lee la copia de trabajo local, de
    modo que ninguna condicion provocada en local llegaria a verse
    (L-15).

    Cobertura actual:
      P5a  Assert-DeployedSourcePrefix (OBS-P2a-01)

    Uso:
      powershell -NoProfile -ExecutionPolicy Bypass -File resources\tools\Test-InstallationReport.ps1

    Salida: una linea PASS o FAIL por escenario, y "TEST HARNESS: OK"
    o "TEST HARNESS: FAILED (n)" al final. Codigo de salida 0 si todo
    pasa, 1 en caso contrario.
#>

param(
    [string]$BootstrapPath = (Join-Path $PSScriptRoot "..\bootstrap\bootstrap-grm-e2e.ps1")
)

$ErrorActionPreference = "Stop"

# --- Extraccion de funciones desde el AST, sin ejecutar el instalador ---

$resolvedBootstrap = (Resolve-Path -LiteralPath $BootstrapPath).ProviderPath
$tokens = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($resolvedBootstrap, [ref]$tokens, [ref]$null)

$targetFunctions = @("Assert-DeployedSourcePrefix")
$found = @{}

foreach ($fn in $ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)) {
    if ($targetFunctions -contains $fn.Name) {
        $found[$fn.Name] = $fn.Extent.Text
    }
}

foreach ($name in $targetFunctions) {
    if (-not $found.ContainsKey($name)) {
        throw "No se encontro la funcion '$name' en $resolvedBootstrap. Extraccion abortada."
    }
}

# Definir las funciones extraidas en este ambito, tal cual, sin tocar
# una sola linea. Si el texto extraido no es valido PowerShell, este
# Invoke-Expression es el primer punto de fallo.
foreach ($name in $targetFunctions) {
    Invoke-Expression $found[$name]
}

# --- Utilidades del arnes ---

$script:Failures = 0
$script:ScenarioCount = 0

function New-DeployedList {
    # Construye la lista label|origen|destino tal como la fabrica
    # Copy-ManifestFile. No se toca el disco: la funcion bajo prueba
    # solo compara cadenas.
    param([string[]]$Entries)
    $list = [System.Collections.Generic.List[string]]::new()
    foreach ($e in $Entries) { $list.Add($e) | Out-Null }
    # La coma evita que PowerShell desenrolle la List al devolverla, que
    # convertiria una lista vacia en $null y una de un elemento en una
    # cadena suelta.
    return ,$list
}

function Invoke-Scenario {
    param(
        [string]$Name,
        [System.Collections.Generic.List[string]]$Deployed,
        [string]$SourceRepoPath,
        [string[]]$PreexistingMissing = @(),
        [int]$ExpectedNewCount,
        [string]$ExpectedSubstring = $null
    )
    $script:ScenarioCount++

    $missing = @()
    foreach ($m in $PreexistingMissing) { $missing += $m }
    $before = $missing.Count

    Assert-DeployedSourcePrefix -Deployed $Deployed -SourceRepoPath $SourceRepoPath -Missing ([ref]$missing)

    $added = @($missing | Select-Object -Skip $before)
    $ok = $true
    $reason = ""

    if ($added.Count -ne $ExpectedNewCount) {
        $ok = $false
        $reason = "se esperaban $ExpectedNewCount entradas nuevas en Missing y hubo $($added.Count): $($added -join '; ')"
    }
    if ($ok -and $missing.Count -lt $before) {
        $ok = $false
        $reason = "se perdieron entradas preexistentes de Missing"
    }
    if ($ok -and $before -gt 0) {
        for ($i = 0; $i -lt $before; $i++) {
            if ($missing[$i] -ne $PreexistingMissing[$i]) {
                $ok = $false
                $reason = "una entrada preexistente de Missing fue alterada en la posicion $i"
                break
            }
        }
    }
    if ($ok -and $ExpectedSubstring) {
        $hit = @($added | Where-Object { $_ -like "*$ExpectedSubstring*" })
        if ($hit.Count -eq 0) {
            $ok = $false
            $reason = "ninguna entrada nueva contiene '$ExpectedSubstring'. Entradas reales: $($added -join '; ')"
        }
    }

    if ($ok) {
        Write-Host "PASS  $Name  (Missing +$($added.Count))"
    } else {
        Write-Host "FAIL  $Name -- $reason"
        $script:Failures++
    }
}

# --- Escenarios ---

$long  = "C:\Users\sesanchez\AppData\Local\Temp\grm-custom-spec-kit-cache\source"
$short = "C:\Users\SESANC~1\AppData\Local\Temp\grm-custom-spec-kit-cache\source"

# 1. Camino feliz: las cuatro clases de entrada que alimenta
#    Copy-ManifestFile, todas bajo el mismo prefijo.
Invoke-Scenario -Name "homogenea-forma-larga" -SourceRepoPath $long -ExpectedNewCount 0 -Deployed (New-DeployedList @(
    "corp agent: corp.load|$long\extensions\grm-corporate-workflow\agents\corp.load.agent.md|C:\dev\e2e\.github\agents\corp.load.agent.md",
    "corp prompt: corp.load|$long\extensions\grm-corporate-workflow\prompts\corp.load.prompt.md|C:\dev\e2e\.github\prompts\corp.load.prompt.md",
    "preset override agent: speckit.plan.agent.md|$long\presets\grm-corporate-governance\agents\speckit.plan.agent.md|C:\dev\e2e\.github\agents\speckit.plan.agent.md",
    "corp skill file: grm-pbi-source-markdown\SKILL.md|$long\extensions\grm-corporate-workflow\skills\grm-pbi-source-markdown\SKILL.md|C:\dev\e2e\.github\skills\grm-pbi-source-markdown\SKILL.md"
))

# 2. Rama de fallo: exactamente el defecto de OBS-P2a-01. Una entrada
#    en forma corta 8.3 conviviendo con dos en forma larga. Debe caer
#    una sola, no las tres.
Invoke-Scenario -Name "forma-corta-8.3-mezclada" -SourceRepoPath $long -ExpectedNewCount 1 -ExpectedSubstring "source-prefix-mismatch" -Deployed (New-DeployedList @(
    "corp agent: corp.load|$long\extensions\grm-corporate-workflow\agents\corp.load.agent.md|C:\dev\e2e\.github\agents\corp.load.agent.md",
    "corp prompt: corp.load|$short\extensions\grm-corporate-workflow\prompts\corp.load.prompt.md|C:\dev\e2e\.github\prompts\corp.load.prompt.md",
    "corp skill file: grm-pbi-source-markdown\SKILL.md|$long\extensions\grm-corporate-workflow\skills\grm-pbi-source-markdown\SKILL.md|C:\dev\e2e\.github\skills\grm-pbi-source-markdown\SKILL.md"
))

# 3. Simetrico del anterior: si la normalizacion hubiera fijado la
#    forma corta, es la larga la que debe caer. La guarda no privilegia
#    una forma; exige una sola.
Invoke-Scenario -Name "forma-larga-contra-prefijo-corto" -SourceRepoPath $short -ExpectedNewCount 1 -ExpectedSubstring "source-prefix-mismatch" -Deployed (New-DeployedList @(
    "corp agent: corp.load|$short\extensions\grm-corporate-workflow\agents\corp.load.agent.md|C:\dev\e2e\.github\agents\corp.load.agent.md",
    "corp skill file: grm-pbi-source-markdown\SKILL.md|$long\extensions\grm-corporate-workflow\skills\grm-pbi-source-markdown\SKILL.md|C:\dev\e2e\.github\skills\grm-pbi-source-markdown\SKILL.md"
))

# 4. Hermano con prefijo compartido. Justifica el separador final del
#    prefijo: sin el, 'source-otro' pasaria por estar dentro de
#    'source'.
Invoke-Scenario -Name "hermano-con-prefijo-compartido" -SourceRepoPath $long -ExpectedNewCount 1 -ExpectedSubstring "source-prefix-mismatch" -Deployed (New-DeployedList @(
    "corp agent: corp.load|$long-otro\extensions\grm-corporate-workflow\agents\corp.load.agent.md|C:\dev\e2e\.github\agents\corp.load.agent.md"
))

# 5. El propio directorio raiz, sin fichero debajo. Tampoco es un
#    origen valido: no cuelga del prefijo, coincide con el.
Invoke-Scenario -Name "raiz-exacta-sin-descendiente" -SourceRepoPath $long -ExpectedNewCount 1 -ExpectedSubstring "source-prefix-mismatch" -Deployed (New-DeployedList @(
    "algo raro|$long|C:\dev\e2e\algo"
))

# 6. Diferencia solo de mayusculas. NO debe caer: las rutas de Windows
#    no distinguen caja y la guarda usa OrdinalIgnoreCase, igual que la
#    guarda de prefijo de Install-CorporateSkills.
Invoke-Scenario -Name "diferencia-solo-de-caja" -SourceRepoPath $long -ExpectedNewCount 0 -Deployed (New-DeployedList @(
    "corp agent: corp.load|$($long.ToUpper())\extensions\grm-corporate-workflow\agents\corp.load.agent.md|C:\dev\e2e\.github\agents\corp.load.agent.md"
))

# 7. Entrada sin los tres campos. Assert-DeployedProvenance la salta en
#    silencio; aqui se reporta (ver nota de OBS-P21-02): una entrada
#    malformada no la verifica nadie, y el silencio sobre lo no
#    verificado es justo lo que L-12 prohibe.
Invoke-Scenario -Name "entrada-malformada" -SourceRepoPath $long -ExpectedNewCount 1 -ExpectedSubstring "deployed-entry-malformed" -Deployed (New-DeployedList @(
    "corp agent: corp.load|$long\extensions\grm-corporate-workflow\agents\corp.load.agent.md"
))

# 8. Lista vacia. Cero entradas nuevas, y por el motivo correcto: no
#    hay nada que comprobar, no es que la comprobacion se saltara.
Invoke-Scenario -Name "lista-vacia" -SourceRepoPath $long -ExpectedNewCount 0 -Deployed (New-DeployedList @())

# 9. Missing preexistente. La guarda acumula sobre el canal existente y
#    no puede pisar lo que ya habia registrado la validacion de runtime.
Invoke-Scenario -Name "preserva-missing-preexistente" -SourceRepoPath $long -ExpectedNewCount 1 -ExpectedSubstring "source-prefix-mismatch" -PreexistingMissing @("provenance-mismatch: C:\dev\e2e\.github\agents\corp.doc.agent.md", ".specify/workflows") -Deployed (New-DeployedList @(
    "corp prompt: corp.load|$short\extensions\grm-corporate-workflow\prompts\corp.load.prompt.md|C:\dev\e2e\.github\prompts\corp.load.prompt.md"
))

# --- Resultado ---

Write-Host ""
if ($script:Failures -gt 0) {
    Write-Host "TEST HARNESS: FAILED ($script:Failures de $script:ScenarioCount escenarios)"
    exit 1
} else {
    Write-Host "TEST HARNESS: OK ($script:ScenarioCount escenarios)"
    exit 0
}
