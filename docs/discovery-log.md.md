# Discovery Log

## Objetivo

Validar la viabilidad técnica de una personalización corporativa de Spec Kit basada en Presets y Extensions sin necesidad de mantener un fork.

## Hipótesis iniciales

### H-01
Es posible crear un comando corporativo `/corp.load` mediante Extensions.

### H-02
Es posible bloquear o neutralizar `/speckit.specify` mediante Presets.

### H-03
Es posible construir un flujo completamente basado en PBIs aprobados.

### H-04
La solución puede mantenerse compatible con futuras versiones de Spec Kit sin modificar el core.


## Hallazgos

### H-00
Spec Kit puede instalarse correctamente en un entorno Windows estándar utilizando:
- VS Code
- Python
- UV
- specify-cli

Resultado: Validado.

Evidencia:
uv 0.11.28
specify-cli 0.12.7

### H-01
Spec Kit soporta distintos tipos de scripting durante la inicialización:

- PowerShell
- Shell (POSIX)
- Python

Resultado:
Validado.

Impacto:
La personalización corporativa podrá alinearse con entornos Windows estándar utilizando PowerShell.

### H-02
Spec Kit instala inicialmente estos comandos:
/ speckit.constitution
/ speckit.specify
/ speckit.plan
/ speckit.tasks
/ speckit.implement
/ speckit.converge

Y además estos comandos auxiliares:
/ speckit.clarify
/ speckit.analyze
/ speckit.checklist

El documento propuesta estaba basado en una versión de flujo de 7 pasos y aquí vemos funcionalidades adicionales (analyze, checklist, converge) que tendremos que estudiar antes de diseñar el preset definitivo.

### H-03
La salida confirma: Install integration (GitHub Copilot)
Completado correctamente. Por tanto, nuestro escenario objetivo:
> Spec Kit + GitHub Copilot + Presets + Extensions

### H-04
La generación ha instalado: scripts (ps)
Esto nos puede resultar útil en el futuro para automatizaciones corporativas auxiliares.

### H-05
Spec Kit almacena la definición funcional del workflow en artefactos abiertos dentro del proyecto:

- templates
- workflows
- scripts
- integrations
- memory

Resultado:
Validado.

Impacto:
Existe una alta probabilidad de poder personalizar el comportamiento sin modificar el núcleo de Spec Kit.

### H-06
Spec Kit registra la integración con GitHub Copilot mediante archivos `.agent.md` y `.prompt.md` ubicados en:

- `.github/agents`
- `.github/prompts`

Resultado:
Validado.

Impacto:
La creación de comandos corporativos como `/corp.load` parece viable mediante nuevos agentes y prompts, sin necesidad inicial de fork.

### H-07
Se ha creado y ejecutado correctamente un comando corporativo personalizado:

/corp.load

mediante los ficheros:

- .github/agents/corp.load.agent.md
- .github/prompts/corp.load.prompt.md

Resultado:
Validado.

Impacto:
Es posible añadir comandos corporativos sin modificar el core de Spec Kit.

Conclusión:
La hipótesis H-01 queda validada.

### H-08

Se ha validado la carga de un PBI desde fichero Markdown mediante:

/corp.load --file samples/pbis/pbi-download-shipment-documents.md

Resultado:
Validado.

Evidencia:
El agente ha creado/cargado el PBI de ejemplo y ha generado el contexto activo en:

.specify/memory/active-pbi.md

Impacto:
El punto de entrada corporativo puede funcionar de forma agnóstica al origen del PBI, permitiendo modo local/sandbox sin depender inicialmente de Azure DevOps ni MCP.

Observación:
Durante la POC, el agente puede crear un PBI de ejemplo si el fichero no existe. En una versión corporativa gobernada, este comportamiento deberá restringirse o hacerse explícito.

### H-09

Se ha probado `/speckit.plan` tras cargar un PBI con `/corp.load`.

Resultado:
Parcialmente validado.

Evidencia:
Se han generado los ficheros:

- features/pbi-download-shipment-documents/spec.md
- features/pbi-download-shipment-documents/plan.md

El `spec.md` referencia `.specify/memory/active-pbi.md` como fuente funcional, y el `plan.md` referencia tanto la feature spec como el PBI activo.

Impacto:
Existe una vía técnica para conectar `/corp.load` con el flujo estándar de Spec Kit, pero los artefactos generados son todavía mínimos.

Conclusión:
No se decide todavía crear `/corp.plan`. Antes se reforzará `/corp.load` para preparar correctamente el contexto de planificación.

