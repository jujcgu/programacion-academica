/*==================================================================================================
  PROYECTO:     Sistema de Gestión de Seguridad y Privacidad de la Información (SGSPI)
  ENTIDAD:      Universidad Surcolombiana (USCO)
  BASE DATOS:   Integrado con el esquema corporativo [dbo] de la USCO (academia3000)
  MOTOR BD:     Microsoft SQL Server 2019 (Compatibilidad 150)
  CONVENCIÓN:   Estándar Institucional USCO (academia3000):
                1. Todas las llaves primarias y foráneas usan el sufijo [_codigo] (cero [_id]).
                2. Todas las columnas (incluidas llaves primarias, foráneas y de control) inician
                   estrictamente con el acrónimo de 3 letras de su tabla local ([<acr>_...]):
                   - Llave primaria: [<acr>_codigo]
                   - Llave foránea simple: [<acr_local>_<acr_remoto>_codigo] (ej. [acf_pev_codigo])
                   - Llave foránea con rol: [<acr_local>_<acr_remoto>_codigo_<rol>] (ej. [eia_aci_codigo_primario])

  MAPA DE ACRÓNIMOS DE TABLAS DEL ESQUEMA [sgspi] (48 TABLAS):
  - [pev] : sgspi.periodo_vigencia                  - [epc] : sgspi.estado_publicacion_catalogo
  - [dfc] : sgspi.dominio_formato_catalogo          - [src] : sgspi.soporte_registro_catalogo
  - [fdv] : sgspi.formato_documental_version        - [mcc] : sgspi.medio_conservacion_catalogo
  - [tpr] : sgspi.tipo_proceso_catalogo             - [idi] : sgspi.idioma_catalogo
  - [pri] : sgspi.proceso_institucional             - [ado] : sgspi.activo_documental (Subtipo 1:1 de [aci])
  - [piu] : sgspi.proceso_institucional_uaa         - [ads] : sgspi.activo_documental_soporte_registro
  - [fec] : sgspi.factor_entorno_catalogo           - [adm] : sgspi.activo_documental_medio_conservacion
  - [acf] : sgspi.analisis_contexto_factor          - [adi] : sgspi.activo_documental_idioma
  - [pai] : sgspi.parte_interesada                  - [adu] : sgspi.activo_documental_unidad_productora
  - [rpi] : sgspi.requisito_parte_interesada        - [epr] : sgspi.escala_probabilidad
  - [rpc] : sgspi.requisito_parte_interesada_cuestionario - [eim] : sgspi.escala_impacto
  - [rpp] : sgspi.requisito_parte_interesada_proceso_institucional - [mvr] : sgspi.matriz_valoracion_riesgo
  - [tac] : sgspi.tipo_activo_catalogo              - [eia] : sgspi.evento_incertidumbre_activo
  - [cet] : sgspi.causal_excepcion_transparencia    - [etc] : sgspi.estrategia_tratamiento_catalogo
  - [aci] : sgspi.activo_informacion (Supertipo)    - [plt] : sgspi.plan_tratamiento
  - [aip] : sgspi.activo_informacion_proceso_institucional - [act] : sgspi.actividad_tratamiento
  - [ais] : sgspi.activo_informacion_sede           - [sga] : sgspi.seguimiento_actividad
  - [air] : sgspi.activo_informacion_responsable    - [enc] : sgspi.estandar_normativo_catalogo
  - [sif] : sgspi.sistema_informacion_ficha         - [crn] : sgspi.control_referencia_normativa
  - [msi] : sgspi.modulo_sistema_informacion        - [cps] : sgspi.control_propiedad_seguridad
  - [sdo] : sgspi.serie_documental_catalogo         - [ccc] : sgspi.control_concepto_ciberseguridad
  - [sbd] : sgspi.subserie_documental_catalogo      - [ptc] : sgspi.plan_tratamiento_control_referencia_normativa
  - [upc] : sgspi.unidad_productora_cuadro_clasificacion_documental - [eac] : sgspi.evaluacion_aplicabilidad_control
  - [pdc] : sgspi.periodicidad_catalogo             - [bas] : sgspi.bitacora_auditoria_sistema

  ACRÓNIMOS REUTILIZADOS DEL ESQUEMA CORPORATIVO [dbo]:
  - [sus] : dbo.sub_sede ([sus_codigo])             - [car] : dbo.cargo ([car_codigo])
  - [esp] : dbo.espacio ([esp_codigo])              - [per] : dbo.persona ([per_codigo])
  - [uaa] : dbo.uaa ([uaa_codigo])                  - [gru] : dbo.grupo ([gru_codigo])
                                                    - [usg] : dbo.usuario_grupo ([usg_codigo])
==================================================================================================*/
SET NOCOUNT ON;

SET XACT_ABORT ON;


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
    pev_estado_vigencia NVARCHAR (20) DEFAULT N'ABIERTA' NOT NULL,
    pev_fecha_creacion  DATETIME2 (0) DEFAULT SYSDATETIME() NOT NULL,
    CONSTRAINT PK_pev_periodo_vigencia PRIMARY KEY CLUSTERED (pev_codigo),
    CONSTRAINT UQ_pev_anio UNIQUE (pev_anio),
    CONSTRAINT CK_pev_estado_vigencia CHECK (pev_estado_vigencia IN (N'EN_CONFIGURACION', N'ABIERTA', N'CERRADA', N'HISTORICA')),
    CONSTRAINT CK_pev_fechas CHECK (pev_fecha_cierre IS NULL
                                    OR pev_fecha_cierre >= pev_fecha_apertura)
);

-- 1.2 [dfc] y [fdv] Catálogo Extensible de Dominios de Formato y Control de Versiones SGC/SGSPI por Vigencia
CREATE TABLE sgspi.dominio_formato_catalogo (
    dfc_codigo        SMALLINT       IDENTITY (1, 1) NOT NULL,
    dfc_identificador NVARCHAR (40)  NOT NULL, -- Ej: 'CONTEXTO_DOFA', 'PARTES_INTERESADAS', 'ACTIVOS_DOCUMENTALES', 'INVENTARIO_ACTIVOS', 'RIESGOS_Y_OPORTUNIDADES'
    dfc_nombre        NVARCHAR (120) NOT NULL,
    dfc_descripcion   NVARCHAR (255) NULL,
    dfc_esta_activo   BIT            DEFAULT 1 NOT NULL,
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
    fdv_es_version_activa      BIT            DEFAULT 1 NOT NULL,
    CONSTRAINT PK_fdv_formato_documental_version PRIMARY KEY CLUSTERED (fdv_codigo),
    CONSTRAINT UQ_fdv_vigencia_dominio UNIQUE (fdv_pev_codigo, fdv_dfc_codigo),
    CONSTRAINT FK_fdv_periodo_vigencia FOREIGN KEY (fdv_pev_codigo) REFERENCES sgspi.periodo_vigencia (pev_codigo),
    CONSTRAINT FK_fdv_dominio_formato FOREIGN KEY (fdv_dfc_codigo) REFERENCES sgspi.dominio_formato_catalogo (dfc_codigo)
);

CREATE NONCLUSTERED INDEX IX_fdv_dfc_codigo
    ON sgspi.formato_documental_version (fdv_dfc_codigo);

-- 1.3 [tpr] Catálogo Extensible de Tipos de Proceso del Sistema Integrado de Gestión (MIPG / SGC)
CREATE TABLE sgspi.tipo_proceso_catalogo (
    tpr_codigo        TINYINT        IDENTITY (1, 1) NOT NULL,
    tpr_identificador NVARCHAR (20)  NOT NULL,
    tpr_nombre        NVARCHAR (50)  NOT NULL, -- Ej: 'ESTRATÉGICO', 'MISIONAL', 'APOYO', 'EVALUACIÓN'
    tpr_descripcion   NVARCHAR (255) NULL,
    tpr_esta_activo   BIT            DEFAULT 1 NOT NULL,
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
    pri_esta_activo      BIT            DEFAULT 1 NOT NULL,
    CONSTRAINT PK_pri_proceso_institucional PRIMARY KEY CLUSTERED (pri_codigo),
    CONSTRAINT UQ_pri_nombre UNIQUE (pri_nombre),
    CONSTRAINT FK_pri_tipo_proceso FOREIGN KEY (pri_tpr_codigo) REFERENCES sgspi.tipo_proceso_catalogo (tpr_codigo),
    CONSTRAINT FK_pri_dbo_uaa_lider FOREIGN KEY (pri_uaa_codigo_lider) REFERENCES dbo.uaa (uaa_codigo),
    CONSTRAINT FK_pri_dbo_cargo_lider FOREIGN KEY (pri_car_codigo_lider) REFERENCES dbo.cargo (car_codigo)
);

CREATE NONCLUSTERED INDEX IX_pri_tpr_codigo
    ON sgspi.proceso_institucional (pri_tpr_codigo);
CREATE NONCLUSTERED INDEX IX_pri_uaa_codigo_lider
    ON sgspi.proceso_institucional (pri_uaa_codigo_lider);
CREATE NONCLUSTERED INDEX IX_pri_car_codigo_lider
    ON sgspi.proceso_institucional (pri_car_codigo_lider);

-- 1.5 [piu] Tabla Puente N:M Proceso Institucional <-> Unidades Académico-Administrativas ([dbo].[uaa])
CREATE TABLE sgspi.proceso_institucional_uaa (
    piu_pri_codigo               INT NOT NULL, -- FK a [sgspi].[proceso_institucional]([pri_codigo])
    piu_uaa_codigo               INT NOT NULL, -- FK a [dbo].[uaa]([uaa_codigo])
    piu_es_responsable_principal BIT DEFAULT 0 NOT NULL,
    CONSTRAINT PK_piu_proceso_institucional_uaa PRIMARY KEY CLUSTERED (piu_pri_codigo, piu_uaa_codigo),
    CONSTRAINT FK_piu_proceso_institucional FOREIGN KEY (piu_pri_codigo) REFERENCES sgspi.proceso_institucional (pri_codigo) ON DELETE CASCADE,
    CONSTRAINT FK_piu_dbo_uaa FOREIGN KEY (piu_uaa_codigo) REFERENCES dbo.uaa (uaa_codigo)
);

CREATE NONCLUSTERED INDEX IX_piu_uaa_codigo
    ON sgspi.proceso_institucional_uaa (piu_uaa_codigo)
    INCLUDE (piu_es_responsable_principal);


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
    acf_nivel_prioridad         NVARCHAR (10)   NOT NULL, -- 'ALTA', 'MEDIA', 'BAJA'
    acf_impacto_sistema_gestion NVARCHAR (1000) NULL,
    acf_accion_propuesta        NVARCHAR (1000) NULL,
    acf_estado_registro         NVARCHAR (30)   DEFAULT N'BORRADOR' NOT NULL,
    acf_per_codigo_creador      INT             NOT NULL, -- FK a [dbo].[persona]([per_codigo])
    acf_per_codigo_aprobador    INT             NULL, -- FK a [dbo].[persona]([per_codigo])
    acf_fecha_creacion          DATETIME2 (0)   DEFAULT SYSDATETIME() NOT NULL,
    acf_fecha_actualizacion     DATETIME2 (0)   DEFAULT SYSDATETIME() NOT NULL,
    CONSTRAINT PK_acf_analisis_contexto_factor PRIMARY KEY CLUSTERED (acf_codigo),
    CONSTRAINT UQ_acf_vigencia_naturaleza_numero UNIQUE (acf_pev_codigo, acf_naturaleza_factor, acf_numero_factor),
    CONSTRAINT FK_acf_periodo_vigencia FOREIGN KEY (acf_pev_codigo) REFERENCES sgspi.periodo_vigencia (pev_codigo),
    CONSTRAINT FK_acf_proceso_institucional FOREIGN KEY (acf_pri_codigo) REFERENCES sgspi.proceso_institucional (pri_codigo),
    CONSTRAINT FK_acf_factor_entorno FOREIGN KEY (acf_fec_codigo) REFERENCES sgspi.factor_entorno_catalogo (fec_codigo),
    CONSTRAINT FK_acf_dbo_persona_creador FOREIGN KEY (acf_per_codigo_creador) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT FK_acf_dbo_persona_aprobador FOREIGN KEY (acf_per_codigo_aprobador) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_acf_naturaleza_factor CHECK (acf_naturaleza_factor IN (N'DEBILIDAD', N'FORTALEZA', N'AMENAZA', N'OPORTUNIDAD')),
    CONSTRAINT CK_acf_numero_factor_positivo CHECK (acf_numero_factor >= 1),
    CONSTRAINT CK_acf_nivel_prioridad CHECK (acf_nivel_prioridad IN (N'ALTA', N'MEDIA', N'BAJA')),
    -- RN-DOFA-03: Si la prioridad es ALTA y no está en borrador, exige Impacto y Acción Propuesta
    CONSTRAINT CK_acf_prioridad_alta_campos CHECK (acf_estado_registro = N'BORRADOR'
                                                   OR acf_nivel_prioridad <> N'ALTA'
                                                   OR (LEN(TRIM(ISNULL(acf_impacto_sistema_gestion, N''))) > 0
                                                       AND LEN(TRIM(ISNULL(acf_accion_propuesta, N''))) > 0)),
    CONSTRAINT CK_acf_estado_registro CHECK (acf_estado_registro IN (N'BORRADOR', N'EN_VALIDACION_LIDER', N'EN_REVISION_SGSPI', N'OBSERVADO', N'VIGENTE', N'HISTORICO'))
);

CREATE NONCLUSTERED INDEX IX_acf_pev_codigo
    ON sgspi.analisis_contexto_factor (acf_pev_codigo, acf_naturaleza_factor)
    INCLUDE (acf_numero_factor, acf_identificador_factor, acf_pri_codigo, acf_fec_codigo);
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
    pai_esta_activa     BIT            DEFAULT 1 NOT NULL,
    CONSTRAINT PK_pai_parte_interesada PRIMARY KEY CLUSTERED (pai_codigo),
    CONSTRAINT UQ_pai_nombre UNIQUE (pai_nombre),
    CONSTRAINT CK_pai_origen CHECK (pai_origen IN (N'INTERNA', N'EXTERNA'))
);

-- 3.2 [rpi] Necesidades, Expectativas y Requisitos por Parte Interesada
CREATE TABLE sgspi.requisito_parte_interesada (
    rpi_codigo                INT             IDENTITY (1, 1) NOT NULL,
    rpi_pev_codigo            SMALLINT        NOT NULL, -- FK a [sgspi].[periodo_vigencia]([pev_codigo])
    rpi_pai_codigo            INT             NOT NULL, -- FK a [sgspi].[parte_interesada]([pai_codigo])
    rpi_necesidad_expectativa NVARCHAR (1000) NOT NULL,
    rpi_nivel_poder           NVARCHAR (10)   NOT NULL, -- 'ALTA', 'MEDIA', 'BAJA'
    rpi_nivel_interes         NVARCHAR (10)   NOT NULL, -- 'ALTA', 'MEDIA', 'BAJA'
    -- Campo Calculado en Tiempo de Ejecución #3: Clasificación según Poder vs Interés (Código de dominio desacoplado de textos de UI)
    rpi_clasificacion_impacto AS             (CASE WHEN rpi_nivel_poder = N'ALTA'
                                                        AND rpi_nivel_interes IN (N'ALTA', N'MEDIA') THEN N'CUIDADO' WHEN (rpi_nivel_poder = N'ALTA'
                                                                                                                           AND rpi_nivel_interes = N'BAJA')
                                                                                                                          OR (rpi_nivel_poder = N'MEDIA'
                                                                                                                              AND rpi_nivel_interes IN (N'ALTA', N'MEDIA')) THEN N'ATENCION' WHEN (rpi_nivel_poder = N'MEDIA'
                                                                                                                                                                                                   AND rpi_nivel_interes = N'BAJA')
                                                                                                                                                                                                  OR (rpi_nivel_poder = N'BAJA'
                                                                                                                                                                                                      AND rpi_nivel_interes = N'ALTA') THEN N'MITIGANTE' ELSE N'SIN_PROBLEMA' END) PERSISTED,
    rpi_nivel_cumplimiento    NVARCHAR (10)  NULL, -- 'ALTA', 'MEDIA', 'BAJA' (NULL cuando aún no se ha evaluado)
    -- Campo Calculado en Tiempo de Ejecución #4: Prioridad de Acción (Inversamente proporcional al cumplimiento: Cumplimiento BAJA -> Prioridad ALTA)
    rpi_prioridad_accion      AS             (CASE rpi_nivel_cumplimiento WHEN N'BAJA' THEN N'ALTA' WHEN N'MEDIA' THEN N'MEDIA' WHEN N'ALTA' THEN N'BAJA' ELSE NULL END) PERSISTED,
    rpi_mecanismo_seguimiento NVARCHAR (255) NULL,
    rpi_estado_registro       NVARCHAR (30)  DEFAULT N'VIGENTE' NOT NULL,
    rpi_fecha_creacion        DATETIME2 (0)  DEFAULT SYSDATETIME() NOT NULL,
    rpi_fecha_actualizacion   DATETIME2 (0)  DEFAULT SYSDATETIME() NOT NULL,
    CONSTRAINT PK_rpi_requisito_parte_interesada PRIMARY KEY CLUSTERED (rpi_codigo),
    CONSTRAINT FK_rpi_periodo_vigencia FOREIGN KEY (rpi_pev_codigo) REFERENCES sgspi.periodo_vigencia (pev_codigo),
    CONSTRAINT FK_rpi_parte_interesada FOREIGN KEY (rpi_pai_codigo) REFERENCES sgspi.parte_interesada (pai_codigo),
    CONSTRAINT CK_rpi_nivel_poder CHECK (rpi_nivel_poder IN (N'ALTA', N'MEDIA', N'BAJA')),
    CONSTRAINT CK_rpi_nivel_interes CHECK (rpi_nivel_interes IN (N'ALTA', N'MEDIA', N'BAJA')),
    CONSTRAINT CK_rpi_nivel_cumplimiento CHECK (rpi_nivel_cumplimiento IS NULL
                                                OR rpi_nivel_cumplimiento IN (N'ALTA', N'MEDIA', N'BAJA')),
    CONSTRAINT CK_rpi_estado_registro CHECK (rpi_estado_registro IN (N'BORRADOR', N'EN_VALIDACION_LIDER', N'EN_REVISION_SGSPI', N'OBSERVADO', N'VIGENTE', N'HISTORICO'))
);

CREATE NONCLUSTERED INDEX IX_rpi_pev_codigo
    ON sgspi.requisito_parte_interesada (rpi_pev_codigo);
CREATE NONCLUSTERED INDEX IX_rpi_pai_codigo
    ON sgspi.requisito_parte_interesada (rpi_pai_codigo);

-- 3.3 [rpc] Referencias Atómicas a Preguntas del Cuestionario por Requisito (Elimina listas multivaluadas como '6-7-8')
CREATE TABLE sgspi.requisito_parte_interesada_cuestionario (
    rpc_rpi_codigo      INT      NOT NULL, -- FK a [sgspi].[requisito_parte_interesada]([rpi_codigo])
    rpc_numero_pregunta SMALLINT NOT NULL, -- Número atómico de pregunta del cuestionario (ej. 6, 7, 8)
    CONSTRAINT PK_rpc_requisito_parte_interesada_cuestionario PRIMARY KEY CLUSTERED (rpc_rpi_codigo, rpc_numero_pregunta),
    CONSTRAINT FK_rpc_requisito_parte_interesada FOREIGN KEY (rpc_rpi_codigo) REFERENCES sgspi.requisito_parte_interesada (rpi_codigo),
    CONSTRAINT CK_rpc_numero_pregunta_positivo CHECK (rpc_numero_pregunta >= 1)
);

CREATE NONCLUSTERED INDEX IX_rpc_numero_pregunta
    ON sgspi.requisito_parte_interesada_cuestionario (rpc_numero_pregunta)
    INCLUDE (rpc_rpi_codigo);

-- 3.4 [rpp] Relación N:M Requisito de Parte Interesada <-> Proceso Institucional
CREATE TABLE sgspi.requisito_parte_interesada_proceso_institucional (
    rpp_rpi_codigo     INT           NOT NULL, -- FK a [sgspi].[requisito_parte_interesada]([rpi_codigo])
    rpp_pri_codigo     INT           NOT NULL, -- FK a [sgspi].[proceso_institucional]([pri_codigo])
    rpp_fecha_registro DATETIME2 (0) DEFAULT SYSDATETIME() NOT NULL,
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
-- 4.1 [tac] Catálogo Extensible de Taxonomía Jerárquica de Activos ISO/IEC 27005 (Categoría -> Tipo -> Subtipo)
CREATE TABLE sgspi.tipo_activo_catalogo (
    tac_codigo              SMALLINT       IDENTITY (1, 1) NOT NULL,
    tac_categoria_iso27005  NVARCHAR (40)  NOT NULL, -- Ej: 'Primario', 'Soporte'
    tac_tipo_activo         NVARCHAR (80)  NOT NULL, -- Ej: 'Información', 'Procesos y Actividades del Negocio', 'Hardware', 'Software', 'Red', 'Personal', 'Sitio', 'Estructura de la organización', 'Ubicación', 'Servicios'
    tac_subtipo_activo      NVARCHAR (120) NOT NULL, -- Ej: 'Servidor de Aplicaciones', 'Equipo de Computo', 'Aplicaciones Específicas del Negocio', etc.
    tac_ejemplos_referencia NVARCHAR (255) NULL,
    tac_esta_activo         BIT            DEFAULT 1 NOT NULL,
    CONSTRAINT PK_tac_tipo_activo_catalogo PRIMARY KEY CLUSTERED (tac_codigo),
    CONSTRAINT UQ_tac_jerarquia UNIQUE (tac_categoria_iso27005, tac_tipo_activo, tac_subtipo_activo),
    CONSTRAINT CK_tac_jerarquia_no_vacia CHECK (LEN(TRIM(tac_categoria_iso27005)) > 0
                                                AND LEN(TRIM(tac_tipo_activo)) > 0
                                                AND LEN(TRIM(tac_subtipo_activo)) > 0)
);

-- 4.2 [cet] Catálogo de Causales de Excepción de Transparencia (Desacoplado de Ley 1712 de 2014)
CREATE TABLE sgspi.causal_excepcion_transparencia (
    cet_codigo                  SMALLINT       IDENTITY (1, 1) NOT NULL,
    cet_nivel_reserva_aplicable NVARCHAR (20)  NOT NULL, -- 'CLASIFICADA' (3 causales) o 'RESERVADA' (9 causales)
    cet_numeral_causal          NVARCHAR (10)  NOT NULL,
    cet_descripcion_causal      NVARCHAR (500) NOT NULL,
    cet_norma_referencia        NVARCHAR (100) DEFAULT N'Ley 1712 de 2014' NOT NULL,
    CONSTRAINT PK_cet_causal_excepcion_transparencia PRIMARY KEY CLUSTERED (cet_codigo),
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
    aci_es_transversal_sedes            BIT             DEFAULT 0 NOT NULL,
    aci_cantidad_unidades               INT             DEFAULT 1 NOT NULL,
    -- Clasificación de Transparencia e Índice de Información Clasificada y Reservada (Ley 1712 de 2014 / Decreto 103 de 2015)
    aci_clasificacion_transparencia     NVARCHAR (20)   NOT NULL, -- 'PÚBLICA', 'CLASIFICADA', 'RESERVADA', 'NO CLASIFICADA'
    aci_cet_codigo                      SMALLINT        NULL, -- FK a [sgspi].[causal_excepcion_transparencia]([cet_codigo]) (NULL cuando es PÚBLICA o NO CLASIFICADA)
    aci_alcance_excepcion               NVARCHAR (15)   NULL, -- 'PARCIAL', 'TOTAL' (NULL cuando es PÚBLICA o NO CLASIFICADA)
    aci_fundamento_constitucional_legal NVARCHAR (150)  NULL, -- Ej: 'Ley 1712 de 2014' (NULL cuando no aplica reserva)
    aci_fundamento_juridico_excepcion   NVARCHAR (150)  NULL, -- Norma o disposición específica de reserva (NULL cuando no aplica reserva)
    aci_fecha_clasificacion_reserva     DATE            NULL, -- NULL cuando no aplica reserva
    aci_es_reserva_indefinida           BIT             NULL, -- 1=Indefinida, 0=Plazo definido en años, NULL=No aplica reserva (elimina texto libre 'Indefinida')
    aci_anios_plazo_reserva             SMALLINT        NULL, -- Plazo numérico en años (ej. 15 años según Art. 22 Ley 1712/2014; NULL cuando es indefinida o no aplica)
    aci_fecha_vencimiento_reserva       AS              (CASE WHEN aci_es_reserva_indefinida = 0
                                                                   AND aci_fecha_clasificacion_reserva IS NOT NULL
                                                                   AND aci_anios_plazo_reserva IS NOT NULL THEN DATEADD(YEAR, aci_anios_plazo_reserva, aci_fecha_clasificacion_reserva) ELSE NULL END) PERSISTED,
    -- Protección de Datos Personales (Ley 1581 de 2012 / ISO 27701): Lógica booleana trivalente (BIT NULL en lugar de cadenas mágicas 'No Aplica')
    aci_contiene_datos_personales       BIT            DEFAULT 0 NOT NULL, -- 1=Sí, 0=No
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
    aci_supera_umbral_social_icc       BIT            DEFAULT 0 NOT NULL, -- > 250.000 personas
    aci_supera_umbral_economico_icc    BIT            DEFAULT 0 NOT NULL, -- > $464.619.736 COP
    aci_supera_umbral_ambiental_icc    BIT            DEFAULT 0 NOT NULL, -- >= 3 años en recuperación
    aci_es_infraestructura_critica_icc AS             (CASE WHEN aci_supera_umbral_social_icc = 1
                                                                 OR aci_supera_umbral_economico_icc = 1
                                                                 OR aci_supera_umbral_ambiental_icc = 1 THEN CAST (1 AS BIT) ELSE CAST (0 AS BIT) END),
    -- Control de ciclo de vida y auditoría (Apuntando a [dbo].[persona])
    aci_estado_registro                NVARCHAR (30)  DEFAULT N'VIGENTE' NOT NULL,
    aci_per_codigo_creador             INT            NOT NULL, -- FK a [dbo].[persona]([per_codigo])
    aci_per_codigo_aprobador           INT            NULL, -- FK a [dbo].[persona]([per_codigo])
    aci_fecha_creacion                 DATETIME2 (0)  DEFAULT SYSDATETIME() NOT NULL,
    aci_fecha_actualizacion            DATETIME2 (0)  DEFAULT SYSDATETIME() NOT NULL,
    CONSTRAINT PK_aci_activo_informacion PRIMARY KEY CLUSTERED (aci_codigo),
    CONSTRAINT UQ_aci_codigo_inventario UNIQUE (aci_codigo_inventario),
    CONSTRAINT FK_aci_tipo_activo FOREIGN KEY (aci_tac_codigo) REFERENCES sgspi.tipo_activo_catalogo (tac_codigo),
    CONSTRAINT FK_aci_dbo_uaa FOREIGN KEY (aci_uaa_codigo) REFERENCES dbo.uaa (uaa_codigo),
    CONSTRAINT FK_aci_dbo_espacio FOREIGN KEY (aci_esp_codigo) REFERENCES dbo.espacio (esp_codigo),
    CONSTRAINT FK_aci_causal_excepcion FOREIGN KEY (aci_cet_codigo) REFERENCES sgspi.causal_excepcion_transparencia (cet_codigo),
    CONSTRAINT FK_aci_dbo_persona_creador FOREIGN KEY (aci_per_codigo_creador) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT FK_aci_dbo_persona_aprobador FOREIGN KEY (aci_per_codigo_aprobador) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_aci_valores_cid CHECK (aci_valor_confidencialidad IN (1, 2, 3)
                                         AND aci_valor_integridad IN (1, 2, 3)
                                         AND aci_valor_disponibilidad IN (1, 2, 3)),
    CONSTRAINT CK_aci_transparencia CHECK (aci_clasificacion_transparencia IN (N'PÚBLICA', N'CLASIFICADA', N'RESERVADA', N'NO CLASIFICADA')),
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
                                                       OR (aci_clasificacion_transparencia IN (N'PÚBLICA', N'NO CLASIFICADA')
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
                                                          OR NOT (aci_clasificacion_transparencia = N'PÚBLICA'
                                                                  AND aci_valor_confidencialidad = 1)),
    CONSTRAINT CK_aci_estado_registro CHECK (aci_estado_registro IN (N'BORRADOR', N'EN_VALIDACION_LIDER', N'EN_REVISION_ARCHIVO', N'EN_REVISION_SGSPI', N'OBSERVADO', N'VIGENTE', N'INACTIVO', N'HISTORICO'))
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
    air_esta_activo          BIT           DEFAULT 1 NOT NULL,
    -- Clave primaria compuesta 100% NOT NULL (elimina UNIQUE sobre columnas NULL [uap_codigo]/[uac_codigo] y unifica [air] + [adr])
    CONSTRAINT PK_air_activo_informacion_responsable PRIMARY KEY CLUSTERED (air_aci_codigo, air_car_codigo, air_uaa_codigo, air_tipo_responsabilidad),
    CONSTRAINT FK_air_activo_informacion FOREIGN KEY (air_aci_codigo) REFERENCES sgspi.activo_informacion (aci_codigo),
    CONSTRAINT FK_air_dbo_cargo FOREIGN KEY (air_car_codigo) REFERENCES dbo.cargo (car_codigo),
    CONSTRAINT FK_air_dbo_uaa FOREIGN KEY (air_uaa_codigo) REFERENCES dbo.uaa (uaa_codigo),
    CONSTRAINT CK_air_tipo_responsabilidad CHECK (air_tipo_responsabilidad IN (N'PROPIETARIO', N'CUSTODIO'))
);

CREATE NONCLUSTERED INDEX IX_air_car_codigo
    ON sgspi.activo_informacion_responsable (air_car_codigo)
    INCLUDE (air_aci_codigo, air_tipo_responsabilidad, air_esta_activo);
CREATE NONCLUSTERED INDEX IX_air_uaa_codigo
    ON sgspi.activo_informacion_responsable (air_uaa_codigo)
    INCLUDE (air_aci_codigo, air_esta_activo);

-- 4.5 [sif] y [msi] Ficha Técnica de Sistemas de Información y sus Módulos (Los 17 Sistemas USCO)
CREATE TABLE sgspi.sistema_informacion_ficha (
    sif_codigo               INT             IDENTITY (1, 1) NOT NULL,
    sif_aci_codigo           INT             NULL, -- FK a [sgspi].[activo_informacion]([aci_codigo])
    sif_nombre_sistema       NVARCHAR (150)  NOT NULL,
    sif_modalidad_desarrollo NVARCHAR (50)   NOT NULL, -- 'PROPIO', 'PROPIO EN DESARROLLO', 'CODIGO ABIERTO ADAPTADO', 'COMERCIAL TERCERO'
    sif_fabricante_proveedor NVARCHAR (150)  NULL,
    sif_descripcion_general  NVARCHAR (1000) NOT NULL,
    CONSTRAINT PK_sif_sistema_informacion_ficha PRIMARY KEY CLUSTERED (sif_codigo),
    CONSTRAINT UQ_sif_nombre_sistema UNIQUE (sif_nombre_sistema),
    CONSTRAINT FK_sif_activo_informacion FOREIGN KEY (sif_aci_codigo) REFERENCES sgspi.activo_informacion (aci_codigo)
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
    CONSTRAINT FK_msi_sistema_informacion FOREIGN KEY (msi_sif_codigo) REFERENCES sgspi.sistema_informacion_ficha (sif_codigo) ON DELETE CASCADE
);

CREATE NONCLUSTERED INDEX IX_msi_sif_codigo
    ON sgspi.modulo_sistema_informacion (msi_sif_codigo);


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
    sdo_tiene_subseries BIT            DEFAULT 1 NOT NULL, -- 0 cuando la serie es directa (ej. CIRCULARES, RESOLUCIONES, HISTORIAS LABORALES)
    sdo_esta_activa     BIT            DEFAULT 1 NOT NULL,
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
    sbd_esta_activa     BIT            DEFAULT 1 NOT NULL,
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
    upc_nodo_jerarquico      HIERARCHYID    NOT NULL, -- Ruta nativa HIERARCHYID (ej. '/1/', '/1/1/', '/1/1/1/', '/5/1/1/2/')
    upc_nodo_padre           AS             (NULLIF(upc_nodo_jerarquico.GetAncestor(1), hierarchyid::GetRoot())) PERSISTED, -- Padre directo determinístico (NULL en nivel 1)
    upc_nivel_jerarquico     AS             (upc_nodo_jerarquico.GetLevel()) PERSISTED, -- Nivel calculado automáticamente por el motor (1=Sección, 2=Subsección, 3..N=Subdivisiones)
    upc_prefijo_archivistico AS             (CONVERT (NVARCHAR (50), REPLACE(TRIM(N'/' FROM upc_nodo_jerarquico.ToString()), N'/', N'.'))) PERSISTED, -- Prefijo CCD derivado sin redundancia (ej. '1', '1.1', '5.1.1.2')
    upc_uaa_codigo           INT            NULL, -- FK a [dbo].[uaa]([uaa_codigo]): Equivalencia organizacional en academia3000
    upc_nombre_unidad        NVARCHAR (150) NOT NULL, -- Ej: 'RECTORIA', 'SECRETARIA GENERAL', 'AREA GESTION DOCUMENTAL'
    upc_esta_activa          BIT            DEFAULT 1 NOT NULL,
    CONSTRAINT PK_upc_unidad_productora_cuadro_clasificacion_documental PRIMARY KEY CLUSTERED (upc_codigo),
    CONSTRAINT UQ_upc_nodo_jerarquico UNIQUE (upc_nodo_jerarquico),
    CONSTRAINT FK_upc_nodo_padre FOREIGN KEY (upc_nodo_padre) REFERENCES sgspi.unidad_productora_cuadro_clasificacion_documental (upc_nodo_jerarquico),
    CONSTRAINT FK_upc_dbo_uaa FOREIGN KEY (upc_uaa_codigo) REFERENCES dbo.uaa (uaa_codigo),
    CONSTRAINT CK_upc_nivel_jerarquico_valido CHECK (upc_nodo_jerarquico.GetLevel() >= 1
                                                     AND upc_nodo_jerarquico.ToString() NOT LIKE N'%.%'
                                                     AND upc_nodo_jerarquico.ToString() NOT LIKE N'%-%')
);

CREATE NONCLUSTERED INDEX IX_upc_busqueda_anchura
    ON sgspi.unidad_productora_cuadro_clasificacion_documental (upc_nivel_jerarquico, upc_nodo_jerarquico)
    INCLUDE (upc_prefijo_archivistico, upc_nombre_unidad);
CREATE NONCLUSTERED INDEX IX_upc_nodo_padre
    ON sgspi.unidad_productora_cuadro_clasificacion_documental (upc_nodo_padre)
    INCLUDE (upc_nivel_jerarquico, upc_prefijo_archivistico, upc_nombre_unidad);
CREATE NONCLUSTERED INDEX IX_upc_uaa_codigo
    ON sgspi.unidad_productora_cuadro_clasificacion_documental (upc_uaa_codigo);

-- 4B.4 [pdc], [epc], [src], [mcc], [idi] Catálogos Extensibles del Dominio Documental y Archivístico
CREATE TABLE sgspi.periodicidad_catalogo (
    pdc_codigo      SMALLINT      IDENTITY (1, 1) NOT NULL,
    pdc_nombre      NVARCHAR (40) NOT NULL, -- Ej: 'A solicitud', 'Diaria', 'Semanal', 'Mensual', 'Bimensual', 'Trimestral', 'Cuatrimestral', 'Semestral', 'Anual', 'Eventual'
    pdc_orden       TINYINT       DEFAULT 1 NOT NULL,
    pdc_esta_activa BIT           DEFAULT 1 NOT NULL,
    CONSTRAINT PK_pdc_periodicidad_catalogo PRIMARY KEY CLUSTERED (pdc_codigo),
    CONSTRAINT UQ_pdc_nombre UNIQUE (pdc_nombre),
    CONSTRAINT CK_pdc_nombre_no_vacio CHECK (LEN(TRIM(pdc_nombre)) > 0)
);

CREATE TABLE sgspi.estado_publicacion_catalogo (
    epc_codigo      SMALLINT       IDENTITY (1, 1) NOT NULL,
    epc_nombre      NVARCHAR (60)  NOT NULL, -- Ej: 'Publicada (Externo - Internet)', 'Publicada (Interno - Intranet)', 'No publicada'
    epc_descripcion NVARCHAR (255) NULL,
    epc_esta_activo BIT            DEFAULT 1 NOT NULL,
    CONSTRAINT PK_epc_estado_publicacion_catalogo PRIMARY KEY CLUSTERED (epc_codigo),
    CONSTRAINT UQ_epc_nombre UNIQUE (epc_nombre),
    CONSTRAINT CK_epc_nombre_no_vacio CHECK (LEN(TRIM(epc_nombre)) > 0)
);

CREATE TABLE sgspi.soporte_registro_catalogo (
    src_codigo      SMALLINT      IDENTITY (1, 1) NOT NULL,
    src_nombre      NVARCHAR (30) NOT NULL, -- Ej: 'Físico', 'Digital', 'Óptico'
    src_esta_activo BIT           DEFAULT 1 NOT NULL,
    CONSTRAINT PK_src_soporte_registro_catalogo PRIMARY KEY CLUSTERED (src_codigo),
    CONSTRAINT UQ_src_nombre UNIQUE (src_nombre),
    CONSTRAINT CK_src_nombre_no_vacio CHECK (LEN(TRIM(src_nombre)) > 0)
);

CREATE TABLE sgspi.medio_conservacion_catalogo (
    mcc_codigo      SMALLINT      IDENTITY (1, 1) NOT NULL,
    mcc_nombre      NVARCHAR (30) NOT NULL, -- Ej: 'Físico', 'Electrónico', 'Microfilm', 'Nube'
    mcc_esta_activo BIT           DEFAULT 1 NOT NULL,
    CONSTRAINT PK_mcc_medio_conservacion_catalogo PRIMARY KEY CLUSTERED (mcc_codigo),
    CONSTRAINT UQ_mcc_nombre UNIQUE (mcc_nombre),
    CONSTRAINT CK_mcc_nombre_no_vacio CHECK (LEN(TRIM(mcc_nombre)) > 0)
);

CREATE TABLE sgspi.idioma_catalogo (
    idi_codigo      SMALLINT      IDENTITY (1, 1) NOT NULL,
    idi_codigo_iso  NVARCHAR (10) NOT NULL, -- Ej: 'es', 'en', 'fr', 'pt' (ISO 639-1)
    idi_nombre      NVARCHAR (50) NOT NULL, -- Ej: 'Español', 'Inglés', 'Francés', 'Portugués'
    idi_esta_activo BIT           DEFAULT 1 NOT NULL,
    CONSTRAINT PK_idi_idioma_catalogo PRIMARY KEY CLUSTERED (idi_codigo),
    CONSTRAINT UQ_idi_codigo_iso UNIQUE (idi_codigo_iso),
    CONSTRAINT UQ_idi_nombre UNIQUE (idi_nombre),
    CONSTRAINT CK_idi_nombre_no_vacio CHECK (LEN(TRIM(idi_nombre)) > 0)
);

-- 4B.5 [ado] Subtipo 1:1 de Activo Documental (Especialización Archivística de [sgspi].[activo_informacion] para ES-GSPI-MR-04 con System-Versioned Temporal Table)
CREATE TABLE sgspi.activo_documental (
    ado_codigo                        INT                                         IDENTITY (1, 1) NOT NULL,
    ado_aci_codigo                    INT                                         NOT NULL, -- FK 1:1 obligatoria hacia el supertipo [sgspi].[activo_informacion]([aci_codigo])
    ado_pev_codigo                    SMALLINT                                    NOT NULL, -- FK a [sgspi].[periodo_vigencia]([pev_codigo])
    ado_sdo_codigo                    SMALLINT                                    NOT NULL, -- FK a [sgspi].[serie_documental_catalogo]([sdo_codigo])
    ado_sbd_codigo                    INT                                         NULL, -- FK nullable a [sgspi].[subserie_documental_catalogo]([sbd_codigo]) (NULL si la serie no tiene subserie)
    ado_tipo_activo_documental        NVARCHAR (80)                               DEFAULT N'Información y datos de la Universidad' NOT NULL,
    ado_pdc_codigo                    SMALLINT                                    NOT NULL, -- FK a [sgspi].[periodicidad_catalogo]([pdc_codigo])
    ado_formato_documental            NVARCHAR (100)                              DEFAULT N'Documento de texto' NOT NULL,
    ado_fecha_ingreso_tabla_retencion DATE                                        NULL,
    ado_fecha_ingreso_archivo         DATE                                        NULL,
    ado_epc_codigo                    SMALLINT                                    NOT NULL, -- FK a [sgspi].[estado_publicacion_catalogo]([epc_codigo])
    ado_lugar_consulta_ubicacion      NVARCHAR (255)                              NOT NULL, -- URL portal de transparencia o nombre de dependencia/archivo
    ado_per_codigo_revisor_archivo    INT                                         NULL, -- FK a [dbo].[persona]([per_codigo]): Aval específico Gestión Documental / Secretaría General
    ado_fecha_creacion                DATETIME2 (0)                               DEFAULT SYSDATETIME() NOT NULL,
    ado_fecha_actualizacion           DATETIME2 (0)                               DEFAULT SYSDATETIME() NOT NULL,
    ado_sys_inicio_utc                DATETIME2 (7) GENERATED ALWAYS AS ROW START HIDDEN DEFAULT SYSUTCDATETIME() NOT NULL,
    ado_sys_fin_utc                   DATETIME2 (7) GENERATED ALWAYS AS ROW END   HIDDEN DEFAULT CONVERT (DATETIME2 (7), '9999-12-31 23:59:59.9999999') NOT NULL,
    PERIOD FOR SYSTEM_TIME (ado_sys_inicio_utc, ado_sys_fin_utc),
    CONSTRAINT PK_ado_activo_documental PRIMARY KEY CLUSTERED (ado_codigo),
    CONSTRAINT UQ_ado_activo_informacion UNIQUE (ado_aci_codigo),
    CONSTRAINT FK_ado_activo_informacion FOREIGN KEY (ado_aci_codigo) REFERENCES sgspi.activo_informacion (aci_codigo),
    CONSTRAINT FK_ado_periodo_vigencia FOREIGN KEY (ado_pev_codigo) REFERENCES sgspi.periodo_vigencia (pev_codigo),
    CONSTRAINT FK_ado_serie_documental FOREIGN KEY (ado_sdo_codigo) REFERENCES sgspi.serie_documental_catalogo (sdo_codigo),
    CONSTRAINT FK_ado_subserie_documental FOREIGN KEY (ado_sdo_codigo, ado_sbd_codigo) REFERENCES sgspi.subserie_documental_catalogo (sbd_sdo_codigo, sbd_codigo),
    CONSTRAINT FK_ado_periodicidad FOREIGN KEY (ado_pdc_codigo) REFERENCES sgspi.periodicidad_catalogo (pdc_codigo),
    CONSTRAINT FK_ado_estado_publicacion FOREIGN KEY (ado_epc_codigo) REFERENCES sgspi.estado_publicacion_catalogo (epc_codigo),
    CONSTRAINT FK_ado_dbo_persona_revisor_archivo FOREIGN KEY (ado_per_codigo_revisor_archivo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_ado_tipo_activo_documental_no_vacio CHECK (LEN(TRIM(ado_tipo_activo_documental)) > 0)
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = sgspi.activo_documental_historial));

CREATE NONCLUSTERED INDEX IX_ado_pev_codigo
    ON sgspi.activo_documental (ado_pev_codigo, ado_sdo_codigo, ado_sbd_codigo)
    INCLUDE (ado_aci_codigo);
CREATE NONCLUSTERED INDEX IX_ado_sdo_codigo
    ON sgspi.activo_documental (ado_sdo_codigo, ado_sbd_codigo);
CREATE NONCLUSTERED INDEX IX_ado_sbd_codigo
    ON sgspi.activo_documental (ado_sbd_codigo);
CREATE NONCLUSTERED INDEX IX_ado_pdc_codigo
    ON sgspi.activo_documental (ado_pdc_codigo);
CREATE NONCLUSTERED INDEX IX_ado_epc_codigo
    ON sgspi.activo_documental (ado_epc_codigo);
CREATE NONCLUSTERED INDEX IX_ado_per_codigo_revisor_archivo
    ON sgspi.activo_documental (ado_per_codigo_revisor_archivo);

-- 4B.6 [ads], [adm], [adi] Tablas Puente N:M de Atributos Atómicos de Activos Documentales hacia Catálogos Extensibles
CREATE TABLE sgspi.activo_documental_soporte_registro (
    ads_ado_codigo INT      NOT NULL, -- FK a [sgspi].[activo_documental]([ado_codigo])
    ads_src_codigo SMALLINT NOT NULL, -- FK a [sgspi].[soporte_registro_catalogo]([src_codigo])
    CONSTRAINT PK_ads_activo_documental_soporte_registro PRIMARY KEY CLUSTERED (ads_ado_codigo, ads_src_codigo),
    CONSTRAINT FK_ads_activo_documental FOREIGN KEY (ads_ado_codigo) REFERENCES sgspi.activo_documental (ado_codigo),
    CONSTRAINT FK_ads_soporte_registro_catalogo FOREIGN KEY (ads_src_codigo) REFERENCES sgspi.soporte_registro_catalogo (src_codigo)
);

CREATE NONCLUSTERED INDEX IX_ads_src_codigo
    ON sgspi.activo_documental_soporte_registro (ads_src_codigo)
    INCLUDE (ads_ado_codigo);

CREATE TABLE sgspi.activo_documental_medio_conservacion (
    adm_ado_codigo INT      NOT NULL, -- FK a [sgspi].[activo_documental]([ado_codigo])
    adm_mcc_codigo SMALLINT NOT NULL, -- FK a [sgspi].[medio_conservacion_catalogo]([mcc_codigo])
    CONSTRAINT PK_adm_activo_documental_medio_conservacion PRIMARY KEY CLUSTERED (adm_ado_codigo, adm_mcc_codigo),
    CONSTRAINT FK_adm_activo_documental FOREIGN KEY (adm_ado_codigo) REFERENCES sgspi.activo_documental (ado_codigo),
    CONSTRAINT FK_adm_medio_conservacion_catalogo FOREIGN KEY (adm_mcc_codigo) REFERENCES sgspi.medio_conservacion_catalogo (mcc_codigo)
);

CREATE NONCLUSTERED INDEX IX_adm_mcc_codigo
    ON sgspi.activo_documental_medio_conservacion (adm_mcc_codigo)
    INCLUDE (adm_ado_codigo);

CREATE TABLE sgspi.activo_documental_idioma (
    adi_ado_codigo INT      NOT NULL, -- FK a [sgspi].[activo_documental]([ado_codigo])
    adi_idi_codigo SMALLINT NOT NULL, -- FK a [sgspi].[idioma_catalogo]([idi_codigo])
    CONSTRAINT PK_adi_activo_documental_idioma PRIMARY KEY CLUSTERED (adi_ado_codigo, adi_idi_codigo),
    CONSTRAINT FK_adi_activo_documental FOREIGN KEY (adi_ado_codigo) REFERENCES sgspi.activo_documental (ado_codigo),
    CONSTRAINT FK_adi_idioma_catalogo FOREIGN KEY (adi_idi_codigo) REFERENCES sgspi.idioma_catalogo (idi_codigo)
);

CREATE NONCLUSTERED INDEX IX_adi_idi_codigo
    ON sgspi.activo_documental_idioma (adi_idi_codigo)
    INCLUDE (adi_ado_codigo);

-- 4B.7 [adu] Asignación N:M Activo Documental <-> Unidad Productora del CCD/TRD (Modela las 240 filas de desglose TRD sin cadenas multivaluadas)
CREATE TABLE sgspi.activo_documental_unidad_productora (
    adu_ado_codigo  INT NOT NULL, -- FK a [sgspi].[activo_documental]([ado_codigo])
    adu_upc_codigo  INT NOT NULL, -- FK a [sgspi].[unidad_productora_cuadro_clasificacion_documental]([upc_codigo]) (Unidad más específica donde se produce la serie/subserie)
    adu_esta_activo BIT DEFAULT 1 NOT NULL,
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
-- 5.1 [epr], [eim], [mvr] Tablas Paramétricas del Mapa de Calor 5x5 (Probabilidad A..E x Impacto 1..5)
CREATE TABLE sgspi.escala_probabilidad (
    epr_codigo                TINYINT        NOT NULL, -- 5=A (Casi seguro), 4=B (Probable), 3=C (Posible), 2=D (Improbable), 1=E (Raro)
    epr_codigo_letra          CHAR (1)       NOT NULL, -- 'A', 'B', 'C', 'D', 'E'
    epr_nombre_nivel          NVARCHAR (30)  NOT NULL,
    epr_descripcion_criterio  NVARCHAR (255) NOT NULL,
    epr_frecuencia_referencia NVARCHAR (100) NOT NULL,
    CONSTRAINT PK_epr_escala_probabilidad PRIMARY KEY CLUSTERED (epr_codigo),
    CONSTRAINT UQ_epr_codigo_letra UNIQUE (epr_codigo_letra),
    CONSTRAINT CK_epr_rango CHECK (epr_codigo BETWEEN 1 AND 5
                                   AND epr_codigo_letra IN ('A', 'B', 'C', 'D', 'E'))
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

CREATE TABLE sgspi.matriz_valoracion_riesgo (
    mvr_epr_codigo                        TINYINT        NOT NULL, -- FK a [sgspi].[escala_probabilidad]([epr_codigo])
    mvr_eim_codigo                        TINYINT        NOT NULL, -- FK a [sgspi].[escala_impacto]([eim_codigo])
    mvr_codigo_posicion                   CHAR (2)       NOT NULL, -- 'A1'..'E5'
    mvr_codigo_zona                       CHAR (1)       NOT NULL, -- 'B' (Bajo), 'M' (Moderado), 'A' (Alto), 'E' (Extremo)
    mvr_nivel_valoracion                  NVARCHAR (30)  NOT NULL, -- 'Riesgo Inferior', 'Riesgo Moderado', 'Riesgo Alto', 'Riesgo Extremo'
    mvr_directriz_tratamiento_riesgo      NVARCHAR (255) NOT NULL,
    mvr_directriz_tratamiento_oportunidad NVARCHAR (255) NOT NULL,
    mvr_requiere_aprobacion_comite        BIT            DEFAULT 0 NOT NULL,
    CONSTRAINT PK_mvr_matriz_valoracion_riesgo PRIMARY KEY CLUSTERED (mvr_epr_codigo, mvr_eim_codigo),
    CONSTRAINT UQ_mvr_codigo_posicion UNIQUE (mvr_codigo_posicion),
    CONSTRAINT FK_mvr_escala_probabilidad FOREIGN KEY (mvr_epr_codigo) REFERENCES sgspi.escala_probabilidad (epr_codigo),
    CONSTRAINT FK_mvr_escala_impacto FOREIGN KEY (mvr_eim_codigo) REFERENCES sgspi.escala_impacto (eim_codigo),
    CONSTRAINT CK_mvr_codigo_zona CHECK (mvr_codigo_zona IN ('B', 'M', 'A', 'E'))
);

CREATE NONCLUSTERED INDEX IX_mvr_eim_codigo
    ON sgspi.matriz_valoracion_riesgo (mvr_eim_codigo);

-- 5.2 [eia] Escenarios de Incertidumbre sobre Activos (Riesgos RA-XX y Oportunidades OA-XX con System-Versioned Temporal Table)
CREATE TABLE sgspi.evento_incertidumbre_activo (
    eia_codigo                      INT                                         IDENTITY (1, 1) NOT NULL,
    eia_pev_codigo                  SMALLINT                                    NOT NULL, -- FK a [sgspi].[periodo_vigencia]([pev_codigo])
    eia_identificador_evento        NVARCHAR (15)                               NOT NULL, -- 'RA-01'..'RA-15', 'OA-01'..'OA-09'
    eia_naturaleza_evento           NVARCHAR (15)                               NOT NULL, -- 'RIESGO' (-), 'OPORTUNIDAD' (+)
    eia_pri_codigo                  INT                                         NOT NULL, -- FK a [sgspi].[proceso_institucional]([pri_codigo])
    eia_aci_codigo_primario         INT                                         NOT NULL, -- FK a [sgspi].[activo_informacion]([aci_codigo])
    eia_aci_codigo_soporte          INT                                         NOT NULL, -- FK a [sgspi].[activo_informacion]([aci_codigo])
    eia_tipo_componente_afectado    NVARCHAR (50)                               NOT NULL, -- 'Información', 'Software', 'Servicio', 'Infraestructura', 'Hardware'
    eia_fuente_generadora           NVARCHAR (255)                              NOT NULL,
    eia_controles_existentes        NVARCHAR (1000)                             NULL,
    eia_condicion_vulnerabilidad    NVARCHAR (1000)                             NOT NULL,
    eia_efecto_consecuencia         NVARCHAR (1000)                             NOT NULL,
    eia_escenario_operacional       NVARCHAR (255)                              NOT NULL,
    -- Valoración Inherente / Actual
    eia_epr_codigo_inherente        TINYINT                                     NOT NULL,
    eia_eim_codigo_inherente        TINYINT                                     NOT NULL,
    -- Máquina de Estados Principal y Firmas sobre [dbo].[persona]
    eia_estado_registro             NVARCHAR (30)                               DEFAULT N'BORRADOR' NOT NULL,
    eia_per_codigo_creador          INT                                         NOT NULL, -- FK a [dbo].[persona]([per_codigo])
    eia_per_codigo_validador_lider  INT                                         NULL, -- FK a [dbo].[persona]([per_codigo])
    eia_per_codigo_revisor_sgspi    INT                                         NULL, -- FK a [dbo].[persona]([per_codigo])
    eia_per_codigo_aprobador_comite INT                                         NULL, -- FK a [dbo].[persona]([per_codigo])
    eia_fecha_creacion              DATETIME2 (0)                               DEFAULT SYSDATETIME() NOT NULL,
    eia_fecha_actualizacion         DATETIME2 (0)                               DEFAULT SYSDATETIME() NOT NULL,
    eia_sys_inicio_utc              DATETIME2 (7) GENERATED ALWAYS AS ROW START HIDDEN DEFAULT SYSUTCDATETIME() NOT NULL,
    eia_sys_fin_utc                 DATETIME2 (7) GENERATED ALWAYS AS ROW END   HIDDEN DEFAULT CONVERT (DATETIME2 (7), '9999-12-31 23:59:59.9999999') NOT NULL,
    PERIOD FOR SYSTEM_TIME (eia_sys_inicio_utc, eia_sys_fin_utc),
    CONSTRAINT PK_eia_evento_incertidumbre_activo PRIMARY KEY CLUSTERED (eia_codigo),
    CONSTRAINT UQ_eia_vigencia_identificador UNIQUE (eia_pev_codigo, eia_identificador_evento),
    CONSTRAINT FK_eia_periodo_vigencia FOREIGN KEY (eia_pev_codigo) REFERENCES sgspi.periodo_vigencia (pev_codigo),
    CONSTRAINT FK_eia_proceso_institucional FOREIGN KEY (eia_pri_codigo) REFERENCES sgspi.proceso_institucional (pri_codigo),
    CONSTRAINT FK_eia_activo_primario FOREIGN KEY (eia_aci_codigo_primario) REFERENCES sgspi.activo_informacion (aci_codigo),
    CONSTRAINT FK_eia_activo_soporte FOREIGN KEY (eia_aci_codigo_soporte) REFERENCES sgspi.activo_informacion (aci_codigo),
    CONSTRAINT FK_eia_valoracion_inherente FOREIGN KEY (eia_epr_codigo_inherente, eia_eim_codigo_inherente) REFERENCES sgspi.matriz_valoracion_riesgo (mvr_epr_codigo, mvr_eim_codigo),
    CONSTRAINT FK_eia_dbo_persona_creador FOREIGN KEY (eia_per_codigo_creador) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT FK_eia_dbo_persona_validador FOREIGN KEY (eia_per_codigo_validador_lider) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT FK_eia_dbo_persona_revisor FOREIGN KEY (eia_per_codigo_revisor_sgspi) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT FK_eia_dbo_persona_comite FOREIGN KEY (eia_per_codigo_aprobador_comite) REFERENCES dbo.persona (per_codigo),
    -- RN-RSG-01: Exclusión Mutua Riesgo (RA-) vs Oportunidad (OA-)
    CONSTRAINT CK_eia_naturaleza_prefijo CHECK ((eia_naturaleza_evento = N'RIESGO'
                                                 AND eia_identificador_evento LIKE N'RA-%')
                                                OR (eia_naturaleza_evento = N'OPORTUNIDAD'
                                                    AND eia_identificador_evento LIKE N'OA-%')),
    -- Máquina de Estados (Sección 10)
    CONSTRAINT CK_eia_estado_maquina CHECK (eia_estado_registro IN (N'BORRADOR', N'EN_VALIDACION_LIDER', N'EN_REVISION_SGSPI', N'OBSERVADO', N'EN_ACEPTACION_COMITE', N'APROBADO_PLANIFICADO', N'EN_EJECUCION', N'EN_EVALUACION_EFICACIA', N'CERRADO_EFICAZ', N'HISTORICO')),
    -- Segregación de funciones ISO 27001 A.5.3: Quien aprueba en SGSPI no puede ser el creador en borrador
    CONSTRAINT CK_eia_sod_revision CHECK (eia_per_codigo_revisor_sgspi IS NULL
                                          OR eia_per_codigo_revisor_sgspi <> eia_per_codigo_creador)
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = sgspi.evento_incertidumbre_activo_historial));

CREATE NONCLUSTERED INDEX IX_eia_pri_codigo
    ON sgspi.evento_incertidumbre_activo (eia_pri_codigo);
CREATE NONCLUSTERED INDEX IX_eia_aci_codigo_primario
    ON sgspi.evento_incertidumbre_activo (eia_aci_codigo_primario);
CREATE NONCLUSTERED INDEX IX_eia_aci_codigo_soporte
    ON sgspi.evento_incertidumbre_activo (eia_aci_codigo_soporte);
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
    etc_esta_activa          BIT            DEFAULT 1 NOT NULL,
    CONSTRAINT PK_etc_estrategia_tratamiento_catalogo PRIMARY KEY CLUSTERED (etc_codigo),
    CONSTRAINT UQ_etc_nombre_estrategia UNIQUE (etc_nombre_estrategia),
    CONSTRAINT CK_etc_nombre_no_vacio CHECK (LEN(TRIM(etc_nombre_estrategia)) > 0),
    CONSTRAINT CK_etc_naturaleza_aplicable CHECK (etc_naturaleza_aplicable IN (N'RIESGO', N'OPORTUNIDAD'))
);

CREATE TABLE sgspi.plan_tratamiento (
    plt_codigo                      INT             IDENTITY (1, 1) NOT NULL,
    plt_eia_codigo                  INT             NOT NULL, -- FK a [sgspi].[evento_incertidumbre_activo]([eia_codigo])
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
    plt_unidad_medida_kpi           NVARCHAR (30)   DEFAULT N'PORCENTAJE' NOT NULL, -- Ej: 'PORCENTAJE', 'CANTIDAD', 'DIAS', 'HORAS'
    plt_meta_indicador_kpi          DECIMAL (10, 2) NOT NULL,
    plt_valor_alcanzado_kpi         DECIMAL (10, 2) NULL,
    plt_porcentaje_cumplimiento_kpi AS              (CASE WHEN plt_meta_indicador_kpi > 0
                                                               AND plt_valor_alcanzado_kpi IS NOT NULL THEN CAST (ROUND((plt_valor_alcanzado_kpi / plt_meta_indicador_kpi) * 100.0, 2) AS DECIMAL (6, 2)) ELSE NULL END),
    plt_es_tratamiento_eficaz       BIT             NULL,
    plt_dictamen_eficacia           NVARCHAR (1000) NULL,
    plt_per_codigo_evaluador        INT             NULL, -- FK a [dbo].[persona]([per_codigo])
    plt_fecha_evaluacion_eficacia   DATETIME2 (0)   NULL,
    plt_fecha_creacion              DATETIME2 (0)   DEFAULT SYSDATETIME() NOT NULL,
    plt_fecha_actualizacion         DATETIME2 (0)   DEFAULT SYSDATETIME() NOT NULL,
    CONSTRAINT PK_plt_plan_tratamiento PRIMARY KEY CLUSTERED (plt_codigo),
    CONSTRAINT UQ_plt_evento UNIQUE (plt_eia_codigo),
    CONSTRAINT FK_plt_evento_incertidumbre FOREIGN KEY (plt_eia_codigo) REFERENCES sgspi.evento_incertidumbre_activo (eia_codigo),
    CONSTRAINT FK_plt_estrategia_tratamiento FOREIGN KEY (plt_etc_codigo) REFERENCES sgspi.estrategia_tratamiento_catalogo (etc_codigo),
    CONSTRAINT FK_plt_valoracion_meta FOREIGN KEY (plt_epr_codigo_residual_meta, plt_eim_codigo_residual_meta) REFERENCES sgspi.matriz_valoracion_riesgo (mvr_epr_codigo, mvr_eim_codigo),
    CONSTRAINT FK_plt_dbo_persona_evaluador FOREIGN KEY (plt_per_codigo_evaluador) REFERENCES dbo.persona (per_codigo),
    -- RN-RSG-06: Validación de cronogramas y métricas numéricas KPI
    CONSTRAINT CK_plt_cronograma CHECK (plt_fecha_fin >= plt_fecha_inicio),
    CONSTRAINT CK_plt_unidad_medida_kpi_no_vacia CHECK (LEN(TRIM(plt_unidad_medida_kpi)) > 0),
    CONSTRAINT CK_plt_valores_kpi CHECK (plt_meta_indicador_kpi > 0
                                         AND (plt_valor_alcanzado_kpi IS NULL
                                              OR plt_valor_alcanzado_kpi >= 0))
);

CREATE NONCLUSTERED INDEX IX_plt_etc_codigo
    ON sgspi.plan_tratamiento (plt_etc_codigo);
CREATE NONCLUSTERED INDEX IX_plt_valoracion_residual_meta
    ON sgspi.plan_tratamiento (plt_epr_codigo_residual_meta, plt_eim_codigo_residual_meta);
CREATE NONCLUSTERED INDEX IX_plt_per_codigo_evaluador
    ON sgspi.plan_tratamiento (plt_per_codigo_evaluador);

-- 5.4 [act] y [sga] Desglose de Actividades del Plan de Tratamiento y Seguimiento con Evidencias
CREATE TABLE sgspi.actividad_tratamiento (
    act_codigo                INT            IDENTITY (1, 1) NOT NULL,
    act_plt_codigo            INT            NOT NULL, -- FK a [sgspi].[plan_tratamiento]([plt_codigo])
    act_numero_orden          SMALLINT       DEFAULT 1 NOT NULL,
    act_descripcion_actividad NVARCHAR (500) NOT NULL,
    act_car_codigo            INT            NULL, -- FK a [dbo].[cargo]([car_codigo])
    act_uaa_codigo            INT            NULL, -- FK a [dbo].[uaa]([uaa_codigo])
    act_fecha_compromiso      DATE           NOT NULL,
    act_porcentaje_avance     TINYINT        DEFAULT 0 NOT NULL,
    act_estado_actividad      NVARCHAR (20)  DEFAULT N'PENDIENTE' NOT NULL,
    act_fecha_creacion        DATETIME2 (0)  DEFAULT SYSDATETIME() NOT NULL,
    act_fecha_actualizacion   DATETIME2 (0)  DEFAULT SYSDATETIME() NOT NULL,
    CONSTRAINT PK_act_actividad_tratamiento PRIMARY KEY CLUSTERED (act_codigo),
    CONSTRAINT FK_act_plan_tratamiento FOREIGN KEY (act_plt_codigo) REFERENCES sgspi.plan_tratamiento (plt_codigo),
    CONSTRAINT FK_act_dbo_cargo FOREIGN KEY (act_car_codigo) REFERENCES dbo.cargo (car_codigo),
    CONSTRAINT FK_act_dbo_uaa FOREIGN KEY (act_uaa_codigo) REFERENCES dbo.uaa (uaa_codigo),
    CONSTRAINT CK_act_porcentaje_avance CHECK (act_porcentaje_avance BETWEEN 0 AND 100),
    CONSTRAINT CK_act_estado_actividad CHECK (act_estado_actividad IN (N'PENDIENTE', N'EN_CURSO', N'COMPLETADA', N'OBSERVADA'))
);

CREATE NONCLUSTERED INDEX IX_act_plt_codigo
    ON sgspi.actividad_tratamiento (act_plt_codigo);
CREATE NONCLUSTERED INDEX IX_act_car_codigo
    ON sgspi.actividad_tratamiento (act_car_codigo);
CREATE NONCLUSTERED INDEX IX_act_uaa_codigo
    ON sgspi.actividad_tratamiento (act_uaa_codigo);

CREATE TABLE sgspi.seguimiento_actividad (
    sga_codigo                       INT             IDENTITY (1, 1) NOT NULL,
    sga_act_codigo                   INT             NOT NULL, -- FK a [sgspi].[actividad_tratamiento]([act_codigo])
    sga_per_codigo                   INT             NOT NULL, -- FK a [dbo].[persona]([per_codigo])
    sga_fecha_registro               DATETIME2 (0)   DEFAULT SYSDATETIME() NOT NULL,
    sga_porcentaje_reportado         TINYINT         NOT NULL,
    sga_descripcion_avance           NVARCHAR (1000) NOT NULL,
    sga_nombre_archivo_evidencia     NVARCHAR (255)  NULL,
    sga_uri_almacenamiento_evidencia NVARCHAR (500)  NULL,
    sga_hash_sha256_evidencia        CHAR (64)       NULL,
    CONSTRAINT PK_sga_seguimiento_actividad PRIMARY KEY CLUSTERED (sga_codigo),
    CONSTRAINT FK_sga_actividad_tratamiento FOREIGN KEY (sga_act_codigo) REFERENCES sgspi.actividad_tratamiento (act_codigo),
    CONSTRAINT FK_sga_dbo_persona FOREIGN KEY (sga_per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_sga_porcentaje_reportado CHECK (sga_porcentaje_reportado BETWEEN 0 AND 100)
);

CREATE NONCLUSTERED INDEX IX_sga_act_codigo
    ON sgspi.seguimiento_actividad (sga_act_codigo);
CREATE NONCLUSTERED INDEX IX_sga_per_codigo
    ON sgspi.seguimiento_actividad (sga_per_codigo);

-- 5.5 [enc] y [crn] Catálogo Extensible de Estándares Normativos y Controles de Referencia (ISO/IEC 27001:2022 [93], ISO/IEC 27701:2025 [71], etc.)
CREATE TABLE sgspi.estandar_normativo_catalogo (
    enc_codigo        SMALLINT       IDENTITY (1, 1) NOT NULL,
    enc_identificador NVARCHAR (50)  NOT NULL, -- Ej: 'ISO/IEC 27001:2022', 'ISO/IEC 27701:2025', 'ISO/IEC 27002:2022', 'ISO/IEC 42001:2023'
    enc_nombre        NVARCHAR (200) NOT NULL,
    enc_organismo     NVARCHAR (100) NULL,     -- Ej: 'ISO/IEC', 'NIST', 'MinTIC'
    enc_anio_edicion  SMALLINT       NULL,
    enc_esta_activo   BIT            DEFAULT 1 NOT NULL,
    CONSTRAINT PK_enc_estandar_normativo_catalogo PRIMARY KEY CLUSTERED (enc_codigo),
    CONSTRAINT UQ_enc_identificador UNIQUE (enc_identificador),
    CONSTRAINT CK_enc_identificador_no_vacio CHECK (LEN(TRIM(enc_identificador)) > 0)
);

CREATE TABLE sgspi.control_referencia_normativa (
    crn_codigo                SMALLINT        IDENTITY (1, 1) NOT NULL,
    crn_enc_codigo            SMALLINT        NOT NULL, -- FK a [sgspi].[estandar_normativo_catalogo]([enc_codigo])
    crn_rol_privacidad_pii    NVARCHAR (20)   NULL, -- 'CONTROLADOR', 'PROCESADOR', 'COMUN' (NULL cuando el estándar no define rol PII, ej. ISO/IEC 27001:2022)
    crn_identificador_control NVARCHAR (20)   NOT NULL, -- 'A.5.1'..'A.8.34', 'A.1.2.2'..'A.3.31'
    crn_nombre_control        NVARCHAR (200)  NOT NULL,
    crn_objetivo_requisito    NVARCHAR (1500) NOT NULL,
    crn_tipo_control          NVARCHAR (50)   NULL, -- Ej: 'Preventivo', 'Detectivo', 'Correctivo', 'Disuasivo'
    crn_capacidad_operacional NVARCHAR (150)  NULL,
    crn_dominio_seguridad     NVARCHAR (100)  NULL, -- Ej: 'Gobierno y Ecosistema', 'Protección', 'Defensa', 'Resiliencia'
    crn_esta_activo           BIT             DEFAULT 1 NOT NULL,
    CONSTRAINT PK_crn_control_referencia_normativa PRIMARY KEY CLUSTERED (crn_codigo),
    CONSTRAINT UQ_crn_estandar_identificador UNIQUE (crn_enc_codigo, crn_identificador_control),
    CONSTRAINT FK_crn_estandar_normativo FOREIGN KEY (crn_enc_codigo) REFERENCES sgspi.estandar_normativo_catalogo (enc_codigo),
    CONSTRAINT CK_crn_rol_privacidad_pii CHECK (crn_rol_privacidad_pii IS NULL
                                                OR crn_rol_privacidad_pii IN (N'CONTROLADOR', N'PROCESADOR', N'COMUN')),
    CONSTRAINT CK_crn_tipo_control_no_vacio CHECK (crn_tipo_control IS NULL
                                                   OR LEN(TRIM(crn_tipo_control)) > 0),
    CONSTRAINT CK_crn_dominio_seguridad_no_vacio CHECK (crn_dominio_seguridad IS NULL
                                                        OR LEN(TRIM(crn_dominio_seguridad)) > 0)
);

-- 5.6 [cps], [ccc] Tablas de Atributos Atómicos de Controles Normativos (Eliminan cadenas multivaluadas de Propiedades CID y Conceptos NIST CSF)
CREATE TABLE sgspi.control_propiedad_seguridad (
    cps_crn_codigo          SMALLINT      NOT NULL, -- FK a [sgspi].[control_referencia_normativa]([crn_codigo])
    cps_propiedad_seguridad NVARCHAR (40) NOT NULL, -- Valor atómico extensible: 'Confidencialidad', 'Integridad', 'Disponibilidad', 'Autenticidad', 'No repudio'
    CONSTRAINT PK_cps_control_propiedad_seguridad PRIMARY KEY CLUSTERED (cps_crn_codigo, cps_propiedad_seguridad),
    CONSTRAINT FK_cps_control_referencia FOREIGN KEY (cps_crn_codigo) REFERENCES sgspi.control_referencia_normativa (crn_codigo) ON DELETE CASCADE,
    CONSTRAINT CK_cps_propiedad_seguridad_no_vacia CHECK (LEN(TRIM(cps_propiedad_seguridad)) > 0)
);

CREATE NONCLUSTERED INDEX IX_cps_propiedad_seguridad
    ON sgspi.control_propiedad_seguridad (cps_propiedad_seguridad)
    INCLUDE (cps_crn_codigo);

CREATE TABLE sgspi.control_concepto_ciberseguridad (
    ccc_crn_codigo              SMALLINT      NOT NULL, -- FK a [sgspi].[control_referencia_normativa]([crn_codigo])
    ccc_concepto_ciberseguridad NVARCHAR (40) NOT NULL, -- Valor atómico extensible: 'Gobernar', 'Identificar', 'Proteger', 'Detectar', 'Responder', 'Recuperar'
    CONSTRAINT PK_ccc_control_concepto_ciberseguridad PRIMARY KEY CLUSTERED (ccc_crn_codigo, ccc_concepto_ciberseguridad),
    CONSTRAINT FK_ccc_control_referencia FOREIGN KEY (ccc_crn_codigo) REFERENCES sgspi.control_referencia_normativa (crn_codigo) ON DELETE CASCADE,
    CONSTRAINT CK_ccc_concepto_ciberseguridad_no_vacio CHECK (LEN(TRIM(ccc_concepto_ciberseguridad)) > 0)
);

CREATE NONCLUSTERED INDEX IX_ccc_concepto_ciberseguridad
    ON sgspi.control_concepto_ciberseguridad (ccc_concepto_ciberseguridad)
    INCLUDE (ccc_crn_codigo);

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
    eac_es_aplicable                BIT                                         DEFAULT 1 NOT NULL,
    eac_justificacion_aplicabilidad NVARCHAR (1000)                             NULL,
    eac_documento_soporte_normativo NVARCHAR (500)                              NULL,
    eac_car_codigo                  INT                                         NULL, -- FK a [dbo].[cargo]([car_codigo])
    eac_frecuencia_revision         NVARCHAR (100)                              NULL, -- Ej: 'Anual y cuando se presenten cambios' (NULL cuando eac_es_aplicable = 0)
    eac_evidencia_objetiva_esperada NVARCHAR (500)                              NULL,
    eac_estado_implementacion       NVARCHAR (20)                               NULL, -- 'CUMPLE', 'CUMPLE_PARCIAL', 'NO_CUMPLE' (NULL cuando eac_es_aplicable = 0)
    eac_observaciones_auditoria     NVARCHAR (1000)                             NULL,
    eac_fecha_creacion              DATETIME2 (0)                               DEFAULT SYSDATETIME() NOT NULL,
    eac_fecha_actualizacion         DATETIME2 (0)                               DEFAULT SYSDATETIME() NOT NULL,
    eac_sys_inicio_utc              DATETIME2 (7) GENERATED ALWAYS AS ROW START HIDDEN DEFAULT SYSUTCDATETIME() NOT NULL,
    eac_sys_fin_utc                 DATETIME2 (7) GENERATED ALWAYS AS ROW END   HIDDEN DEFAULT CONVERT (DATETIME2 (7), '9999-12-31 23:59:59.9999999') NOT NULL,
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

-- 5.9 [bas] Bitácora de Auditoría Inmutable con Arco Exclusivo de Integridad Referencial (Control ISO 27001 A.8.15)
CREATE TABLE sgspi.bitacora_auditoria_sistema (
    bas_codigo                   BIGINT          IDENTITY (1, 1) NOT NULL,
    bas_fecha_evento_utc         DATETIME2 (3)   DEFAULT SYSUTCDATETIME() NOT NULL,
    bas_per_codigo               INT             NULL, -- FK a [dbo].[persona]([per_codigo]) (Resuelto vía SESSION_CONTEXT o columna de firma del registro)
    bas_gru_codigo               INT             NULL, -- FK a [dbo].[grupo]([gru_codigo])
    bas_usg_codigo               INT             NULL, -- FK a [dbo].[usuario_grupo]([usg_codigo])
    bas_usuario_bd               NVARCHAR (128)  DEFAULT ORIGINAL_LOGIN() NOT NULL,
    bas_direccion_ip             VARCHAR (45)    NULL,
    -- Arco Exclusivo (Exclusive Arc) de Llaves Foráneas Fuertes hacia las 8 entidades auditadas (Elimina antipatrón polimórfico sin FK)
    bas_acf_codigo               INT             NULL, -- FK a [sgspi].[analisis_contexto_factor]([acf_codigo])
    bas_rpi_codigo               INT             NULL, -- FK a [sgspi].[requisito_parte_interesada]([rpi_codigo])
    bas_aci_codigo               INT             NULL, -- FK a [sgspi].[activo_informacion]([aci_codigo])
    bas_ado_codigo               INT             NULL, -- FK a [sgspi].[activo_documental]([ado_codigo])
    bas_eia_codigo               INT             NULL, -- FK a [sgspi].[evento_incertidumbre_activo]([eia_codigo])
    bas_plt_codigo               INT             NULL, -- FK a [sgspi].[plan_tratamiento]([plt_codigo])
    bas_act_codigo               INT             NULL, -- FK a [sgspi].[actividad_tratamiento]([act_codigo])
    bas_eac_codigo               INT             NULL, -- FK a [sgspi].[evaluacion_aplicabilidad_control]([eac_codigo])
    bas_entidad_afectada         NVARCHAR (80)   NOT NULL,
    bas_registro_afectado_codigo INT             NOT NULL,
    bas_accion_ejecutada         NVARCHAR (30)   NOT NULL, -- 'CREAR', 'ACTUALIZAR', 'TRANSICION_ESTADO', 'APROBAR', 'OBSERVAR'
    bas_estado_anterior          NVARCHAR (30)   NULL,
    bas_estado_nuevo             NVARCHAR (30)   NULL,
    bas_valores_anteriores_json  NVARCHAR (MAX)  NULL,
    bas_valores_nuevos_json      NVARCHAR (MAX)  NULL,
    bas_motivo_observacion       NVARCHAR (500)  NULL,
    bas_hash_evento_sha256       AS              (CONVERT (CHAR (64), HASHBYTES('SHA2_256', CONVERT (NVARCHAR (4000), CONCAT_WS(N'|', CONVERT (NVARCHAR (30), bas_fecha_evento_utc, 126), ISNULL(CONVERT (NVARCHAR (20), bas_per_codigo), N'SYS'), bas_usuario_bd, bas_entidad_afectada, CONVERT (NVARCHAR (20), bas_registro_afectado_codigo), bas_accion_ejecutada, ISNULL(bas_estado_anterior, N''), ISNULL(bas_estado_nuevo, N''), CONVERT (NVARCHAR (3500), ISNULL(bas_valores_nuevos_json, N''))))), 2)) PERSISTED,
    CONSTRAINT PK_bas_bitacora_auditoria_sistema PRIMARY KEY CLUSTERED (bas_codigo),
    CONSTRAINT FK_bas_dbo_persona FOREIGN KEY (bas_per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT FK_bas_dbo_grupo FOREIGN KEY (bas_gru_codigo) REFERENCES dbo.grupo (gru_codigo),
    CONSTRAINT FK_bas_dbo_usuario_grupo FOREIGN KEY (bas_usg_codigo) REFERENCES dbo.usuario_grupo (usg_codigo),
    CONSTRAINT FK_bas_analisis_contexto_factor FOREIGN KEY (bas_acf_codigo) REFERENCES sgspi.analisis_contexto_factor (acf_codigo),
    CONSTRAINT FK_bas_requisito_parte_interesada FOREIGN KEY (bas_rpi_codigo) REFERENCES sgspi.requisito_parte_interesada (rpi_codigo),
    CONSTRAINT FK_bas_activo_informacion FOREIGN KEY (bas_aci_codigo) REFERENCES sgspi.activo_informacion (aci_codigo),
    CONSTRAINT FK_bas_activo_documental FOREIGN KEY (bas_ado_codigo) REFERENCES sgspi.activo_documental (ado_codigo),
    CONSTRAINT FK_bas_evento_incertidumbre_activo FOREIGN KEY (bas_eia_codigo) REFERENCES sgspi.evento_incertidumbre_activo (eia_codigo),
    CONSTRAINT FK_bas_plan_tratamiento FOREIGN KEY (bas_plt_codigo) REFERENCES sgspi.plan_tratamiento (plt_codigo),
    CONSTRAINT FK_bas_actividad_tratamiento FOREIGN KEY (bas_act_codigo) REFERENCES sgspi.actividad_tratamiento (act_codigo),
    CONSTRAINT FK_bas_evaluacion_aplicabilidad_control FOREIGN KEY (bas_eac_codigo) REFERENCES sgspi.evaluacion_aplicabilidad_control (eac_codigo),
    -- Garantía de Arco Exclusivo: Exactamente 1 FK debe ser NOT NULL y coincidir con bas_entidad_afectada y bas_registro_afectado_codigo
    CONSTRAINT CK_bas_arco_exclusivo_entidad CHECK ((CASE WHEN bas_acf_codigo IS NOT NULL THEN 1 ELSE 0 END
                                                     + CASE WHEN bas_rpi_codigo IS NOT NULL THEN 1 ELSE 0 END
                                                     + CASE WHEN bas_aci_codigo IS NOT NULL THEN 1 ELSE 0 END
                                                     + CASE WHEN bas_ado_codigo IS NOT NULL THEN 1 ELSE 0 END
                                                     + CASE WHEN bas_eia_codigo IS NOT NULL THEN 1 ELSE 0 END
                                                     + CASE WHEN bas_plt_codigo IS NOT NULL THEN 1 ELSE 0 END
                                                     + CASE WHEN bas_act_codigo IS NOT NULL THEN 1 ELSE 0 END
                                                     + CASE WHEN bas_eac_codigo IS NOT NULL THEN 1 ELSE 0 END) = 1
                                                    AND ((bas_acf_codigo IS NOT NULL
                                                          AND bas_entidad_afectada = N'sgspi.analisis_contexto_factor'
                                                          AND bas_registro_afectado_codigo = bas_acf_codigo)
                                                         OR (bas_rpi_codigo IS NOT NULL
                                                             AND bas_entidad_afectada = N'sgspi.requisito_parte_interesada'
                                                             AND bas_registro_afectado_codigo = bas_rpi_codigo)
                                                         OR (bas_aci_codigo IS NOT NULL
                                                             AND bas_entidad_afectada = N'sgspi.activo_informacion'
                                                             AND bas_registro_afectado_codigo = bas_aci_codigo)
                                                         OR (bas_ado_codigo IS NOT NULL
                                                             AND bas_entidad_afectada = N'sgspi.activo_documental'
                                                             AND bas_registro_afectado_codigo = bas_ado_codigo)
                                                         OR (bas_eia_codigo IS NOT NULL
                                                             AND bas_entidad_afectada = N'sgspi.evento_incertidumbre_activo'
                                                             AND bas_registro_afectado_codigo = bas_eia_codigo)
                                                         OR (bas_plt_codigo IS NOT NULL
                                                             AND bas_entidad_afectada = N'sgspi.plan_tratamiento'
                                                             AND bas_registro_afectado_codigo = bas_plt_codigo)
                                                         OR (bas_act_codigo IS NOT NULL
                                                             AND bas_entidad_afectada = N'sgspi.actividad_tratamiento'
                                                             AND bas_registro_afectado_codigo = bas_act_codigo)
                                                         OR (bas_eac_codigo IS NOT NULL
                                                             AND bas_entidad_afectada = N'sgspi.evaluacion_aplicabilidad_control'
                                                             AND bas_registro_afectado_codigo = bas_eac_codigo))),
    CONSTRAINT CK_bas_accion_ejecutada CHECK (bas_accion_ejecutada IN (N'CREAR', N'ACTUALIZAR', N'TRANSICION_ESTADO', N'APROBAR', N'OBSERVAR')),
    CONSTRAINT CK_bas_json_ant CHECK (bas_valores_anteriores_json IS NULL
                                      OR ISJSON(bas_valores_anteriores_json) = 1),
    CONSTRAINT CK_bas_json_nue CHECK (bas_valores_nuevos_json IS NULL
                                      OR ISJSON(bas_valores_nuevos_json) = 1)
);

CREATE NONCLUSTERED INDEX IX_bas_per_codigo
    ON sgspi.bitacora_auditoria_sistema (bas_per_codigo);
CREATE NONCLUSTERED INDEX IX_bas_gru_codigo
    ON sgspi.bitacora_auditoria_sistema (bas_gru_codigo);
CREATE NONCLUSTERED INDEX IX_bas_usg_codigo
    ON sgspi.bitacora_auditoria_sistema (bas_usg_codigo);
CREATE NONCLUSTERED INDEX IX_bas_acf_codigo
    ON sgspi.bitacora_auditoria_sistema (bas_acf_codigo) WHERE bas_acf_codigo IS NOT NULL;
CREATE NONCLUSTERED INDEX IX_bas_rpi_codigo
    ON sgspi.bitacora_auditoria_sistema (bas_rpi_codigo) WHERE bas_rpi_codigo IS NOT NULL;
CREATE NONCLUSTERED INDEX IX_bas_aci_codigo
    ON sgspi.bitacora_auditoria_sistema (bas_aci_codigo) WHERE bas_aci_codigo IS NOT NULL;
CREATE NONCLUSTERED INDEX IX_bas_ado_codigo
    ON sgspi.bitacora_auditoria_sistema (bas_ado_codigo) WHERE bas_ado_codigo IS NOT NULL;
CREATE NONCLUSTERED INDEX IX_bas_eia_codigo
    ON sgspi.bitacora_auditoria_sistema (bas_eia_codigo) WHERE bas_eia_codigo IS NOT NULL;
CREATE NONCLUSTERED INDEX IX_bas_plt_codigo
    ON sgspi.bitacora_auditoria_sistema (bas_plt_codigo) WHERE bas_plt_codigo IS NOT NULL;
CREATE NONCLUSTERED INDEX IX_bas_act_codigo
    ON sgspi.bitacora_auditoria_sistema (bas_act_codigo) WHERE bas_act_codigo IS NOT NULL;
CREATE NONCLUSTERED INDEX IX_bas_eac_codigo
    ON sgspi.bitacora_auditoria_sistema (bas_eac_codigo) WHERE bas_eac_codigo IS NOT NULL;


GO
/*==================================================================================================
  5.10 TRIGGERS DE INMUTABILIDAD DE BITÁCORA, ACTUALIZACIÓN AUTOMÁTICA DE [*_fecha_actualizacion],
       INTEGRIDAD DE MÁQUINA DE ESTADOS Y ALIMENTACIÓN AUTOMÁTICA DE AUDITORÍA (ISO 27001 A.8.15)
==================================================================================================*/
-- 5.10.1 Trigger INSTEAD OF UPDATE, DELETE que garantiza la inmutabilidad física (Append-Only) de [sgspi].[bitacora_auditoria_sistema]
CREATE OR ALTER TRIGGER sgspi.TR_bas_inmutabilidad_bitacora
ON sgspi.bitacora_auditoria_sistema
INSTEAD OF UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    THROW 50001, N'Operación denegada (ISO/IEC 27001 A.8.15): La bitácora de auditoría [sgspi].[bitacora_auditoria_sistema] es estrictamente inmutable (append-only); no se permite UPDATE ni DELETE.', 1;
END;


GO
-- 5.10.2 Trigger sobre [sgspi].[analisis_contexto_factor] ([acf]): Actualiza [acf_fecha_actualizacion], valida estados y alimenta [bas]
CREATE OR ALTER TRIGGER sgspi.TR_acf_auditoria_y_actualizacion
ON sgspi.analisis_contexto_factor
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF TRIGGER_NESTLEVEL(OBJECT_ID(N'sgspi.TR_acf_auditoria_y_actualizacion', N'TR')) > 1
        RETURN;

    IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
    BEGIN
        THROW 50010, N'Operación denegada: No se permite eliminar físicamente registros de [sgspi].[analisis_contexto_factor]. Utilice la transición al estado HISTORICO.', 1;
    END;

    IF NOT EXISTS (SELECT 1 FROM inserted)
        RETURN;

    -- Validar integridad de transiciones de estado y bloqueo de edición sobre registros en estado HISTORICO
    IF EXISTS (SELECT 1 FROM deleted)
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM   inserted AS i
                   INNER JOIN deleted AS d ON d.acf_codigo = i.acf_codigo
            WHERE  d.acf_estado_registro = N'HISTORICO'
                   OR (d.acf_estado_registro <> i.acf_estado_registro
                       AND NOT (
                           (d.acf_estado_registro = N'BORRADOR'            AND i.acf_estado_registro IN (N'EN_VALIDACION_LIDER'))
                        OR (d.acf_estado_registro = N'EN_VALIDACION_LIDER' AND i.acf_estado_registro IN (N'EN_REVISION_SGSPI', N'OBSERVADO', N'BORRADOR'))
                        OR (d.acf_estado_registro = N'EN_REVISION_SGSPI'   AND i.acf_estado_registro IN (N'VIGENTE', N'OBSERVADO'))
                        OR (d.acf_estado_registro = N'OBSERVADO'           AND i.acf_estado_registro IN (N'BORRADOR', N'EN_VALIDACION_LIDER'))
                        OR (d.acf_estado_registro = N'VIGENTE'             AND i.acf_estado_registro IN (N'HISTORICO', N'EN_REVISION_SGSPI'))
                       ))
        )
        BEGIN
            THROW 50011, N'Transición de estado inválida o intento de modificar un registro HISTORICO en [sgspi].[analisis_contexto_factor].', 1;
        END;

        UPDATE t
        SET    t.acf_fecha_actualizacion = SYSDATETIME()
        FROM   sgspi.analisis_contexto_factor AS t
               INNER JOIN inserted AS i ON i.acf_codigo = t.acf_codigo;
    END;

    INSERT INTO sgspi.bitacora_auditoria_sistema (
        bas_per_codigo,
        bas_gru_codigo,
        bas_usg_codigo,
        bas_direccion_ip,
        bas_acf_codigo,
        bas_entidad_afectada,
        bas_registro_afectado_codigo,
        bas_accion_ejecutada,
        bas_estado_anterior,
        bas_estado_nuevo,
        bas_valores_anteriores_json,
        bas_valores_nuevos_json,
        bas_motivo_observacion
    )
    SELECT COALESCE(TRY_CAST(SESSION_CONTEXT(N'sgspi_per_codigo') AS INT), i.acf_per_codigo_aprobador, i.acf_per_codigo_creador),
           TRY_CAST(SESSION_CONTEXT(N'sgspi_gru_codigo') AS INT),
           TRY_CAST(SESSION_CONTEXT(N'sgspi_usg_codigo') AS INT),
           COALESCE(CONVERT(VARCHAR(45), SESSION_CONTEXT(N'sgspi_direccion_ip')), CONVERT(VARCHAR(45), CONNECTIONPROPERTY('client_net_address'))),
           i.acf_codigo,
           N'sgspi.analisis_contexto_factor',
           i.acf_codigo,
           CASE
               WHEN d.acf_codigo IS NULL THEN N'CREAR'
               WHEN d.acf_estado_registro <> i.acf_estado_registro AND i.acf_estado_registro = N'VIGENTE' THEN N'APROBAR'
               WHEN d.acf_estado_registro <> i.acf_estado_registro AND i.acf_estado_registro = N'OBSERVADO' THEN N'OBSERVAR'
               WHEN d.acf_estado_registro <> i.acf_estado_registro THEN N'TRANSICION_ESTADO'
               ELSE N'ACTUALIZAR'
           END,
           d.acf_estado_registro,
           i.acf_estado_registro,
           CASE WHEN d.acf_codigo IS NOT NULL THEN (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) ELSE NULL END,
           (SELECT t.* FROM sgspi.analisis_contexto_factor AS t WHERE t.acf_codigo = i.acf_codigo FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
           CONVERT(NVARCHAR(500), SESSION_CONTEXT(N'sgspi_motivo_observacion'))
    FROM   inserted AS i
           LEFT OUTER JOIN deleted AS d ON d.acf_codigo = i.acf_codigo;
END;


GO
-- 5.10.3 Trigger sobre [sgspi].[requisito_parte_interesada] ([rpi]): Actualiza [rpi_fecha_actualizacion], valida estados y alimenta [bas]
CREATE OR ALTER TRIGGER sgspi.TR_rpi_auditoria_y_actualizacion
ON sgspi.requisito_parte_interesada
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF TRIGGER_NESTLEVEL(OBJECT_ID(N'sgspi.TR_rpi_auditoria_y_actualizacion', N'TR')) > 1
        RETURN;

    IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
    BEGIN
        THROW 50010, N'Operación denegada: No se permite eliminar físicamente registros de [sgspi].[requisito_parte_interesada]. Utilice la transición al estado HISTORICO.', 1;
    END;

    IF NOT EXISTS (SELECT 1 FROM inserted)
        RETURN;

    IF EXISTS (SELECT 1 FROM deleted)
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM   inserted AS i
                   INNER JOIN deleted AS d ON d.rpi_codigo = i.rpi_codigo
            WHERE  d.rpi_estado_registro = N'HISTORICO'
                   OR (d.rpi_estado_registro <> i.rpi_estado_registro
                       AND NOT (
                           (d.rpi_estado_registro = N'BORRADOR'            AND i.rpi_estado_registro IN (N'EN_VALIDACION_LIDER'))
                        OR (d.rpi_estado_registro = N'EN_VALIDACION_LIDER' AND i.rpi_estado_registro IN (N'EN_REVISION_SGSPI', N'OBSERVADO', N'BORRADOR'))
                        OR (d.rpi_estado_registro = N'EN_REVISION_SGSPI'   AND i.rpi_estado_registro IN (N'VIGENTE', N'OBSERVADO'))
                        OR (d.rpi_estado_registro = N'OBSERVADO'           AND i.rpi_estado_registro IN (N'BORRADOR', N'EN_VALIDACION_LIDER'))
                        OR (d.rpi_estado_registro = N'VIGENTE'             AND i.rpi_estado_registro IN (N'HISTORICO', N'EN_REVISION_SGSPI'))
                       ))
        )
        BEGIN
            THROW 50011, N'Transición de estado inválida o intento de modificar un registro HISTORICO en [sgspi].[requisito_parte_interesada].', 1;
        END;

        UPDATE t
        SET    t.rpi_fecha_actualizacion = SYSDATETIME()
        FROM   sgspi.requisito_parte_interesada AS t
               INNER JOIN inserted AS i ON i.rpi_codigo = t.rpi_codigo;
    END;

    INSERT INTO sgspi.bitacora_auditoria_sistema (
        bas_per_codigo,
        bas_gru_codigo,
        bas_usg_codigo,
        bas_direccion_ip,
        bas_rpi_codigo,
        bas_entidad_afectada,
        bas_registro_afectado_codigo,
        bas_accion_ejecutada,
        bas_estado_anterior,
        bas_estado_nuevo,
        bas_valores_anteriores_json,
        bas_valores_nuevos_json,
        bas_motivo_observacion
    )
    SELECT TRY_CAST(SESSION_CONTEXT(N'sgspi_per_codigo') AS INT),
           TRY_CAST(SESSION_CONTEXT(N'sgspi_gru_codigo') AS INT),
           TRY_CAST(SESSION_CONTEXT(N'sgspi_usg_codigo') AS INT),
           COALESCE(CONVERT(VARCHAR(45), SESSION_CONTEXT(N'sgspi_direccion_ip')), CONVERT(VARCHAR(45), CONNECTIONPROPERTY('client_net_address'))),
           i.rpi_codigo,
           N'sgspi.requisito_parte_interesada',
           i.rpi_codigo,
           CASE
               WHEN d.rpi_codigo IS NULL THEN N'CREAR'
               WHEN d.rpi_estado_registro <> i.rpi_estado_registro AND i.rpi_estado_registro = N'VIGENTE' THEN N'APROBAR'
               WHEN d.rpi_estado_registro <> i.rpi_estado_registro AND i.rpi_estado_registro = N'OBSERVADO' THEN N'OBSERVAR'
               WHEN d.rpi_estado_registro <> i.rpi_estado_registro THEN N'TRANSICION_ESTADO'
               ELSE N'ACTUALIZAR'
           END,
           d.rpi_estado_registro,
           i.rpi_estado_registro,
           CASE WHEN d.rpi_codigo IS NOT NULL THEN (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) ELSE NULL END,
           (SELECT t.* FROM sgspi.requisito_parte_interesada AS t WHERE t.rpi_codigo = i.rpi_codigo FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
           CONVERT(NVARCHAR(500), SESSION_CONTEXT(N'sgspi_motivo_observacion'))
    FROM   inserted AS i
           LEFT OUTER JOIN deleted AS d ON d.rpi_codigo = i.rpi_codigo;
END;


GO
-- 5.10.4 Trigger sobre [sgspi].[activo_informacion] ([aci]): Actualiza [aci_fecha_actualizacion], valida estados y alimenta [bas]
CREATE OR ALTER TRIGGER sgspi.TR_aci_auditoria_y_actualizacion
ON sgspi.activo_informacion
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF TRIGGER_NESTLEVEL(OBJECT_ID(N'sgspi.TR_aci_auditoria_y_actualizacion', N'TR')) > 1
        RETURN;

    IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
    BEGIN
        THROW 50010, N'Operación denegada: No se permite eliminar físicamente activos en [sgspi].[activo_informacion]. Utilice los estados INACTIVO o HISTORICO.', 1;
    END;

    IF NOT EXISTS (SELECT 1 FROM inserted)
        RETURN;

    IF EXISTS (SELECT 1 FROM deleted)
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM   inserted AS i
                   INNER JOIN deleted AS d ON d.aci_codigo = i.aci_codigo
            WHERE  d.aci_estado_registro = N'HISTORICO'
                   OR (d.aci_estado_registro <> i.aci_estado_registro
                       AND NOT (
                           (d.aci_estado_registro = N'BORRADOR'            AND i.aci_estado_registro IN (N'EN_VALIDACION_LIDER'))
                        OR (d.aci_estado_registro = N'EN_VALIDACION_LIDER' AND i.aci_estado_registro IN (N'EN_REVISION_ARCHIVO', N'EN_REVISION_SGSPI', N'OBSERVADO', N'BORRADOR'))
                        OR (d.aci_estado_registro = N'EN_REVISION_ARCHIVO' AND i.aci_estado_registro IN (N'EN_REVISION_SGSPI', N'OBSERVADO'))
                        OR (d.aci_estado_registro = N'EN_REVISION_SGSPI'   AND i.aci_estado_registro IN (N'VIGENTE', N'OBSERVADO'))
                        OR (d.aci_estado_registro = N'OBSERVADO'           AND i.aci_estado_registro IN (N'BORRADOR', N'EN_VALIDACION_LIDER'))
                        OR (d.aci_estado_registro = N'VIGENTE'             AND i.aci_estado_registro IN (N'INACTIVO', N'HISTORICO', N'EN_REVISION_SGSPI', N'EN_REVISION_ARCHIVO'))
                        OR (d.aci_estado_registro = N'INACTIVO'            AND i.aci_estado_registro IN (N'VIGENTE', N'HISTORICO'))
                       ))
        )
        BEGIN
            THROW 50011, N'Transición de estado inválida o intento de modificar un activo HISTORICO en [sgspi].[activo_informacion].', 1;
        END;

        UPDATE t
        SET    t.aci_fecha_actualizacion = SYSDATETIME()
        FROM   sgspi.activo_informacion AS t
               INNER JOIN inserted AS i ON i.aci_codigo = t.aci_codigo;
    END;

    INSERT INTO sgspi.bitacora_auditoria_sistema (
        bas_per_codigo,
        bas_gru_codigo,
        bas_usg_codigo,
        bas_direccion_ip,
        bas_aci_codigo,
        bas_entidad_afectada,
        bas_registro_afectado_codigo,
        bas_accion_ejecutada,
        bas_estado_anterior,
        bas_estado_nuevo,
        bas_valores_anteriores_json,
        bas_valores_nuevos_json,
        bas_motivo_observacion
    )
    SELECT COALESCE(TRY_CAST(SESSION_CONTEXT(N'sgspi_per_codigo') AS INT), i.aci_per_codigo_aprobador, i.aci_per_codigo_creador),
           TRY_CAST(SESSION_CONTEXT(N'sgspi_gru_codigo') AS INT),
           TRY_CAST(SESSION_CONTEXT(N'sgspi_usg_codigo') AS INT),
           COALESCE(CONVERT(VARCHAR(45), SESSION_CONTEXT(N'sgspi_direccion_ip')), CONVERT(VARCHAR(45), CONNECTIONPROPERTY('client_net_address'))),
           i.aci_codigo,
           N'sgspi.activo_informacion',
           i.aci_codigo,
           CASE
               WHEN d.aci_codigo IS NULL THEN N'CREAR'
               WHEN d.aci_estado_registro <> i.aci_estado_registro AND i.aci_estado_registro = N'VIGENTE' THEN N'APROBAR'
               WHEN d.aci_estado_registro <> i.aci_estado_registro AND i.aci_estado_registro = N'OBSERVADO' THEN N'OBSERVAR'
               WHEN d.aci_estado_registro <> i.aci_estado_registro THEN N'TRANSICION_ESTADO'
               ELSE N'ACTUALIZAR'
           END,
           d.aci_estado_registro,
           i.aci_estado_registro,
           CASE WHEN d.aci_codigo IS NOT NULL THEN (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) ELSE NULL END,
           (SELECT t.* FROM sgspi.activo_informacion AS t WHERE t.aci_codigo = i.aci_codigo FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
           CONVERT(NVARCHAR(500), SESSION_CONTEXT(N'sgspi_motivo_observacion'))
    FROM   inserted AS i
           LEFT OUTER JOIN deleted AS d ON d.aci_codigo = i.aci_codigo;
END;


GO
-- 5.10.5 Trigger sobre [sgspi].[activo_documental] ([ado]): Actualiza [ado_fecha_actualizacion] y alimenta [bas]
CREATE OR ALTER TRIGGER sgspi.TR_ado_auditoria_y_actualizacion
ON sgspi.activo_documental
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF TRIGGER_NESTLEVEL(OBJECT_ID(N'sgspi.TR_ado_auditoria_y_actualizacion', N'TR')) > 1
        RETURN;

    IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
    BEGIN
        THROW 50010, N'Operación denegada: No se permite eliminar físicamente activos documentales en [sgspi].[activo_documental].', 1;
    END;

    IF NOT EXISTS (SELECT 1 FROM inserted)
        RETURN;

    IF EXISTS (SELECT 1 FROM deleted)
    BEGIN
        UPDATE t
        SET    t.ado_fecha_actualizacion = SYSDATETIME()
        FROM   sgspi.activo_documental AS t
               INNER JOIN inserted AS i ON i.ado_codigo = t.ado_codigo;
    END;

    INSERT INTO sgspi.bitacora_auditoria_sistema (
        bas_per_codigo,
        bas_gru_codigo,
        bas_usg_codigo,
        bas_direccion_ip,
        bas_ado_codigo,
        bas_entidad_afectada,
        bas_registro_afectado_codigo,
        bas_accion_ejecutada,
        bas_estado_anterior,
        bas_estado_nuevo,
        bas_valores_anteriores_json,
        bas_valores_nuevos_json,
        bas_motivo_observacion
    )
    SELECT COALESCE(TRY_CAST(SESSION_CONTEXT(N'sgspi_per_codigo') AS INT), i.ado_per_codigo_revisor_archivo, aci.aci_per_codigo_aprobador, aci.aci_per_codigo_creador),
           TRY_CAST(SESSION_CONTEXT(N'sgspi_gru_codigo') AS INT),
           TRY_CAST(SESSION_CONTEXT(N'sgspi_usg_codigo') AS INT),
           COALESCE(CONVERT(VARCHAR(45), SESSION_CONTEXT(N'sgspi_direccion_ip')), CONVERT(VARCHAR(45), CONNECTIONPROPERTY('client_net_address'))),
           i.ado_codigo,
           N'sgspi.activo_documental',
           i.ado_codigo,
           CASE WHEN d.ado_codigo IS NULL THEN N'CREAR' ELSE N'ACTUALIZAR' END,
           NULL,
           aci.aci_estado_registro,
           CASE WHEN d.ado_codigo IS NOT NULL THEN (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) ELSE NULL END,
           (SELECT t.* FROM sgspi.activo_documental AS t WHERE t.ado_codigo = i.ado_codigo FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
           CONVERT(NVARCHAR(500), SESSION_CONTEXT(N'sgspi_motivo_observacion'))
    FROM   inserted AS i
           INNER JOIN sgspi.activo_informacion AS aci ON aci.aci_codigo = i.ado_aci_codigo
           LEFT OUTER JOIN deleted AS d ON d.ado_codigo = i.ado_codigo;
END;


GO
-- 5.10.6 Trigger sobre [sgspi].[evento_incertidumbre_activo] ([eia]): Actualiza [eia_fecha_actualizacion], valida máquina de estados y alimenta [bas]
CREATE OR ALTER TRIGGER sgspi.TR_eia_auditoria_y_actualizacion
ON sgspi.evento_incertidumbre_activo
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF TRIGGER_NESTLEVEL(OBJECT_ID(N'sgspi.TR_eia_auditoria_y_actualizacion', N'TR')) > 1
        RETURN;

    IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
    BEGIN
        THROW 50010, N'Operación denegada: No se permite eliminar físicamente eventos de riesgo/oportunidad en [sgspi].[evento_incertidumbre_activo]. Utilice el estado HISTORICO.', 1;
    END;

    IF NOT EXISTS (SELECT 1 FROM inserted)
        RETURN;

    IF EXISTS (SELECT 1 FROM deleted)
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM   inserted AS i
                   INNER JOIN deleted AS d ON d.eia_codigo = i.eia_codigo
            WHERE  d.eia_estado_registro = N'HISTORICO'
                   OR (d.eia_estado_registro <> i.eia_estado_registro
                       AND NOT (
                           (d.eia_estado_registro = N'BORRADOR'               AND i.eia_estado_registro IN (N'EN_VALIDACION_LIDER'))
                        OR (d.eia_estado_registro = N'EN_VALIDACION_LIDER'    AND i.eia_estado_registro IN (N'EN_REVISION_SGSPI', N'OBSERVADO', N'BORRADOR'))
                        OR (d.eia_estado_registro = N'EN_REVISION_SGSPI'      AND i.eia_estado_registro IN (N'EN_ACEPTACION_COMITE', N'APROBADO_PLANIFICADO', N'OBSERVADO'))
                        OR (d.eia_estado_registro = N'EN_ACEPTACION_COMITE'   AND i.eia_estado_registro IN (N'APROBADO_PLANIFICADO', N'OBSERVADO'))
                        OR (d.eia_estado_registro = N'OBSERVADO'              AND i.eia_estado_registro IN (N'BORRADOR', N'EN_VALIDACION_LIDER'))
                        OR (d.eia_estado_registro = N'APROBADO_PLANIFICADO'   AND i.eia_estado_registro IN (N'EN_EJECUCION', N'OBSERVADO'))
                        OR (d.eia_estado_registro = N'EN_EJECUCION'           AND i.eia_estado_registro IN (N'EN_EVALUACION_EFICACIA', N'OBSERVADO'))
                        OR (d.eia_estado_registro = N'EN_EVALUACION_EFICACIA' AND i.eia_estado_registro IN (N'CERRADO_EFICAZ', N'EN_EJECUCION', N'OBSERVADO'))
                        OR (d.eia_estado_registro = N'CERRADO_EFICAZ'         AND i.eia_estado_registro IN (N'HISTORICO'))
                       ))
        )
        BEGIN
            THROW 50011, N'Transición de estado inválida o intento de modificar un registro HISTORICO en [sgspi].[evento_incertidumbre_activo].', 1;
        END;

        UPDATE t
        SET    t.eia_fecha_actualizacion = SYSDATETIME()
        FROM   sgspi.evento_incertidumbre_activo AS t
               INNER JOIN inserted AS i ON i.eia_codigo = t.eia_codigo;
    END;

    INSERT INTO sgspi.bitacora_auditoria_sistema (
        bas_per_codigo,
        bas_gru_codigo,
        bas_usg_codigo,
        bas_direccion_ip,
        bas_eia_codigo,
        bas_entidad_afectada,
        bas_registro_afectado_codigo,
        bas_accion_ejecutada,
        bas_estado_anterior,
        bas_estado_nuevo,
        bas_valores_anteriores_json,
        bas_valores_nuevos_json,
        bas_motivo_observacion
    )
    SELECT COALESCE(TRY_CAST(SESSION_CONTEXT(N'sgspi_per_codigo') AS INT), i.eia_per_codigo_aprobador_comite, i.eia_per_codigo_revisor_sgspi, i.eia_per_codigo_validador_lider, i.eia_per_codigo_creador),
           TRY_CAST(SESSION_CONTEXT(N'sgspi_gru_codigo') AS INT),
           TRY_CAST(SESSION_CONTEXT(N'sgspi_usg_codigo') AS INT),
           COALESCE(CONVERT(VARCHAR(45), SESSION_CONTEXT(N'sgspi_direccion_ip')), CONVERT(VARCHAR(45), CONNECTIONPROPERTY('client_net_address'))),
           i.eia_codigo,
           N'sgspi.evento_incertidumbre_activo',
           i.eia_codigo,
           CASE
               WHEN d.eia_codigo IS NULL THEN N'CREAR'
               WHEN d.eia_estado_registro <> i.eia_estado_registro AND i.eia_estado_registro IN (N'APROBADO_PLANIFICADO', N'CERRADO_EFICAZ') THEN N'APROBAR'
               WHEN d.eia_estado_registro <> i.eia_estado_registro AND i.eia_estado_registro = N'OBSERVADO' THEN N'OBSERVAR'
               WHEN d.eia_estado_registro <> i.eia_estado_registro THEN N'TRANSICION_ESTADO'
               ELSE N'ACTUALIZAR'
           END,
           d.eia_estado_registro,
           i.eia_estado_registro,
           CASE WHEN d.eia_codigo IS NOT NULL THEN (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) ELSE NULL END,
           (SELECT t.* FROM sgspi.evento_incertidumbre_activo AS t WHERE t.eia_codigo = i.eia_codigo FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
           CONVERT(NVARCHAR(500), SESSION_CONTEXT(N'sgspi_motivo_observacion'))
    FROM   inserted AS i
           LEFT OUTER JOIN deleted AS d ON d.eia_codigo = i.eia_codigo;
END;


GO
-- 5.10.7 Trigger sobre [sgspi].[plan_tratamiento] ([plt]): Actualiza [plt_fecha_actualizacion] y alimenta [bas]
CREATE OR ALTER TRIGGER sgspi.TR_plt_auditoria_y_actualizacion
ON sgspi.plan_tratamiento
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF TRIGGER_NESTLEVEL(OBJECT_ID(N'sgspi.TR_plt_auditoria_y_actualizacion', N'TR')) > 1
        RETURN;

    IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
    BEGIN
        THROW 50010, N'Operación denegada: No se permite eliminar físicamente planes de tratamiento en [sgspi].[plan_tratamiento].', 1;
    END;

    IF NOT EXISTS (SELECT 1 FROM inserted)
        RETURN;

    IF EXISTS (SELECT 1 FROM deleted)
    BEGIN
        UPDATE t
        SET    t.plt_fecha_actualizacion = SYSDATETIME()
        FROM   sgspi.plan_tratamiento AS t
               INNER JOIN inserted AS i ON i.plt_codigo = t.plt_codigo;
    END;

    INSERT INTO sgspi.bitacora_auditoria_sistema (
        bas_per_codigo,
        bas_gru_codigo,
        bas_usg_codigo,
        bas_direccion_ip,
        bas_plt_codigo,
        bas_entidad_afectada,
        bas_registro_afectado_codigo,
        bas_accion_ejecutada,
        bas_estado_anterior,
        bas_estado_nuevo,
        bas_valores_anteriores_json,
        bas_valores_nuevos_json,
        bas_motivo_observacion
    )
    SELECT COALESCE(TRY_CAST(SESSION_CONTEXT(N'sgspi_per_codigo') AS INT), i.plt_per_codigo_evaluador, eia.eia_per_codigo_creador),
           TRY_CAST(SESSION_CONTEXT(N'sgspi_gru_codigo') AS INT),
           TRY_CAST(SESSION_CONTEXT(N'sgspi_usg_codigo') AS INT),
           COALESCE(CONVERT(VARCHAR(45), SESSION_CONTEXT(N'sgspi_direccion_ip')), CONVERT(VARCHAR(45), CONNECTIONPROPERTY('client_net_address'))),
           i.plt_codigo,
           N'sgspi.plan_tratamiento',
           i.plt_codigo,
           CASE WHEN d.plt_codigo IS NULL THEN N'CREAR' ELSE N'ACTUALIZAR' END,
           NULL,
           NULL,
           CASE WHEN d.plt_codigo IS NOT NULL THEN (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) ELSE NULL END,
           (SELECT t.* FROM sgspi.plan_tratamiento AS t WHERE t.plt_codigo = i.plt_codigo FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
           CONVERT(NVARCHAR(500), SESSION_CONTEXT(N'sgspi_motivo_observacion'))
    FROM   inserted AS i
           INNER JOIN sgspi.evento_incertidumbre_activo AS eia ON eia.eia_codigo = i.plt_eia_codigo
           LEFT OUTER JOIN deleted AS d ON d.plt_codigo = i.plt_codigo;
END;


GO
-- 5.10.8 Trigger sobre [sgspi].[actividad_tratamiento] ([act]): Actualiza [act_fecha_actualizacion], valida estados y alimenta [bas]
CREATE OR ALTER TRIGGER sgspi.TR_act_auditoria_y_actualizacion
ON sgspi.actividad_tratamiento
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF TRIGGER_NESTLEVEL(OBJECT_ID(N'sgspi.TR_act_auditoria_y_actualizacion', N'TR')) > 1
        RETURN;

    IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
    BEGIN
        THROW 50010, N'Operación denegada: No se permite eliminar físicamente actividades de tratamiento en [sgspi].[actividad_tratamiento].', 1;
    END;

    IF NOT EXISTS (SELECT 1 FROM inserted)
        RETURN;

    IF EXISTS (SELECT 1 FROM deleted)
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM   inserted AS i
                   INNER JOIN deleted AS d ON d.act_codigo = i.act_codigo
            WHERE  d.act_estado_actividad <> i.act_estado_actividad
                   AND NOT (
                       (d.act_estado_actividad = N'PENDIENTE'  AND i.act_estado_actividad IN (N'EN_CURSO', N'OBSERVADA'))
                    OR (d.act_estado_actividad = N'EN_CURSO'   AND i.act_estado_actividad IN (N'COMPLETADA', N'OBSERVADA'))
                    OR (d.act_estado_actividad = N'OBSERVADA'  AND i.act_estado_actividad IN (N'PENDIENTE', N'EN_CURSO'))
                    OR (d.act_estado_actividad = N'COMPLETADA' AND i.act_estado_actividad IN (N'OBSERVADA'))
                   )
        )
        BEGIN
            THROW 50011, N'Transición de estado inválida en [sgspi].[actividad_tratamiento].', 1;
        END;

        UPDATE t
        SET    t.act_fecha_actualizacion = SYSDATETIME()
        FROM   sgspi.actividad_tratamiento AS t
               INNER JOIN inserted AS i ON i.act_codigo = t.act_codigo;
    END;

    INSERT INTO sgspi.bitacora_auditoria_sistema (
        bas_per_codigo,
        bas_gru_codigo,
        bas_usg_codigo,
        bas_direccion_ip,
        bas_act_codigo,
        bas_entidad_afectada,
        bas_registro_afectado_codigo,
        bas_accion_ejecutada,
        bas_estado_anterior,
        bas_estado_nuevo,
        bas_valores_anteriores_json,
        bas_valores_nuevos_json,
        bas_motivo_observacion
    )
    SELECT TRY_CAST(SESSION_CONTEXT(N'sgspi_per_codigo') AS INT),
           TRY_CAST(SESSION_CONTEXT(N'sgspi_gru_codigo') AS INT),
           TRY_CAST(SESSION_CONTEXT(N'sgspi_usg_codigo') AS INT),
           COALESCE(CONVERT(VARCHAR(45), SESSION_CONTEXT(N'sgspi_direccion_ip')), CONVERT(VARCHAR(45), CONNECTIONPROPERTY('client_net_address'))),
           i.act_codigo,
           N'sgspi.actividad_tratamiento',
           i.act_codigo,
           CASE
               WHEN d.act_codigo IS NULL THEN N'CREAR'
               WHEN d.act_estado_actividad <> i.act_estado_actividad AND i.act_estado_actividad = N'COMPLETADA' THEN N'APROBAR'
               WHEN d.act_estado_actividad <> i.act_estado_actividad AND i.act_estado_actividad = N'OBSERVADA' THEN N'OBSERVAR'
               WHEN d.act_estado_actividad <> i.act_estado_actividad THEN N'TRANSICION_ESTADO'
               ELSE N'ACTUALIZAR'
           END,
           d.act_estado_actividad,
           i.act_estado_actividad,
           CASE WHEN d.act_codigo IS NOT NULL THEN (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) ELSE NULL END,
           (SELECT t.* FROM sgspi.actividad_tratamiento AS t WHERE t.act_codigo = i.act_codigo FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
           CONVERT(NVARCHAR(500), SESSION_CONTEXT(N'sgspi_motivo_observacion'))
    FROM   inserted AS i
           LEFT OUTER JOIN deleted AS d ON d.act_codigo = i.act_codigo;
END;


GO
-- 5.10.9 Trigger sobre [sgspi].[evaluacion_aplicabilidad_control] ([eac]): Actualiza [eac_fecha_actualizacion] y alimenta [bas]
CREATE OR ALTER TRIGGER sgspi.TR_eac_auditoria_y_actualizacion
ON sgspi.evaluacion_aplicabilidad_control
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF TRIGGER_NESTLEVEL(OBJECT_ID(N'sgspi.TR_eac_auditoria_y_actualizacion', N'TR')) > 1
        RETURN;

    IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
    BEGIN
        THROW 50010, N'Operación denegada: No se permite eliminar físicamente evaluaciones de aplicabilidad (SoA) en [sgspi].[evaluacion_aplicabilidad_control].', 1;
    END;

    IF NOT EXISTS (SELECT 1 FROM inserted)
        RETURN;

    IF EXISTS (SELECT 1 FROM deleted)
    BEGIN
        UPDATE t
        SET    t.eac_fecha_actualizacion = SYSDATETIME()
        FROM   sgspi.evaluacion_aplicabilidad_control AS t
               INNER JOIN inserted AS i ON i.eac_codigo = t.eac_codigo;
    END;

    INSERT INTO sgspi.bitacora_auditoria_sistema (
        bas_per_codigo,
        bas_gru_codigo,
        bas_usg_codigo,
        bas_direccion_ip,
        bas_eac_codigo,
        bas_entidad_afectada,
        bas_registro_afectado_codigo,
        bas_accion_ejecutada,
        bas_estado_anterior,
        bas_estado_nuevo,
        bas_valores_anteriores_json,
        bas_valores_nuevos_json,
        bas_motivo_observacion
    )
    SELECT TRY_CAST(SESSION_CONTEXT(N'sgspi_per_codigo') AS INT),
           TRY_CAST(SESSION_CONTEXT(N'sgspi_gru_codigo') AS INT),
           TRY_CAST(SESSION_CONTEXT(N'sgspi_usg_codigo') AS INT),
           COALESCE(CONVERT(VARCHAR(45), SESSION_CONTEXT(N'sgspi_direccion_ip')), CONVERT(VARCHAR(45), CONNECTIONPROPERTY('client_net_address'))),
           i.eac_codigo,
           N'sgspi.evaluacion_aplicabilidad_control',
           i.eac_codigo,
           CASE
               WHEN d.eac_codigo IS NULL THEN N'CREAR'
               WHEN ISNULL(d.eac_estado_implementacion, N'') <> ISNULL(i.eac_estado_implementacion, N'') THEN N'TRANSICION_ESTADO'
               ELSE N'ACTUALIZAR'
           END,
           d.eac_estado_implementacion,
           i.eac_estado_implementacion,
           CASE WHEN d.eac_codigo IS NOT NULL THEN (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) ELSE NULL END,
           (SELECT t.* FROM sgspi.evaluacion_aplicabilidad_control AS t WHERE t.eac_codigo = i.eac_codigo FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
           CONVERT(NVARCHAR(500), SESSION_CONTEXT(N'sgspi_motivo_observacion'))
    FROM   inserted AS i
           LEFT OUTER JOIN deleted AS d ON d.eac_codigo = i.eac_codigo;
END;


GO
/*==================================================================================================
  6. VISTAS DINÁMICAS PARA CAMPOS CALCULADOS E INTEGRACIÓN CON [dbo]
==================================================================================================*/
-- 6.0 Vista de Integración de Seguridad y Alcance por Proceso/UAA
CREATE OR ALTER VIEW sgspi.vw_usuario_rol_alcance_sgspi
AS
SELECT p.per_codigo,
       p.per_identificacion,
       CONCAT(RTRIM(ISNULL(p.per_nombre, '')), ' ', RTRIM(ISNULL(p.per_apellido, ''))) AS per_nombre_completo,
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
-- 6.2 Vista Resumen de Activos por Categoría, Tipo y Criticidad (Reemplaza Tabla Dinámica de ES-GSPI-MR-05)
CREATE OR ALTER VIEW sgspi.vw_resumen_activos_criticidad
AS
SELECT   ISNULL(tac.tac_categoria_iso27005, N'Total general') AS tac_categoria_activo,
         ISNULL(tac.tac_tipo_activo, N'Subtotal categoría') AS tac_tipo_activo,
         SUM(CASE WHEN ai.aci_nivel_criticidad = N'ALTA' THEN 1 ELSE 0 END) AS aci_criticidad_alta,
         SUM(CASE WHEN ai.aci_nivel_criticidad = N'MEDIA' THEN 1 ELSE 0 END) AS aci_criticidad_media,
         SUM(CASE WHEN ai.aci_nivel_criticidad = N'BAJA' THEN 1 ELSE 0 END) AS aci_criticidad_baja,
         COUNT(ai.aci_codigo) AS aci_total_general
FROM     sgspi.activo_informacion AS ai
         INNER JOIN
         sgspi.tipo_activo_catalogo AS tac
         ON tac.tac_codigo = ai.aci_tac_codigo
WHERE    ai.aci_estado_registro = N'VIGENTE'
GROUP BY GROUPING SETS((tac.tac_categoria_iso27005, tac.tac_tipo_activo), (tac.tac_categoria_iso27005), ());


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
        WHERE    enc.enc_identificador = N'ISO/IEC 27001:2022'
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
        WHERE    enc.enc_identificador = N'ISO/IEC 27701:2025'
        GROUP BY ptc.ptc_plt_codigo)
SELECT eia.eia_identificador_evento AS eia_codigo_riesgo_oportunidad,
       eia.eia_escenario_operacional AS eia_riesgo_oportunidad,
       pr.pri_nombre AS pri_proceso,
       CONCAT(N'Activo primario: ', ap.aci_nombre_activo, N' | Activo secundario: ', asop.aci_nombre_activo) AS eia_detalle_del_riesgo,
       CONCAT(N'Posibilidad: ', ep_inh.epr_nombre_nivel, N' (', ep_inh.epr_codigo_letra, N') | Impacto: ', CASE WHEN eia.eia_naturaleza_evento = N'RIESGO' THEN ei_inh.eim_nombre_impacto_negativo ELSE ei_inh.eim_nombre_impacto_positivo END, N' (', ei_inh.eim_codigo, N') | Nivel actual: ', mvr_inh.mvr_nivel_valoracion) AS eia_resultado_actual,
       CONCAT(N'Posibilidad: ', ep_meta.epr_nombre_nivel, N' (', ep_meta.epr_codigo_letra, N') | Impacto: ', CASE WHEN eia.eia_naturaleza_evento = N'RIESGO' THEN ei_meta.eim_nombre_impacto_negativo ELSE ei_meta.eim_nombre_impacto_positivo END, N' (', ei_meta.eim_codigo, N') | Nivel esperado: ', mvr_meta.mvr_nivel_valoracion) AS plt_resultado_esperado,
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
       sgspi.escala_probabilidad AS ep_meta
       ON ep_meta.epr_codigo = pt.plt_epr_codigo_residual_meta
       INNER JOIN
       sgspi.escala_impacto AS ei_meta
       ON ei_meta.eim_codigo = pt.plt_eim_codigo_residual_meta
       INNER JOIN
       sgspi.matriz_valoracion_riesgo AS mvr_meta
       ON mvr_meta.mvr_epr_codigo = pt.plt_epr_codigo_residual_meta
          AND mvr_meta.mvr_eim_codigo = pt.plt_eim_codigo_residual_meta
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
                 STRING_AGG(x.uaa_nombre, N', ') WITHIN GROUP (ORDER BY x.uaa_nombre) AS ado_dependencias_oficinas
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
                 STRING_AGG(c.car_nombre, N', ') WITHIN GROUP (ORDER BY air.air_car_codigo, air.air_uaa_codigo) AS ado_propietarios_activo
        FROM     sgspi.activo_informacion_responsable AS air
                 INNER JOIN
                 dbo.cargo AS c
                 ON c.car_codigo = air.air_car_codigo
        WHERE    air.air_esta_activo = 1
                 AND air.air_tipo_responsabilidad = N'PROPIETARIO'
        GROUP BY air.air_aci_codigo),
       cte_custodios_doc
AS     (SELECT   air.air_aci_codigo,
                 STRING_AGG(c.car_nombre, N', ') WITHIN GROUP (ORDER BY air.air_car_codigo, air.air_uaa_codigo) AS ado_custodios_activo
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
        GROUP BY adi.adi_ado_codigo)
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
       ado.ado_tipo_activo_documental,
       prop.ado_propietarios_activo,
       cust.ado_custodios_activo,
       pdc.pdc_nombre AS ado_periodicidad_generacion,
       sdoc.ado_soporte_registro,
       mdoc.ado_medio_conservacion,
       ado.ado_formato_documental,
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
       ON aci.aci_codigo = ado.ado_aci_codigo
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
       ON idoc.adi_ado_codigo = ado.ado_codigo;