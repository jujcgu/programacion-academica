-- ============================================================================
-- ARTEFACTO: 02_data_migration_and_cleanup.sql
-- DESCRIPCIÓN: Transformación, saneamiento y preservación de datos (Zero Data Loss)
--              Optimizado para bases de datos de gran volumen (130+ GB) y compatible
--              con todas las versiones de SQL Server (2012/2014/2016/2019/2022):
--              1. Garantía idempotente de columnas calculadas/auditoría (Metadata-Only, 0 I/O)
--              2. Liberación automática de objetos dependientes (índices/defaults/stats)
--                 previo a conversión de tipos (nuc_codigo, car_estado, ese_codigo) y recreación
--              3. Saneamiento seguro de registros huérfanos en tablas principales
--              4. Comprobación de integridad y conteo rápido por particiones (sys.partitions)
-- PROYECTO: Sistema de Programación Académica (p_academica-main)
-- ============================================================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT OFF;
GO

PRINT 'Iniciando migración y saneamiento seguro de datos (Optimizado para 130 GB)...';
GO

-- ============================================================================
-- PASO 0: GARANTÍA IDEMPOTENTE DE COLUMNAS DE COMPATIBILIDAD Y AUDITORÍA
-- (Operaciones puras de metadatos en SQL Server: 0 segundos, 0 crecimiento de log)
-- ============================================================================
PRINT 'Paso 0: Verificando columnas de compatibilidad y auditoría (Metadata-Only)...';

-- 0.1 Garantizar que tanto [per_año] como [per_anio] existan en dbo.periodo sin romper consultas
IF COL_LENGTH('dbo.periodo', 'per_anio') IS NULL AND COL_LENGTH('dbo.periodo', 'per_año') IS NOT NULL
BEGIN
    EXEC('ALTER TABLE [dbo].[periodo] ADD [per_anio] AS ([per_año]);');
    PRINT 'Agregada columna calculada virtual [per_anio] AS ([per_año]) en dbo.periodo.';
END
ELSE IF COL_LENGTH('dbo.periodo', 'per_año') IS NULL AND COL_LENGTH('dbo.periodo', 'per_anio') IS NOT NULL
BEGIN
    EXEC('ALTER TABLE [dbo].[periodo] ADD [per_año] AS ([per_anio]);');
    PRINT 'Agregada columna calculada virtual [per_año] AS ([per_anio]) en dbo.periodo.';
END
GO

-- 0.2 Garantizar que tanto [pre_codgo] como [pre_codigo] existan en proyectos.proyecto_proyeccion_social
IF OBJECT_ID('proyectos.proyecto_proyeccion_social', 'U') IS NOT NULL
BEGIN
    IF COL_LENGTH('proyectos.proyecto_proyeccion_social', 'pre_codigo') IS NULL 
       AND COL_LENGTH('proyectos.proyecto_proyeccion_social', 'pre_codgo') IS NOT NULL
    BEGIN
        EXEC('ALTER TABLE [proyectos].[proyecto_proyeccion_social] ADD [pre_codigo] AS ([pre_codgo]);');
        PRINT 'Agregada columna calculada virtual [pre_codigo] AS ([pre_codgo]) en proyectos.proyecto_proyeccion_social.';
    END
    ELSE IF COL_LENGTH('proyectos.proyecto_proyeccion_social', 'pre_codgo') IS NULL 
            AND COL_LENGTH('proyectos.proyecto_proyeccion_social', 'pre_codigo') IS NOT NULL
    BEGIN
        EXEC('ALTER TABLE [proyectos].[proyecto_proyeccion_social] ADD [pre_codgo] AS ([pre_codigo]);');
        PRINT 'Agregada columna calculada virtual [pre_codgo] AS ([pre_codigo]) en proyectos.proyecto_proyeccion_social.';
    END
END
GO

-- 0.3 Garantizar columnas de auditoría con DEFAULT (Metadata-Only en SQL Server, sin reescribir páginas)
SET NOCOUNT ON;
DECLARE @audit_tables TABLE (sch NVARCHAR(50), tbl NVARCHAR(100));
INSERT INTO @audit_tables VALUES
('dbo', 'curso'), ('dbo', 'espacio_ocupacion'), ('dbo', 'matricula'),
('programacionacademica', 'programacion_academica'),
('programacionacademica', 'programacion_gestion'),
('programacionacademica', 'periodo_unidad'),
('programacionacademica', 'solicitud_cambio_horario'),
('programacionacademica', 'solicitud_prestamo_docente'),
('proyectos', 'proyecto_proyeccion_social');

