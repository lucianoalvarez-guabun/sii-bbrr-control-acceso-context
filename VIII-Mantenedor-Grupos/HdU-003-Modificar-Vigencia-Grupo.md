# HdU-003: Modificar Vigencia de Grupo

## Información General

**ID:** HdU-003  
**Módulo:** VIII - Mantenedor de Grupos  
**Prioridad:** Media  
**Estimación:** 2 puntos  

## Historia de Usuario

**Como** Administrador Nacional del SII  
**Quiero** activar o desactivar la vigencia de un grupo  
**Para** controlar qué grupos están disponibles para asignación a usuarios sin eliminarlos permanentemente  

## Mockups de Referencia

- **image-0127.png**: GroupSection mostrando toggle vigente (switch on/off)
- **image-0027.png**: Alerta de éxito "Registro guardado correctamente"

## Criterios de Aceptación

**AC-001:** El sistema debe mostrar un toggle (switch) de vigencia en el GroupSection junto al nombre del grupo

**AC-002:** Si el grupo está vigente (GRUP_VIGENTE='S'), el switch debe estar activado (ON, color verde)

**AC-003:** Si el grupo NO está vigente (GRUP_VIGENTE='N'), el switch debe estar desactivado (OFF, color gris)

**AC-004:** Al hacer clic en el switch, el sistema debe cambiar el estado de vigencia de forma inmediata (sin confirmación)

**AC-005:** El sistema debe ejecutar PUT `/{grupoId}/vigencia` con el nuevo valor ('S' o 'N')

**AC-006:** Si la actualización es exitosa (200 OK), el sistema debe:
- Actualizar visualmente el switch al nuevo estado
- Mostrar alerta verde "Registro guardado correctamente" por 3 segundos
- Registrar auditoría con operación='UPDATE'

**AC-007:** Si el grupo tiene usuarios activos (cantidadUsuarios > 0) y se intenta cambiar a NO vigente, el sistema debe permitir el cambio con advertencia posterior

**AC-008:** Si ocurre un error de servidor (500), el sistema debe:
- Revertir el switch a su estado anterior
- Mostrar mensaje "Error al actualizar vigencia. Intente nuevamente."

**AC-009:** El cambio de vigencia NO debe afectar las asignaciones existentes de usuarios al grupo (BR_USUARIO_GRUPO permanece intacto)

**AC-010:** El sistema debe actualizar automáticamente el dropdown de búsqueda si el grupo ya no cumple el filtro vigente actual

## Flujos Principales

### Flujo 1: Cambiar de Vigente a No Vigente

1. Usuario busca grupo "Sistema OT" con filtro "Vigente" (vigente='S')
2. Sistema muestra GroupSection con switch vigente activado (verde, ON)
3. Usuario hace clic en switch
4. Sistema cambia visualmente switch a OFF (gris)
5. Sistema ejecuta PUT `/acaj-ms/api/v1/12.345.678-9/grupos/123/vigencia` con body:
   ```json
   { "vigente": "N" }
   ```
6. Backend valida grupo existe
7. Backend ejecuta UPDATE en BR_GRUPOS:
   ```sql
   UPDATE BR_GRUPOS 
   SET GRUP_VIGENTE = 'N',
       GRUP_FECHA_MODIFICACION = SYSDATE,
       GRUP_USUARIO_MODIFICACION = '12.345.678-9'
   WHERE GRUP_ID = 123;
   ```
8. Backend registra auditoría:
   ```sql
   INSERT INTO BR_AUDITORIA_CAMBIOS (
     AUDI_OPERACION, AUDI_TABLA, AUDI_REGISTRO_ID,
     AUDI_VALORES_ANTERIORES, AUDI_VALORES_NUEVOS,
     AUDI_JUSTIFICACION
   ) VALUES (
     'UPDATE', 'BR_GRUPOS', 123,
     JSON_OBJECT('vigente' VALUE 'S'),
     JSON_OBJECT('vigente' VALUE 'N'),
     'Se modificó la vigencia del Grupo Sistema OT a No Vigente'
   );
   ```
9. Backend retorna 200 OK:
   ```json
   {
     "mensaje": "Vigencia actualizada",
     "grupoId": 123,
     "nuevaVigencia": "N"
   }
   ```
10. Sistema muestra alerta verde "Registro guardado correctamente" (image-0027)
11. Sistema mantiene switch en estado OFF
12. Grupo desaparece del dropdown de búsqueda (filtrado por vigente='S')

### Flujo 2: Cambiar de No Vigente a Vigente

1. Usuario busca grupo "Grupo Antiguo" con filtro "No Vigente" (vigente='N')
2. Sistema muestra GroupSection con switch desactivado (gris, OFF)
3. Usuario hace clic en switch
4. Sistema cambia visualmente switch a ON (verde)
5. Sistema ejecuta PUT con body `{ "vigente": "S" }`
6. Backend actualiza GRUP_VIGENTE='S'
7. Sistema muestra alerta verde "Registro guardado correctamente"
8. Grupo aparece en dropdown de búsqueda con filtro "Vigente"

### Flujo 3: Error de Servidor (500)

1. Usuario sigue pasos 1-5 del Flujo 1
2. Backend lanza SQLException por lock de tabla
3. Backend retorna 500 Internal Server Error:
   ```json
   {
     "error": "Servidor",
     "mensaje": "Error al actualizar vigencia. Intente nuevamente."
   }
   ```
4. Sistema revierte switch a estado anterior (ON)
5. Sistema muestra mensaje de error en alerta roja por 5 segundos
6. Sistema registra error en console.error con stack trace

## Notas Técnicas

**API Consumida:**  
- PUT /acaj-ms/api/v1/{rut}-{dv}/grupos/{grupoId}/vigencia

**Validaciones:**
- Parámetro vigente: debe ser 'S' o 'N'
- Grupo: debe existir
- Usuario: autenticación requerida (RUT en JWT)

**Tablas BD (operación UPDATE):**
- BR_GRUPOS: actualiza GRUP_VIGENTE, GRUP_FECHA_MODIFICACION, GRUP_USUARIO_MODIFICACION
- BR_AUDITORIA_CAMBIOS: registro de auditoría (operación UPDATE)

**Impacto:**
- Las asignaciones existentes en BR_USUARIO_GRUPO NO se modifican
- El cambio solo afecta disponibilidad para nuevas asignaciones
- El grupo desaparece/aparece del dropdown según filtro vigente aplicado

## Dependencias

- BR_GRUPOS (actualización de vigencia)
- BR_AUDITORIA_CAMBIOS (registro de cambios)

## Glosario

- **Vigencia**: Estado activo/inactivo de un grupo (S=activo, N=inactivo)
- **Switch**: Componente UI de toggle on/off (Ant Design Switch)
- **Optimistic Update**: Actualización visual inmediata antes de confirmar con backend
- **Rollback**: Reversión del estado visual si backend falla
