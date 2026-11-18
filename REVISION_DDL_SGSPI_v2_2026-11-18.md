# Revisión de diseño, segunda ronda — `DDL_SGSPI_SQLSERVER2019_v2.sql`

Base: commit `b1ea63b` más el formateo sin confirmar de la copia de trabajo (solo espacios y saltos de línea; las líneas `L####` citadas son de esa copia). Revisión por lectura del DDL, de `PRUEBAS_DDL_SGSPI_v2.sql`, de `ESPECIFICACION_ARQUITECTURA_SGSPI.md` (`.md L###`) y de `conexion/cls_config.php`. No se ejecutó contra SQL Server (no hay instancia ni `sqlcmd` en este equipo). Parte de la primera ronda (`REVISION_DDL_SGSPI_v2.md`), cuyas fases 1–5 ya están aplicadas.

Escala: **5** sin hallazgos · **4** detalles menores · **3** brechas relevantes · **2** deficiente · **1** ausente.
**Baja = 3 o menos → entra al plan (sección 3).** Los detalles de las dimensiones con 4 van en la sección 4.

## 1. Resumen

| # | Dimensión | Ronda 1 | Hoy | Hallazgo principal |
|---|---|:-:|:-:|---|
| 1 | Normalización y dependencias | 4 | 4 | 3FN con derivados calculados; el avance de la actividad no se recalcula al anular un seguimiento. |
| 2 | Claves y restricciones | 3 | **3** | Cinco reglas de flujo quedan en la app y se saltan con el login propio; `RA-01` y `RA-001` conviven; la vigencia cerrada no bloquea altas. (Fase 2 aplicada.) |
| 3 | Antipatrones estructurales | 3 | 4 | Lógica copiada a gran escala (112 triggers, 53 copias de la resolución de identidad), mitigada por pruebas. |
| 4 | Cardinalidad y opcionalidad | 3 | 4 | Un plan sin actividades llega a evaluación de eficacia; el custodio es 0..N. |
| 5 | Tipos de datos y precisión | 4 | 4 | `plt_porcentaje_cumplimiento_kpi` todavía desborda y tumba la vista que lo lee. |
| 6 | Almacenamiento y clustering | 5 | 5 | Sin cambios; `aud_plan_tratamiento` queda cerca del límite de 8 060 B. |
| 7 | Estrategia de indexación | 4 | 4 | 100 de 160 índices son de auditoría; la ruta caliente en `dbo` no se verifica. |
| 8 | Volumetría y particionamiento | 4 | 4 | Particionar no hace falta; no hay estimación escrita ni retención de `aud_*`. |
| 9 | Aislamiento y privilegios mínimos | 3 | **3** | El líder y el oficial pueden borrar el dictamen del auditor; el comité y el auditor mueven borradores ajenos; el alcance permite por omisión; el gestor no puede hacer su aval de Archivo. (Fase 1 aplicada.) |
| 10 | Trazabilidad y auditoría | 1 | **3** | Las altas no se auditan: en 45 de 50 tablas no se sabe quién creó la fila; los cambios del DBA y de roles no dejan rastro. (Fase 3 aplicada.) |
| 11 | Protección de datos sensibles | 2 | **3** | La cuenta compartida lee planes, auditoría y los logins reales de todo el personal; no hay cifrado en reposo. (Fase 4 aplicada.) |
| 12 | Convenciones y claridad semántica | 3 | 4 | La especificación cita CHECK que ya no existen (RN-INT-06) y sigue hablando de "Row-Level Security". |
| 13 | Concurrencia y bloqueos | 2 | 4 | El consecutivo `RA-nn` se calcula sobre texto y se atasca en `RA-100`. |
| 14 | Compatibilidad de despliegue | 3 | 4 | La verificación posterior compara el nombre de usuario de BD, pero los triggers comparan el login. |

## 2. Evaluación por dimensión

### 1. Normalización y dependencias — 4
- Bien: derivados como columnas PERSISTED, FK compuestas que fuerzan la coherencia entre tablas, catálogo `zrc`, avance derivado de `sga`.
- `TR_sga_sincronizar_avance` copia el avance al insertar un seguimiento, pero `TR_sga_inmutabilidad` (L4694) no lo recalcula al desactivarlo: la actividad se queda con el porcentaje de un seguimiento anulado.
- `eia_identificador_evento` (L1204) guarda el consecutivo dentro del texto. El efecto se ve en las dimensiones 2 y 13.
- Siguen abiertos desde la ronda 1: `aci_es_transversal_sedes` (L647) contra `ais`, y `rpc_numero_pregunta` sin entidad.

