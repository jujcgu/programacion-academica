-- Base desechable para desplegar DDL_SGSPI_SQLSERVER2019_v2.sql y correr PRUEBAS_DDL_SGSPI_v2.sql (ver especificación 12.3).
-- Solo para pruebas locales: BORRA y recrea la base sgspi_desechable. Nunca apuntarlo a academia3000.
-- Replica el entorno real de academia3000: COMPATIBILITY_LEVEL = 100, RCSI activo, dbo.grupo (331/332),
-- dbo.tipo_id, dbo.sede, dbo.usuario_administrativos / dbo.usuario_docentes (uid INT NOT NULL, uwd2 VARBINARY(64))
-- y las 3 funciones escalares dbo.encriptarClaveReal, dbo.getTokenDocumento y token.getTokenInicioSesion.
USE master;

IF DB_ID(N'sgspi_desechable') IS NOT NULL
    BEGIN
        ALTER DATABASE sgspi_desechable
            SET SINGLE_USER 
            WITH ROLLBACK IMMEDIATE;
        DROP DATABASE sgspi_desechable;
    END

CREATE DATABASE sgspi_desechable COLLATE Modern_Spanish_CI_AS;

ALTER DATABASE sgspi_desechable
    SET COMPATIBILITY_LEVEL = 100;

ALTER DATABASE sgspi_desechable
    SET READ_COMMITTED_SNAPSHOT ON;

ALTER DATABASE sgspi_desechable
    ADD FILEGROUP FG_SGSPI_DATA;

ALTER DATABASE sgspi_desechable
    ADD FILEGROUP FG_SGSPI_AUD;

DECLARE @data_path AS NVARCHAR (512) = CONVERT (NVARCHAR (512), SERVERPROPERTY('InstanceDefaultDataPath'));

EXECUTE (N'ALTER DATABASE sgspi_desechable ADD FILE (NAME = N''sgspi_desechable_data'', FILENAME = N''' + @data_path + N'sgspi_desechable_data.ndf'', SIZE = 16MB, FILEGROWTH = 16MB) TO FILEGROUP FG_SGSPI_DATA;');

EXECUTE (N'ALTER DATABASE sgspi_desechable ADD FILE (NAME = N''sgspi_desechable_aud'', FILENAME = N''' + @data_path + N'sgspi_desechable_aud.ndf'', SIZE = 16MB, FILEGROWTH = 16MB) TO FILEGROUP FG_SGSPI_AUD;');


GO
USE sgspi_desechable;


GO
CREATE SCHEMA token AUTHORIZATION dbo;


GO
CREATE TABLE dbo.sede (
    sed_codigo INT          IDENTITY (1, 1) NOT NULL PRIMARY KEY,
    sed_nombre VARCHAR (50) NOT NULL
);

CREATE TABLE dbo.tipo_id (
    tii_codigo       INT          NOT NULL CONSTRAINT PK_tipo_id PRIMARY KEY CLUSTERED,
    tii_nombre       VARCHAR (50) NOT NULL,
    tii_nombre_corto VARCHAR (15) NOT NULL
);

CREATE TABLE dbo.uaa (
    uaa_codigo       INT           IDENTITY (1, 1) NOT NULL CONSTRAINT PK_uaa PRIMARY KEY NONCLUSTERED,
    uat_codigo       INT           DEFAULT 1 NOT NULL,
    uaa_nombre       VARCHAR (200) NOT NULL,
    uaa_nombre_corto VARCHAR (200) NULL,
    sed_codigo       INT           DEFAULT 1 NULL,
    uaa_estado       INT           DEFAULT 1 NULL
);

CREATE TABLE dbo.cargo (
    car_codigo INT          IDENTITY (0, 1) NOT FOR REPLICATION NOT NULL CONSTRAINT PK_cargo PRIMARY KEY CLUSTERED,
    car_nombre VARCHAR (50) NOT NULL
);

CREATE TABLE dbo.persona (
    per_codigo         INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL CONSTRAINT PK_persona PRIMARY KEY NONCLUSTERED,
    per_identificacion VARCHAR (15)  NOT NULL,
    tii_codigo         INT           DEFAULT 5 NOT NULL,
    per_apellido       VARCHAR (40)  NULL,
    per_nombre         VARCHAR (40)  NULL,
    per_email_interno  VARCHAR (100) NULL,
    per_estado         TINYINT       DEFAULT 1 NULL
);

CREATE TABLE dbo.espacio (
    esp_codigo INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL CONSTRAINT PK_espacios PRIMARY KEY NONCLUSTERED,
    esp_nombre VARCHAR (55) NOT NULL
);

CREATE TABLE dbo.sub_sede (
    sus_codigo INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL CONSTRAINT PK_sub_sede_1 PRIMARY KEY NONCLUSTERED,
    sus_nombre VARCHAR (50) NOT NULL,
    sed_codigo INT          NOT NULL
);

CREATE TABLE dbo.grupo (
    gru_codigo INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL CONSTRAINT PK_grupo PRIMARY KEY NONCLUSTERED,
    gru_nombre VARCHAR (100) NOT NULL,
    gru_id     VARCHAR (100) NULL,
    gru_estado INT           CONSTRAINT DF_grupo_gru_estado DEFAULT 1 NULL
);

CREATE TABLE dbo.usuario_grupo (
    usg_codigo  INT     IDENTITY (1, 1) NOT NULL CONSTRAINT PK_usuario_grupo PRIMARY KEY CLUSTERED,
    usg_usuario INT     NULL,
    usg_grupo   INT     NULL,
    usg_uaa     INT     NULL,
    usg_estado  TINYINT CONSTRAINT DF_usuario_grupo_usg_estado_1 DEFAULT 1 NULL
);

CREATE TABLE dbo.usuario_administrativos (
    uid              INT            NOT NULL CONSTRAINT PK_usuario_administrativos PRIMARY KEY CLUSTERED,
    up               INT            NULL,
    us               VARCHAR (20)   NULL,
    uwd_seguridadold VARCHAR (64)   NULL,
    uwd              VARBINARY (64) NULL,
    uwd2             VARBINARY (64) NULL,
    uwd_anterior     VARCHAR (64)   NULL,
    istipo           TINYINT        CONSTRAINT DF_usuario_administrativos_istipo DEFAULT 1 NULL,
    ischange         TINYINT        CONSTRAINT DF_usuario_administrativos_ischange DEFAULT 0 NULL,
    state            TINYINT        CONSTRAINT DF_usuario_administrativos_state DEFAULT 1 NULL,
    sys              VARCHAR (200)  NULL,
    us_correo        VARCHAR (100)  NULL,
    us_pregunta      VARCHAR (255)  NULL,
    us_respuesta     VARCHAR (255)  NULL,
    us_encriptado    VARBINARY (64) NULL
);

CREATE TABLE dbo.usuario_docentes (
    uid                    INT            NOT NULL CONSTRAINT PK_usuario_docentes PRIMARY KEY CLUSTERED,
    up                     INT            NULL,
    us                     VARCHAR (20)   NULL,
    uwd_seguridadold       VARCHAR (64)   NULL,
    uwd                    VARBINARY (64) NULL,
    uwd2                   VARBINARY (64) NULL,
    uwd_anterior           VARCHAR (64)   NULL,
    istipo                 TINYINT        CONSTRAINT DF_usuario_docentes_istipo DEFAULT 3 NULL,
    ischange               TINYINT        CONSTRAINT DF_usuario_docentes_ischange DEFAULT 0 NULL,
    state                  TINYINT        CONSTRAINT DF_usuario_docentes_state DEFAULT 1 NULL,
    sys                    VARCHAR (200)  NULL,
    us_correo              VARCHAR (100)  NULL,
    us_pregunta            VARCHAR (255)  NULL,
    us_respuesta           VARCHAR (255)  NULL,
    us_encriptado          VARBINARY (64) NULL,
    us_fecha_inactivacion  DATE           NULL,
    us_fecha_actualizacion DATETIME       NULL
);

CREATE INDEX PK_indice_us
    ON dbo.usuario_administrativos(us) INCLUDE (uid, up, sys, ischange, state, uwd2);

CREATE INDEX IX_usuario_administrativos_sys
    ON dbo.usuario_administrativos(sys) INCLUDE (uid, up, state);

CREATE INDEX PK_indice_us
    ON dbo.usuario_docentes(us) INCLUDE (uid, up, sys, ischange, state, uwd2);

CREATE INDEX IX_usuario_docentes_sys
    ON dbo.usuario_docentes(sys) INCLUDE (uid, up, state);

CREATE INDEX ind_usuario_grupo
    ON dbo.usuario_grupo(usg_usuario);

ALTER DATABASE sgspi_desechable
    MODIFY FILEGROUP FG_SGSPI_DATA DEFAULT;


GO
CREATE FUNCTION [dbo].[VarBinToHexStr]
(
    @varbin varbinary(64)
)
RETURNS VARCHAR(64)
AS
BEGIN
    DECLARE @hexstr varchar(8000), @hex char(2), @i int, @msc int, @lsc int, @count int
    SET @hexstr = '0x'
    SET @count = LEN(@varbin)
    SET @i = 1
    WHILE (@i <= @count)
    BEGIN
        SET @msc = FLOOR(CAST(SUBSTRING(@varbin, @i, 1) AS int) / 16)
        SET @lsc = CAST(SUBSTRING(@varbin, @i, 1) AS int) % 16
        SET @hexstr = @hexstr + CASE WHEN @msc >= 10 THEN CHAR(@msc + 55) ELSE CAST(@msc AS varchar(1)) END + CASE WHEN @lsc >= 10 THEN CHAR(@lsc + 55) ELSE CAST(@lsc AS varchar(1)) END
        SET @i = @i+1
    END
    RETURN @hexstr
END
GO

CREATE FUNCTION [dbo].[encriptarClaveReal]
(
    @clave_plana varchar(64)
)
RETURNS varchar(64)
AS
BEGIN
    DECLARE @claveReal varchar(64),
            @clavePlana varchar(64),
            @claveEncriptada varbinary(64),
            @antes varchar(4),
            @despues varchar(4)

    SELECT @antes = '16.3.2012:';
    SELECT @despues = 'Su;NA;mi;';

    SELECT @clavePlana = [dbo].[VarBinToHexStr](HASHBYTES('SHA1', @clave_plana));
    SELECT @claveEncriptada = HashBytes('MD5', @antes + @clavePlana + @despues)
    SELECT @claveReal = [dbo].[VarBinToHexStr](HASHBYTES('SHA1', @claveEncriptada));

    RETURN @claveReal
END
GO

CREATE FUNCTION [dbo].[getTokenDocumento](@atributos varchar(8000))
RETURNS varchar(100)
AS
BEGIN
    DECLARE @key varchar(64),
            @keyEncriptada varbinary(64),
            @antes varchar(4),
            @despues varchar(4),
            @fechaActual varchar(10),
            @token varchar(100)

    SELECT @key = 'Subir-Archivo123;..';
    SELECT @antes = 'Bv.,43lLjh';
    SELECT @despues = 'w7X;87Fir9,';

    SELECT @key = [dbo].[VarBinToHexStr](HASHBYTES('SHA1', @key));
    SELECT @keyEncriptada = HashBytes('MD5', @antes + @key + @despues)
    SELECT @key = [dbo].[VarBinToHexStr](HASHBYTES('SHA1', @keyEncriptada));

    SELECT @fechaActual = CONVERT(VARCHAR(10), getdate(), 105);
    SELECT @token = [dbo].[VarBinToHexStr](HASHBYTES('SHA1', @atributos+@fechaActual));

    RETURN @token;
END
GO

CREATE FUNCTION [token].[getTokenInicioSesion](@atributos varchar(8000))
RETURNS varchar(100)
AS
BEGIN
    DECLARE @key varchar(64),
            @keyEncriptada varbinary(64),
            @antes varchar(4),
            @despues varchar(4),
            @fechaActual varchar(10),
            @token varchar(100)

    SELECT @key = 'G3n3rar-codIGO;SESion..';
    SELECT @antes = 'Bv.,43lL.h..';
    SELECT @despues = 'w7X;87Fir9,';

    SELECT @key = [dbo].[VarBinToHexStr](HASHBYTES('SHA1', @key));
    SELECT @keyEncriptada = HashBytes('MD5', @antes + @key + @despues)
    SELECT @key = [dbo].[VarBinToHexStr](HASHBYTES('SHA1', @keyEncriptada));

    SELECT @fechaActual = CONVERT(VARCHAR(10), getdate(), 105);
    SELECT @token = [dbo].[VarBinToHexStr](HASHBYTES('SHA1', @atributos+@fechaActual));

    RETURN @token;
END
GO

INSERT  dbo.sede (
    sed_nombre
)
VALUES           ('NEIVA');

INSERT  dbo.tipo_id (
    tii_codigo,
    tii_nombre,
    tii_nombre_corto
)
VALUES              (1, 'DOCUMENTO', 'DOC'),
                    (5, 'CEDULA DE CIUDADANIA', 'C.C.');

INSERT  dbo.uaa (
    uaa_nombre,
    uaa_nombre_corto,
    sed_codigo
)
VALUES          ('Oficina de Seguridad de la Información', 'OFICINA DE SEGURIDAD DE LA INFORMACION', 1),
                ('Facultad de Ingeniería', 'FACULTAD DE INGENIERIA', 1);

INSERT  dbo.cargo (
    car_nombre
)
VALUES            ('Cargo 0'),
                  ('Profesional universitario');

INSERT  dbo.persona (
    per_identificacion,
    tii_codigo,
    per_nombre,
    per_apellido,
    per_email_interno
)
VALUES              ('1001', 5, 'Persona', 'Uno', 'persona1@usco.edu.co'),
                    ('1002', 5, 'Persona', 'Dos', 'persona2@usco.edu.co'),
                    ('1003', 5, 'Persona', 'Tres', 'persona3@usco.edu.co'),
                    ('1004', 5, 'Persona', 'Cuatro', 'persona4@usco.edu.co'),
                    ('1005', 5, 'Persona', 'Cinco', 'persona5@usco.edu.co');

INSERT  dbo.espacio (
    esp_nombre
)
VALUES              ('Centro de datos');

INSERT  dbo.sub_sede (
    sus_nombre,
    sed_codigo
)
VALUES               ('Sede central', 1);

SET IDENTITY_INSERT dbo.grupo ON;
INSERT  dbo.grupo (
    gru_codigo,
    gru_nombre,
    gru_id,
    gru_estado
)
VALUES            (331, 'SGSPI_Administrador', 'SGSPI_ADMINISTRADOR', 1),
                  (332, 'SGSPI_General', 'SGSPI_GENERAL', 1);
SET IDENTITY_INSERT dbo.grupo OFF;
DBCC CHECKIDENT ('dbo.grupo', RESEED, 388);

INSERT  dbo.usuario_administrativos (
    uid,
    up,
    us,
    sys,
    uwd2
)
VALUES                              (1, 2, 'admin_prueba', CONVERT (VARCHAR (200), ORIGINAL_LOGIN()), 0x5AE2BACFFEBDF3E8E37DECDD343AC728);

INSERT  dbo.usuario_docentes (
    uid,
    up,
    us,
    sys,
    uwd2
)
VALUES                       (22651, 3, 'docente_prueba', 'sys_docente_prueba', 0x5AE2BACFFEBDF3E8E37DECDD343AC728);
