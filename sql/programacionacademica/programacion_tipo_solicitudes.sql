USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [programacionacademica].[programacion_tipo_solicitudes] Fecha de script: 26/10/2026 8:31:03 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [programacionacademica].[programacion_tipo_solicitudes](
	[pts_codigo] [int] IDENTITY(1,1) NOT NULL,
	[pts_nombre] [varchar](100) NOT NULL,
	[pts_estado] [tinyint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[pts_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO


