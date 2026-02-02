# HdU-006: Eliminar Opción de Función

## Información General

- **ID:** HdU-006
- **Módulo:** VII - Mantenedor de Funciones
- **Prioridad:** Media
- **Estimación:** 3 puntos de historia
- **Actor Principal:** Administrador Nacional

## Historia de Usuario

**Como** Administrador Nacional,  
**Quiero** eliminar opciones de una función,  
**Para** remover permisos que ya no deben estar asociados a esa función.

## Mockups de Referencia

Ver [VII-Mantenedor-Funciones/frontend.md](./frontend.md) - Secciones "OpcionAccordion" y flujo "4.6 Eliminar Opción de Función".

## Criterios de Aceptación

### AC-001: Botón eliminar opción
**Dado que** OpcionAccordion está visible,  
**Entonces** debo ver icono papelera gris en header.

### AC-002: Confirmación
**Cuando** presiono papelera,  
**Entonces** sistema muestra: "¿Está seguro que desea eliminar este registro? Perderá toda la información asociada."

### AC-003: Eliminar sin usuarios
**Cuando** opción NO tiene usuarios y confirmo,  
**Entonces** sistema:
- DELETE /api/v1/{rut}-{dv}/funciones/{id}/opciones/{opcionId}
- Elimina opción y todas sus atribuciones-alcances
- Oculta OpcionAccordion
- Muestra: "Opción eliminada correctamente"

### AC-004: Bloquear con usuarios
**Cuando** opción tiene usuarios,  
**Entonces** sistema muestra: "No se puede eliminar la opción porque tiene usuarios asignados."

## Flujos Principales

Ver [VII-Mantenedor-Funciones/frontend.md](./frontend.md) - Sección "4.6 Eliminar Opción de Función".

## Dependencias

- **HdU-002:** Buscar función
- **HdU-005:** Agregar opción

## Estimación

- Frontend: 1 punto
- Backend: 2 puntos (validación usuarios, cascada)
- Total: 3 puntos
