USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[dia] Fecha de script: 26/10/2026 9:30:13 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[dia](
	[dia_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[dia_nombre] [varchar](50) NULL,
	[dia_posicion_semana] [smallint] NULL,
	[dia_estado] [int] NOT NULL,
 CONSTRAINT [PK_dia] PRIMARY KEY CLUSTERED 
(
	[dia_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[dia] ADD  CONSTRAINT [DF_dia_dia_estado]  DEFAULT ((1)) FOR [dia_estado]
GO