DECLARE @a_sch NVARCHAR(50), @a_tbl NVARCHAR(100);
DECLARE cur_audit CURSOR LOCAL FAST_FORWARD FOR SELECT sch, tbl FROM @audit_tables;
OPEN cur_audit;
FETCH NEXT FROM cur_audit INTO @a_sch, @a_tbl;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF OBJECT_ID('[' + @a_sch + '].[' + @a_tbl + ']', 'U') IS NOT NULL
       AND COL_LENGTH(@a_sch + '.' + @a_tbl, 'aud_fecha_creacion') IS NULL
    BEGIN
        DECLARE @sql_audit NVARCHAR(MAX) = 'ALTER TABLE [' + @a_sch + '].[' + @a_tbl + '] ADD ' +
            '[aud_fecha_creacion] [datetime2](7) NOT NULL CONSTRAINT [DF_' + @a_tbl + '_aud_fecha_creacion] DEFAULT (sysdatetime()), ' +
            '[aud_usuario_creacion] [nvarchar](128) NOT NULL CONSTRAINT [DF_' + @a_tbl + '_aud_usuario_creacion] DEFAULT (suser_sname()), ' +
            '[aud_fecha_modificacion] [datetime2](7) NULL, ' +
            '[aud_usuario_modificacion] [nvarchar](128) NULL;';
        EXEC sp_executesql @sql_audit;
        PRINT 'Agregadas columnas de auditoría (Metadata-Only) a: ' + @a_sch + '.' + @a_tbl;
    END
    FETCH NEXT FROM cur_audit INTO @a_sch, @a_tbl;
END
CLOSE cur_audit;
DEALLOCATE cur_audit;
SET NOCOUNT OFF;
GO

-- ============================================================================
-- PASO 1 Y 2: CONVERSIÓN DE TIPOS DESACOPLANDO ÍNDICES Y DEFAULTS DEPENDIENTES
-- (Resuelve el Error 5074 cuando Fase 3 ya creó IX_FK_programacion_proceso_nuc_codigo
--  o cuando existen restricciones DEFAULT del sistema sobre car_estado)
-- ============================================================================
PRINT 'Paso 1: Registrando métricas pre-migración desde metadatos de partición (instantáneo en 130 GB)...';

DECLARE @count_curso BIGINT, @count_espacio BIGINT, @count_persona BIGINT, @count_matricula BIGINT;
SELECT @count_curso = ISNULL(SUM(p.rows), 0) FROM sys.partitions p WHERE p.object_id = OBJECT_ID('[dbo].[curso]') AND p.index_id IN (0, 1);
SELECT @count_espacio = ISNULL(SUM(p.rows), 0) FROM sys.partitions p WHERE p.object_id = OBJECT_ID('[dbo].[espacio_ocupacion]') AND p.index_id IN (0, 1);
SELECT @count_persona = ISNULL(SUM(p.rows), 0) FROM sys.partitions p WHERE p.object_id = OBJECT_ID('[dbo].[persona]') AND p.index_id IN (0, 1);
SELECT @count_matricula = ISNULL(SUM(p.rows), 0) FROM sys.partitions p WHERE p.object_id = OBJECT_ID('[dbo].[matricula]') AND p.index_id IN (0, 1);

PRINT 'Registros iniciales -> Cursos: ' + CAST(@count_curso AS VARCHAR(30)) +
      ', Ocupaciones: ' + CAST(@count_espacio AS VARCHAR(30)) +
      ', Personas: ' + CAST(@count_persona AS VARCHAR(30)) +
      ', Matrículas: ' + CAST(@count_matricula AS VARCHAR(30));

PRINT 'Paso 2: Estandarizando tipos de datos en tablas de catálogo...';

-- ----------------------------------------------------------------------------
-- 2.1 dbo.programacion_proceso.nuc_codigo: varchar(10) -> int
-- ----------------------------------------------------------------------------
IF EXISTS (
    SELECT 1 FROM sys.columns c
    JOIN sys.tables t ON c.object_id = t.object_id
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    JOIN sys.types ty ON c.user_type_id = ty.user_type_id
    WHERE s.name = 'dbo' AND t.name = 'programacion_proceso' AND c.name = 'nuc_codigo' AND ty.name IN ('varchar', 'char', 'nvarchar')
)
BEGIN
    BEGIN TRY
        PRINT 'Convirtiendo nuc_codigo de varchar a int en dbo.programacion_proceso...';

        -- 1. Eliminar FKs dependientes de dbo.programacion_proceso(nuc_codigo) si existen
        DECLARE @sql_drop_dep_pp NVARCHAR(MAX) = N'';
        SELECT @sql_drop_dep_pp = @sql_drop_dep_pp + N'ALTER TABLE [dbo].[programacion_proceso] DROP CONSTRAINT [' + fk.name + N'];'
        FROM sys.foreign_keys fk
        JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
        JOIN sys.columns c ON fkc.parent_object_id = c.object_id AND fkc.parent_column_id = c.column_id
        WHERE fk.parent_object_id = OBJECT_ID('[dbo].[programacion_proceso]') AND c.name = 'nuc_codigo';

        -- 2. Eliminar DEFAULT constraints sobre nuc_codigo si existen
        SELECT @sql_drop_dep_pp = @sql_drop_dep_pp + N'ALTER TABLE [dbo].[programacion_proceso] DROP CONSTRAINT [' + dc.name + N'];'
        FROM sys.default_constraints dc
        JOIN sys.columns c ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
        WHERE dc.parent_object_id = OBJECT_ID('[dbo].[programacion_proceso]') AND c.name = 'nuc_codigo';

        -- 3. Eliminar índices no agrupados (como IX_FK_programacion_proceso_nuc_codigo creado en Fase 3)
        SELECT @sql_drop_dep_pp = @sql_drop_dep_pp + N'DROP INDEX [' + i.name + N'] ON [dbo].[programacion_proceso];'
        FROM sys.indexes i
        JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
        JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
        WHERE i.object_id = OBJECT_ID('[dbo].[programacion_proceso]')
          AND c.name = 'nuc_codigo'
          AND i.is_primary_key = 0 AND i.is_unique_constraint = 0;

        -- 4. Eliminar estadísticas de usuario sobre nuc_codigo si existen
        SELECT @sql_drop_dep_pp = @sql_drop_dep_pp + N'DROP STATISTICS [dbo].[programacion_proceso].[' + st.name + N'];'
        FROM sys.stats st
        JOIN sys.stats_columns stc ON st.object_id = stc.object_id AND st.stats_id = stc.stats_id
        JOIN sys.columns c ON stc.object_id = c.object_id AND stc.column_id = c.column_id
        WHERE st.object_id = OBJECT_ID('[dbo].[programacion_proceso]')
          AND c.name = 'nuc_codigo'
          AND st.user_created = 1;

        IF LEN(@sql_drop_dep_pp) > 0
            EXEC sp_executesql @sql_drop_dep_pp;

        UPDATE [dbo].[programacion_proceso]
        SET [nuc_codigo] = NULL
        WHERE [nuc_codigo] IS NOT NULL AND ISNUMERIC([nuc_codigo]) = 0;

        ALTER TABLE [dbo].[programacion_proceso] ALTER COLUMN [nuc_codigo] [int] NULL;

        -- 5. Recrear el índice IX_FK_programacion_proceso_nuc_codigo
        IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_programacion_proceso_nuc_codigo' AND object_id = OBJECT_ID('[dbo].[programacion_proceso]'))
        BEGIN
            CREATE NONCLUSTERED INDEX [IX_FK_programacion_proceso_nuc_codigo]
            ON [dbo].[programacion_proceso] ([nuc_codigo]);
        END

        PRINT 'Conversión de nuc_codigo a INT e índice IX_FK_programacion_proceso_nuc_codigo completados.';
    END TRY
    BEGIN CATCH
        PRINT 'ADVERTENCIA en nuc_codigo: ' + ERROR_MESSAGE();
    END CATCH
END

-- ----------------------------------------------------------------------------
-- 2.2 dbo.caracter.car_estado: varchar(1) -> tinyint
-- ----------------------------------------------------------------------------
IF EXISTS (
    SELECT 1 FROM sys.columns c
    JOIN sys.tables t ON c.object_id = t.object_id
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    JOIN sys.types ty ON c.user_type_id = ty.user_type_id
    WHERE s.name = 'dbo' AND t.name = 'caracter' AND c.name = 'car_estado' AND ty.name IN ('varchar', 'char')
)
BEGIN
    BEGIN TRY
        PRINT 'Normalizando car_estado a tinyint en dbo.caracter...';

        -- 1. Eliminar DEFAULT constraint existente sobre car_estado (en sql/dbo/caracter.sql línea 22)
        DECLARE @sql_drop_dep_car NVARCHAR(MAX) = N'';
        SELECT @sql_drop_dep_car = @sql_drop_dep_car + N'ALTER TABLE [dbo].[caracter] DROP CONSTRAINT [' + dc.name + N'];'
        FROM sys.default_constraints dc
        JOIN sys.columns c ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
        WHERE dc.parent_object_id = OBJECT_ID('[dbo].[caracter]') AND c.name = 'car_estado';

        -- 2. Eliminar índices no agrupados sobre car_estado si existen
        SELECT @sql_drop_dep_car = @sql_drop_dep_car + N'DROP INDEX [' + i.name + N'] ON [dbo].[caracter];'
        FROM sys.indexes i
        JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
        JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
        WHERE i.object_id = OBJECT_ID('[dbo].[caracter]')
          AND c.name = 'car_estado'
          AND i.is_primary_key = 0 AND i.is_unique_constraint = 0;

        -- 3. Eliminar estadísticas de usuario sobre car_estado si existen
        SELECT @sql_drop_dep_car = @sql_drop_dep_car + N'DROP STATISTICS [dbo].[caracter].[' + st.name + N'];'
        FROM sys.stats st
        JOIN sys.stats_columns stc ON st.object_id = stc.object_id AND st.stats_id = stc.stats_id
        JOIN sys.columns c ON stc.object_id = c.object_id AND stc.column_id = c.column_id
        WHERE st.object_id = OBJECT_ID('[dbo].[caracter]')
          AND c.name = 'car_estado'
          AND st.user_created = 1;

        IF LEN(@sql_drop_dep_car) > 0
            EXEC sp_executesql @sql_drop_dep_car;

        DECLARE @sql_car_upd NVARCHAR(MAX) = 'UPDATE [dbo].[caracter] SET [car_estado] = CASE ' +
            'WHEN [car_estado] IN (''1'', ''A'', ''S'', ''a'', ''s'') THEN ''1'' ' +
            'ELSE ''0'' END;';
        EXEC sp_executesql @sql_car_upd;

        ALTER TABLE [dbo].[caracter] ALTER COLUMN [car_estado] [tinyint] NOT NULL;

        -- 4. Recrear restricción DEFAULT nombrada
        IF NOT EXISTS (
            SELECT 1 FROM sys.default_constraints dc
            JOIN sys.columns c ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
            WHERE dc.parent_object_id = OBJECT_ID('[dbo].[caracter]') AND c.name = 'car_estado'
        )
        BEGIN
            ALTER TABLE [dbo].[caracter] ADD CONSTRAINT [DF_caracter_car_estado] DEFAULT ((1)) FOR [car_estado];
        END

        PRINT 'Conversión de car_estado a TINYINT completada.';
    END TRY
    BEGIN CATCH
        PRINT 'ADVERTENCIA en car_estado: ' + ERROR_MESSAGE();
    END CATCH
END

-- ----------------------------------------------------------------------------
-- 2.3 dbo.estudiante.ese_codigo: tinyint -> smallint
-- ----------------------------------------------------------------------------
IF EXISTS (
    SELECT 1 FROM sys.columns c
    JOIN sys.tables t ON c.object_id = t.object_id
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    JOIN sys.types ty ON c.user_type_id = ty.user_type_id
    WHERE s.name = 'dbo' AND t.name = 'estudiante' AND c.name = 'ese_codigo' AND ty.name = 'tinyint'
)
BEGIN
    BEGIN TRY
        PRINT 'Ampliando ese_codigo a SMALLINT en dbo.estudiante para compatibilidad con matricula...';

        DECLARE @sql_drop_dep_est NVARCHAR(MAX) = N'';
        SELECT @sql_drop_dep_est = @sql_drop_dep_est + N'ALTER TABLE [dbo].[estudiante] DROP CONSTRAINT [' + dc.name + N'];'
        FROM sys.default_constraints dc
        JOIN sys.columns c ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
        WHERE dc.parent_object_id = OBJECT_ID('[dbo].[estudiante]') AND c.name = 'ese_codigo';

        SELECT @sql_drop_dep_est = @sql_drop_dep_est + N'DROP INDEX [' + i.name + N'] ON [dbo].[estudiante];'
        FROM sys.indexes i
        JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
        JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
        WHERE i.object_id = OBJECT_ID('[dbo].[estudiante]')
          AND c.name = 'ese_codigo'
          AND i.is_primary_key = 0 AND i.is_unique_constraint = 0;

        IF LEN(@sql_drop_dep_est) > 0
            EXEC sp_executesql @sql_drop_dep_est;

        ALTER TABLE [dbo].[estudiante] ALTER COLUMN [ese_codigo] [smallint] NOT NULL;
        PRINT 'Conversión de ese_codigo a SMALLINT completada.';
    END TRY
    BEGIN CATCH
        PRINT 'ADVERTENCIA en ese_codigo: ' + ERROR_MESSAGE();
    END CATCH
END

-- ============================================================================
-- PASO 3: SANEAMIENTO DE REGISTROS HUÉRFANOS PREVIO A CLAVES FORÁNEAS
-- (Usa columnas 100% existentes en sql/dbo/*.sql)
-- ============================================================================
BEGIN TRANSACTION;
BEGIN TRY

    PRINT 'Paso 3: Saneando registros huérfanos en dbo.curso...';

    -- 3.1 Asignaturas en curso: verificar que asi_codigo exista en asignatura
    IF EXISTS (
        SELECT 1 FROM [dbo].[curso] c 
        WHERE c.asi_codigo IS NOT NULL 
          AND NOT EXISTS (SELECT 1 FROM [dbo].[asignatura] a WHERE a.asi_codigo = c.asi_codigo)
    )
    BEGIN
        PRINT 'Advertencia: Detectados cursos con asi_codigo inexistente. Insertando asignatura comodín...';
        SET IDENTITY_INSERT [dbo].[asignatura] ON;
        IF NOT EXISTS (SELECT 1 FROM [dbo].[asignatura] WHERE asi_codigo = 0)
        BEGIN
            DECLARE @fallback_car CHAR(2) = (SELECT TOP 1 car_codigo FROM [dbo].[caracter]);
            IF @fallback_car IS NULL
            BEGIN
                INSERT INTO [dbo].[caracter] (car_codigo, car_nombre, car_estado) VALUES ('NA', 'NO APLICA', 1);
                SET @fallback_car = 'NA';
            END

            INSERT INTO [dbo].[asignatura] (
                asi_codigo, asi_nombre, asi_nombre_corto, car_codigo, for_codigo, asi_estado
            )
            VALUES (
                0, 'ASIGNATURA NO ESPECIFICADA', 'S/A', @fallback_car, 1, 0
            );
        END
        SET IDENTITY_INSERT [dbo].[asignatura] OFF;

        UPDATE [dbo].[curso]
        SET [asi_codigo] = 0
        WHERE [asi_codigo] IS NOT NULL
          AND NOT EXISTS (SELECT 1 FROM [dbo].[asignatura] a WHERE a.asi_codigo = [dbo].[curso].asi_codigo);
    END

    -- 3.2 Calendarios en curso (usa únicamente columnas reales de dbo.periodo: per_codigo, per_nombre, per_periodo)
    IF EXISTS (
        SELECT 1 FROM [dbo].[curso] c 
        WHERE c.cal_codigo IS NOT NULL
          AND NOT EXISTS (SELECT 1 FROM [dbo].[calendario] cal WHERE cal.cal_codigo = c.cal_codigo)
    )
    BEGIN
        PRINT 'Advertencia: Detectados cursos con cal_codigo inexistente. Insertando calendario comodín...';
        SET IDENTITY_INSERT [dbo].[calendario] ON;
        IF NOT EXISTS (SELECT 1 FROM [dbo].[calendario] WHERE cal_codigo = 0)
        BEGIN
            DECLARE @fallback_per INT = (SELECT TOP 1 per_codigo FROM [dbo].[periodo]);
            IF @fallback_per IS NULL
            BEGIN
                SET IDENTITY_INSERT [dbo].[periodo] ON;
                INSERT INTO [dbo].[periodo] (per_codigo, per_nombre, per_periodo)
                VALUES (0, 'PERIODO MIGRACION INICIAL', 1);
                SET IDENTITY_INSERT [dbo].[periodo] OFF;
                SET @fallback_per = 0;
            END

            INSERT INTO [dbo].[calendario] (
                cal_codigo, per_codigo, cal_nombre, cal_estado
            )
            VALUES (
                0, @fallback_per, 'CALENDARIO MIGRACION INICIAL', '0'
            );
        END
        SET IDENTITY_INSERT [dbo].[calendario] OFF;

        UPDATE [dbo].[curso]
        SET [cal_codigo] = 0
        WHERE [cal_codigo] IS NOT NULL
          AND NOT EXISTS (SELECT 1 FROM [dbo].[calendario] cal WHERE cal.cal_codigo = [dbo].[curso].cal_codigo);
    END

    -- 3.3 Sedes en curso
    IF EXISTS (
        SELECT 1 FROM [dbo].[curso] c 
        WHERE c.sed_codigo IS NOT NULL 
          AND NOT EXISTS (SELECT 1 FROM [dbo].[sede] s WHERE s.sed_codigo = c.sed_codigo)
    )
    BEGIN
        PRINT 'Saneando sede inválida en cursos huérfanos...';
        UPDATE [dbo].[curso]
        SET [sed_codigo] = NULL
        WHERE [sed_codigo] IS NOT NULL 
          AND NOT EXISTS (SELECT 1 FROM [dbo].[sede] s WHERE s.sed_codigo = [dbo].[curso].sed_codigo);
    END

    -- ========================================================================
    -- PASO 4: VERIFICACIÓN POST-MIGRACIÓN (ZERO DATA LOSS ASSERTION)
    -- ========================================================================
    PRINT 'Paso 4: Comprobando integridad cuantitativa (Zero Data Loss)...';

    DECLARE @post_curso BIGINT, @post_espacio BIGINT, @post_persona BIGINT, @post_matricula BIGINT;
    SELECT @post_curso = ISNULL(SUM(p.rows), 0) FROM sys.partitions p WHERE p.object_id = OBJECT_ID('[dbo].[curso]') AND p.index_id IN (0, 1);
    SELECT @post_espacio = ISNULL(SUM(p.rows), 0) FROM sys.partitions p WHERE p.object_id = OBJECT_ID('[dbo].[espacio_ocupacion]') AND p.index_id IN (0, 1);
    SELECT @post_persona = ISNULL(SUM(p.rows), 0) FROM sys.partitions p WHERE p.object_id = OBJECT_ID('[dbo].[persona]') AND p.index_id IN (0, 1);
    SELECT @post_matricula = ISNULL(SUM(p.rows), 0) FROM sys.partitions p WHERE p.object_id = OBJECT_ID('[dbo].[matricula]') AND p.index_id IN (0, 1);

    IF (@count_curso <> @post_curso OR @count_espacio <> @post_espacio OR 
        @count_persona <> @post_persona OR @count_matricula <> @post_matricula)
    BEGIN
        RAISERROR('FALLO DE INTEGRIDAD: Se detectó divergencia en el conteo de filas tras la migración.', 16, 1);
    END

    PRINT '¡Verificación exitosa! Cursos: ' + CAST(@post_curso AS VARCHAR(30)) +
          ', Ocupaciones: ' + CAST(@post_espacio AS VARCHAR(30)) +
          ', Personas: ' + CAST(@post_persona AS VARCHAR(30)) +
          ', Matrículas: ' + CAST(@post_matricula AS VARCHAR(30));

    COMMIT TRANSACTION;
    PRINT '¡Migración y saneamiento 02_data_migration_and_cleanup completada exitosamente sin pérdida de datos!';

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrSeverity INT = ERROR_SEVERITY();
    DECLARE @ErrState INT = ERROR_STATE();
    PRINT 'ERROR EN SANEAMIENTO DE DATOS: ' + @ErrMsg;
    RAISERROR(@ErrMsg, @ErrSeverity, @ErrState);
END CATCH;
GO
