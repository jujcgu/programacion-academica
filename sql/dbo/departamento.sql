USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[departamento] Fecha de script: 26/10/2026 9:29:19 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[departamento](
	[dep_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[dep_acronimo] [char](2) NULL,
	[dep_nombre] [varchar](100) NOT NULL,
	[pai_codigo] [int] NOT NULL,
	[sippa_dep_codigo] [int] NULL,
	[dane_codigo] [char](10) NULL,
 CONSTRAINT [PK_departamento_1] PRIMARY KEY CLUSTERED 
(
	[dep_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[departamento]  WITH CHECK ADD  CONSTRAINT [FK_departamento_pais] FOREIGN KEY([pai_codigo])
REFERENCES [dbo].[pais] ([pai_codigo])
GO

ALTER TABLE [dbo].[departamento] CHECK CONSTRAINT [FK_departamento_pais]
GO


