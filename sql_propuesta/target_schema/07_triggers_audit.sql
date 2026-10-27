-- ============================================================================
-- ARTEFACTO: 07_triggers_audit.sql (REMEDIADO Y VALIDADO)
-- DESCRIPCIÓN: Disparadores automáticos de auditoría temporal y trazabilidad
--              - Población automática de tablas shadow de auditoría (aud_curso, aud_espacio_ocupacion, aud_curso_cupo_subgrupo)
--              - Registro de transiciones de estado en programacion_gestion y comentarios de solicitudes
--              - Captura de SYSTEM_USER, HOST_NAME(), marca temporal precisa y tipo de operación (I/U/D)
-- PROYECTO: Sistema de Programación Académica (p_academica-main)
-- MOTOR OBJETIVO: Microsoft SQL Server 2016+ / Azure SQL Database / T-SQL ANSI
-- ============================================================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- ----------------------------------------------------------------------------
-- TRIGGER 1: [dbo].[TR_curso_audit]
-- Captura inserciones, modificaciones y eliminaciones sobre [dbo].[curso] hacia [dbo].[aud_curso]
-- ----------------------------------------------------------------------------
CREATE OR ALTER TRIGGER [dbo].[TR_curso_audit]
ON [dbo].[curso]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @log_type CHAR(6);
    IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
        SET @log_type = 'UPDATE';
    ELSE IF EXISTS (SELECT * FROM inserted)
        SET @log_type = 'INSERT';
    ELSE IF EXISTS (SELECT * FROM deleted)
        SET @log_type = 'DELETE';
    ELSE
        RETURN;

    -- Si es UPDATE o INSERT, capturar imagen desde inserted
    IF @log_type IN ('INSERT', 'UPDATE')
    BEGIN
        INSERT INTO [dbo].[aud_curso] (
            [cur_codigo], [uap_codigo], [asi_codigo], [sed_codigo], [cal_codigo], 
            [cur_grupo], [cur_cupo], [cur_estado], [tic_codigo], [cut_codigo], 
            [pla_codigo], [cur_exclusivo], [cur_fecha_inicio], [cur_semanas], 
            [cur_cierre], [cur_grabado], [cdp_codigo], [usu_codigo], 
            [cur_observaciones], [cur_ampliacion_cupo], [cur_fecha_actualizacion], 
            [cur_notaparcial], [tes_codigo], [cur_url], [cur_id_evento], 
            [aud_user], [aud_changed], [aud_host], [aud_log_type]
        )
        SELECT 
            i.cur_codigo, i.uap_codigo, i.asi_codigo, i.sed_codigo, i.cal_codigo, 
            i.cur_grupo, i.cur_cupo, i.cur_estado, i.tic_codigo, i.cut_codigo, 
            i.pla_codigo, i.cur_exclusivo, i.cur_fecha_inicio, i.cur_semanas, 
            i.cur_cierre, i.cur_grabado, i.cdp_codigo, i.usu_codigo, 
            i.cur_observaciones, i.cur_ampliacion_cupo, i.cur_fecha_actualizacion, 
            i.cur_notaparcial, i.tes_codigo, i.cur_url, i.cur_id_evento, 
            SUSER_SNAME(), SYSDATETIME(), HOST_NAME(), @log_type
        FROM inserted i;
    END
    ELSE -- Si es DELETE, capturar registro eliminado desde deleted
    BEGIN
        INSERT INTO [dbo].[aud_curso] (
            [cur_codigo], [uap_codigo], [asi_codigo], [sed_codigo], [cal_codigo], 
            [cur_grupo], [cur_cupo], [cur_estado], [tic_codigo], [cut_codigo], 
            [pla_codigo], [cur_exclusivo], [cur_fecha_inicio], [cur_semanas], 
            [cur_cierre], [cur_grabado], [cdp_codigo], [usu_codigo], 
            [cur_observaciones], [cur_ampliacion_cupo], [cur_fecha_actualizacion], 
            [cur_notaparcial], [tes_codigo], [cur_url], [cur_id_evento], 
            [aud_user], [aud_changed], [aud_host], [aud_log_type]
        )
        SELECT 
            d.cur_codigo, d.uap_codigo, d.asi_codigo, d.sed_codigo, d.cal_codigo, 
            d.cur_grupo, d.cur_cupo, d.cur_estado, d.tic_codigo, d.cut_codigo, 
            d.pla_codigo, d.cur_exclusivo, d.cur_fecha_inicio, d.cur_semanas, 
            d.cur_cierre, d.cur_grabado, d.cdp_codigo, d.usu_codigo, 
            d.cur_observaciones, d.cur_ampliacion_cupo, d.cur_fecha_actualizacion, 
            d.cur_notaparcial, d.tes_codigo, d.cur_url, d.cur_id_evento, 
            SUSER_SNAME(), SYSDATETIME(), HOST_NAME(), 'DELETE'
        FROM deleted d;
    END
END;
GO

-- ----------------------------------------------------------------------------
-- TRIGGER 2: [dbo].[TR_espacio_ocupacion_audit]
-- Captura cambios de asignación y reservas de aulas en [dbo].[espacio_ocupacion]
-- ----------------------------------------------------------------------------
CREATE OR ALTER TRIGGER [dbo].[TR_espacio_ocupacion_audit]
ON [dbo].[espacio_ocupacion]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @log_type CHAR(5);
    IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
        SET @log_type = 'UPDAT';
    ELSE IF EXISTS (SELECT * FROM inserted)
        SET @log_type = 'INSRT';
    ELSE IF EXISTS (SELECT * FROM deleted)
        SET @log_type = 'DELET';
    ELSE
        RETURN;

    IF @log_type IN ('INSRT', 'UPDAT')
    BEGIN
        INSERT INTO [dbo].[aud_espacio_ocupacion] (
            [eso_codigo], [esp_codigo], [uaa_codigo], [eso_fecha], [hor_codigo], 
            [dia_codigo], [hra_codigo], [eso_actividad], [eso_subgrupo], [uap_codigo], 
            [eso_estado], [oct_codigo], [eso_descripcion], [cdp_codigo], [ctr_codigo], [usu_codigo], 
            [aud_user], [aud_changed], [aud_host], [aud_log_type]
        )
        SELECT 
            i.eso_codigo, i.esp_codigo, i.uaa_codigo, i.eso_fecha, i.hor_codigo, 
            i.dia_codigo, i.hra_codigo, i.eso_actividad, i.eso_subgrupo, i.uap_codigo, 
            i.eso_estado, i.oct_codigo, i.eso_descripcion, i.cdp_codigo, i.ctr_codigo, i.usu_codigo, 
            SUSER_SNAME(), SYSDATETIME(), HOST_NAME(), @log_type
        FROM inserted i;
    END
    ELSE
    BEGIN
        INSERT INTO [dbo].[aud_espacio_ocupacion] (
            [eso_codigo], [esp_codigo], [uaa_codigo], [eso_fecha], [hor_codigo], 
            [dia_codigo], [hra_codigo], [eso_actividad], [eso_subgrupo], [uap_codigo], 
            [eso_estado], [oct_codigo], [eso_descripcion], [cdp_codigo], [ctr_codigo], [usu_codigo], 
            [aud_user], [aud_changed], [aud_host], [aud_log_type]
        )
        SELECT 
            d.eso_codigo, d.esp_codigo, d.uaa_codigo, d.eso_fecha, d.hor_codigo, 
            d.dia_codigo, d.hra_codigo, d.eso_actividad, d.eso_subgrupo, d.uap_codigo, 
            d.eso_estado, d.oct_codigo, d.eso_descripcion, d.cdp_codigo, d.ctr_codigo, d.usu_codigo, 
            SUSER_SNAME(), SYSDATETIME(), HOST_NAME(), 'DELET'
        FROM deleted d;
    END
END;
GO

-- ----------------------------------------------------------------------------
-- TRIGGER 3: [dbo].[TR_curso_cupo_subgrupo_audit]
-- Trazabilidad sobre ampliaciones y ajustes de subgrupos y cupos
-- ----------------------------------------------------------------------------
CREATE OR ALTER TRIGGER [dbo].[TR_curso_cupo_subgrupo_audit]
ON [dbo].[curso_cupo_subgrupo]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @log_type CHAR(6);
    IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
        SET @log_type = 'UPDATE';
    ELSE IF EXISTS (SELECT * FROM inserted)
        SET @log_type = 'INSERT';
    ELSE IF EXISTS (SELECT * FROM deleted)
        SET @log_type = 'DELETE';
    ELSE
        RETURN;

    IF @log_type IN ('INSERT', 'UPDATE')
    BEGIN
        INSERT INTO [dbo].[aud_curso_cupo_subgrupo] (
            [cus_cod], [cur_codigo], [eso_subgrupo], [cus_cupo], [cus_estado], [cus_fecha_registro],
            [aud_user], [aud_changed], [aud_host], [aud_ip], [aud_log_type]
        )
        SELECT 
            i.cus_cod, i.cur_codigo, i.eso_subgrupo, i.cus_cupo, i.cus_estado, i.cus_fecha_registro,
            SUSER_SNAME(), SYSDATETIME(), HOST_NAME(), 
            ISNULL(CONVERT(VARCHAR(50), CONNECTIONPROPERTY('client_net_address')), '127.0.0.1'), 
            @log_type
        FROM inserted i;
    END
    ELSE
    BEGIN
        INSERT INTO [dbo].[aud_curso_cupo_subgrupo] (
            [cus_cod], [cur_codigo], [eso_subgrupo], [cus_cupo], [cus_estado], [cus_fecha_registro],
            [aud_user], [aud_changed], [aud_host], [aud_ip], [aud_log_type]
        )
        SELECT 
            d.cus_cod, d.cur_codigo, d.eso_subgrupo, d.cus_cupo, d.cus_estado, d.cus_fecha_registro,
            SUSER_SNAME(), SYSDATETIME(), HOST_NAME(), 
            ISNULL(CONVERT(VARCHAR(50), CONNECTIONPROPERTY('client_net_address')), '127.0.0.1'), 
            'DELETE'
        FROM deleted d;
    END
END;
GO

-- ----------------------------------------------------------------------------
-- TRIGGER 4: [programacionacademica].[TR_programacion_academica_audit]
-- Registra eventos de apertura, cierre y cambio de fechas en programacion_gestion
-- Suministra pts_codigo = 1 (Tipo de trámite: Programación Académica General)
-- ----------------------------------------------------------------------------
CREATE OR ALTER TRIGGER [programacionacademica].[TR_programacion_academica_audit]
ON [programacionacademica].[programacion_academica]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO [programacionacademica].[programacion_gestion] (
        [uaa_codigo], [cal_codigo], [prg_fecha_inicio], [prg_fecha_fin], [prg_estado], [pts_codigo]
    )
    SELECT 
        i.uaa_codigo, i.cal_codigo, i.pra_fecha_inicio, i.pra_fecha_fin, i.pra_estado, 1
    FROM inserted i;
END;
GO

-- ----------------------------------------------------------------------------
-- TRIGGER 5: [programacionacademica].[TR_solicitud_cambio_horario_audit]
-- Registra automáticamente el comentario de cambio de estado en la solicitud
-- ----------------------------------------------------------------------------
CREATE OR ALTER TRIGGER [programacionacademica].[TR_solicitud_cambio_horario_audit]
ON [programacionacademica].[solicitud_cambio_horario]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Verificar si hubo cambio en la columna sch_estado
    IF UPDATE(sch_estado)
    BEGIN
        INSERT INTO [programacionacademica].[solicitud_cambio_horario_comentario] (
            [sch_codigo], [usu_codigo], [schc_fecha_creacion], [schc_comentario]
        )
        SELECT 
            i.sch_codigo, 
            ISNULL(i.usu_codigo, 1), 
            SYSDATETIME(), 
            CONCAT('Transición de estado automática: de ', d.sch_estado, ' a ', i.sch_estado, ' por ', SUSER_SNAME())
        FROM inserted i
        INNER JOIN deleted d ON i.sch_codigo = d.sch_codigo
        WHERE i.sch_estado <> d.sch_estado;
    END
END;
GO

-- ----------------------------------------------------------------------------
-- TRIGGER 6: [programacionacademica].[TR_solicitud_prestamo_docente_audit]
-- Registra automáticamente comentarios de cambio de estado en préstamo docente
-- ----------------------------------------------------------------------------
CREATE OR ALTER TRIGGER [programacionacademica].[TR_solicitud_prestamo_docente_audit]
ON [programacionacademica].[solicitud_prestamo_docente]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF UPDATE(spd_estado)
    BEGIN
        INSERT INTO [programacionacademica].[solicitud_prestamo_docente_comentario] (
            [spd_codigo], [spdc_estado], [usu_codigo], [spdc_fecha_creacion], [spdc_mensaje]
        )
        SELECT 
            i.spd_codigo, 
            1, 
            ISNULL(i.persona_codigo, 1), 
            SYSDATETIME(), 
            CONCAT('Transición de estado de préstamo docente: de ', d.spd_estado, ' a ', i.spd_estado, ' por ', SUSER_SNAME())
        FROM inserted i
        INNER JOIN deleted d ON i.spd_codigo = d.spd_codigo
        WHERE i.spd_estado <> d.spd_estado;
    END
END;
GO
