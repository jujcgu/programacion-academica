# 07 - Diccionario de Datos: Oferta Académica y Cursos

## Dominio de Oferta Curricular, Planes de Estudio, Asignaturas y Matrículas

---

## 1. Resumen Ejecutivo del Dominio

El dominio de **Oferta Académica y Cursos** modela la dimensión curricular e instruccional de la universidad. Alberga la estructura formal del pensum, las asignaturas maestras, las aperturas semestrales de cursos, el control de cupos y subgrupos, y la formalización de matrículas de estudiantes:

1. **Estructura Curricular y Malla Académica:** Programas académicos (`programa`), planes de estudio (`plan_academico`), mallas semestrales (`plan_academico_asignatura`), catálogo de asignaturas (`asignatura`), núcleos de conocimiento (`nucleo`), prelaciones (`prerrequisito`) y equivalencias (`equivalencia`).
2. **Oferta Semestral y Gestión de Aulas:** Creación y oferta de cursos semestrales (`curso`), vinculación con planes (`curso_plan`), partición en subgrupos de prácticas (`curso_cupo_subgrupo`), ejecuciones territoriales (`curso_institucion_ejecucion`) y autorizaciones extraordinarias de sobrecupo (`cupo_autorizacion`).
3. **Padrón Estudiantil y Matrícula:** Padrón estudiantil (`estudiante`), planes asignados (`plan_estudiante`), matrículas semestrales (`matricula`), autorizaciones excepcionales (`matricula_autorizacion`) y reglas de matrícula por créditos (`matricula_configuracion`, `matricula_configuracion_detalle`).

### Métricas Consolidadas del Dominio

| Métrica Arquitectónica | Valor | Descripción Técnica |
| :--- | :---: | :--- |
| **Total de Entidades Físicas** | **25** | 23 en `sql/dbo/*.sql` y 2 tablas físicas en `sql/dbo/vistas/*.sql` (`estudiante`, `espacio_tipo`) |
| **Total de Claves Primarias (PK)** | **25** | 24 PKs subrogadas/simples + 1 PK compuesta tridimensional en `programa` |
| **Claves Foráneas Explícitas (DDL)** | **28** | Restricciones formales codificadas en scripts DDL |
| **Claves Foráneas Implícitas (Convención)** | **42** | Relaciones lógicas por convención de nombres y claves foráneas en código |
| **Tablas Externas de Apoyo** | **5** | `nivel_academico_creditos`, `matricula_tipo`, `campo_detallado`, `sede`, `usuario_general` |

---

## 2. Catálogo Técnico y Diccionario de Entidades

### 2.1 Entidad: `dbo.curso`

- **Submódulo Funcional:** Planificación y Oferta Semestral
- **Archivo Fuente DDL:** `sql/dbo/curso.sql`
- **Descripción Funcional:** Entidad nuclear de la oferta académica. Representa la apertura formal y concreta de una asignatura en un calendario académico, asignándole cupo máximo, docente responsable, sede de dictado y código de grupo o paralelo. Es el eje sobre el cual se programan los horarios, se reservan las aulas y se matriculan los estudiantes.

#### Reglas de Negocio y Validación Operativa
- Debe asociarse a una asignatura válida (`asi_codigo`) y a un calendario lectivo institucional (`cal_codigo`).
- La asignación de docente (`uap_codigo`) vincula el curso con la nómina en `dbo.uaa_personal` y descuenta horas lectivas semanales.
- El campo `cur_cupo` restringe la cantidad máxima de alumnos que pueden inscribir la materia a través de la interfaz de matrícula.
- Si `cur_cierre = 1`, el curso no admite modificaciones administrativas de notas ni sobrecupos extemporáneos.

#### Ciclo de Vida y Estados
Ciclo de vida operativo:
- *Programado*: Curso creado con cupo y docente asignado (`cur_estado = 1`, `cur_cierre = 0`).
- *En Ejecución*: Periodo de clases activo, captura de notas parciales habilitada (`cur_notaparcial`).
- *Cerrado*: Semestre culminado, actas de notas consolidadas y grabadas (`cur_cierre = 1`, `cur_grabado = 1`).
- *Inactivo / Cancelado*: `cur_estado = 0` (por falta de quórum de matrícula o reestructuración).

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `cur_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Clave primaria secuencial e identificador único del curso ofrecido. |
| 2 | `uap_codigo` | `int` | - | SÍ | - | **FK Explícita** | Clave foránea explícita a la vinculación del docente responsable (`dbo.uaa_personal`). |
| 3 | `asi_codigo` | `int` | - | SÍ | - | **FK Explícita** | Clave foránea explícita a la asignatura ofertada (`dbo.asignatura`). |
| 4 | `sed_codigo` | `int` | - | SÍ | - | **FK Implícita** | Clave foránea implícita a la sede física de dictado (`dbo.sede`). |
| 5 | `cal_codigo` | `int` | - | SÍ | - | **FK Implícita** | Clave foránea implícita al ciclo o calendario académico (`dbo.calendario`). |
| 6 | `cur_grupo` | `char` | 2 | SÍ | - | **FK Implícita** | Clave foránea implícita al grupo o paralelo académico (`dbo.grupo.gru_codigo`). |
| 7 | `cur_cupo` | `smallint` | - | SÍ | - | **-** | Capacidad máxima de estudiantes autorizados para matricularse. |
| 8 | `cur_estado` | `tinyint` | - | SÍ | - | **Estado** | Estado del curso (1: Activo, 0: Inactivo/Cancelado). |
| 9 | `tic_codigo` | `int` | - | SÍ | - | **FK Implícita** | Clave foránea implícita a la modalidad pedagógica (`dbo.tipo_curso`). |
| 10 | `cut_codigo` | `tinyint` | - | SÍ | - | **FK Implícita** | Clave foránea implícita a la clasificación tipológica (`dbo.curso_tipo`). |
| 11 | `pla_codigo` | `int` | - | SÍ | - | **FK Implícita** | Clave foránea implícita al plan de estudios base (`dbo.plan_academico`). |
| 12 | `cur_exclusivo` | `bit` | - | SÍ | - | **-** | Indicador booleano de exclusividad para estudiantes del plan base. |
| 13 | `cur_fecha_inicio` | `datetime` | - | SÍ | - | **Temporal** | Fecha oficial de inicio de impartición de clases. |
| 14 | `cur_semanas` | `tinyint` | - | SÍ | - | **-** | Número de semanas de duración lectiva del curso. |
| 15 | `cur_cierre` | `tinyint` | - | SÍ | - | **-** | Bandera de cierre definitivo de actas y notas (1: Cerrado, 0: Abierto). |
| 16 | `cur_grabado` | `tinyint` | - | SÍ | - | **-** | Indicador de consolidación y grabado de calificaciones definitivas. |
| 17 | `cdp_codigo` | `int` | - | SÍ | - | **-** | Código del departamento académico responsable de la oferta. |
| 18 | `usu_codigo` | `int` | - | SÍ | - | **-** | Usuario responsable de la creación o programación del curso. |
| 19 | `usu_clave` | `varchar` | 50 | SÍ | - | **-** | Clave o hash de validación de seguridad del curso. |
| 20 | `sippa_sedcodigo` | `char` | 2 | SÍ | - | **-** | Código de sede en el sistema legado institucional SIPPA. |
| 21 | `sippa_calcodigo` | `char` | 6 | SÍ | - | **-** | Código de calendario lectivo en SIPPA. |
| 22 | `sippa_progcodigo` | `char` | 4 | SÍ | - | **-** | Código de programa curricular en SIPPA. |
| 23 | `sippa_plancodigo` | `char` | 7 | SÍ | - | **-** | Código de plan de estudios en SIPPA. |
| 24 | `sippa_asicodigo` | `char` | 8 | SÍ | - | **-** | Código de materia o asignatura en SIPPA. |
| 25 | `sippa_grucodigo` | `char` | 2 | SÍ | - | **-** | Código de grupo en SIPPA. |
| 26 | `sippa_forma` | `char` | 15 | SÍ | - | **-** | Modalidad de impartición en el sistema legado. |
| 27 | `cur_codigo_anterior` | `int` | - | SÍ | - | **-** | Identificador del curso previo en caso de reapertura o clonación. |
| 28 | `cur_observaciones` | `varchar` | 200 | SÍ | - | **-** | Notas y observaciones administrativas o pedagógicas del curso. |
| 29 | `cur_ampliacion_cupo` | `int` | - | SÍ | - | **-** | Cantidad acumulada de cupos extraordinarios autorizados. |
| 30 | `cur_fecha_actualizacion` | `datetime` | - | SÍ | - | **Temporal** | Marca temporal de la última actualización del registro. |
| 31 | `cur_notaparcial` | `varchar` | 1 | SÍ | - | **-** | Control y parametrización del asentamiento de evaluaciones parciales. |
| 32 | `tes_codigo` | `int` | - | SÍ | - | **FK Implícita** | Clave foránea implícita a la escala de calificación aplicable (`dbo.tipo_escala`). |
| 33 | `cur_url` | `varchar` | 100 | SÍ | - | **-** | Enlace al aula virtual o recurso educativo digital (LMS). |
| 34 | `cur_id_evento` | `varchar` | 30 | SÍ | - | **-** | Identificador de sincronización con sistemas de eventos de calendario. |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_curso_1` (CLUSTERED) sobre `([cur_codigo] ASC)`

#### Restricciones de Integridad Referencial
**Claves Foráneas Explícitas (DDL):**
- `FK_curso_asignatura`: `curso.asi_codigo` -> `[dbo].[asignatura](asi_codigo)`
- `FK_curso_uaa_personal`: `curso.uap_codigo` -> `[dbo].[uaa_personal](uap_codigo)`

---

### 2.2 Entidad: `dbo.curso_plan`

- **Submódulo Funcional:** Planificación y Oferta Semestral
- **Archivo Fuente DDL:** `sql/dbo/curso_plan.sql`
- **Descripción Funcional:** Tabla asociativa que vincula un curso con múltiples planes de estudio cuando una materia se ofrece de forma compartida entre varios programas académicos.

#### Reglas de Negocio y Validación Operativa
- Permite optimizar recursos docentes compartiendo un mismo curso entre distintas carreras afines.
- Cada registro asocia un curso (`cur_codigo`) con un plan de estudios participante (`pla_codigo`).
- Los cupos del curso pueden reservarse o compartirse según las reglas del plan.

#### Ciclo de Vida y Estados
Estado: `1` = Vinculación activa, `0` = Vinculación suspendida.

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `cup_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Identificador único de la asociación curso-plan. |
| 2 | `cur_codigo` | `int` | - | SÍ | - | **FK Explícita** | Clave foránea explícita al curso ofertado (`dbo.curso`). |
| 3 | `pla_codigo` | `int` | - | SÍ | - | **FK Implícita** | Clave foránea implícita al plan de estudios participante (`dbo.plan_academico`). |
| 4 | `sippa_plancodigo` | `char` | 7 | SÍ | - | **-** | Identificador o código de integración con el sistema externo legacy SIPPA para la asociación curricular del plan de estudios con el curso ofertado. |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_curso_plan_1` (CLUSTERED) sobre `([cup_codigo] ASC)`

#### Restricciones de Integridad Referencial
**Claves Foráneas Explícitas (DDL):**
- `FK_curso_plan_curso`: `curso_plan.cur_codigo` -> `[dbo].[curso](cur_codigo)`

---

### 2.3 Entidad: `dbo.curso_cupo_subgrupo`

- **Submódulo Funcional:** Planificación y Oferta Semestral
- **Archivo Fuente DDL:** `sql/dbo/curso_cupo_subgrupo.sql`
- **Descripción Funcional:** Permite segmentar y particionar el cupo total de un curso en subgrupos para sesiones de laboratorio, prácticas clínicas o talleres especializados.

#### Reglas de Negocio y Validación Operativa
- La sumatoria de los cupos de los subgrupos no debe exceder el cupo general del curso salvo autorización excepcional.
- Cada subgrupo se identifica mediante una letra o código alfanumérico (ej. 'A', 'B', '01').
- Es referenciado de forma implícita por `solicitud_cambio_horario_horario.schh_subgrupo` para cambios de franja en laboratorios.

#### Ciclo de Vida y Estados
Vigencia: `cus_estado = 1` (Subgrupo activo para matrícula y programación).

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `cus_cod` | `int` | - | NO | IDENTITY(1,1) | **PK** | Identificador único de la partición de cupo por subgrupo. |
| 2 | `cur_codigo` | `int` | - | SÍ | - | **FK Implícita** | Clave foránea implícita al curso contenedor (`dbo.curso`). |
| 3 | `eso_subgrupo` | `varchar` | 2 | SÍ | - | **-** | Identificador o nomenclatura del subgrupo práctico/laboratorio (ej. 'A', 'B', '01') al cual se asigna la capacidad o cupo diferenciado. |
| 4 | `cus_cupo` | `int` | - | SÍ | - | **-** | Número de cupos habilitados específicamente para este subgrupo. |
| 5 | `cus_estado` | `int` | - | SÍ | - | **Estado** | Estado operativo del subgrupo (1: Activo, 0: Inactivo). |
| 6 | `cus_fecha_registro` | `datetime` | - | SÍ | - | **Temporal** | Marca temporal de auditoría que registra la fecha y hora exacta en la que se configuró o actualizó el cupo del subgrupo. |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_curso_cupo_subgrupo` (CLUSTERED) sobre `([cus_cod] ASC)`

#### Restricciones de Integridad Referencial
- **Claves Foráneas Explícitas:** Ninguna codificada en DDL.

---

### 2.4 Entidad: `dbo.curso_institucion_ejecucion`

- **Submódulo Funcional:** Planificación y Oferta Semestral
- **Archivo Fuente DDL:** `sql/dbo/curso_institucion_ejecucion.sql`
- **Descripción Funcional:** Registra la ejecución descentralizada y territorial de un curso en espacios físicos específicos y municipios determinados, especialmente para programas regionales y prácticas de campo.

#### Reglas de Negocio y Validación Operativa
- Vincula formalmente el curso con un espacio físico (`esp_codigo`) y un municipio (`mun_codigo`).
- Permite georreferenciar la ejecución de asignaturas extramuros o convenios regionales.

#### Ciclo de Vida y Estados
Estado: `cie_estado = 1` (Ejecución confirmada y activa).

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `cie_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Identificador único de la ejecución institucional del curso. |
| 2 | `cur_codigo` | `int` | - | SÍ | - | **FK Explícita** | Clave foránea explícita hacia el curso (`dbo.curso`). |
| 3 | `cie_subgrupo` | `char` | 2 | SÍ | - | **-** | Subgrupo específico de práctica que se ejecuta en la sede regional. |
| 4 | `esp_codigo` | `int` | - | SÍ | - | **FK Explícita** | Clave foránea explícita hacia el espacio físico o aula (`dbo.espacio`). |
| 5 | `mun_codigo` | `int` | - | SÍ | - | **FK Explícita** | Clave foránea explícita hacia el municipio geográfico (`dbo.municipio`). |
| 6 | `cie_estado` | `int` | - | SÍ | - | **Estado** | Estado del registro de ejecución. |
| 7 | `cie_uid_inserta` | `int` | - | SÍ | - | **-** | Identificador del usuario que radicó la ejecución. |
| 8 | `cie_fecha_inserta` | `datetime` | - | SÍ | - | **Temporal** | Fecha y hora de inserción del registro. |
| 9 | `cie_uid_modifica` | `int` | - | SÍ | - | **-** | Identificador del usuario que realizó la última modificación. |
| 10 | `cie_fecha_modifica` | `datetime` | - | SÍ | - | **Temporal** | Fecha y hora de la última modificación. |

#### Índices y Claves Primarias
- **Clave Primaria:** Primaria sobre `([cie_codigo] ASC)`

#### Restricciones de Integridad Referencial
**Claves Foráneas Explícitas (DDL):**
- `Anonymous`: `curso_institucion_ejecucion.cur_codigo` -> `[dbo].[curso](cur_codigo)`
- `FK__curso_ins__esp_c__44EEF70B`: `curso_institucion_ejecucion.esp_codigo` -> `[dbo].[espacio](esp_codigo)`
- `Anonymous`: `curso_institucion_ejecucion.mun_codigo` -> `[dbo].[municipio](mun_codigo)`

---

### 2.5 Entidad: `dbo.curso_tipo`

- **Submódulo Funcional:** Catálogos de Oferta Curricular
- **Archivo Fuente DDL:** `sql/dbo/curso_tipo.sql`
- **Descripción Funcional:** Catálogo clasificador de los tipos de cursos académicos ofrecidos (ej. Regular, Tutorial, Dirigido, Vacacional).

#### Reglas de Negocio y Validación Operativa
- Define la modalidad administrativa del curso.
- Los cursos de tipo vacacional o tutorial pueden tener reglas diferenciadas de matrícula y liquidación pecuniaria.

#### Ciclo de Vida y Estados
Catálogo estático: `cut_estado = 1` (Activo).

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `cut_codigo` | `tinyint` | - | NO | IDENTITY(1,1) | **PK** | Identificador del tipo de curso. |
| 2 | `cut_nombre` | `char` | 20 | SÍ | - | **-** | Denominación (Regular, Intensivo, Tutorial, Dirigido). |
| 3 | `cut_estado` | `int` | - | SÍ | - | **Estado** | Estado activo o inactivo del clasificador. |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_curso_tipo` (CLUSTERED) sobre `([cut_codigo] ASC)`

#### Restricciones de Integridad Referencial
- **Claves Foráneas Explícitas:** Ninguna codificada en DDL.

---

### 2.6 Entidad: `dbo.tipo_curso`

- **Submódulo Funcional:** Catálogos de Oferta Curricular
- **Archivo Fuente DDL:** `sql/dbo/tipo_curso.sql`
- **Descripción Funcional:** Clasificador pedagógico de la naturaleza de impartición de las asignaturas (Teórico, Práctico, Teórico-Práctico).

#### Reglas de Negocio y Validación Operativa
- Determina el tipo de espacio físico requerido (aula magistral vs laboratorio).
- Influye en la fórmula de liquidación horaria y exigencia de subgrupos prácticos.

#### Ciclo de Vida y Estados
Catálogo estático: `tic_estado = 1`.

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `tic_codigo` | `int` | - | NO | - | **PK** | Identificador único del tipo pedagógico de curso. |
| 2 | `tic_nombre` | `varchar` | 50 | SÍ | - | **-** | Denominación (Teórico, Práctico, Mixto). |
| 3 | `tic_nombre_corto` | `varchar` | 20 | SÍ | - | **-** | Abreviatura nemotécnica o sigla corta oficial del tipo de curso (ej. 'TEO', 'PRA', 'TEOPRA') para interfaces y reportes académicos compactos. |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_tipo_curso` (CLUSTERED) sobre `([tic_codigo] ASC)`

#### Restricciones de Integridad Referencial
- **Claves Foráneas Explícitas:** Ninguna codificada en DDL.

---

### 2.7 Entidad: `dbo.tipo_escala`

- **Submódulo Funcional:** Catálogos de Oferta Curricular
- **Archivo Fuente DDL:** `sql/dbo/tipo_escala.sql`
- **Descripción Funcional:** Catálogo de escalas de calificación utilizadas para asentar notas (ej. Escala Numérica 0.0 a 5.0, Escala Cualitativa Aprobado/Reprobado).

#### Reglas de Negocio y Validación Operativa
- Regula el rango y formato de calificaciones admisibles en las actas de curso.
- La escala estándar en pregrado oscila de 0.0 a 5.0 con nota mínima aprobatoria 3.0.

#### Ciclo de Vida y Estados
Catálogo estático: `tes_estado = 1`.

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `tes_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Identificador de la escala evaluativa. |
| 2 | `tes_nombre` | `varchar` | 255 | SÍ | - | **-** | Denominación de la escala de evaluación. |
| 3 | `tes_estado` | `varchar` | 1 | SÍ | - | **Estado** | Estado de vigencia del clasificador. |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_tipo_escala` (CLUSTERED) sobre `([tes_codigo] ASC)`

#### Restricciones de Integridad Referencial
- **Claves Foráneas Explícitas:** Ninguna codificada en DDL.

---

### 2.8 Entidad: `dbo.cupo_autorizacion`

- **Submódulo Funcional:** Gestión de Cupos y Excepciones
- **Archivo Fuente DDL:** `sql/dbo/cupo_autorizacion.sql`
- **Descripción Funcional:** Registro formal de autorizaciones extraordinarias para ampliación de cupos sobre cursos cuya capacidad inicial se encuentre colmada.

#### Reglas de Negocio y Validación Operativa
- Debe ser avalado por el director de departamento o decanatura.
- Al aprobarse (`cua_estado = 1`), incrementa el contador `cur_ampliacion_cupo` en la tabla `dbo.curso`.
- Verifica que el aforo físico del aula asignada en `dbo.espacio` soporte el nuevo sobrecupo.

#### Ciclo de Vida y Estados
Estados: `1` = Aprobado y aplicado, `0` = Pendiente / Negado.

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `cua_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Identificador único de la autorización de ampliación de cupo. |
| 2 | `cua_curso` | `int` | - | NO | - | **FK Explícita** | Clave foránea explícita hacia el curso beneficiario (`dbo.curso.cur_codigo`). |
| 3 | `cua_grupo` | `varchar` | 2 | NO | - | **-** | Identificador alfanumérico del grupo del curso para el cual la autoridad académica concede la autorización excepcional de sobrecupo. |
| 4 | `cua_subgrupo` | `varchar` | 2 | NO | - | **-** | Subgrupo específico si la ampliación es exclusiva de una sección práctica. |
| 5 | `cua_estudiante` | `char` | 11 | NO | - | **-** | Código del estudiante (est_codigo) beneficiario de la autorización de cupo especial para inscripción en el curso. |
| 6 | `cua_observacion` | `varchar` | max | SÍ | - | **-** | Justificación académica, motivo de excepción o número de oficio administrativo que respalda el otorgamiento del sobrecupo al alumno. |
| 7 | `cua_fecha` | `datetime` | - | SÍ | - | **Temporal** | Fecha y hora de emisión del acto de autorización. |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_cupo_autorizacion` (CLUSTERED) sobre `([cua_codigo] ASC)`

#### Restricciones de Integridad Referencial
**Claves Foráneas Explícitas (DDL):**
- `FK_cupo_autorizacion_curso`: `cupo_autorizacion.cua_curso` -> `[dbo].[curso](cur_codigo)`

---

### 2.9 Entidad: `dbo.asignatura`

- **Submódulo Funcional:** Estructura Curricular y Malla Académica
- **Archivo Fuente DDL:** `sql/dbo/asignatura.sql`
- **Descripción Funcional:** Catálogo maestro de asignaturas de la institución. Modela las materias con su denominación, créditos académicos totales, créditos teóricos y prácticos, horas presenciales e independientes, y departamento académico responsable.

#### Reglas de Negocio y Validación Operativa
- Una asignatura pertenece a una UAA responsable (`uaa_codigo`) que administra su contenido programático.
- La sumatoria de `asi_creditos_teoria` y `asi_creditos_practica` compone los créditos totales de la materia.
- Define la formalidad (`for_codigo`), carácter (`car_codigo`) y núcleo de formación (`nuc_codigo`).

#### Ciclo de Vida y Estados
Vigencia: `asi_estado = 1` (Materia activa y disponible para ser ofertada en cursos).

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `asi_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Identificador numérico principal y clave primaria de la asignatura. |
| 2 | `asi_nombre` | `varchar` | 100 | SÍ | - | **-** | Nombre oficial y completo de la asignatura. |
| 3 | `asi_nombre_corto` | `varchar` | 11 | SÍ | - | **-** | Denominación abreviada para listados operativos. |
| 4 | `asi_nombre_impresion` | `varchar` | 12 | SÍ | - | **-** | Nombre formateado para certificados y actas de grado. |
| 5 | `uaa_codigo` | `int` | - | SÍ | - | **FK Explícita** | Clave foránea explícita a la UAA propietaria (`dbo.uaa`). |
| 6 | `asi_publicar` | `tinyint` | - | SÍ | - | **-** | Indicador de publicación web en catálogos públicos. |
| 7 | `asi_creditos` | `tinyint` | - | SÍ | - | **-** | Total de créditos académicos de la materia. |
| 8 | `asi_creditos_teoria` | `tinyint` | - | SÍ | - | **-** | Componente de créditos teóricos de la asignatura. |
| 9 | `asi_creditos_practica` | `tinyint` | - | SÍ | - | **-** | Componente de créditos prácticos de la asignatura. |
| 10 | `car_codigo` | `char` | 2 | NO | - | **FK Implícita** | Clave foránea implícita al carácter curricular (`dbo.caracter`). |
| 11 | `asi_trabajo_presencial` | `smallint` | - | SÍ | - | **-** | Horas presenciales semanales de clase con docente. |
| 12 | `asi_trabajo_independiente` | `smallint` | - | SÍ | - | **-** | Horas semanales requeridas de estudio autónomo. |
| 13 | `asi_estado` | `tinyint` | - | SÍ | - | **Estado** | Estado operativo de la materia (1: Activa, 0: Inactiva/Extinta). |
| 14 | `nuc_codigo` | `int` | - | SÍ | - | **FK Explícita** | Clave foránea explícita al núcleo de conocimiento (`dbo.nucleo`). |
| 15 | `asi_semanasxsemestre` | `smallint` | - | SÍ | - | **-** | Número estándar de semanas lectivas semestrales. |
| 16 | `nbc_codigo` | `int` | - | SÍ | - | **-** | Núcleo Básico de Conocimiento catalogado por el Ministerio de Educación. |
| 17 | `asi_extramuro` | `char` | 1 | SÍ | - | **-** | Indicador de dictado extramural o fuera de campus principal. |
| 18 | `sippa_asicodigo` | `char` | 8 | SÍ | - | **-** | Código legado de la asignatura en SIPPA. |
| 19 | `sippa_plancodigo` | `char` | 7 | SÍ | - | **-** | Código legado del plan de estudios en SIPPA. |
| 20 | `sippa_progcodigo` | `char` | 4 | SÍ | - | **-** | Código legado del programa académico en SIPPA. |
| 21 | `asi_pendiente_nbc` | `char` | 60 | SÍ | - | **-** | Registro de homologación pendiente ante clasificación NBC. |
| 22 | `asi_credito_migrado_paa` | `char` | 60 | SÍ | - | **-** | Bitácora técnica de migración de créditos curriculares. |
| 23 | `asi_fecha_actualizacion` | `datetime` | - | SÍ | - | **Temporal** | Fecha y hora de última modificación del catálogo. |
| 24 | `for_codigo` | `int` | - | NO | - | **FK Implícita** | Clave foránea implícita a la formalidad de dictado (`dbo.formalidad`). |
| 25 | `asi_trabajo_horas_teorico` | `int` | - | SÍ | - | **-** | Horas semanales teóricas. |
| 26 | `asi_trabajo_horas_practico` | `int` | - | SÍ | - | **-** | Horas semanales prácticas. |
| 27 | `asi_trabajo_horas_teorico_practico` | `int` | - | SÍ | - | **-** | Horas semanales teórico-prácticas. |
| 28 | `asi_trabajo_horas_semestral_teorico` | `int` | - | SÍ | - | **-** | Total horas teóricas en el semestre. |
| 29 | `asi_trabajo_horas_semestral_practico` | `int` | - | SÍ | - | **-** | Total horas prácticas en el semestre. |
| 30 | `asi_trabajo_horas_semestral_teorico_practico` | `int` | - | SÍ | - | **-** | Total horas combinadas semestrales. |
| 31 | `asi_trabajo_horas_semestral_independiente` | `int` | - | SÍ | - | **-** | Total horas de trabajo independiente en el semestre. |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_asignatura` (CLUSTERED) sobre `([asi_codigo] ASC)`

#### Restricciones de Integridad Referencial
**Claves Foráneas Explícitas (DDL):**
- `FK_asignatura_nucleo`: `asignatura.nuc_codigo` -> `[dbo].[nucleo](nuc_codigo)`
- `FK_asignatura_uaa`: `asignatura.uaa_codigo` -> `[dbo].[uaa](uaa_codigo)`

---

### 2.10 Entidad: `dbo.caracter`

- **Submódulo Funcional:** Catálogos de Oferta Curricular
- **Archivo Fuente DDL:** `sql/dbo/caracter.sql`
- **Descripción Funcional:** Clasificador curricular del carácter y naturaleza de la asignatura (ej. Obligatoria, Electiva, Optativa, Complementaria).

#### Reglas de Negocio y Validación Operativa
- Regula si la asignatura es exigible de forma estricta para graduarse o si puede sustituirse por otra electiva del mismo componente.

#### Ciclo de Vida y Estados
Catálogo estático: `car_estado = 1`.

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `car_codigo` | `char` | 2 | NO | - | **PK** | Código mnemotécnico del carácter (ej. 'OB', 'EL'). |
| 2 | `car_nombre` | `varchar` | 25 | SÍ | - | **-** | Denominación (Obligatoria, Electiva, Formación Integral). |
| 3 | `car_estado` | `varchar` | 1 | SÍ | - | **Estado** | Estado del clasificador. |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_caracter` (CLUSTERED) sobre `([car_codigo] ASC)`

#### Restricciones de Integridad Referencial
- **Claves Foráneas Explícitas:** Ninguna codificada en DDL.

---

### 2.11 Entidad: `dbo.formalidad`

- **Submódulo Funcional:** Catálogos de Oferta Curricular
- **Archivo Fuente DDL:** `sql/dbo/formalidad.sql`
- **Descripción Funcional:** Clasificador de la formalidad y metodología de impartición universitaria (Presencial, Virtual, A Distancia, Semipresencial).

#### Reglas de Negocio y Validación Operativa
- Determina si la programación del curso exige asignación de aula física en `dbo.espacio` o si opera de manera remota.

#### Ciclo de Vida y Estados
Catálogo estático: `for_estado = 1`.

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `for_codigo` | `tinyint` | - | NO | IDENTITY(1,1) | **PK** | Identificador único de formalidad. |
| 2 | `for_nombre` | `varchar` | 50 | SÍ | - | **-** | Denominación (Presencial, Virtual, Distancia). |
| 3 | `sippa_for_codigo` | `int` | - | SÍ | - | **-** | Código numérico de homologación de la formalidad académica (educación formal, no formal, continuada) en el sistema SIPPA. |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_formalidad` (CLUSTERED) sobre `([for_codigo] ASC)`

#### Restricciones de Integridad Referencial
- **Claves Foráneas Explícitas:** Ninguna codificada en DDL.

---

### 2.12 Entidad: `dbo.nucleo`

- **Submódulo Funcional:** Estructura Curricular y Malla Académica
- **Archivo Fuente DDL:** `sql/dbo/nucleo.sql`
- **Descripción Funcional:** Núcleos de fundamentación académica y componentes de formación que estructuran las áreas de conocimiento en los planes de estudio.

#### Reglas de Negocio y Validación Operativa
- Agrupa asignaturas afines dentro de un componente formativo (Básico, Profesional, Humanístico).

#### Ciclo de Vida y Estados
Catálogo maestro: `nuc_estado = 1`.

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `nuc_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Identificador único del núcleo temático. |
| 2 | `nuc_nombre` | `char` | 25 | SÍ | - | **-** | Denominación del núcleo de formación. |
| 3 | `nuc_estado` | `bit` | - | SÍ | - | **Estado** | Estado del núcleo de conocimiento. |
| 4 | `nuc_acronimo` | `char` | 1 | SÍ | - | **-** | Sigla o acrónimo representativo del núcleo temático o de formación institucional para categorización curricular y filtros en malla. |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_nucleo` (NONCLUSTERED) sobre `([nuc_codigo] ASC)`

#### Restricciones de Integridad Referencial
- **Claves Foráneas Explícitas:** Ninguna codificada en DDL.

---

### 2.13 Entidad: `dbo.equivalencia`

- **Submódulo Funcional:** Estructura Curricular y Malla Académica
- **Archivo Fuente DDL:** `sql/dbo/equivalencia.sql`
- **Descripción Funcional:** Matriz de equivalencias y homologaciones académicas directas entre materias de uno o varios planes de estudio.

#### Reglas de Negocio y Validación Operativa
- Establece que haber aprobado `equ_asignatura` convalida automáticamente la asignatura `asi_codigo` en el plan `pla_codigo`.
- Es consultada por el motor de matrícula y liquidación de egresados.

#### Ciclo de Vida y Estados
Vigencia: definida por acto administrativo de convalidación curricular.

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `equ_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Identificador único de la regla de equivalencia. |
| 2 | `pla_codigo` | `int` | - | SÍ | - | **FK Implícita** | Clave foránea implícita al plan de estudios (`dbo.plan_academico`). |
| 3 | `asi_codigo` | `int` | - | SÍ | - | **FK Implícita** | Clave foránea implícita a la asignatura requerida (`dbo.asignatura`). |
| 4 | `asi_equivalencia` | `int` | - | SÍ | - | **-** | Código de la asignatura alterna u homóloga (asi_codigo) que satisface y convalida curricularmente el contenido de la materia principal. |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_equivalencia` (CLUSTERED) sobre `([equ_codigo] ASC)`

#### Restricciones de Integridad Referencial
- **Claves Foráneas Explícitas:** Ninguna codificada en DDL.

---

### 2.14 Entidad: `dbo.prerrequisito`

- **Submódulo Funcional:** Estructura Curricular y Malla Académica
- **Archivo Fuente DDL:** `sql/dbo/prerrequisito.sql`
- **Descripción Funcional:** Define las prelaciones curriculares, requisitos previos y correquisitos académicos exigibles antes de inscribir una asignatura en un plan.

#### Reglas de Negocio y Validación Operativa
- Impide al estudiante inscribir una materia en la matrícula si no ha aprobado la asignatura previa (`pre_asignatura`) con calificación mínima `pre_nota`.
- Puede requerir un mínimo de créditos acumulados (`pre_creditos`) o nivel semestral (`pre_semestre`).
- `pre_tipo` diferencia entre Requisito previo ('R') y Correquisito simultáneo ('C').

#### Ciclo de Vida y Estados
Estado: `pre_estado = 1` (Regla activa y evaluada en el proceso de matrícula).

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `pre_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Identificador numérico de la restricción de prelación. |
| 2 | `pla_codigo` | `int` | - | SÍ | - | **FK Implícita** | Clave foránea implícita al plan de estudios contenedor (`dbo.plan_academico`). |
| 3 | `asi_codigo` | `int` | - | SÍ | - | **FK Implícita** | Clave foránea implícita a la materia condicionada (`dbo.asignatura`). |
| 4 | `asi_requisito` | `int` | - | SÍ | - | **-** | Código de la asignatura precedente (asi_codigo) exigida como prerrequisito académico aprobatorio para poder cursar la materia destino. |
| 5 | `pre_creditos` | `int` | - | SÍ | - | **-** | Total de créditos aprobados requeridos para desbloquear la materia. |
| 6 | `pre_codigos` | `varchar` | 20 | SÍ | - | **-** | Cadena o expresión lógica codificada que parametriza reglas compuestas de prerrequisitos (operadores AND/OR entre materias exigidas). |
| 7 | `sippa_plancodigo` | `char` | 7 | SÍ | - | **-** | Código del plan de estudios en el sistema externo SIPPA bajo el cual aplica la regla reglamentaria de prerrequisito. |
| 8 | `sippa_asicodigo` | `char` | 8 | SÍ | - | **-** | Código de la asignatura principal/objetivo en el sistema externo SIPPA para la validación de prerrequisito. |
| 9 | `sippa_preasignatura` | `char` | 8 | SÍ | - | **-** | Código de la asignatura prerrequisito en el sistema externo SIPPA con la que se valida el cumplimiento académico previo. |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_prerequisito` (NONCLUSTERED) sobre `([pre_codigo] ASC)`

#### Restricciones de Integridad Referencial
- **Claves Foráneas Explícitas:** Ninguna codificada en DDL.

---

### 2.15 Entidad: `dbo.plan_academico`

- **Submódulo Funcional:** Planes de Estudio y Programas Curriculares
- **Archivo Fuente DDL:** `sql/dbo/plan_academico.sql`
- **Descripción Funcional:** Representa la estructura formal de un plan de estudios o pensum curricular universitario, especificando resolución aprobatoria, vigencia y créditos.

#### Reglas de Negocio y Validación Operativa
- Pertenece a un programa académico (`pro_codigo`) y tipifica el nivel de créditos (`nac_codigo`).
- Totaliza los créditos requeridos para optar por el título profesional (`pla_creditos`).
- Controla la duración oficial de la carrera en semestres (`pla_semestres`).

#### Ciclo de Vida y Estados
Estados: `1` = Activo y vigente para nuevas cohortes, `0` = Inactivo o cerrado a nuevos ingresos (sólo para estudiantes rezagados).

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `pla_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Identificador único y clave primaria del plan de estudios. |
| 2 | `pla_nombre` | `char` | 10 | SÍ | - | **-** | Nombre formal o versión de la resolución del plan. |
| 3 | `pro_codigo` | `int` | - | NO | - | **FK Implícita** | Clave foránea implícita al programa académico (`dbo.programa`). |
| 4 | `nac_codigo` | `int` | - | SÍ | - | **FK Explícita** | Clave foránea explícita al catálogo de créditos (`dbo.nivel_academico_creditos`). |
| 5 | `pla_creditos` | `tinyint` | - | SÍ | - | **-** | Total de créditos académicos exigidos para graduación. |
| 6 | `pla_total_creditos` | `int` | - | SÍ | - | **-** | Total consolidado de créditos académicos que el estudiante debe cursar y aprobar para cumplir con la totalidad del pensum y optar al título. |
| 7 | `pla_requisito_grado` | `tinyint` | - | SÍ | - | **-** | Bandera booleana (1/0) que indica si el plan académico impone requisitos extracurriculares obligatorios de grado (ej. suficiencia de idioma extranjero o preparatorios). |
| 8 | `pla_antiguo` | `tinyint` | - | SÍ | - | **-** | Bandera booleana (1/0) que clasifica si el plan corresponde a un régimen curricular anterior o pensum en liquidación/extinción paulatina. |
| 9 | `pla_tipo_registro` | `varchar` | 50 | SÍ | - | **-** | Clasificación del tipo de registro oficial o estado de convalidación estatal del plan (ej. 'REGISTRO CALIFICADO', 'ALTA CALIDAD'). |
| 10 | `pla_estado` | `tinyint` | - | SÍ | - | **Estado** | Estado del plan (1: Activo, 0: En extinción/Inactivo). |
| 11 | `pla_fecha` | `datetime` | - | SÍ | - | **Temporal** | Fecha de expedición o promulgación oficial de la resolución institucional que sanciona y pone en vigencia el plan de estudios. |
| 12 | `res_codigo` | `int` | - | SÍ | - | **-** | Identificador de la resolución o acto administrativo del Consejo Académico o Superior que formaliza la creación o modificación del plan. |
| 13 | `pla_actual` | `tinyint` | - | SÍ | - | **-** | Indicador binario (1/0) de vigencia activa del plan; identifica si es la versión curricular oficial actualmente ofrecida a nuevos matriculados. |
| 14 | `snies_periodicidad` | `int` | - | SÍ | - | **-** | Código de periodicidad académica según el estándar nacional SNIES del MEN (ej. 1: Semestral, 2: Anual, 3: Cuatrimestral). |
| 15 | `snies_numero_periodos` | `int` | - | SÍ | - | **-** | Duración reglamentaria estándar del programa académico expresada en número de periodos académicos según registro calificado SNIES. |
| 16 | `sippa_placodigo` | `char` | 7 | SÍ | - | **-** | Código de homologación del plan de estudios en el sistema legacy SIPPA para procesos de migración y compatibilidad histórica. |
| 17 | `sippa_procodigo` | `char` | 4 | SÍ | - | **-** | Código del programa académico asociado al plan de estudios en la base de datos externa SIPPA. |
| 18 | `pla_total_horas` | `int` | - | SÍ | - | **-** | Suma global de horas de formación académica (incluyendo horas de docencia directa presencial y horas de trabajo autónomo independiente) del plan. |
| 19 | `fecha_creacion` | `datetime` | - | NO | - | **Temporal** | Marca temporal de auditoría que registra la fecha y hora de creación de la entidad del plan académico en el repositorio de datos. |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_plan_academico` (NONCLUSTERED) sobre `([pla_codigo] ASC)`

#### Restricciones de Integridad Referencial
**Claves Foráneas Explícitas (DDL):**
- `FK__plan_acad__nac_c__1BE45685`: `plan_academico.nac_codigo` -> `[dbo].[nivel_academico_creditos](nac_codigo)`

---

### 2.16 Entidad: `dbo.plan_academico_asignatura`

- **Submódulo Funcional:** Planes de Estudio y Programas Curriculares
- **Archivo Fuente DDL:** `sql/dbo/plan_academico_asignatura.sql`
- **Descripción Funcional:** Entidad central de la malla curricular. Ubica y articula cada asignatura dentro de un plan de estudios específico, asignándole el semestre sugerido, horas y créditos.

#### Reglas de Negocio y Validación Operativa
- Conecta un plan académico (`pla_codigo`) con una asignatura (`asi_codigo`).
- Define el semestre de ubicación de la materia (`paa_semestre` del 1 al 10).
- Distribuye las horas teóricas, prácticas, combinadas e independientes para el plan.

#### Ciclo de Vida y Estados
Vigencia: `paa_estado = 1` (Malla activa).

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `paa_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Identificador único de la casilla curricular en el plan. |
| 2 | `pla_codigo` | `int` | - | NO | - | **FK Explícita** | Clave foránea explícita al plan contenedor (`dbo.plan_academico`). |
| 3 | `asi_codigo` | `int` | - | NO | - | **FK Explícita** | Clave foránea explícita a la materia en la malla (`dbo.asignatura`). |
| 4 | `paa_area` | `char` | 10 | SÍ | - | **-** | Código o sigla del área formativa o campo de conocimiento al que pertenece la asignatura dentro de la estructura curricular del pensum. |
| 5 | `paa_subarea` | `char` | 10 | SÍ | - | **-** | Subárea temática o campo disciplinar específico dentro del área curricular principal a la que se adscribe la materia. |
| 6 | `paa_semestre` | `int` | - | SÍ | - | **-** | Nivel o semestre lectivo recomendado (1 a 10). |
| 7 | `paa_credito` | `int` | - | NO | - | **-** | Número de créditos académicos que confiere la asignatura al ser aprobada dentro del marco de este plan de estudios específico. |
| 8 | `paa_intensidad` | `int` | - | SÍ | - | **-** | Intensidad horaria semanal presencial de docencia directa prescrita reglamentariamente para impartir la asignatura. |
| 9 | `pet_codigo` | `int` | - | SÍ | - | **-** | Código de periodicidad o ciclo lectivo en el que se ubica la materia dentro del pensum (referencia a dbo.periodo_tipo). |
| 10 | `nuc_codigo` | `int` | - | SÍ | - | **FK Implícita** | Clave foránea implícita al núcleo temático (`dbo.nucleo`). |
| 11 | `com_codigo` | `int` | - | SÍ | - | **-** | Código del componente de formación curricular (básico de ciencias, profesionalizante, sociohumanístico o de profundización). |
| 12 | `paa_estado` | `char` | 10 | SÍ | - | **Estado** | Estado de la asignatura dentro del plan. |
| 13 | `paa_nota_minima` | `float` | - | NO | - | **-** | Calificación numérica mínima requerida para considerar aprobada la asignatura dentro del plan (típicamente 3.0 en escala de 0.0 a 5.0). |
| 14 | `paa_chequeo_requisito` | `tinyint` | - | SÍ | - | **-** | Bandera booleana (1/0) que activa o desactiva la verificación algorítmica obligatoria de prerrequisitos durante el proceso de matrícula web. |
| 15 | `paa_plan_academico` | `tinyint` | - | SÍ | - | **-** | Indicador de pertenencia jerárquica al pensum oficial obligatorio frente a opciones electivas libres del plan. |
| 16 | `paa_obligatoria` | `char` | 1 | SÍ | - | **-** | Carácter curricular reglamentario de la asignatura dentro del plan: 'S' (Obligatoria / Núcleo central) o 'N' (Electiva / Optativa). |
| 17 | `paa_programable` | `char` | 1 | SÍ | - | **-** | Indicador de aptitud operativa: 'S' si la asignatura puede ser ofertada en cursos en la programación académica semestral, 'N' si no. |
| 18 | `paa_multi_asignatura` | `char` | 1 | SÍ | - | **-** | Indicador booleano ('S'/'N') que permite o restringe que el curso programado agrupe concurrentemente múltiples códigos de asignaturas afines. |
| 19 | `paa_semanaxsemestre` | `int` | - | SÍ | - | **-** | Número de semanas efectivas de clase semestrales proyectadas para el dictado de la asignatura (típicamente 16 semanas en período regular). |
| 20 | `paa_h_trabajo_ind_sem` | `int` | - | SÍ | - | **-** | Horas estimadas de trabajo autónomo, estudio independiente y preparación que el estudiante debe dedicar semanalmente por cada crédito. |
| 21 | `sippa_plancodigo` | `char` | 7 | SÍ | - | **-** | Código de plan en sistema SIPPA. |
| 22 | `sippa_asicodigo` | `char` | 8 | SÍ | - | **-** | Código de asignatura en sistema SIPPA. |
| 23 | `sippa_progcodigo` | `char` | 4 | SÍ | - | **-** | Código de programa en sistema SIPPA. |
| 24 | `for_codigo` | `int` | - | NO | - | **FK Implícita** | Clave foránea implícita a la formalidad (`dbo.formalidad`). |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_plan_academico_asignatura` (CLUSTERED) sobre `([paa_codigo] ASC)`

#### Restricciones de Integridad Referencial
**Claves Foráneas Explícitas (DDL):**
- `FK_plan_academico_asignatura_asignatura_agosto2018`: `plan_academico_asignatura.asi_codigo` -> `[dbo].[asignatura](asi_codigo)`
- `FK_plan_academico_asignatura_plan_academico`: `plan_academico_asignatura.pla_codigo` -> `[dbo].[plan_academico](pla_codigo)`

---

### 2.17 Entidad: `dbo.plan_estudiante`

- **Submódulo Funcional:** Planes de Estudio y Matrícula
- **Archivo Fuente DDL:** `sql/dbo/plan_estudiante.sql`
- **Descripción Funcional:** Asigna formalmente la versión activa de un plan de estudios a un estudiante individual, controlando su avance semestral y promedio acumulado.

#### Reglas de Negocio y Validación Operativa
- Un estudiante sólo puede tener un plan de estudios activo simultáneamente en el mismo programa.
- Alberga el contador acumulado de créditos aprobados (`ple_creditos_aprobados`) y el promedio de carrera (`ple_promedio`).

#### Ciclo de Vida y Estados
Estados: `1` = Plan activo, `0` = Inactivo / Graduado / Trasladado.

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `ple_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Identificador único de la asignación plan-estudiante. |
| 2 | `est_codigo` | `char` | 11 | SÍ | - | **FK Explícita** | Clave foránea explícita al estudiante (`dbo.estudiante`). |
| 3 | `pla_codigo` | `int` | - | SÍ | - | **FK Explícita** | Clave foránea explícita al plan que cursa (`dbo.plan_academico`). |
| 4 | `ple_estado` | `bit` | - | SÍ | - | **Estado** | Estado de la asignación (1: Activo, 0: Finalizado/Retirado). |
| 5 | `res_codigo` | `int` | - | SÍ | - | **-** | Identificador de la resolución del Consejo de Facultad o instancia competente que autorizó la adscripción o cambio de pensum del alumno. |
| 6 | `ple_observacion` | `varchar` | 200 | SÍ | - | **-** | Notas circunstanciadas, antecedentes de homologación, transferencias o excepciones sobre la vinculación del estudiante a este plan. |
| 7 | `sippa_placodigo` | `char` | 7 | SÍ | - | **-** | Código del plan de estudios en la base de datos externa SIPPA asociado al historial del estudiante. |
| 8 | `sippa_procodigo` | `char` | 4 | SÍ | - | **-** | Código del programa académico del estudiante registrado en el sistema legacy SIPPA. |
| 9 | `ple_fecha_registro` | `datetime` | - | SÍ | - | **Temporal** | Marca temporal de auditoría en la que se radicó la inscripción formal del estudiante en la versión del plan académico. |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_plan_estudiante` (CLUSTERED) sobre `([ple_codigo] ASC)`

#### Restricciones de Integridad Referencial
**Claves Foráneas Explícitas (DDL):**
- `FK_plan_estudiante_estudiante`: `plan_estudiante.est_codigo` -> `[dbo].[estudiante](est_codigo)`
- `FK_plan_estudiante_plan_academico`: `plan_estudiante.pla_codigo` -> `[dbo].[plan_academico](pla_codigo)`

---

### 2.18 Entidad: `dbo.programa`

- **Submódulo Funcional:** Planes de Estudio y Programas Curriculares
- **Archivo Fuente DDL:** `sql/dbo/programa.sql`
- **Descripción Funcional:** Representa la carrera académica formal universitaria (ej. Ingeniería de Sistemas, Medicina, Derecho). Cuenta con clave primaria compuesta que permite ofertar la carrera en distintas sedes regionales bajo distintas facultades.

#### Reglas de Negocio y Validación Operativa
- Clave primaria compuesta por `(pro_codigo, uaa_codigo, sed_codigo)`.
- Posee relación foránea externa con `[acreditacion].[campo_detallado]` (`cam_det_codigo`).
- Agrupa los planes de estudio y define el nivel académico (`dbo.nivel_academico`).

#### Ciclo de Vida y Estados
Estado: `pro_estado = 1` (Programa activo con registro calificado vigente).

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `pro_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Parte de la PK: Código numérico del programa académico. |
| 2 | `pro_programa` | `char` | 4 | SÍ | - | **-** | Código corto alfanumérico o sigla nemotécnica interna del programa curricular (ej. 'IS', 'ADM', 'DER'). |
| 3 | `sed_codigo` | `int` | - | NO | - | **PK** | Parte de la PK: Sede geográfica donde se imparte (`dbo.sede`). |
| 4 | `uaa_codigo` | `int` | - | NO | - | **PK** | Parte de la PK: Facultad o unidad académica adscrita (`dbo.uaa`). |
| 5 | `uaa_codigo_unificado` | `int` | - | SÍ | - | **-** | Código de la Unidad Académico-Administrativa unificada a la que se asocian las estadísticas consolidadas y gestión del programa. |
| 6 | `nia_codigo` | `int` | - | SÍ | - | **FK Explícita** | Clave foránea explícita al nivel de formación (`dbo.nivel_academico`). |
| 7 | `pro_registro_icfes` | `varchar` | 50 | SÍ | - | **-** | Código oficial de registro SNIES / ICFES ante el MEN. |
| 8 | `pro_registro_snies` | `varchar` | 50 | SÍ | - | **-** | Código oficial único asignado por el Ministerio de Educación Nacional en el Sistema Nacional de Información de la Educación Superior (SNIES). |
| 9 | `pro_extension_snies` | `char` | 1 | SÍ | - | **-** | Código de extensión o radicado complementario SNIES para programas impartidos en sedes o subsedes regionales diferenciadas. |
| 10 | `jor_codigo` | `int` | - | SÍ | - | **-** | Código de la jornada académica autorizada en el registro del programa (ej. Diurna, Nocturna, Vespertina, Mixta). |
| 11 | `res_codigo` | `int` | - | SÍ | - | **-** | Código de la resolución administrativa ministerial que otorga o renueva el Registro Calificado vigente del programa académico. |
| 12 | `pro_titulo_otorgado` | `varchar` | 100 | SÍ | - | **-** | Denominación literal del título universitario oficial que la institución confiere al graduado (ej. 'Ingeniero de Sistemas', 'Médico Cirujano'). |
| 13 | `pro_fecha_creacion` | `datetime` | - | SÍ | - | **Temporal** | Fecha de acto administrativo de creación institucional. |
| 14 | `mod_codigo` | `tinyint` | - | SÍ | - | **-** | Código de modalidad formativa autorizada para el programa curricular (ej. Presencial, A Distancia tradicional, Virtual, Dual). |
| 15 | `con_codigo` | `int` | - | SÍ | - | **-** | Código de convenio marco o específico bajo el cual opera el programa (cuando es interinstitucional o en alianza académica). |
| 16 | `pro_horario` | `varchar` | 100 | SÍ | - | **-** | Descripción funcional o régimen habitual de franjas horarias y días en que se programan las actividades curriculares del programa. |
| 17 | `pro_estado` | `char` | 2 | SÍ | - | **Estado** | Estado operativo del programa académico. |
| 18 | `pro_propio` | `char` | 1 | SÍ | - | **-** | Carácter de titularidad: 'S' si el programa fue creado y es operado con recursos propios, 'N' si opera en convenio o extensión. |
| 19 | `uaa_programa_gen` | `int` | - | SÍ | - | **-** | Código de la UAA matriz o unidad académica generadora del programa que ejerce la coordinación académica superior. |
| 20 | `par_codigo` | `int` | - | SÍ | - | **-** | Código de periodicidad académica formal del programa según la estructura de semestralización institucional. |
| 21 | `nbc_codigo` | `int` | - | SÍ | - | **-** | Código del Núcleo Básico de Conocimiento (NBC) asignado oficialmente al programa por el MEN y el SNIES. |
| 22 | `pro_calendario` | `char` | 1 | SÍ | - | **-** | Régimen de calendario académico bajo el cual opera el programa institucionalmente (ej. 'A', 'B' o calendario semestral continuo). |
| 23 | `sippa_pro_codigo` | `char` | 4 | SÍ | - | **-** | Código de integración del programa académico en el sistema legacy externo SIPPA. |
| 24 | `pro_descripcion` | `varchar` | max | SÍ | - | **-** | Resumen descriptivo del perfil profesional, campo de acción y justificación disciplinar del programa académico. |
| 25 | `pro_creacion_snies` | `date` | - | SÍ | - | **-** | Fecha oficial de expedición o registro original del programa académico ante la plataforma SNIES del MEN. |
| 26 | `cam_det_codigo` | `int` | - | SÍ | - | **FK Explícita** | Clave foránea externa a `[acreditacion].[campo_detallado]`. |
| 27 | `pro_propedeutico` | `int` | - | SÍ | - | **-** | Indicador binario (1/0) que establece si el programa hace parte de una cadena de formación por ciclos propedéuticos articulados. |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_programa` (CLUSTERED) sobre `([pro_codigo] ASC,
	[uaa_codigo] ASC,
	[sed_codigo] ASC)`

#### Restricciones de Integridad Referencial
**Claves Foráneas Explícitas (DDL):**
- `FK_programa_nivel_academico`: `programa.nia_codigo` -> `[dbo].[nivel_academico](nia_codigo)`
- `FK_programa_sede`: `programa.sed_codigo` -> `[dbo].[sede](sed_codigo)`
- `FK_programa_uaa_agosto2018`: `programa.uaa_codigo` -> `[dbo].[uaa](uaa_codigo)`
- `programa_cam_detFK`: `programa.cam_det_codigo` -> `[acreditacion].[campo_detallado](cam_det_codigo)`

---

### 2.19 Entidad: `dbo.nivel_academico`

- **Submódulo Funcional:** Catálogos de Oferta Curricular
- **Archivo Fuente DDL:** `sql/dbo/nivel_academico.sql`
- **Descripción Funcional:** Catálogo clasificador del nivel educativo formal impartido en la universidad (Pregrado Técnico, Tecnológico, Profesional, Especialización, Maestría, Doctorado).

#### Reglas de Negocio y Validación Operativa
- Referenciado por `dbo.programa` para fijar el nivel de titulación.
- Posee relación con el maestro externo `dbo.nivel_academico_tipo` (`nat_codigo`).

