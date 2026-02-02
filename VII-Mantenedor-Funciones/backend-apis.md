# Backend APIs - Módulo VII: Mantenedor de Funciones

> **IMPORTANTE:** Este documento usa el modelo Oracle REAL existente:
> - Tabla: `BR_FUNCIONES` con campos `FUNS_*` (no `FUNC_*`)
> - Tabla: `BR_OPCIONES_FUNCION` (no `BR_FUNCION_OPCION`)
> - Tabla: `BR_ATRIBUCIONES_OPCION_FUNCION` (no `BR_FUNCION_OPCION_ATRIB_ALCANCE`)
> - **ALCANCES embebidos en `BR_ATRIBUCIONES.ATRI_CODIGO`** (2 caracteres: operación+alcance)
> - Ver `/docs/develop-plan/DDL/MODELO-ORACLE-REAL.sql` para detalles completos

## Base URL

```
/acaj-ms/api/v1/{rut}-{dv}/funciones
```

**Formato RUT:** `{rut}` incluye puntos, `{dv}` es dígito verificador separado  
**Ejemplo:** `/acaj-ms/api/v1/12.345.678-9/funciones`

---

## 1. Gestión de Funciones

### 1.1 Listar Funciones

**Endpoint:** `GET /acaj-ms/api/v1/{rut}-{dv}/funciones`

**Descripción:** Obtiene lista de funciones filtradas por vigencia. Usado por dropdown del SearchBar.

**Query Parameters:**

| Parámetro | Tipo | Obligatorio | Descripción |
|-----------|------|-------------|-------------|
| vigente | Boolean | No | `true`=solo vigentes, `false`=solo no vigentes. Default: `true` |
| search | String | No | Búsqueda parcial por nombre función (case insensitive) |

**Response 200 OK:**
```json
{
  "funciones": [
    {
      "id": 1,
      "codigo": "FUNC001",
      "nombre": "Usuario común web",
      "vigente": true,
      "fechaCreacion": "2026-01-15T10:30:00",
      "totalUsuarios": 150
    },
    {
      "id": 2,
      "codigo": "FUNC002",
      "nombre": "Mantención general",
      "vigente": true,
      "fechaCreacion": "2026-01-10T14:00:00",
      "totalUsuarios": 100
    }
  ],
  "total": 2
}
```

**Response 400 Bad Request:**
```json
{
  "codigo": "VALIDACION_ERROR",
  "mensaje": "Parámetro 'vigente' debe ser true o false",
  "timestamp": "2026-02-02T10:00:00"
}
```

**Lógica Backend:**

```sql
-- Query con modelo real Oracle
SELECT 
    f.FUNS_CODIGO as id,
    f.FUNS_CODIGO as codigo,
    f.FUNS_DESCRIPCION as nombre,
    f.FUNS_VIGENTE as vigente,
    COUNT(DISTINCT fcgr.FCGR_CGRE_RUT) as totalUsuarios
FROM AVAL.BR_FUNCIONES f
LEFT JOIN AVAL.BR_FUNCIONES_CARGO_RELACIONADO fcgr 
    ON fcgr.FCGR_FUNS_CODIGO = f.FUNS_CODIGO 
    AND fcgr.FCGR_FECHA_TERMINO > SYSDATE
WHERE f.FUNS_VIGENTE = :vigente
  AND (:search IS NULL OR UPPER(f.FUNS_DESCRIPCION) LIKE '%' || UPPER(:search) || '%')
GROUP BY f.FUNS_CODIGO, f.FUNS_DESCRIPCION, f.FUNS_VIGENTE
ORDER BY f.FUNS_DESCRIPCION ASC;
```

**NOTA:** Tabla real NO tiene campos `FECHA_CREACION` ni `USUARIO_CREACION`. Solo estructura básica de 3 columnas.

**Validaciones:**
- Parámetro `vigente` debe ser boolean válido
- Parámetro `search` max 200 caracteres
- RUT usuario autenticado debe existir y tener permisos

---

### 1.2 Obtener Función por ID

**Endpoint:** `GET /acaj-ms/api/v1/{rut}-{dv}/funciones/{id}`

**Descripción:** Obtiene función completa con opciones, atribuciones y alcances. Usado al buscar con lupa en SearchBar.

**Path Parameters:**

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| id | Long | ID único de la función |

**Response 200 OK:**
```json
{
  "id": 1,
  "codigo": "FUNC001",
  "nombre": "Usuario común web",
  "vigente": true,
  "fechaCreacion": "2026-01-15T10:30:00",
  "usuarioCreacion": "12.345.678-9",
  "totalUsuarios": 150,
  "opciones": [
    {
      "id": 10,
      "opcionCodigo": "OT",
      "opcionNombre": "Mantenedor usuarios relacionados",
      "orden": 1,
      "vigente": true,
      "totalUsuarios": 50,
      "atribucionesAlcances": [
        {
          "id": 100,
          "atribucionCodigo": "RE",
          "atribucionNombre": "Registro",
          "alcanceCodigo": "N",
          "alcanceNombre": "Nacional",
          "vigente": true
        },
        {
          "id": 101,
          "atribucionCodigo": "AR",
          "atribucionNombre": "Archivo",
          "alcanceCodigo": "R",
          "alcanceNombre": "Regional",
          "vigente": true
        }
      ]
    },
    {
      "id": 11,
      "opcionCodigo": "F2890",
      "opcionNombre": "Mantenedor Unidades",
      "orden": 2,
      "vigente": true,
      "totalUsuarios": 30,
      "atribucionesAlcances": [
        {
          "id": 102,
          "atribucionCodigo": "IN",
          "atribucionNombre": "Ingreso",
          "alcanceCodigo": "U",
          "alcanceNombre": "Unidad",
          "vigente": false
        }
      ]
    }
  ]
}
```

**Response 404 Not Found:**
```json
{
  "codigo": "FUNCION_NO_ENCONTRADA",
  "mensaje": "La función con ID 999 no existe",
  "timestamp": "2026-02-02T10:00:00"
}
```

**Lógica Backend:**

```sql
-- Query con modelo real Oracle (alcances embebidos en ATRI_CODIGO)
SELECT 
    f.FUNS_CODIGO as id,
    f.FUNS_CODIGO as codigo,
    f.FUNS_DESCRIPCION as nombre,
    f.FUNS_VIGENTE as vigente,
    -- Opciones
    of.OPCI_CODIGO,
    o.OPCI_NOMBRE as opcionNombre,
    of.TIPO_ACCESO,
    -- Atribuciones (incluyen alcance en código de 2 chars)
    aofu.AOFU_ATRI_CODIGO as atribucionCodigo,
    atri.ATRI_DESCRIPCION as atribucionDescripcion,
    SUBSTR(aofu.AOFU_ATRI_CODIGO, 1, 1) as operacion,
    SUBSTR(aofu.AOFU_ATRI_CODIGO, 2, 1) as alcance,
    CASE SUBSTR(aofu.AOFU_ATRI_CODIGO, 2, 1)
        WHEN 'F' THEN 'Personal'
        WHEN 'U' THEN 'Unidad'
        WHEN 'G' THEN 'Regional'
        WHEN 'N' THEN 'Nacional'
        ELSE 'Otro'
    END as alcanceNombre,
    aofu.AOFU_FECHA_INICIO,
    aofu.AOFU_FECHA_TERMINO
FROM AVAL.BR_FUNCIONES f
LEFT JOIN AVAL.BR_OPCIONES_FUNCION of 
    ON of.FUNS_CODIGO = f.FUNS_CODIGO
LEFT JOIN AVAL.BR_OPCIONES o 
    ON o.OPCI_CODIGO = of.OPCI_CODIGO
LEFT JOIN AVAL.BR_ATRIBUCIONES_OPCION_FUNCION aofu
    ON aofu.AOFU_FUNS_CODIGO = f.FUNS_CODIGO
    AND aofu.AOFU_OPCI_CODIGO = of.OPCI_CODIGO
LEFT JOIN AVAL.BR_ATRIBUCIONES atri
    ON atri.ATRI_CODIGO = aofu.AOFU_ATRI_CODIGO
WHERE f.FUNS_CODIGO = :funcionId
ORDER BY of.OPCI_CODIGO ASC, aofu.AOFU_ATRI_CODIGO ASC;

-- Subquery para contar usuarios por función
SELECT COUNT(DISTINCT USFU_RELA_RUT) 
FROM AVAL.BR_USUARIO_FUNCION 
WHERE USFU_FUNC_ID = :funcionId AND USFU_VIGENTE = 1;

-- Subquery para contar usuarios por opción
SELECT COUNT(DISTINCT uo.USOP_RELA_RUT)
FROM AVAL.BR_USUARIO_OPCION uo
JOIN AVAL.BR_FUNCION_OPCION fo ON fo.FUOP_OPCI_CODIGO = uo.USOP_OPCI_CODIGO
WHERE fo.FUOP_ID = :funcionOpcionId AND uo.USOP_VIGENTE = 1;
```

**Validaciones:**
- ID función debe ser numérico positivo
- Función debe existir (404 si no existe)
- Usuario debe tener permisos Admin Nacional o Consulta

**Notas:**
- Usar mapeador Java para convertir rows planas a estructura jerárquica JSON
- Opciones ordenadas por campo `FUOP_ORDEN` ASC
- Incluir opciones y atribuciones-alcances no vigentes (filtrado en frontend)

---

### 1.3 Crear Función

**Endpoint:** `POST /acaj-ms/api/v1/{rut}-{dv}/funciones`

**Descripción:** Crea nueva función con primera opción, atribución y alcance. Función se crea vigente por defecto.

**Request Body:**
```json
{
  "nombre": "Usuario común web",
  "opcionId": 901,
  "atribucionId": 10,
  "alcanceId": 1
}
```

**Validaciones Request:**
- `nombre`: obligatorio, max 500 caracteres, alfanumérico/espacios/guiones, único entre vigentes
- `opcionId`: obligatorio, debe existir en BR_OPCIONES y estar vigente
- `atribucionId`: obligatorio, debe existir en BR_OPCION_ATRIBUCION para esa opción
- `alcanceId`: obligatorio, debe existir en BR_ALCANCES

**Response 201 Created:**
```json
{
  "id": 123,
  "codigo": "FUNC123",
  "nombre": "Usuario común web",
  "vigente": true,
  "fechaCreacion": "2026-02-02T10:30:00",
  "usuarioCreacion": "12.345.678-9",
  "mensaje": "Función creada exitosamente con opción inicial"
}
```

**Response 409 Conflict - Duplicado:**
```json
{
  "codigo": "FUNCION_DUPLICADA",
  "mensaje": "Ya existe una función vigente con el nombre 'Usuario común web'",
  "funcionExistenteId": 45,
  "timestamp": "2026-02-02T10:30:00"
}
```

**Response 400 Bad Request - Validación:**
```json
{
  "codigo": "VALIDACION_ERROR",
  "mensaje": "Error de validación en los campos",
  "errores": [
    {
      "campo": "nombre",
      "mensaje": "El nombre es obligatorio"
    },
    {
      "campo": "opcionId",
      "mensaje": "La opción con ID 999 no existe o no está vigente"
    }
  ],
  "timestamp": "2026-02-02T10:30:00"
}
```

**Lógica Backend:**

```sql
-- 1. Validar nombre único (case insensitive)
SELECT COUNT(*) 
FROM AVAL.BR_FUNCIONES 
WHERE UPPER(FUNC_NOMBRE) = UPPER(:nombre) 
  AND FUNC_VIGENTE = 1;
-- Si COUNT > 0: retornar HTTP 409

-- 2. Validar opcionId existe y vigente
SELECT COUNT(*) 
FROM AVAL.BR_OPCIONES 
WHERE OPCI_CODIGO = :opcionId 
  AND OPCI_VIGENTE = 1;
-- Si COUNT = 0: retornar HTTP 400

-- 3. Validar atribucionId válido para esa opción
SELECT COUNT(*) 
FROM AVAL.BR_OPCION_ATRIBUCION 
WHERE OPAT_CODIGO = :atribucionId 
  AND OPAT_OPCI_CODIGO = :opcionId 
  AND OPAT_VIGENTE = 1;
-- Si COUNT = 0: retornar HTTP 400

-- 4. Validar alcanceId existe
SELECT COUNT(*) 
FROM AVAL.BR_ALCANCES 
WHERE ALCA_CODIGO = :alcanceId;
-- Si COUNT = 0: retornar HTTP 400

-- 5. Generar código correlativo
SELECT 'FUNC' || LPAD(NVL(MAX(TO_NUMBER(SUBSTR(FUNC_CODIGO, 5))), 0) + 1, 3, '0')
FROM AVAL.BR_FUNCIONES;

-- 6. INSERT transaccional (BEGIN/COMMIT o @Transactional)
-- 6.1. INSERT Función
INSERT INTO AVAL.BR_FUNCIONES (
    FUNC_ID, FUNC_CODIGO, FUNC_NOMBRE, FUNC_VIGENTE, 
    FUNC_FECHA_CREACION, FUNC_USUARIO_CREACION
) VALUES (
    SEQ_FUNCIONES.NEXTVAL, :codigo, :nombre, 1, 
    SYSDATE, :rutUsuario
) RETURNING FUNC_ID INTO :funcionId;

-- 6.2. INSERT FuncionOpcion (orden = 1)
INSERT INTO AVAL.BR_FUNCION_OPCION (
    FUOP_ID, FUOP_FUNC_ID, FUOP_OPCI_CODIGO, FUOP_ORDEN, 
    FUOP_VIGENTE, FUOP_FECHA_CREACION
) VALUES (
    SEQ_FUNCION_OPCION.NEXTVAL, :funcionId, :opcionId, 1, 
    1, SYSDATE
) RETURNING FUOP_ID INTO :funcionOpcionId;

-- 6.3. INSERT FuncionOpcionAtribAlcance
INSERT INTO AVAL.BR_FUNCION_OPCION_ATRIB_ALCANCE (
    FOAA_ID, FOAA_FUOP_ID, FOAA_OPAT_CODIGO, 
    FOAA_ALCANCE_CODIGO, FOAA_VIGENTE, FOAA_FECHA_CREACION
) VALUES (
    SEQ_FUNCION_OPCION_ATRIB_ALCANCE.NEXTVAL, :funcionOpcionId, 
    :atribucionId, :alcanceId, 1, SYSDATE
);

-- 6.4. Auditoría
INSERT INTO AVAL.BR_AUDITORIA_FUNCIONES (
    AUDI_ID, AUDI_TABLA, AUDI_OPERACION, AUDI_REGISTRO_ID,
    AUDI_VALORES_NUEVOS, AUDI_RUT_EJECUTOR, AUDI_FECHA, 
    AUDI_TICKET, AUDI_JUSTIFICACION
) VALUES (
    SEQ_AUDITORIA.NEXTVAL, 'BR_FUNCIONES', 'INSERT', :funcionId,
    '{"nombre":"' || :nombre || '","vigente":true}', 
    :rutUsuario, SYSTIMESTAMP, :ticket, 'Creación función ' || :nombre
);
```

**Validaciones de Negocio:**
- Nombre único case insensitive entre funciones vigentes
- OpcionId debe existir y estar vigente
- AtribucionId debe pertenecer a esa opción específica
- AlcanceId debe existir
- Usuario debe tener perfil Administrador Nacional (validar con claim JWT)

---

### 1.4 Modificar Vigencia de Función

**Endpoint:** `PUT /acaj-ms/api/v1/{rut}-{dv}/funciones/{id}/vigencia`

**Descripción:** Activa o desactiva función. Al desactivar, aplica cascada a opciones y atribuciones-alcances.

**Request Body:**
```json
{
  "vigente": false
}
```

**Response 200 OK:**
```json
{
  "id": 123,
  "vigente": false,
  "usuariosAfectados": 100,
  "mensaje": "Vigencia de función actualizada. 100 usuarios afectados.",
  "timestamp": "2026-02-02T10:35:00"
}
```

**Response 400 Bad Request:**
```json
{
  "codigo": "VALIDACION_ERROR",
  "mensaje": "El campo 'vigente' debe ser true o false",
  "timestamp": "2026-02-02T10:35:00"
}
```

**Lógica Backend:**

```sql
-- 1. Contar usuarios asignados
SELECT COUNT(DISTINCT USFU_RELA_RUT) as totalUsuarios
FROM AVAL.BR_USUARIO_FUNCION
WHERE USFU_FUNC_ID = :funcionId AND USFU_VIGENTE = 1;

-- 2. UPDATE función
UPDATE AVAL.BR_FUNCIONES
SET FUNC_VIGENTE = :vigente,
    FUNC_FECHA_MODIFICACION = SYSDATE,
    FUNC_USUARIO_MODIFICACION = :rutUsuario
WHERE FUNC_ID = :funcionId;

-- 3. Si vigente = false: cascada a opciones y atrib-alc
UPDATE AVAL.BR_FUNCION_OPCION
SET FUOP_VIGENTE = 0,
    FUOP_FECHA_MODIFICACION = SYSDATE
WHERE FUOP_FUNC_ID = :funcionId;

UPDATE AVAL.BR_FUNCION_OPCION_ATRIB_ALCANCE
SET FOAA_VIGENTE = 0,
    FOAA_FECHA_MODIFICACION = SYSDATE
WHERE FOAA_FUOP_ID IN (
    SELECT FUOP_ID FROM AVAL.BR_FUNCION_OPCION WHERE FUOP_FUNC_ID = :funcionId
);

-- 4. Auditoría
INSERT INTO AVAL.BR_AUDITORIA_FUNCIONES (...)
VALUES (..., 'UPDATE', 'Modificar vigencia función a ' || :vigente, ...);
```

**Validaciones:**
- ID función debe existir
- Campo `vigente` debe ser boolean
- Si hay usuarios asignados y vigente=false: frontend debe mostrar confirmación (backend permite operación)

**Notas:**
- Frontend debe solicitar confirmación si `usuariosAfectados > 0` y `vigente=false`
- Cascada solo aplica al desactivar (vigente=false), NO al activar
- Al activar función, opciones y atrib-alc mantienen su estado individual

---

### 1.5 Eliminar Función

**Endpoint:** `DELETE /acaj-ms/api/v1/{rut}-{dv}/funciones/{id}`

**Descripción:** Elimina función permanentemente con todas sus opciones y atribuciones-alcances en cascada. Solo si no tiene usuarios asignados.

**Response 204 No Content:**
(Sin body, función eliminada exitosamente)

**Response 409 Conflict - Tiene Usuarios:**
```json
{
  "codigo": "FUNCION_CON_USUARIOS",
  "mensaje": "No se puede eliminar la función porque tiene 100 usuarios asignados. Primero debe reasignar o eliminar los usuarios.",
  "totalUsuarios": 100,
  "timestamp": "2026-02-02T10:40:00"
}
```

**Response 404 Not Found:**
```json
{
  "codigo": "FUNCION_NO_ENCONTRADA",
  "mensaje": "La función con ID 999 no existe",
  "timestamp": "2026-02-02T10:40:00"
}
```

**Lógica Backend:**

```sql
-- 1. Validar función existe
SELECT COUNT(*) FROM AVAL.BR_FUNCIONES WHERE FUNC_ID = :funcionId;
-- Si COUNT = 0: retornar HTTP 404

-- 2. Validar sin usuarios asignados
SELECT COUNT(DISTINCT USFU_RELA_RUT) as totalUsuarios
FROM AVAL.BR_USUARIO_FUNCION
WHERE USFU_FUNC_ID = :funcionId AND USFU_VIGENTE = 1;
-- Si totalUsuarios > 0: retornar HTTP 409

-- 3. Obtener nombre función para auditoría
SELECT FUNC_NOMBRE INTO :nombreFuncion
FROM AVAL.BR_FUNCIONES
WHERE FUNC_ID = :funcionId;

-- 4. DELETE transaccional (cascada automática con ON DELETE CASCADE)
DELETE FROM AVAL.BR_FUNCIONES WHERE FUNC_ID = :funcionId;
-- Cascada automática elimina:
--   - BR_FUNCION_OPCION (por FK)
--   - BR_FUNCION_OPCION_ATRIB_ALCANCE (por FK)

-- 5. Auditoría
INSERT INTO AVAL.BR_AUDITORIA_FUNCIONES (
    AUDI_ID, AUDI_TABLA, AUDI_OPERACION, AUDI_REGISTRO_ID,
    AUDI_VALORES_ANTERIORES, AUDI_RUT_EJECUTOR, AUDI_FECHA,
    AUDI_TICKET, AUDI_JUSTIFICACION
) VALUES (
    SEQ_AUDITORIA.NEXTVAL, 'BR_FUNCIONES', 'DELETE', :funcionId,
    '{"nombre":"' || :nombreFuncion || '","vigente":true}',
    :rutUsuario, SYSTIMESTAMP, :ticket, 'Eliminación función ' || :nombreFuncion
);
```

**Validaciones:**
- Función debe existir (404 si no)
- Función NO debe tener usuarios asignados vigentes (409 si tiene)
- Usuario debe tener perfil Administrador Nacional

**Notas:**
- Cascada BD elimina opciones y atrib-alc automáticamente (ON DELETE CASCADE en FK)
- Alternativa a eliminar: desactivar vigencia (HdU-003) si tiene usuarios

---

## 2. Gestión de Opciones de Función

### 2.1 Agregar Opción a Función

**Endpoint:** `POST /acaj-ms/api/v1/{rut}-{dv}/funciones/{funcionId}/opciones`

**Descripción:** Agrega opción con múltiples atribuciones-alcances a función existente.

**Request Body:**
```json
{
  "opcionId": 902,
  "atribucionesAlcances": [
    {
      "atribucionId": 10,
      "alcanceId": 1
    },
    {
      "atribucionId": 20,
      "alcanceId": 2
    }
  ]
}
```

**Validaciones Request:**
- `opcionId`: obligatorio, debe existir en BR_OPCIONES, NO debe estar ya en esta función
- `atribucionesAlcances`: array obligatorio, min 1 elemento, max 50
- `atribucionId`: debe existir en BR_OPCION_ATRIBUCION para esa opción
- `alcanceId`: debe existir en BR_ALCANCES
- Combos atrib-alc deben ser únicos dentro del array (no duplicados)

**Response 201 Created:**
```json
{
  "id": 456,
  "opcionCodigo": "F2890",
  "opcionNombre": "Mantenedor Unidades",
  "orden": 3,
  "vigente": true,
  "atribucionesAlcances": [
    {
      "id": 789,
      "atribucionCodigo": "RE",
      "atribucionNombre": "Registro",
      "alcanceCodigo": "N",
      "alcanceNombre": "Nacional",
      "vigente": true
    },
    {
      "id": 790,
      "atribucionCodigo": "AR",
      "atribucionNombre": "Archivo",
      "alcanceCodigo": "R",
      "alcanceNombre": "Regional",
      "vigente": true
    }
  ],
  "mensaje": "Opción agregada exitosamente con 2 atribuciones-alcances"
}
```

**Response 409 Conflict - Opción ya existe:**
```json
{
  "codigo": "OPCION_DUPLICADA",
  "mensaje": "La opción F2890 ya existe en esta función",
  "opcionId": 902,
  "timestamp": "2026-02-02T11:00:00"
}
```

**Lógica Backend:**

```sql
-- 1. Validar función existe
SELECT COUNT(*) FROM AVAL.BR_FUNCIONES WHERE FUNC_ID = :funcionId;

-- 2. Validar opción NO existe en función
SELECT COUNT(*) 
FROM AVAL.BR_FUNCION_OPCION 
WHERE FUOP_FUNC_ID = :funcionId AND FUOP_OPCI_CODIGO = :opcionId;
-- Si COUNT > 0: retornar HTTP 409

-- 3. Validar opción existe y vigente
SELECT COUNT(*) 
FROM AVAL.BR_OPCIONES 
WHERE OPCI_CODIGO = :opcionId AND OPCI_VIGENTE = 1;

-- 4. Calcular orden (último + 1)
SELECT NVL(MAX(FUOP_ORDEN), 0) + 1 INTO :nuevoOrden
FROM AVAL.BR_FUNCION_OPCION
WHERE FUOP_FUNC_ID = :funcionId;

-- 5. INSERT FuncionOpcion
INSERT INTO AVAL.BR_FUNCION_OPCION (
    FUOP_ID, FUOP_FUNC_ID, FUOP_OPCI_CODIGO, FUOP_ORDEN, 
    FUOP_VIGENTE, FUOP_FECHA_CREACION
) VALUES (
    SEQ_FUNCION_OPCION.NEXTVAL, :funcionId, :opcionId, :nuevoOrden,
    1, SYSDATE
) RETURNING FUOP_ID INTO :funcionOpcionId;

-- 6. INSERT múltiples atribuciones-alcances (loop en Java)
FOR EACH atribAlc IN :atribucionesAlcances LOOP
    -- Validar atribución válida para opción
    SELECT COUNT(*) 
    FROM AVAL.BR_OPCION_ATRIBUCION 
    WHERE OPAT_CODIGO = atribAlc.atribucionId 
      AND OPAT_OPCI_CODIGO = :opcionId 
      AND OPAT_VIGENTE = 1;
    
    INSERT INTO AVAL.BR_FUNCION_OPCION_ATRIB_ALCANCE (
        FOAA_ID, FOAA_FUOP_ID, FOAA_OPAT_CODIGO, 
        FOAA_ALCANCE_CODIGO, FOAA_VIGENTE, FOAA_FECHA_CREACION
    ) VALUES (
        SEQ_FUNCION_OPCION_ATRIB_ALCANCE.NEXTVAL, :funcionOpcionId,
        atribAlc.atribucionId, atribAlc.alcanceId, 1, SYSDATE
    );
END LOOP;

-- 7. Auditoría
INSERT INTO AVAL.BR_AUDITORIA_FUNCIONES (...)
VALUES (..., 'INSERT', 'Agregar opción ' || :opcionId || ' a función', ...);
```

**Validaciones:**
- OpcionId NO debe existir ya en la función
- Cada atribucionId debe pertenecer a esa opción
- AlcanceId debe existir
- Combos atrib-alc únicos dentro de la misma opción

---

### 2.2 Eliminar Opción de Función

**Endpoint:** `DELETE /acaj-ms/api/v1/{rut}-{dv}/funciones/{funcionId}/opciones/{opcionId}`

**Descripción:** Elimina opción de función con todas sus atribuciones-alcances. Solo si opción no tiene usuarios asignados.

**Response 204 No Content:**
(Sin body, opción eliminada exitosamente)

**Response 409 Conflict:**
```json
{
  "codigo": "OPCION_CON_USUARIOS",
  "mensaje": "No se puede eliminar la opción porque tiene usuarios asignados",
  "totalUsuarios": 25,
  "timestamp": "2026-02-02T11:15:00"
}
```

**Lógica Backend:**

```sql
-- 1. Validar opción sin usuarios
SELECT COUNT(DISTINCT uo.USOP_RELA_RUT) as totalUsuarios
FROM AVAL.BR_USUARIO_OPCION uo
JOIN AVAL.BR_FUNCION_OPCION fo ON fo.FUOP_OPCI_CODIGO = uo.USOP_OPCI_CODIGO
WHERE fo.FUOP_ID = :funcionOpcionId AND uo.USOP_VIGENTE = 1;
-- Si totalUsuarios > 0: retornar HTTP 409

-- 2. DELETE opción (cascada automática a atrib-alc)
DELETE FROM AVAL.BR_FUNCION_OPCION 
WHERE FUOP_FUNC_ID = :funcionId AND FUOP_ID = :funcionOpcionId;
-- Cascada elimina BR_FUNCION_OPCION_ATRIB_ALCANCE

-- 3. Auditoría
INSERT INTO AVAL.BR_AUDITORIA_FUNCIONES (...);
```

---

### 2.3 Reordenar Opciones

**Endpoint:** `PUT /acaj-ms/api/v1/{rut}-{dv}/funciones/{funcionId}/opciones/orden`

**Descripción:** Actualiza orden de opciones tras drag and drop.

**Request Body:**
```json
{
  "orden": [
    {
      "opcionId": 456,
      "orden": 1
    },
    {
      "opcionId": 123,
      "orden": 2
    },
    {
      "opcionId": 789,
      "orden": 3
    }
  ]
}
```

**Response 200 OK:**
```json
{
  "mensaje": "Orden de opciones actualizado correctamente",
  "opcionesActualizadas": 3
}
```

**Lógica Backend:**

```sql
-- UPDATE en batch (loop en Java)
FOR EACH item IN :orden LOOP
    UPDATE AVAL.BR_FUNCION_OPCION
    SET FUOP_ORDEN = item.orden,
        FUOP_FECHA_MODIFICACION = SYSDATE
    WHERE FUOP_ID = item.opcionId 
      AND FUOP_FUNC_ID = :funcionId;
END LOOP;

-- Auditoría
INSERT INTO AVAL.BR_AUDITORIA_FUNCIONES (...)
VALUES (..., 'UPDATE', 'Reordenar opciones función', ...);
```

---

## 3. Gestión de Atribuciones-Alcances

### 3.1 Agregar Atribución-Alcance

**Endpoint:** `POST /acaj-ms/api/v1/{rut}-{dv}/funciones/{funcionId}/opciones/{opcionId}/atribuciones-alcances`

**Descripción:** Agrega atribución-alcance individual a opción existente.

**Request Body:**
```json
{
  "atribucionId": 15,
  "alcanceId": 3
}
```

**Response 201 Created:**
```json
{
  "id": 999,
  "atribucionCodigo": "EL",
  "atribucionNombre": "Eliminar",
  "alcanceCodigo": "U",
  "alcanceNombre": "Unidad",
  "vigente": true,
  "mensaje": "Atribución-alcance agregado exitosamente"
}
```

**Response 409 Conflict:**
```json
{
  "codigo": "ATRIB_ALC_DUPLICADO",
  "mensaje": "La combinación EL-U ya existe para esta opción",
  "timestamp": "2026-02-02T11:30:00"
}
```

**Lógica Backend:**

```sql
-- 1. Validar combo NO existe
SELECT COUNT(*) 
FROM AVAL.BR_FUNCION_OPCION_ATRIB_ALCANCE foa
JOIN AVAL.BR_FUNCION_OPCION fo ON fo.FUOP_ID = foa.FOAA_FUOP_ID
WHERE fo.FUOP_FUNC_ID = :funcionId
  AND fo.FUOP_ID = :funcionOpcionId
  AND foa.FOAA_OPAT_CODIGO = :atribucionId
  AND foa.FOAA_ALCANCE_CODIGO = :alcanceId;
-- Si COUNT > 0: retornar HTTP 409

-- 2. Validar atribución válida para opción
SELECT COUNT(*) 
FROM AVAL.BR_OPCION_ATRIBUCION oa
JOIN AVAL.BR_FUNCION_OPCION fo ON fo.FUOP_OPCI_CODIGO = oa.OPAT_OPCI_CODIGO
WHERE fo.FUOP_ID = :funcionOpcionId
  AND oa.OPAT_CODIGO = :atribucionId
  AND oa.OPAT_VIGENTE = 1;

-- 3. INSERT atribución-alcance
INSERT INTO AVAL.BR_FUNCION_OPCION_ATRIB_ALCANCE (
    FOAA_ID, FOAA_FUOP_ID, FOAA_OPAT_CODIGO, 
    FOAA_ALCANCE_CODIGO, FOAA_VIGENTE, FOAA_FECHA_CREACION
) VALUES (
    SEQ_FUNCION_OPCION_ATRIB_ALCANCE.NEXTVAL, :funcionOpcionId,
    :atribucionId, :alcanceId, 1, SYSDATE
);

-- 4. Auditoría
INSERT INTO AVAL.BR_AUDITORIA_FUNCIONES (...);
```

---

### 3.2 Modificar Vigencia de Atribución-Alcance

**Endpoint:** `PUT /acaj-ms/api/v1/{rut}-{dv}/funciones/{funcionId}/opciones/{opcionId}/atribuciones-alcances/{id}/vigencia`

**Request Body:**
```json
{
  "vigente": false
}
```

**Response 200 OK:**
```json
{
  "id": 999,
  "vigente": false,
  "mensaje": "Vigencia actualizada correctamente"
}
```

**Lógica Backend:**

```sql
UPDATE AVAL.BR_FUNCION_OPCION_ATRIB_ALCANCE
SET FOAA_VIGENTE = :vigente,
    FOAA_FECHA_MODIFICACION = SYSDATE
WHERE FOAA_ID = :atribAlcId;

INSERT INTO AVAL.BR_AUDITORIA_FUNCIONES (...);
```

---

### 3.3 Eliminar Atribución-Alcance

**Endpoint:** `DELETE /acaj-ms/api/v1/{rut}-{dv}/funciones/{funcionId}/opciones/{opcionId}/atribuciones-alcances/{id}`

**Response 204 No Content:**
(Sin body, eliminado exitosamente)

**Lógica Backend:**

```sql
DELETE FROM AVAL.BR_FUNCION_OPCION_ATRIB_ALCANCE
WHERE FOAA_ID = :atribAlcId;

INSERT INTO AVAL.BR_AUDITORIA_FUNCIONES (...);
```

---

## 4. Visualización de Usuarios

### 4.1 Listar Usuarios de Función

**Endpoint:** `GET /acaj-ms/api/v1/{rut}-{dv}/funciones/{id}/usuarios`

**Descripción:** Obtiene lista de usuarios asignados a función con vigencias. Usado por UserListModal.

**Response 200 OK:**
```json
{
  "funcionNombre": "Usuario común web",
  "totalUsuarios": 150,
  "usuarios": [
    {
      "rut": "12.345.678-9",
      "nombre": "Juan Pérez González",
      "vigenciaInicial": "2026-01-01",
      "vigenciaFinal": "2026-12-31"
    },
    {
      "rut": "98.765.432-1",
      "nombre": "María López Silva",
      "vigenciaInicial": "2026-01-15",
      "vigenciaFinal": null
    }
  ]
}
```

**Response 404 Not Found:**
```json
{
  "codigo": "FUNCION_NO_ENCONTRADA",
  "mensaje": "La función con ID 999 no existe"
}
```

**Lógica Backend:**

```sql
-- Query usuarios con vigencias
SELECT 
    r.RELA_RUT as rut,
    r.RELA_NOMBRE as nombre,
    uf.USFU_VIGENCIA_INICIAL as vigenciaInicial,
    uf.USFU_VIGENCIA_FINAL as vigenciaFinal,
    uf.USFU_VIGENTE as vigente
FROM AVAL.BR_USUARIO_FUNCION uf
JOIN AVAL.BR_RELACIONADOS r ON r.RELA_RUT = uf.USFU_RELA_RUT
WHERE uf.USFU_FUNC_ID = :funcionId
ORDER BY uf.USFU_VIGENTE DESC, uf.USFU_VIGENCIA_FINAL DESC NULLS FIRST;

-- Formato RUT con puntos: XX.XXX.XXX-DV en Java
-- Formato fecha: DD-MM-YYYY
```

**Notas:**
- Ordenar: vigentes primero, luego por vigencia final descendente (indefinidas primero)
- Incluir usuarios vigentes y no vigentes (frontend puede filtrar)
- Sin paginación (max 1000 usuarios esperados por función)

---

### 4.2 Listar Usuarios de Opción

**Endpoint:** `GET /acaj-ms/api/v1/{rut}-{dv}/funciones/{funcionId}/opciones/{opcionId}/usuarios`

**Descripción:** Obtiene lista de usuarios asignados a opción específica de función.

**Response 200 OK:**
```json
{
  "opcionNombre": "OT Mantenedor usuarios relacionados",
  "totalUsuarios": 50,
  "usuarios": [
    {
      "rut": "12.345.678-9",
      "nombre": "Juan Pérez González",
      "vigenciaInicial": "2026-01-01",
      "vigenciaFinal": "2026-12-31"
    }
  ]
}
```

**Lógica Backend:**

```sql
SELECT 
    r.RELA_RUT as rut,
    r.RELA_NOMBRE as nombre,
    uo.USOP_VIGENCIA_INICIAL as vigenciaInicial,
    uo.USOP_VIGENCIA_FINAL as vigenciaFinal,
    uo.USOP_VIGENTE as vigente
FROM AVAL.BR_USUARIO_OPCION uo
JOIN AVAL.BR_FUNCION_OPCION fo ON fo.FUOP_OPCI_CODIGO = uo.USOP_OPCI_CODIGO
JOIN AVAL.BR_RELACIONADOS r ON r.RELA_RUT = uo.USOP_RELA_RUT
WHERE fo.FUOP_FUNC_ID = :funcionId
  AND fo.FUOP_ID = :funcionOpcionId
ORDER BY uo.USOP_VIGENTE DESC, uo.USOP_VIGENCIA_FINAL DESC NULLS FIRST;
```

---

## 5. Datos Auxiliares (Dropdowns)

### 5.1 Listar Opciones Disponibles

**Endpoint:** `GET /acaj-ms/api/v1/{rut}-{dv}/opciones`

**Descripción:** Obtiene lista de opciones de aplicativos para dropdowns.

**Query Parameters:**

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| vigente | Boolean | Default: `true` |
| search | String | Búsqueda parcial por nombre |

**Response 200 OK:**
```json
{
  "opciones": [
    {
      "id": 901,
      "codigo": "OT",
      "nombre": "Mantenedor usuarios relacionados",
      "descripcion": "Permite gestionar usuarios relacionados del sistema",
      "vigente": true
    },
    {
      "id": 902,
      "codigo": "F2890",
      "nombre": "Mantenedor Unidades",
      "descripcion": "Gestión de unidades de negocio",
      "vigente": true
    }
  ]
}
```

**Lógica Backend:**

```sql
SELECT 
    OPCI_CODIGO as id,
    OPCI_CODIGO as codigo,
    OPCI_NOMBRE as nombre,
    OPCI_DESCRIPCION as descripcion,
    OPCI_VIGENTE as vigente
FROM AVAL.BR_OPCIONES
WHERE OPCI_VIGENTE = :vigente
  AND (:search IS NULL OR UPPER(OPCI_NOMBRE) LIKE '%' || UPPER(:search) || '%')
ORDER BY OPCI_NOMBRE ASC;
```

---

### 5.2 Listar Atribuciones por Opción

**Endpoint:** `GET /acaj-ms/api/v1/{rut}-{dv}/atribuciones`

**Query Parameters:**

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| opcionId | Long | Filtra atribuciones de opción específica |

**Response 200 OK:**
```json
{
  "atribuciones": [
    {
      "id": 10,
      "codigo": "RE",
      "nombre": "Registro",
      "descripcion": "Permite registrar nuevos datos",
      "vigente": true
    },
    {
      "id": 20,
      "codigo": "AR",
      "nombre": "Archivo",
      "descripcion": "Permite archivar registros",
      "vigente": true
    }
  ]
}
```

**Lógica Backend:**

```sql
SELECT 
    OPAT_CODIGO as id,
    OPAT_CODIGO as codigo,
    OPAT_DESCRIPCION as nombre,
    OPAT_DESCRIPCION as descripcion,
    OPAT_VIGENTE as vigente
FROM AVAL.BR_OPCION_ATRIBUCION
WHERE OPAT_VIGENTE = 1
  AND (:opcionId IS NULL OR OPAT_OPCI_CODIGO = :opcionId)
ORDER BY OPAT_DESCRIPCION ASC;
```

---

### 5.3 Listar Alcances

**Endpoint:** `GET /acaj-ms/api/v1/{rut}-{dv}/alcances`

**Response 200 OK:**
```json
{
  "alcances": [
    {
      "id": 1,
      "codigo": "N",
      "nombre": "Nacional",
      "descripcion": "Alcance nivel nacional"
    },
    {
      "id": 2,
      "codigo": "R",
      "nombre": "Regional",
      "descripcion": "Alcance nivel regional"
    },
    {
      "id": 3,
      "codigo": "U",
      "nombre": "Unidad",
      "descripcion": "Alcance nivel unidad"
    },
    {
      "id": 4,
      "codigo": "P",
      "nombre": "Personal",
      "descripcion": "Alcance nivel personal"
    }
  ]
}
```

**Lógica Backend:**

```sql
SELECT 
    ALCA_CODIGO as id,
    ALCA_CODIGO as codigo,
    ALCA_NOMBRE as nombre,
    ALCA_DESCRIPCION as descripcion
FROM AVAL.BR_ALCANCES
ORDER BY ALCA_ORDEN ASC;
```

---

## 6. Tabla de Mapeo Frontend/Backend/BD

| Campo Frontend | Campo Backend (JSON) | Tabla/Campo Oracle | Tipo Oracle | Validación |
|----------------|---------------------|-------------------|-------------|------------|
| Nombre función | `nombre` | BR_FUNCIONES.FUNC_NOMBRE | VARCHAR2(500) | Obligatorio, único, max 500 |
| Código función | `codigo` | BR_FUNCIONES.FUNC_CODIGO | VARCHAR2(10) | Auto-generado correlativo |
| Vigente función | `vigente` | BR_FUNCIONES.FUNC_VIGENTE | NUMBER(1) | 0=no vigente, 1=vigente |
| Opción ID | `opcionId` | BR_FUNCIONES.FUOP_OPCI_CODIGO | NUMBER | FK a BR_OPCIONES.OPCI_CODIGO |
| Atribución ID | `atribucionId` | BR_FUNCION_OPCION_ATRIB_ALCANCE.FOAA_OPAT_CODIGO | NUMBER | FK a BR_OPCION_ATRIBUCION.OPAT_CODIGO |
| Alcance ID | `alcanceId` | BR_FUNCION_OPCION_ATRIB_ALCANCE.FOAA_ALCANCE_CODIGO | NUMBER | FK a BR_ALCANCES.ALCA_CODIGO |
| Orden opción | `orden` | BR_FUNCION_OPCION.FUOP_ORDEN | NUMBER | Secuencial, usado para drag-drop |
| Total usuarios | `totalUsuarios` | COUNT(BR_USUARIO_FUNCION.USFU_RELA_RUT) | Calculated | Subquery |
| Fecha creación | `fechaCreacion` | BR_FUNCIONES.FUNC_FECHA_CREACION | TIMESTAMP | Auto SYSDATE |
| Usuario creación | `usuarioCreacion` | BR_FUNCIONES.FUNC_USUARIO_CREACION | NUMBER | RUT del JWT |

---

## 7. Validaciones de Negocio

### 7.1 Crear Función
- Nombre único case insensitive entre funciones vigentes:
```sql
SELECT COUNT(*) FROM BR_FUNCIONES 
WHERE UPPER(FUNC_NOMBRE) = UPPER(:nombre) AND FUNC_VIGENTE = 1;
```
- OpcionId debe existir y estar vigente
- AtribucionId debe pertenecer a esa opción
- AlcanceId debe existir

### 7.2 Modificar Vigencia
- Al desactivar función: cascada a opciones y atribuciones-alcances
- Al activar función: NO activar opciones automáticamente (mantienen su estado)
- Permitir desactivar aunque tenga usuarios (frontend debe confirmar)

### 7.3 Eliminar Función
- Bloquear si tiene usuarios asignados vigentes:
```sql
SELECT COUNT(*) FROM BR_USUARIO_FUNCION 
WHERE USFU_FUNC_ID = :id AND USFU_VIGENTE = 1;
```
- Cascada automática elimina opciones y atribuciones-alcances (ON DELETE CASCADE)

### 7.4 Agregar Opción
- Opción NO debe existir ya en función:
```sql
SELECT COUNT(*) FROM BR_FUNCION_OPCION 
WHERE FUOP_FUNC_ID = :funcionId AND FUOP_OPCI_CODIGO = :opcionId;
```
- Cada atribucionId debe pertenecer a esa opción:
```sql
SELECT COUNT(*) FROM BR_OPCION_ATRIBUCION 
WHERE OPAT_CODIGO = :atribId AND OPAT_OPCI_CODIGO = :opcionId;
```

### 7.5 Eliminar Opción
- Bloquear si tiene usuarios asignados:
```sql
SELECT COUNT(*) FROM BR_USUARIO_OPCION uo
JOIN BR_FUNCION_OPCION fo ON fo.FUOP_OPCI_CODIGO = uo.USOP_OPCI_CODIGO
WHERE fo.FUOP_ID = :funcionOpcionId AND uo.USOP_VIGENTE = 1;
```

### 7.6 Agregar Atribución-Alcance
- Combo atrib-alc NO debe existir en opción:
```sql
SELECT COUNT(*) FROM BR_FUNCION_OPCION_ATRIB_ALCANCE 
WHERE FOAA_FUOP_ID = :funcionOpcionId 
  AND FOAA_OPAT_CODIGO = :atribId 
  AND FOAA_ALCANCE_CODIGO = :alcId;
```

---

## 8. Códigos de Estado HTTP

| Código | Uso | Ejemplo |
|--------|-----|---------|
| 200 OK | GET exitoso, PUT exitoso | Listar funciones, modificar vigencia |
| 201 Created | POST exitoso con recurso creado | Crear función, agregar opción |
| 204 No Content | DELETE exitoso sin body | Eliminar función, eliminar opción |
| 400 Bad Request | Validación campos fallida | Nombre vacío, opcionId inválido |
| 401 Unauthorized | Token JWT inválido o expirado | Usuario no autenticado |
| 403 Forbidden | Permisos insuficientes | Perfil Consulta intenta crear función |
| 404 Not Found | Recurso no existe | Función ID 999 no encontrada |
| 409 Conflict | Restricción negocio violada | Función duplicada, tiene usuarios asignados |
| 500 Internal Server Error | Error no controlado servidor | Excepción no capturada, BD caída |

---

## 9. Seguridad

### 9.1 Autenticación
- Todos los endpoints requieren token JWT válido en header `Authorization: Bearer {token}`
- RUT usuario extraído del claim `sub` del JWT
- Token verificado con clave secreta Oracle (HMAC-SHA512)

### 9.2 Autorización
- **Administrador Nacional:** CRUD completo sin restricciones
- **Perfil Consulta:** Solo GET (listar, obtener), sin POST/PUT/DELETE
- Validar perfil con claim `roles` del JWT:
```java
if (!jwt.getRoles().contains("ADMIN_NACIONAL")) {
    throw new ForbiddenException("No tiene permisos para esta operación");
}
```

### 9.3 Validación RUT en Ruta
- RUT en path debe coincidir con RUT del token JWT
- Si no coincide: retornar HTTP 403 Forbidden
```java
String rutPath = extractRutFromPath(request.getPath());
String rutToken = jwt.getClaim("sub");
if (!rutPath.equals(rutToken)) {
    throw new ForbiddenException("RUT no coincide con token");
}
```

---

## 10. Auditoría

### 10.1 Registro Obligatorio
Todas las operaciones CUD (Create/Update/Delete) deben registrar en `BR_AUDITORIA_FUNCIONES`:

| Campo | Descripción |
|-------|-------------|
| AUDI_TABLA | 'BR_FUNCIONES', 'BR_FUNCION_OPCION', 'BR_FUNCION_OPCION_ATRIB_ALCANCE' |
| AUDI_OPERACION | 'INSERT', 'UPDATE', 'DELETE' |
| AUDI_REGISTRO_ID | ID del registro afectado |
| AUDI_VALORES_ANTERIORES | JSON valores antes (NULL en INSERT) |
| AUDI_VALORES_NUEVOS | JSON valores después (NULL en DELETE) |
| AUDI_RUT_EJECUTOR | RUT del usuario (claim JWT) |
| AUDI_FECHA | SYSTIMESTAMP |
| AUDI_TICKET | Número ticket (header X-Ticket o generado) |
| AUDI_JUSTIFICACION | Descripción operación |

### 10.2 Formato JSON Auditoría
```json
{
  "nombre": "Usuario común web",
  "vigente": true,
  "opcionId": 901,
  "atribucionId": 10,
  "alcanceId": 1
}
```

### 10.3 Consulta Historial
```sql
SELECT 
    AUDI_FECHA as fecha,
    AUDI_OPERACION as operacion,
    AUDI_TABLA as tabla,
    AUDI_VALORES_ANTERIORES as valoresAnteriores,
    AUDI_VALORES_NUEVOS as valoresNuevos,
    r.RELA_NOMBRE as nombreEjecutor
FROM AVAL.BR_AUDITORIA_FUNCIONES a
JOIN AVAL.BR_RELACIONADOS r ON r.RELA_RUT = a.AUDI_RUT_EJECUTOR
WHERE AUDI_TABLA IN ('BR_FUNCIONES', 'BR_FUNCION_OPCION', 'BR_FUNCION_OPCION_ATRIB_ALCANCE')
  AND AUDI_REGISTRO_ID = :funcionId
ORDER BY AUDI_FECHA DESC;
```

---

## 11. Paginación (NO aplica Módulo VII)

El Módulo VII NO requiere paginación según requerimientos:
- Dropdown funciones: max 500 funciones esperadas
- Lista usuarios función: max 1000 usuarios esperados
- Lista usuarios opción: max 500 usuarios esperados

Si en futuro se requiere paginación, usar estándar:
```json
{
  "data": [...],
  "pagination": {
    "page": 1,
    "pageSize": 20,
    "totalItems": 150,
    "totalPages": 8
  }
}
```

---

## 12. Testing

### 12.1 Unit Tests
- Validaciones de negocio (nombre único, duplicados, etc.)
- Formateo RUT (XX.XXX.XXX-DV)
- Formateo fechas (DD-MM-YYYY)
- Cascada vigencia (función → opciones → atrib-alc)

### 12.2 Integration Tests
- Crear función transaccional (3 inserts atómicos)
- Eliminar función con cascada BD
- Agregar opción con múltiples atrib-alc
- Validar usuarios antes eliminar

### 12.3 Tests de Carga
- Listar 500 funciones < 1 segundo
- Obtener función con 50 opciones < 2 segundos
- Crear función < 2 segundos
- Listar 1000 usuarios modal < 2 segundos

---

## 13. Notas de Implementación

### 13.1 Transacciones
- Crear función: transacción atómica para 3 inserts (función, opción, atrib-alc)
- Agregar opción: transacción para N+1 inserts (opción + N atrib-alc)
- Modificar vigencia cascada: transacción para 3 updates (función, opciones, atrib-alc)
- Usar `@Transactional` Spring o `BEGIN/COMMIT` manual

### 13.2 Códigos Correlativo
```sql
-- Generar código función: FUNC001, FUNC002, ...
SELECT 'FUNC' || LPAD(NVL(MAX(TO_NUMBER(SUBSTR(FUNC_CODIGO, 5))), 0) + 1, 3, '0')
FROM AVAL.BR_FUNCIONES;
```

### 13.3 Mapeo Java
- Usar DTOs separados para Request/Response
- Mapeador manual para convertir flat rows a estructura jerárquica JSON
- Caching de opciones/atribuciones/alcances (datos auxiliares estables)

### 13.4 Performance
- Índices requeridos:
  - `idx_funciones_nombre_vigente` (FUNC_NOMBRE, FUNC_VIGENTE)
  - `idx_funcion_opcion_func_id` (FUOP_FUNC_ID)
  - `idx_funcion_opcion_atrib_fuop_id` (FOAA_FUOP_ID)
  - `idx_usuario_funcion_func_vigente` (USFU_FUNC_ID, USFU_VIGENTE)
- Query con LEFT JOIN para cargar función completa en una sola query
- Subqueries para contar usuarios (evitar N+1 queries)

### 13.5 Formato Respuestas
- RUT: formato `XX.XXX.XXX-DV` con puntos y guión
- Fechas: formato `DD-MM-YYYY` para vigencias, `ISO 8601` para timestamps
- Códigos atrib-alc: `RE-N` (código atribución + guión + código alcance)
- Nombres opciones: `[código]: [nombre]` (ej: "OT: Mantenedor usuarios")

---

**Fin del documento backend-apis.md**

**Versión:** 1.0  
**Fecha:** 2 de febrero de 2026  
**Módulo:** VII - Mantenedor de Funciones
