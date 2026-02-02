# HdU-007: Agregar Atribución-Alcance a Opción

## Información General

- **ID:** HdU-007
- **Módulo:** VII - Mantenedor de Funciones
- **Prioridad:** Alta
- **Estimación:** 3 puntos de historia
- **Actor Principal:** Administrador Nacional

## Historia de Usuario

**Como** Administrador Nacional,  
**Quiero** agregar atribuciones-alcances a una opción existente,  
**Para** definir granularmente los permisos de esa opción dentro de la función.

## Mockups de Referencia

Ver [VII-Mantenedor-Funciones/frontend.md](./frontend.md) - Secciones "AtribucionAlcanceItem" y flujo "4.8 Agregar Atribución-Alcance a Opción".

## Criterios de Aceptación

### AC-001: Botón agregar atrib-alc
**Dado que** OpcionAccordion expandido,  
**Entonces** última fila AtribucionAlcanceItem debe tener botón (+) verde adicional.

### AC-002: Modal agregar atrib-alc
**Cuando** presiono (+),  
**Entonces** sistema abre modal con:
- Dropdown "Seleccione una Atribución"
- Dropdown "Seleccione un Alcance"
- Botón "Agregar" verde

### AC-003: Guardar atrib-alc
**Cuando** selecciono atribución y alcance y presiono "Agregar",  
**Entonces** sistema:
- Valida combo no existe en opción
- POST /api/v1/{rut}-{dv}/funciones/{id}/opciones/{opcionId}/atribuciones-alcances
- Cierra modal
- Muestra: "Registro guardado correctamente"
- Agrega nueva fila AtribucionAlcanceItem

### AC-004: Validar duplicados
**Cuando** combo atrib-alc ya existe,  
**Entonces** sistema muestra: "La combinación ya existe para esta opción".

## Flujos Principales

Ver [VII-Mantenedor-Funciones/frontend.md](./frontend.md) - Sección "4.8 Agregar Atribución-Alcance a Opción".

## Dependencias

- **HdU-002:** Buscar función
- **HdU-005:** Agregar opción
- **Módulos IX, X:** Atribuciones y Alcances

## Estimación

- Frontend: 2 puntos
- Backend: 1 punto
- Total: 3 puntos
