# 08 - Diccionario de Datos: Infraestructura y Horarios

## Dominio de Planta Física, Aulas, Grilla Horaria, Calendarios y Ocupación

---

## 1. Resumen Ejecutivo del Dominio

El dominio de **Infraestructura y Horarios** modela la dimensión física, territorial y temporal de la vida universitaria. Su objetivo prioritario es permitir una administración eficiente y libre de conflictos de las aulas, laboratorios y auditorios mediante la sincronización precisa de:

1. **Topología Territorial y Jerarquía Multicampus:** Estructura multinivel que abarca desde el país (`departamento`, `pais`), departamentos y municipios (`municipio`), hasta los campus universitarios (`sede`), subsedes (`sub_sede`), edificios (`bloque`) y aulas o espacios individuales (`espacio`), clasificados funcionalmente (`espacio_tipo`).
2. **Matriz Temporal y Grilla Semanal:** Grilla estándar semanal de días (`dia`) y horas académicas (`hora`), jornadas institucionales (`horario`), ancladas a los calendarios semestrales (`calendario`), periodos anuales (`periodo`) y el cronograma de fechas y suspensiones (`agenda_periodo`, `agenda_periodo_novedad`).
3. **El Núcleo Transaccional de Ocupación (`espacio_ocupacion`):** Entidad pivote donde convergen el espacio físico, el curso académico, el docente responsable, el día de la semana y la franja horaria. Sobre esta entidad opera el motor de validación para garantizar la exclusividad física y evitar colisiones horarias.

### Métricas Consolidadas del Dominio

| Métrica Arquitectónica | Valor | Descripción Técnica |
| :--- | :---: | :--- |
| **Total de Entidades Físicas** | **15** | 14 en `sql/dbo/*.sql` y 1 tabla física en `sql/dbo/vistas/espacio_tipo.sql` |
| **Total de Claves Primarias (PK)** | **15** | 100% de tablas poseen PK subrogada basada en IDENTITY |
| **Claves Foráneas Explícitas (DDL)** | **20** | Restricciones de integridad referencial codificadas en DDL |
| **Claves Foráneas Implícitas (Convención)** | **18** | Relaciones por convención de nombres y claves foráneas en código |
| **Catálogos Maestros Externos** | **5** | `pais`, `horario`, `ocupacion_tipo`, `periodo_tipo`, `programacion_proceso` |

---

## 2. Catálogo Técnico y Diccionario de Entidades

### 2.1 Entidad: `dbo.espacio`

- **Submódulo Funcional:** Planta Física y Espacios Universitarios
- **Archivo Fuente DDL:** `sql/dbo/espacio.sql`
- **Descripción Funcional:** Catálogo físico maestro de aulas, laboratorios, talleres, auditorios y salas de cómputo de la universidad. Registra aforo estándar, aforo de sobrecupo, superficie en metros cuadrados y bloque de pertenencia.

#### Reglas de Negocio y Validación Operativa
- Debe pertenecer a un bloque o edificio edificado (`blo_codigo`).
- Tipificado funcionalmente mediante `eti_codigo` (`dbo.espacio_tipo`).
- El aforo físico `esp_capacidad` es validado por el motor de programación para evitar que los cupos del curso superen la capacidad del salón.
- `esp_cupo_maximo` define el tope máximo absoluto para autorizaciones extraordinarias de sobrecupo.

#### Ciclo de Vida y Estados
Disponibilidad física: `esp_estado = 1` (Habilitado para reserva de clases), `0` (En mantenimiento / Inhabilitado).

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `esp_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Clave primaria secuencial e identificador único del espacio físico. |
| 2 | `esp_nombre` | `varchar` | 55 | NO | - | **-** | Denominación oficial o número de aula (ej. 'Aula 204', 'Lab Redes'). |
| 3 | `esp_nombre_corto` | `varchar` | 50 | SÍ | - | **-** | Sigla, código mnemotécnico o nomenclatura física compacta del aula o laboratorio (ej. 'AUL-101', 'LAB-FIS') para rotulación y visualización en cronogramas. |
| 4 | `blo_codigo` | `int` | - | SÍ | - | **FK Implícita** | Clave foránea implícita por convención de nombres al bloque contenedor (`dbo.bloque.blo_codigo`). |
| 5 | `esp_capacidad` | `int` | - | NO | - | **-** | Capacidad o aforo estándar recomendado de pupitres/puestos. |
| 6 | `esp_area` | `float` | - | SÍ | - | **-** | Superficie total en metros cuadrados del salón. |
| 7 | `eti_codigo` | `int` | - | SÍ | - | **FK Explícita** | Clave foránea explícita al tipo funcional de espacio (`dbo.espacio_tipo`). |
| 8 | `esp_compartido` | `char` | 1 | NO | - | **-** | Bandera clasificatoria ('S'/'N' o booleana) que establece si el espacio físico puede ser programado y compartido simultáneamente por más de un curso o docente. |
| 9 | `esp_descripcion` | `varchar` | 255 | NO | - | **-** | Descripción técnica detallada de las características arquitectónicas, equipamiento audiovisual, mobiliario pedagógico y condiciones de uso del recinto. |
| 10 | `uaa_codigo_responsable` | `int` | - | SÍ | - | **-** | Código de la Unidad Académico-Administrativa custodia y administradora del espacio (responsable de inventario, mantenimiento y autorización de préstamo). |
| 11 | `esp_luminosidad` | `char` | 1 | SÍ | - | **-** | Calificación técnica o descriptiva del nivel de iluminación natural y artificial del espacio según estándares de ergonomía y salud ocupacional. |
| 12 | `esp_espacio_codigo` | `char` | 3 | SÍ | - | **-** | Código alfanumérico o consecutivo institucional de inventario patrimonial del inmueble en el sistema de gestión física. |
| 13 | `esp_capacidad_covid` | `int` | - | SÍ | - | **-** | Aforo máximo permitido y regulado para el espacio físico bajo protocolos de distanciamiento preventivo y bioseguridad durante contingencias sanitarias. |
| 14 | `esp_habilitado_covid` | `int` | - | SÍ | - | **-** | Bandera booleana (1/0) que certifica que el aula cuenta con validación técnica de ventilación y bioseguridad para actividades presenciales. |
| 15 | `sippa_salcodigo` | `char` | 8 | SÍ | - | **-** | Identificador o código del salón en el sistema externo legacy SIPPA para integración, migración histórica y homologación de franjas de aula. |
| 16 | `esp_estado` | `int` | - | SÍ | - | **Estado** | Estado de operatividad física del espacio (1: Activo, 0: Mantenimiento). |
| 17 | `esp_puntos_elect` | `int` | - | SÍ | - | **-** | Cantidad total de tomas de corriente eléctrica disponibles en el recinto para conexión de equipos de cómputo, proyectores y dispositivos pedagógicos. |
| 18 | `esp_puntos_red` | `int` | - | SÍ | - | **-** | Número de tomas o puertos de red cableada estructurada (Ethernet/RJ-45) habilitados para conectividad de red interna e internet en el aula. |
| 19 | `esp_puntos_tel` | `int` | - | SÍ | - | **-** | Número de salidas de conexión de telefonía fija o citofonía institucional instaladas en el espacio para comunicación interna. |
| 20 | `esp_metros_pared` | `float` | - | SÍ | - | **-** | Metros cuadrados totales de superficie vertical (muros y tabiques) del espacio, empleado para cálculo de mantenimiento, pintura y aislamiento. |
| 21 | `esp_metros_suelo` | `float` | - | SÍ | - | **-** | Superficie o área útil de piso en metros cuadrados ($m^2$) del aula o recinto, utilizada para cómputo de densidad ocupacional y aforo normativo. |
| 22 | `mun_codigo` | `int` | - | SÍ | - | **FK Explícita** | Clave foránea explícita que referencia al municipio geográfico (dbo.municipio) en el cual se encuentra físicamente localizado el recinto. |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_espacios` (NONCLUSTERED) sobre `([esp_codigo] ASC)`

#### Restricciones de Integridad Referencial
**Claves Foráneas Explícitas (DDL):**
- `FK_espacio_espacio_tipo`: `espacio.eti_codigo` -> `[dbo].[espacio_tipo](eti_codigo)`
- `FK_espacio_municipio`: `espacio.mun_codigo` -> `[dbo].[municipio](mun_codigo)`

---

### 2.2 Entidad: `dbo.espacio_tipo`

- **Submódulo Funcional:** Planta Física y Espacios Universitarios
- **Archivo Fuente DDL:** `sql/dbo/espacio_tipo.sql`
- **Descripción Funcional:** Clasificador tipológico y funcional de la planta física (ej. Aula Magistral, Laboratorio de Cómputo, Auditorio, Taller de Dibujo, Escenario Deportivo).

#### Reglas de Negocio y Validación Operativa
- Ubicada físicamente en `sql/dbo/vistas/espacio_tipo.sql` pero definida mediante `CREATE TABLE` con PK identity.
- Condiciona qué asignaturas pueden programarse en el aula según su naturaleza (`tipo_curso`).

#### Ciclo de Vida y Estados
Catálogo maestro estático: `eti_estado = 1`.

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `eti_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Identificador numérico del clasificador de espacio. |
| 2 | `eti_nombre` | `varchar` | 50 | NO | - | **-** | Denominación del tipo de espacio (Aula Regular, Laboratorio, etc.). |
| 3 | `sippa_tipcodigo` | `char` | 2 | SÍ | - | **-** | Código legado de tipología en sistema SIPPA. |
| 4 | `etm_codigo` | `int` | - | SÍ | - | **-** | Código del macro-tipo o clasificación superior de tipología de espacio (aula magistral, laboratorio especializado, taller, auditorio, escenario deportivo). |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_espacio_tipo` (CLUSTERED) sobre `([eti_codigo] ASC)`

#### Restricciones de Integridad Referencial
- **Claves Foráneas Explícitas:** Ninguna codificada en DDL.

---

### 2.3 Entidad: `dbo.bloque`

- **Submódulo Funcional:** Planta Física y Espacios Universitarios
- **Archivo Fuente DDL:** `sql/dbo/bloque.sql`
- **Descripción Funcional:** Representa las edificaciones, pabellones o torres dentro de una sede universitaria o subsede.

#### Reglas de Negocio y Validación Operativa
- Se adscribe a una sede institucional (`sed_codigo`) y opcionalmente a una sub-sede (`sus_codigo`).
- Agrupa vertical y horizontalmente los espacios físicos (`dbo.espacio`).

#### Ciclo de Vida y Estados
Estado: `blo_estado = 1` (Edificio operativo).

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `blo_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Identificador único y clave primaria del bloque. |
| 2 | `blo_nombre` | `varchar` | 50 | NO | - | **-** | Nombre o número del bloque (ej. 'Bloque A', 'Torre Administrativa'). |
| 3 | `sus_codigo` | `int` | - | NO | - | **FK Explícita** | Clave foránea explícita a la sub-sede si aplica (`dbo.sub_sede`). |
| 4 | `sippa_blocodigo` | `char` | 4 | SÍ | - | **-** | Código de bloque en sistema legado SIPPA. |
| 5 | `blo_latitud` | `varchar` | 50 | SÍ | - | **-** | Coordenada geográfica de latitud en formato decimal o sexagesimal para georreferenciación y visualización del edificio en visores SIG y mapas del campus. |
| 6 | `blo_longitud` | `varchar` | 50 | SÍ | - | **-** | Coordenada geográfica de longitud para geolocalización satelital y ubicación espacial del bloque arquitectónico dentro del campus universitario. |
| 7 | `blo_estado` | `int` | - | SÍ | - | **Estado** | Estado del bloque o edificio. |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_bloque` (CLUSTERED) sobre `([blo_codigo] ASC)`

#### Restricciones de Integridad Referencial
**Claves Foráneas Explícitas (DDL):**
- `FK_bloque_sub_sede`: `bloque.sus_codigo` -> `[dbo].[sub_sede](sus_codigo)`

---

### 2.4 Entidad: `dbo.sub_sede`

- **Submódulo Funcional:** Jerarquía Territorial Multicampus
- **Archivo Fuente DDL:** `sql/dbo/sub_sede.sql`
- **Descripción Funcional:** Subdivisiones territoriales o seccionales desconcentradas asociadas a una sede universitaria principal.

#### Reglas de Negocio y Validación Operativa
- Depende jerárquicamente de una sede universitaria padre (`sed_codigo`).

#### Ciclo de Vida y Estados
Estado operativo: `sus_estado = 1`.

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `sus_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Identificador único de la sub-sede. |
| 2 | `sus_nombre` | `varchar` | 50 | NO | - | **-** | Nombre descriptivo de la subsede o seccional. |
| 3 | `sed_codigo` | `int` | - | NO | - | **FK Explícita** | Clave foránea explícita a la sede principal (`dbo.sede`). |
| 4 | `sus_direccion` | `varchar` | 50 | SÍ | - | **-** | Nomenclatura vial y dirección domiciliaria formal donde se encuentra ubicada la subsede o campus universitario regional. |
| 5 | `sus_telefono` | `char` | 20 | SÍ | - | **-** | Línea telefónica oficial, conmutador institucional o número de contacto administrativo de la subsede. |
| 6 | `sippa_sedcodigo` | `char` | 2 | SÍ | - | **-** | Código de integración o equivalencia de la subsede en el sistema legacy SIPPA para procesos de migración territorial. |
| 7 | `sus_estado` | `int` | - | SÍ | - | **Estado** | Estado de operatividad territorial. |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_sub_sede_1` (NONCLUSTERED) sobre `([sus_codigo] ASC)`

#### Restricciones de Integridad Referencial
**Claves Foráneas Explícitas (DDL):**
- `FK_sub_sede_sede`: `sub_sede.sed_codigo` -> `[dbo].[sede](sed_codigo)`

---

### 2.5 Entidad: `dbo.sede`

- **Submódulo Funcional:** Jerarquía Territorial Multicampus
- **Archivo Fuente DDL:** `sql/dbo/sede.sql`
- **Descripción Funcional:** Campus principal o seccional geográfica universitaria (ej. Sede Central, Campus Norte, Sede Regional).

#### Reglas de Negocio y Validación Operativa
- Se georreferencia en un municipio específico (`mun_codigo`).
- Es el nivel macro de localización territorial para programas, docentes y aulas.

#### Ciclo de Vida y Estados
Estado: `sed_estado = 1` (Sede activa).

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `sed_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Identificador único de la sede o campus. |
| 2 | `sed_nombre` | `varchar` | 50 | NO | - | **-** | Nombre oficial del campus universitario. |
| 3 | `mun_codigo` | `int` | - | NO | - | **FK Explícita** | Clave foránea explícita al municipio geográfico (`dbo.municipio`). |
| 4 | `sippa_sed_codigo` | `int` | - | SÍ | - | **-** | Identificador numérico de la sede institucional dentro de los registros del sistema legacy SIPPA. |
| 5 | `sed_estado` | `varchar` | 1 | SÍ | - | **Estado** | Estado operativo de la sede institucional. |
| 6 | `SedNombre_corto` | `nchar` | 3 | SÍ | - | **-** | Sigla o denominación abreviada oficial de la sede universitaria (ej. 'NEIVA', 'PITALITO', 'GARZON', 'LA PLATA') para reportes sintéticos. |
| 7 | `sed_PDI` | `int` | - | SÍ | - | **-** | Código de vinculación con proyectos de inversión del Plan de Desarrollo Institucional (PDI) asignados a la expansión o fortalecimiento de la sede. |
| 8 | `sed_dependencia` | `int` | - | SÍ | - | **-** | Código de la dependencia académica o vicerrectoría a la que se subordina administrativamente la gestión integral de la sede regional. |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_sede` (NONCLUSTERED) sobre `([sed_codigo] ASC)`

#### Restricciones de Integridad Referencial
**Claves Foráneas Explícitas (DDL):**
- `FK_sede_municipio`: `sede.mun_codigo` -> `[dbo].[municipio](mun_codigo)`

---

### 2.6 Entidad: `dbo.municipio`

- **Submódulo Funcional:** Jerarquía Territorial Multicampus
- **Archivo Fuente DDL:** `sql/dbo/municipio.sql`
- **Descripción Funcional:** Catálogo de municipios y ciudades de Colombia conforme a la codificación oficial DANE.

#### Reglas de Negocio y Validación Operativa
- Pertenece a un departamento político-administrativo (`dep_codigo`).
- Utilizado para georreferenciación de campus, ejecuciones de curso y proyectos sociales.

#### Ciclo de Vida y Estados
Catálogo nacional estático: `mun_estado = 1`.

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `mun_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Código DANE o numérico del municipio. |
| 2 | `mun_id` | `char` | 5 | SÍ | - | **-** | Identificador alfanumérico corto o código mnemotécnico institucional del municipio para filtros operativos. |
| 3 | `mun_nombre` | `varchar` | 100 | NO | - | **-** | Nombre oficial del municipio o distrito. |
| 4 | `dep_codigo` | `int` | - | NO | - | **-** | Clave foránea explícita al departamento (`dbo.departamento`). |
| 5 | `sippa_mun_codigo` | `int` | - | SÍ | - | **-** | Código de homologación del municipio en el sistema externo legacy SIPPA. |
| 6 | `SNIES_codigo` | `char` | 5 | SÍ | - | **-** | Código oficial del municipio según el estándar de codificación geográfica del SNIES del Ministerio de Educación Nacional. |
| 7 | `dane_codigo` | `char` | 10 | SÍ | - | **-** | Código territorial oficial de 5 dígitos de la División Político-Administrativa de Colombia (DIVIPOLA) asignado por el DANE. |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_municipio` (NONCLUSTERED) sobre `([mun_codigo] ASC)`

#### Restricciones de Integridad Referencial
- **Claves Foráneas Explícitas:** Ninguna codificada en DDL.

---

### 2.7 Entidad: `dbo.departamento`

- **Submódulo Funcional:** Jerarquía Territorial Multicampus
- **Archivo Fuente DDL:** `sql/dbo/departamento.sql`
- **Descripción Funcional:** Catálogo de divisiones departamentales o estados del país conforme a codificación territorial.

#### Reglas de Negocio y Validación Operativa
- Referencia a un país soberano (`pai_codigo`) mediante FK hacia el maestro externo `dbo.pais`.

#### Ciclo de Vida y Estados
Catálogo geográfico estático: `dep_estado = 1`.

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `dep_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Identificador único del departamento territorial. |
| 2 | `dep_acronimo` | `char` | 2 | SÍ | - | **-** | Sigla o acrónimo formal de 2 o 3 caracteres que representa al departamento geográfico (ej. 'HUI', 'CUN', 'ANT', 'TOL'). |
| 3 | `dep_nombre` | `varchar` | 100 | NO | - | **-** | Nombre oficial del departamento. |
| 4 | `pai_codigo` | `int` | - | NO | - | **FK Explícita** | Clave foránea explícita hacia el país (`dbo.pais.pai_codigo`). |
| 5 | `sippa_dep_codigo` | `int` | - | SÍ | - | **-** | Código de equivalencia del departamento geográfico en la base de datos externa SIPPA. |
| 6 | `dane_codigo` | `char` | 10 | SÍ | - | **-** | Código de dos dígitos del departamento según la codificación oficial de la DIVIPOLA del DANE (ej. '41' para el departamento del Huila). |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_departamento_1` (CLUSTERED) sobre `([dep_codigo] ASC)`

#### Restricciones de Integridad Referencial
**Claves Foráneas Explícitas (DDL):**
- `FK_departamento_pais`: `departamento.pai_codigo` -> `[dbo].[pais](pai_codigo)`

---

### 2.8 Entidad: `dbo.espacio_ocupacion`

- **Submódulo Funcional:** Núcleo Transaccional de Ocupación de Aulas
- **Archivo Fuente DDL:** `sql/dbo/espacio_ocupacion.sql`
- **Descripción Funcional:** Entidad pivote y transaccional central del sistema de asignación de espacios. Materializa la reserva física de un aula para un curso específico en un día de la semana y franja horaria determinada.

#### Reglas de Negocio y Validación Operativa
- Regla de No Colisión Física: No pueden existir dos registros activos (`eso_estado = 1`) que compartan simultáneamente el mismo `esp_codigo`, `dia_codigo`, `hra_codigo` y `cal_codigo` con rangos de fechas solapados.
- Regla de No Colisión Docente: Un profesor (`uap_codigo`) no puede tener dos ocupaciones en el mismo día y hora.
- Regla de Capacidad: `eso_capacidad` no debe rebasar `esp_cupo_maximo` de `dbo.espacio`.
- Posee relaciones foráneas con los catálogos maestros externos `dbo.horario` (`hor_codigo`) y `dbo.ocupacion_tipo` (`oct_codigo`).

#### Ciclo de Vida y Estados
Vigencia: `eso_estado = 1` (Asignación activa y bloqueante en la grilla horaria), `0` (Cancelada / Liberada).

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `eso_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Clave primaria secuencial e identificador de la reserva de aula. |
| 2 | `esp_codigo` | `int` | - | NO | - | **FK Explícita** | Clave foránea explícita al espacio físico reservado (`dbo.espacio`). |
| 3 | `uaa_codigo` | `int` | - | NO | - | **FK Explícita** | Código de la Unidad Académico-Administrativa beneficiaria o solicitante de la reserva del aula (referencia a dbo.uaa). |
| 4 | `eso_fecha` | `datetime` | - | NO | - | **Temporal** | Marca temporal precisa en la que se radicó la reserva u ocupación del espacio físico en el cronograma. |
| 5 | `hor_codigo` | `int` | - | SÍ | - | **FK Explícita** | Clave foránea explícita a la jornada institucional (`dbo.horario`). |
| 6 | `dia_codigo` | `int` | - | SÍ | - | **-** | Clave foránea explícita al día lectivo semanal (`dbo.dia`). |
| 7 | `hra_codigo` | `int` | - | SÍ | - | **FK Explícita** | Clave foránea explícita a la franja horaria (`dbo.hora`). |
| 8 | `eso_actividad` | `int` | - | SÍ | - | **FK Explícita** | Descripción de la actividad (Clase teórica, Laboratorio, Parcial). |
| 9 | `eso_subgrupo` | `char` | 2 | SÍ | - | **-** | Identificador del subgrupo específico de práctica o laboratorio (ej. 'A', 'B', '01') al que se le reserva el salón en dicha franja. |
| 10 | `uap_codigo` | `int` | - | SÍ | - | **-** | Clave foránea explícita al docente titular a cargo (`dbo.uaa_personal`). |
| 11 | `eso_estado` | `char` | 1 | SÍ | - | **Estado** | Estado de la ocupación (1: Activa, 0: Liberada/Inactiva). |
| 12 | `oct_codigo` | `int` | - | SÍ | - | **FK Explícita** | Clave foránea explícita al tipo de ocupación (`dbo.ocupacion_tipo`). |
| 13 | `eso_descripcion` | `varchar` | 200 | SÍ | - | **-** | Glosa, justificación o detalle textual sobre la actividad académica, examen, evento o requerimiento logístico de la ocupación. |
| 14 | `cdp_codigo` | `int` | - | SÍ | - | **-** | Código del Certificado de Disponibilidad Presupuestal cuando la reserva implica costos operativos, alquiler a terceros o apoyo logístico extraordinario. |
| 15 | `ctr_codigo` | `int` | - | SÍ | - | **-** | Código del contrato o convenio interinstitucional que ampara el uso de la infraestructura física universitaria por parte de usuarios externos. |
| 16 | `usu_codigo` | `int` | - | SÍ | - | **-** | Código del usuario institucional que registró o programó la asignación horaria del espacio físico. |
| 17 | `usu_clave` | `varchar` | 50 | SÍ | - | **-** | Clave de validación o hash de seguridad de la transacción de asignación de aula efectuada por el funcionario. |
| 18 | `sippa_sedcodigo` | `char` | 2 | SÍ | - | **-** | Código de sede territorial en el sistema SIPPA bajo la cual se registró la reserva física. |
| 19 | `sippa_calcodigo` | `char` | 6 | SÍ | - | **-** | Código de calendario académico en SIPPA asociado a la franja horaria programada. |
| 20 | `sippa_progcodigo` | `char` | 4 | SÍ | - | **-** | Código del programa académico en el sistema SIPPA al que se imputa la asignación de aula. |
| 21 | `sippa_plancodigo` | `char` | 7 | SÍ | - | **-** | Código del plan de estudios en SIPPA al que pertenece la asignatura impartida en el espacio. |
| 22 | `sippa_asicodigo` | `char` | 8 | SÍ | - | **-** | Código de la asignatura en el sistema SIPPA programada en dicha franja espacial. |
| 23 | `sippa_grucodigo` | `char` | 2 | SÍ | - | **-** | Código del grupo en SIPPA asignado a la ocupación del recinto. |
| 24 | `sippa_subgrucodigo` | `char` | 2 | SÍ | - | **-** | Código del subgrupo práctico en SIPPA asociado a la franja de clase. |
| 25 | `sippa_horfecini` | `datetime` | - | SÍ | - | **-** | Fecha de inicio de vigencia de la reserva horaria registrada en el sistema legacy SIPPA. |
| 26 | `sippa_horfecfin` | `datetime` | - | SÍ | - | **-** | Fecha de finalización de vigencia de la reserva horaria en el sistema legacy SIPPA. |
| 27 | `sippa_horcodigo` | `char` | 5 | SÍ | - | **-** | Código de la franja horaria predeterminada en SIPPA para la sesión lectiva. |
| 28 | `sippa_doccedula` | `char` | 11 | SÍ | - | **-** | Cédula de ciudadanía o identificación del docente titular asignado al aula en el sistema SIPPA. |
| 29 | `sippa_salcodigo` | `char` | 8 | SÍ | - | **-** | Código del salón o aula asignada según la nomenclatura de espacios del sistema legacy SIPPA. |
| 30 | `sippa_horsemanas` | `smallint` | - | SÍ | - | **-** | Número de semanas lectivas durante las cuales opera la reserva horaria del espacio en SIPPA. |
| 31 | `sippa_horfactor` | `float` | - | SÍ | - | **-** | Factor multiplicador de ponderación de la hora académica en la franja según reglas SIPPA. |
| 32 | `sippa_vincodigo` | `char` | 3 | SÍ | - | **-** | Código del tipo de vinculación laboral del docente a cargo de la clase en SIPPA. |
| 33 | `eso_url` | `varchar` | 200 | SÍ | - | **-** | Dirección web o enlace URL a la sesión sincrónica virtual (Microsoft Teams, Zoom, Google Meet) para clases en modalidad híbrida o remota. |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_espacio_ocupacion` (CLUSTERED) sobre `([eso_codigo] ASC)`

#### Restricciones de Integridad Referencial
**Claves Foráneas Explícitas (DDL):**
- `FK_espacio_ocupacion_curso`: `espacio_ocupacion.eso_actividad` -> `[dbo].[curso](cur_codigo)`
- `FK_espacio_ocupacion_espacio`: `espacio_ocupacion.esp_codigo` -> `[dbo].[espacio](esp_codigo)`
- `FK_espacio_ocupacion_hora1`: `espacio_ocupacion.hra_codigo` -> `[dbo].[hora](hra_codigo)`
- `FK_espacio_ocupacion_horario1`: `espacio_ocupacion.hor_codigo` -> `[dbo].[horario](hor_codigo)`
- `FK_espacio_ocupacion_ocupacion_tipo`: `espacio_ocupacion.oct_codigo` -> `[dbo].[ocupacion_tipo](oct_codigo)`
- `FK_espacio_ocupacion_uaa_agosto2018`: `espacio_ocupacion.uaa_codigo` -> `[dbo].[uaa](uaa_codigo)`

---

### 2.9 Entidad: `dbo.curso_institucion_ejecucion`

- **Submódulo Funcional:** Planta Física y Espacios Universitarios
- **Archivo Fuente DDL:** `sql/dbo/curso_institucion_ejecucion.sql`
- **Descripción Funcional:** Enlace territorial que vincula un curso con el aula física y municipio de ejecución.

#### Reglas de Negocio y Validación Operativa
- Conecta transversalmente la oferta de cursos con los espacios físicos (`esp_codigo`) y los municipios (`mun_codigo`).

