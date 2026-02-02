# HdU-007: Agregar Función a Título

## Información General

**ID:** HdU-007  
**Módulo:** VIII - Mantenedor de Grupos  
**Prioridad:** Alta  
**Estimación:** 2 puntos  

## Historia de Usuario

**Como** Administrador Nacional del SII  
**Quiero** agregar una función adicional a un título existente  
**Para** expandir los permisos de un título sin tener que recrearlo  

## Mockups de Referencia

- **image-0143.png**: Modal "Agregar Función" con título read-only y dropdown función
- **image-0127.png**: Vista del título expandido mostrando funciones
- **image-0027.png**: Alerta de éxito "Registro guardado correctamente"

## Criterios de Aceptación

**AC-001:** Cada título en la lista debe mostrar un botón (+) "Agregar Función" dentro de su acordeón expandido

**AC-002:** Al hacer clic en "Agregar Función", el sistema debe abrir modal AddFuncionModal con:
- Campo "Título" (read-only, muestra nombre del título seleccionado)
- Dropdown "Seleccione Función" (obligatorio, solo funciones vigentes NO asignadas al título)
- Botón X (cancelar)
- Botón ✓ (guardar)

**AC-003:** El dropdown debe cargar SOLO funciones vigentes (FUNC_VIGENTE='S') que NO estén ya asignadas al título actual

**AC-004:** El dropdown debe permitir seleccionar UNA función a la vez (NO es multi-select)

**AC-005:** El sistema debe validar que se haya seleccionado una función del dropdown

**AC-006:** El sistema debe verificar que la función NO esté ya asignada al título (evitar duplicados en relación N:M)

**AC-007:** Si las validaciones son exitosas, el sistema debe:
- Crear registro en BR_TITULOS_FUNCIONES vinculando título con función
- Registrar auditoría con operación='INSERT'

**AC-008:** Si la creación es exitosa (201 Created), el sistema debe:
- Cerrar modal automáticamente
- Mostrar alerta verde "Registro guardado correctamente" por 3 segundos
- Agregar nueva función al final de la lista de funciones del título (dentro del acordeón)
- Actualizar contador de funciones del título en UI

**AC-009:** Si la función ya está asignada al título (409 Conflict), el sistema debe mostrar:
- "La función ya está asignada a este título."
- Mantener modal abierto
- Marcar dropdown con borde rojo

**AC-010:** Si ocurre un error de servidor (500), el sistema debe:
- Mostrar mensaje "Error al agregar función. Intente nuevamente."
- Mantener modal abierto con datos ingresados

## Flujos Principales

### Flujo 1: Agregar Función Exitosamente

1. Usuario busca grupo "Sistema OT" (grupoId=123)
2. Sistema muestra grupo con título "OT Reportes" (tituloId=45, orden=1)
3. Usuario expande acordeón "OT Reportes"
4. Sistema muestra 2 funciones actuales:
   - "csdfcasc" (funcionId=15)
   - "Función 2" (funcionId=16)
5. Usuario hace clic en botón (+) "Agregar Función"
6. Sistema abre modal AddFuncionModal (image-0143)
7. Sistema muestra campo "Título" read-only con valor "OT Reportes"
8. Sistema carga dropdown "Seleccione Función" con funciones vigentes NO asignadas:
   - Consulta todas las funciones vigentes (FUNC_VIGENTE='S')
   - Filtra las ya asignadas al título (15, 16)
   - Dropdown muestra: "Función 1" (17), "Función 3" (19), "Función 4" (20)
9. Usuario selecciona "Función 3" (funcionId=19) del dropdown
10. Usuario hace clic en botón ✓
11. Sistema valida función seleccionada → OK
12. Sistema ejecuta POST `/acaj-ms/api/v1/12.345.678-9/grupos/123/titulos/45/funciones` con body:
    ```json
    {
      "funcionId": 19
    }
    ```
13. Backend verifica que función NO esté ya asignada:
    ```sql
    SELECT COUNT(*) 
    FROM BR_TITULOS_FUNCIONES 
    WHERE TIFU_TITU_ID = 45 AND TIFU_FUNC_ID = 19;
    -- Result: 0 (no existe, OK)
    ```
14. Backend ejecuta INSERT:
    ```sql
    INSERT INTO BR_TITULOS_FUNCIONES (
      TIFU_TITU_ID, TIFU_FUNC_ID, TIFU_FECHA_CREACION, TIFU_USUARIO_CREACION
    ) VALUES (
      45, 19, SYSDATE, '12.345.678-9'
    );
    ```
15. Backend registra auditoría:
    ```sql
    INSERT INTO BR_AUDITORIA_CAMBIOS (
      AUDI_OPERACION, AUDI_TABLA, AUDI_REGISTRO_ID,
      AUDI_VALORES_NUEVOS, AUDI_JUSTIFICACION
    ) VALUES (
      'INSERT', 'BR_TITULOS_FUNCIONES', NULL,
      JSON_OBJECT(
        'tituloId' VALUE 45,
        'funcionId' VALUE 19,
        'tituloNombre' VALUE 'OT Reportes',
        'funcionNombre' VALUE 'Función 3'
      ),
      'Se agregó la función Función 3 al título OT Reportes del grupo Sistema OT'
    );
    ```
16. Backend retorna 201 Created:
    ```json
    {
      "mensaje": "Función agregada exitosamente"
    }
    ```
17. Sistema cierra modal
18. Sistema muestra alerta verde "Registro guardado correctamente" (image-0027)
19. Sistema agrega "Función 3" al final de la lista de funciones en el acordeón
20. Sistema actualiza contador de funciones: "OT Reportes (3)" (image-0127)

### Flujo 2: Función Duplicada (409 Conflict)

1. Usuario sigue pasos 1-8 del Flujo 1
2. Usuario selecciona "csdfcasc" (funcionId=15) del dropdown (ya asignada)
3. Usuario hace clic en botón ✓
4. Sistema ejecuta POST con funcionId=15
5. Backend verifica duplicado:
   ```sql
   SELECT COUNT(*) 
   FROM BR_TITULOS_FUNCIONES 
   WHERE TIFU_TITU_ID = 45 AND TIFU_FUNC_ID = 15;
   -- Result: 1 (ya existe, CONFLICT)
   ```
6. Backend lanza ConflictException
7. Backend retorna 409 Conflict:
   ```json
   {
     "error": "Conflicto",
     "mensaje": "La función ya está asignada a este título."
   }
   ```
8. Sistema muestra mensaje de error bajo dropdown:
   - "La función ya está asignada a este título."
   - Marca dropdown con borde rojo
9. Modal permanece abierto
10. Usuario selecciona otra función (19)
11. Sistema elimina mensaje de error
12. Usuario hace clic en ✓ nuevamente
13. Sistema continúa con pasos 12-20 del Flujo 1

### Flujo 3: Cancelación

1. Usuario sigue pasos 1-9 del Flujo 1
2. Usuario hace clic en botón X (cancelar)
3. Sistema cierra modal sin ejecutar validaciones
4. Sistema NO guarda ningún dato
5. Lista de funciones permanece sin cambios

## Notas Técnicas

**API Consumida:**  
- POST /acaj-ms/api/v1/{rut}-{dv}/grupos/{grupoId}/titulos/{tituloId}/funciones

**Validaciones:**
- Función: obligatoria, debe existir y estar vigente
- Duplicado: función no debe estar ya asignada al título
- Título: debe existir y pertenecer al grupo

**Tablas BD (operación INSERT):**
- BR_TITULOS_FUNCIONES: registro de relación título-función
- BR_AUDITORIA_CAMBIOS: registro de auditoría

**Dropdown filtrado:**
- El frontend carga solo funciones vigentes NO asignadas al título
- Se filtra mediante consulta de funciones existentes menos las ya asignadas

**Relación N:M:**
- Una función puede estar en múltiples títulos
- Un título puede tener múltiples funciones
- PK compuesta (TIFU_TITU_ID, TIFU_FUNC_ID) evita duplicados

## Dependencias

- BR_TITULOS (título padre debe existir)
- BR_FUNCIONES (función debe existir y estar vigente)
- BR_TITULOS_FUNCIONES (tabla de relación M:N)

## Glosario

- **Read-only field**: Campo de formulario deshabilitado que muestra información contextual (no editable)
- **Dropdown filtrado**: Select que muestra solo opciones disponibles (excluye ya asignadas)
- **Relación N:M**: Relación muchos-a-muchos (un título puede tener muchas funciones, una función puede estar en muchos títulos)
- **Unicidad compuesta**: Constraint de PK compuesta (TIFU_TITU_ID, TIFU_FUNC_ID) que evita duplicados
