-- ===========================================================================
-- Script de Creación de Tablas - Módulo VIII: Mantenedor de Grupos
-- ===========================================================================
-- Proyecto: Control de Acceso SII
-- Schema: AVAL
-- Base de Datos: Oracle 19c (queilen.sii.cl:1540/koala)
--
-- CRITICAL: Este DDL crea 5 tablas nuevas que NO existen en el schema AVAL:
--   - BR_GRUPOS
--   - BR_TITULOS
--   - BR_TITULOS_FUNCIONES
--   - BR_USUARIO_GRUPO
--   - BR_USUARIO_GRUPO_ORDEN
--
-- Dependencias externas (tablas que SÍ existen):
--   - BR_FUNCIONES (para FK en BR_TITULOS_FUNCIONES)
--   - BR_RELACIONADOS (para FK en BR_USUARIO_GRUPO)
-- ===========================================================================

-- ===========================================================================
-- SEQUENCES
-- ===========================================================================

CREATE SEQUENCE SEQ_GRUPO_ID
  START WITH 1
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;

COMMENT ON SEQUENCE SEQ_GRUPO_ID IS 'Secuencia para generar IDs de grupos (BR_GRUPOS.GRUP_ID)';


CREATE SEQUENCE SEQ_TITULO_ID
  START WITH 1
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;

COMMENT ON SEQUENCE SEQ_TITULO_ID IS 'Secuencia para generar IDs de títulos (BR_TITULOS.TITU_ID)';


-- ===========================================================================
-- TABLA: BR_GRUPOS
-- Descripción: Maestro de grupos de permisos con vigencias
-- ===========================================================================

CREATE TABLE BR_GRUPOS (
  GRUP_ID                   NUMBER        NOT NULL,
  GRUP_NOMBRE               VARCHAR2(100) NOT NULL,
  GRUP_VIGENTE              VARCHAR2(1)   DEFAULT 'S' NOT NULL,
  GRUP_FECHA_CREACION       DATE          DEFAULT SYSDATE NOT NULL,
  GRUP_USUARIO_CREACION     VARCHAR2(20)  NOT NULL,
  GRUP_FECHA_MODIFICACION   DATE          NULL,
  GRUP_USUARIO_MODIFICACION VARCHAR2(20)  NULL,
  
  CONSTRAINT PK_GRUPOS PRIMARY KEY (GRUP_ID),
  CONSTRAINT UK_GRUPOS_NOMBRE UNIQUE (GRUP_NOMBRE),
  CONSTRAINT CK_GRUPOS_VIGENTE CHECK (GRUP_VIGENTE IN ('S', 'N'))
);

COMMENT ON TABLE BR_GRUPOS IS 'Maestro de grupos de permisos del sistema';
COMMENT ON COLUMN BR_GRUPOS.GRUP_ID IS 'ID único del grupo (PK, secuencia SEQ_GRUPO_ID)';
COMMENT ON COLUMN BR_GRUPOS.GRUP_NOMBRE IS 'Nombre del grupo (único, max 100 caracteres)';
COMMENT ON COLUMN BR_GRUPOS.GRUP_VIGENTE IS 'Estado de vigencia (S=Vigente, N=No Vigente)';
COMMENT ON COLUMN BR_GRUPOS.GRUP_FECHA_CREACION IS 'Fecha de creación del registro';
COMMENT ON COLUMN BR_GRUPOS.GRUP_USUARIO_CREACION IS 'RUT del usuario que creó el registro (formato XX.XXX.XXX-X)';
COMMENT ON COLUMN BR_GRUPOS.GRUP_FECHA_MODIFICACION IS 'Fecha de última modificación';
COMMENT ON COLUMN BR_GRUPOS.GRUP_USUARIO_MODIFICACION IS 'RUT del usuario que modificó el registro';


-- ===========================================================================
-- TABLA: BR_TITULOS
-- Descripción: Títulos asociados a grupos (relación 1:N con BR_GRUPOS)
-- ===========================================================================

CREATE TABLE BR_TITULOS (
  TITU_ID                   NUMBER        NOT NULL,
  TITU_GRUP_ID              NUMBER        NOT NULL,
  TITU_NOMBRE               VARCHAR2(100) NOT NULL,
  TITU_ORDEN                NUMBER        DEFAULT 1 NOT NULL,
  TITU_FECHA_CREACION       DATE          DEFAULT SYSDATE NOT NULL,
  TITU_USUARIO_CREACION     VARCHAR2(20)  NOT NULL,
  
  CONSTRAINT PK_TITULOS PRIMARY KEY (TITU_ID),
  CONSTRAINT FK_TITULOS_GRUPO FOREIGN KEY (TITU_GRUP_ID) 
    REFERENCES BR_GRUPOS (GRUP_ID) ON DELETE CASCADE,
  CONSTRAINT UK_TITULOS_GRUPO_ORDEN UNIQUE (TITU_GRUP_ID, TITU_ORDEN),
  CONSTRAINT CK_TITULOS_ORDEN CHECK (TITU_ORDEN > 0)
);

COMMENT ON TABLE BR_TITULOS IS 'Títulos (secciones colapsables) asociados a grupos';
COMMENT ON COLUMN BR_TITULOS.TITU_ID IS 'ID único del título (PK, secuencia SEQ_TITULO_ID)';
COMMENT ON COLUMN BR_TITULOS.TITU_GRUP_ID IS 'ID del grupo padre (FK a BR_GRUPOS con DELETE CASCADE)';
COMMENT ON COLUMN BR_TITULOS.TITU_NOMBRE IS 'Nombre del título (ej: "Reportes", "OT Opciones para jefaturas")';
COMMENT ON COLUMN BR_TITULOS.TITU_ORDEN IS 'Orden de visualización dentro del grupo (único por grupo)';
COMMENT ON COLUMN BR_TITULOS.TITU_FECHA_CREACION IS 'Fecha de creación del registro';
COMMENT ON COLUMN BR_TITULOS.TITU_USUARIO_CREACION IS 'RUT del usuario que creó el registro';


-- ===========================================================================
-- TABLA: BR_TITULOS_FUNCIONES
-- Descripción: Relación N:M entre títulos y funciones (PK compuesta)
-- ===========================================================================

CREATE TABLE BR_TITULOS_FUNCIONES (
  TIFU_TITU_ID              NUMBER       NOT NULL,
  TIFU_FUNC_ID              NUMBER       NOT NULL,
  TIFU_FECHA_CREACION       DATE         DEFAULT SYSDATE NOT NULL,
  TIFU_USUARIO_CREACION     VARCHAR2(20) NOT NULL,
  
  CONSTRAINT PK_TITULOS_FUNCIONES PRIMARY KEY (TIFU_TITU_ID, TIFU_FUNC_ID),
  CONSTRAINT FK_TIFU_TITULO FOREIGN KEY (TIFU_TITU_ID) 
    REFERENCES BR_TITULOS (TITU_ID) ON DELETE CASCADE,
  CONSTRAINT FK_TIFU_FUNCION FOREIGN KEY (TIFU_FUNC_ID) 
    REFERENCES BR_FUNCIONES (FUNC_ID)
);

COMMENT ON TABLE BR_TITULOS_FUNCIONES IS 'Relación N:M entre títulos y funciones (permisos)';
COMMENT ON COLUMN BR_TITULOS_FUNCIONES.TIFU_TITU_ID IS 'ID del título (FK a BR_TITULOS con DELETE CASCADE)';
COMMENT ON COLUMN BR_TITULOS_FUNCIONES.TIFU_FUNC_ID IS 'ID de la función (FK a BR_FUNCIONES)';
COMMENT ON COLUMN BR_TITULOS_FUNCIONES.TIFU_FECHA_CREACION IS 'Fecha de creación de la relación';
COMMENT ON COLUMN BR_TITULOS_FUNCIONES.TIFU_USUARIO_CREACION IS 'RUT del usuario que creó la relación';


-- ===========================================================================
-- TABLA: BR_USUARIO_GRUPO
-- Descripción: Asignación de usuarios a grupos con vigencias
-- ===========================================================================

CREATE TABLE BR_USUARIO_GRUPO (
  USGR_RELA_RUT             VARCHAR2(20) NOT NULL,
  USGR_GRUP_ID              NUMBER       NOT NULL,
  USGR_FECHA_INICIO         DATE         NOT NULL,
  USGR_FECHA_FIN            DATE         NULL,
  USGR_ACTIVO               VARCHAR2(1)  DEFAULT 'S' NOT NULL,
  USGR_FECHA_CREACION       DATE         DEFAULT SYSDATE NOT NULL,
  USGR_USUARIO_CREACION     VARCHAR2(20) NOT NULL,
  
  CONSTRAINT PK_USUARIO_GRUPO PRIMARY KEY (USGR_RELA_RUT, USGR_GRUP_ID, USGR_FECHA_INICIO),
  CONSTRAINT FK_USGR_RELACIONADO FOREIGN KEY (USGR_RELA_RUT) 
    REFERENCES BR_RELACIONADOS (RELA_RUT),
  CONSTRAINT FK_USGR_GRUPO FOREIGN KEY (USGR_GRUP_ID) 
    REFERENCES BR_GRUPOS (GRUP_ID),
  CONSTRAINT CK_USGR_ACTIVO CHECK (USGR_ACTIVO IN ('S', 'N')),
  CONSTRAINT CK_USGR_FECHAS CHECK (USGR_FECHA_FIN IS NULL OR USGR_FECHA_FIN >= USGR_FECHA_INICIO)
);

