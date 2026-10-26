USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[curso_cupo_subgrupo] Fecha de script: 26/10/2026 9:26:39 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[curso_cupo_subgrupo](
	[cus_cod] [int] IDENTITY(1,1) NOT NULL,
	[cur_codigo] [int] NULL,
	[eso_subgrupo] [varchar](2) NULL,
	[cus_cupo] [int] NULL,
	[cus_estado] [int] NULL,
	[cus_fecha_registro] [datetime] NULL,
 CONSTRAINT [PK_curso_cupo_subgrupo] PRIMARY KEY CLUSTERED 
(
	[cus_cod] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[curso_cupo_subgrupo] ADD  CONSTRAINT [DF_curso_cupo_subgrupo_cus_estado]  DEFAULT ((1)) FOR [cus_estado]
GO

ALTER TABLE [dbo].[curso_cupo_subgrupo] ADD  CONSTRAINT [DF_curso_cupo_subgrupo_cus_fecha_registro]  DEFAULT (getdate()) FOR [cus_fecha_registro]
GO


