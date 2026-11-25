SET ANSI_NULLS ON;

SET QUOTED_IDENTIFIER ON;

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
    DECLARE @prev_per AS SQL_VARIANT = SESSION_CONTEXT(N'per_codigo');
    BEGIN TRY
        EXECUTE sys.sp_executesql @sql;
    END TRY
    BEGIN CATCH
        SELECT @obt = ERROR_NUMBER(),
               @msg = CONCAT(ERROR_NUMBER(), N': ', LEFT(ERROR_MESSAGE(), 330));
        IF XACT_STATE() <> 0
            ROLLBACK;
    END CATCH
    -- Garantiza aislamiento entre pruebas aunque falle o ruede atrás la transacción
    EXECUTE sys.sp_set_session_context @key = N'per_codigo', @value = @prev_per;
    INSERT  #resultado (
        prueba,
        esperado,
        obtenido,
        ok
    )
    VALUES             (@nombre, CASE WHEN @error = 0 THEN N'OK' ELSE CONCAT(N'error ', @error) END, @msg, IIF (@obt = @error, 1, 0));
END


GO
-- [Fase 1 v2.4] Los triggers toman la persona opcional desde SESSION_CONTEXT(N'per_codigo').
-- #sesion_como la asigna para simular llamadas con actor (persona 1 crea, persona 2 aprueba sin violar SoD)
-- o sin SESSION_CONTEXT (NULL) en llamadas del pool HikariCP.
CREATE PROCEDURE #sesion_como
@per_codigo INT
AS
BEGIN
    EXECUTE sys.sp_set_session_context @key = N'per_codigo', @value = @per_codigo;
END


GO
EXECUTE #espera N'AP-22 toda tabla (salvo las aud_*) tiene columna de borrado lógico BIT NOT NULL DEFAULT 1', N'
IF EXISTS (SELECT 1 FROM sys.tables AS t
           WHERE  t.schema_id = SCHEMA_ID(N''sgspi'')
                  AND t.name NOT LIKE N''aud[_]%''
                  AND NOT EXISTS (SELECT 1 FROM sys.columns AS c
                                  INNER JOIN sys.default_constraints AS dc ON dc.object_id = c.default_object_id
                                  WHERE c.object_id = t.object_id
                                        AND c.name LIKE N''%[_]estado''
                                        AND c.is_nullable = 0
                                        AND c.system_type_id = 104 -- BIT
                                        AND dc.definition = N''((1))''))
    THROW 51000, N''hay tablas sin <acr>_estado'', 1;', 0;

-- Cada tabla aud_* tiene: su código, las columnas no calculadas del origen salvo <acr>_version y <acr>_fecha_creacion, per_codigo,
-- <aud>_operacion ('I'/'U'), usuario_bd y fecha_cambio. Si se agrega una columna a una tabla y no a su auditoría, esta prueba falla.
EXECUTE #espera N'AP-01 cada tabla tiene su auditoría con las mismas columnas', N'
IF EXISTS (SELECT 1 FROM sys.tables AS t
           WHERE  t.schema_id = SCHEMA_ID(N''sgspi'')
                  AND t.name NOT LIKE N''aud[_]%''
                  AND (OBJECT_ID(N''sgspi.aud_'' + t.name) IS NULL
                       OR (SELECT COUNT(*) FROM sys.columns AS c WHERE c.object_id = OBJECT_ID(N''sgspi.aud_'' + t.name))
                          <> 5 + (SELECT COUNT(*) FROM sys.columns AS c
                                  WHERE c.object_id = t.object_id AND c.is_computed = 0 AND c.system_type_id <> 189 AND c.name NOT LIKE N''%[_]fecha[_]creacion'')
                       OR NOT EXISTS (SELECT 1 FROM sys.columns AS c
                                      WHERE  c.object_id = OBJECT_ID(N''sgspi.aud_'' + t.name)
                                             AND c.name LIKE N''___[_]operacion''
                                             AND c.is_nullable = 0)
                       OR NOT EXISTS (SELECT 1 FROM sys.check_constraints AS cc
                                      WHERE  cc.parent_object_id = OBJECT_ID(N''sgspi.aud_'' + t.name)
                                             AND cc.name LIKE N''CK[_]___[_]operacion'')))
    THROW 51000, N''hay tablas sin auditoría o con columnas distintas'', 1;', 0;

-- T1: cada tabla tiene un trigger que escribe en su aud_* y cada aud_* su trigger INSTEAD OF de inmutabilidad.
-- Si un reemplazo masivo trunca uno de los 99 triggers (como en d0df220 y 17d5b8b), esta prueba lo nombra.
EXECUTE #espera N'T1 cada tabla tiene su trigger de auditoría y cada aud_* su trigger de inmutabilidad', N'
IF EXISTS (SELECT 1 FROM sys.tables AS t
           WHERE  t.schema_id = SCHEMA_ID(N''sgspi'')
                  AND ((t.name LIKE N''aud[_]%''
                        AND NOT EXISTS (SELECT 1 FROM sys.triggers AS tr WHERE tr.parent_id = t.object_id AND tr.is_instead_of_trigger = 1))
                       OR (t.name NOT LIKE N''aud[_]%''
                           AND NOT EXISTS (SELECT 1 FROM sys.triggers AS tr
                                           INNER JOIN sys.sql_expression_dependencies AS d ON d.referencing_id = tr.object_id
                                           WHERE tr.parent_id = t.object_id AND d.referenced_id = OBJECT_ID(N''sgspi.aud_'' + t.name)))))
    THROW 51000, N''hay tablas sin trigger de auditoría o aud_* sin trigger de inmutabilidad'', 1;', 0;

EXECUTE #espera N'Fase 1 sensibilidad: 18 columnas confidenciales clasificadas (8 HIGH eia/aud_eia, 4 HIGH aci/aud_aci, 6 MEDIUM plt/sga/eac)', N'
IF (SELECT COUNT(*) FROM sys.sensitivity_classifications AS sc
    WHERE  sc.major_id IN (OBJECT_ID(N''sgspi.evento_incertidumbre_activo''), OBJECT_ID(N''sgspi.aud_evento_incertidumbre_activo''))
           AND sc.rank_desc = N''HIGH'') <> 8
   OR (SELECT COUNT(*) FROM sys.sensitivity_classifications AS sc
       WHERE  sc.major_id IN (OBJECT_ID(N''sgspi.activo_informacion''), OBJECT_ID(N''sgspi.aud_activo_informacion''))
              AND sc.rank_desc = N''HIGH'') <> 4
   OR (SELECT COUNT(*) FROM sys.sensitivity_classifications AS sc
       WHERE  sc.major_id IN (OBJECT_ID(N''sgspi.plan_tratamiento''), OBJECT_ID(N''sgspi.aud_plan_tratamiento''),
                              OBJECT_ID(N''sgspi.seguimiento_actividad''), OBJECT_ID(N''sgspi.aud_seguimiento_actividad''),
                              OBJECT_ID(N''sgspi.evaluacion_aplicabilidad_control''), OBJECT_ID(N''sgspi.aud_evaluacion_aplicabilidad_control''))
              AND sc.rank_desc = N''MEDIUM'') <> 6
    THROW 51000, N''faltan columnas confidenciales por clasificar'', 1;', 0;

-- Guarda de los EXCEPT de transición: toda columna de contenido de las 5 tablas con flujo debe estar en el EXCEPT previo a aud_*
EXECUTE #espera N'AP-05 toda columna de contenido de las tablas con flujo está en el EXCEPT de su trigger', N'
IF EXISTS (SELECT 1
           FROM   sys.tables AS t
                  INNER JOIN sys.columns AS c ON c.object_id = t.object_id
                  INNER JOIN sys.triggers AS tr ON tr.parent_id = t.object_id AND tr.name LIKE N''TR[_]%[_]integridad[_]y[_]actualizacion''
           WHERE  t.schema_id = SCHEMA_ID(N''sgspi'')
                  AND t.name IN (N''analisis_contexto_factor'', N''requisito_parte_interesada'', N''activo_informacion'', N''evento_incertidumbre_activo'', N''actividad_tratamiento'')
                  AND c.is_computed = 0
                  AND c.system_type_id <> 189 -- ROWVERSION
                  AND c.name NOT IN (N''acf_fase_registro'', N''rpi_fase_registro'', N''aci_fase_registro'', N''eia_fase_registro'', N''act_fase_actividad'',
                                     N''per_codigo_aprobador'', N''per_codigo_revisor_archivo'', N''per_codigo_validador_lider'', N''per_codigo_revisor_sgspi'', N''per_codigo_aprobador_comite'')
                  AND (CHARINDEX(N''i.'' + c.name, LEFT(OBJECT_DEFINITION(tr.object_id), CHARINDEX(N''INSERT INTO sgspi.aud_'', OBJECT_DEFINITION(tr.object_id)))) = 0
                       OR CHARINDEX(N''d.'' + c.name, LEFT(OBJECT_DEFINITION(tr.object_id), CHARINDEX(N''INSERT INTO sgspi.aud_'', OBJECT_DEFINITION(tr.object_id)))) = 0))
    THROW 51000, N''hay columnas fuera del EXCEPT de transición'', 1;', 0;

-- Estados referenciados en CHECK o triggers deben existir en estado_flujo_catalogo
EXECUTE #espera N'AP-05 los identificadores de estado usados en CHECK o triggers existen en [efc]', N'
IF EXISTS (SELECT v.id
           FROM   (VALUES (N''BORRADOR''), (N''VIGENTE''), (N''EN_VALIDACION_LIDER''), (N''EN_REVISION_ARCHIVO''),
                          (N''EN_REVISION_SGSPI''), (N''EN_ACEPTACION_COMITE''), (N''APROBADO_PLANIFICADO''),
                          (N''EN_EVALUACION_EFICACIA''), (N''CERRADO_EFICAZ''), (N''PENDIENTE''), (N''COMPLETADA'')) AS v(id)
           WHERE  NOT EXISTS (SELECT 1 FROM sgspi.estado_flujo_catalogo AS efc WHERE efc.efc_identificador = v.id))
    THROW 51000, N''falta un estado requerido por el código'', 1;', 0;

EXECUTE #espera N'Versión 2.4 registrada, compatibilidad 100 soportada y usp_obtener_contexto_usuario disponible sin ufn_persona_sesion', N'
IF NOT EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 3 AND major_id = SCHEMA_ID(N''sgspi'') AND name = N''sgspi_version'' AND CONVERT(NVARCHAR(20), value) = N''2.4'')
    THROW 51000, N''falta propiedad sgspi_version 2.4'', 1;
IF (SELECT compatibility_level FROM sys.databases WHERE database_id = DB_ID()) <> 100
    THROW 51000, N''base desechable no está en compatibility_level 100'', 1;
IF OBJECT_ID(N''sgspi.usp_obtener_contexto_usuario'', N''P'') IS NULL
   OR OBJECT_ID(N''sgspi.ufn_persona_sesion'') IS NOT NULL
    THROW 51000, N''contrato de identidad v2.4 inconsistente en esquema sgspi'', 1;', 0;

-- El usuario de prueba admin_prueba queda en un grupo SGSPI en la UAA 1, que más abajo se liga al proceso 1.
EXECUTE #espera N'Fase 1 contexto de prueba: admin_prueba pertenece a un grupo SGSPI en UAA 1 y usp_obtener_contexto_usuario lo resuelve por us', N'
INSERT dbo.grupo (gru_nombre, gru_id) VALUES (N''Prueba Alcance SGSPI'', N''SGSPI_PRUEBA_ALCANCE'');
DECLARE @gru INT = SCOPE_IDENTITY();
INSERT dbo.usuario_grupo (usg_usuario, usg_grupo, usg_uaa)
SELECT TOP (1) u.uid, @gru, 1 FROM dbo.usuario_administrativos AS u WHERE u.us = ''admin_prueba'' ORDER BY u.uid;
DECLARE @ctx TABLE (per_codigo INT, uid BIGINT, nombre_completo NVARCHAR(500), gru_id NVARCHAR(100), uaa_codigo INT, pri_codigo INT);
INSERT @ctx EXECUTE sgspi.usp_obtener_contexto_usuario @us = ''admin_prueba'';
IF NOT EXISTS (SELECT 1 FROM @ctx WHERE per_codigo = 2 AND gru_id = ''SGSPI_PRUEBA_ALCANCE'' AND uaa_codigo = 1)
    THROW 51000, N''usp_obtener_contexto_usuario no devolvió contexto esperado para admin_prueba'', 1;', 0;

-- ======================= 1. Flujo de estados (ACF) =======================
EXECUTE #sesion_como 1; -- crea la persona 1

EXECUTE #espera N'Datos maestros', N'
INSERT sgspi.periodo_vigencia (pev_anio, pev_fecha_apertura) VALUES (2026, ''2026-01-01'');
INSERT sgspi.tipo_proceso_catalogo (tpr_identificador, tpr_nombre) VALUES (N''EST'', N''ESTRATÉGICO'');
INSERT sgspi.proceso_institucional (pri_identificador, pri_nombre, tpr_codigo, uaa_codigo_lider, car_codigo_lider) VALUES (N''P01'', N''Direccionamiento'', 1, 1, 1);
INSERT sgspi.proceso_institucional_uaa (pri_codigo, uaa_codigo) VALUES (1, 1);
INSERT sgspi.factor_entorno_catalogo (fec_nombre_factor, fec_ambito_entorno) VALUES (N''Tecnológico'', N''INTERNO'');', 0;

EXECUTE #espera N'AP-14 pri_identificador duplicado', N'INSERT sgspi.proceso_institucional (pri_identificador, pri_nombre, tpr_codigo) VALUES (N''P01'', N''Otro'', 1);', 2601;

EXECUTE #espera N'AP-04 INSERT directo en VIGENTE', N'INSERT sgspi.analisis_contexto_factor (pev_codigo, pri_codigo, fec_codigo, acf_naturaleza_factor, acf_numero_factor, acf_descripcion_situacion, acf_fase_registro, per_codigo_creador, per_codigo_aprobador) VALUES (1,1,1,N''DEBILIDAD'',1,N''x'',N''VIGENTE'',1,2);', 50014;

EXECUTE #espera N'AP-05 estado inexistente en catálogo', N'INSERT sgspi.analisis_contexto_factor (pev_codigo, pri_codigo, fec_codigo, acf_naturaleza_factor, acf_numero_factor, acf_descripcion_situacion, acf_fase_registro, per_codigo_creador) VALUES (1,1,1,N''DEBILIDAD'',1,N''x'',N''APROBADISIMO'',1);', 547;

EXECUTE #espera N'INSERT acf en BORRADOR', N'INSERT sgspi.analisis_contexto_factor (pev_codigo, pri_codigo, fec_codigo, acf_naturaleza_factor, acf_numero_factor, acf_descripcion_situacion, per_codigo_creador, acf_valor_prioridad) VALUES (1,1,1,N''DEBILIDAD'',1,N''Obsolescencia'',1,3);', 0;

EXECUTE #espera N'Mejora DOFA: una AMENAZA sobre un factor INTERNO se rechaza (FK_acf_factor_entorno_ambito)', N'INSERT sgspi.analisis_contexto_factor (pev_codigo, pri_codigo, fec_codigo, acf_naturaleza_factor, acf_numero_factor, acf_descripcion_situacion, per_codigo_creador) VALUES (1,1,1,N''AMENAZA'',1,N''Amenaza sobre factor interno'',1);', 547;

EXECUTE #espera N'AP-05 transición no permitida BORRADOR->VIGENTE', N'UPDATE sgspi.analisis_contexto_factor SET acf_fase_registro = N''VIGENTE'', per_codigo_aprobador = 2, acf_impacto_sistema_gestion = N''i'', acf_accion_propuesta = N''a'' WHERE acf_numero_factor = 1;', 50011;

EXECUTE #espera N'Transición BORRADOR->EN_VALIDACION_LIDER', N'UPDATE sgspi.analisis_contexto_factor SET acf_fase_registro = N''EN_VALIDACION_LIDER'', acf_impacto_sistema_gestion = N''i'', acf_accion_propuesta = N''a'' WHERE acf_numero_factor = 1;', 0;

EXECUTE #espera N'Transición EN_VALIDACION_LIDER->EN_REVISION_SGSPI', N'UPDATE sgspi.analisis_contexto_factor SET acf_fase_registro = N''EN_REVISION_SGSPI'' WHERE acf_numero_factor = 1;', 0;

EXECUTE #sesion_como 2; -- aprueba la persona 2

EXECUTE #espera N'AP-15 la firma de aprobación la pone el trigger, no el cliente', N'
UPDATE sgspi.analisis_contexto_factor SET acf_fase_registro = N''VIGENTE'', per_codigo_aprobador = 3 WHERE acf_numero_factor = 1;
IF (SELECT per_codigo_aprobador FROM sgspi.analisis_contexto_factor WHERE acf_numero_factor = 1) <> 2 THROW 51000, N''la firma no es la persona del login'', 1;', 0;

EXECUTE #espera N'AP-15 quien aprueba (persona del login) = creador', N'
INSERT sgspi.analisis_contexto_factor (pev_codigo, pri_codigo, fec_codigo, acf_naturaleza_factor, acf_numero_factor, acf_descripcion_situacion, per_codigo_creador) VALUES (1,1,1,N''DEBILIDAD'',2,N''Autoaprobación'',2);
UPDATE sgspi.analisis_contexto_factor SET acf_fase_registro = N''EN_VALIDACION_LIDER'' WHERE acf_numero_factor = 2;
UPDATE sgspi.analisis_contexto_factor SET acf_fase_registro = N''EN_REVISION_SGSPI'' WHERE acf_numero_factor = 2;
UPDATE sgspi.analisis_contexto_factor SET acf_fase_registro = N''VIGENTE'' WHERE acf_numero_factor = 2;', 547;

EXECUTE #espera N'AP-15 el creador debe ser la persona de la sesión (acf)', N'INSERT sgspi.analisis_contexto_factor (pev_codigo, pri_codigo, fec_codigo, acf_naturaleza_factor, acf_numero_factor, acf_descripcion_situacion, per_codigo_creador) VALUES (1,1,1,N''DEBILIDAD'',3,N''Suplantación'',1);', 50019;

-- El factor D1 se creó (1 'I' de la persona 1) y cambió tres veces (3 'U': EN_VALIDACION_LIDER, EN_REVISION_SGSPI y VIGENTE); los UPDATE internos del trigger no cuentan
EXECUTE #espera N'AP-01 [C2] la auditoría guarda after-image del alta (I) y de cada UPDATE (U), con quién aprobó y su firma', N'
DECLARE @acf INT = (SELECT acf_codigo FROM sgspi.analisis_contexto_factor WHERE acf_numero_factor = 1);
IF (SELECT COUNT(*) FROM sgspi.aud_analisis_contexto_factor WHERE acf_codigo = @acf AND aaf_operacion = ''U'') <> 3
   OR (SELECT COUNT(*) FROM sgspi.aud_analisis_contexto_factor WHERE acf_codigo = @acf AND aaf_operacion = ''I'' AND aaf_fase_registro = N''BORRADOR'' AND per_codigo = 1) <> 1
   OR NOT EXISTS (SELECT 1 FROM sgspi.aud_analisis_contexto_factor
                  WHERE acf_codigo = @acf AND aaf_operacion = ''U'' AND aaf_fase_registro = N''VIGENTE'' AND per_codigo_aprobador = 2 AND per_codigo = 2)
    THROW 51000, N''la auditoría after-image no registró el alta o el estado resultante VIGENTE con aprobador 2'', 1;', 0;

EXECUTE #espera N'AP-05 editar VIGENTE sin cambiar estado', N'UPDATE sgspi.analisis_contexto_factor SET acf_descripcion_situacion = N''cambio'' WHERE acf_numero_factor = 1;', 50011;

-- Toda fila tiene su alta 'I' en aud_*: la FK de la auditoría rechaza el DELETE (547) antes que el trigger (50010)
EXECUTE #espera N'Borrado físico bloqueado', N'DELETE sgspi.analisis_contexto_factor WHERE acf_numero_factor = 1;', 547;


GO
-- ======================= 2. RPI (nuevo creador/aprobador, ya no nace VIGENTE) =======================
EXECUTE #sesion_como 1;

EXECUTE #espera N'AP-04 rpi nace en BORRADOR por defecto', N'
INSERT sgspi.parte_interesada (pai_nombre, pai_origen) VALUES (N''Estudiantes'', N''INTERNA'');
INSERT sgspi.requisito_parte_interesada (pev_codigo, pai_codigo, rpi_necesidad_expectativa, per_codigo_creador) VALUES (1,1,N''Privacidad'',1);
IF (SELECT rpi_fase_registro FROM sgspi.requisito_parte_interesada WHERE rpi_codigo = 1) <> N''BORRADOR'' THROW 51000, N''no nació en BORRADOR'', 1;', 0;

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

EXECUTE #espera N'AP-14 causal duplicada (nivel+numeral)', N'INSERT sgspi.causal_excepcion_transparencia (cet_nivel_reserva_aplicable, cet_numeral_causal, cet_descripcion_causal) VALUES (N''RESERVADA'', N''a'', N''Dup'');', 2601;

EXECUTE #espera N'Activo público en BORRADOR', N'INSERT sgspi.activo_informacion (aci_codigo_inventario, aci_nombre_activo, tac_codigo, aci_clasificacion_transparencia, aci_valor_confidencialidad, aci_valor_integridad, aci_valor_disponibilidad, per_codigo_creador) VALUES (N''INV-1'', N''Actas Consejo'', 3, N''PUBLICA'', 1, 2, 2, 1);', 0;

EXECUTE #espera N'Activo de soporte (de la UAA 1, en el alcance del login de prueba)', N'INSERT sgspi.activo_informacion (aci_codigo_inventario, aci_nombre_activo, tac_codigo, uaa_codigo, aci_clasificacion_transparencia, aci_valor_confidencialidad, aci_valor_integridad, aci_valor_disponibilidad, per_codigo_creador) VALUES (N''INV-2'', N''Servidor de archivos'', 4, 1, N''PUBLICA'', 1, 2, 3, 1);', 0;

EXECUTE #espera N'D4 el activo INV-1 se asocia al proceso 1 antes de registrar sus riesgos', N'INSERT sgspi.activo_informacion_proceso_institucional (aci_codigo, pri_codigo) VALUES (1, 1);', 0;

EXECUTE #espera N'Mejora sedes: un activo transversal no admite sedes activas (FK_ais_activo_no_transversal)', N'
BEGIN TRAN;
UPDATE sgspi.activo_informacion SET aci_es_transversal_sedes = 1 WHERE aci_codigo = 2;
INSERT sgspi.activo_informacion_sede (aci_codigo, sus_codigo) VALUES (2, 1);
ROLLBACK;', 547;

EXECUTE #espera N'Mejora sedes: un activo con una sede activa no se marca transversal', N'
BEGIN TRAN;
INSERT sgspi.activo_informacion_sede (aci_codigo, sus_codigo) VALUES (2, 1);
UPDATE sgspi.activo_informacion SET aci_es_transversal_sedes = 1 WHERE aci_codigo = 2;
ROLLBACK;', 547;

EXECUTE #espera N'Mejora sedes: con la sede desactivada el activo sí se marca transversal', N'
BEGIN TRAN;
INSERT sgspi.activo_informacion_sede (aci_codigo, sus_codigo) VALUES (2, 1);
UPDATE sgspi.activo_informacion_sede SET ais_estado = 0 WHERE aci_codigo = 2 AND sus_codigo = 1;
UPDATE sgspi.activo_informacion SET aci_es_transversal_sedes = 1 WHERE aci_codigo = 2;
ROLLBACK;', 0;

EXECUTE #espera N'AP-13 valor antiguo con tilde rechazado', N'INSERT sgspi.activo_informacion (aci_codigo_inventario, aci_nombre_activo, tac_codigo, aci_clasificacion_transparencia, aci_valor_confidencialidad, aci_valor_integridad, aci_valor_disponibilidad, per_codigo_creador) VALUES (N''INV-3'', N''x'', 3, N''PÚBLICA'', 1, 1, 1, 1);', 547;

EXECUTE #espera N'AP-06 activo RESERVADO con causal de nivel CLASIFICADA', N'INSERT sgspi.activo_informacion (aci_codigo_inventario, aci_nombre_activo, tac_codigo, aci_clasificacion_transparencia, cet_codigo, aci_valor_confidencialidad, aci_valor_integridad, aci_valor_disponibilidad, per_codigo_creador) VALUES (N''INV-4'', N''x'', 3, N''RESERVADA'', 1, 3, 1, 1, 1);', 547;

EXECUTE #espera N'AP-15 el creador debe ser la persona de la sesión (aci)', N'INSERT sgspi.activo_informacion (aci_codigo_inventario, aci_nombre_activo, tac_codigo, aci_clasificacion_transparencia, aci_valor_confidencialidad, aci_valor_integridad, aci_valor_disponibilidad, per_codigo_creador) VALUES (N''INV-S'', N''x'', 3, N''PUBLICA'', 1, 1, 1, 2);', 50019;

EXECUTE #espera N'AP-23 activo RESERVADO a 15 años', N'INSERT sgspi.activo_informacion (aci_codigo_inventario, aci_nombre_activo, tac_codigo, aci_clasificacion_transparencia, cet_codigo, aci_es_reserva_indefinida, aci_anios_plazo_reserva, aci_valor_confidencialidad, aci_valor_integridad, aci_valor_disponibilidad, per_codigo_creador) VALUES (N''INV-6'', N''Expedientes de defensa'', 3, N''RESERVADA'', 2, 0, 15, 3, 1, 1, 1);', 0;

EXECUTE #espera N'AP-23 activo RESERVADO con reserva indefinida', N'INSERT sgspi.activo_informacion (aci_codigo_inventario, aci_nombre_activo, tac_codigo, aci_clasificacion_transparencia, cet_codigo, aci_es_reserva_indefinida, aci_valor_confidencialidad, aci_valor_integridad, aci_valor_disponibilidad, per_codigo_creador) VALUES (N''INV-7'', N''x'', 3, N''RESERVADA'', 2, 1, 3, 1, 1, 1);', 547;

EXECUTE #espera N'AP-23 activo RESERVADO a más de 15 años', N'INSERT sgspi.activo_informacion (aci_codigo_inventario, aci_nombre_activo, tac_codigo, aci_clasificacion_transparencia, cet_codigo, aci_es_reserva_indefinida, aci_anios_plazo_reserva, aci_valor_confidencialidad, aci_valor_integridad, aci_valor_disponibilidad, per_codigo_creador) VALUES (N''INV-8'', N''x'', 3, N''RESERVADA'', 2, 0, 16, 3, 1, 1, 1);', 547;

EXECUTE #espera N'Mejora reserva: un activo CLASIFICADO sin fundamentos no sale de BORRADOR (CK_aci_coherencia_indice_reserva)', N'
BEGIN TRAN;
INSERT sgspi.activo_informacion (aci_codigo_inventario, aci_nombre_activo, tac_codigo, aci_clasificacion_transparencia, cet_codigo, aci_alcance_excepcion, aci_fecha_clasificacion_reserva, aci_es_reserva_indefinida, aci_valor_confidencialidad, aci_valor_integridad, aci_valor_disponibilidad, per_codigo_creador)
VALUES (N''INV-F1'', N''Historias clínicas'', 3, N''CLASIFICADA'', 1, N''TOTAL'', ''2026-01-01'', 1, 3, 2, 2, CONVERT(INT, SESSION_CONTEXT(N''per_codigo'')));
UPDATE sgspi.activo_informacion SET aci_fase_registro = N''EN_VALIDACION_LIDER'' WHERE aci_codigo_inventario = N''INV-F1'';
ROLLBACK;', 547;

EXECUTE #espera N'Mejora reserva: con ambos fundamentos el activo CLASIFICADO sale de BORRADOR', N'
BEGIN TRAN;
INSERT sgspi.activo_informacion (aci_codigo_inventario, aci_nombre_activo, tac_codigo, aci_clasificacion_transparencia, cet_codigo, aci_alcance_excepcion, aci_fundamento_constitucional_legal, aci_fundamento_juridico_excepcion, aci_fecha_clasificacion_reserva, aci_es_reserva_indefinida, aci_valor_confidencialidad, aci_valor_integridad, aci_valor_disponibilidad, per_codigo_creador)
VALUES (N''INV-F2'', N''Historias clínicas'', 3, N''CLASIFICADA'', 1, N''TOTAL'', N''Ley 1712 de 2014'', N''Ley 1712 de 2014, art. 18, literal a'', ''2026-01-01'', 1, 3, 2, 2, CONVERT(INT, SESSION_CONTEXT(N''per_codigo'')));
UPDATE sgspi.activo_informacion SET aci_fase_registro = N''EN_VALIDACION_LIDER'' WHERE aci_codigo_inventario = N''INV-F2'';
ROLLBACK;', 0;

EXECUTE #espera N'Catálogos documentales', N'
INSERT sgspi.serie_documental_catalogo (sdo_numero_ccd, sdo_nombre_serie) VALUES (2, N''ACTAS'');
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

EXECUTE #espera N'AP-06 componente afectado que no es categoría nivel 1', N'INSERT sgspi.evento_incertidumbre_activo (pev_codigo, eia_numero_evento, eia_naturaleza_evento, pri_codigo, aci_codigo_primario, aci_codigo_soporte, tac_codigo_componente, eia_fuente_generadora, eia_condicion_vulnerabilidad, eia_efecto_consecuencia, eia_escenario_operacional, epr_codigo_inherente, eim_codigo_inherente, per_codigo_creador) VALUES (1, 1, N''RIESGO'', 1, 1, 2, 2, N''f'', N''v'', N''e'', N''s'', 5, 5, 1);', 547;

EXECUTE #espera N'A2 número de evento fuera de rango (0) rechazado', N'INSERT sgspi.evento_incertidumbre_activo (pev_codigo, eia_numero_evento, eia_naturaleza_evento, pri_codigo, aci_codigo_primario, aci_codigo_soporte, tac_codigo_componente, eia_fuente_generadora, eia_condicion_vulnerabilidad, eia_efecto_consecuencia, eia_escenario_operacional, epr_codigo_inherente, eim_codigo_inherente, per_codigo_creador) VALUES (1, 0, N''RIESGO'', 1, 1, 2, 1, N''f'', N''v'', N''e'', N''s'', 5, 5, 1);', 547;

EXECUTE #espera N'A2 el identificador se calcula desde el número (100 -> RA-100; 1 -> RA-01 en las pruebas siguientes)', N'
BEGIN TRAN;
INSERT sgspi.evento_incertidumbre_activo (pev_codigo, eia_numero_evento, eia_naturaleza_evento, pri_codigo, aci_codigo_primario, aci_codigo_soporte, tac_codigo_componente, eia_fuente_generadora, eia_condicion_vulnerabilidad, eia_efecto_consecuencia, eia_escenario_operacional, epr_codigo_inherente, eim_codigo_inherente, per_codigo_creador) VALUES (1, 100, N''RIESGO'', 1, 1, 2, 1, N''f'', N''v'', N''e'', N''s'', 5, 5, 1);
IF NOT EXISTS (SELECT 1 FROM sgspi.evento_incertidumbre_activo WHERE eia_numero_evento = 100 AND eia_identificador_evento = N''RA-100'') THROW 51000, N''identificador mal calculado'', 1;
ROLLBACK;', 0;

EXECUTE #espera N'eia activo soporte igual al primario rechazado (CK_eia_activos_distintos)', N'INSERT sgspi.evento_incertidumbre_activo (pev_codigo, eia_numero_evento, eia_naturaleza_evento, pri_codigo, aci_codigo_primario, aci_codigo_soporte, tac_codigo_componente, eia_fuente_generadora, eia_condicion_vulnerabilidad, eia_efecto_consecuencia, eia_escenario_operacional, epr_codigo_inherente, eim_codigo_inherente, per_codigo_creador) VALUES (1, 7, N''RIESGO'', 1, 1, 1, 1, N''f'', N''v'', N''e'', N''Mismo activo'', 5, 5, 1);', 547;

EXECUTE #espera N'Evento de riesgo RA-01 en BORRADOR', N'INSERT sgspi.evento_incertidumbre_activo (pev_codigo, eia_numero_evento, eia_naturaleza_evento, pri_codigo, aci_codigo_primario, aci_codigo_soporte, tac_codigo_componente, eia_fuente_generadora, eia_condicion_vulnerabilidad, eia_efecto_consecuencia, eia_escenario_operacional, epr_codigo_inherente, eim_codigo_inherente, per_codigo_creador) VALUES (1, 1, N''RIESGO'', 1, 1, 2, 1, N''f'', N''v'', N''e'', N''Fuga de actas'', 5, 5, 1);', 0;

EXECUTE #espera N'A2 número repetido en la vigencia y la naturaleza rechazado (UX_eia_vigencia_naturaleza_numero)', N'INSERT sgspi.evento_incertidumbre_activo (pev_codigo, eia_numero_evento, eia_naturaleza_evento, pri_codigo, aci_codigo_primario, aci_codigo_soporte, tac_codigo_componente, eia_fuente_generadora, eia_condicion_vulnerabilidad, eia_efecto_consecuencia, eia_escenario_operacional, epr_codigo_inherente, eim_codigo_inherente, per_codigo_creador) VALUES (1, 1, N''RIESGO'', 1, 1, 2, 1, N''f'', N''v'', N''e'', N''Duplicado de RA-01'', 5, 5, 1);', 2601;

EXECUTE #espera N'AP-15 el creador debe ser la persona de la sesión (eia)', N'INSERT sgspi.evento_incertidumbre_activo (pev_codigo, eia_numero_evento, eia_naturaleza_evento, pri_codigo, aci_codigo_primario, aci_codigo_soporte, tac_codigo_componente, eia_fuente_generadora, eia_condicion_vulnerabilidad, eia_efecto_consecuencia, eia_escenario_operacional, epr_codigo_inherente, eim_codigo_inherente, per_codigo_creador) VALUES (1, 9, N''RIESGO'', 1, 1, 2, 1, N''f'', N''v'', N''e'', N''Suplantación'', 5, 5, 2);', 50019;

EXECUTE #espera N'D4 riesgo en un proceso al que no pertenece su activo primario', N'INSERT sgspi.evento_incertidumbre_activo (pev_codigo, eia_numero_evento, eia_naturaleza_evento, pri_codigo, aci_codigo_primario, aci_codigo_soporte, tac_codigo_componente, eia_fuente_generadora, eia_condicion_vulnerabilidad, eia_efecto_consecuencia, eia_escenario_operacional, epr_codigo_inherente, eim_codigo_inherente, per_codigo_creador) VALUES (1, 8, N''RIESGO'', 1, 2, 1, 1, N''f'', N''v'', N''e'', N''Proceso ajeno al activo'', 5, 5, 1);', 547;

EXECUTE #espera N'AP-15 validador líder = creador', N'UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''EN_VALIDACION_LIDER'', per_codigo_validador_lider = 1 WHERE eia_identificador_evento = N''RA-01'';', 547;

EXECUTE #espera N'AP-06 estrategia de OPORTUNIDAD sobre evento de RIESGO', N'INSERT sgspi.plan_tratamiento (eia_codigo, plt_naturaleza_evento, etc_codigo, plt_justificacion_estrategia, epr_codigo_residual_meta, eim_codigo_residual_meta, plt_fecha_inicio, plt_fecha_fin, plt_recursos_humanos_tecnicos, plt_recursos_economicos_desc, plt_nombre_indicador_kpi, plt_meta_indicador_kpi) VALUES ((SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01''), N''RIESGO'', 2, N''j'', 1, 1, ''2026-01-01'', ''2026-12-31'', N''r'', N''r'', N''k'', 100);', 547;

EXECUTE #espera N'AP-06 plan declarando naturaleza distinta a la del evento', N'INSERT sgspi.plan_tratamiento (eia_codigo, plt_naturaleza_evento, etc_codigo, plt_justificacion_estrategia, epr_codigo_residual_meta, eim_codigo_residual_meta, plt_fecha_inicio, plt_fecha_fin, plt_recursos_humanos_tecnicos, plt_recursos_economicos_desc, plt_nombre_indicador_kpi, plt_meta_indicador_kpi) VALUES ((SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01''), N''OPORTUNIDAD'', 2, N''j'', 1, 1, ''2026-01-01'', ''2026-12-31'', N''r'', N''r'', N''k'', 100);', 547;

EXECUTE #espera N'Plan de tratamiento coherente', N'INSERT sgspi.plan_tratamiento (eia_codigo, plt_naturaleza_evento, etc_codigo, plt_justificacion_estrategia, epr_codigo_residual_meta, eim_codigo_residual_meta, plt_fecha_inicio, plt_fecha_fin, plt_recursos_humanos_tecnicos, plt_recursos_economicos_desc, plt_nombre_indicador_kpi, plt_meta_indicador_kpi) VALUES ((SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01''), N''RIESGO'', 1, N''j'', 1, 1, ''2026-01-01'', ''2026-12-31'', N''r'', N''r'', N''k'', 100);', 0;

EXECUTE #espera N'AP-22 plan inactivo permite crear nuevo plan activo (UX_plt_evento_activo)', N'
BEGIN TRAN;
DECLARE @eia INT = (SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01'');
UPDATE sgspi.plan_tratamiento SET plt_estado = 0 WHERE eia_codigo = @eia;
INSERT sgspi.plan_tratamiento (eia_codigo, plt_naturaleza_evento, etc_codigo, plt_justificacion_estrategia, epr_codigo_residual_meta, eim_codigo_residual_meta, plt_fecha_inicio, plt_fecha_fin, plt_recursos_humanos_tecnicos, plt_recursos_economicos_desc, plt_nombre_indicador_kpi, plt_meta_indicador_kpi) VALUES (@eia, N''RIESGO'', 1, N''Plan corregido'', 1, 1, ''2026-01-01'', ''2026-12-31'', N''r'', N''r'', N''k'', 100);
ROLLBACK;', 0;

EXECUTE #espera N'AP-22 dos planes activos para el mismo evento rechazado (UX_plt_evento_activo)', N'INSERT sgspi.plan_tratamiento (eia_codigo, plt_naturaleza_evento, etc_codigo, plt_justificacion_estrategia, epr_codigo_residual_meta, eim_codigo_residual_meta, plt_fecha_inicio, plt_fecha_fin, plt_recursos_humanos_tecnicos, plt_recursos_economicos_desc, plt_nombre_indicador_kpi, plt_meta_indicador_kpi) VALUES ((SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01''), N''RIESGO'', 1, N''Segundo activo'', 1, 1, ''2026-01-01'', ''2026-12-31'', N''r'', N''r'', N''k'', 100);', 2601;

EXECUTE #espera N'AP-16 eficacia sin dictamen ni evaluador', N'UPDATE sgspi.plan_tratamiento SET plt_es_tratamiento_eficaz = 1 WHERE eia_codigo = (SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01'');', 547;

EXECUTE #espera N'AP-16 KPI extremo cabe en DECIMAL(15,2) sin desbordar', N'UPDATE sgspi.plan_tratamiento SET plt_meta_indicador_kpi = 1, plt_valor_alcanzado_kpi = 100000 WHERE eia_codigo = (SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01''); DECLARE @p DECIMAL(15,2) = (SELECT plt_porcentaje_cumplimiento_kpi FROM sgspi.plan_tratamiento WHERE eia_codigo = (SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01'')); IF @p <> 10000000.00 THROW 51000, N''porcentaje KPI inesperado'', 1;', 0;

EXECUTE #espera N'Mejora KPI: unidad de medida fuera de la lista rechazada (CK_plt_unidad_medida_kpi)', N'UPDATE sgspi.plan_tratamiento SET plt_unidad_medida_kpi = N''METROS'' WHERE eia_codigo = (SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01'');', 547;

EXECUTE #espera N'Actividad en PENDIENTE', N'INSERT sgspi.actividad_tratamiento (plt_codigo, act_numero_orden, act_descripcion_actividad, act_fecha_compromiso) VALUES ((SELECT plt_codigo FROM sgspi.plan_tratamiento WHERE eia_codigo = (SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01'')), 1, N''Cifrar repositorio'', ''2026-06-30'');', 0;

EXECUTE #espera N'AP-14 número de orden duplicado en el plan', N'INSERT sgspi.actividad_tratamiento (plt_codigo, act_numero_orden, act_descripcion_actividad, act_fecha_compromiso) VALUES ((SELECT plt_codigo FROM sgspi.plan_tratamiento WHERE eia_codigo = (SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01'')), 1, N''Dup'', ''2026-06-30'');', 2601;

EXECUTE #espera N'AP-16 evidencia incompleta (nombre sin hash)', N'INSERT sgspi.seguimiento_actividad (act_codigo, per_codigo, sga_porcentaje_reportado, sga_descripcion_avance, sga_nombre_archivo_evidencia) VALUES ((SELECT act_codigo FROM sgspi.actividad_tratamiento WHERE act_numero_orden = 1), 1, 40, N''Avance'', N''acta.pdf'');', 547;

EXECUTE #espera N'AP-16 hash SHA-256 en mayúsculas rechazado (CK_sga_hash_formato)', N'INSERT sgspi.seguimiento_actividad (act_codigo, per_codigo, sga_porcentaje_reportado, sga_descripcion_avance, sga_nombre_archivo_evidencia, sga_uri_almacenamiento_evidencia, sga_hash_sha256_evidencia) VALUES ((SELECT act_codigo FROM sgspi.actividad_tratamiento WHERE act_numero_orden = 1), 1, 20, N''Avance'', N''acta.pdf'', N''https://sgspi/acta.pdf'', REPLICATE(''A'', 64));', 547;

EXECUTE #espera N'AP-16 hash SHA-256 en minúsculas aceptado (CK_sga_hash_formato)', N'
BEGIN TRAN;
INSERT sgspi.seguimiento_actividad (act_codigo, per_codigo, sga_porcentaje_reportado, sga_descripcion_avance, sga_nombre_archivo_evidencia, sga_uri_almacenamiento_evidencia, sga_hash_sha256_evidencia) VALUES ((SELECT act_codigo FROM sgspi.actividad_tratamiento WHERE act_numero_orden = 1), 1, 20, N''Avance'', N''acta.pdf'', N''https://sgspi/acta.pdf'', REPLICATE(''a'', 64));
ROLLBACK;', 0;

EXECUTE #espera N'Fase 1 CK_sga_uri_evidencia: rechaza esquema http://', N'INSERT sgspi.seguimiento_actividad (act_codigo, per_codigo, sga_porcentaje_reportado, sga_descripcion_avance, sga_nombre_archivo_evidencia, sga_uri_almacenamiento_evidencia, sga_hash_sha256_evidencia) VALUES ((SELECT act_codigo FROM sgspi.actividad_tratamiento WHERE act_numero_orden = 1), 1, 20, N''Avance'', N''acta.pdf'', N''http://sgspi/acta.pdf'', REPLICATE(''a'', 64));', 547;

EXECUTE #espera N'Fase 1 CK_sga_uri_evidencia: rechaza ruta UNC y traversal', N'INSERT sgspi.seguimiento_actividad (act_codigo, per_codigo, sga_porcentaje_reportado, sga_descripcion_avance, sga_nombre_archivo_evidencia, sga_uri_almacenamiento_evidencia, sga_hash_sha256_evidencia) VALUES ((SELECT act_codigo FROM sgspi.actividad_tratamiento WHERE act_numero_orden = 1), 1, 20, N''Avance'', N''acta.pdf'', N''\\servidor\recurso\acta.pdf'', REPLICATE(''a'', 64));', 547;

EXECUTE #espera N'Fase 1 CK_sga_uri_evidencia: rechaza traversal (..)', N'INSERT sgspi.seguimiento_actividad (act_codigo, per_codigo, sga_porcentaje_reportado, sga_descripcion_avance, sga_nombre_archivo_evidencia, sga_uri_almacenamiento_evidencia, sga_hash_sha256_evidencia) VALUES ((SELECT act_codigo FROM sgspi.actividad_tratamiento WHERE act_numero_orden = 1), 1, 20, N''Avance'', N''acta.pdf'', N''/sgspi/../secreto.pdf'', REPLICATE(''a'', 64));', 547;

EXECUTE #espera N'Fase 1 CK_sga_uri_evidencia: acepta ruta lógica interna /sgspi/', N'
BEGIN TRAN;
INSERT sgspi.seguimiento_actividad (act_codigo, per_codigo, sga_porcentaje_reportado, sga_descripcion_avance, sga_nombre_archivo_evidencia, sga_uri_almacenamiento_evidencia, sga_hash_sha256_evidencia) VALUES ((SELECT act_codigo FROM sgspi.actividad_tratamiento WHERE act_numero_orden = 1), 1, 20, N''Avance'', N''acta.pdf'', N''/sgspi/2026/acta.pdf'', REPLICATE(''a'', 64));
ROLLBACK;', 0;

EXECUTE #espera N'AP-09 seguimiento sincroniza el avance de la actividad', N'
INSERT sgspi.seguimiento_actividad (act_codigo, per_codigo, sga_porcentaje_reportado, sga_descripcion_avance) VALUES ((SELECT act_codigo FROM sgspi.actividad_tratamiento WHERE act_numero_orden = 1), 1, 40, N''Avance parcial'');
IF (SELECT act_porcentaje_avance FROM sgspi.actividad_tratamiento WHERE act_codigo = 1) <> 40 THROW 51000, N''avance no sincronizado'', 1;', 0;

EXECUTE #espera N'AP-15 el seguimiento lo registra la persona de la sesión', N'INSERT sgspi.seguimiento_actividad (act_codigo, per_codigo, sga_porcentaje_reportado, sga_descripcion_avance) VALUES ((SELECT act_codigo FROM sgspi.actividad_tratamiento WHERE act_numero_orden = 1), 2, 50, N''Avance ajeno'');', 50019;

EXECUTE #espera N'AP-16 seguimiento es append-only', N'UPDATE sgspi.seguimiento_actividad SET sga_porcentaje_reportado = 90 WHERE sga_porcentaje_reportado = 40;', 50016;

EXECUTE #espera N'AP-22 seguimiento no se borra físicamente (FK de su aud_*)', N'DELETE sgspi.seguimiento_actividad WHERE sga_porcentaje_reportado = 40;', 547;

EXECUTE #espera N'AP-22 seguimiento admite borrado lógico y recalcula avance', N'
UPDATE sgspi.seguimiento_actividad SET sga_estado = 0 WHERE sga_porcentaje_reportado = 40;
IF (SELECT act_porcentaje_avance FROM sgspi.actividad_tratamiento WHERE act_codigo = 1) <> 0 THROW 51000, N''avance no volvió a 0'', 1;
UPDATE sgspi.seguimiento_actividad SET sga_estado = 1 WHERE sga_porcentaje_reportado = 40;
IF (SELECT act_porcentaje_avance FROM sgspi.actividad_tratamiento WHERE act_codigo = 1) <> 40 THROW 51000, N''avance no volvió a 40'', 1;', 0;

EXECUTE #espera N'Actividad fuera de PENDIENTE exige cargo y UAA responsables', N'UPDATE sgspi.actividad_tratamiento SET act_fase_actividad = N''EN_CURSO'' WHERE act_codigo = 1;', 547;

EXECUTE #espera N'AP-16 completar sin llegar a 100%', N'UPDATE sgspi.actividad_tratamiento SET act_fase_actividad = N''EN_CURSO'', car_codigo = 1, uaa_codigo = 1 WHERE act_codigo = 1; UPDATE sgspi.actividad_tratamiento SET act_fase_actividad = N''COMPLETADA'' WHERE act_codigo = 1;', 547;


GO
-- ======================= 5. Controles ISO 27002 y SoA =======================
EXECUTE #espera N'AP-07 control con atributos normalizados', N'
INSERT sgspi.estandar_normativo_catalogo (enc_identificador, enc_familia_norma, enc_nombre) VALUES (N''ISO/IEC 27001:2022'', N''ISO27001'', N''SGSI'');
INSERT sgspi.control_referencia_normativa (enc_codigo, crn_identificador_control, crn_nombre_control, crn_objetivo_requisito) VALUES (1, N''A.8.24'', N''Uso de criptografía'', N''o'');
INSERT sgspi.atributo_control_catalogo (aac_tipo_atributo, aac_valor) VALUES (N''TIPO_CONTROL'', N''Preventivo''), (N''PROPIEDAD_SEGURIDAD'', N''Confidencialidad''), (N''PROPIEDAD_SEGURIDAD'', N''Integridad''), (N''DOMINIO_SEGURIDAD'', N''Protección'');
INSERT sgspi.control_referencia_normativa_atributo (crn_codigo, aac_codigo) VALUES (1,1),(1,2),(1,3),(1,4);
INSERT sgspi.plan_tratamiento_control_referencia_normativa (plt_codigo, crn_codigo) VALUES ((SELECT plt_codigo FROM sgspi.plan_tratamiento WHERE eia_codigo = (SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01'')),1);', 0;

EXECUTE #espera N'AP-13 dos ediciones activas de la misma familia', N'INSERT sgspi.estandar_normativo_catalogo (enc_identificador, enc_familia_norma, enc_nombre) VALUES (N''ISO/IEC 27001:2013'', N''ISO27001'', N''SGSI viejo'');', 2601;

EXECUTE #espera N'Mejora SoA: un control aplicable sin responsable se rechaza (CK_eac_coherencia_aplicabilidad)', N'INSERT sgspi.evaluacion_aplicabilidad_control (pev_codigo, crn_codigo, pdc_codigo, eac_fase_implementacion) VALUES (1, 1, 1, N''CUMPLE_PARCIAL'');', 547;

EXECUTE #espera N'SoA aplicable (responsable y frecuencia del catálogo de periodicidad)', N'INSERT sgspi.evaluacion_aplicabilidad_control (pev_codigo, crn_codigo, car_codigo, pdc_codigo, eac_fase_implementacion) VALUES (1, 1, 1, 1, N''CUMPLE_PARCIAL'');', 0;

EXECUTE #espera N'AP-11 el trigger mantiene eac_fecha_actualizacion', N'UPDATE sgspi.evaluacion_aplicabilidad_control SET eac_fecha_actualizacion = ''2000-01-01T00:00:00+00:00'' WHERE eac_codigo = 1; UPDATE sgspi.evaluacion_aplicabilidad_control SET eac_observaciones_auditoria = N''obs'' WHERE eac_codigo = 1; IF (SELECT YEAR(eac_fecha_actualizacion) FROM sgspi.evaluacion_aplicabilidad_control WHERE eac_codigo = 1) = 2000 THROW 51000, N''fecha de actualización no mantenida'', 1;', 0;

EXECUTE #espera N'AP-24 control optimista: un UPDATE con la versión vieja afecta 0 filas', N'
DECLARE @v BINARY(8) = (SELECT eac_version FROM sgspi.evaluacion_aplicabilidad_control WHERE eac_codigo = 1);
UPDATE sgspi.evaluacion_aplicabilidad_control SET eac_observaciones_auditoria = N''cambio vigente'' WHERE eac_codigo = 1 AND eac_version = @v;
UPDATE sgspi.evaluacion_aplicabilidad_control SET eac_observaciones_auditoria = N''cambio obsoleto'' WHERE eac_codigo = 1 AND eac_version = @v;
IF @@ROWCOUNT <> 0 THROW 51000, N''actualizó con versión vieja'', 1;', 0;


GO
-- ======================= 6. Vistas =======================
EXECUTE #espera N'Vista vw_usuario_rol_alcance_sgspi', N'SELECT * INTO #v1 FROM sgspi.vw_usuario_rol_alcance_sgspi;', 0;

EXECUTE #espera N'Vista vw_consolidado_dofa', N'SELECT * INTO #v2 FROM sgspi.vw_consolidado_dofa;', 0;

EXECUTE #espera N'Vista vw_resumen_activos_criticidad', N'SELECT * INTO #v3 FROM sgspi.vw_resumen_activos_criticidad;', 0;

EXECUTE #espera N'Vista vw_matriz_tratamiento_riesgos (ISO27001 por familia)', N'IF (SELECT crn_controles_iso27001 FROM sgspi.vw_matriz_tratamiento_riesgos) <> N''A.8.24'' THROW 51000, N''control no proyectado'', 1;', 0;

EXECUTE #espera N'Vista vw_desglose_ccd_trd_mr04', N'SELECT * INTO #v5 FROM sgspi.vw_desglose_ccd_trd_mr04;', 0;

EXECUTE #espera N'Vista vw_inventario_activo_documental_mr04 (formatos agregados)', N'IF (SELECT ado_formato_documental FROM sgspi.vw_inventario_activo_documental_mr04 WHERE ado_codigo = 1) NOT IN (N''PDF/Documento de texto'', N''Documento de texto/PDF'') THROW 51000, N''formato no agregado'', 1;', 0;

EXECUTE #espera N'Vista vw_controles_atributos_iso27002', N'SELECT * INTO #v7 FROM sgspi.vw_controles_atributos_iso27002;', 0;

EXECUTE #espera N'AP-22 las vistas de reporte filtran <acr>_estado = 1 en su entidad principal', N'
IF CHARINDEX(N''acf.acf_estado = 1'', OBJECT_DEFINITION(OBJECT_ID(N''sgspi.vw_consolidado_dofa''))) = 0
   OR CHARINDEX(N''ai.aci_estado = 1'', OBJECT_DEFINITION(OBJECT_ID(N''sgspi.vw_resumen_activos_criticidad''))) = 0
   OR CHARINDEX(N''eia.eia_estado = 1'', OBJECT_DEFINITION(OBJECT_ID(N''sgspi.vw_matriz_tratamiento_riesgos''))) = 0
   OR CHARINDEX(N''pt.plt_estado = 1'', OBJECT_DEFINITION(OBJECT_ID(N''sgspi.vw_matriz_tratamiento_riesgos''))) = 0
   OR CHARINDEX(N''ado.ado_estado = 1'', OBJECT_DEFINITION(OBJECT_ID(N''sgspi.vw_inventario_activo_documental_mr04''))) = 0
   OR CHARINDEX(N''aci.aci_estado = 1'', OBJECT_DEFINITION(OBJECT_ID(N''sgspi.vw_inventario_activo_documental_mr04''))) = 0
    THROW 51000, N''hay vistas de reporte sin filtro estado = 1'', 1;', 0;


GO
-- ======================= 7. Roles mínimos Spring Boot 4 (Fase 1 v2.4) =======================
-- 229 = permiso denegado sobre objeto; 262/2760 = CREATE TABLE denegado; 1088 = ALTER/DISABLE TRIGGER denegado.
CREATE USER sgspi_prueba_login WITHOUT LOGIN;

CREATE USER sgspi_prueba_consulta WITHOUT LOGIN;

CREATE USER sgspi_prueba_ejecucion WITHOUT LOGIN;

CREATE USER sgspi_prueba_migracion WITHOUT LOGIN;

ALTER ROLE grupo_sgspi_login ADD MEMBER sgspi_prueba_login;

ALTER ROLE grupo_sgspi_consulta ADD MEMBER sgspi_prueba_consulta;

ALTER ROLE grupo_sgspi_ejecucion ADD MEMBER sgspi_prueba_ejecucion;

ALTER ROLE grupo_sgspi_migracion ADD MEMBER sgspi_prueba_migracion;


GO
EXECUTE #espera N'Fase 1 v2.4 estándar USCO: 4 roles grupo_sgspi_* (AUTHORIZATION dbo, sin anidamiento), 0 sgspi_rol_*, 0 RLS y 63 transiciones sin rol en BD', N'
IF EXISTS (SELECT 1 FROM sys.database_principals
           WHERE type = ''R''
             AND name IN (N''sgspi_rol_app'', N''sgspi_rol_migracion'', N''sgspi_rol_consulta'', N''sgspi_rol_login'', N''sgspi_rol_base'',
                          N''sgspi_rol_custodio_operador'', N''sgspi_rol_lider_propietario'',
                          N''sgspi_rol_oficial_seguridad_privacidad'', N''sgspi_rol_auditor_control'',
                          N''sgspi_rol_comite_direccion'', N''sgspi_rol_gestor_documental''))
    THROW 51000, N''aún existen roles fuera de estándar sgspi_rol_*'', 1;
IF (SELECT COUNT(*) FROM sys.database_principals
    WHERE type = ''R''
      AND owning_principal_id = USER_ID(N''dbo'')
      AND name IN (N''grupo_sgspi_login'', N''grupo_sgspi_consulta'', N''grupo_sgspi_ejecucion'', N''grupo_sgspi_migracion'')) <> 4
    THROW 51000, N''faltan roles grupo_sgspi_* o su propietario no es dbo'', 1;
IF EXISTS (SELECT 1 FROM sys.database_role_members AS rm
           INNER JOIN sys.database_principals AS r ON r.principal_id = rm.role_principal_id
           INNER JOIN sys.database_principals AS m ON m.principal_id = rm.member_principal_id
           WHERE r.name IN (N''grupo_sgspi_login'', N''grupo_sgspi_consulta'', N''grupo_sgspi_ejecucion'', N''grupo_sgspi_migracion'')
             AND m.type = ''R'')
    THROW 51000, N''existen roles anidados en grupo_sgspi_*'', 1;
IF OBJECT_ID(N''sgspi.vw_sgspi_admin_login'') IS NOT NULL
   OR OBJECT_ID(N''sgspi.spol_alcance_lectura'') IS NOT NULL
   OR EXISTS (SELECT 1 FROM sys.objects WHERE schema_id = SCHEMA_ID(N''sgspi'') AND type IN (''IF'', ''FN'', ''TF''))
   OR EXISTS (SELECT 1 FROM sys.security_policies WHERE schema_id = SCHEMA_ID(N''sgspi''))
    THROW 51000, N''quedan objetos RLS/TVF/LoginDS retirados en esquema sgspi'', 1;
IF EXISTS (SELECT 1 FROM sgspi.transicion_estado_flujo WHERE tef_estado = 1 AND tef_rol_requerido IS NOT NULL)
   OR (SELECT COUNT(*) FROM sgspi.transicion_estado_flujo WHERE tef_estado = 1) <> 63
    THROW 51000, N''transicion_estado_flujo no coincide con las 63 transiciones activas sin rol en BD'', 1;', 0;

EXECUTE #espera N'Fase 1 v2.4 vw_usuario_rol_alcance_sgspi sin sys/PII sensible, UNION deduplicada y lectura para login/consulta/ejecucion', N'
IF COL_LENGTH(N''sgspi.vw_usuario_rol_alcance_sgspi'', N''per_identificacion'') IS NOT NULL
   OR COL_LENGTH(N''sgspi.vw_usuario_rol_alcance_sgspi'', N''per_correo_institucional'') IS NOT NULL
   OR COL_LENGTH(N''sgspi.vw_usuario_rol_alcance_sgspi'', N''per_email_interno'') IS NOT NULL
   OR COL_LENGTH(N''sgspi.vw_usuario_rol_alcance_sgspi'', N''sys'') IS NOT NULL
   OR CHARINDEX(N''UNION ALL'', OBJECT_DEFINITION(OBJECT_ID(N''sgspi.vw_usuario_rol_alcance_sgspi''))) <> 0
    THROW 51000, N''vw_usuario_rol_alcance_sgspi expone datos prohibidos o usa UNION ALL'', 1;
EXECUTE AS USER = N''sgspi_prueba_login'';
SELECT * INTO #p1_log FROM sgspi.vw_usuario_rol_alcance_sgspi;
REVERT;
EXECUTE AS USER = N''sgspi_prueba_consulta'';
SELECT * INTO #p1_con FROM sgspi.vw_usuario_rol_alcance_sgspi;
REVERT;
EXECUTE AS USER = N''sgspi_prueba_ejecucion'';
SELECT * INTO #p1 FROM sgspi.vw_usuario_rol_alcance_sgspi;
REVERT;
BEGIN TRAN;
UPDATE dbo.usuario_administrativos SET sys = NULL WHERE us = ''admin_prueba'';
SET IDENTITY_INSERT dbo.usuario_docentes ON;
INSERT dbo.usuario_docentes (uid, us, up, state, sys) VALUES (1, ''admin_doc_dup'', 2, 1, NULL);
SET IDENTITY_INSERT dbo.usuario_docentes OFF;
IF (SELECT COUNT(*) FROM sgspi.vw_usuario_rol_alcance_sgspi WHERE per_codigo = 2 AND gru_rol_codigo = ''SGSPI_PRUEBA_ALCANCE'' AND uaa_codigo = 1 AND pri_codigo = 1) <> 1
    THROW 51000, N''vw_usuario_rol_alcance_sgspi duplicó fila admin-docente o falló con sys NULL'', 1;
ROLLBACK;', 0;

EXECUTE #espera N'Fase 1 v2.4 usp_obtener_contexto_usuario exclusivo de grupo_sgspi_login, sin uwd2/sys, soporta docente y sys NULL', N'
IF EXISTS (SELECT 1 FROM sys.dm_exec_describe_first_result_set_for_object(OBJECT_ID(N''sgspi.usp_obtener_contexto_usuario''), NULL)
           WHERE name IN (N''uwd'', N''uwd2'', N''sys'', N''per_identificacion'', N''per_email_interno''))
   OR (SELECT COUNT(*) FROM sys.dm_exec_describe_first_result_set_for_object(OBJECT_ID(N''sgspi.usp_obtener_contexto_usuario''), NULL)) <> 6
   OR CHARINDEX(N''UNION ALL'', OBJECT_DEFINITION(OBJECT_ID(N''sgspi.usp_obtener_contexto_usuario''))) <> 0
    THROW 51000, N''firma o UNION de usp_obtener_contexto_usuario fuera de especificación'', 1;
BEGIN TRAN;
UPDATE dbo.usuario_administrativos SET sys = NULL WHERE us = ''admin_prueba'';
DECLARE @ctx1 TABLE (per_codigo INT, uid BIGINT, nombre_completo NVARCHAR(500), gru_id NVARCHAR(100), uaa_codigo INT, pri_codigo INT);
EXECUTE AS USER = N''sgspi_prueba_login'';
INSERT @ctx1 EXECUTE sgspi.usp_obtener_contexto_usuario @us = ''admin_prueba'';
REVERT;
IF NOT EXISTS (SELECT 1 FROM @ctx1 WHERE per_codigo = 2 AND gru_id = ''SGSPI_PRUEBA_ALCANCE'' AND uaa_codigo = 1 AND pri_codigo = 1)
    THROW 51000, N''usp_obtener_contexto_usuario falló cuando sys IS NULL'', 1;
DECLARE @uid_d INT = (SELECT TOP (1) uid FROM dbo.usuario_docentes WHERE us = ''docente_prueba'');
DECLARE @gru_d INT = (SELECT TOP (1) gru_codigo FROM dbo.grupo WHERE gru_id = ''SGSPI_PRUEBA_ALCANCE'');
IF NOT EXISTS (SELECT 1 FROM dbo.usuario_grupo WHERE usg_usuario = @uid_d AND usg_grupo = @gru_d AND usg_uaa = 1)
    INSERT dbo.usuario_grupo (usg_usuario, usg_grupo, usg_uaa) VALUES (@uid_d, @gru_d, 1);
DECLARE @ctx2 TABLE (per_codigo INT, uid BIGINT, nombre_completo NVARCHAR(500), gru_id NVARCHAR(100), uaa_codigo INT, pri_codigo INT);
EXECUTE AS USER = N''sgspi_prueba_login'';
INSERT @ctx2 EXECUTE sgspi.usp_obtener_contexto_usuario @us = ''docente_prueba'';
REVERT;
IF NOT EXISTS (SELECT 1 FROM @ctx2 WHERE per_codigo = 3 AND gru_id = ''SGSPI_PRUEBA_ALCANCE'' AND uaa_codigo = 1)
    THROW 51000, N''usp_obtener_contexto_usuario no resolvió docente activo'', 1;
ROLLBACK;', 0;

EXECUTE #espera N'Estándar USCO aislamiento por capa: login no lee datos operativos (229), consulta solo lee sgspi + 5 maestras dbo y nadie en runtime lee usuario_administrativos (229)', N'
EXECUTE AS USER = N''sgspi_prueba_login'';
BEGIN TRY SELECT TOP (1) * INTO #f_log1 FROM sgspi.activo_informacion; THROW 51000, N''grupo_sgspi_login leyó activo_informacion'', 1; END TRY BEGIN CATCH IF ERROR_NUMBER() <> 229 THROW; END CATCH;
BEGIN TRY SELECT TOP (1) * INTO #f_log2 FROM dbo.usuario_administrativos; THROW 51000, N''grupo_sgspi_login leyó usuario_administrativos'', 1; END TRY BEGIN CATCH IF ERROR_NUMBER() <> 229 THROW; END CATCH;
REVERT;
EXECUTE AS USER = N''sgspi_prueba_consulta'';
SELECT TOP (1) * INTO #ok_con1 FROM sgspi.vw_consolidado_dofa;
SELECT TOP (1) u.uaa_codigo, c.car_codigo, p.per_codigo, e.esp_codigo, s.sus_codigo INTO #ok_con2
FROM dbo.uaa AS u CROSS JOIN dbo.cargo AS c CROSS JOIN dbo.persona AS p CROSS JOIN dbo.espacio AS e CROSS JOIN dbo.sub_sede AS s;
BEGIN TRY INSERT sgspi.parte_interesada (pai_nombre, pai_origen) VALUES (N''x'', N''INTERNA''); THROW 51000, N''grupo_sgspi_consulta pudo insertar'', 1; END TRY BEGIN CATCH IF ERROR_NUMBER() <> 229 THROW; END CATCH;
BEGIN TRY EXECUTE sgspi.usp_obtener_contexto_usuario @us = ''admin_prueba''; THROW 51000, N''grupo_sgspi_consulta ejecutó usp_obtener_contexto_usuario'', 1; END TRY BEGIN CATCH IF ERROR_NUMBER() <> 229 THROW; END CATCH;
BEGIN TRY SELECT TOP (1) * INTO #f_con1 FROM dbo.usuario_administrativos; THROW 51000, N''grupo_sgspi_consulta leyó usuario_administrativos'', 1; END TRY BEGIN CATCH IF ERROR_NUMBER() <> 229 THROW; END CATCH;
REVERT;
EXECUTE AS USER = N''sgspi_prueba_ejecucion'';
SELECT TOP (1) u.uaa_codigo, c.car_codigo, p.per_codigo, e.esp_codigo, s.sus_codigo INTO #ok_eje1
FROM dbo.uaa AS u CROSS JOIN dbo.cargo AS c CROSS JOIN dbo.persona AS p CROSS JOIN dbo.espacio AS e CROSS JOIN dbo.sub_sede AS s;
BEGIN TRY EXECUTE sgspi.usp_obtener_contexto_usuario @us = ''admin_prueba''; THROW 51000, N''grupo_sgspi_ejecucion ejecutó usp_obtener_contexto_usuario'', 1; END TRY BEGIN CATCH IF ERROR_NUMBER() <> 229 THROW; END CATCH;
BEGIN TRY SELECT TOP (1) * INTO #f_eje1 FROM dbo.usuario_administrativos; THROW 51000, N''grupo_sgspi_ejecucion leyó usuario_administrativos'', 1; END TRY BEGIN CATCH IF ERROR_NUMBER() <> 229 THROW; END CATCH;
REVERT;', 0;

EXECUTE #espera N'AP-02 / Fase 1 grupo_sgspi_ejecucion no escribe la máquina de estados (229)', N'EXECUTE AS USER = N''sgspi_prueba_ejecucion''; INSERT sgspi.transicion_estado_flujo (efc_dominio, efc_identificador_origen, efc_identificador_destino) VALUES (N''ACF'', N''BORRADOR'', N''VIGENTE'');', 229;

EXECUTE #espera N'AP-02 / Fase 1 grupo_sgspi_ejecucion no borra estado_flujo_catalogo (229)', N'EXECUTE AS USER = N''sgspi_prueba_ejecucion''; DELETE sgspi.estado_flujo_catalogo WHERE 1 = 0;', 229;

EXECUTE #espera N'AP-02 / Fase 1 grupo_sgspi_ejecucion administra catálogos con SESSION_CONTEXT=1', N'EXECUTE AS USER = N''sgspi_prueba_ejecucion''; UPDATE sgspi.parte_interesada SET pai_descripcion_rol = N''Comunidad estudiantil'' WHERE pai_codigo = 1;', 0;

EXECUTE #espera N'AP-01 [C2] un catálogo guarda after-image en I y U con quién lo cambió', N'IF NOT EXISTS (SELECT 1 FROM sgspi.aud_parte_interesada WHERE pai_codigo = 1 AND apa_operacion = ''I'' AND apa_descripcion_rol IS NULL AND per_codigo = 1) OR NOT EXISTS (SELECT 1 FROM sgspi.aud_parte_interesada WHERE pai_codigo = 1 AND apa_operacion = ''U'' AND apa_descripcion_rol = N''Comunidad estudiantil'' AND per_codigo = 1) THROW 51000, N''sin after-image en aud_parte_interesada'', 1;', 0;

EXECUTE #espera N'AP-01 la auditoría no se edita', N'UPDATE sgspi.aud_parte_interesada SET apa_descripcion_rol = N''x'';', 50016;

EXECUTE #espera N'AP-01 la auditoría no se borra', N'DELETE sgspi.aud_parte_interesada;', 50016;

EXECUTE #espera N'AP-01 nadie inserta en la auditoría a mano (229)', N'EXECUTE AS USER = N''sgspi_prueba_ejecucion''; INSERT sgspi.aud_parte_interesada (pai_codigo, apa_nombre, apa_origen, apa_estado, per_codigo) VALUES (1, N''x'', N''INTERNA'', 1, 1);', 229;

EXECUTE #espera N'Fase 1 permisos granulares grupo_sgspi_ejecucion: DENY DELETE en las 98 tablas (también las 11 puentes N:M), DENY ALTER en esquema', N'
EXECUTE AS USER = N''sgspi_prueba_ejecucion'';
DECLARE @bad_del INT = 0;
SELECT @bad_del = COUNT(*)
FROM   sys.tables AS t
WHERE  t.schema_id = SCHEMA_ID(N''sgspi'')
       AND HAS_PERMS_BY_NAME(N''sgspi.'' + QUOTENAME(t.name), N''OBJECT'', N''DELETE'') <> 0;
IF @bad_del <> 0
    THROW 51000, N''grupo_sgspi_ejecucion tiene permiso DELETE en alguna tabla de sgspi'', 1;
IF HAS_PERMS_BY_NAME(N''sgspi.parte_interesada'', N''OBJECT'', N''ALTER'') <> 0
    THROW 51000, N''grupo_sgspi_ejecucion tiene permiso ALTER sobre objeto sgspi'', 1;
BEGIN TRY
    EXEC(N''ALTER TABLE sgspi.parte_interesada DISABLE TRIGGER ALL;'');
    THROW 51000, N''grupo_sgspi_ejecucion pudo ejecutar ALTER TABLE / DISABLE TRIGGER'', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() NOT IN (229, 1088, 15151) THROW;
END CATCH', 0;

EXECUTE #espera N'Fase 1 grupo_sgspi_ejecucion no borra físicamente tablas entidad (229)', N'EXECUTE AS USER = N''sgspi_prueba_ejecucion''; DELETE sgspi.analisis_contexto_factor WHERE 1 = 0;', 229;

EXECUTE #espera N'Fase 1 grupo_sgspi_ejecucion no borra físicamente catálogos (229)', N'EXECUTE AS USER = N''sgspi_prueba_ejecucion''; DELETE sgspi.parte_interesada WHERE 1 = 0;', 229;

EXECUTE #espera N'Fase 1 HikariCP sin SESSION_CONTEXT (NULL): opera y audita con per_codigo NULL sin 50017 ni 50021', N'
BEGIN TRAN;
EXECUTE sys.sp_set_session_context @key = N''per_codigo'', @value = NULL;
EXECUTE AS USER = N''sgspi_prueba_ejecucion'';
INSERT sgspi.proceso_institucional (pri_identificador, pri_nombre, tpr_codigo) VALUES (N''P03'', N''Proceso de otra UAA'', 1);
DECLARE @p3 INT = SCOPE_IDENTITY();
INSERT sgspi.analisis_contexto_factor (pev_codigo, pri_codigo, fec_codigo, acf_naturaleza_factor, acf_numero_factor, acf_descripcion_situacion, per_codigo_creador)
VALUES (1, @p3, 1, N''DEBILIDAD'', 77, N''Operación sin SESSION_CONTEXT'', 1);
DECLARE @acf77 INT = SCOPE_IDENTITY();
UPDATE sgspi.parte_interesada SET pai_descripcion_rol = N''Pool sin SESSION_CONTEXT'' WHERE pai_codigo = 1;
REVERT;
IF NOT EXISTS (SELECT 1 FROM sgspi.aud_analisis_contexto_factor WHERE acf_codigo = @acf77 AND aaf_operacion = ''I'' AND per_codigo = 1)
   OR NOT EXISTS (SELECT 1 FROM sgspi.aud_parte_interesada WHERE pai_codigo = 1 AND apa_operacion = ''U'' AND apa_descripcion_rol = N''Pool sin SESSION_CONTEXT'' AND per_codigo IS NULL)
    THROW 51000, N''auditoría sin SESSION_CONTEXT no registró per_codigo NULL'', 1;
ROLLBACK;', 0;

EXECUTE #espera N'Fase 1 firma explícita sin SESSION_CONTEXT: aprobar acf sin per_codigo_aprobador lanza 50020', N'
BEGIN TRAN;
EXECUTE sys.sp_set_session_context @key = N''per_codigo'', @value = NULL;
EXECUTE AS USER = N''sgspi_prueba_ejecucion'';
INSERT sgspi.analisis_contexto_factor (pev_codigo, pri_codigo, fec_codigo, acf_naturaleza_factor, acf_numero_factor, acf_descripcion_situacion, per_codigo_creador)
VALUES (1, 1, 1, N''DEBILIDAD'', 78, N''Sin firma explicita'', 1);
DECLARE @acf78 INT = SCOPE_IDENTITY();
UPDATE sgspi.analisis_contexto_factor SET acf_fase_registro = N''EN_VALIDACION_LIDER'' WHERE acf_codigo = @acf78;
UPDATE sgspi.analisis_contexto_factor SET acf_fase_registro = N''EN_REVISION_SGSPI'' WHERE acf_codigo = @acf78;
UPDATE sgspi.analisis_contexto_factor SET acf_fase_registro = N''VIGENTE'' WHERE acf_codigo = @acf78;', 50020;

EXECUTE #espera N'Fase 1 firma explícita sin SESSION_CONTEXT: aprobar acf pasando per_codigo_aprobador válido persiste y audita firma', N'
BEGIN TRAN;
EXECUTE sys.sp_set_session_context @key = N''per_codigo'', @value = NULL;
EXECUTE AS USER = N''sgspi_prueba_ejecucion'';
INSERT sgspi.analisis_contexto_factor (pev_codigo, pri_codigo, fec_codigo, acf_naturaleza_factor, acf_numero_factor, acf_descripcion_situacion, per_codigo_creador)
VALUES (1, 1, 1, N''DEBILIDAD'', 79, N''Con firma explicita'', 1);
DECLARE @acf79 INT = SCOPE_IDENTITY();
UPDATE sgspi.analisis_contexto_factor SET acf_fase_registro = N''EN_VALIDACION_LIDER'' WHERE acf_codigo = @acf79;
UPDATE sgspi.analisis_contexto_factor SET acf_fase_registro = N''EN_REVISION_SGSPI'' WHERE acf_codigo = @acf79;
UPDATE sgspi.analisis_contexto_factor SET acf_fase_registro = N''VIGENTE'', per_codigo_aprobador = 2 WHERE acf_codigo = @acf79;
REVERT;
IF NOT EXISTS (SELECT 1 FROM sgspi.aud_analisis_contexto_factor WHERE acf_codigo = @acf79 AND aaf_fase_registro = N''VIGENTE'' AND per_codigo_aprobador = 2 AND per_codigo = 2)
    THROW 51000, N''firma explícita sin SESSION_CONTEXT no se reflejó en aud_analisis_contexto_factor'', 1;
ROLLBACK;', 0;

EXECUTE #espera N'Fase 1 grupo_sgspi_migracion (Flyway): DDL en [sgspi] con FK a dbo.persona y DML de catálogo sin SESSION_CONTEXT; sin DDL en [dbo]', N'
BEGIN TRAN;
EXECUTE sys.sp_set_session_context @key = N''per_codigo'', @value = NULL;
EXECUTE AS USER = N''sgspi_prueba_migracion'';
INSERT sgspi.estado_flujo_catalogo (efc_dominio, efc_identificador, efc_nombre, efc_es_inicial, efc_permite_edicion) VALUES (N''ACF'', N''TEST_MIG'', N''Prueba Flyway'', 0, 1);
CREATE TABLE sgspi._flyway_probe (id INT NOT NULL PRIMARY KEY, per_codigo INT NOT NULL REFERENCES dbo.persona(per_codigo));
DROP TABLE sgspi._flyway_probe;
REVERT;
ROLLBACK;
EXECUTE AS USER = N''sgspi_prueba_migracion'';
BEGIN TRY
    EXEC(N''CREATE TABLE dbo._flyway_fail (id INT NOT NULL);'');
    THROW 51000, N''grupo_sgspi_migracion pudo crear tabla en dbo'', 1;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK;
    IF ERROR_NUMBER() NOT IN (262, 2760) THROW;
END CATCH
REVERT;', 0;

EXECUTE #espera N'AP-02 / AP-22 grupo_sgspi_ejecucion sincroniza y recalcula avance vía TR_sga', N'EXECUTE AS USER = N''sgspi_prueba_ejecucion'';
INSERT sgspi.seguimiento_actividad (act_codigo, per_codigo, sga_porcentaje_reportado, sga_descripcion_avance) VALUES (1, 1, 60, N''Avance'');
IF (SELECT act_porcentaje_avance FROM sgspi.actividad_tratamiento WHERE act_codigo = 1) <> 60 THROW 51000, N''avance no sincronizado'', 1;
UPDATE sgspi.seguimiento_actividad SET sga_estado = 0 WHERE sga_porcentaje_reportado = 60;
IF (SELECT act_porcentaje_avance FROM sgspi.actividad_tratamiento WHERE act_codigo = 1) <> 40 THROW 51000, N''avance no recalculado al desactivar'', 1;', 0;

EXECUTE #espera N'AP-22 / Fase 1 grupo_sgspi_ejecucion asocia, desactiva y reactiva puentes N:M con UPDATE; el DELETE físico lo niega DENY DELETE (229)', N'
BEGIN TRAN;
EXECUTE AS USER = N''sgspi_prueba_ejecucion'';
INSERT sgspi.activo_informacion_proceso_institucional (aci_codigo, pri_codigo) VALUES (2, 1);
UPDATE sgspi.activo_informacion_proceso_institucional SET aip_estado = 0 WHERE aci_codigo = 2 AND pri_codigo = 1;
BEGIN TRY
    DELETE sgspi.activo_informacion_proceso_institucional WHERE aci_codigo = 2 AND pri_codigo = 1;
    THROW 51000, N''debía rechazarse por DENY DELETE'', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 229 THROW;
END CATCH
UPDATE sgspi.activo_informacion_proceso_institucional SET aip_estado = 1 WHERE aci_codigo = 2 AND pri_codigo = 1;
REVERT;
ROLLBACK;', 0;

EXECUTE #espera N'Fase 1 sif/msi bloqueados cuando aci padre es VIGENTE (50011)', N'
BEGIN TRAN;
INSERT sgspi.activo_informacion (aci_codigo_inventario, aci_nombre_activo, tac_codigo, uaa_codigo, aci_clasificacion_transparencia, aci_valor_confidencialidad, aci_valor_integridad, aci_valor_disponibilidad, per_codigo_creador) VALUES (N''INV-R'', N''Activo vigente'', 3, 1, N''PUBLICA'', 1, 1, 1, 1);
DECLARE @aci_r INT = SCOPE_IDENTITY();
INSERT sgspi.activo_informacion_proceso_institucional (aci_codigo, pri_codigo) VALUES (@aci_r, 1);
INSERT sgspi.activo_informacion_sede (aci_codigo, sus_codigo) VALUES (@aci_r, 1);
INSERT sgspi.activo_informacion_responsable (aci_codigo, car_codigo, uaa_codigo, air_tipo_responsabilidad) VALUES (@aci_r, 1, 1, N''PROPIETARIO''), (@aci_r, 1, 1, N''CUSTODIO'');
UPDATE sgspi.activo_informacion SET aci_fase_registro = N''EN_VALIDACION_LIDER'' WHERE aci_codigo = @aci_r;
UPDATE sgspi.activo_informacion SET aci_fase_registro = N''EN_REVISION_SGSPI'' WHERE aci_codigo = @aci_r;
EXECUTE sys.sp_set_session_context @key = N''per_codigo'', @value = 2;
UPDATE sgspi.activo_informacion SET aci_fase_registro = N''VIGENTE'' WHERE aci_codigo = @aci_r;
EXECUTE AS USER = N''sgspi_prueba_ejecucion'';
INSERT sgspi.sistema_informacion_ficha (aci_codigo, sif_nombre_sistema, sif_modalidad_desarrollo, sif_descripcion_general)
VALUES (@aci_r, N''SIF en vigente'', N''PROPIO'', N''Prueba'');', 50011;

-- 1.2 [B1] Firma de Archivo (ahora en sgspi.activo_informacion, cero escritura cruzada a [ado])
EXECUTE #sesion_como 2;

EXECUTE #espera N'AP-15 [B1] la firma de Archivo no se envía al crear el activo de información (50018)', N'
INSERT sgspi.activo_informacion (aci_codigo_inventario, aci_nombre_activo, tac_codigo, aci_clasificacion_transparencia, aci_valor_confidencialidad, aci_valor_integridad, aci_valor_disponibilidad, per_codigo_creador, per_codigo_revisor_archivo) VALUES (N''INV-D-ERR'', N''Actas con firma'', 3, N''PUBLICA'', 1, 1, 1, 2, 5);', 50018;

EXECUTE #espera N'AP-15 [B1][B4] persona 5 (<> creador 2) hace EN_REVISION_ARCHIVO -> EN_REVISION_SGSPI bajo grupo_sgspi_ejecucion y TR_aci firma en aci', N'
INSERT sgspi.activo_informacion (aci_codigo_inventario, aci_nombre_activo, tac_codigo, aci_clasificacion_transparencia, aci_valor_confidencialidad, aci_valor_integridad, aci_valor_disponibilidad, per_codigo_creador) VALUES (N''INV-D'', N''Actas por revisar'', 3, N''PUBLICA'', 1, 1, 1, 2);
INSERT sgspi.activo_documental (ado_codigo, pev_codigo, sdo_codigo, sbd_codigo, pdc_codigo, epc_codigo, ado_lugar_consulta_ubicacion) VALUES ((SELECT aci_codigo FROM sgspi.activo_informacion WHERE aci_codigo_inventario = N''INV-D''), 1, 1, 1, 1, 1, N''Archivo'');
UPDATE sgspi.activo_informacion SET aci_fase_registro = N''EN_VALIDACION_LIDER'' WHERE aci_codigo_inventario = N''INV-D'';
UPDATE sgspi.activo_informacion SET aci_fase_registro = N''EN_REVISION_ARCHIVO'' WHERE aci_codigo_inventario = N''INV-D'';
EXECUTE sys.sp_set_session_context @key = N''per_codigo'', @value = 5;
EXECUTE AS USER = N''sgspi_prueba_ejecucion'';
UPDATE sgspi.activo_informacion SET aci_fase_registro = N''EN_REVISION_SGSPI'' WHERE aci_codigo_inventario = N''INV-D'';
REVERT;
IF ISNULL((SELECT per_codigo_revisor_archivo FROM sgspi.activo_informacion WHERE aci_codigo_inventario = N''INV-D''), 0) <> 5 THROW 51000, N''firma de Archivo no registrada en aci'', 1;', 0;

-- 1.3 acotado: entre estados editables se puede completar contenido; hacia uno no editable, no
EXECUTE #espera N'AP-05 aprobar editando el contenido en la misma sentencia', N'UPDATE sgspi.activo_informacion SET aci_fase_registro = N''VIGENTE'', aci_nombre_activo = N''Cambiado al aprobar'' WHERE aci_codigo_inventario = N''INV-D'';', 50011;


GO
-- ======================= 8. Padres no editables en hijas y tablas puente =======================
EXECUTE #sesion_como 1;

EXECUTE #espera N'Preparar catálogos y puentes editables', N'
INSERT sgspi.proceso_institucional (pri_identificador, pri_nombre, tpr_codigo, uaa_codigo_lider, car_codigo_lider) VALUES (N''P02'', N''Operaciones'', 1, 1, 1);
INSERT sgspi.formato_archivo_catalogo (fac_nombre) VALUES (N''Hoja de cálculo'');
INSERT sgspi.soporte_registro_catalogo (src_nombre) VALUES (N''Papel'');
INSERT sgspi.medio_conservacion_catalogo (mcc_nombre) VALUES (N''Servidor institucional''), (N''Nube'');
INSERT sgspi.idioma_catalogo (idi_codigo_iso, idi_nombre) VALUES (N''es'', N''Español''), (N''en'', N''Inglés'');
INSERT sgspi.unidad_productora_cuadro_clasificacion_documental (upc_nodo_jerarquico, upc_nombre_unidad) VALUES (hierarchyid::Parse(''/1/''), N''Rectoría''), (hierarchyid::Parse(''/2/''), N''Secretaría'');
INSERT sgspi.control_referencia_normativa (enc_codigo, crn_identificador_control, crn_nombre_control, crn_objetivo_requisito) VALUES (1, N''A.5.15'', N''Control de acceso'', N''o'');

INSERT sgspi.requisito_parte_interesada_proceso_institucional (rpi_codigo, pri_codigo) VALUES (1, 1);
INSERT sgspi.activo_informacion_sede (aci_codigo, sus_codigo) VALUES (1, 1);
INSERT sgspi.activo_informacion_responsable (aci_codigo, car_codigo, uaa_codigo, air_tipo_responsabilidad) VALUES (1, 1, 1, N''CUSTODIO''), (1, 1, 1, N''PROPIETARIO'');
INSERT sgspi.activo_documental_medio_conservacion (ado_codigo, mcc_codigo) VALUES (1, (SELECT mcc_codigo FROM sgspi.medio_conservacion_catalogo WHERE mcc_nombre = N''Servidor institucional''));
INSERT sgspi.activo_documental_idioma (ado_codigo, idi_codigo) VALUES (1, (SELECT idi_codigo FROM sgspi.idioma_catalogo WHERE idi_codigo_iso = N''es''));
INSERT sgspi.activo_documental_unidad_productora (ado_codigo, upc_codigo) VALUES (1, (SELECT upc_codigo FROM sgspi.unidad_productora_cuadro_clasificacion_documental WHERE upc_nombre_unidad = N''Rectoría''));

INSERT sgspi.activo_informacion (aci_codigo_inventario, aci_nombre_activo, tac_codigo, aci_clasificacion_transparencia, aci_valor_confidencialidad, aci_valor_integridad, aci_valor_disponibilidad, per_codigo_creador)
VALUES (N''INV-5'', N''Actas sin ado'', 3, N''PUBLICA'', 1, 2, 2, 1);
DECLARE @aci_inv5 INT = SCOPE_IDENTITY();
INSERT sgspi.activo_informacion_proceso_institucional (aci_codigo, pri_codigo) VALUES (@aci_inv5, 1);
INSERT sgspi.activo_informacion_sede (aci_codigo, sus_codigo) VALUES (@aci_inv5, 1);
INSERT sgspi.evento_incertidumbre_activo (pev_codigo, eia_numero_evento, eia_naturaleza_evento, pri_codigo, aci_codigo_primario, aci_codigo_soporte, tac_codigo_componente, eia_fuente_generadora, eia_condicion_vulnerabilidad, eia_efecto_consecuencia, eia_escenario_operacional, epr_codigo_inherente, eim_codigo_inherente, per_codigo_creador)
VALUES (1, 2, N''RIESGO'', 1, 1, 2, 1, N''f'', N''v'', N''e'', N''Evento sin plan'', 1, 1, 1);', 0;

EXECUTE #espera N'T1 un alta en air deja una fila I en aud_activo_informacion_responsable con la persona de la sesión', N'
IF NOT EXISTS (SELECT 1 FROM sgspi.aud_activo_informacion_responsable
               WHERE aci_codigo = 1 AND car_codigo = 1 AND uaa_codigo = 1
                     AND air_tipo_responsabilidad = N''PROPIETARIO'' AND aar_operacion = ''I'' AND per_codigo = 1)
    THROW 51000, N''el alta en air no quedó registrada con operación I y la persona de la sesión'', 1;', 0;

EXECUTE #sesion_como 2; -- aprueba la persona 2

EXECUTE #espera N'Bloquear padres', N'
UPDATE sgspi.requisito_parte_interesada SET rpi_fase_registro = N''EN_VALIDACION_LIDER'' WHERE rpi_codigo = 1;
UPDATE sgspi.requisito_parte_interesada SET rpi_fase_registro = N''EN_REVISION_SGSPI'' WHERE rpi_codigo = 1;

UPDATE sgspi.activo_informacion SET aci_fase_registro = N''EN_VALIDACION_LIDER'' WHERE aci_codigo_inventario IN (N''INV-1'', N''INV-5'');
UPDATE sgspi.activo_informacion SET aci_fase_registro = N''EN_REVISION_SGSPI'' WHERE aci_codigo_inventario IN (N''INV-1'', N''INV-5'');

UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''EN_VALIDACION_LIDER'' WHERE eia_identificador_evento IN (N''RA-01'', N''RA-02'');
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''EN_REVISION_SGSPI'' WHERE eia_identificador_evento IN (N''RA-01'', N''RA-02'');', 0;

EXECUTE #espera N'C2 como dbo, pasar a VIGENTE con la fecha en el SET firma el aprobador', N'
UPDATE sgspi.requisito_parte_interesada SET rpi_fase_registro = N''VIGENTE'', rpi_fecha_actualizacion = rpi_fecha_actualizacion WHERE rpi_codigo = 1;
IF ISNULL((SELECT per_codigo_aprobador FROM sgspi.requisito_parte_interesada WHERE rpi_codigo = 1), 0) <> 2 THROW 51000, N''el aprobador no quedó firmado'', 1;', 0;

EXECUTE #espera N'C3 RN-DOC-06 activo documental sin aval de Archivo no pasa a VIGENTE', N'UPDATE sgspi.activo_informacion SET aci_fase_registro = N''VIGENTE'' WHERE aci_codigo_inventario = N''INV-1'';', 50020;

EXECUTE #espera N'C3 RN-RSG-04 en RIESGO la meta residual no puede superar la inherente', N'
BEGIN TRAN;
UPDATE sgspi.evento_incertidumbre_activo SET epr_codigo_inherente = 1, eim_codigo_inherente = 1 WHERE eia_identificador_evento = N''RA-01'';
UPDATE sgspi.plan_tratamiento SET epr_codigo_residual_meta = 5, eim_codigo_residual_meta = 5 WHERE eia_codigo = (SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01'');
EXECUTE sys.sp_set_session_context @key = N''per_codigo'', @value = 4;
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''EN_ACEPTACION_COMITE'' WHERE eia_identificador_evento = N''RA-01'';
EXECUTE sys.sp_set_session_context @key = N''per_codigo'', @value = 5;
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''APROBADO_PLANIFICADO'' WHERE eia_identificador_evento = N''RA-01'';', 50020;

EXECUTE #espera N'C3 RN-RSG-05 activo primario con datos personales exige control ISO27701', N'
BEGIN TRAN;
UPDATE sgspi.activo_informacion SET aci_contiene_datos_personales = 1, aci_contiene_datos_menores = 0, aci_categoria_dato_personal = N''PUBLICOS'', aci_finalidad_recoleccion_pii = N''Gestión'', aci_existe_autorizacion_pii = 1 WHERE aci_codigo = 1;
EXECUTE sys.sp_set_session_context @key = N''per_codigo'', @value = 4;
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''EN_ACEPTACION_COMITE'' WHERE eia_identificador_evento = N''RA-01'';
EXECUTE sys.sp_set_session_context @key = N''per_codigo'', @value = 5;
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''APROBADO_PLANIFICADO'' WHERE eia_identificador_evento = N''RA-01'';', 50020;

EXECUTE #espera N'C3 RN-DOC-06 con aval de Archivo (persona 5) y aprobación SGSPI (persona 4) el activo documental pasa a VIGENTE', N'
UPDATE sgspi.activo_informacion SET aci_fase_registro = N''OBSERVADO'' WHERE aci_codigo_inventario = N''INV-1'';
UPDATE sgspi.activo_informacion SET aci_fase_registro = N''EN_VALIDACION_LIDER'' WHERE aci_codigo_inventario = N''INV-1'';
UPDATE sgspi.activo_informacion SET aci_fase_registro = N''EN_REVISION_ARCHIVO'' WHERE aci_codigo_inventario = N''INV-1'';
EXECUTE sys.sp_set_session_context @key = N''per_codigo'', @value = 5;
UPDATE sgspi.activo_informacion SET aci_fase_registro = N''EN_REVISION_SGSPI'' WHERE aci_codigo_inventario = N''INV-1'';
EXECUTE sys.sp_set_session_context @key = N''per_codigo'', @value = 4;
UPDATE sgspi.activo_informacion SET aci_fase_registro = N''VIGENTE'' WHERE aci_codigo_inventario = N''INV-1'';
EXECUTE sys.sp_set_session_context @key = N''per_codigo'', @value = 2;', 0;

EXECUTE #espera N'D3 un activo sin propietario no se aprueba', N'UPDATE sgspi.activo_informacion SET aci_fase_registro = N''VIGENTE'' WHERE aci_codigo_inventario = N''INV-5'';', 50020;

EXECUTE #espera N'C3 RN-ACT-05 un activo sin custodio no se aprueba', N'
INSERT sgspi.activo_informacion_responsable (aci_codigo, car_codigo, uaa_codigo, air_tipo_responsabilidad) VALUES ((SELECT aci_codigo FROM sgspi.activo_informacion WHERE aci_codigo_inventario = N''INV-5''), 1, 1, N''PROPIETARIO'');
UPDATE sgspi.activo_informacion SET aci_fase_registro = N''VIGENTE'' WHERE aci_codigo_inventario = N''INV-5'';', 50020;

EXECUTE #espera N'D3 y RN-ACT-05 con propietario y custodio el activo se aprueba', N'
INSERT dbo.cargo (car_nombre) VALUES (N''Cargo custodio prueba SGSPI'');
INSERT sgspi.activo_informacion_responsable (aci_codigo, car_codigo, uaa_codigo, air_tipo_responsabilidad) VALUES ((SELECT aci_codigo FROM sgspi.activo_informacion WHERE aci_codigo_inventario = N''INV-5''), SCOPE_IDENTITY(), 1, N''CUSTODIO'');
UPDATE sgspi.activo_informacion SET aci_fase_registro = N''VIGENTE'' WHERE aci_codigo_inventario = N''INV-5'';', 0;

EXECUTE #espera N'D3 un solo propietario activo por activo', N'
INSERT dbo.cargo (car_nombre) VALUES (N''Cargo de prueba SGSPI'');
INSERT sgspi.activo_informacion_responsable (aci_codigo, car_codigo, uaa_codigo, air_tipo_responsabilidad) VALUES (1, SCOPE_IDENTITY(), 1, N''PROPIETARIO'');', 2601;

EXECUTE #espera N'AP-16 APROBADO_PLANIFICADO exige plan de tratamiento', N'UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''APROBADO_PLANIFICADO'' WHERE eia_identificador_evento = N''RA-02'';', 50020;

EXECUTE #espera N'AP-16 riesgo en celda con comité no se aprueba sin pasar por el comité', N'UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''APROBADO_PLANIFICADO'' WHERE eia_identificador_evento = N''RA-01'';', 50020;

EXECUTE #espera N'AP-16 [B4] oficial (persona 4) envía a comité y comité (persona 5) acepta el riesgo con SoD completo', N'
EXECUTE sys.sp_set_session_context @key = N''per_codigo'', @value = 4;
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''EN_ACEPTACION_COMITE'' WHERE eia_identificador_evento = N''RA-01'';
EXECUTE sys.sp_set_session_context @key = N''per_codigo'', @value = 5;
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''APROBADO_PLANIFICADO'' WHERE eia_identificador_evento = N''RA-01'';
IF ISNULL((SELECT per_codigo_aprobador_comite FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01''), 0) <> 5 THROW 51000, N''firma del comité no registrada'', 1;
EXECUTE sys.sp_set_session_context @key = N''per_codigo'', @value = 2;
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''EN_EJECUCION'' WHERE eia_identificador_evento = N''RA-01'';', 0;

EXECUTE #espera N'C3 paso 11 EN_EVALUACION_EFICACIA exige actividades completadas', N'UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''EN_EVALUACION_EFICACIA'' WHERE eia_identificador_evento = N''RA-01'';', 50020;

EXECUTE #espera N'Paso 11 con actividades completadas pasa a EN_EVALUACION_EFICACIA', N'
INSERT sgspi.seguimiento_actividad (act_codigo, per_codigo, sga_porcentaje_reportado, sga_descripcion_avance) VALUES (1, 2, 100, N''Cierre actividad'');
UPDATE sgspi.actividad_tratamiento SET act_fase_actividad = N''COMPLETADA'' WHERE act_codigo = 1;
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''EN_EVALUACION_EFICACIA'' WHERE eia_identificador_evento = N''RA-01'';', 0;

EXECUTE #espera N'Fase 2 TR_plt SoD: validador/revisor (persona 2) no puede dictaminar eficacia', N'EXECUTE AS USER = N''sgspi_prueba_ejecucion''; UPDATE sgspi.plan_tratamiento SET plt_es_tratamiento_eficaz = 1, plt_dictamen_eficacia = N''Auto-auditoría'', per_codigo_evaluador = 2, plt_fecha_evaluacion_eficacia = ''2000-01-01T00:00:00+00:00'' WHERE eia_codigo = (SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01'');', 50019;

EXECUTE #sesion_como 1; -- creador del evento RA-01

EXECUTE #espera N'Fase 2 TR_plt SoD: creador (persona 1) no puede dictaminar eficacia', N'EXECUTE AS USER = N''sgspi_prueba_ejecucion''; UPDATE sgspi.plan_tratamiento SET plt_es_tratamiento_eficaz = 1, plt_dictamen_eficacia = N''Creador evaluando'', per_codigo_evaluador = 1, plt_fecha_evaluacion_eficacia = ''2000-01-01T00:00:00+00:00'' WHERE eia_codigo = (SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01'');', 50019;

EXECUTE #sesion_como 3; -- auditor independiente (persona 3)

EXECUTE #espera N'AP-15 no firma el dictamen como otra persona cuando SESSION_CONTEXT está activo', N'EXECUTE AS USER = N''sgspi_prueba_ejecucion''; UPDATE sgspi.plan_tratamiento SET plt_es_tratamiento_eficaz = 1, plt_dictamen_eficacia = N''Suplantación'', per_codigo_evaluador = 2, plt_fecha_evaluacion_eficacia = ''2000-01-01T00:00:00+00:00'' WHERE eia_codigo = (SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01'');', 50019;

EXECUTE #espera N'AP-16 CERRADO_EFICAZ exige un plan dictaminado eficaz', N'
UPDATE sgspi.plan_tratamiento SET plt_es_tratamiento_eficaz = 0, plt_dictamen_eficacia = N''No eficaz'', per_codigo_evaluador = 3, plt_fecha_evaluacion_eficacia = ''2000-01-01T00:00:00+00:00'' WHERE eia_codigo = (SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01'');
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''CERRADO_EFICAZ'' WHERE eia_identificador_evento = N''RA-01'';', 50020;

EXECUTE #espera N'AP-02 / Fase 1 grupo_sgspi_ejecucion registra el dictamen de eficacia; la fecha la pone el servidor', N'
EXECUTE AS USER = N''sgspi_prueba_ejecucion'';
UPDATE sgspi.plan_tratamiento SET plt_es_tratamiento_eficaz = 1, plt_dictamen_eficacia = N''Eficaz'', per_codigo_evaluador = 3, plt_fecha_evaluacion_eficacia = ''2000-01-01T00:00:00+00:00'' WHERE eia_codigo = (SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01'');
IF (SELECT YEAR(plt_fecha_evaluacion_eficacia) FROM sgspi.plan_tratamiento WHERE eia_codigo = (SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01'')) = 2000 THROW 51000, N''la fecha del dictamen no la puso el servidor'', 1;', 0;

EXECUTE #espera N'Fase 1 grupo_sgspi_ejecucion cierra el riesgo en CERRADO_EFICAZ tras dictamen eficaz', N'EXECUTE AS USER = N''sgspi_prueba_ejecucion''; UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''CERRADO_EFICAZ'' WHERE eia_identificador_evento = N''RA-01'';', 0;

EXECUTE #sesion_como 2;

EXECUTE #espera N'Cargar RA-02 ya cerrado y sin plan (carga histórica con el trigger deshabilitado, AP-04)', N'
DISABLE TRIGGER sgspi.TR_eia_integridad_y_actualizacion ON sgspi.evento_incertidumbre_activo;
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''CERRADO_EFICAZ'' WHERE eia_identificador_evento = N''RA-02'';
ENABLE TRIGGER sgspi.TR_eia_integridad_y_actualizacion ON sgspi.evento_incertidumbre_activo;', 0;

EXECUTE #espera N'ado INSERT con padre VIGENTE bloqueado', N'INSERT sgspi.activo_documental (ado_codigo, pev_codigo, sdo_codigo, sbd_codigo, pdc_codigo, epc_codigo, ado_lugar_consulta_ubicacion) VALUES ((SELECT aci_codigo FROM sgspi.activo_informacion WHERE aci_codigo_inventario = N''INV-5''), 1, 1, 1, 1, 1, N''x'');', 50011;

EXECUTE #espera N'ado UPDATE con padre VIGENTE bloqueado', N'UPDATE sgspi.activo_documental SET ado_lugar_consulta_ubicacion = N''x'' WHERE ado_codigo = 1;', 50011;

EXECUTE #espera N'plt INSERT con padre CERRADO_EFICAZ bloqueado', N'INSERT sgspi.plan_tratamiento (eia_codigo, plt_naturaleza_evento, etc_codigo, plt_justificacion_estrategia, epr_codigo_residual_meta, eim_codigo_residual_meta, plt_fecha_inicio, plt_fecha_fin, plt_recursos_humanos_tecnicos, plt_recursos_economicos_desc, plt_nombre_indicador_kpi, plt_meta_indicador_kpi) VALUES ((SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-02''), N''RIESGO'', 1, N''j'', 1, 1, ''2026-01-01'', ''2026-12-31'', N''r'', N''r'', N''k'', 100);', 50011;

EXECUTE #espera N'plt UPDATE con padre CERRADO_EFICAZ bloqueado', N'UPDATE sgspi.plan_tratamiento SET plt_justificacion_estrategia = N''x'' WHERE plt_codigo = (SELECT plt_codigo FROM sgspi.plan_tratamiento WHERE eia_codigo = (SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01''));', 50011;

EXECUTE #espera N'act INSERT con padre CERRADO_EFICAZ bloqueado', N'INSERT sgspi.actividad_tratamiento (plt_codigo, act_numero_orden, act_descripcion_actividad, act_fecha_compromiso) VALUES ((SELECT plt_codigo FROM sgspi.plan_tratamiento WHERE eia_codigo = (SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01'')), 2, N''Nueva'', ''2026-07-31'');', 50011;

EXECUTE #espera N'act UPDATE con padre CERRADO_EFICAZ bloqueado', N'UPDATE sgspi.actividad_tratamiento SET act_descripcion_actividad = N''x'' WHERE act_codigo = 1;', 50011;

EXECUTE #espera N'rpp INSERT con padre VIGENTE bloqueado', N'INSERT sgspi.requisito_parte_interesada_proceso_institucional (rpi_codigo, pri_codigo) VALUES (1, (SELECT pri_codigo FROM sgspi.proceso_institucional WHERE pri_identificador = N''P02''));', 50011;

EXECUTE #espera N'rpp UPDATE con padre VIGENTE bloqueado', N'UPDATE sgspi.requisito_parte_interesada_proceso_institucional SET rpp_estado = 0 WHERE rpi_codigo = 1 AND pri_codigo = 1;', 50011;

EXECUTE #espera N'aip INSERT con padre VIGENTE bloqueado', N'INSERT sgspi.activo_informacion_proceso_institucional (aci_codigo, pri_codigo) VALUES (1, (SELECT pri_codigo FROM sgspi.proceso_institucional WHERE pri_identificador = N''P02''));', 50011;

EXECUTE #espera N'aip UPDATE con padre VIGENTE bloqueado', N'UPDATE sgspi.activo_informacion_proceso_institucional SET aip_estado = 1 WHERE aci_codigo = 1 AND pri_codigo = 1;', 50011;

EXECUTE #espera N'ais INSERT con padre VIGENTE bloqueado', N'
BEGIN TRAN;
INSERT dbo.sub_sede (sus_nombre, sed_codigo) VALUES (''Sede Pitalito'', 1);
DECLARE @sus2 INT = SCOPE_IDENTITY();
INSERT sgspi.activo_informacion_sede (aci_codigo, sus_codigo) VALUES ((SELECT aci_codigo FROM sgspi.activo_informacion WHERE aci_codigo_inventario = N''INV-5''), @sus2);', 50011;

EXECUTE #espera N'ais UPDATE con padre VIGENTE bloqueado', N'UPDATE sgspi.activo_informacion_sede SET ais_estado = 0 WHERE aci_codigo = 1 AND sus_codigo = 1;', 50011;

EXECUTE #espera N'air INSERT con padre VIGENTE bloqueado', N'INSERT sgspi.activo_informacion_responsable (aci_codigo, car_codigo, uaa_codigo, air_tipo_responsabilidad) VALUES ((SELECT aci_codigo FROM sgspi.activo_informacion WHERE aci_codigo_inventario = N''INV-5''), 1, 1, N''CUSTODIO'');', 50011;

EXECUTE #espera N'air UPDATE con padre VIGENTE bloqueado', N'UPDATE sgspi.activo_informacion_responsable SET air_estado = 0 WHERE aci_codigo = 1 AND car_codigo = 1 AND uaa_codigo = 1 AND air_tipo_responsabilidad = N''CUSTODIO'';', 50011;

EXECUTE #espera N'ads INSERT con padre VIGENTE bloqueado', N'INSERT sgspi.activo_documental_soporte_registro (ado_codigo, src_codigo) VALUES (1, (SELECT src_codigo FROM sgspi.soporte_registro_catalogo WHERE src_nombre = N''Papel''));', 50011;

EXECUTE #espera N'ads UPDATE con padre VIGENTE bloqueado', N'UPDATE sgspi.activo_documental_soporte_registro SET ads_estado = 0 WHERE ado_codigo = 1 AND src_codigo = 1;', 50011;

EXECUTE #espera N'adm INSERT con padre VIGENTE bloqueado', N'INSERT sgspi.activo_documental_medio_conservacion (ado_codigo, mcc_codigo) VALUES (1, (SELECT mcc_codigo FROM sgspi.medio_conservacion_catalogo WHERE mcc_nombre = N''Nube''));', 50011;

EXECUTE #espera N'adm UPDATE con padre VIGENTE bloqueado', N'UPDATE sgspi.activo_documental_medio_conservacion SET adm_estado = 0 WHERE ado_codigo = 1 AND mcc_codigo = (SELECT mcc_codigo FROM sgspi.medio_conservacion_catalogo WHERE mcc_nombre = N''Servidor institucional'');', 50011;

EXECUTE #espera N'adi INSERT con padre VIGENTE bloqueado', N'INSERT sgspi.activo_documental_idioma (ado_codigo, idi_codigo) VALUES (1, (SELECT idi_codigo FROM sgspi.idioma_catalogo WHERE idi_codigo_iso = N''en''));', 50011;

EXECUTE #espera N'adi UPDATE con padre VIGENTE bloqueado', N'UPDATE sgspi.activo_documental_idioma SET adi_estado = 0 WHERE ado_codigo = 1 AND idi_codigo = (SELECT idi_codigo FROM sgspi.idioma_catalogo WHERE idi_codigo_iso = N''es'');', 50011;

EXECUTE #espera N'adf INSERT con padre VIGENTE bloqueado', N'INSERT sgspi.activo_documental_formato_archivo (ado_codigo, fac_codigo) VALUES (1, (SELECT fac_codigo FROM sgspi.formato_archivo_catalogo WHERE fac_nombre = N''Hoja de cálculo''));', 50011;

EXECUTE #espera N'adf UPDATE con padre VIGENTE bloqueado', N'UPDATE sgspi.activo_documental_formato_archivo SET adf_estado = 0 WHERE ado_codigo = 1 AND fac_codigo = 1;', 50011;

EXECUTE #espera N'adu INSERT con padre VIGENTE bloqueado', N'INSERT sgspi.activo_documental_unidad_productora (ado_codigo, upc_codigo) VALUES (1, (SELECT upc_codigo FROM sgspi.unidad_productora_cuadro_clasificacion_documental WHERE upc_nombre_unidad = N''Secretaría''));', 50011;

EXECUTE #espera N'adu UPDATE con padre VIGENTE bloqueado', N'UPDATE sgspi.activo_documental_unidad_productora SET adu_estado = 0 WHERE ado_codigo = 1 AND upc_codigo = (SELECT upc_codigo FROM sgspi.unidad_productora_cuadro_clasificacion_documental WHERE upc_nombre_unidad = N''Rectoría'');', 50011;

EXECUTE #espera N'ptc INSERT con padre CERRADO_EFICAZ bloqueado', N'INSERT sgspi.plan_tratamiento_control_referencia_normativa (plt_codigo, crn_codigo) VALUES ((SELECT plt_codigo FROM sgspi.plan_tratamiento WHERE eia_codigo = (SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01'')), (SELECT crn_codigo FROM sgspi.control_referencia_normativa WHERE crn_identificador_control = N''A.5.15''));', 50011;

EXECUTE #espera N'ptc UPDATE con padre CERRADO_EFICAZ bloqueado', N'UPDATE sgspi.plan_tratamiento_control_referencia_normativa SET ptc_estado = 0 WHERE plt_codigo = (SELECT plt_codigo FROM sgspi.plan_tratamiento WHERE eia_codigo = (SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01'')) AND crn_codigo = 1;', 50011;

EXECUTE #espera N'Fase 2 [B1] reabrir aci de VIGENTE->EN_REVISION_SGSPI limpia aprobador y aval de Archivo en aci e impide volver a VIGENTE sin re-aval', N'
BEGIN TRAN;
UPDATE sgspi.activo_informacion SET aci_fase_registro = N''EN_REVISION_SGSPI'' WHERE aci_codigo = 1;
IF (SELECT per_codigo_aprobador FROM sgspi.activo_informacion WHERE aci_codigo = 1) IS NOT NULL
    THROW 51000, N''per_codigo_aprobador no se limpió al salir de VIGENTE'', 1;
IF (SELECT per_codigo_revisor_archivo FROM sgspi.activo_informacion WHERE aci_codigo = 1) IS NOT NULL
    THROW 51000, N''per_codigo_revisor_archivo no se limpió al reabrir desde VIGENTE'', 1;
UPDATE sgspi.activo_documental SET ado_lugar_consulta_ubicacion = N''Bóveda sin aval'' WHERE ado_codigo = 1;
UPDATE sgspi.activo_informacion SET aci_fase_registro = N''VIGENTE'' WHERE aci_codigo = 1;', 50020;

EXECUTE #espera N'Reabrir padre VIGENTE->EN_REVISION_ARCHIVO habilita edición de hija y puente y exige re-aval (persona 5) + aprobación (persona 4)', N'
UPDATE sgspi.activo_informacion SET aci_fase_registro = N''EN_REVISION_ARCHIVO'' WHERE aci_codigo = 1;
UPDATE sgspi.activo_documental SET ado_lugar_consulta_ubicacion = N''Bóveda'' WHERE ado_codigo = 1;
UPDATE sgspi.activo_documental_formato_archivo SET adf_estado = 0 WHERE ado_codigo = 1 AND fac_codigo = 2;
EXECUTE sys.sp_set_session_context @key = N''per_codigo'', @value = 5;
UPDATE sgspi.activo_informacion SET aci_fase_registro = N''EN_REVISION_SGSPI'' WHERE aci_codigo = 1;
EXECUTE sys.sp_set_session_context @key = N''per_codigo'', @value = 4;
UPDATE sgspi.activo_informacion SET aci_fase_registro = N''VIGENTE'' WHERE aci_codigo = 1;
UPDATE sgspi.activo_informacion SET aci_fase_registro = N''HISTORICO'' WHERE aci_codigo = 1;
EXECUTE sys.sp_set_session_context @key = N''per_codigo'', @value = 2;', 0;

EXECUTE #espera N'ado UPDATE con padre HISTORICO bloqueado', N'UPDATE sgspi.activo_documental SET ado_lugar_consulta_ubicacion = N''Otro'' WHERE ado_codigo = 1;', 50011;

EXECUTE #espera N'AP-01 tampoco se borran físicamente los catálogos (FK de su aud_*)', N'DELETE sgspi.idioma_catalogo WHERE idi_codigo_iso = N''en'';', 547;

EXECUTE #espera N'C4 alta en vigencia CERRADA bloqueada (D7)', N'
BEGIN TRAN;
INSERT sgspi.periodo_vigencia (pev_anio, pev_fecha_apertura, pev_fecha_cierre, pev_fase_vigencia) VALUES (2025, ''2025-01-01'', ''2025-12-31'', N''CERRADA'');
INSERT sgspi.analisis_contexto_factor (pev_codigo, pri_codigo, fec_codigo, acf_naturaleza_factor, acf_numero_factor, acf_descripcion_situacion, per_codigo_creador)
VALUES ((SELECT pev_codigo FROM sgspi.periodo_vigencia WHERE pev_anio = 2025), 1, 1, N''DEBILIDAD'', 1, N''Vigencia cerrada'', 2);', 50022;


GO
-- ======================= 9. Pruebas Fase 2 (claves filtradas, máquina de estados, firmas, trazabilidad) =======================
EXECUTE #sesion_como 1;

EXECUTE #espera N'Fase 2 AP-22: anular con estado=0 permite recrear clave natural (aci, eac, pai)', N'
BEGIN TRAN;
INSERT sgspi.activo_informacion (aci_codigo_inventario, aci_nombre_activo, tac_codigo, uaa_codigo, aci_clasificacion_transparencia, aci_valor_confidencialidad, aci_valor_integridad, aci_valor_disponibilidad, per_codigo_creador)
VALUES (N''INV-RECREAR'', N''Original'', 3, 1, N''PUBLICA'', 1, 1, 1, 1);
UPDATE sgspi.activo_informacion SET aci_estado = 0 WHERE aci_codigo_inventario = N''INV-RECREAR'';
INSERT sgspi.activo_informacion (aci_codigo_inventario, aci_nombre_activo, tac_codigo, uaa_codigo, aci_clasificacion_transparencia, aci_valor_confidencialidad, aci_valor_integridad, aci_valor_disponibilidad, per_codigo_creador)
VALUES (N''INV-RECREAR'', N''Recreado'', 3, 1, N''PUBLICA'', 1, 1, 1, 1);
UPDATE sgspi.evaluacion_aplicabilidad_control SET eac_estado = 0 WHERE pev_codigo = 1 AND crn_codigo = 1;
INSERT sgspi.evaluacion_aplicabilidad_control (pev_codigo, crn_codigo, car_codigo, pdc_codigo, eac_fase_implementacion) VALUES (1, 1, 1, 1, N''CUMPLE_PARCIAL'');
UPDATE sgspi.parte_interesada SET pai_estado = 0 WHERE pai_codigo = 1;
INSERT sgspi.parte_interesada (pai_nombre, pai_origen) VALUES (N''Estudiantes'', N''INTERNA'');
ROLLBACK;', 0;

EXECUTE #espera N'Fase 2 máquina de estados: transición desactivada (tef_estado=0) rechazada', N'
BEGIN TRAN;
UPDATE sgspi.transicion_estado_flujo SET tef_estado = 0
WHERE  efc_dominio = N''ACF'' AND efc_identificador_origen = N''BORRADOR'' AND efc_identificador_destino = N''EN_VALIDACION_LIDER'';
INSERT sgspi.analisis_contexto_factor (pev_codigo, pri_codigo, fec_codigo, acf_naturaleza_factor, acf_numero_factor, acf_descripcion_situacion, per_codigo_creador)
VALUES (1, 1, 1, N''DEBILIDAD'', 90, N''Prueba tef inactiva'', 1);
UPDATE sgspi.analisis_contexto_factor SET acf_fase_registro = N''EN_VALIDACION_LIDER'' WHERE acf_numero_factor = 90;', 50011;

EXECUTE #espera N'Fase 2 máquina de estados: estado destino inactivo (efc_estado=0) rechazado', N'
BEGIN TRAN;
UPDATE sgspi.estado_flujo_catalogo SET efc_estado = 0
WHERE  efc_dominio = N''ACF'' AND efc_identificador = N''EN_VALIDACION_LIDER'';
INSERT sgspi.analisis_contexto_factor (pev_codigo, pri_codigo, fec_codigo, acf_naturaleza_factor, acf_numero_factor, acf_descripcion_situacion, per_codigo_creador)
VALUES (1, 1, 1, N''DEBILIDAD'', 91, N''Prueba efc inactivo'', 1);
UPDATE sgspi.analisis_contexto_factor SET acf_fase_registro = N''EN_VALIDACION_LIDER'' WHERE acf_numero_factor = 91;', 50011;

EXECUTE #espera N'Fase 2 firmas obsoletas: devolver ado a OBSERVADO limpia aval de Archivo e impide bypass a VIGENTE', N'
BEGIN TRAN;
DECLARE @aci_d INT = (SELECT aci_codigo FROM sgspi.activo_informacion WHERE aci_codigo_inventario = N''INV-D'');
INSERT sgspi.activo_informacion_responsable (aci_codigo, car_codigo, uaa_codigo, air_tipo_responsabilidad)
VALUES (@aci_d, 1, 1, N''PROPIETARIO''), (@aci_d, 1, 1, N''CUSTODIO'');
UPDATE sgspi.activo_informacion SET aci_fase_registro = N''OBSERVADO'' WHERE aci_codigo = @aci_d;
IF (SELECT per_codigo_revisor_archivo FROM sgspi.activo_informacion WHERE aci_codigo = @aci_d) IS NOT NULL
    THROW 51000, N''per_codigo_revisor_archivo no se limpió al pasar a OBSERVADO'', 1;
UPDATE sgspi.activo_informacion SET aci_fase_registro = N''EN_VALIDACION_LIDER'' WHERE aci_codigo = @aci_d;
UPDATE sgspi.activo_informacion SET aci_fase_registro = N''EN_REVISION_SGSPI'' WHERE aci_codigo = @aci_d;
UPDATE sgspi.activo_informacion SET aci_fase_registro = N''VIGENTE'' WHERE aci_codigo = @aci_d;', 50020;

EXECUTE #espera N'Fase 2 firmas obsoletas: reabrir acf y rpi limpia per_codigo_aprobador; devolver eia a OBSERVADO limpia validador/revisor/comite', N'
BEGIN TRAN;
UPDATE sgspi.analisis_contexto_factor SET acf_fase_registro = N''EN_REVISION_SGSPI'' WHERE acf_numero_factor = 1;
IF (SELECT per_codigo_aprobador FROM sgspi.analisis_contexto_factor WHERE acf_numero_factor = 1) IS NOT NULL
    THROW 51000, N''acf.per_codigo_aprobador no se limpió'', 1;
UPDATE sgspi.requisito_parte_interesada SET rpi_fase_registro = N''EN_REVISION_SGSPI'' WHERE rpi_codigo = 1;
IF (SELECT per_codigo_aprobador FROM sgspi.requisito_parte_interesada WHERE rpi_codigo = 1) IS NOT NULL
    THROW 51000, N''rpi.per_codigo_aprobador no se limpió'', 1;
INSERT sgspi.evento_incertidumbre_activo (pev_codigo, eia_numero_evento, eia_naturaleza_evento, pri_codigo, aci_codigo_primario, aci_codigo_soporte, tac_codigo_componente, eia_fuente_generadora, eia_condicion_vulnerabilidad, eia_efecto_consecuencia, eia_escenario_operacional, epr_codigo_inherente, eim_codigo_inherente, per_codigo_creador)
VALUES (1, 95, N''RIESGO'', 1, 1, 2, 1, N''f'', N''v'', N''e'', N''Reapertura firmas'', 5, 5, 1);
DECLARE @eia95 INT = SCOPE_IDENTITY();
INSERT sgspi.plan_tratamiento (eia_codigo, plt_naturaleza_evento, etc_codigo, plt_justificacion_estrategia, epr_codigo_residual_meta, eim_codigo_residual_meta, plt_fecha_inicio, plt_fecha_fin, plt_recursos_humanos_tecnicos, plt_recursos_economicos_desc, plt_nombre_indicador_kpi, plt_meta_indicador_kpi)
VALUES (@eia95, N''RIESGO'', 1, N''j'', 1, 1, ''2026-01-01'', ''2026-12-31'', N''r'', N''r'', N''k'', 100);
DECLARE @plt95 INT = SCOPE_IDENTITY();
INSERT sgspi.actividad_tratamiento (plt_codigo, act_numero_orden, act_descripcion_actividad, car_codigo, uaa_codigo, act_fecha_compromiso) VALUES (@plt95, 1, N''Act 95'', 1, 1, ''2026-06-30'');
INSERT sgspi.plan_tratamiento_control_referencia_normativa (plt_codigo, crn_codigo) VALUES (@plt95, 1);
EXECUTE sys.sp_set_session_context @key = N''per_codigo'', @value = 2;
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''EN_VALIDACION_LIDER'' WHERE eia_codigo = @eia95;
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''EN_REVISION_SGSPI'' WHERE eia_codigo = @eia95;
EXECUTE sys.sp_set_session_context @key = N''per_codigo'', @value = 4;
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''EN_ACEPTACION_COMITE'' WHERE eia_codigo = @eia95;
EXECUTE sys.sp_set_session_context @key = N''per_codigo'', @value = 5;
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''APROBADO_PLANIFICADO'' WHERE eia_codigo = @eia95;
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''OBSERVADO'' WHERE eia_codigo = @eia95;
IF EXISTS (SELECT 1 FROM sgspi.evento_incertidumbre_activo WHERE eia_codigo = @eia95 AND (per_codigo_validador_lider IS NOT NULL OR per_codigo_revisor_sgspi IS NOT NULL OR per_codigo_aprobador_comite IS NOT NULL))
    THROW 51000, N''firmas de eia no se limpiaron al pasar a OBSERVADO'', 1;
ROLLBACK;', 0;

EXECUTE #espera N'Fase 2 TR_eia: rechaza asociación aip inactiva (aip_estado=0)', N'
BEGIN TRAN;
INSERT sgspi.activo_informacion (aci_codigo_inventario, aci_nombre_activo, tac_codigo, uaa_codigo, aci_clasificacion_transparencia, aci_valor_confidencialidad, aci_valor_integridad, aci_valor_disponibilidad, per_codigo_creador)
VALUES (N''INV-AIP0'', N''Activo con aip inactiva'', 3, 1, N''PUBLICA'', 1, 1, 1, 1);
DECLARE @aci_aip0 INT = SCOPE_IDENTITY();
INSERT sgspi.activo_informacion_proceso_institucional (aci_codigo, pri_codigo, aip_estado) VALUES (@aci_aip0, 1, 0);
INSERT sgspi.evento_incertidumbre_activo (pev_codigo, eia_numero_evento, eia_naturaleza_evento, pri_codigo, aci_codigo_primario, aci_codigo_soporte, tac_codigo_componente, eia_fuente_generadora, eia_condicion_vulnerabilidad, eia_efecto_consecuencia, eia_escenario_operacional, epr_codigo_inherente, eim_codigo_inherente, per_codigo_creador)
VALUES (1, 96, N''RIESGO'', 1, @aci_aip0, 2, 1, N''f'', N''v'', N''e'', N''aip inactiva'', 1, 1, 1);', 50011;

EXECUTE #espera N'Fase 2 TR_eia: rechaza activo soporte inactivo (aci_estado=0)', N'
BEGIN TRAN;
INSERT sgspi.activo_informacion (aci_codigo_inventario, aci_nombre_activo, tac_codigo, uaa_codigo, aci_clasificacion_transparencia, aci_valor_confidencialidad, aci_valor_integridad, aci_valor_disponibilidad, per_codigo_creador, aci_estado)
VALUES (N''INV-SOP0'', N''Soporte inactivo'', 4, 1, N''PUBLICA'', 1, 1, 1, 1, 0);
DECLARE @aci_sop0 INT = SCOPE_IDENTITY();
INSERT sgspi.evento_incertidumbre_activo (pev_codigo, eia_numero_evento, eia_naturaleza_evento, pri_codigo, aci_codigo_primario, aci_codigo_soporte, tac_codigo_componente, eia_fuente_generadora, eia_condicion_vulnerabilidad, eia_efecto_consecuencia, eia_escenario_operacional, epr_codigo_inherente, eim_codigo_inherente, per_codigo_creador)
VALUES (1, 97, N''RIESGO'', 1, 1, @aci_sop0, 1, N''f'', N''v'', N''e'', N''soporte inactivo'', 1, 1, 1);', 50011;

EXECUTE #espera N'Fase 2 CHECKs: rechaza presupuesto negativo en plt (CK_plt_presupuesto_no_negativo)', N'
BEGIN TRAN;
INSERT sgspi.evento_incertidumbre_activo (pev_codigo, eia_numero_evento, eia_naturaleza_evento, pri_codigo, aci_codigo_primario, aci_codigo_soporte, tac_codigo_componente, eia_fuente_generadora, eia_condicion_vulnerabilidad, eia_efecto_consecuencia, eia_escenario_operacional, epr_codigo_inherente, eim_codigo_inherente, per_codigo_creador)
VALUES (1, 98, N''RIESGO'', 1, 1, 2, 1, N''f'', N''v'', N''e'', N''Presupuesto neg'', 1, 1, 1);
INSERT sgspi.plan_tratamiento (eia_codigo, plt_naturaleza_evento, etc_codigo, plt_justificacion_estrategia, epr_codigo_residual_meta, eim_codigo_residual_meta, plt_fecha_inicio, plt_fecha_fin, plt_recursos_humanos_tecnicos, plt_recursos_economicos_desc, plt_presupuesto_estimado_cop, plt_nombre_indicador_kpi, plt_meta_indicador_kpi)
VALUES (SCOPE_IDENTITY(), N''RIESGO'', 1, N''j'', 1, 1, ''2026-01-01'', ''2026-12-31'', N''r'', N''r'', -1.00, N''k'', 100);', 547;

EXECUTE #espera N'Fase 2 CHECKs: rechaza pev_anio fuera de 2000..2100 (CK_pev_anio)', N'INSERT sgspi.periodo_vigencia (pev_anio, pev_fecha_apertura) VALUES (1999, ''1999-01-01'');', 547;

EXECUTE #espera N'Fase 2 CHECKs: rechaza enc_anio_edicion fuera de 1970..2100 (CK_enc_anio_edicion)', N'INSERT sgspi.estandar_normativo_catalogo (enc_identificador, enc_familia_norma, enc_nombre, enc_anio_edicion) VALUES (N''TEST-1969'', N''TEST'', N''Norma vieja'', 1969);', 547;

EXECUTE #espera N'Fase 2 no-op UPDATE: deja *_fecha_actualizacion y aud_* intactos', N'
BEGIN TRAN;
DECLARE @eac_id INT = (SELECT MAX(eac_codigo) FROM sgspi.evaluacion_aplicabilidad_control WHERE pev_codigo = 1 AND crn_codigo = 1);
UPDATE sgspi.evaluacion_aplicabilidad_control SET eac_fecha_actualizacion = ''2000-01-01T00:00:00+00:00'' WHERE eac_codigo = @eac_id;
IF @@ROWCOUNT <> 1 THROW 51000, N''precondición eac no encontrada'', 1;
DECLARE @n_aud INT = (SELECT COUNT(*) FROM sgspi.aud_evaluacion_aplicabilidad_control WHERE eac_codigo = @eac_id);
UPDATE sgspi.evaluacion_aplicabilidad_control SET eac_observaciones_auditoria = eac_observaciones_auditoria WHERE eac_codigo = @eac_id;
IF @@ROWCOUNT <> 1
   OR (SELECT eac_fecha_actualizacion FROM sgspi.evaluacion_aplicabilidad_control WHERE eac_codigo = @eac_id) <> ''2000-01-01T00:00:00+00:00''
   OR (SELECT COUNT(*) FROM sgspi.aud_evaluacion_aplicabilidad_control WHERE eac_codigo = @eac_id) <> @n_aud
    THROW 51000, N''no-op UPDATE alteró eac_fecha_actualizacion o aud_evaluacion_aplicabilidad_control'', 1;
ROLLBACK;', 0;

EXECUTE #espera N'Fase 1 v2.4 identidad: usuario inactivo (state=0), persona=0 o uaa=0 devuelven 0 filas en usp_obtener_contexto_usuario', N'
BEGIN TRAN;
DECLARE @ctx_chk TABLE (per_codigo INT, uid BIGINT, nombre_completo NVARCHAR(500), gru_id NVARCHAR(100), uaa_codigo INT, pri_codigo INT);
UPDATE dbo.usuario_administrativos SET state = 0 WHERE us = ''admin_prueba'';
INSERT @ctx_chk EXECUTE sgspi.usp_obtener_contexto_usuario @us = ''admin_prueba'';
IF EXISTS (SELECT 1 FROM @ctx_chk) THROW 51000, N''usp_obtener_contexto_usuario resolvió cuenta state=0'', 1;
UPDATE dbo.usuario_administrativos SET state = 1 WHERE us = ''admin_prueba'';
UPDATE dbo.persona SET per_estado = 0 WHERE per_codigo = 2;
INSERT @ctx_chk EXECUTE sgspi.usp_obtener_contexto_usuario @us = ''admin_prueba'';
IF EXISTS (SELECT 1 FROM @ctx_chk) THROW 51000, N''usp_obtener_contexto_usuario resolvió persona per_estado=0'', 1;
UPDATE dbo.persona SET per_estado = 1 WHERE per_codigo = 2;
UPDATE dbo.uaa SET uaa_estado = 0 WHERE uaa_codigo = 1;
INSERT @ctx_chk EXECUTE sgspi.usp_obtener_contexto_usuario @us = ''admin_prueba'';
IF EXISTS (SELECT 1 FROM @ctx_chk) THROW 51000, N''usp_obtener_contexto_usuario resolvió uaa_estado=0'', 1;
ROLLBACK;', 0;

EXECUTE #espera N'Fase 2 alcance: persona o UAA inactiva (per_estado=0 / uaa_estado=0) sale de vw_usuario_rol_alcance_sgspi', N'
BEGIN TRAN;
IF NOT EXISTS (SELECT 1 FROM sgspi.vw_usuario_rol_alcance_sgspi WHERE per_codigo = 2 AND uaa_codigo = 1)
    THROW 51000, N''precondición vw_usuario_rol_alcance_sgspi vacía'', 1;
UPDATE dbo.persona SET per_estado = 0 WHERE per_codigo = 2;
IF EXISTS (SELECT 1 FROM sgspi.vw_usuario_rol_alcance_sgspi WHERE per_codigo = 2)
    THROW 51000, N''persona con per_estado=0 siguió en vw_usuario_rol_alcance_sgspi'', 1;
UPDATE dbo.persona SET per_estado = 1 WHERE per_codigo = 2;
UPDATE dbo.uaa SET uaa_estado = 0 WHERE uaa_codigo = 1;
IF EXISTS (SELECT 1 FROM sgspi.vw_usuario_rol_alcance_sgspi WHERE uaa_codigo = 1)
    THROW 51000, N''uaa con uaa_estado=0 siguió en vw_usuario_rol_alcance_sgspi'', 1;
ROLLBACK;', 0;


GO
-- ======================= 10. Pruebas Fase 3 (consolidación de triggers, ROWVERSION, sga, vistas, RCSI) =======================
EXECUTE #sesion_como 1;

EXECUTE #espera N'Fase 3 triggers: 99 triggers en [sgspi] y 0 triggers TR_*_bloquear_padre_no_editable', N'
IF (SELECT COUNT(*) FROM sys.triggers AS tr INNER JOIN sys.tables AS t ON t.object_id = tr.parent_id WHERE t.schema_id = SCHEMA_ID(N''sgspi'')) <> 99
   OR EXISTS (SELECT 1 FROM sys.triggers AS tr INNER JOIN sys.tables AS t ON t.object_id = tr.parent_id WHERE t.schema_id = SCHEMA_ID(N''sgspi'') AND tr.name LIKE N''TR[_]%[_]bloquear[_]padre[_]no[_]editable'')
    THROW 51000, N''conteo de triggers inesperado o quedan triggers bloquear_padre_no_editable'', 1;', 0;

EXECUTE #espera N'Fase 3 single UPDATE: sin doble UPDATE interno ni doble bump de ROWVERSION en TR_acf, TR_rpi, TR_aci, TR_eia y TR_plt', N'
-- Verifica que cada trigger combine fecha + firmas en 1 solo UPDATE sobre su tabla en la rama UPDATE
IF EXISTS (SELECT 1
           FROM   (VALUES (N''sgspi.TR_acf_integridad_y_actualizacion'', 1),
                          (N''sgspi.TR_rpi_integridad_y_actualizacion'', 1),
                          (N''sgspi.TR_aci_integridad_y_actualizacion'', 1),
                          (N''sgspi.TR_eia_integridad_y_actualizacion'', 1),
                          (N''sgspi.TR_plt_integridad_y_actualizacion'', 2)) AS v(nombre, max_updates) -- TR_plt: 1 en rama UPDATE + 1 en rama INSERT
           WHERE  (LEN(OBJECT_DEFINITION(OBJECT_ID(v.nombre, N''TR'')))
                   - LEN(REPLACE(OBJECT_DEFINITION(OBJECT_ID(v.nombre, N''TR'')), N''UPDATE t'', N''''))) / LEN(N''UPDATE t'') > v.max_updates)
    THROW 51000, N''algún trigger mantiene doble UPDATE sobre su propia tabla'', 1;
-- Verifica en ejecución que fecha + firma/dictamen se actualizan juntas en una sola escritura interna
BEGIN TRAN;
UPDATE sgspi.analisis_contexto_factor SET acf_fase_registro = N''EN_REVISION_SGSPI'' WHERE acf_numero_factor = 1;
IF (SELECT per_codigo_aprobador FROM sgspi.analisis_contexto_factor WHERE acf_numero_factor = 1) IS NOT NULL
    THROW 51000, N''TR_acf no limpió per_codigo_aprobador'', 1;
UPDATE sgspi.requisito_parte_interesada SET rpi_fase_registro = N''EN_REVISION_SGSPI'' WHERE rpi_codigo = 1;
IF (SELECT per_codigo_aprobador FROM sgspi.requisito_parte_interesada WHERE rpi_codigo = 1) IS NOT NULL
    THROW 51000, N''TR_rpi no limpió per_codigo_aprobador'', 1;
UPDATE sgspi.activo_informacion SET aci_fase_registro = N''EN_REVISION_SGSPI'' WHERE aci_codigo_inventario = N''INV-5'';
IF (SELECT per_codigo_aprobador FROM sgspi.activo_informacion WHERE aci_codigo_inventario = N''INV-5'') IS NOT NULL
    THROW 51000, N''TR_aci no limpió per_codigo_aprobador'', 1;
INSERT sgspi.evento_incertidumbre_activo (pev_codigo, eia_numero_evento, eia_naturaleza_evento, pri_codigo, aci_codigo_primario, aci_codigo_soporte, tac_codigo_componente, eia_fuente_generadora, eia_condicion_vulnerabilidad, eia_efecto_consecuencia, eia_escenario_operacional, epr_codigo_inherente, eim_codigo_inherente, per_codigo_creador)
VALUES (1, 99, N''RIESGO'', 1, 1, 2, 1, N''f'', N''v'', N''e'', N''Single UPDATE'', 1, 1, 1);
DECLARE @eia INT = SCOPE_IDENTITY();
INSERT sgspi.plan_tratamiento (eia_codigo, plt_naturaleza_evento, etc_codigo, plt_justificacion_estrategia, epr_codigo_residual_meta, eim_codigo_residual_meta, plt_fecha_inicio, plt_fecha_fin, plt_recursos_humanos_tecnicos, plt_recursos_economicos_desc, plt_nombre_indicador_kpi, plt_meta_indicador_kpi)
VALUES (@eia, N''RIESGO'', 1, N''j'', 1, 1, ''2026-01-01'', ''2026-12-31'', N''r'', N''r'', N''k'', 100);
DECLARE @plt INT = SCOPE_IDENTITY();
INSERT sgspi.actividad_tratamiento (plt_codigo, act_numero_orden, act_descripcion_actividad, car_codigo, uaa_codigo, act_fecha_compromiso)
VALUES (@plt, 1, N''Act 1'', 1, 1, ''2026-06-30'');
DECLARE @act INT = SCOPE_IDENTITY();
INSERT sgspi.plan_tratamiento_control_referencia_normativa (plt_codigo, crn_codigo) VALUES (@plt, 1);
INSERT sgspi.seguimiento_actividad (act_codigo, per_codigo, sga_porcentaje_reportado, sga_descripcion_avance) VALUES (@act, 1, 100, N''Completada'');
UPDATE sgspi.actividad_tratamiento SET act_fase_actividad = N''EN_CURSO'' WHERE act_codigo = @act;
UPDATE sgspi.actividad_tratamiento SET act_fase_actividad = N''COMPLETADA'' WHERE act_codigo = @act;
UPDATE sgspi.plan_tratamiento SET plt_fecha_actualizacion = ''2000-01-01T00:00:00+00:00'' WHERE plt_codigo = @plt;
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''EN_VALIDACION_LIDER'' WHERE eia_codigo = @eia;
UPDATE sgspi.evento_incertidumbre_activo SET eia_fecha_actualizacion = ''2000-01-01T00:00:00+00:00'' WHERE eia_codigo = @eia;
EXECUTE sys.sp_set_session_context @key = N''per_codigo'', @value = 2;
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''EN_REVISION_SGSPI'' WHERE eia_codigo = @eia;
IF NOT EXISTS (SELECT 1 FROM sgspi.evento_incertidumbre_activo WHERE eia_codigo = @eia AND per_codigo_validador_lider = 2 AND eia_fecha_actualizacion > ''2000-01-01T00:00:00+00:00'')
    THROW 51000, N''TR_eia no actualizó firma y fecha juntas'', 1;
EXECUTE sys.sp_set_session_context @key = N''per_codigo'', @value = 4;
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''APROBADO_PLANIFICADO'' WHERE eia_codigo = @eia;
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''EN_EJECUCION'' WHERE eia_codigo = @eia;
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''EN_EVALUACION_EFICACIA'' WHERE eia_codigo = @eia;
EXECUTE sys.sp_set_session_context @key = N''per_codigo'', @value = 3;
UPDATE sgspi.plan_tratamiento SET plt_es_tratamiento_eficaz = 1, plt_dictamen_eficacia = N''Eficaz'', per_codigo_evaluador = 3, plt_fecha_evaluacion_eficacia = ''2020-01-01T00:00:00+00:00'' WHERE plt_codigo = @plt;
IF NOT EXISTS (SELECT 1 FROM sgspi.plan_tratamiento WHERE plt_codigo = @plt AND plt_fecha_actualizacion > ''2000-01-01T00:00:00+00:00'' AND plt_fecha_evaluacion_eficacia > ''2020-01-01T00:00:00+00:00'')
    THROW 51000, N''TR_plt no actualizó fecha_actualizacion y fecha_evaluacion_eficacia juntas'', 1;
ROLLBACK;', 0;

EXECUTE #espera N'Fase 3 TR_sga: seguimiento inactivo (sga_estado=0) no sobrescribe act_porcentaje_avance y converge al mayor sga_codigo activo', N'
BEGIN TRAN;
INSERT sgspi.evento_incertidumbre_activo (pev_codigo, eia_numero_evento, eia_naturaleza_evento, pri_codigo, aci_codigo_primario, aci_codigo_soporte, tac_codigo_componente, eia_fuente_generadora, eia_condicion_vulnerabilidad, eia_efecto_consecuencia, eia_escenario_operacional, epr_codigo_inherente, eim_codigo_inherente, per_codigo_creador)
VALUES (1, 99, N''RIESGO'', 1, 1, 2, 1, N''f'', N''v'', N''e'', N''Avance sga'', 1, 1, 1);
DECLARE @eia INT = SCOPE_IDENTITY();
INSERT sgspi.plan_tratamiento (eia_codigo, plt_naturaleza_evento, etc_codigo, plt_justificacion_estrategia, epr_codigo_residual_meta, eim_codigo_residual_meta, plt_fecha_inicio, plt_fecha_fin, plt_recursos_humanos_tecnicos, plt_recursos_economicos_desc, plt_nombre_indicador_kpi, plt_meta_indicador_kpi)
VALUES (@eia, N''RIESGO'', 1, N''j'', 1, 1, ''2026-01-01'', ''2026-12-31'', N''r'', N''r'', N''k'', 100);
DECLARE @plt INT = SCOPE_IDENTITY();
INSERT sgspi.actividad_tratamiento (plt_codigo, act_numero_orden, act_descripcion_actividad, car_codigo, uaa_codigo, act_fecha_compromiso)
VALUES (@plt, 1, N''Act sga'', 1, 1, ''2026-06-30'');
DECLARE @act INT = SCOPE_IDENTITY();
INSERT sgspi.seguimiento_actividad (act_codigo, per_codigo, sga_porcentaje_reportado, sga_descripcion_avance) VALUES (@act, 1, 60, N''Avance 60'');
INSERT sgspi.seguimiento_actividad (act_codigo, per_codigo, sga_porcentaje_reportado, sga_descripcion_avance, sga_estado) VALUES (@act, 1, 10, N''Inactivo 10'', 0);
IF (SELECT act_porcentaje_avance FROM sgspi.actividad_tratamiento WHERE act_codigo = @act) <> 60
    THROW 51000, N''seguimiento inactivo alteró act_porcentaje_avance'', 1;
INSERT sgspi.seguimiento_actividad (act_codigo, per_codigo, sga_porcentaje_reportado, sga_descripcion_avance) VALUES (@act, 1, 90, N''Avance 90'');
DECLARE @sga90 INT = SCOPE_IDENTITY();
IF (SELECT act_porcentaje_avance FROM sgspi.actividad_tratamiento WHERE act_codigo = @act) <> 90
    THROW 51000, N''avance no subió a 90'', 1;
UPDATE sgspi.seguimiento_actividad SET sga_estado = 0 WHERE sga_codigo = @sga90;
IF (SELECT act_porcentaje_avance FROM sgspi.actividad_tratamiento WHERE act_codigo = @act) <> 60
    THROW 51000, N''al desactivar sga 90 no volvió a 60'', 1;
ROLLBACK;', 0;

EXECUTE #espera N'Fase 3 STRING_AGG NVARCHAR(MAX): soporta > 4500 caracteres (> 8000 bytes) en vistas sin Error 9829', N'
BEGIN TRAN;
DECLARE @n INT = 1;
WHILE @n <= 120
    BEGIN
        INSERT sgspi.atributo_control_catalogo (aac_tipo_atributo, aac_valor)
        VALUES (N''TIPO_CONTROL'', CONCAT(N''ATRIBUTO_LARGO_PRUEBA_9829_'', RIGHT(CONCAT(N''000'', @n), 3), N''_XXXXXXXXXXXXXXX''));
        INSERT sgspi.control_referencia_normativa_atributo (crn_codigo, aac_codigo) VALUES (1, SCOPE_IDENTITY());
        SET @n += 1;
    END
IF (SELECT LEN(tipo_control) FROM sgspi.vw_controles_atributos_iso27002 WHERE crn_codigo = 1) <= 4500
    THROW 51000, N''vw_controles_atributos_iso27002 no superó 4500 caracteres'', 1;
ROLLBACK;', 0;

EXECUTE #espera N'Fase 3 vistas AP-22: excluyen inactivos en vw_usuario_rol_alcance_sgspi (pr), vw_controles_atributos_iso27002 (aac/crn/enc) y vw_desglose_ccd_trd_mr04 (ado/upc/sdo/sbd)', N'
BEGIN TRAN;
-- 1) vw_usuario_rol_alcance_sgspi: proceso insertado inactivo asociado a UAA 1 no proyecta pri_codigo
INSERT sgspi.proceso_institucional (pri_identificador, pri_nombre, tpr_codigo, pri_estado) VALUES (N''P_INACT'', N''Proceso Inactivo'', 1, 0);
DECLARE @pri_inact INT = SCOPE_IDENTITY();
INSERT sgspi.proceso_institucional_uaa (pri_codigo, uaa_codigo) VALUES (@pri_inact, 1);
IF EXISTS (SELECT 1 FROM sgspi.vw_usuario_rol_alcance_sgspi WHERE pri_codigo = @pri_inact)
    THROW 51000, N''vw_usuario_rol_alcance_sgspi no filtró pr.pri_estado'', 1;
-- 2) vw_controles_atributos_iso27002 (aac, crn, enc)
INSERT sgspi.atributo_control_catalogo (aac_tipo_atributo, aac_valor, aac_estado) VALUES (N''TIPO_CONTROL'', N''INACTIVO_F3'', 0);
INSERT sgspi.control_referencia_normativa_atributo (crn_codigo, aac_codigo) VALUES (1, SCOPE_IDENTITY());
IF EXISTS (SELECT 1 FROM sgspi.vw_controles_atributos_iso27002 WHERE crn_codigo = 1 AND tipo_control LIKE N''%INACTIVO_F3%'')
    THROW 51000, N''vw_controles_atributos_iso27002 incluyó aac inactivo'', 1;
UPDATE sgspi.control_referencia_normativa SET crn_estado = 0 WHERE crn_codigo = 1;
IF EXISTS (SELECT 1 FROM sgspi.vw_controles_atributos_iso27002 WHERE crn_codigo = 1)
    THROW 51000, N''vw_controles_atributos_iso27002 incluyó crn inactivo'', 1;
UPDATE sgspi.control_referencia_normativa SET crn_estado = 1 WHERE crn_codigo = 1;
UPDATE sgspi.estandar_normativo_catalogo SET enc_estado = 0 WHERE enc_codigo = (SELECT enc_codigo FROM sgspi.control_referencia_normativa WHERE crn_codigo = 1);
IF EXISTS (SELECT 1 FROM sgspi.vw_controles_atributos_iso27002 WHERE crn_codigo = 1)
    THROW 51000, N''vw_controles_atributos_iso27002 incluyó enc inactivo'', 1;
-- 3) vw_desglose_ccd_trd_mr04 (sbd, sdo, upc, ado; usando catálogos inactivos creados para simular histórico)
INSERT sgspi.serie_documental_catalogo (sdo_numero_ccd, sdo_nombre_serie, sdo_estado) VALUES (99, N''SERIE INACTIVA'', 0);
DECLARE @sdo_inact SMALLINT = SCOPE_IDENTITY();
INSERT sgspi.unidad_productora_cuadro_clasificacion_documental (upc_nodo_jerarquico, upc_nombre_unidad, upc_estado) VALUES (hierarchyid::Parse(''/99/''), N''UPC Inactiva'', 0);
DECLARE @upc_inact INT = SCOPE_IDENTITY();
INSERT sgspi.activo_informacion (aci_codigo_inventario, aci_nombre_activo, tac_codigo, uaa_codigo, aci_clasificacion_transparencia, aci_valor_confidencialidad, aci_valor_integridad, aci_valor_disponibilidad, per_codigo_creador)
VALUES (N''INV-F3DOC'', N''Doc F3'', 3, 1, N''PUBLICA'', 1, 1, 1, 1);
DECLARE @ado INT = SCOPE_IDENTITY();
INSERT sgspi.activo_documental (ado_codigo, pev_codigo, sdo_codigo, sbd_codigo, pdc_codigo, epc_codigo, ado_lugar_consulta_ubicacion)
VALUES (@ado, 1, 1, 1, 1, 1, N''Archivo'');
DECLARE @upc INT = (SELECT TOP (1) upc_codigo FROM sgspi.unidad_productora_cuadro_clasificacion_documental WHERE upc_estado = 1 ORDER BY upc_codigo);
INSERT sgspi.activo_documental_unidad_productora (ado_codigo, upc_codigo) VALUES (@ado, @upc), (@ado, @upc_inact);
IF NOT EXISTS (SELECT 1 FROM sgspi.vw_desglose_ccd_trd_mr04 WHERE ado_codigo = @ado AND upc_codigo = @upc AND sbd_nombre_subserie IS NOT NULL)
    THROW 51000, N''precondición vw_desglose_ccd_trd_mr04 vacía'', 1;
IF EXISTS (SELECT 1 FROM sgspi.vw_desglose_ccd_trd_mr04 WHERE ado_codigo = @ado AND upc_codigo = @upc_inact)
    THROW 51000, N''vw_desglose_ccd_trd_mr04 incluyó upc inactiva'', 1;
UPDATE sgspi.subserie_documental_catalogo SET sbd_estado = 0 WHERE sbd_codigo = 1;
IF NOT EXISTS (SELECT 1 FROM sgspi.vw_desglose_ccd_trd_mr04 WHERE ado_codigo = @ado AND sbd_nombre_subserie IS NULL)
    THROW 51000, N''vw_desglose_ccd_trd_mr04 no ocultó sbd inactiva'', 1;
UPDATE sgspi.subserie_documental_catalogo SET sbd_estado = 1 WHERE sbd_codigo = 1;
UPDATE sgspi.activo_documental SET sdo_codigo = @sdo_inact, sbd_codigo = NULL WHERE ado_codigo = @ado;
IF EXISTS (SELECT 1 FROM sgspi.vw_desglose_ccd_trd_mr04 WHERE ado_codigo = @ado)
    THROW 51000, N''vw_desglose_ccd_trd_mr04 incluyó sdo inactiva'', 1;
UPDATE sgspi.activo_documental SET sdo_codigo = 1, sbd_codigo = 1, ado_estado = 0 WHERE ado_codigo = @ado;
IF EXISTS (SELECT 1 FROM sgspi.vw_desglose_ccd_trd_mr04 WHERE ado_codigo = @ado)
    THROW 51000, N''vw_desglose_ccd_trd_mr04 incluyó ado inactivo'', 1;
ROLLBACK;', 0;

EXECUTE #espera N'Fase 3 RCSI: base desechable tiene READ_COMMITTED_SNAPSHOT ON', N'
IF (SELECT is_read_committed_snapshot_on FROM sys.databases WHERE database_id = DB_ID()) <> 1
    THROW 51000, N''READ_COMMITTED_SNAPSHOT no está habilitado'', 1;', 0;


GO
-- ======================= 11. Pruebas Fase 4 (tipos BIGINT, PERSISTED, índices, compresión y particionamiento) =======================
EXECUTE #sesion_como 1;

EXECUTE #espera N'Fase 4 tipos: PK de las 49 tablas aud_* en BIGINT; 9 etiquetas virtuales y plt_porcentaje_cumplimiento_kpi PERSISTED', N'
IF (SELECT COUNT(*)
    FROM   sys.tables AS t
           INNER JOIN sys.columns AS c ON c.object_id = t.object_id AND c.column_id = 1
    WHERE  t.schema_id = SCHEMA_ID(N''sgspi'')
           AND t.name LIKE N''aud[_]%''
           AND c.system_type_id = 127) <> 49 -- 127 = BIGINT
    THROW 51000, N''no todas las 49 tablas aud_* tienen PK BIGINT'', 1;
IF EXISTS (SELECT 1
           FROM   sys.computed_columns AS cc
           WHERE  cc.object_id IN (OBJECT_ID(N''sgspi.analisis_contexto_factor''), OBJECT_ID(N''sgspi.requisito_parte_interesada''), OBJECT_ID(N''sgspi.activo_informacion''))
                  AND cc.name IN (N''acf_nivel_prioridad'', N''rpi_nivel_poder'', N''rpi_nivel_interes'', N''rpi_clasificacion_impacto'',
                                  N''rpi_nivel_cumplimiento'', N''rpi_prioridad_accion'', N''aci_nivel_confidencialidad'', N''aci_nivel_integridad'', N''aci_nivel_disponibilidad'')
                  AND cc.is_persisted <> 0)
    THROW 51000, N''alguna de las 9 etiquetas de presentación sigue PERSISTED'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.computed_columns WHERE object_id = OBJECT_ID(N''sgspi.plan_tratamiento'') AND name = N''plt_porcentaje_cumplimiento_kpi'' AND is_persisted = 1)
    THROW 51000, N''plt_porcentaje_cumplimiento_kpi no es PERSISTED'', 1;', 0;

EXECUTE #espera N'Fase 4 CK_eia_numero_evento: soporta hasta 9999 (RA-1500) y rechaza 10000', N'
BEGIN TRAN;
INSERT sgspi.evento_incertidumbre_activo (pev_codigo, eia_numero_evento, eia_naturaleza_evento, pri_codigo, aci_codigo_primario, aci_codigo_soporte, tac_codigo_componente, eia_fuente_generadora, eia_condicion_vulnerabilidad, eia_efecto_consecuencia, eia_escenario_operacional, epr_codigo_inherente, eim_codigo_inherente, per_codigo_creador)
VALUES (1, 1500, N''RIESGO'', 1, 1, 2, 1, N''f'', N''v'', N''e'', N''Evento 4 dígitos'', 1, 1, 1);
IF NOT EXISTS (SELECT 1 FROM sgspi.evento_incertidumbre_activo WHERE eia_numero_evento = 1500 AND eia_identificador_evento = N''RA-1500'')
    THROW 51000, N''eia_identificador_evento no formateó RA-1500'', 1;
ROLLBACK;', 0;

EXECUTE #espera N'Fase 4 CK_eia_numero_evento: rechaza > 9999', N'
INSERT sgspi.evento_incertidumbre_activo (pev_codigo, eia_numero_evento, eia_naturaleza_evento, pri_codigo, aci_codigo_primario, aci_codigo_soporte, tac_codigo_componente, eia_fuente_generadora, eia_condicion_vulnerabilidad, eia_efecto_consecuencia, eia_escenario_operacional, epr_codigo_inherente, eim_codigo_inherente, per_codigo_creador)
VALUES (1, 10000, N''RIESGO'', 1, 1, 2, 1, N''f'', N''v'', N''e'', N''Fuera de rango'', 1, 1, 1);', 547;

EXECUTE #espera N'Fase 4 [D1][D2] índices de ruta caliente presentes, IX_*_fase_estado lideran con fase (no efc_dominio) y redundantes podados', N'
IF EXISTS (SELECT 1
           FROM   (VALUES (N''sgspi.plan_tratamiento'', N''IX_plt_eia_codigo_naturaleza''),
                          (N''sgspi.sistema_informacion_ficha'', N''IX_sif_aci_codigo''),
                          (N''sgspi.analisis_contexto_factor'', N''IX_acf_fase_estado''),
                          (N''sgspi.analisis_contexto_factor'', N''IX_acf_pev_estado''),
                          (N''sgspi.requisito_parte_interesada'', N''IX_rpi_fase_estado''),
                          (N''sgspi.activo_informacion'', N''IX_aci_fase_estado''),
                          (N''sgspi.evento_incertidumbre_activo'', N''IX_eia_fase_estado''),
                          (N''sgspi.evento_incertidumbre_activo'', N''IX_eia_pev_estado''),
                          (N''sgspi.actividad_tratamiento'', N''IX_act_fase_estado''),
                          (N''sgspi.actividad_tratamiento'', N''IX_act_plt_codigo''),
                          (N''sgspi.unidad_productora_cuadro_clasificacion_documental'', N''IX_upc_nodo_cobertura''),
                          (N''sgspi.activo_informacion_responsable'', N''IX_air_aci_tipo_activo''),
                          (N''sgspi.seguimiento_actividad'', N''IX_sga_act_codigo'')) AS v(tabla, indice)
           WHERE  NOT EXISTS (SELECT 1 FROM sys.indexes AS ix WHERE ix.object_id = OBJECT_ID(v.tabla) AND ix.name = v.indice AND ix.is_disabled = 0))
    THROW 51000, N''falta algún índice de ruta caliente requerido en v2.3'', 1;
-- D1: ninguno de los 5 IX_*_fase_estado lidera con efc_dominio
IF EXISTS (SELECT 1
           FROM   sys.indexes AS ix
                  INNER JOIN sys.index_columns AS ic ON ic.object_id = ix.object_id AND ic.index_id = ix.index_id AND ic.key_ordinal = 1
                  INNER JOIN sys.columns AS c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
           WHERE  ix.name IN (N''IX_acf_fase_estado'', N''IX_rpi_fase_estado'', N''IX_aci_fase_estado'', N''IX_eia_fase_estado'', N''IX_act_fase_estado'')
                  AND c.name = N''efc_dominio'')
    THROW 51000, N''algún índice IX_*_fase_estado aún lidera con la constante efc_dominio'', 1;
-- D2: índices redundantes / baja selectividad podados
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name IN (N''IX_mvr_eim_codigo'', N''IX_mvr_zrc_codigo'', N''IX_tef_estado_destino'',
                                                    N''IX_pri_tpr_codigo'', N''IX_pri_uaa_codigo_lider'', N''IX_pri_car_codigo_lider'',
                                                    N''IX_eia_tac_codigo_componente'', N''IX_eia_valoracion_inherente'',
                                                    N''IX_eia_per_codigo_creador'', N''IX_aci_cet_codigo'', N''IX_ado_pdc_codigo'', N''IX_apv_per_codigo''))
    THROW 51000, N''no se podaron los índices redundantes de D2'', 1;', 0;

EXECUTE #espera N'Fase 4 [D3][D4] compresión ROW en 9 operativas + NC, PAGE solo en 9 aud_* operativas y sin particionamiento prematuro', N'
-- 1) Las 9 tablas operativas y TODOS sus índices (clustered, NC, UX, UQ) con DATA_COMPRESSION = ROW
IF EXISTS (SELECT 1
           FROM   sys.tables AS t
                  INNER JOIN sys.indexes AS ix ON ix.object_id = t.object_id AND ix.index_id >= 1
                  INNER JOIN sys.partitions AS p ON p.object_id = ix.object_id AND p.index_id = ix.index_id
           WHERE  t.schema_id = SCHEMA_ID(N''sgspi'')
                  AND t.name IN (N''analisis_contexto_factor'', N''requisito_parte_interesada'', N''activo_informacion'', N''activo_documental'',
                                 N''evento_incertidumbre_activo'', N''plan_tratamiento'', N''actividad_tratamiento'', N''seguimiento_actividad'', N''evaluacion_aplicabilidad_control'')
                  AND p.data_compression_desc <> N''ROW'')
    THROW 51000, N''alguna tabla o índice de las 9 operativas no tiene DATA_COMPRESSION = ROW'', 1;
-- 2) Las 9 aud_* operativas y sus índices con PAGE compression; las 40 aud_* de catálogos/puente con NONE
IF EXISTS (SELECT 1
           FROM   sys.tables AS t
                  INNER JOIN sys.indexes AS ix ON ix.object_id = t.object_id AND ix.index_id >= 1
                  INNER JOIN sys.partitions AS p ON p.object_id = ix.object_id AND p.index_id = ix.index_id
           WHERE  t.schema_id = SCHEMA_ID(N''sgspi'')
                  AND t.name IN (N''aud_analisis_contexto_factor'', N''aud_requisito_parte_interesada'', N''aud_activo_informacion'', N''aud_activo_documental'',
                                 N''aud_evento_incertidumbre_activo'', N''aud_plan_tratamiento'', N''aud_actividad_tratamiento'', N''aud_seguimiento_actividad'', N''aud_evaluacion_aplicabilidad_control'')
                  AND p.data_compression_desc <> N''PAGE'')
    THROW 51000, N''alguna de las 9 aud_* operativas no tiene DATA_COMPRESSION = PAGE'', 1;
IF EXISTS (SELECT 1
           FROM   sys.tables AS t
                  INNER JOIN sys.indexes AS ix ON ix.object_id = t.object_id AND ix.index_id >= 1
                  INNER JOIN sys.partitions AS p ON p.object_id = ix.object_id AND p.index_id = ix.index_id
           WHERE  t.schema_id = SCHEMA_ID(N''sgspi'')
                  AND t.name LIKE N''aud[_]%''
                  AND t.name NOT IN (N''aud_analisis_contexto_factor'', N''aud_requisito_parte_interesada'', N''aud_activo_informacion'', N''aud_activo_documental'',
                                     N''aud_evento_incertidumbre_activo'', N''aud_plan_tratamiento'', N''aud_actividad_tratamiento'', N''aud_seguimiento_actividad'', N''aud_evaluacion_aplicabilidad_control'')
                  AND p.data_compression_desc <> N''NONE'')
    THROW 51000, N''alguna aud_* de catálogo/puente conserva compresión PAGE innecesaria'', 1;
-- 3) D3: cero esquemas o funciones de partición prematuras
IF EXISTS (SELECT 1 FROM sys.partition_schemes WHERE name = N''PS_sgspi_aud_anio'')
   OR EXISTS (SELECT 1 FROM sys.partition_functions WHERE name = N''PF_sgspi_aud_anio'')
    THROW 51000, N''persiste el particionamiento prematuro PS_sgspi_aud_anio / PF_sgspi_aud_anio'', 1;', 0;


GO
-- ======================= 12. Pruebas v2.3/v2.4 Fase 1 Spring Boot 4 (A1–A5, B1–B5, C1–C5) =======================
EXECUTE #sesion_como 1;

-- --- A1/A2 (v2.4): pool único sin Msg 230 por columna ni políticas RLS ---
EXECUTE #espera N'v2.4 A1: grupo_sgspi_ejecucion lee plt_presupuesto_estimado_cop, eac_observaciones_auditoria y vistas sin Msg 230 ni 229', N'
EXECUTE AS USER = N''sgspi_prueba_ejecucion'';
SELECT TOP (1) plt_presupuesto_estimado_cop INTO #a1_plt FROM sgspi.plan_tratamiento;
SELECT TOP (1) eac_codigo, eac_fase_implementacion, eac_observaciones_auditoria INTO #a1_eac FROM sgspi.evaluacion_aplicabilidad_control;
SELECT TOP (1) * INTO #a1_dofa FROM sgspi.vw_consolidado_dofa;', 0;

EXECUTE #espera N'v2.4 A2: 0 políticas y 0 predicados RLS activos en esquema sgspi (alcance UAA delega a Spring Security 7)', N'
IF EXISTS (SELECT 1 FROM sys.security_policies WHERE schema_id = SCHEMA_ID(N''sgspi''))
   OR EXISTS (SELECT 1 FROM sys.security_predicates AS sp INNER JOIN sys.objects AS o ON o.object_id = sp.target_object_id WHERE o.schema_id = SCHEMA_ID(N''sgspi''))
    THROW 51000, N''persisten políticas o predicados RLS en esquema sgspi'', 1;', 0;

-- --- A4 (v2.4): Enmascaramiento de ubicación en vista pública de transparencia ---
EXECUTE #espera N'v2.4 A4: vista pública oculta PII/ICC/reserva, filtra VIGENTE y enmascara ado_lugar_consulta_ubicacion en CLASIFICADA, RESERVADA o No publicada', N'
IF COL_LENGTH(N''sgspi.vw_consulta_inventario_documental_vigente'', N''ado_contiene_datos_menores'') IS NOT NULL
   OR COL_LENGTH(N''sgspi.vw_consulta_inventario_documental_vigente'', N''ado_finalidad_recoleccion_pii'') IS NOT NULL
   OR COL_LENGTH(N''sgspi.vw_consulta_inventario_documental_vigente'', N''ado_es_infraestructura_critica_icc'') IS NOT NULL
   OR COL_LENGTH(N''sgspi.vw_consulta_inventario_documental_vigente'', N''ado_fundamento_constitucional_legal'') IS NOT NULL
   OR COL_LENGTH(N''sgspi.vw_inventario_activo_documental_mr04'', N''ado_clasificacion_transparencia'') IS NULL
    THROW 51000, N''esquema de vistas documentales fuera de especificación v2.4'', 1;
BEGIN TRAN;
INSERT sgspi.estado_publicacion_catalogo (epc_nombre) VALUES (N''Publicada'');
DECLARE @epc_pub INT = SCOPE_IDENTITY();
DECLARE @epc_nopub INT = (SELECT TOP (1) epc_codigo FROM sgspi.estado_publicacion_catalogo WHERE epc_nombre = N''No publicada'');

-- 1) PUBLICA + Publicada => mantiene ubicación
INSERT sgspi.activo_informacion (aci_codigo_inventario, aci_nombre_activo, tac_codigo, uaa_codigo, aci_clasificacion_transparencia, aci_valor_confidencialidad, aci_valor_integridad, aci_valor_disponibilidad, per_codigo_creador)
VALUES (N''INV-PUB-OK'', N''Act publico ok'', 3, 1, N''PUBLICA'', 1, 1, 1, 1);
DECLARE @a1 INT = SCOPE_IDENTITY();
INSERT sgspi.activo_informacion_proceso_institucional (aci_codigo, pri_codigo) VALUES (@a1, 1);
INSERT sgspi.activo_informacion_sede (aci_codigo, sus_codigo) VALUES (@a1, 1);
INSERT sgspi.activo_informacion_responsable (aci_codigo, car_codigo, uaa_codigo, air_tipo_responsabilidad) VALUES (@a1, 1, 1, N''PROPIETARIO''), (@a1, 1, 1, N''CUSTODIO'');
INSERT sgspi.activo_documental (ado_codigo, pev_codigo, sdo_codigo, sbd_codigo, pdc_codigo, epc_codigo, ado_lugar_consulta_ubicacion) VALUES (@a1, 1, 1, 1, 1, @epc_pub, N''Archivo Central Piso 1'');

-- 2) PUBLICA + No publicada => NULL en vista pública
INSERT sgspi.activo_informacion (aci_codigo_inventario, aci_nombre_activo, tac_codigo, uaa_codigo, aci_clasificacion_transparencia, aci_valor_confidencialidad, aci_valor_integridad, aci_valor_disponibilidad, per_codigo_creador)
VALUES (N''INV-PUB-NP'', N''Act publico no pub'', 3, 1, N''PUBLICA'', 1, 1, 1, 1);
DECLARE @a2 INT = SCOPE_IDENTITY();
INSERT sgspi.activo_informacion_proceso_institucional (aci_codigo, pri_codigo) VALUES (@a2, 1);
INSERT sgspi.activo_informacion_sede (aci_codigo, sus_codigo) VALUES (@a2, 1);
INSERT sgspi.activo_informacion_responsable (aci_codigo, car_codigo, uaa_codigo, air_tipo_responsabilidad) VALUES (@a2, 1, 1, N''PROPIETARIO''), (@a2, 1, 1, N''CUSTODIO'');
INSERT sgspi.activo_documental (ado_codigo, pev_codigo, sdo_codigo, sbd_codigo, pdc_codigo, epc_codigo, ado_lugar_consulta_ubicacion) VALUES (@a2, 1, 1, 1, 1, @epc_nopub, N''Ubicacion Oculta NoPub'');

-- 3) CLASIFICADA + Publicada => NULL en vista pública
INSERT sgspi.activo_informacion (aci_codigo_inventario, aci_nombre_activo, tac_codigo, uaa_codigo, aci_clasificacion_transparencia, cet_codigo, aci_alcance_excepcion, aci_fundamento_constitucional_legal, aci_fundamento_juridico_excepcion, aci_fecha_clasificacion_reserva, aci_es_reserva_indefinida, aci_valor_confidencialidad, aci_valor_integridad, aci_valor_disponibilidad, per_codigo_creador)
VALUES (N''INV-CLAS-PUB'', N''Act clasificado'', 3, 1, N''CLASIFICADA'', 1, N''TOTAL'', N''Ley 1712'', N''Art 18 a'', ''2026-01-01'', 1, 3, 2, 2, 1);
DECLARE @a3 INT = SCOPE_IDENTITY();
INSERT sgspi.activo_informacion_proceso_institucional (aci_codigo, pri_codigo) VALUES (@a3, 1);
INSERT sgspi.activo_informacion_sede (aci_codigo, sus_codigo) VALUES (@a3, 1);
INSERT sgspi.activo_informacion_responsable (aci_codigo, car_codigo, uaa_codigo, air_tipo_responsabilidad) VALUES (@a3, 1, 1, N''PROPIETARIO''), (@a3, 1, 1, N''CUSTODIO'');
INSERT sgspi.activo_documental (ado_codigo, pev_codigo, sdo_codigo, sbd_codigo, pdc_codigo, epc_codigo, ado_lugar_consulta_ubicacion) VALUES (@a3, 1, 1, 1, 1, @epc_pub, N''Boveda Clasificada'');

-- 4) RESERVADA + Publicada => NULL en vista pública
INSERT sgspi.activo_informacion (aci_codigo_inventario, aci_nombre_activo, tac_codigo, uaa_codigo, aci_clasificacion_transparencia, cet_codigo, aci_alcance_excepcion, aci_fundamento_constitucional_legal, aci_fundamento_juridico_excepcion, aci_fecha_clasificacion_reserva, aci_es_reserva_indefinida, aci_anios_plazo_reserva, aci_valor_confidencialidad, aci_valor_integridad, aci_valor_disponibilidad, per_codigo_creador)
VALUES (N''INV-RES-PUB'', N''Act reservado'', 3, 1, N''RESERVADA'', 2, N''PARCIAL'', N''Ley 1712'', N''Art 19'', ''2026-01-01'', 0, 5, 3, 2, 2, 1);
DECLARE @a4 INT = SCOPE_IDENTITY();
INSERT sgspi.activo_informacion_proceso_institucional (aci_codigo, pri_codigo) VALUES (@a4, 1);
INSERT sgspi.activo_informacion_sede (aci_codigo, sus_codigo) VALUES (@a4, 1);
INSERT sgspi.activo_informacion_responsable (aci_codigo, car_codigo, uaa_codigo, air_tipo_responsabilidad) VALUES (@a4, 1, 1, N''PROPIETARIO''), (@a4, 1, 1, N''CUSTODIO'');
INSERT sgspi.activo_documental (ado_codigo, pev_codigo, sdo_codigo, sbd_codigo, pdc_codigo, epc_codigo, ado_lugar_consulta_ubicacion) VALUES (@a4, 1, 1, 1, 1, @epc_pub, N''Boveda Reservada'');

DECLARE @src_id INT = (SELECT TOP (1) src_codigo FROM sgspi.soporte_registro_catalogo ORDER BY src_codigo);
DECLARE @mcc_id INT = (SELECT TOP (1) mcc_codigo FROM sgspi.medio_conservacion_catalogo ORDER BY mcc_codigo);
DECLARE @idi_id INT = (SELECT TOP (1) idi_codigo FROM sgspi.idioma_catalogo ORDER BY idi_codigo);
DECLARE @fac_id INT = (SELECT TOP (1) fac_codigo FROM sgspi.formato_archivo_catalogo ORDER BY fac_codigo);
DECLARE @upc_id INT = (SELECT TOP (1) upc_codigo FROM sgspi.unidad_productora_cuadro_clasificacion_documental ORDER BY upc_codigo);
INSERT sgspi.activo_documental_soporte_registro (ado_codigo, src_codigo) SELECT x.id, @src_id FROM (VALUES (@a1), (@a2), (@a3), (@a4)) AS x(id);
INSERT sgspi.activo_documental_medio_conservacion (ado_codigo, mcc_codigo) SELECT x.id, @mcc_id FROM (VALUES (@a1), (@a2), (@a3), (@a4)) AS x(id);
INSERT sgspi.activo_documental_idioma (ado_codigo, idi_codigo) SELECT x.id, @idi_id FROM (VALUES (@a1), (@a2), (@a3), (@a4)) AS x(id);
INSERT sgspi.activo_documental_formato_archivo (ado_codigo, fac_codigo) SELECT x.id, @fac_id FROM (VALUES (@a1), (@a2), (@a3), (@a4)) AS x(id);
INSERT sgspi.activo_documental_unidad_productora (ado_codigo, upc_codigo) SELECT x.id, @upc_id FROM (VALUES (@a1), (@a2), (@a3), (@a4)) AS x(id);

-- Llevar los 4 a VIGENTE
UPDATE sgspi.activo_informacion SET aci_fase_registro = N''EN_VALIDACION_LIDER'' WHERE aci_codigo IN (@a1, @a2, @a3, @a4);
UPDATE sgspi.activo_informacion SET aci_fase_registro = N''EN_REVISION_ARCHIVO'' WHERE aci_codigo IN (@a1, @a2, @a3, @a4);
EXECUTE sys.sp_set_session_context @key = N''per_codigo'', @value = 5;
UPDATE sgspi.activo_informacion SET aci_fase_registro = N''EN_REVISION_SGSPI'' WHERE aci_codigo IN (@a1, @a2, @a3, @a4);
EXECUTE sys.sp_set_session_context @key = N''per_codigo'', @value = 4;
UPDATE sgspi.activo_informacion SET aci_fase_registro = N''VIGENTE'' WHERE aci_codigo IN (@a1, @a2, @a3, @a4);

EXECUTE AS USER = N''sgspi_prueba_ejecucion'';
IF ISNULL((SELECT ado_lugar_consulta_ubicacion FROM sgspi.vw_consulta_inventario_documental_vigente WHERE aci_codigo = @a1), N'''') <> N''Archivo Central Piso 1''
    THROW 51000, N''vista pública ocultó ubicación de activo PUBLICA y Publicada'', 1;
IF (SELECT ado_lugar_consulta_ubicacion FROM sgspi.vw_consulta_inventario_documental_vigente WHERE aci_codigo = @a2) IS NOT NULL
   OR (SELECT ado_lugar_consulta_ubicacion FROM sgspi.vw_consulta_inventario_documental_vigente WHERE aci_codigo = @a3) IS NOT NULL
   OR (SELECT ado_lugar_consulta_ubicacion FROM sgspi.vw_consulta_inventario_documental_vigente WHERE aci_codigo = @a4) IS NOT NULL
    THROW 51000, N''vista pública expuso ubicación de activo CLASIFICADA, RESERVADA o No publicada'', 1;
IF ISNULL((SELECT ado_lugar_consulta_ubicacion FROM sgspi.vw_inventario_activo_documental_mr04 WHERE aci_codigo = @a3), N'''') <> N''Boveda Clasificada''
    THROW 51000, N''vw_inventario_activo_documental_mr04 interna perdió ubicación'', 1;
IF EXISTS (SELECT 1 FROM sgspi.vw_consulta_dofa_vigente WHERE acf_fase_registro <> N''VIGENTE'')
   OR NOT EXISTS (SELECT 1 FROM sgspi.vw_consulta_dofa_vigente WHERE acf_fase_registro = N''VIGENTE'')
    THROW 51000, N''vw_consulta_dofa_vigente no filtró exclusivamente VIGENTE'', 1;
REVERT;
ROLLBACK;', 0;

-- --- A5: Endurecimiento CK_sga_uri_evidencia ---
EXECUTE #espera N'v2.3 A5: CK_sga_uri_evidencia rechaza traversal codificado (%2e%2e), %2f, barra invertida, espacio y control chars', N'
BEGIN TRAN;
INSERT sgspi.evento_incertidumbre_activo (pev_codigo, eia_numero_evento, eia_naturaleza_evento, pri_codigo, aci_codigo_primario, aci_codigo_soporte, tac_codigo_componente, eia_fuente_generadora, eia_condicion_vulnerabilidad, eia_efecto_consecuencia, eia_escenario_operacional, epr_codigo_inherente, eim_codigo_inherente, per_codigo_creador)
VALUES (1, 801, N''RIESGO'', 1, 1, 2, 1, N''f'', N''v'', N''e'', N''URI test'', 1, 1, 1);
DECLARE @e INT = SCOPE_IDENTITY();
INSERT sgspi.plan_tratamiento (eia_codigo, plt_naturaleza_evento, etc_codigo, plt_justificacion_estrategia, epr_codigo_residual_meta, eim_codigo_residual_meta, plt_fecha_inicio, plt_fecha_fin, plt_recursos_humanos_tecnicos, plt_recursos_economicos_desc, plt_nombre_indicador_kpi, plt_meta_indicador_kpi)
VALUES (@e, N''RIESGO'', 1, N''j'', 1, 1, ''2026-01-01'', ''2026-12-31'', N''r'', N''r'', N''k'', 100);
DECLARE @p INT = SCOPE_IDENTITY();
INSERT sgspi.actividad_tratamiento (plt_codigo, act_numero_orden, act_descripcion_actividad, car_codigo, uaa_codigo, act_fecha_compromiso) VALUES (@p, 1, N''Act URI'', 1, 1, ''2026-06-30'');
DECLARE @a INT = SCOPE_IDENTITY();
DECLARE @bad TABLE (uri NVARCHAR(500));
INSERT @bad VALUES (N''https://x/%2e%2e/a''), (N''https://x/%2E%2E/a''), (N''https://x/%2f/a''), (N''https://x''), (N''https://x a''), (N''https://x/a'' + NCHAR(10));
DECLARE @u NVARCHAR(500), @ok BIT;
DECLARE cur CURSOR LOCAL FAST_FORWARD FOR SELECT uri FROM @bad;
OPEN cur; FETCH NEXT FROM cur INTO @u;
WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @ok = 0;
        BEGIN TRY
            INSERT sgspi.seguimiento_actividad (act_codigo, per_codigo, sga_porcentaje_reportado, sga_descripcion_avance, sga_nombre_archivo_evidencia, sga_uri_almacenamiento_evidencia, sga_hash_sha256_evidencia)
            VALUES (@a, 1, 10, N''Bad URI'', N''a.pdf'', @u, REPLICATE(''a'', 64));
        END TRY
        BEGIN CATCH
            IF ERROR_NUMBER() = 547 SET @ok = 1;
        END CATCH
        IF @ok = 0 THROW 51000, N''CK_sga_uri_evidencia aceptó una URI maliciosa'', 1;
        FETCH NEXT FROM cur INTO @u;
    END
CLOSE cur; DEALLOCATE cur;
ROLLBACK;', 0;

-- --- B1: Sin deadlock TR_aci <-> TR_ado (cero escritura cruzada) ---
EXECUTE #espera N'v2.3 B1: TR_ado bloquea edición de ado si aci tiene aval vigente de Archivo (50011)', N'
BEGIN TRAN;
DECLARE @aci_d INT = (SELECT aci_codigo FROM sgspi.activo_informacion WHERE aci_codigo_inventario = N''INV-D'');
UPDATE sgspi.activo_documental SET ado_lugar_consulta_ubicacion = N''Intento con aval'' WHERE ado_codigo = @aci_d;', 50011;

EXECUTE #espera N'v2.3 B1: TR_aci no escribe activo_documental y editar aci en EN_REVISION_SGSPI limpia per_codigo_revisor_archivo', N'
IF CHARINDEX(N''UPDATE ado'', OBJECT_DEFINITION(OBJECT_ID(N''sgspi.TR_aci_integridad_y_actualizacion''))) > 0
    THROW 51000, N''TR_aci todavía contiene UPDATE ado'', 1;
BEGIN TRAN;
DECLARE @aci_d INT = (SELECT aci_codigo FROM sgspi.activo_informacion WHERE aci_codigo_inventario = N''INV-D'');
UPDATE sgspi.activo_informacion SET aci_nombre_activo = N''Actas modificadas en SGSPI'' WHERE aci_codigo = @aci_d;
IF (SELECT per_codigo_revisor_archivo FROM sgspi.activo_informacion WHERE aci_codigo = @aci_d) IS NOT NULL
    THROW 51000, N''editar aci en EN_REVISION_SGSPI no limpió per_codigo_revisor_archivo'', 1;
ROLLBACK;', 0;

-- --- B2: Cierre de bypass 100%->100% en TR_sga y orden applock(eia) sin UPDLOCK ---
EXECUTE #espera N'v2.3 B2: TR_sga_inmutabilidad y TR_sga_sincronizar_avance no usan WITH (UPDLOCK) previo', N'
IF CHARINDEX(N''WITH (UPDLOCK)'', OBJECT_DEFINITION(OBJECT_ID(N''sgspi.TR_sga_inmutabilidad''))) > 0
   OR CHARINDEX(N''WITH (UPDLOCK)'', OBJECT_DEFINITION(OBJECT_ID(N''sgspi.TR_sga_sincronizar_avance''))) > 0
    THROW 51000, N''TR_sga_* todavía usa WITH (UPDLOCK)'', 1;', 0;

EXECUTE #espera N'v2.3 B2: insertar sga al 100% en actividad COMPLETADA al 100% se bloquea (50011)', N'
BEGIN TRAN;
INSERT sgspi.evento_incertidumbre_activo (pev_codigo, eia_numero_evento, eia_naturaleza_evento, pri_codigo, aci_codigo_primario, aci_codigo_soporte, tac_codigo_componente, eia_fuente_generadora, eia_condicion_vulnerabilidad, eia_efecto_consecuencia, eia_escenario_operacional, epr_codigo_inherente, eim_codigo_inherente, per_codigo_creador)
VALUES (1, 802, N''RIESGO'', 1, 1, 2, 1, N''f'', N''v'', N''e'', N''Bypass sga ins'', 1, 1, 1);
DECLARE @e INT = SCOPE_IDENTITY();
INSERT sgspi.plan_tratamiento (eia_codigo, plt_naturaleza_evento, etc_codigo, plt_justificacion_estrategia, epr_codigo_residual_meta, eim_codigo_residual_meta, plt_fecha_inicio, plt_fecha_fin, plt_recursos_humanos_tecnicos, plt_recursos_economicos_desc, plt_nombre_indicador_kpi, plt_meta_indicador_kpi)
VALUES (@e, N''RIESGO'', 1, N''j'', 1, 1, ''2026-01-01'', ''2026-12-31'', N''r'', N''r'', N''k'', 100);
DECLARE @p INT = SCOPE_IDENTITY();
INSERT sgspi.actividad_tratamiento (plt_codigo, act_numero_orden, act_descripcion_actividad, car_codigo, uaa_codigo, act_fecha_compromiso) VALUES (@p, 1, N''Act 100'', 1, 1, ''2026-06-30'');
DECLARE @a INT = SCOPE_IDENTITY();
INSERT sgspi.seguimiento_actividad (act_codigo, per_codigo, sga_porcentaje_reportado, sga_descripcion_avance) VALUES (@a, 1, 100, N''SGA 100 A'');
UPDATE sgspi.actividad_tratamiento SET act_fase_actividad = N''EN_CURSO'' WHERE act_codigo = @a;
UPDATE sgspi.actividad_tratamiento SET act_fase_actividad = N''COMPLETADA'' WHERE act_codigo = @a;
INSERT sgspi.seguimiento_actividad (act_codigo, per_codigo, sga_porcentaje_reportado, sga_descripcion_avance) VALUES (@a, 1, 100, N''Bypass INSERT 100'');', 50011;

EXECUTE #espera N'v2.3 B2: desactivar sga al 100% en actividad COMPLETADA al 100% se bloquea (50011)', N'
BEGIN TRAN;
INSERT sgspi.evento_incertidumbre_activo (pev_codigo, eia_numero_evento, eia_naturaleza_evento, pri_codigo, aci_codigo_primario, aci_codigo_soporte, tac_codigo_componente, eia_fuente_generadora, eia_condicion_vulnerabilidad, eia_efecto_consecuencia, eia_escenario_operacional, epr_codigo_inherente, eim_codigo_inherente, per_codigo_creador)
VALUES (1, 802, N''RIESGO'', 1, 1, 2, 1, N''f'', N''v'', N''e'', N''Bypass sga upd'', 1, 1, 1);
DECLARE @e INT = SCOPE_IDENTITY();
INSERT sgspi.plan_tratamiento (eia_codigo, plt_naturaleza_evento, etc_codigo, plt_justificacion_estrategia, epr_codigo_residual_meta, eim_codigo_residual_meta, plt_fecha_inicio, plt_fecha_fin, plt_recursos_humanos_tecnicos, plt_recursos_economicos_desc, plt_nombre_indicador_kpi, plt_meta_indicador_kpi)
VALUES (@e, N''RIESGO'', 1, N''j'', 1, 1, ''2026-01-01'', ''2026-12-31'', N''r'', N''r'', N''k'', 100);
DECLARE @p INT = SCOPE_IDENTITY();
INSERT sgspi.actividad_tratamiento (plt_codigo, act_numero_orden, act_descripcion_actividad, car_codigo, uaa_codigo, act_fecha_compromiso) VALUES (@p, 1, N''Act 100'', 1, 1, ''2026-06-30'');
DECLARE @a INT = SCOPE_IDENTITY();
INSERT sgspi.seguimiento_actividad (act_codigo, per_codigo, sga_porcentaje_reportado, sga_descripcion_avance) VALUES (@a, 1, 100, N''SGA 100 A'');
INSERT sgspi.seguimiento_actividad (act_codigo, per_codigo, sga_porcentaje_reportado, sga_descripcion_avance) VALUES (@a, 1, 100, N''SGA 100 B'');
DECLARE @s2 INT = SCOPE_IDENTITY();
UPDATE sgspi.actividad_tratamiento SET act_fase_actividad = N''EN_CURSO'' WHERE act_codigo = @a;
UPDATE sgspi.actividad_tratamiento SET act_fase_actividad = N''COMPLETADA'' WHERE act_codigo = @a;
UPDATE sgspi.seguimiento_actividad SET sga_estado = 0 WHERE sga_codigo = @s2;', 50011;

-- --- B3: Inmutabilidad post-aprobación en EIA/plt/ptc + sp_getapplock en rpi/rpp ---
EXECUTE #espera N'v2.3 B3: TR_rpi y TR_rpp serializan con sp_getapplock sgspi:rpi: sin UPDLOCK', N'
IF CHARINDEX(N''WITH (UPDLOCK)'', OBJECT_DEFINITION(OBJECT_ID(N''sgspi.TR_rpp_auditoria''))) > 0
   OR CHARINDEX(N''sgspi:rpi:'', OBJECT_DEFINITION(OBJECT_ID(N''sgspi.TR_rpp_auditoria''))) = 0
   OR CHARINDEX(N''sgspi:rpi:'', OBJECT_DEFINITION(OBJECT_ID(N''sgspi.TR_rpi_integridad_y_actualizacion''))) = 0
    THROW 51000, N''TR_rpi / TR_rpp no serializan con sp_getapplock sgspi:rpi:'', 1;', 0;

EXECUTE #espera N'v2.3 B3: tras APROBADO_PLANIFICADO se bloquea edición de contenido en eia (50011)', N'
BEGIN TRAN;
INSERT sgspi.evento_incertidumbre_activo (pev_codigo, eia_numero_evento, eia_naturaleza_evento, pri_codigo, aci_codigo_primario, aci_codigo_soporte, tac_codigo_componente, eia_fuente_generadora, eia_condicion_vulnerabilidad, eia_efecto_consecuencia, eia_escenario_operacional, epr_codigo_inherente, eim_codigo_inherente, per_codigo_creador)
VALUES (1, 803, N''RIESGO'', 1, 1, 2, 1, N''f'', N''v'', N''e'', N''Inmutabilidad eia'', 1, 1, 1);
DECLARE @e INT = SCOPE_IDENTITY();
INSERT sgspi.plan_tratamiento (eia_codigo, plt_naturaleza_evento, etc_codigo, plt_justificacion_estrategia, epr_codigo_residual_meta, eim_codigo_residual_meta, plt_fecha_inicio, plt_fecha_fin, plt_recursos_humanos_tecnicos, plt_recursos_economicos_desc, plt_nombre_indicador_kpi, plt_meta_indicador_kpi)
VALUES (@e, N''RIESGO'', 1, N''j'', 1, 1, ''2026-01-01'', ''2026-12-31'', N''r'', N''r'', N''k'', 100);
DECLARE @p INT = SCOPE_IDENTITY();
INSERT sgspi.actividad_tratamiento (plt_codigo, act_numero_orden, act_descripcion_actividad, car_codigo, uaa_codigo, act_fecha_compromiso) VALUES (@p, 1, N''Act B3'', 1, 1, ''2026-06-30'');
INSERT sgspi.plan_tratamiento_control_referencia_normativa (plt_codigo, crn_codigo) VALUES (@p, 1);
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''EN_VALIDACION_LIDER'' WHERE eia_codigo = @e;
EXECUTE sys.sp_set_session_context @key = N''per_codigo'', @value = 2;
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''EN_REVISION_SGSPI'' WHERE eia_codigo = @e;
EXECUTE sys.sp_set_session_context @key = N''per_codigo'', @value = 4;
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''APROBADO_PLANIFICADO'' WHERE eia_codigo = @e;
UPDATE sgspi.evento_incertidumbre_activo SET eia_condicion_vulnerabilidad = N''alterada'' WHERE eia_codigo = @e;', 50011;

EXECUTE #espera N'v2.3 B3: tras APROBADO_PLANIFICADO se bloquea edición de estrategia/meta en plt (50011)', N'
BEGIN TRAN;
INSERT sgspi.evento_incertidumbre_activo (pev_codigo, eia_numero_evento, eia_naturaleza_evento, pri_codigo, aci_codigo_primario, aci_codigo_soporte, tac_codigo_componente, eia_fuente_generadora, eia_condicion_vulnerabilidad, eia_efecto_consecuencia, eia_escenario_operacional, epr_codigo_inherente, eim_codigo_inherente, per_codigo_creador)
VALUES (1, 803, N''RIESGO'', 1, 1, 2, 1, N''f'', N''v'', N''e'', N''Inmutabilidad plt'', 1, 1, 1);
DECLARE @e INT = SCOPE_IDENTITY();
INSERT sgspi.plan_tratamiento (eia_codigo, plt_naturaleza_evento, etc_codigo, plt_justificacion_estrategia, epr_codigo_residual_meta, eim_codigo_residual_meta, plt_fecha_inicio, plt_fecha_fin, plt_recursos_humanos_tecnicos, plt_recursos_economicos_desc, plt_nombre_indicador_kpi, plt_meta_indicador_kpi)
VALUES (@e, N''RIESGO'', 1, N''j'', 1, 1, ''2026-01-01'', ''2026-12-31'', N''r'', N''r'', N''k'', 100);
DECLARE @p INT = SCOPE_IDENTITY();
INSERT sgspi.actividad_tratamiento (plt_codigo, act_numero_orden, act_descripcion_actividad, car_codigo, uaa_codigo, act_fecha_compromiso) VALUES (@p, 1, N''Act B3'', 1, 1, ''2026-06-30'');
INSERT sgspi.plan_tratamiento_control_referencia_normativa (plt_codigo, crn_codigo) VALUES (@p, 1);
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''EN_VALIDACION_LIDER'' WHERE eia_codigo = @e;
EXECUTE sys.sp_set_session_context @key = N''per_codigo'', @value = 2;
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''EN_REVISION_SGSPI'' WHERE eia_codigo = @e;
EXECUTE sys.sp_set_session_context @key = N''per_codigo'', @value = 4;
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''APROBADO_PLANIFICADO'' WHERE eia_codigo = @e;
UPDATE sgspi.plan_tratamiento SET epr_codigo_residual_meta = 5, eim_codigo_residual_meta = 5, plt_justificacion_estrategia = N''alterada'' WHERE plt_codigo = @p;', 50011;

EXECUTE #espera N'v2.3 B3: tras APROBADO_PLANIFICADO se bloquea cambio en puente ptc (50011)', N'
BEGIN TRAN;
INSERT sgspi.evento_incertidumbre_activo (pev_codigo, eia_numero_evento, eia_naturaleza_evento, pri_codigo, aci_codigo_primario, aci_codigo_soporte, tac_codigo_componente, eia_fuente_generadora, eia_condicion_vulnerabilidad, eia_efecto_consecuencia, eia_escenario_operacional, epr_codigo_inherente, eim_codigo_inherente, per_codigo_creador)
VALUES (1, 803, N''RIESGO'', 1, 1, 2, 1, N''f'', N''v'', N''e'', N''Inmutabilidad ptc'', 1, 1, 1);
DECLARE @e INT = SCOPE_IDENTITY();
INSERT sgspi.plan_tratamiento (eia_codigo, plt_naturaleza_evento, etc_codigo, plt_justificacion_estrategia, epr_codigo_residual_meta, eim_codigo_residual_meta, plt_fecha_inicio, plt_fecha_fin, plt_recursos_humanos_tecnicos, plt_recursos_economicos_desc, plt_nombre_indicador_kpi, plt_meta_indicador_kpi)
VALUES (@e, N''RIESGO'', 1, N''j'', 1, 1, ''2026-01-01'', ''2026-12-31'', N''r'', N''r'', N''k'', 100);
DECLARE @p INT = SCOPE_IDENTITY();
INSERT sgspi.actividad_tratamiento (plt_codigo, act_numero_orden, act_descripcion_actividad, car_codigo, uaa_codigo, act_fecha_compromiso) VALUES (@p, 1, N''Act B3'', 1, 1, ''2026-06-30'');
INSERT sgspi.plan_tratamiento_control_referencia_normativa (plt_codigo, crn_codigo) VALUES (@p, 1);
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''EN_VALIDACION_LIDER'' WHERE eia_codigo = @e;
EXECUTE sys.sp_set_session_context @key = N''per_codigo'', @value = 2;
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''EN_REVISION_SGSPI'' WHERE eia_codigo = @e;
EXECUTE sys.sp_set_session_context @key = N''per_codigo'', @value = 4;
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''APROBADO_PLANIFICADO'' WHERE eia_codigo = @e;
UPDATE sgspi.plan_tratamiento_control_referencia_normativa SET ptc_estado = 0 WHERE plt_codigo = @p AND crn_codigo = 1;', 50011;

EXECUTE #espera N'v2.3 B3: en EN_EJECUCION sí pasan act, sga y plt_valor_alcanzado_kpi', N'
BEGIN TRAN;
INSERT sgspi.evento_incertidumbre_activo (pev_codigo, eia_numero_evento, eia_naturaleza_evento, pri_codigo, aci_codigo_primario, aci_codigo_soporte, tac_codigo_componente, eia_fuente_generadora, eia_condicion_vulnerabilidad, eia_efecto_consecuencia, eia_escenario_operacional, epr_codigo_inherente, eim_codigo_inherente, per_codigo_creador)
VALUES (1, 803, N''RIESGO'', 1, 1, 2, 1, N''f'', N''v'', N''e'', N''Ejecución B3 ok'', 1, 1, 1);
DECLARE @e INT = SCOPE_IDENTITY();
INSERT sgspi.plan_tratamiento (eia_codigo, plt_naturaleza_evento, etc_codigo, plt_justificacion_estrategia, epr_codigo_residual_meta, eim_codigo_residual_meta, plt_fecha_inicio, plt_fecha_fin, plt_recursos_humanos_tecnicos, plt_recursos_economicos_desc, plt_nombre_indicador_kpi, plt_meta_indicador_kpi)
VALUES (@e, N''RIESGO'', 1, N''j'', 1, 1, ''2026-01-01'', ''2026-12-31'', N''r'', N''r'', N''k'', 100);
DECLARE @p INT = SCOPE_IDENTITY();
INSERT sgspi.actividad_tratamiento (plt_codigo, act_numero_orden, act_descripcion_actividad, car_codigo, uaa_codigo, act_fecha_compromiso) VALUES (@p, 1, N''Act B3'', 1, 1, ''2026-06-30'');
DECLARE @a INT = SCOPE_IDENTITY();
INSERT sgspi.plan_tratamiento_control_referencia_normativa (plt_codigo, crn_codigo) VALUES (@p, 1);
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''EN_VALIDACION_LIDER'' WHERE eia_codigo = @e;
EXECUTE sys.sp_set_session_context @key = N''per_codigo'', @value = 2;
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''EN_REVISION_SGSPI'' WHERE eia_codigo = @e;
EXECUTE sys.sp_set_session_context @key = N''per_codigo'', @value = 4;
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''APROBADO_PLANIFICADO'' WHERE eia_codigo = @e;
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''EN_EJECUCION'' WHERE eia_codigo = @e;
UPDATE sgspi.plan_tratamiento SET plt_valor_alcanzado_kpi = 95 WHERE plt_codigo = @p;
EXECUTE sys.sp_set_session_context @key = N''per_codigo'', @value = 1;
INSERT sgspi.seguimiento_actividad (act_codigo, per_codigo, sga_porcentaje_reportado, sga_descripcion_avance) VALUES (@a, 1, 100, N''Ejecución B3'');
UPDATE sgspi.actividad_tratamiento SET act_fase_actividad = N''EN_CURSO'' WHERE act_codigo = @a;
UPDATE sgspi.actividad_tratamiento SET act_fase_actividad = N''COMPLETADA'' WHERE act_codigo = @a;
ROLLBACK;', 0;

EXECUTE #espera N'v2.3 B3: en EN_EVALUACION_EFICACIA se bloquea insertar act (50011)', N'
BEGIN TRAN;
INSERT sgspi.evento_incertidumbre_activo (pev_codigo, eia_numero_evento, eia_naturaleza_evento, pri_codigo, aci_codigo_primario, aci_codigo_soporte, tac_codigo_componente, eia_fuente_generadora, eia_condicion_vulnerabilidad, eia_efecto_consecuencia, eia_escenario_operacional, epr_codigo_inherente, eim_codigo_inherente, per_codigo_creador)
VALUES (1, 803, N''RIESGO'', 1, 1, 2, 1, N''f'', N''v'', N''e'', N''Bloqueo act eval'', 1, 1, 1);
DECLARE @e INT = SCOPE_IDENTITY();
INSERT sgspi.plan_tratamiento (eia_codigo, plt_naturaleza_evento, etc_codigo, plt_justificacion_estrategia, epr_codigo_residual_meta, eim_codigo_residual_meta, plt_fecha_inicio, plt_fecha_fin, plt_recursos_humanos_tecnicos, plt_recursos_economicos_desc, plt_nombre_indicador_kpi, plt_meta_indicador_kpi)
VALUES (@e, N''RIESGO'', 1, N''j'', 1, 1, ''2026-01-01'', ''2026-12-31'', N''r'', N''r'', N''k'', 100);
DECLARE @p INT = SCOPE_IDENTITY();
INSERT sgspi.actividad_tratamiento (plt_codigo, act_numero_orden, act_descripcion_actividad, car_codigo, uaa_codigo, act_fecha_compromiso) VALUES (@p, 1, N''Act B3'', 1, 1, ''2026-06-30'');
DECLARE @a INT = SCOPE_IDENTITY();
INSERT sgspi.plan_tratamiento_control_referencia_normativa (plt_codigo, crn_codigo) VALUES (@p, 1);
INSERT sgspi.seguimiento_actividad (act_codigo, per_codigo, sga_porcentaje_reportado, sga_descripcion_avance) VALUES (@a, 1, 100, N''100'');
UPDATE sgspi.actividad_tratamiento SET act_fase_actividad = N''EN_CURSO'' WHERE act_codigo = @a;
UPDATE sgspi.actividad_tratamiento SET act_fase_actividad = N''COMPLETADA'' WHERE act_codigo = @a;
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''EN_VALIDACION_LIDER'' WHERE eia_codigo = @e;
EXECUTE sys.sp_set_session_context @key = N''per_codigo'', @value = 2;
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''EN_REVISION_SGSPI'' WHERE eia_codigo = @e;
EXECUTE sys.sp_set_session_context @key = N''per_codigo'', @value = 4;
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''APROBADO_PLANIFICADO'' WHERE eia_codigo = @e;
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''EN_EJECUCION'' WHERE eia_codigo = @e;
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''EN_EVALUACION_EFICACIA'' WHERE eia_codigo = @e;
INSERT sgspi.actividad_tratamiento (plt_codigo, act_numero_orden, act_descripcion_actividad, act_fecha_compromiso) VALUES (@p, 2, N''Extra'', ''2026-07-01'');', 50011;

EXECUTE #espera N'v2.3 B3: en EN_EVALUACION_EFICACIA se bloquea editar plt_valor_alcanzado_kpi (50011)', N'
BEGIN TRAN;
INSERT sgspi.evento_incertidumbre_activo (pev_codigo, eia_numero_evento, eia_naturaleza_evento, pri_codigo, aci_codigo_primario, aci_codigo_soporte, tac_codigo_componente, eia_fuente_generadora, eia_condicion_vulnerabilidad, eia_efecto_consecuencia, eia_escenario_operacional, epr_codigo_inherente, eim_codigo_inherente, per_codigo_creador)
VALUES (1, 803, N''RIESGO'', 1, 1, 2, 1, N''f'', N''v'', N''e'', N''Bloqueo kpi eval'', 1, 1, 1);
DECLARE @e INT = SCOPE_IDENTITY();
INSERT sgspi.plan_tratamiento (eia_codigo, plt_naturaleza_evento, etc_codigo, plt_justificacion_estrategia, epr_codigo_residual_meta, eim_codigo_residual_meta, plt_fecha_inicio, plt_fecha_fin, plt_recursos_humanos_tecnicos, plt_recursos_economicos_desc, plt_nombre_indicador_kpi, plt_meta_indicador_kpi)
VALUES (@e, N''RIESGO'', 1, N''j'', 1, 1, ''2026-01-01'', ''2026-12-31'', N''r'', N''r'', N''k'', 100);
DECLARE @p INT = SCOPE_IDENTITY();
INSERT sgspi.actividad_tratamiento (plt_codigo, act_numero_orden, act_descripcion_actividad, car_codigo, uaa_codigo, act_fecha_compromiso) VALUES (@p, 1, N''Act B3'', 1, 1, ''2026-06-30'');
DECLARE @a INT = SCOPE_IDENTITY();
INSERT sgspi.plan_tratamiento_control_referencia_normativa (plt_codigo, crn_codigo) VALUES (@p, 1);
INSERT sgspi.seguimiento_actividad (act_codigo, per_codigo, sga_porcentaje_reportado, sga_descripcion_avance) VALUES (@a, 1, 100, N''100'');
UPDATE sgspi.actividad_tratamiento SET act_fase_actividad = N''EN_CURSO'' WHERE act_codigo = @a;
UPDATE sgspi.actividad_tratamiento SET act_fase_actividad = N''COMPLETADA'' WHERE act_codigo = @a;
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''EN_VALIDACION_LIDER'' WHERE eia_codigo = @e;
EXECUTE sys.sp_set_session_context @key = N''per_codigo'', @value = 2;
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''EN_REVISION_SGSPI'' WHERE eia_codigo = @e;
EXECUTE sys.sp_set_session_context @key = N''per_codigo'', @value = 4;
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''APROBADO_PLANIFICADO'' WHERE eia_codigo = @e;
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''EN_EJECUCION'' WHERE eia_codigo = @e;
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''EN_EVALUACION_EFICACIA'' WHERE eia_codigo = @e;
UPDATE sgspi.plan_tratamiento SET plt_valor_alcanzado_kpi = 100 WHERE plt_codigo = @p;', 50011;

-- --- B4: SoD ampliado, cardinalidad 1..N, exclusividad ado/sif, liderazgo pri/piu, textos vacíos y anti-huérfanos ---
EXECUTE #espera N'v2.3 B4 SoD: validador líder no puede firmar también como revisor SGSPI en eia (CK_eia_sod_firmas -> 547)', N'
BEGIN TRAN;
INSERT sgspi.evento_incertidumbre_activo (pev_codigo, eia_numero_evento, eia_naturaleza_evento, pri_codigo, aci_codigo_primario, aci_codigo_soporte, tac_codigo_componente, eia_fuente_generadora, eia_condicion_vulnerabilidad, eia_efecto_consecuencia, eia_escenario_operacional, epr_codigo_inherente, eim_codigo_inherente, per_codigo_creador)
VALUES (1, 804, N''RIESGO'', 1, 1, 2, 1, N''f'', N''v'', N''e'', N''SoD eia'', 5, 5, 1);
DECLARE @e INT = SCOPE_IDENTITY();
INSERT sgspi.plan_tratamiento (eia_codigo, plt_naturaleza_evento, etc_codigo, plt_justificacion_estrategia, epr_codigo_residual_meta, eim_codigo_residual_meta, plt_fecha_inicio, plt_fecha_fin, plt_recursos_humanos_tecnicos, plt_recursos_economicos_desc, plt_nombre_indicador_kpi, plt_meta_indicador_kpi)
VALUES (@e, N''RIESGO'', 1, N''j'', 1, 1, ''2026-01-01'', ''2026-12-31'', N''r'', N''r'', N''k'', 100);
DECLARE @p INT = SCOPE_IDENTITY();
INSERT sgspi.actividad_tratamiento (plt_codigo, act_numero_orden, act_descripcion_actividad, car_codigo, uaa_codigo, act_fecha_compromiso) VALUES (@p, 1, N''Act SoD'', 1, 1, ''2026-06-30'');
INSERT sgspi.plan_tratamiento_control_referencia_normativa (plt_codigo, crn_codigo) VALUES (@p, 1);
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''EN_VALIDACION_LIDER'' WHERE eia_codigo = @e;
EXECUTE sys.sp_set_session_context @key = N''per_codigo'', @value = 2;
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''EN_REVISION_SGSPI'' WHERE eia_codigo = @e;
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''EN_ACEPTACION_COMITE'' WHERE eia_codigo = @e;', 547;

EXECUTE #espera N'v2.3 B4 SoD: aprobador del comité no puede dictaminar eficacia en plt (50019)', N'
BEGIN TRAN;
INSERT sgspi.evento_incertidumbre_activo (pev_codigo, eia_numero_evento, eia_naturaleza_evento, pri_codigo, aci_codigo_primario, aci_codigo_soporte, tac_codigo_componente, eia_fuente_generadora, eia_condicion_vulnerabilidad, eia_efecto_consecuencia, eia_escenario_operacional, epr_codigo_inherente, eim_codigo_inherente, per_codigo_creador)
VALUES (1, 804, N''RIESGO'', 1, 1, 2, 1, N''f'', N''v'', N''e'', N''SoD comité'', 5, 5, 1);
DECLARE @e INT = SCOPE_IDENTITY();
INSERT sgspi.plan_tratamiento (eia_codigo, plt_naturaleza_evento, etc_codigo, plt_justificacion_estrategia, epr_codigo_residual_meta, eim_codigo_residual_meta, plt_fecha_inicio, plt_fecha_fin, plt_recursos_humanos_tecnicos, plt_recursos_economicos_desc, plt_nombre_indicador_kpi, plt_meta_indicador_kpi)
VALUES (@e, N''RIESGO'', 1, N''j'', 1, 1, ''2026-01-01'', ''2026-12-31'', N''r'', N''r'', N''k'', 100);
DECLARE @p INT = SCOPE_IDENTITY();
INSERT sgspi.actividad_tratamiento (plt_codigo, act_numero_orden, act_descripcion_actividad, car_codigo, uaa_codigo, act_fecha_compromiso) VALUES (@p, 1, N''Act SoD'', 1, 1, ''2026-06-30'');
DECLARE @a INT = SCOPE_IDENTITY();
INSERT sgspi.plan_tratamiento_control_referencia_normativa (plt_codigo, crn_codigo) VALUES (@p, 1);
INSERT sgspi.seguimiento_actividad (act_codigo, per_codigo, sga_porcentaje_reportado, sga_descripcion_avance) VALUES (@a, 1, 100, N''Done'');
UPDATE sgspi.actividad_tratamiento SET act_fase_actividad = N''EN_CURSO'' WHERE act_codigo = @a;
UPDATE sgspi.actividad_tratamiento SET act_fase_actividad = N''COMPLETADA'' WHERE act_codigo = @a;
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''EN_VALIDACION_LIDER'' WHERE eia_codigo = @e;
EXECUTE sys.sp_set_session_context @key = N''per_codigo'', @value = 2;
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''EN_REVISION_SGSPI'' WHERE eia_codigo = @e;
EXECUTE sys.sp_set_session_context @key = N''per_codigo'', @value = 4;
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''EN_ACEPTACION_COMITE'' WHERE eia_codigo = @e;
EXECUTE sys.sp_set_session_context @key = N''per_codigo'', @value = 5;
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''APROBADO_PLANIFICADO'' WHERE eia_codigo = @e;
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''EN_EJECUCION'' WHERE eia_codigo = @e;
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''EN_EVALUACION_EFICACIA'' WHERE eia_codigo = @e;
UPDATE sgspi.plan_tratamiento SET plt_es_tratamiento_eficaz = 1, plt_dictamen_eficacia = N''Auto-comité'', per_codigo_evaluador = 5, plt_fecha_evaluacion_eficacia = SYSDATETIMEOFFSET() WHERE plt_codigo = @p;', 50019;

EXECUTE #espera N'v2.3 B4 1..N: rechaza aprobar rpi sin rpp activo (50020)', N'
BEGIN TRAN;
INSERT sgspi.requisito_parte_interesada (pev_codigo, pai_codigo, rpi_necesidad_expectativa, per_codigo_creador) VALUES (1, 1, N''Sin proceso'', 1);
DECLARE @r INT = SCOPE_IDENTITY();
UPDATE sgspi.requisito_parte_interesada SET rpi_fase_registro = N''EN_VALIDACION_LIDER'' WHERE rpi_codigo = @r;
UPDATE sgspi.requisito_parte_interesada SET rpi_fase_registro = N''EN_REVISION_SGSPI'' WHERE rpi_codigo = @r;
EXECUTE sys.sp_set_session_context @key = N''per_codigo'', @value = 2;
UPDATE sgspi.requisito_parte_interesada SET rpi_fase_registro = N''VIGENTE'' WHERE rpi_codigo = @r;', 50020;

EXECUTE #espera N'v2.3 B4 1..N: rechaza aprobar aci sin aip activo (50020)', N'
BEGIN TRAN;
INSERT sgspi.activo_informacion (aci_codigo_inventario, aci_nombre_activo, tac_codigo, uaa_codigo, aci_clasificacion_transparencia, aci_valor_confidencialidad, aci_valor_integridad, aci_valor_disponibilidad, per_codigo_creador)
VALUES (N''INV-NOAIP'', N''Sin proceso'', 3, 1, N''PUBLICA'', 1, 1, 1, 1);
DECLARE @ac INT = SCOPE_IDENTITY();
INSERT sgspi.activo_informacion_responsable (aci_codigo, car_codigo, uaa_codigo, air_tipo_responsabilidad) VALUES (@ac, 1, 1, N''PROPIETARIO''), (@ac, 1, 1, N''CUSTODIO'');
UPDATE sgspi.activo_informacion SET aci_fase_registro = N''EN_VALIDACION_LIDER'' WHERE aci_codigo = @ac;
UPDATE sgspi.activo_informacion SET aci_fase_registro = N''EN_REVISION_SGSPI'' WHERE aci_codigo = @ac;
EXECUTE sys.sp_set_session_context @key = N''per_codigo'', @value = 2;
UPDATE sgspi.activo_informacion SET aci_fase_registro = N''VIGENTE'' WHERE aci_codigo = @ac;', 50020;

EXECUTE #espera N'v2.3 B4 1..N: rechaza aprobar eia (APROBADO_PLANIFICADO) sin act activa (50020)', N'
BEGIN TRAN;
INSERT sgspi.evento_incertidumbre_activo (pev_codigo, eia_numero_evento, eia_naturaleza_evento, pri_codigo, aci_codigo_primario, aci_codigo_soporte, tac_codigo_componente, eia_fuente_generadora, eia_condicion_vulnerabilidad, eia_efecto_consecuencia, eia_escenario_operacional, epr_codigo_inherente, eim_codigo_inherente, per_codigo_creador)
VALUES (1, 805, N''RIESGO'', 1, 1, 2, 1, N''f'', N''v'', N''e'', N''Sin act'', 1, 1, 1);
DECLARE @ev INT = SCOPE_IDENTITY();
INSERT sgspi.plan_tratamiento (eia_codigo, plt_naturaleza_evento, etc_codigo, plt_justificacion_estrategia, epr_codigo_residual_meta, eim_codigo_residual_meta, plt_fecha_inicio, plt_fecha_fin, plt_recursos_humanos_tecnicos, plt_recursos_economicos_desc, plt_nombre_indicador_kpi, plt_meta_indicador_kpi)
VALUES (@ev, N''RIESGO'', 1, N''j'', 1, 1, ''2026-01-01'', ''2026-12-31'', N''r'', N''r'', N''k'', 100);
DECLARE @pl INT = SCOPE_IDENTITY();
INSERT sgspi.plan_tratamiento_control_referencia_normativa (plt_codigo, crn_codigo) VALUES (@pl, 1);
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''EN_VALIDACION_LIDER'' WHERE eia_codigo = @ev;
EXECUTE sys.sp_set_session_context @key = N''per_codigo'', @value = 2;
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''EN_REVISION_SGSPI'' WHERE eia_codigo = @ev;
EXECUTE sys.sp_set_session_context @key = N''per_codigo'', @value = 4;
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''APROBADO_PLANIFICADO'' WHERE eia_codigo = @ev;', 50020;

EXECUTE #espera N'v2.3 B4 1..N: rechaza aprobar eia (APROBADO_PLANIFICADO) sin ptc activo (50020)', N'
BEGIN TRAN;
INSERT sgspi.evento_incertidumbre_activo (pev_codigo, eia_numero_evento, eia_naturaleza_evento, pri_codigo, aci_codigo_primario, aci_codigo_soporte, tac_codigo_componente, eia_fuente_generadora, eia_condicion_vulnerabilidad, eia_efecto_consecuencia, eia_escenario_operacional, epr_codigo_inherente, eim_codigo_inherente, per_codigo_creador)
VALUES (1, 805, N''RIESGO'', 1, 1, 2, 1, N''f'', N''v'', N''e'', N''Sin ptc'', 1, 1, 1);
DECLARE @ev INT = SCOPE_IDENTITY();
INSERT sgspi.plan_tratamiento (eia_codigo, plt_naturaleza_evento, etc_codigo, plt_justificacion_estrategia, epr_codigo_residual_meta, eim_codigo_residual_meta, plt_fecha_inicio, plt_fecha_fin, plt_recursos_humanos_tecnicos, plt_recursos_economicos_desc, plt_nombre_indicador_kpi, plt_meta_indicador_kpi)
VALUES (@ev, N''RIESGO'', 1, N''j'', 1, 1, ''2026-01-01'', ''2026-12-31'', N''r'', N''r'', N''k'', 100);
DECLARE @pl INT = SCOPE_IDENTITY();
INSERT sgspi.actividad_tratamiento (plt_codigo, act_numero_orden, act_descripcion_actividad, car_codigo, uaa_codigo, act_fecha_compromiso) VALUES (@pl, 1, N''Con act pero sin ptc'', 1, 1, ''2026-06-30'');
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''EN_VALIDACION_LIDER'' WHERE eia_codigo = @ev;
EXECUTE sys.sp_set_session_context @key = N''per_codigo'', @value = 2;
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''EN_REVISION_SGSPI'' WHERE eia_codigo = @ev;
EXECUTE sys.sp_set_session_context @key = N''per_codigo'', @value = 4;
UPDATE sgspi.evento_incertidumbre_activo SET eia_fase_registro = N''APROBADO_PLANIFICADO'' WHERE eia_codigo = @ev;', 50020;

EXECUTE #espera N'v2.3 B4 exclusividad: rechaza crear sif sobre aci que ya tiene ado activo (50020)', N'
BEGIN TRAN;
DECLARE @aci_d INT = (SELECT aci_codigo FROM sgspi.activo_informacion WHERE aci_codigo_inventario = N''INV-D'');
INSERT sgspi.sistema_informacion_ficha (aci_codigo, sif_nombre_sistema, sif_modalidad_desarrollo, sif_descripcion_general) VALUES (@aci_d, N''SIF sobre ado'', N''PROPIO'', N''desc'');', 50020;

EXECUTE #espera N'v2.3 B4 exclusividad: rechaza crear ado sobre aci que ya tiene sif activa (50020)', N'
BEGIN TRAN;
INSERT sgspi.sistema_informacion_ficha (aci_codigo, sif_nombre_sistema, sif_modalidad_desarrollo, sif_descripcion_general) VALUES (2, N''SIF exclusivo'', N''PROPIO'', N''desc'');
INSERT sgspi.activo_documental (ado_codigo, pev_codigo, sdo_codigo, sbd_codigo, pdc_codigo, epc_codigo, ado_lugar_consulta_ubicacion) VALUES (2, 1, 1, 1, 1, 1, N''Archivo'');', 50020;

EXECUTE #espera N'v2.3 B4 coherencia: rechaza textos en blanco (LEN(TRIM)=0 -> 547)', N'
INSERT sgspi.activo_informacion (aci_codigo_inventario, aci_nombre_activo, tac_codigo, aci_clasificacion_transparencia, aci_valor_confidencialidad, aci_valor_integridad, aci_valor_disponibilidad, per_codigo_creador) VALUES (N''   '', N''x'', 3, N''PUBLICA'', 1, 1, 1, 1);', 547;

EXECUTE #espera N'v2.3 B4 coherencia: rechaza par líder incompleto en pri (CK_pri_lider_coherente -> 547)', N'
INSERT sgspi.proceso_institucional (pri_identificador, pri_nombre, tpr_codigo, uaa_codigo_lider) VALUES (N''P_HALF'', N''Medio líder'', 1, 1);', 547;

EXECUTE #espera N'v2.3 B4 coherencia: rechaza desactivar piu de la UAA líder del proceso (50020)', N'
BEGIN TRAN;
UPDATE sgspi.proceso_institucional_uaa SET piu_estado = 0 WHERE pri_codigo = 1 AND uaa_codigo = 1;', 50020;

EXECUTE #espera N'v2.3 B4 anti-huérfanos: rechaza soft-delete de pri con hijos activos (50020)', N'
BEGIN TRAN;
UPDATE sgspi.proceso_institucional SET pri_estado = 0 WHERE pri_codigo = 1;', 50020;

EXECUTE #espera N'v2.3 B4 anti-huérfanos: rechaza soft-delete de sdo con subseries o ado activos (50020)', N'
BEGIN TRAN;
UPDATE sgspi.serie_documental_catalogo SET sdo_estado = 0 WHERE sdo_codigo = 1;', 50020;

EXECUTE #espera N'v2.3 B4 anti-huérfanos: rechaza soft-delete de upc con hijos o adu activos (50020)', N'
BEGIN TRAN;
UPDATE sgspi.unidad_productora_cuadro_clasificacion_documental SET upc_estado = 0 WHERE upc_nombre_unidad = N''Rectoría'';', 50020;

EXECUTE #espera N'v2.3 B4 anti-huérfanos: rechaza soft-delete de aci con ado activo (50020)', N'
BEGIN TRAN;
UPDATE sgspi.activo_informacion SET aci_estado = 0 WHERE aci_codigo_inventario = N''INV-D'';', 50020;

EXECUTE #espera N'v2.3 B4 anti-huérfanos: rechaza soft-delete de plt con act activa (50020)', N'
BEGIN TRAN;
INSERT sgspi.evento_incertidumbre_activo (pev_codigo, eia_numero_evento, eia_naturaleza_evento, pri_codigo, aci_codigo_primario, aci_codigo_soporte, tac_codigo_componente, eia_fuente_generadora, eia_condicion_vulnerabilidad, eia_efecto_consecuencia, eia_escenario_operacional, epr_codigo_inherente, eim_codigo_inherente, per_codigo_creador)
VALUES (1, 806, N''RIESGO'', 1, 1, 2, 1, N''f'', N''v'', N''e'', N''Anti-orphan plt'', 1, 1, 1);
DECLARE @ep INT = SCOPE_IDENTITY();
INSERT sgspi.plan_tratamiento (eia_codigo, plt_naturaleza_evento, etc_codigo, plt_justificacion_estrategia, epr_codigo_residual_meta, eim_codigo_residual_meta, plt_fecha_inicio, plt_fecha_fin, plt_recursos_humanos_tecnicos, plt_recursos_economicos_desc, plt_nombre_indicador_kpi, plt_meta_indicador_kpi)
VALUES (@ep, N''RIESGO'', 1, N''j'', 1, 1, ''2026-01-01'', ''2026-12-31'', N''r'', N''r'', N''k'', 100);
DECLARE @pp INT = SCOPE_IDENTITY();
INSERT sgspi.actividad_tratamiento (plt_codigo, act_numero_orden, act_descripcion_actividad, act_fecha_compromiso) VALUES (@pp, 1, N''Hijo activo'', ''2026-06-30'');
UPDATE sgspi.plan_tratamiento SET plt_estado = 0 WHERE plt_codigo = @pp;', 50020;

-- --- B5: sgspi.usp_siguiente_consecutivo ---
EXECUTE #espera N'v2.3 B5: usp_siguiente_consecutivo exige transacción explícita (50023)', N'
DECLARE @n SMALLINT;
EXECUTE sgspi.usp_siguiente_consecutivo @dominio = N''ACF'', @ambito_codigo = 1, @naturaleza = N''DEBILIDAD'', @siguiente_numero = @n OUTPUT;', 50023;

EXECUTE #espera N'v2.3/v2.4 B5: usp_siguiente_consecutivo genera consecutivos globales para ACF, EIA y ACT bajo grupo_sgspi_ejecucion', N'
BEGIN TRAN;
DECLARE @plt_ra1 INT = (SELECT TOP (1) plt_codigo FROM sgspi.plan_tratamiento ORDER BY plt_codigo);
DECLARE @n_acf SMALLINT, @n_eia SMALLINT, @n_act SMALLINT;
EXECUTE AS USER = N''sgspi_prueba_ejecucion'';
EXECUTE sgspi.usp_siguiente_consecutivo @dominio = N''ACF'', @ambito_codigo = 1, @naturaleza = N''DEBILIDAD'', @siguiente_numero = @n_acf OUTPUT;
EXECUTE sgspi.usp_siguiente_consecutivo @dominio = N''EIA'', @ambito_codigo = 1, @naturaleza = N''RIESGO'', @siguiente_numero = @n_eia OUTPUT;
EXECUTE sgspi.usp_siguiente_consecutivo @dominio = N''ACT'', @ambito_codigo = @plt_ra1, @siguiente_numero = @n_act OUTPUT;
REVERT;
IF ISNULL(@n_acf, 0) < 2 OR ISNULL(@n_eia, 0) < 3 OR ISNULL(@n_act, 0) < 2
    THROW 51000, N''usp_siguiente_consecutivo devolvió consecutivo incorrecto'', 1;
ROLLBACK;', 0;

-- --- C1 / E1: Exactamente 13 FKs a dbo.persona (0 desde aud_*) y 25 FKs totales a [dbo] ---
EXECUTE #espera N'v2.3 C1/E1: 13 FKs a dbo.persona (0 desde aud_*) y 25 FKs totales desde [sgspi] hacia [dbo]', N'
IF (SELECT COUNT(*) FROM sys.foreign_keys WHERE schema_id = SCHEMA_ID(N''sgspi'') AND referenced_object_id = OBJECT_ID(N''dbo.persona'')) <> 13
   OR EXISTS (SELECT 1 FROM sys.foreign_keys AS fk INNER JOIN sys.tables AS t ON t.object_id = fk.parent_object_id
              WHERE fk.schema_id = SCHEMA_ID(N''sgspi'') AND t.name LIKE N''aud[_]%'' AND fk.referenced_object_id = OBJECT_ID(N''dbo.persona''))
   OR (SELECT COUNT(*) FROM sys.foreign_keys WHERE schema_id = SCHEMA_ID(N''sgspi'') AND OBJECT_SCHEMA_NAME(referenced_object_id) = N''dbo'') <> 25
    THROW 51000, N''conteo de FKs hacia [dbo] / dbo.persona fuera de especificación C1/E1'', 1;', 0;

-- --- C2 (v2.4): usp_obtener_contexto_usuario fail-closed + TR_plt auditoría fecha servidor ---
EXECUTE #espera N'v2.4 C2: usp_obtener_contexto_usuario falla en cerrado (0 filas) si un us mapea a >1 per_codigo activo distinto', N'
BEGIN TRAN;
UPDATE dbo.usuario_docentes SET us = ''admin_prueba'', up = 3, state = 1 WHERE us = ''docente_prueba'';
DECLARE @ctx_dup TABLE (per_codigo INT, uid BIGINT, nombre_completo NVARCHAR(500), gru_id NVARCHAR(100), uaa_codigo INT, pri_codigo INT);
INSERT @ctx_dup EXECUTE sgspi.usp_obtener_contexto_usuario @us = ''admin_prueba'';
IF EXISTS (SELECT 1 FROM @ctx_dup)
    THROW 51000, N''usp_obtener_contexto_usuario eligió TOP (1) ante homónimo ambiguo en vez de fallar en cerrado'', 1;
ROLLBACK;', 0;

EXECUTE #espera N'v2.3 C2: TR_plt archiva en aud_plan_tratamiento la fecha del servidor (@ahora) y no la enviada por el cliente', N'
DECLARE @eia_ra1 INT = (SELECT eia_codigo FROM sgspi.evento_incertidumbre_activo WHERE eia_identificador_evento = N''RA-01'');
IF EXISTS (SELECT 1 FROM sgspi.aud_plan_tratamiento WHERE eia_codigo = @eia_ra1 AND apt_operacion = ''U'' AND apt_es_tratamiento_eficaz = 1 AND YEAR(apt_fecha_evaluacion_eficacia) = 2000)
   OR NOT EXISTS (SELECT 1 FROM sgspi.aud_plan_tratamiento WHERE eia_codigo = @eia_ra1 AND apt_operacion = ''U'' AND apt_es_tratamiento_eficaz = 1 AND YEAR(apt_fecha_evaluacion_eficacia) >= 2025)
    THROW 51000, N''aud_plan_tratamiento no archivó la fecha real del servidor del dictamen'', 1;', 0;

-- --- C5: vw_inventario_activo_documental_mr04 consolidada (cte_air_agg) y filtros de catálogo ---
EXECUTE #espera N'v2.3 C5: vw_inventario_activo_documental_mr04 usa cte_air_agg y alinea filtros sdo_estado/sbd_estado', N'
IF CHARINDEX(N''cte_air_agg'', OBJECT_DEFINITION(OBJECT_ID(N''sgspi.vw_inventario_activo_documental_mr04''))) = 0
   OR CHARINDEX(N''sdo.sdo_estado = 1'', OBJECT_DEFINITION(OBJECT_ID(N''sgspi.vw_inventario_activo_documental_mr04''))) = 0
    THROW 51000, N''vw_inventario_activo_documental_mr04 no aplica optimización C5'', 1;
SELECT TOP (1) * INTO #c5_chk FROM sgspi.vw_inventario_activo_documental_mr04;', 0;


GO
DROP USER sgspi_prueba_login;

DROP USER sgspi_prueba_consulta;

DROP USER sgspi_prueba_ejecucion;

DROP USER sgspi_prueba_migracion;


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