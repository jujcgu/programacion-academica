USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[matricula_autorizacion] Fecha de script: 26/10/2026 9:52:35 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[matricula_autorizacion](
	[maa_codigo] [tinyint] NOT NULL,
	[maa_nombre] [varchar](25) NULL,
	[maa_observcion] [varchar](100) NULL,
 CONSTRAINT [PK_matricula_autorizacion] PRIMARY KEY NONCLUSTERED 
(
	[maa_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO


