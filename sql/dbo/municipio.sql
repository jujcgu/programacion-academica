USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[municipio] Fecha de script: 26/10/2026 9:54:28 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[municipio](
	[mun_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[mun_id] [char](5) NULL,
	[mun_nombre] [varchar](100) NOT NULL,
	[dep_codigo] [int] NOT NULL,
	[sippa_mun_codigo] [int] NULL,
	[SNIES_codigo] [char](5) NULL,
	[dane_codigo] [char](10) NULL,
 CONSTRAINT [PK_municipio] PRIMARY KEY NONCLUSTERED 
(
	[mun_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO


