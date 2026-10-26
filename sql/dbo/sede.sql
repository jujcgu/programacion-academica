USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[sede] Fecha de script: 26/10/2026 10:05:57 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[sede](
	[sed_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[sed_nombre] [varchar](50) NOT NULL,
	[mun_codigo] [int] NOT NULL,
	[sippa_sed_codigo] [int] NULL,
	[sed_estado] [varchar](1) NULL,
	[SedNombre_corto] [nchar](3) NULL,
	[sed_PDI] [int] NULL,
	[sed_dependencia] [int] NULL,
 CONSTRAINT [PK_sede] PRIMARY KEY NONCLUSTERED 
(
	[sed_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[sede] ADD  CONSTRAINT [DF_sede_sed_estado]  DEFAULT ((1)) FOR [sed_estado]
GO

ALTER TABLE [dbo].[sede]  WITH CHECK ADD  CONSTRAINT [FK_sede_municipio] FOREIGN KEY([mun_codigo])
REFERENCES [dbo].[municipio] ([mun_codigo])
GO

ALTER TABLE [dbo].[sede] CHECK CONSTRAINT [FK_sede_municipio]
GO


