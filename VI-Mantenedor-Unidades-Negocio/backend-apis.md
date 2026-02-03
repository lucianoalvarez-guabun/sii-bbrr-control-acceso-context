# Backend APIs - Mantenedor de Unidades de Negocio

## Base URL
```
/acaj-ms/api/v1/{rut}-{dv}/unidades-negocio
```

Todas las rutas incluyen el RUT del usuario autenticado: `/{rut}-{dv}/`

## Endpoints

### 1. Listar Unidades de Negocio

```
GET /acaj-ms/api/v1/{rut}-{dv}/unidades-negocio
```

**Query Parameters:**
- `tipoUnidad` (opcional): Filtrar por código de tipo de unidad (NUMBER)
- `vigente` (opcional): 1=vigente, 0=no vigente, omitir=todos (default: 1)
- `nombre` (opcional): Búsqueda parcial por nombre (LIKE '%{nombre}%')
- `page` (opcional): Número de página (default: 1)
- `size` (opcional): Registros por página (default: 20, max: 100)

**Response 200 OK:**
```json
{
  "data": [
    {
      "tipoUnidadCodigo": 1,
      "tipoUnidadDescripcion": "Dirección Regional",
      "codigo": 100,
      "nombre": "Dirección Regional Metropolitana Santiago Poniente",
      "direccion": "Teatinos 20 Piso 1",
      "fono": "56-2-3952000",
      "fax": "56-2-6964185",
      "email": "drsp@sii.cl",
      "comunaCodigo": 13101,
      "unidadPadreTipo": null,
      "unidadPadreCodigo": null,
      "unidadPadreNombre": null,
      "vigente": 1
    },
    {
      "tipoUnidadCodigo": 2,
      "tipoUnidadDescripcion": "Departamento",
      "codigo": 201,
      "nombre": "Departamento de Operaciones",
      "direccion": "Teatinos 20 Piso 3",
      "fono": "56-2-3952100",
      "fax": "56-2-6964186",
      "email": "operaciones.drsp@sii.cl",
      "comunaCodigo": 13101,
      "unidadPadreTipo": 1,
      "unidadPadreCodigo": 100,
      "unidadPadreNombre": "Dirección Regional Metropolitana Santiago Poniente",
      "vigente": 1
    }
  ],
  "pagination": {
    "page": 1,
    "size": 20,
    "totalElements": 585,
    "totalPages": 30
  }
}
```

**Tips SQL:**
```sql
-- Query con JOIN a tipo de unidad y LEFT JOIN a unidad padre
SELECT 
    u.UNNE_TIUN_CODIGO as tipoUnidadCodigo,
    t.TIUN_DESCRIPCION as tipoUnidadDescripcion,
    u.UNNE_CODIGO as codigo,
    u.UNNE_NOMBRE as nombre,
    u.UNNE_DIRECCION as direccion,
    u.UNNE_FONO_1 as fono,
    u.UNNE_FAX_1 as fax,
    u.UNNE_EMAIL as email,
    u.UNNE_COMU_CODIGO_CONARA_SII as comunaCodigo,
    u.UNNE_UNNE_TIUN_CODIGO as unidadPadreTipo,
    u.UNNE_UNNE_CODIGO as unidadPadreCodigo,
    padre.UNNE_NOMBRE as unidadPadreNombre,
    u.UNNE_VIGENTE as vigente
FROM AVAL.BR_UNIDADES_NEGOCIO u
INNER JOIN AVAL.BR_TIPOS_UNIDAD t 
    ON u.UNNE_TIUN_CODIGO = t.TIUN_CODIGO
LEFT JOIN AVAL.BR_UNIDADES_NEGOCIO padre 
    ON u.UNNE_UNNE_TIUN_CODIGO = padre.UNNE_TIUN_CODIGO
    AND u.UNNE_UNNE_CODIGO = padre.UNNE_CODIGO
WHERE u.UNNE_VIGENTE = :vigente
  AND (:tipoUnidad IS NULL OR u.UNNE_TIUN_CODIGO = :tipoUnidad)
  AND (:nombre IS NULL OR UPPER(u.UNNE_NOMBRE) LIKE '%' || UPPER(:nombre) || '%')
ORDER BY u.UNNE_NOMBRE
```

---

### 2. Obtener Unidad de Negocio por ID

```
GET /acaj-ms/api/v1/{rut}-{dv}/unidades-negocio/{tipoUnidadCodigo}/{codigo}
```

**Path Parameters:**
- `tipoUnidadCodigo`: Código del tipo de unidad (NUMBER)
- `codigo`: Código de la unidad (NUMBER)

**Response 200 OK:**
```json
{
  "tipoUnidadCodigo": 1,
  "tipoUnidadDescripcion": "Dirección Regional",
  "codigo": 100,
  "nombre": "Dirección Regional Metropolitana Santiago Poniente",
  "direccion": "Teatinos 20 Piso 1",
  "fono": "56-2-3952000",
  "fax": "56-2-6964185",
  "email": "drsp@sii.cl",
  "comunaCodigo": 13101,
  "unidadPadreTipo": null,
  "unidadPadreCodigo": null,
  "unidadPadreNombre": null,
  "vigente": 1,
  "unidadesHijas": [
    {
      "tipoUnidadCodigo": 2,
      "codigo": 201,
      "nombre": "Departamento de Operaciones",
      "vigente": 1
    }
  ]
}
```

**Response 404 Not Found:**
```json
{
  "error": "Unidad de negocio no encontrada",
  "codigo": "UNIDAD_NO_ENCONTRADA"
}
```

**Tips SQL:**
```sql
-- Query principal con subquery para unidades hijas
SELECT 
    u.*,
    t.TIUN_DESCRIPCION,
    padre.UNNE_NOMBRE as unidadPadreNombre,
    (
        SELECT JSON_ARRAYAGG(
            JSON_OBJECT(
                'tipoUnidadCodigo' VALUE h.UNNE_TIUN_CODIGO,
                'codigo' VALUE h.UNNE_CODIGO,
                'nombre' VALUE h.UNNE_NOMBRE,
                'vigente' VALUE h.UNNE_VIGENTE
            )
        )
        FROM AVAL.BR_UNIDADES_NEGOCIO h
        WHERE h.UNNE_UNNE_TIUN_CODIGO = u.UNNE_TIUN_CODIGO
          AND h.UNNE_UNNE_CODIGO = u.UNNE_CODIGO
    ) as unidadesHijas
FROM AVAL.BR_UNIDADES_NEGOCIO u
INNER JOIN AVAL.BR_TIPOS_UNIDAD t ON u.UNNE_TIUN_CODIGO = t.TIUN_CODIGO
LEFT JOIN AVAL.BR_UNIDADES_NEGOCIO padre 
    ON u.UNNE_UNNE_TIUN_CODIGO = padre.UNNE_TIUN_CODIGO
    AND u.UNNE_UNNE_CODIGO = padre.UNNE_CODIGO
WHERE u.UNNE_TIUN_CODIGO = :tipoUnidadCodigo
  AND u.UNNE_CODIGO = :codigo
```

---

### 3. Crear Unidad de Negocio

```
POST /acaj-ms/api/v1/{rut}-{dv}/unidades-negocio
```

**Request Body:**
```json
{
  "tipoUnidadCodigo": 2,
  "nombre": "Departamento de Fiscalización",
  "direccion": "Teatinos 20 Piso 5",
  "fono": "56-2-3952300",
  "fax": "56-2-6964190",
  "email": "fiscalizacion.drsp@sii.cl",
  "comunaCodigo": 13101,
  "unidadPadreTipo": 1,
  "unidadPadreCodigo": 100,
  "vigente": 1
}
```

**Validaciones:**
- `tipoUnidadCodigo`: REQUERIDO, debe existir en BR_TIPOS_UNIDAD
- `nombre`: REQUERIDO, max 50 caracteres
- `direccion`: REQUERIDO, max 50 caracteres
- `fono`: REQUERIDO, max 15 caracteres
- `fax`: REQUERIDO, max 15 caracteres
- `email`: OPCIONAL, max 80 caracteres, formato RFC 5322
- `comunaCodigo`: REQUERIDO, debe existir en tabla comunas
- `unidadPadreTipo` + `unidadPadreCodigo`: OPCIONAL, ambos requeridos si se especifica padre
- `vigente`: DEFAULT 1 si no se especifica

