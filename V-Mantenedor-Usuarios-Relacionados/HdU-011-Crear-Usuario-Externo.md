# HdU-011: Crear Usuario Externo (OCM/Notario)

## Información General

**ID:** HdU-011  
**Módulo:** V - Mantenedor de Usuarios Relacionados  
**Prioridad:** Alta  
**Estimación:** 5 puntos  

## Historia de Usuario

**Como** Administrador del SII  
**Quiero** crear un nuevo usuario externo consultando RIAC  
**Para** que usuarios de instituciones externas accedan al sistema  

## Mockups de Referencia

- ![image-0027](./images/image-0027.png) - Botón "+ Agregar usuario nuevo"

## Criterios de Aceptación

**AC-001:** El tab "Usuario Externo (OCM)" debe contener:
- Input "RUT" (obligatorio)
- Dropdown "Tipo de Institución" (OCM, Notario, CBR, CDE, Municipalidad)
- Botón "Consultar RIAC"

**AC-002:** Al presionar "Consultar RIAC", el sistema debe:
- Validar RUT y tipo institución
- Ejecutar POST /externo con integración a RIAC
- Mostrar área de resultados con datos de RIAC

**AC-003:** Si RIAC retorna datos, el sistema debe mostrar:
- Input "Nombre" (editable, pre-llenado desde RIAC)
- Input "Apellido Paterno" (editable)
- Input "Apellido Materno" (editable)
- Input "Email" (editable, validación formato)
- Input "Teléfono" (editable, formato +56)
- Dropdown "Unidad Principal" (obligatorio)
- Toggle "Jurisdicción" (SIMPLE/AMPLIADA)
- Calendarios "Vigencia Inicio/Fin"
- Botones "Guardar" y "Cancelar"

**AC-004:** El sistema debe permitir editar datos traídos desde RIAC (a diferencia de SIGER que es read-only)

**AC-005:** Validaciones específicas:
- Nombre: máximo 40 caracteres (límite RELA_NOMBRE en BD)
- Email: formato válido y único en sistema
- Teléfono: formato +56XXXXXXXXX
- RUT único en BR_RELACIONADOS

**AC-006:** Al guardar exitosamente, el sistema debe:
- Insertar en BR_RELACIONADOS con RELA_TIPO_USUARIO='EXTERNO'
- Guardar RELA_CODIGO con código RIAC
- Mostrar alerta éxito
- Buscar automáticamente usuario creado

## Flujos Principales

### Flujo 1: Creación Usuario OCM

1. Usuario abre modal botón verde "Agregar":

![Botón Agregar](./images/image-0027.png)

2. Usuario selecciona tab "Usuario Externo (OCM)"
3. Usuario ingresa RUT "20000000"
4. Usuario selecciona "OCM - Oficinas de Certificados Municipales" en dropdown
5. Usuario hace clic en "Consultar RIAC"
6. RIAC retorna: Nombre "Juan", Paterno "Pérez", Email "juan.perez@ocm.cl"
7. Sistema muestra área de resultados con datos editables
8. Usuario modifica Nombre a "Juan Carlos"
9. Usuario selecciona Unidad Principal
10. Usuario guarda
11. Sistema inserta usuario con RELA_TIPO_USUARIO='EXTERNO'
12. Sistema muestra alerta éxito

### Flujo 2: RIAC Sin Datos

1. Usuario sigue pasos 1-5 del Flujo 1
2. RIAC retorna 404 (usuario no registrado)
3. Sistema muestra formulario vacío para ingreso manual
4. Usuario completa manualmente todos los campos
5. Usuario guarda
6. Sistema inserta usuario

## Notas Técnicas

**API Consumida:** POST /acaj-ms/api/v1/usuarios-relacionados/externo

**Integración RIAC:**
Sistema de Registro e Información de Avalúos Comerciales que contiene datos de usuarios externos.

**Validaciones Backend:**
- RUT único
- Nombre máximo 40 caracteres (RELA_NOMBRE)
- Email formato válido
- Tipo institución válido

**Tablas BD Afectadas:**
- BR_RELACIONADOS (INSERT con RELA_TIPO_USUARIO='EXTERNO', RELA_CODIGO)
- BR_AUDITORIA_CAMBIOS (INSERT)

## Dependencias

**Funcionales:**
- Sistema RIAC disponible
- Tipos de institución configurados
- BR_UNIDADES_NEGOCIO con unidades vigentes

## Glosario

- **RIAC**: Registro e Información de Avalúos Comerciales
- **OCM**: Oficina de Certificados Municipales
- **Usuario Externo**: Usuario de instituciones fuera del SII (OCM, notarios, CBR, CDE, municipalidades)
- **RELA_CODIGO**: Código identificador del usuario en sistema RIAC
