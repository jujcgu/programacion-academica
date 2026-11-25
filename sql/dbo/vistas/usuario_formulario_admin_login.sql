USE [academia3000_sergiomartinez]
GO

/****** Objeto: View [dbo].[usuario_formulario_admin_login] Fecha de script: 25/11/2026 10:20:50 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[usuario_formulario_admin_login]
AS
SELECT        p.per_codigo, ua.uid, ua.us, ua.sys, ua.ischange, p.per_nombre, p.per_apellido, ti.tii_codigo, ti.tii_nombre, ti.tii_nombre_corto, p.per_identificacion, p.per_email_interno, u.uaa_codigo, u.uaa_nombre, 
                         u.uaa_nombre_corto, s.sed_codigo, s.sed_nombre, ua.state, ua.uwd2, ug.usg_estado, g.gru_codigo, g.gru_id, g.gru_nombre
FROM            dbo.usuario_administrativos ua INNER JOIN
                         dbo.persona p ON ua.up = p.per_codigo LEFT JOIN
                         dbo.tipo_id ti ON p.tii_codigo = ti.tii_codigo INNER JOIN
                         dbo.usuario_grupo ug ON ua.uid = ug.usg_usuario INNER JOIN
                         dbo.grupo g ON ug.usg_grupo = g.gru_codigo INNER JOIN
                         dbo.uaa u ON ug.usg_uaa = u.uaa_codigo INNER JOIN
                         dbo.sede s ON u.sed_codigo = s.sed_codigo
WHERE        (g.gru_codigo in (328,276)) AND (g.gru_estado = 1) AND (ug.usg_estado = 1) AND (ua.state = 1)
UNION
SELECT        p.per_codigo, ud.uid, ud.us, ud.sys, ud.ischange, p.per_nombre, p.per_apellido, ti.tii_codigo, ti.tii_nombre, ti.tii_nombre_corto, p.per_identificacion, p.per_email_interno, u.uaa_codigo, u.uaa_nombre, 
                         u.uaa_nombre_corto, s.sed_codigo, s.sed_nombre, ud.state, ud.uwd2, ug.usg_estado, g.gru_codigo, g.gru_id, g.gru_nombre
FROM            dbo.usuario_docentes ud INNER JOIN
                         dbo.persona p ON ud.up = p.per_codigo LEFT JOIN
                         dbo.tipo_id ti ON p.tii_codigo = ti.tii_codigo INNER JOIN
                         dbo.usuario_grupo ug ON ud.uid = ug.usg_usuario INNER JOIN
                         dbo.grupo g ON ug.usg_grupo = g.gru_codigo INNER JOIN
                         dbo.uaa u ON ug.usg_uaa = u.uaa_codigo INNER JOIN
                         dbo.sede s ON u.sed_codigo = s.sed_codigo
WHERE        (g.gru_codigo in (328,276)) AND (g.gru_estado = 1) AND (ug.usg_estado = 1) AND (ud.state = 1);
GO


