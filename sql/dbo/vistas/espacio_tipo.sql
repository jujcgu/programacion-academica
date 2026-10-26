USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[espacio_tipo] Fecha de script: 26/10/2026 9:48:09 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[espacio_tipo](
	[eti_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[eti_nombre] [varchar](50) NOT NULL,
	[sippa_tipcodigo] [char](2) NULL,
	[etm_codigo] [int] NULL,
 CONSTRAINT [PK_espacio_tipo] PRIMARY KEY CLUSTERED 
(
	[eti_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO


