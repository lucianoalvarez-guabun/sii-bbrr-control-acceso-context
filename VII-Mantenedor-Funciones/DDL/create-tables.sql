-- ===========================================================================
-- MÓDULO VII: MANTENEDOR DE FUNCIONES
-- ===========================================================================
-- Schema: AVAL
-- Oracle: 19c
--
-- TABLAS BASE EXISTENTES:
--   - BR_FUNCIONES
--   - BR_OPCIONES_FUNCION (SIN campo ORDEN)
--   - BR_ATRIBUCIONES
--   - BR_ATRIBUCIONES_OPCION_FUNCION
--   - BR_FUNCIONES_CARGO_RELACIONADO
--
-- Ver modelo completo: /docs/develop-plan/DDL/MODELO-ORACLE-REAL.sql
-- ===========================================================================

-- ===========================================================================
-- EXTENSIÓN: BR_OPCIONES_EXTENSION
-- ===========================================================================
-- PROPÓSITO: Extensión flexible para BR_OPCIONES_FUNCION
-- USOS:
--   - ORDEN: drag-and-drop (HdU-010)
--   - STATIC_CODE: códigos estáticos para referencias en código
-- ===========================================================================

CREATE TABLE AVAL.BR_OPCIONES_EXTENSION (
    FUNS_CODIGO         NUMBER(3)       NOT NULL,
    OPCI_CODIGO         NUMBER(4)       NOT NULL,
    ORDEN               NUMBER          DEFAULT 999 NOT NULL,
    STATIC_CODE         VARCHAR2(50)    NULL,
    FECHA_CREACION      DATE            DEFAULT SYSDATE NOT NULL,
    FECHA_ACTUALIZACION DATE            DEFAULT SYSDATE NOT NULL,
    
    CONSTRAINT PK_BR_OPCIONES_EXTENSION PRIMARY KEY (FUNS_CODIGO, OPCI_CODIGO),
    CONSTRAINT FK_BR_OPC_EXT_FUNS FOREIGN KEY (FUNS_CODIGO)
        REFERENCES AVAL.BR_FUNCIONES(FUNS_CODIGO),
    CONSTRAINT FK_BR_OPC_EXT_OPCI FOREIGN KEY (OPCI_CODIGO)
        REFERENCES AVAL.BR_OPCIONES(OPCI_CODIGO)
);

COMMENT ON TABLE AVAL.BR_OPCIONES_EXTENSION IS 'Extensión para campos adicionales de BR_OPCIONES_FUNCION';
COMMENT ON COLUMN AVAL.BR_OPCIONES_EXTENSION.FUNS_CODIGO IS 'Código de la función';
COMMENT ON COLUMN AVAL.BR_OPCIONES_EXTENSION.OPCI_CODIGO IS 'Código de la opción';
COMMENT ON COLUMN AVAL.BR_OPCIONES_EXTENSION.ORDEN IS 'Orden de visualización (menor = primero)';
COMMENT ON COLUMN AVAL.BR_OPCIONES_EXTENSION.STATIC_CODE IS 'Código estático para referencia en código';
COMMENT ON COLUMN AVAL.BR_OPCIONES_EXTENSION.FECHA_CREACION IS 'Fecha creación registro';
COMMENT ON COLUMN AVAL.BR_OPCIONES_EXTENSION.FECHA_ACTUALIZACION IS 'Fecha última actualización';

CREATE INDEX IDX_BR_OPC_EXT_ORDEN ON AVAL.BR_OPCIONES_EXTENSION(FUNS_CODIGO, ORDEN);
CREATE INDEX IDX_BR_OPC_EXT_CODE ON AVAL.BR_OPCIONES_EXTENSION(STATIC_CODE);

-- ===========================================================================
-- QUERY DE INTEGRACIÓN (para backend)
-- ===========================================================================
-- Obtener opciones con extensión (orden + código estático):
/*
SELECT 
    of.FUNS_CODIGO,
    of.OPCI_CODIGO,
    of.TIPO_ACCESO,
    o.OPCI_NOMBRE,
    o.OPCI_DESCRIPCION,
    COALESCE(ext.ORDEN, 999) as ORDEN,
    ext.STATIC_CODE
FROM BR_OPCIONES_FUNCION of
INNER JOIN BR_OPCIONES o ON of.OPCI_CODIGO = o.OPCI_CODIGO
LEFT JOIN BR_OPCIONES_EXTENSION ext 
    ON of.FUNS_CODIGO = ext.FUNS_CODIGO 
    AND of.OPCI_CODIGO = ext.OPCI_CODIGO
WHERE of.FUNS_CODIGO = :funcionCodigo
ORDER BY COALESCE(ext.ORDEN, 999), o.OPCI_NOMBRE;
*/
