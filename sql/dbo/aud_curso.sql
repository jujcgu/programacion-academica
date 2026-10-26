USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[aud_curso] Fecha de script: 26/10/2026 9:17:29 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[aud_curso](
	[aud_codigo_cur] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[aud_log_type] [char](6) NULL,
	[cur_codigo] [int] NOT NULL,
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
	[usu_clave] [char](50) NULL,
	[cur_observaciones] [varchar](200) NULL,
	[cur_ampliacion_cupo] [int] NULL,
	[cur_fecha_actualizacion] [datetime] NULL,
	[cur_notaparcial] [varchar](1) NULL,
	[tes_codigo] [int] NULL,
	[cur_url] [varchar](100) NULL,
	[cur_id_evento] [varchar](30) NULL,
	[aud_user] [sysname] NOT NULL,
	[aud_changed] [datetime] NULL,
	[aud_host] [varchar](200) NULL,
 CONSTRAINT [PK_aud_curso] PRIMARY KEY CLUSTERED 
(
	[aud_codigo_cur] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[aud_curso] ADD  CONSTRAINT [DF_aud_curso_aud_user]  DEFAULT (suser_sname()) FOR [aud_user]
GO

ALTER TABLE [dbo].[aud_curso] ADD  CONSTRAINT [DF_aud_curso_aud_changed]  DEFAULT (getdate()) FOR [aud_changed]
GO

ALTER TABLE [dbo].[aud_curso] ADD  CONSTRAINT [DF_aud_curso_aud_host]  DEFAULT (host_name()) FOR [aud_host]
GO


