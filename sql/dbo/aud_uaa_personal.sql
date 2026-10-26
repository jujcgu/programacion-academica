USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[aud_uaa_personal] Fecha de script: 26/10/2026 9:19:29 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

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
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[aud_uaa_personal] ADD  CONSTRAINT [DF_aud_uaa_personal_sys_user]  DEFAULT (((('system_user:('+suser_sname())+'), user:(')+user_name())+')') FOR [sys_user]
GO

ALTER TABLE [dbo].[aud_uaa_personal] ADD  CONSTRAINT [DF_aud_uaa_personal_aud_fecha]  DEFAULT (getdate()) FOR [aud_fecha]
GO

ALTER TABLE [dbo].[aud_uaa_personal] ADD  CONSTRAINT [DF_aud_uaa_personal_aud_host]  DEFAULT (host_name()) FOR [aud_host]
GO


