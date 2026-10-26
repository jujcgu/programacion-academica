USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[persona_novedad] Fecha de script: 26/10/2026 9:59:13 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

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
 CONSTRAINT [PK_persona_novedad] PRIMARY KEY CLUSTERED 
(
	[pen_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[persona_novedad]  WITH NOCHECK ADD  CONSTRAINT [FK_persona_novedad_novedad] FOREIGN KEY([nov_codigo])
REFERENCES [dbo].[novedad] ([nov_codigo])
GO

ALTER TABLE [dbo].[persona_novedad] CHECK CONSTRAINT [FK_persona_novedad_novedad]
GO

ALTER TABLE [dbo].[persona_novedad]  WITH NOCHECK ADD  CONSTRAINT [FK_persona_novedad_persona] FOREIGN KEY([pen_persona])
REFERENCES [dbo].[persona] ([per_codigo])
GO

ALTER TABLE [dbo].[persona_novedad] CHECK CONSTRAINT [FK_persona_novedad_persona]
GO

ALTER TABLE [dbo].[persona_novedad]  WITH NOCHECK ADD  CONSTRAINT [FK_persona_novedad_uaa_personal] FOREIGN KEY([uap_codigo])
REFERENCES [dbo].[uaa_personal] ([uap_codigo])
GO

ALTER TABLE [dbo].[persona_novedad] CHECK CONSTRAINT [FK_persona_novedad_uaa_personal]
GO


