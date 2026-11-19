-- Base desechable para desplegar DDL_SGSPI_SQLSERVER2019_v2.sql y correr PRUEBAS_DDL_SGSPI_v2.sql (ver especificación 12.3).
-- Solo para pruebas locales: BORRA y recrea la base sgspi_desechable. Nunca apuntarlo a academia3000.
-- Stubs mínimos de [dbo] con los tipos de sql/dbo/*.sql. usuario_general es tabla porque #sesion_como la actualiza
-- (en producción es la vista UNION de sql/dbo/vistas/usuario_general.sql). El login que ejecuta queda como persona 2.
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
    SET COMPATIBILITY_LEVEL = 150;

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
CREATE TABLE dbo.sede (
    sed_codigo INT          IDENTITY (1, 1) NOT NULL PRIMARY KEY,
    sed_nombre VARCHAR (50) NOT NULL
);

CREATE TABLE dbo.uaa (
    uaa_codigo INT           IDENTITY (1, 1) NOT NULL CONSTRAINT PK_uaa PRIMARY KEY NONCLUSTERED,
    uat_codigo INT           DEFAULT 1 NOT NULL,
    uaa_nombre VARCHAR (200) NOT NULL,
    uaa_estado INT           DEFAULT 1 NULL
);

CREATE TABLE dbo.cargo (
    car_codigo INT          IDENTITY (0, 1) NOT FOR REPLICATION NOT NULL CONSTRAINT PK_cargo PRIMARY KEY CLUSTERED,
    car_nombre VARCHAR (50) NOT NULL
);

CREATE TABLE dbo.persona (
    per_codigo         INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL CONSTRAINT PK_persona PRIMARY KEY NONCLUSTERED,
    per_identificacion VARCHAR (15)  NOT NULL,
    tii_codigo         INT           DEFAULT 1 NOT NULL,
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
    gru_estado INT           CONSTRAINT DF_grupo_gru_estado DEFAULT 1 NULL
);

CREATE TABLE dbo.usuario_grupo (
    usg_codigo  INT     IDENTITY (1, 1) NOT NULL CONSTRAINT PK_usuario_grupo PRIMARY KEY CLUSTERED,
    usg_usuario INT     NULL,
    usg_grupo   INT     NULL,
    usg_uaa     INT     NULL,
    usg_estado  TINYINT CONSTRAINT DF_usuario_grupo_usg_estado_1 DEFAULT 1 NULL
);

CREATE TABLE dbo.usuario_general (
    uid   INT           IDENTITY (1, 1) NOT NULL PRIMARY KEY,
    up    INT           NULL,
    us    VARCHAR (100) NOT NULL,
    state TINYINT       CONSTRAINT DF_usuario_general_state DEFAULT 1 NOT NULL
);

CREATE INDEX IX_usuario_general_us
    ON dbo.usuario_general(us);

CREATE INDEX IX_usuario_grupo_usg_usuario
    ON dbo.usuario_grupo(usg_usuario);

ALTER DATABASE sgspi_desechable
    MODIFY FILEGROUP FG_SGSPI_DATA DEFAULT;


GO
INSERT  dbo.sede (
    sed_nombre
)
VALUES           ('Neiva');

INSERT  dbo.uaa (
    uaa_nombre
)
VALUES          ('Oficina de Seguridad de la Información'),
                ('Facultad de Ingeniería');

INSERT  dbo.cargo (
    car_nombre
)
VALUES            ('Cargo 0'),
                  ('Profesional universitario');

INSERT  dbo.persona (
    per_identificacion,
    per_nombre,
    per_apellido
)
VALUES              ('1001', 'Persona', 'Uno'),
                    ('1002', 'Persona', 'Dos'),
                    ('1003', 'Persona', 'Tres');

INSERT  dbo.espacio (
    esp_nombre
)
VALUES              ('Centro de datos');

INSERT  dbo.sub_sede (
    sus_nombre,
    sed_codigo
)
VALUES               ('Sede central', 1);

INSERT  dbo.usuario_general (
    up,
    us
)
VALUES                      (2, CONVERT (VARCHAR (100), ORIGINAL_LOGIN()));