# HdU-005: Agregar Opción a Función

## Información General

- **ID:** HdU-005
- **Módulo:** VII - Mantenedor de Funciones
- **Prioridad:** Alta
- **Estimación:** 5 puntos de historia
- **Actor Principal:** Administrador Nacional

## Historia de Usuario

**Como** Administrador Nacional,  
**Quiero** agregar opciones de aplicativos a una función existente con múltiples atribuciones-alcances,  
**Para** expandir los permisos que proporciona la función a los usuarios.

## Mockups de Referencia

Ver [VII-Mantenedor-Funciones/frontend.md](./frontend.md) - Sección "2.5 OpcionAccordion" y flujo "4.5 Agregar Opción a Función".

## Criterios de Aceptación

### AC-001: Botón agregar opción
**Dado que** función está desplegada,  
**Entonces** debo ver botón (+) verde al final de lista de opciones.

### AC-002: Modal agregar opción
**Cuando** presiono botón (+),  
**Entonces** sistema abre modal "Agregar opción a la función" con:
- Dropdown "Seleccione una Opción" (opciones NO usadas en esta función)
- Dropdown "Seleccione una Atribución"
- Dropdown "Seleccione un Alcance"
- Botón (+) verde para agregar más filas atrib-alc
- Botones "Agregar" (verde) y X (cerrar)

### AC-003: Agregar múltiples atribuciones-alcances
**Cuando** selecciono opción, atribución y alcance,  
**Y** presiono botón (+) interno,  
**Entonces** sistema agrega nueva fila con dropdowns vacíos para segunda atrib-alc.

### AC-004: Guardar opción
**Cuando** completo datos y presiono "Agregar",  
**Entonces** sistema:
- Valida opción no existe en función
- Valida atrib-alc únicos (no duplicados)
- POST /api/v1/{rut}-{dv}/funciones/{id}/opciones con body:
```json
{
  "opcionId": 456,
  "atribucionesAlcances": [
    {"atribucionId": 1, "alcanceId": 1},
    {"atribucionId": 2, "alcanceId": 2}
  ]
}
```
- Cierra modal
- Muestra mensaje: "Registro guardado correctamente"
- Agrega nuevo OpcionAccordion expandido a función

### AC-005: Validar duplicados
**Cuando** intento agregar opción que ya existe,  
**Entonces** sistema muestra: "La opción ya existe para esta función".

## Flujos Principales

Ver [VII-Mantenedor-Funciones/frontend.md](./frontend.md) - Sección "4.5 Agregar Opción a Función".

1. Usuario presiona (+) al final de opciones
2. Modal abre con dropdowns vacíos
3. Usuario selecciona opción "F2890: Mantenedor Unidades"
4. Usuario selecciona atribución "RE - Registro", alcance "R - Regional"
5. Usuario presiona (+) interno para agregar segunda atrib-alc
6. Sistema agrega fila nueva
7. Usuario selecciona atribución "AR - Archivo", alcance "N - Nacional"
8. Usuario presiona "Agregar"
9. Sistema valida y guarda opción con 2 atrib-alc
10. Sistema cierra modal y actualiza función con nuevo OpcionAccordion

## Dependencias

- **HdU-001:** Crear función
- **HdU-002:** Buscar función
- **Módulo XI:** Opciones disponibles

## Estimación

- Frontend: 3 puntos (modal complejo, filas dinámicas)
- Backend: 2 puntos (validación, transacción múltiple)
- Total: 5 puntos
