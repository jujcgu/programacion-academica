# Revisión de diseño, tercera ronda — `DDL_SGSPI_SQLSERVER2019_v2.sql`

Base: commit `e91c9e5` (HEAD, copia de trabajo limpia; las líneas `L####` son de ese commit). Parte de la segunda ronda (`REVISION_DDL_SGSPI_v2_2026-11-18.md`), cuyas fases 1–4 y mejoras menores están confirmadas en `8e9b14a`…`17d5b8b`.

**Es la primera ronda ejecutada contra un motor.** Se usó SQL Server 2025 Developer (17.0.1000.7) de este equipo con una base desechable en `COMPATIBILITY_LEVEL = 150`, intercalación `Modern_Spanish_CI_AS`, stubs de `dbo` (anexo A) y `sqlcmd` v1.10 con `-I`. La base se borró al terminar. El script solo usa funciones de 2017 o anteriores (`STRING_AGG`, `TRIM`, `CONCAT_WS`, `CREATE OR ALTER`), así que el resultado vale para 2019, salvo diferencias del optimizador.

Escala: **5** sin hallazgos · **4** detalles menores · **3** brechas relevantes · **2** deficiente · **1** ausente.
**Baja = 3 o menos → entra al plan (sección 4).** Los detalles de las dimensiones con 4 van en la sección 5.

## 1. Resultado de la ejecución

| Paso | Resultado |
|---|---|
| Desplegar HEAD con `sqlcmd -b` | **Falla**: `Msg 102 … Procedure TR_adm_auditoria, Line 41: Incorrect syntax near ';'`. La transacción se revierte. |
| Desplegar HEAD sin `-b` (como SSMS) | Compila todo lo demás y **confirma**. La verificación posterior solo informa "Base sin TDE", así que da por bueno un esquema sin `TR_adm_auditoria` ni `TR_aid_inmutabilidad`. |
| Desplegar HEAD con el parche F0.1 | Despliega en ~1 s: 100 tablas, 112 triggers, 7 vistas, 3 funciones. |
| `PRUEBAS_DDL_SGSPI_v2.sql` sobre el parche | **185 de 188 pasan.** Las 3 fallas (L180, L315, L728) esperan 50010/50016 al borrar y reciben 547 de la FK `aud_* → origen` (dimensión 2). |
| Tras aplicar la fase 0 en el repo | Despliega con `-b`, **188 de 188** pruebas pasan y un lote roto sin `-b` revierte todo. |
| Tras aplicar la fase 1 | **189 de 189** (se suma T1) y la auditoría del servidor del repo registra lo probado en T3. |
| Tras aplicar la fase 2 (A2) | **190 de 190**; el identificador del evento sale calculado (1 → `RA-01`, 100 → `RA-100`). |
| Tras aplicar las mejoras menores | **199 de 199**; la verificación posterior ya no da el falso positivo de (g). |

Origen del defecto:
- `d0df220` ("Datos sensibles") truncó `TR_aid_inmutabilidad`.
- `17d5b8b` ("Mejoras menores"), al cambiar las 53 copias de `TOP (1) … ORIGINAL_LOGIN()` por `ufn_persona_sesion()`, borró 43 líneas: la rama `'U'` de `TR_adm_auditoria`, su `END`/`GO` y lo que quedaba de `TR_aid_inmutabilidad` (hunk `@@ -8980,49 +8940,6 @@`).

El script no despliega desde `d0df220`. Las rondas anteriores no lo vieron porque nunca se ejecutaron.

## 2. Resumen

| # | Dimensión | Ronda 2 | Hoy | Hallazgo principal |
|---|---|:-:|:-:|---|
| 1 | Normalización y dependencias | 4 | 4 | Sin cambios de fondo; siguen `aci_es_transversal_sedes` contra `ais`, `rpc` sin entidad y dos enumeraciones en texto libre. |
| 2 | Claves y restricciones | 3 | 4 | Fase 2 verificada en el motor. Nuevo: la DOFA no amarra naturaleza con ámbito (entra una AMENAZA sobre un factor INTERNO). |
| 3 | Antipatrones estructurales | 4 | **3** | La lógica copiada produjo el defecto: el reemplazo de las 53 copias truncó dos triggers y nada lo detectó. |
| 4 | Cardinalidad y opcionalidad | 4 | 4 | C3 verificado. Queda una sola categoría de dato personal por activo y `eac.car_codigo` opcional. |
| 5 | Tipos de datos y precisión | 4 | 4 | KPI y hash corregidos y probados; quedan enumeraciones en texto libre. |
| 6 | Almacenamiento y clustering | 5 | 5 | Medido: `aud_plan_tratamiento` ocupa 7 940 B de 8 060 B. |
| 7 | Estrategia de indexación | 4 | 4 | La comprobación (g) mira la vista `usuario_general`, que no tiene índices: en producción siempre alarma y nunca revisa las 7 tablas base. |
| 8 | Volumetría y particionamiento | 4 | 5 | Estimación y retención escritas (RN-INT-17); particionar no hace falta. |
| 9 | Aislamiento y privilegios mínimos | 3 | 4 | Fase 1 verificada con `EXECUTE AS`. Quedan la lectura sin alcance (D5) y el origen del alcance fuera del esquema. |
| 10 | Trazabilidad y auditoría | 3 | **3** | En HEAD una `aud_*` no es inmutable y `adm` no audita cambios. Los cambios de alcance en `dbo.usuario_grupo` no dejan rastro y la auditoría del servidor no se ha probado. |
| 11 | Protección de datos sensibles | 3 | 4 | Fase 4 verificada (229 en `eia`, `plt` y `aud_*`). Falta confirmar TDE. |
| 12 | Convenciones y claridad semántica | 4 | 4 | Versión 2.0 contra 2.1; acrónimos de auditoría que se confunden con los de negocio (`adi`/`aid`). |
| 13 | Concurrencia y bloqueos | 4 | 4 | Sin hallazgos nuevos; el reintento sigue a cargo de la app. |
| 14 | Compatibilidad de despliegue | 4 | **2** | HEAD no despliega. Sin `-b` confirma un esquema incompleto y lo da por bueno. |

## 3. Evaluación por dimensión

### 1. Normalización y dependencias — 4
- Bien: derivados calculados PERSISTED, FK compuestas, catálogo `zrc` y avance derivado de `sga`, que ahora se recalcula al anular un seguimiento (probado).
- Siguen abiertos desde la ronda 1: `aci_es_transversal_sedes` (L667) contra `ais`, y `rpc_numero_pregunta` (L588) sin entidad de cuestionario.
- Enumeraciones en texto libre: `eac_frecuencia_revision` (L1554) repite lo que ya modela `periodicidad_catalogo`, y `plt_unidad_medida_kpi` (L1345) tiene sus valores solo en un comentario.

### 2. Claves y restricciones — 4
- Fase 2 verificada en el motor: C1 (`RA-001` → 547), C2 (firma fuera del `IF NOT UPDATE`), C3 (cinco reglas → 50020) y C4 (vigencia cerrada → 50022) pasan.
- **DOFA sin coherencia entre naturaleza y ámbito.** En la DOFA, debilidades y fortalezas son factores internos, y amenazas y oportunidades, externos. `acf` (L443) no lo exige: en la base de prueba entró `A1` = AMENAZA sobre el factor `INTERNO` "Tecnológico". Se corrige con el patrón de AP-06 (columna calculada + FK compuesta), ya probado (sección 5).
- Los fundamentos constitucional/legal y jurídico de la reserva siguen como validación de la app (RN-DOC-03), aunque el Índice de Información Clasificada y Reservada los pide. Caben en `CK_aci_coherencia_indice_reserva` (L738).
- La FK de cada `aud_*` a su tabla de origen se evalúa antes que el trigger. Como desde T1 toda fila tiene su alta `'I'`, un `DELETE` físico ya no recibe 50010/50016 sino 547. Sigue bloqueado, pero las pruebas y la cabecera (L80) prometen otro error.

### 3. Antipatrones estructurales — 3
- Bien: sin EAV, multivaluados normalizados, supertipo/subtipo con PK compartida y máquina de estados en datos.
- **La lógica copiada produjo un defecto real.** Hay 112 triggers, unas 4 300 líneas de auditoría casi idénticas y listas de columnas escritas tres veces por tabla. La ronda 2 daba el riesgo por mitigado con pruebas, pero las pruebas no se corrían. Un reemplazo masivo (`17d5b8b`) truncó dos triggers y el script dejó de desplegar. Ni la prueba de columnas (PRUEBAS L75) ni la verificación posterior comprueban que cada `aud_*` tenga su trigger de inmutabilidad y cada tabla su trigger de auditoría.
- **Las pruebas no se pueden correr sin preparar una base a mano.** El repo no trae los stubs de `dbo` que necesitan: personas 1–3, UAA 1, cargo 1 y el login mapeado a la persona 2, con `usuario_general` como tabla porque `#sesion_como` la actualiza. Por eso nadie las ejecutó.
- `eia_identificador_evento` (L1224) sigue siendo una clave "inteligente". El número se extrae con `SUBSTRING` (AP-24, L145) y el CHECK (L1268) ocupa 10 líneas, mientras `acf` usa número + identificador calculado.

### 4. Cardinalidad y opcionalidad — 4
- C3 verificado: un plan sin actividades no llega a evaluación y el custodio es obligatorio para aprobar.
- `aci_categoria_dato_personal` (L684) admite una sola categoría. Un activo con datos SENSIBLES y PRIVADOS solo puede registrar una (D13).
- `eac.car_codigo` (L1553) sigue opcional en un control aplicable.
- `ado.pev_codigo` (L1021) ata el subtipo documental a una vigencia, pero el supertipo `aci` no tiene vigencia. No está escrito qué pasa con el activo documental al año siguiente.

### 5. Tipos de datos y precisión — 4
- Probados: el KPI en `DECIMAL(15,2)` (meta 1, alcanzado 100 000) y el hash solo en minúsculas con `Latin1_General_BIN2`.
- Quedan las enumeraciones en texto libre de la dimensión 1. `pev_anio` no tiene rango.

### 6. Almacenamiento y clustering — 5
- Medido en el motor: `aud_plan_tratamiento` 7 940 B, `plan_tratamiento` 7 683 B y `aud_evento_incertidumbre_activo` 7 460 B, frente al límite de 8 060 B por fila. No hace falta ninguna acción, pero cualquier columna de texto nueva en `plt` o `eia` lleva la fila a row-overflow.

### 7. Estrategia de indexación — 4
- Medido: 209 índices no clustered, 100 de ellos en `aud_*`. Todas las FK tienen índice.
- La comprobación (g) de la verificación posterior (L11492) busca índices en `dbo.usuario_general`. En producción es una **vista** `UNION` de 7 tablas (`sql/dbo/vistas/usuario_general.sql`), que no tiene índices: (g) siempre alarma y nunca revisa las tablas base que recorre cada escritura.
- Si `us` es `VARCHAR` en esas tablas, `u.us = ORIGINAL_LOGIN()` (L2970) convierte la columna a `NVARCHAR`. Con una intercalación `SQL_*` eso impide buscar por índice; `CONVERT (VARCHAR (128), ORIGINAL_LOGIN())` lo evita.

### 8. Volumetría y particionamiento — 5
- La estimación y la retención están escritas en RN-INT-17: menos de 50 000 filas al año en `aud_*`. Particionar no hace falta.

### 9. Aislamiento y privilegios mínimos — 4
- Fase 1 verificada con `EXECUTE AS USER`:
  - el dictamen es solo del auditor (el oficial recibe 230);
  - las transiciones van por rol;
  - el alcance es explícito;
  - el gestor hace su aval de Archivo.
- Asociar un activo a un proceso (`aip`) no da alcance, porque L5706-5722 valida el proceso y la UAA del activo.
- Residual aceptado por D5: todo rol de actor lee el esquema entero, incluido el mapa de vulnerabilidades de todos los procesos y las `aud_*` con logins.
- El origen del alcance está fuera del esquema. Quien escriba en `dbo.usuario_grupo` (la administración de academia3000) amplía el alcance de un líder o custodio, y eso no queda auditado (dimensión 10).

### 10. Trazabilidad y auditoría — 3
- Bien: altas `'I'` y versiones `'U'` con persona y fecha, probadas en `acf` y `air`.
- **En HEAD**, `aud_activo_documental_idioma` no tiene trigger de inmutabilidad (49 de 50) y `TR_adm_auditoria` no registra las modificaciones de `adm`. RN-INT-17 afirma lo contrario.
- **Los cambios de alcance no dejan rastro.** `auditoria_servidor.sql` audita DML solo `ON SCHEMA::sgspi` (L19), pero los grupos `SGSPI_*` y su UAA viven en `dbo.usuario_grupo` y `dbo.grupo`.
- **La auditoría del servidor no está probada ni completa:**
  - la base va escrita a mano (`USE academia3000`, L13);
  - no hay especificación de servidor (`SERVER_ROLE_MEMBER_CHANGE_GROUP`, `AUDIT_CHANGE_GROUP`) ni `DATABASE_PRINCIPAL_CHANGE_GROUP`;
  - la lectura del mapa de vulnerabilidades no deja evento;
  - `ON_FAILURE = CONTINUE` pierde eventos en silencio;
  - `MAX_ROLLOVER_FILES = 100` borra los archivos más viejos sin archivarlos (D10).

### 11. Protección de datos sensibles — 4
- Fase 4 verificada: la cuenta compartida lee las cinco vistas y recibe 229 en `eia`, `plt` y `aud_*`.
- Falta confirmar TDE en la instancia (la verificación posterior lo informa).
- No hay clasificación de sensibilidad (`ADD SENSITIVITY CLASSIFICATION`, disponible en 2019), que marcaría vulnerabilidades y datos personales en los registros de auditoría.

### 12. Convenciones y claridad semántica — 4
- La cabecera dice "VERSIÓN 2.0" (L6) y la propiedad `sgspi_version`, 2.1 (L243).
- Los acrónimos de auditoría empiezan por `a`, igual que muchos de negocio, y se confunden: `adi`/`aid`, `aac`/`aca`, `adm`/`aam`. El truncado cayó justo en `TR_adm_auditoria` y `TR_aid_inmutabilidad`.
- Conviven `_esta_activo` y `_esta_activa`. La cabecera (L80) y AP-22 prometen 50010 donde el motor responde 547.

### 13. Concurrencia y bloqueos — 4
- Las lecturas cruzadas de datos mutables en los triggers usan `UPDLOCK` (30 lecturas) o son `UPDATE`. Las demás son sobre catálogos que no cambian en línea (`efc`, `tef`). Eso es correcto tanto con READ COMMITTED con bloqueo como con RCSI.
- Sin hallazgos nuevos. El reintento ante 1205/2601/2627 sigue a cargo de la app, que aún no lo implementa.

### 14. Compatibilidad de despliegue — 2
- **HEAD no despliega.** Con `-b` se detiene y revierte. Sin `-b` (SSMS sin modo SQLCMD, el uso habitual) confirma un esquema incompleto, y la verificación posterior no lo detecta. La promesa "todo o nada" de AP-19 solo se cumple con `-b`, como admite el `shortcut` de L173.
- La comprobación (g) da un falso positivo permanente (dimensión 7), y `auditoria_servidor.sql` lleva la base escrita a mano.

## 4. Plan de corrección (dimensiones 14, 10 y 3)

Va ordenado por riesgo. Esfuerzo: **S** menos de 1 h · **M** medio día · **L** 1–2 días. Por D6 no hay datos desplegados, así que todo se edita en el script de creación. Cada paso deja su prueba en `PRUEBAS_DDL_SGSPI_v2.sql` y se cierra desplegando y probando con F0.4.

### Fase 0 — Desbloquear el despliegue (dimensión 14), S

**Estado:** aplicada el 2026-11-19 en el DDL, las pruebas, la especificación (RN-INT-04, RN-INT-13, 12.1, 12.3 y 12.4) y `sql/sgspi/base_desechable.sql`. Se ejecutó contra el motor:
- el ciclo F0.4 da **188 de 188** en unos 6 s;
- una copia con `TR_aid_inmutabilidad` truncado como en `d0df220`, desplegada sin `-b`, termina con `DESPLIEGUE SGSPI REVERTIDO SIN CAMBIOS` y 0 tablas en `sgspi`.

La guarda quedó con el formato del script y un `shortcut:` sobre los cuatro números. Los pasos describen lo que quedó.

1. **F0.1 Restaurar los dos triggers.**
   - Insertar el bloque del anexo B antes de L8943, el `    SET NOEXEC ON; -- [AP-19]` que hoy sigue al `END` de la rama `'I'` de `TR_adm_auditoria`.
   - Son las 43 líneas que quitó `17d5b8b` más las 9 de `TR_aid_inmutabilidad` tomadas de `4eb8a48`, ya con `ufn_persona_sesion()`.
   - Verificado: despliega y quedan 112 triggers.
2. **F0.2 Guarda antes del `COMMIT`.** Un lote que no compila no revierte la transacción; esta guarda sí lo hace. Va justo antes de `COMMIT TRANSACTION` (L11395):
   ```sql
   -- [AP-19] Un lote que no compila (error de nivel 15) no revierte la transacción: antes del COMMIT se exige el esquema completo.
   IF (SELECT COUNT(*) FROM sys.tables WHERE schema_id = SCHEMA_ID(N'sgspi')) <> 100
      OR (SELECT COUNT(*) FROM sys.triggers AS tr INNER JOIN sys.tables AS t ON t.object_id = tr.parent_id WHERE t.schema_id = SCHEMA_ID(N'sgspi')) <> 112
      OR (SELECT COUNT(*) FROM sys.views WHERE schema_id = SCHEMA_ID(N'sgspi')) <> 7
      OR (SELECT COUNT(*) FROM sys.objects WHERE schema_id = SCHEMA_ID(N'sgspi') AND type = N'IF') <> 3
       BEGIN
           ROLLBACK TRANSACTION;
           RAISERROR (N'DESPLIEGUE SGSPI REVERTIDO SIN CAMBIOS: faltan objetos del esquema (un lote no compiló; ver mensajes anteriores).', 16, 1);
           SET NOEXEC ON;
       END


   GO
   ```
   - Verificado: HEAD + guarda sin `-b` → `Msg 50000 … REVERTIDO` y 0 tablas en `sgspi`. Con F0.1 → 100 tablas.
   - Al agregar objetos hay que actualizar los cuatro números; si se olvida, la guarda falla y lo recuerda.
   - Reescribir el `shortcut` de L173: con la guarda, el script es todo o nada también sin `-b`.
3. **F0.3 Pruebas y textos del borrado físico.**
   - En PRUEBAS L180, L315 y L728, esperar 547.
   - En la cabecera (L80), AP-22 y RN-INT-17, decir que el borrado físico lo rechaza la FK de su `aud_*` (547), también a `db_owner`, y que el trigger (50010/50016) queda como segunda barrera si alguien quitara esa FK.
   - Resultado esperado: 188 de 188.
4. **F0.4 Base desechable en el repo.** Agregar `sql/sgspi/base_desechable.sql` (anexo A) y documentar en la especificación (12.3) los tres comandos:
   ```bash
   sqlcmd -S localhost -E -C -b -I -i sql/sgspi/base_desechable.sql
   ```
   ```bash
   sqlcmd -S localhost -E -C -b -I -d sgspi_desechable -i DDL_SGSPI_SQLSERVER2019_v2.sql
   ```
   ```bash
   sqlcmd -S localhost -E -C -I -W -d sgspi_desechable -i PRUEBAS_DDL_SGSPI_v2.sql
   ```
   El ciclo completo tarda unos 10 s en este equipo. Regla: ningún commit del DDL sin pasarlo.

### Fase 1 — Trazabilidad (dimensión 10)

**Estado:** aplicada el 2026-11-19.
- **T1:** está en PRUEBAS; el ciclo F0.4 da **189 de 189**.
- **T2 y D10:** van en `sql/sgspi/auditoria_servidor.sql`, que ahora toma las variables `BD_SGSPI` y `RUTA_AUDITORIA`. Se actualizaron la cabecera AP-01 del DDL y la especificación (RN-INT-17 y 12.1).
- **T3:** el script del repo se ejecutó contra la base desechable en la instancia local, con los archivos en la carpeta `DATA` de la instancia. La auditoría quedó `STARTED` con `FAIL OPERATION`. Después se borraron la auditoría, sus especificaciones, los archivos y la base.

Resultado de T3 en `sys.fn_get_audit_file`:

| Acción probada | Evento |
|---|---|
| `DISABLE TRIGGER` / `ENABLE TRIGGER` | `AL` (las dos) |
| `CREATE USER … WITHOUT LOGIN` | `CR` |
| `ALTER ROLE sgspi_rol_lider_propietario ADD MEMBER` | `APRL` |
| `GRANT SELECT` sobre un objeto | `G` |
| Alta en `dbo.grupo` y `dbo.usuario_grupo` | `IN` (las dos) |
| `SELECT` de `eia` y de `aud_evento_incertidumbre_activo` | `SL` (las dos) |
| `SELECT` de `vw_matriz_tratamiento_riesgos` | `SL` sobre `eia`: la lectura por vista también queda |
| `UPDATE` en `sgspi.parte_interesada` | `UP`, más el `IN` que hace su trigger en `aud_parte_interesada` (unos 2 eventos por escritura) |
| `TRUNCATE TABLE sgspi.aud_idioma_catalogo` como `db_owner` | `AL` + `DL`. **Vació la tabla (2 → 0 filas) sin pasar por el trigger de inmutabilidad**; queda el hecho, no el contenido |
| `ALTER SERVER AUDIT SPECIFICATION … STATE = OFF` | `AL`. El `ON` siguiente no deja evento (el grupo estaba apagado), pero el hueco se ve |
| Creación de la propia especificación de BD | `CR` |

Sin probar:
- `SERVER_ROLE_MEMBER_CHANGE_GROUP`, porque requiere crear un login de prueba;
- el comportamiento de `FAIL_OPERATION` con el destino caído;
- la ejecución en producción, que corresponde al DBA.

El riesgo residual del `TRUNCATE` quedó escrito en RN-INT-17.

5. **T1 Prueba estructural [S].** En PRUEBAS, después de L90:
   ```sql
   EXECUTE #espera N'AP-01 cada tabla tiene su trigger de auditoría y cada aud_* su trigger de inmutabilidad', N'
   IF EXISTS (SELECT 1 FROM sys.tables AS t
              WHERE  t.schema_id = SCHEMA_ID(N''sgspi'')
                     AND ((t.name LIKE N''aud[_]%''
                           AND NOT EXISTS (SELECT 1 FROM sys.triggers AS tr WHERE tr.parent_id = t.object_id AND tr.is_instead_of_trigger = 1))
                          OR (t.name NOT LIKE N''aud[_]%''
                              AND NOT EXISTS (SELECT 1 FROM sys.triggers AS tr
                                              INNER JOIN sys.sql_expression_dependencies AS d ON d.referencing_id = tr.object_id
                                              WHERE tr.parent_id = t.object_id AND d.referenced_id = OBJECT_ID(N''sgspi.aud_'' + t.name)))))
       THROW 51000, N''hay tablas sin trigger de auditoría o aud_* sin trigger de inmutabilidad'', 1;', 0;
   ```
   Verificado: con el esquema completo no lista nada; sin los dos triggers de HEAD lista `activo_documental_medio_conservacion` y `aud_activo_documental_idioma`.
6. **T2 Auditar el origen del alcance y lo que falta [S].** En `sql/sgspi/auditoria_servidor.sql`, agregar a la especificación de base de datos:
   ```sql
       ADD (INSERT, UPDATE, DELETE ON OBJECT::dbo.usuario_grupo BY public),   -- quién da grupo SGSPI_* y UAA (alcance, 50021)
       ADD (INSERT, UPDATE, DELETE ON OBJECT::dbo.grupo BY public),
       ADD (DATABASE_PRINCIPAL_CHANGE_GROUP),                                 -- CREATE/DROP USER y ROLE
       ADD (SELECT ON OBJECT::sgspi.evento_incertidumbre_activo BY public),   -- lectura del mapa de vulnerabilidades
       ADD (SELECT ON OBJECT::sgspi.aud_evento_incertidumbre_activo BY public)
   ```
   Agregar también una especificación de servidor:
   ```sql
   CREATE SERVER AUDIT SPECIFICATION sgspi_auditoria_servidor
       FOR SERVER AUDIT sgspi_auditoria
       ADD (SERVER_ROLE_MEMBER_CHANGE_GROUP),  -- altas en sysadmin
       ADD (AUDIT_CHANGE_GROUP)                -- cambios o apagado de la propia auditoría
       WITH (STATE = ON);
   ```
   Cambiar `USE academia3000;` por `USE $(BD_SGSPI);` (variable de `sqlcmd`) y aplicar D10.
7. **T3 Probar la auditoría del servidor [M, DBA].**
   - Primero en la instancia local (la edición Developer sirve) y luego en producción.
   - Deben aparecer en `sys.fn_get_audit_file`: `DISABLE TRIGGER`, `ALTER ROLE … ADD MEMBER`, un alta en `dbo.usuario_grupo`, un `SELECT` de `eia` y un `TRUNCATE TABLE` de una `aud_*` hecho como `db_owner`.
   - Si `TRUNCATE` no deja evento, documentarlo como riesgo residual de `db_owner`.

### Fase 2 — Antipatrones (dimensión 3)

**Estado:** A1 y A2 aplicados el 2026-11-19; el ciclo F0.4 da **190 de 190**.
- **A1** quedó cerrado con F0.4 y T1.
- **A2**:
  - `eia_numero_evento SMALLINT` con `CK_eia_numero_evento` (1..999), `CK_eia_naturaleza_evento` y `UQ_eia_vigencia_naturaleza_numero`;
  - `eia_identificador_evento` pasa a calculada `PERSISTED`;
  - `aud_evento_incertidumbre_activo` guarda `aea_numero_evento`;
  - en `TR_eia` se cambiaron las listas del `EXCEPT` y de la auditoría;
  - se retiraron `CK_eia_naturaleza_prefijo` y el `SUBSTRING` de AP-24;
  - se actualizaron la cabecera (AP-09, AP-24), la especificación (RN-RSG-01, 5.1, diccionario y 12.2) y las 8 inserciones de PRUEBAS.
- Las pruebas `RA-ABC` y `RA-001` ya no se pueden expresar. Las reemplazan tres:
  - número 0 → 547;
  - 100 → `RA-100`;
  - número repetido en la vigencia → 2627.
- **A3 no se aplicó**: es opcional y D12 recomienda no hacerlo por ahora.

8. **A1 Ciclo obligatorio [S, queda hecho con F0.4 y T1].** La causa del defecto no es la copia sino editarla sin ejecutar. Con F0.4 y T1, un reemplazo masivo que rompa una de las 112 copias falla en unos 10 s. Con esto la dimensión vuelve a 4 sin reescribir nada.
9. **A2 Consecutivo de eventos como número [M, D11].** Sería el mismo patrón de `acf`:
   - `eia_numero_evento SMALLINT NOT NULL CHECK (BETWEEN 1 AND 999)`;
   - `eia_identificador_evento` pasa a calculada PERSISTED (`RA-`/`OA-` + 2 o 3 dígitos);
   - `UQ (pev_codigo, eia_naturaleza_evento, eia_numero_evento)`.

   Desaparecen el `SUBSTRING` de AP-24 y las 10 líneas de `CK_eia_naturaleza_prefijo`. Toca `eia`, `aud_evento_incertidumbre_activo`, las listas de `TR_eia` y los INSERT de PRUEBAS.
10. **A3 Generar la capa de auditoría desde metadatos [L, D12, opcional].**
    - Un script emite las 50 `aud_*`, los 41 `TR_<acr>_auditoria` y los 50 `TR_<aud>_inmutabilidad` desde `sys.columns` y el mapa de acrónimos de la cabecera.
    - El DDL incluye la salida, y una prueba compara.
    - Quita unas 4 300 líneas mantenidas a mano.

### Decisiones

| # | Pregunta | Recomendación |
|---|---|---|
| D10 | ¿Qué hace la auditoría del servidor si no puede escribir, y qué se hace con los archivos que rota? | `ON_FAILURE = FAIL_OPERATION`, coherente con 50017 ("no hay cambio sin rastro"): solo fallan las acciones auditadas. Los archivos rotados se copian a un almacenamiento fuera del alcance del DBA antes de que `MAX_ROLLOVER_FILES` los borre. **Aplicada la recomendada con la fase 1**; volver a `CONTINUE` es una línea del script. |
| D11 | ¿Convertir `RA-nn`/`OA-nn` en número + identificador calculado (A2)? | Sí, si se toca `TR_eia` por otra razón. Si no, dejarlo: funciona y está probado. **Aplicada (sí) con la fase 2.** |
| D12 | ¿Generar la auditoría desde metadatos (A3)? | No por ahora: A1 cubre el riesgo con esfuerzo S. Sí, si el esquema seguirá creciendo. |
| D13 | ¿Un activo puede tener datos personales de varias categorías? | Si sí, una tabla puente activo–categoría. Si no, documentar que se registra la más restrictiva. |

## 5. Mejoras menores (dimensiones con 4), cada una S

**Estado:** aplicadas el 2026-11-19 en el DDL, las pruebas y la especificación. El ciclo F0.4 da **199 de 199**: nueve pruebas nuevas, y cada rechazo sale de la restricción esperada. Diferencias con lo escrito abajo:
- **DOFA:** la columna calculada de `acf` se llama `fec_ambito_entorno`, porque una columna de FK conserva el acrónimo de la tabla referenciada, como `efc_dominio`.
- **Sedes:** quedó declarativa en lugar de dos `THROW 50020`. `ais` tiene la columna calculada `aci_es_transversal_sedes` (0 si la sede está activa, NULL si no) y la FK compuesta `FK_ais_activo_no_transversal` hacia `UQ_aci_codigo_transversal`. Responde 547 en los dos sentidos y no valida las sedes desactivadas.
- **Frecuencia del SoA:** ahora sale del catálogo de periodicidad, que administra el gestor documental. Textos como "Anual y cuando se presenten cambios" se registran como `Anual`, con el matiz en la justificación. Si el oficial necesita otra frecuencia, la agrega el gestor.
- **Sensibilidad:** se clasificaron las seis columnas del mapa de vulnerabilidades. Las columnas de `aci` sobre datos personales no se clasificaron: describen el tratamiento y no son datos personales. TDE sigue a cargo del DBA.

