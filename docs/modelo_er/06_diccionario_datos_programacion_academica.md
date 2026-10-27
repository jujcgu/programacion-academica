# 06 - Diccionario de Datos: Esquema `programacionacademica`

## Sistema de Programación Académica (`p_academica-main`)

---

## 1. Resumen Ejecutivo y Métricas del Esquema

El esquema `programacionacademica` constituye el **núcleo transaccional especializado** del sistema. Fue concebido como una capa desacoplada del esquema corporativo `dbo` para gobernar con autonomía la apertura y cierre de ventanas de captura curricular, la conformación de grupos de gestión para unidades académicas y los dos grandes flujos de concertación universitaria:

1. **Solicitudes de Cambio de Horario (`solicitud_cambio_horario`):** Gestión de traslados de aula, franjas horarias y reasignaciones profesorales con validación física y aprobación en múltiples niveles (Secretaría, Jefatura, Planta Física, Vicerrectoría).
2. **Solicitudes de Préstamo Docente (`solicitud_prestamo_docente`):** Mecanismo interdepartamental para coordinar la adscripción temporal de profesores entre facultades y departamentos.

### Métricas Consolidadas del Esquema

| Métrica Arquitectónica | Valor | Descripción Técnica |
| :--- | :---: | :--- |
| **Total de Tablas Físicas** | **12** | 100% definidas en `sql/programacionacademica/*.sql` |
| **Total de Columnas Catalogadas** | **68** | Tipos: `int`, `tinyint`, `varchar`, `char`, `datetime`, `date` |
| **Claves Primarias (PK)** | **12** | 100% de tablas cuentan con PK subrogada con `IDENTITY(1,1)` |
| **Estructura de Índices PK** | 1 Clustered / 11 NonClustered | `programacion_tipo_solicitudes` posee índice CLUSTERED; las demás son NONCLUSTERED |
| **Claves Foráneas Explícitas (DDL)** | **22** | 4 internas a `programacionacademica` y 18 cruzadas hacia `dbo` |
| **Claves Foráneas Implícitas (Código)** | **4** | Detectadas por convención y verificadas en lógica PHP (`Solcambh.php`, `Soldoc.php`) |
| **Total de Relaciones Salientes** | **26** | 6 internas + 20 hacia entidades institucionales de `dbo` |
| **Tablas Foráneas de `dbo` Referenciadas** | **12** | `uaa`, `calendario`, `periodo`, `programacion_proceso`, `curso`, `dia`, `hora`, `espacio`, `uaa_personal`, `asignatura`, `persona`, `sede` |

---

## 2. Catálogo Técnico y Diccionario de Entidades

### 2.1 Entidad: `programacionacademica.grupo_uaa`

- **Submódulo Funcional:** Períodos, Unidades y Agrupaciones UAA
- **Archivo Fuente DDL:** `sql/programacionacademica/grupo_uaa.sql`
- **Descripción Funcional:** Cabecera maestra que define agrupaciones lógicas de Unidades Académico-Administrativas (UAA) con el propósito de aplicar configuraciones masivas de fechas de apertura y reglas operativas de programación curricular.

#### Reglas de Negocio y Validación Operativa
- Permite consolidar facultades o departamentos afines bajo una misma política de apertura de calendario.
- El estado `pgr_estado = 1` habilita la agrupación para ser seleccionada en interfaces administrativas.
- Una agrupación no puede ser eliminada físicamente si tiene registros asociados en `grupo_uaa_item` (integridad referencial).

#### Ciclo de Vida y Máquina de Estados
Estado binario: `1` = Activo / Vigente, `0` = Inactivo / Deshabilitado lógicamente.

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `pgr_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Identificador único y clave primaria subrogada del grupo de UAA. |
| 2 | `pgr_nombre` | `varchar` | 100 | NO | - | **-** | Nombre descriptivo y formal asignado a la agrupación de unidades. |
| 3 | `pgr_estado` | `int` | - | NO | - | **Estado** | Bandera de estado lógico operativo (1: Activo, 0: Inactivo). |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_pgr_codigo` (NONCLUSTERED) sobre `([pgr_codigo] ASC)`

#### Restricciones de Integridad Referencial
- **Claves Foráneas Explícitas:** Ninguna definida en DDL.

---

### 2.2 Entidad: `programacionacademica.grupo_uaa_item`

- **Submódulo Funcional:** Períodos, Unidades y Agrupaciones UAA
- **Archivo Fuente DDL:** `sql/programacionacademica/grupo_uaa_item.sql`
- **Descripción Funcional:** Entidad asociativa de detalle que vincula unidades académicas específicas (`dbo.uaa`) a un grupo lógico determinado (`grupo_uaa`).

#### Reglas de Negocio y Validación Operativa
- Cada registro enlaza exactamente una UAA con un grupo lógico.
- Una UAA puede pertenecer a un grupo de gestión para centralizar la parametrización de sus calendarios.
- La eliminación de una UAA del grupo se realiza mediante borrado lógico (`gui_estado = 0`) para preservar la trazabilidad.

#### Ciclo de Vida y Máquina de Estados
Estado de asignación: `1` = Vinculación Activa, `0` = Vinculación Inactiva / Retirada.

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `gui_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Identificador único de la pertenencia de la unidad al grupo. |
| 2 | `pgr_codigo` | `int` | - | NO | - | **FK** | Clave foránea que referencia al grupo cabecera (`programacionacademica.grupo_uaa`). |
| 3 | `uaa_codigo` | `int` | - | NO | - | **FK** | Clave foránea que referencia a la unidad académica adscrita (`dbo.uaa`). |
| 4 | `gui_estado` | `int` | - | NO | - | **Estado** | Estado de vigencia de la asociación (1: Activo, 0: Inactivo). |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_gui_codigo` (NONCLUSTERED) sobre `([gui_codigo] ASC)`

#### Restricciones de Integridad Referencial
**Claves Foráneas Explícitas (DDL):**
- `FK_pgr_codigo`: `grupo_uaa_item.pgr_codigo` -> `[programacionacademica].[grupo_uaa](pgr_codigo)`
- `FK_uaa_codigo`: `grupo_uaa_item.uaa_codigo` -> `[dbo].[uaa](uaa_codigo)`

---

### 2.3 Entidad: `programacionacademica.periodo_unidad`

- **Submódulo Funcional:** Períodos, Unidades y Agrupaciones UAA
- **Archivo Fuente DDL:** `sql/programacionacademica/periodo_unidad.sql`
- **Descripción Funcional:** Configuración temporal que permite desacoplar el calendario general institucional estableciendo rangos de fechas (inicio y fin) específicos e independientes por cada unidad académica (`dbo.uaa`) dentro de un periodo lectivo (`dbo.periodo`).

#### Reglas de Negocio y Validación Operativa
- Permite a programas con regímenes especiales (ej. Postgrados, Medicina, Programas a Distancia) contar con fechas lectivas distintas a las del pregrado central.
- `peu_fecha_fin` debe ser estrictamente posterior a `peu_fecha_inicio`.
- Los procesos de matrícula y radicación de cursos validan que la fecha actual se encuentre dentro de esta ventana para la UAA correspondiente.

#### Ciclo de Vida y Máquina de Estados
Estado: `1` = Habilitado / Activo, `0` = Inactivo. La ventana temporal adquiere relevancia operativa cuando la fecha del sistema se sitúa entre `peu_fecha_inicio` y `peu_fecha_fin`.

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `peu_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Identificador único de la ventana de periodo por unidad. |
| 2 | `uaa_codigo` | `int` | - | NO | - | **FK** | Clave foránea que identifica la UAA a la que aplica la ventana (`dbo.uaa`). |
| 3 | `per_codigo` | `int` | - | NO | - | **FK** | Clave foránea del periodo lectivo institucional (`dbo.periodo`). |
| 4 | `peu_fecha_inicio` | `date` | - | NO | - | **-** | Fecha oficial de inicio de actividades lectivas para la unidad. |
| 5 | `peu_fecha_fin` | `date` | - | NO | - | **-** | Fecha oficial de culminación de actividades lectivas para la unidad. |
| 6 | `peu_estado` | `tinyint` | - | NO | - | **Estado** | Estado de la parametrización temporal (1: Activo, 0: Inactivo). |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_peu_periodo_unidad` (NONCLUSTERED) sobre `([peu_codigo] ASC)`

#### Restricciones de Integridad Referencial
**Claves Foráneas Explícitas (DDL):**
- `FK_periodo_unidad_periodo`: `periodo_unidad.per_codigo` -> `[dbo].[periodo](per_codigo)`
- `FK_periodo_unidad_uaa`: `periodo_unidad.uaa_codigo` -> `[dbo].[uaa](uaa_codigo)`

---

### 2.4 Entidad: `programacionacademica.programacion_academica`

- **Submódulo Funcional:** Núcleo de Programación Académica y Ventanas Operativas
- **Archivo Fuente DDL:** `sql/programacionacademica/programacion_academica.sql`
- **Descripción Funcional:** Entidad nuclear que gobierna las ventanas de apertura temporal (fecha y hora exacta de inicio y fin) para la captura, ajuste y oferta de cursos en el sistema, discriminadas por unidad académica (`uaa`), calendario académico (`calendario`) y etapa o proceso de programación (`programacion_proceso`).

#### Reglas de Negocio y Validación Operativa
- Regula las 4 etapas estándar de la programación académica institucional: 1. Asignaturas Institucionales, 2. Electivas de Facultad, 3. Asignaturas de Programas, 4. Repesca / Ajustes finales.
- Los coordinadores de programa y jefes de departamento sólo pueden crear, modificar o eliminar cursos si existe una ventana activa (`pra_estado = 1` y fecha actual entre `pra_fecha_inicio` y `pra_fecha_fin`).
- Las fechas de captura no pueden solaparse de manera contradictoria para el mismo proceso y unidad.

#### Ciclo de Vida y Máquina de Estados
Máquina de estados temporal combinada:
- *Pendiente*: `pra_estado = 1` y `NOW() < pra_fecha_inicio`.
- *Activa / En Proceso*: `pra_estado = 1` y `pra_fecha_inicio <= NOW() <= pra_fecha_fin`.
- *Vencida / Cerrada*: `pra_estado = 1` y `NOW() > pra_fecha_fin`.
- *Cancelada / Inactiva*: `pra_estado = 0`.

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `pra_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Identificador único del registro de apertura de captura de programación. |
| 2 | `uaa_codigo` | `int` | - | NO | - | **FK** | Clave foránea hacia la UAA facultada para programar (`dbo.uaa`). |
| 3 | `prp_codigo` | `int` | - | NO | - | **FK** | Clave foránea hacia la fase o proceso operativo (`dbo.programacion_proceso`). |
| 4 | `cal_codigo` | `int` | - | NO | - | **FK** | Clave foránea hacia el calendario lectivo institucional (`dbo.calendario`). |
| 5 | `pra_fecha_inicio` | `datetime` | - | NO | - | **-** | Fecha y hora exacta de apertura del sistema para la unidad y fase. |
| 6 | `pra_fecha_fin` | `datetime` | - | NO | - | **-** | Fecha y hora exacta del cierre definitivo de la ventana de captura. |
| 7 | `pra_estado` | `tinyint` | - | NO | - | **Estado** | Indicador lógico de vigencia de la ventana (1: Activo, 0: Inactivo). |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_pra_programacion_academica` (NONCLUSTERED) sobre `([pra_codigo] ASC)`

#### Restricciones de Integridad Referencial
**Claves Foráneas Explícitas (DDL):**
- `FK_programacion_academica_calendario`: `programacion_academica.cal_codigo` -> `[dbo].[calendario](cal_codigo)`
- `FK_programacion_academica_proceso`: `programacion_academica.prp_codigo` -> `[dbo].[programacion_proceso](prp_codigo)`
- `FK_programacion_academica_uaa`: `programacion_academica.uaa_codigo` -> `[dbo].[uaa](uaa_codigo)`

---

### 2.5 Entidad: `programacionacademica.programacion_gestion`

- **Submódulo Funcional:** Núcleo de Programación Académica y Ventanas Operativas
- **Archivo Fuente DDL:** `sql/programacionacademica/programacion_gestion.sql`
- **Descripción Funcional:** Administra las ventanas temporales autorizadas para que las secretarías académicas y coordinaciones radiquen y gestionen solicitudes académicas (cambios de horario o préstamos docentes), parametrizadas por unidad académica, calendario y tipo de trámite.

#### Reglas de Negocio y Validación Operativa
- Gobernanza de fechas límite para la radicación de solicitudes por tipo (`pts_codigo`).
- Evita que se radiquen solicitudes extemporáneas una vez culminado el plazo institucional.
- Permite a la Vicerrectoría Académica extender plazos excepcionales a unidades específicas sin alterar el calendario de las demás.

#### Ciclo de Vida y Máquina de Estados
Estado: `1` = Activa, `0` = Inactiva. Valida en tiempo de ejecución: `prg_fecha_inicio <= NOW() <= prg_fecha_fin`.

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `prg_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Identificador único de la ventana de gestión de solicitudes. |
| 2 | `uaa_codigo` | `int` | - | NO | - | **FK** | Clave foránea que identifica la UAA gestora (`dbo.uaa`). |
| 3 | `cal_codigo` | `int` | - | NO | - | **FK** | Clave foránea del calendario académico institucional (`dbo.calendario`). |
| 4 | `prg_fecha_inicio` | `datetime` | - | NO | - | **-** | Fecha y hora de inicio de radicación autorizada. |
| 5 | `prg_fecha_fin` | `datetime` | - | NO | - | **-** | Fecha y hora límite de recepción de solicitudes. |
| 6 | `prg_estado` | `tinyint` | - | NO | - | **Estado** | Estado operativo de la ventana (1: Habilitada, 0: Inhabilitada). |
| 7 | `pts_codigo` | `int` | - | NO | - | **FK** | Clave foránea que restringe la ventana al tipo de trámite (`programacion_tipo_solicitudes`). |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_prg_programacion_gestion` (NONCLUSTERED) sobre `([prg_codigo] ASC)`

#### Restricciones de Integridad Referencial
**Claves Foráneas Explícitas (DDL):**
- `FK_programacion_gestion_calendario`: `programacion_gestion.cal_codigo` -> `[dbo].[calendario](cal_codigo)`
- `FK_programacion_gestion_tipo_solicitud`: `programacion_gestion.pts_codigo` -> `[programacionacademica].[programacion_tipo_solicitudes](pts_codigo)`
- `FK_programacion_gestion_uaa`: `programacion_gestion.uaa_codigo` -> `[dbo].[uaa](uaa_codigo)`

---

### 2.6 Entidad: `programacionacademica.programacion_tipo_solicitudes`

- **Submódulo Funcional:** Núcleo de Programación Académica y Catálogos
- **Archivo Fuente DDL:** `sql/programacionacademica/programacion_tipo_solicitudes.sql`
- **Descripción Funcional:** Catálogo maestro que tipifica los diferentes tipos de solicitudes y trámites administrativos operados por el sistema de programación académica.

#### Reglas de Negocio y Validación Operativa
- Identifica unívocamente las modalidades de trámite (ej. 1: Solicitud de Cambio de Horario, 2: Solicitud de Préstamo Docente).
- Es la única tabla del esquema configurada físicamente con un índice PRIMARY KEY CLUSTERED.
- Sus códigos son referenciados de manera estricta por `programacion_gestion` para la apertura de plazos.

