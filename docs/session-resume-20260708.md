# Session Resume - GRM Custom Spec Kit

Estamos desarrollando una personalización corporativa de Spec Kit basada en Presets y Extensions.

## Objetivo

Conseguir que el flujo de desarrollo se inicie siempre desde un PBI aprobado y no desde una especificación libre.

Flujo objetivo:

/corp.load
    ↓
/corp.plan
    ↓
/corp.tasks
    ↓
/speckit.implement
    ↓
Testing
    ↓
Reviews
    ↓
Documentation

## Estado actual

### Entorno

- Repositorio: grm-custom-spec-kit
- Sandbox: corp-pilot
- VS Code operativo
- UV instalado
- specify-cli instalado

### Hallazgos clave

- /corp.load ha sido implementado y validado.
- /corp.load soporta carga desde fichero markdown.
- active-pbi.md se genera correctamente.
- No ha sido necesario realizar fork de Spec Kit.
- Los comandos se implementan mediante:
  - .github/agents/*.agent.md
  - .github/prompts/*.prompt.md

### Riesgo principal identificado

Los agentes modifican artefactos de forma demasiado autónoma.

Se ha acordado que:

- Los comandos corporativos deben ser read-only por defecto.
- Las modificaciones deberán realizarse mediante un modo explícito tipo:

  /corp.plan --apply

### Próximo objetivo

Revisar y rediseñar corp.plan para:

- Modo por defecto: análisis y propuesta.
- Modo --apply: escritura controlada.
- Mantener active-pbi.md como fuente única de verdad funcional.

## Documentos de referencia

Adjuntos en la sesión:

- discovery-log.md
- plan_accion_speckit_corporativo.md

Comenzar la conversación revisando primero el discovery log y proponiendo el siguiente experimento técnico.
