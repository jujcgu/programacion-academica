USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [programacionacademica].[solicitud_cambio_horario_horario] Fecha de script: 26/10/2026 8:32:51 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [programacionacademica].[solicitud_cambio_horario_horario](
	[schh_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[sch_codigo] [int] NOT NULL,
	[schh_estado] [int] NOT NULL,
	[schh_subgrupo] [char](2) NOT NULL,
	[schh_dia_codigo_anterior] [int] NOT NULL,
	[schh_hra_codigo_anterior] [int] NOT NULL,
	[schh_esp_codigo_anterior] [int] NOT NULL,
	[schh_uap_codigo_anterior] [int] NOT NULL,
	[schh_dia_codigo_nuevo] [int] NOT NULL,
	[schh_hra_codigo_nuevo] [int] NOT NULL,
	[schh_esp_codigo_nuevo] [int] NULL,
	[schh_uap_codigo_nuevo] [int] NULL,
	[schh_fecha_inicio] [date] NULL,
	[schh_fecha_fin] [date] NULL,
 CONSTRAINT [PK_schh_solicitud_cambio_horario_horario] PRIMARY KEY NONCLUSTERED 
(
	[schh_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [programacionacademica].[solicitud_cambio_horario_horario]  WITH CHECK ADD  CONSTRAINT [FK_solicitud_cambio_horario_horario_dia_anterior] FOREIGN KEY([schh_dia_codigo_anterior])
REFERENCES [dbo].[dia] ([dia_codigo])
GO

ALTER TABLE [programacionacademica].[solicitud_cambio_horario_horario] CHECK CONSTRAINT [FK_solicitud_cambio_horario_horario_dia_anterior]
GO

ALTER TABLE [programacionacademica].[solicitud_cambio_horario_horario]  WITH CHECK ADD  CONSTRAINT [FK_solicitud_cambio_horario_horario_dia_nuevo] FOREIGN KEY([schh_dia_codigo_nuevo])
REFERENCES [dbo].[dia] ([dia_codigo])
GO

ALTER TABLE [programacionacademica].[solicitud_cambio_horario_horario] CHECK CONSTRAINT [FK_solicitud_cambio_horario_horario_dia_nuevo]
GO

ALTER TABLE [programacionacademica].[solicitud_cambio_horario_horario]  WITH CHECK ADD  CONSTRAINT [FK_solicitud_cambio_horario_horario_esp_anterior] FOREIGN KEY([schh_esp_codigo_anterior])
REFERENCES [dbo].[espacio] ([esp_codigo])
GO

ALTER TABLE [programacionacademica].[solicitud_cambio_horario_horario] CHECK CONSTRAINT [FK_solicitud_cambio_horario_horario_esp_anterior]
GO

ALTER TABLE [programacionacademica].[solicitud_cambio_horario_horario]  WITH CHECK ADD  CONSTRAINT [FK_solicitud_cambio_horario_horario_esp_nuevo] FOREIGN KEY([schh_esp_codigo_nuevo])
REFERENCES [dbo].[espacio] ([esp_codigo])
GO

ALTER TABLE [programacionacademica].[solicitud_cambio_horario_horario] CHECK CONSTRAINT [FK_solicitud_cambio_horario_horario_esp_nuevo]
GO

ALTER TABLE [programacionacademica].[solicitud_cambio_horario_horario]  WITH CHECK ADD  CONSTRAINT [FK_solicitud_cambio_horario_horario_hra_anterior] FOREIGN KEY([schh_hra_codigo_anterior])
REFERENCES [dbo].[hora] ([hra_codigo])
GO

ALTER TABLE [programacionacademica].[solicitud_cambio_horario_horario] CHECK CONSTRAINT [FK_solicitud_cambio_horario_horario_hra_anterior]
GO

ALTER TABLE [programacionacademica].[solicitud_cambio_horario_horario]  WITH CHECK ADD  CONSTRAINT [FK_solicitud_cambio_horario_horario_hra_nuevo] FOREIGN KEY([schh_hra_codigo_nuevo])
REFERENCES [dbo].[hora] ([hra_codigo])
GO

ALTER TABLE [programacionacademica].[solicitud_cambio_horario_horario] CHECK CONSTRAINT [FK_solicitud_cambio_horario_horario_hra_nuevo]
GO

ALTER TABLE [programacionacademica].[solicitud_cambio_horario_horario]  WITH CHECK ADD  CONSTRAINT [FK_solicitud_cambio_horario_horario_solicitud] FOREIGN KEY([sch_codigo])
REFERENCES [programacionacademica].[solicitud_cambio_horario] ([sch_codigo])
GO

ALTER TABLE [programacionacademica].[solicitud_cambio_horario_horario] CHECK CONSTRAINT [FK_solicitud_cambio_horario_horario_solicitud]
GO

ALTER TABLE [programacionacademica].[solicitud_cambio_horario_horario]  WITH CHECK ADD  CONSTRAINT [FK_solicitud_cambio_horario_horario_uap_anterior] FOREIGN KEY([schh_uap_codigo_anterior])
REFERENCES [dbo].[uaa_personal] ([uap_codigo])
GO

ALTER TABLE [programacionacademica].[solicitud_cambio_horario_horario] CHECK CONSTRAINT [FK_solicitud_cambio_horario_horario_uap_anterior]
GO

ALTER TABLE [programacionacademica].[solicitud_cambio_horario_horario]  WITH CHECK ADD  CONSTRAINT [FK_solicitud_cambio_horario_horario_uap_nuevo] FOREIGN KEY([schh_uap_codigo_nuevo])
REFERENCES [dbo].[uaa_personal] ([uap_codigo])
GO

ALTER TABLE [programacionacademica].[solicitud_cambio_horario_horario] CHECK CONSTRAINT [FK_solicitud_cambio_horario_horario_uap_nuevo]
GO


