# Revisión de diseño — `DDL_SGSPI_SQLSERVER2019_v2.sql`

Base: commit `560d5eb` (2026-11-17). Revisión por lectura del DDL, de `PRUEBAS_DDL_SGSPI_v2.sql` y de `ESPECIFICACION_ARQUITECTURA_SGSPI.md`. No se ejecutó contra SQL Server.

Escala: **5** sin hallazgos · **4** detalles menores · **3** brechas relevantes · **2** deficiente · **1** ausente.
**Baja = 3 o menos → entra al plan (sección 3).**

## 1. Resumen

| # | Dimensión | Nota | Hallazgo principal |
|---|---|:-:|---|
| 1 | Normalización y dependencias | 4 | 3FN con derivados como columnas calculadas; quedan una bandera derivable y una referencia sin entidad. |
| 2 | Claves y restricciones | 3 | Base declarativa muy sólida, pero el creador lo envía el cliente (anula la SoD) y varias reglas de estado no se validan. |
| 3 | Antipatrones estructurales | 3 | Doble semántica de baja, listas de columnas copiadas a mano en triggers, estados "por datos" escritos en código. |
| 4 | Cardinalidad y opcionalidad | 3 | Propietario 0..N, plan 0..1 aun aprobado, actividad sin responsable. |
| 5 | Tipos de datos y precisión | 4 | Buenas elecciones; hash con dos representaciones, plazo de reserva 1..100. |
| 6 | Almacenamiento y clustering | 5 | Claves clustered estrechas y crecientes; filas bajo 8 060 B. |
| 7 | Estrategia de indexación | 4 | Todas las FK indexadas, redundantes retirados; leve sobreindexación en firmas de `eia`. |
| 8 | Volumetría y particionamiento | 4 | No particiona, correcto para este volumen; falta la estimación escrita. |
| 9 | Aislamiento y privilegios mínimos | 3 | Roles y DENY por columna bien hechos; sin alcance por proceso, GRANT sobrante al comité, vista que expone el directorio de `dbo`. |
| 10 | Trazabilidad y auditoría | **1** | Bitácora y tablas temporales retiradas: no se sabe quién cambió qué ni qué valor tenía. |
| 11 | Protección de datos sensibles | **2** | Vulnerabilidades e información reservada legibles por la cuenta compartida; sin RLS ni máscara. |
| 12 | Convenciones y claridad semántica | 3 | Convención aplicada con rigor, pero la cabecera y la especificación describen otra cosa. |
| 13 | Concurrencia y bloqueos | **2** | Sin control optimista, consecutivos calculados por la app, comprobaciones padre-hijo sin bloqueo. |
| 14 | Compatibilidad de despliegue | 3 | Prechequeos y transacción única ejemplares; la dependencia login ↔ persona ↔ rol no se verifica. |

## 2. Evaluación por dimensión

### 1. Normalización y dependencias — 4
- Bien: derivados como columnas PERSISTED (`acf_identificador_factor`, niveles CID, criticidad, `mvr_codigo_posicion`, vencimiento de reserva); redundancia controlada por FK compuesta (`plt_naturaleza_evento` L1245/L1274-1275, `efc_dominio` constante).
- `sdo_tiene_subseries` (L819) se deriva de la existencia de subseries y puede desincronizarse; TR_ado confía en la bandera (L2025-2032).
- `eia_identificador_evento` (L1142) repite la naturaleza en el prefijo `RA-`/`OA-`; el CHECK L1184 la mantiene coherente. Aceptable, aunque `acf` resuelve lo mismo con columna calculada.
- `rpc_numero_pregunta` (L516) apunta a una pregunta que no existe como entidad (número sin referencia).
- `aci_es_transversal_sedes` (L595) y la tabla `ais` pueden contradecirse.

### 2. Claves y restricciones — 3
- Bien: toda restricción con nombre; FK compuestas para coherencia entre tablas (causal ↔ nivel L645, taxonomía L562, naturaleza L1274-1275); índices únicos filtrados (L223, L786, L1391).
- **Creador falsificable.** `per_codigo_creador` lo envía el cliente en el INSERT y ningún trigger lo valida (solo hay DENY UPDATE, L2920-2932). Quien declara a otra persona como creadora puede aprobar su propio registro: `CK_acf_sod_aprobador` (L410), `CK_rpi_sod_aprobador` (L497), `CK_aci_sod_aprobador` (L700) y `CK_eia_sod_firmas` (L1193) quedan sin efecto.
- `mvr_requiere_aprobacion_comite` (L1123) no se usa en ningún lugar: `EN_REVISION_SGSPI → APROBADO_PLANIFICADO` se permite aunque la celda exija comité.
- Estados sin su dato obligatorio: `APROBADO_PLANIFICADO` sin plan de tratamiento; `CERRADO_EFICAZ` con `plt_es_tratamiento_eficaz` = 0 o NULL.
- `eia.pri_codigo` (L1144) no se liga a los procesos del activo (`aip`): un riesgo puede quedar en un proceso al que el activo no pertenece.
- RESERVADA admite reserva indefinida y plazos de hasta 100 años (L658, L666). El art. 22 de la Ley 1712 de 2014 limita la reserva a 15 años, como cita el propio comentario de L605.
- Una vigencia `CERRADA` o `HISTORICA` (L202) no bloquea escrituras sobre sus registros.

### 3. Antipatrones estructurales — 3
- Bien: sin EAV general, multivaluados eliminados (`rpc`, `cra`, `adf`), supertipo/subtipo con PK compartida (L938-953).
- **Doble semántica de "inactivo"**: `<acr>_esta_activo` en las 50 tablas y, en `aci`, los estados `INACTIVO`/`HISTORICO`. Ninguna vista filtra el `esta_activo` de la entidad principal: `vw_resumen_activos_criticidad` (L3234) cuenta activos VIGENTE dados de baja, y lo mismo pasa en `vw_consolidado_dofa`, `vw_matriz_tratamiento_riesgos` y `vw_inventario_activo_documental_mr04`.
- **Listas de columnas copiadas a mano** en los EXCEPT de cinco triggers (p. ej. L1847-1931): una columna nueva que no se agregue a la lista queda editable durante las transiciones, sin aviso. Además hay 11 triggers puente casi idénticos (L2503-2849).
- **Estados "por datos" escritos en código**: `'VIGENTE'` y `'EN_REVISION_ARCHIVO'` en las firmas (L1624, L1942, L2175), `'BORRADOR'` en CHECK (L404, L661, L681), `'COMPLETADA'` (L1330). Renombrar un estado en `efc` rompe reglas sin que nada falle.

### 4. Cardinalidad y opcionalidad — 3
- `air` (L748-760) admite de 0 a N propietarios activos: un activo VIGENTE puede quedar sin propietario (ISO/IEC 27001 A.5.9) o con varios.
- `plt` es 0..1 por evento (L1272) incluso en `APROBADO_PLANIFICADO`; `act` es 0..N.
- `act.car_codigo` y `act.uaa_codigo` admiten NULL (L1312-1313): actividad sin responsable aun en curso.
- `eia` fija exactamente un activo primario y uno de soporte (L1145-1146): un escenario con varios activos de soporte obliga a duplicar el evento.
- `ado.pev_codigo` es obligatorio (L940), pero el supertipo `aci` no tiene vigencia: asimetría sin explicar.

### 5. Tipos de datos y precisión — 4
- Bien: `DATETIMEOFFSET(0)`, `DECIMAL(18,2)` para COP, escalas en TINYINT, BIT trivalente, ningún `MAX`.
- `sga_hash_sha256_evidencia CHAR(64)` (L1350) acepta mayúsculas y minúsculas (L1366): el mismo hash tiene dos representaciones. Usar `BINARY(32)` o forzar minúsculas.
- `aci_anios_plazo_reserva` 1..100 (ver dimensión 2). `pev_anio` sin rango.
- Códigos ASCII guardados en NVARCHAR (estados, naturalezas): menor, sin acción.

### 6. Almacenamiento y clustering — 5
- PK clustered en IDENTITY estrechas y crecientes; tablas puente clustered por (padre, hijo) con índice inverso. El tamaño máximo de fila de `eia` y `plt` (≈ 7,2–7,7 KB) queda bajo el límite de 8 060 B. Sin acción.

### 7. Estrategia de indexación — 4
- Todas las FK tienen índice, los redundantes se retiraron (AP-18) y los INCLUDE son selectivos.
- `eia` tiene 9 índices no clustered, 4 sobre columnas de firma (L1216-1226) que solo sirven al borrar en `dbo.persona`. Costo despreciable a este volumen; sin acción.

