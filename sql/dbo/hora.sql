USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[hora] Fecha de script: 26/10/2026 9:50:37 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[hora](
	[hra_codigo] [int] NOT NULL,
	[hra_nombre] [varchar](50) NOT NULL,
	[hra_inicio] [char](7) NOT NULL,
	[hra_fin] [char](10) NOT NULL,
	[hra_inicio_24h] [char](5) NULL,
	[hra_fin_24h] [char](5) NULL,
 CONSTRAINT [PK_hora] PRIMARY KEY NONCLUSTERED 
(
	[hra_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[hora]  WITH CHECK ADD  CONSTRAINT [FK_hora_horario] FOREIGN KEY([hra_codigo])
REFERENCES [dbo].[horario] ([hor_codigo])
GO

ALTER TABLE [dbo].[hora] CHECK CONSTRAINT [FK_hora_horario]
GO


