# Modelo Entidad-Relación (ER) y Diccionario de Datos Integral
## Sistema de Programación Académica (`p_academica-main`)

> **Repositorio:** `p_academica-main`  
> **Ingeniería Inversa de Base de Datos:** Scripts DDL en `sql/` y trazabilidad de lógica en PHP (`clases/`, `logica/`, `data_base/`).  
> **Fecha de Consolidación:** Octubre de 2026  
> **Versión:** 2.0 (Modelado Modular y Diccionario Técnico Completo)  

---

## 1. Resumen Ejecutivo del Proyecto

El Sistema de Programación Académica (`p_academica-main`) es una plataforma corporativa universitaria de misión crítica responsable de la planificación semestral de la oferta curricular, la asignación y optimización de espacios físicos (aulas, laboratorios, auditorios), la administración de la nómina docente y la gobernanza de las solicitudes de cambio de horario y préstamos profesorales entre facultades.

A través de un proceso riguroso de ingeniería inversa aplicado sobre los 87 scripts SQL originales y el análisis estático de las clases y controladores PHP, se reconstruyó la topología relacional completa del sistema. El modelo resultante desacopla la base de datos en **dominios funcionales cohesivos**, resolviendo la integridad referencial tanto a nivel de restricciones DDL explícitas como de dependencias lógicas implícitas por convención de nombres.

---

## 2. Métricas Globales del Inventario Relacional

| Dimensión del Modelo | Cantidad | Descripción Arquitectónica |
| :--- | :---: | :--- |
| **Esquemas de Base de Datos** | **3** | `programacionacademica` (núcleo del módulo), `dbo` (corporativo institucional), `proyectos` (extensión social). |
| **Tablas Físicas de Base de Datos** | **75** | 12 en `programacionacademica`, 61 en `dbo` (incluye 2 en `vistas/`), 2 en `proyectos`. |
| **Vistas Analíticas Institucionales** | **12** | Vistas de seguridad, autenticación, consolidación de notas y horarios desnormalizados. |
| **Columnas Catalogadas en Diccionario** | **890+** | Tipos de datos, longitudes, nulabilidad, valores por defecto y descripciones funcionales. |
| **Claves Primarias (PK)** | **75** | 65 PKs de columna única basadas en IDENTITY, 8 PKs de columna única no-IDENTITY, y 2 PKs compuestas (`programa`, `persona_proyecto`). |
| **Claves Foráneas Explícitas (DDL)** | **107** | Restricciones `FOREIGN KEY` codificadas formalmente en los scripts DDL (cubre 100% de las 105 FKs base). |
| **Claves Foráneas Implícitas (Código)** | **94** | Relaciones por convención de nombres verificadas en código PHP y consultas SQL activas. |
| **Total de Relaciones Catalogadas** | **201** | Cobertura integral en matriz de relaciones y cardinalidad sin claves huérfanas. |
| **Catálogos Maestros Externos** | **23** | Tablas institucionales referenciadas (`pais`, `horario`, `ocupacion_tipo`, `matricula_tipo`, `nivel_academico_creditos`, etc.). |

---

## 3. Arquitectura Global y Contenedores de Dominio

La base de datos se estructura bajo una **arquitectura relacional desacoplada por dominios**, garantizando alta cohesión funcional y bajo acoplamiento mediante interfaces bien definidas:

```
+-----------------------------------------------------------------------------------------------+
|                                  SISTEMA DE PROGRAMACIÓN ACADÉMICA                            |
+-----------------------------------------------------------------------------------------------+
|                                                                                               |
|   +------------------------------------+      +-------------------------------------------+   |
|   | ESQUEMA: programacionacademica     |      | ESQUEMA: dbo (Oferta Curricular)          |   |
|   | - Ventanas de Captura y Fases      |      | - Cursos Semestrales y Grupos             |   |
|   | - Períodos y Grupos por Unidad     |      | - Asignaturas, Créditos y Horas           |   |
|   | - Solicitudes de Cambio de Horario |<---->| - Planes de Estudio y Mallas Académicas   |   |
|   | - Solicitudes de Préstamo Docente  |      | - Matrículas y Cupos de Subgrupos         |   |
|   +------------------------------------+      +-------------------------------------------+   |
|                    ^                                                ^                         |
|                    | FKs Docente, Espacio, Tiempo                   | FKs Adscripción         |
|                    v                                                v                         |
|   +------------------------------------+      +-------------------------------------------+   |
|   | ESQUEMA: dbo (Planta Física/Tiempos|      | ESQUEMAS: dbo / proyectos (Talento Humano)|   |
|   | - Espacios Físicos, Tipos y Bloques|      | - Unidades Académicas (UAA) y Cargos      |   |
|   | - Sedes, Municipios y Departamentos|<---->| - Padrón de Personas y Contratos Docentes |   |
|   | - Grilla Semanal: Días y Horas     |      | - Escalafón Docente y Novedades           |   |
|   | - Asignación: espacio_ocupacion    |      | - Descarga por Proyección Social          |   |
|   +------------------------------------+      +-------------------------------------------+   |
|                                                                                               |
+-----------------------------------------------------------------------------------------------+
```

### 3.1 Los Cuatro Dominios Funcionales

1. **Núcleo de Programación Académica y Solicitudes (`programacionacademica` - 12 tablas):**
   Gobierna los plazos institucionales (`programacion_academica`), las ventanas de radicación de trámites (`programacion_gestion`), las agrupaciones de unidades (`grupo_uaa`, `grupo_uaa_item`), los periodos descentralizados (`periodo_unidad`) y el flujo de autorizaciones para traslados de horarios (`solicitud_cambio_horario`) y asignaciones interfacultad de profesores (`solicitud_prestamo_docente`).

2. **Oferta Académica y Cursos (`dbo` - 25 tablas):**
   Estructura la oferta semestral mediante cursos (`curso`), vinculación con planes (`curso_plan`), partición en subgrupos prácticos (`curso_cupo_subgrupo`), catálogo curricular (`asignatura`, `nucleo`, `caracter`, `formalidad`), mallas de pensum (`plan_academico`, `plan_academico_asignatura`), prelaciones y homologaciones (`prerrequisito`, `equivalencia`), y formalización de matrículas (`estudiante`, `plan_estudiante`, `matricula`, `matricula_configuracion`).

3. **Infraestructura, Espacios Físicos y Horarios (`dbo` - 15 tablas):**
   Modela la jerarquía física multicampus (`pais` -> `departamento` -> `municipio` -> `sede` -> `sub_sede` -> `bloque` -> `espacio`), su clasificación funcional (`espacio_tipo`), la matriz semanal recurrente (`dia`, `hora`, `horario`, `calendario`, `periodo`, `agenda_periodo`) y el motor de asignación física (`espacio_ocupacion`), garantizando la prevención de colisiones horarias.

4. **Estructura Institucional, Docencia y Proyección Social (`dbo` y `proyectos` - 22 tablas):**
   Modela el talento humano universitario diferenciando la persona natural (`persona`) de su contrato y adscripción laboral (`uaa_personal`) en una unidad organizativa (`uaa`), su escalafón (`docente_escalafon`), incidencias laborales (`persona_novedad`), roles de seguridad (`usuario_grupo`), investigación (`proyecto`, `persona_proyecto`) y la articulación con proyectos de extensión comunitaria (`proyecto_proyeccion_social`, `docentexproyecto_proyeccion_social`) para la descarga horaria semanal docente.

---

## 4. Índice General y Navegación de Entregables

La documentación técnica se encuentra modularizada en 10 documentos complementarios en formato Markdown estándar:

### 4.1 Diagramas Entidad-Relación en Mermaid (`erDiagram`)

| Documento | Título del Diagrama | Alcance y Contenido Técnico |
| :--- | :--- | :--- |
| [01_diagrama_arquitectonico_general.md](./01_diagrama_arquitectonico_general.md) | **Diagrama Arquitectónico General** | Vista macro de alto nivel, hubs relacionales, fronteras entre esquemas y enlaces cross-domain. |
| [02_subdiagrama_programacion_solicitudes.md](./02_subdiagrama_programacion_solicitudes.md) | **Núcleo de Programación y Solicitudes** | Detalle completo de las 12 tablas de `programacionacademica` y sus puentes hacia `dbo`. |
| [03_subdiagrama_oferta_academica.md](./03_subdiagrama_oferta_academica.md) | **Oferta Académica y Cursos** | Detalle de las 25 entidades de mallas curriculares, cursos, cupos, grupos y matrículas. |
| [04_subdiagrama_infraestructura_horarios.md](./04_subdiagrama_infraestructura_horarios.md) | **Infraestructura y Horarios** | Detalle de las 15 entidades de planta física multicampus, grilla horaria y ocupación de aulas. |
| [05_subdiagrama_institucional_docencia.md](./05_subdiagrama_institucional_docencia.md) | **Institucional, Docencia y Proyectos** | Detalle de las 22 entidades de UAA, nómina docente, escalafón y proyectos de extensión. |

### 4.2 Diccionarios de Datos y Matriz de Relaciones

| Documento | Título del Módulo | Alcance y Contenido Técnico |
| :--- | :--- | :--- |
| [06_diccionario_datos_programacion_academica.md](./06_diccionario_datos_programacion_academica.md) | **Diccionario: Programación Académica** | Especificación técnica de las 12 tablas del esquema: campos, tipos SQL, nulabilidad, reglas de negocio y máquinas de estado. |
| [07_diccionario_datos_oferta_academica.md](./07_diccionario_datos_oferta_academica.md) | **Diccionario: Oferta Académica** | Especificación técnica de las 25 entidades de cursos, asignaturas, planes, prerrequisitos y matrículas. |
| [08_diccionario_datos_infraestructura_horarios.md](./08_diccionario_datos_infraestructura_horarios.md) | **Diccionario: Infraestructura y Horarios** | Especificación técnica de las 15 entidades de espacios, sedes, bloques, franjas horarias y reservas de aula. |
| [09_diccionario_datos_institucional_docencia.md](./09_diccionario_datos_institucional_docencia.md) | **Diccionario: Institucional y Docencia** | Especificación técnica de las 22 entidades de UAA, docentes, dedicación, novedades y proyectos de extensión. |
| [10_matriz_relaciones_cardinalidad.md](./10_matriz_relaciones_cardinalidad.md) | **Matriz de Cardinalidad e Integridad** | Tabulación exhaustiva de las 201 relaciones (107 explícitas DDL + 94 implícitas) con reglas ON DELETE/ON UPDATE y opcionalidad. |

---

## 5. Guía Técnica de Visualización y Renderizado de Diagramas Mermaid

Todos los diagramas Entidad-Relación incluidos en los archivos `01` a `05` fueron desarrollados bajo la sintaxis oficial **Mermaid `erDiagram`**, cumpliendo con los estándares de compatibilidad más rigurosos:
- Sin paréntesis en tipos de datos para prevenir rupturas sintácticas en parsers web.
- Etiquetas de relación delimitadas entre comillas dobles.
- Tipificación explícita de roles de clave (`PK`, `FK`, `UK`).

### Métodos de Visualización Recomendados

1. **Visores Nativos de Markdown:**
   - **GitHub / GitLab / Azure DevOps:** Renderizan automáticamente los bloques ```mermaid directamente en el navegador sin complementos.
   - **VS Code:** Instalar la extensión oficial *Markdown Preview Mermaid Support* (Matt Bierner) o *Mermaid Preview*.
   - **Obsidian / Typora:** Soporte nativo incorporado por defecto.

2. **Herramientas en Línea (Live Editor):**
   - Puede copiar el contenido de cualquier bloque ```mermaid y pegarlo en [Mermaid Live Editor](https://mermaid.live) para generar descargas en formato SVG de alta resolución o PNG vectorial.

3. **Exportación Automatizada por Línea de Comandos (CLI):**
   - Con Node.js instalado, ejecute `@mermaid-js/mermaid-cli` (`mmdc`):
     ```powershell
     npx @mermaid-js/mermaid-cli -i docs/modelo_er/01_diagrama_arquitectonico_general.md -o docs/modelo_er/01_diagrama.svg
     ```

---

## 6. Procedimiento de Auditoría y Verificación Automatizada

El proyecto cuenta con un conjunto de pruebas automatizadas en Python (`tests/test_data_dictionary.py`) que valida rigurosamente:
1. Existencia y completitud de los 10 archivos de documentación y este `README.md`.
2. Cobertura del 100% de las 12 tablas de `programacionacademica` en el archivo `06`.
3. Cobertura del 100% de las 25 tablas de Oferta Académica en el archivo `07`.
4. Cobertura del 100% de las 15 tablas de Infraestructura en el archivo `08`.
5. Cobertura del 100% de las 22 tablas Institucionales y Proyectos en el archivo `09`.
6. Presencia de al menos 200 relaciones documentadas en la matriz de cardinalidad `10`.
7. Validez y resolución de todos los enlaces relativos Markdown en `README.md`.

Para ejecutar la suite de verificación:
```powershell
pytest tests/test_data_dictionary.py -v
```
