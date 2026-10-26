USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[matricula_configuracion] Fecha de script: 26/10/2026 9:53:07 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[matricula_configuracion](
	[mco_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[mco_nombre] [varchar](100) NULL,
	[mco_fecha] [datetime] NULL,
	[cal_codigo] [int] NULL,
	[pla_codigo] [int] NULL,
 CONSTRAINT [PK_matricula_configuracion] PRIMARY KEY NONCLUSTERED 
(
	[mco_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[matricula_configuracion] ADD  CONSTRAINT [DF_matricula_configuracion_mco_fecha]  DEFAULT (getdate()) FOR [mco_fecha]
GO

ALTER TABLE [dbo].[matricula_configuracion]  WITH NOCHECK ADD  CONSTRAINT [FK_matricula_configuracion_plan_academico] FOREIGN KEY([pla_codigo])
REFERENCES [dbo].[plan_academico] ([pla_codigo])
GO

ALTER TABLE [dbo].[matricula_configuracion] CHECK CONSTRAINT [FK_matricula_configuracion_plan_academico]
GO


