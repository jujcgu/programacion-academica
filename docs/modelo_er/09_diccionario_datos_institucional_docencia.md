# 09 - Diccionario de Datos: Estructura Institucional, Docencia y Proyección Social

## Dominio Organizacional, Planta Docente, Escalafón, Roles y Extensión Universitaria

---

## 1. Resumen Ejecutivo del Dominio

El dominio **Institucional y Docencia** modela la columna vertebral organizativa, humana y laboral de la universidad. Articula la estructura de facultades y departamentos con el personal docente, su trayectoria académica, su régimen contractual y su dedicación a labores de extensión y proyección comunitaria:

1. **Estructura Orgánica y Jerarquía Administrativa:** Unidades Académico-Administrativas (`uaa`), catálogo de puestos y cargos orgánicos (`cargo`, `uaa_cargo`), carreras formativas (`programa`, `nivel_academico`), divisiones territoriales (`departamento`, `municipio`, `sede`) y políticas de configuración institucional (`web_parametro`).
2. **Talento Humano, Contratación y Escalafón Docente:** Padrón unificado de personas naturales (`persona`), contratos y adscripción laboral (`uaa_personal`), modalidades de vinculación contractual (`vinculacion`), dedicación horaria semanal (`dedicacion`), escalafón docente (`escalafon`, `docente_escalafon`), incidencias y novedades transitorias (`novedad`, `persona_novedad`).
3. **Seguridad y Control de Acceso:** Grupos funcionales y perfiles institucionales (`grupo`), asignaciones de usuarios a roles (`usuario_grupo`).
4. **Investigación y Extensión Comunitaria:** Proyectos de investigación formal (`proyecto`, `proyecto_tipo`, `persona_proyecto`), banco de proyección social (`proyecto_proyeccion_social`) y descargas horarias semanales de docencia (`docentexproyecto_proyeccion_social`), la cual se conecta formalmente con `dbo.uaa_personal` para verificar topes de jornada laboral.

### Métricas Consolidadas del Dominio

| Métrica Arquitectónica | Valor | Descripción Técnica |
| :--- | :---: | :--- |
| **Total de Entidades Físicas** | **23** | 21 en `dbo` (incluye `[dbo].[programacion_proceso]`) + 2 en el esquema `proyectos` |
| **Total de Claves Primarias (PK)** | **23** | 21 PKs simples/subrogadas + 2 PKs compuestas (`programa`, `persona_proyecto`) |
| **Claves Foráneas Explícitas (DDL)** | **35** | 20 en `dbo` + 15 en `proyectos` (incluyendo 2 cross-schema hacia `dbo`) |
| **Claves Foráneas Implícitas (Convención)** | **30** | Relaciones por convención de nombres y claves foráneas en código |
| **Tablas Externas de Apoyo** | **13** | Catálogos institucionales y de extensión (`pais`, `proyecto_rol`, `ps_area_extension`, etc.) |

---

## 2. Catálogo Técnico y Diccionario de Entidades

### 2.1 Entidad: `[dbo].[uaa]`

- **Submódulo Funcional:** Estructura Organizacional y Unidades Administrativas
- **Archivo Fuente DDL:** `sql/dbo/uaa.sql`
- **Descripción Funcional:** Representa las Unidades Académico-Administrativas (UAA) de la universidad: Vicerrectorías, Facultades, Departamentos Académicos, Escuelas y Direcciones Administrativas. Es la entidad nuclear de agregación jerárquica para la gestión académica y presupuestal.

#### Reglas de Negocio y Validación Operativa
- Posee relación reflexiva jerárquica con `uaa_dependencia` (Facultad madre o Rectoría).
- Se adscribe a una sede institucional (`sed_codigo`) y a un municipio (`mun_codigo`).
- El campo `uaa_responsable` referencia al Decano o Director a cargo (`dbo.persona`).
- La bandera `uaa_facultad = 1` distingue a las facultades de los departamentos u oficinas.

#### Ciclo de Vida y Estados
Operatividad: `uaa_estado = 1` (Unidad académica activa).

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `uaa_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Clave primaria e identificador único de la unidad organizativa. |
| 2 | `uat_codigo` | `int` | - | NO | - | **-** | Código del tipo de Unidad Académico-Administrativa (facultad, departamento, programa curricular, vicerrectoría o sección de apoyo). |
| 3 | `uaa_nombre` | `varchar` | 200 | NO | - | **-** | Nombre oficial de la facultad, departamento o dependencia. |
| 4 | `uaa_dependencia` | `int` | - | SÍ | - | **FK Implícita** | Clave foránea implícita reflexiva a la UAA superior jerárquica (`dbo.uaa`). |
| 5 | `uaa_nombre_corto` | `varchar` | 200 | SÍ | - | **-** | Sigla o acrónimo oficial para listados e impresos. |
| 6 | `uaa_nombre_impresion` | `varchar` | 20 | SÍ | - | **-** | Denominación extendida para actas y diplomas. |
| 7 | `uaa_email` | `varchar` | 50 | SÍ | - | **-** | Correo electrónico institucional oficial de contacto. |
| 8 | `uaa_email_pqr` | `varchar` | 50 | SÍ | - | **-** | Buzón oficial de correo institucional designado para la radicación y seguimiento de Peticiones, Quejas, Reclamos y Sugerencias (PQRS). |
| 9 | `uaa_pagina` | `varchar` | 50 | SÍ | - | **-** | Dirección web o URL oficial del portal web de la unidad académica o dependencia administrativa dentro del dominio institucional. |
| 10 | `uaa_jefe` | `varchar` | 50 | SÍ | - | **-** | Código de funcionario o persona que ejerce el cargo de decano, director, jefe de departamento o responsable directo de la UAA. |
| 11 | `mun_codigo` | `int` | - | SÍ | - | **FK Implícita** | Clave foránea implícita al municipio de ubicación (`dbo.municipio`). |
| 12 | `uaa_telefono` | `varchar` | 50 | SÍ | - | **-** | Teléfono institucional de conmutador o secretaría. |
| 13 | `uaa_fax` | `varchar` | 50 | SÍ | - | **-** | Número de fax de la unidad. |
| 14 | `uaa_direccion` | `varchar` | 50 | SÍ | - | **-** | Dirección física de correspondencia o ubicación en campus. |
| 15 | `sippa_uaa_codigo` | `int` | - | SÍ | - | **-** | Código de homologación e integración de la Unidad Académico-Administrativa en el sistema legacy institucional SIPPA. |
| 16 | `sed_codigo` | `int` | - | SÍ | - | **FK Explícita** | Clave foránea explícita a la sede física principal (`dbo.sede`). |
| 17 | `uaa_centro_costos` | `char` | 3 | SÍ | - | **-** | Código presupuestal o centro de costos asignado a la UAA en el sistema financiero y contable institucional para imputación de gastos. |
| 18 | `uaa_acronimo` | `char` | 7 | SÍ | - | **-** | Sigla o acrónimo representativo de la unidad (ej. 'FACING', 'DEPSIS', 'VICDOC') para membretes, comunicaciones internas y reportes. |
| 19 | `uaa_estado` | `int` | - | SÍ | - | **Estado** | Estado de actividad de la unidad (1: Activa, 0: Extinta). |
| 20 | `uaa_ventanilla` | `int` | - | SÍ | - | **-** | Identificador de la ventanilla única de atención presencial o radicación documental asignada a la dependencia. |
| 21 | `uaa_codigo_retencion` | `varchar` | 15 | SÍ | - | **-** | Código de clasificación asignado a la UAA en las Tablas de Retención Documental (TRD) institucionales aprobadas por el archivo central. |
| 22 | `uaa_propietario_codigo` | `int` | - | SÍ | - | **-** | Código de la UAA jerárquica superior o unidad matriz propietaria a la que se encuentra adscrita orgánicamente la dependencia. |
| 23 | `uaa_jefe_per_codigo` | `bigint` | - | SÍ | - | **-** | Clave foránea que referencia al registro personal (dbo.persona) del funcionario que ejerce la jefatura o dirección de la unidad. |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_unidad_academica_administrativa` (NONCLUSTERED) sobre `([uaa_codigo] ASC)`

#### Restricciones de Integridad Referencial
**Claves Foráneas Explícitas (DDL):**
- `FK_uaa_sede`: `uaa.sed_codigo` -> `[dbo].[sede](sed_codigo)`

---

### 2.2 Entidad: `[dbo].[cargo]`

- **Submódulo Funcional:** Estructura Organizacional y Unidades Administrativas
- **Archivo Fuente DDL:** `sql/dbo/cargo.sql`
- **Descripción Funcional:** Catálogo clasificador de los cargos institucionales universitarios (Profesor de Planta, Catedrático, Decano, Jefe de Departamento, Secretario Académico).

#### Reglas de Negocio y Validación Operativa
- Tipifica la naturaleza del puesto (`car_tipo`: Docente, Directivo, Administrativo).
- Referenciado por `dbo.uaa_cargo` y `dbo.uaa_personal`.

#### Ciclo de Vida y Estados
Catálogo estático: `car_estado = 1`.

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `car_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Identificador único del cargo. |
| 2 | `car_nombre` | `varchar` | 50 | NO | - | **-** | Denominación oficial del cargo. |
| 3 | `car_id` | `varchar` | 4 | SÍ | - | **-** | Identificador alfanumérico o código serial del cargo en la estructura del manual de funciones y planta de personal de la universidad. |
| 4 | `car_tmp` | `int` | - | SÍ | - | **-** | Bandera clasificatoria (1/0) que indica si el cargo tiene naturaleza transitoria/temporal frente a puestos de planta permanente. |
| 5 | `car_jefe` | `int` | - | SÍ | - | **-** | Código del cargo de nivel superior inmediato al cual se reporta jerárquica y funcionalmente en el organigrama institucional. |
| 6 | `car_estado` | `int` | - | SÍ | - | **Estado** | Vigencia del cargo en el organigrama. |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_cargo` (CLUSTERED) sobre `([car_codigo] ASC)`

#### Restricciones de Integridad Referencial
- **Claves Foráneas Explícitas:** Ninguna codificada en DDL.

---

### 2.3 Entidad: `[dbo].[uaa_cargo]`

- **Submódulo Funcional:** Estructura Organizacional y Unidades Administrativas
- **Archivo Fuente DDL:** `sql/dbo/uaa_cargo.sql`
- **Descripción Funcional:** Planta orgánica de cargos formalmente creados y habilitados en cada UAA (plazas docentes y administrativas aprobadas por el Consejo Superior).

#### Reglas de Negocio y Validación Operativa
- Conecta la UAA (`uac_uaa`) con el cargo (`car_codigo`), la vinculación (`uac_vinculacion`) y la dedicación (`uac_dedicacion`).
- Fija el número de plazas presupuestadas (`uac_cantidad`).

#### Ciclo de Vida y Estados
Vigencia: `uac_estado = 1` (Plaza orgánica habilitada).

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `uac_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Identificador único de la plaza orgánica en la UAA. |
| 2 | `uac_uaa` | `int` | - | SÍ | - | **FK Explícita** | Clave foránea explícita a la UAA donde radica la plaza (`dbo.uaa`). |
| 3 | `uac_cargo` | `int` | - | SÍ | - | **-** | Código o clave identificadora del cargo específico asignado a la estructura de planta de la Unidad Académico-Administrativa. |
| 4 | `uac_vinculacion` | `int` | - | SÍ | - | **FK Explícita** | Clave foránea explícita a la vinculación contractual (`dbo.vinculacion`). |
| 5 | `uac_dedicacion` | `int` | - | SÍ | - | **FK Explícita** | Clave foránea explícita a la dedicación horaria (`dbo.dedicacion`). |
| 6 | `uac_codigoplanta` | `nvarchar` | 4 | SÍ | - | **-** | Número de plaza o código de puesto presupuestal asignado en la planta global de cargos de la dependencia. |
| 7 | `uac_grado` | `int` | - | SÍ | - | **-** | Grado salarial o nivel de remuneración del cargo dentro de la escala salarial del régimen de carrera administrativa o docente. |
| 8 | `uac_estado` | `int` | - | SÍ | - | **Estado** | Estado de la plaza (1: Activa, 0: Suprimida). |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_uaa_cargo` (CLUSTERED) sobre `([uac_codigo] ASC)`

#### Restricciones de Integridad Referencial
**Claves Foráneas Explícitas (DDL):**
- `FK_uaa_cargo_dedicacion`: `uaa_cargo.uac_dedicacion` -> `[dbo].[dedicacion](ded_codigo)`
- `FK_uaa_cargo_uaa`: `uaa_cargo.uac_uaa` -> `[dbo].[uaa](uaa_codigo)`
- `FK_uaa_cargo_vinculacion`: `uaa_cargo.uac_vinculacion` -> `[dbo].[vinculacion](vin_codigo)`

---

### 2.4 Entidad: `[dbo].[programa]`

- **Submódulo Funcional:** Estructura Curricular Institucional
- **Archivo Fuente DDL:** `sql/dbo/programa.sql`
- **Descripción Funcional:** Catálogo institucional de programas curriculares y carreras profesionales. Posee PK compuesta (`pro_codigo, uaa_codigo, sed_codigo`).

#### Reglas de Negocio y Validación Operativa
- Representa la oferta académica formal adscrita a una facultad (`uaa_codigo`) y sede (`sed_codigo`).

#### Ciclo de Vida y Estados
Estado: `pro_estado = 1` (Carrera activa).

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `pro_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Código numérico del programa curricular (PK parte 1). |
| 2 | `pro_programa` | `char` | 4 | SÍ | - | **-** | Código corto alfanumérico o nemotécnico interno asignado al programa académico para rotulación compacta de cursos y grupos. |
| 3 | `sed_codigo` | `int` | - | NO | - | **PK** | Sede institucional en `dbo.sede` (PK parte 3). |
| 4 | `uaa_codigo` | `int` | - | NO | - | **PK** | Facultad adscrita en `dbo.uaa` (PK parte 2). |
| 5 | `uaa_codigo_unificado` | `int` | - | SÍ | - | **-** | Código de la Unidad Académico-Administrativa unificada responsable de la gestión curricular y estadísticas consolidadas del programa. |
| 6 | `nia_codigo` | `int` | - | SÍ | - | **FK Explícita** | Clave foránea explícita al nivel académico (`dbo.nivel_academico`). |
| 7 | `pro_registro_icfes` | `varchar` | 50 | SÍ | - | **-** | Código SNIES/ICFES. |
| 8 | `pro_registro_snies` | `varchar` | 50 | SÍ | - | **-** | Código único oficial asignado al programa académico en el Sistema Nacional de Información de la Educación Superior (SNIES) del MEN. |
| 9 | `pro_extension_snies` | `char` | 1 | SÍ | - | **-** | Código de extensión o radicado seccional SNIES cuando el programa cuenta con autorización para operar en municipios o sedes regionales. |
| 10 | `jor_codigo` | `int` | - | SÍ | - | **-** | Código de la jornada académica de oferta del programa (diurna, nocturna, vespertina, a distancia o mixta). |
| 11 | `res_codigo` | `int` | - | SÍ | - | **-** | Código de la resolución administrativa expedida por el Ministerio de Educación Nacional que confiere o renueva el Registro Calificado. |
| 12 | `pro_titulo_otorgado` | `varchar` | 100 | SÍ | - | **-** | Denominación oficial del título universitario que la institución confiere al graduado (ej. 'Ingeniero Agrónomo', 'Licenciado en Matemáticas'). |
| 13 | `pro_fecha_creacion` | `datetime` | - | SÍ | - | **Temporal** | Fecha oficial del acto administrativo institucional (acuerdo del Consejo Superior) que creó y autorizó el programa en la universidad. |
| 14 | `mod_codigo` | `tinyint` | - | SÍ | - | **-** | Código de modalidad formativa autorizada en el registro calificado (presencial, a distancia tradicional, virtual, dual). |
| 15 | `con_codigo` | `int` | - | SÍ | - | **-** | Código de convenio interinstitucional de articulación o titulación compartida bajo el cual se administra el programa académico. |
| 16 | `pro_horario` | `varchar` | 100 | SÍ | - | **Temporal** | Descripción funcional del esquema habitual de programación horaria y franjas asignadas para impartir las clases del programa. |
| 17 | `pro_estado` | `char` | 2 | SÍ | - | **Estado** | Estado del programa. |
| 18 | `pro_propio` | `char` | 1 | SÍ | - | **-** | Indicador de titularidad institucional: 'S' si el programa es propio y autónomo de la universidad, 'N' si opera en convenio o extensión. |
| 19 | `uaa_programa_gen` | `int` | - | SÍ | - | **-** | Código de la facultad matriz o UAA genérica superior encargada del direccionamiento estratégico del programa. |
| 20 | `par_codigo` | `int` | - | SÍ | - | **-** | Código del parámetro de periodicidad o régimen de admisión aplicable para la apertura de cohortes del programa. |
| 21 | `nbc_codigo` | `int` | - | SÍ | - | **-** | Código del Núcleo Básico de Conocimiento (NBC) asignado oficialmente al programa por el MEN y la clasificación SNIES. |
| 22 | `pro_calendario` | `char` | 1 | SÍ | - | **-** | Régimen de calendario académico bajo el cual se rige la matrícula y apertura de cursos del programa (ej. 'A', 'B' o semestral estándar). |
| 23 | `sippa_pro_codigo` | `char` | 4 | SÍ | - | **-** | Código de integración y equivalencia del programa académico en el sistema legacy externo SIPPA. |
| 24 | `pro_descripcion` | `varchar` | max | SÍ | - | **-** | Resumen descriptivo del perfil profesional, campo ocupacional, competencias y justificación académica del programa. |
| 25 | `pro_creacion_snies` | `date` | - | SÍ | - | **-** | Fecha de registro formal y radicación inicial del programa académico ante la plataforma estatal SNIES. |
| 26 | `cam_det_codigo` | `int` | - | SÍ | - | **FK Explícita** | Código del Campo Detallado de formación académica según la Clasificación Internacional Normalizada de la Educación (CINE-F / MEN). |
| 27 | `pro_propedeutico` | `int` | - | SÍ | - | **-** | Indicador binario (1/0) que especifica si el programa hace parte de un ciclo propedéutico secuencial articulado de formación. |

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

### 2.5 Entidad: `[dbo].[nivel_academico]`

- **Submódulo Funcional:** Estructura Curricular Institucional
- **Archivo Fuente DDL:** `sql/dbo/nivel_academico.sql`
- **Descripción Funcional:** Catálogo de niveles de formación académica universitaria (Pregrado, Postgrado, Maestría, Doctorado).

#### Reglas de Negocio y Validación Operativa
- Conecta con el catálogo maestro externo `dbo.nivel_academico_tipo` (`nat_codigo`).

#### Ciclo de Vida y Estados
Catálogo estático: `nia_estado = 1`.

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `nia_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Identificador del nivel formativo. |
| 2 | `nia_nombre` | `varchar` | 50 | SÍ | - | **-** | Denominación del nivel académico. |
| 3 | `nia_orden` | `tinyint` | - | SÍ | - | **-** | Orden jerárquico o secuencia de nivel para clasificación y prelación académica (1: Pregrado, 2: Especialización, 3: Maestría, 4: Doctorado). |
| 4 | `for_codigo` | `tinyint` | - | SÍ | - | **-** | Código de la formalidad académica asociada (educación formal superior frente a diplomados o extensión) según dbo.formalidad. |
| 5 | `snies_codigo` | `char` | 2 | SÍ | - | **-** | Código de homologación del nivel de formación según las tablas maestras estandarizadas del SNIES del Ministerio de Educación. |
| 6 | `sippa_nia_codigo` | `int` | - | SÍ | - | **-** | Identificador numérico del nivel académico en las estructuras de datos del sistema legacy SIPPA. |
| 7 | `sippa_nivcodigo` | `char` | 3 | SÍ | - | **-** | Código mnemotécnico alfanumérico corto de 3 posiciones representativo del nivel académico en SIPPA. |
| 8 | `nia_codigo_mp_hecaa` | `int` | - | SÍ | - | **-** | Código de Metodología de Programa para la integración de datos ante la plataforma estatal HECAA del MEN. |
| 9 | `nia_codigo_ned_hecaa` | `int` | - | SÍ | - | **-** | Código estandarizado de Nivel Educativo / Nivel de Formación requerido para reportes periódicos al sistema HECAA. |
| 10 | `nia_codigo_ne_hecaa` | `int` | - | SÍ | - | **-** | Código de Nivel de Escolaridad asignado para la clasificación de docentes y títulos en la plataforma de información HECAA. |
| 11 | `nat_codigo` | `int` | - | SÍ | - | **FK Explícita** | Clave foránea explícita a `dbo.nivel_academico_tipo`. |
| 12 | `nia_cap_puntos` | `int` | - | SÍ | - | **-** | Puntaje salarial base conferido a los docentes en el escalafón por acreditar títulos académicos obtenidos en este nivel. |
| 13 | `nia_cap_puntos_adicionales` | `int` | - | SÍ | - | **-** | Puntos salariales adicionales o complementarios reconocidos a la carrera docente por formación continua en este nivel. |
| 14 | `nia_cap_maximo` | `int` | MAX | SÍ | - | **-** | Tope o límite máximo reglamentario de puntos salariales acumulables por títulos de capacitación en este nivel de titulación. |
| 15 | `nia_cap_puntos_xano` | `int` | - | SÍ | - | **-** | Ponderación o incremento anual de puntos salariales docentes reconocible por permanencia o experiencia en dicho nivel. |
| 16 | `nia_cap_descripcion` | `int` | - | SÍ | - | **-** | Identificador o referencia al catálogo descriptivo de criterios de evaluación de títulos para este nivel académico. |
| 17 | `nia_estado` | `varchar` | 1 | NO | - | **Estado** | Estado de vigencia. |
| 18 | `nia_cap_estado` | `int` | - | SÍ | - | **Estado** | Bandera operativa que indica la vigencia activa de la tabla de asignación de puntos para este nivel formativo (1: Activo, 0: Inactivo). |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_nivel_academico` (CLUSTERED) sobre `([nia_codigo] ASC)`

#### Restricciones de Integridad Referencial
**Claves Foráneas Explícitas (DDL):**
- `FK_nivel_academico_nivel_academico_tipo`: `nivel_academico.nat_codigo` -> `[dbo].[nivel_academico_tipo](nat_codigo)`

---

### 2.6 Entidad: `[dbo].[departamento]`

- **Submódulo Funcional:** Jerarquía Territorial y Contexto
- **Archivo Fuente DDL:** `sql/dbo/departamento.sql`
- **Descripción Funcional:** Catálogo territorial de departamentos geográficos del país, conectado a `dbo.pais`.

#### Reglas de Negocio y Validación Operativa
- Utilizado para georreferenciación de sedes y municipios.

#### Ciclo de Vida y Estados
Catálogo geográfico estático.

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `dep_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Identificador único de departamento territorial. |
| 2 | `dep_acronimo` | `char` | 2 | SÍ | - | **-** | Sigla o acrónimo formal de 2 o 3 caracteres que representa al departamento geográfico (ej. 'HUI', 'CUN', 'ANT', 'TOL'). |
| 3 | `dep_nombre` | `varchar` | 100 | NO | - | **-** | Nombre oficial del departamento. |
| 4 | `pai_codigo` | `int` | - | NO | - | **FK Explícita** | Clave foránea explícita hacia `dbo.pais`. |
| 5 | `sippa_dep_codigo` | `int` | - | SÍ | - | **-** | Código identificador de equivalencia del departamento geográfico en la base de datos legacy SIPPA. |
| 6 | `dane_codigo` | `char` | 10 | SÍ | - | **-** | Código oficial de dos dígitos de la División Político-Administrativa de Colombia (DANE/DIVIPOLA) para el departamento (ej. '41' para Huila). |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_departamento_1` (CLUSTERED) sobre `([dep_codigo] ASC)`

#### Restricciones de Integridad Referencial
**Claves Foráneas Explícitas (DDL):**
- `FK_departamento_pais`: `departamento.pai_codigo` -> `[dbo].[pais](pai_codigo)`

---

### 2.7 Entidad: `[dbo].[web_parametro]`

- **Submódulo Funcional:** Parámetros y Configuración Institucional
- **Archivo Fuente DDL:** `sql/dbo/web_parametro.sql`
- **Descripción Funcional:** Tabla de configuración de parámetros globales, llaves y políticas del sistema de información institucional.

#### Reglas de Negocio y Validación Operativa
- Almacena pares clave-valor (`wep_nombre`, `wep_valor`) consultados por el framework PHP.

#### Ciclo de Vida y Estados
Vigencia: `wep_estado = 1`.

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `wep_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Identificador único del parámetro web. |
| 2 | `wep_nombre` | `varchar` | 100 | NO | - | **-** | Nombre o clave de configuración del parámetro. |
| 3 | `wep_valor` | `varchar` | max | NO | - | **-** | Valor o contenido asociado al parámetro. |
| 4 | `wep_descripcion` | `varchar` | 500 | SÍ | - | **-** | Explicación funcional detallada del parámetro de configuración web del sistema, su ámbito operativo y valores permitidos. |
| 5 | `wep_estado` | `int` | - | NO | - | **Estado** | Estado activo o inactivo del parámetro. |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_web_parametro_1` (CLUSTERED) sobre `([wep_codigo] ASC)`

#### Restricciones de Integridad Referencial
- **Claves Foráneas Explícitas:** Ninguna codificada en DDL.

---

### 2.8 Entidad: `[dbo].[persona]`

- **Submódulo Funcional:** Talento Humano, Nómina y Escalafón Docente
- **Archivo Fuente DDL:** `sql/dbo/persona.sql`
- **Descripción Funcional:** Padrón unificado de personas naturales vinculadas a la universidad (profesores, funcionarios administrativos, directivos y estudiantes). Centraliza datos biográficos y de contacto.

#### Reglas de Negocio y Validación Operativa
- Garantiza unicidad de documento de identidad (`per_identificacion`).
- Distingue la persona física de sus múltiples roles contractuales en `dbo.uaa_personal`.
- Es referenciada por las solicitudes de préstamo docente (`solicitud_prestamo_docente.persona_codigo`) al formalizar la asignación del profesor.

#### Ciclo de Vida y Estados
Padrón permanente: `per_estado = 1` (Persona activa en el sistema institucional).

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `per_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Clave primaria e identificador único de la persona natural. |
| 2 | `per_identificacion` | `varchar` | 15 | NO | - | **-** | Número de cédula de ciudadanía o documento de identidad. |
| 3 | `tii_codigo` | `int` | - | NO | - | **-** | Código del tipo de documento de identidad oficial de la persona (Cédula de Ciudadanía, Tarjeta de Identidad, Cédula de Extranjería, Pasaporte). |
| 4 | `per_libreta_militar` | `varchar` | 15 | SÍ | - | **-** | Número de la libreta militar o constancia de definición de la situación militar para ciudadanos obligados según la ley. |
| 5 | `per_apellido` | `varchar` | 40 | SÍ | - | **-** | Apellidos de la persona natural. |
| 6 | `per_nombre` | `varchar` | 40 | SÍ | - | **-** | Nombres de la persona natural. |
| 7 | `per_genero` | `char` | 1 | SÍ | - | **-** | Identificador del género o sexo biológico registrado de la persona ('M': Masculino, 'F': Femenino, u otro código institucional). |
| 8 | `per_lugar_expedicion` | `int` | - | SÍ | - | **-** | Código del municipio geográfico en el cual fue formalmente expedido el documento de identidad de la persona (referencia a dbo.municipio). |
| 9 | `per_fecha_expedicion` | `date` | - | SÍ | - | **Temporal** | Fecha de expedición oficial del documento de identidad según consta en el documento físico. |
| 10 | `per_fecha_nacimiento` | `date` | - | SÍ | - | **Temporal** | Fecha de nacimiento de la persona para cálculo de edad cronológica, categorización etaria y trámites pensionales o de admisión. |
| 11 | `per_direccion_residencia` | `varchar` | 255 | SÍ | - | **-** | Dirección domiciliaria física de residencia habitual de la persona para correspondencia formal y visitas domiciliarias. |
| 12 | `per_telefono_movil` | `varchar` | 50 | SÍ | - | **-** | Número de teléfono celular o línea móvil principal de contacto personal para notificaciones operativas y autenticación en dos pasos. |
| 13 | `per_telefono_fijo` | `varchar` | 30 | SÍ | - | **-** | Número de teléfono fijo residencial o número de contacto local alternativo de la persona. |
| 14 | `per_estado_civil` | `char` | 1 | SÍ | - | **-** | Código del estado civil de la persona ('S': Soltero, 'C': Casado, 'U': Unión Libre, 'V': Viudo, 'D': Divorciado). |
| 15 | `per_lugar_nacimiento` | `int` | - | SÍ | - | **-** | Código del municipio geográfico donde se produjo el nacimiento de la persona (referencia a dbo.municipio). |
| 16 | `per_lugar_residencia` | `int` | - | SÍ | - | **-** | Código del municipio geográfico en el que reside actualmente la persona (referencia a dbo.municipio). |
| 17 | `per_departamento_residencia` | `int` | - | SÍ | - | **-** | Código del departamento geográfico correspondiente a la residencia habitual de la persona (referencia a dbo.departamento). |
| 18 | `per_pais_residencia` | `int` | - | SÍ | - | **-** | Código del país de residencia actual de la persona (referencia a tabla maestra dbo.pais). |
| 19 | `per_barrio` | `varchar` | 50 | SÍ | - | **-** | Nombre o denominación del barrio, sector urbano o comuna en el cual se localiza la residencia domiciliaria. |
| 20 | `per_estrato` | `tinyint` | - | SÍ | - | **-** | Estrato socioeconómico de la vivienda (1 a 6) empleado para liquidación socioeconómica de matrículas y asignación de subsidios de bienestar. |
| 21 | `eps_codigo` | `int` | - | SÍ | - | **-** | Código de la Entidad Promotora de Salud (EPS) a la cual está legalmente afiliada la persona dentro del Sistema General de Seguridad Social en Salud. |
| 22 | `eta_codigo` | `int` | - | SÍ | - | **-** | Código de auto-reconocimiento étnico o pertenencia a grupos étnicos minoritarios (indígena, afrodescendiente, raizal, palenquero, Rrom). |
| 23 | `per_numero_afiliacion_eps` | `varchar` | 20 | SÍ | - | **-** | Número de carné, consecutivo de afiliación o folio individual de registro en la entidad prestadora de salud EPS. |
| 24 | `per_ips_sisben` | `varchar` | 200 | SÍ | - | **-** | Nombre de la Institución Prestadora de Servicios de Salud (IPS) asignada o nivel/puntaje registrado en la base del SISBÉN. |
| 25 | `per_id_cotizante` | `varchar` | 15 | SÍ | - | **-** | Número de documento de identidad del cotizante principal cuando la persona tiene calidad de beneficiaria en el sistema de salud. |
| 26 | `per_beneficiario_ley1081` | `char` | 1 | SÍ | - | **-** | Bandera ('S'/'N' o '1'/'0') que certifica si la persona es beneficiaria de los incentivos, becas o exenciones contempladas en la Ley 1081 / 1084. |
| 27 | `per_familiar_direccion` | `varchar` | 255 | SÍ | - | **-** | Dirección domiciliaria física del familiar, tutor o acudiente designado como contacto de emergencia. |
| 28 | `per_familiar_nombre` | `varchar` | 60 | SÍ | - | **-** | Nombre y apellidos completos del familiar o persona de contacto para situaciones de urgencia o representación legal. |
| 29 | `per_familiar_telefono` | `varchar` | 30 | SÍ | - | **-** | Número de teléfono fijo o móvil del familiar de contacto o tutor responsable. |
| 30 | `per_familiar_lugar_residencia` | `int` | - | SÍ | - | **-** | Código del municipio de residencia del familiar o acudiente (referencia a dbo.municipio). |
| 31 | `per_email` | `varchar` | 100 | SÍ | - | **-** | Correo electrónico institucional oficial. |
| 32 | `per_email_interno` | `varchar` | 100 | SÍ | - | **-** | Dirección de correo electrónico institucional corporativo asignada a la persona (dominio @usco.edu.co o equivalente). |
| 33 | `enviar_correo` | `tinyint` | - | SÍ | - | **-** | Bandera booleana (1/0) de consentimiento informado para el envío de notificaciones académicas, circulares y comunicaciones por correo. |
| 34 | `per_pagina_personal` | `varchar` | 100 | SÍ | - | **-** | Dirección web o enlace URL al sitio web personal, blog académico o repositorio de producción intelectual de la persona. |
| 35 | `grs_codigo` | `int` | - | SÍ | - | **-** | Código del grupo sanguíneo y factor RH de la persona (ej. O+, A+, B+, AB+, O-, etc.) para historia clínica y emergencias. |
| 36 | `per_estado` | `tinyint` | - | SÍ | - | **Estado** | Estado de la persona en el padrón universitario (1: Activo, 0: Inactivo). |
| 37 | `nat_codigo` | `int` | - | SÍ | - | **-** | Código de nacionalidad o país de origen legal de la persona según catálogo institucional. |
| 38 | `reg_codigo` | `int` | - | SÍ | - | **-** | Código del régimen de afiliación a seguridad social en salud (Contributivo, Subsidiado, Especial, Excepción). |
| 39 | `per_razon_social` | `varchar` | 200 | SÍ | - | **-** | Razón social formal registrada cuando la persona inscrita en la tabla corresponde a una entidad o persona jurídica externa. |
| 40 | `per_identificacion_dup` | `varchar` | 15 | SÍ | - | **-** | Campo de control para trazabilidad de identificaciones anteriores durante procesos de corrección de homónimos o duplicados. |
| 41 | `per_cedula` | `varchar` | 15 | SÍ | - | **-** | Número histórico de Cédula de Ciudadanía archivado previo a procesos de actualización o unificación de documento de identidad. |
| 42 | `per_tarjeta` | `varchar` | 15 | SÍ | - | **-** | Número histórico de Tarjeta de Identidad almacenado para estudiantes que alcanzaron la mayoría de edad y renovaron documento. |
| 43 | `per_codigo_postal` | `varchar` | 10 | SÍ | - | **-** | Código postal oficial correspondiente a la dirección domiciliaria de la persona según la codificación postal nacional. |
| 44 | `per_pasaporte` | `varchar` | 10 | SÍ | - | **-** | Número oficial de pasaporte vigente para extranjeros, docentes visitantes o trámites de movilidad internacional. |
| 45 | `per_huella` | `varbinary` | 3000 | SÍ | - | **-** | Plantilla o template biométrico digitalizado de la huella dactilar para validación de identidad en control de acceso biométrico. |
| 46 | `per_fecha_registro` | `datetime` | - | SÍ | - | **Temporal** | Marca temporal de auditoría en la que se creó el registro inicial de la persona en la base de datos institucional. |
| 47 | `per_codigo_pais_hecaa` | `int` | - | SÍ | - | **-** | Código de país según la codificación estandarizada del sistema HECAA para estadísticas de población extranjera del MEN. |
| 48 | `per_fecha_actualizacion` | `datetime` | - | SÍ | - | **Temporal** | Fecha y hora de la última modificación o actualización efectuada sobre los datos biográficos de la persona. |
| 49 | `lenguaNativa` | `int` | - | SÍ | - | **-** | Código de la lengua o idioma materno nativo de la persona (español, lengua indígena ancestral, lengua criolla, etc.). |
| 50 | `eps_par_codigo` | `int` | - | SÍ | - | **-** | Código del parentesco de la persona con respecto al titular cotizante principal en el esquema de afiliación a la EPS. |
| 51 | `era_codigo` | `int` | - | SÍ | - | **-** | Código de estrato o régimen arancelario especial aplicable para exenciones o tarifas preferenciales de derechos académicos. |
| 52 | `evt_codigo` | `int` | - | SÍ | - | **-** | Código de caracterización de población vulnerable o especial (víctimas del conflicto armado, desplazados, reincorporados). |
| 53 | `per_municipio_procedencia` | `int` | - | SÍ | - | **-** | Código del municipio geográfico de origen o procedencia previa al ingreso a la universidad (referencia a dbo.municipio). |
| 54 | `zor_codigo` | `int` | - | SÍ | - | **-** | Código de la zona de residencia de procedencia de la persona (Urbana, Rural dispersa, Centro poblado). |
| 55 | `scs_codigo` | `int` | - | SÍ | - | **-** | Código de situación socioeconómica y clasificación del entorno familiar de la persona según instrumentos de bienestar. |
| 56 | `per_email_alterno` | `varchar` | 100 | SÍ | - | **-** | Dirección de correo electrónico secundaria o personal para recuperación de contraseñas y notificaciones externas. |
| 57 | `ors_codigo` | `int` | - | SÍ | - | **-** | Código de orientación sexual para encuestas estadísticas sociodemográficas y de diversidad requeridas por el MEN. |
| 58 | `idge_codigo` | `int` | - | SÍ | - | **-** | Código de identidad de género de la persona según las directrices y categorías censales establecidas por el DANE y el MEN. |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_persona` (NONCLUSTERED) sobre `([per_codigo] ASC)`

#### Restricciones de Integridad Referencial
- **Claves Foráneas Explícitas:** Ninguna codificada en DDL.

---

### 2.9 Entidad: `[dbo].[uaa_personal]`

- **Submódulo Funcional:** Talento Humano, Nómina y Escalafón Docente
- **Archivo Fuente DDL:** `sql/dbo/uaa_personal.sql`
- **Descripción Funcional:** Entidad nuclear de la nómina docente e institucional. Modela el contrato, plaza, cargo y adscripción laboral de un docente o funcionario en una UAA específica, definiendo horas lectivas, de investigación y de extensión.

#### Reglas de Negocio y Validación Operativa
- Conecta la persona natural (`per_codigo`) con la UAA de adscripción (`uaa_codigo`).
- Fija la modalidad de vinculación (`vin_codigo`) y la dedicación horaria semanal (`ded_codigo`).
- Distribuye la jornada laboral en: horas lectivas de clase (`uap_horas_lectivas`), horas de investigación (`uap_horas_investigacion`), horas de extensión social (`uap_horas_extension`) y horas administrativas (`uap_horas_admin`).
- Es la entidad referenciada por `dbo.curso.uap_codigo`, `dbo.espacio_ocupacion.uap_codigo` y `proyectos.docentexproyecto_proyeccion_social.uap_codigo`.

#### Ciclo de Vida y Estados
Ciclo laboral: Posesión (`uap_fecha_inicio`) -> Contrato Activo (`uap_estado = 1`) -> Liquidación / Vencimiento (`uap_fecha_fin`) -> Retiro / Pensionado (`uap_pensionado = 1`).

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `uap_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Clave primaria e identificador único de la vinculación laboral. |
| 2 | `uaa_codigo` | `int` | - | NO | - | **FK Explícita** | Clave foránea explícita a la UAA de adscripción (`dbo.uaa`). |
| 3 | `per_codigo` | `int` | - | NO | - | **FK Explícita** | Clave foránea explícita a la persona natural contratada (`dbo.persona`). |
| 4 | `uap_fecha_inicio` | `date` | - | NO | - | **Temporal** | Fecha oficial de inicio de labores contractuales. |
| 5 | `uap_fecha_fin` | `date` | - | SÍ | - | **Temporal** | Fecha oficial de finalización de contrato. |
| 6 | `uap_cargo` | `int` | - | SÍ | - | **-** | Código o denominación funcional del cargo docente o administrativo desempeñado en la Unidad Académico-Administrativa. |
| 7 | `vin_codigo` | `int` | - | NO | - | **FK Implícita** | Clave foránea implícita al tipo de vinculación (`dbo.vinculacion`). |
| 8 | `ded_codigo` | `int` | - | SÍ | - | **FK Implícita** | Clave foránea implícita a la dedicación horaria (`dbo.dedicacion`). |
| 9 | `uap_resolucion` | `varchar` | 100 | SÍ | - | **-** | Número de acto administrativo o resolución de nombramiento. |
| 10 | `uap_estado` | `smallint` | - | SÍ | - | **Estado** | Estado de la vinculación (1: Activa, 0: Inactiva). |
| 11 | `esv_codigo` | `int` | - | SÍ | - | **-** | Código del estado de la vinculación laboral (ej. Activo, En Comisión de Servicios, Suspendido, Licencia no remunerada). |
| 12 | `esc_valor` | `money` | - | SÍ | - | **-** | Puntaje salarial o valor unitario de remuneración mensual asignado al funcionario o docente dentro de la escala legal. |
| 13 | `sippa_puntos` | `varchar` | 500 | SÍ | - | **-** | Puntos salariales consolidados reconocidos en el sistema SIPPA según el Decreto 1279 y evaluaciones de productividad docente. |
| 14 | `sippa_doccedula` | `char` | 11 | SÍ | - | **-** | Número de documento de identidad del docente registrado en el sistema externo legacy SIPPA. |
| 15 | `sippa_vincodigo` | `char` | 3 | SÍ | - | **-** | Código de homologación del tipo de vinculación laboral docente en el sistema SIPPA. |
| 16 | `sippa_calcodigo` | `char` | 6 | SÍ | - | **-** | Código del calendario académico bajo el cual se contrató o vinculó el funcionario docente en SIPPA. |
| 17 | `sippa_dedcodigo` | `char` | 1 | SÍ | - | **-** | Código de la dedicación horaria (Tiempo Completo, Medio Tiempo, Cátedra) homologado en SIPPA. |
| 18 | `uap_codigo_anterior` | `int` | - | SÍ | - | **-** | Código de vinculación previo para trazabilidad histórica en casos de prórrogas, ascensos o cambios de adscripción. |
| 19 | `uac_codigo` | `int` | - | SÍ | - | **-** | Código de la plaza de personal presupuestal o cargo formal asignado en la planta de la dependencia (dbo.uaa_cargo). |
| 20 | `uap_plantaencargo` | `char` | 1 | SÍ | - | **-** | Bandera booleana (1/0) que indica si el nombramiento corresponde a una designación en encargo sobre un puesto de planta permanente. |
| 21 | `uap_uacocupado` | `int` | - | SÍ | - | **-** | Bandera indicadora (1/0) de si la plaza presupuestal correspondiente se encuentra actualmente ocupada en ejercicio por el titular. |
| 22 | `uap_dependencia_ejerce` | `int` | - | SÍ | - | **-** | Código de la UAA en la cual el funcionario o docente desempeña efectivamente sus labores (si difiere de su unidad de adscripción formal). |
| 23 | `codRegistro` | `bigint` | - | SÍ | - | **-** | Número consecutivo o radicado oficial de registro del contrato o acta de posesión en la Oficina de Talento Humano. |
| 24 | `uap_id_carnet` | `varchar` | 45 | SÍ | - | **-** | Identificador serial o código magnético del carné institucional expedido al funcionario para acceso y servicios universitarios. |
| 25 | `sed_codigo` | `int` | - | SÍ | - | **FK Implícita** | Clave foránea implícita a la sede de trabajo (`dbo.sede`). |
| 26 | `uap_observacion` | `varchar` | max | SÍ | - | **-** | Anotaciones administrativas, antecedentes de designación o particularidades sobre el contrato laboral del personal. |
| 27 | `uap_auto_tratamiento_datos` | `int` | - | SÍ | - | **-** | Bandera booleana (1/0) que certifica que el titular autorizó de manera previa y expresa el tratamiento de sus datos personales (Habeas Data). |
| 28 | `uap_fecha_auto_tratamiento_datos` | `datetime` | - | SÍ | - | **Temporal** | Fecha y hora precisa en la que el funcionario o docente suscribió electrónicamente la autorización de tratamiento de datos personales. |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_uaa_personal` (NONCLUSTERED) sobre `([uap_codigo] ASC)`

#### Restricciones de Integridad Referencial
**Claves Foráneas Explícitas (DDL):**
- `FK_uaa_personal_persona_agosto2018`: `uaa_personal.per_codigo` -> `[dbo].[persona](per_codigo)`
- `FK_uaa_personal_uaa_agosto2018`: `uaa_personal.uaa_codigo` -> `[dbo].[uaa](uaa_codigo)`

---

### 2.10 Entidad: `[dbo].[vinculacion]`

- **Submódulo Funcional:** Talento Humano, Nómina y Escalafón Docente
- **Archivo Fuente DDL:** `sql/dbo/vinculacion.sql`
- **Descripción Funcional:** Catálogo de modalidades contractuales y de vinculación del personal universitario (ej. Docente de Carrera / Planta, Ocasional de Tiempo Completo, Ocasional de Medio Tiempo, Catedrático).

#### Reglas de Negocio y Validación Operativa
- Determina el régimen prestacional, estabilidad y normatividad laboral aplicable.

#### Ciclo de Vida y Estados
Catálogo estático: `vin_estado = 1`.

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `vin_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Identificador único de la modalidad de vinculación. |
| 2 | `vin_nombre` | `varchar` | 50 | NO | - | **-** | Denominación oficial (Planta, Ocasional, Cátedra). |
| 3 | `vin_horas_year` | `int` | - | SÍ | - | **Temporal** | Total de horas laborales reglamentarias proyectadas al año para esta modalidad de vinculación profesoral o administrativa. |
| 4 | `vin_clase` | `int` | - | SÍ | - | **-** | Clasificación estatutaria de la vinculación (Docente de Carrera, Profesor Ocasional, Docente Catedrático, Personal Administrativo). |
| 5 | `sippa_vincodigo` | `char` | 3 | SÍ | - | **-** | Código de homologación del tipo de vinculación laboral en la base de datos externa legacy SIPPA. |
| 6 | `vin_contratacion` | `varchar` | 1 | SÍ | - | **-** | Modalidad jurídica de formalización laboral (Resolución Rectoral de nombramiento, Contrato individual de trabajo, Contrato de servicios). |
| 7 | `vin_externa` | `int` | - | SÍ | - | **-** | Bandera booleana (1/0) que clasifica si la vinculación corresponde a personal externo en comisión, adscripción interinstitucional o pasantía. |
| 8 | `vin_estado` | `int` | - | NO | - | **Estado** | Estado de vigencia del clasificador. |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_vinculacion` (NONCLUSTERED) sobre `([vin_codigo] ASC)`

#### Restricciones de Integridad Referencial
- **Claves Foráneas Explícitas:** Ninguna codificada en DDL.

---

### 2.11 Entidad: `[dbo].[dedicacion]`

- **Submódulo Funcional:** Talento Humano, Nómina y Escalafón Docente
- **Archivo Fuente DDL:** `sql/dbo/dedicacion.sql`
- **Descripción Funcional:** Catálogo de régimen de dedicación horaria semanal reglamentaria (Tiempo Completo 40 horas, Medio Tiempo 20 horas, Cátedra por horas).

#### Reglas de Negocio y Validación Operativa
- Fija el techo máximo de horas semanales (`ded_horas`) exigibles al docente.
- El servicio `ValidarCargaDocenteService` verifica que: Horas Lectivas + Horas Extensión + Horas Investigación <= `ded_horas`.

#### Ciclo de Vida y Estados
Catálogo estático: `ded_estado = 1`.

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `ded_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Identificador único de la dedicación. |
| 2 | `ded_nombre` | `varchar` | 50 | NO | - | **-** | Denominación (Tiempo Completo, Medio Tiempo, Cátedra). |
| 3 | `ded_orden_snies` | `smallint` | - | SÍ | - | **-** | Orden numérico o jerárquico asignado a la dedicación horaria para la remisión de estadísticas al SNIES del Ministerio de Educación. |
| 4 | `sippa_dedcodigo` | `char` | 1 | SÍ | - | **-** | Código de equivalencia de la dedicación docente en el sistema externo legacy SIPPA. |
| 5 | `ded_codigo_hecaa` | `smallint` | - | SÍ | - | **-** | Código de dedicación docente (Tiempo Completo, Medio Tiempo, Cátedra) establecido en el estándar de captura de información HECAA. |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_dedicacion` (CLUSTERED) sobre `([ded_codigo] ASC)`

#### Restricciones de Integridad Referencial
- **Claves Foráneas Explícitas:** Ninguna codificada en DDL.

---

### 2.12 Entidad: `[dbo].[escalafon]`

- **Submódulo Funcional:** Talento Humano, Nómina y Escalafón Docente
- **Archivo Fuente DDL:** `sql/dbo/escalafon.sql`
- **Descripción Funcional:** Catálogo institucional de categorías del escalafón docente universitario (Profesor Auxiliar, Asistente, Asociado, Titular).

#### Reglas de Negocio y Validación Operativa
- Define los puntos salariales base asociados a la categoría académica (`esc_puntos`).

#### Ciclo de Vida y Estados
Catálogo estático: `esc_estado = 1`.

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `esc_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Identificador de la categoría del escalafón. |
| 2 | `esc_nombre` | `varchar` | 50 | NO | - | **-** | Denominación de la categoría (Auxiliar, Asistente, Asociado, Titular). |
| 3 | `esc_cap_puntos` | `int` | - | SÍ | - | **-** | Puntaje salarial acumulativo o base asignado a la categoría del escalafón profesoral (Instructor, Asistente, Asociado, Titular). |
| 4 | `sippa_esccodigo` | `char` | 2 | SÍ | - | **-** | Código de homologación de la categoría de escalafón docente en el sistema externo legacy SIPPA. |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_escalafon` (CLUSTERED) sobre `([esc_codigo] ASC)`

#### Restricciones de Integridad Referencial
- **Claves Foráneas Explícitas:** Ninguna codificada en DDL.

---

### 2.13 Entidad: `[dbo].[docente_escalafon]`

- **Submódulo Funcional:** Talento Humano, Nómina y Escalafón Docente
- **Archivo Fuente DDL:** `sql/dbo/docente_escalafon.sql`
- **Descripción Funcional:** Historial de ascensos y promociones en el escalafón docente obtenidos por un profesor mediante actos administrativos oficiales.

#### Reglas de Negocio y Validación Operativa
- Vincula al docente (`per_codigo`) con la categoría alcanzada (`esc_codigo`).
- Registra fecha de ascenso (`doe_fecha`) y número de resolución del Comité de Asignación de Puntaje.

#### Ciclo de Vida y Estados
Histórico permanente de ascensos en la carrera profesoral.

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `doe_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Identificador único del registro de ascenso en escalafón. |
| 2 | `per_codigo` | `int` | - | SÍ | - | **FK Explícita** | Clave foránea explícita a la persona docente (`dbo.persona`). |
| 3 | `doe_fecha_inicio` | `datetime` | - | SÍ | - | **Temporal** | Fecha formal de posesión, ascenso o entrada en vigencia del docente en la respectiva categoría de la carrera profesoral. |
| 4 | `doe_fecha_fin` | `datetime` | - | SÍ | - | **Temporal** | Fecha de culminación o nuevo ascenso de escalafón que clausura la vigencia de la categoría anterior. |
| 5 | `esc_codigo` | `int` | - | NO | - | **FK Explícita** | Clave foránea explícita a la categoría alcanzada (`dbo.escalafon`). |
| 6 | `doe_documento` | `nvarchar` | 100 | SÍ | - | **-** | Número del acto administrativo, acuerdo o resolución del Comité de Asignación de Puntaje que reconoce y formaliza el escalafón. |
| 7 | `sippa_doccedula` | `char` | 11 | SÍ | - | **-** | Número de documento de identidad del docente en el sistema SIPPA vinculado al registro del escalafón. |
| 8 | `sippa_esccodigo` | `char` | 2 | SÍ | - | **-** | Código del escalafón docente en la base de datos externa legacy SIPPA. |
| 9 | `sippa_escfecini` | `datetime` | - | SÍ | - | **-** | Fecha de inicio de la categoría de escalafón registrada en el sistema legacy SIPPA. |
| 10 | `doe_puntos` | `float` | - | SÍ | - | **-** | Total consolidado de puntos salariales reconocidos al docente conforme a las disposiciones del Decreto 1279 y el Estatuto Docente. |
| 11 | `doe_puntos_fecha` | `datetime` | - | SÍ | - | **Temporal** | Fecha de expedición de la resolución del Comité Central de Puntaje que certificó la liquidación de puntos docentes. |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_docente_escalafon` (CLUSTERED) sobre `([doe_codigo] ASC)`

#### Restricciones de Integridad Referencial
**Claves Foráneas Explícitas (DDL):**
- `FK_docente_escalafon_escalafon`: `docente_escalafon.esc_codigo` -> `[dbo].[escalafon](esc_codigo)`
- `FK_docente_escalafon_persona`: `docente_escalafon.per_codigo` -> `[dbo].[persona](per_codigo)`

---

### 2.14 Entidad: `[dbo].[novedad]`

- **Submódulo Funcional:** Talento Humano, Nómina y Escalafón Docente
- **Archivo Fuente DDL:** `sql/dbo/novedad.sql`
- **Descripción Funcional:** Catálogo clasificador de tipos de novedades e incidencias laborales del personal (ej. Comisión de Estudios, Año Sabático, Incapacidad Médica, Licencia de Maternidad).

#### Reglas de Negocio y Validación Operativa
- Posee relación con el maestro externo `dbo.novedad_tipo` (`not_codigo`).

#### Ciclo de Vida y Estados
Catálogo estático: `nov_estado = 1`.

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `nov_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Identificador del tipo de novedad laboral. |
| 2 | `nov_nombre` | `varchar` | 300 | NO | - | **-** | Denominación de la novedad laboral. |
| 3 | `not_codigo` | `int` | - | NO | - | **FK Explícita** | Clave foránea explícita a `dbo.novedad_tipo`. |
| 4 | `nov_descarga_semanal` | `int` | - | SÍ | - | **-** | Intensidad horaria semanal estándar de descarga lectiva presencial autorizada por este concepto de novedad institucional. |
| 5 | `nov_descarga_semestral` | `int` | - | SÍ | - | **-** | Horas totales de docencia directa descargadas durante todo el semestre por causa de la novedad aprobada. |
| 6 | `nov_fecha_inicio` | `datetime` | - | SÍ | - | **Temporal** | Fecha oficial en la que entra en vigencia el reconocimiento de la novedad profesoral o administrativa. |
| 7 | `nov_fecha_fin` | `datetime` | - | SÍ | - | **Temporal** | Fecha en la que expira formalmente el plazo de disfrute de la novedad docente. |
| 8 | `nov_activa` | `char` | 1 | SÍ | - | **-** | Estado operativo de la novedad en el catálogo institucional ('A': Activa / Vigente, 'I': Inactiva). |
| 9 | `nov_valida` | `int` | - | SÍ | - | **-** | Bandera de validación algorítmica (1/0) que autoriza la aplicación de la novedad en la programación del período académico corriente. |
| 10 | `nov_descripcion` | `varchar` | 250 | SÍ | - | **-** | Detalle o fundamentación normativa de la novedad (ej. comisión de estudios remunerada, año sabático, representación sindical, cargo de dirección). |
| 11 | `nov_usar` | `int` | - | SÍ | - | **-** | Indicador binario (1/0) que define si la novedad se encuentra habilitada para ser seleccionada en las interfaces de programación académica. |
| 12 | `sippa_novcodigo` | `char` | 4 | SÍ | - | **-** | Código de integración de la novedad docente en el catálogo maestro del sistema legacy SIPPA. |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_novedad` (CLUSTERED) sobre `([nov_codigo] ASC)`

#### Restricciones de Integridad Referencial
**Claves Foráneas Explícitas (DDL):**
- `FK_novedad_novedad_tipo`: `novedad.not_codigo` -> `[dbo].[novedad_tipo](not_codigo)`

---

### 2.15 Entidad: `[dbo].[persona_novedad]`

- **Submódulo Funcional:** Talento Humano, Nómina y Escalafón Docente
- **Archivo Fuente DDL:** `sql/dbo/persona_novedad.sql`
- **Descripción Funcional:** Registro transaccional de novedades e incidencias temporales disfrutadas por un funcionario o docente en un periodo de fechas determinado.

#### Reglas de Negocio y Validación Operativa
- Asocia al docente (`per_codigo`) con el tipo de novedad (`nov_codigo`).
- Si el profesor tiene una novedad activa que suspenda actividades docentes, el sistema bloquea su asignación a cursos en `dbo.curso`.

#### Ciclo de Vida y Estados
Vigencia temporal: `pen_fecha_inicio <= NOW() <= pen_fecha_fin`.

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `pen_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Identificador único de la novedad de la persona. |
| 2 | `pen_persona` | `int` | - | NO | - | **FK Explícita** | Código de identificación de la persona (referencia a dbo.persona.per_codigo) favorecida con la novedad o descarga académica. |
| 3 | `uap_codigo` | `int` | - | SÍ | - | **FK Explícita** | Código de vinculación laboral específica del docente (dbo.uaa_personal) sobre la que se imputa la descarga horaria. |
| 4 | `nov_codigo` | `int` | - | NO | - | **FK Explícita** | Clave foránea explícita al tipo de novedad (`dbo.novedad`). |
| 5 | `pen_fecha_inicio` | `datetime` | - | SÍ | - | **Temporal** | Fecha inicial de vigencia de la novedad. |
| 6 | `pen_fecha_fin` | `datetime` | - | SÍ | - | **Temporal** | Fecha final de culminación de la novedad. |
| 7 | `per_codigo` | `int` | - | SÍ | - | **FK Explícita** | Clave foránea explícita a la persona beneficiaria (`dbo.persona`). |
| 8 | `pen_documento` | `char` | 10 | SÍ | - | **-** | Número de resolución rectoral o acto administrativo del Consejo de Facultad que confirió formalmente la novedad a la persona. |
| 9 | `pen_descripcion` | `nvarchar` | 500 | SÍ | - | **-** | Anotaciones circunstanciadas, compromisos académicos o justificación del otorgamiento de la novedad al docente. |
| 10 | `pen_semanas` | `char` | 10 | SÍ | - | **-** | Número efectivo de semanas lectivas durante las cuales opera la descarga de docencia directa para el docente. |
| 11 | `pen_descarga_semanal` | `int` | - | SÍ | - | **-** | Horas presenciales semanales de docencia efectivamente descargadas de la asignación del profesor. |
| 12 | `pen_descarga_semestral` | `int` | - | SÍ | - | **-** | Total de horas semestrales calculadas de descarga lectiva concedidas al docente por este concepto. |
| 13 | `pen_estado` | `int` | - | SÍ | - | **Estado** | Estado de la novedad. |
| 14 | `sippa_novcodigo` | `char` | 4 | SÍ | - | **-** | Código de la novedad en la base de datos externa legacy SIPPA. |
| 15 | `sippa_doccedula` | `char` | 11 | SÍ | - | **-** | Cédula de ciudadanía del docente beneficiario registrada en el sistema legacy SIPPA. |
| 16 | `sippa_percodigo` | `char` | 5 | SÍ | - | **-** | Código del período académico en el sistema SIPPA durante el cual surte efecto la novedad. |
| 17 | `sippa_novfecini` | `datetime` | - | SÍ | - | **-** | Fecha de inicio de la novedad profesoral registrada en el repositorio histórico de SIPPA. |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_persona_novedad` (CLUSTERED) sobre `([pen_codigo] ASC)`

#### Restricciones de Integridad Referencial
**Claves Foráneas Explícitas (DDL):**
- `FK_persona_novedad_novedad`: `persona_novedad.nov_codigo` -> `[dbo].[novedad](nov_codigo)`
- `FK_persona_novedad_persona`: `persona_novedad.pen_persona` -> `[dbo].[persona](per_codigo)`
- `FK_persona_novedad_uaa_personal`: `persona_novedad.uap_codigo` -> `[dbo].[uaa_personal](uap_codigo)`

---

### 2.16 Entidad: `[dbo].[grupo]`

- **Submódulo Funcional:** Seguridad y Roles de Usuario
- **Archivo Fuente DDL:** `sql/dbo/grupo.sql`
- **Descripción Funcional:** Catálogo de grupos funcionales y roles de seguridad institucional (ej. 'AD' Administradores, 'DC' Docentes, 'PF' Planta Física, 'JP' Jefes de Programa).

#### Reglas de Negocio y Validación Operativa
- Clave primaria de dos caracteres (`char(2)`).
- Utilizada por el motor de permisos y control de acceso RBAC.

#### Ciclo de Vida y Estados
Catálogo institucional permanente: `gru_estado = 1`.

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `gru_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Código alfanumérico del grupo de seguridad (PK char(2)). |
| 2 | `gru_nombre` | `varchar` | 100 | NO | - | **-** | Nombre descriptivo del rol o perfil institucional. |
| 3 | `gru_id` | `varchar` | 100 | SÍ | - | **-** | Identificador alfanumérico o clave textual alternativa del grupo institucional para integración con esquemas de autenticación y roles. |
| 4 | `gru_estado` | `int` | - | SÍ | - | **Estado** | Estado de vigencia del grupo. |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_grupo` (NONCLUSTERED) sobre `([gru_codigo] ASC)`

#### Restricciones de Integridad Referencial
- **Claves Foráneas Explícitas:** Ninguna codificada en DDL.

---

### 2.17 Entidad: `[dbo].[usuario_grupo]`

- **Submódulo Funcional:** Seguridad y Roles de Usuario
- **Archivo Fuente DDL:** `sql/dbo/usuario_grupo.sql`
- **Descripción Funcional:** Tabla asociativa que otorga roles y privilegios de seguridad asignando usuarios institucionales a grupos funcionales.

#### Reglas de Negocio y Validación Operativa
- Conecta un usuario institucional (`uid`) con un rol o grupo (`gru_codigo`).
- Gobernada por el módulo de autenticación del sistema.

#### Ciclo de Vida y Estados
Vigencia de membresía: `usg_estado = 1`.

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `usg_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Identificador único de membresía de usuario en grupo. |
| 2 | `usg_usuario` | `int` | - | SÍ | - | **-** | Identificador de la persona o cuenta de usuario institucional a la que se le asignan los privilegios del grupo (dbo.persona). |
| 3 | `usg_grupo` | `int` | - | SÍ | - | **-** | Código del grupo o perfil de seguridad institucional asignado al usuario (referencia a dbo.grupo.gru_codigo). |
| 4 | `usg_uaa` | `int` | - | SÍ | - | **-** | Código de la Unidad Académico-Administrativa sobre la cual se circunscriben y delegan los permisos operativos del usuario (dbo.uaa). |
| 5 | `usg_estado` | `tinyint` | - | SÍ | - | **Estado** | Estado de vigencia del rol otorgado. |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_usuario_grupo` (CLUSTERED) sobre `([usg_codigo] ASC)`

#### Restricciones de Integridad Referencial
- **Claves Foráneas Explícitas:** Ninguna codificada en DDL.

---

### 2.18 Entidad: `[dbo].[proyecto]`

- **Submódulo Funcional:** Investigación y Proyectos Institucionales
- **Archivo Fuente DDL:** `sql/dbo/proyecto.sql`
- **Descripción Funcional:** Banco institucional de proyectos de investigación formalmente aprobados por la Vicerrectoría de Investigaciones.

#### Reglas de Negocio y Validación Operativa
- Tipificado por `prt_codigo` (`dbo.proyecto_tipo`) y con estado `pre_codigo` en `dbo.proyecto_estado` (maestro externo).
- Permite a los docentes descargar horas dedicadas a investigación.

#### Ciclo de Vida y Estados
Fases: Radicado -> Evaluación -> Aprobado en Ejecución -> Liquidado / Publicado.

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `pry_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Clave primaria e identificador del proyecto de investigación. |
| 2 | `gru_codigo` | `int` | - | SÍ | - | **FK Explícita** | Código del grupo de investigación institucional avalado por MinCiencias que respalda y ejecuta el proyecto (dbo.grupo). |
| 3 | `pry_nombre` | `varchar` | 300 | NO | - | **-** | Título o denominación formal de la investigación. |
| 4 | `prt_codigo` | `int` | - | NO | - | **FK Explícita** | Clave foránea explícita al tipo de proyecto (`dbo.proyecto_tipo`). |
| 5 | `pry_coordinador` | `int` | - | SÍ | - | **-** | Código de persona del docente o investigador que ejerce como Investigador Principal y coordinador general del proyecto. |
| 6 | `pry_fecha_inicio` | `datetime` | - | SÍ | - | **Temporal** | Fecha oficial de inicio de ejecución del proyecto. |
| 7 | `pry_fecha_fin` | `datetime` | - | SÍ | - | **Temporal** | Fecha proyectada o real de cierre del proyecto. |
| 8 | `pry_cvlac` | `char` | 10 | SÍ | - | **-** | Identificador alfanumérico del perfil de hoja de vida en la plataforma CvLAC de MinCiencias del coordinador del proyecto. |
| 9 | `pry_resultados` | `varchar` | 200 | SÍ | - | **-** | Síntesis de los productos tangibles de investigación esperados (artículos científicos indexados, patentes, software o ponencias). |
| 10 | `pry_colciencias` | `int` | - | SÍ | - | **-** | Código de radicación, registro o contrato del proyecto ante MinCiencias / Colciencias en convocatorias nacionales. |
| 11 | `pry_resumen` | `varchar` | 200 | SÍ | - | **-** | Resumen ejecutivo o abstract del proyecto de investigación donde se delimitan objetivos, marco conceptual y alcance. |
| 12 | `pry_objetivo` | `varchar` | 200 | SÍ | - | **-** | Objetivo general y metas científicas que orientan la ejecución y desarrollo de la investigación. |
| 13 | `pre_codigo` | `int` | - | SÍ | - | **FK Explícita** | Clave foránea explícita al estado del proyecto (`dbo.proyecto_estado`). |
| 14 | `pry_duracionestimada` | `smallint` | - | SÍ | - | **-** | Plazo o duración estimada para la ejecución del proyecto de investigación expresada en meses calendario. |
| 15 | `pry_acto_administrativo` | `nchar` | 50 | SÍ | - | **-** | Número del acto administrativo o resolución de la Vicerrectoría de Investigación y Posgrados que aprobó y financió la propuesta. |
| 16 | `pry_acto_administrativo_fecha` | `datetime` | - | SÍ | - | **Temporal** | Fecha oficial de expedición de la resolución de aprobación institucional del proyecto investigativo. |
| 17 | `pry_acta_aprobacion` | `nvarchar` | 500 | SÍ | - | **-** | Número de acta del Comité Central de Investigaciones o Consejo de Facultad que evaluó y recomendó favorablemente el proyecto. |
| 18 | `pry_justificacion_beneficio` | `nvarchar` | 4000 | SÍ | - | **-** | Argumentación sobre la pertinencia científica, impacto social, transferencia tecnológica y aportes institucionales derivados del proyecto. |
| 19 | `pry_secretario_administrativo` | `int` | - | SÍ | - | **-** | Código de persona del funcionario o secretario que ejerce la supervisión administrativa y financiera sobre los recursos del proyecto. |
| 20 | `pry_decano` | `int` | - | SÍ | - | **-** | Código de persona del Decano de la facultad que suscribe el aval institucional para el desarrollo del proyecto. |
| 21 | `pry_facultad` | `int` | - | SÍ | - | **-** | Código de la facultad o UAA matriz a la que está formalmente adscrita la línea y ejecución del proyecto de investigación. |
| 22 | `prs_codigo` | `int` | - | SÍ | - | **-** | Código del subtipo o clasificación temática y metodológica del proyecto de investigación según líneas prioritarias. |
| 23 | `prc_codigo` | `int` | - | SÍ | - | **-** | Código de la clase o naturaleza de la investigación (investigación básica, investigación aplicada, desarrollo experimental). |
| 24 | `sippa_proycodigo` | `char` | 10 | SÍ | - | **-** | Código de homologación del proyecto de investigación en el sistema externo legacy SIPPA. |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_proyecto` (NONCLUSTERED) sobre `([pry_codigo] ASC)`

#### Restricciones de Integridad Referencial
**Claves Foráneas Explícitas (DDL):**
- `FK_proyecto_grupo`: `proyecto.gru_codigo` -> `[dbo].[grupo](gru_codigo)`
- `FK_proyecto_proyecto_estado`: `proyecto.pre_codigo` -> `[dbo].[proyecto_estado](pre_codigo)`
- `FK_proyecto_proyecto_tipo`: `proyecto.prt_codigo` -> `[dbo].[proyecto_tipo](prt_codigo)`

---

### 2.19 Entidad: `[dbo].[proyecto_tipo]`

- **Submódulo Funcional:** Investigación y Proyectos Institucionales
- **Archivo Fuente DDL:** `sql/dbo/proyecto_tipo.sql`
- **Descripción Funcional:** Catálogo de clasificación de proyectos de investigación (Convocatoria Interna, Colciencias, Cooperación Internacional, Fondo de Regalías).

#### Reglas de Negocio y Validación Operativa
- Clasificador maestro consultado por el banco de proyectos.

#### Ciclo de Vida y Estados
Catálogo estático: `prt_estado = 1`.

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `prt_codigo` | `int` | - | NO | - | **PK** | Identificador del tipo de investigación. |
| 2 | `prt_nombre` | `varchar` | 50 | SÍ | - | **-** | Denominación del tipo de proyecto. |
| 3 | `sippa_tiproycodigo` | `char` | 2 | SÍ | - | **-** | Código del tipo de proyecto homologado en las tablas del sistema externo legacy SIPPA. |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_proyecto_tipo` (NONCLUSTERED) sobre `([prt_codigo] ASC)`

#### Restricciones de Integridad Referencial
- **Claves Foráneas Explícitas:** Ninguna codificada en DDL.

---

### 2.20 Entidad: `[dbo].[persona_proyecto]`

- **Submódulo Funcional:** Investigación y Proyectos Institucionales
- **Archivo Fuente DDL:** `sql/dbo/persona_proyecto.sql`
- **Descripción Funcional:** Registra la vinculación de docentes e investigadores a proyectos de investigación institucional con asignación de horas semanales.

#### Reglas de Negocio y Validación Operativa
- Clave primaria compuesta por `(pep_codigo, pry_codigo)`.
- Conecta al docente (`per_codigo`) con el proyecto (`pry_codigo`) y su rol (`prr_codigo` en `dbo.proyecto_rol`).
- Fija las horas semanales dedicadas a investigación (`pep_horas`).

#### Ciclo de Vida y Estados
Vigencia durante el cronograma de ejecución del proyecto.

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `pep_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Parte de la PK: Identificador secuencial de participación. |
| 2 | `pry_codigo` | `int` | - | NO | - | **PK** | Parte de la PK: Clave foránea al proyecto contenedor (`dbo.proyecto`). |
| 3 | `pep_persona` | `int` | - | NO | - | **FK Explícita** | Código de identificación de la persona asignada al equipo de investigación del proyecto (dbo.persona.per_codigo). |
| 4 | `uap_codigo` | `int` | - | SÍ | - | **-** | Código de la vinculación laboral del docente o funcionario (dbo.uaa_personal) sobre la cual se respalda su participación. |
| 5 | `pep_hora_semana` | `smallint` | - | NO | - | **Temporal** | Intensidad horaria presencial semanal comprometida formalmente por el docente para labores de investigación en el proyecto. |
| 6 | `pep_semanas` | `smallint` | - | NO | - | **-** | Número de semanas lectivas del período durante las cuales el docente participará activamente en el proyecto. |
| 7 | `pep_descarga_semestral` | `int` | - | SÍ | - | **-** | Total consolidado de horas semestrales de descarga lectiva conferidas al docente por su labor en el proyecto investigativo. |
| 8 | `per_codigo` | `int` | - | NO | - | **FK Explícita** | Clave foránea explícita al investigador (`dbo.persona`). |
| 9 | `pep_cargo` | `int` | - | SÍ | - | **-** | Rol o función investigativa desempeñada en el equipo del proyecto (ej. Coinvestigador, Asistente de Investigación, Auxiliar). |
| 10 | `con_contrato` | `varchar` | 50 | SÍ | - | **-** | Número del contrato de prestación de servicios, adenda o convenio específico que ampara la vinculación de la persona al proyecto. |
| 11 | `prr_codigo` | `int` | - | SÍ | - | **FK Explícita** | Clave foránea explícita al rol (`dbo.proyecto_rol`). |
| 12 | `sippa_proydocente` | `char` | 11 | SÍ | - | **-** | Número de cédula o identificador del docente investigador en el sistema legacy SIPPA. |
| 13 | `sippa_proycodigo` | `char` | 10 | SÍ | - | **-** | Código del proyecto de investigación en el sistema externo legacy SIPPA. |
| 14 | `sippa_percodigo` | `char` | 5 | SÍ | - | **-** | Código del período académico en SIPPA durante el cual se registra la dedicación al proyecto. |
| 15 | `sippa_proyfecini` | `datetime` | - | SÍ | - | **-** | Fecha de inicio de la vinculación del docente al proyecto registrada en el sistema legacy SIPPA. |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_proyecto_persona` (NONCLUSTERED) sobre `([pep_codigo] ASC,
	[pry_codigo] ASC)`

