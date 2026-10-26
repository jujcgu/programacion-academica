USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [programacionacademica].[solicitud_cambio_horario_comentario] Fecha de script: 26/10/2026 8:32:26 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [programacionacademica].[solicitud_cambio_horario_comentario](
	[schc_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[sch_codigo] [int] NOT NULL,
	[schc_fecha_creacion] [datetime] NOT NULL,
	[schc_comentario] [varchar](max) NOT NULL,
	[usu_codigo] [int] NOT NULL,
 CONSTRAINT [PK_schc_solicitud_cambio_horario_comentario] PRIMARY KEY NONCLUSTERED 
(
	[schc_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [programacionacademica].[solicitud_cambio_horario_comentario]  WITH CHECK ADD  CONSTRAINT [FK_solicitud_cambio_horario_comentario_solicitud] FOREIGN KEY([sch_codigo])
REFERENCES [programacionacademica].[solicitud_cambio_horario] ([sch_codigo])
GO

ALTER TABLE [programacionacademica].[solicitud_cambio_horario_comentario] CHECK CONSTRAINT [FK_solicitud_cambio_horario_comentario_solicitud]
GO


