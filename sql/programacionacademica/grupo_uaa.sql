USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [programacionacademica].[grupo_uaa] Fecha de script: 26/10/2026 8:25:36 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [programacionacademica].[grupo_uaa](
	[pgr_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[pgr_nombre] [varchar](100) NOT NULL,
	[pgr_estado] [int] NOT NULL,
 CONSTRAINT [PK_pgr_codigo] PRIMARY KEY NONCLUSTERED 
(
	[pgr_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO


