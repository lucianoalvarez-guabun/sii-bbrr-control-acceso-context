# HdU-001: Crear Grupo

## Información General

**ID:** HdU-001  
**Módulo:** VIII - Mantenedor de Grupos  
**Prioridad:** Alta  
**Estimación:** 5 puntos  

## Historia de Usuario

**Como** Administrador Nacional del SII  
**Quiero** crear un nuevo grupo de permisos con su primer título y función  
**Para** estructurar los accesos de los usuarios a funcionalidades del sistema  

## Mockups de Referencia

- **Imagen 4 (inline)**: Formulario inline "Crear Grupo" expandido en pantalla principal
- **image-0027.png**: Alerta de éxito "Registro guardado correctamente"
- **image-0127.png**: Pantalla principal mostrando grupo recién creado

## Criterios de Aceptación

**AC-001:** El sistema debe mostrar un botón "Agregar Grupo" en la cabecera de la pantalla principal (icono +)

**AC-002:** Al hacer clic en "Agregar Grupo", se debe desplegar un formulario inline (NO modal) en la pantalla principal con los siguientes campos:
- Input "Ingrese nombre del Grupo" (obligatorio, max 100 caracteres)
- Input "Ingrese nombre del Título" (obligatorio, max 100 caracteres)
- Dropdown "Seleccione Función" (obligatorio, carga funciones vigentes de BR_FUNCIONES)
- Botón X (cancelar, colapsa formulario sin guardar)
- Botón ✓ (guardar, ejecuta validaciones y creación)

**AC-003:** El sistema debe validar que el campo "nombre del Grupo" no esté vacío y no contenga más de 100 caracteres

**AC-004:** El sistema debe validar que el campo "nombre del Título" no esté vacío y no contenga más de 100 caracteres

**AC-005:** El sistema debe validar que se haya seleccionado al menos una función del dropdown

**AC-006:** El sistema debe verificar que el nombre del grupo NO exista previamente (case-insensitive: "Sistema OT" == "sistema ot")

**AC-007:** Si las validaciones son exitosas, el sistema debe:
- Generar un nuevo ID de grupo con SEQ_GRUPO_ID.NEXTVAL
- Crear registro en BR_GRUPOS con vigencia='S' y fecha_creacion=SYSDATE
- Generar un nuevo ID de título con SEQ_TITULO_ID.NEXTVAL
- Crear registro en BR_TITULOS con orden=1 vinculado al grupo
- Crear registro en BR_TITULOS_FUNCIONES vinculando título con función seleccionada
- Registrar auditoría en BR_AUDITORIA_CAMBIOS con operación='INSERT'

**AC-008:** Si la creación es exitosa, el sistema debe:
- Colapsar el formulario inline automáticamente
- Mostrar alerta verde "Registro guardado correctamente" por 3 segundos (image-0027)
- Mostrar el nuevo grupo en el área de resultados (como si se hubiera buscado)
- Limpiar los campos del formulario para próxima creación

**AC-009:** Si el nombre del grupo ya existe, el sistema debe mostrar error:
- "El nombre del grupo ya existe. Ingrese un nombre diferente."
- Mantener el formulario expandido con los datos ingresados
- Marcar el campo "nombre del Grupo" en rojo

**AC-010:** Si ocurre un error de servidor (500), el sistema debe mostrar:
- "Error al guardar el grupo. Intente nuevamente."
- Mantener el formulario expandido con los datos ingresados
- Registrar error en logs del backend con stack trace completo

## Flujos Principales

### Flujo 1: Creación Exitosa

1. Usuario hace clic en botón "Agregar Grupo" (icono + en SearchBar)
2. Sistema expande formulario CreateGroupForm inline debajo del SearchBar
3. Usuario ingresa "Sistema OT" en campo nombre del Grupo
4. Usuario ingresa "Reportes" en campo nombre del Título
5. Usuario selecciona "csdfcasc" (ID 15) del dropdown Función
6. Usuario hace clic en botón ✓
7. Sistema valida campos (no vacíos, max 100 caracteres, función seleccionada)
8. Sistema verifica que "Sistema OT" no existe en BR_GRUPOS
9. Sistema ejecuta transacción:
   - INSERT en BR_GRUPOS → grupoId=123
   - INSERT en BR_TITULOS → tituloId=45, orden=1
   - INSERT en BR_TITULOS_FUNCIONES → relación (45, 15)
   - INSERT en BR_AUDITORIA_CAMBIOS
10. Sistema colapsa formulario inline
11. Sistema muestra alerta verde "Registro guardado correctamente" (image-0027)
12. Sistema muestra el grupo recién creado en el área de resultados (como búsqueda automática)
13. Usuario visualiza grupo "Sistema OT" expandido con título "Reportes" (image-0127)

### Flujo 2: Nombre Duplicado

1. Usuario sigue pasos 1-6 del Flujo 1 pero ingresa "Sistema OT" (ya existe)
2. Sistema valida campos → OK
3. Sistema verifica existencia en BR_GRUPOS → encuentra match (case-insensitive)
4. Sistema retorna error 409 Conflict
5. Sistema muestra mensaje: "El nombre del grupo ya existe. Ingrese un nombre diferente."
6. Sistema marca campo "nombre del Grupo" en rojo con borde
7. Formulario permanece expandido con datos ingresados
8. Usuario corrige nombre a "Sistema OT v2"
9. Usuario hace clic en botón ✓
10. Sistema continúa con pasos 7-13 del Flujo 1

### Flujo 3: Cancelación

1. Usuario sigue pasos 1-5 del Flujo 1
2. Usuario hace clic en botón X (cancelar)
3. Sistema colapsa formulario inline sin ejecutar validaciones
4. Sistema NO guarda ningún dato
5. Sistema limpia campos del formulario
6. Pantalla principal permanece sin cambios (área de resultados intacta)

## Notas Técnicas

**API Consumida:**  
- POST /acaj-ms/api/v1/{rut}-{dv}/grupos/crear

**Validaciones:**
- Nombre del grupo: obligatorio, max 100 caracteres, no duplicado (case-insensitive)
- Nombre del título: obligatorio, max 100 caracteres
- Función: obligatoria, debe existir y estar vigente
- Usuario: debe tener perfil Administrador Nacional

**Tablas BD (operación INSERT):**
- BR_GRUPOS: registro del grupo con vigencia='S'
- BR_TITULOS: registro del título con orden=1
- BR_TITULOS_FUNCIONES: relación título-función
- BR_AUDITORIA_CAMBIOS: registro de auditoría

**Secuencias utilizadas:**
- SEQ_GRUPO_ID (genera ID del grupo)
- SEQ_TITULO_ID (genera ID del título)

## Dependencias

- Módulo VII (BR_FUNCIONES debe tener funciones vigentes disponibles)
- Módulo V (BR_RELACIONADOS para usuario creador)
- Sistema de autenticación (JWT con RUT en claims)

## Glosario

- **Grupo**: Conjunto de permisos (funciones) agrupados por contexto funcional (ej: "Sistema OT", "Gestión de Deudas")
- **Título**: Sección colapsable dentro de un grupo que agrupa funciones relacionadas (ej: "Reportes", "OT Opciones para jefaturas")
- **Función**: Permiso atómico que habilita una acción específica en el sistema (ej: "Consulta reportes OT", "Aprobar solicitud")
- **Vigente**: Estado activo del grupo (S=Sí, N=No). Grupos no vigentes no se pueden asignar a usuarios nuevos
- **Orden**: Posición de visualización de títulos dentro de un grupo (1=primero, 2=segundo, etc.)
