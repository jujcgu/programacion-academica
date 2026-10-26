USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [proyectos].[proyecto_proyeccion_social] Fecha de script: 26/10/2026 8:45:05 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [proyectos].[proyecto_proyeccion_social](
	[pps_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[pps_titulo] [varchar](300) NULL,
	[pra_codigo] [int] NULL,
	[oap_codigo] [int] NULL,
	[pst_codigo] [int] NULL,
	[otp_codigo] [int] NULL,
	[pps_grupolac] [varchar](150) NULL,
	[nco_codigo] [int] NULL,
	[pps_fecha_inicio] [date] NULL,
	[pps_fecha_fin] [date] NULL,
	[mun_codigo] [int] NULL,
	[pps_palabras_claves] [varchar](200) NULL,
	[pps_objetivo_general] [varchar](max) NULL,
	[pps_resumen] [varchar](max) NULL,
	[pps_metodologia] [varchar](max) NULL,
	[prc_codigo] [int] NULL,
	[pre_codgo] [int] NULL,
	[pps_descripcion_producto] [varchar](200) NULL,
	[pps_beneficiarios] [varchar](200) NULL,
	[pps_impactoxuso_esperado] [varchar](200) NULL,
	[pps_supuestos_basicos] [varchar](200) NULL,
	[pps_plazo_materializacion] [varchar](10) NULL,
	[pps_probabilidad_ocurrencia] [varchar](10) NULL,
	[pps_acto_administrativo] [varchar](50) NULL,
	[pps_acto_administrativo_fecha] [datetime] NULL,
	[pps_acta_aprobacion] [varchar](500) NULL,
	[pps_justificacion_beneficio] [varchar](max) NULL,
	[pps_secretario_administrativo] [int] NULL,
	[pps_decano] [int] NULL,
	[pps_facultad] [int] NULL,
	[pps_coordinador] [int] NULL,
	[pps_solicitante_servicio] [varchar](200) NULL,
	[pps_obs_cumplimiento_actividades] [varchar](200) NULL,
	[pps_obs_consolidacion_resultados] [varchar](200) NULL,
	[migracion_pry_codigo] [int] NULL,
	[uaa_pertenece] [int] NULL,
	[pps_fecha_registro] [datetime] NULL,
	[pps_pregunta] [varchar](max) NULL,
	[pps_marco_teorico] [varchar](max) NULL,
	[pps_grupo] [int] NULL,
	[pps_justificacion] [varchar](max) NULL,
	[pps_estado] [int] NULL,
	[pps_convocatoria] [int] NULL,
	[pps_tipoproyecto] [int] NULL,
	[pps_bibliografia] [varchar](max) NULL,
	[pps_responsable_admin] [int] NULL,
	[beneficiarios] [varchar](max) NULL,
	[localizacion] [varchar](max) NULL,
	[contenidos_academicos] [varchar](max) NULL,
	[pps_fecha_aprobacion_desaprobacion] [datetime] NULL,
	[pps_fecha_actualizacion] [datetime] NULL,
	[pps_aplicacion] [varchar](50) NULL,
	[pps_ip] [varchar](50) NULL,
	[pps_observacion_modificacion] [varchar](max) NULL,
	[pps_planteamiento_problema] [varchar](max) NULL,
	[pps_linea_estrategica] [int] NULL,
	[pps_localizacion_municipio] [int] NULL,
	[pps_area_trabajo] [int] NULL,
	[pps_linea_investigacion] [int] NULL,
	[are_codigo] [int] NULL,
	[stp_codigo] [int] NULL,
	[pps_semillero] [int] NULL,
 CONSTRAINT [PK_proyecto_proyeccion_social] PRIMARY KEY CLUSTERED 
(
	[pps_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [proyectos].[proyecto_proyeccion_social] ADD  CONSTRAINT [DF_proyecto_proyeccion_social_pps_fecha_registro]  DEFAULT (getdate()) FOR [pps_fecha_registro]
GO

ALTER TABLE [proyectos].[proyecto_proyeccion_social]  WITH CHECK ADD  CONSTRAINT [FK_proyecto_proyeccion_social_mc_proyecto_area] FOREIGN KEY([pra_codigo])
REFERENCES [proyectos].[mc_proyecto_area] ([pra_codigo])
GO

ALTER TABLE [proyectos].[proyecto_proyeccion_social] CHECK CONSTRAINT [FK_proyecto_proyeccion_social_mc_proyecto_area]
GO

ALTER TABLE [proyectos].[proyecto_proyeccion_social]  WITH CHECK ADD  CONSTRAINT [FK_proyecto_proyeccion_social_mc_proyecto_clase] FOREIGN KEY([prc_codigo])
REFERENCES [proyectos].[mc_proyecto_clase] ([prc_codigo])
GO

ALTER TABLE [proyectos].[proyecto_proyeccion_social] CHECK CONSTRAINT [FK_proyecto_proyeccion_social_mc_proyecto_clase]
GO

ALTER TABLE [proyectos].[proyecto_proyeccion_social]  WITH CHECK ADD  CONSTRAINT [FK_proyecto_proyeccion_social_municipio] FOREIGN KEY([mun_codigo])
REFERENCES [dbo].[municipio] ([mun_codigo])
GO

ALTER TABLE [proyectos].[proyecto_proyeccion_social] CHECK CONSTRAINT [FK_proyecto_proyeccion_social_municipio]
GO

ALTER TABLE [proyectos].[proyecto_proyeccion_social]  WITH CHECK ADD  CONSTRAINT [FK_proyecto_proyeccion_social_nbc_colciencias] FOREIGN KEY([nco_codigo])
REFERENCES [proyectos].[ps_nbc_colciencias] ([nco_codigo])
GO

ALTER TABLE [proyectos].[proyecto_proyeccion_social] CHECK CONSTRAINT [FK_proyecto_proyeccion_social_nbc_colciencias]
GO

ALTER TABLE [proyectos].[proyecto_proyeccion_social]  WITH CHECK ADD  CONSTRAINT [FK_proyecto_proyeccion_social_origen_area_proyecto] FOREIGN KEY([oap_codigo])
REFERENCES [proyectos].[ps_origen_area_proyecto] ([oap_codigo])
GO

ALTER TABLE [proyectos].[proyecto_proyeccion_social] CHECK CONSTRAINT [FK_proyecto_proyeccion_social_origen_area_proyecto]
GO

ALTER TABLE [proyectos].[proyecto_proyeccion_social]  WITH CHECK ADD  CONSTRAINT [FK_proyecto_proyeccion_social_origen_tipo_proyecto] FOREIGN KEY([otp_codigo])
REFERENCES [proyectos].[ps_origen_tipo_proyecto] ([otp_codigo])
GO

ALTER TABLE [proyectos].[proyecto_proyeccion_social] CHECK CONSTRAINT [FK_proyecto_proyeccion_social_origen_tipo_proyecto]
GO

ALTER TABLE [proyectos].[proyecto_proyeccion_social]  WITH CHECK ADD  CONSTRAINT [FK_proyecto_proyeccion_social_proyecto_proyeccion_social] FOREIGN KEY([pps_codigo])
REFERENCES [proyectos].[proyecto_proyeccion_social] ([pps_codigo])
GO

ALTER TABLE [proyectos].[proyecto_proyeccion_social] CHECK CONSTRAINT [FK_proyecto_proyeccion_social_proyecto_proyeccion_social]
GO

ALTER TABLE [proyectos].[proyecto_proyeccion_social]  WITH CHECK ADD  CONSTRAINT [FK_proyecto_proyeccion_social_proyecto_proyeccion_social_tipo] FOREIGN KEY([pst_codigo])
REFERENCES [proyectos].[ps_proyecto_tipo] ([pst_codigo])
GO

ALTER TABLE [proyectos].[proyecto_proyeccion_social] CHECK CONSTRAINT [FK_proyecto_proyeccion_social_proyecto_proyeccion_social_tipo]
GO

ALTER TABLE [proyectos].[proyecto_proyeccion_social]  WITH NOCHECK ADD  CONSTRAINT [FK_proyecto_proyeccion_social_ps_semillero] FOREIGN KEY([pps_semillero])
REFERENCES [proyectos].[ps_semilleros] ([pss_codigo])
GO

ALTER TABLE [proyectos].[proyecto_proyeccion_social] CHECK CONSTRAINT [FK_proyecto_proyeccion_social_ps_semillero]
GO

ALTER TABLE [proyectos].[proyecto_proyeccion_social]  WITH CHECK ADD  CONSTRAINT [FK_ps_area_extension] FOREIGN KEY([are_codigo])
REFERENCES [proyectos].[ps_area_extension] ([are_codigo])
GO

ALTER TABLE [proyectos].[proyecto_proyeccion_social] CHECK CONSTRAINT [FK_ps_area_extension]
GO

ALTER TABLE [proyectos].[proyecto_proyeccion_social]  WITH CHECK ADD  CONSTRAINT [FK_sub_tipo_proyecto] FOREIGN KEY([stp_codigo])
REFERENCES [proyectos].[ps_sub_tipo_proyecto] ([stp_codigo])
GO

ALTER TABLE [proyectos].[proyecto_proyeccion_social] CHECK CONSTRAINT [FK_sub_tipo_proyecto]
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Semillero al que pertenece el proyecto, el semillero debe estar abscrito al grupo de investigación.' , @level0type=N'SCHEMA',@level0name=N'proyectos', @level1type=N'TABLE',@level1name=N'proyecto_proyeccion_social', @level2type=N'COLUMN',@level2name=N'pps_semillero'
GO


