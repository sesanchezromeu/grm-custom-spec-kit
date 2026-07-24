# E2E Session Resume - 2026-07-23

## Contexto

Sesión de validación operativa E2E de la personalización **GRM Custom Spec Kit** sobre el repositorio:

```text
C:\dev\proys\e2e-validation
```

Objetivo de la sesión: validar el flujo completo desde un PBI aprobado hasta implementación y documentación final, siguiendo `docs/user-guide.md` y usando el PBI:

```text
samples/PBI-POC-01-calculadora-iva.md
```

Flujo aprobado validado:

```text
corp.erase
↓
corp.load
↓
corp.assess
↓
corp.plan
↓
speckit.plan
↓
speckit.tasks
↓
speckit.implement
↓
corp.doc
```

---

## Estado ejecutivo

```text
Resultado E2E global: PASS
Decisión provisional: GO FOR PILOT
Nivel de confianza: Alto
Bloqueantes técnicos: 0
Hallazgos abiertos relevantes: 3
```

La personalización funciona end-to-end, pero se han detectado ajustes necesarios antes de considerar una certificación definitiva de release.

---

## Ejecución realizada

| Paso | Resultado | Evidencia / comentario |
|---|---:|---|
| Pre-flight | PASS | Estructura base correcta: `.specify`, `.github/agents`, `.github/prompts`, `extensions`, `presets`, `samples`, `docs`. |
| `corp.erase` | PASS | Limpieza correcta para nuevo ciclo. |
| `corp.load` | PASS | Generó `.specify/memory/active-pbi.md`. El PBI se cargó correctamente como fuente funcional de verdad. |
| `corp.assess` | PASS con hallazgos | Resultado: `READY_WITH_RISKS`. Detectó riesgos, pero uno de ellos parte de una interpretación incorrecta del PBI. |
| `corp.plan` | PASS con defecto detectado | Generó `features/pbi-poc-01-calculadora-simple-de-importe-con-iva/spec.md`, pero no generó `.specify/feature.json`. |
| `speckit.plan` | PASS con intervención | Generó `plan.md`, `research.md`, `data-model.md`, `quickstart.md`, `contracts/cli-contract.md`. Necesitó resolver contexto con `SPECIFY_FEATURE_DIRECTORY`. |
| `speckit.tasks` | PASS | Generó `tasks.md` con 22 tareas, agrupadas por setup, foundational, US1 y polish. |
| `speckit.implement` | PASS con hallazgos | Generó implementación CLI Python, tests unitarios/integración/contrato y 14 tests OK. |
| `corp.doc` | PASS con hallazgos | Generó `delivery-doc.md` con estado `COMPLIANT_WITH_FINDINGS`. |

---

## Artefactos finales generados

Feature directory:

```text
features/pbi-poc-01-calculadora-simple-de-importe-con-iva/
```

Contiene:

```text
spec.md
plan.md
research.md
data-model.md
quickstart.md
tasks.md
delivery-doc.md
contracts/cli-contract.md
```

Código generado:

```text
src/iva_calculator/domain.py
src/iva_calculator/cli.py
```

Tests generados:

```text
tests/unit/test_domain.py
tests/integration/test_cli.py
tests/contract/test_cli_contract.py
```

Validación ejecutada:

```text
python -m unittest discover -s tests -p "test_*.py"
```

Resultado reportado:

```text
Ran 14 tests, OK
```

---

## Hallazgos principales

### H-001 - `corp.plan` no genera `.specify/feature.json`

**Estado:** Abierto  
**Severidad:** Alta para integración, no bloqueante para piloto  
**Área:** Runtime / integración Spec Kit

Durante la prueba, tras ejecutar `/corp.plan`, se comprobó:

```powershell
Get-Content .specifyeature.json
```

Resultado:

```text
No se encuentra la ruta de acceso ... .specifyeature.json porque no existe.
```

