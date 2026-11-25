USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[usuario_docentes] Fecha de script: 25/11/2026 10:15:43 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[usuario_docentes](
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
	[us_fecha_inactivacion] [date] NULL,
	[us_fecha_actualizacion] [datetime] NULL,
 CONSTRAINT [PK_usuario_docentes] PRIMARY KEY CLUSTERED 
(
	[uid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[usuario_docentes] ADD  CONSTRAINT [DF_usuario_docentes_istipo]  DEFAULT ((3)) FOR [istipo]
GO


