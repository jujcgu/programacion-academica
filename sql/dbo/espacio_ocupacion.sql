USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[espacio_ocupacion] Fecha de script: 26/10/2026 9:35:05 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

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
	[usu_clave] [varchar](50) NULL,
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
 CONSTRAINT [PK_espacio_ocupacion] PRIMARY KEY CLUSTERED 
(
	[eso_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[espacio_ocupacion]  WITH NOCHECK ADD  CONSTRAINT [FK_espacio_ocupacion_curso] FOREIGN KEY([eso_actividad])
REFERENCES [dbo].[curso] ([cur_codigo])
GO

ALTER TABLE [dbo].[espacio_ocupacion] CHECK CONSTRAINT [FK_espacio_ocupacion_curso]
GO

ALTER TABLE [dbo].[espacio_ocupacion]  WITH CHECK ADD  CONSTRAINT [FK_espacio_ocupacion_espacio] FOREIGN KEY([esp_codigo])
REFERENCES [dbo].[espacio] ([esp_codigo])
GO

ALTER TABLE [dbo].[espacio_ocupacion] CHECK CONSTRAINT [FK_espacio_ocupacion_espacio]
GO

ALTER TABLE [dbo].[espacio_ocupacion]  WITH CHECK ADD  CONSTRAINT [FK_espacio_ocupacion_hora1] FOREIGN KEY([hra_codigo])
REFERENCES [dbo].[hora] ([hra_codigo])
GO

ALTER TABLE [dbo].[espacio_ocupacion] CHECK CONSTRAINT [FK_espacio_ocupacion_hora1]
GO

ALTER TABLE [dbo].[espacio_ocupacion]  WITH CHECK ADD  CONSTRAINT [FK_espacio_ocupacion_horario1] FOREIGN KEY([hor_codigo])
REFERENCES [dbo].[horario] ([hor_codigo])
GO

ALTER TABLE [dbo].[espacio_ocupacion] CHECK CONSTRAINT [FK_espacio_ocupacion_horario1]
GO

ALTER TABLE [dbo].[espacio_ocupacion]  WITH CHECK ADD  CONSTRAINT [FK_espacio_ocupacion_ocupacion_tipo] FOREIGN KEY([oct_codigo])
REFERENCES [dbo].[ocupacion_tipo] ([oct_codigo])
GO

ALTER TABLE [dbo].[espacio_ocupacion] CHECK CONSTRAINT [FK_espacio_ocupacion_ocupacion_tipo]
GO

ALTER TABLE [dbo].[espacio_ocupacion]  WITH NOCHECK ADD  CONSTRAINT [FK_espacio_ocupacion_uaa_agosto2018] FOREIGN KEY([uaa_codigo])
REFERENCES [dbo].[uaa] ([uaa_codigo])
GO

ALTER TABLE [dbo].[espacio_ocupacion] CHECK CONSTRAINT [FK_espacio_ocupacion_uaa_agosto2018]
GO


