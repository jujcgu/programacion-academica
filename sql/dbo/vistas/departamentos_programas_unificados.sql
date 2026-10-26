USE [academia3000_sergiomartinez]
GO

/****** Objeto: View [dbo].[departamentos_programas_unificados] Fecha de script: 26/10/2026 9:29:46 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW 
[dbo].[departamentos_programas_unificados] AS 
SELECT u.uaa_codigo as uaa_codigo_departamento, u.uaa_nombre as uaa_nombre_departamento,
pro.uaa_codigo_unificado, u2.uaa_nombre as uaa_nombre_unificado,
pro.pro_codigo, u3.uaa_codigo as uaa_codigo_programa, u3.uaa_nombre as uaa_nombre_programa
FROM uaa u
LEFT JOIN programa_dpto pdt ON u.uaa_codigo=pdt.uaa_codigo
LEFT JOIN programa pro ON pro.pro_codigo= pdt.pro_codigo
LEFT JOIN uaa u2 ON pro.uaa_codigo_unificado=u2.uaa_codigo
LEFT JOIN uaa u3 ON pro.uaa_codigo=u3.uaa_codigo
WHERE u.uat_codigo=2 AND pdt.prd_estado=1
GROUP BY u.uaa_codigo, u.uaa_nombre,pro.uaa_codigo_unificado, 
u2.uaa_nombre,pro.pro_codigo,u3.uaa_codigo, u3.uaa_nombre
GO


