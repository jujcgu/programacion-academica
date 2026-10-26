USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[curso] Fecha de script: 26/10/2026 9:26:07 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[curso](
	[cur_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[uap_codigo] [int] NULL,
	[asi_codigo] [int] NULL,
	[sed_codigo] [int] NULL,
	[cal_codigo] [int] NULL,
	[cur_grupo] [char](2) NULL,
	[cur_cupo] [smallint] NULL,
	[cur_estado] [tinyint] NULL,
	[tic_codigo] [int] NULL,
	[cut_codigo] [tinyint] NULL,
	[pla_codigo] [int] NULL,
	[cur_exclusivo] [bit] NULL,
	[cur_fecha_inicio] [datetime] NULL,
	[cur_semanas] [tinyint] NULL,
	[cur_cierre] [tinyint] NULL,
	[cur_grabado] [tinyint] NULL,
	[cdp_codigo] [int] NULL,
	[usu_codigo] [int] NULL,
	[usu_clave] [varchar](50) NULL,
	[sippa_sedcodigo] [char](2) NULL,
	[sippa_calcodigo] [char](6) NULL,
	[sippa_progcodigo] [char](4) NULL,
	[sippa_plancodigo] [char](7) NULL,
	[sippa_asicodigo] [char](8) NULL,
	[sippa_grucodigo] [char](2) NULL,
	[sippa_forma] [char](15) NULL,
	[cur_codigo_anterior] [int] NULL,
	[cur_observaciones] [varchar](200) NULL,
	[cur_ampliacion_cupo] [int] NULL,
	[cur_fecha_actualizacion] [datetime] NULL,
	[cur_notaparcial] [varchar](1) NULL,
	[tes_codigo] [int] NULL,
	[cur_url] [varchar](100) NULL,
	[cur_id_evento] [varchar](30) NULL,
 CONSTRAINT [PK_curso_1] PRIMARY KEY CLUSTERED 
(
	[cur_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[curso] ADD  CONSTRAINT [DF_curso_tic_codigo]  DEFAULT ((1)) FOR [tic_codigo]
GO

ALTER TABLE [dbo].[curso] ADD  CONSTRAINT [DF_curso_cut_codigo]  DEFAULT ((1)) FOR [cut_codigo]
GO

ALTER TABLE [dbo].[curso] ADD  CONSTRAINT [DF_curso_cur_exclusivo_1]  DEFAULT ((1)) FOR [cur_exclusivo]
GO

ALTER TABLE [dbo].[curso] ADD  CONSTRAINT [DF_curso_cur_cierre]  DEFAULT ((1)) FOR [cur_cierre]
GO

ALTER TABLE [dbo].[curso] ADD  CONSTRAINT [DF_curso_cur_grabado]  DEFAULT ((0)) FOR [cur_grabado]
GO

ALTER TABLE [dbo].[curso] ADD  CONSTRAINT [DF_curso_cur_ampliacion_cupo]  DEFAULT ((0)) FOR [cur_ampliacion_cupo]
GO

ALTER TABLE [dbo].[curso] ADD  CONSTRAINT [DF_curso_cur_fecha_actualizacion]  DEFAULT (getdate()) FOR [cur_fecha_actualizacion]
GO

ALTER TABLE [dbo].[curso] ADD  CONSTRAINT [DF_curso_tes_codigo]  DEFAULT ((1)) FOR [tes_codigo]
GO

ALTER TABLE [dbo].[curso]  WITH CHECK ADD  CONSTRAINT [FK_curso_asignatura] FOREIGN KEY([asi_codigo])
REFERENCES [dbo].[asignatura] ([asi_codigo])
GO

ALTER TABLE [dbo].[curso] CHECK CONSTRAINT [FK_curso_asignatura]
GO

ALTER TABLE [dbo].[curso]  WITH CHECK ADD  CONSTRAINT [FK_curso_uaa_personal] FOREIGN KEY([uap_codigo])
REFERENCES [dbo].[uaa_personal] ([uap_codigo])
GO

ALTER TABLE [dbo].[curso] CHECK CONSTRAINT [FK_curso_uaa_personal]
GO


