## PBI-POC-02 - Conversión del importe final a moneda de visualización

### Descripción

Como usuario interno,
quiero seleccionar la moneda en la que deseo visualizar el importe final calculado,
para consultar el resultado tanto en euros como en dólares sin modificar el cálculo de IVA existente.

### Objetivo

Validar una segunda iteración funcional sobre una solución ya existente, comprobando que GRM Custom Spec Kit permite evolucionar un producto previamente implementado mediante nuevos PBIs incrementales.

### Dependencias

- Requiere que el PBI-POC-01 esté implementado.
- Reutiliza el cálculo de IVA existente.
- No modifica las reglas de cálculo del IVA.

### Alcance funcional

La solución deberá permitir:
- Mantener toda la funcionalidad existente de cálculo de IVA.
- Incorporar un selector de moneda de visualización.
- Permitir seleccionar:
  - EUR (Euro)
  - USD (Dólar estadounidense)
- Mostrar el importe total en la moneda seleccionada.
- Mostrar la tasa de conversión utilizada.
- Mantener visibles:
  - Importe base.
  - IVA aplicado.
  - Importe IVA.
  - Importe total.

### Reglas de negocio

- El cálculo del IVA siempre se realizará sobre el importe base original.
- La conversión de moneda se aplicará únicamente sobre el importe total calculado.
- Para evitar dependencias externas, se utilizará una tasa fija de conversión.
- Tasa de conversión definida para la POC:
  - 1 EUR = 1,10 USD
- Si la moneda seleccionada es EUR, el importe total se mostrará sin conversión.
- Si la moneda seleccionada es USD, el importe total se convertirá utilizando la tasa fija definida.
- Todos los importes deberán mostrarse con dos decimales.

### Criterios de aceptación

#### CA-01 - Visualización en euros

Dado un importe base de 100
Y un IVA seleccionado del 21 %
Y la moneda EUR
Cuando el usuario calcula el total
Entonces el sistema muestra:
- Importe total: 121,00 EUR
- Tasa de cambio: 1,00

#### CA-02 - Visualización en dólares

Dado un importe base de 100
Y un IVA seleccionado del 21 %
Y la moneda USD
Cuando el usuario calcula el total
Entonces el sistema muestra:
- Importe total original: 121,00 EUR
- Tasa de cambio: 1,10
- Importe convertido: 133,10 USD

#### CA-03 - Cambio de moneda

Dado un cálculo ya realizado
Cuando el usuario cambia de EUR a USD
Entonces el resultado se actualiza utilizando la tasa definida.

#### CA-04 - Conservación del cálculo fiscal

Dado cualquier operación
Cuando se modifica la moneda de visualización
Entonces el importe base y el IVA calculado permanecen inalterados.

#### CA-05 - Redondeo

Dado un resultado con decimales
Cuando se muestra el importe convertido
Entonces el sistema presenta el valor con dos decimales.

### Restricciones técnicas

- La solución debe seguir siendo autocontenida.
- No debe requerir base de datos.
- No debe requerir APIs de divisas.
- No debe requerir acceso a Internet.
- La tasa de conversión será fija y configurable en código.

### Fuera de alcance

- Consulta de tipos de cambio en tiempo real.
- Soporte para más monedas.
- Historial de conversiones.
- Persistencia de preferencias de usuario.
- Integraciones financieras externas.

### Evidencias esperadas

Al finalizar la implementación deberán existir evidencias de:
- Evolución incremental de la solución original.
- Nueva funcionalidad operativa.
- Compatibilidad con el PBI-POC-01.
- Cobertura de criterios de aceptación.
- Decisiones técnicas adoptadas.
- Posible deuda técnica identificada.
