USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [programacionacademica].[programacion_gestion] Fecha de script: 26/10/2026 8:30:25 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [programacionacademica].[programacion_gestion](
	[prg_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[uaa_codigo] [int] NOT NULL,
	[cal_codigo] [int] NOT NULL,
	[prg_fecha_inicio] [datetime] NOT NULL,
	[prg_fecha_fin] [datetime] NOT NULL,
	[prg_estado] [tinyint] NOT NULL,
	[pts_codigo] [int] NOT NULL,
 CONSTRAINT [PK_prg_programacion_gestion] PRIMARY KEY NONCLUSTERED 
(
	[prg_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [programacionacademica].[programacion_gestion]  WITH CHECK ADD  CONSTRAINT [FK_programacion_gestion_calendario] FOREIGN KEY([cal_codigo])
REFERENCES [dbo].[calendario] ([cal_codigo])
GO

ALTER TABLE [programacionacademica].[programacion_gestion] CHECK CONSTRAINT [FK_programacion_gestion_calendario]
GO

ALTER TABLE [programacionacademica].[programacion_gestion]  WITH CHECK ADD  CONSTRAINT [FK_programacion_gestion_tipo_solicitud] FOREIGN KEY([pts_codigo])
REFERENCES [programacionacademica].[programacion_tipo_solicitudes] ([pts_codigo])
GO

ALTER TABLE [programacionacademica].[programacion_gestion] CHECK CONSTRAINT [FK_programacion_gestion_tipo_solicitud]
GO

ALTER TABLE [programacionacademica].[programacion_gestion]  WITH CHECK ADD  CONSTRAINT [FK_programacion_gestion_uaa] FOREIGN KEY([uaa_codigo])
REFERENCES [dbo].[uaa] ([uaa_codigo])
GO

ALTER TABLE [programacionacademica].[programacion_gestion] CHECK CONSTRAINT [FK_programacion_gestion_uaa]
GO


