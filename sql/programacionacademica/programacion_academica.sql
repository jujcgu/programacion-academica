USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [programacionacademica].[programacion_academica] Fecha de script: 26/10/2026 8:29:41 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [programacionacademica].[programacion_academica](
	[pra_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[uaa_codigo] [int] NOT NULL,
	[prp_codigo] [int] NOT NULL,
	[cal_codigo] [int] NOT NULL,
	[pra_fecha_inicio] [datetime] NOT NULL,
	[pra_fecha_fin] [datetime] NOT NULL,
	[pra_estado] [tinyint] NOT NULL,
 CONSTRAINT [PK_pra_programacion_academica] PRIMARY KEY NONCLUSTERED 
(
	[pra_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [programacionacademica].[programacion_academica]  WITH CHECK ADD  CONSTRAINT [FK_programacion_academica_calendario] FOREIGN KEY([cal_codigo])
REFERENCES [dbo].[calendario] ([cal_codigo])
GO

ALTER TABLE [programacionacademica].[programacion_academica] CHECK CONSTRAINT [FK_programacion_academica_calendario]
GO

ALTER TABLE [programacionacademica].[programacion_academica]  WITH CHECK ADD  CONSTRAINT [FK_programacion_academica_proceso] FOREIGN KEY([prp_codigo])
REFERENCES [dbo].[programacion_proceso] ([prp_codigo])
GO

ALTER TABLE [programacionacademica].[programacion_academica] CHECK CONSTRAINT [FK_programacion_academica_proceso]
GO

ALTER TABLE [programacionacademica].[programacion_academica]  WITH CHECK ADD  CONSTRAINT [FK_programacion_academica_uaa] FOREIGN KEY([uaa_codigo])
REFERENCES [dbo].[uaa] ([uaa_codigo])
GO

ALTER TABLE [programacionacademica].[programacion_academica] CHECK CONSTRAINT [FK_programacion_academica_uaa]
GO


