#Requires -Version 5.1
<#
    Test-SkillShape.ps1

    Arnes de pruebas para Assert-SkillShape y Read-SkillFrontmatter
    (P3, D-P20-06). Versionado en resources/tools/ por el mismo motivo
    que Sync-GrmSkills.ps1 (D-P19-05): herramienta de mantenedor, no
    artefacto desplegable.

    Extrae las dos funciones del AST de resources/bootstrap/bootstrap-grm-e2e.ps1
    sin ejecutar el instalador completo, mismo patron que el arnes no
    versionado de P2a. Las ejercita contra arboles de skills falsos
    construidos bajo $env:TEMP, un escenario por caso.

    Uso:
      powershell -NoProfile -ExecutionPolicy Bypass -File resources\tools\Test-SkillShape.ps1

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

$targetFunctions = @("Read-SkillFrontmatter", "Assert-SkillShape")
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

$script:TestRoot = Join-Path $env:TEMP ("skillshape-tests-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $script:TestRoot -Force | Out-Null

$script:Failures = 0
$script:ScenarioCount = 0

function New-FakeSkillsRoot {
    param([string]$ScenarioName)
    $root = Join-Path $script:TestRoot $ScenarioName
    New-Item -ItemType Directory -Path $root -Force | Out-Null
    return $root
}

function New-FakeSkill {
    param(
        [string]$SkillsRoot,
        [string]$DirName,
        [string]$FrontmatterBody,
        [switch]$NoSkillMd,
        [switch]$NoClosingDelimiter
    )
    $dir = Join-Path $SkillsRoot $DirName
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    if ($NoSkillMd) { return }

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add("---")
    $lines.Add($FrontmatterBody)
    if (-not $NoClosingDelimiter) { $lines.Add("---") }
    $lines.Add("")
    $lines.Add("# Body")
    $lines.Add("Contenido de cuerpo, irrelevante para la validacion de forma.")
    Set-Content -LiteralPath (Join-Path $dir "SKILL.md") -Value $lines -Encoding ascii
}

function Invoke-Scenario {
    param(
        [string]$Name,
        [scriptblock]$Setup,
        [bool]$ExpectThrow,
        [string]$ExpectedSubstring = $null
    )
    $script:ScenarioCount++
    $root = New-FakeSkillsRoot -ScenarioName $Name
    & $Setup $root

    $threw = $false
    $message = $null
    try {
        Assert-SkillShape -SkillsFrom $root
    } catch {
        $threw = $true
        $message = $_.Exception.Message
    }

    $ok = $true
    $reason = ""

    if ($ExpectThrow -and -not $threw) {
        $ok = $false
        $reason = "se esperaba fallo y no lo hubo"
    }
    if (-not $ExpectThrow -and $threw) {
        $ok = $false
        $reason = "no se esperaba fallo y se produjo: $message"
    }
    if ($ok -and $ExpectThrow -and $ExpectedSubstring) {
        if ($message -notlike "*$ExpectedSubstring*") {
            $ok = $false
            $reason = "el mensaje no contiene '$ExpectedSubstring'. Mensaje real: $message"
        }
    }

    if ($ok) {
        Write-Host "PASS  $Name"
    } else {
        Write-Host "FAIL  $Name -- $reason"
        $script:Failures++
    }
}

# --- Escenarios ---

# 1. Camino feliz: dos skills validas, distintas entre si.
Invoke-Scenario -Name "camino-feliz-dos-skills-validas" -ExpectThrow $false -Setup {
    param($root)
    New-FakeSkill -SkillsRoot $root -DirName "grm-skill-uno" `
        -FrontmatterBody "name: grm-skill-uno`ndescription: Descripcion breve y valida para la primera skill de prueba."
    New-FakeSkill -SkillsRoot $root -DirName "grm-skill-dos" `
        -FrontmatterBody "name: grm-skill-dos`ndescription: Descripcion breve y valida para la segunda skill de prueba."
}

# 2. Directorio sin SKILL.md: criterio de inclusion, no debe fallar ni
#    generar problema. _shared es el caso real de esto.
Invoke-Scenario -Name "directorio-sin-skillmd-se-ignora" -ExpectThrow $false -Setup {
    param($root)
    New-FakeSkill -SkillsRoot $root -DirName "_shared" -NoSkillMd
    New-FakeSkill -SkillsRoot $root -DirName "grm-skill-valida" `
        -FrontmatterBody "name: grm-skill-valida`ndescription: Descripcion valida."
}

# 3. Frontmatter sin cierre '---': no parseable.
Invoke-Scenario -Name "frontmatter-sin-cierre" -ExpectThrow $true -ExpectedSubstring "frontmatter not parseable" -Setup {
    param($root)
    New-FakeSkill -SkillsRoot $root -DirName "grm-skill-rota" `
        -FrontmatterBody "name: grm-skill-rota`ndescription: Descripcion valida." `
        -NoClosingDelimiter
}

# 4. Falta 'name' en el frontmatter.
Invoke-Scenario -Name "falta-name" -ExpectThrow $true -ExpectedSubstring "missing 'name'" -Setup {
    param($root)
    New-FakeSkill -SkillsRoot $root -DirName "grm-skill-sin-name" `
        -FrontmatterBody "description: Descripcion valida sin campo name."
}

# 5. Falta 'description' en el frontmatter.
Invoke-Scenario -Name "falta-description" -ExpectThrow $true -ExpectedSubstring "missing 'description'" -Setup {
    param($root)
    New-FakeSkill -SkillsRoot $root -DirName "grm-skill-sin-description" `
        -FrontmatterBody "name: grm-skill-sin-description"
}

# 6. 'name' no coincide con el directorio.
Invoke-Scenario -Name "name-no-coincide-con-directorio" -ExpectThrow $true -ExpectedSubstring "does not match directory name" -Setup {
    param($root)
    New-FakeSkill -SkillsRoot $root -DirName "grm-skill-real" `
        -FrontmatterBody "name: grm-skill-otro`ndescription: Descripcion valida."
}

# 7. 'name' con formato invalido (mayusculas).
Invoke-Scenario -Name "name-formato-invalido-mayusculas" -ExpectThrow $true -ExpectedSubstring "must be lowercase-with-hyphens" -Setup {
    param($root)
    New-FakeSkill -SkillsRoot $root -DirName "GRM-Skill-Mal" `
        -FrontmatterBody "name: GRM-Skill-Mal`ndescription: Descripcion valida."
}

# 8. 'name' supera los 64 caracteres.
Invoke-Scenario -Name "name-supera-64-caracteres" -ExpectThrow $true -ExpectedSubstring "must be lowercase-with-hyphens" -Setup {
    param($root)
    $longName = "grm-" + ("a" * 62)
    New-FakeSkill -SkillsRoot $root -DirName $longName `
        -FrontmatterBody "name: $longName`ndescription: Descripcion valida."
}

# 9. 'description' supera los 1024 caracteres.
Invoke-Scenario -Name "description-supera-1024-caracteres" -ExpectThrow $true -ExpectedSubstring "exceeds 1024 characters" -Setup {
    param($root)
    $longDescription = "x" * 1025
    New-FakeSkill -SkillsRoot $root -DirName "grm-skill-descripcion-larga" `
        -FrontmatterBody "name: grm-skill-descripcion-larga`ndescription: $longDescription"
}

# 10. Agregacion: dos skills con fallos distintos en la misma pasada
#     deben aparecer ambas en un unico mensaje.
Invoke-Scenario -Name "agregacion-de-multiples-fallos" -ExpectThrow $true -Setup {
    param($root)
    New-FakeSkill -SkillsRoot $root -DirName "grm-fallo-uno" `
        -FrontmatterBody "description: Sin name."
    New-FakeSkill -SkillsRoot $root -DirName "grm-fallo-dos" `
        -FrontmatterBody "name: grm-fallo-dos`ndescription: $("x" * 1025)"
}
# Verificacion adicional de agregacion: releer con captura explicita.
$aggRoot = New-FakeSkillsRoot -ScenarioName "agregacion-verificacion-detallada"
New-FakeSkill -SkillsRoot $aggRoot -DirName "grm-fallo-uno" -FrontmatterBody "description: Sin name."
New-FakeSkill -SkillsRoot $aggRoot -DirName "grm-fallo-dos" -FrontmatterBody "name: grm-fallo-dos`ndescription: $("x" * 1025)"
$script:ScenarioCount++
try {
    Assert-SkillShape -SkillsFrom $aggRoot
    Write-Host "FAIL  agregacion-verificacion-detallada -- se esperaba fallo y no lo hubo"
    $script:Failures++
} catch {
    $msg = $_.Exception.Message
    if ($msg -like "*grm-fallo-uno*" -and $msg -like "*grm-fallo-dos*") {
        Write-Host "PASS  agregacion-verificacion-detallada"
    } else {
        Write-Host "FAIL  agregacion-verificacion-detallada -- el mensaje no cubre ambos directorios. Mensaje real: $msg"
        $script:Failures++
    }
}

# --- Limpieza y resultado ---

Remove-Item -LiteralPath $script:TestRoot -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ""
if ($script:Failures -gt 0) {
    Write-Host "TEST HARNESS: FAILED ($script:Failures de $script:ScenarioCount escenarios)"
    exit 1
} else {
    Write-Host "TEST HARNESS: OK ($script:ScenarioCount escenarios)"
    exit 0
}
