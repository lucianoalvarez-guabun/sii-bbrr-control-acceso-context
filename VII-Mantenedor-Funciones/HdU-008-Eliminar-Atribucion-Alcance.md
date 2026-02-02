# HdU-008: Eliminar Atribución-Alcance

## Información General

- **ID:** HdU-008
- **Módulo:** VII - Mantenedor de Funciones
- **Prioridad:** Media
- **Estimación:** 2 puntos de historia
- **Actor Principal:** Administrador Nacional

## Historia de Usuario

**Como** Administrador Nacional,  
**Quiero** eliminar atribuciones-alcances de una opción,  
**Para** ajustar los permisos específicos sin eliminar toda la opción.

## Mockups de Referencia

Ver [VII-Mantenedor-Funciones/frontend.md](./frontend.md) - Sección "AtribucionAlcanceItem".

## Criterios de Aceptación

### AC-001: Botón eliminar
**Dado que** AtribucionAlcanceItem visible,  
**Entonces** debo ver icono papelera gris derecha.

### AC-002: Confirmación
**Cuando** presiono papelera,  
**Entonces** sistema muestra confirmación estándar.

### AC-003: Eliminar atrib-alc
**Cuando** confirmo eliminación,  
**Entonces** sistema:
- DELETE /api/v1/{rut}-{dv}/funciones/{id}/opciones/{opcionId}/atribuciones-alcances/{id}
- Oculta fila AtribucionAlcanceItem
- Muestra: "Registro eliminado correctamente"

## Flujos Principales

Ver [VII-Mantenedor-Funciones/frontend.md](./frontend.md) - Sección "4.7 Modificar Vigencia de Atribución-Alcance" (similar).

## Dependencias

- **HdU-002:** Buscar función
- **HdU-007:** Agregar atrib-alc

## Estimación

- Frontend: 1 punto
- Backend: 1 punto
- Total: 2 puntos
