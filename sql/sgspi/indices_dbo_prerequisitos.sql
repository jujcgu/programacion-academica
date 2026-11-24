-- ==================================================================================================
-- ÍNDICES PRERREQUISITO EN [dbo] PARA EL ESQUEMA [sgspi] (DDL v2.2)
-- ==================================================================================================
-- Ejecutar ANTES o DESPUÉS de DDL_SGSPI_SQLSERVER2019_v2.sql (fuera de su transacción única).
-- Motivo:
--   - sgspi.ufn_persona_sesion() busca ORIGINAL_LOGIN() en la columna [sys] de
--     [dbo].[usuario_administrativos] y [dbo].[usuario_docentes] en cada INSERT, UPDATE y lectura RLS.
--   - [dbo].[usuario_grupo](usg_usuario) ya cuenta con [ind_usuario_grupo] en academia3000, pero se
--     incluye una verificación idempotente por seguridad.
--   - Sin filtro (has_filter = 0) para cumplir la verificación de la sección 7 del DDL y permitir
--     Index Seek bajo cualquier configuración de SET options.
-- Nota Standard Edition:
--   - No se incluye ONLINE = ON porque la creación de índices en línea requiere Enterprise Edition;
--     ambas tablas son pequeñas (solo funcionarios y docentes), por lo que el bloqueo dura milisegundos.
-- ==================================================================================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECTPROPERTY(OBJECT_ID(N'dbo.usuario_administrativos'), N'IsUserTable') = 1
   AND NOT EXISTS (SELECT 1
                   FROM   sys.indexes AS ix
                          INNER JOIN
                          sys.index_columns AS ic
                          ON ic.object_id = ix.object_id
                             AND ic.index_id = ix.index_id
                          INNER JOIN
                          sys.columns AS c
                          ON c.object_id = ic.object_id
                             AND c.column_id = ic.column_id
                   WHERE  ix.object_id = OBJECT_ID(N'dbo.usuario_administrativos')
                          AND ix.is_disabled = 0
                          AND ix.has_filter = 0
                          AND ic.key_ordinal = 1
                          AND c.name = N'sys')
BEGIN
    CREATE NONCLUSTERED INDEX IX_usuario_administrativos_sys
        ON dbo.usuario_administrativos (sys)
        INCLUDE (uid, up, state);
END;
GO

IF OBJECTPROPERTY(OBJECT_ID(N'dbo.usuario_docentes'), N'IsUserTable') = 1
   AND NOT EXISTS (SELECT 1
                   FROM   sys.indexes AS ix
                          INNER JOIN
                          sys.index_columns AS ic
                          ON ic.object_id = ix.object_id
                             AND ic.index_id = ix.index_id
                          INNER JOIN
                          sys.columns AS c
                          ON c.object_id = ic.object_id
                             AND c.column_id = ic.column_id
                   WHERE  ix.object_id = OBJECT_ID(N'dbo.usuario_docentes')
                          AND ix.is_disabled = 0
                          AND ix.has_filter = 0
                          AND ic.key_ordinal = 1
                          AND c.name = N'sys')
BEGIN
    CREATE NONCLUSTERED INDEX IX_usuario_docentes_sys
        ON dbo.usuario_docentes (sys)
        INCLUDE (uid, up, state);
END;
GO

IF OBJECTPROPERTY(OBJECT_ID(N'dbo.usuario_grupo'), N'IsUserTable') = 1
   AND NOT EXISTS (SELECT 1
                   FROM   sys.indexes AS ix
                          INNER JOIN
                          sys.index_columns AS ic
                          ON ic.object_id = ix.object_id
                             AND ic.index_id = ix.index_id
                          INNER JOIN
                          sys.columns AS c
                          ON c.object_id = ic.object_id
                             AND c.column_id = ic.column_id
                   WHERE  ix.object_id = OBJECT_ID(N'dbo.usuario_grupo')
                          AND ix.is_disabled = 0
                          AND ix.has_filter = 0
                          AND ic.key_ordinal = 1
                          AND c.name = N'usg_usuario')
BEGIN
    CREATE NONCLUSTERED INDEX IX_usuario_grupo_usg_usuario
        ON dbo.usuario_grupo (usg_usuario)
        INCLUDE (usg_grupo, usg_uaa, usg_estado);
END;
GO
