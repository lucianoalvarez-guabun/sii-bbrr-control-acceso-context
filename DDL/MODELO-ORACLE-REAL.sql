-- ===========================================================================
-- MODELO ORACLE REAL - Tablas relacionadas con Funciones/Roles
-- ===========================================================================
-- Extraído desde: queilen.sii.cl:1540/koala
-- Schema: AVAL
-- Oracle: 19c Enterprise Edition Release 19.0.0.0.0 - Production
-- Fecha: 2 de febrero de 2026
--
-- RESUMEN: El modelo existente combina OPERACIÓN + ALCANCE en un solo código
--          de 2 caracteres en BR_ATRIBUCIONES (ej: BN = Consultar Nacional,
--          BU = Consultar Unidad, JG = Ingresar Regional, etc.)
--
-- NO EXISTE: Tabla BR_ALCANCES separada (el alcance está embebido en atribución)
-- ===========================================================================

-- ============================================
-- TABLA: BR_FUNCIONES
-- ============================================
-- Descripción: (sin comentario en BD)
-- Columnas detectadas: 3

CREATE TABLE AVAL.BR_FUNCIONES (
    FUNS_CODIGO         NUMBER(3)       NOT NULL,
    FUNS_DESCRIPCION    VARCHAR2(60)    NOT NULL,
    FUNS_VIGENTE        NUMBER(1)       NOT NULL,
    
    CONSTRAINT PK_BR_FUNCIONES PRIMARY KEY (FUNS_CODIGO)
);

COMMENT ON COLUMN AVAL.BR_FUNCIONES.FUNS_CODIGO IS 'Código de la función/rol (max 999)';
COMMENT ON COLUMN AVAL.BR_FUNCIONES.FUNS_DESCRIPCION IS 'Descripción de la función (max 60 caracteres)';
COMMENT ON COLUMN AVAL.BR_FUNCIONES.FUNS_VIGENTE IS '1=vigente, 0=no vigente';

-- Ejemplo de datos:
-- FUNS_CODIGO | FUNS_DESCRIPCION                                      | FUNS_VIGENTE
-- ------------|-------------------------------------------------------|-------------
-- 1           | ADMINISTRADOR NACIONAL                                 | 1
-- 2           | SUPERVISOR REGIONAL                                    | 1
-- 3           | OPERADOR UNIDAD                                        | 1

-- ============================================
-- TABLA: BR_OPCIONES
-- ============================================
-- Descripción: (sin comentario en BD)
-- Columnas detectadas: 9

CREATE TABLE AVAL.BR_OPCIONES (
    OPCI_CODIGO             NUMBER(4)       NOT NULL,
    OPCI_NOMBRE             VARCHAR2(100)   NULL,
    OPCI_DESCRIPCION        VARCHAR2(500)   NULL,
    OPCI_URL                VARCHAR2(500)   NULL,
    OPCI_VIGENTE            NUMBER(1)       NULL,
    OPCI_OPCI_CODIGO        NUMBER(4)       NULL,  -- FK recursiva: opción padre
    OPCI_TIPO               NUMBER(1)       NULL,
    OPCI_ORDEN              NUMBER          NULL,
    OPCI_IMAGEN             VARCHAR2(500)   NULL,
    
    CONSTRAINT PK_BR_OPCIONES PRIMARY KEY (OPCI_CODIGO),
    CONSTRAINT FK_BR_OPCIONES_PADRE FOREIGN KEY (OPCI_OPCI_CODIGO)
        REFERENCES AVAL.BR_OPCIONES(OPCI_CODIGO)
);

COMMENT ON COLUMN AVAL.BR_OPCIONES.OPCI_CODIGO IS 'Código único de la opción de aplicativo';
COMMENT ON COLUMN AVAL.BR_OPCIONES.OPCI_NOMBRE IS 'Nombre de la opción de menú';
COMMENT ON COLUMN AVAL.BR_OPCIONES.OPCI_URL IS 'URL de la opción';
COMMENT ON COLUMN AVAL.BR_OPCIONES.OPCI_VIGENTE IS '1=vigente, 0=no vigente';
COMMENT ON COLUMN AVAL.BR_OPCIONES.OPCI_OPCI_CODIGO IS 'Código de opción padre (árbol jerárquico)';

-- ============================================
-- TABLA: BR_OPCIONES_FUNCION
-- ============================================
-- Descripción: (sin comentario en BD)
-- Columnas detectadas: 3
-- NOTA: NO tiene PK, NO tiene columna ORDEN (no soporta drag-drop),
--       NO tiene columna VIGENTE

CREATE TABLE AVAL.BR_OPCIONES_FUNCION (
    FUNS_CODIGO         NUMBER(3)       NULL,  -- FK a BR_FUNCIONES
    OPCI_CODIGO         NUMBER(4)       NULL,  -- FK a BR_OPCIONES
    TIPO_ACCESO         NUMBER(1)       NULL,  -- Campo adicional no especificado
    
    CONSTRAINT FK_OPCIONES_FUNCION_FUNS FOREIGN KEY (FUNS_CODIGO)
        REFERENCES AVAL.BR_FUNCIONES(FUNS_CODIGO),
    CONSTRAINT FK_OPCIONES_FUNCION_OPCI FOREIGN KEY (OPCI_CODIGO)
        REFERENCES AVAL.BR_OPCIONES(OPCI_CODIGO)
);

COMMENT ON COLUMN AVAL.BR_OPCIONES_FUNCION.FUNS_CODIGO IS 'Código de la función';
COMMENT ON COLUMN AVAL.BR_OPCIONES_FUNCION.OPCI_CODIGO IS 'Código de la opción';
COMMENT ON COLUMN AVAL.BR_OPCIONES_FUNCION.TIPO_ACCESO IS 'Tipo de acceso (1=lectura, 2=escritura, etc.)';

-- LIMITACIÓN: Sin PK ni columna ORDEN, no se puede implementar drag-and-drop (HdU-010)

-- ============================================
-- TABLA: BR_ATRIBUCIONES
-- ============================================
-- Descripción: (sin comentario en BD)
-- Columnas detectadas: 2
-- NOTA CRÍTICA: Esta tabla combina OPERACIÓN + ALCANCE en un código de 2 caracteres
--               Primer carácter = Operación (B=Consultar, C=Cancelar, D=Detalle, etc.)
--               Segundo carácter = Alcance (F=Personal, U=Unidad, G=Regional, N=Nacional)

CREATE TABLE AVAL.BR_ATRIBUCIONES (
    ATRI_CODIGO         VARCHAR2(2)     NOT NULL,
    ATRI_DESCRIPCION    VARCHAR2(40)    NOT NULL,
    
    CONSTRAINT PK_BR_ATRIBUCIONES PRIMARY KEY (ATRI_CODIGO)
);

COMMENT ON COLUMN AVAL.BR_ATRIBUCIONES.ATRI_CODIGO IS 'Código de atribución (2 chars: Operación+Alcance)';
COMMENT ON COLUMN AVAL.BR_ATRIBUCIONES.ATRI_DESCRIPCION IS 'Descripción de la atribución';

-- Ejemplo de datos (61 registros encontrados):
-- ATRI_CODIGO | ATRI_DESCRIPCION
-- ------------|-------------------------------------------
-- BF          | CONSULTAR, PERSONAL
-- BU          | CONSULTAR, UNIDAD
-- BG          | CONSULTAR, REGIONAL
-- BN          | CONSULTAR, NACIONAL
-- JU          | INGRESAR, UNIDAD
-- JG          | INGRESAR, REGIONAL
-- JN          | INGRESAR, NACIONAL
-- UU          | MODIFICAR, UNIDAD
-- UG          | MODIFICAR, REGIONAL
-- UN          | MODIFICAR, NACIONAL
-- EU          | ELIMINAR, UNIDAD
-- EG          | ELIMINAR, REGIONAL
-- EN          | ELIMINAR, NACIONAL
-- 3U          | GENERAR INFORMES, UNIDAD
-- 3G          | GENERAR INFORMES, REGIONAL
-- 3N          | GENERAR INFORMES, NACIONAL
-- ... (48 registros más)

-- MAPEO OPERACIONES (primer carácter):
-- 1 = RECTIFICAR ESTADOS
-- 2 = MANTENER ESTADOS
-- 3 = GENERAR INFORMES
-- A = AMPLIAR PLAZO
-- B = CONSULTAR
-- C = CANCELAR
-- D = DETALLE/FICHA
-- E = ELIMINAR
-- F = REENVIAR RECHAZADAS
-- G = CAMBIAR CBR
-- J = INGRESAR
-- M = MARCAR/DESCARGAR
-- P = EXPORTAR
-- Q = PRUEBA
-- R = REABRIR/RECTIFICAR
-- S = FIRMAR SUBROGANTE
-- T = FIRMAR TITULAR
-- U = MODIFICAR
-- V = VISADO/VER
-- X = REUBICAR
-- Y = SOBRETASA/NADA
-- Z = REEMPLAZAR

-- MAPEO ALCANCES (segundo carácter):
-- F = PERSONAL
-- U = UNIDAD
-- G = REGIONAL
-- N = NACIONAL

-- ============================================
-- TABLA: BR_ATRIBUCIONES_OPCION_FUNCION
-- ============================================
-- Descripción: (sin comentario en BD)
-- Columnas detectadas: 5
-- NOTA: Esta tabla relaciona Función + Opción + Atribución
--       NO tiene campo ALCANCE separado (está embebido en AOFU_ATRI_CODIGO)
--       SÍ tiene fechas de vigencia (inicio/término)

CREATE TABLE AVAL.BR_ATRIBUCIONES_OPCION_FUNCION (
    AOFU_FUNS_CODIGO        NUMBER(3)       NOT NULL,  -- FK a BR_FUNCIONES
    AOFU_OPCI_CODIGO        NUMBER(4)       NOT NULL,  -- FK a BR_OPCIONES
    AOFU_ATRI_CODIGO        VARCHAR2(2)     NOT NULL,  -- FK a BR_ATRIBUCIONES (incluye alcance)
    AOFU_FECHA_INICIO       DATE            NULL,
    AOFU_FECHA_TERMINO      DATE            NULL,
    
    CONSTRAINT PK_BR_ATRIBUCIONES_OPCION_FUNCION PRIMARY KEY (
        AOFU_FUNS_CODIGO, 
        AOFU_OPCI_CODIGO, 
        AOFU_ATRI_CODIGO
    ),
    CONSTRAINT FK_ATRIB_OPC_FUNC_FUNS FOREIGN KEY (AOFU_FUNS_CODIGO)
        REFERENCES AVAL.BR_FUNCIONES(FUNS_CODIGO),
    CONSTRAINT FK_ATRIB_OPC_FUNC_OPCI FOREIGN KEY (AOFU_OPCI_CODIGO)
        REFERENCES AVAL.BR_OPCIONES(OPCI_CODIGO),
    CONSTRAINT FK_ATRIB_OPC_FUNC_ATRI FOREIGN KEY (AOFU_ATRI_CODIGO)
        REFERENCES AVAL.BR_ATRIBUCIONES(ATRI_CODIGO)
);

COMMENT ON COLUMN AVAL.BR_ATRIBUCIONES_OPCION_FUNCION.AOFU_FUNS_CODIGO IS 'Código de la función';
COMMENT ON COLUMN AVAL.BR_ATRIBUCIONES_OPCION_FUNCION.AOFU_OPCI_CODIGO IS 'Código de la opción';
COMMENT ON COLUMN AVAL.BR_ATRIBUCIONES_OPCION_FUNCION.AOFU_ATRI_CODIGO IS 'Código de atribución (incluye alcance)';
COMMENT ON COLUMN AVAL.BR_ATRIBUCIONES_OPCION_FUNCION.AOFU_FECHA_INICIO IS 'Fecha inicio vigencia de la atribución';
COMMENT ON COLUMN AVAL.BR_ATRIBUCIONES_OPCION_FUNCION.AOFU_FECHA_TERMINO IS 'Fecha término vigencia (NULL=indefinido)';

-- Ejemplo de datos:
-- AOFU_FUNS_CODIGO | AOFU_OPCI_CODIGO | AOFU_ATRI_CODIGO | AOFU_FECHA_INICIO | AOFU_FECHA_TERMINO
-- -----------------|------------------|------------------|-------------------|--------------------
-- 1                | 100              | BN               | 2020-01-01        | NULL
-- 1                | 100              | JN               | 2020-01-01        | NULL
-- 2                | 100              | BG               | 2020-01-01        | NULL
-- 2                | 101              | JG               | 2020-01-01        | NULL

-- ============================================
-- TABLA: BR_FUNCIONES_CARGO_RELACIONADO
-- ============================================
-- Descripción: (sin comentario en BD)
-- Columnas detectadas: 7
-- NOTA: Esta tabla asigna funciones a usuarios (relacionados) según su cargo
--       Es más compleja que BR_USUARIO_FUNCION especificado porque incluye
--       referencias a cargo (CGRE), unidad de negocio (UNNE), tipo de unidad (TIUN)

CREATE TABLE AVAL.BR_FUNCIONES_CARGO_RELACIONADO (
    FCGR_CGRE_UNNE_TIUN_CODIGO  NUMBER(2)       NOT NULL,  -- FK a tipo de unidad
    FCGR_CGRE_UNNE_CODIGO       NUMBER(6)       NOT NULL,  -- FK a unidad de negocio
    FCGR_CGRE_CODIGO            NUMBER(3)       NOT NULL,  -- FK a cargo
    FCGR_CGRE_RUT               NUMBER(9)       NOT NULL,  -- FK a BR_RELACIONADOS
    FCGR_FUNS_CODIGO            NUMBER(3)       NOT NULL,  -- FK a BR_FUNCIONES
    FCGR_FECHA_INICIO           DATE            NOT NULL,
    FCGR_FECHA_TERMINO          DATE            NOT NULL,
    
    CONSTRAINT PK_BR_FUNCIONES_CARGO_RELACIONADO PRIMARY KEY (
        FCGR_CGRE_UNNE_TIUN_CODIGO,
        FCGR_CGRE_UNNE_CODIGO,
        FCGR_CGRE_CODIGO,
        FCGR_CGRE_RUT,
        FCGR_FUNS_CODIGO
    ),
    CONSTRAINT FK_FUNC_CARGO_REL_RUT FOREIGN KEY (FCGR_CGRE_RUT)
        REFERENCES AVAL.BR_RELACIONADOS(RELA_RUT),
    CONSTRAINT FK_FUNC_CARGO_REL_FUNS FOREIGN KEY (FCGR_FUNS_CODIGO)
        REFERENCES AVAL.BR_FUNCIONES(FUNS_CODIGO)
);

COMMENT ON COLUMN AVAL.BR_FUNCIONES_CARGO_RELACIONADO.FCGR_CGRE_UNNE_TIUN_CODIGO IS 'Código tipo unidad';
COMMENT ON COLUMN AVAL.BR_FUNCIONES_CARGO_RELACIONADO.FCGR_CGRE_UNNE_CODIGO IS 'Código unidad de negocio';
COMMENT ON COLUMN AVAL.BR_FUNCIONES_CARGO_RELACIONADO.FCGR_CGRE_CODIGO IS 'Código del cargo';
COMMENT ON COLUMN AVAL.BR_FUNCIONES_CARGO_RELACIONADO.FCGR_CGRE_RUT IS 'RUT del usuario relacionado';
COMMENT ON COLUMN AVAL.BR_FUNCIONES_CARGO_RELACIONADO.FCGR_FUNS_CODIGO IS 'Código de la función asignada';
COMMENT ON COLUMN AVAL.BR_FUNCIONES_CARGO_RELACIONADO.FCGR_FECHA_INICIO IS 'Fecha inicio asignación';
COMMENT ON COLUMN AVAL.BR_FUNCIONES_CARGO_RELACIONADO.FCGR_FECHA_TERMINO IS 'Fecha término asignación';

-- ============================================
-- TABLA: BR_RELACIONADOS
-- ============================================
-- Descripción: (sin comentario en BD)
-- Columnas detectadas: 9
-- NOTA: Tabla de usuarios del sistema

CREATE TABLE AVAL.BR_RELACIONADOS (
    RELA_RUT                NUMBER(9)       NOT NULL,
    RELA_DV                 VARCHAR2(1)     NOT NULL,
    RELA_NOMBRE             VARCHAR2(100)   NULL,
    RELA_APELLIDO_PATERNO   VARCHAR2(100)   NULL,
    RELA_APELLIDO_MATERNO   VARCHAR2(100)   NULL,
    RELA_EMAIL              VARCHAR2(100)   NULL,
    RELA_TELEFONO           VARCHAR2(20)    NULL,
    RELA_ACTIVO             NUMBER(1)       NULL,
    RELA_FECHA_REGISTRO     DATE            NULL,
    
    CONSTRAINT PK_BR_RELACIONADOS PRIMARY KEY (RELA_RUT)
);

COMMENT ON COLUMN AVAL.BR_RELACIONADOS.RELA_RUT IS 'RUT del usuario (sin dígito verificador)';
COMMENT ON COLUMN AVAL.BR_RELACIONADOS.RELA_DV IS 'Dígito verificador del RUT';
COMMENT ON COLUMN AVAL.BR_RELACIONADOS.RELA_NOMBRE IS 'Nombre del usuario';
COMMENT ON COLUMN AVAL.BR_RELACIONADOS.RELA_ACTIVO IS '1=activo, 0=inactivo';

