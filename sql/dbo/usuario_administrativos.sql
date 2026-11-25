USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[usuario_administrativos] Fecha de script: 25/11/2026 10:13:24 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[usuario_administrativos](
	[uid] [int] NOT NULL,
	[up] [int] NULL,
	[us] [varchar](20) NULL,
	[uwd_seguridadold] [varchar](64) NULL,
	[uwd] [varbinary](64) NULL,
	[uwd2] [varbinary](64) NULL,
	[uwd_anterior] [varchar](64) NULL,
	[istipo] [tinyint] NULL,
	[ischange] [tinyint] NULL,
	[state] [tinyint] NULL,
	[sys] [varchar](200) NULL,
	[us_correo] [varchar](100) NULL,
	[us_pregunta] [varchar](255) NULL,
	[us_respuesta] [varchar](255) NULL,
	[us_encriptado] [varbinary](64) NULL,
 CONSTRAINT [PK_usuario_administrativos] PRIMARY KEY CLUSTERED 
(
	[uid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[usuario_administrativos] ADD  CONSTRAINT [DF_usuario_administrativos_istipo]  DEFAULT ((1)) FOR [istipo]
GO


