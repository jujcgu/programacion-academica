USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[persona_proyecto] Fecha de script: 26/10/2026 9:59:40 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

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
 CONSTRAINT [PK_proyecto_persona] PRIMARY KEY NONCLUSTERED 
(
	[pep_codigo] ASC,
	[pry_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[persona_proyecto]  WITH NOCHECK ADD  CONSTRAINT [FK_persona_proyecto_persona] FOREIGN KEY([pep_persona])
REFERENCES [dbo].[persona] ([per_codigo])
GO

ALTER TABLE [dbo].[persona_proyecto] CHECK CONSTRAINT [FK_persona_proyecto_persona]
GO

ALTER TABLE [dbo].[persona_proyecto]  WITH CHECK ADD  CONSTRAINT [FK_persona_proyecto_proyecto_rol] FOREIGN KEY([prr_codigo])
REFERENCES [dbo].[proyecto_rol] ([prr_codigo])
GO

ALTER TABLE [dbo].[persona_proyecto] CHECK CONSTRAINT [FK_persona_proyecto_proyecto_rol]
GO

ALTER TABLE [dbo].[persona_proyecto]  WITH NOCHECK ADD  CONSTRAINT [FK_proyecto_persona_proyecto] FOREIGN KEY([pry_codigo])
REFERENCES [dbo].[proyecto] ([pry_codigo])
GO

ALTER TABLE [dbo].[persona_proyecto] CHECK CONSTRAINT [FK_proyecto_persona_proyecto]
GO