#### Ciclo de Vida y Estados
Estado: `cie_estado = 1`.

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `cie_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Identificador único de ejecución del curso. |
| 2 | `cur_codigo` | `int` | - | SÍ | - | **FK Explícita** | Clave foránea explícita al curso (`dbo.curso`). |
| 3 | `cie_subgrupo` | `char` | 2 | SÍ | - | **-** | Subgrupo práctico atendido. |
| 4 | `esp_codigo` | `int` | - | SÍ | - | **FK Explícita** | Clave foránea explícita al aula (`dbo.espacio`). |
| 5 | `mun_codigo` | `int` | - | SÍ | - | **FK Explícita** | Clave foránea explícita al municipio (`dbo.municipio`). |
| 6 | `cie_estado` | `int` | - | SÍ | - | **Estado** | Estado de la ejecución territorial. |
| 7 | `cie_uid_inserta` | `int` | - | SÍ | - | **-** | Identificador numérico de usuario (UID) que radicó la asignación de la institución o escenario de práctica externa del curso. |
| 8 | `cie_fecha_inserta` | `datetime` | - | SÍ | - | **Temporal** | Marca temporal de auditoría que registra la fecha y hora de creación de la asignación interinstitucional. |
| 9 | `cie_uid_modifica` | `int` | - | SÍ | - | **-** | Identificador de usuario que realizó la última modificación o actualización sobre la institución de ejecución asignada. |
| 10 | `cie_fecha_modifica` | `datetime` | - | SÍ | - | **Temporal** | Fecha y hora de la última modificación efectuada sobre el registro de ejecución institucional. |

#### Índices y Claves Primarias
- **Clave Primaria:** Primaria sobre `([cie_codigo] ASC)`

#### Restricciones de Integridad Referencial
**Claves Foráneas Explícitas (DDL):**
- `Anonymous`: `curso_institucion_ejecucion.cur_codigo` -> `[dbo].[curso](cur_codigo)`
- `FK__curso_ins__esp_c__44EEF70B`: `curso_institucion_ejecucion.esp_codigo` -> `[dbo].[espacio](esp_codigo)`
- `Anonymous`: `curso_institucion_ejecucion.mun_codigo` -> `[dbo].[municipio](mun_codigo)`

---

### 2.10 Entidad: `dbo.dia`

- **Submódulo Funcional:** Grilla Semanal y Matriz de Tiempos
- **Archivo Fuente DDL:** `sql/dbo/dia.sql`
- **Descripción Funcional:** Catálogo maestro de días de la semana (Lunes a Domingo) para la conformación de la grilla horaria institucional.

#### Reglas de Negocio y Validación Operativa
- Identificadores estándar (ej. 1: Lunes, 2: Martes ... 7: Domingo).
- Referenciado universalmente en `espacio_ocupacion`, `solicitud_cambio_horario_horario` y `solicitud_prestamo_docente_horario`.

#### Ciclo de Vida y Estados
Catálogo estático permanente: `dia_estado = 1`.

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `dia_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Identificador numérico secuencial del día lectivo. |
| 2 | `dia_nombre` | `varchar` | 50 | SÍ | - | **-** | Nombre del día (Lunes, Martes, Miércoles, etc.). |
| 3 | `dia_posicion_semana` | `smallint` | - | SÍ | - | **-** | Índice ordinal numérico del día dentro de la semana civil (1: Lunes, 2: Martes, ..., 6: Sábado, 7: Domingo) para ordenamiento cronológico de horarios. |
| 4 | `dia_estado` | `int` | - | NO | - | **Estado** | Disponibilidad del día para actividades académicas. |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_dia` (CLUSTERED) sobre `([dia_codigo] ASC)`

#### Restricciones de Integridad Referencial
- **Claves Foráneas Explícitas:** Ninguna codificada en DDL.

---

### 2.11 Entidad: `dbo.hora`

- **Submódulo Funcional:** Grilla Semanal y Matriz de Tiempos
- **Archivo Fuente DDL:** `sql/dbo/hora.sql`
- **Descripción Funcional:** Catálogo maestro de bloques o franjas horarias académicas de clase (ej. 06:00-07:00, 07:00-08:00).

#### Reglas de Negocio y Validación Operativa
- Fija la hora exacta de inicio (`hra_hora_inicio`) y terminación (`hra_hora_fin`).
- Se asocia a un turno o jornada mediante FK hacia el maestro externo `dbo.horario` (`hor_codigo`).

#### Ciclo de Vida y Estados
Catálogo estático: `hra_estado = 1`.

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `hra_codigo` | `int` | - | NO | - | **PK** | Identificador único de la franja horaria. |
| 2 | `hra_nombre` | `varchar` | 50 | NO | - | **-** | Etiqueta o descripción textual estándar de la franja horaria (ej. '06:00 - 07:00', '14:00 - 16:00') para interfaces de usuario y cronogramas. |
| 3 | `hra_inicio` | `char` | 7 | NO | - | **-** | Hora de inicio de la franja lectiva expresada en formato civil de 12 horas (ej. '06:00 AM', '02:00 PM'). |
| 4 | `hra_fin` | `char` | 10 | NO | - | **-** | Hora de culminación de la franja lectiva expresada en formato civil de 12 horas (ej. '07:00 AM', '04:00 PM'). |
| 5 | `hra_inicio_24h` | `char` | 5 | SÍ | - | **-** | Hora de inicio estandarizada en formato militar de 24 horas (ej. '06:00', '14:00') para ordenamiento numérico y validación de traslapes. |
| 6 | `hra_fin_24h` | `char` | 5 | SÍ | - | **-** | Hora de finalización en formato estandarizado de 24 horas (ej. '07:00', '16:00') para algoritmos de detección de cruces de horario. |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_hora` (NONCLUSTERED) sobre `([hra_codigo] ASC)`

#### Restricciones de Integridad Referencial
**Claves Foráneas Explícitas (DDL):**
- `FK_hora_horario`: `hora.hra_codigo` -> `[dbo].[horario](hor_codigo)`

---

### 2.12 Entidad: `dbo.calendario`

- **Submódulo Funcional:** Ciclos Lectivos y Cronograma
- **Archivo Fuente DDL:** `sql/dbo/calendario.sql`
- **Descripción Funcional:** Representa el ciclo lectivo semestral oficial de la institución (ej. 2026-1, 2026-2, Periodo Intersemestral).

#### Reglas de Negocio y Validación Operativa
- Pertenece a un periodo anual institucional (`dbo.periodo`).
- Delimita las fechas oficiales de inicio (`cal_fecha_inicio`) y terminación (`cal_fecha_fin`) de clases.
- Es el eje de vigencia para cursos, matrículas, ventanas de programación y ocupaciones.

#### Ciclo de Vida y Estados
Estados: Programación -> Matrículas -> Clases Activas -> Exámenes Finales -> Cierre y Consolidación.

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `cal_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Clave primaria e identificador único del ciclo lectivo. |
| 2 | `per_codigo` | `int` | - | NO | - | **FK Explícita** | Clave foránea explícita al periodo institucional (`dbo.periodo`). |
| 3 | `cal_nombre` | `varchar` | 30 | SÍ | - | **-** | Denominación oficial del semestre (ej. '2026-1'). |
| 4 | `cal_fecha` | `datetime` | - | SÍ | - | **Temporal** | Fecha oficial de expedición o adopción del acto administrativo que promulga el calendario académico universitario. |
| 5 | `cal_documento` | `varchar` | 10 | SÍ | - | **-** | Número oficial del acuerdo del Consejo Superior o resolución rectoral que aprueba formalmente las fechas del calendario académico. |
| 6 | `sippa_cal_codigo` | `char` | 6 | SÍ | - | **-** | Código alfanumérico de homologación del calendario académico en el sistema legacy SIPPA. |
| 7 | `cal_ano_salario_minimo` | `int` | - | SÍ | - | **-** | Año fiscal de vigencia del Salario Mínimo Legal Mensual Vigente (SMLMV) utilizado como base para liquidación de valores de matrícula y derechos pecuniarios. |
| 8 | `cal_estado` | `varchar` | 1 | SÍ | - | **Estado** | Estado del calendario (1: Activo, 0: Histórico/Cerrado). |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_calendario` (CLUSTERED) sobre `([cal_codigo] ASC)`

#### Restricciones de Integridad Referencial
**Claves Foráneas Explícitas (DDL):**
- `FK_calendario_periodo`: `calendario.per_codigo` -> `[dbo].[periodo](per_codigo)`

---

### 2.13 Entidad: `dbo.periodo`

- **Submódulo Funcional:** Ciclos Lectivos y Cronograma
- **Archivo Fuente DDL:** `sql/dbo/periodo.sql`
- **Descripción Funcional:** Representa los periodos institucionales macro (semestrales, anuales, intersemestrales).

#### Reglas de Negocio y Validación Operativa
- Tipificado mediante clave foránea explícita hacia el maestro externo `dbo.periodo_tipo` (`pet_codigo`).

#### Ciclo de Vida y Estados
Vigencia anual o semestral institucional: `per_estado = 1`.

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `per_codigo` | `int` | - | NO | IDENTITY(1,1) | **PK** | Identificador numérico del periodo macro. |
| 2 | `pet_codigo` | `int` | - | SÍ | - | **FK Explícita** | Clave foránea explícita a `dbo.periodo_tipo`. |
| 3 | `per_nombre` | `varchar` | 50 | SÍ | - | **-** | Nombre descriptivo (Primer Semestre, Segundo Semestre). |
| 4 | `per_periodo` | `tinyint` | - | SÍ | - | **-** | Número ordinal o ciclo que identifica el semestre lectivo dentro del año (1: Primer semestre, 2: Segundo semestre, 3: Período intersemestral o vacacional). |
| 5 | `per_fecha_inicio` | `datetime` | - | SÍ | - | **Temporal** | Fecha oficial de apertura y vigencia administrativa del período académico en los sistemas de información. |
| 6 | `per_fecha_fin` | `datetime` | - | SÍ | - | **Temporal** | Fecha de culminación y cierre administrativo formal del período académico. |
| 7 | `per_inicio_actividades` | `date` | - | SÍ | - | **-** | Fecha establecida en el calendario institucional para el inicio formal de labores de docencia directa, clases y asistencia profesoral. |
| 8 | `per_fin_actividades` | `date` | - | SÍ | - | **-** | Fecha oficial de culminación de clases, evaluaciones finales y cierre definitivo de digitación de actas de notas. |
| 9 | `per_acuerdo_actividades` | `varchar` | max | SÍ | - | **-** | Identificador del acuerdo o resolución institucional que reglamentó el cronograma de actividades lectivas y de evaluación del período. |
| 10 | `sippa_per_codigo` | `char` | 5 | SÍ | - | **-** | Código alfanumérico de homologación e integración del período académico en el sistema SIPPA. |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_periodo` (NONCLUSTERED) sobre `([per_codigo] ASC)`

#### Restricciones de Integridad Referencial
**Claves Foráneas Explícitas (DDL):**
- `FK_periodo_periodo_tipo`: `periodo.pet_codigo` -> `[dbo].[periodo_tipo](pet_codigo)`

---

### 2.14 Entidad: `dbo.agenda_periodo`

- **Submódulo Funcional:** Ciclos Lectivos y Cronograma
- **Archivo Fuente DDL:** `sql/dbo/agenda_periodo.sql`
- **Descripción Funcional:** Cronograma de fechas e hitos clave del calendario académico (ventanas de programación docente, matrícula ordinaria, exámenes parciales y finales).

#### Reglas de Negocio y Validación Operativa
- Conecta un calendario (`cal_codigo`) con un periodo (`per_codigo`).
- Establece los lapsos `agp_fecha_inicio` y `agp_fecha_fin` para cada actividad del calendario.

#### Ciclo de Vida y Estados
Hitos secuenciales del calendario académico.

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `idagenda` | `numeric` | 18, 0 | NO | IDENTITY(1,1) | **PK** | Identificador único del hito en el cronograma de actividades. |
| 2 | `creditos` | `int` | - | SÍ | - | **-** | Número de créditos académicos asociados a la asignatura en la asignación horaria y de carga profesoral del período. |
| 3 | `caracter` | `nchar` | 2 | SÍ | - | **-** | Carácter disciplinar y pedagógico de la materia en la agenda docente ('T': Teórica, 'P': Práctica, 'TP': Teórico-Práctica). |
| 4 | `hora_teorica` | `int` | - | SÍ | - | **Temporal** | Número de horas presenciales semanales dedicadas a docencia teórica o cátedra magistral asignadas al docente. |
| 5 | `hora_practica` | `int` | - | SÍ | - | **Temporal** | Número de horas presenciales semanales destinadas a prácticas de laboratorio, talleres formativos o trabajo de campo con el grupo. |
| 6 | `tradicional_o_credito` | `nchar` | 2 | SÍ | - | **-** | Régimen curricular bajo el cual se pondera la asignatura en la agenda docente ('C': Sistema de Créditos Académicos, 'T': Sistema Tradicional). |
| 7 | `numero_total_hora` | `int` | - | SÍ | - | **Temporal** | Total de horas semanales presenciales asignadas de docencia directa para el curso a cargo del profesor. |
| 8 | `factor` | `int` | - | SÍ | - | **-** | Factor multiplicador de ponderación docente de la hora cátedra según el tipo de asignatura y normatividad estatutaria de asignación de carga. |
| 9 | `semanas` | `int` | - | SÍ | - | **-** | Cantidad efectiva de semanas lectivas del período durante las cuales el docente dictará el curso (típicamente 16 semanas). |
| 10 | `vinculacion` | `int` | - | SÍ | - | **-** | Código de vinculación laboral docente (Planta, Ocasional, Cátedra) bajo la cual se remunera o imputa la labor académica. |
| 11 | `uap_codigo` | `int` | - | SÍ | - | **-** | Identificador de vinculación laboral específica del docente (dbo.uaa_personal) a quien se asigna la agenda académica. |
| 12 | `cur_codigo` | `int` | - | SÍ | - | **-** | Código del curso académico programado (dbo.curso) al cual corresponde la asignación de horario y docente. |
| 13 | `sub_grupo` | `nchar` | 2 | SÍ | - | **-** | Identificador del subgrupo específico de laboratorio o taller a cargo del docente. |
| 14 | `total_horas` | `int` | - | SÍ | - | **Temporal** | Total consolidado de horas semestrales de carga de trabajo docente asignadas para el curso (cálculo de horas semanales ponderadas por semanas). |
| 15 | `per_codigo` | `int` | - | SÍ | - | **-** | Clave foránea explícita al periodo institucional (`dbo.periodo`). |
| 16 | `uaa_codigo` | `int` | - | SÍ | - | **-** | Código de la Unidad Académico-Administrativa a la cual se imputa financieramente la dedicación horaria del docente (dbo.uaa). |
| 17 | `factor_formula` | `nchar` | 20 | SÍ | - | **-** | Identificador o nemotécnico de la fórmula algorítmica utilizada por el sistema para calcular el factor de compensación docente. |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_agenda_periodo` (CLUSTERED) sobre `([idagenda] ASC)`

