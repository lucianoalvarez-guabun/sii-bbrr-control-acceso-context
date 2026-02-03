# Backend APIs - Módulo VIII: Mantenedor de Grupos

## Formato de Rutas

**CRÍTICO:** Todas las APIs deben incluir el RUT del usuario autenticado en la ruta:

```
Formato: /{rut}-{dv}/
Ejemplo: /12.345.678-9/
```

**Estructura completa:**
```
/acaj-ms/api/v1/{rut}-{dv}/grupos/{operacion}
```

## Endpoints

### 1. POST /crear - Crear Grupo

**URL:** `/acaj-ms/api/v1/{rut}-{dv}/grupos/crear`

**Descripción:** Crea un nuevo grupo con su primer título y primera función. Genera códigos automáticos con secuencias.

**Request:**
```json
{
  "nombre": "Sistema OT",
  "titulo": "Reportes",
  "funcionId": 15
}
```

**Validaciones:**
- `nombre`: obligatorio, max 100 caracteres, sin caracteres especiales
- `titulo`: obligatorio, max 100 caracteres
- `funcionId`: obligatorio, debe existir en BR_FUNCIONES con FUNS_VIGENTE=1
- Usuario autenticado debe tener perfil "Administrador Nacional"

**Response 201 Created:**
```json
{
  "grupoId": 123,
  "codigo": 123,
  "nombre": "Sistema OT",
  "vigente": 1,
  "mensaje": "Grupo creado exitosamente"
}
```

**Errores:**
- 400 Bad Request: `{ "error": "Validación", "mensaje": "Nombre obligatorio" }`
- 403 Forbidden: `{ "error": "Autorización", "mensaje": "Sin permisos para crear grupos" }`
- 404 Not Found: `{ "error": "No encontrado", "mensaje": "Función ID 15 no existe" }`
- 500 Internal Server Error: `{ "error": "Servidor", "mensaje": "Error al crear grupo" }`

**Tips de SQL:**
```sql
-- Transacción atómica con 3 INSERTs
BEGIN
  INSERT INTO BR_GRUPOS (GRUP_CODIGO, GRUP_NOMBRE, GRUP_VIGENTE)
  VALUES (:codigo, :nombre, 1);
  
  INSERT INTO BR_TITULOS (TITU_GRUP_CODIGO, TITU_CODIGO, TITU_NOMBRE, TITU_ORDEN)
  VALUES (:grupCodigo, :tituCodigo, :titulo, 1);
  
  INSERT INTO BR_TITULOS_FUNCIONES (TIFU_GRUP_CODIGO, TIFU_TITU_CODIGO, TIFU_FUNS_CODIGO)
  VALUES (:grupCodigo, :tituCodigo, :funsCodigo);
  COMMIT;
END;
```

---

### 2. GET /buscar - Buscar Grupo

**URL:** `/acaj-ms/api/v1/{rut}-{dv}/grupos/buscar`

**Descripción:** Busca un grupo por ID y vigencia. Retorna información completa con títulos y funciones.

**Query Params:**
- `vigente`: 'S' | 'N' (obligatorio, por defecto 'S')
- `grupoId`: number (obligatorio)

**Ejemplo:** `/acaj-ms/api/v1/12.345.678-9/grupos/buscar?vigente=S&grupoId=123`

**Response 200 OK:**
```json
{
  "grupoId": 123,
  "nombre": "Sistema OT",
  "cantidadUsuarios": 100,
  "vigente": "S",
  "titulos": [
    {
      "tituloId": 45,
      "nombre": "OT Reportes",
      "orden": 1,
      "funciones": [
        {
          "funcionId": 15,
          "nombre": "csdfcasc",
          "descripcion": "Consulta reportes OT"
        },
        {
          "funcionId": 16,
          "nombre": "Función 2",
          "descripcion": null
        }
      ]
    },
    {
      "tituloId": 46,
      "nombre": "OT Opciones para jefaturas",
      "orden": 2,
      "funciones": [
        {
          "funcionId": 17,
          "nombre": "Función 1",
          "descripcion": null
        }
      ]
    }
  ]
}
```

**Errores:**
- 400 Bad Request: `{ "error": "Validación", "mensaje": "Parámetro vigente obligatorio" }`
- 404 Not Found: `{ "error": "No encontrado", "mensaje": "Grupo ID 123 no existe" }`

**Query SQL:**
```sql
SELECT 
  g.GRUP_CODIGO, g.GRUP_NOMBRE, g.GRUP_VIGENTE,
  (SELECT COUNT(*) FROM BR_USUARIOS_GRUPOS WHERE USGR_GRUP_CODIGO = g.GRUP_CODIGO) AS cantidad_usuarios,
  t.TITU_CODIGO, t.TITU_NOMBRE, t.TITU_ORDEN,
  f.FUNS_CODIGO, f.FUNS_DESCRIPCION
FROM AVAL.BR_GRUPOS g
LEFT JOIN AVAL.BR_TITULOS t ON t.TITU_GRUP_CODIGO = g.GRUP_CODIGO
LEFT JOIN AVAL.BR_TITULOS_FUNCIONES tf ON tf.TIFU_GRUP_CODIGO = t.TITU_GRUP_CODIGO AND tf.TIFU_TITU_CODIGO = t.TITU_CODIGO
LEFT JOIN AVAL.BR_FUNCIONES f ON f.FUNS_CODIGO = tf.TIFU_FUNS_CODIGO
WHERE g.GRUP_CODIGO = :grupoCodigo
  AND g.GRUP_VIGENTE = :vigente
ORDER BY t.TITU_ORDEN, f.FUNS_DESCRIPCION;
```

---

### 3. PUT /{grupoId}/vigencia - Modificar Vigencia

**URL:** `/acaj-ms/api/v1/{rut}-{dv}/grupos/{grupoId}/vigencia`

**Descripción:** Cambia el estado de vigencia del grupo (vigente/no vigente).

**Path Params:**
- `grupoId`: number (obligatorio)

**Request:**
```json
{
  "vigente": "N"
}
```

**Validaciones:**
- `vigente`: obligatorio, solo valores 'S' o 'N'
- Grupo debe existir

**Response 200 OK:**
```json
{
  "mensaje": "Vigencia actualizada",
  "grupoId": 123,
  "nuevaVigencia": "N"
}
```

**Errores:**
- 400 Bad Request: `{ "error": "Validación", "mensaje": "Valor vigente debe ser 'S' o 'N'" }`
- 404 Not Found: `{ "error": "No encontrado", "mensaje": "Grupo ID 123 no existe" }`

**Query SQL:**
```sql
UPDATE BR_GRUPOS 
SET GRUP_VIGENTE = :vigente,
    GRUP_FECHA_MODIFICACION = SYSDATE,
    GRUP_USUARIO_MODIFICACION = :rutUsuario
WHERE GRUP_ID = :grupoId;
```

---

### 4. DELETE /{grupoId} - Eliminar Grupo

**URL:** `/acaj-ms/api/v1/{rut}-{dv}/grupos/{grupoId}`

**Descripción:** Elimina un grupo y todos sus registros asociados (títulos y funciones) mediante DELETE CASCADE.

**Path Params:**
- `grupoId`: number (obligatorio)

**Response 200 OK:**
```json
{
  "mensaje": "Grupo eliminado exitosamente",
  "eliminados": {
    "grupo": 1,
    "titulos": 2,
    "funciones": 5
  }
}
```

**Errores:**
- 404 Not Found: `{ "error": "No encontrado", "mensaje": "Grupo ID 123 no existe" }`
- 409 Conflict: `{ "error": "Conflicto", "mensaje": "Grupo tiene usuarios activos asociados" }`

**Tips de SQL:**
```sql
-- Verificar usuarios activos antes de eliminar
SELECT COUNT(*) FROM BR_USUARIO_GRUPO 
WHERE USGR_GRUP_ID = :grupoId AND USGR_ACTIVO = 'S';
-- Si COUNT > 0 → Error 409

-- DELETE CASCADE automático elimina títulos y funciones
DELETE FROM BR_GRUPOS WHERE GRUP_ID = :grupoId;
```

---

### 5. GET /{grupoId}/usuarios - Listar Usuarios del Grupo

**URL:** `/acaj-ms/api/v1/{rut}-{dv}/grupos/{grupoId}/usuarios`

**Descripción:** Obtiene lista de usuarios asociados al grupo con vigencias.

**Path Params:**
- `grupoId`: number (obligatorio)

**Response 200 OK:**
```json
{
  "total": 100,
  "usuarios": [
    {
      "rut": "15000000-1",
      "nombre": "Adela Maria Lozano Arriagada",
      "vigenciaInicio": "2025-08-05",
      "vigenciaFin": "2026-08-05"
    },
    {
      "rut": "15000000-1",
      "nombre": "Adela Maria Lozano Arriagada",
      "vigenciaInicio": "2025-08-05",
      "vigenciaFin": null
    }
  ]
}
```

**Query SQL:**
```sql
SELECT 
  r.RELA_RUT,
  r.RELA_NOMBRE_COMPLETO,
  ug.USGR_FECHA_INICIO,
  ug.USGR_FECHA_FIN
FROM BR_USUARIO_GRUPO ug
JOIN BR_RELACIONADOS r ON r.RELA_RUT = ug.USGR_RELA_RUT
WHERE ug.USGR_GRUP_ID = :grupoId
  AND ug.USGR_ACTIVO = 'S'
ORDER BY r.RELA_NOMBRE_COMPLETO;
```

---

### 6. POST /{grupoId}/titulos - Agregar Título

**URL:** `/acaj-ms/api/v1/{rut}-{dv}/grupos/{grupoId}/titulos`

**Descripción:** Agrega un nuevo título al grupo con una o más funciones. Calcula orden automáticamente.

**Path Params:**
- `grupoId`: number (obligatorio)

**Request:**
```json
{
  "titulo": "OT Opciones para jefaturas",
  "funciones": [17, 18, 19]
}
```

**Validaciones:**
- `titulo`: obligatorio, max 100 caracteres
- `funciones`: array obligatorio, min 1 elemento, todos deben existir en BR_FUNCIONES

**Response 201 Created:**
```json
{
  "tituloId": 46,
  "orden": 2,
  "mensaje": "Título agregado exitosamente"
}
```

**Tips de SQL:**
```sql
-- Calcular orden automático: MAX(TITU_ORDEN) + 1
SELECT COALESCE(MAX(TITU_ORDEN), 0) + 1 
FROM BR_TITULOS WHERE TITU_GRUP_ID = :grupoId;

-- INSERT múltiples funciones en batch (FORALL)
FORALL i IN funciones.FIRST..funciones.LAST
  INSERT INTO BR_TITULOS_FUNCIONES VALUES (:tituloId, funciones(i), ...);
```

---

### 7. DELETE /{grupoId}/titulos/{tituloId} - Eliminar Título

**URL:** `/acaj-ms/api/v1/{rut}-{dv}/grupos/{grupoId}/titulos/{tituloId}`

**Descripción:** Elimina un título y todas sus funciones asociadas mediante DELETE CASCADE.

**Path Params:**
- `grupoId`: number (obligatorio)
- `tituloId`: number (obligatorio)

**Response 200 OK:**
```json
{
  "mensaje": "Título eliminado exitosamente",
  "eliminados": {
    "titulo": 1,
    "funciones": 3
  }
}
```

**Query SQL:**
```sql
-- Verificar que título pertenezca al grupo
SELECT COUNT(*) FROM BR_TITULOS 
WHERE TITU_ID = :tituloId AND TITU_GRUP_ID = :grupoId;

-- Si COUNT = 0 → Error 404

-- Eliminar (CASCADE automático)
DELETE FROM BR_TITULOS WHERE TITU_ID = :tituloId;
-- ON DELETE CASCADE elimina automáticamente BR_TITULOS_FUNCIONES
```

---

### 8. POST /{grupoId}/titulos/{tituloId}/funciones - Agregar Función a Título

**URL:** `/acaj-ms/api/v1/{rut}-{dv}/grupos/{grupoId}/titulos/{tituloId}/funciones`

**Descripción:** Agrega una función específica a un título. Se agrega de una en una.

**Path Params:**
- `grupoId`: number (obligatorio)
- `tituloId`: number (obligatorio)

**Request:**
```json
{
  "funcionId": 20
}
```

**Validaciones:**
- `funcionId`: obligatorio, debe existir en BR_FUNCIONES
- No debe existir duplicado (tituloId + funcionId)

**Response 201 Created:**
```json
{
  "mensaje": "Función agregada exitosamente"
}
```

**Errores:**
- 409 Conflict: `{ "error": "Conflicto", "mensaje": "Función ya existe en este título" }`

**Query SQL:**
```sql
-- Verificar duplicado
SELECT COUNT(*) FROM BR_TITULOS_FUNCIONES 
WHERE TIFU_TITU_ID = :tituloId AND TIFU_FUNC_ID = :funcionId;

-- Si COUNT > 0 → Error 409

-- INSERT
INSERT INTO BR_TITULOS_FUNCIONES (
  TIFU_TITU_ID, TIFU_FUNC_ID, TIFU_FECHA_CREACION, TIFU_USUARIO_CREACION
) VALUES (
  :tituloId, :funcionId, SYSDATE, :rutUsuario
);
```

---

### 9. DELETE /{grupoId}/titulos/{tituloId}/funciones/{funcionId} - Eliminar Función

**URL:** `/acaj-ms/api/v1/{rut}-{dv}/grupos/{grupoId}/titulos/{tituloId}/funciones/{funcionId}`

**Descripción:** Elimina una función específica de un título. Solo elimina la relación.

**Path Params:**
- `grupoId`: number (obligatorio)
- `tituloId`: number (obligatorio)
- `funcionId`: number (obligatorio)

**Response 200 OK:**
```json
{
  "mensaje": "Función eliminada exitosamente"
}
```

**Validación:**
- Título debe tener al menos 2 funciones (no permitir eliminar la última)

**Errores:**
- 409 Conflict: `{ "error": "Conflicto", "mensaje": "No se puede eliminar la última función del título" }`

**Query SQL:**
```sql
-- Verificar cantidad de funciones del título
SELECT COUNT(*) FROM BR_TITULOS_FUNCIONES WHERE TIFU_TITU_ID = :tituloId;

-- Si COUNT <= 1 → Error 409

-- Eliminar
DELETE FROM BR_TITULOS_FUNCIONES 
WHERE TIFU_TITU_ID = :tituloId AND TIFU_FUNC_ID = :funcionId;
```

---

### 10. GET /{grupoId}/historial - Obtener Historial

**URL:** `/acaj-ms/api/v1/{rut}-{dv}/grupos/{grupoId}/historial`

**Descripción:** Obtiene el historial completo de cambios del grupo desde tabla de auditoría.

**Path Params:**
- `grupoId`: number (obligatorio)

**Query Params (opcionales):**
- `fechaDesde`: date (formato yyyy-MM-dd)
- `fechaHasta`: date (formato yyyy-MM-dd)

**Response 200 OK:**
```json
{
  "registros": [
    {
      "fecha": "2026-01-30 14:35:00",
      "evento": "Crear",
      "descripcion": "Se creó el Grupo Sistema OT",
      "rutFuncionario": "12345678-9",
      "nombreFuncionario": "Juan Pérez",
      "ubicacion": "Dir. Regional Metropolitana",
      "nroTicket": "SDAV-2026-001234",
      "autorizacionSubdirector": "Si",
      "convenioVigente": "No"
    },
    {
      "fecha": "2026-01-31 10:20:00",
      "evento": "Modificar",
      "descripcion": "Se modificó la vigencia del Grupo Sistema OT a No Vigente",
      "rutFuncionario": "98765432-1",
      "nombreFuncionario": "María González",
      "ubicacion": "Dir. Regional Metropolitana",
      "nroTicket": "SDAV-2026-001250",
      "autorizacionSubdirector": "No",
      "convenioVigente": "No"
    }
  ]
}
```

