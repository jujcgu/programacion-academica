USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[estudiante] Fecha de script: 26/10/2026 9:48:45 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[estudiante](
	[est_codigo] [char](11) NOT NULL,
	[per_codigo] [int] NULL,
	[est_fecha_ingreso] [datetime] NOT NULL,
	[pro_codigo] [int] NULL,
	[ese_codigo] [tinyint] NOT NULL,
	[ins_codigo] [int] NOT NULL,
	[est_fecha_retiro] [datetime] NULL,
	[ese_codigo1] [tinyint] NULL,
	[ese_codigo2] [tinyint] NULL,
	[est_id_carnet] [varchar](45) NULL,
	[est_registro_egresado] [int] NULL,
	[ter_codigo] [int] NULL,
	[est_uid] [int] NULL,
	[est_user] [char](50) NULL,
	[est_alterno] [int] NOT NULL,
 CONSTRAINT [PK_estudiante] PRIMARY KEY NONCLUSTERED 
(
	[est_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[estudiante] ADD  CONSTRAINT [DF_estudiante_est_registro_egresado]  DEFAULT ((0)) FOR [est_registro_egresado]
GO

ALTER TABLE [dbo].[estudiante] ADD  CONSTRAINT [DF_estudiante_est_user]  DEFAULT (suser_sname()) FOR [est_user]
GO

ALTER TABLE [dbo].[estudiante] ADD  CONSTRAINT [DF_estudiante_est_alterno]  DEFAULT ((0)) FOR [est_alterno]
GO

ALTER TABLE [dbo].[estudiante]  WITH NOCHECK ADD  CONSTRAINT [FK_estudiante_persona_agosto2018] FOREIGN KEY([per_codigo])
REFERENCES [dbo].[persona] ([per_codigo])
GO

ALTER TABLE [dbo].[estudiante] CHECK CONSTRAINT [FK_estudiante_persona_agosto2018]
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'parametro para identificar los estudiantes que quedan o no en el acuerdo 046' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'estudiante', @level2type=N'COLUMN',@level2name=N'ese_codigo'
GO


