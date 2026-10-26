# INVENTARIO EXHAUSTIVO DE TABLAS Y ESQUEMAS DE BASE DE DATOS
## Proyecto: `p_academica-main` (Sistema de Programación Académica)

> **Fecha de generación:** Octubre 2026  
> **Alcance del análisis:** Inspección estática profunda de archivos PHP (`clases/`, `logica/`, `conexion/`, archivos raíz), SQL (`data_base/`) y configuración (`pacademica.ini`).  
> **Entorno de base de datos:** Microsoft SQL Server (vía PDO SQLSRV / ODBC).

---

## 1. RESUMEN EJECUTIVO

Se realizó un escaneo automatizado y verificado manualmente sobre la totalidad de los archivos del repositorio para identificar todas las sentencias SQL (`SELECT`, `INSERT`, `UPDATE`, `DELETE`, `CREATE TABLE`, `ALTER TABLE`, `REFERENCES`, `JOIN`, subconsultas y CTEs).

### 1.1 Totales Consolidados

| Métrica | Valor Detectado | Descripción |
| :--- | :--- | :--- |
| **Esquemas explícitos en código** | **4** | `programacionacademica`, `proaca`, `proyectos`, `dbo` |
| **Categorías de clasificación** | **5** | 4 esquemas explícitos + 1 categoría de tablas sin prefijo (esquema por defecto) |
| **Tablas en `programacionacademica`** | **12** | Entidades del módulo de gestión de aperturas, grupos y solicitudes |
| **Tablas en `proaca` (DDL)** | **3** | Tablas de gestión definidas en script DDL (`data_base/2. CreateTablesManagement.sql`) |
| **Tablas en `proyectos`** | **2** | Tablas del subsistema de proyección social de docentes |
| **Tablas con prefijo explícito `dbo`** | **20** | Tablas consultadas con cualificador explícito `dbo.<tabla>` |
| **Tablas sin prefijo explícito** | **73** | Tablas institucionales consultadas bajo el esquema por defecto (`dbo`) |
| **Total tablas/entidades únicas** | **88** | Universo consolidado sin duplicar entidades que aparecen con y sin prefijo `dbo` |
| **Archivos fuente con consultas SQL** | **37** | 33 clases (`clases/`), 2 servicios (`clases/servicios/`) y 2 scripts DDL (`data_base/`) |
| **Consultas SQL completas analizadas** | **471** | Sentencias SQL parametrizadas e interpoladas inspeccionadas |

### 1.2 Resumen Cuantitativo por Esquema

| Esquema | Total Tablas | Operaciones Detectadas | Archivos Clave |
| :--- | :---: | :--- | :--- |
| **`programacionacademica`** | 12 | Lectura, Inserción, Actualización | `Aperfe.php`, `Buscurso.php`, `Cambdocente.php`, `Curcrea.php`, `Curhorario.php`, `Peraca.php`, `Solcambh.php`, `Soldoc.php`, `Cupocurso.php` |
| **`proaca`** | 3 | Creación, Modificación / FK | `data_base/2. CreateTablesManagement.sql` |
| **`proyectos`** | 2 | Lectura | `clases/servicios/ValidarCargaDocenteService.php` |
| **`dbo` (prefijo explícito)** | 20 | Lectura, Referencia (FK) | `Inicio_sesion.php`, `Cupoper.php`, `Aperfe.php`, `Csh.php`, `data_base/2. CreateTablesManagement.sql` |
| **Sin prefijo explícito (esquema por defecto / `dbo`)** | 73 | Lectura, Inserción, Actualización, Eliminación | Múltiples clases del núcleo (`Curso`, `Espacio_ocupacion`, `Asignatura`, etc.) |

---

## 2. ESQUEMA `programacionacademica`

Este esquema centraliza las tablas operativas desarrolladas específicamente para este módulo web de programación académica. Incluye la administración de ventanas de apertura por unidad académica, agrupaciones de unidades y la trazabilidad de solicitudes de cambio de horario y préstamo docente.

| # | Tabla | Operaciones Detectadas | Archivos Referenciados | Descripción / Rol Funcional |
| :---: | :--- | :--- | :--- | :--- |
| 1 | **`grupo_uaa`** | Actualización, Inserción, Lectura | `clases/Aperfe.php` | Agrupaciones lógicas de unidades académico-administrativas (UAA) configuradas para apertura y gestión conjunta. |
| 2 | **`grupo_uaa_item`** | Actualización, Inserción, Lectura | `clases/Aperfe.php` | Detalle de unidades (UAA) asignadas a cada grupo lógico de programación académica. |
| 3 | **`periodo_unidad`** | Actualización, Inserción, Lectura | `clases/Aperfe.php`<br>`clases/Buscurso.php`<br>`clases/Cambdocente.php`<br>`clases/Curhorario.php`<br>`clases/Peraca.php` | Control de rangos de fechas (inicio y fin) habilitadas para cada unidad académica dentro de un periodo académico. |
| 4 | **`programacion_academica`** | Actualización, Inserción, Lectura | `clases/Aperfe.php`<br>`clases/Cambdocente.php`<br>`clases/Cupocurso.php`<br>`clases/Curhorario.php`<br>`clases/Soldoc.php` | Registro y control de ventanas de fechas de apertura de programación académica por unidad, calendario y proceso (institucionales, electivas, programas, repesca). |
| 5 | **`programacion_gestion`** | Actualización, Inserción, Lectura | `clases/Aperfe.php`<br>`clases/Cambdocente.php`<br>`clases/Cupocurso.php`<br>`clases/Solcambh.php`<br>`clases/Soldoc.php` | Aperturas de calendario para la gestión administrativa de secretarías de programa por unidad. |
| 6 | **`programacion_tipo_solicitudes`** | Lectura | `clases/Aperfe.php`<br>`clases/Solcambh.php` | Catálogo de tipos de solicitudes de programación académica (cambios de horario, préstamo docente, etc.). |
| 7 | **`solicitud_cambio_horario`** | Actualización, Inserción, Lectura | `clases/Solcambh.php` | Registro de solicitudes de modificación de horario radicadas por programas o secretarías. |
| 8 | **`solicitud_cambio_horario_comentario`** | Inserción, Lectura | `clases/Solcambh.php` | Comentarios, observaciones y trazabilidad de las solicitudes de cambio de horario. |
| 9 | **`solicitud_cambio_horario_horario`** | Actualización, Inserción, Lectura | `clases/Solcambh.php` | Franjas horarias y días propuestos/afectados en las solicitudes de cambio de horario. |
| 10 | **`solicitud_prestamo_docente`** | Actualización, Inserción, Lectura | `clases/Buscurso.php`<br>`clases/Cambdocente.php`<br>`clases/Curcrea.php`<br>`clases/Curhorario.php`<br>`clases/Soldoc.php` | Solicitudes de préstamo o asignación docente entre diferentes unidades académicas. |
| 11 | **`solicitud_prestamo_docente_comentario`** | Inserción, Lectura | `clases/Soldoc.php` | Observaciones y motivos asociados a solicitudes de préstamo docente. |
| 12 | **`solicitud_prestamo_docente_horario`** | Actualización, Inserción, Lectura | `clases/Buscurso.php`<br>`clases/Cambdocente.php`<br>`clases/Curcrea.php`<br>`clases/Curhorario.php`<br>`clases/Soldoc.php` | Horarios y franjas específicas requeridas para el préstamo de docentes entre unidades. |

---

## 3. ESQUEMA `proaca` (DEFINICIÓN DDL)

El esquema `proaca` está presente en el script de definición de base de datos `data_base/2. CreateTablesManagement.sql`. Representa la especificación DDL original para las tres tablas maestras de gestión temporal de programación académica. En el código PHP de producción de las clases (`Aperfe.php`, `Peraca.php`, etc.), estas entidades operan bajo el nombre de esquema unificado `programacionacademica`.

| # | Tabla | Operaciones Detectadas | Archivos Referenciados | Descripción / Rol Funcional |
| :---: | :--- | :--- | :--- | :--- |
| 1 | **`periodo_unidad`** | Creación, Modificación | `data_base/2. CreateTablesManagement.sql` | Definición DDL original de la tabla para fechas independientes de periodo por unidad. |
| 2 | **`programacion_academica`** | Creación, Modificación | `data_base/2. CreateTablesManagement.sql` | Definición DDL original de la tabla para aperturas de programación académica por calendario, unidad y proceso. |
| 3 | **`programacion_gestion`** | Creación, Modificación | `data_base/2. CreateTablesManagement.sql` | Definición DDL original de la tabla para aperturas de gestión de secretarías por calendario y unidad. |

---

## 4. ESQUEMA `proyectos`

El esquema `proyectos` contiene las tablas del subsistema institucional de proyección social e investigación. Es consultado de forma externa y de solo lectura por el servicio de validación de carga complementaria docente para verificar que los profesores no superen los topes de horas semanales y semestrales.

| # | Tabla | Operaciones Detectadas | Archivos Referenciados | Descripción / Rol Funcional |
| :---: | :--- | :--- | :--- | :--- |
| 1 | **`docentexproyecto_proyeccion_social`** | Lectura | `clases/servicios/ValidarCargaDocenteService.php` | Relación de docentes con proyectos de proyección social para cálculo y validación de carga complementaria horaria. |
| 2 | **`proyecto_proyeccion_social`** | Lectura | `clases/servicios/ValidarCargaDocenteService.php` | Catálogo de proyectos de proyección social registrados institucionalmente. |

---

## 5. ESQUEMA `dbo` (TABLAS CON PREFIJO EXPLÍCITO)

Estas tablas son referenciadas en las consultas SQL anteponiendo explícitamente el prefijo de esquema `dbo.` (o `[dbo].`). Corresponden a las tablas maestras institucionales de la base de datos corporativa de la universidad.

| # | Tabla | Operaciones Detectadas | Archivos Referenciados | Descripción / Rol Funcional |
| :---: | :--- | :--- | :--- | :--- |
| 1 | **`asignatura`** | Lectura | `clases/Cupoper.php` | Catálogo general de asignaturas académicas (código, nombre, créditos, horas teóricas y prácticas). |
| 2 | **`calendario`** | Referencia (FK) | `data_base/2. CreateTablesManagement.sql` | Calendarios académicos institucionales asociados a periodos lectivos. |
| 3 | **`grupo`** | Lectura | `clases/Aperfe.php`<br>`clases/Inicio_sesion.php` | Grupos y roles de usuarios dentro del sistema de gestión y permisos. |
| 4 | **`matricula_curso`** | Lectura | `clases/Csh.php` | Inscripción específica de un estudiante en un curso/grupo y subgrupo. |
| 5 | **`nucleo`** | Lectura | `clases/Cupoper.php` | Núcleos de formación o áreas curriculares de conocimiento. |
| 6 | **`periodo`** | Referencia (FK) | `data_base/2. CreateTablesManagement.sql` | Periodos académicos semestrales (identificador, año, semestre, fechas oficiales). |
| 7 | **`persona`** | Lectura | `clases/Aperfe.php`<br>`clases/Inicio_sesion.php` | Información básica de personas (nombres, apellidos, documento, correo electrónico). |
| 8 | **`plan_academico_asignatura`** | Lectura | `clases/Cupoper.php` | Asignaturas pertenecientes a un plan de estudios específico con su semestre/nivel. |
| 9 | **`plan_estudiante`** | Lectura | `clases/Cupoper.php` | Asociación del estudiante con su plan de estudios y programa académico. |
| 10 | **`prerrequisito`** | Lectura | `clases/Cupoper.php` | Requisitos y correquisitos académicos requeridos para cursar una asignatura. |
| 11 | **`programacion_proceso`** | Referencia (FK) | `data_base/2. CreateTablesManagement.sql` | Catálogo de fases o procesos de programación académica (institucionales, electivas, etc.). |
| 12 | **`sede`** | Lectura | `clases/Cupoper.php` | Sedes físicas institucionales (Neiva, Pitalito, Garzón, La Plata, etc.). |
| 13 | **`uaa`** | Lectura, Referencia (FK) | `clases/Cupoper.php`<br>`clases/Inicio_sesion.php`<br>`data_base/2. CreateTablesManagement.sql` | Unidades Académico-Administrativas (facultades, programas, departamentos, oficinas). |
| 14 | **`usuario_administrativo`** | Lectura | `clases/Aperfe.php` | Credenciales y vinculaciones de usuarios administrativos en el sistema. |
| 15 | **`usuario_docente`** | Lectura | `clases/Aperfe.php` | Credenciales y accesos de usuarios de planta o cátedra docente. |
| 16 | **`usuario_general`** | Lectura | `clases/Inicio_sesion.php` | Maestro de usuarios del sistema de información institucional. |
| 17 | **`usuario_grupo`** | Lectura | `clases/Aperfe.php`<br>`clases/Inicio_sesion.php` | Asignación de permisos de usuarios a grupos funcionales por UAA. |
| 18 | **`usuario_programacion`** | Lectura | `clases/Inicio_sesion.php` | Usuarios habilitados para operar el módulo de programación académica. |
| 19 | **`usuario_programacion_login`** | Lectura | `clases/Inicio_sesion.php` | Registro y credenciales de acceso para inicio de sesión en programación académica. |
| 20 | **`web_parametro`** | Lectura | `clases/Inicio_sesion.php` | Parámetros globales de configuración del sistema web. |

---

## 6. TABLAS SIN ESQUEMA EXPLÍCITO PREFIJADO (ESQUEMA POR DEFECTO / `dbo` IMPLÍCITO)

En las consultas SQL del código fuente, una gran cantidad de tablas se invocan directamente por su nombre simple sin prefijo de esquema (por ejemplo: `FROM uaa`, `INNER JOIN curso cur`, `INSERT INTO espacio_ocupacion`). En SQL Server, estas consultas se resuelven contra el esquema por defecto del usuario autenticado (típicamente `dbo`).

| # | Tabla | Operaciones Detectadas | Archivos Referenciados | Descripción / Rol Funcional |
| :---: | :--- | :--- | :--- | :--- |
| 1 | **`agenda_periodo`** | Eliminación, Inserción, Lectura | `clases/Buscurso.php`<br>`clases/Cambdocente.php`<br>`clases/Curcrea.php`<br>`clases/Curhorario.php`<br>`clases/Obsdocente.php`<br>`clases/Solcambh.php`<br>`clases/Soldoc.php`<br>`clases/Vindocente.php`<br>`clases/servicios/ValidarCargaDocenteService.php` | Registro de compromisos de agenda y actividades docentes para un periodo académico. |
| 2 | **`agenda_periodo_novedad`** | Inserción, Lectura | `clases/Obsdocente.php` | Novedades y excepciones aplicadas sobre la agenda de periodos de docentes. |
| 3 | **`asignatura`** | Lectura | `clases/Buscurso.php`<br>`clases/Cambdocente.php`<br>`clases/Ccuser.php`<br>`clases/Ceadmin.php`<br>`clases/Cech.php`<br>`clases/Ceromatriculados.php`<br>`clases/Cmsh.php`<br>`clases/Cpn.php`<br>`clases/Crucehorario.php`<br>`clases/Csh.php`<br>`clases/Csv.php`<br>`clases/Cupocurso.php`<br>`clases/Cupoper.php`<br>`clases/Curcrea.php`<br>`clases/Curhorario.php`<br>`clases/Curpro.php`<br>`clases/Mmatriculados.php`<br>`clases/Rcurhi.php`<br>`clases/Solcambh.php`<br>`clases/Soldoc.php`<br>`clases/Vindocente.php`<br>`clases/servicios/PermisoCurso.php`<br>`clases/servicios/ValidarCargaDocenteService.php` | Catálogo general de asignaturas académicas (código, nombre, créditos, horas teóricas y prácticas). |
| 4 | **`aud_curso`** | Lectura | `clases/Ceadmin.php`<br>`clases/Ceromatriculados.php`<br>`clases/Cupocurso.php` | Pistas de auditoría sobre inserciones, modificaciones y eliminaciones en la entidad de cursos. |
| 5 | **`aud_curso_cupo_subgrupo`** | Lectura | `clases/Ceadmin.php` | Histórico y auditoría de cambios sobre cupos asignados a subgrupos de cursos. |
| 6 | **`aud_espacio_ocupacion`** | Lectura | `clases/Ceadmin.php` | Auditoría de asignación y liberación de espacios físicos y horarios. |
| 7 | **`aud_matricula_curso`** | Lectura | `clases/Cupocurso.php` | Auditoría sobre cambios en la matrícula de estudiantes en cursos. |
| 8 | **`aud_uaa_personal`** | Lectura | `clases/Vindocente.php` | Auditoría de vinculaciones y movimientos de personal docente en unidades académicas. |
| 9 | **`bloque`** | Lectura | `clases/Buscurso.php`<br>`clases/Curhorario.php`<br>`clases/Curpro.php`<br>`clases/Solcambh.php` | Bloques de infraestructura física o módulos de edificios dentro de las sedes. |
| 10 | **`calendario`** | Lectura | `clases/Aperfe.php`<br>`clases/Buscurso.php`<br>`clases/Cambdocente.php`<br>`clases/Cupocurso.php`<br>`clases/Curcrea.php`<br>`clases/Curhorario.php`<br>`clases/Curpro.php`<br>`clases/Mmatriculados.php`<br>`clases/Obsdocente.php`<br>`clases/Rcurhi.php`<br>`clases/Solcambh.php`<br>`clases/Soldoc.php`<br>`clases/Vindocente.php`<br>`clases/servicios/ValidarCargaDocenteService.php` | Calendarios académicos institucionales asociados a periodos lectivos. |
| 11 | **`caracter`** | Lectura | `clases/Buscurso.php`<br>`clases/Ceadmin.php`<br>`clases/Ceromatriculados.php`<br>`clases/Curcrea.php`<br>`clases/Mmatriculados.php`<br>`clases/Solcambh.php` | Clasificación del carácter de las asignaturas (teórica, práctica, teórico-práctica). |
| 12 | **`cargo`** | Lectura | `clases/Inicio_sesion.php` | Catálogo de cargos y funciones desempeñadas por el personal institucional. |
| 13 | **`cupo_autorizacion`** | Eliminación, Inserción, Lectura | `clases/Cupoper.php` | Autorizaciones y registros de solicitudes de modificación de cupo en cursos. |
| 14 | **`curso`** | Actualización, Inserción, Lectura | `clases/Buscurso.php`<br>`clases/Cambdocente.php`<br>`clases/Ccuser.php`<br>`clases/Ceadmin.php`<br>`clases/Cech.php`<br>`clases/Ceromatriculados.php`<br>`clases/Cmsh.php`<br>`clases/Cpn.php`<br>`clases/Crucehorario.php`<br>`clases/Csh.php`<br>`clases/Csv.php`<br>`clases/Cupocurso.php`<br>`clases/Cupoper.php`<br>`clases/Curcrea.php`<br>`clases/Curesp.php`<br>`clases/Curhorario.php`<br>`clases/Curpro.php`<br>`clases/Elicur.php`<br>`clases/Exclu.php`<br>`clases/Mmatriculados.php`<br>`clases/Obscurso.php`<br>`clases/Obsdocente.php`<br>`clases/Rcurhi.php`<br>`clases/Sirea.php`<br>`clases/Solcambh.php`<br>`clases/Soldoc.php`<br>`clases/Vindocente.php`<br>`clases/servicios/PermisoCurso.php`<br>`clases/servicios/ValidarCargaDocenteService.php` | Entidad central de cursos/grupos ofertados y programados en un calendario académico. |
| 15 | **`curso_cupo_subgrupo`** | Actualización, Inserción, Lectura | `clases/Buscurso.php`<br>`clases/Ceromatriculados.php`<br>`clases/Cupocurso.php`<br>`clases/Curhorario.php`<br>`clases/Curpro.php`<br>`clases/Elicur.php`<br>`clases/Sirea.php`<br>`clases/Solcambh.php` | Definición y control de cupos específicos por subgrupo o sección dentro de un curso. |
| 16 | **`curso_institucion_ejecucion`** | Actualización, Inserción, Lectura | `clases/Sirea.php` | Vinculación de convenios o instituciones de ejecución para cursos especiales. |
| 17 | **`curso_plan`** | Eliminación, Inserción, Lectura | `clases/Cupoper.php`<br>`clases/Curcrea.php`<br>`clases/Exclu.php` | Relación entre cursos programados y los planes de estudio correspondientes. |
| 18 | **`curso_tipo`** | Lectura | `clases/Buscurso.php`<br>`clases/Curcrea.php`<br>`clases/Curesp.php`<br>`clases/Solcambh.php` | Clasificación o tipología de cursos ofertados (regulares, especiales, tutoriales). |
| 19 | **`dedicacion`** | Lectura | `clases/Buscurso.php`<br>`clases/Cambdocente.php`<br>`clases/Ceadmin.php`<br>`clases/Cech.php`<br>`clases/Cmsh.php`<br>`clases/Cpn.php`<br>`clases/Csh.php`<br>`clases/Csv.php`<br>`clases/Curcrea.php`<br>`clases/Curhorario.php`<br>`clases/Obsdocente.php`<br>`clases/Rcurhi.php`<br>`clases/Solcambh.php`<br>`clases/Soldoc.php`<br>`clases/Vindocente.php` | Modalidades de dedicación laboral docente (tiempo completo, medio tiempo, cátedra). |
| 20 | **`departamento`** | Lectura | `clases/Sirea.php` | Estructura departamental académica adscrita a las facultades. |
| 21 | **`departamentos_programas_unificados`** | Lectura | `clases/Inicio_sesion.php`<br>`clases/Soldoc.php` | Vista o tabla de consolidación de dependencias y programas unificados. |
| 22 | **`dia`** | Lectura | `clases/Buscurso.php`<br>`clases/Cambdocente.php`<br>`clases/Cech.php`<br>`clases/Cmsh.php`<br>`clases/Cpn.php`<br>`clases/Csv.php`<br>`clases/Curcrea.php`<br>`clases/Curhorario.php`<br>`clases/Curpro.php`<br>`clases/Rcurhi.php`<br>`clases/Solcambh.php`<br>`clases/Soldoc.php`<br>`clases/Vindocente.php` | Catálogo de días de la semana para estructuración de horarios. |
| 23 | **`docente_escalafon`** | Lectura | `clases/Vindocente.php` | Categorización y ubicación en el escalafón del cuerpo docente. |
| 24 | **`equivalencia`** | Lectura | `clases/Buscurso.php`<br>`clases/Cupoper.php`<br>`clases/Curcrea.php` | Equivalencias y homologaciones académicas entre asignaturas de distintos planes. |
| 25 | **`escalafon`** | Lectura | `clases/Vindocente.php` | Niveles del escalafón docente institucional. |
| 26 | **`espacio`** | Lectura | `clases/Buscurso.php`<br>`clases/Cech.php`<br>`clases/Cmsh.php`<br>`clases/Cupocurso.php`<br>`clases/Curcrea.php`<br>`clases/Curhorario.php`<br>`clases/Curpro.php`<br>`clases/Rcurhi.php`<br>`clases/Sirea.php`<br>`clases/Solcambh.php`<br>`clases/Vindocente.php` | Espacios físicos (aulas, laboratorios, auditorios) con capacidad y características. |
| 27 | **`espacio_ocupacion`** | Actualización, Eliminación, Inserción, Lectura | `clases/Buscurso.php`<br>`clases/Cambdocente.php`<br>`clases/Cambiounidad.php`<br>`clases/Ccuser.php`<br>`clases/Cech.php`<br>`clases/Cmsh.php`<br>`clases/Cpn.php`<br>`clases/Csv.php`<br>`clases/Cupocurso.php`<br>`clases/Cupoper.php`<br>`clases/Curcrea.php`<br>`clases/Curhorario.php`<br>`clases/Curpro.php`<br>`clases/Elicur.php`<br>`clases/Rcurhi.php`<br>`clases/Solcambh.php`<br>`clases/Soldoc.php`<br>`clases/servicios/PermisoCurso.php`<br>`clases/servicios/ValidarCargaDocenteService.php` | Horarios activos y asignación física de espacios por curso, docente, día y franja. |
| 28 | **`espacio_ocupacion_historico`** | Actualización, Eliminación, Lectura | `clases/Buscurso.php`<br>`clases/Cambdocente.php`<br>`clases/Curhorario.php` | Histórico de modificaciones y programaciones previas de ocupación de espacios. |
| 29 | **`espacio_ocupacion_total`** | Lectura | `clases/Ceromatriculados.php`<br>`clases/Csh.php`<br>`clases/Curhorario.php`<br>`clases/Mmatriculados.php`<br>`clases/Solcambh.php`<br>`clases/Vindocente.php`<br>`clases/servicios/ValidarCargaDocenteService.php` | Vista consolidada de ocupación horaria total de espacios físicos. |
| 30 | **`espacio_tipo`** | Lectura | `clases/Sirea.php` | Tipos de espacios físicos institucionales (aula magistral, cómputo, taller, etc.). |
| 31 | **`estudiante`** | Lectura | `clases/Crucehorario.php`<br>`clases/Cupocurso.php`<br>`clases/Cupoper.php`<br>`clases/Mmatriculados.php` | Información académica y personal de estudiantes matriculados. |
| 32 | **`estudiante_horario_actual`** | Lectura | `clases/Crucehorario.php` | Vista de horarios vigentes y cursos inscritos por los estudiantes. |
| 33 | **`formalidad`** | Lectura | `clases/Buscurso.php`<br>`clases/Curcrea.php` | Nivel o tipo de formalidad académica de programas y asignaturas. |
| 34 | **`grupo`** | Lectura | `clases/Inicio_sesion.php` | Grupos y roles de usuarios dentro del sistema de gestión y permisos. |
| 35 | **`hora`** | Lectura | `clases/Buscurso.php`<br>`clases/Cambdocente.php`<br>`clases/Cech.php`<br>`clases/Cmsh.php`<br>`clases/Cpn.php`<br>`clases/Crucehorario.php`<br>`clases/Csv.php`<br>`clases/Curcrea.php`<br>`clases/Curhorario.php`<br>`clases/Curpro.php`<br>`clases/Rcurhi.php`<br>`clases/Solcambh.php`<br>`clases/Soldoc.php`<br>`clases/Vindocente.php` | Franjas horarias institucionales (hora inicio y hora fin) por bloque de clase. |
| 36 | **`matricula`** | Lectura | `clases/Ceromatriculados.php`<br>`clases/Crucehorario.php`<br>`clases/Cupocurso.php`<br>`clases/Cupoper.php`<br>`clases/Curhorario.php`<br>`clases/Curpro.php`<br>`clases/Elicur.php`<br>`clases/Matcurso.php`<br>`clases/Mmatriculados.php`<br>`clases/Sirea.php` | Registro maestro de matrícula de estudiantes para un periodo académico. |
| 37 | **`matricula_autorizacion`** | Lectura | `clases/Cupocurso.php` | Autorizaciones de matrícula extemporánea, créditos adicionales o excepciones. |
| 38 | **`matricula_configuracion`** | Lectura | `clases/Curpro.php` | Configuración y reglas de fechas y topes del proceso de matrícula. |
| 39 | **`matricula_configuracion_detalle`** | Lectura | `clases/Curpro.php` | Reglas y parámetros detallados por programa para el proceso de matrícula. |
| 40 | **`matricula_curso`** | Lectura | `clases/Buscurso.php`<br>`clases/Cambdocente.php`<br>`clases/Cech.php`<br>`clases/Ceromatriculados.php`<br>`clases/Cmsh.php`<br>`clases/Cpn.php`<br>`clases/Crucehorario.php`<br>`clases/Csv.php`<br>`clases/Cupocurso.php`<br>`clases/Cupoper.php`<br>`clases/Curcrea.php`<br>`clases/Curhorario.php`<br>`clases/Curpro.php`<br>`clases/Elicur.php`<br>`clases/Matcurso.php`<br>`clases/Mmatriculados.php`<br>`clases/Rcurhi.php`<br>`clases/Sirea.php`<br>`clases/Solcambh.php`<br>`clases/Soldoc.php` | Inscripción específica de un estudiante en un curso/grupo y subgrupo. |
| 41 | **`municipio`** | Lectura | `clases/Sirea.php` | Catálogo geográfico de municipios asociados a sedes o lugares de desarrollo. |
| 42 | **`nivel_academico`** | Lectura | `clases/Aperfe.php`<br>`clases/Buscurso.php`<br>`clases/Curcrea.php` | Niveles de formación académica (pregrado, posgrado, especialización, maestría, doctorado). |
| 43 | **`notas_total`** | Lectura | `clases/Mmatriculados.php` | Vista consolidada de calificaciones y promedios académicos de estudiantes. |
| 44 | **`novedad`** | Lectura | `clases/Curhorario.php`<br>`clases/Solcambh.php`<br>`clases/servicios/ValidarCargaDocenteService.php` | Tipos de novedades de descarga horaria o situaciones administrativas docentes. |
| 45 | **`nucleo`** | Lectura | `clases/Buscurso.php`<br>`clases/Ceadmin.php`<br>`clases/Ceromatriculados.php`<br>`clases/Cpn.php`<br>`clases/Cupocurso.php`<br>`clases/Curcrea.php`<br>`clases/Mmatriculados.php`<br>`clases/Solcambh.php` | Núcleos de formación o áreas curriculares de conocimiento. |
| 46 | **`periodo`** | Lectura | `clases/Aperfe.php`<br>`clases/Buscurso.php`<br>`clases/Cambdocente.php`<br>`clases/Curcrea.php`<br>`clases/Curhorario.php`<br>`clases/Obsdocente.php`<br>`clases/Peraca.php`<br>`clases/Solcambh.php`<br>`clases/Soldoc.php`<br>`clases/servicios/ValidarCargaDocenteService.php` | Periodos académicos semestrales (identificador, año, semestre, fechas oficiales). |
| 47 | **`persona`** | Lectura | `clases/Aperfe.php`<br>`clases/Buscurso.php`<br>`clases/Cambdocente.php`<br>`clases/Ccuser.php`<br>`clases/Ceadmin.php`<br>`clases/Cech.php`<br>`clases/Ceromatriculados.php`<br>`clases/Cmsh.php`<br>`clases/Cpn.php`<br>`clases/Crucehorario.php`<br>`clases/Csh.php`<br>`clases/Csv.php`<br>`clases/Cupocurso.php`<br>`clases/Cupoper.php`<br>`clases/Curcrea.php`<br>`clases/Curhorario.php`<br>`clases/Curpro.php`<br>`clases/Elicur.php`<br>`clases/Inicio_sesion.php`<br>`clases/Mmatriculados.php`<br>`clases/Obsdocente.php`<br>`clases/Rcurhi.php`<br>`clases/Solcambh.php`<br>`clases/Soldoc.php`<br>`clases/Vindocente.php` | Información básica de personas (nombres, apellidos, documento, correo electrónico). |
| 48 | **`persona_novedad`** | Lectura | `clases/Curhorario.php`<br>`clases/Solcambh.php`<br>`clases/servicios/ValidarCargaDocenteService.php` | Novedades laborales y administrativas asociadas a una persona (descargas, permisos). |
| 49 | **`persona_proyecto`** | Lectura | `clases/Curhorario.php`<br>`clases/Solcambh.php`<br>`clases/Soldoc.php`<br>`clases/servicios/ValidarCargaDocenteService.php` | Asignación de personas a proyectos institucionales de investigación o extensión. |
| 50 | **`plan_academico`** | Lectura | `clases/Buscurso.php`<br>`clases/Cupoper.php`<br>`clases/Curcrea.php`<br>`clases/Curpro.php`<br>`clases/Exclu.php`<br>`clases/Mmatriculados.php`<br>`clases/Solcambh.php` | Planes de estudio o mallas curriculares vigentes para cada programa académico. |
| 51 | **`plan_academico_asignatura`** | Lectura | `clases/Buscurso.php`<br>`clases/Cupoper.php`<br>`clases/Curcrea.php`<br>`clases/Mmatriculados.php` | Asignaturas pertenecientes a un plan de estudios específico con su semestre/nivel. |
| 52 | **`plan_estudiante`** | Lectura | `clases/Cupoper.php`<br>`clases/Mmatriculados.php` | Asociación del estudiante con su plan de estudios y programa académico. |
| 53 | **`programa`** | Lectura | `clases/Aperfe.php`<br>`clases/Buscurso.php`<br>`clases/Cupocurso.php`<br>`clases/Cupoper.php`<br>`clases/Curcrea.php`<br>`clases/Curpro.php`<br>`clases/Exclu.php`<br>`clases/Inicio_sesion.php`<br>`clases/Mmatriculados.php`<br>`clases/Soldoc.php`<br>`clases/servicios/PermisoCurso.php` | Programas académicos ofrecidos por la institución y sus unidades unificadas. |
| 54 | **`programacion_proceso`** | Lectura | `clases/Aperfe.php`<br>`clases/Curhorario.php` | Catálogo de fases o procesos de programación académica (institucionales, electivas, etc.). |
| 55 | **`proyecto`** | Lectura | `clases/Curhorario.php`<br>`clases/Solcambh.php`<br>`clases/Soldoc.php`<br>`clases/servicios/ValidarCargaDocenteService.php` | Proyectos institucionales de docencia, investigación o extensión. |
| 56 | **`proyecto_tipo`** | Lectura | `clases/Curhorario.php`<br>`clases/Solcambh.php`<br>`clases/Soldoc.php`<br>`clases/servicios/ValidarCargaDocenteService.php` | Clasificación de tipologías de proyectos institucionales. |
| 57 | **`resumen_docencia_final`** | Lectura | `clases/Buscurso.php`<br>`clases/Curhorario.php` | Vista consolidada de horas y asignación de docencia directa y complementaria. |
| 58 | **`sede`** | Lectura | `clases/Buscurso.php`<br>`clases/Cambdocente.php`<br>`clases/Ceadmin.php`<br>`clases/Ceromatriculados.php`<br>`clases/Cmsh.php`<br>`clases/Cpn.php`<br>`clases/Csv.php`<br>`clases/Cupocurso.php`<br>`clases/Curcrea.php`<br>`clases/Curhorario.php`<br>`clases/Curpro.php`<br>`clases/Mmatriculados.php`<br>`clases/Solcambh.php`<br>`clases/Soldoc.php`<br>`clases/Vindocente.php` | Sedes físicas institucionales (Neiva, Pitalito, Garzón, La Plata, etc.). |
| 59 | **`sub_sede`** | Lectura | `clases/Buscurso.php`<br>`clases/Curhorario.php`<br>`clases/Curpro.php`<br>`clases/Solcambh.php` | Sub-sedes o campus específicos pertenecientes a una sede principal. |
| 60 | **`tipo_curso`** | Lectura | `clases/Buscurso.php`<br>`clases/Ccuser.php`<br>`clases/Ceadmin.php`<br>`clases/Cech.php`<br>`clases/Cmsh.php`<br>`clases/Cpn.php`<br>`clases/Csh.php`<br>`clases/Csv.php`<br>`clases/Curpro.php`<br>`clases/Rcurhi.php`<br>`clases/Solcambh.php`<br>`clases/Vindocente.php` | Tipologías de cursos en oferta académica. |
| 61 | **`tipo_escala`** | Lectura | `clases/Solcambh.php` | Escalas de calificación y evaluación aplicadas a asignaturas. |
| 62 | **`uaa`** | Lectura | `clases/Aperfe.php`<br>`clases/Buscurso.php`<br>`clases/Cambdocente.php`<br>`clases/Ccuser.php`<br>`clases/Ceadmin.php`<br>`clases/Cech.php`<br>`clases/Ceromatriculados.php`<br>`clases/Cmsh.php`<br>`clases/Cpn.php`<br>`clases/Csh.php`<br>`clases/Csv.php`<br>`clases/Cupocurso.php`<br>`clases/Cupoper.php`<br>`clases/Curcrea.php`<br>`clases/Curhorario.php`<br>`clases/Curpro.php`<br>`clases/Exclu.php`<br>`clases/Inicio_sesion.php`<br>`clases/Mmatriculados.php`<br>`clases/Obsdocente.php`<br>`clases/Peraca.php`<br>`clases/Rcurhi.php`<br>`clases/Solcambh.php`<br>`clases/Soldoc.php`<br>`clases/Vindocente.php`<br>`clases/servicios/PermisoCurso.php` | Unidades Académico-Administrativas (facultades, programas, departamentos, oficinas). |
| 63 | **`uaa_cargo`** | Lectura | `clases/Inicio_sesion.php` | Asignación de cargos de dirección o coordinación dentro de una UAA. |
| 64 | **`uaa_personal`** | Lectura | `clases/Buscurso.php`<br>`clases/Cambdocente.php`<br>`clases/Ceadmin.php`<br>`clases/Cech.php`<br>`clases/Ceromatriculados.php`<br>`clases/Cmsh.php`<br>`clases/Cpn.php`<br>`clases/Csh.php`<br>`clases/Csv.php`<br>`clases/Cupocurso.php`<br>`clases/Curcrea.php`<br>`clases/Curhorario.php`<br>`clases/Curpro.php`<br>`clases/Elicur.php`<br>`clases/Inicio_sesion.php`<br>`clases/Obsdocente.php`<br>`clases/Rcurhi.php`<br>`clases/Solcambh.php`<br>`clases/Soldoc.php`<br>`clases/Vindocente.php`<br>`clases/servicios/ValidarCargaDocenteService.php` | Vinculación de docentes y funcionarios a una unidad académica (persona, cargo, dedicación). |
| 65 | **`usuario_administrativo`** | Lectura | `clases/Aperfe.php`<br>`clases/Cupocurso.php` | Credenciales y vinculaciones de usuarios administrativos en el sistema. |
| 66 | **`usuario_docente`** | Lectura | `clases/Aperfe.php`<br>`clases/Cupocurso.php` | Credenciales y accesos de usuarios de planta o cátedra docente. |
| 67 | **`usuario_general`** | Lectura | `clases/Ccuser.php`<br>`clases/Ceromatriculados.php`<br>`clases/Rcurhi.php`<br>`clases/Solcambh.php`<br>`clases/Soldoc.php` | Maestro de usuarios del sistema de información institucional. |
| 68 | **`usuario_grupo`** | Lectura | `clases/Aperfe.php`<br>`clases/Inicio_sesion.php`<br>`clases/servicios/PermisoCurso.php` | Asignación de permisos de usuarios a grupos funcionales por UAA. |
| 69 | **`usuario_planta_fisica`** | Lectura | `clases/Solcambh.php` | Usuarios con permisos de administración de recursos y planta física. |
| 70 | **`usuario_programacion`** | Lectura | `clases/Inicio_sesion.php`<br>`clases/Solcambh.php`<br>`clases/Soldoc.php` | Usuarios habilitados para operar el módulo de programación académica. |
| 71 | **`usuario_programacion_login`** | Lectura | `clases/Inicio_sesion.php` | Registro y credenciales de acceso para inicio de sesión en programación académica. |
| 72 | **`vinculacion`** | Lectura | `clases/Buscurso.php`<br>`clases/Cambdocente.php`<br>`clases/Ceadmin.php`<br>`clases/Cech.php`<br>`clases/Cmsh.php`<br>`clases/Cpn.php`<br>`clases/Csh.php`<br>`clases/Csv.php`<br>`clases/Curcrea.php`<br>`clases/Curhorario.php`<br>`clases/Obsdocente.php`<br>`clases/Rcurhi.php`<br>`clases/Solcambh.php`<br>`clases/Soldoc.php`<br>`clases/Vindocente.php` | Tipos de vinculación laboral docente (planta, ocasional, catedrático, etc.). |
| 73 | **`web_parametro`** | Actualización, Lectura | `clases/Aperfe.php`<br>`clases/Confgen.php`<br>`clases/Cupoper.php`<br>`clases/Curhorario.php`<br>`clases/Inicio_sesion.php`<br>`clases/Solcambh.php`<br>`clases/Soldoc.php`<br>`clases/servicios/ValidarCargaDocenteService.php` | Parámetros globales de configuración del sistema web. |

---

## 7. ANÁLISIS DE CONVERGENCIA Y COINCIDENCIA DE ESQUEMAS

### 7.1 Tablas con Referencia Dual (con y sin prefijo `dbo`)
Se identificaron **19 tablas institucionales** que en ciertos archivos o consultas son invocadas con el prefijo explícito `dbo.<tabla>` y en otros son invocadas con su nombre simple sin prefijo (`<tabla>`):

| # | Tabla | Archivos con `dbo.<tabla>` | Archivos sin prefijo `<tabla>` |
| :---: | :--- | :--- | :--- |
| 1 | **`asignatura`** | `Cupoper.php` | `Buscurso.php`, `Cambdocente.php`, `Ccuser.php`, `Ceadmin.php` (+19 más) |
| 2 | **`calendario`** | `2. CreateTablesManagement.sql` | `Aperfe.php`, `Buscurso.php`, `Cambdocente.php`, `Cupocurso.php` (+10 más) |
| 3 | **`grupo`** | `Aperfe.php`, `Inicio_sesion.php` | `Inicio_sesion.php` |
| 4 | **`matricula_curso`** | `Csh.php` | `Buscurso.php`, `Cambdocente.php`, `Cech.php`, `Ceromatriculados.php` (+16 más) |
| 5 | **`nucleo`** | `Cupoper.php` | `Buscurso.php`, `Ceadmin.php`, `Ceromatriculados.php`, `Cpn.php` (+4 más) |
| 6 | **`periodo`** | `2. CreateTablesManagement.sql` | `Aperfe.php`, `Buscurso.php`, `Cambdocente.php`, `Curcrea.php` (+6 más) |
| 7 | **`persona`** | `Aperfe.php`, `Inicio_sesion.php` | `Aperfe.php`, `Buscurso.php`, `Cambdocente.php`, `Ccuser.php` (+21 más) |
| 8 | **`plan_academico_asignatura`** | `Cupoper.php` | `Buscurso.php`, `Cupoper.php`, `Curcrea.php`, `Mmatriculados.php` |
| 9 | **`plan_estudiante`** | `Cupoper.php` | `Cupoper.php`, `Mmatriculados.php` |
| 10 | **`programacion_proceso`** | `2. CreateTablesManagement.sql` | `Aperfe.php`, `Curhorario.php` |
| 11 | **`sede`** | `Cupoper.php` | `Buscurso.php`, `Cambdocente.php`, `Ceadmin.php`, `Ceromatriculados.php` (+11 más) |
| 12 | **`uaa`** | `Cupoper.php`, `Inicio_sesion.php`, `2. CreateTablesManagement.sql` | `Aperfe.php`, `Buscurso.php`, `Cambdocente.php`, `Ccuser.php` (+22 más) |
| 13 | **`usuario_administrativo`** | `Aperfe.php` | `Aperfe.php`, `Cupocurso.php` |
| 14 | **`usuario_docente`** | `Aperfe.php` | `Aperfe.php`, `Cupocurso.php` |
| 15 | **`usuario_general`** | `Inicio_sesion.php` | `Ccuser.php`, `Ceromatriculados.php`, `Rcurhi.php`, `Solcambh.php` (+1 más) |
| 16 | **`usuario_grupo`** | `Aperfe.php`, `Inicio_sesion.php` | `Aperfe.php`, `Inicio_sesion.php`, `PermisoCurso.php` |
| 17 | **`usuario_programacion`** | `Inicio_sesion.php` | `Inicio_sesion.php`, `Solcambh.php`, `Soldoc.php` |
| 18 | **`usuario_programacion_login`** | `Inicio_sesion.php` | `Inicio_sesion.php` |
| 19 | **`web_parametro`** | `Inicio_sesion.php` | `Aperfe.php`, `Confgen.php`, `Cupoper.php`, `Curhorario.php` (+4 más) |

> **Nota técnica:** La tabla `prerrequisito` es la única tabla institucional que **exclusivamente** aparece con prefijo `dbo.prerrequisito` en `clases/Cupoper.php:456`, sin tener menciones sin prefijo.

### 7.2 Convergencia entre `proaca` y `programacionacademica`
En `data_base/1. Create Schema.sql` se ejecuta:
```sql
CREATE SCHEMA programacionacademica; -- creamos el esquema de programacion academica para centralizar todo lo que se pueda.
```
Mientras que en `data_base/2. CreateTablesManagement.sql` se definen:
- `[proaca].[programacion_academica]`
- `[proaca].[programacion_gestion]`
- `[proaca].[periodo_unidad]`

Sin embargo, en la capa lógica PHP (`Aperfe.php`, `Peraca.php`, `Cambdocente.php`, etc.), estas tres tablas son leídas y actualizadas bajo el esquema `programacionacademica`:
- `programacionacademica.programacion_academica`
- `programacionacademica.programacion_gestion`
- `programacionacademica.periodo_unidad`
Esto evidencia que `proaca` fue un acrónimo de desarrollo preliminar que convergió formalmente en el esquema `programacionacademica`.

---

## 8. OBJETOS ESPECIALES, VISTAS Y ESTRUCTURAS EN MEMORIA