### 2. Claves y restricciones — 3
- Bien: todas las restricciones tienen nombre, hay FK compuestas e índices únicos filtrados, el creador va sellado (50019), las transiciones exigen datos (50020) y el plazo legal de la reserva tiene CHECK.
- **Reglas en la app que se saltan con el login propio.** El diseño parte de que cada persona escribe con su login SQL real (AP-03, `cls_config.php` "usuario real"). Por eso una regla que solo valida la app no protege nada ante quien conecte con esas credenciales desde SSMS u ODBC. La especificación deja 10 reglas en la app (`.md L423-448`). Cinco protegen evidencia de cumplimiento y caben en un `IF EXISTS` dentro de un trigger que ya existe:
  - RN-DOC-06: un activo documental llega a `VIGENTE` por `EN_VALIDACION_LIDER → EN_REVISION_SGSPI` (L335) sin aval de Archivo (`per_codigo_revisor_archivo` NULL).
  - RN-ACT-05: el custodio obligatorio no se exige.
  - Paso 11 del flujo EIA (`.md L611`): `EN_EJECUCION → EN_EVALUACION_EFICACIA` no exige el 100 % de actividades. Hoy pasa un plan con cero actividades.
  - RN-RSG-04: la meta residual puede quedar por encima de la valoración inherente.
  - RN-RSG-05: un activo con datos personales se aprueba sin ningún control ISO 27701.
- **`RA-01` y `RA-001` conviven.** `CK_eia_naturaleza_prefijo` (L1248) admite 2 o 3 dígitos y `UQ_eia_vigencia_identificador` (L1232) compara cadenas, así que el mismo número entra dos veces en una vigencia.
- **El aprobador obligatorio (RN-INT-06) ya no es declarativo.** `CK_*_aprobador_requerido` se retiraron en `e34db73` porque la firma la escribe el trigger después de la sentencia. La especificación (`.md L461`) los sigue citando. Además, la firma quedó dentro de `IF NOT UPDATE (<acr>_fecha_actualizacion)` (L3102, L3305, L3654, L4129): si la sentencia trae la fecha (solo `dbo` puede), la transición queda sin firma y nada lo detecta.
- **Vigencia cerrada.** Ningún trigger usa `pev_estado_vigencia` (L249): se pueden crear registros en una vigencia `CERRADA` o `HISTORICA`. La especificación no define la regla (decisión D7).

### 3. Antipatrones estructurales — 4
- Bien: no hay EAV, los multivaluados están normalizados, el supertipo/subtipo usa PK compartida y la máquina de estados vive en datos.
- Lógica copiada a gran escala: 112 triggers, la resolución `TOP (1) … u.us = ORIGINAL_LOGIN()` aparece 53 veces y las listas de columnas de auditoría se escriben tres veces por tabla. Las pruebas de columnas (PRUEBAS L60-95) cubren el riesgo de olvidar una columna, pero no el de cambiar la regla login ↔ persona en las 53 copias.
- El alcance permite por omisión: `ufn_proceso_en_alcance` (L2842) deja pasar a cualquiera que no sea líder ni custodio (dimensión 9).
- Baja lógica con UNIQUE sin filtro: `UQ_plt_evento` (L1337) obliga a reactivar un plan anulado por error en lugar de crear el correcto.

### 4. Cardinalidad y opcionalidad — 4
- Bien: propietario único y obligatorio (D3), plan obligatorio para aprobar, responsable obligatorio fuera de `PENDIENTE`, subtipo 1:0..1.
- Un plan aprobado puede tener cero actividades y aun así llegar a evaluación. El custodio es 0..N (ambos se corrigen en el paso C3).
- `eia` admite un solo activo de soporte (L1208). Es el diseño del formato MR-06 y se acepta.
- `eac.car_codigo` es opcional aunque el control sea aplicable.

### 5. Tipos de datos y precisión — 4
- Bien: `DATETIMEOFFSET(0)`, `DECIMAL(18,2)` para COP, TINYINT en las escalas, ningún `MAX`.
- `plt_porcentaje_cumplimiento_kpi` (L1326) se convierte a `DECIMAL(9,2)`. Con meta 1 y alcanzado ≥ 100 000 el resultado es 10 000 000,00, que no cabe (error 8115). La columna no es PERSISTED, así que el error salta al leerla y deja caer toda `vw_matriz_tratamiento_riesgos`. AP-16 afirma que ya no desborda.
- `sga_hash_sha256_evidencia CHAR(64)` sigue aceptando mayúsculas y minúsculas (L1434), pendiente desde la ronda 1. `plt_unidad_medida_kpi` es una enumeración en texto libre.

### 6. Almacenamiento y clustering — 5
- Las PK clustered son IDENTITY estrechas, las tablas puente se agrupan por (padre, hijo) y las `aud_*` por IDENTITY. La fila máxima de `aud_plan_tratamiento` ronda los 7 970 B, bajo el límite de 8 060 B. No hace falta ninguna acción, pero cualquier columna de texto nueva en `plt` la pasa a row-overflow.

### 7. Estrategia de indexación — 4
- Bien: todas las FK tienen índice y no quedan redundantes.
- Hay 160 índices no clustered; 100 están en `aud_*`, dos por tabla, y los de `per_codigo` solo sirven a la FK con `dbo.persona`. Se aceptan.
- La ruta caliente está fuera del esquema: cada escritura busca la persona en `dbo.usuario_general` por `us` y el alcance en `usuario_grupo`/`grupo`. La verificación previa comprueba que existan las columnas, pero no los índices ni que `us` sea único.

### 8. Volumetría y particionamiento — 4
- Estimación: unos 200 activos, 240 filas TRD, decenas de riesgos y unos 3 000 seguimientos por año. Las `aud_*` quedarían por debajo de 50 000 filas al año, así que particionar no hace falta.
- No hay estimación escrita ni política de retención para `aud_*`, que son inmutables y no se pueden purgar.

### 9. Aislamiento y privilegios mínimos — 3
- Bien: un rol por actor, DENY de ALTER/DELETE, DENY por columna en firmas y fechas, transiciones por rol, alcance de escritura en los triggers (50021) y vista limitada a `SGSPI_*`.
- **El dictamen del auditor se puede borrar.** El líder y el oficial tienen UPDATE de tabla en `plan_tratamiento` (L8853), y `TR_plt` solo revisa los dictámenes con evaluador no nulo (L4223). Poner los cuatro campos en NULL pasa `CK_plt_coherencia_eficacia`. Contradice D2.
- **Transiciones sin rol.** El comité y el auditor necesitan `UPDATE (eia_estado_registro)` (L8850, L8907) para sus transiciones. Con ese mismo permiso mueven borradores ajenos por las tres transiciones EIA con `tef_rol_requerido` NULL (L336). En la ronda 1 se corrigió esto en `rpi` quitando un GRANT, pero la causa sigue: solo cabe un rol por transición (`UQ_tef_dominio_origen_destino`, L281).
- **Permitido por omisión.** `ufn_proceso_en_alcance` (L2842) trata como transversal a cualquiera que no sea líder ni custodio, incluido un usuario sin rol SGSPI que escriba por otra vía, como `db_datawriter`. El gestor documental tiene INSERT/UPDATE en `actividad_tratamiento` y `seguimiento_actividad` (L8856-8865), como pide la especificación (matriz 5.3 y tabla 11.1), pero con alcance `[Asignado]`, y la función lo deja escribir en todos los procesos. *Corregido al aplicar la fase 1: la primera versión de esta revisión decía que ese GRANT no tenía respaldo en la especificación.*
- **El gestor no podía hacer su propio aval** (hallado al aplicar la fase 1). `tef` le asigna `EN_REVISION_ARCHIVO → EN_REVISION_SGSPI` y `→ OBSERVADO`, pero ningún GRANT le daba UPDATE sobre `activo_informacion` (L8826). Con su login, la transición fallaba con 229 y solo `db_owner` podía hacerla. Las pruebas la ejecutaban como `db_owner` (PRUEBAS L462-467), por eso no se vio.
- **La verificación posterior mira el nombre equivocado** (L9560-9615). Compara `sys.database_principals.name` con `usuario_general.us`, mientras que los triggers comparan `ORIGINAL_LOGIN()`, que es el login. Tampoco revisa `db_owner`/`db_datawriter`, que anulan los GRANT (L8642), ni los `us` duplicados, donde `TOP (1)` elegiría una persona cualquiera.
- Se acepta por D5 que la lectura no tenga alcance por proceso.

### 10. Trazabilidad y auditoría — 3
- Bien: las 50 `aud_*` son inmutables, guardan la versión anterior con quién y cuándo, tienen DENY y tienen pruebas.
- **Las altas no se registran** (L1578). Solo 5 de 50 tablas guardan su creador (`acf`, `rpi`, `aci`, `eia`, `sga`) y 39 no guardan la fecha de alta. Quedan sin respuesta preguntas como estas:
  - quién asignó el propietario de un activo (`air`, ISO/IEC 27001 A.5.9);
  - quién dio a una UAA alcance sobre un proceso (`piu`, que habilita escritura vía `ufn_proceso_en_alcance`, A.5.18);
  - quién creó el plan, sus actividades, la fila del SoA o la asociación de un control.
- **Lo que hace el DBA no deja rastro.** La carga histórica (AP-04, L88-90) deshabilita el trigger que valida y audita. Las altas y bajas en los roles `sgspi_*` y los GRANT/DENY tampoco quedan registrados, porque no hay SQL Server Audit.

### 11. Protección de datos sensibles — 3
- Bien: la cuenta compartida no ve vulnerabilidades, controles existentes ni fuente de amenaza, ni en la tabla ni en su auditoría. La vista de alcance ya no expone identificación ni correo.
- **La cuenta compartida lee todo lo demás.** `sgspi_rol_consulta` es miembro de `sgspi_rol_base` (L8667), que tiene `SELECT ON SCHEMA::sgspi` (L8683). Eso incluye:
  - `plan_tratamiento`: restricciones, recursos y fechas de los controles;
  - el efecto y el escenario de cada evento;
  - las 50 `aud_*` con `<aud>_usuario_bd`, es decir, los logins SQL reales de todo el personal SGSPI.

  Su clave está en el `.ini` del servidor web. Los campos de reserva y de registro de activos de `aci` no son el problema: la Ley 1712 los hace públicos.
- **No hay cifrado en reposo documentado.** El esquema concentra el mapa de vulnerabilidades de la universidad, y SQL Server 2019 Standard ya incluye TDE y backups cifrados.
- Fuera del DDL: la app guarda la clave SQL real en `$_SESSION` (`cls_config.php` L58-59) y conecta con `TrustServerCertificate=true` (L77), que no valida el certificado del servidor.

### 12. Convenciones y claridad semántica — 4
- Bien: el mapa de acrónimos y los prefijos de restricción se aplican con rigor, y la cabecera AP-xx está al día.
- En la especificación:
  - RN-INT-06 describe CHECK que no existen (se corrige en C2);
  - llama "Row-Level Security" (`.md L183`, `L641`) a lo que es alcance de escritura por triggers;
  - el diagrama 12a (`.md L612`) da `EN_EVALUACION_EFICACIA → EN_EJECUCION` a ADMIN_OPDP/AUDITOR, mientras que `tef` se lo da solo al auditor (D2).
- Conviven `_esta_activo` (36 tablas) y `_esta_activa` (14), el paso opcional de la ronda 1.

### 13. Concurrencia y bloqueos — 4
- Bien: ROWVERSION en las 8 tablas con flujo, `UPDLOCK` en los triggers que leen el padre y un patrón único de consecutivos con reintento.
- El consecutivo `RA-nn`/`OA-nn` se calcula sobre la cadena: `MAX('RA-99', 'RA-100')` da `'RA-99'`, así que el siguiente choca siempre con el error 2627. C1 lo resuelve.
- Hay comprobaciones en los dos sentidos padre ↔ hijo (`aci`↔`ado`, `eia`↔`plt`/`act`), lo que permite deadlocks. El reintento ante 1205 está documentado. Las reglas nuevas de C3 deben leer con `UPDLOCK` igual que las demás.

### 14. Compatibilidad de despliegue — 4
- Bien: verificación previa, una sola transacción con guardas NOEXEC, verificación posterior y solo funciones de 2017 o posteriores.
- La verificación compara el nombre de usuario en vez del login (se corrige en P4). No hay marcador de versión del esquema para futuras migraciones.
- Opciones SET: los índices filtrados (`efc`, `air`, `sif`, `enc`) y los índices sobre columnas calculadas (`upc`, `mvr`, `eia`) exigen `QUOTED_IDENTIFIER ON` en cualquier DML. `sqlcmd` sin `-I` y los jobs del Agente fallan con el error 1934. El script lo fija para sí mismo (L142), pero falta documentarlo para cargas y correcciones.

## 3. Plan de corrección (dimensiones 2, 9, 10 y 11)

Va ordenado por riesgo y costo. Cada paso trae el cambio mínimo, su prueba en `PRUEBAS_DDL_SGSPI_v2.sql` (`#espera`) y lo que cambia en la especificación.
Esfuerzo: **S** menos de 1 h · **M** medio día · **L** 1–2 días. Por D6 no hay datos desplegados, así que todo se edita en el script de creación.

### Fase 1 — Segregación y privilegios (dimensión 9)

**Estado:** aplicada el 2026-11-18 en el DDL, las pruebas y la especificación, sin ejecutar contra SQL Server. Los pasos describen lo que quedó.

1. **P1 Proteger el dictamen.**
   - `DENY UPDATE` de las cuatro columnas del dictamen al líder y al oficial, justo después del GRANT de tabla de `plan_tratamiento`, para que el orden no importe.
   - El INSERT de un plan no cambia: `TR_plt` ya exige al auditor si el dictamen viene informado.
   - Pruebas: el oficial escribe el dictamen → 230 (antes 50011); el oficial lo borra → 230.
2. **P2 Varios roles por transición.**
   - `UQ_tef_dominio_origen_destino_rol` incluye `tef_rol_requerido`.
   - Las transiciones de captura con rol NULL pasan a una fila por rol: en EIA, líder y oficial; en ACI, custodio, líder y oficial, porque P3 le da al gestor UPDATE del estado de `aci`. Los triggers no cambian.
   - Pruebas: ninguna transición de ACI o EIA queda sin rol; el comité no envía a validación un evento en borrador → 50011; el gestor no envía a validación un activo en borrador → 50011.
   - En la especificación se alinearon con `tef` las etiquetas de rol del diagrama EIA (pasos 2, 5, 5b, 9, 12a y 12b).
3. **P3 Alcance explícito.**
   - `ufn_proceso_en_alcance`: solo son transversales db_owner, el oficial, el comité y el auditor.
   - `ufn_activo_en_alcance`: también lo es el gestor documental, que en la matriz 4A tiene `[Todo]` sobre lo documental.
   - D9 lo resuelve la especificación: el gestor sí registra actividades y seguimientos, con alcance `[Asignado]` (matriz 5.3, tabla 11.1). Se aplicó la rama "si sí" de la recomendación: conserva los GRANT y en procesos tiene el alcance del custodio.
   - `GRANT UPDATE ON sgspi.activo_informacion (aci_estado_registro) TO sgspi_rol_gestor_documental`, para que pueda hacer su aval de Archivo.
   - Pruebas: un usuario sin rol de actor no tiene alcance transversal; el auditor lo conserva; el gestor es transversal en activos y no en procesos. La transición `EN_REVISION_ARCHIVO → EN_REVISION_SGSPI` la hace ahora el gestor con su usuario y el trigger firma (PRUEBAS L462-467; antes se hacía como `db_owner`).
4. **P4 Verificación posterior.**
   - Compara `SUSER_SNAME(m.sid)`, que es el login, con `usuario_general.us`.
   - Agrega (d) miembros directos de `db_owner`, `db_datawriter`, `db_ddladmin` o `db_securityadmin`, y (e) logins con varias personas en `usuario_general`.
   - Sigue siendo de solo lectura.

Queda una inconsistencia de la especificación que no se tocó: el diagrama ACI dice que el gestor crea activos (paso 1), pero la matriz 4B.1 y la tabla 11.1 solo le dan lectura sobre `activo_informacion`.

### Fase 2 — Reglas en el motor (dimensión 2)

**Estado:** aplicada el 2026-11-18 en el DDL, las pruebas y la especificación, sin ejecutar contra SQL Server (en `TR_eac_integridad_y_actualizacion` se amplió a `AFTER INSERT, UPDATE, DELETE` con `IF EXISTS (SELECT 1 FROM deleted)` para cubrir las altas en C4). Los pasos describen lo que quedó.

5. **C1 Consecutivo de eventos [S]** — añadir a `CK_eia_naturaleza_prefijo` (L1248), fuera del `OR` de las dos naturalezas:
   ```sql
   AND eia_identificador_evento NOT LIKE N'_A-0[0-9][0-9]'   -- 'RA-001' es 'RA-01'
   AND eia_identificador_evento NOT LIKE N'_A-00'
   ```
   - En AP-24(c), documentar que el consecutivo se calcula sobre el número: `ISNULL(MAX(CONVERT(INT, SUBSTRING(eia_identificador_evento, 4, 3))), 0) + 1` con `UPDLOCK, HOLDLOCK`.
   - Prueba: `RA-001` → 547.
6. **C2 Firma fuera del `IF NOT UPDATE` [S]** — en TR_acf, TR_rpi, TR_aci (incluida la firma de Archivo, L3668) y TR_eia:
   - dejar bajo `IF NOT UPDATE (<acr>_fecha_actualizacion)` solo la fecha;
   - mover la firma a su propio `UPDATE t SET per_codigo_… = @per_actor … WHERE <transición>`.
   - Corregir RN-INT-06 en la especificación: lo garantiza el trigger, no un CHECK (ver `e34db73`).
   - Prueba: como `dbo`, pasar a VIGENTE con la fecha en el SET → el aprobador queda firmado.
7. **C3 Cinco reglas de la app al motor [M]** — cada una es un `IF EXISTS … THROW 50020` en un bloque de transición que ya existe, y lleva una prueba que espera 50020. Plantilla de la primera:
   ```sql
   -- TR_aci, junto a la regla D3 (L3496): RN-DOC-06 y RN-ACT-05
   IF EXISTS (SELECT 1
              FROM   inserted AS i
                     INNER JOIN deleted AS d ON d.aci_codigo = i.aci_codigo
              WHERE  i.aci_estado_registro = N'VIGENTE'
                     AND d.aci_estado_registro <> N'VIGENTE'
                     AND (EXISTS (SELECT 1 FROM sgspi.activo_documental AS ado
                                  WHERE ado.ado_codigo = i.aci_codigo AND ado.ado_esta_activo = 1
                                        AND ado.per_codigo_revisor_archivo IS NULL)
                          OR NOT EXISTS (SELECT 1 FROM sgspi.activo_informacion_responsable AS air
                                         WHERE air.aci_codigo = i.aci_codigo AND air.air_esta_activo = 1
                                               AND air.air_tipo_responsabilidad = N'CUSTODIO')))
       THROW 50020, N'Transición incompleta: VIGENTE exige el aval de Archivo (activo documental) y un custodio activo en [sgspi].[activo_informacion].', 1;
   ```
   Las otras tres van en el bloque de requisitos de TR_eia (L3983), leyendo `plt`/`act` con `UPDLOCK`:
   - `→ EN_EVALUACION_EFICACIA`: el plan activo tiene al menos una actividad activa y todas están en `COMPLETADA` (paso 11, `.md L611`);
   - `→ APROBADO_PLANIFICADO` con naturaleza RIESGO: `epr_codigo_residual_meta <= epr_codigo_inherente` y `eim_codigo_residual_meta <= eim_codigo_inherente` (RN-RSG-04). Solo se exige que no suba, porque el catálogo no marca qué estrategia mitiga;
   - `→ APROBADO_PLANIFICADO` con activo primario de datos personales: al menos un control activo en `ptc` cuya norma tenga `enc_familia_norma = N'ISO27701'` (RN-RSG-05). Hay que añadir `ISO27701` a la lista de identificadores que no se renombran (L299).

   En la especificación, quitar "validación en capa de aplicación" de esas cinco RN. Se quedan en la app RN-DOC-04 (necesita una marca de publicación externa en `epc`), RN-DOC-05, RN-ACT-04, RN-PI-01 y RN-RSG-02 (necesita la clase primario/soporte en `tac`). Escribir allí que quien tenga las credenciales reales se las puede saltar.
8. **C4 Vigencia no abierta [S, D7]** — en TR_acf, TR_rpi, TR_ado, TR_eia y TR_eac, error nuevo 50022, que se añade a la lista de errores de la cabecera:
   ```sql
   IF EXISTS (SELECT 1
              FROM   inserted AS i
                     INNER JOIN sgspi.periodo_vigencia AS pev ON pev.pev_codigo = i.pev_codigo
              WHERE  pev.pev_estado_vigencia IN (N'CERRADA', N'HISTORICA')
                     AND NOT EXISTS (SELECT 1 FROM deleted AS d
                                     WHERE d.acf_codigo = i.acf_codigo AND d.pev_codigo = i.pev_codigo))
       THROW 50022, N'Vigencia cerrada: no se crean registros ni se mueven a una vigencia CERRADA o HISTORICA en [sgspi].[analisis_contexto_factor].', 1;
   ```
   La edición de lo que ya existe la sigue gobernando la máquina de estados. Prueba: alta en una vigencia `CERRADA` → 50022.

### Fase 3 — Trazabilidad (dimensión 10)

**Estado:** aplicada el 2026-11-18 en el DDL, las pruebas, la especificación y `sql/sgspi/auditoria_servidor.sql`, sin ejecutar contra SQL Server. Los pasos describen lo que quedó.

9. **T1 Registrar las altas [L, mecánico]**:
   - En las 50 `aud_*`, una columna `<aud>_operacion CHAR(1) CONSTRAINT DF_<aud>_operacion DEFAULT 'U' NOT NULL CONSTRAINT CK_<aud>_operacion CHECK (<aud>_operacion IN ('I', 'U'))`, donde `'I'` es la fila creada con sus valores nuevos y `'U'` la versión anterior, como hoy.
   - Los 41 `TR_<acr>_auditoria` pasan a `AFTER INSERT, UPDATE, DELETE`, y donde hoy dice `IF NOT EXISTS (SELECT 1 FROM deleted) RETURN;` escriben las filas de `inserted` con `'I'`, `@per_actor` y la fecha.
   - Los 8 triggers `TR_<acr>_integridad_y_actualizacion` hacen lo mismo con las filas nuevas. En `sga`, lo hace `TR_sga_sincronizar_avance`, que es el que corre en el INSERT.
   - La fila de máximo tamaño gana 1 B.
   - Pruebas: la guarda de columnas (PRUEBAS L76) pasa de `+ 4` a `+ 5`, y un alta en `air` deja una fila `'I'` con la persona de la sesión.
   - Actualizar AP-01 y el comentario de L1578. Conviene hacerlo con un script de reemplazo sobre el patrón, porque los 50 bloques son idénticos.
10. **T2 Auditoría del servidor [M, DBA]** — en un script aparte, `sql/sgspi/auditoria_servidor.sql`, porque `CREATE SERVER AUDIT` no puede ir dentro de la transacción del despliegue:
    ```sql
    -- master
    CREATE SERVER AUDIT sgspi_auditoria TO FILE (FILEPATH = N'<ruta fuera del alcance del DBA de la BD>', MAXSIZE = 256 MB, MAX_ROLLOVER_FILES = 100)
        WITH (ON_FAILURE = CONTINUE);
    ALTER SERVER AUDIT sgspi_auditoria WITH (STATE = ON);
    -- base de datos
    CREATE DATABASE AUDIT SPECIFICATION sgspi_auditoria_bd FOR SERVER AUDIT sgspi_auditoria
        ADD (SCHEMA_OBJECT_CHANGE_GROUP),             -- ALTER de tablas y triggers
        ADD (DATABASE_ROLE_MEMBER_CHANGE_GROUP),      -- altas y bajas en sgspi_rol_*
        ADD (SCHEMA_OBJECT_PERMISSION_CHANGE_GROUP),  -- GRANT/DENY sobre objetos
        ADD (DATABASE_PERMISSION_CHANGE_GROUP),
        ADD (INSERT, UPDATE, DELETE ON SCHEMA::sgspi BY public)  -- incluye la carga histórica con triggers apagados
        WITH (STATE = ON);
    ```
    - Prueba en la instancia: `DISABLE TRIGGER` y `ALTER ROLE … ADD MEMBER` deben aparecer en `sys.fn_get_audit_file`. Hay que confirmarlo, porque no se probó.
    - Reescribir AP-04: la carga histórica se hace con la auditoría encendida, vuelve a habilitar los triggers en el mismo script y termina con consultas de control que deben dar cero filas (estado inicial, aprobador en VIGENTE, propietario único).

### Fase 4 — Datos sensibles (dimensión 11)

**Estado:** aplicada el 2026-11-18 en el DDL, las pruebas y la especificación (DS1 y la verificación de TDE de DS2; activar TDE en la instancia queda a cargo del DBA), sin ejecutar contra SQL Server. El paso 13 (opcional) se omite.

11. **DS1 Cuenta compartida por lista blanca [S, D8]**:
    - Quitar `ALTER ROLE sgspi_rol_base ADD MEMBER sgspi_rol_consulta` (L8667) y los dos DENY de columnas (L8694-8698), que dejan de hacer falta.
    - Dar `GRANT SELECT … TO sgspi_rol_consulta` solo sobre los catálogos y las vistas que se acuerden en D8. Recomendado: `vw_consolidado_dofa`, `vw_resumen_activos_criticidad`, `vw_desglose_ccd_trd_mr04`, `vw_inventario_activo_documental_mr04` y `vw_controles_atributos_iso27002`, más los catálogos. Las vistas no necesitan permiso sobre las tablas, porque el encadenamiento de propiedad lo resuelve.
    - Pruebas: la cuenta compartida lee `vw_inventario_activo_documental_mr04` → 0, y no lee `plan_tratamiento` ni `aud_activo_informacion` → 229. Las tres pruebas de PRUEBAS L408-412 pasan a esperar 229, porque la cuenta ya no tiene ningún permiso sobre `eia`.
12. **DS2 Cifrado en reposo [S + DBA]**:
    - El DBA activa TDE (`CREATE DATABASE ENCRYPTION KEY WITH ALGORITHM = AES_256 ENCRYPTION BY SERVER CERTIFICATE …; ALTER DATABASE … SET ENCRYPTION ON;`) y respalda con `BACKUP … WITH ENCRYPTION`. El certificado y su clave privada se guardan fuera del servidor.
    - Afecta a toda la base `academia3000`, no solo a `sgspi`.
    - En el DDL, añadir a la verificación posterior una fila "base sin TDE" cuando `sys.databases.is_encrypted = 0`.
13. *(Opcional)* Si la auditoría solo debe leerla el auditor y el oficial, mover las `aud_*` a un esquema `sgspi_aud` con un GRANT de esquema. Los 50 DENY de L8916-9064 quedarían en uno, y los triggers solo cambian el prefijo `sgspi.aud_` por `sgspi_aud.aud_`.

### Decisiones (respondidas el 2026-11-18)

| # | Pregunta | Respuesta | Aplicado |
|---|---|---|---|
| D7 | ¿Qué estados de vigencia admiten altas? | La recomendada: `EN_CONFIGURACION` y `ABIERTA` sí; `CERRADA` e `HISTORICA` no. | C4 (fase 2) |
| D8 | ¿Qué pantallas usan la cuenta compartida y qué deben ver? | La recomendada: catálogos y las cinco vistas de inventario, DOFA y controles; nada de `eia`, `plt`, `act`, `sga` ni `aud_*`. | DS1 (fase 4) |
| D9 | ¿El gestor documental registra actividades y seguimientos? | Sí, con alcance `[Asignado]`, como ya dice la especificación (matriz 5.3, tabla 11.1). La recomendación "No" partía de un dato falso; se aplicó su rama "si sí". | P3 (fase 1) |

## 4. Mejoras menores (dimensiones con 4), cada una S

- `plt_porcentaje_cumplimiento_kpi`: `DECIMAL (9, 2)` → `DECIMAL (15, 2)` (L1326). Es un error real de disponibilidad: una fila extrema tumba la vista.
- `TR_sga_inmutabilidad`: al desactivar un seguimiento, recalcular `act_porcentaje_avance` con el último seguimiento activo.
- Hash en minúsculas: en `CK_sga_hash_formato`, `sga_hash_sha256_evidencia COLLATE Latin1_General_BIN2 NOT LIKE '%[^0-9a-f]%'`, o pasar a `BINARY(32)`.
- `CHECK (aci_codigo_soporte <> aci_codigo_primario)` en `eia`, y `UQ_plt_evento` → índice único filtrado `WHERE plt_esta_activo = 1`.
- Una función `sgspi.ufn_persona_sesion()` (inline, `RETURNS TABLE`) en lugar de las 53 copias de `TOP (1) … ORIGINAL_LOGIN()`.
- En la verificación previa o posterior: confirmar los índices de `dbo.usuario_general(us)` y `dbo.usuario_grupo(usg_usuario)`. Añadir `EXECUTE sys.sp_addextendedproperty N'sgspi_version', N'2.1', N'SCHEMA', N'sgspi';`.
- Documentar las opciones SET obligatorias para cualquier script que escriba en `sgspi` (`sqlcmd -I`, jobs del Agente).
- Especificación: una línea de volumetría y retención de `aud_*`, y sustituir "Row-Level Security" (`.md L183`, `L641`) por "alcance de escritura por triggers (50021)".

## 5. Efecto esperado

| Dimensión | Hoy | Tras el plan |
|---|:-:|:-:|
| 2 Claves y restricciones | 3 | 4–5 |
| 9 Privilegios mínimos | 3 | 4–5 |
| 10 Trazabilidad | 3 | 5 (4 sin T2) |
| 11 Datos sensibles | 3 | 4 (5 con TDE confirmado) |
