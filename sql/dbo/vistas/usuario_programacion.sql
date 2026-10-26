USE [academia3000_sergiomartinez]
GO

/****** Objeto: View [dbo].[usuario_programacion] Fecha de script: 26/10/2026 9:11:10 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO






CREATE VIEW [dbo].[usuario_programacion]
AS
SELECT		usg.usg_usuario,		gru.gru_nombre, 
			usg.usg_grupo,			gru.gru_id, 
			usg.usg_uaa,			usg.usg_estado, 
			gru.gru_codigo,			usg.usg_codigo, 
			uad.up,					uad.us, 
			uad.istipo,				uad.uid,
			uad.state
FROM		dbo.usuario_grupo as usg
INNER JOIN	dbo.grupo as gru ON usg.usg_grupo = gru.gru_codigo 
INNER JOIN	dbo.usuario_administrativos uad ON usg.usg_usuario = uad.uid
WHERE		(gru.gru_codigo in (68,69,318,34,14) ) AND (usg.usg_estado = 1)


UNION 

SELECT		usg.usg_usuario,		gru.gru_nombre, 
			usg.usg_grupo,			gru.gru_id, 
			usg.usg_uaa,			usg.usg_estado, 
			gru.gru_codigo,			usg.usg_codigo, 
			uad.up,					uad.us, 
			uad.istipo,				uad.uid,
			uad.state
FROM		dbo.usuario_grupo as usg
INNER JOIN	dbo.grupo as gru ON usg.usg_grupo = gru.gru_codigo 
INNER JOIN	dbo.usuario_docentes uad ON usg.usg_usuario = uad.uid
WHERE		(gru.gru_codigo in (68,69,318,34,14) ) AND (usg.usg_estado = 1)





GO


