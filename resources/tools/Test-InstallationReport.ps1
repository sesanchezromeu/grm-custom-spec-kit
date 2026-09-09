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
      P5a2 Assert-DeployedProvenance, rama de entrada malformada
           (OBS-P21-02, D-P28-06: b) -- cerrada en P28
      P5b  New-InstallationReport, subseccion ### Skills (D-P21-01c,
           D-P21-03a, D-P21-04) y regresion de Assert-SkillShape
           (D-P21-08: sigue lanzando en camino de fallo, y en exito
           devuelve los directorios validados)

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

$targetFunctions = @("Assert-DeployedSourcePrefix", "Assert-DeployedProvenance", "Assert-SkillShape", "Read-SkillFrontmatter", "New-InstallationReport")
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

function Invoke-ProvenanceScenario {
    # Mismo patron que Invoke-Scenario, para Assert-DeployedProvenance
    # (OBS-P21-02). Guardia distinta -- compara contenido, no prefijo --
    # y su firma no lleva SourceRepoPath.
    param(
        [string]$Name,
        [System.Collections.Generic.List[string]]$Deployed,
        [string[]]$PreexistingMissing = @(),
        [int]$ExpectedNewCount,
        [string]$ExpectedSubstring = $null
    )
    $script:ScenarioCount++

    $missing = @()
    foreach ($m in $PreexistingMissing) { $missing += $m }
    $before = $missing.Count

    Assert-DeployedProvenance -Deployed $Deployed -Missing ([ref]$missing)

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

# --- Helpers P5b: regresion de Assert-SkillShape y estados de
#     New-InstallationReport ---

function Invoke-SkillShapeScenario {
    # Regresion de P3 (D-P19-02 y siguientes): confirma que anadir el
    # "return $validatedDirs" en el camino de exito no toca el camino
    # de fallo, y que el camino de exito ahora devuelve el nombre del
    # directorio que supero las seis reglas.
    param(
        [string]$Name,
        [string]$SkillsFrom,
        [bool]$ExpectThrow,
        [string[]]$ExpectedReturnedDirs = @()
    )
    $script:ScenarioCount++

    $threw = $false
    $returned = @()
    try {
        $returned = @(Assert-SkillShape -SkillsFrom $SkillsFrom)
    } catch {
        $threw = $true
    }

    $ok = $true
    $reason = ""
    if ($threw -ne $ExpectThrow) {
        $ok = $false
        $reason = "se esperaba throw=$ExpectThrow y se obtuvo throw=$threw"
    }
    if ($ok -and -not $ExpectThrow) {
        $missingExpected = @($ExpectedReturnedDirs | Where-Object { $returned -notcontains $_ })
        $extra = @($returned | Where-Object { $ExpectedReturnedDirs -notcontains $_ })
        if ($missingExpected.Count -gt 0 -or $extra.Count -gt 0) {
            $ok = $false
            $reason = "devueltos ($($returned -join ', ')) no coincide con esperado ($($ExpectedReturnedDirs -join ', '))"
        }
    }

    if ($ok) {
        Write-Host "PASS  $Name"
    } else {
        Write-Host "FAIL  $Name -- $reason"
        $script:Failures++
    }
}

function Invoke-ReportSkillsScenario {
    # Ejercita New-InstallationReport de verdad -mismo cmdlet
    # Set-Content, mismo here-string- contra un fichero temporal, y lee
    # de vuelta la subseccion ### Skills. No reimplementa la logica de
    # agrupacion: si esta prueba pasa, es porque el codigo del
    # instalador la produjo asi, no porque el arnes la calculo por su
    # cuenta.
    #
    # La comparacion de lineas se hace como conjunto (ambos lados
    # ordenados) para no acoplar la prueba a la cultura de ordenacion
    # de Sort-Object en la maquina donde corra.
    param(
        [string]$Name,
        [System.Collections.Generic.List[string]]$Deployed,
        [bool]$SkillsShapeValidated,
        [string[]]$ValidatedSkillDirs,
        [string[]]$ExpectedLines
    )
    $script:ScenarioCount++
    $reportPath = Join-Path $env:TEMP ("gsck-report-scenario-" + [guid]::NewGuid().ToString("N") + ".md")

    try {
        New-InstallationReport `
            -ReportPath $reportPath `
            -Status "SUCCESS" `
            -ErrorMessage "" `
            -StartTime (Get-Date) `
            -EndTime (Get-Date) `
            -RootPath "C:\dev\e2e" `
            -TargetPath "C:\dev\e2e" `
            -InstallMode "clean" `
            -EffectiveMode "clean" `
            -GitVersion "git version 2.44.0" `
            -SpecKitVersion "0.9.0" `
            -SpecKitInitCommandForReport "uvx --from git+https://github.com/github/spec-kit.git specify init" `
            -InstalledRemote "https://github.com/sesanchezromeu/grm-custom-spec-kit.git" `
            -InstalledBranch "main" `
            -InstalledCommit "70079f70be0711af4175bf3204be1fb505a6ec9c" `
            -SourceRepoPath "C:\Users\sesanchez\AppData\Local\Temp\grm-custom-spec-kit-cache\source" `
            -KeepSourceCache:$false `
            -AgentFiles @() `
            -PromptFiles @() `
            -WorkflowEntries @() `
            -SamplesCopied:$false `
            -DocsCopied:$false `
            -ConstitutionCopied:$false `
            -BacklogCatalogCopied:$false `
            -Missing @() `
            -DeployedArtifacts $Deployed `
            -PreservedArtifacts @() `
            -UndeployedArtifacts @() `
            -SkillsShapeValidated:$SkillsShapeValidated `
            -ValidatedSkillDirs $ValidatedSkillDirs `
            -Warnings ([System.Collections.Generic.List[string]]::new())

        $content = Get-Content -LiteralPath $reportPath -Raw
        $sectionText = $null
        if ($content -match '(?ms)^### Skills\r?\n\r?\n(.*?)\r?\n\r?\n### Workflows') {
            $sectionText = $matches[1]
        }

        $actualLines = @()
        if ($sectionText) {
            $actualLines = @($sectionText -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" })
        }

        $actualSorted = @($actualLines | Sort-Object)
        $expectedSorted = @($ExpectedLines | Sort-Object)

        $ok = ($actualSorted.Count -eq $expectedSorted.Count)
        if ($ok) {
            for ($i = 0; $i -lt $actualSorted.Count; $i++) {
                if ($actualSorted[$i] -ne $expectedSorted[$i]) { $ok = $false; break }
            }
        }

        if ($ok) {
            Write-Host "PASS  $Name"
        } else {
            Write-Host "FAIL  $Name -- seccion real: [$($actualLines -join ' | ')] -- esperada: [$($ExpectedLines -join ' | ')]"
            $script:Failures++
        }
    } finally {
        if (Test-Path -LiteralPath $reportPath) { Remove-Item -LiteralPath $reportPath -Force }
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

# 7. Entrada sin los tres campos, vista desde Assert-DeployedSourcePrefix.
#    Cierre de OBS-P21-02 (D-P28-06: b): antes, Assert-DeployedProvenance
#    la saltaba en silencio; ahora tambien reporta, con su propio texto
#    (ver escenario 7b). Silencio sobre lo no verificado es justo lo que
#    L-12 prohibe.
Invoke-Scenario -Name "entrada-malformada" -SourceRepoPath $long -ExpectedNewCount 1 -ExpectedSubstring "deployed-entry-malformed" -Deployed (New-DeployedList @(
    "corp agent: corp.load|$long\extensions\grm-corporate-workflow\agents\corp.load.agent.md"
))

# 7b. Simetrico del anterior, ahora desde Assert-DeployedProvenance
#     (OBS-P21-02, D-P28-06: b). Mensaje distinto a proposito
#     ("provenance-entry-malformed", no "deployed-entry-malformed"):
#     las dos guardias corren sobre la misma lista $DeployedArtifacts
#     en produccion, y con el mismo texto la misma entrada aparecería
#     duplicada y sin distincion en el informe final.
Invoke-ProvenanceScenario -Name "entrada-malformada-provenance" -ExpectedNewCount 1 -ExpectedSubstring "provenance-entry-malformed" -Deployed (New-DeployedList @(
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

# --- P5b: regresion de Assert-SkillShape ---

$skillShapePosRoot = Join-Path $env:TEMP ("gsck-skillshape-pos-" + [guid]::NewGuid().ToString("N"))
$skillShapeNegRoot = Join-Path $env:TEMP ("gsck-skillshape-neg-" + [guid]::NewGuid().ToString("N"))

try {
    # 10. Camino feliz de Assert-SkillShape tras P5b: un directorio con
    #     SKILL.md valido no solo no lanza -eso ya lo cubria P3-, ademas
    #     devuelve su propio nombre. Fixture minima, un solo directorio,
    #     para no repetir el corpus de Test-SkillShape.ps1.
    New-Item -ItemType Directory -Path (Join-Path $skillShapePosRoot "valid-skill") -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $skillShapePosRoot "valid-skill\SKILL.md") -Encoding UTF8 -Value @"
---
name: valid-skill
description: Fixture skill used only by the P5b harness to confirm Assert-SkillShape still returns validated directories.
---
# valid-skill
"@
    Invoke-SkillShapeScenario -Name "assert-skillshape-valida-devuelve-directorio" -SkillsFrom $skillShapePosRoot -ExpectThrow $false -ExpectedReturnedDirs @("valid-skill")

    # 11. Camino de fallo de Assert-SkillShape: 'name' no coincide con
    #     el nombre del directorio. Debe seguir lanzando exactamente
    #     igual que en P3; el "return" nuevo es inalcanzable en esta
    #     rama porque $problems.Count -gt 0 corta antes.
    New-Item -ItemType Directory -Path (Join-Path $skillShapeNegRoot "broken-skill") -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $skillShapeNegRoot "broken-skill\SKILL.md") -Encoding UTF8 -Value @"
---
name: wrong-name
description: Fixture skill whose name deliberately does not match its directory, to confirm the failure path still throws after P5b.
---
# broken-skill
"@
    Invoke-SkillShapeScenario -Name "assert-skillshape-invalida-sigue-lanzando" -SkillsFrom $skillShapeNegRoot -ExpectThrow $true
}
finally {
    if (Test-Path -LiteralPath $skillShapePosRoot) { Remove-Item -LiteralPath $skillShapePosRoot -Recurse -Force }
    if (Test-Path -LiteralPath $skillShapeNegRoot) { Remove-Item -LiteralPath $skillShapeNegRoot -Recurse -Force }
}

# --- P5b: los tres estados de la subseccion ### Skills (D-P21-04) ---

# 12. Estado 1: validadas y desplegadas. Tres directorios en Deployed
#     -_shared con tres ficheros y las otras dos con una y dos-, y solo
#     dos de ellos en ValidatedSkillDirs. Comprueba a la vez el
#     recuento por directorio, el singular/plural de "file"/"files", y
#     que _shared se distingue como no-skill sin desaparecer.
Invoke-ReportSkillsScenario -Name "report-skills-estado-1-validadas-y-desplegadas" `
    -SkillsShapeValidated $true `
    -ValidatedSkillDirs @("grm-azure-devops-pbi", "grm-pbi-source-markdown") `
    -Deployed (New-DeployedList @(
        "corp skill file: grm-azure-devops-pbi\SKILL.md|C:\cache\source\extensions\grm-corporate-workflow\skills\grm-azure-devops-pbi\SKILL.md|C:\dev\e2e\.github\skills\grm-azure-devops-pbi\SKILL.md",
        "corp skill file: grm-azure-devops-pbi\scripts\Get-WorkItem.ps1|C:\cache\source\extensions\grm-corporate-workflow\skills\grm-azure-devops-pbi\scripts\Get-WorkItem.ps1|C:\dev\e2e\.github\skills\grm-azure-devops-pbi\scripts\Get-WorkItem.ps1",
        "corp skill file: grm-pbi-source-markdown\SKILL.md|C:\cache\source\extensions\grm-corporate-workflow\skills\grm-pbi-source-markdown\SKILL.md|C:\dev\e2e\.github\skills\grm-pbi-source-markdown\SKILL.md",
        "corp skill file: _shared\SKILL_SHARED.md|C:\cache\source\extensions\grm-corporate-workflow\skills\_shared\SKILL_SHARED.md|C:\dev\e2e\.github\skills\_shared\SKILL_SHARED.md",
        "corp skill file: _shared\scripts\Assert-ActivePbi.ps1|C:\cache\source\extensions\grm-corporate-workflow\skills\_shared\scripts\Assert-ActivePbi.ps1|C:\dev\e2e\.github\skills\_shared\scripts\Assert-ActivePbi.ps1",
        "corp skill file: _shared\scripts\Get-CorpConfig.ps1|C:\cache\source\extensions\grm-corporate-workflow\skills\_shared\scripts\Get-CorpConfig.ps1|C:\dev\e2e\.github\skills\_shared\scripts\Get-CorpConfig.ps1"
    )) `
    -ExpectedLines @(
        "- grm-azure-devops-pbi: 2 files, shape validated",
        "- grm-pbi-source-markdown: 1 file, shape validated",
        "- _shared: 3 files, not a skill (no SKILL.md)"
    )

# 13. Estado 2: la validacion corrio -SkillsShapeValidated=true- pero no
#     hay ninguna entrada "corp skill file:" en Deployed. Otras clases
#     de entrada (agente, prompt) no deben colarse en el recuento.
Invoke-ReportSkillsScenario -Name "report-skills-estado-2-validado-sin-skills" `
    -SkillsShapeValidated $true `
    -ValidatedSkillDirs @() `
    -Deployed (New-DeployedList @(
        "corp agent: corp.load|C:\cache\source\extensions\grm-corporate-workflow\agents\corp.load.agent.md|C:\dev\e2e\.github\agents\corp.load.agent.md"
    )) `
    -ExpectedLines @(
        "- shape validated: no skill directories found in the Source of Truth"
    )

# 14. Estado 3: la ejecucion nunca llego a la validacion de forma.
#     Deployed puede traer artefactos de otras clases -no importa-: el
#     flag manda, no el contenido de Deployed.
Invoke-ReportSkillsScenario -Name "report-skills-estado-3-no-ejecutado" `
    -SkillsShapeValidated $false `
    -ValidatedSkillDirs @() `
    -Deployed (New-DeployedList @(
        "corp agent: corp.load|C:\cache\source\extensions\grm-corporate-workflow\agents\corp.load.agent.md|C:\dev\e2e\.github\agents\corp.load.agent.md"
    )) `
    -ExpectedLines @(
        "- shape validation not executed: installation stopped before this step"
    )

# --- Resultado ---

Write-Host ""
if ($script:Failures -gt 0) {
    Write-Host "TEST HARNESS: FAILED ($script:Failures de $script:ScenarioCount escenarios)"
    exit 1
} else {
    Write-Host "TEST HARNESS: OK ($script:ScenarioCount escenarios)"
    exit 0
}
