# PBI-POC-01 - Calculadora simple de importe con IVA

## Descripción

Como usuario interno,
quiero introducir un importe base y seleccionar un tipo de IVA,
para obtener el importe total calculado de forma automática.

## Objetivo

Crear una funcionalidad sencilla, autocontenida y verificable que permita validar el flujo completo de GRM Custom Spec Kit desde la carga del PBI hasta la implementación y documentación final.

## Alcance funcional

La solución deberá permitir:

1. Introducir un importe base numérico.
2. Seleccionar un tipo de IVA entre:
   - 0 %
   - 4 %
   - 10 %
   - 21 %
3. Calcular el importe total aplicando el IVA seleccionado.
4. Mostrar:
   - Importe base.
   - Porcentaje de IVA aplicado.
   - Importe del IVA.
   - Importe total.
5. Validar que el importe base sea un número mayor o igual que cero.

## Reglas de negocio

- Si el importe base es vacío, negativo o no numérico, se deberá mostrar un mensaje de validación.
- El cálculo será:

  Importe IVA = Importe base × Porcentaje IVA / 100

  Importe total = Importe base + Importe IVA

- Los importes deberán mostrarse con dos decimales.

## Criterios de aceptación

### CA-01 - Cálculo con IVA general

Dado un importe base de 100  
Y un IVA seleccionado del 21 %  
Cuando el usuario calcula el total  
Entonces el sistema muestra:
- Importe base: 100,00
- IVA: 21 %
- Importe IVA: 21,00
- Importe total: 121,00

### CA-02 - Cálculo con IVA reducido

Dado un importe base de 50  
Y un IVA seleccionado del 10 %  
Cuando el usuario calcula el total  
Entonces el sistema muestra:
- Importe base: 50,00
- IVA: 10 %
- Importe IVA: 5,00
- Importe total: 55,00

### CA-03 - Cálculo con IVA cero

Dado un importe base de 80  
Y un IVA seleccionado del 0 %  
Cuando el usuario calcula el total  
Entonces el sistema muestra:
- Importe base: 80,00
- IVA: 0 %
- Importe IVA: 0,00
- Importe total: 80,00

### CA-04 - Validación de importe negativo

Dado un importe base de -10  
Cuando el usuario intenta calcular el total  
Entonces el sistema muestra un mensaje indicando que el importe debe ser mayor o igual que cero.

### CA-05 - Validación de importe no numérico

Dado un importe base no numérico  
Cuando el usuario intenta calcular el total  
Entonces el sistema muestra un mensaje indicando que el importe debe ser numérico.

## Restricciones técnicas

- La solución debe ser autocontenida.
- No debe requerir base de datos.
- No debe requerir servicios externos.
- No debe requerir autenticación.
- Debe poder ejecutarse y verificarse localmente.

## Fuera de alcance

- Persistencia de operaciones.
- Gestión de usuarios.
- Integración con sistemas fiscales reales.
- Configuración dinámica de tipos impositivos.
- Internacionalización avanzada.
- Exportación de resultados.

## Evidencias esperadas

Al finalizar la implementación deberán existir evidencias de:

- Funcionalidad implementada.
- Pruebas o validaciones básicas realizadas.
- Criterios de aceptación cubiertos.
- Desviaciones respecto al PBI, si las hubiera.
- Deuda técnica identificada, si la hubiera.