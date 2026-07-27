# E2E Session Resume - 2026-07-27

## Objetivo de la sesión

Continuar la validación E2E de GRM Custom Spec Kit partiendo del instalador funcional generado en la sesión anterior, ejecutar el workflow completo sobre el PBI de calculadora de IVA y valorar si el resultado era adecuado para una demo demostrable.

## Contexto inicial

Se partía de un instalador local ya funcional, capaz de:

- inicializar Spec Kit de forma determinista,
- aplicar la personalización GRM,
- sincronizar runtime estándar y corporativo,
- copiar la constitución,
- generar `installation-report.md`.

Limitación conocida al inicio:

- el instalador dependía de una ruta local de origen (`C:\DEV\PROYS\grm-custom-spec-kit`), por lo que funcionaba en el equipo de Sergio pero no era portable para otros técnicos.

## Prueba E2E ejecutada

Repositorio de prueba:

```text
C:\dev\proys\e2e-try-01
```

Workflow ejecutado correctamente:

```text
corp.load
corp.assess
corp.plan
speckit.plan
speckit.tasks
speckit.implement
corp.doc
```

Artefactos revisados:

- `installation-report.md`
- `spec.md`
- `plan.md`
- `tasks.md`
- `evidence.md`
- `delivery-doc.md`
- `package.json`
- estructura de `frontend/src`
- componentes y servicios principales generados

## Resultado positivo de la prueba

La prueba demostró que el workflow corporativo es capaz de completar el ciclo documental y técnico de extremo a extremo:

```text
PBI -> spec -> plan -> tasks -> implementación -> evidencia -> delivery-doc
```

Conclusiones positivas:

- La instalación fue correcta.
- El runtime corporativo quedó disponible.
- El PBI fue preservado como fuente funcional.
- Los criterios de aceptación se mantuvieron trazables.
- Se generó plan coherente.
- Se generó `tasks.md` estructurado por fases e historias.
- Se generó código TypeScript real.
- Se generaron pruebas unitarias e integración.
- Se generó `evidence.md`.
- Se generó `delivery-doc.md` con hallazgos, riesgos, deuda técnica y backlog de mejora.

## Evidencia técnica observada

`package.json` generado:

```json
{
  "name": "vat-calculator-frontend-poc",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": {
    "test": "vitest run",
    "start": "node ./scripts/start.mjs"
  },
  "devDependencies": {
    "typescript": "^5.9.2",
    "vitest": "^3.2.4"
  }
}
```

Tests generados:

```text
tests/integration/vat-calculator-invalid-input.spec.ts
tests/integration/vat-calculator-ui-states.spec.ts
tests/integration/vat-calculator-valid-flow.spec.ts
tests/unit/vat-calculator-formula.spec.ts
tests/unit/vat-input-validation.spec.ts
tests/unit/vat-services-foundation.spec.ts
```

Estructura funcional generada:

```text
src/app/core/models/
src/app/core/services/
src/app/features/vat-calculator/components/
src/app/features/vat-calculator/pages/
src/app/features/vat-calculator/vat-calculator.routes.ts
```

## Hallazgo principal

### IMPL-E2E-001 - `speckit.implement` genera feature TypeScript validable, pero no aplicación web ejecutable

#### Descripción

La implementación genera lógica, servicios, componentes, HTML, rutas y pruebas, pero no genera una aplicación web arrancable en navegador.

#### Evidencia

No existen artefactos de bootstrap web:

```text
main.ts
angular.json
index.html
app.component.ts
```

El script de arranque ejecuta únicamente:

```text
node ./scripts/start.mjs
```

Salida observada:

```text
VAT Calculator POC workspace ready.
This repository currently validates domain and UI-flow logic through tests.
```

#### Impacto

Alto para demo.

La solución puede ser útil para validar lógica y trazabilidad, pero no sirve para enseñar un resultado funcional a negocio, PMO o dirección.

#### Conclusión

La prueba E2E valida el workflow, pero no valida la generación de una aplicación demostrable.

## Valoración de la calculadora generada

La calculadora no es humo. El código contiene lógica real y coherente:

- cálculo de IVA,
- redondeo,
- formateo con dos decimales,
- validación previa,
- estados `idle`, `loading`, `invalid`, `calculated`,
- separación entre formulario, página, resultado y servicios.

Sin embargo, el resultado es una librería/feature TypeScript testeable, no una aplicación web completa.

Valoración estimada:

