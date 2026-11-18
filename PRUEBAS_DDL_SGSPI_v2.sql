SET NOCOUNT ON;

SET XACT_ABORT OFF;


GO
CREATE TABLE #resultado (
    n        INT            IDENTITY,
    prueba   NVARCHAR (200),
    esperado NVARCHAR (60) ,
    obtenido NVARCHAR (400),
    ok       BIT           
);


GO
CREATE PROCEDURE #espera
@nombre NVARCHAR (200), @sql NVARCHAR (MAX), @error INT -- @error = 0 => debe funcionar
AS
BEGIN
    DECLARE @obt AS INT = 0, @msg AS NVARCHAR (400) = N'OK';
    BEGIN TRY
        EXECUTE sys.sp_executesql @sql;
    END TRY
    BEGIN CATCH
        SELECT @obt = ERROR_NUMBER(),
               @msg = CONCAT(ERROR_NUMBER(), N': ', LEFT(ERROR_MESSAGE(), 330));
        IF XACT_STATE() <> 0
            ROLLBACK;
    END CATCH
    INSERT  #resultado (
        prueba,
        esperado,
        obtenido,
        ok
    )
    VALUES             (@nombre, CASE WHEN @error = 0 THEN N'OK' ELSE CONCAT(N'error ', @error) END, @msg, IIF (@obt = @error, 1, 0));
END


GO
-- [AP-03] Los triggers toman la persona de ORIGINAL_LOGIN() en dbo.usuario_general (us = login, up = per_codigo).
-- La base desechable mapea el login de quien prueba a la persona 2; #sesion_como la cambia para que la persona 1
-- cree los registros y la persona 2 los apruebe sin violar la segregación de funciones.
CREATE PROCEDURE #sesion_como
@per_codigo INT
AS
BEGIN
    UPDATE dbo.usuario_general
    SET    up = @per_codigo
    WHERE  us = ORIGINAL_LOGIN();
END


GO
EXECUTE #espera N'AP-22 toda tabla (salvo las aud_*) tiene columna de borrado lógico BIT NOT NULL DEFAULT 1', N'
IF EXISTS (SELECT 1 FROM sys.tables AS t
           WHERE  t.schema_id = SCHEMA_ID(N''sgspi'')
                  AND t.name NOT LIKE N''aud[_]%''
                  AND NOT EXISTS (SELECT 1 FROM sys.columns AS c
                                  INNER JOIN sys.default_constraints AS dc ON dc.object_id = c.default_object_id
                                  WHERE c.object_id = t.object_id
                                        AND c.name LIKE N''%[_]esta[_]activ[oa]''
                                        AND c.is_nullable = 0
                                        AND c.system_type_id = 104 -- BIT
                                        AND dc.definition = N''((1))''))
    THROW 51000, N''hay tablas sin <acr>_esta_activo'', 1;', 0;

-- Cada tabla aud_* tiene: su código, las columnas no calculadas del origen salvo <acr>_fecha_creacion, per_codigo,
-- usuario_bd y fecha_cambio. Si se agrega una columna a una tabla y no a su auditoría, esta prueba falla.
EXECUTE #espera N'AP-01 cada tabla tiene su auditoría con las mismas columnas', N'
IF EXISTS (SELECT 1 FROM sys.tables AS t
           WHERE  t.schema_id = SCHEMA_ID(N''sgspi'')
                  AND t.name NOT LIKE N''aud[_]%''
                  AND (OBJECT_ID(N''sgspi.aud_'' + t.name) IS NULL
                       OR (SELECT COUNT(*) FROM sys.columns AS c WHERE c.object_id = OBJECT_ID(N''sgspi.aud_'' + t.name))
                          <> 4 + (SELECT COUNT(*) FROM sys.columns AS c
                                  WHERE c.object_id = t.object_id AND c.is_computed = 0 AND c.name NOT LIKE N''%[_]fecha[_]creacion'')))
    THROW 51000, N''hay tablas sin auditoría o con columnas distintas'', 1;', 0;

-- [AP-02] D5: el alcance sale de dbo.usuario_grupo (grupos SGSPI_*) y de proceso_institucional_uaa. El login de prueba
-- queda en un grupo SGSPI en la UAA 1, que más abajo se liga al proceso 1.
EXECUTE #espera N'D5 alcance de prueba: el login de prueba pertenece a un grupo SGSPI en la UAA 1', N'
INSERT dbo.grupo (gru_nombre) VALUES (N''SGSPI_PRUEBA_ALCANCE'');
DECLARE @gru INT = SCOPE_IDENTITY();
INSERT dbo.usuario_grupo (usg_usuario, usg_grupo, usg_uaa)
SELECT TOP (1) u.uid, @gru, 1 FROM dbo.usuario_general AS u WHERE u.us = ORIGINAL_LOGIN() ORDER BY u.uid;', 0;

-- ======================= 1. Flujo de estados (ACF) =======================
EXECUTE #sesion_como 1; -- crea la persona 1

EXECUTE #espera N'Datos maestros', N'
INSERT sgspi.periodo_vigencia (pev_anio, pev_fecha_apertura) VALUES (2026, ''2026-01-01'');
INSERT sgspi.tipo_proceso_catalogo (tpr_identificador, tpr_nombre) VALUES (N''EST'', N''ESTRATÉGICO'');
INSERT sgspi.proceso_institucional (pri_identificador, pri_nombre, tpr_codigo, uaa_codigo_lider) VALUES (N''P01'', N''Direccionamiento'', 1, 1);
INSERT sgspi.proceso_institucional_uaa (pri_codigo, uaa_codigo) VALUES (1, 1);
INSERT sgspi.factor_entorno_catalogo (fec_nombre_factor, fec_ambito_entorno) VALUES (N''Tecnológico'', N''INTERNO'');', 0;

EXECUTE #espera N'AP-14 pri_identificador duplicado', N'INSERT sgspi.proceso_institucional (pri_identificador, pri_nombre, tpr_codigo) VALUES (N''P01'', N''Otro'', 1);', 2627;

EXECUTE #espera N'AP-04 INSERT directo en VIGENTE', N'INSERT sgspi.analisis_contexto_factor (pev_codigo, pri_codigo, fec_codigo, acf_naturaleza_factor, acf_numero_factor, acf_descripcion_situacion, acf_estado_registro, per_codigo_creador, per_codigo_aprobador) VALUES (1,1,1,N''DEBILIDAD'',1,N''x'',N''VIGENTE'',1,2);', 50014;

EXECUTE #espera N'AP-05 estado inexistente en catálogo', N'INSERT sgspi.analisis_contexto_factor (pev_codigo, pri_codigo, fec_codigo, acf_naturaleza_factor, acf_numero_factor, acf_descripcion_situacion, acf_estado_registro, per_codigo_creador) VALUES (1,1,1,N''DEBILIDAD'',1,N''x'',N''APROBADISIMO'',1);', 547;

EXECUTE #espera N'INSERT acf en BORRADOR', N'INSERT sgspi.analisis_contexto_factor (pev_codigo, pri_codigo, fec_codigo, acf_naturaleza_factor, acf_numero_factor, acf_descripcion_situacion, per_codigo_creador, acf_valor_prioridad) VALUES (1,1,1,N''DEBILIDAD'',1,N''Obsolescencia'',1,3);', 0;

EXECUTE #espera N'AP-05 transición no permitida BORRADOR->VIGENTE', N'UPDATE sgspi.analisis_contexto_factor SET acf_estado_registro = N''VIGENTE'', per_codigo_aprobador = 2, acf_impacto_sistema_gestion = N''i'', acf_accion_propuesta = N''a'' WHERE acf_numero_factor = 1;', 50011;

EXECUTE #espera N'Transición BORRADOR->EN_VALIDACION_LIDER', N'UPDATE sgspi.analisis_contexto_factor SET acf_estado_registro = N''EN_VALIDACION_LIDER'', acf_impacto_sistema_gestion = N''i'', acf_accion_propuesta = N''a'' WHERE acf_numero_factor = 1;', 0;

EXECUTE #espera N'Transición EN_VALIDACION_LIDER->EN_REVISION_SGSPI', N'UPDATE sgspi.analisis_contexto_factor SET acf_estado_registro = N''EN_REVISION_SGSPI'' WHERE acf_numero_factor = 1;', 0;

EXECUTE #sesion_como 2; -- aprueba la persona 2

EXECUTE #espera N'AP-15 la firma de aprobación la pone el trigger, no el cliente', N'
UPDATE sgspi.analisis_contexto_factor SET acf_estado_registro = N''VIGENTE'', per_codigo_aprobador = 3 WHERE acf_numero_factor = 1;
IF (SELECT per_codigo_aprobador FROM sgspi.analisis_contexto_factor WHERE acf_numero_factor = 1) <> 2 THROW 51000, N''la firma no es la persona del login'', 1;', 0;

EXECUTE #espera N'AP-15 quien aprueba (persona del login) = creador', N'
INSERT sgspi.analisis_contexto_factor (pev_codigo, pri_codigo, fec_codigo, acf_naturaleza_factor, acf_numero_factor, acf_descripcion_situacion, per_codigo_creador) VALUES (1,1,1,N''DEBILIDAD'',2,N''Autoaprobación'',2);
UPDATE sgspi.analisis_contexto_factor SET acf_estado_registro = N''EN_VALIDACION_LIDER'' WHERE acf_numero_factor = 2;
UPDATE sgspi.analisis_contexto_factor SET acf_estado_registro = N''EN_REVISION_SGSPI'' WHERE acf_numero_factor = 2;
UPDATE sgspi.analisis_contexto_factor SET acf_estado_registro = N''VIGENTE'' WHERE acf_numero_factor = 2;', 547;

EXECUTE #espera N'AP-15 el creador debe ser la persona de la sesión (acf)', N'INSERT sgspi.analisis_contexto_factor (pev_codigo, pri_codigo, fec_codigo, acf_naturaleza_factor, acf_numero_factor, acf_descripcion_situacion, per_codigo_creador) VALUES (1,1,1,N''DEBILIDAD'',3,N''Suplantación'',1);', 50019;

-- El factor D1 cambió tres veces (a EN_VALIDACION_LIDER, a EN_REVISION_SGSPI y a VIGENTE); los UPDATE internos del trigger no cuentan
EXECUTE #espera N'AP-01 la auditoría guarda una versión por UPDATE, con quién lo hizo', N'
DECLARE @acf INT = (SELECT acf_codigo FROM sgspi.analisis_contexto_factor WHERE acf_numero_factor = 1);
IF (SELECT COUNT(*) FROM sgspi.aud_analisis_contexto_factor WHERE acf_codigo = @acf) <> 3
   OR NOT EXISTS (SELECT 1 FROM sgspi.aud_analisis_contexto_factor
                  WHERE acf_codigo = @acf AND aaf_estado_registro = N''EN_REVISION_SGSPI'' AND per_codigo = 2)
    THROW 51000, N''la auditoría no tiene las tres versiones anteriores o no registra a quien aprobó'', 1;', 0;

EXECUTE #espera N'AP-05 editar VIGENTE sin cambiar estado', N'UPDATE sgspi.analisis_contexto_factor SET acf_descripcion_situacion = N''cambio'' WHERE acf_numero_factor = 1;', 50011;

EXECUTE #espera N'Borrado físico bloqueado', N'DELETE sgspi.analisis_contexto_factor WHERE acf_numero_factor = 1;', 50010;


GO
-- ======================= 2. RPI (nuevo creador/aprobador, ya no nace VIGENTE) =======================
EXECUTE #sesion_como 1;

EXECUTE #espera N'AP-04 rpi nace en BORRADOR por defecto', N'
INSERT sgspi.parte_interesada (pai_nombre, pai_origen) VALUES (N''Estudiantes'', N''INTERNA'');
INSERT sgspi.requisito_parte_interesada (pev_codigo, pai_codigo, rpi_necesidad_expectativa, per_codigo_creador) VALUES (1,1,N''Privacidad'',1);
IF (SELECT rpi_estado_registro FROM sgspi.requisito_parte_interesada WHERE rpi_codigo = 1) <> N''BORRADOR'' THROW 51000, N''no nació en BORRADOR'', 1;', 0;

EXECUTE #espera N'AP-15 el creador debe ser la persona de la sesión (rpi)', N'INSERT sgspi.requisito_parte_interesada (pev_codigo, pai_codigo, rpi_necesidad_expectativa, per_codigo_creador) VALUES (1,1,N''Suplantación'',2);', 50019;


GO
-- ======================= 3. Activos: taxonomía, transparencia, subtipo documental =======================
EXECUTE #espera N'Taxonomía tac 3 niveles', N'
INSERT sgspi.tipo_activo_catalogo (tac_codigo_padre, tac_nivel_taxonomia, tac_nombre) VALUES (NULL,1,N''Información'');
INSERT sgspi.tipo_activo_catalogo (tac_codigo_padre, tac_nivel_taxonomia, tac_nombre) VALUES (1,2,N''Documento'');
INSERT sgspi.tipo_activo_catalogo (tac_codigo_padre, tac_nivel_taxonomia, tac_nombre) VALUES (2,3,N''Acta'');
INSERT sgspi.tipo_activo_catalogo (tac_codigo_padre, tac_nivel_taxonomia, tac_nombre) VALUES (NULL,1,N''Software'');', 0;

EXECUTE #espera N'AP-06 subtipo (nivel 3) colgado de una categoría (nivel 1)', N'INSERT sgspi.tipo_activo_catalogo (tac_codigo_padre, tac_nivel_taxonomia, tac_nombre) VALUES (1,3,N''Salto'');', 547;

EXECUTE #espera N'Causales de excepción', N'
INSERT sgspi.causal_excepcion_transparencia (cet_nivel_reserva_aplicable, cet_numeral_causal, cet_descripcion_causal) VALUES (N''CLASIFICADA'', N''a'', N''Intimidad'');
INSERT sgspi.causal_excepcion_transparencia (cet_nivel_reserva_aplicable, cet_numeral_causal, cet_descripcion_causal) VALUES (N''RESERVADA'', N''a'', N''Defensa'');', 0;

EXECUTE #espera N'AP-14 causal duplicada (nivel+numeral)', N'INSERT sgspi.causal_excepcion_transparencia (cet_nivel_reserva_aplicable, cet_numeral_causal, cet_descripcion_causal) VALUES (N''RESERVADA'', N''a'', N''Dup'');', 2627;

EXECUTE #espera N'Activo público en BORRADOR', N'INSERT sgspi.activo_informacion (aci_codigo_inventario, aci_nombre_activo, tac_codigo, aci_clasificacion_transparencia, aci_valor_confidencialidad, aci_valor_integridad, aci_valor_disponibilidad, per_codigo_creador) VALUES (N''INV-1'', N''Actas Consejo'', 3, N''PUBLICA'', 1, 2, 2, 1);', 0;

EXECUTE #espera N'Activo de soporte (de la UAA 1, en el alcance del login de prueba)', N'INSERT sgspi.activo_informacion (aci_codigo_inventario, aci_nombre_activo, tac_codigo, uaa_codigo, aci_clasificacion_transparencia, aci_valor_confidencialidad, aci_valor_integridad, aci_valor_disponibilidad, per_codigo_creador) VALUES (N''INV-2'', N''Servidor de archivos'', 4, 1, N''PUBLICA'', 1, 2, 3, 1);', 0;

EXECUTE #espera N'D4 el activo INV-1 se asocia al proceso 1 antes de registrar sus riesgos', N'INSERT sgspi.activo_informacion_proceso_institucional (aci_codigo, pri_codigo) VALUES (1, 1);', 0;

EXECUTE #espera N'AP-13 valor antiguo con tilde rechazado', N'INSERT sgspi.activo_informacion (aci_codigo_inventario, aci_nombre_activo, tac_codigo, aci_clasificacion_transparencia, aci_valor_confidencialidad, aci_valor_integridad, aci_valor_disponibilidad, per_codigo_creador) VALUES (N''INV-3'', N''x'', 3, N''PÚBLICA'', 1, 1, 1, 1);', 547;

EXECUTE #espera N'AP-06 activo RESERVADO con causal de nivel CLASIFICADA', N'INSERT sgspi.activo_informacion (aci_codigo_inventario, aci_nombre_activo, tac_codigo, aci_clasificacion_transparencia, cet_codigo, aci_valor_confidencialidad, aci_valor_integridad, aci_valor_disponibilidad, per_codigo_creador) VALUES (N''INV-4'', N''x'', 3, N''RESERVADA'', 1, 3, 1, 1, 1);', 547;

EXECUTE #espera N'AP-15 el creador debe ser la persona de la sesión (aci)', N'INSERT sgspi.activo_informacion (aci_codigo_inventario, aci_nombre_activo, tac_codigo, aci_clasificacion_transparencia, aci_valor_confidencialidad, aci_valor_integridad, aci_valor_disponibilidad, per_codigo_creador) VALUES (N''INV-S'', N''x'', 3, N''PUBLICA'', 1, 1, 1, 2);', 50019;

EXECUTE #espera N'AP-23 activo RESERVADO a 15 años', N'INSERT sgspi.activo_informacion (aci_codigo_inventario, aci_nombre_activo, tac_codigo, aci_clasificacion_transparencia, cet_codigo, aci_es_reserva_indefinida, aci_anios_plazo_reserva, aci_valor_confidencialidad, aci_valor_integridad, aci_valor_disponibilidad, per_codigo_creador) VALUES (N''INV-6'', N''Expedientes de defensa'', 3, N''RESERVADA'', 2, 0, 15, 3, 1, 1, 1);', 0;

EXECUTE #espera N'AP-23 activo RESERVADO con reserva indefinida', N'INSERT sgspi.activo_informacion (aci_codigo_inventario, aci_nombre_activo, tac_codigo, aci_clasificacion_transparencia, cet_codigo, aci_es_reserva_indefinida, aci_valor_confidencialidad, aci_valor_integridad, aci_valor_disponibilidad, per_codigo_creador) VALUES (N''INV-7'', N''x'', 3, N''RESERVADA'', 2, 1, 3, 1, 1, 1);', 547;

EXECUTE #espera N'AP-23 activo RESERVADO a más de 15 años', N'INSERT sgspi.activo_informacion (aci_codigo_inventario, aci_nombre_activo, tac_codigo, aci_clasificacion_transparencia, cet_codigo, aci_es_reserva_indefinida, aci_anios_plazo_reserva, aci_valor_confidencialidad, aci_valor_integridad, aci_valor_disponibilidad, per_codigo_creador) VALUES (N''INV-8'', N''x'', 3, N''RESERVADA'', 2, 0, 16, 3, 1, 1, 1);', 547;

EXECUTE #espera N'Catálogos documentales', N'
INSERT sgspi.serie_documental_catalogo (sdo_numero_ccd, sdo_nombre_serie, sdo_tiene_subseries) VALUES (2, N''ACTAS'', 1);
INSERT sgspi.subserie_documental_catalogo (sdo_codigo, sbd_numero_ccd, sbd_nombre_subserie) VALUES (1, 1, N''Actas de Consejo Superior'');
INSERT sgspi.periodicidad_catalogo (pdc_nombre) VALUES (N''Mensual'');
INSERT sgspi.estado_publicacion_catalogo (epc_nombre) VALUES (N''No publicada'');
INSERT sgspi.formato_archivo_catalogo (fac_nombre) VALUES (N''PDF''), (N''Documento de texto'');
INSERT sgspi.soporte_registro_catalogo (src_nombre) VALUES (N''Digital'');', 0;

EXECUTE #espera N'AP-06 serie con subseries sin subserie', N'INSERT sgspi.activo_documental (ado_codigo, pev_codigo, sdo_codigo, pdc_codigo, epc_codigo, ado_lugar_consulta_ubicacion) VALUES (1, 1, 1, 1, 1, N''Archivo central'');', 50015;

EXECUTE #espera N'AP-10 activo documental con PK compartida', N'
INSERT sgspi.activo_documental (ado_codigo, pev_codigo, sdo_codigo, sbd_codigo, pdc_codigo, epc_codigo, ado_lugar_consulta_ubicacion) VALUES (1, 1, 1, 1, 1, 1, N''Archivo central'');
INSERT sgspi.activo_documental_formato_archivo (ado_codigo, fac_codigo) VALUES (1,1),(1,2);
INSERT sgspi.activo_documental_soporte_registro (ado_codigo, src_codigo) VALUES (1,1);', 0;

EXECUTE #espera N'AP-10 subtipo sin supertipo', N'INSERT sgspi.activo_documental (ado_codigo, pev_codigo, sdo_codigo, sbd_codigo, pdc_codigo, epc_codigo, ado_lugar_consulta_ubicacion) VALUES (99, 1, 1, 1, 1, 1, N''x'');', 547;


GO
-- ======================= 4. Riesgos, plan, actividades, seguimiento =======================
EXECUTE #espera N'Escalas y matriz 5x5 (una celda)', N'
INSERT sgspi.escala_probabilidad (epr_codigo, epr_codigo_letra, epr_nombre_nivel, epr_descripcion_criterio, epr_frecuencia_referencia) VALUES (5, ''A'', N''Casi seguro'', N''d'', N''f''), (1, ''E'', N''Raro'', N''d'', N''f'');
INSERT sgspi.escala_impacto (eim_codigo, eim_nombre_impacto_negativo, eim_nombre_impacto_positivo, eim_descripcion_organizacional) VALUES (5, N''Catastrófico'', N''Altamente beneficioso'', N''d''), (1, N''Insignificante'', N''Leve'', N''d'');
INSERT sgspi.matriz_valoracion_riesgo (epr_codigo, eim_codigo, zrc_codigo, mvr_directriz_tratamiento_riesgo, mvr_directriz_tratamiento_oportunidad, mvr_requiere_aprobacion_comite) VALUES (5,5,''E'',N''Tratar'',N''Explotar'',1), (1,1,''B'',N''Aceptar'',N''Monitorear'',0);
IF (SELECT mvr_codigo_posicion FROM sgspi.matriz_valoracion_riesgo WHERE epr_codigo = 5 AND eim_codigo = 5) <> ''A5'' THROW 51000, N''posición mal calculada'', 1;', 0;

EXECUTE #espera N'AP-09 letra de probabilidad incoherente (3 = A)', N'INSERT sgspi.escala_probabilidad (epr_codigo, epr_codigo_letra, epr_nombre_nivel, epr_descripcion_criterio, epr_frecuencia_referencia) VALUES (3, ''B'', N''x'', N''d'', N''f'');', 547;

EXECUTE #espera N'Estrategias de tratamiento', N'INSERT sgspi.estrategia_tratamiento_catalogo (etc_nombre_estrategia, etc_naturaleza_aplicable) VALUES (N''Mitigar'', N''RIESGO''), (N''Explotar'', N''OPORTUNIDAD'');', 0;

EXECUTE #espera N'AP-06 componente afectado que no es categoría nivel 1', N'INSERT sgspi.evento_incertidumbre_activo (pev_codigo, eia_identificador_evento, eia_naturaleza_evento, pri_codigo, aci_codigo_primario, aci_codigo_soporte, tac_codigo_componente, eia_fuente_generadora, eia_condicion_vulnerabilidad, eia_efecto_consecuencia, eia_escenario_operacional, epr_codigo_inherente, eim_codigo_inherente, per_codigo_creador) VALUES (1, N''RA-01'', N''RIESGO'', 1, 1, 2, 2, N''f'', N''v'', N''e'', N''s'', 5, 5, 1);', 547;

EXECUTE #espera N'AP-06 identificador RA-ABC rechazado', N'INSERT sgspi.evento_incertidumbre_activo (pev_codigo, eia_identificador_evento, eia_naturaleza_evento, pri_codigo, aci_codigo_primario, aci_codigo_soporte, tac_codigo_componente, eia_fuente_generadora, eia_condicion_vulnerabilidad, eia_efecto_consecuencia, eia_escenario_operacional, epr_codigo_inherente, eim_codigo_inherente, per_codigo_creador) VALUES (1, N''RA-ABC'', N''RIESGO'', 1, 1, 2, 1, N''f'', N''v'', N''e'', N''s'', 5, 5, 1);', 547;

EXECUTE #espera N'Evento de riesgo RA-01 en BORRADOR', N'INSERT sgspi.evento_incertidumbre_activo (pev_codigo, eia_identificador_evento, eia_naturaleza_evento, pri_codigo, aci_codigo_primario, aci_codigo_soporte, tac_codigo_componente, eia_fuente_generadora, eia_condicion_vulnerabilidad, eia_efecto_consecuencia, eia_escenario_operacional, epr_codigo_inherente, eim_codigo_inherente, per_codigo_creador) VALUES (1, N''RA-01'', N''RIESGO'', 1, 1, 2, 1, N''f'', N''v'', N''e'', N''Fuga de actas'', 5, 5, 1);', 0;

EXECUTE #espera N'AP-15 el creador debe ser la persona de la sesión (eia)', N'INSERT sgspi.evento_incertidumbre_activo (pev_codigo, eia_identificador_evento, eia_naturaleza_evento, pri_codigo, aci_codigo_primario, aci_codigo_soporte, tac_codigo_componente, eia_fuente_generadora, eia_condicion_vulnerabilidad, eia_efecto_consecuencia, eia_escenario_operacional, epr_codigo_inherente, eim_codigo_inherente, per_codigo_creador) VALUES (1, N''RA-09'', N''RIESGO'', 1, 1, 2, 1, N''f'', N''v'', N''e'', N''Suplantación'', 5, 5, 2);', 50019;

EXECUTE #espera N'D4 riesgo en un proceso al que no pertenece su activo primario', N'INSERT sgspi.evento_incertidumbre_activo (pev_codigo, eia_identificador_evento, eia_naturaleza_evento, pri_codigo, aci_codigo_primario, aci_codigo_soporte, tac_codigo_componente, eia_fuente_generadora, eia_condicion_vulnerabilidad, eia_efecto_consecuencia, eia_escenario_operacional, epr_codigo_inherente, eim_codigo_inherente, per_codigo_creador) VALUES (1, N''RA-08'', N''RIESGO'', 1, 2, 1, 1, N''f'', N''v'', N''e'', N''Proceso ajeno al activo'', 5, 5, 1);', 547;

EXECUTE #espera N'AP-15 validador líder = creador', N'UPDATE sgspi.evento_incertidumbre_activo SET eia_estado_registro = N''EN_VALIDACION_LIDER'', per_codigo_validador_lider = 1 WHERE eia_identificador_evento = N''RA-01'';', 547;

EXECUTE #espera N'AP-06 estrategia de OPORTUNIDAD sobre evento de RIESGO', N'INSERT sgspi.plan_tratamiento (eia_codigo, plt_naturaleza_evento, etc_codigo, plt_justificacion_estrategia, epr_codigo_residual_meta, eim_codigo_residual_meta, plt_fecha_inicio, plt_fecha_fin, plt_recursos_humanos_tecnicos, plt_recursos_economicos_desc, plt_nombre_indicador_kpi, plt_meta_indicador_kpi) VALUES ((SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01''), N''RIESGO'', 2, N''j'', 1, 1, ''2026-01-01'', ''2026-12-31'', N''r'', N''r'', N''k'', 100);', 547;

EXECUTE #espera N'AP-06 plan declarando naturaleza distinta a la del evento', N'INSERT sgspi.plan_tratamiento (eia_codigo, plt_naturaleza_evento, etc_codigo, plt_justificacion_estrategia, epr_codigo_residual_meta, eim_codigo_residual_meta, plt_fecha_inicio, plt_fecha_fin, plt_recursos_humanos_tecnicos, plt_recursos_economicos_desc, plt_nombre_indicador_kpi, plt_meta_indicador_kpi) VALUES ((SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01''), N''OPORTUNIDAD'', 2, N''j'', 1, 1, ''2026-01-01'', ''2026-12-31'', N''r'', N''r'', N''k'', 100);', 547;

EXECUTE #espera N'Plan de tratamiento coherente', N'INSERT sgspi.plan_tratamiento (eia_codigo, plt_naturaleza_evento, etc_codigo, plt_justificacion_estrategia, epr_codigo_residual_meta, eim_codigo_residual_meta, plt_fecha_inicio, plt_fecha_fin, plt_recursos_humanos_tecnicos, plt_recursos_economicos_desc, plt_nombre_indicador_kpi, plt_meta_indicador_kpi) VALUES ((SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01''), N''RIESGO'', 1, N''j'', 1, 1, ''2026-01-01'', ''2026-12-31'', N''r'', N''r'', N''k'', 100);', 0;

EXECUTE #espera N'AP-16 eficacia sin dictamen ni evaluador', N'UPDATE sgspi.plan_tratamiento SET plt_es_tratamiento_eficaz = 1 WHERE eia_codigo = (SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01'');', 547;

EXECUTE #espera N'AP-16 KPI 500 veces la meta ya no desborda', N'UPDATE sgspi.plan_tratamiento SET plt_meta_indicador_kpi = 0.01, plt_valor_alcanzado_kpi = 5 WHERE eia_codigo = (SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01''); DECLARE @p DECIMAL(9,2) = (SELECT plt_porcentaje_cumplimiento_kpi FROM sgspi.plan_tratamiento WHERE eia_codigo = (SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01''));', 0;

EXECUTE #espera N'Actividad en PENDIENTE', N'INSERT sgspi.actividad_tratamiento (plt_codigo, act_numero_orden, act_descripcion_actividad, act_fecha_compromiso) VALUES ((SELECT plt_codigo FROM sgspi.plan_tratamiento WHERE eia_codigo = (SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01'')), 1, N''Cifrar repositorio'', ''2026-06-30'');', 0;

EXECUTE #espera N'AP-14 número de orden duplicado en el plan', N'INSERT sgspi.actividad_tratamiento (plt_codigo, act_numero_orden, act_descripcion_actividad, act_fecha_compromiso) VALUES ((SELECT plt_codigo FROM sgspi.plan_tratamiento WHERE eia_codigo = (SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01'')), 1, N''Dup'', ''2026-06-30'');', 2627;

EXECUTE #espera N'AP-16 evidencia incompleta (nombre sin hash)', N'INSERT sgspi.seguimiento_actividad (act_codigo, per_codigo, sga_porcentaje_reportado, sga_descripcion_avance, sga_nombre_archivo_evidencia) VALUES ((SELECT act_codigo FROM sgspi.actividad_tratamiento WHERE act_numero_orden = 1), 1, 40, N''Avance'', N''acta.pdf'');', 547;

EXECUTE #espera N'AP-09 seguimiento sincroniza el avance de la actividad', N'
INSERT sgspi.seguimiento_actividad (act_codigo, per_codigo, sga_porcentaje_reportado, sga_descripcion_avance) VALUES ((SELECT act_codigo FROM sgspi.actividad_tratamiento WHERE act_numero_orden = 1), 1, 40, N''Avance parcial'');
IF (SELECT act_porcentaje_avance FROM sgspi.actividad_tratamiento WHERE act_codigo = 1) <> 40 THROW 51000, N''avance no sincronizado'', 1;', 0;

EXECUTE #espera N'AP-15 el seguimiento lo registra la persona de la sesión', N'INSERT sgspi.seguimiento_actividad (act_codigo, per_codigo, sga_porcentaje_reportado, sga_descripcion_avance) VALUES ((SELECT act_codigo FROM sgspi.actividad_tratamiento WHERE act_numero_orden = 1), 2, 50, N''Avance ajeno'');', 50019;

EXECUTE #espera N'AP-16 seguimiento es append-only', N'UPDATE sgspi.seguimiento_actividad SET sga_porcentaje_reportado = 90 WHERE sga_porcentaje_reportado = 40;', 50016;

EXECUTE #espera N'AP-22 seguimiento no se borra físicamente', N'DELETE sgspi.seguimiento_actividad WHERE sga_porcentaje_reportado = 40;', 50016;

EXECUTE #espera N'AP-22 seguimiento admite borrado lógico', N'UPDATE sgspi.seguimiento_actividad SET sga_esta_activo = 0 WHERE sga_porcentaje_reportado = 40; UPDATE sgspi.seguimiento_actividad SET sga_esta_activo = 1 WHERE sga_porcentaje_reportado = 40;', 0;

EXECUTE #espera N'AP-16 completar sin llegar a 100%', N'UPDATE sgspi.actividad_tratamiento SET act_estado_actividad = N''EN_CURSO'' WHERE act_codigo = 1; UPDATE sgspi.actividad_tratamiento SET act_estado_actividad = N''COMPLETADA'' WHERE act_codigo = 1;', 547;


GO
-- ======================= 5. Controles ISO 27002 y SoA =======================
EXECUTE #espera N'AP-07 control con atributos normalizados', N'
INSERT sgspi.estandar_normativo_catalogo (enc_identificador, enc_familia_norma, enc_nombre) VALUES (N''ISO/IEC 27001:2022'', N''ISO27001'', N''SGSI'');
INSERT sgspi.control_referencia_normativa (enc_codigo, crn_identificador_control, crn_nombre_control, crn_objetivo_requisito) VALUES (1, N''A.8.24'', N''Uso de criptografía'', N''o'');
INSERT sgspi.atributo_control_catalogo (aac_tipo_atributo, aac_valor) VALUES (N''TIPO_CONTROL'', N''Preventivo''), (N''PROPIEDAD_SEGURIDAD'', N''Confidencialidad''), (N''PROPIEDAD_SEGURIDAD'', N''Integridad''), (N''DOMINIO_SEGURIDAD'', N''Protección'');
INSERT sgspi.control_referencia_normativa_atributo (crn_codigo, aac_codigo) VALUES (1,1),(1,2),(1,3),(1,4);
INSERT sgspi.plan_tratamiento_control_referencia_normativa (plt_codigo, crn_codigo) VALUES ((SELECT plt_codigo FROM sgspi.plan_tratamiento WHERE eia_codigo = (SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01'')),1);', 0;

EXECUTE #espera N'AP-13 dos ediciones activas de la misma familia', N'INSERT sgspi.estandar_normativo_catalogo (enc_identificador, enc_familia_norma, enc_nombre) VALUES (N''ISO/IEC 27001:2013'', N''ISO27001'', N''SGSI viejo'');', 2601;

EXECUTE #espera N'SoA aplicable', N'INSERT sgspi.evaluacion_aplicabilidad_control (pev_codigo, crn_codigo, eac_frecuencia_revision, eac_estado_implementacion) VALUES (1, 1, N''Anual'', N''CUMPLE_PARCIAL'');', 0;

EXECUTE #espera N'AP-11 el trigger mantiene eac_fecha_actualizacion', N'UPDATE sgspi.evaluacion_aplicabilidad_control SET eac_fecha_actualizacion = ''2000-01-01T00:00:00+00:00'' WHERE eac_codigo = 1; UPDATE sgspi.evaluacion_aplicabilidad_control SET eac_observaciones_auditoria = N''obs'' WHERE eac_codigo = 1; IF (SELECT YEAR(eac_fecha_actualizacion) FROM sgspi.evaluacion_aplicabilidad_control WHERE eac_codigo = 1) = 2000 THROW 51000, N''fecha de actualización no mantenida'', 1;', 0;


GO
-- ======================= 6. Vistas =======================
EXECUTE #espera N'Vista vw_usuario_rol_alcance_sgspi', N'SELECT * INTO #v1 FROM sgspi.vw_usuario_rol_alcance_sgspi;', 0;

EXECUTE #espera N'Vista vw_consolidado_dofa', N'SELECT * INTO #v2 FROM sgspi.vw_consolidado_dofa;', 0;

EXECUTE #espera N'Vista vw_resumen_activos_criticidad', N'SELECT * INTO #v3 FROM sgspi.vw_resumen_activos_criticidad;', 0;

EXECUTE #espera N'Vista vw_matriz_tratamiento_riesgos (ISO27001 por familia)', N'IF (SELECT crn_controles_iso27001 FROM sgspi.vw_matriz_tratamiento_riesgos) <> N''A.8.24'' THROW 51000, N''control no proyectado'', 1;', 0;

EXECUTE #espera N'Vista vw_desglose_ccd_trd_mr04', N'SELECT * INTO #v5 FROM sgspi.vw_desglose_ccd_trd_mr04;', 0;

EXECUTE #espera N'Vista vw_inventario_activo_documental_mr04 (formatos agregados)', N'IF (SELECT ado_formato_documental FROM sgspi.vw_inventario_activo_documental_mr04 WHERE ado_codigo = 1) NOT IN (N''PDF/Documento de texto'', N''Documento de texto/PDF'') THROW 51000, N''formato no agregado'', 1;', 0;

EXECUTE #espera N'Vista vw_controles_atributos_iso27002', N'SELECT * INTO #v7 FROM sgspi.vw_controles_atributos_iso27002;', 0;


GO
-- ======================= 7. Roles y permisos (AP-02) =======================
-- 229 = permiso denegado sobre el objeto; 230 = sobre la columna. EXECUTE AS se revierte solo al terminar cada lote dinámico.
CREATE USER sgspi_prueba_consulta WITHOUT LOGIN;

CREATE USER sgspi_prueba_custodio WITHOUT LOGIN;

CREATE USER sgspi_prueba_oficial WITHOUT LOGIN;

CREATE USER sgspi_prueba_auditor WITHOUT LOGIN;

CREATE USER sgspi_prueba_comite WITHOUT LOGIN;

ALTER ROLE sgspi_rol_consulta ADD MEMBER sgspi_prueba_consulta;

ALTER ROLE sgspi_rol_custodio_operador ADD MEMBER sgspi_prueba_custodio;

ALTER ROLE sgspi_rol_oficial_seguridad_privacidad ADD MEMBER sgspi_prueba_oficial;

ALTER ROLE sgspi_rol_auditor_control ADD MEMBER sgspi_prueba_auditor;

ALTER ROLE sgspi_rol_comite_direccion ADD MEMBER sgspi_prueba_comite;


GO
EXECUTE #espera N'AP-02 la vista de alcance no expone la identificación', N'IF COL_LENGTH(N''sgspi.vw_usuario_rol_alcance_sgspi'', N''per_identificacion'') IS NOT NULL THROW 51000, N''per_identificacion sigue expuesta'', 1;', 0;

EXECUTE #espera N'AP-02 la vista de alcance no expone el correo institucional', N'IF COL_LENGTH(N''sgspi.vw_usuario_rol_alcance_sgspi'', N''per_correo_institucional'') IS NOT NULL OR COL_LENGTH(N''sgspi.vw_usuario_rol_alcance_sgspi'', N''per_email_interno'') IS NOT NULL THROW 51000, N''per_correo_institucional sigue expuesto'', 1;', 0;

EXECUTE #espera N'AP-02 base lee vistas que cruzan a [dbo]', N'EXECUTE AS USER = N''sgspi_prueba_consulta''; SELECT * INTO #p1 FROM sgspi.vw_usuario_rol_alcance_sgspi;', 0;

EXECUTE #espera N'AP-02 base no escribe', N'EXECUTE AS USER = N''sgspi_prueba_consulta''; INSERT sgspi.parte_interesada (pai_nombre, pai_origen) VALUES (N''X'', N''INTERNA'');', 229;

EXECUTE #espera N'AP-02 ni el oficial escribe la máquina de estados', N'EXECUTE AS USER = N''sgspi_prueba_oficial''; INSERT sgspi.transicion_estado_flujo (efc_dominio, efc_identificador_origen, efc_identificador_destino) VALUES (N''ACF'', N''BORRADOR'', N''VIGENTE'');', 229;

EXECUTE #espera N'AP-02 el oficial sí administra catálogos', N'EXECUTE AS USER = N''sgspi_prueba_oficial''; UPDATE sgspi.parte_interesada SET pai_descripcion_rol = N''Comunidad estudiantil'' WHERE pai_codigo = 1;', 0;

EXECUTE #espera N'AP-01 un catálogo guarda su versión anterior y quién la cambió', N'IF NOT EXISTS (SELECT 1 FROM sgspi.aud_parte_interesada WHERE pai_codigo = 1 AND apa_descripcion_rol IS NULL AND per_codigo = 1) THROW 51000, N''sin versión anterior en aud_parte_interesada'', 1;', 0;

EXECUTE #espera N'AP-01 la auditoría no se edita', N'UPDATE sgspi.aud_parte_interesada SET apa_descripcion_rol = N''x'';', 50016;

EXECUTE #espera N'AP-01 la auditoría no se borra', N'DELETE sgspi.aud_parte_interesada;', 50016;

EXECUTE #espera N'AP-01 nadie inserta en la auditoría a mano', N'EXECUTE AS USER = N''sgspi_prueba_consulta''; INSERT sgspi.aud_parte_interesada (pai_codigo, apa_nombre, apa_origen, apa_esta_activa, per_codigo) VALUES (1, N''x'', N''INTERNA'', 1, 1);', 229;

EXECUTE #espera N'AP-02 custodio no escribe configuración', N'EXECUTE AS USER = N''sgspi_prueba_custodio''; UPDATE sgspi.periodo_vigencia SET pev_estado_vigencia = N''CERRADA'' WHERE 1 = 0;', 229;

EXECUTE #espera N'AP-02 custodio no escribe planes de tratamiento', N'EXECUTE AS USER = N''sgspi_prueba_custodio''; UPDATE sgspi.plan_tratamiento SET plt_justificacion_estrategia = N''x'' WHERE 1 = 0;', 229;

EXECUTE #espera N'AP-02 custodio no borra tablas con flujo', N'EXECUTE AS USER = N''sgspi_prueba_custodio''; DELETE sgspi.analisis_contexto_factor WHERE 1 = 0;', 229;

EXECUTE #espera N'AP-02 el creador es inmutable', N'EXECUTE AS USER = N''sgspi_prueba_custodio''; UPDATE sgspi.analisis_contexto_factor SET per_codigo_creador = 2 WHERE 1 = 0;', 230;

EXECUTE #espera N'AP-02 el avance no se edita a mano', N'EXECUTE AS USER = N''sgspi_prueba_custodio''; UPDATE sgspi.actividad_tratamiento SET act_porcentaje_avance = 100 WHERE act_codigo = 1;', 230;

EXECUTE #espera N'AP-02 el trigger sincroniza el avance pese al DENY de columna', N'EXECUTE AS USER = N''sgspi_prueba_custodio'';
INSERT sgspi.seguimiento_actividad (act_codigo, per_codigo, sga_porcentaje_reportado, sga_descripcion_avance) VALUES (1, 1, 60, N''Avance'');
IF (SELECT act_porcentaje_avance FROM sgspi.actividad_tratamiento WHERE act_codigo = 1) <> 60 THROW 51000, N''avance no sincronizado'', 1;', 0;

EXECUTE #espera N'AP-22 custodio asocia y desactiva procesos de un activo', N'EXECUTE AS USER = N''sgspi_prueba_custodio'';
INSERT sgspi.activo_informacion_proceso_institucional (aci_codigo, pri_codigo) VALUES (2, 1);
UPDATE sgspi.activo_informacion_proceso_institucional SET aip_esta_activo = 0 WHERE aci_codigo = 2 AND pri_codigo = 1;', 0;

EXECUTE #espera N'AP-22 custodio no borra tablas puente', N'EXECUTE AS USER = N''sgspi_prueba_custodio''; DELETE sgspi.activo_informacion_proceso_institucional WHERE 1 = 0;', 229;

EXECUTE #espera N'AP-22 custodio desactiva un seguimiento', N'EXECUTE AS USER = N''sgspi_prueba_custodio''; UPDATE sgspi.seguimiento_actividad SET sga_esta_activo = 0 WHERE sga_porcentaje_reportado = 60;', 0;

EXECUTE #espera N'AP-02 auditor registra el dictamen de eficacia; la fecha la pone el servidor', N'EXECUTE AS USER = N''sgspi_prueba_auditor''; UPDATE sgspi.plan_tratamiento SET plt_es_tratamiento_eficaz = 1, plt_dictamen_eficacia = N''Eficaz'', per_codigo_evaluador = 1, plt_fecha_evaluacion_eficacia = ''2000-01-01T00:00:00+00:00'' WHERE eia_codigo = (SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01'');
IF (SELECT YEAR(plt_fecha_evaluacion_eficacia) FROM sgspi.plan_tratamiento WHERE eia_codigo = (SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01'')) = 2000 THROW 51000, N''la fecha del dictamen no la puso el servidor'', 1;', 0;

EXECUTE #espera N'AP-15 el auditor no firma el dictamen como otra persona', N'EXECUTE AS USER = N''sgspi_prueba_auditor''; UPDATE sgspi.plan_tratamiento SET plt_dictamen_eficacia = N''Eficaz (corregido)'', per_codigo_evaluador = 2 WHERE eia_codigo = (SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01'');', 50019;

EXECUTE #espera N'D2 solo el auditor registra el dictamen de eficacia', N'EXECUTE AS USER = N''sgspi_prueba_oficial''; UPDATE sgspi.plan_tratamiento SET plt_dictamen_eficacia = N''Eficaz según el oficial'', per_codigo_evaluador = 1 WHERE eia_codigo = (SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01'');', 50011;

EXECUTE #espera N'D5 la cuenta compartida no lee las vulnerabilidades', N'EXECUTE AS USER = N''sgspi_prueba_consulta''; SELECT eia_condicion_vulnerabilidad INTO #p2 FROM sgspi.evento_incertidumbre_activo;', 230;

EXECUTE #espera N'D5 ni su copia en la auditoría', N'EXECUTE AS USER = N''sgspi_prueba_consulta''; SELECT aea_condicion_vulnerabilidad INTO #p3 FROM sgspi.aud_evento_incertidumbre_activo;', 230;

EXECUTE #espera N'D5 la cuenta compartida lee el resto del evento', N'EXECUTE AS USER = N''sgspi_prueba_consulta''; SELECT eia_identificador_evento, eia_escenario_operacional INTO #p4 FROM sgspi.evento_incertidumbre_activo;', 0;

EXECUTE #espera N'D5 el oficial sí lee las vulnerabilidades', N'EXECUTE AS USER = N''sgspi_prueba_oficial''; SELECT eia_condicion_vulnerabilidad INTO #p5 FROM sgspi.evento_incertidumbre_activo;', 0;

EXECUTE #espera N'D5 un custodio no registra DOFA en un proceso fuera de su alcance', N'
INSERT sgspi.proceso_institucional (pri_identificador, pri_nombre, tpr_codigo) VALUES (N''P03'', N''Proceso de otra UAA'', 1);
EXECUTE AS USER = N''sgspi_prueba_custodio'';
INSERT sgspi.analisis_contexto_factor (pev_codigo, pri_codigo, fec_codigo, acf_naturaleza_factor, acf_numero_factor, acf_descripcion_situacion, per_codigo_creador)
VALUES (1, (SELECT pri_codigo FROM sgspi.proceso_institucional WHERE pri_identificador = N''P03''), 1, N''DEBILIDAD'', 4, N''Fuera de alcance'', 1);', 50021;

EXECUTE #espera N'D5 un custodio no modifica un activo fuera de su alcance', N'EXECUTE AS USER = N''sgspi_prueba_custodio''; UPDATE sgspi.activo_informacion SET aci_nombre_activo = N''Cambio ajeno'' WHERE aci_codigo_inventario = N''INV-6'';', 50021;

EXECUTE #espera N'AP-02 auditor no edita el resto del plan', N'EXECUTE AS USER = N''sgspi_prueba_auditor''; UPDATE sgspi.plan_tratamiento SET plt_justificacion_estrategia = N''x'' WHERE 1 = 0;', 230;

EXECUTE #espera N'AP-02 auditor registra observaciones en el SoA', N'EXECUTE AS USER = N''sgspi_prueba_auditor''; UPDATE sgspi.evaluacion_aplicabilidad_control SET eac_observaciones_auditoria = N''Hallazgo'' WHERE eac_codigo = 1;', 0;

EXECUTE #espera N'AP-02 auditor no cambia el estado de implementación del SoA', N'EXECUTE AS USER = N''sgspi_prueba_auditor''; UPDATE sgspi.evaluacion_aplicabilidad_control SET eac_estado_implementacion = N''CUMPLE'' WHERE 1 = 0;', 230;

EXECUTE #espera N'AP-02 comité puede cambiar el estado en eia y rpi', N'EXECUTE AS USER = N''sgspi_prueba_comite''; UPDATE sgspi.evento_incertidumbre_activo SET eia_estado_registro = N''OBSERVADO'' WHERE 1 = 0; UPDATE sgspi.requisito_parte_interesada SET rpi_estado_registro = N''OBSERVADO'' WHERE 1 = 0;', 0;

EXECUTE #espera N'AP-02 comité no edita contenido de eia', N'EXECUTE AS USER = N''sgspi_prueba_comite''; UPDATE sgspi.evento_incertidumbre_activo SET eia_fuente_generadora = N''x'' WHERE 1 = 0;', 230;

EXECUTE #espera N'AP-02 comité no escribe firma directa en eia', N'EXECUTE AS USER = N''sgspi_prueba_comite''; UPDATE sgspi.evento_incertidumbre_activo SET per_codigo_aprobador_comite = 2 WHERE 1 = 0;', 230;

EXECUTE #espera N'AP-02 comité no edita contenido de rpi', N'EXECUTE AS USER = N''sgspi_prueba_comite''; UPDATE sgspi.requisito_parte_interesada SET rpi_necesidad_expectativa = N''x'' WHERE 1 = 0;', 230;

EXECUTE #espera N'AP-02 comité no escribe firma directa en rpi', N'EXECUTE AS USER = N''sgspi_prueba_comite''; UPDATE sgspi.requisito_parte_interesada SET per_codigo_aprobador = 2 WHERE 1 = 0;', 230;

-- 1.1 Rol por transición (tef_rol_requerido)
EXECUTE #espera N'AP-02 solo los estados de captura quedan sin rol requerido', N'IF EXISTS (SELECT 1 FROM sgspi.transicion_estado_flujo WHERE tef_rol_requerido IS NULL AND efc_identificador_origen NOT IN (N''BORRADOR'', N''OBSERVADO'', N''PENDIENTE'', N''OBSERVADA'')) THROW 51000, N''transición sin rol'', 1;', 0;

EXECUTE #espera N'AP-02 la aceptación del comité exige el rol del comité', N'IF EXISTS (SELECT 1 FROM sgspi.transicion_estado_flujo WHERE efc_identificador_origen = N''EN_ACEPTACION_COMITE'' AND tef_rol_requerido <> N''sgspi_rol_comite_direccion'') THROW 51000, N''comité sin rol'', 1;', 0;

EXECUTE #espera N'AP-02 custodio no aprueba un activo', N'
INSERT sgspi.activo_informacion (aci_codigo_inventario, aci_nombre_activo, tac_codigo, uaa_codigo, aci_clasificacion_transparencia, aci_valor_confidencialidad, aci_valor_integridad, aci_valor_disponibilidad, per_codigo_creador) VALUES (N''INV-R'', N''Activo por aprobar'', 3, 1, N''PUBLICA'', 1, 1, 1, 1);
INSERT sgspi.activo_informacion_responsable (aci_codigo, car_codigo, uaa_codigo, air_tipo_responsabilidad) VALUES ((SELECT aci_codigo FROM sgspi.activo_informacion WHERE aci_codigo_inventario = N''INV-R''), 1, 1, N''PROPIETARIO'');
UPDATE sgspi.activo_informacion SET aci_estado_registro = N''EN_VALIDACION_LIDER'' WHERE aci_codigo_inventario = N''INV-R'';
UPDATE sgspi.activo_informacion SET aci_estado_registro = N''EN_REVISION_SGSPI'' WHERE aci_codigo_inventario = N''INV-R'';
EXECUTE AS USER = N''sgspi_prueba_custodio'';
UPDATE sgspi.activo_informacion SET aci_estado_registro = N''VIGENTE'' WHERE aci_codigo_inventario = N''INV-R'';', 50011;

EXECUTE #sesion_como 2; -- aprueba la persona 2

EXECUTE #espera N'AP-02 el oficial sí aprueba el activo', N'EXECUTE AS USER = N''sgspi_prueba_oficial''; UPDATE sgspi.activo_informacion SET aci_estado_registro = N''VIGENTE'' WHERE aci_codigo_inventario = N''INV-R'';', 0;

-- 1.2 Firma de Archivo
EXECUTE #espera N'AP-02 nadie escribe la firma de Archivo con UPDATE', N'EXECUTE AS USER = N''sgspi_prueba_custodio''; UPDATE sgspi.activo_documental SET per_codigo_revisor_archivo = 2 WHERE 1 = 0;', 230;

EXECUTE #espera N'AP-15 la firma de Archivo no se envía al crear el activo documental', N'
INSERT sgspi.activo_informacion (aci_codigo_inventario, aci_nombre_activo, tac_codigo, aci_clasificacion_transparencia, aci_valor_confidencialidad, aci_valor_integridad, aci_valor_disponibilidad, per_codigo_creador) VALUES (N''INV-D'', N''Actas por revisar'', 3, N''PUBLICA'', 1, 1, 1, 2);
INSERT sgspi.activo_documental (ado_codigo, pev_codigo, sdo_codigo, sbd_codigo, pdc_codigo, epc_codigo, ado_lugar_consulta_ubicacion, per_codigo_revisor_archivo) VALUES ((SELECT aci_codigo FROM sgspi.activo_informacion WHERE aci_codigo_inventario = N''INV-D''), 1, 1, 1, 1, 1, N''Archivo'', 3);', 50018;

EXECUTE #espera N'AP-15 la firma de Archivo la pone la transición EN_REVISION_ARCHIVO -> EN_REVISION_SGSPI', N'
INSERT sgspi.activo_documental (ado_codigo, pev_codigo, sdo_codigo, sbd_codigo, pdc_codigo, epc_codigo, ado_lugar_consulta_ubicacion) VALUES ((SELECT aci_codigo FROM sgspi.activo_informacion WHERE aci_codigo_inventario = N''INV-D''), 1, 1, 1, 1, 1, N''Archivo'');
UPDATE sgspi.activo_informacion SET aci_estado_registro = N''EN_VALIDACION_LIDER'' WHERE aci_codigo_inventario = N''INV-D'';
UPDATE sgspi.activo_informacion SET aci_estado_registro = N''EN_REVISION_ARCHIVO'' WHERE aci_codigo_inventario = N''INV-D'';
UPDATE sgspi.activo_informacion SET aci_estado_registro = N''EN_REVISION_SGSPI'' WHERE aci_codigo_inventario = N''INV-D'';
IF ISNULL((SELECT ado.per_codigo_revisor_archivo FROM sgspi.activo_documental AS ado INNER JOIN sgspi.activo_informacion AS aci ON aci.aci_codigo = ado.ado_codigo WHERE aci.aci_codigo_inventario = N''INV-D''), 0) <> 2 THROW 51000, N''firma de Archivo no registrada'', 1;', 0;

-- 1.3 acotado: entre estados editables se puede completar contenido; hacia uno no editable, no
EXECUTE #espera N'AP-05 aprobar editando el contenido en la misma sentencia', N'UPDATE sgspi.activo_informacion SET aci_estado_registro = N''VIGENTE'', aci_nombre_activo = N''Cambiado al aprobar'' WHERE aci_codigo_inventario = N''INV-D'';', 50011;


GO
-- ======================= 8. Padres no editables en hijas y tablas puente =======================
EXECUTE #sesion_como 1;

EXECUTE #espera N'Preparar catálogos y puentes editables', N'
INSERT sgspi.proceso_institucional (pri_identificador, pri_nombre, tpr_codigo, uaa_codigo_lider) VALUES (N''P02'', N''Operaciones'', 1, 1);
INSERT sgspi.formato_archivo_catalogo (fac_nombre) VALUES (N''Hoja de cálculo'');
INSERT sgspi.soporte_registro_catalogo (src_nombre) VALUES (N''Papel'');
INSERT sgspi.medio_conservacion_catalogo (mcc_nombre) VALUES (N''Servidor institucional''), (N''Nube'');
INSERT sgspi.idioma_catalogo (idi_codigo_iso, idi_nombre) VALUES (N''es'', N''Español''), (N''en'', N''Inglés'');
INSERT sgspi.unidad_productora_cuadro_clasificacion_documental (upc_nodo_jerarquico, upc_nombre_unidad) VALUES (hierarchyid::Parse(''/1/''), N''Rectoría''), (hierarchyid::Parse(''/2/''), N''Secretaría'');
INSERT sgspi.control_referencia_normativa (enc_codigo, crn_identificador_control, crn_nombre_control, crn_objetivo_requisito) VALUES (1, N''A.5.15'', N''Control de acceso'', N''o'');

INSERT sgspi.requisito_parte_interesada_cuestionario (rpi_codigo, rpc_numero_pregunta) VALUES (1, 1);
INSERT sgspi.requisito_parte_interesada_proceso_institucional (rpi_codigo, pri_codigo) VALUES (1, 1);
INSERT sgspi.activo_informacion_sede (aci_codigo, sus_codigo) VALUES (1, 1);
INSERT sgspi.activo_informacion_responsable (aci_codigo, car_codigo, uaa_codigo, air_tipo_responsabilidad) VALUES (1, 1, 1, N''CUSTODIO''), (1, 1, 1, N''PROPIETARIO'');
INSERT sgspi.activo_documental_medio_conservacion (ado_codigo, mcc_codigo) VALUES (1, (SELECT mcc_codigo FROM sgspi.medio_conservacion_catalogo WHERE mcc_nombre = N''Servidor institucional''));
INSERT sgspi.activo_documental_idioma (ado_codigo, idi_codigo) VALUES (1, (SELECT idi_codigo FROM sgspi.idioma_catalogo WHERE idi_codigo_iso = N''es''));
INSERT sgspi.activo_documental_unidad_productora (ado_codigo, upc_codigo) VALUES (1, (SELECT upc_codigo FROM sgspi.unidad_productora_cuadro_clasificacion_documental WHERE upc_nombre_unidad = N''Rectoría''));

INSERT sgspi.activo_informacion (aci_codigo_inventario, aci_nombre_activo, tac_codigo, aci_clasificacion_transparencia, aci_valor_confidencialidad, aci_valor_integridad, aci_valor_disponibilidad, per_codigo_creador)
VALUES (N''INV-5'', N''Actas sin ado'', 3, N''PUBLICA'', 1, 2, 2, 1);
INSERT sgspi.evento_incertidumbre_activo (pev_codigo, eia_identificador_evento, eia_naturaleza_evento, pri_codigo, aci_codigo_primario, aci_codigo_soporte, tac_codigo_componente, eia_fuente_generadora, eia_condicion_vulnerabilidad, eia_efecto_consecuencia, eia_escenario_operacional, epr_codigo_inherente, eim_codigo_inherente, per_codigo_creador)
VALUES (1, N''RA-02'', N''RIESGO'', 1, 1, 2, 1, N''f'', N''v'', N''e'', N''Evento sin plan'', 1, 1, 1);', 0;

EXECUTE #sesion_como 2; -- aprueba la persona 2

EXECUTE #espera N'Bloquear padres', N'
UPDATE sgspi.requisito_parte_interesada SET rpi_estado_registro = N''EN_VALIDACION_LIDER'' WHERE rpi_codigo = 1;
UPDATE sgspi.requisito_parte_interesada SET rpi_estado_registro = N''EN_REVISION_SGSPI'' WHERE rpi_codigo = 1;
UPDATE sgspi.requisito_parte_interesada SET rpi_estado_registro = N''VIGENTE'' WHERE rpi_codigo = 1;

UPDATE sgspi.activo_informacion SET aci_estado_registro = N''EN_VALIDACION_LIDER'' WHERE aci_codigo_inventario IN (N''INV-1'', N''INV-5'');
UPDATE sgspi.activo_informacion SET aci_estado_registro = N''EN_REVISION_SGSPI'' WHERE aci_codigo_inventario IN (N''INV-1'', N''INV-5'');
UPDATE sgspi.activo_informacion SET aci_estado_registro = N''VIGENTE'' WHERE aci_codigo_inventario = N''INV-1'';

UPDATE sgspi.evento_incertidumbre_activo SET eia_estado_registro = N''EN_VALIDACION_LIDER'' WHERE eia_identificador_evento IN (N''RA-01'', N''RA-02'');
UPDATE sgspi.evento_incertidumbre_activo SET eia_estado_registro = N''EN_REVISION_SGSPI'' WHERE eia_identificador_evento IN (N''RA-01'', N''RA-02'');', 0;

EXECUTE #espera N'D3 un activo sin propietario no se aprueba', N'UPDATE sgspi.activo_informacion SET aci_estado_registro = N''VIGENTE'' WHERE aci_codigo_inventario = N''INV-5'';', 50020;

EXECUTE #espera N'D3 con su propietario el activo se aprueba', N'
INSERT sgspi.activo_informacion_responsable (aci_codigo, car_codigo, uaa_codigo, air_tipo_responsabilidad) VALUES ((SELECT aci_codigo FROM sgspi.activo_informacion WHERE aci_codigo_inventario = N''INV-5''), 1, 1, N''PROPIETARIO'');
UPDATE sgspi.activo_informacion SET aci_estado_registro = N''VIGENTE'' WHERE aci_codigo_inventario = N''INV-5'';', 0;

EXECUTE #espera N'D3 un solo propietario activo por activo', N'
INSERT dbo.cargo (car_nombre) VALUES (N''Cargo de prueba SGSPI'');
INSERT sgspi.activo_informacion_responsable (aci_codigo, car_codigo, uaa_codigo, air_tipo_responsabilidad) VALUES (1, SCOPE_IDENTITY(), 1, N''PROPIETARIO'');', 2601;

EXECUTE #espera N'AP-16 APROBADO_PLANIFICADO exige plan de tratamiento', N'UPDATE sgspi.evento_incertidumbre_activo SET eia_estado_registro = N''APROBADO_PLANIFICADO'' WHERE eia_identificador_evento = N''RA-02'';', 50020;

EXECUTE #espera N'AP-16 riesgo en celda con comité no se aprueba sin pasar por el comité', N'UPDATE sgspi.evento_incertidumbre_activo SET eia_estado_registro = N''APROBADO_PLANIFICADO'' WHERE eia_identificador_evento = N''RA-01'';', 50020;

EXECUTE #espera N'AP-16 el comité acepta el riesgo y el trigger pone su firma', N'
UPDATE sgspi.evento_incertidumbre_activo SET eia_estado_registro = N''EN_ACEPTACION_COMITE'' WHERE eia_identificador_evento = N''RA-01'';
UPDATE sgspi.evento_incertidumbre_activo SET eia_estado_registro = N''APROBADO_PLANIFICADO'' WHERE eia_identificador_evento = N''RA-01'';
IF ISNULL((SELECT per_codigo_aprobador_comite FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01''), 0) <> 2 THROW 51000, N''firma del comité no registrada'', 1;
UPDATE sgspi.evento_incertidumbre_activo SET eia_estado_registro = N''EN_EJECUCION'' WHERE eia_identificador_evento = N''RA-01'';
UPDATE sgspi.evento_incertidumbre_activo SET eia_estado_registro = N''EN_EVALUACION_EFICACIA'' WHERE eia_identificador_evento = N''RA-01'';', 0;

EXECUTE #espera N'AP-16 CERRADO_EFICAZ exige un plan dictaminado eficaz', N'
UPDATE sgspi.plan_tratamiento SET plt_es_tratamiento_eficaz = 0, plt_dictamen_eficacia = N''No eficaz'', per_codigo_evaluador = 2 WHERE eia_codigo = (SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01'');
UPDATE sgspi.evento_incertidumbre_activo SET eia_estado_registro = N''CERRADO_EFICAZ'' WHERE eia_identificador_evento = N''RA-01'';', 50020;

EXECUTE #espera N'D2 el oficial ya no cierra el riesgo', N'
UPDATE sgspi.plan_tratamiento SET plt_es_tratamiento_eficaz = 1, plt_dictamen_eficacia = N''Eficaz'' WHERE eia_codigo = (SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01'');
EXECUTE AS USER = N''sgspi_prueba_oficial'';
UPDATE sgspi.evento_incertidumbre_activo SET eia_estado_registro = N''CERRADO_EFICAZ'' WHERE eia_identificador_evento = N''RA-01'';', 50011;

EXECUTE #espera N'D2 el auditor certifica la eficacia y cierra el riesgo', N'EXECUTE AS USER = N''sgspi_prueba_auditor''; UPDATE sgspi.evento_incertidumbre_activo SET eia_estado_registro = N''CERRADO_EFICAZ'' WHERE eia_identificador_evento = N''RA-01'';', 0;

EXECUTE #espera N'Cargar RA-02 ya cerrado y sin plan (carga histórica con el trigger deshabilitado, AP-04)', N'
DISABLE TRIGGER sgspi.TR_eia_integridad_y_actualizacion ON sgspi.evento_incertidumbre_activo;
UPDATE sgspi.evento_incertidumbre_activo SET eia_estado_registro = N''CERRADO_EFICAZ'' WHERE eia_identificador_evento = N''RA-02'';
ENABLE TRIGGER sgspi.TR_eia_integridad_y_actualizacion ON sgspi.evento_incertidumbre_activo;', 0;

EXECUTE #espera N'ado INSERT con padre VIGENTE bloqueado', N'INSERT sgspi.activo_documental (ado_codigo, pev_codigo, sdo_codigo, sbd_codigo, pdc_codigo, epc_codigo, ado_lugar_consulta_ubicacion) VALUES ((SELECT aci_codigo FROM sgspi.activo_informacion WHERE aci_codigo_inventario = N''INV-5''), 1, 1, 1, 1, 1, N''x'');', 50011;

EXECUTE #espera N'ado UPDATE con padre VIGENTE bloqueado', N'UPDATE sgspi.activo_documental SET ado_lugar_consulta_ubicacion = N''x'' WHERE ado_codigo = 1;', 50011;

EXECUTE #espera N'plt INSERT con padre CERRADO_EFICAZ bloqueado', N'INSERT sgspi.plan_tratamiento (eia_codigo, plt_naturaleza_evento, etc_codigo, plt_justificacion_estrategia, epr_codigo_residual_meta, eim_codigo_residual_meta, plt_fecha_inicio, plt_fecha_fin, plt_recursos_humanos_tecnicos, plt_recursos_economicos_desc, plt_nombre_indicador_kpi, plt_meta_indicador_kpi) VALUES ((SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-02''), N''RIESGO'', 1, N''j'', 1, 1, ''2026-01-01'', ''2026-12-31'', N''r'', N''r'', N''k'', 100);', 50011;

EXECUTE #espera N'plt UPDATE con padre CERRADO_EFICAZ bloqueado', N'UPDATE sgspi.plan_tratamiento SET plt_justificacion_estrategia = N''x'' WHERE plt_codigo = (SELECT plt_codigo FROM sgspi.plan_tratamiento WHERE eia_codigo = (SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01''));', 50011;

EXECUTE #espera N'act INSERT con padre CERRADO_EFICAZ bloqueado', N'INSERT sgspi.actividad_tratamiento (plt_codigo, act_numero_orden, act_descripcion_actividad, act_fecha_compromiso) VALUES ((SELECT plt_codigo FROM sgspi.plan_tratamiento WHERE eia_codigo = (SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01'')), 2, N''Nueva'', ''2026-07-31'');', 50011;

EXECUTE #espera N'act UPDATE con padre CERRADO_EFICAZ bloqueado', N'UPDATE sgspi.actividad_tratamiento SET act_descripcion_actividad = N''x'' WHERE act_codigo = 1;', 50011;

EXECUTE #espera N'rpc INSERT con padre VIGENTE bloqueado', N'INSERT sgspi.requisito_parte_interesada_cuestionario (rpi_codigo, rpc_numero_pregunta) VALUES (1, 2);', 50011;

EXECUTE #espera N'rpc UPDATE con padre VIGENTE bloqueado', N'UPDATE sgspi.requisito_parte_interesada_cuestionario SET rpc_esta_activo = 0 WHERE rpi_codigo = 1 AND rpc_numero_pregunta = 1;', 50011;

EXECUTE #espera N'rpp INSERT con padre VIGENTE bloqueado', N'INSERT sgspi.requisito_parte_interesada_proceso_institucional (rpi_codigo, pri_codigo) VALUES (1, (SELECT pri_codigo FROM sgspi.proceso_institucional WHERE pri_identificador = N''P02''));', 50011;

EXECUTE #espera N'rpp UPDATE con padre VIGENTE bloqueado', N'UPDATE sgspi.requisito_parte_interesada_proceso_institucional SET rpp_esta_activo = 0 WHERE rpi_codigo = 1 AND pri_codigo = 1;', 50011;

EXECUTE #espera N'aip INSERT con padre VIGENTE bloqueado', N'INSERT sgspi.activo_informacion_proceso_institucional (aci_codigo, pri_codigo) VALUES (1, (SELECT pri_codigo FROM sgspi.proceso_institucional WHERE pri_identificador = N''P02''));', 50011;

EXECUTE #espera N'aip UPDATE con padre VIGENTE bloqueado', N'UPDATE sgspi.activo_informacion_proceso_institucional SET aip_esta_activo = 1 WHERE aci_codigo = 1 AND pri_codigo = 1;', 50011;

EXECUTE #espera N'ais INSERT con padre VIGENTE bloqueado', N'INSERT sgspi.activo_informacion_sede (aci_codigo, sus_codigo) VALUES ((SELECT aci_codigo FROM sgspi.activo_informacion WHERE aci_codigo_inventario = N''INV-5''), 1);', 50011;

EXECUTE #espera N'ais UPDATE con padre VIGENTE bloqueado', N'UPDATE sgspi.activo_informacion_sede SET ais_esta_activo = 0 WHERE aci_codigo = 1 AND sus_codigo = 1;', 50011;

EXECUTE #espera N'air INSERT con padre VIGENTE bloqueado', N'INSERT sgspi.activo_informacion_responsable (aci_codigo, car_codigo, uaa_codigo, air_tipo_responsabilidad) VALUES ((SELECT aci_codigo FROM sgspi.activo_informacion WHERE aci_codigo_inventario = N''INV-5''), 1, 1, N''CUSTODIO'');', 50011;

EXECUTE #espera N'air UPDATE con padre VIGENTE bloqueado', N'UPDATE sgspi.activo_informacion_responsable SET air_esta_activo = 0 WHERE aci_codigo = 1 AND car_codigo = 1 AND uaa_codigo = 1 AND air_tipo_responsabilidad = N''CUSTODIO'';', 50011;

EXECUTE #espera N'ads INSERT con padre VIGENTE bloqueado', N'INSERT sgspi.activo_documental_soporte_registro (ado_codigo, src_codigo) VALUES (1, (SELECT src_codigo FROM sgspi.soporte_registro_catalogo WHERE src_nombre = N''Papel''));', 50011;

EXECUTE #espera N'ads UPDATE con padre VIGENTE bloqueado', N'UPDATE sgspi.activo_documental_soporte_registro SET ads_esta_activo = 0 WHERE ado_codigo = 1 AND src_codigo = 1;', 50011;

EXECUTE #espera N'adm INSERT con padre VIGENTE bloqueado', N'INSERT sgspi.activo_documental_medio_conservacion (ado_codigo, mcc_codigo) VALUES (1, (SELECT mcc_codigo FROM sgspi.medio_conservacion_catalogo WHERE mcc_nombre = N''Nube''));', 50011;

EXECUTE #espera N'adm UPDATE con padre VIGENTE bloqueado', N'UPDATE sgspi.activo_documental_medio_conservacion SET adm_esta_activo = 0 WHERE ado_codigo = 1 AND mcc_codigo = (SELECT mcc_codigo FROM sgspi.medio_conservacion_catalogo WHERE mcc_nombre = N''Servidor institucional'');', 50011;

EXECUTE #espera N'adi INSERT con padre VIGENTE bloqueado', N'INSERT sgspi.activo_documental_idioma (ado_codigo, idi_codigo) VALUES (1, (SELECT idi_codigo FROM sgspi.idioma_catalogo WHERE idi_codigo_iso = N''en''));', 50011;

EXECUTE #espera N'adi UPDATE con padre VIGENTE bloqueado', N'UPDATE sgspi.activo_documental_idioma SET adi_esta_activo = 0 WHERE ado_codigo = 1 AND idi_codigo = (SELECT idi_codigo FROM sgspi.idioma_catalogo WHERE idi_codigo_iso = N''es'');', 50011;

EXECUTE #espera N'adf INSERT con padre VIGENTE bloqueado', N'INSERT sgspi.activo_documental_formato_archivo (ado_codigo, fac_codigo) VALUES (1, (SELECT fac_codigo FROM sgspi.formato_archivo_catalogo WHERE fac_nombre = N''Hoja de cálculo''));', 50011;

EXECUTE #espera N'adf UPDATE con padre VIGENTE bloqueado', N'UPDATE sgspi.activo_documental_formato_archivo SET adf_esta_activo = 0 WHERE ado_codigo = 1 AND fac_codigo = 1;', 50011;

EXECUTE #espera N'adu INSERT con padre VIGENTE bloqueado', N'INSERT sgspi.activo_documental_unidad_productora (ado_codigo, upc_codigo) VALUES (1, (SELECT upc_codigo FROM sgspi.unidad_productora_cuadro_clasificacion_documental WHERE upc_nombre_unidad = N''Secretaría''));', 50011;

EXECUTE #espera N'adu UPDATE con padre VIGENTE bloqueado', N'UPDATE sgspi.activo_documental_unidad_productora SET adu_esta_activo = 0 WHERE ado_codigo = 1 AND upc_codigo = (SELECT upc_codigo FROM sgspi.unidad_productora_cuadro_clasificacion_documental WHERE upc_nombre_unidad = N''Rectoría'');', 50011;

EXECUTE #espera N'ptc INSERT con padre CERRADO_EFICAZ bloqueado', N'INSERT sgspi.plan_tratamiento_control_referencia_normativa (plt_codigo, crn_codigo) VALUES ((SELECT plt_codigo FROM sgspi.plan_tratamiento WHERE eia_codigo = (SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01'')), (SELECT crn_codigo FROM sgspi.control_referencia_normativa WHERE crn_identificador_control = N''A.5.15''));', 50011;

EXECUTE #espera N'ptc UPDATE con padre CERRADO_EFICAZ bloqueado', N'UPDATE sgspi.plan_tratamiento_control_referencia_normativa SET ptc_esta_activo = 0 WHERE plt_codigo = (SELECT plt_codigo FROM sgspi.plan_tratamiento WHERE eia_codigo = (SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01'')) AND crn_codigo = 1;', 50011;

EXECUTE #espera N'Reabrir padre VIGENTE->EN_REVISION_SGSPI habilita edición de hija y puente', N'
UPDATE sgspi.activo_informacion SET aci_estado_registro = N''EN_REVISION_SGSPI'' WHERE aci_codigo = 1;
UPDATE sgspi.activo_documental SET ado_lugar_consulta_ubicacion = N''Bóveda'' WHERE ado_codigo = 1;
UPDATE sgspi.activo_documental_formato_archivo SET adf_esta_activo = 0 WHERE ado_codigo = 1 AND fac_codigo = 2;
UPDATE sgspi.activo_informacion SET aci_estado_registro = N''VIGENTE'' WHERE aci_codigo = 1;
UPDATE sgspi.activo_informacion SET aci_estado_registro = N''HISTORICO'' WHERE aci_codigo = 1;', 0;

EXECUTE #espera N'ado UPDATE con padre HISTORICO bloqueado', N'UPDATE sgspi.activo_documental SET ado_lugar_consulta_ubicacion = N''Otro'' WHERE ado_codigo = 1;', 50011;

EXECUTE #espera N'AP-01 tampoco se borran físicamente los catálogos', N'DELETE sgspi.idioma_catalogo WHERE idi_codigo_iso = N''en'';', 50010;


GO
DROP USER sgspi_prueba_consulta;

DROP USER sgspi_prueba_custodio;

DROP USER sgspi_prueba_oficial;

DROP USER sgspi_prueba_auditor;

DROP USER sgspi_prueba_comite;


GO
SELECT   n,
         IIF (ok = 1, N'PASA', N'FALLA') AS r,
         prueba,
         esperado,
         obtenido
FROM     #resultado
ORDER BY n;

SELECT CONCAT(SUM(CONVERT (INT, ok)), N' de ', COUNT(*), N' pruebas pasan') AS resumen
FROM   #resultado;