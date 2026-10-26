USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[agenda_periodo] Fecha de script: 26/10/2026 9:15:31 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[agenda_periodo](
	[idagenda] [numeric](18, 0) IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[creditos] [int] NULL,
	[caracter] [nchar](2) NULL,
	[hora_teorica] [int] NULL,
	[hora_practica] [int] NULL,
	[tradicional_o_credito] [nchar](2) NULL,
	[numero_total_hora] [int] NULL,
	[factor] [int] NULL,
	[semanas] [int] NULL,
	[vinculacion] [int] NULL,
	[uap_codigo] [int] NULL,
	[cur_codigo] [int] NULL,
	[sub_grupo] [nchar](2) NULL,
	[total_horas] [int] NULL,
	[per_codigo] [int] NULL,
	[uaa_codigo] [int] NULL,
	[factor_formula] [nchar](20) NULL,
 CONSTRAINT [PK_agenda_periodo] PRIMARY KEY CLUSTERED 
(
	[idagenda] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO


