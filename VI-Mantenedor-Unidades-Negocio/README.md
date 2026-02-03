# VI. Mantenedor de Unidades de Negocio

## 1. Contexto

El módulo VI **NO tiene especificación funcional documentada** en el archivo de requerimientos original.

Sin embargo, el modelo de datos Oracle **SÍ contiene tablas completas** para gestionar unidades de negocio:
- **BR_UNIDADES_NEGOCIO**: 585 registros, 23 columnas (validado 3 feb 2026)
- **BR_TIPOS_UNIDAD**: 23 tipos, 2 columnas (validado 3 feb 2026)

## 2. Modelo de Datos Validado

### 2.1 Tabla BR_UNIDADES_NEGOCIO

**Estructura validada con Oracle 19c (queilen.sii.cl:1540/koala):**

```sql
-- PK Compuesta: UNNE_TIUN_CODIGO + UNNE_CODIGO
-- FK Recursiva: UNNE_UNNE_TIUN_CODIGO + UNNE_UNNE_CODIGO (unidad padre)

UNNE_TIUN_CODIGO         NUMBER(2)     NOT NULL  -- PK parte 1, FK a TIPOS_UNIDAD
UNNE_CODIGO              NUMBER(6)     NOT NULL  -- PK parte 2
UNNE_NOMBRE              VARCHAR2(50)  NOT NULL  -- Nombre unidad
UNNE_DIRECCION           VARCHAR2(50)  NOT NULL  -- Dirección física
UNNE_FONO_1              VARCHAR2(15)  NOT NULL  -- Teléfono principal
UNNE_FAX_1               VARCHAR2(15)  NOT NULL  -- Fax
UNNE_EMAIL               VARCHAR2(80)            -- Email contacto
UNNE_COMU_CODIGO_CONARA_SII  NUMBER(5) NOT NULL  -- Comuna SII
UNNE_UNNE_TIUN_CODIGO    NUMBER(2)              -- FK recursiva tipo unidad padre
UNNE_UNNE_CODIGO         NUMBER(6)              -- FK recursiva código unidad padre
UNNE_VIGENTE             NUMBER(1)     NOT NULL  -- 1=vigente, 0=no vigente
... (12 columnas adicionales)
```

**Datos reales:**
- **585 unidades de negocio** registradas en producción
- Jerarquía mediante FK recursiva (unidades padre/hijas)
- PK compuesta (tipo + código) permite múltiples códigos por tipo

### 2.2 Tabla BR_TIPOS_UNIDAD

**Estructura validada:**

```sql
TIUN_CODIGO         NUMBER(2)     NOT NULL  -- PK
TIUN_DESCRIPCION    VARCHAR2(40)  NOT NULL  -- Descripción tipo
```

**Datos reales:**
- **23 tipos de unidad** registrados
- Ejemplos posibles: Dirección Regional, Departamento, Sección, Unidad, etc.

## 3. Alcance del Módulo (Propuesto)

Basado en tablas existentes y patrones de otros módulos (V, VII, VIII):

### 3.1 Funcionalidades CRUD

1. **Listar Unidades de Negocio**
   - Filtrar por tipo de unidad
   - Filtrar por vigencia
   - Búsqueda por nombre/código
   - Vista jerárquica (unidad padre → hijas)

2. **Crear Unidad de Negocio**
   - Seleccionar tipo de unidad (FK a BR_TIPOS_UNIDAD)
   - Asignar código automático secuencial por tipo
   - Ingresar nombre, dirección, contacto
   - Seleccionar unidad padre (opcional, para jerarquía)
   - Seleccionar comuna SII
   - Vigente por defecto

3. **Modificar Unidad de Negocio**
   - Actualizar información descriptiva
   - Cambiar unidad padre (reestructuración)
   - Modificar vigencia

4. **Eliminar Unidad de Negocio**
   - Validar que no tenga unidades hijas activas
   - Soft-delete (UNNE_VIGENTE = 0)

### 3.2 Funcionalidades Adicionales

1. **Gestión de Tipos de Unidad**
   - Listar tipos existentes
   - Crear nuevo tipo
   - Modificar descripción tipo
   - No eliminar (integridad referencial)

2. **Vista Jerárquica**
   - Árbol de unidades organizacionales
   - Expandir/colapsar ramas
   - Navegación por niveles

3. **Auditoría**
   - Historial de cambios (patrón de otros módulos)
   - Fecha/hora, usuario, evento, descripción
   - Nro ticket autorización

## 4. Perfiles de Acceso Propuestos

Siguiendo patrón del módulo V:

- **Administrador Nacional**: CRUD sin restricciones
- **Administrador Regional**: CRUD solo unidades de su región
- **Administrador Unidad**: CRUD solo su unidad y sub-unidades
- **Consulta**: Solo lectura

## 5. Estructura de Archivos

- **README.md** - Este archivo (especificación funcional propuesta)
- **frontend.md** - Componentes Vue 3 (pendiente)
- **backend-apis.md** - Endpoints REST (pendiente)
- **HdU-*.md** - Historias de usuario (pendiente)
- **DDL/create-tables.sql** - DDL validado (TABLAS EXISTEN, sin cambios requeridos)

## 6. Referencias

### 6.1 Validación Oracle

Conexión: `queilen.sii.cl:1540/koala`  
Schema: `AVAL`  
Fecha: 3 febrero 2026

**Queries ejecutadas:**
```sql
-- Verificar existencia tablas
SELECT table_name FROM all_tables 
WHERE owner = 'AVAL' 
AND (table_name LIKE '%UNIDAD%' OR table_name LIKE '%UNNE%');
-- Resultado: 10 tablas (incluyendo BR_UNIDADES_NEGOCIO, BR_TIPOS_UNIDAD)

-- Estructura completa
DESC AVAL.BR_UNIDADES_NEGOCIO;  -- 23 columnas
DESC AVAL.BR_TIPOS_UNIDAD;      -- 2 columnas

-- Datos en producción
SELECT COUNT(*) FROM AVAL.BR_UNIDADES_NEGOCIO;  -- 585
SELECT COUNT(*) FROM AVAL.BR_TIPOS_UNIDAD;      -- 23
```

### 6.2 Patrones Aplicables

Ver [system-prompt.md](../system-prompt.md):
- Sección "Patrones de Implementación Backend" (queries con JOINs complejos)
- Tablas relacionadas con Unidades de Negocio (estructura completa)

### 6.3 Módulos de Referencia

- **Módulo V (Usuarios Relacionados)**: Patrón CRUD con extensiones, LEFT JOIN + COALESCE
- **Módulo VII (Funciones)**: Patrón CRUD con relaciones complejas
- **Módulo VIII (Grupos)**: Patrón CRUD con tablas nuevas

## 7. Estado Actual

- [x] Validación Oracle completada
- [x] DDL/create-tables.sql creado (sin cambios requeridos)
- [x] README.md con especificación propuesta
- [ ] backend-apis.md (siguiente paso)
- [ ] frontend.md (siguiente paso)
- [ ] HdU-*.md (siguiente paso)

## 8. Próximos Pasos

1. **backend-apis.md**: Especificar endpoints REST usando queries Oracle validadas
2. **frontend.md**: Especificar componentes Vue 3 para CRUD + vista jerárquica
3. **HdU-*.md**: Crear historias de usuario para funcionalidades propuestas

## 9. Notas Importantes

- **NO hay especificación funcional en requerimientos originales**
- **SÍ hay modelo de datos completo en Oracle con 585 registros**
- Módulo debe crearse basado en modelo existente + patrones de otros módulos
- Respetar estructura Oracle (PK compuesta, FK recursiva para jerarquía)
- Validar antes de cualquier ALTER TABLE (usar extensiones si se requieren campos adicionales)
