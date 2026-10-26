USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[aud_espacio_ocupacion] Fecha de script: 26/10/2026 9:18:34 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

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
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[aud_espacio_ocupacion] ADD  CONSTRAINT [DF_aud_espacio_ocupacion_aud_user]  DEFAULT (suser_sname()) FOR [aud_user]
GO

ALTER TABLE [dbo].[aud_espacio_ocupacion] ADD  CONSTRAINT [DF_aud_espacio_ocupacion_aud_changed]  DEFAULT (getdate()) FOR [aud_changed]
GO

ALTER TABLE [dbo].[aud_espacio_ocupacion] ADD  CONSTRAINT [DF_aud_espacio_ocupacion_aud_host]  DEFAULT (host_name()) FOR [aud_host]
GO

ALTER TABLE [dbo].[aud_espacio_ocupacion] ADD  CONSTRAINT [DF_aud_espacio_ocupacion_sys_user]  DEFAULT (((('system_user:('+suser_sname())+'), user:(')+user_name())+')') FOR [sys_user]
GO

ALTER TABLE [dbo].[aud_espacio_ocupacion] ADD  CONSTRAINT [DF_aud_espacio_ocupacion_aud_ip]  DEFAULT (CONVERT([varchar],connectionproperty('client_net_address'),(0))) FOR [aud_ip]
GO


