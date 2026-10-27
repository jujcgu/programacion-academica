-- ============================================================================
-- ARTEFACTO: 05_indexes.sql
-- DESCRIPCIÓN: Estrategia exhaustiva de índices secundarios no agrupados (Non-Clustered)
--              Cubre 100% de claves foráneas y optimiza las 178 consultas en bucles (N+1)
-- PROYECTO: Sistema de Programación Académica (p_academica-main)
-- MOTOR OBJETIVO: Microsoft SQL Server 2016+ / Azure SQL Database / T-SQL ANSI
-- ============================================================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- ============================================================================
-- SECCIÓN 1: ÍNDICES SOBRE CLAVES FORÁNEAS (Eliminación de Table Scans en JOINs y Cascadas)
-- ============================================================================

-- Índice FK: IX_FK_asignatura_nuc_codigo en [dbo].[asignatura] ([nuc_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_asignatura_nuc_codigo' AND object_id = OBJECT_ID('[dbo].[asignatura]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_asignatura_nuc_codigo]
    ON [dbo].[asignatura] ([nuc_codigo]);
END
GO

-- Índice FK: IX_FK_asignatura_uaa_codigo en [dbo].[asignatura] ([uaa_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_asignatura_uaa_codigo' AND object_id = OBJECT_ID('[dbo].[asignatura]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_asignatura_uaa_codigo]
    ON [dbo].[asignatura] ([uaa_codigo]);
END
GO

-- Índice FK: IX_FK_bloque_sus_codigo en [dbo].[bloque] ([sus_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_bloque_sus_codigo' AND object_id = OBJECT_ID('[dbo].[bloque]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_bloque_sus_codigo]
    ON [dbo].[bloque] ([sus_codigo]);
END
GO

-- Índice FK: IX_FK_calendario_per_codigo en [dbo].[calendario] ([per_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_calendario_per_codigo' AND object_id = OBJECT_ID('[dbo].[calendario]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_calendario_per_codigo]
    ON [dbo].[calendario] ([per_codigo]);
END
GO

-- Índice FK: IX_FK_cupo_autorizacion_cua_curso en [dbo].[cupo_autorizacion] ([cua_curso])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_cupo_autorizacion_cua_curso' AND object_id = OBJECT_ID('[dbo].[cupo_autorizacion]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_cupo_autorizacion_cua_curso]
    ON [dbo].[cupo_autorizacion] ([cua_curso]);
END
GO

-- Índice FK: IX_FK_curso_asi_codigo en [dbo].[curso] ([asi_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_curso_asi_codigo' AND object_id = OBJECT_ID('[dbo].[curso]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_curso_asi_codigo]
    ON [dbo].[curso] ([asi_codigo]);
END
GO

-- Índice FK: IX_FK_curso_uap_codigo en [dbo].[curso] ([uap_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_curso_uap_codigo' AND object_id = OBJECT_ID('[dbo].[curso]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_curso_uap_codigo]
    ON [dbo].[curso] ([uap_codigo]);
END
GO

-- Índice FK: IX_FK_curso_institucion_ejecucion_cur_codigo en [dbo].[curso_institucion_ejecucion] ([cur_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_curso_institucion_ejecucion_cur_codigo' AND object_id = OBJECT_ID('[dbo].[curso_institucion_ejecucion]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_curso_institucion_ejecucion_cur_codigo]
    ON [dbo].[curso_institucion_ejecucion] ([cur_codigo]);
END
GO

-- Índice FK: IX_FK_curso_institucion_ejecucion_esp_codigo en [dbo].[curso_institucion_ejecucion] ([esp_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_curso_institucion_ejecucion_esp_codigo' AND object_id = OBJECT_ID('[dbo].[curso_institucion_ejecucion]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_curso_institucion_ejecucion_esp_codigo]
    ON [dbo].[curso_institucion_ejecucion] ([esp_codigo]);
END
GO

-- Índice FK: IX_FK_curso_institucion_ejecucion_mun_codigo en [dbo].[curso_institucion_ejecucion] ([mun_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_curso_institucion_ejecucion_mun_codigo' AND object_id = OBJECT_ID('[dbo].[curso_institucion_ejecucion]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_curso_institucion_ejecucion_mun_codigo]
    ON [dbo].[curso_institucion_ejecucion] ([mun_codigo]);
END
GO

-- Índice FK: IX_FK_curso_plan_cur_codigo en [dbo].[curso_plan] ([cur_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_curso_plan_cur_codigo' AND object_id = OBJECT_ID('[dbo].[curso_plan]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_curso_plan_cur_codigo]
    ON [dbo].[curso_plan] ([cur_codigo]);
END
GO

-- Índice FK: IX_FK_departamento_pai_codigo en [dbo].[departamento] ([pai_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_departamento_pai_codigo' AND object_id = OBJECT_ID('[dbo].[departamento]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_departamento_pai_codigo]
    ON [dbo].[departamento] ([pai_codigo]);
END
GO

-- Índice FK: IX_FK_docente_escalafon_esc_codigo en [dbo].[docente_escalafon] ([esc_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_docente_escalafon_esc_codigo' AND object_id = OBJECT_ID('[dbo].[docente_escalafon]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_docente_escalafon_esc_codigo]
    ON [dbo].[docente_escalafon] ([esc_codigo]);
END
GO

-- Índice FK: IX_FK_docente_escalafon_per_codigo en [dbo].[docente_escalafon] ([per_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_docente_escalafon_per_codigo' AND object_id = OBJECT_ID('[dbo].[docente_escalafon]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_docente_escalafon_per_codigo]
    ON [dbo].[docente_escalafon] ([per_codigo]);
END
GO

-- Índice FK: IX_FK_espacio_eti_codigo en [dbo].[espacio] ([eti_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_espacio_eti_codigo' AND object_id = OBJECT_ID('[dbo].[espacio]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_espacio_eti_codigo]
    ON [dbo].[espacio] ([eti_codigo]);
END
GO

-- Índice FK: IX_FK_espacio_mun_codigo en [dbo].[espacio] ([mun_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_espacio_mun_codigo' AND object_id = OBJECT_ID('[dbo].[espacio]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_espacio_mun_codigo]
    ON [dbo].[espacio] ([mun_codigo]);
END
GO

-- Índice FK: IX_FK_espacio_ocupacion_eso_actividad en [dbo].[espacio_ocupacion] ([eso_actividad])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_espacio_ocupacion_eso_actividad' AND object_id = OBJECT_ID('[dbo].[espacio_ocupacion]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_espacio_ocupacion_eso_actividad]
    ON [dbo].[espacio_ocupacion] ([eso_actividad]);
END
GO

-- Índice FK: IX_FK_espacio_ocupacion_esp_codigo en [dbo].[espacio_ocupacion] ([esp_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_espacio_ocupacion_esp_codigo' AND object_id = OBJECT_ID('[dbo].[espacio_ocupacion]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_espacio_ocupacion_esp_codigo]
    ON [dbo].[espacio_ocupacion] ([esp_codigo]);
END
GO

-- Índice FK: IX_FK_espacio_ocupacion_hra_codigo en [dbo].[espacio_ocupacion] ([hra_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_espacio_ocupacion_hra_codigo' AND object_id = OBJECT_ID('[dbo].[espacio_ocupacion]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_espacio_ocupacion_hra_codigo]
    ON [dbo].[espacio_ocupacion] ([hra_codigo]);
END
GO

-- Índice FK: IX_FK_espacio_ocupacion_hor_codigo en [dbo].[espacio_ocupacion] ([hor_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_espacio_ocupacion_hor_codigo' AND object_id = OBJECT_ID('[dbo].[espacio_ocupacion]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_espacio_ocupacion_hor_codigo]
    ON [dbo].[espacio_ocupacion] ([hor_codigo]);
END
GO

-- Índice FK: IX_FK_espacio_ocupacion_oct_codigo en [dbo].[espacio_ocupacion] ([oct_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_espacio_ocupacion_oct_codigo' AND object_id = OBJECT_ID('[dbo].[espacio_ocupacion]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_espacio_ocupacion_oct_codigo]
    ON [dbo].[espacio_ocupacion] ([oct_codigo]);
END
GO

-- Índice FK: IX_FK_espacio_ocupacion_uaa_codigo en [dbo].[espacio_ocupacion] ([uaa_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_espacio_ocupacion_uaa_codigo' AND object_id = OBJECT_ID('[dbo].[espacio_ocupacion]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_espacio_ocupacion_uaa_codigo]
    ON [dbo].[espacio_ocupacion] ([uaa_codigo]);
END
GO

-- Índice FK: IX_FK_hora_hra_codigo en [dbo].[hora] ([hra_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_hora_hra_codigo' AND object_id = OBJECT_ID('[dbo].[hora]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_hora_hra_codigo]
    ON [dbo].[hora] ([hra_codigo]);
END
GO

-- Índice FK: IX_FK_matricula_cal_codigo en [dbo].[matricula] ([cal_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_matricula_cal_codigo' AND object_id = OBJECT_ID('[dbo].[matricula]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_matricula_cal_codigo]
    ON [dbo].[matricula] ([cal_codigo]);
END
GO

-- Índice FK: IX_FK_matricula_est_codigo en [dbo].[matricula] ([est_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_matricula_est_codigo' AND object_id = OBJECT_ID('[dbo].[matricula]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_matricula_est_codigo]
    ON [dbo].[matricula] ([est_codigo]);
END
GO

-- Índice FK: IX_FK_matricula_mat_tipo en [dbo].[matricula] ([mat_tipo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_matricula_mat_tipo' AND object_id = OBJECT_ID('[dbo].[matricula]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_matricula_mat_tipo]
    ON [dbo].[matricula] ([mat_tipo]);
END
GO

-- Índice FK: IX_FK_matricula_configuracion_pla_codigo en [dbo].[matricula_configuracion] ([pla_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_matricula_configuracion_pla_codigo' AND object_id = OBJECT_ID('[dbo].[matricula_configuracion]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_matricula_configuracion_pla_codigo]
    ON [dbo].[matricula_configuracion] ([pla_codigo]);
END
GO

-- Índice FK: IX_FK_matricula_configuracion_detalle_cur_codigo en [dbo].[matricula_configuracion_detalle] ([cur_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_matricula_configuracion_detalle_cur_codigo' AND object_id = OBJECT_ID('[dbo].[matricula_configuracion_detalle]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_matricula_configuracion_detalle_cur_codigo]
    ON [dbo].[matricula_configuracion_detalle] ([cur_codigo]);
END
GO

-- Índice FK: IX_FK_matricula_configuracion_detalle_mco_codigo en [dbo].[matricula_configuracion_detalle] ([mco_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_matricula_configuracion_detalle_mco_codigo' AND object_id = OBJECT_ID('[dbo].[matricula_configuracion_detalle]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_matricula_configuracion_detalle_mco_codigo]
    ON [dbo].[matricula_configuracion_detalle] ([mco_codigo]);
END
GO

-- Índice FK: IX_FK_matricula_configuracion_detalle_paa_codigo en [dbo].[matricula_configuracion_detalle] ([paa_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_matricula_configuracion_detalle_paa_codigo' AND object_id = OBJECT_ID('[dbo].[matricula_configuracion_detalle]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_matricula_configuracion_detalle_paa_codigo]
    ON [dbo].[matricula_configuracion_detalle] ([paa_codigo]);
END
GO

-- Índice FK: IX_FK_nivel_academico_nat_codigo en [dbo].[nivel_academico] ([nat_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_nivel_academico_nat_codigo' AND object_id = OBJECT_ID('[dbo].[nivel_academico]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_nivel_academico_nat_codigo]
    ON [dbo].[nivel_academico] ([nat_codigo]);
END
GO

-- Índice FK: IX_FK_novedad_not_codigo en [dbo].[novedad] ([not_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_novedad_not_codigo' AND object_id = OBJECT_ID('[dbo].[novedad]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_novedad_not_codigo]
    ON [dbo].[novedad] ([not_codigo]);
END
GO

-- Índice FK: IX_FK_periodo_pet_codigo en [dbo].[periodo] ([pet_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_periodo_pet_codigo' AND object_id = OBJECT_ID('[dbo].[periodo]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_periodo_pet_codigo]
    ON [dbo].[periodo] ([pet_codigo]);
END
GO

-- Índice FK: IX_FK_persona_novedad_nov_codigo en [dbo].[persona_novedad] ([nov_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_persona_novedad_nov_codigo' AND object_id = OBJECT_ID('[dbo].[persona_novedad]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_persona_novedad_nov_codigo]
    ON [dbo].[persona_novedad] ([nov_codigo]);
END
GO

-- Índice FK: IX_FK_persona_novedad_pen_persona en [dbo].[persona_novedad] ([pen_persona])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_persona_novedad_pen_persona' AND object_id = OBJECT_ID('[dbo].[persona_novedad]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_persona_novedad_pen_persona]
    ON [dbo].[persona_novedad] ([pen_persona]);
END
GO

-- Índice FK: IX_FK_persona_novedad_uap_codigo en [dbo].[persona_novedad] ([uap_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_persona_novedad_uap_codigo' AND object_id = OBJECT_ID('[dbo].[persona_novedad]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_persona_novedad_uap_codigo]
    ON [dbo].[persona_novedad] ([uap_codigo]);
END
GO

-- Índice FK: IX_FK_persona_proyecto_pep_persona en [dbo].[persona_proyecto] ([pep_persona])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_persona_proyecto_pep_persona' AND object_id = OBJECT_ID('[dbo].[persona_proyecto]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_persona_proyecto_pep_persona]
    ON [dbo].[persona_proyecto] ([pep_persona]);
END
GO

-- Índice FK: IX_FK_persona_proyecto_prr_codigo en [dbo].[persona_proyecto] ([prr_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_persona_proyecto_prr_codigo' AND object_id = OBJECT_ID('[dbo].[persona_proyecto]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_persona_proyecto_prr_codigo]
    ON [dbo].[persona_proyecto] ([prr_codigo]);
END
GO

-- Índice FK: IX_FK_persona_proyecto_pry_codigo en [dbo].[persona_proyecto] ([pry_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_persona_proyecto_pry_codigo' AND object_id = OBJECT_ID('[dbo].[persona_proyecto]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_persona_proyecto_pry_codigo]
    ON [dbo].[persona_proyecto] ([pry_codigo]);
END
GO

-- Índice FK: IX_FK_plan_academico_nac_codigo en [dbo].[plan_academico] ([nac_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_plan_academico_nac_codigo' AND object_id = OBJECT_ID('[dbo].[plan_academico]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_plan_academico_nac_codigo]
    ON [dbo].[plan_academico] ([nac_codigo]);
END
GO

-- Índice FK: IX_FK_plan_academico_asignatura_asi_codigo en [dbo].[plan_academico_asignatura] ([asi_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_plan_academico_asignatura_asi_codigo' AND object_id = OBJECT_ID('[dbo].[plan_academico_asignatura]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_plan_academico_asignatura_asi_codigo]
    ON [dbo].[plan_academico_asignatura] ([asi_codigo]);
END
GO

-- Índice FK: IX_FK_plan_academico_asignatura_pla_codigo en [dbo].[plan_academico_asignatura] ([pla_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_plan_academico_asignatura_pla_codigo' AND object_id = OBJECT_ID('[dbo].[plan_academico_asignatura]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_plan_academico_asignatura_pla_codigo]
    ON [dbo].[plan_academico_asignatura] ([pla_codigo]);
END
GO

-- Índice FK: IX_FK_plan_estudiante_est_codigo en [dbo].[plan_estudiante] ([est_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_plan_estudiante_est_codigo' AND object_id = OBJECT_ID('[dbo].[plan_estudiante]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_plan_estudiante_est_codigo]
    ON [dbo].[plan_estudiante] ([est_codigo]);
END
GO

-- Índice FK: IX_FK_plan_estudiante_pla_codigo en [dbo].[plan_estudiante] ([pla_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_plan_estudiante_pla_codigo' AND object_id = OBJECT_ID('[dbo].[plan_estudiante]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_plan_estudiante_pla_codigo]
    ON [dbo].[plan_estudiante] ([pla_codigo]);
END
GO

-- Índice FK: IX_FK_programa_nia_codigo en [dbo].[programa] ([nia_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_programa_nia_codigo' AND object_id = OBJECT_ID('[dbo].[programa]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_programa_nia_codigo]
    ON [dbo].[programa] ([nia_codigo]);
END
GO

-- Índice FK: IX_FK_programa_sed_codigo en [dbo].[programa] ([sed_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_programa_sed_codigo' AND object_id = OBJECT_ID('[dbo].[programa]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_programa_sed_codigo]
    ON [dbo].[programa] ([sed_codigo]);
END
GO

-- Índice FK: IX_FK_programa_uaa_codigo en [dbo].[programa] ([uaa_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_programa_uaa_codigo' AND object_id = OBJECT_ID('[dbo].[programa]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_programa_uaa_codigo]
    ON [dbo].[programa] ([uaa_codigo]);
END
GO

-- Índice FK: IX_FK_programa_cam_det_codigo en [dbo].[programa] ([cam_det_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_programa_cam_det_codigo' AND object_id = OBJECT_ID('[dbo].[programa]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_programa_cam_det_codigo]
    ON [dbo].[programa] ([cam_det_codigo]);
END
GO

-- Índice FK: IX_FK_proyecto_gru_codigo en [dbo].[proyecto] ([gru_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_proyecto_gru_codigo' AND object_id = OBJECT_ID('[dbo].[proyecto]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_proyecto_gru_codigo]
    ON [dbo].[proyecto] ([gru_codigo]);
END
GO

-- Índice FK: IX_FK_proyecto_pre_codigo en [dbo].[proyecto] ([pre_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_proyecto_pre_codigo' AND object_id = OBJECT_ID('[dbo].[proyecto]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_proyecto_pre_codigo]
    ON [dbo].[proyecto] ([pre_codigo]);
END
GO

-- Índice FK: IX_FK_proyecto_prt_codigo en [dbo].[proyecto] ([prt_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_proyecto_prt_codigo' AND object_id = OBJECT_ID('[dbo].[proyecto]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_proyecto_prt_codigo]
    ON [dbo].[proyecto] ([prt_codigo]);
END
GO

-- Índice FK: IX_FK_sede_mun_codigo en [dbo].[sede] ([mun_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_sede_mun_codigo' AND object_id = OBJECT_ID('[dbo].[sede]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_sede_mun_codigo]
    ON [dbo].[sede] ([mun_codigo]);
END
GO

-- Índice FK: IX_FK_sub_sede_sed_codigo en [dbo].[sub_sede] ([sed_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_sub_sede_sed_codigo' AND object_id = OBJECT_ID('[dbo].[sub_sede]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_sub_sede_sed_codigo]
    ON [dbo].[sub_sede] ([sed_codigo]);
END
GO

-- Índice FK: IX_FK_uaa_sed_codigo en [dbo].[uaa] ([sed_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_uaa_sed_codigo' AND object_id = OBJECT_ID('[dbo].[uaa]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_uaa_sed_codigo]
    ON [dbo].[uaa] ([sed_codigo]);
END
GO

-- Índice FK: IX_FK_uaa_cargo_uac_dedicacion en [dbo].[uaa_cargo] ([uac_dedicacion])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_uaa_cargo_uac_dedicacion' AND object_id = OBJECT_ID('[dbo].[uaa_cargo]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_uaa_cargo_uac_dedicacion]
    ON [dbo].[uaa_cargo] ([uac_dedicacion]);
END
GO

-- Índice FK: IX_FK_uaa_cargo_uac_uaa en [dbo].[uaa_cargo] ([uac_uaa])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_uaa_cargo_uac_uaa' AND object_id = OBJECT_ID('[dbo].[uaa_cargo]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_uaa_cargo_uac_uaa]
    ON [dbo].[uaa_cargo] ([uac_uaa]);
END
GO

-- Índice FK: IX_FK_uaa_cargo_uac_vinculacion en [dbo].[uaa_cargo] ([uac_vinculacion])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_uaa_cargo_uac_vinculacion' AND object_id = OBJECT_ID('[dbo].[uaa_cargo]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_uaa_cargo_uac_vinculacion]
    ON [dbo].[uaa_cargo] ([uac_vinculacion]);
END
GO

-- Índice FK: IX_FK_uaa_personal_per_codigo en [dbo].[uaa_personal] ([per_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_uaa_personal_per_codigo' AND object_id = OBJECT_ID('[dbo].[uaa_personal]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_uaa_personal_per_codigo]
    ON [dbo].[uaa_personal] ([per_codigo]);
END
GO

-- Índice FK: IX_FK_uaa_personal_uaa_codigo en [dbo].[uaa_personal] ([uaa_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_uaa_personal_uaa_codigo' AND object_id = OBJECT_ID('[dbo].[uaa_personal]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_uaa_personal_uaa_codigo]
    ON [dbo].[uaa_personal] ([uaa_codigo]);
END
GO

-- Índice FK: IX_FK_estudiante_per_codigo en [dbo].[estudiante] ([per_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_estudiante_per_codigo' AND object_id = OBJECT_ID('[dbo].[estudiante]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_estudiante_per_codigo]
    ON [dbo].[estudiante] ([per_codigo]);
END
GO

-- Índice FK: IX_FK_grupo_uaa_item_pgr_codigo en [programacionacademica].[grupo_uaa_item] ([pgr_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_grupo_uaa_item_pgr_codigo' AND object_id = OBJECT_ID('[programacionacademica].[grupo_uaa_item]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_grupo_uaa_item_pgr_codigo]
    ON [programacionacademica].[grupo_uaa_item] ([pgr_codigo]);
END
GO

-- Índice FK: IX_FK_grupo_uaa_item_uaa_codigo en [programacionacademica].[grupo_uaa_item] ([uaa_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_grupo_uaa_item_uaa_codigo' AND object_id = OBJECT_ID('[programacionacademica].[grupo_uaa_item]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_grupo_uaa_item_uaa_codigo]
    ON [programacionacademica].[grupo_uaa_item] ([uaa_codigo]);
END
GO

-- Índice FK: IX_FK_periodo_unidad_per_codigo en [programacionacademica].[periodo_unidad] ([per_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_periodo_unidad_per_codigo' AND object_id = OBJECT_ID('[programacionacademica].[periodo_unidad]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_periodo_unidad_per_codigo]
    ON [programacionacademica].[periodo_unidad] ([per_codigo]);
END
GO

-- Índice FK: IX_FK_periodo_unidad_uaa_codigo en [programacionacademica].[periodo_unidad] ([uaa_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_periodo_unidad_uaa_codigo' AND object_id = OBJECT_ID('[programacionacademica].[periodo_unidad]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_periodo_unidad_uaa_codigo]
    ON [programacionacademica].[periodo_unidad] ([uaa_codigo]);
END
GO

-- Índice FK: IX_FK_programacion_academica_cal_codigo en [programacionacademica].[programacion_academica] ([cal_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_programacion_academica_cal_codigo' AND object_id = OBJECT_ID('[programacionacademica].[programacion_academica]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_programacion_academica_cal_codigo]
    ON [programacionacademica].[programacion_academica] ([cal_codigo]);
END
GO

-- Índice FK: IX_FK_programacion_academica_prp_codigo en [programacionacademica].[programacion_academica] ([prp_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_programacion_academica_prp_codigo' AND object_id = OBJECT_ID('[programacionacademica].[programacion_academica]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_programacion_academica_prp_codigo]
    ON [programacionacademica].[programacion_academica] ([prp_codigo]);
END
GO

-- Índice FK: IX_FK_programacion_academica_uaa_codigo en [programacionacademica].[programacion_academica] ([uaa_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_programacion_academica_uaa_codigo' AND object_id = OBJECT_ID('[programacionacademica].[programacion_academica]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_programacion_academica_uaa_codigo]
    ON [programacionacademica].[programacion_academica] ([uaa_codigo]);
END
GO

-- Índice FK: IX_FK_programacion_gestion_cal_codigo en [programacionacademica].[programacion_gestion] ([cal_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_programacion_gestion_cal_codigo' AND object_id = OBJECT_ID('[programacionacademica].[programacion_gestion]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_programacion_gestion_cal_codigo]
    ON [programacionacademica].[programacion_gestion] ([cal_codigo]);
END
GO

-- Índice FK: IX_FK_programacion_gestion_pts_codigo en [programacionacademica].[programacion_gestion] ([pts_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_programacion_gestion_pts_codigo' AND object_id = OBJECT_ID('[programacionacademica].[programacion_gestion]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_programacion_gestion_pts_codigo]
    ON [programacionacademica].[programacion_gestion] ([pts_codigo]);
END
GO

-- Índice FK: IX_FK_programacion_gestion_uaa_codigo en [programacionacademica].[programacion_gestion] ([uaa_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_programacion_gestion_uaa_codigo' AND object_id = OBJECT_ID('[programacionacademica].[programacion_gestion]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_programacion_gestion_uaa_codigo]
    ON [programacionacademica].[programacion_gestion] ([uaa_codigo]);
END
GO

-- Índice FK: IX_FK_solicitud_cambio_horario_cur_codigo en [programacionacademica].[solicitud_cambio_horario] ([cur_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_solicitud_cambio_horario_cur_codigo' AND object_id = OBJECT_ID('[programacionacademica].[solicitud_cambio_horario]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_solicitud_cambio_horario_cur_codigo]
    ON [programacionacademica].[solicitud_cambio_horario] ([cur_codigo]);
END
GO

-- Índice FK: IX_FK_solicitud_cambio_horario_uaa_codigo en [programacionacademica].[solicitud_cambio_horario] ([uaa_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_solicitud_cambio_horario_uaa_codigo' AND object_id = OBJECT_ID('[programacionacademica].[solicitud_cambio_horario]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_solicitud_cambio_horario_uaa_codigo]
    ON [programacionacademica].[solicitud_cambio_horario] ([uaa_codigo]);
END
GO

-- Índice FK: IX_FK_solicitud_cambio_horario_comentario_sch_codigo en [programacionacademica].[solicitud_cambio_horario_comentario] ([sch_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_solicitud_cambio_horario_comentario_sch_codigo' AND object_id = OBJECT_ID('[programacionacademica].[solicitud_cambio_horario_comentario]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_solicitud_cambio_horario_comentario_sch_codigo]
    ON [programacionacademica].[solicitud_cambio_horario_comentario] ([sch_codigo]);
END
GO

-- Índice FK: IX_FK_solicitud_cambio_horario_horario_schh_dia_codigo_anterior en [programacionacademica].[solicitud_cambio_horario_horario] ([schh_dia_codigo_anterior])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_solicitud_cambio_horario_horario_schh_dia_codigo_anterior' AND object_id = OBJECT_ID('[programacionacademica].[solicitud_cambio_horario_horario]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_solicitud_cambio_horario_horario_schh_dia_codigo_anterior]
    ON [programacionacademica].[solicitud_cambio_horario_horario] ([schh_dia_codigo_anterior]);
END
GO

-- Índice FK: IX_FK_solicitud_cambio_horario_horario_schh_dia_codigo_nuevo en [programacionacademica].[solicitud_cambio_horario_horario] ([schh_dia_codigo_nuevo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_solicitud_cambio_horario_horario_schh_dia_codigo_nuevo' AND object_id = OBJECT_ID('[programacionacademica].[solicitud_cambio_horario_horario]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_solicitud_cambio_horario_horario_schh_dia_codigo_nuevo]
    ON [programacionacademica].[solicitud_cambio_horario_horario] ([schh_dia_codigo_nuevo]);
END
GO

-- Índice FK: IX_FK_solicitud_cambio_horario_horario_schh_esp_codigo_anterior en [programacionacademica].[solicitud_cambio_horario_horario] ([schh_esp_codigo_anterior])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_solicitud_cambio_horario_horario_schh_esp_codigo_anterior' AND object_id = OBJECT_ID('[programacionacademica].[solicitud_cambio_horario_horario]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_solicitud_cambio_horario_horario_schh_esp_codigo_anterior]
    ON [programacionacademica].[solicitud_cambio_horario_horario] ([schh_esp_codigo_anterior]);
END
GO

-- Índice FK: IX_FK_solicitud_cambio_horario_horario_schh_esp_codigo_nuevo en [programacionacademica].[solicitud_cambio_horario_horario] ([schh_esp_codigo_nuevo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_solicitud_cambio_horario_horario_schh_esp_codigo_nuevo' AND object_id = OBJECT_ID('[programacionacademica].[solicitud_cambio_horario_horario]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_solicitud_cambio_horario_horario_schh_esp_codigo_nuevo]
    ON [programacionacademica].[solicitud_cambio_horario_horario] ([schh_esp_codigo_nuevo]);
END
GO

-- Índice FK: IX_FK_solicitud_cambio_horario_horario_schh_hra_codigo_anterior en [programacionacademica].[solicitud_cambio_horario_horario] ([schh_hra_codigo_anterior])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_solicitud_cambio_horario_horario_schh_hra_codigo_anterior' AND object_id = OBJECT_ID('[programacionacademica].[solicitud_cambio_horario_horario]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_solicitud_cambio_horario_horario_schh_hra_codigo_anterior]
    ON [programacionacademica].[solicitud_cambio_horario_horario] ([schh_hra_codigo_anterior]);
END
GO

-- Índice FK: IX_FK_solicitud_cambio_horario_horario_schh_hra_codigo_nuevo en [programacionacademica].[solicitud_cambio_horario_horario] ([schh_hra_codigo_nuevo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_solicitud_cambio_horario_horario_schh_hra_codigo_nuevo' AND object_id = OBJECT_ID('[programacionacademica].[solicitud_cambio_horario_horario]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_solicitud_cambio_horario_horario_schh_hra_codigo_nuevo]
    ON [programacionacademica].[solicitud_cambio_horario_horario] ([schh_hra_codigo_nuevo]);
END
GO

-- Índice FK: IX_FK_solicitud_cambio_horario_horario_sch_codigo en [programacionacademica].[solicitud_cambio_horario_horario] ([sch_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_solicitud_cambio_horario_horario_sch_codigo' AND object_id = OBJECT_ID('[programacionacademica].[solicitud_cambio_horario_horario]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_solicitud_cambio_horario_horario_sch_codigo]
    ON [programacionacademica].[solicitud_cambio_horario_horario] ([sch_codigo]);
END
GO

-- Índice FK: IX_FK_solicitud_cambio_horario_horario_schh_uap_codigo_anterior en [programacionacademica].[solicitud_cambio_horario_horario] ([schh_uap_codigo_anterior])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_solicitud_cambio_horario_horario_schh_uap_codigo_anterior' AND object_id = OBJECT_ID('[programacionacademica].[solicitud_cambio_horario_horario]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_solicitud_cambio_horario_horario_schh_uap_codigo_anterior]
    ON [programacionacademica].[solicitud_cambio_horario_horario] ([schh_uap_codigo_anterior]);
END
GO

-- Índice FK: IX_FK_solicitud_cambio_horario_horario_schh_uap_codigo_nuevo en [programacionacademica].[solicitud_cambio_horario_horario] ([schh_uap_codigo_nuevo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_solicitud_cambio_horario_horario_schh_uap_codigo_nuevo' AND object_id = OBJECT_ID('[programacionacademica].[solicitud_cambio_horario_horario]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_solicitud_cambio_horario_horario_schh_uap_codigo_nuevo]
    ON [programacionacademica].[solicitud_cambio_horario_horario] ([schh_uap_codigo_nuevo]);
END
GO

-- Índice FK: IX_FK_solicitud_prestamo_docente_asi_codigo en [programacionacademica].[solicitud_prestamo_docente] ([asi_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_solicitud_prestamo_docente_asi_codigo' AND object_id = OBJECT_ID('[programacionacademica].[solicitud_prestamo_docente]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_solicitud_prestamo_docente_asi_codigo]
    ON [programacionacademica].[solicitud_prestamo_docente] ([asi_codigo]);
END
GO

-- Índice FK: IX_FK_solicitud_prestamo_docente_periodo_codigo en [programacionacademica].[solicitud_prestamo_docente] ([periodo_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_solicitud_prestamo_docente_periodo_codigo' AND object_id = OBJECT_ID('[programacionacademica].[solicitud_prestamo_docente]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_solicitud_prestamo_docente_periodo_codigo]
    ON [programacionacademica].[solicitud_prestamo_docente] ([periodo_codigo]);
END
GO

-- Índice FK: IX_FK_solicitud_prestamo_docente_persona_codigo en [programacionacademica].[solicitud_prestamo_docente] ([persona_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_solicitud_prestamo_docente_persona_codigo' AND object_id = OBJECT_ID('[programacionacademica].[solicitud_prestamo_docente]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_solicitud_prestamo_docente_persona_codigo]
    ON [programacionacademica].[solicitud_prestamo_docente] ([persona_codigo]);
END
GO

-- Índice FK: IX_FK_solicitud_prestamo_docente_sed_codigo en [programacionacademica].[solicitud_prestamo_docente] ([sed_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_solicitud_prestamo_docente_sed_codigo' AND object_id = OBJECT_ID('[programacionacademica].[solicitud_prestamo_docente]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_solicitud_prestamo_docente_sed_codigo]
    ON [programacionacademica].[solicitud_prestamo_docente] ([sed_codigo]);
END
GO

-- Índice FK: IX_FK_solicitud_prestamo_docente_uaa_dirigida en [programacionacademica].[solicitud_prestamo_docente] ([uaa_dirigida])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_solicitud_prestamo_docente_uaa_dirigida' AND object_id = OBJECT_ID('[programacionacademica].[solicitud_prestamo_docente]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_solicitud_prestamo_docente_uaa_dirigida]
    ON [programacionacademica].[solicitud_prestamo_docente] ([uaa_dirigida]);
END
GO

-- Índice FK: IX_FK_solicitud_prestamo_docente_uaa_solicita en [programacionacademica].[solicitud_prestamo_docente] ([uaa_solicita])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_solicitud_prestamo_docente_uaa_solicita' AND object_id = OBJECT_ID('[programacionacademica].[solicitud_prestamo_docente]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_solicitud_prestamo_docente_uaa_solicita]
    ON [programacionacademica].[solicitud_prestamo_docente] ([uaa_solicita]);
END
GO

-- Índice FK: IX_FK_solicitud_prestamo_docente_comentario_spd_codigo en [programacionacademica].[solicitud_prestamo_docente_comentario] ([spd_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_solicitud_prestamo_docente_comentario_spd_codigo' AND object_id = OBJECT_ID('[programacionacademica].[solicitud_prestamo_docente_comentario]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_solicitud_prestamo_docente_comentario_spd_codigo]
    ON [programacionacademica].[solicitud_prestamo_docente_comentario] ([spd_codigo]);
END
GO

-- Índice FK: IX_FK_solicitud_prestamo_docente_horario_dia_codigo en [programacionacademica].[solicitud_prestamo_docente_horario] ([dia_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_solicitud_prestamo_docente_horario_dia_codigo' AND object_id = OBJECT_ID('[programacionacademica].[solicitud_prestamo_docente_horario]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_solicitud_prestamo_docente_horario_dia_codigo]
    ON [programacionacademica].[solicitud_prestamo_docente_horario] ([dia_codigo]);
END
GO

-- Índice FK: IX_FK_solicitud_prestamo_docente_horario_hra_codigo en [programacionacademica].[solicitud_prestamo_docente_horario] ([hra_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_solicitud_prestamo_docente_horario_hra_codigo' AND object_id = OBJECT_ID('[programacionacademica].[solicitud_prestamo_docente_horario]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_solicitud_prestamo_docente_horario_hra_codigo]
    ON [programacionacademica].[solicitud_prestamo_docente_horario] ([hra_codigo]);
END
GO

-- Índice FK: IX_FK_solicitud_prestamo_docente_horario_spd_codigo en [programacionacademica].[solicitud_prestamo_docente_horario] ([spd_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_solicitud_prestamo_docente_horario_spd_codigo' AND object_id = OBJECT_ID('[programacionacademica].[solicitud_prestamo_docente_horario]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_solicitud_prestamo_docente_horario_spd_codigo]
    ON [programacionacademica].[solicitud_prestamo_docente_horario] ([spd_codigo]);
END
GO

-- Índice FK: IX_FK_docentexproyecto_proyeccion_social_nco_codigo en [proyectos].[docentexproyecto_proyeccion_social] ([nco_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_docentexproyecto_proyeccion_social_nco_codigo' AND object_id = OBJECT_ID('[proyectos].[docentexproyecto_proyeccion_social]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_docentexproyecto_proyeccion_social_nco_codigo]
    ON [proyectos].[docentexproyecto_proyeccion_social] ([nco_codigo]);
END
GO

-- Índice FK: IX_FK_docentexproyecto_proyeccion_social_prp_codigo en [proyectos].[docentexproyecto_proyeccion_social] ([prp_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_docentexproyecto_proyeccion_social_prp_codigo' AND object_id = OBJECT_ID('[proyectos].[docentexproyecto_proyeccion_social]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_docentexproyecto_proyeccion_social_prp_codigo]
    ON [proyectos].[docentexproyecto_proyeccion_social] ([prp_codigo]);
END
GO

-- Índice FK: IX_FK_docentexproyecto_proyeccion_social_pps_codigo en [proyectos].[docentexproyecto_proyeccion_social] ([pps_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_docentexproyecto_proyeccion_social_pps_codigo' AND object_id = OBJECT_ID('[proyectos].[docentexproyecto_proyeccion_social]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_docentexproyecto_proyeccion_social_pps_codigo]
    ON [proyectos].[docentexproyecto_proyeccion_social] ([pps_codigo]);
END
GO

-- Índice FK: IX_FK_docentexproyecto_proyeccion_social_uap_codigo en [proyectos].[docentexproyecto_proyeccion_social] ([uap_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_docentexproyecto_proyeccion_social_uap_codigo' AND object_id = OBJECT_ID('[proyectos].[docentexproyecto_proyeccion_social]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_docentexproyecto_proyeccion_social_uap_codigo]
    ON [proyectos].[docentexproyecto_proyeccion_social] ([uap_codigo]);
END
GO

-- Índice FK: IX_FK_proyecto_proyeccion_social_pra_codigo en [proyectos].[proyecto_proyeccion_social] ([pra_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_proyecto_proyeccion_social_pra_codigo' AND object_id = OBJECT_ID('[proyectos].[proyecto_proyeccion_social]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_proyecto_proyeccion_social_pra_codigo]
    ON [proyectos].[proyecto_proyeccion_social] ([pra_codigo]);
END
GO

-- Índice FK: IX_FK_proyecto_proyeccion_social_prc_codigo en [proyectos].[proyecto_proyeccion_social] ([prc_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_proyecto_proyeccion_social_prc_codigo' AND object_id = OBJECT_ID('[proyectos].[proyecto_proyeccion_social]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_proyecto_proyeccion_social_prc_codigo]
    ON [proyectos].[proyecto_proyeccion_social] ([prc_codigo]);
END
GO

-- Índice FK: IX_FK_proyecto_proyeccion_social_mun_codigo en [proyectos].[proyecto_proyeccion_social] ([mun_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_proyecto_proyeccion_social_mun_codigo' AND object_id = OBJECT_ID('[proyectos].[proyecto_proyeccion_social]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_proyecto_proyeccion_social_mun_codigo]
    ON [proyectos].[proyecto_proyeccion_social] ([mun_codigo]);
END
GO

-- Índice FK: IX_FK_proyecto_proyeccion_social_nco_codigo en [proyectos].[proyecto_proyeccion_social] ([nco_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_proyecto_proyeccion_social_nco_codigo' AND object_id = OBJECT_ID('[proyectos].[proyecto_proyeccion_social]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_proyecto_proyeccion_social_nco_codigo]
    ON [proyectos].[proyecto_proyeccion_social] ([nco_codigo]);
END
GO

-- Índice FK: IX_FK_proyecto_proyeccion_social_oap_codigo en [proyectos].[proyecto_proyeccion_social] ([oap_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_proyecto_proyeccion_social_oap_codigo' AND object_id = OBJECT_ID('[proyectos].[proyecto_proyeccion_social]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_proyecto_proyeccion_social_oap_codigo]
    ON [proyectos].[proyecto_proyeccion_social] ([oap_codigo]);
END
GO

-- Índice FK: IX_FK_proyecto_proyeccion_social_otp_codigo en [proyectos].[proyecto_proyeccion_social] ([otp_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_proyecto_proyeccion_social_otp_codigo' AND object_id = OBJECT_ID('[proyectos].[proyecto_proyeccion_social]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_proyecto_proyeccion_social_otp_codigo]
    ON [proyectos].[proyecto_proyeccion_social] ([otp_codigo]);
END
GO

-- Índice FK: IX_FK_proyecto_proyeccion_social_pst_codigo en [proyectos].[proyecto_proyeccion_social] ([pst_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_proyecto_proyeccion_social_pst_codigo' AND object_id = OBJECT_ID('[proyectos].[proyecto_proyeccion_social]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_proyecto_proyeccion_social_pst_codigo]
    ON [proyectos].[proyecto_proyeccion_social] ([pst_codigo]);
END
GO

-- Índice FK: IX_FK_proyecto_proyeccion_social_pps_semillero en [proyectos].[proyecto_proyeccion_social] ([pps_semillero])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_proyecto_proyeccion_social_pps_semillero' AND object_id = OBJECT_ID('[proyectos].[proyecto_proyeccion_social]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_proyecto_proyeccion_social_pps_semillero]
    ON [proyectos].[proyecto_proyeccion_social] ([pps_semillero]);
END
GO

-- Índice FK: IX_FK_proyecto_proyeccion_social_are_codigo en [proyectos].[proyecto_proyeccion_social] ([are_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_proyecto_proyeccion_social_are_codigo' AND object_id = OBJECT_ID('[proyectos].[proyecto_proyeccion_social]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_proyecto_proyeccion_social_are_codigo]
    ON [proyectos].[proyecto_proyeccion_social] ([are_codigo]);
END
GO

-- Índice FK: IX_FK_proyecto_proyeccion_social_stp_codigo en [proyectos].[proyecto_proyeccion_social] ([stp_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_proyecto_proyeccion_social_stp_codigo' AND object_id = OBJECT_ID('[proyectos].[proyecto_proyeccion_social]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_proyecto_proyeccion_social_stp_codigo]
    ON [proyectos].[proyecto_proyeccion_social] ([stp_codigo]);
END
GO

-- Índice FK: IX_FK_curso_cal_codigo en [dbo].[curso] ([cal_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_curso_cal_codigo' AND object_id = OBJECT_ID('[dbo].[curso]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_curso_cal_codigo]
    ON [dbo].[curso] ([cal_codigo]);
END
GO

-- Índice FK: IX_FK_curso_sed_codigo en [dbo].[curso] ([sed_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_curso_sed_codigo' AND object_id = OBJECT_ID('[dbo].[curso]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_curso_sed_codigo]
    ON [dbo].[curso] ([sed_codigo]);
END
GO

-- Índice FK: IX_FK_curso_cut_codigo en [dbo].[curso] ([cut_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_curso_cut_codigo' AND object_id = OBJECT_ID('[dbo].[curso]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_curso_cut_codigo]
    ON [dbo].[curso] ([cut_codigo]);
END
GO

-- Índice FK: IX_FK_curso_tic_codigo en [dbo].[curso] ([tic_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_curso_tic_codigo' AND object_id = OBJECT_ID('[dbo].[curso]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_curso_tic_codigo]
    ON [dbo].[curso] ([tic_codigo]);
END
GO

-- Índice FK: IX_FK_curso_pla_codigo en [dbo].[curso] ([pla_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_curso_pla_codigo' AND object_id = OBJECT_ID('[dbo].[curso]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_curso_pla_codigo]
    ON [dbo].[curso] ([pla_codigo]);
END
GO

-- Índice FK: IX_FK_curso_tes_codigo en [dbo].[curso] ([tes_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_curso_tes_codigo' AND object_id = OBJECT_ID('[dbo].[curso]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_curso_tes_codigo]
    ON [dbo].[curso] ([tes_codigo]);
END
GO

-- Índice FK: IX_FK_programacion_proceso_nuc_codigo en [dbo].[programacion_proceso] ([nuc_codigo])
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FK_programacion_proceso_nuc_codigo' AND object_id = OBJECT_ID('[dbo].[programacion_proceso]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_FK_programacion_proceso_nuc_codigo]
    ON [dbo].[programacion_proceso] ([nuc_codigo]);
END
GO


-- ============================================================================
-- SECCIÓN 2: ÍNDICES COMPUESTOS Y CUBRIENTES PARA CONSULTAS DE ALTA FRECUENCIA
-- (Optimización dirigida para resolver el cuello de botella de 178 loops N+1)
-- ============================================================================

-- Búsqueda y cruce de horarios por curso, día y hora con columnas cubrientes
-- Índice: IX_espacio_ocupacion_actividad_dia_hora_inc en [dbo].[espacio_ocupacion]
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_espacio_ocupacion_actividad_dia_hora_inc' AND object_id = OBJECT_ID('[dbo].[espacio_ocupacion]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_espacio_ocupacion_actividad_dia_hora_inc]
    ON [dbo].[espacio_ocupacion] ([eso_actividad], [dia_codigo], [hra_codigo])
    INCLUDE ([esp_codigo], [eso_estado], [uaa_codigo]);
END
GO

-- Validación de colisión y ocupación de aula física por periodo
-- Índice: IX_espacio_ocupacion_espacio_dia_hora_inc en [dbo].[espacio_ocupacion]
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_espacio_ocupacion_espacio_dia_hora_inc' AND object_id = OBJECT_ID('[dbo].[espacio_ocupacion]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_espacio_ocupacion_espacio_dia_hora_inc]
    ON [dbo].[espacio_ocupacion] ([esp_codigo], [dia_codigo], [hra_codigo])
    INCLUDE ([eso_actividad], [eso_estado], [eso_codigo]);
END
GO

-- Extracción masiva de ocupación activa por periodo lectivo
-- Índice: IX_espacio_ocupacion_periodo_estado_inc en [dbo].[espacio_ocupacion]
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_espacio_ocupacion_periodo_estado_inc' AND object_id = OBJECT_ID('[dbo].[espacio_ocupacion]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_espacio_ocupacion_periodo_estado_inc]
    ON [dbo].[espacio_ocupacion] ([eso_fecha], [eso_estado])
    INCLUDE ([esp_codigo], [dia_codigo], [hra_codigo], [eso_actividad]);
END
GO

-- Búsqueda de oferta de asignaturas por calendario y estado
-- Índice: IX_curso_asignatura_calendario_estado_inc en [dbo].[curso]
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_curso_asignatura_calendario_estado_inc' AND object_id = OBJECT_ID('[dbo].[curso]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_curso_asignatura_calendario_estado_inc]
    ON [dbo].[curso] ([asi_codigo], [cal_codigo], [cur_estado])
    INCLUDE ([cur_codigo], [cur_grupo], [cur_cupo], [uap_codigo], [sed_codigo]);
END
GO

-- Consulta de asignación de carga docente a cursos
-- Índice: IX_curso_uaa_personal_calendario_inc en [dbo].[curso]
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_curso_uaa_personal_calendario_inc' AND object_id = OBJECT_ID('[dbo].[curso]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_curso_uaa_personal_calendario_inc]
    ON [dbo].[curso] ([uap_codigo], [cal_codigo])
    INCLUDE ([cur_codigo], [asi_codigo], [cur_grupo], [cur_estado]);
END
GO

-- Búsqueda inmediata de personas por documento de identificación
-- Índice: IX_persona_identificacion_inc en [dbo].[persona]
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_persona_identificacion_inc' AND object_id = OBJECT_ID('[dbo].[persona]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_persona_identificacion_inc]
    ON [dbo].[persona] ([per_identificacion])
    INCLUDE ([per_codigo], [per_nombre], [per_apellido], [per_email]);
END
GO

-- Búsqueda y ordenamiento alfabético de docentes y estudiantes
-- Índice: IX_persona_apellidos_nombres_inc en [dbo].[persona]
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_persona_apellidos_nombres_inc' AND object_id = OBJECT_ID('[dbo].[persona]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_persona_apellidos_nombres_inc]
    ON [dbo].[persona] ([per_apellido], [per_nombre])
    INCLUDE ([per_codigo], [per_identificacion]);
END
GO

-- Vinculación institucional de personas por unidad académica
-- Índice: IX_uaa_personal_persona_uaa_inc en [dbo].[uaa_personal]
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_uaa_personal_persona_uaa_inc' AND object_id = OBJECT_ID('[dbo].[uaa_personal]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_uaa_personal_persona_uaa_inc]
    ON [dbo].[uaa_personal] ([per_codigo], [uaa_codigo])
    INCLUDE ([uap_codigo], [uap_estado], [uap_cargo], [vin_codigo], [ded_codigo]);
END
GO

-- Validación de asignaturas en la malla curricular
-- Índice: IX_plan_academico_asignatura_pla_asi_inc en [dbo].[plan_academico_asignatura]
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_plan_academico_asignatura_pla_asi_inc' AND object_id = OBJECT_ID('[dbo].[plan_academico_asignatura]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_plan_academico_asignatura_pla_asi_inc]
    ON [dbo].[plan_academico_asignatura] ([pla_codigo], [asi_codigo])
    INCLUDE ([paa_codigo], [paa_semestre], [paa_credito]);
END
GO

-- Control de subgrupos y cupos de laboratorio
-- Índice: IX_curso_cupo_subgrupo_curso_inc en [dbo].[curso_cupo_subgrupo]
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_curso_cupo_subgrupo_curso_inc' AND object_id = OBJECT_ID('[dbo].[curso_cupo_subgrupo]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_curso_cupo_subgrupo_curso_inc]
    ON [dbo].[curso_cupo_subgrupo] ([cur_codigo])
    INCLUDE ([cus_cod], [eso_subgrupo], [cus_cupo], [cus_estado]);
END
GO

-- Verificación de ventanas de apertura de programación académica
-- Índice: IX_programacion_academica_uaa_cal_prp_inc en [programacionacademica].[programacion_academica]
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_programacion_academica_uaa_cal_prp_inc' AND object_id = OBJECT_ID('[programacionacademica].[programacion_academica]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_programacion_academica_uaa_cal_prp_inc]
    ON [programacionacademica].[programacion_academica] ([uaa_codigo], [cal_codigo], [prp_codigo], [pra_estado])
    INCLUDE ([pra_codigo], [pra_fecha_inicio], [pra_fecha_fin]);
END
GO

-- Verificación de periodo habilitado para secretarías
-- Índice: IX_programacion_gestion_uaa_cal_inc en [programacionacademica].[programacion_gestion]
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_programacion_gestion_uaa_cal_inc' AND object_id = OBJECT_ID('[programacionacademica].[programacion_gestion]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_programacion_gestion_uaa_cal_inc]
    ON [programacionacademica].[programacion_gestion] ([uaa_codigo], [cal_codigo], [prg_estado])
    INCLUDE ([prg_codigo], [prg_fecha_inicio], [prg_fecha_fin]);
END
GO

-- Verificación de vigencia de periodos por unidad
-- Índice: IX_periodo_unidad_uaa_per_inc en [programacionacademica].[periodo_unidad]
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_periodo_unidad_uaa_per_inc' AND object_id = OBJECT_ID('[programacionacademica].[periodo_unidad]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_periodo_unidad_uaa_per_inc]
    ON [programacionacademica].[periodo_unidad] ([uaa_codigo], [per_codigo], [peu_estado])
    INCLUDE ([peu_codigo], [peu_fecha_inicio], [peu_fecha_fin]);
END
GO

-- Búsqueda de solicitudes de cambio de horario pendientes por curso
-- Índice: IX_solicitud_cambio_horario_curso_estado_inc en [programacionacademica].[solicitud_cambio_horario]
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_solicitud_cambio_horario_curso_estado_inc' AND object_id = OBJECT_ID('[programacionacademica].[solicitud_cambio_horario]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_solicitud_cambio_horario_curso_estado_inc]
    ON [programacionacademica].[solicitud_cambio_horario] ([cur_codigo], [sch_estado])
    INCLUDE ([sch_codigo], [sch_fecha_creacion], [usu_codigo]);
END
GO

-- Detalle de franjas horarias solicitadas en cambio de horario
-- Índice: IX_solicitud_cambio_horario_horario_sch_inc en [programacionacademica].[solicitud_cambio_horario_horario]
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_solicitud_cambio_horario_horario_sch_inc' AND object_id = OBJECT_ID('[programacionacademica].[solicitud_cambio_horario_horario]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_solicitud_cambio_horario_horario_sch_inc]
    ON [programacionacademica].[solicitud_cambio_horario_horario] ([sch_codigo])
    INCLUDE ([schh_codigo], [schh_estado], [schh_subgrupo], [schh_dia_codigo_nuevo], [schh_hra_codigo_nuevo], [schh_esp_codigo_nuevo]);
END
GO

-- Búsqueda de solicitudes de préstamo docente por docente y calendario
-- Índice: IX_solicitud_prestamo_docente_doc_cal_estado_inc en [programacionacademica].[solicitud_prestamo_docente]
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_solicitud_prestamo_docente_doc_cal_estado_inc' AND object_id = OBJECT_ID('[programacionacademica].[solicitud_prestamo_docente]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_solicitud_prestamo_docente_doc_cal_estado_inc]
    ON [programacionacademica].[solicitud_prestamo_docente] ([persona_codigo], [periodo_codigo], [spd_estado])
    INCLUDE ([spd_codigo], [asi_codigo], [uaa_solicita], [uaa_dirigida], [aud_fecha_creacion]);
END
GO

-- Franjas horarias de préstamo docente
-- Índice: IX_solicitud_prestamo_docente_horario_spd_inc en [programacionacademica].[solicitud_prestamo_docente_horario]
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_solicitud_prestamo_docente_horario_spd_inc' AND object_id = OBJECT_ID('[programacionacademica].[solicitud_prestamo_docente_horario]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_solicitud_prestamo_docente_horario_spd_inc]
    ON [programacionacademica].[solicitud_prestamo_docente_horario] ([spd_codigo])
    INCLUDE ([spdh_codigo], [dia_codigo], [hra_codigo], [spdh_estado]);
END
GO
