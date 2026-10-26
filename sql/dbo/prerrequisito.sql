USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[prerrequisito] Fecha de script: 26/10/2026 9:05:35 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[prerrequisito](
	[pre_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[pla_codigo] [int] NULL,
	[asi_codigo] [int] NULL,
	[asi_requisito] [int] NULL,
	[pre_creditos] [int] NULL,
	[pre_codigos] [varchar](20) NULL,
	[sippa_plancodigo] [char](7) NULL,
	[sippa_asicodigo] [char](8) NULL,
	[sippa_preasignatura] [char](8) NULL,
 CONSTRAINT [PK_prerequisito] PRIMARY KEY NONCLUSTERED 
(
	[pre_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO


