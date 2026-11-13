/*==================================================================================================
  PROYECTO:     Sistema de Gestión de Seguridad y Privacidad de la Información (SGSPI)
  ENTIDAD:      Universidad Surcolombiana (USCO)
  BASE DATOS:   Integrado con el esquema corporativo [dbo] de la USCO (academia3000)
  MOTOR BD:     Microsoft SQL Server 2019 (Compatibilidad 150)
  VERSIÓN:      2.0 — Refactorización de antipatrones (ver REGISTRO DE CAMBIOS al final de esta cabecera)
  CONVENCIÓN:   Estándar Institucional USCO (academia3000):
                1. Todas las llaves primarias y foráneas usan el sufijo [_codigo] (cero [_id]).
                2. Todas las columnas (incluidas llaves primarias, foráneas y de control) inician
                   estrictamente con el acrónimo de 3 letras de su tabla local ([<acr>_...]):
                   - Llave primaria: [<acr>_codigo]
                   - Llave foránea simple: [<acr_local>_<acr_remoto>_codigo] (ej. [acf_pev_codigo])
                   - Llave foránea con rol: [<acr_local>_<acr_remoto>_codigo_<rol>] (ej. [eia_aci_codigo_primario])
                3. Toda restricción tiene nombre explícito: PK_, FK_, UQ_/UX_, CK_ y DF_<columna>.

  MAPA DE ACRÓNIMOS DE TABLAS DEL ESQUEMA [sgspi] (53 TABLAS):
  - [pev] : sgspi.periodo_vigencia                  - [epc] : sgspi.estado_publicacion_catalogo
  - [efc] : sgspi.estado_flujo_catalogo (NUEVA)     - [tef] : sgspi.transicion_estado_flujo (NUEVA)
  - [dfc] : sgspi.dominio_formato_catalogo          - [src] : sgspi.soporte_registro_catalogo
  - [fdv] : sgspi.formato_documental_version        - [mcc] : sgspi.medio_conservacion_catalogo
  - [tpr] : sgspi.tipo_proceso_catalogo             - [idi] : sgspi.idioma_catalogo
  - [pri] : sgspi.proceso_institucional             - [fac] : sgspi.formato_archivo_catalogo (NUEVA)
  - [piu] : sgspi.proceso_institucional_uaa         - [ado] : sgspi.activo_documental (Subtipo 1:1 de [aci], PK compartida)
  - [fec] : sgspi.factor_entorno_catalogo           - [ads] : sgspi.activo_documental_soporte_registro
  - [acf] : sgspi.analisis_contexto_factor          - [adm] : sgspi.activo_documental_medio_conservacion
  - [pai] : sgspi.parte_interesada                  - [adi] : sgspi.activo_documental_idioma
  - [rpi] : sgspi.requisito_parte_interesada        - [adf] : sgspi.activo_documental_formato_archivo (NUEVA)
  - [rpc] : sgspi.requisito_parte_interesada_cuestionario - [adu] : sgspi.activo_documental_unidad_productora
  - [rpp] : sgspi.requisito_parte_interesada_proceso_institucional - [epr] : sgspi.escala_probabilidad
  - [tac] : sgspi.tipo_activo_catalogo              - [eim] : sgspi.escala_impacto
  - [cet] : sgspi.causal_excepcion_transparencia    - [zrc] : sgspi.zona_riesgo_catalogo (NUEVA)
  - [aci] : sgspi.activo_informacion (Supertipo)    - [mvr] : sgspi.matriz_valoracion_riesgo
  - [aip] : sgspi.activo_informacion_proceso_institucional - [eia] : sgspi.evento_incertidumbre_activo
  - [ais] : sgspi.activo_informacion_sede           - [etc] : sgspi.estrategia_tratamiento_catalogo
  - [air] : sgspi.activo_informacion_responsable    - [plt] : sgspi.plan_tratamiento
  - [sif] : sgspi.sistema_informacion_ficha         - [act] : sgspi.actividad_tratamiento
  - [msi] : sgspi.modulo_sistema_informacion        - [sga] : sgspi.seguimiento_actividad
  - [sdo] : sgspi.serie_documental_catalogo         - [enc] : sgspi.estandar_normativo_catalogo
  - [sbd] : sgspi.subserie_documental_catalogo      - [crn] : sgspi.control_referencia_normativa
  - [upc] : sgspi.unidad_productora_cuadro_clasificacion_documental - [aac] : sgspi.atributo_control_catalogo (NUEVA)
  - [pdc] : sgspi.periodicidad_catalogo             - [cra] : sgspi.control_referencia_normativa_atributo (NUEVA)
  - [ptc] : sgspi.plan_tratamiento_control_referencia_normativa - [eac] : sgspi.evaluacion_aplicabilidad_control
  - [bas] : sgspi.bitacora_auditoria_sistema
  ELIMINADAS: [cps] control_propiedad_seguridad y [ccc] control_concepto_ciberseguridad (absorbidas por [aac]/[cra]).

  ACRÓNIMOS REUTILIZADOS DEL ESQUEMA CORPORATIVO [dbo]:
  - [sus] : dbo.sub_sede ([sus_codigo])             - [car] : dbo.cargo ([car_codigo])
  - [esp] : dbo.espacio ([esp_codigo])              - [per] : dbo.persona ([per_codigo])
  - [uaa] : dbo.uaa ([uaa_codigo])                  - [gru] : dbo.grupo ([gru_codigo])
                                                    - [usg] : dbo.usuario_grupo ([usg_codigo])

  REGISTRO DE CAMBIOS v2.0 (cada cambio está marcado en el código con -- [AP-xx]):
  AP-01  Bitácora con cadena de hash SHA-256 almacenada (hash anterior + hash propio) calculada por un trigger
         INSTEAD OF INSERT serializado; antes el hash era una columna calculada que se recalculaba sola si la
         fila se alteraba. Verificación: EXEC sgspi.usp_verificar_cadena_bitacora.
  AP-02  Roles sgspi_rol_aplicacion / sgspi_rol_administrador con DENY UPDATE/DELETE/ALTER sobre la bitácora
         (ALTER es lo que habilita TRUNCATE y DISABLE TRIGGER).
  AP-03  Sin suplantación en auditoría: se exige contexto de sesión en TODA operación (también INSERT); se
         eliminan los COALESCE con creador/revisor/evaluador; la identidad de sesión es de solo lectura.
  AP-04  Todo registro nace en el estado inicial de su flujo (BORRADOR/PENDIENTE); rpi y aci ya no nacen
         VIGENTE. Carga histórica controlada: sgspi.usp_habilitar_carga_inicial.
  AP-05  Máquina de estados dirigida por datos: [efc] estados y [tef] transiciones reemplazan 5 CHECK de
         listas y 5 bloques de transiciones copiados en los triggers.
  AP-06  Integridad declarativa entre tablas: estrategia/naturaleza del evento, causal/nivel de reserva,
         nivel del padre en la taxonomía, componente afectado = categoría ISO 27005, serie con subseries.
  AP-07  Atributos ISO/IEC 27002:2022 normalizados ([aac]/[cra]) en vez de texto multivaluado.
  AP-08  Enumeraciones libres reemplazadas por catálogo o CHECK ([fac]/[adf], eia_tac_codigo_componente,
         sif_modalidad_desarrollo); se elimina ado_tipo_activo_documental (redundante con aci_tac_codigo).
  AP-09  Sin dependencias transitivas ni datos derivados sueltos: [zrc], mvr_codigo_posicion calculada,
         letra de probabilidad coherente, avance de actividad sincronizado desde [sga], UAA líder única.
  AP-10  [ado] usa PK compartida con [aci] (ado_codigo = aci_codigo).
  AP-11  Se eliminan *_fecha_actualizacion de las tablas temporales (nunca se actualizaban).
  AP-12  Marcas de auditoría en DATETIMEOFFSET(0) (bitácora y SYSTEM_TIME siguen en UTC).
  AP-13  Valores normalizados (PUBLICA, NO_CLASIFICADA, ...) y vistas filtradas por enc_familia_norma.
  AP-14  Claves naturales con UNIQUE (pri, cet, msi, act).
  AP-15  Segregación de funciones: aprobador/firmantes distintos del creador; aprobador obligatorio en
         estados aprobados; rpi gana creador y aprobador.
  AP-16  Coherencia de eficacia del plan, KPI sin desborde, evidencia con formato y seguimiento append-only.
  AP-17  Todos los DEFAULT con nombre DF_<columna>.
  AP-18  Índices redundantes eliminados, INCLUDE de claves clustered retirados, índice para FK compuesta.
  AP-19  Verificación previa: el script se detiene sin cambios si [sgspi] ya tiene tablas o faltan
         dependencias de [dbo].
  AP-20  GROUPING() en lugar de ISNULL para rotular subtotales.
  AP-21  Contexto de auditoría y hash centralizados en funciones reutilizadas por todos los triggers.
==================================================================================================*/
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;
SET XACT_ABORT ON;


GO
/*==================================================================================================
  0. VERIFICACIÓN PREVIA DE DESPLIEGUE [AP-19]
     Si algo falla, SET NOEXEC ON hace que el resto del script se compile pero NO se ejecute, de modo que
     nunca queda un despliegue a medias. El script termina con SET NOEXEC OFF.
==================================================================================================*/
DECLARE @errores NVARCHAR (2000) = N'';

IF CONVERT (INT, (SELECT compatibility_level FROM sys.databases WHERE database_id = DB_ID())) < 150
    SET @errores += N' La base de datos debe tener nivel de compatibilidad 150 o superior.';

IF EXISTS (SELECT 1
           FROM   sys.tables AS t
                  INNER JOIN sys.schemas AS s ON s.schema_id = t.schema_id
           WHERE  s.name = N'sgspi')
    SET @errores += N' El esquema [sgspi] ya contiene tablas: este script es de creación inicial; use un script de migración.';

DECLARE @dependencias TABLE (tabla SYSNAME, columna SYSNAME);
INSERT INTO @dependencias (tabla, columna)
VALUES (N'dbo.uaa', N'uaa_codigo'), (N'dbo.uaa', N'uaa_nombre'),
       (N'dbo.cargo', N'car_codigo'), (N'dbo.cargo', N'car_nombre'),
       (N'dbo.persona', N'per_codigo'), (N'dbo.persona', N'per_identificacion'), (N'dbo.persona', N'per_nombre'),
       (N'dbo.persona', N'per_apellido'), (N'dbo.persona', N'per_email_interno'),
       (N'dbo.espacio', N'esp_codigo'), (N'dbo.sub_sede', N'sus_codigo'),
       (N'dbo.grupo', N'gru_codigo'), (N'dbo.grupo', N'gru_nombre'), (N'dbo.grupo', N'gru_estado'),
       (N'dbo.usuario_grupo', N'usg_codigo'), (N'dbo.usuario_grupo', N'usg_grupo'), (N'dbo.usuario_grupo', N'usg_uaa'),
       (N'dbo.usuario_grupo', N'usg_usuario'), (N'dbo.usuario_grupo', N'usg_estado'),
       (N'dbo.usuario_general', N'uid'), (N'dbo.usuario_general', N'up');

DECLARE @faltantes NVARCHAR (1000) = (SELECT STRING_AGG(CONCAT(tabla, N'.', columna), N', ')
                                      FROM   @dependencias
                                      WHERE  COL_LENGTH(tabla, columna) IS NULL);
IF @faltantes IS NOT NULL
    SET @errores += N' Faltan dependencias del esquema corporativo: ' + @faltantes + N'.';

IF LEN(@errores) > 0
    BEGIN
        RAISERROR (N'DESPLIEGUE SGSPI DETENIDO SIN CAMBIOS:%s', 16, 1, @errores);
        SET NOEXEC ON;
    END


GO
IF NOT EXISTS (SELECT 1
               FROM   sys.schemas
               WHERE  name = N'sgspi')
    BEGIN
        EXECUTE (N'CREATE SCHEMA sgspi AUTHORIZATION dbo;');
    END


GO
/*==================================================================================================
  1. DOMINIO TRANSVERSAL, GOBERNANZA SGC Y ARTICULACIÓN CON [dbo]
==================================================================================================*/
-- 1.1 [pev] Periodos de Vigencia Anual del SGSPI
CREATE TABLE sgspi.periodo_vigencia (
    pev_codigo          SMALLINT      IDENTITY (1, 1) NOT NULL,
    pev_anio            SMALLINT      NOT NULL,
    pev_fecha_apertura  DATE          NOT NULL,
    pev_fecha_cierre    DATE          NULL,
    pev_estado_vigencia NVARCHAR (20) CONSTRAINT DF_pev_estado_vigencia DEFAULT N'ABIERTA' NOT NULL, -- [AP-17] DEFAULT con nombre
    pev_fecha_creacion  DATETIMEOFFSET (0) CONSTRAINT DF_pev_fecha_creacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17] Zona horaria explícita
    CONSTRAINT PK_pev_periodo_vigencia PRIMARY KEY CLUSTERED (pev_codigo),
    CONSTRAINT UQ_pev_anio UNIQUE (pev_anio),
    CONSTRAINT CK_pev_estado_vigencia CHECK (pev_estado_vigencia IN (N'EN_CONFIGURACION', N'ABIERTA', N'CERRADA', N'HISTORICA')),
    CONSTRAINT CK_pev_fechas CHECK (pev_fecha_cierre IS NULL
                                    OR pev_fecha_cierre >= pev_fecha_apertura)
);

-- 1.1b [efc] y [tef] Máquina de Estados Dirigida por Datos (Estados y Transiciones Válidas por Dominio de Flujo)
-- [AP-05] Reemplaza los CHECK de lista de estados y las transiciones codificadas en los triggers de acf, rpi, aci, eia y act
CREATE TABLE sgspi.estado_flujo_catalogo (
    efc_codigo          SMALLINT      IDENTITY (1, 1) NOT NULL,
    efc_dominio         NVARCHAR (10) NOT NULL, -- 'ACF', 'RPI', 'ACI', 'EIA', 'ACT'
    efc_identificador   NVARCHAR (30) NOT NULL, -- 'BORRADOR', 'VIGENTE', ...
    efc_nombre          NVARCHAR (80) NOT NULL,
    efc_es_inicial      BIT           CONSTRAINT DF_efc_es_inicial DEFAULT 0 NOT NULL, -- Único estado permitido en INSERT
    efc_permite_edicion BIT           CONSTRAINT DF_efc_permite_edicion DEFAULT 1 NOT NULL, -- 0: no se pueden editar datos sin cambiar de estado
    efc_esta_activo     BIT           CONSTRAINT DF_efc_esta_activo DEFAULT 1 NOT NULL,
    CONSTRAINT PK_efc_estado_flujo_catalogo PRIMARY KEY CLUSTERED (efc_codigo),
    CONSTRAINT UQ_efc_dominio_identificador UNIQUE (efc_dominio, efc_identificador),
    CONSTRAINT CK_efc_dominio CHECK (efc_dominio IN (N'ACF', N'RPI', N'ACI', N'EIA', N'ACT'))
);

-- Un único estado inicial por dominio de flujo
CREATE UNIQUE NONCLUSTERED INDEX UX_efc_estado_inicial
    ON sgspi.estado_flujo_catalogo (efc_dominio)
    WHERE efc_es_inicial = 1;

CREATE TABLE sgspi.transicion_estado_flujo (
    tef_codigo                    SMALLINT      IDENTITY (1, 1) NOT NULL,
    tef_efc_dominio               NVARCHAR (10) NOT NULL,
    tef_efc_identificador_origen  NVARCHAR (30) NOT NULL,
    tef_efc_identificador_destino NVARCHAR (30) NOT NULL,
    tef_accion_bitacora           NVARCHAR (30) CONSTRAINT DF_tef_accion_bitacora DEFAULT N'TRANSICION_ESTADO' NOT NULL,
    CONSTRAINT PK_tef_transicion_estado_flujo PRIMARY KEY CLUSTERED (tef_codigo),
    CONSTRAINT UQ_tef_dominio_origen_destino UNIQUE (tef_efc_dominio, tef_efc_identificador_origen, tef_efc_identificador_destino),
    CONSTRAINT FK_tef_estado_origen FOREIGN KEY (tef_efc_dominio, tef_efc_identificador_origen) REFERENCES sgspi.estado_flujo_catalogo (efc_dominio, efc_identificador),
    CONSTRAINT FK_tef_estado_destino FOREIGN KEY (tef_efc_dominio, tef_efc_identificador_destino) REFERENCES sgspi.estado_flujo_catalogo (efc_dominio, efc_identificador),
    CONSTRAINT CK_tef_origen_distinto_destino CHECK (tef_efc_identificador_origen <> tef_efc_identificador_destino),
    CONSTRAINT CK_tef_accion_bitacora CHECK (tef_accion_bitacora IN (N'TRANSICION_ESTADO', N'APROBAR', N'OBSERVAR'))
);

CREATE NONCLUSTERED INDEX IX_tef_estado_destino
    ON sgspi.transicion_estado_flujo (tef_efc_dominio, tef_efc_identificador_destino);

-- Semilla de estados y transiciones de todos los dominios de flujo
GO
-- [AP-05] Estados (se toman de los CHECK y triggers originales)
INSERT INTO sgspi.estado_flujo_catalogo (efc_dominio, efc_identificador, efc_nombre, efc_es_inicial, efc_permite_edicion)
SELECT v.dominio, v.identificador, v.nombre, v.es_inicial, v.permite_edicion
FROM (VALUES
    -- ACF: Análisis de Contexto de Factores
    (N'ACF', N'BORRADOR',            N'Borrador',                      1, 1),
    (N'ACF', N'EN_VALIDACION_LIDER', N'En validación del líder',       0, 1),
    (N'ACF', N'EN_REVISION_SGSPI',   N'En revisión SGSPI',             0, 1),
    (N'ACF', N'OBSERVADO',           N'Observado',                     0, 1),
    (N'ACF', N'VIGENTE',             N'Vigente',                       0, 0),
    (N'ACF', N'HISTORICO',           N'Histórico',                     0, 0),
    -- RPI: Requisitos de Partes Interesadas
    (N'RPI', N'BORRADOR',            N'Borrador',                      1, 1),
    (N'RPI', N'EN_VALIDACION_LIDER', N'En validación del líder',       0, 1),
    (N'RPI', N'EN_REVISION_SGSPI',   N'En revisión SGSPI',             0, 1),
    (N'RPI', N'OBSERVADO',           N'Observado',                     0, 1),
    (N'RPI', N'VIGENTE',             N'Vigente',                       0, 0),
    (N'RPI', N'HISTORICO',           N'Histórico',                     0, 0),
    -- ACI: Activos de Información
    (N'ACI', N'BORRADOR',            N'Borrador',                      1, 1),
    (N'ACI', N'EN_VALIDACION_LIDER', N'En validación del líder',       0, 1),
    (N'ACI', N'EN_REVISION_ARCHIVO', N'En revisión de Archivo',        0, 1),
    (N'ACI', N'EN_REVISION_SGSPI',   N'En revisión SGSPI',             0, 1),
    (N'ACI', N'OBSERVADO',           N'Observado',                     0, 1),
    (N'ACI', N'VIGENTE',             N'Vigente',                       0, 0),
    (N'ACI', N'INACTIVO',            N'Inactivo',                      0, 1),
    (N'ACI', N'HISTORICO',           N'Histórico',                     0, 0),
    -- EIA: Eventos de Incertidumbre sobre Activos
    (N'EIA', N'BORRADOR',               N'Borrador',                       1, 1),
    (N'EIA', N'EN_VALIDACION_LIDER',    N'En validación del líder',        0, 1),
    (N'EIA', N'EN_REVISION_SGSPI',      N'En revisión SGSPI',              0, 1),
    (N'EIA', N'OBSERVADO',              N'Observado',                      0, 1),
    (N'EIA', N'EN_ACEPTACION_COMITE',   N'En aceptación del comité',       0, 1),
    (N'EIA', N'APROBADO_PLANIFICADO',   N'Aprobado y planificado',         0, 1),
    (N'EIA', N'EN_EJECUCION',           N'En ejecución',                   0, 1),
    (N'EIA', N'EN_EVALUACION_EFICACIA', N'En evaluación de eficacia',      0, 1),
    (N'EIA', N'CERRADO_EFICAZ',         N'Cerrado eficaz',                 0, 0),
    (N'EIA', N'HISTORICO',              N'Histórico',                      0, 0),
    -- ACT: Actividades de Tratamiento
    (N'ACT', N'PENDIENTE',           N'Pendiente',                     1, 1),
    (N'ACT', N'EN_CURSO',            N'En curso',                      0, 1),
    (N'ACT', N'COMPLETADA',          N'Completada',                    0, 0),
    (N'ACT', N'OBSERVADA',           N'Observada',                     0, 1)
) AS v (dominio, identificador, nombre, es_inicial, permite_edicion);

-- [AP-05] Transiciones válidas (se toman de los triggers originales); la acción de bitácora replica los CASE originales
INSERT INTO sgspi.transicion_estado_flujo (tef_efc_dominio, tef_efc_identificador_origen, tef_efc_identificador_destino, tef_accion_bitacora)
SELECT v.dominio, v.origen, v.destino, v.accion
FROM (VALUES
    -- ACF
    (N'ACF', N'BORRADOR',            N'EN_VALIDACION_LIDER', N'TRANSICION_ESTADO'),
    (N'ACF', N'EN_VALIDACION_LIDER', N'EN_REVISION_SGSPI',   N'TRANSICION_ESTADO'),
    (N'ACF', N'EN_VALIDACION_LIDER', N'OBSERVADO',           N'OBSERVAR'),
    (N'ACF', N'EN_VALIDACION_LIDER', N'BORRADOR',            N'TRANSICION_ESTADO'),
    (N'ACF', N'EN_REVISION_SGSPI',   N'VIGENTE',             N'APROBAR'),
    (N'ACF', N'EN_REVISION_SGSPI',   N'OBSERVADO',           N'OBSERVAR'),
    (N'ACF', N'OBSERVADO',           N'BORRADOR',            N'TRANSICION_ESTADO'),
    (N'ACF', N'OBSERVADO',           N'EN_VALIDACION_LIDER', N'TRANSICION_ESTADO'),
    (N'ACF', N'VIGENTE',             N'HISTORICO',           N'TRANSICION_ESTADO'),
    (N'ACF', N'VIGENTE',             N'EN_REVISION_SGSPI',   N'TRANSICION_ESTADO'),
    -- RPI
    (N'RPI', N'BORRADOR',            N'EN_VALIDACION_LIDER', N'TRANSICION_ESTADO'),
    (N'RPI', N'EN_VALIDACION_LIDER', N'EN_REVISION_SGSPI',   N'TRANSICION_ESTADO'),
    (N'RPI', N'EN_VALIDACION_LIDER', N'OBSERVADO',           N'OBSERVAR'),
    (N'RPI', N'EN_VALIDACION_LIDER', N'BORRADOR',            N'TRANSICION_ESTADO'),
    (N'RPI', N'EN_REVISION_SGSPI',   N'VIGENTE',             N'APROBAR'),
    (N'RPI', N'EN_REVISION_SGSPI',   N'OBSERVADO',           N'OBSERVAR'),
    (N'RPI', N'OBSERVADO',           N'BORRADOR',            N'TRANSICION_ESTADO'),
    (N'RPI', N'OBSERVADO',           N'EN_VALIDACION_LIDER', N'TRANSICION_ESTADO'),
    (N'RPI', N'VIGENTE',             N'HISTORICO',           N'TRANSICION_ESTADO'),
    (N'RPI', N'VIGENTE',             N'EN_REVISION_SGSPI',   N'TRANSICION_ESTADO'),
    -- ACI
    (N'ACI', N'BORRADOR',            N'EN_VALIDACION_LIDER', N'TRANSICION_ESTADO'),
    (N'ACI', N'EN_VALIDACION_LIDER', N'EN_REVISION_ARCHIVO', N'TRANSICION_ESTADO'),
    (N'ACI', N'EN_VALIDACION_LIDER', N'EN_REVISION_SGSPI',   N'TRANSICION_ESTADO'),
    (N'ACI', N'EN_VALIDACION_LIDER', N'OBSERVADO',           N'OBSERVAR'),
    (N'ACI', N'EN_VALIDACION_LIDER', N'BORRADOR',            N'TRANSICION_ESTADO'),
    (N'ACI', N'EN_REVISION_ARCHIVO', N'EN_REVISION_SGSPI',   N'TRANSICION_ESTADO'),
    (N'ACI', N'EN_REVISION_ARCHIVO', N'OBSERVADO',           N'OBSERVAR'),
    (N'ACI', N'EN_REVISION_SGSPI',   N'VIGENTE',             N'APROBAR'),
    (N'ACI', N'EN_REVISION_SGSPI',   N'OBSERVADO',           N'OBSERVAR'),
    (N'ACI', N'OBSERVADO',           N'BORRADOR',            N'TRANSICION_ESTADO'),
    (N'ACI', N'OBSERVADO',           N'EN_VALIDACION_LIDER', N'TRANSICION_ESTADO'),
    (N'ACI', N'VIGENTE',             N'INACTIVO',            N'TRANSICION_ESTADO'),
    (N'ACI', N'VIGENTE',             N'HISTORICO',           N'TRANSICION_ESTADO'),
    (N'ACI', N'VIGENTE',             N'EN_REVISION_SGSPI',   N'TRANSICION_ESTADO'),
    (N'ACI', N'VIGENTE',             N'EN_REVISION_ARCHIVO', N'TRANSICION_ESTADO'),
    (N'ACI', N'INACTIVO',            N'VIGENTE',             N'APROBAR'),
    (N'ACI', N'INACTIVO',            N'HISTORICO',           N'TRANSICION_ESTADO'),
    -- EIA
    (N'EIA', N'BORRADOR',               N'EN_VALIDACION_LIDER',    N'TRANSICION_ESTADO'),
    (N'EIA', N'EN_VALIDACION_LIDER',    N'EN_REVISION_SGSPI',      N'TRANSICION_ESTADO'),
    (N'EIA', N'EN_VALIDACION_LIDER',    N'OBSERVADO',              N'OBSERVAR'),
    (N'EIA', N'EN_VALIDACION_LIDER',    N'BORRADOR',               N'TRANSICION_ESTADO'),
    (N'EIA', N'EN_REVISION_SGSPI',      N'EN_ACEPTACION_COMITE',   N'TRANSICION_ESTADO'),
    (N'EIA', N'EN_REVISION_SGSPI',      N'APROBADO_PLANIFICADO',   N'APROBAR'),
    (N'EIA', N'EN_REVISION_SGSPI',      N'OBSERVADO',              N'OBSERVAR'),
    (N'EIA', N'EN_ACEPTACION_COMITE',   N'APROBADO_PLANIFICADO',   N'APROBAR'),
    (N'EIA', N'EN_ACEPTACION_COMITE',   N'OBSERVADO',              N'OBSERVAR'),
    (N'EIA', N'OBSERVADO',              N'BORRADOR',               N'TRANSICION_ESTADO'),
    (N'EIA', N'OBSERVADO',              N'EN_VALIDACION_LIDER',    N'TRANSICION_ESTADO'),
    (N'EIA', N'APROBADO_PLANIFICADO',   N'EN_EJECUCION',           N'TRANSICION_ESTADO'),
    (N'EIA', N'APROBADO_PLANIFICADO',   N'OBSERVADO',              N'OBSERVAR'),
    (N'EIA', N'EN_EJECUCION',           N'EN_EVALUACION_EFICACIA', N'TRANSICION_ESTADO'),
    (N'EIA', N'EN_EJECUCION',           N'OBSERVADO',              N'OBSERVAR'),
    (N'EIA', N'EN_EVALUACION_EFICACIA', N'CERRADO_EFICAZ',         N'APROBAR'),
    (N'EIA', N'EN_EVALUACION_EFICACIA', N'EN_EJECUCION',           N'TRANSICION_ESTADO'),
    (N'EIA', N'EN_EVALUACION_EFICACIA', N'OBSERVADO',              N'OBSERVAR'),
    (N'EIA', N'CERRADO_EFICAZ',         N'HISTORICO',              N'TRANSICION_ESTADO'),
    -- ACT
    (N'ACT', N'PENDIENTE',  N'EN_CURSO',   N'TRANSICION_ESTADO'),
    (N'ACT', N'PENDIENTE',  N'OBSERVADA',  N'OBSERVAR'),
    (N'ACT', N'EN_CURSO',   N'COMPLETADA', N'APROBAR'),
    (N'ACT', N'EN_CURSO',   N'OBSERVADA',  N'OBSERVAR'),
    (N'ACT', N'OBSERVADA',  N'PENDIENTE',  N'TRANSICION_ESTADO'),
    (N'ACT', N'OBSERVADA',  N'EN_CURSO',   N'TRANSICION_ESTADO'),
    (N'ACT', N'COMPLETADA', N'OBSERVADA',  N'OBSERVAR')
) AS v (dominio, origen, destino, accion);
GO

-- 1.2 [dfc] y [fdv] Catálogo Extensible de Dominios de Formato y Control de Versiones SGC/SGSPI por Vigencia
CREATE TABLE sgspi.dominio_formato_catalogo (
    dfc_codigo        SMALLINT       IDENTITY (1, 1) NOT NULL,
    dfc_identificador NVARCHAR (40)  NOT NULL, -- Ej: 'CONTEXTO_DOFA', 'PARTES_INTERESADAS', 'ACTIVOS_DOCUMENTALES', 'INVENTARIO_ACTIVOS', 'RIESGOS_Y_OPORTUNIDADES'
    dfc_nombre        NVARCHAR (120) NOT NULL,
    dfc_descripcion   NVARCHAR (255) NULL,
    dfc_esta_activo   BIT            CONSTRAINT DF_dfc_esta_activo DEFAULT 1 NOT NULL, -- [AP-17]
    CONSTRAINT PK_dfc_dominio_formato_catalogo PRIMARY KEY CLUSTERED (dfc_codigo),
    CONSTRAINT UQ_dfc_identificador UNIQUE (dfc_identificador),
    CONSTRAINT UQ_dfc_nombre UNIQUE (dfc_nombre),
    CONSTRAINT CK_dfc_identificador_no_vacio CHECK (LEN(TRIM(dfc_identificador)) > 0)
);

