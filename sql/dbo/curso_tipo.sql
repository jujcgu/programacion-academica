USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[curso_tipo] Fecha de script: 26/10/2026 9:28:23 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[curso_tipo](
	[cut_codigo] [tinyint] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[cut_nombre] [char](20) NULL,
	[cut_estado] [int] NULL,
 CONSTRAINT [PK_curso_tipo] PRIMARY KEY CLUSTERED 
(
	[cut_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO


