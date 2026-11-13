SET NOCOUNT ON;
SET XACT_ABORT OFF;
GO
CREATE TABLE #resultado (n INT IDENTITY, prueba NVARCHAR (200), esperado NVARCHAR (60), obtenido NVARCHAR (400), ok BIT);
GO
CREATE PROCEDURE #espera @nombre NVARCHAR (200), @sql NVARCHAR (MAX), @error INT  -- @error = 0 => debe funcionar
AS
BEGIN
    DECLARE @obt INT = 0, @msg NVARCHAR (400) = N'OK';
    BEGIN TRY
        EXEC sys.sp_executesql @sql;
    END TRY
    BEGIN CATCH
        SELECT @obt = ERROR_NUMBER(), @msg = CONCAT(ERROR_NUMBER(), N': ', LEFT(ERROR_MESSAGE(), 330));
        IF XACT_STATE() <> 0 ROLLBACK;
    END CATCH;
    INSERT #resultado (prueba, esperado, obtenido, ok)
    VALUES (@nombre, CASE WHEN @error = 0 THEN N'OK' ELSE CONCAT(N'error ', @error) END, @msg, IIF(@obt = @error, 1, 0));
END;
GO
-- ======================= 1. Contexto de auditoría y flujo de estados (ACF) =======================
EXEC #espera N'Datos maestros sin contexto: catálogos sin trigger funcionan', N'
INSERT sgspi.periodo_vigencia (pev_anio, pev_fecha_apertura) VALUES (2026, ''2026-01-01'');
INSERT sgspi.tipo_proceso_catalogo (tpr_identificador, tpr_nombre) VALUES (N''EST'', N''ESTRATÉGICO'');
INSERT sgspi.proceso_institucional (pri_identificador, pri_nombre, pri_tpr_codigo, pri_uaa_codigo_lider) VALUES (N''P01'', N''Direccionamiento'', 1, 1);
INSERT sgspi.factor_entorno_catalogo (fec_nombre_factor, fec_ambito_entorno) VALUES (N''Tecnológico'', N''INTERNO'');', 0;
EXEC #espera N'AP-14 pri_identificador duplicado', N'INSERT sgspi.proceso_institucional (pri_identificador, pri_nombre, pri_tpr_codigo) VALUES (N''P01'', N''Otro'', 1);', 2627;
EXEC #espera N'AP-03 INSERT en acf sin contexto de sesión', N'INSERT sgspi.analisis_contexto_factor (acf_pev_codigo, acf_pri_codigo, acf_fec_codigo, acf_naturaleza_factor, acf_numero_factor, acf_descripcion_situacion, acf_per_codigo_creador) VALUES (1,1,1,N''DEBILIDAD'',1,N''x'',1);', 50012;
EXEC #espera N'AP-03 contexto con persona inexistente', N'EXEC sgspi.usp_establecer_contexto_auditoria @per_codigo = 999;', 50013;
EXEC #espera N'Establecer contexto (persona 1)', N'EXEC sgspi.usp_establecer_contexto_auditoria @per_codigo = 1, @direccion_ip = ''10.0.0.1'';', 0;
EXEC #espera N'AP-03 la identidad de sesión no se puede cambiar a mitad de sesión', N'EXEC sgspi.usp_establecer_contexto_auditoria @per_codigo = 2;', 15664;
EXEC #espera N'AP-04 INSERT directo en VIGENTE', N'INSERT sgspi.analisis_contexto_factor (acf_pev_codigo, acf_pri_codigo, acf_fec_codigo, acf_naturaleza_factor, acf_numero_factor, acf_descripcion_situacion, acf_estado_registro, acf_per_codigo_creador, acf_per_codigo_aprobador) VALUES (1,1,1,N''DEBILIDAD'',1,N''x'',N''VIGENTE'',1,2);', 50014;
EXEC #espera N'AP-05 estado inexistente en catálogo', N'INSERT sgspi.analisis_contexto_factor (acf_pev_codigo, acf_pri_codigo, acf_fec_codigo, acf_naturaleza_factor, acf_numero_factor, acf_descripcion_situacion, acf_estado_registro, acf_per_codigo_creador) VALUES (1,1,1,N''DEBILIDAD'',1,N''x'',N''APROBADISIMO'',1);', 547;
EXEC #espera N'INSERT acf en BORRADOR', N'INSERT sgspi.analisis_contexto_factor (acf_pev_codigo, acf_pri_codigo, acf_fec_codigo, acf_naturaleza_factor, acf_numero_factor, acf_descripcion_situacion, acf_per_codigo_creador, acf_valor_prioridad) VALUES (1,1,1,N''DEBILIDAD'',1,N''Obsolescencia'',1,3);', 0;
EXEC #espera N'AP-05 transición no permitida BORRADOR->VIGENTE', N'UPDATE sgspi.analisis_contexto_factor SET acf_estado_registro = N''VIGENTE'', acf_per_codigo_aprobador = 2, acf_impacto_sistema_gestion = N''i'', acf_accion_propuesta = N''a'' WHERE acf_numero_factor = 1;', 50011;
EXEC #espera N'Transición BORRADOR->EN_VALIDACION_LIDER', N'UPDATE sgspi.analisis_contexto_factor SET acf_estado_registro = N''EN_VALIDACION_LIDER'', acf_impacto_sistema_gestion = N''i'', acf_accion_propuesta = N''a'' WHERE acf_numero_factor = 1;', 0;
EXEC #espera N'Transición EN_VALIDACION_LIDER->EN_REVISION_SGSPI', N'UPDATE sgspi.analisis_contexto_factor SET acf_estado_registro = N''EN_REVISION_SGSPI'' WHERE acf_numero_factor = 1;', 0;
EXEC #espera N'AP-15 aprobar sin aprobador', N'UPDATE sgspi.analisis_contexto_factor SET acf_estado_registro = N''VIGENTE'' WHERE acf_numero_factor = 1;', 547;
EXEC #espera N'AP-15 aprobador = creador', N'UPDATE sgspi.analisis_contexto_factor SET acf_estado_registro = N''VIGENTE'', acf_per_codigo_aprobador = 1 WHERE acf_numero_factor = 1;', 547;
EXEC #espera N'Aprobar con aprobador distinto', N'UPDATE sgspi.analisis_contexto_factor SET acf_estado_registro = N''VIGENTE'', acf_per_codigo_aprobador = 2 WHERE acf_numero_factor = 1;', 0;
EXEC #espera N'AP-05 editar VIGENTE sin cambiar estado', N'UPDATE sgspi.analisis_contexto_factor SET acf_descripcion_situacion = N''cambio'' WHERE acf_numero_factor = 1;', 50011;
EXEC #espera N'Borrado físico bloqueado', N'DELETE sgspi.analisis_contexto_factor WHERE acf_numero_factor = 1;', 50010;
INSERT #resultado (prueba, esperado, obtenido, ok)
SELECT N'Bitácora: acciones registradas para acf (CREAR, 2x TRANSICION, APROBAR)', N'CREAR,TRANSICION_ESTADO,TRANSICION_ESTADO,APROBAR',
       STRING_AGG(bas_accion_ejecutada, N',') WITHIN GROUP (ORDER BY bas_codigo),
       IIF(STRING_AGG(bas_accion_ejecutada, N',') WITHIN GROUP (ORDER BY bas_codigo) = N'CREAR,TRANSICION_ESTADO,TRANSICION_ESTADO,APROBAR' AND MIN(bas_per_codigo) = 1 AND MAX(bas_per_codigo) = 1, 1, 0)
FROM sgspi.bitacora_auditoria_sistema WHERE bas_entidad_afectada = N'sgspi.analisis_contexto_factor';
GO
-- ======================= 2. RPI (nuevo creador/aprobador, ya no nace VIGENTE) =======================
EXEC #espera N'AP-04 rpi nace en BORRADOR por defecto', N'
INSERT sgspi.parte_interesada (pai_nombre, pai_origen) VALUES (N''Estudiantes'', N''INTERNA'');
INSERT sgspi.requisito_parte_interesada (rpi_pev_codigo, rpi_pai_codigo, rpi_necesidad_expectativa, rpi_per_codigo_creador) VALUES (1,1,N''Privacidad'',1);
IF (SELECT rpi_estado_registro FROM sgspi.requisito_parte_interesada WHERE rpi_codigo = 1) <> N''BORRADOR'' THROW 51000, N''no nació en BORRADOR'', 1;', 0;
GO
-- ======================= 3. Activos: taxonomía, transparencia, subtipo documental =======================
EXEC #espera N'Taxonomía tac 3 niveles', N'
INSERT sgspi.tipo_activo_catalogo (tac_tac_codigo_padre, tac_nivel_taxonomia, tac_nombre) VALUES (NULL,1,N''Información'');
INSERT sgspi.tipo_activo_catalogo (tac_tac_codigo_padre, tac_nivel_taxonomia, tac_nombre) VALUES (1,2,N''Documento'');
INSERT sgspi.tipo_activo_catalogo (tac_tac_codigo_padre, tac_nivel_taxonomia, tac_nombre) VALUES (2,3,N''Acta'');
INSERT sgspi.tipo_activo_catalogo (tac_tac_codigo_padre, tac_nivel_taxonomia, tac_nombre) VALUES (NULL,1,N''Software'');', 0;
EXEC #espera N'AP-06 subtipo (nivel 3) colgado de una categoría (nivel 1)', N'INSERT sgspi.tipo_activo_catalogo (tac_tac_codigo_padre, tac_nivel_taxonomia, tac_nombre) VALUES (1,3,N''Salto'');', 547;
EXEC #espera N'Causales de excepción', N'
INSERT sgspi.causal_excepcion_transparencia (cet_nivel_reserva_aplicable, cet_numeral_causal, cet_descripcion_causal) VALUES (N''CLASIFICADA'', N''a'', N''Intimidad'');
INSERT sgspi.causal_excepcion_transparencia (cet_nivel_reserva_aplicable, cet_numeral_causal, cet_descripcion_causal) VALUES (N''RESERVADA'', N''a'', N''Defensa'');', 0;
EXEC #espera N'AP-14 causal duplicada (nivel+numeral)', N'INSERT sgspi.causal_excepcion_transparencia (cet_nivel_reserva_aplicable, cet_numeral_causal, cet_descripcion_causal) VALUES (N''RESERVADA'', N''a'', N''Dup'');', 2627;
EXEC #espera N'Activo público en BORRADOR', N'INSERT sgspi.activo_informacion (aci_codigo_inventario, aci_nombre_activo, aci_tac_codigo, aci_clasificacion_transparencia, aci_valor_confidencialidad, aci_valor_integridad, aci_valor_disponibilidad, aci_per_codigo_creador) VALUES (N''INV-1'', N''Actas Consejo'', 3, N''PUBLICA'', 1, 2, 2, 1);', 0;
EXEC #espera N'Activo de soporte', N'INSERT sgspi.activo_informacion (aci_codigo_inventario, aci_nombre_activo, aci_tac_codigo, aci_clasificacion_transparencia, aci_valor_confidencialidad, aci_valor_integridad, aci_valor_disponibilidad, aci_per_codigo_creador) VALUES (N''INV-2'', N''Servidor de archivos'', 4, N''PUBLICA'', 1, 2, 3, 1);', 0;
EXEC #espera N'AP-13 valor antiguo con tilde rechazado', N'INSERT sgspi.activo_informacion (aci_codigo_inventario, aci_nombre_activo, aci_tac_codigo, aci_clasificacion_transparencia, aci_valor_confidencialidad, aci_valor_integridad, aci_valor_disponibilidad, aci_per_codigo_creador) VALUES (N''INV-3'', N''x'', 3, N''PÚBLICA'', 1, 1, 1, 1);', 547;
EXEC #espera N'AP-06 activo RESERVADO con causal de nivel CLASIFICADA', N'INSERT sgspi.activo_informacion (aci_codigo_inventario, aci_nombre_activo, aci_tac_codigo, aci_clasificacion_transparencia, aci_cet_codigo, aci_valor_confidencialidad, aci_valor_integridad, aci_valor_disponibilidad, aci_per_codigo_creador) VALUES (N''INV-4'', N''x'', 3, N''RESERVADA'', 1, 3, 1, 1, 1);', 547;
EXEC #espera N'Catálogos documentales', N'
INSERT sgspi.serie_documental_catalogo (sdo_numero_ccd, sdo_nombre_serie, sdo_tiene_subseries) VALUES (2, N''ACTAS'', 1);
INSERT sgspi.subserie_documental_catalogo (sbd_sdo_codigo, sbd_numero_ccd, sbd_nombre_subserie) VALUES (1, 1, N''Actas de Consejo Superior'');
INSERT sgspi.periodicidad_catalogo (pdc_nombre) VALUES (N''Mensual'');
INSERT sgspi.estado_publicacion_catalogo (epc_nombre) VALUES (N''No publicada'');
INSERT sgspi.formato_archivo_catalogo (fac_nombre) VALUES (N''PDF''), (N''Documento de texto'');
INSERT sgspi.soporte_registro_catalogo (src_nombre) VALUES (N''Digital'');', 0;
EXEC #espera N'AP-06 serie con subseries sin subserie', N'INSERT sgspi.activo_documental (ado_codigo, ado_pev_codigo, ado_sdo_codigo, ado_pdc_codigo, ado_epc_codigo, ado_lugar_consulta_ubicacion) VALUES (1, 1, 1, 1, 1, N''Archivo central'');', 50015;
EXEC #espera N'AP-10 activo documental con PK compartida', N'
INSERT sgspi.activo_documental (ado_codigo, ado_pev_codigo, ado_sdo_codigo, ado_sbd_codigo, ado_pdc_codigo, ado_epc_codigo, ado_lugar_consulta_ubicacion) VALUES (1, 1, 1, 1, 1, 1, N''Archivo central'');
INSERT sgspi.activo_documental_formato_archivo (adf_ado_codigo, adf_fac_codigo) VALUES (1,1),(1,2);
INSERT sgspi.activo_documental_soporte_registro (ads_ado_codigo, ads_src_codigo) VALUES (1,1);', 0;
EXEC #espera N'AP-10 subtipo sin supertipo', N'INSERT sgspi.activo_documental (ado_codigo, ado_pev_codigo, ado_sdo_codigo, ado_sbd_codigo, ado_pdc_codigo, ado_epc_codigo, ado_lugar_consulta_ubicacion) VALUES (99, 1, 1, 1, 1, 1, N''x'');', 547;
GO
-- ======================= 4. Riesgos, plan, actividades, seguimiento =======================
EXEC #espera N'Escalas y matriz 5x5 (una celda)', N'
INSERT sgspi.escala_probabilidad (epr_codigo, epr_codigo_letra, epr_nombre_nivel, epr_descripcion_criterio, epr_frecuencia_referencia) VALUES (5, ''A'', N''Casi seguro'', N''d'', N''f''), (1, ''E'', N''Raro'', N''d'', N''f'');
INSERT sgspi.escala_impacto (eim_codigo, eim_nombre_impacto_negativo, eim_nombre_impacto_positivo, eim_descripcion_organizacional) VALUES (5, N''Catastrófico'', N''Altamente beneficioso'', N''d''), (1, N''Insignificante'', N''Leve'', N''d'');
INSERT sgspi.matriz_valoracion_riesgo (mvr_epr_codigo, mvr_eim_codigo, mvr_zrc_codigo, mvr_directriz_tratamiento_riesgo, mvr_directriz_tratamiento_oportunidad) VALUES (5,5,''E'',N''Tratar'',N''Explotar''), (1,1,''B'',N''Aceptar'',N''Monitorear'');
IF (SELECT mvr_codigo_posicion FROM sgspi.matriz_valoracion_riesgo WHERE mvr_epr_codigo = 5 AND mvr_eim_codigo = 5) <> ''A5'' THROW 51000, N''posición mal calculada'', 1;', 0;
EXEC #espera N'AP-09 letra de probabilidad incoherente (3 = A)', N'INSERT sgspi.escala_probabilidad (epr_codigo, epr_codigo_letra, epr_nombre_nivel, epr_descripcion_criterio, epr_frecuencia_referencia) VALUES (3, ''B'', N''x'', N''d'', N''f'');', 547;
EXEC #espera N'Estrategias de tratamiento', N'INSERT sgspi.estrategia_tratamiento_catalogo (etc_nombre_estrategia, etc_naturaleza_aplicable) VALUES (N''Mitigar'', N''RIESGO''), (N''Explotar'', N''OPORTUNIDAD'');', 0;
EXEC #espera N'AP-06 componente afectado que no es categoría nivel 1', N'INSERT sgspi.evento_incertidumbre_activo (eia_pev_codigo, eia_identificador_evento, eia_naturaleza_evento, eia_pri_codigo, eia_aci_codigo_primario, eia_aci_codigo_soporte, eia_tac_codigo_componente, eia_fuente_generadora, eia_condicion_vulnerabilidad, eia_efecto_consecuencia, eia_escenario_operacional, eia_epr_codigo_inherente, eia_eim_codigo_inherente, eia_per_codigo_creador) VALUES (1, N''RA-01'', N''RIESGO'', 1, 1, 2, 2, N''f'', N''v'', N''e'', N''s'', 5, 5, 1);', 547;
EXEC #espera N'AP-06 identificador RA-ABC rechazado', N'INSERT sgspi.evento_incertidumbre_activo (eia_pev_codigo, eia_identificador_evento, eia_naturaleza_evento, eia_pri_codigo, eia_aci_codigo_primario, eia_aci_codigo_soporte, eia_tac_codigo_componente, eia_fuente_generadora, eia_condicion_vulnerabilidad, eia_efecto_consecuencia, eia_escenario_operacional, eia_epr_codigo_inherente, eia_eim_codigo_inherente, eia_per_codigo_creador) VALUES (1, N''RA-ABC'', N''RIESGO'', 1, 1, 2, 1, N''f'', N''v'', N''e'', N''s'', 5, 5, 1);', 547;
EXEC #espera N'Evento de riesgo RA-01 en BORRADOR', N'INSERT sgspi.evento_incertidumbre_activo (eia_pev_codigo, eia_identificador_evento, eia_naturaleza_evento, eia_pri_codigo, eia_aci_codigo_primario, eia_aci_codigo_soporte, eia_tac_codigo_componente, eia_fuente_generadora, eia_condicion_vulnerabilidad, eia_efecto_consecuencia, eia_escenario_operacional, eia_epr_codigo_inherente, eia_eim_codigo_inherente, eia_per_codigo_creador) VALUES (1, N''RA-01'', N''RIESGO'', 1, 1, 2, 1, N''f'', N''v'', N''e'', N''Fuga de actas'', 5, 5, 1);', 0;
EXEC #espera N'AP-15 validador líder = creador', N'UPDATE sgspi.evento_incertidumbre_activo SET eia_estado_registro = N''EN_VALIDACION_LIDER'', eia_per_codigo_validador_lider = 1 WHERE eia_identificador_evento = N''RA-01'';', 547;
EXEC #espera N'AP-06 estrategia de OPORTUNIDAD sobre evento de RIESGO', N'INSERT sgspi.plan_tratamiento (plt_eia_codigo, plt_naturaleza_evento, plt_etc_codigo, plt_justificacion_estrategia, plt_epr_codigo_residual_meta, plt_eim_codigo_residual_meta, plt_fecha_inicio, plt_fecha_fin, plt_recursos_humanos_tecnicos, plt_recursos_economicos_desc, plt_nombre_indicador_kpi, plt_meta_indicador_kpi) VALUES ((SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01''), N''RIESGO'', 2, N''j'', 1, 1, ''2026-01-01'', ''2026-12-31'', N''r'', N''r'', N''k'', 100);', 547;
EXEC #espera N'AP-06 plan declarando naturaleza distinta a la del evento', N'INSERT sgspi.plan_tratamiento (plt_eia_codigo, plt_naturaleza_evento, plt_etc_codigo, plt_justificacion_estrategia, plt_epr_codigo_residual_meta, plt_eim_codigo_residual_meta, plt_fecha_inicio, plt_fecha_fin, plt_recursos_humanos_tecnicos, plt_recursos_economicos_desc, plt_nombre_indicador_kpi, plt_meta_indicador_kpi) VALUES ((SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01''), N''OPORTUNIDAD'', 2, N''j'', 1, 1, ''2026-01-01'', ''2026-12-31'', N''r'', N''r'', N''k'', 100);', 547;
EXEC #espera N'Plan de tratamiento coherente', N'INSERT sgspi.plan_tratamiento (plt_eia_codigo, plt_naturaleza_evento, plt_etc_codigo, plt_justificacion_estrategia, plt_epr_codigo_residual_meta, plt_eim_codigo_residual_meta, plt_fecha_inicio, plt_fecha_fin, plt_recursos_humanos_tecnicos, plt_recursos_economicos_desc, plt_nombre_indicador_kpi, plt_meta_indicador_kpi) VALUES ((SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01''), N''RIESGO'', 1, N''j'', 1, 1, ''2026-01-01'', ''2026-12-31'', N''r'', N''r'', N''k'', 100);', 0;
EXEC #espera N'AP-16 eficacia sin dictamen ni evaluador', N'UPDATE sgspi.plan_tratamiento SET plt_es_tratamiento_eficaz = 1 WHERE plt_eia_codigo = (SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01'');', 547;
EXEC #espera N'AP-16 KPI 500 veces la meta ya no desborda', N'UPDATE sgspi.plan_tratamiento SET plt_meta_indicador_kpi = 0.01, plt_valor_alcanzado_kpi = 5 WHERE plt_eia_codigo = (SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01''); DECLARE @p DECIMAL(9,2) = (SELECT plt_porcentaje_cumplimiento_kpi FROM sgspi.plan_tratamiento WHERE plt_eia_codigo = (SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01''));', 0;
EXEC #espera N'Actividad en PENDIENTE', N'INSERT sgspi.actividad_tratamiento (act_plt_codigo, act_numero_orden, act_descripcion_actividad, act_fecha_compromiso) VALUES ((SELECT plt_codigo FROM sgspi.plan_tratamiento WHERE plt_eia_codigo = (SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01'')), 1, N''Cifrar repositorio'', ''2026-06-30'');', 0;
EXEC #espera N'AP-14 número de orden duplicado en el plan', N'INSERT sgspi.actividad_tratamiento (act_plt_codigo, act_numero_orden, act_descripcion_actividad, act_fecha_compromiso) VALUES ((SELECT plt_codigo FROM sgspi.plan_tratamiento WHERE plt_eia_codigo = (SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01'')), 1, N''Dup'', ''2026-06-30'');', 2627;
EXEC #espera N'AP-16 evidencia incompleta (nombre sin hash)', N'INSERT sgspi.seguimiento_actividad (sga_act_codigo, sga_per_codigo, sga_porcentaje_reportado, sga_descripcion_avance, sga_nombre_archivo_evidencia) VALUES ((SELECT act_codigo FROM sgspi.actividad_tratamiento WHERE act_numero_orden = 1), 1, 40, N''Avance'', N''acta.pdf'');', 547;
EXEC #espera N'AP-09 seguimiento sincroniza el avance de la actividad', N'
INSERT sgspi.seguimiento_actividad (sga_act_codigo, sga_per_codigo, sga_porcentaje_reportado, sga_descripcion_avance) VALUES ((SELECT act_codigo FROM sgspi.actividad_tratamiento WHERE act_numero_orden = 1), 1, 40, N''Avance parcial'');
IF (SELECT act_porcentaje_avance FROM sgspi.actividad_tratamiento WHERE act_codigo = 1) <> 40 THROW 51000, N''avance no sincronizado'', 1;', 0;
EXEC #espera N'AP-16 seguimiento es append-only', N'UPDATE sgspi.seguimiento_actividad SET sga_porcentaje_reportado = 90 WHERE sga_porcentaje_reportado = 40;', 50016;
EXEC #espera N'AP-16 completar sin llegar a 100%', N'UPDATE sgspi.actividad_tratamiento SET act_estado_actividad = N''EN_CURSO'' WHERE act_codigo = 1; UPDATE sgspi.actividad_tratamiento SET act_estado_actividad = N''COMPLETADA'' WHERE act_codigo = 1;', 547;
GO
-- ======================= 5. Controles ISO 27002 y SoA =======================
EXEC #espera N'AP-07 control con atributos normalizados', N'
INSERT sgspi.estandar_normativo_catalogo (enc_identificador, enc_familia_norma, enc_nombre) VALUES (N''ISO/IEC 27001:2022'', N''ISO27001'', N''SGSI'');
INSERT sgspi.control_referencia_normativa (crn_enc_codigo, crn_identificador_control, crn_nombre_control, crn_objetivo_requisito) VALUES (1, N''A.8.24'', N''Uso de criptografía'', N''o'');
INSERT sgspi.atributo_control_catalogo (aac_tipo_atributo, aac_valor) VALUES (N''TIPO_CONTROL'', N''Preventivo''), (N''PROPIEDAD_SEGURIDAD'', N''Confidencialidad''), (N''PROPIEDAD_SEGURIDAD'', N''Integridad''), (N''DOMINIO_SEGURIDAD'', N''Protección'');
INSERT sgspi.control_referencia_normativa_atributo (cra_crn_codigo, cra_aac_codigo) VALUES (1,1),(1,2),(1,3),(1,4);
INSERT sgspi.plan_tratamiento_control_referencia_normativa (ptc_plt_codigo, ptc_crn_codigo) VALUES ((SELECT plt_codigo FROM sgspi.plan_tratamiento WHERE plt_eia_codigo = (SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01'')),1);', 0;
EXEC #espera N'AP-13 dos ediciones activas de la misma familia', N'INSERT sgspi.estandar_normativo_catalogo (enc_identificador, enc_familia_norma, enc_nombre) VALUES (N''ISO/IEC 27001:2013'', N''ISO27001'', N''SGSI viejo'');', 2601;
EXEC #espera N'SoA aplicable', N'INSERT sgspi.evaluacion_aplicabilidad_control (eac_pev_codigo, eac_crn_codigo, eac_frecuencia_revision, eac_estado_implementacion) VALUES (1, 1, N''Anual'', N''CUMPLE_PARCIAL'');', 0;
GO
-- ======================= 6. Bitácora: inmutabilidad y cadena de hash =======================
EXEC #espera N'AP-01 UPDATE sobre bitácora bloqueado', N'UPDATE sgspi.bitacora_auditoria_sistema SET bas_motivo_observacion = N''x'' WHERE bas_codigo = 1;', 50001;
INSERT #resultado (prueba, esperado, obtenido, ok)
SELECT N'AP-01 cadena: un solo génesis y cada evento enlaza con el anterior', N'1 génesis, 0 rotos',
       CONCAT(SUM(IIF(bas_hash_evento_anterior IS NULL, 1, 0)), N' génesis, ', SUM(IIF(bas_hash_evento_anterior <> prev, 1, 0)), N' rotos de ', COUNT(*)),
       IIF(SUM(IIF(bas_hash_evento_anterior IS NULL, 1, 0)) = 1 AND SUM(IIF(bas_hash_evento_anterior <> prev, 1, 0)) = 0 AND COUNT(*) > 5, 1, 0)
FROM (SELECT bas_hash_evento_anterior, LAG(bas_hash_evento_sha256) OVER (ORDER BY bas_codigo) AS prev FROM sgspi.bitacora_auditoria_sistema) AS x;
CREATE TABLE #verif (bas_codigo BIGINT, motivo_falla NVARCHAR (400));
INSERT #verif EXEC sgspi.usp_verificar_cadena_bitacora;
INSERT #resultado (prueba, esperado, obtenido, ok) SELECT N'AP-01 verificador sobre cadena íntegra', N'0 fallas', CONCAT(COUNT(*), N' fallas'), IIF(COUNT(*) = 0, 1, 0) FROM #verif;
-- Simula a un sysadmin que deshabilita el trigger y altera un evento
DISABLE TRIGGER sgspi.TR_bas_inmutabilidad_bitacora ON sgspi.bitacora_auditoria_sistema;
DECLARE @b2 BIGINT = (SELECT bas_codigo FROM (SELECT bas_codigo, ROW_NUMBER() OVER (ORDER BY bas_codigo) AS rn FROM sgspi.bitacora_auditoria_sistema) AS x WHERE rn = 2);
UPDATE sgspi.bitacora_auditoria_sistema SET bas_per_codigo = 3 WHERE bas_codigo = @b2;
CREATE TABLE #b2 (v BIGINT); INSERT #b2 VALUES (@b2);
ENABLE TRIGGER sgspi.TR_bas_inmutabilidad_bitacora ON sgspi.bitacora_auditoria_sistema;
DELETE #verif;
INSERT #verif EXEC sgspi.usp_verificar_cadena_bitacora;
INSERT #resultado (prueba, esperado, obtenido, ok) SELECT N'AP-01 verificador detecta alteración del evento 2', N'falla en el 2.º evento', CONCAT(N'fallas en: ', STRING_AGG(CONVERT (NVARCHAR (20), bas_codigo), N',')), IIF(MIN(bas_codigo) = (SELECT v FROM #b2), 1, 0) FROM #verif;
GO
-- ======================= 7. Vistas =======================
EXEC #espera N'Vista vw_usuario_rol_alcance_sgspi', N'SELECT * INTO #v1 FROM sgspi.vw_usuario_rol_alcance_sgspi;', 0;
EXEC #espera N'Vista vw_consolidado_dofa', N'SELECT * INTO #v2 FROM sgspi.vw_consolidado_dofa;', 0;
EXEC #espera N'Vista vw_resumen_activos_criticidad', N'SELECT * INTO #v3 FROM sgspi.vw_resumen_activos_criticidad;', 0;
EXEC #espera N'Vista vw_matriz_tratamiento_riesgos (ISO27001 por familia)', N'IF (SELECT crn_controles_iso27001 FROM sgspi.vw_matriz_tratamiento_riesgos) <> N''A.8.24'' THROW 51000, N''control no proyectado'', 1;', 0;
EXEC #espera N'Vista vw_desglose_ccd_trd_mr04', N'SELECT * INTO #v5 FROM sgspi.vw_desglose_ccd_trd_mr04;', 0;
EXEC #espera N'Vista vw_inventario_activo_documental_mr04 (formatos agregados)', N'IF (SELECT ado_formato_documental FROM sgspi.vw_inventario_activo_documental_mr04 WHERE ado_codigo = 1) NOT IN (N''PDF/Documento de texto'', N''Documento de texto/PDF'') THROW 51000, N''formato no agregado'', 1;', 0;
EXEC #espera N'Vista vw_controles_atributos_iso27002', N'SELECT * INTO #v7 FROM sgspi.vw_controles_atributos_iso27002;', 0;
GO
SELECT n, IIF(ok = 1, N'PASA', N'FALLA') AS r, prueba, esperado, obtenido FROM #resultado ORDER BY n;
SELECT CONCAT(SUM(CONVERT (INT, ok)), N' de ', COUNT(*), N' pruebas pasan') AS resumen FROM #resultado;
GO
