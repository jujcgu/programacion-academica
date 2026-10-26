USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[plan_academico_asignatura] Fecha de script: 26/10/2026 10:00:30 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[plan_academico_asignatura](
	[paa_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[pla_codigo] [int] NOT NULL,
	[asi_codigo] [int] NOT NULL,
	[paa_area] [char](10) NULL,
	[paa_subarea] [char](10) NULL,
	[paa_semestre] [int] NULL,
	[paa_credito] [int] NOT NULL,
	[paa_intensidad] [int] NULL,
	[pet_codigo] [int] NULL,
	[nuc_codigo] [int] NULL,
	[com_codigo] [int] NULL,
	[paa_estado] [char](10) NULL,
	[paa_nota_minima] [float] NOT NULL,
	[paa_chequeo_requisito] [tinyint] NULL,
	[paa_plan_academico] [tinyint] NULL,
	[paa_obligatoria] [char](1) NULL,
	[paa_programable] [char](1) NULL,
	[paa_multi_asignatura] [char](1) NULL,
	[paa_semanaxsemestre] [int] NULL,
	[paa_h_trabajo_ind_sem] [int] NULL,
	[sippa_plancodigo] [char](7) NULL,
	[sippa_asicodigo] [char](8) NULL,
	[sippa_progcodigo] [char](4) NULL,
	[for_codigo] [int] NOT NULL,
 CONSTRAINT [PK_plan_academico_asignatura] PRIMARY KEY CLUSTERED 
(
	[paa_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[plan_academico_asignatura] ADD  CONSTRAINT [DF_plan_academico_asignatura_paa_credito]  DEFAULT ((0)) FOR [paa_credito]
GO

ALTER TABLE [dbo].[plan_academico_asignatura] ADD  CONSTRAINT [DF_plan_academico_asignatura_pet_codigo]  DEFAULT ((1)) FOR [pet_codigo]
GO

ALTER TABLE [dbo].[plan_academico_asignatura] ADD  CONSTRAINT [DF_plan_academico_asignatura_paa_nota_minima]  DEFAULT ((3.0)) FOR [paa_nota_minima]
GO

ALTER TABLE [dbo].[plan_academico_asignatura] ADD  CONSTRAINT [DF_plan_academico_asignatura_paa_chequeo_requisito]  DEFAULT ((0)) FOR [paa_chequeo_requisito]
GO

ALTER TABLE [dbo].[plan_academico_asignatura] ADD  CONSTRAINT [DF_plan_academico_asignatura_paa_plan_academico]  DEFAULT ((0)) FOR [paa_plan_academico]
GO

ALTER TABLE [dbo].[plan_academico_asignatura] ADD  CONSTRAINT [DF_plan_academico_asignatura_paa_programable]  DEFAULT ('s') FOR [paa_programable]
GO

ALTER TABLE [dbo].[plan_academico_asignatura] ADD  CONSTRAINT [DF_plan_academico_asignatura_paa_multi_asignatura]  DEFAULT ('n') FOR [paa_multi_asignatura]
GO

ALTER TABLE [dbo].[plan_academico_asignatura] ADD  CONSTRAINT [DF__plan_acad__for_c__2E69EDB8]  DEFAULT ((1)) FOR [for_codigo]
GO

ALTER TABLE [dbo].[plan_academico_asignatura]  WITH NOCHECK ADD  CONSTRAINT [FK_plan_academico_asignatura_asignatura_agosto2018] FOREIGN KEY([asi_codigo])
REFERENCES [dbo].[asignatura] ([asi_codigo])
GO

ALTER TABLE [dbo].[plan_academico_asignatura] CHECK CONSTRAINT [FK_plan_academico_asignatura_asignatura_agosto2018]
GO

ALTER TABLE [dbo].[plan_academico_asignatura]  WITH CHECK ADD  CONSTRAINT [FK_plan_academico_asignatura_plan_academico] FOREIGN KEY([pla_codigo])
REFERENCES [dbo].[plan_academico] ([pla_codigo])
GO

ALTER TABLE [dbo].[plan_academico_asignatura] CHECK CONSTRAINT [FK_plan_academico_asignatura_plan_academico]
GO


