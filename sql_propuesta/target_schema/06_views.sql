-- ============================================================================
-- ARTEFACTO: 06_views.sql
-- DESCRIPCIÓN: Vistas relacionales optimizadas, normalizadas y seguras
--              - Calificación de esquema canónica ([dbo].[tabla])
--              - Reemplazo de UNION por UNION ALL (eliminación de ordenamiento DISTINCT)
--              - Eliminación de bloqueos sucios WITH(NOLOCK) en favor de RCSI
--              - Corrección del LEFT JOIN negado por WHERE en departamentos_programas_unificados
--              - Ocultamiento de contraseñas en texto claro (up, uwd) en proyecciones
-- PROYECTO: Sistema de Programación Académica (p_academica-main)
-- MOTOR OBJETIVO: Microsoft SQL Server 2016+ / Azure SQL Database / T-SQL ANSI
-- ============================================================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- ----------------------------------------------------------------------------
-- FUNCIÓN AUXILIAR: [dbo].[Split] (Función de división de subgrupos delimitados)
-- Requerida para estudiante_horario_actual
-- ----------------------------------------------------------------------------
IF OBJECT_ID('dbo.Split', 'IF') IS NOT NULL
    DROP FUNCTION dbo.Split;
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
    SELECT value AS Item
    FROM STRING_SPLIT(@String, @Delimiter)
);
GO

-- ----------------------------------------------------------------------------
-- VISTA 1: [dbo].[departamentos_programas_unificados]
-- Optimización: Calificación canónica, proyección de columnas requeridas por PHP
-- ----------------------------------------------------------------------------
CREATE OR ALTER VIEW [dbo].[departamentos_programas_unificados]
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
-- Optimización: Proyección de columnas físicas canónicas y UNION ALL simétrico
-- ----------------------------------------------------------------------------
CREATE OR ALTER VIEW [dbo].[espacio_ocupacion_total]
AS
SELECT 
    eso_codigo, esp_codigo, uaa_codigo, eso_fecha, hor_codigo, dia_codigo, hra_codigo, 
    eso_actividad, eso_subgrupo, uap_codigo, eso_estado, oct_codigo, eso_descripcion, 
    cdp_codigo, ctr_codigo, usu_codigo, 'ACTUAL' AS particion_temporal
FROM [dbo].[espacio_ocupacion]
UNION ALL
SELECT 
    eso_codigo, esp_codigo, uaa_codigo, eso_fecha, hor_codigo, dia_codigo, hra_codigo, 
    eso_actividad, eso_subgrupo, uap_codigo, eso_estado, oct_codigo, eso_descripcion, 
    cdp_codigo, ctr_codigo, usu_codigo, 'HISTORICO' AS particion_temporal
FROM [dbo].[espacio_ocupacion_historico];
GO

-- ----------------------------------------------------------------------------
-- VISTA 3: [dbo].[estudiante_horario_actual]
-- Optimización: Referencia a columna real eo.eso_fecha y proyección de eso_subgrupo
-- ----------------------------------------------------------------------------
CREATE OR ALTER VIEW [dbo].[estudiante_horario_actual]
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
    ON mc.cur_codigo = eo.eso_actividad;
GO

-- ----------------------------------------------------------------------------
-- VISTA 4: [dbo].[matricula_curso]
-- Optimización: UNION ALL en lugar de UNION sobre particiones masivas de calificaciones
-- ----------------------------------------------------------------------------
CREATE OR ALTER VIEW [dbo].[matricula_curso]
AS
SELECT 
    mat_codigo, cur_codigo, est_codigo, mac_nota_definitiva, mac_estado, per_codigo, 'ACTUAL' AS tabla
FROM [dbo].[matricula_curso_actual]
UNION ALL
SELECT 
    mat_codigo, cur_codigo, est_codigo, mac_nota_definitiva, mac_estado, per_codigo, 'HISTORICO' AS tabla
FROM [dbo].[matricula_curso_historico]
UNION ALL
SELECT 
    mat_codigo, cur_codigo, est_codigo, mac_nota_definitiva, mac_estado, per_codigo, 'MULTICURSO' AS tabla
FROM [dbo].[matricula_multicurso];
GO

-- ----------------------------------------------------------------------------
-- VISTA 5: [dbo].[notas_total]
-- Optimización: Calificación canónica de entidades y condiciones de agregación claras
-- ----------------------------------------------------------------------------
CREATE OR ALTER VIEW [dbo].[notas_total]
AS
SELECT				
    c.cal_nombre, 
    mc.mat_codigo, 
    mc.cur_codigo, 
    mc.mac_nota_definitiva, 
    mf.maf_nombre, 
    m.est_codigo, 
    cur.cur_codigo AS curso_codigo_ref, 
    paa.paa_semestre, 
    paa.paa_credito, 
    asi.asi_codigo, 
    paa.pla_codigo, 
    asi.asi_nombre_corto, 
    asi.asi_nombre,
    asi.asi_creditos
FROM [dbo].[calendario] c
INNER JOIN [dbo].[curso] cur 
    ON c.cal_codigo = cur.cal_codigo
INNER JOIN [dbo].[matricula_curso_actual] mc 
    ON cur.cur_codigo = mc.cur_codigo
INNER JOIN [dbo].[matricula] m 
    ON mc.mat_codigo = m.mat_codigo
LEFT JOIN [dbo].[matricula_forma] mf 
    ON cur.cut_codigo = mf.maf_codigo
INNER JOIN [dbo].[asignatura] asi 
    ON cur.asi_codigo = asi.asi_codigo
LEFT JOIN [dbo].[plan_academico_asignatura] paa 
    ON cur.asi_codigo = paa.asi_codigo AND cur.pla_codigo = paa.pla_codigo;
GO

-- ----------------------------------------------------------------------------
-- VISTA 6: [dbo].[resumen_docencia_final]
-- Optimización: Agrupación y suma de horas semestrales por docente y unidad
-- ----------------------------------------------------------------------------
CREATE OR ALTER VIEW [dbo].[resumen_docencia_final]
AS
SELECT     
    p.per_apellido, 
    p.per_nombre, 
    rds.per_codigo AS periodo, 
    u.uaa_codigo, 
    u.uaa_nombre, 
    p.per_identificacion, 
    p.per_codigo, 
    SUM(rds.rds_horas) AS horas_sema, 
    rds.cur_codigo, 
    rds.uap_codigo
FROM [dbo].[resumen_docencia_sem] rds
INNER JOIN [dbo].[uaa_personal] uap 
    ON rds.uap_codigo = uap.uap_codigo
INNER JOIN [dbo].[persona] p 
    ON uap.per_codigo = p.per_codigo
INNER JOIN [dbo].[uaa] u 
    ON uap.uaa_codigo = u.uaa_codigo
GROUP BY 
    p.per_apellido, p.per_nombre, rds.per_codigo, u.uaa_codigo, 
    u.uaa_nombre, p.per_identificacion, p.per_codigo, rds.cur_codigo, rds.uap_codigo;
GO

-- ----------------------------------------------------------------------------
-- VISTAS DE AUTENTICACIÓN Y ROLES INSTITUCIONALES (7 a 12)
-- Seguridad: Supresión de contraseñas en texto claro (up, uwd = NULL/Masked)
-- ----------------------------------------------------------------------------

-- VISTA 7: [dbo].[usuario_administrativo]
CREATE OR ALTER VIEW [dbo].[usuario_administrativo]
AS
SELECT     
    CAST(NULL AS VARCHAR(50)) AS up, 
    u.us_nombre AS us, 
    1 AS istipo, 
    0 AS ischange, 
    u.us_estado AS [state], 
    'ACADEMICA' AS [sys], 
    ug.usg_grupo, 
    g.gru_nombre, 
    ug.usg_usuario, 
    u.[uid], 
    g.gru_id, 
    ug.usg_estado, 
    CAST(NULL AS VARCHAR(50)) AS us_encriptado
FROM [dbo].[grupo] g
INNER JOIN [dbo].[usuario_grupo] ug 
    ON g.gru_codigo = ug.usg_grupo
INNER JOIN [dbo].[usuario_administrativos] u 
    ON ug.usg_usuario = u.[uid]
WHERE g.gru_nombre NOT IN ('Docente', 'Estudiante');
GO

-- VISTA 8: [dbo].[usuario_docente]
CREATE OR ALTER VIEW [dbo].[usuario_docente]
AS
SELECT     
    CAST(NULL AS VARCHAR(50)) AS up, 
    u.us_nombre AS us, 
    2 AS istipo, 
    0 AS ischange, 
    u.us_estado AS [state], 
    'ACADEMICA' AS [sys], 
    ug.usg_grupo, 
    g.gru_nombre, 
    ug.usg_usuario, 
    u.[uid], 
    g.gru_id, 
    ug.usg_estado, 
    ug.usg_uaa, 
    CAST(NULL AS VARCHAR(50)) AS us_encriptado
FROM [dbo].[grupo] g
INNER JOIN [dbo].[usuario_grupo] ug 
    ON g.gru_codigo = ug.usg_grupo
INNER JOIN [dbo].[usuario_docentes] u 
    ON ug.usg_usuario = u.[uid]
WHERE g.gru_id = 'DOCENTE' OR g.gru_nombre = 'Docente';
GO

-- VISTA 9: [dbo].[usuario_general]
CREATE OR ALTER VIEW [dbo].[usuario_general]
AS
SELECT [uid], CAST(NULL AS VARCHAR(50)) AS up, us_nombre AS us, 3 AS istipo, 0 AS ischange, us_estado AS [state], 'ESTUDIANTE' AS [sys], us_correo, CAST(NULL AS VARCHAR(100)) AS us_pregunta, CAST(NULL AS VARCHAR(100)) AS us_respuesta, CAST(NULL AS VARCHAR(50)) AS us_encriptado
FROM [dbo].[usuario_estudiantes]
UNION ALL
SELECT [uid], CAST(NULL AS VARCHAR(50)) AS up, us_nombre AS us, 3 AS istipo, 0 AS ischange, us_estado AS [state], 'VIRTUAL' AS [sys], us_correo, CAST(NULL AS VARCHAR(100)) AS us_pregunta, CAST(NULL AS VARCHAR(100)) AS us_respuesta, CAST(NULL AS VARCHAR(50)) AS us_encriptado
FROM [dbo].[usuario_estudiantes_virtual]
UNION ALL
SELECT [uid], CAST(NULL AS VARCHAR(50)) AS up, us_nombre AS us, 3 AS istipo, 0 AS ischange, us_estado AS [state], 'INTERCAMBIO' AS [sys], us_correo, CAST(NULL AS VARCHAR(100)) AS us_pregunta, CAST(NULL AS VARCHAR(100)) AS us_respuesta, CAST(NULL AS VARCHAR(50)) AS us_encriptado
FROM [dbo].[usuario_estudiantes_intercambio]
UNION ALL
SELECT [uid], CAST(NULL AS VARCHAR(50)) AS up, us_nombre AS us, 4 AS istipo, 0 AS ischange, us_estado AS [state], 'GRADUADO' AS [sys], us_correo, CAST(NULL AS VARCHAR(100)) AS us_pregunta, CAST(NULL AS VARCHAR(100)) AS us_respuesta, CAST(NULL AS VARCHAR(50)) AS us_encriptado
FROM [dbo].[usuario_graduados]
UNION ALL
SELECT [uid], CAST(NULL AS VARCHAR(50)) AS up, us_nombre AS us, 5 AS istipo, 0 AS ischange, us_estado AS [state], 'EXTERNO' AS [sys], us_correo, CAST(NULL AS VARCHAR(100)) AS us_pregunta, CAST(NULL AS VARCHAR(100)) AS us_respuesta, CAST(NULL AS VARCHAR(50)) AS us_encriptado
FROM [dbo].[usuario_externos]
UNION ALL
SELECT [uid], CAST(NULL AS VARCHAR(50)) AS up, us_nombre AS us, 2 AS istipo, 0 AS ischange, us_estado AS [state], 'DOCENTE' AS [sys], us_correo, CAST(NULL AS VARCHAR(100)) AS us_pregunta, CAST(NULL AS VARCHAR(100)) AS us_respuesta, CAST(NULL AS VARCHAR(50)) AS us_encriptado
FROM [dbo].[usuario_docentes]
UNION ALL
SELECT [uid], CAST(NULL AS VARCHAR(50)) AS up, us_nombre AS us, 1 AS istipo, 0 AS ischange, us_estado AS [state], 'ADMIN' AS [sys], us_correo, CAST(NULL AS VARCHAR(100)) AS us_pregunta, CAST(NULL AS VARCHAR(100)) AS us_respuesta, CAST(NULL AS VARCHAR(50)) AS us_encriptado
FROM [dbo].[usuario_administrativos];
GO

-- VISTA 10: [dbo].[usuario_planta_fisica]
CREATE OR ALTER VIEW [dbo].[usuario_planta_fisica]
AS
SELECT		
    ug.usg_usuario,		
    g.gru_nombre, 
    ug.usg_grupo,		
    g.gru_id, 
    ug.usg_uaa,			
    ug.usg_estado, 
    g.gru_codigo,				
    ug.usg_codigo, 
    CAST(NULL AS VARCHAR(50)) AS up,		
    u.us_nombre AS us, 
    1 AS istipo,	
    0 AS ischange, 
    u.us_estado AS [state],	
    'PLANTA_FISICA' AS [sys]
FROM [dbo].[grupo] g
INNER JOIN [dbo].[usuario_grupo] ug 
    ON g.gru_codigo = ug.usg_grupo
INNER JOIN [dbo].[usuario_administrativos] u 
    ON ug.usg_usuario = u.[uid]
WHERE g.gru_nombre = 'Planta Fisica' OR g.gru_id = 'PLANTA_FISICA';
GO

-- VISTA 11: [dbo].[usuario_programacion]
CREATE OR ALTER VIEW [dbo].[usuario_programacion]
AS
SELECT		
    ug.usg_usuario,		
    g.gru_nombre, 
    ug.usg_grupo,			
    g.gru_id, 
    ug.usg_uaa,			
    ug.usg_estado, 
    g.gru_codigo,			
    ug.usg_codigo, 
    CAST(NULL AS VARCHAR(50)) AS up,					
    u.us_nombre AS us, 
    1 AS istipo,				
    u.[uid],
    u.us_estado AS [state]
FROM [dbo].[grupo] g
INNER JOIN [dbo].[usuario_grupo] ug 
    ON g.gru_codigo = ug.usg_grupo
INNER JOIN [dbo].[usuario_administrativos] u 
    ON ug.usg_usuario = u.[uid];
GO

-- VISTA 12: [dbo].[usuario_programacion_login]
CREATE OR ALTER VIEW [dbo].[usuario_programacion_login]
AS
SELECT		
    ug.usg_usuario,		
    g.gru_nombre, 
    ug.usg_grupo,			
    g.gru_id, 
    ug.usg_uaa,			
    ug.usg_estado, 
    g.gru_codigo,			
    ug.usg_codigo, 
    CAST(NULL AS VARCHAR(50)) AS up,					
    u.us_nombre AS us, 
    1 AS istipo,				
    u.[uid],
    u.us_estado AS [state],
    CAST(NULL AS VARCHAR(50)) AS us_encriptado
FROM [dbo].[grupo] g
INNER JOIN [dbo].[usuario_grupo] ug 
    ON g.gru_codigo = ug.usg_grupo
INNER JOIN [dbo].[usuario_administrativos] u 
    ON ug.usg_usuario = u.[uid]
UNION ALL
SELECT		
    ug.usg_usuario,		
    g.gru_nombre, 
    ug.usg_grupo,			
    g.gru_id, 
    ug.usg_uaa,			
    ug.usg_estado, 
    g.gru_codigo,			
    ug.usg_codigo, 
    CAST(NULL AS VARCHAR(50)) AS up,					
    doc.us_nombre AS us, 
    2 AS istipo,				
    doc.[uid],
    doc.us_estado AS [state],
    CAST(NULL AS VARCHAR(50)) AS us_encriptado
FROM [dbo].[grupo] g
INNER JOIN [dbo].[usuario_grupo] ug 
    ON g.gru_codigo = ug.usg_grupo
INNER JOIN [dbo].[usuario_docentes] doc 
    ON ug.usg_usuario = doc.[uid];
GO
