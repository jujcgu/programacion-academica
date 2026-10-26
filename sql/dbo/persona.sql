USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[persona] Fecha de script: 26/10/2026 9:58:40 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

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
 CONSTRAINT [PK_persona] PRIMARY KEY NONCLUSTERED 
(
	[per_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[persona] ADD  CONSTRAINT [DF_persona_per_lugar_expedicion]  DEFAULT ((1124)) FOR [per_lugar_expedicion]
GO

ALTER TABLE [dbo].[persona] ADD  CONSTRAINT [DF_persona_per_lugar_nacimiento]  DEFAULT ((1124)) FOR [per_lugar_nacimiento]
GO

ALTER TABLE [dbo].[persona] ADD  CONSTRAINT [DF_persona_per_lugar_residencia]  DEFAULT ((1124)) FOR [per_lugar_residencia]
GO

ALTER TABLE [dbo].[persona] ADD  CONSTRAINT [DF_persona_per_pais_residencia]  DEFAULT ((21)) FOR [per_pais_residencia]
GO

ALTER TABLE [dbo].[persona] ADD  CONSTRAINT [DF_persona_per_estado]  DEFAULT ((1)) FOR [per_estado]
GO

ALTER TABLE [dbo].[persona] ADD  CONSTRAINT [DF_persona_per_fecha_registro]  DEFAULT (getdate()) FOR [per_fecha_registro]
GO

ALTER TABLE [dbo].[persona] ADD  CONSTRAINT [DF_persona_per_fecha_actualizacion]  DEFAULT (getdate()) FOR [per_fecha_actualizacion]
GO


