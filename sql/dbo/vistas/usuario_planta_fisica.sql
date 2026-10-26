USE [academia3000_sergiomartinez]
GO

/****** Objeto: View [dbo].[usuario_planta_fisica] Fecha de script: 26/10/2026 10:10:29 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO








/* Vista que sirve para seleccionar los usuarios del sistema de duplicado de diploma. No incluye contrasenas. Creacion 14 febrero 2020 */
CREATE VIEW [dbo].[usuario_planta_fisica]
AS

--Esta parte consulta los usuarios administrativos
SELECT		dbo.usuario_grupo.usg_usuario,		dbo.grupo.gru_nombre, 
			dbo.usuario_grupo.usg_grupo,		dbo.grupo.gru_id, 
			dbo.usuario_grupo.usg_uaa,			dbo.usuario_grupo.usg_estado, 
			dbo.grupo.gru_codigo,				dbo.usuario_grupo.usg_codigo, 
			dbo.usuario_administrativos.up,		dbo.usuario_administrativos.us, 
			dbo.usuario_administrativos.istipo,	dbo.usuario_administrativos.ischange, 
			dbo.usuario_administrativos.state,	dbo.usuario_administrativos.sys, 
			dbo.usuario_administrativos.uid,	dbo.usuario_administrativos.us_encriptado
FROM		dbo.usuario_grupo 
INNER JOIN	dbo.grupo ON dbo.usuario_grupo.usg_grupo = dbo.grupo.gru_codigo 
INNER JOIN	dbo.usuario_administrativos ON dbo.usuario_grupo.usg_usuario = dbo.usuario_administrativos.uid
WHERE		(dbo.grupo.gru_codigo in (8,9,56,270,271,272,273,274) ) AND (dbo.grupo.gru_estado = 1) AND (dbo.usuario_grupo.usg_estado = 1)
			AND (dbo.usuario_administrativos.state = 1)
--Esta parte consulta los usuarios docente
UNION ALL
SELECT		dbo.usuario_grupo.usg_usuario,		dbo.grupo.gru_nombre, 
			dbo.usuario_grupo.usg_grupo,		dbo.grupo.gru_id, 
			dbo.usuario_grupo.usg_uaa,			dbo.usuario_grupo.usg_estado, 
			dbo.grupo.gru_codigo,				dbo.usuario_grupo.usg_codigo, 
			dbo.usuario_docentes.up,		dbo.usuario_docentes.us, 
			dbo.usuario_docentes.istipo,	dbo.usuario_docentes.ischange, 
			dbo.usuario_docentes.state,	dbo.usuario_docentes.sys, 
			dbo.usuario_docentes.uid,	dbo.usuario_docentes.us_encriptado
FROM		dbo.usuario_grupo 
INNER JOIN	dbo.grupo ON dbo.usuario_grupo.usg_grupo = dbo.grupo.gru_codigo 
INNER JOIN  dbo.usuario_docentes ON dbo.usuario_grupo.usg_usuario = dbo.usuario_docentes.uid
WHERE		(dbo.grupo.gru_codigo in (8,9,56,270,271,272,273,274) ) AND (dbo.grupo.gru_estado = 1) AND (dbo.usuario_grupo.usg_estado = 1)
			AND (dbo.usuario_docentes.state = 1)



GO


