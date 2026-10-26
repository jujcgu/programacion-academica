USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[proyecto_tipo] Fecha de script: 26/10/2026 10:02:38 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[proyecto_tipo](
	[prt_codigo] [int] NOT NULL,
	[prt_nombre] [varchar](50) NULL,
	[sippa_tiproycodigo] [char](2) NULL,
 CONSTRAINT [PK_proyecto_tipo] PRIMARY KEY NONCLUSTERED 
(
	[prt_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO


