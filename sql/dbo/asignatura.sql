USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[asignatura] Fecha de script: 26/10/2026 8:47:12 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[asignatura](
	[asi_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[asi_nombre] [varchar](100) NULL,
	[asi_nombre_corto] [varchar](11) NULL,
	[asi_nombre_impresion] [varchar](12) NULL,
	[uaa_codigo] [int] NULL,
	[asi_publicar] [tinyint] NULL,
	[asi_creditos] [tinyint] NULL,
	[asi_creditos_teoria] [tinyint] NULL,
	[asi_creditos_practica] [tinyint] NULL,
	[car_codigo] [char](2) NOT NULL,
	[asi_trabajo_presencial] [smallint] NULL,
	[asi_trabajo_independiente] [smallint] NULL,
	[asi_estado] [tinyint] NULL,
	[nuc_codigo] [int] NULL,
	[asi_semanasxsemestre] [smallint] NULL,
	[nbc_codigo] [int] NULL,
	[asi_extramuro] [char](1) NULL,
	[sippa_asicodigo] [char](8) NULL,
	[sippa_plancodigo] [char](7) NULL,
	[sippa_progcodigo] [char](4) NULL,
	[asi_pendiente_nbc] [char](60) NULL,
	[asi_credito_migrado_paa] [char](60) NULL,
	[asi_fecha_actualizacion] [datetime] NULL,
	[for_codigo] [int] NOT NULL,
	[asi_trabajo_horas_teorico] [int] NULL,
	[asi_trabajo_horas_practico] [int] NULL,
	[asi_trabajo_horas_teorico_practico] [int] NULL,
	[asi_trabajo_horas_semestral_teorico] [int] NULL,
	[asi_trabajo_horas_semestral_practico] [int] NULL,
	[asi_trabajo_horas_semestral_teorico_practico] [int] NULL,
	[asi_trabajo_horas_semestral_independiente] [int] NULL,
 CONSTRAINT [PK_asignatura] PRIMARY KEY CLUSTERED 
(
	[asi_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[asignatura] ADD  CONSTRAINT [DF_asignatura_asi_fecha_actualizacion]  DEFAULT (getdate()) FOR [asi_fecha_actualizacion]
GO

ALTER TABLE [dbo].[asignatura] ADD  CONSTRAINT [DF__asignatur__for_c__2D75C97F]  DEFAULT ((1)) FOR [for_codigo]
GO

ALTER TABLE [dbo].[asignatura]  WITH NOCHECK ADD  CONSTRAINT [FK_asignatura_nucleo] FOREIGN KEY([nuc_codigo])
REFERENCES [dbo].[nucleo] ([nuc_codigo])
GO

ALTER TABLE [dbo].[asignatura] CHECK CONSTRAINT [FK_asignatura_nucleo]
GO

ALTER TABLE [dbo].[asignatura]  WITH NOCHECK ADD  CONSTRAINT [FK_asignatura_uaa] FOREIGN KEY([uaa_codigo])
REFERENCES [dbo].[uaa] ([uaa_codigo])
GO

ALTER TABLE [dbo].[asignatura] CHECK CONSTRAINT [FK_asignatura_uaa]
GO


