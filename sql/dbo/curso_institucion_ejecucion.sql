USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[curso_institucion_ejecucion] Fecha de script: 26/10/2026 9:27:01 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[curso_institucion_ejecucion](
	[cie_codigo] [int] IDENTITY(1,1) NOT NULL,
	[cur_codigo] [int] NULL,
	[cie_subgrupo] [char](2) NULL,
	[esp_codigo] [int] NULL,
	[mun_codigo] [int] NULL,
	[cie_estado] [int] NULL,
	[cie_uid_inserta] [int] NULL,
	[cie_fecha_inserta] [datetime] NULL,
	[cie_uid_modifica] [int] NULL,
	[cie_fecha_modifica] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[cie_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[curso_institucion_ejecucion]  WITH CHECK ADD FOREIGN KEY([cur_codigo])
REFERENCES [dbo].[curso] ([cur_codigo])
GO

ALTER TABLE [dbo].[curso_institucion_ejecucion]  WITH CHECK ADD  CONSTRAINT [FK__curso_ins__esp_c__44EEF70B] FOREIGN KEY([esp_codigo])
REFERENCES [dbo].[espacio] ([esp_codigo])
GO

ALTER TABLE [dbo].[curso_institucion_ejecucion] CHECK CONSTRAINT [FK__curso_ins__esp_c__44EEF70B]
GO

ALTER TABLE [dbo].[curso_institucion_ejecucion]  WITH CHECK ADD FOREIGN KEY([mun_codigo])
REFERENCES [dbo].[municipio] ([mun_codigo])
GO


