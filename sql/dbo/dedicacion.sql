USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[dedicacion] Fecha de script: 26/10/2026 9:28:49 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[dedicacion](
	[ded_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[ded_nombre] [varchar](50) NOT NULL,
	[ded_orden_snies] [smallint] NULL,
	[sippa_dedcodigo] [char](1) NULL,
	[ded_codigo_hecaa] [smallint] NULL,
 CONSTRAINT [PK_dedicacion] PRIMARY KEY CLUSTERED 
(
	[ded_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO


