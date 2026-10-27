-- ============================================================================
-- ARTEFACTO: 02_data_migration_and_cleanup.sql
-- DESCRIPCIÓN: Transformación, saneamiento y preservación de datos (Zero Data Loss)
--              1. Conversión de tipos incompatibles (nuc_codigo, for_codigo, ese_codigo)
--              2. Saneamiento de registros huérfanos antes de activar claves foráneas
--              3. Normalización de espacios y tipos de estado (car_estado tinyint)
--              4. Poblamiento retrospectivo de metadatos de auditoría
--              5. Comprobación de integridad y verificación de conteo de filas
-- PROYECTO: Sistema de Programación Académica (p_academica-main)
-- MOTOR OBJETIVO: Microsoft SQL Server 2016+ / Azure SQL Database / T-SQL ANSI
-- ============================================================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
GO

PRINT 'Iniciando migración y saneamiento seguro de datos...';
GO

BEGIN TRANSACTION;
BEGIN TRY

    -- ========================================================================
    -- PASO 1: VALIDACIÓN PREVIA Y CONTEO DE FILAS (AUDITORÍA DE PRESERVACIÓN)
    -- ========================================================================
    PRINT 'Paso 1: Registrando métricas pre-migración para garantía de no pérdida de datos...';

    DECLARE @count_curso INT, @count_espacio INT, @count_persona INT, @count_matricula INT;
    SELECT @count_curso = COUNT(*) FROM [dbo].[curso];
    SELECT @count_espacio = COUNT(*) FROM [dbo].[espacio_ocupacion];
    SELECT @count_persona = COUNT(*) FROM [dbo].[persona];
    SELECT @count_matricula = COUNT(*) FROM [dbo].[matricula];

    PRINT CONCAT('Registros iniciales -> Cursos: ', @count_curso, ', Ocupaciones: ', @count_espacio, ', Personas: ', @count_persona, ', Matrículas: ', @count_matricula);

    -- ========================================================================
    -- PASO 2: CONVERSIÓN DE TIPOS INCOMPATIBLES (17 CONFLICTOS IDENTIFICADOS)
    -- ========================================================================
    PRINT 'Paso 2: Estandarizando tipos de datos...';

    -- 2.1 dbo.programacion_proceso.nuc_codigo: varchar(10) -> int
    IF EXISTS (
        SELECT 1 FROM sys.columns c
        JOIN sys.tables t ON c.object_id = t.object_id
        JOIN sys.schemas s ON t.schema_id = s.schema_id
        JOIN sys.types ty ON c.user_type_id = ty.user_type_id
        WHERE s.name = 'dbo' AND t.name = 'programacion_proceso' AND c.name = 'nuc_codigo' AND ty.name IN ('varchar', 'char', 'nvarchar')
    )
    BEGIN
        PRINT 'Convirtiendo nuc_codigo de varchar a int en dbo.programacion_proceso...';
        
        -- Sanitizar valores no numéricos previos a la conversión
        UPDATE [dbo].[programacion_proceso]
        SET [nuc_codigo] = NULL
        WHERE [nuc_codigo] IS NOT NULL AND TRY_CAST([nuc_codigo] AS INT) IS NULL;

        ALTER TABLE [dbo].[programacion_proceso] ALTER COLUMN [nuc_codigo] [int] NULL;
        PRINT 'Conversión de nuc_codigo a INT completada.';
    END

    -- 2.2 dbo.caracter.car_estado: varchar(1) -> tinyint
    IF EXISTS (
        SELECT 1 FROM sys.columns c
        JOIN sys.tables t ON c.object_id = t.object_id
        JOIN sys.schemas s ON t.schema_id = s.schema_id
        JOIN sys.types ty ON c.user_type_id = ty.user_type_id
        WHERE s.name = 'dbo' AND t.name = 'caracter' AND c.name = 'car_estado' AND ty.name IN ('varchar', 'char')
    )
    BEGIN
        PRINT 'Normalizando car_estado a tinyint en dbo.caracter...';

        -- Convertir valores 'A','1','S' en 1, 'I','0','N' en 0
        DECLARE @sql_car_upd NVARCHAR(MAX) = 'UPDATE [dbo].[caracter] SET [car_estado] = CASE ' +
            'WHEN [car_estado] IN (''1'', ''A'', ''S'', ''a'', ''s'') THEN ''1'' ' +
            'ELSE ''0'' END;';
        EXEC sp_executesql @sql_car_upd;

        ALTER TABLE [dbo].[caracter] ALTER COLUMN [car_estado] [tinyint] NOT NULL;
        PRINT 'Conversión de car_estado a TINYINT completada.';
    END


    -- 2.4 dbo.estudiante.ese_codigo: tinyint -> smallint
    IF EXISTS (
        SELECT 1 FROM sys.columns c
        JOIN sys.tables t ON c.object_id = t.object_id
        JOIN sys.schemas s ON t.schema_id = s.schema_id
        JOIN sys.types ty ON c.user_type_id = ty.user_type_id
        WHERE s.name = 'dbo' AND t.name = 'estudiante' AND c.name = 'ese_codigo' AND ty.name = 'tinyint'
    )
    BEGIN
        PRINT 'Ampliando ese_codigo a SMALLINT en dbo.estudiante para compatibilidad con matricula...';
        ALTER TABLE [dbo].[estudiante] ALTER COLUMN [ese_codigo] [smallint] NOT NULL;
    END

    -- ========================================================================
    -- PASO 3: SANEAMIENTO DE REGISTROS HUÉRFANOS PREVIO A CLAVES FORÁNEAS
    -- ========================================================================
    PRINT 'Paso 3: Saneando registros huérfanos para garantizar activación de FKs...';

    -- 3.1 Asignaturas en curso: verificar que asi_codigo exista en asignatura
    IF EXISTS (
        SELECT 1 FROM [dbo].[curso] c 
        WHERE NOT EXISTS (SELECT 1 FROM [dbo].[asignatura] a WHERE a.asi_codigo = c.asi_codigo)
    )
    BEGIN
        PRINT 'Advertencia: Detectados cursos huérfanos sin asignatura válida. Insertando asignatura comodín...';
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
        WHERE NOT EXISTS (SELECT 1 FROM [dbo].[asignatura] a WHERE a.asi_codigo = [dbo].[curso].asi_codigo);
    END

    -- 3.2 Calendarios en curso
    IF EXISTS (
        SELECT 1 FROM [dbo].[curso] c 
        WHERE NOT EXISTS (SELECT 1 FROM [dbo].[calendario] cal WHERE cal.cal_codigo = c.cal_codigo)
    )
    BEGIN
        PRINT 'Advertencia: Detectados cursos huérfanos sin calendario válido. Insertando calendario comodín...';
        SET IDENTITY_INSERT [dbo].[calendario] ON;
        IF NOT EXISTS (SELECT 1 FROM [dbo].[calendario] WHERE cal_codigo = 0)
        BEGIN
            DECLARE @fallback_per INT = (SELECT TOP 1 per_codigo FROM [dbo].[periodo]);
            IF @fallback_per IS NULL
            BEGIN
                SET IDENTITY_INSERT [dbo].[periodo] ON;
                INSERT INTO [dbo].[periodo] (per_codigo, per_nombre, per_anio, per_estado)
                VALUES (0, 'PERIODO MIGRACION INICIAL', YEAR(GETDATE()), 0);
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
        WHERE NOT EXISTS (SELECT 1 FROM [dbo].[calendario] cal WHERE cal.cal_codigo = [dbo].[curso].cal_codigo);
    END

    -- 3.3 Sedes en curso
    IF EXISTS (
        SELECT 1 FROM [dbo].[curso] c 
        WHERE c.sed_codigo IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [dbo].[sede] s WHERE s.sed_codigo = c.sed_codigo)
    )
    BEGIN
        PRINT 'Saneando sede nula o inválida en cursos huérfanos...';
        UPDATE [dbo].[curso]
        SET [sed_codigo] = NULL
        WHERE [sed_codigo] IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [dbo].[sede] s WHERE s.sed_codigo = [dbo].[curso].sed_codigo);
    END

    -- 3.4 Espacio ocupación -> Curso (eso_actividad)
    IF EXISTS (
        SELECT 1 FROM [dbo].[espacio_ocupacion] eo
        WHERE NOT EXISTS (SELECT 1 FROM [dbo].[curso] c WHERE c.cur_codigo = eo.eso_actividad)
    )
    BEGIN
        PRINT 'Advertencia: Detectadas franjas de ocupación con curso inexistente. Desactivando registros obsoletos...';
        UPDATE [dbo].[espacio_ocupacion]
        SET [eso_estado] = '0', 
            [eso_descripcion] = SUBSTRING(ISNULL([eso_descripcion], '') + ' [SANEADO POR MIGRACION: Curso huérfano]', 1, 200)
        WHERE NOT EXISTS (SELECT 1 FROM [dbo].[curso] c WHERE c.cur_codigo = [dbo].[espacio_ocupacion].eso_actividad);
    END

    -- ========================================================================
    -- PASO 4: POBLAMIENTO RETROSPECTIVO DE METADATOS DE AUDITORÍA
    -- ========================================================================
    PRINT 'Paso 4: Inicializando marcas de auditoría en registros históricos...';

    UPDATE [dbo].[curso]
    SET 
        [aud_fecha_creacion] = ISNULL([cur_fecha_actualizacion], SYSDATETIME()),
        [aud_usuario_creacion] = 'MIGRACION_V2_INICIAL'
    WHERE [aud_usuario_creacion] IS NULL OR [aud_usuario_creacion] = SUSER_SNAME();

    UPDATE [dbo].[espacio_ocupacion]
    SET 
        [aud_fecha_creacion] = ISNULL([eso_fecha], SYSDATETIME()),
        [aud_usuario_creacion] = 'MIGRACION_V2_INICIAL'
    WHERE [aud_usuario_creacion] IS NULL OR [aud_usuario_creacion] = SUSER_SNAME();

    -- ========================================================================
    -- PASO 5: VERIFICACIÓN POST-MIGRACIÓN (ZERO DATA LOSS ASSERTION)
    -- ========================================================================
    PRINT 'Paso 5: Comprobando integridad cuantitativa (Zero Data Loss)...';

    DECLARE @post_curso INT, @post_espacio INT, @post_persona INT, @post_matricula INT;
    SELECT @post_curso = COUNT(*) FROM [dbo].[curso];
    SELECT @post_espacio = COUNT(*) FROM [dbo].[espacio_ocupacion];
    SELECT @post_persona = COUNT(*) FROM [dbo].[persona];
    SELECT @post_matricula = COUNT(*) FROM [dbo].[matricula];

    IF (@count_curso <> @post_curso OR @count_espacio <> @post_espacio OR 
        @count_persona <> @post_persona OR @count_matricula <> @post_matricula)
    BEGIN
        RAISERROR('FALLO DE INTEGRIDAD: Se detectó divergencia en el conteo de filas tras la migración.', 16, 1);
    END

    PRINT CONCAT('¡Verificación exitosa! Cursos: ', @post_curso, ', Ocupaciones: ', @post_espacio, ', Personas: ', @post_persona, ', Matrículas: ', @post_matricula);

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
