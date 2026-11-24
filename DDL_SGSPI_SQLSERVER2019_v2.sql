/*==================================================================================================
PROYECTO:     Sistema de Gestión de Seguridad y Privacidad de la Información (SGSPI)
ENTIDAD:      Universidad Surcolombiana (USCO)
BASE DATOS:   Integrado con el esquema corporativo [dbo] de la USCO (academia3000)
MOTOR BD:     Microsoft SQL Server 2019 Standard/Enterprise (compatible con compatibility_level >= 100)
VERSIÓN:      2.3 — Remediación integral P0–P3 (seguridad, concurrencia, integridad, auditoría after-image, índices y despliegue seguro) + compatibilidad academia3000 nivel 100
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
y la versión resultante after-image de cada fila modificada (<aud>_operacion = 'U') [C2], quién ejecutó la operación (per_codigo de
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
ORIGINAL_LOGIN() -> [dbo].[usuario_administrativos]/[dbo].[usuario_docentes].[sys]; los triggers la exigen (error 50017 si falta), firman con ella las
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
AP-22  Borrado lógico: ningún registro se elimina. Toda tabla (salvo las aud_*, de solo inserción) tiene <acr>_estado BIT
(1 = activo, 0 = inactivo, DEFAULT 1); <acr>_estado = 0 significa registro anulado por error, mientras que
INACTIVO e HISTORICO son etapas del ciclo de vida. DENY DELETE sobre el esquema, sin ON DELETE CASCADE, tablas puente
con UPDATE en vez de DELETE y vistas de reporte que filtran <acr>_estado = 1 en la entidad principal y en las
asociaciones. En estados no editables (efc_permite_edicion = 0) desactivar exige primero una transición.
AP-23  Plazo legal de la reserva (Ley 1712 de 2014, art. 22): la información RESERVADA no puede tener reserva
indefinida ni de más de 15 años.
AP-24  Concurrencia: (a) control optimista con <acr>_version ROWVERSION NOT NULL en acf, rpi, aci, ado, eia, plt, act y
eac (la aplicación actualiza con WHERE <acr>_codigo = @id AND <acr>_version = @v y vuelve a leer tras guardar; NOTA [B5]:
el UPDATE del usuario más el UPDATE interno del trigger incrementan <acr>_version DOS veces, por lo que clientes/ORM
NUNCA deben leer OUTPUT inserted.<acr>_version sino recargar el registro tras COMMIT); (b) los triggers de las familias
[rpi], [aci] y [eia] serializan por raíz con sp_getapplock ('sgspi:rpi:<id>', 'sgspi:aci:<id>', 'sgspi:eia:<id>', orden
ascendente) sin escrituras cruzadas [B1] ni UPDLOCK previos al applock [B2][B3] (exige READ_COMMITTED_SNAPSHOT ON en
pre-vuelo [E2]); (c) consecutivos sin bloqueos de rango mediante sgspi.usp_siguiente_consecutivo [B5] dentro de la misma
transacción del INSERT (usa sp_getapplock por llave de secuencia, sin UPDLOCK/HOLDLOCK sobre la tabla).
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
VENTANA DE MANTENIMIENTO [E1][C1]: las 49 FKs de aud_* hacia dbo.persona fueron retiradas y las 25 FKs
operativas hacia [dbo] (13 a dbo.persona, 6 a dbo.uaa, 4 a dbo.cargo, 1 a dbo.espacio, 1 a dbo.sub_sede) se
agregan en un único lote final breve con SET LOCK_TIMEOUT 5000 inmediatamente antes del COMMIT (bloqueo Sch-M
de milisegundos en vez de toda la ejecución). Ejecutar siempre con "sqlcmd -I -b" para abortar limpiamente si
falla el pre-vuelo sin disparar errores de compilación por SET NOEXEC ON [E2].
Un error de sintaxis (nivel 15) no revierte la transacción, ni siquiera con XACT_ABORT: la guarda previa al COMMIT valida
conteos, objetos nominales clave, paridad aud_* y compilación de vistas (sp_refreshview); si algo falla, revierte todo
(DESPLIEGUE SGSPI REVERTIDO SIN CAMBIOS), con o sin "sqlcmd -b".
==================================================================================================*/
DECLARE @errores AS NVARCHAR (2000) = N'';

IF CONVERT (INT, SERVERPROPERTY('ProductMajorVersion')) < 15
    SET @errores += N' El motor debe ser SQL Server 2019 o superior (ProductMajorVersion >= 15).';

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
                           (N'dbo.uaa', N'uaa_estado'),
                           (N'dbo.cargo', N'car_codigo'),
                           (N'dbo.cargo', N'car_nombre'),
                           (N'dbo.persona', N'per_codigo'),
                           (N'dbo.persona', N'per_nombre'),
                           (N'dbo.persona', N'per_apellido'),
                           (N'dbo.persona', N'per_estado'),
                           (N'dbo.espacio', N'esp_codigo'),
                           (N'dbo.sub_sede', N'sus_codigo'),
                           (N'dbo.grupo', N'gru_codigo'),
                           (N'dbo.grupo', N'gru_nombre'),
                           (N'dbo.grupo', N'gru_id'),
                           (N'dbo.grupo', N'gru_estado'),
                           (N'dbo.usuario_grupo', N'usg_codigo'),
                           (N'dbo.usuario_grupo', N'usg_grupo'),
                           (N'dbo.usuario_grupo', N'usg_uaa'),
                           (N'dbo.usuario_grupo', N'usg_usuario'),
                           (N'dbo.usuario_grupo', N'usg_estado'),
                           (N'dbo.usuario_administrativos', N'uid'),
                           (N'dbo.usuario_administrativos', N'up'),
                           (N'dbo.usuario_administrativos', N'us'),
                           (N'dbo.usuario_administrativos', N'sys'),
                           (N'dbo.usuario_administrativos', N'uwd2'),
                           (N'dbo.usuario_administrativos', N'state'),
                           (N'dbo.usuario_docentes', N'uid'),
                           (N'dbo.usuario_docentes', N'up'),
                           (N'dbo.usuario_docentes', N'us'),
                           (N'dbo.usuario_docentes', N'sys'),
                           (N'dbo.usuario_docentes', N'uwd2'),
                           (N'dbo.usuario_docentes', N'state');

DECLARE @faltantes AS NVARCHAR (1000) = (SELECT STRING_AGG(CONCAT(tabla, N'.', columna), N', ')
                                         FROM   @dependencias
                                         WHERE  COL_LENGTH(tabla, columna) IS NULL);

IF @faltantes IS NOT NULL
    SET @errores += N' Faltan dependencias del esquema corporativo: ' + @faltantes + N'.';

DECLARE @sin_clave_fk AS NVARCHAR (1000) = (SELECT STRING_AGG(CONCAT(v.tabla, N'(', v.columna, N')'), N', ')
                                            FROM   (VALUES (N'dbo.uaa', N'uaa_codigo'), (N'dbo.cargo', N'car_codigo'), (N'dbo.persona', N'per_codigo'), (N'dbo.espacio', N'esp_codigo'), (N'dbo.sub_sede', N'sus_codigo')) AS v(tabla, columna)
                                            WHERE  COL_LENGTH(v.tabla, v.columna) IS NOT NULL
                                                   AND NOT EXISTS (SELECT   1
                                                                   FROM     sys.indexes AS ix
                                                                            INNER JOIN
                                                                            sys.index_columns AS ic
                                                                            ON ic.object_id = ix.object_id
                                                                               AND ic.index_id = ix.index_id
                                                                               AND ic.is_included_column = 0
                                                                            INNER JOIN
                                                                            sys.columns AS c
                                                                            ON c.object_id = ic.object_id
                                                                               AND c.column_id = ic.column_id
                                                                   WHERE    ix.object_id = OBJECT_ID(v.tabla)
                                                                            AND OBJECTPROPERTY(ix.object_id, N'IsUserTable') = 1
                                                                            AND ix.is_unique = 1
                                                                            AND ix.is_disabled = 0
                                                                            AND ix.has_filter = 0
                                                                            AND ix.is_hypothetical = 0
                                                                   GROUP BY ix.index_id
                                                                   HAVING   COUNT(*) = 1
                                                                            AND MAX(c.name) = v.columna));

IF @sin_clave_fk IS NOT NULL
    SET @errores += N' Tablas de [dbo] sin PK/UQ activa para FK: ' + @sin_clave_fk + N'.';

-- [E2] Valida tipo de dato exacto INT (system_type_id = 56) en las 5 PKs referenciadas en [dbo]
DECLARE @tipo_fk_invalido AS NVARCHAR (1000) = (SELECT STRING_AGG(CONCAT(v.tabla, N'.', v.columna, N' (', TYPE_NAME(c.system_type_id), N')'), N', ')
                                                FROM   (VALUES (N'dbo.uaa', N'uaa_codigo'), (N'dbo.cargo', N'car_codigo'), (N'dbo.persona', N'per_codigo'), (N'dbo.espacio', N'esp_codigo'), (N'dbo.sub_sede', N'sus_codigo')) AS v(tabla, columna)
                                                       INNER JOIN
                                                       sys.columns AS c
                                                       ON c.object_id = OBJECT_ID(v.tabla)
                                                          AND c.name = v.columna
                                                WHERE  c.system_type_id <> 56); -- 56 = INT

IF @tipo_fk_invalido IS NOT NULL
    SET @errores += N' Columnas FK de [dbo] no son de tipo INT: ' + @tipo_fk_invalido + N'.';

-- [E2] Valida tipo de cadena (VARCHAR/NVARCHAR) en [sys] de usuario_administrativos y usuario_docentes
DECLARE @tipo_sys_invalido AS NVARCHAR (500) = (SELECT STRING_AGG(CONCAT(v.tabla, N'.sys (', TYPE_NAME(c.system_type_id), N')'), N', ')
                                                FROM   (VALUES (N'dbo.usuario_administrativos'), (N'dbo.usuario_docentes')) AS v(tabla)
                                                       INNER JOIN
                                                       sys.columns AS c
                                                       ON c.object_id = OBJECT_ID(v.tabla)
                                                          AND c.name = N'sys'
                                                WHERE  c.system_type_id NOT IN (167, 231)); -- VARCHAR / NVARCHAR

IF @tipo_sys_invalido IS NOT NULL
    SET @errores += N' Columna [sys] de tipo incompatible (se requiere VARCHAR/NVARCHAR): ' + @tipo_sys_invalido + N'.';

-- [E2] Exige READ_COMMITTED_SNAPSHOT ON (prerequisito de concurrencia sin deadlocks [AP-24])
IF EXISTS (SELECT 1
           FROM   sys.databases
           WHERE  database_id = DB_ID()
                  AND is_read_committed_snapshot_on <> 1)
    SET @errores += N' READ_COMMITTED_SNAPSHOT está desactivado (ejecutar ALTER DATABASE ... SET READ_COMMITTED_SNAPSHOT ON antes de desplegar).';

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
    EXECUTE sys.sp_updateextendedproperty N'sgspi_version', N'2.3', N'SCHEMA', N'sgspi';
ELSE
    EXECUTE sys.sp_addextendedproperty N'sgspi_version', N'2.3', N'SCHEMA', N'sgspi';


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
    pev_fase_vigencia   NVARCHAR (20)      CONSTRAINT DF_pev_fase_vigencia DEFAULT N'ABIERTA' NOT NULL, -- [AP-17] DEFAULT con nombre
    pev_fecha_creacion  DATETIMEOFFSET (0) CONSTRAINT DF_pev_fecha_creacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17] Zona horaria explícita
    pev_estado          BIT                CONSTRAINT DF_pev_estado DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
    CONSTRAINT PK_pev_periodo_vigencia PRIMARY KEY CLUSTERED (pev_codigo),
    CONSTRAINT CK_pev_anio CHECK (pev_anio BETWEEN 2000 AND 2100),
    CONSTRAINT CK_pev_fase_vigencia CHECK (pev_fase_vigencia IN (N'EN_CONFIGURACION', N'ABIERTA', N'CERRADA', N'HISTORICA')),
    CONSTRAINT CK_pev_fechas CHECK (pev_fecha_cierre IS NULL
                                    OR pev_fecha_cierre >= pev_fecha_apertura)
);

CREATE UNIQUE NONCLUSTERED INDEX UX_pev_anio
    ON sgspi.periodo_vigencia(pev_anio) WHERE pev_estado = 1; -- [AP-22]

-- 1.1b [efc] y [tef] Máquina de Estados Dirigida por Datos (Estados y Transiciones Válidas por Dominio de Flujo)
-- [AP-05] Reemplaza los CHECK de lista de estados y las transiciones codificadas en los triggers de acf, rpi, aci, eia y act
CREATE TABLE sgspi.estado_flujo_catalogo (
    efc_codigo          SMALLINT      IDENTITY (1, 1) NOT NULL,
    efc_dominio         NVARCHAR (10) NOT NULL, -- 'ACF', 'RPI', 'ACI', 'EIA', 'ACT'
    efc_identificador   NVARCHAR (30) NOT NULL, -- 'BORRADOR', 'VIGENTE', ...
    efc_nombre          NVARCHAR (80) NOT NULL,
    efc_es_inicial      BIT           CONSTRAINT DF_efc_es_inicial DEFAULT 0 NOT NULL, -- Único estado permitido en INSERT
    efc_permite_edicion BIT           CONSTRAINT DF_efc_permite_edicion DEFAULT 1 NOT NULL, -- 0: no se pueden editar datos sin cambiar de estado
    efc_estado          BIT           CONSTRAINT DF_efc_estado DEFAULT 1 NOT NULL,
    CONSTRAINT PK_efc_estado_flujo_catalogo PRIMARY KEY CLUSTERED (efc_codigo),
    CONSTRAINT UQ_efc_dominio_identificador UNIQUE (efc_dominio, efc_identificador),
    CONSTRAINT CK_efc_dominio CHECK (efc_dominio IN (N'ACF', N'RPI', N'ACI', N'EIA', N'ACT'))
);

-- Un único estado inicial activo por dominio de flujo
CREATE UNIQUE NONCLUSTERED INDEX UX_efc_estado_inicial
    ON sgspi.estado_flujo_catalogo(efc_dominio) WHERE efc_es_inicial = 1
                                                      AND efc_estado = 1;

CREATE TABLE sgspi.transicion_estado_flujo (
    tef_codigo                SMALLINT      IDENTITY (1, 1) NOT NULL,
    efc_dominio               NVARCHAR (10) NOT NULL,
    efc_identificador_origen  NVARCHAR (30) NOT NULL,
    efc_identificador_destino NVARCHAR (30) NOT NULL,
    tef_rol_requerido         SYSNAME       NULL, -- NULL = cualquier rol con UPDATE
    tef_estado                BIT           CONSTRAINT DF_tef_estado DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
    CONSTRAINT PK_tef_transicion_estado_flujo PRIMARY KEY CLUSTERED (tef_codigo),
    CONSTRAINT FK_tef_estado_origen FOREIGN KEY (efc_dominio, efc_identificador_origen) REFERENCES sgspi.estado_flujo_catalogo (efc_dominio, efc_identificador),
    CONSTRAINT FK_tef_estado_destino FOREIGN KEY (efc_dominio, efc_identificador_destino) REFERENCES sgspi.estado_flujo_catalogo (efc_dominio, efc_identificador),
    CONSTRAINT CK_tef_origen_distinto_destino CHECK (efc_identificador_origen <> efc_identificador_destino)
);

CREATE UNIQUE NONCLUSTERED INDEX UX_tef_dominio_origen_destino_rol
    ON sgspi.transicion_estado_flujo(efc_dominio, efc_identificador_origen, efc_identificador_destino, tef_rol_requerido) WHERE tef_estado = 1; -- [AP-22] una fila activa por rol permitido


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
       (N'EIA', N'BORRADOR', N'Borrador', 1, 1), (N'EIA', N'EN_VALIDACION_LIDER', N'En validación del líder', 0, 1), (N'EIA', N'EN_REVISION_SGSPI', N'En revisión SGSPI', 0, 1), (N'EIA', N'OBSERVADO', N'Observado', 0, 1), (N'EIA', N'EN_ACEPTACION_COMITE', N'En aceptación del comité', 0, 1), (N'EIA', N'APROBADO_PLANIFICADO', N'Aprobado y planificado', 0, 0), (N'EIA', N'EN_EJECUCION', N'En ejecución', 0, 0), (N'EIA', N'EN_EVALUACION_EFICACIA', N'En evaluación de eficacia', 0, 0), (N'EIA', N'CERRADO_EFICAZ', N'Cerrado eficaz', 0, 0), (N'EIA', N'HISTORICO', N'Histórico', 0, 0), -- ACT: Actividades de Tratamiento
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
    tpr_estado        BIT            CONSTRAINT DF_tpr_estado DEFAULT 1 NOT NULL, -- [AP-17]
    CONSTRAINT PK_tpr_tipo_proceso_catalogo PRIMARY KEY CLUSTERED (tpr_codigo),
    CONSTRAINT CK_tpr_nombre_no_vacio CHECK (LEN(TRIM(tpr_nombre)) > 0)
);

CREATE UNIQUE NONCLUSTERED INDEX UX_tpr_identificador
    ON sgspi.tipo_proceso_catalogo(tpr_identificador) WHERE tpr_estado = 1; -- [AP-22]

CREATE UNIQUE NONCLUSTERED INDEX UX_tpr_nombre
    ON sgspi.tipo_proceso_catalogo(tpr_nombre) WHERE tpr_estado = 1; -- [AP-22]

-- 1.4 [pri] Procesos Institucionales (Los 21 procesos del SGC / SGSPI USCO)
CREATE TABLE sgspi.proceso_institucional (
    pri_codigo        INT            IDENTITY (1, 1) NOT NULL,
    pri_identificador NVARCHAR (20)  NOT NULL,
    pri_nombre        NVARCHAR (150) NOT NULL,
    tpr_codigo        TINYINT        NOT NULL, -- FK a [sgspi].[tipo_proceso_catalogo]([tpr_codigo])
    uaa_codigo_lider  INT            NULL, -- FK a [dbo].[uaa]([uaa_codigo])
    car_codigo_lider  INT            NULL, -- FK a [dbo].[cargo]([car_codigo])
    pri_estado        BIT            CONSTRAINT DF_pri_estado DEFAULT 1 NOT NULL, -- [AP-17]
    CONSTRAINT PK_pri_proceso_institucional PRIMARY KEY CLUSTERED (pri_codigo),
    CONSTRAINT FK_pri_tipo_proceso FOREIGN KEY (tpr_codigo) REFERENCES sgspi.tipo_proceso_catalogo (tpr_codigo),
    CONSTRAINT CK_pri_identificador_no_vacio CHECK (LEN(TRIM(pri_identificador)) > 0), -- [AP-14]
    CONSTRAINT CK_pri_nombre_no_vacio CHECK (LEN(TRIM(pri_nombre)) > 0), -- [B4]
    CONSTRAINT CK_pri_lider_coherente CHECK ((uaa_codigo_lider IS NULL
                                              AND car_codigo_lider IS NULL)
                                             OR (uaa_codigo_lider IS NOT NULL
                                                 AND car_codigo_lider IS NOT NULL)) -- [B4] par coherente UAA/cargo líder
);

CREATE UNIQUE NONCLUSTERED INDEX UX_pri_identificador
    ON sgspi.proceso_institucional(pri_identificador) WHERE pri_estado = 1; -- [AP-14] [AP-22]

CREATE UNIQUE NONCLUSTERED INDEX UX_pri_nombre
    ON sgspi.proceso_institucional(pri_nombre) WHERE pri_estado = 1; -- [AP-22]




-- 1.5 [piu] Tabla Puente N:M Proceso Institucional <-> Unidades Académico-Administrativas ([dbo].[uaa])
-- [AP-09] Se elimina piu_es_responsable_principal: la UAA líder del proceso es [uaa_codigo_lider] (una sola fuente de verdad)
CREATE TABLE sgspi.proceso_institucional_uaa (
    pri_codigo      INT NOT NULL, -- FK a [sgspi].[proceso_institucional]([pri_codigo])
    uaa_codigo      INT NOT NULL, -- FK a [dbo].[uaa]([uaa_codigo])
    piu_estado      BIT CONSTRAINT DF_piu_estado DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
    CONSTRAINT PK_piu_proceso_institucional_uaa PRIMARY KEY CLUSTERED (pri_codigo, uaa_codigo),
    CONSTRAINT FK_piu_proceso_institucional FOREIGN KEY (pri_codigo) REFERENCES sgspi.proceso_institucional (pri_codigo)
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
    fec_estado         BIT            CONSTRAINT DF_fec_estado DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
    CONSTRAINT PK_fec_factor_entorno_catalogo PRIMARY KEY CLUSTERED (fec_codigo),
    CONSTRAINT UQ_fec_codigo_ambito UNIQUE (fec_codigo, fec_ambito_entorno), -- [AP-06] destino de la FK compuesta FK_acf_factor_entorno_ambito
    CONSTRAINT CK_fec_ambito_entorno CHECK (fec_ambito_entorno IN (N'INTERNO', N'EXTERNO')),
    CONSTRAINT CK_fec_nombre_no_vacio CHECK (LEN(TRIM(fec_nombre_factor)) > 0) -- [B4]
);

CREATE UNIQUE NONCLUSTERED INDEX UX_fec_nombre_ambito
    ON sgspi.factor_entorno_catalogo(fec_nombre_factor, fec_ambito_entorno) WHERE fec_estado = 1; -- [AP-22]

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
    acf_nivel_prioridad         AS                 (CASE acf_valor_prioridad WHEN 3 THEN N'ALTA' WHEN 2 THEN N'MEDIA' ELSE N'BAJA' END),
    acf_impacto_sistema_gestion NVARCHAR (1000)    NULL,
    acf_accion_propuesta        NVARCHAR (1000)    NULL,
    acf_fase_registro           NVARCHAR (30)      CONSTRAINT DF_acf_fase_registro DEFAULT N'BORRADOR' NOT NULL, -- [AP-17]
    efc_dominio                 AS                 (CONVERT (NVARCHAR (10), N'ACF')) PERSISTED, -- [AP-05] Dominio constante para la FK al catálogo de estados
    per_codigo_creador          INT                NOT NULL, -- FK a [dbo].[persona]([per_codigo])
    per_codigo_aprobador        INT                NULL, -- FK a [dbo].[persona]([per_codigo])
    acf_fecha_creacion          DATETIMEOFFSET (0) CONSTRAINT DF_acf_fecha_creacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17]
    acf_fecha_actualizacion     DATETIMEOFFSET (0) CONSTRAINT DF_acf_fecha_actualizacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17]
    acf_estado                  BIT                CONSTRAINT DF_acf_estado DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
    acf_version                 ROWVERSION         NOT NULL, -- [AP-24] Control de concurrencia optimista
    CONSTRAINT PK_acf_analisis_contexto_factor PRIMARY KEY CLUSTERED (acf_codigo),
    CONSTRAINT FK_acf_periodo_vigencia FOREIGN KEY (pev_codigo) REFERENCES sgspi.periodo_vigencia (pev_codigo),
    CONSTRAINT FK_acf_proceso_institucional FOREIGN KEY (pri_codigo) REFERENCES sgspi.proceso_institucional (pri_codigo),
    CONSTRAINT FK_acf_factor_entorno_ambito FOREIGN KEY (fec_codigo, fec_ambito_entorno) REFERENCES sgspi.factor_entorno_catalogo (fec_codigo, fec_ambito_entorno), -- [AP-06] el factor tiene el ámbito que pide la naturaleza
    CONSTRAINT FK_acf_estado_flujo FOREIGN KEY (efc_dominio, acf_fase_registro) REFERENCES sgspi.estado_flujo_catalogo (efc_dominio, efc_identificador), -- [AP-05]
    CONSTRAINT CK_acf_naturaleza_factor CHECK (acf_naturaleza_factor IN (N'DEBILIDAD', N'FORTALEZA', N'AMENAZA', N'OPORTUNIDAD')),
    CONSTRAINT CK_acf_descripcion_no_vacia CHECK (LEN(TRIM(acf_descripcion_situacion)) > 0), -- [B4]
    CONSTRAINT CK_acf_numero_factor_positivo CHECK (acf_numero_factor >= 1),
    CONSTRAINT CK_acf_valor_prioridad CHECK (acf_valor_prioridad IN (1, 2, 3)),
    -- RN-DOFA-03: Si la prioridad es ALTA (3) y no está en borrador, exige Impacto y Acción Propuesta
    CONSTRAINT CK_acf_prioridad_alta_campos CHECK (acf_fase_registro = N'BORRADOR'
                                                   OR acf_valor_prioridad <> 3
                                                   OR (LEN(TRIM(ISNULL(acf_impacto_sistema_gestion, N''))) > 0
                                                       AND LEN(TRIM(ISNULL(acf_accion_propuesta, N''))) > 0)),
    -- [AP-05] Se elimina CK_acf_fase_registro (lista de estados): ahora lo garantiza FK_acf_estado_flujo
    -- [AP-15] Segregación de funciones: el aprobador no puede ser el creador (la firma la escribe TR_acf_integridad_y_actualizacion)
    CONSTRAINT CK_acf_sod_aprobador CHECK (per_codigo_aprobador IS NULL
                                           OR per_codigo_aprobador <> per_codigo_creador)
)
WITH (DATA_COMPRESSION = ROW);

-- [AP-18] [AP-22] Índice único filtrado por activo (permite recrear tras borrado lógico) + índice no filtrado para FK_acf_periodo_vigencia
CREATE UNIQUE NONCLUSTERED INDEX UX_acf_vigencia_naturaleza_numero
    ON sgspi.analisis_contexto_factor(pev_codigo, acf_naturaleza_factor, acf_numero_factor)
    INCLUDE(acf_identificador_factor, pri_codigo, fec_codigo) WHERE acf_estado = 1
    WITH (DATA_COMPRESSION = ROW);

CREATE NONCLUSTERED INDEX IX_acf_pev_estado
    ON sgspi.analisis_contexto_factor(pev_codigo, acf_estado) WITH (DATA_COMPRESSION = ROW);

CREATE NONCLUSTERED INDEX IX_acf_pri_codigo
    ON sgspi.analisis_contexto_factor(pri_codigo) WITH (DATA_COMPRESSION = ROW);

CREATE NONCLUSTERED INDEX IX_acf_fec_codigo
    ON sgspi.analisis_contexto_factor(fec_codigo) WITH (DATA_COMPRESSION = ROW);



CREATE NONCLUSTERED INDEX IX_acf_fase_estado
    ON sgspi.analisis_contexto_factor(acf_fase_registro, acf_estado) WITH (DATA_COMPRESSION = ROW);


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
    pai_estado          BIT            CONSTRAINT DF_pai_estado DEFAULT 1 NOT NULL, -- [AP-17]
    CONSTRAINT PK_pai_parte_interesada PRIMARY KEY CLUSTERED (pai_codigo),
    CONSTRAINT CK_pai_origen CHECK (pai_origen IN (N'INTERNA', N'EXTERNA')),
    CONSTRAINT CK_pai_nombre_no_vacio CHECK (LEN(TRIM(pai_nombre)) > 0) -- [B4]
);

CREATE UNIQUE NONCLUSTERED INDEX UX_pai_nombre
    ON sgspi.parte_interesada(pai_nombre) WHERE pai_estado = 1; -- [AP-22]

-- 3.2 [rpi] Necesidades, Expectativas y Requisitos por Parte Interesada
CREATE TABLE sgspi.requisito_parte_interesada (
    rpi_codigo                 INT                IDENTITY (1, 1) NOT NULL,
    pev_codigo                 SMALLINT           NOT NULL, -- FK a [sgspi].[periodo_vigencia]([pev_codigo])
    pai_codigo                 INT                NOT NULL, -- FK a [sgspi].[parte_interesada]([pai_codigo])
    rpi_necesidad_expectativa  NVARCHAR (1000)    NOT NULL,
    rpi_valor_poder            TINYINT            CONSTRAINT DF_rpi_valor_poder DEFAULT 1 NOT NULL, -- 1=BAJA, 2=MEDIA, 3=ALTA
    rpi_valor_interes          TINYINT            CONSTRAINT DF_rpi_valor_interes DEFAULT 1 NOT NULL, -- 1=BAJA, 2=MEDIA, 3=ALTA
    rpi_nivel_poder            AS                 (CASE rpi_valor_poder WHEN 3 THEN N'ALTA' WHEN 2 THEN N'MEDIA' ELSE N'BAJA' END),
    rpi_nivel_interes          AS                 (CASE rpi_valor_interes WHEN 3 THEN N'ALTA' WHEN 2 THEN N'MEDIA' ELSE N'BAJA' END),
    -- Columna calculada #3: Clasificación según Poder vs Interés con aritmética entera
    rpi_clasificacion_impacto  AS                 (CASE WHEN rpi_valor_poder = 3
                                                             AND rpi_valor_interes >= 2 THEN N'CUIDADO' WHEN (rpi_valor_poder = 3
                                                                                                              AND rpi_valor_interes = 1)
                                                                                                             OR (rpi_valor_poder = 2
                                                                                                                 AND rpi_valor_interes >= 2) THEN N'ATENCION' WHEN (rpi_valor_poder = 2
                                                                                                                                                                    AND rpi_valor_interes = 1)
                                                                                                                                                                   OR (rpi_valor_poder = 1
                                                                                                                                                                       AND rpi_valor_interes = 3) THEN N'MITIGANTE' ELSE N'SIN_PROBLEMA' END),
    rpi_valor_cumplimiento     TINYINT            NULL, -- 1=BAJA, 2=MEDIA, 3=ALTA (NULL cuando aún no se ha evaluado)
    rpi_nivel_cumplimiento     AS                 (CASE rpi_valor_cumplimiento WHEN 3 THEN N'ALTA' WHEN 2 THEN N'MEDIA' WHEN 1 THEN N'BAJA' ELSE NULL END),
    -- Columna calculada PERSISTED #4: Prioridad de Acción con aritmética directa (4 - cumplimiento) y etiqueta
    rpi_valor_prioridad_accion AS                 (CAST (4 - rpi_valor_cumplimiento AS TINYINT)) PERSISTED,
    rpi_prioridad_accion       AS                 (CASE rpi_valor_cumplimiento WHEN 1 THEN N'ALTA' WHEN 2 THEN N'MEDIA' WHEN 3 THEN N'BAJA' ELSE NULL END),
    rpi_mecanismo_seguimiento  NVARCHAR (255)     NULL,
    rpi_fase_registro          NVARCHAR (30)      CONSTRAINT DF_rpi_fase_registro DEFAULT N'BORRADOR' NOT NULL, -- [AP-04] [AP-17] El INSERT solo puede nacer en el estado inicial
    efc_dominio                AS                 (CONVERT (NVARCHAR (10), N'RPI')) PERSISTED, -- [AP-05] Dominio constante para la FK al catálogo de estados
    per_codigo_creador         INT                NOT NULL, -- [AP-15] FK a [dbo].[persona]([per_codigo])
    per_codigo_aprobador       INT                NULL, -- [AP-15] FK a [dbo].[persona]([per_codigo])
    rpi_fecha_creacion         DATETIMEOFFSET (0) CONSTRAINT DF_rpi_fecha_creacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17]
    rpi_fecha_actualizacion    DATETIMEOFFSET (0) CONSTRAINT DF_rpi_fecha_actualizacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17]
    rpi_estado                 BIT                CONSTRAINT DF_rpi_estado DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
    rpi_version                ROWVERSION         NOT NULL, -- [AP-24] Control de concurrencia optimista
    CONSTRAINT PK_rpi_requisito_parte_interesada PRIMARY KEY CLUSTERED (rpi_codigo),
    CONSTRAINT FK_rpi_periodo_vigencia FOREIGN KEY (pev_codigo) REFERENCES sgspi.periodo_vigencia (pev_codigo),
    CONSTRAINT FK_rpi_parte_interesada FOREIGN KEY (pai_codigo) REFERENCES sgspi.parte_interesada (pai_codigo),
    CONSTRAINT FK_rpi_estado_flujo FOREIGN KEY (efc_dominio, rpi_fase_registro) REFERENCES sgspi.estado_flujo_catalogo (efc_dominio, efc_identificador), -- [AP-05]
    CONSTRAINT CK_rpi_valores_escala CHECK (rpi_valor_poder IN (1, 2, 3)
                                            AND rpi_valor_interes IN (1, 2, 3)
                                            AND (rpi_valor_cumplimiento IS NULL
                                                 OR rpi_valor_cumplimiento IN (1, 2, 3))),
    CONSTRAINT CK_rpi_necesidad_no_vacia CHECK (LEN(TRIM(rpi_necesidad_expectativa)) > 0), -- [B4]
    -- [AP-05] Se elimina CK_rpi_fase_registro (lista de estados): ahora lo garantiza FK_rpi_estado_flujo
    -- [AP-15] Segregación de funciones: el aprobador no puede ser el creador (la firma la escribe TR_rpi_integridad_y_actualizacion)
    CONSTRAINT CK_rpi_sod_aprobador CHECK (per_codigo_aprobador IS NULL
                                           OR per_codigo_aprobador <> per_codigo_creador)
)
WITH (DATA_COMPRESSION = ROW);

CREATE NONCLUSTERED INDEX IX_rpi_pev_codigo
    ON sgspi.requisito_parte_interesada(pev_codigo) WITH (DATA_COMPRESSION = ROW);

CREATE NONCLUSTERED INDEX IX_rpi_pai_codigo
    ON sgspi.requisito_parte_interesada(pai_codigo) WITH (DATA_COMPRESSION = ROW);



CREATE NONCLUSTERED INDEX IX_rpi_fase_estado
    ON sgspi.requisito_parte_interesada(rpi_fase_registro, rpi_estado) WITH (DATA_COMPRESSION = ROW);

-- 3.3 [rpp] Relación N:M Requisito de Parte Interesada <-> Proceso Institucional
CREATE TABLE sgspi.requisito_parte_interesada_proceso_institucional (
    rpi_codigo         INT                NOT NULL, -- FK a [sgspi].[requisito_parte_interesada]([rpi_codigo])
    pri_codigo         INT                NOT NULL, -- FK a [sgspi].[proceso_institucional]([pri_codigo])
    rpp_fecha_registro DATETIMEOFFSET (0) CONSTRAINT DF_rpp_fecha_registro DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17]
    rpp_estado         BIT                CONSTRAINT DF_rpp_estado DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
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
    tac_estado                BIT            CONSTRAINT DF_tac_estado DEFAULT 1 NOT NULL, -- [AP-17]
    CONSTRAINT PK_tac_tipo_activo_catalogo PRIMARY KEY CLUSTERED (tac_codigo),
    CONSTRAINT UQ_tac_codigo_nivel UNIQUE (tac_codigo, tac_nivel_taxonomia), -- [AP-06] Destino de FK compuestas (FK_tac_padre y eia)
    CONSTRAINT FK_tac_padre FOREIGN KEY (tac_codigo_padre, tac_nivel_taxonomia_padre) REFERENCES sgspi.tipo_activo_catalogo (tac_codigo, tac_nivel_taxonomia), -- [AP-06] El padre está exactamente un nivel arriba
    CONSTRAINT CK_tac_nivel_coherente CHECK ((tac_nivel_taxonomia = 1
                                              AND tac_codigo_padre IS NULL)
                                             OR (tac_nivel_taxonomia IN (2, 3)
                                                 AND tac_codigo_padre IS NOT NULL
                                                 AND tac_codigo_padre <> tac_codigo)),
    CONSTRAINT CK_tac_nombre_no_vacio CHECK (LEN(TRIM(tac_nombre)) > 0)
);

CREATE UNIQUE NONCLUSTERED INDEX UX_tac_padre_nombre
    ON sgspi.tipo_activo_catalogo(tac_codigo_padre, tac_nombre) WHERE tac_estado = 1; -- [AP-22]

-- 4.2 [cet] Catálogo de Causales de Excepción de Transparencia (Desacoplado de Ley 1712 de 2014)
CREATE TABLE sgspi.causal_excepcion_transparencia (
    cet_codigo                  SMALLINT       IDENTITY (1, 1) NOT NULL,
    cet_nivel_reserva_aplicable NVARCHAR (20)  NOT NULL, -- 'CLASIFICADA' (3 causales) o 'RESERVADA' (9 causales)
    cet_numeral_causal          NVARCHAR (10)  NOT NULL,
    cet_descripcion_causal      NVARCHAR (500) NOT NULL,
    cet_norma_referencia        NVARCHAR (100) CONSTRAINT DF_cet_norma_referencia DEFAULT N'Ley 1712 de 2014' NOT NULL, -- [AP-17]
    cet_estado                  BIT            CONSTRAINT DF_cet_estado DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
    CONSTRAINT PK_cet_causal_excepcion_transparencia PRIMARY KEY CLUSTERED (cet_codigo),
    CONSTRAINT UQ_cet_codigo_nivel UNIQUE (cet_codigo, cet_nivel_reserva_aplicable), -- [AP-06] Destino de la FK compuesta FK_aci_causal_excepcion
    CONSTRAINT CK_cet_nivel_reserva CHECK (cet_nivel_reserva_aplicable IN (N'CLASIFICADA', N'RESERVADA')),
    CONSTRAINT CK_cet_textos_no_vacios CHECK (LEN(TRIM(cet_numeral_causal)) > 0
                                              AND LEN(TRIM(cet_descripcion_causal)) > 0) -- [B4]
);

CREATE UNIQUE NONCLUSTERED INDEX UX_cet_nivel_numeral
    ON sgspi.causal_excepcion_transparencia(cet_nivel_reserva_aplicable, cet_numeral_causal) WHERE cet_estado = 1; -- [AP-14] [AP-22]

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
    -- Columnas calculadas #5: Etiquetas CID unificadas ('ALTA'/'MEDIA'/'BAJA'), Puntaje y Nivel de Criticidad
    aci_nivel_confidencialidad          AS                 (CASE aci_valor_confidencialidad WHEN 3 THEN N'ALTA' WHEN 2 THEN N'MEDIA' ELSE N'BAJA' END),
    aci_nivel_integridad                AS                 (CASE aci_valor_integridad WHEN 3 THEN N'ALTA' WHEN 2 THEN N'MEDIA' ELSE N'BAJA' END),
    aci_nivel_disponibilidad            AS                 (CASE aci_valor_disponibilidad WHEN 3 THEN N'ALTA' WHEN 2 THEN N'MEDIA' ELSE N'BAJA' END),
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
    aci_fase_registro                   NVARCHAR (30)      CONSTRAINT DF_aci_fase_registro DEFAULT N'BORRADOR' NOT NULL, -- [AP-04] El INSERT solo puede iniciar en el estado inicial del flujo
    per_codigo_creador                  INT                NOT NULL, -- FK a [dbo].[persona]([per_codigo])
    per_codigo_aprobador                INT                NULL, -- FK a [dbo].[persona]([per_codigo])
    per_codigo_revisor_archivo          INT                NULL, -- [B1] Aval Gestión Documental / Secretaría General (movido desde [ado] para eliminar deadlock TR_aci <-> TR_ado)
    aci_fecha_creacion                  DATETIMEOFFSET (0) CONSTRAINT DF_aci_fecha_creacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12]
    aci_fecha_actualizacion             DATETIMEOFFSET (0) CONSTRAINT DF_aci_fecha_actualizacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12]
    aci_estado                          BIT                CONSTRAINT DF_aci_estado DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
    aci_version                         ROWVERSION         NOT NULL, -- [AP-24] Control de concurrencia optimista
    CONSTRAINT PK_aci_activo_informacion PRIMARY KEY CLUSTERED (aci_codigo),
    CONSTRAINT UQ_aci_codigo_transversal UNIQUE (aci_codigo, aci_es_transversal_sedes) WITH (DATA_COMPRESSION = ROW), -- [AP-06] destino de FK_ais_activo_no_transversal
    CONSTRAINT FK_aci_tipo_activo FOREIGN KEY (tac_codigo) REFERENCES sgspi.tipo_activo_catalogo (tac_codigo),
    CONSTRAINT FK_aci_causal_excepcion FOREIGN KEY (cet_codigo, aci_clasificacion_transparencia) REFERENCES sgspi.causal_excepcion_transparencia (cet_codigo, cet_nivel_reserva_aplicable), -- [AP-06] La causal debe corresponder al nivel de reserva del activo (no se evalúa con cet_codigo NULL)
    CONSTRAINT FK_aci_estado_flujo FOREIGN KEY (efc_dominio, aci_fase_registro) REFERENCES sgspi.estado_flujo_catalogo (efc_dominio, efc_identificador), -- [AP-05]
    CONSTRAINT CK_aci_textos_no_vacios CHECK (LEN(TRIM(aci_codigo_inventario)) > 0
                                              AND LEN(TRIM(aci_nombre_activo)) > 0), -- [B4]
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
    CONSTRAINT CK_aci_coherencia_indice_reserva CHECK (aci_fase_registro = N'BORRADOR'
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
    CONSTRAINT CK_aci_coherencia_pii CHECK (aci_fase_registro = N'BORRADOR'
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
    -- [AP-05] Se elimina CK_aci_fase_registro: los estados válidos viven en sgspi.estado_flujo_catalogo (FK_aci_estado_flujo)
    CONSTRAINT CK_aci_cantidad_unidades_positiva CHECK (aci_cantidad_unidades >= 1),
    -- [AP-15] [B4] Segregación de funciones: aprobador y revisor de Archivo distintos del creador y distintos entre sí
    CONSTRAINT CK_aci_sod_aprobador CHECK (per_codigo_aprobador IS NULL
                                           OR per_codigo_aprobador <> per_codigo_creador),
    CONSTRAINT CK_aci_sod_revisor_archivo CHECK (per_codigo_revisor_archivo IS NULL
                                                 OR (per_codigo_revisor_archivo <> per_codigo_creador
                                                     AND (per_codigo_aprobador IS NULL
                                                          OR per_codigo_revisor_archivo <> per_codigo_aprobador)))
)
WITH (DATA_COMPRESSION = ROW);

CREATE UNIQUE NONCLUSTERED INDEX UX_aci_codigo_inventario
    ON sgspi.activo_informacion(aci_codigo_inventario) WHERE aci_estado = 1 WITH (DATA_COMPRESSION = ROW); -- [AP-22]

CREATE NONCLUSTERED INDEX IX_aci_tac_codigo
    ON sgspi.activo_informacion(tac_codigo)
    INCLUDE(aci_fase_registro, aci_nivel_criticidad)
    WITH (DATA_COMPRESSION = ROW);

CREATE NONCLUSTERED INDEX IX_aci_uaa_codigo
    ON sgspi.activo_informacion(uaa_codigo) WITH (DATA_COMPRESSION = ROW);

CREATE NONCLUSTERED INDEX IX_aci_esp_codigo
    ON sgspi.activo_informacion(esp_codigo) WITH (DATA_COMPRESSION = ROW);




CREATE NONCLUSTERED INDEX IX_aci_fase_estado
    ON sgspi.activo_informacion(aci_fase_registro, aci_estado) WITH (DATA_COMPRESSION = ROW);

-- 4.4 [aip], [ais], [air] Tablas Asociativas N:M Unificadas de Activos de Información (Compartidas por el Supertipo y todos sus Subtipos)
CREATE TABLE sgspi.activo_informacion_proceso_institucional (
    aci_codigo      INT NOT NULL, -- FK a [sgspi].[activo_informacion]([aci_codigo])
    pri_codigo      INT NOT NULL, -- FK a [sgspi].[proceso_institucional]([pri_codigo])
    aip_estado      BIT CONSTRAINT DF_aip_estado DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
    CONSTRAINT PK_aip_activo_informacion_proceso_institucional PRIMARY KEY CLUSTERED (aci_codigo, pri_codigo),
    CONSTRAINT FK_aip_activo_informacion FOREIGN KEY (aci_codigo) REFERENCES sgspi.activo_informacion (aci_codigo),
    CONSTRAINT FK_aip_proceso_institucional FOREIGN KEY (pri_codigo) REFERENCES sgspi.proceso_institucional (pri_codigo)
);

CREATE NONCLUSTERED INDEX IX_aip_pri_codigo
    ON sgspi.activo_informacion_proceso_institucional(pri_codigo);

CREATE TABLE sgspi.activo_informacion_sede (
    aci_codigo               INT NOT NULL, -- FK a [sgspi].[activo_informacion]([aci_codigo])
    sus_codigo               INT NOT NULL, -- FK a [dbo].[sub_sede]([sus_codigo]) (contiene [sed_codigo] hacia [dbo].[sede])
    ais_estado               BIT CONSTRAINT DF_ais_estado DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
    aci_es_transversal_sedes AS  (CASE WHEN ais_estado = 1 THEN CONVERT (BIT, 0) END) PERSISTED, -- [AP-06] una sede activa exige un activo no transversal; inactiva = NULL, la FK no la valida
    CONSTRAINT PK_ais_activo_informacion_sede PRIMARY KEY CLUSTERED (aci_codigo, sus_codigo),
    CONSTRAINT FK_ais_activo_informacion FOREIGN KEY (aci_codigo) REFERENCES sgspi.activo_informacion (aci_codigo),
    CONSTRAINT FK_ais_activo_no_transversal FOREIGN KEY (aci_codigo, aci_es_transversal_sedes) REFERENCES sgspi.activo_informacion (aci_codigo, aci_es_transversal_sedes) -- [AP-06]
);

CREATE NONCLUSTERED INDEX IX_ais_sus_codigo
    ON sgspi.activo_informacion_sede(sus_codigo);

CREATE TABLE sgspi.activo_informacion_responsable (
    aci_codigo               INT           NOT NULL, -- FK a [sgspi].[activo_informacion]([aci_codigo])
    car_codigo               INT           NOT NULL, -- FK a [dbo].[cargo]([car_codigo]): Cargo institucional responsable (ISO 27001 / Ley 594)
    uaa_codigo               INT           NOT NULL, -- FK a [dbo].[uaa]([uaa_codigo]): Dependencia del cargo
    air_tipo_responsabilidad NVARCHAR (20) NOT NULL, -- 'PROPIETARIO', 'CUSTODIO'
    air_estado               BIT           CONSTRAINT DF_air_estado DEFAULT 1 NOT NULL, -- [AP-17]
    -- Clave primaria compuesta 100% NOT NULL (elimina UNIQUE sobre columnas NULL [uap_codigo]/[uac_codigo] y unifica [air] + [adr])
    CONSTRAINT PK_air_activo_informacion_responsable PRIMARY KEY CLUSTERED (aci_codigo, car_codigo, uaa_codigo, air_tipo_responsabilidad),
    CONSTRAINT FK_air_activo_informacion FOREIGN KEY (aci_codigo) REFERENCES sgspi.activo_informacion (aci_codigo),
    CONSTRAINT CK_air_tipo_responsabilidad CHECK (air_tipo_responsabilidad IN (N'PROPIETARIO', N'CUSTODIO'))
);

CREATE NONCLUSTERED INDEX IX_air_car_codigo
    ON sgspi.activo_informacion_responsable(car_codigo)
    INCLUDE(air_estado); -- [AP-18] aci_codigo y air_tipo_responsabilidad ya son parte de la clave clustered

CREATE NONCLUSTERED INDEX IX_air_uaa_codigo
    ON sgspi.activo_informacion_responsable(uaa_codigo)
    INCLUDE(air_estado); -- [AP-18] aci_codigo ya es parte de la clave clustered

-- D3: un solo propietario activo por activo; los demás responsables son custodios (TR_aci lo exige para aprobar)
CREATE UNIQUE NONCLUSTERED INDEX UX_air_propietario_activo
    ON sgspi.activo_informacion_responsable(aci_codigo) WHERE air_tipo_responsabilidad = N'PROPIETARIO'
                                                              AND air_estado = 1;

CREATE NONCLUSTERED INDEX IX_air_aci_tipo_activo
    ON sgspi.activo_informacion_responsable(aci_codigo, air_tipo_responsabilidad, air_estado);

-- 4.5 [sif] y [msi] Ficha Técnica de Sistemas de Información y sus Módulos (Los 17 Sistemas USCO)
CREATE TABLE sgspi.sistema_informacion_ficha (
    sif_codigo               INT             IDENTITY (1, 1) NOT NULL,
    aci_codigo               INT             NULL, -- FK a [sgspi].[activo_informacion]([aci_codigo])
    sif_nombre_sistema       NVARCHAR (150)  NOT NULL,
    sif_modalidad_desarrollo NVARCHAR (50)   NOT NULL, -- [AP-08] 'PROPIO', 'PROPIO_EN_DESARROLLO', 'CODIGO_ABIERTO_ADAPTADO', 'COMERCIAL_TERCERO'
    sif_fabricante_proveedor NVARCHAR (150)  NULL,
    sif_descripcion_general  NVARCHAR (1000) NOT NULL,
    sif_estado               BIT             CONSTRAINT DF_sif_estado DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
    CONSTRAINT PK_sif_sistema_informacion_ficha PRIMARY KEY CLUSTERED (sif_codigo),
    CONSTRAINT FK_sif_activo_informacion FOREIGN KEY (aci_codigo) REFERENCES sgspi.activo_informacion (aci_codigo),
    CONSTRAINT CK_sif_modalidad_desarrollo CHECK (sif_modalidad_desarrollo IN (N'PROPIO', N'PROPIO_EN_DESARROLLO', N'CODIGO_ABIERTO_ADAPTADO', N'COMERCIAL_TERCERO')), -- [AP-08]
    CONSTRAINT CK_sif_textos_no_vacios CHECK (LEN(TRIM(sif_nombre_sistema)) > 0
                                              AND LEN(TRIM(sif_descripcion_general)) > 0) -- [B4]
);

CREATE UNIQUE NONCLUSTERED INDEX UX_sif_nombre_sistema
    ON sgspi.sistema_informacion_ficha(sif_nombre_sistema) WHERE sif_estado = 1; -- [AP-22]

-- Índice único filtrado (SQL Server 2019) para relación 1:0..1 activa sobre columna NULL sin bloquear múltiples NULL
CREATE UNIQUE NONCLUSTERED INDEX UX_sif_aci_codigo
    ON sgspi.sistema_informacion_ficha(aci_codigo) WHERE aci_codigo IS NOT NULL
                                                         AND sif_estado = 1; -- [AP-22]

CREATE NONCLUSTERED INDEX IX_sif_aci_codigo
    ON sgspi.sistema_informacion_ficha(aci_codigo); -- soporte no filtrado de FK_sif_activo_informacion y RLS

CREATE TABLE sgspi.modulo_sistema_informacion (
    msi_codigo            INT            IDENTITY (1, 1) NOT NULL,
    sif_codigo            INT            NOT NULL, -- FK a [sgspi].[sistema_informacion_ficha]([sif_codigo])
    msi_nombre_modulo     NVARCHAR (200) NOT NULL,
    msi_usuarios_objetivo NVARCHAR (150) NULL,
    msi_estado            BIT            CONSTRAINT DF_msi_estado DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
    CONSTRAINT PK_msi_modulo_sistema_informacion PRIMARY KEY CLUSTERED (msi_codigo),
    CONSTRAINT FK_msi_sistema_informacion FOREIGN KEY (sif_codigo) REFERENCES sgspi.sistema_informacion_ficha (sif_codigo),
    CONSTRAINT CK_msi_nombre_no_vacio CHECK (LEN(TRIM(msi_nombre_modulo)) > 0) -- [B4]
);

CREATE UNIQUE NONCLUSTERED INDEX UX_msi_sistema_nombre
    ON sgspi.modulo_sistema_informacion(sif_codigo, msi_nombre_modulo) WHERE msi_estado = 1; -- [AP-14] [AP-22]

CREATE NONCLUSTERED INDEX IX_msi_sif_codigo
    ON sgspi.modulo_sistema_informacion(sif_codigo); -- soporte no filtrado de FK_msi_sistema_informacion


GO
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
    sdo_estado       BIT            CONSTRAINT DF_sdo_estado DEFAULT 1 NOT NULL, -- [AP-17]
    CONSTRAINT PK_sdo_serie_documental_catalogo PRIMARY KEY CLUSTERED (sdo_codigo),
    CONSTRAINT CK_sdo_numero_ccd_positivo CHECK (sdo_numero_ccd >= 1),
    CONSTRAINT CK_sdo_nombre_no_vacio CHECK (LEN(TRIM(sdo_nombre_serie)) > 0) -- [B4]
);

CREATE UNIQUE NONCLUSTERED INDEX UX_sdo_numero_ccd
    ON sgspi.serie_documental_catalogo(sdo_numero_ccd) WHERE sdo_estado = 1; -- [AP-22]

CREATE UNIQUE NONCLUSTERED INDEX UX_sdo_nombre_serie
    ON sgspi.serie_documental_catalogo(sdo_nombre_serie) WHERE sdo_estado = 1; -- [AP-22]

-- 4B.2 [sbd] Catálogo Maestro de Subseries Documentales del CCD/TRD (COD6 dentro de cada Serie)
CREATE TABLE sgspi.subserie_documental_catalogo (
    sbd_codigo          INT            IDENTITY (1, 1) NOT NULL,
    sdo_codigo          SMALLINT       NOT NULL, -- FK a [sgspi].[serie_documental_catalogo]([sdo_codigo])
    sbd_numero_ccd      SMALLINT       NOT NULL, -- COD6: Número secuencial de la subserie dentro de la serie
    sbd_nombre_subserie NVARCHAR (200) NOT NULL,
    sbd_estado          BIT            CONSTRAINT DF_sbd_estado DEFAULT 1 NOT NULL, -- [AP-17]
    CONSTRAINT PK_sbd_subserie_documental_catalogo PRIMARY KEY CLUSTERED (sbd_codigo),
    CONSTRAINT UQ_sbd_serie_subserie UNIQUE (sdo_codigo, sbd_codigo),
    CONSTRAINT FK_sbd_serie_documental FOREIGN KEY (sdo_codigo) REFERENCES sgspi.serie_documental_catalogo (sdo_codigo),
    CONSTRAINT CK_sbd_numero_ccd_positivo CHECK (sbd_numero_ccd >= 1),
    CONSTRAINT CK_sbd_nombre_no_vacio CHECK (LEN(TRIM(sbd_nombre_subserie)) > 0) -- [B4]
);

CREATE UNIQUE NONCLUSTERED INDEX UX_sbd_serie_numero
    ON sgspi.subserie_documental_catalogo(sdo_codigo, sbd_numero_ccd) WHERE sbd_estado = 1; -- [AP-22]

CREATE UNIQUE NONCLUSTERED INDEX UX_sbd_serie_nombre
    ON sgspi.subserie_documental_catalogo(sdo_codigo, sbd_nombre_subserie) WHERE sbd_estado = 1; -- [AP-22]

-- 4B.3 [upc] Estructura Jerárquica de Unidades Productoras del Cuadro de Clasificación Documental (Árbol N-Niveles con HIERARCHYID)
CREATE TABLE sgspi.unidad_productora_cuadro_clasificacion_documental (
    upc_codigo               INT            IDENTITY (1, 1) NOT NULL,
    upc_nodo_jerarquico      HIERARCHYID    NOT NULL, -- Ruta nativa HIERARCHYID (ej. '/1/', '/1/1/', '/1/1.1/', '/5/1/1/2/')
    upc_nodo_padre           AS             (NULLIF (upc_nodo_jerarquico.GetAncestor(1), hierarchyid::GetRoot())) PERSISTED, -- Padre directo determinístico (NULL en nivel 1)
    upc_nivel_jerarquico     AS             (upc_nodo_jerarquico.GetLevel()) PERSISTED, -- Nivel calculado automáticamente por el motor (1=Sección, 2=Subsección, 3..N=Subdivisiones)
    upc_codigo_archivistico  NVARCHAR (50)  NULL, -- Código documental TRD explícito desacoplado de HIERARCHYID para nodos intermedios (ej. '/1/1.1/' -> '1.2')
    upc_prefijo_archivistico AS             (COALESCE (NULLIF (LTRIM(RTRIM(upc_codigo_archivistico)), N''), CONVERT (NVARCHAR (50), REPLACE(REPLACE(CASE WHEN LEN(upc_nodo_jerarquico.ToString()) > 2 THEN SUBSTRING(upc_nodo_jerarquico.ToString(), 2, LEN(upc_nodo_jerarquico.ToString()) - 2) ELSE N'' END, N'.', N'-'), N'/', N'.')))) PERSISTED, -- Prefijo CCD efectivo (ej. '1', '1.1', '1.1-1', '5.1.1.2')
    uaa_codigo               INT            NULL, -- FK a [dbo].[uaa]([uaa_codigo]): Equivalencia organizacional en academia3000
    upc_nombre_unidad        NVARCHAR (150) NOT NULL, -- Ej: 'RECTORIA', 'SECRETARIA GENERAL', 'AREA GESTION DOCUMENTAL'
    upc_estado               BIT            CONSTRAINT DF_upc_estado DEFAULT 1 NOT NULL, -- [AP-17]
    CONSTRAINT PK_upc_unidad_productora_cuadro_clasificacion_documental PRIMARY KEY CLUSTERED (upc_codigo),
    CONSTRAINT UQ_upc_nodo_jerarquico UNIQUE (upc_nodo_jerarquico),
    CONSTRAINT FK_upc_nodo_padre FOREIGN KEY (upc_nodo_padre) REFERENCES sgspi.unidad_productora_cuadro_clasificacion_documental (upc_nodo_jerarquico),
    CONSTRAINT CK_upc_codigo_archivistico_no_vacio CHECK (upc_codigo_archivistico IS NULL
                                                          OR LEN(TRIM(upc_codigo_archivistico)) > 0),
    CONSTRAINT CK_upc_nivel_jerarquico_valido CHECK (upc_nodo_jerarquico.GetLevel() >= 1
                                                     AND upc_nodo_jerarquico.ToString() NOT LIKE N'%-%'), -- Permite '.' para inserción de nodos intermedios en HIERARCHYID
    CONSTRAINT CK_upc_nombre_no_vacio CHECK (LEN(TRIM(upc_nombre_unidad)) > 0) -- [B4]
);

CREATE UNIQUE NONCLUSTERED INDEX UX_upc_prefijo_archivistico
    ON sgspi.unidad_productora_cuadro_clasificacion_documental(upc_prefijo_archivistico) WHERE upc_estado = 1; -- [AP-22]

CREATE NONCLUSTERED INDEX IX_upc_busqueda_anchura
    ON sgspi.unidad_productora_cuadro_clasificacion_documental(upc_nivel_jerarquico, upc_nodo_jerarquico)
    INCLUDE(upc_prefijo_archivistico, upc_nombre_unidad);

CREATE NONCLUSTERED INDEX IX_upc_nodo_padre
    ON sgspi.unidad_productora_cuadro_clasificacion_documental(upc_nodo_padre)
    INCLUDE(upc_nivel_jerarquico, upc_prefijo_archivistico, upc_nombre_unidad);

CREATE NONCLUSTERED INDEX IX_upc_uaa_codigo
    ON sgspi.unidad_productora_cuadro_clasificacion_documental(uaa_codigo);

CREATE NONCLUSTERED INDEX IX_upc_nodo_cobertura -- [D2] cubriente para IsDescendantOf en vw_desglose_ccd_trd_mr04
    ON sgspi.unidad_productora_cuadro_clasificacion_documental(upc_nodo_jerarquico)
    INCLUDE(upc_estado, upc_prefijo_archivistico, upc_nombre_unidad);

-- 4B.4 [pdc], [epc], [src], [mcc], [idi], [fac] Catálogos Extensibles del Dominio Documental y Archivístico
CREATE TABLE sgspi.periodicidad_catalogo (
    pdc_codigo      SMALLINT      IDENTITY (1, 1) NOT NULL,
    pdc_nombre      NVARCHAR (40) NOT NULL, -- Ej: 'A solicitud', 'Diaria', 'Semanal', 'Mensual', 'Bimensual', 'Trimestral', 'Cuatrimestral', 'Semestral', 'Anual', 'Eventual'
    pdc_orden       TINYINT       CONSTRAINT DF_pdc_orden DEFAULT 1 NOT NULL, -- [AP-17]
    pdc_estado      BIT           CONSTRAINT DF_pdc_estado DEFAULT 1 NOT NULL, -- [AP-17]
    CONSTRAINT PK_pdc_periodicidad_catalogo PRIMARY KEY CLUSTERED (pdc_codigo),
    CONSTRAINT CK_pdc_nombre_no_vacio CHECK (LEN(TRIM(pdc_nombre)) > 0)
);

CREATE UNIQUE NONCLUSTERED INDEX UX_pdc_nombre
    ON sgspi.periodicidad_catalogo(pdc_nombre) WHERE pdc_estado = 1; -- [AP-22]

CREATE TABLE sgspi.estado_publicacion_catalogo (
    epc_codigo      SMALLINT       IDENTITY (1, 1) NOT NULL,
    epc_nombre      NVARCHAR (60)  NOT NULL, -- Ej: 'Publicada (Externo - Internet)', 'Publicada (Interno - Intranet)', 'No publicada'
    epc_descripcion NVARCHAR (255) NULL,
    epc_estado      BIT            CONSTRAINT DF_epc_estado DEFAULT 1 NOT NULL, -- [AP-17]
    CONSTRAINT PK_epc_estado_publicacion_catalogo PRIMARY KEY CLUSTERED (epc_codigo),
    CONSTRAINT CK_epc_nombre_no_vacio CHECK (LEN(TRIM(epc_nombre)) > 0)
);

CREATE UNIQUE NONCLUSTERED INDEX UX_epc_nombre
    ON sgspi.estado_publicacion_catalogo(epc_nombre) WHERE epc_estado = 1; -- [AP-22]

CREATE TABLE sgspi.soporte_registro_catalogo (
    src_codigo      SMALLINT      IDENTITY (1, 1) NOT NULL,
    src_nombre      NVARCHAR (30) NOT NULL, -- Ej: 'Físico', 'Digital', 'Óptico'
    src_estado      BIT           CONSTRAINT DF_src_estado DEFAULT 1 NOT NULL, -- [AP-17]
    CONSTRAINT PK_src_soporte_registro_catalogo PRIMARY KEY CLUSTERED (src_codigo),
    CONSTRAINT CK_src_nombre_no_vacio CHECK (LEN(TRIM(src_nombre)) > 0)
);

CREATE UNIQUE NONCLUSTERED INDEX UX_src_nombre
    ON sgspi.soporte_registro_catalogo(src_nombre) WHERE src_estado = 1; -- [AP-22]

CREATE TABLE sgspi.medio_conservacion_catalogo (
    mcc_codigo      SMALLINT      IDENTITY (1, 1) NOT NULL,
    mcc_nombre      NVARCHAR (30) NOT NULL, -- Ej: 'Físico', 'Electrónico', 'Microfilm', 'Nube'
    mcc_estado      BIT           CONSTRAINT DF_mcc_estado DEFAULT 1 NOT NULL, -- [AP-17]
    CONSTRAINT PK_mcc_medio_conservacion_catalogo PRIMARY KEY CLUSTERED (mcc_codigo),
    CONSTRAINT CK_mcc_nombre_no_vacio CHECK (LEN(TRIM(mcc_nombre)) > 0)
);

CREATE UNIQUE NONCLUSTERED INDEX UX_mcc_nombre
    ON sgspi.medio_conservacion_catalogo(mcc_nombre) WHERE mcc_estado = 1; -- [AP-22]

CREATE TABLE sgspi.idioma_catalogo (
    idi_codigo      SMALLINT      IDENTITY (1, 1) NOT NULL,
    idi_codigo_iso  NVARCHAR (10) NOT NULL, -- Ej: 'es', 'en', 'fr', 'pt' (ISO 639-1)
    idi_nombre      NVARCHAR (50) NOT NULL, -- Ej: 'Español', 'Inglés', 'Francés', 'Portugués'
    idi_estado      BIT           CONSTRAINT DF_idi_estado DEFAULT 1 NOT NULL, -- [AP-17]
    CONSTRAINT PK_idi_idioma_catalogo PRIMARY KEY CLUSTERED (idi_codigo),
    CONSTRAINT CK_idi_nombre_no_vacio CHECK (LEN(TRIM(idi_nombre)) > 0)
);

CREATE UNIQUE NONCLUSTERED INDEX UX_idi_codigo_iso
    ON sgspi.idioma_catalogo(idi_codigo_iso) WHERE idi_estado = 1; -- [AP-22]

CREATE UNIQUE NONCLUSTERED INDEX UX_idi_nombre
    ON sgspi.idioma_catalogo(idi_nombre) WHERE idi_estado = 1; -- [AP-22]

-- [AP-08] Catálogo de formatos de archivo (reemplaza el texto libre formato en texto libre)
CREATE TABLE sgspi.formato_archivo_catalogo (
    fac_codigo      SMALLINT      IDENTITY (1, 1) NOT NULL,
    fac_nombre      NVARCHAR (60) NOT NULL, -- Ej: 'Documento de texto', 'Hoja de cálculo', 'PDF', 'Imagen', 'Audio', 'Video'
    fac_estado      BIT           CONSTRAINT DF_fac_estado DEFAULT 1 NOT NULL, -- [AP-17]
    CONSTRAINT PK_fac_formato_archivo_catalogo PRIMARY KEY CLUSTERED (fac_codigo),
    CONSTRAINT CK_fac_nombre_no_vacio CHECK (LEN(TRIM(fac_nombre)) > 0)
);

CREATE UNIQUE NONCLUSTERED INDEX UX_fac_nombre
    ON sgspi.formato_archivo_catalogo(fac_nombre) WHERE fac_estado = 1; -- [AP-22]

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
    ado_fecha_creacion                DATETIMEOFFSET (0) CONSTRAINT DF_ado_fecha_creacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17]
    ado_fecha_actualizacion           DATETIMEOFFSET (0) CONSTRAINT DF_ado_fecha_actualizacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-11] La mantiene TR_ado_integridad_y_actualizacion
    ado_estado                        BIT                CONSTRAINT DF_ado_estado DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
    ado_version                       ROWVERSION         NOT NULL, -- [AP-24] Control de concurrencia optimista
    CONSTRAINT PK_ado_activo_documental PRIMARY KEY CLUSTERED (ado_codigo),
    CONSTRAINT FK_ado_activo_informacion FOREIGN KEY (ado_codigo) REFERENCES sgspi.activo_informacion (aci_codigo), -- [AP-10] PK compartida (reemplaza UQ_ado_activo_informacion)
    CONSTRAINT FK_ado_periodo_vigencia FOREIGN KEY (pev_codigo) REFERENCES sgspi.periodo_vigencia (pev_codigo),
    CONSTRAINT FK_ado_serie_documental FOREIGN KEY (sdo_codigo) REFERENCES sgspi.serie_documental_catalogo (sdo_codigo),
    CONSTRAINT FK_ado_subserie_documental FOREIGN KEY (sdo_codigo, sbd_codigo) REFERENCES sgspi.subserie_documental_catalogo (sdo_codigo, sbd_codigo),
    CONSTRAINT FK_ado_periodicidad FOREIGN KEY (pdc_codigo) REFERENCES sgspi.periodicidad_catalogo (pdc_codigo),
    CONSTRAINT FK_ado_estado_publicacion FOREIGN KEY (epc_codigo) REFERENCES sgspi.estado_publicacion_catalogo (epc_codigo),
    CONSTRAINT CK_ado_lugar_no_vacio CHECK (LEN(TRIM(ado_lugar_consulta_ubicacion)) > 0) -- [B4]
)
WITH (DATA_COMPRESSION = ROW);

CREATE NONCLUSTERED INDEX IX_ado_pev_codigo
    ON sgspi.activo_documental(pev_codigo, sdo_codigo, sbd_codigo) WITH (DATA_COMPRESSION = ROW); -- [AP-18] Se quita el INCLUDE de la columna eliminada (ado_codigo ya es clave clustered)

CREATE NONCLUSTERED INDEX IX_ado_sdo_sbd_codigo
    ON sgspi.activo_documental(sdo_codigo, sbd_codigo) WITH (DATA_COMPRESSION = ROW); -- [AP-18] Reemplaza IX_ado_sbd_codigo: sirve a FK_ado_serie_documental y FK_ado_subserie_documental



-- 4B.6 [ads], [adm], [adi], [adf] Tablas Puente N:M de Atributos Atómicos de Activos Documentales hacia Catálogos Extensibles
CREATE TABLE sgspi.activo_documental_soporte_registro (
    ado_codigo      INT      NOT NULL, -- FK a [sgspi].[activo_documental]([ado_codigo])
    src_codigo      SMALLINT NOT NULL, -- FK a [sgspi].[soporte_registro_catalogo]([src_codigo])
    ads_estado      BIT      CONSTRAINT DF_ads_estado DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
    CONSTRAINT PK_ads_activo_documental_soporte_registro PRIMARY KEY CLUSTERED (ado_codigo, src_codigo),
    CONSTRAINT FK_ads_activo_documental FOREIGN KEY (ado_codigo) REFERENCES sgspi.activo_documental (ado_codigo),
    CONSTRAINT FK_ads_soporte_registro_catalogo FOREIGN KEY (src_codigo) REFERENCES sgspi.soporte_registro_catalogo (src_codigo)
);

CREATE NONCLUSTERED INDEX IX_ads_src_codigo
    ON sgspi.activo_documental_soporte_registro(src_codigo); -- [AP-18] Sin INCLUDE: ado_codigo ya es clave clustered

CREATE TABLE sgspi.activo_documental_medio_conservacion (
    ado_codigo      INT      NOT NULL, -- FK a [sgspi].[activo_documental]([ado_codigo])
    mcc_codigo      SMALLINT NOT NULL, -- FK a [sgspi].[medio_conservacion_catalogo]([mcc_codigo])
    adm_estado      BIT      CONSTRAINT DF_adm_estado DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
    CONSTRAINT PK_adm_activo_documental_medio_conservacion PRIMARY KEY CLUSTERED (ado_codigo, mcc_codigo),
    CONSTRAINT FK_adm_activo_documental FOREIGN KEY (ado_codigo) REFERENCES sgspi.activo_documental (ado_codigo),
    CONSTRAINT FK_adm_medio_conservacion_catalogo FOREIGN KEY (mcc_codigo) REFERENCES sgspi.medio_conservacion_catalogo (mcc_codigo)
);

CREATE NONCLUSTERED INDEX IX_adm_mcc_codigo
    ON sgspi.activo_documental_medio_conservacion(mcc_codigo); -- [AP-18] Sin INCLUDE: ado_codigo ya es clave clustered

CREATE TABLE sgspi.activo_documental_idioma (
    ado_codigo      INT      NOT NULL, -- FK a [sgspi].[activo_documental]([ado_codigo])
    idi_codigo      SMALLINT NOT NULL, -- FK a [sgspi].[idioma_catalogo]([idi_codigo])
    adi_estado      BIT      CONSTRAINT DF_adi_estado DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
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
    adf_estado      BIT      CONSTRAINT DF_adf_estado DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
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
    adu_estado      BIT CONSTRAINT DF_adu_estado DEFAULT 1 NOT NULL, -- [AP-17]
    CONSTRAINT PK_adu_activo_documental_unidad_productora PRIMARY KEY CLUSTERED (ado_codigo, upc_codigo),
    CONSTRAINT FK_adu_activo_documental FOREIGN KEY (ado_codigo) REFERENCES sgspi.activo_documental (ado_codigo),
    CONSTRAINT FK_adu_unidad_productora_cuadro_clasificacion_documental FOREIGN KEY (upc_codigo) REFERENCES sgspi.unidad_productora_cuadro_clasificacion_documental (upc_codigo)
);

CREATE NONCLUSTERED INDEX IX_adu_upc_codigo
    ON sgspi.activo_documental_unidad_productora(upc_codigo)
    INCLUDE(adu_estado);


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
    epr_estado                BIT            CONSTRAINT DF_epr_estado DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
    CONSTRAINT PK_epr_escala_probabilidad PRIMARY KEY CLUSTERED (epr_codigo),
    CONSTRAINT CK_epr_rango CHECK (epr_codigo BETWEEN 1 AND 5
                                   AND epr_codigo_letra IN ('A', 'B', 'C', 'D', 'E')),
    -- [AP-09] La letra es derivable del código numérico (5=A ... 1=E): se garantiza la coherencia entre ambas
    CONSTRAINT CK_epr_letra_coherente CHECK (ASCII(epr_codigo_letra) = 70 - epr_codigo)
);

CREATE UNIQUE NONCLUSTERED INDEX UX_epr_codigo_letra
    ON sgspi.escala_probabilidad(epr_codigo_letra) WHERE epr_estado = 1; -- [AP-22]

CREATE TABLE sgspi.escala_impacto (
    eim_codigo                     TINYINT         NOT NULL, -- 1=Insignificante, 2=Menor, 3=Moderado, 4=Mayor, 5=Catastrófico / Altamente beneficioso
    eim_nombre_impacto_negativo    NVARCHAR (30)   NOT NULL,
    eim_nombre_impacto_positivo    NVARCHAR (40)   NOT NULL,
    eim_descripcion_organizacional NVARCHAR (1000) NOT NULL,
    eim_descripcion_operativa      NVARCHAR (1000) NULL,
    eim_estado                     BIT             CONSTRAINT DF_eim_estado DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
    CONSTRAINT PK_eim_escala_impacto PRIMARY KEY CLUSTERED (eim_codigo),
    CONSTRAINT CK_eim_rango CHECK (eim_codigo BETWEEN 1 AND 5)
);

-- [AP-09] Catálogo de zonas de riesgo: reemplaza mvr_codigo_zona (código) + mvr_nivel_valoracion (nombre), dependencia transitiva
CREATE TABLE sgspi.zona_riesgo_catalogo (
    zrc_codigo       CHAR (1)      NOT NULL, -- 'B' (Bajo), 'M' (Moderado), 'A' (Alto), 'E' (Extremo)
    zrc_nombre_nivel NVARCHAR (30) NOT NULL, -- 'Riesgo Inferior', 'Riesgo Moderado', 'Riesgo Alto', 'Riesgo Extremo'
    zrc_orden        TINYINT       NOT NULL, -- 1 (menor severidad) .. 4 (mayor severidad)
    zrc_estado       BIT           CONSTRAINT DF_zrc_estado DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
    CONSTRAINT PK_zrc_zona_riesgo_catalogo PRIMARY KEY CLUSTERED (zrc_codigo)
);

CREATE UNIQUE NONCLUSTERED INDEX UX_zrc_nombre_nivel
    ON sgspi.zona_riesgo_catalogo(zrc_nombre_nivel) WHERE zrc_estado = 1; -- [AP-22]

CREATE UNIQUE NONCLUSTERED INDEX UX_zrc_orden
    ON sgspi.zona_riesgo_catalogo(zrc_orden) WHERE zrc_estado = 1; -- [AP-22]


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
    mvr_estado                            BIT            CONSTRAINT DF_mvr_estado DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
    CONSTRAINT PK_mvr_matriz_valoracion_riesgo PRIMARY KEY CLUSTERED (epr_codigo, eim_codigo),
    CONSTRAINT FK_mvr_escala_probabilidad FOREIGN KEY (epr_codigo) REFERENCES sgspi.escala_probabilidad (epr_codigo),
    CONSTRAINT FK_mvr_escala_impacto FOREIGN KEY (eim_codigo) REFERENCES sgspi.escala_impacto (eim_codigo),
    CONSTRAINT FK_mvr_zona_riesgo FOREIGN KEY (zrc_codigo) REFERENCES sgspi.zona_riesgo_catalogo (zrc_codigo) -- [AP-09] reemplaza CK_mvr_codigo_zona
);

CREATE UNIQUE NONCLUSTERED INDEX UX_mvr_codigo_posicion
    ON sgspi.matriz_valoracion_riesgo(mvr_codigo_posicion) WHERE mvr_estado = 1; -- [AP-22]

-- 5.2 [eia] Escenarios de Incertidumbre sobre Activos (Riesgos RA-XX y Oportunidades OA-XX)
CREATE TABLE sgspi.evento_incertidumbre_activo (
    eia_codigo                   INT                IDENTITY (1, 1) NOT NULL,
    pev_codigo                   SMALLINT           NOT NULL, -- FK a [sgspi].[periodo_vigencia]([pev_codigo])
    eia_numero_evento            SMALLINT           NOT NULL, -- [AP-09] Consecutivo por vigencia y naturaleza (1..9999)
    eia_identificador_evento     AS                 (CONVERT (NVARCHAR (15), CONCAT(CASE eia_naturaleza_evento WHEN N'RIESGO' THEN N'RA-' ELSE N'OA-' END, RIGHT(CONCAT(N'000', eia_numero_evento), CASE WHEN eia_numero_evento < 100 THEN 2 WHEN eia_numero_evento < 1000 THEN 3 ELSE 4 END)))) PERSISTED, -- [AP-09] 'RA-01'..'RA-9999', 'OA-01'..'OA-9999': se calcula, no se digita
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
    eia_fase_registro            NVARCHAR (30)      CONSTRAINT DF_eia_fase_registro DEFAULT N'BORRADOR' NOT NULL, -- [AP-17]
    efc_dominio                  AS                 (CONVERT (NVARCHAR (10), N'EIA')) PERSISTED, -- [AP-05] dominio constante para la FK al catálogo de estados
    per_codigo_creador           INT                NOT NULL, -- FK a [dbo].[persona]([per_codigo])
    per_codigo_validador_lider   INT                NULL, -- FK a [dbo].[persona]([per_codigo])
    per_codigo_revisor_sgspi     INT                NULL, -- FK a [dbo].[persona]([per_codigo])
    per_codigo_aprobador_comite  INT                NULL, -- FK a [dbo].[persona]([per_codigo])
    eia_fecha_creacion           DATETIMEOFFSET (0) CONSTRAINT DF_eia_fecha_creacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17]
    eia_fecha_actualizacion      DATETIMEOFFSET (0) CONSTRAINT DF_eia_fecha_actualizacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-11] La mantiene TR_eia_integridad_y_actualizacion
    eia_estado                   BIT                CONSTRAINT DF_eia_estado DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
    eia_version                  ROWVERSION         NOT NULL, -- [AP-24] Control de concurrencia optimista
    CONSTRAINT PK_eia_evento_incertidumbre_activo PRIMARY KEY CLUSTERED (eia_codigo),
    CONSTRAINT UQ_eia_codigo_naturaleza UNIQUE (eia_codigo, eia_naturaleza_evento) WITH (DATA_COMPRESSION = ROW), -- [AP-06] destino de la FK compuesta de plt
    CONSTRAINT FK_eia_periodo_vigencia FOREIGN KEY (pev_codigo) REFERENCES sgspi.periodo_vigencia (pev_codigo),
    CONSTRAINT FK_eia_proceso_institucional FOREIGN KEY (pri_codigo) REFERENCES sgspi.proceso_institucional (pri_codigo),
    CONSTRAINT FK_eia_activo_primario FOREIGN KEY (aci_codigo_primario) REFERENCES sgspi.activo_informacion (aci_codigo),
    CONSTRAINT FK_eia_activo_soporte FOREIGN KEY (aci_codigo_soporte) REFERENCES sgspi.activo_informacion (aci_codigo),
    CONSTRAINT FK_eia_activo_proceso FOREIGN KEY (aci_codigo_primario, pri_codigo) REFERENCES sgspi.activo_informacion_proceso_institucional (aci_codigo, pri_codigo), -- [AP-06] D4: el riesgo está en un proceso que usa su activo primario
    CONSTRAINT FK_eia_tipo_activo_componente FOREIGN KEY (tac_codigo_componente, tac_nivel_componente) REFERENCES sgspi.tipo_activo_catalogo (tac_codigo, tac_nivel_taxonomia), -- [AP-08]
    CONSTRAINT FK_eia_valoracion_inherente FOREIGN KEY (epr_codigo_inherente, eim_codigo_inherente) REFERENCES sgspi.matriz_valoracion_riesgo (epr_codigo, eim_codigo),
    CONSTRAINT FK_eia_estado_flujo FOREIGN KEY (efc_dominio, eia_fase_registro) REFERENCES sgspi.estado_flujo_catalogo (efc_dominio, efc_identificador), -- [AP-05] reemplaza CK_eia_estado_maquina
    -- RN-RSG-01: Exclusión Mutua Riesgo (RA-) vs Oportunidad (OA-); el prefijo y los dígitos los calcula eia_identificador_evento [AP-09]
    CONSTRAINT CK_eia_naturaleza_evento CHECK (eia_naturaleza_evento IN (N'RIESGO', N'OPORTUNIDAD')),
    CONSTRAINT CK_eia_numero_evento CHECK (eia_numero_evento BETWEEN 1 AND 9999),
    -- [AP-15] [B4] Segregación de funciones ISO 27001 A.5.3: todas las firmas (creador, validador, revisor, comité) deben ser personas distintas entre sí
    CONSTRAINT CK_eia_sod_firmas CHECK ((per_codigo_validador_lider IS NULL
                                         OR per_codigo_validador_lider <> per_codigo_creador)
                                        AND (per_codigo_revisor_sgspi IS NULL
                                             OR (per_codigo_revisor_sgspi <> per_codigo_creador
                                                 AND (per_codigo_validador_lider IS NULL
                                                      OR per_codigo_revisor_sgspi <> per_codigo_validador_lider)))
                                        AND (per_codigo_aprobador_comite IS NULL
                                             OR (per_codigo_aprobador_comite <> per_codigo_creador
                                                 AND (per_codigo_validador_lider IS NULL
                                                      OR per_codigo_aprobador_comite <> per_codigo_validador_lider)
                                                 AND (per_codigo_revisor_sgspi IS NULL
                                                      OR per_codigo_aprobador_comite <> per_codigo_revisor_sgspi)))),
    CONSTRAINT CK_eia_activos_distintos CHECK (aci_codigo_soporte <> aci_codigo_primario),
    CONSTRAINT CK_eia_textos_no_vacios CHECK (LEN(TRIM(eia_fuente_generadora)) > 0
                                              AND LEN(TRIM(eia_condicion_vulnerabilidad)) > 0
                                              AND LEN(TRIM(eia_efecto_consecuencia)) > 0
                                              AND LEN(TRIM(eia_escenario_operacional)) > 0) -- [B4]
)
WITH (DATA_COMPRESSION = ROW);

CREATE UNIQUE NONCLUSTERED INDEX UX_eia_vigencia_naturaleza_numero
    ON sgspi.evento_incertidumbre_activo(pev_codigo, eia_naturaleza_evento, eia_numero_evento) WHERE eia_estado = 1 WITH (DATA_COMPRESSION = ROW); -- [AP-09] [AP-22]

CREATE NONCLUSTERED INDEX IX_eia_pev_estado
    ON sgspi.evento_incertidumbre_activo(pev_codigo, eia_estado) WITH (DATA_COMPRESSION = ROW); -- [D2] soporte vigencia + filtro estado

CREATE NONCLUSTERED INDEX IX_eia_pri_codigo
    ON sgspi.evento_incertidumbre_activo(pri_codigo) WITH (DATA_COMPRESSION = ROW);

CREATE NONCLUSTERED INDEX IX_eia_aci_codigo_primario -- [AP-18] sirve a FK_eia_activo_primario y a FK_eia_activo_proceso (D4)
    ON sgspi.evento_incertidumbre_activo(aci_codigo_primario, pri_codigo) WITH (DATA_COMPRESSION = ROW);

CREATE NONCLUSTERED INDEX IX_eia_aci_codigo_soporte
    ON sgspi.evento_incertidumbre_activo(aci_codigo_soporte) WITH (DATA_COMPRESSION = ROW);







CREATE NONCLUSTERED INDEX IX_eia_fase_estado
    ON sgspi.evento_incertidumbre_activo(eia_fase_registro, eia_estado) WITH (DATA_COMPRESSION = ROW);

-- 5.3 [etc] y [plt] Catálogo Extensible de Estrategias y Plan de Tratamiento de Riesgos y Oportunidades
CREATE TABLE sgspi.estrategia_tratamiento_catalogo (
    etc_codigo               SMALLINT       IDENTITY (1, 1) NOT NULL,
    etc_nombre_estrategia    NVARCHAR (80)  NOT NULL, -- Ej: 'Mitigar o reducir', 'Compartir o transferir el riesgo', 'Evitar el riesgo', 'Potenciar o explotar la oportunidad'
    etc_naturaleza_aplicable NVARCHAR (15)  NOT NULL, -- 'RIESGO', 'OPORTUNIDAD'
    etc_descripcion          NVARCHAR (255) NULL,
    etc_estado               BIT            CONSTRAINT DF_etc_estado DEFAULT 1 NOT NULL, -- [AP-17]
    CONSTRAINT PK_etc_estrategia_tratamiento_catalogo PRIMARY KEY CLUSTERED (etc_codigo),
    CONSTRAINT UQ_etc_codigo_naturaleza UNIQUE (etc_codigo, etc_naturaleza_aplicable), -- [AP-06] destino de la FK compuesta de plt
    CONSTRAINT CK_etc_nombre_no_vacio CHECK (LEN(TRIM(etc_nombre_estrategia)) > 0),
    CONSTRAINT CK_etc_naturaleza_aplicable CHECK (etc_naturaleza_aplicable IN (N'RIESGO', N'OPORTUNIDAD'))
);

CREATE UNIQUE NONCLUSTERED INDEX UX_etc_nombre_estrategia
    ON sgspi.estrategia_tratamiento_catalogo(etc_nombre_estrategia) WHERE etc_estado = 1; -- [AP-22]

CREATE TABLE sgspi.plan_tratamiento (
    plt_codigo                      INT                                                  IDENTITY (1, 1) NOT NULL,
    eia_codigo                      INT                                                  NOT NULL, -- FK a [sgspi].[evento_incertidumbre_activo]([eia_codigo])
    plt_naturaleza_evento           NVARCHAR (15)                                        NOT NULL, -- [AP-06] 'RIESGO'/'OPORTUNIDAD': debe coincidir con el evento y con la estrategia (FK compuestas)
    etc_codigo                      SMALLINT                                             NOT NULL, -- FK a [sgspi].[estrategia_tratamiento_catalogo]([etc_codigo])
    plt_justificacion_estrategia    NVARCHAR (1000)                                      NOT NULL,
    -- Valoración Residual Esperada (Meta)
    epr_codigo_residual_meta        TINYINT                                              NOT NULL,
    eim_codigo_residual_meta        TINYINT                                              NOT NULL,
    plt_fecha_inicio                DATE                                                 NOT NULL,
    plt_fecha_fin                   DATE                                                 NOT NULL,
    plt_recursos_humanos_tecnicos   NVARCHAR (500)                                       NOT NULL,
    plt_recursos_economicos_desc    NVARCHAR (500)                                       NOT NULL,
    plt_presupuesto_estimado_cop    DECIMAL (18, 2) NULL, -- A1: protegido por DENY SELECT de columna (reemplaza DDM + UNMASK global)
    plt_restricciones_limitaciones  NVARCHAR (500)                                       NULL,
    plt_nombre_indicador_kpi        NVARCHAR (255)                                       NOT NULL,
    plt_unidad_medida_kpi           NVARCHAR (30)                                        CONSTRAINT DF_plt_unidad_medida_kpi DEFAULT N'PORCENTAJE' NOT NULL, -- [AP-17] Ej: 'PORCENTAJE', 'CANTIDAD', 'DIAS', 'HORAS'
    plt_meta_indicador_kpi          DECIMAL (10, 2)                                      NOT NULL,
    plt_valor_alcanzado_kpi         DECIMAL (10, 2)                                      NULL,
    -- [AP-16] DECIMAL (15, 2) evita desborde (8115) con metas pequeñas y valores alcanzados altos
    plt_porcentaje_cumplimiento_kpi AS                                                   (CASE WHEN plt_meta_indicador_kpi > 0
                                                                                                    AND plt_valor_alcanzado_kpi IS NOT NULL THEN CAST (ROUND((plt_valor_alcanzado_kpi / plt_meta_indicador_kpi) * 100.0, 2) AS DECIMAL (15, 2)) ELSE NULL END) PERSISTED,
    plt_es_tratamiento_eficaz       BIT                                                  NULL,
    plt_dictamen_eficacia           NVARCHAR (1000)                                      NULL,
    per_codigo_evaluador            INT                                                  NULL, -- FK a [dbo].[persona]([per_codigo])
    plt_fecha_evaluacion_eficacia   DATETIMEOFFSET (0)                                   NULL, -- [AP-12]
    plt_fecha_creacion              DATETIMEOFFSET (0)                                   CONSTRAINT DF_plt_fecha_creacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17]
    plt_fecha_actualizacion         DATETIMEOFFSET (0)                                   CONSTRAINT DF_plt_fecha_actualizacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17]
    plt_estado                      BIT                                                  CONSTRAINT DF_plt_estado DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
    plt_version                     ROWVERSION                                           NOT NULL, -- [AP-24] Control de concurrencia optimista
    CONSTRAINT PK_plt_plan_tratamiento PRIMARY KEY CLUSTERED (plt_codigo),
    -- [AP-06] FK compuestas: la naturaleza del plan coincide con la del evento y con la de la estrategia
    CONSTRAINT FK_plt_evento_incertidumbre FOREIGN KEY (eia_codigo, plt_naturaleza_evento) REFERENCES sgspi.evento_incertidumbre_activo (eia_codigo, eia_naturaleza_evento),
    CONSTRAINT FK_plt_estrategia_tratamiento FOREIGN KEY (etc_codigo, plt_naturaleza_evento) REFERENCES sgspi.estrategia_tratamiento_catalogo (etc_codigo, etc_naturaleza_aplicable),
    CONSTRAINT FK_plt_valoracion_meta FOREIGN KEY (epr_codigo_residual_meta, eim_codigo_residual_meta) REFERENCES sgspi.matriz_valoracion_riesgo (epr_codigo, eim_codigo),
    CONSTRAINT CK_plt_naturaleza_evento CHECK (plt_naturaleza_evento IN (N'RIESGO', N'OPORTUNIDAD')), -- [AP-06]
    CONSTRAINT CK_plt_textos_no_vacios CHECK (LEN(TRIM(plt_justificacion_estrategia)) > 0
                                              AND LEN(TRIM(plt_recursos_humanos_tecnicos)) > 0
                                              AND LEN(TRIM(plt_recursos_economicos_desc)) > 0
                                              AND LEN(TRIM(plt_nombre_indicador_kpi)) > 0), -- [B4]
    CONSTRAINT CK_plt_presupuesto_no_negativo CHECK (plt_presupuesto_estimado_cop IS NULL
                                                     OR plt_presupuesto_estimado_cop >= 0),
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
)
WITH (DATA_COMPRESSION = ROW);

-- [AP-22] Un solo plan activo por evento: permite crear el plan correcto tras anular uno por error (plt_estado = 0)
CREATE UNIQUE NONCLUSTERED INDEX UX_plt_evento_activo
    ON sgspi.plan_tratamiento(eia_codigo) WHERE plt_estado = 1 WITH (DATA_COMPRESSION = ROW);

CREATE NONCLUSTERED INDEX IX_plt_eia_codigo_naturaleza
    ON sgspi.plan_tratamiento(eia_codigo, plt_naturaleza_evento)
    INCLUDE(plt_estado, epr_codigo_residual_meta, eim_codigo_residual_meta, plt_es_tratamiento_eficaz)
    WITH (DATA_COMPRESSION = ROW);

CREATE NONCLUSTERED INDEX IX_plt_etc_codigo
    ON sgspi.plan_tratamiento(etc_codigo, plt_naturaleza_evento) WITH (DATA_COMPRESSION = ROW); -- [AP-18] cubre la FK compuesta a etc

CREATE NONCLUSTERED INDEX IX_plt_valoracion_residual_meta
    ON sgspi.plan_tratamiento(epr_codigo_residual_meta, eim_codigo_residual_meta) WITH (DATA_COMPRESSION = ROW);


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
    act_fase_actividad        NVARCHAR (30)      CONSTRAINT DF_act_fase_actividad DEFAULT N'PENDIENTE' NOT NULL, -- [AP-05] [AP-17] ampliada de 20 a 30
    efc_dominio               AS                 (CONVERT (NVARCHAR (10), N'ACT')) PERSISTED, -- [AP-05] dominio constante para la FK al catálogo de estados
    act_fecha_creacion        DATETIMEOFFSET (0) CONSTRAINT DF_act_fecha_creacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17]
    act_fecha_actualizacion   DATETIMEOFFSET (0) CONSTRAINT DF_act_fecha_actualizacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17]
    act_estado                BIT                CONSTRAINT DF_act_estado DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
    act_version               ROWVERSION         NOT NULL, -- [AP-24] Control de concurrencia optimista
    CONSTRAINT PK_act_actividad_tratamiento PRIMARY KEY CLUSTERED (act_codigo),
    CONSTRAINT FK_act_plan_tratamiento FOREIGN KEY (plt_codigo) REFERENCES sgspi.plan_tratamiento (plt_codigo),
    CONSTRAINT FK_act_estado_flujo FOREIGN KEY (efc_dominio, act_fase_actividad) REFERENCES sgspi.estado_flujo_catalogo (efc_dominio, efc_identificador), -- [AP-05] reemplaza CK_act_fase_actividad
    CONSTRAINT CK_act_numero_orden_positivo CHECK (act_numero_orden >= 1), -- [AP-14]
    CONSTRAINT CK_act_descripcion_no_vacia CHECK (LEN(TRIM(act_descripcion_actividad)) > 0), -- [B4]
    CONSTRAINT CK_act_porcentaje_avance CHECK (act_porcentaje_avance BETWEEN 0 AND 100),
    -- [AP-16] Una actividad COMPLETADA debe estar al 100 % de avance
    CONSTRAINT CK_act_completada_al_100 CHECK (act_fase_actividad <> N'COMPLETADA'
                                               OR act_porcentaje_avance = 100),
    -- Fuera de PENDIENTE la actividad exige cargo y UAA responsables
    CONSTRAINT CK_act_responsable CHECK (act_fase_actividad = N'PENDIENTE'
                                         OR (car_codigo IS NOT NULL
                                             AND uaa_codigo IS NOT NULL))
)
WITH (DATA_COMPRESSION = ROW);

CREATE UNIQUE NONCLUSTERED INDEX UX_act_plan_orden
    ON sgspi.actividad_tratamiento(plt_codigo, act_numero_orden) WHERE act_estado = 1 WITH (DATA_COMPRESSION = ROW); -- [AP-14] [AP-22]

CREATE NONCLUSTERED INDEX IX_act_plt_codigo
    ON sgspi.actividad_tratamiento(plt_codigo, act_estado, act_fase_actividad) WITH (DATA_COMPRESSION = ROW); -- [D2] cubriente para TR_eia

CREATE NONCLUSTERED INDEX IX_act_car_codigo
    ON sgspi.actividad_tratamiento(car_codigo) WITH (DATA_COMPRESSION = ROW);

CREATE NONCLUSTERED INDEX IX_act_uaa_codigo
    ON sgspi.actividad_tratamiento(uaa_codigo) WITH (DATA_COMPRESSION = ROW);

CREATE NONCLUSTERED INDEX IX_act_fase_estado
    ON sgspi.actividad_tratamiento(act_fase_actividad, act_estado) WITH (DATA_COMPRESSION = ROW);

CREATE TABLE sgspi.seguimiento_actividad (
    sga_codigo                       INT                IDENTITY (1, 1) NOT NULL,
    act_codigo                       INT                NOT NULL, -- FK a [sgspi].[actividad_tratamiento]([act_codigo])
    per_codigo                       INT                NOT NULL, -- FK a [dbo].[persona]([per_codigo])
    sga_fecha_registro               DATETIMEOFFSET (0) CONSTRAINT DF_sga_fecha_registro DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17]
    sga_porcentaje_reportado         TINYINT            NOT NULL,
    sga_descripcion_avance           NVARCHAR (1000)    NOT NULL,
    sga_nombre_archivo_evidencia     NVARCHAR (255)     NULL,
    sga_uri_almacenamiento_evidencia NVARCHAR (500)     NULL, -- A1: acceso controlado por RLS y RBAC (sin DDM/UNMASK global)
    sga_hash_sha256_evidencia        CHAR (64)          NULL,
    sga_estado                       BIT                CONSTRAINT DF_sga_estado DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
    CONSTRAINT PK_sga_seguimiento_actividad PRIMARY KEY CLUSTERED (sga_codigo),
    CONSTRAINT FK_sga_actividad_tratamiento FOREIGN KEY (act_codigo) REFERENCES sgspi.actividad_tratamiento (act_codigo),
    CONSTRAINT CK_sga_porcentaje_reportado CHECK (sga_porcentaje_reportado BETWEEN 0 AND 100),
    CONSTRAINT CK_sga_descripcion_no_vacia CHECK (LEN(TRIM(sga_descripcion_avance)) > 0), -- [B4]
    -- [AP-16] La evidencia se registra completa (nombre, URI y hash) o no se registra
    CONSTRAINT CK_sga_evidencia_completa CHECK ((sga_nombre_archivo_evidencia IS NULL
                                                 AND sga_uri_almacenamiento_evidencia IS NULL
                                                 AND sga_hash_sha256_evidencia IS NULL)
                                                OR (sga_nombre_archivo_evidencia IS NOT NULL
                                                    AND sga_uri_almacenamiento_evidencia IS NOT NULL
                                                    AND sga_hash_sha256_evidencia IS NOT NULL)),
    -- A5: Evita URIs vacías, rutas UNC (\\), esquemas inseguros (http://), traversal (.. / %2e / %2f / %5c), barras invertidas, espacios y caracteres de control
    CONSTRAINT CK_sga_uri_evidencia CHECK (sga_uri_almacenamiento_evidencia IS NULL
                                           OR ((sga_uri_almacenamiento_evidencia LIKE N'https://_%'
                                                OR sga_uri_almacenamiento_evidencia LIKE N'/sgspi/_%')
                                               AND sga_uri_almacenamiento_evidencia NOT LIKE N'%..%'
                                               AND LOWER(sga_uri_almacenamiento_evidencia) NOT LIKE N'%[%]2e%'
                                               AND LOWER(sga_uri_almacenamiento_evidencia) NOT LIKE N'%[%]2f%'
                                               AND LOWER(sga_uri_almacenamiento_evidencia) NOT LIKE N'%[%]5c%'
                                               AND CHARINDEX(N'\', sga_uri_almacenamiento_evidencia) = 0
                                               AND CHARINDEX(N' ', sga_uri_almacenamiento_evidencia) = 0
                                               AND sga_uri_almacenamiento_evidencia COLLATE Latin1_General_BIN2 NOT LIKE N'%[' + NCHAR(0) + N'-' + NCHAR(31) + N']%')),
    -- [AP-16] Formato del hash SHA-256: 64 caracteres hexadecimales en minúsculas
    CONSTRAINT CK_sga_hash_formato CHECK (sga_hash_sha256_evidencia IS NULL
                                          OR (LEN(sga_hash_sha256_evidencia) = 64
                                              AND sga_hash_sha256_evidencia COLLATE Latin1_General_BIN2 NOT LIKE '%[^0-9a-f]%'))
)
WITH (DATA_COMPRESSION = ROW);

CREATE NONCLUSTERED INDEX IX_sga_act_codigo
    ON sgspi.seguimiento_actividad(act_codigo, sga_estado, sga_codigo DESC)
    INCLUDE(sga_porcentaje_reportado)
    WITH (DATA_COMPRESSION = ROW);

CREATE NONCLUSTERED INDEX IX_sga_per_codigo
    ON sgspi.seguimiento_actividad(per_codigo) WITH (DATA_COMPRESSION = ROW);

-- 5.5 [enc] y [crn] Catálogo Extensible de Estándares Normativos y Controles de Referencia (ISO/IEC 27001:2022 [93], ISO/IEC 27701:2025 [71], etc.)
CREATE TABLE sgspi.estandar_normativo_catalogo (
    enc_codigo        SMALLINT       IDENTITY (1, 1) NOT NULL,
    enc_identificador NVARCHAR (50)  NOT NULL, -- Ej: 'ISO/IEC 27001:2022', 'ISO/IEC 27701:2025', 'ISO/IEC 27002:2022', 'ISO/IEC 42001:2023'
    enc_familia_norma NVARCHAR (20)  NOT NULL, -- [AP-13] Ej: 'ISO27001', 'ISO27701', 'ISO27002', 'NIST_CSF'; una edición activa por familia
    enc_nombre        NVARCHAR (200) NOT NULL,
    enc_organismo     NVARCHAR (100) NULL, -- Ej: 'ISO/IEC', 'NIST', 'MinTIC'
    enc_anio_edicion  SMALLINT       NULL,
    enc_estado        BIT            CONSTRAINT DF_enc_estado DEFAULT 1 NOT NULL, -- [AP-17]
    CONSTRAINT PK_enc_estandar_normativo_catalogo PRIMARY KEY CLUSTERED (enc_codigo),
    CONSTRAINT CK_enc_identificador_no_vacio CHECK (LEN(TRIM(enc_identificador)) > 0),
    CONSTRAINT CK_enc_familia_norma_no_vacia CHECK (LEN(TRIM(enc_familia_norma)) > 0), -- [AP-13]
    CONSTRAINT CK_enc_anio_edicion CHECK (enc_anio_edicion IS NULL
                                          OR enc_anio_edicion BETWEEN 1970 AND 2100)
);

CREATE UNIQUE NONCLUSTERED INDEX UX_enc_identificador
    ON sgspi.estandar_normativo_catalogo(enc_identificador) WHERE enc_estado = 1; -- [AP-22]

-- [AP-13] Una sola edición activa por familia de norma (reemplaza filtros por cadena de edición en vistas)
CREATE UNIQUE NONCLUSTERED INDEX UX_enc_familia_activa
    ON sgspi.estandar_normativo_catalogo(enc_familia_norma) WHERE enc_estado = 1;

-- [AP-07] Se eliminan crn_tipo_control, crn_capacidad_operacional y crn_dominio_seguridad (atributos multivaluados -> aac/cra)
CREATE TABLE sgspi.control_referencia_normativa (
    crn_codigo                SMALLINT        IDENTITY (1, 1) NOT NULL,
    enc_codigo                SMALLINT        NOT NULL, -- FK a [sgspi].[estandar_normativo_catalogo]([enc_codigo])
    crn_rol_privacidad_pii    NVARCHAR (20)   NULL, -- 'CONTROLADOR', 'PROCESADOR', 'COMUN' (NULL cuando el estándar no define rol PII, ej. ISO/IEC 27001:2022)
    crn_identificador_control NVARCHAR (20)   NOT NULL, -- 'A.5.1'..'A.8.34', 'A.1.2.2'..'A.3.31'
    crn_nombre_control        NVARCHAR (200)  NOT NULL,
    crn_objetivo_requisito    NVARCHAR (1500) NOT NULL,
    crn_estado                BIT             CONSTRAINT DF_crn_estado DEFAULT 1 NOT NULL, -- [AP-17]
    CONSTRAINT PK_crn_control_referencia_normativa PRIMARY KEY CLUSTERED (crn_codigo),
    CONSTRAINT FK_crn_estandar_normativo FOREIGN KEY (enc_codigo) REFERENCES sgspi.estandar_normativo_catalogo (enc_codigo),
    CONSTRAINT CK_crn_rol_privacidad_pii CHECK (crn_rol_privacidad_pii IS NULL
                                                OR crn_rol_privacidad_pii IN (N'CONTROLADOR', N'PROCESADOR', N'COMUN')),
    CONSTRAINT CK_crn_textos_no_vacios CHECK (LEN(TRIM(crn_identificador_control)) > 0
                                              AND LEN(TRIM(crn_nombre_control)) > 0
                                              AND LEN(TRIM(crn_objetivo_requisito)) > 0) -- [B4]
);

CREATE UNIQUE NONCLUSTERED INDEX UX_crn_estandar_identificador
    ON sgspi.control_referencia_normativa(enc_codigo, crn_identificador_control) WHERE crn_estado = 1; -- [AP-22]

CREATE NONCLUSTERED INDEX IX_crn_enc_codigo
    ON sgspi.control_referencia_normativa(enc_codigo); -- soporte no filtrado de FK_crn_estandar_normativo

-- 5.6 [aac], [cra] Atributos de Controles Normativos (ISO/IEC 27002:2022 define 5 tipos de atributo multivaluados por control:
--     tipo de control, propiedades de seguridad de la información, conceptos de ciberseguridad, capacidades operativas y dominios de seguridad).
--     [AP-07] Un catálogo único de atributos y una tabla N:M reemplazan las columnas de texto multivaluado y las tablas cps/ccc.
CREATE TABLE sgspi.atributo_control_catalogo (
    aac_codigo        SMALLINT      IDENTITY (1, 1) NOT NULL,
    aac_tipo_atributo NVARCHAR (30) NOT NULL, -- 'TIPO_CONTROL', 'PROPIEDAD_SEGURIDAD', 'CONCEPTO_CIBERSEGURIDAD', 'CAPACIDAD_OPERACIONAL', 'DOMINIO_SEGURIDAD'
    aac_valor         NVARCHAR (60) NOT NULL, -- Ej: 'Preventivo', 'Confidencialidad', 'Proteger', 'Gobernanza', 'Protección'
    aac_estado        BIT           CONSTRAINT DF_aac_estado DEFAULT 1 NOT NULL, -- [AP-17]
    CONSTRAINT PK_aac_atributo_control_catalogo PRIMARY KEY CLUSTERED (aac_codigo),
    CONSTRAINT CK_aac_tipo_atributo CHECK (aac_tipo_atributo IN (N'TIPO_CONTROL', N'PROPIEDAD_SEGURIDAD', N'CONCEPTO_CIBERSEGURIDAD', N'CAPACIDAD_OPERACIONAL', N'DOMINIO_SEGURIDAD')),
    CONSTRAINT CK_aac_valor_no_vacio CHECK (LEN(TRIM(aac_valor)) > 0)
);

CREATE UNIQUE NONCLUSTERED INDEX UX_aac_tipo_valor
    ON sgspi.atributo_control_catalogo(aac_tipo_atributo, aac_valor) WHERE aac_estado = 1; -- [AP-22]

CREATE TABLE sgspi.control_referencia_normativa_atributo (
    crn_codigo      SMALLINT NOT NULL, -- FK a [sgspi].[control_referencia_normativa]([crn_codigo])
    aac_codigo      SMALLINT NOT NULL, -- FK a [sgspi].[atributo_control_catalogo]([aac_codigo])
    cra_estado      BIT      CONSTRAINT DF_cra_estado DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
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
    ptc_estado      BIT      CONSTRAINT DF_ptc_estado DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
    CONSTRAINT PK_ptc_plan_tratamiento_control_referencia_normativa PRIMARY KEY CLUSTERED (plt_codigo, crn_codigo),
    CONSTRAINT FK_ptc_plan_tratamiento FOREIGN KEY (plt_codigo) REFERENCES sgspi.plan_tratamiento (plt_codigo),
    CONSTRAINT FK_ptc_control_referencia FOREIGN KEY (crn_codigo) REFERENCES sgspi.control_referencia_normativa (crn_codigo)
);

CREATE NONCLUSTERED INDEX IX_ptc_crn_codigo
    ON sgspi.plan_tratamiento_control_referencia_normativa(crn_codigo);

-- 5.8 [eac] Declaración de Aplicabilidad (SoA) y Evaluación de Cumplimiento por Vigencia
CREATE TABLE sgspi.evaluacion_aplicabilidad_control (
    eac_codigo                      INT                                                  IDENTITY (1, 1) NOT NULL,
    pev_codigo                      SMALLINT                                             NOT NULL, -- FK a [sgspi].[periodo_vigencia]([pev_codigo])
    crn_codigo                      SMALLINT                                             NOT NULL, -- FK a [sgspi].[control_referencia_normativa]([crn_codigo])
    eac_es_aplicable                BIT                                                  CONSTRAINT DF_eac_es_aplicable DEFAULT 1 NOT NULL, -- [AP-17]
    eac_justificacion_aplicabilidad NVARCHAR (1000)                                      NULL,
    eac_documento_soporte_normativo NVARCHAR (500)                                       NULL,
    car_codigo                      INT                                                  NULL, -- FK a [dbo].[cargo]([car_codigo])
    pdc_codigo                      SMALLINT                                             NULL, -- [AP-08] FK a [sgspi].[periodicidad_catalogo]([pdc_codigo]): frecuencia de revisión (NULL cuando eac_es_aplicable = 0)
    eac_evidencia_objetiva_esperada NVARCHAR (500)                                       NULL,
    eac_fase_implementacion         NVARCHAR (20)                                        NULL, -- 'CUMPLE', 'CUMPLE_PARCIAL', 'NO_CUMPLE' (NULL cuando eac_es_aplicable = 0)
    eac_observaciones_auditoria     NVARCHAR (1000) NULL, -- A1: protegido por DENY SELECT de columna (reemplaza DDM + UNMASK global)
    eac_fecha_creacion              DATETIMEOFFSET (0)                                   CONSTRAINT DF_eac_fecha_creacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-12] [AP-17]
    eac_fecha_actualizacion         DATETIMEOFFSET (0)                                   CONSTRAINT DF_eac_fecha_actualizacion DEFAULT SYSDATETIMEOFFSET() NOT NULL, -- [AP-11] La mantiene TR_eac_integridad_y_actualizacion
    eac_estado                      BIT                                                  CONSTRAINT DF_eac_estado DEFAULT 1 NOT NULL, -- [AP-22] Borrado lógico: 1 = activo, 0 = inactivo
    eac_version                     ROWVERSION                                           NOT NULL, -- [AP-24] Control de concurrencia optimista
    CONSTRAINT PK_eac_evaluacion_aplicabilidad_control PRIMARY KEY CLUSTERED (eac_codigo),
    CONSTRAINT FK_eac_periodo_vigencia FOREIGN KEY (pev_codigo) REFERENCES sgspi.periodo_vigencia (pev_codigo),
    CONSTRAINT FK_eac_control_referencia FOREIGN KEY (crn_codigo) REFERENCES sgspi.control_referencia_normativa (crn_codigo),
    CONSTRAINT FK_eac_periodicidad FOREIGN KEY (pdc_codigo) REFERENCES sgspi.periodicidad_catalogo (pdc_codigo), -- [AP-08]
    CONSTRAINT CK_eac_fase_implementacion CHECK (eac_fase_implementacion IS NULL
                                                   OR eac_fase_implementacion IN (N'CUMPLE', N'CUMPLE_PARCIAL', N'NO_CUMPLE')),
    -- Coherencia entre aplicabilidad (BIT) y estado de implementación (sin valor centinela 'NO_APLICA'); un control aplicable tiene responsable y frecuencia
    CONSTRAINT CK_eac_coherencia_aplicabilidad CHECK ((eac_es_aplicable = 1
                                                       AND eac_fase_implementacion IS NOT NULL
                                                       AND car_codigo IS NOT NULL
                                                       AND pdc_codigo IS NOT NULL)
                                                      OR (eac_es_aplicable = 0
                                                          AND eac_fase_implementacion IS NULL
                                                          AND pdc_codigo IS NULL
                                                          AND LEN(TRIM(ISNULL(eac_justificacion_aplicabilidad, N''))) > 0)),
    -- RN-SOA-01: Un control NO puede marcarse como CUMPLE si el documento soporte o la evidencia esperada están vacíos o dicen 'PENDIENTE'
    CONSTRAINT CK_eac_cumple_requiere_evidencia CHECK (eac_fase_implementacion IS NULL
                                                       OR eac_fase_implementacion <> N'CUMPLE'
                                                       OR (LEN(TRIM(ISNULL(eac_documento_soporte_normativo, N''))) > 0
                                                           AND UPPER(TRIM(ISNULL(eac_documento_soporte_normativo, N''))) <> N'PENDIENTE'
                                                           AND LEN(TRIM(ISNULL(eac_evidencia_objetiva_esperada, N''))) > 0
                                                           AND UPPER(TRIM(ISNULL(eac_evidencia_objetiva_esperada, N''))) <> N'PENDIENTE'))
)
WITH (DATA_COMPRESSION = ROW);

CREATE UNIQUE NONCLUSTERED INDEX UX_eac_vigencia_control
    ON sgspi.evaluacion_aplicabilidad_control(pev_codigo, crn_codigo) WHERE eac_estado = 1 WITH (DATA_COMPRESSION = ROW); -- [AP-22]

CREATE NONCLUSTERED INDEX IX_eac_pev_codigo
    ON sgspi.evaluacion_aplicabilidad_control(pev_codigo) WITH (DATA_COMPRESSION = ROW); -- soporte no filtrado de FK_eac_periodo_vigencia

CREATE NONCLUSTERED INDEX IX_eac_crn_codigo
    ON sgspi.evaluacion_aplicabilidad_control(crn_codigo) WITH (DATA_COMPRESSION = ROW);

CREATE NONCLUSTERED INDEX IX_eac_car_codigo
    ON sgspi.evaluacion_aplicabilidad_control(car_codigo) WITH (DATA_COMPRESSION = ROW);

CREATE NONCLUSTERED INDEX IX_eac_pdc_codigo -- [AP-08] índice para la FK
    ON sgspi.evaluacion_aplicabilidad_control(pdc_codigo) WITH (DATA_COMPRESSION = ROW);


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
/*==================================================================================================
5.9 TABLAS DE AUDITORÍA [AP-01]: una sgspi.aud_<tabla> por cada tabla del esquema (acrónimos en la cabecera)
Cada fila guarda el tipo de operación (<aud>_operacion: 'I' = fila creada con sus valores nuevos; 'U' = versión
RESULTANTE after-image de una fila modificada [C2]), quién hizo la operación (per_codigo de ORIGINAL_LOGIN()) y cuándo. Las llena el
trigger de la tabla de origen: TR_<acr>_auditoria (5.10.9c), los 8 TR_<acr>_integridad_y_actualizacion (acf, rpi,
aci, ado, eia, plt, act, eac) o, en sga, TR_sga_inmutabilidad (UPDATE, 'U') y TR_sga_sincronizar_avance (INSERT, 'I'),
para no registrar dos veces los UPDATE internos de los triggers.
Columnas: las de origen menos las calculadas, <acr>_version y <acr>_fecha_creacion; la clave conserva su nombre (FK al origen) y
las demás cambian el acrónimo de origen por el de auditoría (en aud_seguimiento_actividad, el per_codigo de origen
es per_codigo_autor), más per_codigo, <aud>_operacion (CHAR(1) DEFAULT 'U' CHECK IN ('I', 'U')), <aud>_usuario_bd y
<aud>_fecha_cambio. Son inmutables: TR_<aud>_inmutabilidad (error 50016) y DENY de escritura a sgspi_rol_base.
Almacenamiento [C1][D2][D3][D4]: PK BIGINT monotónica (<aud>_codigo) sin FKs hacia dbo.persona (reduce 62 -> 13 FKs
sobre dbo.persona), DATA_COMPRESSION = PAGE únicamente en las 9 aud_* operativas (aaf, ari, aai, aao, aea, apt, aat, asa,
aae) y sus índices NC, sin compresión ni índice per_codigo en las 40 aud_* de catálogos/puente.
shortcut: [D3] sin particionamiento prematuro (PF_sgspi_aud_anio/PS_sgspi_aud_anio retirados); particionar
aud_seguimiento_actividad (y aud_* de alto volumen) cuando supere 5M filas o 5 GB, usando filegroups anuales separados.
Filegroups [D4]: si el DBA pre-crea [FG_SGSPI_DATOS] / [FG_SGSPI_DATA] y lo marca DEFAULT antes de desplegar, todas las
tablas de [sgspi] se alojan fuera de [PRIMARY] sin fallar cuando el filegroup no existe.
==================================================================================================*/
-- [apv] Auditoría de [sgspi].[periodo_vigencia] ([pev])
CREATE TABLE sgspi.aud_periodo_vigencia (
    apv_codigo          BIGINT             IDENTITY (1, 1) NOT NULL,
    pev_codigo          SMALLINT           NOT NULL,
    apv_anio            SMALLINT           NOT NULL,
    apv_fecha_apertura  DATE               NOT NULL,
    apv_fecha_cierre    DATE               NULL,
    apv_fase_vigencia   NVARCHAR (20)      NOT NULL,
    apv_estado          BIT                NOT NULL,
    per_codigo          INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    apv_operacion       CHAR (1)           CONSTRAINT DF_apv_operacion DEFAULT 'U' NOT NULL,
    apv_usuario_bd      SYSNAME            CONSTRAINT DF_apv_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    apv_fecha_cambio    DATETIMEOFFSET (0) CONSTRAINT DF_apv_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_apv_aud_periodo_vigencia PRIMARY KEY CLUSTERED (apv_codigo),
    CONSTRAINT FK_apv_periodo_vigencia FOREIGN KEY (pev_codigo) REFERENCES sgspi.periodo_vigencia (pev_codigo),
    CONSTRAINT CK_apv_operacion CHECK (apv_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_apv_pev_codigo
    ON sgspi.aud_periodo_vigencia(pev_codigo, apv_fecha_cambio DESC);


-- [aec] Auditoría de [sgspi].[estado_flujo_catalogo] ([efc])
CREATE TABLE sgspi.aud_estado_flujo_catalogo (
    aec_codigo          BIGINT             IDENTITY (1, 1) NOT NULL,
    efc_codigo          SMALLINT           NOT NULL,
    aec_dominio         NVARCHAR (10)      NOT NULL,
    aec_identificador   NVARCHAR (30)      NOT NULL,
    aec_nombre          NVARCHAR (80)      NOT NULL,
    aec_es_inicial      BIT                NOT NULL,
    aec_permite_edicion BIT                NOT NULL,
    aec_estado          BIT                NOT NULL,
    per_codigo          INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    aec_operacion       CHAR (1)           CONSTRAINT DF_aec_operacion DEFAULT 'U' NOT NULL,
    aec_usuario_bd      SYSNAME            CONSTRAINT DF_aec_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    aec_fecha_cambio    DATETIMEOFFSET (0) CONSTRAINT DF_aec_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_aec_aud_estado_flujo_catalogo PRIMARY KEY CLUSTERED (aec_codigo),
    CONSTRAINT FK_aec_estado_flujo_catalogo FOREIGN KEY (efc_codigo) REFERENCES sgspi.estado_flujo_catalogo (efc_codigo),
    CONSTRAINT CK_aec_operacion CHECK (aec_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_aec_efc_codigo
    ON sgspi.aud_estado_flujo_catalogo(efc_codigo, aec_fecha_cambio DESC);


-- [atf] Auditoría de [sgspi].[transicion_estado_flujo] ([tef])
CREATE TABLE sgspi.aud_transicion_estado_flujo (
    atf_codigo                BIGINT             IDENTITY (1, 1) NOT NULL,
    tef_codigo                SMALLINT           NOT NULL,
    efc_dominio               NVARCHAR (10)      NOT NULL,
    efc_identificador_origen  NVARCHAR (30)      NOT NULL,
    efc_identificador_destino NVARCHAR (30)      NOT NULL,
    atf_rol_requerido         SYSNAME            NULL,
    atf_estado                BIT                NOT NULL,
    per_codigo                INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    atf_operacion             CHAR (1)           CONSTRAINT DF_atf_operacion DEFAULT 'U' NOT NULL,
    atf_usuario_bd            SYSNAME            CONSTRAINT DF_atf_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    atf_fecha_cambio          DATETIMEOFFSET (0) CONSTRAINT DF_atf_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_atf_aud_transicion_estado_flujo PRIMARY KEY CLUSTERED (atf_codigo),
    CONSTRAINT FK_atf_transicion_estado_flujo FOREIGN KEY (tef_codigo) REFERENCES sgspi.transicion_estado_flujo (tef_codigo),
    CONSTRAINT CK_atf_operacion CHECK (atf_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_atf_tef_codigo
    ON sgspi.aud_transicion_estado_flujo(tef_codigo, atf_fecha_cambio DESC);


-- [atr] Auditoría de [sgspi].[tipo_proceso_catalogo] ([tpr])
CREATE TABLE sgspi.aud_tipo_proceso_catalogo (
    atr_codigo        BIGINT             IDENTITY (1, 1) NOT NULL,
    tpr_codigo        TINYINT            NOT NULL,
    atr_identificador NVARCHAR (20)      NOT NULL,
    atr_nombre        NVARCHAR (50)      NOT NULL,
    atr_descripcion   NVARCHAR (255)     NULL,
    atr_estado        BIT                NOT NULL,
    per_codigo        INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    atr_operacion     CHAR (1)           CONSTRAINT DF_atr_operacion DEFAULT 'U' NOT NULL,
    atr_usuario_bd    SYSNAME            CONSTRAINT DF_atr_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    atr_fecha_cambio  DATETIMEOFFSET (0) CONSTRAINT DF_atr_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_atr_aud_tipo_proceso_catalogo PRIMARY KEY CLUSTERED (atr_codigo),
    CONSTRAINT FK_atr_tipo_proceso_catalogo FOREIGN KEY (tpr_codigo) REFERENCES sgspi.tipo_proceso_catalogo (tpr_codigo),
    CONSTRAINT CK_atr_operacion CHECK (atr_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_atr_tpr_codigo
    ON sgspi.aud_tipo_proceso_catalogo(tpr_codigo, atr_fecha_cambio DESC);


-- [api] Auditoría de [sgspi].[proceso_institucional] ([pri])
CREATE TABLE sgspi.aud_proceso_institucional (
    api_codigo        BIGINT             IDENTITY (1, 1) NOT NULL,
    pri_codigo        INT                NOT NULL,
    api_identificador NVARCHAR (20)      NOT NULL,
    api_nombre        NVARCHAR (150)     NOT NULL,
    tpr_codigo        TINYINT            NOT NULL,
    uaa_codigo_lider  INT                NULL,
    car_codigo_lider  INT                NULL,
    api_estado        BIT                NOT NULL,
    per_codigo        INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    api_operacion     CHAR (1)           CONSTRAINT DF_api_operacion DEFAULT 'U' NOT NULL,
    api_usuario_bd    SYSNAME            CONSTRAINT DF_api_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    api_fecha_cambio  DATETIMEOFFSET (0) CONSTRAINT DF_api_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_api_aud_proceso_institucional PRIMARY KEY CLUSTERED (api_codigo),
    CONSTRAINT FK_api_proceso_institucional FOREIGN KEY (pri_codigo) REFERENCES sgspi.proceso_institucional (pri_codigo),
    CONSTRAINT CK_api_operacion CHECK (api_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_api_pri_codigo
    ON sgspi.aud_proceso_institucional(pri_codigo, api_fecha_cambio DESC);


-- [apu] Auditoría de [sgspi].[proceso_institucional_uaa] ([piu])
CREATE TABLE sgspi.aud_proceso_institucional_uaa (
    apu_codigo       BIGINT             IDENTITY (1, 1) NOT NULL,
    pri_codigo       INT                NOT NULL,
    uaa_codigo       INT                NOT NULL,
    apu_estado       BIT                NOT NULL,
    per_codigo       INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    apu_operacion    CHAR (1)           CONSTRAINT DF_apu_operacion DEFAULT 'U' NOT NULL,
    apu_usuario_bd   SYSNAME            CONSTRAINT DF_apu_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    apu_fecha_cambio DATETIMEOFFSET (0) CONSTRAINT DF_apu_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_apu_aud_proceso_institucional_uaa PRIMARY KEY CLUSTERED (apu_codigo),
    CONSTRAINT FK_apu_proceso_institucional_uaa FOREIGN KEY (pri_codigo, uaa_codigo) REFERENCES sgspi.proceso_institucional_uaa (pri_codigo, uaa_codigo),
    CONSTRAINT CK_apu_operacion CHECK (apu_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_apu_pri_codigo_uaa_codigo
    ON sgspi.aud_proceso_institucional_uaa(pri_codigo, uaa_codigo, apu_fecha_cambio DESC);


-- [afc] Auditoría de [sgspi].[factor_entorno_catalogo] ([fec])
CREATE TABLE sgspi.aud_factor_entorno_catalogo (
    afc_codigo         BIGINT             IDENTITY (1, 1) NOT NULL,
    fec_codigo         SMALLINT           NOT NULL,
    afc_nombre_factor  NVARCHAR (100)     NOT NULL,
    afc_ambito_entorno NVARCHAR (15)      NOT NULL,
    afc_descripcion    NVARCHAR (255)     NULL,
    afc_estado         BIT                NOT NULL,
    per_codigo         INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    afc_operacion      CHAR (1)           CONSTRAINT DF_afc_operacion DEFAULT 'U' NOT NULL,
    afc_usuario_bd     SYSNAME            CONSTRAINT DF_afc_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    afc_fecha_cambio   DATETIMEOFFSET (0) CONSTRAINT DF_afc_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_afc_aud_factor_entorno_catalogo PRIMARY KEY CLUSTERED (afc_codigo),
    CONSTRAINT FK_afc_factor_entorno_catalogo FOREIGN KEY (fec_codigo) REFERENCES sgspi.factor_entorno_catalogo (fec_codigo),
    CONSTRAINT CK_afc_operacion CHECK (afc_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_afc_fec_codigo
    ON sgspi.aud_factor_entorno_catalogo(fec_codigo, afc_fecha_cambio DESC);


-- [aaf] Auditoría de [sgspi].[analisis_contexto_factor] ([acf])
CREATE TABLE sgspi.aud_analisis_contexto_factor (
    aaf_codigo                  BIGINT             IDENTITY (1, 1) NOT NULL,
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
    aaf_fase_registro           NVARCHAR (30)      NOT NULL,
    per_codigo_creador          INT                NOT NULL,
    per_codigo_aprobador        INT                NULL,
    aaf_fecha_actualizacion     DATETIMEOFFSET (0) NOT NULL,
    aaf_estado                  BIT                NOT NULL,
    per_codigo                  INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    aaf_operacion               CHAR (1)           CONSTRAINT DF_aaf_operacion DEFAULT 'U' NOT NULL,
    aaf_usuario_bd              SYSNAME            CONSTRAINT DF_aaf_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    aaf_fecha_cambio            DATETIMEOFFSET (0) CONSTRAINT DF_aaf_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_aaf_aud_analisis_contexto_factor PRIMARY KEY CLUSTERED (aaf_codigo),
    CONSTRAINT FK_aaf_analisis_contexto_factor FOREIGN KEY (acf_codigo) REFERENCES sgspi.analisis_contexto_factor (acf_codigo),
    CONSTRAINT CK_aaf_operacion CHECK (aaf_operacion IN ('I', 'U'))
)
WITH (DATA_COMPRESSION = PAGE);

CREATE NONCLUSTERED INDEX IX_aaf_acf_codigo
    ON sgspi.aud_analisis_contexto_factor(acf_codigo, aaf_fecha_cambio DESC) WITH (DATA_COMPRESSION = PAGE);

CREATE NONCLUSTERED INDEX IX_aaf_per_codigo
    ON sgspi.aud_analisis_contexto_factor(per_codigo) WITH (DATA_COMPRESSION = PAGE);


-- [apa] Auditoría de [sgspi].[parte_interesada] ([pai])
CREATE TABLE sgspi.aud_parte_interesada (
    apa_codigo          BIGINT             IDENTITY (1, 1) NOT NULL,
    pai_codigo          INT                NOT NULL,
    apa_nombre          NVARCHAR (150)     NOT NULL,
    apa_origen          NVARCHAR (15)      NOT NULL,
    apa_descripcion_rol NVARCHAR (255)     NULL,
    apa_estado          BIT                NOT NULL,
    per_codigo          INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    apa_operacion       CHAR (1)           CONSTRAINT DF_apa_operacion DEFAULT 'U' NOT NULL,
    apa_usuario_bd      SYSNAME            CONSTRAINT DF_apa_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    apa_fecha_cambio    DATETIMEOFFSET (0) CONSTRAINT DF_apa_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_apa_aud_parte_interesada PRIMARY KEY CLUSTERED (apa_codigo),
    CONSTRAINT FK_apa_parte_interesada FOREIGN KEY (pai_codigo) REFERENCES sgspi.parte_interesada (pai_codigo),
    CONSTRAINT CK_apa_operacion CHECK (apa_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_apa_pai_codigo
    ON sgspi.aud_parte_interesada(pai_codigo, apa_fecha_cambio DESC);


-- [ari] Auditoría de [sgspi].[requisito_parte_interesada] ([rpi])
CREATE TABLE sgspi.aud_requisito_parte_interesada (
    ari_codigo                BIGINT             IDENTITY (1, 1) NOT NULL,
    rpi_codigo                INT                NOT NULL,
    pev_codigo                SMALLINT           NOT NULL,
    pai_codigo                INT                NOT NULL,
    ari_necesidad_expectativa NVARCHAR (1000)    NOT NULL,
    ari_valor_poder           TINYINT            NOT NULL,
    ari_valor_interes         TINYINT            NOT NULL,
    ari_valor_cumplimiento    TINYINT            NULL,
    ari_mecanismo_seguimiento NVARCHAR (255)     NULL,
    ari_fase_registro         NVARCHAR (30)      NOT NULL,
    per_codigo_creador        INT                NOT NULL,
    per_codigo_aprobador      INT                NULL,
    ari_fecha_actualizacion   DATETIMEOFFSET (0) NOT NULL,
    ari_estado                BIT                NOT NULL,
    per_codigo                INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    ari_operacion             CHAR (1)           CONSTRAINT DF_ari_operacion DEFAULT 'U' NOT NULL,
    ari_usuario_bd            SYSNAME            CONSTRAINT DF_ari_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    ari_fecha_cambio          DATETIMEOFFSET (0) CONSTRAINT DF_ari_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_ari_aud_requisito_parte_interesada PRIMARY KEY CLUSTERED (ari_codigo),
    CONSTRAINT FK_ari_requisito_parte_interesada FOREIGN KEY (rpi_codigo) REFERENCES sgspi.requisito_parte_interesada (rpi_codigo),
    CONSTRAINT CK_ari_operacion CHECK (ari_operacion IN ('I', 'U'))
)
WITH (DATA_COMPRESSION = PAGE);

CREATE NONCLUSTERED INDEX IX_ari_rpi_codigo
    ON sgspi.aud_requisito_parte_interesada(rpi_codigo, ari_fecha_cambio DESC) WITH (DATA_COMPRESSION = PAGE);

CREATE NONCLUSTERED INDEX IX_ari_per_codigo
    ON sgspi.aud_requisito_parte_interesada(per_codigo) WITH (DATA_COMPRESSION = PAGE);


-- [arp] Auditoría de [sgspi].[requisito_parte_interesada_proceso_institucional] ([rpp])
CREATE TABLE sgspi.aud_requisito_parte_interesada_proceso_institucional (
    arp_codigo         BIGINT             IDENTITY (1, 1) NOT NULL,
    rpi_codigo         INT                NOT NULL,
    pri_codigo         INT                NOT NULL,
    arp_fecha_registro DATETIMEOFFSET (0) NOT NULL,
    arp_estado         BIT                NOT NULL,
    per_codigo         INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    arp_operacion      CHAR (1)           CONSTRAINT DF_arp_operacion DEFAULT 'U' NOT NULL,
    arp_usuario_bd     SYSNAME            CONSTRAINT DF_arp_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    arp_fecha_cambio   DATETIMEOFFSET (0) CONSTRAINT DF_arp_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_arp_aud_requisito_parte_interesada_proceso_institucional PRIMARY KEY CLUSTERED (arp_codigo),
    CONSTRAINT FK_arp_requisito_parte_interesada_proceso_institucional FOREIGN KEY (rpi_codigo, pri_codigo) REFERENCES sgspi.requisito_parte_interesada_proceso_institucional (rpi_codigo, pri_codigo),
    CONSTRAINT CK_arp_operacion CHECK (arp_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_arp_rpi_codigo_pri_codigo
    ON sgspi.aud_requisito_parte_interesada_proceso_institucional(rpi_codigo, pri_codigo, arp_fecha_cambio DESC);


-- [atc] Auditoría de [sgspi].[tipo_activo_catalogo] ([tac])
CREATE TABLE sgspi.aud_tipo_activo_catalogo (
    atc_codigo          BIGINT             IDENTITY (1, 1) NOT NULL,
    tac_codigo          SMALLINT           NOT NULL,
    atc_codigo_padre    SMALLINT           NULL,
    atc_nivel_taxonomia TINYINT            NOT NULL,
    atc_nombre          NVARCHAR (120)     NOT NULL,
    atc_ejemplos_ref    NVARCHAR (255)     NULL,
    atc_estado          BIT                NOT NULL,
    per_codigo          INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    atc_operacion       CHAR (1)           CONSTRAINT DF_atc_operacion DEFAULT 'U' NOT NULL,
    atc_usuario_bd      SYSNAME            CONSTRAINT DF_atc_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    atc_fecha_cambio    DATETIMEOFFSET (0) CONSTRAINT DF_atc_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_atc_aud_tipo_activo_catalogo PRIMARY KEY CLUSTERED (atc_codigo),
    CONSTRAINT FK_atc_tipo_activo_catalogo FOREIGN KEY (tac_codigo) REFERENCES sgspi.tipo_activo_catalogo (tac_codigo),
    CONSTRAINT CK_atc_operacion CHECK (atc_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_atc_tac_codigo
    ON sgspi.aud_tipo_activo_catalogo(tac_codigo, atc_fecha_cambio DESC);


-- [ace] Auditoría de [sgspi].[causal_excepcion_transparencia] ([cet])
CREATE TABLE sgspi.aud_causal_excepcion_transparencia (
    ace_codigo                  BIGINT             IDENTITY (1, 1) NOT NULL,
    cet_codigo                  SMALLINT           NOT NULL,
    ace_nivel_reserva_aplicable NVARCHAR (20)      NOT NULL,
    ace_numeral_causal          NVARCHAR (10)      NOT NULL,
    ace_descripcion_causal      NVARCHAR (500)     NOT NULL,
    ace_norma_referencia        NVARCHAR (100)     NOT NULL,
    ace_estado                  BIT                NOT NULL,
    per_codigo                  INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    ace_operacion               CHAR (1)           CONSTRAINT DF_ace_operacion DEFAULT 'U' NOT NULL,
    ace_usuario_bd              SYSNAME            CONSTRAINT DF_ace_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    ace_fecha_cambio            DATETIMEOFFSET (0) CONSTRAINT DF_ace_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_ace_aud_causal_excepcion_transparencia PRIMARY KEY CLUSTERED (ace_codigo),
    CONSTRAINT FK_ace_causal_excepcion_transparencia FOREIGN KEY (cet_codigo) REFERENCES sgspi.causal_excepcion_transparencia (cet_codigo),
    CONSTRAINT CK_ace_operacion CHECK (ace_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_ace_cet_codigo
    ON sgspi.aud_causal_excepcion_transparencia(cet_codigo, ace_fecha_cambio DESC);


-- [aai] Auditoría de [sgspi].[activo_informacion] ([aci])
CREATE TABLE sgspi.aud_activo_informacion (
    aai_codigo                          BIGINT             IDENTITY (1, 1) NOT NULL,
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
    aai_fase_registro                   NVARCHAR (30)      NOT NULL,
    per_codigo_creador                  INT                NOT NULL,
    per_codigo_aprobador                INT                NULL,
    per_codigo_revisor_archivo          INT                NULL,
    aai_fecha_actualizacion             DATETIMEOFFSET (0) NOT NULL,
    aai_estado                          BIT                NOT NULL,
    per_codigo                          INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    aai_operacion                       CHAR (1)           CONSTRAINT DF_aai_operacion DEFAULT 'U' NOT NULL,
    aai_usuario_bd                      SYSNAME            CONSTRAINT DF_aai_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    aai_fecha_cambio                    DATETIMEOFFSET (0) CONSTRAINT DF_aai_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_aai_aud_activo_informacion PRIMARY KEY CLUSTERED (aai_codigo),
    CONSTRAINT FK_aai_activo_informacion FOREIGN KEY (aci_codigo) REFERENCES sgspi.activo_informacion (aci_codigo),
    CONSTRAINT CK_aai_operacion CHECK (aai_operacion IN ('I', 'U'))
)
WITH (DATA_COMPRESSION = PAGE);

CREATE NONCLUSTERED INDEX IX_aai_aci_codigo
    ON sgspi.aud_activo_informacion(aci_codigo, aai_fecha_cambio DESC) WITH (DATA_COMPRESSION = PAGE);

CREATE NONCLUSTERED INDEX IX_aai_per_codigo
    ON sgspi.aud_activo_informacion(per_codigo) WITH (DATA_COMPRESSION = PAGE);


-- [aap] Auditoría de [sgspi].[activo_informacion_proceso_institucional] ([aip])
CREATE TABLE sgspi.aud_activo_informacion_proceso_institucional (
    aap_codigo       BIGINT             IDENTITY (1, 1) NOT NULL,
    aci_codigo       INT                NOT NULL,
    pri_codigo       INT                NOT NULL,
    aap_estado       BIT                NOT NULL,
    per_codigo       INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    aap_operacion    CHAR (1)           CONSTRAINT DF_aap_operacion DEFAULT 'U' NOT NULL,
    aap_usuario_bd   SYSNAME            CONSTRAINT DF_aap_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    aap_fecha_cambio DATETIMEOFFSET (0) CONSTRAINT DF_aap_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_aap_aud_activo_informacion_proceso_institucional PRIMARY KEY CLUSTERED (aap_codigo),
    CONSTRAINT FK_aap_activo_informacion_proceso_institucional FOREIGN KEY (aci_codigo, pri_codigo) REFERENCES sgspi.activo_informacion_proceso_institucional (aci_codigo, pri_codigo),
    CONSTRAINT CK_aap_operacion CHECK (aap_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_aap_aci_codigo_pri_codigo
    ON sgspi.aud_activo_informacion_proceso_institucional(aci_codigo, pri_codigo, aap_fecha_cambio DESC);


-- [aas] Auditoría de [sgspi].[activo_informacion_sede] ([ais])
CREATE TABLE sgspi.aud_activo_informacion_sede (
    aas_codigo       BIGINT             IDENTITY (1, 1) NOT NULL,
    aci_codigo       INT                NOT NULL,
    sus_codigo       INT                NOT NULL,
    aas_estado       BIT                NOT NULL,
    per_codigo       INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    aas_operacion    CHAR (1)           CONSTRAINT DF_aas_operacion DEFAULT 'U' NOT NULL,
    aas_usuario_bd   SYSNAME            CONSTRAINT DF_aas_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    aas_fecha_cambio DATETIMEOFFSET (0) CONSTRAINT DF_aas_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_aas_aud_activo_informacion_sede PRIMARY KEY CLUSTERED (aas_codigo),
    CONSTRAINT FK_aas_activo_informacion_sede FOREIGN KEY (aci_codigo, sus_codigo) REFERENCES sgspi.activo_informacion_sede (aci_codigo, sus_codigo),
    CONSTRAINT CK_aas_operacion CHECK (aas_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_aas_aci_codigo_sus_codigo
    ON sgspi.aud_activo_informacion_sede(aci_codigo, sus_codigo, aas_fecha_cambio DESC);


-- [aar] Auditoría de [sgspi].[activo_informacion_responsable] ([air])
CREATE TABLE sgspi.aud_activo_informacion_responsable (
    aar_codigo               BIGINT             IDENTITY (1, 1) NOT NULL,
    aci_codigo               INT                NOT NULL,
    car_codigo               INT                NOT NULL,
    uaa_codigo               INT                NOT NULL,
    air_tipo_responsabilidad NVARCHAR (20)      NOT NULL,
    aar_estado               BIT                NOT NULL,
    per_codigo               INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    aar_operacion            CHAR (1)           CONSTRAINT DF_aar_operacion DEFAULT 'U' NOT NULL,
    aar_usuario_bd           SYSNAME            CONSTRAINT DF_aar_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    aar_fecha_cambio         DATETIMEOFFSET (0) CONSTRAINT DF_aar_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_aar_aud_activo_informacion_responsable PRIMARY KEY CLUSTERED (aar_codigo),
    CONSTRAINT FK_aar_activo_informacion_responsable FOREIGN KEY (aci_codigo, car_codigo, uaa_codigo, air_tipo_responsabilidad) REFERENCES sgspi.activo_informacion_responsable (aci_codigo, car_codigo, uaa_codigo, air_tipo_responsabilidad),
    CONSTRAINT CK_aar_operacion CHECK (aar_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_aar_aci_codigo_car_codigo_uaa_codigo_air_tipo_responsabilidad
    ON sgspi.aud_activo_informacion_responsable(aci_codigo, car_codigo, uaa_codigo, air_tipo_responsabilidad, aar_fecha_cambio DESC);


-- [asf] Auditoría de [sgspi].[sistema_informacion_ficha] ([sif])
CREATE TABLE sgspi.aud_sistema_informacion_ficha (
    asf_codigo               BIGINT             IDENTITY (1, 1) NOT NULL,
    sif_codigo               INT                NOT NULL,
    aci_codigo               INT                NULL,
    asf_nombre_sistema       NVARCHAR (150)     NOT NULL,
    asf_modalidad_desarrollo NVARCHAR (50)      NOT NULL,
    asf_fabricante_proveedor NVARCHAR (150)     NULL,
    asf_descripcion_general  NVARCHAR (1000)    NOT NULL,
    asf_estado               BIT                NOT NULL,
    per_codigo               INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    asf_operacion            CHAR (1)           CONSTRAINT DF_asf_operacion DEFAULT 'U' NOT NULL,
    asf_usuario_bd           SYSNAME            CONSTRAINT DF_asf_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    asf_fecha_cambio         DATETIMEOFFSET (0) CONSTRAINT DF_asf_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_asf_aud_sistema_informacion_ficha PRIMARY KEY CLUSTERED (asf_codigo),
    CONSTRAINT FK_asf_sistema_informacion_ficha FOREIGN KEY (sif_codigo) REFERENCES sgspi.sistema_informacion_ficha (sif_codigo),
    CONSTRAINT CK_asf_operacion CHECK (asf_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_asf_sif_codigo
    ON sgspi.aud_sistema_informacion_ficha(sif_codigo, asf_fecha_cambio DESC);



-- [ami] Auditoría de [sgspi].[modulo_sistema_informacion] ([msi])
CREATE TABLE sgspi.aud_modulo_sistema_informacion (
    ami_codigo            BIGINT             IDENTITY (1, 1) NOT NULL,
    msi_codigo            INT                NOT NULL,
    sif_codigo            INT                NOT NULL,
    ami_nombre_modulo     NVARCHAR (200)     NOT NULL,
    ami_usuarios_objetivo NVARCHAR (150)     NULL,
    ami_estado            BIT                NOT NULL,
    per_codigo            INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    ami_operacion         CHAR (1)           CONSTRAINT DF_ami_operacion DEFAULT 'U' NOT NULL,
    ami_usuario_bd        SYSNAME            CONSTRAINT DF_ami_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    ami_fecha_cambio      DATETIMEOFFSET (0) CONSTRAINT DF_ami_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_ami_aud_modulo_sistema_informacion PRIMARY KEY CLUSTERED (ami_codigo),
    CONSTRAINT FK_ami_modulo_sistema_informacion FOREIGN KEY (msi_codigo) REFERENCES sgspi.modulo_sistema_informacion (msi_codigo),
    CONSTRAINT CK_ami_operacion CHECK (ami_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_ami_msi_codigo
    ON sgspi.aud_modulo_sistema_informacion(msi_codigo, ami_fecha_cambio DESC);


-- [aso] Auditoría de [sgspi].[serie_documental_catalogo] ([sdo])
CREATE TABLE sgspi.aud_serie_documental_catalogo (
    aso_codigo       BIGINT             IDENTITY (1, 1) NOT NULL,
    sdo_codigo       SMALLINT           NOT NULL,
    aso_numero_ccd   SMALLINT           NOT NULL,
    aso_nombre_serie NVARCHAR (150)     NOT NULL,
    aso_estado       BIT                NOT NULL,
    per_codigo       INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    aso_operacion    CHAR (1)           CONSTRAINT DF_aso_operacion DEFAULT 'U' NOT NULL,
    aso_usuario_bd   SYSNAME            CONSTRAINT DF_aso_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    aso_fecha_cambio DATETIMEOFFSET (0) CONSTRAINT DF_aso_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_aso_aud_serie_documental_catalogo PRIMARY KEY CLUSTERED (aso_codigo),
    CONSTRAINT FK_aso_serie_documental_catalogo FOREIGN KEY (sdo_codigo) REFERENCES sgspi.serie_documental_catalogo (sdo_codigo),
    CONSTRAINT CK_aso_operacion CHECK (aso_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_aso_sdo_codigo
    ON sgspi.aud_serie_documental_catalogo(sdo_codigo, aso_fecha_cambio DESC);


-- [asd] Auditoría de [sgspi].[subserie_documental_catalogo] ([sbd])
CREATE TABLE sgspi.aud_subserie_documental_catalogo (
    asd_codigo          BIGINT             IDENTITY (1, 1) NOT NULL,
    sbd_codigo          INT                NOT NULL,
    sdo_codigo          SMALLINT           NOT NULL,
    asd_numero_ccd      SMALLINT           NOT NULL,
    asd_nombre_subserie NVARCHAR (200)     NOT NULL,
    asd_estado          BIT                NOT NULL,
    per_codigo          INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    asd_operacion       CHAR (1)           CONSTRAINT DF_asd_operacion DEFAULT 'U' NOT NULL,
    asd_usuario_bd      SYSNAME            CONSTRAINT DF_asd_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    asd_fecha_cambio    DATETIMEOFFSET (0) CONSTRAINT DF_asd_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_asd_aud_subserie_documental_catalogo PRIMARY KEY CLUSTERED (asd_codigo),
    CONSTRAINT FK_asd_subserie_documental_catalogo FOREIGN KEY (sbd_codigo) REFERENCES sgspi.subserie_documental_catalogo (sbd_codigo),
    CONSTRAINT CK_asd_operacion CHECK (asd_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_asd_sbd_codigo
    ON sgspi.aud_subserie_documental_catalogo(sbd_codigo, asd_fecha_cambio DESC);


-- [auc] Auditoría de [sgspi].[unidad_productora_cuadro_clasificacion_documental] ([upc])
CREATE TABLE sgspi.aud_unidad_productora_cuadro_clasificacion_documental (
    auc_codigo              BIGINT             IDENTITY (1, 1) NOT NULL,
    upc_codigo              INT                NOT NULL,
    auc_nodo_jerarquico     HIERARCHYID        NOT NULL,
    auc_codigo_archivistico NVARCHAR (50)      NULL,
    uaa_codigo              INT                NULL,
    auc_nombre_unidad       NVARCHAR (150)     NOT NULL,
    auc_estado              BIT                NOT NULL,
    per_codigo              INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    auc_operacion           CHAR (1)           CONSTRAINT DF_auc_operacion DEFAULT 'U' NOT NULL,
    auc_usuario_bd          SYSNAME            CONSTRAINT DF_auc_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    auc_fecha_cambio        DATETIMEOFFSET (0) CONSTRAINT DF_auc_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_auc_aud_unidad_productora_cuadro_clasificacion_documental PRIMARY KEY CLUSTERED (auc_codigo),
    CONSTRAINT FK_auc_unidad_productora_cuadro_clasificacion_documental FOREIGN KEY (upc_codigo) REFERENCES sgspi.unidad_productora_cuadro_clasificacion_documental (upc_codigo),
    CONSTRAINT CK_auc_operacion CHECK (auc_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_auc_upc_codigo
    ON sgspi.aud_unidad_productora_cuadro_clasificacion_documental(upc_codigo, auc_fecha_cambio DESC);


-- [apc] Auditoría de [sgspi].[periodicidad_catalogo] ([pdc])
CREATE TABLE sgspi.aud_periodicidad_catalogo (
    apc_codigo       BIGINT             IDENTITY (1, 1) NOT NULL,
    pdc_codigo       SMALLINT           NOT NULL,
    apc_nombre       NVARCHAR (40)      NOT NULL,
    apc_orden        TINYINT            NOT NULL,
    apc_estado       BIT                NOT NULL,
    per_codigo       INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    apc_operacion    CHAR (1)           CONSTRAINT DF_apc_operacion DEFAULT 'U' NOT NULL,
    apc_usuario_bd   SYSNAME            CONSTRAINT DF_apc_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    apc_fecha_cambio DATETIMEOFFSET (0) CONSTRAINT DF_apc_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_apc_aud_periodicidad_catalogo PRIMARY KEY CLUSTERED (apc_codigo),
    CONSTRAINT FK_apc_periodicidad_catalogo FOREIGN KEY (pdc_codigo) REFERENCES sgspi.periodicidad_catalogo (pdc_codigo),
    CONSTRAINT CK_apc_operacion CHECK (apc_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_apc_pdc_codigo
    ON sgspi.aud_periodicidad_catalogo(pdc_codigo, apc_fecha_cambio DESC);


-- [aep] Auditoría de [sgspi].[estado_publicacion_catalogo] ([epc])
CREATE TABLE sgspi.aud_estado_publicacion_catalogo (
    aep_codigo       BIGINT             IDENTITY (1, 1) NOT NULL,
    epc_codigo       SMALLINT           NOT NULL,
    aep_nombre       NVARCHAR (60)      NOT NULL,
    aep_descripcion  NVARCHAR (255)     NULL,
    aep_estado       BIT                NOT NULL,
    per_codigo       INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    aep_operacion    CHAR (1)           CONSTRAINT DF_aep_operacion DEFAULT 'U' NOT NULL,
    aep_usuario_bd   SYSNAME            CONSTRAINT DF_aep_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    aep_fecha_cambio DATETIMEOFFSET (0) CONSTRAINT DF_aep_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_aep_aud_estado_publicacion_catalogo PRIMARY KEY CLUSTERED (aep_codigo),
    CONSTRAINT FK_aep_estado_publicacion_catalogo FOREIGN KEY (epc_codigo) REFERENCES sgspi.estado_publicacion_catalogo (epc_codigo),
    CONSTRAINT CK_aep_operacion CHECK (aep_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_aep_epc_codigo
    ON sgspi.aud_estado_publicacion_catalogo(epc_codigo, aep_fecha_cambio DESC);


-- [asc] Auditoría de [sgspi].[soporte_registro_catalogo] ([src])
CREATE TABLE sgspi.aud_soporte_registro_catalogo (
    asc_codigo       BIGINT             IDENTITY (1, 1) NOT NULL,
    src_codigo       SMALLINT           NOT NULL,
    asc_nombre       NVARCHAR (30)      NOT NULL,
    asc_estado       BIT                NOT NULL,
    per_codigo       INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    asc_operacion    CHAR (1)           CONSTRAINT DF_asc_operacion DEFAULT 'U' NOT NULL,
    asc_usuario_bd   SYSNAME            CONSTRAINT DF_asc_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    asc_fecha_cambio DATETIMEOFFSET (0) CONSTRAINT DF_asc_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_asc_aud_soporte_registro_catalogo PRIMARY KEY CLUSTERED (asc_codigo),
    CONSTRAINT FK_asc_soporte_registro_catalogo FOREIGN KEY (src_codigo) REFERENCES sgspi.soporte_registro_catalogo (src_codigo),
    CONSTRAINT CK_asc_operacion CHECK (asc_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_asc_src_codigo
    ON sgspi.aud_soporte_registro_catalogo(src_codigo, asc_fecha_cambio DESC);


-- [amc] Auditoría de [sgspi].[medio_conservacion_catalogo] ([mcc])
CREATE TABLE sgspi.aud_medio_conservacion_catalogo (
    amc_codigo       BIGINT             IDENTITY (1, 1) NOT NULL,
    mcc_codigo       SMALLINT           NOT NULL,
    amc_nombre       NVARCHAR (30)      NOT NULL,
    amc_estado       BIT                NOT NULL,
    per_codigo       INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    amc_operacion    CHAR (1)           CONSTRAINT DF_amc_operacion DEFAULT 'U' NOT NULL,
    amc_usuario_bd   SYSNAME            CONSTRAINT DF_amc_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    amc_fecha_cambio DATETIMEOFFSET (0) CONSTRAINT DF_amc_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_amc_aud_medio_conservacion_catalogo PRIMARY KEY CLUSTERED (amc_codigo),
    CONSTRAINT FK_amc_medio_conservacion_catalogo FOREIGN KEY (mcc_codigo) REFERENCES sgspi.medio_conservacion_catalogo (mcc_codigo),
    CONSTRAINT CK_amc_operacion CHECK (amc_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_amc_mcc_codigo
    ON sgspi.aud_medio_conservacion_catalogo(mcc_codigo, amc_fecha_cambio DESC);


-- [aii] Auditoría de [sgspi].[idioma_catalogo] ([idi])
CREATE TABLE sgspi.aud_idioma_catalogo (
    aii_codigo       BIGINT             IDENTITY (1, 1) NOT NULL,
    idi_codigo       SMALLINT           NOT NULL,
    aii_codigo_iso   NVARCHAR (10)      NOT NULL,
    aii_nombre       NVARCHAR (50)      NOT NULL,
    aii_estado       BIT                NOT NULL,
    per_codigo       INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    aii_operacion    CHAR (1)           CONSTRAINT DF_aii_operacion DEFAULT 'U' NOT NULL,
    aii_usuario_bd   SYSNAME            CONSTRAINT DF_aii_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    aii_fecha_cambio DATETIMEOFFSET (0) CONSTRAINT DF_aii_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_aii_aud_idioma_catalogo PRIMARY KEY CLUSTERED (aii_codigo),
    CONSTRAINT FK_aii_idioma_catalogo FOREIGN KEY (idi_codigo) REFERENCES sgspi.idioma_catalogo (idi_codigo),
    CONSTRAINT CK_aii_operacion CHECK (aii_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_aii_idi_codigo
    ON sgspi.aud_idioma_catalogo(idi_codigo, aii_fecha_cambio DESC);


-- [afa] Auditoría de [sgspi].[formato_archivo_catalogo] ([fac])
CREATE TABLE sgspi.aud_formato_archivo_catalogo (
    afa_codigo       BIGINT             IDENTITY (1, 1) NOT NULL,
    fac_codigo       SMALLINT           NOT NULL,
    afa_nombre       NVARCHAR (60)      NOT NULL,
    afa_estado       BIT                NOT NULL,
    per_codigo       INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    afa_operacion    CHAR (1)           CONSTRAINT DF_afa_operacion DEFAULT 'U' NOT NULL,
    afa_usuario_bd   SYSNAME            CONSTRAINT DF_afa_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    afa_fecha_cambio DATETIMEOFFSET (0) CONSTRAINT DF_afa_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_afa_aud_formato_archivo_catalogo PRIMARY KEY CLUSTERED (afa_codigo),
    CONSTRAINT FK_afa_formato_archivo_catalogo FOREIGN KEY (fac_codigo) REFERENCES sgspi.formato_archivo_catalogo (fac_codigo),
    CONSTRAINT CK_afa_operacion CHECK (afa_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_afa_fac_codigo
    ON sgspi.aud_formato_archivo_catalogo(fac_codigo, afa_fecha_cambio DESC);


-- [aao] Auditoría de [sgspi].[activo_documental] ([ado])
CREATE TABLE sgspi.aud_activo_documental (
    aao_codigo                        BIGINT             IDENTITY (1, 1) NOT NULL,
    ado_codigo                        INT                NOT NULL,
    pev_codigo                        SMALLINT           NOT NULL,
    sdo_codigo                        SMALLINT           NOT NULL,
    sbd_codigo                        INT                NULL,
    pdc_codigo                        SMALLINT           NOT NULL,
    aao_fecha_ingreso_tabla_retencion DATE               NULL,
    aao_fecha_ingreso_archivo         DATE               NULL,
    epc_codigo                        SMALLINT           NOT NULL,
    aao_lugar_consulta_ubicacion      NVARCHAR (255)     NOT NULL,
    aao_fecha_actualizacion           DATETIMEOFFSET (0) NOT NULL,
    aao_estado                        BIT                NOT NULL,
    per_codigo                        INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    aao_operacion                     CHAR (1)           CONSTRAINT DF_aao_operacion DEFAULT 'U' NOT NULL,
    aao_usuario_bd                    SYSNAME            CONSTRAINT DF_aao_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    aao_fecha_cambio                  DATETIMEOFFSET (0) CONSTRAINT DF_aao_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_aao_aud_activo_documental PRIMARY KEY CLUSTERED (aao_codigo),
    CONSTRAINT FK_aao_activo_documental FOREIGN KEY (ado_codigo) REFERENCES sgspi.activo_documental (ado_codigo),
    CONSTRAINT CK_aao_operacion CHECK (aao_operacion IN ('I', 'U'))
)
WITH (DATA_COMPRESSION = PAGE);

CREATE NONCLUSTERED INDEX IX_aao_ado_codigo
    ON sgspi.aud_activo_documental(ado_codigo, aao_fecha_cambio DESC) WITH (DATA_COMPRESSION = PAGE);

CREATE NONCLUSTERED INDEX IX_aao_per_codigo
    ON sgspi.aud_activo_documental(per_codigo) WITH (DATA_COMPRESSION = PAGE);


-- [aad] Auditoría de [sgspi].[activo_documental_soporte_registro] ([ads])
CREATE TABLE sgspi.aud_activo_documental_soporte_registro (
    aad_codigo       BIGINT             IDENTITY (1, 1) NOT NULL,
    ado_codigo       INT                NOT NULL,
    src_codigo       SMALLINT           NOT NULL,
    aad_estado       BIT                NOT NULL,
    per_codigo       INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    aad_operacion    CHAR (1)           CONSTRAINT DF_aad_operacion DEFAULT 'U' NOT NULL,
    aad_usuario_bd   SYSNAME            CONSTRAINT DF_aad_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    aad_fecha_cambio DATETIMEOFFSET (0) CONSTRAINT DF_aad_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_aad_aud_activo_documental_soporte_registro PRIMARY KEY CLUSTERED (aad_codigo),
    CONSTRAINT FK_aad_activo_documental_soporte_registro FOREIGN KEY (ado_codigo, src_codigo) REFERENCES sgspi.activo_documental_soporte_registro (ado_codigo, src_codigo),
    CONSTRAINT CK_aad_operacion CHECK (aad_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_aad_ado_codigo_src_codigo
    ON sgspi.aud_activo_documental_soporte_registro(ado_codigo, src_codigo, aad_fecha_cambio DESC);


-- [aam] Auditoría de [sgspi].[activo_documental_medio_conservacion] ([adm])
CREATE TABLE sgspi.aud_activo_documental_medio_conservacion (
    aam_codigo       BIGINT             IDENTITY (1, 1) NOT NULL,
    ado_codigo       INT                NOT NULL,
    mcc_codigo       SMALLINT           NOT NULL,
    aam_estado       BIT                NOT NULL,
    per_codigo       INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    aam_operacion    CHAR (1)           CONSTRAINT DF_aam_operacion DEFAULT 'U' NOT NULL,
    aam_usuario_bd   SYSNAME            CONSTRAINT DF_aam_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    aam_fecha_cambio DATETIMEOFFSET (0) CONSTRAINT DF_aam_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_aam_aud_activo_documental_medio_conservacion PRIMARY KEY CLUSTERED (aam_codigo),
    CONSTRAINT FK_aam_activo_documental_medio_conservacion FOREIGN KEY (ado_codigo, mcc_codigo) REFERENCES sgspi.activo_documental_medio_conservacion (ado_codigo, mcc_codigo),
    CONSTRAINT CK_aam_operacion CHECK (aam_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_aam_ado_codigo_mcc_codigo
    ON sgspi.aud_activo_documental_medio_conservacion(ado_codigo, mcc_codigo, aam_fecha_cambio DESC);


-- [aid] Auditoría de [sgspi].[activo_documental_idioma] ([adi])
CREATE TABLE sgspi.aud_activo_documental_idioma (
    aid_codigo       BIGINT             IDENTITY (1, 1) NOT NULL,
    ado_codigo       INT                NOT NULL,
    idi_codigo       SMALLINT           NOT NULL,
    aid_estado       BIT                NOT NULL,
    per_codigo       INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    aid_operacion    CHAR (1)           CONSTRAINT DF_aid_operacion DEFAULT 'U' NOT NULL,
    aid_usuario_bd   SYSNAME            CONSTRAINT DF_aid_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    aid_fecha_cambio DATETIMEOFFSET (0) CONSTRAINT DF_aid_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_aid_aud_activo_documental_idioma PRIMARY KEY CLUSTERED (aid_codigo),
    CONSTRAINT FK_aid_activo_documental_idioma FOREIGN KEY (ado_codigo, idi_codigo) REFERENCES sgspi.activo_documental_idioma (ado_codigo, idi_codigo),
    CONSTRAINT CK_aid_operacion CHECK (aid_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_aid_ado_codigo_idi_codigo
    ON sgspi.aud_activo_documental_idioma(ado_codigo, idi_codigo, aid_fecha_cambio DESC);


-- [afd] Auditoría de [sgspi].[activo_documental_formato_archivo] ([adf])
CREATE TABLE sgspi.aud_activo_documental_formato_archivo (
    afd_codigo       BIGINT             IDENTITY (1, 1) NOT NULL,
    ado_codigo       INT                NOT NULL,
    fac_codigo       SMALLINT           NOT NULL,
    afd_estado       BIT                NOT NULL,
    per_codigo       INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    afd_operacion    CHAR (1)           CONSTRAINT DF_afd_operacion DEFAULT 'U' NOT NULL,
    afd_usuario_bd   SYSNAME            CONSTRAINT DF_afd_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    afd_fecha_cambio DATETIMEOFFSET (0) CONSTRAINT DF_afd_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_afd_aud_activo_documental_formato_archivo PRIMARY KEY CLUSTERED (afd_codigo),
    CONSTRAINT FK_afd_activo_documental_formato_archivo FOREIGN KEY (ado_codigo, fac_codigo) REFERENCES sgspi.activo_documental_formato_archivo (ado_codigo, fac_codigo),
    CONSTRAINT CK_afd_operacion CHECK (afd_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_afd_ado_codigo_fac_codigo
    ON sgspi.aud_activo_documental_formato_archivo(ado_codigo, fac_codigo, afd_fecha_cambio DESC);


-- [aau] Auditoría de [sgspi].[activo_documental_unidad_productora] ([adu])
CREATE TABLE sgspi.aud_activo_documental_unidad_productora (
    aau_codigo       BIGINT             IDENTITY (1, 1) NOT NULL,
    ado_codigo       INT                NOT NULL,
    upc_codigo       INT                NOT NULL,
    aau_estado       BIT                NOT NULL,
    per_codigo       INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    aau_operacion    CHAR (1)           CONSTRAINT DF_aau_operacion DEFAULT 'U' NOT NULL,
    aau_usuario_bd   SYSNAME            CONSTRAINT DF_aau_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    aau_fecha_cambio DATETIMEOFFSET (0) CONSTRAINT DF_aau_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_aau_aud_activo_documental_unidad_productora PRIMARY KEY CLUSTERED (aau_codigo),
    CONSTRAINT FK_aau_activo_documental_unidad_productora FOREIGN KEY (ado_codigo, upc_codigo) REFERENCES sgspi.activo_documental_unidad_productora (ado_codigo, upc_codigo),
    CONSTRAINT CK_aau_operacion CHECK (aau_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_aau_ado_codigo_upc_codigo
    ON sgspi.aud_activo_documental_unidad_productora(ado_codigo, upc_codigo, aau_fecha_cambio DESC);


-- [aer] Auditoría de [sgspi].[escala_probabilidad] ([epr])
CREATE TABLE sgspi.aud_escala_probabilidad (
    aer_codigo                BIGINT             IDENTITY (1, 1) NOT NULL,
    epr_codigo                TINYINT            NOT NULL,
    aer_codigo_letra          CHAR (1)           NOT NULL,
    aer_nombre_nivel          NVARCHAR (30)      NOT NULL,
    aer_descripcion_criterio  NVARCHAR (255)     NOT NULL,
    aer_frecuencia_referencia NVARCHAR (100)     NOT NULL,
    aer_estado                BIT                NOT NULL,
    per_codigo                INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    aer_operacion             CHAR (1)           CONSTRAINT DF_aer_operacion DEFAULT 'U' NOT NULL,
    aer_usuario_bd            SYSNAME            CONSTRAINT DF_aer_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    aer_fecha_cambio          DATETIMEOFFSET (0) CONSTRAINT DF_aer_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_aer_aud_escala_probabilidad PRIMARY KEY CLUSTERED (aer_codigo),
    CONSTRAINT FK_aer_escala_probabilidad FOREIGN KEY (epr_codigo) REFERENCES sgspi.escala_probabilidad (epr_codigo),
    CONSTRAINT CK_aer_operacion CHECK (aer_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_aer_epr_codigo
    ON sgspi.aud_escala_probabilidad(epr_codigo, aer_fecha_cambio DESC);


-- [aem] Auditoría de [sgspi].[escala_impacto] ([eim])
CREATE TABLE sgspi.aud_escala_impacto (
    aem_codigo                     BIGINT             IDENTITY (1, 1) NOT NULL,
    eim_codigo                     TINYINT            NOT NULL,
    aem_nombre_impacto_negativo    NVARCHAR (30)      NOT NULL,
    aem_nombre_impacto_positivo    NVARCHAR (40)      NOT NULL,
    aem_descripcion_organizacional NVARCHAR (1000)    NOT NULL,
    aem_descripcion_operativa      NVARCHAR (1000)    NULL,
    aem_estado                     BIT                NOT NULL,
    per_codigo                     INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    aem_operacion                  CHAR (1)           CONSTRAINT DF_aem_operacion DEFAULT 'U' NOT NULL,
    aem_usuario_bd                 SYSNAME            CONSTRAINT DF_aem_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    aem_fecha_cambio               DATETIMEOFFSET (0) CONSTRAINT DF_aem_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_aem_aud_escala_impacto PRIMARY KEY CLUSTERED (aem_codigo),
    CONSTRAINT FK_aem_escala_impacto FOREIGN KEY (eim_codigo) REFERENCES sgspi.escala_impacto (eim_codigo),
    CONSTRAINT CK_aem_operacion CHECK (aem_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_aem_eim_codigo
    ON sgspi.aud_escala_impacto(eim_codigo, aem_fecha_cambio DESC);


-- [azc] Auditoría de [sgspi].[zona_riesgo_catalogo] ([zrc])
CREATE TABLE sgspi.aud_zona_riesgo_catalogo (
    azc_codigo       BIGINT             IDENTITY (1, 1) NOT NULL,
    zrc_codigo       CHAR (1)           NOT NULL,
    azc_nombre_nivel NVARCHAR (30)      NOT NULL,
    azc_orden        TINYINT            NOT NULL,
    azc_estado       BIT                NOT NULL,
    per_codigo       INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    azc_operacion    CHAR (1)           CONSTRAINT DF_azc_operacion DEFAULT 'U' NOT NULL,
    azc_usuario_bd   SYSNAME            CONSTRAINT DF_azc_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    azc_fecha_cambio DATETIMEOFFSET (0) CONSTRAINT DF_azc_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_azc_aud_zona_riesgo_catalogo PRIMARY KEY CLUSTERED (azc_codigo),
    CONSTRAINT FK_azc_zona_riesgo_catalogo FOREIGN KEY (zrc_codigo) REFERENCES sgspi.zona_riesgo_catalogo (zrc_codigo),
    CONSTRAINT CK_azc_operacion CHECK (azc_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_azc_zrc_codigo
    ON sgspi.aud_zona_riesgo_catalogo(zrc_codigo, azc_fecha_cambio DESC);


-- [amr] Auditoría de [sgspi].[matriz_valoracion_riesgo] ([mvr])
CREATE TABLE sgspi.aud_matriz_valoracion_riesgo (
    amr_codigo                            BIGINT             IDENTITY (1, 1) NOT NULL,
    epr_codigo                            TINYINT            NOT NULL,
    eim_codigo                            TINYINT            NOT NULL,
    zrc_codigo                            CHAR (1)           NOT NULL,
    amr_directriz_tratamiento_riesgo      NVARCHAR (255)     NOT NULL,
    amr_directriz_tratamiento_oportunidad NVARCHAR (255)     NOT NULL,
    amr_requiere_aprobacion_comite        BIT                NOT NULL,
    amr_estado                            BIT                NOT NULL,
    per_codigo                            INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    amr_operacion                         CHAR (1)           CONSTRAINT DF_amr_operacion DEFAULT 'U' NOT NULL,
    amr_usuario_bd                        SYSNAME            CONSTRAINT DF_amr_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    amr_fecha_cambio                      DATETIMEOFFSET (0) CONSTRAINT DF_amr_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_amr_aud_matriz_valoracion_riesgo PRIMARY KEY CLUSTERED (amr_codigo),
    CONSTRAINT FK_amr_matriz_valoracion_riesgo FOREIGN KEY (epr_codigo, eim_codigo) REFERENCES sgspi.matriz_valoracion_riesgo (epr_codigo, eim_codigo),
    CONSTRAINT CK_amr_operacion CHECK (amr_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_amr_epr_codigo_eim_codigo
    ON sgspi.aud_matriz_valoracion_riesgo(epr_codigo, eim_codigo, amr_fecha_cambio DESC);


-- [aea] Auditoría de [sgspi].[evento_incertidumbre_activo] ([eia])
CREATE TABLE sgspi.aud_evento_incertidumbre_activo (
    aea_codigo                   BIGINT             IDENTITY (1, 1) NOT NULL,
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
    aea_fase_registro            NVARCHAR (30)      NOT NULL,
    per_codigo_creador           INT                NOT NULL,
    per_codigo_validador_lider   INT                NULL,
    per_codigo_revisor_sgspi     INT                NULL,
    per_codigo_aprobador_comite  INT                NULL,
    aea_fecha_actualizacion      DATETIMEOFFSET (0) NOT NULL,
    aea_estado                   BIT                NOT NULL,
    per_codigo                   INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    aea_operacion                CHAR (1)           CONSTRAINT DF_aea_operacion DEFAULT 'U' NOT NULL,
    aea_usuario_bd               SYSNAME            CONSTRAINT DF_aea_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    aea_fecha_cambio             DATETIMEOFFSET (0) CONSTRAINT DF_aea_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_aea_aud_evento_incertidumbre_activo PRIMARY KEY CLUSTERED (aea_codigo),
    CONSTRAINT FK_aea_evento_incertidumbre_activo FOREIGN KEY (eia_codigo) REFERENCES sgspi.evento_incertidumbre_activo (eia_codigo),
    CONSTRAINT CK_aea_operacion CHECK (aea_operacion IN ('I', 'U'))
)
WITH (DATA_COMPRESSION = PAGE);

CREATE NONCLUSTERED INDEX IX_aea_eia_codigo
    ON sgspi.aud_evento_incertidumbre_activo(eia_codigo, aea_fecha_cambio DESC) WITH (DATA_COMPRESSION = PAGE);

CREATE NONCLUSTERED INDEX IX_aea_per_codigo
    ON sgspi.aud_evento_incertidumbre_activo(per_codigo) WITH (DATA_COMPRESSION = PAGE);


-- [aet] Auditoría de [sgspi].[estrategia_tratamiento_catalogo] ([etc])
CREATE TABLE sgspi.aud_estrategia_tratamiento_catalogo (
    aet_codigo               BIGINT             IDENTITY (1, 1) NOT NULL,
    etc_codigo               SMALLINT           NOT NULL,
    aet_nombre_estrategia    NVARCHAR (80)      NOT NULL,
    aet_naturaleza_aplicable NVARCHAR (15)      NOT NULL,
    aet_descripcion          NVARCHAR (255)     NULL,
    aet_estado               BIT                NOT NULL,
    per_codigo               INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    aet_operacion            CHAR (1)           CONSTRAINT DF_aet_operacion DEFAULT 'U' NOT NULL,
    aet_usuario_bd           SYSNAME            CONSTRAINT DF_aet_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    aet_fecha_cambio         DATETIMEOFFSET (0) CONSTRAINT DF_aet_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_aet_aud_estrategia_tratamiento_catalogo PRIMARY KEY CLUSTERED (aet_codigo),
    CONSTRAINT FK_aet_estrategia_tratamiento_catalogo FOREIGN KEY (etc_codigo) REFERENCES sgspi.estrategia_tratamiento_catalogo (etc_codigo),
    CONSTRAINT CK_aet_operacion CHECK (aet_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_aet_etc_codigo
    ON sgspi.aud_estrategia_tratamiento_catalogo(etc_codigo, aet_fecha_cambio DESC);


-- [apt] Auditoría de [sgspi].[plan_tratamiento] ([plt])
CREATE TABLE sgspi.aud_plan_tratamiento (
    apt_codigo                     BIGINT             IDENTITY (1, 1) NOT NULL,
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
    apt_estado                     BIT                NOT NULL,
    per_codigo                     INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    apt_operacion                  CHAR (1)           CONSTRAINT DF_apt_operacion DEFAULT 'U' NOT NULL,
    apt_usuario_bd                 SYSNAME            CONSTRAINT DF_apt_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    apt_fecha_cambio               DATETIMEOFFSET (0) CONSTRAINT DF_apt_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_apt_aud_plan_tratamiento PRIMARY KEY CLUSTERED (apt_codigo),
    CONSTRAINT FK_apt_plan_tratamiento FOREIGN KEY (plt_codigo) REFERENCES sgspi.plan_tratamiento (plt_codigo),
    CONSTRAINT CK_apt_operacion CHECK (apt_operacion IN ('I', 'U'))
)
WITH (DATA_COMPRESSION = PAGE);

CREATE NONCLUSTERED INDEX IX_apt_plt_codigo
    ON sgspi.aud_plan_tratamiento(plt_codigo, apt_fecha_cambio DESC) WITH (DATA_COMPRESSION = PAGE);

CREATE NONCLUSTERED INDEX IX_apt_per_codigo
    ON sgspi.aud_plan_tratamiento(per_codigo) WITH (DATA_COMPRESSION = PAGE);


-- [aat] Auditoría de [sgspi].[actividad_tratamiento] ([act])
CREATE TABLE sgspi.aud_actividad_tratamiento (
    aat_codigo                BIGINT             IDENTITY (1, 1) NOT NULL,
    act_codigo                INT                NOT NULL,
    plt_codigo                INT                NOT NULL,
    aat_numero_orden          SMALLINT           NOT NULL,
    aat_descripcion_actividad NVARCHAR (500)     NOT NULL,
    car_codigo                INT                NULL,
    uaa_codigo                INT                NULL,
    aat_fecha_compromiso      DATE               NOT NULL,
    aat_porcentaje_avance     TINYINT            NOT NULL,
    aat_fase_actividad        NVARCHAR (30)      NOT NULL,
    aat_fecha_actualizacion   DATETIMEOFFSET (0) NOT NULL,
    aat_estado                BIT                NOT NULL,
    per_codigo                INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    aat_operacion             CHAR (1)           CONSTRAINT DF_aat_operacion DEFAULT 'U' NOT NULL,
    aat_usuario_bd            SYSNAME            CONSTRAINT DF_aat_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    aat_fecha_cambio          DATETIMEOFFSET (0) CONSTRAINT DF_aat_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_aat_aud_actividad_tratamiento PRIMARY KEY CLUSTERED (aat_codigo),
    CONSTRAINT FK_aat_actividad_tratamiento FOREIGN KEY (act_codigo) REFERENCES sgspi.actividad_tratamiento (act_codigo),
    CONSTRAINT CK_aat_operacion CHECK (aat_operacion IN ('I', 'U'))
)
WITH (DATA_COMPRESSION = PAGE);

CREATE NONCLUSTERED INDEX IX_aat_act_codigo
    ON sgspi.aud_actividad_tratamiento(act_codigo, aat_fecha_cambio DESC) WITH (DATA_COMPRESSION = PAGE);

CREATE NONCLUSTERED INDEX IX_aat_per_codigo
    ON sgspi.aud_actividad_tratamiento(per_codigo) WITH (DATA_COMPRESSION = PAGE);


-- [asa] Auditoría de [sgspi].[seguimiento_actividad] ([sga])
CREATE TABLE sgspi.aud_seguimiento_actividad (
    asa_codigo                       BIGINT             IDENTITY (1, 1) NOT NULL,
    sga_codigo                       INT                NOT NULL,
    act_codigo                       INT                NOT NULL,
    per_codigo_autor                 INT                NOT NULL,
    asa_fecha_registro               DATETIMEOFFSET (0) NOT NULL,
    asa_porcentaje_reportado         TINYINT            NOT NULL,
    asa_descripcion_avance           NVARCHAR (1000)    NOT NULL,
    asa_nombre_archivo_evidencia     NVARCHAR (255)     NULL,
    asa_uri_almacenamiento_evidencia NVARCHAR (500)     NULL,
    asa_hash_sha256_evidencia        CHAR (64)          NULL,
    asa_estado                       BIT                NOT NULL,
    per_codigo                       INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    asa_operacion                    CHAR (1)           CONSTRAINT DF_asa_operacion DEFAULT 'U' NOT NULL,
    asa_usuario_bd                   SYSNAME            CONSTRAINT DF_asa_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    asa_fecha_cambio                 DATETIMEOFFSET (0) CONSTRAINT DF_asa_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_asa_aud_seguimiento_actividad PRIMARY KEY CLUSTERED (asa_codigo),
    CONSTRAINT FK_asa_seguimiento_actividad FOREIGN KEY (sga_codigo) REFERENCES sgspi.seguimiento_actividad (sga_codigo),
    CONSTRAINT CK_asa_operacion CHECK (asa_operacion IN ('I', 'U'))
)
WITH (DATA_COMPRESSION = PAGE);

CREATE NONCLUSTERED INDEX IX_asa_sga_codigo
    ON sgspi.aud_seguimiento_actividad(sga_codigo, asa_fecha_cambio DESC) WITH (DATA_COMPRESSION = PAGE);

CREATE NONCLUSTERED INDEX IX_asa_per_codigo
    ON sgspi.aud_seguimiento_actividad(per_codigo) WITH (DATA_COMPRESSION = PAGE);


-- [aen] Auditoría de [sgspi].[estandar_normativo_catalogo] ([enc])
CREATE TABLE sgspi.aud_estandar_normativo_catalogo (
    aen_codigo        BIGINT             IDENTITY (1, 1) NOT NULL,
    enc_codigo        SMALLINT           NOT NULL,
    aen_identificador NVARCHAR (50)      NOT NULL,
    aen_familia_norma NVARCHAR (20)      NOT NULL,
    aen_nombre        NVARCHAR (200)     NOT NULL,
    aen_organismo     NVARCHAR (100)     NULL,
    aen_anio_edicion  SMALLINT           NULL,
    aen_estado        BIT                NOT NULL,
    per_codigo        INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    aen_operacion     CHAR (1)           CONSTRAINT DF_aen_operacion DEFAULT 'U' NOT NULL,
    aen_usuario_bd    SYSNAME            CONSTRAINT DF_aen_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    aen_fecha_cambio  DATETIMEOFFSET (0) CONSTRAINT DF_aen_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_aen_aud_estandar_normativo_catalogo PRIMARY KEY CLUSTERED (aen_codigo),
    CONSTRAINT FK_aen_estandar_normativo_catalogo FOREIGN KEY (enc_codigo) REFERENCES sgspi.estandar_normativo_catalogo (enc_codigo),
    CONSTRAINT CK_aen_operacion CHECK (aen_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_aen_enc_codigo
    ON sgspi.aud_estandar_normativo_catalogo(enc_codigo, aen_fecha_cambio DESC);


-- [acn] Auditoría de [sgspi].[control_referencia_normativa] ([crn])
CREATE TABLE sgspi.aud_control_referencia_normativa (
    acn_codigo                BIGINT             IDENTITY (1, 1) NOT NULL,
    crn_codigo                SMALLINT           NOT NULL,
    enc_codigo                SMALLINT           NOT NULL,
    acn_rol_privacidad_pii    NVARCHAR (20)      NULL,
    acn_identificador_control NVARCHAR (20)      NOT NULL,
    acn_nombre_control        NVARCHAR (200)     NOT NULL,
    acn_objetivo_requisito    NVARCHAR (1500)    NOT NULL,
    acn_estado                BIT                NOT NULL,
    per_codigo                INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    acn_operacion             CHAR (1)           CONSTRAINT DF_acn_operacion DEFAULT 'U' NOT NULL,
    acn_usuario_bd            SYSNAME            CONSTRAINT DF_acn_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    acn_fecha_cambio          DATETIMEOFFSET (0) CONSTRAINT DF_acn_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_acn_aud_control_referencia_normativa PRIMARY KEY CLUSTERED (acn_codigo),
    CONSTRAINT FK_acn_control_referencia_normativa FOREIGN KEY (crn_codigo) REFERENCES sgspi.control_referencia_normativa (crn_codigo),
    CONSTRAINT CK_acn_operacion CHECK (acn_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_acn_crn_codigo
    ON sgspi.aud_control_referencia_normativa(crn_codigo, acn_fecha_cambio DESC);


-- [acc] Auditoría de [sgspi].[atributo_control_catalogo] ([aac])
CREATE TABLE sgspi.aud_atributo_control_catalogo (
    acc_codigo        BIGINT             IDENTITY (1, 1) NOT NULL,
    aac_codigo        SMALLINT           NOT NULL,
    acc_tipo_atributo NVARCHAR (30)      NOT NULL,
    acc_valor         NVARCHAR (60)      NOT NULL,
    acc_estado        BIT                NOT NULL,
    per_codigo        INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    acc_operacion     CHAR (1)           CONSTRAINT DF_acc_operacion DEFAULT 'U' NOT NULL,
    acc_usuario_bd    SYSNAME            CONSTRAINT DF_acc_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    acc_fecha_cambio  DATETIMEOFFSET (0) CONSTRAINT DF_acc_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_acc_aud_atributo_control_catalogo PRIMARY KEY CLUSTERED (acc_codigo),
    CONSTRAINT FK_acc_atributo_control_catalogo FOREIGN KEY (aac_codigo) REFERENCES sgspi.atributo_control_catalogo (aac_codigo),
    CONSTRAINT CK_acc_operacion CHECK (acc_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_acc_aac_codigo
    ON sgspi.aud_atributo_control_catalogo(aac_codigo, acc_fecha_cambio DESC);


-- [aca] Auditoría de [sgspi].[control_referencia_normativa_atributo] ([cra])
CREATE TABLE sgspi.aud_control_referencia_normativa_atributo (
    aca_codigo       BIGINT             IDENTITY (1, 1) NOT NULL,
    crn_codigo       SMALLINT           NOT NULL,
    aac_codigo       SMALLINT           NOT NULL,
    aca_estado       BIT                NOT NULL,
    per_codigo       INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    aca_operacion    CHAR (1)           CONSTRAINT DF_aca_operacion DEFAULT 'U' NOT NULL,
    aca_usuario_bd   SYSNAME            CONSTRAINT DF_aca_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    aca_fecha_cambio DATETIMEOFFSET (0) CONSTRAINT DF_aca_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_aca_aud_control_referencia_normativa_atributo PRIMARY KEY CLUSTERED (aca_codigo),
    CONSTRAINT FK_aca_control_referencia_normativa_atributo FOREIGN KEY (crn_codigo, aac_codigo) REFERENCES sgspi.control_referencia_normativa_atributo (crn_codigo, aac_codigo),
    CONSTRAINT CK_aca_operacion CHECK (aca_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_aca_crn_codigo_aac_codigo
    ON sgspi.aud_control_referencia_normativa_atributo(crn_codigo, aac_codigo, aca_fecha_cambio DESC);


-- [acp] Auditoría de [sgspi].[plan_tratamiento_control_referencia_normativa] ([ptc])
CREATE TABLE sgspi.aud_plan_tratamiento_control_referencia_normativa (
    acp_codigo       BIGINT             IDENTITY (1, 1) NOT NULL,
    plt_codigo       INT                NOT NULL,
    crn_codigo       SMALLINT           NOT NULL,
    acp_estado       BIT                NOT NULL,
    per_codigo       INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    acp_operacion    CHAR (1)           CONSTRAINT DF_acp_operacion DEFAULT 'U' NOT NULL,
    acp_usuario_bd   SYSNAME            CONSTRAINT DF_acp_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    acp_fecha_cambio DATETIMEOFFSET (0) CONSTRAINT DF_acp_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_acp_aud_plan_tratamiento_control_referencia_normativa PRIMARY KEY CLUSTERED (acp_codigo),
    CONSTRAINT FK_acp_plan_tratamiento_control_referencia_normativa FOREIGN KEY (plt_codigo, crn_codigo) REFERENCES sgspi.plan_tratamiento_control_referencia_normativa (plt_codigo, crn_codigo),
    CONSTRAINT CK_acp_operacion CHECK (acp_operacion IN ('I', 'U'))
);

CREATE NONCLUSTERED INDEX IX_acp_plt_codigo_crn_codigo
    ON sgspi.aud_plan_tratamiento_control_referencia_normativa(plt_codigo, crn_codigo, acp_fecha_cambio DESC);


-- [aae] Auditoría de [sgspi].[evaluacion_aplicabilidad_control] ([eac])
CREATE TABLE sgspi.aud_evaluacion_aplicabilidad_control (
    aae_codigo                      BIGINT             IDENTITY (1, 1) NOT NULL,
    eac_codigo                      INT                NOT NULL,
    pev_codigo                      SMALLINT           NOT NULL,
    crn_codigo                      SMALLINT           NOT NULL,
    aae_es_aplicable                BIT                NOT NULL,
    aae_justificacion_aplicabilidad NVARCHAR (1000)    NULL,
    aae_documento_soporte_normativo NVARCHAR (500)     NULL,
    car_codigo                      INT                NULL,
    pdc_codigo                      SMALLINT           NULL,
    aae_evidencia_objetiva_esperada NVARCHAR (500)     NULL,
    aae_fase_implementacion         NVARCHAR (20)      NULL,
    aae_observaciones_auditoria     NVARCHAR (1000)    NULL,
    aae_fecha_actualizacion         DATETIMEOFFSET (0) NOT NULL,
    aae_estado                      BIT                NOT NULL,
    per_codigo                      INT                NOT NULL, -- Quién hizo el cambio ([dbo].[persona])
    aae_operacion                   CHAR (1)           CONSTRAINT DF_aae_operacion DEFAULT 'U' NOT NULL,
    aae_usuario_bd                  SYSNAME            CONSTRAINT DF_aae_usuario_bd DEFAULT ORIGINAL_LOGIN() NOT NULL,
    aae_fecha_cambio                DATETIMEOFFSET (0) CONSTRAINT DF_aae_fecha_cambio DEFAULT SYSDATETIMEOFFSET() NOT NULL,
    CONSTRAINT PK_aae_aud_evaluacion_aplicabilidad_control PRIMARY KEY CLUSTERED (aae_codigo),
    CONSTRAINT FK_aae_evaluacion_aplicabilidad_control FOREIGN KEY (eac_codigo) REFERENCES sgspi.evaluacion_aplicabilidad_control (eac_codigo),
    CONSTRAINT CK_aae_operacion CHECK (aae_operacion IN ('I', 'U'))
)
WITH (DATA_COMPRESSION = PAGE);

CREATE NONCLUSTERED INDEX IX_aae_eac_codigo
    ON sgspi.aud_evaluacion_aplicabilidad_control(eac_codigo, aae_fecha_cambio DESC) WITH (DATA_COMPRESSION = PAGE);

CREATE NONCLUSTERED INDEX IX_aae_per_codigo
    ON sgspi.aud_evaluacion_aplicabilidad_control(per_codigo) WITH (DATA_COMPRESSION = PAGE);


-- Clasificación de sensibilidad (SQL Server 2019): queda en sys.sensitivity_classifications y en cada evento de SQL Server Audit
ADD SENSITIVITY CLASSIFICATION TO
    sgspi.evento_incertidumbre_activo.eia_condicion_vulnerabilidad, sgspi.evento_incertidumbre_activo.eia_controles_existentes, sgspi.evento_incertidumbre_activo.eia_fuente_generadora, sgspi.evento_incertidumbre_activo.eia_efecto_consecuencia, sgspi.aud_evento_incertidumbre_activo.aea_condicion_vulnerabilidad, sgspi.aud_evento_incertidumbre_activo.aea_controles_existentes, sgspi.aud_evento_incertidumbre_activo.aea_fuente_generadora, sgspi.aud_evento_incertidumbre_activo.aea_efecto_consecuencia
    WITH (LABEL = 'Confidencial', INFORMATION_TYPE = 'Vulnerabilidades de seguridad', RANK = HIGH);

ADD SENSITIVITY CLASSIFICATION TO
    sgspi.activo_informacion.aci_categoria_dato_personal, sgspi.activo_informacion.aci_finalidad_recoleccion_pii, sgspi.aud_activo_informacion.aai_categoria_dato_personal, sgspi.aud_activo_informacion.aai_finalidad_recoleccion_pii
    WITH (LABEL = 'Confidencial', INFORMATION_TYPE = 'Datos personales (Ley 1581)', RANK = HIGH);

ADD SENSITIVITY CLASSIFICATION TO
    sgspi.plan_tratamiento.plt_presupuesto_estimado_cop, sgspi.aud_plan_tratamiento.apt_presupuesto_estimado_cop
    WITH (LABEL = 'Confidencial', INFORMATION_TYPE = 'Financiero', RANK = MEDIUM);

ADD SENSITIVITY CLASSIFICATION TO
    sgspi.seguimiento_actividad.sga_uri_almacenamiento_evidencia, sgspi.aud_seguimiento_actividad.asa_uri_almacenamiento_evidencia
    WITH (LABEL = 'Confidencial', INFORMATION_TYPE = 'Evidencias de control', RANK = MEDIUM);

ADD SENSITIVITY CLASSIFICATION TO
    sgspi.evaluacion_aplicabilidad_control.eac_observaciones_auditoria, sgspi.aud_evaluacion_aplicabilidad_control.aae_observaciones_auditoria
    WITH (LABEL = 'Confidencial', INFORMATION_TYPE = 'Auditoria interna', RANK = MEDIUM);


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
-- CONCAT con literales Unicode (N''); consulta solo administrativos y docentes (UNION ALL sin Sort)
CREATE OR ALTER VIEW sgspi.vw_usuario_rol_alcance_sgspi
AS
SELECT p.per_codigo,
       -- sin per_identificacion ni per_email_interno: la vista la lee todo sgspi_rol_base [AP-02]
       CONCAT(RTRIM(ISNULL(p.per_nombre, N'')), N' ', RTRIM(ISNULL(p.per_apellido, N''))) AS per_nombre_completo,
       ug.usg_codigo,
       ug.usg_usuario AS uge_codigo_usuario,
       g.gru_codigo,
       g.gru_id AS gru_rol_codigo,
       g.gru_nombre AS gru_rol_seguridad,
       u.uaa_codigo,
       u.uaa_nombre AS uaa_dependencia,
       pr.pri_codigo AS pri_codigo,
       pr.pri_nombre AS pri_nombre_proceso
FROM   dbo.usuario_grupo AS ug
       INNER JOIN
       dbo.grupo AS g
       ON g.gru_codigo = ug.usg_grupo
       INNER JOIN
       dbo.uaa AS u
       ON u.uaa_codigo = ug.usg_uaa
       INNER JOIN
       (SELECT uid,
               up,
               sys,
               state
        FROM   dbo.usuario_administrativos
        UNION ALL
        SELECT uid,
               up,
               sys,
               state
        FROM   dbo.usuario_docentes) AS ugen
       ON ugen.uid = ug.usg_usuario
       INNER JOIN
       dbo.persona AS p
       ON p.per_codigo = ugen.up
       LEFT OUTER JOIN
       sgspi.proceso_institucional_uaa AS piu
       ON piu.uaa_codigo = u.uaa_codigo
          AND piu.piu_estado = 1 -- [AP-22]
       LEFT OUTER JOIN
       sgspi.proceso_institucional AS pr
       ON pr.pri_codigo = piu.pri_codigo
          AND pr.pri_estado = 1 -- [AP-22]
WHERE  ug.usg_estado = 1
       AND g.gru_estado = 1
       AND ugen.state = 1
       AND ugen.up IS NOT NULL
       AND ugen.sys IS NOT NULL
       AND p.per_estado = 1
       AND u.uaa_estado = 1
       AND g.gru_id LIKE 'SGSPI[_]%'; -- D5: grupos del SGSPI por gru_id (estándar dbo.grupo USCO)


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- 6.0b Vista de Autenticación Administrativa SGSPI (estándar LoginDS de Spring Boot USCO; lectura exclusiva de sgspi_rol_login)
CREATE OR ALTER VIEW sgspi.vw_sgspi_admin_login
AS
SELECT ug.usg_codigo,
       ug.usg_usuario,
       ug.usg_grupo,
       ug.usg_uaa,
       ug.usg_estado,
       g.gru_codigo,
       g.gru_nombre,
       g.gru_id,
       u.uid,
       u.up,
       u.us,
       u.sys,
       u.uwd2,
       u.state
FROM   dbo.usuario_grupo AS ug
       INNER JOIN
       dbo.grupo AS g
       ON g.gru_codigo = ug.usg_grupo
       INNER JOIN
       (SELECT uid,
               up,
               us,
               sys,
               uwd2,
               state
        FROM   dbo.usuario_administrativos
        UNION ALL
        SELECT uid,
               up,
               us,
               sys,
               uwd2,
               state
        FROM   dbo.usuario_docentes) AS u
       ON u.uid = ug.usg_usuario
WHERE  ug.usg_estado = 1
       AND g.gru_estado = 1
       AND g.gru_id LIKE 'SGSPI[_]%'
       AND u.state = 1
       AND u.up IS NOT NULL
       AND u.sys IS NOT NULL;


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [AP-03] [C2] Persona de la sesión fail-closed (ORIGINAL_LOGIN() -> dbo.usuario_administrativos/dbo.usuario_docentes.sys):
-- devuelve 0 filas (disparando error 50017) si el login no existe activo o mapea a más de una persona distinta (COUNT(DISTINCT up) <> 1).
CREATE OR ALTER FUNCTION sgspi.ufn_persona_sesion
( )
RETURNS TABLE 
AS
RETURN 
    SELECT MIN(u.up) AS per_codigo
    FROM   (SELECT up,
                   sys,
                   state
            FROM   dbo.usuario_administrativos
            UNION ALL
            SELECT up,
                   sys,
                   state
            FROM   dbo.usuario_docentes) AS u
    WHERE  u.sys = CONVERT (VARCHAR (128), ORIGINAL_LOGIN()) -- si [sys] es VARCHAR, la columna no se convierte y usa IX_*_sys
           AND u.sys IS NOT NULL
           AND u.up IS NOT NULL
           AND u.state = 1
    HAVING COUNT(DISTINCT u.up) = 1


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [A3] Una fila si la sesión puede escribir en el proceso. Con @pri_codigo NULL solo hay fila si la sesión es transversal.
-- Consulta directa a piu + dbo.usuario_grupo + dbo.grupo + usuario_administrativos/usuario_docentes (sin vw_usuario_rol_alcance_sgspi
-- ni joins innecesarios a persona/uaa/pri), filtrando por sys para buscar por índice IX_*_sys.
CREATE OR ALTER FUNCTION sgspi.ufn_proceso_en_alcance
(@pri_codigo INT, @per_actor INT)
RETURNS TABLE 
AS
RETURN 
    SELECT 1 AS permitido
    WHERE  ISNULL(IS_MEMBER(N'db_owner'), 0) = 1
           OR ISNULL(IS_MEMBER(N'sgspi_rol_oficial_seguridad_privacidad'), 0) = 1
           OR ISNULL(IS_MEMBER(N'sgspi_rol_comite_direccion'), 0) = 1
           OR ISNULL(IS_MEMBER(N'sgspi_rol_auditor_control'), 0) = 1
           OR (@per_actor IS NOT NULL
               AND @pri_codigo IS NOT NULL
               AND EXISTS (SELECT 1
                           FROM   sgspi.proceso_institucional_uaa AS piu
                                  INNER JOIN
                                  dbo.usuario_grupo AS ug
                                  ON ug.usg_uaa = piu.uaa_codigo
                                     AND ug.usg_estado = 1
                                  INNER JOIN
                                  dbo.grupo AS g
                                  ON g.gru_codigo = ug.usg_grupo
                                     AND g.gru_estado = 1
                                     AND g.gru_id LIKE 'SGSPI[_]%'
                                  INNER JOIN
                                  (SELECT uid,
                                          up,
                                          sys,
                                          state
                                   FROM   dbo.usuario_administrativos
                                   UNION ALL
                                   SELECT uid,
                                          up,
                                          sys,
                                          state
                                   FROM   dbo.usuario_docentes) AS u
                                  ON u.uid = ug.usg_usuario
                                     AND u.sys = CONVERT (VARCHAR (128), ORIGINAL_LOGIN())
                                     AND u.up = @per_actor
                                     AND u.state = 1
                                     AND u.sys IS NOT NULL
                           WHERE  piu.pri_codigo = @pri_codigo
                                  AND piu.piu_estado = 1))



GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [A3] Una fila si la sesión puede escribir en el activo: es transversal (en activos también el gestor documental), el activo
-- es de una de sus UAA o está asociado (aip activa) a uno de sus procesos. Con @aci_codigo NULL solo cuenta la UAA.
CREATE OR ALTER FUNCTION sgspi.ufn_activo_en_alcance
(@aci_codigo INT, @uaa_codigo INT, @per_actor INT)
RETURNS TABLE 
AS
RETURN 
    SELECT 1 AS permitido
    WHERE  EXISTS (SELECT 1
                   FROM   sgspi.ufn_proceso_en_alcance(NULL, NULL))
           OR ISNULL(IS_MEMBER(N'sgspi_rol_gestor_documental'), 0) = 1 -- D9: avala y completa todos los activos documentales
           OR (@per_actor IS NOT NULL
               AND EXISTS (SELECT 1
                           FROM   dbo.usuario_grupo AS ug
                                  INNER JOIN
                                  dbo.grupo AS g
                                  ON g.gru_codigo = ug.usg_grupo
                                     AND g.gru_estado = 1
                                     AND g.gru_id LIKE 'SGSPI[_]%'
                                  INNER JOIN
                                  (SELECT uid,
                                          up,
                                          sys,
                                          state
                                   FROM   dbo.usuario_administrativos
                                   UNION ALL
                                   SELECT uid,
                                          up,
                                          sys,
                                          state
                                   FROM   dbo.usuario_docentes) AS u
                                  ON u.uid = ug.usg_usuario
                                     AND u.sys = CONVERT (VARCHAR (128), ORIGINAL_LOGIN())
                                     AND u.up = @per_actor
                                     AND u.state = 1
                                     AND u.sys IS NOT NULL
                           WHERE  ug.usg_estado = 1
                                  AND (ug.usg_uaa = @uaa_codigo
                                       OR (@aci_codigo IS NOT NULL
                                           AND EXISTS (SELECT 1
                                                       FROM   sgspi.proceso_institucional_uaa AS piu
                                                              INNER JOIN
                                                              sgspi.activo_informacion_proceso_institucional AS aip
                                                              ON aip.pri_codigo = piu.pri_codigo
                                                                 AND aip.aci_codigo = @aci_codigo
                                                                 AND aip.aip_estado = 1
                                                       WHERE  piu.uaa_codigo = ug.usg_uaa
                                                              AND piu.piu_estado = 1)))))



GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [A2][A3] Predicado RLS exclusivo para [aip] sin referencia a [aci] ni [aip] (evita recursión circular con ufn_activo_en_alcance).
CREATE OR ALTER FUNCTION sgspi.ufn_rls_alcance_aip
(@pri_codigo INT)
RETURNS TABLE 
AS
RETURN 
    SELECT 1 AS permitido
    WHERE  EXISTS (SELECT 1
                   FROM   sgspi.ufn_proceso_en_alcance(NULL, NULL))
           OR ISNULL(IS_MEMBER(N'sgspi_rol_gestor_documental'), 0) = 1
           OR (ISNULL(IS_MEMBER(N'sgspi_rol_consulta'), 0) = 1
               AND ISNULL(IS_MEMBER(N'sgspi_rol_base'), 0) = 0)
           OR (@pri_codigo IS NOT NULL
               AND EXISTS (SELECT 1
                           FROM   sgspi.ufn_persona_sesion() AS ps
                                  CROSS APPLY sgspi.ufn_proceso_en_alcance(@pri_codigo, ps.per_codigo) AS a))



GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- Predicados RLS en lectura [AP-02]: sin SCHEMABINDING porque las tablas corporativas de [dbo] y vw_usuario_rol_alcance_sgspi no tienen SCHEMABINDING (SQL Server exige SCHEMABINDING = OFF en la política y GRANT SELECT sobre estas funciones).
-- sgspi_rol_consulta solo entra si NO pertenece a sgspi_rol_base (solo lee sus 5 vistas en lista blanca; un actor en sgspi_rol_base no puede escalar).
CREATE OR ALTER FUNCTION sgspi.ufn_rls_alcance_proceso
(@pri_codigo INT, @rpi_codigo INT, @eia_codigo INT, @plt_codigo INT, @act_codigo INT)
RETURNS TABLE 
AS
RETURN 
    SELECT 1 AS permitido
    WHERE  EXISTS (SELECT 1
                   FROM   sgspi.ufn_proceso_en_alcance(NULL, NULL))
           OR (ISNULL(IS_MEMBER(N'sgspi_rol_consulta'), 0) = 1
               AND ISNULL(IS_MEMBER(N'sgspi_rol_base'), 0) = 0)
           OR (@pri_codigo IS NOT NULL
               AND EXISTS (SELECT 1
                           FROM   sgspi.ufn_persona_sesion() AS ps
                                  CROSS APPLY sgspi.ufn_proceso_en_alcance(@pri_codigo, ps.per_codigo) AS a))
           OR (@rpi_codigo IS NOT NULL
               AND EXISTS (SELECT 1
                           FROM   sgspi.ufn_persona_sesion() AS ps
                                  INNER JOIN
                                  sgspi.requisito_parte_interesada_proceso_institucional AS rpp
                                  ON rpp.rpi_codigo = @rpi_codigo
                                     AND rpp.rpp_estado = 1
                                  CROSS APPLY sgspi.ufn_proceso_en_alcance(rpp.pri_codigo, ps.per_codigo) AS a))
           OR (@eia_codigo IS NOT NULL
               AND EXISTS (SELECT 1
                           FROM   sgspi.ufn_persona_sesion() AS ps
                                  INNER JOIN
                                  sgspi.evento_incertidumbre_activo AS eia
                                  ON eia.eia_codigo = @eia_codigo
                                  CROSS APPLY sgspi.ufn_proceso_en_alcance(eia.pri_codigo, ps.per_codigo) AS a))
           OR (@plt_codigo IS NOT NULL
               AND EXISTS (SELECT 1
                           FROM   sgspi.ufn_persona_sesion() AS ps
                                  INNER JOIN
                                  sgspi.plan_tratamiento AS plt
                                  ON plt.plt_codigo = @plt_codigo
                                  INNER JOIN
                                  sgspi.evento_incertidumbre_activo AS eia
                                  ON eia.eia_codigo = plt.eia_codigo
                                  CROSS APPLY sgspi.ufn_proceso_en_alcance(eia.pri_codigo, ps.per_codigo) AS a))
           OR (@act_codigo IS NOT NULL
               AND EXISTS (SELECT 1
                           FROM   sgspi.ufn_persona_sesion() AS ps
                                  INNER JOIN
                                  sgspi.actividad_tratamiento AS act
                                  ON act.act_codigo = @act_codigo
                                  INNER JOIN
                                  sgspi.plan_tratamiento AS plt
                                  ON plt.plt_codigo = act.plt_codigo
                                  INNER JOIN
                                  sgspi.evento_incertidumbre_activo AS eia
                                  ON eia.eia_codigo = plt.eia_codigo
                                  CROSS APPLY sgspi.ufn_proceso_en_alcance(eia.pri_codigo, ps.per_codigo) AS a))



GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
CREATE OR ALTER FUNCTION sgspi.ufn_rls_alcance_activo
(@aci_codigo INT, @uaa_codigo INT, @aci_codigo_padre INT, @sif_codigo INT)
RETURNS TABLE 
AS
RETURN 
    SELECT 1 AS permitido
    WHERE  EXISTS (SELECT 1
                   FROM   sgspi.ufn_activo_en_alcance(NULL, NULL, NULL))
           OR (ISNULL(IS_MEMBER(N'sgspi_rol_consulta'), 0) = 1
               AND ISNULL(IS_MEMBER(N'sgspi_rol_base'), 0) = 0)
           OR (@aci_codigo IS NOT NULL
               AND EXISTS (SELECT 1
                           FROM   sgspi.ufn_persona_sesion() AS ps
                                  CROSS APPLY sgspi.ufn_activo_en_alcance(@aci_codigo, @uaa_codigo, ps.per_codigo) AS a))
           OR (@aci_codigo_padre IS NOT NULL
               AND EXISTS (SELECT 1
                           FROM   sgspi.ufn_persona_sesion() AS ps
                                  INNER JOIN
                                  sgspi.activo_informacion AS aci
                                  ON aci.aci_codigo = @aci_codigo_padre
                                  CROSS APPLY sgspi.ufn_activo_en_alcance(aci.aci_codigo, aci.uaa_codigo, ps.per_codigo) AS a))
           OR (@sif_codigo IS NOT NULL
               AND EXISTS (SELECT 1
                           FROM   sgspi.ufn_persona_sesion() AS ps
                                  INNER JOIN
                                  sgspi.sistema_informacion_ficha AS sif
                                  ON sif.sif_codigo = @sif_codigo
                                  INNER JOIN
                                  sgspi.activo_informacion AS aci
                                  ON aci.aci_codigo = sif.aci_codigo
                                  CROSS APPLY sgspi.ufn_activo_en_alcance(aci.aci_codigo, aci.uaa_codigo, ps.per_codigo) AS a))



GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [AP-24] [B5] Helper de consecutivos sin bloqueos de rango (HOLDLOCK): serializa con sp_getapplock por llave de secuencia.
-- WITH EXECUTE AS OWNER asegura consecutivos globales únicos por vigencia/plan aunque RLS oculte registros de otras UAA, sin exponer datos.
CREATE OR ALTER PROCEDURE sgspi.usp_siguiente_consecutivo
@dominio NVARCHAR (10), @ambito_codigo INT, @naturaleza NVARCHAR (15)=NULL, @siguiente_numero SMALLINT OUTPUT
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF @@TRANCOUNT = 0
        THROW 50023, N'sgspi.usp_siguiente_consecutivo debe ejecutarse dentro de una transacción explícita junto con el INSERT correspondiente.', 1;
    DECLARE @dom AS NVARCHAR (10) = UPPER(TRIM(ISNULL(@dominio, N'')));
    DECLARE @nat AS NVARCHAR (15) = CASE WHEN @naturaleza IS NULL THEN NULL ELSE UPPER(TRIM(@naturaleza)) END;
    IF @ambito_codigo IS NULL OR @ambito_codigo < 1
        THROW 50014, N'Parámetro [@ambito_codigo] inválido en [sgspi].[usp_siguiente_consecutivo].', 1;
    IF @dom = N'ACF'
       AND ISNULL(@nat, N'') NOT IN (N'DEBILIDAD', N'FORTALEZA', N'AMENAZA', N'OPORTUNIDAD')
        THROW 50014, N'Naturaleza inválida para dominio ACF en [sgspi].[usp_siguiente_consecutivo].', 1;
    ELSE IF @dom = N'EIA'
            AND ISNULL(@nat, N'') NOT IN (N'RIESGO', N'OPORTUNIDAD')
        THROW 50014, N'Naturaleza inválida para dominio EIA en [sgspi].[usp_siguiente_consecutivo].', 1;
    ELSE IF @dom NOT IN (N'ACF', N'EIA', N'ACT')
        THROW 50014, N'Dominio inválido en [sgspi].[usp_siguiente_consecutivo] (valores permitidos: ACF, EIA, ACT).', 1;
    DECLARE @lock_res AS NVARCHAR (80) = CONCAT(N'sgspi:seq:', @dom, N':', @ambito_codigo, CASE WHEN @nat IS NOT NULL THEN CONCAT(N':', @nat) ELSE N'' END);
    DECLARE @lock_rc AS INT;
    EXECUTE @lock_rc = sys.sp_getapplock @Resource = @lock_res, @LockMode = 'Exclusive', @LockOwner = 'Transaction', @LockTimeout = 10000;
    IF @lock_rc < 0
        THROW 50023, N'Tiempo de espera agotado al adquirir bloqueo de secuencia en [sgspi].[usp_siguiente_consecutivo].', 1;
    DECLARE @next AS INT;
    IF @dom = N'ACF'
        SELECT @next = ISNULL(MAX(acf_numero_factor), 0) + 1
        FROM   sgspi.analisis_contexto_factor
        WHERE  pev_codigo = @ambito_codigo
               AND acf_naturaleza_factor = @nat
               AND acf_estado = 1;
    ELSE IF @dom = N'EIA'
        SELECT @next = ISNULL(MAX(eia_numero_evento), 0) + 1
        FROM   sgspi.evento_incertidumbre_activo
        WHERE  pev_codigo = @ambito_codigo
               AND eia_naturaleza_evento = @nat
               AND eia_estado = 1;
    ELSE
        SELECT @next = ISNULL(MAX(act_numero_orden), 0) + 1
        FROM   sgspi.actividad_tratamiento
        WHERE  plt_codigo = @ambito_codigo
               AND act_estado = 1;
    IF (@dom = N'EIA' AND @next > 9999)
       OR @next > 32767
        THROW 50020, N'Se alcanzó el límite máximo de consecutivo permitido para el dominio en [sgspi].[usp_siguiente_consecutivo].', 1;
    SET @siguiente_numero = CONVERT (SMALLINT, @next);
END


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
                                                                    (f) archivan after-image de las altas ('I') y modificaciones ('U') en aud_<tabla> (AP-01/C2); en las tablas sin estos triggers lo hace TR_<acr>_auditoria (5.10.9b).
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
                                                    AND efc.efc_identificador = i.acf_fase_registro
                                                    AND efc.efc_es_inicial = 1
                                                    AND efc.efc_estado = 1))
               THROW 50014, N'Estado inicial inválido: un registro nuevo de [sgspi].[analisis_contexto_factor] solo puede crearse en el estado inicial del flujo.', 1;
           -- [AP-03] Persona de la sesión: crea los registros nuevos y firma las aprobaciones
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona activa (usuario_administrativos/usuario_docentes.sys) para ORIGINAL_LOGIN().', 1;
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
                             OUTER APPLY sgspi.ufn_proceso_en_alcance(x.pri_codigo, @per_actor) AS a
                      WHERE  a.permitido IS NULL)
               THROW 50021, N'Fuera de alcance: el proceso no está en las UAA del usuario en [sgspi].[analisis_contexto_factor].', 1;
           -- D7: no se crean registros ni se mueven a una vigencia cerrada o histórica
           IF EXISTS (SELECT 1
                      FROM   inserted AS i
                             INNER JOIN
                             sgspi.periodo_vigencia AS pev
                             ON pev.pev_codigo = i.pev_codigo
                      WHERE  pev.pev_fase_vigencia IN (N'CERRADA', N'HISTORICA')
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
                              WHERE  (i.acf_fase_registro = d.acf_fase_registro
                                      AND EXISTS (SELECT 1
                                                  FROM   sgspi.estado_flujo_catalogo AS efc
                                                  WHERE  efc.efc_dominio = N'ACF'
                                                         AND efc.efc_identificador = d.acf_fase_registro
                                                         AND (efc.efc_permite_edicion = 0
                                                              OR efc.efc_estado = 0)))
                                     OR (i.acf_fase_registro <> d.acf_fase_registro
                                         AND NOT EXISTS (SELECT 1
                                                         FROM   sgspi.transicion_estado_flujo AS tef
                                                                INNER JOIN
                                                                sgspi.estado_flujo_catalogo AS efc_dest
                                                                ON efc_dest.efc_dominio = tef.efc_dominio
                                                                   AND efc_dest.efc_identificador = tef.efc_identificador_destino
                                                         WHERE  tef.efc_dominio = N'ACF'
                                                                AND tef.efc_identificador_origen = d.acf_fase_registro
                                                                AND tef.efc_identificador_destino = i.acf_fase_registro
                                                                AND tef.tef_estado = 1
                                                                AND efc_dest.efc_estado = 1
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
                                     i.acf_estado
                              FROM   inserted AS i
                                     INNER JOIN
                                     deleted AS d
                                     ON d.acf_codigo = i.acf_codigo
                              WHERE  i.acf_fase_registro <> d.acf_fase_registro
                                     AND EXISTS (SELECT 1
                                                 FROM   sgspi.estado_flujo_catalogo AS efc
                                                 WHERE  efc.efc_dominio = N'ACF'
                                                        AND efc.efc_identificador IN (d.acf_fase_registro, i.acf_fase_registro)
                                                        AND (efc.efc_permite_edicion = 0
                                                             OR efc.efc_estado = 0))
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
                                     d.acf_estado
                              FROM   deleted AS d
                                     INNER JOIN
                                     inserted AS i
                                     ON i.acf_codigo = d.acf_codigo
                              WHERE  i.acf_fase_registro <> d.acf_fase_registro
                                     AND EXISTS (SELECT 1
                                                 FROM   sgspi.estado_flujo_catalogo AS efc
                                                 WHERE  efc.efc_dominio = N'ACF'
                                                        AND efc.efc_identificador IN (d.acf_fase_registro, i.acf_fase_registro)
                                                        AND (efc.efc_permite_edicion = 0
                                                             OR efc.efc_estado = 0)))
                       THROW 50011, N'No se permite modificar el contenido durante una transición de estado en [sgspi].[analisis_contexto_factor].', 1;
                    -- [AP-01] [C2] Detecta filas con cambio real, actualiza fecha/firma en 1 UPDATE y archiva after-image ('U')
                    DECLARE @cambiadas TABLE (
                        acf_codigo INT PRIMARY KEY);
                    INSERT INTO @cambiadas (
                        acf_codigo
                    )
                    SELECT i.acf_codigo
                    FROM   inserted AS i
                           INNER JOIN
                           deleted AS d
                           ON d.acf_codigo = i.acf_codigo
                    WHERE  EXISTS (SELECT i.pev_codigo,
                                          i.pri_codigo,
                                          i.fec_codigo,
                                          i.acf_naturaleza_factor,
                                          i.acf_numero_factor,
                                          i.acf_descripcion_situacion,
                                          i.acf_valor_prioridad,
                                          i.acf_impacto_sistema_gestion,
                                          i.acf_accion_propuesta,
                                          i.acf_fase_registro,
                                          i.per_codigo_creador,
                                          i.per_codigo_aprobador,
                                          i.acf_fecha_actualizacion,
                                          i.acf_estado
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
                                          d.acf_fase_registro,
                                          d.per_codigo_creador,
                                          d.per_codigo_aprobador,
                                          d.acf_fecha_actualizacion,
                                          d.acf_estado);
                    DECLARE @ahora AS DATETIMEOFFSET (0) = SYSDATETIMEOFFSET();
                    DECLARE @actualizar_fecha AS BIT = CASE WHEN UPDATE (acf_fecha_actualizacion) THEN 0 ELSE 1 END;
                    IF EXISTS (SELECT 1
                               FROM   @cambiadas)
                        BEGIN
                            UPDATE t
                            SET    t.acf_fecha_actualizacion = CASE WHEN @actualizar_fecha = 1 THEN @ahora ELSE t.acf_fecha_actualizacion END, -- [AP-12]
                                   t.per_codigo_aprobador    = CASE WHEN d.acf_fase_registro <> i.acf_fase_registro
                                                                         AND i.acf_fase_registro = N'VIGENTE' THEN @per_actor WHEN d.acf_fase_registro <> i.acf_fase_registro
                                                                                                                                     AND ((d.acf_fase_registro = N'VIGENTE'
                                                                                                                                           AND i.acf_fase_registro <> N'HISTORICO')
                                                                                                                                          OR i.acf_fase_registro IN (N'OBSERVADO', N'BORRADOR')) THEN NULL ELSE t.per_codigo_aprobador END
                            FROM   sgspi.analisis_contexto_factor AS t
                                   INNER JOIN
                                   @cambiadas AS c
                                   ON c.acf_codigo = t.acf_codigo
                                   INNER JOIN
                                   inserted AS i
                                   ON i.acf_codigo = t.acf_codigo
                                   INNER JOIN
                                   deleted AS d
                                   ON d.acf_codigo = i.acf_codigo
                            WHERE  @actualizar_fecha = 1
                                   OR (d.acf_fase_registro <> i.acf_fase_registro
                                       AND (i.acf_fase_registro = N'VIGENTE'
                                            OR (d.acf_fase_registro = N'VIGENTE'
                                                AND i.acf_fase_registro <> N'HISTORICO')
                                            OR i.acf_fase_registro IN (N'OBSERVADO', N'BORRADOR')));
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
                                aaf_fase_registro,
                                per_codigo_creador,
                                per_codigo_aprobador,
                                aaf_fecha_actualizacion,
                                aaf_estado,
                                per_codigo,
                                aaf_operacion,
                                aaf_usuario_bd,
                                aaf_fecha_cambio
                            )
                            SELECT t.acf_codigo,
                                   t.pev_codigo,
                                   t.pri_codigo,
                                   t.fec_codigo,
                                   t.acf_naturaleza_factor,
                                   t.acf_numero_factor,
                                   t.acf_descripcion_situacion,
                                   t.acf_valor_prioridad,
                                   t.acf_impacto_sistema_gestion,
                                   t.acf_accion_propuesta,
                                   t.acf_fase_registro,
                                   t.per_codigo_creador,
                                   t.per_codigo_aprobador,
                                   t.acf_fecha_actualizacion,
                                   t.acf_estado,
                                   @per_actor,
                                   'U',
                                   ORIGINAL_LOGIN(),
                                   @ahora
                            FROM   sgspi.analisis_contexto_factor AS t
                                   INNER JOIN
                                   @cambiadas AS c
                                   ON c.acf_codigo = t.acf_codigo;
                        END
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
                   aaf_fase_registro,
                   per_codigo_creador,
                   per_codigo_aprobador,
                   aaf_fecha_actualizacion,
                   aaf_estado,
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
                      i.acf_fase_registro,
                      i.per_codigo_creador,
                      i.per_codigo_aprobador,
                      i.acf_fecha_actualizacion,
                      i.acf_estado,
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
           -- [AP-24] [B3] Serializa el agregado por raíz (rpi) en orden ascendente para evitar deadlocks con TR_rpp
           DECLARE @lock_id AS INT = (SELECT MIN(rpi_codigo)
                                      FROM   (SELECT rpi_codigo
                                              FROM   inserted
                                              UNION
                                              SELECT rpi_codigo
                                              FROM   deleted) AS l), @lock_res AS NVARCHAR (60), @lock_rc AS INT;
           WHILE @lock_id IS NOT NULL
               BEGIN
                   SET @lock_res = CONCAT(N'sgspi:rpi:', @lock_id);
                   EXECUTE @lock_rc = sys.sp_getapplock @Resource = @lock_res, @LockMode = 'Exclusive', @LockOwner = 'Transaction', @LockTimeout = 10000;
                   IF @lock_rc < 0
                       THROW 50023, N'Tiempo de espera agotado al adquirir bloqueo del agregado [sgspi:rpi] en [sgspi].[requisito_parte_interesada].', 1;
                   SET @lock_id = (SELECT MIN(rpi_codigo)
                                   FROM   (SELECT rpi_codigo
                                           FROM   inserted
                                           UNION
                                           SELECT rpi_codigo
                                           FROM   deleted) AS l
                                   WHERE  l.rpi_codigo > @lock_id);
               END
           -- [AP-04] En INSERT el estado debe ser el inicial del dominio
           IF EXISTS (SELECT 1
                      FROM   inserted AS i
                      WHERE  NOT EXISTS (SELECT 1
                                         FROM   deleted AS d
                                         WHERE  d.rpi_codigo = i.rpi_codigo)
                             AND NOT EXISTS (SELECT 1
                                             FROM   sgspi.estado_flujo_catalogo AS efc
                                             WHERE  efc.efc_dominio = N'RPI'
                                                    AND efc.efc_identificador = i.rpi_fase_registro
                                                    AND efc.efc_es_inicial = 1
                                                    AND efc.efc_estado = 1))
               THROW 50014, N'Estado inicial inválido: un registro nuevo de [sgspi].[requisito_parte_interesada] solo puede crearse en el estado inicial del flujo.', 1;
           -- [AP-03] Persona de la sesión: crea los registros nuevos y firma las aprobaciones
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona activa (usuario_administrativos/usuario_docentes.sys) para ORIGINAL_LOGIN().', 1;
           -- [AP-15] Un creador ajeno anularía CK_rpi_sod_aprobador
           IF EXISTS (SELECT 1
                      FROM   inserted AS i
                      WHERE  NOT EXISTS (SELECT 1
                                         FROM   deleted AS d
                                         WHERE  d.rpi_codigo = i.rpi_codigo)
                             AND i.per_codigo_creador <> @per_actor)
               THROW 50019, N'Creador inválido: [per_codigo_creador] debe ser la persona de la sesión en [sgspi].[requisito_parte_interesada].', 1;
           -- [AP-02] D5: un rol no transversal solo escribe en rpi con al menos un proceso activo (rpp) en su alcance
           IF NOT EXISTS (SELECT 1
                          FROM   sgspi.ufn_proceso_en_alcance(NULL, @per_actor))
              AND EXISTS (SELECT 1
                          FROM   inserted AS i
                          WHERE  NOT EXISTS (SELECT 1
                                             FROM   sgspi.requisito_parte_interesada_proceso_institucional AS rpp
                                                    CROSS APPLY sgspi.ufn_proceso_en_alcance(rpp.pri_codigo, @per_actor) AS a
                                             WHERE  rpp.rpi_codigo = i.rpi_codigo
                                                    AND rpp.rpp_estado = 1))
               THROW 50021, N'Fuera de alcance: el requisito no tiene procesos activos en las UAA del usuario en [sgspi].[requisito_parte_interesada].', 1;
           -- D7: no se crean registros ni se mueven a una vigencia cerrada o histórica
           IF EXISTS (SELECT 1
                      FROM   inserted AS i
                             INNER JOIN
                             sgspi.periodo_vigencia AS pev
                             ON pev.pev_codigo = i.pev_codigo
                      WHERE  pev.pev_fase_vigencia IN (N'CERRADA', N'HISTORICA')
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
                              WHERE  (i.rpi_fase_registro = d.rpi_fase_registro
                                      AND EXISTS (SELECT 1
                                                  FROM   sgspi.estado_flujo_catalogo AS efc
                                                  WHERE  efc.efc_dominio = N'RPI'
                                                         AND efc.efc_identificador = d.rpi_fase_registro
                                                         AND (efc.efc_permite_edicion = 0
                                                              OR efc.efc_estado = 0)))
                                     OR (i.rpi_fase_registro <> d.rpi_fase_registro
                                         AND NOT EXISTS (SELECT 1
                                                         FROM   sgspi.transicion_estado_flujo AS tef
                                                                INNER JOIN
                                                                sgspi.estado_flujo_catalogo AS efc_dest
                                                                ON efc_dest.efc_dominio = tef.efc_dominio
                                                                   AND efc_dest.efc_identificador = tef.efc_identificador_destino
                                                         WHERE  tef.efc_dominio = N'RPI'
                                                                AND tef.efc_identificador_origen = d.rpi_fase_registro
                                                                AND tef.efc_identificador_destino = i.rpi_fase_registro
                                                                AND tef.tef_estado = 1
                                                                AND efc_dest.efc_estado = 1
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
                                     i.rpi_estado
                              FROM   inserted AS i
                                     INNER JOIN
                                     deleted AS d
                                     ON d.rpi_codigo = i.rpi_codigo
                              WHERE  i.rpi_fase_registro <> d.rpi_fase_registro
                                     AND EXISTS (SELECT 1
                                                 FROM   sgspi.estado_flujo_catalogo AS efc
                                                 WHERE  efc.efc_dominio = N'RPI'
                                                        AND efc.efc_identificador IN (d.rpi_fase_registro, i.rpi_fase_registro)
                                                        AND (efc.efc_permite_edicion = 0
                                                             OR efc.efc_estado = 0))
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
                                     d.rpi_estado
                              FROM   deleted AS d
                                     INNER JOIN
                                     inserted AS i
                                     ON i.rpi_codigo = d.rpi_codigo
                              WHERE  i.rpi_fase_registro <> d.rpi_fase_registro
                                     AND EXISTS (SELECT 1
                                                 FROM   sgspi.estado_flujo_catalogo AS efc
                                                 WHERE  efc.efc_dominio = N'RPI'
                                                        AND efc.efc_identificador IN (d.rpi_fase_registro, i.rpi_fase_registro)
                                                        AND (efc.efc_permite_edicion = 0
                                                             OR efc.efc_estado = 0)))
                       THROW 50011, N'No se permite modificar el contenido durante una transición de estado en [sgspi].[requisito_parte_interesada].', 1;
                    -- [B4] Cardinalidad mínima 1..N: aprobar a VIGENTE exige al menos un proceso asociado activo en [rpp]
                    IF EXISTS (SELECT 1
                               FROM   inserted AS i
                                      INNER JOIN
                                      deleted AS d
                                      ON d.rpi_codigo = i.rpi_codigo
                               WHERE  i.rpi_fase_registro = N'VIGENTE'
                                      AND d.rpi_fase_registro <> N'VIGENTE'
                                      AND NOT EXISTS (SELECT 1
                                                      FROM   sgspi.requisito_parte_interesada_proceso_institucional AS rpp
                                                      WHERE  rpp.rpi_codigo = i.rpi_codigo
                                                             AND rpp.rpp_estado = 1))
                        THROW 50020, N'Transición incompleta: VIGENTE exige al menos un proceso activo asociado en [sgspi].[requisito_parte_interesada_proceso_institucional].', 1;
                    -- [AP-01] [C2] Detecta filas con cambio real, actualiza fecha/firma en 1 UPDATE y archiva after-image ('U')
                    DECLARE @cambiadas TABLE (
                        rpi_codigo INT PRIMARY KEY);
                    INSERT INTO @cambiadas (
                        rpi_codigo
                    )
                    SELECT i.rpi_codigo
                    FROM   inserted AS i
                           INNER JOIN
                           deleted AS d
                           ON d.rpi_codigo = i.rpi_codigo
                    WHERE  EXISTS (SELECT i.pev_codigo,
                                          i.pai_codigo,
                                          i.rpi_necesidad_expectativa,
                                          i.rpi_valor_poder,
                                          i.rpi_valor_interes,
                                          i.rpi_valor_cumplimiento,
                                          i.rpi_mecanismo_seguimiento,
                                          i.rpi_fase_registro,
                                          i.per_codigo_creador,
                                          i.per_codigo_aprobador,
                                          i.rpi_fecha_actualizacion,
                                          i.rpi_estado
                                   EXCEPT
                                   SELECT d.pev_codigo,
                                          d.pai_codigo,
                                          d.rpi_necesidad_expectativa,
                                          d.rpi_valor_poder,
                                          d.rpi_valor_interes,
                                          d.rpi_valor_cumplimiento,
                                          d.rpi_mecanismo_seguimiento,
                                          d.rpi_fase_registro,
                                          d.per_codigo_creador,
                                          d.per_codigo_aprobador,
                                          d.rpi_fecha_actualizacion,
                                          d.rpi_estado);
                    DECLARE @ahora AS DATETIMEOFFSET (0) = SYSDATETIMEOFFSET();
                    DECLARE @actualizar_fecha AS BIT = CASE WHEN UPDATE (rpi_fecha_actualizacion) THEN 0 ELSE 1 END;
                    IF EXISTS (SELECT 1
                               FROM   @cambiadas)
                        BEGIN
                            UPDATE t
                            SET    t.rpi_fecha_actualizacion = CASE WHEN @actualizar_fecha = 1 THEN @ahora ELSE t.rpi_fecha_actualizacion END, -- [AP-12]
                                   t.per_codigo_aprobador    = CASE WHEN d.rpi_fase_registro <> i.rpi_fase_registro
                                                                         AND i.rpi_fase_registro = N'VIGENTE' THEN @per_actor WHEN d.rpi_fase_registro <> i.rpi_fase_registro
                                                                                                                                     AND ((d.rpi_fase_registro = N'VIGENTE'
                                                                                                                                           AND i.rpi_fase_registro <> N'HISTORICO')
                                                                                                                                          OR i.rpi_fase_registro IN (N'OBSERVADO', N'BORRADOR')) THEN NULL ELSE t.per_codigo_aprobador END
                            FROM   sgspi.requisito_parte_interesada AS t
                                   INNER JOIN
                                   @cambiadas AS c
                                   ON c.rpi_codigo = t.rpi_codigo
                                   INNER JOIN
                                   inserted AS i
                                   ON i.rpi_codigo = t.rpi_codigo
                                   INNER JOIN
                                   deleted AS d
                                   ON d.rpi_codigo = i.rpi_codigo
                            WHERE  @actualizar_fecha = 1
                                   OR (d.rpi_fase_registro <> i.rpi_fase_registro
                                       AND (i.rpi_fase_registro = N'VIGENTE'
                                            OR (d.rpi_fase_registro = N'VIGENTE'
                                                AND i.rpi_fase_registro <> N'HISTORICO')
                                            OR i.rpi_fase_registro IN (N'OBSERVADO', N'BORRADOR')));
                            INSERT INTO sgspi.aud_requisito_parte_interesada (
                                rpi_codigo,
                                pev_codigo,
                                pai_codigo,
                                ari_necesidad_expectativa,
                                ari_valor_poder,
                                ari_valor_interes,
                                ari_valor_cumplimiento,
                                ari_mecanismo_seguimiento,
                                ari_fase_registro,
                                per_codigo_creador,
                                per_codigo_aprobador,
                                ari_fecha_actualizacion,
                                ari_estado,
                                per_codigo,
                                ari_operacion,
                                ari_usuario_bd,
                                ari_fecha_cambio
                            )
                            SELECT t.rpi_codigo,
                                   t.pev_codigo,
                                   t.pai_codigo,
                                   t.rpi_necesidad_expectativa,
                                   t.rpi_valor_poder,
                                   t.rpi_valor_interes,
                                   t.rpi_valor_cumplimiento,
                                   t.rpi_mecanismo_seguimiento,
                                   t.rpi_fase_registro,
                                   t.per_codigo_creador,
                                   t.per_codigo_aprobador,
                                   t.rpi_fecha_actualizacion,
                                   t.rpi_estado,
                                   @per_actor,
                                   'U',
                                   ORIGINAL_LOGIN(),
                                   @ahora
                            FROM   sgspi.requisito_parte_interesada AS t
                                   INNER JOIN
                                   @cambiadas AS c
                                   ON c.rpi_codigo = t.rpi_codigo;
                        END
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
                   ari_fase_registro,
                   per_codigo_creador,
                   per_codigo_aprobador,
                   ari_fecha_actualizacion,
                   ari_estado,
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
                      i.rpi_fase_registro,
                      i.per_codigo_creador,
                      i.per_codigo_aprobador,
                      i.rpi_fecha_actualizacion,
                      i.rpi_estado,
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
           -- [AP-24] Serializa el agregado por raíz (aci) en orden ascendente para evitar deadlocks AB-BA
           DECLARE @lock_id AS INT = (SELECT MIN(aci_codigo)
                                      FROM   (SELECT aci_codigo
                                              FROM   inserted
                                              UNION
                                              SELECT aci_codigo
                                              FROM   deleted) AS l), @lock_res AS NVARCHAR (60), @lock_rc AS INT;
           WHILE @lock_id IS NOT NULL
               BEGIN
                   SET @lock_res = CONCAT(N'sgspi:aci:', @lock_id);
                   EXECUTE @lock_rc = sys.sp_getapplock @Resource = @lock_res, @LockMode = 'Exclusive', @LockOwner = 'Transaction', @LockTimeout = 10000;
                   IF @lock_rc < 0
                       THROW 50023, N'Tiempo de espera agotado al adquirir bloqueo del agregado [sgspi:aci] en [sgspi].[activo_informacion].', 1;
                   SET @lock_id = (SELECT MIN(aci_codigo)
                                   FROM   (SELECT aci_codigo
                                           FROM   inserted
                                           UNION
                                           SELECT aci_codigo
                                           FROM   deleted) AS l
                                   WHERE  l.aci_codigo > @lock_id);
               END
           -- [AP-04] En INSERT el estado debe ser el inicial del dominio
           IF EXISTS (SELECT 1
                      FROM   inserted AS i
                      WHERE  NOT EXISTS (SELECT 1
                                         FROM   deleted AS d
                                         WHERE  d.aci_codigo = i.aci_codigo)
                             AND NOT EXISTS (SELECT 1
                                             FROM   sgspi.estado_flujo_catalogo AS efc
                                             WHERE  efc.efc_dominio = N'ACI'
                                                    AND efc.efc_identificador = i.aci_fase_registro
                                                    AND efc.efc_es_inicial = 1
                                                    AND efc.efc_estado = 1))
               THROW 50014, N'Estado inicial inválido: un registro nuevo de [sgspi].[activo_informacion] solo puede crearse en el estado inicial del flujo.', 1;
           -- [B1] La firma de Archivo la registra TR_aci en EN_REVISION_ARCHIVO -> EN_REVISION_SGSPI; nunca se envía en INSERT
           IF EXISTS (SELECT 1
                      FROM   inserted AS i
                      WHERE  i.per_codigo_revisor_archivo IS NOT NULL
                             AND NOT EXISTS (SELECT 1
                                             FROM   deleted AS d
                                             WHERE  d.aci_codigo = i.aci_codigo))
               THROW 50018, N'La firma de Archivo [per_codigo_revisor_archivo] no se envía al crear el activo: la registra la transición EN_REVISION_ARCHIVO -> EN_REVISION_SGSPI.', 1;
           -- [AP-03] Persona de la sesión: crea los registros nuevos y firma las aprobaciones y la revisión de Archivo
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona activa (usuario_administrativos/usuario_docentes.sys) para ORIGINAL_LOGIN().', 1;
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
                             OUTER APPLY sgspi.ufn_activo_en_alcance(x.aci_codigo, x.uaa_codigo, @per_actor) AS a
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
                              WHERE  (i.aci_fase_registro = d.aci_fase_registro
                                      AND EXISTS (SELECT 1
                                                  FROM   sgspi.estado_flujo_catalogo AS efc
                                                  WHERE  efc.efc_dominio = N'ACI'
                                                         AND efc.efc_identificador = d.aci_fase_registro
                                                         AND (efc.efc_permite_edicion = 0
                                                              OR efc.efc_estado = 0)))
                                     OR (i.aci_fase_registro <> d.aci_fase_registro
                                         AND NOT EXISTS (SELECT 1
                                                         FROM   sgspi.transicion_estado_flujo AS tef
                                                                INNER JOIN
                                                                sgspi.estado_flujo_catalogo AS efc_dest
                                                                ON efc_dest.efc_dominio = tef.efc_dominio
                                                                   AND efc_dest.efc_identificador = tef.efc_identificador_destino
                                                         WHERE  tef.efc_dominio = N'ACI'
                                                                AND tef.efc_identificador_origen = d.aci_fase_registro
                                                                AND tef.efc_identificador_destino = i.aci_fase_registro
                                                                AND tef.tef_estado = 1
                                                                AND efc_dest.efc_estado = 1
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
                                     i.aci_estado
                              FROM   inserted AS i
                                     INNER JOIN
                                     deleted AS d
                                     ON d.aci_codigo = i.aci_codigo
                              WHERE  i.aci_fase_registro <> d.aci_fase_registro
                                     AND EXISTS (SELECT 1
                                                 FROM   sgspi.estado_flujo_catalogo AS efc
                                                 WHERE  efc.efc_dominio = N'ACI'
                                                        AND efc.efc_identificador IN (d.aci_fase_registro, i.aci_fase_registro)
                                                        AND (efc.efc_permite_edicion = 0
                                                             OR efc.efc_estado = 0))
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
                                     d.aci_estado
                              FROM   deleted AS d
                                     INNER JOIN
                                     inserted AS i
                                     ON i.aci_codigo = d.aci_codigo
                              WHERE  i.aci_fase_registro <> d.aci_fase_registro
                                     AND EXISTS (SELECT 1
                                                 FROM   sgspi.estado_flujo_catalogo AS efc
                                                 WHERE  efc.efc_dominio = N'ACI'
                                                        AND efc.efc_identificador IN (d.aci_fase_registro, i.aci_fase_registro)
                                                        AND (efc.efc_permite_edicion = 0
                                                             OR efc.efc_estado = 0)))
                       THROW 50011, N'No se permite modificar el contenido durante una transición de estado en [sgspi].[activo_informacion].', 1;
                    -- [B4] Protección anti-huérfanos en borrado lógico: no desactivar [aci] si tiene hijos activos
                    IF EXISTS (SELECT 1
                               FROM   inserted AS i
                                      INNER JOIN
                                      deleted AS d
                                      ON d.aci_codigo = i.aci_codigo
                               WHERE  d.aci_estado = 1
                                      AND i.aci_estado = 0
                                      AND (EXISTS (SELECT 1
                                                   FROM   sgspi.activo_documental AS ado
                                                   WHERE  ado.ado_codigo = i.aci_codigo
                                                          AND ado.ado_estado = 1)
                                           OR EXISTS (SELECT 1
                                                      FROM   sgspi.sistema_informacion_ficha AS sif
                                                      WHERE  sif.aci_codigo = i.aci_codigo
                                                             AND sif.sif_estado = 1)
                                           OR EXISTS (SELECT 1
                                                      FROM   sgspi.evento_incertidumbre_activo AS eia
                                                      WHERE  (eia.aci_codigo_primario = i.aci_codigo
                                                              OR eia.aci_codigo_soporte = i.aci_codigo)
                                                             AND eia.eia_estado = 1)
                                           OR EXISTS (SELECT 1
                                                      FROM   sgspi.activo_informacion_proceso_institucional AS aip
                                                      WHERE  aip.aci_codigo = i.aci_codigo
                                                             AND aip.aip_estado = 1)
                                           OR EXISTS (SELECT 1
                                                      FROM   sgspi.activo_informacion_sede AS ais
                                                      WHERE  ais.aci_codigo = i.aci_codigo
                                                             AND ais.ais_estado = 1)
                                           OR EXISTS (SELECT 1
                                                      FROM   sgspi.activo_informacion_responsable AS air
                                                      WHERE  air.aci_codigo = i.aci_codigo
                                                             AND air.air_estado = 1)))
                        THROW 50020, N'Baja lógica denegada: existen registros hijos activos asociados a [sgspi].[activo_informacion].', 1;
                    -- [AP-16] D3: un activo solo se aprueba con su propietario activo (único por UX_air_propietario_activo)
                    IF EXISTS (SELECT 1
                               FROM   inserted AS i
                                      INNER JOIN
                                      deleted AS d
                                      ON d.aci_codigo = i.aci_codigo
                               WHERE  i.aci_fase_registro = N'VIGENTE'
                                      AND d.aci_fase_registro <> N'VIGENTE'
                                      AND NOT EXISTS (SELECT 1
                                                      FROM   sgspi.activo_informacion_responsable AS air
                                                      WHERE  air.aci_codigo = i.aci_codigo
                                                             AND air.air_tipo_responsabilidad = N'PROPIETARIO'
                                                             AND air.air_estado = 1))
                        THROW 50020, N'Transición incompleta: VIGENTE exige un propietario activo en [sgspi].[activo_informacion_responsable].', 1;
                    -- [B1] RN-DOC-06 y RN-ACT-05: el activo documental exige aval de Archivo (aci.per_codigo_revisor_archivo) y todo activo exige al menos un custodio activo
                    IF EXISTS (SELECT 1
                               FROM   inserted AS i
                                      INNER JOIN
                                      deleted AS d
                                      ON d.aci_codigo = i.aci_codigo
                               WHERE  i.aci_fase_registro = N'VIGENTE'
                                      AND d.aci_fase_registro <> N'VIGENTE'
                                      AND ((EXISTS (SELECT 1
                                                    FROM   sgspi.activo_documental AS ado
                                                    WHERE  ado.ado_codigo = i.aci_codigo
                                                           AND ado.ado_estado = 1)
                                            AND i.per_codigo_revisor_archivo IS NULL)
                                           OR NOT EXISTS (SELECT 1
                                                          FROM   sgspi.activo_informacion_responsable AS air
                                                          WHERE  air.aci_codigo = i.aci_codigo
                                                                 AND air.air_estado = 1
                                                                 AND air.air_tipo_responsabilidad = N'CUSTODIO')))
                        THROW 50020, N'Transición incompleta: VIGENTE exige el aval de Archivo (activo documental) y un custodio activo en [sgspi].[activo_informacion].', 1;
                    -- [B4] Cardinalidad mínima 1..N en aprobación VIGENTE: >=1 proceso (aip), >=1 sede (ais) si no es transversal, y en ado >=1 fila activa en ads, adm, adi, adf, adu
                    IF EXISTS (SELECT 1
                               FROM   inserted AS i
                                      INNER JOIN
                                      deleted AS d
                                      ON d.aci_codigo = i.aci_codigo
                               WHERE  i.aci_fase_registro = N'VIGENTE'
                                      AND d.aci_fase_registro <> N'VIGENTE'
                                      AND (NOT EXISTS (SELECT 1
                                                       FROM   sgspi.activo_informacion_proceso_institucional AS aip
                                                       WHERE  aip.aci_codigo = i.aci_codigo
                                                              AND aip.aip_estado = 1)
                                           OR (i.aci_es_transversal_sedes = 0
                                               AND NOT EXISTS (SELECT 1
                                                               FROM   sgspi.activo_informacion_sede AS ais
                                                               WHERE  ais.aci_codigo = i.aci_codigo
                                                                      AND ais.ais_estado = 1))
                                           OR (EXISTS (SELECT 1
                                                       FROM   sgspi.activo_documental AS ado
                                                       WHERE  ado.ado_codigo = i.aci_codigo
                                                              AND ado.ado_estado = 1)
                                               AND (NOT EXISTS (SELECT 1
                                                                FROM   sgspi.activo_documental_soporte_registro AS ads
                                                                WHERE  ads.ado_codigo = i.aci_codigo
                                                                       AND ads.ads_estado = 1)
                                                    OR NOT EXISTS (SELECT 1
                                                                   FROM   sgspi.activo_documental_medio_conservacion AS adm
                                                                   WHERE  adm.ado_codigo = i.aci_codigo
                                                                          AND adm.adm_estado = 1)
                                                    OR NOT EXISTS (SELECT 1
                                                                   FROM   sgspi.activo_documental_idioma AS adi
                                                                   WHERE  adi.ado_codigo = i.aci_codigo
                                                                          AND adi.adi_estado = 1)
                                                    OR NOT EXISTS (SELECT 1
                                                                   FROM   sgspi.activo_documental_formato_archivo AS adf
                                                                   WHERE  adf.ado_codigo = i.aci_codigo
                                                                          AND adf.adf_estado = 1)
                                                    OR NOT EXISTS (SELECT 1
                                                                   FROM   sgspi.activo_documental_unidad_productora AS adu
                                                                   WHERE  adu.ado_codigo = i.aci_codigo
                                                                          AND adu.adu_estado = 1)))))
                        THROW 50020, N'Transición incompleta: VIGENTE exige proceso (aip), sede si no es transversal (ais) y, en activos documentales, soporte/medio/idioma/formato/unidad productora activos en [sgspi].[activo_informacion].', 1;
                    -- [AP-01] [B1] [C2] Detecta filas con cambio real, actualiza fecha y firmas en 1 solo UPDATE sobre [aci] (sin escribir [ado]) y archiva after-image ('U')
                    DECLARE @cambiadas TABLE (
                        aci_codigo INT PRIMARY KEY);
                    INSERT INTO @cambiadas (
                        aci_codigo
                    )
                    SELECT i.aci_codigo
                    FROM   inserted AS i
                           INNER JOIN
                           deleted AS d
                           ON d.aci_codigo = i.aci_codigo
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
                                          i.aci_fase_registro,
                                          i.per_codigo_creador,
                                          i.per_codigo_aprobador,
                                          i.per_codigo_revisor_archivo,
                                          i.aci_fecha_actualizacion,
                                          i.aci_estado
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
                                          d.aci_fase_registro,
                                          d.per_codigo_creador,
                                          d.per_codigo_aprobador,
                                          d.per_codigo_revisor_archivo,
                                          d.aci_fecha_actualizacion,
                                          d.aci_estado);
                    DECLARE @ahora AS DATETIMEOFFSET (0) = SYSDATETIMEOFFSET();
                    DECLARE @actualizar_fecha AS BIT = CASE WHEN UPDATE (aci_fecha_actualizacion) THEN 0 ELSE 1 END;
                    IF EXISTS (SELECT 1
                               FROM   @cambiadas)
                        BEGIN
                            UPDATE t
                            SET    t.aci_fecha_actualizacion    = CASE WHEN @actualizar_fecha = 1 THEN @ahora ELSE t.aci_fecha_actualizacion END, -- [AP-12]
                                   t.per_codigo_aprobador       = CASE WHEN d.aci_fase_registro <> i.aci_fase_registro
                                                                            AND i.aci_fase_registro = N'VIGENTE' THEN @per_actor WHEN d.aci_fase_registro <> i.aci_fase_registro
                                                                                                                                        AND ((d.aci_fase_registro = N'VIGENTE'
                                                                                                                                              AND i.aci_fase_registro <> N'HISTORICO')
                                                                                                                                             OR i.aci_fase_registro IN (N'OBSERVADO', N'BORRADOR')) THEN NULL ELSE t.per_codigo_aprobador END,
                                   t.per_codigo_revisor_archivo = CASE WHEN d.aci_fase_registro = N'EN_REVISION_ARCHIVO'
                                                                            AND i.aci_fase_registro = N'EN_REVISION_SGSPI' THEN @per_actor WHEN (d.aci_fase_registro <> i.aci_fase_registro
                                                                                                                                                 AND ((d.aci_fase_registro = N'VIGENTE'
                                                                                                                                                       AND i.aci_fase_registro NOT IN (N'HISTORICO', N'INACTIVO'))
                                                                                                                                                      OR i.aci_fase_registro IN (N'OBSERVADO', N'BORRADOR', N'EN_REVISION_ARCHIVO')))
                                                                                                                                                OR (d.aci_fase_registro = i.aci_fase_registro
                                                                                                                                                    AND i.aci_fase_registro IN (N'EN_REVISION_SGSPI', N'INACTIVO')
                                                                                                                                                    AND t.per_codigo_revisor_archivo IS NOT NULL) THEN NULL ELSE t.per_codigo_revisor_archivo END
                            FROM   sgspi.activo_informacion AS t
                                   INNER JOIN
                                   @cambiadas AS c
                                   ON c.aci_codigo = t.aci_codigo
                                   INNER JOIN
                                   inserted AS i
                                   ON i.aci_codigo = t.aci_codigo
                                   INNER JOIN
                                   deleted AS d
                                   ON d.aci_codigo = i.aci_codigo
                            WHERE  @actualizar_fecha = 1
                                   OR (d.aci_fase_registro <> i.aci_fase_registro
                                       AND (i.aci_fase_registro = N'VIGENTE'
                                            OR (d.aci_fase_registro = N'VIGENTE'
                                                AND i.aci_fase_registro <> N'HISTORICO')
                                            OR (d.aci_fase_registro = N'EN_REVISION_ARCHIVO'
                                                AND i.aci_fase_registro = N'EN_REVISION_SGSPI')
                                            OR i.aci_fase_registro IN (N'OBSERVADO', N'BORRADOR', N'EN_REVISION_ARCHIVO')))
                                   OR (d.aci_fase_registro = i.aci_fase_registro
                                       AND i.aci_fase_registro IN (N'EN_REVISION_SGSPI', N'INACTIVO')
                                       AND t.per_codigo_revisor_archivo IS NOT NULL);
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
                                aai_fase_registro,
                                per_codigo_creador,
                                per_codigo_aprobador,
                                per_codigo_revisor_archivo,
                                aai_fecha_actualizacion,
                                aai_estado,
                                per_codigo,
                                aai_operacion,
                                aai_usuario_bd,
                                aai_fecha_cambio
                            )
                            SELECT t.aci_codigo,
                                   t.aci_codigo_inventario,
                                   t.aci_nombre_activo,
                                   t.aci_descripcion_detallada,
                                   t.tac_codigo,
                                   t.uaa_codigo,
                                   t.esp_codigo,
                                   t.aci_es_transversal_sedes,
                                   t.aci_cantidad_unidades,
                                   t.aci_clasificacion_transparencia,
                                   t.cet_codigo,
                                   t.aci_alcance_excepcion,
                                   t.aci_fundamento_constitucional_legal,
                                   t.aci_fundamento_juridico_excepcion,
                                   t.aci_fecha_clasificacion_reserva,
                                   t.aci_es_reserva_indefinida,
                                   t.aci_anios_plazo_reserva,
                                   t.aci_contiene_datos_personales,
                                   t.aci_contiene_datos_menores,
                                   t.aci_categoria_dato_personal,
                                   t.aci_finalidad_recoleccion_pii,
                                   t.aci_existe_autorizacion_pii,
                                   t.aci_valor_confidencialidad,
                                   t.aci_valor_integridad,
                                   t.aci_valor_disponibilidad,
                                   t.aci_supera_umbral_social_icc,
                                   t.aci_supera_umbral_economico_icc,
                                   t.aci_supera_umbral_ambiental_icc,
                                   t.aci_fase_registro,
                                   t.per_codigo_creador,
                                   t.per_codigo_aprobador,
                                   t.per_codigo_revisor_archivo,
                                   t.aci_fecha_actualizacion,
                                   t.aci_estado,
                                   @per_actor,
                                   'U',
                                   ORIGINAL_LOGIN(),
                                   @ahora
                            FROM   sgspi.activo_informacion AS t
                                   INNER JOIN
                                   @cambiadas AS c
                                   ON c.aci_codigo = t.aci_codigo;
                        END
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
                    aai_fase_registro,
                    per_codigo_creador,
                    per_codigo_aprobador,
                    per_codigo_revisor_archivo,
                    aai_fecha_actualizacion,
                    aai_estado,
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
                       i.aci_fase_registro,
                       i.per_codigo_creador,
                       i.per_codigo_aprobador,
                       i.per_codigo_revisor_archivo,
                       i.aci_fecha_actualizacion,
                       i.aci_estado,
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
           -- [AP-24] Serializa el agregado por raíz (aci) en orden ascendente para evitar deadlocks AB-BA
           DECLARE @lock_id AS INT = (SELECT MIN(ado_codigo)
                                      FROM   (SELECT ado_codigo
                                              FROM   inserted
                                              UNION
                                              SELECT ado_codigo
                                              FROM   deleted) AS l), @lock_res AS NVARCHAR (60), @lock_rc AS INT;
           WHILE @lock_id IS NOT NULL
               BEGIN
                   SET @lock_res = CONCAT(N'sgspi:aci:', @lock_id);
                   EXECUTE @lock_rc = sys.sp_getapplock @Resource = @lock_res, @LockMode = 'Exclusive', @LockOwner = 'Transaction', @LockTimeout = 10000;
                   IF @lock_rc < 0
                       THROW 50023, N'Tiempo de espera agotado al adquirir bloqueo del agregado [sgspi:aci] en [sgspi].[activo_documental].', 1;
                   SET @lock_id = (SELECT MIN(ado_codigo)
                                   FROM   (SELECT ado_codigo
                                           FROM   inserted
                                           UNION
                                           SELECT ado_codigo
                                           FROM   deleted) AS l
                                   WHERE  l.ado_codigo > @lock_id);
               END
           IF EXISTS (SELECT 1
                      FROM   (SELECT ado_codigo
                              FROM   inserted
                              UNION
                              SELECT ado_codigo
                              FROM   deleted) AS x
                             INNER JOIN
                             sgspi.activo_informacion AS aci
                             ON aci.aci_codigo = x.ado_codigo
                             INNER JOIN
                             sgspi.estado_flujo_catalogo AS efc
                             ON efc.efc_dominio = N'ACI'
                                AND efc.efc_identificador = aci.aci_fase_registro
                      WHERE  efc.efc_permite_edicion = 0
                             OR efc.efc_estado = 0)
               THROW 50011, N'Operación denegada: No se permite insertar ni modificar un activo documental cuyo activo de información no es editable en [sgspi].[activo_documental].', 1;
           -- [B1] Sin escritura cruzada a [aci] (cero deadlock): si [aci] tiene aval de Archivo vigente, debe devolverse primero a OBSERVADO o EN_REVISION_ARCHIVO
           IF EXISTS (SELECT 1
                      FROM   (SELECT ado_codigo
                              FROM   inserted
                              UNION
                              SELECT ado_codigo
                              FROM   deleted) AS x
                             INNER JOIN
                             sgspi.activo_informacion AS aci
                             ON aci.aci_codigo = x.ado_codigo
                      WHERE  aci.per_codigo_revisor_archivo IS NOT NULL)
               THROW 50011, N'Operación denegada: el activo documental ya cuenta con aval de Archivo vigente; devuelva el activo a OBSERVADO o EN_REVISION_ARCHIVO antes de modificar [sgspi].[activo_documental].', 1;
           -- [B4] Exclusividad de subtipos: un activo no puede tener [ado] activo y [sif] activo simultáneamente
           IF EXISTS (SELECT 1
                      FROM   inserted AS i
                      WHERE  i.ado_estado = 1
                             AND EXISTS (SELECT 1
                                         FROM   sgspi.sistema_informacion_ficha AS sif
                                         WHERE  sif.aci_codigo = i.ado_codigo
                                                AND sif.sif_estado = 1))
               THROW 50020, N'Exclusividad de subtipos: un activo con ficha de sistema de información activa ([sif]) no puede registrarse como activo documental ([ado]).', 1;
           -- [AP-06] Una serie con subseries activas exige indicar la subserie (INSERT y UPDATE)
           IF EXISTS (SELECT 1
                      FROM   inserted AS i
                      WHERE  i.sbd_codigo IS NULL
                             AND EXISTS (SELECT 1
                                         FROM   sgspi.subserie_documental_catalogo AS sbd
                                         WHERE  sbd.sdo_codigo = i.sdo_codigo
                                                AND sbd.sbd_estado = 1))
               THROW 50015, N'Subserie requerida: la serie documental seleccionada tiene subseries y [sbd_codigo] no puede ser NULL en [sgspi].[activo_documental].', 1;
           -- [AP-03] Persona de la sesión: queda en la auditoría
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona activa (usuario_administrativos/usuario_docentes.sys) para ORIGINAL_LOGIN().', 1;
           -- [AP-02] D5: los roles líder y custodio solo escriben activos de su alcance (ufn_activo_en_alcance; LEFT JOIN evita bypass cuando RLS oculta al padre)
           IF EXISTS (SELECT 1
                      FROM   (SELECT ado_codigo
                              FROM   inserted
                              UNION
                              SELECT ado_codigo
                              FROM   deleted) AS x
                             LEFT OUTER JOIN
                             sgspi.activo_informacion AS p
                             ON p.aci_codigo = x.ado_codigo
                             OUTER APPLY sgspi.ufn_activo_en_alcance(p.aci_codigo, p.uaa_codigo, @per_actor) AS a
                      WHERE  a.permitido IS NULL)
               THROW 50021, N'Fuera de alcance: el activo no es de las UAA ni de los procesos del usuario en [sgspi].[activo_documental].', 1;
           -- D7: no se crean registros ni se mueven a una vigencia cerrada o histórica
           IF EXISTS (SELECT 1
                      FROM   inserted AS i
                             INNER JOIN
                             sgspi.periodo_vigencia AS pev
                             ON pev.pev_codigo = i.pev_codigo
                      WHERE  pev.pev_fase_vigencia IN (N'CERRADA', N'HISTORICA')
                             AND NOT EXISTS (SELECT 1
                                             FROM   deleted AS d
                                             WHERE  d.ado_codigo = i.ado_codigo
                                                    AND d.pev_codigo = i.pev_codigo))
               THROW 50022, N'Vigencia cerrada: no se crean registros ni se mueven a una vigencia CERRADA o HISTORICA en [sgspi].[activo_documental].', 1;
           IF EXISTS (SELECT 1
                      FROM   deleted)
               BEGIN
                    -- [AP-01] [B1] [C2] Detecta filas con cambio real, actualiza fecha en 1 UPDATE y archiva after-image ('U')
                    IF EXISTS (SELECT 1
                               FROM   deleted AS d
                               WHERE  NOT EXISTS (SELECT 1
                                                  FROM   inserted AS i
                                                  WHERE  i.ado_codigo = d.ado_codigo))
                        THROW 50011, N'Operación denegada: No se permite cambiar la clave de [sgspi].[activo_documental]; desactive la fila y cree una nueva.', 1;
                    DECLARE @cambiadas TABLE (
                        ado_codigo INT PRIMARY KEY);
                    INSERT INTO @cambiadas (
                        ado_codigo
                    )
                    SELECT i.ado_codigo
                    FROM   inserted AS i
                           INNER JOIN
                           deleted AS d
                           ON d.ado_codigo = i.ado_codigo
                    WHERE  EXISTS (SELECT i.pev_codigo,
                                          i.sdo_codigo,
                                          i.sbd_codigo,
                                          i.pdc_codigo,
                                          i.ado_fecha_ingreso_tabla_retencion,
                                          i.ado_fecha_ingreso_archivo,
                                          i.epc_codigo,
                                          i.ado_lugar_consulta_ubicacion,
                                          i.ado_fecha_actualizacion,
                                          i.ado_estado
                                   EXCEPT
                                   SELECT d.pev_codigo,
                                          d.sdo_codigo,
                                          d.sbd_codigo,
                                          d.pdc_codigo,
                                          d.ado_fecha_ingreso_tabla_retencion,
                                          d.ado_fecha_ingreso_archivo,
                                          d.epc_codigo,
                                          d.ado_lugar_consulta_ubicacion,
                                          d.ado_fecha_actualizacion,
                                          d.ado_estado);
                    DECLARE @ahora AS DATETIMEOFFSET (0) = SYSDATETIMEOFFSET();
                    DECLARE @actualizar_fecha AS BIT = CASE WHEN UPDATE (ado_fecha_actualizacion) THEN 0 ELSE 1 END;
                    IF EXISTS (SELECT 1
                               FROM   @cambiadas)
                        BEGIN
                            IF @actualizar_fecha = 1
                                UPDATE t
                                SET    t.ado_fecha_actualizacion = @ahora -- [AP-11] [AP-12]
                                FROM   sgspi.activo_documental AS t
                                       INNER JOIN
                                       @cambiadas AS c
                                       ON c.ado_codigo = t.ado_codigo;
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
                                aao_fecha_actualizacion,
                                aao_estado,
                                per_codigo,
                                aao_operacion,
                                aao_usuario_bd,
                                aao_fecha_cambio
                            )
                            SELECT t.ado_codigo,
                                   t.pev_codigo,
                                   t.sdo_codigo,
                                   t.sbd_codigo,
                                   t.pdc_codigo,
                                   t.ado_fecha_ingreso_tabla_retencion,
                                   t.ado_fecha_ingreso_archivo,
                                   t.epc_codigo,
                                   t.ado_lugar_consulta_ubicacion,
                                   t.ado_fecha_actualizacion,
                                   t.ado_estado,
                                   @per_actor,
                                   'U',
                                   ORIGINAL_LOGIN(),
                                   @ahora
                            FROM   sgspi.activo_documental AS t
                                   INNER JOIN
                                   @cambiadas AS c
                                   ON c.ado_codigo = t.ado_codigo;
                        END
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
                    aao_fecha_actualizacion,
                    aao_estado,
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
                       i.ado_fecha_actualizacion,
                       i.ado_estado,
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
           -- [AP-24] Serializa el agregado por raíz (eia) en orden ascendente para evitar deadlocks AB-BA
           DECLARE @lock_id AS INT = (SELECT MIN(eia_codigo)
                                      FROM   (SELECT eia_codigo
                                              FROM   inserted
                                              UNION
                                              SELECT eia_codigo
                                              FROM   deleted) AS l), @lock_res AS NVARCHAR (60), @lock_rc AS INT;
           WHILE @lock_id IS NOT NULL
               BEGIN
                   SET @lock_res = CONCAT(N'sgspi:eia:', @lock_id);
                   EXECUTE @lock_rc = sys.sp_getapplock @Resource = @lock_res, @LockMode = 'Exclusive', @LockOwner = 'Transaction', @LockTimeout = 10000;
                   IF @lock_rc < 0
                       THROW 50023, N'Tiempo de espera agotado al adquirir bloqueo del agregado [sgspi:eia] en [sgspi].[evento_incertidumbre_activo].', 1;
                   SET @lock_id = (SELECT MIN(eia_codigo)
                                   FROM   (SELECT eia_codigo
                                           FROM   inserted
                                           UNION
                                           SELECT eia_codigo
                                           FROM   deleted) AS l
                                   WHERE  l.eia_codigo > @lock_id);
               END
           -- [AP-04] En INSERT el estado debe ser el inicial del dominio
           IF EXISTS (SELECT 1
                      FROM   inserted AS i
                      WHERE  NOT EXISTS (SELECT 1
                                         FROM   deleted AS d
                                         WHERE  d.eia_codigo = i.eia_codigo)
                             AND NOT EXISTS (SELECT 1
                                             FROM   sgspi.estado_flujo_catalogo AS efc
                                             WHERE  efc.efc_dominio = N'EIA'
                                                    AND efc.efc_identificador = i.eia_fase_registro
                                                    AND efc.efc_es_inicial = 1
                                                    AND efc.efc_estado = 1))
               THROW 50014, N'Estado inicial inválido: un registro nuevo de [sgspi].[evento_incertidumbre_activo] solo puede crearse en el estado inicial del flujo.', 1;
           -- [AP-03] Persona de la sesión: crea los registros nuevos y firma las validaciones y aprobaciones
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona activa (usuario_administrativos/usuario_docentes.sys) para ORIGINAL_LOGIN().', 1;
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
                             OUTER APPLY sgspi.ufn_proceso_en_alcance(x.pri_codigo, @per_actor) AS a
                      WHERE  a.permitido IS NULL)
               THROW 50021, N'Fuera de alcance: el proceso no está en las UAA del usuario en [sgspi].[evento_incertidumbre_activo].', 1;
           -- D7: no se crean registros ni se mueven a una vigencia cerrada o histórica
           IF EXISTS (SELECT 1
                      FROM   inserted AS i
                             INNER JOIN
                             sgspi.periodo_vigencia AS pev
                             ON pev.pev_codigo = i.pev_codigo
                      WHERE  pev.pev_fase_vigencia IN (N'CERRADA', N'HISTORICA')
                             AND NOT EXISTS (SELECT 1
                                             FROM   deleted AS d
                                             WHERE  d.eia_codigo = i.eia_codigo
                                                    AND d.pev_codigo = i.pev_codigo))
               THROW 50022, N'Vigencia cerrada: no se crean registros ni se mueven a una vigencia CERRADA o HISTORICA en [sgspi].[evento_incertidumbre_activo].', 1;
           -- Exige asociación activo-proceso activa y ambos activos (primario y soporte) activos en alta, cambio de vínculo o reactivación
           IF EXISTS (SELECT 1
                      FROM   inserted AS i
                             LEFT OUTER JOIN
                             deleted AS d
                             ON d.eia_codigo = i.eia_codigo
                      WHERE  (d.eia_codigo IS NULL
                              OR (i.eia_estado = 1
                                  AND (i.aci_codigo_primario <> d.aci_codigo_primario
                                       OR i.aci_codigo_soporte <> d.aci_codigo_soporte
                                       OR i.pri_codigo <> d.pri_codigo
                                       OR d.eia_estado = 0)))
                             AND (NOT EXISTS (SELECT 1
                                              FROM   sgspi.activo_informacion_proceso_institucional AS aip
                                              WHERE  aip.aci_codigo = i.aci_codigo_primario
                                                     AND aip.pri_codigo = i.pri_codigo
                                                     AND aip.aip_estado = 1)
                                  OR NOT EXISTS (SELECT 1
                                                 FROM   sgspi.activo_informacion AS aci
                                                 WHERE  aci.aci_codigo = i.aci_codigo_primario
                                                        AND aci.aci_estado = 1)
                                  OR NOT EXISTS (SELECT 1
                                                 FROM   sgspi.activo_informacion AS aci
                                                 WHERE  aci.aci_codigo = i.aci_codigo_soporte
                                                        AND aci.aci_estado = 1)))
               THROW 50011, N'Activo o asociación inactiva: el activo primario, el activo de soporte y la asociación activo-proceso deben estar activos en [sgspi].[evento_incertidumbre_activo].', 1;
           IF EXISTS (SELECT 1
                      FROM   deleted)
               BEGIN
                   -- [AP-05] Máquina de estados dirigida por datos: sin listas de estados codificadas
                   IF EXISTS (SELECT 1
                              FROM   inserted AS i
                                     INNER JOIN
                                     deleted AS d
                                     ON d.eia_codigo = i.eia_codigo
                              WHERE  (i.eia_fase_registro = d.eia_fase_registro
                                      AND EXISTS (SELECT 1
                                                  FROM   sgspi.estado_flujo_catalogo AS efc
                                                  WHERE  efc.efc_dominio = N'EIA'
                                                         AND efc.efc_identificador = d.eia_fase_registro
                                                         AND (efc.efc_permite_edicion = 0
                                                              OR efc.efc_estado = 0)))
                                     OR (i.eia_fase_registro <> d.eia_fase_registro
                                         AND NOT EXISTS (SELECT 1
                                                         FROM   sgspi.transicion_estado_flujo AS tef
                                                                INNER JOIN
                                                                sgspi.estado_flujo_catalogo AS efc_dest
                                                                ON efc_dest.efc_dominio = tef.efc_dominio
                                                                   AND efc_dest.efc_identificador = tef.efc_identificador_destino
                                                         WHERE  tef.efc_dominio = N'EIA'
                                                                AND tef.efc_identificador_origen = d.eia_fase_registro
                                                                AND tef.efc_identificador_destino = i.eia_fase_registro
                                                                AND tef.tef_estado = 1
                                                                AND efc_dest.efc_estado = 1
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
                                     i.eia_estado
                              FROM   inserted AS i
                                     INNER JOIN
                                     deleted AS d
                                     ON d.eia_codigo = i.eia_codigo
                              WHERE  i.eia_fase_registro <> d.eia_fase_registro
                                     AND EXISTS (SELECT 1
                                                 FROM   sgspi.estado_flujo_catalogo AS efc
                                                 WHERE  efc.efc_dominio = N'EIA'
                                                        AND efc.efc_identificador IN (d.eia_fase_registro, i.eia_fase_registro)
                                                        AND (efc.efc_permite_edicion = 0
                                                             OR efc.efc_estado = 0))
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
                                     d.eia_estado
                              FROM   deleted AS d
                                     INNER JOIN
                                     inserted AS i
                                     ON i.eia_codigo = d.eia_codigo
                              WHERE  i.eia_fase_registro <> d.eia_fase_registro
                                     AND EXISTS (SELECT 1
                                                 FROM   sgspi.estado_flujo_catalogo AS efc
                                                 WHERE  efc.efc_dominio = N'EIA'
                                                        AND efc.efc_identificador IN (d.eia_fase_registro, i.eia_fase_registro)
                                                        AND (efc.efc_permite_edicion = 0
                                                             OR efc.efc_estado = 0)))
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
                              WHERE  i.eia_fase_registro = N'APROBADO_PLANIFICADO'
                                     AND d.eia_fase_registro <> N'APROBADO_PLANIFICADO'
                                     AND NOT EXISTS (SELECT 1
                                                     FROM   sgspi.plan_tratamiento AS plt
                                                     WHERE  plt.eia_codigo = i.eia_codigo
                                                            AND plt.plt_estado = 1))
                       THROW 50020, N'Transición incompleta: APROBADO_PLANIFICADO exige un plan de tratamiento activo en [sgspi].[evento_incertidumbre_activo].', 1;
                   IF EXISTS (SELECT 1
                              FROM   inserted AS i
                                     INNER JOIN
                                     deleted AS d
                                     ON d.eia_codigo = i.eia_codigo
                              WHERE  d.eia_fase_registro = N'EN_REVISION_SGSPI'
                                     AND i.eia_fase_registro = N'APROBADO_PLANIFICADO'
                                     AND EXISTS (SELECT 1
                                                 FROM   sgspi.matriz_valoracion_riesgo AS mvr
                                                 WHERE  mvr.mvr_requiere_aprobacion_comite = 1
                                                        AND ((mvr.epr_codigo = i.epr_codigo_inherente
                                                              AND mvr.eim_codigo = i.eim_codigo_inherente)
                                                             OR EXISTS (SELECT 1
                                                                        FROM   sgspi.plan_tratamiento AS plt
                                                                        WHERE  plt.eia_codigo = i.eia_codigo
                                                                               AND plt.plt_estado = 1
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
                                     sgspi.plan_tratamiento AS plt
                                     ON plt.eia_codigo = i.eia_codigo
                                        AND plt.plt_estado = 1
                              WHERE  i.eia_fase_registro = N'APROBADO_PLANIFICADO'
                                     AND d.eia_fase_registro <> N'APROBADO_PLANIFICADO'
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
                              WHERE  i.eia_fase_registro = N'APROBADO_PLANIFICADO'
                                     AND d.eia_fase_registro <> N'APROBADO_PLANIFICADO'
                                     AND aci.aci_contiene_datos_personales = 1
                                     AND NOT EXISTS (SELECT 1
                                                     FROM   sgspi.plan_tratamiento AS plt
                                                            INNER JOIN
                                                            sgspi.plan_tratamiento_control_referencia_normativa AS ptc
                                                            ON ptc.plt_codigo = plt.plt_codigo
                                                            INNER JOIN
                                                            sgspi.control_referencia_normativa AS crn
                                                            ON crn.crn_codigo = ptc.crn_codigo
                                                            INNER JOIN
                                                            sgspi.estandar_normativo_catalogo AS enc
                                                            ON enc.enc_codigo = crn.enc_codigo
                                                     WHERE  plt.eia_codigo = i.eia_codigo
                                                            AND plt.plt_estado = 1
                                                            AND ptc.ptc_estado = 1
                                                            AND enc.enc_familia_norma = N'ISO27701'))
                       THROW 50020, N'Transición incompleta: APROBADO_PLANIFICADO sobre un activo con datos personales exige un control activo de la familia ISO27701 en [sgspi].[evento_incertidumbre_activo].', 1;
                   -- Paso 11: pasar a evaluación de eficacia exige al menos una actividad activa y todas completadas
                   IF EXISTS (SELECT 1
                              FROM   inserted AS i
                                     INNER JOIN
                                     deleted AS d
                                     ON d.eia_codigo = i.eia_codigo
                              WHERE  i.eia_fase_registro = N'EN_EVALUACION_EFICACIA'
                                     AND d.eia_fase_registro <> N'EN_EVALUACION_EFICACIA'
                                     AND (NOT EXISTS (SELECT 1
                                                      FROM   sgspi.plan_tratamiento AS plt
                                                             INNER JOIN
                                                             sgspi.actividad_tratamiento AS act
                                                             ON act.plt_codigo = plt.plt_codigo
                                                      WHERE  plt.eia_codigo = i.eia_codigo
                                                             AND plt.plt_estado = 1
                                                             AND act.act_estado = 1)
                                          OR EXISTS (SELECT 1
                                                     FROM   sgspi.plan_tratamiento AS plt
                                                            INNER JOIN
                                                            sgspi.actividad_tratamiento AS act
                                                            ON act.plt_codigo = plt.plt_codigo
                                                     WHERE  plt.eia_codigo = i.eia_codigo
                                                            AND plt.plt_estado = 1
                                                            AND act.act_estado = 1
                                                            AND act.act_fase_actividad <> N'COMPLETADA')))
                       THROW 50020, N'Transición incompleta: EN_EVALUACION_EFICACIA exige un plan activo con al menos una actividad activa y todas en COMPLETADA en [sgspi].[evento_incertidumbre_activo].', 1;
                   IF EXISTS (SELECT 1
                              FROM   inserted AS i
                                     INNER JOIN
                                     deleted AS d
                                     ON d.eia_codigo = i.eia_codigo
                              WHERE  i.eia_fase_registro = N'CERRADO_EFICAZ'
                                     AND d.eia_fase_registro <> N'CERRADO_EFICAZ'
                                     AND NOT EXISTS (SELECT 1
                                                     FROM   sgspi.plan_tratamiento AS plt
                                                     WHERE  plt.eia_codigo = i.eia_codigo
                                                            AND plt.plt_estado = 1
                                                            AND plt.plt_es_tratamiento_eficaz = 1))
                       THROW 50020, N'Transición incompleta: CERRADO_EFICAZ exige un plan de tratamiento dictaminado eficaz en [sgspi].[evento_incertidumbre_activo].', 1;
                    -- [B4] Cardinalidad mínima 1..N: APROBADO_PLANIFICADO exige >=1 actividad activa (act) y >=1 control normativo activo (ptc)
                    IF EXISTS (SELECT 1
                               FROM   inserted AS i
                                      INNER JOIN
                                      deleted AS d
                                      ON d.eia_codigo = i.eia_codigo
                               WHERE  i.eia_fase_registro = N'APROBADO_PLANIFICADO'
                                      AND d.eia_fase_registro <> N'APROBADO_PLANIFICADO'
                                      AND (NOT EXISTS (SELECT 1
                                                       FROM   sgspi.plan_tratamiento AS plt
                                                              INNER JOIN
                                                              sgspi.actividad_tratamiento AS act
                                                              ON act.plt_codigo = plt.plt_codigo
                                                       WHERE  plt.eia_codigo = i.eia_codigo
                                                              AND plt.plt_estado = 1
                                                              AND act.act_estado = 1)
                                           OR NOT EXISTS (SELECT 1
                                                          FROM   sgspi.plan_tratamiento AS plt
                                                                 INNER JOIN
                                                                 sgspi.plan_tratamiento_control_referencia_normativa AS ptc
                                                                 ON ptc.plt_codigo = plt.plt_codigo
                                                          WHERE  plt.eia_codigo = i.eia_codigo
                                                                 AND plt.plt_estado = 1
                                                                 AND ptc.ptc_estado = 1)))
                        THROW 50020, N'Transición incompleta: APROBADO_PLANIFICADO exige al menos una actividad activa ([act]) y un control normativo activo ([ptc]) en el plan de tratamiento de [sgspi].[evento_incertidumbre_activo].', 1;
                    -- [AP-01] [C2] Detecta filas con cambio real, actualiza fecha/firmas en 1 UPDATE y archiva after-image ('U')
                    DECLARE @cambiadas TABLE (
                        eia_codigo INT PRIMARY KEY);
                    INSERT INTO @cambiadas (
                        eia_codigo
                    )
                    SELECT i.eia_codigo
                    FROM   inserted AS i
                           INNER JOIN
                           deleted AS d
                           ON d.eia_codigo = i.eia_codigo
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
                                          i.eia_fase_registro,
                                          i.per_codigo_creador,
                                          i.per_codigo_validador_lider,
                                          i.per_codigo_revisor_sgspi,
                                          i.per_codigo_aprobador_comite,
                                          i.eia_fecha_actualizacion,
                                          i.eia_estado
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
                                          d.eia_fase_registro,
                                          d.per_codigo_creador,
                                          d.per_codigo_validador_lider,
                                          d.per_codigo_revisor_sgspi,
                                          d.per_codigo_aprobador_comite,
                                          d.eia_fecha_actualizacion,
                                          d.eia_estado);
                    DECLARE @ahora AS DATETIMEOFFSET (0) = SYSDATETIMEOFFSET();
                    DECLARE @actualizar_fecha AS BIT = CASE WHEN UPDATE (eia_fecha_actualizacion) THEN 0 ELSE 1 END;
                    IF EXISTS (SELECT 1
                               FROM   @cambiadas)
                        BEGIN
                            UPDATE t
                            SET    t.eia_fecha_actualizacion     = CASE WHEN @actualizar_fecha = 1 THEN @ahora ELSE t.eia_fecha_actualizacion END, -- [AP-11] [AP-12]
                                   t.per_codigo_validador_lider  = CASE WHEN d.eia_fase_registro <> i.eia_fase_registro
                                                                             AND i.eia_fase_registro IN (N'OBSERVADO', N'BORRADOR') THEN NULL WHEN d.eia_fase_registro = N'EN_VALIDACION_LIDER'
                                                                                                                                                     AND i.eia_fase_registro = N'EN_REVISION_SGSPI' THEN @per_actor ELSE t.per_codigo_validador_lider END,
                                   t.per_codigo_revisor_sgspi    = CASE WHEN d.eia_fase_registro <> i.eia_fase_registro
                                                                             AND i.eia_fase_registro IN (N'OBSERVADO', N'BORRADOR') THEN NULL WHEN d.eia_fase_registro = N'EN_REVISION_SGSPI'
                                                                                                                                                     AND i.eia_fase_registro IN (N'EN_ACEPTACION_COMITE', N'APROBADO_PLANIFICADO') THEN @per_actor ELSE t.per_codigo_revisor_sgspi END,
                                   t.per_codigo_aprobador_comite = CASE WHEN d.eia_fase_registro <> i.eia_fase_registro
                                                                             AND i.eia_fase_registro IN (N'OBSERVADO', N'BORRADOR') THEN NULL WHEN d.eia_fase_registro = N'EN_ACEPTACION_COMITE'
                                                                                                                                                     AND i.eia_fase_registro = N'APROBADO_PLANIFICADO' THEN @per_actor ELSE t.per_codigo_aprobador_comite END
                            FROM   sgspi.evento_incertidumbre_activo AS t
                                   INNER JOIN
                                   @cambiadas AS c
                                   ON c.eia_codigo = t.eia_codigo
                                   INNER JOIN
                                   inserted AS i
                                   ON i.eia_codigo = t.eia_codigo
                                   INNER JOIN
                                   deleted AS d
                                   ON d.eia_codigo = i.eia_codigo
                            WHERE  @actualizar_fecha = 1
                                   OR (d.eia_fase_registro = N'EN_VALIDACION_LIDER'
                                       AND i.eia_fase_registro = N'EN_REVISION_SGSPI')
                                   OR (d.eia_fase_registro = N'EN_REVISION_SGSPI'
                                       AND i.eia_fase_registro IN (N'EN_ACEPTACION_COMITE', N'APROBADO_PLANIFICADO'))
                                   OR (d.eia_fase_registro = N'EN_ACEPTACION_COMITE'
                                       AND i.eia_fase_registro = N'APROBADO_PLANIFICADO')
                                   OR (d.eia_fase_registro <> i.eia_fase_registro
                                       AND i.eia_fase_registro IN (N'OBSERVADO', N'BORRADOR'));
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
                                aea_fase_registro,
                                per_codigo_creador,
                                per_codigo_validador_lider,
                                per_codigo_revisor_sgspi,
                                per_codigo_aprobador_comite,
                                aea_fecha_actualizacion,
                                aea_estado,
                                per_codigo,
                                aea_operacion,
                                aea_usuario_bd,
                                aea_fecha_cambio
                            )
                            SELECT t.eia_codigo,
                                   t.pev_codigo,
                                   t.eia_numero_evento,
                                   t.eia_naturaleza_evento,
                                   t.pri_codigo,
                                   t.aci_codigo_primario,
                                   t.aci_codigo_soporte,
                                   t.tac_codigo_componente,
                                   t.eia_fuente_generadora,
                                   t.eia_controles_existentes,
                                   t.eia_condicion_vulnerabilidad,
                                   t.eia_efecto_consecuencia,
                                   t.eia_escenario_operacional,
                                   t.epr_codigo_inherente,
                                   t.eim_codigo_inherente,
                                   t.eia_fase_registro,
                                   t.per_codigo_creador,
                                   t.per_codigo_validador_lider,
                                   t.per_codigo_revisor_sgspi,
                                   t.per_codigo_aprobador_comite,
                                   t.eia_fecha_actualizacion,
                                   t.eia_estado,
                                   @per_actor,
                                   'U',
                                   ORIGINAL_LOGIN(),
                                   @ahora
                            FROM   sgspi.evento_incertidumbre_activo AS t
                                   INNER JOIN
                                   @cambiadas AS c
                                   ON c.eia_codigo = t.eia_codigo;
                        END
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
                   aea_fase_registro,
                   per_codigo_creador,
                   per_codigo_validador_lider,
                   per_codigo_revisor_sgspi,
                   per_codigo_aprobador_comite,
                   aea_fecha_actualizacion,
                   aea_estado,
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
                      i.eia_fase_registro,
                      i.per_codigo_creador,
                      i.per_codigo_validador_lider,
                      i.per_codigo_revisor_sgspi,
                      i.per_codigo_aprobador_comite,
                      i.eia_fecha_actualizacion,
                      i.eia_estado,
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
           -- [AP-24] Serializa el agregado por raíz (eia) en orden ascendente para evitar deadlocks AB-BA
           DECLARE @lock_id AS INT = (SELECT MIN(eia_codigo)
                                      FROM   (SELECT eia_codigo
                                              FROM   inserted
                                              UNION
                                              SELECT eia_codigo
                                              FROM   deleted) AS l), @lock_res AS NVARCHAR (60), @lock_rc AS INT;
           WHILE @lock_id IS NOT NULL
               BEGIN
                   SET @lock_res = CONCAT(N'sgspi:eia:', @lock_id);
                   EXECUTE @lock_rc = sys.sp_getapplock @Resource = @lock_res, @LockMode = 'Exclusive', @LockOwner = 'Transaction', @LockTimeout = 10000;
                   IF @lock_rc < 0
                       THROW 50023, N'Tiempo de espera agotado al adquirir bloqueo del agregado [sgspi:eia] en [sgspi].[plan_tratamiento].', 1;
                   SET @lock_id = (SELECT MIN(eia_codigo)
                                   FROM   (SELECT eia_codigo
                                           FROM   inserted
                                           UNION
                                           SELECT eia_codigo
                                           FROM   deleted) AS l
                                   WHERE  l.eia_codigo > @lock_id);
               END
           -- [B3] Inmutabilidad post-aprobación del plan de tratamiento:
           -- En INSERT solo se admite si eia está en fase de planificación editable (efc_permite_edicion = 1).
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
              AND EXISTS (SELECT 1
                          FROM   inserted AS x
                                 INNER JOIN
                                 sgspi.evento_incertidumbre_activo AS eia
                                 ON eia.eia_codigo = x.eia_codigo
                                 INNER JOIN
                                 sgspi.estado_flujo_catalogo AS efc
                                 ON efc.efc_dominio = N'EIA'
                                    AND efc.efc_identificador = eia.eia_fase_registro
                          WHERE  efc.efc_permite_edicion = 0
                                 OR efc.efc_estado = 0)
               THROW 50011, N'Operación denegada: No se permite crear un plan de tratamiento en un evento ya aprobado o cerrado en [sgspi].[plan_tratamiento].', 1;
           -- En UPDATE:
           -- - Estados cerrados/bloqueados (APROBADO_PLANIFICADO, CERRADO_EFICAZ, HISTORICO): prohibido todo cambio.
           -- - EN_EJECUCION: solo se permite actualizar plt_valor_alcanzado_kpi (y plt_fecha_actualizacion).
           -- - EN_EVALUACION_EFICACIA: solo se permiten los 4 campos del dictamen de eficacia (evaluados por el auditor).
           IF EXISTS (SELECT 1
                      FROM   deleted)
               BEGIN
                   IF EXISTS (SELECT 1
                              FROM   (SELECT eia_codigo
                                      FROM   inserted
                                      UNION
                                      SELECT eia_codigo
                                      FROM   deleted) AS x
                                     INNER JOIN
                                     sgspi.evento_incertidumbre_activo AS eia
                                     ON eia.eia_codigo = x.eia_codigo
                                     INNER JOIN
                                     sgspi.estado_flujo_catalogo AS efc
                                     ON efc.efc_dominio = N'EIA'
                                        AND efc.efc_identificador = eia.eia_fase_registro
                              WHERE  efc.efc_estado = 0
                                     OR (efc.efc_permite_edicion = 0
                                         AND eia.eia_fase_registro NOT IN (N'EN_EJECUCION', N'EN_EVALUACION_EFICACIA')))
                       THROW 50011, N'Operación denegada: No se permite modificar el plan de tratamiento de un evento aprobado o cerrado sin reabrirlo a OBSERVADO en [sgspi].[plan_tratamiento].', 1;
                   IF EXISTS (SELECT i.plt_codigo,
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
                                     i.plt_es_tratamiento_eficaz,
                                     i.plt_dictamen_eficacia,
                                     i.per_codigo_evaluador,
                                     i.plt_fecha_evaluacion_eficacia,
                                     i.plt_fecha_creacion,
                                     i.plt_estado
                              FROM   inserted AS i
                                     INNER JOIN
                                     sgspi.evento_incertidumbre_activo AS eia
                                     ON eia.eia_codigo = i.eia_codigo
                              WHERE  eia.eia_fase_registro = N'EN_EJECUCION'
                              EXCEPT
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
                                     d.plt_es_tratamiento_eficaz,
                                     d.plt_dictamen_eficacia,
                                     d.per_codigo_evaluador,
                                     d.plt_fecha_evaluacion_eficacia,
                                     d.plt_fecha_creacion,
                                     d.plt_estado
                              FROM   deleted AS d
                                     INNER JOIN
                                     sgspi.evento_incertidumbre_activo AS eia
                                     ON eia.eia_codigo = d.eia_codigo
                              WHERE  eia.eia_fase_registro = N'EN_EJECUCION')
                       THROW 50011, N'Operación denegada: en EN_EJECUCION solo puede actualizarse [plt_valor_alcanzado_kpi]; para alterar estrategia, meta residual o estado debe reabrir el evento a OBSERVADO en [sgspi].[plan_tratamiento].', 1;
                   IF EXISTS (SELECT i.plt_codigo,
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
                                     i.plt_fecha_creacion,
                                     i.plt_estado
                              FROM   inserted AS i
                                     INNER JOIN
                                     sgspi.evento_incertidumbre_activo AS eia
                                     ON eia.eia_codigo = i.eia_codigo
                              WHERE  eia.eia_fase_registro = N'EN_EVALUACION_EFICACIA'
                              EXCEPT
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
                                     d.plt_fecha_creacion,
                                     d.plt_estado
                              FROM   deleted AS d
                                     INNER JOIN
                                     sgspi.evento_incertidumbre_activo AS eia
                                     ON eia.eia_codigo = d.eia_codigo
                              WHERE  eia.eia_fase_registro = N'EN_EVALUACION_EFICACIA')
                       THROW 50011, N'Operación denegada: en EN_EVALUACION_EFICACIA solo el auditor puede registrar el dictamen de eficacia en [sgspi].[plan_tratamiento].', 1;
                   -- [B4] Protección anti-huérfanos en borrado lógico: no desactivar [plt] si tiene actividades o controles activos
                   IF EXISTS (SELECT 1
                              FROM   inserted AS i
                                     INNER JOIN
                                     deleted AS d
                                     ON d.plt_codigo = i.plt_codigo
                              WHERE  d.plt_estado = 1
                                     AND i.plt_estado = 0
                                     AND (EXISTS (SELECT 1
                                                  FROM   sgspi.actividad_tratamiento AS act
                                                  WHERE  act.plt_codigo = i.plt_codigo
                                                         AND act.act_estado = 1)
                                          OR EXISTS (SELECT 1
                                                     FROM   sgspi.plan_tratamiento_control_referencia_normativa AS ptc
                                                     WHERE  ptc.plt_codigo = i.plt_codigo
                                                            AND ptc.ptc_estado = 1)))
                       THROW 50020, N'Baja lógica denegada: existen actividades o controles activos asociados a [sgspi].[plan_tratamiento].', 1;
               END
           -- [AP-03] Persona de la sesión: firma el dictamen y queda en la auditoría
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona activa (usuario_administrativos/usuario_docentes.sys) para ORIGINAL_LOGIN().', 1;
           -- [AP-02] D5: los roles líder y custodio solo escriben en procesos de su alcance (ufn_proceso_en_alcance; LEFT JOIN evita bypass por RLS)
           IF EXISTS (SELECT 1
                      FROM   (SELECT eia_codigo
                              FROM   inserted
                              UNION
                              SELECT eia_codigo
                              FROM   deleted) AS x
                             LEFT OUTER JOIN
                             sgspi.evento_incertidumbre_activo AS eia
                             ON eia.eia_codigo = x.eia_codigo
                             OUTER APPLY sgspi.ufn_proceso_en_alcance(eia.pri_codigo, @per_actor) AS a
                      WHERE  a.permitido IS NULL)
               THROW 50021, N'Fuera de alcance: el proceso del evento no está en las UAA del usuario en [sgspi].[plan_tratamiento].', 1;
           -- [AP-15] [B4] Dictamen de eficacia nuevo o cambiado (EXCEPT trata NULL = NULL): solo en EN_EVALUACION_EFICACIA, con SoD completo (incluyendo aprobador comité) y firmado por la persona de la sesión
           DECLARE @dictamen TABLE (
               plt_codigo           INT PRIMARY KEY,
               eia_codigo           INT NOT NULL,
               per_codigo_evaluador INT NULL);
           INSERT INTO @dictamen (
               plt_codigo,
               eia_codigo,
               per_codigo_evaluador
           )
           SELECT i.plt_codigo,
                  i.eia_codigo,
                  i.per_codigo_evaluador
           FROM   inserted AS i
                  LEFT OUTER JOIN
                  deleted AS d
                  ON d.plt_codigo = i.plt_codigo
           WHERE  (d.plt_codigo IS NULL
                   AND i.per_codigo_evaluador IS NOT NULL)
                  OR (d.plt_codigo IS NOT NULL
                      AND EXISTS (SELECT i.plt_es_tratamiento_eficaz,
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
                              FROM   @dictamen AS x
                                     INNER JOIN
                                     sgspi.evento_incertidumbre_activo AS eia
                                     ON eia.eia_codigo = x.eia_codigo
                              WHERE  eia.eia_fase_registro <> N'EN_EVALUACION_EFICACIA')
                       THROW 50011, N'Estado inválido: el dictamen de eficacia solo puede registrarse o modificarse cuando el evento está en EN_EVALUACION_EFICACIA en [sgspi].[plan_tratamiento].', 1;
                   IF EXISTS (SELECT 1
                              FROM   @dictamen
                              WHERE  per_codigo_evaluador IS NOT NULL
                                     AND per_codigo_evaluador <> @per_actor)
                       THROW 50019, N'Evaluador inválido: [per_codigo_evaluador] debe ser la persona de la sesión en [sgspi].[plan_tratamiento].', 1;
                   IF EXISTS (SELECT 1
                              FROM   @dictamen AS x
                                     INNER JOIN
                                     sgspi.evento_incertidumbre_activo AS eia
                                     ON eia.eia_codigo = x.eia_codigo
                              WHERE  x.per_codigo_evaluador IS NOT NULL
                                     AND (@per_actor = eia.per_codigo_creador
                                          OR @per_actor = eia.per_codigo_validador_lider
                                          OR @per_actor = eia.per_codigo_revisor_sgspi
                                          OR @per_actor = eia.per_codigo_aprobador_comite))
                       THROW 50019, N'Segregación de funciones: el evaluador de eficacia no puede ser creador, validador líder, revisor SGSPI ni aprobador del comité del evento en [sgspi].[plan_tratamiento].', 1;
               END
           DECLARE @ahora AS DATETIMEOFFSET (0) = SYSDATETIMEOFFSET();
           IF EXISTS (SELECT 1
                      FROM   deleted)
               BEGIN
                   -- [AP-01] [C2] Detecta filas con cambio real, actualiza fechas en 1 UPDATE y archiva after-image ('U')
                   DECLARE @cambiadas TABLE (
                       plt_codigo INT PRIMARY KEY);
                   INSERT INTO @cambiadas (
                       plt_codigo
                   )
                   SELECT i.plt_codigo
                   FROM   inserted AS i
                          INNER JOIN
                          deleted AS d
                          ON d.plt_codigo = i.plt_codigo
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
                                         i.plt_estado
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
                                         d.plt_estado);
                   DECLARE @actualizar_fecha AS BIT = CASE WHEN UPDATE (plt_fecha_actualizacion) THEN 0 ELSE 1 END;
                   IF EXISTS (SELECT 1
                              FROM   @cambiadas)
                       BEGIN
                           UPDATE t
                           SET    t.plt_fecha_actualizacion       = CASE WHEN @actualizar_fecha = 1 THEN @ahora ELSE t.plt_fecha_actualizacion END, -- [AP-12]
                                  t.plt_fecha_evaluacion_eficacia = CASE WHEN x.per_codigo_evaluador IS NOT NULL THEN @ahora ELSE t.plt_fecha_evaluacion_eficacia END
                           FROM   sgspi.plan_tratamiento AS t
                                  INNER JOIN
                                  @cambiadas AS c
                                  ON c.plt_codigo = t.plt_codigo
                                  LEFT OUTER JOIN
                                  @dictamen AS x
                                  ON x.plt_codigo = t.plt_codigo
                           WHERE  @actualizar_fecha = 1
                                  OR x.per_codigo_evaluador IS NOT NULL;
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
                               apt_estado,
                               per_codigo,
                               apt_operacion,
                               apt_usuario_bd,
                               apt_fecha_cambio
                           )
                           SELECT t.plt_codigo,
                                  t.eia_codigo,
                                  t.plt_naturaleza_evento,
                                  t.etc_codigo,
                                  t.plt_justificacion_estrategia,
                                  t.epr_codigo_residual_meta,
                                  t.eim_codigo_residual_meta,
                                  t.plt_fecha_inicio,
                                  t.plt_fecha_fin,
                                  t.plt_recursos_humanos_tecnicos,
                                  t.plt_recursos_economicos_desc,
                                  t.plt_presupuesto_estimado_cop,
                                  t.plt_restricciones_limitaciones,
                                  t.plt_nombre_indicador_kpi,
                                  t.plt_unidad_medida_kpi,
                                  t.plt_meta_indicador_kpi,
                                  t.plt_valor_alcanzado_kpi,
                                  t.plt_es_tratamiento_eficaz,
                                  t.plt_dictamen_eficacia,
                                  t.per_codigo_evaluador,
                                  t.plt_fecha_evaluacion_eficacia,
                                  t.plt_fecha_actualizacion,
                                  t.plt_estado,
                                  @per_actor,
                                  'U',
                                  ORIGINAL_LOGIN(),
                                  @ahora
                           FROM   sgspi.plan_tratamiento AS t
                                  INNER JOIN
                                  @cambiadas AS c
                                  ON c.plt_codigo = t.plt_codigo;
                       END
               END
           ELSE
               BEGIN
                   IF EXISTS (SELECT 1
                              FROM   @dictamen
                              WHERE  per_codigo_evaluador IS NOT NULL)
                       UPDATE t
                       SET    t.plt_fecha_evaluacion_eficacia = @ahora -- [AP-12] [C2]
                       FROM   sgspi.plan_tratamiento AS t
                              INNER JOIN
                              @dictamen AS x
                              ON x.plt_codigo = t.plt_codigo
                       WHERE  x.per_codigo_evaluador IS NOT NULL;
                   -- [C2] Lee desde [t] tras el UPDATE interno para archivar @ahora real del servidor y no la fecha enviada por el cliente
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
                       apt_estado,
                       per_codigo,
                       apt_operacion,
                       apt_usuario_bd,
                       apt_fecha_cambio
                   )
                   SELECT t.plt_codigo,
                          t.eia_codigo,
                          t.plt_naturaleza_evento,
                          t.etc_codigo,
                          t.plt_justificacion_estrategia,
                          t.epr_codigo_residual_meta,
                          t.eim_codigo_residual_meta,
                          t.plt_fecha_inicio,
                          t.plt_fecha_fin,
                          t.plt_recursos_humanos_tecnicos,
                          t.plt_recursos_economicos_desc,
                          t.plt_presupuesto_estimado_cop,
                          t.plt_restricciones_limitaciones,
                          t.plt_nombre_indicador_kpi,
                          t.plt_unidad_medida_kpi,
                          t.plt_meta_indicador_kpi,
                          t.plt_valor_alcanzado_kpi,
                          t.plt_es_tratamiento_eficaz,
                          t.plt_dictamen_eficacia,
                          t.per_codigo_evaluador,
                          t.plt_fecha_evaluacion_eficacia,
                          t.plt_fecha_actualizacion,
                          t.plt_estado,
                          @per_actor,
                          'I',
                          ORIGINAL_LOGIN(),
                          @ahora
                   FROM   sgspi.plan_tratamiento AS t
                          INNER JOIN
                          inserted AS i
                          ON i.plt_codigo = t.plt_codigo;
               END
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
           -- [AP-24] Serializa el agregado por raíz (eia) en orden ascendente para evitar deadlocks AB-BA
           DECLARE @raices_eia TABLE (
               eia_codigo INT PRIMARY KEY);
           INSERT INTO @raices_eia (
               eia_codigo
           )
           SELECT DISTINCT plt.eia_codigo
           FROM   (SELECT plt_codigo
                   FROM   inserted
                   UNION
                   SELECT plt_codigo
                   FROM   deleted) AS x
                  INNER JOIN
                  sgspi.plan_tratamiento AS plt
                  ON plt.plt_codigo = x.plt_codigo;
           DECLARE @lock_id AS INT = (SELECT MIN(eia_codigo)
                                      FROM   @raices_eia), @lock_res AS NVARCHAR (60), @lock_rc AS INT;
           WHILE @lock_id IS NOT NULL
               BEGIN
                   SET @lock_res = CONCAT(N'sgspi:eia:', @lock_id);
                   EXECUTE @lock_rc = sys.sp_getapplock @Resource = @lock_res, @LockMode = 'Exclusive', @LockOwner = 'Transaction', @LockTimeout = 10000;
                   IF @lock_rc < 0
                       THROW 50023, N'Tiempo de espera agotado al adquirir bloqueo del agregado [sgspi:eia] en [sgspi].[actividad_tratamiento].', 1;
                   SET @lock_id = (SELECT MIN(eia_codigo)
                                   FROM   @raices_eia
                                   WHERE  eia_codigo > @lock_id);
               END
           -- [AP-04] En INSERT el estado debe ser el inicial del dominio
           IF EXISTS (SELECT 1
                      FROM   inserted AS i
                      WHERE  NOT EXISTS (SELECT 1
                                         FROM   deleted AS d
                                         WHERE  d.act_codigo = i.act_codigo)
                             AND NOT EXISTS (SELECT 1
                                             FROM   sgspi.estado_flujo_catalogo AS efc
                                             WHERE  efc.efc_dominio = N'ACT'
                                                    AND efc.efc_identificador = i.act_fase_actividad
                                                    AND efc.efc_es_inicial = 1
                                                    AND efc.efc_estado = 1))
               THROW 50014, N'Estado inicial inválido: un registro nuevo de [sgspi].[actividad_tratamiento] solo puede crearse en el estado inicial del flujo.', 1;
           -- [B3] Solo se tocan actividades en fases de planificación editables o durante la ejecución (APROBADO_PLANIFICADO / EN_EJECUCION)
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
                             INNER JOIN
                             sgspi.estado_flujo_catalogo AS efc
                             ON efc.efc_dominio = N'EIA'
                                AND efc.efc_identificador = eia.eia_fase_registro
                      WHERE  efc.efc_estado = 0
                             OR (efc.efc_permite_edicion = 0
                                 AND eia.eia_fase_registro NOT IN (N'APROBADO_PLANIFICADO', N'EN_EJECUCION')))
               THROW 50011, N'Operación denegada: No se permite insertar ni modificar actividades de un evento en evaluación de eficacia, cerrado o histórico en [sgspi].[actividad_tratamiento].', 1;
           -- [AP-03] Persona de la sesión: queda en la auditoría
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona activa (usuario_administrativos/usuario_docentes.sys) para ORIGINAL_LOGIN().', 1;
           -- [AP-02] D5: los roles líder y custodio solo escriben en procesos de su alcance (ufn_proceso_en_alcance; LEFT JOIN evita bypass por RLS)
           IF EXISTS (SELECT 1
                      FROM   (SELECT plt_codigo
                              FROM   inserted
                              UNION
                              SELECT plt_codigo
                              FROM   deleted) AS x
                             LEFT OUTER JOIN
                             sgspi.plan_tratamiento AS plt
                             ON plt.plt_codigo = x.plt_codigo
                             LEFT OUTER JOIN
                             sgspi.evento_incertidumbre_activo AS eia
                             ON eia.eia_codigo = plt.eia_codigo
                             OUTER APPLY sgspi.ufn_proceso_en_alcance(eia.pri_codigo, @per_actor) AS a
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
                              WHERE  (i.act_fase_actividad = d.act_fase_actividad
                                      AND EXISTS (SELECT 1
                                                  FROM   sgspi.estado_flujo_catalogo AS efc
                                                  WHERE  efc.efc_dominio = N'ACT'
                                                         AND efc.efc_identificador = d.act_fase_actividad
                                                         AND (efc.efc_permite_edicion = 0
                                                              OR efc.efc_estado = 0)))
                                     OR (i.act_fase_actividad <> d.act_fase_actividad
                                         AND NOT EXISTS (SELECT 1
                                                         FROM   sgspi.transicion_estado_flujo AS tef
                                                                INNER JOIN
                                                                sgspi.estado_flujo_catalogo AS efc_dest
                                                                ON efc_dest.efc_dominio = tef.efc_dominio
                                                                   AND efc_dest.efc_identificador = tef.efc_identificador_destino
                                                         WHERE  tef.efc_dominio = N'ACT'
                                                                AND tef.efc_identificador_origen = d.act_fase_actividad
                                                                AND tef.efc_identificador_destino = i.act_fase_actividad
                                                                AND tef.tef_estado = 1
                                                                AND efc_dest.efc_estado = 1
                                                                AND (tef.tef_rol_requerido IS NULL
                                                                     OR IS_MEMBER(tef.tef_rol_requerido) = 1
                                                                     OR IS_MEMBER(N'db_owner') = 1))))
                       THROW 50011, N'Transición de estado inválida o intento de modificar una actividad en estado no editable (COMPLETADA) en [sgspi].[actividad_tratamiento].', 1;
                   -- EXCEPT trata NULL = NULL: si cambia el estado, solo puede cambiar act_fase_actividad (si el origen o el destino no es editable)
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
                                     i.act_estado
                              FROM   inserted AS i
                                     INNER JOIN
                                     deleted AS d
                                     ON d.act_codigo = i.act_codigo
                              WHERE  i.act_fase_actividad <> d.act_fase_actividad
                                     AND EXISTS (SELECT 1
                                                 FROM   sgspi.estado_flujo_catalogo AS efc
                                                 WHERE  efc.efc_dominio = N'ACT'
                                                        AND efc.efc_identificador IN (d.act_fase_actividad, i.act_fase_actividad)
                                                        AND (efc.efc_permite_edicion = 0
                                                             OR efc.efc_estado = 0))
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
                                     d.act_estado
                              FROM   deleted AS d
                                     INNER JOIN
                                     inserted AS i
                                     ON i.act_codigo = d.act_codigo
                              WHERE  i.act_fase_actividad <> d.act_fase_actividad
                                     AND EXISTS (SELECT 1
                                                 FROM   sgspi.estado_flujo_catalogo AS efc
                                                 WHERE  efc.efc_dominio = N'ACT'
                                                        AND efc.efc_identificador IN (d.act_fase_actividad, i.act_fase_actividad)
                                                        AND (efc.efc_permite_edicion = 0
                                                             OR efc.efc_estado = 0)))
                       THROW 50011, N'No se permite modificar el contenido durante una transición de estado en [sgspi].[actividad_tratamiento].', 1;
                    -- [AP-01] [C2] Detecta filas con cambio real, actualiza fecha en 1 UPDATE y archiva after-image ('U')
                    DECLARE @cambiadas TABLE (
                        act_codigo INT PRIMARY KEY);
                    INSERT INTO @cambiadas (
                        act_codigo
                    )
                    SELECT i.act_codigo
                    FROM   inserted AS i
                           INNER JOIN
                           deleted AS d
                           ON d.act_codigo = i.act_codigo
                    WHERE  EXISTS (SELECT i.plt_codigo,
                                          i.act_numero_orden,
                                          i.act_descripcion_actividad,
                                          i.car_codigo,
                                          i.uaa_codigo,
                                          i.act_fecha_compromiso,
                                          i.act_porcentaje_avance,
                                          i.act_fase_actividad,
                                          i.act_fecha_actualizacion,
                                          i.act_estado
                                   EXCEPT
                                   SELECT d.plt_codigo,
                                          d.act_numero_orden,
                                          d.act_descripcion_actividad,
                                          d.car_codigo,
                                          d.uaa_codigo,
                                          d.act_fecha_compromiso,
                                          d.act_porcentaje_avance,
                                          d.act_fase_actividad,
                                          d.act_fecha_actualizacion,
                                          d.act_estado);
                    DECLARE @ahora AS DATETIMEOFFSET (0) = SYSDATETIMEOFFSET();
                    IF EXISTS (SELECT 1
                               FROM   @cambiadas)
                        BEGIN
                            IF NOT UPDATE (act_fecha_actualizacion)
                                UPDATE t
                                SET    t.act_fecha_actualizacion = @ahora -- [AP-12]
                                FROM   sgspi.actividad_tratamiento AS t
                                       INNER JOIN
                                       @cambiadas AS c
                                       ON c.act_codigo = t.act_codigo;
                            INSERT INTO sgspi.aud_actividad_tratamiento (
                                act_codigo,
                                plt_codigo,
                                aat_numero_orden,
                                aat_descripcion_actividad,
                                car_codigo,
                                uaa_codigo,
                                aat_fecha_compromiso,
                                aat_porcentaje_avance,
                                aat_fase_actividad,
                                aat_fecha_actualizacion,
                                aat_estado,
                                per_codigo,
                                aat_operacion,
                                aat_usuario_bd,
                                aat_fecha_cambio
                            )
                            SELECT t.act_codigo,
                                   t.plt_codigo,
                                   t.act_numero_orden,
                                   t.act_descripcion_actividad,
                                   t.car_codigo,
                                   t.uaa_codigo,
                                   t.act_fecha_compromiso,
                                   t.act_porcentaje_avance,
                                   t.act_fase_actividad,
                                   t.act_fecha_actualizacion,
                                   t.act_estado,
                                   @per_actor,
                                   'U',
                                   ORIGINAL_LOGIN(),
                                   @ahora
                            FROM   sgspi.actividad_tratamiento AS t
                                   INNER JOIN
                                   @cambiadas AS c
                                   ON c.act_codigo = t.act_codigo;
                        END
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
                   aat_fase_actividad,
                   aat_fecha_actualizacion,
                   aat_estado,
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
                      i.act_fase_actividad,
                      i.act_fecha_actualizacion,
                      i.act_estado,
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
               THROW 50017, N'No se encontró una persona activa (usuario_administrativos/usuario_docentes.sys) para ORIGINAL_LOGIN().', 1;
           -- D7: no se crean registros ni se mueven a una vigencia cerrada o histórica
           IF EXISTS (SELECT 1
                      FROM   inserted AS i
                             INNER JOIN
                             sgspi.periodo_vigencia AS pev
                             ON pev.pev_codigo = i.pev_codigo
                      WHERE  pev.pev_fase_vigencia IN (N'CERRADA', N'HISTORICA')
                             AND NOT EXISTS (SELECT 1
                                             FROM   deleted AS d
                                             WHERE  d.eac_codigo = i.eac_codigo
                                                    AND d.pev_codigo = i.pev_codigo))
               THROW 50022, N'Vigencia cerrada: no se crean registros ni se mueven a una vigencia CERRADA o HISTORICA en [sgspi].[evaluacion_aplicabilidad_control].', 1;
           IF EXISTS (SELECT 1
                      FROM   deleted)
               BEGIN
                    -- [AP-01] [C2] Detecta filas con cambio real, actualiza fecha en 1 UPDATE y archiva after-image ('U')
                    DECLARE @cambiadas TABLE (
                        eac_codigo INT PRIMARY KEY);
                    INSERT INTO @cambiadas (
                        eac_codigo
                    )
                    SELECT i.eac_codigo
                    FROM   inserted AS i
                           INNER JOIN
                           deleted AS d
                           ON d.eac_codigo = i.eac_codigo
                    WHERE  EXISTS (SELECT i.pev_codigo,
                                          i.crn_codigo,
                                          i.eac_es_aplicable,
                                          i.eac_justificacion_aplicabilidad,
                                          i.eac_documento_soporte_normativo,
                                          i.car_codigo,
                                          i.pdc_codigo,
                                          i.eac_evidencia_objetiva_esperada,
                                          i.eac_fase_implementacion,
                                          i.eac_observaciones_auditoria,
                                          i.eac_fecha_actualizacion,
                                          i.eac_estado
                                   EXCEPT
                                   SELECT d.pev_codigo,
                                          d.crn_codigo,
                                          d.eac_es_aplicable,
                                          d.eac_justificacion_aplicabilidad,
                                          d.eac_documento_soporte_normativo,
                                          d.car_codigo,
                                          d.pdc_codigo,
                                          d.eac_evidencia_objetiva_esperada,
                                          d.eac_fase_implementacion,
                                          d.eac_observaciones_auditoria,
                                          d.eac_fecha_actualizacion,
                                          d.eac_estado);
                    DECLARE @ahora AS DATETIMEOFFSET (0) = SYSDATETIMEOFFSET();
                    IF EXISTS (SELECT 1
                               FROM   @cambiadas)
                        BEGIN
                            IF NOT UPDATE (eac_fecha_actualizacion)
                                UPDATE t
                                SET    t.eac_fecha_actualizacion = @ahora -- [AP-11] [AP-12]
                                FROM   sgspi.evaluacion_aplicabilidad_control AS t
                                       INNER JOIN
                                       @cambiadas AS c
                                       ON c.eac_codigo = t.eac_codigo;
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
                                aae_fase_implementacion,
                                aae_observaciones_auditoria,
                                aae_fecha_actualizacion,
                                aae_estado,
                                per_codigo,
                                aae_operacion,
                                aae_usuario_bd,
                                aae_fecha_cambio
                            )
                            SELECT t.eac_codigo,
                                   t.pev_codigo,
                                   t.crn_codigo,
                                   t.eac_es_aplicable,
                                   t.eac_justificacion_aplicabilidad,
                                   t.eac_documento_soporte_normativo,
                                   t.car_codigo,
                                   t.pdc_codigo,
                                   t.eac_evidencia_objetiva_esperada,
                                   t.eac_fase_implementacion,
                                   t.eac_observaciones_auditoria,
                                   t.eac_fecha_actualizacion,
                                   t.eac_estado,
                                   @per_actor,
                                   'U',
                                   ORIGINAL_LOGIN(),
                                   @ahora
                            FROM   sgspi.evaluacion_aplicabilidad_control AS t
                                   INNER JOIN
                                   @cambiadas AS c
                                   ON c.eac_codigo = t.eac_codigo;
                        END
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
                   aae_fase_implementacion,
                   aae_observaciones_auditoria,
                   aae_fecha_actualizacion,
                   aae_estado,
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
                      i.eac_fase_implementacion,
                      i.eac_observaciones_auditoria,
                      i.eac_fecha_actualizacion,
                      i.eac_estado,
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
-- Inmutabilidad: el seguimiento con evidencia es append-only; solo admite el borrado lógico (sga_estado) [AP-22]
CREATE OR ALTER TRIGGER sgspi.TR_sga_inmutabilidad
    ON sgspi.seguimiento_actividad
    AFTER UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           -- EXCEPT trata NULL = NULL: cualquier diferencia fuera de sga_estado es una edición prohibida
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
               THROW 50016, N'Operación denegada: el seguimiento de actividades con evidencia es append-only (solo se puede desactivar con sga_estado = 0); registre un nuevo seguimiento en [sgspi].[seguimiento_actividad].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           -- [AP-24] [B2] Orden unificado applock(eia) -> act (sin UPDLOCK previo a applock): elimina deadlock AB-BA con UPDATE eia + UPDATE act
           DECLARE @raices_eia TABLE (
               eia_codigo INT PRIMARY KEY);
           INSERT INTO @raices_eia (
               eia_codigo
           )
           SELECT DISTINCT plt.eia_codigo
           FROM   sgspi.actividad_tratamiento AS act
                  INNER JOIN
                  sgspi.plan_tratamiento AS plt
                  ON plt.plt_codigo = act.plt_codigo
           WHERE  act.act_codigo IN (SELECT act_codigo
                                     FROM   inserted);
           DECLARE @lock_id AS INT = (SELECT MIN(eia_codigo)
                                      FROM   @raices_eia), @lock_res AS NVARCHAR (60), @lock_rc AS INT;
           WHILE @lock_id IS NOT NULL
               BEGIN
                   SET @lock_res = CONCAT(N'sgspi:eia:', @lock_id);
                   EXECUTE @lock_rc = sys.sp_getapplock @Resource = @lock_res, @LockMode = 'Exclusive', @LockOwner = 'Transaction', @LockTimeout = 10000;
                   IF @lock_rc < 0
                       THROW 50023, N'Tiempo de espera agotado al adquirir bloqueo del agregado [sgspi:eia] en [sgspi].[seguimiento_actividad].', 1;
                   SET @lock_id = (SELECT MIN(eia_codigo)
                                   FROM   @raices_eia
                                   WHERE  eia_codigo > @lock_id);
               END
           -- [B2] [B3] Validación explícita de estado de actividad y evento (cierra bypass cuando act_porcentaje_avance ya es 100%)
           IF EXISTS (SELECT 1
                      FROM   inserted AS x
                             INNER JOIN
                             sgspi.actividad_tratamiento AS act
                             ON act.act_codigo = x.act_codigo
                             INNER JOIN
                             sgspi.estado_flujo_catalogo AS efc_act
                             ON efc_act.efc_dominio = N'ACT'
                                AND efc_act.efc_identificador = act.act_fase_actividad
                             INNER JOIN
                             sgspi.plan_tratamiento AS plt
                             ON plt.plt_codigo = act.plt_codigo
                             INNER JOIN
                             sgspi.evento_incertidumbre_activo AS eia
                             ON eia.eia_codigo = plt.eia_codigo
                             INNER JOIN
                             sgspi.estado_flujo_catalogo AS efc_eia
                             ON efc_eia.efc_dominio = N'EIA'
                                AND efc_eia.efc_identificador = eia.eia_fase_registro
                      WHERE  act.act_estado = 0
                             OR efc_act.efc_permite_edicion = 0
                             OR efc_act.efc_estado = 0
                             OR efc_eia.efc_estado = 0
                             OR (efc_eia.efc_permite_edicion = 0
                                 AND eia.eia_fase_registro NOT IN (N'APROBADO_PLANIFICADO', N'EN_EJECUCION')))
               THROW 50011, N'Operación denegada: No se permite alterar seguimientos de una actividad completada/inactiva o de un evento en evaluación de eficacia, cerrado o histórico en [sgspi].[seguimiento_actividad].', 1;
           -- [AP-03] Persona de la sesión: queda en la auditoría
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona activa (usuario_administrativos/usuario_docentes.sys) para ORIGINAL_LOGIN().', 1;
           -- [AP-02] D5: los roles líder y custodio solo desactivan seguimientos de procesos de su alcance
           IF EXISTS (SELECT 1
                      FROM   inserted AS x
                             LEFT OUTER JOIN
                             sgspi.actividad_tratamiento AS act
                             ON act.act_codigo = x.act_codigo
                             LEFT OUTER JOIN
                             sgspi.plan_tratamiento AS plt
                             ON plt.plt_codigo = act.plt_codigo
                             LEFT OUTER JOIN
                             sgspi.evento_incertidumbre_activo AS eia
                             ON eia.eia_codigo = plt.eia_codigo
                             OUTER APPLY sgspi.ufn_proceso_en_alcance(eia.pri_codigo, @per_actor) AS a
                      WHERE  a.permitido IS NULL)
               THROW 50021, N'Fuera de alcance: el proceso del evento no está en las UAA del usuario en [sgspi].[seguimiento_actividad].', 1;
           -- [AP-01] [C2] Archiva after-image ('U') de las filas que cambian, con quién y cuándo
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
               asa_estado,
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
                  i.sga_estado,
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
                                 i.sga_estado
                          EXCEPT
                          SELECT d.act_codigo,
                                 d.per_codigo,
                                 d.sga_fecha_registro,
                                 d.sga_porcentaje_reportado,
                                 d.sga_descripcion_avance,
                                 d.sga_nombre_archivo_evidencia,
                                 d.sga_uri_almacenamiento_evidencia,
                                 d.sga_hash_sha256_evidencia,
                                 d.sga_estado);
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
                   WHERE  i.sga_estado <> d.sga_estado) AS x
                  ON x.act_codigo = act.act_codigo
                  OUTER APPLY (SELECT   TOP (1) s.sga_porcentaje_reportado
                               FROM     sgspi.seguimiento_actividad AS s
                               WHERE    s.act_codigo = act.act_codigo
                                        AND s.sga_estado = 1
                               ORDER BY s.sga_codigo DESC) AS u
           WHERE  act.act_porcentaje_avance <> ISNULL(u.sga_porcentaje_reportado, 0);
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [AP-09] El avance de la actividad deja de ser un dato duplicado y desincronizado: se deriva del último seguimiento reportado.
-- [B2] Adquiere applock(eia) antes de validar/actualizar [act] y bloquea explícitamente actividades completadas o eventos cerrados.
CREATE OR ALTER TRIGGER sgspi.TR_sga_sincronizar_avance
    ON sgspi.seguimiento_actividad
    AFTER INSERT
    AS BEGIN
           SET NOCOUNT ON;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           -- [AP-24] [B2] Orden unificado applock(eia) -> act (sin UPDLOCK previo a applock)
           DECLARE @raices_eia TABLE (
               eia_codigo INT PRIMARY KEY);
           INSERT INTO @raices_eia (
               eia_codigo
           )
           SELECT DISTINCT plt.eia_codigo
           FROM   sgspi.actividad_tratamiento AS act
                  INNER JOIN
                  sgspi.plan_tratamiento AS plt
                  ON plt.plt_codigo = act.plt_codigo
           WHERE  act.act_codigo IN (SELECT act_codigo
                                     FROM   inserted);
           DECLARE @lock_id AS INT = (SELECT MIN(eia_codigo)
                                      FROM   @raices_eia), @lock_res AS NVARCHAR (60), @lock_rc AS INT;
           WHILE @lock_id IS NOT NULL
               BEGIN
                   SET @lock_res = CONCAT(N'sgspi:eia:', @lock_id);
                   EXECUTE @lock_rc = sys.sp_getapplock @Resource = @lock_res, @LockMode = 'Exclusive', @LockOwner = 'Transaction', @LockTimeout = 10000;
                   IF @lock_rc < 0
                       THROW 50023, N'Tiempo de espera agotado al adquirir bloqueo del agregado [sgspi:eia] en [sgspi].[seguimiento_actividad].', 1;
                   SET @lock_id = (SELECT MIN(eia_codigo)
                                   FROM   @raices_eia
                                   WHERE  eia_codigo > @lock_id);
               END
           -- [B2] [B3] Validación explícita de estado de actividad y evento (cierra bypass cuando act_porcentaje_avance ya es 100%)
           IF EXISTS (SELECT 1
                      FROM   inserted AS x
                             INNER JOIN
                             sgspi.actividad_tratamiento AS act
                             ON act.act_codigo = x.act_codigo
                             INNER JOIN
                             sgspi.estado_flujo_catalogo AS efc_act
                             ON efc_act.efc_dominio = N'ACT'
                                AND efc_act.efc_identificador = act.act_fase_actividad
                             INNER JOIN
                             sgspi.plan_tratamiento AS plt
                             ON plt.plt_codigo = act.plt_codigo
                             INNER JOIN
                             sgspi.evento_incertidumbre_activo AS eia
                             ON eia.eia_codigo = plt.eia_codigo
                             INNER JOIN
                             sgspi.estado_flujo_catalogo AS efc_eia
                             ON efc_eia.efc_dominio = N'EIA'
                                AND efc_eia.efc_identificador = eia.eia_fase_registro
                      WHERE  act.act_estado = 0
                             OR efc_act.efc_permite_edicion = 0
                             OR efc_act.efc_estado = 0
                             OR efc_eia.efc_estado = 0
                             OR (efc_eia.efc_permite_edicion = 0
                                 AND eia.eia_fase_registro NOT IN (N'APROBADO_PLANIFICADO', N'EN_EJECUCION')))
               THROW 50011, N'Operación denegada: No se permite registrar seguimientos sobre una actividad completada/inactiva o un evento en evaluación de eficacia, cerrado o histórico en [sgspi].[seguimiento_actividad].', 1;
           -- [AP-03] [AP-15] El seguimiento lo registra la persona de la sesión
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona activa (usuario_administrativos/usuario_docentes.sys) para ORIGINAL_LOGIN().', 1;
           IF EXISTS (SELECT 1
                      FROM   inserted
                      WHERE  per_codigo <> @per_actor)
               THROW 50019, N'Autor inválido: [per_codigo] debe ser la persona de la sesión en [sgspi].[seguimiento_actividad].', 1;
           -- [AP-02] D5: los roles líder y custodio solo reportan avances de procesos de su alcance (LEFT JOIN evita bypass por RLS)
           IF EXISTS (SELECT 1
                      FROM   inserted AS x
                             LEFT OUTER JOIN
                             sgspi.actividad_tratamiento AS act
                             ON act.act_codigo = x.act_codigo
                             LEFT OUTER JOIN
                             sgspi.plan_tratamiento AS plt
                             ON plt.plt_codigo = act.plt_codigo
                             LEFT OUTER JOIN
                             sgspi.evento_incertidumbre_activo AS eia
                             ON eia.eia_codigo = plt.eia_codigo
                             OUTER APPLY sgspi.ufn_proceso_en_alcance(eia.pri_codigo, @per_actor) AS a
                      WHERE  a.permitido IS NULL)
               THROW 50021, N'Fuera de alcance: el proceso del evento no está en las UAA del usuario en [sgspi].[seguimiento_actividad].', 1;
           -- Recalcula desde el último seguimiento activo por sga_codigo (serializado por applock en eia)
           UPDATE act
           SET    act.act_porcentaje_avance = ISNULL(u.sga_porcentaje_reportado, 0)
           FROM   sgspi.actividad_tratamiento AS act
                  INNER JOIN
                  (SELECT DISTINCT i.act_codigo
                   FROM   inserted AS i) AS x
                  ON x.act_codigo = act.act_codigo
                  OUTER APPLY (SELECT   TOP (1) s.sga_porcentaje_reportado
                               FROM     sgspi.seguimiento_actividad AS s
                               WHERE    s.act_codigo = act.act_codigo
                                        AND s.sga_estado = 1
                               ORDER BY s.sga_codigo DESC) AS u
           WHERE  act.act_porcentaje_avance <> ISNULL(u.sga_porcentaje_reportado, 0);
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
               asa_estado,
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
                  i.sga_estado,
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
-- 5.10.9b Triggers de auditoría [AP-01]: inmutabilidad de las 49 tablas aud_* y archivo after-image de altas ('I') y modificaciones ('U')
-- en las 40 tablas cuyo trigger no se actualiza a sí mismo (las otras 9 lo hacen dentro de su trigger, ver 5.9).
-- En las 10 tablas puente (rpp, aip, ais, air, ads, adm, adi, adf, adu, ptc) y en sif/msi, el mismo trigger valida
-- primero bloqueo de padre/alcance (con serialización por raíz sp_getapplock en familias aci/eia) y luego audita.
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
-- [pev] Bloquea el borrado físico y archiva en [sgspi].[aud_periodo_vigencia] las altas ('I') y la versión resultante (after-image) de cada fila modificada ('U')
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
               THROW 50017, N'No se encontró una persona activa (usuario_administrativos/usuario_docentes.sys) para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_periodo_vigencia (
                       pev_codigo,
                       apv_anio,
                       apv_fecha_apertura,
                       apv_fecha_cierre,
                       apv_fase_vigencia,
                       apv_estado,
                       per_codigo,
                       apv_operacion,
                       apv_usuario_bd,
                       apv_fecha_cambio
                   )
                   SELECT i.pev_codigo,
                          i.pev_anio,
                          i.pev_fecha_apertura,
                          i.pev_fecha_cierre,
                          i.pev_fase_vigencia,
                          i.pev_estado,
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
               apv_fase_vigencia,
               apv_estado,
               per_codigo,
               apv_operacion,
               apv_usuario_bd,
               apv_fecha_cambio
           )
           SELECT i.pev_codigo,
                  i.pev_anio,
                  i.pev_fecha_apertura,
                  i.pev_fecha_cierre,
                  i.pev_fase_vigencia,
                  i.pev_estado,
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
                                 i.pev_fase_vigencia,
                                 i.pev_estado
                          EXCEPT
                          SELECT d.pev_anio,
                                 d.pev_fecha_apertura,
                                 d.pev_fecha_cierre,
                                 d.pev_fase_vigencia,
                                 d.pev_estado);
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
-- [efc] Bloquea el borrado físico y archiva en [sgspi].[aud_estado_flujo_catalogo] las altas ('I') y la versión resultante (after-image) de cada fila modificada ('U')
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
               THROW 50017, N'No se encontró una persona activa (usuario_administrativos/usuario_docentes.sys) para ORIGINAL_LOGIN().', 1;
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
                       aec_estado,
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
                          i.efc_estado,
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
               aec_estado,
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
                  i.efc_estado,
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
                                 i.efc_estado
                          EXCEPT
                          SELECT d.efc_dominio,
                                 d.efc_identificador,
                                 d.efc_nombre,
                                 d.efc_es_inicial,
                                 d.efc_permite_edicion,
                                 d.efc_estado);
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
-- [tef] Bloquea el borrado físico y archiva en [sgspi].[aud_transicion_estado_flujo] las altas ('I') y la versión resultante (after-image) de cada fila modificada ('U')
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
               THROW 50017, N'No se encontró una persona activa (usuario_administrativos/usuario_docentes.sys) para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_transicion_estado_flujo (
                       tef_codigo,
                       efc_dominio,
                       efc_identificador_origen,
                       efc_identificador_destino,
                       atf_rol_requerido,
                       atf_estado,
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
                          i.tef_estado,
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
               atf_estado,
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
                  i.tef_estado,
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
                                 i.tef_estado
                          EXCEPT
                          SELECT d.efc_dominio,
                                 d.efc_identificador_origen,
                                 d.efc_identificador_destino,
                                 d.tef_rol_requerido,
                                 d.tef_estado);
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
-- [tpr] Bloquea el borrado físico y archiva en [sgspi].[aud_tipo_proceso_catalogo] las altas ('I') y la versión resultante (after-image) de cada fila modificada ('U')
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
               THROW 50017, N'No se encontró una persona activa (usuario_administrativos/usuario_docentes.sys) para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_tipo_proceso_catalogo (
                       tpr_codigo,
                       atr_identificador,
                       atr_nombre,
                       atr_descripcion,
                       atr_estado,
                       per_codigo,
                       atr_operacion,
                       atr_usuario_bd,
                       atr_fecha_cambio
                   )
                   SELECT i.tpr_codigo,
                          i.tpr_identificador,
                          i.tpr_nombre,
                          i.tpr_descripcion,
                          i.tpr_estado,
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
               atr_estado,
               per_codigo,
               atr_operacion,
               atr_usuario_bd,
               atr_fecha_cambio
           )
           SELECT i.tpr_codigo,
                  i.tpr_identificador,
                  i.tpr_nombre,
                  i.tpr_descripcion,
                  i.tpr_estado,
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
                                 i.tpr_estado
                          EXCEPT
                          SELECT d.tpr_identificador,
                                 d.tpr_nombre,
                                 d.tpr_descripcion,
                                 d.tpr_estado);
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
-- [pri] Bloquea el borrado físico y archiva en [sgspi].[aud_proceso_institucional] las altas ('I') y la versión resultante (after-image) de cada fila modificada ('U')
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
               THROW 50017, N'No se encontró una persona activa (usuario_administrativos/usuario_docentes.sys) para ORIGINAL_LOGIN().', 1;
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
                       api_estado,
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
                          i.pri_estado,
                          @per_actor,
                          'I',
                          ORIGINAL_LOGIN(),
                          SYSDATETIMEOFFSET()
                   FROM   inserted AS i;
                   RETURN;
               END
           -- [B4] Coherencia uaa_codigo_lider <-> piu en UPDATE: si cambia a una UAA líder no nula, exige asociación activa en [piu]
           IF EXISTS (SELECT 1
                      FROM   inserted AS i
                             INNER JOIN
                             deleted AS d
                             ON d.pri_codigo = i.pri_codigo
                      WHERE  i.uaa_codigo_lider IS NOT NULL
                             AND (d.uaa_codigo_lider IS NULL
                                  OR i.uaa_codigo_lider <> d.uaa_codigo_lider)
                             AND NOT EXISTS (SELECT 1
                                             FROM   sgspi.proceso_institucional_uaa AS piu
                                             WHERE  piu.pri_codigo = i.pri_codigo
                                                    AND piu.uaa_codigo = i.uaa_codigo_lider
                                                    AND piu.piu_estado = 1))
               THROW 50020, N'Coherencia de liderazgo: [uaa_codigo_lider] debe existir activa en [sgspi].[proceso_institucional_uaa] antes de asignarse en [sgspi].[proceso_institucional].', 1;
           -- [B4] Protección anti-huérfanos en borrado lógico: no desactivar [pri] si tiene hijos activos
           IF EXISTS (SELECT 1
                      FROM   inserted AS i
                             INNER JOIN
                             deleted AS d
                             ON d.pri_codigo = i.pri_codigo
                      WHERE  d.pri_estado = 1
                             AND i.pri_estado = 0
                             AND (EXISTS (SELECT 1
                                          FROM   sgspi.proceso_institucional_uaa AS piu
                                          WHERE  piu.pri_codigo = i.pri_codigo
                                                 AND piu.piu_estado = 1)
                                  OR EXISTS (SELECT 1
                                             FROM   sgspi.analisis_contexto_factor AS acf
                                             WHERE  acf.pri_codigo = i.pri_codigo
                                                    AND acf.acf_estado = 1)
                                  OR EXISTS (SELECT 1
                                             FROM   sgspi.requisito_parte_interesada_proceso_institucional AS rpp
                                             WHERE  rpp.pri_codigo = i.pri_codigo
                                                    AND rpp.rpp_estado = 1)
                                  OR EXISTS (SELECT 1
                                             FROM   sgspi.activo_informacion_proceso_institucional AS aip
                                             WHERE  aip.pri_codigo = i.pri_codigo
                                                    AND aip.aip_estado = 1)
                                  OR EXISTS (SELECT 1
                                             FROM   sgspi.evento_incertidumbre_activo AS eia
                                             WHERE  eia.pri_codigo = i.pri_codigo
                                                    AND eia.eia_estado = 1)))
               THROW 50020, N'Baja lógica denegada: existen registros hijos activos asociados a [sgspi].[proceso_institucional].', 1;
           INSERT INTO sgspi.aud_proceso_institucional (
               pri_codigo,
               api_identificador,
               api_nombre,
               tpr_codigo,
               uaa_codigo_lider,
               car_codigo_lider,
               api_estado,
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
                  i.pri_estado,
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
                                 i.pri_estado
                          EXCEPT
                          SELECT d.pri_identificador,
                                 d.pri_nombre,
                                 d.tpr_codigo,
                                 d.uaa_codigo_lider,
                                 d.car_codigo_lider,
                                 d.pri_estado);
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
-- [piu] Bloquea el borrado físico y archiva en [sgspi].[aud_proceso_institucional_uaa] las altas ('I') y la versión resultante (after-image) de cada fila modificada ('U')
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
               THROW 50017, N'No se encontró una persona activa (usuario_administrativos/usuario_docentes.sys) para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_proceso_institucional_uaa (
                       pri_codigo,
                       uaa_codigo,
                       apu_estado,
                       per_codigo,
                       apu_operacion,
                       apu_usuario_bd,
                       apu_fecha_cambio
                   )
                   SELECT i.pri_codigo,
                          i.uaa_codigo,
                          i.piu_estado,
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
           -- [B4] No desactivar la UAA líder de un proceso activo sin cambiar antes [pri].[uaa_codigo_lider]
           IF EXISTS (SELECT 1
                      FROM   inserted AS i
                             INNER JOIN
                             deleted AS d
                             ON d.pri_codigo = i.pri_codigo
                                AND d.uaa_codigo = i.uaa_codigo
                             INNER JOIN
                             sgspi.proceso_institucional AS pri
                             ON pri.pri_codigo = i.pri_codigo
                      WHERE  d.piu_estado = 1
                             AND i.piu_estado = 0
                             AND pri.pri_estado = 1
                             AND pri.uaa_codigo_lider = i.uaa_codigo)
               THROW 50020, N'Baja lógica denegada: la UAA es [uaa_codigo_lider] del proceso activo en [sgspi].[proceso_institucional].', 1;
           INSERT INTO sgspi.aud_proceso_institucional_uaa (
               pri_codigo,
               uaa_codigo,
               apu_estado,
               per_codigo,
               apu_operacion,
               apu_usuario_bd,
               apu_fecha_cambio
           )
           SELECT i.pri_codigo,
                  i.uaa_codigo,
                  i.piu_estado,
                  @per_actor,
                  'U',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   deleted AS d
                  INNER JOIN
                  inserted AS i
                  ON i.pri_codigo = d.pri_codigo
                     AND i.uaa_codigo = d.uaa_codigo
           WHERE  EXISTS (SELECT i.piu_estado
                          EXCEPT
                          SELECT d.piu_estado);
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
-- [fec] Bloquea el borrado físico y archiva en [sgspi].[aud_factor_entorno_catalogo] las altas ('I') y la versión resultante (after-image) de cada fila modificada ('U')
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
               THROW 50017, N'No se encontró una persona activa (usuario_administrativos/usuario_docentes.sys) para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_factor_entorno_catalogo (
                       fec_codigo,
                       afc_nombre_factor,
                       afc_ambito_entorno,
                       afc_descripcion,
                       afc_estado,
                       per_codigo,
                       afc_operacion,
                       afc_usuario_bd,
                       afc_fecha_cambio
                   )
                   SELECT i.fec_codigo,
                          i.fec_nombre_factor,
                          i.fec_ambito_entorno,
                          i.fec_descripcion,
                          i.fec_estado,
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
               afc_estado,
               per_codigo,
               afc_operacion,
               afc_usuario_bd,
               afc_fecha_cambio
           )
           SELECT i.fec_codigo,
                  i.fec_nombre_factor,
                  i.fec_ambito_entorno,
                  i.fec_descripcion,
                  i.fec_estado,
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
                                 i.fec_estado
                          EXCEPT
                          SELECT d.fec_nombre_factor,
                                 d.fec_ambito_entorno,
                                 d.fec_descripcion,
                                 d.fec_estado);
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
-- [pai] Bloquea el borrado físico y archiva en [sgspi].[aud_parte_interesada] las altas ('I') y la versión resultante (after-image) de cada fila modificada ('U')
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
               THROW 50017, N'No se encontró una persona activa (usuario_administrativos/usuario_docentes.sys) para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_parte_interesada (
                       pai_codigo,
                       apa_nombre,
                       apa_origen,
                       apa_descripcion_rol,
                       apa_estado,
                       per_codigo,
                       apa_operacion,
                       apa_usuario_bd,
                       apa_fecha_cambio
                   )
                   SELECT i.pai_codigo,
                          i.pai_nombre,
                          i.pai_origen,
                          i.pai_descripcion_rol,
                          i.pai_estado,
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
               apa_estado,
               per_codigo,
               apa_operacion,
               apa_usuario_bd,
               apa_fecha_cambio
           )
           SELECT i.pai_codigo,
                  i.pai_nombre,
                  i.pai_origen,
                  i.pai_descripcion_rol,
                  i.pai_estado,
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
                                 i.pai_estado
                          EXCEPT
                          SELECT d.pai_nombre,
                                 d.pai_origen,
                                 d.pai_descripcion_rol,
                                 d.pai_estado);
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
-- [rpp] Bloquea el borrado físico y archiva en [sgspi].[aud_requisito_parte_interesada_proceso_institucional] las altas ('I') y la versión resultante (after-image) de cada fila modificada ('U')
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
           -- [AP-24] [B3] Serializa el agregado por raíz (rpi) en orden ascendente (sin UPDLOCK cruzado)
           DECLARE @lock_id AS INT = (SELECT MIN(rpi_codigo)
                                      FROM   (SELECT rpi_codigo
                                              FROM   inserted
                                              UNION
                                              SELECT rpi_codigo
                                              FROM   deleted) AS l), @lock_res AS NVARCHAR (60), @lock_rc AS INT;
           WHILE @lock_id IS NOT NULL
               BEGIN
                   SET @lock_res = CONCAT(N'sgspi:rpi:', @lock_id);
                   EXECUTE @lock_rc = sys.sp_getapplock @Resource = @lock_res, @LockMode = 'Exclusive', @LockOwner = 'Transaction', @LockTimeout = 10000;
                   IF @lock_rc < 0
                       THROW 50023, N'Tiempo de espera agotado al adquirir bloqueo del agregado [sgspi:rpi] en [sgspi].[requisito_parte_interesada_proceso_institucional].', 1;
                   SET @lock_id = (SELECT MIN(rpi_codigo)
                                   FROM   (SELECT rpi_codigo
                                           FROM   inserted
                                           UNION
                                           SELECT rpi_codigo
                                           FROM   deleted) AS l
                                   WHERE  l.rpi_codigo > @lock_id);
               END
           IF EXISTS (SELECT 1
                      FROM   (SELECT rpi_codigo
                              FROM   inserted
                              UNION
                              SELECT rpi_codigo
                              FROM   deleted) AS x
                             INNER JOIN
                             sgspi.requisito_parte_interesada AS p
                             ON p.rpi_codigo = x.rpi_codigo
                             INNER JOIN
                             sgspi.estado_flujo_catalogo AS efc
                             ON efc.efc_dominio = N'RPI'
                                AND efc.efc_identificador = p.rpi_fase_registro
                      WHERE  efc.efc_permite_edicion = 0
                             OR efc.efc_estado = 0)
               THROW 50011, N'Operación denegada: No se permite insertar ni modificar registros de [sgspi].[requisito_parte_interesada_proceso_institucional] cuando el padre no es editable.', 1;
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona activa (usuario_administrativos/usuario_docentes.sys) para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_requisito_parte_interesada_proceso_institucional (
                       rpi_codigo,
                       pri_codigo,
                       arp_fecha_registro,
                       arp_estado,
                       per_codigo,
                       arp_operacion,
                       arp_usuario_bd,
                       arp_fecha_cambio
                   )
                   SELECT i.rpi_codigo,
                          i.pri_codigo,
                          i.rpp_fecha_registro,
                          i.rpp_estado,
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
               arp_estado,
               per_codigo,
               arp_operacion,
               arp_usuario_bd,
               arp_fecha_cambio
           )
           SELECT i.rpi_codigo,
                  i.pri_codigo,
                  i.rpp_fecha_registro,
                  i.rpp_estado,
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
                                 i.rpp_estado
                          EXCEPT
                          SELECT d.rpp_fecha_registro,
                                 d.rpp_estado);
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
-- [tac] Bloquea el borrado físico y archiva en [sgspi].[aud_tipo_activo_catalogo] las altas ('I') y la versión resultante (after-image) de cada fila modificada ('U')
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
               THROW 50017, N'No se encontró una persona activa (usuario_administrativos/usuario_docentes.sys) para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_tipo_activo_catalogo (
                       tac_codigo,
                       atc_codigo_padre,
                       atc_nivel_taxonomia,
                       atc_nombre,
                       atc_ejemplos_ref,
                       atc_estado,
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
                          i.tac_estado,
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
               atc_estado,
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
                  i.tac_estado,
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
                                 i.tac_estado
                          EXCEPT
                          SELECT d.tac_codigo_padre,
                                 d.tac_nivel_taxonomia,
                                 d.tac_nombre,
                                 d.tac_ejemplos_ref,
                                 d.tac_estado);
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
-- [cet] Bloquea el borrado físico y archiva en [sgspi].[aud_causal_excepcion_transparencia] las altas ('I') y la versión resultante (after-image) de cada fila modificada ('U')
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
               THROW 50017, N'No se encontró una persona activa (usuario_administrativos/usuario_docentes.sys) para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_causal_excepcion_transparencia (
                       cet_codigo,
                       ace_nivel_reserva_aplicable,
                       ace_numeral_causal,
                       ace_descripcion_causal,
                       ace_norma_referencia,
                       ace_estado,
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
                          i.cet_estado,
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
               ace_estado,
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
                  i.cet_estado,
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
                                 i.cet_estado
                          EXCEPT
                          SELECT d.cet_nivel_reserva_aplicable,
                                 d.cet_numeral_causal,
                                 d.cet_descripcion_causal,
                                 d.cet_norma_referencia,
                                 d.cet_estado);
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
-- [aip] Bloquea el borrado físico y archiva en [sgspi].[aud_activo_informacion_proceso_institucional] las altas ('I') y la versión resultante (after-image) de cada fila modificada ('U')
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
           -- [AP-24] Serializa el agregado por raíz (aci) en orden ascendente para evitar deadlocks AB-BA
           DECLARE @lock_id AS INT = (SELECT MIN(aci_codigo)
                                      FROM   (SELECT aci_codigo
                                              FROM   inserted
                                              UNION
                                              SELECT aci_codigo
                                              FROM   deleted) AS l), @lock_res AS NVARCHAR (60), @lock_rc AS INT;
           WHILE @lock_id IS NOT NULL
               BEGIN
                   SET @lock_res = CONCAT(N'sgspi:aci:', @lock_id);
                   EXECUTE @lock_rc = sys.sp_getapplock @Resource = @lock_res, @LockMode = 'Exclusive', @LockOwner = 'Transaction', @LockTimeout = 10000;
                   IF @lock_rc < 0
                       THROW 50023, N'Tiempo de espera agotado al adquirir bloqueo del agregado [sgspi:aci] en [sgspi].[activo_informacion_proceso_institucional].', 1;
                   SET @lock_id = (SELECT MIN(aci_codigo)
                                   FROM   (SELECT aci_codigo
                                           FROM   inserted
                                           UNION
                                           SELECT aci_codigo
                                           FROM   deleted) AS l
                                   WHERE  l.aci_codigo > @lock_id);
               END
           IF EXISTS (SELECT 1
                      FROM   (SELECT aci_codigo
                              FROM   inserted
                              UNION
                              SELECT aci_codigo
                              FROM   deleted) AS x
                             INNER JOIN
                             sgspi.activo_informacion AS p
                             ON p.aci_codigo = x.aci_codigo
                             INNER JOIN
                             sgspi.estado_flujo_catalogo AS efc
                             ON efc.efc_dominio = N'ACI'
                                AND efc.efc_identificador = p.aci_fase_registro
                      WHERE  efc.efc_permite_edicion = 0
                             OR efc.efc_estado = 0)
               THROW 50011, N'Operación denegada: No se permite insertar ni modificar registros de [sgspi].[activo_informacion_proceso_institucional] cuando el padre no es editable.', 1;
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona activa (usuario_administrativos/usuario_docentes.sys) para ORIGINAL_LOGIN().', 1;
           -- [AP-02] D5: los roles líder y custodio asocian a sus procesos solo activos de sus UAA (la asociación nueva no da alcance; LEFT JOIN evita bypass por RLS)
           IF EXISTS (SELECT 1
                      FROM   (SELECT aci_codigo,
                                     pri_codigo
                              FROM   inserted
                              UNION
                              SELECT aci_codigo,
                                     pri_codigo
                              FROM   deleted) AS x
                             LEFT OUTER JOIN
                             sgspi.activo_informacion AS p
                             ON p.aci_codigo = x.aci_codigo
                             OUTER APPLY sgspi.ufn_proceso_en_alcance(x.pri_codigo, @per_actor) AS ap
                             OUTER APPLY sgspi.ufn_activo_en_alcance(NULL, p.uaa_codigo, @per_actor) AS aa
                      WHERE  ap.permitido IS NULL
                             OR aa.permitido IS NULL)
               THROW 50021, N'Fuera de alcance: el activo o el proceso no son de las UAA del usuario en [sgspi].[activo_informacion_proceso_institucional].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_activo_informacion_proceso_institucional (
                       aci_codigo,
                       pri_codigo,
                       aap_estado,
                       per_codigo,
                       aap_operacion,
                       aap_usuario_bd,
                       aap_fecha_cambio
                   )
                   SELECT i.aci_codigo,
                          i.pri_codigo,
                          i.aip_estado,
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
               aap_estado,
               per_codigo,
               aap_operacion,
               aap_usuario_bd,
               aap_fecha_cambio
           )
           SELECT i.aci_codigo,
                  i.pri_codigo,
                  i.aip_estado,
                  @per_actor,
                  'U',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   deleted AS d
                  INNER JOIN
                  inserted AS i
                  ON i.aci_codigo = d.aci_codigo
                     AND i.pri_codigo = d.pri_codigo
           WHERE  EXISTS (SELECT i.aip_estado
                          EXCEPT
                          SELECT d.aip_estado);
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
-- [ais] Bloquea el borrado físico y archiva en [sgspi].[aud_activo_informacion_sede] las altas ('I') y la versión resultante (after-image) de cada fila modificada ('U')
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
           -- [AP-24] Serializa el agregado por raíz (aci) en orden ascendente para evitar deadlocks AB-BA
           DECLARE @lock_id AS INT = (SELECT MIN(aci_codigo)
                                      FROM   (SELECT aci_codigo
                                              FROM   inserted
                                              UNION
                                              SELECT aci_codigo
                                              FROM   deleted) AS l), @lock_res AS NVARCHAR (60), @lock_rc AS INT;
           WHILE @lock_id IS NOT NULL
               BEGIN
                   SET @lock_res = CONCAT(N'sgspi:aci:', @lock_id);
                   EXECUTE @lock_rc = sys.sp_getapplock @Resource = @lock_res, @LockMode = 'Exclusive', @LockOwner = 'Transaction', @LockTimeout = 10000;
                   IF @lock_rc < 0
                       THROW 50023, N'Tiempo de espera agotado al adquirir bloqueo del agregado [sgspi:aci] en [sgspi].[activo_informacion_sede].', 1;
                   SET @lock_id = (SELECT MIN(aci_codigo)
                                   FROM   (SELECT aci_codigo
                                           FROM   inserted
                                           UNION
                                           SELECT aci_codigo
                                           FROM   deleted) AS l
                                   WHERE  l.aci_codigo > @lock_id);
               END
           IF EXISTS (SELECT 1
                      FROM   (SELECT aci_codigo
                              FROM   inserted
                              UNION
                              SELECT aci_codigo
                              FROM   deleted) AS x
                             INNER JOIN
                             sgspi.activo_informacion AS p
                             ON p.aci_codigo = x.aci_codigo
                             INNER JOIN
                             sgspi.estado_flujo_catalogo AS efc
                             ON efc.efc_dominio = N'ACI'
                                AND efc.efc_identificador = p.aci_fase_registro
                      WHERE  efc.efc_permite_edicion = 0
                             OR efc.efc_estado = 0)
               THROW 50011, N'Operación denegada: No se permite insertar ni modificar registros de [sgspi].[activo_informacion_sede] cuando el padre no es editable.', 1;
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona activa (usuario_administrativos/usuario_docentes.sys) para ORIGINAL_LOGIN().', 1;
           -- [AP-02] D5: los roles líder y custodio solo escriben activos de su alcance (ufn_activo_en_alcance; LEFT JOIN evita bypass por RLS)
           IF EXISTS (SELECT 1
                      FROM   (SELECT aci_codigo
                              FROM   inserted
                              UNION
                              SELECT aci_codigo
                              FROM   deleted) AS x
                             LEFT OUTER JOIN
                             sgspi.activo_informacion AS p
                             ON p.aci_codigo = x.aci_codigo
                             OUTER APPLY sgspi.ufn_activo_en_alcance(p.aci_codigo, p.uaa_codigo, @per_actor) AS a
                      WHERE  a.permitido IS NULL)
               THROW 50021, N'Fuera de alcance: el activo no es de las UAA ni de los procesos del usuario en [sgspi].[activo_informacion_sede].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_activo_informacion_sede (
                       aci_codigo,
                       sus_codigo,
                       aas_estado,
                       per_codigo,
                       aas_operacion,
                       aas_usuario_bd,
                       aas_fecha_cambio
                   )
                   SELECT i.aci_codigo,
                          i.sus_codigo,
                          i.ais_estado,
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
               aas_estado,
               per_codigo,
               aas_operacion,
               aas_usuario_bd,
               aas_fecha_cambio
           )
           SELECT i.aci_codigo,
                  i.sus_codigo,
                  i.ais_estado,
                  @per_actor,
                  'U',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   deleted AS d
                  INNER JOIN
                  inserted AS i
                  ON i.aci_codigo = d.aci_codigo
                     AND i.sus_codigo = d.sus_codigo
           WHERE  EXISTS (SELECT i.ais_estado
                          EXCEPT
                          SELECT d.ais_estado);
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
-- [air] Bloquea el borrado físico y archiva en [sgspi].[aud_activo_informacion_responsable] las altas ('I') y la versión resultante (after-image) de cada fila modificada ('U')
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
           -- [AP-24] Serializa el agregado por raíz (aci) en orden ascendente para evitar deadlocks AB-BA
           DECLARE @lock_id AS INT = (SELECT MIN(aci_codigo)
                                      FROM   (SELECT aci_codigo
                                              FROM   inserted
                                              UNION
                                              SELECT aci_codigo
                                              FROM   deleted) AS l), @lock_res AS NVARCHAR (60), @lock_rc AS INT;
           WHILE @lock_id IS NOT NULL
               BEGIN
                   SET @lock_res = CONCAT(N'sgspi:aci:', @lock_id);
                   EXECUTE @lock_rc = sys.sp_getapplock @Resource = @lock_res, @LockMode = 'Exclusive', @LockOwner = 'Transaction', @LockTimeout = 10000;
                   IF @lock_rc < 0
                       THROW 50023, N'Tiempo de espera agotado al adquirir bloqueo del agregado [sgspi:aci] en [sgspi].[activo_informacion_responsable].', 1;
                   SET @lock_id = (SELECT MIN(aci_codigo)
                                   FROM   (SELECT aci_codigo
                                           FROM   inserted
                                           UNION
                                           SELECT aci_codigo
                                           FROM   deleted) AS l
                                   WHERE  l.aci_codigo > @lock_id);
               END
           IF EXISTS (SELECT 1
                      FROM   (SELECT aci_codigo
                              FROM   inserted
                              UNION
                              SELECT aci_codigo
                              FROM   deleted) AS x
                             INNER JOIN
                             sgspi.activo_informacion AS p
                             ON p.aci_codigo = x.aci_codigo
                             INNER JOIN
                             sgspi.estado_flujo_catalogo AS efc
                             ON efc.efc_dominio = N'ACI'
                                AND efc.efc_identificador = p.aci_fase_registro
                      WHERE  efc.efc_permite_edicion = 0
                             OR efc.efc_estado = 0)
               THROW 50011, N'Operación denegada: No se permite insertar ni modificar registros de [sgspi].[activo_informacion_responsable] cuando el padre no es editable.', 1;
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona activa (usuario_administrativos/usuario_docentes.sys) para ORIGINAL_LOGIN().', 1;
           -- [AP-02] D5: los roles líder y custodio solo escriben activos de su alcance (ufn_activo_en_alcance; LEFT JOIN evita bypass por RLS)
           IF EXISTS (SELECT 1
                      FROM   (SELECT aci_codigo
                              FROM   inserted
                              UNION
                              SELECT aci_codigo
                              FROM   deleted) AS x
                             LEFT OUTER JOIN
                             sgspi.activo_informacion AS p
                             ON p.aci_codigo = x.aci_codigo
                             OUTER APPLY sgspi.ufn_activo_en_alcance(p.aci_codigo, p.uaa_codigo, @per_actor) AS a
                      WHERE  a.permitido IS NULL)
               THROW 50021, N'Fuera de alcance: el activo no es de las UAA ni de los procesos del usuario en [sgspi].[activo_informacion_responsable].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_activo_informacion_responsable (
                       aci_codigo,
                       car_codigo,
                       uaa_codigo,
                       air_tipo_responsabilidad,
                       aar_estado,
                       per_codigo,
                       aar_operacion,
                       aar_usuario_bd,
                       aar_fecha_cambio
                   )
                   SELECT i.aci_codigo,
                          i.car_codigo,
                          i.uaa_codigo,
                          i.air_tipo_responsabilidad,
                          i.air_estado,
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
               aar_estado,
               per_codigo,
               aar_operacion,
               aar_usuario_bd,
               aar_fecha_cambio
           )
           SELECT i.aci_codigo,
                  i.car_codigo,
                  i.uaa_codigo,
                  i.air_tipo_responsabilidad,
                  i.air_estado,
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
           WHERE  EXISTS (SELECT i.air_estado
                          EXCEPT
                          SELECT d.air_estado);
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
-- [sif] Bloquea el borrado físico y archiva en [sgspi].[aud_sistema_informacion_ficha] las altas ('I') y la versión resultante (after-image) de cada fila modificada ('U')
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
           -- [AP-24] Serializa el agregado por raíz (aci) en orden ascendente para evitar deadlocks AB-BA
           DECLARE @lock_id AS INT = (SELECT MIN(aci_codigo)
                                      FROM   (SELECT aci_codigo
                                              FROM   inserted
                                              WHERE  aci_codigo IS NOT NULL
                                              UNION
                                              SELECT aci_codigo
                                              FROM   deleted
                                              WHERE  aci_codigo IS NOT NULL) AS l), @lock_res AS NVARCHAR (60), @lock_rc AS INT;
           WHILE @lock_id IS NOT NULL
               BEGIN
                   SET @lock_res = CONCAT(N'sgspi:aci:', @lock_id);
                   EXECUTE @lock_rc = sys.sp_getapplock @Resource = @lock_res, @LockMode = 'Exclusive', @LockOwner = 'Transaction', @LockTimeout = 10000;
                   IF @lock_rc < 0
                       THROW 50023, N'Tiempo de espera agotado al adquirir bloqueo del agregado [sgspi:aci] en [sgspi].[sistema_informacion_ficha].', 1;
                   SET @lock_id = (SELECT MIN(aci_codigo)
                                   FROM   (SELECT aci_codigo
                                           FROM   inserted
                                           WHERE  aci_codigo IS NOT NULL
                                           UNION
                                           SELECT aci_codigo
                                           FROM   deleted
                                           WHERE  aci_codigo IS NOT NULL) AS l
                                   WHERE  l.aci_codigo > @lock_id);
               END
           -- Bloquea INSERT/UPDATE cuando el activo de información asociado (anterior o nuevo) no es editable
           IF EXISTS (SELECT 1
                      FROM   (SELECT aci_codigo
                              FROM   inserted
                              WHERE  aci_codigo IS NOT NULL
                              UNION
                              SELECT aci_codigo
                              FROM   deleted
                              WHERE  aci_codigo IS NOT NULL) AS x
                             INNER JOIN
                             sgspi.activo_informacion AS aci
                             ON aci.aci_codigo = x.aci_codigo
                             INNER JOIN
                             sgspi.estado_flujo_catalogo AS efc
                             ON efc.efc_dominio = N'ACI'
                                AND efc.efc_identificador = aci.aci_fase_registro
                      WHERE  efc.efc_permite_edicion = 0
                             OR efc.efc_estado = 0)
               THROW 50011, N'Operación denegada: No se permite insertar ni modificar la ficha de un sistema cuyo activo de información no es editable en [sgspi].[sistema_informacion_ficha].', 1;
           -- [B4] Exclusividad de subtipos: un activo documental activo ([ado]) no puede asociarse a una ficha de sistema activa ([sif])
           IF EXISTS (SELECT 1
                      FROM   inserted AS i
                      WHERE  i.sif_estado = 1
                             AND i.aci_codigo IS NOT NULL
                             AND EXISTS (SELECT 1
                                         FROM   sgspi.activo_documental AS ado
                                         WHERE  ado.ado_codigo = i.aci_codigo
                                                AND ado.ado_estado = 1))
               THROW 50020, N'Exclusividad de subtipos: un activo documental activo ([ado]) no puede asociarse a una ficha de sistema de información ([sif]).', 1;
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona activa (usuario_administrativos/usuario_docentes.sys) para ORIGINAL_LOGIN().', 1;
           -- [AP-02] D5: líder y custodio solo escriben fichas asociadas a activos de su alcance (aci_codigo NULL queda solo para roles transversales)
           IF EXISTS (SELECT 1
                      FROM   (SELECT aci_codigo
                              FROM   inserted
                              UNION
                              SELECT aci_codigo
                              FROM   deleted) AS x
                             LEFT OUTER JOIN
                             sgspi.activo_informacion AS aci
                             ON aci.aci_codigo = x.aci_codigo
                             OUTER APPLY sgspi.ufn_activo_en_alcance(aci.aci_codigo, aci.uaa_codigo, @per_actor) AS a
                      WHERE  a.permitido IS NULL)
               THROW 50021, N'Fuera de alcance: la ficha de sistema no está asociada a un activo de las UAA ni de los procesos del usuario en [sgspi].[sistema_informacion_ficha].', 1;
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
                       asf_estado,
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
                          i.sif_estado,
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
               asf_estado,
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
                  i.sif_estado,
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
                                 i.sif_estado
                          EXCEPT
                          SELECT d.aci_codigo,
                                 d.sif_nombre_sistema,
                                 d.sif_modalidad_desarrollo,
                                 d.sif_fabricante_proveedor,
                                 d.sif_descripcion_general,
                                 d.sif_estado);
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
-- [msi] Bloquea el borrado físico y archiva en [sgspi].[aud_modulo_sistema_informacion] las altas ('I') y la versión resultante (after-image) de cada fila modificada ('U')
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
           -- [AP-24] Serializa el agregado por raíz (aci) en orden ascendente para evitar deadlocks AB-BA
           DECLARE @raices_aci TABLE (
               aci_codigo INT PRIMARY KEY);
           INSERT INTO @raices_aci (
               aci_codigo
           )
           SELECT DISTINCT sif.aci_codigo
           FROM   (SELECT sif_codigo
                   FROM   inserted
                   UNION
                   SELECT sif_codigo
                   FROM   deleted) AS x
                  INNER JOIN
                  sgspi.sistema_informacion_ficha AS sif
                  ON sif.sif_codigo = x.sif_codigo
           WHERE  sif.aci_codigo IS NOT NULL;
           DECLARE @lock_id AS INT = (SELECT MIN(aci_codigo)
                                      FROM   @raices_aci), @lock_res AS NVARCHAR (60), @lock_rc AS INT;
           WHILE @lock_id IS NOT NULL
               BEGIN
                   SET @lock_res = CONCAT(N'sgspi:aci:', @lock_id);
                   EXECUTE @lock_rc = sys.sp_getapplock @Resource = @lock_res, @LockMode = 'Exclusive', @LockOwner = 'Transaction', @LockTimeout = 10000;
                   IF @lock_rc < 0
                       THROW 50023, N'Tiempo de espera agotado al adquirir bloqueo del agregado [sgspi:aci] en [sgspi].[modulo_sistema_informacion].', 1;
                   SET @lock_id = (SELECT MIN(aci_codigo)
                                   FROM   @raices_aci
                                   WHERE  aci_codigo > @lock_id);
               END
           -- Bloquea INSERT/UPDATE cuando el activo de información del sistema padre no es editable
           IF EXISTS (SELECT 1
                      FROM   (SELECT sif_codigo
                              FROM   inserted
                              UNION
                              SELECT sif_codigo
                              FROM   deleted) AS x
                             INNER JOIN
                             sgspi.sistema_informacion_ficha AS sif
                             ON sif.sif_codigo = x.sif_codigo
                             INNER JOIN
                             sgspi.activo_informacion AS aci
                             ON aci.aci_codigo = sif.aci_codigo
                             INNER JOIN
                             sgspi.estado_flujo_catalogo AS efc
                             ON efc.efc_dominio = N'ACI'
                                AND efc.efc_identificador = aci.aci_fase_registro
                      WHERE  efc.efc_permite_edicion = 0
                             OR efc.efc_estado = 0)
               THROW 50011, N'Operación denegada: No se permite insertar ni modificar módulos de un sistema cuyo activo de información no es editable en [sgspi].[modulo_sistema_informacion].', 1;
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona activa (usuario_administrativos/usuario_docentes.sys) para ORIGINAL_LOGIN().', 1;
           -- [AP-02] D5: líder y custodio solo escriben módulos de sistemas asociados a activos de su alcance
           IF EXISTS (SELECT 1
                      FROM   (SELECT sif_codigo
                              FROM   inserted
                              UNION
                              SELECT sif_codigo
                              FROM   deleted) AS x
                             LEFT OUTER JOIN
                             sgspi.sistema_informacion_ficha AS sif
                             ON sif.sif_codigo = x.sif_codigo
                             LEFT OUTER JOIN
                             sgspi.activo_informacion AS aci
                             ON aci.aci_codigo = sif.aci_codigo
                             OUTER APPLY sgspi.ufn_activo_en_alcance(aci.aci_codigo, aci.uaa_codigo, @per_actor) AS a
                      WHERE  a.permitido IS NULL)
               THROW 50021, N'Fuera de alcance: el sistema del módulo no está asociado a un activo de las UAA ni de los procesos del usuario en [sgspi].[modulo_sistema_informacion].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_modulo_sistema_informacion (
                       msi_codigo,
                       sif_codigo,
                       ami_nombre_modulo,
                       ami_usuarios_objetivo,
                       ami_estado,
                       per_codigo,
                       ami_operacion,
                       ami_usuario_bd,
                       ami_fecha_cambio
                   )
                   SELECT i.msi_codigo,
                          i.sif_codigo,
                          i.msi_nombre_modulo,
                          i.msi_usuarios_objetivo,
                          i.msi_estado,
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
               ami_estado,
               per_codigo,
               ami_operacion,
               ami_usuario_bd,
               ami_fecha_cambio
           )
           SELECT i.msi_codigo,
                  i.sif_codigo,
                  i.msi_nombre_modulo,
                  i.msi_usuarios_objetivo,
                  i.msi_estado,
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
                                 i.msi_estado
                          EXCEPT
                          SELECT d.sif_codigo,
                                 d.msi_nombre_modulo,
                                 d.msi_usuarios_objetivo,
                                 d.msi_estado);
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
-- [sdo] Bloquea el borrado físico y archiva en [sgspi].[aud_serie_documental_catalogo] las altas ('I') y la versión resultante (after-image) de cada fila modificada ('U')
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
               THROW 50017, N'No se encontró una persona activa (usuario_administrativos/usuario_docentes.sys) para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_serie_documental_catalogo (
                       sdo_codigo,
                       aso_numero_ccd,
                       aso_nombre_serie,
                       aso_estado,
                       per_codigo,
                       aso_operacion,
                       aso_usuario_bd,
                       aso_fecha_cambio
                   )
                   SELECT i.sdo_codigo,
                          i.sdo_numero_ccd,
                          i.sdo_nombre_serie,
                          i.sdo_estado,
                          @per_actor,
                          'I',
                          ORIGINAL_LOGIN(),
                          SYSDATETIMEOFFSET()
                   FROM   inserted AS i;
                   RETURN;
               END
           -- [B4] Protección anti-huérfanos en borrado lógico: no desactivar [sdo] si tiene subseries o activos documentales activos
           IF EXISTS (SELECT 1
                      FROM   inserted AS i
                             INNER JOIN
                             deleted AS d
                             ON d.sdo_codigo = i.sdo_codigo
                      WHERE  d.sdo_estado = 1
                             AND i.sdo_estado = 0
                             AND (EXISTS (SELECT 1
                                          FROM   sgspi.subserie_documental_catalogo AS sbd
                                          WHERE  sbd.sdo_codigo = i.sdo_codigo
                                                 AND sbd.sbd_estado = 1)
                                  OR EXISTS (SELECT 1
                                             FROM   sgspi.activo_documental AS ado
                                             WHERE  ado.sdo_codigo = i.sdo_codigo
                                                    AND ado.ado_estado = 1)))
               THROW 50020, N'Baja lógica denegada: existen subseries o activos documentales activos asociados a [sgspi].[serie_documental_catalogo].', 1;
           INSERT INTO sgspi.aud_serie_documental_catalogo (
               sdo_codigo,
               aso_numero_ccd,
               aso_nombre_serie,
               aso_estado,
               per_codigo,
               aso_operacion,
               aso_usuario_bd,
               aso_fecha_cambio
           )
           SELECT i.sdo_codigo,
                  i.sdo_numero_ccd,
                  i.sdo_nombre_serie,
                  i.sdo_estado,
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
                                 i.sdo_estado
                          EXCEPT
                          SELECT d.sdo_numero_ccd,
                                 d.sdo_nombre_serie,
                                 d.sdo_estado);
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
-- [sbd] Bloquea el borrado físico y archiva en [sgspi].[aud_subserie_documental_catalogo] las altas ('I') y la versión resultante (after-image) de cada fila modificada ('U')
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
               THROW 50017, N'No se encontró una persona activa (usuario_administrativos/usuario_docentes.sys) para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_subserie_documental_catalogo (
                       sbd_codigo,
                       sdo_codigo,
                       asd_numero_ccd,
                       asd_nombre_subserie,
                       asd_estado,
                       per_codigo,
                       asd_operacion,
                       asd_usuario_bd,
                       asd_fecha_cambio
                   )
                   SELECT i.sbd_codigo,
                          i.sdo_codigo,
                          i.sbd_numero_ccd,
                          i.sbd_nombre_subserie,
                          i.sbd_estado,
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
               asd_estado,
               per_codigo,
               asd_operacion,
               asd_usuario_bd,
               asd_fecha_cambio
           )
           SELECT i.sbd_codigo,
                  i.sdo_codigo,
                  i.sbd_numero_ccd,
                  i.sbd_nombre_subserie,
                  i.sbd_estado,
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
                                 i.sbd_estado
                          EXCEPT
                          SELECT d.sdo_codigo,
                                 d.sbd_numero_ccd,
                                 d.sbd_nombre_subserie,
                                 d.sbd_estado);
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
-- [upc] Bloquea el borrado físico y archiva en [sgspi].[aud_unidad_productora_cuadro_clasificacion_documental] las altas ('I') y la versión resultante (after-image) de cada fila modificada ('U')
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
               THROW 50017, N'No se encontró una persona activa (usuario_administrativos/usuario_docentes.sys) para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_unidad_productora_cuadro_clasificacion_documental (
                       upc_codigo,
                       auc_nodo_jerarquico,
                       auc_codigo_archivistico,
                       uaa_codigo,
                       auc_nombre_unidad,
                       auc_estado,
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
                          i.upc_estado,
                          @per_actor,
                          'I',
                          ORIGINAL_LOGIN(),
                          SYSDATETIMEOFFSET()
                   FROM   inserted AS i;
                   RETURN;
               END
           -- [B4] Protección anti-huérfanos en borrado lógico: no desactivar [upc] si tiene nodos descendientes activos o asociaciones [adu] activas
           IF EXISTS (SELECT 1
                      FROM   inserted AS i
                             INNER JOIN
                             deleted AS d
                             ON d.upc_codigo = i.upc_codigo
                      WHERE  d.upc_estado = 1
                             AND i.upc_estado = 0
                             AND (EXISTS (SELECT 1
                                          FROM   sgspi.unidad_productora_cuadro_clasificacion_documental AS hijo
                                          WHERE  hijo.upc_nodo_padre = d.upc_nodo_jerarquico
                                                 AND hijo.upc_estado = 1)
                                  OR EXISTS (SELECT 1
                                             FROM   sgspi.activo_documental_unidad_productora AS adu
                                             WHERE  adu.upc_codigo = i.upc_codigo
                                                    AND adu.adu_estado = 1)))
               THROW 50020, N'Baja lógica denegada: existen unidades productoras hijas o activos documentales activos asociados a [sgspi].[unidad_productora_cuadro_clasificacion_documental].', 1;
           INSERT INTO sgspi.aud_unidad_productora_cuadro_clasificacion_documental (
               upc_codigo,
               auc_nodo_jerarquico,
               auc_codigo_archivistico,
               uaa_codigo,
               auc_nombre_unidad,
               auc_estado,
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
                  i.upc_estado,
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
                                 i.upc_estado
                          EXCEPT
                          SELECT d.upc_nodo_jerarquico,
                                 d.upc_codigo_archivistico,
                                 d.uaa_codigo,
                                 d.upc_nombre_unidad,
                                 d.upc_estado);
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
-- [pdc] Bloquea el borrado físico y archiva en [sgspi].[aud_periodicidad_catalogo] las altas ('I') y la versión resultante (after-image) de cada fila modificada ('U')
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
               THROW 50017, N'No se encontró una persona activa (usuario_administrativos/usuario_docentes.sys) para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_periodicidad_catalogo (
                       pdc_codigo,
                       apc_nombre,
                       apc_orden,
                       apc_estado,
                       per_codigo,
                       apc_operacion,
                       apc_usuario_bd,
                       apc_fecha_cambio
                   )
                   SELECT i.pdc_codigo,
                          i.pdc_nombre,
                          i.pdc_orden,
                          i.pdc_estado,
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
               apc_estado,
               per_codigo,
               apc_operacion,
               apc_usuario_bd,
               apc_fecha_cambio
           )
           SELECT i.pdc_codigo,
                  i.pdc_nombre,
                  i.pdc_orden,
                  i.pdc_estado,
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
                                 i.pdc_estado
                          EXCEPT
                          SELECT d.pdc_nombre,
                                 d.pdc_orden,
                                 d.pdc_estado);
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
-- [epc] Bloquea el borrado físico y archiva en [sgspi].[aud_estado_publicacion_catalogo] las altas ('I') y la versión resultante (after-image) de cada fila modificada ('U')
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
               THROW 50017, N'No se encontró una persona activa (usuario_administrativos/usuario_docentes.sys) para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_estado_publicacion_catalogo (
                       epc_codigo,
                       aep_nombre,
                       aep_descripcion,
                       aep_estado,
                       per_codigo,
                       aep_operacion,
                       aep_usuario_bd,
                       aep_fecha_cambio
                   )
                   SELECT i.epc_codigo,
                          i.epc_nombre,
                          i.epc_descripcion,
                          i.epc_estado,
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
               aep_estado,
               per_codigo,
               aep_operacion,
               aep_usuario_bd,
               aep_fecha_cambio
           )
           SELECT i.epc_codigo,
                  i.epc_nombre,
                  i.epc_descripcion,
                  i.epc_estado,
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
                                 i.epc_estado
                          EXCEPT
                          SELECT d.epc_nombre,
                                 d.epc_descripcion,
                                 d.epc_estado);
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
-- [src] Bloquea el borrado físico y archiva en [sgspi].[aud_soporte_registro_catalogo] las altas ('I') y la versión resultante (after-image) de cada fila modificada ('U')
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
               THROW 50017, N'No se encontró una persona activa (usuario_administrativos/usuario_docentes.sys) para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_soporte_registro_catalogo (
                       src_codigo,
                       asc_nombre,
                       asc_estado,
                       per_codigo,
                       asc_operacion,
                       asc_usuario_bd,
                       asc_fecha_cambio
                   )
                   SELECT i.src_codigo,
                          i.src_nombre,
                          i.src_estado,
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
               asc_estado,
               per_codigo,
               asc_operacion,
               asc_usuario_bd,
               asc_fecha_cambio
           )
           SELECT i.src_codigo,
                  i.src_nombre,
                  i.src_estado,
                  @per_actor,
                  'U',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   deleted AS d
                  INNER JOIN
                  inserted AS i
                  ON i.src_codigo = d.src_codigo
           WHERE  EXISTS (SELECT i.src_nombre,
                                 i.src_estado
                          EXCEPT
                          SELECT d.src_nombre,
                                 d.src_estado);
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
-- [mcc] Bloquea el borrado físico y archiva en [sgspi].[aud_medio_conservacion_catalogo] las altas ('I') y la versión resultante (after-image) de cada fila modificada ('U')
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
               THROW 50017, N'No se encontró una persona activa (usuario_administrativos/usuario_docentes.sys) para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_medio_conservacion_catalogo (
                       mcc_codigo,
                       amc_nombre,
                       amc_estado,
                       per_codigo,
                       amc_operacion,
                       amc_usuario_bd,
                       amc_fecha_cambio
                   )
                   SELECT i.mcc_codigo,
                          i.mcc_nombre,
                          i.mcc_estado,
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
               amc_estado,
               per_codigo,
               amc_operacion,
               amc_usuario_bd,
               amc_fecha_cambio
           )
           SELECT i.mcc_codigo,
                  i.mcc_nombre,
                  i.mcc_estado,
                  @per_actor,
                  'U',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   deleted AS d
                  INNER JOIN
                  inserted AS i
                  ON i.mcc_codigo = d.mcc_codigo
           WHERE  EXISTS (SELECT i.mcc_nombre,
                                 i.mcc_estado
                          EXCEPT
                          SELECT d.mcc_nombre,
                                 d.mcc_estado);
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
-- [idi] Bloquea el borrado físico y archiva en [sgspi].[aud_idioma_catalogo] las altas ('I') y la versión resultante (after-image) de cada fila modificada ('U')
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
               THROW 50017, N'No se encontró una persona activa (usuario_administrativos/usuario_docentes.sys) para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_idioma_catalogo (
                       idi_codigo,
                       aii_codigo_iso,
                       aii_nombre,
                       aii_estado,
                       per_codigo,
                       aii_operacion,
                       aii_usuario_bd,
                       aii_fecha_cambio
                   )
                   SELECT i.idi_codigo,
                          i.idi_codigo_iso,
                          i.idi_nombre,
                          i.idi_estado,
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
               aii_estado,
               per_codigo,
               aii_operacion,
               aii_usuario_bd,
               aii_fecha_cambio
           )
           SELECT i.idi_codigo,
                  i.idi_codigo_iso,
                  i.idi_nombre,
                  i.idi_estado,
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
                                 i.idi_estado
                          EXCEPT
                          SELECT d.idi_codigo_iso,
                                 d.idi_nombre,
                                 d.idi_estado);
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
-- [fac] Bloquea el borrado físico y archiva en [sgspi].[aud_formato_archivo_catalogo] las altas ('I') y la versión resultante (after-image) de cada fila modificada ('U')
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
               THROW 50017, N'No se encontró una persona activa (usuario_administrativos/usuario_docentes.sys) para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_formato_archivo_catalogo (
                       fac_codigo,
                       afa_nombre,
                       afa_estado,
                       per_codigo,
                       afa_operacion,
                       afa_usuario_bd,
                       afa_fecha_cambio
                   )
                   SELECT i.fac_codigo,
                          i.fac_nombre,
                          i.fac_estado,
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
               afa_estado,
               per_codigo,
               afa_operacion,
               afa_usuario_bd,
               afa_fecha_cambio
           )
           SELECT i.fac_codigo,
                  i.fac_nombre,
                  i.fac_estado,
                  @per_actor,
                  'U',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   deleted AS d
                  INNER JOIN
                  inserted AS i
                  ON i.fac_codigo = d.fac_codigo
           WHERE  EXISTS (SELECT i.fac_nombre,
                                 i.fac_estado
                          EXCEPT
                          SELECT d.fac_nombre,
                                 d.fac_estado);
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
-- [ads] Bloquea el borrado físico y archiva en [sgspi].[aud_activo_documental_soporte_registro] las altas ('I') y la versión resultante (after-image) de cada fila modificada ('U')
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
           -- [AP-24] Serializa el agregado por raíz (aci) en orden ascendente para evitar deadlocks AB-BA
           DECLARE @lock_id AS INT = (SELECT MIN(ado_codigo)
                                      FROM   (SELECT ado_codigo
                                              FROM   inserted
                                              UNION
                                              SELECT ado_codigo
                                              FROM   deleted) AS l), @lock_res AS NVARCHAR (60), @lock_rc AS INT;
           WHILE @lock_id IS NOT NULL
               BEGIN
                   SET @lock_res = CONCAT(N'sgspi:aci:', @lock_id);
                   EXECUTE @lock_rc = sys.sp_getapplock @Resource = @lock_res, @LockMode = 'Exclusive', @LockOwner = 'Transaction', @LockTimeout = 10000;
                   IF @lock_rc < 0
                       THROW 50023, N'Tiempo de espera agotado al adquirir bloqueo del agregado [sgspi:aci] en [sgspi].[activo_documental_soporte_registro].', 1;
                   SET @lock_id = (SELECT MIN(ado_codigo)
                                   FROM   (SELECT ado_codigo
                                           FROM   inserted
                                           UNION
                                           SELECT ado_codigo
                                           FROM   deleted) AS l
                                   WHERE  l.ado_codigo > @lock_id);
               END
           IF EXISTS (SELECT 1
                      FROM   (SELECT ado_codigo
                              FROM   inserted
                              UNION
                              SELECT ado_codigo
                              FROM   deleted) AS x
                             INNER JOIN
                             sgspi.activo_informacion AS p
                             ON p.aci_codigo = x.ado_codigo
                             INNER JOIN
                             sgspi.estado_flujo_catalogo AS efc
                             ON efc.efc_dominio = N'ACI'
                                AND efc.efc_identificador = p.aci_fase_registro
                      WHERE  efc.efc_permite_edicion = 0
                             OR efc.efc_estado = 0)
               THROW 50011, N'Operación denegada: No se permite insertar ni modificar registros de [sgspi].[activo_documental_soporte_registro] cuando el padre no es editable.', 1;
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona activa (usuario_administrativos/usuario_docentes.sys) para ORIGINAL_LOGIN().', 1;
           -- [AP-02] D5: los roles líder y custodio solo escriben activos de su alcance (ufn_activo_en_alcance; LEFT JOIN evita bypass por RLS)
           IF EXISTS (SELECT 1
                      FROM   (SELECT ado_codigo
                              FROM   inserted
                              UNION
                              SELECT ado_codigo
                              FROM   deleted) AS x
                             LEFT OUTER JOIN
                             sgspi.activo_informacion AS p
                             ON p.aci_codigo = x.ado_codigo
                             OUTER APPLY sgspi.ufn_activo_en_alcance(p.aci_codigo, p.uaa_codigo, @per_actor) AS a
                      WHERE  a.permitido IS NULL)
               THROW 50021, N'Fuera de alcance: el activo no es de las UAA ni de los procesos del usuario en [sgspi].[activo_documental_soporte_registro].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_activo_documental_soporte_registro (
                       ado_codigo,
                       src_codigo,
                       aad_estado,
                       per_codigo,
                       aad_operacion,
                       aad_usuario_bd,
                       aad_fecha_cambio
                   )
                   SELECT i.ado_codigo,
                          i.src_codigo,
                          i.ads_estado,
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
               aad_estado,
               per_codigo,
               aad_operacion,
               aad_usuario_bd,
               aad_fecha_cambio
           )
           SELECT i.ado_codigo,
                  i.src_codigo,
                  i.ads_estado,
                  @per_actor,
                  'U',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   deleted AS d
                  INNER JOIN
                  inserted AS i
                  ON i.ado_codigo = d.ado_codigo
                     AND i.src_codigo = d.src_codigo
           WHERE  EXISTS (SELECT i.ads_estado
                          EXCEPT
                          SELECT d.ads_estado);
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
-- [adm] Bloquea el borrado físico y archiva en [sgspi].[aud_activo_documental_medio_conservacion] las altas ('I') y la versión resultante (after-image) de cada fila modificada ('U')
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
           -- [AP-24] Serializa el agregado por raíz (aci) en orden ascendente para evitar deadlocks AB-BA
           DECLARE @lock_id AS INT = (SELECT MIN(ado_codigo)
                                      FROM   (SELECT ado_codigo
                                              FROM   inserted
                                              UNION
                                              SELECT ado_codigo
                                              FROM   deleted) AS l), @lock_res AS NVARCHAR (60), @lock_rc AS INT;
           WHILE @lock_id IS NOT NULL
               BEGIN
                   SET @lock_res = CONCAT(N'sgspi:aci:', @lock_id);
                   EXECUTE @lock_rc = sys.sp_getapplock @Resource = @lock_res, @LockMode = 'Exclusive', @LockOwner = 'Transaction', @LockTimeout = 10000;
                   IF @lock_rc < 0
                       THROW 50023, N'Tiempo de espera agotado al adquirir bloqueo del agregado [sgspi:aci] en [sgspi].[activo_documental_medio_conservacion].', 1;
                   SET @lock_id = (SELECT MIN(ado_codigo)
                                   FROM   (SELECT ado_codigo
                                           FROM   inserted
                                           UNION
                                           SELECT ado_codigo
                                           FROM   deleted) AS l
                                   WHERE  l.ado_codigo > @lock_id);
               END
           IF EXISTS (SELECT 1
                      FROM   (SELECT ado_codigo
                              FROM   inserted
                              UNION
                              SELECT ado_codigo
                              FROM   deleted) AS x
                             INNER JOIN
                             sgspi.activo_informacion AS p
                             ON p.aci_codigo = x.ado_codigo
                             INNER JOIN
                             sgspi.estado_flujo_catalogo AS efc
                             ON efc.efc_dominio = N'ACI'
                                AND efc.efc_identificador = p.aci_fase_registro
                      WHERE  efc.efc_permite_edicion = 0
                             OR efc.efc_estado = 0)
               THROW 50011, N'Operación denegada: No se permite insertar ni modificar registros de [sgspi].[activo_documental_medio_conservacion] cuando el padre no es editable.', 1;
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona activa (usuario_administrativos/usuario_docentes.sys) para ORIGINAL_LOGIN().', 1;
           -- [AP-02] D5: los roles líder y custodio solo escriben activos de su alcance (ufn_activo_en_alcance; LEFT JOIN evita bypass por RLS)
           IF EXISTS (SELECT 1
                      FROM   (SELECT ado_codigo
                              FROM   inserted
                              UNION
                              SELECT ado_codigo
                              FROM   deleted) AS x
                             LEFT OUTER JOIN
                             sgspi.activo_informacion AS p
                             ON p.aci_codigo = x.ado_codigo
                             OUTER APPLY sgspi.ufn_activo_en_alcance(p.aci_codigo, p.uaa_codigo, @per_actor) AS a
                      WHERE  a.permitido IS NULL)
               THROW 50021, N'Fuera de alcance: el activo no es de las UAA ni de los procesos del usuario en [sgspi].[activo_documental_medio_conservacion].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_activo_documental_medio_conservacion (
                       ado_codigo,
                       mcc_codigo,
                       aam_estado,
                       per_codigo,
                       aam_operacion,
                       aam_usuario_bd,
                       aam_fecha_cambio
                   )
                   SELECT i.ado_codigo,
                          i.mcc_codigo,
                          i.adm_estado,
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
               aam_estado,
               per_codigo,
               aam_operacion,
               aam_usuario_bd,
               aam_fecha_cambio
           )
           SELECT i.ado_codigo,
                  i.mcc_codigo,
                  i.adm_estado,
                  @per_actor,
                  'U',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   deleted AS d
                  INNER JOIN
                  inserted AS i
                  ON i.ado_codigo = d.ado_codigo
                     AND i.mcc_codigo = d.mcc_codigo
           WHERE  EXISTS (SELECT i.adm_estado
                          EXCEPT
                          SELECT d.adm_estado);
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
-- [adi] Bloquea el borrado físico y archiva en [sgspi].[aud_activo_documental_idioma] las altas ('I') y la versión resultante (after-image) de cada fila modificada ('U')
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
           -- [AP-24] Serializa el agregado por raíz (aci) en orden ascendente para evitar deadlocks AB-BA
           DECLARE @lock_id AS INT = (SELECT MIN(ado_codigo)
                                      FROM   (SELECT ado_codigo
                                              FROM   inserted
                                              UNION
                                              SELECT ado_codigo
                                              FROM   deleted) AS l), @lock_res AS NVARCHAR (60), @lock_rc AS INT;
           WHILE @lock_id IS NOT NULL
               BEGIN
                   SET @lock_res = CONCAT(N'sgspi:aci:', @lock_id);
                   EXECUTE @lock_rc = sys.sp_getapplock @Resource = @lock_res, @LockMode = 'Exclusive', @LockOwner = 'Transaction', @LockTimeout = 10000;
                   IF @lock_rc < 0
                       THROW 50023, N'Tiempo de espera agotado al adquirir bloqueo del agregado [sgspi:aci] en [sgspi].[activo_documental_idioma].', 1;
                   SET @lock_id = (SELECT MIN(ado_codigo)
                                   FROM   (SELECT ado_codigo
                                           FROM   inserted
                                           UNION
                                           SELECT ado_codigo
                                           FROM   deleted) AS l
                                   WHERE  l.ado_codigo > @lock_id);
               END
           IF EXISTS (SELECT 1
                      FROM   (SELECT ado_codigo
                              FROM   inserted
                              UNION
                              SELECT ado_codigo
                              FROM   deleted) AS x
                             INNER JOIN
                             sgspi.activo_informacion AS p
                             ON p.aci_codigo = x.ado_codigo
                             INNER JOIN
                             sgspi.estado_flujo_catalogo AS efc
                             ON efc.efc_dominio = N'ACI'
                                AND efc.efc_identificador = p.aci_fase_registro
                      WHERE  efc.efc_permite_edicion = 0
                             OR efc.efc_estado = 0)
               THROW 50011, N'Operación denegada: No se permite insertar ni modificar registros de [sgspi].[activo_documental_idioma] cuando el padre no es editable.', 1;
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona activa (usuario_administrativos/usuario_docentes.sys) para ORIGINAL_LOGIN().', 1;
           -- [AP-02] D5: los roles líder y custodio solo escriben activos de su alcance (ufn_activo_en_alcance; LEFT JOIN evita bypass por RLS)
           IF EXISTS (SELECT 1
                      FROM   (SELECT ado_codigo
                              FROM   inserted
                              UNION
                              SELECT ado_codigo
                              FROM   deleted) AS x
                             LEFT OUTER JOIN
                             sgspi.activo_informacion AS p
                             ON p.aci_codigo = x.ado_codigo
                             OUTER APPLY sgspi.ufn_activo_en_alcance(p.aci_codigo, p.uaa_codigo, @per_actor) AS a
                      WHERE  a.permitido IS NULL)
               THROW 50021, N'Fuera de alcance: el activo no es de las UAA ni de los procesos del usuario en [sgspi].[activo_documental_idioma].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_activo_documental_idioma (
                       ado_codigo,
                       idi_codigo,
                       aid_estado,
                       per_codigo,
                       aid_operacion,
                       aid_usuario_bd,
                       aid_fecha_cambio
                   )
                   SELECT i.ado_codigo,
                          i.idi_codigo,
                          i.adi_estado,
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
               aid_estado,
               per_codigo,
               aid_operacion,
               aid_usuario_bd,
               aid_fecha_cambio
           )
           SELECT i.ado_codigo,
                  i.idi_codigo,
                  i.adi_estado,
                  @per_actor,
                  'U',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   deleted AS d
                  INNER JOIN
                  inserted AS i
                  ON i.ado_codigo = d.ado_codigo
                     AND i.idi_codigo = d.idi_codigo
           WHERE  EXISTS (SELECT i.adi_estado
                          EXCEPT
                          SELECT d.adi_estado);
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
-- [adf] Bloquea el borrado físico y archiva en [sgspi].[aud_activo_documental_formato_archivo] las altas ('I') y la versión resultante (after-image) de cada fila modificada ('U')
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
           -- [AP-24] Serializa el agregado por raíz (aci) en orden ascendente para evitar deadlocks AB-BA
           DECLARE @lock_id AS INT = (SELECT MIN(ado_codigo)
                                      FROM   (SELECT ado_codigo
                                              FROM   inserted
                                              UNION
                                              SELECT ado_codigo
                                              FROM   deleted) AS l), @lock_res AS NVARCHAR (60), @lock_rc AS INT;
           WHILE @lock_id IS NOT NULL
               BEGIN
                   SET @lock_res = CONCAT(N'sgspi:aci:', @lock_id);
                   EXECUTE @lock_rc = sys.sp_getapplock @Resource = @lock_res, @LockMode = 'Exclusive', @LockOwner = 'Transaction', @LockTimeout = 10000;
                   IF @lock_rc < 0
                       THROW 50023, N'Tiempo de espera agotado al adquirir bloqueo del agregado [sgspi:aci] en [sgspi].[activo_documental_formato_archivo].', 1;
                   SET @lock_id = (SELECT MIN(ado_codigo)
                                   FROM   (SELECT ado_codigo
                                           FROM   inserted
                                           UNION
                                           SELECT ado_codigo
                                           FROM   deleted) AS l
                                   WHERE  l.ado_codigo > @lock_id);
               END
           IF EXISTS (SELECT 1
                      FROM   (SELECT ado_codigo
                              FROM   inserted
                              UNION
                              SELECT ado_codigo
                              FROM   deleted) AS x
                             INNER JOIN
                             sgspi.activo_informacion AS p
                             ON p.aci_codigo = x.ado_codigo
                             INNER JOIN
                             sgspi.estado_flujo_catalogo AS efc
                             ON efc.efc_dominio = N'ACI'
                                AND efc.efc_identificador = p.aci_fase_registro
                      WHERE  efc.efc_permite_edicion = 0
                             OR efc.efc_estado = 0)
               THROW 50011, N'Operación denegada: No se permite insertar ni modificar registros de [sgspi].[activo_documental_formato_archivo] cuando el padre no es editable.', 1;
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona activa (usuario_administrativos/usuario_docentes.sys) para ORIGINAL_LOGIN().', 1;
           -- [AP-02] D5: los roles líder y custodio solo escriben activos de su alcance (ufn_activo_en_alcance; LEFT JOIN evita bypass por RLS)
           IF EXISTS (SELECT 1
                      FROM   (SELECT ado_codigo
                              FROM   inserted
                              UNION
                              SELECT ado_codigo
                              FROM   deleted) AS x
                             LEFT OUTER JOIN
                             sgspi.activo_informacion AS p
                             ON p.aci_codigo = x.ado_codigo
                             OUTER APPLY sgspi.ufn_activo_en_alcance(p.aci_codigo, p.uaa_codigo, @per_actor) AS a
                      WHERE  a.permitido IS NULL)
               THROW 50021, N'Fuera de alcance: el activo no es de las UAA ni de los procesos del usuario en [sgspi].[activo_documental_formato_archivo].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_activo_documental_formato_archivo (
                       ado_codigo,
                       fac_codigo,
                       afd_estado,
                       per_codigo,
                       afd_operacion,
                       afd_usuario_bd,
                       afd_fecha_cambio
                   )
                   SELECT i.ado_codigo,
                          i.fac_codigo,
                          i.adf_estado,
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
                                                AND i.fac_codigo = d.fac_codigo))
               THROW 50011, N'Operación denegada: No se permite cambiar la clave de [sgspi].[activo_documental_formato_archivo]; desactive la fila y cree una nueva.', 1;
           INSERT INTO sgspi.aud_activo_documental_formato_archivo (
               ado_codigo,
               fac_codigo,
               afd_estado,
               per_codigo,
               afd_operacion,
               afd_usuario_bd,
               afd_fecha_cambio
           )
           SELECT i.ado_codigo,
                  i.fac_codigo,
                  i.adf_estado,
                  @per_actor,
                  'U',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   deleted AS d
                  INNER JOIN
                  inserted AS i
                  ON i.ado_codigo = d.ado_codigo
                     AND i.fac_codigo = d.fac_codigo
           WHERE  EXISTS (SELECT i.adf_estado
                          EXCEPT
                          SELECT d.adf_estado);
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [aau] La auditoría no se edita ni se borra
CREATE OR ALTER TRIGGER sgspi.TR_aau_inmutabilidad
    ON sgspi.aud_activo_documental_unidad_productora
    INSTEAD OF UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           THROW 50016, N'Operación denegada: la tabla de auditoría [sgspi].[aud_activo_documental_unidad_productora] es inmutable y no admite modificaciones ni borrados.', 1;
       END


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [adu] Bloquea el borrado físico y archiva en [sgspi].[aud_activo_documental_unidad_productora] las altas ('I') y la versión resultante (after-image) de cada fila modificada ('U')
CREATE OR ALTER TRIGGER sgspi.TR_adu_auditoria
    ON sgspi.activo_documental_unidad_productora
    AFTER INSERT, UPDATE, DELETE
    AS BEGIN
           SET NOCOUNT ON;
           IF EXISTS (SELECT 1
                      FROM   deleted)
              AND NOT EXISTS (SELECT 1
                              FROM   inserted)
               THROW 50010, N'Operación denegada: No se permite eliminar físicamente registros de [sgspi].[activo_documental_unidad_productora].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   inserted)
               RETURN;
           -- [AP-24] Serializa el agregado por raíz (aci) en orden ascendente para evitar deadlocks AB-BA
           DECLARE @lock_id AS INT = (SELECT MIN(ado_codigo)
                                      FROM   (SELECT ado_codigo
                                              FROM   inserted
                                              UNION
                                              SELECT ado_codigo
                                              FROM   deleted) AS l), @lock_res AS NVARCHAR (60), @lock_rc AS INT;
           WHILE @lock_id IS NOT NULL
               BEGIN
                   SET @lock_res = CONCAT(N'sgspi:aci:', @lock_id);
                   EXECUTE @lock_rc = sys.sp_getapplock @Resource = @lock_res, @LockMode = 'Exclusive', @LockOwner = 'Transaction', @LockTimeout = 10000;
                   IF @lock_rc < 0
                       THROW 50023, N'Tiempo de espera agotado al adquirir bloqueo del agregado [sgspi:aci] en [sgspi].[activo_documental_unidad_productora].', 1;
                   SET @lock_id = (SELECT MIN(ado_codigo)
                                   FROM   (SELECT ado_codigo
                                           FROM   inserted
                                           UNION
                                           SELECT ado_codigo
                                           FROM   deleted) AS l
                                   WHERE  l.ado_codigo > @lock_id);
               END
           IF EXISTS (SELECT 1
                      FROM   (SELECT ado_codigo
                              FROM   inserted
                              UNION
                              SELECT ado_codigo
                              FROM   deleted) AS x
                             INNER JOIN
                             sgspi.activo_informacion AS p
                             ON p.aci_codigo = x.ado_codigo
                             INNER JOIN
                             sgspi.estado_flujo_catalogo AS efc
                             ON efc.efc_dominio = N'ACI'
                                AND efc.efc_identificador = p.aci_fase_registro
                      WHERE  efc.efc_permite_edicion = 0
                             OR efc.efc_estado = 0)
               THROW 50011, N'Operación denegada: No se permite insertar ni modificar registros de [sgspi].[activo_documental_unidad_productora] cuando el padre no es editable.', 1;
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona activa (usuario_administrativos/usuario_docentes.sys) para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_activo_documental_unidad_productora (
                       ado_codigo,
                       upc_codigo,
                       aau_estado,
                       per_codigo,
                       aau_operacion,
                       aau_usuario_bd,
                       aau_fecha_cambio
                   )
                   SELECT i.ado_codigo,
                          i.upc_codigo,
                          i.adu_estado,
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
               aau_estado,
               per_codigo,
               aau_operacion,
               aau_usuario_bd,
               aau_fecha_cambio
           )
           SELECT i.ado_codigo,
                  i.upc_codigo,
                  i.adu_estado,
                  @per_actor,
                  'U',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   deleted AS d
                  INNER JOIN
                  inserted AS i
                  ON i.ado_codigo = d.ado_codigo
                     AND i.upc_codigo = d.upc_codigo
           WHERE  EXISTS (SELECT i.adu_estado
                          EXCEPT
                          SELECT d.adu_estado);
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
-- [epr] Bloquea el borrado físico y archiva en [sgspi].[aud_escala_probabilidad] las altas ('I') y la versión resultante (after-image) de cada fila modificada ('U')
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
               THROW 50017, N'No se encontró una persona activa (usuario_administrativos/usuario_docentes.sys) para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_escala_probabilidad (
                       epr_codigo,
                       aer_codigo_letra,
                       aer_nombre_nivel,
                       aer_descripcion_criterio,
                       aer_frecuencia_referencia,
                       aer_estado,
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
                          i.epr_estado,
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
               aer_estado,
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
                  i.epr_estado,
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
                                 i.epr_estado
                          EXCEPT
                          SELECT d.epr_codigo_letra,
                                 d.epr_nombre_nivel,
                                 d.epr_descripcion_criterio,
                                 d.epr_frecuencia_referencia,
                                 d.epr_estado);
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
-- [eim] Bloquea el borrado físico y archiva en [sgspi].[aud_escala_impacto] las altas ('I') y la versión resultante (after-image) de cada fila modificada ('U')
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
               THROW 50017, N'No se encontró una persona activa (usuario_administrativos/usuario_docentes.sys) para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_escala_impacto (
                       eim_codigo,
                       aem_nombre_impacto_negativo,
                       aem_nombre_impacto_positivo,
                       aem_descripcion_organizacional,
                       aem_descripcion_operativa,
                       aem_estado,
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
                          i.eim_estado,
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
               aem_estado,
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
                  i.eim_estado,
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
                                 i.eim_estado
                          EXCEPT
                          SELECT d.eim_nombre_impacto_negativo,
                                 d.eim_nombre_impacto_positivo,
                                 d.eim_descripcion_organizacional,
                                 d.eim_descripcion_operativa,
                                 d.eim_estado);
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
-- [zrc] Bloquea el borrado físico y archiva en [sgspi].[aud_zona_riesgo_catalogo] las altas ('I') y la versión resultante (after-image) de cada fila modificada ('U')
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
               THROW 50017, N'No se encontró una persona activa (usuario_administrativos/usuario_docentes.sys) para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_zona_riesgo_catalogo (
                       zrc_codigo,
                       azc_nombre_nivel,
                       azc_orden,
                       azc_estado,
                       per_codigo,
                       azc_operacion,
                       azc_usuario_bd,
                       azc_fecha_cambio
                   )
                   SELECT i.zrc_codigo,
                          i.zrc_nombre_nivel,
                          i.zrc_orden,
                          i.zrc_estado,
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
               azc_estado,
               per_codigo,
               azc_operacion,
               azc_usuario_bd,
               azc_fecha_cambio
           )
           SELECT i.zrc_codigo,
                  i.zrc_nombre_nivel,
                  i.zrc_orden,
                  i.zrc_estado,
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
                                 i.zrc_estado
                          EXCEPT
                          SELECT d.zrc_nombre_nivel,
                                 d.zrc_orden,
                                 d.zrc_estado);
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
-- [mvr] Bloquea el borrado físico y archiva en [sgspi].[aud_matriz_valoracion_riesgo] las altas ('I') y la versión resultante (after-image) de cada fila modificada ('U')
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
               THROW 50017, N'No se encontró una persona activa (usuario_administrativos/usuario_docentes.sys) para ORIGINAL_LOGIN().', 1;
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
                       amr_estado,
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
                          i.mvr_estado,
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
               amr_estado,
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
                  i.mvr_estado,
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
                                 i.mvr_estado
                          EXCEPT
                          SELECT d.zrc_codigo,
                                 d.mvr_directriz_tratamiento_riesgo,
                                 d.mvr_directriz_tratamiento_oportunidad,
                                 d.mvr_requiere_aprobacion_comite,
                                 d.mvr_estado);
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
-- [etc] Bloquea el borrado físico y archiva en [sgspi].[aud_estrategia_tratamiento_catalogo] las altas ('I') y la versión resultante (after-image) de cada fila modificada ('U')
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
               THROW 50017, N'No se encontró una persona activa (usuario_administrativos/usuario_docentes.sys) para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_estrategia_tratamiento_catalogo (
                       etc_codigo,
                       aet_nombre_estrategia,
                       aet_naturaleza_aplicable,
                       aet_descripcion,
                       aet_estado,
                       per_codigo,
                       aet_operacion,
                       aet_usuario_bd,
                       aet_fecha_cambio
                   )
                   SELECT i.etc_codigo,
                          i.etc_nombre_estrategia,
                          i.etc_naturaleza_aplicable,
                          i.etc_descripcion,
                          i.etc_estado,
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
               aet_estado,
               per_codigo,
               aet_operacion,
               aet_usuario_bd,
               aet_fecha_cambio
           )
           SELECT i.etc_codigo,
                  i.etc_nombre_estrategia,
                  i.etc_naturaleza_aplicable,
                  i.etc_descripcion,
                  i.etc_estado,
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
                                 i.etc_estado
                          EXCEPT
                          SELECT d.etc_nombre_estrategia,
                                 d.etc_naturaleza_aplicable,
                                 d.etc_descripcion,
                                 d.etc_estado);
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
-- [enc] Bloquea el borrado físico y archiva en [sgspi].[aud_estandar_normativo_catalogo] las altas ('I') y la versión resultante (after-image) de cada fila modificada ('U')
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
               THROW 50017, N'No se encontró una persona activa (usuario_administrativos/usuario_docentes.sys) para ORIGINAL_LOGIN().', 1;
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
                       aen_estado,
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
                          i.enc_estado,
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
               aen_estado,
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
                  i.enc_estado,
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
                                 i.enc_estado
                          EXCEPT
                          SELECT d.enc_identificador,
                                 d.enc_familia_norma,
                                 d.enc_nombre,
                                 d.enc_organismo,
                                 d.enc_anio_edicion,
                                 d.enc_estado);
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
-- [crn] Bloquea el borrado físico y archiva en [sgspi].[aud_control_referencia_normativa] las altas ('I') y la versión resultante (after-image) de cada fila modificada ('U')
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
               THROW 50017, N'No se encontró una persona activa (usuario_administrativos/usuario_docentes.sys) para ORIGINAL_LOGIN().', 1;
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
                       acn_estado,
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
                          i.crn_estado,
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
               acn_estado,
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
                  i.crn_estado,
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
                                 i.crn_estado
                          EXCEPT
                          SELECT d.enc_codigo,
                                 d.crn_rol_privacidad_pii,
                                 d.crn_identificador_control,
                                 d.crn_nombre_control,
                                 d.crn_objetivo_requisito,
                                 d.crn_estado);
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
-- [aac] Bloquea el borrado físico y archiva en [sgspi].[aud_atributo_control_catalogo] las altas ('I') y la versión resultante (after-image) de cada fila modificada ('U')
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
               THROW 50017, N'No se encontró una persona activa (usuario_administrativos/usuario_docentes.sys) para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_atributo_control_catalogo (
                       aac_codigo,
                       acc_tipo_atributo,
                       acc_valor,
                       acc_estado,
                       per_codigo,
                       acc_operacion,
                       acc_usuario_bd,
                       acc_fecha_cambio
                   )
                   SELECT i.aac_codigo,
                          i.aac_tipo_atributo,
                          i.aac_valor,
                          i.aac_estado,
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
               acc_estado,
               per_codigo,
               acc_operacion,
               acc_usuario_bd,
               acc_fecha_cambio
           )
           SELECT i.aac_codigo,
                  i.aac_tipo_atributo,
                  i.aac_valor,
                  i.aac_estado,
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
                                 i.aac_estado
                          EXCEPT
                          SELECT d.aac_tipo_atributo,
                                 d.aac_valor,
                                 d.aac_estado);
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
-- [cra] Bloquea el borrado físico y archiva en [sgspi].[aud_control_referencia_normativa_atributo] las altas ('I') y la versión resultante (after-image) de cada fila modificada ('U')
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
               THROW 50017, N'No se encontró una persona activa (usuario_administrativos/usuario_docentes.sys) para ORIGINAL_LOGIN().', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_control_referencia_normativa_atributo (
                       crn_codigo,
                       aac_codigo,
                       aca_estado,
                       per_codigo,
                       aca_operacion,
                       aca_usuario_bd,
                       aca_fecha_cambio
                   )
                   SELECT i.crn_codigo,
                          i.aac_codigo,
                          i.cra_estado,
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
               aca_estado,
               per_codigo,
               aca_operacion,
               aca_usuario_bd,
               aca_fecha_cambio
           )
           SELECT i.crn_codigo,
                  i.aac_codigo,
                  i.cra_estado,
                  @per_actor,
                  'U',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   deleted AS d
                  INNER JOIN
                  inserted AS i
                  ON i.crn_codigo = d.crn_codigo
                     AND i.aac_codigo = d.aac_codigo
           WHERE  EXISTS (SELECT i.cra_estado
                          EXCEPT
                          SELECT d.cra_estado);
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
-- [ptc] Bloquea el borrado físico y archiva en [sgspi].[aud_plan_tratamiento_control_referencia_normativa] las altas ('I') y la versión resultante (after-image) de cada fila modificada ('U')
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
           -- [AP-24] Serializa el agregado por raíz (eia) en orden ascendente para evitar deadlocks AB-BA
           DECLARE @raices_eia TABLE (
               eia_codigo INT PRIMARY KEY);
           INSERT INTO @raices_eia (
               eia_codigo
           )
           SELECT DISTINCT plt.eia_codigo
           FROM   (SELECT plt_codigo
                   FROM   inserted
                   UNION
                   SELECT plt_codigo
                   FROM   deleted) AS x
                  INNER JOIN
                  sgspi.plan_tratamiento AS plt
                  ON plt.plt_codigo = x.plt_codigo;
           DECLARE @lock_id AS INT = (SELECT MIN(eia_codigo)
                                      FROM   @raices_eia), @lock_res AS NVARCHAR (60), @lock_rc AS INT;
           WHILE @lock_id IS NOT NULL
               BEGIN
                   SET @lock_res = CONCAT(N'sgspi:eia:', @lock_id);
                   EXECUTE @lock_rc = sys.sp_getapplock @Resource = @lock_res, @LockMode = 'Exclusive', @LockOwner = 'Transaction', @LockTimeout = 10000;
                   IF @lock_rc < 0
                       THROW 50023, N'Tiempo de espera agotado al adquirir bloqueo del agregado [sgspi:eia] en [sgspi].[plan_tratamiento_control_referencia_normativa].', 1;
                   SET @lock_id = (SELECT MIN(eia_codigo)
                                   FROM   @raices_eia
                                   WHERE  eia_codigo > @lock_id);
               END
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
                             sgspi.evento_incertidumbre_activo AS p
                             ON p.eia_codigo = plt.eia_codigo
                             INNER JOIN
                             sgspi.estado_flujo_catalogo AS efc
                             ON efc.efc_dominio = N'EIA'
                                AND efc.efc_identificador = p.eia_fase_registro
                      WHERE  efc.efc_permite_edicion = 0
                             OR efc.efc_estado = 0)
               THROW 50011, N'Operación denegada: No se permite insertar ni modificar registros de [sgspi].[plan_tratamiento_control_referencia_normativa] cuando el padre no es editable.', 1;
           DECLARE @per_actor AS INT = (SELECT per_codigo
                                        FROM   sgspi.ufn_persona_sesion());
           IF @per_actor IS NULL
               THROW 50017, N'No se encontró una persona activa (usuario_administrativos/usuario_docentes.sys) para ORIGINAL_LOGIN().', 1;
           -- [AP-02] D5: los roles líder y custodio solo escriben en procesos de su alcance (ufn_proceso_en_alcance; LEFT JOIN evita bypass por RLS)
           IF EXISTS (SELECT 1
                      FROM   (SELECT plt_codigo
                              FROM   inserted
                              UNION
                              SELECT plt_codigo
                              FROM   deleted) AS x
                             LEFT OUTER JOIN
                             sgspi.plan_tratamiento AS plt
                             ON plt.plt_codigo = x.plt_codigo
                             LEFT OUTER JOIN
                             sgspi.evento_incertidumbre_activo AS eia
                             ON eia.eia_codigo = plt.eia_codigo
                             OUTER APPLY sgspi.ufn_proceso_en_alcance(eia.pri_codigo, @per_actor) AS a
                      WHERE  a.permitido IS NULL)
               THROW 50021, N'Fuera de alcance: el proceso del evento no está en las UAA del usuario en [sgspi].[plan_tratamiento_control_referencia_normativa].', 1;
           IF NOT EXISTS (SELECT 1
                          FROM   deleted)
               BEGIN
                   INSERT INTO sgspi.aud_plan_tratamiento_control_referencia_normativa (
                       plt_codigo,
                       crn_codigo,
                       acp_estado,
                       per_codigo,
                       acp_operacion,
                       acp_usuario_bd,
                       acp_fecha_cambio
                   )
                   SELECT i.plt_codigo,
                          i.crn_codigo,
                          i.ptc_estado,
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
               acp_estado,
               per_codigo,
               acp_operacion,
               acp_usuario_bd,
               acp_fecha_cambio
           )
           SELECT i.plt_codigo,
                  i.crn_codigo,
                  i.ptc_estado,
                  @per_actor,
                  'U',
                  ORIGINAL_LOGIN(),
                  SYSDATETIMEOFFSET()
           FROM   deleted AS d
                  INNER JOIN
                  inserted AS i
                  ON i.plt_codigo = d.plt_codigo
                     AND i.crn_codigo = d.crn_codigo
           WHERE  EXISTS (SELECT i.ptc_estado
                          EXCEPT
                          SELECT d.ptc_estado);
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

IF DATABASE_PRINCIPAL_ID(N'sgspi_rol_login') IS NULL
    CREATE ROLE sgspi_rol_login; -- Cuenta compartida de login de la aplicación (LoginDS Spring Boot)

ALTER ROLE sgspi_rol_base ADD MEMBER sgspi_rol_custodio_operador;

ALTER ROLE sgspi_rol_base ADD MEMBER sgspi_rol_lider_propietario;

ALTER ROLE sgspi_rol_base ADD MEMBER sgspi_rol_gestor_documental;

ALTER ROLE sgspi_rol_base ADD MEMBER sgspi_rol_oficial_seguridad_privacidad;

ALTER ROLE sgspi_rol_base ADD MEMBER sgspi_rol_comite_direccion;

ALTER ROLE sgspi_rol_base ADD MEMBER sgspi_rol_auditor_control;

-- Base: lista blanca de lectura sobre las 49 tablas de negocio, la vista de alcance y las 5 funciones inline (las 49 aud_* quedan solo para auditor y oficial).
-- ALTER es lo que habilita TRUNCATE y DISABLE TRIGGER. Las 6 vistas de reporte se otorgan al final de la sección 6.
GRANT SELECT
    ON sgspi.periodo_vigencia TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.estado_flujo_catalogo TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.transicion_estado_flujo TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.tipo_proceso_catalogo TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.proceso_institucional TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.proceso_institucional_uaa TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.factor_entorno_catalogo TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.analisis_contexto_factor TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.parte_interesada TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.requisito_parte_interesada TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.requisito_parte_interesada_proceso_institucional TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.tipo_activo_catalogo TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.causal_excepcion_transparencia TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.activo_informacion TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.activo_informacion_proceso_institucional TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.activo_informacion_sede TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.activo_informacion_responsable TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.sistema_informacion_ficha TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.modulo_sistema_informacion TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.serie_documental_catalogo TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.subserie_documental_catalogo TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.unidad_productora_cuadro_clasificacion_documental TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.periodicidad_catalogo TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.estado_publicacion_catalogo TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.soporte_registro_catalogo TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.medio_conservacion_catalogo TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.idioma_catalogo TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.formato_archivo_catalogo TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.activo_documental TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.activo_documental_soporte_registro TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.activo_documental_medio_conservacion TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.activo_documental_idioma TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.activo_documental_formato_archivo TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.activo_documental_unidad_productora TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.escala_probabilidad TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.escala_impacto TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.zona_riesgo_catalogo TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.matriz_valoracion_riesgo TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.evento_incertidumbre_activo TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.estrategia_tratamiento_catalogo TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.plan_tratamiento TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.actividad_tratamiento TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.seguimiento_actividad TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.estandar_normativo_catalogo TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.control_referencia_normativa TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.atributo_control_catalogo TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.control_referencia_normativa_atributo TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.plan_tratamiento_control_referencia_normativa TO sgspi_rol_base;

-- A2: SoA (evaluacion_aplicabilidad_control) se retira de sgspi_rol_base y se otorga solo a roles con necesidad operativa/gobierno
GRANT SELECT
    ON sgspi.evaluacion_aplicabilidad_control TO sgspi_rol_oficial_seguridad_privacidad, sgspi_rol_auditor_control, sgspi_rol_comite_direccion, sgspi_rol_lider_propietario;

GRANT SELECT
    ON sgspi.vw_usuario_rol_alcance_sgspi TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.ufn_persona_sesion TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.ufn_proceso_en_alcance TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.ufn_activo_en_alcance TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.ufn_rls_alcance_aip TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.ufn_rls_alcance_proceso TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.ufn_rls_alcance_activo TO sgspi_rol_base;

-- [B5] Helper de consecutivos para roles que crean acf, eia o act
GRANT EXECUTE
    ON sgspi.usp_siguiente_consecutivo TO sgspi_rol_custodio_operador, sgspi_rol_lider_propietario, sgspi_rol_gestor_documental, sgspi_rol_oficial_seguridad_privacidad;

DENY ALTER
    ON SCHEMA::sgspi TO sgspi_rol_base;

-- [AP-22] Ningún registro se elimina: la baja es lógica (<acr>_estado = 0). El DENY también anula db_datawriter.
DENY DELETE
    ON SCHEMA::sgspi TO sgspi_rol_base;

-- D8 / A4: la cuenta compartida queda fuera de sgspi_rol_base y solo lee por lista blanca los catálogos (aquí)
-- y las cuatro vistas públicas vigentes sin PII/ICC restringida (al final de la sección 6, tras crearlas).
-- Se blinda contra errores de DBA (escritura/DDL) y se otorga SELECT sobre las 3 funciones RLS (SCHEMABINDING = OFF).
DENY INSERT, UPDATE, DELETE, ALTER
    ON SCHEMA::sgspi TO sgspi_rol_consulta;

-- LoginDS (estándar Spring Boot USCO): solo lee sgspi.vw_sgspi_admin_login; los demás roles tienen DENY explícito (expone uwd2).
DENY INSERT, UPDATE, DELETE, ALTER
    ON SCHEMA::sgspi TO sgspi_rol_login;

GRANT SELECT
    ON sgspi.vw_sgspi_admin_login TO sgspi_rol_login;

DENY SELECT
    ON sgspi.vw_sgspi_admin_login TO sgspi_rol_base, sgspi_rol_consulta;

GRANT SELECT
    ON sgspi.ufn_rls_alcance_aip TO sgspi_rol_consulta;

GRANT SELECT
    ON sgspi.ufn_rls_alcance_proceso TO sgspi_rol_consulta;

GRANT SELECT
    ON sgspi.ufn_rls_alcance_activo TO sgspi_rol_consulta;

-- A1: Sin GRANT UNMASK global (en SQL 2019 expone [dbo] y columnas de auditoría); reemplazado por DENY SELECT explícito por columna.
DENY SELECT
    ON sgspi.plan_tratamiento (plt_presupuesto_estimado_cop) TO sgspi_rol_custodio_operador, sgspi_rol_gestor_documental;

DENY SELECT
    ON sgspi.evaluacion_aplicabilidad_control (eac_observaciones_auditoria) TO sgspi_rol_lider_propietario, sgspi_rol_custodio_operador, sgspi_rol_gestor_documental;

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

-- Columnas inmutables para la aplicación: creador, consecutivos, fechas de control (las mantienen DEFAULT y triggers) y avance derivado de [sga].
DENY UPDATE
    ON sgspi.periodo_vigencia (pev_fecha_creacion) TO sgspi_rol_base;

DENY UPDATE
    ON sgspi.analisis_contexto_factor (acf_numero_factor, per_codigo_creador, per_codigo_aprobador, acf_fecha_creacion, acf_fecha_actualizacion) TO sgspi_rol_base;

DENY UPDATE
    ON sgspi.requisito_parte_interesada (per_codigo_creador, per_codigo_aprobador, rpi_fecha_creacion, rpi_fecha_actualizacion) TO sgspi_rol_base;

DENY UPDATE
    ON sgspi.requisito_parte_interesada_proceso_institucional (rpp_fecha_registro) TO sgspi_rol_base;

DENY UPDATE
    ON sgspi.activo_informacion (per_codigo_creador, per_codigo_aprobador, per_codigo_revisor_archivo, aci_fecha_creacion, aci_fecha_actualizacion) TO sgspi_rol_base;

DENY UPDATE
    ON sgspi.activo_documental (ado_fecha_creacion, ado_fecha_actualizacion) TO sgspi_rol_base;

DENY UPDATE
    ON sgspi.evento_incertidumbre_activo (eia_numero_evento, per_codigo_creador, per_codigo_validador_lider, per_codigo_revisor_sgspi, per_codigo_aprobador_comite, eia_fecha_creacion, eia_fecha_actualizacion) TO sgspi_rol_base;

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
    ON sgspi.activo_informacion (aci_fase_registro) TO sgspi_rol_gestor_documental;

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
    ON sgspi.evento_incertidumbre_activo (eia_fase_registro) TO sgspi_rol_comite_direccion;

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
    ON sgspi.seguimiento_actividad (sga_estado) TO sgspi_rol_custodio_operador, sgspi_rol_lider_propietario, sgspi_rol_gestor_documental; -- [AP-22] solo borrado lógico

GRANT INSERT, UPDATE
    ON sgspi.evaluacion_aplicabilidad_control TO sgspi_rol_oficial_seguridad_privacidad;

-- Tablas puente: INSERT y UPDATE; una asociación errada se desactiva con <acr>_estado = 0 (nunca DELETE) [AP-22].
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
    ON sgspi.evento_incertidumbre_activo (eia_fase_registro) TO sgspi_rol_auditor_control;

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

-- [AP-01] [AP-02] Lectura de las 49 tablas aud_* restringida exclusivamente a auditoría y oficial de seguridad/privacidad
GRANT SELECT
    ON sgspi.aud_periodo_vigencia TO sgspi_rol_auditor_control, sgspi_rol_oficial_seguridad_privacidad;

GRANT SELECT
    ON sgspi.aud_estado_flujo_catalogo TO sgspi_rol_auditor_control, sgspi_rol_oficial_seguridad_privacidad;

GRANT SELECT
    ON sgspi.aud_transicion_estado_flujo TO sgspi_rol_auditor_control, sgspi_rol_oficial_seguridad_privacidad;

GRANT SELECT
    ON sgspi.aud_tipo_proceso_catalogo TO sgspi_rol_auditor_control, sgspi_rol_oficial_seguridad_privacidad;

GRANT SELECT
    ON sgspi.aud_proceso_institucional TO sgspi_rol_auditor_control, sgspi_rol_oficial_seguridad_privacidad;

GRANT SELECT
    ON sgspi.aud_proceso_institucional_uaa TO sgspi_rol_auditor_control, sgspi_rol_oficial_seguridad_privacidad;

GRANT SELECT
    ON sgspi.aud_factor_entorno_catalogo TO sgspi_rol_auditor_control, sgspi_rol_oficial_seguridad_privacidad;

GRANT SELECT
    ON sgspi.aud_analisis_contexto_factor TO sgspi_rol_auditor_control, sgspi_rol_oficial_seguridad_privacidad;

GRANT SELECT
    ON sgspi.aud_parte_interesada TO sgspi_rol_auditor_control, sgspi_rol_oficial_seguridad_privacidad;

GRANT SELECT
    ON sgspi.aud_requisito_parte_interesada TO sgspi_rol_auditor_control, sgspi_rol_oficial_seguridad_privacidad;

GRANT SELECT
    ON sgspi.aud_requisito_parte_interesada_proceso_institucional TO sgspi_rol_auditor_control, sgspi_rol_oficial_seguridad_privacidad;

GRANT SELECT
    ON sgspi.aud_tipo_activo_catalogo TO sgspi_rol_auditor_control, sgspi_rol_oficial_seguridad_privacidad;

GRANT SELECT
    ON sgspi.aud_causal_excepcion_transparencia TO sgspi_rol_auditor_control, sgspi_rol_oficial_seguridad_privacidad;

GRANT SELECT
    ON sgspi.aud_activo_informacion TO sgspi_rol_auditor_control, sgspi_rol_oficial_seguridad_privacidad;

GRANT SELECT
    ON sgspi.aud_activo_informacion_proceso_institucional TO sgspi_rol_auditor_control, sgspi_rol_oficial_seguridad_privacidad;

GRANT SELECT
    ON sgspi.aud_activo_informacion_sede TO sgspi_rol_auditor_control, sgspi_rol_oficial_seguridad_privacidad;

GRANT SELECT
    ON sgspi.aud_activo_informacion_responsable TO sgspi_rol_auditor_control, sgspi_rol_oficial_seguridad_privacidad;

GRANT SELECT
    ON sgspi.aud_sistema_informacion_ficha TO sgspi_rol_auditor_control, sgspi_rol_oficial_seguridad_privacidad;

GRANT SELECT
    ON sgspi.aud_modulo_sistema_informacion TO sgspi_rol_auditor_control, sgspi_rol_oficial_seguridad_privacidad;

GRANT SELECT
    ON sgspi.aud_serie_documental_catalogo TO sgspi_rol_auditor_control, sgspi_rol_oficial_seguridad_privacidad;

GRANT SELECT
    ON sgspi.aud_subserie_documental_catalogo TO sgspi_rol_auditor_control, sgspi_rol_oficial_seguridad_privacidad;

GRANT SELECT
    ON sgspi.aud_unidad_productora_cuadro_clasificacion_documental TO sgspi_rol_auditor_control, sgspi_rol_oficial_seguridad_privacidad;

GRANT SELECT
    ON sgspi.aud_periodicidad_catalogo TO sgspi_rol_auditor_control, sgspi_rol_oficial_seguridad_privacidad;

GRANT SELECT
    ON sgspi.aud_estado_publicacion_catalogo TO sgspi_rol_auditor_control, sgspi_rol_oficial_seguridad_privacidad;

GRANT SELECT
    ON sgspi.aud_soporte_registro_catalogo TO sgspi_rol_auditor_control, sgspi_rol_oficial_seguridad_privacidad;

GRANT SELECT
    ON sgspi.aud_medio_conservacion_catalogo TO sgspi_rol_auditor_control, sgspi_rol_oficial_seguridad_privacidad;

GRANT SELECT
    ON sgspi.aud_idioma_catalogo TO sgspi_rol_auditor_control, sgspi_rol_oficial_seguridad_privacidad;

GRANT SELECT
    ON sgspi.aud_formato_archivo_catalogo TO sgspi_rol_auditor_control, sgspi_rol_oficial_seguridad_privacidad;

GRANT SELECT
    ON sgspi.aud_activo_documental TO sgspi_rol_auditor_control, sgspi_rol_oficial_seguridad_privacidad;

GRANT SELECT
    ON sgspi.aud_activo_documental_soporte_registro TO sgspi_rol_auditor_control, sgspi_rol_oficial_seguridad_privacidad;

GRANT SELECT
    ON sgspi.aud_activo_documental_medio_conservacion TO sgspi_rol_auditor_control, sgspi_rol_oficial_seguridad_privacidad;

GRANT SELECT
    ON sgspi.aud_activo_documental_idioma TO sgspi_rol_auditor_control, sgspi_rol_oficial_seguridad_privacidad;

GRANT SELECT
    ON sgspi.aud_activo_documental_formato_archivo TO sgspi_rol_auditor_control, sgspi_rol_oficial_seguridad_privacidad;

GRANT SELECT
    ON sgspi.aud_activo_documental_unidad_productora TO sgspi_rol_auditor_control, sgspi_rol_oficial_seguridad_privacidad;

GRANT SELECT
    ON sgspi.aud_escala_probabilidad TO sgspi_rol_auditor_control, sgspi_rol_oficial_seguridad_privacidad;

GRANT SELECT
    ON sgspi.aud_escala_impacto TO sgspi_rol_auditor_control, sgspi_rol_oficial_seguridad_privacidad;

GRANT SELECT
    ON sgspi.aud_zona_riesgo_catalogo TO sgspi_rol_auditor_control, sgspi_rol_oficial_seguridad_privacidad;

GRANT SELECT
    ON sgspi.aud_matriz_valoracion_riesgo TO sgspi_rol_auditor_control, sgspi_rol_oficial_seguridad_privacidad;

GRANT SELECT
    ON sgspi.aud_evento_incertidumbre_activo TO sgspi_rol_auditor_control, sgspi_rol_oficial_seguridad_privacidad;

GRANT SELECT
    ON sgspi.aud_estrategia_tratamiento_catalogo TO sgspi_rol_auditor_control, sgspi_rol_oficial_seguridad_privacidad;

GRANT SELECT
    ON sgspi.aud_plan_tratamiento TO sgspi_rol_auditor_control, sgspi_rol_oficial_seguridad_privacidad;

GRANT SELECT
    ON sgspi.aud_actividad_tratamiento TO sgspi_rol_auditor_control, sgspi_rol_oficial_seguridad_privacidad;

GRANT SELECT
    ON sgspi.aud_seguimiento_actividad TO sgspi_rol_auditor_control, sgspi_rol_oficial_seguridad_privacidad;

GRANT SELECT
    ON sgspi.aud_estandar_normativo_catalogo TO sgspi_rol_auditor_control, sgspi_rol_oficial_seguridad_privacidad;

GRANT SELECT
    ON sgspi.aud_control_referencia_normativa TO sgspi_rol_auditor_control, sgspi_rol_oficial_seguridad_privacidad;

GRANT SELECT
    ON sgspi.aud_atributo_control_catalogo TO sgspi_rol_auditor_control, sgspi_rol_oficial_seguridad_privacidad;

GRANT SELECT
    ON sgspi.aud_control_referencia_normativa_atributo TO sgspi_rol_auditor_control, sgspi_rol_oficial_seguridad_privacidad;

GRANT SELECT
    ON sgspi.aud_plan_tratamiento_control_referencia_normativa TO sgspi_rol_auditor_control, sgspi_rol_oficial_seguridad_privacidad;

GRANT SELECT
    ON sgspi.aud_evaluacion_aplicabilidad_control TO sgspi_rol_auditor_control, sgspi_rol_oficial_seguridad_privacidad;


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- RLS en lectura y escritura [AP-02][A2]: custodios y líderes solo leen y escriben registros en su alcance UAA/proceso en las 20 tablas operativas y puente.
-- BLOCK PREDICATE es obligatorio junto a FILTER PREDICATE: sin él, FILTER oculta inserted en los triggers AFTER y anula sus validaciones/auditoría.
-- SCHEMABINDING = OFF es obligatorio porque las tablas corporativas de [dbo] no tienen SCHEMABINDING.
IF EXISTS (SELECT 1
           FROM   sys.security_policies
           WHERE  schema_id = SCHEMA_ID(N'sgspi')
                  AND name = N'spol_alcance_lectura')
    DROP SECURITY POLICY sgspi.spol_alcance_lectura;

CREATE SECURITY POLICY sgspi.spol_alcance_lectura
    ADD FILTER PREDICATE sgspi.ufn_rls_alcance_proceso(pri_codigo, NULL, NULL, NULL, NULL) ON sgspi.analisis_contexto_factor,
    ADD BLOCK PREDICATE sgspi.ufn_rls_alcance_proceso(pri_codigo, NULL, NULL, NULL, NULL) ON sgspi.analisis_contexto_factor,
    ADD FILTER PREDICATE sgspi.ufn_rls_alcance_proceso(NULL, rpi_codigo, NULL, NULL, NULL) ON sgspi.requisito_parte_interesada,
    ADD BLOCK PREDICATE sgspi.ufn_rls_alcance_proceso(NULL, rpi_codigo, NULL, NULL, NULL) ON sgspi.requisito_parte_interesada,
    ADD FILTER PREDICATE sgspi.ufn_rls_alcance_proceso(pri_codigo, NULL, NULL, NULL, NULL) ON sgspi.requisito_parte_interesada_proceso_institucional,
    ADD BLOCK PREDICATE sgspi.ufn_rls_alcance_proceso(pri_codigo, NULL, NULL, NULL, NULL) ON sgspi.requisito_parte_interesada_proceso_institucional,
    ADD FILTER PREDICATE sgspi.ufn_rls_alcance_activo(aci_codigo, uaa_codigo, NULL, NULL) ON sgspi.activo_informacion,
    ADD BLOCK PREDICATE sgspi.ufn_rls_alcance_activo(aci_codigo, uaa_codigo, NULL, NULL) ON sgspi.activo_informacion,
    ADD FILTER PREDICATE sgspi.ufn_rls_alcance_aip(pri_codigo) ON sgspi.activo_informacion_proceso_institucional,
    ADD BLOCK PREDICATE sgspi.ufn_rls_alcance_aip(pri_codigo) ON sgspi.activo_informacion_proceso_institucional,
    ADD FILTER PREDICATE sgspi.ufn_rls_alcance_activo(NULL, NULL, aci_codigo, NULL) ON sgspi.activo_informacion_sede,
    ADD BLOCK PREDICATE sgspi.ufn_rls_alcance_activo(NULL, NULL, aci_codigo, NULL) ON sgspi.activo_informacion_sede,
    ADD FILTER PREDICATE sgspi.ufn_rls_alcance_activo(NULL, NULL, aci_codigo, NULL) ON sgspi.activo_informacion_responsable,
    ADD BLOCK PREDICATE sgspi.ufn_rls_alcance_activo(NULL, NULL, aci_codigo, NULL) ON sgspi.activo_informacion_responsable,
    ADD FILTER PREDICATE sgspi.ufn_rls_alcance_activo(NULL, NULL, ado_codigo, NULL) ON sgspi.activo_documental,
    ADD BLOCK PREDICATE sgspi.ufn_rls_alcance_activo(NULL, NULL, ado_codigo, NULL) ON sgspi.activo_documental,
    ADD FILTER PREDICATE sgspi.ufn_rls_alcance_activo(NULL, NULL, ado_codigo, NULL) ON sgspi.activo_documental_soporte_registro,
    ADD BLOCK PREDICATE sgspi.ufn_rls_alcance_activo(NULL, NULL, ado_codigo, NULL) ON sgspi.activo_documental_soporte_registro,
    ADD FILTER PREDICATE sgspi.ufn_rls_alcance_activo(NULL, NULL, ado_codigo, NULL) ON sgspi.activo_documental_medio_conservacion,
    ADD BLOCK PREDICATE sgspi.ufn_rls_alcance_activo(NULL, NULL, ado_codigo, NULL) ON sgspi.activo_documental_medio_conservacion,
    ADD FILTER PREDICATE sgspi.ufn_rls_alcance_activo(NULL, NULL, ado_codigo, NULL) ON sgspi.activo_documental_idioma,
    ADD BLOCK PREDICATE sgspi.ufn_rls_alcance_activo(NULL, NULL, ado_codigo, NULL) ON sgspi.activo_documental_idioma,
    ADD FILTER PREDICATE sgspi.ufn_rls_alcance_activo(NULL, NULL, ado_codigo, NULL) ON sgspi.activo_documental_formato_archivo,
    ADD BLOCK PREDICATE sgspi.ufn_rls_alcance_activo(NULL, NULL, ado_codigo, NULL) ON sgspi.activo_documental_formato_archivo,
    ADD FILTER PREDICATE sgspi.ufn_rls_alcance_activo(NULL, NULL, ado_codigo, NULL) ON sgspi.activo_documental_unidad_productora,
    ADD BLOCK PREDICATE sgspi.ufn_rls_alcance_activo(NULL, NULL, ado_codigo, NULL) ON sgspi.activo_documental_unidad_productora,
    ADD FILTER PREDICATE sgspi.ufn_rls_alcance_proceso(pri_codigo, NULL, NULL, NULL, NULL) ON sgspi.evento_incertidumbre_activo,
    ADD BLOCK PREDICATE sgspi.ufn_rls_alcance_proceso(pri_codigo, NULL, NULL, NULL, NULL) ON sgspi.evento_incertidumbre_activo,
    ADD FILTER PREDICATE sgspi.ufn_rls_alcance_proceso(NULL, NULL, eia_codigo, NULL, NULL) ON sgspi.plan_tratamiento,
    ADD BLOCK PREDICATE sgspi.ufn_rls_alcance_proceso(NULL, NULL, eia_codigo, NULL, NULL) ON sgspi.plan_tratamiento,
    ADD FILTER PREDICATE sgspi.ufn_rls_alcance_proceso(NULL, NULL, NULL, plt_codigo, NULL) ON sgspi.plan_tratamiento_control_referencia_normativa,
    ADD BLOCK PREDICATE sgspi.ufn_rls_alcance_proceso(NULL, NULL, NULL, plt_codigo, NULL) ON sgspi.plan_tratamiento_control_referencia_normativa,
    ADD FILTER PREDICATE sgspi.ufn_rls_alcance_proceso(NULL, NULL, NULL, plt_codigo, NULL) ON sgspi.actividad_tratamiento,
    ADD BLOCK PREDICATE sgspi.ufn_rls_alcance_proceso(NULL, NULL, NULL, plt_codigo, NULL) ON sgspi.actividad_tratamiento,
    ADD FILTER PREDICATE sgspi.ufn_rls_alcance_proceso(NULL, NULL, NULL, NULL, act_codigo) ON sgspi.seguimiento_actividad,
    ADD BLOCK PREDICATE sgspi.ufn_rls_alcance_proceso(NULL, NULL, NULL, NULL, act_codigo) ON sgspi.seguimiento_actividad,
    ADD FILTER PREDICATE sgspi.ufn_rls_alcance_activo(NULL, NULL, aci_codigo, NULL) ON sgspi.sistema_informacion_ficha,
    ADD BLOCK PREDICATE sgspi.ufn_rls_alcance_activo(NULL, NULL, aci_codigo, NULL) ON sgspi.sistema_informacion_ficha,
    ADD FILTER PREDICATE sgspi.ufn_rls_alcance_activo(NULL, NULL, NULL, sif_codigo) ON sgspi.modulo_sistema_informacion,
    ADD BLOCK PREDICATE sgspi.ufn_rls_alcance_activo(NULL, NULL, NULL, sif_codigo) ON sgspi.modulo_sistema_informacion
    WITH (STATE = ON, SCHEMABINDING = OFF);


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
       acf.acf_fase_registro
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
WHERE  acf.acf_estado = 1; -- [AP-22]


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
          WHERE  ai.aci_fase_registro = N'VIGENTE'
                 AND ai.aci_estado = 1) -- [AP-22]
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
SELECT eia.eia_identificador_evento AS eia_codigo_riesgo_oportunidad,
       eia.eia_escenario_operacional AS eia_riesgo_oportunidad,
       pr.pri_nombre AS pri_proceso,
       CONCAT(N'Activo primario: ', ap.aci_nombre_activo, N' | Activo secundario: ', asop.aci_nombre_activo) AS eia_detalle_del_riesgo,
       CONCAT(N'Posibilidad: ', ep_inh.epr_nombre_nivel, N' (', ep_inh.epr_codigo_letra, N') | Impacto: ', CASE WHEN eia.eia_naturaleza_evento = N'RIESGO' THEN ei_inh.eim_nombre_impacto_negativo ELSE ei_inh.eim_nombre_impacto_positivo END, N' (', ei_inh.eim_codigo, N') | Nivel actual: ', zrc_inh.zrc_nombre_nivel) AS eia_resultado_actual,
       CONCAT(N'Posibilidad: ', ep_meta.epr_nombre_nivel, N' (', ep_meta.epr_codigo_letra, N') | Impacto: ', CASE WHEN eia.eia_naturaleza_evento = N'RIESGO' THEN ei_meta.eim_nombre_impacto_negativo ELSE ei_meta.eim_nombre_impacto_positivo END, N' (', ei_meta.eim_codigo, N') | Nivel esperado: ', zrc_meta.zrc_nombre_nivel) AS plt_resultado_esperado,
       STUFF((SELECT   N', ' + crn.crn_identificador_control
              FROM     sgspi.plan_tratamiento_control_referencia_normativa AS ptc
                       INNER JOIN
                       sgspi.control_referencia_normativa AS crn
                       ON crn.crn_codigo = ptc.crn_codigo
                       INNER JOIN
                       sgspi.estandar_normativo_catalogo AS enc
                       ON enc.enc_codigo = crn.enc_codigo
              WHERE    ptc.plt_codigo = pt.plt_codigo
                       AND enc.enc_familia_norma = N'ISO27001' -- [AP-13]
                       AND ptc.ptc_estado = 1 -- [AP-22]
              ORDER BY crn.crn_codigo
              FOR XML PATH (N''), TYPE).value(N'.', N'NVARCHAR(MAX)'), 1, 2, N'') AS crn_controles_iso27001,
       STUFF((SELECT   N' | ' + CASE WHEN crn.crn_rol_privacidad_pii IS NOT NULL THEN crn.crn_rol_privacidad_pii + N': ' ELSE N'' END + crn.crn_identificador_control
              FROM     sgspi.plan_tratamiento_control_referencia_normativa AS ptc
                       INNER JOIN
                       sgspi.control_referencia_normativa AS crn
                       ON crn.crn_codigo = ptc.crn_codigo
                       INNER JOIN
                       sgspi.estandar_normativo_catalogo AS enc
                       ON enc.enc_codigo = crn.enc_codigo
              WHERE    ptc.plt_codigo = pt.plt_codigo
                       AND enc.enc_familia_norma = N'ISO27701' -- [AP-13]
                       AND ptc.ptc_estado = 1 -- [AP-22]
              ORDER BY crn.crn_codigo
              FOR XML PATH (N''), TYPE).value(N'.', N'NVARCHAR(MAX)'), 1, 3, N'') AS crn_controles_iso27701,
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
       eia.eia_fase_registro
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
WHERE  eia.eia_estado = 1 -- [AP-22]
       AND pt.plt_estado = 1;


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- 6.4 Vista de Desglose Jerárquico del Cuadro de Clasificación Documental CCD/TRD (ES-GSPI-MR-04: Resolución Jerárquica N-Niveles con HIERARCHYID)
CREATE OR ALTER VIEW sgspi.vw_desglose_ccd_trd_mr04
AS
WITH   cte_jerarquia_ccd
AS     (SELECT u.upc_codigo,
               u.upc_nodo_jerarquico,
               u.upc_nivel_jerarquico,
               u.upc_prefijo_archivistico,
               u.upc_nombre_unidad,
               raiz.upc_prefijo_archivistico AS upc_cod_seccion_raiz,
               raiz.upc_nombre_unidad AS upc_nombre_seccion_raiz,
               STUFF((SELECT   N' > ' + anc.upc_prefijo_archivistico
                      FROM     sgspi.unidad_productora_cuadro_clasificacion_documental AS anc
                      WHERE    u.upc_nodo_jerarquico.IsDescendantOf(anc.upc_nodo_jerarquico) = 1
                               AND anc.upc_estado = 1
                      ORDER BY anc.upc_nodo_jerarquico
                      FOR XML PATH (N''), TYPE).value(N'.', N'NVARCHAR(MAX)'), 1, 3, N'') AS upc_ruta_prefijos_ccd,
               STUFF((SELECT   N' > ' + anc.upc_nombre_unidad
                      FROM     sgspi.unidad_productora_cuadro_clasificacion_documental AS anc
                      WHERE    u.upc_nodo_jerarquico.IsDescendantOf(anc.upc_nodo_jerarquico) = 1
                               AND anc.upc_estado = 1
                      ORDER BY anc.upc_nodo_jerarquico
                      FOR XML PATH (N''), TYPE).value(N'.', N'NVARCHAR(MAX)'), 1, 3, N'') AS upc_ruta_jerarquica_unidad
        FROM   sgspi.unidad_productora_cuadro_clasificacion_documental AS u
               INNER JOIN
               sgspi.unidad_productora_cuadro_clasificacion_documental AS raiz
               ON raiz.upc_nodo_jerarquico = u.upc_nodo_jerarquico.GetAncestor(u.upc_nodo_jerarquico.GetLevel() - 1)
                  AND raiz.upc_estado = 1
        WHERE  u.upc_estado = 1) -- [AP-22]
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
          AND sbd.sbd_estado = 1 -- [AP-22]
WHERE  adu.adu_estado = 1
       AND ado.ado_estado = 1
       AND sdo.sdo_estado = 1; -- [AP-22]


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- 6.5 Vista Matriz Consolidada de Inventario y Clasificación de Activos Documentales (Une Subtipo [ado] con Supertipo [aci] para ES-GSPI-MR-04)
-- [C5] Consolida los 3 escaneos de [air] en una sola CTE (cte_air_agg) y los 2 escaneos de [vw_desglose_ccd_trd_mr04] en cte_trd_agg,
-- alineando filtros *_estado = 1 en catálogos y manteniendo compatibilidad 100 % con COMPATIBILITY_LEVEL = 100 (STRING_AGG sin WITHIN GROUP y FOR XML PATH).
CREATE OR ALTER VIEW sgspi.vw_inventario_activo_documental_mr04
AS
WITH cte_air_dedup
AS   (SELECT air.aci_codigo,
             air.air_tipo_responsabilidad,
             c.car_nombre,
             CASE WHEN ROW_NUMBER() OVER (PARTITION BY air.aci_codigo, air.uaa_codigo ORDER BY air.car_codigo, air.air_tipo_responsabilidad) = 1 THEN u.uaa_nombre END AS uaa_nombre_unico
      FROM   sgspi.activo_informacion_responsable AS air
             INNER JOIN
             dbo.uaa AS u
             ON u.uaa_codigo = air.uaa_codigo
             INNER JOIN
             dbo.cargo AS c
             ON c.car_codigo = air.car_codigo
      WHERE  air.air_estado = 1),
     cte_air_agg
AS   (SELECT aci_codigo,
             STRING_AGG(CAST (uaa_nombre_unico AS NVARCHAR (MAX)), N', ') AS ado_dependencias_oficinas,
             MAX(CASE WHEN air_tipo_responsabilidad = N'PROPIETARIO' THEN car_nombre END) AS ado_propietarios_activo,
             STRING_AGG(CAST (CASE WHEN air_tipo_responsabilidad = N'CUSTODIO' THEN car_nombre END AS NVARCHAR (MAX)), N', ') AS ado_custodios_activo
      FROM   cte_air_dedup
      GROUP BY aci_codigo),
     cte_trd_agg
AS   (SELECT ado_codigo,
             STRING_AGG(CAST (adu_codigo_serie_trd_calculado AS NVARCHAR (MAX)), N', ') AS ado_codigos_serie_documental_trd,
             STRING_AGG(CAST (adu_codigo_subserie_trd_calculado AS NVARCHAR (MAX)), N', ') AS ado_codigos_subserie_documental_trd
      FROM   sgspi.vw_desglose_ccd_trd_mr04
      GROUP BY ado_codigo)
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
       STUFF((SELECT   N', ' + pr.pri_nombre
              FROM     sgspi.activo_informacion_proceso_institucional AS aip
                       INNER JOIN
                       sgspi.proceso_institucional AS pr
                       ON pr.pri_codigo = aip.pri_codigo
                          AND pr.pri_estado = 1 -- [AP-22] [C5]
              WHERE    aip.aci_codigo = aci.aci_codigo
                       AND aip.aip_estado = 1 -- [AP-22]
              ORDER BY pr.pri_codigo
              FOR XML PATH (N''), TYPE).value(N'.', N'NVARCHAR(MAX)'), 1, 2, N'') AS ado_procesos_asociados,
       air.ado_dependencias_oficinas,
       tac.tac_nombre AS ado_tipo_activo_documental,
       -- [AP-08] derivado del tipo de activo del supertipo
       air.ado_propietarios_activo,
       air.ado_custodios_activo,
       pdc.pdc_nombre AS ado_periodicidad_generacion,
       STUFF((SELECT   N'/' + src.src_nombre
              FROM     sgspi.activo_documental_soporte_registro AS ads
                       INNER JOIN
                       sgspi.soporte_registro_catalogo AS src
                       ON src.src_codigo = ads.src_codigo
                          AND src.src_estado = 1 -- [AP-22] [C5]
              WHERE    ads.ado_codigo = ado.ado_codigo
                       AND ads.ads_estado = 1 -- [AP-22]
              ORDER BY src.src_nombre DESC
              FOR XML PATH (N''), TYPE).value(N'.', N'NVARCHAR(MAX)'), 1, 1, N'') AS ado_soporte_registro,
       STUFF((SELECT   N'/' + mcc.mcc_nombre
              FROM     sgspi.activo_documental_medio_conservacion AS adm
                       INNER JOIN
                       sgspi.medio_conservacion_catalogo AS mcc
                       ON mcc.mcc_codigo = adm.mcc_codigo
                          AND mcc.mcc_estado = 1 -- [AP-22] [C5]
              WHERE    adm.ado_codigo = ado.ado_codigo
                       AND adm.adm_estado = 1 -- [AP-22]
              ORDER BY mcc.mcc_nombre DESC
              FOR XML PATH (N''), TYPE).value(N'.', N'NVARCHAR(MAX)'), 1, 1, N'') AS ado_medio_conservacion,
       -- [AP-08] El formato documental ahora es multivaluado normalizado ([adf] + [fac])
       STUFF((SELECT   N'/' + fac.fac_nombre
              FROM     sgspi.activo_documental_formato_archivo AS adf
                       INNER JOIN
                       sgspi.formato_archivo_catalogo AS fac
                       ON fac.fac_codigo = adf.fac_codigo
                          AND fac.fac_estado = 1 -- [AP-22] [C5]
              WHERE    adf.ado_codigo = ado.ado_codigo
                       AND adf.adf_estado = 1 -- [AP-22]
              ORDER BY fac.fac_nombre
              FOR XML PATH (N''), TYPE).value(N'.', N'NVARCHAR(MAX)'), 1, 1, N'') AS ado_formato_documental,
       STUFF((SELECT   N'/' + idi.idi_nombre
              FROM     sgspi.activo_documental_idioma AS adi
                       INNER JOIN
                       sgspi.idioma_catalogo AS idi
                       ON idi.idi_codigo = adi.idi_codigo
                          AND idi.idi_estado = 1 -- [AP-22] [C5]
              WHERE    adi.ado_codigo = ado.ado_codigo
                       AND adi.adi_estado = 1 -- [AP-22]
              ORDER BY idi.idi_nombre
              FOR XML PATH (N''), TYPE).value(N'.', N'NVARCHAR(MAX)'), 1, 1, N'') AS ado_idioma,
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
       epc.epc_nombre AS ado_fase_publicacion,
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
       aci.aci_fase_registro AS ado_fase_registro
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
       cte_air_agg AS air
       ON air.aci_codigo = aci.aci_codigo
       LEFT OUTER JOIN
       cte_trd_agg AS trd
       ON trd.ado_codigo = ado.ado_codigo
       LEFT OUTER JOIN
       sgspi.subserie_documental_catalogo AS sbd
       ON sbd.sdo_codigo = ado.sdo_codigo
          AND sbd.sbd_codigo = ado.sbd_codigo
          AND sbd.sbd_estado = 1 -- [AP-22] [C5]
       LEFT OUTER JOIN
       sgspi.causal_excepcion_transparencia AS cet
       ON cet.cet_codigo = aci.cet_codigo
          AND cet.cet_estado = 1 -- [AP-22] [C5]
WHERE  ado.ado_estado = 1 -- [AP-22]
       AND aci.aci_estado = 1
       AND sdo.sdo_estado = 1; -- [AP-22] [C5]


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- 6.6 Vista de Atributos de Controles ISO/IEC 27002:2022 (reemplaza las tablas cps/ccc y las columnas de texto de [crn]) [AP-07]
CREATE OR ALTER VIEW sgspi.vw_controles_atributos_iso27002
AS
SELECT crn.crn_codigo,
       enc.enc_identificador,
       crn.crn_identificador_control,
       crn.crn_nombre_control,
       STUFF((SELECT   N', ' + aac.aac_valor
              FROM     sgspi.control_referencia_normativa_atributo AS cra
                       INNER JOIN
                       sgspi.atributo_control_catalogo AS aac
                       ON aac.aac_codigo = cra.aac_codigo
                          AND aac.aac_estado = 1 -- [AP-22]
              WHERE    cra.crn_codigo = crn.crn_codigo
                       AND cra.cra_estado = 1 -- [AP-22]
                       AND aac.aac_tipo_atributo = N'TIPO_CONTROL'
              ORDER BY aac.aac_valor
              FOR XML PATH (N''), TYPE).value(N'.', N'NVARCHAR(MAX)'), 1, 2, N'') AS tipo_control,
       STUFF((SELECT   N', ' + aac.aac_valor
              FROM     sgspi.control_referencia_normativa_atributo AS cra
                       INNER JOIN
                       sgspi.atributo_control_catalogo AS aac
                       ON aac.aac_codigo = cra.aac_codigo
                          AND aac.aac_estado = 1 -- [AP-22]
              WHERE    cra.crn_codigo = crn.crn_codigo
                       AND cra.cra_estado = 1 -- [AP-22]
                       AND aac.aac_tipo_atributo = N'PROPIEDAD_SEGURIDAD'
              ORDER BY aac.aac_valor
              FOR XML PATH (N''), TYPE).value(N'.', N'NVARCHAR(MAX)'), 1, 2, N'') AS propiedades_seguridad,
       STUFF((SELECT   N', ' + aac.aac_valor
              FROM     sgspi.control_referencia_normativa_atributo AS cra
                       INNER JOIN
                       sgspi.atributo_control_catalogo AS aac
                       ON aac.aac_codigo = cra.aac_codigo
                          AND aac.aac_estado = 1 -- [AP-22]
              WHERE    cra.crn_codigo = crn.crn_codigo
                       AND cra.cra_estado = 1 -- [AP-22]
                       AND aac.aac_tipo_atributo = N'CONCEPTO_CIBERSEGURIDAD'
              ORDER BY aac.aac_valor
              FOR XML PATH (N''), TYPE).value(N'.', N'NVARCHAR(MAX)'), 1, 2, N'') AS conceptos_ciberseguridad,
       STUFF((SELECT   N', ' + aac.aac_valor
              FROM     sgspi.control_referencia_normativa_atributo AS cra
                       INNER JOIN
                       sgspi.atributo_control_catalogo AS aac
                       ON aac.aac_codigo = cra.aac_codigo
                          AND aac.aac_estado = 1 -- [AP-22]
              WHERE    cra.crn_codigo = crn.crn_codigo
                       AND cra.cra_estado = 1 -- [AP-22]
                       AND aac.aac_tipo_atributo = N'CAPACIDAD_OPERACIONAL'
              ORDER BY aac.aac_valor
              FOR XML PATH (N''), TYPE).value(N'.', N'NVARCHAR(MAX)'), 1, 2, N'') AS capacidades_operacionales,
       STUFF((SELECT   N', ' + aac.aac_valor
              FROM     sgspi.control_referencia_normativa_atributo AS cra
                       INNER JOIN
                       sgspi.atributo_control_catalogo AS aac
                       ON aac.aac_codigo = cra.aac_codigo
                          AND aac.aac_estado = 1 -- [AP-22]
              WHERE    cra.crn_codigo = crn.crn_codigo
                       AND cra.cra_estado = 1 -- [AP-22]
                       AND aac.aac_tipo_atributo = N'DOMINIO_SEGURIDAD'
              ORDER BY aac.aac_valor
              FOR XML PATH (N''), TYPE).value(N'.', N'NVARCHAR(MAX)'), 1, 2, N'') AS dominios_seguridad
FROM   sgspi.control_referencia_normativa AS crn
       INNER JOIN
       sgspi.estandar_normativo_catalogo AS enc
       ON enc.enc_codigo = crn.enc_codigo
WHERE  crn.crn_estado = 1
       AND enc.enc_estado = 1; -- [AP-22]


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- 6.7 [A4] Vistas públicas restringidas para sgspi_rol_consulta (solo registros VIGENTE, sin borradores ni columnas PII/ICC/reserva interna)
CREATE OR ALTER VIEW sgspi.vw_consulta_dofa_vigente
AS
SELECT acf_codigo,
       pev_vigencia,
       tpr_tipo_proceso,
       pri_proceso,
       fec_variable_entorno,
       fec_ambito_entorno,
       acf_naturaleza_factor,
       acf_numero_factor,
       acf_identificador_factor,
       acf_descripcion_situacion,
       acf_valor_prioridad,
       acf_nivel_prioridad,
       acf_impacto_sistema_gestion,
       acf_accion_propuesta,
       acf_fase_registro
FROM   sgspi.vw_consolidado_dofa
WHERE  acf_fase_registro = N'VIGENTE';


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
CREATE OR ALTER VIEW sgspi.vw_consulta_inventario_documental_vigente
AS
SELECT ado_codigo,
       aci_codigo,
       aci_codigo_inventario,
       pev_vigencia,
       ado_codigos_serie_documental_trd,
       ado_codigos_subserie_documental_trd,
       sdo_nombre_serie,
       sbd_nombre_subserie,
       ado_nombre_activo,
       ado_descripcion,
       ado_procesos_asociados,
       ado_dependencias_oficinas,
       ado_tipo_activo_documental,
       ado_propietarios_activo,
       ado_custodios_activo,
       ado_periodicidad_generacion,
       ado_soporte_registro,
       ado_medio_conservacion,
       ado_formato_documental,
       ado_idioma,
       ado_fecha_ingreso_tabla_retencion,
       ado_fecha_ingreso_archivo,
       ado_nivel_confidencialidad,
       ado_nivel_integridad,
       ado_nivel_disponibilidad,
       ado_nivel_criticidad,
       ado_fase_publicacion,
       ado_lugar_consulta_ubicacion,
       ado_contiene_datos_personales,
       ado_objeto_legitimo_excepcion,
       ado_fecha_clasificacion_reserva,
       ado_tiempo_clasificacion_reserva,
       ado_fase_registro
FROM   sgspi.vw_inventario_activo_documental_mr04
WHERE  ado_fase_registro = N'VIGENTE';


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- Lectura de las vistas de reporte para sgspi_rol_base (RLS filtra las filas según alcance del actor)
GRANT SELECT
    ON sgspi.vw_consolidado_dofa TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.vw_resumen_activos_criticidad TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.vw_matriz_tratamiento_riesgos TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.vw_desglose_ccd_trd_mr04 TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.vw_inventario_activo_documental_mr04 TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.vw_controles_atributos_iso27002 TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.vw_consulta_dofa_vigente TO sgspi_rol_base;

GRANT SELECT
    ON sgspi.vw_consulta_inventario_documental_vigente TO sgspi_rol_base;

-- D8 / A4: la cuenta compartida solo lee vistas públicas vigentes sin borradores ni PII/ICC/reserva interna (encadenamiento de propiedad con dbo).
GRANT SELECT
    ON sgspi.vw_consulta_dofa_vigente TO sgspi_rol_consulta;

GRANT SELECT
    ON sgspi.vw_resumen_activos_criticidad TO sgspi_rol_consulta;

GRANT SELECT
    ON sgspi.vw_consulta_inventario_documental_vigente TO sgspi_rol_consulta;

GRANT SELECT
    ON sgspi.vw_controles_atributos_iso27002 TO sgspi_rol_consulta;


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
-- [E1] Lote final breve de FKs hacia [dbo] con LOCK_TIMEOUT 5000 (minimiza retención de bloqueos Sch-M sobre dbo.persona/uaa/cargo/espacio/sub_sede a milisegundos)
SET LOCK_TIMEOUT 5000;

ALTER TABLE sgspi.proceso_institucional
    WITH CHECK ADD CONSTRAINT FK_pri_dbo_uaa_lider FOREIGN KEY (uaa_codigo_lider) REFERENCES dbo.uaa (uaa_codigo);

ALTER TABLE sgspi.proceso_institucional
    WITH CHECK ADD CONSTRAINT FK_pri_dbo_cargo_lider FOREIGN KEY (car_codigo_lider) REFERENCES dbo.cargo (car_codigo);

ALTER TABLE sgspi.proceso_institucional_uaa
    WITH CHECK ADD CONSTRAINT FK_piu_dbo_uaa FOREIGN KEY (uaa_codigo) REFERENCES dbo.uaa (uaa_codigo);

ALTER TABLE sgspi.analisis_contexto_factor
    WITH CHECK ADD CONSTRAINT FK_acf_dbo_persona_creador FOREIGN KEY (per_codigo_creador) REFERENCES dbo.persona (per_codigo);

ALTER TABLE sgspi.analisis_contexto_factor
    WITH CHECK ADD CONSTRAINT FK_acf_dbo_persona_aprobador FOREIGN KEY (per_codigo_aprobador) REFERENCES dbo.persona (per_codigo);

ALTER TABLE sgspi.requisito_parte_interesada
    WITH CHECK ADD CONSTRAINT FK_rpi_dbo_persona_creador FOREIGN KEY (per_codigo_creador) REFERENCES dbo.persona (per_codigo);

ALTER TABLE sgspi.requisito_parte_interesada
    WITH CHECK ADD CONSTRAINT FK_rpi_dbo_persona_aprobador FOREIGN KEY (per_codigo_aprobador) REFERENCES dbo.persona (per_codigo);

ALTER TABLE sgspi.activo_informacion
    WITH CHECK ADD CONSTRAINT FK_aci_dbo_uaa FOREIGN KEY (uaa_codigo) REFERENCES dbo.uaa (uaa_codigo);

ALTER TABLE sgspi.activo_informacion
    WITH CHECK ADD CONSTRAINT FK_aci_dbo_espacio FOREIGN KEY (esp_codigo) REFERENCES dbo.espacio (esp_codigo);

ALTER TABLE sgspi.activo_informacion
    WITH CHECK ADD CONSTRAINT FK_aci_dbo_persona_creador FOREIGN KEY (per_codigo_creador) REFERENCES dbo.persona (per_codigo);

ALTER TABLE sgspi.activo_informacion
    WITH CHECK ADD CONSTRAINT FK_aci_dbo_persona_aprobador FOREIGN KEY (per_codigo_aprobador) REFERENCES dbo.persona (per_codigo);

ALTER TABLE sgspi.activo_informacion
    WITH CHECK ADD CONSTRAINT FK_aci_dbo_persona_revisor_archivo FOREIGN KEY (per_codigo_revisor_archivo) REFERENCES dbo.persona (per_codigo);

ALTER TABLE sgspi.activo_informacion_sede
    WITH CHECK ADD CONSTRAINT FK_ais_dbo_sub_sede FOREIGN KEY (sus_codigo) REFERENCES dbo.sub_sede (sus_codigo);

ALTER TABLE sgspi.activo_informacion_responsable
    WITH CHECK ADD CONSTRAINT FK_air_dbo_cargo FOREIGN KEY (car_codigo) REFERENCES dbo.cargo (car_codigo);

ALTER TABLE sgspi.activo_informacion_responsable
    WITH CHECK ADD CONSTRAINT FK_air_dbo_uaa FOREIGN KEY (uaa_codigo) REFERENCES dbo.uaa (uaa_codigo);

ALTER TABLE sgspi.unidad_productora_cuadro_clasificacion_documental
    WITH CHECK ADD CONSTRAINT FK_upc_dbo_uaa FOREIGN KEY (uaa_codigo) REFERENCES dbo.uaa (uaa_codigo);

ALTER TABLE sgspi.evento_incertidumbre_activo
    WITH CHECK ADD CONSTRAINT FK_eia_dbo_persona_creador FOREIGN KEY (per_codigo_creador) REFERENCES dbo.persona (per_codigo);

ALTER TABLE sgspi.evento_incertidumbre_activo
    WITH CHECK ADD CONSTRAINT FK_eia_dbo_persona_validador FOREIGN KEY (per_codigo_validador_lider) REFERENCES dbo.persona (per_codigo);

ALTER TABLE sgspi.evento_incertidumbre_activo
    WITH CHECK ADD CONSTRAINT FK_eia_dbo_persona_revisor FOREIGN KEY (per_codigo_revisor_sgspi) REFERENCES dbo.persona (per_codigo);

ALTER TABLE sgspi.evento_incertidumbre_activo
    WITH CHECK ADD CONSTRAINT FK_eia_dbo_persona_comite FOREIGN KEY (per_codigo_aprobador_comite) REFERENCES dbo.persona (per_codigo);

ALTER TABLE sgspi.plan_tratamiento
    WITH CHECK ADD CONSTRAINT FK_plt_dbo_persona_evaluador FOREIGN KEY (per_codigo_evaluador) REFERENCES dbo.persona (per_codigo);

ALTER TABLE sgspi.actividad_tratamiento
    WITH CHECK ADD CONSTRAINT FK_act_dbo_cargo FOREIGN KEY (car_codigo) REFERENCES dbo.cargo (car_codigo);

ALTER TABLE sgspi.actividad_tratamiento
    WITH CHECK ADD CONSTRAINT FK_act_dbo_uaa FOREIGN KEY (uaa_codigo) REFERENCES dbo.uaa (uaa_codigo);

ALTER TABLE sgspi.seguimiento_actividad
    WITH CHECK ADD CONSTRAINT FK_sga_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo);

ALTER TABLE sgspi.evaluacion_aplicabilidad_control
    WITH CHECK ADD CONSTRAINT FK_eac_dbo_cargo FOREIGN KEY (car_codigo) REFERENCES dbo.cargo (car_codigo);

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
       WHERE  t.schema_id = SCHEMA_ID(N'sgspi')) <> 99
   OR (SELECT COUNT(*)
       FROM   sys.views
       WHERE  schema_id = SCHEMA_ID(N'sgspi')) <> 10
   OR (SELECT COUNT(*)
       FROM   sys.objects
       WHERE  schema_id = SCHEMA_ID(N'sgspi')
              AND type = N'IF') <> 6
   OR OBJECT_ID(N'sgspi.usp_siguiente_consecutivo', N'P') IS NULL
   OR NOT EXISTS (SELECT 1
                  FROM   sys.security_policies AS sp
                  WHERE  sp.schema_id = SCHEMA_ID(N'sgspi')
                         AND sp.name = N'spol_alcance_lectura'
                         AND sp.is_enabled = 1
                         AND (SELECT COUNT(*)
                              FROM   sys.security_predicates AS pr
                              WHERE  pr.object_id = sp.object_id) = 40)
   OR (SELECT COUNT(*)
       FROM   sys.foreign_keys
       WHERE  schema_id = SCHEMA_ID(N'sgspi')
              AND OBJECT_SCHEMA_NAME(referenced_object_id) = N'dbo') <> 25
   OR (SELECT COUNT(*)
       FROM   sys.foreign_keys
       WHERE  schema_id = SCHEMA_ID(N'sgspi')
              AND referenced_object_id = OBJECT_ID(N'dbo.persona')) <> 13
    SET @fallos += N' Conteo de objetos incompleto (esperado: 98 tablas, 99 triggers, 10 vistas, 6 funciones, 1 SP usp_siguiente_consecutivo, política RLS spol_alcance_lectura activa con 40 predicados, 25 FKs a [dbo] con 13 a dbo.persona).';

DECLARE @objetos_faltantes AS NVARCHAR (1000) = LEFT((SELECT STRING_AGG(CAST (v.nombre AS NVARCHAR (MAX)), N', ')
                                                      FROM   (VALUES (N'sgspi.estado_flujo_catalogo', N'U'), (N'sgspi.transicion_estado_flujo', N'U'), (N'sgspi.analisis_contexto_factor', N'U'), (N'sgspi.requisito_parte_interesada', N'U'), (N'sgspi.activo_informacion', N'U'), (N'sgspi.activo_documental', N'U'), (N'sgspi.evento_incertidumbre_activo', N'U'), (N'sgspi.plan_tratamiento', N'U'), (N'sgspi.actividad_tratamiento', N'U'), (N'sgspi.seguimiento_actividad', N'U'), (N'sgspi.evaluacion_aplicabilidad_control', N'U'), (N'sgspi.ufn_persona_sesion', N'IF'), (N'sgspi.ufn_proceso_en_alcance', N'IF'), (N'sgspi.ufn_activo_en_alcance', N'IF'), (N'sgspi.ufn_rls_alcance_proceso', N'IF'), (N'sgspi.ufn_rls_alcance_activo', N'IF'), (N'sgspi.ufn_rls_alcance_aip', N'IF'), (N'sgspi.usp_siguiente_consecutivo', N'P'), (N'sgspi.vw_usuario_rol_alcance_sgspi', N'V'), (N'sgspi.vw_sgspi_admin_login', N'V'), (N'sgspi.vw_consolidado_dofa', N'V'), (N'sgspi.vw_resumen_activos_criticidad', N'V'), (N'sgspi.vw_matriz_tratamiento_riesgos', N'V'), (N'sgspi.vw_desglose_ccd_trd_mr04', N'V'), (N'sgspi.vw_inventario_activo_documental_mr04', N'V'), (N'sgspi.vw_controles_atributos_iso27002', N'V'), (N'sgspi.vw_consulta_dofa_vigente', N'V'), (N'sgspi.vw_consulta_inventario_documental_vigente', N'V'), (N'sgspi.TR_acf_integridad_y_actualizacion', N'TR'), (N'sgspi.TR_rpi_integridad_y_actualizacion', N'TR'), (N'sgspi.TR_aci_integridad_y_actualizacion', N'TR'), (N'sgspi.TR_ado_integridad_y_actualizacion', N'TR'), (N'sgspi.TR_eia_integridad_y_actualizacion', N'TR'), (N'sgspi.TR_plt_integridad_y_actualizacion', N'TR'), (N'sgspi.TR_act_integridad_y_actualizacion', N'TR'), (N'sgspi.TR_eac_integridad_y_actualizacion', N'TR'), (N'sgspi.TR_sga_inmutabilidad', N'TR'), (N'sgspi.TR_sga_sincronizar_avance', N'TR')) AS v(nombre, tipo)
                                                      WHERE  OBJECT_ID(v.nombre, v.tipo) IS NULL), 1000);

IF @objetos_faltantes IS NOT NULL
    SET @fallos += N' Faltan objetos clave: ' + @objetos_faltantes + N'.';

DECLARE @roles_faltantes AS NVARCHAR (500) = (SELECT STRING_AGG(v.rol, N', ')
                                              FROM   (VALUES (N'sgspi_rol_base'), (N'sgspi_rol_custodio_operador'), (N'sgspi_rol_lider_propietario'), (N'sgspi_rol_gestor_documental'), (N'sgspi_rol_oficial_seguridad_privacidad'), (N'sgspi_rol_comite_direccion'), (N'sgspi_rol_auditor_control'), (N'sgspi_rol_consulta'), (N'sgspi_rol_login')) AS v(rol)
                                              WHERE  DATABASE_PRINCIPAL_ID(v.rol) IS NULL);

IF @roles_faltantes IS NOT NULL
    SET @fallos += N' Faltan roles: ' + @roles_faltantes + N'.';

DECLARE @aud_rotas AS NVARCHAR (1000) = LEFT((SELECT STRING_AGG(CAST (t.name AS NVARCHAR (MAX)), N', ')
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
        ROLLBACK;
        RAISERROR (N'DESPLIEGUE SGSPI REVERTIDO SIN CAMBIOS:%s', 16, 1, @fallos);
        SET NOEXEC ON;
    END
ELSE
    BEGIN TRY
        EXECUTE sys.sp_refreshview N'sgspi.vw_usuario_rol_alcance_sgspi';
        EXECUTE sys.sp_refreshview N'sgspi.vw_sgspi_admin_login';
        EXECUTE sys.sp_refreshview N'sgspi.vw_consolidado_dofa';
        EXECUTE sys.sp_refreshview N'sgspi.vw_resumen_activos_criticidad';
        EXECUTE sys.sp_refreshview N'sgspi.vw_matriz_tratamiento_riesgos';
        EXECUTE sys.sp_refreshview N'sgspi.vw_desglose_ccd_trd_mr04';
        EXECUTE sys.sp_refreshview N'sgspi.vw_inventario_activo_documental_mr04';
        EXECUTE sys.sp_refreshview N'sgspi.vw_controles_atributos_iso27002';
        EXECUTE sys.sp_refreshview N'sgspi.vw_consulta_dofa_vigente';
        EXECUTE sys.sp_refreshview N'sgspi.vw_consulta_inventario_documental_vigente';
    END TRY
    BEGIN CATCH
        DECLARE @err_vista AS NVARCHAR (1500) = ERROR_MESSAGE();
        IF @@TRANCOUNT > 0
            ROLLBACK;
        RAISERROR (N'DESPLIEGUE SGSPI REVERTIDO SIN CAMBIOS: error al compilar vista (%s).', 16, 1, @err_vista);
        SET NOEXEC ON;
    END CATCH


GO
IF @@TRANCOUNT = 0
    SET NOEXEC ON; -- [AP-19]


GO
COMMIT TRANSACTION; -- [AP-19]

SET LOCK_TIMEOUT -1; -- [E1] restablece timeout por defecto tras aplicar FKs a [dbo]


GO
/*==================================================================================================
7. VERIFICACIÓN POSTERIOR AL DESPLIEGUE (SOLO LECTURA)
Lista desalineaciones entre [dbo].[usuario_grupo]/[dbo].[usuario_administrativos]/[dbo].[usuario_docentes] y los roles de BD del SGSPI. Compara el
login del usuario de BD (SUSER_SNAME de su sid), que es lo que los triggers buscan con ORIGINAL_LOGIN() en la columna [sys]:
(a) miembros de grupos SGSPI_* (por gru_id) sin cuenta SQL ([sys] NULL), sin usuario de BD o sin el rol equivalente; (b) usuarios de BD en un rol de actor cuyo
login no está en [sys] de usuario_administrativos/usuario_docentes; (c) usuarios de BD en más de un rol SGSPI (incluyendo sgspi_rol_consulta y sgspi_rol_login);
(d) usuarios de un rol SGSPI que también son miembros directos de db_owner, db_datareader, db_datawriter, db_ddladmin o db_securityadmin, que anulan los GRANT;
(e) logins de un rol de actor con varias personas en usuario_administrativos/usuario_docentes (ufn_persona_sesion falla en cerrado con error 50017 [C2]);
(f) base sin TDE (sys.databases.is_encrypted = 0); (g) base sin RCSI; (h) compatibility_level < 150 (nota informativa);
(i) tablas de [dbo] sin índice en las columnas de búsqueda del SGSPI (usuario_administrativos.sys, usuario_docentes.sys, usuario_grupo.usg_usuario).
==================================================================================================*/
WITH     cte_usuarios_sgspi
AS       (SELECT uid,
                 up,
                 us,
                 sys,
                 state
          FROM   dbo.usuario_administrativos
          UNION ALL
          SELECT uid,
                 up,
                 us,
                 sys,
                 state
          FROM   dbo.usuario_docentes),
         cte_mapa_roles
AS       (SELECT v.gru_id,
                 v.rol_bd
          FROM   (VALUES (N'SGSPI_CUSTODIO_OPERADOR', N'sgspi_rol_custodio_operador'), (N'SGSPI_LIDER_PROPIETARIO', N'sgspi_rol_lider_propietario'), (N'SGSPI_GESTOR_DOCUMENTAL', N'sgspi_rol_gestor_documental'), (N'SGSPI_ADMIN_OPDP', N'sgspi_rol_oficial_seguridad_privacidad'), (N'SGSPI_COMITE_DIRECCION', N'sgspi_rol_comite_direccion'), (N'SGSPI_AUDITOR_CONTROL', N'sgspi_rol_auditor_control')) AS v(gru_id, rol_bd)),
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
                            FROM   cte_mapa_roles)),
         cte_membresia_sgspi
AS       (SELECT usuario_id,
                 usuario_bd,
                 rol_bd
          FROM   cte_membresia_bd
          UNION ALL
          SELECT m.principal_id,
                 m.name,
                 r.name
          FROM   sys.database_role_members AS rm
                 INNER JOIN
                 sys.database_principals AS r
                 ON r.principal_id = rm.role_principal_id
                 INNER JOIN
                 sys.database_principals AS m
                 ON m.principal_id = rm.member_principal_id
          WHERE  r.name IN (N'sgspi_rol_consulta', N'sgspi_rol_login'))
SELECT   DISTINCT N'Grupo SGSPI_* sin cuenta SQL (sys), sin usuario de BD o sin su rol equivalente' AS hallazgo,
                  ISNULL(u.sys, u.us) AS usuario,
                  g.gru_id AS detalle
FROM     dbo.usuario_grupo AS ug
         INNER JOIN
         dbo.grupo AS g
         ON g.gru_codigo = ug.usg_grupo
         INNER JOIN
         cte_usuarios_sgspi AS u
         ON u.uid = ug.usg_usuario
         LEFT OUTER JOIN
         cte_mapa_roles AS mr
         ON mr.gru_id = g.gru_id
WHERE    ug.usg_estado = 1
         AND g.gru_estado = 1
         AND u.state = 1
         AND u.up IS NOT NULL
         AND g.gru_id LIKE 'SGSPI[_]%'
         AND (u.sys IS NULL
              OR NOT EXISTS (SELECT 1
                             FROM   cte_membresia_bd AS mb
                             WHERE  mb.login_bd = u.sys
                                    AND mb.rol_bd = mr.rol_bd))
UNION ALL
SELECT   DISTINCT N'Usuario de BD en rol de actor cuyo login no está en usuario_administrativos/usuario_docentes.sys' AS hallazgo,
                  mb.usuario_bd AS usuario,
                  mb.rol_bd AS detalle
FROM     cte_membresia_bd AS mb
WHERE    NOT EXISTS (SELECT 1
                     FROM   cte_usuarios_sgspi AS u
                     WHERE  u.sys = mb.login_bd
                            AND u.sys IS NOT NULL
                            AND u.state = 1
                            AND u.up IS NOT NULL)
UNION ALL
SELECT   N'Usuario de BD en más de un rol SGSPI' AS hallazgo,
         ms.usuario_bd AS usuario,
         STUFF((SELECT   N', ' + ms2.rol_bd
                FROM     cte_membresia_sgspi AS ms2
                WHERE    ms2.usuario_bd = ms.usuario_bd
                ORDER BY ms2.rol_bd
                FOR XML PATH (N''), TYPE).value(N'.', N'NVARCHAR(MAX)'), 1, 2, N'') AS detalle
FROM     cte_membresia_sgspi AS ms
GROUP BY ms.usuario_bd
HAVING   COUNT(*) > 1
UNION ALL
SELECT   DISTINCT N'Usuario de rol SGSPI en un rol fijo que anula los GRANT' AS hallazgo,
                  ms.usuario_bd AS usuario,
                  f.name AS detalle
FROM     cte_membresia_sgspi AS ms
         INNER JOIN
         sys.database_role_members AS frm
         ON frm.member_principal_id = ms.usuario_id
         INNER JOIN
         sys.database_principals AS f
         ON f.principal_id = frm.role_principal_id
WHERE    f.name IN (N'db_owner', N'db_datareader', N'db_datawriter', N'db_ddladmin', N'db_securityadmin')
UNION ALL
SELECT   N'Login de rol de actor con varias personas en usuario_administrativos/usuario_docentes' AS hallazgo,
         u.sys AS usuario,
         STUFF((SELECT   N', ' + CONVERT (NVARCHAR (20), x.up)
                FROM     (SELECT DISTINCT u2.up
                          FROM   cte_usuarios_sgspi AS u2
                          WHERE  u2.sys = u.sys
                                 AND u2.state = 1
                                 AND u2.up IS NOT NULL) AS x
                ORDER BY x.up
                FOR XML PATH (N''), TYPE).value(N'.', N'NVARCHAR(MAX)'), 1, 2, N'') AS detalle
FROM     cte_usuarios_sgspi AS u
WHERE    u.sys IN (SELECT mb.login_bd
                   FROM   cte_membresia_bd AS mb)
         AND u.sys IS NOT NULL
         AND u.state = 1
         AND u.up IS NOT NULL
GROUP BY u.sys
HAVING   COUNT(DISTINCT u.up) > 1
UNION ALL
SELECT   N'Base sin TDE' AS hallazgo,
         DB_NAME() AS usuario,
         N'sys.databases.is_encrypted = 0' AS detalle
FROM     sys.databases
WHERE    database_id = DB_ID()
         AND is_encrypted = 0
UNION ALL
SELECT   N'Base sin RCSI (ejecutar ALTER DATABASE ... SET READ_COMMITTED_SNAPSHOT ON en ventana de mantenimiento)' AS hallazgo,
         DB_NAME() AS usuario,
         N'sys.databases.is_read_committed_snapshot_on = 0' AS detalle
FROM     sys.databases
WHERE    database_id = DB_ID()
         AND is_read_committed_snapshot_on = 0
UNION ALL
SELECT   N'Nivel de compatibilidad heredado (informativo: DDL v2.3 opera en nivel >= 100 sobre SQL Server 2019+)' AS hallazgo,
         DB_NAME() AS usuario,
         CONCAT(N'sys.databases.compatibility_level = ', compatibility_level) AS detalle
FROM     sys.databases
WHERE    database_id = DB_ID()
         AND compatibility_level < 150
UNION ALL
SELECT   N'Tabla de [dbo] sin índice en la columna de búsqueda del SGSPI' AS hallazgo,
         v.tabla AS usuario,
         v.columna AS detalle
FROM     (VALUES (N'dbo.usuario_administrativos', N'sys'), (N'dbo.usuario_docentes', N'sys'), (N'dbo.usuario_grupo', N'usg_usuario')) AS v(tabla, columna)
WHERE    OBJECTPROPERTY(OBJECT_ID(v.tabla), N'IsUserTable') = 1
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