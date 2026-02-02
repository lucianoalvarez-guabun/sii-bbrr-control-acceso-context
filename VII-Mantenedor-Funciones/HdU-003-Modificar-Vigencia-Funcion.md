# HdU-003: Modificar Vigencia de Función

## Información General

- **ID:** HdU-003
- **Módulo:** VII - Mantenedor de Funciones
- **Prioridad:** Alta
- **Estimación:** 3 puntos de historia
- **Actor Principal:** Administrador Nacional

## Historia de Usuario

**Como** Administrador Nacional del Sistema Control de Acceso,  
**Quiero** modificar la vigencia de una función (activar/desactivar),  
**Para** controlar el acceso de usuarios a opciones específicas sin eliminar la configuración permanentemente.

## Mockups de Referencia

Ver [VII-Mantenedor-Funciones/frontend.md](./frontend.md) - Sección "Análisis de Mockups" y componente "FuncionSection".

## Criterios de Aceptación

### AC-001: Visualizar estado actual de vigencia
**Dado que** tengo una función desplegada,  
**Cuando** observo el header de FuncionSection,  
**Entonces** el sistema debe:
- Mostrar toggle vigencia en color verde si función está vigente
- Mostrar texto "Vigente" en toggle verde
- Mostrar toggle vigencia en color naranja si función no está vigente
- Mostrar texto "No Vigente" en toggle naranja
- Toggle debe ser clickeable (cursor pointer al hover)

### AC-002: Desactivar función vigente
**Dado que** tengo una función vigente desplegada,  
**Cuando** hago clic en el toggle para cambiar de "Vigente" a "No Vigente",  
**Entonces** el sistema debe:
- Si función NO tiene usuarios asignados:
  - Cambiar toggle a naranja "No Vigente" inmediatamente
  - Ejecutar PUT /api/v1/{rut}-{dv}/funciones/{id}/vigencia con body: {vigente: false}
  - Mostrar mensaje: "Vigencia de función actualizada correctamente"
  - Propagar cambio en cascada: desactivar todas las opciones y atribuciones-alcances
  - Actualizar toggles de opciones y atribuciones-alcances a naranja

### AC-003: Advertencia al desactivar función con usuarios
**Dado que** tengo una función vigente con usuarios asignados,  
**Cuando** intento cambiar toggle a "No Vigente",  
**Entonces** el sistema debe:
- Mostrar modal de confirmación: "Esta función tiene [N] usuarios asignados. Al desactivarla, los usuarios perderán acceso. ¿Desea continuar?"
- Botones: "Continuar" (verde) y "Cancelar" (blanco)
- Si usuario presiona "Cancelar": cerrar modal sin cambios, toggle permanece en "Vigente"
- Si usuario presiona "Continuar": desactivar función, mostrar mensaje "Vigencia actualizada"

### AC-004: Activar función no vigente
**Dado que** tengo una función no vigente desplegada,  
**Cuando** hago clic en el toggle para cambiar de "No Vigente" a "Vigente",  
**Entonces** el sistema debe:
- Cambiar toggle a verde "Vigente"
- Ejecutar PUT /api/v1/{rut}-{dv}/funciones/{id}/vigencia con body: {vigente: true}
- Mostrar mensaje: "Vigencia de función actualizada correctamente"
- NO activar automáticamente opciones y atribuciones-alcances (mantienen su estado individual)

### AC-005: Cascada al desactivar función
**Dado que** desactivo una función vigente,  
**Cuando** la función tiene 2 opciones con 3 atribuciones-alcances cada una,  
**Entonces** el sistema debe:
- Desactivar función (vigente = false)
- Desactivar en cascada las 2 opciones (vigente = false)
- Desactivar en cascada las 6 atribuciones-alcances (vigente = false)
- Actualizar todos los toggles visuales a naranja
- Registrar auditoría para función y cada elemento desactivado

### AC-006: Persistencia en base de datos
**Dado que** modifico la vigencia de una función,  
**Cuando** el sistema guarda el cambio,  
**Entonces** debe:
- UPDATE FUNCION SET vigente = :vigente, fecha_modificacion = SYSDATE, usuario_modificacion = :rut WHERE id = :id
- Si desactivar: UPDATE FUNCION_OPCION SET vigente = 0 WHERE funcion_id = :id
- Si desactivar: UPDATE FUNCION_OPCION_ATRIB_ALCANCE SET vigente = 0 WHERE funcion_opcion_id IN (SELECT id FROM FUNCION_OPCION WHERE funcion_id = :id)
- Registrar auditoría: INSERT INTO AUDITORIA_FUNCIONES (accion, descripcion, usuario, fecha) VALUES ('Modificar vigencia', 'Se desactivó función [nombre]', :rut, SYSDATE)

