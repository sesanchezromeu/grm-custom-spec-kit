# GRM Corporate Development Constitution

> Constitución del estándar de desarrollo de software corporativo de GRM Group.
> Vinculante para todo proyecto derivado de los templates corporativos (`TEMPLATE_API`, `TEMPLATE_BFF`).
> Este documento fija **qué es obligatorio**; los documentos de estándar referenciados fijan **cómo se implementa**.

## Core Principles

### I. Especificación antes que código (NO NEGOCIABLE)

Ninguna línea de código de producción se escribe sin especificación aprobada previamente.

- La secuencia es estricta: spec funcional → tech specs (BD / API / Frontend) → roadmap → delta previsto → PBIs → implementación. No se salta ninguna fase.
- La **fuente de verdad del sistema** es la documentación (spec + deltas posteriores), no el código. Cuando código y spec divergen, el código está en deuda, no la spec.
- Todo cambio se captura como **delta versionado** (`_previsto` antes de implementar, `_resultante` al cerrar) sobre la base documental consolidada.
- Nada fuera de spec: toda mejora detectada durante la implementación se propone antes de aplicarse y, si se aprueba, se documenta en el delta resultante.

*Racional:* sin este principio el resto del método es decorativo. Es el único gate que impide que la documentación degrade a arqueología.

### II. Herencia del template, desviación explícita

Todo proyecto nace del template corporativo y documenta únicamente sus deltas.

- Prohibido reimplementar lo que el template ya resuelve (bootstrap, DI, interceptores, multitenancy, auditoría, observabilidad, design system).
- Toda desviación respecto al template es un **ADR con identificador canónico** (`ADR-BD-nn`, `ADR-API-nn`, `ADR-FE-nn`), con contexto, decisión, alternativas descartadas, consecuencias y estado (`Propuesto` / `Cerrado`).
- Una desviación que introduzca una dependencia no listada en el catálogo corporativo de paquetes queda en estado `Propuesto` y **requiere validación explícita de Arquitectura** antes de fijarse en el gestor de versiones de dependencias.
- Toda referencia a decisiones, riesgos o restricciones se hace **por su identificador canónico**, nunca parafraseada.

*Racional:* el valor del template es la homogeneidad entre productos. Una desviación no documentada es una bifurcación silenciosa del estándar.

### III. Capas con dependencia unidireccional

La arquitectura en capas del backend es estructural y verificable en build.

- Regla de dependencias: `Domain ← Business ← {Persistence, ExternalServices} ← Host`. Ninguna capa inferior referencia a una superior.
- `Domain` no tiene dependencias externas. `Business` define los contratos (interfaces) que `Persistence` y `ExternalServices` implementan.
- Patrones corporativos obligatorios: CQRS vía Mediator, Feature Modules autodescubiertos, Repository + Unit of Work, resultado funcional (sin excepciones como flujo de control), Options Pattern.
- El **frontend nunca accede a la base de datos** ni conoce URLs de API internas: toda petición va a la misma origin del BFF, que proxifica.
- Las entidades hijas de un *aggregate* se gestionan exclusivamente a través de su raíz; no se crean repositorios propios para ellas.

*Racional:* la separación de capas solo sobrevive si es una restricción de compilación y no una convención de buena voluntad.

### IV. El contrato de API es una frontera pública

Un endpoint publicado es un compromiso, no un detalle de implementación.

- Convención de rutas: `/api/v{version}/{Recurso}`. Los endpoints se registran por descubrimiento automático, nunca manualmente.
- Semántica HTTP normada por la guía corporativa de APIs. Los verbos y códigos de éxito estándar no se reinterpretan por proyecto.
- **Política de breaking changes:** cualquier cambio en ruta, verbo, contrato de request/response o comportamiento observable de un endpoint existente exige una **versión nueva**. Los contratos de versiones activas no se modifican.
- **Contract-First:** el contrato (DTO, endpoint, evento de tiempo real, DDL) se fija en la tech spec antes de que exista un consumidor. Ningún consumidor se codifica contra una firma asumida — se verifica contra el artefacto real.
- La validación de cliente es UX; la **autoridad es siempre el servidor**.

*Racional:* el coste de romper un contrato lo paga un equipo que no participó en la decisión.

### V. Persistencia gobernada

El modelo de datos se rige por la política de la unidad de datos corporativa, sin excepciones tácitas.

- Motor relacional: **MySQL**, en la versión aprobada por el equipo de datos. Cualquier otro motor requiere aprobación previa de dicho equipo.
- Nomenclatura normada y uniforme para tablas, PK, unique constraints, FK e índices. Prefijo de módulo obligatorio en las tablas de cada producto.
- **Tipos de dato:** longitud explícita siempre en campos alfanuméricos. Vetados los tipos de longitud indefinida o binarios masivos. Los ficheros se almacenan en blob storage externo; la base de datos persiste metadatos y referencia, nunca el binario.
- Persistencia **code-first**: el DDL real se genera desde migraciones versionadas. No se definen procedimientos almacenados, funciones ni triggers de negocio.
- Toda tabla de negocio incorpora columnas de auditoría técnica y discriminador de tenant desde su creación.
- Toda excepción a la política se notifica al equipo de datos **antes** de la solicitud de cambio, no durante su ejecución.