Esto explica por qué `/speckit.plan` necesitó resolver manualmente el contexto con:

```powershell
$env:SPECIFY_FEATURE_DIRECTORY = "features/pbi-poc-01-calculadora-simple-de-importe-con-iva"
```

#### Diagnóstico

Se actualizó `extensions/grm-corporate-workflow/agents/corp.plan.agent.md`, pero el runtime ejecutó probablemente la copia antigua en:

```text
.github/agents/corp.plan.agent.md
```

#### Próximo paso recomendado

Verificar si la copia runtime contiene la nueva lógica:

```powershell
Select-String -Path .githubgents\corp.plan.agent.md -Pattern "feature.json"
```

Si no devuelve resultados, sincronizar:

```powershell
Copy-Item extensions\grm-corporate-workflowgents\corp.plan.agent.md .githubgents\corp.plan.agent.md -Force
```

Después repetir prueba mínima:

```text
/corp.erase
/corp.load --file samples/PBI-POC-01-calculadora-iva.md
/corp.assess
/corp.plan
```

Y validar:

```powershell
Get-Content .specifyeature.json
```

Resultado esperado:

```json
{
  "feature_directory": "features/pbi-poc-01-calculadora-simple-de-importe-con-iva"
}
```

---

### H-002 - Sincronización runtime no evidente

**Estado:** Abierto  
**Severidad:** Media  
**Área:** Instalación / mantenimiento

Se ha confirmado que modificar el agente en `extensions/` no implica necesariamente que Copilot use esa versión durante la ejecución. La copia efectiva parece estar en `.github/agents/`.

#### Riesgo

El mantenedor puede creer que un cambio está aplicado cuando el runtime sigue ejecutando una versión anterior.

#### Acción recomendada

Actualizar documentación de instalación/mantenimiento con una instrucción explícita de sincronización runtime:

```text
extensions/grm-corporate-workflow/agents/*.agent.md
↓
.github/agents/*.agent.md
```

También valorar crear un script de sincronización.

---

### H-003 - `corp.assess` interpreta incorrectamente el catálogo de IVA

**Estado:** Abierto  
**Severidad:** Media  
**Área:** Calidad del agente / prompt de assessment

El PBI original define explícitamente los tipos de IVA permitidos:

```text
0 %
4 %
10 %
21 %
```

Sin embargo, `corp.assess` indicó riesgo sobre conjunto de IVA no cerrado y generó preguntas/recomendaciones como si el catálogo no estuviera definido.

#### Impacto

El delivery-doc acabó registrando deuda técnica relacionada con restringir tasas de IVA, aunque el PBI sí contenía una lista explícita.

#### Próximo paso recomendado

Revisar:

```text
extensions/grm-corporate-workflow/agents/corp.assess.agent.md
```

y/o prompt asociado, para reforzar esta regla:

```text
If the PBI provides an explicit finite list of allowed values, treat that list as defined scope. Do not raise a clarification asking whether the set is open or extensible unless the PBI explicitly suggests extensibility.
```

---

### H-004 - Implementación CLI en lugar de Web

**Estado:** Aceptado / No bloqueante  
**Severidad:** Baja  
**Área:** Constitución / estándares técnicos

La implementación generó una CLI Python, no una aplicación web. Se considera correcto porque la constitución corporativa no define todavía una tecnología objetivo ni obliga a formato web.

#### Decisión

No es defecto del workflow. Si GRM quiere que futuras implementaciones sean web por defecto, debe definirse en:

```text
.specify/memory/constitution.md
```

o en estándares técnicos corporativos.

---

## Documentación: hallazgos para actualizar `user-guide.md`

Se acumularon hallazgos `UG-E2E-001` a `UG-E2E-030`. No todos requieren cambios individuales, pero deben consolidarse en mejoras documentales.

### Cambios recomendados en `docs/user-guide.md`

