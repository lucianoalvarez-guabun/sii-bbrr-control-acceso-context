# HdU-008: Eliminar Función de Título

## Información General

**ID:** HdU-008  
**Módulo:** VIII - Mantenedor de Grupos  
**Prioridad:** Media  
**Estimación:** 2 puntos  

## Historia de Usuario

**Como** Administrador Nacional del SII  
**Quiero** eliminar una función específica de un título  
**Para** ajustar los permisos del título sin tener que eliminarlo completamente  

## Mockups de Referencia

- **image-0127.png**: Lista de funciones con botón eliminar (X) por función
- **image-0034.png**: ConfirmDialog "¿Está seguro que desea eliminar...?"
- **image-0027.png**: Alerta de éxito tras eliminación

## Criterios de Aceptación

**AC-001:** Cada función en la lista (dentro del acordeón del título) debe mostrar un botón eliminar (icono X) al lado derecho

**AC-002:** Al hacer clic en botón eliminar, el sistema debe mostrar modal de confirmación (ConfirmDialog) con:
- Icono advertencia (triángulo amarillo)
- Mensaje: "¿Está seguro que desea eliminar la función [NOMBRE_FUNCION] del título [NOMBRE_TITULO]? Esta acción no se puede deshacer."
- Botón "Cancelar" (gris)
- Botón "Eliminar" (rojo)

**AC-003:** Si usuario hace clic en "Cancelar", el sistema debe cerrar modal sin ejecutar eliminación

**AC-004:** Si usuario hace clic en "Eliminar", el sistema debe:
- Verificar que el título tenga al menos 2 funciones (no permitir eliminar la última)
- Ejecutar DELETE `/{grupoId}/titulos/{tituloId}/funciones/{funcionId}`
- Eliminar registro en BR_TITULOS_FUNCIONES

**AC-005:** Si la eliminación es exitosa (200 OK), el sistema debe:
- Cerrar modal de confirmación
- Mostrar alerta verde "Función eliminada exitosamente" por 3 segundos
- Remover la función de la lista visual del título
- Actualizar contador de funciones del título

**AC-006:** Si el título solo tiene 1 función (última), el botón eliminar debe estar deshabilitado (gris) con tooltip "No se puede eliminar la última función del título"

**AC-007:** Si se intenta eliminar la última función vía API (bypass UI), el sistema debe retornar 409 Conflict:
- "No se puede eliminar la última función del título."

**AC-008:** Si la función no existe o ya fue eliminada (404 Not Found), el sistema debe mostrar:
- "Función no encontrada. Es posible que ya haya sido eliminada."
- Actualizar vista del título

**AC-009:** El sistema debe registrar auditoría con operación='DELETE'

**AC-010:** La eliminación solo afecta la relación (BR_TITULOS_FUNCIONES), NO elimina la función de BR_FUNCIONES (función sigue existiendo para otros títulos)

## Flujos Principales

### Flujo 1: Eliminación Exitosa de Función

1. Usuario busca grupo "Sistema OT" (grupoId=123)
2. Usuario expande título "OT Reportes" (tituloId=45)
3. Sistema muestra 3 funciones:
   - "csdfcasc" (funcionId=15) con botón X habilitado
   - "Función 2" (funcionId=16) con botón X habilitado
   - "Función 3" (funcionId=19) con botón X habilitado
4. Usuario hace clic en botón X de "Función 2"
5. Sistema abre modal ConfirmDialog (image-0034):
   - Icono advertencia
   - Texto: "¿Está seguro que desea eliminar la función 'Función 2' del título 'OT Reportes'? Esta acción no se puede deshacer."
   - Botones: Cancelar, Eliminar
6. Usuario hace clic en botón "Eliminar"
7. Sistema cierra modal
8. Sistema ejecuta DELETE `/acaj-ms/api/v1/12.345.678-9/grupos/123/titulos/45/funciones/16`
9. Backend verifica cantidad de funciones del título:
   ```sql
   SELECT COUNT(*) 
   FROM BR_TITULOS_FUNCIONES 
   WHERE TIFU_TITU_ID = 45;
   -- Result: 3 (OK, tiene más de 1)
   ```
10. Backend ejecuta DELETE:
    ```sql
    DELETE FROM BR_TITULOS_FUNCIONES 
    WHERE TIFU_TITU_ID = 45 AND TIFU_FUNC_ID = 16;
    ```
11. Backend registra auditoría:
    ```sql
    INSERT INTO BR_AUDITORIA_CAMBIOS (
      AUDI_OPERACION, AUDI_TABLA, AUDI_REGISTRO_ID,
      AUDI_VALORES_ANTERIORES, AUDI_JUSTIFICACION
    ) VALUES (
      'DELETE', 'BR_TITULOS_FUNCIONES', NULL,
      JSON_OBJECT(
        'tituloId' VALUE 45,
        'funcionId' VALUE 16,
        'tituloNombre' VALUE 'OT Reportes',
        'funcionNombre' VALUE 'Función 2'
      ),
      'Se eliminó la función Función 2 del título OT Reportes del grupo Sistema OT'
    );
    ```
12. Backend retorna 200 OK:
    ```json
    {
      "mensaje": "Función eliminada exitosamente"
    }
    ```
13. Sistema muestra alerta verde "Función eliminada exitosamente" (image-0027)
14. Sistema remueve "Función 2" de la lista visual
15. Sistema actualiza contador: "OT Reportes (2)" (antes era 3)
16. Funciones restantes: "csdfcasc", "Función 3"

### Flujo 2: Intento de Eliminar Última Función (UI Bloqueado)

1. Usuario busca grupo "Sistema OT" (grupoId=123)
2. Usuario expande título "Título con 1 Función" (tituloId=50)
3. Sistema muestra 1 función:
   - "Función Única" (funcionId=25) con botón X deshabilitado (gris)
4. Usuario hace hover sobre botón X deshabilitado
5. Sistema muestra tooltip: "No se puede eliminar la última función del título"
6. Usuario NO puede hacer clic (botón disabled)

**Caso Edge:** Si usuario intenta eliminar vía API directamente (bypass UI):
1. Backend ejecuta verificación de cantidad de funciones
2. Backend encuentra COUNT=1
3. Backend lanza ConflictException
4. Backend retorna 409 Conflict:
   ```json
   {
     "error": "Conflicto",
     "mensaje": "No se puede eliminar la última función del título."
   }
   ```
5. Sistema muestra mensaje de error en alerta roja por 5 segundos

### Flujo 3: Cancelación de Eliminación

1. Usuario sigue pasos 1-5 del Flujo 1
2. Usuario hace clic en botón "Cancelar"
3. Sistema cierra modal ConfirmDialog inmediatamente
4. Sistema NO ejecuta DELETE
5. Función permanece visible sin cambios
6. Usuario puede continuar operando con la función

### Flujo 4: Función No Existe (404)

1. Usuario sigue pasos 1-8 del Flujo 1
2. Backend ejecuta DELETE pero no encuentra registro (ya eliminado concurrentemente)
3. Backend lanza NotFoundException
4. Backend retorna 404 Not Found:
   ```json
   {
     "error": "No encontrado",
     "mensaje": "Función ID 16 no existe en el título 45"
   }
   ```
5. Sistema muestra mensaje de error en alerta roja por 5 segundos:
   - "Función no encontrada. Es posible que ya haya sido eliminada."
6. Sistema actualiza vista del título (re-ejecuta búsqueda)
7. Función desaparece de lista (si fue eliminada por otro usuario)

## Notas Técnicas

**API Consumida:**  
- DELETE /acaj-ms/api/v1/{rut}-{dv}/grupos/{grupoId}/titulos/{tituloId}/funciones/{funcionId}

**Validaciones:**
- Título: debe existir y pertenecer al grupo
- Función: debe estar asignada al título
- Última función: NO permitir eliminar si es la única función del título (mínimo 1)
- Usuario: autenticación requerida (RUT en JWT)

**Tablas BD (operación DELETE):**
- BR_TITULOS_FUNCIONES: eliminación de la relación título-función
- BR_AUDITORIA_CAMBIOS: registro de auditoría (operación DELETE)

**Impacto:**
- Solo se elimina la relación en BR_TITULOS_FUNCIONES
- BR_FUNCIONES permanece intacto (función sigue existiendo para otros títulos)
- BR_TITULOS permanece intacto (título no se modifica)

**Restricción de última función:**
- Si COUNT(funciones del título) <= 1, el botón eliminar debe estar deshabilitado
- Si se intenta eliminar vía API, retorna 409 Conflict

## Dependencias

- BR_TITULOS (título permanece intacto)
- BR_FUNCIONES (función permanece en catálogo)
- BR_TITULOS_FUNCIONES (tabla de relación M:N)

## Glosario

- **Eliminar relación**: Eliminar solo el vínculo entre título y función (BR_TITULOS_FUNCIONES), NO la función del catálogo
- **Última función**: Restricción de negocio que impide eliminar la única función restante de un título
- **Tooltip**: Mensaje emergente informativo que aparece al hacer hover sobre un elemento
- **Eliminación concurrente**: Caso edge donde 2 usuarios intentan eliminar la misma función simultáneamente (HTTP 404)
