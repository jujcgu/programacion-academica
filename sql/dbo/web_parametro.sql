USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[web_parametro] Fecha de script: 26/10/2026 9:12:04 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[web_parametro](
	[wep_codigo] [int] IDENTITY(1,1) NOT NULL,
	[wep_nombre] [varchar](100) NOT NULL,
	[wep_valor] [varchar](max) NOT NULL,
	[wep_descripcion] [varchar](500) NULL,
	[wep_estado] [int] NOT NULL,
 CONSTRAINT [PK_web_parametro_1] PRIMARY KEY CLUSTERED 
(
	[wep_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[web_parametro] ADD  CONSTRAINT [DF_web_parametro_wep_estado]  DEFAULT ((1)) FOR [wep_estado]
GO


