USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[agenda_periodo_novedad] Fecha de script: 26/10/2026 9:16:02 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[agenda_periodo_novedad](
	[apn_id] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[novedad] [text] NULL,
	[fecha] [date] NULL,
	[ag_id] [int] NULL,
	[periodo] [int] NULL,
	[per_codigo] [int] NULL,
 CONSTRAINT [PK_agenda_periodo_novedad] PRIMARY KEY CLUSTERED 
(
	[apn_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO


