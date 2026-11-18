-- Auditoría del servidor y de la base de datos para el esquema [sgspi] (T2, ISO/IEC 27001 A.8.15).
-- Se ejecuta fuera de DDL_SGSPI_SQLSERVER2019_v2.sql porque CREATE SERVER AUDIT no puede ir dentro de una transacción.

USE master;
GO
CREATE SERVER AUDIT sgspi_auditoria
    TO FILE (FILEPATH = N'<ruta fuera del alcance del DBA de la BD>', MAXSIZE = 256 MB, MAX_ROLLOVER_FILES = 100)
    WITH (ON_FAILURE = CONTINUE);
GO
ALTER SERVER AUDIT sgspi_auditoria WITH (STATE = ON);
GO

USE academia3000;
GO
CREATE DATABASE AUDIT SPECIFICATION sgspi_auditoria_bd
    FOR SERVER AUDIT sgspi_auditoria
    ADD (SCHEMA_OBJECT_CHANGE_GROUP),             -- ALTER de tablas y triggers (incluye DISABLE/ENABLE TRIGGER)
    ADD (DATABASE_ROLE_MEMBER_CHANGE_GROUP),      -- altas y bajas en sgspi_rol_*
    ADD (SCHEMA_OBJECT_PERMISSION_CHANGE_GROUP),  -- GRANT/DENY sobre objetos
    ADD (DATABASE_PERMISSION_CHANGE_GROUP),
    ADD (INSERT, UPDATE, DELETE ON SCHEMA::sgspi BY public)  -- incluye la carga histórica con triggers apagados
    WITH (STATE = ON);
GO

-- Verificación en la instancia tras probar DISABLE TRIGGER y ALTER ROLE ... ADD MEMBER:
-- SELECT event_time, action_id, succeeded, server_principal_name, object_name, statement
-- FROM   sys.fn_get_audit_file(N'<ruta fuera del alcance del DBA de la BD>\*.sqlaudit', DEFAULT, DEFAULT)
-- WHERE  database_name = N'academia3000'
-- ORDER BY event_time DESC;

-- Consultas de control tras una carga histórica con triggers deshabilitados (AP-04; todas deben devolver 0 filas):
-- 1) Registros en VIGENTE sin aprobador o con aprobador = creador:
SELECT 'acf' AS tabla, acf_codigo AS codigo FROM sgspi.analisis_contexto_factor WHERE acf_estado_registro = N'VIGENTE' AND (per_codigo_aprobador IS NULL OR per_codigo_aprobador = per_codigo_creador)
UNION ALL
SELECT 'rpi', rpi_codigo FROM sgspi.requisito_parte_interesada WHERE rpi_estado_registro = N'VIGENTE' AND (per_codigo_aprobador IS NULL OR per_codigo_aprobador = per_codigo_creador)
UNION ALL
SELECT 'aci', aci_codigo FROM sgspi.activo_informacion WHERE aci_estado_registro = N'VIGENTE' AND (per_codigo_aprobador IS NULL OR per_codigo_aprobador = per_codigo_creador);

-- 2) Activos en VIGENTE sin propietario activo, sin custodio activo o documentales sin aval de Archivo:
SELECT aci.aci_codigo
FROM   sgspi.activo_informacion AS aci
WHERE  aci.aci_estado_registro = N'VIGENTE'
       AND aci.aci_esta_activo = 1
       AND (NOT EXISTS (SELECT 1 FROM sgspi.activo_informacion_responsable AS air WHERE air.aci_codigo = aci.aci_codigo AND air.air_esta_activo = 1 AND air.air_tipo_responsabilidad = N'PROPIETARIO')
            OR NOT EXISTS (SELECT 1 FROM sgspi.activo_informacion_responsable AS air WHERE air.aci_codigo = aci.aci_codigo AND air.air_esta_activo = 1 AND air.air_tipo_responsabilidad = N'CUSTODIO')
            OR EXISTS (SELECT 1 FROM sgspi.activo_documental AS ado WHERE ado.ado_codigo = aci.aci_codigo AND ado.ado_esta_activo = 1 AND ado.per_codigo_revisor_archivo IS NULL));