### AC-007: Actualización visual inmediata
**Dado que** modifico la vigencia de una función,  
**Cuando** el backend confirma el cambio,  
**Entonces** el sistema debe:
- Actualizar toggle de función inmediatamente (sin refrescar página)
- Si desactivar: actualizar todos los toggles de opciones y atribuciones-alcances
- Mantener función desplegada (NO colapsar)
- Mantener estado de acordeones (expandidos/colapsados)

### AC-008: Validación de permisos
**Dado que** soy un usuario autenticado,  
**Cuando** intento modificar vigencia de una función,  
**Entonces** el sistema debe:
- Si perfil Administrador Nacional: permitir modificación, toggle habilitado
- Si perfil Consulta: NO mostrar toggle (solo texto "Vigente" o "No Vigente")
- Si intento modificar vía API sin permisos: retornar HTTP 403 Forbidden

### AC-009: Manejo de errores de actualización
**Dado que** intento modificar vigencia de una función,  
**Cuando** ocurre un error en el backend,  
**Entonces** el sistema debe:
- Si error 404: mostrar "Función no encontrada"
- Si error 500: mostrar "Error al actualizar vigencia. Intente nuevamente."
- Revertir toggle a estado anterior (no dejar inconsistencia visual)
- Permitir reintentar la operación

### AC-010: Impacto en búsqueda
**Dado que** desactivo una función vigente,  
**Cuando** vuelvo al SearchBar con filtro "Vigente",  
**Entonces** el sistema debe:
- Recargar dropdown funciones vigentes (GET /funciones?vigente=true)
- Función desactivada ya NO debe aparecer en dropdown vigentes
- Si cambio filtro a "No Vigente": función desactivada DEBE aparecer en dropdown

### AC-011: Impacto en usuarios asignados
**Dado que** desactivo una función con usuarios asignados,  
**Cuando** los usuarios intentan acceder a opciones de esa función,  
**Entonces** el sistema debe:
- Bloquear acceso de usuarios a opciones de función no vigente
- Mostrar mensaje: "No tiene permisos para acceder a esta opción"
- Usuarios mantienen asignación (no se elimina relación, solo se desactiva acceso)

### AC-012: Auditoría completa
**Dado que** modifico vigencia de una función,  
**Cuando** el sistema registra el cambio,  
**Entonces** debe guardar en auditoría:
- Fecha y hora (DD/MM/YYYY - HH:MM)
- Evento: "Modificar vigencia función"
- Descripción: "Se desactivó función Mantención general" o "Se activó función Mantención general"
- RUT funcionario que ejecutó acción
- Nombre funcionario
- Ubicación (unidad del funcionario)
- Nro ticket (si aplica)
- Autorización subdirector (Sí/No, si aplica)

## Flujos Principales

### Flujo 1: Desactivar función sin usuarios

Ver [VII-Mantenedor-Funciones/frontend.md](./frontend.md) - Sección "4.3 Modificar Vigencia de Función".

**Precondición:** Función vigente sin usuarios asignados desplegada

1. Usuario observa función "Mantención general" con toggle Vigente verde
2. Usuario hace clic en toggle para cambiar a "No Vigente"
3. Sistema valida que función NO tiene usuarios asignados (contador "0")
4. Sistema ejecuta PUT /api/v1/{rut}-{dv}/funciones/123/vigencia con {vigente: false}
5. Sistema actualiza vigencia en BD: función, opciones y atribuciones-alcances
6. Sistema cambia toggle función a naranja "No Vigente"
7. Sistema cambia toggles de todas las opciones a naranja
8. Sistema cambia toggles de todas las atribuciones-alcances a naranja
9. Sistema muestra mensaje: "Vigencia de función actualizada correctamente"
10. Usuario presiona "Aceptar" en mensaje
11. Función permanece desplegada con todos los toggles naranja

### Flujo 2: Desactivar función con usuarios (confirmación)

**Precondición:** Función vigente con 100 usuarios asignados desplegada

1. Usuario observa función "Usuario común web" con toggle Vigente verde y contador "100"
2. Usuario hace clic en toggle para cambiar a "No Vigente"
3. Sistema detecta que función tiene 100 usuarios asignados
4. Sistema muestra modal confirmación: "Esta función tiene 100 usuarios asignados. Al desactivarla, los usuarios perderán acceso. ¿Desea continuar?"
5. Usuario revisa mensaje y decide continuar
6. Usuario presiona botón "Continuar" verde
7. Sistema cierra modal
8. Sistema ejecuta PUT /api/v1/{rut}-{dv}/funciones/456/vigencia con {vigente: false}
9. Sistema desactiva función y opciones en cascada
10. Sistema actualiza todos los toggles a naranja
11. Sistema muestra mensaje: "Vigencia de función actualizada correctamente"
12. 100 usuarios pierden acceso a opciones de esta función inmediatamente

