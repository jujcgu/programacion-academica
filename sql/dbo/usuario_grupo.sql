USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[usuario_grupo] Fecha de script: 26/10/2026 9:10:20 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[usuario_grupo](
	[usg_codigo] [int] IDENTITY(1,1) NOT NULL,
	[usg_usuario] [int] NULL,
	[usg_grupo] [int] NULL,
	[usg_uaa] [int] NULL,
	[usg_estado] [tinyint] NULL,
 CONSTRAINT [PK_usuario_grupo] PRIMARY KEY CLUSTERED 
(
	[usg_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[usuario_grupo] ADD  CONSTRAINT [DF_usuario_grupo_usg_estado_1]  DEFAULT ((1)) FOR [usg_estado]
GO


