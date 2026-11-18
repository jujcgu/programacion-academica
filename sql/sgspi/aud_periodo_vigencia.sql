-- 1. Tabla de auditoría (acrónimo [apv]): guarda las altas ('I') y la versión anterior ('U') con quién ejecutó la operación
CREATE TABLE sgspi.aud_periodo_vigencia (
    apv_codigo          INT                IDENTITY (1, 1) NOT NULL,
    pev_codigo          SMALLINT           NOT NULL,
    apv_anio            SMALLINT           NOT NULL,
    apv_fecha_apertura  DATE               NOT NULL,
    apv_fecha_cierre    DATE               NULL,
    apv_estado_vigencia NVARCHAR (20)      NOT NULL,
    apv_esta_activo     BIT                NOT NULL,
    per_codigo          INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    apv_operacion       CHAR (1)           CONSTRAINT DF_apv_operacion DEFAULT 'U' NOT NULL,
    apv_usuario_bd      SYSNAME            CONSTRAINT DF_apv_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    apv_fecha_cambio    DATETIMEOFFSET (0) CONSTRAINT DF_apv_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_apv_aud_periodo_vigencia PRIMARY KEY CLUSTERED (apv_codigo),
    CONSTRAINT FK_apv_periodo_vigencia FOREIGN KEY (pev_codigo) REFERENCES sgspi.periodo_vigencia (pev_codigo),
    CONSTRAINT FK_apv_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_apv_operacion CHECK (apv_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_apv_pev_codigo
    ON sgspi.aud_periodo_vigencia(pev_codigo, apv_fecha_cambio DESC);

CREATE NONCLUSTERED INDEX IX_apv_per_codigo
    ON sgspi.aud_periodo_vigencia(per_codigo);


GO
-- 2. Inmutabilidad de la auditoría: nadie puede borrar ni editar filas registradas
CREATE OR ALTER TRIGGER sgspi.TR_apv_inmutabilidad
    ON sgspi.aud_periodo_vigencia
    INSTEAD OF UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           THROW 50016, N'Operación denegada: la tabla de auditoría [sgspi].[aud_periodo_vigencia] es inmutable y no admite modificaciones ni borrados.', 1;
       END


GO
-- 3. Trigger en [sgspi].[periodo_vigencia]: bloquea DELETE físico y archiva altas ('I') y versión anterior ('U')
CREATE OR ALTER TRIGGER sgspi.TR_pev_auditoria
    ON sgspi.periodo_vigencia
    AFTER INSERT, UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           IF EXISTS (SELECT 1
                      FROM   deleted)
              AND NOT EXISTS (SELECT 1
                              FROM   inserted)
               THROW 50010, N'Operación denegada: No se permite eliminar físicamente periodos de vigencia en [sgspi].[periodo_vigencia].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           DECLARE @per_actor AS INT = (SELECT   TOP (1) u.up
                                        FROM     dbo.usuario_general AS u
                                        WHERE    u.us = ORIGINAL_LOGIN()
                                        ORDER BY u.uid);
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona en [dbo].[usuario_general] para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_periodo_vigencia (
                       pev_codigo,
                       apv_anio,
                       apv_fecha_apertura,
                       apv_fecha_cierre,
                       apv_estado_vigencia,
                       apv_esta_activo,
                       per_codigo,
                       apv_operacion,
                       apv_usuario_bd,
                       apv_fecha_cambio
                   )
                   SELECT i.pev_codigo,
                          i.pev_anio,
                          i.pev_fecha_apertura,
                          i.pev_fecha_cierre,
                          i.pev_estado_vigencia,
                          i.pev_esta_activo,
                          @per_actor,
                          'I',
                          ORIGINAL_LOGIN(),
                          SYSDATETIMEOFFSET()
                   FROM   inserted AS i;
                   RETURN;
               END
           INSERT INTO sgspi.aud_periodo_vigencia (
               pev_codigo,
               apv_anio,
               apv_fecha_apertura,
               apv_fecha_cierre,
               apv_estado_vigencia,
               apv_esta_activo,
               per_codigo,
               apv_operacion,
               apv_usuario_bd,
               apv_fecha_cambio
           )
           SELECT d.pev_codigo,
                  d.pev_anio,
                  d.pev_fecha_apertura,
                  d.pev_fecha_cierre,
                  d.pev_estado_vigencia,
                  d.pev_esta_activo,
                  @per_actor,
                  'U',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   deleted AS d
                  INNER JOIN
                  inserted AS i
                  ON i.pev_codigo = d.pev_codigo
           WHERE  EXISTS (SELECT i.pev_anio,
                                 i.pev_fecha_apertura,
                                 i.pev_fecha_cierre,
                                 i.pev_estado_vigencia,
                                 i.pev_esta_activo
                          EXCEPT
                          SELECT d.pev_anio,
                                 d.pev_fecha_apertura,
                                 d.pev_fecha_cierre,
                                 d.pev_estado_vigencia,
                                 d.pev_esta_activo);
       END


GO
-- 4. Permisos: solo lectura para usuarios; la inserción ocurre únicamente vía trigger por encadenamiento de propiedad (dbo)
DENY INSERT, UPDATE, DELETE, ALTER
    ON sgspi.aud_periodo_vigencia TO sgspi_rol_base;