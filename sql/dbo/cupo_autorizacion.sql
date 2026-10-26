USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[cupo_autorizacion] Fecha de script: 26/10/2026 9:25:25 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[cupo_autorizacion](
	[cua_codigo] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[cua_curso] [int] NOT NULL,
	[cua_grupo] [varchar](2) NOT NULL,
	[cua_subgrupo] [varchar](2) NOT NULL,
	[cua_estudiante] [char](11) NOT NULL,
	[cua_observacion] [varchar](max) NULL,
	[cua_fecha] [datetime] NULL,
 CONSTRAINT [PK_cupo_autorizacion] PRIMARY KEY CLUSTERED 
(
	[cua_codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[cupo_autorizacion] ADD  CONSTRAINT [DF_cupo_autorizacion_cua_fecha]  DEFAULT (getdate()) FOR [cua_fecha]
GO

ALTER TABLE [dbo].[cupo_autorizacion]  WITH CHECK ADD  CONSTRAINT [FK_cupo_autorizacion_curso] FOREIGN KEY([cua_curso])
REFERENCES [dbo].[curso] ([cur_codigo])
GO

ALTER TABLE [dbo].[cupo_autorizacion] CHECK CONSTRAINT [FK_cupo_autorizacion_curso]
GO


