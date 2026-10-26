USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[equivalencia] Fecha de script: 26/10/2026 9:33:42 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[equivalencia](
	[equ_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[pla_codigo] [int] NULL,
	[asi_codigo] [int] NULL,
	[asi_equivalencia] [int] NULL,
 CONSTRAINT [PK_equivalencia] PRIMARY KEY CLUSTERED 
(
	[equ_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO


