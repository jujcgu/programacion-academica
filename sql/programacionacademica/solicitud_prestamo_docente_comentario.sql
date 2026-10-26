USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [programacionacademica].[solicitud_prestamo_docente_comentario] Fecha de script: 26/10/2026 8:34:26 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [programacionacademica].[solicitud_prestamo_docente_comentario](
	[spdc_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[spd_codigo] [int] NOT NULL,
	[spdc_estado] [tinyint] NOT NULL,
	[usu_codigo] [int] NOT NULL,
	[spdc_fecha_creacion] [datetime] NOT NULL,
	[spdc_mensaje] [varchar](max) NULL,
 CONSTRAINT [PK_spd_solicitud_prestamo_docente_comentario] PRIMARY KEY NONCLUSTERED 
(
	[spdc_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [programacionacademica].[solicitud_prestamo_docente_comentario]  WITH CHECK ADD  CONSTRAINT [FK_solicitud_prestamo_docente_comentario_solicitud] FOREIGN KEY([spd_codigo])
REFERENCES [programacionacademica].[solicitud_prestamo_docente] ([spd_codigo])
GO

ALTER TABLE [programacionacademica].[solicitud_prestamo_docente_comentario] CHECK CONSTRAINT [FK_solicitud_prestamo_docente_comentario_solicitud]
GO


