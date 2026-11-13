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
                   - Llave foránea simple: [<acr_local>_<acr_remoto>_codigo] (ej. [pev_codigo])
                   - Llave foránea con rol: [<acr_local>_<acr_remoto>_codigo_<rol>] (ej. [aci_codigo_primario])
                3. Toda restricción tiene nombre explícito: PK_, FK_, UQ_/UX_, CK_ y DF_<columna>.

  MAPA DE ACRÓNIMOS DE TABLAS DEL ESQUEMA [sgspi] (52 TABLAS):
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
  ELIMINADAS: [cps] control_propiedad_seguridad y [ccc] control_concepto_ciberseguridad (absorbidas por [aac]/[cra]);
              [bas] bitacora_auditoria_sistema y las tablas *_historial (auditoría retirada, ver AP-01).

  ACRÓNIMOS REUTILIZADOS DEL ESQUEMA CORPORATIVO [dbo]:
  - [sus] : dbo.sub_sede ([sus_codigo])             - [car] : dbo.cargo ([car_codigo])
  - [esp] : dbo.espacio ([esp_codigo])              - [per] : dbo.persona ([per_codigo])
  - [uaa] : dbo.uaa ([uaa_codigo])                  - [gru] : dbo.grupo ([gru_codigo])
                                                    - [usg] : dbo.usuario_grupo ([usg_codigo])

  REGISTRO DE CAMBIOS v2.0 (cada cambio está marcado en el código con -- [AP-xx]):
  AP-01  RETIRADO. La bitácora [bas] con cadena de hash, sus triggers y usp_verificar_cadena_bitacora se
         eliminaron junto con las tablas temporales (SYSTEM_VERSIONING) de ado, eia y eac. El script no
         registra quién cambió qué: solo conserva <acr>_fecha_creacion y <acr>_fecha_actualizacion.
  AP-02  Rol sgspi_rol_aplicacion con SELECT/INSERT/UPDATE sobre el esquema y DENY ALTER (ALTER es lo que
         habilita TRUNCATE y DISABLE TRIGGER). sgspi_rol_administrador se crea sin permisos (reservado).
  AP-03  RETIRADO. Ya no se exige contexto de sesión: creador, aprobador y firmantes son los per_codigo que
         envía la aplicación, y la base de datos no puede verificar quién ejecuta la operación.
  AP-04  Todo registro nace en el estado inicial de su flujo (BORRADOR/PENDIENTE); rpi y aci ya no nacen
         VIGENTE (error 50014). Carga histórica: un administrador (dbo) deshabilita temporalmente el trigger
         TR_<acr>_integridad_y_actualizacion de la tabla; ya no existe usp_habilitar_carga_inicial.
  AP-05  Máquina de estados dirigida por datos: [efc] estados y [tef] transiciones reemplazan 5 CHECK de
         listas y 5 bloques de transiciones copiados en los triggers. La aplican los triggers
         TR_<acr>_integridad_y_actualizacion de acf, rpi, aci, eia y act (error 50011).
         [tef_accion_bitacora] quedó sin uso al retirarse la bitácora.
  AP-06  Integridad declarativa entre tablas: estrategia/naturaleza del evento, causal/nivel de reserva,
         nivel del padre en la taxonomía, componente afectado = categoría ISO 27005, serie con subseries.
  AP-07  Atributos ISO/IEC 27002:2022 normalizados ([aac]/[cra]) en vez de texto multivaluado.
  AP-08  Enumeraciones libres reemplazadas por catálogo o CHECK ([fac]/[adf], tac_codigo_componente,
         sif_modalidad_desarrollo); se elimina ado_tipo_activo_documental (redundante con tac_codigo).
  AP-09  Sin dependencias transitivas ni datos derivados sueltos: [zrc], mvr_codigo_posicion calculada,
         letra de probabilidad coherente, avance de actividad sincronizado desde [sga], UAA líder única.
  AP-10  [ado] usa PK compartida con [aci] (ado_codigo = aci_codigo).
  AP-11  *_fecha_actualizacion ya no es una columna muerta: la mantiene el trigger
         TR_<acr>_integridad_y_actualizacion en acf, rpi, aci, ado, eia, plt, act y eac (ado, eia y eac la
         recuperan al retirarse las tablas temporales).
  AP-12  Marcas de fecha en DATETIMEOFFSET(0) (zona horaria explícita).
  AP-13  Valores normalizados (PUBLICA, NO_CLASIFICADA, ...) y vistas filtradas por enc_familia_norma.
  AP-14  Claves naturales con UNIQUE (pri, cet, msi, act).
  AP-15  Segregación de funciones: aprobador/firmantes distintos del creador; aprobador obligatorio en
         estados aprobados; rpi gana creador y aprobador.
  AP-16  Coherencia de eficacia del plan, KPI sin desborde, evidencia con formato y seguimiento append-only.
  AP-17  Todos los DEFAULT con nombre DF_<columna>.
  AP-18  Índices redundantes eliminados, INCLUDE de claves clustered retirados, índice para FK compuesta.
  AP-19  Verificación previa: el script se detiene sin cambios si [sgspi] ya tiene tablas o faltan
         dependencias de [dbo]. El despliegue corre en una sola transacción (todo o nada).
  AP-20  GROUPING() en lugar de ISNULL para rotular subtotales.
  AP-21  RETIRADO (funciones de contexto de auditoría y de hash, eliminadas con AP-01 y AP-03).
==================================================================================================*/
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;
SET XACT_ABORT ON;


GO
/*==================================================================================================
  0. VERIFICACIÓN PREVIA DE DESPLIEGUE [AP-19]
     Si la verificación falla, SET NOEXEC ON hace que el resto del script se compile pero NO se ejecute.
     Si pasa, todo el despliegue corre en UNA transacción: ante un error, XACT_ABORT la revierte y la guarda
     "IF @@TRANCOUNT = 0 SET NOEXEC ON" que abre cada lote impide que los lotes siguientes se ejecuten sueltos,
     de modo que nunca queda un despliegue a medias. El script termina con COMMIT y SET NOEXEC OFF.
     La transacción retiene bloqueos de esquema sobre las tablas de [dbo] referenciadas hasta el COMMIT:
     desplegar en ventana de baja carga.
     shortcut: un error de sintaxis en un lote no revierte la transacción, ejecutar con "sqlcmd -b" si se edita el script.
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
BEGIN TRANSACTION; -- [AP-19] No se ejecuta si la verificación previa activó NOEXEC

IF NOT EXISTS (SELECT 1
               FROM   sys.schemas
               WHERE  name = N'sgspi')
    BEGIN
        EXECUTE (N'CREATE SCHEMA sgspi AUTHORIZATION dbo;');
    END


GO
IF @@TRANCOUNT = 0 SET NOEXEC ON; -- [AP-19]
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
    efc_dominio               NVARCHAR (10) NOT NULL,
    efc_identificador_origen  NVARCHAR (30) NOT NULL,
    efc_identificador_destino NVARCHAR (30) NOT NULL,
    tef_accion_bitacora           NVARCHAR (30) CONSTRAINT DF_tef_accion_bitacora DEFAULT N'TRANSICION_ESTADO' NOT NULL,
    CONSTRAINT PK_tef_transicion_estado_flujo PRIMARY KEY CLUSTERED (tef_codigo),
    CONSTRAINT UQ_tef_dominio_origen_destino UNIQUE (efc_dominio, efc_identificador_origen, efc_identificador_destino),
    CONSTRAINT FK_tef_estado_origen FOREIGN KEY (efc_dominio, efc_identificador_origen) REFERENCES sgspi.estado_flujo_catalogo (efc_dominio, efc_identificador),
    CONSTRAINT FK_tef_estado_destino FOREIGN KEY (efc_dominio, efc_identificador_destino) REFERENCES sgspi.estado_flujo_catalogo (efc_dominio, efc_identificador),
    CONSTRAINT CK_tef_origen_distinto_destino CHECK (efc_identificador_origen <> efc_identificador_destino),
    CONSTRAINT CK_tef_accion_bitacora CHECK (tef_accion_bitacora IN (N'TRANSICION_ESTADO', N'APROBAR', N'OBSERVAR'))
);

CREATE NONCLUSTERED INDEX IX_tef_estado_destino
    ON sgspi.transicion_estado_flujo (efc_dominio, efc_identificador_destino);

-- Semilla de estados y transiciones de todos los dominios de flujo
GO
IF @@TRANCOUNT = 0 SET NOEXEC ON; -- [AP-19]
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
INSERT INTO sgspi.transicion_estado_flujo (efc_dominio, efc_identificador_origen, efc_identificador_destino, tef_accion_bitacora)
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
IF @@TRANCOUNT = 0 SET NOEXEC ON; -- [AP-19]
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
    pev_codigo             SMALLINT       NOT NULL, -- FK a [sgspi].[periodo_vigencia]([pev_codigo])
    dfc_codigo             SMALLINT       NOT NULL, -- FK a [sgspi].[dominio_formato_catalogo]([dfc_codigo])
    fdv_codigo_formato         NVARCHAR (20)  NOT NULL, -- 'ES-GSPI-MR-01', 'ES-GSPI-MR-03', 'ES-GSPI-MR-04', 'ES-GSPI-MR-05', 'ES-GSPI-MR-06'
    fdv_numero_version         NVARCHAR (10)  NOT NULL, -- '02', '04', '01', '01', '02'
    fdv_nombre_oficial_formato NVARCHAR (200) NOT NULL,
    fdv_fecha_emision_formato  DATE           NULL,
    fdv_es_version_activa      BIT            CONSTRAINT DF_fdv_es_version_activa DEFAULT 1 NOT NULL, -- [AP-17]
    CONSTRAINT PK_fdv_formato_documental_version PRIMARY KEY CLUSTERED (fdv_codigo),
    CONSTRAINT UQ_fdv_vigencia_dominio UNIQUE (pev_codigo, dfc_codigo),
    CONSTRAINT FK_fdv_periodo_vigencia FOREIGN KEY (pev_codigo) REFERENCES sgspi.periodo_vigencia (pev_codigo),
    CONSTRAINT FK_fdv_dominio_formato FOREIGN KEY (dfc_codigo) REFERENCES sgspi.dominio_formato_catalogo (dfc_codigo),
    CONSTRAINT CK_fdv_codigo_formato_no_vacio CHECK (LEN(TRIM(fdv_codigo_formato)) > 0) -- [AP-14] Código de formato no vacío
);

CREATE NONCLUSTERED INDEX IX_fdv_dfc_codigo
    ON sgspi.formato_documental_version (dfc_codigo);

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
    tpr_codigo       TINYINT        NOT NULL, -- FK a [sgspi].[tipo_proceso_catalogo]([tpr_codigo])
    uaa_codigo_lider INT            NULL, -- FK a [dbo].[uaa]([uaa_codigo])
    car_codigo_lider INT            NULL, -- FK a [dbo].[cargo]([car_codigo])
    pri_esta_activo      BIT            CONSTRAINT DF_pri_esta_activo DEFAULT 1 NOT NULL, -- [AP-17]
    CONSTRAINT PK_pri_proceso_institucional PRIMARY KEY CLUSTERED (pri_codigo),
    CONSTRAINT UQ_pri_identificador UNIQUE (pri_identificador), -- [AP-14] Clave natural con UNIQUE
    CONSTRAINT UQ_pri_nombre UNIQUE (pri_nombre),
    CONSTRAINT FK_pri_tipo_proceso FOREIGN KEY (tpr_codigo) REFERENCES sgspi.tipo_proceso_catalogo (tpr_codigo),
    CONSTRAINT FK_pri_dbo_uaa_lider FOREIGN KEY (uaa_codigo_lider) REFERENCES dbo.uaa (uaa_codigo),
    CONSTRAINT FK_pri_dbo_cargo_lider FOREIGN KEY (car_codigo_lider) REFERENCES dbo.cargo (car_codigo),
    CONSTRAINT CK_pri_identificador_no_vacio CHECK (LEN(TRIM(pri_identificador)) > 0) -- [AP-14]
);

CREATE NONCLUSTERED INDEX IX_pri_tpr_codigo
    ON sgspi.proceso_institucional (tpr_codigo);
CREATE NONCLUSTERED INDEX IX_pri_uaa_codigo_lider
    ON sgspi.proceso_institucional (uaa_codigo_lider);
CREATE NONCLUSTERED INDEX IX_pri_car_codigo_lider
    ON sgspi.proceso_institucional (car_codigo_lider);

-- 1.5 [piu] Tabla Puente N:M Proceso Institucional <-> Unidades Académico-Administrativas ([dbo].[uaa])
-- [AP-09] Se elimina piu_es_responsable_principal: la UAA líder del proceso es [uaa_codigo_lider] (una sola fuente de verdad)
CREATE TABLE sgspi.proceso_institucional_uaa (
    pri_codigo INT NOT NULL, -- FK a [sgspi].[proceso_institucional]([pri_codigo])
    uaa_codigo INT NOT NULL, -- FK a [dbo].[uaa]([uaa_codigo])
    CONSTRAINT PK_piu_proceso_institucional_uaa PRIMARY KEY CLUSTERED (pri_codigo, uaa_codigo),
    CONSTRAINT FK_piu_proceso_institucional FOREIGN KEY (pri_codigo) REFERENCES sgspi.proceso_institucional (pri_codigo) ON DELETE CASCADE,
    CONSTRAINT FK_piu_dbo_uaa FOREIGN KEY (uaa_codigo) REFERENCES dbo.uaa (uaa_codigo)
);

CREATE NONCLUSTERED INDEX IX_piu_uaa_codigo
    ON sgspi.proceso_institucional_uaa (uaa_codigo); -- [AP-09] Sin INCLUDE de la columna eliminada


GO
IF @@TRANCOUNT = 0 SET NOEXEC ON; -- [AP-19]
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
    pev_codigo              SMALLINT        NOT NULL, -- FK a [sgspi].[periodo_vigencia]([pev_codigo])
    pri_codigo              INT             NOT NULL, -- FK a [sgspi].[proceso_institucional]([pri_codigo])
    fec_codigo              SMALLINT        NOT NULL, -- FK a [sgspi].[factor_entorno_catalogo]([fec_codigo])
    acf_naturaleza_factor       NVARCHAR (15)   NOT NULL, -- 'DEBILIDAD', 'FORTALEZA', 'AMENAZA', 'OPORTUNIDAD'
    acf_numero_factor           SMALLINT        NOT NULL, -- Consecutivo inmutable por vigencia y naturaleza (1..n)
    acf_identificador_factor    AS              (CONVERT (NVARCHAR (15), CONCAT(LEFT(acf_naturaleza_factor, 1), acf_numero_factor))) PERSISTED, -- Identificador documental estable ('D1'..'Dn', 'F1'..'Fn', 'A1'..'An', 'O1'..'On')
    acf_descripcion_situacion   NVARCHAR (1000) NOT NULL,
    acf_valor_prioridad         TINYINT         CONSTRAINT DF_acf_valor_prioridad DEFAULT 1 NOT NULL, -- Escala ordinal unificada: 1=BAJA, 2=MEDIA, 3=ALTA
    acf_nivel_prioridad         AS              (CASE acf_valor_prioridad WHEN 3 THEN N'ALTA' WHEN 2 THEN N'MEDIA' ELSE N'BAJA' END) PERSISTED,
    acf_impacto_sistema_gestion NVARCHAR (1000) NULL,
    acf_accion_propuesta        NVARCHAR (1000) NULL,
    acf_estado_registro         NVARCHAR (30)   CONSTRAINT DF_acf_estado_registro DEFAULT N'BORRADOR' NOT NULL, -- [AP-17]
    efc_dominio             AS              (CONVERT (NVARCHAR (10), N'ACF')) PERSISTED, -- [AP-05] Dominio constante para la FK al catálogo de estados
    per_codigo_creador      INT             NOT NULL, -- FK a [dbo].[persona]([per_codigo])
    per_codigo_aprobador    INT             NULL, -- FK a [dbo].[persona]([per_codigo])
    acf_fecha_creacion          DATETIMEOFFSET (0) CONSTRAINT DF_acf_fecha_creacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17]
    acf_fecha_actualizacion     DATETIMEOFFSET (0) CONSTRAINT DF_acf_fecha_actualizacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17]
    CONSTRAINT PK_acf_analisis_contexto_factor PRIMARY KEY CLUSTERED (acf_codigo),
    CONSTRAINT FK_acf_periodo_vigencia FOREIGN KEY (pev_codigo) REFERENCES sgspi.periodo_vigencia (pev_codigo),
    CONSTRAINT FK_acf_proceso_institucional FOREIGN KEY (pri_codigo) REFERENCES sgspi.proceso_institucional (pri_codigo),
    CONSTRAINT FK_acf_factor_entorno FOREIGN KEY (fec_codigo) REFERENCES sgspi.factor_entorno_catalogo (fec_codigo),
    CONSTRAINT FK_acf_dbo_persona_creador FOREIGN KEY (per_codigo_creador) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT FK_acf_dbo_persona_aprobador FOREIGN KEY (per_codigo_aprobador) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT FK_acf_estado_flujo FOREIGN KEY (efc_dominio, acf_estado_registro) REFERENCES sgspi.estado_flujo_catalogo (efc_dominio, efc_identificador), -- [AP-05]
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
    CONSTRAINT CK_acf_sod_aprobador CHECK (per_codigo_aprobador IS NULL
                                           OR per_codigo_aprobador <> per_codigo_creador),
    CONSTRAINT CK_acf_aprobador_requerido CHECK (acf_estado_registro NOT IN (N'VIGENTE', N'HISTORICO')
                                                 OR per_codigo_aprobador IS NOT NULL)
);

-- [AP-18] Reemplaza la UNIQUE constraint y el índice IX_acf_pev_codigo (prefijo duplicado) por un único índice único con INCLUDE
CREATE UNIQUE NONCLUSTERED INDEX UQ_acf_vigencia_naturaleza_numero
    ON sgspi.analisis_contexto_factor (pev_codigo, acf_naturaleza_factor, acf_numero_factor)
    INCLUDE (acf_identificador_factor, pri_codigo, fec_codigo);
CREATE NONCLUSTERED INDEX IX_acf_pri_codigo
    ON sgspi.analisis_contexto_factor (pri_codigo);
CREATE NONCLUSTERED INDEX IX_acf_fec_codigo
    ON sgspi.analisis_contexto_factor (fec_codigo);
CREATE NONCLUSTERED INDEX IX_acf_per_codigo_creador
    ON sgspi.analisis_contexto_factor (per_codigo_creador);
CREATE NONCLUSTERED INDEX IX_acf_per_codigo_aprobador
    ON sgspi.analisis_contexto_factor (per_codigo_aprobador);


GO
IF @@TRANCOUNT = 0 SET NOEXEC ON; -- [AP-19]
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
    pev_codigo             SMALLINT        NOT NULL, -- FK a [sgspi].[periodo_vigencia]([pev_codigo])
    pai_codigo             INT             NOT NULL, -- FK a [sgspi].[parte_interesada]([pai_codigo])
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
    efc_dominio            AS              (CONVERT (NVARCHAR (10), N'RPI')) PERSISTED, -- [AP-05] Dominio constante para la FK al catálogo de estados
    per_codigo_creador     INT             NOT NULL, -- [AP-15] FK a [dbo].[persona]([per_codigo])
    per_codigo_aprobador   INT             NULL, -- [AP-15] FK a [dbo].[persona]([per_codigo])
    rpi_fecha_creacion         DATETIMEOFFSET (0) CONSTRAINT DF_rpi_fecha_creacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17]
    rpi_fecha_actualizacion    DATETIMEOFFSET (0) CONSTRAINT DF_rpi_fecha_actualizacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17]
    CONSTRAINT PK_rpi_requisito_parte_interesada PRIMARY KEY CLUSTERED (rpi_codigo),
    CONSTRAINT FK_rpi_periodo_vigencia FOREIGN KEY (pev_codigo) REFERENCES sgspi.periodo_vigencia (pev_codigo),
    CONSTRAINT FK_rpi_parte_interesada FOREIGN KEY (pai_codigo) REFERENCES sgspi.parte_interesada (pai_codigo),
    CONSTRAINT FK_rpi_dbo_persona_creador FOREIGN KEY (per_codigo_creador) REFERENCES dbo.persona (per_codigo), -- [AP-15]
    CONSTRAINT FK_rpi_dbo_persona_aprobador FOREIGN KEY (per_codigo_aprobador) REFERENCES dbo.persona (per_codigo), -- [AP-15]
    CONSTRAINT FK_rpi_estado_flujo FOREIGN KEY (efc_dominio, rpi_estado_registro) REFERENCES sgspi.estado_flujo_catalogo (efc_dominio, efc_identificador), -- [AP-05]
    CONSTRAINT CK_rpi_valores_escala CHECK (rpi_valor_poder IN (1, 2, 3)
                                            AND rpi_valor_interes IN (1, 2, 3)
                                            AND (rpi_valor_cumplimiento IS NULL
                                                 OR rpi_valor_cumplimiento IN (1, 2, 3))),
    -- [AP-05] Se elimina CK_rpi_estado_registro (lista de estados): ahora lo garantiza FK_rpi_estado_flujo
    -- [AP-15] Segregación de funciones: el aprobador no puede ser el creador, y VIGENTE/HISTORICO exigen aprobador
    CONSTRAINT CK_rpi_sod_aprobador CHECK (per_codigo_aprobador IS NULL
                                           OR per_codigo_aprobador <> per_codigo_creador),
    CONSTRAINT CK_rpi_aprobador_requerido CHECK (rpi_estado_registro NOT IN (N'VIGENTE', N'HISTORICO')
                                                 OR per_codigo_aprobador IS NOT NULL)
);

CREATE NONCLUSTERED INDEX IX_rpi_pev_codigo
    ON sgspi.requisito_parte_interesada (pev_codigo);
CREATE NONCLUSTERED INDEX IX_rpi_pai_codigo
    ON sgspi.requisito_parte_interesada (pai_codigo);
CREATE NONCLUSTERED INDEX IX_rpi_per_codigo_creador -- [AP-15] [AP-18] Índice para la FK
    ON sgspi.requisito_parte_interesada (per_codigo_creador);
CREATE NONCLUSTERED INDEX IX_rpi_per_codigo_aprobador -- [AP-15] [AP-18] Índice para la FK
    ON sgspi.requisito_parte_interesada (per_codigo_aprobador);

-- 3.3 [rpc] Referencias Atómicas a Preguntas del Cuestionario por Requisito (Elimina listas multivaluadas como '6-7-8')
CREATE TABLE sgspi.requisito_parte_interesada_cuestionario (
    rpi_codigo      INT      NOT NULL, -- FK a [sgspi].[requisito_parte_interesada]([rpi_codigo])
    rpc_numero_pregunta SMALLINT NOT NULL, -- Número atómico de pregunta del cuestionario (ej. 6, 7, 8)
    CONSTRAINT PK_rpc_requisito_parte_interesada_cuestionario PRIMARY KEY CLUSTERED (rpi_codigo, rpc_numero_pregunta),
    CONSTRAINT FK_rpc_requisito_parte_interesada FOREIGN KEY (rpi_codigo) REFERENCES sgspi.requisito_parte_interesada (rpi_codigo),
    CONSTRAINT CK_rpc_numero_pregunta_positivo CHECK (rpc_numero_pregunta >= 1)
);

CREATE NONCLUSTERED INDEX IX_rpc_numero_pregunta
    ON sgspi.requisito_parte_interesada_cuestionario (rpc_numero_pregunta); -- [AP-18] Sin INCLUDE: rpi_codigo ya es parte de la clave clustered

-- 3.4 [rpp] Relación N:M Requisito de Parte Interesada <-> Proceso Institucional
CREATE TABLE sgspi.requisito_parte_interesada_proceso_institucional (
    rpi_codigo     INT           NOT NULL, -- FK a [sgspi].[requisito_parte_interesada]([rpi_codigo])
    pri_codigo     INT           NOT NULL, -- FK a [sgspi].[proceso_institucional]([pri_codigo])
    rpp_fecha_registro DATETIMEOFFSET (0) CONSTRAINT DF_rpp_fecha_registro DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17]
    CONSTRAINT PK_rpp_requisito_parte_interesada_proceso_institucional PRIMARY KEY CLUSTERED (rpi_codigo, pri_codigo),
    CONSTRAINT FK_rpp_requisito_parte_interesada FOREIGN KEY (rpi_codigo) REFERENCES sgspi.requisito_parte_interesada (rpi_codigo),
    CONSTRAINT FK_rpp_proceso_institucional FOREIGN KEY (pri_codigo) REFERENCES sgspi.proceso_institucional (pri_codigo)
);

CREATE NONCLUSTERED INDEX IX_rpp_pri_codigo
    ON sgspi.requisito_parte_interesada_proceso_institucional (pri_codigo);


GO
IF @@TRANCOUNT = 0 SET NOEXEC ON; -- [AP-19]
GO
/*==================================================================================================
  4. DOMINIO DE INVENTARIO Y CLASIFICACIÓN DE ACTIVOS (DOCUMENTO 4: ES-GSPI-MR-05)
     Articulado con [dbo].[uaa], [dbo].[sede], [dbo].[sub_sede], [dbo].[espacio], [dbo].[cargo] y [dbo].[persona]
==================================================================================================*/
-- 4.1 [tac] Catálogo Extensible de Taxonomía Jerárquica Autorreferenciada de Activos ISO/IEC 27005 (1=Categoría -> 2=Tipo -> 3=Subtipo)
CREATE TABLE sgspi.tipo_activo_catalogo (
    tac_codigo           SMALLINT       IDENTITY (1, 1) NOT NULL,
    tac_codigo_padre SMALLINT       NULL, -- Código del nodo padre inmediato (NULL en las categorías de nivel 1; el padre de un Tipo es una Categoría y el de un Subtipo es un Tipo) [AP-06]
    tac_nivel_taxonomia  TINYINT        NOT NULL, -- 1=Categoría ISO 27005, 2=Tipo, 3=Subtipo
    tac_nivel_taxonomia_padre AS        (CONVERT (TINYINT, tac_nivel_taxonomia - 1)) PERSISTED, -- [AP-06] Nivel que debe tener el padre (exactamente un nivel arriba); soporta la FK compuesta FK_tac_padre
    tac_nombre           NVARCHAR (120) NOT NULL,
    tac_ejemplos_ref     NVARCHAR (255) NULL,
    tac_esta_activo      BIT            CONSTRAINT DF_tac_esta_activo DEFAULT 1 NOT NULL, -- [AP-17]
    CONSTRAINT PK_tac_tipo_activo_catalogo PRIMARY KEY CLUSTERED (tac_codigo),
    CONSTRAINT UQ_tac_codigo_nivel UNIQUE (tac_codigo, tac_nivel_taxonomia), -- [AP-06] Destino de FK compuestas (FK_tac_padre y eia)
    CONSTRAINT FK_tac_padre FOREIGN KEY (tac_codigo_padre, tac_nivel_taxonomia_padre) REFERENCES sgspi.tipo_activo_catalogo (tac_codigo, tac_nivel_taxonomia), -- [AP-06] El padre está exactamente un nivel arriba
    CONSTRAINT UQ_tac_padre_nombre UNIQUE (tac_codigo_padre, tac_nombre),
    CONSTRAINT CK_tac_nivel_coherente CHECK ((tac_nivel_taxonomia = 1
                                              AND tac_codigo_padre IS NULL)
                                             OR (tac_nivel_taxonomia IN (2, 3)
                                                 AND tac_codigo_padre IS NOT NULL
                                                 AND tac_codigo_padre <> tac_codigo)),
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
    tac_codigo                      SMALLINT        NOT NULL, -- FK a [sgspi].[tipo_activo_catalogo]([tac_codigo])
    uaa_codigo                      INT             NULL, -- FK a [dbo].[uaa]([uaa_codigo])
    esp_codigo                      INT             NULL, -- FK a [dbo].[espacio]([esp_codigo])
    aci_es_transversal_sedes            BIT             CONSTRAINT DF_aci_es_transversal_sedes DEFAULT 0 NOT NULL, -- [AP-17]
    aci_cantidad_unidades               INT             CONSTRAINT DF_aci_cantidad_unidades DEFAULT 1 NOT NULL, -- [AP-17]
    -- Clasificación de Transparencia e Índice de Información Clasificada y Reservada (Ley 1712 de 2014 / Decreto 103 de 2015)
    aci_clasificacion_transparencia     NVARCHAR (20)   NOT NULL, -- [AP-13] 'PUBLICA', 'CLASIFICADA', 'RESERVADA', 'NO_CLASIFICADA'
    cet_codigo                      SMALLINT        NULL, -- FK a [sgspi].[causal_excepcion_transparencia]([cet_codigo]) (NULL cuando es PUBLICA o NO_CLASIFICADA)
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
    efc_dominio                    AS             (CONVERT (NVARCHAR (10), N'ACI')) PERSISTED, -- [AP-05] Dominio constante para la FK compuesta hacia el catálogo de estados
    aci_estado_registro                NVARCHAR (30)  CONSTRAINT DF_aci_estado_registro DEFAULT N'BORRADOR' NOT NULL, -- [AP-04] El INSERT solo puede iniciar en el estado inicial del flujo
    per_codigo_creador             INT            NOT NULL, -- FK a [dbo].[persona]([per_codigo])
    per_codigo_aprobador           INT            NULL, -- FK a [dbo].[persona]([per_codigo])
    aci_fecha_creacion                 DATETIMEOFFSET (0) CONSTRAINT DF_aci_fecha_creacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12]
    aci_fecha_actualizacion            DATETIMEOFFSET (0) CONSTRAINT DF_aci_fecha_actualizacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12]
    CONSTRAINT PK_aci_activo_informacion PRIMARY KEY CLUSTERED (aci_codigo),
    CONSTRAINT UQ_aci_codigo_inventario UNIQUE (aci_codigo_inventario),
    CONSTRAINT FK_aci_tipo_activo FOREIGN KEY (tac_codigo) REFERENCES sgspi.tipo_activo_catalogo (tac_codigo),
    CONSTRAINT FK_aci_dbo_uaa FOREIGN KEY (uaa_codigo) REFERENCES dbo.uaa (uaa_codigo),
    CONSTRAINT FK_aci_dbo_espacio FOREIGN KEY (esp_codigo) REFERENCES dbo.espacio (esp_codigo),
    CONSTRAINT FK_aci_causal_excepcion FOREIGN KEY (cet_codigo, aci_clasificacion_transparencia) REFERENCES sgspi.causal_excepcion_transparencia (cet_codigo, cet_nivel_reserva_aplicable), -- [AP-06] La causal debe corresponder al nivel de reserva del activo (no se evalúa con cet_codigo NULL)
    CONSTRAINT FK_aci_estado_flujo FOREIGN KEY (efc_dominio, aci_estado_registro) REFERENCES sgspi.estado_flujo_catalogo (efc_dominio, efc_identificador), -- [AP-05]
    CONSTRAINT FK_aci_dbo_persona_creador FOREIGN KEY (per_codigo_creador) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT FK_aci_dbo_persona_aprobador FOREIGN KEY (per_codigo_aprobador) REFERENCES dbo.persona (per_codigo),
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
                                                           AND cet_codigo IS NOT NULL
                                                           AND aci_alcance_excepcion IS NOT NULL
                                                           AND aci_fecha_clasificacion_reserva IS NOT NULL
                                                           AND ((aci_es_reserva_indefinida = 1
                                                                 AND aci_anios_plazo_reserva IS NULL)
                                                                OR (aci_es_reserva_indefinida = 0
                                                                    AND aci_anios_plazo_reserva IS NOT NULL)))
                                                       OR (aci_clasificacion_transparencia IN (N'PUBLICA', N'NO_CLASIFICADA') -- [AP-13]
                                                           AND cet_codigo IS NULL
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
    CONSTRAINT CK_aci_sod_aprobador CHECK (per_codigo_aprobador IS NULL
                                           OR per_codigo_aprobador <> per_codigo_creador),
    -- [AP-15] Un activo vigente, inactivo o histórico debe tener aprobador
    CONSTRAINT CK_aci_aprobador_requerido CHECK (aci_estado_registro NOT IN (N'VIGENTE', N'INACTIVO', N'HISTORICO')
                                                 OR per_codigo_aprobador IS NOT NULL)
);

CREATE NONCLUSTERED INDEX IX_aci_tac_codigo
    ON sgspi.activo_informacion (tac_codigo)
    INCLUDE (aci_estado_registro, aci_nivel_criticidad);
CREATE NONCLUSTERED INDEX IX_aci_uaa_codigo
    ON sgspi.activo_informacion (uaa_codigo);
CREATE NONCLUSTERED INDEX IX_aci_esp_codigo
    ON sgspi.activo_informacion (esp_codigo);
CREATE NONCLUSTERED INDEX IX_aci_cet_codigo
    ON sgspi.activo_informacion (cet_codigo);
CREATE NONCLUSTERED INDEX IX_aci_per_codigo_creador
    ON sgspi.activo_informacion (per_codigo_creador);
CREATE NONCLUSTERED INDEX IX_aci_per_codigo_aprobador
    ON sgspi.activo_informacion (per_codigo_aprobador);

-- 4.4 [aip], [ais], [air] Tablas Asociativas N:M Unificadas de Activos de Información (Compartidas por el Supertipo y todos sus Subtipos)
CREATE TABLE sgspi.activo_informacion_proceso_institucional (
    aci_codigo INT NOT NULL, -- FK a [sgspi].[activo_informacion]([aci_codigo])
    pri_codigo INT NOT NULL, -- FK a [sgspi].[proceso_institucional]([pri_codigo])
    CONSTRAINT PK_aip_activo_informacion_proceso_institucional PRIMARY KEY CLUSTERED (aci_codigo, pri_codigo),
    CONSTRAINT FK_aip_activo_informacion FOREIGN KEY (aci_codigo) REFERENCES sgspi.activo_informacion (aci_codigo),
    CONSTRAINT FK_aip_proceso_institucional FOREIGN KEY (pri_codigo) REFERENCES sgspi.proceso_institucional (pri_codigo)
);

CREATE NONCLUSTERED INDEX IX_aip_pri_codigo
    ON sgspi.activo_informacion_proceso_institucional (pri_codigo);

CREATE TABLE sgspi.activo_informacion_sede (
    aci_codigo INT NOT NULL, -- FK a [sgspi].[activo_informacion]([aci_codigo])
    sus_codigo INT NOT NULL, -- FK a [dbo].[sub_sede]([sus_codigo]) (contiene [sed_codigo] hacia [dbo].[sede])
    CONSTRAINT PK_ais_activo_informacion_sede PRIMARY KEY CLUSTERED (aci_codigo, sus_codigo),
    CONSTRAINT FK_ais_activo_informacion FOREIGN KEY (aci_codigo) REFERENCES sgspi.activo_informacion (aci_codigo),
    CONSTRAINT FK_ais_dbo_sub_sede FOREIGN KEY (sus_codigo) REFERENCES dbo.sub_sede (sus_codigo)
);

CREATE NONCLUSTERED INDEX IX_ais_sus_codigo
    ON sgspi.activo_informacion_sede (sus_codigo);

CREATE TABLE sgspi.activo_informacion_responsable (
    aci_codigo           INT           NOT NULL, -- FK a [sgspi].[activo_informacion]([aci_codigo])
    car_codigo           INT           NOT NULL, -- FK a [dbo].[cargo]([car_codigo]): Cargo institucional responsable (ISO 27001 / Ley 594)
    uaa_codigo           INT           NOT NULL, -- FK a [dbo].[uaa]([uaa_codigo]): Dependencia del cargo
    air_tipo_responsabilidad NVARCHAR (20) NOT NULL, -- 'PROPIETARIO', 'CUSTODIO'
    air_esta_activo          BIT           CONSTRAINT DF_air_esta_activo DEFAULT 1 NOT NULL, -- [AP-17]
    -- Clave primaria compuesta 100% NOT NULL (elimina UNIQUE sobre columnas NULL [uap_codigo]/[uac_codigo] y unifica [air] + [adr])
    CONSTRAINT PK_air_activo_informacion_responsable PRIMARY KEY CLUSTERED (aci_codigo, car_codigo, uaa_codigo, air_tipo_responsabilidad),
    CONSTRAINT FK_air_activo_informacion FOREIGN KEY (aci_codigo) REFERENCES sgspi.activo_informacion (aci_codigo),
    CONSTRAINT FK_air_dbo_cargo FOREIGN KEY (car_codigo) REFERENCES dbo.cargo (car_codigo),
    CONSTRAINT FK_air_dbo_uaa FOREIGN KEY (uaa_codigo) REFERENCES dbo.uaa (uaa_codigo),
    CONSTRAINT CK_air_tipo_responsabilidad CHECK (air_tipo_responsabilidad IN (N'PROPIETARIO', N'CUSTODIO'))
);

CREATE NONCLUSTERED INDEX IX_air_car_codigo
    ON sgspi.activo_informacion_responsable (car_codigo)
    INCLUDE (air_esta_activo); -- [AP-18] aci_codigo y air_tipo_responsabilidad ya son parte de la clave clustered
CREATE NONCLUSTERED INDEX IX_air_uaa_codigo
    ON sgspi.activo_informacion_responsable (uaa_codigo)
    INCLUDE (air_esta_activo); -- [AP-18] aci_codigo ya es parte de la clave clustered

-- 4.5 [sif] y [msi] Ficha Técnica de Sistemas de Información y sus Módulos (Los 17 Sistemas USCO)
CREATE TABLE sgspi.sistema_informacion_ficha (
    sif_codigo               INT             IDENTITY (1, 1) NOT NULL,
    aci_codigo           INT             NULL, -- FK a [sgspi].[activo_informacion]([aci_codigo])
    sif_nombre_sistema       NVARCHAR (150)  NOT NULL,
    sif_modalidad_desarrollo NVARCHAR (50)   NOT NULL, -- [AP-08] 'PROPIO', 'PROPIO_EN_DESARROLLO', 'CODIGO_ABIERTO_ADAPTADO', 'COMERCIAL_TERCERO'
    sif_fabricante_proveedor NVARCHAR (150)  NULL,
    sif_descripcion_general  NVARCHAR (1000) NOT NULL,
    CONSTRAINT PK_sif_sistema_informacion_ficha PRIMARY KEY CLUSTERED (sif_codigo),
    CONSTRAINT UQ_sif_nombre_sistema UNIQUE (sif_nombre_sistema),
    CONSTRAINT FK_sif_activo_informacion FOREIGN KEY (aci_codigo) REFERENCES sgspi.activo_informacion (aci_codigo),
    CONSTRAINT CK_sif_modalidad_desarrollo CHECK (sif_modalidad_desarrollo IN (N'PROPIO', N'PROPIO_EN_DESARROLLO', N'CODIGO_ABIERTO_ADAPTADO', N'COMERCIAL_TERCERO')) -- [AP-08]
);

-- Índice único filtrado (SQL Server 2019) para relación 1:0..1 sobre columna NULL sin bloquear múltiples NULL
CREATE UNIQUE NONCLUSTERED INDEX UQ_sif_aci_codigo
    ON sgspi.sistema_informacion_ficha (aci_codigo)
    WHERE aci_codigo IS NOT NULL;

CREATE TABLE sgspi.modulo_sistema_informacion (
    msi_codigo            INT            IDENTITY (1, 1) NOT NULL,
    sif_codigo        INT            NOT NULL, -- FK a [sgspi].[sistema_informacion_ficha]([sif_codigo])
    msi_nombre_modulo     NVARCHAR (200) NOT NULL,
    msi_usuarios_objetivo NVARCHAR (150) NULL,
    CONSTRAINT PK_msi_modulo_sistema_informacion PRIMARY KEY CLUSTERED (msi_codigo),
    CONSTRAINT UQ_msi_sistema_nombre UNIQUE (sif_codigo, msi_nombre_modulo), -- [AP-14] Clave natural; además cubre las búsquedas por sif_codigo
    CONSTRAINT FK_msi_sistema_informacion FOREIGN KEY (sif_codigo) REFERENCES sgspi.sistema_informacion_ficha (sif_codigo) ON DELETE CASCADE
);

-- [AP-18] Se elimina IX_msi_sif_codigo: redundante con UQ_msi_sistema_nombre (misma columna líder)


GO
IF @@TRANCOUNT = 0 SET NOEXEC ON; -- [AP-19]
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
    sdo_codigo      SMALLINT       NOT NULL, -- FK a [sgspi].[serie_documental_catalogo]([sdo_codigo])
    sbd_numero_ccd      SMALLINT       NOT NULL, -- COD6: Número secuencial de la subserie dentro de la serie
    sbd_nombre_subserie NVARCHAR (200) NOT NULL,
    sbd_esta_activa     BIT            CONSTRAINT DF_sbd_esta_activa DEFAULT 1 NOT NULL, -- [AP-17]
    CONSTRAINT PK_sbd_subserie_documental_catalogo PRIMARY KEY CLUSTERED (sbd_codigo),
    CONSTRAINT UQ_sbd_serie_subserie UNIQUE (sdo_codigo, sbd_codigo),
    CONSTRAINT UQ_sbd_serie_numero UNIQUE (sdo_codigo, sbd_numero_ccd),
    CONSTRAINT UQ_sbd_serie_nombre UNIQUE (sdo_codigo, sbd_nombre_subserie),
    CONSTRAINT FK_sbd_serie_documental FOREIGN KEY (sdo_codigo) REFERENCES sgspi.serie_documental_catalogo (sdo_codigo),
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
    uaa_codigo           INT            NULL, -- FK a [dbo].[uaa]([uaa_codigo]): Equivalencia organizacional en academia3000
    upc_nombre_unidad        NVARCHAR (150) NOT NULL, -- Ej: 'RECTORIA', 'SECRETARIA GENERAL', 'AREA GESTION DOCUMENTAL'
    upc_esta_activa          BIT            CONSTRAINT DF_upc_esta_activa DEFAULT 1 NOT NULL, -- [AP-17]
    CONSTRAINT PK_upc_unidad_productora_cuadro_clasificacion_documental PRIMARY KEY CLUSTERED (upc_codigo),
    CONSTRAINT UQ_upc_nodo_jerarquico UNIQUE (upc_nodo_jerarquico),
    CONSTRAINT UQ_upc_prefijo_archivistico UNIQUE (upc_prefijo_archivistico),
    CONSTRAINT FK_upc_nodo_padre FOREIGN KEY (upc_nodo_padre) REFERENCES sgspi.unidad_productora_cuadro_clasificacion_documental (upc_nodo_jerarquico),
    CONSTRAINT FK_upc_dbo_uaa FOREIGN KEY (uaa_codigo) REFERENCES dbo.uaa (uaa_codigo),
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
    ON sgspi.unidad_productora_cuadro_clasificacion_documental (uaa_codigo);

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

-- 4B.5 [ado] Subtipo 1:1 de Activo Documental (Especialización Archivística de [sgspi].[activo_informacion] para ES-GSPI-MR-04)
-- [AP-10] PK compartida: ado_codigo ES el aci_codigo del supertipo (sin IDENTITY propio ni columna FK separada).
-- [AP-08] El tipo de activo documental se deriva de tac_codigo y el formato se modela en [adf] (4B.6).
CREATE TABLE sgspi.activo_documental (
    ado_codigo                        INT                                         NOT NULL, -- [AP-10] PK compartida = [sgspi].[activo_informacion]([aci_codigo])
    pev_codigo                    SMALLINT                                    NOT NULL, -- FK a [sgspi].[periodo_vigencia]([pev_codigo])
    sdo_codigo                    SMALLINT                                    NOT NULL, -- FK a [sgspi].[serie_documental_catalogo]([sdo_codigo])
    sbd_codigo                    INT                                         NULL, -- FK nullable a [sgspi].[subserie_documental_catalogo]([sbd_codigo]) (NULL si la serie no tiene subserie)
    pdc_codigo                    SMALLINT                                    NOT NULL, -- FK a [sgspi].[periodicidad_catalogo]([pdc_codigo])
    ado_fecha_ingreso_tabla_retencion DATE                                        NULL,
    ado_fecha_ingreso_archivo         DATE                                        NULL,
    epc_codigo                    SMALLINT                                    NOT NULL, -- FK a [sgspi].[estado_publicacion_catalogo]([epc_codigo])
    ado_lugar_consulta_ubicacion      NVARCHAR (255)                              NOT NULL, -- URL portal de transparencia o nombre de dependencia/archivo
    per_codigo_revisor_archivo    INT                                         NULL, -- FK a [dbo].[persona]([per_codigo]): Aval específico Gestión Documental / Secretaría General
    ado_fecha_creacion                DATETIMEOFFSET (0)                          CONSTRAINT DF_ado_fecha_creacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17]
    ado_fecha_actualizacion           DATETIMEOFFSET (0)                          CONSTRAINT DF_ado_fecha_actualizacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-11] La mantiene TR_ado_integridad_y_actualizacion
    CONSTRAINT PK_ado_activo_documental PRIMARY KEY CLUSTERED (ado_codigo),
    CONSTRAINT FK_ado_activo_informacion FOREIGN KEY (ado_codigo) REFERENCES sgspi.activo_informacion (aci_codigo), -- [AP-10] PK compartida (reemplaza UQ_ado_activo_informacion)
    CONSTRAINT FK_ado_periodo_vigencia FOREIGN KEY (pev_codigo) REFERENCES sgspi.periodo_vigencia (pev_codigo),
    CONSTRAINT FK_ado_serie_documental FOREIGN KEY (sdo_codigo) REFERENCES sgspi.serie_documental_catalogo (sdo_codigo),
    CONSTRAINT FK_ado_subserie_documental FOREIGN KEY (sdo_codigo, sbd_codigo) REFERENCES sgspi.subserie_documental_catalogo (sdo_codigo, sbd_codigo),
    CONSTRAINT FK_ado_periodicidad FOREIGN KEY (pdc_codigo) REFERENCES sgspi.periodicidad_catalogo (pdc_codigo),
    CONSTRAINT FK_ado_estado_publicacion FOREIGN KEY (epc_codigo) REFERENCES sgspi.estado_publicacion_catalogo (epc_codigo),
    CONSTRAINT FK_ado_dbo_persona_revisor_archivo FOREIGN KEY (per_codigo_revisor_archivo) REFERENCES dbo.persona (per_codigo)
);

CREATE NONCLUSTERED INDEX IX_ado_pev_codigo
    ON sgspi.activo_documental (pev_codigo, sdo_codigo, sbd_codigo); -- [AP-18] Se quita el INCLUDE de la columna eliminada (ado_codigo ya es clave clustered)
CREATE NONCLUSTERED INDEX IX_ado_sdo_sbd_codigo
    ON sgspi.activo_documental (sdo_codigo, sbd_codigo); -- [AP-18] Reemplaza IX_ado_sbd_codigo: sirve a FK_ado_serie_documental y FK_ado_subserie_documental
CREATE NONCLUSTERED INDEX IX_ado_pdc_codigo
    ON sgspi.activo_documental (pdc_codigo);
CREATE NONCLUSTERED INDEX IX_ado_epc_codigo
    ON sgspi.activo_documental (epc_codigo);
CREATE NONCLUSTERED INDEX IX_ado_per_codigo_revisor_archivo
    ON sgspi.activo_documental (per_codigo_revisor_archivo);

-- 4B.6 [ads], [adm], [adi], [adf] Tablas Puente N:M de Atributos Atómicos de Activos Documentales hacia Catálogos Extensibles
CREATE TABLE sgspi.activo_documental_soporte_registro (
    ado_codigo INT      NOT NULL, -- FK a [sgspi].[activo_documental]([ado_codigo])
    src_codigo SMALLINT NOT NULL, -- FK a [sgspi].[soporte_registro_catalogo]([src_codigo])
    CONSTRAINT PK_ads_activo_documental_soporte_registro PRIMARY KEY CLUSTERED (ado_codigo, src_codigo),
    CONSTRAINT FK_ads_activo_documental FOREIGN KEY (ado_codigo) REFERENCES sgspi.activo_documental (ado_codigo),
    CONSTRAINT FK_ads_soporte_registro_catalogo FOREIGN KEY (src_codigo) REFERENCES sgspi.soporte_registro_catalogo (src_codigo)
);

CREATE NONCLUSTERED INDEX IX_ads_src_codigo
    ON sgspi.activo_documental_soporte_registro (src_codigo); -- [AP-18] Sin INCLUDE: ado_codigo ya es clave clustered

CREATE TABLE sgspi.activo_documental_medio_conservacion (
    ado_codigo INT      NOT NULL, -- FK a [sgspi].[activo_documental]([ado_codigo])
    mcc_codigo SMALLINT NOT NULL, -- FK a [sgspi].[medio_conservacion_catalogo]([mcc_codigo])
    CONSTRAINT PK_adm_activo_documental_medio_conservacion PRIMARY KEY CLUSTERED (ado_codigo, mcc_codigo),
    CONSTRAINT FK_adm_activo_documental FOREIGN KEY (ado_codigo) REFERENCES sgspi.activo_documental (ado_codigo),
    CONSTRAINT FK_adm_medio_conservacion_catalogo FOREIGN KEY (mcc_codigo) REFERENCES sgspi.medio_conservacion_catalogo (mcc_codigo)
);

CREATE NONCLUSTERED INDEX IX_adm_mcc_codigo
    ON sgspi.activo_documental_medio_conservacion (mcc_codigo); -- [AP-18] Sin INCLUDE: ado_codigo ya es clave clustered

CREATE TABLE sgspi.activo_documental_idioma (
    ado_codigo INT      NOT NULL, -- FK a [sgspi].[activo_documental]([ado_codigo])
    idi_codigo SMALLINT NOT NULL, -- FK a [sgspi].[idioma_catalogo]([idi_codigo])
    CONSTRAINT PK_adi_activo_documental_idioma PRIMARY KEY CLUSTERED (ado_codigo, idi_codigo),
    CONSTRAINT FK_adi_activo_documental FOREIGN KEY (ado_codigo) REFERENCES sgspi.activo_documental (ado_codigo),
    CONSTRAINT FK_adi_idioma_catalogo FOREIGN KEY (idi_codigo) REFERENCES sgspi.idioma_catalogo (idi_codigo)
);

CREATE NONCLUSTERED INDEX IX_adi_idi_codigo
    ON sgspi.activo_documental_idioma (idi_codigo); -- [AP-18] Sin INCLUDE: ado_codigo ya es clave clustered

-- [AP-08] [adf] Formatos de archivo del activo documental (reemplaza el texto libre formato en texto libre)
CREATE TABLE sgspi.activo_documental_formato_archivo (
    ado_codigo INT      NOT NULL, -- FK a [sgspi].[activo_documental]([ado_codigo])
    fac_codigo SMALLINT NOT NULL, -- FK a [sgspi].[formato_archivo_catalogo]([fac_codigo])
    CONSTRAINT PK_adf_activo_documental_formato_archivo PRIMARY KEY CLUSTERED (ado_codigo, fac_codigo),
    CONSTRAINT FK_adf_activo_documental FOREIGN KEY (ado_codigo) REFERENCES sgspi.activo_documental (ado_codigo),
    CONSTRAINT FK_adf_formato_archivo_catalogo FOREIGN KEY (fac_codigo) REFERENCES sgspi.formato_archivo_catalogo (fac_codigo)
);

CREATE NONCLUSTERED INDEX IX_adf_fac_codigo
    ON sgspi.activo_documental_formato_archivo (fac_codigo); -- [AP-18] Sin INCLUDE: ado_codigo ya es clave clustered

-- 4B.7 [adu] Asignación N:M Activo Documental <-> Unidad Productora del CCD/TRD (Modela las 240 filas de desglose TRD sin cadenas multivaluadas)
CREATE TABLE sgspi.activo_documental_unidad_productora (
    ado_codigo  INT NOT NULL, -- FK a [sgspi].[activo_documental]([ado_codigo])
    upc_codigo  INT NOT NULL, -- FK a [sgspi].[unidad_productora_cuadro_clasificacion_documental]([upc_codigo]) (Unidad más específica donde se produce la serie/subserie)
    adu_esta_activo BIT CONSTRAINT DF_adu_esta_activo DEFAULT 1 NOT NULL, -- [AP-17]
    CONSTRAINT PK_adu_activo_documental_unidad_productora PRIMARY KEY CLUSTERED (ado_codigo, upc_codigo),
    CONSTRAINT FK_adu_activo_documental FOREIGN KEY (ado_codigo) REFERENCES sgspi.activo_documental (ado_codigo),
    CONSTRAINT FK_adu_unidad_productora_cuadro_clasificacion_documental FOREIGN KEY (upc_codigo) REFERENCES sgspi.unidad_productora_cuadro_clasificacion_documental (upc_codigo)
);

CREATE NONCLUSTERED INDEX IX_adu_upc_codigo
    ON sgspi.activo_documental_unidad_productora (upc_codigo)
    INCLUDE (adu_esta_activo);



GO
IF @@TRANCOUNT = 0 SET NOEXEC ON; -- [AP-19]
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
IF @@TRANCOUNT = 0 SET NOEXEC ON; -- [AP-19]
GO

-- [AP-09] Semilla de zonas de riesgo (bloque propio: la tabla ya existe en el lote anterior)
INSERT INTO sgspi.zona_riesgo_catalogo (zrc_codigo, zrc_nombre_nivel, zrc_orden)
VALUES ('B', N'Riesgo Inferior', 1),
       ('M', N'Riesgo Moderado', 2),
       ('A', N'Riesgo Alto', 3),
       ('E', N'Riesgo Extremo', 4);
GO
IF @@TRANCOUNT = 0 SET NOEXEC ON; -- [AP-19]
GO

CREATE TABLE sgspi.matriz_valoracion_riesgo (
    epr_codigo                        TINYINT        NOT NULL, -- FK a [sgspi].[escala_probabilidad]([epr_codigo])
    eim_codigo                        TINYINT        NOT NULL, -- FK a [sgspi].[escala_impacto]([eim_codigo])
    -- [AP-09] Columna calculada PERSISTED: 'A1'..'E5' deriva de probabilidad (5=A..1=E) e impacto
    mvr_codigo_posicion                   AS (CONVERT (CHAR (2), CONCAT(CHAR(70 - epr_codigo), eim_codigo))) PERSISTED NOT NULL,
    zrc_codigo                        CHAR (1)       NOT NULL, -- [AP-09] FK a [sgspi].[zona_riesgo_catalogo]([zrc_codigo]) (antes mvr_codigo_zona + mvr_nivel_valoracion)
    mvr_directriz_tratamiento_riesgo      NVARCHAR (255) NOT NULL,
    mvr_directriz_tratamiento_oportunidad NVARCHAR (255) NOT NULL,
    mvr_requiere_aprobacion_comite        BIT            CONSTRAINT DF_mvr_requiere_aprobacion_comite DEFAULT 0 NOT NULL, -- [AP-17]
    CONSTRAINT PK_mvr_matriz_valoracion_riesgo PRIMARY KEY CLUSTERED (epr_codigo, eim_codigo),
    CONSTRAINT UQ_mvr_codigo_posicion UNIQUE (mvr_codigo_posicion),
    CONSTRAINT FK_mvr_escala_probabilidad FOREIGN KEY (epr_codigo) REFERENCES sgspi.escala_probabilidad (epr_codigo),
    CONSTRAINT FK_mvr_escala_impacto FOREIGN KEY (eim_codigo) REFERENCES sgspi.escala_impacto (eim_codigo),
    CONSTRAINT FK_mvr_zona_riesgo FOREIGN KEY (zrc_codigo) REFERENCES sgspi.zona_riesgo_catalogo (zrc_codigo) -- [AP-09] reemplaza CK_mvr_codigo_zona
);

CREATE NONCLUSTERED INDEX IX_mvr_eim_codigo
    ON sgspi.matriz_valoracion_riesgo (eim_codigo);
CREATE NONCLUSTERED INDEX IX_mvr_zrc_codigo -- [AP-18] soporte de la FK a zrc
    ON sgspi.matriz_valoracion_riesgo (zrc_codigo);

-- 5.2 [eia] Escenarios de Incertidumbre sobre Activos (Riesgos RA-XX y Oportunidades OA-XX)
CREATE TABLE sgspi.evento_incertidumbre_activo (
    eia_codigo                      INT                                         IDENTITY (1, 1) NOT NULL,
    pev_codigo                  SMALLINT                                    NOT NULL, -- FK a [sgspi].[periodo_vigencia]([pev_codigo])
    eia_identificador_evento        NVARCHAR (15)                               NOT NULL, -- 'RA-01'..'RA-15', 'OA-01'..'OA-09'
    eia_naturaleza_evento           NVARCHAR (15)                               NOT NULL, -- 'RIESGO' (-), 'OPORTUNIDAD' (+)
    pri_codigo                  INT                                         NOT NULL, -- FK a [sgspi].[proceso_institucional]([pri_codigo])
    aci_codigo_primario         INT                                         NOT NULL, -- FK a [sgspi].[activo_informacion]([aci_codigo])
    aci_codigo_soporte          INT                                         NOT NULL, -- FK a [sgspi].[activo_informacion]([aci_codigo])
    -- [AP-08] Componente afectado vía catálogo de tipos de activo (solo categorías de nivel 1: Información, Software, Servicio, Infraestructura, Hardware)
    tac_codigo_componente       SMALLINT                                    NOT NULL, -- FK a [sgspi].[tipo_activo_catalogo]([tac_codigo])
    tac_nivel_componente        AS (CONVERT (TINYINT, 1)) PERSISTED, -- [AP-08] columna constante: fuerza nivel 1 de la taxonomía en la FK compuesta
    eia_fuente_generadora           NVARCHAR (255)                              NOT NULL,
    eia_controles_existentes        NVARCHAR (1000)                             NULL,
    eia_condicion_vulnerabilidad    NVARCHAR (1000)                             NOT NULL,
    eia_efecto_consecuencia         NVARCHAR (1000)                             NOT NULL,
    eia_escenario_operacional       NVARCHAR (255)                              NOT NULL,
    -- Valoración Inherente / Actual
    epr_codigo_inherente        TINYINT                                     NOT NULL,
    eim_codigo_inherente        TINYINT                                     NOT NULL,
    -- Máquina de Estados Principal y Firmas sobre [dbo].[persona]
    eia_estado_registro             NVARCHAR (30)                               CONSTRAINT DF_eia_estado_registro DEFAULT N'BORRADOR' NOT NULL, -- [AP-17]
    efc_dominio                 AS (CONVERT (NVARCHAR (10), N'EIA')) PERSISTED, -- [AP-05] dominio constante para la FK al catálogo de estados
    per_codigo_creador          INT                                         NOT NULL, -- FK a [dbo].[persona]([per_codigo])
    per_codigo_validador_lider  INT                                         NULL, -- FK a [dbo].[persona]([per_codigo])
    per_codigo_revisor_sgspi    INT                                         NULL, -- FK a [dbo].[persona]([per_codigo])
    per_codigo_aprobador_comite INT                                         NULL, -- FK a [dbo].[persona]([per_codigo])
    eia_fecha_creacion              DATETIMEOFFSET (0)                          CONSTRAINT DF_eia_fecha_creacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17]
    eia_fecha_actualizacion         DATETIMEOFFSET (0)                          CONSTRAINT DF_eia_fecha_actualizacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-11] La mantiene TR_eia_integridad_y_actualizacion
    CONSTRAINT PK_eia_evento_incertidumbre_activo PRIMARY KEY CLUSTERED (eia_codigo),
    CONSTRAINT UQ_eia_vigencia_identificador UNIQUE (pev_codigo, eia_identificador_evento),
    CONSTRAINT UQ_eia_codigo_naturaleza UNIQUE (eia_codigo, eia_naturaleza_evento), -- [AP-06] destino de la FK compuesta de plt
    CONSTRAINT FK_eia_periodo_vigencia FOREIGN KEY (pev_codigo) REFERENCES sgspi.periodo_vigencia (pev_codigo),
    CONSTRAINT FK_eia_proceso_institucional FOREIGN KEY (pri_codigo) REFERENCES sgspi.proceso_institucional (pri_codigo),
    CONSTRAINT FK_eia_activo_primario FOREIGN KEY (aci_codigo_primario) REFERENCES sgspi.activo_informacion (aci_codigo),
    CONSTRAINT FK_eia_activo_soporte FOREIGN KEY (aci_codigo_soporte) REFERENCES sgspi.activo_informacion (aci_codigo),
    CONSTRAINT FK_eia_tipo_activo_componente FOREIGN KEY (tac_codigo_componente, tac_nivel_componente) REFERENCES sgspi.tipo_activo_catalogo (tac_codigo, tac_nivel_taxonomia), -- [AP-08]
    CONSTRAINT FK_eia_valoracion_inherente FOREIGN KEY (epr_codigo_inherente, eim_codigo_inherente) REFERENCES sgspi.matriz_valoracion_riesgo (epr_codigo, eim_codigo),
    CONSTRAINT FK_eia_estado_flujo FOREIGN KEY (efc_dominio, eia_estado_registro) REFERENCES sgspi.estado_flujo_catalogo (efc_dominio, efc_identificador), -- [AP-05] reemplaza CK_eia_estado_maquina
    CONSTRAINT FK_eia_dbo_persona_creador FOREIGN KEY (per_codigo_creador) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT FK_eia_dbo_persona_validador FOREIGN KEY (per_codigo_validador_lider) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT FK_eia_dbo_persona_revisor FOREIGN KEY (per_codigo_revisor_sgspi) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT FK_eia_dbo_persona_comite FOREIGN KEY (per_codigo_aprobador_comite) REFERENCES dbo.persona (per_codigo),
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
    CONSTRAINT CK_eia_sod_firmas CHECK ((per_codigo_validador_lider IS NULL
                                         OR per_codigo_validador_lider <> per_codigo_creador)
                                        AND (per_codigo_revisor_sgspi IS NULL
                                             OR per_codigo_revisor_sgspi <> per_codigo_creador)
                                        AND (per_codigo_aprobador_comite IS NULL
                                             OR per_codigo_aprobador_comite <> per_codigo_creador))
);

CREATE NONCLUSTERED INDEX IX_eia_pri_codigo
    ON sgspi.evento_incertidumbre_activo (pri_codigo);
CREATE NONCLUSTERED INDEX IX_eia_aci_codigo_primario
    ON sgspi.evento_incertidumbre_activo (aci_codigo_primario);
CREATE NONCLUSTERED INDEX IX_eia_aci_codigo_soporte
    ON sgspi.evento_incertidumbre_activo (aci_codigo_soporte);
CREATE NONCLUSTERED INDEX IX_eia_tac_codigo_componente -- [AP-08] [AP-18] soporte de la FK compuesta a tac
    ON sgspi.evento_incertidumbre_activo (tac_codigo_componente, tac_nivel_componente);
CREATE NONCLUSTERED INDEX IX_eia_valoracion_inherente
    ON sgspi.evento_incertidumbre_activo (epr_codigo_inherente, eim_codigo_inherente);
CREATE NONCLUSTERED INDEX IX_eia_per_codigo_creador
    ON sgspi.evento_incertidumbre_activo (per_codigo_creador);
CREATE NONCLUSTERED INDEX IX_eia_per_codigo_validador_lider
    ON sgspi.evento_incertidumbre_activo (per_codigo_validador_lider);
CREATE NONCLUSTERED INDEX IX_eia_per_codigo_revisor_sgspi
    ON sgspi.evento_incertidumbre_activo (per_codigo_revisor_sgspi);
CREATE NONCLUSTERED INDEX IX_eia_per_codigo_aprobador_comite
    ON sgspi.evento_incertidumbre_activo (per_codigo_aprobador_comite);

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
    eia_codigo                  INT             NOT NULL, -- FK a [sgspi].[evento_incertidumbre_activo]([eia_codigo])
    plt_naturaleza_evento           NVARCHAR (15)   NOT NULL, -- [AP-06] 'RIESGO'/'OPORTUNIDAD': debe coincidir con el evento y con la estrategia (FK compuestas)
    etc_codigo                  SMALLINT        NOT NULL, -- FK a [sgspi].[estrategia_tratamiento_catalogo]([etc_codigo])
    plt_justificacion_estrategia    NVARCHAR (1000) NOT NULL,
    -- Valoración Residual Esperada (Meta)
    epr_codigo_residual_meta    TINYINT         NOT NULL,
    eim_codigo_residual_meta    TINYINT         NOT NULL,
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
    per_codigo_evaluador        INT             NULL, -- FK a [dbo].[persona]([per_codigo])
    plt_fecha_evaluacion_eficacia   DATETIMEOFFSET (0) NULL, -- [AP-12]
    plt_fecha_creacion              DATETIMEOFFSET (0) CONSTRAINT DF_plt_fecha_creacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17]
    plt_fecha_actualizacion         DATETIMEOFFSET (0) CONSTRAINT DF_plt_fecha_actualizacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17]
    CONSTRAINT PK_plt_plan_tratamiento PRIMARY KEY CLUSTERED (plt_codigo),
    CONSTRAINT UQ_plt_evento UNIQUE (eia_codigo),
    -- [AP-06] FK compuestas: la naturaleza del plan coincide con la del evento y con la de la estrategia
    CONSTRAINT FK_plt_evento_incertidumbre FOREIGN KEY (eia_codigo, plt_naturaleza_evento) REFERENCES sgspi.evento_incertidumbre_activo (eia_codigo, eia_naturaleza_evento),
    CONSTRAINT FK_plt_estrategia_tratamiento FOREIGN KEY (etc_codigo, plt_naturaleza_evento) REFERENCES sgspi.estrategia_tratamiento_catalogo (etc_codigo, etc_naturaleza_aplicable),
    CONSTRAINT FK_plt_valoracion_meta FOREIGN KEY (epr_codigo_residual_meta, eim_codigo_residual_meta) REFERENCES sgspi.matriz_valoracion_riesgo (epr_codigo, eim_codigo),
    CONSTRAINT FK_plt_dbo_persona_evaluador FOREIGN KEY (per_codigo_evaluador) REFERENCES dbo.persona (per_codigo),
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
                                                  AND per_codigo_evaluador IS NULL
                                                  AND plt_fecha_evaluacion_eficacia IS NULL)
                                                 OR (plt_es_tratamiento_eficaz IS NOT NULL
                                                     AND plt_dictamen_eficacia IS NOT NULL
                                                     AND LEN(TRIM(plt_dictamen_eficacia)) > 0
                                                     AND per_codigo_evaluador IS NOT NULL
                                                     AND plt_fecha_evaluacion_eficacia IS NOT NULL))
);

CREATE NONCLUSTERED INDEX IX_plt_etc_codigo
    ON sgspi.plan_tratamiento (etc_codigo, plt_naturaleza_evento); -- [AP-18] cubre la FK compuesta a etc
CREATE NONCLUSTERED INDEX IX_plt_valoracion_residual_meta
    ON sgspi.plan_tratamiento (epr_codigo_residual_meta, eim_codigo_residual_meta);
CREATE NONCLUSTERED INDEX IX_plt_per_codigo_evaluador
    ON sgspi.plan_tratamiento (per_codigo_evaluador);

-- 5.4 [act] y [sga] Desglose de Actividades del Plan de Tratamiento y Seguimiento con Evidencias
CREATE TABLE sgspi.actividad_tratamiento (
    act_codigo                INT            IDENTITY (1, 1) NOT NULL,
    plt_codigo            INT            NOT NULL, -- FK a [sgspi].[plan_tratamiento]([plt_codigo])
    act_numero_orden          SMALLINT       CONSTRAINT DF_act_numero_orden DEFAULT 1 NOT NULL, -- [AP-17]
    act_descripcion_actividad NVARCHAR (500) NOT NULL,
    car_codigo            INT            NULL, -- FK a [dbo].[cargo]([car_codigo])
    uaa_codigo            INT            NULL, -- FK a [dbo].[uaa]([uaa_codigo])
    act_fecha_compromiso      DATE           NOT NULL,
    act_porcentaje_avance     TINYINT        CONSTRAINT DF_act_porcentaje_avance DEFAULT 0 NOT NULL, -- [AP-17]
    act_estado_actividad      NVARCHAR (30)  CONSTRAINT DF_act_estado_actividad DEFAULT N'PENDIENTE' NOT NULL, -- [AP-05] [AP-17] ampliada de 20 a 30
    efc_dominio           AS (CONVERT (NVARCHAR (10), N'ACT')) PERSISTED, -- [AP-05] dominio constante para la FK al catálogo de estados
    act_fecha_creacion        DATETIMEOFFSET (0) CONSTRAINT DF_act_fecha_creacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17]
    act_fecha_actualizacion   DATETIMEOFFSET (0) CONSTRAINT DF_act_fecha_actualizacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17]
    CONSTRAINT PK_act_actividad_tratamiento PRIMARY KEY CLUSTERED (act_codigo),
    CONSTRAINT UQ_act_plan_orden UNIQUE (plt_codigo, act_numero_orden), -- [AP-14] clave natural; también cubre la FK a plt
    CONSTRAINT FK_act_plan_tratamiento FOREIGN KEY (plt_codigo) REFERENCES sgspi.plan_tratamiento (plt_codigo),
    CONSTRAINT FK_act_dbo_cargo FOREIGN KEY (car_codigo) REFERENCES dbo.cargo (car_codigo),
    CONSTRAINT FK_act_dbo_uaa FOREIGN KEY (uaa_codigo) REFERENCES dbo.uaa (uaa_codigo),
    CONSTRAINT FK_act_estado_flujo FOREIGN KEY (efc_dominio, act_estado_actividad) REFERENCES sgspi.estado_flujo_catalogo (efc_dominio, efc_identificador), -- [AP-05] reemplaza CK_act_estado_actividad
    CONSTRAINT CK_act_numero_orden_positivo CHECK (act_numero_orden >= 1), -- [AP-14]
    CONSTRAINT CK_act_porcentaje_avance CHECK (act_porcentaje_avance BETWEEN 0 AND 100),
    -- [AP-16] Una actividad COMPLETADA debe estar al 100 % de avance
    CONSTRAINT CK_act_completada_al_100 CHECK (act_estado_actividad <> N'COMPLETADA'
                                               OR act_porcentaje_avance = 100)
);

-- [AP-14] IX_act_plt_codigo eliminado: lo cubre UQ_act_plan_orden (plt_codigo es su primera columna)
CREATE NONCLUSTERED INDEX IX_act_car_codigo
    ON sgspi.actividad_tratamiento (car_codigo);
CREATE NONCLUSTERED INDEX IX_act_uaa_codigo
    ON sgspi.actividad_tratamiento (uaa_codigo);

CREATE TABLE sgspi.seguimiento_actividad (
    sga_codigo                       INT             IDENTITY (1, 1) NOT NULL,
    act_codigo                   INT             NOT NULL, -- FK a [sgspi].[actividad_tratamiento]([act_codigo])
    per_codigo                   INT             NOT NULL, -- FK a [dbo].[persona]([per_codigo])
    sga_fecha_registro               DATETIMEOFFSET (0) CONSTRAINT DF_sga_fecha_registro DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17]
    sga_porcentaje_reportado         TINYINT         NOT NULL,
    sga_descripcion_avance           NVARCHAR (1000) NOT NULL,
    sga_nombre_archivo_evidencia     NVARCHAR (255)  NULL,
    sga_uri_almacenamiento_evidencia NVARCHAR (500)  NULL,
    sga_hash_sha256_evidencia        CHAR (64)       NULL,
    CONSTRAINT PK_sga_seguimiento_actividad PRIMARY KEY CLUSTERED (sga_codigo),
    CONSTRAINT FK_sga_actividad_tratamiento FOREIGN KEY (act_codigo) REFERENCES sgspi.actividad_tratamiento (act_codigo),
    CONSTRAINT FK_sga_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo),
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
    ON sgspi.seguimiento_actividad (act_codigo);
CREATE NONCLUSTERED INDEX IX_sga_per_codigo
    ON sgspi.seguimiento_actividad (per_codigo);

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
    enc_codigo            SMALLINT        NOT NULL, -- FK a [sgspi].[estandar_normativo_catalogo]([enc_codigo])
    crn_rol_privacidad_pii    NVARCHAR (20)   NULL, -- 'CONTROLADOR', 'PROCESADOR', 'COMUN' (NULL cuando el estándar no define rol PII, ej. ISO/IEC 27001:2022)
    crn_identificador_control NVARCHAR (20)   NOT NULL, -- 'A.5.1'..'A.8.34', 'A.1.2.2'..'A.3.31'
    crn_nombre_control        NVARCHAR (200)  NOT NULL,
    crn_objetivo_requisito    NVARCHAR (1500) NOT NULL,
    crn_esta_activo           BIT             CONSTRAINT DF_crn_esta_activo DEFAULT 1 NOT NULL, -- [AP-17]
    CONSTRAINT PK_crn_control_referencia_normativa PRIMARY KEY CLUSTERED (crn_codigo),
    CONSTRAINT UQ_crn_estandar_identificador UNIQUE (enc_codigo, crn_identificador_control),
    CONSTRAINT FK_crn_estandar_normativo FOREIGN KEY (enc_codigo) REFERENCES sgspi.estandar_normativo_catalogo (enc_codigo),
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
    crn_codigo SMALLINT NOT NULL, -- FK a [sgspi].[control_referencia_normativa]([crn_codigo])
    aac_codigo SMALLINT NOT NULL, -- FK a [sgspi].[atributo_control_catalogo]([aac_codigo])
    CONSTRAINT PK_cra_control_referencia_normativa_atributo PRIMARY KEY CLUSTERED (crn_codigo, aac_codigo),
    CONSTRAINT FK_cra_control_referencia FOREIGN KEY (crn_codigo) REFERENCES sgspi.control_referencia_normativa (crn_codigo) ON DELETE CASCADE,
    CONSTRAINT FK_cra_atributo_control FOREIGN KEY (aac_codigo) REFERENCES sgspi.atributo_control_catalogo (aac_codigo)
);

CREATE NONCLUSTERED INDEX IX_cra_aac_codigo
    ON sgspi.control_referencia_normativa_atributo (aac_codigo);

-- 5.7 [ptc] Relación N:M Plan de Tratamiento <-> Controles de Referencia Normativa (ISO 27001 e ISO 27701)
CREATE TABLE sgspi.plan_tratamiento_control_referencia_normativa (
    plt_codigo INT      NOT NULL, -- FK a [sgspi].[plan_tratamiento]([plt_codigo])
    crn_codigo SMALLINT NOT NULL, -- FK a [sgspi].[control_referencia_normativa]([crn_codigo])
    CONSTRAINT PK_ptc_plan_tratamiento_control_referencia_normativa PRIMARY KEY CLUSTERED (plt_codigo, crn_codigo),
    CONSTRAINT FK_ptc_plan_tratamiento FOREIGN KEY (plt_codigo) REFERENCES sgspi.plan_tratamiento (plt_codigo),
    CONSTRAINT FK_ptc_control_referencia FOREIGN KEY (crn_codigo) REFERENCES sgspi.control_referencia_normativa (crn_codigo)
);

CREATE NONCLUSTERED INDEX IX_ptc_crn_codigo
    ON sgspi.plan_tratamiento_control_referencia_normativa (crn_codigo);

-- 5.8 [eac] Declaración de Aplicabilidad (SoA) y Evaluación de Cumplimiento por Vigencia
CREATE TABLE sgspi.evaluacion_aplicabilidad_control (
    eac_codigo                      INT                                         IDENTITY (1, 1) NOT NULL,
    pev_codigo                  SMALLINT                                    NOT NULL, -- FK a [sgspi].[periodo_vigencia]([pev_codigo])
    crn_codigo                  SMALLINT                                    NOT NULL, -- FK a [sgspi].[control_referencia_normativa]([crn_codigo])
    eac_es_aplicable                BIT                                         CONSTRAINT DF_eac_es_aplicable DEFAULT 1 NOT NULL, -- [AP-17]
    eac_justificacion_aplicabilidad NVARCHAR (1000)                             NULL,
    eac_documento_soporte_normativo NVARCHAR (500)                              NULL,
    car_codigo                  INT                                         NULL, -- FK a [dbo].[cargo]([car_codigo])
    eac_frecuencia_revision         NVARCHAR (100)                              NULL, -- Ej: 'Anual y cuando se presenten cambios' (NULL cuando eac_es_aplicable = 0)
    eac_evidencia_objetiva_esperada NVARCHAR (500)                              NULL,
    eac_estado_implementacion       NVARCHAR (20)                               NULL, -- 'CUMPLE', 'CUMPLE_PARCIAL', 'NO_CUMPLE' (NULL cuando eac_es_aplicable = 0)
    eac_observaciones_auditoria     NVARCHAR (1000)                             NULL,
    eac_fecha_creacion              DATETIMEOFFSET (0)                          CONSTRAINT DF_eac_fecha_creacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17]
    eac_fecha_actualizacion         DATETIMEOFFSET (0)                          CONSTRAINT DF_eac_fecha_actualizacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-11] La mantiene TR_eac_integridad_y_actualizacion
    CONSTRAINT PK_eac_evaluacion_aplicabilidad_control PRIMARY KEY CLUSTERED (eac_codigo),
    CONSTRAINT UQ_eac_vigencia_control UNIQUE (pev_codigo, crn_codigo),
    CONSTRAINT FK_eac_periodo_vigencia FOREIGN KEY (pev_codigo) REFERENCES sgspi.periodo_vigencia (pev_codigo),
    CONSTRAINT FK_eac_control_referencia FOREIGN KEY (crn_codigo) REFERENCES sgspi.control_referencia_normativa (crn_codigo),
    CONSTRAINT FK_eac_dbo_cargo FOREIGN KEY (car_codigo) REFERENCES dbo.cargo (car_codigo),
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
);

CREATE NONCLUSTERED INDEX IX_eac_crn_codigo
    ON sgspi.evaluacion_aplicabilidad_control (crn_codigo);
CREATE NONCLUSTERED INDEX IX_eac_car_codigo
    ON sgspi.evaluacion_aplicabilidad_control (car_codigo);


GO
IF @@TRANCOUNT = 0 SET NOEXEC ON; -- [AP-19]
GO
/*==================================================================================================
  5.10 TRIGGERS DE INTEGRIDAD: MÁQUINA DE ESTADOS DIRIGIDA POR DATOS, BORRADO LÓGICO, FECHA DE
       ACTUALIZACIÓN Y SEGUIMIENTO APPEND-ONLY
       Cada TR_<acr>_integridad_y_actualizacion: (a) impide el borrado físico (error 50010); (b) en las tablas
       con flujo exige el estado inicial en INSERT (50014) y solo admite las transiciones de [tef] y la
       edición en estados con efc_permite_edicion = 1 (50011); (c) mantiene <acr>_fecha_actualizacion.
       No registran bitácora ni exigen contexto de sesión (auditoría retirada: AP-01, AP-03).
==================================================================================================*/
-- 5.10.1 Trigger sobre [sgspi].[analisis_contexto_factor] ([acf])
CREATE OR ALTER TRIGGER sgspi.TR_acf_integridad_y_actualizacion
ON sgspi.analisis_contexto_factor
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- La actualización de la fecha que hace este mismo trigger no debe volver a validarse
    IF TRIGGER_NESTLEVEL(OBJECT_ID(N'sgspi.TR_acf_integridad_y_actualizacion', N'TR')) > 1
        RETURN;

    IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
        THROW 50010, N'Operación denegada: No se permite eliminar físicamente registros de [sgspi].[analisis_contexto_factor].', 1;

    IF NOT EXISTS (SELECT 1 FROM inserted)
        RETURN;

    -- [AP-04] En INSERT el estado debe ser el inicial del dominio
    IF EXISTS (
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
                           WHERE  tef.efc_dominio = N'ACF'
                                  AND tef.efc_identificador_origen = d.acf_estado_registro
                                  AND tef.efc_identificador_destino = i.acf_estado_registro
                       ))
        )
            THROW 50011, N'Transición inválida o intento de modificar un registro sin estado editable (VIGENTE/HISTORICO) sin reabrir revisión en [sgspi].[analisis_contexto_factor].', 1;

        IF NOT UPDATE(acf_fecha_actualizacion)
            UPDATE t
            SET    t.acf_fecha_actualizacion = SYSDATETIMEOFFSET() -- [AP-12]
            FROM   sgspi.analisis_contexto_factor AS t
                   INNER JOIN inserted AS i ON i.acf_codigo = t.acf_codigo;
    END;
END;


GO
IF @@TRANCOUNT = 0 SET NOEXEC ON; -- [AP-19]
GO
-- 5.10.2 Trigger sobre [sgspi].[requisito_parte_interesada] ([rpi])
CREATE OR ALTER TRIGGER sgspi.TR_rpi_integridad_y_actualizacion
ON sgspi.requisito_parte_interesada
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF TRIGGER_NESTLEVEL(OBJECT_ID(N'sgspi.TR_rpi_integridad_y_actualizacion', N'TR')) > 1
        RETURN;

    IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
        THROW 50010, N'Operación denegada: No se permite eliminar físicamente registros de [sgspi].[requisito_parte_interesada].', 1;

    IF NOT EXISTS (SELECT 1 FROM inserted)
        RETURN;

    -- [AP-04] En INSERT el estado debe ser el inicial del dominio
    IF EXISTS (
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
                           WHERE  tef.efc_dominio = N'RPI'
                                  AND tef.efc_identificador_origen = d.rpi_estado_registro
                                  AND tef.efc_identificador_destino = i.rpi_estado_registro
                       ))
        )
            THROW 50011, N'Transición inválida o intento de modificar un registro sin estado editable (VIGENTE/HISTORICO) sin reabrir revisión en [sgspi].[requisito_parte_interesada].', 1;

        IF NOT UPDATE(rpi_fecha_actualizacion)
            UPDATE t
            SET    t.rpi_fecha_actualizacion = SYSDATETIMEOFFSET() -- [AP-12]
            FROM   sgspi.requisito_parte_interesada AS t
                   INNER JOIN inserted AS i ON i.rpi_codigo = t.rpi_codigo;
    END;
END;


GO
IF @@TRANCOUNT = 0 SET NOEXEC ON; -- [AP-19]
GO
-- 5.10.3 Trigger sobre [sgspi].[activo_informacion] ([aci])
CREATE OR ALTER TRIGGER sgspi.TR_aci_integridad_y_actualizacion
ON sgspi.activo_informacion
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF TRIGGER_NESTLEVEL(OBJECT_ID(N'sgspi.TR_aci_integridad_y_actualizacion', N'TR')) > 1
        RETURN;

    IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
        THROW 50010, N'Operación denegada: No se permite eliminar físicamente activos en [sgspi].[activo_informacion]. Utilice los estados INACTIVO o HISTORICO.', 1;

    IF NOT EXISTS (SELECT 1 FROM inserted)
        RETURN;

    -- [AP-04] En INSERT el estado debe ser el inicial del dominio
    IF EXISTS (
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
                           WHERE  tef.efc_dominio = N'ACI'
                                  AND tef.efc_identificador_origen = d.aci_estado_registro
                                  AND tef.efc_identificador_destino = i.aci_estado_registro
                       ))
        )
            THROW 50011, N'Transición inválida o intento de modificar un activo no editable (VIGENTE/HISTORICO) sin reabrir revisión en [sgspi].[activo_informacion].', 1;

        IF NOT UPDATE(aci_fecha_actualizacion)
            UPDATE t
            SET    t.aci_fecha_actualizacion = SYSDATETIMEOFFSET() -- [AP-12]
            FROM   sgspi.activo_informacion AS t
                   INNER JOIN inserted AS i ON i.aci_codigo = t.aci_codigo;
    END;
END;


GO
IF @@TRANCOUNT = 0 SET NOEXEC ON; -- [AP-19]
GO
-- 5.10.4 Trigger sobre [sgspi].[activo_documental] ([ado]): sin flujo propio (hereda el estado de [aci])
CREATE OR ALTER TRIGGER sgspi.TR_ado_integridad_y_actualizacion
ON sgspi.activo_documental
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF TRIGGER_NESTLEVEL(OBJECT_ID(N'sgspi.TR_ado_integridad_y_actualizacion', N'TR')) > 1
        RETURN;

    IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
        THROW 50010, N'Operación denegada: No se permite eliminar físicamente activos documentales en [sgspi].[activo_documental].', 1;

    IF NOT EXISTS (SELECT 1 FROM inserted)
        RETURN;

    -- [AP-06] Una serie con subseries exige indicar la subserie (INSERT y UPDATE)
    IF EXISTS (
        SELECT 1
        FROM   inserted AS i
               INNER JOIN sgspi.serie_documental_catalogo AS sdo ON sdo.sdo_codigo = i.sdo_codigo
        WHERE  sdo.sdo_tiene_subseries = 1
               AND i.sbd_codigo IS NULL
    )
        THROW 50015, N'Subserie requerida: la serie documental seleccionada tiene subseries y [sbd_codigo] no puede ser NULL en [sgspi].[activo_documental].', 1;

    IF EXISTS (SELECT 1 FROM deleted)
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM   inserted AS i
                   INNER JOIN sgspi.activo_informacion AS aci ON aci.aci_codigo = i.ado_codigo
            WHERE  aci.aci_estado_registro = N'HISTORICO'
        )
            THROW 50011, N'Operación denegada: No se permite modificar un activo documental cuyo activo de información se encuentra en estado HISTORICO en [sgspi].[activo_documental].', 1;

        IF NOT UPDATE(ado_fecha_actualizacion)
            UPDATE t
            SET    t.ado_fecha_actualizacion = SYSDATETIMEOFFSET() -- [AP-11] [AP-12]
            FROM   sgspi.activo_documental AS t
                   INNER JOIN inserted AS i ON i.ado_codigo = t.ado_codigo;
    END;
END;


GO
IF @@TRANCOUNT = 0 SET NOEXEC ON; -- [AP-19]
GO
-- 5.10.5 Trigger sobre [sgspi].[evento_incertidumbre_activo] ([eia])
CREATE OR ALTER TRIGGER sgspi.TR_eia_integridad_y_actualizacion
ON sgspi.evento_incertidumbre_activo
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF TRIGGER_NESTLEVEL(OBJECT_ID(N'sgspi.TR_eia_integridad_y_actualizacion', N'TR')) > 1
        RETURN;

    IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
        THROW 50010, N'Operación denegada: No se permite eliminar físicamente eventos en [sgspi].[evento_incertidumbre_activo].', 1;

    IF NOT EXISTS (SELECT 1 FROM inserted)
        RETURN;

    -- [AP-04] En INSERT el estado debe ser el inicial del dominio
    IF EXISTS (
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
                           WHERE  tef.efc_dominio = N'EIA'
                                  AND tef.efc_identificador_origen = d.eia_estado_registro
                                  AND tef.efc_identificador_destino = i.eia_estado_registro
                       ))
        )
            THROW 50011, N'Transición de estado inválida o intento de alterar un evento cerrado/histórico en [sgspi].[evento_incertidumbre_activo].', 1;

        IF NOT UPDATE(eia_fecha_actualizacion)
            UPDATE t
            SET    t.eia_fecha_actualizacion = SYSDATETIMEOFFSET() -- [AP-11] [AP-12]
            FROM   sgspi.evento_incertidumbre_activo AS t
                   INNER JOIN inserted AS i ON i.eia_codigo = t.eia_codigo;
    END;
END;


GO
IF @@TRANCOUNT = 0 SET NOEXEC ON; -- [AP-19]
GO
-- 5.10.6 Trigger sobre [sgspi].[plan_tratamiento] ([plt]): sin flujo propio (depende del estado de su evento [eia])
CREATE OR ALTER TRIGGER sgspi.TR_plt_integridad_y_actualizacion
ON sgspi.plan_tratamiento
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF TRIGGER_NESTLEVEL(OBJECT_ID(N'sgspi.TR_plt_integridad_y_actualizacion', N'TR')) > 1
        RETURN;

    IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
        THROW 50010, N'Operación denegada: No se permite eliminar físicamente planes de tratamiento en [sgspi].[plan_tratamiento].', 1;

    IF EXISTS (SELECT 1 FROM deleted)
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM   inserted AS i
                   INNER JOIN sgspi.evento_incertidumbre_activo AS eia ON eia.eia_codigo = i.eia_codigo
            WHERE  eia.eia_estado_registro IN (N'CERRADO_EFICAZ', N'HISTORICO')
        )
            THROW 50011, N'Operación denegada: No se permite modificar el plan de tratamiento de un evento CERRADO_EFICAZ o HISTORICO en [sgspi].[plan_tratamiento].', 1;

        IF NOT UPDATE(plt_fecha_actualizacion)
            UPDATE t
            SET    t.plt_fecha_actualizacion = SYSDATETIMEOFFSET() -- [AP-12]
            FROM   sgspi.plan_tratamiento AS t
                   INNER JOIN inserted AS i ON i.plt_codigo = t.plt_codigo;
    END;
END;


GO
IF @@TRANCOUNT = 0 SET NOEXEC ON; -- [AP-19]
GO
-- 5.10.7 Trigger sobre [sgspi].[actividad_tratamiento] ([act])
CREATE OR ALTER TRIGGER sgspi.TR_act_integridad_y_actualizacion
ON sgspi.actividad_tratamiento
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF TRIGGER_NESTLEVEL(OBJECT_ID(N'sgspi.TR_act_integridad_y_actualizacion', N'TR')) > 1
        RETURN;

    IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
        THROW 50010, N'Operación denegada: No se permite eliminar físicamente actividades de tratamiento en [sgspi].[actividad_tratamiento].', 1;

    IF NOT EXISTS (SELECT 1 FROM inserted)
        RETURN;

    -- [AP-04] En INSERT el estado debe ser el inicial del dominio
    IF EXISTS (
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
                           WHERE  tef.efc_dominio = N'ACT'
                                  AND tef.efc_identificador_origen = d.act_estado_actividad
                                  AND tef.efc_identificador_destino = i.act_estado_actividad
                       ))
        )
            THROW 50011, N'Transición de estado inválida o intento de modificar una actividad en estado no editable (COMPLETADA) en [sgspi].[actividad_tratamiento].', 1;

        -- No se tocan actividades de un evento CERRADO_EFICAZ o HISTORICO
        IF EXISTS (
            SELECT 1
            FROM   inserted AS i
                   INNER JOIN sgspi.plan_tratamiento AS plt ON plt.plt_codigo = i.plt_codigo
                   INNER JOIN sgspi.evento_incertidumbre_activo AS eia ON eia.eia_codigo = plt.eia_codigo
            WHERE  eia.eia_estado_registro IN (N'CERRADO_EFICAZ', N'HISTORICO')
        )
            THROW 50011, N'Operación denegada: No se permite modificar actividades de un evento CERRADO_EFICAZ o HISTORICO en [sgspi].[actividad_tratamiento].', 1;

        IF NOT UPDATE(act_fecha_actualizacion)
            UPDATE t
            SET    t.act_fecha_actualizacion = SYSDATETIMEOFFSET() -- [AP-12]
            FROM   sgspi.actividad_tratamiento AS t
                   INNER JOIN inserted AS i ON i.act_codigo = t.act_codigo;
    END;
END;


GO
IF @@TRANCOUNT = 0 SET NOEXEC ON; -- [AP-19]
GO
-- 5.10.8 Trigger sobre [sgspi].[evaluacion_aplicabilidad_control] ([eac]): sin flujo de estados
CREATE OR ALTER TRIGGER sgspi.TR_eac_integridad_y_actualizacion
ON sgspi.evaluacion_aplicabilidad_control
AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF TRIGGER_NESTLEVEL(OBJECT_ID(N'sgspi.TR_eac_integridad_y_actualizacion', N'TR')) > 1
        RETURN;

    IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
        THROW 50010, N'Operación denegada: No se permite eliminar físicamente evaluaciones de aplicabilidad (SoA) en [sgspi].[evaluacion_aplicabilidad_control].', 1;

    IF NOT UPDATE(eac_fecha_actualizacion)
        UPDATE t
        SET    t.eac_fecha_actualizacion = SYSDATETIMEOFFSET() -- [AP-11] [AP-12]
        FROM   sgspi.evaluacion_aplicabilidad_control AS t
               INNER JOIN inserted AS i ON i.eac_codigo = t.eac_codigo;
END;


GO
IF @@TRANCOUNT = 0 SET NOEXEC ON; -- [AP-19]
GO
-- 5.10.9 Triggers sobre [sgspi].[seguimiento_actividad] ([sga]) [AP-16]
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
IF @@TRANCOUNT = 0 SET NOEXEC ON; -- [AP-19]
GO
-- [AP-09] El avance de la actividad deja de ser un dato duplicado y desincronizado: se deriva del último seguimiento reportado.
-- El UPDATE sobre [act] dispara TR_act_integridad_y_actualizacion (aplica sus reglas de estado): es lo deseado.
CREATE OR ALTER TRIGGER sgspi.TR_sga_sincronizar_avance
ON sgspi.seguimiento_actividad
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM inserted)
        RETURN;

    -- Si hay varias filas de la misma actividad en el lote, prevalece la de mayor sga_codigo
    UPDATE act
    SET    act.act_porcentaje_avance = x.sga_porcentaje_reportado
    FROM   sgspi.actividad_tratamiento AS act
           INNER JOIN (SELECT i.act_codigo,
                              i.sga_porcentaje_reportado,
                              ROW_NUMBER() OVER (PARTITION BY i.act_codigo ORDER BY i.sga_codigo DESC) AS rn
                       FROM   inserted AS i) AS x
           ON x.act_codigo = act.act_codigo
              AND x.rn = 1
    WHERE  act.act_porcentaje_avance <> x.sga_porcentaje_reportado;
END;


GO
IF @@TRANCOUNT = 0 SET NOEXEC ON; -- [AP-19]
GO
-- 5.10.10 Roles y permisos [AP-02]: las reglas no pueden depender solo de triggers (TRUNCATE / DISABLE TRIGGER los evaden),
-- por eso se deniega ALTER al rol de aplicación. dbo / db_owner / sysadmin NO se pueden restringir con DENY.
-- [sgspi_rol_administrador] se crea sin permisos: queda reservado hasta definir sus privilegios.
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'sgspi_rol_aplicacion' AND type = N'R')
    CREATE ROLE sgspi_rol_aplicacion;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'sgspi_rol_administrador' AND type = N'R')
    CREATE ROLE sgspi_rol_administrador;

GRANT SELECT, INSERT, UPDATE ON SCHEMA::sgspi TO sgspi_rol_aplicacion;
DENY ALTER ON SCHEMA::sgspi TO sgspi_rol_aplicacion;



GO
IF @@TRANCOUNT = 0 SET NOEXEC ON; -- [AP-19]
GO
/*==================================================================================================
  6. VISTAS DINÁMICAS PARA CAMPOS CALCULADOS E INTEGRACIÓN CON [dbo]
==================================================================================================*/
-- 6.0 Vista de Integración de Seguridad y Alcance por Proceso/UAA
-- CONCAT con literales Unicode (N'')
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
       piu.pri_codigo AS pri_codigo,
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
       ON piu.uaa_codigo = u.uaa_codigo
       LEFT OUTER JOIN
       sgspi.proceso_institucional AS pr
       ON pr.pri_codigo = piu.pri_codigo
WHERE  ug.usg_estado = 1
       AND g.gru_estado = 1;


GO
IF @@TRANCOUNT = 0 SET NOEXEC ON; -- [AP-19]
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
       ON pv.pev_codigo = acf.pev_codigo
       INNER JOIN
       sgspi.proceso_institucional AS pr
       ON pr.pri_codigo = acf.pri_codigo
       INNER JOIN
       sgspi.tipo_proceso_catalogo AS tpc
       ON tpc.tpr_codigo = pr.tpr_codigo
       INNER JOIN
       sgspi.factor_entorno_catalogo AS fec
       ON fec.fec_codigo = acf.fec_codigo;


GO
IF @@TRANCOUNT = 0 SET NOEXEC ON; -- [AP-19]
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
               ON tac.tac_codigo = ai.tac_codigo
               LEFT OUTER JOIN
               sgspi.tipo_activo_catalogo AS pad
               ON pad.tac_codigo = tac.tac_codigo_padre
               LEFT OUTER JOIN
               sgspi.tipo_activo_catalogo AS abu
               ON abu.tac_codigo = pad.tac_codigo_padre
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
IF @@TRANCOUNT = 0 SET NOEXEC ON; -- [AP-19]
GO
-- 6.3 Vista Matriz de Tratamiento de Riesgos y Oportunidades (Calcula concatenaciones y cruces en tiempo real)
CREATE OR ALTER VIEW sgspi.vw_matriz_tratamiento_riesgos
AS
WITH   cte_controles_27001
AS     (SELECT   ptc.plt_codigo,
                 STRING_AGG(crn.crn_identificador_control, N', ') WITHIN GROUP (ORDER BY crn.crn_codigo) AS crn_controles_iso27001
        FROM     sgspi.plan_tratamiento_control_referencia_normativa AS ptc
                 INNER JOIN
                 sgspi.control_referencia_normativa AS crn
                 ON crn.crn_codigo = ptc.crn_codigo
                 INNER JOIN
                 sgspi.estandar_normativo_catalogo AS enc
                 ON enc.enc_codigo = crn.enc_codigo
        WHERE    enc.enc_familia_norma = N'ISO27001' -- [AP-13]
        GROUP BY ptc.plt_codigo),
       cte_controles_27701
AS     (SELECT   ptc.plt_codigo,
                 STRING_AGG(CONCAT_WS(N': ', crn.crn_rol_privacidad_pii, crn.crn_identificador_control), N' | ') WITHIN GROUP (ORDER BY crn.crn_codigo) AS crn_controles_iso27701
        FROM     sgspi.plan_tratamiento_control_referencia_normativa AS ptc
                 INNER JOIN
                 sgspi.control_referencia_normativa AS crn
                 ON crn.crn_codigo = ptc.crn_codigo
                 INNER JOIN
                 sgspi.estandar_normativo_catalogo AS enc
                 ON enc.enc_codigo = crn.enc_codigo
        WHERE    enc.enc_familia_norma = N'ISO27701' -- [AP-13]
        GROUP BY ptc.plt_codigo)
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
       ON pt.eia_codigo = eia.eia_codigo
       INNER JOIN
       sgspi.estrategia_tratamiento_catalogo AS etc
       ON etc.etc_codigo = pt.etc_codigo
       INNER JOIN
       sgspi.proceso_institucional AS pr
       ON pr.pri_codigo = eia.pri_codigo
       INNER JOIN
       sgspi.activo_informacion AS ap
       ON ap.aci_codigo = eia.aci_codigo_primario
       INNER JOIN
       sgspi.activo_informacion AS asop
       ON asop.aci_codigo = eia.aci_codigo_soporte
       INNER JOIN
       sgspi.escala_probabilidad AS ep_inh
       ON ep_inh.epr_codigo = eia.epr_codigo_inherente
       INNER JOIN
       sgspi.escala_impacto AS ei_inh
       ON ei_inh.eim_codigo = eia.eim_codigo_inherente
       INNER JOIN
       sgspi.matriz_valoracion_riesgo AS mvr_inh
       ON mvr_inh.epr_codigo = eia.epr_codigo_inherente
          AND mvr_inh.eim_codigo = eia.eim_codigo_inherente
       INNER JOIN
       sgspi.zona_riesgo_catalogo AS zrc_inh -- [AP-13] nivel de valoración desde el catálogo de zonas
       ON zrc_inh.zrc_codigo = mvr_inh.zrc_codigo
       INNER JOIN
       sgspi.escala_probabilidad AS ep_meta
       ON ep_meta.epr_codigo = pt.epr_codigo_residual_meta
       INNER JOIN
       sgspi.escala_impacto AS ei_meta
       ON ei_meta.eim_codigo = pt.eim_codigo_residual_meta
       INNER JOIN
       sgspi.matriz_valoracion_riesgo AS mvr_meta
       ON mvr_meta.epr_codigo = pt.epr_codigo_residual_meta
          AND mvr_meta.eim_codigo = pt.eim_codigo_residual_meta
       INNER JOIN
       sgspi.zona_riesgo_catalogo AS zrc_meta
       ON zrc_meta.zrc_codigo = mvr_meta.zrc_codigo
       LEFT OUTER JOIN
       cte_controles_27001 AS c27001
       ON c27001.plt_codigo = pt.plt_codigo
       LEFT OUTER JOIN
       cte_controles_27701 AS c27701
       ON c27701.plt_codigo = pt.plt_codigo;


GO
IF @@TRANCOUNT = 0 SET NOEXEC ON; -- [AP-19]
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
SELECT adu.ado_codigo AS ado_codigo,
       adu.upc_codigo AS upc_codigo,
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
       ON ado.ado_codigo = adu.ado_codigo
       INNER JOIN
       cte_jerarquia_ccd AS j
       ON j.upc_codigo = adu.upc_codigo
       INNER JOIN
       sgspi.serie_documental_catalogo AS sdo
       ON sdo.sdo_codigo = ado.sdo_codigo
       LEFT OUTER JOIN
       sgspi.subserie_documental_catalogo AS sbd
       ON sbd.sdo_codigo = ado.sdo_codigo
          AND sbd.sbd_codigo = ado.sbd_codigo
WHERE  adu.adu_esta_activo = 1;


GO
IF @@TRANCOUNT = 0 SET NOEXEC ON; -- [AP-19]
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
AS     (SELECT   aip.aci_codigo,
                 STRING_AGG(pr.pri_nombre, N', ') WITHIN GROUP (ORDER BY pr.pri_codigo) AS ado_procesos_asociados
        FROM     sgspi.activo_informacion_proceso_institucional AS aip
                 INNER JOIN
                 sgspi.proceso_institucional AS pr
                 ON pr.pri_codigo = aip.pri_codigo
        GROUP BY aip.aci_codigo),
       cte_dependencias_doc
AS     (SELECT   x.aci_codigo,
                 STRING_AGG(CONVERT(NVARCHAR(200), x.uaa_nombre), N', ') WITHIN GROUP (ORDER BY x.uaa_nombre) AS ado_dependencias_oficinas
        FROM     (SELECT DISTINCT air.aci_codigo,
                                  u.uaa_nombre
                  FROM   sgspi.activo_informacion_responsable AS air
                         INNER JOIN
                         dbo.uaa AS u
                         ON u.uaa_codigo = air.uaa_codigo
                  WHERE  air.air_esta_activo = 1) AS x
        GROUP BY x.aci_codigo),
       cte_propietarios_doc
AS     (SELECT   air.aci_codigo,
                 STRING_AGG(CONVERT(NVARCHAR(100), c.car_nombre), N', ') WITHIN GROUP (ORDER BY air.car_codigo, air.uaa_codigo) AS ado_propietarios_activo
        FROM     sgspi.activo_informacion_responsable AS air
                 INNER JOIN
                 dbo.cargo AS c
                 ON c.car_codigo = air.car_codigo
        WHERE    air.air_esta_activo = 1
                 AND air.air_tipo_responsabilidad = N'PROPIETARIO'
        GROUP BY air.aci_codigo),
       cte_custodios_doc
AS     (SELECT   air.aci_codigo,
                 STRING_AGG(CONVERT(NVARCHAR(100), c.car_nombre), N', ') WITHIN GROUP (ORDER BY air.car_codigo, air.uaa_codigo) AS ado_custodios_activo
        FROM     sgspi.activo_informacion_responsable AS air
                 INNER JOIN
                 dbo.cargo AS c
                 ON c.car_codigo = air.car_codigo
        WHERE    air.air_esta_activo = 1
                 AND air.air_tipo_responsabilidad = N'CUSTODIO'
        GROUP BY air.aci_codigo),
       cte_soportes_doc
AS     (SELECT   ads.ado_codigo,
                 STRING_AGG(src.src_nombre, N'/') WITHIN GROUP (ORDER BY src.src_nombre DESC) AS ado_soporte_registro
        FROM     sgspi.activo_documental_soporte_registro AS ads
                 INNER JOIN
                 sgspi.soporte_registro_catalogo AS src
                 ON src.src_codigo = ads.src_codigo
        GROUP BY ads.ado_codigo),
       cte_medios_doc
AS     (SELECT   adm.ado_codigo,
                 STRING_AGG(mcc.mcc_nombre, N'/') WITHIN GROUP (ORDER BY mcc.mcc_nombre DESC) AS ado_medio_conservacion
        FROM     sgspi.activo_documental_medio_conservacion AS adm
                 INNER JOIN
                 sgspi.medio_conservacion_catalogo AS mcc
                 ON mcc.mcc_codigo = adm.mcc_codigo
        GROUP BY adm.ado_codigo),
       cte_idiomas_doc
AS     (SELECT   adi.ado_codigo,
                 STRING_AGG(idi.idi_nombre, N'/') WITHIN GROUP (ORDER BY idi.idi_nombre) AS ado_idioma
        FROM     sgspi.activo_documental_idioma AS adi
                 INNER JOIN
                 sgspi.idioma_catalogo AS idi
                 ON idi.idi_codigo = adi.idi_codigo
        GROUP BY adi.ado_codigo),
       -- [AP-08] El formato documental ahora es multivaluado normalizado ([adf] + [fac])
       cte_formatos_doc
AS     (SELECT   adf.ado_codigo,
                 STRING_AGG(fac.fac_nombre, N'/') WITHIN GROUP (ORDER BY fac.fac_nombre) AS ado_formato_documental
        FROM     sgspi.activo_documental_formato_archivo AS adf
                 INNER JOIN
                 sgspi.formato_archivo_catalogo AS fac
                 ON fac.fac_codigo = adf.fac_codigo
        GROUP BY adf.ado_codigo)
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
       ON tac.tac_codigo = aci.tac_codigo
       INNER JOIN
       sgspi.periodo_vigencia AS pv
       ON pv.pev_codigo = ado.pev_codigo
       INNER JOIN
       sgspi.serie_documental_catalogo AS sdo
       ON sdo.sdo_codigo = ado.sdo_codigo
       INNER JOIN
       sgspi.periodicidad_catalogo AS pdc
       ON pdc.pdc_codigo = ado.pdc_codigo
       INNER JOIN
       sgspi.estado_publicacion_catalogo AS epc
       ON epc.epc_codigo = ado.epc_codigo
       LEFT OUTER JOIN
       sgspi.subserie_documental_catalogo AS sbd
       ON sbd.sdo_codigo = ado.sdo_codigo
          AND sbd.sbd_codigo = ado.sbd_codigo
       LEFT OUTER JOIN
       sgspi.causal_excepcion_transparencia AS cet
       ON cet.cet_codigo = aci.cet_codigo
       LEFT OUTER JOIN
       cte_trd_agregado AS trd
       ON trd.ado_codigo = ado.ado_codigo
       LEFT OUTER JOIN
       cte_procesos_doc AS pdoc
       ON pdoc.aci_codigo = aci.aci_codigo
       LEFT OUTER JOIN
       cte_dependencias_doc AS ddoc
       ON ddoc.aci_codigo = aci.aci_codigo
       LEFT OUTER JOIN
       cte_propietarios_doc AS prop
       ON prop.aci_codigo = aci.aci_codigo
       LEFT OUTER JOIN
       cte_custodios_doc AS cust
       ON cust.aci_codigo = aci.aci_codigo
       LEFT OUTER JOIN
       cte_soportes_doc AS sdoc
       ON sdoc.ado_codigo = ado.ado_codigo
       LEFT OUTER JOIN
       cte_medios_doc AS mdoc
       ON mdoc.ado_codigo = ado.ado_codigo
       LEFT OUTER JOIN
       cte_idiomas_doc AS idoc
       ON idoc.ado_codigo = ado.ado_codigo
       LEFT OUTER JOIN
       cte_formatos_doc AS fdoc
       ON fdoc.ado_codigo = ado.ado_codigo;


GO
IF @@TRANCOUNT = 0 SET NOEXEC ON; -- [AP-19]
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
         ON enc.enc_codigo = crn.enc_codigo
         LEFT OUTER JOIN
         sgspi.control_referencia_normativa_atributo AS cra
         ON cra.crn_codigo = crn.crn_codigo
         LEFT OUTER JOIN
         sgspi.atributo_control_catalogo AS aac
         ON aac.aac_codigo = cra.aac_codigo
GROUP BY crn.crn_codigo,
         enc.enc_identificador,
         crn.crn_identificador_control,
         crn.crn_nombre_control;


GO
IF @@TRANCOUNT = 0 SET NOEXEC ON; -- [AP-19]
GO
COMMIT TRANSACTION; -- [AP-19]
GO
SET NOEXEC OFF;
GO
