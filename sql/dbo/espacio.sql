USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[espacio] Fecha de script: 26/10/2026 9:34:46 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[espacio](
	[esp_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[esp_nombre] [varchar](55) NOT NULL,
	[esp_nombre_corto] [varchar](50) NULL,
	[blo_codigo] [int] NULL,
	[esp_capacidad] [int] NOT NULL,
	[esp_area] [float] NULL,
	[eti_codigo] [int] NULL,
	[esp_compartido] [char](1) NOT NULL,
	[esp_descripcion] [varchar](255) NOT NULL,
	[uaa_codigo_responsable] [int] NULL,
	[esp_luminosidad] [char](1) NULL,
	[esp_espacio_codigo] [char](3) NULL,
	[esp_capacidad_covid] [int] NULL,
	[esp_habilitado_covid] [int] NULL,
	[sippa_salcodigo] [char](8) NULL,
	[esp_estado] [int] NULL,
	[esp_puntos_elect] [int] NULL,
	[esp_puntos_red] [int] NULL,
	[esp_puntos_tel] [int] NULL,
	[esp_metros_pared] [float] NULL,
	[esp_metros_suelo] [float] NULL,
	[mun_codigo] [int] NULL,
 CONSTRAINT [PK_espacios] PRIMARY KEY NONCLUSTERED 
(
	[esp_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[espacio]  WITH CHECK ADD  CONSTRAINT [FK_espacio_espacio_tipo] FOREIGN KEY([eti_codigo])
REFERENCES [dbo].[espacio_tipo] ([eti_codigo])
GO

ALTER TABLE [dbo].[espacio] CHECK CONSTRAINT [FK_espacio_espacio_tipo]
GO

ALTER TABLE [dbo].[espacio]  WITH CHECK ADD  CONSTRAINT [FK_espacio_municipio] FOREIGN KEY([mun_codigo])
REFERENCES [dbo].[municipio] ([mun_codigo])
GO

ALTER TABLE [dbo].[espacio] CHECK CONSTRAINT [FK_espacio_municipio]
GO


