# HdU-016: Eliminar Función (Validar Última)

## Información General

**ID:** HdU-016  
**Módulo:** V - Mantenedor de Usuarios Relacionados  
**Prioridad:** Media  
**Estimación:** 3 puntos  

## Historia de Usuario

**Como** Administrador del SII  
**Quiero** eliminar una función asignada a un cargo  
**Para** remover permisos específicos que el usuario ya no necesita  

## Mockups de Referencia

- ![image-0025](./images/image-0025.png) - Lista de funciones en verde con botón eliminar (X roja)

## Criterios de Aceptación

**AC-001:** Cada función en la lista debe mostrar:
- Botón eliminar (X roja) a la derecha
- Visible solo para usuarios con permisos

**AC-002:** El botón eliminar debe estar:
- Habilitado si el cargo tiene 2 o más funciones
- Deshabilitado si es la única función del cargo (COUNT=1)
- Mostrar tooltip "No se puede eliminar la última función del cargo" si deshabilitado

**AC-003:** Al hacer clic en botón eliminar de función (con COUNT > 1), el sistema debe:
- Abrir alerta confirmación "¿Está seguro que desea eliminar este registro? Perderá toda la información asociada."
- Mostrar nombre de la función a eliminar
- Botones "Aceptar" (verde) y "Cancelar" (blanco)

**AC-004:** Al hacer clic en "Cancelar", el sistema debe:
- Cerrar alerta sin cambios
- Mantener función en la lista

**AC-005:** Al hacer clic en "Aceptar", el sistema debe:
- Ejecutar DELETE /{rut}-{dv}/cargos/{cargoId}/funciones/{funcionId}
- Eliminar registro en BR_FUNCIONES_USUARIO
- Registrar auditoría
- Cerrar alerta
- Refrescar lista de funciones del cargo
- Mostrar alerta éxito "Función eliminada correctamente"

**AC-006:** Si se intenta eliminar la última función (COUNT=1), el sistema debe:
- Retornar error 409 Conflict
- Mostrar mensaje "No se puede eliminar la última función del cargo. Elimine el cargo completo si es necesario"
- NO eliminar función

**AC-007:** El sistema debe validar antes de eliminar:
- Cargo debe tener al menos 2 funciones (COUNT >= 2)
- Función debe existir y pertenecer al cargo especificado

## Flujos Principales

### Flujo 1: Eliminar Función de Cargo con 3 Funciones

1. Usuario ve cargo "Jefe de Departamento" con 3 funciones:

![Cargo con 3 funciones](./images/image-0025.png)

   - "Aprobar solicitudes" (X habilitada)
   - "Consultar reportes" (X habilitada)
   - "Modificar avalúos" (X habilitada)
2. Usuario hace clic en X de "Consultar reportes"
3. Sistema abre alerta confirmación "¿Está seguro que desea eliminar este registro?"
4. Sistema muestra "Función: Consultar reportes"
5. Usuario hace clic en "Aceptar"
6. Sistema ejecuta DELETE /cargos/100/funciones/25
7. Sistema elimina registro BR_FUNCIONES_USUARIO
8. Sistema registra auditoría
9. Sistema cierra alerta
10. Sistema refresca cargo
11. Usuario ve cargo ahora con 2 funciones restantes
12. Sistema muestra alerta "Función eliminada correctamente"

### Flujo 2: Intento Eliminar Última Función

1. Usuario ve cargo "Supervisor Regional" con 1 función única:
   - "Ver estadísticas" (X deshabilitada en gris)
2. Usuario pasa mouse sobre X deshabilitada
3. Sistema muestra tooltip "No se puede eliminar la última función del cargo"
4. Usuario hace clic en X (no responde, deshabilitado)

### Flujo 3: Validación Backend Última Función

1. Usuario modifica HTML/JS y logra enviar DELETE para única función
2. Backend ejecuta COUNT en BR_FUNCIONES_USUARIO WHERE cargoId=200
3. Backend detecta COUNT=1
4. Backend retorna 409 Conflict
5. Frontend muestra error "No se puede eliminar la última función del cargo. Elimine el cargo completo si es necesario"
6. Función NO se elimina

### Flujo 4: Cancelación

1. Usuario hace clic en X de función
2. Sistema abre alerta confirmación
3. Usuario hace clic en "Cancelar"
4. Sistema cierra alerta
5. Sistema NO elimina función
6. Lista permanece sin cambios

## Notas Técnicas

**API Consumida:** DELETE /acaj-ms/api/v1/usuarios-relacionados/{rut}-{dv}/cargos/{cargoId}/funciones/{funcionId}

**Validaciones Backend:**
- Función debe existir y pertenecer al cargoId
- Cargo debe tener COUNT >= 2 funciones
- Usuario debe tener permisos según alcance

**Query Validación:**
```
SELECT COUNT(*) 
FROM BR_FUNCIONES_USUARIO 
WHERE FUUS_CARGO_USUARIO_ID = :cargoId
```
Si COUNT = 1 → retornar 409 Conflict

**Tablas BD Afectadas:**
- BR_FUNCIONES_USUARIO (DELETE)
- BR_AUDITORIA_CAMBIOS (INSERT)

**Response 409 Conflict:**
```json
{
  "error": "LAST_FUNCTION",
  "mensaje": "No se puede eliminar la última función del cargo"
}
```

## Dependencias

**Funcionales:**
- Cargo debe existir
- Función debe existir
- Usuario debe tener permisos Administrador

## Glosario

- **Última Función**: Única función asignada a un cargo (COUNT=1)
- **Función Múltiple**: Una de varias funciones del cargo (COUNT > 1)
- **COUNT**: Cantidad de funciones asignadas a un cargo específico
- **409 Conflict**: Código HTTP que indica conflicto de negocio (no se puede realizar operación)