**Response 201 Created:**
```json
{
  "tipoUnidadCodigo": 2,
  "codigo": 350,
  "nombre": "Departamento de Fiscalización",
  "direccion": "Teatinos 20 Piso 5",
  "fono": "56-2-3952300",
  "fax": "56-2-6964190",
  "email": "fiscalizacion.drsp@sii.cl",
  "comunaCodigo": 13101,
  "unidadPadreTipo": 1,
  "unidadPadreCodigo": 100,
  "vigente": 1,
  "mensaje": "Unidad de negocio creada correctamente"
}
```

**Response 400 Bad Request:**
```json
{
  "error": "Datos inválidos",
  "codigo": "VALIDACION_FALLIDA",
  "detalles": [
    {"campo": "nombre", "mensaje": "El nombre es requerido"},
    {"campo": "email", "mensaje": "Formato de email inválido"}
  ]
}
```

**Response 409 Conflict:**
```json
{
  "error": "Ya existe una unidad de negocio con el mismo nombre",
  "codigo": "UNIDAD_DUPLICADA"
}
```

**Tips SQL:**
```sql
-- Obtener siguiente código disponible para el tipo de unidad
SELECT COALESCE(MAX(UNNE_CODIGO), 0) + 1 as siguienteCodigo
FROM AVAL.BR_UNIDADES_NEGOCIO
WHERE UNNE_TIUN_CODIGO = :tipoUnidadCodigo;

-- Validar que tipo de unidad existe
SELECT COUNT(*) FROM AVAL.BR_TIPOS_UNIDAD
WHERE TIUN_CODIGO = :tipoUnidadCodigo;

-- Validar que unidad padre existe (si se especifica)
SELECT COUNT(*) FROM AVAL.BR_UNIDADES_NEGOCIO
WHERE UNNE_TIUN_CODIGO = :unidadPadreTipo
  AND UNNE_CODIGO = :unidadPadreCodigo
  AND UNNE_VIGENTE = 1;

-- Insertar nueva unidad
INSERT INTO AVAL.BR_UNIDADES_NEGOCIO (
    UNNE_TIUN_CODIGO, UNNE_CODIGO, UNNE_NOMBRE, UNNE_DIRECCION,
    UNNE_FONO_1, UNNE_FAX_1, UNNE_EMAIL, UNNE_COMU_CODIGO_CONARA_SII,
    UNNE_UNNE_TIUN_CODIGO, UNNE_UNNE_CODIGO, UNNE_VIGENTE
) VALUES (
    :tipoUnidadCodigo, :codigo, :nombre, :direccion,
    :fono, :fax, :email, :comunaCodigo,
    :unidadPadreTipo, :unidadPadreCodigo, :vigente
);
```

---

### 4. Actualizar Unidad de Negocio

```
PUT /acaj-ms/api/v1/{rut}-{dv}/unidades-negocio/{tipoUnidadCodigo}/{codigo}
```

**Request Body:**
```json
{
  "nombre": "Departamento de Fiscalización y Control",
  "direccion": "Teatinos 20 Piso 5 Of 501",
  "fono": "56-2-3952301",
  "fax": "56-2-6964191",
  "email": "fiscalizacion.control.drsp@sii.cl",
  "comunaCodigo": 13101,
  "unidadPadreTipo": 1,
  "unidadPadreCodigo": 100,
  "vigente": 1
}
```

**Validaciones:**
- `tipoUnidadCodigo` (path): NO se puede modificar (parte de PK)
- `codigo` (path): NO se puede modificar (parte de PK)
- Resto de validaciones igual que POST

**Response 200 OK:**
```json
{
  "tipoUnidadCodigo": 2,
  "codigo": 350,
  "nombre": "Departamento de Fiscalización y Control",
  "mensaje": "Unidad de negocio actualizada correctamente"
}
```

**Response 404 Not Found:**
```json
{
  "error": "Unidad de negocio no encontrada",
  "codigo": "UNIDAD_NO_ENCONTRADA"
}
```

**Response 409 Conflict:**
```json
{
  "error": "No se puede asignar como padre a una unidad hija",
  "codigo": "JERARQUIA_INVALIDA"
}
```

**Tips SQL:**
```sql
-- Validar jerarquía circular (no puede ser padre de sí misma ni de sus ancestros)
WITH RECURSIVE jerarquia AS (
    SELECT UNNE_TIUN_CODIGO, UNNE_CODIGO, UNNE_UNNE_TIUN_CODIGO, UNNE_UNNE_CODIGO, 1 as nivel
    FROM AVAL.BR_UNIDADES_NEGOCIO
    WHERE UNNE_TIUN_CODIGO = :tipoUnidadCodigo AND UNNE_CODIGO = :codigo
    UNION ALL
    SELECT u.UNNE_TIUN_CODIGO, u.UNNE_CODIGO, u.UNNE_UNNE_TIUN_CODIGO, u.UNNE_UNNE_CODIGO, j.nivel + 1
    FROM AVAL.BR_UNIDADES_NEGOCIO u
    INNER JOIN jerarquia j ON u.UNNE_TIUN_CODIGO = j.UNNE_UNNE_TIUN_CODIGO 
                           AND u.UNNE_CODIGO = j.UNNE_UNNE_CODIGO
    WHERE j.nivel < 10
)
SELECT COUNT(*) as esDescendiente
FROM jerarquia
WHERE UNNE_TIUN_CODIGO = :nuevoPadreTipo AND UNNE_CODIGO = :nuevoPadreCodigo;

-- Actualizar unidad
UPDATE AVAL.BR_UNIDADES_NEGOCIO
SET UNNE_NOMBRE = :nombre,
    UNNE_DIRECCION = :direccion,
    UNNE_FONO_1 = :fono,
    UNNE_FAX_1 = :fax,
    UNNE_EMAIL = :email,
    UNNE_COMU_CODIGO_CONARA_SII = :comunaCodigo,
    UNNE_UNNE_TIUN_CODIGO = :unidadPadreTipo,
    UNNE_UNNE_CODIGO = :unidadPadreCodigo,
    UNNE_VIGENTE = :vigente
WHERE UNNE_TIUN_CODIGO = :tipoUnidadCodigo
  AND UNNE_CODIGO = :codigo;
```

---

### 5. Eliminar Unidad de Negocio (Soft Delete)

```
DELETE /acaj-ms/api/v1/{rut}-{dv}/unidades-negocio/{tipoUnidadCodigo}/{codigo}
```

**Response 200 OK:**
```json
{
  "mensaje": "Unidad de negocio marcada como no vigente correctamente"
}
```

**Response 404 Not Found:**
```json
{
  "error": "Unidad de negocio no encontrada",
  "codigo": "UNIDAD_NO_ENCONTRADA"
}
```

**Response 409 Conflict:**
```json
{
  "error": "No se puede eliminar una unidad con unidades hijas activas",
  "codigo": "TIENE_UNIDADES_HIJAS",
  "detalles": {
    "unidadesHijasActivas": 3
  }
}
```

**Tips SQL:**
```sql
-- Validar que no tenga unidades hijas activas
SELECT COUNT(*) as hijasActivas
FROM AVAL.BR_UNIDADES_NEGOCIO
WHERE UNNE_UNNE_TIUN_CODIGO = :tipoUnidadCodigo
  AND UNNE_UNNE_CODIGO = :codigo
  AND UNNE_VIGENTE = 1;

-- Soft delete (marcar como no vigente)
UPDATE AVAL.BR_UNIDADES_NEGOCIO
SET UNNE_VIGENTE = 0
WHERE UNNE_TIUN_CODIGO = :tipoUnidadCodigo
  AND UNNE_CODIGO = :codigo;
```

---

