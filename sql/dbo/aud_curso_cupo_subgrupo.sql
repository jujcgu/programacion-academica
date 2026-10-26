USE [academia3000_sergiomartinez]
GO

/****** Objeto: Table [dbo].[aud_curso_cupo_subgrupo] Fecha de script: 26/10/2026 9:17:53 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[aud_curso_cupo_subgrupo](
	[aud_cus_cod] [int] IDENTITY(1,1) NOT NULL,
	[aud_log_type] [char](6) NOT NULL,
	[cus_cod] [int] NOT NULL,
	[cur_codigo] [int] NULL,
	[eso_subgrupo] [varchar](2) NULL,
	[cus_cupo] [int] NULL,
	[cus_estado] [int] NULL,
	[cus_fecha_registro] [datetime] NULL,
	[aud_user] [nvarchar](128) NOT NULL,
	[aud_changed] [datetime] NOT NULL,
	[aud_host] [varchar](200) NOT NULL,
	[aud_ip] [varchar](50) NOT NULL,
 CONSTRAINT [PK_aud_curso_cupo_subgrupo] PRIMARY KEY CLUSTERED 
(
	[aud_cus_cod] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[aud_curso_cupo_subgrupo] ADD  CONSTRAINT [DF_aud_curso_cupo_subgrupo_aud_user]  DEFAULT (suser_sname()) FOR [aud_user]
GO

ALTER TABLE [dbo].[aud_curso_cupo_subgrupo] ADD  CONSTRAINT [DF_aud_curso_cupo_subgrupo_aud_changed]  DEFAULT (getdate()) FOR [aud_changed]
GO

ALTER TABLE [dbo].[aud_curso_cupo_subgrupo] ADD  CONSTRAINT [DF_aud_curso_cupo_subgrupo_aud_host]  DEFAULT (host_name()) FOR [aud_host]
GO

ALTER TABLE [dbo].[aud_curso_cupo_subgrupo] ADD  CONSTRAINT [DF_aud_curso_cupo_subgrupo_aud_ip]  DEFAULT (CONVERT([varchar],connectionproperty('client_net_address'),(0))) FOR [aud_ip]
GO


