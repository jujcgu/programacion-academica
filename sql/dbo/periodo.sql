USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[periodo] Fecha de script: 26/10/2026 9:03:03 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[periodo](
	[per_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[pet_codigo] [int] NULL,
	[per_nombre] [varchar](50) NULL,
	[per_año] [int] NULL,
	[per_periodo] [tinyint] NULL,
	[per_fecha_inicio] [datetime] NULL,
	[per_fecha_fin] [datetime] NULL,
	[per_inicio_actividades] [date] NULL,
	[per_fin_actividades] [date] NULL,
	[per_acuerdo_actividades] [varchar](max) NULL,
	[sippa_per_codigo] [char](5) NULL,
 CONSTRAINT [PK_periodo] PRIMARY KEY NONCLUSTERED 
(
	[per_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[periodo]  WITH CHECK ADD  CONSTRAINT [FK_periodo_periodo_tipo] FOREIGN KEY([pet_codigo])
REFERENCES [dbo].[periodo_tipo] ([pet_codigo])
GO

ALTER TABLE [dbo].[periodo] CHECK CONSTRAINT [FK_periodo_periodo_tipo]
GO


