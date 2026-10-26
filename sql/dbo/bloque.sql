USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[bloque] Fecha de script: 26/10/2026 9:19:57 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[bloque](
	[blo_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[blo_nombre] [varchar](50) NOT NULL,
	[sus_codigo] [int] NOT NULL,
	[sippa_blocodigo] [char](4) NULL,
	[blo_latitud] [varchar](50) NULL,
	[blo_longitud] [varchar](50) NULL,
	[blo_estado] [int] NULL,
 CONSTRAINT [PK_bloque] PRIMARY KEY CLUSTERED 
(
	[blo_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[bloque] ADD  CONSTRAINT [DF_bloque_blo_estado]  DEFAULT ((1)) FOR [blo_estado]
GO

ALTER TABLE [dbo].[bloque]  WITH NOCHECK ADD  CONSTRAINT [FK_bloque_sub_sede] FOREIGN KEY([sus_codigo])
REFERENCES [dbo].[sub_sede] ([sus_codigo])
GO

ALTER TABLE [dbo].[bloque] CHECK CONSTRAINT [FK_bloque_sub_sede]
GO


