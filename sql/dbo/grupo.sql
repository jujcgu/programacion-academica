USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[grupo] Fecha de script: 26/10/2026 8:48:50 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[grupo](
	[gru_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[gru_nombre] [varchar](100) NOT NULL,
	[gru_id] [varchar](100) NULL,
	[gru_estado] [int] NULL,
 CONSTRAINT [PK_grupo] PRIMARY KEY NONCLUSTERED 
(
	[gru_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[grupo] ADD  CONSTRAINT [DF_grupo_gru_estado]  DEFAULT ((1)) FOR [gru_estado]
GO


