# Backend APIs - Módulo V: Mantenedor de Usuarios Relacionados

**Proyecto:** Control de Acceso SII  
**Microservicio:** `acaj-ms` (Spring Boot)  
**Base URL:** `/acaj-ms/api/v1/usuarios-relacionados`  
**Schema BD:** AVAL (Oracle 19c)

---

## 1. GET /buscar

**Descripción:** Busca un usuario relacionado por RUT y retorna toda su información completa.

**Endpoint:** `GET /buscar`

**Query Params:**
- `rut` (Number, obligatorio): RUT del usuario sin puntos ni guión (ej: 15000000)

**Response 200 OK:**
```json
{
  "rut": 15000000,
  "dv": "1",
  "nombre": "María de los Ángeles",
  "paterno": "Moscoso",
  "materno": "Aldumate",
  "nombreCompleto": "María de los Ángeles Moscoso Aldumate",
  "email": "maria.moscoso@sii.cl",
  "telefono": "+56912345678",
  "tipoUsuario": "INTERNO",
  "jurisdiccion": "SIMPLE",
  "vigenciaInicio": "2024-01-15",
  "vigenciaFin": null,
  "unidadPrincipal": 1025,
  "cargos": [
    {
      "id": 123,
      "codigoCargo": 5,
      "descripcionCargo": "Jefe de Departamento",
      "codigoUnidad": 1025,
      "vigente": "S",
      "fechaInicio": "2024-01-15",
      "fechaFin": null,
      "funciones": [
        {
          "id": 456,
          "codigoFuncion": 10,
          "descripcionFuncion": "Administrador Sistema",
          "fechaAsignacion": "2024-01-16"
        }
      ]
    }
  ],
  "jurisdiccionesExtendidas": []
}
```

**Response 404 Not Found:**
```json
{
  "error": "Usuario no encontrado",
  "message": "No existe un usuario relacionado con RUT 15000000-1"
}
```

**Mapeo Frontend/Backend:**
| Campo Frontend | Response JSON | BD Columna | Observación |
|----------------|---------------|------------|-------------|
| RUT input | `rut`, `dv` | `RELA_RUT`, `RELA_DV` | Separados para validación |
| Nombre completo | `nombreCompleto` | `RELA_NOMBRE \|\| ' ' \|\| RELA_PATERNO \|\| ' ' \|\| RELA_MATERNO` | Concatenación en query |
| Email | `email` | `RELA_EMAIL` | Read-only si tipo=INTERNO |
| Teléfono | `telefono` | `RELA_FONO` | BD usa RELA_FONO |
| Tipo Usuario | `tipoUsuario` | `BR_RELACIONADOS_EXTENSION.TIPO_USUARIO` | INTERNO/EXTERNO (LEFT JOIN) |
| Jurisdicción | `jurisdiccion` | `BR_RELACIONADOS_EXTENSION.JURISDICCION` | SIMPLE/AMPLIADA (LEFT JOIN) |

**Query SQL:**
```sql
-- Usuario base con LEFT JOIN a extensión
SELECT 
  r.RELA_RUT as rut,
  r.RELA_DV as dv,
  r.RELA_NOMBRE as nombre,
  r.RELA_PATERNO as paterno,
  r.RELA_MATERNO as materno,
  r.RELA_NOMBRE || ' ' || r.RELA_PATERNO || ' ' || r.RELA_MATERNO as nombreCompleto,
  r.RELA_EMAIL as email,
  r.RELA_FONO as telefono,
  COALESCE(ext.TIPO_USUARIO, 'INTERNO') as tipoUsuario,
  COALESCE(ext.JURISDICCION, 'SIMPLE') as jurisdiccion,
  ext.VIGENCIA_INICIO as vigenciaInicio,
  ext.VIGENCIA_FIN as vigenciaFin,
  ext.UNIDAD_PRINCIPAL as unidadPrincipal
FROM AVAL.BR_RELACIONADOS r
LEFT JOIN AVAL.BR_RELACIONADOS_EXTENSION ext ON r.RELA_RUT = ext.RELA_RUT
WHERE r.RELA_RUT = :rut;

-- Cargos del usuario (vigentes y no vigentes)
SELECT 
  cu.CAUS_ID as id,
  cu.CAUS_CARGO_CODIGO as codigoCargo,
  c.CARG_DESCRIPCION as descripcionCargo,
  cu.CAUS_UNIDAD_CODIGO as codigoUnidad,
  cu.CAUS_VIGENTE as vigente,
  cu.CAUS_FECHA_INICIO as fechaInicio,
  cu.CAUS_FECHA_FIN as fechaFin
FROM AVAL.BR_CARGOS_USUARIO cu
INNER JOIN AVAL.BR_CARGOS c ON cu.CAUS_CARGO_CODIGO = c.CARG_CODIGO
WHERE cu.CAUS_RELA_RUT = :rut
ORDER BY cu.CAUS_FECHA_INICIO DESC;

-- Funciones por cada cargo
SELECT 
  fu.FUUS_ID as id,
  fu.FUUS_FUNC_CODIGO as codigoFuncion,
  f.FUNS_DESCRIPCION as descripcionFuncion,
  fu.FUUS_FECHA_ASIGNACION as fechaAsignacion
FROM AVAL.BR_FUNCIONES_USUARIO fu
INNER JOIN AVAL.BR_FUNCIONES f ON fu.FUUS_FUNC_CODIGO = f.FUNS_CODIGO
WHERE fu.FUUS_CAUS_ID = :cargoId
ORDER BY fu.FUUS_FECHA_ASIGNACION;
```

**Tips de SQL:**
```sql
-- ⚠️ RELA_NOMBRE tiene límite de 40 caracteres en BD (verificado)
-- ⚠️ BR_CARGOS.CARG_VIGENTE y BR_FUNCIONES.FUNS_VIGENTE son NUMBER(1): 1=vigente, 0=no vigente
-- Al listar cargos/funciones disponibles: WHERE CARG_VIGENTE = 1
```

**Validaciones de Negocio:**
```sql
-- VN-001: Validar que el usuario existe
SELECT COUNT(*) FROM AVAL.BR_RELACIONADOS WHERE RELA_RUT = :rut;

-- VN-002: Usuario vigente (fecha fin NULL o > hoy)
SELECT COUNT(*) FROM AVAL.BR_RELACIONADOS 
WHERE RELA_RUT = :rut 
  AND (RELA_VIGENCIA_FIN IS NULL OR RELA_VIGENCIA_FIN > SYSDATE);
```

---

## 2. POST /interno

**Descripción:** Crea un nuevo usuario INTERNO (funcionario SII) consumiendo servicio SIGER.

**Endpoint:** `POST /interno`

**Request Body:**
```json
{
  "rut": 16000000,
  "dv": "5",
  "jurisdiccion": "SIMPLE",
  "vigenciaInicio": "2025-02-01",
  "vigenciaFin": null,
  "unidadPrincipal": 1025
}
```

**Response 201 Created:**
```json
{
  "rut": 16000000,
  "dv": "5",
  "nombre": "Juan Carlos",
  "paterno": "González",
  "materno": "Pérez",
  "nombreCompleto": "Juan Carlos González Pérez",
  "email": "juan.gonzalez@sii.cl",
  "telefono": "+56987654321",
  "tipoUsuario": "INTERNO",
  "jurisdiccion": "SIMPLE",
  "vigenciaInicio": "2025-02-01",
  "vigenciaFin": null,
  "unidadPrincipal": 1025,
  "cargos": [],
  "jurisdiccionesExtendidas": []
}
```

**Response 409 Conflict:**
```json
{
  "error": "Usuario ya existe",
  "message": "El RUT 16000000-5 ya está registrado como usuario relacionado"
}
```

**Response 502 Bad Gateway:**
```json
{
  "error": "Error integrando con SIGER",
  "message": "No se pudo obtener datos del funcionario desde SIGER"
}
```

**Mapeo Frontend/Backend:**
| Campo Frontend | Request JSON | BD Columna | Observación |
|----------------|--------------|------------|-------------|
| RUT input | `rut`, `dv` | `RELA_RUT`, `RELA_DV` | Validación módulo 11 |
| Jurisdicción toggle | `jurisdiccion` | `RELA_JURISDICCION` | SIMPLE/AMPLIADA |
| Fecha inicio | `vigenciaInicio` | `RELA_VIGENCIA_INICIO` | Obligatorio |
| Fecha fin | `vigenciaFin` | `RELA_VIGENCIA_FIN` | Opcional (NULL = indefinido) |
| Unidad principal | `unidadPrincipal` | `RELA_UNIDAD_PRINCIPAL` | Código unidad base |

**Integración Externa:**
```java
// 1. Consumir servicio SIGER (API REST interna SII)
GET https://siger.sii.cl/api/funcionarios/{rut}
Response: {
  "rut": 16000000,
  "dv": "5",
  "nombres": "Juan Carlos",
  "apellidoPaterno": "González",
  "apellidoMaterno": "Pérez",
  "email": "juan.gonzalez@sii.cl",
  "telefonoMovil": "+56987654321"
}
```

**Query SQL:**
```sql
-- Insertar usuario INTERNO con datos de SIGER
INSERT INTO AVAL.BR_RELACIONADOS (
  RELA_RUT,
  RELA_DV,
  RELA_TIPO_USUARIO,
  RELA_NOMBRE,
  RELA_PATERNO,
  RELA_MATERNO,
  RELA_EMAIL,
  RELA_FONO,
  RELA_JURISDICCION,
  RELA_VIGENCIA_INICIO,
  RELA_VIGENCIA_FIN,
  RELA_UNIDAD_PRINCIPAL,
  RELA_FECHA_CREACION,
  RELA_USUARIO_CREACION
) VALUES (
  :rut,
  :dv,
  'INTERNO',
  SUBSTR(:nombres, 1, 40), -- ⚠️ Límite 40 chars
  :apellidoPaterno,
  :apellidoMaterno,
  :email,
  :telefonoMovil,
  :jurisdiccion,
  TO_DATE(:vigenciaInicio, 'YYYY-MM-DD'),
  CASE WHEN :vigenciaFin IS NOT NULL THEN TO_DATE(:vigenciaFin, 'YYYY-MM-DD') ELSE NULL END,
  :unidadPrincipal,
  SYSDATE,
  :usuarioCreador
);
```

**Tips de SQL:**
```sql
-- Transacción con integración externa:
-- 1. Validar RUT no duplicado
-- 2. Consumir SIGER (si falla: rollback)
-- 3. INSERT con SUBSTR en RELA_NOMBRE (límite 40)
-- 4. COMMIT
```

**Validaciones de Negocio:**
```sql
-- VN-001: RUT no duplicado
SELECT COUNT(*) FROM AVAL.BR_RELACIONADOS WHERE RELA_RUT = :rut;

-- VN-002: Validación vigencias
-- vigenciaInicio <= hoy
-- vigenciaFin > vigenciaInicio (si no es NULL)

-- VN-003: Validar dígito verificador (módulo 11)
-- Implementado en capa Java
```

---

## 3. POST /externo

**Descripción:** Crea un nuevo usuario EXTERNO (OCM, notarios, CBR, CDE, etc.) consumiendo servicio RIAC.

**Endpoint:** `POST /externo`

**Request Body:**
```json
{
  "rut": 17000000,
  "dv": "8",
  "jurisdiccion": "AMPLIADA",
  "vigenciaInicio": "2025-02-01",
  "vigenciaFin": "2025-12-31",
  "unidadPrincipal": 2050
}
```

**Response 201 Created:**
```json
{
  "rut": 17000000,
  "dv": "8",
  "nombre": "Ana María",
  "paterno": "Torres",
  "materno": "Silva",
  "nombreCompleto": "Ana María Torres Silva",
  "email": "ana.torres@ocm.cl",
  "telefono": "+56966554433",
  "tipoUsuario": "EXTERNO",
  "jurisdiccion": "AMPLIADA",
  "vigenciaInicio": "2025-02-01",
  "vigenciaFin": "2025-12-31",
  "unidadPrincipal": 2050,
  "cargos": [],
  "jurisdiccionesExtendidas": []
}
```

**Response 409 Conflict:**
```json
{
  "error": "Usuario ya existe",
  "message": "El RUT 17000000-8 ya está registrado como usuario relacionado"
}
```

**Response 502 Bad Gateway:**
```json
{
  "error": "Error integrando con RIAC",
  "message": "No se pudo obtener datos del usuario externo desde RIAC"
}
```

**Integración Externa:**
```java
// 1. Consumir servicio RIAC (Registro de Instituciones y Actores Clave)
GET https://riac.sii.cl/api/usuarios/{rut}
Response: {
  "rut": 17000000,
  "dv": "8",
  "nombres": "Ana María",
  "apellidoPaterno": "Torres",
  "apellidoMaterno": "Silva",
  "correoElectronico": "ana.torres@ocm.cl",
  "telefonoContacto": "+56966554433",
  "tipoInstitucion": "OCM"
}
```

**Query SQL:**
```sql
-- Insertar usuario EXTERNO con datos de RIAC
INSERT INTO AVAL.BR_RELACIONADOS (
  RELA_RUT,
  RELA_DV,
  RELA_TIPO_USUARIO,
  RELA_NOMBRE,
  RELA_PATERNO,
  RELA_MATERNO,
  RELA_EMAIL,
  RELA_FONO,
  RELA_JURISDICCION,
  RELA_VIGENCIA_INICIO,
  RELA_VIGENCIA_FIN,
  RELA_UNIDAD_PRINCIPAL,
  RELA_FECHA_CREACION,
  RELA_USUARIO_CREACION
) VALUES (
  :rut,
  :dv,
  'EXTERNO',
  SUBSTR(:nombres, 1, 40), -- ⚠️ Límite 40 chars
  :apellidoPaterno,
  :apellidoMaterno,
  :correoElectronico,
  :telefonoContacto,
  :jurisdiccion,
  TO_DATE(:vigenciaInicio, 'YYYY-MM-DD'),
  TO_DATE(:vigenciaFin, 'YYYY-MM-DD'),
  :unidadPrincipal,
  SYSDATE,
  :usuarioCreador
);
```

**Tips de SQL:**
```sql
-- Usuarios EXTERNOS típicamente tienen vigenciaFin definida (no NULL)
-- OCM, Notarios, CBR, CDE: jurisdicción AMPLIADA común
-- RIAC retorna tipoInstitucion: mapear a RELA_CODIGO si es necesario
```

**Validaciones de Negocio:**
```sql
-- VN-001: RUT no duplicado
SELECT COUNT(*) FROM AVAL.BR_RELACIONADOS WHERE RELA_RUT = :rut;

-- VN-002: Validar vigencias
-- vigenciaInicio <= hoy
-- vigenciaFin > vigenciaInicio (obligatorio para EXTERNOS)

-- VN-003: Validar que vigenciaFin no sea NULL para EXTERNOS
-- Implementado en capa Java
```

---

## 4. PUT /{rut}-{dv}/jurisdiccion

**Descripción:** Actualiza el tipo de jurisdicción de un usuario relacionado.

**Endpoint:** `PUT /{rut}-{dv}/jurisdiccion`

**Path Params:**
- `rut` (Number): RUT del usuario sin puntos (ej: 15000000)
- `dv` (String): Dígito verificador (ej: "1")

**Request Body:**
```json
{
  "jurisdiccion": "AMPLIADA"
}
```

**Response 200 OK:**
```json
{
  "rut": 15000000,
  "dv": "1",
  "jurisdiccion": "AMPLIADA",
  "mensaje": "Jurisdicción actualizada correctamente"
}
```

**Response 404 Not Found:**
```json
{
  "error": "Usuario no encontrado",
  "message": "No existe un usuario relacionado con RUT 15000000-1"
}
```

**Mapeo Frontend/Backend:**
| Campo Frontend | Request JSON | BD Columna | Observación |
|----------------|--------------|------------|-------------|
| Toggle Simple/Ampliada | `jurisdiccion` | `RELA_JURISDICCION` | SIMPLE/AMPLIADA |

**Query SQL:**
```sql
UPDATE AVAL.BR_RELACIONADOS
SET RELA_JURISDICCION = :jurisdiccion,
    RELA_FECHA_MODIFICACION = SYSDATE,
    RELA_USUARIO_MODIFICACION = :usuarioModificador
WHERE RELA_RUT = :rut;
```

**Validaciones de Negocio:**
```sql
-- VN-001: Usuario existe
SELECT COUNT(*) FROM AVAL.BR_RELACIONADOS WHERE RELA_RUT = :rut;

-- VN-002: Valor jurisdicción válido ('SIMPLE' o 'AMPLIADA')
-- Implementado en capa Java (constraint CHK_RELA_JURISDICCION en DDL)
```

---

## 5. DELETE /{rut}-{dv}

**Descripción:** Elimina un usuario relacionado y todos sus cargos/funciones (CASCADE).

**Endpoint:** `DELETE /{rut}-{dv}`

**Path Params:**
- `rut` (Number): RUT del usuario sin puntos
- `dv` (String): Dígito verificador

**Response 200 OK:**
```json
{
  "mensaje": "Usuario relacionado eliminado correctamente",
  "rut": 15000000,
  "dv": "1",
  "cargosEliminados": 3,
  "funcionesEliminadas": 7
}
```

**Response 404 Not Found:**
```json
{
  "error": "Usuario no encontrado",
  "message": "No existe un usuario relacionado con RUT 15000000-1"
}
```

**Response 409 Conflict:**
```json
{
  "error": "Usuario tiene registros activos",
  "message": "No se puede eliminar el usuario porque tiene cargos vigentes. Debe desactivarlos primero."
}
```

**Query SQL:**
```sql
-- Verificar cargos vigentes
SELECT COUNT(*) 
FROM AVAL.BR_CARGOS_USUARIO
WHERE CAUS_RELA_RUT = :rut
  AND CAUS_VIGENTE = 'S'
  AND (CAUS_FECHA_FIN IS NULL OR CAUS_FECHA_FIN > SYSDATE);

-- Si no tiene cargos vigentes: eliminar (CASCADE automático)
DELETE FROM AVAL.BR_RELACIONADOS
WHERE RELA_RUT = :rut;

-- Nota: FK con ON DELETE CASCADE eliminará automáticamente:
-- - BR_CARGOS_USUARIO
-- - BR_FUNCIONES_USUARIO (cascade desde cargos)
-- - BR_JURISDICCION_USUARIO
```

**Tips de SQL:**
```sql
-- DELETE CASCADE configurado en DDL:
-- BR_RELACIONADOS → BR_CARGOS_USUARIO → BR_FUNCIONES_USUARIO
-- Validar cargos vigentes antes de permitir eliminación
```

**Validaciones de Negocio:**
```sql
-- VN-001: Usuario existe
SELECT COUNT(*) FROM AVAL.BR_RELACIONADOS WHERE RELA_RUT = :rut;

-- VN-002: No tiene cargos vigentes
SELECT COUNT(*) 
FROM AVAL.BR_CARGOS_USUARIO
WHERE CAUS_RELA_RUT = :rut AND CAUS_VIGENTE = 'S';
```

---

## 6. GET /{rut}-{dv}/cargos/disponibles

**Descripción:** Lista todos los cargos disponibles (vigentes) para asignar a un usuario.

**Endpoint:** `GET /{rut}-{dv}/cargos/disponibles`

**Response 200 OK:**
```json
[
  {
    "codigo": 1,
    "descripcion": "Director Regional"
  },
  {
    "codigo": 5,
    "descripcion": "Jefe de Departamento"
  },
  {
    "codigo": 10,
    "descripcion": "Profesional"
  }
]
```

**Query SQL:**
```sql
SELECT 
  c.CARG_CODIGO as codigo,
  c.CARG_DESCRIPCION as descripcion
FROM AVAL.BR_CARGOS c
WHERE c.CARG_VIGENTE = 1  -- ⚠️ Es NUMBER(1): 1=vigente
ORDER BY c.CARG_DESCRIPCION;
```

**Tips de SQL:**
```sql
-- ⚠️ CARG_VIGENTE es NUMBER(1), no VARCHAR2 'S'/'N'
-- Filtrar con: WHERE CARG_VIGENTE = 1
-- PKs son NUMBER(3), no genérico NUMBER
```

**Validaciones de Negocio:**
```sql
-- VN-001: Listar solo cargos vigentes
SELECT COUNT(*) FROM AVAL.BR_CARGOS WHERE CARG_VIGENTE = 1;
```

---

## 7. POST /{rut}-{dv}/cargos

**Descripción:** Asigna un nuevo cargo a un usuario relacionado.

**Endpoint:** `POST /{rut}-{dv}/cargos`

**Request Body:**
```json
{
  "codigoCargo": 5,
  "codigoUnidad": 1025,
  "fechaInicio": "2025-02-01",
  "fechaFin": null
}
```

**Response 201 Created:**
```json
{
  "id": 789,
  "codigoCargo": 5,
  "descripcionCargo": "Jefe de Departamento",
  "codigoUnidad": 1025,
  "vigente": "S",
  "fechaInicio": "2025-02-01",
  "fechaFin": null,
  "funciones": []
}
```

**Response 400 Bad Request:**
```json
{
  "error": "Cargo no vigente",
  "message": "El cargo seleccionado no está vigente"
}
```

**Response 409 Conflict:**
```json
{
  "error": "Cargo duplicado",
  "message": "El usuario ya tiene asignado el cargo 'Jefe de Departamento' en la unidad 1025"
}
```

**Query SQL:**
```sql
-- Validar cargo vigente
SELECT COUNT(*) 
FROM AVAL.BR_CARGOS
WHERE CARG_CODIGO = :codigoCargo AND CARG_VIGENTE = 1;

-- Validar cargo no duplicado (mismo cargo + unidad vigentes)
SELECT COUNT(*)
FROM AVAL.BR_CARGOS_USUARIO
WHERE CAUS_RELA_RUT = :rut
  AND CAUS_CARGO_CODIGO = :codigoCargo
  AND CAUS_UNIDAD_CODIGO = :codigoUnidad
  AND CAUS_VIGENTE = 'S';

-- Insertar cargo
INSERT INTO AVAL.BR_CARGOS_USUARIO (
  CAUS_ID,
  CAUS_RELA_RUT,
  CAUS_CARGO_CODIGO,
  CAUS_UNIDAD_CODIGO,
  CAUS_VIGENTE,
  CAUS_FECHA_INICIO,
  CAUS_FECHA_FIN,
  CAUS_FECHA_ASIGNACION,
  CAUS_USUARIO_ASIGNADOR
) VALUES (
  SEQ_CARGO_USUARIO_ID.NEXTVAL,
  :rut,
  :codigoCargo,
  :codigoUnidad,
  'S',
  TO_DATE(:fechaInicio, 'YYYY-MM-DD'),
  CASE WHEN :fechaFin IS NOT NULL THEN TO_DATE(:fechaFin, 'YYYY-MM-DD') ELSE NULL END,
  SYSDATE,
  :usuarioAsignador
);
```

**Tips de SQL:**
```sql
-- Usar SEQ_CARGO_USUARIO_ID.NEXTVAL para PK
-- ⚠️ Validar cargo vigente: WHERE CARG_VIGENTE = 1 (NUMBER)
-- ⚠️ FK es NUMBER(3): CAUS_CARGO_CODIGO → BR_CARGOS.CARG_CODIGO
```

**Validaciones de Negocio:**
```sql
-- VN-001: Usuario existe
SELECT COUNT(*) FROM AVAL.BR_RELACIONADOS WHERE RELA_RUT = :rut;

-- VN-002: Cargo existe y vigente
SELECT COUNT(*) 
FROM AVAL.BR_CARGOS 
WHERE CARG_CODIGO = :codigoCargo AND CARG_VIGENTE = 1;

-- VN-003: Cargo no duplicado (mismo cargo + unidad vigentes)
SELECT COUNT(*)
FROM AVAL.BR_CARGOS_USUARIO
WHERE CAUS_RELA_RUT = :rut
  AND CAUS_CARGO_CODIGO = :codigoCargo
  AND CAUS_UNIDAD_CODIGO = :codigoUnidad
  AND CAUS_VIGENTE = 'S';

-- VN-004: Fechas válidas (inicio <= fin si fin no es NULL)
```

---

## 8. DELETE /{rut}-{dv}/cargos/{cargoId}

**Descripción:** Elimina un cargo de un usuario (CASCADE elimina funciones asociadas).

**Endpoint:** `DELETE /{rut}-{dv}/cargos/{cargoId}`

**Path Params:**
- `cargoId` (Number): ID del cargo del usuario (CAUS_ID)

**Response 200 OK:**
```json
{
  "mensaje": "Cargo eliminado correctamente",
  "cargoId": 789,
  "funcionesEliminadas": 3
}
```

**Response 404 Not Found:**
```json
{
  "error": "Cargo no encontrado",
  "message": "No existe el cargo con ID 789 para el usuario 15000000-1"
}
```

