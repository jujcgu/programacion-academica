-- ============================================================================
-- ARTEFACTO: 04_foreign_keys.sql
-- DESCRIPCIÓN: Integridad referencial completa del sistema (Claves foráneas normalizadas y confiables)
-- PROYECTO: Sistema de Programación Académica (p_academica-main)
-- MOTOR OBJETIVO: Microsoft SQL Server 2016+ / Azure SQL Database / T-SQL ANSI
-- ============================================================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- ============================================================================
-- SECCIÓN 1: CLAVES FORÁNEAS EXISTENTES CONVERTIDAS A CONFIABLES (WITH CHECK)
-- (Se eliminan los 26 WITH NOCHECK originales para permitir optimización de consultas)
-- ============================================================================

-- Clave foránea: FK_asignatura_nucleo (dbo.asignatura -> dbo.nucleo)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_asignatura_nucleo')
BEGIN
    ALTER TABLE [dbo].[asignatura] WITH CHECK
    ADD CONSTRAINT [FK_asignatura_nucleo] FOREIGN KEY ([nuc_codigo])
    REFERENCES [dbo].[nucleo] ([nuc_codigo]);
END
GO
ALTER TABLE [dbo].[asignatura] CHECK CONSTRAINT [FK_asignatura_nucleo];
GO

-- Clave foránea: FK_asignatura_uaa (dbo.asignatura -> dbo.uaa)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_asignatura_uaa')
BEGIN
    ALTER TABLE [dbo].[asignatura] WITH CHECK
    ADD CONSTRAINT [FK_asignatura_uaa] FOREIGN KEY ([uaa_codigo])
    REFERENCES [dbo].[uaa] ([uaa_codigo]);
END
GO
ALTER TABLE [dbo].[asignatura] CHECK CONSTRAINT [FK_asignatura_uaa];
GO

-- Clave foránea: FK_bloque_sub_sede (dbo.bloque -> dbo.sub_sede)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_bloque_sub_sede')
BEGIN
    ALTER TABLE [dbo].[bloque] WITH CHECK
    ADD CONSTRAINT [FK_bloque_sub_sede] FOREIGN KEY ([sus_codigo])
    REFERENCES [dbo].[sub_sede] ([sus_codigo]);
END
GO
ALTER TABLE [dbo].[bloque] CHECK CONSTRAINT [FK_bloque_sub_sede];
GO

-- Clave foránea: FK_calendario_periodo (dbo.calendario -> dbo.periodo)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_calendario_periodo')
BEGIN
    ALTER TABLE [dbo].[calendario] WITH CHECK
    ADD CONSTRAINT [FK_calendario_periodo] FOREIGN KEY ([per_codigo])
    REFERENCES [dbo].[periodo] ([per_codigo]);
END
GO
ALTER TABLE [dbo].[calendario] CHECK CONSTRAINT [FK_calendario_periodo];
GO

-- Clave foránea: FK_cupo_autorizacion_curso (dbo.cupo_autorizacion -> dbo.curso)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_cupo_autorizacion_curso')
BEGIN
    ALTER TABLE [dbo].[cupo_autorizacion] WITH CHECK
    ADD CONSTRAINT [FK_cupo_autorizacion_curso] FOREIGN KEY ([cua_curso])
    REFERENCES [dbo].[curso] ([cur_codigo]);
END
GO
ALTER TABLE [dbo].[cupo_autorizacion] CHECK CONSTRAINT [FK_cupo_autorizacion_curso];
GO

-- Clave foránea: FK_curso_asignatura (dbo.curso -> dbo.asignatura)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_curso_asignatura')
BEGIN
    ALTER TABLE [dbo].[curso] WITH CHECK
    ADD CONSTRAINT [FK_curso_asignatura] FOREIGN KEY ([asi_codigo])
    REFERENCES [dbo].[asignatura] ([asi_codigo]);
END
GO
ALTER TABLE [dbo].[curso] CHECK CONSTRAINT [FK_curso_asignatura];
GO

-- Clave foránea: FK_curso_uaa_personal (dbo.curso -> dbo.uaa_personal)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_curso_uaa_personal')
BEGIN
    ALTER TABLE [dbo].[curso] WITH CHECK
    ADD CONSTRAINT [FK_curso_uaa_personal] FOREIGN KEY ([uap_codigo])
    REFERENCES [dbo].[uaa_personal] ([uap_codigo]);
END
GO
ALTER TABLE [dbo].[curso] CHECK CONSTRAINT [FK_curso_uaa_personal];
GO

-- Clave foránea: FK_curso_institucion_ejecucion_curso_cur_codigo (dbo.curso_institucion_ejecucion -> dbo.curso)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_curso_institucion_ejecucion_curso_cur_codigo')
BEGIN
    ALTER TABLE [dbo].[curso_institucion_ejecucion] WITH CHECK
    ADD CONSTRAINT [FK_curso_institucion_ejecucion_curso_cur_codigo] FOREIGN KEY ([cur_codigo])
    REFERENCES [dbo].[curso] ([cur_codigo]);
END
GO
ALTER TABLE [dbo].[curso_institucion_ejecucion] CHECK CONSTRAINT [FK_curso_institucion_ejecucion_curso_cur_codigo];
GO

-- Clave foránea: FK__curso_ins__esp_c__44EEF70B (dbo.curso_institucion_ejecucion -> dbo.espacio)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK__curso_ins__esp_c__44EEF70B')
BEGIN
    ALTER TABLE [dbo].[curso_institucion_ejecucion] WITH CHECK
    ADD CONSTRAINT [FK__curso_ins__esp_c__44EEF70B] FOREIGN KEY ([esp_codigo])
    REFERENCES [dbo].[espacio] ([esp_codigo]);
END
GO
ALTER TABLE [dbo].[curso_institucion_ejecucion] CHECK CONSTRAINT [FK__curso_ins__esp_c__44EEF70B];
GO

-- Clave foránea: FK_curso_institucion_ejecucion_municipio_mun_codigo (dbo.curso_institucion_ejecucion -> dbo.municipio)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_curso_institucion_ejecucion_municipio_mun_codigo')
BEGIN
    ALTER TABLE [dbo].[curso_institucion_ejecucion] WITH CHECK
    ADD CONSTRAINT [FK_curso_institucion_ejecucion_municipio_mun_codigo] FOREIGN KEY ([mun_codigo])
    REFERENCES [dbo].[municipio] ([mun_codigo]);
END
GO
ALTER TABLE [dbo].[curso_institucion_ejecucion] CHECK CONSTRAINT [FK_curso_institucion_ejecucion_municipio_mun_codigo];
GO

-- Clave foránea: FK_curso_plan_curso (dbo.curso_plan -> dbo.curso)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_curso_plan_curso')
BEGIN
    ALTER TABLE [dbo].[curso_plan] WITH CHECK
    ADD CONSTRAINT [FK_curso_plan_curso] FOREIGN KEY ([cur_codigo])
    REFERENCES [dbo].[curso] ([cur_codigo]);
END
GO
ALTER TABLE [dbo].[curso_plan] CHECK CONSTRAINT [FK_curso_plan_curso];
GO

-- Clave foránea: FK_departamento_pais (dbo.departamento -> dbo.pais)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_departamento_pais')
BEGIN
    ALTER TABLE [dbo].[departamento] WITH CHECK
    ADD CONSTRAINT [FK_departamento_pais] FOREIGN KEY ([pai_codigo])
    REFERENCES [dbo].[pais] ([pai_codigo]);
END
GO
ALTER TABLE [dbo].[departamento] CHECK CONSTRAINT [FK_departamento_pais];
GO

-- Clave foránea: FK_docente_escalafon_escalafon (dbo.docente_escalafon -> dbo.escalafon)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_docente_escalafon_escalafon')
BEGIN
    ALTER TABLE [dbo].[docente_escalafon] WITH CHECK
    ADD CONSTRAINT [FK_docente_escalafon_escalafon] FOREIGN KEY ([esc_codigo])
    REFERENCES [dbo].[escalafon] ([esc_codigo]);
END
GO
ALTER TABLE [dbo].[docente_escalafon] CHECK CONSTRAINT [FK_docente_escalafon_escalafon];
GO

-- Clave foránea: FK_docente_escalafon_persona (dbo.docente_escalafon -> dbo.persona)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_docente_escalafon_persona')
BEGIN
    ALTER TABLE [dbo].[docente_escalafon] WITH CHECK
    ADD CONSTRAINT [FK_docente_escalafon_persona] FOREIGN KEY ([per_codigo])
    REFERENCES [dbo].[persona] ([per_codigo]);
END
GO
ALTER TABLE [dbo].[docente_escalafon] CHECK CONSTRAINT [FK_docente_escalafon_persona];
GO

-- Clave foránea: FK_espacio_espacio_tipo (dbo.espacio -> dbo.espacio_tipo)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_espacio_espacio_tipo')
BEGIN
    ALTER TABLE [dbo].[espacio] WITH CHECK
    ADD CONSTRAINT [FK_espacio_espacio_tipo] FOREIGN KEY ([eti_codigo])
    REFERENCES [dbo].[espacio_tipo] ([eti_codigo]);
END
GO
ALTER TABLE [dbo].[espacio] CHECK CONSTRAINT [FK_espacio_espacio_tipo];
GO

-- Clave foránea: FK_espacio_municipio (dbo.espacio -> dbo.municipio)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_espacio_municipio')
BEGIN
    ALTER TABLE [dbo].[espacio] WITH CHECK
    ADD CONSTRAINT [FK_espacio_municipio] FOREIGN KEY ([mun_codigo])
    REFERENCES [dbo].[municipio] ([mun_codigo]);
END
GO
ALTER TABLE [dbo].[espacio] CHECK CONSTRAINT [FK_espacio_municipio];
GO

-- Clave foránea: FK_espacio_ocupacion_curso (dbo.espacio_ocupacion -> dbo.curso)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_espacio_ocupacion_curso')
BEGIN
    ALTER TABLE [dbo].[espacio_ocupacion] WITH CHECK
    ADD CONSTRAINT [FK_espacio_ocupacion_curso] FOREIGN KEY ([eso_actividad])
    REFERENCES [dbo].[curso] ([cur_codigo]);
END
GO
ALTER TABLE [dbo].[espacio_ocupacion] CHECK CONSTRAINT [FK_espacio_ocupacion_curso];
GO

-- Clave foránea: FK_espacio_ocupacion_espacio (dbo.espacio_ocupacion -> dbo.espacio)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_espacio_ocupacion_espacio')
BEGIN
    ALTER TABLE [dbo].[espacio_ocupacion] WITH CHECK
    ADD CONSTRAINT [FK_espacio_ocupacion_espacio] FOREIGN KEY ([esp_codigo])
    REFERENCES [dbo].[espacio] ([esp_codigo]);
END
GO
ALTER TABLE [dbo].[espacio_ocupacion] CHECK CONSTRAINT [FK_espacio_ocupacion_espacio];
GO

-- Clave foránea: FK_espacio_ocupacion_hora1 (dbo.espacio_ocupacion -> dbo.hora)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_espacio_ocupacion_hora1')
BEGIN
    ALTER TABLE [dbo].[espacio_ocupacion] WITH CHECK
    ADD CONSTRAINT [FK_espacio_ocupacion_hora1] FOREIGN KEY ([hra_codigo])
    REFERENCES [dbo].[hora] ([hra_codigo]);
END
GO
ALTER TABLE [dbo].[espacio_ocupacion] CHECK CONSTRAINT [FK_espacio_ocupacion_hora1];
GO

-- Clave foránea: FK_espacio_ocupacion_horario1 (dbo.espacio_ocupacion -> dbo.horario)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_espacio_ocupacion_horario1')
BEGIN
    ALTER TABLE [dbo].[espacio_ocupacion] WITH CHECK
    ADD CONSTRAINT [FK_espacio_ocupacion_horario1] FOREIGN KEY ([hor_codigo])
    REFERENCES [dbo].[horario] ([hor_codigo]);
END
GO
ALTER TABLE [dbo].[espacio_ocupacion] CHECK CONSTRAINT [FK_espacio_ocupacion_horario1];
GO

-- Clave foránea: FK_espacio_ocupacion_ocupacion_tipo (dbo.espacio_ocupacion -> dbo.ocupacion_tipo)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_espacio_ocupacion_ocupacion_tipo')
BEGIN
    ALTER TABLE [dbo].[espacio_ocupacion] WITH CHECK
    ADD CONSTRAINT [FK_espacio_ocupacion_ocupacion_tipo] FOREIGN KEY ([oct_codigo])
    REFERENCES [dbo].[ocupacion_tipo] ([oct_codigo]);
END
GO
ALTER TABLE [dbo].[espacio_ocupacion] CHECK CONSTRAINT [FK_espacio_ocupacion_ocupacion_tipo];
GO

-- Clave foránea: FK_espacio_ocupacion_uaa_agosto2018 (dbo.espacio_ocupacion -> dbo.uaa)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_espacio_ocupacion_uaa_agosto2018')
BEGIN
    ALTER TABLE [dbo].[espacio_ocupacion] WITH CHECK
    ADD CONSTRAINT [FK_espacio_ocupacion_uaa_agosto2018] FOREIGN KEY ([uaa_codigo])
    REFERENCES [dbo].[uaa] ([uaa_codigo]);
END
GO
ALTER TABLE [dbo].[espacio_ocupacion] CHECK CONSTRAINT [FK_espacio_ocupacion_uaa_agosto2018];
GO

-- Clave foránea: FK_hora_horario (dbo.hora -> dbo.horario)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_hora_horario')
BEGIN
    ALTER TABLE [dbo].[hora] WITH CHECK
    ADD CONSTRAINT [FK_hora_horario] FOREIGN KEY ([hra_codigo])
    REFERENCES [dbo].[horario] ([hor_codigo]);
END
GO
ALTER TABLE [dbo].[hora] CHECK CONSTRAINT [FK_hora_horario];
GO

-- Clave foránea: FK_matricula_calendario (dbo.matricula -> dbo.calendario)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_matricula_calendario')
BEGIN
    ALTER TABLE [dbo].[matricula] WITH CHECK
    ADD CONSTRAINT [FK_matricula_calendario] FOREIGN KEY ([cal_codigo])
    REFERENCES [dbo].[calendario] ([cal_codigo]);
END
GO
ALTER TABLE [dbo].[matricula] CHECK CONSTRAINT [FK_matricula_calendario];
GO

-- Clave foránea: FK_matricula_estudiante_agosto2018 (dbo.matricula -> dbo.estudiante)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_matricula_estudiante_agosto2018')
BEGIN
    ALTER TABLE [dbo].[matricula] WITH CHECK
    ADD CONSTRAINT [FK_matricula_estudiante_agosto2018] FOREIGN KEY ([est_codigo])
    REFERENCES [dbo].[estudiante] ([est_codigo]);
END
GO
ALTER TABLE [dbo].[matricula] CHECK CONSTRAINT [FK_matricula_estudiante_agosto2018];
GO

-- Clave foránea: FK_matricula_matricula_tipo_agosto2018 (dbo.matricula -> dbo.matricula_tipo)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_matricula_matricula_tipo_agosto2018')
BEGIN
    ALTER TABLE [dbo].[matricula] WITH CHECK
    ADD CONSTRAINT [FK_matricula_matricula_tipo_agosto2018] FOREIGN KEY ([mat_tipo])
    REFERENCES [dbo].[matricula_tipo] ([mat_tipo_codigo]);
END
GO
ALTER TABLE [dbo].[matricula] CHECK CONSTRAINT [FK_matricula_matricula_tipo_agosto2018];
GO

-- Clave foránea: FK_matricula_configuracion_plan_academico (dbo.matricula_configuracion -> dbo.plan_academico)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_matricula_configuracion_plan_academico')
BEGIN
    ALTER TABLE [dbo].[matricula_configuracion] WITH CHECK
    ADD CONSTRAINT [FK_matricula_configuracion_plan_academico] FOREIGN KEY ([pla_codigo])
    REFERENCES [dbo].[plan_academico] ([pla_codigo]);
END
GO
ALTER TABLE [dbo].[matricula_configuracion] CHECK CONSTRAINT [FK_matricula_configuracion_plan_academico];
GO

-- Clave foránea: FK_matricula_configuracion_detalle_curso (dbo.matricula_configuracion_detalle -> dbo.curso)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_matricula_configuracion_detalle_curso')
BEGIN
    ALTER TABLE [dbo].[matricula_configuracion_detalle] WITH CHECK
    ADD CONSTRAINT [FK_matricula_configuracion_detalle_curso] FOREIGN KEY ([cur_codigo])
    REFERENCES [dbo].[curso] ([cur_codigo]);
END
GO
ALTER TABLE [dbo].[matricula_configuracion_detalle] CHECK CONSTRAINT [FK_matricula_configuracion_detalle_curso];
GO

-- Clave foránea: FK_matricula_configuracion_detalle_matricula_configuracion (dbo.matricula_configuracion_detalle -> dbo.matricula_configuracion)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_matricula_configuracion_detalle_matricula_configuracion')
BEGIN
    ALTER TABLE [dbo].[matricula_configuracion_detalle] WITH CHECK
    ADD CONSTRAINT [FK_matricula_configuracion_detalle_matricula_configuracion] FOREIGN KEY ([mco_codigo])
    REFERENCES [dbo].[matricula_configuracion] ([mco_codigo]);
END
GO
ALTER TABLE [dbo].[matricula_configuracion_detalle] CHECK CONSTRAINT [FK_matricula_configuracion_detalle_matricula_configuracion];
GO

-- Clave foránea: FK_matricula_configuracion_detalle_plan_academico_asignatura (dbo.matricula_configuracion_detalle -> dbo.plan_academico_asignatura)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_matricula_configuracion_detalle_plan_academico_asignatura')
BEGIN
    ALTER TABLE [dbo].[matricula_configuracion_detalle] WITH CHECK
    ADD CONSTRAINT [FK_matricula_configuracion_detalle_plan_academico_asignatura] FOREIGN KEY ([paa_codigo])
    REFERENCES [dbo].[plan_academico_asignatura] ([paa_codigo]);
END
GO
ALTER TABLE [dbo].[matricula_configuracion_detalle] CHECK CONSTRAINT [FK_matricula_configuracion_detalle_plan_academico_asignatura];
GO

-- Clave foránea: FK_nivel_academico_nivel_academico_tipo (dbo.nivel_academico -> dbo.nivel_academico_tipo)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_nivel_academico_nivel_academico_tipo')
BEGIN
    ALTER TABLE [dbo].[nivel_academico] WITH CHECK
    ADD CONSTRAINT [FK_nivel_academico_nivel_academico_tipo] FOREIGN KEY ([nat_codigo])
    REFERENCES [dbo].[nivel_academico_tipo] ([nat_codigo]);
END
GO
ALTER TABLE [dbo].[nivel_academico] CHECK CONSTRAINT [FK_nivel_academico_nivel_academico_tipo];
GO

-- Clave foránea: FK_novedad_novedad_tipo (dbo.novedad -> dbo.novedad_tipo)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_novedad_novedad_tipo')
BEGIN
    ALTER TABLE [dbo].[novedad] WITH CHECK
    ADD CONSTRAINT [FK_novedad_novedad_tipo] FOREIGN KEY ([not_codigo])
    REFERENCES [dbo].[novedad_tipo] ([not_codigo]);
END
GO
ALTER TABLE [dbo].[novedad] CHECK CONSTRAINT [FK_novedad_novedad_tipo];
GO

-- Clave foránea: FK_periodo_periodo_tipo (dbo.periodo -> dbo.periodo_tipo)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_periodo_periodo_tipo')
BEGIN
    ALTER TABLE [dbo].[periodo] WITH CHECK
    ADD CONSTRAINT [FK_periodo_periodo_tipo] FOREIGN KEY ([pet_codigo])
    REFERENCES [dbo].[periodo_tipo] ([pet_codigo]);
END
GO
ALTER TABLE [dbo].[periodo] CHECK CONSTRAINT [FK_periodo_periodo_tipo];
GO

-- Clave foránea: FK_persona_novedad_novedad (dbo.persona_novedad -> dbo.novedad)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_persona_novedad_novedad')
BEGIN
    ALTER TABLE [dbo].[persona_novedad] WITH CHECK
    ADD CONSTRAINT [FK_persona_novedad_novedad] FOREIGN KEY ([nov_codigo])
    REFERENCES [dbo].[novedad] ([nov_codigo]);
END
GO
ALTER TABLE [dbo].[persona_novedad] CHECK CONSTRAINT [FK_persona_novedad_novedad];
GO

-- Clave foránea: FK_persona_novedad_persona (dbo.persona_novedad -> dbo.persona)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_persona_novedad_persona')
BEGIN
    ALTER TABLE [dbo].[persona_novedad] WITH CHECK
    ADD CONSTRAINT [FK_persona_novedad_persona] FOREIGN KEY ([pen_persona])
    REFERENCES [dbo].[persona] ([per_codigo]);
END
GO
ALTER TABLE [dbo].[persona_novedad] CHECK CONSTRAINT [FK_persona_novedad_persona];
GO

-- Clave foránea: FK_persona_novedad_uaa_personal (dbo.persona_novedad -> dbo.uaa_personal)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_persona_novedad_uaa_personal')
BEGIN
    ALTER TABLE [dbo].[persona_novedad] WITH CHECK
    ADD CONSTRAINT [FK_persona_novedad_uaa_personal] FOREIGN KEY ([uap_codigo])
    REFERENCES [dbo].[uaa_personal] ([uap_codigo]);
END
GO
ALTER TABLE [dbo].[persona_novedad] CHECK CONSTRAINT [FK_persona_novedad_uaa_personal];
GO

-- Clave foránea: FK_persona_proyecto_persona (dbo.persona_proyecto -> dbo.persona)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_persona_proyecto_persona')
BEGIN
    ALTER TABLE [dbo].[persona_proyecto] WITH CHECK
    ADD CONSTRAINT [FK_persona_proyecto_persona] FOREIGN KEY ([pep_persona])
    REFERENCES [dbo].[persona] ([per_codigo]);
END
GO
ALTER TABLE [dbo].[persona_proyecto] CHECK CONSTRAINT [FK_persona_proyecto_persona];
GO

-- Clave foránea: FK_persona_proyecto_proyecto_rol (dbo.persona_proyecto -> dbo.proyecto_rol)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_persona_proyecto_proyecto_rol')
BEGIN
    ALTER TABLE [dbo].[persona_proyecto] WITH CHECK
    ADD CONSTRAINT [FK_persona_proyecto_proyecto_rol] FOREIGN KEY ([prr_codigo])
    REFERENCES [dbo].[proyecto_rol] ([pyr_codigo]);
END
GO
ALTER TABLE [dbo].[persona_proyecto] CHECK CONSTRAINT [FK_persona_proyecto_proyecto_rol];
GO

-- Clave foránea: FK_proyecto_persona_proyecto (dbo.persona_proyecto -> dbo.proyecto)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_proyecto_persona_proyecto')
BEGIN
    ALTER TABLE [dbo].[persona_proyecto] WITH CHECK
    ADD CONSTRAINT [FK_proyecto_persona_proyecto] FOREIGN KEY ([pry_codigo])
    REFERENCES [dbo].[proyecto] ([pry_codigo]);
END
GO
ALTER TABLE [dbo].[persona_proyecto] CHECK CONSTRAINT [FK_proyecto_persona_proyecto];
GO

-- Clave foránea: FK__plan_acad__nac_c__1BE45685 (dbo.plan_academico -> dbo.nivel_academico_creditos)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK__plan_acad__nac_c__1BE45685')
BEGIN
    ALTER TABLE [dbo].[plan_academico] WITH CHECK
    ADD CONSTRAINT [FK__plan_acad__nac_c__1BE45685] FOREIGN KEY ([nac_codigo])
    REFERENCES [dbo].[nivel_academico_creditos] ([nac_codigo]);
END
GO
ALTER TABLE [dbo].[plan_academico] CHECK CONSTRAINT [FK__plan_acad__nac_c__1BE45685];
GO

-- Clave foránea: FK_plan_academico_asignatura_asignatura_agosto2018 (dbo.plan_academico_asignatura -> dbo.asignatura)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_plan_academico_asignatura_asignatura_agosto2018')
BEGIN
    ALTER TABLE [dbo].[plan_academico_asignatura] WITH CHECK
    ADD CONSTRAINT [FK_plan_academico_asignatura_asignatura_agosto2018] FOREIGN KEY ([asi_codigo])
    REFERENCES [dbo].[asignatura] ([asi_codigo]);
END
GO
ALTER TABLE [dbo].[plan_academico_asignatura] CHECK CONSTRAINT [FK_plan_academico_asignatura_asignatura_agosto2018];
GO

-- Clave foránea: FK_plan_academico_asignatura_plan_academico (dbo.plan_academico_asignatura -> dbo.plan_academico)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_plan_academico_asignatura_plan_academico')
BEGIN
    ALTER TABLE [dbo].[plan_academico_asignatura] WITH CHECK
    ADD CONSTRAINT [FK_plan_academico_asignatura_plan_academico] FOREIGN KEY ([pla_codigo])
    REFERENCES [dbo].[plan_academico] ([pla_codigo]);
END
GO
ALTER TABLE [dbo].[plan_academico_asignatura] CHECK CONSTRAINT [FK_plan_academico_asignatura_plan_academico];
GO

-- Clave foránea: FK_plan_estudiante_estudiante (dbo.plan_estudiante -> dbo.estudiante)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_plan_estudiante_estudiante')
BEGIN
    ALTER TABLE [dbo].[plan_estudiante] WITH CHECK
    ADD CONSTRAINT [FK_plan_estudiante_estudiante] FOREIGN KEY ([est_codigo])
    REFERENCES [dbo].[estudiante] ([est_codigo]);
END
GO
ALTER TABLE [dbo].[plan_estudiante] CHECK CONSTRAINT [FK_plan_estudiante_estudiante];
GO

-- Clave foránea: FK_plan_estudiante_plan_academico (dbo.plan_estudiante -> dbo.plan_academico)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_plan_estudiante_plan_academico')
BEGIN
    ALTER TABLE [dbo].[plan_estudiante] WITH CHECK
    ADD CONSTRAINT [FK_plan_estudiante_plan_academico] FOREIGN KEY ([pla_codigo])
    REFERENCES [dbo].[plan_academico] ([pla_codigo]);
END
GO
ALTER TABLE [dbo].[plan_estudiante] CHECK CONSTRAINT [FK_plan_estudiante_plan_academico];
GO

-- Clave foránea: FK_programa_nivel_academico (dbo.programa -> dbo.nivel_academico)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_programa_nivel_academico')
BEGIN
    ALTER TABLE [dbo].[programa] WITH CHECK
    ADD CONSTRAINT [FK_programa_nivel_academico] FOREIGN KEY ([nia_codigo])
    REFERENCES [dbo].[nivel_academico] ([nia_codigo]);
END
GO
ALTER TABLE [dbo].[programa] CHECK CONSTRAINT [FK_programa_nivel_academico];
GO

-- Clave foránea: FK_programa_sede (dbo.programa -> dbo.sede)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_programa_sede')
BEGIN
    ALTER TABLE [dbo].[programa] WITH CHECK
    ADD CONSTRAINT [FK_programa_sede] FOREIGN KEY ([sed_codigo])
    REFERENCES [dbo].[sede] ([sed_codigo]);
