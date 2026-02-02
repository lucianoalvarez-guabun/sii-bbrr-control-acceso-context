# HdU-010: Reordenar Opciones con Drag and Drop

## Información General

- **ID:** HdU-010
- **Módulo:** VII - Mantenedor de Funciones
- **Prioridad:** Baja
- **Estimación:** 3 puntos de historia
- **Actor Principal:** Administrador Nacional

## Historia de Usuario

**Como** Administrador Nacional,  
**Quiero** reordenar opciones de una función con drag and drop,  
**Para** organizarlas según prioridad o frecuencia de uso.

## Mockups de Referencia

Ver [VII-Mantenedor-Funciones/frontend.md](./frontend.md) - Secciones "OpcionAccordion" y flujo "4.10 Reordenar Opciones con Drag and Drop".

## Criterios de Aceptación

### AC-001: Cursor drag
**Dado que** función tiene múltiples opciones,  
**Cuando** hago hover sobre header OpcionAccordion,  
**Entonces** cursor cambia a "grab".

### AC-002: Drag and drop
**Cuando** arrastro OpcionAccordion a nueva posición,  
**Entonces** sistema:
- Muestra indicador visual posición inserción
- Al soltar: reordena opciones visualmente
- PUT /api/v1/{rut}-{dv}/funciones/{id}/opciones/orden con body:
```json
[
  {"opcionId": 456, "orden": 1},
  {"opcionId": 123, "orden": 2}
]
```
- Persiste nuevo orden en BD

### AC-003: Persistencia
**Cuando** recargo página después de reordenar,  
**Entonces** opciones deben aparecer en nuevo orden guardado.

## Flujos Principales

Ver [VII-Mantenedor-Funciones/frontend.md](./frontend.md) - Sección "4.10 Reordenar Opciones con Drag and Drop".

## Dependencias

- **HdU-002:** Buscar función
- **HdU-005:** Agregar opción

## Notas Técnicas

- Librería: Sortable.js o vue-draggable
- Campo BD: FUNCION_OPCION.orden (INTEGER)
- Query ordenamiento: `ORDER BY orden ASC`

## Estimación

- Frontend: 2 puntos (drag and drop, animación)
- Backend: 1 punto (endpoint actualizar orden)
- Total: 3 puntos