**Query SQL:**
```sql
SELECT 
  a.AUDI_FECHA,
  a.AUDI_OPERACION AS evento,
  a.AUDI_JUSTIFICACION AS descripcion,
  a.AUDI_RUT_EJECUTOR,
  r.RELA_NOMBRE_COMPLETO,
  u.UNNE_NOMBRE AS ubicacion,
  a.AUDI_TICKET,
  a.AUDI_AUTORIZACION,
  a.AUDI_CONVENIO
FROM BR_AUDITORIA_CAMBIOS a
JOIN BR_RELACIONADOS r ON r.RELA_RUT = a.AUDI_RUT_EJECUTOR
LEFT JOIN BR_UNIDADES_NEGOCIO u ON u.UNNE_CODIGO = r.RELA_UNIDAD
WHERE a.AUDI_TABLA = 'BR_GRUPOS'
  AND a.AUDI_REGISTRO_ID = :grupoId
  AND (:fechaDesde IS NULL OR a.AUDI_FECHA >= :fechaDesde)
  AND (:fechaHasta IS NULL OR a.AUDI_FECHA <= :fechaHasta)
ORDER BY a.AUDI_FECHA DESC;
```

---

## Mapeo Frontend/Backend

| Frontend Campo | Componente | Backend API | API Body/Query | BD Tabla.Columna | Tipo | Validación |
|----------------|-----------|-------------|---------------|------------------|------|------------|
| "Ingrese nombre del Grupo" | CreateGroupModal | POST /crear | body.nombre | BR_GRUPOS.GRUP_NOMBRE | VARCHAR2(100) | required, max 100 |
| "Ingrese nombre del Título" | CreateGroupModal | POST /crear | body.titulo | BR_TITULOS.TITU_NOMBRE | VARCHAR2(100) | required, max 100 |
| "Seleccione Función" (dropdown) | CreateGroupModal | POST /crear | body.funcionId | BR_TITULOS_FUNCIONES.TIFU_FUNC_ID | NUMBER | required, FK BR_FUNCIONES |
| Toggle "Vigente/No Vigente" | GroupSection | PUT /{id}/vigencia | body.vigente | BR_GRUPOS.GRUP_VIGENTE | VARCHAR2(1) | 'S' o 'N' |
| Cantidad usuarios (clickeable) | GroupSection | GET /{id}/usuarios | - | COUNT(*) BR_USUARIO_GRUPO | NUMBER | Read-only |
| Dropdown "Grupo" | SearchBar | GET /buscar | query.grupoId | BR_GRUPOS.GRUP_ID | NUMBER | required |
| Filtro vigente | SearchBar | GET /buscar | query.vigente | BR_GRUPOS.GRUP_VIGENTE | VARCHAR2(1) | default 'S' |
| Input título (modal agregar) | AddTituloModal | POST /{gid}/titulos | body.titulo | BR_TITULOS.TITU_NOMBRE | VARCHAR2(100) | required, max 100 |
| Dropdown función (modal agregar) | AddTituloModal | POST /{gid}/titulos | body.funciones[] | BR_TITULOS_FUNCIONES.TIFU_FUNC_ID | NUMBER[] | min 1 elemento |
| Título read-only (agregar función) | AddFuncionModal | POST /{gid}/titulos/{tid}/funciones | - | BR_TITULOS.TITU_NOMBRE | VARCHAR2(100) | Read-only |
| Dropdown función (agregar a título) | AddFuncionModal | POST /{gid}/titulos/{tid}/funciones | body.funcionId | BR_TITULOS_FUNCIONES.TIFU_FUNC_ID | NUMBER | required, unique |

