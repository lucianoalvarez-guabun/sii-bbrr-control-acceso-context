# HdU-010: Crear Usuario Interno (SII)

## Información General

**ID:** HdU-010  
**Módulo:** V - Mantenedor de Usuarios Relacionados  
**Prioridad:** Alta  
**Estimación:** 5 puntos  

## Historia de Usuario

**Como** Administrador del SII  
**Quiero** crear un nuevo usuario interno consultando SIGER  
**Para** que funcionarios del SII accedan al sistema con sus datos oficiales  

## Mockups de Referencia

- ![image-0027](./images/image-0027.png) - Botón "+ Agregar usuario nuevo"

## Criterios de Aceptación

**AC-001:** Al hacer clic en "+ Agregar usuario nuevo" desde pantalla inicial, el sistema debe:
- Abrir modal "Agregar Usuario Relacionado"
- Mostrar tabs: "Usuario Interno (SII)" y "Usuario Externo (OCM)"
- Tab "Usuario Interno (SII)" debe estar seleccionado por defecto

**AC-002:** El tab "Usuario Interno (SII)" debe contener:
- Input "RUT del Funcionario" (obligatorio, formato XX.XXX.XXX-X)
- Botón "Consultar SIGER" (ejecuta integración)
- Área de resultados (oculta hasta consultar)

**AC-003:** Al presionar "Consultar SIGER", el sistema debe:
- Validar RUT formato y módulo 11
- Ejecutar POST /interno con integración a SIGER
- Mostrar indicador de carga durante consulta

**AC-004:** Si SIGER retorna datos exitosamente, el sistema debe mostrar en área de resultados:
- Nombre completo (read-only desde SIGER)
- Email institucional (read-only desde SIGER)
- Teléfono móvil (read-only desde SIGER)
- Dropdown "Unidad Principal" (obligatorio, carga BR_UNIDADES_NEGOCIO)
- Toggle "Jurisdicción" (SIMPLE/AMPLIADA, default SIMPLE)
- Calendario "Vigencia Inicio" (obligatorio, default hoy)
- Calendario "Vigencia Fin" (opcional)
- Botón "Guardar" (habilitado solo si unidad seleccionada)
- Botón "Cancelar"

**AC-005:** El sistema debe validar:
- RUT no debe existir previamente en BR_RELACIONADOS (unique constraint)
- Vigencia Inicio no debe ser futura
- Vigencia Fin debe ser posterior a Vigencia Inicio (si se ingresa)
- Unidad Principal es obligatoria

**AC-006:** Si el RUT ya existe, el sistema debe:
- Mostrar error "El RUT 15.000.000-1 ya está registrado como usuario relacionado"
- NO cerrar modal
- Deshabilitar botón "Guardar"

**AC-007:** Si SIGER no encuentra el RUT, el sistema debe:
- Mostrar error "RUT no encontrado en SIGER. Verifique que sea un funcionario activo del SII"
- Limpiar área de resultados
- Mantener input RUT para nuevo intento

**AC-008:** Si la integración con SIGER falla (timeout, error 500), el sistema debe:
- Mostrar error "Error al consultar SIGER. Intente nuevamente más tarde"
- Mantener modal abierto
- Permitir reintentar consulta

**AC-009:** Al presionar "Guardar" con datos válidos, el sistema debe:
- Insertar registro en BR_RELACIONADOS con:
  - RELA_TIPO_USUARIO = 'INTERNO'
  - Datos desde SIGER (nombre, email, teléfono)
  - Unidad seleccionada
  - Jurisdicción seleccionada
  - Vigencias ingresadas
- Insertar auditoría en BR_AUDITORIA_CAMBIOS
- Cerrar modal
- Mostrar alerta verde "Registro guardado correctamente" (image-0028)
- Buscar automáticamente el usuario recién creado (mostrar UserDetailCard)

**AC-010:** Al presionar "Cancelar", el sistema debe:
- Cerrar modal sin guardar
- Volver a pantalla inicial (SearchBar)

## Flujos Principales

### Flujo 1: Creación Exitosa

1. Usuario hace clic en botón verde "Agregar":

![Botón Agregar](./images/image-0027.png)