*Racional:* la base de datos es el activo con mayor coste de corrección y menor tolerancia al rediseño tardío.

### VI. Seguridad y multitenancy por defecto

No existe el modo "lo aseguramos después".

- Autenticación OIDC/JWT desde el día 1; es bloqueante de secuenciación en cualquier roadmap, no un incremento posterior.
- Multitenancy incorporado desde el diseño inicial aunque el producto arranque con un único tenant. Sin valores de tenant cableados en código o en datos semilla.
- **Autorización de negocio** (rol y propiedad del recurso) resuelta en la capa de aplicación, con el recurso ya cargado. El *scoping* por propiedad se aplica siempre y no es deshabilitable desde el cliente.
- Los secretos residen exclusivamente en el gestor de secretos corporativo. Ningún secreto en repositorio, en fichero de configuración versionado ni en variables de build.
- Los códigos de error distinguen semánticamente entre "no autenticado", "no dado de alta en el producto" y "sin permiso para esta acción", para que el cliente pueda reaccionar de forma distinta a cada uno.

*Racional:* la seguridad retrofit obliga a rediseñar el modelo de datos y el motor de estados, que es exactamente lo que nunca se replanifica.

### VII. Trazabilidad y observabilidad exigibles

Todo sistema debe poder responder "qué pasó, cuándo y quién lo hizo" sin acceso al código.

- **Doble capa de trazabilidad** cuando el dominio lo requiera: auditoría técnica genérica (último cambio: quién y cuándo) e histórico de negocio *append-only* e inmutable (secuencia completa de eventos). La primera no sustituye a la segunda.
- Logging estructurado, health checks de todas las dependencias externas y trazas distribuidas configurados desde la composición del host, no añadidos al final.
- Toda decisión de diseño con consecuencias irreversibles se registra como ADR antes de implementarse.
- Los puntos abiertos y riesgos se **declaran con su clasificación de impacto**; no se resuelven unilateralmente ni se omiten por incomodidad.

*Racional:* un incidente en producción no se diagnostica con buenas intenciones.

## Restricciones tecnológicas

Stack corporativo vinculante. Las versiones concretas se fijan en el gestor centralizado de dependencias de cada template; aquí se fija el **componente**, no el número exacto.

| Capa | Componente | Nota |
|---|---|---|
| API | .NET — **última versión estable con soporte LTS** | Minimal API + Feature Modules |
| Persistencia | ORM code-first + micro-ORM para consultas específicas | Proveedor MySQL |
| Base de datos | **MySQL** | Charset y collation unificados a nivel de esquema |
| Mensajería interna | Mediator (CQRS) | `ICommand` / `IQuery` |
| Validación | Librería de validación fluida | Validadores registrados por ensamblado |
| Mapeo | Librería de mapeo por perfiles | Sin mapeo manual disperso |
| Caché / backplane | Redis | Caché de tenant y escalado de tiempo real |
| Host de presentación | BFF ASP.NET Core | Proxy inverso configurable + inyección de configuración en arranque |
| SPA | Angular (versión alineada al template) + TypeScript | Arquitectura por módulos según el template vigente |
| UI | Angular Material + CDK · Bootstrap · SCSS | Design system corporativo heredado |
| Autenticación cliente | Cliente OIDC estándar | Configuración inyectada en bootstrap, sin rebuild |
| Tiempo real | SignalR | Degradación documentada si el transporte no está disponible |
| Secretos | Gestor de secretos corporativo | Sin secretos en repositorio |
| Observabilidad | Logging estructurado + trazas + health checks | Configurado en composición del host |

**Restricciones adicionales:**

- La versión de cualquier dependencia se gestiona de forma centralizada; no se declaran versiones dispersas por proyecto.
- Una dependencia no presente en el catálogo corporativo requiere ADR en estado `Propuesto` y validación de Arquitectura antes de su fijación.
- Los entornos (desarrollo, preproducción, producción) son configurables por fichero/servicio de configuración. Ninguna URL de entorno se compila en el artefacto.

### User-facing application rule

Unless explicitly stated otherwise in the approved specification, any feature intended for interaction by a business user must be implemented as a corporate web application.

Corporate web applications consist of:

- Angular SPA frontend.
- ASP.NET Core BFF.
- Backend services following the corporate architecture standards.

CLI applications, desktop applications, console utilities, scripts and local executables are not valid delivery mechanisms for end-user functionality unless the approved specification explicitly declares them as the intended user interface.

When a PBI describes user interaction through screens, forms, selections, inputs, calculations, validations or visual results, the default interpretation is a web application workflow implemented using the corporate frontend and BFF templates.

The principle of simplicity cannot be used to replace a required web application with a CLI implementation.

## Flujo de desarrollo y quality gates

### Fases

| Fase | Salida | Gate de salida |
|---|---|---|
| 1 — Especificación funcional | `*-Functional_Spec_v{N}.md` | Aprobación del responsable funcional |
| 2.1 — Especificaciones técnicas | Un documento por capa (BD, API, Frontend) | Aprobación del responsable técnico |
| 2.2 — Consistencia arquitectónica | Veredicto: *coherencia verificada* o *ajustes requeridos* | Sin contradicciones entre capas |
| 3 — Roadmap | `*_Product_Roadmap.md` | Secuenciación validada |
| 4 — Delta previsto | `*_DELTA_v{N}_previsto.md` | **Aprobación explícita antes de implementar** |
| 5 — Backlog | PBIs (uno por fichero) | Trazabilidad completa al delta |
| 6 — Implementación | Código + delta resultante | Verificación unidad por unidad |

### Criterios de secuenciación del roadmap

1. Independencia técnica: la capa de servicio precede a la de presentación.
2. Bloqueadores críticos primero (autenticación, modelo de datos, contratos de integración).
3. Validación temprana: un incremento demostrable lo antes posible.

### Reglas de ejecución

- **Unidad por unidad.** Secuencial. No se inicia la siguiente unidad hasta verificar la actual.
- **Orden de implementación dentro de una unidad:** BD → API → contratos/tipos compartidos → servicios/estado → componentes → páginas → integración.
- **Partición vertical.** Los PBIs se parten como rebanadas verticales de funcionalidad, nunca capa a capa.
- **Sin avance silencioso.** El paso entre unidades, lotes o fases requiere aprobación explícita.
- Si se solicita avanzar sin completar la fase previa, se advierte del incumplimiento y se requiere confirmación razonada.

### Criterios de aceptación de un PBI

Un PBI es admisible en el backlog solo si cumple **todos** los puntos:

- [ ] Deriva de un delta previsto aprobado y es trazable a él.
- [ ] Usa la plantilla corporativa correspondiente a su tipo (historia de usuario / tarea técnica / bug).
- [ ] Tiene criterios de aceptación **testables**, no descriptivos.
- [ ] Tiene estimación realista.
- [ ] Declara sus dependencias y bloqueos conocidos.

### Testing

- Cobertura obligatoria por unidad de: manejadores de negocio, validadores, servicios de acceso a datos, guards de autorización y mapeadores.
- Toda matriz de decisión (estado × rol, permisos, transiciones) se cubre de forma explícita, no por muestreo.
- Casos límite derivados de riesgos declarados en la spec: cobertura obligatoria y nominal.
- Verificación de contrato antes de codificar cualquier consumidor.

### Aprendizaje continuo

Existe un documento vivo de lecciones aprendidas (`LESSONS.md`), de consulta **obligatoria** en tres puntos: al iniciar una especificación funcional, antes de generar un delta previsto y al cerrar un delta resultante. Las lecciones nuevas se incorporan en el cierre del delta resultante.

## Governance

**Supremacía.** Esta constitución prevalece sobre cualquier práctica, costumbre o preferencia individual. Los documentos de estándar corporativo (templates de backend y frontend, guía de APIs, políticas de la unidad de datos) son **normativos por referencia**: esta constitución obliga a cumplirlos y no duplica su contenido. Si un documento de estándar sube de versión, prevalece su versión vigente sin necesidad de enmendar esta constitución.

**Conflictos.** Ante contradicción entre esta constitución y un documento de estándar, prevalece esta constitución y se abre inmediatamente un punto de reconciliación con Arquitectura. Ante contradicción entre dos documentos de estándar, se escala a Arquitectura antes de decidir; nunca se resuelve por criterio local del proyecto.

**Cumplimiento.** Toda revisión de código y de especificación verifica el cumplimiento de los principios I–VII. Un incumplimiento detectado bloquea la aprobación hasta que se corrija o se registre como desviación aprobada con su ADR.

**Excepciones.** Un principio solo se incumple con autorización explícita y razonada del responsable técnico, documentada como ADR con estado, motivo, alcance temporal y plan de retorno al estándar. No existen excepciones tácitas ni permanentes por omisión.

**Complejidad.** Toda complejidad debe justificarse. Ante dos soluciones que satisfacen la especificación, se adopta la más simple. La anticipación de requisitos no especificados no es justificación válida.

**Enmiendas.** Requieren propuesta escrita con motivo e impacto, aprobación de Arquitectura y, cuando afecten a proyectos en curso, plan de migración explícito. Versionado semántico: **MAJOR** = eliminación o redefinición incompatible de un principio; **MINOR** = principio o sección nueva, o ampliación material de una existente; **PATCH** = aclaración de redacción sin cambio normativo.

**Version**: 1.0.0 | **Ratified**: 2026-07-24 | **Last Amended**: 2026-07-24