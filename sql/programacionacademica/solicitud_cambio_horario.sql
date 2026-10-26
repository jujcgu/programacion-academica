USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [programacionacademica].[solicitud_cambio_horario] Fecha de script: 26/10/2026 8:31:53 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [programacionacademica].[solicitud_cambio_horario](
	[sch_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[cur_codigo] [int] NOT NULL,
	[usu_codigo] [int] NOT NULL,
	[uaa_codigo] [int] NOT NULL,
	[sch_cambio_docente] [int] NULL,
	[sch_cambio_semanas] [int] NULL,
	[sch_estado] [int] NOT NULL,
	[sch_fecha_creacion] [datetime] NOT NULL,
	[sch_espacio_deportivo] [int] NULL,
 CONSTRAINT [PK_sch_solicitud_cambio_horario] PRIMARY KEY NONCLUSTERED 
(
	[sch_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [programacionacademica].[solicitud_cambio_horario]  WITH CHECK ADD  CONSTRAINT [FK_solicitud_cambio_horario_curso] FOREIGN KEY([cur_codigo])
REFERENCES [dbo].[curso] ([cur_codigo])
GO

ALTER TABLE [programacionacademica].[solicitud_cambio_horario] CHECK CONSTRAINT [FK_solicitud_cambio_horario_curso]
GO

ALTER TABLE [programacionacademica].[solicitud_cambio_horario]  WITH CHECK ADD  CONSTRAINT [FK_solicitud_cambio_horario_uaa_codigo] FOREIGN KEY([uaa_codigo])
REFERENCES [dbo].[uaa] ([uaa_codigo])
GO

ALTER TABLE [programacionacademica].[solicitud_cambio_horario] CHECK CONSTRAINT [FK_solicitud_cambio_horario_uaa_codigo]
GO


