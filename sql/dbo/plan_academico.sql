USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[plan_academico] Fecha de script: 26/10/2026 10:00:11 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[plan_academico](
	[pla_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[pla_nombre] [char](10) NULL,
	[pro_codigo] [int] NOT NULL,
	[nac_codigo] [int] NULL,
	[pla_creditos] [tinyint] NULL,
	[pla_total_creditos] [int] NULL,
	[pla_requisito_grado] [tinyint] NULL,
	[pla_antiguo] [tinyint] NULL,
	[pla_tipo_registro] [varchar](50) NULL,
	[pla_estado] [tinyint] NULL,
	[pla_fecha] [datetime] NULL,
	[res_codigo] [int] NULL,
	[pla_actual] [tinyint] NULL,
	[snies_periodicidad] [int] NULL,
	[snies_numero_periodos] [int] NULL,
	[sippa_placodigo] [char](7) NULL,
	[sippa_procodigo] [char](4) NULL,
	[pla_total_horas] [int] NULL,
	[fecha_creacion] [datetime] NOT NULL,
 CONSTRAINT [PK_plan_academico] PRIMARY KEY NONCLUSTERED 
(
	[pla_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[plan_academico] ADD  CONSTRAINT [DF_plan_academico_pla_antiguedad]  DEFAULT ((0)) FOR [pla_antiguo]
GO

ALTER TABLE [dbo].[plan_academico] ADD  CONSTRAINT [DF_plan_academico_pla_estado]  DEFAULT ((0)) FOR [pla_estado]
GO

ALTER TABLE [dbo].[plan_academico] ADD  CONSTRAINT [DF_plan_academico_pla_actual]  DEFAULT ((1)) FOR [pla_actual]
GO

ALTER TABLE [dbo].[plan_academico] ADD  CONSTRAINT [DF_plan_academico_fecha_creacion_registro]  DEFAULT (getdate()) FOR [fecha_creacion]
GO

ALTER TABLE [dbo].[plan_academico]  WITH CHECK ADD  CONSTRAINT [FK__plan_acad__nac_c__1BE45685] FOREIGN KEY([nac_codigo])
REFERENCES [dbo].[nivel_academico_creditos] ([nac_codigo])
GO

ALTER TABLE [dbo].[plan_academico] CHECK CONSTRAINT [FK__plan_acad__nac_c__1BE45685]
GO