END
GO
ALTER TABLE [dbo].[programa] CHECK CONSTRAINT [FK_programa_sede];
GO

-- Clave foránea: FK_programa_uaa_agosto2018 (dbo.programa -> dbo.uaa)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_programa_uaa_agosto2018')
BEGIN
    ALTER TABLE [dbo].[programa] WITH CHECK
    ADD CONSTRAINT [FK_programa_uaa_agosto2018] FOREIGN KEY ([uaa_codigo])
    REFERENCES [dbo].[uaa] ([uaa_codigo]);
END
GO
ALTER TABLE [dbo].[programa] CHECK CONSTRAINT [FK_programa_uaa_agosto2018];
GO

-- Clave foránea: programa_cam_detFK (dbo.programa -> acreditacion.campo_detallado)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'programa_cam_detFK')
BEGIN
    ALTER TABLE [dbo].[programa] WITH CHECK
    ADD CONSTRAINT [programa_cam_detFK] FOREIGN KEY ([cam_det_codigo])
    REFERENCES [acreditacion].[campo_detallado] ([cam_det_codigo]);
END
GO
ALTER TABLE [dbo].[programa] CHECK CONSTRAINT [programa_cam_detFK];
GO

-- Clave foránea: FK_proyecto_grupo (dbo.proyecto -> dbo.grupo)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_proyecto_grupo')
BEGIN
    ALTER TABLE [dbo].[proyecto] WITH CHECK
    ADD CONSTRAINT [FK_proyecto_grupo] FOREIGN KEY ([gru_codigo])
    REFERENCES [dbo].[grupo] ([gru_codigo]);
END
GO
ALTER TABLE [dbo].[proyecto] CHECK CONSTRAINT [FK_proyecto_grupo];
GO

-- Clave foránea: FK_proyecto_proyecto_estado (dbo.proyecto -> dbo.proyecto_estado)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_proyecto_proyecto_estado')
BEGIN
    ALTER TABLE [dbo].[proyecto] WITH CHECK
    ADD CONSTRAINT [FK_proyecto_proyecto_estado] FOREIGN KEY ([pre_codigo])
    REFERENCES [dbo].[proyecto_estado] ([pye_codigo]);
END
GO
ALTER TABLE [dbo].[proyecto] CHECK CONSTRAINT [FK_proyecto_proyecto_estado];
GO

-- Clave foránea: FK_proyecto_proyecto_tipo (dbo.proyecto -> dbo.proyecto_tipo)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_proyecto_proyecto_tipo')
BEGIN
    ALTER TABLE [dbo].[proyecto] WITH CHECK
    ADD CONSTRAINT [FK_proyecto_proyecto_tipo] FOREIGN KEY ([prt_codigo])
    REFERENCES [dbo].[proyecto_tipo] ([prt_codigo]);
END
GO
ALTER TABLE [dbo].[proyecto] CHECK CONSTRAINT [FK_proyecto_proyecto_tipo];
GO

-- Clave foránea: FK_sede_municipio (dbo.sede -> dbo.municipio)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_sede_municipio')
BEGIN
    ALTER TABLE [dbo].[sede] WITH CHECK
    ADD CONSTRAINT [FK_sede_municipio] FOREIGN KEY ([mun_codigo])
    REFERENCES [dbo].[municipio] ([mun_codigo]);
END
GO
ALTER TABLE [dbo].[sede] CHECK CONSTRAINT [FK_sede_municipio];
GO

-- Clave foránea: FK_sub_sede_sede (dbo.sub_sede -> dbo.sede)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_sub_sede_sede')
BEGIN
    ALTER TABLE [dbo].[sub_sede] WITH CHECK
    ADD CONSTRAINT [FK_sub_sede_sede] FOREIGN KEY ([sed_codigo])
    REFERENCES [dbo].[sede] ([sed_codigo]);
END
GO
ALTER TABLE [dbo].[sub_sede] CHECK CONSTRAINT [FK_sub_sede_sede];
GO

-- Clave foránea: FK_uaa_sede (dbo.uaa -> dbo.sede)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_uaa_sede')
BEGIN
    ALTER TABLE [dbo].[uaa] WITH CHECK
    ADD CONSTRAINT [FK_uaa_sede] FOREIGN KEY ([sed_codigo])
    REFERENCES [dbo].[sede] ([sed_codigo]);
END
GO
ALTER TABLE [dbo].[uaa] CHECK CONSTRAINT [FK_uaa_sede];
GO

-- Clave foránea: FK_uaa_cargo_dedicacion (dbo.uaa_cargo -> dbo.dedicacion)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_uaa_cargo_dedicacion')
BEGIN
    ALTER TABLE [dbo].[uaa_cargo] WITH CHECK
    ADD CONSTRAINT [FK_uaa_cargo_dedicacion] FOREIGN KEY ([uac_dedicacion])
    REFERENCES [dbo].[dedicacion] ([ded_codigo]);
END
GO
ALTER TABLE [dbo].[uaa_cargo] CHECK CONSTRAINT [FK_uaa_cargo_dedicacion];
GO

-- Clave foránea: FK_uaa_cargo_uaa (dbo.uaa_cargo -> dbo.uaa)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_uaa_cargo_uaa')
BEGIN
    ALTER TABLE [dbo].[uaa_cargo] WITH CHECK
    ADD CONSTRAINT [FK_uaa_cargo_uaa] FOREIGN KEY ([uac_uaa])
    REFERENCES [dbo].[uaa] ([uaa_codigo]);
END
GO
ALTER TABLE [dbo].[uaa_cargo] CHECK CONSTRAINT [FK_uaa_cargo_uaa];
GO

-- Clave foránea: FK_uaa_cargo_vinculacion (dbo.uaa_cargo -> dbo.vinculacion)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_uaa_cargo_vinculacion')
BEGIN
    ALTER TABLE [dbo].[uaa_cargo] WITH CHECK
    ADD CONSTRAINT [FK_uaa_cargo_vinculacion] FOREIGN KEY ([uac_vinculacion])
    REFERENCES [dbo].[vinculacion] ([vin_codigo]);
END
GO
ALTER TABLE [dbo].[uaa_cargo] CHECK CONSTRAINT [FK_uaa_cargo_vinculacion];
GO

-- Clave foránea: FK_uaa_personal_persona_agosto2018 (dbo.uaa_personal -> dbo.persona)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_uaa_personal_persona_agosto2018')
BEGIN
    ALTER TABLE [dbo].[uaa_personal] WITH CHECK
    ADD CONSTRAINT [FK_uaa_personal_persona_agosto2018] FOREIGN KEY ([per_codigo])
    REFERENCES [dbo].[persona] ([per_codigo]);
END
GO
ALTER TABLE [dbo].[uaa_personal] CHECK CONSTRAINT [FK_uaa_personal_persona_agosto2018];
GO

-- Clave foránea: FK_uaa_personal_uaa_agosto2018 (dbo.uaa_personal -> dbo.uaa)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_uaa_personal_uaa_agosto2018')
BEGIN
    ALTER TABLE [dbo].[uaa_personal] WITH CHECK
    ADD CONSTRAINT [FK_uaa_personal_uaa_agosto2018] FOREIGN KEY ([uaa_codigo])
    REFERENCES [dbo].[uaa] ([uaa_codigo]);
END
GO
ALTER TABLE [dbo].[uaa_personal] CHECK CONSTRAINT [FK_uaa_personal_uaa_agosto2018];
GO

-- Clave foránea: FK_estudiante_persona_agosto2018 (dbo.estudiante -> dbo.persona)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_estudiante_persona_agosto2018')
BEGIN
    ALTER TABLE [dbo].[estudiante] WITH CHECK
    ADD CONSTRAINT [FK_estudiante_persona_agosto2018] FOREIGN KEY ([per_codigo])
    REFERENCES [dbo].[persona] ([per_codigo]);
END
GO
ALTER TABLE [dbo].[estudiante] CHECK CONSTRAINT [FK_estudiante_persona_agosto2018];
GO

-- Clave foránea: FK_pgr_codigo (programacionacademica.grupo_uaa_item -> programacionacademica.grupo_uaa)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_pgr_codigo')
BEGIN
    ALTER TABLE [programacionacademica].[grupo_uaa_item] WITH CHECK
    ADD CONSTRAINT [FK_pgr_codigo] FOREIGN KEY ([pgr_codigo])
    REFERENCES [programacionacademica].[grupo_uaa] ([pgr_codigo]);
END
GO
ALTER TABLE [programacionacademica].[grupo_uaa_item] CHECK CONSTRAINT [FK_pgr_codigo];
GO

-- Clave foránea: FK_uaa_codigo (programacionacademica.grupo_uaa_item -> dbo.uaa)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_uaa_codigo')
BEGIN
    ALTER TABLE [programacionacademica].[grupo_uaa_item] WITH CHECK
    ADD CONSTRAINT [FK_uaa_codigo] FOREIGN KEY ([uaa_codigo])
    REFERENCES [dbo].[uaa] ([uaa_codigo]);
END
GO
ALTER TABLE [programacionacademica].[grupo_uaa_item] CHECK CONSTRAINT [FK_uaa_codigo];
GO

-- Clave foránea: FK_periodo_unidad_periodo (programacionacademica.periodo_unidad -> dbo.periodo)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_periodo_unidad_periodo')
BEGIN
    ALTER TABLE [programacionacademica].[periodo_unidad] WITH CHECK
    ADD CONSTRAINT [FK_periodo_unidad_periodo] FOREIGN KEY ([per_codigo])
    REFERENCES [dbo].[periodo] ([per_codigo]);
END
GO
ALTER TABLE [programacionacademica].[periodo_unidad] CHECK CONSTRAINT [FK_periodo_unidad_periodo];
GO

-- Clave foránea: FK_periodo_unidad_uaa (programacionacademica.periodo_unidad -> dbo.uaa)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_periodo_unidad_uaa')
BEGIN
    ALTER TABLE [programacionacademica].[periodo_unidad] WITH CHECK
    ADD CONSTRAINT [FK_periodo_unidad_uaa] FOREIGN KEY ([uaa_codigo])
    REFERENCES [dbo].[uaa] ([uaa_codigo]);
END
GO
ALTER TABLE [programacionacademica].[periodo_unidad] CHECK CONSTRAINT [FK_periodo_unidad_uaa];
GO

-- Clave foránea: FK_programacion_academica_calendario (programacionacademica.programacion_academica -> dbo.calendario)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_programacion_academica_calendario')
BEGIN
    ALTER TABLE [programacionacademica].[programacion_academica] WITH CHECK
    ADD CONSTRAINT [FK_programacion_academica_calendario] FOREIGN KEY ([cal_codigo])
    REFERENCES [dbo].[calendario] ([cal_codigo]);
END
GO
ALTER TABLE [programacionacademica].[programacion_academica] CHECK CONSTRAINT [FK_programacion_academica_calendario];
GO

-- Clave foránea: FK_programacion_academica_proceso (programacionacademica.programacion_academica -> dbo.programacion_proceso)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_programacion_academica_proceso')
BEGIN
    ALTER TABLE [programacionacademica].[programacion_academica] WITH CHECK
    ADD CONSTRAINT [FK_programacion_academica_proceso] FOREIGN KEY ([prp_codigo])
    REFERENCES [dbo].[programacion_proceso] ([prp_codigo]);
END
GO
ALTER TABLE [programacionacademica].[programacion_academica] CHECK CONSTRAINT [FK_programacion_academica_proceso];
GO

-- Clave foránea: FK_programacion_academica_uaa (programacionacademica.programacion_academica -> dbo.uaa)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_programacion_academica_uaa')
BEGIN
    ALTER TABLE [programacionacademica].[programacion_academica] WITH CHECK
    ADD CONSTRAINT [FK_programacion_academica_uaa] FOREIGN KEY ([uaa_codigo])
    REFERENCES [dbo].[uaa] ([uaa_codigo]);
END
GO
ALTER TABLE [programacionacademica].[programacion_academica] CHECK CONSTRAINT [FK_programacion_academica_uaa];
GO

-- Clave foránea: FK_programacion_gestion_calendario (programacionacademica.programacion_gestion -> dbo.calendario)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_programacion_gestion_calendario')
BEGIN
    ALTER TABLE [programacionacademica].[programacion_gestion] WITH CHECK
    ADD CONSTRAINT [FK_programacion_gestion_calendario] FOREIGN KEY ([cal_codigo])
    REFERENCES [dbo].[calendario] ([cal_codigo]);
END
GO
ALTER TABLE [programacionacademica].[programacion_gestion] CHECK CONSTRAINT [FK_programacion_gestion_calendario];
GO

-- Clave foránea: FK_programacion_gestion_tipo_solicitud (programacionacademica.programacion_gestion -> programacionacademica.programacion_tipo_solicitudes)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_programacion_gestion_tipo_solicitud')
BEGIN
    ALTER TABLE [programacionacademica].[programacion_gestion] WITH CHECK
    ADD CONSTRAINT [FK_programacion_gestion_tipo_solicitud] FOREIGN KEY ([pts_codigo])
    REFERENCES [programacionacademica].[programacion_tipo_solicitudes] ([pts_codigo]);
END
GO
ALTER TABLE [programacionacademica].[programacion_gestion] CHECK CONSTRAINT [FK_programacion_gestion_tipo_solicitud];
GO

-- Clave foránea: FK_programacion_gestion_uaa (programacionacademica.programacion_gestion -> dbo.uaa)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_programacion_gestion_uaa')
BEGIN
    ALTER TABLE [programacionacademica].[programacion_gestion] WITH CHECK
    ADD CONSTRAINT [FK_programacion_gestion_uaa] FOREIGN KEY ([uaa_codigo])
    REFERENCES [dbo].[uaa] ([uaa_codigo]);
END
GO
ALTER TABLE [programacionacademica].[programacion_gestion] CHECK CONSTRAINT [FK_programacion_gestion_uaa];
GO

-- Clave foránea: FK_solicitud_cambio_horario_curso (programacionacademica.solicitud_cambio_horario -> dbo.curso)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_solicitud_cambio_horario_curso')
BEGIN
    ALTER TABLE [programacionacademica].[solicitud_cambio_horario] WITH CHECK
    ADD CONSTRAINT [FK_solicitud_cambio_horario_curso] FOREIGN KEY ([cur_codigo])
    REFERENCES [dbo].[curso] ([cur_codigo]);
END
GO
ALTER TABLE [programacionacademica].[solicitud_cambio_horario] CHECK CONSTRAINT [FK_solicitud_cambio_horario_curso];
GO

-- Clave foránea: FK_solicitud_cambio_horario_uaa_codigo (programacionacademica.solicitud_cambio_horario -> dbo.uaa)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_solicitud_cambio_horario_uaa_codigo')
BEGIN
    ALTER TABLE [programacionacademica].[solicitud_cambio_horario] WITH CHECK
    ADD CONSTRAINT [FK_solicitud_cambio_horario_uaa_codigo] FOREIGN KEY ([uaa_codigo])
    REFERENCES [dbo].[uaa] ([uaa_codigo]);
END
GO
ALTER TABLE [programacionacademica].[solicitud_cambio_horario] CHECK CONSTRAINT [FK_solicitud_cambio_horario_uaa_codigo];
GO

-- Clave foránea: FK_solicitud_cambio_horario_comentario_solicitud (programacionacademica.solicitud_cambio_horario_comentario -> programacionacademica.solicitud_cambio_horario)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_solicitud_cambio_horario_comentario_solicitud')
BEGIN
    ALTER TABLE [programacionacademica].[solicitud_cambio_horario_comentario] WITH CHECK
    ADD CONSTRAINT [FK_solicitud_cambio_horario_comentario_solicitud] FOREIGN KEY ([sch_codigo])
    REFERENCES [programacionacademica].[solicitud_cambio_horario] ([sch_codigo]);
END
GO
ALTER TABLE [programacionacademica].[solicitud_cambio_horario_comentario] CHECK CONSTRAINT [FK_solicitud_cambio_horario_comentario_solicitud];
GO

-- Clave foránea: FK_solicitud_cambio_horario_horario_dia_anterior (programacionacademica.solicitud_cambio_horario_horario -> dbo.dia)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_solicitud_cambio_horario_horario_dia_anterior')
BEGIN
    ALTER TABLE [programacionacademica].[solicitud_cambio_horario_horario] WITH CHECK
    ADD CONSTRAINT [FK_solicitud_cambio_horario_horario_dia_anterior] FOREIGN KEY ([schh_dia_codigo_anterior])
    REFERENCES [dbo].[dia] ([dia_codigo]);
END
GO
ALTER TABLE [programacionacademica].[solicitud_cambio_horario_horario] CHECK CONSTRAINT [FK_solicitud_cambio_horario_horario_dia_anterior];
GO

-- Clave foránea: FK_solicitud_cambio_horario_horario_dia_nuevo (programacionacademica.solicitud_cambio_horario_horario -> dbo.dia)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_solicitud_cambio_horario_horario_dia_nuevo')
BEGIN
    ALTER TABLE [programacionacademica].[solicitud_cambio_horario_horario] WITH CHECK
    ADD CONSTRAINT [FK_solicitud_cambio_horario_horario_dia_nuevo] FOREIGN KEY ([schh_dia_codigo_nuevo])
    REFERENCES [dbo].[dia] ([dia_codigo]);
END
GO
ALTER TABLE [programacionacademica].[solicitud_cambio_horario_horario] CHECK CONSTRAINT [FK_solicitud_cambio_horario_horario_dia_nuevo];
GO

-- Clave foránea: FK_solicitud_cambio_horario_horario_esp_anterior (programacionacademica.solicitud_cambio_horario_horario -> dbo.espacio)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_solicitud_cambio_horario_horario_esp_anterior')
BEGIN
    ALTER TABLE [programacionacademica].[solicitud_cambio_horario_horario] WITH CHECK
    ADD CONSTRAINT [FK_solicitud_cambio_horario_horario_esp_anterior] FOREIGN KEY ([schh_esp_codigo_anterior])
    REFERENCES [dbo].[espacio] ([esp_codigo]);
END
GO
ALTER TABLE [programacionacademica].[solicitud_cambio_horario_horario] CHECK CONSTRAINT [FK_solicitud_cambio_horario_horario_esp_anterior];
GO

