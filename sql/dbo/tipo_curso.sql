USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[tipo_curso] Fecha de script: 26/10/2026 10:07:06 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[tipo_curso](
	[tic_codigo] [int] NOT NULL,
	[tic_nombre] [varchar](50) NULL,
	[tic_nombre_corto] [varchar](20) NULL,
 CONSTRAINT [PK_tipo_curso] PRIMARY KEY CLUSTERED 
(
	[tic_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO


