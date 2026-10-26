USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [programacionacademica].[solicitud_prestamo_docente_horario] Fecha de script: 26/10/2026 8:35:02 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [programacionacademica].[solicitud_prestamo_docente_horario](
	[spdh_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[spd_codigo] [int] NOT NULL,
	[dia_codigo] [int] NOT NULL,
	[hra_codigo] [int] NOT NULL,
	[spdh_estado] [tinyint] NOT NULL,
 CONSTRAINT [PK_spd_solicitud_prestamo_docente_horario] PRIMARY KEY NONCLUSTERED 
(
	[spdh_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [programacionacademica].[solicitud_prestamo_docente_horario]  WITH CHECK ADD  CONSTRAINT [FK_solicitud_prestamo_docente_horario_dia] FOREIGN KEY([dia_codigo])
REFERENCES [dbo].[dia] ([dia_codigo])
GO

ALTER TABLE [programacionacademica].[solicitud_prestamo_docente_horario] CHECK CONSTRAINT [FK_solicitud_prestamo_docente_horario_dia]
GO

ALTER TABLE [programacionacademica].[solicitud_prestamo_docente_horario]  WITH CHECK ADD  CONSTRAINT [FK_solicitud_prestamo_docente_horario_hora] FOREIGN KEY([hra_codigo])
REFERENCES [dbo].[hora] ([hra_codigo])
GO

ALTER TABLE [programacionacademica].[solicitud_prestamo_docente_horario] CHECK CONSTRAINT [FK_solicitud_prestamo_docente_horario_hora]
GO

ALTER TABLE [programacionacademica].[solicitud_prestamo_docente_horario]  WITH CHECK ADD  CONSTRAINT [FK_solicitud_prestamo_docente_horario_solicitud] FOREIGN KEY([spd_codigo])
REFERENCES [programacionacademica].[solicitud_prestamo_docente] ([spd_codigo])
GO

ALTER TABLE [programacionacademica].[solicitud_prestamo_docente_horario] CHECK CONSTRAINT [FK_solicitud_prestamo_docente_horario_solicitud]
GO