#### Ciclo de Vida y Máquina de Estados
Catálogo estático: `pts_estado = 1` (Vigente / Habilitado para uso en el sistema), `0` (Deprecado).

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `pts_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Identificador numérico único del tipo de solicitud académica. |
| 2 | `pts_nombre` | `varchar` | 100 | NO | - | **-** | Denominación oficial del trámite (ej. 'Cambio de Horario', 'Préstamo Docente'). |
| 3 | `pts_estado` | `tinyint` | - | NO | - | **Estado** | Estado de vigencia en el catálogo maestro (1: Activo, 0: Inactivo). |

#### Índices y Claves Primarias
- **Clave Primaria:** Subrogada IDENTITY.

#### Restricciones de Integridad Referencial
- **Claves Foráneas Explícitas:** Ninguna definida en DDL.

---

### 2.7 Entidad: `programacionacademica.solicitud_cambio_horario`

- **Submódulo Funcional:** Gestión de Solicitudes de Cambio de Horario
- **Archivo Fuente DDL:** `sql/programacionacademica/solicitud_cambio_horario.sql`
- **Descripción Funcional:** Entidad transaccional cabecera que registra los requerimientos formales de modificación de horarios, espacios físicos o docentes asignados sobre cursos previamente programados, gestionando un flujo de aprobación multinivel.

#### Reglas de Negocio y Validación Operativa
- Debe apuntar a un curso preexistente y válido en `dbo.curso`.
- El radicador debe ser un usuario autenticado registrado en `dbo.usuario_general`.
- No se permite crear una nueva solicitud sobre un curso si existe otra en trámite (estados 1, 2 o 7).
- Alcanzar el estado final de aprobación (estado 4 o 6) desencadena la actualización atómica de las reservas físicas en `dbo.espacio_ocupacion`.

#### Ciclo de Vida y Máquina de Estados
Máquina de estados multinivel (`sch_estado`):
- `0`: Eliminado lógicamente
- `1`: Solicitado (radicado ante Planta Física)
- `2`: Aprobado Planta Física (pendiente de aval por Vicerrectoría Académica)
- `3`: Rechazado por Planta Física
- `4`: Aprobado Vicerrectoría Académica (aprobación final y aplicación a ocupaciones)
- `5`: Rechazado por Vicerrectoría Académica
- `6`: Aprobado Curso Virtual (aprobación directa y automática sin necesidad de aula física)
- `7`: Solicitado Jefe de Programa (radicado por Secretaría, en espera de aval del Jefe)
- `8`: Rechazado por Jefe de Programa

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `sch_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Identificador único y clave primaria de la solicitud de cambio de horario. |
| 2 | `cur_codigo` | `int` | - | NO | - | **FK** | Clave foránea hacia el curso institucional afectado (`dbo.curso`). |
| 3 | `usu_codigo` | `int` | - | NO | - | **FK Implícita** | Clave foránea implícita hacia el usuario institucional radicador (`dbo.usuario_general.uid`). |
| 4 | `uaa_codigo` | `int` | - | NO | - | **FK** | Clave foránea hacia la unidad académica radicadora (`dbo.uaa`). |
| 5 | `sch_cambio_docente` | `int` | - | SÍ | - | **-** | Bandera booleana: `1` indica que la solicitud incluye cambio de profesor. |
| 6 | `sch_cambio_semanas` | `int` | - | SÍ | - | **-** | Bandera booleana: `1` indica que el cambio aplica sólo a semanas específicas. |
| 7 | `sch_estado` | `int` | - | NO | - | **Estado** | Estado transaccional en el flujo de aprobación multinivel (0 a 8). |
| 8 | `sch_fecha_creacion` | `datetime` | - | NO | - | **Auditoría** | Marca temporal oficial de radicación de la solicitud. |
| 9 | `sch_espacio_deportivo` | `int` | - | SÍ | - | **-** | Bandera booleana: `1` indica que requiere escenarios deportivos especiales. |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_sch_solicitud_cambio_horario` (NONCLUSTERED) sobre `([sch_codigo] ASC)`

#### Restricciones de Integridad Referencial
**Claves Foráneas Explícitas (DDL):**
- `FK_solicitud_cambio_horario_curso`: `solicitud_cambio_horario.cur_codigo` -> `[dbo].[curso](cur_codigo)`
- `FK_solicitud_cambio_horario_uaa_codigo`: `solicitud_cambio_horario.uaa_codigo` -> `[dbo].[uaa](uaa_codigo)`
- **Claves Foráneas Implícitas:** `usu_codigo` -> `[dbo].[usuario_general].[uid]` (Usuario autenticado que crea la solicitud)

---

### 2.8 Entidad: `programacionacademica.solicitud_cambio_horario_comentario`

- **Submódulo Funcional:** Auditoría, Trazabilidad y Comentarios
- **Archivo Fuente DDL:** `sql/programacionacademica/solicitud_cambio_horario_comentario.sql`
- **Descripción Funcional:** Bitácora cronológica de observaciones, justificaciones y conceptos emitidos por los distintos actores (Secretaría, Jefatura, Planta Física, Vicerrectoría) durante el trámite de una solicitud de cambio de horario.

#### Reglas de Negocio y Validación Operativa
- Cada comentario pertenece obligatoriamente a una solicitud de cambio de horario.
- Todo comentario queda asociado al usuario que lo redactó para garantizar la auditoría.
- Los comentarios son de naturaleza append-only para preservar la trazabilidad jurídica.

#### Ciclo de Vida y Máquina de Estados
Registro de auditoría permanente: ordenado por `schc_fecha_creacion ASC`.

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `schc_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Identificador único del comentario de cambio de horario. |
| 2 | `sch_codigo` | `int` | - | NO | - | **FK** | Clave foránea que referencia la solicitud cabecera (`solicitud_cambio_horario`). |
| 3 | `schc_fecha_creacion` | `datetime` | - | NO | - | **Auditoría** | Fecha y hora exacta en la que se consignó el comentario. |
| 4 | `schc_comentario` | `varchar` | max | NO | - | **-** | Texto íntegro de la observación, concepto o justificación técnica. |
| 5 | `usu_codigo` | `int` | - | NO | - | **FK Implícita** | Clave foránea implícita hacia el usuario autor (`dbo.usuario_general.uid`). |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_schc_solicitud_cambio_horario_comentario` (NONCLUSTERED) sobre `([schc_codigo] ASC)`

#### Restricciones de Integridad Referencial
**Claves Foráneas Explícitas (DDL):**
- `FK_solicitud_cambio_horario_comentario_solicitud`: `solicitud_cambio_horario_comentario.sch_codigo` -> `[programacionacademica].[solicitud_cambio_horario](sch_codigo)`
- **Claves Foráneas Implícitas:** `usu_codigo` -> `[dbo].[usuario_general].[uid]` (Autor de la observación o concepto)

---

### 2.9 Entidad: `programacionacademica.solicitud_cambio_horario_horario`

- **Submódulo Funcional:** Gestión de Solicitudes de Cambio de Horario
- **Archivo Fuente DDL:** `sql/programacionacademica/solicitud_cambio_horario_horario.sql`
- **Descripción Funcional:** Detalle técnico de franjas horarias y espacios que materializa la transición entre el estado de programación actual ('anterior') y el estado pretendido ('nuevo'), soportando cambios transitorios o permanentes.

#### Reglas de Negocio y Validación Operativa
- Estructura pareada: almacena simultáneamente `dia`, `hora`, `espacio` y `docente` anterior vs nuevo.
- Si la materia es virtual, `schh_esp_codigo_nuevo` puede ser NULL.
- Si el cambio no modifica docente, `schh_uap_codigo_nuevo` puede mantenerse NULL o igual al anterior.
- Las fechas `schh_fecha_inicio` y `schh_fecha_fin` delimitan la vigencia cuando `sch_cambio_semanas = 1`.

#### Ciclo de Vida y Máquina de Estados
Estado del ítem: `1` = Activo / Parte de la propuesta, `0` = Descartado / Eliminado.

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `schh_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Identificador único del ítem horario de la solicitud. |
| 2 | `sch_codigo` | `int` | - | NO | - | **FK** | Clave foránea a la solicitud cabecera (`solicitud_cambio_horario`). |
| 3 | `schh_estado` | `int` | - | NO | - | **Estado** | Estado del ítem de horario (1: Activo, 0: Inactivo). |
| 4 | `schh_subgrupo` | `char` | 2 | NO | - | **FK Implícita** | Clave foránea implícita a la sección o subgrupo del curso (`dbo.curso_cupo_subgrupo`). |
| 5 | `schh_dia_codigo_anterior` | `int` | - | NO | - | **FK / Transición** | Clave foránea al día de la semana original (`dbo.dia`). |
| 6 | `schh_hra_codigo_anterior` | `int` | - | NO | - | **FK / Transición** | Clave foránea a la franja horaria original (`dbo.hora`). |
| 7 | `schh_esp_codigo_anterior` | `int` | - | NO | - | **FK / Transición** | Clave foránea al aula o espacio original (`dbo.espacio`). |
| 8 | `schh_uap_codigo_anterior` | `int` | - | NO | - | **FK / Transición** | Clave foránea a la vinculación docente original (`dbo.uaa_personal`). |
| 9 | `schh_dia_codigo_nuevo` | `int` | - | NO | - | **FK / Transición** | Clave foránea al nuevo día lectivo propuesto (`dbo.dia`). |
| 10 | `schh_hra_codigo_nuevo` | `int` | - | NO | - | **FK / Transición** | Clave foránea a la nueva franja horaria propuesta (`dbo.hora`). |
| 11 | `schh_esp_codigo_nuevo` | `int` | - | SÍ | - | **FK / Transición** | Clave foránea al nuevo espacio físico asignado (`dbo.espacio`, opcional/nullable). |
| 12 | `schh_uap_codigo_nuevo` | `int` | - | SÍ | - | **FK / Transición** | Clave foránea al nuevo docente propuesto (`dbo.uaa_personal`, opcional/nullable). |
| 13 | `schh_fecha_inicio` | `date` | - | SÍ | - | **-** | Fecha inicial de vigencia para cambios por semanas (nullable). |
| 14 | `schh_fecha_fin` | `date` | - | SÍ | - | **-** | Fecha final de vigencia para cambios por semanas (nullable). |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_schh_solicitud_cambio_horario_horario` (NONCLUSTERED) sobre `([schh_codigo] ASC)`

#### Restricciones de Integridad Referencial
**Claves Foráneas Explícitas (DDL):**
- `FK_solicitud_cambio_horario_horario_dia_anterior`: `solicitud_cambio_horario_horario.schh_dia_codigo_anterior` -> `[dbo].[dia](dia_codigo)`
- `FK_solicitud_cambio_horario_horario_dia_nuevo`: `solicitud_cambio_horario_horario.schh_dia_codigo_nuevo` -> `[dbo].[dia](dia_codigo)`
- `FK_solicitud_cambio_horario_horario_esp_anterior`: `solicitud_cambio_horario_horario.schh_esp_codigo_anterior` -> `[dbo].[espacio](esp_codigo)`
- `FK_solicitud_cambio_horario_horario_esp_nuevo`: `solicitud_cambio_horario_horario.schh_esp_codigo_nuevo` -> `[dbo].[espacio](esp_codigo)`
- `FK_solicitud_cambio_horario_horario_hra_anterior`: `solicitud_cambio_horario_horario.schh_hra_codigo_anterior` -> `[dbo].[hora](hra_codigo)`
- `FK_solicitud_cambio_horario_horario_hra_nuevo`: `solicitud_cambio_horario_horario.schh_hra_codigo_nuevo` -> `[dbo].[hora](hra_codigo)`
- `FK_solicitud_cambio_horario_horario_solicitud`: `solicitud_cambio_horario_horario.sch_codigo` -> `[programacionacademica].[solicitud_cambio_horario](sch_codigo)`
- `FK_solicitud_cambio_horario_horario_uap_anterior`: `solicitud_cambio_horario_horario.schh_uap_codigo_anterior` -> `[dbo].[uaa_personal](uap_codigo)`
- `FK_solicitud_cambio_horario_horario_uap_nuevo`: `solicitud_cambio_horario_horario.schh_uap_codigo_nuevo` -> `[dbo].[uaa_personal](uap_codigo)`
- **Claves Foráneas Implícitas:** `schh_subgrupo` -> `[dbo].[curso_cupo_subgrupo].[ccs_subgrupo]` (Identificador de subgrupo del curso)

---

### 2.10 Entidad: `programacionacademica.solicitud_prestamo_docente`

- **Submódulo Funcional:** Gestión de Solicitudes de Préstamo Docente
- **Archivo Fuente DDL:** `sql/programacionacademica/solicitud_prestamo_docente.sql`
- **Descripción Funcional:** Cabecera de concertación interdepartamental e interfacultades que modela el requerimiento formal de un docente de otra UAA para cubrir una asignatura en una sede y periodo lectivo determinado.

#### Reglas de Negocio y Validación Operativa
- Conecta bilateralmente dos unidades académicas: la requirente (`uaa_solicita`) y la cedente (`uaa_dirigida`).
- Al radicarse, el campo `persona_codigo` permanece habitualmente NULL hasta que la unidad dirigida asigna y aprueba el docente.
- La aprobación final adjudica formalmente al profesor y permite su asignación en la oferta de cursos de la UAA solicitante.

#### Ciclo de Vida y Máquina de Estados
Máquina de estados de préstamo docente (`spd_estado`):
- `0`: Eliminado / Anulado
- `1`: Solicitado (radicado, en espera de revisión por el Director del departamento dirigido)
- `2`: Aprobado (profesor formalmente asignado en `persona_codigo`)
- `3`: Rechazado (petición negada por falta de horas o disponibilidad; `persona_codigo` nulo)

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `spd_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Identificador único y clave primaria de la solicitud de préstamo docente. |
| 2 | `periodo_codigo` | `int` | - | NO | - | **FK** | Clave foránea al periodo académico de la solicitud (`dbo.periodo.per_codigo`). |
| 3 | `persona_codigo` | `int` | - | SÍ | - | **FK** | Clave foránea al docente adjudicado (`dbo.persona.per_codigo`, nullable hasta aprobación). |
| 4 | `asi_codigo` | `int` | - | NO | - | **FK** | Clave foránea a la asignatura que requiere cobertura (`dbo.asignatura.asi_codigo`). |
| 5 | `spd_estado` | `tinyint` | - | NO | - | **Estado** | Estado en el flujo de concertación profesoral (0 a 3). |
| 6 | `uaa_solicita` | `int` | - | NO | - | **FK** | Clave foránea a la unidad académica solicitante (`dbo.uaa.uaa_codigo`). |
| 7 | `uaa_dirigida` | `int` | - | NO | - | **FK** | Clave foránea a la unidad académica poseedora del docente (`dbo.uaa.uaa_codigo`). |
| 8 | `sed_codigo` | `int` | - | NO | - | **FK** | Clave foránea a la sede universitaria de dictado (`dbo.sede.sed_codigo`). |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_spd_solicitud_prestamo_docente` (NONCLUSTERED) sobre `([spd_codigo] ASC)`

#### Restricciones de Integridad Referencial
**Claves Foráneas Explícitas (DDL):**
- `FK_solicitud_prestamo_docente_asignatura`: `solicitud_prestamo_docente.asi_codigo` -> `[dbo].[asignatura](asi_codigo)`
- `FK_solicitud_prestamo_docente_periodo`: `solicitud_prestamo_docente.periodo_codigo` -> `[dbo].[periodo](per_codigo)`
- `FK_solicitud_prestamo_docente_persona`: `solicitud_prestamo_docente.persona_codigo` -> `[dbo].[persona](per_codigo)`
- `FK_solicitud_prestamo_docente_sed_codigo`: `solicitud_prestamo_docente.sed_codigo` -> `[dbo].[sede](sed_codigo)`
- `FK_solicitud_prestamo_docente_uaa_dirigida`: `solicitud_prestamo_docente.uaa_dirigida` -> `[dbo].[uaa](uaa_codigo)`
- `FK_solicitud_prestamo_docente_uaa_solicita`: `solicitud_prestamo_docente.uaa_solicita` -> `[dbo].[uaa](uaa_codigo)`

---

### 2.11 Entidad: `programacionacademica.solicitud_prestamo_docente_comentario`

- **Submódulo Funcional:** Auditoría, Trazabilidad y Comentarios
- **Archivo Fuente DDL:** `sql/programacionacademica/solicitud_prestamo_docente_comentario.sql`
- **Descripción Funcional:** Registro cronológico de observaciones, acuerdos y conceptos cruzados entre directores de departamento y coordinadores en el trámite de préstamo docente.

#### Reglas de Negocio y Validación Operativa
- Cada nota queda enlazada obligatoriamente a una solicitud de préstamo docente.
- Se registra la autoría institucional mediante el identificador de usuario radicador.
- Los mensajes no son editables una vez emitidos.

#### Ciclo de Vida y Máquina de Estados
Histórico secuencial permanente: `spdc_estado = 1` (visible/activo), `0` (oculto).

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `spdc_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Identificador único del comentario de préstamo docente. |
| 2 | `spd_codigo` | `int` | - | NO | - | **FK** | Clave foránea a la solicitud de préstamo docente (`solicitud_prestamo_docente`). |
| 3 | `spdc_estado` | `tinyint` | - | NO | - | **Estado** | Estado de visualización del comentario (1: Activo, 0: Inactivo). |
| 4 | `usu_codigo` | `int` | - | NO | - | **FK Implícita** | Clave foránea implícita hacia el usuario emisor (`dbo.usuario_general.uid`). |
| 5 | `spdc_fecha_creacion` | `datetime` | - | NO | - | **Auditoría** | Fecha y hora exacta de registro de la nota. |
| 6 | `spdc_mensaje` | `varchar` | max | SÍ | - | **-** | Texto de la justificación, observación o contrapropuesta. |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_spd_solicitud_prestamo_docente_comentario` (NONCLUSTERED) sobre `([spdc_codigo] ASC)`

#### Restricciones de Integridad Referencial
**Claves Foráneas Explícitas (DDL):**
- `FK_solicitud_prestamo_docente_comentario_solicitud`: `solicitud_prestamo_docente_comentario.spd_codigo` -> `[programacionacademica].[solicitud_prestamo_docente](spd_codigo)`
- **Claves Foráneas Implícitas:** `usu_codigo` -> `[dbo].[usuario_general].[uid]` (Autor del mensaje o acuerdo)

---

### 2.12 Entidad: `programacionacademica.solicitud_prestamo_docente_horario`

- **Submódulo Funcional:** Gestión de Solicitudes de Préstamo Docente
- **Archivo Fuente DDL:** `sql/programacionacademica/solicitud_prestamo_docente_horario.sql`
- **Descripción Funcional:** Detalle semanal de franjas horarias (día y hora) en que la unidad solicitante necesita la disponibilidad del docente prestado, permitiendo validar colisiones y topes horarios.

#### Reglas de Negocio y Validación Operativa
- Cada registro especifica un bloque semanal (`dia_codigo` y `hra_codigo`) requerido.
- El sistema verifica contra la agenda del docente y contra `proyectos` si existe cruce horario antes de autorizar el préstamo.
- Una solicitud puede componerse de múltiples bloques semanales según la intensidad de la asignatura.

#### Ciclo de Vida y Máquina de Estados
Estado de la franja horaria: `1` = Activa / Vigente en la solicitud, `0` = Eliminada.

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `spdh_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Identificador único de la franja horaria requerida para el préstamo. |
| 2 | `spd_codigo` | `int` | - | NO | - | **FK** | Clave foránea a la solicitud de préstamo cabecera (`solicitud_prestamo_docente`). |
| 3 | `dia_codigo` | `int` | - | NO | - | **FK** | Clave foránea al día de la semana (`dbo.dia.dia_codigo`). |
| 4 | `hra_codigo` | `int` | - | NO | - | **FK** | Clave foránea al bloque horario solicitado (`dbo.hora.hra_codigo`). |
| 5 | `spdh_estado` | `tinyint` | - | NO | - | **Estado** | Estado de la franja horaria (1: Activa, 0: Inactiva). |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_spd_solicitud_prestamo_docente_horario` (NONCLUSTERED) sobre `([spdh_codigo] ASC)`

#### Restricciones de Integridad Referencial
**Claves Foráneas Explícitas (DDL):**
- `FK_solicitud_prestamo_docente_horario_dia`: `solicitud_prestamo_docente_horario.dia_codigo` -> `[dbo].[dia](dia_codigo)`
- `FK_solicitud_prestamo_docente_horario_hora`: `solicitud_prestamo_docente_horario.hra_codigo` -> `[dbo].[hora](hra_codigo)`
- `FK_solicitud_prestamo_docente_horario_solicitud`: `solicitud_prestamo_docente_horario.spd_codigo` -> `[programacionacademica].[solicitud_prestamo_docente](spd_codigo)`

---