- **DOFA (dimensión 2), probada en el motor.** En `fec`, `CONSTRAINT UQ_fec_codigo_ambito UNIQUE (fec_codigo, fec_ambito_entorno)`. En `acf`, una columna calculada y una FK compuesta que reemplaza a `FK_acf_factor_entorno`:
  ```sql
  acf_ambito_entorno AS (CONVERT (NVARCHAR (15), CASE WHEN acf_naturaleza_factor IN (N'DEBILIDAD', N'FORTALEZA') THEN N'INTERNO' ELSE N'EXTERNO' END)) PERSISTED,
  CONSTRAINT FK_acf_factor_entorno_ambito FOREIGN KEY (fec_codigo, acf_ambito_entorno) REFERENCES sgspi.factor_entorno_catalogo (fec_codigo, fec_ambito_entorno),
  ```
  AMENAZA sobre un factor INTERNO → 547, mientras las coherentes entran y se auditan. Las pruebas actuales no se rompen, porque todas usan DEBILIDAD con el factor INTERNO. Agregar la prueba que espera 547.
- **Fundamentos de la reserva (dimensión 2).** En la rama CLASIFICADA/RESERVADA de `CK_aci_coherencia_indice_reserva` (L738), agregar `AND LEN(TRIM(ISNULL(aci_fundamento_constitucional_legal, N''))) > 0 AND LEN(TRIM(ISNULL(aci_fundamento_juridico_excepcion, N''))) > 0`, y quitar esa validación de la app en RN-DOC-03.
- **Sedes (dimensión 1).** Si `aci_es_transversal_sedes = 1`, no debe haber filas activas en `ais`. Va como un `IF EXISTS … THROW 50020` en `TR_aci` y en el trigger puente de `ais`.
- **Responsable del SoA (dimensión 4).** Agregar `AND car_codigo IS NOT NULL` a la rama aplicable de `CK_eac_coherencia_aplicabilidad` (L1570). La prueba "SoA aplicable" (PRUEBAS L339) debe pasar a enviar `car_codigo = 1`.
- **Enumeraciones (dimensiones 1 y 5).** Un CHECK con `PORCENTAJE`, `CANTIDAD`, `DIAS` y `HORAS` para `plt_unidad_medida_kpi`, y `eac_frecuencia_revision` reemplazada por `pdc_codigo` con FK a `periodicidad_catalogo`.
- **Ruta caliente (dimensión 7).**
  - En la comprobación (g) (L11492), listar las 7 tablas base de la vista (`usuario_estudiantes`, `usuario_estudiantes_virtual`, `usuario_docentes`, `usuario_administrativos`, `usuario_graduados`, `usuario_estudiantes_intercambio`, `usuario_externos`) en lugar de `usuario_general`.
  - Si `us` es `VARCHAR`, comparar con `CONVERT (VARCHAR (128), ORIGINAL_LOGIN())` en `ufn_persona_sesion` (L2970).
- **Versión (dimensión 12).** Poner "VERSIÓN 2.1" en la cabecera (L6).
- **Sensibilidad (dimensión 11).**
  - `ADD SENSITIVITY CLASSIFICATION` en `eia_condicion_vulnerabilidad`, `eia_controles_existentes`, `eia_fuente_generadora`, sus copias en `aud_evento_incertidumbre_activo` y las columnas PII de `aci`.
  - El DBA confirma TDE (DS2 de la ronda 2).

## 6. Efecto esperado

| Dimensión | Al revisar | Tras la fase 0 | Tras la fase 1 | Tras el plan |
|---|:-:|:-:|:-:|:-:|
| 14 Compatibilidad de despliegue | 2 | 4 (quedan la comprobación (g) y la base escrita a mano en `auditoria_servidor.sql`) | 4 (la base ya es variable; queda (g)) | 5 |
| 10 Trazabilidad | 3 | 3 (inmutabilidad y auditoría de `adm` ya restauradas; faltan T1–T3) | 4 (5 con T3 en producción) | 5 |
| 3 Antipatrones | 3 | 3 (el ciclo F0.4 ya existe; falta T1 para cerrar A1) | 4 (A1 cerrado; con la fase 2 se va también la clave "inteligente" de `eia`) | 4 (5 con A3) |

Estado tras las mejoras menores, para las dimensiones que estaban en 4 (la 14 sube porque la comprobación (g) ya no da el falso positivo):

| Dimensión | Antes | Ahora | Lo que falta |
|---|:-:|:-:|---|
| 1 Normalización | 4 | 4 | `rpc_numero_pregunta` sin entidad de cuestionario |
| 2 Claves y restricciones | 4 | 4 | cinco reglas siguen en la app (RN-DOC-04, RN-DOC-05, RN-ACT-04, RN-PI-01, RN-RSG-02) porque necesitan datos que el modelo no tiene |
| 4 Cardinalidad | 4 | 4 | D13 (categorías de datos personales) y la vigencia de `ado` |
| 5 Tipos de datos | 4 | 4 | `pev_anio` sin rango |
| 7 Indexación | 4 | 5 | — |
| 11 Datos sensibles | 4 | 4 | TDE confirmado por el DBA (→ 5) |
| 12 Convenciones | 4 | 4 | acrónimos de auditoría que se confunden (`adi`/`aid`) y `_esta_activo`/`_esta_activa` |
| 14 Compatibilidad de despliegue | 4 | 5 | — |