-- Clave foránea: FK_solicitud_cambio_horario_horario_esp_nuevo (programacionacademica.solicitud_cambio_horario_horario -> dbo.espacio)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_solicitud_cambio_horario_horario_esp_nuevo')
BEGIN
    ALTER TABLE [programacionacademica].[solicitud_cambio_horario_horario] WITH CHECK
    ADD CONSTRAINT [FK_solicitud_cambio_horario_horario_esp_nuevo] FOREIGN KEY ([schh_esp_codigo_nuevo])
    REFERENCES [dbo].[espacio] ([esp_codigo]);
END
GO
ALTER TABLE [programacionacademica].[solicitud_cambio_horario_horario] CHECK CONSTRAINT [FK_solicitud_cambio_horario_horario_esp_nuevo];
GO

-- Clave foránea: FK_solicitud_cambio_horario_horario_hra_anterior (programacionacademica.solicitud_cambio_horario_horario -> dbo.hora)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_solicitud_cambio_horario_horario_hra_anterior')
BEGIN
    ALTER TABLE [programacionacademica].[solicitud_cambio_horario_horario] WITH CHECK
    ADD CONSTRAINT [FK_solicitud_cambio_horario_horario_hra_anterior] FOREIGN KEY ([schh_hra_codigo_anterior])
    REFERENCES [dbo].[hora] ([hra_codigo]);
END
GO
ALTER TABLE [programacionacademica].[solicitud_cambio_horario_horario] CHECK CONSTRAINT [FK_solicitud_cambio_horario_horario_hra_anterior];
GO

-- Clave foránea: FK_solicitud_cambio_horario_horario_hra_nuevo (programacionacademica.solicitud_cambio_horario_horario -> dbo.hora)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_solicitud_cambio_horario_horario_hra_nuevo')
BEGIN
    ALTER TABLE [programacionacademica].[solicitud_cambio_horario_horario] WITH CHECK
    ADD CONSTRAINT [FK_solicitud_cambio_horario_horario_hra_nuevo] FOREIGN KEY ([schh_hra_codigo_nuevo])
    REFERENCES [dbo].[hora] ([hra_codigo]);
END
GO
ALTER TABLE [programacionacademica].[solicitud_cambio_horario_horario] CHECK CONSTRAINT [FK_solicitud_cambio_horario_horario_hra_nuevo];
GO

-- Clave foránea: FK_solicitud_cambio_horario_horario_solicitud (programacionacademica.solicitud_cambio_horario_horario -> programacionacademica.solicitud_cambio_horario)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_solicitud_cambio_horario_horario_solicitud')
BEGIN
    ALTER TABLE [programacionacademica].[solicitud_cambio_horario_horario] WITH CHECK
    ADD CONSTRAINT [FK_solicitud_cambio_horario_horario_solicitud] FOREIGN KEY ([sch_codigo])
    REFERENCES [programacionacademica].[solicitud_cambio_horario] ([sch_codigo]);
END
GO
ALTER TABLE [programacionacademica].[solicitud_cambio_horario_horario] CHECK CONSTRAINT [FK_solicitud_cambio_horario_horario_solicitud];
GO

-- Clave foránea: FK_solicitud_cambio_horario_horario_uap_anterior (programacionacademica.solicitud_cambio_horario_horario -> dbo.uaa_personal)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_solicitud_cambio_horario_horario_uap_anterior')
BEGIN
    ALTER TABLE [programacionacademica].[solicitud_cambio_horario_horario] WITH CHECK
    ADD CONSTRAINT [FK_solicitud_cambio_horario_horario_uap_anterior] FOREIGN KEY ([schh_uap_codigo_anterior])
    REFERENCES [dbo].[uaa_personal] ([uap_codigo]);
END
GO
ALTER TABLE [programacionacademica].[solicitud_cambio_horario_horario] CHECK CONSTRAINT [FK_solicitud_cambio_horario_horario_uap_anterior];
GO

-- Clave foránea: FK_solicitud_cambio_horario_horario_uap_nuevo (programacionacademica.solicitud_cambio_horario_horario -> dbo.uaa_personal)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_solicitud_cambio_horario_horario_uap_nuevo')
BEGIN
    ALTER TABLE [programacionacademica].[solicitud_cambio_horario_horario] WITH CHECK
    ADD CONSTRAINT [FK_solicitud_cambio_horario_horario_uap_nuevo] FOREIGN KEY ([schh_uap_codigo_nuevo])
    REFERENCES [dbo].[uaa_personal] ([uap_codigo]);
END
GO
ALTER TABLE [programacionacademica].[solicitud_cambio_horario_horario] CHECK CONSTRAINT [FK_solicitud_cambio_horario_horario_uap_nuevo];
GO

-- Clave foránea: FK_solicitud_prestamo_docente_asignatura (programacionacademica.solicitud_prestamo_docente -> dbo.asignatura)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_solicitud_prestamo_docente_asignatura')
BEGIN
    ALTER TABLE [programacionacademica].[solicitud_prestamo_docente] WITH CHECK
    ADD CONSTRAINT [FK_solicitud_prestamo_docente_asignatura] FOREIGN KEY ([asi_codigo])
    REFERENCES [dbo].[asignatura] ([asi_codigo]);
END
GO
ALTER TABLE [programacionacademica].[solicitud_prestamo_docente] CHECK CONSTRAINT [FK_solicitud_prestamo_docente_asignatura];
GO

-- Clave foránea: FK_solicitud_prestamo_docente_periodo (programacionacademica.solicitud_prestamo_docente -> dbo.periodo)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_solicitud_prestamo_docente_periodo')
BEGIN
    ALTER TABLE [programacionacademica].[solicitud_prestamo_docente] WITH CHECK
    ADD CONSTRAINT [FK_solicitud_prestamo_docente_periodo] FOREIGN KEY ([periodo_codigo])
    REFERENCES [dbo].[periodo] ([per_codigo]);
END
GO
ALTER TABLE [programacionacademica].[solicitud_prestamo_docente] CHECK CONSTRAINT [FK_solicitud_prestamo_docente_periodo];
GO

-- Clave foránea: FK_solicitud_prestamo_docente_persona (programacionacademica.solicitud_prestamo_docente -> dbo.persona)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_solicitud_prestamo_docente_persona')
BEGIN
    ALTER TABLE [programacionacademica].[solicitud_prestamo_docente] WITH CHECK
    ADD CONSTRAINT [FK_solicitud_prestamo_docente_persona] FOREIGN KEY ([persona_codigo])
    REFERENCES [dbo].[persona] ([per_codigo]);
END
GO
ALTER TABLE [programacionacademica].[solicitud_prestamo_docente] CHECK CONSTRAINT [FK_solicitud_prestamo_docente_persona];
GO

-- Clave foránea: FK_solicitud_prestamo_docente_sed_codigo (programacionacademica.solicitud_prestamo_docente -> dbo.sede)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_solicitud_prestamo_docente_sed_codigo')
BEGIN
    ALTER TABLE [programacionacademica].[solicitud_prestamo_docente] WITH CHECK
    ADD CONSTRAINT [FK_solicitud_prestamo_docente_sed_codigo] FOREIGN KEY ([sed_codigo])
    REFERENCES [dbo].[sede] ([sed_codigo]);
END
GO
ALTER TABLE [programacionacademica].[solicitud_prestamo_docente] CHECK CONSTRAINT [FK_solicitud_prestamo_docente_sed_codigo];
GO

-- Clave foránea: FK_solicitud_prestamo_docente_uaa_dirigida (programacionacademica.solicitud_prestamo_docente -> dbo.uaa)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_solicitud_prestamo_docente_uaa_dirigida')
BEGIN
    ALTER TABLE [programacionacademica].[solicitud_prestamo_docente] WITH CHECK
    ADD CONSTRAINT [FK_solicitud_prestamo_docente_uaa_dirigida] FOREIGN KEY ([uaa_dirigida])
    REFERENCES [dbo].[uaa] ([uaa_codigo]);
END
GO
ALTER TABLE [programacionacademica].[solicitud_prestamo_docente] CHECK CONSTRAINT [FK_solicitud_prestamo_docente_uaa_dirigida];
GO

-- Clave foránea: FK_solicitud_prestamo_docente_uaa_solicita (programacionacademica.solicitud_prestamo_docente -> dbo.uaa)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_solicitud_prestamo_docente_uaa_solicita')
BEGIN
    ALTER TABLE [programacionacademica].[solicitud_prestamo_docente] WITH CHECK
    ADD CONSTRAINT [FK_solicitud_prestamo_docente_uaa_solicita] FOREIGN KEY ([uaa_solicita])
    REFERENCES [dbo].[uaa] ([uaa_codigo]);
END
GO
ALTER TABLE [programacionacademica].[solicitud_prestamo_docente] CHECK CONSTRAINT [FK_solicitud_prestamo_docente_uaa_solicita];
GO

-- Clave foránea: FK_solicitud_prestamo_docente_comentario_solicitud (programacionacademica.solicitud_prestamo_docente_comentario -> programacionacademica.solicitud_prestamo_docente)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_solicitud_prestamo_docente_comentario_solicitud')
BEGIN
    ALTER TABLE [programacionacademica].[solicitud_prestamo_docente_comentario] WITH CHECK
    ADD CONSTRAINT [FK_solicitud_prestamo_docente_comentario_solicitud] FOREIGN KEY ([spd_codigo])
    REFERENCES [programacionacademica].[solicitud_prestamo_docente] ([spd_codigo]);
END
GO
ALTER TABLE [programacionacademica].[solicitud_prestamo_docente_comentario] CHECK CONSTRAINT [FK_solicitud_prestamo_docente_comentario_solicitud];
GO

-- Clave foránea: FK_solicitud_prestamo_docente_horario_dia (programacionacademica.solicitud_prestamo_docente_horario -> dbo.dia)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_solicitud_prestamo_docente_horario_dia')
BEGIN
    ALTER TABLE [programacionacademica].[solicitud_prestamo_docente_horario] WITH CHECK
    ADD CONSTRAINT [FK_solicitud_prestamo_docente_horario_dia] FOREIGN KEY ([dia_codigo])
    REFERENCES [dbo].[dia] ([dia_codigo]);
END
GO
ALTER TABLE [programacionacademica].[solicitud_prestamo_docente_horario] CHECK CONSTRAINT [FK_solicitud_prestamo_docente_horario_dia];
GO

-- Clave foránea: FK_solicitud_prestamo_docente_horario_hora (programacionacademica.solicitud_prestamo_docente_horario -> dbo.hora)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_solicitud_prestamo_docente_horario_hora')
BEGIN
    ALTER TABLE [programacionacademica].[solicitud_prestamo_docente_horario] WITH CHECK
    ADD CONSTRAINT [FK_solicitud_prestamo_docente_horario_hora] FOREIGN KEY ([hra_codigo])
    REFERENCES [dbo].[hora] ([hra_codigo]);
END
GO
ALTER TABLE [programacionacademica].[solicitud_prestamo_docente_horario] CHECK CONSTRAINT [FK_solicitud_prestamo_docente_horario_hora];
GO

-- Clave foránea: FK_solicitud_prestamo_docente_horario_solicitud (programacionacademica.solicitud_prestamo_docente_horario -> programacionacademica.solicitud_prestamo_docente)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_solicitud_prestamo_docente_horario_solicitud')
BEGIN
    ALTER TABLE [programacionacademica].[solicitud_prestamo_docente_horario] WITH CHECK
    ADD CONSTRAINT [FK_solicitud_prestamo_docente_horario_solicitud] FOREIGN KEY ([spd_codigo])
    REFERENCES [programacionacademica].[solicitud_prestamo_docente] ([spd_codigo]);
END
GO
ALTER TABLE [programacionacademica].[solicitud_prestamo_docente_horario] CHECK CONSTRAINT [FK_solicitud_prestamo_docente_horario_solicitud];
GO

-- Clave foránea: FK_docentexproyecto_proyeccion_social_nbc_colciencias (proyectos.docentexproyecto_proyeccion_social -> proyectos.ps_nbc_colciencias)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_docentexproyecto_proyeccion_social_nbc_colciencias')
BEGIN
    ALTER TABLE [proyectos].[docentexproyecto_proyeccion_social] WITH CHECK
    ADD CONSTRAINT [FK_docentexproyecto_proyeccion_social_nbc_colciencias] FOREIGN KEY ([nco_codigo])
    REFERENCES [proyectos].[ps_nbc_colciencias] ([nbc_codigo]);
END
GO
ALTER TABLE [proyectos].[docentexproyecto_proyeccion_social] CHECK CONSTRAINT [FK_docentexproyecto_proyeccion_social_nbc_colciencias];
GO

-- Clave foránea: FK_docentexproyecto_proyeccion_social_proyeccion_rolxproyecto (proyectos.docentexproyecto_proyeccion_social -> proyectos.proyeccion_rolxproyecto)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_docentexproyecto_proyeccion_social_proyeccion_rolxproyecto')
BEGIN
    ALTER TABLE [proyectos].[docentexproyecto_proyeccion_social] WITH CHECK
    ADD CONSTRAINT [FK_docentexproyecto_proyeccion_social_proyeccion_rolxproyecto] FOREIGN KEY ([prp_codigo])
    REFERENCES [proyectos].[proyeccion_rolxproyecto] ([rxp_codigo]);
END
GO
ALTER TABLE [proyectos].[docentexproyecto_proyeccion_social] CHECK CONSTRAINT [FK_docentexproyecto_proyeccion_social_proyeccion_rolxproyecto];
GO

-- Clave foránea: FK_docentexproyecto_proyeccion_social_proyecto_proyeccion_social (proyectos.docentexproyecto_proyeccion_social -> proyectos.proyecto_proyeccion_social)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_docentexproyecto_proyeccion_social_proyecto_proyeccion_social')
BEGIN
    ALTER TABLE [proyectos].[docentexproyecto_proyeccion_social] WITH CHECK
    ADD CONSTRAINT [FK_docentexproyecto_proyeccion_social_proyecto_proyeccion_social] FOREIGN KEY ([pps_codigo])
    REFERENCES [proyectos].[proyecto_proyeccion_social] ([pps_codigo]);
END
GO
ALTER TABLE [proyectos].[docentexproyecto_proyeccion_social] CHECK CONSTRAINT [FK_docentexproyecto_proyeccion_social_proyecto_proyeccion_social];
GO

-- Clave foránea: FK_docentexproyecto_proyeccion_social_uaa_personal (proyectos.docentexproyecto_proyeccion_social -> dbo.uaa_personal)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_docentexproyecto_proyeccion_social_uaa_personal')
BEGIN
    ALTER TABLE [proyectos].[docentexproyecto_proyeccion_social] WITH CHECK
    ADD CONSTRAINT [FK_docentexproyecto_proyeccion_social_uaa_personal] FOREIGN KEY ([uap_codigo])
    REFERENCES [dbo].[uaa_personal] ([uap_codigo]);
END
GO
ALTER TABLE [proyectos].[docentexproyecto_proyeccion_social] CHECK CONSTRAINT [FK_docentexproyecto_proyeccion_social_uaa_personal];
GO

-- Clave foránea: FK_proyecto_proyeccion_social_mc_proyecto_area (proyectos.proyecto_proyeccion_social -> proyectos.mc_proyecto_area)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_proyecto_proyeccion_social_mc_proyecto_area')
BEGIN
    ALTER TABLE [proyectos].[proyecto_proyeccion_social] WITH CHECK
    ADD CONSTRAINT [FK_proyecto_proyeccion_social_mc_proyecto_area] FOREIGN KEY ([pra_codigo])
    REFERENCES [proyectos].[mc_proyecto_area] ([mca_codigo]);
END
GO
ALTER TABLE [proyectos].[proyecto_proyeccion_social] CHECK CONSTRAINT [FK_proyecto_proyeccion_social_mc_proyecto_area];
GO

-- Clave foránea: FK_proyecto_proyeccion_social_mc_proyecto_clase (proyectos.proyecto_proyeccion_social -> proyectos.mc_proyecto_clase)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_proyecto_proyeccion_social_mc_proyecto_clase')
BEGIN
    ALTER TABLE [proyectos].[proyecto_proyeccion_social] WITH CHECK
    ADD CONSTRAINT [FK_proyecto_proyeccion_social_mc_proyecto_clase] FOREIGN KEY ([prc_codigo])
    REFERENCES [proyectos].[mc_proyecto_clase] ([mcc_codigo]);
END
GO
ALTER TABLE [proyectos].[proyecto_proyeccion_social] CHECK CONSTRAINT [FK_proyecto_proyeccion_social_mc_proyecto_clase];
GO

-- Clave foránea: FK_proyecto_proyeccion_social_municipio (proyectos.proyecto_proyeccion_social -> dbo.municipio)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_proyecto_proyeccion_social_municipio')
BEGIN
    ALTER TABLE [proyectos].[proyecto_proyeccion_social] WITH CHECK
    ADD CONSTRAINT [FK_proyecto_proyeccion_social_municipio] FOREIGN KEY ([mun_codigo])
    REFERENCES [dbo].[municipio] ([mun_codigo]);
END
GO
ALTER TABLE [proyectos].[proyecto_proyeccion_social] CHECK CONSTRAINT [FK_proyecto_proyeccion_social_municipio];
GO

-- Clave foránea: FK_proyecto_proyeccion_social_nbc_colciencias (proyectos.proyecto_proyeccion_social -> proyectos.ps_nbc_colciencias)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_proyecto_proyeccion_social_nbc_colciencias')
BEGIN
    ALTER TABLE [proyectos].[proyecto_proyeccion_social] WITH CHECK
    ADD CONSTRAINT [FK_proyecto_proyeccion_social_nbc_colciencias] FOREIGN KEY ([nco_codigo])
    REFERENCES [proyectos].[ps_nbc_colciencias] ([nbc_codigo]);
END
GO
ALTER TABLE [proyectos].[proyecto_proyeccion_social] CHECK CONSTRAINT [FK_proyecto_proyeccion_social_nbc_colciencias];
GO

-- Clave foránea: FK_proyecto_proyeccion_social_origen_area_proyecto (proyectos.proyecto_proyeccion_social -> proyectos.ps_origen_area_proyecto)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_proyecto_proyeccion_social_origen_area_proyecto')
BEGIN
    ALTER TABLE [proyectos].[proyecto_proyeccion_social] WITH CHECK
    ADD CONSTRAINT [FK_proyecto_proyeccion_social_origen_area_proyecto] FOREIGN KEY ([oap_codigo])
    REFERENCES [proyectos].[ps_origen_area_proyecto] ([oap_codigo]);
END
GO
ALTER TABLE [proyectos].[proyecto_proyeccion_social] CHECK CONSTRAINT [FK_proyecto_proyeccion_social_origen_area_proyecto];
GO

-- Clave foránea: FK_proyecto_proyeccion_social_origen_tipo_proyecto (proyectos.proyecto_proyeccion_social -> proyectos.ps_origen_tipo_proyecto)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_proyecto_proyeccion_social_origen_tipo_proyecto')
BEGIN
    ALTER TABLE [proyectos].[proyecto_proyeccion_social] WITH CHECK
    ADD CONSTRAINT [FK_proyecto_proyeccion_social_origen_tipo_proyecto] FOREIGN KEY ([otp_codigo])
    REFERENCES [proyectos].[ps_origen_tipo_proyecto] ([otp_codigo]);
END
GO
ALTER TABLE [proyectos].[proyecto_proyeccion_social] CHECK CONSTRAINT [FK_proyecto_proyeccion_social_origen_tipo_proyecto];
GO

-- Clave foránea: FK_proyecto_proyeccion_social_proyecto_proyeccion_social_tipo (proyectos.proyecto_proyeccion_social -> proyectos.ps_proyecto_tipo)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_proyecto_proyeccion_social_proyecto_proyeccion_social_tipo')
BEGIN
    ALTER TABLE [proyectos].[proyecto_proyeccion_social] WITH CHECK
    ADD CONSTRAINT [FK_proyecto_proyeccion_social_proyecto_proyeccion_social_tipo] FOREIGN KEY ([pst_codigo])
    REFERENCES [proyectos].[ps_proyecto_tipo] ([ppt_codigo]);
END
GO
ALTER TABLE [proyectos].[proyecto_proyeccion_social] CHECK CONSTRAINT [FK_proyecto_proyeccion_social_proyecto_proyeccion_social_tipo];
GO

-- Clave foránea: FK_proyecto_proyeccion_social_ps_semillero (proyectos.proyecto_proyeccion_social -> proyectos.ps_semilleros)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_proyecto_proyeccion_social_ps_semillero')
BEGIN
    ALTER TABLE [proyectos].[proyecto_proyeccion_social] WITH CHECK
    ADD CONSTRAINT [FK_proyecto_proyeccion_social_ps_semillero] FOREIGN KEY ([pps_semillero])
    REFERENCES [proyectos].[ps_semilleros] ([semi_codigo]);
END
GO
ALTER TABLE [proyectos].[proyecto_proyeccion_social] CHECK CONSTRAINT [FK_proyecto_proyeccion_social_ps_semillero];
GO

-- Clave foránea: FK_ps_area_extension (proyectos.proyecto_proyeccion_social -> proyectos.ps_area_extension)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_ps_area_extension')
BEGIN
    ALTER TABLE [proyectos].[proyecto_proyeccion_social] WITH CHECK
    ADD CONSTRAINT [FK_ps_area_extension] FOREIGN KEY ([are_codigo])
    REFERENCES [proyectos].[ps_area_extension] ([pae_codigo]);
END
GO
ALTER TABLE [proyectos].[proyecto_proyeccion_social] CHECK CONSTRAINT [FK_ps_area_extension];
GO

-- Clave foránea: FK_sub_tipo_proyecto (proyectos.proyecto_proyeccion_social -> proyectos.ps_sub_tipo_proyecto)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_sub_tipo_proyecto')
BEGIN
    ALTER TABLE [proyectos].[proyecto_proyeccion_social] WITH CHECK
    ADD CONSTRAINT [FK_sub_tipo_proyecto] FOREIGN KEY ([stp_codigo])
    REFERENCES [proyectos].[ps_sub_tipo_proyecto] ([pst_codigo]);
END
GO
ALTER TABLE [proyectos].[proyecto_proyeccion_social] CHECK CONSTRAINT [FK_sub_tipo_proyecto];
GO

-- ============================================================================
-- SECCIÓN 2: NUEVAS CLAVES FORÁNEAS PARA RESOLVER BRECHAS DE INTEGRIDAD
-- (Resuelve las 65 columnas relacionales huérfanas en curso, espacio_ocupacion, matricula, etc.)
-- ============================================================================

-- Integridad referencial entre Curso y Calendario académico
-- Clave foránea: FK_curso_calendario (dbo.curso -> dbo.calendario)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_curso_calendario')
BEGIN
    ALTER TABLE [dbo].[curso] WITH CHECK
    ADD CONSTRAINT [FK_curso_calendario] FOREIGN KEY ([cal_codigo])
    REFERENCES [dbo].[calendario] ([cal_codigo]);
END
GO
ALTER TABLE [dbo].[curso] CHECK CONSTRAINT [FK_curso_calendario];
GO

-- Integridad referencial entre Curso y Sede universitaria
-- Clave foránea: FK_curso_sede (dbo.curso -> dbo.sede)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_curso_sede')
BEGIN
    ALTER TABLE [dbo].[curso] WITH CHECK
    ADD CONSTRAINT [FK_curso_sede] FOREIGN KEY ([sed_codigo])
    REFERENCES [dbo].[sede] ([sed_codigo]);
END
GO
ALTER TABLE [dbo].[curso] CHECK CONSTRAINT [FK_curso_sede];
GO

-- Integridad referencial entre Curso y Tipo de curso (clasificación)
-- Clave foránea: FK_curso_curso_tipo (dbo.curso -> dbo.curso_tipo)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_curso_curso_tipo')
BEGIN
    ALTER TABLE [dbo].[curso] WITH CHECK
    ADD CONSTRAINT [FK_curso_curso_tipo] FOREIGN KEY ([cut_codigo])
    REFERENCES [dbo].[curso_tipo] ([cut_codigo]);
END
GO
ALTER TABLE [dbo].[curso] CHECK CONSTRAINT [FK_curso_curso_tipo];
GO

-- Integridad referencial entre Curso y Naturaleza del curso (teórico/práctico)
-- Clave foránea: FK_curso_tipo_curso (dbo.curso -> dbo.tipo_curso)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_curso_tipo_curso')
BEGIN
    ALTER TABLE [dbo].[curso] WITH CHECK
    ADD CONSTRAINT [FK_curso_tipo_curso] FOREIGN KEY ([tic_codigo])
    REFERENCES [dbo].[tipo_curso] ([tic_codigo]);
END
GO
ALTER TABLE [dbo].[curso] CHECK CONSTRAINT [FK_curso_tipo_curso];
GO

-- Integridad referencial entre Curso y Plan académico
-- Clave foránea: FK_curso_plan_academico (dbo.curso -> dbo.plan_academico)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_curso_plan_academico')
BEGIN
    ALTER TABLE [dbo].[curso] WITH CHECK
    ADD CONSTRAINT [FK_curso_plan_academico] FOREIGN KEY ([pla_codigo])
    REFERENCES [dbo].[plan_academico] ([pla_codigo]);
END
GO
ALTER TABLE [dbo].[curso] CHECK CONSTRAINT [FK_curso_plan_academico];
GO

-- Integridad referencial entre Curso y Tipo de escala de calificación
-- Clave foránea: FK_curso_tipo_escala (dbo.curso -> dbo.tipo_escala)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_curso_tipo_escala')
BEGIN
    ALTER TABLE [dbo].[curso] WITH CHECK
    ADD CONSTRAINT [FK_curso_tipo_escala] FOREIGN KEY ([tes_codigo])
    REFERENCES [dbo].[tipo_escala] ([tes_codigo]);
END
GO
ALTER TABLE [dbo].[curso] CHECK CONSTRAINT [FK_curso_tipo_escala];
GO

-- Integridad referencial estandarizada entre Proceso de programación y Núcleo temático
-- Clave foránea: FK_programacion_proceso_nucleo (dbo.programacion_proceso -> dbo.nucleo)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_programacion_proceso_nucleo')
BEGIN
    ALTER TABLE [dbo].[programacion_proceso] WITH CHECK
    ADD CONSTRAINT [FK_programacion_proceso_nucleo] FOREIGN KEY ([nuc_codigo])
    REFERENCES [dbo].[nucleo] ([nuc_codigo]);
END
GO
ALTER TABLE [dbo].[programacion_proceso] CHECK CONSTRAINT [FK_programacion_proceso_nucleo];
GO

-- Integridad referencial entre Matrícula y Estudiante
-- Clave foránea: FK_matricula_estudiante (dbo.matricula -> dbo.estudiante)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_matricula_estudiante')
BEGIN
    ALTER TABLE [dbo].[matricula] WITH CHECK
    ADD CONSTRAINT [FK_matricula_estudiante] FOREIGN KEY ([est_codigo])
    REFERENCES [dbo].[estudiante] ([est_codigo]);
END
GO
ALTER TABLE [dbo].[matricula] CHECK CONSTRAINT [FK_matricula_estudiante];
GO