COMMENT ON TABLE BR_USUARIO_GRUPO IS 'Asignación de usuarios (BR_RELACIONADOS) a grupos con vigencias';
COMMENT ON COLUMN BR_USUARIO_GRUPO.USGR_RELA_RUT IS 'RUT del usuario (FK a BR_RELACIONADOS, formato XX.XXX.XXX-X)';
COMMENT ON COLUMN BR_USUARIO_GRUPO.USGR_GRUP_ID IS 'ID del grupo (FK a BR_GRUPOS)';
COMMENT ON COLUMN BR_USUARIO_GRUPO.USGR_FECHA_INICIO IS 'Fecha de inicio de la asignación (parte de PK)';
COMMENT ON COLUMN BR_USUARIO_GRUPO.USGR_FECHA_FIN IS 'Fecha de fin de la asignación (NULL si vigencia indefinida)';
COMMENT ON COLUMN BR_USUARIO_GRUPO.USGR_ACTIVO IS 'Estado de la asignación (S=Activo, N=Inactivo)';
COMMENT ON COLUMN BR_USUARIO_GRUPO.USGR_FECHA_CREACION IS 'Fecha de creación del registro';
COMMENT ON COLUMN BR_USUARIO_GRUPO.USGR_USUARIO_CREACION IS 'RUT del usuario que creó el registro';


-- ===========================================================================
-- TABLA: BR_USUARIO_GRUPO_ORDEN
-- Descripción: Orden de prioridad de grupos para un usuario
-- ===========================================================================

CREATE TABLE BR_USUARIO_GRUPO_ORDEN (
  USGO_RELA_RUT             VARCHAR2(20) NOT NULL,
  USGO_GRUP_ID              NUMBER       NOT NULL,
  USGO_ORDEN                NUMBER       DEFAULT 1 NOT NULL,
  USGO_FECHA_MODIFICACION   DATE         DEFAULT SYSDATE NOT NULL,
  USGO_USUARIO_MODIFICACION VARCHAR2(20) NOT NULL,
  
  CONSTRAINT PK_USUARIO_GRUPO_ORDEN PRIMARY KEY (USGO_RELA_RUT, USGO_GRUP_ID),
  CONSTRAINT FK_USGO_RELACIONADO FOREIGN KEY (USGO_RELA_RUT) 
    REFERENCES BR_RELACIONADOS (RELA_RUT),
  CONSTRAINT FK_USGO_GRUPO FOREIGN KEY (USGO_GRUP_ID) 
    REFERENCES BR_GRUPOS (GRUP_ID),
  CONSTRAINT UK_USGO_USUARIO_ORDEN UNIQUE (USGO_RELA_RUT, USGO_ORDEN),
  CONSTRAINT CK_USGO_ORDEN CHECK (USGO_ORDEN > 0)
);

COMMENT ON TABLE BR_USUARIO_GRUPO_ORDEN IS 'Orden de prioridad de grupos para cada usuario (drag-and-drop en UI)';
COMMENT ON COLUMN BR_USUARIO_GRUPO_ORDEN.USGO_RELA_RUT IS 'RUT del usuario (FK a BR_RELACIONADOS)';
COMMENT ON COLUMN BR_USUARIO_GRUPO_ORDEN.USGO_GRUP_ID IS 'ID del grupo (FK a BR_GRUPOS)';
COMMENT ON COLUMN BR_USUARIO_GRUPO_ORDEN.USGO_ORDEN IS 'Orden de prioridad (1=mayor prioridad, único por usuario)';
COMMENT ON COLUMN BR_USUARIO_GRUPO_ORDEN.USGO_FECHA_MODIFICACION IS 'Fecha de última modificación del orden';
COMMENT ON COLUMN BR_USUARIO_GRUPO_ORDEN.USGO_USUARIO_MODIFICACION IS 'RUT del usuario que modificó el orden';


-- ===========================================================================
-- INDEXES
-- ===========================================================================

-- Índice para búsqueda de grupos por vigencia
CREATE INDEX IDX_GRUPOS_VIGENTE ON BR_GRUPOS (GRUP_VIGENTE);

-- Índice para búsqueda de grupos por nombre (case-insensitive)
CREATE INDEX IDX_GRUPOS_NOMBRE_UPPER ON BR_GRUPOS (UPPER(GRUP_NOMBRE));

-- Índice para búsqueda de títulos por grupo
CREATE INDEX IDX_TITULOS_GRUPO ON BR_TITULOS (TITU_GRUP_ID);

-- Índice para búsqueda de funciones por título
CREATE INDEX IDX_TIFU_TITULO ON BR_TITULOS_FUNCIONES (TIFU_TITU_ID);

-- Índice para búsqueda de títulos por función (queries inversas)
CREATE INDEX IDX_TIFU_FUNCION ON BR_TITULOS_FUNCIONES (TIFU_FUNC_ID);

-- Índice para búsqueda de asignaciones por grupo
CREATE INDEX IDX_USGR_GRUPO ON BR_USUARIO_GRUPO (USGR_GRUP_ID);

-- Índice para búsqueda de asignaciones activas
CREATE INDEX IDX_USGR_ACTIVO ON BR_USUARIO_GRUPO (USGR_ACTIVO);


-- ===========================================================================
-- GRANTS (opcional, según permisos del schema)
-- ===========================================================================

-- GRANT SELECT, INSERT, UPDATE, DELETE ON BR_GRUPOS TO ROLE_ADMIN;
-- GRANT SELECT, INSERT, UPDATE, DELETE ON BR_TITULOS TO ROLE_ADMIN;
-- GRANT SELECT, INSERT, UPDATE, DELETE ON BR_TITULOS_FUNCIONES TO ROLE_ADMIN;
-- GRANT SELECT, INSERT, UPDATE, DELETE ON BR_USUARIO_GRUPO TO ROLE_ADMIN;
-- GRANT SELECT, INSERT, UPDATE, DELETE ON BR_USUARIO_GRUPO_ORDEN TO ROLE_ADMIN;

-- GRANT SELECT ON SEQ_GRUPO_ID TO ROLE_ADMIN;
-- GRANT SELECT ON SEQ_TITULO_ID TO ROLE_ADMIN;


-- ===========================================================================
-- VERIFICACIÓN DE ESTRUCTURA
-- ===========================================================================

-- Verificar tablas creadas
SELECT table_name FROM user_tables 
WHERE table_name IN ('BR_GRUPOS', 'BR_TITULOS', 'BR_TITULOS_FUNCIONES', 
                     'BR_USUARIO_GRUPO', 'BR_USUARIO_GRUPO_ORDEN')
ORDER BY table_name;

-- Verificar secuencias creadas
SELECT sequence_name FROM user_sequences 
WHERE sequence_name IN ('SEQ_GRUPO_ID', 'SEQ_TITULO_ID')
ORDER BY sequence_name;

-- Verificar constraints (foreign keys)
SELECT constraint_name, constraint_type, table_name
FROM user_constraints
WHERE table_name IN ('BR_GRUPOS', 'BR_TITULOS', 'BR_TITULOS_FUNCIONES', 
                     'BR_USUARIO_GRUPO', 'BR_USUARIO_GRUPO_ORDEN')
ORDER BY table_name, constraint_type;

-- Verificar índices creados
SELECT index_name, table_name, uniqueness
FROM user_indexes
WHERE table_name IN ('BR_GRUPOS', 'BR_TITULOS', 'BR_TITULOS_FUNCIONES', 
                     'BR_USUARIO_GRUPO', 'BR_USUARIO_GRUPO_ORDEN')
ORDER BY table_name, index_name;


-- ===========================================================================
-- DATOS DE PRUEBA (opcional, para desarrollo)
-- ===========================================================================

-- INSERT INTO BR_GRUPOS (GRUP_ID, GRUP_NOMBRE, GRUP_VIGENTE, GRUP_USUARIO_CREACION)
-- VALUES (SEQ_GRUPO_ID.NEXTVAL, 'Sistema OT', 'S', '12.345.678-9');

-- INSERT INTO BR_TITULOS (TITU_ID, TITU_GRUP_ID, TITU_NOMBRE, TITU_ORDEN, TITU_USUARIO_CREACION)
-- VALUES (SEQ_TITULO_ID.NEXTVAL, 1, 'Reportes', 1, '12.345.678-9');

-- INSERT INTO BR_TITULOS_FUNCIONES (TIFU_TITU_ID, TIFU_FUNC_ID, TIFU_USUARIO_CREACION)
-- VALUES (1, 15, '12.345.678-9');

-- COMMIT;


-- ===========================================================================
-- ROLLBACK (solo para desarrollo)
-- ===========================================================================

-- DROP TABLE BR_USUARIO_GRUPO_ORDEN CASCADE CONSTRAINTS;
-- DROP TABLE BR_USUARIO_GRUPO CASCADE CONSTRAINTS;
-- DROP TABLE BR_TITULOS_FUNCIONES CASCADE CONSTRAINTS;
-- DROP TABLE BR_TITULOS CASCADE CONSTRAINTS;
-- DROP TABLE BR_GRUPOS CASCADE CONSTRAINTS;
-- DROP SEQUENCE SEQ_TITULO_ID;
-- DROP SEQUENCE SEQ_GRUPO_ID;
