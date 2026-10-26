USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[programa] Fecha de script: 26/10/2026 10:01:22 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[programa](
	[pro_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[pro_programa] [char](4) NULL,
	[sed_codigo] [int] NOT NULL,
	[uaa_codigo] [int] NOT NULL,
	[uaa_codigo_unificado] [int] NULL,
	[nia_codigo] [int] NULL,
	[pro_registro_icfes] [varchar](50) NULL,
	[pro_registro_snies] [varchar](50) NULL,
	[pro_extension_snies] [char](1) NULL,
	[jor_codigo] [int] NULL,
	[res_codigo] [int] NULL,
	[pro_titulo_otorgado] [varchar](100) NULL,
	[pro_fecha_creacion] [datetime] NULL,
	[mod_codigo] [tinyint] NULL,
	[con_codigo] [int] NULL,
	[pro_horario] [varchar](100) NULL,
	[pro_estado] [char](2) NULL,
	[pro_propio] [char](1) NULL,
	[uaa_programa_gen] [int] NULL,
	[par_codigo] [int] NULL,
	[nbc_codigo] [int] NULL,
	[pro_calendario] [char](1) NULL,
	[sippa_pro_codigo] [char](4) NULL,
	[pro_descripcion] [varchar](max) NULL,
	[pro_creacion_snies] [date] NULL,
	[cam_det_codigo] [int] NULL,
	[pro_propedeutico] [int] NULL,
 CONSTRAINT [PK_programa] PRIMARY KEY CLUSTERED 
(
	[pro_codigo] ASC,
	[uaa_codigo] ASC,
	[sed_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[programa] ADD  CONSTRAINT [DF_programa_pro_extension_snies]  DEFAULT ('n') FOR [pro_extension_snies]
GO

ALTER TABLE [dbo].[programa] ADD  CONSTRAINT [DF_programa_pro_fecha_creacion]  DEFAULT (getdate()) FOR [pro_fecha_creacion]
GO

ALTER TABLE [dbo].[programa] ADD  DEFAULT ((0)) FOR [pro_propedeutico]
GO

ALTER TABLE [dbo].[programa]  WITH CHECK ADD  CONSTRAINT [FK_programa_nivel_academico] FOREIGN KEY([nia_codigo])
REFERENCES [dbo].[nivel_academico] ([nia_codigo])
GO

ALTER TABLE [dbo].[programa] CHECK CONSTRAINT [FK_programa_nivel_academico]
GO

ALTER TABLE [dbo].[programa]  WITH CHECK ADD  CONSTRAINT [FK_programa_sede] FOREIGN KEY([sed_codigo])
REFERENCES [dbo].[sede] ([sed_codigo])
GO

ALTER TABLE [dbo].[programa] CHECK CONSTRAINT [FK_programa_sede]
GO

ALTER TABLE [dbo].[programa]  WITH NOCHECK ADD  CONSTRAINT [FK_programa_uaa_agosto2018] FOREIGN KEY([uaa_codigo])
REFERENCES [dbo].[uaa] ([uaa_codigo])
GO

ALTER TABLE [dbo].[programa] CHECK CONSTRAINT [FK_programa_uaa_agosto2018]
GO

ALTER TABLE [dbo].[programa]  WITH CHECK ADD  CONSTRAINT [programa_cam_detFK] FOREIGN KEY([cam_det_codigo])
REFERENCES [acreditacion].[campo_detallado] ([cam_det_codigo])
GO

ALTER TABLE [dbo].[programa] CHECK CONSTRAINT [programa_cam_detFK]
GO


