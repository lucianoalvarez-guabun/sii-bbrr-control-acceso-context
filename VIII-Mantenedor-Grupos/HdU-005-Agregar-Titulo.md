# HdU-005: Agregar Título a Grupo

## Información General

**ID:** HdU-005  
**Módulo:** VIII - Mantenedor de Grupos  
**Prioridad:** Alta  
**Estimación:** 3 puntos  

## Historia de Usuario

**Como** Administrador Nacional del SII  
**Quiero** agregar un nuevo título con sus funciones a un grupo existente  
**Para** expandir la estructura de permisos del grupo sin crear uno nuevo  

## Mockups de Referencia

- **image-0139.png**: Modal "Agregar Título" con input título y dropdown funciones múltiples
- **image-0127.png**: Vista del grupo con títulos en acordeones colapsables
- **image-0027.png**: Alerta de éxito "Registro guardado correctamente"

## Criterios de Aceptación

**AC-001:** El sistema debe mostrar un botón (+) "Agregar Título" en la sección de títulos del grupo (bajo el último título)

**AC-002:** Al hacer clic en "Agregar Título", el sistema debe abrir modal AddTituloModal con:
- Input "Ingrese nombre del Título" (obligatorio, max 100 caracteres)
- Dropdown "Seleccione Función" (obligatorio, permite selección múltiple con checkboxes)
- Botón X (cancelar)
- Botón ✓ (guardar)

**AC-003:** El dropdown de funciones debe cargar todas las funciones vigentes de BR_FUNCIONES (FUNC_VIGENTE='S')

**AC-004:** El dropdown debe permitir seleccionar múltiples funciones a la vez (checkbox por función)

**AC-005:** El sistema debe validar que el campo "nombre del Título" no esté vacío y no exceda 100 caracteres

**AC-006:** El sistema debe validar que se haya seleccionado al menos UNA función del dropdown

**AC-007:** Si las validaciones son exitosas, el sistema debe:
- Generar nuevo ID de título con SEQ_TITULO_ID.NEXTVAL
- Calcular orden automático (MAX(TITU_ORDEN) + 1 del grupo)
- Crear registro en BR_TITULOS
- Crear N registros en BR_TITULOS_FUNCIONES (uno por cada función seleccionada)
- Registrar auditoría con operación='INSERT'

**AC-008:** Si la creación es exitosa (201 Created), el sistema debe:
- Cerrar modal automáticamente
- Mostrar alerta verde "Registro guardado correctamente" por 3 segundos
- Agregar nuevo título al final de la lista de títulos del grupo (acordeón colapsado)
- Actualizar contador de títulos en UI

**AC-009:** Si el nombre del título ya existe dentro del mismo grupo, el sistema debe permitir el duplicado (NO es error)

**AC-010:** Si ocurre un error de servidor (500), el sistema debe:
- Mostrar mensaje "Error al agregar título. Intente nuevamente."
- Mantener modal abierto con datos ingresados
- Registrar error en logs

## Flujos Principales

### Flujo 1: Agregar Título con Múltiples Funciones

1. Usuario busca grupo "Sistema OT" (grupoId=123)
2. Sistema muestra grupo con 1 título existente: "OT Reportes" (orden 1)
3. Usuario hace clic en botón (+) "Agregar Título"
4. Sistema abre modal AddTituloModal vacío (image-0139)
5. Usuario ingresa "OT Opciones para jefaturas" en campo nombre del Título
6. Usuario abre dropdown "Seleccione Función"
7. Sistema muestra lista de funciones vigentes:
   - ☐ Función 1 (ID 17)
   - ☐ Función 2 (ID 18)
   - ☐ csdfcasc (ID 15)
   - ☐ Función 3 (ID 19)
8. Usuario selecciona 3 funciones:
   - ☑ Función 1 (ID 17)
   - ☑ Función 2 (ID 18)
   - ☐ csdfcasc (ID 15)
   - ☑ Función 3 (ID 19)
9. Sistema muestra contador "3 funciones seleccionadas"
10. Usuario hace clic en botón ✓
11. Sistema valida:
    - Título no vacío ✓
    - Título max 100 caracteres ✓
    - Al menos 1 función seleccionada ✓
12. Sistema ejecuta POST `/acaj-ms/api/v1/12.345.678-9/grupos/123/titulos` con body:
    ```json
    {
      "titulo": "OT Opciones para jefaturas",
      "funciones": [17, 18, 19]
    }
    ```
13. Backend calcula orden:
    ```sql
    SELECT COALESCE(MAX(TITU_ORDEN), 0) + 1 
    FROM BR_TITULOS 
    WHERE TITU_GRUP_ID = 123;
    -- Result: 2
    ```
14. Backend ejecuta INSERT título:
    ```sql
    INSERT INTO BR_TITULOS (
      TITU_ID, TITU_GRUP_ID, TITU_NOMBRE, TITU_ORDEN, 
      TITU_FECHA_CREACION, TITU_USUARIO_CREACION
    ) VALUES (
      SEQ_TITULO_ID.NEXTVAL, 123, 'OT Opciones para jefaturas', 2, 
      SYSDATE, '12.345.678-9'
    ) RETURNING TITU_ID INTO :tituloId;
    -- tituloId = 46
    ```
15. Backend ejecuta INSERT funciones (batch):
    ```sql
    INSERT INTO BR_TITULOS_FUNCIONES (
      TIFU_TITU_ID, TIFU_FUNC_ID, TIFU_FECHA_CREACION, TIFU_USUARIO_CREACION
    ) VALUES (46, 17, SYSDATE, '12.345.678-9');
    
    INSERT INTO BR_TITULOS_FUNCIONES (
      TIFU_TITU_ID, TIFU_FUNC_ID, TIFU_FECHA_CREACION, TIFU_USUARIO_CREACION
    ) VALUES (46, 18, SYSDATE, '12.345.678-9');
    
    INSERT INTO BR_TITULOS_FUNCIONES (
      TIFU_TITU_ID, TIFU_FUNC_ID, TIFU_FECHA_CREACION, TIFU_USUARIO_CREACION
    ) VALUES (46, 19, SYSDATE, '12.345.678-9');
    ```
16. Backend registra auditoría:
    ```sql
    INSERT INTO BR_AUDITORIA_CAMBIOS (
      AUDI_OPERACION, AUDI_TABLA, AUDI_REGISTRO_ID,
      AUDI_VALORES_NUEVOS, AUDI_JUSTIFICACION
    ) VALUES (
      'INSERT', 'BR_TITULOS', 46,
      JSON_OBJECT(
        'nombre' VALUE 'OT Opciones para jefaturas',
        'grupoId' VALUE 123,
        'funciones' VALUE JSON_ARRAY(17, 18, 19)
      ),
      'Se agregó el título OT Opciones para jefaturas al grupo Sistema OT con 3 funciones'
    );
    ```
17. Backend retorna 201 Created:
    ```json
    {
      "tituloId": 46,
      "orden": 2,
      "mensaje": "Título agregado exitosamente"
    }
    ```
18. Sistema cierra modal
19. Sistema muestra alerta verde "Registro guardado correctamente" (image-0027)
20. Sistema agrega nuevo acordeón "OT Opciones para jefaturas (3)" al final de la lista
21. Usuario expande acordeón y visualiza 3 funciones: Función 1, Función 2, Función 3 (image-0127)

### Flujo 2: Error - No Selecciona Funciones

1. Usuario sigue pasos 1-5 del Flujo 1
2. Usuario ingresa "Nuevo Título" en campo nombre
3. Usuario NO selecciona ninguna función del dropdown
4. Usuario hace clic en botón ✓
5. Sistema valida → encuentra error: 0 funciones seleccionadas
6. Sistema muestra mensaje de error bajo dropdown:
   - "Debe seleccionar al menos una función"
   - Marca dropdown con borde rojo
7. Modal permanece abierto
8. Usuario selecciona 1 función
9. Sistema elimina mensaje de error
10. Usuario hace clic en ✓ nuevamente
11. Sistema continúa con pasos 12-21 del Flujo 1

### Flujo 3: Cancelación

1. Usuario sigue pasos 1-8 del Flujo 1
2. Usuario hace clic en botón X (cancelar)
3. Sistema cierra modal sin ejecutar validaciones
4. Sistema NO guarda ningún dato
5. Lista de títulos permanece sin cambios

## Notas Técnicas

**API Consumida:**  
- POST /acaj-ms/api/v1/{rut}-{dv}/grupos/{grupoId}/titulos

**Validaciones:**
- Nombre del título: obligatorio, max 100 caracteres
- Funciones: al menos 1 función requerida (permite selección múltiple)
- Funciones seleccionadas: deben existir y estar vigentes
- Grupo: debe existir

**Tablas BD (operación INSERT):**
- BR_TITULOS: registro del título con orden auto-calculado (MAX+1)
- BR_TITULOS_FUNCIONES: N registros (uno por cada función seleccionada)
- BR_AUDITORIA_CAMBIOS: registro de auditoría

**Orden automático:**
- Se calcula como MAX(TITU_ORDEN) + 1 del grupo
- Nuevo título siempre se agrega al final de la lista

**Secuencias utilizadas:**
- SEQ_TITULO_ID (genera ID del título)

## Dependencias

- BR_GRUPOS (grupo padre debe existir)
- BR_FUNCIONES (funciones vigentes para selección)
- BR_TITULOS (tabla de títulos)
- BR_TITULOS_FUNCIONES (relación M:N)

## Glosario

- **Título**: Sección colapsable dentro de un grupo que agrupa funciones relacionadas
- **Orden automático**: Cálculo de posición secuencial (MAX + 1) para nuevos títulos
- **Selección múltiple**: Dropdown que permite elegir varias opciones con checkboxes
- **Batch INSERT**: Inserción de múltiples registros en una sola transacción para optimizar performance
