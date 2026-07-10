# Session Resume - GRM Custom Spec Kit (Parte 1)

**Fecha:** 09/07/2026

## Objetivo de la sesión

Continuar la POC de personalización corporativa de Spec Kit, validando un flujo basado en PBIs aprobados y eliminando la dependencia de especificaciones funcionales libres.

## Decisiones principales

### Cambio de flujo

Se sustituye el planteamiento inicial:

```text
/corp.load
↓
/corp.plan
```

Por:

```text
/corp.load
↓
/corp.assess
↓
/corp.plan (pendiente)
```

Principio rector:

```text
No plan without assessment.
```

## Estado de /corp.load

### Resultado

VALIDADO.

### Alcance MVP aprobado

- Solo admite carga desde fichero Markdown.
- Se elimina del MVP:
  - Azure DevOps
  - MCP
  - URLs
  - PBI IDs
- Comando soportado:

```text
/corp.load --file <path-to-pbi.md>
```

### Comportamiento validado

- Lee el PBI desde Markdown.
- Actualiza realmente:

```text
.specify/memory/active-pbi.md
```

- No modifica el fichero origen.
- Recomienda:

```text
/ corp.assess
```

### Hallazgo

H-15 documentado.

---

## Estado de /corp.assess

### Resultado

VALIDADO (v1).

### Objetivo

Actuar como gate de readiness previo a planificación.

### Características

- Read-only.
- Lee exclusivamente:

```text
.specify/memory/active-pbi.md
```

- Genera:
  - resumen PBI
  - checklist
  - riesgos
  - preguntas para Product Owner
  - observaciones técnicas
  - readiness assessment

### Clasificaciones

```text
READY
READY_WITH_RISKS
NOT_READY
```

### Limitación conocida

El modelo puede seguir sobreclasificando algunos gaps como BLOCKING.

No bloquea el MVP.

### Hallazgos

- H-13 documentado.
- H-14 documentado.

---

## Validación del PBI de prueba

PBI utilizado:

```text
PBI-1234
Enable users to download shipment documents
```

Resultado funcional esperado:

```text
READY_WITH_RISKS
```

Observaciones:

- Objetivo claro.
- Criterios de aceptación presentes.
- Dependencias identificadas.
- Restricciones técnicas identificadas.
- Out of scope ya identificado tras normalización del Active PBI.

---

## Neutralización de comandos estándar

### /speckit.specify

Resultado:

VALIDADO.

Respuesta observada:

```text
/speckit.specify is disabled in the corporate MVP workflow.
```

Redirección:

```text
/corp.load
↓
/corp.assess
```

### /speckit.clarify

Resultado:

VALIDADO.

Respuesta observada:

```text
/speckit.clarify is disabled in the corporate MVP workflow.
```

Redirección:

```text
/corp.assess
```

### Conclusión

Los desarrolladores ya no pueden iniciar el flujo mediante especificaciones funcionales libres.

---

## Validación de /speckit.plan

### Resultado

PARCIALMENTE VALIDADO.

### Aspectos positivos

- Lee correctamente:

```text
.specify/memory/active-pbi.md
```

- Mantiene trazabilidad al PBI.

En:

```text
features/pbi-download-shipment-documents/spec.md
```

aparece:

```text
Source: .specify/memory/active-pbi.md
```

En:

```text
features/pbi-download-shipment-documents/plan.md
```

aparece:

```text
Active PBI: .specify/memory/active-pbi.md
```

- No solicita ejecutar:

```text
/speckit.specify
```

### Riesgo detectado

No se ha demostrado que genere correctamente la estructura desde cero.

La ejecución observada reutiliza artefactos existentes:

```text
plan.md
research.md
data-model.md
quickstart.md
openapi.yaml
```

Todos ellos procedentes de pruebas anteriores.

### Conclusión

No queda validado como generador autónomo para nuevos PBIs.

---

## Decisión: crear /corp.plan MVP

Se aprueba implementar un comando corporativo:

```text
/corp.plan
```

En una sesión posterior.

### Objetivo

Crear una estructura mínima y gobernada para permitir continuar posteriormente con:

```text
/speckit.tasks
```

### Responsabilidades previstas

Leer:

```text
.specify/memory/active-pbi.md
```

Generar:

```text
features/<feature>/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
└── contracts/
```

### Restricciones

No puede:

- modificar alcance funcional
- modificar criterios de aceptación
- modificar active-pbi.md
- ejecutar speckit.specify
- ejecutar speckit.clarify

### Salida esperada

Recomendar:

```text
/speckit.tasks
```

---

## Estado de hallazgos

Documentados:

```text
H-13
H-14
H-15
```

Pendientes de documentar:

```text
H-16 (revisado)
H-17
H-18
```

---

## Estado actual del MVP

```text
/corp.load --file <pbi.md>
↓
/corp.assess
↓
/corp.plan (pendiente)
↓
/speckit.tasks
↓
/speckit.implement
```

## Próxima sesión

Diseñar e implementar:

```text
.github/prompts/corp.plan.prompt.md
.github/agents/corp.plan.agent.md
```

Con alcance MVP mínimo y foco en bootstrap de planificación gobernada.
