USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [proyectos].[docentexproyecto_proyeccion_social] Fecha de script: 26/10/2026 8:42:32 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [proyectos].[docentexproyecto_proyeccion_social](
	[id_docentesxproyecto] [int] IDENTITY(1,1) NOT NULL,
	[uap_codigo] [int] NOT NULL,
	[pps_codigo] [int] NOT NULL,
	[prp_codigo] [int] NULL,
	[dpp_horas_descarga] [int] NULL,
	[dpp_horas_sindescarga] [int] NULL,
	[nco_codigo] [int] NULL,
	[dpp_descarga_aprobada] [int] NULL,
	[dpp_sindescarga_aprobada] [int] NULL,
	[dpp_periodo] [int] NULL,
	[dpp_numero_semanas] [int] NULL,
	[dpp_horas_semana] [int] NULL,
	[dpp_observacion] [varchar](5000) NULL,
	[migracion_persona] [int] NULL,
	[migracion_periodo] [int] NULL,
	[migracion_uap] [int] NULL,
	[migracion_horas_semana] [smallint] NULL,
	[migracion_semanas] [smallint] NULL,
	[migracion_observacion] [varchar](300) NULL,
	[dpp_estado] [bit] NULL,
	[derecho_mencion] [int] NULL,
 CONSTRAINT [PK_docentexproyecto_proyeccion_social_1] PRIMARY KEY CLUSTERED 
(
	[id_docentesxproyecto] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [proyectos].[docentexproyecto_proyeccion_social] ADD  DEFAULT ((0)) FOR [derecho_mencion]
GO

ALTER TABLE [proyectos].[docentexproyecto_proyeccion_social]  WITH CHECK ADD  CONSTRAINT [FK_docentexproyecto_proyeccion_social_nbc_colciencias] FOREIGN KEY([nco_codigo])
REFERENCES [proyectos].[ps_nbc_colciencias] ([nco_codigo])
GO

ALTER TABLE [proyectos].[docentexproyecto_proyeccion_social] CHECK CONSTRAINT [FK_docentexproyecto_proyeccion_social_nbc_colciencias]
GO

ALTER TABLE [proyectos].[docentexproyecto_proyeccion_social]  WITH CHECK ADD  CONSTRAINT [FK_docentexproyecto_proyeccion_social_proyeccion_rolxproyecto] FOREIGN KEY([prp_codigo])
REFERENCES [proyectos].[proyeccion_rolxproyecto] ([prp_codigo])
GO

ALTER TABLE [proyectos].[docentexproyecto_proyeccion_social] CHECK CONSTRAINT [FK_docentexproyecto_proyeccion_social_proyeccion_rolxproyecto]
GO

ALTER TABLE [proyectos].[docentexproyecto_proyeccion_social]  WITH CHECK ADD  CONSTRAINT [FK_docentexproyecto_proyeccion_social_proyecto_proyeccion_social] FOREIGN KEY([pps_codigo])
REFERENCES [proyectos].[proyecto_proyeccion_social] ([pps_codigo])
GO

ALTER TABLE [proyectos].[docentexproyecto_proyeccion_social] CHECK CONSTRAINT [FK_docentexproyecto_proyeccion_social_proyecto_proyeccion_social]
GO

ALTER TABLE [proyectos].[docentexproyecto_proyeccion_social]  WITH CHECK ADD  CONSTRAINT [FK_docentexproyecto_proyeccion_social_uaa_personal] FOREIGN KEY([uap_codigo])
REFERENCES [dbo].[uaa_personal] ([uap_codigo])
GO

ALTER TABLE [proyectos].[docentexproyecto_proyeccion_social] CHECK CONSTRAINT [FK_docentexproyecto_proyeccion_social_uaa_personal]
GO


