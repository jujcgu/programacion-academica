-- ============================================================================
-- ARTEFACTO: 06_views.sql
-- DESCRIPCIÓN: Vistas relacionales optimizadas, 100% compatibles con las tablas
--              reales de producción (sql/dbo/vistas/*.sql):
--              - Función dbo.Split compatible con cualquier nivel de compatibilidad
--                (sin dependencia de STRING_SPLIT para SQL Server 2008/2012/2014/2016+)
--              - Reemplazo de UNION por UNION ALL en vistas particionadas masivas
--                (espacio_ocupacion_total, matricula_curso, usuario_general,
--                 usuario_programacion, usuario_programacion_login)
--              - Eliminación de hints WITH(NOLOCK) en estudiante_horario_actual
--              - Corrección del LEFT JOIN en departamentos_programas_unificados
--              - Conservación del 100% de nombres de columnas reales de producción
-- PROYECTO: Sistema de Programación Académica (p_academica-main)
-- ============================================================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- ----------------------------------------------------------------------------
-- FUNCIÓN AUXILIAR: [dbo].[Split]
-- Compatible con todos los niveles de compatibilidad de SQL Server (80 a 160)
-- sin requerir STRING_SPLIT. Expone la columna [Value] requerida por
-- dbo.estudiante_horario_actual.
-- ----------------------------------------------------------------------------
IF OBJECT_ID(N'[dbo].[Split]', N'IF') IS NOT NULL
    OR OBJECT_ID(N'[dbo].[Split]', N'TF') IS NOT NULL
    OR OBJECT_ID(N'[dbo].[Split]', N'FN') IS NOT NULL
    DROP FUNCTION [dbo].[Split];
GO

CREATE FUNCTION [dbo].[Split]
(
    @String NVARCHAR(MAX),
    @Delimiter CHAR(1)
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        LTRIM(RTRIM(m.n.value('.[1]', 'varchar(8000)'))) AS [Value]
    FROM (
        SELECT CAST('<XMLRoot><RowData>' + REPLACE(ISNULL(@String, ''), @Delimiter, '</RowData><RowData>') + '</RowData></XMLRoot>' AS XML) AS x
    ) AS t
    CROSS APPLY x.nodes('/XMLRoot/RowData') m(n)
    WHERE LTRIM(RTRIM(m.n.value('.[1]', 'varchar(8000)'))) <> ''
);
GO

-- ----------------------------------------------------------------------------
-- VISTA 1: [dbo].[departamentos_programas_unificados]
-- Optimización: Traslado de pdt.prd_estado = 1 al predicado ON del LEFT JOIN
-- ----------------------------------------------------------------------------
IF OBJECT_ID(N'[dbo].[departamentos_programas_unificados]', N'V') IS NULL
    EXEC('CREATE VIEW [dbo].[departamentos_programas_unificados] AS SELECT 1 AS stub');
GO

ALTER VIEW [dbo].[departamentos_programas_unificados]
AS 
SELECT 
    u.uaa_codigo AS uaa_codigo_departamento, 
    u.uaa_nombre AS uaa_nombre_departamento,
    pro.uaa_codigo_unificado, 
    u2.uaa_nombre AS uaa_nombre_unificado,
    pro.pro_codigo, 
    u3.uaa_codigo AS uaa_codigo_programa, 
    u3.uaa_nombre AS uaa_nombre_programa
FROM [dbo].[uaa] u
LEFT JOIN [dbo].[programa_dpto] pdt 
    ON u.uaa_codigo = pdt.uaa_codigo AND pdt.prd_estado = 1
LEFT JOIN [dbo].[programa] pro 
    ON pro.pro_codigo = pdt.pro_codigo
LEFT JOIN [dbo].[uaa] u2 
    ON pro.uaa_codigo_unificado = u2.uaa_codigo
LEFT JOIN [dbo].[uaa] u3 
    ON pro.uaa_codigo = u3.uaa_codigo
WHERE u.uat_codigo = 2
GROUP BY 
    u.uaa_codigo, u.uaa_nombre, pro.uaa_codigo_unificado, 
    u2.uaa_nombre, pro.pro_codigo, u3.uaa_codigo, u3.uaa_nombre;
GO

-- ----------------------------------------------------------------------------
-- VISTA 2: [dbo].[espacio_ocupacion_total]
-- Optimización: UNION ALL en lugar de UNION sobre las 32 columnas reales
-- ----------------------------------------------------------------------------
IF OBJECT_ID(N'[dbo].[espacio_ocupacion_total]', N'V') IS NULL
    EXEC('CREATE VIEW [dbo].[espacio_ocupacion_total] AS SELECT 1 AS stub');
GO

ALTER VIEW [dbo].[espacio_ocupacion_total]
AS
SELECT 
    eso_codigo, esp_codigo, uaa_codigo, eso_fecha, hor_codigo, dia_codigo, hra_codigo, 
    eso_actividad, eso_subgrupo, uap_codigo, eso_estado, oct_codigo, eso_descripcion, 
    cdp_codigo, ctr_codigo, usu_codigo, usu_clave, sippa_sedcodigo, sippa_calcodigo, 
    sippa_progcodigo, sippa_plancodigo, sippa_asicodigo, sippa_grucodigo, sippa_subgrucodigo, 
    sippa_horfecini, sippa_horfecfin, sippa_horcodigo, sippa_doccedula, sippa_salcodigo, 
    sippa_horsemanas, sippa_horfactor, sippa_vincodigo
FROM [dbo].[espacio_ocupacion]
UNION ALL
SELECT 
    eso_codigo, esp_codigo, uaa_codigo, eso_fecha, hor_codigo, dia_codigo, hra_codigo, 
    eso_actividad, eso_subgrupo, uap_codigo, eso_estado, oct_codigo, eso_descripcion, 
    cdp_codigo, ctr_codigo, usu_codigo, usu_clave, sippa_sedcodigo, sippa_calcodigo, 
    sippa_progcodigo, sippa_plancodigo, sippa_asicodigo, sippa_grucodigo, sippa_subgrucodigo, 
    sippa_horfecini, sippa_horfecfin, sippa_horcodigo, sippa_doccedula, sippa_salcodigo, 
    sippa_horsemanas, sippa_horfactor, sippa_vincodigo
FROM [dbo].[espacio_ocupacion_historico];
GO

-- ----------------------------------------------------------------------------
-- VISTA 3: [dbo].[estudiante_horario_actual]
-- Optimización: Eliminación de hints WITH(NOLOCK) y acotación de VARCHAR(30/10)
-- ----------------------------------------------------------------------------
IF OBJECT_ID(N'[dbo].[estudiante_horario_actual]', N'V') IS NULL
    EXEC('CREATE VIEW [dbo].[estudiante_horario_actual] AS SELECT 1 AS stub');
GO

ALTER VIEW [dbo].[estudiante_horario_actual]
AS
SELECT     
    CONVERT(VARCHAR(30), CONVERT(date, eo.eso_fecha)) + '--' + CONVERT(VARCHAR(10), eo.dia_codigo) + '--' + CONVERT(VARCHAR(10), eo.hra_codigo) AS [date], 
    eo.eso_fecha, 
    eo.dia_codigo, 
    eo.hra_codigo, 
    m.est_codigo, 
    mc.cur_codigo, 
    eo.eso_actividad, 
    eo.eso_subgrupo, 
    est.per_codigo, 
    pro.nia_codigo
FROM [dbo].[matricula] AS m
INNER JOIN [dbo].[matricula_curso_actual] AS mc 
    ON m.mat_codigo = mc.mat_codigo
INNER JOIN [dbo].[estudiante] AS est 
    ON m.est_codigo = est.est_codigo
INNER JOIN [dbo].[programa] AS pro 
    ON est.pro_codigo = pro.pro_codigo
INNER JOIN [dbo].[espacio_ocupacion] AS eo 
    ON mc.cur_codigo = eo.eso_actividad
WHERE (m.cal_codigo IN (
          SELECT [Value]
          FROM [dbo].[Split]((
              SELECT wep_valor
              FROM [dbo].[web_parametro]
              WHERE (wep_nombre = 'MATRICULA_PREGRADO_POSGRADO_CALENDARIO_ACTUAL')
          ), ',') AS Split_1
      ))
  AND (mc.maa_codigo IN (1, 2))
  AND (eo.eso_subgrupo IN ('00', mc.mac_subgrupo))
GROUP BY 
    eo.eso_fecha, eo.dia_codigo, eo.hra_codigo, m.est_codigo, 
    mc.cur_codigo, eo.eso_actividad, eo.eso_subgrupo, est.per_codigo, pro.nia_codigo;
GO

-- ----------------------------------------------------------------------------
-- VISTA 4: [dbo].[matricula_curso]
-- Optimización: UNION ALL en lugar de UNION sobre las 41 columnas reales
-- ----------------------------------------------------------------------------
IF OBJECT_ID(N'[dbo].[matricula_curso]', N'V') IS NULL
    EXEC('CREATE VIEW [dbo].[matricula_curso] AS SELECT 1 AS stub');
GO

ALTER VIEW [dbo].[matricula_curso]
AS
SELECT 
    mac_codigo, mat_codigo, cur_codigo, mac_subgrupo, mac_estado, mac_nota, mac_habilitacion, 
    mac_perdio_fallas, mac_definitiva, maf_codigo, res_codigo, paa_codigo, mac_novedad, 
    maa_codigo, mac_usuario, mac_ip_nota, mac_clave, mac_cliente, mac_fecha_nota, 
    paa_codigo_anterior, sippa_sedcodigo, sippa_calcodigo, sippa_estcodigo, sippa_progcodigo, 
    sippa_plancodigo, sippa_asicodigo, sippa_horasasignatura, sippa_grucodigo, sippa_subgrucodigo, 
    sippa_cursemestre, sippa_curasignatura, sippa_curnomasigna, sippa_curforma, sippa_curautorizacion, 
    temporal_null, mac_usuario_nota, mac_cliente_nota, esc_codigo, esc_nombre, mac_fecha_hora, 
    'ACTUAL' AS tabla
FROM [dbo].[matricula_curso_actual]
UNION ALL
SELECT 
    mac_codigo, mat_codigo, cur_codigo, mac_subgrupo, mac_estado, mac_nota, mac_habilitacion, 
    mac_perdio_fallas, mac_definitiva, maf_codigo, res_codigo, paa_codigo, mac_novedad, 
    maa_codigo, mac_usuario, mac_ip_nota, mac_clave, mac_cliente, mac_fecha_nota, 
    paa_codigo_anterior, sippa_sedcodigo, sippa_calcodigo, sippa_estcodigo, sippa_progcodigo, 
    sippa_plancodigo, sippa_asicodigo, sippa_horasasignatura, sippa_grucodigo, sippa_subgrucodigo, 
    sippa_cursemestre, sippa_curasignatura, sippa_curnomasigna, sippa_curforma, sippa_curautorizacion, 
    temporal_null, mac_usuario_nota, mac_cliente_nota, esc_codigo, esc_nombre, mac_fecha_hora, 
    'HISTORICO' AS tabla
FROM [dbo].[matricula_curso_historico]
UNION ALL
SELECT 
    mac_codigo, mat_codigo, cur_codigo, mac_subgrupo, mac_estado, mac_nota, mac_habilitacion, 
    mac_perdio_fallas, mac_definitiva, maf_codigo, res_codigo, paa_codigo, mac_novedad, 
    maa_codigo, mac_usuario, mac_ip_nota, mac_clave, mac_cliente, mac_fecha_nota, 
    paa_codigo_anterior, sippa_sedcodigo, sippa_calcodigo, sippa_estcodigo, sippa_progcodigo, 
    sippa_plancodigo, sippa_asicodigo, sippa_horasasignatura, sippa_grucodigo, sippa_subgrucodigo, 
    sippa_cursemestre, sippa_curasignatura, sippa_curnomasigna, sippa_curforma, sippa_curautorizacion, 
    temporal_null, mac_usuario_nota, mac_cliente_nota, esc_codigo, esc_nombre, mac_fecha_hora, 
    'MULTICURSO' AS tabla
FROM [dbo].[matricula_multicurso];
GO

-- ----------------------------------------------------------------------------
-- VISTA 5: [dbo].[notas_total]
-- Optimización: Se beneficia directamente del UNION ALL de dbo.matricula_curso
--               y reemplaza LIKE por = en el join numérico de sippa_asicodigo
-- ----------------------------------------------------------------------------
IF OBJECT_ID(N'[dbo].[notas_total]', N'V') IS NULL
    EXEC('CREATE VIEW [dbo].[notas_total] AS SELECT 1 AS stub');
GO

ALTER VIEW [dbo].[notas_total]
AS
SELECT				
    [dbo].[calendario].cal_nombre, 
    [dbo].[matricula_curso].mac_subgrupo, 
    [dbo].[matricula_curso].mac_nota, 
    [dbo].[matricula_curso].maa_codigo, 
    [dbo].[matricula_curso].cur_codigo, 
    [dbo].[matricula_curso].mac_habilitacion, 
    [dbo].[matricula_curso].mac_definitiva, 
    [dbo].[matricula_forma].maf_nombre, 
    [dbo].[matricula_curso].paa_codigo, 
    [dbo].[matricula].est_codigo, 
    [dbo].[curso].cur_codigo AS Expr1, 
    [dbo].[plan_academico_asignatura].paa_semestre, 
    [dbo].[plan_academico_asignatura].paa_credito, 
    asignatura2.asi_codigo, 
    [dbo].[plan_academico_asignatura].pla_codigo, 
    asignatura1.asi_nombre_corto, 
    asignatura2.asi_nombre,
    asignatura2.asi_nombre_corto AS asi_nombre_corto_paa,
    asignatura1.asi_nombre AS asi_nom2, 
    asignatura1.asi_codigo AS Expr3, 
    COALESCE(
        CASE WHEN asignatura1.asi_creditos IS NULL THEN asignatura3.asi_creditos ELSE asignatura1.asi_creditos END,
        CASE WHEN asignatura3.asi_creditos IS NULL THEN [dbo].[plan_academico_asignatura].paa_credito ELSE asignatura3.asi_creditos END
    ) AS asi_creditos, 
    [dbo].[matricula_curso].sippa_curnomasigna, 
    [dbo].[matricula_curso].sippa_asicodigo, 
    [dbo].[matricula_curso].sippa_cursemestre, 
    [dbo].[matricula_curso].mac_fecha_nota, 
    [dbo].[matricula_curso].esc_codigo, 
    [dbo].[matricula_curso].esc_nombre, 
    [dbo].[curso].tes_codigo, 
    [dbo].[matricula_curso].tabla,
    [dbo].[plan_academico_asignatura].paa_intensidad, 
    [dbo].[matricula_autorizacion].maa_nombre, 
    [dbo].[plan_academico_asignatura].paa_multi_asignatura, 
    [dbo].[plan_academico_asignatura].paa_plan_academico
FROM [dbo].[asignatura] AS asignatura2 
INNER JOIN [dbo].[plan_academico_asignatura] 
    ON asignatura2.asi_codigo = [dbo].[plan_academico_asignatura].asi_codigo 
RIGHT OUTER JOIN [dbo].[calendario] 
INNER JOIN [dbo].[matricula_curso] 
INNER JOIN [dbo].[matricula] 
    ON [dbo].[matricula_curso].mat_codigo = [dbo].[matricula].mat_codigo 
INNER JOIN [dbo].[matricula_autorizacion] 
    ON [dbo].[matricula_curso].maa_codigo = [dbo].[matricula_autorizacion].maa_codigo 
INNER JOIN [dbo].[matricula_forma] 
    ON [dbo].[matricula_curso].maf_codigo = [dbo].[matricula_forma].maf_codigo 
    ON [dbo].[calendario].cal_codigo = [dbo].[matricula].cal_codigo 
    ON [dbo].[plan_academico_asignatura].paa_codigo = [dbo].[matricula_curso].paa_codigo 
LEFT OUTER JOIN [dbo].[curso] 
    ON [dbo].[matricula_curso].cur_codigo = [dbo].[curso].cur_codigo 
LEFT OUTER JOIN [dbo].[asignatura] AS asignatura1 
    ON [dbo].[curso].asi_codigo = asignatura1.asi_codigo
LEFT JOIN [dbo].[asignatura] AS asignatura3 
    ON [dbo].[matricula_curso].sippa_asicodigo = asignatura3.asi_codigo;
GO

-- ----------------------------------------------------------------------------
-- VISTA 6: [dbo].[resumen_docencia_final]
-- Optimización: Conserva las 20 columnas reales de dbo.resumen_docencia_sem (SUM(c_horas))
-- ----------------------------------------------------------------------------
IF OBJECT_ID(N'[dbo].[resumen_docencia_final]', N'V') IS NULL
    EXEC('CREATE VIEW [dbo].[resumen_docencia_final] AS SELECT 1 AS stub');
GO

ALTER VIEW [dbo].[resumen_docencia_final]
AS
SELECT     
    per_apellido, per_nombre, periodo, vin_codigo, vin_nombre, ded_codigo, ded_nombre, 
    uaa_codigo, uaa_dependencia, per_identificacion, per_codigo, 
    SUM(c_horas) AS horas_sema, 
    semanas, uaa_nombre_corto, persona, uaa_nombre, cur_codigo, eso_subgrupo, cur_grupo, uap_codigo
FROM [dbo].[resumen_docencia_sem]
GROUP BY 
    per_apellido, per_nombre, persona, periodo, vin_codigo, vin_nombre, ded_codigo, ded_nombre, 
    uaa_codigo, uaa_dependencia, per_identificacion, cur_codigo, eso_subgrupo, per_codigo, 
    semanas, uaa_nombre_corto, uaa_nombre, cur_grupo, uap_codigo;
GO

-- ----------------------------------------------------------------------------
-- VISTAS DE AUTENTICACIÓN Y ROLES INSTITUCIONALES (7 a 12)
-- Conservan el 100% de los nombres de columna reales de usuario_administrativos,
-- usuario_docentes, usuario_estudiantes, etc. y optimizan UNION -> UNION ALL.
-- ----------------------------------------------------------------------------

-- VISTA 7: [dbo].[usuario_administrativo]
IF OBJECT_ID(N'[dbo].[usuario_administrativo]', N'V') IS NULL
    EXEC('CREATE VIEW [dbo].[usuario_administrativo] AS SELECT 1 AS stub');
GO

ALTER VIEW [dbo].[usuario_administrativo]
AS
SELECT     
    [dbo].[usuario_administrativos].up, 
    [dbo].[usuario_administrativos].us, 
    [dbo].[usuario_administrativos].istipo, 
    [dbo].[usuario_administrativos].ischange, 
    [dbo].[usuario_administrativos].[state], 
    [dbo].[usuario_administrativos].[sys], 
    [dbo].[usuario_grupo].usg_grupo, 
    [dbo].[grupo].gru_nombre, 
    [dbo].[usuario_grupo].usg_usuario, 
    [dbo].[usuario_administrativos].[uid], 
    [dbo].[grupo].gru_id, 
    [dbo].[usuario_grupo].usg_estado, 
    [dbo].[usuario_administrativos].us_encriptado
FROM [dbo].[grupo] 
INNER JOIN [dbo].[usuario_grupo] 
    ON [dbo].[grupo].gru_codigo = [dbo].[usuario_grupo].usg_grupo 
INNER JOIN [dbo].[usuario_administrativos] 
    ON [dbo].[usuario_grupo].usg_usuario = [dbo].[usuario_administrativos].[uid]
WHERE ([dbo].[grupo].gru_nombre NOT IN ('Docente', 'Estudiante'));
GO

-- VISTA 8: [dbo].[usuario_docente]
IF OBJECT_ID(N'[dbo].[usuario_docente]', N'V') IS NULL
    EXEC('CREATE VIEW [dbo].[usuario_docente] AS SELECT 1 AS stub');
GO

ALTER VIEW [dbo].[usuario_docente]
AS
SELECT     
    [dbo].[usuario_docentes].up, 
    [dbo].[usuario_docentes].us, 
    [dbo].[usuario_docentes].istipo, 
    [dbo].[usuario_docentes].ischange, 
    [dbo].[usuario_docentes].[state], 
    [dbo].[usuario_docentes].[sys], 
    [dbo].[usuario_grupo].usg_grupo, 
    [dbo].[grupo].gru_nombre, 
    [dbo].[usuario_grupo].usg_usuario, 
    [dbo].[usuario_docentes].[uid], 
    [dbo].[grupo].gru_id, 
    [dbo].[usuario_grupo].usg_estado, 
    [dbo].[usuario_grupo].usg_uaa, 
    [dbo].[usuario_docentes].us_encriptado
FROM [dbo].[grupo] 
INNER JOIN [dbo].[usuario_grupo] 
    ON [dbo].[grupo].gru_codigo = [dbo].[usuario_grupo].usg_grupo 
INNER JOIN [dbo].[usuario_docentes] 
    ON [dbo].[usuario_grupo].usg_usuario = [dbo].[usuario_docentes].[uid]
WHERE ([dbo].[grupo].gru_id IN ('DOCENTE', 'JEFE_PROGRAMA', 'JEFE_DEPARTAMENTO'));
GO

-- VISTA 9: [dbo].[usuario_general]
-- Optimización: UNION ALL en lugar de UNION sobre las 7 tablas de usuarios
IF OBJECT_ID(N'[dbo].[usuario_general]', N'V') IS NULL
    EXEC('CREATE VIEW [dbo].[usuario_general] AS SELECT 1 AS stub');
GO

ALTER VIEW [dbo].[usuario_general]
AS
SELECT [uid], up, us, istipo, ischange, [state], [sys], us_correo, us_pregunta, us_respuesta, us_encriptado
FROM [dbo].[usuario_estudiantes]
UNION ALL
SELECT [uid], up, us, istipo, ischange, [state], [sys], us_correo, us_pregunta, us_respuesta, us_encriptado
FROM [dbo].[usuario_estudiantes_virtual]
UNION ALL
SELECT [uid], up, us, istipo, ischange, [state], [sys], us_correo, us_pregunta, us_respuesta, us_encriptado
FROM [dbo].[usuario_docentes]
UNION ALL
SELECT [uid], up, us, istipo, ischange, [state], [sys], us_correo, us_pregunta, us_respuesta, us_encriptado
FROM [dbo].[usuario_administrativos]
UNION ALL
SELECT [uid], up, us, istipo, ischange, [state], NULL AS [sys], NULL AS us_correo, NULL AS us_pregunta, NULL AS us_respuesta, us_encriptado
FROM [dbo].[usuario_graduados]
UNION ALL
SELECT [uid], up, us, istipo, ischange, [state], [sys], us_correo, us_pregunta, us_respuesta, us_encriptado
FROM [dbo].[usuario_estudiantes_intercambio]
UNION ALL
SELECT [uid], up, us, istipo, ischange, [state], [sys], us_correo, us_pregunta, us_respuesta, us_encriptado
FROM [dbo].[usuario_externos];
GO

-- VISTA 10: [dbo].[usuario_planta_fisica]
IF OBJECT_ID(N'[dbo].[usuario_planta_fisica]', N'V') IS NULL
    EXEC('CREATE VIEW [dbo].[usuario_planta_fisica] AS SELECT 1 AS stub');
GO

ALTER VIEW [dbo].[usuario_planta_fisica]
AS
SELECT		
    [dbo].[usuario_grupo].usg_usuario,		
    [dbo].[grupo].gru_nombre, 
    [dbo].[usuario_grupo].usg_grupo,		
    [dbo].[grupo].gru_id, 
    [dbo].[usuario_grupo].usg_uaa,			
    [dbo].[usuario_grupo].usg_estado, 
    [dbo].[grupo].gru_codigo,				
    [dbo].[usuario_grupo].usg_codigo, 
    [dbo].[usuario_administrativos].up,		
    [dbo].[usuario_administrativos].us, 
    [dbo].[usuario_administrativos].istipo,	
    [dbo].[usuario_administrativos].ischange, 
    [dbo].[usuario_administrativos].[state],	
    [dbo].[usuario_administrativos].[sys], 
    [dbo].[usuario_administrativos].[uid],	
    [dbo].[usuario_administrativos].us_encriptado
FROM [dbo].[usuario_grupo] 
INNER JOIN [dbo].[grupo] 
    ON [dbo].[usuario_grupo].usg_grupo = [dbo].[grupo].gru_codigo 
INNER JOIN [dbo].[usuario_administrativos] 
    ON [dbo].[usuario_grupo].usg_usuario = [dbo].[usuario_administrativos].[uid]
WHERE ([dbo].[grupo].gru_codigo IN (8,9,56,270,271,272,273,274)) 
  AND ([dbo].[grupo].gru_estado = 1) 
  AND ([dbo].[usuario_grupo].usg_estado = 1)
  AND ([dbo].[usuario_administrativos].[state] = 1)
UNION ALL
SELECT		
    [dbo].[usuario_grupo].usg_usuario,		
    [dbo].[grupo].gru_nombre, 
    [dbo].[usuario_grupo].usg_grupo,		
    [dbo].[grupo].gru_id, 
    [dbo].[usuario_grupo].usg_uaa,			
    [dbo].[usuario_grupo].usg_estado, 
    [dbo].[grupo].gru_codigo,				
    [dbo].[usuario_grupo].usg_codigo, 
    [dbo].[usuario_docentes].up,		
    [dbo].[usuario_docentes].us, 
    [dbo].[usuario_docentes].istipo,	
    [dbo].[usuario_docentes].ischange, 
    [dbo].[usuario_docentes].[state],	
    [dbo].[usuario_docentes].[sys], 
    [dbo].[usuario_docentes].[uid],	
    [dbo].[usuario_docentes].us_encriptado
FROM [dbo].[usuario_grupo] 
INNER JOIN [dbo].[grupo] 
    ON [dbo].[usuario_grupo].usg_grupo = [dbo].[grupo].gru_codigo 
INNER JOIN [dbo].[usuario_docentes] 
    ON [dbo].[usuario_grupo].usg_usuario = [dbo].[usuario_docentes].[uid]
WHERE ([dbo].[grupo].gru_codigo IN (8,9,56,270,271,272,273,274)) 
  AND ([dbo].[grupo].gru_estado = 1) 
  AND ([dbo].[usuario_grupo].usg_estado = 1)
  AND ([dbo].[usuario_docentes].[state] = 1);
GO

-- VISTA 11: [dbo].[usuario_programacion]
-- Optimización: UNION ALL en lugar de UNION
IF OBJECT_ID(N'[dbo].[usuario_programacion]', N'V') IS NULL
    EXEC('CREATE VIEW [dbo].[usuario_programacion] AS SELECT 1 AS stub');
GO

ALTER VIEW [dbo].[usuario_programacion]
AS
SELECT		
    usg.usg_usuario,		
    gru.gru_nombre, 
    usg.usg_grupo,			
    gru.gru_id, 
    usg.usg_uaa,			
    usg.usg_estado, 
    gru.gru_codigo,			
    usg.usg_codigo, 
    uad.up,					
    uad.us, 
    uad.istipo,				
    uad.[uid],
    uad.[state]
FROM [dbo].[usuario_grupo] AS usg
INNER JOIN [dbo].[grupo] AS gru 
    ON usg.usg_grupo = gru.gru_codigo 
INNER JOIN [dbo].[usuario_administrativos] AS uad 
    ON usg.usg_usuario = uad.[uid]
WHERE (gru.gru_codigo IN (68,69,318,34,14)) AND (usg.usg_estado = 1)
UNION ALL
SELECT		
    usg.usg_usuario,		
    gru.gru_nombre, 
    usg.usg_grupo,			
    gru.gru_id, 
    usg.usg_uaa,			
    usg.usg_estado, 
    gru.gru_codigo,			
    usg.usg_codigo, 
    uad.up,					
    uad.us, 
    uad.istipo,				
    uad.[uid],
    uad.[state]
FROM [dbo].[usuario_grupo] AS usg
INNER JOIN [dbo].[grupo] AS gru 
    ON usg.usg_grupo = gru.gru_codigo 
INNER JOIN [dbo].[usuario_docentes] AS uad 
    ON usg.usg_usuario = uad.[uid]
WHERE (gru.gru_codigo IN (68,69,318,34,14)) AND (usg.usg_estado = 1);
GO

-- VISTA 12: [dbo].[usuario_programacion_login]
-- Optimización: UNION ALL en lugar de UNION conservando uwd, uwd2, up, us_encriptado
IF OBJECT_ID(N'[dbo].[usuario_programacion_login]', N'V') IS NULL
    EXEC('CREATE VIEW [dbo].[usuario_programacion_login] AS SELECT 1 AS stub');
GO

ALTER VIEW [dbo].[usuario_programacion_login]
AS
SELECT		
    usg.usg_usuario,		
    gru.gru_nombre, 
    usg.usg_grupo,			
    gru.gru_id, 
    usg.usg_uaa,			
    usg.usg_estado, 
    gru.gru_codigo,			
    usg.usg_codigo, 
    uad.up,					
    uad.us, 
    uad.istipo,				
    uad.ischange, 
    uad.uwd,				
    uad.uwd2, 
    uad.[state],				
    uad.[sys], 
    uad.[uid],				
    uad.us_encriptado
FROM [dbo].[usuario_grupo] AS usg
INNER JOIN [dbo].[grupo] AS gru 
    ON usg.usg_grupo = gru.gru_codigo 
INNER JOIN [dbo].[usuario_administrativos] AS uad 
    ON usg.usg_usuario = uad.[uid]
WHERE (gru.gru_codigo IN (68,69,318,34,14)) AND (usg.usg_estado = 1)
UNION ALL
SELECT		
    usg.usg_usuario,		
    gru.gru_nombre, 
    usg.usg_grupo,			
    gru.gru_id, 
    usg.usg_uaa,			
    usg.usg_estado, 
    gru.gru_codigo,			
    usg.usg_codigo, 
    uad.up,					
    uad.us, 
    uad.istipo,				
    uad.ischange, 
    uad.uwd,				
    uad.uwd2, 
    uad.[state],				
    uad.[sys], 
    uad.[uid],				
    uad.us_encriptado
FROM [dbo].[usuario_grupo] AS usg
INNER JOIN [dbo].[grupo] AS gru 
    ON usg.usg_grupo = gru.gru_codigo 
INNER JOIN [dbo].[usuario_docentes] AS uad 
    ON usg.usg_usuario = uad.[uid]
WHERE (gru.gru_codigo IN (68,69,318,34,14)) AND (usg.usg_estado = 1);
GO
