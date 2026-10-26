USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[novedad] Fecha de script: 26/10/2026 9:56:31 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

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
 CONSTRAINT [PK_novedad] PRIMARY KEY CLUSTERED 
(
	[nov_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[novedad] ADD  CONSTRAINT [DF_novedad_nov_activa]  DEFAULT ('A') FOR [nov_activa]
GO

ALTER TABLE [dbo].[novedad] ADD  CONSTRAINT [DF_novedad_nov_valida]  DEFAULT ((1)) FOR [nov_valida]
GO

ALTER TABLE [dbo].[novedad] ADD  CONSTRAINT [DF_novedad_nov_usar]  DEFAULT ((1)) FOR [nov_usar]
GO

ALTER TABLE [dbo].[novedad]  WITH NOCHECK ADD  CONSTRAINT [FK_novedad_novedad_tipo] FOREIGN KEY([not_codigo])
REFERENCES [dbo].[novedad_tipo] ([not_codigo])
GO

ALTER TABLE [dbo].[novedad] CHECK CONSTRAINT [FK_novedad_novedad_tipo]
GO