### 6. Listar Tipos de Unidad

```
GET /acaj-ms/api/v1/{rut}-{dv}/tipos-unidad
```

**Response 200 OK:**
```json
{
  "data": [
    {"codigo": 1, "descripcion": "Dirección Regional"},
    {"codigo": 2, "descripcion": "Departamento"},
    {"codigo": 3, "descripcion": "Sección"},
    {"codigo": 4, "descripcion": "Unidad"}
  ]
}
```

**Tips SQL:**
```sql
-- Listar todos los tipos de unidad
SELECT TIUN_CODIGO as codigo, TIUN_DESCRIPCION as descripcion
FROM AVAL.BR_TIPOS_UNIDAD
ORDER BY TIUN_DESCRIPCION;
```

---

### 7. Obtener Árbol Jerárquico de Unidades

```
GET /acaj-ms/api/v1/{rut}-{dv}/unidades-negocio/arbol
```

**Query Parameters:**
- `vigente` (opcional): 1=vigente, 0=no vigente, omitir=todos (default: 1)

**Response 200 OK:**
```json
{
  "data": [
    {
      "tipoUnidadCodigo": 1,
      "codigo": 100,
      "nombre": "Dirección Regional Metropolitana Santiago Poniente",
      "vigente": 1,
      "nivel": 0,
      "hijas": [
        {
          "tipoUnidadCodigo": 2,
          "codigo": 201,
          "nombre": "Departamento de Operaciones",
          "vigente": 1,
          "nivel": 1,
          "hijas": [
            {
              "tipoUnidadCodigo": 3,
              "codigo": 301,
              "nombre": "Sección Fiscalización",
              "vigente": 1,
              "nivel": 2,
              "hijas": []
            }
          ]
        }
      ]
    }
  ]
}
```

**Tips SQL:**
```sql
-- Query recursiva para construir árbol completo
WITH RECURSIVE arbol AS (
    -- Nivel 0: Unidades sin padre (raíces)
    SELECT 
        UNNE_TIUN_CODIGO, UNNE_CODIGO, UNNE_NOMBRE, UNNE_VIGENTE,
        UNNE_UNNE_TIUN_CODIGO, UNNE_UNNE_CODIGO,
        0 as nivel,
        CAST(UNNE_NOMBRE AS VARCHAR2(4000)) as ruta
    FROM AVAL.BR_UNIDADES_NEGOCIO
    WHERE UNNE_UNNE_TIUN_CODIGO IS NULL
      AND UNNE_VIGENTE = :vigente
    
    UNION ALL
    
    -- Niveles subsecuentes: Unidades hijas
    SELECT 
        u.UNNE_TIUN_CODIGO, u.UNNE_CODIGO, u.UNNE_NOMBRE, u.UNNE_VIGENTE,
        u.UNNE_UNNE_TIUN_CODIGO, u.UNNE_UNNE_CODIGO,
        a.nivel + 1,
        a.ruta || ' > ' || u.UNNE_NOMBRE
    FROM AVAL.BR_UNIDADES_NEGOCIO u
    INNER JOIN arbol a 
        ON u.UNNE_UNNE_TIUN_CODIGO = a.UNNE_TIUN_CODIGO
        AND u.UNNE_UNNE_CODIGO = a.UNNE_CODIGO
    WHERE u.UNNE_VIGENTE = :vigente
      AND a.nivel < 10
)
SELECT * FROM arbol
ORDER BY ruta;
```

---

## Mapeo Frontend/Backend/BD

| Frontend Campo | API Endpoint | API Param | BD Tabla | BD Columna | Tipo | Validación |
|---|---|---|---|---|---|---|
| Tipo Unidad | GET /tipos-unidad | - | BR_TIPOS_UNIDAD | TIUN_CODIGO | NUMBER(2) | FK obligatorio |
| Código | GET /:tipo/:codigo | path.codigo | BR_UNIDADES_NEGOCIO | UNNE_CODIGO | NUMBER(6) | PK, auto-generado |
| Nombre | POST /crear | body.nombre | BR_UNIDADES_NEGOCIO | UNNE_NOMBRE | VARCHAR2(50) | Requerido, max 50 |
| Dirección | POST /crear | body.direccion | BR_UNIDADES_NEGOCIO | UNNE_DIRECCION | VARCHAR2(50) | Requerido, max 50 |
| Teléfono | POST /crear | body.fono | BR_UNIDADES_NEGOCIO | UNNE_FONO_1 | VARCHAR2(15) | Requerido, max 15 |
| Fax | POST /crear | body.fax | BR_UNIDADES_NEGOCIO | UNNE_FAX_1 | VARCHAR2(15) | Requerido, max 15 |
| Email | POST /crear | body.email | BR_UNIDADES_NEGOCIO | UNNE_EMAIL | VARCHAR2(80) | Opcional, RFC 5322 |
| Comuna SII | POST /crear | body.comunaCodigo | BR_UNIDADES_NEGOCIO | UNNE_COMU_CODIGO_CONARA_SII | NUMBER(5) | FK requerido |
| Unidad Padre Tipo | POST /crear | body.unidadPadreTipo | BR_UNIDADES_NEGOCIO | UNNE_UNNE_TIUN_CODIGO | NUMBER(2) | FK opcional |
| Unidad Padre Código | POST /crear | body.unidadPadreCodigo | BR_UNIDADES_NEGOCIO | UNNE_UNNE_CODIGO | NUMBER(6) | FK opcional |
| Vigente | PUT /actualizar | body.vigente | BR_UNIDADES_NEGOCIO | UNNE_VIGENTE | NUMBER(1) | 1=vigente, 0=no |

---

## Validaciones de Negocio

### 1. Validar Tipo de Unidad Existe

```sql
SELECT COUNT(*) as existe
FROM AVAL.BR_TIPOS_UNIDAD
WHERE TIUN_CODIGO = :tipoUnidadCodigo;
-- Si existe = 0 → error 400
```

### 2. Validar Unidad Padre Existe y Está Vigente

```sql
SELECT COUNT(*) as existe
FROM AVAL.BR_UNIDADES_NEGOCIO
WHERE UNNE_TIUN_CODIGO = :unidadPadreTipo
  AND UNNE_CODIGO = :unidadPadreCodigo
  AND UNNE_VIGENTE = 1;
-- Si existe = 0 → error 400
```

### 3. Validar No Jerarquía Circular

```sql
-- Verificar que nueva unidad padre no sea descendiente de la unidad actual
WITH RECURSIVE descendientes AS (
    SELECT UNNE_TIUN_CODIGO, UNNE_CODIGO
    FROM AVAL.BR_UNIDADES_NEGOCIO
    WHERE UNNE_UNNE_TIUN_CODIGO = :tipoUnidadCodigo
      AND UNNE_UNNE_CODIGO = :codigo
    UNION ALL
    SELECT u.UNNE_TIUN_CODIGO, u.UNNE_CODIGO
    FROM AVAL.BR_UNIDADES_NEGOCIO u
    INNER JOIN descendientes d 
        ON u.UNNE_UNNE_TIUN_CODIGO = d.UNNE_TIUN_CODIGO
        AND u.UNNE_UNNE_CODIGO = d.UNNE_CODIGO
)
SELECT COUNT(*) as esCircular
FROM descendientes
WHERE UNNE_TIUN_CODIGO = :nuevoPadreTipo
  AND UNNE_CODIGO = :nuevoPadreCodigo;
-- Si esCircular > 0 → error 409
```

### 4. Validar Nombre Único por Tipo de Unidad

```sql
SELECT COUNT(*) as existe
FROM AVAL.BR_UNIDADES_NEGOCIO
WHERE UNNE_TIUN_CODIGO = :tipoUnidadCodigo
  AND UPPER(TRIM(UNNE_NOMBRE)) = UPPER(TRIM(:nombre))
  AND NOT (UNNE_TIUN_CODIGO = :tipoUnidadActual AND UNNE_CODIGO = :codigoActual);
-- Si existe > 0 → error 409
```

### 5. Validar No Tiene Unidades Hijas Activas (al eliminar)

