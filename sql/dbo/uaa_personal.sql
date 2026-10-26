USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[uaa_personal] Fecha de script: 26/10/2026 10:09:01 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

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
 CONSTRAINT [PK_uaa_personal] PRIMARY KEY NONCLUSTERED 
(
	[uap_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[uaa_personal] ADD  CONSTRAINT [DF_uaa_personal_uap_estado]  DEFAULT ((1)) FOR [uap_estado]
GO

ALTER TABLE [dbo].[uaa_personal]  WITH NOCHECK ADD  CONSTRAINT [FK_uaa_personal_persona_agosto2018] FOREIGN KEY([per_codigo])
REFERENCES [dbo].[persona] ([per_codigo])
GO

ALTER TABLE [dbo].[uaa_personal] CHECK CONSTRAINT [FK_uaa_personal_persona_agosto2018]
GO

ALTER TABLE [dbo].[uaa_personal]  WITH NOCHECK ADD  CONSTRAINT [FK_uaa_personal_uaa_agosto2018] FOREIGN KEY([uaa_codigo])
REFERENCES [dbo].[uaa] ([uaa_codigo])
GO

ALTER TABLE [dbo].[uaa_personal] CHECK CONSTRAINT [FK_uaa_personal_uaa_agosto2018]
GO


