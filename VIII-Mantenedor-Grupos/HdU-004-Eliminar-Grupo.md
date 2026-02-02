# HdU-004: Eliminar Grupo

## Información General

**ID:** HdU-004  
**Módulo:** VIII - Mantenedor de Grupos  
**Prioridad:** Alta  
**Estimación:** 3 puntos  

## Historia de Usuario

**Como** Administrador Nacional del SII  
**Quiero** eliminar un grupo que ya no se utiliza  
**Para** mantener limpia la base de datos y evitar confusiones con grupos obsoletos  

## Mockups de Referencia

Ver [VIII-Mantenedor-Grupos/frontend.md](./frontend.md) - Sección "Análisis de Mockups" y componente "GroupSection"

## Criterios de Aceptación

**AC-001:** El sistema debe mostrar un botón papelera (icono delete) en el GroupSection junto al nombre del grupo

**AC-002:** Si el grupo tiene usuarios activos (cantidadUsuarios > 0), el botón papelera debe estar deshabilitado (gris) con tooltip "Grupo con usuarios activos"

**AC-003:** Si el grupo NO tiene usuarios activos (cantidadUsuarios = 0), el botón papelera debe estar habilitado (rojo)

**AC-004:** Al hacer clic en botón papelera habilitado, el sistema debe mostrar modal de confirmación (ConfirmDialog) con:
- Icono advertencia (triángulo amarillo)
- Mensaje: "¿Está seguro que desea eliminar el grupo [NOMBRE_GRUPO]? Esta acción no se puede deshacer."
- Botón "Cancelar" (gris)
- Botón "Eliminar" (rojo)

**AC-005:** Si usuario hace clic en "Cancelar", el sistema debe cerrar modal sin ejecutar eliminación

**AC-006:** Si usuario hace clic en "Eliminar", el sistema debe ejecutar DELETE `/{grupoId}` y eliminar:
- Registro en BR_GRUPOS (grupoId)
- Todos los registros en BR_TITULOS (por FK CASCADE)
- Todos los registros en BR_TITULOS_FUNCIONES (por FK CASCADE)
- Registros en BR_USUARIO_GRUPO_ORDEN (si existen)

**AC-007:** Si la eliminación es exitosa (200 OK), el sistema debe:
- Cerrar modal de confirmación
- Mostrar alerta verde "Grupo eliminado exitosamente" por 3 segundos
- Remover el grupo de la lista visual
- Limpiar el área de resultados

**AC-008:** Si el grupo tiene usuarios activos y se intenta eliminar (409 Conflict), el sistema debe mostrar:
- "No se puede eliminar el grupo porque tiene usuarios activos asociados."
- Cerrar modal de confirmación
- Mantener grupo visible

**AC-009:** Si el grupo no existe (404 Not Found), el sistema debe mostrar:
- "Grupo no encontrado. Es posible que ya haya sido eliminado."
- Actualizar lista de grupos

**AC-010:** El sistema debe registrar auditoría con operación='DELETE' incluyendo toda la estructura eliminada (grupo, títulos, funciones)

## Flujos Principales

### Flujo 1: Eliminación Exitosa (Sin Usuarios)

1. Usuario busca grupo "Sistema Test" con filtro "Vigente"
2. Sistema muestra GroupSection con cantidadUsuarios=0
3. Sistema habilita botón papelera (rojo, clickeable)
4. Usuario hace clic en botón papelera
5. Sistema abre modal de confirmación con mensaje: "¿Está seguro que desea eliminar el grupo Sistema Test? Esta acción no se puede deshacer."
6. Usuario hace clic en botón "Eliminar"
7. Sistema cierra modal
8. Sistema ejecuta DELETE `/acaj-ms/api/v1/12.345.678-9/grupos/123`
9. Backend verifica usuarios activos:
   ```sql
   SELECT COUNT(*) FROM BR_USUARIO_GRUPO 
   WHERE USGR_GRUP_ID = 123 AND USGR_ACTIVO = 'S';
   -- Result: 0
   ```
10. Backend ejecuta DELETE con CASCADE:
    ```sql
    DELETE FROM BR_GRUPOS WHERE GRUP_ID = 123;
    -- Cascade elimina automáticamente:
    --   BR_TITULOS (2 registros)
    --   BR_TITULOS_FUNCIONES (5 registros)
    ```
11. Backend registra auditoría:
    ```sql
    INSERT INTO BR_AUDITORIA_CAMBIOS (
      AUDI_OPERACION, AUDI_TABLA, AUDI_REGISTRO_ID,
      AUDI_VALORES_ANTERIORES,
      AUDI_JUSTIFICACION
    ) VALUES (
      'DELETE', 'BR_GRUPOS', 123,
      JSON_OBJECT(
        'nombre' VALUE 'Sistema Test',
        'titulos_eliminados' VALUE 2,
        'funciones_eliminadas' VALUE 5
      ),
      'Se eliminó el grupo Sistema Test (2 títulos, 5 funciones)'
    );
    ```
12. Backend retorna 200 OK:
    ```json
    {
      "mensaje": "Grupo eliminado exitosamente",
      "eliminados": {
        "grupo": 1,
        "titulos": 2,
        "funciones": 5
      }
    }
    ```
13. Sistema muestra alerta "Grupo eliminado exitosamente"
14. Sistema remueve grupo de lista visual
15. Sistema limpia área de resultados mostrando mensaje "Seleccione un grupo para ver detalles"

### Flujo 2: Intento de Eliminar Grupo con Usuarios (409 Conflict)

1. Usuario sigue pasos 1-6 del Flujo 1, pero grupo tiene cantidadUsuarios=100
2. Sistema muestra botón papelera deshabilitado (gris)
3. Usuario hace hover sobre botón papelera
4. Sistema muestra tooltip: "Grupo con usuarios activos"
5. Usuario NO puede hacer clic (botón disabled)

**Caso Edge:** Si usuario intenta eliminar vía API directamente (bypass UI):
1. Backend ejecuta verificación de usuarios activos
2. Backend encuentra 100 usuarios activos
3. Backend lanza ConflictException
4. Backend retorna 409 Conflict:
   ```json
   {
     "error": "Conflicto",
     "mensaje": "No se puede eliminar el grupo porque tiene usuarios activos asociados."
   }
   ```
5. Sistema muestra mensaje de error en alerta roja por 5 segundos

### Flujo 3: Cancelación de Eliminación

1. Usuario sigue pasos 1-5 del Flujo 1
2. Usuario hace clic en botón "Cancelar"
3. Sistema cierra modal ConfirmDialog inmediatamente
4. Sistema NO ejecuta DELETE
5. Sistema mantiene grupo visible sin cambios
6. Usuario puede continuar operando con el grupo

## Notas Técnicas

**API Consumida:**  
- DELETE /acaj-ms/api/v1/{rut}-{dv}/grupos/{grupoId}

**Validaciones:**
- Grupo: debe existir
- Usuarios activos: debe ser 0 (no permitir eliminar grupos con usuarios)
- Usuario: autenticación requerida (RUT en JWT)

**Tablas BD (operación DELETE con CASCADE):**
- BR_GRUPOS: eliminación física del grupo
- BR_TITULOS: eliminación automática por FK CASCADE
- BR_TITULOS_FUNCIONES: eliminación automática por FK CASCADE
- BR_USUARIO_GRUPO_ORDEN: eliminación si existe
- BR_AUDITORIA_CAMBIOS: registro de auditoría (operación DELETE)

**Eliminación en CASCADE:**
- Al eliminar BR_GRUPOS, se eliminan automáticamente todos los títulos (ON DELETE CASCADE)
- Al eliminar BR_TITULOS, se eliminan automáticamente todas las funciones asociadas (ON DELETE CASCADE)

## Dependencias

- BR_GRUPOS (tabla principal)
- BR_TITULOS (eliminación en cascade)
- BR_TITULOS_FUNCIONES (eliminación en cascade)
- BR_USUARIO_GRUPO (verificación de usuarios activos)

## Glosario

- **DELETE CASCADE**: Mecanismo de Oracle que elimina automáticamente registros relacionados cuando se elimina el registro padre
- **Conflict (409)**: Error HTTP que indica que la operación no se puede completar por conflicto de estado (ej: usuarios activos)
- **Soft Delete**: Eliminación lógica (no física) mediante campo activo/inactivo - NO aplicado en este módulo
- **Hard Delete**: Eliminación física del registro de la base de datos - usado en este módulo