```sql
SELECT COUNT(*) as hijasActivas
FROM AVAL.BR_UNIDADES_NEGOCIO
WHERE UNNE_UNNE_TIUN_CODIGO = :tipoUnidadCodigo
  AND UNNE_UNNE_CODIGO = :codigo
  AND UNNE_VIGENTE = 1;
-- Si hijasActivas > 0 → error 409
```

---

## Códigos de Estado HTTP

| Código | Descripción | Cuándo Usar |
|---|---|---|
| 200 OK | Operación exitosa | GET, PUT, DELETE exitosos |
| 201 Created | Recurso creado | POST exitoso |
| 400 Bad Request | Datos inválidos | Validación de campos falló |
| 404 Not Found | Recurso no encontrado | GET/PUT/DELETE de unidad inexistente |
| 409 Conflict | Conflicto de negocio | Nombre duplicado, jerarquía circular, tiene hijas activas |
| 500 Internal Server Error | Error del servidor | Errores no controlados |

---

## Paginación

Todas las listas usan paginación basada en offset:

**Request:**
- `page`: número de página (1-based)
- `size`: registros por página (default 20, max 100)

**Response:**
```json
{
  "data": [...],
  "pagination": {
    "page": 1,
    "size": 20,
    "totalElements": 585,
    "totalPages": 30
  }
}
```

---

## Seguridad

### Validación de RUT en Ruta

Todas las APIs validan que el `{rut}-{dv}` en la ruta corresponda al usuario autenticado en el token JWT.

### Permisos por Alcance

- **Administrador Nacional**: Acceso a todas las unidades
- **Administrador Regional**: Solo unidades de su región/dirección regional
- **Administrador Unidad**: Solo su unidad y sub-unidades
- **Consulta**: Solo lectura (GET)

**Implementación:**
```sql
-- Filtrar unidades según alcance del usuario
WHERE (
    :alcance = 'NACIONAL' 
    OR (
        :alcance = 'REGIONAL' 
        AND u.UNNE_TIUN_CODIGO IN (SELECT codigo FROM unidades_usuario_regional)
    )
    OR (
        :alcance = 'UNIDAD'
        AND u.UNNE_TIUN_CODIGO = :unidadUsuarioTipo
        AND u.UNNE_CODIGO = :unidadUsuarioCodigo
    )
)
```

---

## Auditoría

Todas las operaciones de escritura (POST, PUT, DELETE) deben registrar:

**Tabla de Auditoría (propuesta):**
- Fecha/hora operación
- RUT usuario
- Tipo operación (CREATE, UPDATE, DELETE)
- Entidad afectada (tipo + código unidad)
- Valores anteriores (UPDATE)
- Valores nuevos (CREATE, UPDATE)
- Nro ticket autorización (opcional)

**Implementación:**
```sql
INSERT INTO AVAL.BR_AUDITORIA_UNIDADES (
    AUDI_FECHA, AUDI_RUT_USUARIO, AUDI_OPERACION,
    AUDI_UNNE_TIUN_CODIGO, AUDI_UNNE_CODIGO,
    AUDI_VALORES_ANTERIORES, AUDI_VALORES_NUEVOS,
    AUDI_NRO_TICKET
) VALUES (
    SYSDATE, :rutUsuario, :operacion,
    :tipoUnidadCodigo, :codigo,
    :valoresAnteriores, :valoresNuevos,
    :nroTicket
);
```

---

## Testing

### Casos de Prueba Sugeridos

1. **Listar unidades**: 585 registros total, paginación correcta
2. **Buscar por tipo**: filtrado correcto
3. **Crear unidad**: código auto-generado, validaciones OK
4. **Crear con padre**: FK válida, jerarquía OK
5. **Actualizar unidad**: cambios persistidos
6. **Cambiar unidad padre**: validar no circular
7. **Eliminar con hijas**: error 409
8. **Eliminar sin hijas**: soft-delete OK (vigente=0)
9. **Árbol jerárquico**: niveles correctos
10. **Permisos por alcance**: filtrado correcto
