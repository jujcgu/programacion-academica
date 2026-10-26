USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[nivel_academico] Fecha de script: 26/10/2026 9:55:18 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[nivel_academico](
	[nia_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[nia_nombre] [varchar](50) NULL,
	[nia_orden] [tinyint] NULL,
	[for_codigo] [tinyint] NULL,
	[snies_codigo] [char](2) NULL,
	[sippa_nia_codigo] [int] NULL,
	[sippa_nivcodigo] [char](3) NULL,
	[nia_codigo_mp_hecaa] [int] NULL,
	[nia_codigo_ned_hecaa] [int] NULL,
	[nia_codigo_ne_hecaa] [int] NULL,
	[nat_codigo] [int] NULL,
	[nia_cap_puntos] [int] NULL,
	[nia_cap_puntos_adicionales] [int] NULL,
	[nia_cap_maximo] [int] NULL,
	[nia_cap_puntos_xano] [int] NULL,
	[nia_cap_descripcion] [int] NULL,
	[nia_estado] [varchar](1) NOT NULL,
	[nia_cap_estado] [int] NULL,
 CONSTRAINT [PK_nivel_academico] PRIMARY KEY CLUSTERED 
(
	[nia_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[nivel_academico] ADD  CONSTRAINT [DF_nivel_academico_nia_estado]  DEFAULT ((1)) FOR [nia_estado]
GO

ALTER TABLE [dbo].[nivel_academico]  WITH CHECK ADD  CONSTRAINT [FK_nivel_academico_nivel_academico_tipo] FOREIGN KEY([nat_codigo])
REFERENCES [dbo].[nivel_academico_tipo] ([nat_codigo])
GO

ALTER TABLE [dbo].[nivel_academico] CHECK CONSTRAINT [FK_nivel_academico_nivel_academico_tipo]
GO


