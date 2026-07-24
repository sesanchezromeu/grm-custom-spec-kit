# GRM Frontend POC Constitution (LITE)

> Variante reducida de la constitución corporativa, acotada a **desarrollo web de solo frontend** (HTML, SCSS, TypeScript/Angular).
> Uso previsto: validación del workflow SDD/speckit sobre un alcance pequeño. **No sustituye a la constitución corporativa completa** en proyectos con backend.
> Fuera de alcance por diseño: API REST, persistencia, infraestructura, despliegue.

## Core Principles

### I. Especificación antes que código (NO NEGOCIABLE)

Se mantiene íntegro respecto a la constitución completa: es el objeto mismo de esta POC.

- Secuencia obligatoria: spec funcional → spec técnica de frontend → delta previsto → PBIs → implementación.
- La fuente de verdad es la documentación, no el código.
- Todo cambio se captura como delta versionado antes de implementarse.
- Nada fuera de spec: toda mejora detectada se propone antes de aplicarse.

### II. Frontera de datos explícita

Aunque no exista backend, la aplicación se construye **como si lo hubiera**.

- Todo dato de dominio se consume a través de un **servicio con contrato tipado** (interfaz TypeScript + modelos). Los componentes nunca conocen el origen del dato.
- La implementación simulada (datos en memoria, fixtures JSON, `delay()` para latencia) vive detrás de esa interfaz y es sustituible por un cliente HTTP real **sin tocar ningún componente**.
- Prohibido el dato de dominio embebido en plantillas o en el propio componente.
- Los modelos se declaran una sola vez y se reutilizan; nada de formas de objeto duplicadas o inferidas ad hoc.

*Racional:* es la única línea que impide que la POC valide un workflow que no sobreviva a la llegada del backend.

### III. Arquitectura de frontend

- Estructura por **feature modules** con carga diferida; un módulo por área funcional.
- Separación estricta: el **componente presenta y orquesta**, el **servicio decide y transforma**. Sin lógica de negocio en plantillas.
- Formularios reactivos. Sin manipulación directa del DOM salvo justificación registrada.
- Tipado estricto activado. `any` requiere justificación explícita en el PBI.
- Estado compartido en servicios con flujo observable; sin estado global implícito ni acoplamiento entre componentes hermanos.

### IV. UI corporativa, accesible y responsive

- Design system corporativo heredado: componentes de la librería estándar antes que componentes propios. Un componente propio solo se crea cuando la librería no cubre el caso, y se justifica.
- Estilos en SCSS con tokens y variables; sin valores de color, espaciado o tipografía cableados en el componente.
- **Responsive obligatorio** en los tres breakpoints (móvil, tablet, escritorio); la verificación visual es criterio de aceptación, no una comprobación posterior.
- Todo listado, tabla o panel declara su **estado vacío** y su **estado de carga**. Los listados largos usan scroll contenido, no crecimiento indefinido.
- Todo error se traduce en un mensaje accionable para el usuario. Nada falla en silencio.

### V. Simplicidad y trazabilidad ligera

- Ante dos soluciones que satisfacen la spec, se adopta la más simple. La anticipación de requisitos no especificados no es justificación válida.
- Las decisiones con consecuencias estructurales (librería nueva, patrón de estado, ruta de navegación) se registran como ADR breve con identificador canónico, incluso en POC.
- Los puntos abiertos se declaran con su impacto; no se resuelven unilateralmente.

## Restricciones tecnológicas

| Componente | Valor |
|---|---|
| Framework | Angular (versión alineada al template corporativo vigente) |
| Lenguaje | TypeScript, modo estricto |
| Estilos | SCSS |
| UI | Angular Material + CDK · Bootstrap |
| Formularios | Reactive Forms |
| Listados | Componentes de tabla, paginador y ordenación de la librería estándar |
| Notificaciones | Librería de toasts del template |
| Datos | **Simulados en cliente** tras interfaz tipada — sin llamadas de red reales |
| Autenticación | **Fuera de alcance.** Si se necesita, se simula un usuario/rol fijo tras un servicio de contexto |

**Explícitamente fuera de alcance:** backend, base de datos, autenticación real, tiempo real, internacionalización, CI/CD, despliegue. Cualquiera de estos elementos que aparezca en una spec debe marcarse como *fuera de alcance de la POC*, no implementarse a medias.

## Flujo de desarrollo y quality gates

### Fases (reducidas)

| Fase | Salida | Gate |
|---|---|---|
| 1 — Spec funcional | `*-Functional_Spec_v{N}.md` | Aprobación |
| 2 — Spec técnica de frontend | `*-Tech_Spec-Frontend_v{N}.md` (documento único) | Aprobación |
| 3 — Delta previsto | `*_DELTA_v{N}_previsto.md` | **Aprobación explícita antes de implementar** |
| 4 — Backlog | PBIs, uno por fichero | Trazables al delta |
| 5 — Implementación | Código + delta resultante | Verificación unidad por unidad |

Roadmap y validación de consistencia entre capas se omiten: con una sola capa no aportan.

### Reglas de ejecución

- **Unidad por unidad**, secuencial. No se inicia la siguiente sin verificar la actual.
- **Orden dentro de una unidad:** modelos/contratos → servicio (con implementación simulada) → componentes → rutas → integración.
- **Partición vertical:** cada PBI entrega una pantalla o flujo completo y demostrable, nunca "todos los modelos" o "todos los servicios".
- **Sin avance silencioso:** el paso entre unidades o fases requiere aprobación explícita.

### Criterios de aceptación de un PBI

- [ ] Deriva de un delta previsto aprobado.
- [ ] Usa la plantilla corporativa de su tipo.
- [ ] Criterios de aceptación testables.
- [ ] Verificación visual en los tres breakpoints.
- [ ] Estados vacío, de carga y de error cubiertos.

### Testing

Cobertura mínima: servicios (con datos simulados), guards, mappers y toda matriz de decisión explícita (estado × rol, visibilidad de acciones). Los componentes se verifican visualmente. Sin exigencia de cobertura porcentual en POC.

## Governance

**Alcance.** Esta variante rige **exclusivamente** proyectos de solo frontend en fase de prueba de concepto. En el momento en que aparezca backend, persistencia o despliegue real, se sustituye por la constitución corporativa completa — no se amplía esta.

**Supremacía.** Prevalece sobre preferencias individuales. El template corporativo de frontend y el design system son normativos por referencia.

**Excepciones.** Solo con autorización explícita y razonada del responsable técnico, registrada como ADR breve con motivo y alcance. No hay excepciones tácitas.

**Deuda declarada.** Todo atajo aceptado por tratarse de una POC se anota como deuda explícita en el delta resultante, con la condición que lo haría inaceptable en producción. Una POC sin deuda declarada es una POC que miente.

**Enmiendas.** Versionado semántico, con sufijo `-lite` para distinguir el linaje. MAJOR = redefinición incompatible de un principio; MINOR = principio o sección nueva; PATCH = aclaración de redacción.

**Version**: 1.0.0-lite | **Ratified**: 2026-07-24 | **Last Amended**: 2026-07-24
