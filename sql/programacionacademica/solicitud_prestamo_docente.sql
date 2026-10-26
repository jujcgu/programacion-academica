USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [programacionacademica].[solicitud_prestamo_docente] Fecha de script: 26/10/2026 8:34:02 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [programacionacademica].[solicitud_prestamo_docente](
	[spd_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[periodo_codigo] [int] NOT NULL,
	[persona_codigo] [int] NULL,
	[asi_codigo] [int] NOT NULL,
	[spd_estado] [tinyint] NOT NULL,
	[uaa_solicita] [int] NOT NULL,
	[uaa_dirigida] [int] NOT NULL,
	[sed_codigo] [int] NOT NULL,
 CONSTRAINT [PK_spd_solicitud_prestamo_docente] PRIMARY KEY NONCLUSTERED 
(
	[spd_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [programacionacademica].[solicitud_prestamo_docente]  WITH CHECK ADD  CONSTRAINT [FK_solicitud_prestamo_docente_asignatura] FOREIGN KEY([asi_codigo])
REFERENCES [dbo].[asignatura] ([asi_codigo])
GO

ALTER TABLE [programacionacademica].[solicitud_prestamo_docente] CHECK CONSTRAINT [FK_solicitud_prestamo_docente_asignatura]
GO

ALTER TABLE [programacionacademica].[solicitud_prestamo_docente]  WITH CHECK ADD  CONSTRAINT [FK_solicitud_prestamo_docente_periodo] FOREIGN KEY([periodo_codigo])
REFERENCES [dbo].[periodo] ([per_codigo])
GO

ALTER TABLE [programacionacademica].[solicitud_prestamo_docente] CHECK CONSTRAINT [FK_solicitud_prestamo_docente_periodo]
GO

ALTER TABLE [programacionacademica].[solicitud_prestamo_docente]  WITH CHECK ADD  CONSTRAINT [FK_solicitud_prestamo_docente_persona] FOREIGN KEY([persona_codigo])
REFERENCES [dbo].[persona] ([per_codigo])
GO

ALTER TABLE [programacionacademica].[solicitud_prestamo_docente] CHECK CONSTRAINT [FK_solicitud_prestamo_docente_persona]
GO

ALTER TABLE [programacionacademica].[solicitud_prestamo_docente]  WITH CHECK ADD  CONSTRAINT [FK_solicitud_prestamo_docente_sed_codigo] FOREIGN KEY([sed_codigo])
REFERENCES [dbo].[sede] ([sed_codigo])
GO

ALTER TABLE [programacionacademica].[solicitud_prestamo_docente] CHECK CONSTRAINT [FK_solicitud_prestamo_docente_sed_codigo]
GO

ALTER TABLE [programacionacademica].[solicitud_prestamo_docente]  WITH CHECK ADD  CONSTRAINT [FK_solicitud_prestamo_docente_uaa_dirigida] FOREIGN KEY([uaa_dirigida])
REFERENCES [dbo].[uaa] ([uaa_codigo])
GO

ALTER TABLE [programacionacademica].[solicitud_prestamo_docente] CHECK CONSTRAINT [FK_solicitud_prestamo_docente_uaa_dirigida]
GO

ALTER TABLE [programacionacademica].[solicitud_prestamo_docente]  WITH CHECK ADD  CONSTRAINT [FK_solicitud_prestamo_docente_uaa_solicita] FOREIGN KEY([uaa_solicita])
REFERENCES [dbo].[uaa] ([uaa_codigo])
GO

ALTER TABLE [programacionacademica].[solicitud_prestamo_docente] CHECK CONSTRAINT [FK_solicitud_prestamo_docente_uaa_solicita]
GO