#### Restricciones de Integridad Referencial
- **Claves Foráneas Explícitas:** Ninguna codificada en DDL.

---

### 2.15 Entidad: `dbo.agenda_periodo_novedad`

- **Submódulo Funcional:** Ciclos Lectivos y Cronograma
- **Archivo Fuente DDL:** `sql/dbo/agenda_periodo_novedad.sql`
- **Descripción Funcional:** Registro de suspensiones, feriados, semanas culturales o novedades imprevistas que alteran el cronograma oficial.

#### Reglas de Negocio y Validación Operativa
- Afecta a un hito o agenda determinada (`idagenda`).
- Las franjas suspendidas no se computan como semanas de clase lectiva exigible.

#### Ciclo de Vida y Estados
Vigencia durante los días declarados de suspensión.

#### Diccionario de Datos de Columnas

| # | Columna | Tipo SQL | Longitud | Nulo | Identidad / Defecto | Rol Clave | Descripción Funcional |
| :-: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| 1 | `apn_id` | `int` | - | NO | IDENTITY(1,1) | **PK** | Identificador único y clave primaria subrogada de la novedad radicada sobre la asignación de carga docente en el período. |
| 2 | `novedad` | `text` | - | SÍ | - | **-** | Descripción circunstanciada del motivo de la modificación de agenda (ej. incapacidad médica, permiso académico, reasignación docente o ajuste de horario). |
| 3 | `fecha` | `date` | - | SÍ | - | **Temporal** | Fecha formal en la que se radicó o surtió efectos la novedad administrativa sobre la agenda docente. |
| 4 | `ag_id` | `int` | - | SÍ | - | **-** | Identificador del registro de agenda docente afectado (clave foránea implícita hacia dbo.agenda_periodo.idagenda). |
| 5 | `periodo` | `int` | - | SÍ | - | **-** | Código del período académico en el cual se presenta y formaliza la novedad de carga docente. |
| 6 | `per_codigo` | `int` | - | SÍ | - | **-** | Código de la persona o docente titular (dbo.persona) sobre quien recae la novedad o descarga académica. |

#### Índices y Claves Primarias
- **Clave Primaria:** `PK_agenda_periodo_novedad` (CLUSTERED) sobre `([apn_id] ASC)`

#### Restricciones de Integridad Referencial
- **Claves Foráneas Explícitas:** Ninguna codificada en DDL.

---

## 3. Anexo: Tablas de Auditoría y Vistas de Infraestructura

### 3.1 Tablas de Auditoría de Ocupación
- `dbo.aud_espacio_ocupacion`: Bitácora histórica de modificaciones DML sobre reservas de aula (`eso_codigo`). Registra tipo de operación (INSERT, UPDATE, DELETE), usuario y valores previos/posteriores.

### 3.2 Vistas Analíticas de Ocupación
- `dbo.espacio_ocupacion_total`: Vista analítica desnormalizada que consolida la ocupación física integrando espacio, bloque, sede, curso, asignatura, docente y horario semanal para reportes institucionales.