1. Añadir checklist post-comando para:
   - `corp.load`
   - `corp.assess`
   - `corp.plan`
   - `speckit.plan`
   - `speckit.tasks`
   - `speckit.implement`
   - `corp.doc`

2. Documentar naming de feature directory:

```text
features/<normalized-pbi-id-and-title>
```

3. Documentar outputs esperados reales:

```text
corp.plan:
- features/<feature>/spec.md
- .specify/feature.json

speckit.plan:
- plan.md
- research.md
- data-model.md
- quickstart.md
- contracts/*

speckit.tasks:
- tasks.md

speckit.implement:
- src/*
- tests/*
- README/quickstart/spec/tasks updates where applicable

corp.doc:
- delivery-doc.md
```

4. Documentar comportamiento `READY_WITH_RISKS`:
   - quién acepta riesgos,
   - cómo se registra,
   - cómo se arrastran a planning/delivery-doc.

5. Documentar PowerShell Execution Policy:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
```

6. Documentar comportamiento sin repositorio Git:
   - Git recomendado, no obligatorio.
   - Algunas validaciones de `.gitignore` pueden omitirse si no existe `.git`.

7. Documentar ausencia de hooks:
   - Si `.specify/extensions.yml` no existe, no se ejecutan pre/post hooks.

8. Documentar sincronización runtime:

```text
Actualizar extensions/ no implica actualizar .github/agents automáticamente.
```

---

## Cambios realizados durante la sesión

Se generó un nuevo fichero actualizado:

```text
corp.plan.agent.md
```

Objetivo del cambio:

- Añadir creación/actualización obligatoria de `.specify/feature.json`.
- Validar que apunta al feature directory correcto.
- Mantener `corp.plan.prompt.md` como entrada mínima delegadora.
- Evitar duplicar lógica de agente en el prompt.

Decisión de diseño validada:

```text
prompt = entrypoint mínimo
agent = comportamiento gobernado
```

---

## Próxima sesión: plan recomendado

### Paso 1 - Cerrar H-001 / H-002

Ejecutar:

```powershell
Select-String -Path .githubgents\corp.plan.agent.md -Pattern "feature.json"
```

Si no hay resultados:

```powershell
Copy-Item extensions\grm-corporate-workflowgents\corp.plan.agent.md .githubgents\corp.plan.agent.md -Force
```

Validar de nuevo:

```powershell
Select-String -Path .githubgents\corp.plan.agent.md -Pattern "feature.json"
```

Repetir prueba mínima:

```text
/corp.erase
/corp.load --file samples/PBI-POC-01-calculadora-iva.md
/corp.assess
/corp.plan
```

Comprobar:

```powershell
Get-Content .specifyeature.json
```

### Paso 2 - Corregir `corp.assess`

Adjuntar o revisar:

```text
corp.assess.agent.md
```

Objetivo: evitar falsos riesgos cuando el PBI ya define listas explícitas de valores permitidos.

### Paso 3 - Actualizar `user-guide.md`

Consolidar los hallazgos documentales en una versión mejorada, sin sobrecargar el documento.

### Paso 4 - Generar informe final

Crear:

```text
e2e-validation-report-20260723.md
```

Debe incluir:

- Workflow Execution Report
- Documentation Findings
- Governance Findings
- Usability Findings
- Final Go/No-Go Assessment
- Inputs for Release Certification

---

## Mensaje de tranquilidad

Es normal que aparezcan ajustes en esta fase. La prueba E2E precisamente ha servido para encontrar defectos de integración entre:

```text
source extension
runtime agents
native Spec Kit context
published documentation
```

El resultado no invalida el trabajo realizado. Al contrario: confirma que el flujo base funciona y que los hallazgos detectados son acotables, corregibles y propios de una fase de endurecimiento antes de release.

---

## Estado al pausar

```text
Sesión pausada el 2026-07-23.
Pendiente principal: sincronizar agente actualizado con runtime .github/agents y validar generación de .specify/feature.json.
```