| Área | Estado |
|---|---|
| Lógica de cálculo | Correcta |
| Validación | Bien planteada |
| Tests | Presentes |
| Documentación | Buena |
| Trazabilidad | Buena |
| Aplicación web ejecutable | Fallida |
| Utilidad para demo | Insuficiente |

## Decisión sobre la prueba E2E

Se decide no continuar intentando levantar o completar la calculadora generada.

Motivo:

- Que los tests pasen no aporta valor suficiente para una demo.
- El objetivo de la siguiente validación debe ser obtener un resultado visible, ejecutable y mostrable.

Estado de la prueba:

```text
E2E validada como workflow técnico/documental.
E2E no válida como demo funcional mostrable.
```

## Decisión sobre constitución

Se revisó la constitución `GRM Frontend POC Constitution (LITE)`.

Conclusión:

- La constitución actual apunta a Angular, TypeScript, SCSS, Angular Material y reactive forms.
- Aunque declara que el resultado esperado siempre es una aplicación web, el modelo generó una feature testeable pero no una aplicación ejecutable.
- Para una demo E2E, interesa priorizar ejecutabilidad y mostrabilidad sobre fidelidad al stack corporativo.

Decisión propuesta:

- Crear una constitución alternativa específica para E2E demo.
- Stack recomendado: HTML, CSS y JavaScript nativo.
- Objetivo: asegurar que el resultado pueda abrirse en navegador y enseñarse.

Artefacto generado:

```text
GRM-E2E-Demo-Constitution-20260727.md
```

## Próxima línea de trabajo acordada

Retomar el trabajo sobre el instalador.

Objetivo principal:

```text
Convertir el instalador en portable para cualquier técnico.
```

Situación actual:

- El instalador funciona localmente.
- Copia carpetas y ficheros desde una ruta local de Sergio.
- No es adecuado como entregable corporativo.

Objetivo deseado:

- Que el instalador obtenga todos los ficheros necesarios desde Git.
- Que no dependa de `C:\DEV\PROYS\grm-custom-spec-kit`.
- Que pueda ejecutarse en cualquier equipo técnico con Git, Node/Spec Kit y permisos adecuados.

Modelo recomendado:

```text
bootstrap-grm-e2e.ps1
  -> recibe TargetName
  -> clona o descarga grm-custom-spec-kit desde Git
  -> ejecuta specify init --here --integration copilot --script ps --force
  -> aplica personalización GRM
  -> sincroniza runtime
  -> copia constitución
  -> valida estructura
  -> genera installation-report.md
```

## Pendientes para próxima sesión

| Prioridad | Acción | Objetivo |
|---|---|---|
| Alta | Rediseñar instalador para usar Git como fuente | Hacerlo portable |
| Alta | Parametrizar SourceRepoUrl o usar URL por defecto | Evitar dependencias locales |
| Alta | Validar instalación limpia en nuevo directorio | Confirmar repetibilidad |
| Media | Añadir validación de conectividad/repositorio | Mejor diagnóstico de errores |
| Media | Decidir si el instalador se commitea al repositorio | Convertirlo en entregable oficial |
| Media | Preparar siguiente E2E con constitución demo | Obtener app mostrable |

## Estado de hallazgos

| Código | Estado | Comentario |
|---|---|---|
| AUTO-001 | Cerrado | Orden de `specify init` y `git init` corregido |
| AUTO-002 | Cerrado | Inicialización no interactiva con flags |
| AUTO-003 | Cerrado | Eliminada anidación por BAT |
| AUTO-004 | Cerrado | Validación explícita de runtime GRM |
| DF-002 | Prácticamente cerrado | Catálogo y criterios preservados en esta E2E |
| GOV-E2E-006 | Prácticamente cerrado | No se observaron modificaciones indebidas |
| H-005 | Reorientado | La implementación ya genera código, pero no runtime web |
| IMPL-E2E-001 | Nuevo | Feature TypeScript sin aplicación ejecutable |
| INST-PORT-001 | Pendiente | Instalador no portable por dependencia de ruta local |

## Recomendación para reanudar

Comenzar directamente por el instalador portable.

Primera tarea recomendada:

```text
Diseñar la interfaz final del script bootstrap-grm-e2e.ps1
```

Parámetros sugeridos:

```powershell
-TargetName
-SourceRepoUrl
-Branch
-KeepSourceCache
-Force
```

Criterio de éxito de la próxima sesión:

```text
Un técnico puede crear un entorno E2E limpio desde cero usando únicamente el instalador y el repositorio Git remoto, sin copiar manualmente carpetas ni depender de rutas locales de Sergio.
```
