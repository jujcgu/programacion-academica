USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[calendario] Fecha de script: 26/10/2026 8:48:12 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[calendario](
	[cal_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[per_codigo] [int] NOT NULL,
	[cal_nombre] [varchar](30) NULL,
	[cal_fecha] [datetime] NULL,
	[cal_documento] [varchar](10) NULL,
	[sippa_cal_codigo] [char](6) NULL,
	[cal_ano_salario_minimo] [int] NULL,
	[cal_estado] [varchar](1) NULL,
 CONSTRAINT [PK_calendario] PRIMARY KEY CLUSTERED 
(
	[cal_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[calendario] ADD  DEFAULT ((1)) FOR [cal_estado]
GO

ALTER TABLE [dbo].[calendario]  WITH CHECK ADD  CONSTRAINT [FK_calendario_periodo] FOREIGN KEY([per_codigo])
REFERENCES [dbo].[periodo] ([per_codigo])
GO

ALTER TABLE [dbo].[calendario] CHECK CONSTRAINT [FK_calendario_periodo]
GO


