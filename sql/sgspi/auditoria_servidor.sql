-- Auditoría del servidor y de la base de datos para el esquema [sgspi] (T2, ISO/IEC 27001 A.8.15).
-- Se ejecuta fuera de DDL_SGSPI_SQLSERVER2019_v2.sql porque CREATE SERVER AUDIT no puede ir dentro de una transacción.
-- Requiere sysadmin y las variables de sqlcmd BD_SGSPI y RUTA_AUDITORIA (en SSMS, modo SQLCMD):
--   sqlcmd -S <servidor> -E -b -I -v BD_SGSPI=academia3000 RUTA_AUDITORIA="<carpeta fuera del alcance del DBA de la BD>" -i sql/sgspi/auditoria_servidor.sql
-- D10: con ON_FAILURE = FAIL_OPERATION, si la auditoría no puede escribir fallan las acciones auditadas en lugar de quedar
-- sin rastro (como el error 50017). Antes de que MAX_ROLLOVER_FILES borre un archivo, se copia a un almacenamiento fuera
-- del alcance del DBA, según la política institucional de retención.

USE master;
GO
CREATE SERVER AUDIT sgspi_auditoria
    TO FILE (FILEPATH = N'$(RUTA_AUDITORIA)', MAXSIZE = 256 MB, MAX_ROLLOVER_FILES = 100)
    WITH (ON_FAILURE = FAIL_OPERATION);
GO
ALTER SERVER AUDIT sgspi_auditoria WITH (STATE = ON);
GO
CREATE SERVER AUDIT SPECIFICATION sgspi_auditoria_servidor
    FOR SERVER AUDIT sgspi_auditoria
    ADD (SERVER_ROLE_MEMBER_CHANGE_GROUP),  -- altas y bajas en roles de servidor (sysadmin)
    ADD (AUDIT_CHANGE_GROUP)                -- cambios o apagado de la propia auditoría
    WITH (STATE = ON);
GO

USE $(BD_SGSPI);
GO
CREATE DATABASE AUDIT SPECIFICATION sgspi_auditoria_bd
    FOR SERVER AUDIT sgspi_auditoria
    ADD (SCHEMA_OBJECT_CHANGE_GROUP),             -- ALTER de tablas y triggers (incluye DISABLE/ENABLE TRIGGER)
    ADD (DATABASE_ROLE_MEMBER_CHANGE_GROUP),      -- altas y bajas en sgspi_rol_*
    ADD (DATABASE_PRINCIPAL_CHANGE_GROUP),        -- CREATE/ALTER/DROP USER y ROLE
    ADD (SCHEMA_OBJECT_PERMISSION_CHANGE_GROUP),  -- GRANT/DENY sobre objetos
    ADD (DATABASE_PERMISSION_CHANGE_GROUP),
    ADD (INSERT, UPDATE, DELETE ON SCHEMA::sgspi BY public),                -- incluye la carga histórica con triggers apagados
    ADD (INSERT, UPDATE, DELETE ON OBJECT::dbo.usuario_grupo BY public),    -- quién da grupo SGSPI_* y UAA (alcance, error 50021)
    ADD (INSERT, UPDATE, DELETE ON OBJECT::dbo.grupo BY public),
    ADD (SELECT ON OBJECT::sgspi.evento_incertidumbre_activo BY public),     -- lectura del mapa de vulnerabilidades
    ADD (SELECT ON OBJECT::sgspi.aud_evento_incertidumbre_activo BY public),
    ADD (SELECT ON OBJECT::sgspi.activo_informacion BY public),              -- lectura de activos con PII/reserva (Ley 1581 / Ley 1712)
    ADD (SELECT ON OBJECT::sgspi.aud_activo_informacion BY public)
    WITH (STATE = ON);
GO

-- Verificación tras probar DISABLE TRIGGER, ALTER ROLE ... ADD MEMBER, un alta en dbo.usuario_grupo y un SELECT de eia:
-- SELECT event_time, action_id, succeeded, server_principal_name, database_name, object_name, statement
-- FROM   sys.fn_get_audit_file(N'$(RUTA_AUDITORIA)\*.sqlaudit', DEFAULT, DEFAULT)
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