CREATE TABLE sgspi.formato_documental_version (
    fdv_codigo                 SMALLINT       IDENTITY (1, 1) NOT NULL,
    fdv_pev_codigo             SMALLINT       NOT NULL, -- FK a [sgspi].[periodo_vigencia]([pev_codigo])
    fdv_dfc_codigo             SMALLINT       NOT NULL, -- FK a [sgspi].[dominio_formato_catalogo]([dfc_codigo])
    fdv_codigo_formato         NVARCHAR (20)  NOT NULL, -- 'ES-GSPI-MR-01', 'ES-GSPI-MR-03', 'ES-GSPI-MR-04', 'ES-GSPI-MR-05', 'ES-GSPI-MR-06'
    fdv_numero_version         NVARCHAR (10)  NOT NULL, -- '02', '04', '01', '01', '02'
    fdv_nombre_oficial_formato NVARCHAR (200) NOT NULL,
    fdv_fecha_emision_formato  DATE           NULL,
    fdv_es_version_activa      BIT            CONSTRAINT DF_fdv_es_version_activa DEFAULT 1 NOT NULL, -- [AP-17]
    CONSTRAINT PK_fdv_formato_documental_version PRIMARY KEY CLUSTERED (fdv_codigo),
    CONSTRAINT UQ_fdv_vigencia_dominio UNIQUE (fdv_pev_codigo, fdv_dfc_codigo),
    CONSTRAINT FK_fdv_periodo_vigencia FOREIGN KEY (fdv_pev_codigo) REFERENCES sgspi.periodo_vigencia (pev_codigo),
    CONSTRAINT FK_fdv_dominio_formato FOREIGN KEY (fdv_dfc_codigo) REFERENCES sgspi.dominio_formato_catalogo (dfc_codigo),
    CONSTRAINT CK_fdv_codigo_formato_no_vacio CHECK (LEN(TRIM(fdv_codigo_formato)) > 0) -- [AP-14] Código de formato no vacío
);

CREATE NONCLUSTERED INDEX IX_fdv_dfc_codigo
    ON sgspi.formato_documental_version (fdv_dfc_codigo);

-- 1.3 [tpr] Catálogo Extensible de Tipos de Proceso del Sistema Integrado de Gestión (MIPG / SGC)
CREATE TABLE sgspi.tipo_proceso_catalogo (
    tpr_codigo        TINYINT        IDENTITY (1, 1) NOT NULL,
    tpr_identificador NVARCHAR (20)  NOT NULL,
    tpr_nombre        NVARCHAR (50)  NOT NULL, -- Ej: 'ESTRATÉGICO', 'MISIONAL', 'APOYO', 'EVALUACIÓN'
    tpr_descripcion   NVARCHAR (255) NULL,
    tpr_esta_activo   BIT            CONSTRAINT DF_tpr_esta_activo DEFAULT 1 NOT NULL, -- [AP-17]
    CONSTRAINT PK_tpr_tipo_proceso_catalogo PRIMARY KEY CLUSTERED (tpr_codigo),
    CONSTRAINT UQ_tpr_identificador UNIQUE (tpr_identificador),
    CONSTRAINT UQ_tpr_nombre UNIQUE (tpr_nombre),
    CONSTRAINT CK_tpr_nombre_no_vacio CHECK (LEN(TRIM(tpr_nombre)) > 0)
);

-- 1.4 [pri] Procesos Institucionales (Los 21 procesos del SGC / SGSPI USCO)
CREATE TABLE sgspi.proceso_institucional (
    pri_codigo           INT            IDENTITY (1, 1) NOT NULL,
    pri_identificador    NVARCHAR (20)  NOT NULL,
    pri_nombre           NVARCHAR (150) NOT NULL,
    pri_tpr_codigo       TINYINT        NOT NULL, -- FK a [sgspi].[tipo_proceso_catalogo]([tpr_codigo])
    pri_uaa_codigo_lider INT            NULL, -- FK a [dbo].[uaa]([uaa_codigo])
    pri_car_codigo_lider INT            NULL, -- FK a [dbo].[cargo]([car_codigo])
    pri_esta_activo      BIT            CONSTRAINT DF_pri_esta_activo DEFAULT 1 NOT NULL, -- [AP-17]
    CONSTRAINT PK_pri_proceso_institucional PRIMARY KEY CLUSTERED (pri_codigo),
    CONSTRAINT UQ_pri_identificador UNIQUE (pri_identificador), -- [AP-14] Clave natural con UNIQUE
    CONSTRAINT UQ_pri_nombre UNIQUE (pri_nombre),
    CONSTRAINT FK_pri_tipo_proceso FOREIGN KEY (pri_tpr_codigo) REFERENCES sgspi.tipo_proceso_catalogo (tpr_codigo),
    CONSTRAINT FK_pri_dbo_uaa_lider FOREIGN KEY (pri_uaa_codigo_lider) REFERENCES dbo.uaa (uaa_codigo),
    CONSTRAINT FK_pri_dbo_cargo_lider FOREIGN KEY (pri_car_codigo_lider) REFERENCES dbo.cargo (car_codigo),
    CONSTRAINT CK_pri_identificador_no_vacio CHECK (LEN(TRIM(pri_identificador)) > 0) -- [AP-14]
);

CREATE NONCLUSTERED INDEX IX_pri_tpr_codigo
    ON sgspi.proceso_institucional (pri_tpr_codigo);
CREATE NONCLUSTERED INDEX IX_pri_uaa_codigo_lider
    ON sgspi.proceso_institucional (pri_uaa_codigo_lider);
CREATE NONCLUSTERED INDEX IX_pri_car_codigo_lider
    ON sgspi.proceso_institucional (pri_car_codigo_lider);

-- 1.5 [piu] Tabla Puente N:M Proceso Institucional <-> Unidades Académico-Administrativas ([dbo].[uaa])
-- [AP-09] Se elimina piu_es_responsable_principal: la UAA líder del proceso es [pri_uaa_codigo_lider] (una sola fuente de verdad)
CREATE TABLE sgspi.proceso_institucional_uaa (
    piu_pri_codigo INT NOT NULL, -- FK a [sgspi].[proceso_institucional]([pri_codigo])
    piu_uaa_codigo INT NOT NULL, -- FK a [dbo].[uaa]([uaa_codigo])
    CONSTRAINT PK_piu_proceso_institucional_uaa PRIMARY KEY CLUSTERED (piu_pri_codigo, piu_uaa_codigo),
    CONSTRAINT FK_piu_proceso_institucional FOREIGN KEY (piu_pri_codigo) REFERENCES sgspi.proceso_institucional (pri_codigo) ON DELETE CASCADE,
    CONSTRAINT FK_piu_dbo_uaa FOREIGN KEY (piu_uaa_codigo) REFERENCES dbo.uaa (uaa_codigo)
);

CREATE NONCLUSTERED INDEX IX_piu_uaa_codigo
    ON sgspi.proceso_institucional_uaa (piu_uaa_codigo); -- [AP-09] Sin INCLUDE de la columna eliminada


GO
/*==================================================================================================
  2. DOMINIO DE CONTEXTO ORGANIZACIONAL — MATRIZ DOFA (DOCUMENTOS 1 Y 2: ES-GSPI-MR-01)
==================================================================================================*/
-- 2.1 [fec] Catálogo de Factores de Entorno (Variables Internas y Externas)
CREATE TABLE sgspi.factor_entorno_catalogo (
    fec_codigo         SMALLINT       IDENTITY (1, 1) NOT NULL,
    fec_nombre_factor  NVARCHAR (100) NOT NULL,
    fec_ambito_entorno NVARCHAR (15)  NOT NULL, -- 'INTERNO', 'EXTERNO'
    fec_descripcion    NVARCHAR (255) NULL,
    CONSTRAINT PK_fec_factor_entorno_catalogo PRIMARY KEY CLUSTERED (fec_codigo),
    CONSTRAINT UQ_fec_nombre_ambito UNIQUE (fec_nombre_factor, fec_ambito_entorno),
    CONSTRAINT CK_fec_ambito_entorno CHECK (fec_ambito_entorno IN (N'INTERNO', N'EXTERNO'))
);

-- 2.2 [acf] Análisis de Factores de Contexto por Proceso (DOFA por Proceso y Consolidado)
CREATE TABLE sgspi.analisis_contexto_factor (
    acf_codigo                  INT             IDENTITY (1, 1) NOT NULL,
    acf_pev_codigo              SMALLINT        NOT NULL, -- FK a [sgspi].[periodo_vigencia]([pev_codigo])
    acf_pri_codigo              INT             NOT NULL, -- FK a [sgspi].[proceso_institucional]([pri_codigo])
    acf_fec_codigo              SMALLINT        NOT NULL, -- FK a [sgspi].[factor_entorno_catalogo]([fec_codigo])
    acf_naturaleza_factor       NVARCHAR (15)   NOT NULL, -- 'DEBILIDAD', 'FORTALEZA', 'AMENAZA', 'OPORTUNIDAD'
    acf_numero_factor           SMALLINT        NOT NULL, -- Consecutivo inmutable por vigencia y naturaleza (1..n)
    acf_identificador_factor    AS              (CONVERT (NVARCHAR (15), CONCAT(LEFT(acf_naturaleza_factor, 1), acf_numero_factor))) PERSISTED, -- Identificador documental estable ('D1'..'Dn', 'F1'..'Fn', 'A1'..'An', 'O1'..'On')
    acf_descripcion_situacion   NVARCHAR (1000) NOT NULL,
    acf_valor_prioridad         TINYINT         CONSTRAINT DF_acf_valor_prioridad DEFAULT 1 NOT NULL, -- Escala ordinal unificada: 1=BAJA, 2=MEDIA, 3=ALTA
    acf_nivel_prioridad         AS              (CASE acf_valor_prioridad WHEN 3 THEN N'ALTA' WHEN 2 THEN N'MEDIA' ELSE N'BAJA' END) PERSISTED,
    acf_impacto_sistema_gestion NVARCHAR (1000) NULL,
    acf_accion_propuesta        NVARCHAR (1000) NULL,
    acf_estado_registro         NVARCHAR (30)   CONSTRAINT DF_acf_estado_registro DEFAULT N'BORRADOR' NOT NULL, -- [AP-17]
    acf_efc_dominio             AS              (CONVERT (NVARCHAR (10), N'ACF')) PERSISTED, -- [AP-05] Dominio constante para la FK al catálogo de estados
    acf_per_codigo_creador      INT             NOT NULL, -- FK a [dbo].[persona]([per_codigo])
    acf_per_codigo_aprobador    INT             NULL, -- FK a [dbo].[persona]([per_codigo])
    acf_fecha_creacion          DATETIMEOFFSET (0) CONSTRAINT DF_acf_fecha_creacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17]
    acf_fecha_actualizacion     DATETIMEOFFSET (0) CONSTRAINT DF_acf_fecha_actualizacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17]
    CONSTRAINT PK_acf_analisis_contexto_factor PRIMARY KEY CLUSTERED (acf_codigo),
    CONSTRAINT FK_acf_periodo_vigencia FOREIGN KEY (acf_pev_codigo) REFERENCES sgspi.periodo_vigencia (pev_codigo),
    CONSTRAINT FK_acf_proceso_institucional FOREIGN KEY (acf_pri_codigo) REFERENCES sgspi.proceso_institucional (pri_codigo),
    CONSTRAINT FK_acf_factor_entorno FOREIGN KEY (acf_fec_codigo) REFERENCES sgspi.factor_entorno_catalogo (fec_codigo),
    CONSTRAINT FK_acf_dbo_persona_creador FOREIGN KEY (acf_per_codigo_creador) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT FK_acf_dbo_persona_aprobador FOREIGN KEY (acf_per_codigo_aprobador) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT FK_acf_estado_flujo FOREIGN KEY (acf_efc_dominio, acf_estado_registro) REFERENCES sgspi.estado_flujo_catalogo (efc_dominio, efc_identificador), -- [AP-05]
    CONSTRAINT CK_acf_naturaleza_factor CHECK (acf_naturaleza_factor IN (N'DEBILIDAD', N'FORTALEZA', N'AMENAZA', N'OPORTUNIDAD')),
    CONSTRAINT CK_acf_numero_factor_positivo CHECK (acf_numero_factor >= 1),
    CONSTRAINT CK_acf_valor_prioridad CHECK (acf_valor_prioridad IN (1, 2, 3)),
    -- RN-DOFA-03: Si la prioridad es ALTA (3) y no está en borrador, exige Impacto y Acción Propuesta
    CONSTRAINT CK_acf_prioridad_alta_campos CHECK (acf_estado_registro = N'BORRADOR'
                                                   OR acf_valor_prioridad <> 3
                                                   OR (LEN(TRIM(ISNULL(acf_impacto_sistema_gestion, N''))) > 0
                                                       AND LEN(TRIM(ISNULL(acf_accion_propuesta, N''))) > 0)),
    -- [AP-05] Se elimina CK_acf_estado_registro (lista de estados): ahora lo garantiza FK_acf_estado_flujo
    -- [AP-15] Segregación de funciones: el aprobador no puede ser el creador, y VIGENTE/HISTORICO exigen aprobador
    CONSTRAINT CK_acf_sod_aprobador CHECK (acf_per_codigo_aprobador IS NULL
                                           OR acf_per_codigo_aprobador <> acf_per_codigo_creador),
    CONSTRAINT CK_acf_aprobador_requerido CHECK (acf_estado_registro NOT IN (N'VIGENTE', N'HISTORICO')
                                                 OR acf_per_codigo_aprobador IS NOT NULL)
);

-- [AP-18] Reemplaza la UNIQUE constraint y el índice IX_acf_pev_codigo (prefijo duplicado) por un único índice único con INCLUDE
CREATE UNIQUE NONCLUSTERED INDEX UQ_acf_vigencia_naturaleza_numero
    ON sgspi.analisis_contexto_factor (acf_pev_codigo, acf_naturaleza_factor, acf_numero_factor)
    INCLUDE (acf_identificador_factor, acf_pri_codigo, acf_fec_codigo);
CREATE NONCLUSTERED INDEX IX_acf_pri_codigo
    ON sgspi.analisis_contexto_factor (acf_pri_codigo);
CREATE NONCLUSTERED INDEX IX_acf_fec_codigo
    ON sgspi.analisis_contexto_factor (acf_fec_codigo);
CREATE NONCLUSTERED INDEX IX_acf_per_codigo_creador
    ON sgspi.analisis_contexto_factor (acf_per_codigo_creador);
CREATE NONCLUSTERED INDEX IX_acf_per_codigo_aprobador
    ON sgspi.analisis_contexto_factor (acf_per_codigo_aprobador);


GO
/*==================================================================================================
  3. DOMINIO DE PARTES INTERESADAS (DOCUMENTO 3: ES-GSPI-MR-03)
==================================================================================================*/
-- 3.1 [pai] Catálogo de Partes Interesadas (Internas y Externas)
CREATE TABLE sgspi.parte_interesada (
    pai_codigo          INT            IDENTITY (1, 1) NOT NULL,
    pai_nombre          NVARCHAR (150) NOT NULL,
    pai_origen          NVARCHAR (15)  NOT NULL, -- 'INTERNA', 'EXTERNA'
    pai_descripcion_rol NVARCHAR (255) NULL,
    pai_esta_activa     BIT            CONSTRAINT DF_pai_esta_activa DEFAULT 1 NOT NULL, -- [AP-17]
    CONSTRAINT PK_pai_parte_interesada PRIMARY KEY CLUSTERED (pai_codigo),
    CONSTRAINT UQ_pai_nombre UNIQUE (pai_nombre),
    CONSTRAINT CK_pai_origen CHECK (pai_origen IN (N'INTERNA', N'EXTERNA'))
);

-- 3.2 [rpi] Necesidades, Expectativas y Requisitos por Parte Interesada
CREATE TABLE sgspi.requisito_parte_interesada (
    rpi_codigo                 INT             IDENTITY (1, 1) NOT NULL,
    rpi_pev_codigo             SMALLINT        NOT NULL, -- FK a [sgspi].[periodo_vigencia]([pev_codigo])
    rpi_pai_codigo             INT             NOT NULL, -- FK a [sgspi].[parte_interesada]([pai_codigo])
    rpi_necesidad_expectativa  NVARCHAR (1000) NOT NULL,
    rpi_valor_poder            TINYINT         CONSTRAINT DF_rpi_valor_poder DEFAULT 1 NOT NULL, -- 1=BAJA, 2=MEDIA, 3=ALTA
    rpi_valor_interes          TINYINT         CONSTRAINT DF_rpi_valor_interes DEFAULT 1 NOT NULL, -- 1=BAJA, 2=MEDIA, 3=ALTA
    rpi_nivel_poder            AS              (CASE rpi_valor_poder WHEN 3 THEN N'ALTA' WHEN 2 THEN N'MEDIA' ELSE N'BAJA' END) PERSISTED,
    rpi_nivel_interes          AS              (CASE rpi_valor_interes WHEN 3 THEN N'ALTA' WHEN 2 THEN N'MEDIA' ELSE N'BAJA' END) PERSISTED,
    -- Campo Calculado en Tiempo de Ejecución #3: Clasificación según Poder vs Interés con aritmética entera
    rpi_clasificacion_impacto  AS              (CASE WHEN rpi_valor_poder = 3
                                                          AND rpi_valor_interes >= 2 THEN N'CUIDADO' WHEN (rpi_valor_poder = 3
                                                                                                           AND rpi_valor_interes = 1)
                                                                                                          OR (rpi_valor_poder = 2
                                                                                                              AND rpi_valor_interes >= 2) THEN N'ATENCION' WHEN (rpi_valor_poder = 2
                                                                                                                                                                 AND rpi_valor_interes = 1)
                                                                                                                                                                OR (rpi_valor_poder = 1
                                                                                                                                                                    AND rpi_valor_interes = 3) THEN N'MITIGANTE' ELSE N'SIN_PROBLEMA' END) PERSISTED,
    rpi_valor_cumplimiento     TINYINT         NULL, -- 1=BAJA, 2=MEDIA, 3=ALTA (NULL cuando aún no se ha evaluado)
    rpi_nivel_cumplimiento     AS              (CASE rpi_valor_cumplimiento WHEN 3 THEN N'ALTA' WHEN 2 THEN N'MEDIA' WHEN 1 THEN N'BAJA' ELSE NULL END) PERSISTED,
    -- Campo Calculado en Tiempo de Ejecución #4: Prioridad de Acción con aritmética directa (4 - cumplimiento) y etiqueta
    rpi_valor_prioridad_accion AS              (CAST (4 - rpi_valor_cumplimiento AS TINYINT)) PERSISTED,
    rpi_prioridad_accion       AS              (CASE rpi_valor_cumplimiento WHEN 1 THEN N'ALTA' WHEN 2 THEN N'MEDIA' WHEN 3 THEN N'BAJA' ELSE NULL END) PERSISTED,
    rpi_mecanismo_seguimiento  NVARCHAR (255)  NULL,
    rpi_estado_registro        NVARCHAR (30)   CONSTRAINT DF_rpi_estado_registro DEFAULT N'BORRADOR' NOT NULL, -- [AP-04] [AP-17] El INSERT solo puede nacer en el estado inicial
    rpi_efc_dominio            AS              (CONVERT (NVARCHAR (10), N'RPI')) PERSISTED, -- [AP-05] Dominio constante para la FK al catálogo de estados
    rpi_per_codigo_creador     INT             NOT NULL, -- [AP-15] FK a [dbo].[persona]([per_codigo])
    rpi_per_codigo_aprobador   INT             NULL, -- [AP-15] FK a [dbo].[persona]([per_codigo])
    rpi_fecha_creacion         DATETIMEOFFSET (0) CONSTRAINT DF_rpi_fecha_creacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17]
    rpi_fecha_actualizacion    DATETIMEOFFSET (0) CONSTRAINT DF_rpi_fecha_actualizacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17]
    CONSTRAINT PK_rpi_requisito_parte_interesada PRIMARY KEY CLUSTERED (rpi_codigo),
    CONSTRAINT FK_rpi_periodo_vigencia FOREIGN KEY (rpi_pev_codigo) REFERENCES sgspi.periodo_vigencia (pev_codigo),
    CONSTRAINT FK_rpi_parte_interesada FOREIGN KEY (rpi_pai_codigo) REFERENCES sgspi.parte_interesada (pai_codigo),
    CONSTRAINT FK_rpi_dbo_persona_creador FOREIGN KEY (rpi_per_codigo_creador) REFERENCES dbo.persona (per_codigo), -- [AP-15]
    CONSTRAINT FK_rpi_dbo_persona_aprobador FOREIGN KEY (rpi_per_codigo_aprobador) REFERENCES dbo.persona (per_codigo), -- [AP-15]
    CONSTRAINT FK_rpi_estado_flujo FOREIGN KEY (rpi_efc_dominio, rpi_estado_registro) REFERENCES sgspi.estado_flujo_catalogo (efc_dominio, efc_identificador), -- [AP-05]
    CONSTRAINT CK_rpi_valores_escala CHECK (rpi_valor_poder IN (1, 2, 3)
                                            AND rpi_valor_interes IN (1, 2, 3)
                                            AND (rpi_valor_cumplimiento IS NULL
                                                 OR rpi_valor_cumplimiento IN (1, 2, 3))),
    -- [AP-05] Se elimina CK_rpi_estado_registro (lista de estados): ahora lo garantiza FK_rpi_estado_flujo
    -- [AP-15] Segregación de funciones: el aprobador no puede ser el creador, y VIGENTE/HISTORICO exigen aprobador
    CONSTRAINT CK_rpi_sod_aprobador CHECK (rpi_per_codigo_aprobador IS NULL
                                           OR rpi_per_codigo_aprobador <> rpi_per_codigo_creador),
    CONSTRAINT CK_rpi_aprobador_requerido CHECK (rpi_estado_registro NOT IN (N'VIGENTE', N'HISTORICO')
                                                 OR rpi_per_codigo_aprobador IS NOT NULL)
);

CREATE NONCLUSTERED INDEX IX_rpi_pev_codigo
    ON sgspi.requisito_parte_interesada (rpi_pev_codigo);
CREATE NONCLUSTERED INDEX IX_rpi_pai_codigo
    ON sgspi.requisito_parte_interesada (rpi_pai_codigo);
CREATE NONCLUSTERED INDEX IX_rpi_per_codigo_creador -- [AP-15] [AP-18] Índice para la FK
    ON sgspi.requisito_parte_interesada (rpi_per_codigo_creador);
CREATE NONCLUSTERED INDEX IX_rpi_per_codigo_aprobador -- [AP-15] [AP-18] Índice para la FK
    ON sgspi.requisito_parte_interesada (rpi_per_codigo_aprobador);

-- 3.3 [rpc] Referencias Atómicas a Preguntas del Cuestionario por Requisito (Elimina listas multivaluadas como '6-7-8')
CREATE TABLE sgspi.requisito_parte_interesada_cuestionario (
    rpc_rpi_codigo      INT      NOT NULL, -- FK a [sgspi].[requisito_parte_interesada]([rpi_codigo])
    rpc_numero_pregunta SMALLINT NOT NULL, -- Número atómico de pregunta del cuestionario (ej. 6, 7, 8)
    CONSTRAINT PK_rpc_requisito_parte_interesada_cuestionario PRIMARY KEY CLUSTERED (rpc_rpi_codigo, rpc_numero_pregunta),
    CONSTRAINT FK_rpc_requisito_parte_interesada FOREIGN KEY (rpc_rpi_codigo) REFERENCES sgspi.requisito_parte_interesada (rpi_codigo),
    CONSTRAINT CK_rpc_numero_pregunta_positivo CHECK (rpc_numero_pregunta >= 1)
);

CREATE NONCLUSTERED INDEX IX_rpc_numero_pregunta
    ON sgspi.requisito_parte_interesada_cuestionario (rpc_numero_pregunta); -- [AP-18] Sin INCLUDE: rpc_rpi_codigo ya es parte de la clave clustered

-- 3.4 [rpp] Relación N:M Requisito de Parte Interesada <-> Proceso Institucional
CREATE TABLE sgspi.requisito_parte_interesada_proceso_institucional (
    rpp_rpi_codigo     INT           NOT NULL, -- FK a [sgspi].[requisito_parte_interesada]([rpi_codigo])
    rpp_pri_codigo     INT           NOT NULL, -- FK a [sgspi].[proceso_institucional]([pri_codigo])
    rpp_fecha_registro DATETIMEOFFSET (0) CONSTRAINT DF_rpp_fecha_registro DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17]
    CONSTRAINT PK_rpp_requisito_parte_interesada_proceso_institucional PRIMARY KEY CLUSTERED (rpp_rpi_codigo, rpp_pri_codigo),
    CONSTRAINT FK_rpp_requisito_parte_interesada FOREIGN KEY (rpp_rpi_codigo) REFERENCES sgspi.requisito_parte_interesada (rpi_codigo),
    CONSTRAINT FK_rpp_proceso_institucional FOREIGN KEY (rpp_pri_codigo) REFERENCES sgspi.proceso_institucional (pri_codigo)
);

CREATE NONCLUSTERED INDEX IX_rpp_pri_codigo
    ON sgspi.requisito_parte_interesada_proceso_institucional (rpp_pri_codigo);


GO
/*==================================================================================================
  4. DOMINIO DE INVENTARIO Y CLASIFICACIÓN DE ACTIVOS (DOCUMENTO 4: ES-GSPI-MR-05)
     Articulado con [dbo].[uaa], [dbo].[sede], [dbo].[sub_sede], [dbo].[espacio], [dbo].[cargo] y [dbo].[persona]
==================================================================================================*/
-- 4.1 [tac] Catálogo Extensible de Taxonomía Jerárquica Autorreferenciada de Activos ISO/IEC 27005 (1=Categoría -> 2=Tipo -> 3=Subtipo)
CREATE TABLE sgspi.tipo_activo_catalogo (
    tac_codigo           SMALLINT       IDENTITY (1, 1) NOT NULL,
    tac_tac_codigo_padre SMALLINT       NULL, -- Código del nodo padre inmediato (NULL en las categorías de nivel 1; el padre de un Tipo es una Categoría y el de un Subtipo es un Tipo) [AP-06]
    tac_nivel_taxonomia  TINYINT        NOT NULL, -- 1=Categoría ISO 27005, 2=Tipo, 3=Subtipo
    tac_nivel_taxonomia_padre AS        (CONVERT (TINYINT, tac_nivel_taxonomia - 1)) PERSISTED, -- [AP-06] Nivel que debe tener el padre (exactamente un nivel arriba); soporta la FK compuesta FK_tac_padre
    tac_nombre           NVARCHAR (120) NOT NULL,
    tac_ejemplos_ref     NVARCHAR (255) NULL,
    tac_esta_activo      BIT            CONSTRAINT DF_tac_esta_activo DEFAULT 1 NOT NULL, -- [AP-17]
    CONSTRAINT PK_tac_tipo_activo_catalogo PRIMARY KEY CLUSTERED (tac_codigo),
    CONSTRAINT UQ_tac_codigo_nivel UNIQUE (tac_codigo, tac_nivel_taxonomia), -- [AP-06] Destino de FK compuestas (FK_tac_padre y eia)
    CONSTRAINT FK_tac_padre FOREIGN KEY (tac_tac_codigo_padre, tac_nivel_taxonomia_padre) REFERENCES sgspi.tipo_activo_catalogo (tac_codigo, tac_nivel_taxonomia), -- [AP-06] El padre está exactamente un nivel arriba
    CONSTRAINT UQ_tac_padre_nombre UNIQUE (tac_tac_codigo_padre, tac_nombre),
    CONSTRAINT CK_tac_nivel_coherente CHECK ((tac_nivel_taxonomia = 1
                                              AND tac_tac_codigo_padre IS NULL)
                                             OR (tac_nivel_taxonomia IN (2, 3)
                                                 AND tac_tac_codigo_padre IS NOT NULL
                                                 AND tac_tac_codigo_padre <> tac_codigo)),
    CONSTRAINT CK_tac_nombre_no_vacio CHECK (LEN(TRIM(tac_nombre)) > 0)
);

-- 4.2 [cet] Catálogo de Causales de Excepción de Transparencia (Desacoplado de Ley 1712 de 2014)
CREATE TABLE sgspi.causal_excepcion_transparencia (
    cet_codigo                  SMALLINT       IDENTITY (1, 1) NOT NULL,
    cet_nivel_reserva_aplicable NVARCHAR (20)  NOT NULL, -- 'CLASIFICADA' (3 causales) o 'RESERVADA' (9 causales)
    cet_numeral_causal          NVARCHAR (10)  NOT NULL,
    cet_descripcion_causal      NVARCHAR (500) NOT NULL,
    cet_norma_referencia        NVARCHAR (100) CONSTRAINT DF_cet_norma_referencia DEFAULT N'Ley 1712 de 2014' NOT NULL, -- [AP-17]
    CONSTRAINT PK_cet_causal_excepcion_transparencia PRIMARY KEY CLUSTERED (cet_codigo),
    CONSTRAINT UQ_cet_nivel_numeral UNIQUE (cet_nivel_reserva_aplicable, cet_numeral_causal), -- [AP-14] Clave natural de la causal
    CONSTRAINT UQ_cet_codigo_nivel UNIQUE (cet_codigo, cet_nivel_reserva_aplicable), -- [AP-06] Destino de la FK compuesta FK_aci_causal_excepcion
    CONSTRAINT CK_cet_nivel_reserva CHECK (cet_nivel_reserva_aplicable IN (N'CLASIFICADA', N'RESERVADA'))
);

-- 4.3 [aci] Supertipo: Inventario Maestro de Activos de Información (General ES-GSPI-MR-05 y Base de Activos Documentales ES-GSPI-MR-04)
CREATE TABLE sgspi.activo_informacion (
    aci_codigo                          INT             IDENTITY (1, 1) NOT NULL,
    aci_codigo_inventario               NVARCHAR (30)   NOT NULL,
    aci_nombre_activo                   NVARCHAR (255)  NOT NULL,
    aci_descripcion_detallada           NVARCHAR (1000) NULL,
    aci_tac_codigo                      SMALLINT        NOT NULL, -- FK a [sgspi].[tipo_activo_catalogo]([tac_codigo])
    aci_uaa_codigo                      INT             NULL, -- FK a [dbo].[uaa]([uaa_codigo])
    aci_esp_codigo                      INT             NULL, -- FK a [dbo].[espacio]([esp_codigo])
    aci_es_transversal_sedes            BIT             CONSTRAINT DF_aci_es_transversal_sedes DEFAULT 0 NOT NULL, -- [AP-17]
    aci_cantidad_unidades               INT             CONSTRAINT DF_aci_cantidad_unidades DEFAULT 1 NOT NULL, -- [AP-17]
    -- Clasificación de Transparencia e Índice de Información Clasificada y Reservada (Ley 1712 de 2014 / Decreto 103 de 2015)
    aci_clasificacion_transparencia     NVARCHAR (20)   NOT NULL, -- [AP-13] 'PUBLICA', 'CLASIFICADA', 'RESERVADA', 'NO_CLASIFICADA'
    aci_cet_codigo                      SMALLINT        NULL, -- FK a [sgspi].[causal_excepcion_transparencia]([cet_codigo]) (NULL cuando es PUBLICA o NO_CLASIFICADA)
    aci_alcance_excepcion               NVARCHAR (15)   NULL, -- 'PARCIAL', 'TOTAL' (NULL cuando es PUBLICA o NO_CLASIFICADA)
    aci_fundamento_constitucional_legal NVARCHAR (150)  NULL, -- Ej: 'Ley 1712 de 2014' (NULL cuando no aplica reserva)
    aci_fundamento_juridico_excepcion   NVARCHAR (150)  NULL, -- Norma o disposición específica de reserva (NULL cuando no aplica reserva)
    aci_fecha_clasificacion_reserva     DATE            NULL, -- NULL cuando no aplica reserva
    aci_es_reserva_indefinida           BIT             NULL, -- 1=Indefinida, 0=Plazo definido en años, NULL=No aplica reserva (elimina texto libre 'Indefinida')
    aci_anios_plazo_reserva             SMALLINT        NULL, -- Plazo numérico en años (ej. 15 años según Art. 22 Ley 1712/2014; NULL cuando es indefinida o no aplica)
    aci_fecha_vencimiento_reserva       AS              (CASE WHEN aci_es_reserva_indefinida = 0
                                                                   AND aci_fecha_clasificacion_reserva IS NOT NULL
                                                                   AND aci_anios_plazo_reserva IS NOT NULL THEN DATEADD(YEAR, aci_anios_plazo_reserva, aci_fecha_clasificacion_reserva) ELSE NULL END) PERSISTED,
    -- Protección de Datos Personales (Ley 1581 de 2012 / ISO 27701): Lógica booleana trivalente (BIT NULL en lugar de cadenas mágicas 'No Aplica')
    aci_contiene_datos_personales       BIT            CONSTRAINT DF_aci_contiene_datos_personales DEFAULT 0 NOT NULL, -- 1=Sí, 0=No [AP-17]
    aci_contiene_datos_menores          BIT            NULL, -- 1=Sí, 0=No, NULL=No aplica (cuando aci_contiene_datos_personales = 0)
    aci_categoria_dato_personal         NVARCHAR (20)  NULL, -- 'PRIVADOS', 'SEMIPRIVADOS', 'PUBLICOS', 'SENSIBLES' (NULL cuando aci_contiene_datos_personales = 0)
    aci_finalidad_recoleccion_pii       NVARCHAR (500) NULL, -- NULL cuando aci_contiene_datos_personales = 0
    aci_existe_autorizacion_pii         BIT            NULL, -- 1=Sí, 0=No, NULL=No aplica (cuando aci_contiene_datos_personales = 0)
    -- Valoración CID almacenada como entero (1=BAJA, 2=MEDIA, 3=ALTA)
    aci_valor_confidencialidad         TINYINT        NOT NULL,
    aci_valor_integridad               TINYINT        NOT NULL,
    aci_valor_disponibilidad           TINYINT        NOT NULL,
    -- Campos Calculados en Tiempo de Ejecución #5: Etiquetas CID unificadas ('ALTA'/'MEDIA'/'BAJA'), Puntaje y Nivel de Criticidad
    aci_nivel_confidencialidad         AS             (CASE aci_valor_confidencialidad WHEN 3 THEN N'ALTA' WHEN 2 THEN N'MEDIA' ELSE N'BAJA' END) PERSISTED,
    aci_nivel_integridad               AS             (CASE aci_valor_integridad WHEN 3 THEN N'ALTA' WHEN 2 THEN N'MEDIA' ELSE N'BAJA' END) PERSISTED,
    aci_nivel_disponibilidad           AS             (CASE aci_valor_disponibilidad WHEN 3 THEN N'ALTA' WHEN 2 THEN N'MEDIA' ELSE N'BAJA' END) PERSISTED,
    aci_puntaje_criticidad             AS             (CAST (aci_valor_confidencialidad + aci_valor_integridad + aci_valor_disponibilidad AS TINYINT)) PERSISTED,
    aci_nivel_criticidad               AS             (CASE WHEN (aci_valor_confidencialidad + aci_valor_integridad + aci_valor_disponibilidad) >= 7 THEN N'ALTA' WHEN (aci_valor_confidencialidad + aci_valor_integridad + aci_valor_disponibilidad) >= 5 THEN N'MEDIA' ELSE N'BAJA' END) PERSISTED,
    -- Infraestructura Crítica Cibernética (ICC)
    aci_supera_umbral_social_icc       BIT            CONSTRAINT DF_aci_supera_umbral_social_icc DEFAULT 0 NOT NULL, -- > 250.000 personas [AP-17]
    aci_supera_umbral_economico_icc    BIT            CONSTRAINT DF_aci_supera_umbral_economico_icc DEFAULT 0 NOT NULL, -- > $464.619.736 COP [AP-17]
    aci_supera_umbral_ambiental_icc    BIT            CONSTRAINT DF_aci_supera_umbral_ambiental_icc DEFAULT 0 NOT NULL, -- >= 3 años en recuperación [AP-17]
    aci_es_infraestructura_critica_icc AS             (CASE WHEN aci_supera_umbral_social_icc = 1
                                                                 OR aci_supera_umbral_economico_icc = 1
                                                                 OR aci_supera_umbral_ambiental_icc = 1 THEN CAST (1 AS BIT) ELSE CAST (0 AS BIT) END) PERSISTED, -- [AP-18] PERSISTED (indexable y sin recálculo)
    -- Control de ciclo de vida y auditoría (Apuntando a [dbo].[persona])
    aci_efc_dominio                    AS             (CONVERT (NVARCHAR (10), N'ACI')) PERSISTED, -- [AP-05] Dominio constante para la FK compuesta hacia el catálogo de estados
    aci_estado_registro                NVARCHAR (30)  CONSTRAINT DF_aci_estado_registro DEFAULT N'BORRADOR' NOT NULL, -- [AP-04] El INSERT solo puede iniciar en el estado inicial del flujo
    aci_per_codigo_creador             INT            NOT NULL, -- FK a [dbo].[persona]([per_codigo])
    aci_per_codigo_aprobador           INT            NULL, -- FK a [dbo].[persona]([per_codigo])
    aci_fecha_creacion                 DATETIMEOFFSET (0) CONSTRAINT DF_aci_fecha_creacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12]
    aci_fecha_actualizacion            DATETIMEOFFSET (0) CONSTRAINT DF_aci_fecha_actualizacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12]
    CONSTRAINT PK_aci_activo_informacion PRIMARY KEY CLUSTERED (aci_codigo),
    CONSTRAINT UQ_aci_codigo_inventario UNIQUE (aci_codigo_inventario),
    CONSTRAINT FK_aci_tipo_activo FOREIGN KEY (aci_tac_codigo) REFERENCES sgspi.tipo_activo_catalogo (tac_codigo),
    CONSTRAINT FK_aci_dbo_uaa FOREIGN KEY (aci_uaa_codigo) REFERENCES dbo.uaa (uaa_codigo),
    CONSTRAINT FK_aci_dbo_espacio FOREIGN KEY (aci_esp_codigo) REFERENCES dbo.espacio (esp_codigo),
    CONSTRAINT FK_aci_causal_excepcion FOREIGN KEY (aci_cet_codigo, aci_clasificacion_transparencia) REFERENCES sgspi.causal_excepcion_transparencia (cet_codigo, cet_nivel_reserva_aplicable), -- [AP-06] La causal debe corresponder al nivel de reserva del activo (no se evalúa con aci_cet_codigo NULL)
    CONSTRAINT FK_aci_estado_flujo FOREIGN KEY (aci_efc_dominio, aci_estado_registro) REFERENCES sgspi.estado_flujo_catalogo (efc_dominio, efc_identificador), -- [AP-05]
    CONSTRAINT FK_aci_dbo_persona_creador FOREIGN KEY (aci_per_codigo_creador) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT FK_aci_dbo_persona_aprobador FOREIGN KEY (aci_per_codigo_aprobador) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_aci_valores_cid CHECK (aci_valor_confidencialidad IN (1, 2, 3)
                                         AND aci_valor_integridad IN (1, 2, 3)
                                         AND aci_valor_disponibilidad IN (1, 2, 3)),
    CONSTRAINT CK_aci_transparencia CHECK (aci_clasificacion_transparencia IN (N'PUBLICA', N'CLASIFICADA', N'RESERVADA', N'NO_CLASIFICADA')), -- [AP-13]
    CONSTRAINT CK_aci_alcance_excepcion CHECK (aci_alcance_excepcion IS NULL
                                               OR aci_alcance_excepcion IN (N'PARCIAL', N'TOTAL')),
    -- RN-ACT-02: Si es RESERVADA, la confidencialidad no puede ser BAJA (1)
    CONSTRAINT CK_aci_reserva_confidencialidad CHECK (aci_clasificacion_transparencia <> N'RESERVADA'
                                                      OR aci_valor_confidencialidad >= 2),
    CONSTRAINT CK_aci_anios_plazo_reserva CHECK (aci_anios_plazo_reserva IS NULL
                                                 OR aci_anios_plazo_reserva BETWEEN 1 AND 100),
    -- RN-DOC-03 (Unificada en Supertipo): Coherencia del Índice de Información Clasificada y Reservada (Ley 1712 de 2014 / Decreto 103 de 2015) con plazos tipados
    CONSTRAINT CK_aci_coherencia_indice_reserva CHECK (aci_estado_registro = N'BORRADOR'
                                                       OR (aci_clasificacion_transparencia IN (N'CLASIFICADA', N'RESERVADA')
                                                           AND aci_cet_codigo IS NOT NULL
                                                           AND aci_alcance_excepcion IS NOT NULL
                                                           AND aci_fecha_clasificacion_reserva IS NOT NULL
                                                           AND ((aci_es_reserva_indefinida = 1
                                                                 AND aci_anios_plazo_reserva IS NULL)
                                                                OR (aci_es_reserva_indefinida = 0
                                                                    AND aci_anios_plazo_reserva IS NOT NULL)))
                                                       OR (aci_clasificacion_transparencia IN (N'PUBLICA', N'NO_CLASIFICADA') -- [AP-13]
                                                           AND aci_cet_codigo IS NULL
                                                           AND aci_alcance_excepcion IS NULL
                                                           AND aci_fundamento_constitucional_legal IS NULL
                                                           AND aci_fundamento_juridico_excepcion IS NULL
                                                           AND aci_fecha_clasificacion_reserva IS NULL
                                                           AND aci_es_reserva_indefinida IS NULL
                                                           AND aci_anios_plazo_reserva IS NULL)),
    -- RN-ACT-03 y RN-DOC-02 (Unificadas en Supertipo): Coherencia de Datos Personales (Ley 1581 de 2012) con lógica trivalente BIT NULL
    CONSTRAINT CK_aci_categoria_pii CHECK (aci_categoria_dato_personal IS NULL
                                           OR aci_categoria_dato_personal IN (N'PRIVADOS', N'SEMIPRIVADOS', N'PUBLICOS', N'SENSIBLES')),
    CONSTRAINT CK_aci_coherencia_pii CHECK (aci_estado_registro = N'BORRADOR'
                                            OR (aci_contiene_datos_personales = 1
                                                AND aci_contiene_datos_menores IS NOT NULL
                                                AND aci_categoria_dato_personal IS NOT NULL
                                                AND LEN(TRIM(ISNULL(aci_finalidad_recoleccion_pii, N''))) > 0
                                                AND aci_existe_autorizacion_pii IS NOT NULL)
                                            OR (aci_contiene_datos_personales = 0
                                                AND aci_contiene_datos_menores IS NULL
                                                AND aci_categoria_dato_personal IS NULL
                                                AND aci_finalidad_recoleccion_pii IS NULL
                                                AND aci_existe_autorizacion_pii IS NULL)),
    CONSTRAINT CK_aci_pii_privados_no_publico_bajo CHECK (aci_contiene_datos_personales = 0
                                                          OR (ISNULL(aci_categoria_dato_personal, N'') NOT IN (N'PRIVADOS', N'SENSIBLES')
                                                              AND ISNULL(aci_contiene_datos_menores, 0) = 0)
                                                          OR NOT (aci_clasificacion_transparencia = N'PUBLICA' -- [AP-13]
                                                                  AND aci_valor_confidencialidad = 1)),
    -- [AP-05] Se elimina CK_aci_estado_registro: los estados válidos viven en sgspi.estado_flujo_catalogo (FK_aci_estado_flujo)
    CONSTRAINT CK_aci_cantidad_unidades_positiva CHECK (aci_cantidad_unidades >= 1),
    -- [AP-15] Segregación de funciones: el aprobador no puede ser el creador
    CONSTRAINT CK_aci_sod_aprobador CHECK (aci_per_codigo_aprobador IS NULL
                                           OR aci_per_codigo_aprobador <> aci_per_codigo_creador),
    -- [AP-15] Un activo vigente, inactivo o histórico debe tener aprobador
    CONSTRAINT CK_aci_aprobador_requerido CHECK (aci_estado_registro NOT IN (N'VIGENTE', N'INACTIVO', N'HISTORICO')
                                                 OR aci_per_codigo_aprobador IS NOT NULL)
);

CREATE NONCLUSTERED INDEX IX_aci_tac_codigo
    ON sgspi.activo_informacion (aci_tac_codigo)
    INCLUDE (aci_estado_registro, aci_nivel_criticidad);
CREATE NONCLUSTERED INDEX IX_aci_uaa_codigo
    ON sgspi.activo_informacion (aci_uaa_codigo);
CREATE NONCLUSTERED INDEX IX_aci_esp_codigo
    ON sgspi.activo_informacion (aci_esp_codigo);
CREATE NONCLUSTERED INDEX IX_aci_cet_codigo
    ON sgspi.activo_informacion (aci_cet_codigo);
CREATE NONCLUSTERED INDEX IX_aci_per_codigo_creador
    ON sgspi.activo_informacion (aci_per_codigo_creador);
CREATE NONCLUSTERED INDEX IX_aci_per_codigo_aprobador
    ON sgspi.activo_informacion (aci_per_codigo_aprobador);

-- 4.4 [aip], [ais], [air] Tablas Asociativas N:M Unificadas de Activos de Información (Compartidas por el Supertipo y todos sus Subtipos)
CREATE TABLE sgspi.activo_informacion_proceso_institucional (
    aip_aci_codigo INT NOT NULL, -- FK a [sgspi].[activo_informacion]([aci_codigo])
    aip_pri_codigo INT NOT NULL, -- FK a [sgspi].[proceso_institucional]([pri_codigo])
    CONSTRAINT PK_aip_activo_informacion_proceso_institucional PRIMARY KEY CLUSTERED (aip_aci_codigo, aip_pri_codigo),
    CONSTRAINT FK_aip_activo_informacion FOREIGN KEY (aip_aci_codigo) REFERENCES sgspi.activo_informacion (aci_codigo),
    CONSTRAINT FK_aip_proceso_institucional FOREIGN KEY (aip_pri_codigo) REFERENCES sgspi.proceso_institucional (pri_codigo)
);

CREATE NONCLUSTERED INDEX IX_aip_pri_codigo
    ON sgspi.activo_informacion_proceso_institucional (aip_pri_codigo);

CREATE TABLE sgspi.activo_informacion_sede (
    ais_aci_codigo INT NOT NULL, -- FK a [sgspi].[activo_informacion]([aci_codigo])
    ais_sus_codigo INT NOT NULL, -- FK a [dbo].[sub_sede]([sus_codigo]) (contiene [sed_codigo] hacia [dbo].[sede])
    CONSTRAINT PK_ais_activo_informacion_sede PRIMARY KEY CLUSTERED (ais_aci_codigo, ais_sus_codigo),
    CONSTRAINT FK_ais_activo_informacion FOREIGN KEY (ais_aci_codigo) REFERENCES sgspi.activo_informacion (aci_codigo),
    CONSTRAINT FK_ais_dbo_sub_sede FOREIGN KEY (ais_sus_codigo) REFERENCES dbo.sub_sede (sus_codigo)
);

CREATE NONCLUSTERED INDEX IX_ais_sus_codigo
    ON sgspi.activo_informacion_sede (ais_sus_codigo);

CREATE TABLE sgspi.activo_informacion_responsable (
    air_aci_codigo           INT           NOT NULL, -- FK a [sgspi].[activo_informacion]([aci_codigo])
    air_car_codigo           INT           NOT NULL, -- FK a [dbo].[cargo]([car_codigo]): Cargo institucional responsable (ISO 27001 / Ley 594)
    air_uaa_codigo           INT           NOT NULL, -- FK a [dbo].[uaa]([uaa_codigo]): Dependencia del cargo
    air_tipo_responsabilidad NVARCHAR (20) NOT NULL, -- 'PROPIETARIO', 'CUSTODIO'
    air_esta_activo          BIT           CONSTRAINT DF_air_esta_activo DEFAULT 1 NOT NULL, -- [AP-17]
    -- Clave primaria compuesta 100% NOT NULL (elimina UNIQUE sobre columnas NULL [uap_codigo]/[uac_codigo] y unifica [air] + [adr])
    CONSTRAINT PK_air_activo_informacion_responsable PRIMARY KEY CLUSTERED (air_aci_codigo, air_car_codigo, air_uaa_codigo, air_tipo_responsabilidad),
    CONSTRAINT FK_air_activo_informacion FOREIGN KEY (air_aci_codigo) REFERENCES sgspi.activo_informacion (aci_codigo),
    CONSTRAINT FK_air_dbo_cargo FOREIGN KEY (air_car_codigo) REFERENCES dbo.cargo (car_codigo),
    CONSTRAINT FK_air_dbo_uaa FOREIGN KEY (air_uaa_codigo) REFERENCES dbo.uaa (uaa_codigo),
    CONSTRAINT CK_air_tipo_responsabilidad CHECK (air_tipo_responsabilidad IN (N'PROPIETARIO', N'CUSTODIO'))
);

CREATE NONCLUSTERED INDEX IX_air_car_codigo
    ON sgspi.activo_informacion_responsable (air_car_codigo)
    INCLUDE (air_esta_activo); -- [AP-18] air_aci_codigo y air_tipo_responsabilidad ya son parte de la clave clustered
CREATE NONCLUSTERED INDEX IX_air_uaa_codigo
    ON sgspi.activo_informacion_responsable (air_uaa_codigo)
    INCLUDE (air_esta_activo); -- [AP-18] air_aci_codigo ya es parte de la clave clustered

-- 4.5 [sif] y [msi] Ficha Técnica de Sistemas de Información y sus Módulos (Los 17 Sistemas USCO)
CREATE TABLE sgspi.sistema_informacion_ficha (
    sif_codigo               INT             IDENTITY (1, 1) NOT NULL,
    sif_aci_codigo           INT             NULL, -- FK a [sgspi].[activo_informacion]([aci_codigo])
    sif_nombre_sistema       NVARCHAR (150)  NOT NULL,
    sif_modalidad_desarrollo NVARCHAR (50)   NOT NULL, -- [AP-08] 'PROPIO', 'PROPIO_EN_DESARROLLO', 'CODIGO_ABIERTO_ADAPTADO', 'COMERCIAL_TERCERO'
    sif_fabricante_proveedor NVARCHAR (150)  NULL,
    sif_descripcion_general  NVARCHAR (1000) NOT NULL,
    CONSTRAINT PK_sif_sistema_informacion_ficha PRIMARY KEY CLUSTERED (sif_codigo),
    CONSTRAINT UQ_sif_nombre_sistema UNIQUE (sif_nombre_sistema),
    CONSTRAINT FK_sif_activo_informacion FOREIGN KEY (sif_aci_codigo) REFERENCES sgspi.activo_informacion (aci_codigo),
    CONSTRAINT CK_sif_modalidad_desarrollo CHECK (sif_modalidad_desarrollo IN (N'PROPIO', N'PROPIO_EN_DESARROLLO', N'CODIGO_ABIERTO_ADAPTADO', N'COMERCIAL_TERCERO')) -- [AP-08]
);

-- Índice único filtrado (SQL Server 2019) para relación 1:0..1 sobre columna NULL sin bloquear múltiples NULL
CREATE UNIQUE NONCLUSTERED INDEX UQ_sif_aci_codigo
    ON sgspi.sistema_informacion_ficha (sif_aci_codigo)
    WHERE sif_aci_codigo IS NOT NULL;

CREATE TABLE sgspi.modulo_sistema_informacion (
    msi_codigo            INT            IDENTITY (1, 1) NOT NULL,
    msi_sif_codigo        INT            NOT NULL, -- FK a [sgspi].[sistema_informacion_ficha]([sif_codigo])
    msi_nombre_modulo     NVARCHAR (200) NOT NULL,
    msi_usuarios_objetivo NVARCHAR (150) NULL,
    CONSTRAINT PK_msi_modulo_sistema_informacion PRIMARY KEY CLUSTERED (msi_codigo),
    CONSTRAINT UQ_msi_sistema_nombre UNIQUE (msi_sif_codigo, msi_nombre_modulo), -- [AP-14] Clave natural; además cubre las búsquedas por msi_sif_codigo
    CONSTRAINT FK_msi_sistema_informacion FOREIGN KEY (msi_sif_codigo) REFERENCES sgspi.sistema_informacion_ficha (sif_codigo) ON DELETE CASCADE
);

-- [AP-18] Se elimina IX_msi_sif_codigo: redundante con UQ_msi_sistema_nombre (misma columna líder)


GO
/*==================================================================================================
  4B. DOMINIO DE ACTIVOS DE LA INFORMACIÓN DOCUMENTAL Y ARCHIVÍSTICA (SUBTIPO DE [aci]: ES-GSPI-MR-04)
      Patrón Supertipo/Subtipo (Herencia de Tabla 1:1): Hereda valoración CID, criticidad, privacidad PII,
      ley de transparencia, umbrales ICC, estados, auditoría, procesos ([aip]) y responsables ([air])
      directamente de [sgspi].[activo_informacion], almacenando aquí solo metadatos archivísticos (Ley 594/2000).
==================================================================================================*/
-- 4B.1 [sdo] Catálogo Maestro de Series Documentales del CCD/TRD (39 Series: COD5 = 1..39)
CREATE TABLE sgspi.serie_documental_catalogo (
    sdo_codigo          SMALLINT       IDENTITY (1, 1) NOT NULL,
    sdo_numero_ccd      SMALLINT       NOT NULL, -- COD5: 1=ACCIONES CONSTITUCIONALES .. 39=RESOLUCIONES
    sdo_nombre_serie    NVARCHAR (150) NOT NULL,
    sdo_tiene_subseries BIT            CONSTRAINT DF_sdo_tiene_subseries DEFAULT 1 NOT NULL, -- [AP-17] -- 0 cuando la serie es directa (ej. CIRCULARES, RESOLUCIONES, HISTORIAS LABORALES)
    sdo_esta_activa     BIT            CONSTRAINT DF_sdo_esta_activa DEFAULT 1 NOT NULL, -- [AP-17]
    CONSTRAINT PK_sdo_serie_documental_catalogo PRIMARY KEY CLUSTERED (sdo_codigo),
    CONSTRAINT UQ_sdo_numero_ccd UNIQUE (sdo_numero_ccd),
    CONSTRAINT UQ_sdo_nombre_serie UNIQUE (sdo_nombre_serie),
    CONSTRAINT CK_sdo_numero_ccd_positivo CHECK (sdo_numero_ccd >= 1)
);

-- 4B.2 [sbd] Catálogo Maestro de Subseries Documentales del CCD/TRD (COD6 dentro de cada Serie)
CREATE TABLE sgspi.subserie_documental_catalogo (
    sbd_codigo          INT            IDENTITY (1, 1) NOT NULL,
    sbd_sdo_codigo      SMALLINT       NOT NULL, -- FK a [sgspi].[serie_documental_catalogo]([sdo_codigo])
    sbd_numero_ccd      SMALLINT       NOT NULL, -- COD6: Número secuencial de la subserie dentro de la serie
    sbd_nombre_subserie NVARCHAR (200) NOT NULL,
    sbd_esta_activa     BIT            CONSTRAINT DF_sbd_esta_activa DEFAULT 1 NOT NULL, -- [AP-17]
    CONSTRAINT PK_sbd_subserie_documental_catalogo PRIMARY KEY CLUSTERED (sbd_codigo),
    CONSTRAINT UQ_sbd_serie_subserie UNIQUE (sbd_sdo_codigo, sbd_codigo),
    CONSTRAINT UQ_sbd_serie_numero UNIQUE (sbd_sdo_codigo, sbd_numero_ccd),
    CONSTRAINT UQ_sbd_serie_nombre UNIQUE (sbd_sdo_codigo, sbd_nombre_subserie),
    CONSTRAINT FK_sbd_serie_documental FOREIGN KEY (sbd_sdo_codigo) REFERENCES sgspi.serie_documental_catalogo (sdo_codigo),
    CONSTRAINT CK_sbd_numero_ccd_positivo CHECK (sbd_numero_ccd >= 1)
);

-- 4B.3 [upc] Estructura Jerárquica de Unidades Productoras del Cuadro de Clasificación Documental (Árbol N-Niveles con HIERARCHYID)
CREATE TABLE sgspi.unidad_productora_cuadro_clasificacion_documental (
    upc_codigo               INT            IDENTITY (1, 1) NOT NULL,
    upc_nodo_jerarquico      HIERARCHYID    NOT NULL, -- Ruta nativa HIERARCHYID (ej. '/1/', '/1/1/', '/1/1.1/', '/5/1/1/2/')
    upc_nodo_padre           AS             (NULLIF(upc_nodo_jerarquico.GetAncestor(1), hierarchyid::GetRoot())) PERSISTED, -- Padre directo determinístico (NULL en nivel 1)
    upc_nivel_jerarquico     AS             (upc_nodo_jerarquico.GetLevel()) PERSISTED, -- Nivel calculado automáticamente por el motor (1=Sección, 2=Subsección, 3..N=Subdivisiones)
    upc_codigo_archivistico  NVARCHAR (50)  NULL, -- Código documental TRD explícito desacoplado de HIERARCHYID para nodos intermedios (ej. '/1/1.1/' -> '1.2')
    upc_prefijo_archivistico AS             (COALESCE(NULLIF(TRIM(upc_codigo_archivistico), N''), CONVERT (NVARCHAR (50), REPLACE(REPLACE(TRIM(N'/' FROM upc_nodo_jerarquico.ToString()), N'.', N'-'), N'/', N'.')))) PERSISTED, -- Prefijo CCD efectivo (ej. '1', '1.1', '1.1-1', '5.1.1.2')
    upc_uaa_codigo           INT            NULL, -- FK a [dbo].[uaa]([uaa_codigo]): Equivalencia organizacional en academia3000
    upc_nombre_unidad        NVARCHAR (150) NOT NULL, -- Ej: 'RECTORIA', 'SECRETARIA GENERAL', 'AREA GESTION DOCUMENTAL'
    upc_esta_activa          BIT            CONSTRAINT DF_upc_esta_activa DEFAULT 1 NOT NULL, -- [AP-17]
    CONSTRAINT PK_upc_unidad_productora_cuadro_clasificacion_documental PRIMARY KEY CLUSTERED (upc_codigo),
    CONSTRAINT UQ_upc_nodo_jerarquico UNIQUE (upc_nodo_jerarquico),
    CONSTRAINT UQ_upc_prefijo_archivistico UNIQUE (upc_prefijo_archivistico),
    CONSTRAINT FK_upc_nodo_padre FOREIGN KEY (upc_nodo_padre) REFERENCES sgspi.unidad_productora_cuadro_clasificacion_documental (upc_nodo_jerarquico),
    CONSTRAINT FK_upc_dbo_uaa FOREIGN KEY (upc_uaa_codigo) REFERENCES dbo.uaa (uaa_codigo),
    CONSTRAINT CK_upc_codigo_archivistico_no_vacio CHECK (upc_codigo_archivistico IS NULL
                                                          OR LEN(TRIM(upc_codigo_archivistico)) > 0),
    CONSTRAINT CK_upc_nivel_jerarquico_valido CHECK (upc_nodo_jerarquico.GetLevel() >= 1
                                                     AND upc_nodo_jerarquico.ToString() NOT LIKE N'%-%') -- Permite '.' para inserción de nodos intermedios en HIERARCHYID
);

CREATE NONCLUSTERED INDEX IX_upc_busqueda_anchura
    ON sgspi.unidad_productora_cuadro_clasificacion_documental (upc_nivel_jerarquico, upc_nodo_jerarquico)
    INCLUDE (upc_prefijo_archivistico, upc_nombre_unidad);
CREATE NONCLUSTERED INDEX IX_upc_nodo_padre
    ON sgspi.unidad_productora_cuadro_clasificacion_documental (upc_nodo_padre)
    INCLUDE (upc_nivel_jerarquico, upc_prefijo_archivistico, upc_nombre_unidad);
CREATE NONCLUSTERED INDEX IX_upc_uaa_codigo
    ON sgspi.unidad_productora_cuadro_clasificacion_documental (upc_uaa_codigo);

-- 4B.4 [pdc], [epc], [src], [mcc], [idi], [fac] Catálogos Extensibles del Dominio Documental y Archivístico
CREATE TABLE sgspi.periodicidad_catalogo (
    pdc_codigo      SMALLINT      IDENTITY (1, 1) NOT NULL,
    pdc_nombre      NVARCHAR (40) NOT NULL, -- Ej: 'A solicitud', 'Diaria', 'Semanal', 'Mensual', 'Bimensual', 'Trimestral', 'Cuatrimestral', 'Semestral', 'Anual', 'Eventual'
    pdc_orden       TINYINT       CONSTRAINT DF_pdc_orden DEFAULT 1 NOT NULL, -- [AP-17]
    pdc_esta_activa BIT           CONSTRAINT DF_pdc_esta_activa DEFAULT 1 NOT NULL, -- [AP-17]
    CONSTRAINT PK_pdc_periodicidad_catalogo PRIMARY KEY CLUSTERED (pdc_codigo),
    CONSTRAINT UQ_pdc_nombre UNIQUE (pdc_nombre),
    CONSTRAINT CK_pdc_nombre_no_vacio CHECK (LEN(TRIM(pdc_nombre)) > 0)
);

CREATE TABLE sgspi.estado_publicacion_catalogo (
    epc_codigo      SMALLINT       IDENTITY (1, 1) NOT NULL,
    epc_nombre      NVARCHAR (60)  NOT NULL, -- Ej: 'Publicada (Externo - Internet)', 'Publicada (Interno - Intranet)', 'No publicada'
    epc_descripcion NVARCHAR (255) NULL,
    epc_esta_activo BIT            CONSTRAINT DF_epc_esta_activo DEFAULT 1 NOT NULL, -- [AP-17]
    CONSTRAINT PK_epc_estado_publicacion_catalogo PRIMARY KEY CLUSTERED (epc_codigo),
    CONSTRAINT UQ_epc_nombre UNIQUE (epc_nombre),
    CONSTRAINT CK_epc_nombre_no_vacio CHECK (LEN(TRIM(epc_nombre)) > 0)
);

CREATE TABLE sgspi.soporte_registro_catalogo (
    src_codigo      SMALLINT      IDENTITY (1, 1) NOT NULL,
    src_nombre      NVARCHAR (30) NOT NULL, -- Ej: 'Físico', 'Digital', 'Óptico'
    src_esta_activo BIT           CONSTRAINT DF_src_esta_activo DEFAULT 1 NOT NULL, -- [AP-17]
    CONSTRAINT PK_src_soporte_registro_catalogo PRIMARY KEY CLUSTERED (src_codigo),
    CONSTRAINT UQ_src_nombre UNIQUE (src_nombre),
    CONSTRAINT CK_src_nombre_no_vacio CHECK (LEN(TRIM(src_nombre)) > 0)
);

CREATE TABLE sgspi.medio_conservacion_catalogo (
    mcc_codigo      SMALLINT      IDENTITY (1, 1) NOT NULL,
    mcc_nombre      NVARCHAR (30) NOT NULL, -- Ej: 'Físico', 'Electrónico', 'Microfilm', 'Nube'
    mcc_esta_activo BIT           CONSTRAINT DF_mcc_esta_activo DEFAULT 1 NOT NULL, -- [AP-17]
    CONSTRAINT PK_mcc_medio_conservacion_catalogo PRIMARY KEY CLUSTERED (mcc_codigo),
    CONSTRAINT UQ_mcc_nombre UNIQUE (mcc_nombre),
    CONSTRAINT CK_mcc_nombre_no_vacio CHECK (LEN(TRIM(mcc_nombre)) > 0)
);

CREATE TABLE sgspi.idioma_catalogo (
    idi_codigo      SMALLINT      IDENTITY (1, 1) NOT NULL,
    idi_codigo_iso  NVARCHAR (10) NOT NULL, -- Ej: 'es', 'en', 'fr', 'pt' (ISO 639-1)
    idi_nombre      NVARCHAR (50) NOT NULL, -- Ej: 'Español', 'Inglés', 'Francés', 'Portugués'
    idi_esta_activo BIT           CONSTRAINT DF_idi_esta_activo DEFAULT 1 NOT NULL, -- [AP-17]
    CONSTRAINT PK_idi_idioma_catalogo PRIMARY KEY CLUSTERED (idi_codigo),
    CONSTRAINT UQ_idi_codigo_iso UNIQUE (idi_codigo_iso),
    CONSTRAINT UQ_idi_nombre UNIQUE (idi_nombre),
    CONSTRAINT CK_idi_nombre_no_vacio CHECK (LEN(TRIM(idi_nombre)) > 0)
);

-- [AP-08] Catálogo de formatos de archivo (reemplaza el texto libre formato en texto libre)
CREATE TABLE sgspi.formato_archivo_catalogo (
    fac_codigo      SMALLINT      IDENTITY (1, 1) NOT NULL,
    fac_nombre      NVARCHAR (60) NOT NULL, -- Ej: 'Documento de texto', 'Hoja de cálculo', 'PDF', 'Imagen', 'Audio', 'Video'
    fac_esta_activo BIT           CONSTRAINT DF_fac_esta_activo DEFAULT 1 NOT NULL, -- [AP-17]
    CONSTRAINT PK_fac_formato_archivo_catalogo PRIMARY KEY CLUSTERED (fac_codigo),
    CONSTRAINT UQ_fac_nombre UNIQUE (fac_nombre),
    CONSTRAINT CK_fac_nombre_no_vacio CHECK (LEN(TRIM(fac_nombre)) > 0)
);

-- 4B.5 [ado] Subtipo 1:1 de Activo Documental (Especialización Archivística de [sgspi].[activo_informacion] para ES-GSPI-MR-04 con System-Versioned Temporal Table)
-- [AP-10] PK compartida: ado_codigo ES el aci_codigo del supertipo (sin IDENTITY propio ni columna FK separada).
-- [AP-08] El tipo de activo documental se deriva de aci_tac_codigo y el formato se modela en [adf] (4B.6).
CREATE TABLE sgspi.activo_documental (
    ado_codigo                        INT                                         NOT NULL, -- [AP-10] PK compartida = [sgspi].[activo_informacion]([aci_codigo])
    ado_pev_codigo                    SMALLINT                                    NOT NULL, -- FK a [sgspi].[periodo_vigencia]([pev_codigo])
    ado_sdo_codigo                    SMALLINT                                    NOT NULL, -- FK a [sgspi].[serie_documental_catalogo]([sdo_codigo])
    ado_sbd_codigo                    INT                                         NULL, -- FK nullable a [sgspi].[subserie_documental_catalogo]([sbd_codigo]) (NULL si la serie no tiene subserie)
    ado_pdc_codigo                    SMALLINT                                    NOT NULL, -- FK a [sgspi].[periodicidad_catalogo]([pdc_codigo])
    ado_fecha_ingreso_tabla_retencion DATE                                        NULL,
    ado_fecha_ingreso_archivo         DATE                                        NULL,
    ado_epc_codigo                    SMALLINT                                    NOT NULL, -- FK a [sgspi].[estado_publicacion_catalogo]([epc_codigo])
    ado_lugar_consulta_ubicacion      NVARCHAR (255)                              NOT NULL, -- URL portal de transparencia o nombre de dependencia/archivo
    ado_per_codigo_revisor_archivo    INT                                         NULL, -- FK a [dbo].[persona]([per_codigo]): Aval específico Gestión Documental / Secretaría General
    ado_fecha_creacion                DATETIMEOFFSET (0)                          CONSTRAINT DF_ado_fecha_creacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17] (se elimina ado_fecha_actualizacion [AP-11]: ado_sys_inicio_utc es la fuente de verdad)
    ado_sys_inicio_utc                DATETIME2 (7) GENERATED ALWAYS AS ROW START HIDDEN NOT NULL, -- [AP-17] sin DEFAULT
    ado_sys_fin_utc                   DATETIME2 (7) GENERATED ALWAYS AS ROW END   HIDDEN NOT NULL, -- [AP-17] sin DEFAULT
    PERIOD FOR SYSTEM_TIME (ado_sys_inicio_utc, ado_sys_fin_utc),
    CONSTRAINT PK_ado_activo_documental PRIMARY KEY CLUSTERED (ado_codigo),
    CONSTRAINT FK_ado_activo_informacion FOREIGN KEY (ado_codigo) REFERENCES sgspi.activo_informacion (aci_codigo), -- [AP-10] PK compartida (reemplaza UQ_ado_activo_informacion)
    CONSTRAINT FK_ado_periodo_vigencia FOREIGN KEY (ado_pev_codigo) REFERENCES sgspi.periodo_vigencia (pev_codigo),
    CONSTRAINT FK_ado_serie_documental FOREIGN KEY (ado_sdo_codigo) REFERENCES sgspi.serie_documental_catalogo (sdo_codigo),
    CONSTRAINT FK_ado_subserie_documental FOREIGN KEY (ado_sdo_codigo, ado_sbd_codigo) REFERENCES sgspi.subserie_documental_catalogo (sbd_sdo_codigo, sbd_codigo),
    CONSTRAINT FK_ado_periodicidad FOREIGN KEY (ado_pdc_codigo) REFERENCES sgspi.periodicidad_catalogo (pdc_codigo),
    CONSTRAINT FK_ado_estado_publicacion FOREIGN KEY (ado_epc_codigo) REFERENCES sgspi.estado_publicacion_catalogo (epc_codigo),
    CONSTRAINT FK_ado_dbo_persona_revisor_archivo FOREIGN KEY (ado_per_codigo_revisor_archivo) REFERENCES dbo.persona (per_codigo)
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = sgspi.activo_documental_historial));

CREATE NONCLUSTERED INDEX IX_ado_pev_codigo
    ON sgspi.activo_documental (ado_pev_codigo, ado_sdo_codigo, ado_sbd_codigo); -- [AP-18] Se quita el INCLUDE de la columna eliminada (ado_codigo ya es clave clustered)
CREATE NONCLUSTERED INDEX IX_ado_sdo_sbd_codigo
    ON sgspi.activo_documental (ado_sdo_codigo, ado_sbd_codigo); -- [AP-18] Reemplaza IX_ado_sbd_codigo: sirve a FK_ado_serie_documental y FK_ado_subserie_documental
CREATE NONCLUSTERED INDEX IX_ado_pdc_codigo
    ON sgspi.activo_documental (ado_pdc_codigo);
CREATE NONCLUSTERED INDEX IX_ado_epc_codigo
    ON sgspi.activo_documental (ado_epc_codigo);
CREATE NONCLUSTERED INDEX IX_ado_per_codigo_revisor_archivo
    ON sgspi.activo_documental (ado_per_codigo_revisor_archivo);

-- 4B.6 [ads], [adm], [adi], [adf] Tablas Puente N:M de Atributos Atómicos de Activos Documentales hacia Catálogos Extensibles
CREATE TABLE sgspi.activo_documental_soporte_registro (
    ads_ado_codigo INT      NOT NULL, -- FK a [sgspi].[activo_documental]([ado_codigo])
    ads_src_codigo SMALLINT NOT NULL, -- FK a [sgspi].[soporte_registro_catalogo]([src_codigo])
    CONSTRAINT PK_ads_activo_documental_soporte_registro PRIMARY KEY CLUSTERED (ads_ado_codigo, ads_src_codigo),
    CONSTRAINT FK_ads_activo_documental FOREIGN KEY (ads_ado_codigo) REFERENCES sgspi.activo_documental (ado_codigo),
    CONSTRAINT FK_ads_soporte_registro_catalogo FOREIGN KEY (ads_src_codigo) REFERENCES sgspi.soporte_registro_catalogo (src_codigo)
);

CREATE NONCLUSTERED INDEX IX_ads_src_codigo
    ON sgspi.activo_documental_soporte_registro (ads_src_codigo); -- [AP-18] Sin INCLUDE: ads_ado_codigo ya es clave clustered

CREATE TABLE sgspi.activo_documental_medio_conservacion (
    adm_ado_codigo INT      NOT NULL, -- FK a [sgspi].[activo_documental]([ado_codigo])
    adm_mcc_codigo SMALLINT NOT NULL, -- FK a [sgspi].[medio_conservacion_catalogo]([mcc_codigo])
    CONSTRAINT PK_adm_activo_documental_medio_conservacion PRIMARY KEY CLUSTERED (adm_ado_codigo, adm_mcc_codigo),
    CONSTRAINT FK_adm_activo_documental FOREIGN KEY (adm_ado_codigo) REFERENCES sgspi.activo_documental (ado_codigo),
    CONSTRAINT FK_adm_medio_conservacion_catalogo FOREIGN KEY (adm_mcc_codigo) REFERENCES sgspi.medio_conservacion_catalogo (mcc_codigo)
);

CREATE NONCLUSTERED INDEX IX_adm_mcc_codigo
    ON sgspi.activo_documental_medio_conservacion (adm_mcc_codigo); -- [AP-18] Sin INCLUDE: adm_ado_codigo ya es clave clustered

CREATE TABLE sgspi.activo_documental_idioma (
    adi_ado_codigo INT      NOT NULL, -- FK a [sgspi].[activo_documental]([ado_codigo])
    adi_idi_codigo SMALLINT NOT NULL, -- FK a [sgspi].[idioma_catalogo]([idi_codigo])
    CONSTRAINT PK_adi_activo_documental_idioma PRIMARY KEY CLUSTERED (adi_ado_codigo, adi_idi_codigo),
    CONSTRAINT FK_adi_activo_documental FOREIGN KEY (adi_ado_codigo) REFERENCES sgspi.activo_documental (ado_codigo),
    CONSTRAINT FK_adi_idioma_catalogo FOREIGN KEY (adi_idi_codigo) REFERENCES sgspi.idioma_catalogo (idi_codigo)
);

CREATE NONCLUSTERED INDEX IX_adi_idi_codigo
    ON sgspi.activo_documental_idioma (adi_idi_codigo); -- [AP-18] Sin INCLUDE: adi_ado_codigo ya es clave clustered

-- [AP-08] [adf] Formatos de archivo del activo documental (reemplaza el texto libre formato en texto libre)
CREATE TABLE sgspi.activo_documental_formato_archivo (
    adf_ado_codigo INT      NOT NULL, -- FK a [sgspi].[activo_documental]([ado_codigo])
    adf_fac_codigo SMALLINT NOT NULL, -- FK a [sgspi].[formato_archivo_catalogo]([fac_codigo])
    CONSTRAINT PK_adf_activo_documental_formato_archivo PRIMARY KEY CLUSTERED (adf_ado_codigo, adf_fac_codigo),
    CONSTRAINT FK_adf_activo_documental FOREIGN KEY (adf_ado_codigo) REFERENCES sgspi.activo_documental (ado_codigo),
    CONSTRAINT FK_adf_formato_archivo_catalogo FOREIGN KEY (adf_fac_codigo) REFERENCES sgspi.formato_archivo_catalogo (fac_codigo)
);

CREATE NONCLUSTERED INDEX IX_adf_fac_codigo
    ON sgspi.activo_documental_formato_archivo (adf_fac_codigo); -- [AP-18] Sin INCLUDE: adf_ado_codigo ya es clave clustered

-- 4B.7 [adu] Asignación N:M Activo Documental <-> Unidad Productora del CCD/TRD (Modela las 240 filas de desglose TRD sin cadenas multivaluadas)
CREATE TABLE sgspi.activo_documental_unidad_productora (
    adu_ado_codigo  INT NOT NULL, -- FK a [sgspi].[activo_documental]([ado_codigo])
    adu_upc_codigo  INT NOT NULL, -- FK a [sgspi].[unidad_productora_cuadro_clasificacion_documental]([upc_codigo]) (Unidad más específica donde se produce la serie/subserie)
    adu_esta_activo BIT CONSTRAINT DF_adu_esta_activo DEFAULT 1 NOT NULL, -- [AP-17]
    CONSTRAINT PK_adu_activo_documental_unidad_productora PRIMARY KEY CLUSTERED (adu_ado_codigo, adu_upc_codigo),
    CONSTRAINT FK_adu_activo_documental FOREIGN KEY (adu_ado_codigo) REFERENCES sgspi.activo_documental (ado_codigo),
    CONSTRAINT FK_adu_unidad_productora_cuadro_clasificacion_documental FOREIGN KEY (adu_upc_codigo) REFERENCES sgspi.unidad_productora_cuadro_clasificacion_documental (upc_codigo)
);

CREATE NONCLUSTERED INDEX IX_adu_upc_codigo
    ON sgspi.activo_documental_unidad_productora (adu_upc_codigo)
    INCLUDE (adu_esta_activo);



GO
/*==================================================================================================
  5. DOMINIO DE RIESGOS, OPORTUNIDADES, PLAN DE TRATAMIENTO Y SOA (DOCUMENTO 5: ES-GSPI-MR-06)
     Articulado con [dbo].[persona], [dbo].[cargo], [dbo].[uaa], [dbo].[grupo] y [dbo].[usuario_grupo]
==================================================================================================*/
-- 5.1 [epr], [eim], [zrc], [mvr] Tablas Paramétricas del Mapa de Calor 5x5 (Probabilidad A..E x Impacto 1..5)
CREATE TABLE sgspi.escala_probabilidad (
    epr_codigo                TINYINT        NOT NULL, -- 5=A (Casi seguro), 4=B (Probable), 3=C (Posible), 2=D (Improbable), 1=E (Raro)
    epr_codigo_letra          CHAR (1)       NOT NULL, -- 'A', 'B', 'C', 'D', 'E'
    epr_nombre_nivel          NVARCHAR (30)  NOT NULL,
    epr_descripcion_criterio  NVARCHAR (255) NOT NULL,
    epr_frecuencia_referencia NVARCHAR (100) NOT NULL,
    CONSTRAINT PK_epr_escala_probabilidad PRIMARY KEY CLUSTERED (epr_codigo),
    CONSTRAINT UQ_epr_codigo_letra UNIQUE (epr_codigo_letra),
    CONSTRAINT CK_epr_rango CHECK (epr_codigo BETWEEN 1 AND 5
                                   AND epr_codigo_letra IN ('A', 'B', 'C', 'D', 'E')),
    -- [AP-09] La letra es derivable del código numérico (5=A ... 1=E): se garantiza la coherencia entre ambas
    CONSTRAINT CK_epr_letra_coherente CHECK (ASCII(epr_codigo_letra) = 70 - epr_codigo)
);

CREATE TABLE sgspi.escala_impacto (
    eim_codigo                     TINYINT         NOT NULL, -- 1=Insignificante, 2=Menor, 3=Moderado, 4=Mayor, 5=Catastrófico / Altamente beneficioso
    eim_nombre_impacto_negativo    NVARCHAR (30)   NOT NULL,
    eim_nombre_impacto_positivo    NVARCHAR (40)   NOT NULL,
    eim_descripcion_organizacional NVARCHAR (1000) NOT NULL,
    eim_descripcion_operativa      NVARCHAR (1000) NULL,
    CONSTRAINT PK_eim_escala_impacto PRIMARY KEY CLUSTERED (eim_codigo),
    CONSTRAINT CK_eim_rango CHECK (eim_codigo BETWEEN 1 AND 5)
);

-- [AP-09] Catálogo de zonas de riesgo: reemplaza mvr_codigo_zona (código) + mvr_nivel_valoracion (nombre), dependencia transitiva
CREATE TABLE sgspi.zona_riesgo_catalogo (
    zrc_codigo       CHAR (1)      NOT NULL, -- 'B' (Bajo), 'M' (Moderado), 'A' (Alto), 'E' (Extremo)
    zrc_nombre_nivel NVARCHAR (30) NOT NULL, -- 'Riesgo Inferior', 'Riesgo Moderado', 'Riesgo Alto', 'Riesgo Extremo'
    zrc_orden        TINYINT       NOT NULL, -- 1 (menor severidad) .. 4 (mayor severidad)
    CONSTRAINT PK_zrc_zona_riesgo_catalogo PRIMARY KEY CLUSTERED (zrc_codigo),
    CONSTRAINT UQ_zrc_nombre_nivel UNIQUE (zrc_nombre_nivel),
    CONSTRAINT UQ_zrc_orden UNIQUE (zrc_orden)
);
GO

-- [AP-09] Semilla de zonas de riesgo (bloque propio: la tabla ya existe en el lote anterior)
INSERT INTO sgspi.zona_riesgo_catalogo (zrc_codigo, zrc_nombre_nivel, zrc_orden)
VALUES ('B', N'Riesgo Inferior', 1),
       ('M', N'Riesgo Moderado', 2),
       ('A', N'Riesgo Alto', 3),
       ('E', N'Riesgo Extremo', 4);
GO

CREATE TABLE sgspi.matriz_valoracion_riesgo (
    mvr_epr_codigo                        TINYINT        NOT NULL, -- FK a [sgspi].[escala_probabilidad]([epr_codigo])
    mvr_eim_codigo                        TINYINT        NOT NULL, -- FK a [sgspi].[escala_impacto]([eim_codigo])
    -- [AP-09] Columna calculada PERSISTED: 'A1'..'E5' deriva de probabilidad (5=A..1=E) e impacto
    mvr_codigo_posicion                   AS (CONVERT (CHAR (2), CONCAT(CHAR(70 - mvr_epr_codigo), mvr_eim_codigo))) PERSISTED NOT NULL,
    mvr_zrc_codigo                        CHAR (1)       NOT NULL, -- [AP-09] FK a [sgspi].[zona_riesgo_catalogo]([zrc_codigo]) (antes mvr_codigo_zona + mvr_nivel_valoracion)
    mvr_directriz_tratamiento_riesgo      NVARCHAR (255) NOT NULL,
    mvr_directriz_tratamiento_oportunidad NVARCHAR (255) NOT NULL,
    mvr_requiere_aprobacion_comite        BIT            CONSTRAINT DF_mvr_requiere_aprobacion_comite DEFAULT 0 NOT NULL, -- [AP-17]
    CONSTRAINT PK_mvr_matriz_valoracion_riesgo PRIMARY KEY CLUSTERED (mvr_epr_codigo, mvr_eim_codigo),
    CONSTRAINT UQ_mvr_codigo_posicion UNIQUE (mvr_codigo_posicion),
    CONSTRAINT FK_mvr_escala_probabilidad FOREIGN KEY (mvr_epr_codigo) REFERENCES sgspi.escala_probabilidad (epr_codigo),
    CONSTRAINT FK_mvr_escala_impacto FOREIGN KEY (mvr_eim_codigo) REFERENCES sgspi.escala_impacto (eim_codigo),
    CONSTRAINT FK_mvr_zona_riesgo FOREIGN KEY (mvr_zrc_codigo) REFERENCES sgspi.zona_riesgo_catalogo (zrc_codigo) -- [AP-09] reemplaza CK_mvr_codigo_zona
);

CREATE NONCLUSTERED INDEX IX_mvr_eim_codigo
    ON sgspi.matriz_valoracion_riesgo (mvr_eim_codigo);
CREATE NONCLUSTERED INDEX IX_mvr_zrc_codigo -- [AP-18] soporte de la FK a zrc
    ON sgspi.matriz_valoracion_riesgo (mvr_zrc_codigo);

-- 5.2 [eia] Escenarios de Incertidumbre sobre Activos (Riesgos RA-XX y Oportunidades OA-XX con System-Versioned Temporal Table)
CREATE TABLE sgspi.evento_incertidumbre_activo (
    eia_codigo                      INT                                         IDENTITY (1, 1) NOT NULL,
    eia_pev_codigo                  SMALLINT                                    NOT NULL, -- FK a [sgspi].[periodo_vigencia]([pev_codigo])
    eia_identificador_evento        NVARCHAR (15)                               NOT NULL, -- 'RA-01'..'RA-15', 'OA-01'..'OA-09'
    eia_naturaleza_evento           NVARCHAR (15)                               NOT NULL, -- 'RIESGO' (-), 'OPORTUNIDAD' (+)
    eia_pri_codigo                  INT                                         NOT NULL, -- FK a [sgspi].[proceso_institucional]([pri_codigo])
    eia_aci_codigo_primario         INT                                         NOT NULL, -- FK a [sgspi].[activo_informacion]([aci_codigo])
    eia_aci_codigo_soporte          INT                                         NOT NULL, -- FK a [sgspi].[activo_informacion]([aci_codigo])
    -- [AP-08] Componente afectado vía catálogo de tipos de activo (solo categorías de nivel 1: Información, Software, Servicio, Infraestructura, Hardware)
    eia_tac_codigo_componente       SMALLINT                                    NOT NULL, -- FK a [sgspi].[tipo_activo_catalogo]([tac_codigo])
    eia_tac_nivel_componente        AS (CONVERT (TINYINT, 1)) PERSISTED, -- [AP-08] columna constante: fuerza nivel 1 de la taxonomía en la FK compuesta
    eia_fuente_generadora           NVARCHAR (255)                              NOT NULL,
    eia_controles_existentes        NVARCHAR (1000)                             NULL,
    eia_condicion_vulnerabilidad    NVARCHAR (1000)                             NOT NULL,
    eia_efecto_consecuencia         NVARCHAR (1000)                             NOT NULL,
    eia_escenario_operacional       NVARCHAR (255)                              NOT NULL,
    -- Valoración Inherente / Actual
    eia_epr_codigo_inherente        TINYINT                                     NOT NULL,
    eia_eim_codigo_inherente        TINYINT                                     NOT NULL,
    -- Máquina de Estados Principal y Firmas sobre [dbo].[persona]
    eia_estado_registro             NVARCHAR (30)                               CONSTRAINT DF_eia_estado_registro DEFAULT N'BORRADOR' NOT NULL, -- [AP-17]
    eia_efc_dominio                 AS (CONVERT (NVARCHAR (10), N'EIA')) PERSISTED, -- [AP-05] dominio constante para la FK al catálogo de estados
    eia_per_codigo_creador          INT                                         NOT NULL, -- FK a [dbo].[persona]([per_codigo])
    eia_per_codigo_validador_lider  INT                                         NULL, -- FK a [dbo].[persona]([per_codigo])
    eia_per_codigo_revisor_sgspi    INT                                         NULL, -- FK a [dbo].[persona]([per_codigo])
    eia_per_codigo_aprobador_comite INT                                         NULL, -- FK a [dbo].[persona]([per_codigo])
    eia_fecha_creacion              DATETIMEOFFSET (0)                          CONSTRAINT DF_eia_fecha_creacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17] [AP-11: se elimina eia_fecha_actualizacion]
    eia_sys_inicio_utc              DATETIME2 (7) GENERATED ALWAYS AS ROW START HIDDEN NOT NULL, -- [AP-17] sin DEFAULT
    eia_sys_fin_utc                 DATETIME2 (7) GENERATED ALWAYS AS ROW END   HIDDEN NOT NULL, -- [AP-17] sin DEFAULT
    PERIOD FOR SYSTEM_TIME (eia_sys_inicio_utc, eia_sys_fin_utc),
    CONSTRAINT PK_eia_evento_incertidumbre_activo PRIMARY KEY CLUSTERED (eia_codigo),
    CONSTRAINT UQ_eia_vigencia_identificador UNIQUE (eia_pev_codigo, eia_identificador_evento),
    CONSTRAINT UQ_eia_codigo_naturaleza UNIQUE (eia_codigo, eia_naturaleza_evento), -- [AP-06] destino de la FK compuesta de plt
    CONSTRAINT FK_eia_periodo_vigencia FOREIGN KEY (eia_pev_codigo) REFERENCES sgspi.periodo_vigencia (pev_codigo),
    CONSTRAINT FK_eia_proceso_institucional FOREIGN KEY (eia_pri_codigo) REFERENCES sgspi.proceso_institucional (pri_codigo),
    CONSTRAINT FK_eia_activo_primario FOREIGN KEY (eia_aci_codigo_primario) REFERENCES sgspi.activo_informacion (aci_codigo),
    CONSTRAINT FK_eia_activo_soporte FOREIGN KEY (eia_aci_codigo_soporte) REFERENCES sgspi.activo_informacion (aci_codigo),
    CONSTRAINT FK_eia_tipo_activo_componente FOREIGN KEY (eia_tac_codigo_componente, eia_tac_nivel_componente) REFERENCES sgspi.tipo_activo_catalogo (tac_codigo, tac_nivel_taxonomia), -- [AP-08]
    CONSTRAINT FK_eia_valoracion_inherente FOREIGN KEY (eia_epr_codigo_inherente, eia_eim_codigo_inherente) REFERENCES sgspi.matriz_valoracion_riesgo (mvr_epr_codigo, mvr_eim_codigo),
    CONSTRAINT FK_eia_estado_flujo FOREIGN KEY (eia_efc_dominio, eia_estado_registro) REFERENCES sgspi.estado_flujo_catalogo (efc_dominio, efc_identificador), -- [AP-05] reemplaza CK_eia_estado_maquina
    CONSTRAINT FK_eia_dbo_persona_creador FOREIGN KEY (eia_per_codigo_creador) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT FK_eia_dbo_persona_validador FOREIGN KEY (eia_per_codigo_validador_lider) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT FK_eia_dbo_persona_revisor FOREIGN KEY (eia_per_codigo_revisor_sgspi) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT FK_eia_dbo_persona_comite FOREIGN KEY (eia_per_codigo_aprobador_comite) REFERENCES dbo.persona (per_codigo),
    -- RN-RSG-01: Exclusión Mutua Riesgo (RA-) vs Oportunidad (OA-)
    -- [AP-13] Formato estricto: prefijo 'RA-' / 'OA-' seguido de 2 o 3 dígitos y nada más (LEN 5..6)
    CONSTRAINT CK_eia_naturaleza_prefijo CHECK ((eia_naturaleza_evento = N'RIESGO'
                                                 AND eia_identificador_evento LIKE N'RA-%'
                                                 AND LEN(eia_identificador_evento) BETWEEN 5 AND 6
                                                 AND SUBSTRING(eia_identificador_evento, 4, 3) NOT LIKE N'%[^0-9]%')
                                                OR (eia_naturaleza_evento = N'OPORTUNIDAD'
                                                    AND eia_identificador_evento LIKE N'OA-%'
                                                    AND LEN(eia_identificador_evento) BETWEEN 5 AND 6
                                                    AND SUBSTRING(eia_identificador_evento, 4, 3) NOT LIKE N'%[^0-9]%')),
    -- [AP-15] Segregación de funciones ISO 27001 A.5.3: ninguna firma (validador, revisor, comité) puede ser del creador
    CONSTRAINT CK_eia_sod_firmas CHECK ((eia_per_codigo_validador_lider IS NULL
                                         OR eia_per_codigo_validador_lider <> eia_per_codigo_creador)
                                        AND (eia_per_codigo_revisor_sgspi IS NULL
                                             OR eia_per_codigo_revisor_sgspi <> eia_per_codigo_creador)
                                        AND (eia_per_codigo_aprobador_comite IS NULL
                                             OR eia_per_codigo_aprobador_comite <> eia_per_codigo_creador))
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = sgspi.evento_incertidumbre_activo_historial));

CREATE NONCLUSTERED INDEX IX_eia_pri_codigo
    ON sgspi.evento_incertidumbre_activo (eia_pri_codigo);
CREATE NONCLUSTERED INDEX IX_eia_aci_codigo_primario
    ON sgspi.evento_incertidumbre_activo (eia_aci_codigo_primario);
CREATE NONCLUSTERED INDEX IX_eia_aci_codigo_soporte
    ON sgspi.evento_incertidumbre_activo (eia_aci_codigo_soporte);
CREATE NONCLUSTERED INDEX IX_eia_tac_codigo_componente -- [AP-08] [AP-18] soporte de la FK compuesta a tac
    ON sgspi.evento_incertidumbre_activo (eia_tac_codigo_componente, eia_tac_nivel_componente);
CREATE NONCLUSTERED INDEX IX_eia_valoracion_inherente
    ON sgspi.evento_incertidumbre_activo (eia_epr_codigo_inherente, eia_eim_codigo_inherente);
CREATE NONCLUSTERED INDEX IX_eia_per_codigo_creador
    ON sgspi.evento_incertidumbre_activo (eia_per_codigo_creador);
CREATE NONCLUSTERED INDEX IX_eia_per_codigo_validador_lider
    ON sgspi.evento_incertidumbre_activo (eia_per_codigo_validador_lider);
CREATE NONCLUSTERED INDEX IX_eia_per_codigo_revisor_sgspi
    ON sgspi.evento_incertidumbre_activo (eia_per_codigo_revisor_sgspi);
CREATE NONCLUSTERED INDEX IX_eia_per_codigo_aprobador_comite
    ON sgspi.evento_incertidumbre_activo (eia_per_codigo_aprobador_comite);

-- 5.3 [etc] y [plt] Catálogo Extensible de Estrategias y Plan de Tratamiento de Riesgos y Oportunidades
CREATE TABLE sgspi.estrategia_tratamiento_catalogo (
    etc_codigo               SMALLINT       IDENTITY (1, 1) NOT NULL,
    etc_nombre_estrategia    NVARCHAR (80)  NOT NULL, -- Ej: 'Mitigar o reducir', 'Compartir o transferir el riesgo', 'Evitar el riesgo', 'Potenciar o explotar la oportunidad'
    etc_naturaleza_aplicable NVARCHAR (15)  NOT NULL, -- 'RIESGO', 'OPORTUNIDAD'
    etc_descripcion          NVARCHAR (255) NULL,
    etc_esta_activa          BIT            CONSTRAINT DF_etc_esta_activa DEFAULT 1 NOT NULL, -- [AP-17]
    CONSTRAINT PK_etc_estrategia_tratamiento_catalogo PRIMARY KEY CLUSTERED (etc_codigo),
    CONSTRAINT UQ_etc_nombre_estrategia UNIQUE (etc_nombre_estrategia),
    CONSTRAINT UQ_etc_codigo_naturaleza UNIQUE (etc_codigo, etc_naturaleza_aplicable), -- [AP-06] destino de la FK compuesta de plt
    CONSTRAINT CK_etc_nombre_no_vacio CHECK (LEN(TRIM(etc_nombre_estrategia)) > 0),
    CONSTRAINT CK_etc_naturaleza_aplicable CHECK (etc_naturaleza_aplicable IN (N'RIESGO', N'OPORTUNIDAD'))
);

CREATE TABLE sgspi.plan_tratamiento (
    plt_codigo                      INT             IDENTITY (1, 1) NOT NULL,
    plt_eia_codigo                  INT             NOT NULL, -- FK a [sgspi].[evento_incertidumbre_activo]([eia_codigo])
    plt_naturaleza_evento           NVARCHAR (15)   NOT NULL, -- [AP-06] 'RIESGO'/'OPORTUNIDAD': debe coincidir con el evento y con la estrategia (FK compuestas)
    plt_etc_codigo                  SMALLINT        NOT NULL, -- FK a [sgspi].[estrategia_tratamiento_catalogo]([etc_codigo])
    plt_justificacion_estrategia    NVARCHAR (1000) NOT NULL,
    -- Valoración Residual Esperada (Meta)
    plt_epr_codigo_residual_meta    TINYINT         NOT NULL,
    plt_eim_codigo_residual_meta    TINYINT         NOT NULL,
    plt_fecha_inicio                DATE            NOT NULL,
    plt_fecha_fin                   DATE            NOT NULL,
    plt_recursos_humanos_tecnicos   NVARCHAR (500)  NOT NULL,
    plt_recursos_economicos_desc    NVARCHAR (500)  NOT NULL,
    plt_presupuesto_estimado_cop    DECIMAL (18, 2) NULL,
    plt_restricciones_limitaciones  NVARCHAR (500)  NULL,
    plt_nombre_indicador_kpi        NVARCHAR (255)  NOT NULL,
    plt_unidad_medida_kpi           NVARCHAR (30)   CONSTRAINT DF_plt_unidad_medida_kpi DEFAULT N'PORCENTAJE' NOT NULL, -- [AP-17] Ej: 'PORCENTAJE', 'CANTIDAD', 'DIAS', 'HORAS'
    plt_meta_indicador_kpi          DECIMAL (10, 2) NOT NULL,
    plt_valor_alcanzado_kpi         DECIMAL (10, 2) NULL,
    -- [AP-16] DECIMAL (9, 2) (antes (6, 2), desbordaba con valores alcanzados muy superiores a la meta)
    plt_porcentaje_cumplimiento_kpi AS              (CASE WHEN plt_meta_indicador_kpi > 0
                                                               AND plt_valor_alcanzado_kpi IS NOT NULL THEN CAST (ROUND((plt_valor_alcanzado_kpi / plt_meta_indicador_kpi) * 100.0, 2) AS DECIMAL (9, 2)) ELSE NULL END),
    plt_es_tratamiento_eficaz       BIT             NULL,
    plt_dictamen_eficacia           NVARCHAR (1000) NULL,
    plt_per_codigo_evaluador        INT             NULL, -- FK a [dbo].[persona]([per_codigo])
    plt_fecha_evaluacion_eficacia   DATETIMEOFFSET (0) NULL, -- [AP-12]
    plt_fecha_creacion              DATETIMEOFFSET (0) CONSTRAINT DF_plt_fecha_creacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17]
    plt_fecha_actualizacion         DATETIMEOFFSET (0) CONSTRAINT DF_plt_fecha_actualizacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17]
    CONSTRAINT PK_plt_plan_tratamiento PRIMARY KEY CLUSTERED (plt_codigo),
    CONSTRAINT UQ_plt_evento UNIQUE (plt_eia_codigo),
    -- [AP-06] FK compuestas: la naturaleza del plan coincide con la del evento y con la de la estrategia
    CONSTRAINT FK_plt_evento_incertidumbre FOREIGN KEY (plt_eia_codigo, plt_naturaleza_evento) REFERENCES sgspi.evento_incertidumbre_activo (eia_codigo, eia_naturaleza_evento),
    CONSTRAINT FK_plt_estrategia_tratamiento FOREIGN KEY (plt_etc_codigo, plt_naturaleza_evento) REFERENCES sgspi.estrategia_tratamiento_catalogo (etc_codigo, etc_naturaleza_aplicable),
    CONSTRAINT FK_plt_valoracion_meta FOREIGN KEY (plt_epr_codigo_residual_meta, plt_eim_codigo_residual_meta) REFERENCES sgspi.matriz_valoracion_riesgo (mvr_epr_codigo, mvr_eim_codigo),
    CONSTRAINT FK_plt_dbo_persona_evaluador FOREIGN KEY (plt_per_codigo_evaluador) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_plt_naturaleza_evento CHECK (plt_naturaleza_evento IN (N'RIESGO', N'OPORTUNIDAD')), -- [AP-06]
    -- RN-RSG-06: Validación de cronogramas y métricas numéricas KPI
    CONSTRAINT CK_plt_cronograma CHECK (plt_fecha_fin >= plt_fecha_inicio),
    CONSTRAINT CK_plt_unidad_medida_kpi_no_vacia CHECK (LEN(TRIM(plt_unidad_medida_kpi)) > 0),
    CONSTRAINT CK_plt_valores_kpi CHECK (plt_meta_indicador_kpi > 0
                                         AND (plt_valor_alcanzado_kpi IS NULL
                                              OR plt_valor_alcanzado_kpi >= 0)),
    -- [AP-16] Coherencia de la evaluación de eficacia: los cuatro campos juntos o ninguno, con dictamen no vacío
    CONSTRAINT CK_plt_coherencia_eficacia CHECK ((plt_es_tratamiento_eficaz IS NULL
                                                  AND plt_dictamen_eficacia IS NULL
                                                  AND plt_per_codigo_evaluador IS NULL
                                                  AND plt_fecha_evaluacion_eficacia IS NULL)
                                                 OR (plt_es_tratamiento_eficaz IS NOT NULL
                                                     AND plt_dictamen_eficacia IS NOT NULL
                                                     AND LEN(TRIM(plt_dictamen_eficacia)) > 0
                                                     AND plt_per_codigo_evaluador IS NOT NULL
                                                     AND plt_fecha_evaluacion_eficacia IS NOT NULL))
);

CREATE NONCLUSTERED INDEX IX_plt_etc_codigo
    ON sgspi.plan_tratamiento (plt_etc_codigo, plt_naturaleza_evento); -- [AP-18] cubre la FK compuesta a etc
CREATE NONCLUSTERED INDEX IX_plt_valoracion_residual_meta
    ON sgspi.plan_tratamiento (plt_epr_codigo_residual_meta, plt_eim_codigo_residual_meta);
CREATE NONCLUSTERED INDEX IX_plt_per_codigo_evaluador
    ON sgspi.plan_tratamiento (plt_per_codigo_evaluador);

-- 5.4 [act] y [sga] Desglose de Actividades del Plan de Tratamiento y Seguimiento con Evidencias
CREATE TABLE sgspi.actividad_tratamiento (
    act_codigo                INT            IDENTITY (1, 1) NOT NULL,
    act_plt_codigo            INT            NOT NULL, -- FK a [sgspi].[plan_tratamiento]([plt_codigo])
    act_numero_orden          SMALLINT       CONSTRAINT DF_act_numero_orden DEFAULT 1 NOT NULL, -- [AP-17]
    act_descripcion_actividad NVARCHAR (500) NOT NULL,
    act_car_codigo            INT            NULL, -- FK a [dbo].[cargo]([car_codigo])
    act_uaa_codigo            INT            NULL, -- FK a [dbo].[uaa]([uaa_codigo])
    act_fecha_compromiso      DATE           NOT NULL,
    act_porcentaje_avance     TINYINT        CONSTRAINT DF_act_porcentaje_avance DEFAULT 0 NOT NULL, -- [AP-17]
    act_estado_actividad      NVARCHAR (30)  CONSTRAINT DF_act_estado_actividad DEFAULT N'PENDIENTE' NOT NULL, -- [AP-05] [AP-17] ampliada de 20 a 30
    act_efc_dominio           AS (CONVERT (NVARCHAR (10), N'ACT')) PERSISTED, -- [AP-05] dominio constante para la FK al catálogo de estados
    act_fecha_creacion        DATETIMEOFFSET (0) CONSTRAINT DF_act_fecha_creacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17]
    act_fecha_actualizacion   DATETIMEOFFSET (0) CONSTRAINT DF_act_fecha_actualizacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17]
    CONSTRAINT PK_act_actividad_tratamiento PRIMARY KEY CLUSTERED (act_codigo),
    CONSTRAINT UQ_act_plan_orden UNIQUE (act_plt_codigo, act_numero_orden), -- [AP-14] clave natural; también cubre la FK a plt
    CONSTRAINT FK_act_plan_tratamiento FOREIGN KEY (act_plt_codigo) REFERENCES sgspi.plan_tratamiento (plt_codigo),
    CONSTRAINT FK_act_dbo_cargo FOREIGN KEY (act_car_codigo) REFERENCES dbo.cargo (car_codigo),
    CONSTRAINT FK_act_dbo_uaa FOREIGN KEY (act_uaa_codigo) REFERENCES dbo.uaa (uaa_codigo),
    CONSTRAINT FK_act_estado_flujo FOREIGN KEY (act_efc_dominio, act_estado_actividad) REFERENCES sgspi.estado_flujo_catalogo (efc_dominio, efc_identificador), -- [AP-05] reemplaza CK_act_estado_actividad
    CONSTRAINT CK_act_numero_orden_positivo CHECK (act_numero_orden >= 1), -- [AP-14]
    CONSTRAINT CK_act_porcentaje_avance CHECK (act_porcentaje_avance BETWEEN 0 AND 100),
    -- [AP-16] Una actividad COMPLETADA debe estar al 100 % de avance
    CONSTRAINT CK_act_completada_al_100 CHECK (act_estado_actividad <> N'COMPLETADA'
                                               OR act_porcentaje_avance = 100)
);

-- [AP-14] IX_act_plt_codigo eliminado: lo cubre UQ_act_plan_orden (act_plt_codigo es su primera columna)
CREATE NONCLUSTERED INDEX IX_act_car_codigo
    ON sgspi.actividad_tratamiento (act_car_codigo);
CREATE NONCLUSTERED INDEX IX_act_uaa_codigo
    ON sgspi.actividad_tratamiento (act_uaa_codigo);

CREATE TABLE sgspi.seguimiento_actividad (
    sga_codigo                       INT             IDENTITY (1, 1) NOT NULL,
    sga_act_codigo                   INT             NOT NULL, -- FK a [sgspi].[actividad_tratamiento]([act_codigo])
    sga_per_codigo                   INT             NOT NULL, -- FK a [dbo].[persona]([per_codigo])
    sga_fecha_registro               DATETIMEOFFSET (0) CONSTRAINT DF_sga_fecha_registro DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17]
    sga_porcentaje_reportado         TINYINT         NOT NULL,
    sga_descripcion_avance           NVARCHAR (1000) NOT NULL,
    sga_nombre_archivo_evidencia     NVARCHAR (255)  NULL,
    sga_uri_almacenamiento_evidencia NVARCHAR (500)  NULL,
    sga_hash_sha256_evidencia        CHAR (64)       NULL,
    CONSTRAINT PK_sga_seguimiento_actividad PRIMARY KEY CLUSTERED (sga_codigo),
    CONSTRAINT FK_sga_actividad_tratamiento FOREIGN KEY (sga_act_codigo) REFERENCES sgspi.actividad_tratamiento (act_codigo),
    CONSTRAINT FK_sga_dbo_persona FOREIGN KEY (sga_per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_sga_porcentaje_reportado CHECK (sga_porcentaje_reportado BETWEEN 0 AND 100),
    -- [AP-16] La evidencia se registra completa (nombre, URI y hash) o no se registra
    CONSTRAINT CK_sga_evidencia_completa CHECK ((sga_nombre_archivo_evidencia IS NULL
                                                 AND sga_uri_almacenamiento_evidencia IS NULL
                                                 AND sga_hash_sha256_evidencia IS NULL)
                                                OR (sga_nombre_archivo_evidencia IS NOT NULL
                                                    AND sga_uri_almacenamiento_evidencia IS NOT NULL
                                                    AND sga_hash_sha256_evidencia IS NOT NULL)),
    -- [AP-16] Formato del hash SHA-256: 64 caracteres hexadecimales
    CONSTRAINT CK_sga_hash_formato CHECK (sga_hash_sha256_evidencia IS NULL
                                          OR (LEN(sga_hash_sha256_evidencia) = 64
                                              AND sga_hash_sha256_evidencia NOT LIKE '%[^0-9A-Fa-f]%'))
);

CREATE NONCLUSTERED INDEX IX_sga_act_codigo
    ON sgspi.seguimiento_actividad (sga_act_codigo);
CREATE NONCLUSTERED INDEX IX_sga_per_codigo
    ON sgspi.seguimiento_actividad (sga_per_codigo);

-- 5.5 [enc] y [crn] Catálogo Extensible de Estándares Normativos y Controles de Referencia (ISO/IEC 27001:2022 [93], ISO/IEC 27701:2025 [71], etc.)
CREATE TABLE sgspi.estandar_normativo_catalogo (
    enc_codigo        SMALLINT       IDENTITY (1, 1) NOT NULL,
    enc_identificador NVARCHAR (50)  NOT NULL, -- Ej: 'ISO/IEC 27001:2022', 'ISO/IEC 27701:2025', 'ISO/IEC 27002:2022', 'ISO/IEC 42001:2023'
    enc_familia_norma NVARCHAR (20)  NOT NULL, -- [AP-13] Ej: 'ISO27001', 'ISO27701', 'ISO27002', 'NIST_CSF'; una edición activa por familia
    enc_nombre        NVARCHAR (200) NOT NULL,
    enc_organismo     NVARCHAR (100) NULL,     -- Ej: 'ISO/IEC', 'NIST', 'MinTIC'
    enc_anio_edicion  SMALLINT       NULL,
    enc_esta_activo   BIT            CONSTRAINT DF_enc_esta_activo DEFAULT 1 NOT NULL, -- [AP-17]
    CONSTRAINT PK_enc_estandar_normativo_catalogo PRIMARY KEY CLUSTERED (enc_codigo),
    CONSTRAINT UQ_enc_identificador UNIQUE (enc_identificador),
    CONSTRAINT CK_enc_identificador_no_vacio CHECK (LEN(TRIM(enc_identificador)) > 0),
    CONSTRAINT CK_enc_familia_norma_no_vacia CHECK (LEN(TRIM(enc_familia_norma)) > 0) -- [AP-13]
);

-- [AP-13] Una sola edición activa por familia de norma (reemplaza filtros por cadena de edición en vistas)
CREATE UNIQUE NONCLUSTERED INDEX UX_enc_familia_activa
    ON sgspi.estandar_normativo_catalogo (enc_familia_norma)
    WHERE enc_esta_activo = 1;

-- [AP-07] Se eliminan crn_tipo_control, crn_capacidad_operacional y crn_dominio_seguridad (atributos multivaluados -> aac/cra)
CREATE TABLE sgspi.control_referencia_normativa (
    crn_codigo                SMALLINT        IDENTITY (1, 1) NOT NULL,
    crn_enc_codigo            SMALLINT        NOT NULL, -- FK a [sgspi].[estandar_normativo_catalogo]([enc_codigo])
    crn_rol_privacidad_pii    NVARCHAR (20)   NULL, -- 'CONTROLADOR', 'PROCESADOR', 'COMUN' (NULL cuando el estándar no define rol PII, ej. ISO/IEC 27001:2022)
    crn_identificador_control NVARCHAR (20)   NOT NULL, -- 'A.5.1'..'A.8.34', 'A.1.2.2'..'A.3.31'
    crn_nombre_control        NVARCHAR (200)  NOT NULL,
    crn_objetivo_requisito    NVARCHAR (1500) NOT NULL,
    crn_esta_activo           BIT             CONSTRAINT DF_crn_esta_activo DEFAULT 1 NOT NULL, -- [AP-17]
    CONSTRAINT PK_crn_control_referencia_normativa PRIMARY KEY CLUSTERED (crn_codigo),
    CONSTRAINT UQ_crn_estandar_identificador UNIQUE (crn_enc_codigo, crn_identificador_control),
    CONSTRAINT FK_crn_estandar_normativo FOREIGN KEY (crn_enc_codigo) REFERENCES sgspi.estandar_normativo_catalogo (enc_codigo),
    CONSTRAINT CK_crn_rol_privacidad_pii CHECK (crn_rol_privacidad_pii IS NULL
                                                OR crn_rol_privacidad_pii IN (N'CONTROLADOR', N'PROCESADOR', N'COMUN'))
);

-- 5.6 [aac], [cra] Atributos de Controles Normativos (ISO/IEC 27002:2022 define 5 tipos de atributo multivaluados por control:
--     tipo de control, propiedades de seguridad de la información, conceptos de ciberseguridad, capacidades operativas y dominios de seguridad).
--     [AP-07] Un catálogo único de atributos y una tabla N:M reemplazan las columnas de texto multivaluado y las tablas cps/ccc.
CREATE TABLE sgspi.atributo_control_catalogo (
    aac_codigo        SMALLINT      IDENTITY (1, 1) NOT NULL,
    aac_tipo_atributo NVARCHAR (30) NOT NULL, -- 'TIPO_CONTROL', 'PROPIEDAD_SEGURIDAD', 'CONCEPTO_CIBERSEGURIDAD', 'CAPACIDAD_OPERACIONAL', 'DOMINIO_SEGURIDAD'
    aac_valor         NVARCHAR (60) NOT NULL, -- Ej: 'Preventivo', 'Confidencialidad', 'Proteger', 'Gobernanza', 'Protección'
    aac_esta_activo   BIT           CONSTRAINT DF_aac_esta_activo DEFAULT 1 NOT NULL, -- [AP-17]
    CONSTRAINT PK_aac_atributo_control_catalogo PRIMARY KEY CLUSTERED (aac_codigo),
    CONSTRAINT UQ_aac_tipo_valor UNIQUE (aac_tipo_atributo, aac_valor),
    CONSTRAINT CK_aac_tipo_atributo CHECK (aac_tipo_atributo IN (N'TIPO_CONTROL', N'PROPIEDAD_SEGURIDAD', N'CONCEPTO_CIBERSEGURIDAD', N'CAPACIDAD_OPERACIONAL', N'DOMINIO_SEGURIDAD')),
    CONSTRAINT CK_aac_valor_no_vacio CHECK (LEN(TRIM(aac_valor)) > 0)
);

CREATE TABLE sgspi.control_referencia_normativa_atributo (
    cra_crn_codigo SMALLINT NOT NULL, -- FK a [sgspi].[control_referencia_normativa]([crn_codigo])
    cra_aac_codigo SMALLINT NOT NULL, -- FK a [sgspi].[atributo_control_catalogo]([aac_codigo])
    CONSTRAINT PK_cra_control_referencia_normativa_atributo PRIMARY KEY CLUSTERED (cra_crn_codigo, cra_aac_codigo),
    CONSTRAINT FK_cra_control_referencia FOREIGN KEY (cra_crn_codigo) REFERENCES sgspi.control_referencia_normativa (crn_codigo) ON DELETE CASCADE,
    CONSTRAINT FK_cra_atributo_control FOREIGN KEY (cra_aac_codigo) REFERENCES sgspi.atributo_control_catalogo (aac_codigo)
);

CREATE NONCLUSTERED INDEX IX_cra_aac_codigo
    ON sgspi.control_referencia_normativa_atributo (cra_aac_codigo);

-- 5.7 [ptc] Relación N:M Plan de Tratamiento <-> Controles de Referencia Normativa (ISO 27001 e ISO 27701)
CREATE TABLE sgspi.plan_tratamiento_control_referencia_normativa (
    ptc_plt_codigo INT      NOT NULL, -- FK a [sgspi].[plan_tratamiento]([plt_codigo])
    ptc_crn_codigo SMALLINT NOT NULL, -- FK a [sgspi].[control_referencia_normativa]([crn_codigo])
    CONSTRAINT PK_ptc_plan_tratamiento_control_referencia_normativa PRIMARY KEY CLUSTERED (ptc_plt_codigo, ptc_crn_codigo),
    CONSTRAINT FK_ptc_plan_tratamiento FOREIGN KEY (ptc_plt_codigo) REFERENCES sgspi.plan_tratamiento (plt_codigo),
    CONSTRAINT FK_ptc_control_referencia FOREIGN KEY (ptc_crn_codigo) REFERENCES sgspi.control_referencia_normativa (crn_codigo)
);

CREATE NONCLUSTERED INDEX IX_ptc_crn_codigo
    ON sgspi.plan_tratamiento_control_referencia_normativa (ptc_crn_codigo);

-- 5.8 [eac] Declaración de Aplicabilidad (SoA) y Evaluación de Cumplimiento por Vigencia (Con System-Versioned Temporal Table)
CREATE TABLE sgspi.evaluacion_aplicabilidad_control (
    eac_codigo                      INT                                         IDENTITY (1, 1) NOT NULL,
    eac_pev_codigo                  SMALLINT                                    NOT NULL, -- FK a [sgspi].[periodo_vigencia]([pev_codigo])
    eac_crn_codigo                  SMALLINT                                    NOT NULL, -- FK a [sgspi].[control_referencia_normativa]([crn_codigo])
    eac_es_aplicable                BIT                                         CONSTRAINT DF_eac_es_aplicable DEFAULT 1 NOT NULL, -- [AP-17]
    eac_justificacion_aplicabilidad NVARCHAR (1000)                             NULL,
    eac_documento_soporte_normativo NVARCHAR (500)                              NULL,
    eac_car_codigo                  INT                                         NULL, -- FK a [dbo].[cargo]([car_codigo])
    eac_frecuencia_revision         NVARCHAR (100)                              NULL, -- Ej: 'Anual y cuando se presenten cambios' (NULL cuando eac_es_aplicable = 0)
    eac_evidencia_objetiva_esperada NVARCHAR (500)                              NULL,
    eac_estado_implementacion       NVARCHAR (20)                               NULL, -- 'CUMPLE', 'CUMPLE_PARCIAL', 'NO_CUMPLE' (NULL cuando eac_es_aplicable = 0)
    eac_observaciones_auditoria     NVARCHAR (1000)                             NULL,
    eac_fecha_creacion              DATETIMEOFFSET (0)                          CONSTRAINT DF_eac_fecha_creacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17] [AP-11: se elimina eac_fecha_actualizacion]
    eac_sys_inicio_utc              DATETIME2 (7) GENERATED ALWAYS AS ROW START HIDDEN NOT NULL, -- [AP-17] sin DEFAULT
    eac_sys_fin_utc                 DATETIME2 (7) GENERATED ALWAYS AS ROW END   HIDDEN NOT NULL, -- [AP-17] sin DEFAULT
    PERIOD FOR SYSTEM_TIME (eac_sys_inicio_utc, eac_sys_fin_utc),
    CONSTRAINT PK_eac_evaluacion_aplicabilidad_control PRIMARY KEY CLUSTERED (eac_codigo),
    CONSTRAINT UQ_eac_vigencia_control UNIQUE (eac_pev_codigo, eac_crn_codigo),
    CONSTRAINT FK_eac_periodo_vigencia FOREIGN KEY (eac_pev_codigo) REFERENCES sgspi.periodo_vigencia (pev_codigo),
    CONSTRAINT FK_eac_control_referencia FOREIGN KEY (eac_crn_codigo) REFERENCES sgspi.control_referencia_normativa (crn_codigo),
    CONSTRAINT FK_eac_dbo_cargo FOREIGN KEY (eac_car_codigo) REFERENCES dbo.cargo (car_codigo),
    CONSTRAINT CK_eac_estado_implementacion CHECK (eac_estado_implementacion IS NULL
                                                   OR eac_estado_implementacion IN (N'CUMPLE', N'CUMPLE_PARCIAL', N'NO_CUMPLE')),
    -- Coherencia entre aplicabilidad (BIT) y estado de implementación (sin valor centinela 'NO_APLICA')
    CONSTRAINT CK_eac_coherencia_aplicabilidad CHECK ((eac_es_aplicable = 1
                                                       AND eac_estado_implementacion IS NOT NULL
                                                       AND LEN(TRIM(ISNULL(eac_frecuencia_revision, N''))) > 0)
                                                      OR (eac_es_aplicable = 0
                                                          AND eac_estado_implementacion IS NULL
                                                          AND eac_frecuencia_revision IS NULL
                                                          AND LEN(TRIM(ISNULL(eac_justificacion_aplicabilidad, N''))) > 0)),
    -- RN-SOA-01: Un control NO puede marcarse como CUMPLE si el documento soporte o la evidencia esperada están vacíos o dicen 'PENDIENTE'
    CONSTRAINT CK_eac_cumple_requiere_evidencia CHECK (eac_estado_implementacion IS NULL
                                                       OR eac_estado_implementacion <> N'CUMPLE'
                                                       OR (LEN(TRIM(ISNULL(eac_documento_soporte_normativo, N''))) > 0
                                                           AND UPPER(TRIM(ISNULL(eac_documento_soporte_normativo, N''))) <> N'PENDIENTE'
                                                           AND LEN(TRIM(ISNULL(eac_evidencia_objetiva_esperada, N''))) > 0
                                                           AND UPPER(TRIM(ISNULL(eac_evidencia_objetiva_esperada, N''))) <> N'PENDIENTE'))
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = sgspi.evaluacion_aplicabilidad_control_historial));

CREATE NONCLUSTERED INDEX IX_eac_crn_codigo
    ON sgspi.evaluacion_aplicabilidad_control (eac_crn_codigo);
CREATE NONCLUSTERED INDEX IX_eac_car_codigo
    ON sgspi.evaluacion_aplicabilidad_control (eac_car_codigo);

-- 5.9 [bas] Bitácora de Auditoría Inmutable Desacoplada con Cadena de Hash SHA-256 (Control ISO 27001 A.8.15)
-- [AP-01] El hash ya no es una columna calculada sobre la propia fila (se recalcularía si la fila se alterara y no
-- detectaría borrados). Ahora es una cadena: cada evento almacena el hash del evento anterior (bas_hash_evento_anterior,
-- NULL solo en el evento génesis) y su propio hash SHA-256 (bas_hash_evento_sha256), calculado sobre el contenido del
-- evento más el hash anterior por el trigger INSTEAD OF INSERT de la sección 5.10. El índice único UX_bas_hash_evento_anterior
-- permite un solo génesis (NULL) y prohíbe bifurcaciones de la cadena: dos eventos no pueden tener el mismo predecesor.
CREATE TABLE sgspi.bitacora_auditoria_sistema (
    bas_codigo                   BIGINT         IDENTITY (1, 1) NOT NULL,
    bas_fecha_evento_utc         DATETIME2 (3)  CONSTRAINT DF_bas_fecha_evento_utc DEFAULT SYSUTCDATETIME() NOT NULL, -- [AP-17] UTC por diseño
    bas_per_codigo               INT            NULL, -- FK a [dbo].[persona]([per_codigo])
    bas_gru_codigo               INT            NULL, -- FK a [dbo].[grupo]([gru_codigo])
    bas_usg_codigo               INT            NULL, -- FK a [dbo].[usuario_grupo]([usg_codigo])
    bas_usuario_bd               NVARCHAR (128) CONSTRAINT DF_bas_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL, -- [AP-17]
    bas_direccion_ip             VARCHAR (45)   NULL,
    bas_entidad_afectada         NVARCHAR (80)  NOT NULL,
    bas_registro_afectado_codigo INT            NOT NULL,
    bas_accion_ejecutada         NVARCHAR (30)  NOT NULL,
    bas_estado_anterior          NVARCHAR (30)  NULL,
    bas_estado_nuevo             NVARCHAR (30)  NULL,
    bas_valores_anteriores_json  NVARCHAR (MAX) NULL,
    bas_valores_nuevos_json      NVARCHAR (MAX) NULL,
    bas_motivo_observacion       NVARCHAR (500) NULL,
    -- [AP-01] Cadena de hash: columnas almacenadas (no calculadas) que completa el trigger INSTEAD OF INSERT de la sección 5.10
    bas_hash_evento_anterior     CHAR (64)      NULL,     -- NULL solo en el evento génesis
    bas_hash_evento_sha256       CHAR (64)      NOT NULL, -- SHA-256 hex del evento + hash anterior
    CONSTRAINT PK_bas_bitacora_auditoria_sistema PRIMARY KEY CLUSTERED (bas_codigo),
    CONSTRAINT UQ_bas_hash_evento_sha256 UNIQUE (bas_hash_evento_sha256), -- [AP-01]
    CONSTRAINT FK_bas_dbo_persona FOREIGN KEY (bas_per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT FK_bas_dbo_grupo FOREIGN KEY (bas_gru_codigo) REFERENCES dbo.grupo (gru_codigo),
    CONSTRAINT FK_bas_dbo_usuario_grupo FOREIGN KEY (bas_usg_codigo) REFERENCES dbo.usuario_grupo (usg_codigo),
    CONSTRAINT CK_bas_accion_ejecutada CHECK (bas_accion_ejecutada IN (N'CREAR', N'ACTUALIZAR', N'TRANSICION_ESTADO', N'APROBAR', N'OBSERVAR')),
    CONSTRAINT CK_bas_json_ant CHECK (bas_valores_anteriores_json IS NULL OR ISJSON(bas_valores_anteriores_json) = 1),
    CONSTRAINT CK_bas_json_nue CHECK (bas_valores_nuevos_json IS NULL OR ISJSON(bas_valores_nuevos_json) = 1),
    -- [AP-01] Formato hexadecimal de 64 caracteres (SHA-256) en ambos hashes; el anterior puede ser NULL (génesis)
    CONSTRAINT CK_bas_hash_formato CHECK (LEN(bas_hash_evento_sha256) = 64
                                          AND bas_hash_evento_sha256 NOT LIKE '%[^0-9A-F]%' COLLATE Latin1_General_100_BIN2
                                          AND (bas_hash_evento_anterior IS NULL
                                               OR (LEN(bas_hash_evento_anterior) = 64
                                                   AND bas_hash_evento_anterior NOT LIKE '%[^0-9A-F]%' COLLATE Latin1_General_100_BIN2)))
);

-- [AP-01] Índice ÚNICO no filtrado: SQL Server trata NULL como igual en índices únicos, por lo que admite un solo
-- génesis y prohíbe bifurcaciones de la cadena (dos eventos con el mismo hash anterior)
CREATE UNIQUE NONCLUSTERED INDEX UX_bas_hash_evento_anterior
    ON sgspi.bitacora_auditoria_sistema (bas_hash_evento_anterior);

-- Un único índice compuesto cubre las búsquedas por entidad y registro sin crear N índices filtrados
CREATE NONCLUSTERED INDEX IX_bas_entidad_registro
    ON sgspi.bitacora_auditoria_sistema (bas_entidad_afectada, bas_registro_afectado_codigo, bas_fecha_evento_utc DESC);
CREATE NONCLUSTERED INDEX IX_bas_per_codigo
    ON sgspi.bitacora_auditoria_sistema (bas_per_codigo)
    WHERE bas_per_codigo IS NOT NULL;
CREATE NONCLUSTERED INDEX IX_bas_gru_codigo
    ON sgspi.bitacora_auditoria_sistema (bas_gru_codigo)
    WHERE bas_gru_codigo IS NOT NULL;
CREATE NONCLUSTERED INDEX IX_bas_usg_codigo
    ON sgspi.bitacora_auditoria_sistema (bas_usg_codigo)
    WHERE bas_usg_codigo IS NOT NULL;


GO
/*==================================================================================================
  5.10 PROCEDIMIENTO DE CONTEXTO SEGURO, CADENA DE HASH DE BITÁCORA, TRIGGERS DE INMUTABILIDAD,
       INTEGRIDAD DE MÁQUINA DE ESTADOS Y ALIMENTACIÓN AUTOMÁTICA DE AUDITORÍA (ISO 27001 A.8.15)
==================================================================================================*/
-- 5.10.0 Objetos de soporte: contexto de auditoría, carga inicial y hash encadenado de la bitácora
-- 5.10.0.a Función en línea que centraliza la lectura de SESSION_CONTEXT
-- [AP-21] Única fuente de lectura del contexto: todos los triggers la consumen con CROSS APPLY en vez de repetir SESSION_CONTEXT
CREATE OR ALTER FUNCTION sgspi.ufn_contexto_auditoria ()
RETURNS TABLE
AS
RETURN
SELECT CAST(TRY_CAST(SESSION_CONTEXT(N'sgspi_per_codigo') AS INT) AS INT) AS per_codigo,
       CAST(TRY_CAST(SESSION_CONTEXT(N'sgspi_gru_codigo') AS INT) AS INT) AS gru_codigo,
       CAST(TRY_CAST(SESSION_CONTEXT(N'sgspi_usg_codigo') AS INT) AS INT) AS usg_codigo,
       CAST(COALESCE(CONVERT(VARCHAR(45), SESSION_CONTEXT(N'sgspi_direccion_ip')), CONVERT(VARCHAR(45), CONNECTIONPROPERTY('client_net_address'))) AS VARCHAR(45)) AS direccion_ip,
       CAST(CONVERT(NVARCHAR(500), SESSION_CONTEXT(N'sgspi_motivo_observacion')) AS NVARCHAR(500)) AS motivo_observacion,
       -- [AP-04] Modo de carga inicial: solo se activa con [sgspi].[usp_habilitar_carga_inicial] (por defecto 0)
       CAST(CASE WHEN TRY_CAST(SESSION_CONTEXT(N'sgspi_modo_carga_inicial') AS INT) = 1 THEN 1 ELSE 0 END AS BIT) AS modo_carga_inicial;


GO
-- 5.10.0.b Procedimiento de Contexto Seguro (Mitiga fuga de conexiones en el pool HikariCP / ADO.NET / PDO)
-- [AP-03] Valida la identidad contra [dbo].[persona] y la fija de solo lectura para la sesión
CREATE OR ALTER PROCEDURE sgspi.usp_establecer_contexto_auditoria
    @per_codigo         INT,
    @gru_codigo         INT            = NULL,
    @usg_codigo         INT            = NULL,
    @direccion_ip       VARCHAR (45)   = NULL,
    @motivo_observacion NVARCHAR (500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- [AP-03] La identidad es obligatoria y debe existir: se evita adjudicar acciones a personas inexistentes
    IF @per_codigo IS NULL
       OR NOT EXISTS (SELECT 1 FROM dbo.persona AS p WHERE p.per_codigo = @per_codigo)
        THROW 50013, N'Contexto de auditoría inválido: [per_codigo] es obligatorio y debe existir en [dbo].[persona].', 1;

    -- [AP-03] @read_only = 1: la identidad no puede reasignarse a mitad de la sesión. El pool de conexiones
    -- (ADO.NET / ODBC / PDO) ejecuta sp_reset_connection al devolver la conexión, lo que limpia SESSION_CONTEXT;
    -- así la identidad queda fija mientras la aplicación retiene la conexión y se renueva al reutilizarla.
    EXEC sys.sp_set_session_context @key = N'sgspi_per_codigo',         @value = @per_codigo,         @read_only = 1;
    EXEC sys.sp_set_session_context @key = N'sgspi_gru_codigo',         @value = @gru_codigo,         @read_only = 0;
    EXEC sys.sp_set_session_context @key = N'sgspi_usg_codigo',         @value = @usg_codigo,         @read_only = 0;
    EXEC sys.sp_set_session_context @key = N'sgspi_direccion_ip',       @value = @direccion_ip,       @read_only = 0;
    EXEC sys.sp_set_session_context @key = N'sgspi_motivo_observacion', @value = @motivo_observacion, @read_only = 0;
END;


GO
-- 5.10.0.c Habilitación de carga inicial [AP-04]
-- Solo para migración de inventarios existentes (permite INSERT en estados distintos del inicial del flujo).
-- Su EXECUTE se concede ÚNICAMENTE al rol [sgspi_rol_administrador] (ver 5.10.13); nunca al rol de aplicación.
CREATE OR ALTER PROCEDURE sgspi.usp_habilitar_carga_inicial
AS
BEGIN
    SET NOCOUNT ON;
    -- @read_only = 1: una vez habilitado no puede desactivarse ni reescribirse en la misma sesión
    EXEC sys.sp_set_session_context @key = N'sgspi_modo_carga_inicial', @value = 1, @read_only = 1;
END;


GO
-- 5.10.0.d Función única de hash encadenado de la bitácora [AP-01]
-- Es la ÚNICA definición del hash: la usan el trigger INSTEAD OF INSERT y el verificador de cadena.
CREATE OR ALTER FUNCTION sgspi.ufn_hash_evento_bitacora (
    @hash_anterior CHAR (64),
    @fecha         DATETIME2 (3),
    @per           INT,
    @gru           INT,
    @usg           INT,
    @usuario_bd    NVARCHAR (128),
    @ip            VARCHAR (45),
    @entidad       NVARCHAR (80),
    @registro      INT,
    @accion        NVARCHAR (30),
    @estado_ant    NVARCHAR (30),
    @estado_nue    NVARCHAR (30),
    @json_ant      NVARCHAR (MAX),
    @json_nue      NVARCHAR (MAX),
    @motivo        NVARCHAR (500)
)
RETURNS CHAR (64)
WITH SCHEMABINDING
AS
BEGIN
    -- Hash SHA-256 en dos etapas: hashea el NVARCHAR(MAX) completo de ambos JSON antes de concatenar
    RETURN CONVERT(
               CHAR (64),
               HASHBYTES(
                   'SHA2_256',
                   CONCAT_WS(
                       N'|',
                       ISNULL(@hash_anterior, REPLICATE(N'0', 64)),
                       CONVERT(NVARCHAR (30), @fecha, 126),
                       ISNULL(CONVERT(NVARCHAR (20), @per), N'SYS'),
                       ISNULL(CONVERT(NVARCHAR (20), @gru), N''),
                       ISNULL(CONVERT(NVARCHAR (20), @usg), N''),
                       ISNULL(@usuario_bd, N''),
                       ISNULL(@ip, N''),
                       ISNULL(@entidad, N''),
                       ISNULL(CONVERT(NVARCHAR (20), @registro), N''),
                       ISNULL(@accion, N''),
                       ISNULL(@estado_ant, N''),
                       ISNULL(@estado_nue, N''),
                       CONVERT(CHAR (64), HASHBYTES('SHA2_256', ISNULL(@json_ant, N'')), 2),
                       CONVERT(CHAR (64), HASHBYTES('SHA2_256', ISNULL(@json_nue, N'')), 2),
                       ISNULL(@motivo, N'')
                   )
               ),
               2
           );
END;


GO
-- 5.10.1 Trigger INSTEAD OF INSERT que calcula la cadena de hash de [sgspi].[bitacora_auditoria_sistema]
-- [AP-01] El hash deja de ser una columna calculada autorreferente: se almacena y se encadena con el del evento anterior,
-- de modo que alterar o borrar un evento (incluso por un sysadmin) rompe la cadena y lo detecta [sgspi].[usp_verificar_cadena_bitacora].
CREATE OR ALTER TRIGGER sgspi.TR_bas_cadena_hash
ON sgspi.bitacora_auditoria_sistema
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM inserted)
        RETURN;

    -- Serializa la escritura de la cadena. Con LockOwner = 'Transaction' el candado se libera al terminar la transacción;
    -- si el trigger corre sin transacción explícita, igual está dentro de la transacción implícita de la sentencia.
    DECLARE @rc INT;
    EXEC @rc = sys.sp_getapplock @Resource = N'sgspi_bitacora_cadena', @LockMode = 'Exclusive', @LockOwner = 'Transaction', @LockTimeout = 30000;
    IF @rc < 0
        THROW 50017, N'No fue posible obtener el candado de la cadena de hash de la bitácora de auditoría.', 1;

    -- Último hash de la cadena (NULL si la bitácora está vacía: este lote inicia con el evento génesis)
    DECLARE @hash_previo CHAR (64);
    SELECT TOP (1) @hash_previo = b.bas_hash_evento_sha256
    FROM   sgspi.bitacora_auditoria_sistema AS b WITH (UPDLOCK, HOLDLOCK)
    ORDER BY b.bas_codigo DESC;

    -- Lote en orden determinista; se ignora cualquier valor de hash que venga en [inserted]
    DECLARE @lote TABLE (
        rn                           INT            NOT NULL PRIMARY KEY,
        bas_fecha_evento_utc         DATETIME2 (3)  NOT NULL,
        bas_per_codigo               INT            NULL,
        bas_gru_codigo               INT            NULL,
        bas_usg_codigo               INT            NULL,
        bas_usuario_bd               NVARCHAR (128) NOT NULL,
        bas_direccion_ip             VARCHAR (45)   NULL,
        bas_entidad_afectada         NVARCHAR (80)  NOT NULL,
        bas_registro_afectado_codigo INT            NOT NULL,
        bas_accion_ejecutada         NVARCHAR (30)  NOT NULL,
        bas_estado_anterior          NVARCHAR (30)  NULL,
        bas_estado_nuevo             NVARCHAR (30)  NULL,
        bas_valores_anteriores_json  NVARCHAR (MAX) NULL,
        bas_valores_nuevos_json      NVARCHAR (MAX) NULL,
        bas_motivo_observacion       NVARCHAR (500) NULL
    );

    INSERT INTO @lote
    SELECT ROW_NUMBER() OVER (ORDER BY COALESCE(i.bas_fecha_evento_utc, SYSUTCDATETIME()), i.bas_entidad_afectada, i.bas_registro_afectado_codigo, i.bas_accion_ejecutada),
           COALESCE(i.bas_fecha_evento_utc, SYSUTCDATETIME()),
           i.bas_per_codigo,
           i.bas_gru_codigo,
           i.bas_usg_codigo,
           COALESCE(i.bas_usuario_bd, ORIGINAL_LOGIN()),
           i.bas_direccion_ip,
           i.bas_entidad_afectada,
           i.bas_registro_afectado_codigo,
           i.bas_accion_ejecutada,
           i.bas_estado_anterior,
           i.bas_estado_nuevo,
           i.bas_valores_anteriores_json,
           i.bas_valores_nuevos_json,
           i.bas_motivo_observacion
    FROM   inserted AS i;

    DECLARE @n INT = 1, @max INT = (SELECT COUNT(*) FROM @lote), @hash_nuevo CHAR (64);

    WHILE @n <= @max
    BEGIN
        SELECT @hash_nuevo = sgspi.ufn_hash_evento_bitacora(
                   @hash_previo, l.bas_fecha_evento_utc, l.bas_per_codigo, l.bas_gru_codigo, l.bas_usg_codigo,
                   l.bas_usuario_bd, l.bas_direccion_ip, l.bas_entidad_afectada, l.bas_registro_afectado_codigo,
                   l.bas_accion_ejecutada, l.bas_estado_anterior, l.bas_estado_nuevo,
                   l.bas_valores_anteriores_json, l.bas_valores_nuevos_json, l.bas_motivo_observacion)
        FROM   @lote AS l
        WHERE  l.rn = @n;

        INSERT INTO sgspi.bitacora_auditoria_sistema (
            bas_fecha_evento_utc, bas_per_codigo, bas_gru_codigo, bas_usg_codigo, bas_usuario_bd, bas_direccion_ip,
            bas_entidad_afectada, bas_registro_afectado_codigo, bas_accion_ejecutada, bas_estado_anterior, bas_estado_nuevo,
            bas_valores_anteriores_json, bas_valores_nuevos_json, bas_motivo_observacion,
            bas_hash_evento_anterior, bas_hash_evento_sha256
        )
        SELECT l.bas_fecha_evento_utc, l.bas_per_codigo, l.bas_gru_codigo, l.bas_usg_codigo, l.bas_usuario_bd, l.bas_direccion_ip,
               l.bas_entidad_afectada, l.bas_registro_afectado_codigo, l.bas_accion_ejecutada, l.bas_estado_anterior, l.bas_estado_nuevo,
               l.bas_valores_anteriores_json, l.bas_valores_nuevos_json, l.bas_motivo_observacion,
               @hash_previo, @hash_nuevo
        FROM   @lote AS l
        WHERE  l.rn = @n;

        SET @hash_previo = @hash_nuevo;
        SET @n += 1;
    END;
END;


GO
-- 5.10.2 Trigger INSTEAD OF UPDATE, DELETE que garantiza la inmutabilidad física (Append-Only) de [sgspi].[bitacora_auditoria_sistema]
CREATE OR ALTER TRIGGER sgspi.TR_bas_inmutabilidad_bitacora
ON sgspi.bitacora_auditoria_sistema
INSTEAD OF UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    THROW 50001, N'Operación denegada (ISO/IEC 27001 A.8.15): La bitácora de auditoría es estrictamente inmutable (append-only).', 1;
END;


GO
-- 5.10.3 Procedimiento de verificación de la cadena de hash de la bitácora [AP-01]
-- Devuelve los eventos con encadenamiento roto (evento previo alterado/borrado) o con hash almacenado distinto del recalculado.
-- Nota: el borrado de los últimos eventos (truncamiento de la cola) no es detectable sin un ancla externa del último hash.
CREATE OR ALTER PROCEDURE sgspi.usp_verificar_cadena_bitacora
    @desde_codigo BIGINT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    WITH cte_cadena
    AS (SELECT b.*,
               LAG(b.bas_hash_evento_sha256) OVER (ORDER BY b.bas_codigo) AS hash_previo_real
        FROM   sgspi.bitacora_auditoria_sistema AS b),
         cte_verificada
    AS (SELECT c.bas_codigo,
               CASE WHEN ISNULL(c.bas_hash_evento_anterior, N'') <> ISNULL(c.hash_previo_real, N'') THEN 1 ELSE 0 END AS falla_encadenamiento,
               CASE WHEN c.bas_hash_evento_sha256 <> sgspi.ufn_hash_evento_bitacora(
                             c.bas_hash_evento_anterior, c.bas_fecha_evento_utc, c.bas_per_codigo, c.bas_gru_codigo, c.bas_usg_codigo,
                             c.bas_usuario_bd, c.bas_direccion_ip, c.bas_entidad_afectada, c.bas_registro_afectado_codigo,
                             c.bas_accion_ejecutada, c.bas_estado_anterior, c.bas_estado_nuevo,
                             c.bas_valores_anteriores_json, c.bas_valores_nuevos_json, c.bas_motivo_observacion)
                    THEN 1 ELSE 0 END AS falla_hash
        FROM   cte_cadena AS c
        WHERE  c.bas_codigo >= ISNULL(@desde_codigo, 0))
    SELECT   v.bas_codigo,
             CONCAT_WS(N'; ',
                       CASE WHEN v.falla_encadenamiento = 1 THEN N'ENCADENAMIENTO_ROTO: el hash anterior no coincide con el del evento previo' END,
                       CASE WHEN v.falla_hash = 1 THEN N'HASH_ALTERADO: el hash almacenado no coincide con el recalculado' END) AS motivo_falla
    FROM     cte_verificada AS v
    WHERE    v.falla_encadenamiento = 1
             OR v.falla_hash = 1
    ORDER BY v.bas_codigo;
END;


GO
-- 5.10.4 Trigger sobre [sgspi].[analisis_contexto_factor] ([acf]): Actualiza [acf_fecha_actualizacion], valida el flujo de estados (dirigido por datos) y alimenta [bas]
CREATE OR ALTER TRIGGER sgspi.TR_acf_auditoria_y_actualizacion
ON sgspi.analisis_contexto_factor
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF TRIGGER_NESTLEVEL(OBJECT_ID(N'sgspi.TR_acf_auditoria_y_actualizacion', N'TR')) > 1
        RETURN;

    IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
        THROW 50010, N'Operación denegada: No se permite eliminar físicamente registros de [sgspi].[analisis_contexto_factor].', 1;

    IF NOT EXISTS (SELECT 1 FROM inserted)
        RETURN;

    -- [AP-03] Contexto obligatorio para TODA operación (también INSERT); sin fallback al creador/revisor/evaluador
    DECLARE @per_sesion INT, @modo_carga BIT;
    SELECT @per_sesion = ctx.per_codigo, @modo_carga = ctx.modo_carga_inicial
    FROM   sgspi.ufn_contexto_auditoria() AS ctx;

    IF @per_sesion IS NULL
        THROW 50012, N'Contexto de auditoría ausente: Ejecute [sgspi].[usp_establecer_contexto_auditoria] antes de modificar registros.', 1;

    -- [AP-04] En INSERT el estado debe ser el inicial del dominio, salvo carga inicial habilitada por el administrador
    IF @modo_carga = 0
       AND EXISTS (
            SELECT 1
            FROM   inserted AS i
            WHERE  NOT EXISTS (SELECT 1 FROM deleted AS d WHERE d.acf_codigo = i.acf_codigo)
                   AND NOT EXISTS (
                       SELECT 1
                       FROM   sgspi.estado_flujo_catalogo AS efc
                       WHERE  efc.efc_dominio = N'ACF'
                              AND efc.efc_identificador = i.acf_estado_registro
                              AND efc.efc_es_inicial = 1
                   )
       )
        THROW 50014, N'Estado inicial inválido: un registro nuevo de [sgspi].[analisis_contexto_factor] solo puede crearse en el estado inicial del flujo.', 1;

    IF EXISTS (SELECT 1 FROM deleted)
    BEGIN
        -- [AP-05] Máquina de estados dirigida por datos: sin listas de estados codificadas
        IF EXISTS (
            SELECT 1
            FROM   inserted AS i
                   INNER JOIN deleted AS d ON d.acf_codigo = i.acf_codigo
            WHERE  (i.acf_estado_registro = d.acf_estado_registro
                    AND EXISTS (
                        SELECT 1
                        FROM   sgspi.estado_flujo_catalogo AS efc
                        WHERE  efc.efc_dominio = N'ACF'
                               AND efc.efc_identificador = d.acf_estado_registro
                               AND efc.efc_permite_edicion = 0
                    ))
                   OR (i.acf_estado_registro <> d.acf_estado_registro
                       AND NOT EXISTS (
                           SELECT 1
                           FROM   sgspi.transicion_estado_flujo AS tef
                           WHERE  tef.tef_efc_dominio = N'ACF'
                                  AND tef.tef_efc_identificador_origen = d.acf_estado_registro
                                  AND tef.tef_efc_identificador_destino = i.acf_estado_registro
                       ))
        )
        BEGIN
            THROW 50011, N'Transición inválida o intento de modificar un registro sin estado editable (VIGENTE/HISTORICO) sin reabrir revisión en [sgspi].[analisis_contexto_factor].', 1;
        END;

        IF NOT UPDATE(acf_fecha_actualizacion)
        BEGIN
            UPDATE t
            SET    t.acf_fecha_actualizacion = SYSDATETIMEOFFSET() -- [AP-12]
            FROM   sgspi.analisis_contexto_factor AS t
                   INNER JOIN inserted AS i ON i.acf_codigo = t.acf_codigo;
        END;
    END;

    -- Se usa SELECT d.* / i.* de forma deliberada: el payload JSON captura la fila completa (antes/después) sin mantener listas de columnas
    INSERT INTO sgspi.bitacora_auditoria_sistema (
        bas_per_codigo,
        bas_gru_codigo,
        bas_usg_codigo,
        bas_direccion_ip,
        bas_entidad_afectada,
        bas_registro_afectado_codigo,
        bas_accion_ejecutada,
        bas_estado_anterior,
        bas_estado_nuevo,
        bas_valores_anteriores_json,
        bas_valores_nuevos_json,
        bas_motivo_observacion
    )
    SELECT ctx.per_codigo, -- [AP-03] sin COALESCE con creador/revisor/evaluador
           ctx.gru_codigo,
           ctx.usg_codigo,
           ctx.direccion_ip,
           N'sgspi.analisis_contexto_factor',
           i.acf_codigo,
           CASE
               WHEN d.acf_codigo IS NULL THEN N'CREAR'
               WHEN d.acf_estado_registro <> i.acf_estado_registro THEN tef.tef_accion_bitacora -- [AP-05] acción tomada de la transición
               ELSE N'ACTUALIZAR'
           END,
           d.acf_estado_registro,
           i.acf_estado_registro,
           j_ant.payload,
           j_nue.payload,
           ctx.motivo_observacion
    FROM   inserted AS i
           CROSS APPLY sgspi.ufn_contexto_auditoria() AS ctx -- [AP-21]
           LEFT OUTER JOIN deleted AS d ON d.acf_codigo = i.acf_codigo
           LEFT OUTER JOIN sgspi.transicion_estado_flujo AS tef
               ON tef.tef_efc_dominio = N'ACF'
                  AND tef.tef_efc_identificador_origen = d.acf_estado_registro
                  AND tef.tef_efc_identificador_destino = i.acf_estado_registro
           OUTER APPLY (
               SELECT d.*
               FROM   (VALUES (1)) AS v(n)
               WHERE  d.acf_codigo IS NOT NULL
               FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
           ) AS j_ant(payload)
           CROSS APPLY (
               SELECT i.*
               FROM   (VALUES (1)) AS v(n)
               FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
           ) AS j_nue(payload);
END;



GO
-- 5.10.5 Trigger sobre [sgspi].[requisito_parte_interesada] ([rpi]): Actualiza [rpi_fecha_actualizacion], valida el flujo de estados (dirigido por datos) y alimenta [bas]
CREATE OR ALTER TRIGGER sgspi.TR_rpi_auditoria_y_actualizacion
ON sgspi.requisito_parte_interesada
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF TRIGGER_NESTLEVEL(OBJECT_ID(N'sgspi.TR_rpi_auditoria_y_actualizacion', N'TR')) > 1
        RETURN;

    IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
        THROW 50010, N'Operación denegada: No se permite eliminar físicamente registros de [sgspi].[requisito_parte_interesada].', 1;

    IF NOT EXISTS (SELECT 1 FROM inserted)
        RETURN;

    -- [AP-03] Contexto obligatorio para TODA operación (también INSERT); sin fallback al creador/revisor/evaluador
    DECLARE @per_sesion INT, @modo_carga BIT;
    SELECT @per_sesion = ctx.per_codigo, @modo_carga = ctx.modo_carga_inicial
    FROM   sgspi.ufn_contexto_auditoria() AS ctx;

    IF @per_sesion IS NULL
        THROW 50012, N'Contexto de auditoría ausente: Ejecute [sgspi].[usp_establecer_contexto_auditoria] antes de modificar registros.', 1;

    -- [AP-04] En INSERT el estado debe ser el inicial del dominio, salvo carga inicial habilitada por el administrador
    IF @modo_carga = 0
       AND EXISTS (
            SELECT 1
            FROM   inserted AS i
            WHERE  NOT EXISTS (SELECT 1 FROM deleted AS d WHERE d.rpi_codigo = i.rpi_codigo)
                   AND NOT EXISTS (
                       SELECT 1
                       FROM   sgspi.estado_flujo_catalogo AS efc
                       WHERE  efc.efc_dominio = N'RPI'
                              AND efc.efc_identificador = i.rpi_estado_registro
                              AND efc.efc_es_inicial = 1
                   )
       )
        THROW 50014, N'Estado inicial inválido: un registro nuevo de [sgspi].[requisito_parte_interesada] solo puede crearse en el estado inicial del flujo.', 1;

    IF EXISTS (SELECT 1 FROM deleted)
    BEGIN
        -- [AP-05] Máquina de estados dirigida por datos: sin listas de estados codificadas
        IF EXISTS (
            SELECT 1
            FROM   inserted AS i
                   INNER JOIN deleted AS d ON d.rpi_codigo = i.rpi_codigo
            WHERE  (i.rpi_estado_registro = d.rpi_estado_registro
                    AND EXISTS (
                        SELECT 1
                        FROM   sgspi.estado_flujo_catalogo AS efc
                        WHERE  efc.efc_dominio = N'RPI'
                               AND efc.efc_identificador = d.rpi_estado_registro
                               AND efc.efc_permite_edicion = 0
                    ))
                   OR (i.rpi_estado_registro <> d.rpi_estado_registro
                       AND NOT EXISTS (
                           SELECT 1
                           FROM   sgspi.transicion_estado_flujo AS tef
                           WHERE  tef.tef_efc_dominio = N'RPI'
                                  AND tef.tef_efc_identificador_origen = d.rpi_estado_registro
                                  AND tef.tef_efc_identificador_destino = i.rpi_estado_registro
                       ))
        )
        BEGIN
            THROW 50011, N'Transición inválida o intento de modificar un registro sin estado editable (VIGENTE/HISTORICO) sin reabrir revisión en [sgspi].[requisito_parte_interesada].', 1;
        END;

        IF NOT UPDATE(rpi_fecha_actualizacion)
        BEGIN
            UPDATE t
            SET    t.rpi_fecha_actualizacion = SYSDATETIMEOFFSET() -- [AP-12]
            FROM   sgspi.requisito_parte_interesada AS t
                   INNER JOIN inserted AS i ON i.rpi_codigo = t.rpi_codigo;
        END;
    END;

    -- Se usa SELECT d.* / i.* de forma deliberada: el payload JSON captura la fila completa (antes/después) sin mantener listas de columnas
    INSERT INTO sgspi.bitacora_auditoria_sistema (
        bas_per_codigo,
        bas_gru_codigo,
        bas_usg_codigo,
        bas_direccion_ip,
        bas_entidad_afectada,
        bas_registro_afectado_codigo,
        bas_accion_ejecutada,
        bas_estado_anterior,
        bas_estado_nuevo,
        bas_valores_anteriores_json,
        bas_valores_nuevos_json,
        bas_motivo_observacion
    )
    SELECT ctx.per_codigo, -- [AP-03] sin COALESCE con creador/revisor/evaluador
           ctx.gru_codigo,
           ctx.usg_codigo,
           ctx.direccion_ip,
           N'sgspi.requisito_parte_interesada',
           i.rpi_codigo,
           CASE
               WHEN d.rpi_codigo IS NULL THEN N'CREAR'
               WHEN d.rpi_estado_registro <> i.rpi_estado_registro THEN tef.tef_accion_bitacora -- [AP-05] acción tomada de la transición
               ELSE N'ACTUALIZAR'
           END,
           d.rpi_estado_registro,
           i.rpi_estado_registro,
           j_ant.payload,
           j_nue.payload,
           ctx.motivo_observacion
    FROM   inserted AS i
           CROSS APPLY sgspi.ufn_contexto_auditoria() AS ctx -- [AP-21]
           LEFT OUTER JOIN deleted AS d ON d.rpi_codigo = i.rpi_codigo
           LEFT OUTER JOIN sgspi.transicion_estado_flujo AS tef
               ON tef.tef_efc_dominio = N'RPI'
                  AND tef.tef_efc_identificador_origen = d.rpi_estado_registro
                  AND tef.tef_efc_identificador_destino = i.rpi_estado_registro
           OUTER APPLY (
               SELECT d.*
               FROM   (VALUES (1)) AS v(n)
               WHERE  d.rpi_codigo IS NOT NULL
               FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
           ) AS j_ant(payload)
           CROSS APPLY (
               SELECT i.*
               FROM   (VALUES (1)) AS v(n)
               FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
           ) AS j_nue(payload);
END;



GO
-- 5.10.6 Trigger sobre [sgspi].[activo_informacion] ([aci]): Actualiza [aci_fecha_actualizacion], valida el flujo de estados (dirigido por datos) y alimenta [bas]
CREATE OR ALTER TRIGGER sgspi.TR_aci_auditoria_y_actualizacion
ON sgspi.activo_informacion
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF TRIGGER_NESTLEVEL(OBJECT_ID(N'sgspi.TR_aci_auditoria_y_actualizacion', N'TR')) > 1
        RETURN;

    IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
        THROW 50010, N'Operación denegada: No se permite eliminar físicamente activos en [sgspi].[activo_informacion]. Utilice los estados INACTIVO o HISTORICO.', 1;

    IF NOT EXISTS (SELECT 1 FROM inserted)
        RETURN;

    -- [AP-03] Contexto obligatorio para TODA operación (también INSERT); sin fallback al creador/revisor/evaluador
    DECLARE @per_sesion INT, @modo_carga BIT;
    SELECT @per_sesion = ctx.per_codigo, @modo_carga = ctx.modo_carga_inicial
    FROM   sgspi.ufn_contexto_auditoria() AS ctx;

    IF @per_sesion IS NULL
        THROW 50012, N'Contexto de auditoría ausente: Ejecute [sgspi].[usp_establecer_contexto_auditoria] antes de modificar registros.', 1;

    -- [AP-04] En INSERT el estado debe ser el inicial del dominio, salvo carga inicial habilitada por el administrador
    IF @modo_carga = 0
       AND EXISTS (
            SELECT 1
            FROM   inserted AS i
            WHERE  NOT EXISTS (SELECT 1 FROM deleted AS d WHERE d.aci_codigo = i.aci_codigo)
                   AND NOT EXISTS (
                       SELECT 1
                       FROM   sgspi.estado_flujo_catalogo AS efc
                       WHERE  efc.efc_dominio = N'ACI'
                              AND efc.efc_identificador = i.aci_estado_registro
                              AND efc.efc_es_inicial = 1
                   )
       )
        THROW 50014, N'Estado inicial inválido: un registro nuevo de [sgspi].[activo_informacion] solo puede crearse en el estado inicial del flujo.', 1;

    IF EXISTS (SELECT 1 FROM deleted)
    BEGIN
        -- [AP-05] Máquina de estados dirigida por datos: sin listas de estados codificadas
        IF EXISTS (
            SELECT 1
            FROM   inserted AS i
                   INNER JOIN deleted AS d ON d.aci_codigo = i.aci_codigo
            WHERE  (i.aci_estado_registro = d.aci_estado_registro
                    AND EXISTS (
                        SELECT 1
                        FROM   sgspi.estado_flujo_catalogo AS efc
                        WHERE  efc.efc_dominio = N'ACI'
                               AND efc.efc_identificador = d.aci_estado_registro
                               AND efc.efc_permite_edicion = 0
                    ))
                   OR (i.aci_estado_registro <> d.aci_estado_registro
                       AND NOT EXISTS (
                           SELECT 1
                           FROM   sgspi.transicion_estado_flujo AS tef
                           WHERE  tef.tef_efc_dominio = N'ACI'
                                  AND tef.tef_efc_identificador_origen = d.aci_estado_registro
                                  AND tef.tef_efc_identificador_destino = i.aci_estado_registro
                       ))
        )
        BEGIN
            THROW 50011, N'Transición inválida o intento de modificar un activo no editable (VIGENTE/HISTORICO) sin reabrir revisión en [sgspi].[activo_informacion].', 1;
        END;

        IF NOT UPDATE(aci_fecha_actualizacion)
        BEGIN
            UPDATE t
            SET    t.aci_fecha_actualizacion = SYSDATETIMEOFFSET() -- [AP-12]
            FROM   sgspi.activo_informacion AS t
                   INNER JOIN inserted AS i ON i.aci_codigo = t.aci_codigo;
        END;
    END;

    -- Se usa SELECT d.* / i.* de forma deliberada: el payload JSON captura la fila completa (antes/después) sin mantener listas de columnas
    INSERT INTO sgspi.bitacora_auditoria_sistema (
        bas_per_codigo,
        bas_gru_codigo,
        bas_usg_codigo,
        bas_direccion_ip,
        bas_entidad_afectada,
        bas_registro_afectado_codigo,
        bas_accion_ejecutada,
        bas_estado_anterior,
        bas_estado_nuevo,
        bas_valores_anteriores_json,
        bas_valores_nuevos_json,
        bas_motivo_observacion
    )
    SELECT ctx.per_codigo, -- [AP-03] sin COALESCE con creador/revisor/evaluador
           ctx.gru_codigo,
           ctx.usg_codigo,
           ctx.direccion_ip,
           N'sgspi.activo_informacion',
           i.aci_codigo,
           CASE
               WHEN d.aci_codigo IS NULL THEN N'CREAR'
               WHEN d.aci_estado_registro <> i.aci_estado_registro THEN tef.tef_accion_bitacora -- [AP-05] acción tomada de la transición
               ELSE N'ACTUALIZAR'
           END,
           d.aci_estado_registro,
           i.aci_estado_registro,
           j_ant.payload,
           j_nue.payload,
           ctx.motivo_observacion
    FROM   inserted AS i
           CROSS APPLY sgspi.ufn_contexto_auditoria() AS ctx -- [AP-21]
           LEFT OUTER JOIN deleted AS d ON d.aci_codigo = i.aci_codigo
           LEFT OUTER JOIN sgspi.transicion_estado_flujo AS tef
               ON tef.tef_efc_dominio = N'ACI'
                  AND tef.tef_efc_identificador_origen = d.aci_estado_registro
                  AND tef.tef_efc_identificador_destino = i.aci_estado_registro
           OUTER APPLY (
               SELECT d.*
               FROM   (VALUES (1)) AS v(n)
               WHERE  d.aci_codigo IS NOT NULL
               FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
           ) AS j_ant(payload)
           CROSS APPLY (
               SELECT i.*
               FROM   (VALUES (1)) AS v(n)
               FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
           ) AS j_nue(payload);
END;



GO
-- 5.10.7 Trigger sobre [sgspi].[activo_documental] ([ado] - System-Versioned Temporal Table)
-- Sin UPDATE secundario para evitar filas fantasma en [sgspi].[activo_documental_historial]
-- [AP-10] La unión con el supertipo es por PK compartida: ado_codigo = aci_codigo
CREATE OR ALTER TRIGGER sgspi.TR_ado_auditoria_y_actualizacion
ON sgspi.activo_documental
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF TRIGGER_NESTLEVEL(OBJECT_ID(N'sgspi.TR_ado_auditoria_y_actualizacion', N'TR')) > 1
        RETURN;

    IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
        THROW 50010, N'Operación denegada: No se permite eliminar físicamente activos documentales en [sgspi].[activo_documental].', 1;

    IF NOT EXISTS (SELECT 1 FROM inserted)
        RETURN;

    -- [AP-03] Contexto obligatorio para TODA operación; sin fallback al revisor de archivo ni al creador del activo
    IF NOT EXISTS (SELECT 1 FROM sgspi.ufn_contexto_auditoria() AS ctx WHERE ctx.per_codigo IS NOT NULL)
        THROW 50012, N'Contexto de auditoría ausente: Ejecute [sgspi].[usp_establecer_contexto_auditoria] antes de modificar registros.', 1;

    -- [AP-06] Una serie con subseries exige indicar la subserie (INSERT y UPDATE)
    IF EXISTS (
        SELECT 1
        FROM   inserted AS i
               INNER JOIN sgspi.serie_documental_catalogo AS sdo ON sdo.sdo_codigo = i.ado_sdo_codigo
        WHERE  sdo.sdo_tiene_subseries = 1
               AND i.ado_sbd_codigo IS NULL
    )
    BEGIN
        THROW 50015, N'Subserie requerida: la serie documental seleccionada tiene subseries y [ado_sbd_codigo] no puede ser NULL en [sgspi].[activo_documental].', 1;
    END;

    IF EXISTS (SELECT 1 FROM deleted)
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM   inserted AS i
                   INNER JOIN sgspi.activo_informacion AS aci ON aci.aci_codigo = i.ado_codigo
            WHERE  aci.aci_estado_registro = N'HISTORICO'
        )
        BEGIN
            THROW 50011, N'Operación denegada: No se permite modificar un activo documental cuyo activo de información se encuentra en estado HISTORICO en [sgspi].[activo_documental].', 1;
        END;
    END;

    -- Se usa SELECT d.* / i.* de forma deliberada: el payload JSON captura la fila completa (antes/después)
    INSERT INTO sgspi.bitacora_auditoria_sistema (
        bas_per_codigo,
        bas_gru_codigo,
        bas_usg_codigo,
        bas_direccion_ip,
        bas_entidad_afectada,
        bas_registro_afectado_codigo,
        bas_accion_ejecutada,
        bas_estado_anterior,
        bas_estado_nuevo,
        bas_valores_anteriores_json,
        bas_valores_nuevos_json,
        bas_motivo_observacion
    )
    SELECT ctx.per_codigo, -- [AP-03] sin COALESCE con ado_per_codigo_revisor_archivo
           ctx.gru_codigo,
           ctx.usg_codigo,
           ctx.direccion_ip,
           N'sgspi.activo_documental',
           i.ado_codigo,
           CASE WHEN d.ado_codigo IS NULL THEN N'CREAR' ELSE N'ACTUALIZAR' END,
           CASE WHEN d.ado_codigo IS NOT NULL THEN aci.aci_estado_registro ELSE NULL END,
           aci.aci_estado_registro,
           j_ant.payload,
           j_nue.payload,
           ctx.motivo_observacion
    FROM   inserted AS i
           CROSS APPLY sgspi.ufn_contexto_auditoria() AS ctx -- [AP-21]
           INNER JOIN sgspi.activo_informacion AS aci ON aci.aci_codigo = i.ado_codigo
           LEFT OUTER JOIN deleted AS d ON d.ado_codigo = i.ado_codigo
           OUTER APPLY (
               SELECT d.*
               FROM   (VALUES (1)) AS v(n)
               WHERE  d.ado_codigo IS NOT NULL
               FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
           ) AS j_ant(payload)
           CROSS APPLY (
               SELECT i.*
               FROM   (VALUES (1)) AS v(n)
               FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
           ) AS j_nue(payload);
END;



GO
-- 5.10.8 Trigger sobre [sgspi].[evento_incertidumbre_activo] ([eia]): Valida el flujo de estados (dirigido por datos) y alimenta [bas]
CREATE OR ALTER TRIGGER sgspi.TR_eia_auditoria_y_actualizacion
ON sgspi.evento_incertidumbre_activo
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF TRIGGER_NESTLEVEL(OBJECT_ID(N'sgspi.TR_eia_auditoria_y_actualizacion', N'TR')) > 1
        RETURN;

    IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
        THROW 50010, N'Operación denegada: No se permite eliminar físicamente eventos en [sgspi].[evento_incertidumbre_activo].', 1;

    IF NOT EXISTS (SELECT 1 FROM inserted)
        RETURN;

    -- [AP-03] Contexto obligatorio para TODA operación (también INSERT); sin fallback al creador/revisor/evaluador
    DECLARE @per_sesion INT, @modo_carga BIT;
    SELECT @per_sesion = ctx.per_codigo, @modo_carga = ctx.modo_carga_inicial
    FROM   sgspi.ufn_contexto_auditoria() AS ctx;

    IF @per_sesion IS NULL
        THROW 50012, N'Contexto de auditoría ausente: Ejecute [sgspi].[usp_establecer_contexto_auditoria] antes de modificar registros.', 1;

    -- [AP-04] En INSERT el estado debe ser el inicial del dominio, salvo carga inicial habilitada por el administrador
    IF @modo_carga = 0
       AND EXISTS (
            SELECT 1
            FROM   inserted AS i
            WHERE  NOT EXISTS (SELECT 1 FROM deleted AS d WHERE d.eia_codigo = i.eia_codigo)
                   AND NOT EXISTS (
                       SELECT 1
                       FROM   sgspi.estado_flujo_catalogo AS efc
                       WHERE  efc.efc_dominio = N'EIA'
                              AND efc.efc_identificador = i.eia_estado_registro
                              AND efc.efc_es_inicial = 1
                   )
       )
        THROW 50014, N'Estado inicial inválido: un registro nuevo de [sgspi].[evento_incertidumbre_activo] solo puede crearse en el estado inicial del flujo.', 1;

    IF EXISTS (SELECT 1 FROM deleted)
    BEGIN
        -- [AP-05] Máquina de estados dirigida por datos: sin listas de estados codificadas
        IF EXISTS (
            SELECT 1
            FROM   inserted AS i
                   INNER JOIN deleted AS d ON d.eia_codigo = i.eia_codigo
            WHERE  (i.eia_estado_registro = d.eia_estado_registro
                    AND EXISTS (
                        SELECT 1
                        FROM   sgspi.estado_flujo_catalogo AS efc
                        WHERE  efc.efc_dominio = N'EIA'
                               AND efc.efc_identificador = d.eia_estado_registro
                               AND efc.efc_permite_edicion = 0
                    ))
                   OR (i.eia_estado_registro <> d.eia_estado_registro
                       AND NOT EXISTS (
                           SELECT 1
                           FROM   sgspi.transicion_estado_flujo AS tef
                           WHERE  tef.tef_efc_dominio = N'EIA'
                                  AND tef.tef_efc_identificador_origen = d.eia_estado_registro
                                  AND tef.tef_efc_identificador_destino = i.eia_estado_registro
                       ))
        )
        BEGIN
            THROW 50011, N'Transición de estado inválida o intento de alterar un evento cerrado/histórico en [sgspi].[evento_incertidumbre_activo].', 1;
        END;
    END;

    -- Se usa SELECT d.* / i.* de forma deliberada: el payload JSON captura la fila completa (antes/después) sin mantener listas de columnas
    INSERT INTO sgspi.bitacora_auditoria_sistema (
        bas_per_codigo,
        bas_gru_codigo,
        bas_usg_codigo,
        bas_direccion_ip,
        bas_entidad_afectada,
        bas_registro_afectado_codigo,
        bas_accion_ejecutada,
        bas_estado_anterior,
        bas_estado_nuevo,
        bas_valores_anteriores_json,
        bas_valores_nuevos_json,
        bas_motivo_observacion
    )
    SELECT ctx.per_codigo, -- [AP-03] sin COALESCE con creador/revisor/evaluador
           ctx.gru_codigo,
           ctx.usg_codigo,
           ctx.direccion_ip,
           N'sgspi.evento_incertidumbre_activo',
           i.eia_codigo,
           CASE
               WHEN d.eia_codigo IS NULL THEN N'CREAR'
               WHEN d.eia_estado_registro <> i.eia_estado_registro THEN tef.tef_accion_bitacora -- [AP-05] acción tomada de la transición
               ELSE N'ACTUALIZAR'
           END,
           d.eia_estado_registro,
           i.eia_estado_registro,
           j_ant.payload,
           j_nue.payload,
           ctx.motivo_observacion
    FROM   inserted AS i
           CROSS APPLY sgspi.ufn_contexto_auditoria() AS ctx -- [AP-21]
           LEFT OUTER JOIN deleted AS d ON d.eia_codigo = i.eia_codigo
           LEFT OUTER JOIN sgspi.transicion_estado_flujo AS tef
               ON tef.tef_efc_dominio = N'EIA'
                  AND tef.tef_efc_identificador_origen = d.eia_estado_registro
                  AND tef.tef_efc_identificador_destino = i.eia_estado_registro
           OUTER APPLY (
               SELECT d.*
               FROM   (VALUES (1)) AS v(n)
               WHERE  d.eia_codigo IS NOT NULL
               FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
           ) AS j_ant(payload)
           CROSS APPLY (
               SELECT i.*
               FROM   (VALUES (1)) AS v(n)
               FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
           ) AS j_nue(payload);
END;



GO
-- 5.10.9 Trigger sobre [sgspi].[plan_tratamiento] ([plt]): Actualiza [plt_fecha_actualizacion] y alimenta [bas]
CREATE OR ALTER TRIGGER sgspi.TR_plt_auditoria_y_actualizacion
ON sgspi.plan_tratamiento
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF TRIGGER_NESTLEVEL(OBJECT_ID(N'sgspi.TR_plt_auditoria_y_actualizacion', N'TR')) > 1
        RETURN;

    IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
        THROW 50010, N'Operación denegada: No se permite eliminar físicamente planes de tratamiento en [sgspi].[plan_tratamiento].', 1;

    IF NOT EXISTS (SELECT 1 FROM inserted)
        RETURN;

    -- [AP-03] Contexto obligatorio para TODA operación; sin fallback al evaluador ni al creador del evento
    IF NOT EXISTS (SELECT 1 FROM sgspi.ufn_contexto_auditoria() AS ctx WHERE ctx.per_codigo IS NOT NULL)
        THROW 50012, N'Contexto de auditoría ausente: Ejecute [sgspi].[usp_establecer_contexto_auditoria] antes de modificar registros.', 1;

    IF EXISTS (SELECT 1 FROM deleted)
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM   inserted AS i
                   INNER JOIN sgspi.evento_incertidumbre_activo AS eia ON eia.eia_codigo = i.plt_eia_codigo
            WHERE  eia.eia_estado_registro IN (N'CERRADO_EFICAZ', N'HISTORICO')
        )
        BEGIN
            THROW 50011, N'Operación denegada: No se permite modificar el plan de tratamiento de un evento CERRADO_EFICAZ o HISTORICO en [sgspi].[plan_tratamiento].', 1;
        END;

        IF NOT UPDATE(plt_fecha_actualizacion)
        BEGIN
            UPDATE t
            SET    t.plt_fecha_actualizacion = SYSDATETIMEOFFSET() -- [AP-12]
            FROM   sgspi.plan_tratamiento AS t
                   INNER JOIN inserted AS i ON i.plt_codigo = t.plt_codigo;
        END;
    END;

    -- Se usa SELECT d.* / i.* de forma deliberada: el payload JSON captura la fila completa (antes/después)
    INSERT INTO sgspi.bitacora_auditoria_sistema (
        bas_per_codigo,
        bas_gru_codigo,
        bas_usg_codigo,
        bas_direccion_ip,
        bas_entidad_afectada,
        bas_registro_afectado_codigo,
        bas_accion_ejecutada,
        bas_estado_anterior,
        bas_estado_nuevo,
        bas_valores_anteriores_json,
        bas_valores_nuevos_json,
        bas_motivo_observacion
    )
    SELECT ctx.per_codigo, -- [AP-03] sin COALESCE con evaluador/creador
           ctx.gru_codigo,
           ctx.usg_codigo,
           ctx.direccion_ip,
           N'sgspi.plan_tratamiento',
           i.plt_codigo,
           CASE WHEN d.plt_codigo IS NULL THEN N'CREAR' ELSE N'ACTUALIZAR' END,
           CASE WHEN d.plt_codigo IS NOT NULL THEN eia.eia_estado_registro ELSE NULL END,
           eia.eia_estado_registro,
           j_ant.payload,
           j_nue.payload,
           ctx.motivo_observacion
    FROM   inserted AS i
           CROSS APPLY sgspi.ufn_contexto_auditoria() AS ctx -- [AP-21]
           INNER JOIN sgspi.evento_incertidumbre_activo AS eia ON eia.eia_codigo = i.plt_eia_codigo
           LEFT OUTER JOIN deleted AS d ON d.plt_codigo = i.plt_codigo
           OUTER APPLY (
               SELECT d.*
               FROM   (VALUES (1)) AS v(n)
               WHERE  d.plt_codigo IS NOT NULL
               FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
           ) AS j_ant(payload)
           CROSS APPLY (
               SELECT i.*
               FROM   (VALUES (1)) AS v(n)
               FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
           ) AS j_nue(payload);
END;



GO
-- 5.10.10 Trigger sobre [sgspi].[actividad_tratamiento] ([act]): Actualiza [act_fecha_actualizacion], valida el flujo de estados (dirigido por datos) y alimenta [bas]
CREATE OR ALTER TRIGGER sgspi.TR_act_auditoria_y_actualizacion
ON sgspi.actividad_tratamiento
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF TRIGGER_NESTLEVEL(OBJECT_ID(N'sgspi.TR_act_auditoria_y_actualizacion', N'TR')) > 1
        RETURN;

    IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
        THROW 50010, N'Operación denegada: No se permite eliminar físicamente actividades de tratamiento en [sgspi].[actividad_tratamiento].', 1;

    IF NOT EXISTS (SELECT 1 FROM inserted)
        RETURN;

    -- [AP-03] Contexto obligatorio para TODA operación (también INSERT); sin fallback al creador/revisor/evaluador
    DECLARE @per_sesion INT, @modo_carga BIT;
    SELECT @per_sesion = ctx.per_codigo, @modo_carga = ctx.modo_carga_inicial
    FROM   sgspi.ufn_contexto_auditoria() AS ctx;

    IF @per_sesion IS NULL
        THROW 50012, N'Contexto de auditoría ausente: Ejecute [sgspi].[usp_establecer_contexto_auditoria] antes de modificar registros.', 1;

    -- [AP-04] En INSERT el estado debe ser el inicial del dominio, salvo carga inicial habilitada por el administrador
    IF @modo_carga = 0
       AND EXISTS (
            SELECT 1
            FROM   inserted AS i
            WHERE  NOT EXISTS (SELECT 1 FROM deleted AS d WHERE d.act_codigo = i.act_codigo)
                   AND NOT EXISTS (
                       SELECT 1
                       FROM   sgspi.estado_flujo_catalogo AS efc
                       WHERE  efc.efc_dominio = N'ACT'
                              AND efc.efc_identificador = i.act_estado_actividad
                              AND efc.efc_es_inicial = 1
                   )
       )
        THROW 50014, N'Estado inicial inválido: un registro nuevo de [sgspi].[actividad_tratamiento] solo puede crearse en el estado inicial del flujo.', 1;

    IF EXISTS (SELECT 1 FROM deleted)
    BEGIN
        -- [AP-05] Máquina de estados dirigida por datos: sin listas de estados codificadas
        IF EXISTS (
            SELECT 1
            FROM   inserted AS i
                   INNER JOIN deleted AS d ON d.act_codigo = i.act_codigo
            WHERE  (i.act_estado_actividad = d.act_estado_actividad
                    AND EXISTS (
                        SELECT 1
                        FROM   sgspi.estado_flujo_catalogo AS efc
                        WHERE  efc.efc_dominio = N'ACT'
                               AND efc.efc_identificador = d.act_estado_actividad
                               AND efc.efc_permite_edicion = 0
                    ))
                   OR (i.act_estado_actividad <> d.act_estado_actividad
                       AND NOT EXISTS (
                           SELECT 1
                           FROM   sgspi.transicion_estado_flujo AS tef
                           WHERE  tef.tef_efc_dominio = N'ACT'
                                  AND tef.tef_efc_identificador_origen = d.act_estado_actividad
                                  AND tef.tef_efc_identificador_destino = i.act_estado_actividad
                       ))
        )
        BEGIN
            THROW 50011, N'Transición de estado inválida o intento de modificar una actividad en estado no editable (COMPLETADA) en [sgspi].[actividad_tratamiento].', 1;
        END;

        -- Regla conservada: no se tocan actividades de un evento CERRADO_EFICAZ o HISTORICO
        IF EXISTS (
            SELECT 1
            FROM   inserted AS i
                   INNER JOIN sgspi.plan_tratamiento AS plt ON plt.plt_codigo = i.act_plt_codigo
                   INNER JOIN sgspi.evento_incertidumbre_activo AS eia ON eia.eia_codigo = plt.plt_eia_codigo
            WHERE  eia.eia_estado_registro IN (N'CERRADO_EFICAZ', N'HISTORICO')
        )
        BEGIN
            THROW 50011, N'Operación denegada: No se permite modificar actividades de un evento CERRADO_EFICAZ o HISTORICO en [sgspi].[actividad_tratamiento].', 1;
        END;

        IF NOT UPDATE(act_fecha_actualizacion)
        BEGIN
            UPDATE t
            SET    t.act_fecha_actualizacion = SYSDATETIMEOFFSET() -- [AP-12]
            FROM   sgspi.actividad_tratamiento AS t
                   INNER JOIN inserted AS i ON i.act_codigo = t.act_codigo;
        END;
    END;

    -- Se usa SELECT d.* / i.* de forma deliberada: el payload JSON captura la fila completa (antes/después) sin mantener listas de columnas
    INSERT INTO sgspi.bitacora_auditoria_sistema (
        bas_per_codigo,
        bas_gru_codigo,
        bas_usg_codigo,
        bas_direccion_ip,
        bas_entidad_afectada,
        bas_registro_afectado_codigo,
        bas_accion_ejecutada,
        bas_estado_anterior,
        bas_estado_nuevo,
        bas_valores_anteriores_json,
        bas_valores_nuevos_json,
        bas_motivo_observacion
    )
    SELECT ctx.per_codigo, -- [AP-03] sin COALESCE con creador/revisor/evaluador
           ctx.gru_codigo,
           ctx.usg_codigo,
           ctx.direccion_ip,
           N'sgspi.actividad_tratamiento',
           i.act_codigo,
           CASE
               WHEN d.act_codigo IS NULL THEN N'CREAR'
               WHEN d.act_estado_actividad <> i.act_estado_actividad THEN tef.tef_accion_bitacora -- [AP-05] acción tomada de la transición
               ELSE N'ACTUALIZAR'
           END,
           d.act_estado_actividad,
           i.act_estado_actividad,
           j_ant.payload,
           j_nue.payload,
           ctx.motivo_observacion
    FROM   inserted AS i
           CROSS APPLY sgspi.ufn_contexto_auditoria() AS ctx -- [AP-21]
           LEFT OUTER JOIN deleted AS d ON d.act_codigo = i.act_codigo
           LEFT OUTER JOIN sgspi.transicion_estado_flujo AS tef
               ON tef.tef_efc_dominio = N'ACT'
                  AND tef.tef_efc_identificador_origen = d.act_estado_actividad
                  AND tef.tef_efc_identificador_destino = i.act_estado_actividad
           OUTER APPLY (
               SELECT d.*
               FROM   (VALUES (1)) AS v(n)
               WHERE  d.act_codigo IS NOT NULL
               FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
           ) AS j_ant(payload)
           CROSS APPLY (
               SELECT i.*
               FROM   (VALUES (1)) AS v(n)
               FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
           ) AS j_nue(payload);
END;



GO
-- 5.10.11 Trigger sobre [sgspi].[evaluacion_aplicabilidad_control] ([eac] - System-Versioned Temporal Table)
-- Sin UPDATE secundario para evitar filas fantasma en [sgspi].[evaluacion_aplicabilidad_control_historial]
CREATE OR ALTER TRIGGER sgspi.TR_eac_auditoria_y_actualizacion
ON sgspi.evaluacion_aplicabilidad_control
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF TRIGGER_NESTLEVEL(OBJECT_ID(N'sgspi.TR_eac_auditoria_y_actualizacion', N'TR')) > 1
        RETURN;

    IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
        THROW 50010, N'Operación denegada: No se permite eliminar físicamente evaluaciones de aplicabilidad (SoA) en [sgspi].[evaluacion_aplicabilidad_control].', 1;

    IF NOT EXISTS (SELECT 1 FROM inserted)
        RETURN;

    -- [AP-03] Contexto obligatorio para TODA operación (también INSERT)
    IF NOT EXISTS (SELECT 1 FROM sgspi.ufn_contexto_auditoria() AS ctx WHERE ctx.per_codigo IS NOT NULL)
        THROW 50012, N'Contexto de auditoría ausente: Ejecute [sgspi].[usp_establecer_contexto_auditoria] antes de modificar registros.', 1;

    -- Se usa SELECT d.* / i.* de forma deliberada: el payload JSON captura la fila completa (antes/después)
    INSERT INTO sgspi.bitacora_auditoria_sistema (
        bas_per_codigo,
        bas_gru_codigo,
        bas_usg_codigo,
        bas_direccion_ip,
        bas_entidad_afectada,
        bas_registro_afectado_codigo,
        bas_accion_ejecutada,
        bas_estado_anterior,
        bas_estado_nuevo,
        bas_valores_anteriores_json,
        bas_valores_nuevos_json,
        bas_motivo_observacion
    )
    SELECT ctx.per_codigo,
           ctx.gru_codigo,
           ctx.usg_codigo,
           ctx.direccion_ip,
           N'sgspi.evaluacion_aplicabilidad_control',
           i.eac_codigo,
           CASE
               WHEN d.eac_codigo IS NULL THEN N'CREAR'
               WHEN ISNULL(d.eac_estado_implementacion, N'') <> ISNULL(i.eac_estado_implementacion, N'') THEN N'TRANSICION_ESTADO'
               ELSE N'ACTUALIZAR'
           END,
           d.eac_estado_implementacion,
           i.eac_estado_implementacion,
           j_ant.payload,
           j_nue.payload,
           ctx.motivo_observacion
    FROM   inserted AS i
           CROSS APPLY sgspi.ufn_contexto_auditoria() AS ctx -- [AP-21]
           LEFT OUTER JOIN deleted AS d ON d.eac_codigo = i.eac_codigo
           OUTER APPLY (
               SELECT d.*
               FROM   (VALUES (1)) AS v(n)
               WHERE  d.eac_codigo IS NOT NULL
               FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
           ) AS j_ant(payload)
           CROSS APPLY (
               SELECT i.*
               FROM   (VALUES (1)) AS v(n)
               FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
           ) AS j_nue(payload);
END;


GO
-- 5.10.12 Triggers sobre [sgspi].[seguimiento_actividad] ([sga]) [AP-16]
-- Inmutabilidad: el seguimiento con evidencia es append-only (INSTEAD OF UPDATE, DELETE)
CREATE OR ALTER TRIGGER sgspi.TR_sga_inmutabilidad
ON sgspi.seguimiento_actividad
INSTEAD OF UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    THROW 50016, N'Operación denegada: el seguimiento de actividades con evidencia es append-only; registre un nuevo seguimiento en [sgspi].[seguimiento_actividad].', 1;
END;


GO
-- [AP-09] El avance de la actividad deja de ser un dato duplicado y desincronizado: se deriva del último seguimiento reportado.
-- El UPDATE sobre [act] dispara TR_act_auditoria_y_actualizacion (audita y aplica sus reglas de estado): es lo deseado.
CREATE OR ALTER TRIGGER sgspi.TR_sga_sincronizar_avance
ON sgspi.seguimiento_actividad
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM inserted)
        RETURN;

    -- [AP-03] Contexto obligatorio
    IF NOT EXISTS (SELECT 1 FROM sgspi.ufn_contexto_auditoria() AS ctx WHERE ctx.per_codigo IS NOT NULL)
        THROW 50012, N'Contexto de auditoría ausente: Ejecute [sgspi].[usp_establecer_contexto_auditoria] antes de modificar registros.', 1;

    -- Si hay varias filas de la misma actividad en el lote, prevalece la de mayor sga_codigo
    UPDATE act
    SET    act.act_porcentaje_avance = x.sga_porcentaje_reportado
    FROM   sgspi.actividad_tratamiento AS act
           INNER JOIN (SELECT i.sga_act_codigo,
                              i.sga_porcentaje_reportado,
                              ROW_NUMBER() OVER (PARTITION BY i.sga_act_codigo ORDER BY i.sga_codigo DESC) AS rn
                       FROM   inserted AS i) AS x
           ON x.sga_act_codigo = act.act_codigo
              AND x.rn = 1
    WHERE  act.act_porcentaje_avance <> x.sga_porcentaje_reportado;
END;


GO
-- 5.10.13 Roles y permisos [AP-02]: la inmutabilidad no puede depender solo de triggers (TRUNCATE / DISABLE TRIGGER los evaden)
-- Nota: dbo / db_owner / sysadmin NO se pueden restringir con DENY; frente a ellos la defensa es la cadena de hash
-- ([bas_hash_evento_anterior] + [sgspi].[usp_verificar_cadena_bitacora]), que detecta cualquier alteración o borrado intermedio.
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'sgspi_rol_aplicacion' AND type = N'R')
    CREATE ROLE sgspi_rol_aplicacion;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'sgspi_rol_administrador' AND type = N'R')
    CREATE ROLE sgspi_rol_administrador;

GRANT SELECT, INSERT, UPDATE ON SCHEMA::sgspi TO sgspi_rol_aplicacion;
GRANT EXECUTE ON sgspi.usp_establecer_contexto_auditoria TO sgspi_rol_aplicacion;
-- ALTER sobre la tabla es lo que permite TRUNCATE TABLE y DISABLE TRIGGER
DENY UPDATE, DELETE, ALTER ON sgspi.bitacora_auditoria_sistema TO sgspi_rol_aplicacion;
DENY ALTER ON SCHEMA::sgspi TO sgspi_rol_aplicacion;

-- Solo el administrador puede habilitar la carga inicial y verificar la cadena de hash
GRANT EXECUTE ON sgspi.usp_habilitar_carga_inicial TO sgspi_rol_administrador;
GRANT EXECUTE ON sgspi.usp_verificar_cadena_bitacora TO sgspi_rol_administrador;



GO
/*==================================================================================================
  6. VISTAS DINÁMICAS PARA CAMPOS CALCULADOS E INTEGRACIÓN CON [dbo]
==================================================================================================*/
-- 6.0 Vista de Integración de Seguridad y Alcance por Proceso/UAA
-- [AP-21] CONCAT con literales Unicode (N'')
CREATE OR ALTER VIEW sgspi.vw_usuario_rol_alcance_sgspi
AS
SELECT p.per_codigo,
       p.per_identificacion,
       CONCAT(RTRIM(ISNULL(p.per_nombre, N'')), N' ', RTRIM(ISNULL(p.per_apellido, N''))) AS per_nombre_completo,
       p.per_email_interno AS per_correo_institucional,
       ug.usg_codigo,
       ug.usg_usuario AS uge_codigo_usuario,
       g.gru_codigo,
       g.gru_nombre AS gru_rol_seguridad,
       u.uaa_codigo,
       u.uaa_nombre AS uaa_dependencia,
       piu.piu_pri_codigo AS pri_codigo,
       pr.pri_nombre AS pri_nombre_proceso
FROM   dbo.usuario_grupo AS ug
       INNER JOIN
       dbo.grupo AS g
       ON g.gru_codigo = ug.usg_grupo
       INNER JOIN
       dbo.uaa AS u
       ON u.uaa_codigo = ug.usg_uaa
       INNER JOIN
       dbo.usuario_general AS ugen
       ON ugen.uid = ug.usg_usuario
       INNER JOIN
       dbo.persona AS p
       ON p.per_codigo = ugen.up
       LEFT OUTER JOIN
       sgspi.proceso_institucional_uaa AS piu
       ON piu.piu_uaa_codigo = u.uaa_codigo
       LEFT OUTER JOIN
       sgspi.proceso_institucional AS pr
       ON pr.pri_codigo = piu.piu_pri_codigo
WHERE  ug.usg_estado = 1
       AND g.gru_estado = 1;


GO
-- 6.1 Vista Consolidado DOFA (Proyecta los identificadores inmutables persistidos D1..Dn, F1..Fn, A1..An, O1..On)
CREATE OR ALTER VIEW sgspi.vw_consolidado_dofa
AS
SELECT acf.acf_codigo,
       pv.pev_anio AS pev_vigencia,
       tpc.tpr_nombre AS tpr_tipo_proceso,
       pr.pri_nombre AS pri_proceso,
       fec.fec_nombre_factor AS fec_variable_entorno,
       fec.fec_ambito_entorno,
       acf.acf_naturaleza_factor,
       acf.acf_numero_factor,
       acf.acf_identificador_factor,
       acf.acf_descripcion_situacion,
       acf.acf_valor_prioridad,
       acf.acf_nivel_prioridad,
       acf.acf_impacto_sistema_gestion,
       acf.acf_accion_propuesta,
       acf.acf_estado_registro
FROM   sgspi.analisis_contexto_factor AS acf
       INNER JOIN
       sgspi.periodo_vigencia AS pv
       ON pv.pev_codigo = acf.acf_pev_codigo
       INNER JOIN
       sgspi.proceso_institucional AS pr
       ON pr.pri_codigo = acf.acf_pri_codigo
       INNER JOIN
       sgspi.tipo_proceso_catalogo AS tpc
       ON tpc.tpr_codigo = pr.pri_tpr_codigo
       INNER JOIN
       sgspi.factor_entorno_catalogo AS fec
       ON fec.fec_codigo = acf.acf_fec_codigo;


GO
-- 6.2 Vista Resumen de Activos por Categoría, Tipo y Criticidad (Reemplaza Tabla Dinámica de ES-GSPI-MR-05 sobre jerarquía normalizada [tac])
CREATE OR ALTER VIEW sgspi.vw_resumen_activos_criticidad
AS
WITH   cte_taxonomia_activo
AS     (SELECT ai.aci_codigo,
               ai.aci_nivel_criticidad,
               COALESCE(abu.tac_nombre, pad.tac_nombre, tac.tac_nombre) AS tac_categoria_iso27005,
               CASE WHEN tac.tac_nivel_taxonomia = 3 THEN pad.tac_nombre ELSE tac.tac_nombre END AS tac_tipo_activo
        FROM   sgspi.activo_informacion AS ai
               INNER JOIN
               sgspi.tipo_activo_catalogo AS tac
               ON tac.tac_codigo = ai.aci_tac_codigo
               LEFT OUTER JOIN
               sgspi.tipo_activo_catalogo AS pad
               ON pad.tac_codigo = tac.tac_tac_codigo_padre
               LEFT OUTER JOIN
               sgspi.tipo_activo_catalogo AS abu
               ON abu.tac_codigo = pad.tac_tac_codigo_padre
        WHERE  ai.aci_estado_registro = N'VIGENTE')
SELECT   CASE WHEN GROUPING(t.tac_categoria_iso27005) = 1 THEN N'Total general' ELSE t.tac_categoria_iso27005 END AS tac_categoria_activo, -- [AP-20] GROUPING en vez de ISNULL
         CASE WHEN GROUPING(t.tac_tipo_activo) = 1 THEN N'Subtotal categoría' ELSE t.tac_tipo_activo END AS tac_tipo_activo,
         SUM(CASE WHEN t.aci_nivel_criticidad = N'ALTA' THEN 1 ELSE 0 END) AS aci_criticidad_alta,
         SUM(CASE WHEN t.aci_nivel_criticidad = N'MEDIA' THEN 1 ELSE 0 END) AS aci_criticidad_media,
         SUM(CASE WHEN t.aci_nivel_criticidad = N'BAJA' THEN 1 ELSE 0 END) AS aci_criticidad_baja,
         COUNT(t.aci_codigo) AS aci_total_general
FROM     cte_taxonomia_activo AS t
GROUP BY GROUPING SETS((t.tac_categoria_iso27005, t.tac_tipo_activo), (t.tac_categoria_iso27005), ());


GO
-- 6.3 Vista Matriz de Tratamiento de Riesgos y Oportunidades (Calcula concatenaciones y cruces en tiempo real)
CREATE OR ALTER VIEW sgspi.vw_matriz_tratamiento_riesgos
AS
WITH   cte_controles_27001
AS     (SELECT   ptc.ptc_plt_codigo,
                 STRING_AGG(crn.crn_identificador_control, N', ') WITHIN GROUP (ORDER BY crn.crn_codigo) AS crn_controles_iso27001
        FROM     sgspi.plan_tratamiento_control_referencia_normativa AS ptc
                 INNER JOIN
                 sgspi.control_referencia_normativa AS crn
                 ON crn.crn_codigo = ptc.ptc_crn_codigo
                 INNER JOIN
                 sgspi.estandar_normativo_catalogo AS enc
                 ON enc.enc_codigo = crn.crn_enc_codigo
        WHERE    enc.enc_familia_norma = N'ISO27001' -- [AP-13]
        GROUP BY ptc.ptc_plt_codigo),
       cte_controles_27701
AS     (SELECT   ptc.ptc_plt_codigo,
                 STRING_AGG(CONCAT_WS(N': ', crn.crn_rol_privacidad_pii, crn.crn_identificador_control), N' | ') WITHIN GROUP (ORDER BY crn.crn_codigo) AS crn_controles_iso27701
        FROM     sgspi.plan_tratamiento_control_referencia_normativa AS ptc
                 INNER JOIN
                 sgspi.control_referencia_normativa AS crn
                 ON crn.crn_codigo = ptc.ptc_crn_codigo
                 INNER JOIN
                 sgspi.estandar_normativo_catalogo AS enc
                 ON enc.enc_codigo = crn.crn_enc_codigo
        WHERE    enc.enc_familia_norma = N'ISO27701' -- [AP-13]
        GROUP BY ptc.ptc_plt_codigo)
SELECT eia.eia_identificador_evento AS eia_codigo_riesgo_oportunidad,
       eia.eia_escenario_operacional AS eia_riesgo_oportunidad,
       pr.pri_nombre AS pri_proceso,
       CONCAT(N'Activo primario: ', ap.aci_nombre_activo, N' | Activo secundario: ', asop.aci_nombre_activo) AS eia_detalle_del_riesgo,
       CONCAT(N'Posibilidad: ', ep_inh.epr_nombre_nivel, N' (', ep_inh.epr_codigo_letra, N') | Impacto: ', CASE WHEN eia.eia_naturaleza_evento = N'RIESGO' THEN ei_inh.eim_nombre_impacto_negativo ELSE ei_inh.eim_nombre_impacto_positivo END, N' (', ei_inh.eim_codigo, N') | Nivel actual: ', zrc_inh.zrc_nombre_nivel) AS eia_resultado_actual,
       CONCAT(N'Posibilidad: ', ep_meta.epr_nombre_nivel, N' (', ep_meta.epr_codigo_letra, N') | Impacto: ', CASE WHEN eia.eia_naturaleza_evento = N'RIESGO' THEN ei_meta.eim_nombre_impacto_negativo ELSE ei_meta.eim_nombre_impacto_positivo END, N' (', ei_meta.eim_codigo, N') | Nivel esperado: ', zrc_meta.zrc_nombre_nivel) AS plt_resultado_esperado,
       c27001.crn_controles_iso27001,
       c27701.crn_controles_iso27701,
       etc.etc_nombre_estrategia AS plt_opcion_tratamiento,
       pt.plt_justificacion_estrategia,
       pt.plt_fecha_inicio,
       pt.plt_fecha_fin,
       CONCAT(CONVERT(NVARCHAR(10), pt.plt_fecha_inicio, 103), N' – ', CONVERT(NVARCHAR(10), pt.plt_fecha_fin, 103)) AS plt_cronograma,
       pt.plt_recursos_humanos_tecnicos,
       pt.plt_recursos_economicos_desc,
       pt.plt_restricciones_limitaciones AS plt_limitaciones,
       pt.plt_nombre_indicador_kpi AS plt_indicador_rendimiento,
       pt.plt_unidad_medida_kpi,
       pt.plt_meta_indicador_kpi,
       pt.plt_valor_alcanzado_kpi,
       pt.plt_porcentaje_cumplimiento_kpi,
       pt.plt_es_tratamiento_eficaz AS plt_eficacia,
       eia.eia_estado_registro
FROM   sgspi.evento_incertidumbre_activo AS eia
       INNER JOIN
       sgspi.plan_tratamiento AS pt
       ON pt.plt_eia_codigo = eia.eia_codigo
       INNER JOIN
       sgspi.estrategia_tratamiento_catalogo AS etc
       ON etc.etc_codigo = pt.plt_etc_codigo
       INNER JOIN
       sgspi.proceso_institucional AS pr
       ON pr.pri_codigo = eia.eia_pri_codigo
       INNER JOIN
       sgspi.activo_informacion AS ap
       ON ap.aci_codigo = eia.eia_aci_codigo_primario
       INNER JOIN
       sgspi.activo_informacion AS asop
       ON asop.aci_codigo = eia.eia_aci_codigo_soporte
       INNER JOIN
       sgspi.escala_probabilidad AS ep_inh
       ON ep_inh.epr_codigo = eia.eia_epr_codigo_inherente
       INNER JOIN
       sgspi.escala_impacto AS ei_inh
       ON ei_inh.eim_codigo = eia.eia_eim_codigo_inherente
       INNER JOIN
       sgspi.matriz_valoracion_riesgo AS mvr_inh
       ON mvr_inh.mvr_epr_codigo = eia.eia_epr_codigo_inherente
          AND mvr_inh.mvr_eim_codigo = eia.eia_eim_codigo_inherente
       INNER JOIN
       sgspi.zona_riesgo_catalogo AS zrc_inh -- [AP-13] nivel de valoración desde el catálogo de zonas
       ON zrc_inh.zrc_codigo = mvr_inh.mvr_zrc_codigo
       INNER JOIN
       sgspi.escala_probabilidad AS ep_meta
       ON ep_meta.epr_codigo = pt.plt_epr_codigo_residual_meta
       INNER JOIN
       sgspi.escala_impacto AS ei_meta
       ON ei_meta.eim_codigo = pt.plt_eim_codigo_residual_meta
       INNER JOIN
       sgspi.matriz_valoracion_riesgo AS mvr_meta
       ON mvr_meta.mvr_epr_codigo = pt.plt_epr_codigo_residual_meta
          AND mvr_meta.mvr_eim_codigo = pt.plt_eim_codigo_residual_meta
       INNER JOIN
       sgspi.zona_riesgo_catalogo AS zrc_meta
       ON zrc_meta.zrc_codigo = mvr_meta.mvr_zrc_codigo
       LEFT OUTER JOIN
       cte_controles_27001 AS c27001
       ON c27001.ptc_plt_codigo = pt.plt_codigo
       LEFT OUTER JOIN
       cte_controles_27701 AS c27701
       ON c27701.ptc_plt_codigo = pt.plt_codigo;


GO
-- 6.4 Vista de Desglose Jerárquico del Cuadro de Clasificación Documental CCD/TRD (ES-GSPI-MR-04: Resolución Jerárquica N-Niveles con HIERARCHYID)
CREATE OR ALTER VIEW sgspi.vw_desglose_ccd_trd_mr04
AS
WITH   cte_jerarquia_ccd
AS     (SELECT   u.upc_codigo,
                 u.upc_nodo_jerarquico,
                 u.upc_nivel_jerarquico,
                 u.upc_prefijo_archivistico,
                 u.upc_nombre_unidad,
                 raiz.upc_prefijo_archivistico AS upc_cod_seccion_raiz,
                 raiz.upc_nombre_unidad AS upc_nombre_seccion_raiz,
                 STRING_AGG(anc.upc_prefijo_archivistico, N' > ') WITHIN GROUP (ORDER BY anc.upc_nodo_jerarquico) AS upc_ruta_prefijos_ccd,
                 STRING_AGG(anc.upc_nombre_unidad, N' > ') WITHIN GROUP (ORDER BY anc.upc_nodo_jerarquico) AS upc_ruta_jerarquica_unidad
        FROM     sgspi.unidad_productora_cuadro_clasificacion_documental AS u
                 INNER JOIN
                 sgspi.unidad_productora_cuadro_clasificacion_documental AS anc
                 ON u.upc_nodo_jerarquico.IsDescendantOf(anc.upc_nodo_jerarquico) = 1
                 INNER JOIN
                 sgspi.unidad_productora_cuadro_clasificacion_documental AS raiz
                 ON raiz.upc_nodo_jerarquico = u.upc_nodo_jerarquico.GetAncestor(u.upc_nodo_jerarquico.GetLevel() - 1)
        GROUP BY u.upc_codigo,
                 u.upc_nodo_jerarquico,
                 u.upc_nivel_jerarquico,
                 u.upc_prefijo_archivistico,
                 u.upc_nombre_unidad,
                 raiz.upc_prefijo_archivistico,
                 raiz.upc_nombre_unidad)
SELECT adu.adu_ado_codigo AS ado_codigo,
       adu.adu_upc_codigo AS upc_codigo,
       j.upc_nodo_jerarquico,
       j.upc_nivel_jerarquico,
       j.upc_prefijo_archivistico,
       j.upc_nombre_unidad,
       j.upc_cod_seccion_raiz,
       j.upc_nombre_seccion_raiz,
       j.upc_ruta_prefijos_ccd,
       j.upc_ruta_jerarquica_unidad,
       sdo.sdo_numero_ccd AS sdo_cod5_serie,
       sdo.sdo_nombre_serie,
       sbd.sbd_numero_ccd AS sbd_cod6_subserie,
       sbd.sbd_nombre_subserie,
       -- Cálculo en tiempo de ejecución de los códigos archivísticos TRD: <prefijo_unidad>.<COD5> y <prefijo_unidad>.<COD5>.<COD6>
       CONCAT_WS(N'.', j.upc_prefijo_archivistico, sdo.sdo_numero_ccd) AS adu_codigo_serie_trd_calculado,
       CONCAT_WS(N'.', j.upc_prefijo_archivistico, sdo.sdo_numero_ccd, sbd.sbd_numero_ccd) AS adu_codigo_subserie_trd_calculado
FROM   sgspi.activo_documental_unidad_productora AS adu
       INNER JOIN
       sgspi.activo_documental AS ado
       ON ado.ado_codigo = adu.adu_ado_codigo
       INNER JOIN
       cte_jerarquia_ccd AS j
       ON j.upc_codigo = adu.adu_upc_codigo
       INNER JOIN
       sgspi.serie_documental_catalogo AS sdo
       ON sdo.sdo_codigo = ado.ado_sdo_codigo
       LEFT OUTER JOIN
       sgspi.subserie_documental_catalogo AS sbd
       ON sbd.sbd_sdo_codigo = ado.ado_sdo_codigo
          AND sbd.sbd_codigo = ado.ado_sbd_codigo
WHERE  adu.adu_esta_activo = 1;


GO
-- 6.5 Vista Matriz Consolidada de Inventario y Clasificación de Activos Documentales (Une Subtipo [ado] con Supertipo [aci] para ES-GSPI-MR-04)
CREATE OR ALTER VIEW sgspi.vw_inventario_activo_documental_mr04
AS
WITH   cte_trd_agregado
AS     (SELECT   v.ado_codigo,
                 STRING_AGG(v.adu_codigo_serie_trd_calculado, N', ') WITHIN GROUP (ORDER BY v.upc_codigo) AS ado_codigos_serie_documental_trd,
                 STRING_AGG(v.adu_codigo_subserie_trd_calculado, N', ') WITHIN GROUP (ORDER BY v.upc_codigo) AS ado_codigos_subserie_documental_trd
        FROM     sgspi.vw_desglose_ccd_trd_mr04 AS v
        GROUP BY v.ado_codigo),
       cte_procesos_doc
AS     (SELECT   aip.aip_aci_codigo,
                 STRING_AGG(pr.pri_nombre, N', ') WITHIN GROUP (ORDER BY pr.pri_codigo) AS ado_procesos_asociados
        FROM     sgspi.activo_informacion_proceso_institucional AS aip
                 INNER JOIN
                 sgspi.proceso_institucional AS pr
                 ON pr.pri_codigo = aip.aip_pri_codigo
        GROUP BY aip.aip_aci_codigo),
       cte_dependencias_doc
AS     (SELECT   x.air_aci_codigo,
                 STRING_AGG(CONVERT(NVARCHAR(200), x.uaa_nombre), N', ') WITHIN GROUP (ORDER BY x.uaa_nombre) AS ado_dependencias_oficinas
        FROM     (SELECT DISTINCT air.air_aci_codigo,
                                  u.uaa_nombre
                  FROM   sgspi.activo_informacion_responsable AS air
                         INNER JOIN
                         dbo.uaa AS u
                         ON u.uaa_codigo = air.air_uaa_codigo
                  WHERE  air.air_esta_activo = 1) AS x
        GROUP BY x.air_aci_codigo),
       cte_propietarios_doc
AS     (SELECT   air.air_aci_codigo,
                 STRING_AGG(CONVERT(NVARCHAR(100), c.car_nombre), N', ') WITHIN GROUP (ORDER BY air.air_car_codigo, air.air_uaa_codigo) AS ado_propietarios_activo
        FROM     sgspi.activo_informacion_responsable AS air
                 INNER JOIN
                 dbo.cargo AS c
                 ON c.car_codigo = air.air_car_codigo
        WHERE    air.air_esta_activo = 1
                 AND air.air_tipo_responsabilidad = N'PROPIETARIO'
        GROUP BY air.air_aci_codigo),
       cte_custodios_doc
AS     (SELECT   air.air_aci_codigo,
                 STRING_AGG(CONVERT(NVARCHAR(100), c.car_nombre), N', ') WITHIN GROUP (ORDER BY air.air_car_codigo, air.air_uaa_codigo) AS ado_custodios_activo
        FROM     sgspi.activo_informacion_responsable AS air
                 INNER JOIN
                 dbo.cargo AS c
                 ON c.car_codigo = air.air_car_codigo
        WHERE    air.air_esta_activo = 1
                 AND air.air_tipo_responsabilidad = N'CUSTODIO'
        GROUP BY air.air_aci_codigo),
       cte_soportes_doc
AS     (SELECT   ads.ads_ado_codigo,
                 STRING_AGG(src.src_nombre, N'/') WITHIN GROUP (ORDER BY src.src_nombre DESC) AS ado_soporte_registro
        FROM     sgspi.activo_documental_soporte_registro AS ads
                 INNER JOIN
                 sgspi.soporte_registro_catalogo AS src
                 ON src.src_codigo = ads.ads_src_codigo
        GROUP BY ads.ads_ado_codigo),
       cte_medios_doc
AS     (SELECT   adm.adm_ado_codigo,
                 STRING_AGG(mcc.mcc_nombre, N'/') WITHIN GROUP (ORDER BY mcc.mcc_nombre DESC) AS ado_medio_conservacion
        FROM     sgspi.activo_documental_medio_conservacion AS adm
                 INNER JOIN
                 sgspi.medio_conservacion_catalogo AS mcc
                 ON mcc.mcc_codigo = adm.adm_mcc_codigo
        GROUP BY adm.adm_ado_codigo),
       cte_idiomas_doc
AS     (SELECT   adi.adi_ado_codigo,
                 STRING_AGG(idi.idi_nombre, N'/') WITHIN GROUP (ORDER BY idi.idi_nombre) AS ado_idioma
        FROM     sgspi.activo_documental_idioma AS adi
                 INNER JOIN
                 sgspi.idioma_catalogo AS idi
                 ON idi.idi_codigo = adi.adi_idi_codigo
        GROUP BY adi.adi_ado_codigo),
       -- [AP-08] El formato documental ahora es multivaluado normalizado ([adf] + [fac])
       cte_formatos_doc
AS     (SELECT   adf.adf_ado_codigo,
                 STRING_AGG(fac.fac_nombre, N'/') WITHIN GROUP (ORDER BY fac.fac_nombre) AS ado_formato_documental
        FROM     sgspi.activo_documental_formato_archivo AS adf
                 INNER JOIN
                 sgspi.formato_archivo_catalogo AS fac
                 ON fac.fac_codigo = adf.adf_fac_codigo
        GROUP BY adf.adf_ado_codigo)
SELECT ado.ado_codigo,
       aci.aci_codigo,
       aci.aci_codigo_inventario,
       pv.pev_anio AS pev_vigencia,
       trd.ado_codigos_serie_documental_trd,
       trd.ado_codigos_subserie_documental_trd,
       sdo.sdo_nombre_serie,
       sbd.sbd_nombre_subserie,
       aci.aci_nombre_activo AS ado_nombre_activo,
       aci.aci_descripcion_detallada AS ado_descripcion,
       pdoc.ado_procesos_asociados,
       ddoc.ado_dependencias_oficinas,
       tac.tac_nombre AS ado_tipo_activo_documental, -- [AP-08] derivado del tipo de activo del supertipo
       prop.ado_propietarios_activo,
       cust.ado_custodios_activo,
       pdc.pdc_nombre AS ado_periodicidad_generacion,
       sdoc.ado_soporte_registro,
       mdoc.ado_medio_conservacion,
       fdoc.ado_formato_documental,
       idoc.ado_idioma,
       ado.ado_fecha_ingreso_tabla_retencion,
       ado.ado_fecha_ingreso_archivo,
       aci.aci_nivel_confidencialidad AS ado_nivel_confidencialidad,
       aci.aci_valor_confidencialidad AS ado_valor_confidencialidad,
       aci.aci_nivel_integridad AS ado_nivel_integridad,
       aci.aci_valor_integridad AS ado_valor_integridad,
       aci.aci_nivel_disponibilidad AS ado_nivel_disponibilidad,
       aci.aci_valor_disponibilidad AS ado_valor_disponibilidad,
       aci.aci_puntaje_criticidad AS ado_puntaje_criticidad,
       aci.aci_nivel_criticidad AS ado_nivel_criticidad,
       epc.epc_nombre AS ado_estado_publicacion,
       ado.ado_lugar_consulta_ubicacion,
       aci.aci_contiene_datos_personales AS ado_contiene_datos_personales,
       aci.aci_contiene_datos_menores AS ado_contiene_datos_menores,
       aci.aci_categoria_dato_personal AS ado_tipo_dato_personal,
       aci.aci_finalidad_recoleccion_pii AS ado_finalidad_recoleccion_pii,
       aci.aci_existe_autorizacion_pii AS ado_existe_autorizacion_pii,
       cet.cet_descripcion_causal AS ado_objeto_legitimo_excepcion,
       aci.aci_fundamento_constitucional_legal AS ado_fundamento_constitucional_legal,
       ISNULL(aci.aci_fundamento_juridico_excepcion, cet.cet_norma_referencia) AS ado_fundamento_juridico_excepcion,
       aci.aci_alcance_excepcion AS ado_alcance_reserva,
       aci.aci_fecha_clasificacion_reserva AS ado_fecha_clasificacion_reserva,
       aci.aci_es_reserva_indefinida AS ado_es_reserva_indefinida,
       aci.aci_anios_plazo_reserva AS ado_anios_plazo_reserva,
       aci.aci_fecha_vencimiento_reserva AS ado_fecha_vencimiento_reserva,
       CASE WHEN aci.aci_es_reserva_indefinida = 1 THEN N'Indefinida' WHEN aci.aci_anios_plazo_reserva IS NOT NULL THEN CONCAT(aci.aci_anios_plazo_reserva, N' años') ELSE NULL END AS ado_tiempo_clasificacion_reserva,
       aci.aci_es_infraestructura_critica_icc AS ado_es_infraestructura_critica_icc,
       aci.aci_estado_registro AS ado_estado_registro
FROM   sgspi.activo_documental AS ado
       INNER JOIN
       sgspi.activo_informacion AS aci
       ON aci.aci_codigo = ado.ado_codigo -- [AP-10] PK compartida
       INNER JOIN
       sgspi.tipo_activo_catalogo AS tac
       ON tac.tac_codigo = aci.aci_tac_codigo
       INNER JOIN
       sgspi.periodo_vigencia AS pv
       ON pv.pev_codigo = ado.ado_pev_codigo
       INNER JOIN
       sgspi.serie_documental_catalogo AS sdo
       ON sdo.sdo_codigo = ado.ado_sdo_codigo
       INNER JOIN
       sgspi.periodicidad_catalogo AS pdc
       ON pdc.pdc_codigo = ado.ado_pdc_codigo
       INNER JOIN
       sgspi.estado_publicacion_catalogo AS epc
       ON epc.epc_codigo = ado.ado_epc_codigo
       LEFT OUTER JOIN
       sgspi.subserie_documental_catalogo AS sbd
       ON sbd.sbd_sdo_codigo = ado.ado_sdo_codigo
          AND sbd.sbd_codigo = ado.ado_sbd_codigo
       LEFT OUTER JOIN
       sgspi.causal_excepcion_transparencia AS cet
       ON cet.cet_codigo = aci.aci_cet_codigo
       LEFT OUTER JOIN
       cte_trd_agregado AS trd
       ON trd.ado_codigo = ado.ado_codigo
       LEFT OUTER JOIN
       cte_procesos_doc AS pdoc
       ON pdoc.aip_aci_codigo = aci.aci_codigo
       LEFT OUTER JOIN
       cte_dependencias_doc AS ddoc
       ON ddoc.air_aci_codigo = aci.aci_codigo
       LEFT OUTER JOIN
       cte_propietarios_doc AS prop
       ON prop.air_aci_codigo = aci.aci_codigo
       LEFT OUTER JOIN
       cte_custodios_doc AS cust
       ON cust.air_aci_codigo = aci.aci_codigo
       LEFT OUTER JOIN
       cte_soportes_doc AS sdoc
       ON sdoc.ads_ado_codigo = ado.ado_codigo
       LEFT OUTER JOIN
       cte_medios_doc AS mdoc
       ON mdoc.adm_ado_codigo = ado.ado_codigo
       LEFT OUTER JOIN
       cte_idiomas_doc AS idoc
       ON idoc.adi_ado_codigo = ado.ado_codigo
       LEFT OUTER JOIN
       cte_formatos_doc AS fdoc
       ON fdoc.adf_ado_codigo = ado.ado_codigo;


GO
-- 6.6 Vista de Atributos de Controles ISO/IEC 27002:2022 (reemplaza las tablas cps/ccc y las columnas de texto de [crn]) [AP-07]
CREATE OR ALTER VIEW sgspi.vw_controles_atributos_iso27002
AS
SELECT   crn.crn_codigo,
         enc.enc_identificador,
         crn.crn_identificador_control,
         crn.crn_nombre_control,
         STRING_AGG(CASE WHEN aac.aac_tipo_atributo = N'TIPO_CONTROL' THEN aac.aac_valor END, N', ') WITHIN GROUP (ORDER BY aac.aac_valor) AS tipo_control,
         STRING_AGG(CASE WHEN aac.aac_tipo_atributo = N'PROPIEDAD_SEGURIDAD' THEN aac.aac_valor END, N', ') WITHIN GROUP (ORDER BY aac.aac_valor) AS propiedades_seguridad,
         STRING_AGG(CASE WHEN aac.aac_tipo_atributo = N'CONCEPTO_CIBERSEGURIDAD' THEN aac.aac_valor END, N', ') WITHIN GROUP (ORDER BY aac.aac_valor) AS conceptos_ciberseguridad,
         STRING_AGG(CASE WHEN aac.aac_tipo_atributo = N'CAPACIDAD_OPERACIONAL' THEN aac.aac_valor END, N', ') WITHIN GROUP (ORDER BY aac.aac_valor) AS capacidades_operacionales,
         STRING_AGG(CASE WHEN aac.aac_tipo_atributo = N'DOMINIO_SEGURIDAD' THEN aac.aac_valor END, N', ') WITHIN GROUP (ORDER BY aac.aac_valor) AS dominios_seguridad
FROM     sgspi.control_referencia_normativa AS crn
         INNER JOIN
         sgspi.estandar_normativo_catalogo AS enc
         ON enc.enc_codigo = crn.crn_enc_codigo
         LEFT OUTER JOIN
         sgspi.control_referencia_normativa_atributo AS cra
         ON cra.cra_crn_codigo = crn.crn_codigo
         LEFT OUTER JOIN
         sgspi.atributo_control_catalogo AS aac
         ON aac.aac_codigo = cra.cra_aac_codigo
GROUP BY crn.crn_codigo,
         enc.enc_identificador,
         crn.crn_identificador_control,
         crn.crn_nombre_control;


GO
SET NOEXEC OFF;
GO
