USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[plan_estudiante] Fecha de script: 26/10/2026 10:00:57 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[plan_estudiante](
	[ple_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[est_codigo] [char](11) NULL,
	[pla_codigo] [int] NULL,
	[ple_estado] [bit] NULL,
	[res_codigo] [int] NULL,
	[ple_observacion] [varchar](200) NULL,
	[sippa_placodigo] [char](7) NULL,
	[sippa_procodigo] [char](4) NULL,
	[ple_fecha_registro] [datetime] NULL,
 CONSTRAINT [PK_plan_estudiante] PRIMARY KEY CLUSTERED 
(
	[ple_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[plan_estudiante] ADD  CONSTRAINT [DF_plan_estudiante_ple_fecha_registro]  DEFAULT (getdate()) FOR [ple_fecha_registro]
GO

ALTER TABLE [dbo].[plan_estudiante]  WITH CHECK ADD  CONSTRAINT [FK_plan_estudiante_estudiante] FOREIGN KEY([est_codigo])
REFERENCES [dbo].[estudiante] ([est_codigo])
GO

ALTER TABLE [dbo].[plan_estudiante] CHECK CONSTRAINT [FK_plan_estudiante_estudiante]
GO

ALTER TABLE [dbo].[plan_estudiante]  WITH NOCHECK ADD  CONSTRAINT [FK_plan_estudiante_plan_academico] FOREIGN KEY([pla_codigo])
REFERENCES [dbo].[plan_academico] ([pla_codigo])
GO

ALTER TABLE [dbo].[plan_estudiante] CHECK CONSTRAINT [FK_plan_estudiante_plan_academico]
GO