### Flujo 3: Cancelar desactivación con usuarios

**Precondición:** Función vigente con 50 usuarios desplegada

1. Usuario hace clic en toggle Vigente para cambiar a "No Vigente"
2. Sistema muestra modal: "Esta función tiene 50 usuarios asignados. Al desactivarla, los usuarios perderán acceso. ¿Desea continuar?"
3. Usuario revisa mensaje y decide NO continuar
4. Usuario presiona botón "Cancelar" blanco
5. Sistema cierra modal
6. Toggle permanece en "Vigente" verde (sin cambios)
7. Función mantiene 50 usuarios con acceso

### Flujo 4: Activar función no vigente

Ver [VII-Mantenedor-Funciones/frontend.md](./frontend.md) - Sección "4.3 Modificar Vigencia de Función" - Variante "Activar Función No Vigente".

**Precondición:** Función no vigente desplegada con opciones no vigentes

1. Usuario busca función no vigente "Función antigua" con filtro "No Vigente"
2. Sistema despliega función con toggle naranja "No Vigente"
3. Opciones y atribuciones-alcances también tienen toggles naranja
4. Usuario hace clic en toggle función para cambiar a "Vigente"
5. Sistema ejecuta PUT /api/v1/{rut}-{dv}/funciones/789/vigencia con {vigente: true}
6. Sistema actualiza función a vigente en BD
7. Sistema cambia toggle función a verde "Vigente"
8. Opciones y atribuciones-alcances mantienen sus toggles naranja (NO se activan automáticamente)
9. Sistema muestra mensaje: "Vigencia de función actualizada correctamente"
10. Usuario debe activar manualmente cada opción y atribución-alcance si desea

## Dependencias

### Módulos/HdU Previos Requeridos
- **HdU-001:** Crear función (requiere función existente)
- **HdU-002:** Buscar función (para desplegar función antes de modificar)
- **Módulo V - HdU usuarios:** Asignar función a usuario (para casos con usuarios asignados)

### Módulos/HdU que Dependen de Esta
- **HdU-004:** Eliminar función (alternativa a desactivar)
- **HdU-009:** Ver usuarios (validar usuarios antes de desactivar)

## Notas Técnicas

### Frontend
- Modal confirmación reutilizable (mismo componente que eliminar)
- Toggle animado con transición CSS (verde ↔ naranja, 200ms)
- Actualización optimista del UI (cambiar toggle antes de respuesta API)
- Si API falla: revertir toggle a estado anterior

### Backend
- Endpoint: PUT /api/v1/{rut}-{dv}/funciones/{id}/vigencia
- Request body: `{"vigente": true|false}`
- Response 200: `{"mensaje": "Vigencia actualizada", "usuariosAfectados": 100}`
- Transacción atómica: UPDATE función → UPDATE opciones → UPDATE atrib-alc
- Query cascada: `UPDATE FUNCION_OPCION SET vigente = 0 WHERE funcion_id = ?`
- Contar usuarios antes de desactivar: `SELECT COUNT(*) FROM USUARIO_FUNCION WHERE funcion_id = ? AND vigente = 1`

### Base de Datos
- Índices: idx_funcion_vigente (vigente), idx_usuario_funcion_funcion_vigente (funcion_id, vigente)
- Trigger NO requerido (lógica en backend)
- Auditoría manual con INSERT en cada UPDATE

## Criterios de Prueba

1. **Desactivar función sin usuarios:** Verificar cascada a opciones y atrib-alc
2. **Desactivar función con usuarios:** Verificar modal confirmación
3. **Cancelar desactivación:** Verificar que toggle NO cambia
4. **Activar función no vigente:** Verificar que opciones NO se activan automáticamente
5. **Impacto en búsqueda:** Verificar que función desactivada desaparece de filtro vigentes
6. **Permisos consulta:** Verificar que toggle NO es clickeable
7. **Auditoría:** Verificar registro en tabla AUDITORIA_FUNCIONES

## Estimación Detallada

- **Frontend:** 2 puntos (toggle, modal confirmación, cascada visual)
- **Backend:** 1 punto (endpoint PUT, transacción cascada, contar usuarios)
- **Total:** 3 puntos de historia
