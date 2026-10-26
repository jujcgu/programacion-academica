USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[tipo_escala] Fecha de script: 26/10/2026 10:07:34 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[tipo_escala](
	[tes_codigo] [int] IDENTITY(1,1) NOT NULL,
	[tes_nombre] [varchar](255) NULL,
	[tes_estado] [varchar](1) NULL,
 CONSTRAINT [PK_tipo_escala] PRIMARY KEY CLUSTERED 
(
	[tes_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO


