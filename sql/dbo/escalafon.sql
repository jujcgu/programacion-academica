USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[escalafon] Fecha de script: 26/10/2026 9:34:09 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[escalafon](
	[esc_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[esc_nombre] [varchar](50) NOT NULL,
	[esc_cap_puntos] [int] NULL,
	[sippa_esccodigo] [char](2) NULL,
 CONSTRAINT [PK_escalafon] PRIMARY KEY CLUSTERED 
(
	[esc_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO


