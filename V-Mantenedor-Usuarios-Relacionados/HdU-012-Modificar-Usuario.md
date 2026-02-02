# HdU-012: Modificar Datos Usuario

## Información General

**ID:** HdU-012  
**Módulo:** V - Mantenedor de Usuarios Relacionados  
**Prioridad:** Media  
**Estimación:** 3 puntos  

## Historia de Usuario

**Como** Administrador del SII  
**Quiero** modificar datos de un usuario relacionado existente  
**Para** mantener actualizada la información de contacto y configuración  

## Mockups de Referencia

- ![image-0025](./images/image-0025.png) - UserDetailCard con botón editar (lápiz)

## Criterios de Aceptación

**AC-001:** El UserDetailCard debe mostrar botón editar (icono lápiz) visible solo para usuarios con permisos

**AC-002:** Al hacer clic en botón editar, el sistema debe:
- Abrir modal "Modificar Usuario Relacionado"
- Pre-llenar todos los campos con datos actuales
- Mostrar RUT como read-only (no modificable)
- Mostrar Tipo Usuario como read-only (no modificable)

**AC-003:** Para usuarios INTERNO (SII), el modal debe mostrar:
- Nombre completo: read-only (desde SIGER, no editable)
- Email: read-only (desde SIGER)
- Teléfono: read-only (desde SIGER)
- Unidad Principal: editable (dropdown)
- Jurisdicción: editable (toggle SIMPLE/AMPLIADA)
- Vigencia Inicio: editable
- Vigencia Fin: editable

**AC-004:** Para usuarios EXTERNO, el modal debe mostrar:
- Nombre: editable (max 40 chars)
- Apellido Paterno: editable (max 20 chars)
- Apellido Materno: editable (max 20 chars)
- Email: editable (formato válido)
- Teléfono: editable (formato +56)
- Unidad Principal: editable
- Jurisdicción: editable
- Vigencias: editables

**AC-005:** El sistema debe validar:
- Vigencia Inicio <= hoy
- Vigencia Fin > Vigencia Inicio (si se ingresa)
- Email formato válido
- Teléfono formato +56XXXXXXXXX
- Unidad Principal debe existir

**AC-006:** Al presionar "Guardar", el sistema debe:
- Ejecutar PUT /{rut}-{dv} con datos modificados
- Actualizar registro en BR_RELACIONADOS
- Registrar auditoría con campos modificados
- Cerrar modal
- Actualizar UserDetailCard con nuevos datos
- Mostrar alerta éxito

**AC-007:** Si hay conflicto (ej: otro usuario modificó mientras tanto), el sistema debe:
- Mostrar error "Los datos fueron modificados por otro usuario. Por favor recargue"
- Mantener modal abierto
- No perder cambios ingresados

## Flujos Principales

### Flujo 1: Modificar Jurisdicción Usuario Interno

1. Usuario busca usuario RUT 15.000.000-1 (INTERNO)
2. Sistema muestra UserDetailCard con Jurisdicción SIMPLE:

![UserDetailCard](./images/image-0025.png)

3. Usuario hace clic en botón editar (lápiz)
4. Sistema abre modal con datos actuales
5. Usuario cambia toggle Jurisdicción de SIMPLE a AMPLIADA
6. Usuario hace clic en "Guardar"
7. Sistema ejecuta PUT /15000000-1/jurisdiccion
8. Sistema actualiza RELA_JURISDICCION='AMPLIADA'
9. Sistema registra auditoría
10. Sistema cierra modal
11. Sistema actualiza UserDetailCard (muestra AMPLIADA)
12. Sistema muestra alerta éxito

### Flujo 2: Modificar Datos Usuario Externo

1. Usuario busca usuario RUT 20.000.000-0 (EXTERNO)
2. Usuario hace clic en editar
3. Sistema abre modal con campos editables
4. Usuario modifica Email de "juan.perez@ocm.cl" a "jperez@ocm.cl"
5. Usuario modifica Teléfono de "+56912345678" a "+56987654321"
6. Usuario guarda
7. Sistema valida formato email y teléfono
8. Sistema actualiza BR_RELACIONADOS
9. Sistema registra auditoría con campos modificados
10. Sistema muestra alerta éxito

### Flujo 3: Validación Vigencia Inválida

1. Usuario abre modal editar
2. Usuario ingresa Vigencia Fin = 2023-01-01
3. Usuario ingresa Vigencia Inicio = 2024-01-01 (posterior a Fin)
4. Usuario intenta guardar
5. Sistema valida y detecta error
6. Sistema muestra mensaje "Vigencia Fin debe ser posterior a Vigencia Inicio"
7. Sistema marca campos en rojo
8. Sistema NO cierra modal
9. Usuario corrige fechas
10. Usuario guarda exitosamente

## Notas Técnicas

**API Consumida:** PUT /acaj-ms/api/v1/usuarios-relacionados/{rut}-{dv}

**Validaciones Backend:**
- Usuario debe existir
- Campos editables según tipo (INTERNO vs EXTERNO)
- Email formato válido
- Vigencias coherentes
- Unidad Principal debe existir

**Tablas BD Afectadas:**
- BR_RELACIONADOS (UPDATE)
- BR_AUDITORIA_CAMBIOS (INSERT con before/after)

**Auditoría:**
Registrar solo campos modificados con valores antes/después.

## Dependencias

**Funcionales:**
- Usuario debe tener permisos para modificar según alcance
- BR_UNIDADES_NEGOCIO con unidades vigentes

## Glosario

- **Campos Read-only**: Datos que no pueden modificarse manualmente (SIGER para usuarios INTERNO)
- **Campos Editables**: Datos que pueden modificarse según tipo de usuario
- **Auditoría**: Registro de cambios con usuario, fecha y valores antes/después
