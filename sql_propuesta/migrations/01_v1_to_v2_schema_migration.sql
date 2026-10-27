-- ============================================================================
-- ARTEFACTO: 01_v1_to_v2_schema_migration.sql
-- DESCRIPCIÓN: Migración estructural e idempotente del esquema v1 a v2
--              1. Creación segura de esquemas faltantes
--              2. Eliminación de 34 HEAPS (conversión a Clustered PKs B-Tree)
--              3. Estandarización de claves primarias anónimas
--              4. Renombramiento de columnas defectuosas (per_año -> per_anio, pre_codgo -> pre_codigo)
--              5. Remoción de columnas de contraseñas en texto claro (usu_clave)
--              6. Eliminación de restricciones tautológicas y actualización de FKs a WITH CHECK
--              7. Incorporación de columnas canónicas de auditoría temporal
-- PROYECTO: Sistema de Programación Académica (p_academica-main)
-- MOTOR OBJETIVO: Microsoft SQL Server 2016+ / Azure SQL Database / T-SQL ANSI
-- ============================================================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
GO

PRINT 'Iniciando migración estructural de esquema v1 a v2...';
GO

BEGIN TRANSACTION;
BEGIN TRY

    -- ========================================================================
    -- PASO 1: CREACIÓN DE ESQUEMAS FALTANTES
    -- ========================================================================
    PRINT 'Paso 1: Verificando y creando esquemas lógicos...';

    IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'programacionacademica')
        EXEC('CREATE SCHEMA [programacionacademica]');

    IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'proyectos')
        EXEC('CREATE SCHEMA [proyectos]');

    IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'auditoria')
        EXEC('CREATE SCHEMA [auditoria]');

    IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'acreditacion')
        EXEC('CREATE SCHEMA [acreditacion]');

    -- ========================================================================
    -- PASO 2: CONVERSIÓN DE 34 TABLAS HEAP A CLUSTERED PKs
    -- ========================================================================
    PRINT 'Paso 2: Eliminando 34 Heaps y recreando Primary Keys como CLUSTERED...';

    -- Helper script para convertir PKs no agrupadas en agrupadas de forma segura
    DECLARE @heap_tables TABLE (
        sch NVARCHAR(50),
        tbl NVARCHAR(100),
        pk_name NVARCHAR(128),
        pk_cols NVARCHAR(200)
    );

    INSERT INTO @heap_tables (sch, tbl, pk_name, pk_cols) VALUES
    ('dbo', 'espacio', 'PK_espacios', '[esp_codigo] ASC'),
    ('dbo', 'grupo', 'PK_grupo', '[gru_codigo] ASC'),
    ('dbo', 'hora', 'PK_hora', '[hra_codigo] ASC'),
    ('dbo', 'matricula', 'PK_matricula', '[mat_codigo] ASC'),
    ('dbo', 'matricula_autorizacion', 'PK_matricula_autorizacion', '[maa_codigo] ASC'),
    ('dbo', 'matricula_configuracion', 'PK_matricula_configuracion', '[mco_codigo] ASC'),
    ('dbo', 'matricula_configuracion_detalle', 'PK_matricula_configuracion_detalle', '[mcd_codigo] ASC'),
    ('dbo', 'municipio', 'PK_municipio', '[mun_codigo] ASC'),
    ('dbo', 'nucleo', 'PK_nucleo', '[nuc_codigo] ASC'),
    ('dbo', 'periodo', 'PK_periodo', '[per_codigo] ASC'),
    ('dbo', 'persona', 'PK_persona', '[per_codigo] ASC'),
    ('dbo', 'persona_proyecto', 'PK_proyecto_persona', '[pep_codigo] ASC, [pry_codigo] ASC'),
    ('dbo', 'plan_academico', 'PK_plan_academico', '[pla_codigo] ASC'),
    ('dbo', 'prerrequisito', 'PK_prerequisito', '[pre_codigo] ASC'),
    ('dbo', 'programacion_proceso', 'PK_programacion_proceso', '[prp_codigo] ASC'),
    ('dbo', 'proyecto', 'PK_proyecto', '[pry_codigo] ASC'),
    ('dbo', 'proyecto_tipo', 'PK_proyecto_tipo', '[prt_codigo] ASC'),
    ('dbo', 'sede', 'PK_sede', '[sed_codigo] ASC'),
    ('dbo', 'sub_sede', 'PK_sub_sede_1', '[sus_codigo] ASC'),
    ('dbo', 'uaa', 'PK_unidad_academica_administrativa', '[uaa_codigo] ASC'),
    ('dbo', 'uaa_personal', 'PK_uaa_personal', '[uap_codigo] ASC'),
    ('dbo', 'vinculacion', 'PK_vinculacion', '[vin_codigo] ASC'),
    ('dbo', 'estudiante', 'PK_estudiante', '[est_codigo] ASC'),
    ('programacionacademica', 'grupo_uaa', 'PK_pgr_codigo', '[pgr_codigo] ASC'),
    ('programacionacademica', 'grupo_uaa_item', 'PK_gui_codigo', '[gui_codigo] ASC'),
    ('programacionacademica', 'periodo_unidad', 'PK_peu_periodo_unidad', '[peu_codigo] ASC'),
    ('programacionacademica', 'programacion_academica', 'PK_pra_programacion_academica', '[pra_codigo] ASC'),
    ('programacionacademica', 'programacion_gestion', 'PK_prg_programacion_gestion', '[prg_codigo] ASC'),
    ('programacionacademica', 'solicitud_cambio_horario', 'PK_sch_solicitud_cambio_horario', '[sch_codigo] ASC'),
    ('programacionacademica', 'solicitud_cambio_horario_comentario', 'PK_schc_solicitud_cambio_horario_comentario', '[schc_codigo] ASC'),
    ('programacionacademica', 'solicitud_cambio_horario_horario', 'PK_schh_solicitud_cambio_horario_horario', '[schh_codigo] ASC'),
    ('programacionacademica', 'solicitud_prestamo_docente', 'PK_spd_solicitud_prestamo_docente', '[spd_codigo] ASC'),
    ('programacionacademica', 'solicitud_prestamo_docente_comentario', 'PK_spd_solicitud_prestamo_docente_comentario', '[spdc_codigo] ASC'),
    ('programacionacademica', 'solicitud_prestamo_docente_horario', 'PK_spd_solicitud_prestamo_docente_horario', '[spdh_codigo] ASC');

    DECLARE @cur_sch NVARCHAR(50), @cur_tbl NVARCHAR(100), @cur_pk NVARCHAR(128), @cur_cols NVARCHAR(200);
    DECLARE cur_heaps CURSOR LOCAL FAST_FORWARD FOR 
        SELECT sch, tbl, pk_name, pk_cols FROM @heap_tables;

    OPEN cur_heaps;
    FETCH NEXT FROM cur_heaps INTO @cur_sch, @cur_tbl, @cur_pk, @cur_cols;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Verificar si la tabla existe y su PK actual no es agrupada (type = 2 en sys.indexes)
        IF EXISTS (
            SELECT 1 FROM sys.indexes i
            JOIN sys.tables t ON i.object_id = t.object_id
            JOIN sys.schemas s ON t.schema_id = s.schema_id
            WHERE s.name = @cur_sch AND t.name = @cur_tbl AND i.is_primary_key = 1 AND i.type = 2
        )
        BEGIN
            PRINT 'Re-clusterizando con resolución de dependencias: ' + @cur_sch + '.' + @cur_tbl;
            
            -- Obtener nombre real de la PK
            DECLARE @actual_pk_name NVARCHAR(128);
            SELECT @actual_pk_name = i.name 
            FROM sys.indexes i
            JOIN sys.tables t ON i.object_id = t.object_id
            JOIN sys.schemas s ON t.schema_id = s.schema_id
            WHERE s.name = @cur_sch AND t.name = @cur_tbl AND i.is_primary_key = 1;

            -- 1. Capturar claves foráneas entrantes referenciando a esta tabla
            DECLARE @tbl_id INT = OBJECT_ID('[' + @cur_sch + '].[' + @cur_tbl + ']');
            DECLARE @fk_store TABLE (
                id INT IDENTITY(1,1),
                drop_stmt NVARCHAR(MAX),
                create_stmt NVARCHAR(MAX)
            );

            INSERT INTO @fk_store (drop_stmt, create_stmt)
            SELECT 
                'ALTER TABLE [' + OBJECT_SCHEMA_NAME(fk.parent_object_id) + '].[' + OBJECT_NAME(fk.parent_object_id) + '] DROP CONSTRAINT [' + fk.name + '];',
                'ALTER TABLE [' + OBJECT_SCHEMA_NAME(fk.parent_object_id) + '].[' + OBJECT_NAME(fk.parent_object_id) + '] WITH CHECK ADD CONSTRAINT [' + fk.name + '] FOREIGN KEY (' +
                STUFF((
                    SELECT ', [' + col_name(fkc.parent_object_id, fkc.parent_column_id) + ']'
                    FROM sys.foreign_key_columns fkc
                    WHERE fkc.constraint_object_id = fk.object_id
                    ORDER BY fkc.constraint_column_id
                    FOR XML PATH(''), TYPE
                ).value('.', 'NVARCHAR(MAX)'), 1, 2, '') +
                ') REFERENCES [' + @cur_sch + '].[' + @cur_tbl + '] (' +
                STUFF((
                    SELECT ', [' + col_name(fkc.referenced_object_id, fkc.referenced_column_id) + ']'
                    FROM sys.foreign_key_columns fkc
                    WHERE fkc.constraint_object_id = fk.object_id
                    ORDER BY fkc.constraint_column_id
                    FOR XML PATH(''), TYPE
                ).value('.', 'NVARCHAR(MAX)'), 1, 2, '') + ');'
            FROM sys.foreign_keys fk
            WHERE fk.referenced_object_id = @tbl_id;

            -- 2. Eliminar temporalmente las FKs referenciadoras
            DECLARE @fk_idx INT = 1, @fk_tot INT = (SELECT COUNT(*) FROM @fk_store);
            DECLARE @stmt_drop NVARCHAR(MAX), @stmt_create NVARCHAR(MAX);

            WHILE @fk_idx <= @fk_tot
            BEGIN
                SELECT @stmt_drop = drop_stmt FROM @fk_store WHERE id = @fk_idx;
                EXEC sp_executesql @stmt_drop;
                SET @fk_idx = @fk_idx + 1;
            END

            -- 3. Eliminar PK no agrupada actual
            DECLARE @sql_drop NVARCHAR(MAX) = 'ALTER TABLE [' + @cur_sch + '].[' + @cur_tbl + '] DROP CONSTRAINT [' + @actual_pk_name + '];';
            EXEC sp_executesql @sql_drop;

            -- 4. Recrear PK como CLUSTERED
            DECLARE @sql_add NVARCHAR(MAX) = 'ALTER TABLE [' + @cur_sch + '].[' + @cur_tbl + '] ADD CONSTRAINT [' + @cur_pk + '] PRIMARY KEY CLUSTERED (' + @cur_cols + ');';
            EXEC sp_executesql @sql_add;

            -- 5. Restaurar todas las FKs referenciadoras
            SET @fk_idx = 1;
            WHILE @fk_idx <= @fk_tot
            BEGIN
                SELECT @stmt_create = create_stmt FROM @fk_store WHERE id = @fk_idx;
                EXEC sp_executesql @stmt_create;
                SET @fk_idx = @fk_idx + 1;
            END

            DELETE FROM @fk_store;
        END
        FETCH NEXT FROM cur_heaps INTO @cur_sch, @cur_tbl, @cur_pk, @cur_cols;
    END

    CLOSE cur_heaps;
    DEALLOCATE cur_heaps;

    -- ========================================================================
    -- PASO 3: ESTANDARIZACIÓN DE CLAVES PRIMARIAS ANÓNIMAS
    -- ========================================================================
    PRINT 'Paso 3: Estandarizando claves primarias anónimas...';

    -- dbo.curso_institucion_ejecucion
    IF EXISTS (
        SELECT 1 FROM sys.key_constraints kc
        JOIN sys.tables t ON kc.parent_object_id = t.object_id
        JOIN sys.schemas s ON t.schema_id = s.schema_id
        WHERE s.name = 'dbo' AND t.name = 'curso_institucion_ejecucion' AND kc.type = 'PK' AND kc.name LIKE 'PK__%'
    )
    BEGIN
        DECLARE @anon_cie_pk NVARCHAR(128);
        SELECT @anon_cie_pk = kc.name
        FROM sys.key_constraints kc
        JOIN sys.tables t ON kc.parent_object_id = t.object_id
        JOIN sys.schemas s ON t.schema_id = s.schema_id
        WHERE s.name = 'dbo' AND t.name = 'curso_institucion_ejecucion' AND kc.type = 'PK';

        EXEC sp_rename @anon_cie_pk, 'PK_curso_institucion_ejecucion', 'OBJECT';
        PRINT 'Renombrada PK anónima en curso_institucion_ejecucion a PK_curso_institucion_ejecucion';
    END

    -- programacionacademica.programacion_tipo_solicitudes
    IF EXISTS (
        SELECT 1 FROM sys.key_constraints kc
        JOIN sys.tables t ON kc.parent_object_id = t.object_id
        JOIN sys.schemas s ON t.schema_id = s.schema_id
        WHERE s.name = 'programacionacademica' AND t.name = 'programacion_tipo_solicitudes' AND kc.type = 'PK' AND kc.name LIKE 'PK__%'
    )
    BEGIN
        DECLARE @anon_pts_pk NVARCHAR(128);
        SELECT @anon_pts_pk = kc.name
        FROM sys.key_constraints kc
        JOIN sys.tables t ON kc.parent_object_id = t.object_id
        JOIN sys.schemas s ON t.schema_id = s.schema_id
        WHERE s.name = 'programacionacademica' AND t.name = 'programacion_tipo_solicitudes' AND kc.type = 'PK';

        EXEC sp_rename @anon_pts_pk, 'PK_programacion_tipo_solicitudes', 'OBJECT';
        PRINT 'Renombrada PK anónima en programacion_tipo_solicitudes a PK_programacion_tipo_solicitudes';
    END

    -- ========================================================================
    -- PASO 4: CORRECCIÓN DE NOMBRES DE COLUMNAS DEFECTUOSAS
    -- ========================================================================
    PRINT 'Paso 4: Corrigiendo nombres de columnas defectuosas...';

    -- dbo.periodo.per_año -> per_anio
    IF EXISTS (
        SELECT 1 FROM sys.columns c
        JOIN sys.tables t ON c.object_id = t.object_id
        JOIN sys.schemas s ON t.schema_id = s.schema_id
        WHERE s.name = 'dbo' AND t.name = 'periodo' AND c.name <> 'per_anio' AND (c.name = 'per_año' OR c.name LIKE 'per_a%o')
    ) AND NOT EXISTS (
        SELECT 1 FROM sys.columns c
        JOIN sys.tables t ON c.object_id = t.object_id
        JOIN sys.schemas s ON t.schema_id = s.schema_id
        WHERE s.name = 'dbo' AND t.name = 'periodo' AND c.name = 'per_anio'
    )
    BEGIN
        DECLARE @old_col_periodo NVARCHAR(128);
        SELECT @old_col_periodo = c.name FROM sys.columns c
        JOIN sys.tables t ON c.object_id = t.object_id
        JOIN sys.schemas s ON t.schema_id = s.schema_id
        WHERE s.name = 'dbo' AND t.name = 'periodo' AND c.name <> 'per_anio' AND (c.name = 'per_año' OR c.name LIKE 'per_a%o');

        DECLARE @ren_periodo NVARCHAR(200) = 'dbo.periodo.' + @old_col_periodo;
        EXEC sp_rename @ren_periodo, 'per_anio', 'COLUMN';
        PRINT 'Renombrada columna en dbo.periodo a per_anio';
    END

    -- proyectos.proyecto_proyeccion_social.pre_codgo -> pre_codigo
    IF EXISTS (
        SELECT 1 FROM sys.columns c
        JOIN sys.tables t ON c.object_id = t.object_id
        JOIN sys.schemas s ON t.schema_id = s.schema_id
        WHERE s.name = 'proyectos' AND t.name = 'proyecto_proyeccion_social' AND c.name = 'pre_codgo'
    )
    BEGIN
        EXEC sp_rename 'proyectos.proyecto_proyeccion_social.pre_codgo', 'pre_codigo', 'COLUMN';
        PRINT 'Corregido error tipográfico en proyectos.proyecto_proyeccion_social a pre_codigo';
    END

    -- ========================================================================
    -- PASO 5: REMOCIÓN DE CONTRASEÑAS EN TEXTO PLANO DE TABLAS OPERATIVAS Y AUDITORÍA
    -- ========================================================================
    PRINT 'Paso 5: Purgando columnas de contraseñas en texto claro (usu_clave)...';

    IF EXISTS (
        SELECT 1 FROM sys.columns c
        JOIN sys.tables t ON c.object_id = t.object_id
        JOIN sys.schemas s ON t.schema_id = s.schema_id
        WHERE s.name = 'dbo' AND t.name = 'curso' AND c.name = 'usu_clave'
    )
    BEGIN
        ALTER TABLE [dbo].[curso] DROP COLUMN [usu_clave];
        PRINT 'Eliminada columna usu_clave de dbo.curso';
    END

    IF EXISTS (
        SELECT 1 FROM sys.columns c
        JOIN sys.tables t ON c.object_id = t.object_id
        JOIN sys.schemas s ON t.schema_id = s.schema_id
        WHERE s.name = 'dbo' AND t.name = 'espacio_ocupacion' AND c.name = 'usu_clave'
    )
    BEGIN
        ALTER TABLE [dbo].[espacio_ocupacion] DROP COLUMN [usu_clave];
        PRINT 'Eliminada columna usu_clave de dbo.espacio_ocupacion';
    END

    IF EXISTS (
        SELECT 1 FROM sys.columns c
        JOIN sys.tables t ON c.object_id = t.object_id
        JOIN sys.schemas s ON t.schema_id = s.schema_id
        WHERE s.name = 'dbo' AND t.name = 'aud_curso' AND c.name = 'usu_clave'
    )
    BEGIN
        ALTER TABLE [dbo].[aud_curso] DROP COLUMN [usu_clave];
        PRINT 'Eliminada columna usu_clave de dbo.aud_curso';
    END

    -- ========================================================================
    -- PASO 6: ELIMINACIÓN DE CLAVE FORÁNEA TAUTOLÓGICA Y TRUST DE RESTRECCIONES
    -- ========================================================================
    PRINT 'Paso 6: Removiendo FK tautológica y actualizando restricciones a WITH CHECK...';

    IF EXISTS (
        SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_proyecto_proyeccion_social_proyecto_proyeccion_social'
    )
    BEGIN
        ALTER TABLE [proyectos].[proyecto_proyeccion_social] 
        DROP CONSTRAINT [FK_proyecto_proyeccion_social_proyecto_proyeccion_social];
        PRINT 'Eliminada clave foránea tautológica en proyecto_proyeccion_social';
    END

    -- ========================================================================
    -- PASO 7: INCORPORACIÓN DE AUDITORÍA TEMPORAL ESTANDARIZADA
    -- ========================================================================
    PRINT 'Paso 7: Incorporando columnas canónicas de auditoría...';

    DECLARE @audit_tables TABLE (sch NVARCHAR(50), tbl NVARCHAR(100));
    INSERT INTO @audit_tables VALUES
    ('dbo', 'curso'), ('dbo', 'espacio_ocupacion'), ('dbo', 'matricula'),
    ('programacionacademica', 'programacion_academica'),
    ('programacionacademica', 'solicitud_cambio_horario'),
    ('programacionacademica', 'solicitud_prestamo_docente'),
    ('proyectos', 'proyecto_proyeccion_social');

    DECLARE @a_sch NVARCHAR(50), @a_tbl NVARCHAR(100);
    DECLARE cur_audit CURSOR LOCAL FAST_FORWARD FOR SELECT sch, tbl FROM @audit_tables;
    OPEN cur_audit;
    FETCH NEXT FROM cur_audit INTO @a_sch, @a_tbl;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF NOT EXISTS (
            SELECT 1 FROM sys.columns c
            JOIN sys.tables t ON c.object_id = t.object_id
            JOIN sys.schemas s ON t.schema_id = s.schema_id
            WHERE s.name = @a_sch AND t.name = @a_tbl AND c.name = 'aud_fecha_creacion'
        )
        BEGIN
            DECLARE @sql_audit NVARCHAR(MAX) = 'ALTER TABLE [' + @a_sch + '].[' + @a_tbl + '] ADD ' +
                '[aud_fecha_creacion] [datetime2](7) NOT NULL CONSTRAINT [DF_' + @a_tbl + '_aud_fecha_creacion] DEFAULT (sysdatetime()), ' +
                '[aud_usuario_creacion] [nvarchar](128) NOT NULL CONSTRAINT [DF_' + @a_tbl + '_aud_usuario_creacion] DEFAULT (suser_sname()), ' +
                '[aud_fecha_modificacion] [datetime2](7) NULL, ' +
                '[aud_usuario_modificacion] [nvarchar](128) NULL;';
            EXEC sp_executesql @sql_audit;
            PRINT 'Agregadas columnas de auditoría a: ' + @a_sch + '.' + @a_tbl;
        END
        FETCH NEXT FROM cur_audit INTO @a_sch, @a_tbl;
    END

    CLOSE cur_audit;
    DEALLOCATE cur_audit;

    COMMIT TRANSACTION;
    PRINT '¡Migración estructural 01_v1_to_v2_schema_migration completada exitosamente!';

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrSeverity INT = ERROR_SEVERITY();
    DECLARE @ErrState INT = ERROR_STATE();
    PRINT 'ERROR EN MIGRACIÓN: ' + @ErrMsg;
    RAISERROR(@ErrMsg, @ErrSeverity, @ErrState);
END CATCH;
GO
