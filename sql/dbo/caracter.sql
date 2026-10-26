USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[caracter] Fecha de script: 26/10/2026 9:24:22 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[caracter](
	[car_codigo] [char](2) NOT NULL,
	[car_nombre] [varchar](25) NULL,
	[car_estado] [varchar](1) NULL,
 CONSTRAINT [PK_caracter] PRIMARY KEY CLUSTERED 
(
	[car_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[caracter] ADD  DEFAULT ((1)) FOR [car_estado]
GO