## Validaciones de Negocio

### Validaciones de Creación

1. **Nombre grupo único:**
   ```sql
   SELECT COUNT(*) FROM BR_GRUPOS WHERE UPPER(GRUP_NOMBRE) = UPPER(:nombre);
   -- Si COUNT > 0 → Error 409 "Nombre de grupo ya existe"
   ```

2. **Función vigente:**
   ```sql
   SELECT FUNC_VIGENTE FROM BR_FUNCIONES WHERE FUNC_ID = :funcionId;
   -- Si FUNC_VIGENTE != 'S' → Error 400 "Función no vigente"
   ```

3. **Perfil administrador:**
   ```sql
   SELECT COUNT(*) FROM BR_PERFILES_USUARIO 
   WHERE PERU_RUT = :rutUsuario AND PERU_PERFIL = 'ADMIN_NACIONAL';
   -- Si COUNT = 0 → Error 403 "Sin permisos"
   ```

### Validaciones de Eliminación

1. **Usuarios activos:**
   ```sql
   SELECT COUNT(*) FROM BR_USUARIO_GRUPO 
   WHERE USGR_GRUP_ID = :grupoId AND USGR_ACTIVO = 'S';
   -- Si COUNT > 0 → Error 409 "Grupo tiene usuarios activos"
   ```

2. **Última función de título:**
   ```sql
   SELECT COUNT(*) FROM BR_TITULOS_FUNCIONES WHERE TIFU_TITU_ID = :tituloId;
   -- Si COUNT <= 1 → Error 409 "No se puede eliminar última función"
   ```

## Códigos de Estado HTTP

| Código | Significado | Cuándo usar |
|--------|-------------|-------------|
| 200 OK | Éxito en operación de lectura/modificación | GET, PUT, DELETE exitosos |
| 201 Created | Recurso creado exitosamente | POST crear grupo/título/función |
| 400 Bad Request | Error de validación de datos | Campos obligatorios faltantes, formato incorrecto |
| 403 Forbidden | Sin permisos para la operación | Usuario sin perfil administrador |
| 404 Not Found | Recurso no encontrado | Grupo/título/función no existe |
| 409 Conflict | Conflicto de estado | Nombre duplicado, usuarios activos, última función |
| 500 Internal Server Error | Error del servidor | Error en BD, excepción no controlada |

## Auditoría

Todas las operaciones CUD (Create, Update, Delete) deben registrarse en `BR_AUDITORIA_CAMBIOS`:

```sql
INSERT INTO BR_AUDITORIA_CAMBIOS (
  AUDI_ID,
  AUDI_TABLA,
  AUDI_OPERACION,
  AUDI_REGISTRO_ID,
  AUDI_VALORES_ANTERIORES,
  AUDI_VALORES_NUEVOS,
  AUDI_RUT_EJECUTOR,
  AUDI_FECHA,
  AUDI_TICKET,
  AUDI_JUSTIFICACION
) VALUES (
  SEQ_AUDITORIA.NEXTVAL,
  'BR_GRUPOS',
  'INSERT',
  :grupoId,
  NULL,
  JSON_OBJECT('nombre' VALUE :nombre, 'vigente' VALUE 'S'),
  :rutUsuario,
  SYSTIMESTAMP,
  :ticket,
  'Se creó el Grupo ' || :nombre
);
```

## Paginación (Historial)

Para endpoint GET /historial con muchos registros:

**Query Params:**
- `page`: número de página (default: 1)
- `pageSize`: registros por página (default: 50, max: 200)

**Response Headers:**
```
X-Total-Count: 350
X-Page: 1
X-Page-Size: 50
X-Total-Pages: 7
```

## Ejemplos de Uso

### Flujo Completo: Crear Grupo con 2 Títulos

