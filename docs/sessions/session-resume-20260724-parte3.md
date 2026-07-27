# E2E Session Resume - 2026-07-24 (Parte 3)

## Objetivo de la sesión

Preparar una capacidad repetible de instalación limpia para validar GRM Custom Spec Kit en entornos E2E completamente nuevos, eliminando la necesidad de ejecutar manualmente la instalación de Spec Kit y la aplicación de la personalización corporativa.

---

# Contexto de partida

La sesión comenzó con la necesidad de realizar nuevas pruebas E2E limpias para:

- Completar validación de DF-002.
- Completar validación de GOV-E2E-006.
- Investigar H-005 en un entorno completamente limpio.
- Evitar instalaciones manuales repetitivas.

Se decidió construir un instalador automatizado para generar nuevos entornos E2E de forma reproducible.

---

# Desarrollo del instalador automático

## Primera versión

Se creó un bootstrap compuesto por:

- bootstrap-grm-e2e.ps1
- bootstrap-grm-e2e.bat

Funcionalidades iniciales:

1. Crear directorio E2E.
2. Ejecutar instalación limpia de Spec Kit.
3. Copiar personalización GRM.
4. Sincronizar runtime.
5. Generar installation-report.md.

---

# Hallazgos detectados durante la validación

## AUTO-001

### Código

AUTO-001

### Título

Prompt interactivo por inicialización Git previa

### Situación observada

El instalador ejecutaba:

```powershell
git init
specify init --here
```

Spec Kit mostraba:

```text
Current directory is not empty
Do you want to continue? [y/N]
```

### Causa

La presencia de:

```text
.git/
```

provocaba que Spec Kit considerase el directorio no vacío.

### Corrección aplicada

Cambio de orden:

```powershell
specify init --here
git init
```

### Estado

Cerrado.

---

## AUTO-002

### Código

AUTO-002

### Título

Inicialización interactiva de Spec Kit

### Situación observada

Spec Kit mostraba dos asistentes interactivos:

1. Selección de integración.
2. Selección de tipo de script.

Además aparecían caracteres corruptos durante la ejecución automatizada.

### Evidencias

Menú observado:

```text
Choose your coding agent integration
```

Selección utilizada manualmente:

```text
copilot
```

Posteriormente:

```text
Choose script type
```

Selección manual:

```text
ps
```

### Investigación

La ayuda de Spec Kit confirmó soporte para:

```powershell
--integration
--script
--force
```

### Corrección aplicada

Inicialización determinista:

```powershell
specify init --here `
  --integration copilot `
  --script ps `
  --force
```

### Resultado

- Eliminados menús interactivos.
- Eliminadas pulsaciones ENTER manuales.
- Mismo comportamiento en todas las instalaciones.

### Estado

Cerrado.

---

## AUTO-003

### Código

AUTO-003

### Título

Generación de directorios anidados

### Situación observada

El instalador llegó a crear:

```text
e2e-validation-2/
└── e2e-validation-2/
    └── e2e-validation-2/
```

### Causa raíz

Error en el wrapper BAT.

Uso incorrecto de:

```bat
shift
%*
```

provocando el paso repetido del parámetro TargetName.

### Corrección aplicada

Simplificación completa del BAT.

Eliminación de:

```bat
shift
%*
```

Uso exclusivo de:

```bat
-TargetName
```

### Estado

Cerrado.

---

## AUTO-004

### Código

AUTO-004

### Título

Validación insuficiente de runtime GRM

### Situación observada

Las primeras versiones validaban únicamente estructura global.

No verificaban presencia de:

```text
corp.load
corp.assess
corp.plan
corp.doc
corp.erase
```

### Corrección aplicada

Añadida validación explícita de:

#### Agentes

```text
corp.assess.agent.md
corp.doc.agent.md
corp.erase.agent.md
corp.load.agent.md
corp.plan.agent.md
```

#### Prompts

```text
corp.assess.prompt.md
corp.doc.prompt.md
corp.erase.prompt.md
corp.load.prompt.md
corp.plan.prompt.md
```

### Estado

Cerrado.

---

# Funcionalidades finales del instalador

## Instalación determinista

```powershell
specify init --here `
  --integration copilot `
  --script ps `
  --force
```