#### Restricciones de Integridad Referencial
**Claves Foráneas Explícitas (DDL):**
- `FK_persona_proyecto_persona`: `persona_proyecto.pep_persona` -> `[dbo].[persona](per_codigo)`
- `FK_persona_proyecto_proyecto_rol`: `persona_proyecto.prr_codigo` -> `[dbo].[proyecto_rol](prr_codigo)`
- `FK_proyecto_persona_proyecto`: `persona_proyecto.pry_codigo` -> `[dbo].[proyecto](pry_codigo)`

---

### 2.21 Entidad: `[proyectos].[proyecto_proyeccion_social]`

- **Submódulo Funcional:** Proyección Social y Extensión Universitaria
- **Archivo Fuente DDL:** `sql/proyectos/proyecto_proyeccion_social.sql`
- **Descripción Funcional:** Banco de iniciativas, programas y proyectos de proyección social, extensión comunitaria y consultoría externa adscritos a la Dirección de Extensión.

#### Reglas de Negocio y Validación Operativa
- Radicada en el esquema satélite `proyectos`.
- Se adscribe formalmente a una UAA promotora (`uaa_pertenece` hacia `dbo.uaa`) y a un municipio de impacto (`mun_codigo` hacia `dbo.municipio`).
- Posee 8 relaciones de clave foránea hacia catálogos maestros de extensión (`ps_area_extension`, `ps_nbc_colciencias`, `ps_semilleros`, etc.).

#### Ciclo de Vida y Estados
Ciclo de vida: Formulación -> Aprobado por Consejo de Facultad -> En Ejecución -> Liquidado / Culminado.

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `pps_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Clave primaria e identificador de la iniciativa de proyección social. |
| 2 | `pps_titulo` | `varchar` | 300 | SÍ | - | **-** | Título oficial del proyecto de extensión o impacto comunitario. |
| 3 | `pra_codigo` | `int` | - | SÍ | - | **FK Explícita** | Clave foránea explícita al área macro (`proyectos.mc_proyecto_area`). |
| 4 | `oap_codigo` | `int` | - | SÍ | - | **FK Explícita** | Clave foránea explícita al origen de área (`proyectos.ps_origen_area_proyecto`). |
| 5 | `pst_codigo` | `int` | - | SÍ | - | **FK Explícita** | Clave foránea explícita a la tipología (`proyectos.ps_proyecto_tipo`). |
| 6 | `otp_codigo` | `int` | - | SÍ | - | **FK Explícita** | Clave foránea explícita al tipo de origen (`proyectos.ps_origen_tipo_proyecto`). |
| 7 | `pps_grupolac` | `varchar` | 150 | SÍ | - | **-** | Enlace o identificador del grupo de investigación registrado en la plataforma GrupLAC de MinCiencias que lidera la proyección social. |
| 8 | `nco_codigo` | `int` | - | SÍ | - | **FK Explícita** | Clave foránea explícita al área Colciencias (`proyectos.ps_nbc_colciencias`). |
| 9 | `pps_fecha_inicio` | `date` | - | SÍ | - | **Temporal** | Fecha formal de inicio de ejecución de las actividades de extensión y proyección social en la comunidad. |
| 10 | `pps_fecha_fin` | `date` | - | SÍ | - | **Temporal** | Fecha programada de culminación y entrega de resultados del proyecto de proyección social. |
| 11 | `mun_codigo` | `int` | - | SÍ | - | **FK Explícita** | Clave foránea explícita al municipio de ejecución (`dbo.municipio.mun_codigo`). |
| 12 | `pps_palabras_claves` | `varchar` | 200 | SÍ | - | **-** | Términos clave y descriptores temáticos del proyecto para facilitar su indexación, divulgación y recuperación en repositorios institucionales. |
| 13 | `pps_objetivo_general` | `varchar` | max | SÍ | - | **-** | Propósito central o meta global de impacto social y transferencia comunitaria que persigue el proyecto de extensión. |
| 14 | `pps_resumen` | `varchar` | max | SÍ | - | **-** | Síntesis ejecutiva de la propuesta del proyecto de proyección social, delimitando problemática, población y alcance. |
| 15 | `pps_metodologia` | `varchar` | max | SÍ | - | **-** | Descripción de las estrategias pedagógicas, fases operativas, talleres e instrumentos de intervención comunitaria a desplegar. |
| 16 | `prc_codigo` | `int` | - | SÍ | - | **FK Explícita** | Clave foránea explícita a la clase de proyecto (`proyectos.mc_proyecto_clase`). |
| 17 | `pre_codgo` | `int` | - | SÍ | - | **-** | Código del estado operativo y de avance del proyecto de proyección social (referencia a dbo.proyecto_estado). |
| 18 | `pps_descripcion_producto` | `varchar` | 200 | SÍ | - | **-** | Detalle cuantitativo y cualitativo de los bienes, servicios, cartillas, prototipos o capacitaciones generadas para la comunidad. |
| 19 | `pps_beneficiarios` | `varchar` | 200 | SÍ | - | **-** | Caracterización de los grupos poblacionales, organizaciones comunitarias, sectores vulnerables o gremios receptores del proyecto. |
| 20 | `pps_impactoxuso_esperado` | `varchar` | 200 | SÍ | - | **-** | Impactos sociales, económicos o ambientales esperados y apropiación social del conocimiento proyectada en el territorio. |
| 21 | `pps_supuestos_basicos` | `varchar` | 200 | SÍ | - | **-** | Condiciones de entorno, premisas de estabilidad social y supuestos requeridos para el cumplimiento satisfactorio del proyecto. |
| 22 | `pps_plazo_materializacion` | `varchar` | 10 | SÍ | - | **-** | Horizonte temporal en el que se proyecta la consolidación de los beneficios sociales del proyecto (corto, mediano o largo plazo). |
| 23 | `pps_probabilidad_ocurrencia` | `varchar` | 10 | SÍ | - | **-** | Calificación cualitativa o nivel de probabilidad de ocurrencia de los riesgos y supuestos previstos en la formulación. |
| 24 | `pps_acto_administrativo` | `varchar` | 50 | SÍ | - | **-** | Número del acto administrativo institucional (resolución de Vicerrectoría) que aprobó y ordenó la ejecución de la iniciativa de proyección social. |
| 25 | `pps_acto_administrativo_fecha` | `datetime` | - | SÍ | - | **Temporal** | Fecha de expedición oficial de la resolución que concede el aval y presupuesto al proyecto de proyección social. |
| 26 | `pps_acta_aprobacion` | `varchar` | 500 | SÍ | - | **-** | Número de acta del Consejo de Facultad o Comité de Proyección Social que evaluó y aprobó la viabilidad de la propuesta. |
| 27 | `pps_justificacion_beneficio` | `varchar` | max | SÍ | - | **-** | Fundamentación de la pertinencia social, justificación comunitaria y valor público aportado por el proyecto a la región. |
| 28 | `pps_secretario_administrativo` | `int` | - | SÍ | - | **-** | Código de persona del Secretario Administrativo de la facultad encargado del seguimiento financiero y legal del proyecto. |
| 29 | `pps_decano` | `int` | - | SÍ | - | **-** | Código de persona del Decano de la facultad responsable que suscribe el aval institucional ante la Vicerrectoría. |
| 30 | `pps_facultad` | `int` | - | SÍ | - | **-** | Código de la facultad o UAA mayor donde está radicado el proyecto de proyección social (referencia a dbo.uaa). |
| 31 | `pps_coordinador` | `int` | - | SÍ | - | **-** | Código de persona del docente que actúa como Director o Coordinador principal del proyecto de proyección social. |
| 32 | `pps_solicitante_servicio` | `varchar` | 200 | SÍ | - | **-** | Nombre o entidad externa, alcaldía, junta comunal o gremio que demandó o solicitó el acompañamiento de proyección social. |
| 33 | `pps_obs_cumplimiento_actividades` | `varchar` | 200 | SÍ | - | **-** | Informe cualitativo y observaciones sobre el porcentaje de cumplimiento y ejecución de las metas programadas en el cronograma. |
| 34 | `pps_obs_consolidacion_resultados` | `varchar` | 200 | SÍ | - | **-** | Concepto técnico final sobre la consolidación de resultados, productos entregados e indicadores de satisfacción comunitaria. |
| 35 | `migracion_pry_codigo` | `int` | - | SÍ | - | **-** | Identificador previo del proyecto en el repositorio anterior migrado hacia la estructura especializada de proyectos. |
| 36 | `uaa_pertenece` | `int` | - | SÍ | - | **-** | Clave foránea explícita a la UAA promotora (`dbo.uaa.uaa_codigo`). |
| 37 | `pps_fecha_registro` | `datetime` | - | SÍ | - | **Temporal** | Marca temporal de auditoría en la que se radicó formalmente la propuesta del proyecto en el aplicativo web. |
| 38 | `pps_pregunta` | `varchar` | max | SÍ | - | **-** | Pregunta orientadora o planteamiento del reto comunitario central que el proyecto pretende resolver con la intervención. |
| 39 | `pps_marco_teorico` | `varchar` | max | SÍ | - | **-** | Fundamentación conceptual, teórica y antecedentes de intervención comunitaria que sustentan la metodología del proyecto. |
| 40 | `pps_grupo` | `int` | - | SÍ | - | **-** | Código de identificación del grupo o colectivo de investigación institucional que soporta la propuesta de extensión. |
| 41 | `pps_justificacion` | `varchar` | max | SÍ | - | **-** | Exposición de motivos sociales, académicos e institucionales que sustentan la necesidad y viabilidad de realizar el proyecto. |
| 42 | `pps_estado` | `int` | - | SÍ | - | **Estado** | Estado de ejecución de la iniciativa social. |
| 43 | `pps_convocatoria` | `int` | - | SÍ | - | **-** | Código o número de la convocatoria institucional interna o externa bajo la cual fue postulado y financiado el proyecto. |
| 44 | `pps_tipoproyecto` | `int` | - | SÍ | - | **-** | Código del tipo o modalidad de proyecto de proyección social (Asesoría comunitaria, Consultoría técnica, Educación continuada, Intervención social). |
| 45 | `pps_bibliografia` | `varchar` | max | SÍ | - | **-** | Referencias documentales, fuentes bibliográficas y normatividad legal que fundamentan el marco del proyecto. |
| 46 | `pps_responsable_admin` | `int` | - | SÍ | - | **-** | Código del funcionario o profesional responsable de la administración y ejecución de rubros presupuestales del proyecto. |
| 47 | `beneficiarios` | `varchar` | max | SÍ | - | **-** | Texto ampliado de caracterización sociodemográfica y cuantificación de las comunidades directamente beneficiadas por las actividades. |
| 48 | `localizacion` | `varchar` | max | SÍ | - | **-** | Descripción textual detallada de la ubicación espacial, comunas, veredas, corregimientos o barrios donde se desarrollan las jornadas. |
| 49 | `contenidos_academicos` | `varchar` | max | SÍ | - | **-** | Ejes temáticos, módulos pedagógicos o contenidos curriculares transferidos a la comunidad en el marco de la proyección social. |
| 50 | `pps_fecha_aprobacion_desaprobacion` | `datetime` | - | SÍ | - | **Temporal** | Fecha y hora formal en la que la instancia decisoria dictaminó la aprobación o no aprobación del proyecto presentado. |
| 51 | `pps_fecha_actualizacion` | `datetime` | - | SÍ | - | **Temporal** | Marca temporal de la última actualización efectuada sobre la ficha descriptiva y plan operativo del proyecto. |
| 52 | `pps_aplicacion` | `varchar` | 50 | SÍ | - | **-** | Nombre o subsistema del aplicativo institucional desde el cual se registró o modificó la información del proyecto. |
| 53 | `pps_ip` | `varchar` | 50 | SÍ | - | **-** | Dirección IP del equipo o terminal desde la cual se diligenció o actualizó el expediente electrónico del proyecto. |
| 54 | `pps_observacion_modificacion` | `varchar` | max | SÍ | - | **-** | Registro de justificación y trazabilidad de los ajustes presupuestales, prórrogas o modificaciones al plan de trabajo autorizadas. |
| 55 | `pps_planteamiento_problema` | `varchar` | max | SÍ | - | **-** | Diagnóstico situacional y formulación precisa de la problemática social, necesidad insatisfecha o conflicto comunitario a intervenir. |
| 56 | `pps_linea_estrategica` | `int` | - | SÍ | - | **-** | Código de la línea estratégica del Plan de Desarrollo Institucional (PDI) con la cual se articula misionalmente el proyecto. |
| 57 | `pps_localizacion_municipio` | `int` | - | SÍ | - | **-** | Código del municipio geográfico en el que se focalizan las acciones de proyección social (referencia a dbo.municipio). |
| 58 | `pps_area_trabajo` | `int` | - | SÍ | - | **-** | Área temática o sectorial de desarrollo comunitario al que tributa la iniciativa (salud comunitaria, medio ambiente, educación, desarrollo económico). |
| 59 | `pps_linea_investigacion` | `int` | - | SÍ | - | **-** | Código de la línea de investigación institucional a la cual se vincula académicamente el proyecto de proyección social. |
| 60 | `are_codigo` | `int` | - | SÍ | - | **FK Explícita** | Clave foránea explícita al área de extensión (`proyectos.ps_area_extension`). |
| 61 | `stp_codigo` | `int` | - | SÍ | - | **FK Explícita** | Clave foránea explícita al subtipo (`proyectos.ps_sub_tipo_proyecto`). |
| 62 | `pps_semillero` | `int` | - | SÍ | - | **FK Explícita** | Clave foránea explícita al semillero adscrito (`proyectos.ps_semilleros`). |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_proyecto_proyeccion_social` (CLUSTERED) sobre `([pps_codigo] ASC)`

#### Restricciones de Integridad Referencial
**Claves Foráneas Explícitas (DDL):**
- `FK_proyecto_proyeccion_social_mc_proyecto_area`: `proyecto_proyeccion_social.pra_codigo` -> `[proyectos].[mc_proyecto_area](pra_codigo)`
- `FK_proyecto_proyeccion_social_mc_proyecto_clase`: `proyecto_proyeccion_social.prc_codigo` -> `[proyectos].[mc_proyecto_clase](prc_codigo)`
- `FK_proyecto_proyeccion_social_municipio`: `proyecto_proyeccion_social.mun_codigo` -> `[dbo].[municipio](mun_codigo)`
- `FK_proyecto_proyeccion_social_nbc_colciencias`: `proyecto_proyeccion_social.nco_codigo` -> `[proyectos].[ps_nbc_colciencias](nco_codigo)`
- `FK_proyecto_proyeccion_social_origen_area_proyecto`: `proyecto_proyeccion_social.oap_codigo` -> `[proyectos].[ps_origen_area_proyecto](oap_codigo)`
- `FK_proyecto_proyeccion_social_origen_tipo_proyecto`: `proyecto_proyeccion_social.otp_codigo` -> `[proyectos].[ps_origen_tipo_proyecto](otp_codigo)`
- `FK_proyecto_proyeccion_social_proyecto_proyeccion_social`: `proyecto_proyeccion_social.pps_codigo` -> `[proyectos].[proyecto_proyeccion_social](pps_codigo)`
- `FK_proyecto_proyeccion_social_proyecto_proyeccion_social_tipo`: `proyecto_proyeccion_social.pst_codigo` -> `[proyectos].[ps_proyecto_tipo](pst_codigo)`
- `FK_proyecto_proyeccion_social_ps_semillero`: `proyecto_proyeccion_social.pps_semillero` -> `[proyectos].[ps_semilleros](pss_codigo)`
- `FK_ps_area_extension`: `proyecto_proyeccion_social.are_codigo` -> `[proyectos].[ps_area_extension](are_codigo)`
- `FK_sub_tipo_proyecto`: `proyecto_proyeccion_social.stp_codigo` -> `[proyectos].[ps_sub_tipo_proyecto](stp_codigo)`

---

### 2.22 Entidad: `[proyectos].[docentexproyecto_proyeccion_social]`

- **Submódulo Funcional:** Proyección Social y Extensión Universitaria
- **Archivo Fuente DDL:** `sql/proyectos/docentexproyecto_proyeccion_social.sql`
- **Descripción Funcional:** Entidad clave de enlace inter-esquemas (`proyectos` -> `dbo`). Modela la descarga horaria semanal otorgada a los docentes para participar en proyectos de extensión comunitaria.

#### Reglas de Negocio y Validación Operativa
- Conecta un proyecto de extensión (`pps_codigo`) con el contrato del docente en `dbo.uaa_personal` (`uap_codigo`).
- Almacena las horas semanales descargadas de docencia (`dpp_horas_descarga`).
- El servicio `ValidarCargaDocenteService.php` consulta esta tabla de forma estricta para garantizar que la descarga no vulnere la disponibilidad del docente al programar cursos.

#### Ciclo de Vida y Estados
Vigencia durante el periodo activo de la descarga docente.

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `id_docentesxproyecto` | `int` | - | NO | IDENTITY(1,1) | **PK** | Clave primaria secuencial de la asignación profesoral en el proyecto. |
| 2 | `uap_codigo` | `int` | - | NO | - | **FK Explícita** | Clave foránea explícita al contrato docente en nómina (`dbo.uaa_personal.uap_codigo`). |
| 3 | `pps_codigo` | `int` | - | NO | - | **FK Explícita** | Clave foránea explícita al proyecto social (`proyectos.proyecto_proyeccion_social`). |
| 4 | `prp_codigo` | `int` | - | SÍ | - | **FK Explícita** | Clave foránea explícita al rol de participación (`proyectos.proyeccion_rolxproyecto`). |
| 5 | `dpp_horas_descarga` | `int` | - | SÍ | - | **Temporal** | Horas semanales formalmente descargadas de la labor docente frente a grupo. |
| 6 | `dpp_horas_sindescarga` | `int` | - | SÍ | - | **Temporal** | Horas semanales dedicadas por el docente a las labores del proyecto sin representar descarga de docencia directa (dedicación complementaria o ad honorem). |
| 7 | `nco_codigo` | `int` | - | SÍ | - | **FK Explícita** | Clave foránea explícita a la clasificación Colciencias (`proyectos.ps_nbc_colciencias`). |
| 8 | `dpp_descarga_aprobada` | `int` | - | SÍ | - | **-** | Total de horas semanales de descarga de docencia directa formalmente avaladas y aprobadas por el Consejo de Facultad. |
| 9 | `dpp_sindescarga_aprobada` | `int` | - | SÍ | - | **-** | Total de horas de dedicación docente sin descarga lectiva avaladas para el plan de trabajo profesoral del período. |
| 10 | `dpp_periodo` | `int` | - | SÍ | - | **-** | Código del período académico en el cual se ejecuta la participación del docente en las actividades de proyección social. |
| 11 | `dpp_numero_semanas` | `int` | - | SÍ | - | **-** | Cantidad de semanas lectivas efectivas en las que el profesor desempeñará sus compromisos de proyección social en el período. |
| 12 | `dpp_horas_semana` | `int` | - | SÍ | - | **Temporal** | Intensidad horaria presencial semanal pactada para la ejecución de las tareas y talleres de proyección social por parte del docente. |
| 13 | `dpp_observacion` | `varchar` | 5000 | SÍ | - | **-** | Anotaciones, metas acordadas o justificación detallada de las funciones y responsabilidades encomendadas al docente en el proyecto. |
| 14 | `migracion_persona` | `int` | - | SÍ | - | **-** | Código identificador de la persona bajo el esquema de la base de datos histórica previa a la migración. |
| 15 | `migracion_periodo` | `int` | - | SÍ | - | **-** | Código del período académico en el sistema anterior conservado para trazabilidad histórica de la carga docente. |
| 16 | `migracion_uap` | `int` | - | SÍ | - | **-** | Código de vinculación laboral docente (uap_codigo) en el repositorio institucional previo a la homologación. |
| 17 | `migracion_horas_semana` | `smallint` | - | SÍ | - | **Temporal** | Horas semanales de dedicación que figuraban registradas en el sistema legacy antes del proceso de migración de datos. |
| 18 | `migracion_semanas` | `smallint` | - | SÍ | - | **-** | Duración en semanas registrada en el histórico migrado para la participación del docente. |
| 19 | `migracion_observacion` | `varchar` | 300 | SÍ | - | **-** | Observaciones de homologación o conciliación de datos asentadas durante el proceso de migración tecnológica. |
| 20 | `dpp_estado` | `bit` | - | SÍ | - | **Estado** | Estado de vigencia de la descarga docente (1: Activa, 0: Finalizada). |
| 21 | `derecho_mencion` | `int` | - | SÍ | - | **-** | Bandera clasificatoria (0/1) que determina si la participación docente en el proyecto confiere derecho a reconocimiento o mención de honor en producción académica. |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_docentexproyecto_proyeccion_social_1` (CLUSTERED) sobre `([id_docentesxproyecto] ASC)`

#### Restricciones de Integridad Referencial
**Claves Foráneas Explícitas (DDL):**
- `FK_docentexproyecto_proyeccion_social_nbc_colciencias`: `docentexproyecto_proyeccion_social.nco_codigo` -> `[proyectos].[ps_nbc_colciencias](nco_codigo)`
- `FK_docentexproyecto_proyeccion_social_proyeccion_rolxproyecto`: `docentexproyecto_proyeccion_social.prp_codigo` -> `[proyectos].[proyeccion_rolxproyecto](prp_codigo)`
- `FK_docentexproyecto_proyeccion_social_proyecto_proyeccion_social`: `docentexproyecto_proyeccion_social.pps_codigo` -> `[proyectos].[proyecto_proyeccion_social](pps_codigo)`
- `FK_docentexproyecto_proyeccion_social_uaa_personal`: `docentexproyecto_proyeccion_social.uap_codigo` -> `[dbo].[uaa_personal](uap_codigo)`

---

### 2.23 Entidad: `[dbo].[programacion_proceso]`

- **Submódulo Funcional:** Núcleo de Planificación y Fases del Proceso de Programación Académica
- **Archivo Fuente DDL:** `sql/dbo/programacion_proceso.sql`
- **Descripción Funcional:** Catálogo maestro institucional que define y tipifica las etapas, fases u hitos operativos secuenciales que estructuran el ciclo de programación académica semestral (por ejemplo: 1. Asignaturas Institucionales, 2. Electivas de Facultad, 3. Asignaturas de Programa, 4. Repesca / Ajustes extemporáneos). Constituye la dimensión de proceso requerida por `programacionacademica.programacion_academica` para habilitar temporalmente la captura, modificación y oferta de cursos a las unidades académicas según la naturaleza curricular de las materias.

#### Reglas de Negocio y Validación Operativa
- **Secuencialidad y Prelación del Flujo (`prp_orden`):** Cada etapa cuenta con un número ordinal de orden (`prp_orden`) que determina la secuencia metodológica en que las unidades académicas deben cargar su oferta (primero materias transversales institucionales, luego núcleos comunes de facultad, posteriormente asignaturas disciplinares de carrera y finalmente ajustes/repesca). Las consultas del sistema ordenan las aperturas cronológicamente mediante `ORDER BY prp.prp_orden ASC` (`Aperfe.php:970`).
- **Filtrado Curricular por Núcleos (`nuc_codigo`):** El campo `nuc_codigo` asocia la fase operativa con uno o varios núcleos temáticos de formación (`dbo.nucleo`). En el motor de creación y gestión de cursos (`Curcrea.php:532-616`), este valor delimita de forma estricta qué asignaturas (`asi.nuc_codigo IN ({$NucCodigo})`) pueden ser ofertadas en la ventana de captura activa.
- **Restricción Operativa de Repesca (`prp_codigo = 4`):** El motor transaccional de horarios (`Curhorario.php:41-49`) y de creación de cursos (`Curcrea.php:40-48`) implementa la validación obligatoria `validarProcesoSeleccionable($PrpCodigo)`. Cuando `prp_codigo == 4` ("Repesca"), el sistema bloquea la asignación estándar de horarios y creación de cursos regulares, exigiendo canales de trámite y autorización administrativa especial para modificaciones extemporáneas.
- **Integridad Referencial con Ventanas Operativas:** No puede eliminarse un registro de proceso mientras existan aperturas de calendario vinculadas en `programacionacademica.programacion_academica` (regla `RESTRICT / NO ACTION` por clave foránea DDL `FK_programacion_academica_proceso`).

#### Ciclo de Vida y Máquina de Estados
Tabla de parametrización institucional cuasi-estática:
- *Definición / Configuración Inicial:* Registro del proceso con su identificador único (`prp_codigo`), denominación institucional (`prp_nombre`), orden ordinal (`prp_orden`) y núcleos curriculares habilitados (`nuc_codigo`).
- *Operación en Periodo Activo:* En cada ciclo lectivo, la Vicerrectoría Académica parametriza ventanas temporales (`programacionacademica.programacion_academica`) asociando calendarios (`cal_codigo`), unidades académicas (`uaa_codigo`) y el proceso (`prp_codigo`). Mientras la fecha actual se encuentre dentro de `pra_fecha_inicio` y `pra_fecha_fin`, el proceso rige la oferta de los cursos de su competencia.
- *Cierre y Conclusión de Fase:* Cumplida la fecha límite (`pra_fecha_fin`), la fase se bloquea automáticamente para los directores de programa, dando paso a la apertura de la fase siguiente según el orden ascendente (`prp_orden + 1`).

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `prp_codigo` | `int` | - | NO | - | **PK** | Identificador primario y código numérico único de la etapa o proceso de programación académica institucional. |
| 2 | `prp_nombre` | `char` | 50 | SÍ | - | **-** | Nombre o denominación descriptiva oficial de la fase operativa (ej. 'ASIGNATURAS INSTITUCIONALES', 'ELECTIVAS DE FACULTAD', 'REPESCA'). |
| 3 | `prp_orden` | `int` | - | SÍ | - | **-** | Orden secuencial numérico que define la cronología y prelación de la etapa en el flujo de apertura y en las interfaces administrativas. |
| 4 | `nuc_codigo` | `varchar` | 10 | SÍ | - | **FK Implícita** | Código o conjunto de códigos de núcleos temáticos (`dbo.nucleo.nuc_codigo`) habilitados para asignaturas a programar en esta fase. |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_programacion_proceso` (NONCLUSTERED) sobre `([prp_codigo] ASC)` en el grupo de archivos `[PRIMARY]`.

#### Restricciones de Integridad Referencial
**Claves Foráneas Salientes:**
- Clave foránea implícita hacia `dbo.nucleo(nuc_codigo)` por convención de nombres y lógica de filtrado curricular en `Curcrea.php`.

**Claves Foráneas Entrantes (Dependencias del Catálogo):**
- Referenciada explícitamente desde `programacionacademica.programacion_academica(prp_codigo)` mediante la restricción DDL `FK_programacion_academica_proceso`.

---

## 3. Anexo: Entidades Complementarias y Vistas Administrativas

### 3.1 Entidades del Núcleo de Planificación en DBO
- `dbo.programacion_proceso`: Catálogo de etapas institucionales del proceso de captura de horarios (1: Asignaturas Institucionales, 2: Electivas de Facultad, 3: Asignaturas de Programa, 4: Repesca / Ajustes). Enlazada por clave foránea formal desde `programacionacademica.programacion_academica.prp_codigo`.
- `dbo.aud_uaa_personal`: Bitácora histórica de modificaciones DML sobre la nómina y contratación docente (`uap_codigo`).

### 3.2 Vistas Analíticas Administrativas y de Seguridad
- `dbo.usuario_general`: Vista maestra de cuentas y credenciales de usuario institucional, vinculada a personas mediante el campo `up`.
- `dbo.usuario_docente`: Vista desnormalizada de credenciales y perfiles exclusivos del cuerpo profesoral.
- `dbo.usuario_administrativo`: Vista de usuarios con roles en secretarías académicas y direcciones.
- `dbo.usuario_planta_fisica`: Vista de usuarios acreditados de la Dirección de Planta Física para gestión de aulas.
- `dbo.usuario_programacion`: Vista de usuarios autorizados para operar el módulo de programación académica.
- `dbo.usuario_programacion_login`: Vista de autenticación y validación de sesiones para la interfaz web.
- `dbo.resumen_docencia_final`: Vista analítica consolidada de la carga horaria semanal total del docente (horas lectivas de clase + horas de investigación + horas de proyección social).