### H-10

Durante la prueba de `/corp.plan`, el agente modificó múltiples artefactos de planificación de forma unilateral.

Resultado:
Riesgo identificado.

Evidencia:
El agente reescribió `spec.md`, `plan.md`, `research.md`, `data-model.md`, `openapi.yaml` y `quickstart.md` sin solicitar confirmación previa explícita.

Impacto:
Los comandos corporativos no deben aplicar cambios automáticamente salvo que el usuario invoque un modo explícito de aplicación, por ejemplo `--apply`.

Decisión:
Rediseñar `/corp.plan` para que el modo por defecto sea read-only/proposal-only.

#### H-11
El comando /speckit.plan ha sido capaz de continuar el flujo partiendo de un contexto generado por /corp.load, sin haber ejecutado previamente /speckit.specify.

Resultado: Validado.

Impacto:
Existe una posibilidad real de reutilizar partes del flujo estándar de Spec Kit reduciendo el nivel de personalización necesario.

Pendiente:
Determinar si la calidad de los artefactos generados es suficiente para un entorno corporativo gobernado.

#### H-12
Los agentes personalizados tienen capacidad para crear, modificar y sobrescribir múltiples artefactos del proyecto sin confirmación previa explícita.

Resultado:
Validado.

Impacto:
La gobernanza corporativa requiere un patrón de doble fase:
- Análisis / propuesta (solo lectura)
- Aplicación explícita (--apply)

Este principio deberá incorporarse a todos los comandos corporativos relevantes.

#### H-13
Se revisa el flujo corporativo y se identifica la necesidad de incorporar un gate explícito de evaluación del PBI antes de la planificación técnica.

Resultado:
Decisión de diseño aprobada.

Decisión:
Se crea el comando corporativo /corp.assess.

Motivación:
No debe generarse un plan técnico sobre un PBI cuya completitud, consistencia y readiness no hayan sido previamente evaluadas.

Comportamiento:

- Lee exclusivamente .specify/memory/active-pbi.md
- Es read-only en todos los casos
- No modifica el PBI original
- No genera decisiones funcionales
- No amplía el alcance
- No modifica criterios de aceptación
- No genera artefactos de planificación
- Produce un assessment estructurado mediante checklist

Outputs:

- Resumen del PBI
- Checklist de preparación
- Riesgos detectados
- Preguntas para el Product Owner
- Supuestos técnicos
- Veredicto final

Clasificación:

- READY
- READY_WITH_RISKS
- NOT_READY

Impacto en el flujo:

/corp.load
↓
/corp.assess
↓
/corp.plan
↓
/corp.tasks
↓
/speckit.implement

Principio rector:

No plan without assessment.

Conclusión:
Se pospone el diseño de /corp.plan hasta disponer de una primera versión funcional de /corp.assess.

#### H-14
Se implementa y valida una primera versión del comando corporativo /corp.assess.

Resultado:
Validado.

Evidencia:

- El comando lee correctamente:
  .specify/memory/active-pbi.md

- Genera un assessment estructurado.

- Clasifica el PBI mediante:
  - READY
  - READY_WITH_RISKS
  - NOT_READY

- Genera checklist de readiness.

- Identifica riesgos, preguntas para PO y supuestos técnicos.

- No crea artefactos de planificación.

- No modifica artefactos existentes.

- No modifica el PBI activo.

Impacto:

Se valida la viabilidad de incorporar una fase explícita de evaluación previa a la planificación técnica.

Decisión:

/corp.assess se convierte en el gate obligatorio entre:

/corp.load
↓
/corp.assess
↓
/corp.plan

Conclusión:

Queda validado el patrón corporativo de comandos read-only para actividades de análisis y gobierno.

#### H-15
Se simplifica y valida /corp.load para el MVP.

Resultado:
Validado.

Decisión:
Para el MVP, /corp.load solo acepta carga desde fichero Markdown local mediante:

/corp.load --file <path-to-pbi-markdown>

Se eliminan del alcance inicial:
- Azure DevOps URL
- MCP
- carga por PBI ID
- creación automática de PBIs de ejemplo
- generación de contenido funcional

Evidencia:
El comando actualiza realmente:

.specify/memory/active-pbi.md

con estructura normalizada de Active PBI, incluyendo:
- Source
- PBI ID
- Title
- Description
- Business Context
- Acceptance Criteria
- Constraints
- Dependencies
- Out of Scope
- Governance Notes

Impacto:
El MVP queda desacoplado de Azure DevOps y puede ser probado por cualquier developer usando un PBI en Markdown.

