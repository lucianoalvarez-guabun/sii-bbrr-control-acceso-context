# HdU-013: Agregar Cargo con Funciones

## Información General

**ID:** HdU-013  
**Módulo:** V - Mantenedor de Usuarios Relacionados  
**Prioridad:** Alta  
**Estimación:** 5 puntos  

## Historia de Usuario

**Como** Administrador del SII  
**Quiero** asignar un cargo con sus funciones a un usuario  
**Para** otorgarle permisos específicos según su rol  

## Mockups de Referencia

- ![image-0025](./images/image-0025.png) - Sección Unidad de Negocio con botón "+ Agregar cargo"

## Criterios de Aceptación

**AC-001:** La sección Unidad de Negocio debe mostrar botón "+ Agregar cargo" para cada unidad

**AC-002:** Al hacer clic en "+ Agregar cargo", el sistema debe:
- Abrir modal "Agregar Cargo"
- Mostrar dropdown "Seleccione Cargo" (carga solo cargos vigentes BR_CARGOS WHERE CARG_VIGENTE=1)
- Mostrar calendarios "Vigencia Inicio" y "Vigencia Fin"
- Mostrar sección "Funciones del cargo" con dropdown "Seleccione la Función"
- Mostrar botón icono (+) para agregar más funciones
- Al menos 1 función obligatoria

**AC-003:** Al seleccionar un cargo, el sistema debe:
- Cargar funciones disponibles para ese cargo (filtradas por FUNS_VIGENTE=1)
- Permitir seleccionar múltiples funciones
- Validar que no se repitan funciones

**AC-004:** Al hacer clic en icono (+), el sistema debe:
- Agregar nuevo dropdown "Seleccione la Función" debajo del anterior
- Cargar mismas funciones disponibles
- Excluir funciones ya seleccionadas en dropdowns anteriores

**AC-005:** El sistema debe validar:
- Cargo obligatorio
- Al menos 1 función seleccionada
- Vigencia Inicio obligatoria, <= hoy
- Vigencia Fin > Vigencia Inicio (si se ingresa)
- Cargo no debe estar ya asignado al usuario en esa unidad con vigencia activa

**AC-006:** Si el cargo ya está asignado, el sistema debe:
- Mostrar error "El cargo [nombre] ya está asignado a este usuario en esta unidad"
- NO cerrar modal
- Permitir seleccionar otro cargo

**AC-007:** Al presionar "Agregar" con datos válidos, el sistema debe:
- Insertar en BR_CARGOS_USUARIO (genera ID con SEQ_CARGO_USUARIO_ID)
- Insertar en BR_FUNCIONES_USUARIO para cada función seleccionada (CASCADE a cargo)
- Registrar auditoría
- Cerrar modal
- Refrescar lista de cargos en UserDetailCard
- Mostrar alerta éxito

**AC-008:** El sistema debe mostrar cada cargo con:
- Nombre del cargo
- Badge "Vigente" (verde) si vigente actual, "No vigente" (gris) si no
- Fechas vigencia inicio y fin
- Lista de funciones asignadas (en verde)
- Botones acción: agregar función, eliminar cargo

## Flujos Principales

### Flujo 1: Asignar Cargo con 3 Funciones

1. Usuario busca usuario RUT 15.000.000-1
2. Sistema muestra UserDetailCard con Unidad de Negocio:

![UserDetailCard con unidades](./images/image-0025.png)

3. Usuario hace clic en "+ Agregar cargo"
4. Sistema abre modal "Agregar Cargo"
5. Usuario selecciona "Jefe de Departamento" en dropdown Cargo
6. Sistema carga funciones disponibles para ese cargo
7. Usuario selecciona "Aprobar solicitudes" en primer dropdown función
8. Usuario hace clic en icono (+)
9. Sistema agrega segundo dropdown función
10. Usuario selecciona "Consultar reportes"
11. Usuario hace clic en icono (+) nuevamente
12. Usuario selecciona "Modificar avalúos"
13. Usuario ingresa Vigencia Inicio 2024-01-01
14. Usuario hace clic en "Agregar"
15. Sistema valida: cargo, 3 funciones, vigencia válida
16. Sistema inserta en BR_CARGOS_USUARIO (cargo ID 100)
17. Sistema inserta 3 registros en BR_FUNCIONES_USUARIO
18. Sistema cierra modal
19. Sistema refresca UserDetailCard
20. Usuario ve nuevo cargo "Jefe de Departamento" con 3 funciones en verde
21. Sistema muestra alerta éxito

### Flujo 2: Cargo Duplicado

1. Usuario intenta agregar cargo "Jefe de Departamento" ya asignado
2. Sistema detecta duplicado con vigencia activa
3. Sistema muestra error "El cargo Jefe de Departamento ya está asignado a este usuario en esta unidad"
4. Sistema mantiene modal abierto
5. Usuario selecciona otro cargo
6. Usuario completa y guarda exitosamente

### Flujo 3: Sin Funciones Seleccionadas

1. Usuario selecciona cargo
2. Usuario NO selecciona ninguna función
3. Usuario intenta guardar
4. Sistema valida y detecta error
5. Sistema muestra mensaje "Debe seleccionar al menos una función"
6. Sistema marca sección funciones en rojo
7. Usuario selecciona función
8. Usuario guarda exitosamente

## Notas Técnicas

**APIs Consumidas:**
- GET /acaj-ms/api/v1/usuarios-relacionados/{rut}-{dv}/cargos/disponibles
- POST /acaj-ms/api/v1/usuarios-relacionados/{rut}-{dv}/cargos

**Validaciones Backend:**
- Cargo debe ser vigente (CARG_VIGENTE=1)
- Funciones deben ser vigentes (FUNS_VIGENTE=1)
- No duplicar cargo en misma unidad con vigencia activa
- Al menos 1 función obligatoria

**Transacción:**
La inserción del cargo y todas sus funciones debe ser transacción atómica.

**Tablas BD Afectadas:**
- BR_CARGOS_USUARIO (INSERT)
- BR_FUNCIONES_USUARIO (INSERT múltiple, CASCADE a cargo)
- BR_AUDITORIA_CAMBIOS (INSERT)

**Secuencias:**
- SEQ_CARGO_USUARIO_ID para CAUS_ID
- SEQ_FUNCION_USUARIO_ID para cada FUUS_ID

## Dependencias

**Funcionales:**
- BR_CARGOS debe tener cargos vigentes
- BR_FUNCIONES debe tener funciones vigentes
- Usuario debe tener permisos según alcance

## Glosario

- **Cargo**: Rol laboral asignado al usuario (ej: Jefe de Departamento, Supervisor)
- **Función**: Permiso específico asociado a un cargo (ej: Aprobar solicitudes)
- **Vigencia Activa**: Registro con fecha fin NULL o futura
- **CASCADE**: Al eliminar cargo, se eliminan automáticamente todas sus funciones
