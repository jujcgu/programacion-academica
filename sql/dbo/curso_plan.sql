USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[curso_plan] Fecha de script: 26/10/2026 9:27:18 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[curso_plan](
	[cup_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[cur_codigo] [int] NULL,
	[pla_codigo] [int] NULL,
	[sippa_plancodigo] [char](7) NULL,
 CONSTRAINT [PK_curso_plan_1] PRIMARY KEY CLUSTERED 
(
	[cup_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[curso_plan]  WITH CHECK ADD  CONSTRAINT [FK_curso_plan_curso] FOREIGN KEY([cur_codigo])
REFERENCES [dbo].[curso] ([cur_codigo])
GO

ALTER TABLE [dbo].[curso_plan] CHECK CONSTRAINT [FK_curso_plan_curso]
GO


