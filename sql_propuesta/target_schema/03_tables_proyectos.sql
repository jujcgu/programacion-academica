-- ============================================================================
-- ARTEFACTO: 03_tables_proyectos.sql
-- DESCRIPCIÓN: Definición de tablas del subsistema de investigación y proyección social (Corrección de typos y Clustered PKs)
-- PROYECTO: Sistema de Programación Académica (p_academica-main)
-- MOTOR OBJETIVO: Microsoft SQL Server 2016+ / Azure SQL Database / T-SQL ANSI
-- ============================================================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- ----------------------------------------------------------------------------
-- TABLA: [proyectos].[docentexproyecto_proyeccion_social]
-- ----------------------------------------------------------------------------
CREATE TABLE [proyectos].[docentexproyecto_proyeccion_social](
	[id_docentesxproyecto] [int] IDENTITY(1,1) NOT NULL,
	[uap_codigo] [int] NOT NULL,
	[pps_codigo] [int] NOT NULL,
	[prp_codigo] [int] NULL,
	[dpp_horas_descarga] [int] NULL,
	[dpp_horas_sindescarga] [int] NULL,
	[nco_codigo] [int] NULL,
	[dpp_descarga_aprobada] [int] NULL,
	[dpp_sindescarga_aprobada] [int] NULL,
	[dpp_periodo] [int] NULL,
	[dpp_numero_semanas] [int] NULL,
	[dpp_horas_semana] [int] NULL,
	[dpp_observacion] [varchar](5000) NULL,
	[migracion_persona] [int] NULL,
	[migracion_periodo] [int] NULL,
	[migracion_uap] [int] NULL,
	[migracion_horas_semana] [smallint] NULL,
	[migracion_semanas] [smallint] NULL,
	[migracion_observacion] [varchar](300) NULL,
	[dpp_estado] [bit] NULL,
	[derecho_mencion] [int] NULL,
 	[aud_fecha_creacion] [datetime2](7) NOT NULL CONSTRAINT [DF_docentexproyecto_proyeccion_social_aud_fecha_creacion] DEFAULT (sysdatetime()),
	[aud_usuario_creacion] [nvarchar](128) NOT NULL CONSTRAINT [DF_docentexproyecto_proyeccion_social_aud_usuario_creacion] DEFAULT (suser_sname()),
	[aud_fecha_modificacion] [datetime2](7) NULL,
	[aud_usuario_modificacion] [nvarchar](128) NULL,
 CONSTRAINT [PK_docentexproyecto_proyeccion_social_1] PRIMARY KEY CLUSTERED 
(
	[id_docentesxproyecto] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

IF NOT EXISTS (SELECT 1 FROM sys.default_constraints dc JOIN sys.tables t ON dc.parent_object_id = t.object_id JOIN sys.schemas s ON t.schema_id = s.schema_id JOIN sys.columns c ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id WHERE s.name = 'proyectos' AND t.name = 'docentexproyecto_proyeccion_social' AND c.name = 'derecho_mencion')
BEGIN
    ALTER TABLE [proyectos].[docentexproyecto_proyeccion_social] ADD CONSTRAINT [DF_docentexproyecto_proyeccion_social_derecho_mencion] DEFAULT (0) FOR [derecho_mencion];
END
GO

-- ----------------------------------------------------------------------------
-- TABLA: [proyectos].[proyecto_proyeccion_social]
-- ----------------------------------------------------------------------------
CREATE TABLE [proyectos].[proyecto_proyeccion_social](
	[pps_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[pps_titulo] [varchar](300) NULL,
	[pra_codigo] [int] NULL,
	[oap_codigo] [int] NULL,
	[pst_codigo] [int] NULL,
	[otp_codigo] [int] NULL,
	[pps_grupolac] [varchar](150) NULL,
	[nco_codigo] [int] NULL,
	[pps_fecha_inicio] [date] NULL,
	[pps_fecha_fin] [date] NULL,
	[mun_codigo] [int] NULL,
	[pps_palabras_claves] [varchar](200) NULL,
	[pps_objetivo_general] [varchar](max) NULL,
	[pps_resumen] [varchar](max) NULL,
	[pps_metodologia] [varchar](max) NULL,
	[prc_codigo] [int] NULL,
	[pre_codigo] [int] NULL,
	[pps_descripcion_producto] [varchar](200) NULL,
	[pps_beneficiarios] [varchar](200) NULL,
	[pps_impactoxuso_esperado] [varchar](200) NULL,
	[pps_supuestos_basicos] [varchar](200) NULL,
	[pps_plazo_materializacion] [varchar](10) NULL,
	[pps_probabilidad_ocurrencia] [varchar](10) NULL,
	[pps_acto_administrativo] [varchar](50) NULL,
	[pps_acto_administrativo_fecha] [datetime] NULL,
	[pps_acta_aprobacion] [varchar](500) NULL,
	[pps_justificacion_beneficio] [varchar](max) NULL,
	[pps_secretario_administrativo] [int] NULL,
	[pps_decano] [int] NULL,
	[pps_facultad] [int] NULL,
	[pps_coordinador] [int] NULL,
	[pps_solicitante_servicio] [varchar](200) NULL,
	[pps_obs_cumplimiento_actividades] [varchar](200) NULL,
	[pps_obs_consolidacion_resultados] [varchar](200) NULL,
		[uaa_pertenece] [int] NULL,
	[pps_fecha_registro] [datetime] NULL,
	[pps_pregunta] [varchar](max) NULL,
	[pps_marco_teorico] [varchar](max) NULL,
	[pps_grupo] [int] NULL,
	[pps_justificacion] [varchar](max) NULL,
	[pps_estado] [int] NULL,
	[pps_convocatoria] [int] NULL,
	[pps_tipoproyecto] [int] NULL,
	[pps_bibliografia] [varchar](max) NULL,
	[pps_responsable_admin] [int] NULL,
	[beneficiarios] [varchar](max) NULL,
	[localizacion] [varchar](max) NULL,
	[contenidos_academicos] [varchar](max) NULL,
	[pps_fecha_aprobacion_desaprobacion] [datetime] NULL,
	[pps_fecha_actualizacion] [datetime] NULL,
	[pps_aplicacion] [varchar](50) NULL,
	[pps_ip] [varchar](50) NULL,
	[pps_observacion_modificacion] [varchar](max) NULL,
	[pps_planteamiento_problema] [varchar](max) NULL,
	[pps_linea_estrategica] [int] NULL,
	[pps_localizacion_municipio] [int] NULL,
	[pps_area_trabajo] [int] NULL,
	[pps_linea_investigacion] [int] NULL,
	[are_codigo] [int] NULL,
	[stp_codigo] [int] NULL,
	[pps_semillero] [int] NULL,
 	[aud_fecha_creacion] [datetime2](7) NOT NULL CONSTRAINT [DF_proyecto_proyeccion_social_aud_fecha_creacion] DEFAULT (sysdatetime()),
	[aud_usuario_creacion] [nvarchar](128) NOT NULL CONSTRAINT [DF_proyecto_proyeccion_social_aud_usuario_creacion] DEFAULT (suser_sname()),
	[aud_fecha_modificacion] [datetime2](7) NULL,
	[aud_usuario_modificacion] [nvarchar](128) NULL,
 CONSTRAINT [PK_proyecto_proyeccion_social] PRIMARY KEY CLUSTERED 
(
	[pps_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_proyecto_proyeccion_social_pps_fecha_registro')
BEGIN
    ALTER TABLE [proyectos].[proyecto_proyeccion_social] ADD CONSTRAINT [DF_proyecto_proyeccion_social_pps_fecha_registro] DEFAULT getdate() FOR [pps_fecha_registro];
END
GO

-- ============================================================================
-- TABLAS MAESTRAS DEL ESQUEMA PROYECTOS (Catálogos de proyección social e investigación)
-- ============================================================================

IF NOT EXISTS (SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'proyectos' AND t.name = 'mc_proyecto_area')
BEGIN
    CREATE TABLE [proyectos].[mc_proyecto_area](
        [mca_codigo] [int] NOT NULL,
        [mca_nombre] [varchar](100) NOT NULL,
        CONSTRAINT [PK_mc_proyecto_area] PRIMARY KEY CLUSTERED ([mca_codigo] ASC)
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'proyectos' AND t.name = 'mc_proyecto_clase')
BEGIN
    CREATE TABLE [proyectos].[mc_proyecto_clase](
        [mcc_codigo] [int] NOT NULL,
        [mcc_nombre] [varchar](100) NOT NULL,
        CONSTRAINT [PK_mc_proyecto_clase] PRIMARY KEY CLUSTERED ([mcc_codigo] ASC)
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'proyectos' AND t.name = 'ps_nbc_colciencias')
BEGIN
    CREATE TABLE [proyectos].[ps_nbc_colciencias](
        [nbc_codigo] [int] NOT NULL,
        [nbc_nombre] [varchar](150) NOT NULL,
        CONSTRAINT [PK_ps_nbc_colciencias] PRIMARY KEY CLUSTERED ([nbc_codigo] ASC)
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'proyectos' AND t.name = 'ps_origen_area_proyecto')
BEGIN
    CREATE TABLE [proyectos].[ps_origen_area_proyecto](
        [oap_codigo] [int] NOT NULL,
        [oap_nombre] [varchar](100) NOT NULL,
        CONSTRAINT [PK_ps_origen_area_proyecto] PRIMARY KEY CLUSTERED ([oap_codigo] ASC)
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'proyectos' AND t.name = 'ps_origen_tipo_proyecto')
BEGIN
    CREATE TABLE [proyectos].[ps_origen_tipo_proyecto](
        [otp_codigo] [int] NOT NULL,
        [otp_nombre] [varchar](100) NOT NULL,
        CONSTRAINT [PK_ps_origen_tipo_proyecto] PRIMARY KEY CLUSTERED ([otp_codigo] ASC)
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'proyectos' AND t.name = 'ps_proyecto_tipo')
BEGIN
    CREATE TABLE [proyectos].[ps_proyecto_tipo](
        [ppt_codigo] [int] NOT NULL,
        [ppt_nombre] [varchar](100) NOT NULL,
        CONSTRAINT [PK_ps_proyecto_tipo] PRIMARY KEY CLUSTERED ([ppt_codigo] ASC)
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'proyectos' AND t.name = 'ps_semilleros')
BEGIN
    CREATE TABLE [proyectos].[ps_semilleros](
        [semi_codigo] [int] NOT NULL,
        [semi_nombre] [varchar](150) NOT NULL,
        CONSTRAINT [PK_ps_semilleros] PRIMARY KEY CLUSTERED ([semi_codigo] ASC)
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'proyectos' AND t.name = 'ps_area_extension')
BEGIN
    CREATE TABLE [proyectos].[ps_area_extension](
        [pae_codigo] [int] NOT NULL,
        [pae_nombre] [varchar](100) NOT NULL,
        CONSTRAINT [PK_ps_area_extension] PRIMARY KEY CLUSTERED ([pae_codigo] ASC)
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'proyectos' AND t.name = 'ps_sub_tipo_proyecto')
BEGIN
    CREATE TABLE [proyectos].[ps_sub_tipo_proyecto](
        [pst_codigo] [int] NOT NULL,
        [pst_nombre] [varchar](100) NOT NULL,
        CONSTRAINT [PK_ps_sub_tipo_proyecto] PRIMARY KEY CLUSTERED ([pst_codigo] ASC)
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'proyectos' AND t.name = 'proyeccion_rolxproyecto')
BEGIN
    CREATE TABLE [proyectos].[proyeccion_rolxproyecto](
        [rxp_codigo] [int] NOT NULL,
        [rxp_nombre] [varchar](100) NOT NULL,
        CONSTRAINT [PK_proyeccion_rolxproyecto] PRIMARY KEY CLUSTERED ([rxp_codigo] ASC)
    );
END
GO
