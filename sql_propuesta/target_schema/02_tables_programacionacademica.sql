-- ============================================================================
-- ARTEFACTO: 02_tables_programacionacademica.sql
-- DESCRIPCIÓN: Definición de tablas del núcleo de programación académica y solicitudes (Eliminación de HEAPS con Clustered PKs)
-- PROYECTO: Sistema de Programación Académica (p_academica-main)
-- MOTOR OBJETIVO: Microsoft SQL Server 2016+ / Azure SQL Database / T-SQL ANSI
-- ============================================================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- ----------------------------------------------------------------------------
-- TABLA: [programacionacademica].[grupo_uaa]
-- ----------------------------------------------------------------------------
CREATE TABLE [programacionacademica].[grupo_uaa](
	[pgr_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[pgr_nombre] [varchar](100) NOT NULL,
	[pgr_estado] [int] NOT NULL,
 	[aud_fecha_creacion] [datetime2](7) NOT NULL CONSTRAINT [DF_grupo_uaa_aud_fecha_creacion] DEFAULT (sysdatetime()),
	[aud_usuario_creacion] [nvarchar](128) NOT NULL CONSTRAINT [DF_grupo_uaa_aud_usuario_creacion] DEFAULT (suser_sname()),
	[aud_fecha_modificacion] [datetime2](7) NULL,
	[aud_usuario_modificacion] [nvarchar](128) NULL,
 CONSTRAINT [PK_pgr_codigo] PRIMARY KEY CLUSTERED 
(
	[pgr_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

-- ----------------------------------------------------------------------------
-- TABLA: [programacionacademica].[grupo_uaa_item]
-- ----------------------------------------------------------------------------
CREATE TABLE [programacionacademica].[grupo_uaa_item](
	[gui_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[pgr_codigo] [int] NOT NULL,
	[uaa_codigo] [int] NOT NULL,
	[gui_estado] [int] NOT NULL,
 	[aud_fecha_creacion] [datetime2](7) NOT NULL CONSTRAINT [DF_grupo_uaa_item_aud_fecha_creacion] DEFAULT (sysdatetime()),
	[aud_usuario_creacion] [nvarchar](128) NOT NULL CONSTRAINT [DF_grupo_uaa_item_aud_usuario_creacion] DEFAULT (suser_sname()),
	[aud_fecha_modificacion] [datetime2](7) NULL,
	[aud_usuario_modificacion] [nvarchar](128) NULL,
 CONSTRAINT [PK_gui_codigo] PRIMARY KEY CLUSTERED 
(
	[gui_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

-- ----------------------------------------------------------------------------
-- TABLA: [programacionacademica].[periodo_unidad]
-- ----------------------------------------------------------------------------
CREATE TABLE [programacionacademica].[periodo_unidad](
	[peu_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[uaa_codigo] [int] NOT NULL,
	[per_codigo] [int] NOT NULL,
	[peu_fecha_inicio] [date] NOT NULL,
	[peu_fecha_fin] [date] NOT NULL,
	[peu_estado] [tinyint] NOT NULL,
 	[aud_fecha_creacion] [datetime2](7) NOT NULL CONSTRAINT [DF_periodo_unidad_aud_fecha_creacion] DEFAULT (sysdatetime()),
	[aud_usuario_creacion] [nvarchar](128) NOT NULL CONSTRAINT [DF_periodo_unidad_aud_usuario_creacion] DEFAULT (suser_sname()),
	[aud_fecha_modificacion] [datetime2](7) NULL,
	[aud_usuario_modificacion] [nvarchar](128) NULL,
 CONSTRAINT [PK_peu_periodo_unidad] PRIMARY KEY CLUSTERED 
(
	[peu_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

-- ----------------------------------------------------------------------------
-- TABLA: [programacionacademica].[programacion_academica]
-- ----------------------------------------------------------------------------
CREATE TABLE [programacionacademica].[programacion_academica](
	[pra_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[uaa_codigo] [int] NOT NULL,
	[prp_codigo] [int] NOT NULL,
	[cal_codigo] [int] NOT NULL,
	[pra_fecha_inicio] [datetime] NOT NULL,
	[pra_fecha_fin] [datetime] NOT NULL,
	[pra_estado] [tinyint] NOT NULL,
 	[aud_fecha_creacion] [datetime2](7) NOT NULL CONSTRAINT [DF_programacion_academica_aud_fecha_creacion] DEFAULT (sysdatetime()),
	[aud_usuario_creacion] [nvarchar](128) NOT NULL CONSTRAINT [DF_programacion_academica_aud_usuario_creacion] DEFAULT (suser_sname()),
	[aud_fecha_modificacion] [datetime2](7) NULL,
	[aud_usuario_modificacion] [nvarchar](128) NULL,
 CONSTRAINT [PK_pra_programacion_academica] PRIMARY KEY CLUSTERED 
(
	[pra_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

-- ----------------------------------------------------------------------------
-- TABLA: [programacionacademica].[programacion_gestion]
-- ----------------------------------------------------------------------------
CREATE TABLE [programacionacademica].[programacion_gestion](
	[prg_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[uaa_codigo] [int] NOT NULL,
	[cal_codigo] [int] NOT NULL,
	[prg_fecha_inicio] [datetime] NOT NULL,
	[prg_fecha_fin] [datetime] NOT NULL,
	[prg_estado] [tinyint] NOT NULL,
	[pts_codigo] [int] NOT NULL,
 	[aud_fecha_creacion] [datetime2](7) NOT NULL CONSTRAINT [DF_programacion_gestion_aud_fecha_creacion] DEFAULT (sysdatetime()),
	[aud_usuario_creacion] [nvarchar](128) NOT NULL CONSTRAINT [DF_programacion_gestion_aud_usuario_creacion] DEFAULT (suser_sname()),
	[aud_fecha_modificacion] [datetime2](7) NULL,
	[aud_usuario_modificacion] [nvarchar](128) NULL,
 CONSTRAINT [PK_prg_programacion_gestion] PRIMARY KEY CLUSTERED 
(
	[prg_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

-- ----------------------------------------------------------------------------
-- TABLA: [programacionacademica].[programacion_tipo_solicitudes]
-- ----------------------------------------------------------------------------
CREATE TABLE [programacionacademica].[programacion_tipo_solicitudes](
	[pts_codigo] [int] IDENTITY(1,1) NOT NULL,
	[pts_nombre] [varchar](100) NOT NULL,
	[pts_estado] [tinyint] NOT NULL,
	[aud_fecha_creacion] [datetime2](7) NOT NULL CONSTRAINT [DF_programacion_tipo_solicitudes_aud_fecha_creacion] DEFAULT (sysdatetime()),
	[aud_usuario_creacion] [nvarchar](128) NOT NULL CONSTRAINT [DF_programacion_tipo_solicitudes_aud_usuario_creacion] DEFAULT (suser_sname()),
	[aud_fecha_modificacion] [datetime2](7) NULL,
	[aud_usuario_modificacion] [nvarchar](128) NULL,
 CONSTRAINT [PK_programacion_tipo_solicitudes] PRIMARY KEY CLUSTERED (
	[pts_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

-- ----------------------------------------------------------------------------
-- TABLA: [programacionacademica].[solicitud_cambio_horario]
-- ----------------------------------------------------------------------------
CREATE TABLE [programacionacademica].[solicitud_cambio_horario](
	[sch_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[cur_codigo] [int] NOT NULL,
	[usu_codigo] [int] NOT NULL,
	[uaa_codigo] [int] NOT NULL,
	[sch_cambio_docente] [int] NULL,
	[sch_cambio_semanas] [int] NULL,
	[sch_estado] [int] NOT NULL,
	[sch_fecha_creacion] [datetime] NOT NULL,
	[sch_espacio_deportivo] [int] NULL,
 	[aud_fecha_creacion] [datetime2](7) NOT NULL CONSTRAINT [DF_solicitud_cambio_horario_aud_fecha_creacion] DEFAULT (sysdatetime()),
	[aud_usuario_creacion] [nvarchar](128) NOT NULL CONSTRAINT [DF_solicitud_cambio_horario_aud_usuario_creacion] DEFAULT (suser_sname()),
	[aud_fecha_modificacion] [datetime2](7) NULL,
	[aud_usuario_modificacion] [nvarchar](128) NULL,
 CONSTRAINT [PK_sch_solicitud_cambio_horario] PRIMARY KEY CLUSTERED 
(
	[sch_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

-- ----------------------------------------------------------------------------
-- TABLA: [programacionacademica].[solicitud_cambio_horario_comentario]
-- ----------------------------------------------------------------------------
CREATE TABLE [programacionacademica].[solicitud_cambio_horario_comentario](
	[schc_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[sch_codigo] [int] NOT NULL,
	[schc_fecha_creacion] [datetime] NOT NULL,
	[schc_comentario] [varchar](max) NOT NULL,
	[usu_codigo] [int] NOT NULL,
 	[aud_fecha_creacion] [datetime2](7) NOT NULL CONSTRAINT [DF_solicitud_cambio_horario_comentario_aud_fecha_creacion] DEFAULT (sysdatetime()),
	[aud_usuario_creacion] [nvarchar](128) NOT NULL CONSTRAINT [DF_solicitud_cambio_horario_comentario_aud_usuario_creacion] DEFAULT (suser_sname()),
	[aud_fecha_modificacion] [datetime2](7) NULL,
	[aud_usuario_modificacion] [nvarchar](128) NULL,
 CONSTRAINT [PK_schc_solicitud_cambio_horario_comentario] PRIMARY KEY CLUSTERED 
(
	[schc_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];
GO

-- ----------------------------------------------------------------------------
-- TABLA: [programacionacademica].[solicitud_cambio_horario_horario]
-- ----------------------------------------------------------------------------
CREATE TABLE [programacionacademica].[solicitud_cambio_horario_horario](
	[schh_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[sch_codigo] [int] NOT NULL,
	[schh_estado] [int] NOT NULL,
	[schh_subgrupo] [char](2) NOT NULL,
	[schh_dia_codigo_anterior] [int] NOT NULL,
	[schh_hra_codigo_anterior] [int] NOT NULL,
	[schh_esp_codigo_anterior] [int] NOT NULL,
	[schh_uap_codigo_anterior] [int] NOT NULL,
	[schh_dia_codigo_nuevo] [int] NOT NULL,
	[schh_hra_codigo_nuevo] [int] NOT NULL,
	[schh_esp_codigo_nuevo] [int] NULL,
	[schh_uap_codigo_nuevo] [int] NULL,
	[schh_fecha_inicio] [date] NULL,
	[schh_fecha_fin] [date] NULL,
 	[aud_fecha_creacion] [datetime2](7) NOT NULL CONSTRAINT [DF_solicitud_cambio_horario_horario_aud_fecha_creacion] DEFAULT (sysdatetime()),
	[aud_usuario_creacion] [nvarchar](128) NOT NULL CONSTRAINT [DF_solicitud_cambio_horario_horario_aud_usuario_creacion] DEFAULT (suser_sname()),
	[aud_fecha_modificacion] [datetime2](7) NULL,
	[aud_usuario_modificacion] [nvarchar](128) NULL,
 CONSTRAINT [PK_schh_solicitud_cambio_horario_horario] PRIMARY KEY CLUSTERED 
(
	[schh_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

-- ----------------------------------------------------------------------------
-- TABLA: [programacionacademica].[solicitud_prestamo_docente]
-- ----------------------------------------------------------------------------
CREATE TABLE [programacionacademica].[solicitud_prestamo_docente](
	[spd_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[periodo_codigo] [int] NOT NULL,
	[persona_codigo] [int] NULL,
	[asi_codigo] [int] NOT NULL,
	[spd_estado] [tinyint] NOT NULL,
	[uaa_solicita] [int] NOT NULL,
	[uaa_dirigida] [int] NOT NULL,
	[sed_codigo] [int] NOT NULL,
 	[aud_fecha_creacion] [datetime2](7) NOT NULL CONSTRAINT [DF_solicitud_prestamo_docente_aud_fecha_creacion] DEFAULT (sysdatetime()),
	[aud_usuario_creacion] [nvarchar](128) NOT NULL CONSTRAINT [DF_solicitud_prestamo_docente_aud_usuario_creacion] DEFAULT (suser_sname()),
	[aud_fecha_modificacion] [datetime2](7) NULL,
	[aud_usuario_modificacion] [nvarchar](128) NULL,
 CONSTRAINT [PK_spd_solicitud_prestamo_docente] PRIMARY KEY CLUSTERED 
(
	[spd_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

-- ----------------------------------------------------------------------------
-- TABLA: [programacionacademica].[solicitud_prestamo_docente_comentario]
-- ----------------------------------------------------------------------------
CREATE TABLE [programacionacademica].[solicitud_prestamo_docente_comentario](
	[spdc_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[spd_codigo] [int] NOT NULL,
	[spdc_estado] [tinyint] NOT NULL,
	[usu_codigo] [int] NOT NULL,
	[spdc_fecha_creacion] [datetime] NOT NULL,
	[spdc_mensaje] [varchar](max) NULL,
 	[aud_fecha_creacion] [datetime2](7) NOT NULL CONSTRAINT [DF_solicitud_prestamo_docente_comentario_aud_fecha_creacion] DEFAULT (sysdatetime()),
	[aud_usuario_creacion] [nvarchar](128) NOT NULL CONSTRAINT [DF_solicitud_prestamo_docente_comentario_aud_usuario_creacion] DEFAULT (suser_sname()),
	[aud_fecha_modificacion] [datetime2](7) NULL,
	[aud_usuario_modificacion] [nvarchar](128) NULL,
 CONSTRAINT [PK_spd_solicitud_prestamo_docente_comentario] PRIMARY KEY CLUSTERED 
(
	[spdc_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];
GO

-- ----------------------------------------------------------------------------
-- TABLA: [programacionacademica].[solicitud_prestamo_docente_horario]
-- ----------------------------------------------------------------------------
CREATE TABLE [programacionacademica].[solicitud_prestamo_docente_horario](
	[spdh_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[spd_codigo] [int] NOT NULL,
	[dia_codigo] [int] NOT NULL,
	[hra_codigo] [int] NOT NULL,
	[spdh_estado] [tinyint] NOT NULL,
 	[aud_fecha_creacion] [datetime2](7) NOT NULL CONSTRAINT [DF_solicitud_prestamo_docente_horario_aud_fecha_creacion] DEFAULT (sysdatetime()),
	[aud_usuario_creacion] [nvarchar](128) NOT NULL CONSTRAINT [DF_solicitud_prestamo_docente_horario_aud_usuario_creacion] DEFAULT (suser_sname()),
	[aud_fecha_modificacion] [datetime2](7) NULL,
	[aud_usuario_modificacion] [nvarchar](128) NULL,
 CONSTRAINT [PK_spd_solicitud_prestamo_docente_horario] PRIMARY KEY CLUSTERED 
(
	[spdh_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO
