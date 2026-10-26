USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[uaa_cargo] Fecha de script: 26/10/2026 10:08:23 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[uaa_cargo](
	[uac_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[uac_uaa] [int] NULL,
	[uac_cargo] [int] NULL,
	[uac_vinculacion] [int] NULL,
	[uac_dedicacion] [int] NULL,
	[uac_codigoplanta] [nvarchar](4) NULL,
	[uac_grado] [int] NULL,
	[uac_estado] [int] NULL,
 CONSTRAINT [PK_uaa_cargo] PRIMARY KEY CLUSTERED 
(
	[uac_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[uaa_cargo] ADD  CONSTRAINT [DF_uaa_cargo_uac_estado]  DEFAULT ((1)) FOR [uac_estado]
GO

ALTER TABLE [dbo].[uaa_cargo]  WITH CHECK ADD  CONSTRAINT [FK_uaa_cargo_dedicacion] FOREIGN KEY([uac_dedicacion])
REFERENCES [dbo].[dedicacion] ([ded_codigo])
GO

ALTER TABLE [dbo].[uaa_cargo] CHECK CONSTRAINT [FK_uaa_cargo_dedicacion]
GO

ALTER TABLE [dbo].[uaa_cargo]  WITH CHECK ADD  CONSTRAINT [FK_uaa_cargo_uaa] FOREIGN KEY([uac_uaa])
REFERENCES [dbo].[uaa] ([uaa_codigo])
GO

ALTER TABLE [dbo].[uaa_cargo] CHECK CONSTRAINT [FK_uaa_cargo_uaa]
GO

ALTER TABLE [dbo].[uaa_cargo]  WITH CHECK ADD  CONSTRAINT [FK_uaa_cargo_vinculacion] FOREIGN KEY([uac_vinculacion])
REFERENCES [dbo].[vinculacion] ([vin_codigo])
GO

ALTER TABLE [dbo].[uaa_cargo] CHECK CONSTRAINT [FK_uaa_cargo_vinculacion]
GO