**Response 409 Conflict:**
```json
{
  "error": "Cargo vigente",
  "message": "No se puede eliminar un cargo vigente. Debe desactivarlo primero."
}
```

**Query SQL:**
```sql
-- Validar cargo vigente
SELECT CAUS_VIGENTE
FROM AVAL.BR_CARGOS_USUARIO
WHERE CAUS_ID = :cargoId AND CAUS_RELA_RUT = :rut;

-- Si CAUS_VIGENTE = 'N': eliminar (CASCADE)
DELETE FROM AVAL.BR_CARGOS_USUARIO
WHERE CAUS_ID = :cargoId AND CAUS_RELA_RUT = :rut;

-- FK con ON DELETE CASCADE eliminará automáticamente BR_FUNCIONES_USUARIO
```

**Tips de SQL:**
```sql
-- DELETE CASCADE configurado en DDL:
-- BR_CARGOS_USUARIO → BR_FUNCIONES_USUARIO
-- Solo permitir eliminar si CAUS_VIGENTE = 'N'
```

**Validaciones de Negocio:**
```sql
-- VN-001: Cargo existe y pertenece al usuario
SELECT COUNT(*) 
FROM AVAL.BR_CARGOS_USUARIO
WHERE CAUS_ID = :cargoId AND CAUS_RELA_RUT = :rut;

-- VN-002: Cargo no vigente
SELECT CAUS_VIGENTE
FROM AVAL.BR_CARGOS_USUARIO
WHERE CAUS_ID = :cargoId;
-- Solo permitir si CAUS_VIGENTE = 'N'
```

---

## 9. GET /{rut}-{dv}/cargos/{cargoId}/funciones/disponibles

**Descripción:** Lista funciones disponibles (vigentes) para asignar a un cargo específico.

**Endpoint:** `GET /{rut}-{dv}/cargos/{cargoId}/funciones/disponibles`

**Response 200 OK:**
```json
[
  {
    "codigo": 10,
    "descripcion": "Administrador Sistema"
  },
  {
    "codigo": 15,
    "descripcion": "Validador de Avalúos"
  },
  {
    "codigo": 20,
    "descripcion": "Consulta de Tasaciones"
  }
]
```

**Query SQL:**
```sql
-- Funciones disponibles (vigentes) que NO están asignadas al cargo
SELECT 
  f.FUNS_CODIGO as codigo,
  f.FUNS_DESCRIPCION as descripcion
FROM AVAL.BR_FUNCIONES f
WHERE f.FUNS_VIGENTE = 1  -- ⚠️ Es NUMBER(1): 1=vigente
  AND f.FUNS_CODIGO NOT IN (
    SELECT fu.FUUS_FUNC_CODIGO
    FROM AVAL.BR_FUNCIONES_USUARIO fu
    WHERE fu.FUUS_CAUS_ID = :cargoId
  )
ORDER BY f.FUNS_DESCRIPCION;
```

**Tips de SQL:**
```sql
-- ⚠️ FUNS_VIGENTE es NUMBER(1): 1=vigente, 0=no vigente
-- Filtrar funciones ya asignadas con NOT IN
-- PKs son NUMBER(3)
```

**Validaciones de Negocio:**
```sql
-- VN-001: Cargo existe
SELECT COUNT(*) FROM AVAL.BR_CARGOS_USUARIO WHERE CAUS_ID = :cargoId;

-- VN-002: Listar solo funciones vigentes no asignadas
SELECT COUNT(*) FROM AVAL.BR_FUNCIONES WHERE FUNS_VIGENTE = 1;
```

---

## 10. POST /{rut}-{dv}/cargos/{cargoId}/funciones

**Descripción:** Asigna una nueva función a un cargo del usuario.

**Endpoint:** `POST /{rut}-{dv}/cargos/{cargoId}/funciones`

**Request Body:**
```json
{
  "codigoFuncion": 10
}
```

**Response 201 Created:**
```json
{
  "id": 999,
  "codigoFuncion": 10,
  "descripcionFuncion": "Administrador Sistema",
  "fechaAsignacion": "2025-02-01T10:30:00"
}
```

**Response 400 Bad Request:**
```json
{
  "error": "Función no vigente",
  "message": "La función seleccionada no está vigente"
}
```

**Response 409 Conflict:**
```json
{
  "error": "Función duplicada",
  "message": "La función 'Administrador Sistema' ya está asignada a este cargo"
}
```

**Query SQL:**
```sql
-- Validar función vigente
SELECT COUNT(*) 
FROM AVAL.BR_FUNCIONES
WHERE FUNS_CODIGO = :codigoFuncion AND FUNS_VIGENTE = 1;

-- Validar función no duplicada
SELECT COUNT(*)
FROM AVAL.BR_FUNCIONES_USUARIO
WHERE FUUS_CAUS_ID = :cargoId
  AND FUUS_FUNC_CODIGO = :codigoFuncion;

-- Insertar función
INSERT INTO AVAL.BR_FUNCIONES_USUARIO (
  FUUS_ID,
  FUUS_CAUS_ID,
  FUUS_FUNC_CODIGO,
  FUUS_FECHA_ASIGNACION,
  FUUS_USUARIO_ASIGNADOR
) VALUES (
  SEQ_FUNCION_USUARIO_ID.NEXTVAL,
  :cargoId,
  :codigoFuncion,
  SYSDATE,
  :usuarioAsignador
);
```

