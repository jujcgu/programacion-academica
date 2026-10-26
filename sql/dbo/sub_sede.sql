USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[sub_sede] Fecha de script: 26/10/2026 10:06:27 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[sub_sede](
	[sus_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[sus_nombre] [varchar](50) NOT NULL,
	[sed_codigo] [int] NOT NULL,
	[sus_direccion] [varchar](50) NULL,
	[sus_telefono] [char](20) NULL,
	[sippa_sedcodigo] [char](2) NULL,
	[sus_estado] [int] NULL,
 CONSTRAINT [PK_sub_sede_1] PRIMARY KEY NONCLUSTERED 
(
	[sus_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[sub_sede] ADD  CONSTRAINT [DF_sub_sede_sus_estado]  DEFAULT ((1)) FOR [sus_estado]
GO

ALTER TABLE [dbo].[sub_sede]  WITH CHECK ADD  CONSTRAINT [FK_sub_sede_sede] FOREIGN KEY([sed_codigo])
REFERENCES [dbo].[sede] ([sed_codigo])
GO

ALTER TABLE [dbo].[sub_sede] CHECK CONSTRAINT [FK_sub_sede_sede]
GO


