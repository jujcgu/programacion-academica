/*==================================================================================================
PROYECTO:     Sistema de Gestión de Seguridad y Privacidad de la Información (SGSPI)
ENTIDAD:      Universidad Surcolombiana (USCO)
BASE DATOS:   Integrado con el esquema corporativo [dbo] de la USCO (academia3000)
MOTOR BD:     Microsoft SQL Server 2019 (Compatibilidad 150)
VERSIÓN:      2.1 — Refactorización de antipatrones (ver REGISTRO DE CAMBIOS al final de esta cabecera)
CONVENCIÓN:   Estándar Institucional USCO (academia3000):
1. Todas las llaves primarias y foráneas usan el sufijo [_codigo] (cero [_id]).
2. Las columnas propias de cada tabla inician con el acrónimo de 3 letras de su tabla local ([<acr>_...]) y las
foráneas conservan el acrónimo de la tabla referenciada:
- Llave primaria: [<acr>_codigo]
- Llave foránea simple: [<acr_remoto>_codigo] (ej. [pev_codigo], [pri_codigo])
- Llave foránea con rol: [<acr_remoto>_codigo_<rol>] (ej. [aci_codigo_primario], [per_codigo_creador])
3. Toda restricción tiene nombre explícito: PK_, FK_, UQ_ (UNIQUE), UX_ (índice único), CK_ y DF_<columna>.
MAPA DE ACRÓNIMOS DE TABLAS DEL ESQUEMA [sgspi] (49 TABLAS DE NEGOCIO, CADA UNA CON SU TABLA aud_*):
- [pev] : sgspi.periodo_vigencia                  - [src] : sgspi.soporte_registro_catalogo
- [efc] : sgspi.estado_flujo_catalogo (NUEVA)     - [mcc] : sgspi.medio_conservacion_catalogo
- [tef] : sgspi.transicion_estado_flujo (NUEVA)   - [epc] : sgspi.estado_publicacion_catalogo
- [tpr] : sgspi.tipo_proceso_catalogo             - [idi] : sgspi.idioma_catalogo
- [pri] : sgspi.proceso_institucional             - [fac] : sgspi.formato_archivo_catalogo (NUEVA)
- [piu] : sgspi.proceso_institucional_uaa         - [ado] : sgspi.activo_documental (Subtipo 1:1 de [aci], PK compartida)
- [fec] : sgspi.factor_entorno_catalogo           - [ads] : sgspi.activo_documental_soporte_registro
- [acf] : sgspi.analisis_contexto_factor          - [adm] : sgspi.activo_documental_medio_conservacion
- [pai] : sgspi.parte_interesada                  - [adi] : sgspi.activo_documental_idioma
- [rpi] : sgspi.requisito_parte_interesada        - [adf] : sgspi.activo_documental_formato_archivo (NUEVA)
                                                    - [adu] : sgspi.activo_documental_unidad_productora
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
MAPA DE ACRÓNIMOS DE LAS TABLAS DE AUDITORÍA (sgspi.aud_<tabla>, sección 5.9, AP-01):
- [apv] : aud_periodo_vigencia                                   - [aec] : aud_estado_flujo_catalogo
- [atf] : aud_transicion_estado_flujo                            - [atr] : aud_tipo_proceso_catalogo
- [api] : aud_proceso_institucional                              - [apu] : aud_proceso_institucional_uaa
- [afc] : aud_factor_entorno_catalogo                            - [aaf] : aud_analisis_contexto_factor
- [apa] : aud_parte_interesada                                   - [ari] : aud_requisito_parte_interesada
                                                                   - [arp] : aud_requisito_parte_interesada_proceso_institucional
- [atc] : aud_tipo_activo_catalogo                               - [ace] : aud_causal_excepcion_transparencia
- [aai] : aud_activo_informacion                                 - [aap] : aud_activo_informacion_proceso_institucional
- [aas] : aud_activo_informacion_sede                            - [aar] : aud_activo_informacion_responsable
- [asf] : aud_sistema_informacion_ficha                          - [ami] : aud_modulo_sistema_informacion
- [aso] : aud_serie_documental_catalogo                          - [asd] : aud_subserie_documental_catalogo
- [auc] : aud_unidad_productora_cuadro_clasificacion_documental  - [apc] : aud_periodicidad_catalogo
- [aep] : aud_estado_publicacion_catalogo                        - [asc] : aud_soporte_registro_catalogo
- [amc] : aud_medio_conservacion_catalogo                        - [aii] : aud_idioma_catalogo
- [afa] : aud_formato_archivo_catalogo                           - [aao] : aud_activo_documental
- [aad] : aud_activo_documental_soporte_registro                 - [aam] : aud_activo_documental_medio_conservacion
- [aid] : aud_activo_documental_idioma                           - [afd] : aud_activo_documental_formato_archivo
- [aau] : aud_activo_documental_unidad_productora                - [aer] : aud_escala_probabilidad
- [aem] : aud_escala_impacto                                     - [azc] : aud_zona_riesgo_catalogo
- [amr] : aud_matriz_valoracion_riesgo                           - [aea] : aud_evento_incertidumbre_activo
- [aet] : aud_estrategia_tratamiento_catalogo                    - [apt] : aud_plan_tratamiento
- [aat] : aud_actividad_tratamiento                              - [asa] : aud_seguimiento_actividad
- [aen] : aud_estandar_normativo_catalogo                        - [acn] : aud_control_referencia_normativa
- [acc] : aud_atributo_control_catalogo                          - [aca] : aud_control_referencia_normativa_atributo
- [acp] : aud_plan_tratamiento_control_referencia_normativa      - [aae] : aud_evaluacion_aplicabilidad_control
ELIMINADAS: [cps] control_propiedad_seguridad y [ccc] control_concepto_ciberseguridad (absorbidas por [aac]/[cra]);
[bas] bitacora_auditoria_sistema y las tablas *_historial (reemplazadas por las tablas aud_*, ver AP-01);
[dfc] dominio_formato_catalogo, [fdv] formato_documental_version y [rpc] requisito_parte_interesada_cuestionario.
ACRÓNIMOS REUTILIZADOS DEL ESQUEMA CORPORATIVO [dbo]:
- [sus] : dbo.sub_sede ([sus_codigo])             - [car] : dbo.cargo ([car_codigo])
- [esp] : dbo.espacio ([esp_codigo])              - [per] : dbo.persona ([per_codigo])
- [uaa] : dbo.uaa ([uaa_codigo])                  - [gru] : dbo.grupo ([gru_codigo])
- [usg] : dbo.usuario_grupo ([usg_codigo])
REGISTRO DE CAMBIOS v2.0 (cada cambio está marcado en el código con -- [AP-xx]):
AP-01  Auditoría por tabla (reemplaza la bitácora [bas] y las tablas temporales): cada tabla tiene su
sgspi.aud_<tabla> (sección 5.9) con las altas (<aud>_operacion = 'I', con los valores iniciales de la fila creada)
y la versión anterior de cada fila modificada (<aud>_operacion = 'U'), quién ejecutó la operación (per_codigo de
ORIGINAL_LOGIN(), error 50017 si no hay persona; también para un DBA) y cuándo. Las tablas aud_* son inmutables
(error 50016) y el borrado físico de cualquier tabla lo rechaza la FK de su aud_* (547, también a dbo; el trigger, 50010,
queda como segunda barrera). La auditoría del servidor (DISABLE TRIGGER, roles de BD y de servidor, usuarios, permisos,
DML de [sgspi] y de dbo.usuario_grupo/dbo.grupo, lecturas de [eia] y cambios de la propia auditoría) se configura fuera de
la transacción en sql/sgspi/auditoria_servidor.sql.
AP-02  Privilegios mínimos: sgspi_rol_base (SELECT, DENY ALTER, DENY de escritura sobre [efc]/[tef] y sobre
columnas inmutables) y seis roles de actor, uno por grupo SGSPI_* de [dbo].[grupo], con GRANT por
tabla (sección 5.10.10). vw_usuario_rol_alcance_sgspi ya no expone per_identificacion ni per_email_interno
y solo lista grupos SGSPI_*. D5/D8: líder y custodio solo escriben en el alcance de sus UAA (sección 5.9b,
error 50021); la cuenta compartida (sgspi_rol_consulta) queda fuera de sgspi_rol_base y solo lee por lista blanca
los catálogos y las cinco vistas de inventario, DOFA y controles (vw_consolidado_dofa,
vw_resumen_activos_criticidad, vw_desglose_ccd_trd_mr04, vw_inventario_activo_documental_mr04,
vw_controles_atributos_iso27002), sin acceso a eia, plt, act, sga ni aud_*. Los roles transversales
van en lista explícita (oficial, comité y auditor; el gestor documental solo en activos, D9): sin rol de actor no hay
alcance. D2: el dictamen de eficacia solo lo escribe el auditor (DENY de sus columnas al líder y al oficial).
AP-03  Identidad sin procedimiento de contexto de sesión: sgspi.ufn_persona_sesion() resuelve la persona desde
ORIGINAL_LOGIN() -> [dbo].[usuario_general]; los triggers la exigen (error 50017 si falta), firman con ella las
aprobaciones y la fecha del dictamen de eficacia, y rechazan (50019) un creador, evaluador o autor distinto.
AP-04  Todo registro nace en el estado inicial de su flujo (BORRADOR/PENDIENTE); rpi y aci ya no nacen
VIGENTE (error 50014). Tampoco se crean registros ni se mueven a una vigencia CERRADA o HISTORICA en
acf, rpi, ado, eia y eac (error 50022, D7). Carga histórica: con la auditoría del servidor encendida
(sql/sgspi/auditoria_servidor.sql), un administrador (dbo) deshabilita temporalmente el trigger
TR_<acr>_integridad_y_actualizacion de la tabla, vuelve a habilitarlo en el mismo script y termina con consultas de
control que deben dar cero filas (estado inicial, aprobador en VIGENTE y propietario único activo); ya no existe
usp_habilitar_carga_inicial.
AP-05  Máquina de estados dirigida por datos: [efc] estados y [tef] transiciones reemplazan 5 CHECK de
listas y 5 bloques de transiciones copiados en los triggers. La aplican los triggers
TR_<acr>_integridad_y_actualizacion de acf, rpi, aci, eia y act (error 50011).
[tef_rol_requerido] restringe transiciones por rol de BD, una fila por rol permitido (NULL = cualquier rol con UPDATE; db_owner pasa siempre).
Las transiciones de captura de ACI y EIA nombran sus roles: el gestor, el comité y el auditor tienen UPDATE del estado para las suyas.
AP-06  Integridad declarativa entre tablas: estrategia/naturaleza del evento, causal/nivel de reserva,
nivel del padre en la taxonomía, componente afectado = categoría ISO 27005, serie con subseries y, D4, riesgo
en un proceso que usa su activo primario (FK_eia_activo_proceso hacia [aip]).
AP-07  Atributos ISO/IEC 27002:2022 normalizados ([aac]/[cra]) en vez de texto multivaluado.
AP-08  Enumeraciones libres reemplazadas por catálogo o CHECK ([fac]/[adf], tac_codigo_componente,
sif_modalidad_desarrollo); se elimina ado_tipo_activo_documental (redundante con tac_codigo).
AP-09  Sin dependencias transitivas ni datos derivados sueltos: [zrc], mvr_codigo_posicion calculada,
letra de probabilidad coherente, avance de actividad sincronizado desde [sga], UAA líder única e identificador
RA-nn/OA-nn de [eia] calculado desde eia_numero_evento (antes texto con el número dentro).
AP-10  [ado] usa PK compartida con [aci] (ado_codigo = aci_codigo).
AP-11  *_fecha_actualizacion ya no es una columna muerta: la mantiene el trigger
TR_<acr>_integridad_y_actualizacion en acf, rpi, aci, ado, eia, plt, act y eac (ado, eia y eac la
recuperan al retirarse las tablas temporales).
AP-12  Marcas de fecha en DATETIMEOFFSET(0) (zona horaria explícita).
AP-13  Valores normalizados (PUBLICA, NO_CLASIFICADA, ...) y vistas filtradas por enc_familia_norma.
AP-14  Claves naturales con UNIQUE (pri, cet, msi, act).
AP-15  Segregación de funciones: aprobador/firmantes distintos del creador; aprobador obligatorio en
estados aprobados; rpi gana creador y aprobador. El creador debe ser la persona de la sesión (50019, AP-03):
sin eso, declarar a otra persona como creadora anularía los CHECK de segregación.
AP-16  Coherencia de eficacia del plan, KPI sin desborde (DECIMAL(15,2)), evidencia con formato hex minúscula, seguimiento
append-only con recálculo de avance al desactivar y requisitos de transición (50020) en aci (propietario D3, aval de Archivo RN-DOC-06 y custodio RN-ACT-05) y en eia (plan, comité, meta residual <= inherente RN-RSG-04, control ISO27701 RN-RSG-05, actividades completadas en paso 11 y eficacia en cierre, D2).
AP-17  Todos los DEFAULT con nombre DF_<columna>.
AP-18  Índices redundantes eliminados, INCLUDE de claves clustered retirados, índice para FK compuesta.
AP-19  Verificación previa: el script se detiene sin cambios si [sgspi] ya tiene tablas o faltan
dependencias de [dbo]. El despliegue corre en una sola transacción (todo o nada) y, antes del COMMIT, se revierte si falta
algún objeto (un lote que no compiló).
AP-20  GROUPING() en lugar de ISNULL para rotular subtotales.
AP-21  RETIRADO (funciones de contexto de auditoría y de hash, eliminadas con AP-01 y AP-03).
AP-22  Borrado lógico: ningún registro se elimina. Toda tabla (salvo las aud_*, de solo inserción) tiene <acr>_esta_activo/<acr>_esta_activa BIT
(1 = activo, 0 = inactivo, DEFAULT 1); <acr>_esta_activo = 0 significa registro anulado por error, mientras que
INACTIVO e HISTORICO son etapas del ciclo de vida. DENY DELETE sobre el esquema, sin ON DELETE CASCADE, tablas puente
con UPDATE en vez de DELETE y vistas de reporte que filtran <acr>_esta_activo = 1 en la entidad principal y en las
asociaciones. En estados no editables (efc_permite_edicion = 0) desactivar exige primero una transición.
AP-23  Plazo legal de la reserva (Ley 1712 de 2014, art. 22): la información RESERVADA no puede tener reserva
indefinida ni de más de 15 años.
AP-24  Concurrencia: (a) control optimista con <acr>_version ROWVERSION NOT NULL en acf, rpi, aci, ado, eia, plt, act y
eac (la aplicación actualiza con WHERE <acr>_codigo = @id AND <acr>_version = @v y vuelve a leer tras guardar, porque el
UPDATE del trigger incrementa la versión); (b) TR_ado, TR_plt, TR_act y los 10 triggers puente leen el padre con
WITH (UPDLOCK) (la aplicación reintenta ante deadlock, error 1205); (c) patrón único de consecutivos (acf_numero_factor y
eia_numero_evento por vigencia y naturaleza, act_numero_orden por plan), con reintento en la aplicación ante los errores
2601/2627; en eia el identificador RA-nn/OA-nn se calcula desde el número:
    INSERT sgspi.analisis_contexto_factor (..., acf_numero_factor, ...)
    SELECT ..., ISNULL(MAX(acf_numero_factor), 0) + 1, ...
    FROM sgspi.analisis_contexto_factor WITH (UPDLOCK, HOLDLOCK)
    WHERE pev_codigo = @pev AND acf_naturaleza_factor = @naturaleza;
==================================================================================================*/
-- Opciones SET obligatorias para toda sesión, script o job del Agente SQL que ejecute DML sobre [sgspi]
-- (sqlcmd requiere -I para QUOTED_IDENTIFIER ON): los índices filtrados (UX_*) y las columnas calculadas
-- indexadas (upc, mvr, eia) fallan con el error 1934 si alguna de estas opciones no tiene este valor.
SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET QUOTED_IDENTIFIER ON;
SET NUMERIC_ROUNDABORT OFF;
SET NOCOUNT ON;
SET XACT_ABORT ON;


GO
/*==================================================================================================
0. VERIFICACIÓN PREVIA DE DESPLIEGUE [AP-19]
Si la verificación falla, SET NOEXEC ON hace que el resto del script se compile pero NO se ejecute.
Si pasa, todo el despliegue corre en UNA transacción: ante un error, XACT_ABORT la revierte y la guarda
"IF @@TRANCOUNT = 0 SET NOEXEC ON" que abre cada lote impide que los lotes siguientes se ejecuten sueltos,
de modo que nunca queda un despliegue a medias. El script termina con COMMIT y SET NOEXEC OFF.
VENTANA DE MANTENIMIENTO: la transacción retiene bloqueos de esquema (Sch-M) sobre dbo.persona, dbo.uaa,
dbo.cargo, dbo.espacio y dbo.sub_sede hasta el COMMIT (bloquea lecturas y escrituras concurrentes sobre
esas tablas); se conservan las FK hacia dbo.persona en negocio y aud_* para integridad referencial [AP-01].
Un error de sintaxis (nivel 15) no revierte la transacción, ni siquiera con XACT_ABORT: la guarda previa al COMMIT valida
conteos, objetos nominales clave, paridad aud_* y compilación de vistas (sp_refreshview); si algo falla, revierte todo
(DESPLIEGUE SGSPI REVERTIDO SIN CAMBIOS), con o sin "sqlcmd -b".
==================================================================================================*/
DECLARE @errores AS NVARCHAR (2000) = N'';

IF CONVERT (INT, (SELECT compatibility_level
                  FROM   sys.databases
                  WHERE  database_id = DB_ID())) < 150
    SET @errores += N' La base de datos debe tener nivel de compatibilidad 150 o superior.';

IF EXISTS (SELECT 1
           FROM   sys.tables AS t
                  INNER JOIN
                  sys.schemas AS s
                  ON s.schema_id = t.schema_id
           WHERE  s.name = N'sgspi')
    SET @errores += N' El esquema [sgspi] ya contiene tablas: este script es de creación inicial; use un script de migración.';

DECLARE @dependencias TABLE (
    tabla   SYSNAME,
    columna SYSNAME);

INSERT  INTO @dependencias (
    tabla,
    columna
)
VALUES                     (N'dbo.uaa', N'uaa_codigo'),
                           (N'dbo.uaa', N'uaa_nombre'),
                           (N'dbo.cargo', N'car_codigo'),
                           (N'dbo.cargo', N'car_nombre'),
                           (N'dbo.persona', N'per_codigo'),
                           (N'dbo.persona', N'per_nombre'),
                           (N'dbo.persona', N'per_apellido'),
                           (N'dbo.espacio', N'esp_codigo'),
                           (N'dbo.sub_sede', N'sus_codigo'),
                           (N'dbo.grupo', N'gru_codigo'),
                           (N'dbo.grupo', N'gru_nombre'),
                           (N'dbo.grupo', N'gru_estado'),
                           (N'dbo.usuario_grupo', N'usg_codigo'),
                           (N'dbo.usuario_grupo', N'usg_grupo'),
                           (N'dbo.usuario_grupo', N'usg_uaa'),
                           (N'dbo.usuario_grupo', N'usg_usuario'),
                           (N'dbo.usuario_grupo', N'usg_estado'),
                           (N'dbo.usuario_general', N'uid'),
                           (N'dbo.usuario_general', N'up'),
                           (N'dbo.usuario_general', N'us'),
                           (N'dbo.usuario_general', N'state');

DECLARE @faltantes AS NVARCHAR (1000) = (SELECT STRING_AGG(CONCAT(tabla, N'.', columna), N', ')
                                         FROM   @dependencias
                                         WHERE  COL_LENGTH(tabla, columna) IS NULL);

IF @faltantes IS NOT NULL
    SET @errores += N' Faltan dependencias del esquema corporativo: ' + @faltantes + N'.';

DECLARE @sin_clave_fk AS NVARCHAR (1000) = (SELECT STRING_AGG(CONCAT(v.tabla, N'(', v.columna, N')'), N', ')
                                            FROM   (VALUES (N'dbo.uaa', N'uaa_codigo'),
                                                           (N'dbo.cargo', N'car_codigo'),
                                                           (N'dbo.persona', N'per_codigo'),
                                                           (N'dbo.espacio', N'esp_codigo'),
                                                           (N'dbo.sub_sede', N'sus_codigo')) AS v(tabla, columna)
                                            WHERE  COL_LENGTH(v.tabla, v.columna) IS NOT NULL
                                                   AND NOT EXISTS (SELECT 1
                                                                   FROM   sys.indexes AS ix
                                                                          INNER JOIN
                                                                          sys.index_columns AS ic
                                                                          ON ic.object_id = ix.object_id
                                                                             AND ic.index_id = ix.index_id
                                                                             AND ic.is_included_column = 0
                                                                          INNER JOIN
                                                                          sys.columns AS c
                                                                          ON c.object_id = ic.object_id
                                                                             AND c.column_id = ic.column_id
                                                                   WHERE  ix.object_id = OBJECT_ID(v.tabla)
                                                                          AND OBJECTPROPERTY(ix.object_id, N'IsUserTable') = 1
                                                                          AND ix.is_unique = 1
                                                                          AND ix.is_disabled = 0
                                                                          AND ix.has_filter = 0
                                                                          AND ix.is_hypothetical = 0
                                                                   GROUP BY ix.index_id
                                                                   HAVING COUNT(*) = 1
                                                                          AND MAX(c.name) = v.columna));

IF @sin_clave_fk IS NOT NULL
    SET @errores += N' Tablas de [dbo] sin PK/UQ activa para FK: ' + @sin_clave_fk + N'.';

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

IF EXISTS (SELECT 1
           FROM   sys.fn_listextendedproperty(N'sgspi_version', N'SCHEMA', N'sgspi', NULL, NULL, NULL, NULL))
    EXECUTE sys.sp_updateextendedproperty N'sgspi_version', N'2.1', N'SCHEMA', N'sgspi';
ELSE
    EXECUTE sys.sp_addextendedproperty N'sgspi_version', N'2.1', N'SCHEMA', N'sgspi';


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
/*==================================================================================================
                            1. DOMINIO TRANSVERSAL, GOBERNANZA SGC Y ARTICULACIÓN CON [dbo]
                            ==================================================================================================*/
-- 1.1 [pev] Periodos de Vigencia Anual del SGSPI
CREATE TABLE sgspi.periodo_vigencia (
    pev_codigo          SMALLINT           IDENTITY (1, 1) NOT NULL,
    pev_anio            SMALLINT           NOT NULL,
    pev_fecha_apertura  DATE               NOT NULL,
    pev_fecha_cierre    DATE               NULL,
    pev_estado_vigencia NVARCHAR (20)      CONSTRAINT DF_pev_estado_vigencia DEFAULT N'ABIERTA' NOT NULL, -- [AP-17] DEFAULT con nombre
    pev_fecha_creacion  DATETIMEOFFSET (0) CONSTRAINT DF_pev_fecha_creacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17] Zona horaria explícita
    pev_esta_activo     BIT                CONSTRAINT DF_pev_esta_activo DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
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
    ON sgspi.estado_flujo_catalogo(efc_dominio) WHERE efc_es_inicial = 1;

CREATE TABLE sgspi.transicion_estado_flujo (
    tef_codigo                SMALLINT      IDENTITY (1, 1) NOT NULL,
    efc_dominio               NVARCHAR (10) NOT NULL,
    efc_identificador_origen  NVARCHAR (30) NOT NULL,
    efc_identificador_destino NVARCHAR (30) NOT NULL,
    tef_rol_requerido         SYSNAME       NULL, -- NULL = cualquier rol con UPDATE
    tef_esta_activa           BIT           CONSTRAINT DF_tef_esta_activa DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
    CONSTRAINT PK_tef_transicion_estado_flujo PRIMARY KEY CLUSTERED (tef_codigo),
    CONSTRAINT UQ_tef_dominio_origen_destino_rol UNIQUE (efc_dominio, efc_identificador_origen, efc_identificador_destino, tef_rol_requerido), -- una fila por rol permitido
    CONSTRAINT FK_tef_estado_origen FOREIGN KEY (efc_dominio, efc_identificador_origen) REFERENCES sgspi.estado_flujo_catalogo (efc_dominio, efc_identificador),
    CONSTRAINT FK_tef_estado_destino FOREIGN KEY (efc_dominio, efc_identificador_destino) REFERENCES sgspi.estado_flujo_catalogo (efc_dominio, efc_identificador),
    CONSTRAINT CK_tef_origen_distinto_destino CHECK (efc_identificador_origen <> efc_identificador_destino)
);

CREATE NONCLUSTERED INDEX IX_tef_estado_destino
    ON sgspi.transicion_estado_flujo(efc_dominio, efc_identificador_destino);


GO
-- Semilla de estados y transiciones de todos los dominios de flujo
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [AP-05] Estados (se toman de los CHECK y triggers originales)
-- Identificadores usados en CHECK o triggers (no renombrar en [efc] ni en [enc].[enc_familia_norma]):
-- BORRADOR, VIGENTE, EN_VALIDACION_LIDER, EN_REVISION_ARCHIVO, EN_REVISION_SGSPI, EN_ACEPTACION_COMITE,
-- APROBADO_PLANIFICADO, EN_EVALUACION_EFICACIA, CERRADO_EFICAZ, PENDIENTE, COMPLETADA; familia ISO27701.
INSERT INTO sgspi.estado_flujo_catalogo (
    efc_dominio,
    efc_identificador,
    efc_nombre,
    efc_es_inicial,
    efc_permite_edicion
)
SELECT v.dominio,
       v.identificador,
       v.nombre,
       v.es_inicial,
       v.permite_edicion
FROM   (VALUES -- ACF: Análisis de Contexto de Factores
       (N'ACF', N'BORRADOR', N'Borrador', 1, 1), (N'ACF', N'EN_VALIDACION_LIDER', N'En validación del líder', 0, 1), (N'ACF', N'EN_REVISION_SGSPI', N'En revisión SGSPI', 0, 1), (N'ACF', N'OBSERVADO', N'Observado', 0, 1), (N'ACF', N'VIGENTE', N'Vigente', 0, 0), (N'ACF', N'HISTORICO', N'Histórico', 0, 0), -- RPI: Requisitos de Partes Interesadas
       (N'RPI', N'BORRADOR', N'Borrador', 1, 1), (N'RPI', N'EN_VALIDACION_LIDER', N'En validación del líder', 0, 1), (N'RPI', N'EN_REVISION_SGSPI', N'En revisión SGSPI', 0, 1), (N'RPI', N'OBSERVADO', N'Observado', 0, 1), (N'RPI', N'VIGENTE', N'Vigente', 0, 0), (N'RPI', N'HISTORICO', N'Histórico', 0, 0), -- ACI: Activos de Información
       (N'ACI', N'BORRADOR', N'Borrador', 1, 1), (N'ACI', N'EN_VALIDACION_LIDER', N'En validación del líder', 0, 1), (N'ACI', N'EN_REVISION_ARCHIVO', N'En revisión de Archivo', 0, 1), (N'ACI', N'EN_REVISION_SGSPI', N'En revisión SGSPI', 0, 1), (N'ACI', N'OBSERVADO', N'Observado', 0, 1), (N'ACI', N'VIGENTE', N'Vigente', 0, 0), (N'ACI', N'INACTIVO', N'Inactivo', 0, 1), (N'ACI', N'HISTORICO', N'Histórico', 0, 0), -- EIA: Eventos de Incertidumbre sobre Activos
       (N'EIA', N'BORRADOR', N'Borrador', 1, 1), (N'EIA', N'EN_VALIDACION_LIDER', N'En validación del líder', 0, 1), (N'EIA', N'EN_REVISION_SGSPI', N'En revisión SGSPI', 0, 1), (N'EIA', N'OBSERVADO', N'Observado', 0, 1), (N'EIA', N'EN_ACEPTACION_COMITE', N'En aceptación del comité', 0, 1), (N'EIA', N'APROBADO_PLANIFICADO', N'Aprobado y planificado', 0, 1), (N'EIA', N'EN_EJECUCION', N'En ejecución', 0, 1), (N'EIA', N'EN_EVALUACION_EFICACIA', N'En evaluación de eficacia', 0, 1), (N'EIA', N'CERRADO_EFICAZ', N'Cerrado eficaz', 0, 0), (N'EIA', N'HISTORICO', N'Histórico', 0, 0), -- ACT: Actividades de Tratamiento
       (N'ACT', N'PENDIENTE', N'Pendiente', 1, 1), (N'ACT', N'EN_CURSO', N'En curso', 0, 1), (N'ACT', N'COMPLETADA', N'Completada', 0, 0), (N'ACT', N'OBSERVADA', N'Observada', 0, 1)) AS v(dominio, identificador, nombre, es_inicial, permite_edicion);

-- [AP-05] Transiciones válidas (se toman de los triggers originales); tef_rol_requerido NULL = cualquier rol con UPDATE
-- Las de captura de ACI y EIA (desde BORRADOR y OBSERVADO) nombran sus roles, una fila por rol: el gestor (ACI), el comité
-- y el auditor (EIA) tienen UPDATE del estado solo para sus propias transiciones.
-- D2: el auditor certifica la eficacia (EN_EVALUACION_EFICACIA -> CERRADO_EFICAZ) o reabre la ejecución (-> EN_EJECUCION)
INSERT INTO sgspi.transicion_estado_flujo (
    efc_dominio,
    efc_identificador_origen,
    efc_identificador_destino,
    tef_rol_requerido
)
SELECT v.dominio,
       v.origen,
       v.destino,
       v.rol_requerido
FROM   (VALUES -- ACF
       (N'ACF', N'BORRADOR', N'EN_VALIDACION_LIDER', NULL), (N'ACF', N'EN_VALIDACION_LIDER', N'EN_REVISION_SGSPI', N'sgspi_rol_lider_propietario'), (N'ACF', N'EN_VALIDACION_LIDER', N'OBSERVADO', N'sgspi_rol_lider_propietario'), (N'ACF', N'EN_VALIDACION_LIDER', N'BORRADOR', N'sgspi_rol_lider_propietario'), (N'ACF', N'EN_REVISION_SGSPI', N'VIGENTE', N'sgspi_rol_oficial_seguridad_privacidad'), (N'ACF', N'EN_REVISION_SGSPI', N'OBSERVADO', N'sgspi_rol_oficial_seguridad_privacidad'), (N'ACF', N'OBSERVADO', N'BORRADOR', NULL), (N'ACF', N'OBSERVADO', N'EN_VALIDACION_LIDER', NULL), (N'ACF', N'VIGENTE', N'HISTORICO', N'sgspi_rol_oficial_seguridad_privacidad'), (N'ACF', N'VIGENTE', N'EN_REVISION_SGSPI', N'sgspi_rol_oficial_seguridad_privacidad'), -- RPI
       (N'RPI', N'BORRADOR', N'EN_VALIDACION_LIDER', NULL), (N'RPI', N'EN_VALIDACION_LIDER', N'EN_REVISION_SGSPI', N'sgspi_rol_lider_propietario'), (N'RPI', N'EN_VALIDACION_LIDER', N'OBSERVADO', N'sgspi_rol_lider_propietario'), (N'RPI', N'EN_VALIDACION_LIDER', N'BORRADOR', N'sgspi_rol_lider_propietario'), (N'RPI', N'EN_REVISION_SGSPI', N'VIGENTE', N'sgspi_rol_oficial_seguridad_privacidad'), (N'RPI', N'EN_REVISION_SGSPI', N'OBSERVADO', N'sgspi_rol_oficial_seguridad_privacidad'), (N'RPI', N'OBSERVADO', N'BORRADOR', NULL), (N'RPI', N'OBSERVADO', N'EN_VALIDACION_LIDER', NULL), (N'RPI', N'VIGENTE', N'HISTORICO', N'sgspi_rol_oficial_seguridad_privacidad'), (N'RPI', N'VIGENTE', N'EN_REVISION_SGSPI', N'sgspi_rol_oficial_seguridad_privacidad'), -- ACI
       (N'ACI', N'BORRADOR', N'EN_VALIDACION_LIDER', N'sgspi_rol_custodio_operador'), (N'ACI', N'BORRADOR', N'EN_VALIDACION_LIDER', N'sgspi_rol_lider_propietario'), (N'ACI', N'BORRADOR', N'EN_VALIDACION_LIDER', N'sgspi_rol_oficial_seguridad_privacidad'), (N'ACI', N'EN_VALIDACION_LIDER', N'EN_REVISION_ARCHIVO', N'sgspi_rol_lider_propietario'), (N'ACI', N'EN_VALIDACION_LIDER', N'EN_REVISION_SGSPI', N'sgspi_rol_lider_propietario'), (N'ACI', N'EN_VALIDACION_LIDER', N'OBSERVADO', N'sgspi_rol_lider_propietario'), (N'ACI', N'EN_VALIDACION_LIDER', N'BORRADOR', N'sgspi_rol_lider_propietario'), (N'ACI', N'EN_REVISION_ARCHIVO', N'EN_REVISION_SGSPI', N'sgspi_rol_gestor_documental'), (N'ACI', N'EN_REVISION_ARCHIVO', N'OBSERVADO', N'sgspi_rol_gestor_documental'), (N'ACI', N'EN_REVISION_SGSPI', N'VIGENTE', N'sgspi_rol_oficial_seguridad_privacidad'), (N'ACI', N'EN_REVISION_SGSPI', N'OBSERVADO', N'sgspi_rol_oficial_seguridad_privacidad'), (N'ACI', N'OBSERVADO', N'BORRADOR', N'sgspi_rol_custodio_operador'), (N'ACI', N'OBSERVADO', N'BORRADOR', N'sgspi_rol_lider_propietario'), (N'ACI', N'OBSERVADO', N'BORRADOR', N'sgspi_rol_oficial_seguridad_privacidad'), (N'ACI', N'OBSERVADO', N'EN_VALIDACION_LIDER', N'sgspi_rol_custodio_operador'), (N'ACI', N'OBSERVADO', N'EN_VALIDACION_LIDER', N'sgspi_rol_lider_propietario'), (N'ACI', N'OBSERVADO', N'EN_VALIDACION_LIDER', N'sgspi_rol_oficial_seguridad_privacidad'), (N'ACI', N'VIGENTE', N'INACTIVO', N'sgspi_rol_oficial_seguridad_privacidad'), (N'ACI', N'VIGENTE', N'HISTORICO', N'sgspi_rol_oficial_seguridad_privacidad'), (N'ACI', N'VIGENTE', N'EN_REVISION_SGSPI', N'sgspi_rol_oficial_seguridad_privacidad'), (N'ACI', N'VIGENTE', N'EN_REVISION_ARCHIVO', N'sgspi_rol_oficial_seguridad_privacidad'), (N'ACI', N'INACTIVO', N'VIGENTE', N'sgspi_rol_oficial_seguridad_privacidad'), (N'ACI', N'INACTIVO', N'HISTORICO', N'sgspi_rol_oficial_seguridad_privacidad'), -- EIA
       (N'EIA', N'BORRADOR', N'EN_VALIDACION_LIDER', N'sgspi_rol_lider_propietario'), (N'EIA', N'BORRADOR', N'EN_VALIDACION_LIDER', N'sgspi_rol_oficial_seguridad_privacidad'), (N'EIA', N'EN_VALIDACION_LIDER', N'EN_REVISION_SGSPI', N'sgspi_rol_lider_propietario'), (N'EIA', N'EN_VALIDACION_LIDER', N'OBSERVADO', N'sgspi_rol_lider_propietario'), (N'EIA', N'EN_VALIDACION_LIDER', N'BORRADOR', N'sgspi_rol_lider_propietario'), (N'EIA', N'EN_REVISION_SGSPI', N'EN_ACEPTACION_COMITE', N'sgspi_rol_oficial_seguridad_privacidad'), (N'EIA', N'EN_REVISION_SGSPI', N'APROBADO_PLANIFICADO', N'sgspi_rol_oficial_seguridad_privacidad'), (N'EIA', N'EN_REVISION_SGSPI', N'OBSERVADO', N'sgspi_rol_oficial_seguridad_privacidad'), (N'EIA', N'EN_ACEPTACION_COMITE', N'APROBADO_PLANIFICADO', N'sgspi_rol_comite_direccion'), (N'EIA', N'EN_ACEPTACION_COMITE', N'OBSERVADO', N'sgspi_rol_comite_direccion'), (N'EIA', N'OBSERVADO', N'BORRADOR', N'sgspi_rol_lider_propietario'), (N'EIA', N'OBSERVADO', N'BORRADOR', N'sgspi_rol_oficial_seguridad_privacidad'), (N'EIA', N'OBSERVADO', N'EN_VALIDACION_LIDER', N'sgspi_rol_lider_propietario'), (N'EIA', N'OBSERVADO', N'EN_VALIDACION_LIDER', N'sgspi_rol_oficial_seguridad_privacidad'), (N'EIA', N'APROBADO_PLANIFICADO', N'EN_EJECUCION', N'sgspi_rol_lider_propietario'), (N'EIA', N'APROBADO_PLANIFICADO', N'OBSERVADO', N'sgspi_rol_lider_propietario'), (N'EIA', N'EN_EJECUCION', N'EN_EVALUACION_EFICACIA', N'sgspi_rol_lider_propietario'), (N'EIA', N'EN_EJECUCION', N'OBSERVADO', N'sgspi_rol_lider_propietario'), (N'EIA', N'EN_EVALUACION_EFICACIA', N'CERRADO_EFICAZ', N'sgspi_rol_auditor_control'), (N'EIA', N'EN_EVALUACION_EFICACIA', N'EN_EJECUCION', N'sgspi_rol_auditor_control'), (N'EIA', N'EN_EVALUACION_EFICACIA', N'OBSERVADO', N'sgspi_rol_oficial_seguridad_privacidad'), (N'EIA', N'CERRADO_EFICAZ', N'HISTORICO', N'sgspi_rol_oficial_seguridad_privacidad'), -- ACT
       (N'ACT', N'PENDIENTE', N'EN_CURSO', NULL), (N'ACT', N'PENDIENTE', N'OBSERVADA', NULL), (N'ACT', N'EN_CURSO', N'COMPLETADA', N'sgspi_rol_lider_propietario'), (N'ACT', N'EN_CURSO', N'OBSERVADA', N'sgspi_rol_lider_propietario'), (N'ACT', N'OBSERVADA', N'PENDIENTE', NULL), (N'ACT', N'OBSERVADA', N'EN_CURSO', NULL), (N'ACT', N'COMPLETADA', N'OBSERVADA', N'sgspi_rol_oficial_seguridad_privacidad')) AS v(dominio, origen, destino, rol_requerido);


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
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
    pri_codigo        INT            IDENTITY (1, 1) NOT NULL,
    pri_identificador NVARCHAR (20)  NOT NULL,
    pri_nombre        NVARCHAR (150) NOT NULL,
    tpr_codigo        TINYINT        NOT NULL, -- FK a [sgspi].[tipo_proceso_catalogo]([tpr_codigo])
    uaa_codigo_lider  INT            NULL, -- FK a [dbo].[uaa]([uaa_codigo])
    car_codigo_lider  INT            NULL, -- FK a [dbo].[cargo]([car_codigo])
    pri_esta_activo   BIT            CONSTRAINT DF_pri_esta_activo DEFAULT 1 NOT NULL, -- [AP-17]
    CONSTRAINT PK_pri_proceso_institucional PRIMARY KEY CLUSTERED (pri_codigo),
    CONSTRAINT UQ_pri_identificador UNIQUE (pri_identificador), -- [AP-14] Clave natural con UNIQUE
    CONSTRAINT UQ_pri_nombre UNIQUE (pri_nombre),
    CONSTRAINT FK_pri_tipo_proceso FOREIGN KEY (tpr_codigo) REFERENCES sgspi.tipo_proceso_catalogo (tpr_codigo),
    CONSTRAINT FK_pri_dbo_uaa_lider FOREIGN KEY (uaa_codigo_lider) REFERENCES dbo.uaa (uaa_codigo),
    CONSTRAINT FK_pri_dbo_cargo_lider FOREIGN KEY (car_codigo_lider) REFERENCES dbo.cargo (car_codigo),
    CONSTRAINT CK_pri_identificador_no_vacio CHECK (LEN(TRIM(pri_identificador)) > 0) -- [AP-14]
);

CREATE NONCLUSTERED INDEX IX_pri_tpr_codigo
    ON sgspi.proceso_institucional(tpr_codigo);

CREATE NONCLUSTERED INDEX IX_pri_uaa_codigo_lider
    ON sgspi.proceso_institucional(uaa_codigo_lider);

CREATE NONCLUSTERED INDEX IX_pri_car_codigo_lider
    ON sgspi.proceso_institucional(car_codigo_lider);

-- 1.5 [piu] Tabla Puente N:M Proceso Institucional <-> Unidades Académico-Administrativas ([dbo].[uaa])
-- [AP-09] Se elimina piu_es_responsable_principal: la UAA líder del proceso es [uaa_codigo_lider] (una sola fuente de verdad)
CREATE TABLE sgspi.proceso_institucional_uaa (
    pri_codigo      INT NOT NULL, -- FK a [sgspi].[proceso_institucional]([pri_codigo])
    uaa_codigo      INT NOT NULL, -- FK a [dbo].[uaa]([uaa_codigo])
    piu_esta_activo BIT CONSTRAINT DF_piu_esta_activo DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
    CONSTRAINT PK_piu_proceso_institucional_uaa PRIMARY KEY CLUSTERED (pri_codigo, uaa_codigo),
    CONSTRAINT FK_piu_proceso_institucional FOREIGN KEY (pri_codigo) REFERENCES sgspi.proceso_institucional (pri_codigo),
    CONSTRAINT FK_piu_dbo_uaa FOREIGN KEY (uaa_codigo) REFERENCES dbo.uaa (uaa_codigo)
);

CREATE NONCLUSTERED INDEX IX_piu_uaa_codigo
    ON sgspi.proceso_institucional_uaa(uaa_codigo); -- [AP-09] Sin INCLUDE de la columna eliminada


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


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
    fec_esta_activo    BIT            CONSTRAINT DF_fec_esta_activo DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
    CONSTRAINT PK_fec_factor_entorno_catalogo PRIMARY KEY CLUSTERED (fec_codigo),
    CONSTRAINT UQ_fec_nombre_ambito UNIQUE (fec_nombre_factor, fec_ambito_entorno),
    CONSTRAINT UQ_fec_codigo_ambito UNIQUE (fec_codigo, fec_ambito_entorno), -- [AP-06] destino de la FK compuesta FK_acf_factor_entorno_ambito
    CONSTRAINT CK_fec_ambito_entorno CHECK (fec_ambito_entorno IN (N'INTERNO', N'EXTERNO'))
);

-- 2.2 [acf] Análisis de Factores de Contexto por Proceso (DOFA por Proceso y Consolidado)
CREATE TABLE sgspi.analisis_contexto_factor (
    acf_codigo                  INT                IDENTITY (1, 1) NOT NULL,
    pev_codigo                  SMALLINT           NOT NULL, -- FK a [sgspi].[periodo_vigencia]([pev_codigo])
    pri_codigo                  INT                NOT NULL, -- FK a [sgspi].[proceso_institucional]([pri_codigo])
    fec_codigo                  SMALLINT           NOT NULL, -- FK a [sgspi].[factor_entorno_catalogo]([fec_codigo])
    acf_naturaleza_factor       NVARCHAR (15)      NOT NULL, -- 'DEBILIDAD', 'FORTALEZA', 'AMENAZA', 'OPORTUNIDAD'
    fec_ambito_entorno          AS                 (CONVERT (NVARCHAR (15), CASE WHEN acf_naturaleza_factor IN (N'DEBILIDAD', N'FORTALEZA') THEN N'INTERNO' ELSE N'EXTERNO' END)) PERSISTED, -- [AP-06] DOFA: debilidades y fortalezas son factores internos; amenazas y oportunidades, externos
    acf_numero_factor           SMALLINT           NOT NULL, -- Consecutivo inmutable por vigencia y naturaleza (1..n)
    acf_identificador_factor    AS                 (CONVERT (NVARCHAR (15), CONCAT(LEFT(acf_naturaleza_factor, 1), acf_numero_factor))) PERSISTED, -- Identificador documental estable ('D1'..'Dn', 'F1'..'Fn', 'A1'..'An', 'O1'..'On')
    acf_descripcion_situacion   NVARCHAR (1000)    NOT NULL,
    acf_valor_prioridad         TINYINT            CONSTRAINT DF_acf_valor_prioridad DEFAULT 1 NOT NULL, -- Escala ordinal unificada: 1=BAJA, 2=MEDIA, 3=ALTA
    acf_nivel_prioridad         AS                 (CASE acf_valor_prioridad WHEN 3 THEN N'ALTA' WHEN 2 THEN N'MEDIA' ELSE N'BAJA' END) PERSISTED,
    acf_impacto_sistema_gestion NVARCHAR (1000)    NULL,
    acf_accion_propuesta        NVARCHAR (1000)    NULL,
    acf_estado_registro         NVARCHAR (30)      CONSTRAINT DF_acf_estado_registro DEFAULT N'BORRADOR' NOT NULL, -- [AP-17]
    efc_dominio                 AS                 (CONVERT (NVARCHAR (10), N'ACF')) PERSISTED, -- [AP-05] Dominio constante para la FK al catálogo de estados
    per_codigo_creador          INT                NOT NULL, -- FK a [dbo].[persona]([per_codigo])
    per_codigo_aprobador        INT                NULL, -- FK a [dbo].[persona]([per_codigo])
    acf_fecha_creacion          DATETIMEOFFSET (0) CONSTRAINT DF_acf_fecha_creacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17]
    acf_fecha_actualizacion     DATETIMEOFFSET (0) CONSTRAINT DF_acf_fecha_actualizacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17]
    acf_esta_activo             BIT                CONSTRAINT DF_acf_esta_activo DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
    acf_version                 ROWVERSION         NOT NULL, -- [AP-24] Control de concurrencia optimista
    CONSTRAINT PK_acf_analisis_contexto_factor PRIMARY KEY CLUSTERED (acf_codigo),
    CONSTRAINT FK_acf_periodo_vigencia FOREIGN KEY (pev_codigo) REFERENCES sgspi.periodo_vigencia (pev_codigo),
    CONSTRAINT FK_acf_proceso_institucional FOREIGN KEY (pri_codigo) REFERENCES sgspi.proceso_institucional (pri_codigo),
    CONSTRAINT FK_acf_factor_entorno_ambito FOREIGN KEY (fec_codigo, fec_ambito_entorno) REFERENCES sgspi.factor_entorno_catalogo (fec_codigo, fec_ambito_entorno), -- [AP-06] el factor tiene el ámbito que pide la naturaleza
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
    -- [AP-15] Segregación de funciones: el aprobador no puede ser el creador (la firma la escribe TR_acf_integridad_y_actualizacion)
    CONSTRAINT CK_acf_sod_aprobador CHECK (per_codigo_aprobador IS NULL
                                           OR per_codigo_aprobador <> per_codigo_creador)
);

-- [AP-18] Reemplaza la UNIQUE constraint y el índice IX_acf_pev_codigo (prefijo duplicado) por un único índice único con INCLUDE
CREATE UNIQUE NONCLUSTERED INDEX UX_acf_vigencia_naturaleza_numero
    ON sgspi.analisis_contexto_factor(pev_codigo, acf_naturaleza_factor, acf_numero_factor)
    INCLUDE(acf_identificador_factor, pri_codigo, fec_codigo);

CREATE NONCLUSTERED INDEX IX_acf_pri_codigo
    ON sgspi.analisis_contexto_factor(pri_codigo);

CREATE NONCLUSTERED INDEX IX_acf_fec_codigo
    ON sgspi.analisis_contexto_factor(fec_codigo);

CREATE NONCLUSTERED INDEX IX_acf_per_codigo_creador
    ON sgspi.analisis_contexto_factor(per_codigo_creador);

CREATE NONCLUSTERED INDEX IX_acf_per_codigo_aprobador
    ON sgspi.analisis_contexto_factor(per_codigo_aprobador);


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


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
    rpi_codigo                 INT                IDENTITY (1, 1) NOT NULL,
    pev_codigo                 SMALLINT           NOT NULL, -- FK a [sgspi].[periodo_vigencia]([pev_codigo])
    pai_codigo                 INT                NOT NULL, -- FK a [sgspi].[parte_interesada]([pai_codigo])
    rpi_necesidad_expectativa  NVARCHAR (1000)    NOT NULL,
    rpi_valor_poder            TINYINT            CONSTRAINT DF_rpi_valor_poder DEFAULT 1 NOT NULL, -- 1=BAJA, 2=MEDIA, 3=ALTA
    rpi_valor_interes          TINYINT            CONSTRAINT DF_rpi_valor_interes DEFAULT 1 NOT NULL, -- 1=BAJA, 2=MEDIA, 3=ALTA
    rpi_nivel_poder            AS                 (CASE rpi_valor_poder WHEN 3 THEN N'ALTA' WHEN 2 THEN N'MEDIA' ELSE N'BAJA' END) PERSISTED,
    rpi_nivel_interes          AS                 (CASE rpi_valor_interes WHEN 3 THEN N'ALTA' WHEN 2 THEN N'MEDIA' ELSE N'BAJA' END) PERSISTED,
    -- Columna calculada PERSISTED #3: Clasificación según Poder vs Interés con aritmética entera
    rpi_clasificacion_impacto  AS                 (CASE WHEN rpi_valor_poder = 3
                                                             AND rpi_valor_interes >= 2 THEN N'CUIDADO' WHEN (rpi_valor_poder = 3
                                                                                                              AND rpi_valor_interes = 1)
                                                                                                             OR (rpi_valor_poder = 2
                                                                                                                 AND rpi_valor_interes >= 2) THEN N'ATENCION' WHEN (rpi_valor_poder = 2
                                                                                                                                                                    AND rpi_valor_interes = 1)
                                                                                                                                                                   OR (rpi_valor_poder = 1
                                                                                                                                                                       AND rpi_valor_interes = 3) THEN N'MITIGANTE' ELSE N'SIN_PROBLEMA' END) PERSISTED,
    rpi_valor_cumplimiento     TINYINT            NULL, -- 1=BAJA, 2=MEDIA, 3=ALTA (NULL cuando aún no se ha evaluado)
    rpi_nivel_cumplimiento     AS                 (CASE rpi_valor_cumplimiento WHEN 3 THEN N'ALTA' WHEN 2 THEN N'MEDIA' WHEN 1 THEN N'BAJA' ELSE NULL END) PERSISTED,
    -- Columna calculada PERSISTED #4: Prioridad de Acción con aritmética directa (4 - cumplimiento) y etiqueta
    rpi_valor_prioridad_accion AS                 (CAST (4 - rpi_valor_cumplimiento AS TINYINT)) PERSISTED,
    rpi_prioridad_accion       AS                 (CASE rpi_valor_cumplimiento WHEN 1 THEN N'ALTA' WHEN 2 THEN N'MEDIA' WHEN 3 THEN N'BAJA' ELSE NULL END) PERSISTED,
    rpi_mecanismo_seguimiento  NVARCHAR (255)     NULL,
    rpi_estado_registro        NVARCHAR (30)      CONSTRAINT DF_rpi_estado_registro DEFAULT N'BORRADOR' NOT NULL, -- [AP-04] [AP-17] El INSERT solo puede nacer en el estado inicial
    efc_dominio                AS                 (CONVERT (NVARCHAR (10), N'RPI')) PERSISTED, -- [AP-05] Dominio constante para la FK al catálogo de estados
    per_codigo_creador         INT                NOT NULL, -- [AP-15] FK a [dbo].[persona]([per_codigo])
    per_codigo_aprobador       INT                NULL, -- [AP-15] FK a [dbo].[persona]([per_codigo])
    rpi_fecha_creacion         DATETIMEOFFSET (0) CONSTRAINT DF_rpi_fecha_creacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17]
    rpi_fecha_actualizacion    DATETIMEOFFSET (0) CONSTRAINT DF_rpi_fecha_actualizacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17]
    rpi_esta_activo            BIT                CONSTRAINT DF_rpi_esta_activo DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
    rpi_version                ROWVERSION         NOT NULL, -- [AP-24] Control de concurrencia optimista
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
    -- [AP-15] Segregación de funciones: el aprobador no puede ser el creador (la firma la escribe TR_rpi_integridad_y_actualizacion)
    CONSTRAINT CK_rpi_sod_aprobador CHECK (per_codigo_aprobador IS NULL
                                           OR per_codigo_aprobador <> per_codigo_creador)
);

CREATE NONCLUSTERED INDEX IX_rpi_pev_codigo
    ON sgspi.requisito_parte_interesada(pev_codigo);

CREATE NONCLUSTERED INDEX IX_rpi_pai_codigo
    ON sgspi.requisito_parte_interesada(pai_codigo);

CREATE NONCLUSTERED INDEX IX_rpi_per_codigo_creador -- [AP-15] [AP-18] Índice para la FK
    ON sgspi.requisito_parte_interesada(per_codigo_creador);

CREATE NONCLUSTERED INDEX IX_rpi_per_codigo_aprobador -- [AP-15] [AP-18] Índice para la FK
    ON sgspi.requisito_parte_interesada(per_codigo_aprobador);

-- 3.3 [rpp] Relación N:M Requisito de Parte Interesada <-> Proceso Institucional
CREATE TABLE sgspi.requisito_parte_interesada_proceso_institucional (
    rpi_codigo         INT                NOT NULL, -- FK a [sgspi].[requisito_parte_interesada]([rpi_codigo])
    pri_codigo         INT                NOT NULL, -- FK a [sgspi].[proceso_institucional]([pri_codigo])
    rpp_fecha_registro DATETIMEOFFSET (0) CONSTRAINT DF_rpp_fecha_registro DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17]
    rpp_esta_activo    BIT                CONSTRAINT DF_rpp_esta_activo DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
    CONSTRAINT PK_rpp_requisito_parte_interesada_proceso_institucional PRIMARY KEY CLUSTERED (rpi_codigo, pri_codigo),
    CONSTRAINT FK_rpp_requisito_parte_interesada FOREIGN KEY (rpi_codigo) REFERENCES sgspi.requisito_parte_interesada (rpi_codigo),
    CONSTRAINT FK_rpp_proceso_institucional FOREIGN KEY (pri_codigo) REFERENCES sgspi.proceso_institucional (pri_codigo)
);

CREATE NONCLUSTERED INDEX IX_rpp_pri_codigo
    ON sgspi.requisito_parte_interesada_proceso_institucional(pri_codigo);


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
/*==================================================================================================
                                                4. DOMINIO DE INVENTARIO Y CLASIFICACIÓN DE ACTIVOS (DOCUMENTO 4: ES-GSPI-MR-05)
                                                Articulado con [dbo].[uaa], [dbo].[sede], [dbo].[sub_sede], [dbo].[espacio], [dbo].[cargo] y [dbo].[persona]
                                                ==================================================================================================*/
-- 4.1 [tac] Catálogo Extensible de Taxonomía Jerárquica Autorreferenciada de Activos ISO/IEC 27005 (1=Categoría -> 2=Tipo -> 3=Subtipo)
CREATE TABLE sgspi.tipo_activo_catalogo (
    tac_codigo                SMALLINT       IDENTITY (1, 1) NOT NULL,
    tac_codigo_padre          SMALLINT       NULL, -- Código del nodo padre inmediato (NULL en las categorías de nivel 1; el padre de un Tipo es una Categoría y el de un Subtipo es un Tipo) [AP-06]
    tac_nivel_taxonomia       TINYINT        NOT NULL, -- 1=Categoría ISO 27005, 2=Tipo, 3=Subtipo
    tac_nivel_taxonomia_padre AS             (CONVERT (TINYINT, tac_nivel_taxonomia - 1)) PERSISTED, -- [AP-06] Nivel que debe tener el padre (exactamente un nivel arriba); soporta la FK compuesta FK_tac_padre
    tac_nombre                NVARCHAR (120) NOT NULL,
    tac_ejemplos_ref          NVARCHAR (255) NULL,
    tac_esta_activo           BIT            CONSTRAINT DF_tac_esta_activo DEFAULT 1 NOT NULL, -- [AP-17]
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
    cet_esta_activa             BIT            CONSTRAINT DF_cet_esta_activa DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
    CONSTRAINT PK_cet_causal_excepcion_transparencia PRIMARY KEY CLUSTERED (cet_codigo),
    CONSTRAINT UQ_cet_nivel_numeral UNIQUE (cet_nivel_reserva_aplicable, cet_numeral_causal), -- [AP-14] Clave natural de la causal
    CONSTRAINT UQ_cet_codigo_nivel UNIQUE (cet_codigo, cet_nivel_reserva_aplicable), -- [AP-06] Destino de la FK compuesta FK_aci_causal_excepcion
    CONSTRAINT CK_cet_nivel_reserva CHECK (cet_nivel_reserva_aplicable IN (N'CLASIFICADA', N'RESERVADA'))
);

-- 4.3 [aci] Supertipo: Inventario Maestro de Activos de Información (General ES-GSPI-MR-05 y Base de Activos Documentales ES-GSPI-MR-04)
CREATE TABLE sgspi.activo_informacion (
    aci_codigo                          INT                IDENTITY (1, 1) NOT NULL,
    aci_codigo_inventario               NVARCHAR (30)      NOT NULL,
    aci_nombre_activo                   NVARCHAR (255)     NOT NULL,
    aci_descripcion_detallada           NVARCHAR (1000)    NULL,
    tac_codigo                          SMALLINT           NOT NULL, -- FK a [sgspi].[tipo_activo_catalogo]([tac_codigo])
    uaa_codigo                          INT                NULL, -- FK a [dbo].[uaa]([uaa_codigo])
    esp_codigo                          INT                NULL, -- FK a [dbo].[espacio]([esp_codigo])
    aci_es_transversal_sedes            BIT                CONSTRAINT DF_aci_es_transversal_sedes DEFAULT 0 NOT NULL, -- [AP-17]
    aci_cantidad_unidades               INT                CONSTRAINT DF_aci_cantidad_unidades DEFAULT 1 NOT NULL, -- [AP-17]
    -- Clasificación de Transparencia e Índice de Información Clasificada y Reservada (Ley 1712 de 2014 / Decreto 103 de 2015)
    aci_clasificacion_transparencia     NVARCHAR (20)      NOT NULL, -- [AP-13] 'PUBLICA', 'CLASIFICADA', 'RESERVADA', 'NO_CLASIFICADA'
    cet_codigo                          SMALLINT           NULL, -- FK a [sgspi].[causal_excepcion_transparencia]([cet_codigo]) (NULL cuando es PUBLICA o NO_CLASIFICADA)
    aci_alcance_excepcion               NVARCHAR (15)      NULL, -- 'PARCIAL', 'TOTAL' (NULL cuando es PUBLICA o NO_CLASIFICADA)
    aci_fundamento_constitucional_legal NVARCHAR (150)     NULL, -- Ej: 'Ley 1712 de 2014' (NULL cuando no aplica reserva)
    aci_fundamento_juridico_excepcion   NVARCHAR (150)     NULL, -- Norma o disposición específica de reserva (NULL cuando no aplica reserva)
    aci_fecha_clasificacion_reserva     DATE               NULL, -- NULL cuando no aplica reserva
    aci_es_reserva_indefinida           BIT                NULL, -- 1=Indefinida, 0=Plazo definido en años, NULL=No aplica reserva (elimina texto libre 'Indefinida')
    aci_anios_plazo_reserva             SMALLINT           NULL, -- Plazo numérico en años (ej. 15 años según Art. 22 Ley 1712/2014; NULL cuando es indefinida o no aplica)
    aci_fecha_vencimiento_reserva       AS                 (CASE WHEN aci_es_reserva_indefinida = 0
                                                                      AND aci_fecha_clasificacion_reserva IS NOT NULL
                                                                      AND aci_anios_plazo_reserva IS NOT NULL THEN DATEADD(YEAR, aci_anios_plazo_reserva, aci_fecha_clasificacion_reserva) ELSE NULL END) PERSISTED,
    -- Protección de Datos Personales (Ley 1581 de 2012 / ISO 27701): Lógica booleana trivalente (BIT NULL en lugar de cadenas mágicas 'No Aplica')
    aci_contiene_datos_personales       BIT                CONSTRAINT DF_aci_contiene_datos_personales DEFAULT 0 NOT NULL, -- 1=Sí, 0=No [AP-17]
    aci_contiene_datos_menores          BIT                NULL, -- 1=Sí, 0=No, NULL=No aplica (cuando aci_contiene_datos_personales = 0)
    aci_categoria_dato_personal         NVARCHAR (20)      NULL, -- 'PRIVADOS', 'SEMIPRIVADOS', 'PUBLICOS', 'SENSIBLES' (NULL cuando aci_contiene_datos_personales = 0)
    aci_finalidad_recoleccion_pii       NVARCHAR (500)     NULL, -- NULL cuando aci_contiene_datos_personales = 0
    aci_existe_autorizacion_pii         BIT                NULL, -- 1=Sí, 0=No, NULL=No aplica (cuando aci_contiene_datos_personales = 0)
    -- Valoración CID almacenada como entero (1=BAJA, 2=MEDIA, 3=ALTA)
    aci_valor_confidencialidad          TINYINT            NOT NULL,
    aci_valor_integridad                TINYINT            NOT NULL,
    aci_valor_disponibilidad            TINYINT            NOT NULL,
    -- Columnas calculadas PERSISTED #5: Etiquetas CID unificadas ('ALTA'/'MEDIA'/'BAJA'), Puntaje y Nivel de Criticidad
    aci_nivel_confidencialidad          AS                 (CASE aci_valor_confidencialidad WHEN 3 THEN N'ALTA' WHEN 2 THEN N'MEDIA' ELSE N'BAJA' END) PERSISTED,
    aci_nivel_integridad                AS                 (CASE aci_valor_integridad WHEN 3 THEN N'ALTA' WHEN 2 THEN N'MEDIA' ELSE N'BAJA' END) PERSISTED,
    aci_nivel_disponibilidad            AS                 (CASE aci_valor_disponibilidad WHEN 3 THEN N'ALTA' WHEN 2 THEN N'MEDIA' ELSE N'BAJA' END) PERSISTED,
    aci_puntaje_criticidad              AS                 (CAST (aci_valor_confidencialidad + aci_valor_integridad + aci_valor_disponibilidad AS TINYINT)) PERSISTED,
    aci_nivel_criticidad                AS                 (CASE WHEN (aci_valor_confidencialidad + aci_valor_integridad + aci_valor_disponibilidad) >= 7 THEN N'ALTA' WHEN (aci_valor_confidencialidad + aci_valor_integridad + aci_valor_disponibilidad) >= 5 THEN N'MEDIA' ELSE N'BAJA' END) PERSISTED,
    -- Infraestructura Crítica Cibernética (ICC)
    aci_supera_umbral_social_icc        BIT                CONSTRAINT DF_aci_supera_umbral_social_icc DEFAULT 0 NOT NULL, -- > 250.000 personas [AP-17]
    aci_supera_umbral_economico_icc     BIT                CONSTRAINT DF_aci_supera_umbral_economico_icc DEFAULT 0 NOT NULL, -- > $464.619.736 COP [AP-17]
    aci_supera_umbral_ambiental_icc     BIT                CONSTRAINT DF_aci_supera_umbral_ambiental_icc DEFAULT 0 NOT NULL, -- >= 3 años en recuperación [AP-17]
    aci_es_infraestructura_critica_icc  AS                 (CASE WHEN aci_supera_umbral_social_icc = 1
                                                                      OR aci_supera_umbral_economico_icc = 1
                                                                      OR aci_supera_umbral_ambiental_icc = 1 THEN CAST (1 AS BIT) ELSE CAST (0 AS BIT) END) PERSISTED, -- [AP-18] PERSISTED (indexable y sin recálculo)
    -- Control de ciclo de vida y auditoría (Apuntando a [dbo].[persona])
    efc_dominio                         AS                 (CONVERT (NVARCHAR (10), N'ACI')) PERSISTED, -- [AP-05] Dominio constante para la FK compuesta hacia el catálogo de estados
    aci_estado_registro                 NVARCHAR (30)      CONSTRAINT DF_aci_estado_registro DEFAULT N'BORRADOR' NOT NULL, -- [AP-04] El INSERT solo puede iniciar en el estado inicial del flujo
    per_codigo_creador                  INT                NOT NULL, -- FK a [dbo].[persona]([per_codigo])
    per_codigo_aprobador                INT                NULL, -- FK a [dbo].[persona]([per_codigo])
    aci_fecha_creacion                  DATETIMEOFFSET (0) CONSTRAINT DF_aci_fecha_creacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12]
    aci_fecha_actualizacion             DATETIMEOFFSET (0) CONSTRAINT DF_aci_fecha_actualizacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12]
    aci_esta_activo                     BIT                CONSTRAINT DF_aci_esta_activo DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
    aci_version                         ROWVERSION         NOT NULL, -- [AP-24] Control de concurrencia optimista
    CONSTRAINT PK_aci_activo_informacion PRIMARY KEY CLUSTERED (aci_codigo),
    CONSTRAINT UQ_aci_codigo_inventario UNIQUE (aci_codigo_inventario),
    CONSTRAINT UQ_aci_codigo_transversal UNIQUE (aci_codigo, aci_es_transversal_sedes), -- [AP-06] destino de FK_ais_activo_no_transversal
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
    -- [AP-23] Ley 1712 de 2014, art. 22: la reserva no es indefinida ni supera 15 años (la CLASIFICADA, art. 18, no tiene ese límite)
    CONSTRAINT CK_aci_reserva_plazo_legal CHECK (aci_clasificacion_transparencia <> N'RESERVADA'
                                                 OR (ISNULL(aci_es_reserva_indefinida, 0) = 0
                                                     AND ISNULL(aci_anios_plazo_reserva, 0) <= 15)),
    -- RN-DOC-03 (Unificada en Supertipo): Coherencia del Índice de Información Clasificada y Reservada (Ley 1712 de 2014 / Decreto 103 de 2015) con plazos tipados
    CONSTRAINT CK_aci_coherencia_indice_reserva CHECK (aci_estado_registro = N'BORRADOR'
                                                       OR (aci_clasificacion_transparencia IN (N'CLASIFICADA', N'RESERVADA')
                                                           AND cet_codigo IS NOT NULL
                                                           AND aci_alcance_excepcion IS NOT NULL
                                                           AND LEN(TRIM(ISNULL(aci_fundamento_constitucional_legal, N''))) > 0 -- el Índice exige ambos fundamentos
                                                           AND LEN(TRIM(ISNULL(aci_fundamento_juridico_excepcion, N''))) > 0
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
    -- [AP-15] Segregación de funciones: el aprobador no puede ser el creador (la firma la escribe TR_aci_integridad_y_actualizacion)
    CONSTRAINT CK_aci_sod_aprobador CHECK (per_codigo_aprobador IS NULL
                                           OR per_codigo_aprobador <> per_codigo_creador)
);

CREATE NONCLUSTERED INDEX IX_aci_tac_codigo
    ON sgspi.activo_informacion(tac_codigo)
    INCLUDE(aci_estado_registro, aci_nivel_criticidad);

CREATE NONCLUSTERED INDEX IX_aci_uaa_codigo
    ON sgspi.activo_informacion(uaa_codigo);

CREATE NONCLUSTERED INDEX IX_aci_esp_codigo
    ON sgspi.activo_informacion(esp_codigo);

CREATE NONCLUSTERED INDEX IX_aci_cet_codigo
    ON sgspi.activo_informacion(cet_codigo);

CREATE NONCLUSTERED INDEX IX_aci_per_codigo_creador
    ON sgspi.activo_informacion(per_codigo_creador);

CREATE NONCLUSTERED INDEX IX_aci_per_codigo_aprobador
    ON sgspi.activo_informacion(per_codigo_aprobador);

-- 4.4 [aip], [ais], [air] Tablas Asociativas N:M Unificadas de Activos de Información (Compartidas por el Supertipo y todos sus Subtipos)
CREATE TABLE sgspi.activo_informacion_proceso_institucional (
    aci_codigo      INT NOT NULL, -- FK a [sgspi].[activo_informacion]([aci_codigo])
    pri_codigo      INT NOT NULL, -- FK a [sgspi].[proceso_institucional]([pri_codigo])
    aip_esta_activo BIT CONSTRAINT DF_aip_esta_activo DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
    CONSTRAINT PK_aip_activo_informacion_proceso_institucional PRIMARY KEY CLUSTERED (aci_codigo, pri_codigo),
    CONSTRAINT FK_aip_activo_informacion FOREIGN KEY (aci_codigo) REFERENCES sgspi.activo_informacion (aci_codigo),
    CONSTRAINT FK_aip_proceso_institucional FOREIGN KEY (pri_codigo) REFERENCES sgspi.proceso_institucional (pri_codigo)
);

CREATE NONCLUSTERED INDEX IX_aip_pri_codigo
    ON sgspi.activo_informacion_proceso_institucional(pri_codigo);

CREATE TABLE sgspi.activo_informacion_sede (
    aci_codigo      INT NOT NULL, -- FK a [sgspi].[activo_informacion]([aci_codigo])
    sus_codigo      INT NOT NULL, -- FK a [dbo].[sub_sede]([sus_codigo]) (contiene [sed_codigo] hacia [dbo].[sede])
    ais_esta_activo BIT CONSTRAINT DF_ais_esta_activo DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
    aci_es_transversal_sedes AS (CASE WHEN ais_esta_activo = 1 THEN CONVERT (BIT, 0) END) PERSISTED, -- [AP-06] una sede activa exige un activo no transversal; inactiva = NULL, la FK no la valida
    CONSTRAINT PK_ais_activo_informacion_sede PRIMARY KEY CLUSTERED (aci_codigo, sus_codigo),
    CONSTRAINT FK_ais_activo_informacion FOREIGN KEY (aci_codigo) REFERENCES sgspi.activo_informacion (aci_codigo),
    CONSTRAINT FK_ais_activo_no_transversal FOREIGN KEY (aci_codigo, aci_es_transversal_sedes) REFERENCES sgspi.activo_informacion (aci_codigo, aci_es_transversal_sedes), -- [AP-06]
    CONSTRAINT FK_ais_dbo_sub_sede FOREIGN KEY (sus_codigo) REFERENCES dbo.sub_sede (sus_codigo)
);

CREATE NONCLUSTERED INDEX IX_ais_sus_codigo
    ON sgspi.activo_informacion_sede(sus_codigo);

CREATE TABLE sgspi.activo_informacion_responsable (
    aci_codigo               INT           NOT NULL, -- FK a [sgspi].[activo_informacion]([aci_codigo])
    car_codigo               INT           NOT NULL, -- FK a [dbo].[cargo]([car_codigo]): Cargo institucional responsable (ISO 27001 / Ley 594)
    uaa_codigo               INT           NOT NULL, -- FK a [dbo].[uaa]([uaa_codigo]): Dependencia del cargo
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
    ON sgspi.activo_informacion_responsable(car_codigo)
    INCLUDE(air_esta_activo); -- [AP-18] aci_codigo y air_tipo_responsabilidad ya son parte de la clave clustered

CREATE NONCLUSTERED INDEX IX_air_uaa_codigo
    ON sgspi.activo_informacion_responsable(uaa_codigo)
    INCLUDE(air_esta_activo); -- [AP-18] aci_codigo ya es parte de la clave clustered

-- D3: un solo propietario activo por activo; los demás responsables son custodios (TR_aci lo exige para aprobar)
CREATE UNIQUE NONCLUSTERED INDEX UX_air_propietario_activo
    ON sgspi.activo_informacion_responsable(aci_codigo) WHERE air_tipo_responsabilidad = N'PROPIETARIO'
                                                              AND air_esta_activo = 1;

-- 4.5 [sif] y [msi] Ficha Técnica de Sistemas de Información y sus Módulos (Los 17 Sistemas USCO)
CREATE TABLE sgspi.sistema_informacion_ficha (
    sif_codigo               INT             IDENTITY (1, 1) NOT NULL,
    aci_codigo               INT             NULL, -- FK a [sgspi].[activo_informacion]([aci_codigo])
    sif_nombre_sistema       NVARCHAR (150)  NOT NULL,
    sif_modalidad_desarrollo NVARCHAR (50)   NOT NULL, -- [AP-08] 'PROPIO', 'PROPIO_EN_DESARROLLO', 'CODIGO_ABIERTO_ADAPTADO', 'COMERCIAL_TERCERO'
    sif_fabricante_proveedor NVARCHAR (150)  NULL,
    sif_descripcion_general  NVARCHAR (1000) NOT NULL,
    sif_esta_activo          BIT             CONSTRAINT DF_sif_esta_activo DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
    CONSTRAINT PK_sif_sistema_informacion_ficha PRIMARY KEY CLUSTERED (sif_codigo),
    CONSTRAINT UQ_sif_nombre_sistema UNIQUE (sif_nombre_sistema),
    CONSTRAINT FK_sif_activo_informacion FOREIGN KEY (aci_codigo) REFERENCES sgspi.activo_informacion (aci_codigo),
    CONSTRAINT CK_sif_modalidad_desarrollo CHECK (sif_modalidad_desarrollo IN (N'PROPIO', N'PROPIO_EN_DESARROLLO', N'CODIGO_ABIERTO_ADAPTADO', N'COMERCIAL_TERCERO')) -- [AP-08]
);

-- Índice único filtrado (SQL Server 2019) para relación 1:0..1 sobre columna NULL sin bloquear múltiples NULL
CREATE UNIQUE NONCLUSTERED INDEX UX_sif_aci_codigo
    ON sgspi.sistema_informacion_ficha(aci_codigo) WHERE aci_codigo IS NOT NULL;

CREATE TABLE sgspi.modulo_sistema_informacion (
    msi_codigo            INT            IDENTITY (1, 1) NOT NULL,
    sif_codigo            INT            NOT NULL, -- FK a [sgspi].[sistema_informacion_ficha]([sif_codigo])
    msi_nombre_modulo     NVARCHAR (200) NOT NULL,
    msi_usuarios_objetivo NVARCHAR (150) NULL,
    msi_esta_activo       BIT            CONSTRAINT DF_msi_esta_activo DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
    CONSTRAINT PK_msi_modulo_sistema_informacion PRIMARY KEY CLUSTERED (msi_codigo),
    CONSTRAINT UQ_msi_sistema_nombre UNIQUE (sif_codigo, msi_nombre_modulo), -- [AP-14] Clave natural; además cubre las búsquedas por sif_codigo
    CONSTRAINT FK_msi_sistema_informacion FOREIGN KEY (sif_codigo) REFERENCES sgspi.sistema_informacion_ficha (sif_codigo)
);


GO
-- [AP-18] Se elimina IX_msi_sif_codigo: redundante con UQ_msi_sistema_nombre (misma columna líder)
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
/*==================================================================================================
                                                    4B. DOMINIO DE ACTIVOS DE LA INFORMACIÓN DOCUMENTAL Y ARCHIVÍSTICA (SUBTIPO DE [aci]: ES-GSPI-MR-04)
                                                    Patrón Supertipo/Subtipo (Herencia de Tabla 1:1): Hereda valoración CID, criticidad, privacidad PII,
                                                    ley de transparencia, umbrales ICC, estados, auditoría, procesos ([aip]) y responsables ([air])
                                                    directamente de [sgspi].[activo_informacion], almacenando aquí solo metadatos archivísticos (Ley 594/2000).
                                                    ==================================================================================================*/
-- 4B.1 [sdo] Catálogo Maestro de Series Documentales del CCD/TRD (39 Series: COD5 = 1..39)
CREATE TABLE sgspi.serie_documental_catalogo (
    sdo_codigo       SMALLINT       IDENTITY (1, 1) NOT NULL,
    sdo_numero_ccd   SMALLINT       NOT NULL, -- COD5: 1=ACCIONES CONSTITUCIONALES .. 39=RESOLUCIONES
    sdo_nombre_serie NVARCHAR (150) NOT NULL,
    sdo_esta_activa  BIT            CONSTRAINT DF_sdo_esta_activa DEFAULT 1 NOT NULL, -- [AP-17]
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
    upc_nodo_padre           AS             (NULLIF (upc_nodo_jerarquico.GetAncestor(1), hierarchyid::GetRoot())) PERSISTED, -- Padre directo determinístico (NULL en nivel 1)
    upc_nivel_jerarquico     AS             (upc_nodo_jerarquico.GetLevel()) PERSISTED, -- Nivel calculado automáticamente por el motor (1=Sección, 2=Subsección, 3..N=Subdivisiones)
    upc_codigo_archivistico  NVARCHAR (50)  NULL, -- Código documental TRD explícito desacoplado de HIERARCHYID para nodos intermedios (ej. '/1/1.1/' -> '1.2')
    upc_prefijo_archivistico AS             (COALESCE (NULLIF (TRIM(upc_codigo_archivistico), N''), CONVERT (NVARCHAR (50), REPLACE(REPLACE(TRIM(N'/' FROM upc_nodo_jerarquico.ToString()), N'.', N'-'), N'/', N'.')))) PERSISTED, -- Prefijo CCD efectivo (ej. '1', '1.1', '1.1-1', '5.1.1.2')
    uaa_codigo               INT            NULL, -- FK a [dbo].[uaa]([uaa_codigo]): Equivalencia organizacional en academia3000
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
    ON sgspi.unidad_productora_cuadro_clasificacion_documental(upc_nivel_jerarquico, upc_nodo_jerarquico)
    INCLUDE(upc_prefijo_archivistico, upc_nombre_unidad);

CREATE NONCLUSTERED INDEX IX_upc_nodo_padre
    ON sgspi.unidad_productora_cuadro_clasificacion_documental(upc_nodo_padre)
    INCLUDE(upc_nivel_jerarquico, upc_prefijo_archivistico, upc_nombre_unidad);

CREATE NONCLUSTERED INDEX IX_upc_uaa_codigo
    ON sgspi.unidad_productora_cuadro_clasificacion_documental(uaa_codigo);

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
    ado_codigo                        INT                NOT NULL, -- [AP-10] PK compartida = [sgspi].[activo_informacion]([aci_codigo])
    pev_codigo                        SMALLINT           NOT NULL, -- FK a [sgspi].[periodo_vigencia]([pev_codigo])
    sdo_codigo                        SMALLINT           NOT NULL, -- FK a [sgspi].[serie_documental_catalogo]([sdo_codigo])
    sbd_codigo                        INT                NULL, -- FK nullable a [sgspi].[subserie_documental_catalogo]([sbd_codigo]) (NULL si la serie no tiene subserie)
    pdc_codigo                        SMALLINT           NOT NULL, -- FK a [sgspi].[periodicidad_catalogo]([pdc_codigo])
    ado_fecha_ingreso_tabla_retencion DATE               NULL,
    ado_fecha_ingreso_archivo         DATE               NULL,
    epc_codigo                        SMALLINT           NOT NULL, -- FK a [sgspi].[estado_publicacion_catalogo]([epc_codigo])
    ado_lugar_consulta_ubicacion      NVARCHAR (255)     NOT NULL, -- URL portal de transparencia o nombre de dependencia/archivo
    per_codigo_revisor_archivo        INT                NULL, -- FK a [dbo].[persona]([per_codigo]): Aval específico Gestión Documental / Secretaría General
    ado_fecha_creacion                DATETIMEOFFSET (0) CONSTRAINT DF_ado_fecha_creacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17]
    ado_fecha_actualizacion           DATETIMEOFFSET (0) CONSTRAINT DF_ado_fecha_actualizacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-11] La mantiene TR_ado_integridad_y_actualizacion
    ado_esta_activo                   BIT                CONSTRAINT DF_ado_esta_activo DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
    ado_version                       ROWVERSION         NOT NULL, -- [AP-24] Control de concurrencia optimista
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
    ON sgspi.activo_documental(pev_codigo, sdo_codigo, sbd_codigo); -- [AP-18] Se quita el INCLUDE de la columna eliminada (ado_codigo ya es clave clustered)

CREATE NONCLUSTERED INDEX IX_ado_sdo_sbd_codigo
    ON sgspi.activo_documental(sdo_codigo, sbd_codigo); -- [AP-18] Reemplaza IX_ado_sbd_codigo: sirve a FK_ado_serie_documental y FK_ado_subserie_documental

CREATE NONCLUSTERED INDEX IX_ado_pdc_codigo
    ON sgspi.activo_documental(pdc_codigo);

CREATE NONCLUSTERED INDEX IX_ado_epc_codigo
    ON sgspi.activo_documental(epc_codigo);

CREATE NONCLUSTERED INDEX IX_ado_per_codigo_revisor_archivo
    ON sgspi.activo_documental(per_codigo_revisor_archivo);

-- 4B.6 [ads], [adm], [adi], [adf] Tablas Puente N:M de Atributos Atómicos de Activos Documentales hacia Catálogos Extensibles
CREATE TABLE sgspi.activo_documental_soporte_registro (
    ado_codigo      INT      NOT NULL, -- FK a [sgspi].[activo_documental]([ado_codigo])
    src_codigo      SMALLINT NOT NULL, -- FK a [sgspi].[soporte_registro_catalogo]([src_codigo])
    ads_esta_activo BIT      CONSTRAINT DF_ads_esta_activo DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
    CONSTRAINT PK_ads_activo_documental_soporte_registro PRIMARY KEY CLUSTERED (ado_codigo, src_codigo),
    CONSTRAINT FK_ads_activo_documental FOREIGN KEY (ado_codigo) REFERENCES sgspi.activo_documental (ado_codigo),
    CONSTRAINT FK_ads_soporte_registro_catalogo FOREIGN KEY (src_codigo) REFERENCES sgspi.soporte_registro_catalogo (src_codigo)
);

CREATE NONCLUSTERED INDEX IX_ads_src_codigo
    ON sgspi.activo_documental_soporte_registro(src_codigo); -- [AP-18] Sin INCLUDE: ado_codigo ya es clave clustered

CREATE TABLE sgspi.activo_documental_medio_conservacion (
    ado_codigo      INT      NOT NULL, -- FK a [sgspi].[activo_documental]([ado_codigo])
    mcc_codigo      SMALLINT NOT NULL, -- FK a [sgspi].[medio_conservacion_catalogo]([mcc_codigo])
    adm_esta_activo BIT      CONSTRAINT DF_adm_esta_activo DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
    CONSTRAINT PK_adm_activo_documental_medio_conservacion PRIMARY KEY CLUSTERED (ado_codigo, mcc_codigo),
    CONSTRAINT FK_adm_activo_documental FOREIGN KEY (ado_codigo) REFERENCES sgspi.activo_documental (ado_codigo),
    CONSTRAINT FK_adm_medio_conservacion_catalogo FOREIGN KEY (mcc_codigo) REFERENCES sgspi.medio_conservacion_catalogo (mcc_codigo)
);

CREATE NONCLUSTERED INDEX IX_adm_mcc_codigo
    ON sgspi.activo_documental_medio_conservacion(mcc_codigo); -- [AP-18] Sin INCLUDE: ado_codigo ya es clave clustered

CREATE TABLE sgspi.activo_documental_idioma (
    ado_codigo      INT      NOT NULL, -- FK a [sgspi].[activo_documental]([ado_codigo])
    idi_codigo      SMALLINT NOT NULL, -- FK a [sgspi].[idioma_catalogo]([idi_codigo])
    adi_esta_activo BIT      CONSTRAINT DF_adi_esta_activo DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
    CONSTRAINT PK_adi_activo_documental_idioma PRIMARY KEY CLUSTERED (ado_codigo, idi_codigo),
    CONSTRAINT FK_adi_activo_documental FOREIGN KEY (ado_codigo) REFERENCES sgspi.activo_documental (ado_codigo),
    CONSTRAINT FK_adi_idioma_catalogo FOREIGN KEY (idi_codigo) REFERENCES sgspi.idioma_catalogo (idi_codigo)
);

CREATE NONCLUSTERED INDEX IX_adi_idi_codigo
    ON sgspi.activo_documental_idioma(idi_codigo); -- [AP-18] Sin INCLUDE: ado_codigo ya es clave clustered

-- [AP-08] [adf] Formatos de archivo del activo documental (reemplaza el texto libre formato en texto libre)
CREATE TABLE sgspi.activo_documental_formato_archivo (
    ado_codigo      INT      NOT NULL, -- FK a [sgspi].[activo_documental]([ado_codigo])
    fac_codigo      SMALLINT NOT NULL, -- FK a [sgspi].[formato_archivo_catalogo]([fac_codigo])
    adf_esta_activo BIT      CONSTRAINT DF_adf_esta_activo DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
    CONSTRAINT PK_adf_activo_documental_formato_archivo PRIMARY KEY CLUSTERED (ado_codigo, fac_codigo),
    CONSTRAINT FK_adf_activo_documental FOREIGN KEY (ado_codigo) REFERENCES sgspi.activo_documental (ado_codigo),
    CONSTRAINT FK_adf_formato_archivo_catalogo FOREIGN KEY (fac_codigo) REFERENCES sgspi.formato_archivo_catalogo (fac_codigo)
);

CREATE NONCLUSTERED INDEX IX_adf_fac_codigo
    ON sgspi.activo_documental_formato_archivo(fac_codigo); -- [AP-18] Sin INCLUDE: ado_codigo ya es clave clustered

-- 4B.7 [adu] Asignación N:M Activo Documental <-> Unidad Productora del CCD/TRD (Modela las 240 filas de desglose TRD sin cadenas multivaluadas)
CREATE TABLE sgspi.activo_documental_unidad_productora (
    ado_codigo      INT NOT NULL, -- FK a [sgspi].[activo_documental]([ado_codigo])
    upc_codigo      INT NOT NULL, -- FK a [sgspi].[unidad_productora_cuadro_clasificacion_documental]([upc_codigo]) (Unidad más específica donde se produce la serie/subserie)
    adu_esta_activo BIT CONSTRAINT DF_adu_esta_activo DEFAULT 1 NOT NULL, -- [AP-17]
    CONSTRAINT PK_adu_activo_documental_unidad_productora PRIMARY KEY CLUSTERED (ado_codigo, upc_codigo),
    CONSTRAINT FK_adu_activo_documental FOREIGN KEY (ado_codigo) REFERENCES sgspi.activo_documental (ado_codigo),
    CONSTRAINT FK_adu_unidad_productora_cuadro_clasificacion_documental FOREIGN KEY (upc_codigo) REFERENCES sgspi.unidad_productora_cuadro_clasificacion_documental (upc_codigo)
);

CREATE NONCLUSTERED INDEX IX_adu_upc_codigo
    ON sgspi.activo_documental_unidad_productora(upc_codigo)
    INCLUDE(adu_esta_activo);


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


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
    epr_esta_activa           BIT            CONSTRAINT DF_epr_esta_activa DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
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
    eim_esta_activa                BIT             CONSTRAINT DF_eim_esta_activa DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
    CONSTRAINT PK_eim_escala_impacto PRIMARY KEY CLUSTERED (eim_codigo),
    CONSTRAINT CK_eim_rango CHECK (eim_codigo BETWEEN 1 AND 5)
);

-- [AP-09] Catálogo de zonas de riesgo: reemplaza mvr_codigo_zona (código) + mvr_nivel_valoracion (nombre), dependencia transitiva
CREATE TABLE sgspi.zona_riesgo_catalogo (
    zrc_codigo       CHAR (1)      NOT NULL, -- 'B' (Bajo), 'M' (Moderado), 'A' (Alto), 'E' (Extremo)
    zrc_nombre_nivel NVARCHAR (30) NOT NULL, -- 'Riesgo Inferior', 'Riesgo Moderado', 'Riesgo Alto', 'Riesgo Extremo'
    zrc_orden        TINYINT       NOT NULL, -- 1 (menor severidad) .. 4 (mayor severidad)
    zrc_esta_activa  BIT           CONSTRAINT DF_zrc_esta_activa DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
    CONSTRAINT PK_zrc_zona_riesgo_catalogo PRIMARY KEY CLUSTERED (zrc_codigo),
    CONSTRAINT UQ_zrc_nombre_nivel UNIQUE (zrc_nombre_nivel),
    CONSTRAINT UQ_zrc_orden UNIQUE (zrc_orden)
);


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [AP-09] Semilla de zonas de riesgo (bloque propio: la tabla ya existe en el lote anterior)
INSERT  INTO sgspi.zona_riesgo_catalogo (
    zrc_codigo,
    zrc_nombre_nivel,
    zrc_orden
)
VALUES                                  ('B', N'Riesgo Inferior', 1),
                                        ('M', N'Riesgo Moderado', 2),
                                        ('A', N'Riesgo Alto', 3),
                                        ('E', N'Riesgo Extremo', 4);


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
CREATE TABLE sgspi.matriz_valoracion_riesgo (
    epr_codigo                            TINYINT        NOT NULL, -- FK a [sgspi].[escala_probabilidad]([epr_codigo])
    eim_codigo                            TINYINT        NOT NULL, -- FK a [sgspi].[escala_impacto]([eim_codigo])
    -- [AP-09] Columna calculada PERSISTED: 'A1'..'E5' deriva de probabilidad (5=A..1=E) e impacto
    mvr_codigo_posicion                   AS             (CONVERT (CHAR (2), CONCAT(CHAR(70 - epr_codigo), eim_codigo))) PERSISTED NOT NULL,
    zrc_codigo                            CHAR (1)       NOT NULL, -- [AP-09] FK a [sgspi].[zona_riesgo_catalogo]([zrc_codigo]) (antes mvr_codigo_zona + mvr_nivel_valoracion)
    mvr_directriz_tratamiento_riesgo      NVARCHAR (255) NOT NULL,
    mvr_directriz_tratamiento_oportunidad NVARCHAR (255) NOT NULL,
    mvr_requiere_aprobacion_comite        BIT            CONSTRAINT DF_mvr_requiere_aprobacion_comite DEFAULT 0 NOT NULL, -- [AP-17]
    mvr_esta_activa                       BIT            CONSTRAINT DF_mvr_esta_activa DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
    CONSTRAINT PK_mvr_matriz_valoracion_riesgo PRIMARY KEY CLUSTERED (epr_codigo, eim_codigo),
    CONSTRAINT UQ_mvr_codigo_posicion UNIQUE (mvr_codigo_posicion),
    CONSTRAINT FK_mvr_escala_probabilidad FOREIGN KEY (epr_codigo) REFERENCES sgspi.escala_probabilidad (epr_codigo),
    CONSTRAINT FK_mvr_escala_impacto FOREIGN KEY (eim_codigo) REFERENCES sgspi.escala_impacto (eim_codigo),
    CONSTRAINT FK_mvr_zona_riesgo FOREIGN KEY (zrc_codigo) REFERENCES sgspi.zona_riesgo_catalogo (zrc_codigo) -- [AP-09] reemplaza CK_mvr_codigo_zona
);

CREATE NONCLUSTERED INDEX IX_mvr_eim_codigo
    ON sgspi.matriz_valoracion_riesgo(eim_codigo);

CREATE NONCLUSTERED INDEX IX_mvr_zrc_codigo -- [AP-18] soporte de la FK a zrc
    ON sgspi.matriz_valoracion_riesgo(zrc_codigo);

-- 5.2 [eia] Escenarios de Incertidumbre sobre Activos (Riesgos RA-XX y Oportunidades OA-XX)
CREATE TABLE sgspi.evento_incertidumbre_activo (
    eia_codigo                   INT                IDENTITY (1, 1) NOT NULL,
    pev_codigo                   SMALLINT           NOT NULL, -- FK a [sgspi].[periodo_vigencia]([pev_codigo])
    eia_numero_evento            SMALLINT           NOT NULL, -- [AP-09] Consecutivo por vigencia y naturaleza (1..999)
    eia_identificador_evento     AS                 (CONVERT (NVARCHAR (15), CONCAT(CASE eia_naturaleza_evento WHEN N'RIESGO' THEN N'RA-' ELSE N'OA-' END, RIGHT(CONCAT(N'00', eia_numero_evento), CASE WHEN eia_numero_evento < 100 THEN 2 ELSE 3 END)))) PERSISTED, -- [AP-09] 'RA-01'..'RA-999', 'OA-01'..'OA-999': se calcula, no se digita
    eia_naturaleza_evento        NVARCHAR (15)      NOT NULL, -- 'RIESGO' (-), 'OPORTUNIDAD' (+)
    pri_codigo                   INT                NOT NULL, -- FK a [sgspi].[proceso_institucional]([pri_codigo])
    aci_codigo_primario          INT                NOT NULL, -- FK a [sgspi].[activo_informacion]([aci_codigo])
    aci_codigo_soporte           INT                NOT NULL, -- FK a [sgspi].[activo_informacion]([aci_codigo])
    -- [AP-08] Componente afectado vía catálogo de tipos de activo (solo categorías de nivel 1: Información, Software, Servicio, Infraestructura, Hardware)
    tac_codigo_componente        SMALLINT           NOT NULL, -- FK a [sgspi].[tipo_activo_catalogo]([tac_codigo])
    tac_nivel_componente         AS                 (CONVERT (TINYINT, 1)) PERSISTED, -- [AP-08] columna constante: fuerza nivel 1 de la taxonomía en la FK compuesta
    eia_fuente_generadora        NVARCHAR (255)     NOT NULL,
    eia_controles_existentes     NVARCHAR (1000)    NULL,
    eia_condicion_vulnerabilidad NVARCHAR (1000)    NOT NULL,
    eia_efecto_consecuencia      NVARCHAR (1000)    NOT NULL,
    eia_escenario_operacional    NVARCHAR (255)     NOT NULL,
    -- Valoración Inherente / Actual
    epr_codigo_inherente         TINYINT            NOT NULL,
    eim_codigo_inherente         TINYINT            NOT NULL,
    -- Máquina de Estados Principal y Firmas sobre [dbo].[persona]
    eia_estado_registro          NVARCHAR (30)      CONSTRAINT DF_eia_estado_registro DEFAULT N'BORRADOR' NOT NULL, -- [AP-17]
    efc_dominio                  AS                 (CONVERT (NVARCHAR (10), N'EIA')) PERSISTED, -- [AP-05] dominio constante para la FK al catálogo de estados
    per_codigo_creador           INT                NOT NULL, -- FK a [dbo].[persona]([per_codigo])
    per_codigo_validador_lider   INT                NULL, -- FK a [dbo].[persona]([per_codigo])
    per_codigo_revisor_sgspi     INT                NULL, -- FK a [dbo].[persona]([per_codigo])
    per_codigo_aprobador_comite  INT                NULL, -- FK a [dbo].[persona]([per_codigo])
    eia_fecha_creacion           DATETIMEOFFSET (0) CONSTRAINT DF_eia_fecha_creacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17]
    eia_fecha_actualizacion      DATETIMEOFFSET (0) CONSTRAINT DF_eia_fecha_actualizacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-11] La mantiene TR_eia_integridad_y_actualizacion
    eia_esta_activo              BIT                CONSTRAINT DF_eia_esta_activo DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
    eia_version                  ROWVERSION         NOT NULL, -- [AP-24] Control de concurrencia optimista
    CONSTRAINT PK_eia_evento_incertidumbre_activo PRIMARY KEY CLUSTERED (eia_codigo),
    CONSTRAINT UQ_eia_vigencia_naturaleza_numero UNIQUE (pev_codigo, eia_naturaleza_evento, eia_numero_evento), -- [AP-09] el identificador es función de (naturaleza, número)
    CONSTRAINT UQ_eia_codigo_naturaleza UNIQUE (eia_codigo, eia_naturaleza_evento), -- [AP-06] destino de la FK compuesta de plt
    CONSTRAINT FK_eia_periodo_vigencia FOREIGN KEY (pev_codigo) REFERENCES sgspi.periodo_vigencia (pev_codigo),
    CONSTRAINT FK_eia_proceso_institucional FOREIGN KEY (pri_codigo) REFERENCES sgspi.proceso_institucional (pri_codigo),
    CONSTRAINT FK_eia_activo_primario FOREIGN KEY (aci_codigo_primario) REFERENCES sgspi.activo_informacion (aci_codigo),
    CONSTRAINT FK_eia_activo_soporte FOREIGN KEY (aci_codigo_soporte) REFERENCES sgspi.activo_informacion (aci_codigo),
    CONSTRAINT FK_eia_activo_proceso FOREIGN KEY (aci_codigo_primario, pri_codigo) REFERENCES sgspi.activo_informacion_proceso_institucional (aci_codigo, pri_codigo), -- [AP-06] D4: el riesgo está en un proceso que usa su activo primario
    CONSTRAINT FK_eia_tipo_activo_componente FOREIGN KEY (tac_codigo_componente, tac_nivel_componente) REFERENCES sgspi.tipo_activo_catalogo (tac_codigo, tac_nivel_taxonomia), -- [AP-08]
    CONSTRAINT FK_eia_valoracion_inherente FOREIGN KEY (epr_codigo_inherente, eim_codigo_inherente) REFERENCES sgspi.matriz_valoracion_riesgo (epr_codigo, eim_codigo),
    CONSTRAINT FK_eia_estado_flujo FOREIGN KEY (efc_dominio, eia_estado_registro) REFERENCES sgspi.estado_flujo_catalogo (efc_dominio, efc_identificador), -- [AP-05] reemplaza CK_eia_estado_maquina
    CONSTRAINT FK_eia_dbo_persona_creador FOREIGN KEY (per_codigo_creador) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT FK_eia_dbo_persona_validador FOREIGN KEY (per_codigo_validador_lider) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT FK_eia_dbo_persona_revisor FOREIGN KEY (per_codigo_revisor_sgspi) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT FK_eia_dbo_persona_comite FOREIGN KEY (per_codigo_aprobador_comite) REFERENCES dbo.persona (per_codigo),
    -- RN-RSG-01: Exclusión Mutua Riesgo (RA-) vs Oportunidad (OA-); el prefijo y los dígitos los calcula eia_identificador_evento [AP-09]
    CONSTRAINT CK_eia_naturaleza_evento CHECK (eia_naturaleza_evento IN (N'RIESGO', N'OPORTUNIDAD')),
    CONSTRAINT CK_eia_numero_evento CHECK (eia_numero_evento BETWEEN 1 AND 999),
    -- [AP-15] Segregación de funciones ISO 27001 A.5.3: ninguna firma (validador, revisor, comité) puede ser del creador
    CONSTRAINT CK_eia_sod_firmas CHECK ((per_codigo_validador_lider IS NULL
                                         OR per_codigo_validador_lider <> per_codigo_creador)
                                        AND (per_codigo_revisor_sgspi IS NULL
                                             OR per_codigo_revisor_sgspi <> per_codigo_creador)
                                        AND (per_codigo_aprobador_comite IS NULL
                                             OR per_codigo_aprobador_comite <> per_codigo_creador)),
    CONSTRAINT CK_eia_activos_distintos CHECK (aci_codigo_soporte <> aci_codigo_primario)
);

CREATE NONCLUSTERED INDEX IX_eia_pri_codigo
    ON sgspi.evento_incertidumbre_activo(pri_codigo);

CREATE NONCLUSTERED INDEX IX_eia_aci_codigo_primario -- [AP-18] sirve a FK_eia_activo_primario y a FK_eia_activo_proceso (D4)
    ON sgspi.evento_incertidumbre_activo(aci_codigo_primario, pri_codigo);

CREATE NONCLUSTERED INDEX IX_eia_aci_codigo_soporte
    ON sgspi.evento_incertidumbre_activo(aci_codigo_soporte);

CREATE NONCLUSTERED INDEX IX_eia_tac_codigo_componente -- [AP-08] [AP-18] soporte de la FK compuesta a tac
    ON sgspi.evento_incertidumbre_activo(tac_codigo_componente, tac_nivel_componente);

CREATE NONCLUSTERED INDEX IX_eia_valoracion_inherente
    ON sgspi.evento_incertidumbre_activo(epr_codigo_inherente, eim_codigo_inherente);

CREATE NONCLUSTERED INDEX IX_eia_per_codigo_creador
    ON sgspi.evento_incertidumbre_activo(per_codigo_creador);

CREATE NONCLUSTERED INDEX IX_eia_per_codigo_validador_lider
    ON sgspi.evento_incertidumbre_activo(per_codigo_validador_lider);

CREATE NONCLUSTERED INDEX IX_eia_per_codigo_revisor_sgspi
    ON sgspi.evento_incertidumbre_activo(per_codigo_revisor_sgspi);

CREATE NONCLUSTERED INDEX IX_eia_per_codigo_aprobador_comite
    ON sgspi.evento_incertidumbre_activo(per_codigo_aprobador_comite);

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
    plt_codigo                      INT                IDENTITY (1, 1) NOT NULL,
    eia_codigo                      INT                NOT NULL, -- FK a [sgspi].[evento_incertidumbre_activo]([eia_codigo])
    plt_naturaleza_evento           NVARCHAR (15)      NOT NULL, -- [AP-06] 'RIESGO'/'OPORTUNIDAD': debe coincidir con el evento y con la estrategia (FK compuestas)
    etc_codigo                      SMALLINT           NOT NULL, -- FK a [sgspi].[estrategia_tratamiento_catalogo]([etc_codigo])
    plt_justificacion_estrategia    NVARCHAR (1000)    NOT NULL,
    -- Valoración Residual Esperada (Meta)
    epr_codigo_residual_meta        TINYINT            NOT NULL,
    eim_codigo_residual_meta        TINYINT            NOT NULL,
    plt_fecha_inicio                DATE               NOT NULL,
    plt_fecha_fin                   DATE               NOT NULL,
    plt_recursos_humanos_tecnicos   NVARCHAR (500)     NOT NULL,
    plt_recursos_economicos_desc    NVARCHAR (500)     NOT NULL,
    plt_presupuesto_estimado_cop    DECIMAL (18, 2)    NULL,
    plt_restricciones_limitaciones  NVARCHAR (500)     NULL,
    plt_nombre_indicador_kpi        NVARCHAR (255)     NOT NULL,
    plt_unidad_medida_kpi           NVARCHAR (30)      CONSTRAINT DF_plt_unidad_medida_kpi DEFAULT N'PORCENTAJE' NOT NULL, -- [AP-17] Ej: 'PORCENTAJE', 'CANTIDAD', 'DIAS', 'HORAS'
    plt_meta_indicador_kpi          DECIMAL (10, 2)    NOT NULL,
    plt_valor_alcanzado_kpi         DECIMAL (10, 2)    NULL,
    -- [AP-16] DECIMAL (15, 2) evita desborde (8115) con metas pequeñas y valores alcanzados altos
    plt_porcentaje_cumplimiento_kpi AS                 (CASE WHEN plt_meta_indicador_kpi > 0
                                                                  AND plt_valor_alcanzado_kpi IS NOT NULL THEN CAST (ROUND((plt_valor_alcanzado_kpi / plt_meta_indicador_kpi) * 100.0, 2) AS DECIMAL (15, 2)) ELSE NULL END),
    plt_es_tratamiento_eficaz       BIT                NULL,
    plt_dictamen_eficacia           NVARCHAR (1000)    NULL,
    per_codigo_evaluador            INT                NULL, -- FK a [dbo].[persona]([per_codigo])
    plt_fecha_evaluacion_eficacia   DATETIMEOFFSET (0) NULL, -- [AP-12]
    plt_fecha_creacion              DATETIMEOFFSET (0) CONSTRAINT DF_plt_fecha_creacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17]
    plt_fecha_actualizacion         DATETIMEOFFSET (0) CONSTRAINT DF_plt_fecha_actualizacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17]
    plt_esta_activo                 BIT                CONSTRAINT DF_plt_esta_activo DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
    plt_version                     ROWVERSION         NOT NULL, -- [AP-24] Control de concurrencia optimista
    CONSTRAINT PK_plt_plan_tratamiento PRIMARY KEY CLUSTERED (plt_codigo),
    -- [AP-06] FK compuestas: la naturaleza del plan coincide con la del evento y con la de la estrategia
    CONSTRAINT FK_plt_evento_incertidumbre FOREIGN KEY (eia_codigo, plt_naturaleza_evento) REFERENCES sgspi.evento_incertidumbre_activo (eia_codigo, eia_naturaleza_evento),
    CONSTRAINT FK_plt_estrategia_tratamiento FOREIGN KEY (etc_codigo, plt_naturaleza_evento) REFERENCES sgspi.estrategia_tratamiento_catalogo (etc_codigo, etc_naturaleza_aplicable),
    CONSTRAINT FK_plt_valoracion_meta FOREIGN KEY (epr_codigo_residual_meta, eim_codigo_residual_meta) REFERENCES sgspi.matriz_valoracion_riesgo (epr_codigo, eim_codigo),
    CONSTRAINT FK_plt_dbo_persona_evaluador FOREIGN KEY (per_codigo_evaluador) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_plt_naturaleza_evento CHECK (plt_naturaleza_evento IN (N'RIESGO', N'OPORTUNIDAD')), -- [AP-06]
    -- RN-RSG-06: Validación de cronogramas y métricas numéricas KPI
    CONSTRAINT CK_plt_cronograma CHECK (plt_fecha_fin >= plt_fecha_inicio),
    CONSTRAINT CK_plt_unidad_medida_kpi CHECK (plt_unidad_medida_kpi IN (N'PORCENTAJE', N'CANTIDAD', N'DIAS', N'HORAS')), -- [AP-08] antes texto libre no vacío
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

-- [AP-22] Un solo plan activo por evento: permite crear el plan correcto tras anular uno por error (plt_esta_activo = 0)
CREATE UNIQUE NONCLUSTERED INDEX UX_plt_evento_activo
    ON sgspi.plan_tratamiento(eia_codigo) WHERE plt_esta_activo = 1;

CREATE NONCLUSTERED INDEX IX_plt_etc_codigo
    ON sgspi.plan_tratamiento(etc_codigo, plt_naturaleza_evento); -- [AP-18] cubre la FK compuesta a etc

CREATE NONCLUSTERED INDEX IX_plt_valoracion_residual_meta
    ON sgspi.plan_tratamiento(epr_codigo_residual_meta, eim_codigo_residual_meta);

CREATE NONCLUSTERED INDEX IX_plt_per_codigo_evaluador
    ON sgspi.plan_tratamiento(per_codigo_evaluador);

-- 5.4 [act] y [sga] Desglose de Actividades del Plan de Tratamiento y Seguimiento con Evidencias
CREATE TABLE sgspi.actividad_tratamiento (
    act_codigo                INT                IDENTITY (1, 1) NOT NULL,
    plt_codigo                INT                NOT NULL, -- FK a [sgspi].[plan_tratamiento]([plt_codigo])
    act_numero_orden          SMALLINT           CONSTRAINT DF_act_numero_orden DEFAULT 1 NOT NULL, -- [AP-17]
    act_descripcion_actividad NVARCHAR (500)     NOT NULL,
    car_codigo                INT                NULL, -- FK a [dbo].[cargo]([car_codigo])
    uaa_codigo                INT                NULL, -- FK a [dbo].[uaa]([uaa_codigo])
    act_fecha_compromiso      DATE               NOT NULL,
    act_porcentaje_avance     TINYINT            CONSTRAINT DF_act_porcentaje_avance DEFAULT 0 NOT NULL, -- [AP-17]
    act_estado_actividad      NVARCHAR (30)      CONSTRAINT DF_act_estado_actividad DEFAULT N'PENDIENTE' NOT NULL, -- [AP-05] [AP-17] ampliada de 20 a 30
    efc_dominio               AS                 (CONVERT (NVARCHAR (10), N'ACT')) PERSISTED, -- [AP-05] dominio constante para la FK al catálogo de estados
    act_fecha_creacion        DATETIMEOFFSET (0) CONSTRAINT DF_act_fecha_creacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17]
    act_fecha_actualizacion   DATETIMEOFFSET (0) CONSTRAINT DF_act_fecha_actualizacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17]
    act_esta_activa           BIT                CONSTRAINT DF_act_esta_activa DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
    act_version               ROWVERSION         NOT NULL, -- [AP-24] Control de concurrencia optimista
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
                                               OR act_porcentaje_avance = 100),
    -- Fuera de PENDIENTE la actividad exige cargo y UAA responsables
    CONSTRAINT CK_act_responsable CHECK (act_estado_actividad = N'PENDIENTE'
                                         OR (car_codigo IS NOT NULL
                                             AND uaa_codigo IS NOT NULL))
);

-- [AP-14] IX_act_plt_codigo eliminado: lo cubre UQ_act_plan_orden (plt_codigo es su primera columna)
CREATE NONCLUSTERED INDEX IX_act_car_codigo
    ON sgspi.actividad_tratamiento(car_codigo);

CREATE NONCLUSTERED INDEX IX_act_uaa_codigo
    ON sgspi.actividad_tratamiento(uaa_codigo);

CREATE TABLE sgspi.seguimiento_actividad (
    sga_codigo                       INT                IDENTITY (1, 1) NOT NULL,
    act_codigo                       INT                NOT NULL, -- FK a [sgspi].[actividad_tratamiento]([act_codigo])
    per_codigo                       INT                NOT NULL, -- FK a [dbo].[persona]([per_codigo])
    sga_fecha_registro               DATETIMEOFFSET (0) CONSTRAINT DF_sga_fecha_registro DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17]
    sga_porcentaje_reportado         TINYINT            NOT NULL,
    sga_descripcion_avance           NVARCHAR (1000)    NOT NULL,
    sga_nombre_archivo_evidencia     NVARCHAR (255)     NULL,
    sga_uri_almacenamiento_evidencia NVARCHAR (500)     NULL,
    sga_hash_sha256_evidencia        CHAR (64)          NULL,
    sga_esta_activo                  BIT                CONSTRAINT DF_sga_esta_activo DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
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
    -- [AP-16] Formato del hash SHA-256: 64 caracteres hexadecimales en minúsculas
    CONSTRAINT CK_sga_hash_formato CHECK (sga_hash_sha256_evidencia IS NULL
                                          OR (LEN(sga_hash_sha256_evidencia) = 64
                                              AND sga_hash_sha256_evidencia COLLATE Latin1_General_BIN2 NOT LIKE '%[^0-9a-f]%'))
);

CREATE NONCLUSTERED INDEX IX_sga_act_codigo
    ON sgspi.seguimiento_actividad(act_codigo);

CREATE NONCLUSTERED INDEX IX_sga_per_codigo
    ON sgspi.seguimiento_actividad(per_codigo);

-- 5.5 [enc] y [crn] Catálogo Extensible de Estándares Normativos y Controles de Referencia (ISO/IEC 27001:2022 [93], ISO/IEC 27701:2025 [71], etc.)
CREATE TABLE sgspi.estandar_normativo_catalogo (
    enc_codigo        SMALLINT       IDENTITY (1, 1) NOT NULL,
    enc_identificador NVARCHAR (50)  NOT NULL, -- Ej: 'ISO/IEC 27001:2022', 'ISO/IEC 27701:2025', 'ISO/IEC 27002:2022', 'ISO/IEC 42001:2023'
    enc_familia_norma NVARCHAR (20)  NOT NULL, -- [AP-13] Ej: 'ISO27001', 'ISO27701', 'ISO27002', 'NIST_CSF'; una edición activa por familia
    enc_nombre        NVARCHAR (200) NOT NULL,
    enc_organismo     NVARCHAR (100) NULL, -- Ej: 'ISO/IEC', 'NIST', 'MinTIC'
    enc_anio_edicion  SMALLINT       NULL,
    enc_esta_activo   BIT            CONSTRAINT DF_enc_esta_activo DEFAULT 1 NOT NULL, -- [AP-17]
    CONSTRAINT PK_enc_estandar_normativo_catalogo PRIMARY KEY CLUSTERED (enc_codigo),
    CONSTRAINT UQ_enc_identificador UNIQUE (enc_identificador),
    CONSTRAINT CK_enc_identificador_no_vacio CHECK (LEN(TRIM(enc_identificador)) > 0),
    CONSTRAINT CK_enc_familia_norma_no_vacia CHECK (LEN(TRIM(enc_familia_norma)) > 0) -- [AP-13]
);

-- [AP-13] Una sola edición activa por familia de norma (reemplaza filtros por cadena de edición en vistas)
CREATE UNIQUE NONCLUSTERED INDEX UX_enc_familia_activa
    ON sgspi.estandar_normativo_catalogo(enc_familia_norma) WHERE enc_esta_activo = 1;

-- [AP-07] Se eliminan crn_tipo_control, crn_capacidad_operacional y crn_dominio_seguridad (atributos multivaluados -> aac/cra)
CREATE TABLE sgspi.control_referencia_normativa (
    crn_codigo                SMALLINT        IDENTITY (1, 1) NOT NULL,
    enc_codigo                SMALLINT        NOT NULL, -- FK a [sgspi].[estandar_normativo_catalogo]([enc_codigo])
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
    crn_codigo      SMALLINT NOT NULL, -- FK a [sgspi].[control_referencia_normativa]([crn_codigo])
    aac_codigo      SMALLINT NOT NULL, -- FK a [sgspi].[atributo_control_catalogo]([aac_codigo])
    cra_esta_activo BIT      CONSTRAINT DF_cra_esta_activo DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
    CONSTRAINT PK_cra_control_referencia_normativa_atributo PRIMARY KEY CLUSTERED (crn_codigo, aac_codigo),
    CONSTRAINT FK_cra_control_referencia FOREIGN KEY (crn_codigo) REFERENCES sgspi.control_referencia_normativa (crn_codigo),
    CONSTRAINT FK_cra_atributo_control FOREIGN KEY (aac_codigo) REFERENCES sgspi.atributo_control_catalogo (aac_codigo)
);

CREATE NONCLUSTERED INDEX IX_cra_aac_codigo
    ON sgspi.control_referencia_normativa_atributo(aac_codigo);

-- 5.7 [ptc] Relación N:M Plan de Tratamiento <-> Controles de Referencia Normativa (ISO 27001 e ISO 27701)
CREATE TABLE sgspi.plan_tratamiento_control_referencia_normativa (
    plt_codigo      INT      NOT NULL, -- FK a [sgspi].[plan_tratamiento]([plt_codigo])
    crn_codigo      SMALLINT NOT NULL, -- FK a [sgspi].[control_referencia_normativa]([crn_codigo])
    ptc_esta_activo BIT      CONSTRAINT DF_ptc_esta_activo DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
    CONSTRAINT PK_ptc_plan_tratamiento_control_referencia_normativa PRIMARY KEY CLUSTERED (plt_codigo, crn_codigo),
    CONSTRAINT FK_ptc_plan_tratamiento FOREIGN KEY (plt_codigo) REFERENCES sgspi.plan_tratamiento (plt_codigo),
    CONSTRAINT FK_ptc_control_referencia FOREIGN KEY (crn_codigo) REFERENCES sgspi.control_referencia_normativa (crn_codigo)
);

CREATE NONCLUSTERED INDEX IX_ptc_crn_codigo
    ON sgspi.plan_tratamiento_control_referencia_normativa(crn_codigo);

-- 5.8 [eac] Declaración de Aplicabilidad (SoA) y Evaluación de Cumplimiento por Vigencia
CREATE TABLE sgspi.evaluacion_aplicabilidad_control (
    eac_codigo                      INT                IDENTITY (1, 1) NOT NULL,
    pev_codigo                      SMALLINT           NOT NULL, -- FK a [sgspi].[periodo_vigencia]([pev_codigo])
    crn_codigo                      SMALLINT           NOT NULL, -- FK a [sgspi].[control_referencia_normativa]([crn_codigo])
    eac_es_aplicable                BIT                CONSTRAINT DF_eac_es_aplicable DEFAULT 1 NOT NULL, -- [AP-17]
    eac_justificacion_aplicabilidad NVARCHAR (1000)    NULL,
    eac_documento_soporte_normativo NVARCHAR (500)     NULL,
    car_codigo                      INT                NULL, -- FK a [dbo].[cargo]([car_codigo])
    pdc_codigo                      SMALLINT           NULL, -- [AP-08] FK a [sgspi].[periodicidad_catalogo]([pdc_codigo]): frecuencia de revisión (NULL cuando eac_es_aplicable = 0)
    eac_evidencia_objetiva_esperada NVARCHAR (500)     NULL,
    eac_estado_implementacion       NVARCHAR (20)      NULL, -- 'CUMPLE', 'CUMPLE_PARCIAL', 'NO_CUMPLE' (NULL cuando eac_es_aplicable = 0)
    eac_observaciones_auditoria     NVARCHAR (1000)    NULL,
    eac_fecha_creacion              DATETIMEOFFSET (0) CONSTRAINT DF_eac_fecha_creacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17]
    eac_fecha_actualizacion         DATETIMEOFFSET (0) CONSTRAINT DF_eac_fecha_actualizacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-11] La mantiene TR_eac_integridad_y_actualizacion
    eac_esta_activa                 BIT                CONSTRAINT DF_eac_esta_activa DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
    eac_version                     ROWVERSION         NOT NULL, -- [AP-24] Control de concurrencia optimista
    CONSTRAINT PK_eac_evaluacion_aplicabilidad_control PRIMARY KEY CLUSTERED (eac_codigo),
    CONSTRAINT UQ_eac_vigencia_control UNIQUE (pev_codigo, crn_codigo),
    CONSTRAINT FK_eac_periodo_vigencia FOREIGN KEY (pev_codigo) REFERENCES sgspi.periodo_vigencia (pev_codigo),
    CONSTRAINT FK_eac_control_referencia FOREIGN KEY (crn_codigo) REFERENCES sgspi.control_referencia_normativa (crn_codigo),
    CONSTRAINT FK_eac_dbo_cargo FOREIGN KEY (car_codigo) REFERENCES dbo.cargo (car_codigo),
    CONSTRAINT FK_eac_periodicidad FOREIGN KEY (pdc_codigo) REFERENCES sgspi.periodicidad_catalogo (pdc_codigo), -- [AP-08]
    CONSTRAINT CK_eac_estado_implementacion CHECK (eac_estado_implementacion IS NULL
                                                   OR eac_estado_implementacion IN (N'CUMPLE', N'CUMPLE_PARCIAL', N'NO_CUMPLE')),
    -- Coherencia entre aplicabilidad (BIT) y estado de implementación (sin valor centinela 'NO_APLICA'); un control aplicable tiene responsable y frecuencia
    CONSTRAINT CK_eac_coherencia_aplicabilidad CHECK ((eac_es_aplicable = 1
                                                       AND eac_estado_implementacion IS NOT NULL
                                                       AND car_codigo IS NOT NULL
                                                       AND pdc_codigo IS NOT NULL)
                                                      OR (eac_es_aplicable = 0
                                                          AND eac_estado_implementacion IS NULL
                                                          AND pdc_codigo IS NULL
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
    ON sgspi.evaluacion_aplicabilidad_control(crn_codigo);

CREATE NONCLUSTERED INDEX IX_eac_car_codigo
    ON sgspi.evaluacion_aplicabilidad_control(car_codigo);

CREATE NONCLUSTERED INDEX IX_eac_pdc_codigo -- [AP-08] índice para la FK
    ON sgspi.evaluacion_aplicabilidad_control(pdc_codigo);


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
/*==================================================================================================
5.9 TABLAS DE AUDITORÍA [AP-01]: una sgspi.aud_<tabla> por cada tabla del esquema (acrónimos en la cabecera)
Cada fila guarda el tipo de operación (<aud>_operacion: 'I' = fila creada con sus valores nuevos; 'U' = versión
ANTERIOR de una fila modificada), quién hizo la operación (per_codigo de ORIGINAL_LOGIN()) y cuándo. Las llena el
trigger de la tabla de origen: TR_<acr>_auditoria (5.10.9c), los 8 TR_<acr>_integridad_y_actualizacion (acf, rpi,
aci, ado, eia, plt, act, eac) o, en sga, TR_sga_inmutabilidad (UPDATE, 'U') y TR_sga_sincronizar_avance (INSERT, 'I'),
para no registrar dos veces los UPDATE internos de los triggers.
Columnas: las de origen menos las calculadas, <acr>_version y <acr>_fecha_creacion; la clave conserva su nombre (FK al origen) y
las demás cambian el acrónimo de origen por el de auditoría (en aud_seguimiento_actividad, el per_codigo de origen
es per_codigo_autor), más per_codigo, <aud>_operacion (CHAR(1) DEFAULT 'U' CHECK IN ('I', 'U')), <aud>_usuario_bd y
<aud>_fecha_cambio. Son inmutables: TR_<aud>_inmutabilidad (error 50016) y DENY de escritura a sgspi_rol_base.
==================================================================================================*/
-- [apv] Auditoría de [sgspi].[periodo_vigencia] ([pev])
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

-- [aec] Auditoría de [sgspi].[estado_flujo_catalogo] ([efc])
CREATE TABLE sgspi.aud_estado_flujo_catalogo (
    aec_codigo          INT                IDENTITY (1, 1) NOT NULL,
    efc_codigo          SMALLINT           NOT NULL,
    aec_dominio         NVARCHAR (10)      NOT NULL,
    aec_identificador   NVARCHAR (30)      NOT NULL,
    aec_nombre          NVARCHAR (80)      NOT NULL,
    aec_es_inicial      BIT                NOT NULL,
    aec_permite_edicion BIT                NOT NULL,
    aec_esta_activo     BIT                NOT NULL,
    per_codigo          INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    aec_operacion       CHAR (1)           CONSTRAINT DF_aec_operacion DEFAULT 'U' NOT NULL,
    aec_usuario_bd      SYSNAME            CONSTRAINT DF_aec_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    aec_fecha_cambio    DATETIMEOFFSET (0) CONSTRAINT DF_aec_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_aec_aud_estado_flujo_catalogo PRIMARY KEY CLUSTERED (aec_codigo),
    CONSTRAINT FK_aec_estado_flujo_catalogo FOREIGN KEY (efc_codigo) REFERENCES sgspi.estado_flujo_catalogo (efc_codigo),
    CONSTRAINT FK_aec_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_aec_operacion CHECK (aec_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_aec_efc_codigo
    ON sgspi.aud_estado_flujo_catalogo(efc_codigo, aec_fecha_cambio DESC);

CREATE NONCLUSTERED INDEX IX_aec_per_codigo
    ON sgspi.aud_estado_flujo_catalogo(per_codigo);

-- [atf] Auditoría de [sgspi].[transicion_estado_flujo] ([tef])
CREATE TABLE sgspi.aud_transicion_estado_flujo (
    atf_codigo                INT                IDENTITY (1, 1) NOT NULL,
    tef_codigo                SMALLINT           NOT NULL,
    efc_dominio               NVARCHAR (10)      NOT NULL,
    efc_identificador_origen  NVARCHAR (30)      NOT NULL,
    efc_identificador_destino NVARCHAR (30)      NOT NULL,
    atf_rol_requerido         SYSNAME            NULL,
    atf_esta_activa           BIT                NOT NULL,
    per_codigo                INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    atf_operacion             CHAR (1)           CONSTRAINT DF_atf_operacion DEFAULT 'U' NOT NULL,
    atf_usuario_bd            SYSNAME            CONSTRAINT DF_atf_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    atf_fecha_cambio          DATETIMEOFFSET (0) CONSTRAINT DF_atf_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_atf_aud_transicion_estado_flujo PRIMARY KEY CLUSTERED (atf_codigo),
    CONSTRAINT FK_atf_transicion_estado_flujo FOREIGN KEY (tef_codigo) REFERENCES sgspi.transicion_estado_flujo (tef_codigo),
    CONSTRAINT FK_atf_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_atf_operacion CHECK (atf_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_atf_tef_codigo
    ON sgspi.aud_transicion_estado_flujo(tef_codigo, atf_fecha_cambio DESC);

CREATE NONCLUSTERED INDEX IX_atf_per_codigo
    ON sgspi.aud_transicion_estado_flujo(per_codigo);

-- [atr] Auditoría de [sgspi].[tipo_proceso_catalogo] ([tpr])
CREATE TABLE sgspi.aud_tipo_proceso_catalogo (
    atr_codigo        INT                IDENTITY (1, 1) NOT NULL,
    tpr_codigo        TINYINT            NOT NULL,
    atr_identificador NVARCHAR (20)      NOT NULL,
    atr_nombre        NVARCHAR (50)      NOT NULL,
    atr_descripcion   NVARCHAR (255)     NULL,
    atr_esta_activo   BIT                NOT NULL,
    per_codigo        INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    atr_operacion     CHAR (1)           CONSTRAINT DF_atr_operacion DEFAULT 'U' NOT NULL,
    atr_usuario_bd    SYSNAME            CONSTRAINT DF_atr_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    atr_fecha_cambio  DATETIMEOFFSET (0) CONSTRAINT DF_atr_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_atr_aud_tipo_proceso_catalogo PRIMARY KEY CLUSTERED (atr_codigo),
    CONSTRAINT FK_atr_tipo_proceso_catalogo FOREIGN KEY (tpr_codigo) REFERENCES sgspi.tipo_proceso_catalogo (tpr_codigo),
    CONSTRAINT FK_atr_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_atr_operacion CHECK (atr_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_atr_tpr_codigo
    ON sgspi.aud_tipo_proceso_catalogo(tpr_codigo, atr_fecha_cambio DESC);

CREATE NONCLUSTERED INDEX IX_atr_per_codigo
    ON sgspi.aud_tipo_proceso_catalogo(per_codigo);

-- [api] Auditoría de [sgspi].[proceso_institucional] ([pri])
CREATE TABLE sgspi.aud_proceso_institucional (
    api_codigo        INT                IDENTITY (1, 1) NOT NULL,
    pri_codigo        INT                NOT NULL,
    api_identificador NVARCHAR (20)      NOT NULL,
    api_nombre        NVARCHAR (150)     NOT NULL,
    tpr_codigo        TINYINT            NOT NULL,
    uaa_codigo_lider  INT                NULL,
    car_codigo_lider  INT                NULL,
    api_esta_activo   BIT                NOT NULL,
    per_codigo        INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    api_operacion     CHAR (1)           CONSTRAINT DF_api_operacion DEFAULT 'U' NOT NULL,
    api_usuario_bd    SYSNAME            CONSTRAINT DF_api_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    api_fecha_cambio  DATETIMEOFFSET (0) CONSTRAINT DF_api_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_api_aud_proceso_institucional PRIMARY KEY CLUSTERED (api_codigo),
    CONSTRAINT FK_api_proceso_institucional FOREIGN KEY (pri_codigo) REFERENCES sgspi.proceso_institucional (pri_codigo),
    CONSTRAINT FK_api_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_api_operacion CHECK (api_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_api_pri_codigo
    ON sgspi.aud_proceso_institucional(pri_codigo, api_fecha_cambio DESC);

CREATE NONCLUSTERED INDEX IX_api_per_codigo
    ON sgspi.aud_proceso_institucional(per_codigo);

-- [apu] Auditoría de [sgspi].[proceso_institucional_uaa] ([piu])
CREATE TABLE sgspi.aud_proceso_institucional_uaa (
    apu_codigo       INT                IDENTITY (1, 1) NOT NULL,
    pri_codigo       INT                NOT NULL,
    uaa_codigo       INT                NOT NULL,
    apu_esta_activo  BIT                NOT NULL,
    per_codigo       INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    apu_operacion    CHAR (1)           CONSTRAINT DF_apu_operacion DEFAULT 'U' NOT NULL,
    apu_usuario_bd   SYSNAME            CONSTRAINT DF_apu_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    apu_fecha_cambio DATETIMEOFFSET (0) CONSTRAINT DF_apu_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_apu_aud_proceso_institucional_uaa PRIMARY KEY CLUSTERED (apu_codigo),
    CONSTRAINT FK_apu_proceso_institucional_uaa FOREIGN KEY (pri_codigo, uaa_codigo) REFERENCES sgspi.proceso_institucional_uaa (pri_codigo, uaa_codigo),
    CONSTRAINT FK_apu_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_apu_operacion CHECK (apu_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_apu_pri_codigo_uaa_codigo
    ON sgspi.aud_proceso_institucional_uaa(pri_codigo, uaa_codigo, apu_fecha_cambio DESC);

CREATE NONCLUSTERED INDEX IX_apu_per_codigo
    ON sgspi.aud_proceso_institucional_uaa(per_codigo);

-- [afc] Auditoría de [sgspi].[factor_entorno_catalogo] ([fec])
CREATE TABLE sgspi.aud_factor_entorno_catalogo (
    afc_codigo         INT                IDENTITY (1, 1) NOT NULL,
    fec_codigo         SMALLINT           NOT NULL,
    afc_nombre_factor  NVARCHAR (100)     NOT NULL,
    afc_ambito_entorno NVARCHAR (15)      NOT NULL,
    afc_descripcion    NVARCHAR (255)     NULL,
    afc_esta_activo    BIT                NOT NULL,
    per_codigo         INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    afc_operacion      CHAR (1)           CONSTRAINT DF_afc_operacion DEFAULT 'U' NOT NULL,
    afc_usuario_bd     SYSNAME            CONSTRAINT DF_afc_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    afc_fecha_cambio   DATETIMEOFFSET (0) CONSTRAINT DF_afc_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_afc_aud_factor_entorno_catalogo PRIMARY KEY CLUSTERED (afc_codigo),
    CONSTRAINT FK_afc_factor_entorno_catalogo FOREIGN KEY (fec_codigo) REFERENCES sgspi.factor_entorno_catalogo (fec_codigo),
    CONSTRAINT FK_afc_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_afc_operacion CHECK (afc_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_afc_fec_codigo
    ON sgspi.aud_factor_entorno_catalogo(fec_codigo, afc_fecha_cambio DESC);

CREATE NONCLUSTERED INDEX IX_afc_per_codigo
    ON sgspi.aud_factor_entorno_catalogo(per_codigo);

-- [aaf] Auditoría de [sgspi].[analisis_contexto_factor] ([acf])
CREATE TABLE sgspi.aud_analisis_contexto_factor (
    aaf_codigo                  INT                IDENTITY (1, 1) NOT NULL,
    acf_codigo                  INT                NOT NULL,
    pev_codigo                  SMALLINT           NOT NULL,
    pri_codigo                  INT                NOT NULL,
    fec_codigo                  SMALLINT           NOT NULL,
    aaf_naturaleza_factor       NVARCHAR (15)      NOT NULL,
    aaf_numero_factor           SMALLINT           NOT NULL,
    aaf_descripcion_situacion   NVARCHAR (1000)    NOT NULL,
    aaf_valor_prioridad         TINYINT            NOT NULL,
    aaf_impacto_sistema_gestion NVARCHAR (1000)    NULL,
    aaf_accion_propuesta        NVARCHAR (1000)    NULL,
    aaf_estado_registro         NVARCHAR (30)      NOT NULL,
    per_codigo_creador          INT                NOT NULL,
    per_codigo_aprobador        INT                NULL,
    aaf_fecha_actualizacion     DATETIMEOFFSET (0) NOT NULL,
    aaf_esta_activo             BIT                NOT NULL,
    per_codigo                  INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    aaf_operacion               CHAR (1)           CONSTRAINT DF_aaf_operacion DEFAULT 'U' NOT NULL,
    aaf_usuario_bd              SYSNAME            CONSTRAINT DF_aaf_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    aaf_fecha_cambio            DATETIMEOFFSET (0) CONSTRAINT DF_aaf_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_aaf_aud_analisis_contexto_factor PRIMARY KEY CLUSTERED (aaf_codigo),
    CONSTRAINT FK_aaf_analisis_contexto_factor FOREIGN KEY (acf_codigo) REFERENCES sgspi.analisis_contexto_factor (acf_codigo),
    CONSTRAINT FK_aaf_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_aaf_operacion CHECK (aaf_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_aaf_acf_codigo
    ON sgspi.aud_analisis_contexto_factor(acf_codigo, aaf_fecha_cambio DESC);

CREATE NONCLUSTERED INDEX IX_aaf_per_codigo
    ON sgspi.aud_analisis_contexto_factor(per_codigo);

-- [apa] Auditoría de [sgspi].[parte_interesada] ([pai])
CREATE TABLE sgspi.aud_parte_interesada (
    apa_codigo          INT                IDENTITY (1, 1) NOT NULL,
    pai_codigo          INT                NOT NULL,
    apa_nombre          NVARCHAR (150)     NOT NULL,
    apa_origen          NVARCHAR (15)      NOT NULL,
    apa_descripcion_rol NVARCHAR (255)     NULL,
    apa_esta_activa     BIT                NOT NULL,
    per_codigo          INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    apa_operacion       CHAR (1)           CONSTRAINT DF_apa_operacion DEFAULT 'U' NOT NULL,
    apa_usuario_bd      SYSNAME            CONSTRAINT DF_apa_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    apa_fecha_cambio    DATETIMEOFFSET (0) CONSTRAINT DF_apa_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_apa_aud_parte_interesada PRIMARY KEY CLUSTERED (apa_codigo),
    CONSTRAINT FK_apa_parte_interesada FOREIGN KEY (pai_codigo) REFERENCES sgspi.parte_interesada (pai_codigo),
    CONSTRAINT FK_apa_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_apa_operacion CHECK (apa_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_apa_pai_codigo
    ON sgspi.aud_parte_interesada(pai_codigo, apa_fecha_cambio DESC);

CREATE NONCLUSTERED INDEX IX_apa_per_codigo
    ON sgspi.aud_parte_interesada(per_codigo);

-- [ari] Auditoría de [sgspi].[requisito_parte_interesada] ([rpi])
CREATE TABLE sgspi.aud_requisito_parte_interesada (
    ari_codigo                INT                IDENTITY (1, 1) NOT NULL,
    rpi_codigo                INT                NOT NULL,
    pev_codigo                SMALLINT           NOT NULL,
    pai_codigo                INT                NOT NULL,
    ari_necesidad_expectativa NVARCHAR (1000)    NOT NULL,
    ari_valor_poder           TINYINT            NOT NULL,
    ari_valor_interes         TINYINT            NOT NULL,
    ari_valor_cumplimiento    TINYINT            NULL,
    ari_mecanismo_seguimiento NVARCHAR (255)     NULL,
    ari_estado_registro       NVARCHAR (30)      NOT NULL,
    per_codigo_creador        INT                NOT NULL,
    per_codigo_aprobador      INT                NULL,
    ari_fecha_actualizacion   DATETIMEOFFSET (0) NOT NULL,
    ari_esta_activo           BIT                NOT NULL,
    per_codigo                INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    ari_operacion             CHAR (1)           CONSTRAINT DF_ari_operacion DEFAULT 'U' NOT NULL,
    ari_usuario_bd            SYSNAME            CONSTRAINT DF_ari_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    ari_fecha_cambio          DATETIMEOFFSET (0) CONSTRAINT DF_ari_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_ari_aud_requisito_parte_interesada PRIMARY KEY CLUSTERED (ari_codigo),
    CONSTRAINT FK_ari_requisito_parte_interesada FOREIGN KEY (rpi_codigo) REFERENCES sgspi.requisito_parte_interesada (rpi_codigo),
    CONSTRAINT FK_ari_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_ari_operacion CHECK (ari_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_ari_rpi_codigo
    ON sgspi.aud_requisito_parte_interesada(rpi_codigo, ari_fecha_cambio DESC);

CREATE NONCLUSTERED INDEX IX_ari_per_codigo
    ON sgspi.aud_requisito_parte_interesada(per_codigo);

-- [arp] Auditoría de [sgspi].[requisito_parte_interesada_proceso_institucional] ([rpp])
CREATE TABLE sgspi.aud_requisito_parte_interesada_proceso_institucional (
    arp_codigo         INT                IDENTITY (1, 1) NOT NULL,
    rpi_codigo         INT                NOT NULL,
    pri_codigo         INT                NOT NULL,
    arp_fecha_registro DATETIMEOFFSET (0) NOT NULL,
    arp_esta_activo    BIT                NOT NULL,
    per_codigo         INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    arp_operacion      CHAR (1)           CONSTRAINT DF_arp_operacion DEFAULT 'U' NOT NULL,
    arp_usuario_bd     SYSNAME            CONSTRAINT DF_arp_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    arp_fecha_cambio   DATETIMEOFFSET (0) CONSTRAINT DF_arp_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_arp_aud_requisito_parte_interesada_proceso_institucional PRIMARY KEY CLUSTERED (arp_codigo),
    CONSTRAINT FK_arp_requisito_parte_interesada_proceso_institucional FOREIGN KEY (rpi_codigo, pri_codigo) REFERENCES sgspi.requisito_parte_interesada_proceso_institucional (rpi_codigo, pri_codigo),
    CONSTRAINT FK_arp_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_arp_operacion CHECK (arp_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_arp_rpi_codigo_pri_codigo
    ON sgspi.aud_requisito_parte_interesada_proceso_institucional(rpi_codigo, pri_codigo, arp_fecha_cambio DESC);

CREATE NONCLUSTERED INDEX IX_arp_per_codigo
    ON sgspi.aud_requisito_parte_interesada_proceso_institucional(per_codigo);

-- [atc] Auditoría de [sgspi].[tipo_activo_catalogo] ([tac])
CREATE TABLE sgspi.aud_tipo_activo_catalogo (
    atc_codigo          INT                IDENTITY (1, 1) NOT NULL,
    tac_codigo          SMALLINT           NOT NULL,
    atc_codigo_padre    SMALLINT           NULL,
    atc_nivel_taxonomia TINYINT            NOT NULL,
    atc_nombre          NVARCHAR (120)     NOT NULL,
    atc_ejemplos_ref    NVARCHAR (255)     NULL,
    atc_esta_activo     BIT                NOT NULL,
    per_codigo          INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    atc_operacion       CHAR (1)           CONSTRAINT DF_atc_operacion DEFAULT 'U' NOT NULL,
    atc_usuario_bd      SYSNAME            CONSTRAINT DF_atc_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    atc_fecha_cambio    DATETIMEOFFSET (0) CONSTRAINT DF_atc_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_atc_aud_tipo_activo_catalogo PRIMARY KEY CLUSTERED (atc_codigo),
    CONSTRAINT FK_atc_tipo_activo_catalogo FOREIGN KEY (tac_codigo) REFERENCES sgspi.tipo_activo_catalogo (tac_codigo),
    CONSTRAINT FK_atc_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_atc_operacion CHECK (atc_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_atc_tac_codigo
    ON sgspi.aud_tipo_activo_catalogo(tac_codigo, atc_fecha_cambio DESC);

CREATE NONCLUSTERED INDEX IX_atc_per_codigo
    ON sgspi.aud_tipo_activo_catalogo(per_codigo);

-- [ace] Auditoría de [sgspi].[causal_excepcion_transparencia] ([cet])
CREATE TABLE sgspi.aud_causal_excepcion_transparencia (
    ace_codigo                  INT                IDENTITY (1, 1) NOT NULL,
    cet_codigo                  SMALLINT           NOT NULL,
    ace_nivel_reserva_aplicable NVARCHAR (20)      NOT NULL,
    ace_numeral_causal          NVARCHAR (10)      NOT NULL,
    ace_descripcion_causal      NVARCHAR (500)     NOT NULL,
    ace_norma_referencia        NVARCHAR (100)     NOT NULL,
    ace_esta_activa             BIT                NOT NULL,
    per_codigo                  INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    ace_operacion               CHAR (1)           CONSTRAINT DF_ace_operacion DEFAULT 'U' NOT NULL,
    ace_usuario_bd              SYSNAME            CONSTRAINT DF_ace_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    ace_fecha_cambio            DATETIMEOFFSET (0) CONSTRAINT DF_ace_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_ace_aud_causal_excepcion_transparencia PRIMARY KEY CLUSTERED (ace_codigo),
    CONSTRAINT FK_ace_causal_excepcion_transparencia FOREIGN KEY (cet_codigo) REFERENCES sgspi.causal_excepcion_transparencia (cet_codigo),
    CONSTRAINT FK_ace_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_ace_operacion CHECK (ace_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_ace_cet_codigo
    ON sgspi.aud_causal_excepcion_transparencia(cet_codigo, ace_fecha_cambio DESC);

CREATE NONCLUSTERED INDEX IX_ace_per_codigo
    ON sgspi.aud_causal_excepcion_transparencia(per_codigo);

-- [aai] Auditoría de [sgspi].[activo_informacion] ([aci])
CREATE TABLE sgspi.aud_activo_informacion (
    aai_codigo                          INT                IDENTITY (1, 1) NOT NULL,
    aci_codigo                          INT                NOT NULL,
    aai_codigo_inventario               NVARCHAR (30)      NOT NULL,
    aai_nombre_activo                   NVARCHAR (255)     NOT NULL,
    aai_descripcion_detallada           NVARCHAR (1000)    NULL,
    tac_codigo                          SMALLINT           NOT NULL,
    uaa_codigo                          INT                NULL,
    esp_codigo                          INT                NULL,
    aai_es_transversal_sedes            BIT                NOT NULL,
    aai_cantidad_unidades               INT                NOT NULL,
    aai_clasificacion_transparencia     NVARCHAR (20)      NOT NULL,
    cet_codigo                          SMALLINT           NULL,
    aai_alcance_excepcion               NVARCHAR (15)      NULL,
    aai_fundamento_constitucional_legal NVARCHAR (150)     NULL,
    aai_fundamento_juridico_excepcion   NVARCHAR (150)     NULL,
    aai_fecha_clasificacion_reserva     DATE               NULL,
    aai_es_reserva_indefinida           BIT                NULL,
    aai_anios_plazo_reserva             SMALLINT           NULL,
    aai_contiene_datos_personales       BIT                NOT NULL,
    aai_contiene_datos_menores          BIT                NULL,
    aai_categoria_dato_personal         NVARCHAR (20)      NULL,
    aai_finalidad_recoleccion_pii       NVARCHAR (500)     NULL,
    aai_existe_autorizacion_pii         BIT                NULL,
    aai_valor_confidencialidad          TINYINT            NOT NULL,
    aai_valor_integridad                TINYINT            NOT NULL,
    aai_valor_disponibilidad            TINYINT            NOT NULL,
    aai_supera_umbral_social_icc        BIT                NOT NULL,
    aai_supera_umbral_economico_icc     BIT                NOT NULL,
    aai_supera_umbral_ambiental_icc     BIT                NOT NULL,
    aai_estado_registro                 NVARCHAR (30)      NOT NULL,
    per_codigo_creador                  INT                NOT NULL,
    per_codigo_aprobador                INT                NULL,
    aai_fecha_actualizacion             DATETIMEOFFSET (0) NOT NULL,
    aai_esta_activo                     BIT                NOT NULL,
    per_codigo                          INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    aai_operacion                       CHAR (1)           CONSTRAINT DF_aai_operacion DEFAULT 'U' NOT NULL,
    aai_usuario_bd                      SYSNAME            CONSTRAINT DF_aai_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    aai_fecha_cambio                    DATETIMEOFFSET (0) CONSTRAINT DF_aai_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_aai_aud_activo_informacion PRIMARY KEY CLUSTERED (aai_codigo),
    CONSTRAINT FK_aai_activo_informacion FOREIGN KEY (aci_codigo) REFERENCES sgspi.activo_informacion (aci_codigo),
    CONSTRAINT FK_aai_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_aai_operacion CHECK (aai_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_aai_aci_codigo
    ON sgspi.aud_activo_informacion(aci_codigo, aai_fecha_cambio DESC);

CREATE NONCLUSTERED INDEX IX_aai_per_codigo
    ON sgspi.aud_activo_informacion(per_codigo);

-- [aap] Auditoría de [sgspi].[activo_informacion_proceso_institucional] ([aip])
CREATE TABLE sgspi.aud_activo_informacion_proceso_institucional (
    aap_codigo       INT                IDENTITY (1, 1) NOT NULL,
    aci_codigo       INT                NOT NULL,
    pri_codigo       INT                NOT NULL,
    aap_esta_activo  BIT                NOT NULL,
    per_codigo       INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    aap_operacion    CHAR (1)           CONSTRAINT DF_aap_operacion DEFAULT 'U' NOT NULL,
    aap_usuario_bd   SYSNAME            CONSTRAINT DF_aap_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    aap_fecha_cambio DATETIMEOFFSET (0) CONSTRAINT DF_aap_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_aap_aud_activo_informacion_proceso_institucional PRIMARY KEY CLUSTERED (aap_codigo),
    CONSTRAINT FK_aap_activo_informacion_proceso_institucional FOREIGN KEY (aci_codigo, pri_codigo) REFERENCES sgspi.activo_informacion_proceso_institucional (aci_codigo, pri_codigo),
    CONSTRAINT FK_aap_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_aap_operacion CHECK (aap_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_aap_aci_codigo_pri_codigo
    ON sgspi.aud_activo_informacion_proceso_institucional(aci_codigo, pri_codigo, aap_fecha_cambio DESC);

CREATE NONCLUSTERED INDEX IX_aap_per_codigo
    ON sgspi.aud_activo_informacion_proceso_institucional(per_codigo);

-- [aas] Auditoría de [sgspi].[activo_informacion_sede] ([ais])
CREATE TABLE sgspi.aud_activo_informacion_sede (
    aas_codigo       INT                IDENTITY (1, 1) NOT NULL,
    aci_codigo       INT                NOT NULL,
    sus_codigo       INT                NOT NULL,
    aas_esta_activo  BIT                NOT NULL,
    per_codigo       INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    aas_operacion    CHAR (1)           CONSTRAINT DF_aas_operacion DEFAULT 'U' NOT NULL,
    aas_usuario_bd   SYSNAME            CONSTRAINT DF_aas_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    aas_fecha_cambio DATETIMEOFFSET (0) CONSTRAINT DF_aas_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_aas_aud_activo_informacion_sede PRIMARY KEY CLUSTERED (aas_codigo),
    CONSTRAINT FK_aas_activo_informacion_sede FOREIGN KEY (aci_codigo, sus_codigo) REFERENCES sgspi.activo_informacion_sede (aci_codigo, sus_codigo),
    CONSTRAINT FK_aas_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_aas_operacion CHECK (aas_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_aas_aci_codigo_sus_codigo
    ON sgspi.aud_activo_informacion_sede(aci_codigo, sus_codigo, aas_fecha_cambio DESC);

CREATE NONCLUSTERED INDEX IX_aas_per_codigo
    ON sgspi.aud_activo_informacion_sede(per_codigo);

-- [aar] Auditoría de [sgspi].[activo_informacion_responsable] ([air])
CREATE TABLE sgspi.aud_activo_informacion_responsable (
    aar_codigo               INT                IDENTITY (1, 1) NOT NULL,
    aci_codigo               INT                NOT NULL,
    car_codigo               INT                NOT NULL,
    uaa_codigo               INT                NOT NULL,
    air_tipo_responsabilidad NVARCHAR (20)      NOT NULL,
    aar_esta_activo          BIT                NOT NULL,
    per_codigo               INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    aar_operacion            CHAR (1)           CONSTRAINT DF_aar_operacion DEFAULT 'U' NOT NULL,
    aar_usuario_bd           SYSNAME            CONSTRAINT DF_aar_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    aar_fecha_cambio         DATETIMEOFFSET (0) CONSTRAINT DF_aar_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_aar_aud_activo_informacion_responsable PRIMARY KEY CLUSTERED (aar_codigo),
    CONSTRAINT FK_aar_activo_informacion_responsable FOREIGN KEY (aci_codigo, car_codigo, uaa_codigo, air_tipo_responsabilidad) REFERENCES sgspi.activo_informacion_responsable (aci_codigo, car_codigo, uaa_codigo, air_tipo_responsabilidad),
    CONSTRAINT FK_aar_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_aar_operacion CHECK (aar_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_aar_aci_codigo_car_codigo_uaa_codigo_air_tipo_responsabilidad
    ON sgspi.aud_activo_informacion_responsable(aci_codigo, car_codigo, uaa_codigo, air_tipo_responsabilidad, aar_fecha_cambio DESC);

CREATE NONCLUSTERED INDEX IX_aar_per_codigo
    ON sgspi.aud_activo_informacion_responsable(per_codigo);

-- [asf] Auditoría de [sgspi].[sistema_informacion_ficha] ([sif])
CREATE TABLE sgspi.aud_sistema_informacion_ficha (
    asf_codigo               INT                IDENTITY (1, 1) NOT NULL,
    sif_codigo               INT                NOT NULL,
    aci_codigo               INT                NULL,
    asf_nombre_sistema       NVARCHAR (150)     NOT NULL,
    asf_modalidad_desarrollo NVARCHAR (50)      NOT NULL,
    asf_fabricante_proveedor NVARCHAR (150)     NULL,
    asf_descripcion_general  NVARCHAR (1000)    NOT NULL,
    asf_esta_activo          BIT                NOT NULL,
    per_codigo               INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    asf_operacion            CHAR (1)           CONSTRAINT DF_asf_operacion DEFAULT 'U' NOT NULL,
    asf_usuario_bd           SYSNAME            CONSTRAINT DF_asf_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    asf_fecha_cambio         DATETIMEOFFSET (0) CONSTRAINT DF_asf_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_asf_aud_sistema_informacion_ficha PRIMARY KEY CLUSTERED (asf_codigo),
    CONSTRAINT FK_asf_sistema_informacion_ficha FOREIGN KEY (sif_codigo) REFERENCES sgspi.sistema_informacion_ficha (sif_codigo),
    CONSTRAINT FK_asf_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_asf_operacion CHECK (asf_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_asf_sif_codigo
    ON sgspi.aud_sistema_informacion_ficha(sif_codigo, asf_fecha_cambio DESC);

CREATE NONCLUSTERED INDEX IX_asf_per_codigo
    ON sgspi.aud_sistema_informacion_ficha(per_codigo);

-- [ami] Auditoría de [sgspi].[modulo_sistema_informacion] ([msi])
CREATE TABLE sgspi.aud_modulo_sistema_informacion (
    ami_codigo            INT                IDENTITY (1, 1) NOT NULL,
    msi_codigo            INT                NOT NULL,
    sif_codigo            INT                NOT NULL,
    ami_nombre_modulo     NVARCHAR (200)     NOT NULL,
    ami_usuarios_objetivo NVARCHAR (150)     NULL,
    ami_esta_activo       BIT                NOT NULL,
    per_codigo            INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    ami_operacion         CHAR (1)           CONSTRAINT DF_ami_operacion DEFAULT 'U' NOT NULL,
    ami_usuario_bd        SYSNAME            CONSTRAINT DF_ami_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    ami_fecha_cambio      DATETIMEOFFSET (0) CONSTRAINT DF_ami_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_ami_aud_modulo_sistema_informacion PRIMARY KEY CLUSTERED (ami_codigo),
    CONSTRAINT FK_ami_modulo_sistema_informacion FOREIGN KEY (msi_codigo) REFERENCES sgspi.modulo_sistema_informacion (msi_codigo),
    CONSTRAINT FK_ami_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_ami_operacion CHECK (ami_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_ami_msi_codigo
    ON sgspi.aud_modulo_sistema_informacion(msi_codigo, ami_fecha_cambio DESC);

CREATE NONCLUSTERED INDEX IX_ami_per_codigo
    ON sgspi.aud_modulo_sistema_informacion(per_codigo);

-- [aso] Auditoría de [sgspi].[serie_documental_catalogo] ([sdo])
CREATE TABLE sgspi.aud_serie_documental_catalogo (
    aso_codigo       INT                IDENTITY (1, 1) NOT NULL,
    sdo_codigo       SMALLINT           NOT NULL,
    aso_numero_ccd   SMALLINT           NOT NULL,
    aso_nombre_serie NVARCHAR (150)     NOT NULL,
    aso_esta_activa  BIT                NOT NULL,
    per_codigo       INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    aso_operacion    CHAR (1)           CONSTRAINT DF_aso_operacion DEFAULT 'U' NOT NULL,
    aso_usuario_bd   SYSNAME            CONSTRAINT DF_aso_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    aso_fecha_cambio DATETIMEOFFSET (0) CONSTRAINT DF_aso_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_aso_aud_serie_documental_catalogo PRIMARY KEY CLUSTERED (aso_codigo),
    CONSTRAINT FK_aso_serie_documental_catalogo FOREIGN KEY (sdo_codigo) REFERENCES sgspi.serie_documental_catalogo (sdo_codigo),
    CONSTRAINT FK_aso_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_aso_operacion CHECK (aso_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_aso_sdo_codigo
    ON sgspi.aud_serie_documental_catalogo(sdo_codigo, aso_fecha_cambio DESC);

CREATE NONCLUSTERED INDEX IX_aso_per_codigo
    ON sgspi.aud_serie_documental_catalogo(per_codigo);

-- [asd] Auditoría de [sgspi].[subserie_documental_catalogo] ([sbd])
CREATE TABLE sgspi.aud_subserie_documental_catalogo (
    asd_codigo          INT                IDENTITY (1, 1) NOT NULL,
    sbd_codigo          INT                NOT NULL,
    sdo_codigo          SMALLINT           NOT NULL,
    asd_numero_ccd      SMALLINT           NOT NULL,
    asd_nombre_subserie NVARCHAR (200)     NOT NULL,
    asd_esta_activa     BIT                NOT NULL,
    per_codigo          INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    asd_operacion       CHAR (1)           CONSTRAINT DF_asd_operacion DEFAULT 'U' NOT NULL,
    asd_usuario_bd      SYSNAME            CONSTRAINT DF_asd_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    asd_fecha_cambio    DATETIMEOFFSET (0) CONSTRAINT DF_asd_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_asd_aud_subserie_documental_catalogo PRIMARY KEY CLUSTERED (asd_codigo),
    CONSTRAINT FK_asd_subserie_documental_catalogo FOREIGN KEY (sbd_codigo) REFERENCES sgspi.subserie_documental_catalogo (sbd_codigo),
    CONSTRAINT FK_asd_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_asd_operacion CHECK (asd_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_asd_sbd_codigo
    ON sgspi.aud_subserie_documental_catalogo(sbd_codigo, asd_fecha_cambio DESC);

CREATE NONCLUSTERED INDEX IX_asd_per_codigo
    ON sgspi.aud_subserie_documental_catalogo(per_codigo);

-- [auc] Auditoría de [sgspi].[unidad_productora_cuadro_clasificacion_documental] ([upc])
CREATE TABLE sgspi.aud_unidad_productora_cuadro_clasificacion_documental (
    auc_codigo              INT                IDENTITY (1, 1) NOT NULL,
    upc_codigo              INT                NOT NULL,
    auc_nodo_jerarquico     HIERARCHYID        NOT NULL,
    auc_codigo_archivistico NVARCHAR (50)      NULL,
    uaa_codigo              INT                NULL,
    auc_nombre_unidad       NVARCHAR (150)     NOT NULL,
    auc_esta_activa         BIT                NOT NULL,
    per_codigo              INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    auc_operacion           CHAR (1)           CONSTRAINT DF_auc_operacion DEFAULT 'U' NOT NULL,
    auc_usuario_bd          SYSNAME            CONSTRAINT DF_auc_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    auc_fecha_cambio        DATETIMEOFFSET (0) CONSTRAINT DF_auc_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_auc_aud_unidad_productora_cuadro_clasificacion_documental PRIMARY KEY CLUSTERED (auc_codigo),
    CONSTRAINT FK_auc_unidad_productora_cuadro_clasificacion_documental FOREIGN KEY (upc_codigo) REFERENCES sgspi.unidad_productora_cuadro_clasificacion_documental (upc_codigo),
    CONSTRAINT FK_auc_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_auc_operacion CHECK (auc_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_auc_upc_codigo
    ON sgspi.aud_unidad_productora_cuadro_clasificacion_documental(upc_codigo, auc_fecha_cambio DESC);

CREATE NONCLUSTERED INDEX IX_auc_per_codigo
    ON sgspi.aud_unidad_productora_cuadro_clasificacion_documental(per_codigo);

-- [apc] Auditoría de [sgspi].[periodicidad_catalogo] ([pdc])
CREATE TABLE sgspi.aud_periodicidad_catalogo (
    apc_codigo       INT                IDENTITY (1, 1) NOT NULL,
    pdc_codigo       SMALLINT           NOT NULL,
    apc_nombre       NVARCHAR (40)      NOT NULL,
    apc_orden        TINYINT            NOT NULL,
    apc_esta_activa  BIT                NOT NULL,
    per_codigo       INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    apc_operacion    CHAR (1)           CONSTRAINT DF_apc_operacion DEFAULT 'U' NOT NULL,
    apc_usuario_bd   SYSNAME            CONSTRAINT DF_apc_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    apc_fecha_cambio DATETIMEOFFSET (0) CONSTRAINT DF_apc_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_apc_aud_periodicidad_catalogo PRIMARY KEY CLUSTERED (apc_codigo),
    CONSTRAINT FK_apc_periodicidad_catalogo FOREIGN KEY (pdc_codigo) REFERENCES sgspi.periodicidad_catalogo (pdc_codigo),
    CONSTRAINT FK_apc_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_apc_operacion CHECK (apc_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_apc_pdc_codigo
    ON sgspi.aud_periodicidad_catalogo(pdc_codigo, apc_fecha_cambio DESC);

CREATE NONCLUSTERED INDEX IX_apc_per_codigo
    ON sgspi.aud_periodicidad_catalogo(per_codigo);

-- [aep] Auditoría de [sgspi].[estado_publicacion_catalogo] ([epc])
CREATE TABLE sgspi.aud_estado_publicacion_catalogo (
    aep_codigo       INT                IDENTITY (1, 1) NOT NULL,
    epc_codigo       SMALLINT           NOT NULL,
    aep_nombre       NVARCHAR (60)      NOT NULL,
    aep_descripcion  NVARCHAR (255)     NULL,
    aep_esta_activo  BIT                NOT NULL,
    per_codigo       INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    aep_operacion    CHAR (1)           CONSTRAINT DF_aep_operacion DEFAULT 'U' NOT NULL,
    aep_usuario_bd   SYSNAME            CONSTRAINT DF_aep_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    aep_fecha_cambio DATETIMEOFFSET (0) CONSTRAINT DF_aep_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_aep_aud_estado_publicacion_catalogo PRIMARY KEY CLUSTERED (aep_codigo),
    CONSTRAINT FK_aep_estado_publicacion_catalogo FOREIGN KEY (epc_codigo) REFERENCES sgspi.estado_publicacion_catalogo (epc_codigo),
    CONSTRAINT FK_aep_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_aep_operacion CHECK (aep_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_aep_epc_codigo
    ON sgspi.aud_estado_publicacion_catalogo(epc_codigo, aep_fecha_cambio DESC);

CREATE NONCLUSTERED INDEX IX_aep_per_codigo
    ON sgspi.aud_estado_publicacion_catalogo(per_codigo);

-- [asc] Auditoría de [sgspi].[soporte_registro_catalogo] ([src])
CREATE TABLE sgspi.aud_soporte_registro_catalogo (
    asc_codigo       INT                IDENTITY (1, 1) NOT NULL,
    src_codigo       SMALLINT           NOT NULL,
    asc_nombre       NVARCHAR (30)      NOT NULL,
    asc_esta_activo  BIT                NOT NULL,
    per_codigo       INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    asc_operacion    CHAR (1)           CONSTRAINT DF_asc_operacion DEFAULT 'U' NOT NULL,
    asc_usuario_bd   SYSNAME            CONSTRAINT DF_asc_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    asc_fecha_cambio DATETIMEOFFSET (0) CONSTRAINT DF_asc_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_asc_aud_soporte_registro_catalogo PRIMARY KEY CLUSTERED (asc_codigo),
    CONSTRAINT FK_asc_soporte_registro_catalogo FOREIGN KEY (src_codigo) REFERENCES sgspi.soporte_registro_catalogo (src_codigo),
    CONSTRAINT FK_asc_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_asc_operacion CHECK (asc_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_asc_src_codigo
    ON sgspi.aud_soporte_registro_catalogo(src_codigo, asc_fecha_cambio DESC);

CREATE NONCLUSTERED INDEX IX_asc_per_codigo
    ON sgspi.aud_soporte_registro_catalogo(per_codigo);

-- [amc] Auditoría de [sgspi].[medio_conservacion_catalogo] ([mcc])
CREATE TABLE sgspi.aud_medio_conservacion_catalogo (
    amc_codigo       INT                IDENTITY (1, 1) NOT NULL,
    mcc_codigo       SMALLINT           NOT NULL,
    amc_nombre       NVARCHAR (30)      NOT NULL,
    amc_esta_activo  BIT                NOT NULL,
    per_codigo       INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    amc_operacion    CHAR (1)           CONSTRAINT DF_amc_operacion DEFAULT 'U' NOT NULL,
    amc_usuario_bd   SYSNAME            CONSTRAINT DF_amc_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    amc_fecha_cambio DATETIMEOFFSET (0) CONSTRAINT DF_amc_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_amc_aud_medio_conservacion_catalogo PRIMARY KEY CLUSTERED (amc_codigo),
    CONSTRAINT FK_amc_medio_conservacion_catalogo FOREIGN KEY (mcc_codigo) REFERENCES sgspi.medio_conservacion_catalogo (mcc_codigo),
    CONSTRAINT FK_amc_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_amc_operacion CHECK (amc_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_amc_mcc_codigo
    ON sgspi.aud_medio_conservacion_catalogo(mcc_codigo, amc_fecha_cambio DESC);

CREATE NONCLUSTERED INDEX IX_amc_per_codigo
    ON sgspi.aud_medio_conservacion_catalogo(per_codigo);

-- [aii] Auditoría de [sgspi].[idioma_catalogo] ([idi])
CREATE TABLE sgspi.aud_idioma_catalogo (
    aii_codigo       INT                IDENTITY (1, 1) NOT NULL,
    idi_codigo       SMALLINT           NOT NULL,
    aii_codigo_iso   NVARCHAR (10)      NOT NULL,
    aii_nombre       NVARCHAR (50)      NOT NULL,
    aii_esta_activo  BIT                NOT NULL,
    per_codigo       INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    aii_operacion    CHAR (1)           CONSTRAINT DF_aii_operacion DEFAULT 'U' NOT NULL,
    aii_usuario_bd   SYSNAME            CONSTRAINT DF_aii_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    aii_fecha_cambio DATETIMEOFFSET (0) CONSTRAINT DF_aii_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_aii_aud_idioma_catalogo PRIMARY KEY CLUSTERED (aii_codigo),
    CONSTRAINT FK_aii_idioma_catalogo FOREIGN KEY (idi_codigo) REFERENCES sgspi.idioma_catalogo (idi_codigo),
    CONSTRAINT FK_aii_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_aii_operacion CHECK (aii_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_aii_idi_codigo
    ON sgspi.aud_idioma_catalogo(idi_codigo, aii_fecha_cambio DESC);

CREATE NONCLUSTERED INDEX IX_aii_per_codigo
    ON sgspi.aud_idioma_catalogo(per_codigo);

-- [afa] Auditoría de [sgspi].[formato_archivo_catalogo] ([fac])
CREATE TABLE sgspi.aud_formato_archivo_catalogo (
    afa_codigo       INT                IDENTITY (1, 1) NOT NULL,
    fac_codigo       SMALLINT           NOT NULL,
    afa_nombre       NVARCHAR (60)      NOT NULL,
    afa_esta_activo  BIT                NOT NULL,
    per_codigo       INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    afa_operacion    CHAR (1)           CONSTRAINT DF_afa_operacion DEFAULT 'U' NOT NULL,
    afa_usuario_bd   SYSNAME            CONSTRAINT DF_afa_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    afa_fecha_cambio DATETIMEOFFSET (0) CONSTRAINT DF_afa_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_afa_aud_formato_archivo_catalogo PRIMARY KEY CLUSTERED (afa_codigo),
    CONSTRAINT FK_afa_formato_archivo_catalogo FOREIGN KEY (fac_codigo) REFERENCES sgspi.formato_archivo_catalogo (fac_codigo),
    CONSTRAINT FK_afa_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_afa_operacion CHECK (afa_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_afa_fac_codigo
    ON sgspi.aud_formato_archivo_catalogo(fac_codigo, afa_fecha_cambio DESC);

CREATE NONCLUSTERED INDEX IX_afa_per_codigo
    ON sgspi.aud_formato_archivo_catalogo(per_codigo);

-- [aao] Auditoría de [sgspi].[activo_documental] ([ado])
CREATE TABLE sgspi.aud_activo_documental (
    aao_codigo                        INT                IDENTITY (1, 1) NOT NULL,
    ado_codigo                        INT                NOT NULL,
    pev_codigo                        SMALLINT           NOT NULL,
    sdo_codigo                        SMALLINT           NOT NULL,
    sbd_codigo                        INT                NULL,
    pdc_codigo                        SMALLINT           NOT NULL,
    aao_fecha_ingreso_tabla_retencion DATE               NULL,
    aao_fecha_ingreso_archivo         DATE               NULL,
    epc_codigo                        SMALLINT           NOT NULL,
    aao_lugar_consulta_ubicacion      NVARCHAR (255)     NOT NULL,
    per_codigo_revisor_archivo        INT                NULL,
    aao_fecha_actualizacion           DATETIMEOFFSET (0) NOT NULL,
    aao_esta_activo                   BIT                NOT NULL,
    per_codigo                        INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    aao_operacion                     CHAR (1)           CONSTRAINT DF_aao_operacion DEFAULT 'U' NOT NULL,
    aao_usuario_bd                    SYSNAME            CONSTRAINT DF_aao_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    aao_fecha_cambio                  DATETIMEOFFSET (0) CONSTRAINT DF_aao_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_aao_aud_activo_documental PRIMARY KEY CLUSTERED (aao_codigo),
    CONSTRAINT FK_aao_activo_documental FOREIGN KEY (ado_codigo) REFERENCES sgspi.activo_documental (ado_codigo),
    CONSTRAINT FK_aao_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_aao_operacion CHECK (aao_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_aao_ado_codigo
    ON sgspi.aud_activo_documental(ado_codigo, aao_fecha_cambio DESC);

CREATE NONCLUSTERED INDEX IX_aao_per_codigo
    ON sgspi.aud_activo_documental(per_codigo);

-- [aad] Auditoría de [sgspi].[activo_documental_soporte_registro] ([ads])
CREATE TABLE sgspi.aud_activo_documental_soporte_registro (
    aad_codigo       INT                IDENTITY (1, 1) NOT NULL,
    ado_codigo       INT                NOT NULL,
    src_codigo       SMALLINT           NOT NULL,
    aad_esta_activo  BIT                NOT NULL,
    per_codigo       INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    aad_operacion    CHAR (1)           CONSTRAINT DF_aad_operacion DEFAULT 'U' NOT NULL,
    aad_usuario_bd   SYSNAME            CONSTRAINT DF_aad_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    aad_fecha_cambio DATETIMEOFFSET (0) CONSTRAINT DF_aad_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_aad_aud_activo_documental_soporte_registro PRIMARY KEY CLUSTERED (aad_codigo),
    CONSTRAINT FK_aad_activo_documental_soporte_registro FOREIGN KEY (ado_codigo, src_codigo) REFERENCES sgspi.activo_documental_soporte_registro (ado_codigo, src_codigo),
    CONSTRAINT FK_aad_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_aad_operacion CHECK (aad_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_aad_ado_codigo_src_codigo
    ON sgspi.aud_activo_documental_soporte_registro(ado_codigo, src_codigo, aad_fecha_cambio DESC);

CREATE NONCLUSTERED INDEX IX_aad_per_codigo
    ON sgspi.aud_activo_documental_soporte_registro(per_codigo);

-- [aam] Auditoría de [sgspi].[activo_documental_medio_conservacion] ([adm])
CREATE TABLE sgspi.aud_activo_documental_medio_conservacion (
    aam_codigo       INT                IDENTITY (1, 1) NOT NULL,
    ado_codigo       INT                NOT NULL,
    mcc_codigo       SMALLINT           NOT NULL,
    aam_esta_activo  BIT                NOT NULL,
    per_codigo       INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    aam_operacion    CHAR (1)           CONSTRAINT DF_aam_operacion DEFAULT 'U' NOT NULL,
    aam_usuario_bd   SYSNAME            CONSTRAINT DF_aam_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    aam_fecha_cambio DATETIMEOFFSET (0) CONSTRAINT DF_aam_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_aam_aud_activo_documental_medio_conservacion PRIMARY KEY CLUSTERED (aam_codigo),
    CONSTRAINT FK_aam_activo_documental_medio_conservacion FOREIGN KEY (ado_codigo, mcc_codigo) REFERENCES sgspi.activo_documental_medio_conservacion (ado_codigo, mcc_codigo),
    CONSTRAINT FK_aam_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_aam_operacion CHECK (aam_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_aam_ado_codigo_mcc_codigo
    ON sgspi.aud_activo_documental_medio_conservacion(ado_codigo, mcc_codigo, aam_fecha_cambio DESC);

CREATE NONCLUSTERED INDEX IX_aam_per_codigo
    ON sgspi.aud_activo_documental_medio_conservacion(per_codigo);

-- [aid] Auditoría de [sgspi].[activo_documental_idioma] ([adi])
CREATE TABLE sgspi.aud_activo_documental_idioma (
    aid_codigo       INT                IDENTITY (1, 1) NOT NULL,
    ado_codigo       INT                NOT NULL,
    idi_codigo       SMALLINT           NOT NULL,
    aid_esta_activo  BIT                NOT NULL,
    per_codigo       INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    aid_operacion    CHAR (1)           CONSTRAINT DF_aid_operacion DEFAULT 'U' NOT NULL,
    aid_usuario_bd   SYSNAME            CONSTRAINT DF_aid_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    aid_fecha_cambio DATETIMEOFFSET (0) CONSTRAINT DF_aid_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_aid_aud_activo_documental_idioma PRIMARY KEY CLUSTERED (aid_codigo),
    CONSTRAINT FK_aid_activo_documental_idioma FOREIGN KEY (ado_codigo, idi_codigo) REFERENCES sgspi.activo_documental_idioma (ado_codigo, idi_codigo),
    CONSTRAINT FK_aid_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_aid_operacion CHECK (aid_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_aid_ado_codigo_idi_codigo
    ON sgspi.aud_activo_documental_idioma(ado_codigo, idi_codigo, aid_fecha_cambio DESC);

CREATE NONCLUSTERED INDEX IX_aid_per_codigo
    ON sgspi.aud_activo_documental_idioma(per_codigo);

-- [afd] Auditoría de [sgspi].[activo_documental_formato_archivo] ([adf])
CREATE TABLE sgspi.aud_activo_documental_formato_archivo (
    afd_codigo       INT                IDENTITY (1, 1) NOT NULL,
    ado_codigo       INT                NOT NULL,
    fac_codigo       SMALLINT           NOT NULL,
    afd_esta_activo  BIT                NOT NULL,
    per_codigo       INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    afd_operacion    CHAR (1)           CONSTRAINT DF_afd_operacion DEFAULT 'U' NOT NULL,
    afd_usuario_bd   SYSNAME            CONSTRAINT DF_afd_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    afd_fecha_cambio DATETIMEOFFSET (0) CONSTRAINT DF_afd_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_afd_aud_activo_documental_formato_archivo PRIMARY KEY CLUSTERED (afd_codigo),
    CONSTRAINT FK_afd_activo_documental_formato_archivo FOREIGN KEY (ado_codigo, fac_codigo) REFERENCES sgspi.activo_documental_formato_archivo (ado_codigo, fac_codigo),
    CONSTRAINT FK_afd_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_afd_operacion CHECK (afd_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_afd_ado_codigo_fac_codigo
    ON sgspi.aud_activo_documental_formato_archivo(ado_codigo, fac_codigo, afd_fecha_cambio DESC);

CREATE NONCLUSTERED INDEX IX_afd_per_codigo
    ON sgspi.aud_activo_documental_formato_archivo(per_codigo);

-- [aau] Auditoría de [sgspi].[activo_documental_unidad_productora] ([adu])
CREATE TABLE sgspi.aud_activo_documental_unidad_productora (
    aau_codigo       INT                IDENTITY (1, 1) NOT NULL,
    ado_codigo       INT                NOT NULL,
    upc_codigo       INT                NOT NULL,
    aau_esta_activo  BIT                NOT NULL,
    per_codigo       INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    aau_operacion    CHAR (1)           CONSTRAINT DF_aau_operacion DEFAULT 'U' NOT NULL,
    aau_usuario_bd   SYSNAME            CONSTRAINT DF_aau_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    aau_fecha_cambio DATETIMEOFFSET (0) CONSTRAINT DF_aau_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_aau_aud_activo_documental_unidad_productora PRIMARY KEY CLUSTERED (aau_codigo),
    CONSTRAINT FK_aau_activo_documental_unidad_productora FOREIGN KEY (ado_codigo, upc_codigo) REFERENCES sgspi.activo_documental_unidad_productora (ado_codigo, upc_codigo),
    CONSTRAINT FK_aau_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_aau_operacion CHECK (aau_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_aau_ado_codigo_upc_codigo
    ON sgspi.aud_activo_documental_unidad_productora(ado_codigo, upc_codigo, aau_fecha_cambio DESC);

CREATE NONCLUSTERED INDEX IX_aau_per_codigo
    ON sgspi.aud_activo_documental_unidad_productora(per_codigo);

-- [aer] Auditoría de [sgspi].[escala_probabilidad] ([epr])
CREATE TABLE sgspi.aud_escala_probabilidad (
    aer_codigo                INT                IDENTITY (1, 1) NOT NULL,
    epr_codigo                TINYINT            NOT NULL,
    aer_codigo_letra          CHAR (1)           NOT NULL,
    aer_nombre_nivel          NVARCHAR (30)      NOT NULL,
    aer_descripcion_criterio  NVARCHAR (255)     NOT NULL,
    aer_frecuencia_referencia NVARCHAR (100)     NOT NULL,
    aer_esta_activa           BIT                NOT NULL,
    per_codigo                INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    aer_operacion             CHAR (1)           CONSTRAINT DF_aer_operacion DEFAULT 'U' NOT NULL,
    aer_usuario_bd            SYSNAME            CONSTRAINT DF_aer_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    aer_fecha_cambio          DATETIMEOFFSET (0) CONSTRAINT DF_aer_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_aer_aud_escala_probabilidad PRIMARY KEY CLUSTERED (aer_codigo),
    CONSTRAINT FK_aer_escala_probabilidad FOREIGN KEY (epr_codigo) REFERENCES sgspi.escala_probabilidad (epr_codigo),
    CONSTRAINT FK_aer_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_aer_operacion CHECK (aer_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_aer_epr_codigo
    ON sgspi.aud_escala_probabilidad(epr_codigo, aer_fecha_cambio DESC);

CREATE NONCLUSTERED INDEX IX_aer_per_codigo
    ON sgspi.aud_escala_probabilidad(per_codigo);

-- [aem] Auditoría de [sgspi].[escala_impacto] ([eim])
CREATE TABLE sgspi.aud_escala_impacto (
    aem_codigo                     INT                IDENTITY (1, 1) NOT NULL,
    eim_codigo                     TINYINT            NOT NULL,
    aem_nombre_impacto_negativo    NVARCHAR (30)      NOT NULL,
    aem_nombre_impacto_positivo    NVARCHAR (40)      NOT NULL,
    aem_descripcion_organizacional NVARCHAR (1000)    NOT NULL,
    aem_descripcion_operativa      NVARCHAR (1000)    NULL,
    aem_esta_activa                BIT                NOT NULL,
    per_codigo                     INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    aem_operacion                  CHAR (1)           CONSTRAINT DF_aem_operacion DEFAULT 'U' NOT NULL,
    aem_usuario_bd                 SYSNAME            CONSTRAINT DF_aem_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    aem_fecha_cambio               DATETIMEOFFSET (0) CONSTRAINT DF_aem_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_aem_aud_escala_impacto PRIMARY KEY CLUSTERED (aem_codigo),
    CONSTRAINT FK_aem_escala_impacto FOREIGN KEY (eim_codigo) REFERENCES sgspi.escala_impacto (eim_codigo),
    CONSTRAINT FK_aem_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_aem_operacion CHECK (aem_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_aem_eim_codigo
    ON sgspi.aud_escala_impacto(eim_codigo, aem_fecha_cambio DESC);

CREATE NONCLUSTERED INDEX IX_aem_per_codigo
    ON sgspi.aud_escala_impacto(per_codigo);

-- [azc] Auditoría de [sgspi].[zona_riesgo_catalogo] ([zrc])
CREATE TABLE sgspi.aud_zona_riesgo_catalogo (
    azc_codigo       INT                IDENTITY (1, 1) NOT NULL,
    zrc_codigo       CHAR (1)           NOT NULL,
    azc_nombre_nivel NVARCHAR (30)      NOT NULL,
    azc_orden        TINYINT            NOT NULL,
    azc_esta_activa  BIT                NOT NULL,
    per_codigo       INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    azc_operacion    CHAR (1)           CONSTRAINT DF_azc_operacion DEFAULT 'U' NOT NULL,
    azc_usuario_bd   SYSNAME            CONSTRAINT DF_azc_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    azc_fecha_cambio DATETIMEOFFSET (0) CONSTRAINT DF_azc_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_azc_aud_zona_riesgo_catalogo PRIMARY KEY CLUSTERED (azc_codigo),
    CONSTRAINT FK_azc_zona_riesgo_catalogo FOREIGN KEY (zrc_codigo) REFERENCES sgspi.zona_riesgo_catalogo (zrc_codigo),
    CONSTRAINT FK_azc_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_azc_operacion CHECK (azc_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_azc_zrc_codigo
    ON sgspi.aud_zona_riesgo_catalogo(zrc_codigo, azc_fecha_cambio DESC);

CREATE NONCLUSTERED INDEX IX_azc_per_codigo
    ON sgspi.aud_zona_riesgo_catalogo(per_codigo);

-- [amr] Auditoría de [sgspi].[matriz_valoracion_riesgo] ([mvr])
CREATE TABLE sgspi.aud_matriz_valoracion_riesgo (
    amr_codigo                            INT                IDENTITY (1, 1) NOT NULL,
    epr_codigo                            TINYINT            NOT NULL,
    eim_codigo                            TINYINT            NOT NULL,
    zrc_codigo                            CHAR (1)           NOT NULL,
    amr_directriz_tratamiento_riesgo      NVARCHAR (255)     NOT NULL,
    amr_directriz_tratamiento_oportunidad NVARCHAR (255)     NOT NULL,
    amr_requiere_aprobacion_comite        BIT                NOT NULL,
    amr_esta_activa                       BIT                NOT NULL,
    per_codigo                            INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    amr_operacion                         CHAR (1)           CONSTRAINT DF_amr_operacion DEFAULT 'U' NOT NULL,
    amr_usuario_bd                        SYSNAME            CONSTRAINT DF_amr_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    amr_fecha_cambio                      DATETIMEOFFSET (0) CONSTRAINT DF_amr_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_amr_aud_matriz_valoracion_riesgo PRIMARY KEY CLUSTERED (amr_codigo),
    CONSTRAINT FK_amr_matriz_valoracion_riesgo FOREIGN KEY (epr_codigo, eim_codigo) REFERENCES sgspi.matriz_valoracion_riesgo (epr_codigo, eim_codigo),
    CONSTRAINT FK_amr_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_amr_operacion CHECK (amr_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_amr_epr_codigo_eim_codigo
    ON sgspi.aud_matriz_valoracion_riesgo(epr_codigo, eim_codigo, amr_fecha_cambio DESC);

CREATE NONCLUSTERED INDEX IX_amr_per_codigo
    ON sgspi.aud_matriz_valoracion_riesgo(per_codigo);

-- [aea] Auditoría de [sgspi].[evento_incertidumbre_activo] ([eia])
CREATE TABLE sgspi.aud_evento_incertidumbre_activo (
    aea_codigo                   INT                IDENTITY (1, 1) NOT NULL,
    eia_codigo                   INT                NOT NULL,
    pev_codigo                   SMALLINT           NOT NULL,
    aea_numero_evento            SMALLINT           NOT NULL,
    aea_naturaleza_evento        NVARCHAR (15)      NOT NULL,
    pri_codigo                   INT                NOT NULL,
    aci_codigo_primario          INT                NOT NULL,
    aci_codigo_soporte           INT                NOT NULL,
    tac_codigo_componente        SMALLINT           NOT NULL,
    aea_fuente_generadora        NVARCHAR (255)     NOT NULL,
    aea_controles_existentes     NVARCHAR (1000)    NULL,
    aea_condicion_vulnerabilidad NVARCHAR (1000)    NOT NULL,
    aea_efecto_consecuencia      NVARCHAR (1000)    NOT NULL,
    aea_escenario_operacional    NVARCHAR (255)     NOT NULL,
    epr_codigo_inherente         TINYINT            NOT NULL,
    eim_codigo_inherente         TINYINT            NOT NULL,
    aea_estado_registro          NVARCHAR (30)      NOT NULL,
    per_codigo_creador           INT                NOT NULL,
    per_codigo_validador_lider   INT                NULL,
    per_codigo_revisor_sgspi     INT                NULL,
    per_codigo_aprobador_comite  INT                NULL,
    aea_fecha_actualizacion      DATETIMEOFFSET (0) NOT NULL,
    aea_esta_activo              BIT                NOT NULL,
    per_codigo                   INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    aea_operacion                CHAR (1)           CONSTRAINT DF_aea_operacion DEFAULT 'U' NOT NULL,
    aea_usuario_bd               SYSNAME            CONSTRAINT DF_aea_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    aea_fecha_cambio             DATETIMEOFFSET (0) CONSTRAINT DF_aea_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_aea_aud_evento_incertidumbre_activo PRIMARY KEY CLUSTERED (aea_codigo),
    CONSTRAINT FK_aea_evento_incertidumbre_activo FOREIGN KEY (eia_codigo) REFERENCES sgspi.evento_incertidumbre_activo (eia_codigo),
    CONSTRAINT FK_aea_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_aea_operacion CHECK (aea_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_aea_eia_codigo
    ON sgspi.aud_evento_incertidumbre_activo(eia_codigo, aea_fecha_cambio DESC);

CREATE NONCLUSTERED INDEX IX_aea_per_codigo
    ON sgspi.aud_evento_incertidumbre_activo(per_codigo);

-- [aet] Auditoría de [sgspi].[estrategia_tratamiento_catalogo] ([etc])
CREATE TABLE sgspi.aud_estrategia_tratamiento_catalogo (
    aet_codigo               INT                IDENTITY (1, 1) NOT NULL,
    etc_codigo               SMALLINT           NOT NULL,
    aet_nombre_estrategia    NVARCHAR (80)      NOT NULL,
    aet_naturaleza_aplicable NVARCHAR (15)      NOT NULL,
    aet_descripcion          NVARCHAR (255)     NULL,
    aet_esta_activa          BIT                NOT NULL,
    per_codigo               INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    aet_operacion            CHAR (1)           CONSTRAINT DF_aet_operacion DEFAULT 'U' NOT NULL,
    aet_usuario_bd           SYSNAME            CONSTRAINT DF_aet_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    aet_fecha_cambio         DATETIMEOFFSET (0) CONSTRAINT DF_aet_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_aet_aud_estrategia_tratamiento_catalogo PRIMARY KEY CLUSTERED (aet_codigo),
    CONSTRAINT FK_aet_estrategia_tratamiento_catalogo FOREIGN KEY (etc_codigo) REFERENCES sgspi.estrategia_tratamiento_catalogo (etc_codigo),
    CONSTRAINT FK_aet_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_aet_operacion CHECK (aet_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_aet_etc_codigo
    ON sgspi.aud_estrategia_tratamiento_catalogo(etc_codigo, aet_fecha_cambio DESC);

CREATE NONCLUSTERED INDEX IX_aet_per_codigo
    ON sgspi.aud_estrategia_tratamiento_catalogo(per_codigo);

-- [apt] Auditoría de [sgspi].[plan_tratamiento] ([plt])
CREATE TABLE sgspi.aud_plan_tratamiento (
    apt_codigo                     INT                IDENTITY (1, 1) NOT NULL,
    plt_codigo                     INT                NOT NULL,
    eia_codigo                     INT                NOT NULL,
    apt_naturaleza_evento          NVARCHAR (15)      NOT NULL,
    etc_codigo                     SMALLINT           NOT NULL,
    apt_justificacion_estrategia   NVARCHAR (1000)    NOT NULL,
    epr_codigo_residual_meta       TINYINT            NOT NULL,
    eim_codigo_residual_meta       TINYINT            NOT NULL,
    apt_fecha_inicio               DATE               NOT NULL,
    apt_fecha_fin                  DATE               NOT NULL,
    apt_recursos_humanos_tecnicos  NVARCHAR (500)     NOT NULL,
    apt_recursos_economicos_desc   NVARCHAR (500)     NOT NULL,
    apt_presupuesto_estimado_cop   DECIMAL (18, 2)    NULL,
    apt_restricciones_limitaciones NVARCHAR (500)     NULL,
    apt_nombre_indicador_kpi       NVARCHAR (255)     NOT NULL,
    apt_unidad_medida_kpi          NVARCHAR (30)      NOT NULL,
    apt_meta_indicador_kpi         DECIMAL (10, 2)    NOT NULL,
    apt_valor_alcanzado_kpi        DECIMAL (10, 2)    NULL,
    apt_es_tratamiento_eficaz      BIT                NULL,
    apt_dictamen_eficacia          NVARCHAR (1000)    NULL,
    per_codigo_evaluador           INT                NULL,
    apt_fecha_evaluacion_eficacia  DATETIMEOFFSET (0) NULL,
    apt_fecha_actualizacion        DATETIMEOFFSET (0) NOT NULL,
    apt_esta_activo                BIT                NOT NULL,
    per_codigo                     INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    apt_operacion                  CHAR (1)           CONSTRAINT DF_apt_operacion DEFAULT 'U' NOT NULL,
    apt_usuario_bd                 SYSNAME            CONSTRAINT DF_apt_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    apt_fecha_cambio               DATETIMEOFFSET (0) CONSTRAINT DF_apt_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_apt_aud_plan_tratamiento PRIMARY KEY CLUSTERED (apt_codigo),
    CONSTRAINT FK_apt_plan_tratamiento FOREIGN KEY (plt_codigo) REFERENCES sgspi.plan_tratamiento (plt_codigo),
    CONSTRAINT FK_apt_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_apt_operacion CHECK (apt_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_apt_plt_codigo
    ON sgspi.aud_plan_tratamiento(plt_codigo, apt_fecha_cambio DESC);

CREATE NONCLUSTERED INDEX IX_apt_per_codigo
    ON sgspi.aud_plan_tratamiento(per_codigo);

-- [aat] Auditoría de [sgspi].[actividad_tratamiento] ([act])
CREATE TABLE sgspi.aud_actividad_tratamiento (
    aat_codigo                INT                IDENTITY (1, 1) NOT NULL,
    act_codigo                INT                NOT NULL,
    plt_codigo                INT                NOT NULL,
    aat_numero_orden          SMALLINT           NOT NULL,
    aat_descripcion_actividad NVARCHAR (500)     NOT NULL,
    car_codigo                INT                NULL,
    uaa_codigo                INT                NULL,
    aat_fecha_compromiso      DATE               NOT NULL,
    aat_porcentaje_avance     TINYINT            NOT NULL,
    aat_estado_actividad      NVARCHAR (30)      NOT NULL,
    aat_fecha_actualizacion   DATETIMEOFFSET (0) NOT NULL,
    aat_esta_activa           BIT                NOT NULL,
    per_codigo                INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    aat_operacion             CHAR (1)           CONSTRAINT DF_aat_operacion DEFAULT 'U' NOT NULL,
    aat_usuario_bd            SYSNAME            CONSTRAINT DF_aat_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    aat_fecha_cambio          DATETIMEOFFSET (0) CONSTRAINT DF_aat_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_aat_aud_actividad_tratamiento PRIMARY KEY CLUSTERED (aat_codigo),
    CONSTRAINT FK_aat_actividad_tratamiento FOREIGN KEY (act_codigo) REFERENCES sgspi.actividad_tratamiento (act_codigo),
    CONSTRAINT FK_aat_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_aat_operacion CHECK (aat_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_aat_act_codigo
    ON sgspi.aud_actividad_tratamiento(act_codigo, aat_fecha_cambio DESC);

CREATE NONCLUSTERED INDEX IX_aat_per_codigo
    ON sgspi.aud_actividad_tratamiento(per_codigo);

-- [asa] Auditoría de [sgspi].[seguimiento_actividad] ([sga])
CREATE TABLE sgspi.aud_seguimiento_actividad (
    asa_codigo                       INT                IDENTITY (1, 1) NOT NULL,
    sga_codigo                       INT                NOT NULL,
    act_codigo                       INT                NOT NULL,
    per_codigo_autor                 INT                NOT NULL,
    asa_fecha_registro               DATETIMEOFFSET (0) NOT NULL,
    asa_porcentaje_reportado         TINYINT            NOT NULL,
    asa_descripcion_avance           NVARCHAR (1000)    NOT NULL,
    asa_nombre_archivo_evidencia     NVARCHAR (255)     NULL,
    asa_uri_almacenamiento_evidencia NVARCHAR (500)     NULL,
    asa_hash_sha256_evidencia        CHAR (64)          NULL,
    asa_esta_activo                  BIT                NOT NULL,
    per_codigo                       INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    asa_operacion                    CHAR (1)           CONSTRAINT DF_asa_operacion DEFAULT 'U' NOT NULL,
    asa_usuario_bd                   SYSNAME            CONSTRAINT DF_asa_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    asa_fecha_cambio                 DATETIMEOFFSET (0) CONSTRAINT DF_asa_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_asa_aud_seguimiento_actividad PRIMARY KEY CLUSTERED (asa_codigo),
    CONSTRAINT FK_asa_seguimiento_actividad FOREIGN KEY (sga_codigo) REFERENCES sgspi.seguimiento_actividad (sga_codigo),
    CONSTRAINT FK_asa_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_asa_operacion CHECK (asa_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_asa_sga_codigo
    ON sgspi.aud_seguimiento_actividad(sga_codigo, asa_fecha_cambio DESC);

CREATE NONCLUSTERED INDEX IX_asa_per_codigo
    ON sgspi.aud_seguimiento_actividad(per_codigo);

-- [aen] Auditoría de [sgspi].[estandar_normativo_catalogo] ([enc])
CREATE TABLE sgspi.aud_estandar_normativo_catalogo (
    aen_codigo        INT                IDENTITY (1, 1) NOT NULL,
    enc_codigo        SMALLINT           NOT NULL,
    aen_identificador NVARCHAR (50)      NOT NULL,
    aen_familia_norma NVARCHAR (20)      NOT NULL,
    aen_nombre        NVARCHAR (200)     NOT NULL,
    aen_organismo     NVARCHAR (100)     NULL,
    aen_anio_edicion  SMALLINT           NULL,
    aen_esta_activo   BIT                NOT NULL,
    per_codigo        INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    aen_operacion     CHAR (1)           CONSTRAINT DF_aen_operacion DEFAULT 'U' NOT NULL,
    aen_usuario_bd    SYSNAME            CONSTRAINT DF_aen_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    aen_fecha_cambio  DATETIMEOFFSET (0) CONSTRAINT DF_aen_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_aen_aud_estandar_normativo_catalogo PRIMARY KEY CLUSTERED (aen_codigo),
    CONSTRAINT FK_aen_estandar_normativo_catalogo FOREIGN KEY (enc_codigo) REFERENCES sgspi.estandar_normativo_catalogo (enc_codigo),
    CONSTRAINT FK_aen_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_aen_operacion CHECK (aen_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_aen_enc_codigo
    ON sgspi.aud_estandar_normativo_catalogo(enc_codigo, aen_fecha_cambio DESC);

CREATE NONCLUSTERED INDEX IX_aen_per_codigo
    ON sgspi.aud_estandar_normativo_catalogo(per_codigo);

-- [acn] Auditoría de [sgspi].[control_referencia_normativa] ([crn])
CREATE TABLE sgspi.aud_control_referencia_normativa (
    acn_codigo                INT                IDENTITY (1, 1) NOT NULL,
    crn_codigo                SMALLINT           NOT NULL,
    enc_codigo                SMALLINT           NOT NULL,
    acn_rol_privacidad_pii    NVARCHAR (20)      NULL,
    acn_identificador_control NVARCHAR (20)      NOT NULL,
    acn_nombre_control        NVARCHAR (200)     NOT NULL,
    acn_objetivo_requisito    NVARCHAR (1500)    NOT NULL,
    acn_esta_activo           BIT                NOT NULL,
    per_codigo                INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    acn_operacion             CHAR (1)           CONSTRAINT DF_acn_operacion DEFAULT 'U' NOT NULL,
    acn_usuario_bd            SYSNAME            CONSTRAINT DF_acn_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    acn_fecha_cambio          DATETIMEOFFSET (0) CONSTRAINT DF_acn_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_acn_aud_control_referencia_normativa PRIMARY KEY CLUSTERED (acn_codigo),
    CONSTRAINT FK_acn_control_referencia_normativa FOREIGN KEY (crn_codigo) REFERENCES sgspi.control_referencia_normativa (crn_codigo),
    CONSTRAINT FK_acn_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_acn_operacion CHECK (acn_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_acn_crn_codigo
    ON sgspi.aud_control_referencia_normativa(crn_codigo, acn_fecha_cambio DESC);

CREATE NONCLUSTERED INDEX IX_acn_per_codigo
    ON sgspi.aud_control_referencia_normativa(per_codigo);

-- [acc] Auditoría de [sgspi].[atributo_control_catalogo] ([aac])
CREATE TABLE sgspi.aud_atributo_control_catalogo (
    acc_codigo        INT                IDENTITY (1, 1) NOT NULL,
    aac_codigo        SMALLINT           NOT NULL,
    acc_tipo_atributo NVARCHAR (30)      NOT NULL,
    acc_valor         NVARCHAR (60)      NOT NULL,
    acc_esta_activo   BIT                NOT NULL,
    per_codigo        INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    acc_operacion     CHAR (1)           CONSTRAINT DF_acc_operacion DEFAULT 'U' NOT NULL,
    acc_usuario_bd    SYSNAME            CONSTRAINT DF_acc_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    acc_fecha_cambio  DATETIMEOFFSET (0) CONSTRAINT DF_acc_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_acc_aud_atributo_control_catalogo PRIMARY KEY CLUSTERED (acc_codigo),
    CONSTRAINT FK_acc_atributo_control_catalogo FOREIGN KEY (aac_codigo) REFERENCES sgspi.atributo_control_catalogo (aac_codigo),
    CONSTRAINT FK_acc_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_acc_operacion CHECK (acc_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_acc_aac_codigo
    ON sgspi.aud_atributo_control_catalogo(aac_codigo, acc_fecha_cambio DESC);

CREATE NONCLUSTERED INDEX IX_acc_per_codigo
    ON sgspi.aud_atributo_control_catalogo(per_codigo);

-- [aca] Auditoría de [sgspi].[control_referencia_normativa_atributo] ([cra])
CREATE TABLE sgspi.aud_control_referencia_normativa_atributo (
    aca_codigo       INT                IDENTITY (1, 1) NOT NULL,
    crn_codigo       SMALLINT           NOT NULL,
    aac_codigo       SMALLINT           NOT NULL,
    aca_esta_activo  BIT                NOT NULL,
    per_codigo       INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    aca_operacion    CHAR (1)           CONSTRAINT DF_aca_operacion DEFAULT 'U' NOT NULL,
    aca_usuario_bd   SYSNAME            CONSTRAINT DF_aca_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    aca_fecha_cambio DATETIMEOFFSET (0) CONSTRAINT DF_aca_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_aca_aud_control_referencia_normativa_atributo PRIMARY KEY CLUSTERED (aca_codigo),
    CONSTRAINT FK_aca_control_referencia_normativa_atributo FOREIGN KEY (crn_codigo, aac_codigo) REFERENCES sgspi.control_referencia_normativa_atributo (crn_codigo, aac_codigo),
    CONSTRAINT FK_aca_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_aca_operacion CHECK (aca_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_aca_crn_codigo_aac_codigo
    ON sgspi.aud_control_referencia_normativa_atributo(crn_codigo, aac_codigo, aca_fecha_cambio DESC);

CREATE NONCLUSTERED INDEX IX_aca_per_codigo
    ON sgspi.aud_control_referencia_normativa_atributo(per_codigo);

-- [acp] Auditoría de [sgspi].[plan_tratamiento_control_referencia_normativa] ([ptc])
CREATE TABLE sgspi.aud_plan_tratamiento_control_referencia_normativa (
    acp_codigo       INT                IDENTITY (1, 1) NOT NULL,
    plt_codigo       INT                NOT NULL,
    crn_codigo       SMALLINT           NOT NULL,
    acp_esta_activo  BIT                NOT NULL,
    per_codigo       INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    acp_operacion    CHAR (1)           CONSTRAINT DF_acp_operacion DEFAULT 'U' NOT NULL,
    acp_usuario_bd   SYSNAME            CONSTRAINT DF_acp_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    acp_fecha_cambio DATETIMEOFFSET (0) CONSTRAINT DF_acp_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_acp_aud_plan_tratamiento_control_referencia_normativa PRIMARY KEY CLUSTERED (acp_codigo),
    CONSTRAINT FK_acp_plan_tratamiento_control_referencia_normativa FOREIGN KEY (plt_codigo, crn_codigo) REFERENCES sgspi.plan_tratamiento_control_referencia_normativa (plt_codigo, crn_codigo),
    CONSTRAINT FK_acp_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_acp_operacion CHECK (acp_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_acp_plt_codigo_crn_codigo
    ON sgspi.aud_plan_tratamiento_control_referencia_normativa(plt_codigo, crn_codigo, acp_fecha_cambio DESC);

CREATE NONCLUSTERED INDEX IX_acp_per_codigo
    ON sgspi.aud_plan_tratamiento_control_referencia_normativa(per_codigo);

-- [aae] Auditoría de [sgspi].[evaluacion_aplicabilidad_control] ([eac])
CREATE TABLE sgspi.aud_evaluacion_aplicabilidad_control (
    aae_codigo                      INT                IDENTITY (1, 1) NOT NULL,
    eac_codigo                      INT                NOT NULL,
    pev_codigo                      SMALLINT           NOT NULL,
    crn_codigo                      SMALLINT           NOT NULL,
    aae_es_aplicable                BIT                NOT NULL,
    aae_justificacion_aplicabilidad NVARCHAR (1000)    NULL,
    aae_documento_soporte_normativo NVARCHAR (500)     NULL,
    car_codigo                      INT                NULL,
    pdc_codigo                      SMALLINT           NULL,
    aae_evidencia_objetiva_esperada NVARCHAR (500)     NULL,
    aae_estado_implementacion       NVARCHAR (20)      NULL,
    aae_observaciones_auditoria     NVARCHAR (1000)    NULL,
    aae_fecha_actualizacion         DATETIMEOFFSET (0) NOT NULL,
    aae_esta_activa                 BIT                NOT NULL,
    per_codigo                      INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    aae_operacion                   CHAR (1)           CONSTRAINT DF_aae_operacion DEFAULT 'U' NOT NULL,
    aae_usuario_bd                  SYSNAME            CONSTRAINT DF_aae_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    aae_fecha_cambio                DATETIMEOFFSET (0) CONSTRAINT DF_aae_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_aae_aud_evaluacion_aplicabilidad_control PRIMARY KEY CLUSTERED (aae_codigo),
    CONSTRAINT FK_aae_evaluacion_aplicabilidad_control FOREIGN KEY (eac_codigo) REFERENCES sgspi.evaluacion_aplicabilidad_control (eac_codigo),
    CONSTRAINT FK_aae_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_aae_operacion CHECK (aae_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_aae_eac_codigo
    ON sgspi.aud_evaluacion_aplicabilidad_control(eac_codigo, aae_fecha_cambio DESC);

CREATE NONCLUSTERED INDEX IX_aae_per_codigo
    ON sgspi.aud_evaluacion_aplicabilidad_control(per_codigo);

-- Mapa de vulnerabilidades: la clasificación queda en los metadatos y en cada evento de la auditoría del servidor (SELECT de eia)
ADD SENSITIVITY CLASSIFICATION TO sgspi.evento_incertidumbre_activo.eia_condicion_vulnerabilidad, sgspi.evento_incertidumbre_activo.eia_controles_existentes, sgspi.evento_incertidumbre_activo.eia_fuente_generadora, sgspi.aud_evento_incertidumbre_activo.aea_condicion_vulnerabilidad, sgspi.aud_evento_incertidumbre_activo.aea_controles_existentes, sgspi.aud_evento_incertidumbre_activo.aea_fuente_generadora
    WITH (LABEL = 'Confidencial', INFORMATION_TYPE = 'Vulnerabilidades de seguridad', RANK = HIGH);


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
/*==================================================================================================
5.9b ALCANCE POR PROCESO [AP-02] D5: la vista y las funciones con que los triggers limitan la escritura
Los roles líder y custodio solo escriben en los procesos de las UAA donde la persona tiene un grupo SGSPI_*
(vía proceso_institucional_uaa) y en los activos de esas UAA o asociados a esos procesos (error 50021). El oficial,
el comité, el auditor y db_owner son transversales; el gestor documental lo es solo en los activos (D9: en actividades
y seguimientos tiene el alcance del custodio, que aproxima [Asignado]). Sin uno de esos roles no hay alcance transversal.
==================================================================================================*/
-- 6.0 Vista de Integración de Seguridad y Alcance por Proceso/UAA
-- CONCAT con literales Unicode (N'')
CREATE OR ALTER VIEW sgspi.vw_usuario_rol_alcance_sgspi
AS
SELECT p.per_codigo,
       -- sin per_identificacion ni per_email_interno: la vista la lee todo sgspi_rol_base [AP-02]
       CONCAT(RTRIM(ISNULL(p.per_nombre, N'')), N' ', RTRIM(ISNULL(p.per_apellido, N''))) AS per_nombre_completo,
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
          AND piu.piu_esta_activo = 1 -- [AP-22]
       LEFT OUTER JOIN
       sgspi.proceso_institucional AS pr
       ON pr.pri_codigo = piu.pri_codigo
WHERE  ug.usg_estado = 1
       AND g.gru_estado = 1
       AND g.gru_nombre LIKE N'SGSPI[_]%'; -- D5: solo grupos del SGSPI (antes listaba todo el directorio de academia3000)


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [AP-03] Persona de la sesión (ORIGINAL_LOGIN() -> dbo.usuario_general): un solo punto de resolución para alcance y auditoría.
CREATE OR ALTER FUNCTION sgspi.ufn_persona_sesion
()
RETURNS TABLE 
AS
RETURN 
    SELECT   TOP (1) u.up AS per_codigo
    FROM     dbo.usuario_general AS u
    WHERE    u.us = CONVERT (VARCHAR (128), ORIGINAL_LOGIN()) -- si [us] es VARCHAR, la columna no se convierte y se busca por índice
    ORDER BY u.uid


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- Una fila si la sesión puede escribir en el proceso. Con @pri_codigo NULL solo hay fila si la sesión es transversal.
-- Los roles transversales van en lista explícita: un rol nuevo o un usuario sin rol de actor no lo es por omisión.
CREATE OR ALTER FUNCTION sgspi.ufn_proceso_en_alcance
(@pri_codigo INT)
RETURNS TABLE 
AS
RETURN 
    SELECT 1 AS permitido
    WHERE  ISNULL(IS_MEMBER(N'db_owner'), 0) = 1
           OR ISNULL(IS_MEMBER(N'sgspi_rol_oficial_seguridad_privacidad'), 0) = 1
           OR ISNULL(IS_MEMBER(N'sgspi_rol_comite_direccion'), 0) = 1
           OR ISNULL(IS_MEMBER(N'sgspi_rol_auditor_control'), 0) = 1
           OR EXISTS (SELECT 1
                      FROM   sgspi.vw_usuario_rol_alcance_sgspi AS v
                      WHERE  v.per_codigo = (SELECT per_codigo
                                             FROM   sgspi.ufn_persona_sesion())
                             AND v.pri_codigo = @pri_codigo)



GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- Una fila si la sesión puede escribir en el activo: es transversal (en activos también el gestor documental), el activo
-- es de una de sus UAA o está asociado (aip activa) a uno de sus procesos. Con @aci_codigo NULL solo cuenta la UAA.
CREATE OR ALTER FUNCTION sgspi.ufn_activo_en_alcance
(@aci_codigo INT, @uaa_codigo INT)
RETURNS TABLE 
AS
RETURN 
    SELECT 1 AS permitido
    WHERE  EXISTS (SELECT 1
                   FROM   sgspi.ufn_proceso_en_alcance(NULL))
           OR ISNULL(IS_MEMBER(N'sgspi_rol_gestor_documental'), 0) = 1 -- D9: avala y completa todos los activos documentales
           OR EXISTS (SELECT 1
                      FROM   sgspi.vw_usuario_rol_alcance_sgspi AS v
                      WHERE  v.per_codigo = (SELECT per_codigo
                                             FROM   sgspi.ufn_persona_sesion())
                             AND (v.uaa_codigo = @uaa_codigo
                                  OR EXISTS (SELECT 1
                                             FROM   sgspi.activo_informacion_proceso_institucional AS aip
                                             WHERE  aip.aci_codigo = @aci_codigo
                                                    AND aip.pri_codigo = v.pri_codigo
                                                    AND aip.aip_esta_activo = 1)))



GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
/*==================================================================================================
                                                                    5.10 TRIGGERS DE INTEGRIDAD: MÁQUINA DE ESTADOS DIRIGIDA POR DATOS, BORRADO LÓGICO, FECHA DE
                                                                    ACTUALIZACIÓN Y SEGUIMIENTO APPEND-ONLY
                                                                    Cada TR_<acr>_integridad_y_actualizacion: (a) impide el borrado físico (error 50010, si antes no lo rechaza la FK de su aud_* con 547); (b) en las tablas
                                                                    con flujo exige el estado inicial en INSERT (50014) y solo admite las transiciones de [tef] y la
                                                                    edición en estados con efc_permite_edicion = 1 (50011); (c) mantiene <acr>_fecha_actualizacion.
                                                                    (d) en acf, rpi, aci y eia exigen la persona de la sesión (50017), que sea el creador de lo nuevo (50019) y firman con ella (AP-03);
                                                                    (e) en acf, rpi, ado, eia y eac bloquean altas o traslados hacia una vigencia CERRADA o HISTORICA (50022, D7);
                                                                    (f) archivan las altas ('I') y la versión anterior ('U') en aud_<tabla> (AP-01); en las tablas sin estos triggers lo hace TR_<acr>_auditoria (5.10.9c).
                                                                    ==================================================================================================*/
-- 5.10.1 Trigger sobre [sgspi].[analisis_contexto_factor] ([acf])
CREATE OR ALTER TRIGGER sgspi.TR_acf_integridad_y_actualizacion
    ON sgspi.analisis_contexto_factor
    AFTER INSERT, UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           -- La actualización de la fecha que hace este mismo trigger no debe volver a validarse
           IF TRIGGER_NESTLEVEL(OBJECT_ID(N'sgspi.TR_acf_integridad_y_actualizacion', N'TR')) > 1
               RETURN;
           IF EXISTS (SELECT 1
                      FROM   deleted)
              AND NOT EXISTS (SELECT 1
                              FROM   inserted)
               THROW 50010, N'Operación denegada: No se permite eliminar físicamente registros de [sgspi].[analisis_contexto_factor].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           -- [AP-04] En INSERT el estado debe ser el inicial del dominio
           IF EXISTS (SELECT 1
                      FROM   inserted AS i
                      WHERE  NOT EXISTS (SELECT 1
                                         FROM   deleted AS d
                                         WHERE  d.acf_codigo = i.acf_codigo)
                             AND NOT EXISTS (SELECT 1
                                             FROM   sgspi.estado_flujo_catalogo AS efc
                                             WHERE  efc.efc_dominio = N'ACF'
                                                    AND efc.efc_identificador = i.acf_estado_registro
                                                    AND efc.efc_es_inicial = 1))
               THROW 50014, N'Estado inicial inválido: un registro nuevo de [sgspi].[analisis_contexto_factor] solo puede crearse en el estado inicial del flujo.', 1;
           -- [AP-03] Persona de la sesión: crea los registros nuevos y firma las aprobaciones
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona en [dbo].[usuario_general] para ORIGINAL_LOGIN().', 1;
           -- [AP-15] Un creador ajeno anularía CK_acf_sod_aprobador
           IF EXISTS (SELECT 1
                      FROM   inserted AS i
                      WHERE  NOT EXISTS (SELECT 1
                                         FROM   deleted AS d
                                         WHERE  d.acf_codigo = i.acf_codigo)
                             AND i.per_codigo_creador <> @per_actor)
               THROW 50019, N'Creador inválido: [per_codigo_creador] debe ser la persona de la sesión en [sgspi].[analisis_contexto_factor].', 1;
           -- [AP-02] D5: los roles líder y custodio solo escriben en procesos de su alcance (ufn_proceso_en_alcance)
           IF EXISTS (SELECT 1
                      FROM   (SELECT pri_codigo
                              FROM   inserted
                              UNION
                              SELECT pri_codigo
                              FROM   deleted) AS x
                             OUTER APPLY sgspi.ufn_proceso_en_alcance(x.pri_codigo) AS a
                      WHERE  a.permitido IS NULL)
               THROW 50021, N'Fuera de alcance: el proceso no está en las UAA del usuario en [sgspi].[analisis_contexto_factor].', 1;
           -- D7: no se crean registros ni se mueven a una vigencia cerrada o histórica
           IF EXISTS (SELECT 1
                      FROM   inserted AS i
                             INNER JOIN
                             sgspi.periodo_vigencia AS pev
                             ON pev.pev_codigo = i.pev_codigo
                      WHERE  pev.pev_estado_vigencia IN (N'CERRADA', N'HISTORICA')
                             AND NOT EXISTS (SELECT 1
                                             FROM   deleted AS d
                                             WHERE  d.acf_codigo = i.acf_codigo
                                                    AND d.pev_codigo = i.pev_codigo))
               THROW 50022, N'Vigencia cerrada: no se crean registros ni se mueven a una vigencia CERRADA o HISTORICA en [sgspi].[analisis_contexto_factor].', 1;
           IF EXISTS (SELECT 1
                      FROM   deleted)
               BEGIN
                   -- [AP-05] Máquina de estados dirigida por datos: sin listas de estados codificadas
                   IF EXISTS (SELECT 1
                              FROM   inserted AS i
                                     INNER JOIN
                                     deleted AS d
                                     ON d.acf_codigo = i.acf_codigo
                              WHERE  (i.acf_estado_registro = d.acf_estado_registro
                                      AND EXISTS (SELECT 1
                                                  FROM   sgspi.estado_flujo_catalogo AS efc
                                                  WHERE  efc.efc_dominio = N'ACF'
                                                         AND efc.efc_identificador = d.acf_estado_registro
                                                         AND efc.efc_permite_edicion = 0))
                                     OR (i.acf_estado_registro <> d.acf_estado_registro
                                         AND NOT EXISTS (SELECT 1
                                                         FROM   sgspi.transicion_estado_flujo AS tef
                                                         WHERE  tef.efc_dominio = N'ACF'
                                                                AND tef.efc_identificador_origen = d.acf_estado_registro
                                                                AND tef.efc_identificador_destino = i.acf_estado_registro
                                                                AND (tef.tef_rol_requerido IS NULL
                                                                     OR IS_MEMBER(tef.tef_rol_requerido) = 1
                                                                     OR IS_MEMBER(N'db_owner') = 1))))
                       THROW 50011, N'Transición inválida o intento de modificar un registro sin estado editable (VIGENTE/HISTORICO) sin reabrir revisión en [sgspi].[analisis_contexto_factor].', 1;
                   -- EXCEPT trata NULL = NULL: si cambia el estado, solo pueden cambiar el estado y las firmas (si el origen o el destino no es editable)
                   IF EXISTS (SELECT i.acf_codigo,
                                     i.pev_codigo,
                                     i.pri_codigo,
                                     i.fec_codigo,
                                     i.acf_naturaleza_factor,
                                     i.acf_numero_factor,
                                     i.acf_descripcion_situacion,
                                     i.acf_valor_prioridad,
                                     i.acf_impacto_sistema_gestion,
                                     i.acf_accion_propuesta,
                                     i.per_codigo_creador,
                                     i.acf_fecha_creacion,
                                     i.acf_fecha_actualizacion,
                                     i.acf_esta_activo
                              FROM   inserted AS i
                                     INNER JOIN
                                     deleted AS d
                                     ON d.acf_codigo = i.acf_codigo
                              WHERE  i.acf_estado_registro <> d.acf_estado_registro
                                     AND EXISTS (SELECT 1
                                                 FROM   sgspi.estado_flujo_catalogo AS efc
                                                 WHERE  efc.efc_dominio = N'ACF'
                                                        AND efc.efc_identificador IN (d.acf_estado_registro, i.acf_estado_registro)
                                                        AND efc.efc_permite_edicion = 0)
                              EXCEPT
                              SELECT d.acf_codigo,
                                     d.pev_codigo,
                                     d.pri_codigo,
                                     d.fec_codigo,
                                     d.acf_naturaleza_factor,
                                     d.acf_numero_factor,
                                     d.acf_descripcion_situacion,
                                     d.acf_valor_prioridad,
                                     d.acf_impacto_sistema_gestion,
                                     d.acf_accion_propuesta,
                                     d.per_codigo_creador,
                                     d.acf_fecha_creacion,
                                     d.acf_fecha_actualizacion,
                                     d.acf_esta_activo
                              FROM   deleted AS d
                                     INNER JOIN
                                     inserted AS i
                                     ON i.acf_codigo = d.acf_codigo
                              WHERE  i.acf_estado_registro <> d.acf_estado_registro
                                     AND EXISTS (SELECT 1
                                                 FROM   sgspi.estado_flujo_catalogo AS efc
                                                 WHERE  efc.efc_dominio = N'ACF'
                                                        AND efc.efc_identificador IN (d.acf_estado_registro, i.acf_estado_registro)
                                                        AND efc.efc_permite_edicion = 0))
                       THROW 50011, N'No se permite modificar el contenido durante una transición de estado en [sgspi].[analisis_contexto_factor].', 1;
                   -- [AP-01] Archiva la versión anterior de las filas que cambian, con quién y cuándo (ver 5.9)
                   INSERT INTO sgspi.aud_analisis_contexto_factor (
                       acf_codigo,
                       pev_codigo,
                       pri_codigo,
                       fec_codigo,
                       aaf_naturaleza_factor,
                       aaf_numero_factor,
                       aaf_descripcion_situacion,
                       aaf_valor_prioridad,
                       aaf_impacto_sistema_gestion,
                       aaf_accion_propuesta,
                       aaf_estado_registro,
                       per_codigo_creador,
                       per_codigo_aprobador,
                       aaf_fecha_actualizacion,
                       aaf_esta_activo,
                       per_codigo,
                       aaf_operacion,
                       aaf_usuario_bd,
                       aaf_fecha_cambio
                   )
                   SELECT d.acf_codigo,
                          d.pev_codigo,
                          d.pri_codigo,
                          d.fec_codigo,
                          d.acf_naturaleza_factor,
                          d.acf_numero_factor,
                          d.acf_descripcion_situacion,
                          d.acf_valor_prioridad,
                          d.acf_impacto_sistema_gestion,
                          d.acf_accion_propuesta,
                          d.acf_estado_registro,
                          d.per_codigo_creador,
                          d.per_codigo_aprobador,
                          d.acf_fecha_actualizacion,
                          d.acf_esta_activo,
                          @per_actor,
                          'U',
                          ORIGINAL_LOGIN(),
                          SYSDATETIMEOFFSET()
                   FROM   deleted AS d
                          INNER JOIN
                          inserted AS i
                          ON i.acf_codigo = d.acf_codigo
                   WHERE  EXISTS (SELECT i.pev_codigo,
                                         i.pri_codigo,
                                         i.fec_codigo,
                                         i.acf_naturaleza_factor,
                                         i.acf_numero_factor,
                                         i.acf_descripcion_situacion,
                                         i.acf_valor_prioridad,
                                         i.acf_impacto_sistema_gestion,
                                         i.acf_accion_propuesta,
                                         i.acf_estado_registro,
                                         i.per_codigo_creador,
                                         i.per_codigo_aprobador,
                                         i.acf_fecha_actualizacion,
                                         i.acf_esta_activo
                                  EXCEPT
                                  SELECT d.pev_codigo,
                                         d.pri_codigo,
                                         d.fec_codigo,
                                         d.acf_naturaleza_factor,
                                         d.acf_numero_factor,
                                         d.acf_descripcion_situacion,
                                         d.acf_valor_prioridad,
                                         d.acf_impacto_sistema_gestion,
                                         d.acf_accion_propuesta,
                                         d.acf_estado_registro,
                                         d.per_codigo_creador,
                                         d.per_codigo_aprobador,
                                         d.acf_fecha_actualizacion,
                                         d.acf_esta_activo);
                   IF NOT UPDATE (acf_fecha_actualizacion)
                       UPDATE t
                       SET    t.acf_fecha_actualizacion = SYSDATETIMEOFFSET() -- [AP-12]
                       FROM   sgspi.analisis_contexto_factor AS t
                              INNER JOIN
                              inserted AS i
                              ON i.acf_codigo = t.acf_codigo;
                   UPDATE t
                   SET    t.per_codigo_aprobador = @per_actor
                   FROM   sgspi.analisis_contexto_factor AS t
                          INNER JOIN
                          inserted AS i
                          ON i.acf_codigo = t.acf_codigo
                          INNER JOIN
                          deleted AS d
                          ON d.acf_codigo = i.acf_codigo
                   WHERE  d.acf_estado_registro <> i.acf_estado_registro
                          AND i.acf_estado_registro = N'VIGENTE';
               END
           ELSE
               INSERT INTO sgspi.aud_analisis_contexto_factor (
                   acf_codigo,
                   pev_codigo,
                   pri_codigo,
                   fec_codigo,
                   aaf_naturaleza_factor,
                   aaf_numero_factor,
                   aaf_descripcion_situacion,
                   aaf_valor_prioridad,
                   aaf_impacto_sistema_gestion,
                   aaf_accion_propuesta,
                   aaf_estado_registro,
                   per_codigo_creador,
                   per_codigo_aprobador,
                   aaf_fecha_actualizacion,
                   aaf_esta_activo,
                   per_codigo,
                   aaf_operacion,
                   aaf_usuario_bd,
                   aaf_fecha_cambio
               )
               SELECT i.acf_codigo,
                      i.pev_codigo,
                      i.pri_codigo,
                      i.fec_codigo,
                      i.acf_naturaleza_factor,
                      i.acf_numero_factor,
                      i.acf_descripcion_situacion,
                      i.acf_valor_prioridad,
                      i.acf_impacto_sistema_gestion,
                      i.acf_accion_propuesta,
                      i.acf_estado_registro,
                      i.per_codigo_creador,
                      i.per_codigo_aprobador,
                      i.acf_fecha_actualizacion,
                      i.acf_esta_activo,
                      @per_actor,
                      'I',
                      ORIGINAL_LOGIN(),
                      SYSDATETIMEOFFSET()
               FROM   inserted AS i;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- 5.10.2 Trigger sobre [sgspi].[requisito_parte_interesada] ([rpi])
CREATE OR ALTER TRIGGER sgspi.TR_rpi_integridad_y_actualizacion
    ON sgspi.requisito_parte_interesada
    AFTER INSERT, UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           IF TRIGGER_NESTLEVEL(OBJECT_ID(N'sgspi.TR_rpi_integridad_y_actualizacion', N'TR')) > 1
               RETURN;
           IF EXISTS (SELECT 1
                      FROM   deleted)
              AND NOT EXISTS (SELECT 1
                              FROM   inserted)
               THROW 50010, N'Operación denegada: No se permite eliminar físicamente registros de [sgspi].[requisito_parte_interesada].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           -- [AP-04] En INSERT el estado debe ser el inicial del dominio
           IF EXISTS (SELECT 1
                      FROM   inserted AS i
                      WHERE  NOT EXISTS (SELECT 1
                                         FROM   deleted AS d
                                         WHERE  d.rpi_codigo = i.rpi_codigo)
                             AND NOT EXISTS (SELECT 1
                                             FROM   sgspi.estado_flujo_catalogo AS efc
                                             WHERE  efc.efc_dominio = N'RPI'
                                                    AND efc.efc_identificador = i.rpi_estado_registro
                                                    AND efc.efc_es_inicial = 1))
               THROW 50014, N'Estado inicial inválido: un registro nuevo de [sgspi].[requisito_parte_interesada] solo puede crearse en el estado inicial del flujo.', 1;
           -- [AP-03] Persona de la sesión: crea los registros nuevos y firma las aprobaciones
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona en [dbo].[usuario_general] para ORIGINAL_LOGIN().', 1;
           -- [AP-15] Un creador ajeno anularía CK_rpi_sod_aprobador
           IF EXISTS (SELECT 1
                      FROM   inserted AS i
                      WHERE  NOT EXISTS (SELECT 1
                                         FROM   deleted AS d
                                         WHERE  d.rpi_codigo = i.rpi_codigo)
                             AND i.per_codigo_creador <> @per_actor)
               THROW 50019, N'Creador inválido: [per_codigo_creador] debe ser la persona de la sesión en [sgspi].[requisito_parte_interesada].', 1;
           -- D7: no se crean registros ni se mueven a una vigencia cerrada o histórica
           IF EXISTS (SELECT 1
                      FROM   inserted AS i
                             INNER JOIN
                             sgspi.periodo_vigencia AS pev
                             ON pev.pev_codigo = i.pev_codigo
                      WHERE  pev.pev_estado_vigencia IN (N'CERRADA', N'HISTORICA')
                             AND NOT EXISTS (SELECT 1
                                             FROM   deleted AS d
                                             WHERE  d.rpi_codigo = i.rpi_codigo
                                                    AND d.pev_codigo = i.pev_codigo))
               THROW 50022, N'Vigencia cerrada: no se crean registros ni se mueven a una vigencia CERRADA o HISTORICA en [sgspi].[requisito_parte_interesada].', 1;
           IF EXISTS (SELECT 1
                      FROM   deleted)
               BEGIN
                   -- [AP-05] Máquina de estados dirigida por datos: sin listas de estados codificadas
                   IF EXISTS (SELECT 1
                              FROM   inserted AS i
                                     INNER JOIN
                                     deleted AS d
                                     ON d.rpi_codigo = i.rpi_codigo
                              WHERE  (i.rpi_estado_registro = d.rpi_estado_registro
                                      AND EXISTS (SELECT 1
                                                  FROM   sgspi.estado_flujo_catalogo AS efc
                                                  WHERE  efc.efc_dominio = N'RPI'
                                                         AND efc.efc_identificador = d.rpi_estado_registro
                                                         AND efc.efc_permite_edicion = 0))
                                     OR (i.rpi_estado_registro <> d.rpi_estado_registro
                                         AND NOT EXISTS (SELECT 1
                                                         FROM   sgspi.transicion_estado_flujo AS tef
                                                         WHERE  tef.efc_dominio = N'RPI'
                                                                AND tef.efc_identificador_origen = d.rpi_estado_registro
                                                                AND tef.efc_identificador_destino = i.rpi_estado_registro
                                                                AND (tef.tef_rol_requerido IS NULL
                                                                     OR IS_MEMBER(tef.tef_rol_requerido) = 1
                                                                     OR IS_MEMBER(N'db_owner') = 1))))
                       THROW 50011, N'Transición inválida o intento de modificar un registro sin estado editable (VIGENTE/HISTORICO) sin reabrir revisión en [sgspi].[requisito_parte_interesada].', 1;
                   -- EXCEPT trata NULL = NULL: si cambia el estado, solo pueden cambiar el estado y las firmas (si el origen o el destino no es editable)
                   IF EXISTS (SELECT i.rpi_codigo,
                                     i.pev_codigo,
                                     i.pai_codigo,
                                     i.rpi_necesidad_expectativa,
                                     i.rpi_valor_poder,
                                     i.rpi_valor_interes,
                                     i.rpi_valor_cumplimiento,
                                     i.rpi_mecanismo_seguimiento,
                                     i.per_codigo_creador,
                                     i.rpi_fecha_creacion,
                                     i.rpi_fecha_actualizacion,
                                     i.rpi_esta_activo
                              FROM   inserted AS i
                                     INNER JOIN
                                     deleted AS d
                                     ON d.rpi_codigo = i.rpi_codigo
                              WHERE  i.rpi_estado_registro <> d.rpi_estado_registro
                                     AND EXISTS (SELECT 1
                                                 FROM   sgspi.estado_flujo_catalogo AS efc
                                                 WHERE  efc.efc_dominio = N'RPI'
                                                        AND efc.efc_identificador IN (d.rpi_estado_registro, i.rpi_estado_registro)
                                                        AND efc.efc_permite_edicion = 0)
                              EXCEPT
                              SELECT d.rpi_codigo,
                                     d.pev_codigo,
                                     d.pai_codigo,
                                     d.rpi_necesidad_expectativa,
                                     d.rpi_valor_poder,
                                     d.rpi_valor_interes,
                                     d.rpi_valor_cumplimiento,
                                     d.rpi_mecanismo_seguimiento,
                                     d.per_codigo_creador,
                                     d.rpi_fecha_creacion,
                                     d.rpi_fecha_actualizacion,
                                     d.rpi_esta_activo
                              FROM   deleted AS d
                                     INNER JOIN
                                     inserted AS i
                                     ON i.rpi_codigo = d.rpi_codigo
                              WHERE  i.rpi_estado_registro <> d.rpi_estado_registro
                                     AND EXISTS (SELECT 1
                                                 FROM   sgspi.estado_flujo_catalogo AS efc
                                                 WHERE  efc.efc_dominio = N'RPI'
                                                        AND efc.efc_identificador IN (d.rpi_estado_registro, i.rpi_estado_registro)
                                                        AND efc.efc_permite_edicion = 0))
                       THROW 50011, N'No se permite modificar el contenido durante una transición de estado en [sgspi].[requisito_parte_interesada].', 1;
                   -- [AP-01] Archiva la versión anterior de las filas que cambian, con quién y cuándo (ver 5.9)
                   INSERT INTO sgspi.aud_requisito_parte_interesada (
                       rpi_codigo,
                       pev_codigo,
                       pai_codigo,
                       ari_necesidad_expectativa,
                       ari_valor_poder,
                       ari_valor_interes,
                       ari_valor_cumplimiento,
                       ari_mecanismo_seguimiento,
                       ari_estado_registro,
                       per_codigo_creador,
                       per_codigo_aprobador,
                       ari_fecha_actualizacion,
                       ari_esta_activo,
                       per_codigo,
                       ari_operacion,
                       ari_usuario_bd,
                       ari_fecha_cambio
                   )
                   SELECT d.rpi_codigo,
                          d.pev_codigo,
                          d.pai_codigo,
                          d.rpi_necesidad_expectativa,
                          d.rpi_valor_poder,
                          d.rpi_valor_interes,
                          d.rpi_valor_cumplimiento,
                          d.rpi_mecanismo_seguimiento,
                          d.rpi_estado_registro,
                          d.per_codigo_creador,
                          d.per_codigo_aprobador,
                          d.rpi_fecha_actualizacion,
                          d.rpi_esta_activo,
                          @per_actor,
                          'U',
                          ORIGINAL_LOGIN(),
                          SYSDATETIMEOFFSET()
                   FROM   deleted AS d
                          INNER JOIN
                          inserted AS i
                          ON i.rpi_codigo = d.rpi_codigo
                   WHERE  EXISTS (SELECT i.pev_codigo,
                                         i.pai_codigo,
                                         i.rpi_necesidad_expectativa,
                                         i.rpi_valor_poder,
                                         i.rpi_valor_interes,
                                         i.rpi_valor_cumplimiento,
                                         i.rpi_mecanismo_seguimiento,
                                         i.rpi_estado_registro,
                                         i.per_codigo_creador,
                                         i.per_codigo_aprobador,
                                         i.rpi_fecha_actualizacion,
                                         i.rpi_esta_activo
                                  EXCEPT
                                  SELECT d.pev_codigo,
                                         d.pai_codigo,
                                         d.rpi_necesidad_expectativa,
                                         d.rpi_valor_poder,
                                         d.rpi_valor_interes,
                                         d.rpi_valor_cumplimiento,
                                         d.rpi_mecanismo_seguimiento,
                                         d.rpi_estado_registro,
                                         d.per_codigo_creador,
                                         d.per_codigo_aprobador,
                                         d.rpi_fecha_actualizacion,
                                         d.rpi_esta_activo);
                   IF NOT UPDATE (rpi_fecha_actualizacion)
                       UPDATE t
                       SET    t.rpi_fecha_actualizacion = SYSDATETIMEOFFSET() -- [AP-12]
                       FROM   sgspi.requisito_parte_interesada AS t
                              INNER JOIN
                              inserted AS i
                              ON i.rpi_codigo = t.rpi_codigo;
                   UPDATE t
                   SET    t.per_codigo_aprobador = @per_actor
                   FROM   sgspi.requisito_parte_interesada AS t
                          INNER JOIN
                          inserted AS i
                          ON i.rpi_codigo = t.rpi_codigo
                          INNER JOIN
                          deleted AS d
                          ON d.rpi_codigo = i.rpi_codigo
                   WHERE  d.rpi_estado_registro <> i.rpi_estado_registro
                          AND i.rpi_estado_registro = N'VIGENTE';
               END
           ELSE
               INSERT INTO sgspi.aud_requisito_parte_interesada (
                   rpi_codigo,
                   pev_codigo,
                   pai_codigo,
                   ari_necesidad_expectativa,
                   ari_valor_poder,
                   ari_valor_interes,
                   ari_valor_cumplimiento,
                   ari_mecanismo_seguimiento,
                   ari_estado_registro,
                   per_codigo_creador,
                   per_codigo_aprobador,
                   ari_fecha_actualizacion,
                   ari_esta_activo,
                   per_codigo,
                   ari_operacion,
                   ari_usuario_bd,
                   ari_fecha_cambio
               )
               SELECT i.rpi_codigo,
                      i.pev_codigo,
                      i.pai_codigo,
                      i.rpi_necesidad_expectativa,
                      i.rpi_valor_poder,
                      i.rpi_valor_interes,
                      i.rpi_valor_cumplimiento,
                      i.rpi_mecanismo_seguimiento,
                      i.rpi_estado_registro,
                      i.per_codigo_creador,
                      i.per_codigo_aprobador,
                      i.rpi_fecha_actualizacion,
                      i.rpi_esta_activo,
                      @per_actor,
                      'I',
                      ORIGINAL_LOGIN(),
                      SYSDATETIMEOFFSET()
               FROM   inserted AS i;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- 5.10.3 Trigger sobre [sgspi].[activo_informacion] ([aci])
CREATE OR ALTER TRIGGER sgspi.TR_aci_integridad_y_actualizacion
    ON sgspi.activo_informacion
    AFTER INSERT, UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           IF TRIGGER_NESTLEVEL(OBJECT_ID(N'sgspi.TR_aci_integridad_y_actualizacion', N'TR')) > 1
               RETURN;
           IF EXISTS (SELECT 1
                      FROM   deleted)
              AND NOT EXISTS (SELECT 1
                              FROM   inserted)
               THROW 50010, N'Operación denegada: No se permite eliminar físicamente activos en [sgspi].[activo_informacion]. Utilice los estados INACTIVO o HISTORICO.', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           -- [AP-04] En INSERT el estado debe ser el inicial del dominio
           IF EXISTS (SELECT 1
                      FROM   inserted AS i
                      WHERE  NOT EXISTS (SELECT 1
                                         FROM   deleted AS d
                                         WHERE  d.aci_codigo = i.aci_codigo)
                             AND NOT EXISTS (SELECT 1
                                             FROM   sgspi.estado_flujo_catalogo AS efc
                                             WHERE  efc.efc_dominio = N'ACI'
                                                    AND efc.efc_identificador = i.aci_estado_registro
                                                    AND efc.efc_es_inicial = 1))
               THROW 50014, N'Estado inicial inválido: un registro nuevo de [sgspi].[activo_informacion] solo puede crearse en el estado inicial del flujo.', 1;
           -- [AP-03] Persona de la sesión: crea los registros nuevos y firma las aprobaciones y la revisión de Archivo
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona en [dbo].[usuario_general] para ORIGINAL_LOGIN().', 1;
           -- [AP-15] Un creador ajeno anularía CK_aci_sod_aprobador
           IF EXISTS (SELECT 1
                      FROM   inserted AS i
                      WHERE  NOT EXISTS (SELECT 1
                                         FROM   deleted AS d
                                         WHERE  d.aci_codigo = i.aci_codigo)
                             AND i.per_codigo_creador <> @per_actor)
               THROW 50019, N'Creador inválido: [per_codigo_creador] debe ser la persona de la sesión en [sgspi].[activo_informacion].', 1;
           -- [AP-02] D5: los roles líder y custodio solo escriben activos de su alcance, antes y después del cambio de UAA
           IF EXISTS (SELECT 1
                      FROM   (SELECT aci_codigo,
                                     uaa_codigo
                              FROM   inserted
                              UNION
                              SELECT aci_codigo,
                                     uaa_codigo
                              FROM   deleted) AS x
                             OUTER APPLY sgspi.ufn_activo_en_alcance(x.aci_codigo, x.uaa_codigo) AS a
                      WHERE  a.permitido IS NULL)
               THROW 50021, N'Fuera de alcance: el activo no es de las UAA ni de los procesos del usuario en [sgspi].[activo_informacion].', 1;
           IF EXISTS (SELECT 1
                      FROM   deleted)
               BEGIN
                   -- [AP-05] Máquina de estados dirigida por datos: sin listas de estados codificadas
                   IF EXISTS (SELECT 1
                              FROM   inserted AS i
                                     INNER JOIN
                                     deleted AS d
                                     ON d.aci_codigo = i.aci_codigo
                              WHERE  (i.aci_estado_registro = d.aci_estado_registro
                                      AND EXISTS (SELECT 1
                                                  FROM   sgspi.estado_flujo_catalogo AS efc
                                                  WHERE  efc.efc_dominio = N'ACI'
                                                         AND efc.efc_identificador = d.aci_estado_registro
                                                         AND efc.efc_permite_edicion = 0))
                                     OR (i.aci_estado_registro <> d.aci_estado_registro
                                         AND NOT EXISTS (SELECT 1
                                                         FROM   sgspi.transicion_estado_flujo AS tef
                                                         WHERE  tef.efc_dominio = N'ACI'
                                                                AND tef.efc_identificador_origen = d.aci_estado_registro
                                                                AND tef.efc_identificador_destino = i.aci_estado_registro
                                                                AND (tef.tef_rol_requerido IS NULL
                                                                     OR IS_MEMBER(tef.tef_rol_requerido) = 1
                                                                     OR IS_MEMBER(N'db_owner') = 1))))
                       THROW 50011, N'Transición inválida o intento de modificar un activo no editable (VIGENTE/HISTORICO) sin reabrir revisión en [sgspi].[activo_informacion].', 1;
                   -- EXCEPT trata NULL = NULL: si cambia el estado, solo pueden cambiar el estado y las firmas (si el origen o el destino no es editable)
                   IF EXISTS (SELECT i.aci_codigo,
                                     i.aci_codigo_inventario,
                                     i.aci_nombre_activo,
                                     i.aci_descripcion_detallada,
                                     i.tac_codigo,
                                     i.uaa_codigo,
                                     i.esp_codigo,
                                     i.aci_es_transversal_sedes,
                                     i.aci_cantidad_unidades,
                                     i.aci_clasificacion_transparencia,
                                     i.cet_codigo,
                                     i.aci_alcance_excepcion,
                                     i.aci_fundamento_constitucional_legal,
                                     i.aci_fundamento_juridico_excepcion,
                                     i.aci_fecha_clasificacion_reserva,
                                     i.aci_es_reserva_indefinida,
                                     i.aci_anios_plazo_reserva,
                                     i.aci_contiene_datos_personales,
                                     i.aci_contiene_datos_menores,
                                     i.aci_categoria_dato_personal,
                                     i.aci_finalidad_recoleccion_pii,
                                     i.aci_existe_autorizacion_pii,
                                     i.aci_valor_confidencialidad,
                                     i.aci_valor_integridad,
                                     i.aci_valor_disponibilidad,
                                     i.aci_supera_umbral_social_icc,
                                     i.aci_supera_umbral_economico_icc,
                                     i.aci_supera_umbral_ambiental_icc,
                                     i.per_codigo_creador,
                                     i.aci_fecha_creacion,
                                     i.aci_fecha_actualizacion,
                                     i.aci_esta_activo
                              FROM   inserted AS i
                                     INNER JOIN
                                     deleted AS d
                                     ON d.aci_codigo = i.aci_codigo
                              WHERE  i.aci_estado_registro <> d.aci_estado_registro
                                     AND EXISTS (SELECT 1
                                                 FROM   sgspi.estado_flujo_catalogo AS efc
                                                 WHERE  efc.efc_dominio = N'ACI'
                                                        AND efc.efc_identificador IN (d.aci_estado_registro, i.aci_estado_registro)
                                                        AND efc.efc_permite_edicion = 0)
                              EXCEPT
                              SELECT d.aci_codigo,
                                     d.aci_codigo_inventario,
                                     d.aci_nombre_activo,
                                     d.aci_descripcion_detallada,
                                     d.tac_codigo,
                                     d.uaa_codigo,
                                     d.esp_codigo,
                                     d.aci_es_transversal_sedes,
                                     d.aci_cantidad_unidades,
                                     d.aci_clasificacion_transparencia,
                                     d.cet_codigo,
                                     d.aci_alcance_excepcion,
                                     d.aci_fundamento_constitucional_legal,
                                     d.aci_fundamento_juridico_excepcion,
                                     d.aci_fecha_clasificacion_reserva,
                                     d.aci_es_reserva_indefinida,
                                     d.aci_anios_plazo_reserva,
                                     d.aci_contiene_datos_personales,
                                     d.aci_contiene_datos_menores,
                                     d.aci_categoria_dato_personal,
                                     d.aci_finalidad_recoleccion_pii,
                                     d.aci_existe_autorizacion_pii,
                                     d.aci_valor_confidencialidad,
                                     d.aci_valor_integridad,
                                     d.aci_valor_disponibilidad,
                                     d.aci_supera_umbral_social_icc,
                                     d.aci_supera_umbral_economico_icc,
                                     d.aci_supera_umbral_ambiental_icc,
                                     d.per_codigo_creador,
                                     d.aci_fecha_creacion,
                                     d.aci_fecha_actualizacion,
                                     d.aci_esta_activo
                              FROM   deleted AS d
                                     INNER JOIN
                                     inserted AS i
                                     ON i.aci_codigo = d.aci_codigo
                              WHERE  i.aci_estado_registro <> d.aci_estado_registro
                                     AND EXISTS (SELECT 1
                                                 FROM   sgspi.estado_flujo_catalogo AS efc
                                                 WHERE  efc.efc_dominio = N'ACI'
                                                        AND efc.efc_identificador IN (d.aci_estado_registro, i.aci_estado_registro)
                                                        AND efc.efc_permite_edicion = 0))
                       THROW 50011, N'No se permite modificar el contenido durante una transición de estado en [sgspi].[activo_informacion].', 1;
                   -- [AP-16] D3: un activo solo se aprueba con su propietario activo (único por UX_air_propietario_activo)
                   IF EXISTS (SELECT 1
                              FROM   inserted AS i
                                     INNER JOIN
                                     deleted AS d
                                     ON d.aci_codigo = i.aci_codigo
                              WHERE  i.aci_estado_registro = N'VIGENTE'
                                     AND d.aci_estado_registro <> N'VIGENTE'
                                     AND NOT EXISTS (SELECT 1
                                                     FROM   sgspi.activo_informacion_responsable AS air WITH (UPDLOCK)
                                                     WHERE  air.aci_codigo = i.aci_codigo
                                                            AND air.air_tipo_responsabilidad = N'PROPIETARIO'
                                                            AND air.air_esta_activo = 1))
                       THROW 50020, N'Transición incompleta: VIGENTE exige un propietario activo en [sgspi].[activo_informacion_responsable].', 1;
                   -- RN-DOC-06 y RN-ACT-05: el activo documental exige aval de Archivo y todo activo exige al menos un custodio activo
                   IF EXISTS (SELECT 1
                              FROM   inserted AS i
                                     INNER JOIN
                                     deleted AS d
                                     ON d.aci_codigo = i.aci_codigo
                              WHERE  i.aci_estado_registro = N'VIGENTE'
                                     AND d.aci_estado_registro <> N'VIGENTE'
                                     AND (EXISTS (SELECT 1
                                                  FROM   sgspi.activo_documental AS ado WITH (UPDLOCK)
                                                  WHERE  ado.ado_codigo = i.aci_codigo
                                                         AND ado.ado_esta_activo = 1
                                                         AND ado.per_codigo_revisor_archivo IS NULL)
                                          OR NOT EXISTS (SELECT 1
                                                         FROM   sgspi.activo_informacion_responsable AS air WITH (UPDLOCK)
                                                         WHERE  air.aci_codigo = i.aci_codigo
                                                                AND air.air_esta_activo = 1
                                                                AND air.air_tipo_responsabilidad = N'CUSTODIO')))
                       THROW 50020, N'Transición incompleta: VIGENTE exige el aval de Archivo (activo documental) y un custodio activo en [sgspi].[activo_informacion].', 1;
                   -- [AP-01] Archiva la versión anterior de las filas que cambian, con quién y cuándo (ver 5.9)
                   INSERT INTO sgspi.aud_activo_informacion (
                       aci_codigo,
                       aai_codigo_inventario,
                       aai_nombre_activo,
                       aai_descripcion_detallada,
                       tac_codigo,
                       uaa_codigo,
                       esp_codigo,
                       aai_es_transversal_sedes,
                       aai_cantidad_unidades,
                       aai_clasificacion_transparencia,
                       cet_codigo,
                       aai_alcance_excepcion,
                       aai_fundamento_constitucional_legal,
                       aai_fundamento_juridico_excepcion,
                       aai_fecha_clasificacion_reserva,
                       aai_es_reserva_indefinida,
                       aai_anios_plazo_reserva,
                       aai_contiene_datos_personales,
                       aai_contiene_datos_menores,
                       aai_categoria_dato_personal,
                       aai_finalidad_recoleccion_pii,
                       aai_existe_autorizacion_pii,
                       aai_valor_confidencialidad,
                       aai_valor_integridad,
                       aai_valor_disponibilidad,
                       aai_supera_umbral_social_icc,
                       aai_supera_umbral_economico_icc,
                       aai_supera_umbral_ambiental_icc,
                       aai_estado_registro,
                       per_codigo_creador,
                       per_codigo_aprobador,
                       aai_fecha_actualizacion,
                       aai_esta_activo,
                       per_codigo,
                       aai_operacion,
                       aai_usuario_bd,
                       aai_fecha_cambio
                   )
                   SELECT d.aci_codigo,
                          d.aci_codigo_inventario,
                          d.aci_nombre_activo,
                          d.aci_descripcion_detallada,
                          d.tac_codigo,
                          d.uaa_codigo,
                          d.esp_codigo,
                          d.aci_es_transversal_sedes,
                          d.aci_cantidad_unidades,
                          d.aci_clasificacion_transparencia,
                          d.cet_codigo,
                          d.aci_alcance_excepcion,
                          d.aci_fundamento_constitucional_legal,
                          d.aci_fundamento_juridico_excepcion,
                          d.aci_fecha_clasificacion_reserva,
                          d.aci_es_reserva_indefinida,
                          d.aci_anios_plazo_reserva,
                          d.aci_contiene_datos_personales,
                          d.aci_contiene_datos_menores,
                          d.aci_categoria_dato_personal,
                          d.aci_finalidad_recoleccion_pii,
                          d.aci_existe_autorizacion_pii,
                          d.aci_valor_confidencialidad,
                          d.aci_valor_integridad,
                          d.aci_valor_disponibilidad,
                          d.aci_supera_umbral_social_icc,
                          d.aci_supera_umbral_economico_icc,
                          d.aci_supera_umbral_ambiental_icc,
                          d.aci_estado_registro,
                          d.per_codigo_creador,
                          d.per_codigo_aprobador,
                          d.aci_fecha_actualizacion,
                          d.aci_esta_activo,
                          @per_actor,
                          'U',
                          ORIGINAL_LOGIN(),
                          SYSDATETIMEOFFSET()
                   FROM   deleted AS d
                          INNER JOIN
                          inserted AS i
                          ON i.aci_codigo = d.aci_codigo
                   WHERE  EXISTS (SELECT i.aci_codigo_inventario,
                                         i.aci_nombre_activo,
                                         i.aci_descripcion_detallada,
                                         i.tac_codigo,
                                         i.uaa_codigo,
                                         i.esp_codigo,
                                         i.aci_es_transversal_sedes,
                                         i.aci_cantidad_unidades,
                                         i.aci_clasificacion_transparencia,
                                         i.cet_codigo,
                                         i.aci_alcance_excepcion,
                                         i.aci_fundamento_constitucional_legal,
                                         i.aci_fundamento_juridico_excepcion,
                                         i.aci_fecha_clasificacion_reserva,
                                         i.aci_es_reserva_indefinida,
                                         i.aci_anios_plazo_reserva,
                                         i.aci_contiene_datos_personales,
                                         i.aci_contiene_datos_menores,
                                         i.aci_categoria_dato_personal,
                                         i.aci_finalidad_recoleccion_pii,
                                         i.aci_existe_autorizacion_pii,
                                         i.aci_valor_confidencialidad,
                                         i.aci_valor_integridad,
                                         i.aci_valor_disponibilidad,
                                         i.aci_supera_umbral_social_icc,
                                         i.aci_supera_umbral_economico_icc,
                                         i.aci_supera_umbral_ambiental_icc,
                                         i.aci_estado_registro,
                                         i.per_codigo_creador,
                                         i.per_codigo_aprobador,
                                         i.aci_fecha_actualizacion,
                                         i.aci_esta_activo
                                  EXCEPT
                                  SELECT d.aci_codigo_inventario,
                                         d.aci_nombre_activo,
                                         d.aci_descripcion_detallada,
                                         d.tac_codigo,
                                         d.uaa_codigo,
                                         d.esp_codigo,
                                         d.aci_es_transversal_sedes,
                                         d.aci_cantidad_unidades,
                                         d.aci_clasificacion_transparencia,
                                         d.cet_codigo,
                                         d.aci_alcance_excepcion,
                                         d.aci_fundamento_constitucional_legal,
                                         d.aci_fundamento_juridico_excepcion,
                                         d.aci_fecha_clasificacion_reserva,
                                         d.aci_es_reserva_indefinida,
                                         d.aci_anios_plazo_reserva,
                                         d.aci_contiene_datos_personales,
                                         d.aci_contiene_datos_menores,
                                         d.aci_categoria_dato_personal,
                                         d.aci_finalidad_recoleccion_pii,
                                         d.aci_existe_autorizacion_pii,
                                         d.aci_valor_confidencialidad,
                                         d.aci_valor_integridad,
                                         d.aci_valor_disponibilidad,
                                         d.aci_supera_umbral_social_icc,
                                         d.aci_supera_umbral_economico_icc,
                                         d.aci_supera_umbral_ambiental_icc,
                                         d.aci_estado_registro,
                                         d.per_codigo_creador,
                                         d.per_codigo_aprobador,
                                         d.aci_fecha_actualizacion,
                                         d.aci_esta_activo);
                   IF NOT UPDATE (aci_fecha_actualizacion)
                       UPDATE t
                       SET    t.aci_fecha_actualizacion = SYSDATETIMEOFFSET() -- [AP-12]
                       FROM   sgspi.activo_informacion AS t
                              INNER JOIN
                              inserted AS i
                              ON i.aci_codigo = t.aci_codigo;
                   UPDATE t
                   SET    t.per_codigo_aprobador = @per_actor
                   FROM   sgspi.activo_informacion AS t
                          INNER JOIN
                          inserted AS i
                          ON i.aci_codigo = t.aci_codigo
                          INNER JOIN
                          deleted AS d
                          ON d.aci_codigo = i.aci_codigo
                   WHERE  d.aci_estado_registro <> i.aci_estado_registro
                          AND i.aci_estado_registro = N'VIGENTE';
                   -- Firma de Archivo: la pone el trigger al salir de EN_REVISION_ARCHIVO hacia EN_REVISION_SGSPI
                   UPDATE ado
                   SET    ado.per_codigo_revisor_archivo = @per_actor
                   FROM   sgspi.activo_documental AS ado
                          INNER JOIN
                          inserted AS i
                          ON i.aci_codigo = ado.ado_codigo
                          INNER JOIN
                          deleted AS d
                          ON d.aci_codigo = i.aci_codigo
                   WHERE  d.aci_estado_registro = N'EN_REVISION_ARCHIVO'
                          AND i.aci_estado_registro = N'EN_REVISION_SGSPI';
               END
           ELSE
               INSERT INTO sgspi.aud_activo_informacion (
                   aci_codigo,
                   aai_codigo_inventario,
                   aai_nombre_activo,
                   aai_descripcion_detallada,
                   tac_codigo,
                   uaa_codigo,
                   esp_codigo,
                   aai_es_transversal_sedes,
                   aai_cantidad_unidades,
                   aai_clasificacion_transparencia,
                   cet_codigo,
                   aai_alcance_excepcion,
                   aai_fundamento_constitucional_legal,
                   aai_fundamento_juridico_excepcion,
                   aai_fecha_clasificacion_reserva,
                   aai_es_reserva_indefinida,
                   aai_anios_plazo_reserva,
                   aai_contiene_datos_personales,
                   aai_contiene_datos_menores,
                   aai_categoria_dato_personal,
                   aai_finalidad_recoleccion_pii,
                   aai_existe_autorizacion_pii,
                   aai_valor_confidencialidad,
                   aai_valor_integridad,
                   aai_valor_disponibilidad,
                   aai_supera_umbral_social_icc,
                   aai_supera_umbral_economico_icc,
                   aai_supera_umbral_ambiental_icc,
                   aai_estado_registro,
                   per_codigo_creador,
                   per_codigo_aprobador,
                   aai_fecha_actualizacion,
                   aai_esta_activo,
                   per_codigo,
                   aai_operacion,
                   aai_usuario_bd,
                   aai_fecha_cambio
               )
               SELECT i.aci_codigo,
                      i.aci_codigo_inventario,
                      i.aci_nombre_activo,
                      i.aci_descripcion_detallada,
                      i.tac_codigo,
                      i.uaa_codigo,
                      i.esp_codigo,
                      i.aci_es_transversal_sedes,
                      i.aci_cantidad_unidades,
                      i.aci_clasificacion_transparencia,
                      i.cet_codigo,
                      i.aci_alcance_excepcion,
                      i.aci_fundamento_constitucional_legal,
                      i.aci_fundamento_juridico_excepcion,
                      i.aci_fecha_clasificacion_reserva,
                      i.aci_es_reserva_indefinida,
                      i.aci_anios_plazo_reserva,
                      i.aci_contiene_datos_personales,
                      i.aci_contiene_datos_menores,
                      i.aci_categoria_dato_personal,
                      i.aci_finalidad_recoleccion_pii,
                      i.aci_existe_autorizacion_pii,
                      i.aci_valor_confidencialidad,
                      i.aci_valor_integridad,
                      i.aci_valor_disponibilidad,
                      i.aci_supera_umbral_social_icc,
                      i.aci_supera_umbral_economico_icc,
                      i.aci_supera_umbral_ambiental_icc,
                      i.aci_estado_registro,
                      i.per_codigo_creador,
                      i.per_codigo_aprobador,
                      i.aci_fecha_actualizacion,
                      i.aci_esta_activo,
                      @per_actor,
                      'I',
                      ORIGINAL_LOGIN(),
                      SYSDATETIMEOFFSET()
               FROM   inserted AS i;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- 5.10.4 Trigger sobre [sgspi].[activo_documental] ([ado]): sin flujo propio (hereda el estado de [aci])
CREATE OR ALTER TRIGGER sgspi.TR_ado_integridad_y_actualizacion
    ON sgspi.activo_documental
    AFTER INSERT, UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           IF TRIGGER_NESTLEVEL(OBJECT_ID(N'sgspi.TR_ado_integridad_y_actualizacion', N'TR')) > 1
               RETURN;
           IF EXISTS (SELECT 1
                      FROM   deleted)
              AND NOT EXISTS (SELECT 1
                              FROM   inserted)
               THROW 50010, N'Operación denegada: No se permite eliminar físicamente activos documentales en [sgspi].[activo_documental].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           IF EXISTS (SELECT 1
                      FROM   (SELECT ado_codigo
                              FROM   inserted
                              UNION
                              SELECT ado_codigo
                              FROM   deleted) AS x
                             INNER JOIN
                             sgspi.activo_informacion AS aci WITH (UPDLOCK)
                             ON aci.aci_codigo = x.ado_codigo
                             INNER JOIN
                             sgspi.estado_flujo_catalogo AS efc
                             ON efc.efc_dominio = N'ACI'
                                AND efc.efc_identificador = aci.aci_estado_registro
                      WHERE  efc.efc_permite_edicion = 0)
               THROW 50011, N'Operación denegada: No se permite insertar ni modificar un activo documental cuyo activo de información no es editable en [sgspi].[activo_documental].', 1;
           -- La firma de Archivo la escribe TR_aci; en UPDATE la impide el DENY de columna, en INSERT esta comprobación
           IF EXISTS (SELECT 1
                      FROM   inserted AS i
                      WHERE  i.per_codigo_revisor_archivo IS NOT NULL
                             AND NOT EXISTS (SELECT 1
                                             FROM   deleted AS d
                                             WHERE  d.ado_codigo = i.ado_codigo))
               THROW 50018, N'La firma de Archivo [per_codigo_revisor_archivo] no se envía al crear el activo documental: la registra la transición EN_REVISION_ARCHIVO -> EN_REVISION_SGSPI.', 1;
           -- [AP-06] Una serie con subseries activas exige indicar la subserie (INSERT y UPDATE)
           IF EXISTS (SELECT 1
                      FROM   inserted AS i
                      WHERE  i.sbd_codigo IS NULL
                             AND EXISTS (SELECT 1
                                         FROM   sgspi.subserie_documental_catalogo AS sbd
                                         WHERE  sbd.sdo_codigo = i.sdo_codigo
                                                AND sbd.sbd_esta_activa = 1))
               THROW 50015, N'Subserie requerida: la serie documental seleccionada tiene subseries y [sbd_codigo] no puede ser NULL en [sgspi].[activo_documental].', 1;
           -- [AP-03] Persona de la sesión: queda en la auditoría
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona en [dbo].[usuario_general] para ORIGINAL_LOGIN().', 1;
           -- [AP-02] D5: los roles líder y custodio solo escriben activos de su alcance (ufn_activo_en_alcance)
           IF EXISTS (SELECT 1
                      FROM   (SELECT ado_codigo
                              FROM   inserted
                              UNION
                              SELECT ado_codigo
                              FROM   deleted) AS x
                             INNER JOIN
                             sgspi.activo_informacion AS p
                             ON p.aci_codigo = x.ado_codigo
                             OUTER APPLY sgspi.ufn_activo_en_alcance(p.aci_codigo, p.uaa_codigo) AS a
                      WHERE  a.permitido IS NULL)
               THROW 50021, N'Fuera de alcance: el activo no es de las UAA ni de los procesos del usuario en [sgspi].[activo_documental].', 1;
           -- D7: no se crean registros ni se mueven a una vigencia cerrada o histórica
           IF EXISTS (SELECT 1
                      FROM   inserted AS i
                             INNER JOIN
                             sgspi.periodo_vigencia AS pev
                             ON pev.pev_codigo = i.pev_codigo
                      WHERE  pev.pev_estado_vigencia IN (N'CERRADA', N'HISTORICA')
                             AND NOT EXISTS (SELECT 1
                                             FROM   deleted AS d
                                             WHERE  d.ado_codigo = i.ado_codigo
                                                    AND d.pev_codigo = i.pev_codigo))
               THROW 50022, N'Vigencia cerrada: no se crean registros ni se mueven a una vigencia CERRADA o HISTORICA en [sgspi].[activo_documental].', 1;
           IF EXISTS (SELECT 1
                      FROM   deleted)
               BEGIN
                   -- [AP-01] Archiva la versión anterior de las filas que cambian, con quién y cuándo (ver 5.9)
                   IF EXISTS (SELECT 1
                              FROM   deleted AS d
                              WHERE  NOT EXISTS (SELECT 1
                                                 FROM   inserted AS i
                                                 WHERE  i.ado_codigo = d.ado_codigo))
                       THROW 50011, N'Operación denegada: No se permite cambiar la clave de [sgspi].[activo_documental]; desactive la fila y cree una nueva.', 1;
                   INSERT INTO sgspi.aud_activo_documental (
                       ado_codigo,
                       pev_codigo,
                       sdo_codigo,
                       sbd_codigo,
                       pdc_codigo,
                       aao_fecha_ingreso_tabla_retencion,
                       aao_fecha_ingreso_archivo,
                       epc_codigo,
                       aao_lugar_consulta_ubicacion,
                       per_codigo_revisor_archivo,
                       aao_fecha_actualizacion,
                       aao_esta_activo,
                       per_codigo,
                       aao_operacion,
                       aao_usuario_bd,
                       aao_fecha_cambio
                   )
                   SELECT d.ado_codigo,
                          d.pev_codigo,
                          d.sdo_codigo,
                          d.sbd_codigo,
                          d.pdc_codigo,
                          d.ado_fecha_ingreso_tabla_retencion,
                          d.ado_fecha_ingreso_archivo,
                          d.epc_codigo,
                          d.ado_lugar_consulta_ubicacion,
                          d.per_codigo_revisor_archivo,
                          d.ado_fecha_actualizacion,
                          d.ado_esta_activo,
                          @per_actor,
                          'U',
                          ORIGINAL_LOGIN(),
                          SYSDATETIMEOFFSET()
                   FROM   deleted AS d
                          INNER JOIN
                          inserted AS i
                          ON i.ado_codigo = d.ado_codigo
                   WHERE  EXISTS (SELECT i.pev_codigo,
                                         i.sdo_codigo,
                                         i.sbd_codigo,
                                         i.pdc_codigo,
                                         i.ado_fecha_ingreso_tabla_retencion,
                                         i.ado_fecha_ingreso_archivo,
                                         i.epc_codigo,
                                         i.ado_lugar_consulta_ubicacion,
                                         i.per_codigo_revisor_archivo,
                                         i.ado_fecha_actualizacion,
                                         i.ado_esta_activo
                                  EXCEPT
                                  SELECT d.pev_codigo,
                                         d.sdo_codigo,
                                         d.sbd_codigo,
                                         d.pdc_codigo,
                                         d.ado_fecha_ingreso_tabla_retencion,
                                         d.ado_fecha_ingreso_archivo,
                                         d.epc_codigo,
                                         d.ado_lugar_consulta_ubicacion,
                                         d.per_codigo_revisor_archivo,
                                         d.ado_fecha_actualizacion,
                                         d.ado_esta_activo);
                   IF NOT UPDATE (ado_fecha_actualizacion)
                       UPDATE t
                       SET    t.ado_fecha_actualizacion = SYSDATETIMEOFFSET() -- [AP-11] [AP-12]
                       FROM   sgspi.activo_documental AS t
                              INNER JOIN
                              inserted AS i
                              ON i.ado_codigo = t.ado_codigo;
               END
           ELSE
               INSERT INTO sgspi.aud_activo_documental (
                   ado_codigo,
                   pev_codigo,
                   sdo_codigo,
                   sbd_codigo,
                   pdc_codigo,
                   aao_fecha_ingreso_tabla_retencion,
                   aao_fecha_ingreso_archivo,
                   epc_codigo,
                   aao_lugar_consulta_ubicacion,
                   per_codigo_revisor_archivo,
                   aao_fecha_actualizacion,
                   aao_esta_activo,
                   per_codigo,
                   aao_operacion,
                   aao_usuario_bd,
                   aao_fecha_cambio
               )
               SELECT i.ado_codigo,
                      i.pev_codigo,
                      i.sdo_codigo,
                      i.sbd_codigo,
                      i.pdc_codigo,
                      i.ado_fecha_ingreso_tabla_retencion,
                      i.ado_fecha_ingreso_archivo,
                      i.epc_codigo,
                      i.ado_lugar_consulta_ubicacion,
                      i.per_codigo_revisor_archivo,
                      i.ado_fecha_actualizacion,
                      i.ado_esta_activo,
                      @per_actor,
                      'I',
                      ORIGINAL_LOGIN(),
                      SYSDATETIMEOFFSET()
               FROM   inserted AS i;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- 5.10.5 Trigger sobre [sgspi].[evento_incertidumbre_activo] ([eia])
CREATE OR ALTER TRIGGER sgspi.TR_eia_integridad_y_actualizacion
    ON sgspi.evento_incertidumbre_activo
    AFTER INSERT, UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           IF TRIGGER_NESTLEVEL(OBJECT_ID(N'sgspi.TR_eia_integridad_y_actualizacion', N'TR')) > 1
               RETURN;
           IF EXISTS (SELECT 1
                      FROM   deleted)
              AND NOT EXISTS (SELECT 1
                              FROM   inserted)
               THROW 50010, N'Operación denegada: No se permite eliminar físicamente eventos en [sgspi].[evento_incertidumbre_activo].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           -- [AP-04] En INSERT el estado debe ser el inicial del dominio
           IF EXISTS (SELECT 1
                      FROM   inserted AS i
                      WHERE  NOT EXISTS (SELECT 1
                                         FROM   deleted AS d
                                         WHERE  d.eia_codigo = i.eia_codigo)
                             AND NOT EXISTS (SELECT 1
                                             FROM   sgspi.estado_flujo_catalogo AS efc
                                             WHERE  efc.efc_dominio = N'EIA'
                                                    AND efc.efc_identificador = i.eia_estado_registro
                                                    AND efc.efc_es_inicial = 1))
               THROW 50014, N'Estado inicial inválido: un registro nuevo de [sgspi].[evento_incertidumbre_activo] solo puede crearse en el estado inicial del flujo.', 1;
           -- [AP-03] Persona de la sesión: crea los registros nuevos y firma las validaciones y aprobaciones
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona en [dbo].[usuario_general] para ORIGINAL_LOGIN().', 1;
           -- [AP-15] Un creador ajeno anularía CK_eia_sod_firmas
           IF EXISTS (SELECT 1
                      FROM   inserted AS i
                      WHERE  NOT EXISTS (SELECT 1
                                         FROM   deleted AS d
                                         WHERE  d.eia_codigo = i.eia_codigo)
                             AND i.per_codigo_creador <> @per_actor)
               THROW 50019, N'Creador inválido: [per_codigo_creador] debe ser la persona de la sesión en [sgspi].[evento_incertidumbre_activo].', 1;
           -- [AP-02] D5: los roles líder y custodio solo escriben en procesos de su alcance (ufn_proceso_en_alcance)
           IF EXISTS (SELECT 1
                      FROM   (SELECT pri_codigo
                              FROM   inserted
                              UNION
                              SELECT pri_codigo
                              FROM   deleted) AS x
                             OUTER APPLY sgspi.ufn_proceso_en_alcance(x.pri_codigo) AS a
                      WHERE  a.permitido IS NULL)
               THROW 50021, N'Fuera de alcance: el proceso no está en las UAA del usuario en [sgspi].[evento_incertidumbre_activo].', 1;
           -- D7: no se crean registros ni se mueven a una vigencia cerrada o histórica
           IF EXISTS (SELECT 1
                      FROM   inserted AS i
                             INNER JOIN
                             sgspi.periodo_vigencia AS pev
                             ON pev.pev_codigo = i.pev_codigo
                      WHERE  pev.pev_estado_vigencia IN (N'CERRADA', N'HISTORICA')
                             AND NOT EXISTS (SELECT 1
                                             FROM   deleted AS d
                                             WHERE  d.eia_codigo = i.eia_codigo
                                                    AND d.pev_codigo = i.pev_codigo))
               THROW 50022, N'Vigencia cerrada: no se crean registros ni se mueven a una vigencia CERRADA o HISTORICA en [sgspi].[evento_incertidumbre_activo].', 1;
           IF EXISTS (SELECT 1
                      FROM   deleted)
               BEGIN
                   -- [AP-05] Máquina de estados dirigida por datos: sin listas de estados codificadas
                   IF EXISTS (SELECT 1
                              FROM   inserted AS i
                                     INNER JOIN
                                     deleted AS d
                                     ON d.eia_codigo = i.eia_codigo
                              WHERE  (i.eia_estado_registro = d.eia_estado_registro
                                      AND EXISTS (SELECT 1
                                                  FROM   sgspi.estado_flujo_catalogo AS efc
                                                  WHERE  efc.efc_dominio = N'EIA'
                                                         AND efc.efc_identificador = d.eia_estado_registro
                                                         AND efc.efc_permite_edicion = 0))
                                     OR (i.eia_estado_registro <> d.eia_estado_registro
                                         AND NOT EXISTS (SELECT 1
                                                         FROM   sgspi.transicion_estado_flujo AS tef
                                                         WHERE  tef.efc_dominio = N'EIA'
                                                                AND tef.efc_identificador_origen = d.eia_estado_registro
                                                                AND tef.efc_identificador_destino = i.eia_estado_registro
                                                                AND (tef.tef_rol_requerido IS NULL
                                                                     OR IS_MEMBER(tef.tef_rol_requerido) = 1
                                                                     OR IS_MEMBER(N'db_owner') = 1))))
                       THROW 50011, N'Transición de estado inválida o intento de alterar un evento cerrado/histórico en [sgspi].[evento_incertidumbre_activo].', 1;
                   -- EXCEPT trata NULL = NULL: si cambia el estado, solo pueden cambiar el estado y las firmas (si el origen o el destino no es editable)
                   IF EXISTS (SELECT i.eia_codigo,
                                     i.pev_codigo,
                                     i.eia_numero_evento,
                                     i.eia_naturaleza_evento,
                                     i.pri_codigo,
                                     i.aci_codigo_primario,
                                     i.aci_codigo_soporte,
                                     i.tac_codigo_componente,
                                     i.eia_fuente_generadora,
                                     i.eia_controles_existentes,
                                     i.eia_condicion_vulnerabilidad,
                                     i.eia_efecto_consecuencia,
                                     i.eia_escenario_operacional,
                                     i.epr_codigo_inherente,
                                     i.eim_codigo_inherente,
                                     i.per_codigo_creador,
                                     i.eia_fecha_creacion,
                                     i.eia_fecha_actualizacion,
                                     i.eia_esta_activo
                              FROM   inserted AS i
                                     INNER JOIN
                                     deleted AS d
                                     ON d.eia_codigo = i.eia_codigo
                              WHERE  i.eia_estado_registro <> d.eia_estado_registro
                                     AND EXISTS (SELECT 1
                                                 FROM   sgspi.estado_flujo_catalogo AS efc
                                                 WHERE  efc.efc_dominio = N'EIA'
                                                        AND efc.efc_identificador IN (d.eia_estado_registro, i.eia_estado_registro)
                                                        AND efc.efc_permite_edicion = 0)
                              EXCEPT
                              SELECT d.eia_codigo,
                                     d.pev_codigo,
                                     d.eia_numero_evento,
                                     d.eia_naturaleza_evento,
                                     d.pri_codigo,
                                     d.aci_codigo_primario,
                                     d.aci_codigo_soporte,
                                     d.tac_codigo_componente,
                                     d.eia_fuente_generadora,
                                     d.eia_controles_existentes,
                                     d.eia_condicion_vulnerabilidad,
                                     d.eia_efecto_consecuencia,
                                     d.eia_escenario_operacional,
                                     d.epr_codigo_inherente,
                                     d.eim_codigo_inherente,
                                     d.per_codigo_creador,
                                     d.eia_fecha_creacion,
                                     d.eia_fecha_actualizacion,
                                     d.eia_esta_activo
                              FROM   deleted AS d
                                     INNER JOIN
                                     inserted AS i
                                     ON i.eia_codigo = d.eia_codigo
                              WHERE  i.eia_estado_registro <> d.eia_estado_registro
                                     AND EXISTS (SELECT 1
                                                 FROM   sgspi.estado_flujo_catalogo AS efc
                                                 WHERE  efc.efc_dominio = N'EIA'
                                                        AND efc.efc_identificador IN (d.eia_estado_registro, i.eia_estado_registro)
                                                        AND efc.efc_permite_edicion = 0))
                       THROW 50011, N'No se permite modificar el contenido durante una transición de estado en [sgspi].[evento_incertidumbre_activo].', 1;
                   -- [AP-16] Requisitos de la transición (50020): plan activo para aprobar, paso por el comité cuando la celda
                   -- inherente o la residual meta lo exige (RN-RSG-03), meta residual no mayor a la inherente en RIESGO (RN-RSG-04),
                   -- control ISO27701 si el activo primario contiene datos personales (RN-RSG-05), actividades completadas para
                   -- evaluar eficacia (paso 11) y plan dictaminado eficaz para cerrar
                   IF EXISTS (SELECT 1
                              FROM   inserted AS i
                                     INNER JOIN
                                     deleted AS d
                                     ON d.eia_codigo = i.eia_codigo
                              WHERE  i.eia_estado_registro = N'APROBADO_PLANIFICADO'
                                     AND d.eia_estado_registro <> N'APROBADO_PLANIFICADO'
                                     AND NOT EXISTS (SELECT 1
                                                     FROM   sgspi.plan_tratamiento AS plt WITH (UPDLOCK)
                                                     WHERE  plt.eia_codigo = i.eia_codigo
                                                            AND plt.plt_esta_activo = 1))
                       THROW 50020, N'Transición incompleta: APROBADO_PLANIFICADO exige un plan de tratamiento activo en [sgspi].[evento_incertidumbre_activo].', 1;
                   IF EXISTS (SELECT 1
                              FROM   inserted AS i
                                     INNER JOIN
                                     deleted AS d
                                     ON d.eia_codigo = i.eia_codigo
                              WHERE  d.eia_estado_registro = N'EN_REVISION_SGSPI'
                                     AND i.eia_estado_registro = N'APROBADO_PLANIFICADO'
                                     AND EXISTS (SELECT 1
                                                 FROM   sgspi.matriz_valoracion_riesgo AS mvr
                                                 WHERE  mvr.mvr_requiere_aprobacion_comite = 1
                                                        AND ((mvr.epr_codigo = i.epr_codigo_inherente
                                                              AND mvr.eim_codigo = i.eim_codigo_inherente)
                                                             OR EXISTS (SELECT 1
                                                                        FROM   sgspi.plan_tratamiento AS plt WITH (UPDLOCK)
                                                                        WHERE  plt.eia_codigo = i.eia_codigo
                                                                               AND plt.plt_esta_activo = 1
                                                                               AND plt.epr_codigo_residual_meta = mvr.epr_codigo
                                                                               AND plt.eim_codigo_residual_meta = mvr.eim_codigo))))
                       THROW 50020, N'Transición incompleta: la celda inherente o la residual meta exige pasar por EN_ACEPTACION_COMITE antes de APROBADO_PLANIFICADO en [sgspi].[evento_incertidumbre_activo].', 1;
                   -- RN-RSG-04: en un riesgo, la valoración residual meta no puede superar la inherente
                   IF EXISTS (SELECT 1
                              FROM   inserted AS i
                                     INNER JOIN
                                     deleted AS d
                                     ON d.eia_codigo = i.eia_codigo
                                     INNER JOIN
                                     sgspi.plan_tratamiento AS plt WITH (UPDLOCK)
                                     ON plt.eia_codigo = i.eia_codigo
                                        AND plt.plt_esta_activo = 1
                              WHERE  i.eia_estado_registro = N'APROBADO_PLANIFICADO'
                                     AND d.eia_estado_registro <> N'APROBADO_PLANIFICADO'
                                     AND i.eia_naturaleza_evento = N'RIESGO'
                                     AND (plt.epr_codigo_residual_meta > i.epr_codigo_inherente
                                          OR plt.eim_codigo_residual_meta > i.eim_codigo_inherente))
                       THROW 50020, N'Transición incompleta: en un RIESGO la valoración residual meta no puede superar la inherente en [sgspi].[evento_incertidumbre_activo].', 1;
                   -- RN-RSG-05: si el activo primario contiene datos personales, el plan debe vincular al menos un control ISO27701
                   IF EXISTS (SELECT 1
                              FROM   inserted AS i
                                     INNER JOIN
                                     deleted AS d
                                     ON d.eia_codigo = i.eia_codigo
                                     INNER JOIN
                                     sgspi.activo_informacion AS aci
                                     ON aci.aci_codigo = i.aci_codigo_primario
                              WHERE  i.eia_estado_registro = N'APROBADO_PLANIFICADO'
                                     AND d.eia_estado_registro <> N'APROBADO_PLANIFICADO'
                                     AND aci.aci_contiene_datos_personales = 1
                                     AND NOT EXISTS (SELECT 1
                                                     FROM   sgspi.plan_tratamiento AS plt WITH (UPDLOCK)
                                                            INNER JOIN
                                                            sgspi.plan_tratamiento_control_referencia_normativa AS ptc WITH (UPDLOCK)
                                                            ON ptc.plt_codigo = plt.plt_codigo
                                                            INNER JOIN
                                                            sgspi.control_referencia_normativa AS crn
                                                            ON crn.crn_codigo = ptc.crn_codigo
                                                            INNER JOIN
                                                            sgspi.estandar_normativo_catalogo AS enc
                                                            ON enc.enc_codigo = crn.enc_codigo
                                                     WHERE  plt.eia_codigo = i.eia_codigo
                                                            AND plt.plt_esta_activo = 1
                                                            AND ptc.ptc_esta_activo = 1
                                                            AND enc.enc_familia_norma = N'ISO27701'))
                       THROW 50020, N'Transición incompleta: APROBADO_PLANIFICADO sobre un activo con datos personales exige un control activo de la familia ISO27701 en [sgspi].[evento_incertidumbre_activo].', 1;
                   -- Paso 11: pasar a evaluación de eficacia exige al menos una actividad activa y todas completadas
                   IF EXISTS (SELECT 1
                              FROM   inserted AS i
                                     INNER JOIN
                                     deleted AS d
                                     ON d.eia_codigo = i.eia_codigo
                              WHERE  i.eia_estado_registro = N'EN_EVALUACION_EFICACIA'
                                     AND d.eia_estado_registro <> N'EN_EVALUACION_EFICACIA'
                                     AND (NOT EXISTS (SELECT 1
                                                      FROM   sgspi.plan_tratamiento AS plt WITH (UPDLOCK)
                                                             INNER JOIN
                                                             sgspi.actividad_tratamiento AS act WITH (UPDLOCK)
                                                             ON act.plt_codigo = plt.plt_codigo
                                                      WHERE  plt.eia_codigo = i.eia_codigo
                                                             AND plt.plt_esta_activo = 1
                                                             AND act.act_esta_activa = 1)
                                          OR EXISTS (SELECT 1
                                                     FROM   sgspi.plan_tratamiento AS plt WITH (UPDLOCK)
                                                            INNER JOIN
                                                            sgspi.actividad_tratamiento AS act WITH (UPDLOCK)
                                                            ON act.plt_codigo = plt.plt_codigo
                                                     WHERE  plt.eia_codigo = i.eia_codigo
                                                            AND plt.plt_esta_activo = 1
                                                            AND act.act_esta_activa = 1
                                                            AND act.act_estado_actividad <> N'COMPLETADA')))
                       THROW 50020, N'Transición incompleta: EN_EVALUACION_EFICACIA exige un plan activo con al menos una actividad activa y todas en COMPLETADA en [sgspi].[evento_incertidumbre_activo].', 1;
                   IF EXISTS (SELECT 1
                              FROM   inserted AS i
                                     INNER JOIN
                                     deleted AS d
                                     ON d.eia_codigo = i.eia_codigo
                              WHERE  i.eia_estado_registro = N'CERRADO_EFICAZ'
                                     AND d.eia_estado_registro <> N'CERRADO_EFICAZ'
                                     AND NOT EXISTS (SELECT 1
                                                     FROM   sgspi.plan_tratamiento AS plt WITH (UPDLOCK)
                                                     WHERE  plt.eia_codigo = i.eia_codigo
                                                            AND plt.plt_esta_activo = 1
                                                            AND plt.plt_es_tratamiento_eficaz = 1))
                       THROW 50020, N'Transición incompleta: CERRADO_EFICAZ exige un plan de tratamiento dictaminado eficaz en [sgspi].[evento_incertidumbre_activo].', 1;
                   -- [AP-01] Archiva la versión anterior de las filas que cambian, con quién y cuándo (ver 5.9)
                   INSERT INTO sgspi.aud_evento_incertidumbre_activo (
                       eia_codigo,
                       pev_codigo,
                       aea_numero_evento,
                       aea_naturaleza_evento,
                       pri_codigo,
                       aci_codigo_primario,
                       aci_codigo_soporte,
                       tac_codigo_componente,
                       aea_fuente_generadora,
                       aea_controles_existentes,
                       aea_condicion_vulnerabilidad,
                       aea_efecto_consecuencia,
                       aea_escenario_operacional,
                       epr_codigo_inherente,
                       eim_codigo_inherente,
                       aea_estado_registro,
                       per_codigo_creador,
                       per_codigo_validador_lider,
                       per_codigo_revisor_sgspi,
                       per_codigo_aprobador_comite,
                       aea_fecha_actualizacion,
                       aea_esta_activo,
                       per_codigo,
                       aea_operacion,
                       aea_usuario_bd,
                       aea_fecha_cambio
                   )
                   SELECT d.eia_codigo,
                          d.pev_codigo,
                          d.eia_numero_evento,
                          d.eia_naturaleza_evento,
                          d.pri_codigo,
                          d.aci_codigo_primario,
                          d.aci_codigo_soporte,
                          d.tac_codigo_componente,
                          d.eia_fuente_generadora,
                          d.eia_controles_existentes,
                          d.eia_condicion_vulnerabilidad,
                          d.eia_efecto_consecuencia,
                          d.eia_escenario_operacional,
                          d.epr_codigo_inherente,
                          d.eim_codigo_inherente,
                          d.eia_estado_registro,
                          d.per_codigo_creador,
                          d.per_codigo_validador_lider,
                          d.per_codigo_revisor_sgspi,
                          d.per_codigo_aprobador_comite,
                          d.eia_fecha_actualizacion,
                          d.eia_esta_activo,
                          @per_actor,
                          'U',
                          ORIGINAL_LOGIN(),
                          SYSDATETIMEOFFSET()
                   FROM   deleted AS d
                          INNER JOIN
                          inserted AS i
                          ON i.eia_codigo = d.eia_codigo
                   WHERE  EXISTS (SELECT i.pev_codigo,
                                         i.eia_numero_evento,
                                         i.eia_naturaleza_evento,
                                         i.pri_codigo,
                                         i.aci_codigo_primario,
                                         i.aci_codigo_soporte,
                                         i.tac_codigo_componente,
                                         i.eia_fuente_generadora,
                                         i.eia_controles_existentes,
                                         i.eia_condicion_vulnerabilidad,
                                         i.eia_efecto_consecuencia,
                                         i.eia_escenario_operacional,
                                         i.epr_codigo_inherente,
                                         i.eim_codigo_inherente,
                                         i.eia_estado_registro,
                                         i.per_codigo_creador,
                                         i.per_codigo_validador_lider,
                                         i.per_codigo_revisor_sgspi,
                                         i.per_codigo_aprobador_comite,
                                         i.eia_fecha_actualizacion,
                                         i.eia_esta_activo
                                  EXCEPT
                                  SELECT d.pev_codigo,
                                         d.eia_numero_evento,
                                         d.eia_naturaleza_evento,
                                         d.pri_codigo,
                                         d.aci_codigo_primario,
                                         d.aci_codigo_soporte,
                                         d.tac_codigo_componente,
                                         d.eia_fuente_generadora,
                                         d.eia_controles_existentes,
                                         d.eia_condicion_vulnerabilidad,
                                         d.eia_efecto_consecuencia,
                                         d.eia_escenario_operacional,
                                         d.epr_codigo_inherente,
                                         d.eim_codigo_inherente,
                                         d.eia_estado_registro,
                                         d.per_codigo_creador,
                                         d.per_codigo_validador_lider,
                                         d.per_codigo_revisor_sgspi,
                                         d.per_codigo_aprobador_comite,
                                         d.eia_fecha_actualizacion,
                                         d.eia_esta_activo);
                   IF NOT UPDATE (eia_fecha_actualizacion)
                       UPDATE t
                       SET    t.eia_fecha_actualizacion = SYSDATETIMEOFFSET() -- [AP-11] [AP-12]
                       FROM   sgspi.evento_incertidumbre_activo AS t
                              INNER JOIN
                              inserted AS i
                              ON i.eia_codigo = t.eia_codigo;
                   UPDATE t
                   SET    t.per_codigo_validador_lider  = CASE WHEN d.eia_estado_registro = N'EN_VALIDACION_LIDER'
                                                                    AND i.eia_estado_registro = N'EN_REVISION_SGSPI' THEN @per_actor ELSE t.per_codigo_validador_lider END,
                          t.per_codigo_revisor_sgspi    = CASE WHEN d.eia_estado_registro = N'EN_REVISION_SGSPI'
                                                                    AND i.eia_estado_registro IN (N'EN_ACEPTACION_COMITE', N'APROBADO_PLANIFICADO') THEN @per_actor ELSE t.per_codigo_revisor_sgspi END,
                          t.per_codigo_aprobador_comite = CASE WHEN d.eia_estado_registro = N'EN_ACEPTACION_COMITE'
                                                                    AND i.eia_estado_registro = N'APROBADO_PLANIFICADO' THEN @per_actor ELSE t.per_codigo_aprobador_comite END
                   FROM   sgspi.evento_incertidumbre_activo AS t
                          INNER JOIN
                          inserted AS i
                          ON i.eia_codigo = t.eia_codigo
                          INNER JOIN
                          deleted AS d
                          ON d.eia_codigo = i.eia_codigo
                   WHERE  (d.eia_estado_registro = N'EN_VALIDACION_LIDER'
                           AND i.eia_estado_registro = N'EN_REVISION_SGSPI')
                          OR (d.eia_estado_registro = N'EN_REVISION_SGSPI'
                              AND i.eia_estado_registro IN (N'EN_ACEPTACION_COMITE', N'APROBADO_PLANIFICADO'))
                          OR (d.eia_estado_registro = N'EN_ACEPTACION_COMITE'
                              AND i.eia_estado_registro = N'APROBADO_PLANIFICADO');
               END
           ELSE
               INSERT INTO sgspi.aud_evento_incertidumbre_activo (
                   eia_codigo,
                   pev_codigo,
                   aea_numero_evento,
                   aea_naturaleza_evento,
                   pri_codigo,
                   aci_codigo_primario,
                   aci_codigo_soporte,
                   tac_codigo_componente,
                   aea_fuente_generadora,
                   aea_controles_existentes,
                   aea_condicion_vulnerabilidad,
                   aea_efecto_consecuencia,
                   aea_escenario_operacional,
                   epr_codigo_inherente,
                   eim_codigo_inherente,
                   aea_estado_registro,
                   per_codigo_creador,
                   per_codigo_validador_lider,
                   per_codigo_revisor_sgspi,
                   per_codigo_aprobador_comite,
                   aea_fecha_actualizacion,
                   aea_esta_activo,
                   per_codigo,
                   aea_operacion,
                   aea_usuario_bd,
                   aea_fecha_cambio
               )
               SELECT i.eia_codigo,
                      i.pev_codigo,
                      i.eia_numero_evento,
                      i.eia_naturaleza_evento,
                      i.pri_codigo,
                      i.aci_codigo_primario,
                      i.aci_codigo_soporte,
                      i.tac_codigo_componente,
                      i.eia_fuente_generadora,
                      i.eia_controles_existentes,
                      i.eia_condicion_vulnerabilidad,
                      i.eia_efecto_consecuencia,
                      i.eia_escenario_operacional,
                      i.epr_codigo_inherente,
                      i.eim_codigo_inherente,
                      i.eia_estado_registro,
                      i.per_codigo_creador,
                      i.per_codigo_validador_lider,
                      i.per_codigo_revisor_sgspi,
                      i.per_codigo_aprobador_comite,
                      i.eia_fecha_actualizacion,
                      i.eia_esta_activo,
                      @per_actor,
                      'I',
                      ORIGINAL_LOGIN(),
                      SYSDATETIMEOFFSET()
               FROM   inserted AS i;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- 5.10.6 Trigger sobre [sgspi].[plan_tratamiento] ([plt]): sin flujo propio (depende del estado de su evento [eia])
CREATE OR ALTER TRIGGER sgspi.TR_plt_integridad_y_actualizacion
    ON sgspi.plan_tratamiento
    AFTER INSERT, UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           IF TRIGGER_NESTLEVEL(OBJECT_ID(N'sgspi.TR_plt_integridad_y_actualizacion', N'TR')) > 1
               RETURN;
           IF EXISTS (SELECT 1
                      FROM   deleted)
              AND NOT EXISTS (SELECT 1
                              FROM   inserted)
               THROW 50010, N'Operación denegada: No se permite eliminar físicamente planes de tratamiento en [sgspi].[plan_tratamiento].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           IF EXISTS (SELECT 1
                      FROM   (SELECT eia_codigo
                              FROM   inserted
                              UNION
                              SELECT eia_codigo
                              FROM   deleted) AS x
                             INNER JOIN
                             sgspi.evento_incertidumbre_activo AS eia WITH (UPDLOCK)
                             ON eia.eia_codigo = x.eia_codigo
                             INNER JOIN
                             sgspi.estado_flujo_catalogo AS efc
                             ON efc.efc_dominio = N'EIA'
                                AND efc.efc_identificador = eia.eia_estado_registro
                      WHERE  efc.efc_permite_edicion = 0)
               THROW 50011, N'Operación denegada: No se permite insertar ni modificar el plan de tratamiento de un evento no editable en [sgspi].[plan_tratamiento].', 1;
           -- [AP-03] Persona de la sesión: firma el dictamen y queda en la auditoría
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona en [dbo].[usuario_general] para ORIGINAL_LOGIN().', 1;
           -- [AP-02] D5: los roles líder y custodio solo escriben en procesos de su alcance (ufn_proceso_en_alcance)
           IF EXISTS (SELECT 1
                      FROM   (SELECT eia_codigo
                              FROM   inserted
                              UNION
                              SELECT eia_codigo
                              FROM   deleted) AS x
                             INNER JOIN
                             sgspi.evento_incertidumbre_activo AS eia
                             ON eia.eia_codigo = x.eia_codigo
                             OUTER APPLY sgspi.ufn_proceso_en_alcance(eia.pri_codigo) AS a
                      WHERE  a.permitido IS NULL)
               THROW 50021, N'Fuera de alcance: el proceso del evento no está en las UAA del usuario en [sgspi].[plan_tratamiento].', 1;
           -- [AP-15] Dictamen de eficacia nuevo o cambiado (EXCEPT trata NULL = NULL): lo firma la persona de la sesión
           -- [AP-03] y su fecha es la del servidor, aunque CK_plt_coherencia_eficacia obligue al cliente a enviarla
           DECLARE @dictamen TABLE (
               plt_codigo           INT PRIMARY KEY,
               per_codigo_evaluador INT NOT NULL);
           INSERT INTO @dictamen (
               plt_codigo,
               per_codigo_evaluador
           )
           SELECT i.plt_codigo,
                  i.per_codigo_evaluador
           FROM   inserted AS i
                  LEFT OUTER JOIN
                  deleted AS d
                  ON d.plt_codigo = i.plt_codigo
           WHERE  i.per_codigo_evaluador IS NOT NULL
                  AND (d.plt_codigo IS NULL
                       OR EXISTS (SELECT i.plt_es_tratamiento_eficaz,
                                         i.plt_dictamen_eficacia,
                                         i.per_codigo_evaluador,
                                         i.plt_fecha_evaluacion_eficacia
                                  EXCEPT
                                  SELECT d.plt_es_tratamiento_eficaz,
                                         d.plt_dictamen_eficacia,
                                         d.per_codigo_evaluador,
                                         d.plt_fecha_evaluacion_eficacia));
           IF EXISTS (SELECT 1
                      FROM   @dictamen)
               BEGIN
                   -- D2: solo el auditor dictamina la eficacia; ni el líder ni el oficial evalúan el plan que ejecutan o aprobaron
                   IF ISNULL(IS_MEMBER(N'sgspi_rol_auditor_control'), 0) = 0
                      AND ISNULL(IS_MEMBER(N'db_owner'), 0) = 0
                       THROW 50011, N'Operación denegada: el dictamen de eficacia solo lo registra el auditor (sgspi_rol_auditor_control) en [sgspi].[plan_tratamiento].', 1;
                   IF EXISTS (SELECT 1
                              FROM   @dictamen
                              WHERE  per_codigo_evaluador <> @per_actor)
                       THROW 50019, N'Evaluador inválido: [per_codigo_evaluador] debe ser la persona de la sesión en [sgspi].[plan_tratamiento].', 1;
                   UPDATE t
                   SET    t.plt_fecha_evaluacion_eficacia = SYSDATETIMEOFFSET() -- [AP-12]
                   FROM   sgspi.plan_tratamiento AS t
                          INNER JOIN
                          @dictamen AS x
                          ON x.plt_codigo = t.plt_codigo;
               END
           IF EXISTS (SELECT 1
                      FROM   deleted)
               BEGIN
                   -- [AP-01] Archiva la versión anterior de las filas que cambian, con quién y cuándo (ver 5.9)
                   INSERT INTO sgspi.aud_plan_tratamiento (
                       plt_codigo,
                       eia_codigo,
                       apt_naturaleza_evento,
                       etc_codigo,
                       apt_justificacion_estrategia,
                       epr_codigo_residual_meta,
                       eim_codigo_residual_meta,
                       apt_fecha_inicio,
                       apt_fecha_fin,
                       apt_recursos_humanos_tecnicos,
                       apt_recursos_economicos_desc,
                       apt_presupuesto_estimado_cop,
                       apt_restricciones_limitaciones,
                       apt_nombre_indicador_kpi,
                       apt_unidad_medida_kpi,
                       apt_meta_indicador_kpi,
                       apt_valor_alcanzado_kpi,
                       apt_es_tratamiento_eficaz,
                       apt_dictamen_eficacia,
                       per_codigo_evaluador,
                       apt_fecha_evaluacion_eficacia,
                       apt_fecha_actualizacion,
                       apt_esta_activo,
                       per_codigo,
                       apt_operacion,
                       apt_usuario_bd,
                       apt_fecha_cambio
                   )
                   SELECT d.plt_codigo,
                          d.eia_codigo,
                          d.plt_naturaleza_evento,
                          d.etc_codigo,
                          d.plt_justificacion_estrategia,
                          d.epr_codigo_residual_meta,
                          d.eim_codigo_residual_meta,
                          d.plt_fecha_inicio,
                          d.plt_fecha_fin,
                          d.plt_recursos_humanos_tecnicos,
                          d.plt_recursos_economicos_desc,
                          d.plt_presupuesto_estimado_cop,
                          d.plt_restricciones_limitaciones,
                          d.plt_nombre_indicador_kpi,
                          d.plt_unidad_medida_kpi,
                          d.plt_meta_indicador_kpi,
                          d.plt_valor_alcanzado_kpi,
                          d.plt_es_tratamiento_eficaz,
                          d.plt_dictamen_eficacia,
                          d.per_codigo_evaluador,
                          d.plt_fecha_evaluacion_eficacia,
                          d.plt_fecha_actualizacion,
                          d.plt_esta_activo,
                          @per_actor,
                          'U',
                          ORIGINAL_LOGIN(),
                          SYSDATETIMEOFFSET()
                   FROM   deleted AS d
                          INNER JOIN
                          inserted AS i
                          ON i.plt_codigo = d.plt_codigo
                   WHERE  EXISTS (SELECT i.eia_codigo,
                                         i.plt_naturaleza_evento,
                                         i.etc_codigo,
                                         i.plt_justificacion_estrategia,
                                         i.epr_codigo_residual_meta,
                                         i.eim_codigo_residual_meta,
                                         i.plt_fecha_inicio,
                                         i.plt_fecha_fin,
                                         i.plt_recursos_humanos_tecnicos,
                                         i.plt_recursos_economicos_desc,
                                         i.plt_presupuesto_estimado_cop,
                                         i.plt_restricciones_limitaciones,
                                         i.plt_nombre_indicador_kpi,
                                         i.plt_unidad_medida_kpi,
                                         i.plt_meta_indicador_kpi,
                                         i.plt_valor_alcanzado_kpi,
                                         i.plt_es_tratamiento_eficaz,
                                         i.plt_dictamen_eficacia,
                                         i.per_codigo_evaluador,
                                         i.plt_fecha_evaluacion_eficacia,
                                         i.plt_fecha_actualizacion,
                                         i.plt_esta_activo
                                  EXCEPT
                                  SELECT d.eia_codigo,
                                         d.plt_naturaleza_evento,
                                         d.etc_codigo,
                                         d.plt_justificacion_estrategia,
                                         d.epr_codigo_residual_meta,
                                         d.eim_codigo_residual_meta,
                                         d.plt_fecha_inicio,
                                         d.plt_fecha_fin,
                                         d.plt_recursos_humanos_tecnicos,
                                         d.plt_recursos_economicos_desc,
                                         d.plt_presupuesto_estimado_cop,
                                         d.plt_restricciones_limitaciones,
                                         d.plt_nombre_indicador_kpi,
                                         d.plt_unidad_medida_kpi,
                                         d.plt_meta_indicador_kpi,
                                         d.plt_valor_alcanzado_kpi,
                                         d.plt_es_tratamiento_eficaz,
                                         d.plt_dictamen_eficacia,
                                         d.per_codigo_evaluador,
                                         d.plt_fecha_evaluacion_eficacia,
                                         d.plt_fecha_actualizacion,
                                         d.plt_esta_activo);
                   IF NOT UPDATE (plt_fecha_actualizacion)
                       UPDATE t
                       SET    t.plt_fecha_actualizacion = SYSDATETIMEOFFSET() -- [AP-12]
                       FROM   sgspi.plan_tratamiento AS t
                              INNER JOIN
                              inserted AS i
                              ON i.plt_codigo = t.plt_codigo;
               END
           ELSE
               INSERT INTO sgspi.aud_plan_tratamiento (
                   plt_codigo,
                   eia_codigo,
                   apt_naturaleza_evento,
                   etc_codigo,
                   apt_justificacion_estrategia,
                   epr_codigo_residual_meta,
                   eim_codigo_residual_meta,
                   apt_fecha_inicio,
                   apt_fecha_fin,
                   apt_recursos_humanos_tecnicos,
                   apt_recursos_economicos_desc,
                   apt_presupuesto_estimado_cop,
                   apt_restricciones_limitaciones,
                   apt_nombre_indicador_kpi,
                   apt_unidad_medida_kpi,
                   apt_meta_indicador_kpi,
                   apt_valor_alcanzado_kpi,
                   apt_es_tratamiento_eficaz,
                   apt_dictamen_eficacia,
                   per_codigo_evaluador,
                   apt_fecha_evaluacion_eficacia,
                   apt_fecha_actualizacion,
                   apt_esta_activo,
                   per_codigo,
                   apt_operacion,
                   apt_usuario_bd,
                   apt_fecha_cambio
               )
               SELECT i.plt_codigo,
                      i.eia_codigo,
                      i.plt_naturaleza_evento,
                      i.etc_codigo,
                      i.plt_justificacion_estrategia,
                      i.epr_codigo_residual_meta,
                      i.eim_codigo_residual_meta,
                      i.plt_fecha_inicio,
                      i.plt_fecha_fin,
                      i.plt_recursos_humanos_tecnicos,
                      i.plt_recursos_economicos_desc,
                      i.plt_presupuesto_estimado_cop,
                      i.plt_restricciones_limitaciones,
                      i.plt_nombre_indicador_kpi,
                      i.plt_unidad_medida_kpi,
                      i.plt_meta_indicador_kpi,
                      i.plt_valor_alcanzado_kpi,
                      i.plt_es_tratamiento_eficaz,
                      i.plt_dictamen_eficacia,
                      i.per_codigo_evaluador,
                      i.plt_fecha_evaluacion_eficacia,
                      i.plt_fecha_actualizacion,
                      i.plt_esta_activo,
                      @per_actor,
                      'I',
                      ORIGINAL_LOGIN(),
                      SYSDATETIMEOFFSET()
               FROM   inserted AS i;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- 5.10.7 Trigger sobre [sgspi].[actividad_tratamiento] ([act])
CREATE OR ALTER TRIGGER sgspi.TR_act_integridad_y_actualizacion
    ON sgspi.actividad_tratamiento
    AFTER INSERT, UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           IF TRIGGER_NESTLEVEL(OBJECT_ID(N'sgspi.TR_act_integridad_y_actualizacion', N'TR')) > 1
               RETURN;
           IF EXISTS (SELECT 1
                      FROM   deleted)
              AND NOT EXISTS (SELECT 1
                              FROM   inserted)
               THROW 50010, N'Operación denegada: No se permite eliminar físicamente actividades de tratamiento en [sgspi].[actividad_tratamiento].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           -- [AP-04] En INSERT el estado debe ser el inicial del dominio
           IF EXISTS (SELECT 1
                      FROM   inserted AS i
                      WHERE  NOT EXISTS (SELECT 1
                                         FROM   deleted AS d
                                         WHERE  d.act_codigo = i.act_codigo)
                             AND NOT EXISTS (SELECT 1
                                             FROM   sgspi.estado_flujo_catalogo AS efc
                                             WHERE  efc.efc_dominio = N'ACT'
                                                    AND efc.efc_identificador = i.act_estado_actividad
                                                    AND efc.efc_es_inicial = 1))
               THROW 50014, N'Estado inicial inválido: un registro nuevo de [sgspi].[actividad_tratamiento] solo puede crearse en el estado inicial del flujo.', 1;
           -- No se tocan actividades de un evento en estado no editable
           IF EXISTS (SELECT 1
                      FROM   (SELECT plt_codigo
                              FROM   inserted
                              UNION
                              SELECT plt_codigo
                              FROM   deleted) AS x
                             INNER JOIN
                             sgspi.plan_tratamiento AS plt WITH (UPDLOCK)
                             ON plt.plt_codigo = x.plt_codigo
                             INNER JOIN
                             sgspi.evento_incertidumbre_activo AS eia WITH (UPDLOCK)
                             ON eia.eia_codigo = plt.eia_codigo
                             INNER JOIN
                             sgspi.estado_flujo_catalogo AS efc
                             ON efc.efc_dominio = N'EIA'
                                AND efc.efc_identificador = eia.eia_estado_registro
                      WHERE  efc.efc_permite_edicion = 0)
               THROW 50011, N'Operación denegada: No se permite insertar ni modificar actividades de un evento no editable en [sgspi].[actividad_tratamiento].', 1;
           -- [AP-03] Persona de la sesión: queda en la auditoría
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona en [dbo].[usuario_general] para ORIGINAL_LOGIN().', 1;
           -- [AP-02] D5: los roles líder y custodio solo escriben en procesos de su alcance (ufn_proceso_en_alcance)
           IF EXISTS (SELECT 1
                      FROM   (SELECT plt_codigo
                              FROM   inserted
                              UNION
                              SELECT plt_codigo
                              FROM   deleted) AS x
                             INNER JOIN
                             sgspi.plan_tratamiento AS plt
                             ON plt.plt_codigo = x.plt_codigo
                             INNER JOIN
                             sgspi.evento_incertidumbre_activo AS eia
                             ON eia.eia_codigo = plt.eia_codigo
                             OUTER APPLY sgspi.ufn_proceso_en_alcance(eia.pri_codigo) AS a
                      WHERE  a.permitido IS NULL)
               THROW 50021, N'Fuera de alcance: el proceso del evento no está en las UAA del usuario en [sgspi].[actividad_tratamiento].', 1;
           IF EXISTS (SELECT 1
                      FROM   deleted)
               BEGIN
                   -- [AP-05] Máquina de estados dirigida por datos: sin listas de estados codificadas
                   IF EXISTS (SELECT 1
                              FROM   inserted AS i
                                     INNER JOIN
                                     deleted AS d
                                     ON d.act_codigo = i.act_codigo
                              WHERE  (i.act_estado_actividad = d.act_estado_actividad
                                      AND EXISTS (SELECT 1
                                                  FROM   sgspi.estado_flujo_catalogo AS efc
                                                  WHERE  efc.efc_dominio = N'ACT'
                                                         AND efc.efc_identificador = d.act_estado_actividad
                                                         AND efc.efc_permite_edicion = 0))
                                     OR (i.act_estado_actividad <> d.act_estado_actividad
                                         AND NOT EXISTS (SELECT 1
                                                         FROM   sgspi.transicion_estado_flujo AS tef
                                                         WHERE  tef.efc_dominio = N'ACT'
                                                                AND tef.efc_identificador_origen = d.act_estado_actividad
                                                                AND tef.efc_identificador_destino = i.act_estado_actividad
                                                                AND (tef.tef_rol_requerido IS NULL
                                                                     OR IS_MEMBER(tef.tef_rol_requerido) = 1
                                                                     OR IS_MEMBER(N'db_owner') = 1))))
                       THROW 50011, N'Transición de estado inválida o intento de modificar una actividad en estado no editable (COMPLETADA) en [sgspi].[actividad_tratamiento].', 1;
                   -- EXCEPT trata NULL = NULL: si cambia el estado, solo puede cambiar act_estado_actividad (si el origen o el destino no es editable)
                   IF EXISTS (SELECT i.act_codigo,
                                     i.plt_codigo,
                                     i.act_numero_orden,
                                     i.act_descripcion_actividad,
                                     i.car_codigo,
                                     i.uaa_codigo,
                                     i.act_fecha_compromiso,
                                     i.act_porcentaje_avance,
                                     i.act_fecha_creacion,
                                     i.act_fecha_actualizacion,
                                     i.act_esta_activa
                              FROM   inserted AS i
                                     INNER JOIN
                                     deleted AS d
                                     ON d.act_codigo = i.act_codigo
                              WHERE  i.act_estado_actividad <> d.act_estado_actividad
                                     AND EXISTS (SELECT 1
                                                 FROM   sgspi.estado_flujo_catalogo AS efc
                                                 WHERE  efc.efc_dominio = N'ACT'
                                                        AND efc.efc_identificador IN (d.act_estado_actividad, i.act_estado_actividad)
                                                        AND efc.efc_permite_edicion = 0)
                              EXCEPT
                              SELECT d.act_codigo,
                                     d.plt_codigo,
                                     d.act_numero_orden,
                                     d.act_descripcion_actividad,
                                     d.car_codigo,
                                     d.uaa_codigo,
                                     d.act_fecha_compromiso,
                                     d.act_porcentaje_avance,
                                     d.act_fecha_creacion,
                                     d.act_fecha_actualizacion,
                                     d.act_esta_activa
                              FROM   deleted AS d
                                     INNER JOIN
                                     inserted AS i
                                     ON i.act_codigo = d.act_codigo
                              WHERE  i.act_estado_actividad <> d.act_estado_actividad
                                     AND EXISTS (SELECT 1
                                                 FROM   sgspi.estado_flujo_catalogo AS efc
                                                 WHERE  efc.efc_dominio = N'ACT'
                                                        AND efc.efc_identificador IN (d.act_estado_actividad, i.act_estado_actividad)
                                                        AND efc.efc_permite_edicion = 0))
                       THROW 50011, N'No se permite modificar el contenido durante una transición de estado en [sgspi].[actividad_tratamiento].', 1;
                   -- [AP-01] Archiva la versión anterior de las filas que cambian, con quién y cuándo (ver 5.9)
                   INSERT INTO sgspi.aud_actividad_tratamiento (
                       act_codigo,
                       plt_codigo,
                       aat_numero_orden,
                       aat_descripcion_actividad,
                       car_codigo,
                       uaa_codigo,
                       aat_fecha_compromiso,
                       aat_porcentaje_avance,
                       aat_estado_actividad,
                       aat_fecha_actualizacion,
                       aat_esta_activa,
                       per_codigo,
                       aat_operacion,
                       aat_usuario_bd,
                       aat_fecha_cambio
                   )
                   SELECT d.act_codigo,
                          d.plt_codigo,
                          d.act_numero_orden,
                          d.act_descripcion_actividad,
                          d.car_codigo,
                          d.uaa_codigo,
                          d.act_fecha_compromiso,
                          d.act_porcentaje_avance,
                          d.act_estado_actividad,
                          d.act_fecha_actualizacion,
                          d.act_esta_activa,
                          @per_actor,
                          'U',
                          ORIGINAL_LOGIN(),
                          SYSDATETIMEOFFSET()
                   FROM   deleted AS d
                          INNER JOIN
                          inserted AS i
                          ON i.act_codigo = d.act_codigo
                   WHERE  EXISTS (SELECT i.plt_codigo,
                                         i.act_numero_orden,
                                         i.act_descripcion_actividad,
                                         i.car_codigo,
                                         i.uaa_codigo,
                                         i.act_fecha_compromiso,
                                         i.act_porcentaje_avance,
                                         i.act_estado_actividad,
                                         i.act_fecha_actualizacion,
                                         i.act_esta_activa
                                  EXCEPT
                                  SELECT d.plt_codigo,
                                         d.act_numero_orden,
                                         d.act_descripcion_actividad,
                                         d.car_codigo,
                                         d.uaa_codigo,
                                         d.act_fecha_compromiso,
                                         d.act_porcentaje_avance,
                                         d.act_estado_actividad,
                                         d.act_fecha_actualizacion,
                                         d.act_esta_activa);
                   IF NOT UPDATE (act_fecha_actualizacion)
                       UPDATE t
                       SET    t.act_fecha_actualizacion = SYSDATETIMEOFFSET() -- [AP-12]
                       FROM   sgspi.actividad_tratamiento AS t
                              INNER JOIN
                              inserted AS i
                              ON i.act_codigo = t.act_codigo;
               END
           ELSE
               INSERT INTO sgspi.aud_actividad_tratamiento (
                   act_codigo,
                   plt_codigo,
                   aat_numero_orden,
                   aat_descripcion_actividad,
                   car_codigo,
                   uaa_codigo,
                   aat_fecha_compromiso,
                   aat_porcentaje_avance,
                   aat_estado_actividad,
                   aat_fecha_actualizacion,
                   aat_esta_activa,
                   per_codigo,
                   aat_operacion,
                   aat_usuario_bd,
                   aat_fecha_cambio
               )
               SELECT i.act_codigo,
                      i.plt_codigo,
                      i.act_numero_orden,
                      i.act_descripcion_actividad,
                      i.car_codigo,
                      i.uaa_codigo,
                      i.act_fecha_compromiso,
                      i.act_porcentaje_avance,
                      i.act_estado_actividad,
                      i.act_fecha_actualizacion,
                      i.act_esta_activa,
                      @per_actor,
                      'I',
                      ORIGINAL_LOGIN(),
                      SYSDATETIMEOFFSET()
               FROM   inserted AS i;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- 5.10.8 Trigger sobre [sgspi].[evaluacion_aplicabilidad_control] ([eac]): sin flujo de estados
CREATE OR ALTER TRIGGER sgspi.TR_eac_integridad_y_actualizacion
    ON sgspi.evaluacion_aplicabilidad_control
    AFTER INSERT, UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           IF TRIGGER_NESTLEVEL(OBJECT_ID(N'sgspi.TR_eac_integridad_y_actualizacion', N'TR')) > 1
               RETURN;
           IF EXISTS (SELECT 1
                      FROM   deleted)
              AND NOT EXISTS (SELECT 1
                              FROM   inserted)
               THROW 50010, N'Operación denegada: No se permite eliminar físicamente evaluaciones de aplicabilidad (SoA) en [sgspi].[evaluacion_aplicabilidad_control].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           -- [AP-03] Persona de la sesión: queda en la auditoría
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona en [dbo].[usuario_general] para ORIGINAL_LOGIN().', 1;
           -- D7: no se crean registros ni se mueven a una vigencia cerrada o histórica
           IF EXISTS (SELECT 1
                      FROM   inserted AS i
                             INNER JOIN
                             sgspi.periodo_vigencia AS pev
                             ON pev.pev_codigo = i.pev_codigo
                      WHERE  pev.pev_estado_vigencia IN (N'CERRADA', N'HISTORICA')
                             AND NOT EXISTS (SELECT 1
                                             FROM   deleted AS d
                                             WHERE  d.eac_codigo = i.eac_codigo
                                                    AND d.pev_codigo = i.pev_codigo))
               THROW 50022, N'Vigencia cerrada: no se crean registros ni se mueven a una vigencia CERRADA o HISTORICA en [sgspi].[evaluacion_aplicabilidad_control].', 1;
           IF EXISTS (SELECT 1
                      FROM   deleted)
               BEGIN
                   -- [AP-01] Archiva la versión anterior de las filas que cambian, con quién y cuándo (ver 5.9)
                   INSERT INTO sgspi.aud_evaluacion_aplicabilidad_control (
                       eac_codigo,
                       pev_codigo,
                       crn_codigo,
                       aae_es_aplicable,
                       aae_justificacion_aplicabilidad,
                       aae_documento_soporte_normativo,
                       car_codigo,
                       pdc_codigo,
                       aae_evidencia_objetiva_esperada,
                       aae_estado_implementacion,
                       aae_observaciones_auditoria,
                       aae_fecha_actualizacion,
                       aae_esta_activa,
                       per_codigo,
                       aae_operacion,
                       aae_usuario_bd,
                       aae_fecha_cambio
                   )
                   SELECT d.eac_codigo,
                          d.pev_codigo,
                          d.crn_codigo,
                          d.eac_es_aplicable,
                          d.eac_justificacion_aplicabilidad,
                          d.eac_documento_soporte_normativo,
                          d.car_codigo,
                          d.pdc_codigo,
                          d.eac_evidencia_objetiva_esperada,
                          d.eac_estado_implementacion,
                          d.eac_observaciones_auditoria,
                          d.eac_fecha_actualizacion,
                          d.eac_esta_activa,
                          @per_actor,
                          'U',
                          ORIGINAL_LOGIN(),
                          SYSDATETIMEOFFSET()
                   FROM   deleted AS d
                          INNER JOIN
                          inserted AS i
                          ON i.eac_codigo = d.eac_codigo
                   WHERE  EXISTS (SELECT i.pev_codigo,
                                         i.crn_codigo,
                                         i.eac_es_aplicable,
                                         i.eac_justificacion_aplicabilidad,
                                         i.eac_documento_soporte_normativo,
                                         i.car_codigo,
                                         i.pdc_codigo,
                                         i.eac_evidencia_objetiva_esperada,
                                         i.eac_estado_implementacion,
                                         i.eac_observaciones_auditoria,
                                         i.eac_fecha_actualizacion,
                                         i.eac_esta_activa
                                  EXCEPT
                                  SELECT d.pev_codigo,
                                         d.crn_codigo,
                                         d.eac_es_aplicable,
                                         d.eac_justificacion_aplicabilidad,
                                         d.eac_documento_soporte_normativo,
                                         d.car_codigo,
                                         d.pdc_codigo,
                                         d.eac_evidencia_objetiva_esperada,
                                         d.eac_estado_implementacion,
                                         d.eac_observaciones_auditoria,
                                         d.eac_fecha_actualizacion,
                                         d.eac_esta_activa);
                   IF NOT UPDATE (eac_fecha_actualizacion)
                       UPDATE t
                       SET    t.eac_fecha_actualizacion = SYSDATETIMEOFFSET() -- [AP-11] [AP-12]
                       FROM   sgspi.evaluacion_aplicabilidad_control AS t
                              INNER JOIN
                              inserted AS i
                              ON i.eac_codigo = t.eac_codigo;
               END
           ELSE
               INSERT INTO sgspi.aud_evaluacion_aplicabilidad_control (
                   eac_codigo,
                   pev_codigo,
                   crn_codigo,
                   aae_es_aplicable,
                   aae_justificacion_aplicabilidad,
                   aae_documento_soporte_normativo,
                   car_codigo,
                   pdc_codigo,
                   aae_evidencia_objetiva_esperada,
                   aae_estado_implementacion,
                   aae_observaciones_auditoria,
                   aae_fecha_actualizacion,
                   aae_esta_activa,
                   per_codigo,
                   aae_operacion,
                   aae_usuario_bd,
                   aae_fecha_cambio
               )
               SELECT i.eac_codigo,
                      i.pev_codigo,
                      i.crn_codigo,
                      i.eac_es_aplicable,
                      i.eac_justificacion_aplicabilidad,
                      i.eac_documento_soporte_normativo,
                      i.car_codigo,
                      i.pdc_codigo,
                      i.eac_evidencia_objetiva_esperada,
                      i.eac_estado_implementacion,
                      i.eac_observaciones_auditoria,
                      i.eac_fecha_actualizacion,
                      i.eac_esta_activa,
                      @per_actor,
                      'I',
                      ORIGINAL_LOGIN(),
                      SYSDATETIMEOFFSET()
               FROM   inserted AS i;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- 5.10.9 Triggers sobre [sgspi].[seguimiento_actividad] ([sga]) [AP-16]
-- Inmutabilidad: el seguimiento con evidencia es append-only; solo admite el borrado lógico (sga_esta_activo) [AP-22]
CREATE OR ALTER TRIGGER sgspi.TR_sga_inmutabilidad
    ON sgspi.seguimiento_actividad
    AFTER UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           -- EXCEPT trata NULL = NULL: cualquier diferencia fuera de sga_esta_activo es una edición prohibida
           IF (EXISTS (SELECT 1
                       FROM   deleted)
               AND NOT EXISTS (SELECT 1
                               FROM   inserted))
              OR EXISTS (SELECT sga_codigo,
                                act_codigo,
                                per_codigo,
                                sga_fecha_registro,
                                sga_porcentaje_reportado,
                                sga_descripcion_avance,
                                sga_nombre_archivo_evidencia,
                                sga_uri_almacenamiento_evidencia,
                                sga_hash_sha256_evidencia
                         FROM   inserted
                         EXCEPT
                         SELECT sga_codigo,
                                act_codigo,
                                per_codigo,
                                sga_fecha_registro,
                                sga_porcentaje_reportado,
                                sga_descripcion_avance,
                                sga_nombre_archivo_evidencia,
                                sga_uri_almacenamiento_evidencia,
                                sga_hash_sha256_evidencia
                         FROM   deleted)
               THROW 50016, N'Operación denegada: el seguimiento de actividades con evidencia es append-only (solo se puede desactivar con sga_esta_activo = 0); registre un nuevo seguimiento en [sgspi].[seguimiento_actividad].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           -- [AP-03] Persona de la sesión: queda en la auditoría
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona en [dbo].[usuario_general] para ORIGINAL_LOGIN().', 1;
           -- [AP-02] D5: los roles líder y custodio solo desactivan seguimientos de procesos de su alcance
           IF EXISTS (SELECT 1
                      FROM   inserted AS x
                             INNER JOIN
                             sgspi.actividad_tratamiento AS act
                             ON act.act_codigo = x.act_codigo
                             INNER JOIN
                             sgspi.plan_tratamiento AS plt
                             ON plt.plt_codigo = act.plt_codigo
                             INNER JOIN
                             sgspi.evento_incertidumbre_activo AS eia
                             ON eia.eia_codigo = plt.eia_codigo
                             OUTER APPLY sgspi.ufn_proceso_en_alcance(eia.pri_codigo) AS a
                      WHERE  a.permitido IS NULL)
               THROW 50021, N'Fuera de alcance: el proceso del evento no está en las UAA del usuario en [sgspi].[seguimiento_actividad].', 1;
           -- [AP-01] Archiva la versión anterior de las filas que cambian, con quién y cuándo (ver 5.9)
           INSERT INTO sgspi.aud_seguimiento_actividad (
               sga_codigo,
               act_codigo,
               per_codigo_autor,
               asa_fecha_registro,
               asa_porcentaje_reportado,
               asa_descripcion_avance,
               asa_nombre_archivo_evidencia,
               asa_uri_almacenamiento_evidencia,
               asa_hash_sha256_evidencia,
               asa_esta_activo,
               per_codigo,
               asa_operacion,
               asa_usuario_bd,
               asa_fecha_cambio
           )
           SELECT d.sga_codigo,
                  d.act_codigo,
                  d.per_codigo,
                  d.sga_fecha_registro,
                  d.sga_porcentaje_reportado,
                  d.sga_descripcion_avance,
                  d.sga_nombre_archivo_evidencia,
                  d.sga_uri_almacenamiento_evidencia,
                  d.sga_hash_sha256_evidencia,
                  d.sga_esta_activo,
                  @per_actor,
                  'U',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   deleted AS d
                  INNER JOIN
                  inserted AS i
                  ON i.sga_codigo = d.sga_codigo
           WHERE  EXISTS (SELECT i.act_codigo,
                                 i.per_codigo,
                                 i.sga_fecha_registro,
                                 i.sga_porcentaje_reportado,
                                 i.sga_descripcion_avance,
                                 i.sga_nombre_archivo_evidencia,
                                 i.sga_uri_almacenamiento_evidencia,
                                 i.sga_hash_sha256_evidencia,
                                 i.sga_esta_activo
                          EXCEPT
                          SELECT d.act_codigo,
                                 d.per_codigo,
                                 d.sga_fecha_registro,
                                 d.sga_porcentaje_reportado,
                                 d.sga_descripcion_avance,
                                 d.sga_nombre_archivo_evidencia,
                                 d.sga_uri_almacenamiento_evidencia,
                                 d.sga_hash_sha256_evidencia,
                                 d.sga_esta_activo);
           -- [AP-09] Al desactivar o reactivar un seguimiento, recalcula el avance con el último seguimiento activo (0 si no queda ninguno)
           UPDATE act
           SET    act.act_porcentaje_avance = ISNULL(u.sga_porcentaje_reportado, 0)
           FROM   sgspi.actividad_tratamiento AS act
                  INNER JOIN
                  (SELECT DISTINCT i.act_codigo
                   FROM   inserted AS i
                          INNER JOIN
                          deleted AS d
                          ON d.sga_codigo = i.sga_codigo
                   WHERE  i.sga_esta_activo <> d.sga_esta_activo) AS x
                  ON x.act_codigo = act.act_codigo
                  OUTER APPLY (SELECT   TOP (1) s.sga_porcentaje_reportado
                               FROM     sgspi.seguimiento_actividad AS s
                               WHERE    s.act_codigo = act.act_codigo
                                        AND s.sga_esta_activo = 1
                               ORDER BY s.sga_codigo DESC) AS u
           WHERE  act.act_porcentaje_avance <> ISNULL(u.sga_porcentaje_reportado, 0);
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [AP-09] El avance de la actividad deja de ser un dato duplicado y desincronizado: se deriva del último seguimiento reportado.
-- El UPDATE sobre [act] dispara TR_act_integridad_y_actualizacion (aplica sus reglas de estado): es lo deseado.
CREATE OR ALTER TRIGGER sgspi.TR_sga_sincronizar_avance
    ON sgspi.seguimiento_actividad
    AFTER INSERT
    AS BEGIN
           SET NOCOUNT ON;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           -- [AP-03] [AP-15] El seguimiento lo registra la persona de la sesión
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona en [dbo].[usuario_general] para ORIGINAL_LOGIN().', 1;
           IF EXISTS (SELECT 1
                      FROM   inserted
                      WHERE  per_codigo <> @per_actor)
               THROW 50019, N'Autor inválido: [per_codigo] debe ser la persona de la sesión en [sgspi].[seguimiento_actividad].', 1;
           -- [AP-02] D5: los roles líder y custodio solo reportan avances de procesos de su alcance
           IF EXISTS (SELECT 1
                      FROM   inserted AS x
                             INNER JOIN
                             sgspi.actividad_tratamiento AS act
                             ON act.act_codigo = x.act_codigo
                             INNER JOIN
                             sgspi.plan_tratamiento AS plt
                             ON plt.plt_codigo = act.plt_codigo
                             INNER JOIN
                             sgspi.evento_incertidumbre_activo AS eia
                             ON eia.eia_codigo = plt.eia_codigo
                             OUTER APPLY sgspi.ufn_proceso_en_alcance(eia.pri_codigo) AS a
                      WHERE  a.permitido IS NULL)
               THROW 50021, N'Fuera de alcance: el proceso del evento no está en las UAA del usuario en [sgspi].[seguimiento_actividad].', 1;
           -- Si hay varias filas de la misma actividad en el lote, prevalece la de mayor sga_codigo
           UPDATE act
           SET    act.act_porcentaje_avance = x.sga_porcentaje_reportado
           FROM   sgspi.actividad_tratamiento AS act
                  INNER JOIN
                  (SELECT i.act_codigo,
                          i.sga_porcentaje_reportado,
                          ROW_NUMBER() OVER (PARTITION BY i.act_codigo ORDER BY i.sga_codigo DESC) AS rn
                   FROM   inserted AS i) AS x
                  ON x.act_codigo = act.act_codigo
                     AND x.rn = 1
           WHERE  act.act_porcentaje_avance <> x.sga_porcentaje_reportado;
           INSERT INTO sgspi.aud_seguimiento_actividad (
               sga_codigo,
               act_codigo,
               per_codigo_autor,
               asa_fecha_registro,
               asa_porcentaje_reportado,
               asa_descripcion_avance,
               asa_nombre_archivo_evidencia,
               asa_uri_almacenamiento_evidencia,
               asa_hash_sha256_evidencia,
               asa_esta_activo,
               per_codigo,
               asa_operacion,
               asa_usuario_bd,
               asa_fecha_cambio
           )
           SELECT i.sga_codigo,
                  i.act_codigo,
                  i.per_codigo,
                  i.sga_fecha_registro,
                  i.sga_porcentaje_reportado,
                  i.sga_descripcion_avance,
                  i.sga_nombre_archivo_evidencia,
                  i.sga_uri_almacenamiento_evidencia,
                  i.sga_hash_sha256_evidencia,
                  i.sga_esta_activo,
                  @per_actor,
                  'I',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   inserted AS i;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- 5.10.9b Triggers sobre tablas puente: bloquean INSERT/UPDATE cuando el padre tiene efc_permite_edicion = 0 [AP-24: WITH (UPDLOCK)]
CREATE OR ALTER TRIGGER sgspi.TR_rpp_bloquear_padre_no_editable
    ON sgspi.requisito_parte_interesada_proceso_institucional
    AFTER INSERT, UPDATE
    AS BEGIN
           SET NOCOUNT ON;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           IF EXISTS (SELECT 1
                      FROM   (SELECT rpi_codigo
                              FROM   inserted
                              UNION
                              SELECT rpi_codigo
                              FROM   deleted) AS x
                             INNER JOIN
                             sgspi.requisito_parte_interesada AS p WITH (UPDLOCK)
                             ON p.rpi_codigo = x.rpi_codigo
                             INNER JOIN
                             sgspi.estado_flujo_catalogo AS efc
                             ON efc.efc_dominio = N'RPI'
                                AND efc.efc_identificador = p.rpi_estado_registro
                      WHERE  efc.efc_permite_edicion = 0)
               THROW 50011, N'Operación denegada: No se permite insertar ni modificar registros de [sgspi].[requisito_parte_interesada_proceso_institucional] cuando el padre no es editable.', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
CREATE OR ALTER TRIGGER sgspi.TR_aip_bloquear_padre_no_editable
    ON sgspi.activo_informacion_proceso_institucional
    AFTER INSERT, UPDATE
    AS BEGIN
           SET NOCOUNT ON;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           IF EXISTS (SELECT 1
                      FROM   (SELECT aci_codigo
                              FROM   inserted
                              UNION
                              SELECT aci_codigo
                              FROM   deleted) AS x
                             INNER JOIN
                             sgspi.activo_informacion AS p WITH (UPDLOCK)
                             ON p.aci_codigo = x.aci_codigo
                             INNER JOIN
                             sgspi.estado_flujo_catalogo AS efc
                             ON efc.efc_dominio = N'ACI'
                                AND efc.efc_identificador = p.aci_estado_registro
                      WHERE  efc.efc_permite_edicion = 0)
               THROW 50011, N'Operación denegada: No se permite insertar ni modificar registros de [sgspi].[activo_informacion_proceso_institucional] cuando el padre no es editable.', 1;
           -- [AP-02] D5: los roles líder y custodio asocian a sus procesos solo activos de sus UAA (la asociación nueva no da alcance)
           IF EXISTS (SELECT 1
                      FROM   (SELECT aci_codigo,
                                     pri_codigo
                              FROM   inserted
                              UNION
                              SELECT aci_codigo,
                                     pri_codigo
                              FROM   deleted) AS x
                             INNER JOIN
                             sgspi.activo_informacion AS p
                             ON p.aci_codigo = x.aci_codigo
                             OUTER APPLY sgspi.ufn_proceso_en_alcance(x.pri_codigo) AS ap
                             OUTER APPLY sgspi.ufn_activo_en_alcance(NULL, p.uaa_codigo) AS aa
                      WHERE  ap.permitido IS NULL
                             OR aa.permitido IS NULL)
               THROW 50021, N'Fuera de alcance: el activo o el proceso no son de las UAA del usuario en [sgspi].[activo_informacion_proceso_institucional].', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
CREATE OR ALTER TRIGGER sgspi.TR_ais_bloquear_padre_no_editable
    ON sgspi.activo_informacion_sede
    AFTER INSERT, UPDATE
    AS BEGIN
           SET NOCOUNT ON;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           IF EXISTS (SELECT 1
                      FROM   (SELECT aci_codigo
                              FROM   inserted
                              UNION
                              SELECT aci_codigo
                              FROM   deleted) AS x
                             INNER JOIN
                             sgspi.activo_informacion AS p WITH (UPDLOCK)
                             ON p.aci_codigo = x.aci_codigo
                             INNER JOIN
                             sgspi.estado_flujo_catalogo AS efc
                             ON efc.efc_dominio = N'ACI'
                                AND efc.efc_identificador = p.aci_estado_registro
                      WHERE  efc.efc_permite_edicion = 0)
               THROW 50011, N'Operación denegada: No se permite insertar ni modificar registros de [sgspi].[activo_informacion_sede] cuando el padre no es editable.', 1;
           -- [AP-02] D5: los roles líder y custodio solo escriben activos de su alcance (ufn_activo_en_alcance)
           IF EXISTS (SELECT 1
                      FROM   (SELECT aci_codigo
                              FROM   inserted
                              UNION
                              SELECT aci_codigo
                              FROM   deleted) AS x
                             INNER JOIN
                             sgspi.activo_informacion AS p
                             ON p.aci_codigo = x.aci_codigo
                             OUTER APPLY sgspi.ufn_activo_en_alcance(p.aci_codigo, p.uaa_codigo) AS a
                      WHERE  a.permitido IS NULL)
               THROW 50021, N'Fuera de alcance: el activo no es de las UAA ni de los procesos del usuario en [sgspi].[activo_informacion_sede].', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
CREATE OR ALTER TRIGGER sgspi.TR_air_bloquear_padre_no_editable
    ON sgspi.activo_informacion_responsable
    AFTER INSERT, UPDATE
    AS BEGIN
           SET NOCOUNT ON;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           IF EXISTS (SELECT 1
                      FROM   (SELECT aci_codigo
                              FROM   inserted
                              UNION
                              SELECT aci_codigo
                              FROM   deleted) AS x
                             INNER JOIN
                             sgspi.activo_informacion AS p WITH (UPDLOCK)
                             ON p.aci_codigo = x.aci_codigo
                             INNER JOIN
                             sgspi.estado_flujo_catalogo AS efc
                             ON efc.efc_dominio = N'ACI'
                                AND efc.efc_identificador = p.aci_estado_registro
                      WHERE  efc.efc_permite_edicion = 0)
               THROW 50011, N'Operación denegada: No se permite insertar ni modificar registros de [sgspi].[activo_informacion_responsable] cuando el padre no es editable.', 1;
           -- [AP-02] D5: los roles líder y custodio solo escriben activos de su alcance (ufn_activo_en_alcance)
           IF EXISTS (SELECT 1
                      FROM   (SELECT aci_codigo
                              FROM   inserted
                              UNION
                              SELECT aci_codigo
                              FROM   deleted) AS x
                             INNER JOIN
                             sgspi.activo_informacion AS p
                             ON p.aci_codigo = x.aci_codigo
                             OUTER APPLY sgspi.ufn_activo_en_alcance(p.aci_codigo, p.uaa_codigo) AS a
                      WHERE  a.permitido IS NULL)
               THROW 50021, N'Fuera de alcance: el activo no es de las UAA ni de los procesos del usuario en [sgspi].[activo_informacion_responsable].', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
CREATE OR ALTER TRIGGER sgspi.TR_ads_bloquear_padre_no_editable
    ON sgspi.activo_documental_soporte_registro
    AFTER INSERT, UPDATE
    AS BEGIN
           SET NOCOUNT ON;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           IF EXISTS (SELECT 1
                      FROM   (SELECT ado_codigo
                              FROM   inserted
                              UNION
                              SELECT ado_codigo
                              FROM   deleted) AS x
                             INNER JOIN
                             sgspi.activo_informacion AS p WITH (UPDLOCK)
                             ON p.aci_codigo = x.ado_codigo
                             INNER JOIN
                             sgspi.estado_flujo_catalogo AS efc
                             ON efc.efc_dominio = N'ACI'
                                AND efc.efc_identificador = p.aci_estado_registro
                      WHERE  efc.efc_permite_edicion = 0)
               THROW 50011, N'Operación denegada: No se permite insertar ni modificar registros de [sgspi].[activo_documental_soporte_registro] cuando el padre no es editable.', 1;
           -- [AP-02] D5: los roles líder y custodio solo escriben activos de su alcance (ufn_activo_en_alcance)
           IF EXISTS (SELECT 1
                      FROM   (SELECT ado_codigo
                              FROM   inserted
                              UNION
                              SELECT ado_codigo
                              FROM   deleted) AS x
                             INNER JOIN
                             sgspi.activo_informacion AS p
                             ON p.aci_codigo = x.ado_codigo
                             OUTER APPLY sgspi.ufn_activo_en_alcance(p.aci_codigo, p.uaa_codigo) AS a
                      WHERE  a.permitido IS NULL)
               THROW 50021, N'Fuera de alcance: el activo no es de las UAA ni de los procesos del usuario en [sgspi].[activo_documental_soporte_registro].', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
CREATE OR ALTER TRIGGER sgspi.TR_adm_bloquear_padre_no_editable
    ON sgspi.activo_documental_medio_conservacion
    AFTER INSERT, UPDATE
    AS BEGIN
           SET NOCOUNT ON;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           IF EXISTS (SELECT 1
                      FROM   (SELECT ado_codigo
                              FROM   inserted
                              UNION
                              SELECT ado_codigo
                              FROM   deleted) AS x
                             INNER JOIN
                             sgspi.activo_informacion AS p WITH (UPDLOCK)
                             ON p.aci_codigo = x.ado_codigo
                             INNER JOIN
                             sgspi.estado_flujo_catalogo AS efc
                             ON efc.efc_dominio = N'ACI'
                                AND efc.efc_identificador = p.aci_estado_registro
                      WHERE  efc.efc_permite_edicion = 0)
               THROW 50011, N'Operación denegada: No se permite insertar ni modificar registros de [sgspi].[activo_documental_medio_conservacion] cuando el padre no es editable.', 1;
           -- [AP-02] D5: los roles líder y custodio solo escriben activos de su alcance (ufn_activo_en_alcance)
           IF EXISTS (SELECT 1
                      FROM   (SELECT ado_codigo
                              FROM   inserted
                              UNION
                              SELECT ado_codigo
                              FROM   deleted) AS x
                             INNER JOIN
                             sgspi.activo_informacion AS p
                             ON p.aci_codigo = x.ado_codigo
                             OUTER APPLY sgspi.ufn_activo_en_alcance(p.aci_codigo, p.uaa_codigo) AS a
                      WHERE  a.permitido IS NULL)
               THROW 50021, N'Fuera de alcance: el activo no es de las UAA ni de los procesos del usuario en [sgspi].[activo_documental_medio_conservacion].', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
CREATE OR ALTER TRIGGER sgspi.TR_adi_bloquear_padre_no_editable
    ON sgspi.activo_documental_idioma
    AFTER INSERT, UPDATE
    AS BEGIN
           SET NOCOUNT ON;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           IF EXISTS (SELECT 1
                      FROM   (SELECT ado_codigo
                              FROM   inserted
                              UNION
                              SELECT ado_codigo
                              FROM   deleted) AS x
                             INNER JOIN
                             sgspi.activo_informacion AS p WITH (UPDLOCK)
                             ON p.aci_codigo = x.ado_codigo
                             INNER JOIN
                             sgspi.estado_flujo_catalogo AS efc
                             ON efc.efc_dominio = N'ACI'
                                AND efc.efc_identificador = p.aci_estado_registro
                      WHERE  efc.efc_permite_edicion = 0)
               THROW 50011, N'Operación denegada: No se permite insertar ni modificar registros de [sgspi].[activo_documental_idioma] cuando el padre no es editable.', 1;
           -- [AP-02] D5: los roles líder y custodio solo escriben activos de su alcance (ufn_activo_en_alcance)
           IF EXISTS (SELECT 1
                      FROM   (SELECT ado_codigo
                              FROM   inserted
                              UNION
                              SELECT ado_codigo
                              FROM   deleted) AS x
                             INNER JOIN
                             sgspi.activo_informacion AS p
                             ON p.aci_codigo = x.ado_codigo
                             OUTER APPLY sgspi.ufn_activo_en_alcance(p.aci_codigo, p.uaa_codigo) AS a
                      WHERE  a.permitido IS NULL)
               THROW 50021, N'Fuera de alcance: el activo no es de las UAA ni de los procesos del usuario en [sgspi].[activo_documental_idioma].', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
CREATE OR ALTER TRIGGER sgspi.TR_adf_bloquear_padre_no_editable
    ON sgspi.activo_documental_formato_archivo
    AFTER INSERT, UPDATE
    AS BEGIN
           SET NOCOUNT ON;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           IF EXISTS (SELECT 1
                      FROM   (SELECT ado_codigo
                              FROM   inserted
                              UNION
                              SELECT ado_codigo
                              FROM   deleted) AS x
                             INNER JOIN
                             sgspi.activo_informacion AS p WITH (UPDLOCK)
                             ON p.aci_codigo = x.ado_codigo
                             INNER JOIN
                             sgspi.estado_flujo_catalogo AS efc
                             ON efc.efc_dominio = N'ACI'
                                AND efc.efc_identificador = p.aci_estado_registro
                      WHERE  efc.efc_permite_edicion = 0)
               THROW 50011, N'Operación denegada: No se permite insertar ni modificar registros de [sgspi].[activo_documental_formato_archivo] cuando el padre no es editable.', 1;
           -- [AP-02] D5: los roles líder y custodio solo escriben activos de su alcance (ufn_activo_en_alcance)
           IF EXISTS (SELECT 1
                      FROM   (SELECT ado_codigo
                              FROM   inserted
                              UNION
                              SELECT ado_codigo
                              FROM   deleted) AS x
                             INNER JOIN
                             sgspi.activo_informacion AS p
                             ON p.aci_codigo = x.ado_codigo
                             OUTER APPLY sgspi.ufn_activo_en_alcance(p.aci_codigo, p.uaa_codigo) AS a
                      WHERE  a.permitido IS NULL)
               THROW 50021, N'Fuera de alcance: el activo no es de las UAA ni de los procesos del usuario en [sgspi].[activo_documental_formato_archivo].', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
CREATE OR ALTER TRIGGER sgspi.TR_adu_bloquear_padre_no_editable
    ON sgspi.activo_documental_unidad_productora
    AFTER INSERT, UPDATE
    AS BEGIN
           SET NOCOUNT ON;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           IF EXISTS (SELECT 1
                      FROM   (SELECT ado_codigo
                              FROM   inserted
                              UNION
                              SELECT ado_codigo
                              FROM   deleted) AS x
                             INNER JOIN
                             sgspi.activo_informacion AS p WITH (UPDLOCK)
                             ON p.aci_codigo = x.ado_codigo
                             INNER JOIN
                             sgspi.estado_flujo_catalogo AS efc
                             ON efc.efc_dominio = N'ACI'
                                AND efc.efc_identificador = p.aci_estado_registro
                      WHERE  efc.efc_permite_edicion = 0)
               THROW 50011, N'Operación denegada: No se permite insertar ni modificar registros de [sgspi].[activo_documental_unidad_productora] cuando el padre no es editable.', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
CREATE OR ALTER TRIGGER sgspi.TR_ptc_bloquear_padre_no_editable
    ON sgspi.plan_tratamiento_control_referencia_normativa
    AFTER INSERT, UPDATE
    AS BEGIN
           SET NOCOUNT ON;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           IF EXISTS (SELECT 1
                      FROM   (SELECT plt_codigo
                              FROM   inserted
                              UNION
                              SELECT plt_codigo
                              FROM   deleted) AS x
                             INNER JOIN
                             sgspi.plan_tratamiento AS plt WITH (UPDLOCK)
                             ON plt.plt_codigo = x.plt_codigo
                             INNER JOIN
                             sgspi.evento_incertidumbre_activo AS p WITH (UPDLOCK)
                             ON p.eia_codigo = plt.eia_codigo
                             INNER JOIN
                             sgspi.estado_flujo_catalogo AS efc
                             ON efc.efc_dominio = N'EIA'
                                AND efc.efc_identificador = p.eia_estado_registro
                      WHERE  efc.efc_permite_edicion = 0)
               THROW 50011, N'Operación denegada: No se permite insertar ni modificar registros de [sgspi].[plan_tratamiento_control_referencia_normativa] cuando el padre no es editable.', 1;
           -- [AP-02] D5: los roles líder y custodio solo escriben en procesos de su alcance (ufn_proceso_en_alcance)
           IF EXISTS (SELECT 1
                      FROM   (SELECT plt_codigo
                              FROM   inserted
                              UNION
                              SELECT plt_codigo
                              FROM   deleted) AS x
                             INNER JOIN
                             sgspi.plan_tratamiento AS plt
                             ON plt.plt_codigo = x.plt_codigo
                             INNER JOIN
                             sgspi.evento_incertidumbre_activo AS eia
                             ON eia.eia_codigo = plt.eia_codigo
                             OUTER APPLY sgspi.ufn_proceso_en_alcance(eia.pri_codigo) AS a
                      WHERE  a.permitido IS NULL)
               THROW 50021, N'Fuera de alcance: el proceso del evento no está en las UAA del usuario en [sgspi].[plan_tratamiento_control_referencia_normativa].', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- 5.10.9c Triggers de auditoría [AP-01]: inmutabilidad de las 49 tablas aud_* y archivo de altas ('I') y versiones anteriores ('U')
-- en las 40 tablas cuyo trigger no se actualiza a sí mismo (las otras 9 lo hacen dentro de su trigger, ver 5.9)
-- [apv] La auditoría no se edita ni se borra
CREATE OR ALTER TRIGGER sgspi.TR_apv_inmutabilidad
    ON sgspi.aud_periodo_vigencia
    INSTEAD OF UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           THROW 50016, N'Operación denegada: la tabla de auditoría [sgspi].[aud_periodo_vigencia] es inmutable y no admite modificaciones ni borrados.', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [pev] Bloquea el borrado físico y archiva en [sgspi].[aud_periodo_vigencia] las altas ('I') y la versión anterior de cada fila modificada ('U')
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
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
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
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [aec] La auditoría no se edita ni se borra
CREATE OR ALTER TRIGGER sgspi.TR_aec_inmutabilidad
    ON sgspi.aud_estado_flujo_catalogo
    INSTEAD OF UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           THROW 50016, N'Operación denegada: la tabla de auditoría [sgspi].[aud_estado_flujo_catalogo] es inmutable y no admite modificaciones ni borrados.', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [efc] Bloquea el borrado físico y archiva en [sgspi].[aud_estado_flujo_catalogo] las altas ('I') y la versión anterior de cada fila modificada ('U')
CREATE OR ALTER TRIGGER sgspi.TR_efc_auditoria
    ON sgspi.estado_flujo_catalogo
    AFTER INSERT, UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           IF EXISTS (SELECT 1
                      FROM   deleted)
              AND NOT EXISTS (SELECT 1
                              FROM   inserted)
               THROW 50010, N'Operación denegada: No se permite eliminar físicamente registros de [sgspi].[estado_flujo_catalogo].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona en [dbo].[usuario_general] para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_estado_flujo_catalogo (
                       efc_codigo,
                       aec_dominio,
                       aec_identificador,
                       aec_nombre,
                       aec_es_inicial,
                       aec_permite_edicion,
                       aec_esta_activo,
                       per_codigo,
                       aec_operacion,
                       aec_usuario_bd,
                       aec_fecha_cambio
                   )
                   SELECT i.efc_codigo,
                          i.efc_dominio,
                          i.efc_identificador,
                          i.efc_nombre,
                          i.efc_es_inicial,
                          i.efc_permite_edicion,
                          i.efc_esta_activo,
                          @per_actor,
                          'I',
                          ORIGINAL_LOGIN(),
                          SYSDATETIMEOFFSET()
                   FROM   inserted AS i;
                   RETURN;
               END
           INSERT INTO sgspi.aud_estado_flujo_catalogo (
               efc_codigo,
               aec_dominio,
               aec_identificador,
               aec_nombre,
               aec_es_inicial,
               aec_permite_edicion,
               aec_esta_activo,
               per_codigo,
               aec_operacion,
               aec_usuario_bd,
               aec_fecha_cambio
           )
           SELECT d.efc_codigo,
                  d.efc_dominio,
                  d.efc_identificador,
                  d.efc_nombre,
                  d.efc_es_inicial,
                  d.efc_permite_edicion,
                  d.efc_esta_activo,
                  @per_actor,
                  'U',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   deleted AS d
                  INNER JOIN
                  inserted AS i
                  ON i.efc_codigo = d.efc_codigo
           WHERE  EXISTS (SELECT i.efc_dominio,
                                 i.efc_identificador,
                                 i.efc_nombre,
                                 i.efc_es_inicial,
                                 i.efc_permite_edicion,
                                 i.efc_esta_activo
                          EXCEPT
                          SELECT d.efc_dominio,
                                 d.efc_identificador,
                                 d.efc_nombre,
                                 d.efc_es_inicial,
                                 d.efc_permite_edicion,
                                 d.efc_esta_activo);
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [atf] La auditoría no se edita ni se borra
CREATE OR ALTER TRIGGER sgspi.TR_atf_inmutabilidad
    ON sgspi.aud_transicion_estado_flujo
    INSTEAD OF UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           THROW 50016, N'Operación denegada: la tabla de auditoría [sgspi].[aud_transicion_estado_flujo] es inmutable y no admite modificaciones ni borrados.', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [tef] Bloquea el borrado físico y archiva en [sgspi].[aud_transicion_estado_flujo] las altas ('I') y la versión anterior de cada fila modificada ('U')
CREATE OR ALTER TRIGGER sgspi.TR_tef_auditoria
    ON sgspi.transicion_estado_flujo
    AFTER INSERT, UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           IF EXISTS (SELECT 1
                      FROM   deleted)
              AND NOT EXISTS (SELECT 1
                              FROM   inserted)
               THROW 50010, N'Operación denegada: No se permite eliminar físicamente registros de [sgspi].[transicion_estado_flujo].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona en [dbo].[usuario_general] para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_transicion_estado_flujo (
                       tef_codigo,
                       efc_dominio,
                       efc_identificador_origen,
                       efc_identificador_destino,
                       atf_rol_requerido,
                       atf_esta_activa,
                       per_codigo,
                       atf_operacion,
                       atf_usuario_bd,
                       atf_fecha_cambio
                   )
                   SELECT i.tef_codigo,
                          i.efc_dominio,
                          i.efc_identificador_origen,
                          i.efc_identificador_destino,
                          i.tef_rol_requerido,
                          i.tef_esta_activa,
                          @per_actor,
                          'I',
                          ORIGINAL_LOGIN(),
                          SYSDATETIMEOFFSET()
                   FROM   inserted AS i;
                   RETURN;
               END
           INSERT INTO sgspi.aud_transicion_estado_flujo (
               tef_codigo,
               efc_dominio,
               efc_identificador_origen,
               efc_identificador_destino,
               atf_rol_requerido,
               atf_esta_activa,
               per_codigo,
               atf_operacion,
               atf_usuario_bd,
               atf_fecha_cambio
           )
           SELECT d.tef_codigo,
                  d.efc_dominio,
                  d.efc_identificador_origen,
                  d.efc_identificador_destino,
                  d.tef_rol_requerido,
                  d.tef_esta_activa,
                  @per_actor,
                  'U',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   deleted AS d
                  INNER JOIN
                  inserted AS i
                  ON i.tef_codigo = d.tef_codigo
           WHERE  EXISTS (SELECT i.efc_dominio,
                                 i.efc_identificador_origen,
                                 i.efc_identificador_destino,
                                 i.tef_rol_requerido,
                                 i.tef_esta_activa
                          EXCEPT
                          SELECT d.efc_dominio,
                                 d.efc_identificador_origen,
                                 d.efc_identificador_destino,
                                 d.tef_rol_requerido,
                                 d.tef_esta_activa);
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [atr] La auditoría no se edita ni se borra
CREATE OR ALTER TRIGGER sgspi.TR_atr_inmutabilidad
    ON sgspi.aud_tipo_proceso_catalogo
    INSTEAD OF UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           THROW 50016, N'Operación denegada: la tabla de auditoría [sgspi].[aud_tipo_proceso_catalogo] es inmutable y no admite modificaciones ni borrados.', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [tpr] Bloquea el borrado físico y archiva en [sgspi].[aud_tipo_proceso_catalogo] las altas ('I') y la versión anterior de cada fila modificada ('U')
CREATE OR ALTER TRIGGER sgspi.TR_tpr_auditoria
    ON sgspi.tipo_proceso_catalogo
    AFTER INSERT, UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           IF EXISTS (SELECT 1
                      FROM   deleted)
              AND NOT EXISTS (SELECT 1
                              FROM   inserted)
               THROW 50010, N'Operación denegada: No se permite eliminar físicamente registros de [sgspi].[tipo_proceso_catalogo].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona en [dbo].[usuario_general] para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_tipo_proceso_catalogo (
                       tpr_codigo,
                       atr_identificador,
                       atr_nombre,
                       atr_descripcion,
                       atr_esta_activo,
                       per_codigo,
                       atr_operacion,
                       atr_usuario_bd,
                       atr_fecha_cambio
                   )
                   SELECT i.tpr_codigo,
                          i.tpr_identificador,
                          i.tpr_nombre,
                          i.tpr_descripcion,
                          i.tpr_esta_activo,
                          @per_actor,
                          'I',
                          ORIGINAL_LOGIN(),
                          SYSDATETIMEOFFSET()
                   FROM   inserted AS i;
                   RETURN;
               END
           INSERT INTO sgspi.aud_tipo_proceso_catalogo (
               tpr_codigo,
               atr_identificador,
               atr_nombre,
               atr_descripcion,
               atr_esta_activo,
               per_codigo,
               atr_operacion,
               atr_usuario_bd,
               atr_fecha_cambio
           )
           SELECT d.tpr_codigo,
                  d.tpr_identificador,
                  d.tpr_nombre,
                  d.tpr_descripcion,
                  d.tpr_esta_activo,
                  @per_actor,
                  'U',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   deleted AS d
                  INNER JOIN
                  inserted AS i
                  ON i.tpr_codigo = d.tpr_codigo
           WHERE  EXISTS (SELECT i.tpr_identificador,
                                 i.tpr_nombre,
                                 i.tpr_descripcion,
                                 i.tpr_esta_activo
                          EXCEPT
                          SELECT d.tpr_identificador,
                                 d.tpr_nombre,
                                 d.tpr_descripcion,
                                 d.tpr_esta_activo);
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [api] La auditoría no se edita ni se borra
CREATE OR ALTER TRIGGER sgspi.TR_api_inmutabilidad
    ON sgspi.aud_proceso_institucional
    INSTEAD OF UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           THROW 50016, N'Operación denegada: la tabla de auditoría [sgspi].[aud_proceso_institucional] es inmutable y no admite modificaciones ni borrados.', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [pri] Bloquea el borrado físico y archiva en [sgspi].[aud_proceso_institucional] las altas ('I') y la versión anterior de cada fila modificada ('U')
CREATE OR ALTER TRIGGER sgspi.TR_pri_auditoria
    ON sgspi.proceso_institucional
    AFTER INSERT, UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           IF EXISTS (SELECT 1
                      FROM   deleted)
              AND NOT EXISTS (SELECT 1
                              FROM   inserted)
               THROW 50010, N'Operación denegada: No se permite eliminar físicamente registros de [sgspi].[proceso_institucional].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona en [dbo].[usuario_general] para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_proceso_institucional (
                       pri_codigo,
                       api_identificador,
                       api_nombre,
                       tpr_codigo,
                       uaa_codigo_lider,
                       car_codigo_lider,
                       api_esta_activo,
                       per_codigo,
                       api_operacion,
                       api_usuario_bd,
                       api_fecha_cambio
                   )
                   SELECT i.pri_codigo,
                          i.pri_identificador,
                          i.pri_nombre,
                          i.tpr_codigo,
                          i.uaa_codigo_lider,
                          i.car_codigo_lider,
                          i.pri_esta_activo,
                          @per_actor,
                          'I',
                          ORIGINAL_LOGIN(),
                          SYSDATETIMEOFFSET()
                   FROM   inserted AS i;
                   RETURN;
               END
           INSERT INTO sgspi.aud_proceso_institucional (
               pri_codigo,
               api_identificador,
               api_nombre,
               tpr_codigo,
               uaa_codigo_lider,
               car_codigo_lider,
               api_esta_activo,
               per_codigo,
               api_operacion,
               api_usuario_bd,
               api_fecha_cambio
           )
           SELECT d.pri_codigo,
                  d.pri_identificador,
                  d.pri_nombre,
                  d.tpr_codigo,
                  d.uaa_codigo_lider,
                  d.car_codigo_lider,
                  d.pri_esta_activo,
                  @per_actor,
                  'U',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   deleted AS d
                  INNER JOIN
                  inserted AS i
                  ON i.pri_codigo = d.pri_codigo
           WHERE  EXISTS (SELECT i.pri_identificador,
                                 i.pri_nombre,
                                 i.tpr_codigo,
                                 i.uaa_codigo_lider,
                                 i.car_codigo_lider,
                                 i.pri_esta_activo
                          EXCEPT
                          SELECT d.pri_identificador,
                                 d.pri_nombre,
                                 d.tpr_codigo,
                                 d.uaa_codigo_lider,
                                 d.car_codigo_lider,
                                 d.pri_esta_activo);
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [apu] La auditoría no se edita ni se borra
CREATE OR ALTER TRIGGER sgspi.TR_apu_inmutabilidad
    ON sgspi.aud_proceso_institucional_uaa
    INSTEAD OF UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           THROW 50016, N'Operación denegada: la tabla de auditoría [sgspi].[aud_proceso_institucional_uaa] es inmutable y no admite modificaciones ni borrados.', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [piu] Bloquea el borrado físico y archiva en [sgspi].[aud_proceso_institucional_uaa] las altas ('I') y la versión anterior de cada fila modificada ('U')
CREATE OR ALTER TRIGGER sgspi.TR_piu_auditoria
    ON sgspi.proceso_institucional_uaa
    AFTER INSERT, UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           IF EXISTS (SELECT 1
                      FROM   deleted)
              AND NOT EXISTS (SELECT 1
                              FROM   inserted)
               THROW 50010, N'Operación denegada: No se permite eliminar físicamente registros de [sgspi].[proceso_institucional_uaa].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona en [dbo].[usuario_general] para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_proceso_institucional_uaa (
                       pri_codigo,
                       uaa_codigo,
                       apu_esta_activo,
                       per_codigo,
                       apu_operacion,
                       apu_usuario_bd,
                       apu_fecha_cambio
                   )
                   SELECT i.pri_codigo,
                          i.uaa_codigo,
                          i.piu_esta_activo,
                          @per_actor,
                          'I',
                          ORIGINAL_LOGIN(),
                          SYSDATETIMEOFFSET()
                   FROM   inserted AS i;
                   RETURN;
               END
           IF EXISTS (SELECT 1
                      FROM   deleted AS d
                      WHERE  NOT EXISTS (SELECT 1
                                         FROM   inserted AS i
                                         WHERE  i.pri_codigo = d.pri_codigo
                                                AND i.uaa_codigo = d.uaa_codigo))
               THROW 50011, N'Operación denegada: No se permite cambiar la clave de [sgspi].[proceso_institucional_uaa]; desactive la fila y cree una nueva.', 1;
           INSERT INTO sgspi.aud_proceso_institucional_uaa (
               pri_codigo,
               uaa_codigo,
               apu_esta_activo,
               per_codigo,
               apu_operacion,
               apu_usuario_bd,
               apu_fecha_cambio
           )
           SELECT d.pri_codigo,
                  d.uaa_codigo,
                  d.piu_esta_activo,
                  @per_actor,
                  'U',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   deleted AS d
                  INNER JOIN
                  inserted AS i
                  ON i.pri_codigo = d.pri_codigo
                     AND i.uaa_codigo = d.uaa_codigo
           WHERE  EXISTS (SELECT i.piu_esta_activo
                          EXCEPT
                          SELECT d.piu_esta_activo);
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [afc] La auditoría no se edita ni se borra
CREATE OR ALTER TRIGGER sgspi.TR_afc_inmutabilidad
    ON sgspi.aud_factor_entorno_catalogo
    INSTEAD OF UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           THROW 50016, N'Operación denegada: la tabla de auditoría [sgspi].[aud_factor_entorno_catalogo] es inmutable y no admite modificaciones ni borrados.', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [fec] Bloquea el borrado físico y archiva en [sgspi].[aud_factor_entorno_catalogo] las altas ('I') y la versión anterior de cada fila modificada ('U')
CREATE OR ALTER TRIGGER sgspi.TR_fec_auditoria
    ON sgspi.factor_entorno_catalogo
    AFTER INSERT, UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           IF EXISTS (SELECT 1
                      FROM   deleted)
              AND NOT EXISTS (SELECT 1
                              FROM   inserted)
               THROW 50010, N'Operación denegada: No se permite eliminar físicamente registros de [sgspi].[factor_entorno_catalogo].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona en [dbo].[usuario_general] para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_factor_entorno_catalogo (
                       fec_codigo,
                       afc_nombre_factor,
                       afc_ambito_entorno,
                       afc_descripcion,
                       afc_esta_activo,
                       per_codigo,
                       afc_operacion,
                       afc_usuario_bd,
                       afc_fecha_cambio
                   )
                   SELECT i.fec_codigo,
                          i.fec_nombre_factor,
                          i.fec_ambito_entorno,
                          i.fec_descripcion,
                          i.fec_esta_activo,
                          @per_actor,
                          'I',
                          ORIGINAL_LOGIN(),
                          SYSDATETIMEOFFSET()
                   FROM   inserted AS i;
                   RETURN;
               END
           INSERT INTO sgspi.aud_factor_entorno_catalogo (
               fec_codigo,
               afc_nombre_factor,
               afc_ambito_entorno,
               afc_descripcion,
               afc_esta_activo,
               per_codigo,
               afc_operacion,
               afc_usuario_bd,
               afc_fecha_cambio
           )
           SELECT d.fec_codigo,
                  d.fec_nombre_factor,
                  d.fec_ambito_entorno,
                  d.fec_descripcion,
                  d.fec_esta_activo,
                  @per_actor,
                  'U',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   deleted AS d
                  INNER JOIN
                  inserted AS i
                  ON i.fec_codigo = d.fec_codigo
           WHERE  EXISTS (SELECT i.fec_nombre_factor,
                                 i.fec_ambito_entorno,
                                 i.fec_descripcion,
                                 i.fec_esta_activo
                          EXCEPT
                          SELECT d.fec_nombre_factor,
                                 d.fec_ambito_entorno,
                                 d.fec_descripcion,
                                 d.fec_esta_activo);
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [aaf] La auditoría no se edita ni se borra
CREATE OR ALTER TRIGGER sgspi.TR_aaf_inmutabilidad
    ON sgspi.aud_analisis_contexto_factor
    INSTEAD OF UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           THROW 50016, N'Operación denegada: la tabla de auditoría [sgspi].[aud_analisis_contexto_factor] es inmutable y no admite modificaciones ni borrados.', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [apa] La auditoría no se edita ni se borra
CREATE OR ALTER TRIGGER sgspi.TR_apa_inmutabilidad
    ON sgspi.aud_parte_interesada
    INSTEAD OF UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           THROW 50016, N'Operación denegada: la tabla de auditoría [sgspi].[aud_parte_interesada] es inmutable y no admite modificaciones ni borrados.', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [pai] Bloquea el borrado físico y archiva en [sgspi].[aud_parte_interesada] las altas ('I') y la versión anterior de cada fila modificada ('U')
CREATE OR ALTER TRIGGER sgspi.TR_pai_auditoria
    ON sgspi.parte_interesada
    AFTER INSERT, UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           IF EXISTS (SELECT 1
                      FROM   deleted)
              AND NOT EXISTS (SELECT 1
                              FROM   inserted)
               THROW 50010, N'Operación denegada: No se permite eliminar físicamente registros de [sgspi].[parte_interesada].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona en [dbo].[usuario_general] para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_parte_interesada (
                       pai_codigo,
                       apa_nombre,
                       apa_origen,
                       apa_descripcion_rol,
                       apa_esta_activa,
                       per_codigo,
                       apa_operacion,
                       apa_usuario_bd,
                       apa_fecha_cambio
                   )
                   SELECT i.pai_codigo,
                          i.pai_nombre,
                          i.pai_origen,
                          i.pai_descripcion_rol,
                          i.pai_esta_activa,
                          @per_actor,
                          'I',
                          ORIGINAL_LOGIN(),
                          SYSDATETIMEOFFSET()
                   FROM   inserted AS i;
                   RETURN;
               END
           INSERT INTO sgspi.aud_parte_interesada (
               pai_codigo,
               apa_nombre,
               apa_origen,
               apa_descripcion_rol,
               apa_esta_activa,
               per_codigo,
               apa_operacion,
               apa_usuario_bd,
               apa_fecha_cambio
           )
           SELECT d.pai_codigo,
                  d.pai_nombre,
                  d.pai_origen,
                  d.pai_descripcion_rol,
                  d.pai_esta_activa,
                  @per_actor,
                  'U',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   deleted AS d
                  INNER JOIN
                  inserted AS i
                  ON i.pai_codigo = d.pai_codigo
           WHERE  EXISTS (SELECT i.pai_nombre,
                                 i.pai_origen,
                                 i.pai_descripcion_rol,
                                 i.pai_esta_activa
                          EXCEPT
                          SELECT d.pai_nombre,
                                 d.pai_origen,
                                 d.pai_descripcion_rol,
                                 d.pai_esta_activa);
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [ari] La auditoría no se edita ni se borra
CREATE OR ALTER TRIGGER sgspi.TR_ari_inmutabilidad
    ON sgspi.aud_requisito_parte_interesada
    INSTEAD OF UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           THROW 50016, N'Operación denegada: la tabla de auditoría [sgspi].[aud_requisito_parte_interesada] es inmutable y no admite modificaciones ni borrados.', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [arp] La auditoría no se edita ni se borra
CREATE OR ALTER TRIGGER sgspi.TR_arp_inmutabilidad
    ON sgspi.aud_requisito_parte_interesada_proceso_institucional
    INSTEAD OF UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           THROW 50016, N'Operación denegada: la tabla de auditoría [sgspi].[aud_requisito_parte_interesada_proceso_institucional] es inmutable y no admite modificaciones ni borrados.', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [rpp] Bloquea el borrado físico y archiva en [sgspi].[aud_requisito_parte_interesada_proceso_institucional] las altas ('I') y la versión anterior de cada fila modificada ('U')
CREATE OR ALTER TRIGGER sgspi.TR_rpp_auditoria
    ON sgspi.requisito_parte_interesada_proceso_institucional
    AFTER INSERT, UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           IF EXISTS (SELECT 1
                      FROM   deleted)
              AND NOT EXISTS (SELECT 1
                              FROM   inserted)
               THROW 50010, N'Operación denegada: No se permite eliminar físicamente registros de [sgspi].[requisito_parte_interesada_proceso_institucional].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona en [dbo].[usuario_general] para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_requisito_parte_interesada_proceso_institucional (
                       rpi_codigo,
                       pri_codigo,
                       arp_fecha_registro,
                       arp_esta_activo,
                       per_codigo,
                       arp_operacion,
                       arp_usuario_bd,
                       arp_fecha_cambio
                   )
                   SELECT i.rpi_codigo,
                          i.pri_codigo,
                          i.rpp_fecha_registro,
                          i.rpp_esta_activo,
                          @per_actor,
                          'I',
                          ORIGINAL_LOGIN(),
                          SYSDATETIMEOFFSET()
                   FROM   inserted AS i;
                   RETURN;
               END
           IF EXISTS (SELECT 1
                      FROM   deleted AS d
                      WHERE  NOT EXISTS (SELECT 1
                                         FROM   inserted AS i
                                         WHERE  i.rpi_codigo = d.rpi_codigo
                                                AND i.pri_codigo = d.pri_codigo))
               THROW 50011, N'Operación denegada: No se permite cambiar la clave de [sgspi].[requisito_parte_interesada_proceso_institucional]; desactive la fila y cree una nueva.', 1;
           INSERT INTO sgspi.aud_requisito_parte_interesada_proceso_institucional (
               rpi_codigo,
               pri_codigo,
               arp_fecha_registro,
               arp_esta_activo,
               per_codigo,
               arp_operacion,
               arp_usuario_bd,
               arp_fecha_cambio
           )
           SELECT d.rpi_codigo,
                  d.pri_codigo,
                  d.rpp_fecha_registro,
                  d.rpp_esta_activo,
                  @per_actor,
                  'U',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   deleted AS d
                  INNER JOIN
                  inserted AS i
                  ON i.rpi_codigo = d.rpi_codigo
                     AND i.pri_codigo = d.pri_codigo
           WHERE  EXISTS (SELECT i.rpp_fecha_registro,
                                 i.rpp_esta_activo
                          EXCEPT
                          SELECT d.rpp_fecha_registro,
                                 d.rpp_esta_activo);
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [atc] La auditoría no se edita ni se borra
CREATE OR ALTER TRIGGER sgspi.TR_atc_inmutabilidad
    ON sgspi.aud_tipo_activo_catalogo
    INSTEAD OF UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           THROW 50016, N'Operación denegada: la tabla de auditoría [sgspi].[aud_tipo_activo_catalogo] es inmutable y no admite modificaciones ni borrados.', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [tac] Bloquea el borrado físico y archiva en [sgspi].[aud_tipo_activo_catalogo] las altas ('I') y la versión anterior de cada fila modificada ('U')
CREATE OR ALTER TRIGGER sgspi.TR_tac_auditoria
    ON sgspi.tipo_activo_catalogo
    AFTER INSERT, UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           IF EXISTS (SELECT 1
                      FROM   deleted)
              AND NOT EXISTS (SELECT 1
                              FROM   inserted)
               THROW 50010, N'Operación denegada: No se permite eliminar físicamente registros de [sgspi].[tipo_activo_catalogo].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona en [dbo].[usuario_general] para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_tipo_activo_catalogo (
                       tac_codigo,
                       atc_codigo_padre,
                       atc_nivel_taxonomia,
                       atc_nombre,
                       atc_ejemplos_ref,
                       atc_esta_activo,
                       per_codigo,
                       atc_operacion,
                       atc_usuario_bd,
                       atc_fecha_cambio
                   )
                   SELECT i.tac_codigo,
                          i.tac_codigo_padre,
                          i.tac_nivel_taxonomia,
                          i.tac_nombre,
                          i.tac_ejemplos_ref,
                          i.tac_esta_activo,
                          @per_actor,
                          'I',
                          ORIGINAL_LOGIN(),
                          SYSDATETIMEOFFSET()
                   FROM   inserted AS i;
                   RETURN;
               END
           INSERT INTO sgspi.aud_tipo_activo_catalogo (
               tac_codigo,
               atc_codigo_padre,
               atc_nivel_taxonomia,
               atc_nombre,
               atc_ejemplos_ref,
               atc_esta_activo,
               per_codigo,
               atc_operacion,
               atc_usuario_bd,
               atc_fecha_cambio
           )
           SELECT d.tac_codigo,
                  d.tac_codigo_padre,
                  d.tac_nivel_taxonomia,
                  d.tac_nombre,
                  d.tac_ejemplos_ref,
                  d.tac_esta_activo,
                  @per_actor,
                  'U',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   deleted AS d
                  INNER JOIN
                  inserted AS i
                  ON i.tac_codigo = d.tac_codigo
           WHERE  EXISTS (SELECT i.tac_codigo_padre,
                                 i.tac_nivel_taxonomia,
                                 i.tac_nombre,
                                 i.tac_ejemplos_ref,
                                 i.tac_esta_activo
                          EXCEPT
                          SELECT d.tac_codigo_padre,
                                 d.tac_nivel_taxonomia,
                                 d.tac_nombre,
                                 d.tac_ejemplos_ref,
                                 d.tac_esta_activo);
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [ace] La auditoría no se edita ni se borra
CREATE OR ALTER TRIGGER sgspi.TR_ace_inmutabilidad
    ON sgspi.aud_causal_excepcion_transparencia
    INSTEAD OF UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           THROW 50016, N'Operación denegada: la tabla de auditoría [sgspi].[aud_causal_excepcion_transparencia] es inmutable y no admite modificaciones ni borrados.', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [cet] Bloquea el borrado físico y archiva en [sgspi].[aud_causal_excepcion_transparencia] las altas ('I') y la versión anterior de cada fila modificada ('U')
CREATE OR ALTER TRIGGER sgspi.TR_cet_auditoria
    ON sgspi.causal_excepcion_transparencia
    AFTER INSERT, UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           IF EXISTS (SELECT 1
                      FROM   deleted)
              AND NOT EXISTS (SELECT 1
                              FROM   inserted)
               THROW 50010, N'Operación denegada: No se permite eliminar físicamente registros de [sgspi].[causal_excepcion_transparencia].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona en [dbo].[usuario_general] para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_causal_excepcion_transparencia (
                       cet_codigo,
                       ace_nivel_reserva_aplicable,
                       ace_numeral_causal,
                       ace_descripcion_causal,
                       ace_norma_referencia,
                       ace_esta_activa,
                       per_codigo,
                       ace_operacion,
                       ace_usuario_bd,
                       ace_fecha_cambio
                   )
                   SELECT i.cet_codigo,
                          i.cet_nivel_reserva_aplicable,
                          i.cet_numeral_causal,
                          i.cet_descripcion_causal,
                          i.cet_norma_referencia,
                          i.cet_esta_activa,
                          @per_actor,
                          'I',
                          ORIGINAL_LOGIN(),
                          SYSDATETIMEOFFSET()
                   FROM   inserted AS i;
                   RETURN;
               END
           INSERT INTO sgspi.aud_causal_excepcion_transparencia (
               cet_codigo,
               ace_nivel_reserva_aplicable,
               ace_numeral_causal,
               ace_descripcion_causal,
               ace_norma_referencia,
               ace_esta_activa,
               per_codigo,
               ace_operacion,
               ace_usuario_bd,
               ace_fecha_cambio
           )
           SELECT d.cet_codigo,
                  d.cet_nivel_reserva_aplicable,
                  d.cet_numeral_causal,
                  d.cet_descripcion_causal,
                  d.cet_norma_referencia,
                  d.cet_esta_activa,
                  @per_actor,
                  'U',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   deleted AS d
                  INNER JOIN
                  inserted AS i
                  ON i.cet_codigo = d.cet_codigo
           WHERE  EXISTS (SELECT i.cet_nivel_reserva_aplicable,
                                 i.cet_numeral_causal,
                                 i.cet_descripcion_causal,
                                 i.cet_norma_referencia,
                                 i.cet_esta_activa
                          EXCEPT
                          SELECT d.cet_nivel_reserva_aplicable,
                                 d.cet_numeral_causal,
                                 d.cet_descripcion_causal,
                                 d.cet_norma_referencia,
                                 d.cet_esta_activa);
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [aai] La auditoría no se edita ni se borra
CREATE OR ALTER TRIGGER sgspi.TR_aai_inmutabilidad
    ON sgspi.aud_activo_informacion
    INSTEAD OF UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           THROW 50016, N'Operación denegada: la tabla de auditoría [sgspi].[aud_activo_informacion] es inmutable y no admite modificaciones ni borrados.', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [aap] La auditoría no se edita ni se borra
CREATE OR ALTER TRIGGER sgspi.TR_aap_inmutabilidad
    ON sgspi.aud_activo_informacion_proceso_institucional
    INSTEAD OF UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           THROW 50016, N'Operación denegada: la tabla de auditoría [sgspi].[aud_activo_informacion_proceso_institucional] es inmutable y no admite modificaciones ni borrados.', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [aip] Bloquea el borrado físico y archiva en [sgspi].[aud_activo_informacion_proceso_institucional] las altas ('I') y la versión anterior de cada fila modificada ('U')
CREATE OR ALTER TRIGGER sgspi.TR_aip_auditoria
    ON sgspi.activo_informacion_proceso_institucional
    AFTER INSERT, UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           IF EXISTS (SELECT 1
                      FROM   deleted)
              AND NOT EXISTS (SELECT 1
                              FROM   inserted)
               THROW 50010, N'Operación denegada: No se permite eliminar físicamente registros de [sgspi].[activo_informacion_proceso_institucional].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona en [dbo].[usuario_general] para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_activo_informacion_proceso_institucional (
                       aci_codigo,
                       pri_codigo,
                       aap_esta_activo,
                       per_codigo,
                       aap_operacion,
                       aap_usuario_bd,
                       aap_fecha_cambio
                   )
                   SELECT i.aci_codigo,
                          i.pri_codigo,
                          i.aip_esta_activo,
                          @per_actor,
                          'I',
                          ORIGINAL_LOGIN(),
                          SYSDATETIMEOFFSET()
                   FROM   inserted AS i;
                   RETURN;
               END
           IF EXISTS (SELECT 1
                      FROM   deleted AS d
                      WHERE  NOT EXISTS (SELECT 1
                                         FROM   inserted AS i
                                         WHERE  i.aci_codigo = d.aci_codigo
                                                AND i.pri_codigo = d.pri_codigo))
               THROW 50011, N'Operación denegada: No se permite cambiar la clave de [sgspi].[activo_informacion_proceso_institucional]; desactive la fila y cree una nueva.', 1;
           INSERT INTO sgspi.aud_activo_informacion_proceso_institucional (
               aci_codigo,
               pri_codigo,
               aap_esta_activo,
               per_codigo,
               aap_operacion,
               aap_usuario_bd,
               aap_fecha_cambio
           )
           SELECT d.aci_codigo,
                  d.pri_codigo,
                  d.aip_esta_activo,
                  @per_actor,
                  'U',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   deleted AS d
                  INNER JOIN
                  inserted AS i
                  ON i.aci_codigo = d.aci_codigo
                     AND i.pri_codigo = d.pri_codigo
           WHERE  EXISTS (SELECT i.aip_esta_activo
                          EXCEPT
                          SELECT d.aip_esta_activo);
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [aas] La auditoría no se edita ni se borra
CREATE OR ALTER TRIGGER sgspi.TR_aas_inmutabilidad
    ON sgspi.aud_activo_informacion_sede
    INSTEAD OF UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           THROW 50016, N'Operación denegada: la tabla de auditoría [sgspi].[aud_activo_informacion_sede] es inmutable y no admite modificaciones ni borrados.', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [ais] Bloquea el borrado físico y archiva en [sgspi].[aud_activo_informacion_sede] las altas ('I') y la versión anterior de cada fila modificada ('U')
CREATE OR ALTER TRIGGER sgspi.TR_ais_auditoria
    ON sgspi.activo_informacion_sede
    AFTER INSERT, UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           IF EXISTS (SELECT 1
                      FROM   deleted)
              AND NOT EXISTS (SELECT 1
                              FROM   inserted)
               THROW 50010, N'Operación denegada: No se permite eliminar físicamente registros de [sgspi].[activo_informacion_sede].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona en [dbo].[usuario_general] para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_activo_informacion_sede (
                       aci_codigo,
                       sus_codigo,
                       aas_esta_activo,
                       per_codigo,
                       aas_operacion,
                       aas_usuario_bd,
                       aas_fecha_cambio
                   )
                   SELECT i.aci_codigo,
                          i.sus_codigo,
                          i.ais_esta_activo,
                          @per_actor,
                          'I',
                          ORIGINAL_LOGIN(),
                          SYSDATETIMEOFFSET()
                   FROM   inserted AS i;
                   RETURN;
               END
           IF EXISTS (SELECT 1
                      FROM   deleted AS d
                      WHERE  NOT EXISTS (SELECT 1
                                         FROM   inserted AS i
                                         WHERE  i.aci_codigo = d.aci_codigo
                                                AND i.sus_codigo = d.sus_codigo))
               THROW 50011, N'Operación denegada: No se permite cambiar la clave de [sgspi].[activo_informacion_sede]; desactive la fila y cree una nueva.', 1;
           INSERT INTO sgspi.aud_activo_informacion_sede (
               aci_codigo,
               sus_codigo,
               aas_esta_activo,
               per_codigo,
               aas_operacion,
               aas_usuario_bd,
               aas_fecha_cambio
           )
           SELECT d.aci_codigo,
                  d.sus_codigo,
                  d.ais_esta_activo,
                  @per_actor,
                  'U',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   deleted AS d
                  INNER JOIN
                  inserted AS i
                  ON i.aci_codigo = d.aci_codigo
                     AND i.sus_codigo = d.sus_codigo
           WHERE  EXISTS (SELECT i.ais_esta_activo
                          EXCEPT
                          SELECT d.ais_esta_activo);
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [aar] La auditoría no se edita ni se borra
CREATE OR ALTER TRIGGER sgspi.TR_aar_inmutabilidad
    ON sgspi.aud_activo_informacion_responsable
    INSTEAD OF UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           THROW 50016, N'Operación denegada: la tabla de auditoría [sgspi].[aud_activo_informacion_responsable] es inmutable y no admite modificaciones ni borrados.', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [air] Bloquea el borrado físico y archiva en [sgspi].[aud_activo_informacion_responsable] las altas ('I') y la versión anterior de cada fila modificada ('U')
CREATE OR ALTER TRIGGER sgspi.TR_air_auditoria
    ON sgspi.activo_informacion_responsable
    AFTER INSERT, UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           IF EXISTS (SELECT 1
                      FROM   deleted)
              AND NOT EXISTS (SELECT 1
                              FROM   inserted)
               THROW 50010, N'Operación denegada: No se permite eliminar físicamente registros de [sgspi].[activo_informacion_responsable].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona en [dbo].[usuario_general] para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_activo_informacion_responsable (
                       aci_codigo,
                       car_codigo,
                       uaa_codigo,
                       air_tipo_responsabilidad,
                       aar_esta_activo,
                       per_codigo,
                       aar_operacion,
                       aar_usuario_bd,
                       aar_fecha_cambio
                   )
                   SELECT i.aci_codigo,
                          i.car_codigo,
                          i.uaa_codigo,
                          i.air_tipo_responsabilidad,
                          i.air_esta_activo,
                          @per_actor,
                          'I',
                          ORIGINAL_LOGIN(),
                          SYSDATETIMEOFFSET()
                   FROM   inserted AS i;
                   RETURN;
               END
           IF EXISTS (SELECT 1
                      FROM   deleted AS d
                      WHERE  NOT EXISTS (SELECT 1
                                         FROM   inserted AS i
                                         WHERE  i.aci_codigo = d.aci_codigo
                                                AND i.car_codigo = d.car_codigo
                                                AND i.uaa_codigo = d.uaa_codigo
                                                AND i.air_tipo_responsabilidad = d.air_tipo_responsabilidad))
               THROW 50011, N'Operación denegada: No se permite cambiar la clave de [sgspi].[activo_informacion_responsable]; desactive la fila y cree una nueva.', 1;
           INSERT INTO sgspi.aud_activo_informacion_responsable (
               aci_codigo,
               car_codigo,
               uaa_codigo,
               air_tipo_responsabilidad,
               aar_esta_activo,
               per_codigo,
               aar_operacion,
               aar_usuario_bd,
               aar_fecha_cambio
           )
           SELECT d.aci_codigo,
                  d.car_codigo,
                  d.uaa_codigo,
                  d.air_tipo_responsabilidad,
                  d.air_esta_activo,
                  @per_actor,
                  'U',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   deleted AS d
                  INNER JOIN
                  inserted AS i
                  ON i.aci_codigo = d.aci_codigo
                     AND i.car_codigo = d.car_codigo
                     AND i.uaa_codigo = d.uaa_codigo
                     AND i.air_tipo_responsabilidad = d.air_tipo_responsabilidad
           WHERE  EXISTS (SELECT i.air_esta_activo
                          EXCEPT
                          SELECT d.air_esta_activo);
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [asf] La auditoría no se edita ni se borra
CREATE OR ALTER TRIGGER sgspi.TR_asf_inmutabilidad
    ON sgspi.aud_sistema_informacion_ficha
    INSTEAD OF UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           THROW 50016, N'Operación denegada: la tabla de auditoría [sgspi].[aud_sistema_informacion_ficha] es inmutable y no admite modificaciones ni borrados.', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [sif] Bloquea el borrado físico y archiva en [sgspi].[aud_sistema_informacion_ficha] las altas ('I') y la versión anterior de cada fila modificada ('U')
CREATE OR ALTER TRIGGER sgspi.TR_sif_auditoria
    ON sgspi.sistema_informacion_ficha
    AFTER INSERT, UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           IF EXISTS (SELECT 1
                      FROM   deleted)
              AND NOT EXISTS (SELECT 1
                              FROM   inserted)
               THROW 50010, N'Operación denegada: No se permite eliminar físicamente registros de [sgspi].[sistema_informacion_ficha].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona en [dbo].[usuario_general] para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_sistema_informacion_ficha (
                       sif_codigo,
                       aci_codigo,
                       asf_nombre_sistema,
                       asf_modalidad_desarrollo,
                       asf_fabricante_proveedor,
                       asf_descripcion_general,
                       asf_esta_activo,
                       per_codigo,
                       asf_operacion,
                       asf_usuario_bd,
                       asf_fecha_cambio
                   )
                   SELECT i.sif_codigo,
                          i.aci_codigo,
                          i.sif_nombre_sistema,
                          i.sif_modalidad_desarrollo,
                          i.sif_fabricante_proveedor,
                          i.sif_descripcion_general,
                          i.sif_esta_activo,
                          @per_actor,
                          'I',
                          ORIGINAL_LOGIN(),
                          SYSDATETIMEOFFSET()
                   FROM   inserted AS i;
                   RETURN;
               END
           INSERT INTO sgspi.aud_sistema_informacion_ficha (
               sif_codigo,
               aci_codigo,
               asf_nombre_sistema,
               asf_modalidad_desarrollo,
               asf_fabricante_proveedor,
               asf_descripcion_general,
               asf_esta_activo,
               per_codigo,
               asf_operacion,
               asf_usuario_bd,
               asf_fecha_cambio
           )
           SELECT d.sif_codigo,
                  d.aci_codigo,
                  d.sif_nombre_sistema,
                  d.sif_modalidad_desarrollo,
                  d.sif_fabricante_proveedor,
                  d.sif_descripcion_general,
                  d.sif_esta_activo,
                  @per_actor,
                  'U',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   deleted AS d
                  INNER JOIN
                  inserted AS i
                  ON i.sif_codigo = d.sif_codigo
           WHERE  EXISTS (SELECT i.aci_codigo,
                                 i.sif_nombre_sistema,
                                 i.sif_modalidad_desarrollo,
                                 i.sif_fabricante_proveedor,
                                 i.sif_descripcion_general,
                                 i.sif_esta_activo
                          EXCEPT
                          SELECT d.aci_codigo,
                                 d.sif_nombre_sistema,
                                 d.sif_modalidad_desarrollo,
                                 d.sif_fabricante_proveedor,
                                 d.sif_descripcion_general,
                                 d.sif_esta_activo);
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [ami] La auditoría no se edita ni se borra
CREATE OR ALTER TRIGGER sgspi.TR_ami_inmutabilidad
    ON sgspi.aud_modulo_sistema_informacion
    INSTEAD OF UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           THROW 50016, N'Operación denegada: la tabla de auditoría [sgspi].[aud_modulo_sistema_informacion] es inmutable y no admite modificaciones ni borrados.', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [msi] Bloquea el borrado físico y archiva en [sgspi].[aud_modulo_sistema_informacion] las altas ('I') y la versión anterior de cada fila modificada ('U')
CREATE OR ALTER TRIGGER sgspi.TR_msi_auditoria
    ON sgspi.modulo_sistema_informacion
    AFTER INSERT, UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           IF EXISTS (SELECT 1
                      FROM   deleted)
              AND NOT EXISTS (SELECT 1
                              FROM   inserted)
               THROW 50010, N'Operación denegada: No se permite eliminar físicamente registros de [sgspi].[modulo_sistema_informacion].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona en [dbo].[usuario_general] para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_modulo_sistema_informacion (
                       msi_codigo,
                       sif_codigo,
                       ami_nombre_modulo,
                       ami_usuarios_objetivo,
                       ami_esta_activo,
                       per_codigo,
                       ami_operacion,
                       ami_usuario_bd,
                       ami_fecha_cambio
                   )
                   SELECT i.msi_codigo,
                          i.sif_codigo,
                          i.msi_nombre_modulo,
                          i.msi_usuarios_objetivo,
                          i.msi_esta_activo,
                          @per_actor,
                          'I',
                          ORIGINAL_LOGIN(),
                          SYSDATETIMEOFFSET()
                   FROM   inserted AS i;
                   RETURN;
               END
           INSERT INTO sgspi.aud_modulo_sistema_informacion (
               msi_codigo,
               sif_codigo,
               ami_nombre_modulo,
               ami_usuarios_objetivo,
               ami_esta_activo,
               per_codigo,
               ami_operacion,
               ami_usuario_bd,
               ami_fecha_cambio
           )
           SELECT d.msi_codigo,
                  d.sif_codigo,
                  d.msi_nombre_modulo,
                  d.msi_usuarios_objetivo,
                  d.msi_esta_activo,
                  @per_actor,
                  'U',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   deleted AS d
                  INNER JOIN
                  inserted AS i
                  ON i.msi_codigo = d.msi_codigo
           WHERE  EXISTS (SELECT i.sif_codigo,
                                 i.msi_nombre_modulo,
                                 i.msi_usuarios_objetivo,
                                 i.msi_esta_activo
                          EXCEPT
                          SELECT d.sif_codigo,
                                 d.msi_nombre_modulo,
                                 d.msi_usuarios_objetivo,
                                 d.msi_esta_activo);
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [aso] La auditoría no se edita ni se borra
CREATE OR ALTER TRIGGER sgspi.TR_aso_inmutabilidad
    ON sgspi.aud_serie_documental_catalogo
    INSTEAD OF UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           THROW 50016, N'Operación denegada: la tabla de auditoría [sgspi].[aud_serie_documental_catalogo] es inmutable y no admite modificaciones ni borrados.', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [sdo] Bloquea el borrado físico y archiva en [sgspi].[aud_serie_documental_catalogo] las altas ('I') y la versión anterior de cada fila modificada ('U')
CREATE OR ALTER TRIGGER sgspi.TR_sdo_auditoria
    ON sgspi.serie_documental_catalogo
    AFTER INSERT, UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           IF EXISTS (SELECT 1
                      FROM   deleted)
              AND NOT EXISTS (SELECT 1
                              FROM   inserted)
               THROW 50010, N'Operación denegada: No se permite eliminar físicamente registros de [sgspi].[serie_documental_catalogo].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona en [dbo].[usuario_general] para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_serie_documental_catalogo (
                       sdo_codigo,
                       aso_numero_ccd,
                       aso_nombre_serie,
                       aso_esta_activa,
                       per_codigo,
                       aso_operacion,
                       aso_usuario_bd,
                       aso_fecha_cambio
                   )
                   SELECT i.sdo_codigo,
                          i.sdo_numero_ccd,
                          i.sdo_nombre_serie,
                          i.sdo_esta_activa,
                          @per_actor,
                          'I',
                          ORIGINAL_LOGIN(),
                          SYSDATETIMEOFFSET()
                   FROM   inserted AS i;
                   RETURN;
               END
           INSERT INTO sgspi.aud_serie_documental_catalogo (
               sdo_codigo,
               aso_numero_ccd,
               aso_nombre_serie,
               aso_esta_activa,
               per_codigo,
               aso_operacion,
               aso_usuario_bd,
               aso_fecha_cambio
           )
           SELECT d.sdo_codigo,
                  d.sdo_numero_ccd,
                  d.sdo_nombre_serie,
                  d.sdo_esta_activa,
                  @per_actor,
                  'U',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   deleted AS d
                  INNER JOIN
                  inserted AS i
                  ON i.sdo_codigo = d.sdo_codigo
           WHERE  EXISTS (SELECT i.sdo_numero_ccd,
                                 i.sdo_nombre_serie,
                                 i.sdo_esta_activa
                          EXCEPT
                          SELECT d.sdo_numero_ccd,
                                 d.sdo_nombre_serie,
                                 d.sdo_esta_activa);
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [asd] La auditoría no se edita ni se borra
CREATE OR ALTER TRIGGER sgspi.TR_asd_inmutabilidad
    ON sgspi.aud_subserie_documental_catalogo
    INSTEAD OF UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           THROW 50016, N'Operación denegada: la tabla de auditoría [sgspi].[aud_subserie_documental_catalogo] es inmutable y no admite modificaciones ni borrados.', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [sbd] Bloquea el borrado físico y archiva en [sgspi].[aud_subserie_documental_catalogo] las altas ('I') y la versión anterior de cada fila modificada ('U')
CREATE OR ALTER TRIGGER sgspi.TR_sbd_auditoria
    ON sgspi.subserie_documental_catalogo
    AFTER INSERT, UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           IF EXISTS (SELECT 1
                      FROM   deleted)
              AND NOT EXISTS (SELECT 1
                              FROM   inserted)
               THROW 50010, N'Operación denegada: No se permite eliminar físicamente registros de [sgspi].[subserie_documental_catalogo].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona en [dbo].[usuario_general] para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_subserie_documental_catalogo (
                       sbd_codigo,
                       sdo_codigo,
                       asd_numero_ccd,
                       asd_nombre_subserie,
                       asd_esta_activa,
                       per_codigo,
                       asd_operacion,
                       asd_usuario_bd,
                       asd_fecha_cambio
                   )
                   SELECT i.sbd_codigo,
                          i.sdo_codigo,
                          i.sbd_numero_ccd,
                          i.sbd_nombre_subserie,
                          i.sbd_esta_activa,
                          @per_actor,
                          'I',
                          ORIGINAL_LOGIN(),
                          SYSDATETIMEOFFSET()
                   FROM   inserted AS i;
                   RETURN;
               END
           INSERT INTO sgspi.aud_subserie_documental_catalogo (
               sbd_codigo,
               sdo_codigo,
               asd_numero_ccd,
               asd_nombre_subserie,
               asd_esta_activa,
               per_codigo,
               asd_operacion,
               asd_usuario_bd,
               asd_fecha_cambio
           )
           SELECT d.sbd_codigo,
                  d.sdo_codigo,
                  d.sbd_numero_ccd,
                  d.sbd_nombre_subserie,
                  d.sbd_esta_activa,
                  @per_actor,
                  'U',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   deleted AS d
                  INNER JOIN
                  inserted AS i
                  ON i.sbd_codigo = d.sbd_codigo
           WHERE  EXISTS (SELECT i.sdo_codigo,
                                 i.sbd_numero_ccd,
                                 i.sbd_nombre_subserie,
                                 i.sbd_esta_activa
                          EXCEPT
                          SELECT d.sdo_codigo,
                                 d.sbd_numero_ccd,
                                 d.sbd_nombre_subserie,
                                 d.sbd_esta_activa);
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [auc] La auditoría no se edita ni se borra
CREATE OR ALTER TRIGGER sgspi.TR_auc_inmutabilidad
    ON sgspi.aud_unidad_productora_cuadro_clasificacion_documental
    INSTEAD OF UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           THROW 50016, N'Operación denegada: la tabla de auditoría [sgspi].[aud_unidad_productora_cuadro_clasificacion_documental] es inmutable y no admite modificaciones ni borrados.', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [upc] Bloquea el borrado físico y archiva en [sgspi].[aud_unidad_productora_cuadro_clasificacion_documental] las altas ('I') y la versión anterior de cada fila modificada ('U')
CREATE OR ALTER TRIGGER sgspi.TR_upc_auditoria
    ON sgspi.unidad_productora_cuadro_clasificacion_documental
    AFTER INSERT, UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           IF EXISTS (SELECT 1
                      FROM   deleted)
              AND NOT EXISTS (SELECT 1
                              FROM   inserted)
               THROW 50010, N'Operación denegada: No se permite eliminar físicamente registros de [sgspi].[unidad_productora_cuadro_clasificacion_documental].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona en [dbo].[usuario_general] para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_unidad_productora_cuadro_clasificacion_documental (
                       upc_codigo,
                       auc_nodo_jerarquico,
                       auc_codigo_archivistico,
                       uaa_codigo,
                       auc_nombre_unidad,
                       auc_esta_activa,
                       per_codigo,
                       auc_operacion,
                       auc_usuario_bd,
                       auc_fecha_cambio
                   )
                   SELECT i.upc_codigo,
                          i.upc_nodo_jerarquico,
                          i.upc_codigo_archivistico,
                          i.uaa_codigo,
                          i.upc_nombre_unidad,
                          i.upc_esta_activa,
                          @per_actor,
                          'I',
                          ORIGINAL_LOGIN(),
                          SYSDATETIMEOFFSET()
                   FROM   inserted AS i;
                   RETURN;
               END
           INSERT INTO sgspi.aud_unidad_productora_cuadro_clasificacion_documental (
               upc_codigo,
               auc_nodo_jerarquico,
               auc_codigo_archivistico,
               uaa_codigo,
               auc_nombre_unidad,
               auc_esta_activa,
               per_codigo,
               auc_operacion,
               auc_usuario_bd,
               auc_fecha_cambio
           )
           SELECT d.upc_codigo,
                  d.upc_nodo_jerarquico,
                  d.upc_codigo_archivistico,
                  d.uaa_codigo,
                  d.upc_nombre_unidad,
                  d.upc_esta_activa,
                  @per_actor,
                  'U',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   deleted AS d
                  INNER JOIN
                  inserted AS i
                  ON i.upc_codigo = d.upc_codigo
           WHERE  EXISTS (SELECT i.upc_nodo_jerarquico,
                                 i.upc_codigo_archivistico,
                                 i.uaa_codigo,
                                 i.upc_nombre_unidad,
                                 i.upc_esta_activa
                          EXCEPT
                          SELECT d.upc_nodo_jerarquico,
                                 d.upc_codigo_archivistico,
                                 d.uaa_codigo,
                                 d.upc_nombre_unidad,
                                 d.upc_esta_activa);
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [apc] La auditoría no se edita ni se borra
CREATE OR ALTER TRIGGER sgspi.TR_apc_inmutabilidad
    ON sgspi.aud_periodicidad_catalogo
    INSTEAD OF UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           THROW 50016, N'Operación denegada: la tabla de auditoría [sgspi].[aud_periodicidad_catalogo] es inmutable y no admite modificaciones ni borrados.', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [pdc] Bloquea el borrado físico y archiva en [sgspi].[aud_periodicidad_catalogo] las altas ('I') y la versión anterior de cada fila modificada ('U')
CREATE OR ALTER TRIGGER sgspi.TR_pdc_auditoria
    ON sgspi.periodicidad_catalogo
    AFTER INSERT, UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           IF EXISTS (SELECT 1
                      FROM   deleted)
              AND NOT EXISTS (SELECT 1
                              FROM   inserted)
               THROW 50010, N'Operación denegada: No se permite eliminar físicamente registros de [sgspi].[periodicidad_catalogo].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona en [dbo].[usuario_general] para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_periodicidad_catalogo (
                       pdc_codigo,
                       apc_nombre,
                       apc_orden,
                       apc_esta_activa,
                       per_codigo,
                       apc_operacion,
                       apc_usuario_bd,
                       apc_fecha_cambio
                   )
                   SELECT i.pdc_codigo,
                          i.pdc_nombre,
                          i.pdc_orden,
                          i.pdc_esta_activa,
                          @per_actor,
                          'I',
                          ORIGINAL_LOGIN(),
                          SYSDATETIMEOFFSET()
                   FROM   inserted AS i;
                   RETURN;
               END
           INSERT INTO sgspi.aud_periodicidad_catalogo (
               pdc_codigo,
               apc_nombre,
               apc_orden,
               apc_esta_activa,
               per_codigo,
               apc_operacion,
               apc_usuario_bd,
               apc_fecha_cambio
           )
           SELECT d.pdc_codigo,
                  d.pdc_nombre,
                  d.pdc_orden,
                  d.pdc_esta_activa,
                  @per_actor,
                  'U',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   deleted AS d
                  INNER JOIN
                  inserted AS i
                  ON i.pdc_codigo = d.pdc_codigo
           WHERE  EXISTS (SELECT i.pdc_nombre,
                                 i.pdc_orden,
                                 i.pdc_esta_activa
                          EXCEPT
                          SELECT d.pdc_nombre,
                                 d.pdc_orden,
                                 d.pdc_esta_activa);
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [aep] La auditoría no se edita ni se borra
CREATE OR ALTER TRIGGER sgspi.TR_aep_inmutabilidad
    ON sgspi.aud_estado_publicacion_catalogo
    INSTEAD OF UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           THROW 50016, N'Operación denegada: la tabla de auditoría [sgspi].[aud_estado_publicacion_catalogo] es inmutable y no admite modificaciones ni borrados.', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [epc] Bloquea el borrado físico y archiva en [sgspi].[aud_estado_publicacion_catalogo] las altas ('I') y la versión anterior de cada fila modificada ('U')
CREATE OR ALTER TRIGGER sgspi.TR_epc_auditoria
    ON sgspi.estado_publicacion_catalogo
    AFTER INSERT, UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           IF EXISTS (SELECT 1
                      FROM   deleted)
              AND NOT EXISTS (SELECT 1
                              FROM   inserted)
               THROW 50010, N'Operación denegada: No se permite eliminar físicamente registros de [sgspi].[estado_publicacion_catalogo].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona en [dbo].[usuario_general] para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_estado_publicacion_catalogo (
                       epc_codigo,
                       aep_nombre,
                       aep_descripcion,
                       aep_esta_activo,
                       per_codigo,
                       aep_operacion,
                       aep_usuario_bd,
                       aep_fecha_cambio
                   )
                   SELECT i.epc_codigo,
                          i.epc_nombre,
                          i.epc_descripcion,
                          i.epc_esta_activo,
                          @per_actor,
                          'I',
                          ORIGINAL_LOGIN(),
                          SYSDATETIMEOFFSET()
                   FROM   inserted AS i;
                   RETURN;
               END
           INSERT INTO sgspi.aud_estado_publicacion_catalogo (
               epc_codigo,
               aep_nombre,
               aep_descripcion,
               aep_esta_activo,
               per_codigo,
               aep_operacion,
               aep_usuario_bd,
               aep_fecha_cambio
           )
           SELECT d.epc_codigo,
                  d.epc_nombre,
                  d.epc_descripcion,
                  d.epc_esta_activo,
                  @per_actor,
                  'U',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   deleted AS d
                  INNER JOIN
                  inserted AS i
                  ON i.epc_codigo = d.epc_codigo
           WHERE  EXISTS (SELECT i.epc_nombre,
                                 i.epc_descripcion,
                                 i.epc_esta_activo
                          EXCEPT
                          SELECT d.epc_nombre,
                                 d.epc_descripcion,
                                 d.epc_esta_activo);
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [asc] La auditoría no se edita ni se borra
CREATE OR ALTER TRIGGER sgspi.TR_asc_inmutabilidad
    ON sgspi.aud_soporte_registro_catalogo
    INSTEAD OF UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           THROW 50016, N'Operación denegada: la tabla de auditoría [sgspi].[aud_soporte_registro_catalogo] es inmutable y no admite modificaciones ni borrados.', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [src] Bloquea el borrado físico y archiva en [sgspi].[aud_soporte_registro_catalogo] las altas ('I') y la versión anterior de cada fila modificada ('U')
CREATE OR ALTER TRIGGER sgspi.TR_src_auditoria
    ON sgspi.soporte_registro_catalogo
    AFTER INSERT, UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           IF EXISTS (SELECT 1
                      FROM   deleted)
              AND NOT EXISTS (SELECT 1
                              FROM   inserted)
               THROW 50010, N'Operación denegada: No se permite eliminar físicamente registros de [sgspi].[soporte_registro_catalogo].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona en [dbo].[usuario_general] para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_soporte_registro_catalogo (
                       src_codigo,
                       asc_nombre,
                       asc_esta_activo,
                       per_codigo,
                       asc_operacion,
                       asc_usuario_bd,
                       asc_fecha_cambio
                   )
                   SELECT i.src_codigo,
                          i.src_nombre,
                          i.src_esta_activo,
                          @per_actor,
                          'I',
                          ORIGINAL_LOGIN(),
                          SYSDATETIMEOFFSET()
                   FROM   inserted AS i;
                   RETURN;
               END
           INSERT INTO sgspi.aud_soporte_registro_catalogo (
               src_codigo,
               asc_nombre,
               asc_esta_activo,
               per_codigo,
               asc_operacion,
               asc_usuario_bd,
               asc_fecha_cambio
           )
           SELECT d.src_codigo,
                  d.src_nombre,
                  d.src_esta_activo,
                  @per_actor,
                  'U',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   deleted AS d
                  INNER JOIN
                  inserted AS i
                  ON i.src_codigo = d.src_codigo
           WHERE  EXISTS (SELECT i.src_nombre,
                                 i.src_esta_activo
                          EXCEPT
                          SELECT d.src_nombre,
                                 d.src_esta_activo);
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [amc] La auditoría no se edita ni se borra
CREATE OR ALTER TRIGGER sgspi.TR_amc_inmutabilidad
    ON sgspi.aud_medio_conservacion_catalogo
    INSTEAD OF UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           THROW 50016, N'Operación denegada: la tabla de auditoría [sgspi].[aud_medio_conservacion_catalogo] es inmutable y no admite modificaciones ni borrados.', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [mcc] Bloquea el borrado físico y archiva en [sgspi].[aud_medio_conservacion_catalogo] las altas ('I') y la versión anterior de cada fila modificada ('U')
CREATE OR ALTER TRIGGER sgspi.TR_mcc_auditoria
    ON sgspi.medio_conservacion_catalogo
    AFTER INSERT, UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           IF EXISTS (SELECT 1
                      FROM   deleted)
              AND NOT EXISTS (SELECT 1
                              FROM   inserted)
               THROW 50010, N'Operación denegada: No se permite eliminar físicamente registros de [sgspi].[medio_conservacion_catalogo].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona en [dbo].[usuario_general] para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_medio_conservacion_catalogo (
                       mcc_codigo,
                       amc_nombre,
                       amc_esta_activo,
                       per_codigo,
                       amc_operacion,
                       amc_usuario_bd,
                       amc_fecha_cambio
                   )
                   SELECT i.mcc_codigo,
                          i.mcc_nombre,
                          i.mcc_esta_activo,
                          @per_actor,
                          'I',
                          ORIGINAL_LOGIN(),
                          SYSDATETIMEOFFSET()
                   FROM   inserted AS i;
                   RETURN;
               END
           INSERT INTO sgspi.aud_medio_conservacion_catalogo (
               mcc_codigo,
               amc_nombre,
               amc_esta_activo,
               per_codigo,
               amc_operacion,
               amc_usuario_bd,
               amc_fecha_cambio
           )
           SELECT d.mcc_codigo,
                  d.mcc_nombre,
                  d.mcc_esta_activo,
                  @per_actor,
                  'U',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   deleted AS d
                  INNER JOIN
                  inserted AS i
                  ON i.mcc_codigo = d.mcc_codigo
           WHERE  EXISTS (SELECT i.mcc_nombre,
                                 i.mcc_esta_activo
                          EXCEPT
                          SELECT d.mcc_nombre,
                                 d.mcc_esta_activo);
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [aii] La auditoría no se edita ni se borra
CREATE OR ALTER TRIGGER sgspi.TR_aii_inmutabilidad
    ON sgspi.aud_idioma_catalogo
    INSTEAD OF UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           THROW 50016, N'Operación denegada: la tabla de auditoría [sgspi].[aud_idioma_catalogo] es inmutable y no admite modificaciones ni borrados.', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [idi] Bloquea el borrado físico y archiva en [sgspi].[aud_idioma_catalogo] las altas ('I') y la versión anterior de cada fila modificada ('U')
CREATE OR ALTER TRIGGER sgspi.TR_idi_auditoria
    ON sgspi.idioma_catalogo
    AFTER INSERT, UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           IF EXISTS (SELECT 1
                      FROM   deleted)
              AND NOT EXISTS (SELECT 1
                              FROM   inserted)
               THROW 50010, N'Operación denegada: No se permite eliminar físicamente registros de [sgspi].[idioma_catalogo].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona en [dbo].[usuario_general] para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_idioma_catalogo (
                       idi_codigo,
                       aii_codigo_iso,
                       aii_nombre,
                       aii_esta_activo,
                       per_codigo,
                       aii_operacion,
                       aii_usuario_bd,
                       aii_fecha_cambio
                   )
                   SELECT i.idi_codigo,
                          i.idi_codigo_iso,
                          i.idi_nombre,
                          i.idi_esta_activo,
                          @per_actor,
                          'I',
                          ORIGINAL_LOGIN(),
                          SYSDATETIMEOFFSET()
                   FROM   inserted AS i;
                   RETURN;
               END
           INSERT INTO sgspi.aud_idioma_catalogo (
               idi_codigo,
               aii_codigo_iso,
               aii_nombre,
               aii_esta_activo,
               per_codigo,
               aii_operacion,
               aii_usuario_bd,
               aii_fecha_cambio
           )
           SELECT d.idi_codigo,
                  d.idi_codigo_iso,
                  d.idi_nombre,
                  d.idi_esta_activo,
                  @per_actor,
                  'U',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   deleted AS d
                  INNER JOIN
                  inserted AS i
                  ON i.idi_codigo = d.idi_codigo
           WHERE  EXISTS (SELECT i.idi_codigo_iso,
                                 i.idi_nombre,
                                 i.idi_esta_activo
                          EXCEPT
                          SELECT d.idi_codigo_iso,
                                 d.idi_nombre,
                                 d.idi_esta_activo);
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [afa] La auditoría no se edita ni se borra
CREATE OR ALTER TRIGGER sgspi.TR_afa_inmutabilidad
    ON sgspi.aud_formato_archivo_catalogo
    INSTEAD OF UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           THROW 50016, N'Operación denegada: la tabla de auditoría [sgspi].[aud_formato_archivo_catalogo] es inmutable y no admite modificaciones ni borrados.', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [fac] Bloquea el borrado físico y archiva en [sgspi].[aud_formato_archivo_catalogo] las altas ('I') y la versión anterior de cada fila modificada ('U')
CREATE OR ALTER TRIGGER sgspi.TR_fac_auditoria
    ON sgspi.formato_archivo_catalogo
    AFTER INSERT, UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           IF EXISTS (SELECT 1
                      FROM   deleted)
              AND NOT EXISTS (SELECT 1
                              FROM   inserted)
               THROW 50010, N'Operación denegada: No se permite eliminar físicamente registros de [sgspi].[formato_archivo_catalogo].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona en [dbo].[usuario_general] para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_formato_archivo_catalogo (
                       fac_codigo,
                       afa_nombre,
                       afa_esta_activo,
                       per_codigo,
                       afa_operacion,
                       afa_usuario_bd,
                       afa_fecha_cambio
                   )
                   SELECT i.fac_codigo,
                          i.fac_nombre,
                          i.fac_esta_activo,
                          @per_actor,
                          'I',
                          ORIGINAL_LOGIN(),
                          SYSDATETIMEOFFSET()
                   FROM   inserted AS i;
                   RETURN;
               END
           INSERT INTO sgspi.aud_formato_archivo_catalogo (
               fac_codigo,
               afa_nombre,
               afa_esta_activo,
               per_codigo,
               afa_operacion,
               afa_usuario_bd,
               afa_fecha_cambio
           )
           SELECT d.fac_codigo,
                  d.fac_nombre,
                  d.fac_esta_activo,
                  @per_actor,
                  'U',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   deleted AS d
                  INNER JOIN
                  inserted AS i
                  ON i.fac_codigo = d.fac_codigo
           WHERE  EXISTS (SELECT i.fac_nombre,
                                 i.fac_esta_activo
                          EXCEPT
                          SELECT d.fac_nombre,
                                 d.fac_esta_activo);
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [aao] La auditoría no se edita ni se borra
CREATE OR ALTER TRIGGER sgspi.TR_aao_inmutabilidad
    ON sgspi.aud_activo_documental
    INSTEAD OF UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           THROW 50016, N'Operación denegada: la tabla de auditoría [sgspi].[aud_activo_documental] es inmutable y no admite modificaciones ni borrados.', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [aad] La auditoría no se edita ni se borra
CREATE OR ALTER TRIGGER sgspi.TR_aad_inmutabilidad
    ON sgspi.aud_activo_documental_soporte_registro
    INSTEAD OF UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           THROW 50016, N'Operación denegada: la tabla de auditoría [sgspi].[aud_activo_documental_soporte_registro] es inmutable y no admite modificaciones ni borrados.', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [ads] Bloquea el borrado físico y archiva en [sgspi].[aud_activo_documental_soporte_registro] las altas ('I') y la versión anterior de cada fila modificada ('U')
CREATE OR ALTER TRIGGER sgspi.TR_ads_auditoria
    ON sgspi.activo_documental_soporte_registro
    AFTER INSERT, UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           IF EXISTS (SELECT 1
                      FROM   deleted)
              AND NOT EXISTS (SELECT 1
                              FROM   inserted)
               THROW 50010, N'Operación denegada: No se permite eliminar físicamente registros de [sgspi].[activo_documental_soporte_registro].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona en [dbo].[usuario_general] para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_activo_documental_soporte_registro (
                       ado_codigo,
                       src_codigo,
                       aad_esta_activo,
                       per_codigo,
                       aad_operacion,
                       aad_usuario_bd,
                       aad_fecha_cambio
                   )
                   SELECT i.ado_codigo,
                          i.src_codigo,
                          i.ads_esta_activo,
                          @per_actor,
                          'I',
                          ORIGINAL_LOGIN(),
                          SYSDATETIMEOFFSET()
                   FROM   inserted AS i;
                   RETURN;
               END
           IF EXISTS (SELECT 1
                      FROM   deleted AS d
                      WHERE  NOT EXISTS (SELECT 1
                                         FROM   inserted AS i
                                         WHERE  i.ado_codigo = d.ado_codigo
                                                AND i.src_codigo = d.src_codigo))
               THROW 50011, N'Operación denegada: No se permite cambiar la clave de [sgspi].[activo_documental_soporte_registro]; desactive la fila y cree una nueva.', 1;
           INSERT INTO sgspi.aud_activo_documental_soporte_registro (
               ado_codigo,
               src_codigo,
               aad_esta_activo,
               per_codigo,
               aad_operacion,
               aad_usuario_bd,
               aad_fecha_cambio
           )
           SELECT d.ado_codigo,
                  d.src_codigo,
                  d.ads_esta_activo,
                  @per_actor,
                  'U',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   deleted AS d
                  INNER JOIN
                  inserted AS i
                  ON i.ado_codigo = d.ado_codigo
                     AND i.src_codigo = d.src_codigo
           WHERE  EXISTS (SELECT i.ads_esta_activo
                          EXCEPT
                          SELECT d.ads_esta_activo);
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [aam] La auditoría no se edita ni se borra
CREATE OR ALTER TRIGGER sgspi.TR_aam_inmutabilidad
    ON sgspi.aud_activo_documental_medio_conservacion
    INSTEAD OF UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           THROW 50016, N'Operación denegada: la tabla de auditoría [sgspi].[aud_activo_documental_medio_conservacion] es inmutable y no admite modificaciones ni borrados.', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [adm] Bloquea el borrado físico y archiva en [sgspi].[aud_activo_documental_medio_conservacion] las altas ('I') y la versión anterior de cada fila modificada ('U')
CREATE OR ALTER TRIGGER sgspi.TR_adm_auditoria
    ON sgspi.activo_documental_medio_conservacion
    AFTER INSERT, UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           IF EXISTS (SELECT 1
                      FROM   deleted)
              AND NOT EXISTS (SELECT 1
                              FROM   inserted)
               THROW 50010, N'Operación denegada: No se permite eliminar físicamente registros de [sgspi].[activo_documental_medio_conservacion].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona en [dbo].[usuario_general] para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_activo_documental_medio_conservacion (
                       ado_codigo,
                       mcc_codigo,
                       aam_esta_activo,
                       per_codigo,
                       aam_operacion,
                       aam_usuario_bd,
                       aam_fecha_cambio
                   )
                   SELECT i.ado_codigo,
                          i.mcc_codigo,
                          i.adm_esta_activo,
                          @per_actor,
                          'I',
                          ORIGINAL_LOGIN(),
                          SYSDATETIMEOFFSET()
                   FROM   inserted AS i;
                   RETURN;
               END
           IF EXISTS (SELECT 1
                      FROM   deleted AS d
                      WHERE  NOT EXISTS (SELECT 1
                                         FROM   inserted AS i
                                         WHERE  i.ado_codigo = d.ado_codigo
                                                AND i.mcc_codigo = d.mcc_codigo))
               THROW 50011, N'Operación denegada: No se permite cambiar la clave de [sgspi].[activo_documental_medio_conservacion]; desactive la fila y cree una nueva.', 1;
           INSERT INTO sgspi.aud_activo_documental_medio_conservacion (
               ado_codigo,
               mcc_codigo,
               aam_esta_activo,
               per_codigo,
               aam_operacion,
               aam_usuario_bd,
               aam_fecha_cambio
           )
           SELECT d.ado_codigo,
                  d.mcc_codigo,
                  d.adm_esta_activo,
                  @per_actor,
                  'U',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   deleted AS d
                  INNER JOIN
                  inserted AS i
                  ON i.ado_codigo = d.ado_codigo
                     AND i.mcc_codigo = d.mcc_codigo
           WHERE  EXISTS (SELECT i.adm_esta_activo
                          EXCEPT
                          SELECT d.adm_esta_activo);
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [aid] La auditoría no se edita ni se borra
CREATE OR ALTER TRIGGER sgspi.TR_aid_inmutabilidad
    ON sgspi.aud_activo_documental_idioma
    INSTEAD OF UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           THROW 50016, N'Operación denegada: la tabla de auditoría [sgspi].[aud_activo_documental_idioma] es inmutable y no admite modificaciones ni borrados.', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [adi] Bloquea el borrado físico y archiva en [sgspi].[aud_activo_documental_idioma] las altas ('I') y la versión anterior de cada fila modificada ('U')
CREATE OR ALTER TRIGGER sgspi.TR_adi_auditoria
    ON sgspi.activo_documental_idioma
    AFTER INSERT, UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           IF EXISTS (SELECT 1
                      FROM   deleted)
              AND NOT EXISTS (SELECT 1
                              FROM   inserted)
               THROW 50010, N'Operación denegada: No se permite eliminar físicamente registros de [sgspi].[activo_documental_idioma].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona en [dbo].[usuario_general] para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_activo_documental_idioma (
                       ado_codigo,
                       idi_codigo,
                       aid_esta_activo,
                       per_codigo,
                       aid_operacion,
                       aid_usuario_bd,
                       aid_fecha_cambio
                   )
                   SELECT i.ado_codigo,
                          i.idi_codigo,
                          i.adi_esta_activo,
                          @per_actor,
                          'I',
                          ORIGINAL_LOGIN(),
                          SYSDATETIMEOFFSET()
                   FROM   inserted AS i;
                   RETURN;
               END
           IF EXISTS (SELECT 1
                      FROM   deleted AS d
                      WHERE  NOT EXISTS (SELECT 1
                                         FROM   inserted AS i
                                         WHERE  i.ado_codigo = d.ado_codigo
                                                AND i.idi_codigo = d.idi_codigo))
               THROW 50011, N'Operación denegada: No se permite cambiar la clave de [sgspi].[activo_documental_idioma]; desactive la fila y cree una nueva.', 1;
           INSERT INTO sgspi.aud_activo_documental_idioma (
               ado_codigo,
               idi_codigo,
               aid_esta_activo,
               per_codigo,
               aid_operacion,
               aid_usuario_bd,
               aid_fecha_cambio
           )
           SELECT d.ado_codigo,
                  d.idi_codigo,
                  d.adi_esta_activo,
                  @per_actor,
                  'U',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   deleted AS d
                  INNER JOIN
                  inserted AS i
                  ON i.ado_codigo = d.ado_codigo
                     AND i.idi_codigo = d.idi_codigo
           WHERE  EXISTS (SELECT i.adi_esta_activo
                          EXCEPT
                          SELECT d.adi_esta_activo);
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [afd] La auditoría no se edita ni se borra
CREATE OR ALTER TRIGGER sgspi.TR_afd_inmutabilidad
    ON sgspi.aud_activo_documental_formato_archivo
    INSTEAD OF UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           THROW 50016, N'Operación denegada: la tabla de auditoría [sgspi].[aud_activo_documental_formato_archivo] es inmutable y no admite modificaciones ni borrados.', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [adf] Bloquea el borrado físico y archiva en [sgspi].[aud_activo_documental_formato_archivo] las altas ('I') y la versión anterior de cada fila modificada ('U')
CREATE OR ALTER TRIGGER sgspi.TR_adf_auditoria
    ON sgspi.activo_documental_formato_archivo
    AFTER INSERT, UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           IF EXISTS (SELECT 1
                      FROM   deleted)
              AND NOT EXISTS (SELECT 1
                              FROM   inserted)
               THROW 50010, N'Operación denegada: No se permite eliminar físicamente registros de [sgspi].[activo_documental_formato_archivo].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona en [dbo].[usuario_general] para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_activo_documental_formato_archivo (
                       ado_codigo,
                       fac_codigo,
                       afd_esta_activo,
               THROW 50017, N'No se encontró una persona en [dbo].[usuario_general] para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_activo_documental_unidad_productora (
                       ado_codigo,
                       upc_codigo,
                       aau_esta_activo,
                       per_codigo,
                       aau_operacion,
                       aau_usuario_bd,
                       aau_fecha_cambio
                   )
                   SELECT i.ado_codigo,
                          i.upc_codigo,
                          i.adu_esta_activo,
                          @per_actor,
                          'I',
                          ORIGINAL_LOGIN(),
                          SYSDATETIMEOFFSET()
                   FROM   inserted AS i;
                   RETURN;
               END
           IF EXISTS (SELECT 1
                      FROM   deleted AS d
                      WHERE  NOT EXISTS (SELECT 1
                                         FROM   inserted AS i
                                         WHERE  i.ado_codigo = d.ado_codigo
                                                AND i.upc_codigo = d.upc_codigo))
               THROW 50011, N'Operación denegada: No se permite cambiar la clave de [sgspi].[activo_documental_unidad_productora]; desactive la fila y cree una nueva.', 1;
           INSERT INTO sgspi.aud_activo_documental_unidad_productora (
               ado_codigo,
               upc_codigo,
               aau_esta_activo,
               per_codigo,
               aau_operacion,
               aau_usuario_bd,
               aau_fecha_cambio
           )
           SELECT d.ado_codigo,
                  d.upc_codigo,
                  d.adu_esta_activo,
                  @per_actor,
                  'U',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   deleted AS d
                  INNER JOIN
                  inserted AS i
                  ON i.ado_codigo = d.ado_codigo
                     AND i.upc_codigo = d.upc_codigo
           WHERE  EXISTS (SELECT i.adu_esta_activo
                          EXCEPT
                          SELECT d.adu_esta_activo);
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [aer] La auditoría no se edita ni se borra
CREATE OR ALTER TRIGGER sgspi.TR_aer_inmutabilidad
    ON sgspi.aud_escala_probabilidad
    INSTEAD OF UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           THROW 50016, N'Operación denegada: la tabla de auditoría [sgspi].[aud_escala_probabilidad] es inmutable y no admite modificaciones ni borrados.', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [epr] Bloquea el borrado físico y archiva en [sgspi].[aud_escala_probabilidad] las altas ('I') y la versión anterior de cada fila modificada ('U')
CREATE OR ALTER TRIGGER sgspi.TR_epr_auditoria
    ON sgspi.escala_probabilidad
    AFTER INSERT, UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           IF EXISTS (SELECT 1
                      FROM   deleted)
              AND NOT EXISTS (SELECT 1
                              FROM   inserted)
               THROW 50010, N'Operación denegada: No se permite eliminar físicamente registros de [sgspi].[escala_probabilidad].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona en [dbo].[usuario_general] para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_escala_probabilidad (
                       epr_codigo,
                       aer_codigo_letra,
                       aer_nombre_nivel,
                       aer_descripcion_criterio,
                       aer_frecuencia_referencia,
                       aer_esta_activa,
                       per_codigo,
                       aer_operacion,
                       aer_usuario_bd,
                       aer_fecha_cambio
                   )
                   SELECT i.epr_codigo,
                          i.epr_codigo_letra,
                          i.epr_nombre_nivel,
                          i.epr_descripcion_criterio,
                          i.epr_frecuencia_referencia,
                          i.epr_esta_activa,
                          @per_actor,
                          'I',
                          ORIGINAL_LOGIN(),
                          SYSDATETIMEOFFSET()
                   FROM   inserted AS i;
                   RETURN;
               END
           IF EXISTS (SELECT 1
                      FROM   deleted AS d
                      WHERE  NOT EXISTS (SELECT 1
                                         FROM   inserted AS i
                                         WHERE  i.epr_codigo = d.epr_codigo))
               THROW 50011, N'Operación denegada: No se permite cambiar la clave de [sgspi].[escala_probabilidad]; desactive la fila y cree una nueva.', 1;
           INSERT INTO sgspi.aud_escala_probabilidad (
               epr_codigo,
               aer_codigo_letra,
               aer_nombre_nivel,
               aer_descripcion_criterio,
               aer_frecuencia_referencia,
               aer_esta_activa,
               per_codigo,
               aer_operacion,
               aer_usuario_bd,
               aer_fecha_cambio
           )
           SELECT d.epr_codigo,
                  d.epr_codigo_letra,
                  d.epr_nombre_nivel,
                  d.epr_descripcion_criterio,
                  d.epr_frecuencia_referencia,
                  d.epr_esta_activa,
                  @per_actor,
                  'U',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   deleted AS d
                  INNER JOIN
                  inserted AS i
                  ON i.epr_codigo = d.epr_codigo
           WHERE  EXISTS (SELECT i.epr_codigo_letra,
                                 i.epr_nombre_nivel,
                                 i.epr_descripcion_criterio,
                                 i.epr_frecuencia_referencia,
                                 i.epr_esta_activa
                          EXCEPT
                          SELECT d.epr_codigo_letra,
                                 d.epr_nombre_nivel,
                                 d.epr_descripcion_criterio,
                                 d.epr_frecuencia_referencia,
                                 d.epr_esta_activa);
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [aem] La auditoría no se edita ni se borra
CREATE OR ALTER TRIGGER sgspi.TR_aem_inmutabilidad
    ON sgspi.aud_escala_impacto
    INSTEAD OF UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           THROW 50016, N'Operación denegada: la tabla de auditoría [sgspi].[aud_escala_impacto] es inmutable y no admite modificaciones ni borrados.', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [eim] Bloquea el borrado físico y archiva en [sgspi].[aud_escala_impacto] las altas ('I') y la versión anterior de cada fila modificada ('U')
CREATE OR ALTER TRIGGER sgspi.TR_eim_auditoria
    ON sgspi.escala_impacto
    AFTER INSERT, UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           IF EXISTS (SELECT 1
                      FROM   deleted)
              AND NOT EXISTS (SELECT 1
                              FROM   inserted)
               THROW 50010, N'Operación denegada: No se permite eliminar físicamente registros de [sgspi].[escala_impacto].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona en [dbo].[usuario_general] para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_escala_impacto (
                       eim_codigo,
                       aem_nombre_impacto_negativo,
                       aem_nombre_impacto_positivo,
                       aem_descripcion_organizacional,
                       aem_descripcion_operativa,
                       aem_esta_activa,
                       per_codigo,
                       aem_operacion,
                       aem_usuario_bd,
                       aem_fecha_cambio
                   )
                   SELECT i.eim_codigo,
                          i.eim_nombre_impacto_negativo,
                          i.eim_nombre_impacto_positivo,
                          i.eim_descripcion_organizacional,
                          i.eim_descripcion_operativa,
                          i.eim_esta_activa,
                          @per_actor,
                          'I',
                          ORIGINAL_LOGIN(),
                          SYSDATETIMEOFFSET()
                   FROM   inserted AS i;
                   RETURN;
               END
           IF EXISTS (SELECT 1
                      FROM   deleted AS d
                      WHERE  NOT EXISTS (SELECT 1
                                         FROM   inserted AS i
                                         WHERE  i.eim_codigo = d.eim_codigo))
               THROW 50011, N'Operación denegada: No se permite cambiar la clave de [sgspi].[escala_impacto]; desactive la fila y cree una nueva.', 1;
           INSERT INTO sgspi.aud_escala_impacto (
               eim_codigo,
               aem_nombre_impacto_negativo,
               aem_nombre_impacto_positivo,
               aem_descripcion_organizacional,
               aem_descripcion_operativa,
               aem_esta_activa,
               per_codigo,
               aem_operacion,
               aem_usuario_bd,
               aem_fecha_cambio
           )
           SELECT d.eim_codigo,
                  d.eim_nombre_impacto_negativo,
                  d.eim_nombre_impacto_positivo,
                  d.eim_descripcion_organizacional,
                  d.eim_descripcion_operativa,
                  d.eim_esta_activa,
                  @per_actor,
                  'U',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   deleted AS d
                  INNER JOIN
                  inserted AS i
                  ON i.eim_codigo = d.eim_codigo
           WHERE  EXISTS (SELECT i.eim_nombre_impacto_negativo,
                                 i.eim_nombre_impacto_positivo,
                                 i.eim_descripcion_organizacional,
                                 i.eim_descripcion_operativa,
                                 i.eim_esta_activa
                          EXCEPT
                          SELECT d.eim_nombre_impacto_negativo,
                                 d.eim_nombre_impacto_positivo,
                                 d.eim_descripcion_organizacional,
                                 d.eim_descripcion_operativa,
                                 d.eim_esta_activa);
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [azc] La auditoría no se edita ni se borra
CREATE OR ALTER TRIGGER sgspi.TR_azc_inmutabilidad
    ON sgspi.aud_zona_riesgo_catalogo
    INSTEAD OF UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           THROW 50016, N'Operación denegada: la tabla de auditoría [sgspi].[aud_zona_riesgo_catalogo] es inmutable y no admite modificaciones ni borrados.', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [zrc] Bloquea el borrado físico y archiva en [sgspi].[aud_zona_riesgo_catalogo] las altas ('I') y la versión anterior de cada fila modificada ('U')
CREATE OR ALTER TRIGGER sgspi.TR_zrc_auditoria
    ON sgspi.zona_riesgo_catalogo
    AFTER INSERT, UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           IF EXISTS (SELECT 1
                      FROM   deleted)
              AND NOT EXISTS (SELECT 1
                              FROM   inserted)
               THROW 50010, N'Operación denegada: No se permite eliminar físicamente registros de [sgspi].[zona_riesgo_catalogo].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona en [dbo].[usuario_general] para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_zona_riesgo_catalogo (
                       zrc_codigo,
                       azc_nombre_nivel,
                       azc_orden,
                       azc_esta_activa,
                       per_codigo,
                       azc_operacion,
                       azc_usuario_bd,
                       azc_fecha_cambio
                   )
                   SELECT i.zrc_codigo,
                          i.zrc_nombre_nivel,
                          i.zrc_orden,
                          i.zrc_esta_activa,
                          @per_actor,
                          'I',
                          ORIGINAL_LOGIN(),
                          SYSDATETIMEOFFSET()
                   FROM   inserted AS i;
                   RETURN;
               END
           IF EXISTS (SELECT 1
                      FROM   deleted AS d
                      WHERE  NOT EXISTS (SELECT 1
                                         FROM   inserted AS i
                                         WHERE  i.zrc_codigo = d.zrc_codigo))
               THROW 50011, N'Operación denegada: No se permite cambiar la clave de [sgspi].[zona_riesgo_catalogo]; desactive la fila y cree una nueva.', 1;
           INSERT INTO sgspi.aud_zona_riesgo_catalogo (
               zrc_codigo,
               azc_nombre_nivel,
               azc_orden,
               azc_esta_activa,
               per_codigo,
               azc_operacion,
               azc_usuario_bd,
               azc_fecha_cambio
           )
           SELECT d.zrc_codigo,
                  d.zrc_nombre_nivel,
                  d.zrc_orden,
                  d.zrc_esta_activa,
                  @per_actor,
                  'U',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   deleted AS d
                  INNER JOIN
                  inserted AS i
                  ON i.zrc_codigo = d.zrc_codigo
           WHERE  EXISTS (SELECT i.zrc_nombre_nivel,
                                 i.zrc_orden,
                                 i.zrc_esta_activa
                          EXCEPT
                          SELECT d.zrc_nombre_nivel,
                                 d.zrc_orden,
                                 d.zrc_esta_activa);
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [amr] La auditoría no se edita ni se borra
CREATE OR ALTER TRIGGER sgspi.TR_amr_inmutabilidad
    ON sgspi.aud_matriz_valoracion_riesgo
    INSTEAD OF UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           THROW 50016, N'Operación denegada: la tabla de auditoría [sgspi].[aud_matriz_valoracion_riesgo] es inmutable y no admite modificaciones ni borrados.', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [mvr] Bloquea el borrado físico y archiva en [sgspi].[aud_matriz_valoracion_riesgo] las altas ('I') y la versión anterior de cada fila modificada ('U')
CREATE OR ALTER TRIGGER sgspi.TR_mvr_auditoria
    ON sgspi.matriz_valoracion_riesgo
    AFTER INSERT, UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           IF EXISTS (SELECT 1
                      FROM   deleted)
              AND NOT EXISTS (SELECT 1
                              FROM   inserted)
               THROW 50010, N'Operación denegada: No se permite eliminar físicamente registros de [sgspi].[matriz_valoracion_riesgo].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona en [dbo].[usuario_general] para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_matriz_valoracion_riesgo (
                       epr_codigo,
                       eim_codigo,
                       zrc_codigo,
                       amr_directriz_tratamiento_riesgo,
                       amr_directriz_tratamiento_oportunidad,
                       amr_requiere_aprobacion_comite,
                       amr_esta_activa,
                       per_codigo,
                       amr_operacion,
                       amr_usuario_bd,
                       amr_fecha_cambio
                   )
                   SELECT i.epr_codigo,
                          i.eim_codigo,
                          i.zrc_codigo,
                          i.mvr_directriz_tratamiento_riesgo,
                          i.mvr_directriz_tratamiento_oportunidad,
                          i.mvr_requiere_aprobacion_comite,
                          i.mvr_esta_activa,
                          @per_actor,
                          'I',
                          ORIGINAL_LOGIN(),
                          SYSDATETIMEOFFSET()
                   FROM   inserted AS i;
                   RETURN;
               END
           IF EXISTS (SELECT 1
                      FROM   deleted AS d
                      WHERE  NOT EXISTS (SELECT 1
                                         FROM   inserted AS i
                                         WHERE  i.epr_codigo = d.epr_codigo
                                                AND i.eim_codigo = d.eim_codigo))
               THROW 50011, N'Operación denegada: No se permite cambiar la clave de [sgspi].[matriz_valoracion_riesgo]; desactive la fila y cree una nueva.', 1;
           INSERT INTO sgspi.aud_matriz_valoracion_riesgo (
               epr_codigo,
               eim_codigo,
               zrc_codigo,
               amr_directriz_tratamiento_riesgo,
               amr_directriz_tratamiento_oportunidad,
               amr_requiere_aprobacion_comite,
               amr_esta_activa,
               per_codigo,
               amr_operacion,
               amr_usuario_bd,
               amr_fecha_cambio
           )
           SELECT d.epr_codigo,
                  d.eim_codigo,
                  d.zrc_codigo,
                  d.mvr_directriz_tratamiento_riesgo,
                  d.mvr_directriz_tratamiento_oportunidad,
                  d.mvr_requiere_aprobacion_comite,
                  d.mvr_esta_activa,
                  @per_actor,
                  'U',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   deleted AS d
                  INNER JOIN
                  inserted AS i
                  ON i.epr_codigo = d.epr_codigo
                     AND i.eim_codigo = d.eim_codigo
           WHERE  EXISTS (SELECT i.zrc_codigo,
                                 i.mvr_directriz_tratamiento_riesgo,
                                 i.mvr_directriz_tratamiento_oportunidad,
                                 i.mvr_requiere_aprobacion_comite,
                                 i.mvr_esta_activa
                          EXCEPT
                          SELECT d.zrc_codigo,
                                 d.mvr_directriz_tratamiento_riesgo,
                                 d.mvr_directriz_tratamiento_oportunidad,
                                 d.mvr_requiere_aprobacion_comite,
                                 d.mvr_esta_activa);
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [aea] La auditoría no se edita ni se borra
CREATE OR ALTER TRIGGER sgspi.TR_aea_inmutabilidad
    ON sgspi.aud_evento_incertidumbre_activo
    INSTEAD OF UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           THROW 50016, N'Operación denegada: la tabla de auditoría [sgspi].[aud_evento_incertidumbre_activo] es inmutable y no admite modificaciones ni borrados.', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [aet] La auditoría no se edita ni se borra
CREATE OR ALTER TRIGGER sgspi.TR_aet_inmutabilidad
    ON sgspi.aud_estrategia_tratamiento_catalogo
    INSTEAD OF UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           THROW 50016, N'Operación denegada: la tabla de auditoría [sgspi].[aud_estrategia_tratamiento_catalogo] es inmutable y no admite modificaciones ni borrados.', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [etc] Bloquea el borrado físico y archiva en [sgspi].[aud_estrategia_tratamiento_catalogo] las altas ('I') y la versión anterior de cada fila modificada ('U')
CREATE OR ALTER TRIGGER sgspi.TR_etc_auditoria
    ON sgspi.estrategia_tratamiento_catalogo
    AFTER INSERT, UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           IF EXISTS (SELECT 1
                      FROM   deleted)
              AND NOT EXISTS (SELECT 1
                              FROM   inserted)
               THROW 50010, N'Operación denegada: No se permite eliminar físicamente registros de [sgspi].[estrategia_tratamiento_catalogo].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona en [dbo].[usuario_general] para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_estrategia_tratamiento_catalogo (
                       etc_codigo,
                       aet_nombre_estrategia,
                       aet_naturaleza_aplicable,
                       aet_descripcion,
                       aet_esta_activa,
                       per_codigo,
                       aet_operacion,
                       aet_usuario_bd,
                       aet_fecha_cambio
                   )
                   SELECT i.etc_codigo,
                          i.etc_nombre_estrategia,
                          i.etc_naturaleza_aplicable,
                          i.etc_descripcion,
                          i.etc_esta_activa,
                          @per_actor,
                          'I',
                          ORIGINAL_LOGIN(),
                          SYSDATETIMEOFFSET()
                   FROM   inserted AS i;
                   RETURN;
               END
           INSERT INTO sgspi.aud_estrategia_tratamiento_catalogo (
               etc_codigo,
               aet_nombre_estrategia,
               aet_naturaleza_aplicable,
               aet_descripcion,
               aet_esta_activa,
               per_codigo,
               aet_operacion,
               aet_usuario_bd,
               aet_fecha_cambio
           )
           SELECT d.etc_codigo,
                  d.etc_nombre_estrategia,
                  d.etc_naturaleza_aplicable,
                  d.etc_descripcion,
                  d.etc_esta_activa,
                  @per_actor,
                  'U',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   deleted AS d
                  INNER JOIN
                  inserted AS i
                  ON i.etc_codigo = d.etc_codigo
           WHERE  EXISTS (SELECT i.etc_nombre_estrategia,
                                 i.etc_naturaleza_aplicable,
                                 i.etc_descripcion,
                                 i.etc_esta_activa
                          EXCEPT
                          SELECT d.etc_nombre_estrategia,
                                 d.etc_naturaleza_aplicable,
                                 d.etc_descripcion,
                                 d.etc_esta_activa);
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [apt] La auditoría no se edita ni se borra
CREATE OR ALTER TRIGGER sgspi.TR_apt_inmutabilidad
    ON sgspi.aud_plan_tratamiento
    INSTEAD OF UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           THROW 50016, N'Operación denegada: la tabla de auditoría [sgspi].[aud_plan_tratamiento] es inmutable y no admite modificaciones ni borrados.', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [aat] La auditoría no se edita ni se borra
CREATE OR ALTER TRIGGER sgspi.TR_aat_inmutabilidad
    ON sgspi.aud_actividad_tratamiento
    INSTEAD OF UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           THROW 50016, N'Operación denegada: la tabla de auditoría [sgspi].[aud_actividad_tratamiento] es inmutable y no admite modificaciones ni borrados.', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [asa] La auditoría no se edita ni se borra
CREATE OR ALTER TRIGGER sgspi.TR_asa_inmutabilidad
    ON sgspi.aud_seguimiento_actividad
    INSTEAD OF UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           THROW 50016, N'Operación denegada: la tabla de auditoría [sgspi].[aud_seguimiento_actividad] es inmutable y no admite modificaciones ni borrados.', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [aen] La auditoría no se edita ni se borra
CREATE OR ALTER TRIGGER sgspi.TR_aen_inmutabilidad
    ON sgspi.aud_estandar_normativo_catalogo
    INSTEAD OF UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           THROW 50016, N'Operación denegada: la tabla de auditoría [sgspi].[aud_estandar_normativo_catalogo] es inmutable y no admite modificaciones ni borrados.', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [enc] Bloquea el borrado físico y archiva en [sgspi].[aud_estandar_normativo_catalogo] las altas ('I') y la versión anterior de cada fila modificada ('U')
CREATE OR ALTER TRIGGER sgspi.TR_enc_auditoria
    ON sgspi.estandar_normativo_catalogo
    AFTER INSERT, UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           IF EXISTS (SELECT 1
                      FROM   deleted)
              AND NOT EXISTS (SELECT 1
                              FROM   inserted)
               THROW 50010, N'Operación denegada: No se permite eliminar físicamente registros de [sgspi].[estandar_normativo_catalogo].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona en [dbo].[usuario_general] para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_estandar_normativo_catalogo (
                       enc_codigo,
                       aen_identificador,
                       aen_familia_norma,
                       aen_nombre,
                       aen_organismo,
                       aen_anio_edicion,
                       aen_esta_activo,
                       per_codigo,
                       aen_operacion,
                       aen_usuario_bd,
                       aen_fecha_cambio
                   )
                   SELECT i.enc_codigo,
                          i.enc_identificador,
                          i.enc_familia_norma,
                          i.enc_nombre,
                          i.enc_organismo,
                          i.enc_anio_edicion,
                          i.enc_esta_activo,
                          @per_actor,
                          'I',
                          ORIGINAL_LOGIN(),
                          SYSDATETIMEOFFSET()
                   FROM   inserted AS i;
                   RETURN;
               END
           INSERT INTO sgspi.aud_estandar_normativo_catalogo (
               enc_codigo,
               aen_identificador,
               aen_familia_norma,
               aen_nombre,
               aen_organismo,
               aen_anio_edicion,
               aen_esta_activo,
               per_codigo,
               aen_operacion,
               aen_usuario_bd,
               aen_fecha_cambio
           )
           SELECT d.enc_codigo,
                  d.enc_identificador,
                  d.enc_familia_norma,
                  d.enc_nombre,
                  d.enc_organismo,
                  d.enc_anio_edicion,
                  d.enc_esta_activo,
                  @per_actor,
                  'U',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   deleted AS d
                  INNER JOIN
                  inserted AS i
                  ON i.enc_codigo = d.enc_codigo
           WHERE  EXISTS (SELECT i.enc_identificador,
                                 i.enc_familia_norma,
                                 i.enc_nombre,
                                 i.enc_organismo,
                                 i.enc_anio_edicion,
                                 i.enc_esta_activo
                          EXCEPT
                          SELECT d.enc_identificador,
                                 d.enc_familia_norma,
                                 d.enc_nombre,
                                 d.enc_organismo,
                                 d.enc_anio_edicion,
                                 d.enc_esta_activo);
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [acn] La auditoría no se edita ni se borra
CREATE OR ALTER TRIGGER sgspi.TR_acn_inmutabilidad
    ON sgspi.aud_control_referencia_normativa
    INSTEAD OF UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           THROW 50016, N'Operación denegada: la tabla de auditoría [sgspi].[aud_control_referencia_normativa] es inmutable y no admite modificaciones ni borrados.', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [crn] Bloquea el borrado físico y archiva en [sgspi].[aud_control_referencia_normativa] las altas ('I') y la versión anterior de cada fila modificada ('U')
CREATE OR ALTER TRIGGER sgspi.TR_crn_auditoria
    ON sgspi.control_referencia_normativa
    AFTER INSERT, UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           IF EXISTS (SELECT 1
                      FROM   deleted)
              AND NOT EXISTS (SELECT 1
                              FROM   inserted)
               THROW 50010, N'Operación denegada: No se permite eliminar físicamente registros de [sgspi].[control_referencia_normativa].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona en [dbo].[usuario_general] para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_control_referencia_normativa (
                       crn_codigo,
                       enc_codigo,
                       acn_rol_privacidad_pii,
                       acn_identificador_control,
                       acn_nombre_control,
                       acn_objetivo_requisito,
                       acn_esta_activo,
                       per_codigo,
                       acn_operacion,
                       acn_usuario_bd,
                       acn_fecha_cambio
                   )
                   SELECT i.crn_codigo,
                          i.enc_codigo,
                          i.crn_rol_privacidad_pii,
                          i.crn_identificador_control,
                          i.crn_nombre_control,
                          i.crn_objetivo_requisito,
                          i.crn_esta_activo,
                          @per_actor,
                          'I',
                          ORIGINAL_LOGIN(),
                          SYSDATETIMEOFFSET()
                   FROM   inserted AS i;
                   RETURN;
               END
           INSERT INTO sgspi.aud_control_referencia_normativa (
               crn_codigo,
               enc_codigo,
               acn_rol_privacidad_pii,
               acn_identificador_control,
               acn_nombre_control,
               acn_objetivo_requisito,
               acn_esta_activo,
               per_codigo,
               acn_operacion,
               acn_usuario_bd,
               acn_fecha_cambio
           )
           SELECT d.crn_codigo,
                  d.enc_codigo,
                  d.crn_rol_privacidad_pii,
                  d.crn_identificador_control,
                  d.crn_nombre_control,
                  d.crn_objetivo_requisito,
                  d.crn_esta_activo,
                  @per_actor,
                  'U',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   deleted AS d
                  INNER JOIN
                  inserted AS i
                  ON i.crn_codigo = d.crn_codigo
           WHERE  EXISTS (SELECT i.enc_codigo,
                                 i.crn_rol_privacidad_pii,
                                 i.crn_identificador_control,
                                 i.crn_nombre_control,
                                 i.crn_objetivo_requisito,
                                 i.crn_esta_activo
                          EXCEPT
                          SELECT d.enc_codigo,
                                 d.crn_rol_privacidad_pii,
                                 d.crn_identificador_control,
                                 d.crn_nombre_control,
                                 d.crn_objetivo_requisito,
                                 d.crn_esta_activo);
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [acc] La auditoría no se edita ni se borra
CREATE OR ALTER TRIGGER sgspi.TR_acc_inmutabilidad
    ON sgspi.aud_atributo_control_catalogo
    INSTEAD OF UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           THROW 50016, N'Operación denegada: la tabla de auditoría [sgspi].[aud_atributo_control_catalogo] es inmutable y no admite modificaciones ni borrados.', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [aac] Bloquea el borrado físico y archiva en [sgspi].[aud_atributo_control_catalogo] las altas ('I') y la versión anterior de cada fila modificada ('U')
CREATE OR ALTER TRIGGER sgspi.TR_aac_auditoria
    ON sgspi.atributo_control_catalogo
    AFTER INSERT, UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           IF EXISTS (SELECT 1
                      FROM   deleted)
              AND NOT EXISTS (SELECT 1
                              FROM   inserted)
               THROW 50010, N'Operación denegada: No se permite eliminar físicamente registros de [sgspi].[atributo_control_catalogo].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona en [dbo].[usuario_general] para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_atributo_control_catalogo (
                       aac_codigo,
                       acc_tipo_atributo,
                       acc_valor,
                       acc_esta_activo,
                       per_codigo,
                       acc_operacion,
                       acc_usuario_bd,
                       acc_fecha_cambio
                   )
                   SELECT i.aac_codigo,
                          i.aac_tipo_atributo,
                          i.aac_valor,
                          i.aac_esta_activo,
                          @per_actor,
                          'I',
                          ORIGINAL_LOGIN(),
                          SYSDATETIMEOFFSET()
                   FROM   inserted AS i;
                   RETURN;
               END
           INSERT INTO sgspi.aud_atributo_control_catalogo (
               aac_codigo,
               acc_tipo_atributo,
               acc_valor,
               acc_esta_activo,
               per_codigo,
               acc_operacion,
               acc_usuario_bd,
               acc_fecha_cambio
           )
           SELECT d.aac_codigo,
                  d.aac_tipo_atributo,
                  d.aac_valor,
                  d.aac_esta_activo,
                  @per_actor,
                  'U',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   deleted AS d
                  INNER JOIN
                  inserted AS i
                  ON i.aac_codigo = d.aac_codigo
           WHERE  EXISTS (SELECT i.aac_tipo_atributo,
                                 i.aac_valor,
                                 i.aac_esta_activo
                          EXCEPT
                          SELECT d.aac_tipo_atributo,
                                 d.aac_valor,
                                 d.aac_esta_activo);
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [aca] La auditoría no se edita ni se borra
CREATE OR ALTER TRIGGER sgspi.TR_aca_inmutabilidad
    ON sgspi.aud_control_referencia_normativa_atributo
    INSTEAD OF UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           THROW 50016, N'Operación denegada: la tabla de auditoría [sgspi].[aud_control_referencia_normativa_atributo] es inmutable y no admite modificaciones ni borrados.', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [cra] Bloquea el borrado físico y archiva en [sgspi].[aud_control_referencia_normativa_atributo] las altas ('I') y la versión anterior de cada fila modificada ('U')
CREATE OR ALTER TRIGGER sgspi.TR_cra_auditoria
    ON sgspi.control_referencia_normativa_atributo
    AFTER INSERT, UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           IF EXISTS (SELECT 1
                      FROM   deleted)
              AND NOT EXISTS (SELECT 1
                              FROM   inserted)
               THROW 50010, N'Operación denegada: No se permite eliminar físicamente registros de [sgspi].[control_referencia_normativa_atributo].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona en [dbo].[usuario_general] para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_control_referencia_normativa_atributo (
                       crn_codigo,
                       aac_codigo,
                       aca_esta_activo,
                       per_codigo,
                       aca_operacion,
                       aca_usuario_bd,
                       aca_fecha_cambio
                   )
                   SELECT i.crn_codigo,
                          i.aac_codigo,
                          i.cra_esta_activo,
                          @per_actor,
                          'I',
                          ORIGINAL_LOGIN(),
                          SYSDATETIMEOFFSET()
                   FROM   inserted AS i;
                   RETURN;
               END
           IF EXISTS (SELECT 1
                      FROM   deleted AS d
                      WHERE  NOT EXISTS (SELECT 1
                                         FROM   inserted AS i
                                         WHERE  i.crn_codigo = d.crn_codigo
                                                AND i.aac_codigo = d.aac_codigo))
               THROW 50011, N'Operación denegada: No se permite cambiar la clave de [sgspi].[control_referencia_normativa_atributo]; desactive la fila y cree una nueva.', 1;
           INSERT INTO sgspi.aud_control_referencia_normativa_atributo (
               crn_codigo,
               aac_codigo,
               aca_esta_activo,
               per_codigo,
               aca_operacion,
               aca_usuario_bd,
               aca_fecha_cambio
           )
           SELECT d.crn_codigo,
                  d.aac_codigo,
                  d.cra_esta_activo,
                  @per_actor,
                  'U',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   deleted AS d
                  INNER JOIN
                  inserted AS i
                  ON i.crn_codigo = d.crn_codigo
                     AND i.aac_codigo = d.aac_codigo
           WHERE  EXISTS (SELECT i.cra_esta_activo
                          EXCEPT
                          SELECT d.cra_esta_activo);
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [acp] La auditoría no se edita ni se borra
CREATE OR ALTER TRIGGER sgspi.TR_acp_inmutabilidad
    ON sgspi.aud_plan_tratamiento_control_referencia_normativa
    INSTEAD OF UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           THROW 50016, N'Operación denegada: la tabla de auditoría [sgspi].[aud_plan_tratamiento_control_referencia_normativa] es inmutable y no admite modificaciones ni borrados.', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [ptc] Bloquea el borrado físico y archiva en [sgspi].[aud_plan_tratamiento_control_referencia_normativa] las altas ('I') y la versión anterior de cada fila modificada ('U')
CREATE OR ALTER TRIGGER sgspi.TR_ptc_auditoria
    ON sgspi.plan_tratamiento_control_referencia_normativa
    AFTER INSERT, UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           IF EXISTS (SELECT 1
                      FROM   deleted)
              AND NOT EXISTS (SELECT 1
                              FROM   inserted)
               THROW 50010, N'Operación denegada: No se permite eliminar físicamente registros de [sgspi].[plan_tratamiento_control_referencia_normativa].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona en [dbo].[usuario_general] para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_plan_tratamiento_control_referencia_normativa (
                       plt_codigo,
                       crn_codigo,
                       acp_esta_activo,
                       per_codigo,
                       acp_operacion,
                       acp_usuario_bd,
                       acp_fecha_cambio
                   )
                   SELECT i.plt_codigo,
                          i.crn_codigo,
                          i.ptc_esta_activo,
                          @per_actor,
                          'I',
                          ORIGINAL_LOGIN(),
                          SYSDATETIMEOFFSET()
                   FROM   inserted AS i;
                   RETURN;
               END
           IF EXISTS (SELECT 1
                      FROM   deleted AS d
                      WHERE  NOT EXISTS (SELECT 1
                                         FROM   inserted AS i
                                         WHERE  i.plt_codigo = d.plt_codigo
                                                AND i.crn_codigo = d.crn_codigo))
               THROW 50011, N'Operación denegada: No se permite cambiar la clave de [sgspi].[plan_tratamiento_control_referencia_normativa]; desactive la fila y cree una nueva.', 1;
           INSERT INTO sgspi.aud_plan_tratamiento_control_referencia_normativa (
               plt_codigo,
               crn_codigo,
               acp_esta_activo,
               per_codigo,
               acp_operacion,
               acp_usuario_bd,
               acp_fecha_cambio
           )
           SELECT d.plt_codigo,
                  d.crn_codigo,
                  d.ptc_esta_activo,
                  @per_actor,
                  'U',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   deleted AS d
                  INNER JOIN
                  inserted AS i
                  ON i.plt_codigo = d.plt_codigo
                     AND i.crn_codigo = d.crn_codigo
           WHERE  EXISTS (SELECT i.ptc_esta_activo
                          EXCEPT
                          SELECT d.ptc_esta_activo);
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [aae] La auditoría no se edita ni se borra
CREATE OR ALTER TRIGGER sgspi.TR_aae_inmutabilidad
    ON sgspi.aud_evaluacion_aplicabilidad_control
    INSTEAD OF UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           THROW 50016, N'Operación denegada: la tabla de auditoría [sgspi].[aud_evaluacion_aplicabilidad_control] es inmutable y no admite modificaciones ni borrados.', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- 5.10.10 Roles y permisos [AP-02]: privilegios mínimos por actor.
-- Cada persona escribe con su login SQL real, miembro de UN rol de actor (uno por grupo SGSPI_* de [dbo].[grupo]);
-- la cuenta compartida de consulta es miembro solo de sgspi_rol_consulta (fuera de sgspi_rol_base: solo lee por
-- lista blanca los catálogos y las cinco vistas de D8, sin acceso a eia, plt, act, sga ni aud_*). Los seis roles
-- de actor son miembros de sgspi_rol_base y heredan su SELECT y sus DENY. Este script NO asigna personas a roles (lo hace el DBA).
-- Los triggers no se ven afectados por los DENY: [sgspi] es de dbo y el encadenamiento de propiedad omite la verificación.
-- dbo / db_owner / sysadmin NO se pueden restringir con DENY; un login en db_datawriter anula estos GRANT.
IF DATABASE_PRINCIPAL_ID(N'sgspi_rol_base') IS NULL
    CREATE ROLE sgspi_rol_base;

IF DATABASE_PRINCIPAL_ID(N'sgspi_rol_custodio_operador') IS NULL
    CREATE ROLE sgspi_rol_custodio_operador; -- SGSPI_CUSTODIO_OPERADOR

IF DATABASE_PRINCIPAL_ID(N'sgspi_rol_lider_propietario') IS NULL
    CREATE ROLE sgspi_rol_lider_propietario; -- SGSPI_LIDER_PROPIETARIO

IF DATABASE_PRINCIPAL_ID(N'sgspi_rol_gestor_documental') IS NULL
    CREATE ROLE sgspi_rol_gestor_documental; -- SGSPI_GESTOR_DOCUMENTAL

IF DATABASE_PRINCIPAL_ID(N'sgspi_rol_oficial_seguridad_privacidad') IS NULL
    CREATE ROLE sgspi_rol_oficial_seguridad_privacidad; -- SGSPI_ADMIN_OPDP

IF DATABASE_PRINCIPAL_ID(N'sgspi_rol_comite_direccion') IS NULL
    CREATE ROLE sgspi_rol_comite_direccion; -- SGSPI_COMITE_DIRECCION

IF DATABASE_PRINCIPAL_ID(N'sgspi_rol_auditor_control') IS NULL
    CREATE ROLE sgspi_rol_auditor_control; -- SGSPI_AUDITOR_CONTROL

IF DATABASE_PRINCIPAL_ID(N'sgspi_rol_consulta') IS NULL
    CREATE ROLE sgspi_rol_consulta; -- Cuenta compartida de consulta de la aplicación (D5/D8)

ALTER ROLE sgspi_rol_base ADD MEMBER sgspi_rol_custodio_operador;

ALTER ROLE sgspi_rol_base ADD MEMBER sgspi_rol_lider_propietario;

ALTER ROLE sgspi_rol_base ADD MEMBER sgspi_rol_gestor_documental;

ALTER ROLE sgspi_rol_base ADD MEMBER sgspi_rol_oficial_seguridad_privacidad;

ALTER ROLE sgspi_rol_base ADD MEMBER sgspi_rol_comite_direccion;

ALTER ROLE sgspi_rol_base ADD MEMBER sgspi_rol_auditor_control;

-- Base: lectura de todo el esquema. ALTER es lo que habilita TRUNCATE y DISABLE TRIGGER.
GRANT SELECT
    ON SCHEMA::sgspi TO sgspi_rol_base;

DENY ALTER
    ON SCHEMA::sgspi TO sgspi_rol_base;

-- [AP-22] Ningún registro se elimina: la baja es lógica (<acr>_esta_activo = 0). El DENY también anula db_datawriter.
DENY DELETE
    ON SCHEMA::sgspi TO sgspi_rol_base;

-- D8: la cuenta compartida queda fuera de sgspi_rol_base y solo lee por lista blanca los catálogos (aquí)
-- y las cinco vistas de inventario, DOFA y controles (al final de la sección 6, tras crearlas).
GRANT SELECT
    ON sgspi.periodo_vigencia TO sgspi_rol_consulta;

GRANT SELECT
    ON sgspi.estado_flujo_catalogo TO sgspi_rol_consulta;

GRANT SELECT
    ON sgspi.transicion_estado_flujo TO sgspi_rol_consulta;

GRANT SELECT
    ON sgspi.tipo_proceso_catalogo TO sgspi_rol_consulta;

GRANT SELECT
    ON sgspi.proceso_institucional TO sgspi_rol_consulta;

GRANT SELECT
    ON sgspi.proceso_institucional_uaa TO sgspi_rol_consulta;

GRANT SELECT
    ON sgspi.factor_entorno_catalogo TO sgspi_rol_consulta;

GRANT SELECT
    ON sgspi.parte_interesada TO sgspi_rol_consulta;

GRANT SELECT
    ON sgspi.tipo_activo_catalogo TO sgspi_rol_consulta;

GRANT SELECT
    ON sgspi.causal_excepcion_transparencia TO sgspi_rol_consulta;

GRANT SELECT
    ON sgspi.serie_documental_catalogo TO sgspi_rol_consulta;

GRANT SELECT
    ON sgspi.subserie_documental_catalogo TO sgspi_rol_consulta;

GRANT SELECT
    ON sgspi.unidad_productora_cuadro_clasificacion_documental TO sgspi_rol_consulta;

GRANT SELECT
    ON sgspi.periodicidad_catalogo TO sgspi_rol_consulta;

GRANT SELECT
    ON sgspi.estado_publicacion_catalogo TO sgspi_rol_consulta;

GRANT SELECT
    ON sgspi.soporte_registro_catalogo TO sgspi_rol_consulta;

GRANT SELECT
    ON sgspi.medio_conservacion_catalogo TO sgspi_rol_consulta;

GRANT SELECT
    ON sgspi.idioma_catalogo TO sgspi_rol_consulta;

GRANT SELECT
    ON sgspi.formato_archivo_catalogo TO sgspi_rol_consulta;

GRANT SELECT
    ON sgspi.escala_probabilidad TO sgspi_rol_consulta;

GRANT SELECT
    ON sgspi.escala_impacto TO sgspi_rol_consulta;

GRANT SELECT
    ON sgspi.zona_riesgo_catalogo TO sgspi_rol_consulta;

GRANT SELECT
    ON sgspi.matriz_valoracion_riesgo TO sgspi_rol_consulta;

GRANT SELECT
    ON sgspi.estrategia_tratamiento_catalogo TO sgspi_rol_consulta;

GRANT SELECT
    ON sgspi.estandar_normativo_catalogo TO sgspi_rol_consulta;

GRANT SELECT
    ON sgspi.control_referencia_normativa TO sgspi_rol_consulta;

GRANT SELECT
    ON sgspi.atributo_control_catalogo TO sgspi_rol_consulta;

GRANT SELECT
    ON sgspi.control_referencia_normativa_atributo TO sgspi_rol_consulta;

-- La máquina de estados solo cambia por script de migración: quien la escribe se salta los triggers de flujo.
DENY INSERT, UPDATE, DELETE
    ON sgspi.estado_flujo_catalogo TO sgspi_rol_base;

DENY INSERT, UPDATE, DELETE
    ON sgspi.transicion_estado_flujo TO sgspi_rol_base;

-- Columnas inmutables para la aplicación: creador, fechas de control (las mantienen DEFAULT y triggers) y avance derivado de [sga].
DENY UPDATE
    ON sgspi.periodo_vigencia (pev_fecha_creacion) TO sgspi_rol_base;

DENY UPDATE
    ON sgspi.analisis_contexto_factor (per_codigo_creador, per_codigo_aprobador, acf_fecha_creacion, acf_fecha_actualizacion) TO sgspi_rol_base;

DENY UPDATE
    ON sgspi.requisito_parte_interesada (per_codigo_creador, per_codigo_aprobador, rpi_fecha_creacion, rpi_fecha_actualizacion) TO sgspi_rol_base;

DENY UPDATE
    ON sgspi.activo_informacion (per_codigo_creador, per_codigo_aprobador, aci_fecha_creacion, aci_fecha_actualizacion) TO sgspi_rol_base;

DENY UPDATE
    ON sgspi.activo_documental (per_codigo_revisor_archivo, ado_fecha_creacion, ado_fecha_actualizacion) TO sgspi_rol_base;

DENY UPDATE
    ON sgspi.evento_incertidumbre_activo (per_codigo_creador, per_codigo_validador_lider, per_codigo_revisor_sgspi, per_codigo_aprobador_comite, eia_fecha_creacion, eia_fecha_actualizacion) TO sgspi_rol_base;

DENY UPDATE
    ON sgspi.plan_tratamiento (plt_fecha_creacion, plt_fecha_actualizacion) TO sgspi_rol_base;

DENY UPDATE
    ON sgspi.actividad_tratamiento (act_porcentaje_avance, act_fecha_creacion, act_fecha_actualizacion) TO sgspi_rol_base;

DENY UPDATE
    ON sgspi.evaluacion_aplicabilidad_control (eac_fecha_creacion, eac_fecha_actualizacion) TO sgspi_rol_base;

-- Configuración y catálogos del SGSPI: solo el oficial de seguridad y privacidad.
GRANT INSERT, UPDATE
    ON sgspi.periodo_vigencia TO sgspi_rol_oficial_seguridad_privacidad;

GRANT INSERT, UPDATE
    ON sgspi.tipo_proceso_catalogo TO sgspi_rol_oficial_seguridad_privacidad;

GRANT INSERT, UPDATE
    ON sgspi.proceso_institucional TO sgspi_rol_oficial_seguridad_privacidad;

GRANT INSERT, UPDATE
    ON sgspi.factor_entorno_catalogo TO sgspi_rol_oficial_seguridad_privacidad;

GRANT INSERT, UPDATE
    ON sgspi.tipo_activo_catalogo TO sgspi_rol_oficial_seguridad_privacidad;

GRANT INSERT, UPDATE
    ON sgspi.causal_excepcion_transparencia TO sgspi_rol_oficial_seguridad_privacidad;

GRANT INSERT, UPDATE
    ON sgspi.parte_interesada TO sgspi_rol_oficial_seguridad_privacidad;

GRANT INSERT, UPDATE
    ON sgspi.escala_probabilidad TO sgspi_rol_oficial_seguridad_privacidad;

GRANT INSERT, UPDATE
    ON sgspi.escala_impacto TO sgspi_rol_oficial_seguridad_privacidad;

GRANT INSERT, UPDATE
    ON sgspi.zona_riesgo_catalogo TO sgspi_rol_oficial_seguridad_privacidad;

GRANT INSERT, UPDATE
    ON sgspi.matriz_valoracion_riesgo TO sgspi_rol_oficial_seguridad_privacidad;

GRANT INSERT, UPDATE
    ON sgspi.estrategia_tratamiento_catalogo TO sgspi_rol_oficial_seguridad_privacidad;

GRANT INSERT, UPDATE
    ON sgspi.estandar_normativo_catalogo TO sgspi_rol_oficial_seguridad_privacidad;

GRANT INSERT, UPDATE
    ON sgspi.control_referencia_normativa TO sgspi_rol_oficial_seguridad_privacidad;

GRANT INSERT, UPDATE
    ON sgspi.atributo_control_catalogo TO sgspi_rol_oficial_seguridad_privacidad;

-- Catálogos documentales (CCD/TRD): solo el gestor documental.
GRANT INSERT, UPDATE
    ON sgspi.serie_documental_catalogo TO sgspi_rol_gestor_documental;

GRANT INSERT, UPDATE
    ON sgspi.subserie_documental_catalogo TO sgspi_rol_gestor_documental;

GRANT INSERT, UPDATE
    ON sgspi.unidad_productora_cuadro_clasificacion_documental TO sgspi_rol_gestor_documental;

GRANT INSERT, UPDATE
    ON sgspi.periodicidad_catalogo TO sgspi_rol_gestor_documental;

GRANT INSERT, UPDATE
    ON sgspi.estado_publicacion_catalogo TO sgspi_rol_gestor_documental;

GRANT INSERT, UPDATE
    ON sgspi.soporte_registro_catalogo TO sgspi_rol_gestor_documental;

GRANT INSERT, UPDATE
    ON sgspi.medio_conservacion_catalogo TO sgspi_rol_gestor_documental;

GRANT INSERT, UPDATE
    ON sgspi.idioma_catalogo TO sgspi_rol_gestor_documental;

GRANT INSERT, UPDATE
    ON sgspi.formato_archivo_catalogo TO sgspi_rol_gestor_documental;

GRANT INSERT, UPDATE
    ON sgspi.activo_documental_unidad_productora TO sgspi_rol_gestor_documental;

-- Tablas con datos del negocio. El comité solo actualiza el estado en [eia] (su firma la escribe el trigger).
GRANT INSERT, UPDATE
    ON sgspi.analisis_contexto_factor TO sgspi_rol_custodio_operador, sgspi_rol_lider_propietario;

GRANT UPDATE
    ON sgspi.analisis_contexto_factor TO sgspi_rol_oficial_seguridad_privacidad;

GRANT INSERT, UPDATE
    ON sgspi.requisito_parte_interesada TO sgspi_rol_oficial_seguridad_privacidad;

GRANT UPDATE
    ON sgspi.requisito_parte_interesada TO sgspi_rol_lider_propietario;

GRANT INSERT, UPDATE
    ON sgspi.activo_informacion TO sgspi_rol_custodio_operador, sgspi_rol_lider_propietario, sgspi_rol_oficial_seguridad_privacidad;

-- El gestor documental solo cambia el estado de [aci] para su aval de Archivo (EN_REVISION_ARCHIVO -> EN_REVISION_SGSPI
-- u OBSERVADO, RN-DOC-06); sin este GRANT la transición que [tef] le asigna fallaba con 229.
GRANT UPDATE
    ON sgspi.activo_informacion (aci_estado_registro) TO sgspi_rol_gestor_documental;

GRANT INSERT, UPDATE
    ON sgspi.activo_informacion_responsable TO sgspi_rol_custodio_operador, sgspi_rol_lider_propietario, sgspi_rol_oficial_seguridad_privacidad;

GRANT INSERT, UPDATE
    ON sgspi.sistema_informacion_ficha TO sgspi_rol_custodio_operador, sgspi_rol_lider_propietario, sgspi_rol_oficial_seguridad_privacidad;

GRANT INSERT, UPDATE
    ON sgspi.modulo_sistema_informacion TO sgspi_rol_custodio_operador, sgspi_rol_lider_propietario, sgspi_rol_oficial_seguridad_privacidad;

GRANT INSERT, UPDATE
    ON sgspi.activo_documental TO sgspi_rol_custodio_operador, sgspi_rol_lider_propietario, sgspi_rol_gestor_documental;

GRANT UPDATE
    ON sgspi.activo_documental TO sgspi_rol_oficial_seguridad_privacidad;

GRANT INSERT
    ON sgspi.evento_incertidumbre_activo TO sgspi_rol_custodio_operador;

GRANT INSERT, UPDATE
    ON sgspi.evento_incertidumbre_activo TO sgspi_rol_lider_propietario, sgspi_rol_oficial_seguridad_privacidad;

GRANT UPDATE
    ON sgspi.evento_incertidumbre_activo (eia_estado_registro) TO sgspi_rol_comite_direccion;

GRANT INSERT, UPDATE
    ON sgspi.plan_tratamiento TO sgspi_rol_lider_propietario, sgspi_rol_oficial_seguridad_privacidad;

-- D2: el dictamen de eficacia es solo del auditor; el líder y el oficial no lo escriben ni lo borran (TR_plt solo revisa
-- dictámenes con evaluador). Va después del GRANT de tabla: el DENY de columna prevalece sobre él.
DENY UPDATE
    ON sgspi.plan_tratamiento (plt_es_tratamiento_eficaz, plt_dictamen_eficacia, per_codigo_evaluador, plt_fecha_evaluacion_eficacia) TO sgspi_rol_lider_propietario, sgspi_rol_oficial_seguridad_privacidad;

GRANT INSERT, UPDATE
    ON sgspi.actividad_tratamiento TO sgspi_rol_custodio_operador, sgspi_rol_lider_propietario, sgspi_rol_gestor_documental;

GRANT UPDATE
    ON sgspi.actividad_tratamiento TO sgspi_rol_oficial_seguridad_privacidad;

GRANT INSERT
    ON sgspi.seguimiento_actividad TO sgspi_rol_custodio_operador, sgspi_rol_lider_propietario, sgspi_rol_gestor_documental; -- append-only

GRANT UPDATE
    ON sgspi.seguimiento_actividad (sga_esta_activo) TO sgspi_rol_custodio_operador, sgspi_rol_lider_propietario, sgspi_rol_gestor_documental; -- [AP-22] solo borrado lógico

GRANT INSERT, UPDATE
    ON sgspi.evaluacion_aplicabilidad_control TO sgspi_rol_oficial_seguridad_privacidad;

-- Tablas puente: INSERT y UPDATE; una asociación errada se desactiva con <acr>_esta_activo = 0 (nunca DELETE) [AP-22].
GRANT INSERT, UPDATE
    ON sgspi.proceso_institucional_uaa TO sgspi_rol_oficial_seguridad_privacidad;

GRANT INSERT, UPDATE
    ON sgspi.control_referencia_normativa_atributo TO sgspi_rol_oficial_seguridad_privacidad;

GRANT INSERT, UPDATE
    ON sgspi.requisito_parte_interesada_proceso_institucional TO sgspi_rol_oficial_seguridad_privacidad;

GRANT INSERT, UPDATE
    ON sgspi.activo_informacion_proceso_institucional TO sgspi_rol_custodio_operador, sgspi_rol_lider_propietario, sgspi_rol_oficial_seguridad_privacidad;

GRANT INSERT, UPDATE
    ON sgspi.activo_informacion_sede TO sgspi_rol_custodio_operador, sgspi_rol_lider_propietario, sgspi_rol_oficial_seguridad_privacidad;

GRANT INSERT, UPDATE
    ON sgspi.activo_documental_soporte_registro TO sgspi_rol_custodio_operador, sgspi_rol_lider_propietario, sgspi_rol_gestor_documental;

GRANT INSERT, UPDATE
    ON sgspi.activo_documental_medio_conservacion TO sgspi_rol_custodio_operador, sgspi_rol_lider_propietario, sgspi_rol_gestor_documental;

GRANT INSERT, UPDATE
    ON sgspi.activo_documental_idioma TO sgspi_rol_custodio_operador, sgspi_rol_lider_propietario, sgspi_rol_gestor_documental;

GRANT INSERT, UPDATE
    ON sgspi.activo_documental_formato_archivo TO sgspi_rol_custodio_operador, sgspi_rol_lider_propietario, sgspi_rol_gestor_documental;

GRANT INSERT, UPDATE
    ON sgspi.plan_tratamiento_control_referencia_normativa TO sgspi_rol_lider_propietario, sgspi_rol_oficial_seguridad_privacidad;

-- Auditor: solo lectura, salvo el dictamen de eficacia del plan (solo él lo registra, TR_plt), el cierre o la reapertura
-- de esa evaluación en eia (D2) y sus observaciones en el SoA.
GRANT UPDATE
    ON sgspi.evento_incertidumbre_activo (eia_estado_registro) TO sgspi_rol_auditor_control;

GRANT UPDATE
    ON sgspi.plan_tratamiento (plt_es_tratamiento_eficaz, plt_dictamen_eficacia, per_codigo_evaluador, plt_fecha_evaluacion_eficacia) TO sgspi_rol_auditor_control;

GRANT UPDATE
    ON sgspi.evaluacion_aplicabilidad_control (eac_observaciones_auditoria) TO sgspi_rol_auditor_control;

-- [AP-01] Auditoría de solo lectura: las tablas aud_* solo las escriben los triggers (encadenamiento de propiedad)
DENY INSERT, UPDATE, DELETE, ALTER
    ON sgspi.aud_periodo_vigencia TO sgspi_rol_base;

DENY INSERT, UPDATE, DELETE, ALTER
    ON sgspi.aud_estado_flujo_catalogo TO sgspi_rol_base;

DENY INSERT, UPDATE, DELETE, ALTER
    ON sgspi.aud_transicion_estado_flujo TO sgspi_rol_base;

DENY INSERT, UPDATE, DELETE, ALTER
    ON sgspi.aud_tipo_proceso_catalogo TO sgspi_rol_base;

DENY INSERT, UPDATE, DELETE, ALTER
    ON sgspi.aud_proceso_institucional TO sgspi_rol_base;

DENY INSERT, UPDATE, DELETE, ALTER
    ON sgspi.aud_proceso_institucional_uaa TO sgspi_rol_base;

DENY INSERT, UPDATE, DELETE, ALTER
    ON sgspi.aud_factor_entorno_catalogo TO sgspi_rol_base;

DENY INSERT, UPDATE, DELETE, ALTER
    ON sgspi.aud_analisis_contexto_factor TO sgspi_rol_base;

DENY INSERT, UPDATE, DELETE, ALTER
    ON sgspi.aud_parte_interesada TO sgspi_rol_base;

DENY INSERT, UPDATE, DELETE, ALTER
    ON sgspi.aud_requisito_parte_interesada TO sgspi_rol_base;

DENY INSERT, UPDATE, DELETE, ALTER
    ON sgspi.aud_requisito_parte_interesada_proceso_institucional TO sgspi_rol_base;

DENY INSERT, UPDATE, DELETE, ALTER
    ON sgspi.aud_tipo_activo_catalogo TO sgspi_rol_base;

DENY INSERT, UPDATE, DELETE, ALTER
    ON sgspi.aud_causal_excepcion_transparencia TO sgspi_rol_base;

DENY INSERT, UPDATE, DELETE, ALTER
    ON sgspi.aud_activo_informacion TO sgspi_rol_base;

DENY INSERT, UPDATE, DELETE, ALTER
    ON sgspi.aud_activo_informacion_proceso_institucional TO sgspi_rol_base;

DENY INSERT, UPDATE, DELETE, ALTER
    ON sgspi.aud_activo_informacion_sede TO sgspi_rol_base;

DENY INSERT, UPDATE, DELETE, ALTER
    ON sgspi.aud_activo_informacion_responsable TO sgspi_rol_base;

DENY INSERT, UPDATE, DELETE, ALTER
    ON sgspi.aud_sistema_informacion_ficha TO sgspi_rol_base;

DENY INSERT, UPDATE, DELETE, ALTER
    ON sgspi.aud_modulo_sistema_informacion TO sgspi_rol_base;

DENY INSERT, UPDATE, DELETE, ALTER
    ON sgspi.aud_serie_documental_catalogo TO sgspi_rol_base;

DENY INSERT, UPDATE, DELETE, ALTER
    ON sgspi.aud_subserie_documental_catalogo TO sgspi_rol_base;

DENY INSERT, UPDATE, DELETE, ALTER
    ON sgspi.aud_unidad_productora_cuadro_clasificacion_documental TO sgspi_rol_base;

DENY INSERT, UPDATE, DELETE, ALTER
    ON sgspi.aud_periodicidad_catalogo TO sgspi_rol_base;

DENY INSERT, UPDATE, DELETE, ALTER
    ON sgspi.aud_estado_publicacion_catalogo TO sgspi_rol_base;

DENY INSERT, UPDATE, DELETE, ALTER
    ON sgspi.aud_soporte_registro_catalogo TO sgspi_rol_base;

DENY INSERT, UPDATE, DELETE, ALTER
    ON sgspi.aud_medio_conservacion_catalogo TO sgspi_rol_base;

DENY INSERT, UPDATE, DELETE, ALTER
    ON sgspi.aud_idioma_catalogo TO sgspi_rol_base;

DENY INSERT, UPDATE, DELETE, ALTER
    ON sgspi.aud_formato_archivo_catalogo TO sgspi_rol_base;

DENY INSERT, UPDATE, DELETE, ALTER
    ON sgspi.aud_activo_documental TO sgspi_rol_base;

DENY INSERT, UPDATE, DELETE, ALTER
    ON sgspi.aud_activo_documental_soporte_registro TO sgspi_rol_base;

DENY INSERT, UPDATE, DELETE, ALTER
    ON sgspi.aud_activo_documental_medio_conservacion TO sgspi_rol_base;

DENY INSERT, UPDATE, DELETE, ALTER
    ON sgspi.aud_activo_documental_idioma TO sgspi_rol_base;

DENY INSERT, UPDATE, DELETE, ALTER
    ON sgspi.aud_activo_documental_formato_archivo TO sgspi_rol_base;

DENY INSERT, UPDATE, DELETE, ALTER
    ON sgspi.aud_activo_documental_unidad_productora TO sgspi_rol_base;

DENY INSERT, UPDATE, DELETE, ALTER
    ON sgspi.aud_escala_probabilidad TO sgspi_rol_base;

DENY INSERT, UPDATE, DELETE, ALTER
    ON sgspi.aud_escala_impacto TO sgspi_rol_base;

DENY INSERT, UPDATE, DELETE, ALTER
    ON sgspi.aud_zona_riesgo_catalogo TO sgspi_rol_base;

DENY INSERT, UPDATE, DELETE, ALTER
    ON sgspi.aud_matriz_valoracion_riesgo TO sgspi_rol_base;

DENY INSERT, UPDATE, DELETE, ALTER
    ON sgspi.aud_evento_incertidumbre_activo TO sgspi_rol_base;

DENY INSERT, UPDATE, DELETE, ALTER
    ON sgspi.aud_estrategia_tratamiento_catalogo TO sgspi_rol_base;

DENY INSERT, UPDATE, DELETE, ALTER
    ON sgspi.aud_plan_tratamiento TO sgspi_rol_base;

DENY INSERT, UPDATE, DELETE, ALTER
    ON sgspi.aud_actividad_tratamiento TO sgspi_rol_base;

DENY INSERT, UPDATE, DELETE, ALTER
    ON sgspi.aud_seguimiento_actividad TO sgspi_rol_base;

DENY INSERT, UPDATE, DELETE, ALTER
    ON sgspi.aud_estandar_normativo_catalogo TO sgspi_rol_base;

DENY INSERT, UPDATE, DELETE, ALTER
    ON sgspi.aud_control_referencia_normativa TO sgspi_rol_base;

DENY INSERT, UPDATE, DELETE, ALTER
    ON sgspi.aud_atributo_control_catalogo TO sgspi_rol_base;

DENY INSERT, UPDATE, DELETE, ALTER
    ON sgspi.aud_control_referencia_normativa_atributo TO sgspi_rol_base;

DENY INSERT, UPDATE, DELETE, ALTER
    ON sgspi.aud_plan_tratamiento_control_referencia_normativa TO sgspi_rol_base;

DENY INSERT, UPDATE, DELETE, ALTER
    ON sgspi.aud_evaluacion_aplicabilidad_control TO sgspi_rol_base;


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
/*==================================================================================================
                                                                                                                                                                                                                                                                                                                        6. VISTAS DINÁMICAS PARA CAMPOS CALCULADOS E INTEGRACIÓN CON [dbo]
                                                                                                                                                                                                                                                                                                                        ==================================================================================================*/
-- 6.0 vw_usuario_rol_alcance_sgspi se crea en 5.9b: la usan las funciones de alcance de los triggers [AP-02] D5
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
       ON fec.fec_codigo = acf.fec_codigo
WHERE  acf.acf_esta_activo = 1; -- [AP-22]


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- 6.2 Vista Resumen de Activos por Categoría, Tipo y Criticidad (Reemplaza Tabla Dinámica de ES-GSPI-MR-05 sobre jerarquía normalizada [tac])
CREATE OR ALTER VIEW sgspi.vw_resumen_activos_criticidad
AS
WITH     cte_taxonomia_activo
AS       (SELECT ai.aci_codigo,
                 ai.aci_nivel_criticidad,
                 COALESCE (abu.tac_nombre, pad.tac_nombre, tac.tac_nombre) AS tac_categoria_iso27005,
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
          WHERE  ai.aci_estado_registro = N'VIGENTE'
                 AND ai.aci_esta_activo = 1) -- [AP-22]
SELECT   CASE WHEN GROUPING(t.tac_categoria_iso27005) = 1 THEN N'Total general' ELSE t.tac_categoria_iso27005 END AS tac_categoria_activo,
         -- [AP-20] GROUPING en vez de ISNULL
         CASE WHEN GROUPING(t.tac_tipo_activo) = 1 THEN N'Subtotal categoría' ELSE t.tac_tipo_activo END AS tac_tipo_activo,
         SUM(CASE WHEN t.aci_nivel_criticidad = N'ALTA' THEN 1 ELSE 0 END) AS aci_criticidad_alta,
         SUM(CASE WHEN t.aci_nivel_criticidad = N'MEDIA' THEN 1 ELSE 0 END) AS aci_criticidad_media,
         SUM(CASE WHEN t.aci_nivel_criticidad = N'BAJA' THEN 1 ELSE 0 END) AS aci_criticidad_baja,
         COUNT(t.aci_codigo) AS aci_total_general
FROM     cte_taxonomia_activo AS t
GROUP BY GROUPING SETS((t.tac_categoria_iso27005, t.tac_tipo_activo), (t.tac_categoria_iso27005), ());


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


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
                 AND ptc.ptc_esta_activo = 1 -- [AP-22]
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
                 AND ptc.ptc_esta_activo = 1 -- [AP-22]
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
       CONCAT(CONVERT (NVARCHAR (10), pt.plt_fecha_inicio, 103), N' – ', CONVERT (NVARCHAR (10), pt.plt_fecha_fin, 103)) AS plt_cronograma,
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
       ON c27701.plt_codigo = pt.plt_codigo
WHERE  eia.eia_esta_activo = 1 -- [AP-22]
       AND pt.plt_esta_activo = 1;


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


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
        GROUP BY u.upc_codigo, u.upc_nodo_jerarquico, u.upc_nivel_jerarquico, u.upc_prefijo_archivistico, u.upc_nombre_unidad, raiz.upc_prefijo_archivistico, raiz.upc_nombre_unidad)
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
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


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
        WHERE    aip.aip_esta_activo = 1 -- [AP-22]
        GROUP BY aip.aci_codigo),
       cte_dependencias_doc
AS     (SELECT   x.aci_codigo,
                 STRING_AGG(CONVERT (NVARCHAR (200), x.uaa_nombre), N', ') WITHIN GROUP (ORDER BY x.uaa_nombre) AS ado_dependencias_oficinas
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
                 STRING_AGG(CONVERT (NVARCHAR (100), c.car_nombre), N', ') WITHIN GROUP (ORDER BY air.car_codigo, air.uaa_codigo) AS ado_propietarios_activo
        FROM     sgspi.activo_informacion_responsable AS air
                 INNER JOIN
                 dbo.cargo AS c
                 ON c.car_codigo = air.car_codigo
        WHERE    air.air_esta_activo = 1
                 AND air.air_tipo_responsabilidad = N'PROPIETARIO'
        GROUP BY air.aci_codigo),
       cte_custodios_doc
AS     (SELECT   air.aci_codigo,
                 STRING_AGG(CONVERT (NVARCHAR (100), c.car_nombre), N', ') WITHIN GROUP (ORDER BY air.car_codigo, air.uaa_codigo) AS ado_custodios_activo
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
        WHERE    ads.ads_esta_activo = 1 -- [AP-22]
        GROUP BY ads.ado_codigo),
       cte_medios_doc
AS     (SELECT   adm.ado_codigo,
                 STRING_AGG(mcc.mcc_nombre, N'/') WITHIN GROUP (ORDER BY mcc.mcc_nombre DESC) AS ado_medio_conservacion
        FROM     sgspi.activo_documental_medio_conservacion AS adm
                 INNER JOIN
                 sgspi.medio_conservacion_catalogo AS mcc
                 ON mcc.mcc_codigo = adm.mcc_codigo
        WHERE    adm.adm_esta_activo = 1 -- [AP-22]
        GROUP BY adm.ado_codigo),
       cte_idiomas_doc
AS     (SELECT   adi.ado_codigo,
                 STRING_AGG(idi.idi_nombre, N'/') WITHIN GROUP (ORDER BY idi.idi_nombre) AS ado_idioma
        FROM     sgspi.activo_documental_idioma AS adi
                 INNER JOIN
                 sgspi.idioma_catalogo AS idi
                 ON idi.idi_codigo = adi.idi_codigo
        WHERE    adi.adi_esta_activo = 1 -- [AP-22]
        GROUP BY adi.ado_codigo),
-- [AP-08] El formato documental ahora es multivaluado normalizado ([adf] + [fac])
       cte_formatos_doc
AS     (SELECT   adf.ado_codigo,
                 STRING_AGG(fac.fac_nombre, N'/') WITHIN GROUP (ORDER BY fac.fac_nombre) AS ado_formato_documental
        FROM     sgspi.activo_documental_formato_archivo AS adf
                 INNER JOIN
                 sgspi.formato_archivo_catalogo AS fac
                 ON fac.fac_codigo = adf.fac_codigo
        WHERE    adf.adf_esta_activo = 1 -- [AP-22]
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
       tac.tac_nombre AS ado_tipo_activo_documental,
       -- [AP-08] derivado del tipo de activo del supertipo
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
       ON fdoc.ado_codigo = ado.ado_codigo
WHERE  ado.ado_esta_activo = 1 -- [AP-22]
       AND aci.aci_esta_activo = 1;


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


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
            AND cra.cra_esta_activo = 1 -- [AP-22]
         LEFT OUTER JOIN
         sgspi.atributo_control_catalogo AS aac
         ON aac.aac_codigo = cra.aac_codigo
GROUP BY crn.crn_codigo, enc.enc_identificador, crn.crn_identificador_control, crn.crn_nombre_control;


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- D8: la cuenta compartida solo lee las cinco vistas de inventario, DOFA y controles (encadenamiento de propiedad con dbo).
GRANT SELECT
    ON sgspi.vw_consolidado_dofa TO sgspi_rol_consulta;

GRANT SELECT
    ON sgspi.vw_resumen_activos_criticidad TO sgspi_rol_consulta;

GRANT SELECT
    ON sgspi.vw_desglose_ccd_trd_mr04 TO sgspi_rol_consulta;

GRANT SELECT
    ON sgspi.vw_inventario_activo_documental_mr04 TO sgspi_rol_consulta;

GRANT SELECT
    ON sgspi.vw_controles_atributos_iso27002 TO sgspi_rol_consulta;


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [AP-19] Un lote que no compila (error de nivel 15) no revierte la transacción: antes del COMMIT se exige el esquema completo.
DECLARE @fallos AS NVARCHAR (2000) = N'';

IF (SELECT COUNT(*)
    FROM   sys.tables
    WHERE  schema_id = SCHEMA_ID(N'sgspi')) <> 98
   OR (SELECT COUNT(*)
       FROM   sys.triggers AS tr
              INNER JOIN
              sys.tables AS t
              ON t.object_id = tr.parent_id
       WHERE  t.schema_id = SCHEMA_ID(N'sgspi')) <> 109
   OR (SELECT COUNT(*)
       FROM   sys.views
       WHERE  schema_id = SCHEMA_ID(N'sgspi')) <> 7
   OR (SELECT COUNT(*)
       FROM   sys.objects
       WHERE  schema_id = SCHEMA_ID(N'sgspi')
              AND type = N'IF') <> 3
    SET @fallos += N' Conteo de objetos incompleto (esperado: 98 tablas, 109 triggers, 7 vistas, 3 funciones).';

DECLARE @objetos_faltantes AS NVARCHAR (1000) = LEFT((SELECT STRING_AGG(CAST(v.nombre AS NVARCHAR (MAX)), N', ')
                                                      FROM   (VALUES (N'sgspi.estado_flujo_catalogo', N'U'),
                                                                     (N'sgspi.transicion_estado_flujo', N'U'),
                                                                     (N'sgspi.analisis_contexto_factor', N'U'),
                                                                     (N'sgspi.requisito_parte_interesada', N'U'),
                                                                     (N'sgspi.activo_informacion', N'U'),
                                                                     (N'sgspi.activo_documental', N'U'),
                                                                     (N'sgspi.evento_incertidumbre_activo', N'U'),
                                                                     (N'sgspi.plan_tratamiento', N'U'),
                                                                     (N'sgspi.actividad_tratamiento', N'U'),
                                                                     (N'sgspi.seguimiento_actividad', N'U'),
                                                                     (N'sgspi.evaluacion_aplicabilidad_control', N'U'),
                                                                     (N'sgspi.ufn_persona_sesion', N'IF'),
                                                                     (N'sgspi.ufn_proceso_en_alcance', N'IF'),
                                                                     (N'sgspi.ufn_activo_en_alcance', N'IF'),
                                                                     (N'sgspi.vw_usuario_rol_alcance_sgspi', N'V'),
                                                                     (N'sgspi.vw_consolidado_dofa', N'V'),
                                                                     (N'sgspi.vw_resumen_activos_criticidad', N'V'),
                                                                     (N'sgspi.vw_matriz_tratamiento_riesgos', N'V'),
                                                                     (N'sgspi.vw_desglose_ccd_trd_mr04', N'V'),
                                                                     (N'sgspi.vw_inventario_activo_documental_mr04', N'V'),
                                                                     (N'sgspi.vw_controles_atributos_iso27002', N'V'),
                                                                     (N'sgspi.TR_acf_integridad_y_actualizacion', N'TR'),
                                                                     (N'sgspi.TR_rpi_integridad_y_actualizacion', N'TR'),
                                                                     (N'sgspi.TR_aci_integridad_y_actualizacion', N'TR'),
                                                                     (N'sgspi.TR_ado_integridad_y_actualizacion', N'TR'),
                                                                     (N'sgspi.TR_eia_integridad_y_actualizacion', N'TR'),
                                                                     (N'sgspi.TR_plt_integridad_y_actualizacion', N'TR'),
                                                                     (N'sgspi.TR_act_integridad_y_actualizacion', N'TR'),
                                                                     (N'sgspi.TR_eac_integridad_y_actualizacion', N'TR'),
                                                                     (N'sgspi.TR_sga_inmutabilidad', N'TR'),
                                                                     (N'sgspi.TR_sga_sincronizar_avance', N'TR')) AS v(nombre, tipo)
                                                      WHERE  OBJECT_ID(v.nombre, v.tipo) IS NULL), 1000);

IF @objetos_faltantes IS NOT NULL
    SET @fallos += N' Faltan objetos clave: ' + @objetos_faltantes + N'.';

DECLARE @roles_faltantes AS NVARCHAR (500) = (SELECT STRING_AGG(v.rol, N', ')
                                              FROM   (VALUES (N'sgspi_rol_base'),
                                                             (N'sgspi_rol_custodio_operador'),
                                                             (N'sgspi_rol_lider_propietario'),
                                                             (N'sgspi_rol_gestor_documental'),
                                                             (N'sgspi_rol_oficial_seguridad_privacidad'),
                                                             (N'sgspi_rol_comite_direccion'),
                                                             (N'sgspi_rol_auditor_control'),
                                                             (N'sgspi_rol_consulta')) AS v(rol)
                                              WHERE  DATABASE_PRINCIPAL_ID(v.rol) IS NULL);

IF @roles_faltantes IS NOT NULL
    SET @fallos += N' Faltan roles: ' + @roles_faltantes + N'.';

DECLARE @aud_rotas AS NVARCHAR (1000) = LEFT((SELECT STRING_AGG(CAST(t.name AS NVARCHAR (MAX)), N', ')
                                              FROM   sys.tables AS t
                                              WHERE  t.schema_id = SCHEMA_ID(N'sgspi')
                                                     AND ((t.name LIKE N'aud[_]%'
                                                           AND NOT EXISTS (SELECT 1
                                                                           FROM   sys.triggers AS tr
                                                                           WHERE  tr.parent_id = t.object_id
                                                                                  AND tr.is_instead_of_trigger = 1))
                                                          OR (t.name NOT LIKE N'aud[_]%'
                                                              AND (OBJECT_ID(N'sgspi.aud_' + t.name, N'U') IS NULL
                                                                   OR NOT EXISTS (SELECT 1
                                                                                  FROM   sys.triggers AS tr
                                                                                         INNER JOIN
                                                                                         sys.sql_expression_dependencies AS d
                                                                                         ON d.referencing_id = tr.object_id
                                                                                  WHERE  tr.parent_id = t.object_id
                                                                                         AND d.referenced_id = OBJECT_ID(N'sgspi.aud_' + t.name)))))), 1000);

IF @aud_rotas IS NOT NULL
    SET @fallos += N' Tablas sin paridad de auditoría/trigger: ' + @aud_rotas + N'.';

IF LEN(@fallos) > 0
    BEGIN
        ROLLBACK TRANSACTION;
        RAISERROR (N'DESPLIEGUE SGSPI REVERTIDO SIN CAMBIOS:%s', 16, 1, @fallos);
        SET NOEXEC ON;
    END
ELSE
    BEGIN TRY
        EXECUTE sys.sp_refreshview N'sgspi.vw_usuario_rol_alcance_sgspi';
        EXECUTE sys.sp_refreshview N'sgspi.vw_consolidado_dofa';
        EXECUTE sys.sp_refreshview N'sgspi.vw_resumen_activos_criticidad';
        EXECUTE sys.sp_refreshview N'sgspi.vw_matriz_tratamiento_riesgos';
        EXECUTE sys.sp_refreshview N'sgspi.vw_desglose_ccd_trd_mr04';
        EXECUTE sys.sp_refreshview N'sgspi.vw_inventario_activo_documental_mr04';
        EXECUTE sys.sp_refreshview N'sgspi.vw_controles_atributos_iso27002';
    END TRY
    BEGIN CATCH
        DECLARE @err_vista AS NVARCHAR (1500) = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        RAISERROR (N'DESPLIEGUE SGSPI REVERTIDO SIN CAMBIOS: error al compilar vista (%s).', 16, 1, @err_vista);
        SET NOEXEC ON;
    END CATCH


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
COMMIT TRANSACTION; -- [AP-19]


GO
/*==================================================================================================
7. VERIFICACIÓN POSTERIOR AL DESPLIEGUE (SOLO LECTURA)
Lista desalineaciones entre [dbo].[usuario_grupo]/[dbo].[usuario_general] y los roles de BD del SGSPI. Compara el
login del usuario de BD (SUSER_SNAME de su sid), que es lo que los triggers buscan con ORIGINAL_LOGIN():
(a) miembros de grupos SGSPI_* sin usuario de BD o sin el rol equivalente; (b) usuarios de BD en un rol de actor cuyo
login no está en [dbo].[usuario_general].[us]; (c) usuarios de BD en más de un rol de actor; (d) usuarios de un rol de
actor que también son miembros directos de db_owner, db_datawriter, db_ddladmin o db_securityadmin, que anulan los
GRANT; (e) logins de un rol de actor con varias personas en [dbo].[usuario_general] (TOP (1) elegiría una de ellas);
(f) base sin TDE (sys.databases.is_encrypted = 0); (g) tablas de [dbo] sin índice en la columna de búsqueda del SGSPI
(dbo.usuario_general.us, dbo.usuario_grupo.usg_usuario).
==================================================================================================*/
WITH     cte_mapa_roles
AS       (SELECT v.gru_nombre,
                 v.rol_bd
          FROM   (VALUES (N'SGSPI_CUSTODIO_OPERADOR', N'sgspi_rol_custodio_operador'), (N'SGSPI_LIDER_PROPIETARIO', N'sgspi_rol_lider_propietario'), (N'SGSPI_GESTOR_DOCUMENTAL', N'sgspi_rol_gestor_documental'), (N'SGSPI_ADMIN_OPDP', N'sgspi_rol_oficial_seguridad_privacidad'), (N'SGSPI_COMITE_DIRECCION', N'sgspi_rol_comite_direccion'), (N'SGSPI_AUDITOR_CONTROL', N'sgspi_rol_auditor_control')) AS v(gru_nombre, rol_bd)),
         cte_membresia_bd
AS       (SELECT m.principal_id AS usuario_id,
                 m.name AS usuario_bd,
                 SUSER_SNAME(m.sid) AS login_bd,
                 r.name AS rol_bd
          FROM   sys.database_role_members AS rm
                 INNER JOIN
                 sys.database_principals AS r
                 ON r.principal_id = rm.role_principal_id
                 INNER JOIN
                 sys.database_principals AS m
                 ON m.principal_id = rm.member_principal_id
          WHERE  r.name IN (SELECT rol_bd
                            FROM   cte_mapa_roles))
SELECT   DISTINCT N'Grupo SGSPI_* sin usuario de BD o sin su rol equivalente' AS hallazgo,
                  u.us AS usuario,
                  g.gru_nombre AS detalle
FROM     dbo.usuario_grupo AS ug
         INNER JOIN
         dbo.grupo AS g
         ON g.gru_codigo = ug.usg_grupo
         INNER JOIN
         dbo.usuario_general AS u
         ON u.uid = ug.usg_usuario
         LEFT OUTER JOIN
         cte_mapa_roles AS mr
         ON mr.gru_nombre = g.gru_nombre
WHERE    ug.usg_estado = 1
         AND g.gru_estado = 1
         AND g.gru_nombre LIKE N'SGSPI[_]%'
         AND NOT EXISTS (SELECT 1
                         FROM   cte_membresia_bd AS mb
                         WHERE  mb.login_bd = u.us
                                AND mb.rol_bd = mr.rol_bd)
UNION ALL
SELECT   DISTINCT N'Usuario de BD en rol de actor cuyo login no está en dbo.usuario_general.us' AS hallazgo,
                  mb.usuario_bd AS usuario,
                  mb.rol_bd AS detalle
FROM     cte_membresia_bd AS mb
WHERE    NOT EXISTS (SELECT 1
                     FROM   dbo.usuario_general AS u
                     WHERE  u.us = mb.login_bd)
UNION ALL
SELECT   N'Usuario de BD en más de un rol de actor' AS hallazgo,
         mb.usuario_bd AS usuario,
         STRING_AGG(mb.rol_bd, N', ') WITHIN GROUP (ORDER BY mb.rol_bd) AS detalle
FROM     cte_membresia_bd AS mb
GROUP BY mb.usuario_bd
HAVING   COUNT(*) > 1
UNION ALL
SELECT   DISTINCT N'Usuario de rol de actor en un rol fijo que anula los GRANT' AS hallazgo,
                  mb.usuario_bd AS usuario,
                  f.name AS detalle
FROM     cte_membresia_bd AS mb
         INNER JOIN
         sys.database_role_members AS frm
         ON frm.member_principal_id = mb.usuario_id
         INNER JOIN
         sys.database_principals AS f
         ON f.principal_id = frm.role_principal_id
WHERE    f.name IN (N'db_owner', N'db_datawriter', N'db_ddladmin', N'db_securityadmin')
UNION ALL
SELECT   N'Login de rol de actor con varias personas en dbo.usuario_general' AS hallazgo,
         u.us AS usuario,
         STRING_AGG(CONVERT (NVARCHAR (20), u.up), N', ') WITHIN GROUP (ORDER BY u.up) AS detalle
FROM     dbo.usuario_general AS u
WHERE    u.us IN (SELECT mb.login_bd
                  FROM   cte_membresia_bd AS mb)
GROUP BY u.us
HAVING   COUNT(DISTINCT u.up) > 1
UNION ALL
SELECT   N'Base sin TDE' AS hallazgo,
         DB_NAME() AS usuario,
         N'sys.databases.is_encrypted = 0' AS detalle
FROM     sys.databases
WHERE    database_id = DB_ID()
         AND is_encrypted = 0
UNION ALL
SELECT   N'Tabla de [dbo] sin índice en la columna de búsqueda del SGSPI' AS hallazgo,
         v.tabla AS usuario,
         v.columna AS detalle
FROM     (VALUES (N'dbo.usuario_general', N'us'), (N'dbo.usuario_estudiantes', N'us'), (N'dbo.usuario_estudiantes_virtual', N'us'), (N'dbo.usuario_docentes', N'us'), (N'dbo.usuario_administrativos', N'us'), (N'dbo.usuario_graduados', N'us'), (N'dbo.usuario_estudiantes_intercambio', N'us'), (N'dbo.usuario_externos', N'us'), (N'dbo.usuario_grupo', N'usg_usuario')) AS v(tabla, columna)
WHERE    OBJECTPROPERTY(OBJECT_ID(v.tabla), N'IsUserTable') = 1 -- en producción usuario_general es una vista UNION: se revisan sus 7 tablas base
         AND NOT EXISTS (SELECT 1
                     FROM   sys.indexes AS ix
                            INNER JOIN
                            sys.index_columns AS ic
                            ON ic.object_id = ix.object_id
                               AND ic.index_id = ix.index_id
                            INNER JOIN
                            sys.columns AS c
                            ON c.object_id = ic.object_id
                               AND c.column_id = ic.column_id
                     WHERE  ix.object_id = OBJECT_ID(v.tabla)
                            AND ix.is_disabled = 0
                            AND ix.has_filter = 0
                            AND ic.key_ordinal = 1
                            AND c.name = v.columna);


GO
SET NOEXEC OFF;