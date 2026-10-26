USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[uaa] Fecha de script: 26/10/2026 9:07:19 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[uaa](
	[uaa_codigo] [int] IDENTITY(1,1) NOT NULL,
	[uat_codigo] [int] NOT NULL,
	[uaa_nombre] [varchar](200) NOT NULL,
	[uaa_dependencia] [int] NULL,
	[uaa_nombre_corto] [varchar](200) NULL,
	[uaa_nombre_impresion] [varchar](20) NULL,
	[uaa_email] [varchar](50) NULL,
	[uaa_email_pqr] [varchar](50) NULL,
	[uaa_pagina] [varchar](50) NULL,
	[uaa_jefe] [varchar](50) NULL,
	[mun_codigo] [int] NULL,
	[uaa_telefono] [varchar](50) NULL,
	[uaa_fax] [varchar](50) NULL,
	[uaa_direccion] [varchar](50) NULL,
	[sippa_uaa_codigo] [int] NULL,
	[sed_codigo] [int] NULL,
	[uaa_centro_costos] [char](3) NULL,
	[uaa_acronimo] [char](7) NULL,
	[uaa_estado] [int] NULL,
	[uaa_ventanilla] [int] NULL,
	[uaa_codigo_retencion] [varchar](15) NULL,
	[uaa_propietario_codigo] [int] NULL,
	[uaa_jefe_per_codigo] [bigint] NULL,
 CONSTRAINT [PK_unidad_academica_administrativa] PRIMARY KEY NONCLUSTERED 
(
	[uaa_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[uaa] ADD  CONSTRAINT [DF_uaa_uaa_estado]  DEFAULT ((1)) FOR [uaa_estado]
GO

ALTER TABLE [dbo].[uaa]  WITH CHECK ADD  CONSTRAINT [FK_uaa_sede] FOREIGN KEY([sed_codigo])
REFERENCES [dbo].[sede] ([sed_codigo])
GO

ALTER TABLE [dbo].[uaa] CHECK CONSTRAINT [FK_uaa_sede]
GO


