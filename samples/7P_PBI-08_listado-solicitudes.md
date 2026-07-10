# Metadatos

- **Tipo:** User Story
- **Título:** Consultar el listado de solicitudes (vista Usuario/Representante, paginado, con "Múltiple" y filtros persistentes)
- **Origen:** `7P_DELTA_v2_previsto` — Unidad(es) de origen: **U3, U4, U6**
- **Documento(s) fuente relacionado(s):** `7P_DELTA_v2_previsto.md` (§6.2, §6.3, D-v2-03, §7, CA-4/CA-7, DT-v2-01) · `7P-Functional_Spec_v1.md` (§5.7) · `7P-Tech_Spec-Backend-API_v1.md` (§7.3, §13.1) · `7P-Tech_Spec-Frontend_v1.md` (§15.2) · `LESSONS.md` (§5.3/§5.4/§5.5)

> ID y Estado se gestionan en la herramienta de backlog, no en este documento.
> Prioridad, estimación y asignación a sprint se definen en Refinamiento/Planning; no se registran en este documento.

---

# Definición

- **Como** usuario o representante de 7P
- **Quiero** ver un listado paginado de mis solicitudes (propias y en las que soy viajero representado), con filtros
- **Para** localizar rápidamente un viaje y acceder a su detalle

---

# Contexto y antecedentes

S1 dejó un `SolicitudListComponent` mínimo con estado vacío. Esta US lo **evoluciona a listado con datos**. En v2 se entrega **solo la vista Usuario/Representante** (D-v2-03); la vista Admin (columnas y filtros propios, orden "Enviado primero") se difiere a **S3** (DT-v2-01), aunque **el backend ya codifica el scoping Admin** porque es la misma consulta.

---

# Descripción y alcance

**Backend — `SolicitudPageQueryFeature` (`GET /Solicitudes`):**
- **Scoping por ownership completo en el handler**, aplicado **siempre antes de cualquier filtro** (empleado: propias + representadas; Admin: todas). **No deshabilitable desde el cliente.**
- Acepta como **contrato estable** los query params `estados`, `paisCodigoExterno`, `fechaViajeDesde/Hasta` y los **Admin** `viajeroUsuarioId`/`creadorUsuarioId`/`filtroTemporal` (aceptados aunque la UI v2 no los use).
- Proyección a `SolicitudListItemDto` con **`esMultiple`** resuelto por agregación SQL (repo de PBI-01).
- **Resolución de etiquetas país/empresa en batch** vía `ResolverEtiquetasAsync` (mock), con **fallback `etiquetasNoResueltas: true` no bloqueante** (API §13.1).

**Frontend — vista Usuario/Representante (spec §5.7):**
- `SolicitudListComponent` (contenedor con datos) + `SolicitudTableComponent` (`MatTable` + `MatPaginator` + `MatSort`).
- **Columnas:** ID/Referencia · País ("Múltiple" si >1) · Fechas · Motivo ("Múltiple") · Empresa ("Múltiple") · Estado (`EstadoBadgeComponent`, mapa de colores completo spec §4.2 aunque en v2 siempre `CREADO`) · **Creada por** (visible solo si la creó un representante) · Última actualización · Acciones.
- **Filtros:** estado (selección múltiple), rango de fechas del viaje, país. **Orden por defecto:** última actualización descendente. **Paginación** server-side (mín. 20/página).
- `MultiplesDestinosPopoverComponent`: al mostrar "Múltiple", abre popover/modal ligero para ver todos los destinos **sin editar**.
- `SolicitudFiltersService`: **filtros persistidos en sesión** (`sessionStorage`, LESSONS §5.3).
- **Estado vacío** contextual ("No tienes solicitudes todavía", LESSONS §5.4), **skeleton** coherente (§5.5) y **scroll contenido** en tabla (§2.5).
- Acceso al **detalle** desde cualquier fila (navega a PBI-09).

## Restricciones y limitaciones de uso

- El **scoping no es deshabilitable** desde el cliente: vive siempre en el handler.
- El **fallback `etiquetasNoResueltas`** no bloquea el listado (etiquetas "best effort" con mock, R-04).

## Validaciones y gestión de errores

- Fallo de resolución de etiquetas → la fila se muestra con el código y `etiquetasNoResueltas: true`, sin romper el listado.

---

# Fuera de alcance

- **Vista RRHH Admin del listado** (columnas Empleado/Compañía; filtros por viajero/creador; filtro temporal; orden "Enviado primero") → **S3** (DT-v2-01). El contrato del endpoint ya la soporta.
- **Contador de pendientes** (§5.8) → S3+.
- **Filtro por compañía/sociedad y búsqueda por texto libre** → no MVP (D10).
- Indicador "Pendiente empleado" (estado `Pdte revisión`) → no ocurre en v2 (solo existe `CREADO`).

---

# Decisiones técnicas y de producto relevantes

- **D-v2-03** — solo vista Usuario/Representante en v2; backend codifica el scoping completo (incl. Admin).
- **spec §5.7** — columnas, filtros, orden, paginación, popover "Múltiple".
- **API §13.1** — resolución de etiquetas en batch + fallback no bloqueante.
- **LESSONS §5.3/§5.4/§5.5** — persistencia de filtros, estado vacío, skeleton.

---

# Criterios de aceptación

- **AC001** (CA-4): El listado muestra **propias + representadas**, paginado server-side, con País/Motivo/Empresa = "Múltiple" y **popover de desglose** cuando hay >1 destino.
- **AC002**: El **scoping por ownership** se aplica siempre en el handler y **no es deshabilitable** desde el cliente; un empleado no ve solicitudes ajenas.
- **AC003** (CA-7): Los filtros (estado, rango de fechas, país) **persisten durante la sesión**.
- **AC004**: El fallback `etiquetasNoResueltas` no bloquea el listado; la fila se muestra igualmente.
- **AC005**: La columna "Creada por" aparece solo cuando la solicitud fue creada por un representante.
- **AC006**: Estado vacío contextual, skeleton coherente y orden por defecto (última actualización desc.).
- **AC007** (CA-9): Compila en modo estricto; ningún fichero fuera del alcance se modifica.

---

# Estrategia sugerida

`SolicitudTableComponent` puramente presentacional: recibe los datos ya filtrados/paginados del contenedor, sin query propia (LESSONS §5.1). El popover y el `EstadoBadge` se implementan reutilizables (el badge lo reusa PBI-09).

---

# Información técnica

## Capas previsiblemente afectadas

- [ ] BD / schema *(usa repo `GetPageAsync` de PBI-01)*
- [x] API / servicio *(`SolicitudPageQueryFeature` + scoping + etiquetas batch)*
- [x] Capa intermedia (hooks / cliente de datos) *(`SolicitudApiService.page`, `SolicitudFiltersService`)*
- [x] Componentes *(`SolicitudListComponent`, `SolicitudTableComponent`, `MultiplesDestinosPopoverComponent`, `EstadoBadgeComponent`)*
- [x] Páginas / rutas *(la ruta `solicitudes` de S1 evoluciona a listado con datos)*
- [ ] Otro

## Especificación técnica

Basada en `7P-Tech_Spec-Backend-API_v1.md` §7.3/§13.1 y `7P-Functional_Spec_v1.md` §5.7. Destinado a Developers.

**Contrato REST estable (§7):** `GET /Solicitudes` → página de `SolicitudListItemDto` (`{ id, paisEtiqueta, motivoEtiqueta, empresaEtiqueta, fechaInicioViaje, fechaFinViaje, estadoActual, viajeroNombre, creadorNombre?, fechaUltimaActualizacion, esMultiple, etiquetasNoResueltas }`), con los query params de §7.3 (Admin aceptados, no expuestos en UI v2). **Extiende `SolicitudApiService`** (método `page`) y los tipos base creados en PBI-06 (añade `SolicitudListItem`).

## Casos de test y validación de funcionamiento

- **TC001**: Empleado con 2 propias + 1 representada → ve 3; no ve ajenas.
- **TC002**: Manipular la petición para intentar ver todas (sin rol) → el scoping del handler lo impide.
- **TC003**: Solicitud con >1 destino → País/Motivo/Empresa = "Múltiple"; popover lista todos los destinos sin permitir edición.
- **TC004**: Aplicar filtros, navegar y volver → los filtros persisten en la sesión.
- **TC005**: Forzar fallo de etiquetas → filas visibles con `etiquetasNoResueltas: true`.
- **TC006**: Sin solicitudes → estado vacío contextual.

---

# Glosario de términos

- **Scoping por ownership**: restricción de resultados a las solicitudes que el usuario puede ver (propias + representadas), aplicada en el servidor.
- **`esMultiple` / "Múltiple"**: la solicitud tiene más de un destino; País/Motivo/Empresa se muestran como "Múltiple".
- **`etiquetasNoResueltas`**: indicador de que la resolución de etiquetas país/empresa (mock) no completó; no bloquea el listado.

---

# Información adicional

Depende de **PBI-06** (base de `SolicitudApiService`/tipos), **PBI-01** (repo `GetPageAsync`) y **PBI-04** (fechas). La vista Admin del listado (DT-v2-01) se recoloca en S3.