Conclusión:
El flujo inicial queda validado como:

/corp.load --file <pbi.md>
↓
/corp.assess
↓
/speckit.plan o /corp.plan según resultado de la siguiente validación

#### H-16
Se valida provisionalmente la reutilización de /speckit.plan dentro del MVP corporativo tras ejecutar /corp.load y /corp.assess.

Resultado:
Validado con condición.

Condición:
Para reutilizar /speckit.plan en el MVP, los comandos /speckit.specify y /speckit.clarify deben quedar neutralizados o redirigidos, ya que permitirían saltarse el flujo corporativo basado en PBI aprobado.

Evidencia:
El comando /speckit.plan lee .specify/memory/active-pbi.md y completa la planificación sin requerir /speckit.specify.

Los artefactos revisados mantienen trazabilidad explícita al PBI activo:
- features/pbi-download-shipment-documents/spec.md referencia .specify/memory/active-pbi.md
- features/pbi-download-shipment-documents/plan.md referencia .specify/memory/active-pbi.md

Impacto:
No es necesario implementar /corp.plan para el MVP inicial siempre que se impida el uso de /speckit.specify y /speckit.clarify.

Flujo MVP aceptado:

/corp.load --file <pbi.md>
↓
/corp.assess
↓
/speckit.plan
↓
/speckit.tasks
↓
/speckit.implement

Conclusión:
Para el MVP, se reutiliza /speckit.plan, pero se bloquean /speckit.specify y /speckit.clarify para preservar la gobernanza del flujo.

#### H-17

Se neutralizan los comandos estándar /speckit.specify y /speckit.clarify para proteger el flujo corporativo del MVP.

Resultado:
Validado.

Motivación:
La reutilización de /speckit.plan solo es segura si el developer no puede iniciar el flujo mediante /speckit.specify ni resolver ambigüedades funcionales mediante /speckit.clarify.

Acción realizada:
Se sustituyen los comportamientos estándar de:

- /speckit.specify
- /speckit.clarify

por respuestas corporativas de bloqueo y redirección.

Comportamiento validado:

/speckit.specify responde que está deshabilitado en el flujo corporativo MVP y redirige a:

/corp.load --file <path-to-pbi-markdown>
↓
/corp.assess

/speckit.clarify responde que está deshabilitado en el flujo corporativo MVP y redirige a:

/corp.assess

Decisión:
Para el MVP, /speckit.plan puede reutilizarse siempre que /speckit.specify y /speckit.clarify permanezcan neutralizados.

Flujo MVP protegido:

/corp.load --file <pbi.md>
↓
/corp.assess
↓
/speckit.plan
↓
/speckit.tasks
↓
/speckit.implement

Impacto:
Se evita que el developer genere especificaciones funcionales libres o resuelva ambigüedades funcionales fuera del proceso del Product Owner.

Conclusión:
El MVP queda metodológicamente protegido sin necesidad inicial de implementar /corp.plan.

##### H-18 [VALIDADO]

Se decide implementar /corp.plan como bootstrap corporativo mínimo previo a /speckit.plan, no como sustituto completo del plan estándar de Spec Kit.

Resultado:
Decisión de diseño aprobada.

Motivación:
La sustitución completa de /speckit.plan incrementa demasiado el alcance de la POC y obliga a replicar responsabilidades internas de Spec Kit todavía no suficientemente comprendidas.

Decisión:
Para el MVP, /corp.plan se ejecutará manualmente después de /corp.assess y antes de /speckit.plan.

Responsabilidad de /corp.plan:
- Leer .specify/memory/active-pbi.md
- Crear features/<feature-slug>/
- Crear features/<feature-slug>/spec.md
- Mantener trazabilidad explícita al PBI activo
- No generar plan.md
- No generar artefactos técnicos adicionales
- No modificar alcance funcional
- No modificar criterios de aceptación
- Recomendar /speckit.plan

Impacto:
Se reduce el alcance de la POC, se mantiene la reutilización del flujo estándar de Spec Kit y se protege el punto de entrada funcional mediante una especificación corporativa mínima generada desde el PBI activo.

Decisión adicional:
Se ajustará /speckit.plan para bloquear su ejecución si no detecta previamente un spec.md generado por /corp.plan.

Conclusión:
El flujo MVP protegido queda como:

/corp.load --file <pbi.md>
↓
/corp.assess
↓
/corp.plan
↓
/speckit.plan
↓
/speckit.tasks
↓
/speckit.implement