```bash
# 1. Crear grupo inicial
POST /acaj-ms/api/v1/12.345.678-9/grupos/crear
{
  "nombre": "Sistema OT",
  "titulo": "Reportes",
  "funcionId": 15
}
→ Response: { "grupoId": 123 }

# 2. Buscar grupo creado
GET /acaj-ms/api/v1/12.345.678-9/grupos/buscar?vigente=S&grupoId=123
→ Response: { grupo con 1 título }

# 3. Agregar segundo título
POST /acaj-ms/api/v1/12.345.678-9/grupos/123/titulos
{
  "titulo": "OT Opciones para jefaturas",
  "funciones": [17, 18]
}
→ Response: { "tituloId": 46, "orden": 2 }

# 4. Agregar función al primer título
POST /acaj-ms/api/v1/12.345.678-9/grupos/123/titulos/45/funciones
{
  "funcionId": 19
}
→ Response: { "mensaje": "Función agregada exitosamente" }

# 5. Ver usuarios del grupo
GET /acaj-ms/api/v1/12.345.678-9/grupos/123/usuarios
→ Response: { "total": 0, "usuarios": [] }

# 6. Modificar vigencia
PUT /acaj-ms/api/v1/12.345.678-9/grupos/123/vigencia
{
  "vigente": "N"
}
→ Response: { "nuevaVigencia": "N" }

# 7. Ver historial
GET /acaj-ms/api/v1/12.345.678-9/grupos/123/historial
→ Response: { "registros": [...6 operaciones...] }
```

## Seguridad

### Validación de RUT en Path

```java
@GetMapping("/{rut}-{dv}/grupos/buscar")
public ResponseEntity<?> buscar(
    @PathVariable String rut,
    @PathVariable String dv,
    @RequestParam String vigente,
    @RequestParam Long grupoId
) {
    // Validar que RUT del path coincide con JWT
    String rutFromToken = SecurityContextHolder.getContext()
        .getAuthentication().getName();
    
    if (!rutFromToken.equals(rut + "-" + dv)) {
        return ResponseEntity.status(403)
            .body(Map.of("error", "Autorización", 
                        "mensaje", "RUT no coincide con token"));
    }
    
    // Continuar con lógica...
}
```

### Protección CSRF

- APIs REST con JWT no requieren CSRF token
- `csrf().disable()` en SecurityConfig

### SQL Injection Prevention

- Usar PreparedStatement/NamedParameterJdbcTemplate
- NO concatenar strings en queries
- Validar tipos de datos antes de query

## Testing

### Unit Tests (JUnit 5 + Mockito)

```java
@Test
void crearGrupo_conDatosValidos_debeRetornar201() {
    // Arrange
    CreateGrupoRequest request = new CreateGrupoRequest("Sistema OT", "Reportes", 15L);
    when(grupoRepository.existsByNombre(anyString())).thenReturn(false);
    when(funcionRepository.existsByIdAndVigente(anyLong(), anyString())).thenReturn(true);
    
    // Act
    ResponseEntity<?> response = grupoController.crear("12345678", "9", request);
    
    // Assert
    assertEquals(201, response.getStatusCodeValue());
    verify(grupoRepository, times(1)).save(any(Grupo.class));
}
```

### Integration Tests (Spring Boot Test)

```java
@SpringBootTest(webEnvironment = RANDOM_PORT)
@AutoConfigureMockMvc
class GrupoControllerIntegrationTest {
    
    @Test
    void buscarGrupo_conGrupoExistente_debeRetornarGrupoCompleto() throws Exception {
        mockMvc.perform(get("/acaj-ms/api/v1/12345678-9/grupos/buscar")
                .param("vigente", "S")
                .param("grupoId", "123")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.grupoId").value(123))
            .andExpect(jsonPath("$.titulos").isArray())
            .andExpect(jsonPath("$.titulos[0].funciones").isArray());
    }
}
```

## Referencias

- Frontend: [frontend.md](./frontend.md)
- Modelo de Datos: [DDL/create-tables.sql](./DDL/create-tables.sql)
- Historias de Usuario: HdU-*.md
