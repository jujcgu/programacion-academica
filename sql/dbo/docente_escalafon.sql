USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[docente_escalafon] Fecha de script: 26/10/2026 9:30:38 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

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
 CONSTRAINT [PK_docente_escalafon] PRIMARY KEY CLUSTERED 
(
	[doe_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[docente_escalafon]  WITH NOCHECK ADD  CONSTRAINT [FK_docente_escalafon_escalafon] FOREIGN KEY([esc_codigo])
REFERENCES [dbo].[escalafon] ([esc_codigo])
GO

ALTER TABLE [dbo].[docente_escalafon] CHECK CONSTRAINT [FK_docente_escalafon_escalafon]
GO

ALTER TABLE [dbo].[docente_escalafon]  WITH NOCHECK ADD  CONSTRAINT [FK_docente_escalafon_persona] FOREIGN KEY([per_codigo])
REFERENCES [dbo].[persona] ([per_codigo])
GO

ALTER TABLE [dbo].[docente_escalafon] CHECK CONSTRAINT [FK_docente_escalafon_persona]
GO


