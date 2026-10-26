USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[aud_matricula_curso] Fecha de script: 26/10/2026 9:19:04 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[aud_matricula_curso](
	[aud_codigo_mat_curso] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[aud_log_type] [char](6) NOT NULL,
	[mac_codigo] [int] NOT NULL,
	[mat_codigo] [int] NULL,
	[cur_codigo] [int] NULL,
	[mac_subgrupo] [char](2) NULL,
	[mac_estado] [char](1) NULL,
	[mac_nota] [float] NULL,
	[mac_habilitacion] [float] NULL,
	[mac_perdio_fallas] [char](1) NULL,
	[mac_definitiva] [float] NULL,
	[maf_codigo] [tinyint] NULL,
	[res_codigo] [int] NULL,
	[paa_codigo] [int] NULL,
	[mac_novedad] [varchar](400) NULL,
	[maa_codigo] [tinyint] NULL,
	[mac_usuario] [int] NULL,
	[mac_ip_nota] [varchar](50) NULL,
	[mac_clave] [varchar](50) NULL,
	[mac_cliente] [varchar](50) NULL,
	[mac_fecha_nota] [datetime] NULL,
	[paa_codigo_anterior] [int] NULL,
	[aud_user] [sysname] NOT NULL,
	[aud_ip_nota] [varchar](50) NULL,
	[aud_changed] [datetime] NULL,
	[aud_host] [varchar](200) NULL,
	[aud_mac] [nchar](12) NULL,
	[aud_programname] [nchar](128) NULL,
	[aud_fechainiciologin] [datetime] NULL,
	[aud_perdio_fallas] [char](1) NULL,
	[aud_usuario_nota] [varchar](50) NULL,
	[aud_cliente_nota] [varchar](50) NULL,
	[aud_sippa_sedcodigo] [char](2) NULL,
	[aud_sippa_calcodigo] [char](6) NULL,
	[aud_sippa_estcodigo] [char](12) NULL,
	[aud_sippa_progcodigo] [char](4) NULL,
	[aud_sippa_plancodigo] [char](7) NULL,
	[aud_sippa_asicodigo] [char](8) NULL,
	[aud_sippa_grucodigo] [char](2) NULL,
	[aud_sippa_subgrucodigo] [char](10) NULL,
	[aud_sippa_cursemestre] [smallint] NULL,
	[aud_sippa_curasignatura] [char](8) NULL,
	[aud_sippa_curnomasigna] [varchar](max) NULL,
	[aud_sippa_curforma] [char](15) NULL,
	[aud_codigo_mac] [int] NULL,
	[mac_fecha_actualizacion] [datetime] NULL,
	[temporal_null] [smallint] NULL,
	[esc_codigo] [int] NULL,
	[esc_nombre] [varchar](50) NULL,
 CONSTRAINT [PK_aud_matricula_curso] PRIMARY KEY CLUSTERED 
(
	[aud_codigo_mat_curso] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[aud_matricula_curso] ADD  CONSTRAINT [DF_aud_matricula_curso_aud_user]  DEFAULT (suser_sname()) FOR [aud_user]
GO

ALTER TABLE [dbo].[aud_matricula_curso] ADD  CONSTRAINT [DF_aud_matricula_curso_aud_changed]  DEFAULT (getdate()) FOR [aud_changed]
GO


