-- ============================================================================
-- ARTEFACTO: 03_compatibility_views.sql
-- DESCRIPCIÓN: Capa de compatibilidad retrospectiva (Backward Compatibility Layer)
--              Permite que la aplicación heredada (PHP 7.x/8.x) continúe funcionando
--              sin modificaciones de código durante el proceso de transición:
--              1. Aliasing de per_año sobre la columna normalizada per_anio en periodo
--              2. Aliasing del typo pre_codgo a pre_codigo en proyectos
--              3. Exposición de stubs seguros para usu_clave en curso y espacio_ocupacion
--              4. Provisión de vistas en esquema proaca redirigiendo a programacionacademica
--              5. Provisión de extensiones virtuales en uaa para columnas departamentales
-- PROYECTO: Sistema de Programación Académica (p_academica-main)
-- MOTOR OBJETIVO: Microsoft SQL Server 2016+ / Azure SQL Database / T-SQL ANSI
-- ============================================================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT 'Creando capa de vistas de compatibilidad para código heredado...';
GO

-- ============================================================================
-- 1. ESQUEMA PROACA: Redirección al esquema canónico programacionacademica
-- Resuelve la discrepancia observada en data_base/2. CreateTablesManagement.sql
-- ============================================================================
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'proaca')
BEGIN
    EXEC('CREATE SCHEMA [proaca]');
    PRINT 'Esquema de compatibilidad [proaca] creado.';
END
GO

CREATE OR ALTER VIEW [proaca].[programacion_academica]
AS
SELECT 
    pra_codigo, uaa_codigo, prp_codigo, cal_codigo, 
    pra_fecha_inicio, pra_fecha_fin, pra_estado,
    aud_fecha_creacion, aud_usuario_creacion, aud_fecha_modificacion, aud_usuario_modificacion
FROM [programacionacademica].[programacion_academica];
GO

CREATE OR ALTER VIEW [proaca].[programacion_gestion]
AS
SELECT 
    prg_codigo, uaa_codigo, cal_codigo, 
    prg_fecha_inicio, prg_fecha_fin, prg_estado,
    aud_fecha_creacion, aud_usuario_creacion, aud_fecha_modificacion, aud_usuario_modificacion
FROM [programacionacademica].[programacion_gestion];
GO

CREATE OR ALTER VIEW [proaca].[periodo_unidad]
AS
SELECT 
    peu_codigo, uaa_codigo, per_codigo, 
    peu_fecha_inicio, peu_fecha_fin, peu_estado,
    aud_fecha_creacion, aud_usuario_creacion, aud_fecha_modificacion, aud_usuario_modificacion
FROM [programacionacademica].[periodo_unidad];
GO

-- ============================================================================
-- 2. VISTAS DE COMPATIBILIDAD CON ALIAS DE COLUMNAS DEFECTUOSAS / RENOMBRADAS
-- ============================================================================

-- 2.1 Periodo: Expone per_año para consultas heredadas que usan la eñe
CREATE OR ALTER VIEW [dbo].[vw_compat_periodo]
AS
SELECT 
    per_codigo, 
    pet_codigo, 
    per_nombre, 
    per_anio, 
    per_anio AS [per_año], 
    per_periodo, 
    per_fecha_inicio, 
    per_fecha_fin, 
    per_inicio_actividades, 
    per_fin_actividades, 
    per_acuerdo_actividades, 
    sippa_per_codigo
FROM [dbo].[periodo];
GO

-- 2.2 Proyectos: Expone pre_codgo para consultas con el typo histórico
CREATE OR ALTER VIEW [proyectos].[vw_compat_proyecto_proyeccion_social]
AS
SELECT 
    pps_codigo, pps_titulo, pra_codigo, oap_codigo, pst_codigo, otp_codigo, 
    pps_grupolac, nco_codigo, pps_fecha_inicio, pps_fecha_fin, mun_codigo, 
    pps_palabras_claves, pps_objetivo_general, pps_resumen, pps_metodologia, 
    prc_codigo, 
    pre_codigo, 
    pre_codigo AS [pre_codgo], 
    pps_descripcion_producto, pps_beneficiarios, pps_impactoxuso_esperado, 
    pps_supuestos_basicos, pps_plazo_materializacion, pps_probabilidad_ocurrencia, 
    pps_acto_administrativo, pps_acto_administrativo_fecha, pps_acta_aprobacion, 
    pps_justificacion_beneficio, pps_secretario_administrativo, pps_decano, 
    pps_facultad, pps_coordinador, pps_solicitante_servicio, 
    pps_obs_cumplimiento_actividades, pps_obs_consolidacion_resultados, 
    uaa_pertenece, pps_fecha_registro, pps_pregunta, pps_marco_teorico, 
    pps_grupo, pps_justificacion, pps_estado, pps_convocatoria, 
    pps_tipoproyecto, pps_bibliografia, pps_responsable_admin, beneficiarios, 
    localizacion, contenidos_academicos, pps_fecha_aprobacion_desaprobacion, 
    pps_fecha_actualizacion, pps_aplicacion, pps_ip, pps_observacion_modificacion, 
    pps_planteamiento_problema, pps_linea_estrategica, pps_localizacion_municipio, 
    pps_area_trabajo, pps_linea_investigacion, are_codigo, stp_codigo, 
    pps_semillero, aud_fecha_creacion, aud_usuario_creacion
FROM [proyectos].[proyecto_proyeccion_social];
GO

-- ============================================================================
-- 3. VISTAS DE COMPATIBILIDAD CON STUBS SEGUROS PARA USU_CLAVE (CONTRASEÑAS)
-- Permite que SELECT cur.usu_clave o eso.usu_clave no arrojen error 207
-- ============================================================================

CREATE OR ALTER VIEW [dbo].[vw_compat_curso]
AS
SELECT 
    cur_codigo, uap_codigo, asi_codigo, cur_grupo, sed_codigo, 
    cal_codigo, cur_cupo, cut_codigo, cur_estado, tic_codigo, 
    pla_codigo, tes_codigo, cur_observaciones, 
    cur_exclusivo, cur_fecha_inicio, cur_semanas, cur_cierre, cur_grabado, 
    cdp_codigo, usu_codigo, cur_ampliacion_cupo, cur_fecha_actualizacion, 
    cur_notaparcial, cur_url, cur_id_evento,
    CAST(0 AS INT) AS [cur_matriculados],
    CAST(NULL AS VARCHAR(50)) AS [cur_consecutivo_impresion],
    CAST(NULL AS VARCHAR(2)) AS [cur_subgrupo],
    CAST('' AS VARCHAR(50)) AS [usu_clave],
    aud_fecha_creacion, aud_usuario_creacion, aud_fecha_modificacion, aud_usuario_modificacion
FROM [dbo].[curso];
GO

CREATE OR ALTER VIEW [dbo].[vw_compat_espacio_ocupacion]
AS
SELECT 
    eso_codigo, esp_codigo, uaa_codigo, eso_fecha, hor_codigo, 
    dia_codigo, hra_codigo, eso_actividad, eso_subgrupo, uap_codigo, 
    eso_estado, oct_codigo, eso_descripcion, cdp_codigo, ctr_codigo, 
    usu_codigo, eso_url,
    CAST('' AS VARCHAR(50)) AS [usu_clave],
    aud_fecha_creacion, aud_usuario_creacion, aud_fecha_modificacion, aud_usuario_modificacion
FROM [dbo].[espacio_ocupacion];
GO

-- ============================================================================
-- 4. VISTA DE COMPATIBILIDAD UAA EXTENDIDA
-- Resuelve consultas en Soldoc.php y Inicio_sesion.php que esperan columnas de programa en uaa
-- ============================================================================
CREATE OR ALTER VIEW [dbo].[vw_compat_uaa]
AS
SELECT 
    u.uaa_codigo,
    u.uat_codigo,
    u.uaa_nombre,
    u.uaa_nombre_corto,
    u.sed_codigo,
    u.mun_codigo,
    u.uaa_telefono,
    u.uaa_fax,
    u.uaa_email,
    u.uaa_direccion,
    u.uaa_dependencia,
    u.uaa_estado,
    u.uaa_centro_costos,
    u.uaa_centro_costos AS [uaa_centro_costo],
    u.uaa_acronimo,
    u.sippa_uaa_codigo,
    u.uaa_codigo AS uaa_codigo_departamento,
    u.uaa_nombre AS uaa_nombre_departamento,
    dpu.pro_codigo
FROM [dbo].[uaa] u
LEFT JOIN [dbo].[departamentos_programas_unificados] dpu 
    ON u.uaa_codigo = dpu.uaa_codigo_departamento;
GO

PRINT '¡Vistas de compatibilidad 03_compatibility_views desplegadas exitosamente!';
GO
