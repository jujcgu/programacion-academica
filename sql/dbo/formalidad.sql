USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[formalidad] Fecha de script: 26/10/2026 9:49:57 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[formalidad](
	[for_codigo] [tinyint] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[for_nombre] [varchar](50) NULL,
	[sippa_for_codigo] [int] NULL,
 CONSTRAINT [PK_formalidad] PRIMARY KEY CLUSTERED 
(
	[for_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO


