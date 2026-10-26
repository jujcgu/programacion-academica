USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[matricula] Fecha de script: 26/10/2026 9:51:09 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[matricula](
	[mat_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[est_codigo] [char](11) NOT NULL,
	[cal_codigo] [int] NOT NULL,
	[mat_fecha] [datetime] NOT NULL,
	[mat_problema] [varchar](500) NULL,
	[mat_observacion] [varchar](300) NULL,
	[mat_estado] [char](1) NULL,
	[ese_codigo] [smallint] NULL,
	[mat_tipo] [tinyint] NULL,
	[mat_usuario] [int] NULL,
	[mat_clave] [varchar](80) NULL,
	[mat_cliente] [varchar](50) NULL,
	[mat_ip] [varchar](150) NULL,
	[sippa_calcodigo] [char](7) NULL,
	[mat_fecha_actualizacion] [datetime] NULL,
 CONSTRAINT [PK_matricula] PRIMARY KEY NONCLUSTERED 
(
	[mat_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[matricula] ADD  CONSTRAINT [DF_matricula_mat_fecha]  DEFAULT (getdate()) FOR [mat_fecha]
GO

ALTER TABLE [dbo].[matricula] ADD  CONSTRAINT [DF_matricula_mat_estado]  DEFAULT ('A') FOR [mat_estado]
GO

ALTER TABLE [dbo].[matricula] ADD  CONSTRAINT [DF_matricula_mat_tipo]  DEFAULT ((1)) FOR [mat_tipo]
GO

ALTER TABLE [dbo].[matricula] ADD  CONSTRAINT [DF_matricula_mat_fecha_actualizacion]  DEFAULT (getdate()) FOR [mat_fecha_actualizacion]
GO

ALTER TABLE [dbo].[matricula]  WITH CHECK ADD  CONSTRAINT [FK_matricula_calendario] FOREIGN KEY([cal_codigo])
REFERENCES [dbo].[calendario] ([cal_codigo])
GO

ALTER TABLE [dbo].[matricula] CHECK CONSTRAINT [FK_matricula_calendario]
GO

ALTER TABLE [dbo].[matricula]  WITH NOCHECK ADD  CONSTRAINT [FK_matricula_estudiante_agosto2018] FOREIGN KEY([est_codigo])
REFERENCES [dbo].[estudiante] ([est_codigo])
GO

ALTER TABLE [dbo].[matricula] CHECK CONSTRAINT [FK_matricula_estudiante_agosto2018]
GO

ALTER TABLE [dbo].[matricula]  WITH NOCHECK ADD  CONSTRAINT [FK_matricula_matricula_tipo_agosto2018] FOREIGN KEY([mat_tipo])
REFERENCES [dbo].[matricula_tipo] ([mti_codigo])
GO

ALTER TABLE [dbo].[matricula] CHECK CONSTRAINT [FK_matricula_matricula_tipo_agosto2018]
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'parametro para identificar los estudiantes que quedan o no en el acuerdo 046' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'matricula', @level2type=N'COLUMN',@level2name=N'ese_codigo'
GO


