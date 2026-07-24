# E2E Session Resume - 2026-07-24 (Parte 1)

## Objetivo

Continuar la validación E2E de la personalización corporativa de GRM Custom Spec Kit y determinar si el workflow corporativo puede certificarse para uso piloto.

---

# Alcance validado

Workflow ejecutado:

corp.erase
→ corp.load
→ corp.assess
→ corp.plan
→ speckit.plan
→ speckit.tasks
→ speckit.implement
→ corp.doc

---

# Hallazgos cerrados

## H-001
Título:
corp.plan no genera .specify/feature.json

Resultado:
Cerrado.

Corrección:
corp.plan.agent.md actualizado.

Validación:
feature.json generado correctamente y consumido por speckit.plan.

---

## H-002
Título:
Desalineación runtime/extensión

Resultado:
Cerrado.

Causa raíz:
.github/agents contenía versiones antiguas.

Corrección:
Sincronización runtime desde extensions/.

---

## H-003
Título:
corp.assess genera falsos positivos sobre catálogo IVA.

Resultado:
Cerrado.

Corrección:
Nueva regla:

Explicit finite value lists

Validación:
READY_WITH_RISKS sin cuestionar catálogo IVA.

---

## H-004
Título:
Implementación CLI en lugar de aplicación web.

Resultado:
Cerrado.

Causa raíz:
Constitución insuficientemente prescriptiva.

Corrección:
Constitución frontend-only.

Validación:
speckit.plan genera ahora Angular / TypeScript / frontend web.

---

## GOV-E2E-001
Título:
speckit.implement modifica spec.md

Resultado:
Cerrado.

Validación:
spec.md permanece estable tras implement.

---

# Hallazgos abiertos inicialmente

## DF-002
Título:
Pérdida del IVA 4 %

Estado inicial:
Abierto.

Síntoma:
PBI original contiene:

- 0 %
- 4 %
- 10 %
- 21 %

pero planificación e implementación terminan usando:

- 0 %
- 10 %
- 21 %

---

# Investigación DF-002

## Hallazgo intermedio DF-003

Título:
corp.load pierde alcance funcional.

Diagnóstico:

corp.load generaba active-pbi.md resumido.

La sección:

"Alcance funcional"

desaparecía.

Como consecuencia:

corp.plan no podía detectar el catálogo completo.

---

# Correcciones aplicadas

## corp.load.agent.md

Añadida regla:

Full PBI preservation rule

Objetivo:

- preservar el PBI completo
- evitar resúmenes funcionales
- evitar pérdida de catálogos
- copiar el contenido aprobado completo

Runtime sincronizado:
OK

---

## corp.plan.agent.md

Añadida regla:

Explicit business catalogs and value sets

Objetivo:

- preservar listas cerradas
- copiar catálogos funcionales
- evitar pérdida de alcance

Runtime sincronizado:
OK

---

## Constitución

Añadida regla:

Protected Corporate Documentation

Objetivo:

Proteger:

- docs/user-guide.md
- docs/installation-guide.md
- docs/maintenance.md
- docs/architecture.md
- docs/governance.md
- docs/release-checklist.md

frente a modificaciones realizadas por implementaciones funcionales.

---

# Revalidación corp.load

Resultado:

active-pbi.md ahora contiene:

## Alcance funcional

- 0 %
- 4 %
- 10 %
- 21 %

Estado:

DF-003 cerrado.

---

# Estado actual al cerrar esta sesión

## Cerrados

- H-001
- H-002
- H-003
- H-004
- GOV-E2E-001
- DF-003

## Pendientes de revalidar

### DF-002

Objetivo:

Verificar que:

corp.plan

ahora preserva correctamente:

- 0 %
- 4 %
- 10 %
- 21 %

dentro de spec.md.

---

### GOV-E2E-006

Objetivo:

Verificar que la nueva constitución evita que:

speckit.tasks
speckit.implement

modifiquen documentación corporativa.

---

# Próximo paso recomendado

Ejecutar nuevo workflow completo desde:

corp.assess
→ corp.plan
→ speckit.plan
→ speckit.tasks
→ speckit.implement
→ corp.doc

y validar:

1. spec.md conserva catálogo completo 0/4/10/21
2. plan.md conserva catálogo completo
3. implementation conserva catálogo completo
4. delivery-doc conserva catálogo completo
5. docs/user-guide.md no se modifica
6. docs/release-checklist.md no se modifica

---

# Pendiente de propagar a grm-custom-spec-kit

Cambios validados en e2e-validation:

- corp.assess.agent.md
- corp.plan.agent.md
- corp.load.agent.md
- constitution.md

NO propagar todavía.

Primero completar revalidación E2E final.