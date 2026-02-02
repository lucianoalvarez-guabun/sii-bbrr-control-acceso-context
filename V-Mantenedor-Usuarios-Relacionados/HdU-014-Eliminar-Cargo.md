# HdU-014: Eliminar Cargo (CASCADE Funciones)

## Información General

**ID:** HdU-014  
**Módulo:** V - Mantenedor de Usuarios Relacionados  
**Prioridad:** Alta  
**Estimación:** 3 puntos  

## Historia de Usuario

**Como** Administrador del SII  
**Quiero** eliminar un cargo asignado a un usuario  
**Para** remover permisos que ya no son necesarios  

## Mockups de Referencia

- ![image-0025](./images/image-0025.png) - Lista de cargos con botón eliminar (basurero)

## Criterios de Aceptación

**AC-001:** Cada cargo en la lista debe mostrar botón eliminar (icono basurero) visible solo para usuarios con permisos

**AC-002:** El botón eliminar debe estar:
- Habilitado si el cargo NO está vigente actualmente (vigencia fin pasada)
- Deshabilitado si el cargo está vigente actualmente
- Mostrar tooltip "No se puede eliminar un cargo vigente" al pasar mouse sobre botón deshabilitado

**AC-003:** Al hacer clic en botón eliminar de cargo NO vigente, el sistema debe:
- Abrir alerta confirmación "¿Está seguro que desea eliminar este registro? Perderá toda la información asociada."
- Mostrar advertencia "Se eliminarán también todas las funciones asignadas a este cargo"
- Mostrar botones "Aceptar" (verde) y "Cancelar" (blanco)

**AC-004:** Al hacer clic en "Cancelar", el sistema debe:
- Cerrar alerta sin realizar cambios
- Mantener UserDetailCard sin modificaciones

**AC-005:** Al hacer clic en "Aceptar", el sistema debe:
- Ejecutar DELETE /{rut}-{dv}/cargos/{cargoId}
- Eliminar registro en BR_CARGOS_USUARIO
- Eliminar automáticamente (CASCADE) todas las funciones asociadas en BR_FUNCIONES_USUARIO
- Registrar auditoría con cantidad de funciones eliminadas
- Cerrar alerta
- Refrescar lista de cargos en UserDetailCard
- Mostrar alerta éxito "Cargo eliminado correctamente. Se eliminaron X funciones asociadas"

**AC-006:** Si se intenta eliminar cargo vigente, el sistema debe:
- Mostrar error "No se puede eliminar un cargo vigente. Modifique la vigencia fin primero"
- NO abrir alerta confirmación

**AC-007:** Si el cargo tiene vigencia activa (vigencia fin NULL o futura), el sistema debe:
- Deshabilitar botón eliminar visualmente (gris, cursor not-allowed)
- Mostrar tooltip explicativo al hover

## Flujos Principales

### Flujo 1: Eliminar Cargo No Vigente

1. Usuario busca usuario RUT 15.000.000-1
2. Sistema muestra UserDetailCard con 2 cargos:

![UserDetailCard con cargos](./images/image-0025.png)

   - "Jefe de Departamento" (vigente, 2024-01-01 a presente) - botón eliminar deshabilitado
   - "Supervisor Regional" (NO vigente, 2023-01-01 a 2023-12-31) - botón eliminar habilitado
3. Usuario hace clic en botón eliminar de "Supervisor Regional"
4. Sistema abre alerta confirmación
5. Sistema muestra advertencia "Se eliminarán también 5 funciones asignadas a este cargo"
6. Usuario hace clic en "Aceptar"
7. Sistema ejecuta DELETE /cargos/200 (cargoId=200)
8. Sistema elimina registro BR_CARGOS_USUARIO
9. Sistema elimina automáticamente 5 registros BR_FUNCIONES_USUARIO (FK CASCADE)
10. Sistema registra auditoría "Cargo Supervisor Regional eliminado (5 funciones)"
11. Sistema cierra alerta
12. Sistema refresca UserDetailCard
13. Usuario ve solo cargo "Jefe de Departamento" restante
14. Sistema muestra alerta éxito "Cargo eliminado correctamente. Se eliminaron 5 funciones asociadas"

### Flujo 2: Intento Eliminar Cargo Vigente

1. Usuario ve cargo "Jefe de Departamento" vigente (vigencia fin NULL)
2. Usuario pasa mouse sobre botón eliminar (deshabilitado)
3. Sistema muestra tooltip "No se puede eliminar un cargo vigente. Modifique la vigencia fin primero"
4. Usuario hace clic en botón (no responde, está deshabilitado)

### Flujo 3: Cancelación

1. Usuario hace clic en eliminar cargo NO vigente
2. Sistema abre alerta confirmación
3. Usuario lee advertencia sobre funciones que se eliminarán
4. Usuario hace clic en "Cancelar"
5. Sistema cierra alerta
6. Sistema NO elimina cargo ni funciones
7. UserDetailCard permanece sin cambios

## Notas Técnicas

**API Consumida:** DELETE /acaj-ms/api/v1/usuarios-relacionados/{rut}-{dv}/cargos/{cargoId}

**Validaciones Backend:**
- Cargo debe existir
- Cargo NO debe estar vigente (vigencia fin <= hoy)
- Usuario debe tener permisos según alcance

**Comportamiento CASCADE:**
Al eliminar registro en BR_CARGOS_USUARIO, la FK con ON DELETE CASCADE automáticamente elimina todos los registros relacionados en BR_FUNCIONES_USUARIO.

**Tablas BD Afectadas:**
- BR_CARGOS_USUARIO (DELETE)
- BR_FUNCIONES_USUARIO (DELETE CASCADE automático por FK)
- BR_AUDITORIA_CAMBIOS (INSERT)

**Auditoría:**
Registrar cantidad de funciones eliminadas junto con el cargo.

## Dependencias

**Funcionales:**
- Usuario debe tener permisos Administrador
- FK en BR_FUNCIONES_USUARIO debe tener ON DELETE CASCADE

## Glosario

- **Cargo Vigente**: Cargo con vigencia fin NULL o futura (actualmente activo)
- **Cargo No Vigente**: Cargo con vigencia fin pasada (ya no activo)
- **CASCADE**: Eliminación automática de registros relacionados por FK
- **FK (Foreign Key)**: Llave foránea que relaciona tablas