Durante el análisis exhaustivo se detectaron objetos que syntácticamente aparecen en cláusulas `FROM`, `JOIN` o `APPLY`, pero que tienen una naturaleza técnica distinta a tablas base:

### 8.1 Funciones con Valor de Tabla (Table-Valued Functions - TVF)
- **`dbo.personaFromSys(aud.aud_user)`**: Función definida por el usuario en `dbo`, invocada mediante `CROSS APPLY` en `clases/Ceadmin.php` (líneas 86 y 134, en las consultas iniciadas en las líneas 52 y 94) para convertir nombres de usuario del sistema operativo/auditoría en registros de personas.

### 8.2 Funciones Escalares de Base de Datos (Scalar User-Defined Functions - UDF)
- **`dbo.validarUsuarioProgramacion($usuario, $contra1)`**: Función escalar en `dbo` invocada en `clases/Inicio_sesion.php` (línea 28) para validar credenciales y estado activo del usuario en el módulo de programación académica (retorna `1` si es válido y activo, `0` en caso contrario).
- **`dbo.getClaveRealProgramacion($usuario, $contra1, $contra2)`**: Función escalar en `dbo` invocada en `clases/Inicio_sesion.php` (línea 218) para obtener o desencriptar la clave real de conexión con privilegios de escritura en SQL Server.

### 8.3 Expresiones de Tabla Común (CTEs - Common Table Expressions)
- **`horario_curso`**: CTE temporal definida mediante cláusula `WITH horario_curso AS (...)` en `clases/Rcurhi.php` (línea 78).
- **`cursos`**: CTE temporal encadenada en la misma consulta `WITH ... cursos AS (...)` en `clases/Rcurhi.php` (línea 121), consultada luego mediante `FROM cursos`.

### 8.4 Variables de Tabla en Memoria (T-SQL Table Variables)
En el procedimiento de validación masiva de colisiones de horario en `clases/Crucehorario.php` (líneas 92-150), se declaran y manipulan variables de tabla locales en memoria:
- `@tbl_fechas_futuro`
- `@tbl_horas`
- `@tbl_fechas_exactas`
- `@tbl_matriculados`
- `@tbl_horario_matriculados`

### 8.5 Vistas Relacionales (Views)
Las siguientes entidades corresponden a vistas de base de datos institucionales (en lugar de tablas base directas), aunque son consumidas mediante sentencias `SELECT` transparentemente:
- `departamentos_programas_unificados`: Vista de consolidación de UAA unificadas.
- `espacio_ocupacion_total`: Vista consolidada de ocupación horaria y de infraestructura física.
- `estudiante_horario_actual`: Vista de matrícula y carga horaria vigente del estudiante.
- `notas_total`: Vista acumulada de calificaciones y promedios.
- `resumen_docencia_final`: Vista institucional de cálculo de horas de docencia directa.

---

## 9. MATRIZ DE TRAZABILIDAD INVERSA (ARCHIVO FUENTE -> TABLAS)

A continuación se lista cada uno de los 37 archivos fuente del sistema que interactúan con la base de datos, detallando el conjunto de tablas y esquemas que referencia cada uno:

### `clases/Aperfe.php`
- **dbo** (5): `grupo`, `persona`, `usuario_administrativo`, `usuario_docente`, `usuario_grupo`
- **programacionacademica** (6): `grupo_uaa`, `grupo_uaa_item`, `periodo_unidad`, `programacion_academica`, `programacion_gestion`, `programacion_tipo_solicitudes`
- **Esquema por defecto (sin prefijo)** (11): `calendario`, `nivel_academico`, `periodo`, `persona`, `programa`, `programacion_proceso`, `uaa`, `usuario_administrativo`, `usuario_docente`, `usuario_grupo`, `web_parametro`

### `clases/Buscurso.php`
- **programacionacademica** (3): `periodo_unidad`, `solicitud_prestamo_docente`, `solicitud_prestamo_docente_horario`
- **Esquema por defecto (sin prefijo)** (31): `agenda_periodo`, `asignatura`, `bloque`, `calendario`, `caracter`, `curso`, `curso_cupo_subgrupo`, `curso_tipo`, `dedicacion`, `dia`, `equivalencia`, `espacio`, `espacio_ocupacion`, `espacio_ocupacion_historico`, `formalidad`, `hora`, `matricula_curso`, `nivel_academico`, `nucleo`, `periodo`, `persona`, `plan_academico`, `plan_academico_asignatura`, `programa`, `resumen_docencia_final`, `sede`, `sub_sede`, `tipo_curso`, `uaa`, `uaa_personal`, `vinculacion`

### `clases/Cambdocente.php`
- **programacionacademica** (5): `periodo_unidad`, `programacion_academica`, `programacion_gestion`, `solicitud_prestamo_docente`, `solicitud_prestamo_docente_horario`
- **Esquema por defecto (sin prefijo)** (16): `agenda_periodo`, `asignatura`, `calendario`, `curso`, `dedicacion`, `dia`, `espacio_ocupacion`, `espacio_ocupacion_historico`, `hora`, `matricula_curso`, `periodo`, `persona`, `sede`, `uaa`, `uaa_personal`, `vinculacion`

### `clases/Cambiounidad.php`
- **Esquema por defecto (sin prefijo)** (1): `espacio_ocupacion`

### `clases/Ccuser.php`
- **Esquema por defecto (sin prefijo)** (7): `asignatura`, `curso`, `espacio_ocupacion`, `persona`, `tipo_curso`, `uaa`, `usuario_general`

### `clases/Ceadmin.php`
- **Esquema por defecto (sin prefijo)** (14): `asignatura`, `aud_curso`, `aud_curso_cupo_subgrupo`, `aud_espacio_ocupacion`, `caracter`, `curso`, `dedicacion`, `nucleo`, `persona`, `sede`, `tipo_curso`, `uaa`, `uaa_personal`, `vinculacion`

### `clases/Cech.php`
- **Esquema por defecto (sin prefijo)** (13): `asignatura`, `curso`, `dedicacion`, `dia`, `espacio`, `espacio_ocupacion`, `hora`, `matricula_curso`, `persona`, `tipo_curso`, `uaa`, `uaa_personal`, `vinculacion`

### `clases/Ceromatriculados.php`
- **Esquema por defecto (sin prefijo)** (14): `asignatura`, `aud_curso`, `caracter`, `curso`, `curso_cupo_subgrupo`, `espacio_ocupacion_total`, `matricula`, `matricula_curso`, `nucleo`, `persona`, `sede`, `uaa`, `uaa_personal`, `usuario_general`

### `clases/Cmsh.php`
- **Esquema por defecto (sin prefijo)** (14): `asignatura`, `curso`, `dedicacion`, `dia`, `espacio`, `espacio_ocupacion`, `hora`, `matricula_curso`, `persona`, `sede`, `tipo_curso`, `uaa`, `uaa_personal`, `vinculacion`

### `clases/Confgen.php`
- **Esquema por defecto (sin prefijo)** (1): `web_parametro`

### `clases/Cpn.php`
- **Esquema por defecto (sin prefijo)** (14): `asignatura`, `curso`, `dedicacion`, `dia`, `espacio_ocupacion`, `hora`, `matricula_curso`, `nucleo`, `persona`, `sede`, `tipo_curso`, `uaa`, `uaa_personal`, `vinculacion`

### `clases/Crucehorario.php`
- **Esquema por defecto (sin prefijo)** (8): `asignatura`, `curso`, `estudiante`, `estudiante_horario_actual`, `hora`, `matricula`, `matricula_curso`, `persona`

### `clases/Csh.php`
- **dbo** (1): `matricula_curso`
- **Esquema por defecto (sin prefijo)** (9): `asignatura`, `curso`, `dedicacion`, `espacio_ocupacion_total`, `persona`, `tipo_curso`, `uaa`, `uaa_personal`, `vinculacion`

### `clases/Csv.php`
- **Esquema por defecto (sin prefijo)** (13): `asignatura`, `curso`, `dedicacion`, `dia`, `espacio_ocupacion`, `hora`, `matricula_curso`, `persona`, `sede`, `tipo_curso`, `uaa`, `uaa_personal`, `vinculacion`

### `clases/Cupocurso.php`
- **programacionacademica** (2): `programacion_academica`, `programacion_gestion`
- **Esquema por defecto (sin prefijo)** (20): `asignatura`, `aud_curso`, `aud_matricula_curso`, `calendario`, `curso`, `curso_cupo_subgrupo`, `espacio`, `espacio_ocupacion`, `estudiante`, `matricula`, `matricula_autorizacion`, `matricula_curso`, `nucleo`, `persona`, `programa`, `sede`, `uaa`, `uaa_personal`, `usuario_administrativo`, `usuario_docente`

### `clases/Cupoper.php`
- **dbo** (7): `asignatura`, `nucleo`, `plan_academico_asignatura`, `plan_estudiante`, `prerrequisito`, `sede`, `uaa`
- **Esquema por defecto (sin prefijo)** (16): `asignatura`, `cupo_autorizacion`, `curso`, `curso_plan`, `equivalencia`, `espacio_ocupacion`, `estudiante`, `matricula`, `matricula_curso`, `persona`, `plan_academico`, `plan_academico_asignatura`, `plan_estudiante`, `programa`, `uaa`, `web_parametro`

### `clases/Curcrea.php`
- **programacionacademica** (2): `solicitud_prestamo_docente`, `solicitud_prestamo_docente_horario`
- **Esquema por defecto (sin prefijo)** (26): `agenda_periodo`, `asignatura`, `calendario`, `caracter`, `curso`, `curso_plan`, `curso_tipo`, `dedicacion`, `dia`, `equivalencia`, `espacio`, `espacio_ocupacion`, `formalidad`, `hora`, `matricula_curso`, `nivel_academico`, `nucleo`, `periodo`, `persona`, `plan_academico`, `plan_academico_asignatura`, `programa`, `sede`, `uaa`, `uaa_personal`, `vinculacion`

### `clases/Curesp.php`
- **Esquema por defecto (sin prefijo)** (2): `curso`, `curso_tipo`

### `clases/Curhorario.php`
- **programacionacademica** (4): `periodo_unidad`, `programacion_academica`, `solicitud_prestamo_docente`, `solicitud_prestamo_docente_horario`
- **Esquema por defecto (sin prefijo)** (30): `agenda_periodo`, `asignatura`, `bloque`, `calendario`, `curso`, `curso_cupo_subgrupo`, `dedicacion`, `dia`, `espacio`, `espacio_ocupacion`, `espacio_ocupacion_historico`, `espacio_ocupacion_total`, `hora`, `matricula`, `matricula_curso`, `novedad`, `periodo`, `persona`, `persona_novedad`, `persona_proyecto`, `programacion_proceso`, `proyecto`, `proyecto_tipo`, `resumen_docencia_final`, `sede`, `sub_sede`, `uaa`, `uaa_personal`, `vinculacion`, `web_parametro`

### `clases/Curpro.php`
- **Esquema por defecto (sin prefijo)** (21): `asignatura`, `bloque`, `calendario`, `curso`, `curso_cupo_subgrupo`, `dia`, `espacio`, `espacio_ocupacion`, `hora`, `matricula`, `matricula_configuracion`, `matricula_configuracion_detalle`, `matricula_curso`, `persona`, `plan_academico`, `programa`, `sede`, `sub_sede`, `tipo_curso`, `uaa`, `uaa_personal`

### `clases/Elicur.php`
- **Esquema por defecto (sin prefijo)** (7): `curso`, `curso_cupo_subgrupo`, `espacio_ocupacion`, `matricula`, `matricula_curso`, `persona`, `uaa_personal`

### `clases/Exclu.php`
- **Esquema por defecto (sin prefijo)** (5): `curso`, `curso_plan`, `plan_academico`, `programa`, `uaa`

### `clases/Inicio_sesion.php`
- **dbo** (8): `grupo`, `persona`, `uaa`, `usuario_general`, `usuario_grupo`, `usuario_programacion`, `usuario_programacion_login`, `web_parametro`
- **Esquema por defecto (sin prefijo)** (12): `cargo`, `departamentos_programas_unificados`, `grupo`, `persona`, `programa`, `uaa`, `uaa_cargo`, `uaa_personal`, `usuario_grupo`, `usuario_programacion`, `usuario_programacion_login`, `web_parametro`

### `clases/Matcurso.php`
- **Esquema por defecto (sin prefijo)** (2): `matricula`, `matricula_curso`

### `clases/Mmatriculados.php`
- **Esquema por defecto (sin prefijo)** (17): `asignatura`, `calendario`, `caracter`, `curso`, `espacio_ocupacion_total`, `estudiante`, `matricula`, `matricula_curso`, `notas_total`, `nucleo`, `persona`, `plan_academico`, `plan_academico_asignatura`, `plan_estudiante`, `programa`, `sede`, `uaa`

### `clases/Obscurso.php`
- **Esquema por defecto (sin prefijo)** (1): `curso`

### `clases/Obsdocente.php`
- **Esquema por defecto (sin prefijo)** (10): `agenda_periodo`, `agenda_periodo_novedad`, `calendario`, `curso`, `dedicacion`, `periodo`, `persona`, `uaa`, `uaa_personal`, `vinculacion`

### `clases/Peraca.php`
- **programacionacademica** (1): `periodo_unidad`
- **Esquema por defecto (sin prefijo)** (2): `periodo`, `uaa`

### `clases/Rcurhi.php`
- **Esquema por defecto (sin prefijo)** (15): `asignatura`, `calendario`, `curso`, `dedicacion`, `dia`, `espacio`, `espacio_ocupacion`, `hora`, `matricula_curso`, `persona`, `tipo_curso`, `uaa`, `uaa_personal`, `usuario_general`, `vinculacion`

### `clases/Sirea.php`
- **Esquema por defecto (sin prefijo)** (9): `curso`, `curso_cupo_subgrupo`, `curso_institucion_ejecucion`, `departamento`, `espacio`, `espacio_tipo`, `matricula`, `matricula_curso`, `municipio`

### `clases/Solcambh.php`
- **programacionacademica** (5): `programacion_gestion`, `programacion_tipo_solicitudes`, `solicitud_cambio_horario`, `solicitud_cambio_horario_comentario`, `solicitud_cambio_horario_horario`
- **Esquema por defecto (sin prefijo)** (35): `agenda_periodo`, `asignatura`, `bloque`, `calendario`, `caracter`, `curso`, `curso_cupo_subgrupo`, `curso_tipo`, `dedicacion`, `dia`, `espacio`, `espacio_ocupacion`, `espacio_ocupacion_total`, `hora`, `matricula_curso`, `novedad`, `nucleo`, `periodo`, `persona`, `persona_novedad`, `persona_proyecto`, `plan_academico`, `proyecto`, `proyecto_tipo`, `sede`, `sub_sede`, `tipo_curso`, `tipo_escala`, `uaa`, `uaa_personal`, `usuario_general`, `usuario_planta_fisica`, `usuario_programacion`, `vinculacion`, `web_parametro`

### `clases/Soldoc.php`
- **programacionacademica** (5): `programacion_academica`, `programacion_gestion`, `solicitud_prestamo_docente`, `solicitud_prestamo_docente_comentario`, `solicitud_prestamo_docente_horario`
- **Esquema por defecto (sin prefijo)** (23): `agenda_periodo`, `asignatura`, `calendario`, `curso`, `dedicacion`, `departamentos_programas_unificados`, `dia`, `espacio_ocupacion`, `hora`, `matricula_curso`, `periodo`, `persona`, `persona_proyecto`, `programa`, `proyecto`, `proyecto_tipo`, `sede`, `uaa`, `uaa_personal`, `usuario_general`, `usuario_programacion`, `vinculacion`, `web_parametro`

### `clases/Vindocente.php`
- **Esquema por defecto (sin prefijo)** (18): `agenda_periodo`, `asignatura`, `aud_uaa_personal`, `calendario`, `curso`, `dedicacion`, `dia`, `docente_escalafon`, `escalafon`, `espacio`, `espacio_ocupacion_total`, `hora`, `persona`, `sede`, `tipo_curso`, `uaa`, `uaa_personal`, `vinculacion`

### `clases/servicios/PermisoCurso.php`
- **Esquema por defecto (sin prefijo)** (6): `asignatura`, `curso`, `espacio_ocupacion`, `programa`, `uaa`, `usuario_grupo`

### `clases/servicios/ValidarCargaDocenteService.php`
- **proyectos** (2): `docentexproyecto_proyeccion_social`, `proyecto_proyeccion_social`
- **Esquema por defecto (sin prefijo)** (14): `agenda_periodo`, `asignatura`, `calendario`, `curso`, `espacio_ocupacion`, `espacio_ocupacion_total`, `novedad`, `periodo`, `persona_novedad`, `persona_proyecto`, `proyecto`, `proyecto_tipo`, `uaa_personal`, `web_parametro`

### `data_base/1. Create Schema.sql`
- **programacionacademica** (1 sentencia DDL): Creación de esquema formal `CREATE SCHEMA programacionacademica;` (no define tablas base directamente; establece el contenedor de objetos para el módulo).

### `data_base/2. CreateTablesManagement.sql`
- **dbo** (4): `calendario`, `periodo`, `programacion_proceso`, `uaa`
- **proaca** (3): `periodo_unidad`, `programacion_academica`, `programacion_gestion`

---

## 10. REVISIÓN DE INTEGRIDAD DE ARCHIVOS NO IMPACTADOS

Se confirmó formalmente que los siguientes componentes del proyecto **NO contienen referencias directas a tablas de base de datos**:
- **Archivos raíz PHP** (`index.php`, `login1.php`, `login2.php`, `loginToken.php`, `loginMensaje.php`, `foto.php`, `sesion.php`, `suite_admin.php`): Son controladores de sesión, autenticación OAuth/API institucional, o enrutadores de vistas.
- **Capa de lógica / controladores REST** (`logica/*.php`): Reciben las peticiones HTTP POST, validan parámetros y delegan la ejecución a las clases correspondientes en `clases/`.
- **Servicios utilitarios** (`clases/servicios/FechaSqlServer.php`): Clase auxiliar para la normalización de formatos de fecha a expresiones estándar SQL Server ISO 8601 (`CONVERT(datetime2, ...)`); no interactúa directamente con tablas de base de datos.
- **Capa de conexión / abstracción de datos** (`conexion/cls_config.php`): Envoltorio PDO SQLSRV/ODBC dinámico que recibe consultas parametrizadas o cadenas SQL desde las clases; no contiene tablas de dominio embebidas.
- **Módulos de correo** (`correos/`): Plantillas de correo HTML y bibliotecas PHPMailer sin interacción SQL.
- **Componentes cliente** (`components/`): Interfaces AngularJS (HTML y JS) desacopladas de la base de datos.
- **Archivo de configuración** (`pacademica.ini`): Contiene parámetros de conexión (host, port, acceso_datos) sin sentencias DDL/DML.

---
*Reporte generado automáticamente como inventario fidedigno y auditable de base de datos para el repositorio `p_academica-main`.*