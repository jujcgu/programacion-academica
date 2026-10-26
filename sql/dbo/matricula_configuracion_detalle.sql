USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[matricula_configuracion_detalle] Fecha de script: 26/10/2026 9:53:21 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[matricula_configuracion_detalle](
	[mcd_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[mco_codigo] [int] NOT NULL,
	[mcd_fecha] [datetime] NOT NULL,
	[cur_codigo] [int] NOT NULL,
	[paa_codigo] [int] NOT NULL,
	[mcd_subgrupo] [char](2) NULL,
	[mcd_cerrado] [char](1) NULL,
	[mcd_estado] [int] NULL,
 CONSTRAINT [PK_matricula_configuracion_detalle] PRIMARY KEY NONCLUSTERED 
(
	[mcd_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[matricula_configuracion_detalle] ADD  CONSTRAINT [DF_matricula_configuracion_detalle_mcd_fecha]  DEFAULT (getdate()) FOR [mcd_fecha]
GO

ALTER TABLE [dbo].[matricula_configuracion_detalle] ADD  CONSTRAINT [DF_matricula_configuracion_detalle_mcd_estado]  DEFAULT (1) FOR [mcd_cerrado]
GO

ALTER TABLE [dbo].[matricula_configuracion_detalle] ADD  DEFAULT ((1)) FOR [mcd_estado]
GO

ALTER TABLE [dbo].[matricula_configuracion_detalle]  WITH CHECK ADD  CONSTRAINT [FK_matricula_configuracion_detalle_curso] FOREIGN KEY([cur_codigo])
REFERENCES [dbo].[curso] ([cur_codigo])
GO

ALTER TABLE [dbo].[matricula_configuracion_detalle] CHECK CONSTRAINT [FK_matricula_configuracion_detalle_curso]
GO

ALTER TABLE [dbo].[matricula_configuracion_detalle]  WITH CHECK ADD  CONSTRAINT [FK_matricula_configuracion_detalle_matricula_configuracion] FOREIGN KEY([mco_codigo])
REFERENCES [dbo].[matricula_configuracion] ([mco_codigo])
GO

ALTER TABLE [dbo].[matricula_configuracion_detalle] CHECK CONSTRAINT [FK_matricula_configuracion_detalle_matricula_configuracion]
GO

ALTER TABLE [dbo].[matricula_configuracion_detalle]  WITH CHECK ADD  CONSTRAINT [FK_matricula_configuracion_detalle_plan_academico_asignatura] FOREIGN KEY([paa_codigo])
REFERENCES [dbo].[plan_academico_asignatura] ([paa_codigo])
GO

ALTER TABLE [dbo].[matricula_configuracion_detalle] CHECK CONSTRAINT [FK_matricula_configuracion_detalle_plan_academico_asignatura]
GO