### 8. Volumetría y particionamiento — 4
- No particiona, lo cual es correcto para 21 procesos, unos 194 activos, unas 240 filas TRD y decenas de riesgos por vigencia. Falta una línea de estimación de crecimiento y retención en la especificación. Sin acción de código.

### 9. Aislamiento y privilegios mínimos — 3
- Bien: roles por actor, `DENY ALTER`/`DELETE` a nivel de esquema, DENY por columna en firmas y fechas, transición por rol (`tef_rol_requerido`) y pruebas de permisos.
- **Sin alcance por proceso/UAA en el motor**: cualquier líder o custodio escribe en activos, riesgos y DOFA de cualquier proceso. La especificación lo deja en la aplicación (L675), pero en L183 y L651 lo llama "Row-Level Security".
- **GRANT sobrante**: el comité tiene `UPDATE(rpi_estado_registro)` (L3033-3034) y no existe ninguna transición RPI asignada al comité; solo le sirve para mover borradores ajenos (las transiciones con rol NULL).
- **Directorio expuesto**: `vw_usuario_rol_alcance_sgspi` (L3134-3168) no filtra los grupos `SGSPI_*`. Por encadenamiento de propiedad, todo `sgspi_rol_base` (incluida la cuenta compartida) lee nombre, grupo y UAA de todos los usuarios de academia3000.
- Identidad con dos fuentes: las firmas usan `ORIGINAL_LOGIN()` y los roles `IS_MEMBER()`; con `EXECUTE AS` divergen.
- No hay script que mantenga la membresía de roles alineada con `dbo.usuario_grupo` (L2861: "lo hace el DBA").

### 10. Trazabilidad y auditoría — 1
- AP-01 y AP-21 retiraron la bitácora y las tablas temporales (L50-52). Solo quedan `fecha_creacion`/`fecha_actualizacion` y la **última** firma, que se sobrescribe al reabrir y volver a aprobar.
- No se puede responder "¿quién cambió la clasificación de este activo, el SoA o la valoración de este riesgo, y qué valor tenía antes?". Para un SGSPI esto choca con ISO/IEC 27001 7.5.3 (control de la información documentada) y A.8.15 (registro de eventos).
- Firmas que siguen en manos del cliente: el creador (en todas las tablas), `per_codigo_evaluador` y `plt_fecha_evaluacion_eficacia` (GRANT al auditor en L3117; ninguna regla compara el evaluador con la persona de la sesión) y `sga.per_codigo`.
- `eac` (SoA) no tiene estado ni firma: el oficial cambia `CUMPLE`/`NO_CUMPLE` sin rastro.

### 11. Protección de datos sensibles — 2
- `GRANT SELECT ON SCHEMA::sgspi TO sgspi_rol_base` (L2898): la cuenta compartida lee `eia_condicion_vulnerabilidad`, `eia_controles_existentes`, los fundamentos de reserva y la finalidad PII de todos los activos. Las vulnerabilidades son el dato más sensible del sistema.
- Directorio institucional expuesto por la vista (dimensión 9).
- Sin máscara dinámica, RLS ni cifrado de columna. TDE y backups cifrados no se mencionan (SQL Server 2019 Standard ya incluye TDE).
- Bien: la vista ya no expone identificación ni correo, y el esquema guarda metadatos de activos, no datos personales.

### 12. Convenciones y claridad semántica — 3
- Bien: prefijos de 3 letras, nombres de restricción uniformes (PK_/FK_/UQ_/CK_/DF_) y mapa de acrónimos.
- La regla escrita (L9-13: "toda columna inicia con el acrónimo local"; FK = `<acr_local>_<acr_remoto>_codigo`) no es la que se aplica (FK = `<acr_remoto>_codigo[_rol]`), y su propio ejemplo `[pev_codigo]` la contradice.
- Variantes del mismo concepto: `_esta_activo` (36 tablas) y `_esta_activa` (14); `_estado_registro`, `act_estado_actividad` y `pev_estado_vigencia`; índices únicos con prefijo `UQ_` (L415, L786) y `UX_` (L223, L1391).
- Cabecera desactualizada: AP-03 (L56-57) dice que la BD no puede verificar quién opera, pero los triggers ya firman con `ORIGINAL_LOGIN()`.
- `ESPECIFICACION_ARQUITECTURA_SGSPI.md` describe otro sistema: 13 líneas citan `bitacora_auditoria_sistema`, `usp_establecer_contexto_auditoria`, tablas `*_historial` o "53 tablas"; RN-INT-01 (L466) exige un contexto de auditoría que ya no existe; L540 dice que el **auditor** certifica `CERRADO_EFICAZ`, pero el DDL se lo asigna al **oficial** (L286).
- Comentarios "Campo Calculado en Tiempo de Ejecución" sobre columnas PERSISTED (L463, L474, L619).

