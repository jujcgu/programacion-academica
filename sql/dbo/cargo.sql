USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[cargo] Fecha de script: 26/10/2026 9:24:53 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[cargo](
	[car_codigo] [int] IDENTITY(0,1) NOT FOR REPLICATION NOT NULL,
	[car_nombre] [varchar](50) NOT NULL,
	[car_id] [varchar](4) NULL,
	[car_tmp] [int] NULL,
	[car_jefe] [int] NULL,
	[car_estado] [int] NULL,
 CONSTRAINT [PK_cargo] PRIMARY KEY CLUSTERED 
(
	[car_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO


