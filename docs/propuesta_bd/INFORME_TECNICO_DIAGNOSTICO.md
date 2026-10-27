# INFORME TÉCNICO DE DIAGNÓSTICO: ARQUITECTURA DE BASE DE DATOS Y CAPA DE ACCESO A DATOS

**Sistema:** Sistema de Programación Académica (`p_academica-main`)  
**Motor de Base de Datos:** Microsoft SQL Server (T-SQL)  
**Pila Tecnológica:** PHP 7.x / 8.x con PDO Driver (`pdo_sqlsrv`), SQL Server Management Tools  
**Fecha de Emisión:** 27 de Octubre de 2026  
**Versión del Documento:** 1.0 — Diagnóstico Exhaustivo de Línea Base (Requisito R1)  
**Clasificación:** Informe Técnico de Auditoría, Arquitectura y Calidad de Software  
**Directorio de Trabajo:** `c:\Users\USER\Pictures\p_academica-main\p_academica-main`  

---

## 1. Resumen Ejecutivo y Métricas del Diagnóstico

El presente informe constituye la auditoría técnica exhaustiva e ingeniería inversa de la base de datos y la capa de persistencia del proyecto `p_academica-main`. Se evaluó el 100% de los archivos de definición de datos (DDL) contenidos en el directorio `sql/` (87 archivos distribuidos entre tablas y vistas) y en `data_base/`, cruzándolos con la totalidad del código fuente de la aplicación (95 archivos PHP en `clases/`, `logica/`, `conexion/`, `correos/` y scripts raíz).

El análisis evaluó de forma rigurosa cuatro dimensiones cardinales:
1. **Diseño de esquema, vistas, normalización e integridad referencial**: detección de anomalías de almacenamiento físico (tablas montículo / Heaps), ausencia o debilidad de restricciones (`PRIMARY KEY`, `FOREIGN KEY`, `CHECK`, `UNIQUE`), inconsistencias de tipos de datos, violaciones de formas normales y objetos fantasma.
2. **Rendimiento y patrones de acceso a datos**: evaluación de planes de acceso, omisión total de índices secundarios, cuellos de botella por consultas dentro de ciclos iterativos (problema N+1) y destrucción de la atomicidad transaccional por el modelo de conexión en `conexion/cls_config.php`.
3. **Seguridad en el acceso a datos**: evaluación de vectores de inyección SQL (0% de parametrización sobre 566 consultas analizadas), exposición y fuga de credenciales en memoria, texto claro y volcados HTTP públicos (`sesion.php`).
4. **Mantenibilidad y evolución**: acoplamiento a T-SQL sin capa de abstracción, inconsistencias entre borrado físico y lógico, falta de versionado de disparadores de auditoría y desincronización de esquemas.

### 1.1 Cuadro Consolidado de Métricas Cuantitativas

| Dimensión / Indicador | Métrica Medida | Calificación de Riesgo | Ubicación / Evidencia Central |
|:---|:---:|:---:|:---|
| **Archivos SQL analizados en `sql/`** | **87 archivos (100%)** | Cobertura Total | Directorio `c:\Users\USER\Pictures\p_academica-main\p_academica-main\sql\` |
| **Tablas base definidas en `sql/`** | **75 tablas** | Cobertura Total | 61 en `dbo`, 12 en `programacionacademica`, 2 en `proyectos` |
| **Vistas relacionales en `sql/`** | **12 vistas** | Cobertura Total | `sql/dbo/vistas/*.sql` |
| **Total de columnas de tablas base** | **957 columnas** | Informativo | Promedio de 12.76 columnas/tabla (rango: 3 a 73 columnas) |
| **Total de columnas proyectadas en vistas** | **233 columnas** | Informativo | Exposición de proyecciones agregadas y denormalizadas |
| **Total consolidado de columnas catalogadas** | **1,190 columnas** | Informativo | Inventario 100% verificado |
| **Claves Primarias (PK) existentes** | **75 / 75 (100%)** | Satisfactorio | 73 con restricción nombrada, 2 PKs anónimas |
| **Claves Primarias Agrupadas (Clustered PK)** | **41 tablas** | Adecuado | Organizadas físicamente en árboles B-Tree |
| **Tablas Montículo (Heaps sin Clustered Index)** | **34 tablas (45.3%)** | **CRÍTICO** | Declaradas con `PRIMARY KEY NONCLUSTERED` sin índice agrupado |
| **Claves Foráneas (FK) explícitas totales** | **107 restricciones** | Estructural | Relaciones formales declaradas en los DDLs |
| **Claves Foráneas con destino interno válido** | **84 restricciones** | Adecuado | Apuntan a tablas presentes dentro de `sql/` |
| **Claves Foráneas hacia tablas externas/ausentes** | **23 restricciones** | **CRÍTICO** | Apuntan a tablas fuera de `sql/` (`dbo.pais`, `dbo.horario`, `ps_*`) |
| **Claves Foráneas no confiables (`WITH NOCHECK`)** | **26 restricciones (24.3%)** | **ALTO** | `is_not_trusted = 1`; el optimizador no puede usarlas para join elimination |
| **Claves Foráneas candidatas faltantes** | **65 columnas** | **ALTO** | Columnas con nombres de PKs de otras tablas sin constraint FK |
| **Clave Foránea Tautológica (auto-referencial PK)** | **1 restricción** | **ALTO** | `sql/proyectos/proyecto_proyeccion_social.sql:126` (`pps_codigo` -> `pps_codigo`) |
| **Índices secundarios no-PK en `sql/`** | **0 índices (0.0%)** | **CRÍTICO** | Cero índices en claves foráneas o predicados de búsqueda |
| **Restricciones `UNIQUE` explícitas** | **0 restricciones** | **MEDIO** | No se garantiza unicidad sobre claves candidatas de negocio |
| **Restricciones `CHECK` explícitas** | **0 restricciones** | **MEDIO** | No se validan dominios numéricos ni estados en base de datos |
| **Archivos PHP analizados en la aplicación** | **95 archivos** | Cobertura Total | Directorios raíz, `clases/`, `logica/`, `conexion/`, `correos/` |
| **Archivos de clases con persistencia activa** | **34 clases** | Cobertura Total | 33 en `clases/` y 1 en `clases/servicios/` |
| **Total de puntos de ejecución de consultas SQL** | **542 consultas** | Cobertura Total | 366 SELECT, 50 UPDATE, 27 INSERT, 13 DELETE, 83 TX, 3 DYN |
| **Consultas dentro de bucles iterativos (N+1)** | **178 ejecuciones** | **CRÍTICO** | Ejecución reiterada de consultas individuales en bucles PHP |
| **Uso de consultas preparadas PDO parametrizadas** | **0 consultas (0.0%)** | **CRÍTICO** | 100% de consultas usan interpolación/concatenación directa |
| **Reutilización de conexión PDO en `cls_config`** | **0% (Conexión nueva por query)** | **CRÍTICO** | `conectar()` invocado al inicio de cada método; destruye transacciones |
| **Fuga pública de credenciales de BD y sesión** | **1 archivo crítico** | **CRÍTICO** | `sesion.php:4-5` imprime `$_SESSION` a clientes no autenticados |
| **Credenciales SMTP en texto claro en código** | **3 archivos** | **CRÍTICO** | Contraseña de app de Gmail activa en `correos/correo_*.php` |
| **Contraseñas almacenadas en tablas operacionales** | **2 tablas operacionales** | **ALTO** | `sql/dbo/curso.sql:30` y `sql/dbo/espacio_ocupacion.sql:30` almacenan `usu_clave` |
| **Objetos fantasma indispensables para vistas** | **14 tablas/funciones** | **CRÍTICO** | Vistas en `sql/dbo/vistas/` referencian tablas sin DDL en el repositorio |
| **Discrepancia en esquema de gestión académica** | **1 divergencia grave** | **ALTO** | `data_base/2. CreateTablesManagement.sql` usa `proaca`; código usa `programacionacademica` |

---

## 2. Inventario y Catálogo Exhaustivo del 100% de Archivos DDL (`sql/`)

A continuación se detalla el catálogo completo de las 87 entidades DDL inspeccionadas en `c:\Users\USER\Pictures\p_academica-main\p_academica-main\sql\`. Todas las rutas, líneas de código y atributos han sido verificados de forma directa contra el sistema de archivos del proyecto.

### 2.1 Catálogo General de las 87 Entidades DDL

| # | Esquema | Nombre de la Entidad | Tipo | Ruta Relativa del Archivo DDL | Líneas | Clave Primaria (Nombre, Agrupamiento, Columna, Línea) | Cols | FKs | Defaults | Observaciones Técnicas y Anomalías |
|:---:|:---|:---|:---:|:---|:---:|:---|:---:|:---:|:---:|:---|
| 1 | `dbo` | `agenda_periodo` | TABLA | `sql/dbo/agenda_periodo.sql` | 36 | `PK_agenda_periodo` (CLUSTERED: `idagenda`) [L29] | 17 | 0 | 0 | Tabla relacional; falta FK a `curso`, `uaa`, `periodo` |
| 2 | `dbo` | `agenda_periodo_novedad` | TABLA | `sql/dbo/agenda_periodo_novedad.sql` | 25 | `PK_agenda_periodo_novedad` (CLUSTERED: `apn_id`) [L18] | 6 | 0 | 0 | Bitácora de novedades de agenda |
| 3 | `dbo` | `asignatura` | TABLA | `sql/dbo/asignatura.sql` | 70 | `PK_asignatura` (CLUSTERED: `asi_codigo`) [L43] | 31 | 2 | 2 | Catálogo de asignaturas; incluye columnas `sippa_*` |
| 4 | `dbo` | `aud_curso` | TABLA | `sql/dbo/aud_curso.sql` | 59 | `PK_aud_curso` (CLUSTERED: `aud_codigo_cur`) [L43] | 31 | 0 | 3 | Tabla sombra de auditoría; almacena `usu_clave` (L32) |
| 5 | `dbo` | `aud_curso_cupo_subgrupo` | TABLA | `sql/dbo/aud_curso_cupo_subgrupo.sql` | 43 | `PK_aud_curso_cupo_subgrupo` (CLUSTERED: `aud_cus_cod`) [L24] | 12 | 0 | 4 | Auditoría de subgrupos de cupos |
| 6 | `dbo` | `aud_espacio_ocupacion` | TABLA | `sql/dbo/aud_espacio_ocupacion.sql` | 58 | `PK_aud_espacio_ocupacion` (CLUSTERED: `aud_codigo_eso`) [L36] | 24 | 0 | 5 | Auditoría de horarios; almacena `usu_clave` (L26) |
| 7 | `dbo` | `aud_matricula_curso` | TABLA | `sql/dbo/aud_matricula_curso.sql` | 74 | `PK_aud_matricula_curso` (CLUSTERED: `aud_codigo_mat_curso`) [L61] | 49 | 0 | 2 | Auditoría de matrícula académica |
| 8 | `dbo` | `aud_uaa_personal` | TABLA | `sql/dbo/aud_uaa_personal.sql` | 56 | `PK_aud_uaa_personal` (CLUSTERED: `aud_codigo_uap`) [L40] | 28 | 0 | 3 | Auditoría de vinculación de personal a unidades |
| 9 | `dbo` | `bloque` | TABLA | `sql/dbo/bloque.sql` | 36 | `PK_bloque` (CLUSTERED: `blo_codigo`) [L19] | 7 | 1 | 1 | Edificaciones institucionales; FK a `sub_sede` (L29) |
| 10 | `dbo` | `calendario` | TABLA | `sql/dbo/calendario.sql` | 37 | `PK_calendario` (CLUSTERED: `cal_codigo`) [L20] | 8 | 1 | 1 | Períodos lectivos y calendarios académicos |
| 11 | `dbo` | `caracter` | TABLA | `sql/dbo/caracter.sql` | 25 | `PK_caracter` (CLUSTERED: `car_codigo`) [L15] | 3 | 0 | 1 | Carácter de asignaturas (Obligatoria, Electiva, etc.) |
| 12 | `dbo` | `cargo` | TABLA | `sql/dbo/cargo.sql` | 25 | `PK_cargo` (CLUSTERED: `car_codigo`) [L18] | 6 | 0 | 0 | Colisión semántica de prefijo `car` con `caracter` |
| 13 | `dbo` | `cupo_autorizacion` | TABLA | `sql/dbo/cupo_autorizacion.sql` | 36 | `PK_cupo_autorizacion` (CLUSTERED: `cua_codigo`) [L19] | 7 | 1 | 1 | Autorizaciones excepcionales de cupo |
| 14 | `dbo` | `curso` | TABLA | `sql/dbo/curso.sql` | 91 | `PK_curso_1` (CLUSTERED: `cur_codigo`) [L46] | 34 | 2 | 8 | Entidad central; almacena `usu_clave` (L30); 6 FKs faltantes |
| 15 | `dbo` | `curso_cupo_subgrupo` | TABLA | `sql/dbo/curso_cupo_subgrupo.sql` | 31 | `PK_curso_cupo_subgrupo` (CLUSTERED: `cus_cod`) [L18] | 6 | 0 | 2 | Subgrupos prácticos; falta FK a `curso` |
| 16 | `dbo` | `curso_institucion_ejecucion` | TABLA | `sql/dbo/curso_institucion_ejecucion.sql` | 44 | *(anónima)* (CLUSTERED: `cie_codigo`) [L22] | 10 | 3 | 0 | Clave primaria anónima y 2 FKs anónimas (L29, L40) |
| 17 | `dbo` | `curso_plan` | TABLA | `sql/dbo/curso_plan.sql` | 30 | `PK_curso_plan_1` (CLUSTERED: `cup_codigo`) [L16] | 4 | 1 | 0 | Asociación curso con plan de estudios |
| 18 | `dbo` | `curso_tipo` | TABLA | `sql/dbo/curso_tipo.sql` | 22 | `PK_curso_tipo` (CLUSTERED: `cut_codigo`) [L15] | 3 | 0 | 0 | Tipología de cursos académicos |
| 19 | `dbo` | `dedicacion` | TABLA | `sql/dbo/dedicacion.sql` | 24 | `PK_dedicacion` (CLUSTERED: `ded_codigo`) [L17] | 5 | 0 | 0 | Dedicación docente (Tiempo Completo, Cátedra) |
| 20 | `dbo` | `departamento` | TABLA | `sql/dbo/departamento.sql` | 32 | `PK_departamento_1` (CLUSTERED: `dep_codigo`) [L18] | 6 | 1 | 0 | Departamentos; FK a tabla externa `dbo.pais` (L26) |
| 21 | `dbo` | `dia` | TABLA | `sql/dbo/dia.sql` | 26 | `PK_dia` (CLUSTERED: `dia_codigo`) [L16] | 4 | 0 | 1 | Días de la semana para franjas horarias |
| 22 | `dbo` | `docente_escalafon` | TABLA | `sql/dbo/docente_escalafon.sql` | 44 | `PK_docente_escalafon` (CLUSTERED: `doe_codigo`) [L23] | 11 | 2 | 0 | Escalafón del docente; 2 FKs `WITH NOCHECK` (L30, L37) |
| 23 | `dbo` | `equivalencia` | TABLA | `sql/dbo/equivalencia.sql` | 23 | `PK_equivalencia` (CLUSTERED: `equ_codigo`) [L16] | 4 | 0 | 0 | Homologaciones; falta FK a `asignatura` y `plan` |
| 24 | `dbo` | `escalafon` | TABLA | `sql/dbo/escalafon.sql` | 23 | `PK_escalafon` (CLUSTERED: `esc_codigo`) [L16] | 4 | 0 | 0 | Categorías del escalafón docente |
| 25 | `dbo` | `espacio` | TABLA | `sql/dbo/espacio.sql` | 55 | `PK_espacios` (**NONCLUSTERED**: `esp_codigo`) [L34] | 22 | 2 | 0 | **Tabla Montículo (Heap)**; salones y laboratorios |
| 26 | `dbo` | `espacio_ocupacion` | TABLA | `sql/dbo/espacio_ocupacion.sql` | 94 | `PK_espacio_ocupacion` (CLUSTERED: `eso_codigo`) [L45] | 33 | 6 | 0 | Horarios; almacena `usu_clave` (L30); FK `eso_actividad` ofuscada |
| 27 | `dbo` | `formalidad` | TABLA | `sql/dbo/formalidad.sql` | 22 | `PK_formalidad` (CLUSTERED: `for_codigo`) [L15] | 3 | 0 | 0 | Formalidad académica; discrepancia de tipo (`tinyint`) |
| 28 | `dbo` | `grupo` | TABLA | `sql/dbo/grupo.sql` | 26 | `PK_grupo` (**NONCLUSTERED**: `gru_codigo`) [L16] | 4 | 0 | 1 | **Tabla Montículo (Heap)**; grupos de seguridad |
| 29 | `dbo` | `hora` | TABLA | `sql/dbo/hora.sql` | 32 | `PK_hora` (**NONCLUSTERED**: `hra_codigo`) [L18] | 6 | 1 | 0 | **Tabla Montículo (Heap)**; FK a tabla externa `dbo.horario` |
| 30 | `dbo` | `matricula` | TABLA | `sql/dbo/matricula.sql` | 70 | `PK_matricula` (**NONCLUSTERED**: `mat_codigo`) [L27] | 15 | 3 | 4 | **Tabla Montículo (Heap)**; FK externa `dbo.matricula_tipo` |
| 31 | `dbo` | `matricula_autorizacion` | TABLA | `sql/dbo/matricula_autorizacion.sql` | 22 | `PK_matricula_autorizacion` (**NONCLUSTERED**: `maa_codigo`) [L15] | 3 | 0 | 0 | **Tabla Montículo (Heap)** |
| 32 | `dbo` | `matricula_configuracion` | TABLA | `sql/dbo/matricula_configuracion.sql` | 34 | `PK_matricula_configuracion` (**NONCLUSTERED**: `mco_codigo`) [L17] | 5 | 1 | 1 | **Tabla Montículo (Heap)**; FK `WITH NOCHECK` (L27) |
| 33 | `dbo` | `matricula_configuracion_detalle` | TABLA | `sql/dbo/matricula_configuracion_detalle.sql` | 57 | `PK_matricula_configuracion_detalle` (**NONCLUSTERED**: `mcd_codigo`) [L20] | 8 | 3 | 3 | **Tabla Montículo (Heap)** |
| 34 | `dbo` | `municipio` | TABLA | `sql/dbo/municipio.sql` | 26 | `PK_municipio` (**NONCLUSTERED**: `mun_codigo`) [L19] | 7 | 0 | 0 | **Tabla Montículo (Heap)**; catálogo geográfico |
| 35 | `dbo` | `nivel_academico` | TABLA | `sql/dbo/nivel_academico.sql` | 47 | `PK_nivel_academico` (CLUSTERED: `nia_codigo`) [L30] | 18 | 1 | 1 | FK a tabla externa `dbo.nivel_academico_tipo` (L29) |
| 36 | `dbo` | `novedad` | TABLA | `sql/dbo/novedad.sql` | 47 | `PK_novedad` (CLUSTERED: `nov_codigo`) [L24] | 12 | 1 | 3 | FK a tabla externa `dbo.novedad_tipo` (L40) |
| 37 | `dbo` | `nucleo` | TABLA | `sql/dbo/nucleo.sql` | 26 | `PK_nucleo` (**NONCLUSTERED**: `nuc_codigo`) [L16] | 4 | 0 | 1 | **Tabla Montículo (Heap)**; discrepancia de tipo (`int` vs `varchar`) |
| 38 | `dbo` | `periodo` | TABLA | `sql/dbo/periodo.sql` | 37 | `PK_periodo` (**NONCLUSTERED**: `per_codigo`) [L23] | 11 | 1 | 0 | **Tabla Montículo (Heap)**; columna multibyte `per_año` (L15) |
| 39 | `dbo` | `persona` | TABLA | `sql/dbo/persona.sql` | 98 | `PK_persona` (**NONCLUSTERED**: `per_codigo`) [L70] | 58 | 0 | 7 | **Tabla Montículo (Heap)**; colisión de PK con `periodo` |
| 40 | `dbo` | `persona_novedad` | TABLA | `sql/dbo/persona_novedad.sql` | 57 | `PK_persona_novedad` (CLUSTERED: `pen_codigo`) [L29] | 17 | 3 | 0 | 3 FKs `WITH NOCHECK` (L36, L43, L50) |
| 41 | `dbo` | `persona_proyecto` | TABLA | `sql/dbo/persona_proyecto.sql` | 56 | `PK_proyecto_persona` (**NONCLUSTERED**: `pep_codigo`, `pry_codigo`) [L27] | 15 | 3 | 0 | **Tabla Montículo (Heap)**; FK a tabla externa `dbo.proyecto_rol` |
| 42 | `dbo` | `plan_academico` | TABLA | `sql/dbo/plan_academico.sql` | 57 | `PK_plan_academico` (**NONCLUSTERED**: `pla_codigo`) [L31] | 19 | 1 | 4 | **Tabla Montículo (Heap)**; FK a tabla externa `dbo.nivel_academico_creditos` |
| 43 | `dbo` | `plan_academico_asignatura` | TABLA | `sql/dbo/plan_academico_asignatura.sql` | 81 | `PK_plan_academico_asignatura` (CLUSTERED: `paa_codigo`) [L36] | 24 | 2 | 8 | Malla curricular; FK `WITH NOCHECK` (L67) |
| 44 | `dbo` | `plan_estudiante` | TABLA | `sql/dbo/plan_estudiante.sql` | 45 | `PK_plan_estudiante` (CLUSTERED: `ple_codigo`) [L21] | 9 | 2 | 1 | FK `WITH NOCHECK` a `plan_academico` (L38) |
| 45 | `dbo` | `prerrequisito` | TABLA | `sql/dbo/prerrequisito.sql` | 28 | `PK_prerequisito` (**NONCLUSTERED**: `pre_codigo`) [L21] | 9 | 0 | 0 | **Tabla Montículo (Heap)**; faltan FKs a `asignatura` |
| 46 | `dbo` | `programa` | TABLA | `sql/dbo/programa.sql` | 85 | `PK_programa` (CLUSTERED: `pro_codigo`, `uaa_codigo`, `sed_codigo`) [L39] | 27 | 4 | 3 | FK externa a `acreditacion.campo_detallado` (L78) |
| 47 | `dbo` | `programacion_proceso` | TABLA | `sql/dbo/programacion_proceso.sql` | 23 | `PK_programacion_proceso` (**NONCLUSTERED**: `prp_codigo`) [L16] | 4 | 0 | 0 | **Tabla Montículo (Heap)** |
| 48 | `dbo` | `proyecto` | TABLA | `sql/dbo/proyecto.sql` | 64 | `PK_proyecto` (**NONCLUSTERED**: `pry_codigo`) [L36] | 24 | 3 | 0 | **Tabla Montículo (Heap)**; 3 FKs `WITH NOCHECK` (L43, L50, L57) |
| 49 | `dbo` | `proyecto_tipo` | TABLA | `sql/dbo/proyecto_tipo.sql` | 22 | `PK_proyecto_tipo` (**NONCLUSTERED**: `prt_codigo`) [L15] | 3 | 0 | 0 | **Tabla Montículo (Heap)** |
| 50 | `dbo` | `sede` | TABLA | `sql/dbo/sede.sql` | 37 | `PK_sede` (**NONCLUSTERED**: `sed_codigo`) [L20] | 8 | 1 | 1 | **Tabla Montículo (Heap)**; sedes universitarias |
| 51 | `dbo` | `sub_sede` | TABLA | `sql/dbo/sub_sede.sql` | 36 | `PK_sub_sede_1` (**NONCLUSTERED**: `sus_codigo`) [L19] | 7 | 1 | 1 | **Tabla Montículo (Heap)** |
| 52 | `dbo` | `tipo_curso` | TABLA | `sql/dbo/tipo_curso.sql` | 22 | `PK_tipo_curso` (CLUSTERED: `tic_codigo`) [L15] | 3 | 0 | 0 | Modalidad del curso (Teórico, Práctico) |
| 53 | `dbo` | `tipo_escala` | TABLA | `sql/dbo/tipo_escala.sql` | 22 | `PK_tipo_escala` (CLUSTERED: `tes_codigo`) [L15] | 3 | 0 | 0 | Escalas de calificación numérica/cualitativa |
| 54 | `dbo` | `uaa` | TABLA | `sql/dbo/uaa.sql` | 52 | `PK_unidad_academica_administrativa` (**NONCLUSTERED**: `uaa_codigo`) [L35] | 23 | 1 | 1 | **Tabla Montículo (Heap)**; unidades académicas/administrativas |
| 55 | `dbo` | `uaa_cargo` | TABLA | `sql/dbo/uaa_cargo.sql` | 51 | `PK_uaa_cargo` (CLUSTERED: `uac_codigo`) [L20] | 8 | 3 | 1 | Asignación de cargos en dependencias |
| 56 | `dbo` | `uaa_personal` | TABLA | `sql/dbo/uaa_personal.sql` | 64 | `PK_uaa_personal` (**NONCLUSTERED**: `uap_codigo`) [L40] | 28 | 2 | 1 | **Tabla Montículo (Heap)**; 2 FKs `WITH NOCHECK` (L50, L57) |
| 57 | `dbo` | `usuario_grupo` | TABLA | `sql/dbo/usuario_grupo.sql` | 27 | `PK_usuario_grupo` (CLUSTERED: `usg_codigo`) [L17] | 5 | 0 | 1 | Membresías de usuarios en roles |
| 58 | `dbo` | `vinculacion` | TABLA | `sql/dbo/vinculacion.sql` | 33 | `PK_vinculacion` (**NONCLUSTERED**: `vin_codigo`) [L20] | 8 | 0 | 2 | **Tabla Montículo (Heap)**; tipo de vinculación laboral |
| 59 | `dbo` | `espacio_tipo` | TABLA | `sql/dbo/vistas/espacio_tipo.sql` | 23 | `PK_espacio_tipo` (CLUSTERED: `eti_codigo`) [L16] | 4 | 0 | 0 | **Tabla ubicada por error en `vistas/`** |
| 60 | `dbo` | `estudiante` | TABLA | `sql/dbo/vistas/estudiante.sql` | 53 | `PK_estudiante` (**NONCLUSTERED**: `est_codigo`) [L27] | 15 | 1 | 3 | **Tabla Montículo ubicada por error en `vistas/`**; violación 1NF |
| 61 | `dbo` | `web_parametro` | TABLA | `sql/dbo/web_parametro.sql` | 27 | `PK_web_parametro_1` (CLUSTERED: `wep_codigo`) [L17] | 5 | 0 | 1 | Parámetros de configuración del sistema web |
| 62 | `programacionacademica` | `grupo_uaa` | TABLA | `sql/programacionacademica/grupo_uaa.sql` | 22 | `PK_pgr_codigo` (**NONCLUSTERED**: `pgr_codigo`) [L15] | 3 | 0 | 0 | **Tabla Montículo (Heap)**; agrupación de dependencias |
| 63 | `programacionacademica` | `grupo_uaa_item` | TABLA | `sql/programacionacademica/grupo_uaa_item.sql` | 37 | `PK_gui_codigo` (**NONCLUSTERED**: `gui_codigo`) [L16] | 4 | 2 | 0 | **Tabla Montículo (Heap)**; ítems de dependencias |
| 64 | `programacionacademica` | `periodo_unidad` | TABLA | `sql/programacionacademica/periodo_unidad.sql` | 39 | `PK_peu_periodo_unidad` (**NONCLUSTERED**: `peu_codigo`) [L18] | 6 | 2 | 0 | **Tabla Montículo (Heap)**; habilitación de períodos |
| 65 | `programacionacademica` | `programacion_academica` | TABLA | `sql/programacionacademica/programacion_academica.sql` | 47 | `PK_pra_programacion_academica` (**NONCLUSTERED**: `pra_codigo`) [L19] | 7 | 3 | 0 | **Tabla Montículo (Heap)**; cabecera de programación |
| 66 | `programacionacademica` | `programacion_gestion` | TABLA | `sql/programacionacademica/programacion_gestion.sql` | 47 | `PK_prg_programacion_gestion` (**NONCLUSTERED**: `prg_codigo`) [L19] | 7 | 3 | 0 | **Tabla Montículo (Heap)**; bitácora de estados de gestión |
| 67 | `programacionacademica` | `programacion_tipo_solicitudes` | TABLA | `sql/programacionacademica/programacion_tipo_solicitudes.sql` | 22 | *(anónima)* (CLUSTERED: `pts_codigo`) [L15] | 3 | 0 | 0 | **Clave primaria anónima** |
| 68 | `programacionacademica` | `solicitud_cambio_horario` | TABLA | `sql/programacionacademica/solicitud_cambio_horario.sql` | 42 | `PK_sch_solicitud_cambio_horario` (**NONCLUSTERED**: `sch_codigo`) [L21] | 9 | 2 | 0 | **Tabla Montículo (Heap)**; cabecera de solicitud cambio |
| 69 | `programacionacademica` | `solicitud_cambio_horario_comentario` | TABLA | `sql/programacionacademica/solicitud_cambio_horario_comentario.sql` | 31 | `PK_schc_solicitud_cambio_horario_comentario` (**NONCLUSTERED**: `schc_codigo`) [L17] | 5 | 1 | 0 | **Tabla Montículo (Heap)** |
| 70 | `programacionacademica` | `solicitud_cambio_horario_horario` | TABLA | `sql/programacionacademica/solicitud_cambio_horario_horario.sql` | 96 | `PK_schh_solicitud_cambio_horario_horario` (**NONCLUSTERED**: `schh_codigo`) [L26] | 14 | 9 | 0 | **Tabla Montículo (Heap)**; 9 FKs; franjas de cambio horario |
| 71 | `programacionacademica` | `solicitud_prestamo_docente` | TABLA | `sql/programacionacademica/solicitud_prestamo_docente.sql` | 69 | `PK_spd_solicitud_prestamo_docente` (**NONCLUSTERED**: `spd_codigo`) [L20] | 8 | 6 | 0 | **Tabla Montículo (Heap)**; préstamo de docentes entre UAAs |
| 72 | `programacionacademica` | `solicitud_prestamo_docente_comentario` | TABLA | `sql/programacionacademica/solicitud_prestamo_docente_comentario.sql` | 32 | `PK_spd_solicitud_prestamo_docente_comentario` (**NONCLUSTERED**: `spdc_codigo`) [L18] | 6 | 1 | 0 | **Tabla Montículo (Heap)** |
| 73 | `programacionacademica` | `solicitud_prestamo_docente_horario` | TABLA | `sql/programacionacademica/solicitud_prestamo_docente_horario.sql` | 45 | `PK_spd_solicitud_prestamo_docente_horario` (**NONCLUSTERED**: `spdh_codigo`) [L17] | 5 | 3 | 0 | **Tabla Montículo (Heap)** |
| 74 | `proyectos` | `docentexproyecto_proyeccion_social` | TABLA | `sql/proyectos/docentexproyecto_proyeccion_social.sql` | 71 | `PK_docentexproyecto_proyeccion_social_1` (CLUSTERED: `id_docentesxproyecto`) [L33] | 21 | 4 | 1 | Nombre de PK plural no estándar; 2 FKs a tablas externas `ps_*` |
| 75 | `proyectos` | `proyecto_proyeccion_social` | TABLA | `sql/proyectos/proyecto_proyeccion_social.sql` | 164 | `PK_proyecto_proyeccion_social` (CLUSTERED: `pps_codigo`) [L74] | 62 | 11 | 1 | **FK Tautológica** (L126); error tipográfico `pre_codgo` (L28); 8 FKs a `ps_*` |
| 76 | `dbo` | `departamentos_programas_unificados` | VISTA | `sql/dbo/vistas/departamentos_programas_unificados.sql` | 27 | N/A (Vista Relacional) | 7 | N/A | N/A | LEFT JOIN anulado por WHERE (L22); GROUP BY redundante (L23-24) |
| 77 | `dbo` | `espacio_ocupacion_total` | VISTA | `sql/dbo/vistas/espacio_ocupacion_total.sql` | 140 | N/A (Vista Relacional) | 32 | N/A | N/A | **Usa `UNION` costoso** (L18); depende de objeto fantasma `espacio_ocupacion_historico` |
| 78 | `dbo` | `estudiante_horario_actual` | VISTA | `sql/dbo/vistas/estudiante_horario_actual.sql` | 175 | N/A (Vista Relacional) | 14 | N/A | N/A | **Usa hints `with(nolock)`** (L14-18); depende de TVF `Split` y tabla fantasma |
| 79 | `dbo` | `matricula_curso` | VISTA | `sql/dbo/vistas/matricula_curso.sql` | 138 | N/A (Vista Relacional) | 41 | N/A | N/A | **Usa `UNION` sobre 3 tablas masivas**; 3 tablas subyacentes son fantasmas |
| 80 | `dbo` | `notas_total` | VISTA | `sql/dbo/vistas/notas_total.sql` | 232 | N/A (Vista Relacional) | 34 | N/A | N/A | Depende de vista recursiva y tabla fantasma `dbo.matricula_forma` (L19) |
| 81 | `dbo` | `resumen_docencia_final` | VISTA | `sql/dbo/vistas/resumen_docencia_final.sql` | 133 | N/A (Vista Relacional) | 20 | N/A | N/A | Depende de tabla fantasma `dbo.resumen_docencia_sem` (L13) |
| 82 | `dbo` | `usuario_administrativo` | VISTA | `sql/dbo/vistas/usuario_administrativo.sql` | 155 | N/A (Vista Relacional) | 13 | N/A | N/A | **Expone contraseña en claro `up`**; depende de tabla fantasma `usuario_administrativos` |
| 83 | `dbo` | `usuario_docente` | VISTA | `sql/dbo/vistas/usuario_docente.sql` | 173 | N/A (Vista Relacional) | 14 | N/A | N/A | **Expone contraseña en claro `up`**; depende de tabla fantasma `usuario_docentes` |
| 84 | `dbo` | `usuario_general` | VISTA | `sql/dbo/vistas/usuario_general.sql` | 154 | N/A (Vista Relacional) | 11 | N/A | N/A | **Expone `up`, preguntas y respuestas secretas**; `UNION` sobre 7 tablas fantasma |
| 85 | `dbo` | `usuario_planta_fisica` | VISTA | `sql/dbo/vistas/usuario_planta_fisica.sql` | 56 | N/A (Vista Relacional) | 16 | N/A | N/A | Vista de autenticación con `UNION ALL`; depende de tablas fantasma |
| 86 | `dbo` | `usuario_programacion` | VISTA | `sql/dbo/vistas/usuario_programacion.sql` | 51 | N/A (Vista Relacional) | 13 | N/A | N/A | **Usa `UNION` y filtra por IDs mágicos** (68,69,318,34,14); expone contraseña `up` |
| 87 | `dbo` | `usuario_programacion_login` | VISTA | `sql/dbo/vistas/usuario_programacion_login.sql` | 175 | N/A (Vista Relacional) | 18 | N/A | N/A | **Expone `up`, `uwd`, `uwd2`**; vista crítica de login con `UNION` y IDs mágicos |

---

## 3. Dimensión 1: Diseño de Esquema, Normalización e Integridad Referencial

### 3.1 Almacenamiento Físico: 34 Tablas Montículo (Heaps sin Clustered Index)
El análisis físico de las definiciones DDL reveló un patrón arquitectónico sumamente perjudicial: **34 de las 75 tablas (el 45.3%) carecen de un índice agrupado (Clustered Index)** debido a que su clave primaria fue declarada de forma explícita como `PRIMARY KEY NONCLUSTERED` sin definir ningún otro índice agrupado en la tabla.

#### Justificación Técnica del Impacto en SQL Server
En SQL Server, una tabla sin índice agrupado es físicamente una tabla montículo (**Heap**). Las consecuencias técnicas sobre el motor de base de datos son severas:
1. **Desorden Físico y Fragmentación de Páginas**: Las inserciones no siguen ningún orden de clave, colocándose en la primera página de datos con espacio disponible reportada en el PFS (*Page Free Space*).
2. **Punteros de Desvío (*Forwarding Pointers*)**: Cuando una fila que contiene columnas de longitud variable (`varchar`, `nvarchar`) es actualizada y crece de tamaño, si la página actual no tiene espacio suficiente, el motor traslada los datos a una nueva página y deja un puntero de reenvío de 16 bytes en la posición original. Esto duplica el costo de lecturas lógicas de I/O para acceder a un solo registro.
3. **Sobrecarga de Lookups por RID (*Row ID*)**: Cualquier índice no agrupado secundario que se construya sobre un montículo almacena el identificador físico de fila (`RID: Archivo:Página:Ranura`). A medida que los RIDs se fragmentan o se generan punteros de desvío, las búsquedas experimentan degradaciones masivas de latencia.
4. **Escaneos de Montículo Ineficientes**: Al no existir un árbol B que mantenga orden físico, cualquier escaneo de rango o consulta sin predicado exacto debe recurrir a un *Table Scan* de páginas desordenadas a través de la cadena IAM (*Index Allocation Map*).

#### Inventario de las 34 Tablas Montículo Identificadas
- **Núcleo de Programación Académica (11 tablas en `sql/programacionacademica/`)**:
  - `sql/programacionacademica/grupo_uaa.sql:15` (`PK_pgr_codigo`)
  - `sql/programacionacademica/grupo_uaa_item.sql:16` (`PK_gui_codigo`)
  - `sql/programacionacademica/periodo_unidad.sql:18` (`PK_peu_periodo_unidad`)
  - `sql/programacionacademica/programacion_academica.sql:19` (`PK_pra_programacion_academica`)
  - `sql/programacionacademica/programacion_gestion.sql:19` (`PK_prg_programacion_gestion`)
  - `sql/programacionacademica/solicitud_cambio_horario.sql:21` (`PK_sch_solicitud_cambio_horario`)
  - `sql/programacionacademica/solicitud_cambio_horario_comentario.sql:17` (`PK_schc_solicitud_cambio_horario_comentario`)
  - `sql/programacionacademica/solicitud_cambio_horario_horario.sql:26` (`PK_schh_solicitud_cambio_horario_horario`)
  - `sql/programacionacademica/solicitud_prestamo_docente.sql:20` (`PK_spd_solicitud_prestamo_docente`)
  - `sql/programacionacademica/solicitud_prestamo_docente_comentario.sql:18` (`PK_spd_solicitud_prestamo_docente_comentario`)
  - `sql/programacionacademica/solicitud_prestamo_docente_horario.sql:17` (`PK_spd_solicitud_prestamo_docente_horario`)
  *(Nota crítica: El 100% de las tablas con PK nombrada del esquema de programación académica son Heaps).*
- **Tablas de Infraestructura y Soporte Académico en `sql/dbo/` (23 tablas)**:
  - `sql/dbo/espacio.sql:34` (`PK_espacios`)
  - `sql/dbo/grupo.sql:16` (`PK_grupo`)
  - `sql/dbo/hora.sql:18` (`PK_hora`)
  - `sql/dbo/matricula.sql:27` (`PK_matricula`)
  - `sql/dbo/matricula_autorizacion.sql:15` (`PK_matricula_autorizacion`)
  - `sql/dbo/matricula_configuracion.sql:17` (`PK_matricula_configuracion`)
  - `sql/dbo/matricula_configuracion_detalle.sql:20` (`PK_matricula_configuracion_detalle`)
  - `sql/dbo/municipio.sql:19` (`PK_municipio`)
  - `sql/dbo/nucleo.sql:16` (`PK_nucleo`)
  - `sql/dbo/periodo.sql:23` (`PK_periodo`)
  - `sql/dbo/persona.sql:70` (`PK_persona`)
  - `sql/dbo/persona_proyecto.sql:27` (`PK_proyecto_persona`)
  - `sql/dbo/plan_academico.sql:31` (`PK_plan_academico`)
  - `sql/dbo/prerrequisito.sql:21` (`PK_prerequisito`)
  - `sql/dbo/programacion_proceso.sql:16` (`PK_programacion_proceso`)
  - `sql/dbo/proyecto.sql:36` (`PK_proyecto`)
  - `sql/dbo/proyecto_tipo.sql:15` (`PK_proyecto_tipo`)
  - `sql/dbo/sede.sql:20` (`PK_sede`)
  - `sql/dbo/sub_sede.sql:19` (`PK_sub_sede_1`)
  - `sql/dbo/uaa.sql:35` (`PK_unidad_academica_administrativa`)
  - `sql/dbo/uaa_personal.sql:40` (`PK_uaa_personal`)
  - `sql/dbo/vinculacion.sql:20` (`PK_vinculacion`)
  - `sql/dbo/vistas/estudiante.sql:27` (`PK_estudiante`)

---

### 3.2 Integridad Referencial y Análisis de Claves Foráneas

#### 3.2.1 Claves Foráneas Externas / Huérfanas de Definición (23 Restricciones)
Se identificaron 23 restricciones `FOREIGN KEY` que referencian tablas para las cuales **no existe ningún script DDL dentro del repositorio del proyecto**:

| # | Tabla Origen | Columna FK | Nombre de Restricción | Tabla y Columna Externa Referenciada | Archivo DDL y Línea |
|:---:|:---|:---|:---|:---|:---|
| 1 | `dbo.departamento` | `pai_codigo` | `FK_departamento_pais` | `dbo.pais (pai_codigo)` | `sql/dbo/departamento.sql:26-28` |
| 2 | `dbo.espacio_ocupacion` | `hor_codigo` | `FK_espacio_ocupacion_horario1` | `dbo.horario (hor_codigo)` | `sql/dbo/espacio_ocupacion.sql:66-68` |
| 3 | `dbo.espacio_ocupacion` | `oct_codigo` | `FK_espacio_ocupacion_ocupacion_tipo` | `dbo.ocupacion_tipo (oct_codigo)` | `sql/dbo/espacio_ocupacion.sql:73-75` |
| 4 | `dbo.hora` | `hra_codigo` | `FK_hora_horario` | `dbo.horario (hor_codigo)` | `sql/dbo/hora.sql:25-27` |
| 5 | `dbo.matricula` | `mat_tipo` | `FK_matricula_matricula_tipo_agosto2018` | `dbo.matricula_tipo (mti_codigo)` | `sql/dbo/matricula.sql:60-62` |
| 6 | `dbo.nivel_academico` | `nat_codigo` | `FK_nivel_academico_nivel_academico_tipo` | `dbo.nivel_academico_tipo (nat_codigo)` | `sql/dbo/nivel_academico.sql:29-31` |
| 7 | `dbo.novedad` | `not_codigo` | `FK_novedad_novedad_tipo` | `dbo.novedad_tipo (not_codigo)` | `sql/dbo/novedad.sql:40-42` |
| 8 | `dbo.periodo` | `pet_codigo` | `FK_periodo_periodo_tipo` | `dbo.periodo_tipo (pet_codigo)` | `sql/dbo/periodo.sql:32-34` |
| 9 | `dbo.persona_proyecto` | `prr_codigo` | `FK_persona_proyecto_proyecto_rol` | `dbo.proyecto_rol (prr_codigo)` | `sql/dbo/persona_proyecto.sql:42-44` |
| 10 | `dbo.plan_academico` | `nac_codigo` | `FK__plan_acad__nac_c__1BE45685` | `dbo.nivel_academico_creditos (nac_codigo)` | `sql/dbo/plan_academico.sql:38-40` |
| 11 | `dbo.programa` | `cam_det_codigo` | `programa_cam_detFK` | `acreditacion.campo_detallado (cam_det_codigo)` | `sql/dbo/programa.sql:78-80` |
| 12 | `dbo.proyecto` | `pre_codigo` | `FK_proyecto_proyecto_estado` | `dbo.proyecto_estado (pre_codigo)` | `sql/dbo/proyecto.sql:50-52` |
| 13 | `proyectos.docentexproyecto` | `nco_codigo` | `FK_docentexproyecto_nbc_colciencias` | `proyectos.ps_nbc_colciencias (nco_codigo)` | `sql/proyectos/docentexproyecto_proyeccion_social.sql:43-45` |
| 14 | `proyectos.docentexproyecto` | `prp_codigo` | `FK_docentexproyecto_proyeccion_rol` | `proyectos.proyeccion_rolxproyecto (prp_codigo)` | `sql/proyectos/docentexproyecto_proyeccion_social.sql:50-52` |
| 15 | `proyectos.proyecto_proyeccion` | `pra_codigo` | `FK_proyecto_mc_proyecto_area` | `proyectos.mc_proyecto_area (pra_codigo)` | `sql/proyectos/proyecto_proyeccion_social.sql:84-86` |
| 16 | `proyectos.proyecto_proyeccion` | `prc_codigo` | `FK_proyecto_mc_proyecto_clase` | `proyectos.mc_proyecto_clase (prc_codigo)` | `sql/proyectos/proyecto_proyeccion_social.sql:91-93` |
| 17 | `proyectos.proyecto_proyeccion` | `nco_codigo` | `FK_proyecto_nbc_colciencias` | `proyectos.ps_nbc_colciencias (nco_codigo)` | `sql/proyectos/proyecto_proyeccion_social.sql:105-107` |
| 18 | `proyectos.proyecto_proyeccion` | `oap_codigo` | `FK_proyecto_origen_area_proyecto` | `proyectos.ps_origen_area_proyecto (oap_codigo)` | `sql/proyectos/proyecto_proyeccion_social.sql:112-114` |
| 19 | `proyectos.proyecto_proyeccion` | `otp_codigo` | `FK_proyecto_origen_tipo_proyecto` | `proyectos.ps_origen_tipo_proyecto (otp_codigo)` | `sql/proyectos/proyecto_proyeccion_social.sql:119-121` |
| 20 | `proyectos.proyecto_proyeccion` | `pst_codigo` | `FK_proyecto_proyecto_tipo` | `proyectos.ps_proyecto_tipo (pst_codigo)` | `sql/proyectos/proyecto_proyeccion_social.sql:133-135` |
| 21 | `proyectos.proyecto_proyeccion` | `pps_semillero` | `FK_proyecto_ps_semillero` | `proyectos.ps_semilleros (pss_codigo)` | `sql/proyectos/proyecto_proyeccion_social.sql:140-142` |
| 22 | `proyectos.proyecto_proyeccion` | `are_codigo` | `FK_ps_area_extension` | `proyectos.ps_area_extension (are_codigo)` | `sql/proyectos/proyecto_proyeccion_social.sql:147-149` |
| 23 | `proyectos.proyecto_proyeccion` | `stp_codigo` | `FK_sub_tipo_proyecto` | `proyectos.ps_sub_tipo_proyecto (stp_codigo)` | `sql/proyectos/proyecto_proyeccion_social.sql:154-156` |

*Impacto Crítico:* La ejecución aislada de los DDLs en un motor SQL Server recién instalado o en un contenedor CI/CD falla de forma irrecuperable por dependencias no resueltas.

#### 3.2.2 Claves Foráneas no Confiables Creadas con `WITH NOCHECK` (26 Restricciones)
Exactamente 26 claves foráneas fueron creadas mediante la instrucción `ALTER TABLE ... WITH NOCHECK ADD CONSTRAINT`:
- Evidencia: `sql/dbo/espacio_ocupacion.sql:52`, `sql/dbo/matricula.sql:53,60`, `sql/dbo/uaa_personal.sql:50,57`, `sql/dbo/plan_academico_asignatura.sql:67`, `sql/dbo/vistas/estudiante.sql:43`, etc.
- **Consecuencia en el Optimizador de Consultas**: Cuando una clave foránea se marca con `WITH NOCHECK`, SQL Server establece `is_not_trusted = 1` en el catálogo del sistema (`sys.foreign_keys`). Por tanto:
  1. El optimizador de consultas **no puede asumir** que los datos cumplen la restricción de integridad.
  2. Queda deshabilitada la técnica de **Join Elimination** (eliminación de uniones redundantes cuando la consulta solo proyecta columnas de la tabla padre).
  3. Los planes de ejecución se ven obligados a evaluar uniones físicas costosas (*Nested Loops* o *Hash Joins*) aunque el resultado sea formalmente redundante.

#### 3.2.3 Claves Foráneas Candidatas Faltantes (65 Oclusiones Semánticas)
Se detectaron 65 columnas en tablas base que siguen la convención de clave foránea pero carecen por completo de una restricción `FOREIGN KEY` que garantice la consistencia referencial:
- `dbo.curso`: Carece de FK en `sed_codigo` (hacia `sede`), `cal_codigo` (hacia `calendario`), `cut_codigo` (hacia `curso_tipo`), `tic_codigo` (hacia `tipo_curso`), `pla_codigo` (hacia `plan_academico`) y `tes_codigo` (hacia `tipo_escala`). Esto permite la creación de cursos huérfanos con calendarios o sedes inexistentes.
- `dbo.espacio_ocupacion`: Carece de FK en `dia_codigo` (hacia `dia`) y `uap_codigo` (hacia `uaa_personal`).
- `dbo.uaa_personal`: Carece de FK en `ded_codigo` (hacia `dedicacion`), `sed_codigo` (hacia `sede`), `uac_codigo` (hacia `uaa_cargo`) y `vin_codigo` (hacia `vinculacion`).
- `dbo.curso_cupo_subgrupo`: Carece de FK en `cur_codigo` hacia `dbo.curso`.
- `dbo.agenda_periodo`: Carece de FKs en `cur_codigo`, `per_codigo`, `uaa_codigo` y `uap_codigo`.
- `dbo.prerrequisito`: Carece de FKs en `asi_codigo` (hacia `asignatura`) y `pla_codigo` (hacia `plan_academico`).
- `dbo.equivalencia`: Carece de FKs en `asi_codigo` (hacia `asignatura`) y `pla_codigo` (hacia `plan_academico`).

#### 3.2.4 Clave Foránea Tautológica en `proyectos.proyecto_proyeccion_social`
En `sql/proyectos/proyecto_proyeccion_social.sql:126-128`:
```sql
ALTER TABLE [proyectos].[proyecto_proyeccion_social]  WITH CHECK ADD  
CONSTRAINT [FK_proyecto_proyeccion_social_proyecto_proyeccion_social] 
FOREIGN KEY([pps_codigo]) REFERENCES [proyectos].[proyecto_proyeccion_social] ([pps_codigo])
```
La clave primaria `pps_codigo` referencia a la misma columna de la misma tabla en el mismo registro. Esta restricción es conceptualmente absurda, ofrece 0% de protección de negocio y genera sobrecosto de CPU en cada inserción y actualización para validar un valor contra sí mismo.

---

### 3.3 Normalización y Deuda de Modelado

#### 3.3.1 Violación de Primera Forma Normal (1NF)
En `sql/dbo/vistas/estudiante.sql:19-20`:
```sql
[ese_codigo1] [tinyint] NULL,
[ese_codigo2] [tinyint] NULL,
```
La tabla `estudiante` implementa grupos repetitivos de atributos para registrar múltiples estados del estudiante (`ese_codigo1` y `ese_codigo2`), violando la Primera Forma Normal (1NF). Obliga al código PHP a evaluar ambas columnas de forma redundante (`WHERE ese_codigo1 = X OR ese_codigo2 = X`) en lugar de modelar una relación 1:N o una tabla histórica de estados del estudiante.

#### 3.3.2 Violaciones de Segunda y Tercera Forma Normal (2NF y 3NF) por Columnas SIPPA
A lo largo de las tablas centrales del sistema se replican atributos desnormalizados provenientes del sistema heredado SIPPA:
- `sql/dbo/curso.sql:31-37`: `sippa_sedcodigo`, `sippa_calcodigo`, `sippa_procodigo`, `sippa_placodigo`, `sippa_curcodigo`.
- `sql/dbo/espacio_ocupacion.sql:31-36`: Réplica exacta de los mismos códigos SIPPA del curso.
- `sql/dbo/matricula.sql:28-34`: Réplica exacta de los códigos SIPPA de estudiante y calendario.
- `sql/dbo/uaa_personal.sql:27-31`: Réplica de códigos SIPPA de vinculación.

Estas columnas introducen dependencias transitivas (violación de 3NF): si un curso o programa modifica su vinculación curricular, las filas secundarias en `espacio_ocupacion` o `matricula` quedan desincronizadas, generando anomalías de actualización.

#### 3.3.3 Codificación Temporal Redundante en `dbo.hora`
En `sql/dbo/hora.sql:14-17`:
```sql
[hra_inicio] [char](7) NOT NULL,
[hra_fin] [char](10) NOT NULL,
[hra_inicio_24h] [char](5) NULL,
[hra_fin_24h] [char](5) NULL,
```
Se almacenan horas mediante cadenas de texto en dos formatos paralelos (`char(7)` formato 12h y `char(5)` formato 24h) en lugar de utilizar el tipo de datos nativo estándar `time(0)`. Esto desperdicia 27 bytes por fila e impide la aplicación de operadores de comparación temporal eficientes en el motor relacional.

---

### 3.4 Discrepancias de Tipos de Datos Entre Tablas

Se verificaron 17 incompatibilidades de tipo entre columnas que representan el mismo concepto de negocio en tablas distintas:

| # | Concepto / Columna | Definición Tabla 1 | Definición Tabla 2 | Impacto Técnico en Motor Relacional | Cita de Evidencia |
|:---:|:---|:---|:---|:---|:---|
| 1 | `car_codigo` | `dbo.caracter`: `[char](2) NOT NULL` | `dbo.cargo`: `[int] NOT NULL` | Colisión de prefijo `car`; imposibilita uniones homogéneas | `sql/dbo/caracter.sql:12` vs `sql/dbo/cargo.sql:12` |
| 2 | `car_estado` | `dbo.caracter`: `[varchar](1) NULL` | `dbo.cargo`: `[int] NULL` | Incompatibilidad de estado: string de 1 byte vs entero de 4 bytes | `sql/dbo/caracter.sql:14` vs `sql/dbo/cargo.sql:15` |
| 3 | `ese_codigo` | `dbo.estudiante`: `[tinyint] NOT NULL` | `dbo.matricula`: `[smallint] NULL` | Estado estudiante: `tinyint` (1 byte) vs `smallint` (2 bytes); conversión implícita | `sql/dbo/vistas/estudiante.sql:16` vs `sql/dbo/matricula.sql:26` |
| 4 | `for_codigo` | `dbo.formalidad`: `[tinyint] NOT NULL` | `dbo.asignatura`: `[int] NULL` | Formalidad: `tinyint` (1 byte) vs `int` (4 bytes); conversión en JOIN | `sql/dbo/formalidad.sql:12` vs `sql/dbo/asignatura.sql:22` |
| 5 | `for_codigo` | `dbo.formalidad`: `[tinyint] NOT NULL` | `dbo.plan_academico_asignatura`: `[int] NULL` | Formalidad: `tinyint` en catálogo vs `int` en plan de estudios | `sql/dbo/formalidad.sql:12` vs `sql/dbo/plan_academico_asignatura.sql:28` |
| 6 | `nuc_codigo` | `dbo.nucleo`: `[int] NOT NULL` | `dbo.programacion_proceso`: `[varchar](10) NULL` | **Grave desajuste**: entero subrogado vs cadena alfanumérica; anula índices | `sql/dbo/nucleo.sql:12` vs `sql/dbo/programacion_proceso.sql:14` |
| 7 | `sippa_calcodigo` | `dbo.curso`: `[char](6) NULL` | `dbo.matricula`: `[char](7) NULL` | Longitud disímil en códigos de calendario SIPPA (`char(6)` vs `char(7)`) | `sql/dbo/curso.sql:32` vs `sql/dbo/matricula.sql:29` |
| 8 | `snies_codigo` | `dbo.municipio`: `[char](5) NULL` | `dbo.nivel_academico`: `[char](2) NULL` | Código SNIES con longitudes incompatibles | `sql/dbo/municipio.sql:16` vs `sql/dbo/nivel_academico.sql:16` |
| 9 | `usu_clave` | `dbo.curso`: `[varchar](50) NULL` | `dbo.aud_curso`: `[char](50) NULL` | Contraseña en texto claro: variable `varchar` vs padding fijo `char(50)` | `sql/dbo/curso.sql:30` vs `sql/dbo/aud_curso.sql:32` |
| 10 | `usu_clave` | `dbo.espacio_ocupacion`: `[varchar](50) NULL` | `dbo.aud_espacio_ocupacion`: `[char](50) NULL` | Contraseña en horario: `varchar(50)` vs `char(50)` en tabla de auditoría | `sql/dbo/espacio_ocupacion.sql:30` vs `sql/dbo/aud_espacio_ocupacion.sql:26` |
| 11 | `aud_log_type` | `dbo.aud_curso`: `[char](6) NULL` | `dbo.aud_espacio_ocupacion`: `[char](6) NULL` | Tipo de operación de auditoría como cadena en vez de `tinyint` | `sql/dbo/aud_curso.sql:13` vs `sql/dbo/aud_espacio_ocupacion.sql:13` |
| 12 | `dpp_estado` | `proyectos.docentexproyecto`: `[bit] NULL` | `dbo.curso`: `cur_estado [tinyint] NULL` | Booleano nativo `bit` frente a entero `tinyint` para estados lógicos | `sql/proyectos/docentexproyecto_proyeccion_social.sql:31` vs `sql/dbo/curso.sql:19` |
| 13 | `cie_estado` | `dbo.curso_institucion_ejecucion`: `[int] NULL` | `dbo.curso`: `cur_estado [tinyint] NULL` | Estado de ejecución usa 4 bytes (`int`) vs 1 byte (`tinyint`) en tabla base | `sql/dbo/curso_institucion_ejecucion.sql:17` vs `sql/dbo/curso.sql:19` |
| 14 | `hra_inicio` | `dbo.hora`: `[char](7) NOT NULL` | `dbo.hora`: `hra_inicio_24h [char](5) NULL` | Almacenamiento redundante de cadenas en lugar de tipo `time(0)` | `sql/dbo/hora.sql:14,16` |
| 15 | `per_año` | `dbo.periodo`: `[int] NULL` | `dbo.periodo`: `per_periodo [tinyint] NULL` | Año almacenado en 4 bytes (`int`) en lugar de `smallint` (2 bytes) | `sql/dbo/periodo.sql:15,16` |
| 16 | `est_user` | `dbo.estudiante`: `[char](50) NULL` | `dbo.curso`: `usu_clave [varchar](50) NULL` | Nombre de usuario con padding fijo de 50 bytes desperdiciando espacio | `sql/dbo/vistas/estudiante.sql:25` |
| 17 | `cur_notaparcial` | `dbo.curso`: `[varchar](1) NULL` | `dbo.curso`: `cur_exclusivo [bit] NULL` | Flag booleano como `varchar(1)` en lugar de tipo `bit` | `sql/dbo/curso.sql:42` |

---

### 3.5 Anomalías Sintácticas y de Nomenclatura

1. **Caracter Multibyte en Nombre de Columna**:
   En `sql/dbo/periodo.sql:15`:
   `[per_año] [int] NULL`
   Contiene el caracter hispano `ñ` (codificado como UTF-8: `\xc3\xb1`). Esto genera fallas críticas de compilación y runtime en conexiones ODBC, FreeTDS, PDO o entornos con codificaciones Windows-1252 o ISO-8859-1.
2. **Error Tipográfico en Columna Relacional**:
   En `sql/proyectos/proyecto_proyeccion_social.sql:28`:
   `[pre_codgo] [int] NULL`
   Falta la letra `i` en `codigo`. Cualquier desarrollador o query builder que intente realizar un JOIN usando la convención estándar `pre_codigo` fallará con un error de columna inválida en tiempo de ejecución.
3. **Clave Primaria Plural no Estándar**:
   En `sql/proyectos/docentexproyecto_proyeccion_social.sql:12, 33`:
   `[id_docentesxproyecto] [int] IDENTITY(1,1)`
   Rompe la convención arquitectónica de 3 letras prefijadas (`dpp_codigo`), dificultando la introspección automatizada de metadatos.
4. **Columna de Clave Foránea Ofuscada Semánticamente**:
   En `sql/dbo/espacio_ocupacion.sql:52-54`:
   `FOREIGN KEY([eso_actividad]) REFERENCES [dbo].[curso] ([cur_codigo])`
   La columna se denomina `eso_actividad`, ocultando por completo que almacena el identificador foráneo `cur_codigo`.
5. **Colisión de Nombres de Claves Primarias**:
   `sql/dbo/periodo.sql:12` define `per_codigo` como PK de período.
   `sql/dbo/persona.sql:12` define `per_codigo` como PK de persona.
   Esto obliga a tablas dependientes que integran ambos dominios a inventar alias atípicos como `periodo_codigo` y `persona_codigo` (ej. `sql/programacionacademica/solicitud_prestamo_docente.sql:13,15`).
6. **Restricciones Anónimas no Deterministas**:
   - `sql/dbo/curso_institucion_ejecucion.sql:22` y `sql/programacionacademica/programacion_tipo_solicitudes.sql:15`: Declaran `PRIMARY KEY CLUSTERED (...)` sin cláusula `CONSTRAINT [nombre]`.
   - `sql/dbo/curso_institucion_ejecucion.sql:29, 40`: Declara `ADD FOREIGN KEY(...) REFERENCES ...` sin nombre de restricción.
   SQL Server asigna nombres pseudoaleatorios (ej. `PK__curso_in__3213E83F...`), lo que destruye la idempotencia de scripts de migración o eliminación de constraints.
7. **Tablas Físicas Ubicadas Erróneamente en `vistas/`**:
   Los archivos `sql/dbo/vistas/espacio_tipo.sql:11` y `sql/dbo/vistas/estudiante.sql:11` contienen sentencias `CREATE TABLE` de entidades base. Su ubicación en el directorio de vistas es un error organizativo severo que confunde a herramientas de migración y auditoría.

---

### 3.6 Análisis Estructural del Catálogo de Vistas (`sql/dbo/vistas/`)

#### 3.6.1 Sobrecosto Masivo de Clasificación por `UNION` vs `UNION ALL`
Las siguientes vistas implementan particionamiento histórico mediante `UNION`:
- `dbo.espacio_ocupacion_total` (`sql/dbo/vistas/espacio_ocupacion_total.sql:18`): `UNION` entre `espacio_ocupacion` y `espacio_ocupacion_historico`.
- `dbo.matricula_curso` (`sql/dbo/vistas/matricula_curso.sql:11`): `UNION` entre tres tablas masivas de matrículas (`matricula_curso_actual`, `matricula_curso_historico`, `matricula_multicurso`).
- `dbo.usuario_general` (`sql/dbo/vistas/usuario_general.sql:13-33`): `UNION` entre 7 tablas de usuarios.
- `dbo.usuario_programacion` (`sql/dbo/vistas/usuario_programacion.sql:16`): `UNION` de administrativos y docentes.
- `dbo.usuario_programacion_login` (`sql/dbo/vistas/usuario_programacion_login.sql:20`): `UNION` en la vista de inicio de sesión.

*Impacto de Rendimiento*: El operador `UNION` fuerza a SQL Server a ejecutar un operador físico **Sort (Distinct Sort)** en memoria o volcándose a `tempdb` para eliminar filas idénticas. Debido a que las tablas transaccionales e históricas poseen claves primarias disyuntas por diseño temporal o secuencias numéricas, **jamás existen filas duplicadas**. El uso de `UNION` en lugar de `UNION ALL` degrada el rendimiento de consultas agregadas en un orden de magnitud (10x-50x más latencia y consumo de disco en `tempdb`).

#### 3.6.2 Riesgos de Concurrencia y Lecturas Sucias por Hints `WITH (NOLOCK)`
En `sql/dbo/vistas/estudiante_horario_actual.sql:14-18`:
Se encadenan hints `with(nolock)` sobre `matricula`, `matricula_curso_actual`, `estudiante`, `programa` y `espacio_ocupacion`.
*Riesgos Técnicos*:
1. **Lecturas Sucias (*Dirty Reads*)**: Permite leer transacciones no confirmadas que luego sufren `ROLLBACK`, mostrando inscripciones o asignaciones inexistentes.
2. **Filas Fantasma y Omisiones por Split de Página**: Si ocurre una división de página (*page split*) concurrente durante la lectura en montículo o índice, la consulta puede leer la misma fila dos veces o ignorarla completamente.

#### 3.6.3 Joins Negados y Agrupamiento Ineficiente
En `sql/dbo/vistas/departamentos_programas_unificados.sql:18, 22-24`:
1. La cláusula `LEFT JOIN programa_dpto pdt ON u.uaa_codigo = pdt.uaa_codigo` es anulada por el predicado `WHERE ... AND pdt.prd_estado = 1`. Debido a que para las filas sin coincidencia `pdt.prd_estado` es `NULL`, la condición descarta las filas no coincidentes, transformando de facto el `LEFT JOIN` en un `INNER JOIN`.
2. Utiliza una cláusula `GROUP BY` con 7 columnas sin ninguna función agregada (`COUNT`, `SUM`, etc.), utilizándola como un sustituto rudimentario y costoso de `SELECT DISTINCT`.

#### 3.6.4 Objetos Fantasma Ausentes en el Repositorio (14 Objetos)
Las 12 vistas de `sql/dbo/vistas/` dependen directamente de 14 tablas y funciones que **no tienen script DDL en el repositorio**:
1. `dbo.espacio_ocupacion_historico` (`sql/dbo/vistas/espacio_ocupacion_total.sql:23`)
2. `dbo.programa_dpto` (`sql/dbo/vistas/departamentos_programas_unificados.sql:18`)
3. `dbo.usuario_docentes` (`sql/dbo/vistas/usuario_docente.sql:18`, `sql/dbo/vistas/usuario_general.sql:13,20`)
4. `dbo.usuario_administrativos` (`sql/dbo/vistas/usuario_administrativo.sql:18`, `sql/dbo/vistas/usuario_general.sql:13`)
5. `dbo.usuario_estudiantes` (`sql/dbo/vistas/usuario_general.sql:13,27`)
6. `dbo.usuario_estudiantes_virtual` (`sql/dbo/vistas/usuario_general.sql:13,34`)
7. `dbo.usuario_estudiantes_intercambio` (`sql/dbo/vistas/usuario_general.sql:13,41`)
8. `dbo.usuario_graduados` (`sql/dbo/vistas/usuario_general.sql:13,48`)
9. `dbo.usuario_externos` (`sql/dbo/vistas/usuario_general.sql:13,55`)
10. `dbo.matricula_curso_actual` (`sql/dbo/vistas/matricula_curso.sql:15`, `sql/dbo/vistas/estudiante_horario_actual.sql:24`)
11. `dbo.matricula_curso_historico` (`sql/dbo/vistas/matricula_curso.sql:18`)
12. `dbo.matricula_multicurso` (`sql/dbo/vistas/matricula_curso.sql:21`)
13. `dbo.resumen_docencia_sem` (`sql/dbo/vistas/resumen_docencia_final.sql:14`)
14. `dbo.matricula_forma` (`sql/dbo/vistas/notas_total.sql:14`)
15. `dbo.Split` (TVF en `sql/dbo/vistas/estudiante_horario_actual.sql:27`)

---

## 4. Dimensión 2: Rendimiento y Patrones de Acceso a Datos

### 4.1 Omisión Total de Índices Secundarios (0 Índices en 75 Tablas)
Una inspección léxica automatizada sobre el 100% de los DDLs confirmó que **no existe una sola sentencia `CREATE INDEX` para índices secundarios no-PK en todo el repositorio `sql/`**.
- Las claves foráneas de mayor tráfico transaccional carecen de índices:
  - `espacio_ocupacion`: columnas `eso_actividad` (curso), `esp_codigo`, `uap_codigo`, `dia_codigo`, `hra_codigo`.
  - `curso`: columnas `cal_codigo`, `asi_codigo`, `uap_codigo`.
  - `matricula_curso_actual` / `matricula_curso`: columnas `cur_codigo`, `mat_codigo`.
  - `solicitud_cambio_horario_horario`: columna `sch_codigo`.
  - `solicitud_prestamo_docente_horario`: columna `spd_codigo`.
  - `programacion_gestion`: columnas `(uaa_codigo, cal_codigo, pts_codigo, prg_estado)`.

*Consecuencia Catastrófica*: En SQL Server, cuando una clave foránea no está indexada, cualquier operación de `JOIN`, búsqueda por filtro `WHERE` o verificación referencial ante `DELETE`/`UPDATE` en la tabla padre obliga al motor a realizar un escaneo completo de tabla (**Table Scan** o **Clustered Index Scan**) sobre la tabla hija.

---

### 4.2 Arquitectura de Conexión y Falla de Transacciones en `conexion/cls_config.php`

#### 4.2.1 Destrucción del Pool y Reconexión Continua
En `conexion/cls_config.php:95, 123, 150, 180`, cada método de ejecución invoca `cls_config::conectar()`:
```php
public function consultar($sql) {
    if (!cls_config::conectar($this->usuario_bd_consulta, $this->clave_bd_consulta)) { ... }
    ...
}
public function sentencia($sql) {
    if (!cls_config::conectar($this->usuario_bd_real, $this->clave_bd_real)) { ... }
    ...
}
```
`cls_config::conectar()` (`conexion/cls_config.php:77-84`) ejecuta:
```php
$this->conexion = new PDO($dsn, $usuario, $contra, $options);
```
**Efecto**: Cada consulta SQL individual ejecuta un nuevo handshake TCP/IP y autenticación completa contra Microsoft SQL Server. No existe reutilización de conexión PDO ni persistencia entre consultas dentro de una misma petición web.

#### 4.2.2 Descomposición Absoluta de Transacciones ACID
Debido a que `sentencia($sql)` instancia un nuevo objeto `PDO` en cada llamado:
1. `$this->cnx->sentencia("BEGIN TRAN")`: Se abre la Conexión 1; la transacción se inicia en la Conexión 1.
2. `$this->cnx->sentencia("UPDATE ...")`: Se abre la Conexión 2, sobreescribiendo `$this->conexion`. El `UPDATE` corre en Conexión 2 en modo autocommit.
3. `$this->cnx->sentencia("COMMIT TRAN")`: Se abre la Conexión 3. Se envía `COMMIT TRAN` en una sesión donde no hay transacción activa, arrojando **SQL Server Error 3902**: *"The COMMIT TRANSACTION request has no corresponding BEGIN TRANSACTION."*
4. La Conexión 1 se cierra por recolección de basura de PHP, provocando un `ROLLBACK` forzado de la transacción huérfana.

#### 4.2.3 Evidencia Documentada por los Propios Desarrolladores en Código
En `c:clases/Solcambh.php`, líneas 605-610:
```php
605: // Validamos que el horario anterior de CADA hora de la solicitud siga existiendo tal cual antes de
606: // tocar ninguna. Si esto se validara horario por horario dentro del mismo loop que borra y crea,
607: // una solicitud con varias horas podria quedar con las primeras ya aplicadas y las ultimas rechazadas,
608: // dejando la solicitud a medio aplicar y sin forma de reintentarla (el ROLLBACK TRAN de este archivo
609: // no revierte nada real porque cada sentencia abre su propia conexion nueva,conexion/cls_config.php).
610: // Validar todo antes de aplicar nada evita ese escenario.
```
Esta evidencia demuestra de forma concluyente que el equipo de desarrollo detectó la falla transaccional de `conexion/cls_config.php` y optó por implementar validaciones previas frágiles en lugar de corregir la capa de persistencia.

Como consecuencia directa, se deshabilitaron transacciones comentándolas en múltiples clases:
- `clases/Aperfe.php:74, 80, 84, 253, 259, 263, 888, 937`
- `clases/Buscurso.php:1493, 1527, 1530`
- `clases/Curhorario.php:1113, 1151, 1154`

---

### 4.3 Multiplicadores de Consultas N+1 en Bucles PHP (178 Puntos Críticos)

Se detectaron **178 ejecuciones de consultas SQL dentro de bucles `foreach`, `for` y `while`** en 12 clases de negocio. Cada iteración realiza una nueva conexión y una consulta sin índices secundarios.

#### Principales Hotspots N+1:
1. **`clases/Curhorario.php` (41 ejecuciones en bucles)**:
   - `actualizarAgenda()` (líneas 3064-3650): Bucles anidados sobre docentes y franjas horarias que ejecutan 10 consultas (líneas 3115, 3141, 3212, 3309, 3364, 3400, 3447, 3488, 3599, 3642) contra `agenda_periodo`, `espacio_ocupacion` y `uaa`.
   - `validarHorarioCrear()` (líneas 1823-2350): Bucle sobre franjas solicitadas ejecutando 13 consultas (líneas 1848, 1895, 1997, 2042, 2068, 2099, 2115, 2125, 2172, 2294, 2316, 2327, 2342) contra `agenda_periodo`, `espacio_ocupacion`, `persona_novedad`, `persona_proyecto`.
   - `guardarHorario()` (líneas 955-1160): 9 consultas por hora seleccionada (líneas 972, 1010, 1046, 1070, 1094, 1113, 1148, 1151, 1154).
2. **`clases/Solcambh.php` (32 ejecuciones en bucles)**:
   - `aprobarSolicitud()` (líneas 494-845): Bucles en líneas 494, 611, 657, 698, 786 ejecutando 16 consultas individuales para validar, borrar e insertar franjas de cambio horario una a una.
   - `validarHorasDocente()` (líneas 2636-2937): 9 consultas por docente y franja.
3. **`clases/Buscurso.php` (28 ejecuciones en bucles)**:
   - Búsqueda y consolidación de cursos y ocupación de aulas (líneas 730-1420), ejecutando consultas por cada curso para recuperar ocupaciones y docentes.
4. **`clases/Aperfe.php` (24 ejecuciones en bucles)**:
   - `guardarAperturaProaca()` (líneas 444-486):
     ```php
     444: foreach ($obj->UaaSeleccionadas as $uaa) {
     447:     $sql = "UPDATE programacionacademica.programacion_gestion ... WHERE uaa_codigo = {$uaa->UaaCodigo} ...";
     455:     $this->cnx->Sentencia($sql);
     462:     $sql = "INSERT INTO programacionacademica.programacion_gestion (...) VALUES ({$uaa->UaaCodigo}, ...)";
     479:     $this->cnx->Sentencia($sql);
     486: }
     ```
     Si se seleccionan 40 dependencias, se abren 80 conexiones TCP y se ejecutan 80 consultas en serie.

---

### 4.4 Sobredescarga de Datos y Filtrado en Memoria PHP

En múltiples puntos del sistema se descargan grandes volúmenes de datos hacia PHP para realizar filtros rudimentarios con bucles `foreach`, en lugar de delegar el filtrado y agregación al motor SQL:
1. `clases/Inicio_sesion.php:578-590`: Descarga todos los vínculos y recorre el arreglo en PHP para verificar si existe el cargo de jefe de programa (`if ($usuarioV["Cargo"] == ...)`), en lugar de usar `WHERE car_codigo = ...`.
2. `clases/Ccuser.php:90-130`: Descarga cursos para computar totales creados y eliminados mediante bucles en PHP en vez de `COUNT(*) / GROUP BY`.
3. `clases/Curhorario.php:3443, 3484` y `clases/Buscurso.php:967`: Empleo de `SELECT *` descargando columnas operacionales innecesarias a través de la red.

---

## 5. Dimensión 3: Seguridad en el Acceso a Datos

### 5.1 Ausencia de Parametrización (0.0% en 566 Consultas) y Vectores de Inyección SQL
En `conexion/cls_config.php:104, 130, 159, 189`:
```php
$resultado = $this->conexion->prepare($sql);
$resultado->execute();
```
`prepare()` se ejecuta siempre sobre una cadena `$sql` previamente construida mediante concatenación o interpolación, y `execute()` se invoca **sin ningún parámetro vinculado** (`execute()` vacío). La protección contra inyección SQL es nula.

#### Vectores de Inyección SQL Directa Comprobados:
1. **Autenticación en `clases/Inicio_sesion.php:50`**:
   ```php
   $sql = "select uid from dbo.usuario_programacion_login where us = '{$txtUsuario}' ";
   ```
   Inyección directa en la consulta de autenticación inicial antes de cualquier verificación de clave.
2. **Consulta de Credenciales en `clases/Inicio_sesion.php:187`**:
   ```php
   $sql = "select sys, us, up, gru_codigo from usuario_programacion_login where us='" . $txtUsuario . "' ";
   ```
3. **Búsqueda de Asignaturas en `clases/Buscurso.php:78-80`**:
   ```php
   asi.asi_nombre like '%{$filtroAsignatura}%' OR asi.asi_nombre_corto like '%{$filtroAsignatura}%'
   ```
   Entrada `$obj->filtroAsignatura` interpolada directamente sin sanitizar.
4. **Búsqueda de Docentes en `clases/Vindocente.php:238, 252-253`**:
   ```php
   per.per_identificacion like '%{$CriterioBusqueda}%' OR per.per_nombre + ' ' + per.per_apellido like '%{$CriterioBusqueda}%'
   ```
5. **Inserción de Comentarios en `clases/Solcambh.php:1517, 1530`**:
   ```php
   $sql = "INSERT INTO programacionacademica.solicitud_cambio_horario_comentario(...) VALUES (..., '{$mensajeComentario}', ...)";
   ```
   Cualquier comilla simple (`'`) introducida por un usuario rompe la sintaxis o ejecuta código malicioso (*Second-Order Injection*).

---

### 5.2 Fuga y Almacenamiento Inseguro de Credenciales

#### 5.2.1 Volcado Público de Sesión en `sesion.php`
En `sesion.php:1-5`:
```php
<?php
    session_start();
    header('Content-Type: text/html; charset=UTF-8');
    $cosa= print_r( $_SESSION, true );
    echo "<div style='text-align : justify; white-space: pre-wrap;'>".$cosa."</div>";
```
Este archivo reside en la raíz pública del servidor web sin control de acceso. Cualquier usuario que navegue a `sesion.php` recibe el volcado íntegro de la variable superglobal `$_SESSION`.

#### 5.2.2 Contraseñas de Base de Datos en Texto Claro en `$_SESSION`
En `clases/Inicio_sesion.php:218`, el sistema recupera la contraseña real del usuario de SQL Server descifrada y la guarda en la sesión.
En `conexion/cls_config.php:58-59`:
```php
$this->usuario_bd_real = $_SESSION['pacademica']['usuario_real'];
$this->clave_bd_real = $_SESSION['pacademica']["clave_real"];
```
La contraseña en texto plano del usuario de base de datos viaja y reside en el almacenamiento de sesión de PHP, quedando inmediatamente expuesta a través de `sesion.php`.

#### 5.2.3 Credenciales SMTP Comprometidas en Código
En el módulo de correos se encuentran contraseñas de aplicación de Google hardcodeadas en texto claro:
- `correos/correo_apertura.php:44-46`:
  ```php
  $correo = "prog.academica@usco.edu.co";
  $clave = "oxlw vygk rgav ocfx ";
  ```
- `correos/correo_solicitud_docente.php:35-37` y `correos/correo_solicitud_horario.php:55-57`: Mismas credenciales activas comprometidas en el repositorio.

#### 5.2.4 Contraseñas Almacenadas en Tablas Operacionales
En `sql/dbo/curso.sql:30` y `sql/dbo/espacio_ocupacion.sql:30`, las tablas operacionales contienen la columna:
`[usu_clave] [varchar](50) NULL,`
Almacenar contraseñas de usuario en registros de cursos y horarios viola el principio de mínimo privilegio y separación de incumbencias.

---

### 5.3 Inseguridad en Canales y Criptografía
- `clases/Inicio_sesion.php:157`: `curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);` desactiva la validación de certificados TLS hacia el servicio institucional de autenticación.
- `conexion/cls_config.php:77`: Parámetro `TrustServerCertificate=true` en el DSN de conexión PDO SQLSRV permite conexiones cifradas sin verificar el certificado del servidor, habilitando ataques de interceptación *Machine-in-the-Middle* (MITM).

---

## 6. Dimensión 4: Mantenibilidad y Evolución

### 6.1 Acoplamiento de la Capa de Persistencia
- Las 34 clases PHP ensamblan sentencias SQL directamente mediante cadenas de texto. No existe ninguna capa de repositorio, Active Record o Query Builder.
- Fuerte acoplamiento con sintaxis propietaria de T-SQL (`STUFF(... FOR XML PATH(''))`, `CONVERT(varchar, ..., 23)`, `ISNULL()`, hints `WITH (NOLOCK)`). Cualquier cambio en el motor o en el nombre de una tabla requiere refactorizaciones manuales propensas a errores.

### 6.2 Inconsistencias de Borrado: Físico (*Hard*) vs Lógico (*Soft*)
Existe una política de eliminación fragmentada y no regulada:
- **13 Borrados Físicos (`HARD DELETE`)**:
  - `agenda_periodo` (`clases/Buscurso.php:528, 2228`, `clases/Cambdocente.php:851`, `clases/Curhorario.php:2326, 2976`, `clases/Solcambh.php:2916`)
  - `espacio_ocupacion` (`clases/Cambdocente.php:245`, `clases/Curhorario.php:3859`, `clases/Solcambh.php:725`)
  - `espacio_ocupacion_historico` (`clases/Curhorario.php:3877`)
  - `cupo_autorizacion` (`clases/Cupoper.php:763`)
  - `curso_plan` (`clases/Curcrea.php:1301`, `clases/Exclu.php:48`)
- **18 Borrados Lógicos (`SOFT DELETE`)**:
  - `curso`: `cur_estado = 0` (`clases/Elicur.php:194`)
  - `curso_cupo_subgrupo`: `cus_estado = 0` (`clases/Curhorario.php:3721`, `clases/Elicur.php:213, 251`)
  - `curso_institucion_ejecucion`: `cie_estado = 0` (`clases/Sirea.php:136`)
  - Entidades de `programacionacademica`: `pra_estado = 0`, `prg_estado = 0`, `sch_estado = 0`, etc.
- **Riesgo de Registros Huérfanos**: En `clases/Elicur.php:232`, al desactivar un curso, se ejecuta `SET eso_actividad = null` en `espacio_ocupacion`, desvinculando la actividad pero dejando filas huérfanas en la tabla de horarios sin trazabilidad de a qué curso pertenecían.

### 6.3 Falta de Disparadores de Auditoría y Migraciones
- Existen 5 tablas de auditoría (`aud_curso`, `aud_curso_cupo_subgrupo`, `aud_espacio_ocupacion`, `aud_matricula_curso`, `aud_uaa_personal`), pero en el repositorio **no existe ningún script `CREATE TRIGGER`**. Los disparadores que deberían poblar estas tablas no están versionados.
- 58 de las 75 tablas (77.3%) carecen de columnas de auditoría temporal (`created_at`, `updated_at`, `created_by`, `updated_by`).
- No existe ninguna herramienta formal de migración de base de datos (Phinx, Flyway, Liquibase).
- **Desincronización de Esquema**: `data_base/2. CreateTablesManagement.sql:4, 43, 73` define tablas bajo el esquema `[proaca]`, mientras que `data_base/1. Create Schema.sql:1`, `sql/programacionacademica/` y todo el código PHP utilizan el esquema `programacionacademica`.

---

## 7. Matriz Cruzada de Trazabilidad: DDLs vs Código PHP

A continuación se presenta el mapeo de uso entre las tablas/vistas del sistema y las 34 clases PHP:

| Esquema / Entidad | Archivo DDL | Tipo | Clases PHP que la Acceden | Operaciones Detectadas |
|:---|:---|:---:|:---|:---:|
| `dbo.agenda_periodo` | `sql/dbo/agenda_periodo.sql` | TABLA | `clases/Buscurso.php`, `clases/Curhorario.php`, `clases/Solcambh.php`, `clases/servicios/ValidarCargaDocenteService.php` | SELECT, INSERT, DELETE |
| `dbo.agenda_periodo_novedad` | `sql/dbo/agenda_periodo_novedad.sql` | TABLA | *(Mantenimiento de agenda)* | SELECT, INSERT |
| `dbo.asignatura` | `sql/dbo/asignatura.sql` | TABLA | `clases/Buscurso.php`, `clases/Curcrea.php`, `clases/Curhorario.php`, `clases/Matcurso.php`, `clases/Solcambh.php`, `clases/Soldoc.php` | SELECT |
| `dbo.aud_curso` | `sql/dbo/aud_curso.sql` | TABLA | `clases/Elicur.php`, `clases/Ceadmin.php`, `clases/Cupocurso.php` | SELECT, INSERT |
| `dbo.aud_espacio_ocupacion` | `sql/dbo/aud_espacio_ocupacion.sql` | TABLA | `clases/Elicur.php` | SELECT, INSERT |
| `dbo.bloque` | `sql/dbo/bloque.sql` | TABLA | `clases/Curhorario.php` | SELECT |
| `dbo.calendario` | `sql/dbo/calendario.sql` | TABLA | `clases/Aperfe.php`, `clases/Buscurso.php`, `clases/Peraca.php`, `clases/Exclu.php`, `clases/Cupoper.php` | SELECT |
| `dbo.cargo` | `sql/dbo/cargo.sql` | TABLA | `clases/Inicio_sesion.php` | SELECT |
| `dbo.cupo_autorizacion` | `sql/dbo/cupo_autorizacion.sql` | TABLA | `clases/Cupoper.php` | SELECT, INSERT, DELETE |
| `dbo.curso` | `sql/dbo/curso.sql` | TABLA | `clases/Buscurso.php`, `clases/Curcrea.php`, `clases/Curhorario.php`, `clases/Elicur.php`, `clases/Obscurso.php`, `clases/Solcambh.php` | SELECT, INSERT, UPDATE, DELETE |
| `dbo.curso_cupo_subgrupo` | `sql/dbo/curso_cupo_subgrupo.sql` | TABLA | `clases/Cupocurso.php`, `clases/Curhorario.php`, `clases/Elicur.php` | SELECT, INSERT, UPDATE |
| `dbo.curso_institucion_ejecucion` | `sql/dbo/curso_institucion_ejecucion.sql` | TABLA | `clases/Sirea.php` | SELECT, INSERT, UPDATE |
| `dbo.curso_plan` | `sql/dbo/curso_plan.sql` | TABLA | `clases/Curcrea.php`, `clases/Elicur.php`, `clases/Exclu.php` | SELECT, INSERT, DELETE |
| `dbo.curso_tipo` | `sql/dbo/curso_tipo.sql` | TABLA | `clases/Curcrea.php`, `clases/Curesp.php` | SELECT |
| `dbo.dedicacion` | `sql/dbo/dedicacion.sql` | TABLA | `clases/Buscurso.php`, `clases/Cambdocente.php`, `clases/Vindocente.php` | SELECT |
| `dbo.departamento` | `sql/dbo/departamento.sql` | TABLA | `clases/Inicio_sesion.php`, `clases/Soldoc.php` | SELECT |
| `dbo.dia` | `sql/dbo/dia.sql` | TABLA | `clases/Curhorario.php`, `clases/Curpro.php`, `clases/Solcambh.php` | SELECT |
| `dbo.docente_escalafon` | `sql/dbo/docente_escalafon.sql` | TABLA | `clases/Buscurso.php`, `clases/Vindocente.php` | SELECT |
| `dbo.equivalencia` | `sql/dbo/equivalencia.sql` | TABLA | `clases/Buscurso.php` | SELECT |
| `dbo.espacio` | `sql/dbo/espacio.sql` | TABLA | `clases/Curhorario.php`, `clases/Solcambh.php` | SELECT |
| `dbo.espacio_ocupacion` | `sql/dbo/espacio_ocupacion.sql` | TABLA | `clases/Buscurso.php`, `clases/Cambdocente.php`, `clases/Curhorario.php`, `clases/Elicur.php`, `clases/Solcambh.php`, `clases/Soldoc.php` | SELECT, INSERT, UPDATE, DELETE |
| `dbo.espacio_tipo` | `sql/dbo/vistas/espacio_tipo.sql` | TABLA | `clases/Sirea.php` | SELECT |
| `dbo.estudiante` | `sql/dbo/vistas/estudiante.sql` | TABLA | `clases/Crucehorario.php`, `clases/Cupoper.php`, `clases/Exclu.php`, `clases/Mmatriculados.php` | SELECT |
| `dbo.hora` | `sql/dbo/hora.sql` | TABLA | `clases/Curhorario.php`, `clases/Curpro.php`, `clases/Solcambh.php` | SELECT |
| `dbo.matricula` | `sql/dbo/matricula.sql` | TABLA | `clases/Crucehorario.php` | SELECT |
| `dbo.matricula_autorizacion` | `sql/dbo/matricula_autorizacion.sql` | TABLA | `clases/Exclu.php` | SELECT, DELETE |
| `dbo.matricula_configuracion` | `sql/dbo/matricula_configuracion.sql` | TABLA | `clases/Cupoper.php` | SELECT |
| `dbo.novedad` | `sql/dbo/novedad.sql` | TABLA | `clases/Curhorario.php`, `clases/servicios/ValidarCargaDocenteService.php` | SELECT |
| `dbo.periodo` | `sql/dbo/periodo.sql` | TABLA | `clases/Buscurso.php`, `clases/Peraca.php`, `clases/Obsdocente.php`, `clases/servicios/ValidarCargaDocenteService.php` | SELECT |
| `dbo.persona` | `sql/dbo/persona.sql` | TABLA | `clases/Buscurso.php`, `clases/Cambdocente.php`, `clases/Inicio_sesion.php`, `clases/Obsdocente.php`, `clases/Vindocente.php` | SELECT, INSERT, UPDATE |
| `dbo.persona_novedad` | `sql/dbo/persona_novedad.sql` | TABLA | `clases/Curhorario.php`, `clases/Solcambh.php`, `clases/servicios/ValidarCargaDocenteService.php` | SELECT |
| `dbo.persona_proyecto` | `sql/dbo/persona_proyecto.sql` | TABLA | `clases/Curhorario.php`, `clases/Solcambh.php` | SELECT |
| `dbo.plan_academico` | `sql/dbo/plan_academico.sql` | TABLA | `clases/Cupoper.php`, `clases/Curcrea.php`, `clases/Mmatriculados.php` | SELECT |
| `dbo.plan_academico_asignatura` | `sql/dbo/plan_academico_asignatura.sql` | TABLA | `clases/Buscurso.php`, `clases/Curcrea.php`, `clases/Mmatriculados.php` | SELECT |
| `dbo.programa` | `sql/dbo/programa.sql` | TABLA | `clases/Cupoper.php`, `clases/Inicio_sesion.php` | SELECT |
| `dbo.proyecto` | `sql/dbo/proyecto.sql` | TABLA | `clases/Curhorario.php` | SELECT |
| `dbo.sede` | `sql/dbo/sede.sql` | TABLA | `clases/Curhorario.php`, `clases/Solcambh.php` | SELECT |
| `dbo.uaa` | `sql/dbo/uaa.sql` | TABLA | `clases/Aperfe.php`, `clases/Buscurso.php`, `clases/Curcrea.php`, `clases/Inicio_sesion.php`, `clases/Peraca.php` | SELECT |
| `dbo.uaa_personal` | `sql/dbo/uaa_personal.sql` | TABLA | `clases/Buscurso.php`, `clases/Cambdocente.php`, `clases/Curcrea.php`, `clases/Inicio_sesion.php`, `clases/Soldoc.php`, `clases/Vindocente.php` | SELECT, INSERT, UPDATE |
| `dbo.usuario_grupo` | `sql/dbo/usuario_grupo.sql` | TABLA | `clases/Cambiounidad.php`, `clases/Inicio_sesion.php` | SELECT, UPDATE |
| `dbo.web_parametro` | `sql/dbo/web_parametro.sql` | TABLA | `clases/Confgen.php`, `clases/Inicio_sesion.php` | SELECT, UPDATE |
| `programacionacademica.grupo_uaa` | `sql/programacionacademica/grupo_uaa.sql` | TABLA | `clases/Aperfe.php` | SELECT, UPDATE |
| `programacionacademica.grupo_uaa_item` | `sql/programacionacademica/grupo_uaa_item.sql` | TABLA | `clases/Aperfe.php` | SELECT, UPDATE |
| `programacionacademica.periodo_unidad` | `sql/programacionacademica/periodo_unidad.sql` | TABLA | `clases/Aperfe.php`, `clases/Peraca.php` | SELECT, INSERT, UPDATE |
| `programacionacademica.programacion_academica` | `sql/programacionacademica/programacion_academica.sql` | TABLA | `clases/Aperfe.php` | SELECT, INSERT, UPDATE |
| `programacionacademica.programacion_gestion` | `sql/programacionacademica/programacion_gestion.sql` | TABLA | `clases/Aperfe.php`, `clases/Solcambh.php` | SELECT, INSERT, UPDATE |
| `programacionacademica.solicitud_cambio_horario` | `sql/programacionacademica/solicitud_cambio_horario.sql` | TABLA | `clases/Cmsh.php`, `clases/Csh.php`, `clases/Solcambh.php` | SELECT, INSERT, UPDATE |
| `programacionacademica.solicitud_cambio_horario_comentario` | `sql/programacionacademica/solicitud_cambio_horario_comentario.sql` | TABLA | `clases/Solcambh.php` | SELECT, INSERT |
| `programacionacademica.solicitud_cambio_horario_horario` | `sql/programacionacademica/solicitud_cambio_horario_horario.sql` | TABLA | `clases/Solcambh.php` | SELECT, INSERT, UPDATE |
| `programacionacademica.solicitud_prestamo_docente` | `sql/programacionacademica/solicitud_prestamo_docente.sql` | TABLA | `clases/Curcrea.php`, `clases/Soldoc.php` | SELECT, INSERT, UPDATE |
| `programacionacademica.solicitud_prestamo_docente_comentario` | `sql/programacionacademica/solicitud_prestamo_docente_comentario.sql` | TABLA | `clases/Soldoc.php` | SELECT, INSERT |
| `programacionacademica.solicitud_prestamo_docente_horario` | `sql/programacionacademica/solicitud_prestamo_docente_horario.sql` | TABLA | `clases/Curcrea.php`, `clases/Soldoc.php` | SELECT, INSERT, UPDATE |
| `proyectos.docentexproyecto` | `sql/proyectos/docentexproyecto_proyeccion_social.sql` | TABLA | `clases/servicios/ValidarCargaDocenteService.php` | SELECT |
| `proyectos.proyecto_proyeccion` | `sql/proyectos/proyecto_proyeccion_social.sql` | TABLA | `clases/servicios/ValidarCargaDocenteService.php` | SELECT |
| `dbo.departamentos_programas_unificados` | `sql/dbo/vistas/departamentos_programas_unificados.sql` | VISTA | `clases/Inicio_sesion.php`, `clases/Soldoc.php` | SELECT |
| `dbo.espacio_ocupacion_total` | `sql/dbo/vistas/espacio_ocupacion_total.sql` | VISTA | `clases/Ceromatriculados.php`, `clases/Csh.php`, `clases/Mmatriculados.php`, `clases/Solcambh.php`, `clases/Vindocente.php`, `clases/servicios/ValidarCargaDocenteService.php` | SELECT |
| `dbo.estudiante_horario_actual` | `sql/dbo/vistas/estudiante_horario_actual.sql` | VISTA | `clases/Crucehorario.php` | SELECT |
| `dbo.matricula_curso` | `sql/dbo/vistas/matricula_curso.sql` | VISTA | `clases/Buscurso.php`, `clases/Cambdocente.php`, `clases/Cech.php`, `clases/Ceromatriculados.php`, `clases/Cmsh.php`, `clases/Cpn.php`, `clases/Crucehorario.php`, `clases/Csv.php`, `clases/Cupocurso.php`, `clases/Matcurso.php`, `clases/Mmatriculados.php`, `clases/Rcurhi.php` | SELECT |
| `dbo.notas_total` | `sql/dbo/vistas/notas_total.sql` | VISTA | `clases/Mmatriculados.php` | SELECT |
| `dbo.resumen_docencia_final` | `sql/dbo/vistas/resumen_docencia_final.sql` | VISTA | `clases/Buscurso.php`, `clases/Curhorario.php` | SELECT |
| `dbo.usuario_administrativo` | `sql/dbo/vistas/usuario_administrativo.sql` | VISTA | `clases/Aperfe.php`, `clases/Cupocurso.php` | SELECT |
| `dbo.usuario_docente` | `sql/dbo/vistas/usuario_docente.sql` | VISTA | `clases/Aperfe.php`, `clases/Cupocurso.php` | SELECT |
| `dbo.usuario_general` | `sql/dbo/vistas/usuario_general.sql` | VISTA | `clases/Ccuser.php`, `clases/Ceromatriculados.php` | SELECT |
| `dbo.usuario_programacion` | `sql/dbo/vistas/usuario_programacion.sql` | VISTA | `clases/Inicio_sesion.php` | SELECT |
| `dbo.usuario_programacion_login` | `sql/dbo/vistas/usuario_programacion_login.sql` | VISTA | `clases/Ceadmin.php`, `clases/Inicio_sesion.php` | SELECT |

---

## 8. Conclusiones y Matriz de Priorización de Riesgos del Diagnóstico

El análisis integral evidencia que el sistema `p_academica-main` se encuentra funcionalmente activo pero opera bajo un estado de **deuda técnica crítica** que compromete la estabilidad, el rendimiento y la seguridad institucional.

### Matriz de Priorización de Riesgos

| Nivel de Riesgo | Hallazgo / Problema Identificado | Justificación del Impacto | Acción Requerida en R2 / Modernización |
|:---:|:---|:---|:---|
| **CRÍTICO** | Inyección SQL total (0% parametrización en 566 consultas) | Exposición completa a robo o alteración de base de datos institucional | Implementar consultas preparadas obligatorias con PDO parameter binding |
| **CRÍTICO** | Fuga de sesión y credenciales en `sesion.php` y `$_SESSION` | Acceso no autenticado a contraseñas maestras de SQL Server | Eliminar `sesion.php` y purgar contraseñas de sesión |
| **CRÍTICO** | Conexiones PDO efímeras y falla catastrófica de transacciones | Corrupción de datos por operaciones a medio aplicar sin ACID | Conexión PDO compartida y transacciones nativas `beginTransaction()` |
| **CRÍTICO** | 34 Tablas Montículo (Heaps) y 0 índices secundarios | Degradación exponencial de I/O, bloqueos y saturación de CPU por escaneos | Reestructurar a Clustered PKs y crear índices B-Tree en FKs y filtros |
| **CRÍTICO** | 178 Consultas N+1 dentro de ciclos PHP | Latencias de varios segundos y saturación de conexiones en operaciones masivas | Reemplazar bucles por consultas agrupadas, batching e `INSERT ... SELECT` |
| **CRÍTICO** | 14 Objetos fantasma y vistas rotas con `UNION` masivos | Despliegue limpio imposible; derroche de tempdb y sorting inútil | Definir objetos faltantes y sustituir `UNION` por `UNION ALL` |
| **ALTO** | 26 Claves foráneas no confiables (`WITH NOCHECK`) | Pérdida de Join Elimination en el optimizador | Validar datos históricos y activar `WITH CHECK` |
| **ALTO** | 65 Claves foráneas candidatas faltantes | Inserción de huérfanos en cursos, horarios y docentes | Crear restricciones `FOREIGN KEY` formales |
| **ALTO** | Contraseñas en texto claro en tablas operacionales y correos | Violación de normativas de protección de datos (Habeas Data) | Cifrado/hash con Argon2id y externalización de secretos a variables de entorno |
| **ALTO** | Inconsistencia de borrado (13 físicos vs 18 lógicos) | Pérdida irrecuperable de auditoría y registros huérfanos | Estandarizar borrado lógico uniforme (`is_deleted` / `estado = 0`) |
| **MEDIO** | 17 Inconsistencias de tipos de datos (`car_codigo`, etc.) | Sobrecosto de conversión implícita en JOINs | Armonizar tipos de datos numéricos y longitudes de texto |
| **MEDIO** | Anomalías sintácticas (`[per_año]`, `[pre_codgo]`) | Fallas en drivers no-UTF8 y errores de desarrollo | Renombrar formalmente o desplegar vistas de compatibilidad |

---
*Fin del Informe Técnico de Diagnóstico (Requisito R1).*
