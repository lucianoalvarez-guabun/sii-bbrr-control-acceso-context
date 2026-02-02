# HdU-004: Eliminar Función

## Información General

- **ID:** HdU-004
- **Módulo:** VII - Mantenedor de Funciones
- **Prioridad:** Media
- **Estimación:** 3 puntos de historia
- **Actor Principal:** Administrador Nacional

## Historia de Usuario

**Como** Administrador Nacional,  
**Quiero** eliminar una función completa con todas sus opciones y atribuciones-alcances,  
**Para** remover configuraciones obsoletas o erróneas del sistema permanentemente.

## Mockups de Referencia

Ver [VII-Mantenedor-Funciones/frontend.md](./frontend.md) - Secciones "FuncionSection" y flujo "4.4 Eliminar Función".

## Criterios de Aceptación

### AC-001: Botón eliminar visible
**Dado que** tengo función desplegada,  
**Cuando** observo header de FuncionSection,  
**Entonces** debo ver icono papelera gris extremo derecha (cursor pointer al hover).

### AC-002: Confirmación de eliminación
**Dado que** presiono icono papelera,  
**Entonces** sistema debe mostrar modal: "¿Está seguro que desea eliminar este registro? Perderá toda la información asociada." con botones "Aceptar" (verde) y "Cancelar" (blanco).

### AC-003: Validar función sin usuarios
**Dado que** función NO tiene usuarios asignados,  
**Cuando** confirmo eliminación,  
**Entonces** sistema debe:
- Ejecutar DELETE /api/v1/{rut}-{dv}/funciones/{id}
- Eliminar en cascada: función → opciones → atribuciones-alcances
- Ocultar FuncionSection de vista
- Mostrar mensaje: "Función eliminada correctamente"
- Registrar auditoría

### AC-004: Bloquear eliminación con usuarios
**Dado que** función tiene usuarios asignados,  
**Cuando** confirmo eliminación,  
**Entonces** sistema debe:
- Retornar HTTP 409 Conflict
- Mostrar mensaje: "No se puede eliminar la función porque tiene usuarios asignados. Primero debe reasignar o eliminar los usuarios."
- Mantener función desplegada (NO eliminar)

### AC-005: Cancelar eliminación
**Dado que** modal confirmación está abierto,  
**Cuando** presiono "Cancelar",  
**Entonces** sistema cierra modal sin cambios.

### AC-006: Cascada en base de datos
**Cuando** elimino función,  
**Entonces** sistema debe:
- DELETE FROM FUNCION WHERE id = :id
- Cascada automática con ON DELETE CASCADE:
  - DELETE FROM FUNCION_OPCION WHERE funcion_id = :id
  - DELETE FROM FUNCION_OPCION_ATRIB_ALCANCE WHERE funcion_opcion_id IN (...)
- Auditoría: INSERT "Eliminar función" con nombre eliminado

## Flujos Principales

### Flujo 1: Eliminar función sin usuarios

Ver [VII-Mantenedor-Funciones/frontend.md](./frontend.md) - Sección "4.4 Eliminar Función".

1. Usuario despliega función "Función test" con contador "0" usuarios
2. Usuario presiona icono papelera gris
3. Sistema muestra confirmación
4. Usuario presiona "Aceptar"
5. Sistema valida sin usuarios (contador = 0)
6. Sistema ejecuta DELETE /funciones/123
7. Sistema elimina función y relaciones en cascada
8. Sistema oculta FuncionSection
9. Sistema muestra mensaje: "Función eliminada correctamente"
10. Si usuario busca nuevamente esa función: ya no aparece en dropdown

### Flujo 2: Bloquear eliminación con usuarios

1. Usuario despliega función "Usuario común web" con contador "100"
2. Usuario presiona icono papelera
3. Sistema muestra confirmación
4. Usuario presiona "Aceptar"
5. Sistema detecta 100 usuarios asignados
6. Sistema retorna HTTP 409
7. Sistema muestra error: "No se puede eliminar la función porque tiene usuarios asignados..."
8. Función permanece desplegada sin cambios
9. Usuario debe primero reasignar/eliminar usuarios o desactivar función (HdU-003)

## Dependencias

- **HdU-001:** Crear función (requiere función existente)
- **HdU-002:** Buscar función
- **HdU-003:** Modificar vigencia (alternativa a eliminar)

## Notas Técnicas

- Modal confirmación reutilizable (image-0108)
- Validación usuarios: `SELECT COUNT(*) FROM USUARIO_FUNCION WHERE funcion_id = ?`
- Cascada BD: foreign keys con ON DELETE CASCADE
- Auditoría: registrar nombre función antes de eliminar

## Criterios de Prueba

1. Eliminar función sin usuarios: verificar cascada completa
2. Bloquear eliminación con usuarios: verificar HTTP 409
3. Cancelar eliminación: verificar sin cambios
4. Auditoría: verificar registro eliminación

## Estimación

- Frontend: 1 punto (modal confirmación)
- Backend: 2 puntos (validación usuarios, cascada, auditoría)
- Total: 3 puntos
