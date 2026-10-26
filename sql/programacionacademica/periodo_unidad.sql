USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [programacionacademica].[periodo_unidad] Fecha de script: 26/10/2026 8:29:00 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [programacionacademica].[periodo_unidad](
	[peu_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[uaa_codigo] [int] NOT NULL,
	[per_codigo] [int] NOT NULL,
	[peu_fecha_inicio] [date] NOT NULL,
	[peu_fecha_fin] [date] NOT NULL,
	[peu_estado] [tinyint] NOT NULL,
 CONSTRAINT [PK_peu_periodo_unidad] PRIMARY KEY NONCLUSTERED 
(
	[peu_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [programacionacademica].[periodo_unidad]  WITH CHECK ADD  CONSTRAINT [FK_periodo_unidad_periodo] FOREIGN KEY([per_codigo])
REFERENCES [dbo].[periodo] ([per_codigo])
GO

ALTER TABLE [programacionacademica].[periodo_unidad] CHECK CONSTRAINT [FK_periodo_unidad_periodo]
GO

ALTER TABLE [programacionacademica].[periodo_unidad]  WITH CHECK ADD  CONSTRAINT [FK_periodo_unidad_uaa] FOREIGN KEY([uaa_codigo])
REFERENCES [dbo].[uaa] ([uaa_codigo])
GO

ALTER TABLE [programacionacademica].[periodo_unidad] CHECK CONSTRAINT [FK_periodo_unidad_uaa]
GO