**Tips de SQL:**
```sql
-- Usar SEQ_FUNCION_USUARIO_ID.NEXTVAL para PK
-- ⚠️ Validar función vigente: WHERE FUNS_VIGENTE = 1 (NUMBER)
-- ⚠️ FK es NUMBER(3): FUUS_FUNC_CODIGO → BR_FUNCIONES.FUNS_CODIGO
-- UNIQUE constraint: UK_FUUS_CARGO_FUNCION (FUUS_CAUS_ID, FUUS_FUNC_CODIGO)
```

**Validaciones de Negocio:**
```sql
-- VN-001: Cargo existe
SELECT COUNT(*) FROM AVAL.BR_CARGOS_USUARIO WHERE CAUS_ID = :cargoId;

-- VN-002: Función existe y vigente
SELECT COUNT(*) 
FROM AVAL.BR_FUNCIONES 
WHERE FUNS_CODIGO = :codigoFuncion AND FUNS_VIGENTE = 1;

-- VN-003: Función no duplicada (UNIQUE constraint)
SELECT COUNT(*)
FROM AVAL.BR_FUNCIONES_USUARIO
WHERE FUUS_CAUS_ID = :cargoId AND FUUS_FUNC_CODIGO = :codigoFuncion;
```

---

## 11. DELETE /{rut}-{dv}/cargos/{cargoId}/funciones/{funcionId}

**Descripción:** Elimina una función de un cargo del usuario.

**Endpoint:** `DELETE /{rut}-{dv}/cargos/{cargoId}/funciones/{funcionId}`

**Path Params:**
- `cargoId` (Number): ID del cargo
- `funcionId` (Number): ID de la función del usuario (FUUS_ID)

**Response 200 OK:**
```json
{
  "mensaje": "Función eliminada correctamente",
  "funcionId": 999,
  "cargoId": 789
}
```

**Response 404 Not Found:**
```json
{
  "error": "Función no encontrada",
  "message": "No existe la función con ID 999 para el cargo 789"
}
```

**Response 409 Conflict:**
```json
{
  "error": "Última función del cargo",
  "message": "No se puede eliminar la última función de un cargo. Debe eliminar el cargo completo."
}
```

**Query SQL:**
```sql
-- Validar que no sea la última función
SELECT COUNT(*)
FROM AVAL.BR_FUNCIONES_USUARIO
WHERE FUUS_CAUS_ID = :cargoId;

-- Si COUNT > 1: eliminar
DELETE FROM AVAL.BR_FUNCIONES_USUARIO
WHERE FUUS_ID = :funcionId AND FUUS_CAUS_ID = :cargoId;
```

**Tips de SQL:**
```sql
-- Validar COUNT(*) > 1 antes de eliminar
-- Si es la última función: retornar error 409
-- Usuario debe eliminar el cargo completo (no solo la última función)
```

**Validaciones de Negocio:**
```sql
-- VN-001: Función existe y pertenece al cargo
SELECT COUNT(*)
FROM AVAL.BR_FUNCIONES_USUARIO
WHERE FUUS_ID = :funcionId AND FUUS_CAUS_ID = :cargoId;

-- VN-002: No es la última función del cargo
SELECT COUNT(*)
FROM AVAL.BR_FUNCIONES_USUARIO
WHERE FUUS_CAUS_ID = :cargoId;
-- Solo permitir eliminar si COUNT > 1
```

---

## 12. POST /{rut}-{dv}/jurisdicciones-extendidas

**Descripción:** Agrega un período de multi-jurisdicción (apoyo temporal en otra unidad).

**Endpoint:** `POST /{rut}-{dv}/jurisdicciones-extendidas`

**Request Body:**
```json
{
  "codigoUnidadApoyo": 3050,
  "fechaInicio": "2025-03-01",
  "fechaFin": "2025-06-30",
  "motivo": "Apoyo temporal período declaración de renta"
}
```

**Response 201 Created:**
```json
{
  "id": 100,
  "codigoUnidadApoyo": 3050,
  "fechaInicio": "2025-03-01",
  "fechaFin": "2025-06-30",
  "motivo": "Apoyo temporal período declaración de renta"
}
```

**Response 400 Bad Request:**
```json
{
  "error": "Fechas inválidas",
  "message": "La fecha fin debe ser posterior a la fecha inicio"
}
```

**Query SQL:**
```sql
INSERT INTO AVAL.BR_JURISDICCION_USUARIO (
  JUUR_ID,
  JUUR_RELA_RUT,
  JUUR_UNIDAD_APOYO,
  JUUR_FECHA_INICIO,
  JUUR_FECHA_FIN,
  JUUR_MOTIVO,
  JUUR_FECHA_REGISTRO,
  JUUR_USUARIO_REGISTRO
) VALUES (
  SEQ_JURISDICCION_USUARIO_ID.NEXTVAL,
  :rut,
  :codigoUnidadApoyo,
  TO_DATE(:fechaInicio, 'YYYY-MM-DD'),
  TO_DATE(:fechaFin, 'YYYY-MM-DD'),
  :motivo,
  SYSDATE,
  :usuarioRegistro
);
```