#### Ciclo de Vida y Estados
Catálogo institucional permanente: `nia_estado = 1`.

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `nia_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Identificador único del nivel académico. |
| 2 | `nia_nombre` | `varchar` | 50 | SÍ | - | **-** | Denominación (Pregrado, Especialización, Maestría, Doctorado). |
| 3 | `nia_orden` | `tinyint` | - | SÍ | - | **-** | Orden de jerarquía en listados oficiales. |
| 4 | `for_codigo` | `tinyint` | - | SÍ | - | **FK Implícita** | Clave foránea implícita a la formalidad (`dbo.formalidad`). |
| 5 | `snies_codigo` | `char` | 2 | SÍ | - | **-** | Código de nivel de formación homologado según el catálogo maestro del SNIES del Ministerio de Educación Nacional. |
| 6 | `sippa_nia_codigo` | `int` | - | SÍ | - | **-** | Identificador numérico del nivel académico utilizado en las tablas del sistema legacy SIPPA. |
| 7 | `sippa_nivcodigo` | `char` | 3 | SÍ | - | **-** | Código alfanumérico corto o nemotécnico de 3 caracteres del nivel académico en SIPPA. |
| 8 | `nia_codigo_mp_hecaa` | `int` | - | SÍ | - | **-** | Código de Metodología de Programa establecido en el sistema HECAA (Herramienta de Captura de Información de Educación Superior). |
| 9 | `nia_codigo_ned_hecaa` | `int` | - | SÍ | - | **-** | Código de Nivel Educativo / Nivel de Formación estándar exigido en reportes estadísticos ante el sistema HECAA. |
| 10 | `nia_codigo_ne_hecaa` | `int` | - | SÍ | - | **-** | Código de Nivel de Escolaridad asignado para la clasificación de títulos y docentes en la plataforma ministerial HECAA. |
| 11 | `nat_codigo` | `int` | - | SÍ | - | **FK Explícita** | Clave foránea explícita a `dbo.nivel_academico_tipo`. |
| 12 | `nia_cap_puntos` | `int` | - | SÍ | - | **-** | Puntos salariales de capacitación base o escalafonaria conferidos a los docentes por títulos acreditados en este nivel formativo. |
| 13 | `nia_cap_puntos_adicionales` | `int` | - | SÍ | - | **-** | Puntaje salarial adicional o bonificado reconocido en la carrera profesoral por títulos complementarios en este nivel. |
| 14 | `nia_cap_maximo` | `int` | MAX | SÍ | - | **-** | Techo o límite máximo reglamentario de puntos salariales reconocibles a un docente por capacitación en este nivel. |
| 15 | `nia_cap_puntos_xano` | `int` | - | SÍ | - | **-** | Ponderación o incremento anual de puntos docentes asignable por experiencia o permanencia con dicha titulación. |
| 16 | `nia_cap_descripcion` | `int` | - | SÍ | - | **-** | Identificador del catálogo o escala descriptiva que categoriza los criterios de evaluación de títulos de este nivel. |
| 17 | `nia_estado` | `varchar` | 1 | NO | - | **Estado** | Estado del nivel formativo. |
| 18 | `nia_cap_estado` | `int` | - | SÍ | - | **Estado** | Estado operativo de la tabla de asignación de puntos de capacitación para este nivel académico (1: Vigente, 0: Derogado). |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_nivel_academico` (CLUSTERED) sobre `([nia_codigo] ASC)`

#### Restricciones de Integridad Referencial
**Claves Foráneas Explícitas (DDL):**
- `FK_nivel_academico_nivel_academico_tipo`: `nivel_academico.nat_codigo` -> `[dbo].[nivel_academico_tipo](nat_codigo)`

---

### 2.20 Entidad: `dbo.grupo`

- **Submódulo Funcional:** Planificación y Oferta Semestral
- **Archivo Fuente DDL:** `sql/dbo/grupo.sql`
- **Descripción Funcional:** Catálogo maestro de identificadores de paralelo o grupo de clase (ej. '01', '02', 'A', 'B') sobre los cuales se abren las secciones de los cursos.

#### Reglas de Negocio y Validación Operativa
- Clave primaria de longitud fija `char(2)`.
- Referenciado por `dbo.curso.cur_grupo` para distinguir comisiones de alumnos.

#### Ciclo de Vida y Estados
Catálogo estático: `gru_estado = 1`.

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `gru_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Código único de dos caracteres del grupo o paralelo. |
| 2 | `gru_nombre` | `varchar` | 100 | NO | - | **-** | Denominación descriptiva del grupo. |
| 3 | `gru_id` | `varchar` | 100 | SÍ | - | **-** | Identificador alfanumérico alternativo o clave de sincronización para integración del grupo con directorios de usuarios o autenticación. |
| 4 | `gru_estado` | `int` | - | SÍ | - | **Estado** | Estado de vigencia del identificador de grupo. |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_grupo` (NONCLUSTERED) sobre `([gru_codigo] ASC)`

#### Restricciones de Integridad Referencial
- **Claves Foráneas Explícitas:** Ninguna codificada en DDL.

---

### 2.21 Entidad: `dbo.estudiante`

- **Submódulo Funcional:** Padrón Estudiantil y Matrícula
- **Archivo Fuente DDL:** `sql/dbo/estudiante.sql`
- **Descripción Funcional:** Padrón oficial de estudiantes matriculados en la institución. Registra el código de carné estudiantil, la persona natural asociada, programa y condición de permanencia.

#### Reglas de Negocio y Validación Operativa
- Ubicada físicamente en `sql/dbo/vistas/estudiante.sql` pero definida mediante `CREATE TABLE` con PK `char(11)`.
- Vincula al alumno con su registro de persona natural (`dbo.persona`) y con su programa (`dbo.programa`).
- El campo `ese_codigo` almacena el parámetro de adscripción al acuerdo de permanencia 046.

#### Ciclo de Vida y Estados
Estados de permanencia: Activo, Graduado, Retirado, Suspendido, Egresado no graduado.

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `est_codigo` | `char` | 11 | NO | - | **PK** | Código estudiantil único de 11 caracteres (Carné institucional). |
| 2 | `per_codigo` | `int` | - | SÍ | - | **FK Explícita** | Clave foránea explícita a los datos biográficos (`dbo.persona`). |
| 3 | `est_fecha_ingreso` | `datetime` | - | NO | - | **Temporal** | Fecha oficial de primer ingreso o cohorte de admisión. |
| 4 | `pro_codigo` | `int` | - | SÍ | - | **FK Implícita** | Clave foránea implícita al programa matriculado (`dbo.programa`). |
| 5 | `ese_codigo` | `tinyint` | - | NO | - | **-** | Parámetro que identifica si el estudiante se rige por el Acuerdo 046. |
| 6 | `ins_codigo` | `int` | - | NO | - | **-** | Código del proceso de inscripción o convocatoria de admisión institucional con el cual el alumno formalizó su ingreso universitario. |
| 7 | `est_fecha_retiro` | `datetime` | - | SÍ | - | **Temporal** | Fecha oficial en la que se radicó y formalizó la cancelación de matrícula, retiro voluntario o pérdida de cupo del estudiante. |
| 8 | `ese_codigo1` | `tinyint` | - | SÍ | - | **-** | Estado secundario o histórico del estudiante para seguimiento de transiciones reglamentarias o acuerdos previos. |
| 9 | `ese_codigo2` | `tinyint` | - | SÍ | - | **-** | Segundo estado clasificatorio del estudiante para auditoría interna y estadísticas de deserción/retención institucional. |
| 10 | `est_id_carnet` | `varchar` | 45 | SÍ | - | **-** | Número serial o identificador de tarjeta/código magnético asignado al carné estudiantil físico para control de acceso y biblioteca. |
| 11 | `est_registro_egresado` | `int` | - | SÍ | - | **-** | Bandera booleana (1/0) que certifica que el estudiante cumplió la totalidad del pensum y está inscrito en el libro de egresados/graduados. |
| 12 | `ter_codigo` | `int` | - | SÍ | - | **-** | Código de la causal reglamentaria de terminación de estudios o modalidad de egreso (graduación ordinaria, retiro forzoso, prescripción). |
| 13 | `est_uid` | `int` | - | SÍ | - | **-** | Identificador numérico de usuario interno (UID) en el Directorio Activo institucional para servicios informáticos y correo electrónico. |
| 14 | `est_user` | `char` | 50 | SÍ | - | **-** | Usuario de base de datos o sistema operativo que realizó la última transacción sobre el registro estudiantil (DEFAULT suser_sname()). |
| 15 | `est_alterno` | `int` | - | NO | - | **-** | Código de identificación académica alterno o matrícula previa utilizado en procesos de migración histórica de datos o doble titulación. |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_estudiante` (NONCLUSTERED) sobre `([est_codigo] ASC)`

#### Restricciones de Integridad Referencial
**Claves Foráneas Explícitas (DDL):**
- `FK_estudiante_persona_agosto2018`: `estudiante.per_codigo` -> `[dbo].[persona](per_codigo)`

---

### 2.22 Entidad: `dbo.matricula`

- **Submódulo Funcional:** Padrón Estudiantil y Matrícula
- **Archivo Fuente DDL:** `sql/dbo/matricula.sql`
- **Descripción Funcional:** Registro maestro de la matrícula semestral formalizada por un estudiante para un calendario académico determinado, computando créditos liquidados y fechas de legalización.

#### Reglas de Negocio y Validación Operativa
- Asocia formalmente a un estudiante (`est_codigo`) con un calendario (`cal_codigo`).
- Controla el tipo de matrícula (`mat_tipo`) mediante FK hacia el maestro externo `dbo.matricula_tipo`.
- Permite verificar si el alumno tiene matrícula legalizada antes de inscribir cursos.

#### Ciclo de Vida y Estados
Ciclo de vida: Registrada -> Liquidada -> Pagada -> Legalizada -> Anulada.

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `mat_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Identificador único y clave primaria de la matrícula semestral. |
| 2 | `est_codigo` | `char` | 11 | NO | - | **FK Explícita** | Clave foránea explícita al estudiante matriculado (`dbo.estudiante`). |
| 3 | `cal_codigo` | `int` | - | NO | - | **FK Explícita** | Clave foránea explícita al calendario lectivo (`dbo.calendario`). |
| 4 | `mat_fecha` | `datetime` | - | NO | - | **Temporal** | Fecha de radicación de la matrícula. |
| 5 | `mat_problema` | `varchar` | 500 | SÍ | - | **-** | Detalle o registro técnico de inconsistencias, bloqueos financieros o impedimentos académicos que suscitaron revisión durante la matrícula. |
| 6 | `mat_observacion` | `varchar` | 300 | SÍ | - | **-** | Observaciones especiales, anotaciones de excepción académica o autorizaciones de secretaría docente sobre la matrícula del alumno. |
| 7 | `mat_estado` | `char` | 1 | SÍ | - | **Estado** | Estado de la matrícula (1: Legalizada, 0: Cancelada). |
| 8 | `ese_codigo` | `smallint` | - | SÍ | - | **-** | Código del estado estudiantil en el período; parámetro para identificar si el alumno queda cobijado bajo el régimen del Acuerdo 046. |
| 9 | `mat_tipo` | `tinyint` | - | SÍ | - | **FK Explícita** | Clave foránea explícita a la tipología (`dbo.matricula_tipo`). |
| 10 | `mat_usuario` | `int` | - | SÍ | - | **-** | Código de la persona o funcionario administrativo que procesó o autorizó la inscripción de asignaturas en el sistema. |
| 11 | `mat_clave` | `varchar` | 80 | SÍ | - | **-** | Clave transaccional temporal, token o hash de seguridad emitido para confirmar el cierre definitivo de la matrícula web. |
| 12 | `mat_cliente` | `varchar` | 50 | SÍ | - | **-** | Agente de usuario (User-Agent) o identificación del navegador cliente desde el cual se tramitó la sesión de matrícula. |
| 13 | `mat_ip` | `varchar` | 150 | SÍ | - | **-** | Dirección IP del equipo o terminal desde la cual se efectuó la transacción de inscripción y liquidación de matrícula. |
| 14 | `sippa_calcodigo` | `char` | 7 | SÍ | - | **-** | Código del calendario académico en el sistema SIPPA bajo el cual fue radicada la transacción de matrícula. |
| 15 | `mat_fecha_actualizacion` | `datetime` | - | SÍ | - | **Temporal** | Marca temporal de auditoría que registra la última actualización efectuada sobre los registros de matrícula del alumno. |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_matricula` (NONCLUSTERED) sobre `([mat_codigo] ASC)`

#### Restricciones de Integridad Referencial
**Claves Foráneas Explícitas (DDL):**
- `FK_matricula_calendario`: `matricula.cal_codigo` -> `[dbo].[calendario](cal_codigo)`
- `FK_matricula_estudiante_agosto2018`: `matricula.est_codigo` -> `[dbo].[estudiante](est_codigo)`
- `FK_matricula_matricula_tipo_agosto2018`: `matricula.mat_tipo` -> `[dbo].[matricula_tipo](mti_codigo)`

---

### 2.23 Entidad: `dbo.matricula_autorizacion`

- **Submódulo Funcional:** Padrón Estudiantil y Matrícula
- **Archivo Fuente DDL:** `sql/dbo/matricula_autorizacion.sql`
- **Descripción Funcional:** Registro de autorizaciones especiales otorgadas por jefaturas de programa para permitir a un estudiante matricularse de manera extemporánea o con prerrequisitos pendientes.

#### Reglas de Negocio y Validación Operativa
- Habilita excepciones operativas a estudiantes con bloqueos de sistema.
- Registra usuario y justificación administrativa del desbloqueo.

#### Ciclo de Vida y Estados
Vigencia temporal asociada a la ventana de matrícula.

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `maa_codigo` | `tinyint` | - | NO | - | **PK** | Identificador de la autorización de matrícula. |
| 2 | `maa_nombre` | `varchar` | 25 | SÍ | - | **-** | Nombre descriptivo o denominación del tipo de autorización especial de matrícula (ej. 'Extemporánea', 'Sobrecupo', 'Créditos Extra'). |
| 3 | `maa_observcion` | `varchar` | 100 | SÍ | - | **-** | Descripción detallada del alcance normativo, requisitos y directrices que rigen el tipo de autorización de matrícula. |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_matricula_autorizacion` (NONCLUSTERED) sobre `([maa_codigo] ASC)`