-- ===========================================================================
-- CONCLUSIONES
-- ===========================================================================
--
-- 1. NO EXISTE tabla BR_ALCANCES separada
--    → El alcance está embebido en BR_ATRIBUCIONES.ATRI_CODIGO (2° carácter)
--    → Ejemplo: BN = Consultar Nacional, BU = Consultar Unidad
--
-- 2. Nomenclatura diferente a la especificada:
--    → FUNS_* en lugar de FUNC_*
--    → BR_OPCIONES_FUNCION en lugar de BR_FUNCION_OPCION
--    → BR_ATRIBUCIONES_OPCION_FUNCION en lugar de BR_FUNCION_OPCION_ATRIB_ALCANCE
--    → BR_FUNCIONES_CARGO_RELACIONADO en lugar de BR_USUARIO_FUNCION (más complejo)
--
-- 3. Limitaciones estructura legado:
--    → BR_OPCIONES_FUNCION sin PK, sin ORDEN, sin VIGENTE
--      (no soporta drag-and-drop HdU-010)
--    → BR_FUNCIONES solo 3 columnas (sin auditoría extendida)
--    → FUNS_DESCRIPCION VARCHAR2(60) en lugar de 500
--    → FUNS_CODIGO NUMBER(3) límite 999 funciones
--
-- 4. Ventajas modelo existente:
--    → Ya probado en producción
--    → Integrado con acaj-ms (funcionando)
--    → 61 atribuciones definidas (operaciones + alcances)
--    → Tablas con FKs e índices optimizados
--
-- 5. Recomendación:
--    → ADAPTAR backend-apis.md y frontend.md al modelo existente
--    → NO crear tablas paralelas (duplicaría funcionalidad)
--    → Si se requiere drag-and-drop, crear tabla extensión:
--      BR_OPCIONES_FUNCION_EXT con campos adicionales
--    → Si se requiere gestión alcances independiente, crear:
--      BR_ALCANCES (catálogo de 4 alcances: F, U, G, N)
--      pero manteniendo lógica actual en BR_ATRIBUCIONES
--
-- ===========================================================================
-- Queries útiles para validación:
-- ===========================================================================
--
-- 1. Ver funciones con sus opciones y atribuciones:
/*
SELECT 
    f.funs_codigo,
    f.funs_descripcion,
    o.opci_codigo,
    o.opci_nombre,
    aofu.aofu_atri_codigo,
    a.atri_descripcion,
    SUBSTR(aofu.aofu_atri_codigo, 1, 1) as operacion,
    SUBSTR(aofu.aofu_atri_codigo, 2, 1) as alcance
FROM AVAL.BR_FUNCIONES f
JOIN AVAL.BR_OPCIONES_FUNCION of 
    ON of.funs_codigo = f.funs_codigo
JOIN AVAL.BR_OPCIONES o 
    ON o.opci_codigo = of.opci_codigo
JOIN AVAL.BR_ATRIBUCIONES_OPCION_FUNCION aofu
    ON aofu.aofu_funs_codigo = f.funs_codigo
    AND aofu.aofu_opci_codigo = of.opci_codigo
JOIN AVAL.BR_ATRIBUCIONES a
    ON a.atri_codigo = aofu.aofu_atri_codigo
WHERE f.funs_vigente = 1
ORDER BY f.funs_codigo, o.opci_codigo, aofu.aofu_atri_codigo;
*/
--
-- 2. Ver usuarios con sus funciones asignadas:
/*
SELECT 
    r.rela_rut,
    r.rela_nombre,
    r.rela_apellido_paterno,
    f.funs_codigo,
    f.funs_descripcion,
    fcgr.fcgr_fecha_inicio,
    fcgr.fcgr_fecha_termino
FROM AVAL.BR_RELACIONADOS r
JOIN AVAL.BR_FUNCIONES_CARGO_RELACIONADO fcgr
    ON fcgr.fcgr_cgre_rut = r.rela_rut
JOIN AVAL.BR_FUNCIONES f
    ON f.funs_codigo = fcgr.fcgr_funs_codigo
WHERE r.rela_activo = 1
  AND fcgr.fcgr_fecha_termino > SYSDATE
ORDER BY r.rela_rut, f.funs_codigo;
*/
--
-- 3. Ver todas las atribuciones (operación + alcance):
/*
SELECT 
    atri_codigo,
    SUBSTR(atri_codigo, 1, 1) as operacion,
    SUBSTR(atri_codigo, 2, 1) as alcance,
    atri_descripcion,
    CASE SUBSTR(atri_codigo, 2, 1)
        WHEN 'F' THEN 'Personal'
        WHEN 'U' THEN 'Unidad'
        WHEN 'G' THEN 'Regional'
        WHEN 'N' THEN 'Nacional'
        ELSE 'Otro'
    END as alcance_nombre
FROM AVAL.BR_ATRIBUCIONES
ORDER BY atri_codigo;
*/
--
-- ===========================================================================