**Tips de SQL:**
```sql
-- Usar SEQ_JURISDICCION_USUARIO_ID.NEXTVAL para PK
-- CHK_JUUR_FECHAS valida fechaInicio < fechaFin en DDL
-- Multi-jurisdicción es temporal: fechaFin siempre obligatoria
```

**Validaciones de Negocio:**
```sql
-- VN-001: Usuario existe
SELECT COUNT(*) FROM AVAL.BR_RELACIONADOS WHERE RELA_RUT = :rut;

-- VN-002: Fechas válidas (inicio < fin, ambas obligatorias)
-- Implementado en constraint CHK_JUUR_FECHAS

-- VN-003: Validar que no exista solapamiento de períodos
SELECT COUNT(*)
FROM AVAL.BR_JURISDICCION_USUARIO
WHERE JUUR_RELA_RUT = :rut
  AND JUUR_UNIDAD_APOYO = :codigoUnidadApoyo
  AND (
    (TO_DATE(:fechaInicio, 'YYYY-MM-DD') BETWEEN JUUR_FECHA_INICIO AND JUUR_FECHA_FIN)
    OR (TO_DATE(:fechaFin, 'YYYY-MM-DD') BETWEEN JUUR_FECHA_INICIO AND JUUR_FECHA_FIN)
  );
```

---

## 13. DELETE /{rut}-{dv}/jurisdicciones-extendidas/{jurisdiccionId}

**Descripción:** Elimina un período de multi-jurisdicción.

**Endpoint:** `DELETE /{rut}-{dv}/jurisdicciones-extendidas/{jurisdiccionId}`

**Path Params:**
- `jurisdiccionId` (Number): ID del período de multi-jurisdicción (JUUR_ID)

**Response 200 OK:**
```json
{
  "mensaje": "Período de multi-jurisdicción eliminado correctamente",
  "jurisdiccionId": 100
}
```

**Response 404 Not Found:**
```json
{
  "error": "Jurisdicción no encontrada",
  "message": "No existe el período de multi-jurisdicción con ID 100"
}
```

**Query SQL:**
```sql
DELETE FROM AVAL.BR_JURISDICCION_USUARIO
WHERE JUUR_ID = :jurisdiccionId AND JUUR_RELA_RUT = :rut;
```

**Validaciones de Negocio:**
```sql
-- VN-001: Jurisdicción existe y pertenece al usuario
SELECT COUNT(*)
FROM AVAL.BR_JURISDICCION_USUARIO
WHERE JUUR_ID = :jurisdiccionId AND JUUR_RELA_RUT = :rut;
```

---

## Resumen de Endpoints

| Método | Endpoint | Descripción | Tablas BD |
|--------|----------|-------------|-----------|
| GET | `/buscar` | Buscar usuario por RUT | BR_RELACIONADOS, BR_CARGOS_USUARIO, BR_FUNCIONES_USUARIO |
| POST | `/interno` | Crear usuario INTERNO (SIGER) | BR_RELACIONADOS |
| POST | `/externo` | Crear usuario EXTERNO (RIAC) | BR_RELACIONADOS |
| PUT | `/{rut}-{dv}/jurisdiccion` | Actualizar jurisdicción | BR_RELACIONADOS |
| DELETE | `/{rut}-{dv}` | Eliminar usuario (CASCADE) | BR_RELACIONADOS (CASCADE a cargos/funciones) |
| GET | `/{rut}-{dv}/cargos/disponibles` | Listar cargos disponibles | BR_CARGOS |
| POST | `/{rut}-{dv}/cargos` | Asignar cargo a usuario | BR_CARGOS_USUARIO |
| DELETE | `/{rut}-{dv}/cargos/{cargoId}` | Eliminar cargo (CASCADE funciones) | BR_CARGOS_USUARIO (CASCADE a funciones) |
| GET | `/{rut}-{dv}/cargos/{cargoId}/funciones/disponibles` | Listar funciones disponibles | BR_FUNCIONES |
| POST | `/{rut}-{dv}/cargos/{cargoId}/funciones` | Asignar función a cargo | BR_FUNCIONES_USUARIO |
| DELETE | `/{rut}-{dv}/cargos/{cargoId}/funciones/{funcionId}` | Eliminar función | BR_FUNCIONES_USUARIO |
| POST | `/{rut}-{dv}/jurisdicciones-extendidas` | Agregar multi-jurisdicción | BR_JURISDICCION_USUARIO |
| DELETE | `/{rut}-{dv}/jurisdicciones-extendidas/{jurisdiccionId}` | Eliminar multi-jurisdicción | BR_JURISDICCION_USUARIO |

**Total Endpoints:** 13  
**Integraciones Externas:** 2 (SIGER, RIAC)  
**Operaciones CRUD:** Completas para usuario, cargos, funciones y multi-jurisdicción  
**Validaciones:** 30+ queries de validación de negocio implementadas
