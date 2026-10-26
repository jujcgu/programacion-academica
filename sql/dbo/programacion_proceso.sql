USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[programacion_proceso] Fecha de script: 26/10/2026 10:01:43 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[programacion_proceso](
	[prp_codigo] [int] NOT NULL,
	[prp_nombre] [char](50) NULL,
	[prp_orden] [int] NULL,
	[nuc_codigo] [varchar](10) NULL,
 CONSTRAINT [PK_programacion_proceso] PRIMARY KEY NONCLUSTERED 
(
	[prp_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO


