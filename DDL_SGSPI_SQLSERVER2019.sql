/*==================================================================================================
  PROYECTO:     Sistema de Gestión de Seguridad y Privacidad de la Información (SGSPI)
  ENTIDAD:      Universidad Surcolombiana (USCO)
  BASE DATOS:   Integrado con el esquema corporativo [dbo] de la USCO (academia3000)
  MOTOR BD:     Microsoft SQL Server 2019 (Compatibilidad 150)
  CONVENCIÓN:   Estándar Institucional USCO (academia3000):
                1. Todas las llaves primarias y foráneas usan el sufijo [_codigo] (cero [_id]).
                2. Todas las columnas inician con el acrónimo de 3 letras de su tabla ([<acr>_...]).

  MAPA DE ACRÓNIMOS DE TABLAS DEL ESQUEMA [sgspi] (36 TABLAS):
  - [pev] : sgspi.periodo_vigencia                  - [sdo] : sgspi.serie_documental_catalogo
  - [fdv] : sgspi.formato_documental_version        - [sbd] : sgspi.subserie_documental_catalogo
  - [tpr] : sgspi.tipo_proceso_catalogo             - [upc] : sgspi.unidad_productora_cuadro_clasificacion_documental
  - [pri] : sgspi.proceso_institucional             - [ado] : sgspi.activo_documental
  - [piu] : sgspi.proceso_institucional_uaa         - [adu] : sgspi.activo_documental_unidad_productora
  - [fec] : sgspi.factor_entorno_catalogo           - [adp] : sgspi.activo_documental_proceso_institucional
  - [acf] : sgspi.analisis_contexto_factor          - [adr] : sgspi.activo_documental_responsable
  - [pai] : sgspi.parte_interesada                  - [epr] : sgspi.escala_probabilidad
  - [rpi] : sgspi.requisito_parte_interesada        - [eim] : sgspi.escala_impacto
  - [rpp] : sgspi.requisito_parte_interesada_proceso_institucional - [mvr] : sgspi.matriz_valoracion_riesgo
  - [tac] : sgspi.tipo_activo_catalogo              - [eia] : sgspi.evento_incertidumbre_activo
  - [cet] : sgspi.causal_excepcion_transparencia    - [plt] : sgspi.plan_tratamiento
  - [aci] : sgspi.activo_informacion                - [act] : sgspi.actividad_tratamiento
  - [aip] : sgspi.activo_informacion_proceso_institucional - [sga] : sgspi.seguimiento_actividad
  - [ais] : sgspi.activo_informacion_sede           - [crn] : sgspi.control_referencia_normativa
  - [air] : sgspi.activo_informacion_responsable    - [ptc] : sgspi.plan_tratamiento_control_referencia_normativa
  - [sif] : sgspi.sistema_informacion_ficha         - [eac] : sgspi.evaluacion_aplicabilidad_control
  - [msi] : sgspi.modulo_sistema_informacion        - [bas] : sgspi.bitacora_auditoria_sistema

  ACRÓNIMOS REUTILIZADOS DEL ESQUEMA CORPORATIVO [dbo]:
  - [sed] : dbo.sede ([sed_codigo])                 - [car] : dbo.cargo ([car_codigo])
  - [sus] : dbo.sub_sede ([sus_codigo])             - [uac] : dbo.uaa_cargo ([uac_codigo])
  - [esp] : dbo.espacio ([esp_codigo])              - [uap] : dbo.uaa_personal ([uap_codigo])
  - [uaa] : dbo.uaa ([uaa_codigo])                  - [per] : dbo.persona ([per_codigo])
  - [gru] : dbo.grupo ([gru_codigo])                - [usg] : dbo.usuario_grupo ([usg_codigo])
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

-- 1.2 [fdv] Control Documental de Versiones de Formatos SGC/SGSPI por Vigencia
CREATE TABLE sgspi.formato_documental_version (
    fdv_codigo                 SMALLINT       IDENTITY (1, 1) NOT NULL,
    pev_codigo                 SMALLINT       NOT NULL,
    fdv_dominio_funcional      NVARCHAR (40)  NOT NULL, -- 'CONTEXTO_DOFA', 'PARTES_INTERESADAS', 'ACTIVOS_DOCUMENTALES', 'INVENTARIO_ACTIVOS', 'RIESGOS_Y_OPORTUNIDADES'
    fdv_codigo_formato         NVARCHAR (20)  NOT NULL, -- 'ES-GSPI-MR-01', 'ES-GSPI-MR-03', 'ES-GSPI-MR-04', 'ES-GSPI-MR-05', 'ES-GSPI-MR-06'
    fdv_numero_version         NVARCHAR (10)  NOT NULL, -- '02', '04', '01', '01', '02'
    fdv_nombre_oficial_formato NVARCHAR (200) NOT NULL,
    fdv_fecha_emision_formato  DATE           NULL,
    fdv_es_version_activa      BIT            DEFAULT 1 NOT NULL,
    CONSTRAINT PK_fdv_formato_documental_version PRIMARY KEY CLUSTERED (fdv_codigo),
    CONSTRAINT UQ_fdv_vigencia_dominio UNIQUE (pev_codigo, fdv_dominio_funcional),
    CONSTRAINT FK_fdv_periodo_vigencia FOREIGN KEY (pev_codigo) REFERENCES sgspi.periodo_vigencia (pev_codigo),
    CONSTRAINT CK_fdv_dominio_funcional CHECK (fdv_dominio_funcional IN (N'CONTEXTO_DOFA', N'PARTES_INTERESADAS', N'ACTIVOS_DOCUMENTALES', N'INVENTARIO_ACTIVOS', N'RIESGOS_Y_OPORTUNIDADES'))
);

-- 1.3 [tpr] Catálogo de Tipos de Proceso del Sistema Integrado de Gestión (MIPG / SGC)
CREATE TABLE sgspi.tipo_proceso_catalogo (
    tpr_codigo        TINYINT        IDENTITY (1, 1) NOT NULL,
    tpr_identificador NVARCHAR (20)  NOT NULL,
    tpr_nombre        NVARCHAR (50)  NOT NULL, -- 'ESTRATÉGICO', 'MISIONAL', 'APOYO', 'EVALUACIÓN'
    tpr_descripcion   NVARCHAR (255) NULL,
    CONSTRAINT PK_tpr_tipo_proceso_catalogo PRIMARY KEY CLUSTERED (tpr_codigo),
    CONSTRAINT UQ_tpr_identificador UNIQUE (tpr_identificador),
    CONSTRAINT CK_tpr_nombre CHECK (tpr_nombre IN (N'ESTRATÉGICO', N'MISIONAL', N'APOYO', N'EVALUACIÓN'))
);

-- 1.4 [pri] Procesos Institucionales (Los 21 procesos del SGC / SGSPI USCO)
CREATE TABLE sgspi.proceso_institucional (
    pri_codigo           INT            IDENTITY (1, 1) NOT NULL,
    pri_identificador    NVARCHAR (20)  NOT NULL,
    pri_nombre           NVARCHAR (150) NOT NULL,
    tpr_codigo           TINYINT        NOT NULL,
    pri_uaa_codigo_lider INT            NULL, -- FK a [dbo].[uaa]([uaa_codigo])
    pri_car_codigo_lider INT            NULL, -- FK a [dbo].[cargo]([car_codigo])
    pri_esta_activo      BIT            DEFAULT 1 NOT NULL,
    CONSTRAINT PK_pri_proceso_institucional PRIMARY KEY CLUSTERED (pri_codigo),
    CONSTRAINT UQ_pri_nombre UNIQUE (pri_nombre),
    CONSTRAINT FK_pri_tipo_proceso FOREIGN KEY (tpr_codigo) REFERENCES sgspi.tipo_proceso_catalogo (tpr_codigo),
    CONSTRAINT FK_pri_dbo_uaa_lider FOREIGN KEY (pri_uaa_codigo_lider) REFERENCES dbo.uaa (uaa_codigo),
    CONSTRAINT FK_pri_dbo_cargo_lider FOREIGN KEY (pri_car_codigo_lider) REFERENCES dbo.cargo (car_codigo)
);

-- 1.5 [piu] Tabla Puente N:M Proceso Institucional <-> Unidades Académico-Administrativas ([dbo].[uaa])
CREATE TABLE sgspi.proceso_institucional_uaa (
    piu_codigo                   INT IDENTITY (1, 1) NOT NULL,
    pri_codigo                   INT NOT NULL,
    uaa_codigo                   INT NOT NULL, -- FK a [dbo].[uaa]([uaa_codigo])
    piu_es_responsable_principal BIT DEFAULT 0 NOT NULL,
    CONSTRAINT PK_piu_proceso_institucional_uaa PRIMARY KEY CLUSTERED (piu_codigo),
    CONSTRAINT UQ_piu_proceso_institucional_uaa UNIQUE (pri_codigo, uaa_codigo),
    CONSTRAINT FK_piu_proceso_institucional FOREIGN KEY (pri_codigo) REFERENCES sgspi.proceso_institucional (pri_codigo) ON DELETE CASCADE,
    CONSTRAINT FK_piu_dbo_uaa FOREIGN KEY (uaa_codigo) REFERENCES dbo.uaa (uaa_codigo)
);


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
    acf_codigo                  INT            IDENTITY (1, 1) NOT NULL,
    pev_codigo                  SMALLINT       NOT NULL,
    pri_codigo                  INT            NOT NULL,
    fec_codigo                  SMALLINT       NOT NULL,
    acf_ambito_entorno          NVARCHAR (15)  NOT NULL, -- 'INTERNO', 'EXTERNO'
    acf_naturaleza_factor       NVARCHAR (15)  NOT NULL, -- 'DEBILIDAD', 'FORTALEZA', 'AMENAZA', 'OPORTUNIDAD'
    acf_descripcion_situacion   NVARCHAR (MAX) NOT NULL,
    acf_nivel_prioridad         NVARCHAR (10)  NOT NULL, -- 'Alta', 'Media', 'Baja'
    acf_impacto_sistema_gestion NVARCHAR (MAX) NULL,
    acf_accion_propuesta        NVARCHAR (MAX) NULL,
    acf_estado_registro         NVARCHAR (30)  DEFAULT N'BORRADOR' NOT NULL,
    acf_per_codigo_creador      INT            NOT NULL, -- FK a [dbo].[persona]([per_codigo])
    acf_per_codigo_aprobador    INT            NULL, -- FK a [dbo].[persona]([per_codigo])
    acf_fecha_creacion          DATETIME2 (0)  DEFAULT SYSDATETIME() NOT NULL,
    acf_fecha_actualizacion     DATETIME2 (0)  DEFAULT SYSDATETIME() NOT NULL,
    CONSTRAINT PK_acf_analisis_contexto_factor PRIMARY KEY CLUSTERED (acf_codigo),
    CONSTRAINT FK_acf_periodo_vigencia FOREIGN KEY (pev_codigo) REFERENCES sgspi.periodo_vigencia (pev_codigo),
    CONSTRAINT FK_acf_proceso_institucional FOREIGN KEY (pri_codigo) REFERENCES sgspi.proceso_institucional (pri_codigo),
    CONSTRAINT FK_acf_factor_entorno FOREIGN KEY (fec_codigo) REFERENCES sgspi.factor_entorno_catalogo (fec_codigo),
    CONSTRAINT FK_acf_dbo_persona_creador FOREIGN KEY (acf_per_codigo_creador) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT FK_acf_dbo_persona_aprobador FOREIGN KEY (acf_per_codigo_aprobador) REFERENCES dbo.persona (per_codigo),
    -- RN-DOFA-01 y RN-DOFA-02: Coherencia estricta entre ámbito (Interno/Externo) y naturaleza (DOFA)
    CONSTRAINT CK_acf_ambito_naturaleza CHECK ((acf_ambito_entorno = N'INTERNO'
                                                AND acf_naturaleza_factor IN (N'DEBILIDAD', N'FORTALEZA'))
                                               OR (acf_ambito_entorno = N'EXTERNO'
                                                   AND acf_naturaleza_factor IN (N'AMENAZA', N'OPORTUNIDAD'))),
    CONSTRAINT CK_acf_nivel_prioridad CHECK (acf_nivel_prioridad IN (N'Alta', N'Media', N'Baja')),
    -- RN-DOFA-03: Si la prioridad es Alta y no está en borrador, exige Impacto y Acción Propuesta
    CONSTRAINT CK_acf_prioridad_alta_campos CHECK (acf_estado_registro = N'BORRADOR'
                                                   OR acf_nivel_prioridad <> N'Alta'
                                                   OR (LEN(TRIM(ISNULL(acf_impacto_sistema_gestion, N''))) > 0
                                                       AND LEN(TRIM(ISNULL(acf_accion_propuesta, N''))) > 0)),
    CONSTRAINT CK_acf_estado_registro CHECK (acf_estado_registro IN (N'BORRADOR', N'EN_VALIDACION_LIDER', N'EN_REVISION_SGSPI', N'OBSERVADO', N'VIGENTE', N'HISTORICO'))
);


GO
/*==================================================================================================
  3. DOMINIO DE PARTES INTERESADAS (DOCUMENTO 3: ES-GSPI-MR-03)
==================================================================================================*/
-- 3.1 [pai] Catálogo de Partes Interesadas (Internas y Externas)
CREATE TABLE sgspi.parte_interesada (
    pai_codigo          INT            IDENTITY (1, 1) NOT NULL,
    pai_nombre          NVARCHAR (150) NOT NULL,
    pai_origen          NVARCHAR (15)  NOT NULL, -- 'Interna', 'Externa'
    pai_descripcion_rol NVARCHAR (255) NULL,
    pai_esta_activa     BIT            DEFAULT 1 NOT NULL,
    CONSTRAINT PK_pai_parte_interesada PRIMARY KEY CLUSTERED (pai_codigo),
    CONSTRAINT UQ_pai_nombre UNIQUE (pai_nombre),
    CONSTRAINT CK_pai_origen CHECK (pai_origen IN (N'Interna', N'Externa'))
);

-- 3.2 [rpi] Necesidades, Expectativas y Requisitos por Parte Interesada
CREATE TABLE sgspi.requisito_parte_interesada (
    rpi_codigo                  INT            IDENTITY (1, 1) NOT NULL,
    pev_codigo                  SMALLINT       NOT NULL,
    pai_codigo                  INT            NOT NULL,
    rpi_referencia_cuestionario NVARCHAR (30)  NULL, -- Ej: '6-7-8', 'N/A'
    rpi_necesidad_expectativa   NVARCHAR (MAX) NOT NULL,
    rpi_nivel_poder             NVARCHAR (10)  NOT NULL, -- 'Alto', 'Medio', 'Bajo'
    rpi_nivel_interes           NVARCHAR (10)  NOT NULL, -- 'Alto', 'Medio', 'Bajo'
    -- Campo Calculado en Tiempo de Ejecución #3: Clasificación según Poder vs Interés
    rpi_clasificacion_impacto   AS             (CASE WHEN rpi_nivel_poder = N'Alto'
                                                          AND rpi_nivel_interes IN (N'Alto', N'Medio') THEN N'CUIDADO "Tratar como requisito legal y otros requisitos"' WHEN (rpi_nivel_poder = N'Alto'
                                                                                                                                                                              AND rpi_nivel_interes = N'Bajo')
                                                                                                                                                                             OR (rpi_nivel_poder = N'Medio'
                                                                                                                                                                                 AND rpi_nivel_interes IN (N'Alto', N'Medio')) THEN N'ATENCIÓN "Mantener Satisfecho"' WHEN (rpi_nivel_poder = N'Medio'
                                                                                                                                                                                                                                                                            AND rpi_nivel_interes = N'Bajo')
                                                                                                                                                                                                                                                                           OR (rpi_nivel_poder = N'Bajo'
                                                                                                                                                                                                                                                                               AND rpi_nivel_interes = N'Alto') THEN N'MITIGANTE "Mantener Informado"' ELSE N'SIN PROBLEMA "Monitorear por si cambia de categoria"' END),
    rpi_nivel_cumplimiento      NVARCHAR (10)  NULL, -- 'Alto', 'Medio', 'Bajo'
    -- Campo Calculado en Tiempo de Ejecución #4: Prioridad de Acción
    rpi_prioridad_accion        AS             (CASE rpi_nivel_cumplimiento WHEN N'Alto' THEN N'Prioridad alta' WHEN N'Medio' THEN N'Prioridad media' WHEN N'Bajo' THEN N'Prioridad baja' ELSE NULL END),
    rpi_mecanismo_seguimiento   NVARCHAR (255) NULL,
    rpi_estado_registro         NVARCHAR (30)  DEFAULT N'VIGENTE' NOT NULL,
    rpi_fecha_creacion          DATETIME2 (0)  DEFAULT SYSDATETIME() NOT NULL,
    CONSTRAINT PK_rpi_requisito_parte_interesada PRIMARY KEY CLUSTERED (rpi_codigo),
    CONSTRAINT FK_rpi_periodo_vigencia FOREIGN KEY (pev_codigo) REFERENCES sgspi.periodo_vigencia (pev_codigo),
    CONSTRAINT FK_rpi_parte_interesada FOREIGN KEY (pai_codigo) REFERENCES sgspi.parte_interesada (pai_codigo),
    CONSTRAINT CK_rpi_nivel_poder CHECK (rpi_nivel_poder IN (N'Alto', N'Medio', N'Bajo')),
    CONSTRAINT CK_rpi_nivel_interes CHECK (rpi_nivel_interes IN (N'Alto', N'Medio', N'Bajo')),
    CONSTRAINT CK_rpi_nivel_cumplimiento CHECK (rpi_nivel_cumplimiento IS NULL
                                                OR rpi_nivel_cumplimiento IN (N'Alto', N'Medio', N'Bajo'))
);

-- 3.3 [rpp] Relación N:M Requisito de Parte Interesada <-> Proceso Institucional
CREATE TABLE sgspi.requisito_parte_interesada_proceso_institucional (
    rpp_codigo         INT           IDENTITY (1, 1) NOT NULL,
    rpi_codigo         INT           NOT NULL,
    pri_codigo         INT           NOT NULL,
    rpp_fecha_registro DATETIME2 (0) DEFAULT SYSDATETIME() NOT NULL,
    CONSTRAINT PK_rpp_requisito_parte_interesada_proceso_institucional PRIMARY KEY CLUSTERED (rpp_codigo),
    CONSTRAINT UQ_rpp_requisito_parte_interesada_proceso_institucional UNIQUE (rpi_codigo, pri_codigo),
    CONSTRAINT FK_rpp_requisito_parte_interesada FOREIGN KEY (rpi_codigo) REFERENCES sgspi.requisito_parte_interesada (rpi_codigo) ON DELETE CASCADE,
    CONSTRAINT FK_rpp_proceso_institucional FOREIGN KEY (pri_codigo) REFERENCES sgspi.proceso_institucional (pri_codigo)
);


GO
/*==================================================================================================
  4. DOMINIO DE INVENTARIO Y CLASIFICACIÓN DE ACTIVOS (DOCUMENTO 4: ES-GSPI-MR-05)
     Articulado con [dbo].[uaa], [dbo].[sede], [dbo].[sub_sede], [dbo].[espacio], [dbo].[cargo] y [dbo].[persona]
==================================================================================================*/
-- 4.1 [tac] Taxonomía Jerárquica de Activos ISO/IEC 27005 (Categoría -> Tipo -> Subtipo)
CREATE TABLE sgspi.tipo_activo_catalogo (
    tac_codigo              SMALLINT       IDENTITY (1, 1) NOT NULL,
    tac_categoria_iso27005  NVARCHAR (20)  NOT NULL, -- 'Primario', 'Soporte'
    tac_tipo_activo         NVARCHAR (80)  NOT NULL, -- 'Información', 'Procesos y Actividades del Negocio', 'Hardware', 'Software', 'Red', 'Personal', 'Sitio', 'Estructura de la organización', 'Ubicación'
    tac_subtipo_activo      NVARCHAR (120) NOT NULL, -- 'Servidor de Aplicaciones', 'Equipo de Computo', 'Aplicaciones Específicas del Negocio', etc.
    tac_ejemplos_referencia NVARCHAR (255) NULL,
    CONSTRAINT PK_tac_tipo_activo_catalogo PRIMARY KEY CLUSTERED (tac_codigo),
    CONSTRAINT UQ_tac_jerarquia UNIQUE (tac_categoria_iso27005, tac_tipo_activo, tac_subtipo_activo),
    -- RN-ACT-01: Integridad Taxonómica Primario vs Soporte
    CONSTRAINT CK_tac_categoria_coherencia CHECK ((tac_categoria_iso27005 = N'Primario'
                                                   AND tac_tipo_activo IN (N'Información', N'Procesos y Actividades del Negocio'))
                                                  OR (tac_categoria_iso27005 = N'Soporte'
                                                      AND tac_tipo_activo IN (N'Hardware', N'Software', N'Red', N'Personal', N'Sitio', N'Estructura de la organización', N'Ubicación')))
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

-- 4.3 [aci] Inventario Maestro de Activos de Información (511 activos base)
CREATE TABLE sgspi.activo_informacion (
    aci_codigo                         INT            IDENTITY (1, 1) NOT NULL,
    aci_codigo_inventario              NVARCHAR (30)  NOT NULL,
    aci_nombre_activo                  NVARCHAR (255) NOT NULL,
    aci_descripcion_detallada          NVARCHAR (MAX) NULL,
    tac_codigo                         SMALLINT       NOT NULL,
    uaa_codigo                         INT            NULL, -- FK a [dbo].[uaa]([uaa_codigo])
    esp_codigo                         INT            NULL, -- FK a [dbo].[espacio]([esp_codigo])
    aci_es_transversal_sedes           BIT            DEFAULT 0 NOT NULL,
    aci_cantidad_unidades              INT            DEFAULT 1 NOT NULL,
    -- Clasificación de Transparencia y Privacidad
    aci_clasificacion_transparencia    NVARCHAR (20)  NOT NULL, -- 'PÚBLICA', 'CLASIFICADA', 'RESERVADA', 'NO CLASIFICADA'
    cet_codigo                         SMALLINT       NULL,
    aci_alcance_excepcion              NVARCHAR (15)  DEFAULT N'No aplica' NOT NULL, -- 'Parcial', 'Total', 'No aplica'
    aci_contiene_datos_personales      BIT            DEFAULT 0 NOT NULL,
    aci_contiene_datos_menores         BIT            NULL,
    aci_categoria_dato_personal        NVARCHAR (20)  NULL, -- 'PRIVADOS', 'SEMIPRIVADOS', 'PUBLICOS'
    -- Valoración CID almacenada como entero (1=Baja, 2=Media, 3=Alta)
    aci_valor_confidencialidad         TINYINT        NOT NULL,
    aci_valor_integridad               TINYINT        NOT NULL,
    aci_valor_disponibilidad           TINYINT        NOT NULL,
    -- Campos Calculados en Tiempo de Ejecución #5: Etiquetas CID, Puntaje y Nivel de Criticidad
    aci_nivel_confidencialidad         AS             (CASE aci_valor_confidencialidad WHEN 3 THEN N'Alta' WHEN 2 THEN N'Media' ELSE N'Baja' END),
    aci_nivel_integridad               AS             (CASE aci_valor_integridad WHEN 3 THEN N'Alta' WHEN 2 THEN N'Media' ELSE N'Baja' END),
    aci_nivel_disponibilidad           AS             (CASE aci_valor_disponibilidad WHEN 3 THEN N'Alta' WHEN 2 THEN N'Media' ELSE N'Baja' END),
    aci_puntaje_criticidad             AS             (CAST (aci_valor_confidencialidad + aci_valor_integridad + aci_valor_disponibilidad AS TINYINT)) PERSISTED,
    aci_nivel_criticidad               AS             (CASE WHEN (aci_valor_confidencialidad + aci_valor_integridad + aci_valor_disponibilidad) >= 7 THEN N'Alta' WHEN (aci_valor_confidencialidad + aci_valor_integridad + aci_valor_disponibilidad) >= 5 THEN N'Media' ELSE N'Baja' END) PERSISTED,
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
    CONSTRAINT FK_aci_tipo_activo FOREIGN KEY (tac_codigo) REFERENCES sgspi.tipo_activo_catalogo (tac_codigo),
    CONSTRAINT FK_aci_dbo_uaa FOREIGN KEY (uaa_codigo) REFERENCES dbo.uaa (uaa_codigo),
    CONSTRAINT FK_aci_dbo_espacio FOREIGN KEY (esp_codigo) REFERENCES dbo.espacio (esp_codigo),
    CONSTRAINT FK_aci_causal_excepcion FOREIGN KEY (cet_codigo) REFERENCES sgspi.causal_excepcion_transparencia (cet_codigo),
    CONSTRAINT FK_aci_dbo_persona_creador FOREIGN KEY (aci_per_codigo_creador) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT FK_aci_dbo_persona_aprobador FOREIGN KEY (aci_per_codigo_aprobador) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_aci_valores_cid CHECK (aci_valor_confidencialidad IN (1, 2, 3)
                                         AND aci_valor_integridad IN (1, 2, 3)
                                         AND aci_valor_disponibilidad IN (1, 2, 3)),
    CONSTRAINT CK_aci_transparencia CHECK (aci_clasificacion_transparencia IN (N'PÚBLICA', N'CLASIFICADA', N'RESERVADA', N'NO CLASIFICADA')),
    CONSTRAINT CK_aci_alcance_excepcion CHECK (aci_alcance_excepcion IN (N'Parcial', N'Total', N'No aplica')),
    -- RN-ACT-02: Si es RESERVADA, la confidencialidad no puede ser Baja (1)
    CONSTRAINT CK_aci_reserva_confidencialidad CHECK (aci_clasificacion_transparencia <> N'RESERVADA'
                                                      OR aci_valor_confidencialidad >= 2),
    -- RN-ACT-03: Coherencia de Datos Personales
    CONSTRAINT CK_aci_categoria_pii CHECK (aci_categoria_dato_personal IS NULL
                                           OR aci_categoria_dato_personal IN (N'PRIVADOS', N'SEMIPRIVADOS', N'PUBLICOS')),
    CONSTRAINT CK_aci_pii_privados_no_publico_bajo CHECK (aci_contiene_datos_personales = 0
                                                          OR (ISNULL(aci_categoria_dato_personal, N'') <> N'PRIVADOS'
                                                              AND ISNULL(aci_contiene_datos_menores, 0) = 0)
                                                          OR NOT (aci_clasificacion_transparencia = N'PÚBLICA'
                                                                  AND aci_valor_confidencialidad = 1)),
    CONSTRAINT CK_aci_estado_registro CHECK (aci_estado_registro IN (N'BORRADOR', N'EN_VALIDACION_LIDER', N'EN_REVISION_SGSPI', N'OBSERVADO', N'VIGENTE', N'INACTIVO', N'HISTORICO'))
);

-- 4.4 [aip], [ais], [air] Tablas Asociativas N:M de Activos de Información
CREATE TABLE sgspi.activo_informacion_proceso_institucional (
    aip_codigo INT IDENTITY (1, 1) NOT NULL,
    aci_codigo INT NOT NULL,
    pri_codigo INT NOT NULL,
    CONSTRAINT PK_aip_activo_informacion_proceso_institucional PRIMARY KEY CLUSTERED (aip_codigo),
    CONSTRAINT UQ_aip_activo_informacion_proceso_institucional UNIQUE (aci_codigo, pri_codigo),
    CONSTRAINT FK_aip_activo_informacion FOREIGN KEY (aci_codigo) REFERENCES sgspi.activo_informacion (aci_codigo) ON DELETE CASCADE,
    CONSTRAINT FK_aip_proceso_institucional FOREIGN KEY (pri_codigo) REFERENCES sgspi.proceso_institucional (pri_codigo)
);

CREATE TABLE sgspi.activo_informacion_sede (
    ais_codigo INT IDENTITY (1, 1) NOT NULL,
    aci_codigo INT NOT NULL,
    sed_codigo INT NOT NULL, -- FK a [dbo].[sede]([sed_codigo])
    sus_codigo INT NULL, -- FK a [dbo].[sub_sede]([sus_codigo])
    CONSTRAINT PK_ais_activo_informacion_sede PRIMARY KEY CLUSTERED (ais_codigo),
    CONSTRAINT UQ_ais_activo_informacion_sede_subsede UNIQUE (aci_codigo, sed_codigo, sus_codigo),
    CONSTRAINT FK_ais_activo_informacion FOREIGN KEY (aci_codigo) REFERENCES sgspi.activo_informacion (aci_codigo) ON DELETE CASCADE,
    CONSTRAINT FK_ais_dbo_sede FOREIGN KEY (sed_codigo) REFERENCES dbo.sede (sed_codigo),
    CONSTRAINT FK_ais_dbo_sub_sede FOREIGN KEY (sus_codigo) REFERENCES dbo.sub_sede (sus_codigo)
);

CREATE TABLE sgspi.activo_informacion_responsable (
    air_codigo               INT           IDENTITY (1, 1) NOT NULL,
    aci_codigo               INT           NOT NULL,
    car_codigo               INT           NOT NULL, -- FK a [dbo].[cargo]([car_codigo]): Cargo responsable (ISO 27001)
    uaa_codigo               INT           NOT NULL, -- FK a [dbo].[uaa]([uaa_codigo]): Dependencia del cargo
    uac_codigo               INT           NULL, -- FK opcional a [dbo].[uaa_cargo]([uac_codigo]): Plaza de planta
    uap_codigo               INT           NULL, -- FK opcional a [dbo].[uaa_personal]([uap_codigo]): Vinculación del funcionario actual
    air_tipo_responsabilidad NVARCHAR (20) NOT NULL, -- 'PROPIETARIO', 'CUSTODIO'
    air_esta_activo          BIT           DEFAULT 1 NOT NULL,
    CONSTRAINT PK_air_activo_informacion_responsable PRIMARY KEY CLUSTERED (air_codigo),
    -- Incluye uaa_codigo y uap_codigo para permitir el mismo cargo en distintas UAA o distintos funcionarios
    CONSTRAINT UQ_air_activo_informacion_responsable UNIQUE (aci_codigo, car_codigo, uaa_codigo, uap_codigo, air_tipo_responsabilidad),
    CONSTRAINT FK_air_activo_informacion FOREIGN KEY (aci_codigo) REFERENCES sgspi.activo_informacion (aci_codigo) ON DELETE CASCADE,
    CONSTRAINT FK_air_dbo_cargo FOREIGN KEY (car_codigo) REFERENCES dbo.cargo (car_codigo),
    CONSTRAINT FK_air_dbo_uaa FOREIGN KEY (uaa_codigo) REFERENCES dbo.uaa (uaa_codigo),
    CONSTRAINT FK_air_dbo_uaa_cargo FOREIGN KEY (uac_codigo) REFERENCES dbo.uaa_cargo (uac_codigo),
    CONSTRAINT FK_air_dbo_uaa_personal FOREIGN KEY (uap_codigo) REFERENCES dbo.uaa_personal (uap_codigo),
    CONSTRAINT CK_air_tipo_responsabilidad CHECK (air_tipo_responsabilidad IN (N'PROPIETARIO', N'CUSTODIO'))
);

-- 4.5 [sif] y [msi] Ficha Técnica de Sistemas de Información y sus Módulos (Los 17 Sistemas USCO)
CREATE TABLE sgspi.sistema_informacion_ficha (
    sif_codigo               INT            IDENTITY (1, 1) NOT NULL,
    aci_codigo               INT            NULL,
    sif_nombre_sistema       NVARCHAR (150) NOT NULL,
    sif_modalidad_desarrollo NVARCHAR (50)  NOT NULL, -- 'PROPIO', 'PROPIO EN DESARROLLO', 'CODIGO ABIERTO ADAPTADO', 'COMERCIAL TERCERO'
    sif_fabricante_proveedor NVARCHAR (150) NULL,
    sif_descripcion_general  NVARCHAR (MAX) NOT NULL,
    CONSTRAINT PK_sif_sistema_informacion_ficha PRIMARY KEY CLUSTERED (sif_codigo),
    CONSTRAINT FK_sif_activo_informacion FOREIGN KEY (aci_codigo) REFERENCES sgspi.activo_informacion (aci_codigo)
);

CREATE TABLE sgspi.modulo_sistema_informacion (
    msi_codigo            INT            IDENTITY (1, 1) NOT NULL,
    sif_codigo            INT            NOT NULL,
    msi_nombre_modulo     NVARCHAR (200) NOT NULL,
    msi_usuarios_objetivo NVARCHAR (150) NULL,
    CONSTRAINT PK_msi_modulo_sistema_informacion PRIMARY KEY CLUSTERED (msi_codigo),
    CONSTRAINT FK_msi_sistema_informacion FOREIGN KEY (sif_codigo) REFERENCES sgspi.sistema_informacion_ficha (sif_codigo) ON DELETE CASCADE
);


GO
/*==================================================================================================
  4B. DOMINIO DE ACTIVOS DE LA INFORMACIÓN DOCUMENTAL Y ARCHIVÍSTICA (DOCUMENTO PARALELO: ES-GSPI-MR-04)
      Normativa: Ley 594/2000 (TRD/CCD), Ley 1712/2014, Decreto 103/2015, Decreto 1080/2015, Ley 1581/2012, ISO 27001
      Articulado con [dbo].[uaa], [dbo].[cargo], [dbo].[uaa_cargo], [dbo].[uaa_personal] y [dbo].[persona]
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
    sdo_codigo          SMALLINT       NOT NULL, -- FK a [sgspi].[serie_documental_catalogo]([sdo_codigo])
    sbd_numero_ccd      SMALLINT       NOT NULL, -- COD6: Número secuencial de la subserie dentro de la serie
    sbd_nombre_subserie NVARCHAR (200) NOT NULL,
    sbd_esta_activa     BIT            DEFAULT 1 NOT NULL,
    CONSTRAINT PK_sbd_subserie_documental_catalogo PRIMARY KEY CLUSTERED (sbd_codigo),
    CONSTRAINT UQ_sbd_serie_numero UNIQUE (sdo_codigo, sbd_numero_ccd),
    CONSTRAINT UQ_sbd_serie_nombre UNIQUE (sdo_codigo, sbd_nombre_subserie),
    CONSTRAINT FK_sbd_serie_documental FOREIGN KEY (sdo_codigo) REFERENCES sgspi.serie_documental_catalogo (sdo_codigo),
    CONSTRAINT CK_sbd_numero_ccd_positivo CHECK (sbd_numero_ccd >= 1)
);

-- 4B.3 [upc] Estructura Jerárquica de Unidades Productoras del Cuadro de Clasificación Documental (Niveles 1..4: cod1..cod4)
CREATE TABLE sgspi.unidad_productora_cuadro_clasificacion_documental (
    upc_codigo               INT            IDENTITY (1, 1) NOT NULL,
    upc_codigo_padre         INT            NULL, -- FK autorreferenciada al nivel superior (Sección -> Subsección -> N1 -> N2)
    uaa_codigo               INT            NULL, -- FK a [dbo].[uaa]([uaa_codigo]): Equivalencia organizacional en academia3000
    upc_nivel_jerarquico     TINYINT        NOT NULL, -- 1=Sección (cod1), 2=Subsección (cod2), 3=Subsección N1 (cod3), 4=Subsección N2 (cod4)
    upc_prefijo_archivistico NVARCHAR (20)  NOT NULL, -- Ej: '1', '1.1', '1.1.1', '5.1.1.2'
    upc_nombre_unidad        NVARCHAR (150) NOT NULL, -- Ej: 'RECTORIA', 'SECRETARIA GENERAL', 'AREA GESTION DOCUMENTAL'
    upc_esta_activa          BIT            DEFAULT 1 NOT NULL,
    CONSTRAINT PK_upc_unidad_productora_cuadro_clasificacion_documental PRIMARY KEY CLUSTERED (upc_codigo),
    CONSTRAINT UQ_upc_prefijo_archivistico UNIQUE (upc_prefijo_archivistico),
    CONSTRAINT FK_upc_unidad_padre FOREIGN KEY (upc_codigo_padre) REFERENCES sgspi.unidad_productora_cuadro_clasificacion_documental (upc_codigo),
    CONSTRAINT FK_upc_dbo_uaa FOREIGN KEY (uaa_codigo) REFERENCES dbo.uaa (uaa_codigo),
    CONSTRAINT CK_upc_nivel_jerarquico CHECK (upc_nivel_jerarquico BETWEEN 1 AND 4)
);

-- 4B.4 [ado] Matriz de Inventario y Clasificación de Activos de la Información Documental (ES-GSPI-MR-04: 194 registros consolidados)
CREATE TABLE sgspi.activo_documental (
    ado_codigo                          INT            IDENTITY (1, 1) NOT NULL,
    pev_codigo                          SMALLINT       NOT NULL, -- FK a [sgspi].[periodo_vigencia]([pev_codigo])
    aci_codigo                          INT            NULL, -- FK opcional a [sgspi].[activo_informacion]([aci_codigo]) para enlace con ES-GSPI-MR-05/06
    sdo_codigo                          SMALLINT       NOT NULL, -- FK a [sgspi].[serie_documental_catalogo]([sdo_codigo])
    sbd_codigo                          INT            NULL, -- FK nullable a [sgspi].[subserie_documental_catalogo]([sbd_codigo]) (NULL si la serie no tiene subserie)
    ado_nombre_activo                   NVARCHAR (255) NOT NULL, -- Columna NOMBRE
    ado_descripcion                     NVARCHAR (MAX) NOT NULL, -- Columna Descripción (Tipos documentales del expediente)
    ado_tipo_activo_documental          NVARCHAR (80)  DEFAULT N'Informacion y datos de la Universidad' NOT NULL,
    ado_periodicidad_generacion         NVARCHAR (30)  NOT NULL, -- 'A solicitud', 'Diaria', 'Semanal', 'Mensual', 'Bimensual', 'Trimestral', 'Cuatrimestral', 'Semestral', 'Anual', 'Eventual'
    ado_soporte_registro                NVARCHAR (20)  DEFAULT N'Físico/Digital' NOT NULL, -- 'Físico', 'Digital', 'Físico/Digital'
    ado_medio_conservacion              NVARCHAR (25)  DEFAULT N'Físico/Electrónico' NOT NULL, -- 'Físico', 'Electrónico', 'Físico/Electrónico'
    ado_formato_documental              NVARCHAR (100) DEFAULT N'Documento de texto' NOT NULL,
    ado_idioma                          NVARCHAR (30)  DEFAULT N'Español' NOT NULL, -- 'Español', 'Ingles', 'Español/Ingles', 'Frances'
    ado_fecha_ingreso_tabla_retencion   DATE           NULL,
    ado_fecha_ingreso_archivo           DATE           NULL,
    -- Sección 2: Clasificación del Activo (ISO 27001) - Solo se almacena el entero 1..3 (corrige error de digitación D=1 en Disponibilidad=Alto)
    ado_valor_confidencialidad          TINYINT        NOT NULL, -- 3=Alta (Pública Reservada), 2=Medio (Clasificada), 1=Bajo (Pública)
    ado_valor_integridad                TINYINT        NOT NULL, -- 3=Alto, 2=Medio, 1=Bajo
    ado_valor_disponibilidad            TINYINT        NOT NULL, -- 3=Alto, 2=Medio, 1=Bajo
    -- Campos Calculados en Tiempo de Ejecución: Etiquetas CID, Puntaje y Criticidad del Activo Documental
    ado_nivel_confidencialidad          AS             (CASE ado_valor_confidencialidad WHEN 3 THEN N'Pública Reservada / Confidencial =Alta' WHEN 2 THEN N'Clasificada / Uso Interno = Medio' ELSE N'Información Pública / Pública =Bajo' END),
    ado_nivel_integridad                AS             (CASE ado_valor_integridad WHEN 3 THEN N'Alto' WHEN 2 THEN N'Medio' ELSE N'Bajo' END),
    ado_nivel_disponibilidad            AS             (CASE ado_valor_disponibilidad WHEN 3 THEN N'Alto' WHEN 2 THEN N'Medio' ELSE N'Bajo' END),
    ado_puntaje_criticidad              AS             (CAST (ado_valor_confidencialidad + ado_valor_integridad + ado_valor_disponibilidad AS TINYINT)) PERSISTED,
    ado_nivel_criticidad                AS             (CASE WHEN (ado_valor_confidencialidad + ado_valor_integridad + ado_valor_disponibilidad) >= 7 THEN N'ALTA' WHEN (ado_valor_confidencialidad + ado_valor_integridad + ado_valor_disponibilidad) >= 5 THEN N'MEDIA' ELSE N'BAJA' END) PERSISTED,
    ado_estado_publicacion              NVARCHAR (40)  NOT NULL, -- 'Publicada ( Externo - Internet)', 'Publicada ( Interno - Intranet)', 'No publicada'
    ado_lugar_consulta_ubicacion        NVARCHAR (255) NOT NULL, -- URL portal de transparencia o nombre de dependencia/archivo
    -- Sección 3: Datos Personales (Ley 1581 de 2012)
    ado_contiene_datos_personales       NVARCHAR (15)  NOT NULL, -- 'Si', 'No', 'No Aplica'
    ado_contiene_datos_menores          NVARCHAR (15)  DEFAULT N'No Aplica' NOT NULL, -- 'Si', 'No', 'No Aplica'
    ado_tipo_dato_personal              NVARCHAR (40)  DEFAULT N'No Aplica' NOT NULL, -- 'Dato personal privado', 'Dato personal público', 'Dato semiprivado', 'Dato sensible', 'No Aplica'
    ado_finalidad_recoleccion_pii       NVARCHAR (500) DEFAULT N'No Aplica' NOT NULL,
    ado_existe_autorizacion_pii         NVARCHAR (15)  DEFAULT N'No Aplica' NOT NULL, -- 'Si', 'No', 'No Aplica'
    -- Sección 4: Índice de Información Clasificada y Reservada (Decreto 103 de 2015 / Ley 1712 de 2014)
    cet_codigo                          SMALLINT       NULL, -- FK opcional a [sgspi].[causal_excepcion_transparencia]([cet_codigo])
    ado_objeto_legitimo_excepcion       NVARCHAR (150) DEFAULT N'No Aplica' NOT NULL, -- 'Si', 'No', 'No Aplica' o causal específica
    ado_fundamento_constitucional_legal NVARCHAR (150) DEFAULT N'No Aplica' NOT NULL, -- Ej: 'Ley 1712 de 2014', 'No Aplica'
    ado_fundamento_juridico_excepcion   NVARCHAR (150) DEFAULT N'No Aplica' NOT NULL, -- Ej: 'Ley 1712 de 2014', 'No Aplica'
    ado_alcance_reserva                 NVARCHAR (30)  DEFAULT N'No Aplica' NOT NULL, -- 'Reserva total', 'Reserva parcial', 'Sin reserva', 'No Aplica'
    ado_fecha_clasificacion_reserva     DATE           NULL,
    ado_tiempo_clasificacion_reserva    NVARCHAR (50)  DEFAULT N'No Aplica' NOT NULL, -- 'Indefinida', '15 años', 'No Aplica'
    -- Umbrales de Infraestructura Crítica Cibernética (ICC) presentes en el catálogo de ES-GSPI-MR-04
    ado_supera_umbral_social_icc        BIT            DEFAULT 0 NOT NULL,
    ado_supera_umbral_economico_icc     BIT            DEFAULT 0 NOT NULL,
    ado_supera_umbral_ambiental_icc     BIT            DEFAULT 0 NOT NULL,
    ado_es_infraestructura_critica_icc  AS             (CASE WHEN ado_supera_umbral_social_icc = 1
                                                                  OR ado_supera_umbral_economico_icc = 1
                                                                  OR ado_supera_umbral_ambiental_icc = 1 THEN CAST (1 AS BIT) ELSE CAST (0 AS BIT) END),
    -- Control de ciclo de vida y firmas (Articulado con [dbo].[persona])
    ado_estado_registro                 NVARCHAR (30)  DEFAULT N'BORRADOR' NOT NULL,
    ado_per_codigo_creador              INT            NOT NULL, -- FK a [dbo].[persona]([per_codigo])
    ado_per_codigo_revisor_archivo      INT            NULL, -- FK a [dbo].[persona]([per_codigo]): Aval Gestión Documental / Secretaría General
    ado_per_codigo_aprobador_sgspi      INT            NULL, -- FK a [dbo].[persona]([per_codigo]): Aprobación Oficial de Privacidad / Líder SGSPI
    ado_fecha_creacion                  DATETIME2 (0)  DEFAULT SYSDATETIME() NOT NULL,
    ado_fecha_actualizacion             DATETIME2 (0)  DEFAULT SYSDATETIME() NOT NULL,
    CONSTRAINT PK_ado_activo_documental PRIMARY KEY CLUSTERED (ado_codigo),
    CONSTRAINT UQ_ado_vigencia_serie_subserie_nombre UNIQUE (pev_codigo, sdo_codigo, sbd_codigo, ado_nombre_activo),
    CONSTRAINT FK_ado_periodo_vigencia FOREIGN KEY (pev_codigo) REFERENCES sgspi.periodo_vigencia (pev_codigo),
    CONSTRAINT FK_ado_activo_informacion FOREIGN KEY (aci_codigo) REFERENCES sgspi.activo_informacion (aci_codigo),
    CONSTRAINT FK_ado_serie_documental FOREIGN KEY (sdo_codigo) REFERENCES sgspi.serie_documental_catalogo (sdo_codigo),
    CONSTRAINT FK_ado_subserie_documental FOREIGN KEY (sbd_codigo) REFERENCES sgspi.subserie_documental_catalogo (sbd_codigo),
    CONSTRAINT FK_ado_causal_excepcion FOREIGN KEY (cet_codigo) REFERENCES sgspi.causal_excepcion_transparencia (cet_codigo),
    CONSTRAINT FK_ado_dbo_persona_creador FOREIGN KEY (ado_per_codigo_creador) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT FK_ado_dbo_persona_revisor_archivo FOREIGN KEY (ado_per_codigo_revisor_archivo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT FK_ado_dbo_persona_aprobador_sgspi FOREIGN KEY (ado_per_codigo_aprobador_sgspi) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_ado_valores_cid CHECK (ado_valor_confidencialidad IN (1, 2, 3)
                                         AND ado_valor_integridad IN (1, 2, 3)
                                         AND ado_valor_disponibilidad IN (1, 2, 3)),
    CONSTRAINT CK_ado_tipo_activo_documental CHECK (ado_tipo_activo_documental IN (N'Informacion y datos de la Universidad', N'Sistemas de información y aplicaciones de Software', N'Dispositivos de Tecnologías de información- Hardware', N'Soporte para almacenamiento de información', N'Servicios')),
    CONSTRAINT CK_ado_periodicidad CHECK (ado_periodicidad_generacion IN (N'A solicitud', N'Diaria', N'Semanal', N'Mensual', N'Bimensual', N'Trimestral', N'Cuatrimestral', N'Semestral', N'Anual', N'Eventual')),
    CONSTRAINT CK_ado_soporte_registro CHECK (ado_soporte_registro IN (N'Físico', N'Digital', N'Físico/Digital')),
    CONSTRAINT CK_ado_medio_conservacion CHECK (ado_medio_conservacion IN (N'Físico', N'Electrónico', N'Físico/Electrónico')),
    CONSTRAINT CK_ado_idioma CHECK (ado_idioma IN (N'Español', N'Ingles', N'Español/Ingles', N'Frances')),
    CONSTRAINT CK_ado_estado_publicacion CHECK (ado_estado_publicacion IN (N'Publicada ( Externo - Internet)', N'Publicada ( Interno - Intranet)', N'No publicada')),
    CONSTRAINT CK_ado_datos_personales CHECK (ado_contiene_datos_personales IN (N'Si', N'No', N'No Aplica')
                                              AND ado_contiene_datos_menores IN (N'Si', N'No', N'No Aplica')
                                              AND ado_existe_autorizacion_pii IN (N'Si', N'No', N'No Aplica')),
    CONSTRAINT CK_ado_tipo_dato_personal CHECK (ado_tipo_dato_personal IN (N'Dato personal privado', N'Dato personal público', N'Dato semiprivado', N'Dato sensible', N'No Aplica')),
    CONSTRAINT CK_ado_alcance_reserva CHECK (ado_alcance_reserva IN (N'Reserva total', N'Reserva parcial', N'Sin reserva', N'No Aplica')),
    -- RN-DOC-02: Coherencia de Datos Personales (Ley 1581 de 2012): Si contiene datos personales ('Si'), exige tipo de dato y finalidad distintos de 'No Aplica'
    CONSTRAINT CK_ado_coherencia_pii CHECK (ado_estado_registro = N'BORRADOR'
                                            OR (ado_contiene_datos_personales = N'Si'
                                                AND ado_tipo_dato_personal <> N'No Aplica'
                                                AND LEN(TRIM(ISNULL(ado_finalidad_recoleccion_pii, N''))) > 0
                                                AND ado_finalidad_recoleccion_pii <> N'No Aplica')
                                            OR (ado_contiene_datos_personales IN (N'No', N'No Aplica'))),
    -- RN-DOC-03: Coherencia del Índice de Información Clasificada y Reservada (Decreto 103 de 2015 / Ley 1712 de 2014):
    -- Si Confidencialidad es 2 (Clasificada) o 3 (Reservada), exige fundamento legal y alcance de reserva; si es 1 (Pública), no puede tener Reserva total
    CONSTRAINT CK_ado_coherencia_indice_reserva CHECK (ado_estado_registro = N'BORRADOR'
                                                       OR (ado_valor_confidencialidad IN (2, 3)
                                                           AND ado_objeto_legitimo_excepcion <> N'No Aplica'
                                                           AND ado_fundamento_constitucional_legal <> N'No Aplica'
                                                           AND ado_alcance_reserva IN (N'Reserva total', N'Reserva parcial'))
                                                       OR (ado_valor_confidencialidad = 1
                                                           AND ado_alcance_reserva IN (N'Sin reserva', N'No Aplica'))),
    -- RN-DOC-04: Un documento con 'Reserva total' no puede estar publicado externamente en Internet sin anonimización/disociación
    CONSTRAINT CK_ado_reserva_total_no_internet CHECK (NOT (ado_alcance_reserva = N'Reserva total'
                                                            AND ado_estado_publicacion = N'Publicada ( Externo - Internet)'
                                                            AND ado_valor_confidencialidad = 3
                                                            AND ado_tipo_dato_personal IN (N'Dato sensible', N'Dato personal privado'))),
    CONSTRAINT CK_ado_estado_registro CHECK (ado_estado_registro IN (N'BORRADOR', N'EN_VALIDACION_LIDER', N'EN_REVISION_ARCHIVO', N'EN_REVISION_SGSPI', N'OBSERVADO', N'VIGENTE', N'INACTIVO', N'HISTORICO'))
);

-- 4B.5 [adu] Asignación N:M Activo Documental <-> Unidad Productora del CCD/TRD (Modela las 240 filas de desglose TRD sin cadenas multivaluadas)
CREATE TABLE sgspi.activo_documental_unidad_productora (
    adu_codigo      INT IDENTITY (1, 1) NOT NULL, -- Corresponde a la columna XX (1..240) del desglose TRD
    ado_codigo      INT NOT NULL, -- FK a [sgspi].[activo_documental]([ado_codigo])
    upc_codigo      INT NOT NULL, -- FK a [sgspi].[unidad_productora_cuadro_clasificacion_documental]([upc_codigo]) (Unidad más específica donde se produce la serie/subserie)
    adu_esta_activo BIT DEFAULT 1 NOT NULL,
    CONSTRAINT PK_adu_activo_documental_unidad_productora PRIMARY KEY CLUSTERED (adu_codigo),
    CONSTRAINT UQ_adu_activo_unidad_ccd UNIQUE (ado_codigo, upc_codigo),
    CONSTRAINT FK_adu_activo_documental FOREIGN KEY (ado_codigo) REFERENCES sgspi.activo_documental (ado_codigo) ON DELETE CASCADE,
    CONSTRAINT FK_adu_unidad_productora_cuadro_clasificacion_documental FOREIGN KEY (upc_codigo) REFERENCES sgspi.unidad_productora_cuadro_clasificacion_documental (upc_codigo)
);

-- 4B.6 [adp] Tabla Puente N:M Activo Documental <-> Proceso Institucional
CREATE TABLE sgspi.activo_documental_proceso_institucional (
    adp_codigo INT IDENTITY (1, 1) NOT NULL,
    ado_codigo INT NOT NULL, -- FK a [sgspi].[activo_documental]([ado_codigo])
    pri_codigo INT NOT NULL, -- FK a [sgspi].[proceso_institucional]([pri_codigo])
    CONSTRAINT PK_adp_activo_documental_proceso_institucional PRIMARY KEY CLUSTERED (adp_codigo),
    CONSTRAINT UQ_adp_activo_documental_proceso_institucional UNIQUE (ado_codigo, pri_codigo),
    CONSTRAINT FK_adp_activo_documental FOREIGN KEY (ado_codigo) REFERENCES sgspi.activo_documental (ado_codigo) ON DELETE CASCADE,
    CONSTRAINT FK_adp_proceso_institucional FOREIGN KEY (pri_codigo) REFERENCES sgspi.proceso_institucional (pri_codigo)
);

-- 4B.7 [adr] Tabla Puente N:M de Responsables del Activo Documental (Propietarios y Custodios sobre [dbo].[cargo], [dbo].[uaa], [dbo].[uaa_cargo], [dbo].[uaa_personal])
CREATE TABLE sgspi.activo_documental_responsable (
    adr_codigo               INT           IDENTITY (1, 1) NOT NULL,
    ado_codigo               INT           NOT NULL, -- FK a [sgspi].[activo_documental]([ado_codigo])
    car_codigo               INT           NOT NULL, -- FK a [dbo].[cargo]([car_codigo]): Cargo responsable (ISO 27001 / Ley 594)
    uaa_codigo               INT           NOT NULL, -- FK a [dbo].[uaa]([uaa_codigo]): Dependencia productora o custodia
    uac_codigo               INT           NULL, -- FK opcional a [dbo].[uaa_cargo]([uac_codigo]): Plaza de planta
    uap_codigo               INT           NULL, -- FK opcional a [dbo].[uaa_personal]([uap_codigo]): Vinculación del funcionario actual
    adr_tipo_responsabilidad NVARCHAR (20) NOT NULL, -- 'PROPIETARIO', 'CUSTODIO'
    adr_esta_activo          BIT           DEFAULT 1 NOT NULL,
    CONSTRAINT PK_adr_activo_documental_responsable PRIMARY KEY CLUSTERED (adr_codigo),
    CONSTRAINT UQ_adr_activo_documental_responsable UNIQUE (ado_codigo, car_codigo, uaa_codigo, uap_codigo, adr_tipo_responsabilidad),
    CONSTRAINT FK_adr_activo_documental FOREIGN KEY (ado_codigo) REFERENCES sgspi.activo_documental (ado_codigo) ON DELETE CASCADE,
    CONSTRAINT FK_adr_dbo_cargo FOREIGN KEY (car_codigo) REFERENCES dbo.cargo (car_codigo),
    CONSTRAINT FK_adr_dbo_uaa FOREIGN KEY (uaa_codigo) REFERENCES dbo.uaa (uaa_codigo),
    CONSTRAINT FK_adr_dbo_uaa_cargo FOREIGN KEY (uac_codigo) REFERENCES dbo.uaa_cargo (uac_codigo),
    CONSTRAINT FK_adr_dbo_uaa_personal FOREIGN KEY (uap_codigo) REFERENCES dbo.uaa_personal (uap_codigo),
    CONSTRAINT CK_adr_tipo_responsabilidad CHECK (adr_tipo_responsabilidad IN (N'PROPIETARIO', N'CUSTODIO'))
);


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
    eim_codigo                     TINYINT        NOT NULL, -- 1=Insignificante, 2=Menor, 3=Moderado, 4=Mayor, 5=Catastrófico / Altamente beneficioso
    eim_nombre_impacto_negativo    NVARCHAR (30)  NOT NULL,
    eim_nombre_impacto_positivo    NVARCHAR (40)  NOT NULL,
    eim_descripcion_organizacional NVARCHAR (MAX) NOT NULL,
    eim_descripcion_operativa      NVARCHAR (MAX) NULL,
    CONSTRAINT PK_eim_escala_impacto PRIMARY KEY CLUSTERED (eim_codigo),
    CONSTRAINT CK_eim_rango CHECK (eim_codigo BETWEEN 1 AND 5)
);

CREATE TABLE sgspi.matriz_valoracion_riesgo (
    epr_codigo                            TINYINT        NOT NULL,
    eim_codigo                            TINYINT        NOT NULL,
    mvr_codigo_posicion                   CHAR (2)       NOT NULL, -- 'A1'..'E5'
    mvr_codigo_zona                       CHAR (1)       NOT NULL, -- 'B' (Bajo), 'M' (Moderado), 'A' (Alto), 'E' (Extremo)
    mvr_nivel_valoracion                  NVARCHAR (30)  NOT NULL, -- 'Riesgo Inferior', 'Riesgo Moderado', 'Riesgo Alto', 'Riesgo Extremo'
    mvr_directriz_tratamiento_riesgo      NVARCHAR (255) NOT NULL,
    mvr_directriz_tratamiento_oportunidad NVARCHAR (255) NOT NULL,
    mvr_requiere_aprobacion_comite        BIT            DEFAULT 0 NOT NULL,
    CONSTRAINT PK_mvr_matriz_valoracion_riesgo PRIMARY KEY CLUSTERED (epr_codigo, eim_codigo),
    CONSTRAINT UQ_mvr_codigo_posicion UNIQUE (mvr_codigo_posicion),
    CONSTRAINT FK_mvr_escala_probabilidad FOREIGN KEY (epr_codigo) REFERENCES sgspi.escala_probabilidad (epr_codigo),
    CONSTRAINT FK_mvr_escala_impacto FOREIGN KEY (eim_codigo) REFERENCES sgspi.escala_impacto (eim_codigo),
    CONSTRAINT CK_mvr_codigo_zona CHECK (mvr_codigo_zona IN ('B', 'M', 'A', 'E'))
);

-- 5.2 [eia] Escenarios de Incertidumbre sobre Activos (Riesgos RA-XX y Oportunidades OA-XX)
CREATE TABLE sgspi.evento_incertidumbre_activo (
    eia_codigo                      INT            IDENTITY (1, 1) NOT NULL,
    pev_codigo                      SMALLINT       NOT NULL,
    eia_identificador_evento        NVARCHAR (15)  NOT NULL, -- 'RA-01'..'RA-15', 'OA-01'..'OA-09'
    eia_naturaleza_evento           NVARCHAR (15)  NOT NULL, -- 'RIESGO' (-), 'OPORTUNIDAD' (+)
    pri_codigo                      INT            NOT NULL,
    eia_aci_codigo_primario         INT            NOT NULL, -- FK a [sgspi].[activo_informacion]([aci_codigo])
    eia_aci_codigo_soporte          INT            NOT NULL, -- FK a [sgspi].[activo_informacion]([aci_codigo])
    eia_tipo_componente_afectado    NVARCHAR (50)  NOT NULL, -- 'Información', 'Software', 'Servicio', 'Infraestructura', 'Hardware'
    eia_fuente_generadora           NVARCHAR (255) NOT NULL,
    eia_controles_existentes        NVARCHAR (MAX) NULL,
    eia_condicion_vulnerabilidad    NVARCHAR (MAX) NOT NULL,
    eia_efecto_consecuencia         NVARCHAR (MAX) NOT NULL,
    eia_escenario_operacional       NVARCHAR (255) NOT NULL,
    -- Valoración Inherente / Actual
    eia_epr_codigo_inherente        TINYINT        NOT NULL,
    eia_eim_codigo_inherente        TINYINT        NOT NULL,
    -- Máquina de Estados Principal y Firmas sobre [dbo].[persona]
    eia_estado_registro             NVARCHAR (30)  DEFAULT N'BORRADOR' NOT NULL,
    eia_per_codigo_creador          INT            NOT NULL, -- FK a [dbo].[persona]([per_codigo])
    eia_per_codigo_validador_lider  INT            NULL, -- FK a [dbo].[persona]([per_codigo])
    eia_per_codigo_revisor_sgspi    INT            NULL, -- FK a [dbo].[persona]([per_codigo])
    eia_per_codigo_aprobador_comite INT            NULL, -- FK a [dbo].[persona]([per_codigo])
    eia_fecha_creacion              DATETIME2 (0)  DEFAULT SYSDATETIME() NOT NULL,
    eia_fecha_actualizacion         DATETIME2 (0)  DEFAULT SYSDATETIME() NOT NULL,
    CONSTRAINT PK_eia_evento_incertidumbre_activo PRIMARY KEY CLUSTERED (eia_codigo),
    CONSTRAINT UQ_eia_vigencia_identificador UNIQUE (pev_codigo, eia_identificador_evento),
    CONSTRAINT FK_eia_periodo_vigencia FOREIGN KEY (pev_codigo) REFERENCES sgspi.periodo_vigencia (pev_codigo),
    CONSTRAINT FK_eia_proceso_institucional FOREIGN KEY (pri_codigo) REFERENCES sgspi.proceso_institucional (pri_codigo),
    CONSTRAINT FK_eia_activo_primario FOREIGN KEY (eia_aci_codigo_primario) REFERENCES sgspi.activo_informacion (aci_codigo),
    CONSTRAINT FK_eia_activo_soporte FOREIGN KEY (eia_aci_codigo_soporte) REFERENCES sgspi.activo_informacion (aci_codigo),
    CONSTRAINT FK_eia_valoracion_inherente FOREIGN KEY (eia_epr_codigo_inherente, eia_eim_codigo_inherente) REFERENCES sgspi.matriz_valoracion_riesgo (epr_codigo, eim_codigo),
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
);

-- 5.3 [plt] Plan de Tratamiento de Riesgos y Oportunidades
CREATE TABLE sgspi.plan_tratamiento (
    plt_codigo                     INT             IDENTITY (1, 1) NOT NULL,
    eia_codigo                     INT             NOT NULL,
    plt_estrategia_tratamiento     NVARCHAR (80)   NOT NULL,
    plt_justificacion_estrategia   NVARCHAR (MAX)  NOT NULL,
    -- Valoración Residual Esperada (Meta)
    plt_epr_codigo_residual_meta   TINYINT         NOT NULL,
    plt_eim_codigo_residual_meta   TINYINT         NOT NULL,
    plt_fecha_inicio               DATE            NOT NULL,
    plt_fecha_fin                  DATE            NOT NULL,
    plt_recursos_humanos_tecnicos  NVARCHAR (MAX)  NOT NULL,
    plt_recursos_economicos_desc   NVARCHAR (500)  NOT NULL,
    plt_presupuesto_estimado_cop   DECIMAL (18, 2) NULL,
    plt_restricciones_limitaciones NVARCHAR (MAX)  NULL,
    plt_nombre_indicador_kpi       NVARCHAR (255)  NOT NULL,
    plt_meta_indicador_kpi         NVARCHAR (100)  NULL,
    plt_valor_alcanzado_kpi        NVARCHAR (100)  NULL,
    plt_es_tratamiento_eficaz      BIT             NULL,
    plt_dictamen_eficacia          NVARCHAR (MAX)  NULL,
    plt_per_codigo_evaluador       INT             NULL, -- FK a [dbo].[persona]([per_codigo])
    plt_fecha_evaluacion_eficacia  DATETIME2 (0)   NULL,
    CONSTRAINT PK_plt_plan_tratamiento PRIMARY KEY CLUSTERED (plt_codigo),
    CONSTRAINT UQ_plt_evento UNIQUE (eia_codigo),
    CONSTRAINT FK_plt_evento_incertidumbre FOREIGN KEY (eia_codigo) REFERENCES sgspi.evento_incertidumbre_activo (eia_codigo) ON DELETE CASCADE,
    CONSTRAINT FK_plt_valoracion_meta FOREIGN KEY (plt_epr_codigo_residual_meta, plt_eim_codigo_residual_meta) REFERENCES sgspi.matriz_valoracion_riesgo (epr_codigo, eim_codigo),
    CONSTRAINT FK_plt_dbo_persona_evaluador FOREIGN KEY (plt_per_codigo_evaluador) REFERENCES dbo.persona (per_codigo),
    -- RN-RSG-06: Validación de cronogramas
    CONSTRAINT CK_plt_cronograma CHECK (plt_fecha_fin >= plt_fecha_inicio),
    CONSTRAINT CK_plt_estrategia_catalogo CHECK (plt_estrategia_tratamiento IN (N'Mitigar o reducir', N'Mitigar o reducir y compartir el riesgo', N'Compartir o transferir el riesgo', N'Evitar el riesgo', N'Asumir el riesgo', N'Potenciar o explotar la oportunidad', N'Potenciar o explotar y compartir la oportunidad', N'Asumir la oportunidad'))
);

-- 5.4 [act] y [sga] Desglose de Actividades del Plan de Tratamiento y Seguimiento con Evidencias
CREATE TABLE sgspi.actividad_tratamiento (
    act_codigo                INT            IDENTITY (1, 1) NOT NULL,
    plt_codigo                INT            NOT NULL,
    act_numero_orden          SMALLINT       DEFAULT 1 NOT NULL,
    act_descripcion_actividad NVARCHAR (500) NOT NULL,
    car_codigo                INT            NULL, -- FK a [dbo].[cargo]([car_codigo])
    uaa_codigo                INT            NULL, -- FK a [dbo].[uaa]([uaa_codigo])
    act_fecha_compromiso      DATE           NOT NULL,
    act_porcentaje_avance     TINYINT        DEFAULT 0 NOT NULL,
    act_estado_actividad      NVARCHAR (20)  DEFAULT N'PENDIENTE' NOT NULL,
    CONSTRAINT PK_act_actividad_tratamiento PRIMARY KEY CLUSTERED (act_codigo),
    CONSTRAINT FK_act_plan_tratamiento FOREIGN KEY (plt_codigo) REFERENCES sgspi.plan_tratamiento (plt_codigo) ON DELETE CASCADE,
    CONSTRAINT FK_act_dbo_cargo FOREIGN KEY (car_codigo) REFERENCES dbo.cargo (car_codigo),
    CONSTRAINT FK_act_dbo_uaa FOREIGN KEY (uaa_codigo) REFERENCES dbo.uaa (uaa_codigo),
    CONSTRAINT CK_act_porcentaje_avance CHECK (act_porcentaje_avance BETWEEN 0 AND 100),
    CONSTRAINT CK_act_estado_actividad CHECK (act_estado_actividad IN (N'PENDIENTE', N'EN_CURSO', N'COMPLETADA', N'OBSERVADA'))
);

CREATE TABLE sgspi.seguimiento_actividad (
    sga_codigo                       INT            IDENTITY (1, 1) NOT NULL,
    act_codigo                       INT            NOT NULL,
    per_codigo                       INT            NOT NULL, -- FK a [dbo].[persona]([per_codigo])
    sga_fecha_registro               DATETIME2 (0)  DEFAULT SYSDATETIME() NOT NULL,
    sga_porcentaje_reportado         TINYINT        NOT NULL,
    sga_descripcion_avance           NVARCHAR (MAX) NOT NULL,
    sga_nombre_archivo_evidencia     NVARCHAR (255) NULL,
    sga_uri_almacenamiento_evidencia NVARCHAR (500) NULL,
    sga_hash_sha256_evidencia        CHAR (64)      NULL,
    CONSTRAINT PK_sga_seguimiento_actividad PRIMARY KEY CLUSTERED (sga_codigo),
    CONSTRAINT FK_sga_actividad_tratamiento FOREIGN KEY (act_codigo) REFERENCES sgspi.actividad_tratamiento (act_codigo) ON DELETE CASCADE,
    CONSTRAINT FK_sga_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_sga_porcentaje_reportado CHECK (sga_porcentaje_reportado BETWEEN 0 AND 100)
);

-- 5.5 [crn] Catálogo Maestro de Controles Normativos (ISO/IEC 27001:2022 [93] e ISO/IEC 27701:2025 [71])
CREATE TABLE sgspi.control_referencia_normativa (
    crn_codigo                  SMALLINT       IDENTITY (1, 1) NOT NULL,
    crn_estandar_normativo      NVARCHAR (30)  NOT NULL, -- 'ISO/IEC 27001:2022', 'ISO/IEC 27701:2025'
    crn_rol_privacidad_pii      NVARCHAR (20)  DEFAULT N'NO_APLICA' NOT NULL, -- 'NO_APLICA', 'CONTROLADOR', 'PROCESADOR', 'COMUN'
    crn_identificador_control   NVARCHAR (20)  NOT NULL, -- 'A.5.1'..'A.8.34', 'A.1.2.2'..'A.3.31'
    crn_nombre_control          NVARCHAR (200) NOT NULL,
    crn_objetivo_requisito      NVARCHAR (MAX) NOT NULL,
    crn_tipo_control            NVARCHAR (50)  NULL, -- 'Preventivo', 'Detectivo', 'Correctivo'
    crn_propiedades_seguridad   NVARCHAR (100) NULL, -- 'Confidencialidad, Integridad, Disponibilidad'
    crn_concepto_ciberseguridad NVARCHAR (100) NULL, -- 'Identificar, Proteger, Detectar, Responder, Recuperar'
    crn_capacidad_operacional   NVARCHAR (150) NULL,
    crn_dominio_seguridad       NVARCHAR (100) NULL, -- 'Gobierno y Ecosistema', 'Protección', 'Defensa', 'Resiliencia'
    CONSTRAINT PK_crn_control_referencia_normativa PRIMARY KEY CLUSTERED (crn_codigo),
    CONSTRAINT UQ_crn_estandar_identificador UNIQUE (crn_estandar_normativo, crn_identificador_control),
    CONSTRAINT CK_crn_estandar_normativo CHECK (crn_estandar_normativo IN (N'ISO/IEC 27001:2022', N'ISO/IEC 27701:2025')),
    CONSTRAINT CK_crn_rol_privacidad_pii CHECK (crn_rol_privacidad_pii IN (N'NO_APLICA', N'CONTROLADOR', N'PROCESADOR', N'COMUN'))
);

-- 5.6 [ptc] Relación N:M Plan de Tratamiento <-> Controles de Referencia Normativa (ISO 27001 e ISO 27701)
CREATE TABLE sgspi.plan_tratamiento_control_referencia_normativa (
    ptc_codigo INT      IDENTITY (1, 1) NOT NULL,
    plt_codigo INT      NOT NULL,
    crn_codigo SMALLINT NOT NULL,
    CONSTRAINT PK_ptc_plan_tratamiento_control_referencia_normativa PRIMARY KEY CLUSTERED (ptc_codigo),
    CONSTRAINT UQ_ptc_plan_control UNIQUE (plt_codigo, crn_codigo),
    CONSTRAINT FK_ptc_plan_tratamiento FOREIGN KEY (plt_codigo) REFERENCES sgspi.plan_tratamiento (plt_codigo) ON DELETE CASCADE,
    CONSTRAINT FK_ptc_control_referencia FOREIGN KEY (crn_codigo) REFERENCES sgspi.control_referencia_normativa (crn_codigo)
);

-- 5.7 [eac] Declaración de Aplicabilidad (SoA) y Evaluación de Cumplimiento por Vigencia
CREATE TABLE sgspi.evaluacion_aplicabilidad_control (
    eac_codigo                      INT            IDENTITY (1, 1) NOT NULL,
    pev_codigo                      SMALLINT       NOT NULL,
    crn_codigo                      SMALLINT       NOT NULL,
    eac_es_aplicable                BIT            DEFAULT 1 NOT NULL,
    eac_justificacion_aplicabilidad NVARCHAR (MAX) NULL,
    eac_documento_soporte_normativo NVARCHAR (500) NULL,
    car_codigo                      INT            NULL, -- FK a [dbo].[cargo]([car_codigo])
    eac_frecuencia_revision         NVARCHAR (100) DEFAULT N'Anual y cuando se presenten cambios' NOT NULL,
    eac_evidencia_objetiva_esperada NVARCHAR (500) NULL,
    eac_estado_implementacion       NVARCHAR (20)  DEFAULT N'NO_CUMPLE' NOT NULL, -- 'CUMPLE', 'CUMPLE_PARCIAL', 'NO_CUMPLE', 'NO_APLICA'
    eac_observaciones_auditoria     NVARCHAR (MAX) NULL,
    eac_fecha_actualizacion         DATETIME2 (0)  DEFAULT SYSDATETIME() NOT NULL,
    CONSTRAINT PK_eac_evaluacion_aplicabilidad_control PRIMARY KEY CLUSTERED (eac_codigo),
    CONSTRAINT UQ_eac_vigencia_control UNIQUE (pev_codigo, crn_codigo),
    CONSTRAINT FK_eac_periodo_vigencia FOREIGN KEY (pev_codigo) REFERENCES sgspi.periodo_vigencia (pev_codigo),
    CONSTRAINT FK_eac_control_referencia FOREIGN KEY (crn_codigo) REFERENCES sgspi.control_referencia_normativa (crn_codigo),
    CONSTRAINT FK_eac_dbo_cargo FOREIGN KEY (car_codigo) REFERENCES dbo.cargo (car_codigo),
    CONSTRAINT CK_eac_estado_implementacion CHECK (eac_estado_implementacion IN (N'CUMPLE', N'CUMPLE_PARCIAL', N'NO_CUMPLE', N'NO_APLICA')),
    -- RN-SOA-01: Un control NO puede marcarse como CUMPLE si el documento soporte o la evidencia esperada están vacíos o dicen 'PENDIENTE'
    CONSTRAINT CK_eac_cumple_requiere_evidencia CHECK (eac_estado_implementacion <> N'CUMPLE'
                                                       OR (LEN(TRIM(ISNULL(eac_documento_soporte_normativo, N''))) > 0
                                                           AND UPPER(TRIM(ISNULL(eac_documento_soporte_normativo, N''))) <> N'PENDIENTE'
                                                           AND LEN(TRIM(ISNULL(eac_evidencia_objetiva_esperada, N''))) > 0
                                                           AND UPPER(TRIM(ISNULL(eac_evidencia_objetiva_esperada, N''))) <> N'PENDIENTE'))
);

-- 5.8 [bas] Bitácora de Auditoría Inmutable (Control ISO 27001 A.8.15) articulada con [dbo].[persona] y [dbo].[grupo]
CREATE TABLE sgspi.bitacora_auditoria_sistema (
    bas_codigo                   BIGINT         IDENTITY (1, 1) NOT NULL,
    bas_fecha_evento_utc         DATETIME2 (3)  DEFAULT SYSUTCDATETIME() NOT NULL,
    per_codigo                   INT            NOT NULL, -- FK a [dbo].[persona]([per_codigo])
    gru_codigo                   INT            NULL, -- FK a [dbo].[grupo]([gru_codigo])
    usg_codigo                   INT            NULL, -- FK a [dbo].[usuario_grupo]([usg_codigo])
    bas_direccion_ip             VARCHAR (45)   NULL,
    bas_entidad_afectada         NVARCHAR (80)  NOT NULL,
    bas_registro_afectado_codigo NVARCHAR (50)  NOT NULL,
    bas_accion_ejecutada         NVARCHAR (30)  NOT NULL, -- 'CREAR', 'ACTUALIZAR', 'TRANSICION_ESTADO', 'APROBAR', 'OBSERVAR'
    bas_estado_anterior          NVARCHAR (30)  NULL,
    bas_estado_nuevo             NVARCHAR (30)  NULL,
    bas_valores_anteriores_json  NVARCHAR (MAX) NULL,
    bas_valores_nuevos_json      NVARCHAR (MAX) NULL,
    bas_motivo_observacion       NVARCHAR (500) NULL,
    CONSTRAINT PK_bas_bitacora_auditoria_sistema PRIMARY KEY CLUSTERED (bas_codigo),
    CONSTRAINT FK_bas_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT FK_bas_dbo_grupo FOREIGN KEY (gru_codigo) REFERENCES dbo.grupo (gru_codigo),
    CONSTRAINT FK_bas_dbo_usuario_grupo FOREIGN KEY (usg_codigo) REFERENCES dbo.usuario_grupo (usg_codigo),
    CONSTRAINT CK_bas_json_ant CHECK (bas_valores_anteriores_json IS NULL
                                      OR ISJSON(bas_valores_anteriores_json) = 1),
    CONSTRAINT CK_bas_json_nue CHECK (bas_valores_nuevos_json IS NULL
                                      OR ISJSON(bas_valores_nuevos_json) = 1)
);


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
       piu.pri_codigo,
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
-- 6.1 Vista Consolidado DOFA (Genera dinámicamente los códigos D1..Dn, F1..Fn, A1..An, O1..On)
CREATE OR ALTER VIEW sgspi.vw_consolidado_dofa
AS
SELECT acf.acf_codigo,
       pv.pev_anio AS pev_vigencia,
       tpc.tpr_nombre AS tpr_tipo_proceso,
       pr.pri_nombre AS pri_proceso,
       fec.fec_nombre_factor AS fec_variable_entorno,
       acf.acf_ambito_entorno,
       acf.acf_naturaleza_factor,
       CONCAT(LEFT(acf.acf_naturaleza_factor, 1), ROW_NUMBER() OVER (PARTITION BY acf.pev_codigo, acf.acf_naturaleza_factor ORDER BY tpc.tpr_codigo, pr.pri_codigo, acf.acf_codigo)) AS acf_codigo_autogenerado,
       acf.acf_descripcion_situacion,
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
-- 6.2 Vista Resumen de Activos por Categoría, Tipo y Criticidad (Reemplaza Tabla Dinámica de ES-GSPI-MR-05)
CREATE OR ALTER VIEW sgspi.vw_resumen_activos_criticidad
AS
SELECT   ISNULL(tac.tac_categoria_iso27005, N'Total general') AS tac_categoria_activo,
         ISNULL(tac.tac_tipo_activo, N'Subtotal categoría') AS tac_tipo_activo,
         SUM(CASE WHEN ai.aci_nivel_criticidad = N'Alta' THEN 1 ELSE 0 END) AS aci_criticidad_alta,
         SUM(CASE WHEN ai.aci_nivel_criticidad = N'Media' THEN 1 ELSE 0 END) AS aci_criticidad_media,
         SUM(CASE WHEN ai.aci_nivel_criticidad = N'Baja' THEN 1 ELSE 0 END) AS aci_criticidad_baja,
         COUNT(ai.aci_codigo) AS aci_total_general
FROM     sgspi.activo_informacion AS ai
         INNER JOIN
         sgspi.tipo_activo_catalogo AS tac
         ON tac.tac_codigo = ai.tac_codigo
WHERE    ai.aci_estado_registro = N'VIGENTE'
GROUP BY GROUPING SETS((tac.tac_categoria_iso27005, tac.tac_tipo_activo), (tac.tac_categoria_iso27005), ());


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
        WHERE    crn.crn_estandar_normativo = N'ISO/IEC 27001:2022'
        GROUP BY ptc.plt_codigo),
       cte_controles_27701
AS     (SELECT   ptc.plt_codigo,
                 STRING_AGG(CONCAT(crn.crn_rol_privacidad_pii, N': ', crn.crn_identificador_control), N' | ') WITHIN GROUP (ORDER BY crn.crn_codigo) AS crn_controles_iso27701
        FROM     sgspi.plan_tratamiento_control_referencia_normativa AS ptc
                 INNER JOIN
                 sgspi.control_referencia_normativa AS crn
                 ON crn.crn_codigo = ptc.crn_codigo
        WHERE    crn.crn_estandar_normativo = N'ISO/IEC 27701:2025'
        GROUP BY ptc.plt_codigo)
SELECT eia.eia_identificador_evento AS eia_codigo_riesgo_oportunidad,
       eia.eia_escenario_operacional AS eia_riesgo_oportunidad,
       pr.pri_nombre AS pri_proceso,
       CONCAT(N'Activo primario: ', ap.aci_nombre_activo, N' | Activo secundario: ', asop.aci_nombre_activo) AS eia_detalle_del_riesgo,
       CONCAT(N'Posibilidad: ', ep_inh.epr_nombre_nivel, N' (', ep_inh.epr_codigo_letra, N') | Impacto: ', CASE WHEN eia.eia_naturaleza_evento = N'RIESGO' THEN ei_inh.eim_nombre_impacto_negativo ELSE ei_inh.eim_nombre_impacto_positivo END, N' (', ei_inh.eim_codigo, N') | Nivel actual: ', mvr_inh.mvr_nivel_valoracion) AS eia_resultado_actual,
       CONCAT(N'Posibilidad: ', ep_meta.epr_nombre_nivel, N' (', ep_meta.epr_codigo_letra, N') | Impacto: ', CASE WHEN eia.eia_naturaleza_evento = N'RIESGO' THEN ei_meta.eim_nombre_impacto_negativo ELSE ei_meta.eim_nombre_impacto_positivo END, N' (', ei_meta.eim_codigo, N') | Nivel esperado: ', mvr_meta.mvr_nivel_valoracion) AS plt_resultado_esperado,
       c27001.crn_controles_iso27001,
       c27701.crn_controles_iso27701,
       pt.plt_estrategia_tratamiento AS plt_opcion_tratamiento,
       pt.plt_justificacion_estrategia,
       CONCAT(FORMAT(pt.plt_fecha_inicio, 'dd/MM/yyyy'), N' – ', FORMAT(pt.plt_fecha_fin, 'dd/MM/yyyy')) AS plt_cronograma,
       pt.plt_recursos_humanos_tecnicos,
       pt.plt_recursos_economicos_desc,
       pt.plt_restricciones_limitaciones AS plt_limitaciones,
       pt.plt_nombre_indicador_kpi AS plt_indicador_rendimiento,
       pt.plt_es_tratamiento_eficaz AS plt_eficacia,
       eia.eia_estado_registro
FROM   sgspi.evento_incertidumbre_activo AS eia
       INNER JOIN
       sgspi.plan_tratamiento AS pt
       ON pt.eia_codigo = eia.eia_codigo
       INNER JOIN
       sgspi.proceso_institucional AS pr
       ON pr.pri_codigo = eia.pri_codigo
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
       ON mvr_inh.epr_codigo = eia.eia_epr_codigo_inherente
          AND mvr_inh.eim_codigo = eia.eia_eim_codigo_inherente
       INNER JOIN
       sgspi.escala_probabilidad AS ep_meta
       ON ep_meta.epr_codigo = pt.plt_epr_codigo_residual_meta
       INNER JOIN
       sgspi.escala_impacto AS ei_meta
       ON ei_meta.eim_codigo = pt.plt_eim_codigo_residual_meta
       INNER JOIN
       sgspi.matriz_valoracion_riesgo AS mvr_meta
       ON mvr_meta.epr_codigo = pt.plt_epr_codigo_residual_meta
          AND mvr_meta.eim_codigo = pt.plt_eim_codigo_residual_meta
       LEFT OUTER JOIN
       cte_controles_27001 AS c27001
       ON c27001.plt_codigo = pt.plt_codigo
       LEFT OUTER JOIN
       cte_controles_27701 AS c27701
       ON c27701.plt_codigo = pt.plt_codigo;


GO
-- 6.4 Vista de Desglose Jerárquico del Cuadro de Clasificación Documental CCD/TRD (240 filas de ES-GSPI-MR-04: cod1..cod6)
CREATE OR ALTER VIEW sgspi.vw_desglose_ccd_trd_mr04
AS
WITH   cte_jerarquia_ccd
AS     (SELECT u.upc_codigo,
               u.upc_nivel_jerarquico,
               u.upc_prefijo_archivistico,
               u.upc_nombre_unidad,
               CASE u.upc_nivel_jerarquico WHEN 1 THEN u.upc_prefijo_archivistico WHEN 2 THEN p1.upc_prefijo_archivistico WHEN 3 THEN p2.upc_prefijo_archivistico WHEN 4 THEN p3.upc_prefijo_archivistico END AS upc_cod1_seccion,
               CASE u.upc_nivel_jerarquico WHEN 1 THEN u.upc_nombre_unidad WHEN 2 THEN p1.upc_nombre_unidad WHEN 3 THEN p2.upc_nombre_unidad WHEN 4 THEN p3.upc_nombre_unidad END AS upc_nombre_seccion,
               CASE u.upc_nivel_jerarquico WHEN 2 THEN u.upc_prefijo_archivistico WHEN 3 THEN p1.upc_prefijo_archivistico WHEN 4 THEN p2.upc_prefijo_archivistico ELSE NULL END AS upc_cod2_subseccion,
               CASE u.upc_nivel_jerarquico WHEN 2 THEN u.upc_nombre_unidad WHEN 3 THEN p1.upc_nombre_unidad WHEN 4 THEN p2.upc_nombre_unidad ELSE NULL END AS upc_nombre_subseccion,
               CASE u.upc_nivel_jerarquico WHEN 3 THEN u.upc_prefijo_archivistico WHEN 4 THEN p1.upc_prefijo_archivistico ELSE NULL END AS upc_cod3_subseccion_n1,
               CASE u.upc_nivel_jerarquico WHEN 3 THEN u.upc_nombre_unidad WHEN 4 THEN p1.upc_nombre_unidad ELSE NULL END AS upc_nombre_subseccion_n1,
               CASE u.upc_nivel_jerarquico WHEN 4 THEN u.upc_prefijo_archivistico ELSE NULL END AS upc_cod4_subseccion_n2,
               CASE u.upc_nivel_jerarquico WHEN 4 THEN u.upc_nombre_unidad ELSE NULL END AS upc_nombre_subseccion_n2
        FROM   sgspi.unidad_productora_cuadro_clasificacion_documental AS u
               LEFT OUTER JOIN
               sgspi.unidad_productora_cuadro_clasificacion_documental AS p1
               ON p1.upc_codigo = u.upc_codigo_padre
               LEFT OUTER JOIN
               sgspi.unidad_productora_cuadro_clasificacion_documental AS p2
               ON p2.upc_codigo = p1.upc_codigo_padre
               LEFT OUTER JOIN
               sgspi.unidad_productora_cuadro_clasificacion_documental AS p3
               ON p3.upc_codigo = p2.upc_codigo_padre)
SELECT adu.adu_codigo,
       adu.ado_codigo,
       j.upc_cod1_seccion,
       j.upc_nombre_seccion,
       j.upc_cod2_subseccion,
       j.upc_nombre_subseccion,
       j.upc_cod3_subseccion_n1,
       j.upc_nombre_subseccion_n1,
       j.upc_cod4_subseccion_n2,
       j.upc_nombre_subseccion_n2,
       sdo.sdo_numero_ccd AS sdo_cod5_serie,
       sdo.sdo_nombre_serie,
       sbd.sbd_numero_ccd AS sbd_cod6_subserie,
       sbd.sbd_nombre_subserie,
       -- Cálculo en tiempo de ejecución de los códigos archivísticos TRD: <prefijo_unidad>.<COD5> y <prefijo_unidad>.<COD5>.<COD6>
       CONCAT(j.upc_prefijo_archivistico, N'.', sdo.sdo_numero_ccd) AS adu_codigo_serie_trd_calculado,
       CASE WHEN sbd.sbd_numero_ccd IS NOT NULL THEN CONCAT(j.upc_prefijo_archivistico, N'.', sdo.sdo_numero_ccd, N'.', sbd.sbd_numero_ccd) ELSE CONCAT(j.upc_prefijo_archivistico, N'.', sdo.sdo_numero_ccd) END AS adu_codigo_subserie_trd_calculado
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
       ON sbd.sbd_codigo = ado.sbd_codigo
WHERE  adu.adu_esta_activo = 1;


GO
-- 6.5 Vista Matriz Consolidada de Inventario y Clasificación de Activos Documentales (194 filas de ES-GSPI-MR-04)
CREATE OR ALTER VIEW sgspi.vw_inventario_activo_documental_mr04
AS
WITH   cte_trd_agregado
AS     (SELECT   v.ado_codigo,
                 STRING_AGG(v.adu_codigo_serie_trd_calculado, N', ') WITHIN GROUP (ORDER BY v.adu_codigo) AS ado_codigos_serie_documental_trd,
                 STRING_AGG(v.adu_codigo_subserie_trd_calculado, N', ') WITHIN GROUP (ORDER BY v.adu_codigo) AS ado_codigos_subserie_documental_trd
        FROM     sgspi.vw_desglose_ccd_trd_mr04 AS v
        GROUP BY v.ado_codigo),
       cte_procesos_doc
AS     (SELECT   adp.ado_codigo,
                 STRING_AGG(pr.pri_nombre, N', ') WITHIN GROUP (ORDER BY pr.pri_codigo) AS ado_procesos_asociados
        FROM     sgspi.activo_documental_proceso_institucional AS adp
                 INNER JOIN
                 sgspi.proceso_institucional AS pr
                 ON pr.pri_codigo = adp.pri_codigo
        GROUP BY adp.ado_codigo),
       cte_dependencias_doc
AS     (SELECT   x.ado_codigo,
                 STRING_AGG(x.uaa_nombre, N', ') WITHIN GROUP (ORDER BY x.uaa_nombre) AS ado_dependencias_oficinas
        FROM     (SELECT DISTINCT adr.ado_codigo,
                                  u.uaa_nombre
                  FROM   sgspi.activo_documental_responsable AS adr
                         INNER JOIN
                         dbo.uaa AS u
                         ON u.uaa_codigo = adr.uaa_codigo
                  WHERE  adr.adr_esta_activo = 1) AS x
        GROUP BY x.ado_codigo),
       cte_propietarios_doc
AS     (SELECT   adr.ado_codigo,
                 STRING_AGG(c.car_nombre, N', ') WITHIN GROUP (ORDER BY adr.adr_codigo) AS ado_propietarios_activo
        FROM     sgspi.activo_documental_responsable AS adr
                 INNER JOIN
                 dbo.cargo AS c
                 ON c.car_codigo = adr.car_codigo
        WHERE    adr.adr_esta_activo = 1
                 AND adr.adr_tipo_responsabilidad = N'PROPIETARIO'
        GROUP BY adr.ado_codigo),
       cte_custodios_doc
AS     (SELECT   adr.ado_codigo,
                 STRING_AGG(c.car_nombre, N', ') WITHIN GROUP (ORDER BY adr.adr_codigo) AS ado_custodios_activo
        FROM     sgspi.activo_documental_responsable AS adr
                 INNER JOIN
                 dbo.cargo AS c
                 ON c.car_codigo = adr.car_codigo
        WHERE    adr.adr_esta_activo = 1
                 AND adr.adr_tipo_responsabilidad = N'CUSTODIO'
        GROUP BY adr.ado_codigo)
SELECT ado.ado_codigo,
       pv.pev_anio AS pev_vigencia,
       trd.ado_codigos_serie_documental_trd,
       trd.ado_codigos_subserie_documental_trd,
       sdo.sdo_nombre_serie,
       sbd.sbd_nombre_subserie,
       ado.ado_nombre_activo,
       ado.ado_descripcion,
       pdoc.ado_procesos_asociados,
       ddoc.ado_dependencias_oficinas,
       ado.ado_tipo_activo_documental,
       prop.ado_propietarios_activo,
       cust.ado_custodios_activo,
       ado.ado_periodicidad_generacion,
       ado.ado_soporte_registro,
       ado.ado_medio_conservacion,
       ado.ado_formato_documental,
       ado.ado_idioma,
       ado.ado_fecha_ingreso_tabla_retencion,
       ado.ado_fecha_ingreso_archivo,
       ado.ado_nivel_confidencialidad,
       ado.ado_valor_confidencialidad,
       ado.ado_nivel_integridad,
       ado.ado_valor_integridad,
       ado.ado_nivel_disponibilidad,
       ado.ado_valor_disponibilidad,
       ado.ado_puntaje_criticidad,
       ado.ado_nivel_criticidad,
       ado.ado_estado_publicacion,
       ado.ado_lugar_consulta_ubicacion,
       ado.ado_contiene_datos_personales,
       ado.ado_contiene_datos_menores,
       ado.ado_tipo_dato_personal,
       ado.ado_finalidad_recoleccion_pii,
       ado.ado_existe_autorizacion_pii,
       ado.ado_objeto_legitimo_excepcion,
       ado.ado_fundamento_constitucional_legal,
       ado.ado_fundamento_juridico_excepcion,
       ado.ado_alcance_reserva,
       ado.ado_fecha_clasificacion_reserva,
       ado.ado_tiempo_clasificacion_reserva,
       ado.ado_es_infraestructura_critica_icc,
       ado.ado_estado_registro
FROM   sgspi.activo_documental AS ado
       INNER JOIN
       sgspi.periodo_vigencia AS pv
       ON pv.pev_codigo = ado.pev_codigo
       INNER JOIN
       sgspi.serie_documental_catalogo AS sdo
       ON sdo.sdo_codigo = ado.sdo_codigo
       LEFT OUTER JOIN
       sgspi.subserie_documental_catalogo AS sbd
       ON sbd.sbd_codigo = ado.sbd_codigo
       LEFT OUTER JOIN
       cte_trd_agregado AS trd
       ON trd.ado_codigo = ado.ado_codigo
       LEFT OUTER JOIN
       cte_procesos_doc AS pdoc
       ON pdoc.ado_codigo = ado.ado_codigo
       LEFT OUTER JOIN
       cte_dependencias_doc AS ddoc
       ON ddoc.ado_codigo = ado.ado_codigo
       LEFT OUTER JOIN
       cte_propietarios_doc AS prop
       ON prop.ado_codigo = ado.ado_codigo
       LEFT OUTER JOIN
       cte_custodios_doc AS cust
       ON cust.ado_codigo = ado.ado_codigo;