## Aplicación automática de:

- extensions/
- presets/
- docs/
- samples/
- README.md
- LICENSE

## Runtime merge

Conserva runtime Spec Kit estándar.

Añade:

```text
corp.*
```

sin perder:

```text
speckit.analyze
speckit.checklist
speckit.converge
speckit.taskstoissues
```

## Constitución

Copia automáticamente:

```text
.specify/memory/constitution.md
```

## Informe

Genera:

```text
installation-report.md
```

---

# Decisión importante sobre el instalador

## Evaluación para commit

Se analizó incorporar el instalador al repositorio.

### Hallazgo

El instalador utiliza actualmente:

```text
C:\DEV\PROYS\grm-custom-spec-kit
```

como repositorio fuente.

Por tanto:

- Funciona correctamente en el entorno de Sergio.
- No es portable para otros usuarios.
- No clona ni descarga la personalización desde Git.

### Decisión

NO realizar commit del instalador.

### Motivo

Actualmente es una herramienta local de soporte E2E.

Antes de convertirse en entregable oficial debería:

- trabajar desde el propio repositorio,
- o clonar desde Git automáticamente,
- o recibir SourceRepo como parámetro portable.

### Estado

No commit.

---

# Validación final del instalador

## Entorno generado

```text
e2e-grm-custom-speckit-try1
```

## Resultado

Estructura correcta:

```text
.github
.specify
.vscode
docs
extensions
presets
samples
README.md
LICENSE
installation-report.md
```

## Runtime validado

Presentes:

### Corporativos

```text
corp.assess
corp.doc
corp.erase
corp.load
corp.plan
```

### Estándar

```text
speckit.analyze
speckit.checklist
speckit.clarify
speckit.converge
speckit.implement
speckit.plan
speckit.specify
speckit.tasks
speckit.taskstoissues
```

## Estado

Instalador validado.

Versión candidata:

```text
bootstrap-grm-e2e v1.0
```

---

# Validación de gobernanza

## speckit.specify

Resultado:

```text
/speckit.specify is disabled in the corporate MVP workflow.
```

Estado:

✅ Correcto

---

## speckit.clarify

Resultado:

```text
/speckit.clarify is disabled in the corporate MVP workflow.
```

Estado:

✅ Correcto

---

## speckit.plan

Resultado:

```text
/speckit.plan is blocked in the corporate MVP workflow.
```

Adicionalmente verificó:

```text
.specify/memory/active-pbi.md
features/**/spec.md
```

y devolvió el flujo correcto:

```text
/corp.load
/corp.assess
/corp.plan
/speckit.plan
```

Estado:

✅ Correcto

---

# Estado consolidado

| Código | Estado |
|----------|----------|
| AUTO-001 | Cerrado |
| AUTO-002 | Cerrado |
| AUTO-003 | Cerrado |
| AUTO-004 | Cerrado |
| DF-002 | Pendiente |
| GOV-E2E-006 | Pendiente |
| H-005 | Pendiente |

---

# Próxima sesión recomendada

Trabajar sobre:

```text
C:\DEV\PROYS\e2e-grm-custom-speckit-try1
```

Workflow completo:

```text
/corp.erase
/corp.load --file samples/PBI-POC-01-calculadora-iva.md
/corp.assess
/corp.plan
/speckit.plan
/speckit.tasks
/speckit.implement
/corp.doc
```

Objetivos:

1. Validar DF-002 hasta delivery-doc.
2. Validar GOV-E2E-006 durante implement y corp.doc.
3. Confirmar o descartar H-005 en entorno limpio certificado.

---

# Punto de reanudación

La instalación limpia y la validación de gobernanza han sido completadas satisfactoriamente.

La siguiente sesión debe comenzar directamente ejecutando:

```text
/corp.erase
```

sobre:

```text
e2e-grm-custom-speckit-try1
```

sin necesidad de realizar nuevas tareas de instalación.