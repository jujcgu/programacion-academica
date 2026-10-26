USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [programacionacademica].[grupo_uaa_item] Fecha de script: 26/10/2026 8:28:19 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [programacionacademica].[grupo_uaa_item](
	[gui_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[pgr_codigo] [int] NOT NULL,
	[uaa_codigo] [int] NOT NULL,
	[gui_estado] [int] NOT NULL,
 CONSTRAINT [PK_gui_codigo] PRIMARY KEY NONCLUSTERED 
(
	[gui_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [programacionacademica].[grupo_uaa_item]  WITH CHECK ADD  CONSTRAINT [FK_pgr_codigo] FOREIGN KEY([pgr_codigo])
REFERENCES [programacionacademica].[grupo_uaa] ([pgr_codigo])
GO

ALTER TABLE [programacionacademica].[grupo_uaa_item] CHECK CONSTRAINT [FK_pgr_codigo]
GO

ALTER TABLE [programacionacademica].[grupo_uaa_item]  WITH CHECK ADD  CONSTRAINT [FK_uaa_codigo] FOREIGN KEY([uaa_codigo])
REFERENCES [dbo].[uaa] ([uaa_codigo])
GO

ALTER TABLE [programacionacademica].[grupo_uaa_item] CHECK CONSTRAINT [FK_uaa_codigo]
GO


