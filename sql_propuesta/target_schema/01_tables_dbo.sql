-- ============================================================================
-- ARTEFACTO: 01_tables_dbo.sql
-- DESCRIPCIÓN: Definición de tablas base normalizadas del esquema dbo (Clustered PKs, auditoría y resolución de tipos)
-- PROYECTO: Sistema de Programación Académica (p_academica-main)
-- MOTOR OBJETIVO: Microsoft SQL Server 2016+ / Azure SQL Database / T-SQL ANSI
-- ============================================================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[agenda_periodo]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[agenda_periodo](
	[idagenda] [numeric](18, 0) IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[creditos] [int] NULL,
	[caracter] [nchar](2) NULL,
	[hora_teorica] [int] NULL,
	[hora_practica] [int] NULL,
	[tradicional_o_credito] [nchar](2) NULL,
	[numero_total_hora] [int] NULL,
	[factor] [int] NULL,
	[semanas] [int] NULL,
	[vinculacion] [int] NULL,
	[uap_codigo] [int] NULL,
	[cur_codigo] [int] NULL,
	[sub_grupo] [nchar](2) NULL,
	[total_horas] [int] NULL,
	[per_codigo] [int] NULL,
	[uaa_codigo] [int] NULL,
	[factor_formula] [nchar](20) NULL,
 CONSTRAINT [PK_agenda_periodo] PRIMARY KEY CLUSTERED 
(
	[idagenda] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[agenda_periodo_novedad]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[agenda_periodo_novedad](
	[apn_id] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[novedad] [text] NULL,
	[fecha] [date] NULL,
	[ag_id] [int] NULL,
	[periodo] [int] NULL,
	[per_codigo] [int] NULL,
 CONSTRAINT [PK_agenda_periodo_novedad] PRIMARY KEY CLUSTERED 
(
	[apn_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[asignatura]
-- ----------------------------------------------------------------------------
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
) ON [PRIMARY];
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_asignatura_asi_fecha_actualizacion')
BEGIN
    ALTER TABLE [dbo].[asignatura] ADD CONSTRAINT [DF_asignatura_asi_fecha_actualizacion] DEFAULT getdate() FOR [asi_fecha_actualizacion];
END
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF__asignatur__for_c__2D75C97F')
BEGIN
    ALTER TABLE [dbo].[asignatura] ADD CONSTRAINT [DF__asignatur__for_c__2D75C97F] DEFAULT (1) FOR [for_codigo];
END
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[aud_curso]
-- ----------------------------------------------------------------------------
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
) ON [PRIMARY];
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_aud_curso_aud_user')
BEGIN
    ALTER TABLE [dbo].[aud_curso] ADD CONSTRAINT [DF_aud_curso_aud_user] DEFAULT suser_sname() FOR [aud_user];
END
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_aud_curso_aud_changed')
BEGIN
    ALTER TABLE [dbo].[aud_curso] ADD CONSTRAINT [DF_aud_curso_aud_changed] DEFAULT getdate() FOR [aud_changed];
END
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_aud_curso_aud_host')
BEGIN
    ALTER TABLE [dbo].[aud_curso] ADD CONSTRAINT [DF_aud_curso_aud_host] DEFAULT host_name() FOR [aud_host];
END
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[aud_curso_cupo_subgrupo]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[aud_curso_cupo_subgrupo](
	[aud_cus_cod] [int] IDENTITY(1,1) NOT NULL,
	[aud_log_type] [char](6) NOT NULL,
	[cus_cod] [int] NOT NULL,
	[cur_codigo] [int] NULL,
	[eso_subgrupo] [varchar](2) NULL,
	[cus_cupo] [int] NULL,
	[cus_estado] [int] NULL,
	[cus_fecha_registro] [datetime] NULL,
	[aud_user] [nvarchar](128) NOT NULL,
	[aud_changed] [datetime] NOT NULL,
	[aud_host] [varchar](200) NOT NULL,
	[aud_ip] [varchar](50) NOT NULL,
 CONSTRAINT [PK_aud_curso_cupo_subgrupo] PRIMARY KEY CLUSTERED 
(
	[aud_cus_cod] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_aud_curso_cupo_subgrupo_aud_user')
BEGIN
    ALTER TABLE [dbo].[aud_curso_cupo_subgrupo] ADD CONSTRAINT [DF_aud_curso_cupo_subgrupo_aud_user] DEFAULT suser_sname() FOR [aud_user];
END
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_aud_curso_cupo_subgrupo_aud_changed')
BEGIN
    ALTER TABLE [dbo].[aud_curso_cupo_subgrupo] ADD CONSTRAINT [DF_aud_curso_cupo_subgrupo_aud_changed] DEFAULT getdate() FOR [aud_changed];
END
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_aud_curso_cupo_subgrupo_aud_host')
BEGIN
    ALTER TABLE [dbo].[aud_curso_cupo_subgrupo] ADD CONSTRAINT [DF_aud_curso_cupo_subgrupo_aud_host] DEFAULT host_name() FOR [aud_host];
END
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_aud_curso_cupo_subgrupo_aud_ip')
BEGIN
    ALTER TABLE [dbo].[aud_curso_cupo_subgrupo] ADD CONSTRAINT [DF_aud_curso_cupo_subgrupo_aud_ip] DEFAULT CONVERT([varchar],connectionproperty('client_net_address'),(0)) FOR [aud_ip];
END
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[aud_espacio_ocupacion]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[aud_espacio_ocupacion](
	[aud_codigo_eso] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[aud_log_type] [char](5) NULL,
	[eso_codigo] [int] NOT NULL,
	[esp_codigo] [int] NOT NULL,
	[uaa_codigo] [int] NOT NULL,
	[eso_fecha] [datetime] NOT NULL,
	[hor_codigo] [int] NULL,
	[dia_codigo] [int] NULL,
	[hra_codigo] [int] NULL,
	[eso_actividad] [int] NULL,
	[eso_subgrupo] [char](2) NULL,
	[uap_codigo] [int] NULL,
	[eso_estado] [char](1) NULL,
	[oct_codigo] [int] NULL,
	[eso_descripcion] [varchar](200) NULL,
	[cdp_codigo] [int] NULL,
	[ctr_codigo] [int] NULL,
	[aud_user] [sysname] NOT NULL,
	[aud_changed] [datetime] NULL,
	[usu_codigo] [int] NULL,
	[tabla] [varchar](50) NULL,
	[aud_host] [varchar](200) NULL,
	[sys_user] [varchar](150) NULL,
	[aud_ip] [varchar](500) NULL,
 CONSTRAINT [PK_aud_espacio_ocupacion] PRIMARY KEY CLUSTERED 
(
	[aud_codigo_eso] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_aud_espacio_ocupacion_aud_user')
BEGIN
    ALTER TABLE [dbo].[aud_espacio_ocupacion] ADD CONSTRAINT [DF_aud_espacio_ocupacion_aud_user] DEFAULT suser_sname() FOR [aud_user];
END
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_aud_espacio_ocupacion_aud_changed')
BEGIN
    ALTER TABLE [dbo].[aud_espacio_ocupacion] ADD CONSTRAINT [DF_aud_espacio_ocupacion_aud_changed] DEFAULT getdate() FOR [aud_changed];
END
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_aud_espacio_ocupacion_aud_host')
BEGIN
    ALTER TABLE [dbo].[aud_espacio_ocupacion] ADD CONSTRAINT [DF_aud_espacio_ocupacion_aud_host] DEFAULT host_name() FOR [aud_host];
END
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_aud_espacio_ocupacion_sys_user')
BEGIN
    ALTER TABLE [dbo].[aud_espacio_ocupacion] ADD CONSTRAINT [DF_aud_espacio_ocupacion_sys_user] DEFAULT ((('system_user:('+suser_sname())+'), user:(')+user_name())+')' FOR [sys_user];
END
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_aud_espacio_ocupacion_aud_ip')
BEGIN
    ALTER TABLE [dbo].[aud_espacio_ocupacion] ADD CONSTRAINT [DF_aud_espacio_ocupacion_aud_ip] DEFAULT CONVERT([varchar],connectionproperty('client_net_address'),(0)) FOR [aud_ip];
END
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[aud_matricula_curso]
-- ----------------------------------------------------------------------------
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
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_aud_matricula_curso_aud_user')
BEGIN
    ALTER TABLE [dbo].[aud_matricula_curso] ADD CONSTRAINT [DF_aud_matricula_curso_aud_user] DEFAULT suser_sname() FOR [aud_user];
END
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_aud_matricula_curso_aud_changed')
BEGIN
    ALTER TABLE [dbo].[aud_matricula_curso] ADD CONSTRAINT [DF_aud_matricula_curso_aud_changed] DEFAULT getdate() FOR [aud_changed];
END
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[aud_uaa_personal]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[aud_uaa_personal](
	[aud_codigo_uap] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[aud_tipo] [char](6) NULL,
	[uap_codigo] [int] NULL,
	[uaa_codigo] [int] NULL,
	[per_codigo] [int] NULL,
	[uap_fecha_inicio] [datetime] NULL,
	[uap_fecha_fin] [datetime] NULL,
	[uap_cargo] [int] NULL,
	[vin_codigo] [int] NULL,
	[ded_codigo] [int] NULL,
	[uap_resolucion] [varchar](100) NULL,
	[uap_estado] [smallint] NULL,
	[esv_codigo] [int] NULL,
	[esc_valor] [money] NULL,
	[uap_codigo_anterior] [int] NULL,
	[uac_codigo] [int] NULL,
	[uap_plantaencargo] [char](1) NULL,
	[uap_uacocupado] [int] NULL,
	[uap_dependencia_ejerce] [int] NULL,
	[codRegistro] [bigint] NULL,
	[uap_id_carnet] [varchar](45) NULL,
	[sed_codigo] [int] NULL,
	[uap_observacion] [varchar](max) NULL,
	[sys_user] [varchar](200) NULL,
	[aud_fecha] [datetime] NULL,
	[aud_host] [varchar](200) NULL,
	[uap_auto_tratamiento_datos] [int] NULL,
	[uap_fecha_auto_tratamiento_datos] [datetime] NULL,
 CONSTRAINT [PK_aud_uaa_personal] PRIMARY KEY CLUSTERED 
(
	[aud_codigo_uap] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_aud_uaa_personal_sys_user')
BEGIN
    ALTER TABLE [dbo].[aud_uaa_personal] ADD CONSTRAINT [DF_aud_uaa_personal_sys_user] DEFAULT ((('system_user:('+suser_sname())+'), user:(')+user_name())+')' FOR [sys_user];
END
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_aud_uaa_personal_aud_fecha')
BEGIN
    ALTER TABLE [dbo].[aud_uaa_personal] ADD CONSTRAINT [DF_aud_uaa_personal_aud_fecha] DEFAULT getdate() FOR [aud_fecha];
END
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_aud_uaa_personal_aud_host')
BEGIN
    ALTER TABLE [dbo].[aud_uaa_personal] ADD CONSTRAINT [DF_aud_uaa_personal_aud_host] DEFAULT host_name() FOR [aud_host];
END
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[bloque]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[bloque](
	[blo_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[blo_nombre] [varchar](50) NOT NULL,
	[sus_codigo] [int] NOT NULL,
	[sippa_blocodigo] [char](4) NULL,
	[blo_latitud] [varchar](50) NULL,
	[blo_longitud] [varchar](50) NULL,
	[blo_estado] [int] NULL,
 CONSTRAINT [PK_bloque] PRIMARY KEY CLUSTERED 
(
	[blo_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_bloque_blo_estado')
BEGIN
    ALTER TABLE [dbo].[bloque] ADD CONSTRAINT [DF_bloque_blo_estado] DEFAULT (1) FOR [blo_estado];
END
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[calendario]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[calendario](
	[cal_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[per_codigo] [int] NOT NULL,
	[cal_nombre] [varchar](30) NULL,
	[cal_fecha] [datetime] NULL,
	[cal_documento] [varchar](10) NULL,
	[sippa_cal_codigo] [char](6) NULL,
	[cal_ano_salario_minimo] [int] NULL,
	[cal_estado] [varchar](1) NULL,
 CONSTRAINT [PK_calendario] PRIMARY KEY CLUSTERED 
(
	[cal_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

IF NOT EXISTS (SELECT 1 FROM sys.default_constraints dc JOIN sys.tables t ON dc.parent_object_id = t.object_id JOIN sys.schemas s ON t.schema_id = s.schema_id JOIN sys.columns c ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id WHERE s.name = 'dbo' AND t.name = 'calendario' AND c.name = 'cal_estado')
BEGIN
    ALTER TABLE [dbo].[calendario] ADD CONSTRAINT [DF_calendario_cal_estado] DEFAULT (1) FOR [cal_estado];
END
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[caracter]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[caracter](
	[car_codigo] [char](2) NOT NULL,
	[car_nombre] [varchar](25) NULL,
	[car_estado] [tinyint] NOT NULL,
 CONSTRAINT [PK_caracter] PRIMARY KEY CLUSTERED 
(
	[car_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

IF NOT EXISTS (SELECT 1 FROM sys.default_constraints dc JOIN sys.tables t ON dc.parent_object_id = t.object_id JOIN sys.schemas s ON t.schema_id = s.schema_id JOIN sys.columns c ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id WHERE s.name = 'dbo' AND t.name = 'caracter' AND c.name = 'car_estado')
BEGIN
    ALTER TABLE [dbo].[caracter] ADD CONSTRAINT [DF_caracter_car_estado] DEFAULT (1) FOR [car_estado];
END
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[cargo]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[cargo](
	[car_codigo] [int] IDENTITY(0,1) NOT FOR REPLICATION NOT NULL,
	[car_nombre] [varchar](50) NOT NULL,
	[car_id] [varchar](4) NULL,
	[car_tmp] [int] NULL,
	[car_jefe] [int] NULL,
	[car_estado] [int] NULL,
 CONSTRAINT [PK_cargo] PRIMARY KEY CLUSTERED 
(
	[car_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[cupo_autorizacion]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[cupo_autorizacion](
	[cua_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[cua_curso] [int] NOT NULL,
	[cua_grupo] [varchar](2) NOT NULL,
	[cua_subgrupo] [varchar](2) NOT NULL,
	[cua_estudiante] [char](11) NOT NULL,
	[cua_observacion] [varchar](max) NULL,
	[cua_fecha] [datetime] NULL,
 	[aud_fecha_creacion] [datetime2](7) NOT NULL CONSTRAINT [DF_cupo_autorizacion_aud_fecha_creacion] DEFAULT (sysdatetime()),
	[aud_usuario_creacion] [nvarchar](128) NOT NULL CONSTRAINT [DF_cupo_autorizacion_aud_usuario_creacion] DEFAULT (suser_sname()),
	[aud_fecha_modificacion] [datetime2](7) NULL,
	[aud_usuario_modificacion] [nvarchar](128) NULL,
 CONSTRAINT [PK_cupo_autorizacion] PRIMARY KEY CLUSTERED 
(
	[cua_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_cupo_autorizacion_cua_fecha')
BEGIN
    ALTER TABLE [dbo].[cupo_autorizacion] ADD CONSTRAINT [DF_cupo_autorizacion_cua_fecha] DEFAULT getdate() FOR [cua_fecha];
END
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[curso]
-- ----------------------------------------------------------------------------
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
 	[aud_fecha_creacion] [datetime2](7) NOT NULL CONSTRAINT [DF_curso_aud_fecha_creacion] DEFAULT (sysdatetime()),
	[aud_usuario_creacion] [nvarchar](128) NOT NULL CONSTRAINT [DF_curso_aud_usuario_creacion] DEFAULT (suser_sname()),
	[aud_fecha_modificacion] [datetime2](7) NULL,
	[aud_usuario_modificacion] [nvarchar](128) NULL,
 CONSTRAINT [PK_curso_1] PRIMARY KEY CLUSTERED 
(
	[cur_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_curso_tic_codigo')
BEGIN
    ALTER TABLE [dbo].[curso] ADD CONSTRAINT [DF_curso_tic_codigo] DEFAULT (1) FOR [tic_codigo];
END
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_curso_cut_codigo')
BEGIN
    ALTER TABLE [dbo].[curso] ADD CONSTRAINT [DF_curso_cut_codigo] DEFAULT (1) FOR [cut_codigo];
END
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_curso_cur_exclusivo_1')
BEGIN
    ALTER TABLE [dbo].[curso] ADD CONSTRAINT [DF_curso_cur_exclusivo_1] DEFAULT (1) FOR [cur_exclusivo];
END
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_curso_cur_cierre')
BEGIN
    ALTER TABLE [dbo].[curso] ADD CONSTRAINT [DF_curso_cur_cierre] DEFAULT (1) FOR [cur_cierre];
END
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_curso_cur_grabado')
BEGIN
    ALTER TABLE [dbo].[curso] ADD CONSTRAINT [DF_curso_cur_grabado] DEFAULT (0) FOR [cur_grabado];
END
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_curso_cur_ampliacion_cupo')
BEGIN
    ALTER TABLE [dbo].[curso] ADD CONSTRAINT [DF_curso_cur_ampliacion_cupo] DEFAULT (0) FOR [cur_ampliacion_cupo];
END
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_curso_cur_fecha_actualizacion')
BEGIN
    ALTER TABLE [dbo].[curso] ADD CONSTRAINT [DF_curso_cur_fecha_actualizacion] DEFAULT getdate() FOR [cur_fecha_actualizacion];
END
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_curso_tes_codigo')
BEGIN
    ALTER TABLE [dbo].[curso] ADD CONSTRAINT [DF_curso_tes_codigo] DEFAULT (1) FOR [tes_codigo];
END
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[curso_cupo_subgrupo]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[curso_cupo_subgrupo](
	[cus_cod] [int] IDENTITY(1,1) NOT NULL,
	[cur_codigo] [int] NULL,
	[eso_subgrupo] [varchar](2) NULL,
	[cus_cupo] [int] NULL,
	[cus_estado] [int] NULL,
	[cus_fecha_registro] [datetime] NULL,
 	[aud_fecha_creacion] [datetime2](7) NOT NULL CONSTRAINT [DF_curso_cupo_subgrupo_aud_fecha_creacion] DEFAULT (sysdatetime()),
	[aud_usuario_creacion] [nvarchar](128) NOT NULL CONSTRAINT [DF_curso_cupo_subgrupo_aud_usuario_creacion] DEFAULT (suser_sname()),
	[aud_fecha_modificacion] [datetime2](7) NULL,
	[aud_usuario_modificacion] [nvarchar](128) NULL,
 CONSTRAINT [PK_curso_cupo_subgrupo] PRIMARY KEY CLUSTERED 
(
	[cus_cod] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_curso_cupo_subgrupo_cus_estado')
BEGIN
    ALTER TABLE [dbo].[curso_cupo_subgrupo] ADD CONSTRAINT [DF_curso_cupo_subgrupo_cus_estado] DEFAULT (1) FOR [cus_estado];
END
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_curso_cupo_subgrupo_cus_fecha_registro')
BEGIN
    ALTER TABLE [dbo].[curso_cupo_subgrupo] ADD CONSTRAINT [DF_curso_cupo_subgrupo_cus_fecha_registro] DEFAULT getdate() FOR [cus_fecha_registro];
END
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[curso_institucion_ejecucion]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[curso_institucion_ejecucion](
	[cie_codigo] [int] IDENTITY(1,1) NOT NULL,
	[cur_codigo] [int] NULL,
	[cie_subgrupo] [char](2) NULL,
	[esp_codigo] [int] NULL,
	[mun_codigo] [int] NULL,
	[cie_estado] [int] NULL,
	[cie_uid_inserta] [int] NULL,
	[cie_fecha_inserta] [datetime] NULL,
	[cie_uid_modifica] [int] NULL,
	[cie_fecha_modifica] [datetime] NULL,
	[aud_fecha_creacion] [datetime2](7) NOT NULL CONSTRAINT [DF_curso_institucion_ejecucion_aud_fecha_creacion] DEFAULT (sysdatetime()),
	[aud_usuario_creacion] [nvarchar](128) NOT NULL CONSTRAINT [DF_curso_institucion_ejecucion_aud_usuario_creacion] DEFAULT (suser_sname()),
	[aud_fecha_modificacion] [datetime2](7) NULL,
	[aud_usuario_modificacion] [nvarchar](128) NULL,
 CONSTRAINT [PK_curso_institucion_ejecucion] PRIMARY KEY CLUSTERED (
	[cie_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[curso_plan]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[curso_plan](
	[cup_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[cur_codigo] [int] NULL,
	[pla_codigo] [int] NULL,
	[sippa_plancodigo] [char](7) NULL,
 	[aud_fecha_creacion] [datetime2](7) NOT NULL CONSTRAINT [DF_curso_plan_aud_fecha_creacion] DEFAULT (sysdatetime()),
	[aud_usuario_creacion] [nvarchar](128) NOT NULL CONSTRAINT [DF_curso_plan_aud_usuario_creacion] DEFAULT (suser_sname()),
	[aud_fecha_modificacion] [datetime2](7) NULL,
	[aud_usuario_modificacion] [nvarchar](128) NULL,
 CONSTRAINT [PK_curso_plan_1] PRIMARY KEY CLUSTERED 
(
	[cup_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[curso_tipo]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[curso_tipo](
	[cut_codigo] [tinyint] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[cut_nombre] [char](20) NULL,
	[cut_estado] [int] NULL,
 CONSTRAINT [PK_curso_tipo] PRIMARY KEY CLUSTERED 
(
	[cut_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[dedicacion]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[dedicacion](
	[ded_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[ded_nombre] [varchar](50) NOT NULL,
	[ded_orden_snies] [smallint] NULL,
	[sippa_dedcodigo] [char](1) NULL,
	[ded_codigo_hecaa] [smallint] NULL,
 CONSTRAINT [PK_dedicacion] PRIMARY KEY CLUSTERED 
(
	[ded_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[departamento]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[departamento](
	[dep_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[dep_acronimo] [char](2) NULL,
	[dep_nombre] [varchar](100) NOT NULL,
	[pai_codigo] [int] NOT NULL,
	[sippa_dep_codigo] [int] NULL,
	[dane_codigo] [char](10) NULL,
 CONSTRAINT [PK_departamento_1] PRIMARY KEY CLUSTERED 
(
	[dep_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[dia]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[dia](
	[dia_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[dia_nombre] [varchar](50) NULL,
	[dia_posicion_semana] [smallint] NULL,
	[dia_estado] [int] NOT NULL,
 CONSTRAINT [PK_dia] PRIMARY KEY CLUSTERED 
(
	[dia_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_dia_dia_estado')
BEGIN
    ALTER TABLE [dbo].[dia] ADD CONSTRAINT [DF_dia_dia_estado] DEFAULT (1) FOR [dia_estado];
END
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[docente_escalafon]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[docente_escalafon](
	[doe_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[per_codigo] [int] NULL,
	[doe_fecha_inicio] [datetime] NULL,
	[doe_fecha_fin] [datetime] NULL,
	[esc_codigo] [int] NOT NULL,
	[doe_documento] [nvarchar](100) NULL,
	[sippa_doccedula] [char](11) NULL,
	[sippa_esccodigo] [char](2) NULL,
	[sippa_escfecini] [datetime] NULL,
	[doe_puntos] [float] NULL,
	[doe_puntos_fecha] [datetime] NULL,
 	[aud_fecha_creacion] [datetime2](7) NOT NULL CONSTRAINT [DF_docente_escalafon_aud_fecha_creacion] DEFAULT (sysdatetime()),
	[aud_usuario_creacion] [nvarchar](128) NOT NULL CONSTRAINT [DF_docente_escalafon_aud_usuario_creacion] DEFAULT (suser_sname()),
	[aud_fecha_modificacion] [datetime2](7) NULL,
	[aud_usuario_modificacion] [nvarchar](128) NULL,
 CONSTRAINT [PK_docente_escalafon] PRIMARY KEY CLUSTERED 
(
	[doe_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[equivalencia]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[equivalencia](
	[equ_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[pla_codigo] [int] NULL,
	[asi_codigo] [int] NULL,
	[asi_equivalencia] [int] NULL,
 CONSTRAINT [PK_equivalencia] PRIMARY KEY CLUSTERED 
(
	[equ_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[escalafon]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[escalafon](
	[esc_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[esc_nombre] [varchar](50) NOT NULL,
	[esc_cap_puntos] [int] NULL,
	[sippa_esccodigo] [char](2) NULL,
 CONSTRAINT [PK_escalafon] PRIMARY KEY CLUSTERED 
(
	[esc_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[espacio]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[espacio](
	[esp_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[esp_nombre] [varchar](55) NOT NULL,
	[esp_nombre_corto] [varchar](50) NULL,
	[blo_codigo] [int] NULL,
	[esp_capacidad] [int] NOT NULL,
	[esp_area] [float] NULL,
	[eti_codigo] [int] NULL,
	[esp_compartido] [char](1) NOT NULL,
	[esp_descripcion] [varchar](255) NOT NULL,
	[uaa_codigo_responsable] [int] NULL,
	[esp_luminosidad] [char](1) NULL,
	[esp_espacio_codigo] [char](3) NULL,
	[esp_capacidad_covid] [int] NULL,
	[esp_habilitado_covid] [int] NULL,
	[sippa_salcodigo] [char](8) NULL,
	[esp_estado] [int] NULL,
	[esp_puntos_elect] [int] NULL,
	[esp_puntos_red] [int] NULL,
	[esp_puntos_tel] [int] NULL,
	[esp_metros_pared] [float] NULL,
	[esp_metros_suelo] [float] NULL,
	[mun_codigo] [int] NULL,
 CONSTRAINT [PK_espacios] PRIMARY KEY CLUSTERED 
(
	[esp_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[espacio_ocupacion]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[espacio_ocupacion](
	[eso_codigo] [int] IDENTITY(1,1) NOT NULL,
	[esp_codigo] [int] NOT NULL,
	[uaa_codigo] [int] NOT NULL,
	[eso_fecha] [datetime] NOT NULL,
	[hor_codigo] [int] NULL,
	[dia_codigo] [int] NULL,
	[hra_codigo] [int] NULL,
	[eso_actividad] [int] NULL,
	[eso_subgrupo] [char](2) NULL,
	[uap_codigo] [int] NULL,
	[eso_estado] [char](1) NULL,
	[oct_codigo] [int] NULL,
	[eso_descripcion] [varchar](200) NULL,
	[cdp_codigo] [int] NULL,
	[ctr_codigo] [int] NULL,
	[usu_codigo] [int] NULL,
		[sippa_sedcodigo] [char](2) NULL,
	[sippa_calcodigo] [char](6) NULL,
	[sippa_progcodigo] [char](4) NULL,
	[sippa_plancodigo] [char](7) NULL,
	[sippa_asicodigo] [char](8) NULL,
	[sippa_grucodigo] [char](2) NULL,
	[sippa_subgrucodigo] [char](2) NULL,
	[sippa_horfecini] [datetime] NULL,
	[sippa_horfecfin] [datetime] NULL,
	[sippa_horcodigo] [char](5) NULL,
	[sippa_doccedula] [char](11) NULL,
	[sippa_salcodigo] [char](8) NULL,
	[sippa_horsemanas] [smallint] NULL,
	[sippa_horfactor] [float] NULL,
	[sippa_vincodigo] [char](3) NULL,
	[eso_url] [varchar](200) NULL,
 	[aud_fecha_creacion] [datetime2](7) NOT NULL CONSTRAINT [DF_espacio_ocupacion_aud_fecha_creacion] DEFAULT (sysdatetime()),
	[aud_usuario_creacion] [nvarchar](128) NOT NULL CONSTRAINT [DF_espacio_ocupacion_aud_usuario_creacion] DEFAULT (suser_sname()),
	[aud_fecha_modificacion] [datetime2](7) NULL,
	[aud_usuario_modificacion] [nvarchar](128) NULL,
 CONSTRAINT [PK_espacio_ocupacion] PRIMARY KEY CLUSTERED 
(
	[eso_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[espacio_tipo]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[espacio_tipo](
	[eti_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[eti_nombre] [varchar](50) NOT NULL,
	[sippa_tipcodigo] [char](2) NULL,
	[etm_codigo] [int] NULL,
 CONSTRAINT [PK_espacio_tipo] PRIMARY KEY CLUSTERED 
(
	[eti_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[estudiante]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[estudiante](
	[est_codigo] [char](11) NOT NULL,
	[per_codigo] [int] NULL,
	[est_fecha_ingreso] [datetime] NOT NULL,
	[pro_codigo] [int] NULL,
	[ese_codigo] [smallint] NOT NULL,
	[ins_codigo] [int] NOT NULL,
	[est_fecha_retiro] [datetime] NULL,
	[ese_codigo1] [tinyint] NULL,
	[ese_codigo2] [tinyint] NULL,
	[est_id_carnet] [varchar](45) NULL,
	[est_registro_egresado] [int] NULL,
	[ter_codigo] [int] NULL,
	[est_uid] [int] NULL,
	[est_user] [char](50) NULL,
	[est_alterno] [int] NOT NULL,
 	[aud_fecha_creacion] [datetime2](7) NOT NULL CONSTRAINT [DF_estudiante_aud_fecha_creacion] DEFAULT (sysdatetime()),
	[aud_usuario_creacion] [nvarchar](128) NOT NULL CONSTRAINT [DF_estudiante_aud_usuario_creacion] DEFAULT (suser_sname()),
	[aud_fecha_modificacion] [datetime2](7) NULL,
	[aud_usuario_modificacion] [nvarchar](128) NULL,
 CONSTRAINT [PK_estudiante] PRIMARY KEY CLUSTERED 
(
	[est_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_estudiante_est_registro_egresado')
BEGIN
    ALTER TABLE [dbo].[estudiante] ADD CONSTRAINT [DF_estudiante_est_registro_egresado] DEFAULT (0) FOR [est_registro_egresado];
END
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_estudiante_est_user')
BEGIN
    ALTER TABLE [dbo].[estudiante] ADD CONSTRAINT [DF_estudiante_est_user] DEFAULT suser_sname() FOR [est_user];
END
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_estudiante_est_alterno')
BEGIN
    ALTER TABLE [dbo].[estudiante] ADD CONSTRAINT [DF_estudiante_est_alterno] DEFAULT (0) FOR [est_alterno];
END
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[formalidad]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[formalidad](
	[for_codigo] [tinyint] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[for_nombre] [varchar](50) NULL,
	[sippa_for_codigo] [int] NULL,
 CONSTRAINT [PK_formalidad] PRIMARY KEY CLUSTERED 
(
	[for_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[grupo]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[grupo](
	[gru_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[gru_nombre] [varchar](100) NOT NULL,
	[gru_id] [varchar](100) NULL,
	[gru_estado] [int] NULL,
 CONSTRAINT [PK_grupo] PRIMARY KEY CLUSTERED 
(
	[gru_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_grupo_gru_estado')
BEGIN
    ALTER TABLE [dbo].[grupo] ADD CONSTRAINT [DF_grupo_gru_estado] DEFAULT (1) FOR [gru_estado];
END
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[hora]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[hora](
	[hra_codigo] [int] NOT NULL,
	[hra_nombre] [varchar](50) NOT NULL,
	[hra_inicio] [char](7) NOT NULL,
	[hra_fin] [char](10) NOT NULL,
	[hra_inicio_24h] [char](5) NULL,
	[hra_fin_24h] [char](5) NULL,
 CONSTRAINT [PK_hora] PRIMARY KEY CLUSTERED 
(
	[hra_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[matricula]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[matricula](
	[mat_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[est_codigo] [char](11) NOT NULL,
	[cal_codigo] [int] NOT NULL,
	[mat_fecha] [datetime] NOT NULL,
	[mat_problema] [varchar](500) NULL,
	[mat_observacion] [varchar](300) NULL,
	[mat_estado] [char](1) NULL,
	[ese_codigo] [smallint] NULL,
	[mat_tipo] [tinyint] NULL,
	[mat_usuario] [int] NULL,
	[mat_clave] [varchar](80) NULL,
	[mat_cliente] [varchar](50) NULL,
	[mat_ip] [varchar](150) NULL,
	[sippa_calcodigo] [char](7) NULL,
	[mat_fecha_actualizacion] [datetime] NULL,
 	[aud_fecha_creacion] [datetime2](7) NOT NULL CONSTRAINT [DF_matricula_aud_fecha_creacion] DEFAULT (sysdatetime()),
	[aud_usuario_creacion] [nvarchar](128) NOT NULL CONSTRAINT [DF_matricula_aud_usuario_creacion] DEFAULT (suser_sname()),
	[aud_fecha_modificacion] [datetime2](7) NULL,
	[aud_usuario_modificacion] [nvarchar](128) NULL,
 CONSTRAINT [PK_matricula] PRIMARY KEY CLUSTERED 
(
	[mat_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_matricula_mat_fecha')
BEGIN
    ALTER TABLE [dbo].[matricula] ADD CONSTRAINT [DF_matricula_mat_fecha] DEFAULT getdate() FOR [mat_fecha];
END
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_matricula_mat_estado')
BEGIN
    ALTER TABLE [dbo].[matricula] ADD CONSTRAINT [DF_matricula_mat_estado] DEFAULT 'A' FOR [mat_estado];
END
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_matricula_mat_tipo')
BEGIN
    ALTER TABLE [dbo].[matricula] ADD CONSTRAINT [DF_matricula_mat_tipo] DEFAULT (1) FOR [mat_tipo];
END
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_matricula_mat_fecha_actualizacion')
BEGIN
    ALTER TABLE [dbo].[matricula] ADD CONSTRAINT [DF_matricula_mat_fecha_actualizacion] DEFAULT getdate() FOR [mat_fecha_actualizacion];
END
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[matricula_autorizacion]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[matricula_autorizacion](
	[maa_codigo] [tinyint] NOT NULL,
	[maa_nombre] [varchar](25) NULL,
	[maa_observcion] [varchar](100) NULL,
 CONSTRAINT [PK_matricula_autorizacion] PRIMARY KEY CLUSTERED 
(
	[maa_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[matricula_configuracion]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[matricula_configuracion](
	[mco_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[mco_nombre] [varchar](100) NULL,
	[mco_fecha] [datetime] NULL,
	[cal_codigo] [int] NULL,
	[pla_codigo] [int] NULL,
 	[aud_fecha_creacion] [datetime2](7) NOT NULL CONSTRAINT [DF_matricula_configuracion_aud_fecha_creacion] DEFAULT (sysdatetime()),
	[aud_usuario_creacion] [nvarchar](128) NOT NULL CONSTRAINT [DF_matricula_configuracion_aud_usuario_creacion] DEFAULT (suser_sname()),
	[aud_fecha_modificacion] [datetime2](7) NULL,
	[aud_usuario_modificacion] [nvarchar](128) NULL,
 CONSTRAINT [PK_matricula_configuracion] PRIMARY KEY CLUSTERED 
(
	[mco_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_matricula_configuracion_mco_fecha')
BEGIN
    ALTER TABLE [dbo].[matricula_configuracion] ADD CONSTRAINT [DF_matricula_configuracion_mco_fecha] DEFAULT getdate() FOR [mco_fecha];
END
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[matricula_configuracion_detalle]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[matricula_configuracion_detalle](
	[mcd_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[mco_codigo] [int] NOT NULL,
	[mcd_fecha] [datetime] NOT NULL,
	[cur_codigo] [int] NOT NULL,
	[paa_codigo] [int] NOT NULL,
	[mcd_subgrupo] [char](2) NULL,
	[mcd_cerrado] [char](1) NULL,
	[mcd_estado] [int] NULL,
 	[aud_fecha_creacion] [datetime2](7) NOT NULL CONSTRAINT [DF_matricula_configuracion_detalle_aud_fecha_creacion] DEFAULT (sysdatetime()),
	[aud_usuario_creacion] [nvarchar](128) NOT NULL CONSTRAINT [DF_matricula_configuracion_detalle_aud_usuario_creacion] DEFAULT (suser_sname()),
	[aud_fecha_modificacion] [datetime2](7) NULL,
	[aud_usuario_modificacion] [nvarchar](128) NULL,
 CONSTRAINT [PK_matricula_configuracion_detalle] PRIMARY KEY CLUSTERED 
(
	[mcd_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_matricula_configuracion_detalle_mcd_fecha')
BEGIN
    ALTER TABLE [dbo].[matricula_configuracion_detalle] ADD CONSTRAINT [DF_matricula_configuracion_detalle_mcd_fecha] DEFAULT getdate() FOR [mcd_fecha];
END
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_matricula_configuracion_detalle_mcd_estado')
BEGIN
    ALTER TABLE [dbo].[matricula_configuracion_detalle] ADD CONSTRAINT [DF_matricula_configuracion_detalle_mcd_estado] DEFAULT 1 FOR [mcd_cerrado];
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.default_constraints dc JOIN sys.tables t ON dc.parent_object_id = t.object_id JOIN sys.schemas s ON t.schema_id = s.schema_id JOIN sys.columns c ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id WHERE s.name = 'dbo' AND t.name = 'matricula_configuracion_detalle' AND c.name = 'mcd_estado')
BEGIN
    ALTER TABLE [dbo].[matricula_configuracion_detalle] ADD CONSTRAINT [DF_matricula_configuracion_detalle_mcd_estado_val] DEFAULT (1) FOR [mcd_estado];
END
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[municipio]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[municipio](
	[mun_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[mun_id] [char](5) NULL,
	[mun_nombre] [varchar](100) NOT NULL,
	[dep_codigo] [int] NOT NULL,
	[sippa_mun_codigo] [int] NULL,
	[SNIES_codigo] [char](5) NULL,
	[dane_codigo] [char](10) NULL,
 CONSTRAINT [PK_municipio] PRIMARY KEY CLUSTERED 
(
	[mun_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[nivel_academico]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[nivel_academico](
	[nia_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[nia_nombre] [varchar](50) NULL,
	[nia_orden] [tinyint] NULL,
	[for_codigo] [tinyint] NULL,
	[snies_codigo] [char](2) NULL,
	[sippa_nia_codigo] [int] NULL,
	[sippa_nivcodigo] [char](3) NULL,
	[nia_codigo_mp_hecaa] [int] NULL,
	[nia_codigo_ned_hecaa] [int] NULL,
	[nia_codigo_ne_hecaa] [int] NULL,
	[nat_codigo] [int] NULL,
	[nia_cap_puntos] [int] NULL,
	[nia_cap_puntos_adicionales] [int] NULL,
	[nia_cap_maximo] [int] NULL,
	[nia_cap_puntos_xano] [int] NULL,
	[nia_cap_descripcion] [int] NULL,
	[nia_estado] [varchar](1) NOT NULL,
	[nia_cap_estado] [int] NULL,
 CONSTRAINT [PK_nivel_academico] PRIMARY KEY CLUSTERED 
(
	[nia_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_nivel_academico_nia_estado')
BEGIN
    ALTER TABLE [dbo].[nivel_academico] ADD CONSTRAINT [DF_nivel_academico_nia_estado] DEFAULT (1) FOR [nia_estado];
END
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[novedad]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[novedad](
	[nov_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[nov_nombre] [varchar](300) NOT NULL,
	[not_codigo] [int] NOT NULL,
	[nov_descarga_semanal] [int] NULL,
	[nov_descarga_semestral] [int] NULL,
	[nov_fecha_inicio] [datetime] NULL,
	[nov_fecha_fin] [datetime] NULL,
	[nov_activa] [char](1) NULL,
	[nov_valida] [int] NULL,
	[nov_descripcion] [varchar](250) NULL,
	[nov_usar] [int] NULL,
	[sippa_novcodigo] [char](4) NULL,
 	[aud_fecha_creacion] [datetime2](7) NOT NULL CONSTRAINT [DF_novedad_aud_fecha_creacion] DEFAULT (sysdatetime()),
	[aud_usuario_creacion] [nvarchar](128) NOT NULL CONSTRAINT [DF_novedad_aud_usuario_creacion] DEFAULT (suser_sname()),
	[aud_fecha_modificacion] [datetime2](7) NULL,
	[aud_usuario_modificacion] [nvarchar](128) NULL,
 CONSTRAINT [PK_novedad] PRIMARY KEY CLUSTERED 
(
	[nov_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_novedad_nov_activa')
BEGIN
    ALTER TABLE [dbo].[novedad] ADD CONSTRAINT [DF_novedad_nov_activa] DEFAULT 'A' FOR [nov_activa];
END
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_novedad_nov_valida')
BEGIN
    ALTER TABLE [dbo].[novedad] ADD CONSTRAINT [DF_novedad_nov_valida] DEFAULT (1) FOR [nov_valida];
END
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_novedad_nov_usar')
BEGIN
    ALTER TABLE [dbo].[novedad] ADD CONSTRAINT [DF_novedad_nov_usar] DEFAULT (1) FOR [nov_usar];
END
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[nucleo]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[nucleo](
	[nuc_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[nuc_nombre] [char](25) NULL,
	[nuc_estado] [bit] NULL,
	[nuc_acronimo] [char](1) NULL,
 CONSTRAINT [PK_nucleo] PRIMARY KEY CLUSTERED 
(
	[nuc_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_nucleo_nuc_estado')
BEGIN
    ALTER TABLE [dbo].[nucleo] ADD CONSTRAINT [DF_nucleo_nuc_estado] DEFAULT 0 FOR [nuc_estado];
END
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[periodo]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[periodo](
	[per_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[pet_codigo] [int] NULL,
	[per_nombre] [varchar](50) NULL,
	[per_anio] [int] NOT NULL,
	[per_periodo] [tinyint] NULL,
	[per_fecha_inicio] [datetime] NULL,
	[per_fecha_fin] [datetime] NULL,
	[per_inicio_actividades] [date] NULL,
	[per_fin_actividades] [date] NULL,
	[per_acuerdo_actividades] [varchar](max) NULL,
	[sippa_per_codigo] [char](5) NULL,
 CONSTRAINT [PK_periodo] PRIMARY KEY CLUSTERED 
(
	[per_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[persona]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[persona](
	[per_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[per_identificacion] [varchar](15) NOT NULL,
	[tii_codigo] [int] NOT NULL,
	[per_libreta_militar] [varchar](15) NULL,
	[per_apellido] [varchar](40) NULL,
	[per_nombre] [varchar](40) NULL,
	[per_genero] [char](1) NULL,
	[per_lugar_expedicion] [int] NULL,
	[per_fecha_expedicion] [date] NULL,
	[per_fecha_nacimiento] [date] NULL,
	[per_direccion_residencia] [varchar](255) NULL,
	[per_telefono_movil] [varchar](50) NULL,
	[per_telefono_fijo] [varchar](30) NULL,
	[per_estado_civil] [char](1) NULL,
	[per_lugar_nacimiento] [int] NULL,
	[per_lugar_residencia] [int] NULL,
	[per_departamento_residencia] [int] NULL,
	[per_pais_residencia] [int] NULL,
	[per_barrio] [varchar](50) NULL,
	[per_estrato] [tinyint] NULL,
	[eps_codigo] [int] NULL,
	[eta_codigo] [int] NULL,
	[per_numero_afiliacion_eps] [varchar](20) NULL,
	[per_ips_sisben] [varchar](200) NULL,
	[per_id_cotizante] [varchar](15) NULL,
	[per_beneficiario_ley1081] [char](1) NULL,
	[per_familiar_direccion] [varchar](255) NULL,
	[per_familiar_nombre] [varchar](60) NULL,
	[per_familiar_telefono] [varchar](30) NULL,
	[per_familiar_lugar_residencia] [int] NULL,
	[per_email] [varchar](100) NULL,
	[per_email_interno] [varchar](100) NULL,
	[enviar_correo] [tinyint] NULL,
	[per_pagina_personal] [varchar](100) NULL,
	[grs_codigo] [int] NULL,
	[per_estado] [tinyint] NULL,
	[nat_codigo] [int] NULL,
	[reg_codigo] [int] NULL,
	[per_razon_social] [varchar](200) NULL,
	[per_identificacion_dup] [varchar](15) NULL,
	[per_cedula] [varchar](15) NULL,
	[per_tarjeta] [varchar](15) NULL,
	[per_codigo_postal] [varchar](10) NULL,
	[per_pasaporte] [varchar](10) NULL,
	[per_huella] [varbinary](3000) NULL,
	[per_fecha_registro] [datetime] NULL,
	[per_codigo_pais_hecaa] [int] NULL,
	[per_fecha_actualizacion] [datetime] NULL,
	[lenguaNativa] [int] NULL,
	[eps_par_codigo] [int] NULL,
	[era_codigo] [int] NULL,
	[evt_codigo] [int] NULL,
	[per_municipio_procedencia] [int] NULL,
	[zor_codigo] [int] NULL,
	[scs_codigo] [int] NULL,
	[per_email_alterno] [varchar](100) NULL,
	[ors_codigo] [int] NULL,
	[idge_codigo] [int] NULL,
 CONSTRAINT [PK_persona] PRIMARY KEY CLUSTERED 
(
	[per_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_persona_per_lugar_expedicion')
BEGIN
    ALTER TABLE [dbo].[persona] ADD CONSTRAINT [DF_persona_per_lugar_expedicion] DEFAULT (1124) FOR [per_lugar_expedicion];
END
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_persona_per_lugar_nacimiento')
BEGIN
    ALTER TABLE [dbo].[persona] ADD CONSTRAINT [DF_persona_per_lugar_nacimiento] DEFAULT (1124) FOR [per_lugar_nacimiento];
END
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_persona_per_lugar_residencia')
BEGIN
    ALTER TABLE [dbo].[persona] ADD CONSTRAINT [DF_persona_per_lugar_residencia] DEFAULT (1124) FOR [per_lugar_residencia];
END
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_persona_per_pais_residencia')
BEGIN
    ALTER TABLE [dbo].[persona] ADD CONSTRAINT [DF_persona_per_pais_residencia] DEFAULT (21) FOR [per_pais_residencia];
END
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_persona_per_estado')
BEGIN
    ALTER TABLE [dbo].[persona] ADD CONSTRAINT [DF_persona_per_estado] DEFAULT (1) FOR [per_estado];
END
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_persona_per_fecha_registro')
BEGIN
    ALTER TABLE [dbo].[persona] ADD CONSTRAINT [DF_persona_per_fecha_registro] DEFAULT getdate() FOR [per_fecha_registro];
END
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_persona_per_fecha_actualizacion')
BEGIN
    ALTER TABLE [dbo].[persona] ADD CONSTRAINT [DF_persona_per_fecha_actualizacion] DEFAULT getdate() FOR [per_fecha_actualizacion];
END
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[persona_novedad]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[persona_novedad](
	[pen_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[pen_persona] [int] NOT NULL,
	[uap_codigo] [int] NULL,
	[nov_codigo] [int] NOT NULL,
	[pen_fecha_inicio] [datetime] NULL,
	[pen_fecha_fin] [datetime] NULL,
	[per_codigo] [int] NULL,
	[pen_documento] [char](10) NULL,
	[pen_descripcion] [nvarchar](500) NULL,
	[pen_semanas] [char](10) NULL,
	[pen_descarga_semanal] [int] NULL,
	[pen_descarga_semestral] [int] NULL,
	[pen_estado] [int] NULL,
	[sippa_novcodigo] [char](4) NULL,
	[sippa_doccedula] [char](11) NULL,
	[sippa_percodigo] [char](5) NULL,
	[sippa_novfecini] [datetime] NULL,
 	[aud_fecha_creacion] [datetime2](7) NOT NULL CONSTRAINT [DF_persona_novedad_aud_fecha_creacion] DEFAULT (sysdatetime()),
	[aud_usuario_creacion] [nvarchar](128) NOT NULL CONSTRAINT [DF_persona_novedad_aud_usuario_creacion] DEFAULT (suser_sname()),
	[aud_fecha_modificacion] [datetime2](7) NULL,
	[aud_usuario_modificacion] [nvarchar](128) NULL,
 CONSTRAINT [PK_persona_novedad] PRIMARY KEY CLUSTERED 
(
	[pen_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[persona_proyecto]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[persona_proyecto](
	[pep_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[pry_codigo] [int] NOT NULL,
	[pep_persona] [int] NOT NULL,
	[uap_codigo] [int] NULL,
	[pep_hora_semana] [smallint] NOT NULL,
	[pep_semanas] [smallint] NOT NULL,
	[pep_descarga_semestral] [int] NULL,
	[per_codigo] [int] NOT NULL,
	[pep_cargo] [int] NULL,
	[con_contrato] [varchar](50) NULL,
	[prr_codigo] [int] NULL,
	[sippa_proydocente] [char](11) NULL,
	[sippa_proycodigo] [char](10) NULL,
	[sippa_percodigo] [char](5) NULL,
	[sippa_proyfecini] [datetime] NULL,
 	[aud_fecha_creacion] [datetime2](7) NOT NULL CONSTRAINT [DF_persona_proyecto_aud_fecha_creacion] DEFAULT (sysdatetime()),
	[aud_usuario_creacion] [nvarchar](128) NOT NULL CONSTRAINT [DF_persona_proyecto_aud_usuario_creacion] DEFAULT (suser_sname()),
	[aud_fecha_modificacion] [datetime2](7) NULL,
	[aud_usuario_modificacion] [nvarchar](128) NULL,
 CONSTRAINT [PK_proyecto_persona] PRIMARY KEY CLUSTERED 
(
	[pep_codigo] ASC,
	[pry_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[plan_academico]
-- ----------------------------------------------------------------------------
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
 	[aud_fecha_creacion] [datetime2](7) NOT NULL CONSTRAINT [DF_plan_academico_aud_fecha_creacion] DEFAULT (sysdatetime()),
	[aud_usuario_creacion] [nvarchar](128) NOT NULL CONSTRAINT [DF_plan_academico_aud_usuario_creacion] DEFAULT (suser_sname()),
	[aud_fecha_modificacion] [datetime2](7) NULL,
	[aud_usuario_modificacion] [nvarchar](128) NULL,
 CONSTRAINT [PK_plan_academico] PRIMARY KEY CLUSTERED 
(
	[pla_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_plan_academico_pla_antiguedad')
BEGIN
    ALTER TABLE [dbo].[plan_academico] ADD CONSTRAINT [DF_plan_academico_pla_antiguedad] DEFAULT (0) FOR [pla_antiguo];
END
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_plan_academico_pla_estado')
BEGIN
    ALTER TABLE [dbo].[plan_academico] ADD CONSTRAINT [DF_plan_academico_pla_estado] DEFAULT (0) FOR [pla_estado];
END
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_plan_academico_pla_actual')
BEGIN
    ALTER TABLE [dbo].[plan_academico] ADD CONSTRAINT [DF_plan_academico_pla_actual] DEFAULT (1) FOR [pla_actual];
END
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_plan_academico_fecha_creacion_registro')
BEGIN
    ALTER TABLE [dbo].[plan_academico] ADD CONSTRAINT [DF_plan_academico_fecha_creacion_registro] DEFAULT getdate() FOR [fecha_creacion];
END
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[plan_academico_asignatura]
-- ----------------------------------------------------------------------------
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
 	[aud_fecha_creacion] [datetime2](7) NOT NULL CONSTRAINT [DF_plan_academico_asignatura_aud_fecha_creacion] DEFAULT (sysdatetime()),
	[aud_usuario_creacion] [nvarchar](128) NOT NULL CONSTRAINT [DF_plan_academico_asignatura_aud_usuario_creacion] DEFAULT (suser_sname()),
	[aud_fecha_modificacion] [datetime2](7) NULL,
	[aud_usuario_modificacion] [nvarchar](128) NULL,
 CONSTRAINT [PK_plan_academico_asignatura] PRIMARY KEY CLUSTERED 
(
	[paa_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_plan_academico_asignatura_paa_credito')
BEGIN
    ALTER TABLE [dbo].[plan_academico_asignatura] ADD CONSTRAINT [DF_plan_academico_asignatura_paa_credito] DEFAULT (0) FOR [paa_credito];
END
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_plan_academico_asignatura_pet_codigo')
BEGIN
    ALTER TABLE [dbo].[plan_academico_asignatura] ADD CONSTRAINT [DF_plan_academico_asignatura_pet_codigo] DEFAULT (1) FOR [pet_codigo];
END
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_plan_academico_asignatura_paa_nota_minima')
BEGIN
    ALTER TABLE [dbo].[plan_academico_asignatura] ADD CONSTRAINT [DF_plan_academico_asignatura_paa_nota_minima] DEFAULT (3.0) FOR [paa_nota_minima];
END
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_plan_academico_asignatura_paa_chequeo_requisito')
BEGIN
    ALTER TABLE [dbo].[plan_academico_asignatura] ADD CONSTRAINT [DF_plan_academico_asignatura_paa_chequeo_requisito] DEFAULT (0) FOR [paa_chequeo_requisito];
END
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_plan_academico_asignatura_paa_plan_academico')
BEGIN
    ALTER TABLE [dbo].[plan_academico_asignatura] ADD CONSTRAINT [DF_plan_academico_asignatura_paa_plan_academico] DEFAULT (0) FOR [paa_plan_academico];
END
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_plan_academico_asignatura_paa_programable')
BEGIN
    ALTER TABLE [dbo].[plan_academico_asignatura] ADD CONSTRAINT [DF_plan_academico_asignatura_paa_programable] DEFAULT 's' FOR [paa_programable];
END
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_plan_academico_asignatura_paa_multi_asignatura')
BEGIN
    ALTER TABLE [dbo].[plan_academico_asignatura] ADD CONSTRAINT [DF_plan_academico_asignatura_paa_multi_asignatura] DEFAULT 'n' FOR [paa_multi_asignatura];
END
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF__plan_acad__for_c__2E69EDB8')
BEGIN
    ALTER TABLE [dbo].[plan_academico_asignatura] ADD CONSTRAINT [DF__plan_acad__for_c__2E69EDB8] DEFAULT (1) FOR [for_codigo];
END
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[plan_estudiante]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[plan_estudiante](
	[ple_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[est_codigo] [char](11) NULL,
	[pla_codigo] [int] NULL,
	[ple_estado] [bit] NULL,
	[res_codigo] [int] NULL,
	[ple_observacion] [varchar](200) NULL,
	[sippa_placodigo] [char](7) NULL,
	[sippa_procodigo] [char](4) NULL,
	[ple_fecha_registro] [datetime] NULL,
 	[aud_fecha_creacion] [datetime2](7) NOT NULL CONSTRAINT [DF_plan_estudiante_aud_fecha_creacion] DEFAULT (sysdatetime()),
	[aud_usuario_creacion] [nvarchar](128) NOT NULL CONSTRAINT [DF_plan_estudiante_aud_usuario_creacion] DEFAULT (suser_sname()),
	[aud_fecha_modificacion] [datetime2](7) NULL,
	[aud_usuario_modificacion] [nvarchar](128) NULL,
 CONSTRAINT [PK_plan_estudiante] PRIMARY KEY CLUSTERED 
(
	[ple_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_plan_estudiante_ple_fecha_registro')
BEGIN
    ALTER TABLE [dbo].[plan_estudiante] ADD CONSTRAINT [DF_plan_estudiante_ple_fecha_registro] DEFAULT getdate() FOR [ple_fecha_registro];
END
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[prerrequisito]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[prerrequisito](
	[pre_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[pla_codigo] [int] NULL,
	[asi_codigo] [int] NULL,
	[asi_requisito] [int] NULL,
	[pre_creditos] [int] NULL,
	[pre_codigos] [varchar](20) NULL,
	[sippa_plancodigo] [char](7) NULL,
	[sippa_asicodigo] [char](8) NULL,
	[sippa_preasignatura] [char](8) NULL,
 CONSTRAINT [PK_prerequisito] PRIMARY KEY CLUSTERED 
(
	[pre_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[programa]
-- ----------------------------------------------------------------------------
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
 	[aud_fecha_creacion] [datetime2](7) NOT NULL CONSTRAINT [DF_programa_aud_fecha_creacion] DEFAULT (sysdatetime()),
	[aud_usuario_creacion] [nvarchar](128) NOT NULL CONSTRAINT [DF_programa_aud_usuario_creacion] DEFAULT (suser_sname()),
	[aud_fecha_modificacion] [datetime2](7) NULL,
	[aud_usuario_modificacion] [nvarchar](128) NULL,
 CONSTRAINT [PK_programa] PRIMARY KEY CLUSTERED 
(
	[pro_codigo] ASC,
	[uaa_codigo] ASC,
	[sed_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_programa_pro_extension_snies')
BEGIN
    ALTER TABLE [dbo].[programa] ADD CONSTRAINT [DF_programa_pro_extension_snies] DEFAULT 'n' FOR [pro_extension_snies];
END
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_programa_pro_fecha_creacion')
BEGIN
    ALTER TABLE [dbo].[programa] ADD CONSTRAINT [DF_programa_pro_fecha_creacion] DEFAULT getdate() FOR [pro_fecha_creacion];
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.default_constraints dc JOIN sys.tables t ON dc.parent_object_id = t.object_id JOIN sys.schemas s ON t.schema_id = s.schema_id JOIN sys.columns c ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id WHERE s.name = 'dbo' AND t.name = 'programa' AND c.name = 'pro_propedeutico')
BEGIN
    ALTER TABLE [dbo].[programa] ADD CONSTRAINT [DF_programa_pro_propedeutico] DEFAULT (0) FOR [pro_propedeutico];
END
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[programacion_proceso]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[programacion_proceso](
	[prp_codigo] [int] NOT NULL,
	[prp_nombre] [char](50) NULL,
	[prp_orden] [int] NULL,
	[nuc_codigo] [int] NULL,
 CONSTRAINT [PK_programacion_proceso] PRIMARY KEY CLUSTERED 
(
	[prp_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[proyecto]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[proyecto](
	[pry_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[gru_codigo] [int] NULL,
	[pry_nombre] [varchar](300) NOT NULL,
	[prt_codigo] [int] NOT NULL,
	[pry_coordinador] [int] NULL,
	[pry_fecha_inicio] [datetime] NULL,
	[pry_fecha_fin] [datetime] NULL,
	[pry_cvlac] [char](10) NULL,
	[pry_resultados] [varchar](200) NULL,
	[pry_colciencias] [int] NULL,
	[pry_resumen] [varchar](200) NULL,
	[pry_objetivo] [varchar](200) NULL,
	[pre_codigo] [int] NULL,
	[pry_duracionestimada] [smallint] NULL,
	[pry_acto_administrativo] [nchar](50) NULL,
	[pry_acto_administrativo_fecha] [datetime] NULL,
	[pry_acta_aprobacion] [nvarchar](500) NULL,
	[pry_justificacion_beneficio] [nvarchar](4000) NULL,
	[pry_secretario_administrativo] [int] NULL,
	[pry_decano] [int] NULL,
	[pry_facultad] [int] NULL,
	[prs_codigo] [int] NULL,
	[prc_codigo] [int] NULL,
	[sippa_proycodigo] [char](10) NULL,
 CONSTRAINT [PK_proyecto] PRIMARY KEY CLUSTERED 
(
	[pry_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[proyecto_tipo]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[proyecto_tipo](
	[prt_codigo] [int] NOT NULL,
	[prt_nombre] [varchar](50) NULL,
	[sippa_tiproycodigo] [char](2) NULL,
 CONSTRAINT [PK_proyecto_tipo] PRIMARY KEY CLUSTERED 
(
	[prt_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[sede]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[sede](
	[sed_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[sed_nombre] [varchar](50) NOT NULL,
	[mun_codigo] [int] NOT NULL,
	[sippa_sed_codigo] [int] NULL,
	[sed_estado] [varchar](1) NULL,
	[SedNombre_corto] [nchar](3) NULL,
	[sed_PDI] [int] NULL,
	[sed_dependencia] [int] NULL,
 CONSTRAINT [PK_sede] PRIMARY KEY CLUSTERED 
(
	[sed_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_sede_sed_estado')
BEGIN
    ALTER TABLE [dbo].[sede] ADD CONSTRAINT [DF_sede_sed_estado] DEFAULT (1) FOR [sed_estado];
END
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[sub_sede]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[sub_sede](
	[sus_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[sus_nombre] [varchar](50) NOT NULL,
	[sed_codigo] [int] NOT NULL,
	[sus_direccion] [varchar](50) NULL,
	[sus_telefono] [char](20) NULL,
	[sippa_sedcodigo] [char](2) NULL,
	[sus_estado] [int] NULL,
 CONSTRAINT [PK_sub_sede_1] PRIMARY KEY CLUSTERED 
(
	[sus_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_sub_sede_sus_estado')
BEGIN
    ALTER TABLE [dbo].[sub_sede] ADD CONSTRAINT [DF_sub_sede_sus_estado] DEFAULT (1) FOR [sus_estado];
END
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[tipo_curso]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[tipo_curso](
	[tic_codigo] [int] NOT NULL,
	[tic_nombre] [varchar](50) NULL,
	[tic_nombre_corto] [varchar](20) NULL,
 CONSTRAINT [PK_tipo_curso] PRIMARY KEY CLUSTERED 
(
	[tic_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[tipo_escala]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[tipo_escala](
	[tes_codigo] [int] IDENTITY(1,1) NOT NULL,
	[tes_nombre] [varchar](255) NULL,
	[tes_estado] [varchar](1) NULL,
 CONSTRAINT [PK_tipo_escala] PRIMARY KEY CLUSTERED 
(
	[tes_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[uaa]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[uaa](
	[uaa_codigo] [int] IDENTITY(1,1) NOT NULL,
	[uat_codigo] [int] NOT NULL,
	[uaa_nombre] [varchar](200) NOT NULL,
	[uaa_dependencia] [int] NULL,
	[uaa_nombre_corto] [varchar](200) NULL,
	[uaa_nombre_impresion] [varchar](20) NULL,
	[uaa_email] [varchar](50) NULL,
	[uaa_email_pqr] [varchar](50) NULL,
	[uaa_pagina] [varchar](50) NULL,
	[uaa_jefe] [varchar](50) NULL,
	[mun_codigo] [int] NULL,
	[uaa_telefono] [varchar](50) NULL,
	[uaa_fax] [varchar](50) NULL,
	[uaa_direccion] [varchar](50) NULL,
	[sippa_uaa_codigo] [int] NULL,
	[sed_codigo] [int] NULL,
	[uaa_centro_costos] [char](3) NULL,
	[uaa_acronimo] [char](7) NULL,
	[uaa_estado] [int] NULL,
	[uaa_ventanilla] [int] NULL,
	[uaa_codigo_retencion] [varchar](15) NULL,
	[uaa_propietario_codigo] [int] NULL,
	[uaa_jefe_per_codigo] [bigint] NULL,
 CONSTRAINT [PK_unidad_academica_administrativa] PRIMARY KEY CLUSTERED 
(
	[uaa_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_uaa_uaa_estado')
BEGIN
    ALTER TABLE [dbo].[uaa] ADD CONSTRAINT [DF_uaa_uaa_estado] DEFAULT (1) FOR [uaa_estado];
END
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[uaa_cargo]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[uaa_cargo](
	[uac_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[uac_uaa] [int] NULL,
	[uac_cargo] [int] NULL,
	[uac_vinculacion] [int] NULL,
	[uac_dedicacion] [int] NULL,
	[uac_codigoplanta] [nvarchar](4) NULL,
	[uac_grado] [int] NULL,
	[uac_estado] [int] NULL,
 CONSTRAINT [PK_uaa_cargo] PRIMARY KEY CLUSTERED 
(
	[uac_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_uaa_cargo_uac_estado')
BEGIN
    ALTER TABLE [dbo].[uaa_cargo] ADD CONSTRAINT [DF_uaa_cargo_uac_estado] DEFAULT (1) FOR [uac_estado];
END
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[uaa_personal]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[uaa_personal](
	[uap_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[uaa_codigo] [int] NOT NULL,
	[per_codigo] [int] NOT NULL,
	[uap_fecha_inicio] [date] NOT NULL,
	[uap_fecha_fin] [date] NULL,
	[uap_cargo] [int] NULL,
	[vin_codigo] [int] NOT NULL,
	[ded_codigo] [int] NULL,
	[uap_resolucion] [varchar](100) NULL,
	[uap_estado] [smallint] NULL,
	[esv_codigo] [int] NULL,
	[esc_valor] [money] NULL,
	[sippa_puntos] [varchar](500) NULL,
	[sippa_doccedula] [char](11) NULL,
	[sippa_vincodigo] [char](3) NULL,
	[sippa_calcodigo] [char](6) NULL,
	[sippa_dedcodigo] [char](1) NULL,
	[uap_codigo_anterior] [int] NULL,
	[uac_codigo] [int] NULL,
	[uap_plantaencargo] [char](1) NULL,
	[uap_uacocupado] [int] NULL,
	[uap_dependencia_ejerce] [int] NULL,
	[codRegistro] [bigint] NULL,
	[uap_id_carnet] [varchar](45) NULL,
	[sed_codigo] [int] NULL,
	[uap_observacion] [varchar](max) NULL,
	[uap_auto_tratamiento_datos] [int] NULL,
	[uap_fecha_auto_tratamiento_datos] [datetime] NULL,
 	[aud_fecha_creacion] [datetime2](7) NOT NULL CONSTRAINT [DF_uaa_personal_aud_fecha_creacion] DEFAULT (sysdatetime()),
	[aud_usuario_creacion] [nvarchar](128) NOT NULL CONSTRAINT [DF_uaa_personal_aud_usuario_creacion] DEFAULT (suser_sname()),
	[aud_fecha_modificacion] [datetime2](7) NULL,
	[aud_usuario_modificacion] [nvarchar](128) NULL,
 CONSTRAINT [PK_uaa_personal] PRIMARY KEY CLUSTERED 
(
	[uap_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_uaa_personal_uap_estado')
BEGIN
    ALTER TABLE [dbo].[uaa_personal] ADD CONSTRAINT [DF_uaa_personal_uap_estado] DEFAULT (1) FOR [uap_estado];
END
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[usuario_grupo]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[usuario_grupo](
	[usg_codigo] [int] IDENTITY(1,1) NOT NULL,
	[usg_usuario] [int] NULL,
	[usg_grupo] [int] NULL,
	[usg_uaa] [int] NULL,
	[usg_estado] [tinyint] NULL,
 CONSTRAINT [PK_usuario_grupo] PRIMARY KEY CLUSTERED 
(
	[usg_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_usuario_grupo_usg_estado_1')
BEGIN
    ALTER TABLE [dbo].[usuario_grupo] ADD CONSTRAINT [DF_usuario_grupo_usg_estado_1] DEFAULT (1) FOR [usg_estado];
END
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[vinculacion]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[vinculacion](
	[vin_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[vin_nombre] [varchar](50) NOT NULL,
	[vin_horas_year] [int] NULL,
	[vin_clase] [int] NULL,
	[sippa_vincodigo] [char](3) NULL,
	[vin_contratacion] [varchar](1) NULL,
	[vin_externa] [int] NULL,
	[vin_estado] [int] NOT NULL,
 CONSTRAINT [PK_vinculacion] PRIMARY KEY CLUSTERED 
(
	[vin_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY];
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_vinculacion_vin_contratacion')
BEGIN
    ALTER TABLE [dbo].[vinculacion] ADD CONSTRAINT [DF_vinculacion_vin_contratacion] DEFAULT (0) FOR [vin_contratacion];
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.default_constraints dc JOIN sys.tables t ON dc.parent_object_id = t.object_id JOIN sys.schemas s ON t.schema_id = s.schema_id JOIN sys.columns c ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id WHERE s.name = 'dbo' AND t.name = 'vinculacion' AND c.name = 'vin_estado')
BEGIN
    ALTER TABLE [dbo].[vinculacion] ADD CONSTRAINT [DF_vinculacion_vin_estado] DEFAULT (1) FOR [vin_estado];
END
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[web_parametro]
-- ----------------------------------------------------------------------------
CREATE TABLE [dbo].[web_parametro](
	[wep_codigo] [int] IDENTITY(1,1) NOT NULL,
	[wep_nombre] [varchar](100) NOT NULL,
	[wep_valor] [varchar](max) NOT NULL,
	[wep_descripcion] [varchar](500) NULL,
	[wep_estado] [int] NOT NULL,
 CONSTRAINT [PK_web_parametro_1] PRIMARY KEY CLUSTERED 
(
	[wep_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];
GO

IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_web_parametro_wep_estado')
BEGIN
    ALTER TABLE [dbo].[web_parametro] ADD CONSTRAINT [DF_web_parametro_wep_estado] DEFAULT (1) FOR [wep_estado];
END
GO

-- ============================================================================
-- TABLAS DE SOPORTE, VINCULACIONES EXTERNAS Y PERSISTENCIA HISTÓRICA
-- (Resuelve dependencias de vistas institucionales y referencias de claves foráneas)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[espacio_ocupacion_historico] (Histórico de ocupación de aulas)
-- ----------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'dbo' AND t.name = 'espacio_ocupacion_historico')
BEGIN
    CREATE TABLE [dbo].[espacio_ocupacion_historico](
        [eso_codigo] [int] IDENTITY(1,1) NOT NULL,
        [esp_codigo] [int] NOT NULL,
        [uaa_codigo] [int] NOT NULL,
        [eso_fecha] [datetime] NOT NULL,
        [hor_codigo] [int] NULL,
        [dia_codigo] [int] NULL,
        [hra_codigo] [int] NULL,
        [eso_actividad] [int] NULL,
        [eso_subgrupo] [char](2) NULL,
        [uap_codigo] [int] NULL,
        [eso_estado] [char](1) NULL,
        [oct_codigo] [int] NULL,
        [eso_descripcion] [varchar](200) NULL,
        [cdp_codigo] [int] NULL,
        [ctr_codigo] [int] NULL,
        [usu_codigo] [int] NULL,
        [aud_fecha_creacion] [datetime2](7) NOT NULL CONSTRAINT [DF_espacio_ocupacion_historico_aud_fecha_creacion] DEFAULT (sysdatetime()),
        [aud_usuario_creacion] [nvarchar](128) NOT NULL CONSTRAINT [DF_espacio_ocupacion_historico_aud_usuario_creacion] DEFAULT (suser_sname()),
        CONSTRAINT [PK_espacio_ocupacion_historico] PRIMARY KEY CLUSTERED ([eso_codigo] ASC)
    );
END
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[programa_dpto] (Relación programa académico - departamento UAA)
-- ----------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'dbo' AND t.name = 'programa_dpto')
BEGIN
    CREATE TABLE [dbo].[programa_dpto](
        [prd_id] [int] IDENTITY(1,1) NOT NULL,
        [uaa_codigo] [int] NOT NULL,
        [pro_codigo] [int] NOT NULL,
        [prd_estado] [tinyint] NOT NULL CONSTRAINT [DF_programa_dpto_prd_estado] DEFAULT (1),
        CONSTRAINT [PK_programa_dpto] PRIMARY KEY CLUSTERED ([prd_id] ASC)
    );
END
GO

-- ----------------------------------------------------------------------------
-- TABLAS DE CUENTAS DE USUARIO INSTITUCIONALES (Vistas usuario_*)
-- ----------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'dbo' AND t.name = 'usuario_docentes')
BEGIN
    CREATE TABLE [dbo].[usuario_docentes](
        [uid] [varchar](50) NOT NULL,
        [per_codigo] [int] NULL,
        [uaa_codigo] [int] NULL,
        [us_nombre] [varchar](100) NULL,
        [us_apellido] [varchar](100) NULL,
        [us_titulo] [varchar](100) NULL,
        [us_correo] [varchar](150) NULL,
        [us_estado] [tinyint] NOT NULL CONSTRAINT [DF_usuario_docentes_us_estado] DEFAULT (1),
        CONSTRAINT [PK_usuario_docentes] PRIMARY KEY CLUSTERED ([uid] ASC)
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'dbo' AND t.name = 'usuario_administrativos')
BEGIN
    CREATE TABLE [dbo].[usuario_administrativos](
        [uid] [varchar](50) NOT NULL,
        [per_codigo] [int] NULL,
        [uaa_codigo] [int] NULL,
        [us_nombre] [varchar](100) NULL,
        [us_apellido] [varchar](100) NULL,
        [us_titulo] [varchar](100) NULL,
        [us_correo] [varchar](150) NULL,
        [us_estado] [tinyint] NOT NULL CONSTRAINT [DF_usuario_administrativos_us_estado] DEFAULT (1),
        CONSTRAINT [PK_usuario_administrativos] PRIMARY KEY CLUSTERED ([uid] ASC)
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'dbo' AND t.name = 'usuario_estudiantes')
BEGIN
    CREATE TABLE [dbo].[usuario_estudiantes](
        [uid] [varchar](50) NOT NULL,
        [est_codigo] [char](11) NULL,
        [us_nombre] [varchar](100) NULL,
        [us_apellido] [varchar](100) NULL,
        [us_correo] [varchar](150) NULL,
        [us_estado] [tinyint] NOT NULL CONSTRAINT [DF_usuario_estudiantes_us_estado] DEFAULT (1),
        CONSTRAINT [PK_usuario_estudiantes] PRIMARY KEY CLUSTERED ([uid] ASC)
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'dbo' AND t.name = 'usuario_estudiantes_virtual')
BEGIN
    CREATE TABLE [dbo].[usuario_estudiantes_virtual](
        [uid] [varchar](50) NOT NULL,
        [est_codigo] [char](11) NULL,
        [us_nombre] [varchar](100) NULL,
        [us_apellido] [varchar](100) NULL,
        [us_correo] [varchar](150) NULL,
        [us_estado] [tinyint] NOT NULL CONSTRAINT [DF_usuario_estudiantes_virtual_us_estado] DEFAULT (1),
        CONSTRAINT [PK_usuario_estudiantes_virtual] PRIMARY KEY CLUSTERED ([uid] ASC)
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'dbo' AND t.name = 'usuario_estudiantes_intercambio')
BEGIN
    CREATE TABLE [dbo].[usuario_estudiantes_intercambio](
        [uid] [varchar](50) NOT NULL,
        [est_codigo] [char](11) NULL,
        [us_nombre] [varchar](100) NULL,
        [us_apellido] [varchar](100) NULL,
        [us_correo] [varchar](150) NULL,
        [us_estado] [tinyint] NOT NULL CONSTRAINT [DF_usuario_estudiantes_intercambio_us_estado] DEFAULT (1),
        CONSTRAINT [PK_usuario_estudiantes_intercambio] PRIMARY KEY CLUSTERED ([uid] ASC)
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'dbo' AND t.name = 'usuario_graduados')
BEGIN
    CREATE TABLE [dbo].[usuario_graduados](
        [uid] [varchar](50) NOT NULL,
        [per_codigo] [int] NULL,
        [us_nombre] [varchar](100) NULL,
        [us_apellido] [varchar](100) NULL,
        [us_correo] [varchar](150) NULL,
        [us_estado] [tinyint] NOT NULL CONSTRAINT [DF_usuario_graduados_us_estado] DEFAULT (1),
        CONSTRAINT [PK_usuario_graduados] PRIMARY KEY CLUSTERED ([uid] ASC)
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'dbo' AND t.name = 'usuario_externos')
BEGIN
    CREATE TABLE [dbo].[usuario_externos](
        [uid] [varchar](50) NOT NULL,
        [per_codigo] [int] NULL,
        [us_nombre] [varchar](100) NULL,
        [us_apellido] [varchar](100) NULL,
        [us_correo] [varchar](150) NULL,
        [us_estado] [tinyint] NOT NULL CONSTRAINT [DF_usuario_externos_us_estado] DEFAULT (1),
        CONSTRAINT [PK_usuario_externos] PRIMARY KEY CLUSTERED ([uid] ASC)
    );
END
GO

-- ----------------------------------------------------------------------------
-- TABLAS DE PARTICIONAMIENTO DE MATRICULA (Vistas matricula_curso)
-- ----------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'dbo' AND t.name = 'matricula_curso_actual')
BEGIN
    CREATE TABLE [dbo].[matricula_curso_actual](
        [mat_codigo] [int] NOT NULL,
        [cur_codigo] [int] NOT NULL,
        [est_codigo] [char](11) NOT NULL,
        [mac_nota_definitiva] [decimal](3,1) NULL,
        [mac_estado] [tinyint] NOT NULL CONSTRAINT [DF_matricula_curso_actual_mac_estado] DEFAULT (1),
        [per_codigo] [int] NULL,
        CONSTRAINT [PK_matricula_curso_actual] PRIMARY KEY CLUSTERED ([mat_codigo] ASC, [cur_codigo] ASC)
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'dbo' AND t.name = 'matricula_curso_historico')
BEGIN
    CREATE TABLE [dbo].[matricula_curso_historico](
        [mat_codigo] [int] NOT NULL,
        [cur_codigo] [int] NOT NULL,
        [est_codigo] [char](11) NOT NULL,
        [mac_nota_definitiva] [decimal](3,1) NULL,
        [mac_estado] [tinyint] NOT NULL CONSTRAINT [DF_matricula_curso_historico_mac_estado] DEFAULT (1),
        [per_codigo] [int] NULL,
        CONSTRAINT [PK_matricula_curso_historico] PRIMARY KEY CLUSTERED ([mat_codigo] ASC, [cur_codigo] ASC)
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'dbo' AND t.name = 'matricula_multicurso')
BEGIN
    CREATE TABLE [dbo].[matricula_multicurso](
        [mat_codigo] [int] NOT NULL,
        [cur_codigo] [int] NOT NULL,
        [est_codigo] [char](11) NOT NULL,
        [mac_nota_definitiva] [decimal](3,1) NULL,
        [mac_estado] [tinyint] NOT NULL CONSTRAINT [DF_matricula_multicurso_mac_estado] DEFAULT (1),
        [per_codigo] [int] NULL,
        CONSTRAINT [PK_matricula_multicurso] PRIMARY KEY CLUSTERED ([mat_codigo] ASC, [cur_codigo] ASC)
    );
END
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[resumen_docencia_sem] (Carga docente semestral)
-- ----------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'dbo' AND t.name = 'resumen_docencia_sem')
BEGIN
    CREATE TABLE [dbo].[resumen_docencia_sem](
        [rds_codigo] [int] IDENTITY(1,1) NOT NULL,
        [per_codigo] [int] NOT NULL,
        [uap_codigo] [int] NOT NULL,
        [cur_codigo] [int] NULL,
        [rds_horas] [decimal](5,2) NOT NULL,
        [rds_estado] [tinyint] NOT NULL CONSTRAINT [DF_resumen_docencia_sem_rds_estado] DEFAULT (1),
        CONSTRAINT [PK_resumen_docencia_sem] PRIMARY KEY CLUSTERED ([rds_codigo] ASC)
    );
END
GO

-- ----------------------------------------------------------------------------
-- TABLA: [dbo].[matricula_forma] (Formas de matrícula para notas_total)
-- ----------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'dbo' AND t.name = 'matricula_forma')
BEGIN
    CREATE TABLE [dbo].[matricula_forma](
        [maf_codigo] [smallint] IDENTITY(1,1) NOT NULL,
        [maf_nombre] [varchar](50) NOT NULL,
        [maf_estado] [tinyint] NOT NULL CONSTRAINT [DF_matricula_forma_maf_estado] DEFAULT (1),
        CONSTRAINT [PK_matricula_forma] PRIMARY KEY CLUSTERED ([maf_codigo] ASC)
    );
END
GO

-- ----------------------------------------------------------------------------
-- TABLAS MAESTRAS EXTERNAS REFERENCIADAS POR CLAVES FORÁNEAS EN DBO
-- ----------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'dbo' AND t.name = 'pais')
BEGIN
    CREATE TABLE [dbo].[pais](
        [pai_codigo] [smallint] NOT NULL,
        [pai_nombre] [varchar](100) NOT NULL,
        CONSTRAINT [PK_pais] PRIMARY KEY CLUSTERED ([pai_codigo] ASC)
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'dbo' AND t.name = 'horario')
BEGIN
    CREATE TABLE [dbo].[horario](
        [hor_codigo] [smallint] NOT NULL,
        [hor_nombre] [varchar](50) NOT NULL,
        CONSTRAINT [PK_horario] PRIMARY KEY CLUSTERED ([hor_codigo] ASC)
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'dbo' AND t.name = 'ocupacion_tipo')
BEGIN
    CREATE TABLE [dbo].[ocupacion_tipo](
        [oct_codigo] [smallint] NOT NULL,
        [oct_nombre] [varchar](50) NOT NULL,
        CONSTRAINT [PK_ocupacion_tipo] PRIMARY KEY CLUSTERED ([oct_codigo] ASC)
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'dbo' AND t.name = 'matricula_tipo')
BEGIN
    CREATE TABLE [dbo].[matricula_tipo](
        [mat_tipo_codigo] [smallint] NOT NULL,
        [mat_tipo_nombre] [varchar](50) NOT NULL,
        CONSTRAINT [PK_matricula_tipo] PRIMARY KEY CLUSTERED ([mat_tipo_codigo] ASC)
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'dbo' AND t.name = 'nivel_academico_tipo')
BEGIN
    CREATE TABLE [dbo].[nivel_academico_tipo](
        [nat_codigo] [smallint] NOT NULL,
        [nat_nombre] [varchar](50) NOT NULL,
        CONSTRAINT [PK_nivel_academico_tipo] PRIMARY KEY CLUSTERED ([nat_codigo] ASC)
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'dbo' AND t.name = 'novedad_tipo')
BEGIN
    CREATE TABLE [dbo].[novedad_tipo](
        [not_codigo] [smallint] NOT NULL,
        [not_nombre] [varchar](50) NOT NULL,
        CONSTRAINT [PK_novedad_tipo] PRIMARY KEY CLUSTERED ([not_codigo] ASC)
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'dbo' AND t.name = 'periodo_tipo')
BEGIN
    CREATE TABLE [dbo].[periodo_tipo](
        [pet_codigo] [smallint] NOT NULL,
        [pet_nombre] [varchar](50) NOT NULL,
        CONSTRAINT [PK_periodo_tipo] PRIMARY KEY CLUSTERED ([pet_codigo] ASC)
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'dbo' AND t.name = 'proyecto_rol')
BEGIN
    CREATE TABLE [dbo].[proyecto_rol](
        [pyr_codigo] [smallint] NOT NULL,
        [pyr_nombre] [varchar](50) NOT NULL,
        CONSTRAINT [PK_proyecto_rol] PRIMARY KEY CLUSTERED ([pyr_codigo] ASC)
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'dbo' AND t.name = 'nivel_academico_creditos')
BEGIN
    CREATE TABLE [dbo].[nivel_academico_creditos](
        [nac_codigo] [smallint] NOT NULL,
        [nac_nombre] [varchar](50) NOT NULL,
        CONSTRAINT [PK_nivel_academico_creditos] PRIMARY KEY CLUSTERED ([nac_codigo] ASC)
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'dbo' AND t.name = 'proyecto_estado')
BEGIN
    CREATE TABLE [dbo].[proyecto_estado](
        [pye_codigo] [smallint] NOT NULL,
        [pye_nombre] [varchar](50) NOT NULL,
        CONSTRAINT [PK_proyecto_estado] PRIMARY KEY CLUSTERED ([pye_codigo] ASC)
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'acreditacion' AND t.name = 'campo_detallado')
BEGIN
    CREATE TABLE [acreditacion].[campo_detallado](
        [cam_det_codigo] [int] NOT NULL,
        [cam_det_nombre] [varchar](150) NOT NULL,
        CONSTRAINT [PK_acreditacion_campo_detallado] PRIMARY KEY CLUSTERED ([cam_det_codigo] ASC)
    );
END
GO
