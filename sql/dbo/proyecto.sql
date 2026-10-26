USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[proyecto] Fecha de script: 26/10/2026 10:02:10 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[proyecto](
	[pry_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[gru_codigo] [int] NULL,
	[pry_nombre] [varchar](300) NOT NULL,
	[prt_codigo] [int] NOT NULL,
	[pry_coordinador] [int] NULL,
	[pry_fecha_inicio] [datetime] NULL,
	[pry_fecha_fin] [datetime] NULL,
	[pry_cvlac] [char](10) NULL,
	[pry_resultados] [varchar](200) NULL,
	[pry_colciencias] [int] NULL,
	[pry_resumen] [varchar](200) NULL,
	[pry_objetivo] [varchar](200) NULL,
	[pre_codigo] [int] NULL,
	[pry_duracionestimada] [smallint] NULL,
	[pry_acto_administrativo] [nchar](50) NULL,
	[pry_acto_administrativo_fecha] [datetime] NULL,
	[pry_acta_aprobacion] [nvarchar](500) NULL,
	[pry_justificacion_beneficio] [nvarchar](4000) NULL,
	[pry_secretario_administrativo] [int] NULL,
	[pry_decano] [int] NULL,
	[pry_facultad] [int] NULL,
	[prs_codigo] [int] NULL,
	[prc_codigo] [int] NULL,
	[sippa_proycodigo] [char](10) NULL,
 CONSTRAINT [PK_proyecto] PRIMARY KEY NONCLUSTERED 
(
	[pry_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[proyecto]  WITH NOCHECK ADD  CONSTRAINT [FK_proyecto_grupo] FOREIGN KEY([gru_codigo])
REFERENCES [dbo].[grupo] ([gru_codigo])
GO

ALTER TABLE [dbo].[proyecto] CHECK CONSTRAINT [FK_proyecto_grupo]
GO

ALTER TABLE [dbo].[proyecto]  WITH NOCHECK ADD  CONSTRAINT [FK_proyecto_proyecto_estado] FOREIGN KEY([pre_codigo])
REFERENCES [dbo].[proyecto_estado] ([pre_codigo])
GO

ALTER TABLE [dbo].[proyecto] CHECK CONSTRAINT [FK_proyecto_proyecto_estado]
GO

ALTER TABLE [dbo].[proyecto]  WITH NOCHECK ADD  CONSTRAINT [FK_proyecto_proyecto_tipo] FOREIGN KEY([prt_codigo])
REFERENCES [dbo].[proyecto_tipo] ([prt_codigo])
GO

ALTER TABLE [dbo].[proyecto] CHECK CONSTRAINT [FK_proyecto_proyecto_tipo]
GO