2. Sistema abre modal con tabs (Interno/Externo)
3. Usuario selecciona tab "Usuario Interno (SII)" (ya seleccionado por default)
4. Usuario ingresa RUT "15000000"
5. Sistema formatea a "15.000.000-1"
6. Usuario hace clic en "Consultar SIGER"
7. Sistema valida RUT y ejecuta POST /interno
8. SIGER retorna: Nombre "María Moscoso", Email "maria.moscoso@sii.cl", Teléfono "+56912345678"
9. Sistema muestra área de resultados con datos read-only de SIGER
10. Usuario selecciona "Dirección Regional Metropolitana" en dropdown Unidad Principal
11. Usuario mantiene Jurisdicción SIMPLE (default)
12. Usuario ingresa Vigencia Inicio 2024-01-15
13. Usuario hace clic en "Guardar"
14. Sistema valida: RUT único, vigencia válida, unidad seleccionada
15. Sistema inserta registro en BR_RELACIONADOS (RELA_TIPO_USUARIO='INTERNO')
16. Sistema cierra modal
17. Sistema muestra alerta "Usuario interno creado correctamente"
18. Usuario hace clic en "Aceptar"
19. Sistema busca automáticamente usuario recién creado
20. Sistema muestra UserDetailCard con datos completos

### Flujo 2: RUT Duplicado

1. Usuario sigue pasos 1-7 del Flujo 1
2. Sistema valida RUT en BR_RELACIONADOS → encuentra registro existente
3. Sistema muestra error "El RUT 15.000.000-1 ya está registrado como usuario relacionado"
4. Sistema deshabilita botón "Guardar"
5. Usuario hace clic en "Cancelar"
6. Modal se cierra

### Flujo 3: RUT No en SIGER

1. Usuario sigue pasos 1-6 del Flujo 1 pero ingresa RUT "99999999"
2. Sistema ejecuta POST /interno con integración SIGER
3. SIGER retorna 404 Not Found (funcionario no existe o no está activo)
4. Sistema muestra error "RUT no encontrado en SIGER. Verifique que sea un funcionario activo del SII"
5. Sistema limpia área de resultados
6. Usuario corrige RUT a uno válido
7. Usuario reintenta consulta

### Flujo 4: Error SIGER

1. Usuario sigue pasos 1-6 del Flujo 1
2. Sistema ejecuta POST /interno
3. SIGER retorna 502 Bad Gateway (servicio caído)
4. Sistema muestra error "Error al consultar SIGER. Intente nuevamente más tarde"
5. Sistema mantiene input RUT
6. Usuario hace clic en "Cancelar" y cierra modal

## Notas Técnicas

**API Consumida:** POST /acaj-ms/api/v1/usuarios-relacionados/interno

**Request Body:**
- rut (number)
- unidadPrincipalId (number)
- jurisdiccion (string: SIMPLE/AMPLIADA)
- vigenciaInicio (date)
- vigenciaFin (date, opcional)

**Integración SIGER:**
El backend consulta SIGER (Sistema Integrado de Gestión de Recursos Humanos) para obtener datos oficiales del funcionario. Estos datos son read-only en el sistema.

**Validaciones Backend:**
- RUT debe ser único en BR_RELACIONADOS
- RUT debe existir en SIGER como funcionario activo
- Unidad Principal debe existir en BR_UNIDADES_NEGOCIO
- Vigencia Inicio <= hoy
- Vigencia Fin > Vigencia Inicio (si se ingresa)

**Transacción:**
La creación del usuario y registro de auditoría deben ejecutarse como transacción atómica.

**Tablas BD Afectadas:**
- BR_RELACIONADOS (INSERT con RELA_TIPO_USUARIO='INTERNO')
- BR_AUDITORIA_CAMBIOS (INSERT)

## Dependencias

**Funcionales:**
- Sistema SIGER disponible y funcionando
- Tabla BR_UNIDADES_NEGOCIO con unidades vigentes
- Permisos de Administrador Nacional, Regional o de Unidad

**Técnicas:**
- Integración REST con SIGER
- Timeout configurado para SIGER (ej: 10 segundos)
- Manejo de errores 404, 500, 502 de SIGER

## Glosario

- **SIGER**: Sistema Integrado de Gestión de Recursos Humanos del SII
- **Usuario Interno**: Funcionario del SII con contrato vigente
- **Unidad Principal**: Unidad de negocio a la que pertenece el usuario
- **Jurisdicción SIMPLE**: Usuario opera solo en región de su unidad
- **Jurisdicción AMPLIADA**: Usuario opera en todo el país
- **Read-only**: Datos que no pueden ser modificados manualmente (vienen desde sistema externo)