#### Restricciones de Integridad Referencial
- **Claves Foráneas Explícitas:** Ninguna codificada en DDL.

---

### 2.24 Entidad: `dbo.matricula_configuracion`

- **Submódulo Funcional:** Reglas y Parámetros de Matrícula
- **Archivo Fuente DDL:** `sql/dbo/matricula_configuracion.sql`
- **Descripción Funcional:** Cabecera de reglas y parámetros que gobierna el proceso de matrícula por plan de estudios y calendario académico, fijando topes de créditos y fechas de registro.

#### Reglas de Negocio y Validación Operativa
- Fija el número máximo y mínimo de créditos permitidos para inscripción (`mco_creditos_max`, `mco_creditos_min`).
- Delimita las fechas oficiales para matrícula ordinaria y extraordinaria.

#### Ciclo de Vida y Estados
Estado: `mco_estado = 1` (Configuración activa para el calendario).

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `mco_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Identificador único de la configuración de matrícula. |
| 2 | `mco_nombre` | `varchar` | 100 | SÍ | - | **-** | Nombre descriptivo asignado a la ventana o jornada de parametrización de prematrícula y matrícula de asignaturas. |
| 3 | `mco_fecha` | `datetime` | - | SÍ | - | **Temporal** | Fecha y hora de creación y entrada en vigencia del esquema de parametrización de matrícula. |
| 4 | `cal_codigo` | `int` | - | SÍ | - | **FK Implícita** | Clave foránea implícita al calendario lectivo (`dbo.calendario`). |
| 5 | `pla_codigo` | `int` | - | SÍ | - | **FK Explícita** | Clave foránea explícita al plan de estudios (`dbo.plan_academico`). |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_matricula_configuracion` (NONCLUSTERED) sobre `([mco_codigo] ASC)`

#### Restricciones de Integridad Referencial
**Claves Foráneas Explícitas (DDL):**
- `FK_matricula_configuracion_plan_academico`: `matricula_configuracion.pla_codigo` -> `[dbo].[plan_academico](pla_codigo)`

---

### 2.25 Entidad: `dbo.matricula_configuracion_detalle`

- **Submódulo Funcional:** Reglas y Parámetros de Matrícula
- **Archivo Fuente DDL:** `sql/dbo/matricula_configuracion_detalle.sql`
- **Descripción Funcional:** Detalle técnico de reglas de matrícula que parametriza la apertura y restricción de asignaturas y cursos específicos para una configuración de matrícula determinada.

#### Reglas de Negocio y Validación Operativa
- Vincula la configuración cabecera (`mco_codigo`) con la materia de la malla (`paa_codigo`) y el curso ofrecido (`cur_codigo`).
- Permite reservar cupos exclusivos por semestre o cohorte de estudiantes.

#### Ciclo de Vida y Estados
Vigencia operativa durante el periodo de matrícula.

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `mcd_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Identificador único del ítem de detalle de regla de matrícula. |
| 2 | `mco_codigo` | `int` | - | NO | - | **FK Explícita** | Clave foránea explícita a la configuración cabecera (`dbo.matricula_configuracion`). |
| 3 | `mcd_fecha` | `datetime` | - | NO | - | **Temporal** | Fecha y hora límite o de turno programado en que se habilita la inscripción del curso para los estudiantes autorizados. |
| 4 | `cur_codigo` | `int` | - | NO | - | **FK Explícita** | Clave foránea explícita al curso disponible (`dbo.curso`). |
| 5 | `paa_codigo` | `int` | - | NO | - | **FK Explícita** | Clave foránea explícita a la materia en la malla (`dbo.plan_academico_asignatura`). |
| 6 | `mcd_subgrupo` | `char` | 2 | SÍ | - | **-** | Código o identificador del subgrupo particular del curso al que aplica la restricción de inscripción parametrizada. |
| 7 | `mcd_cerrado` | `char` | 1 | SÍ | - | **-** | Bandera indicadora ('S'/'N' o '1'/'0') de cierre o clausura manual de la opción de matrícula para este curso y subgrupo. |
| 8 | `mcd_estado` | `int` | - | SÍ | - | **Estado** | Estado de la regla de detalle. |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_matricula_configuracion_detalle` (NONCLUSTERED) sobre `([mcd_codigo] ASC)`

#### Restricciones de Integridad Referencial
**Claves Foráneas Explícitas (DDL):**
- `FK_matricula_configuracion_detalle_curso`: `matricula_configuracion_detalle.cur_codigo` -> `[dbo].[curso](cur_codigo)`
- `FK_matricula_configuracion_detalle_matricula_configuracion`: `matricula_configuracion_detalle.mco_codigo` -> `[dbo].[matricula_configuracion](mco_codigo)`
- `FK_matricula_configuracion_detalle_plan_academico_asignatura`: `matricula_configuracion_detalle.paa_codigo` -> `[dbo].[plan_academico_asignatura](paa_codigo)`

---

## 3. Anexo: Tablas de Auditoría y Vistas Analíticas del Dominio

### 3.1 Tablas de Auditoría Transaccional
- `dbo.aud_curso`: Bitácora histórica de modificaciones DML sobre la oferta de cursos (`cur_codigo`).
- `dbo.aud_curso_cupo_subgrupo`: Bitácora histórica de variaciones en cupos de subgrupos prácticos.
- `dbo.aud_matricula_curso`: Bitácora de inscripciones, adiciones y cancelaciones de materias por alumnos.

### 3.2 Vistas Analíticas Curriculares
- `dbo.estudiante_horario_actual`: Vista agregada que consolida la agenda horaria semanal del estudiante combinando matrícula, cursos y ocupaciones de aula.
- `dbo.matricula_curso`: Vista/tabla desnormalizada para la consulta de asignaturas inscritas por estudiante en el periodo activo.
- `dbo.notas_total`: Vista analítica consolidada de calificaciones parciales y definitivas para cálculo de promedios de carrera.