### 13. Concurrencia y bloqueos — 2
- **Sin control optimista**: ninguna tabla tiene `ROWVERSION`. Si dos personas editan el mismo activo, gana la última sin aviso.
- **Consecutivos sin estrategia**: `acf_numero_factor`, `RA-nn`/`OA-nn`, `act_numero_orden` y `aci_codigo_inventario` los calcula la aplicación; no hay SEQUENCE, procedimiento ni patrón documentado. Dos altas simultáneas chocan con el UNIQUE.
- **Write skew padre-hijo**: las comprobaciones de "padre no editable" (TR_ado, TR_plt, TR_act y los 11 puentes) leen el padre sin `UPDLOCK`. Un hijo puede insertarse justo cuando el padre pasa a VIGENTE; con READ_COMMITTED_SNAPSHOT la ventana es mayor.
- Orden de bloqueo inverso: `aci → ado` en TR_aci (L1963) frente a `ado → aci` en TR_ado (L2001). Puede haber deadlock en `EN_REVISION_ARCHIVO → EN_REVISION_SGSPI`; la app debe reintentar ante el error 1205.
- `TOP (1)` sin `ORDER BY` al resolver la persona de la sesión (L1626 y sus equivalentes).

### 14. Compatibilidad de despliegue — 3
- Bien: verifica compatibilidad 150, dependencias de `dbo` y esquema vacío; una sola transacción con guardas NOEXEC; solo usa funciones de SQL Server 2017+ disponibles en todas las ediciones.
- **Dependencia no verificada**: cada persona que escribe necesita un usuario de BD en un único rol de actor y que `ORIGINAL_LOGIN()` coincida con `dbo.usuario_general.us`. Si falta, toda aprobación falla con 50017 y toda transición con rol falla con 50011, y nada lo detecta al desplegar.
- Solo instalación inicial: no hay migración v1 → v2 (`sql_propuesta/migrations` es del esquema `dbo`) ni marcador de versión del esquema.
- Un error de compilación no revierte la transacción salvo con `sqlcmd -b` (ya documentado en L111).

## 3. Plan de corrección

Ordenado por riesgo. Cada paso trae el cambio mínimo y su prueba en `PRUEBAS_DDL_SGSPI_v2.sql`.
Esfuerzo: **S** menos de 1 h · **M** medio día · **L** 1–2 días.

### Fase 1 — Firmas y reglas de negocio (dimensiones 2 y 10). Bloqueante.

**Estado:** fase completa: pasos 1–4 (errores nuevos 50019 y 50020, AP-23) y paso 5 tras la decisión D4.

1. **Sellar al creador [S]** — en TR_acf, TR_rpi, TR_aci y TR_eia:
   - Resolver `@per_actor` una sola vez al inicio (`… WHERE u.us = ORIGINAL_LOGIN() ORDER BY u.uid`), exigirlo en toda escritura (hoy solo en aprobaciones) y reutilizarlo en las firmas.
   - En INSERT: `IF EXISTS (SELECT 1 FROM inserted AS i WHERE NOT EXISTS (SELECT 1 FROM deleted AS d WHERE d.<pk> = i.<pk>) AND i.per_codigo_creador <> @per_actor) THROW 50019, …`.
   - Lo mismo para `sga.per_codigo` (en TR_sga_sincronizar_avance, que ya es AFTER INSERT).
   - Pruebas: INSERT con creador distinto de la persona de la sesión → 50019. Los fixtures que hoy insertan con creador 1 y sesión 2 deben usar 2; para probar la SoD, cambiar `dbo.usuario_general.up` entre pasos (la base de prueba es desechable).
2. **Firma del evaluador [S]** — en TR_plt, cuando `plt_es_tratamiento_eficaz` pasa de NULL a un valor: exigir `per_codigo_evaluador = @per_actor` y fijar `plt_fecha_evaluacion_eficacia = SYSDATETIMEOFFSET()` en el `UPDATE t` que ya existe. El GRANT del auditor se mantiene porque `CK_plt_coherencia_eficacia` exige los cuatro campos en la misma sentencia. Prueba: el auditor firma como otra persona → 50019.
3. **Reglas de estado en TR_eia [S]** — tres `IF EXISTS … THROW 50020` en la transición:
   - `→ APROBADO_PLANIFICADO` exige un `plt` activo.
   - `EN_REVISION_SGSPI → APROBADO_PLANIFICADO` se rechaza si la celda inherente tiene `mvr_requiere_aprobacion_comite = 1`.
   - `→ CERRADO_EFICAZ` exige `plt_es_tratamiento_eficaz = 1`.
   - Una prueba por regla.
4. **Plazo legal de la reserva [S]** — confirmar antes con la oficina jurídica:
   ```sql
   CONSTRAINT CK_aci_reserva_plazo_legal CHECK (aci_clasificacion_transparencia <> N'RESERVADA'
       OR (ISNULL(aci_es_reserva_indefinida, 0) = 0 AND ISNULL(aci_anios_plazo_reserva, 0) <= 15))
   ```
   Prueba: RESERVADA indefinida → 547.
5. **Evento ↔ proceso del activo [S]** — solo si la regla aplica (decisión D4):
   `CONSTRAINT FK_eia_activo_proceso FOREIGN KEY (aci_codigo_primario, pri_codigo) REFERENCES sgspi.activo_informacion_proceso_institucional (aci_codigo, pri_codigo)`, y cambiar `IX_eia_aci_codigo_primario` a `(aci_codigo_primario, pri_codigo)`. Los fixtures deben crear la fila en `aip` antes del evento.

### Fase 2 — Trazabilidad (dimensión 10) [M]

**Estado:** aplicada con otra técnica, según D1: en lugar de tablas temporales, una tabla `aud_<tabla>` por cada tabla del esquema, siguiendo `sql/sgspi/aud_periodo_vigencia.sql` (sección 5.9 del DDL). La descripción de abajo queda como alternativa descartada.

6. **Historial nativo** en `acf, rpi, aci, ado, eia, plt, act, eac`:
   ```sql
   <acr>_valido_desde DATETIME2(0) GENERATED ALWAYS AS ROW START HIDDEN NOT NULL,
   <acr>_valido_hasta DATETIME2(0) GENERATED ALWAYS AS ROW END HIDDEN NOT NULL,
   PERIOD FOR SYSTEM_TIME (<acr>_valido_desde, <acr>_valido_hasta)
   -- …
   ) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = sgspi.<tabla>_historial));
   ```
   - Columna `<acr>_per_codigo_modificador INT NULL` (FK a `dbo.persona`) que el trigger llena con `@per_actor` en su `UPDATE t` actual; agregarla al DENY UPDATE de L2916-2941. Así cada versión guarda quién la produjo.
   - Las tablas de historial no se pueden escribir mientras el versionado está activo, y el `DENY ALTER` de L2901 impide apagarlo.
   - Las columnas de periodo deben ser `DATETIME2` (UTC): excepción explícita a AP-12. El `UPDATE` del propio trigger genera versiones de duración cero, que `FOR SYSTEM_TIME AS OF` y `BETWEEN` omiten.
   - Las columnas nuevas no van en los EXCEPT. Actualizar AP-01 y AP-11 en la cabecera.
   - Prueba: aprobar un activo y comprobar en `FOR SYSTEM_TIME ALL` dos versiones con modificador distinto.
   - Opcional (DBA, fuera del script): SQL Server Audit con una `DATABASE AUDIT SPECIFICATION` para `INSERT, UPDATE ON SCHEMA::sgspi BY public`.

### Fase 3 — Concurrencia (dimensión 13)

**Estado:** fase completa: pasos 7–9 aplicados al DDL, a las pruebas y a la especificación (AP-24).

7. **Control optimista [S]** — `<acr>_version ROWVERSION NOT NULL` en las 8 tablas con flujo. La app actualiza con `WHERE <acr>_codigo = @id AND <acr>_version = @v` y vuelve a leer después de guardar (el `UPDATE` del trigger cambia la versión). La columna no va en los EXCEPT. Prueba: un UPDATE con la versión vieja afecta 0 filas.
8. **Consecutivos [S]** — documentar en la cabecera un único patrón, sin objetos nuevos:
   ```sql
   INSERT sgspi.analisis_contexto_factor (…, acf_numero_factor, …)
   SELECT …, ISNULL(MAX(acf_numero_factor), 0) + 1, …
   FROM sgspi.analisis_contexto_factor WITH (UPDLOCK, HOLDLOCK)
   WHERE pev_codigo = @pev AND acf_naturaleza_factor = @naturaleza;
   ```
   Lo mismo para `RA-nn`/`OA-nn` por vigencia y para `act_numero_orden` por plan. La app reintenta ante los errores 2601/2627.
9. **Bloqueo del padre [S, mecánico]** — en TR_ado, TR_plt, TR_act y los 11 triggers puente, leer el padre con `WITH (UPDLOCK)` (p. ej. `INNER JOIN sgspi.activo_informacion AS p WITH (UPDLOCK)`). Documentar el reintento ante el error 1205.

### Fase 4 — Privilegios y datos sensibles (dimensiones 9 y 11)

**Estado:** aplicados los pasos 10, 11, 12 (vulnerabilidades fuera de `sgspi_rol_consulta`) y 13 (en triggers: `ufn_proceso_en_alcance` y `ufn_activo_en_alcance`, error 50021). El paso 14 queda en operación del DBA.

10. **Vista de alcance [S]** — en `vw_usuario_rol_alcance_sgspi`, agregar `AND g.gru_nombre LIKE N'SGSPI[_]%'`. Prueba: un usuario de un grupo ajeno al SGSPI no aparece.
11. **GRANT del comité sobre `rpi` [S]** — borrar L3033-3034 y ajustar la prueba de L290, que hoy afirma que el comité puede hacerlo.
12. **Cuenta compartida fuera de `sgspi_rol_base` [M]** — crear `sgspi_rol_consulta` con SELECT solo sobre catálogos y vistas sin vulnerabilidades. `eia`, `plt` y los campos de reserva y PII de `aci` se leen con la conexión del usuario, que ya existe para escribir. Requiere decidir en la app qué pantallas usan la cuenta compartida.
13. **Alcance de escritura por proceso [L, opcional]** — `SECURITY POLICY` con `BLOCK PREDICATE` (AFTER INSERT, BEFORE UPDATE y AFTER UPDATE) sobre `acf` y `eia`, que tienen `pri_codigo`, para líder y custodio: `ORIGINAL_LOGIN()` → `usuario_grupo` → `proceso_institucional_uaa`. Oficial, comité, auditor y `db_owner` pasan. Si se mantiene la decisión de L675 (alcance en la app), registrarla como riesgo aceptado y quitar "Row-Level Security" de L183 y L651.
14. **Cifrado en reposo [DBA]** — TDE o, como mínimo, backups cifrados.

### Fase 5 — Antipatrones, cardinalidad, convenciones y despliegue (dimensiones 3, 4, 12 y 14)

**Estado:** aplicados los pasos 15–21 y 23. El paso 22 (opcional) se omite y el paso 24 no aplica (D6: no hay datos de ninguna versión).

15. **Baja lógica coherente [S]** — filtrar `<acr>_esta_activo = 1` en la entidad principal de las vistas de reporte (acf L3195, aci L3234, eia y plt L3304, ado y aci L3556) y escribir en AP-22: `esta_activo = 0` significa registro anulado por error; `INACTIVO`/`HISTORICO` son etapas del ciclo de vida.
16. **Guarda de los EXCEPT [S]** — una prueba que recorra `sys.columns` de las tablas con flujo (sin calculadas, estado, firmas, versión ni periodo) y falle si alguna columna no aparece en `OBJECT_DEFINITION` de su trigger.
17. **Estados usados en código [S]** — junto a la semilla de `efc`, un comentario con los identificadores que no se pueden renombrar (`BORRADOR`, `VIGENTE`, `EN_VALIDACION_LIDER`, `EN_REVISION_ARCHIVO`, `EN_REVISION_SGSPI`, `EN_ACEPTACION_COMITE`, `APROBADO_PLANIFICADO`, `COMPLETADA`) y una prueba de que existen.
18. **Propietario del activo [S]** — en TR_aci, exigir un PROPIETARIO activo en `air` para entrar a `EN_REVISION_SGSPI` o `VIGENTE`. Si el procedimiento exige uno solo (decisión D3):
    `CREATE UNIQUE NONCLUSTERED INDEX UX_air_propietario_activo ON sgspi.activo_informacion_responsable (aci_codigo) WHERE air_tipo_responsabilidad = N'PROPIETARIO' AND air_esta_activo = 1;`
19. **Responsable de la actividad [S]** — `CONSTRAINT CK_act_responsable CHECK (act_estado_actividad = N'PENDIENTE' OR (car_codigo IS NOT NULL AND uaa_codigo IS NOT NULL))`.
20. **Derivar las subseries [S]** — borrar `sdo_tiene_subseries` (y su DEFAULT) y, en TR_ado, preguntar si existe una subserie activa de la serie.
21. **Cabecera y especificación [S]**:
    - Corregir la regla de FK (L9-13), AP-03 (L56-57) y los comentarios "en tiempo de ejecución" de columnas PERSISTED.
    - Prefijo `UX_` para todos los índices únicos: renombrar L415 y L786.
    - Sincronizar la especificación con el DDL (las 13 líneas de objetos retirados, RN-INT-01, el conteo de tablas).
    - Resolver quién cierra `CERRADO_EFICAZ` (decisión D2). Si es el auditor: cambiar `tef_rol_requerido` de las dos transiciones que salen de `EN_EVALUACION_EFICACIA` hacia `CERRADO_EFICAZ` y `EN_EJECUCION` y darle `UPDATE(eia_estado_registro)`. Mejora la SoD, porque hoy el oficial aprueba el plan y también certifica su eficacia.
22. **`_esta_activa` → `_esta_activo` [M, opcional]** — 14 columnas. Conviene solo antes del primer despliegue con la aplicación.
23. **Verificación posterior al despliegue [S]** — una consulta de solo lectura al final del script que liste: miembros de grupos `SGSPI_*` sin usuario de BD o con otro rol; usuarios de BD en roles de actor sin fila en `usuario_general.us`; usuarios en más de un rol de actor.
24. **Versión del esquema [S]** — `EXECUTE sys.sp_addextendedproperty N'sgspi_version', N'2.1', N'SCHEMA', N'sgspi';`. Si la v1 está desplegada con datos, falta además un script de migración (decisión D6).

### Decisiones (respondidas el 2026-11-18)

| # | Pregunta | Respuesta | Aplicado |
|---|---|---|---|
| D1 | ¿Se reintroduce el historial? | Una tabla de auditoría por tabla, como `sql/sgspi/aud_periodo_vigencia.sql` | 50 tablas `aud_*` (sección 5.9) |
| D2 | ¿Quién certifica `CERRADO_EFICAZ`? | El auditor dictamina y cierra | `tef`, GRANT y TR_plt |
| D3 | ¿Un único propietario por activo? | Sí, y obligatorio para aprobar | `UX_air_propietario_activo` y TR_aci (50020) |
| D4 | ¿El riesgo debe estar en un proceso de su activo? | Sí; los activos compartidos se asocian una vez a cada proceso | `FK_eia_activo_proceso` |
| D5 | ¿Alcance por proceso en la BD? | Bloquear al menos las modificaciones y quitar las vulnerabilidades a la cuenta compartida | Triggers (50021) y `sgspi_rol_consulta` |
| D6 | ¿La v1 está desplegada con datos? | No hay datos de ninguna versión | Sin migración |

### Efecto esperado

| Dimensión | Hoy | Tras el plan |
|---|:-:|:-:|
| 2 Claves y restricciones | 3 | 4–5 |
| 3 Antipatrones | 3 | 4 |
| 4 Cardinalidad | 3 | 4 |
| 9 Privilegios mínimos | 3 | 4 (5 con el paso 13) |
| 10 Trazabilidad | 1 | 4 |
| 11 Datos sensibles | 2 | 4 |
| 12 Convenciones | 3 | 4–5 |
| 13 Concurrencia | 2 | 4 |
| 14 Despliegue | 3 | 4 |
