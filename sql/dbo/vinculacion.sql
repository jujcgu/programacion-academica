USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[vinculacion] Fecha de script: 26/10/2026 10:11:23 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[vinculacion](
	[vin_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[vin_nombre] [varchar](50) NOT NULL,
	[vin_horas_year] [int] NULL,
	[vin_clase] [int] NULL,
	[sippa_vincodigo] [char](3) NULL,
	[vin_contratacion] [varchar](1) NULL,
	[vin_externa] [int] NULL,
	[vin_estado] [int] NOT NULL,
 CONSTRAINT [PK_vinculacion] PRIMARY KEY NONCLUSTERED 
(
	[vin_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[vinculacion] ADD  CONSTRAINT [DF_vinculacion_vin_contratacion]  DEFAULT ((0)) FOR [vin_contratacion]
GO

ALTER TABLE [dbo].[vinculacion] ADD  DEFAULT ((1)) FOR [vin_estado]
GO