Fuera del DDL siguen los puntos de la ronda 2: `TrustServerCertificate=true` y la clave SQL real en `$_SESSION`. Además, `clases/Inicio_sesion.php` (L50) arma `where us = '{$txtUsuario}'` por concatenación con la cuenta de login, lo que permite inyección SQL.

## Anexo A — `sql/sgspi/base_desechable.sql`

Stubs mínimos de `dbo` con los tipos de `sql/dbo/*.sql`. `usuario_general` es tabla porque `#sesion_como` la actualiza; en producción es una vista. El login que ejecuta queda como persona 2.

```sql
USE master;
IF DB_ID(N'sgspi_desechable') IS NOT NULL
BEGIN
    ALTER DATABASE sgspi_desechable SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE sgspi_desechable;
END
CREATE DATABASE sgspi_desechable COLLATE Modern_Spanish_CI_AS;
ALTER DATABASE sgspi_desechable SET COMPATIBILITY_LEVEL = 150;
GO
USE sgspi_desechable;
GO
CREATE TABLE dbo.sede (sed_codigo INT IDENTITY(1,1) NOT NULL PRIMARY KEY, sed_nombre VARCHAR(50) NOT NULL);
CREATE TABLE dbo.uaa (uaa_codigo INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_uaa PRIMARY KEY NONCLUSTERED, uat_codigo INT NOT NULL DEFAULT 1, uaa_nombre VARCHAR(200) NOT NULL, uaa_estado INT NULL DEFAULT 1);
CREATE TABLE dbo.cargo (car_codigo INT IDENTITY(0,1) NOT FOR REPLICATION NOT NULL CONSTRAINT PK_cargo PRIMARY KEY CLUSTERED, car_nombre VARCHAR(50) NOT NULL);
CREATE TABLE dbo.persona (per_codigo INT IDENTITY(1,1) NOT FOR REPLICATION NOT NULL CONSTRAINT PK_persona PRIMARY KEY NONCLUSTERED, per_identificacion VARCHAR(15) NOT NULL, tii_codigo INT NOT NULL DEFAULT 1, per_apellido VARCHAR(40) NULL, per_nombre VARCHAR(40) NULL, per_email_interno VARCHAR(100) NULL);
CREATE TABLE dbo.espacio (esp_codigo INT IDENTITY(1,1) NOT FOR REPLICATION NOT NULL CONSTRAINT PK_espacios PRIMARY KEY NONCLUSTERED, esp_nombre VARCHAR(55) NOT NULL);
CREATE TABLE dbo.sub_sede (sus_codigo INT IDENTITY(1,1) NOT FOR REPLICATION NOT NULL CONSTRAINT PK_sub_sede_1 PRIMARY KEY NONCLUSTERED, sus_nombre VARCHAR(50) NOT NULL, sed_codigo INT NOT NULL);
CREATE TABLE dbo.grupo (gru_codigo INT IDENTITY(1,1) NOT FOR REPLICATION NOT NULL CONSTRAINT PK_grupo PRIMARY KEY NONCLUSTERED, gru_nombre VARCHAR(100) NOT NULL, gru_estado INT NULL CONSTRAINT DF_grupo_gru_estado DEFAULT 1);
CREATE TABLE dbo.usuario_grupo (usg_codigo INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_usuario_grupo PRIMARY KEY CLUSTERED, usg_usuario INT NULL, usg_grupo INT NULL, usg_uaa INT NULL, usg_estado TINYINT NULL CONSTRAINT DF_usuario_grupo_usg_estado_1 DEFAULT 1);
CREATE TABLE dbo.usuario_general (uid INT IDENTITY(1,1) NOT NULL PRIMARY KEY, up INT NULL, us VARCHAR(100) NOT NULL);
CREATE INDEX IX_usuario_general_us ON dbo.usuario_general (us);
CREATE INDEX IX_usuario_grupo_usg_usuario ON dbo.usuario_grupo (usg_usuario);
GO
INSERT dbo.sede (sed_nombre) VALUES ('Neiva');
INSERT dbo.uaa (uaa_nombre) VALUES ('Oficina de Seguridad de la Información'), ('Facultad de Ingeniería');
INSERT dbo.cargo (car_nombre) VALUES ('Cargo 0'), ('Profesional universitario');
INSERT dbo.persona (per_identificacion, per_nombre, per_apellido) VALUES ('1001', 'Persona', 'Uno'), ('1002', 'Persona', 'Dos'), ('1003', 'Persona', 'Tres');
INSERT dbo.espacio (esp_nombre) VALUES ('Centro de datos');
INSERT dbo.sub_sede (sus_nombre, sed_codigo) VALUES ('Sede central', 1);
INSERT dbo.usuario_general (up, us) VALUES (2, CONVERT(VARCHAR(100), ORIGINAL_LOGIN()));
GO
```

## Anexo B — Bloque de F0.1

Va antes de L8943. Esa línea, `    SET NOEXEC ON; -- [AP-19]`, queda como cierre del bloque.

```sql
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
```
