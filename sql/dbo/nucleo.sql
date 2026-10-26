USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[nucleo] Fecha de script: 26/10/2026 9:01:58 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[nucleo](
	[nuc_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[nuc_nombre] [char](25) NULL,
	[nuc_estado] [bit] NULL,
	[nuc_acronimo] [char](1) NULL,
 CONSTRAINT [PK_nucleo] PRIMARY KEY NONCLUSTERED 
(
	[nuc_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[nucleo] ADD  CONSTRAINT [DF_nucleo_nuc_estado]  DEFAULT (0) FOR [nuc_estado]
GO


