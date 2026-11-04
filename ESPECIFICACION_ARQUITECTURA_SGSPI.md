# Especificación de Arquitectura de Software y Análisis de Sistemas: Migración del SGSPI (Universidad Surcolombiana) a Plataforma Web/Móvil

**Organización:** Universidad Surcolombiana (USCO)  
**Sistema Objetivo:** Sistema de Gestión de Seguridad y Privacidad de la Información (SGSPI)  
**Motor de Base de Datos Objetivo:** Microsoft SQL Server 2019 (Compatibilidad 150, Esquema `sgspi` integrado con `dbo` de `academia3000`)  
**Estándar de Nomenclatura de Base de Datos (Convención Institucional USCO):**
1. **Llaves Primarias y Foráneas con sufijo `_codigo`:** Cero uso de `_id`; todas las llaves primarias y foráneas terminan en `_codigo` (ej. `pev_codigo`, `pri_codigo`, `aci_codigo`, `eia_codigo`, `plt_codigo`, `uaa_codigo`, `per_codigo`, `sed_codigo`, `car_codigo`).
2. **Prefijo Acrónimo de 3 Letras por Tabla (`<acr>_`):** Cada tabla posee un acrónimo único de 3 letras y todas sus columnas inician con dicho acrónimo (ej. `aci_nombre_activo`, `aci_valor_confidencialidad`, `eia_fuente_generadora`, `plt_estrategia_tratamiento`).

**Formatos Controlados Integrados (Orden de Llenado 1 → 5):**
1. `ES-GSPI-MR-01` — Matriz de Contexto de la Organización (DOFA por Proceso - Ej. Gestión de Tecnologías)
2. `CONSOLIDADO DOFA` — Contexto Consolidado Institucional (`D1..D124`, `F1..F30`, `A1..A101`, `O1..O37`)
3. `ES-GSPI-MR-03` — Matriz de Identificación de Partes Interesadas Pertinentes SGSPI (v4)
4. `ES-GSPI-MR-05` — Matriz de Inventario y Clasificación de Activos de la Información
5. `ES-GSPI-MR-06` — Matriz de Riesgos y Oportunidades (Enfoque Basado en Activos), Plan de Tratamiento y Declaración de Aplicabilidad (SoA ISO 27001:2022 / ISO 27701:2025)

---

## Tabla de Contenido
1. [Flujos de Trabajo (Orden de Llenado 1 → 5)](#1-flujos-de-trabajo-orden-de-llenado-1--5)
2. [Diccionario de Datos Extraído (Con Acrónimos y `_codigo`)](#2-diccionario-de-datos-extraído-con-acrónimos-y-_codigo)
3. [Entidades Principales y Mapa de Acrónimos (`sgspi` + `dbo`)](#3-entidades-principales-y-mapa-de-acrónimos-sgspi--dbo)
4. [Modelo Entidad-Relación (ER) Normalizado en 3NF](#4-modelo-entidad-relación-er-normalizado-en-3nf)
5. [Campos Calculados en Tiempo de Ejecución (Microsoft SQL Server 2019)](#5-campos-calculados-en-tiempo-de-ejecución-microsoft-sql-server-2019)
6. [Reglas de Negocio y Validaciones](#6-reglas-de-negocio-y-validaciones)
7. [Actores Actuales del Sistema](#7-actores-actuales-del-sistema)
8. [Ciclo de Vida del Registro](#8-ciclo-de-vida-del-registro)
9. [Casos de Uso Principales por Rol (CRUD, Aprobaciones y Reportería)](#9-casos-de-uso-principales-por-rol-crud-aprobaciones-y-reportería)
10. [Máquina de Estados para el Registro Principal](#10-máquina-de-estados-para-el-registro-principal)
11. [Matriz Básica de Permisos (RBAC) y Seguridad](#11-matriz-básica-de-permisos-rbac-y-seguridad)
12. [Script DDL T-SQL de Producción para Microsoft SQL Server 2019](#12-script-ddl-t-sql-de-producción-para-microsoft-sql-server-2019)

---

## 1. Flujos de Trabajo (Orden de Llenado 1 → 5)

El proceso operativo del SGSPI sigue una cadena de valor donde la salida de cada matriz constituye la entrada obligatoria del siguiente paso:

```mermaid
flowchart LR
    subgraph Fase1["Paso 1 y 2: Contexto Organizacional (ISO 27001 Cl. 4.1)"]
        D1["1. DOFA por Proceso<br/>(ES-GSPI-MR-01)<br/>acf_analisis_contexto_factor"]
        D2["2. Consolidado DOFA<br/>(vw_consolidado_dofa)<br/>D1..D124, F1..F30, A1..A101, O1..O37"]
        D1 -->|"Vista SQL agregada<br/>de los 21 procesos"| D2
    end

    subgraph Fase2["Paso 3: Partes Interesadas (ISO 27001 Cl. 4.2)"]
        D3["3. Matriz Partes Interesadas<br/>(ES-GSPI-MR-03)<br/>41 Partes [pai] / 169 Requisitos [rpi]"]
    end

    subgraph Fase3["Paso 4: Gestión de Activos (ISO 27001 Anexo A: A.5.9 / A.5.12)"]
        D4["4. Inventario y Clasificación<br/>de Activos (ES-GSPI-MR-05)<br/>511 Activos [aci] + 17 Sistemas [sif]"]
    end

    subgraph Fase4["Paso 5: Gestión de Riesgos, Tratamiento y SoA (Cl. 6.1 / 8.2 / 8.3)"]
        D5A["5.1 Identificación y Valoración<br/>evento_incertidumbre_activo [eia]<br/>Matriz 5x5 (RA / OA)"]
        D5B["5.2 Plan de Tratamiento<br/>plan_tratamiento [plt] + Actividades [act]<br/>+ Controles [crn]"]
        D5C["5.3 Declaración de Aplicabilidad<br/>evaluacion_aplicabilidad_control [eac]<br/>93 ISO 27001 + 71 ISO 27701"]
        D5A -->|"Escenarios en Zona<br/>Moderada, Alta o Extrema"| D5B
        D5B -->|"Trazabilidad de Controles<br/>y Evidencias"| D5C
    end

    %% Enlaces inter-subgrafos con etiquetas entre comillas para escapar corchetes
    D2 -->|"Catálogo Maestro<br/>pri_proceso_institucional"| D3
    D3 -->|"Procesos [pri], UAA [uaa]<br/>y Cargos [car]"| D4
    D4 -->|"Activos Primarios y Soporte<br/>+ Valoración CID y PII"| D5A
```

---

## 2. Diccionario de Datos Extraído (Con Acrónimos y `_codigo`)

### 2.1 Mapeo de Columnas Excel $\rightarrow$ Columnas con Acrónimo en SQL Server 2019

#### A. Documentos 1 y 2: `DOFA por Proceso (ES-GSPI-MR-01)` y `CONSOLIDADO DOFA`
| Columna en Excel | Tabla (`[acr]`) y Columna en SQL Server 2019 | Tipo T-SQL | Ejemplo Real del Dataset |
| :--- | :--- | :--- | :--- |
| `VIGENCIA` | `periodo_vigencia.pev_anio` (`pev_codigo`) | `SMALLINT` | `2025` |
| `TIPO DE PROCESO` | `tipo_proceso_catalogo.tpr_nombre` (`tpr_codigo`) | `NVARCHAR(50)` | `ESTRATÉGICO`, `APOYO`, `EVALUACIÓN`, `MISIONAL` |
| `PROCESO` | `proceso_institucional.pri_nombre` (`pri_codigo`) | `NVARCHAR(150)` | `SISTEMA GESTIÓN DE INFORMACION, TECNOLOGÍAS Y CONTROL DOCUMENTAL` |
| `VARIABLE` | `factor_entorno_catalogo.fec_nombre_factor` (`fec_codigo`) | `NVARCHAR(100)` | Interno: `Gobernanza`, `Cultura organizacional` / Externo: `Aspecto Tecnológico`, `Aspecto Normativo` |
| *(Código D1..O37)* | `vw_consolidado_dofa.acf_codigo_autogenerado` | Calculado (`ROW_NUMBER`) | `D1`..`D124`, `F1`..`F30`, `A1`..`A101`, `O1`..`O37` |
| `DEBILIDAD` / `FORTALEZA` / `AMENAZA` / `OPORTUNIDAD` | `analisis_contexto_factor.acf_naturaleza_factor` + `acf_descripcion_situacion` | `NVARCHAR(15)` + `NVARCHAR(MAX)` | `DEBILIDAD`: `"Múltiples equipos de soporte, desarrollo y redes con roles no unificados."` |
| `PRIORIZACIÓN` | `analisis_contexto_factor.acf_nivel_prioridad` | `NVARCHAR(10)` | `Alta`, `Media`, `Baja` |
| `IMPACTO SOBRE EL SGSPI` | `analisis_contexto_factor.acf_impacto_sistema_gestion` | `NVARCHAR(MAX)` | `"Riesgo de brechas de coordinación y duplicidad de controles."` |
| `ACCIÓN SUGERIDA` | `analisis_contexto_factor.acf_accion_propuesta` | `NVARCHAR(MAX)` | `"Definir claramente roles y responsabilidades en seguridad de la información."` |

#### B. Documento 3: `ES-GSPI-MR-03 MATRIZ DE PARTES INTERESADAS SGSPI v4`
| Columna en Excel | Tabla (`[acr]`) y Columna en SQL Server 2019 | Tipo T-SQL | Ejemplo Real del Dataset |
| :--- | :--- | :--- | :--- |
| `PARTES INTERESADAS` | `parte_interesada.pai_nombre` (`pai_codigo`) | `NVARCHAR(150)` | `Consejo Superior`, `Estudiantes`, `Ministerio de Educación Nacional- MEN`, `Hackers individuales` |
| `CATEGORIA DE LAS PARTES INTERESADAS` | `parte_interesada.pai_origen` | `NVARCHAR(15)` | `Interna`, `Externa` |
| `PREG.` | `requisito_parte_interesada.rpi_referencia_cuestionario` | `NVARCHAR(30)` | `6-7-8`, `N/A` |
| `INTERÉS (REQUISITOS) NECESIDADES Y EXPECTATIVAS` | `requisito_parte_interesada.rpi_necesidad_expectativa` | `NVARCHAR(MAX)` | `"Garantizar la confidencialidad e integridad de la información contenida en los audios..."` |
| `PODER` / `INTERÉS` | `requisito_parte_interesada.rpi_nivel_poder`, `rpi_nivel_interes` | `NVARCHAR(10)` | `Alto` \| `Medio` \| `Bajo` |
| `CLASIFICACIÓN SEGÚN EL IMPACTO` | `requisito_parte_interesada.rpi_clasificacion_impacto` | Columna Calculada `AS (...)` | `CUIDADO "Tratar como requisito legal y otros requisitos"` |
| `ESTADO DE CUMPLIMIENTO` | `requisito_parte_interesada.rpi_nivel_cumplimiento` | `NVARCHAR(10)` | `Alto`, `Medio`, `Bajo` |
| `PRIORIDAD PARA LA TOMA DE ACCIONES` | `requisito_parte_interesada.rpi_prioridad_accion` | Columna Calculada `AS (...)` | `Prioridad alta`, `Prioridad media`, `Prioridad baja` |
| `HERRAMIENTA DE SEGUIMIENTO` | `requisito_parte_interesada.rpi_mecanismo_seguimiento` | `NVARCHAR(255)` | `Capacitaciones y SIAC`, `Uso de Plataformas del MEN` |
| `AFECTACIÓN A PROCESOS` *(21 columnas)* | `requisito_proceso_afectado (rpa_codigo, rpi_codigo, pri_codigo)` | Tabla Puente N:M | Asocia cada requisito `rpi_codigo` con los procesos `pri_codigo` impactados |

#### C. Documento 4: `ES-GSPI-MR-05 MATRIZ DE INVENTARIO Y CLASIFICACIÓN DE ACTIVOS`
| Columna en Excel | Tabla (`[acr]`) y Columna en SQL Server 2019 | Tipo T-SQL | Ejemplo Real del Dataset |
| :--- | :--- | :--- | :--- |
| `ID ACTIVO INFORMACION` | `activo_informacion.aci_codigo` + `aci_codigo_inventario` | `INT IDENTITY` + `NVARCHAR(30)` | `1` a `511` |
| `Nombre del Activo de Información` | `activo_informacion.aci_nombre_activo` | `NVARCHAR(255)` | `Sistema Financiero (Linix)`, `BD Académica3000`, `Historias Laborales` |
| `Tipo` / `Clase` / `Descripción del Activo` | `tipo_activo_catalogo (tac_codigo, tac_categoria_iso27005, tac_tipo_activo, tac_subtipo_activo)` | `SMALLINT (FK)` | `Primario` $\rightarrow$ `Información` $\rightarrow$ `Aplicaciones Estandar del Negocio` |
| `Proceso al que pertenece` | `activo_proceso (acp_codigo, aci_codigo, pri_codigo)` | Tabla Puente N:M | `FORMACIÓN`, `GESTIÓN FINANCIERA Y DE RECURSOS FÍSICOS` |
| `Dependencia` | `activo_informacion.uaa_codigo` $\rightarrow$ `dbo.uaa (uaa_codigo)` | `INT (FK a dbo.uaa)` | `Oficina Asesora Jurídica`, `Centro de Información, Tecnología y Control documental` |
| `Sede` | `activo_sede (acs_codigo, aci_codigo, sed_codigo, sus_codigo)` $\rightarrow$ `dbo.sede` / `dbo.sub_sede` | Tabla Puente N:M | `Sede Central`, `Sede Postgrados`, `Todas las sedes` |
| `Propietario del Activo` / `Custodio del Activo` | `activo_responsable (acr_codigo, aci_codigo, car_codigo, acr_tipo_responsabilidad)` $\rightarrow$ `dbo.cargo` | Tabla Puente N:M | `PROPIETARIO`: `Vicerrector Académico` \| `CUSTODIO`: `Director Registro y Control` |
| `Tipo de Información Ley 1712 de 2014` | `activo_informacion.aci_clasificacion_transparencia` | `NVARCHAR(20)` | `PÚBLICA`, `CLASIFICADA`, `RESERVADA`, `NO CLASIFICADA` |
| `¿Contiene datos personales (Ley 1581)?` | `activo_informacion.aci_contiene_datos_personales` | `BIT` | `1 (SI)`, `0 (NO)` |
| `Confidencialidad` / `Integridad` / `Disponibilidad` | `aci_valor_confidencialidad`, `aci_valor_integridad`, `aci_valor_disponibilidad` | `TINYINT (3, 2, 1)` | `3 (Alta)`, `2 (Media)`, `1 (Baja)` |
| `calculo criticidad` / `Criticidad` | `aci_puntaje_criticidad` y `aci_nivel_criticidad` | Columnas Calculadas `PERSISTED` | `9` $\rightarrow$ `Alta` \| `6` $\rightarrow$ `Media` \| `3` $\rightarrow$ `Baja` |
| `IMPACTO SOCIAL` / `ECONÓMICO` / `AMBIENTAL` (ICC) | `aci_supera_umbral_social_icc`, `aci_supera_umbral_economico_icc`, `aci_supera_umbral_ambiental_icc` | `BIT` | `0 (NO)` / `1 (SI)` $\rightarrow$ calcula `aci_es_infraestructura_critica_icc` |

#### D. Documento 5: `ES-GSPI-MR-06 RIESGOS, TRATAMIENTO Y SOA (ISO 27001 / 27701)`
| Sub-Matriz | Tabla (`[acr]`) en SQL Server 2019 | Columnas Clave con Acrónimo y `_codigo` |
| :--- | :--- | :--- |
| **5.1 Identificación y Valoración** | `sgspi.evento_incertidumbre_activo` (`[eia]`) | `eia_codigo`, `pev_codigo`, `eia_identificador_evento` (`RA-01..15`, `OA-01..09`), `eia_naturaleza_evento`, `pri_codigo`, `eia_aci_codigo_primario`, `eia_aci_codigo_soporte`, `eia_tipo_componente_afectado`, `eia_fuente_generadora`, `eia_controles_existentes`, `eia_condicion_vulnerabilidad`, `eia_efecto_consecuencia`, `eia_escenario_operacional`, `eia_epr_codigo_inherente`, `eia_eim_codigo_inherente`, `eia_estado_registro`. |
| **5.2 Plan de Tratamiento** | `sgspi.plan_tratamiento` (`[plt]`) + `sgspi.actividad_tratamiento` (`[act]`) + `sgspi.seguimiento_actividad` (`[sga]`) | `plt_codigo`, `eia_codigo`, `plt_estrategia_tratamiento`, `plt_justificacion_estrategia`, `plt_epr_codigo_residual_meta`, `plt_eim_codigo_residual_meta`, `plt_fecha_inicio`, `plt_fecha_fin`, `plt_recursos_humanos_tecnicos`, `plt_recursos_economicos_desc`, `plt_presupuesto_estimado_cop`, `plt_restricciones_limitaciones`, `plt_nombre_indicador_kpi`, `plt_es_tratamiento_eficaz`, `act_codigo`, `sga_codigo`. |
| **5.3 Controles y SoA ISO 27001 / 27701** | `sgspi.control_referencia_normativa` (`[crn]`) + `sgspi.evaluacion_aplicabilidad_control` (`[eac]`) | `crn_codigo`, `crn_estandar_normativo`, `crn_rol_privacidad_pii`, `crn_identificador_control`, `crn_nombre_control`, `crn_objetivo_requisito`, `eac_codigo`, `eac_es_aplicable`, `eac_justificacion_aplicabilidad`, `eac_documento_soporte_normativo`, `car_codigo`, `eac_frecuencia_revision`, `eac_evidencia_objetiva_esperada`, `eac_estado_implementacion`. |

---

## 3. Entidades Principales y Mapa de Acrónimos (`sgspi` + `dbo`)

### 3.1 Tablas Maestras Reutilizadas del Esquema Corporativo `[dbo]` (`academia3000`)
| Acrónimo | Tabla en `[dbo]` | Llave Primaria | Rol en el SGSPI |
| :---: | :--- | :--- | :--- |
| **`sed`** | `dbo.sede` | `sed_codigo` (`INT`) | Sedes principales de la USCO (Neiva, Pitalito, Garzón, La Plata). |
| **`sus`** | `dbo.sub_sede` | `sus_codigo` (`INT`) | Campus físicos (Sede Central, Sede Postgrados, Sede Salud/Quirinal). |
| **`esp`** | `dbo.espacio` | `esp_codigo` (`INT`) | Espacios físicos, centros de cómputo, cuartos de cableado y oficinas. |
| **`uaa`** | `dbo.uaa` | `uaa_codigo` (`INT`) | Unidades Académico-Administrativas (Facultades, Oficinas, Vicerrectorías, Centros). |
| **`car`** | `dbo.cargo` | `car_codigo` (`INT`) | Catálogo oficial de cargos institucionales (Propietarios, Custodios, Líderes). |
| **`per`** | `dbo.persona` | `per_codigo` (`INT`) | Maestro único de personas (Funcionarios, Docentes, Contratistas). |
| **`gru`** | `dbo.grupo` | `gru_codigo` (`INT`) | Grupos/Roles de seguridad RBAC institucionales. |
| **`usg`** | `dbo.usuario_grupo` | `usg_codigo` (`INT`) | Asignación de usuarios a grupos RBAC por UAA (Row-Level Security). |

### 3.2 Mapa de las 25 Tablas Propias del Esquema `[sgspi]` y sus Acrónimos
| # | Acrónimo | Tabla en `[sgspi]` | Llave Primaria | Prefijo de Columnas |
| :-: | :---: | :--- | :--- | :--- |
| 1 | **`pev`** | `sgspi.periodo_vigencia` | `pev_codigo` | `pev_anio`, `pev_fecha_apertura`, `pev_estado_vigencia`... |
| 2 | **`fdv`** | `sgspi.formato_documental_version` | `fdv_codigo` | `fdv_dominio_funcional`, `fdv_codigo_formato`, `fdv_numero_version`... |
| 3 | **`tpr`** | `sgspi.tipo_proceso_catalogo` | `tpr_codigo` | `tpr_identificador`, `tpr_nombre`, `tpr_descripcion` |
| 4 | **`pri`** | `sgspi.proceso_institucional` | `pri_codigo` | `pri_identificador`, `pri_nombre`, `pri_uaa_codigo_lider`... |
| 5 | **`pru`** | `sgspi.proceso_uaa` | `pru_codigo` | `pri_codigo`, `uaa_codigo`, `pru_es_responsable_principal` |
| 6 | **`fec`** | `sgspi.factor_entorno_catalogo` | `fec_codigo` | `fec_nombre_factor`, `fec_ambito_entorno`, `fec_descripcion` |
| 7 | **`acf`** | `sgspi.analisis_contexto_factor` | `acf_codigo` | `acf_ambito_entorno`, `acf_naturaleza_factor`, `acf_nivel_prioridad`... |
| 8 | **`pai`** | `sgspi.parte_interesada` | `pai_codigo` | `pai_nombre`, `pai_origen`, `pai_descripcion_rol`, `pai_esta_activa` |
| 9 | **`rpi`** | `sgspi.requisito_parte_interesada` | `rpi_codigo` | `rpi_necesidad_expectativa`, `rpi_nivel_poder`, `rpi_nivel_interes`... |
| 10 | **`rpa`** | `sgspi.requisito_proceso_afectado` | `rpa_codigo` | `rpi_codigo`, `pri_codigo`, `rpa_fecha_registro` |
| 11 | **`tac`** | `sgspi.tipo_activo_catalogo` | `tac_codigo` | `tac_categoria_iso27005`, `tac_tipo_activo`, `tac_subtipo_activo` |
| 12 | **`cet`** | `sgspi.causal_excepcion_transparencia`| `cet_codigo` | `cet_nivel_reserva_aplicable`, `cet_numeral_causal`, `cet_descripcion_causal` |
| 13 | **`aci`** | `sgspi.activo_informacion` | `aci_codigo` | `aci_nombre_activo`, `aci_valor_confidencialidad`, `aci_puntaje_criticidad`... |
| 14 | **`acp`** | `sgspi.activo_proceso` | `acp_codigo` | `aci_codigo`, `pri_codigo` |
| 15 | **`acs`** | `sgspi.activo_sede` | `acs_codigo` | `aci_codigo`, `sed_codigo`, `sus_codigo` |
| 16 | **`acr`** | `sgspi.activo_responsable` | `acr_codigo` | `aci_codigo`, `car_codigo`, `uaa_codigo`, `acr_tipo_responsabilidad` |
| 17 | **`sif`** | `sgspi.sistema_informacion_ficha` | `sif_codigo` | `sif_nombre_sistema`, `sif_modalidad_desarrollo`, `sif_fabricante_proveedor` |
| 18 | **`msi`** | `sgspi.modulo_sistema_informacion` | `msi_codigo` | `sif_codigo`, `msi_nombre_modulo`, `msi_usuarios_objetivo` |
| 19 | **`epr`** | `sgspi.escala_probabilidad` | `epr_codigo` | `epr_codigo_letra`, `epr_nombre_nivel`, `epr_frecuencia_referencia` |
| 20 | **`eim`** | `sgspi.escala_impacto` | `eim_codigo` | `eim_nombre_impacto_negativo`, `eim_nombre_impacto_positivo` |
| 21 | **`mvr`** | `sgspi.matriz_valoracion_riesgo` | `(epr_codigo, eim_codigo)` | `mvr_codigo_posicion`, `mvr_codigo_zona`, `mvr_nivel_valoracion` |
| 22 | **`eia`** | `sgspi.evento_incertidumbre_activo` | `eia_codigo` | `eia_identificador_evento`, `eia_naturaleza_evento`, `eia_fuente_generadora`... |
| 23 | **`plt`** | `sgspi.plan_tratamiento` | `plt_codigo` | `plt_estrategia_tratamiento`, `plt_fecha_inicio`, `plt_fecha_fin`... |
| 24 | **`act`** / **`sga`**| `actividad_tratamiento` / `seguimiento_actividad` | `act_codigo` / `sga_codigo` | `act_descripcion_actividad`, `act_porcentaje_avance` / `sga_descripcion_avance`... |
| 25 | **`crn`** / **`ptc`** / **`eac`** / **`bas`** | `control_referencia_normativa`, `plan_tratamiento_control`, `evaluacion_aplicabilidad_control`, `bitacora_auditoria_sistema` | `crn_codigo`, `ptc_codigo`, `eac_codigo`, `bas_codigo` | `crn_identificador_control`, `eac_estado_implementacion`, `bas_accion_ejecutada`... |

---

## 4. Modelo Entidad-Relación (ER) Normalizado en 3NF

```mermaid
erDiagram
    TIPO_PROCESO_CATALOGO ||--o{ PROCESO_INSTITUCIONAL : "tpr_codigo"
    DBO_CARGO ||--o{ PROCESO_INSTITUCIONAL : "pri_car_codigo_lider"
    DBO_UAA ||--o{ PROCESO_INSTITUCIONAL : "pri_uaa_codigo_lider"
    PROCESO_INSTITUCIONAL ||--o{ PROCESO_UAA : "pri_codigo"
    DBO_UAA ||--o{ PROCESO_UAA : "uaa_codigo"
    DBO_SEDE ||--o{ DBO_SUB_SEDE : "sed_codigo"
    DBO_SEDE ||--o{ DBO_UAA : "sed_codigo"

    PERIODO_VIGENCIA ||--o{ FORMATO_DOCUMENTAL_VERSION : "pev_codigo"
    PERIODO_VIGENCIA ||--o{ ANALISIS_CONTEXTO_FACTOR : "pev_codigo"
    PROCESO_INSTITUCIONAL ||--o{ ANALISIS_CONTEXTO_FACTOR : "pri_codigo"
    FACTOR_ENTORNO_CATALOGO ||--o{ ANALISIS_CONTEXTO_FACTOR : "fec_codigo"
    DBO_PERSONA ||--o{ ANALISIS_CONTEXTO_FACTOR : "acf_per_codigo_creador"

    PARTE_INTERESADA ||--o{ REQUISITO_PARTE_INTERESADA : "pai_codigo"
    PERIODO_VIGENCIA ||--o{ REQUISITO_PARTE_INTERESADA : "pev_codigo"
    REQUISITO_PARTE_INTERESADA ||--o{ REQUISITO_PROCESO_AFECTADO : "rpi_codigo"
    PROCESO_INSTITUCIONAL ||--o{ REQUISITO_PROCESO_AFECTADO : "pri_codigo"

    TIPO_ACTIVO_CATALOGO ||--o{ ACTIVO_INFORMACION : "tac_codigo"
    CAUSAL_EXCEPCION_TRANSPARENCIA ||--o{ ACTIVO_INFORMACION : "cet_codigo"
    DBO_UAA ||--o{ ACTIVO_INFORMACION : "uaa_codigo"
    DBO_ESPACIO ||--o{ ACTIVO_INFORMACION : "esp_codigo"
    ACTIVO_INFORMACION ||--o{ ACTIVO_PROCESO : "aci_codigo"
    PROCESO_INSTITUCIONAL ||--o{ ACTIVO_PROCESO : "pri_codigo"
    ACTIVO_INFORMACION ||--o{ ACTIVO_SEDE : "aci_codigo"
    DBO_SEDE ||--o{ ACTIVO_SEDE : "sed_codigo"
    DBO_SUB_SEDE ||--o{ ACTIVO_SEDE : "sus_codigo"
    ACTIVO_INFORMACION ||--o{ ACTIVO_RESPONSABLE : "aci_codigo"
    DBO_CARGO ||--o{ ACTIVO_RESPONSABLE : "car_codigo"
    ACTIVO_INFORMACION ||--o| SISTEMA_INFORMACION_FICHA : "aci_codigo"
    SISTEMA_INFORMACION_FICHA ||--o{ MODULO_SISTEMA_INFORMACION : "sif_codigo"

    PERIODO_VIGENCIA ||--o{ EVENTO_INCERTIDUMBRE_ACTIVO : "pev_codigo"
    PROCESO_INSTITUCIONAL ||--o{ EVENTO_INCERTIDUMBRE_ACTIVO : "pri_codigo"
    ACTIVO_INFORMACION ||--o{ EVENTO_INCERTIDUMBRE_ACTIVO : "eia_aci_codigo_primario"
    ACTIVO_INFORMACION ||--o{ EVENTO_INCERTIDUMBRE_ACTIVO : "eia_aci_codigo_soporte"
    MATRIZ_VALORACION_RIESGO ||--o{ EVENTO_INCERTIDUMBRE_ACTIVO : "eia_epr_eim_inherente"
    DBO_PERSONA ||--o{ EVENTO_INCERTIDUMBRE_ACTIVO : "eia_per_codigo_creador"

    EVENTO_INCERTIDUMBRE_ACTIVO ||--|| PLAN_TRATAMIENTO : "eia_codigo"
    MATRIZ_VALORACION_RIESGO ||--o{ PLAN_TRATAMIENTO : "plt_epr_eim_residual_meta"
    PLAN_TRATAMIENTO ||--o{ ACTIVIDAD_TRATAMIENTO : "plt_codigo"
    DBO_CARGO ||--o{ ACTIVIDAD_TRATAMIENTO : "car_codigo"
    ACTIVIDAD_TRATAMIENTO ||--o{ SEGUIMIENTO_ACTIVIDAD : "act_codigo"
    DBO_PERSONA ||--o{ SEGUIMIENTO_ACTIVIDAD : "per_codigo"
    PLAN_TRATAMIENTO ||--o{ PLAN_TRATAMIENTO_CONTROL : "plt_codigo"
    CONTROL_REFERENCIA_NORMATIVA ||--o{ PLAN_TRATAMIENTO_CONTROL : "crn_codigo"

    PERIODO_VIGENCIA ||--o{ EVALUACION_APLICABILIDAD_CONTROL : "pev_codigo"
    CONTROL_REFERENCIA_NORMATIVA ||--o{ EVALUACION_APLICABILIDAD_CONTROL : "crn_codigo"
    DBO_PERSONA ||--o{ BITACORA_AUDITORIA_SISTEMA : "per_codigo"
    DBO_GRUPO ||--o{ BITACORA_AUDITORIA_SISTEMA : "gru_codigo"
```

---

## 5. Campos Calculados en Tiempo de Ejecución (Microsoft SQL Server 2019)

| # | Documento | Campo Calculado con Acrónimo | Implementación Nativa en SQL Server 2019 |
| :-: | :--- | :--- | :--- |
| **1** | **Doc 2** (`Consolidado DOFA`) | `acf_codigo_autogenerado` (`D1..D124`, `F1..F30`, `A1..A101`, `O1..O37`) | Vista **`sgspi.vw_consolidado_dofa`** usando `CONCAT(LEFT(acf_naturaleza_factor, 1), ROW_NUMBER() OVER (PARTITION BY pev_codigo, acf_naturaleza_factor ORDER BY tpr_codigo, pri_codigo, acf_codigo))`. |
| **2** | **Doc 3** (`ES-GSPI-MR-03`) | `rpi_clasificacion_impacto` y `rpi_prioridad_accion` | **Columnas calculadas nativas** en `sgspi.requisito_parte_interesada` mediante expresiones `CASE WHEN` sobre `(rpi_nivel_poder, rpi_nivel_interes)` y `rpi_nivel_cumplimiento`. |
| **3** | **Doc 4** (`ES-GSPI-MR-05`) | `aci_nivel_confidencialidad`, `aci_nivel_integridad`, `aci_nivel_disponibilidad`, `aci_puntaje_criticidad` (`3..9`), `aci_nivel_criticidad` y `aci_es_infraestructura_critica_icc` | **Columnas calculadas `PERSISTED`** en `sgspi.activo_informacion` a partir de `aci_valor_confidencialidad + aci_valor_integridad + aci_valor_disponibilidad` y evaluación booleana de los 3 umbrales ICC. |
| **4** | **Doc 4** (`ES-GSPI-MR-05`) | Tabla Dinámica Superior de Conteo de Activos por Categoría, Tipo y Criticidad | Vista **`sgspi.vw_resumen_activos_criticidad`** utilizando `GROUP BY GROUPING SETS ((tac_categoria_iso27005, tac_tipo_activo), (tac_categoria_iso27005), ())`. |
| **5** | **Doc 5** (`ES-GSPI-MR-06`) | `eia_detalle_del_riesgo`, `eia_resultado_actual`, `plt_resultado_esperado`, `crn_controles_iso27001` y `crn_controles_iso27701` | Vista **`sgspi.vw_matriz_tratamiento_riesgos`** usando `JOIN` contra `matriz_valoracion_riesgo` y la función nativa **`STRING_AGG(...) WITHIN GROUP (ORDER BY crn_codigo)`**. |

---

## 6. Reglas de Negocio y Validaciones

### 6.1 Contexto y Matriz DOFA (Documentos 1 y 2)
- **RN-DOFA-01 y 02 (Coherencia Ámbito vs. Naturaleza):** En `sgspi.analisis_contexto_factor`, el constraint `CK_acf_ambito_naturaleza` exige que si `acf_ambito_entorno = 'INTERNO'`, `acf_naturaleza_factor` sea exclusivamente `'DEBILIDAD'` o `'FORTALEZA'`; si es `'EXTERNO'`, sea `'AMENAZA'` u `'OPORTUNIDAD'`.
- **RN-DOFA-03 (Obligatoriedad de Acción Propuesta en Prioridad Alta):** El constraint `CK_acf_prioridad_alta_campos` impide que un factor con `acf_nivel_prioridad = 'Alta'` avance de `'BORRADOR'` si `acf_impacto_sistema_gestion` o `acf_accion_propuesta` están vacíos.

### 6.2 Partes Interesadas (`ES-GSPI-MR-03` - Documento 3)
- **RN-PI-01 (Cobertura de Procesos):** Si `rpi_clasificacion_impacto` comienza por `'CUIDADO'`, la capa de aplicación exige al menos un registro asociado en `sgspi.requisito_proceso_afectado` (`rpa_codigo`) y el campo `rpi_mecanismo_seguimiento` diligenciado.

### 6.3 Inventario y Clasificación de Activos (`ES-GSPI-MR-05` - Documento 4)
- **RN-ACT-01 (Integridad Taxonómica ISO 27005):** El constraint `CK_tac_categoria_coherencia` garantiza que `Primario` solo admita `Información` y `Procesos y Actividades del Negocio`, y `Soporte` solo admita `Hardware`, `Software`, `Red`, `Personal`, `Sitio`, `Estructura de la organización` y `Ubicación`.
- **RN-ACT-02 (Transparencia y Reserva Legal):** El constraint `CK_aci_reserva_confidencialidad` impide que un activo con `aci_clasificacion_transparencia = 'RESERVADA'` tenga `aci_valor_confidencialidad = 1 (Baja)`. Si es `CLASIFICADA` o `RESERVADA`, requiere `cet_codigo` no nulo.
- **RN-ACT-03 (Protección de Datos Personales):** El constraint `CK_aci_pii_privados_no_publico_bajo` impide clasificar un activo como `PÚBLICA` con confidencialidad `Baja (1)` si `aci_contiene_datos_personales = 1` y contiene datos `'PRIVADOS'` o `aci_contiene_datos_menores = 1`.
- **RN-ACT-04 (Alerta de Infraestructura Crítica Cibernética - ICC):** Cuando la columna calculada `aci_es_infraestructura_critica_icc = 1`, el sistema emite alerta obligatoria de notificación a las autoridades nacionales de ciberseguridad.
- **RN-ACT-05 (Propietario y Custodio Obligatorios):** Todo activo en `aci_estado_registro = 'VIGENTE'` debe tener al menos un `'PROPIETARIO'` y un `'CUSTODIO'` en `sgspi.activo_responsable` (`acr_codigo`).

### 6.4 Riesgos, Tratamiento y Controles SoA (`ES-GSPI-MR-06` - Documento 5)
- **RN-RSG-01 (Exclusión Mutua y Prefijo):** El constraint `CK_eia_naturaleza_prefijo` valida que todo `'RIESGO'` lleve prefijo `'RA-%'` y toda `'OPORTUNIDAD'` lleve prefijo `'OA-%'`.
- **RN-RSG-02 (Tipología de Activos Primario vs. Soporte):** `eia_aci_codigo_primario` debe pertenecer a categoría `'Primario'` y `eia_aci_codigo_soporte` a categoría `'Soporte'`.
- **RN-RSG-03 (Gobernanza de Zonas Altas y Extremas):** Si la valoración inherente o residual cae en zona `'A'` (Alto) o `'E'` (Extremo) (`mvr_requiere_aprobacion_comite = 1`), se exige la firma de `eia_per_codigo_aprobador_comite` con rol `COMITE_DIRECCION`.
- **RN-RSG-04 (Coherencia Matemática del Riesgo Residual Meta):** En mitigación de riesgos negativos, `plt_epr_codigo_residual_meta <= eia_epr_codigo_inherente` y `plt_eim_codigo_residual_meta <= eia_eim_codigo_inherente` (con reducción en al menos uno).
- **RN-RSG-05 (Privacidad por Diseño - ISO 27701):** Si el `eia_aci_codigo_primario` tiene `aci_contiene_datos_personales = 1`, el plan de tratamiento debe vincular al menos un control con `crn_estandar_normativo = 'ISO/IEC 27701:2025'` en `sgspi.plan_tratamiento_control` (`ptc_codigo`).
- **RN-RSG-06 (Validación de Cronogramas):** Garantizada por `CK_plt_cronograma` (`plt_fecha_fin >= plt_fecha_inicio`).
- **RN-SOA-01 (Evidencia Obligatoria para Cumplimiento SoA):** Garantizada por `CK_eac_cumple_requiere_evidencia` en SQL Server: bloquea guardar `eac_estado_implementacion = 'CUMPLE'` si `eac_documento_soporte_normativo` o `eac_evidencia_objetiva_esperada` son nulos, vacíos o `'PENDIENTE'`.

---

## 7. Actores Actuales del Sistema (Integrados con `dbo.grupo` y `dbo.usuario_grupo`)

| Grupo en `dbo.grupo` (`gru_nombre`) | Nombre del Rol / Actor Institucional | Cargos Reales en `dbo.cargo` (`car_nombre`) | Responsabilidad Principal |
| :--- | :--- | :--- | :--- |
| **`SGSPI_CUSTODIO_OPERADOR`** | Operador / Custodio de Activo / Ejecutor | Profesionales de gestión, Profesionales especializados, DBA, Administradores de red, Desarrolladores, Secretarías, Técnicos operativos, Contratistas | Registra borradores de contexto DOFA (`acf`), mantiene el inventario técnico de activos bajo su custodia (`aci`) y carga avances y evidencias en `sgspi.seguimiento_actividad` (`sga`). |
| **`SGSPI_LIDER_PROPIETARIO`** | Líder de Proceso / Propietario de Activo | Directores de oficina, Jefes de programa, Decanos, Vicerrectores, Secretario General, Líderes de los 21 procesos | Valora $C, I, D$ y clasificación de transparencia/privacidad de sus activos, identifica riesgos de su proceso (`eia`) y avala en 1.ª instancia los registros de su área. |
| **`SGSPI_ADMIN_OPDP`** | Administrador Funcional SGSPI y Oficial de Protección de Datos | Profesional Especializado Líder del SGSPI, Oficial de Protección de Datos Personales, Asesor Jurídico de Privacidad | Administra vigencias (`pev`) y catálogos, gestiona Partes Interesadas (`pai`/`rpi`) y SoA (`eac`), realiza la revisión metodológica (2.ª instancia) y monitorea KPIs. |
| **`SGSPI_COMITE_DIRECCION`** | Comité Institucional de Seguridad y Privacidad / Alta Dirección | Rector, Vicerrectores, Comité Administrativo, Comité Institucional de Seguridad y Privacidad | Aprueba políticas y planes anuales de tratamiento (`plt`), autoriza recursos y aprueba excepcionalmente la aceptación de riesgos Altos/Extremos. |
| **`SGSPI_AUDITOR_CONTROL`** | Auditor Interno / Aseguramiento de Calidad / Ente Externo | Jefe y Auditores de Control Interno, Coordinador y Auditores SGC, Auditores externos (ICONTEC / MinTIC / Contraloría) | Consulta transversal de solo lectura, verifica trazabilidad en `sgspi.bitacora_auditoria_sistema` (`bas`), audita el SoA (`eac`) y certifica la eficacia final de los planes de tratamiento. |

---

## 8. Ciclo de Vida del Registro

$$\text{BORRADOR} \longrightarrow \text{EN\_VALIDACION\_LIDER} \longrightarrow \text{EN\_REVISION\_SGSPI} \longrightarrow \text{APROBADO\_PLANIFICADO} \longrightarrow \text{EN\_EJECUCION} \longrightarrow \text{EN\_EVALUACION\_EFICACIA} \longrightarrow \text{CERRADO\_EFICAZ} \longrightarrow \text{HISTORICO}$$

- **Estados de Excepción y Control:**
  - **`OBSERVADO`**: Cuando un registro es devuelto por el `SGSPI_LIDER_PROPIETARIO`, `SGSPI_ADMIN_OPDP` o `SGSPI_COMITE_DIRECCION` con motivo obligatorio registrado en `bas_motivo_observacion` (`sgspi.bitacora_auditoria_sistema`).
  - **`EN_ACEPTACION_COMITE`**: Estado requerido cuando un riesgo en zona `Alta (A)` o `Extrema (E)` solicita ser asumido, compartido o mantiene un nivel residual Alto/Extremo.

---

## 9. Casos de Uso Principales por Rol (CRUD, Aprobaciones y Reportería)

| Rol (`dbo.grupo`) | Operaciones CRUD | Flujos de Aprobación / Validación | Reportería y Consultas |
| :--- | :--- | :--- | :--- |
| **`SGSPI_CUSTODIO_OPERADOR`** | • Crear/editar factores DOFA (`acf`) en borrador.<br>• Crear/actualizar datos técnicos de activos (`aci`) asignados.<br>• Registrar avances y subir evidencias en `sgspi.seguimiento_actividad` (`sga`). | • Enviar registros en `BORRADOR` u `OBSERVADO` a `EN_VALIDACION_LIDER`. | • Bandeja de actividades pendientes (`act`) y alertas de vencimiento.<br>• Exportación de fichas de activos bajo su custodia. |
| **`SGSPI_LIDER_PROPIETARIO`** | • CRUD de contexto (`acf`), activos (`aci`) y eventos de riesgo (`eia`) de su proceso.<br>• Valorar `aci_valor_confidencialidad`, `aci_valor_integridad`, `aci_valor_disponibilidad`, transparencia, PII e ICC.<br>• Diseñar propuestas en `sgspi.plan_tratamiento` (`plt`). | • **Avalar en 1.ª instancia** (`EN_VALIDACION_LIDER` $\rightarrow$ `EN_REVISION_SGSPI`).<br>• Observar/devolver borradores a sus custodios.<br>• Solicitar cierre de plan al completar el 100% de actividades. | • Tablero de control de su proceso (`pri_codigo`): activos por criticidad, mapa de calor de riesgos de su área, avance de planes. |
| **`SGSPI_ADMIN_OPDP`** | • CRUD de `periodo_vigencia` (`pev`) y catálogos maestros.<br>• CRUD completo de `requisito_parte_interesada` (`rpi`) y `evaluacion_aplicabilidad_control` (`eac`).<br>• Vincular controles en `plan_tratamiento_control` (`ptc`). | • **Aprobar en 2.ª instancia (Revisión Metodológica)** (`EN_REVISION_SGSPI` $\rightarrow$ `APROBADO_PLANIFICADO`).<br>• Escalar riesgos `Altos/Extremos` a `EN_ACEPTACION_COMITE`.<br>• Evaluar cumplimiento de KPIs. | • Vista `vw_consolidado_dofa`.<br>• Exportación oficial de formatos controlados `ES-GSPI-MR-01` al `06`.<br>• Reportes de cumplimiento de privacidad y alertas ICC. |
| **`SGSPI_COMITE_DIRECCION`** | • Registrar actas, resoluciones y decisiones estratégicas del Comité. | • **Aprobar en instancia ejecutiva** riesgos escalados (`EN_ACEPTACION_COMITE` $\rightarrow$ `APROBADO_PLANIFICADO`) y cierre de planeación anual. | • Cuadro de Mando Ejecutivo: Mapa de calor 5x5 global, reducción de riesgo inherente vs. residual y presupuesto. |
| **`SGSPI_AUDITOR_CONTROL`** | • **Sin permisos de creación/edición/borrado sobre datos operativos.**<br>• Registrar `eac_observaciones_auditoria` en el SoA y `plt_dictamen_eficacia` en planes de tratamiento. | • **Certificar o rechazar la eficacia final** (`EN_EVALUACION_EFICACIA` $\rightarrow$ `CERRADO_EFICAZ` o reabrir a `EN_EJECUCION`). | • Acceso completo a `sgspi.bitacora_auditoria_sistema` (`bas`), historial de versiones, evidencias con hash SHA-256 (`sga_hash_sha256_evidencia`) y brechas del SoA. |

---

## 10. Máquina de Estados para el Registro Principal

```mermaid
stateDiagram-v2
    [*] --> BORRADOR : 1. Crear registro (CUSTODIO / LIDER)

    BORRADOR --> EN_VALIDACION_LIDER : 2. Enviar a validación (CUSTODIO)
    EN_VALIDACION_LIDER --> EN_REVISION_SGSPI : 3. Avalar por Proceso (LIDER_PROPIETARIO)
    BORRADOR --> EN_REVISION_SGSPI : 3b. Envío directo si crea el LIDER

    EN_VALIDACION_LIDER --> OBSERVADO : 4a. Devolver con ajustes (LIDER_PROPIETARIO)
    EN_REVISION_SGSPI --> OBSERVADO : 4b. Rechazar técnicamente (ADMIN_OPDP)
    OBSERVADO --> EN_VALIDACION_LIDER : 5. Subsanar observaciones (CUSTODIO / LIDER)

    EN_REVISION_SGSPI --> EN_ACEPTACION_COMITE : 6a. Escalar si Riesgo es Alto/Extremo\ny requiere Aceptación o Presupuesto (ADMIN_OPDP)
    EN_ACEPTACION_COMITE --> OBSERVADO : 6b. Rechazar plan o exigir más controles (COMITE_DIRECCION)
    EN_ACEPTACION_COMITE --> APROBADO_PLANIFICADO : 7a. Aprobar tratamiento / Aceptar riesgo (COMITE_DIRECCION)

    EN_REVISION_SGSPI --> APROBADO_PLANIFICADO : 7b. Aprobar Plan de Tratamiento estándar (ADMIN_OPDP)

    APROBADO_PLANIFICADO --> EN_EJECUCION : 8. Iniciar cronograma / Registrar 1er avance (CUSTODIO / LIDER)
    EN_EJECUCION --> EN_EJECUCION : 9. Cargar seguimiento y evidencias parciales (CUSTODIO / LIDER)

    EN_EJECUCION --> EN_EVALUACION_EFICACIA : 10. Completar 100% actividades y reportar KPI (LIDER_PROPIETARIO)
    EN_EVALUACION_EFICACIA --> EN_EJECUCION : 11a. Tratamiento Ineficaz / Evidencia insuficiente (ADMIN_OPDP / AUDITOR)
    EN_EVALUACION_EFICACIA --> CERRADO_EFICAZ : 11b. Certificar Eficacia y actualizar Riesgo Residual (ADMIN_OPDP / AUDITOR)

    CERRADO_EFICAZ --> HISTORICO : 12. Cierre de vigencia anual (ADMIN_OPDP)
```

---

## 11. Matriz Básica de Permisos (RBAC) y Seguridad

**Convenciones:** `C` = Crear \| `R` = Leer \| `U` = Actualizar \| `D` = Inactivar/Eliminar lógico \| `V` = Validar/Observar \| `A` = Aprobar/Cerrar \| `E` = Exportar/Auditar.  
**Alcance (Row-Level Security vía `sgspi.vw_usuario_rol_alcance_sgspi`):** `[Todo]` = Transversal 21 procesos \| `[Proceso/UAA]` = Solo su `pri_codigo` / `uaa_codigo` \| `[Asignado]` = Solo activos/actividades asignadas.

| Tabla / Vista en Esquema `sgspi` (`[acr]`) | `CUSTODIO_OPERADOR` | `LIDER_PROPIETARIO` | `ADMIN_OPDP` | `COMITE_DIRECCION` | `AUDITOR_CONTROL` |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **0. `periodo_vigencia` (`[pev]`) y Catálogos** | `R [Todo]` | `R [Todo]` | **`C, R, U, D, A [Todo]`** | `R [Todo]` | `R, E [Todo]` |
| **1. `analisis_contexto_factor` (`[acf]`)** | `C, R, U [Proceso/UAA]` | **`C, R, U, D, V, E [Proceso/UAA]`** | **`R, V, A, E [Todo]`** | `R, E [Todo]` | `R, E [Todo]` |
| **2. `vw_consolidado_dofa`** | `R [Proceso/UAA]` | `R, E [Proceso/UAA]` | **`R, V, A, E [Todo]`** | **`R, A, E [Todo]`** | `R, E [Todo]` |
| **3. `parte_interesada` (`[pai]`) y `requisito_parte_interesada` (`[rpi]`)** | `R [Proceso/UAA]` | `R, U (cumplimiento), V [Proceso/UAA]` | **`C, R, U, D, V, A, E [Todo]`** | `R, A, E [Todo]` | `R, E [Todo]` |
| **4.1 `activo_informacion` (`[aci]` - Datos Básicos)** | `C, R, U [Asignado]` | **`C, R, U, D, V, E [Proceso/UAA]`** | **`C, R, U, V, A, E [Todo]`** | `R, E [Todo]` | `R, E [Todo]` |
| **4.2 `activo_informacion` (`[aci]` - CID, Transparencia, PII, ICC)**| `R [Asignado]` | **`C, R, U, V [Proceso/UAA]`** | **`R, U, V, A, E [Todo]`** | `R, A (ICC), E [Todo]` | `R, E [Todo]` |
| **5.1 `evento_incertidumbre_activo` (`[eia]`)** | `C, R [Asignado]` | **`C, R, U, D, V, E [Proceso/UAA]`** | **`C, R, U, V, A, E [Todo]`** | **`R, A (Zonas A/E), E [Todo]`** | `R, E [Todo]` |
| **5.2 `plan_tratamiento` (`[plt]`)** | `R [Asignado]` | **`C, R, U, V, E [Proceso/UAA]`** | **`C, R, U, V, A, E [Todo]`** | **`R, A, E [Todo]`** | `R, E [Todo]` |
| **5.3 `actividad_tratamiento` (`[act]`) y `seguimiento_actividad` (`[sga]`)** | **`C, R, U [Asignado]`** | **`C, R, U, V, E [Proceso/UAA]`** | **`R, V, A, E [Todo]`** | `R, E [Todo]` | **`R, V, A (Eficacia), E [Todo]`** |
| **5.4 `evaluacion_aplicabilidad_control` (`[eac]` - SoA)** | `R [Asignado]` | `R [Proceso/UAA]` | **`C, R, U, V, A, E [Todo]`** | **`R, A, E [Todo]`** | **`R, V, E [Todo]`** |
| **6. `bitacora_auditoria_sistema` (`[bas]`)** | *Sin acceso* | *Sin acceso* | `R, E [Todo]` | `R [Todo]` | **`R, E [Todo]`** |

---

## 12. Script DDL T-SQL de Producción para Microsoft SQL Server 2019 (Con Acrónimos y `_codigo`)

El script ejecutable completo (incluyendo las 4 vistas dinámicas `vw_usuario_rol_alcance_sgspi`, `vw_consolidado_dofa`, `vw_resumen_activos_criticidad` y `vw_matriz_tratamiento_riesgos`) se encuentra guardado en [DDL_SGSPI_SQLSERVER2019.sql](file:///c:/Users/USER/Pictures/p_academica-main/p_academica-main/DDL_SGSPI_SQLSERVER2019.sql).

```sql
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'sgspi')
BEGIN
    EXEC(N'CREATE SCHEMA sgspi AUTHORIZATION dbo;');
END
GO

-- 1.1 [pev] Periodos de Vigencia Anual del SGSPI
CREATE TABLE sgspi.periodo_vigencia (
    pev_codigo              SMALLINT IDENTITY(1,1) NOT NULL,
    pev_anio                SMALLINT NOT NULL,
    pev_fecha_apertura      DATE NOT NULL,
    pev_fecha_cierre        DATE NULL,
    pev_estado_vigencia     NVARCHAR(20) NOT NULL DEFAULT N'ABIERTA',
    pev_fecha_creacion      DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_pev_periodo_vigencia PRIMARY KEY CLUSTERED (pev_codigo),
    CONSTRAINT UQ_pev_anio UNIQUE (pev_anio),
    CONSTRAINT CK_pev_estado_vigencia CHECK (pev_estado_vigencia IN (N'EN_CONFIGURACION', N'ABIERTA', N'CERRADA', N'HISTORICA')),
    CONSTRAINT CK_pev_fechas CHECK (pev_fecha_cierre IS NULL OR pev_fecha_cierre >= pev_fecha_apertura)
);

-- 1.2 [fdv] Control Documental de Versiones de Formatos SGC/SGSPI por Vigencia
CREATE TABLE sgspi.formato_documental_version (
    fdv_codigo                  SMALLINT IDENTITY(1,1) NOT NULL,
    pev_codigo                  SMALLINT NOT NULL,
    fdv_dominio_funcional       NVARCHAR(40) NOT NULL,
    fdv_codigo_formato          NVARCHAR(20) NOT NULL,
    fdv_numero_version          NVARCHAR(10) NOT NULL,
    fdv_nombre_oficial_formato  NVARCHAR(200) NOT NULL,
    fdv_fecha_emision_formato   DATE NULL,
    fdv_es_version_activa       BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_fdv_formato_documental_version PRIMARY KEY CLUSTERED (fdv_codigo),
    CONSTRAINT UQ_fdv_vigencia_dominio UNIQUE (pev_codigo, fdv_dominio_funcional),
    CONSTRAINT FK_fdv_periodo_vigencia FOREIGN KEY (pev_codigo) REFERENCES sgspi.periodo_vigencia (pev_codigo),
    CONSTRAINT CK_fdv_dominio_funcional CHECK (fdv_dominio_funcional IN (
        N'CONTEXTO_DOFA', N'PARTES_INTERESADAS', N'INVENTARIO_ACTIVOS', N'RIESGOS_Y_OPORTUNIDADES'
    ))
);

-- 1.3 [tpr] Catálogo de Tipos de Proceso del Sistema Integrado de Gestión (MIPG / SGC)
CREATE TABLE sgspi.tipo_proceso_catalogo (
    tpr_codigo              TINYINT IDENTITY(1,1) NOT NULL,
    tpr_identificador       NVARCHAR(20) NOT NULL,
    tpr_nombre              NVARCHAR(50) NOT NULL,
    tpr_descripcion         NVARCHAR(255) NULL,
    CONSTRAINT PK_tpr_tipo_proceso_catalogo PRIMARY KEY CLUSTERED (tpr_codigo),
    CONSTRAINT UQ_tpr_identificador UNIQUE (tpr_identificador),
    CONSTRAINT CK_tpr_nombre CHECK (tpr_nombre IN (N'ESTRATÉGICO', N'MISIONAL', N'APOYO', N'EVALUACIÓN'))
);

-- 1.4 [pri] Procesos Institucionales (Los 21 procesos del SGC / SGSPI USCO)
CREATE TABLE sgspi.proceso_institucional (
    pri_codigo              INT IDENTITY(1,1) NOT NULL,
    pri_identificador       NVARCHAR(20) NOT NULL,
    pri_nombre              NVARCHAR(150) NOT NULL,
    tpr_codigo              TINYINT NOT NULL,
    pri_uaa_codigo_lider    INT NULL, -- FK a [dbo].[uaa]([uaa_codigo])
    pri_car_codigo_lider    INT NULL, -- FK a [dbo].[cargo]([car_codigo])
    pri_esta_activo         BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_pri_proceso_institucional PRIMARY KEY CLUSTERED (pri_codigo),
    CONSTRAINT UQ_pri_nombre UNIQUE (pri_nombre),
    CONSTRAINT FK_pri_tipo_proceso FOREIGN KEY (tpr_codigo) REFERENCES sgspi.tipo_proceso_catalogo (tpr_codigo),
    CONSTRAINT FK_pri_dbo_uaa_lider FOREIGN KEY (pri_uaa_codigo_lider) REFERENCES dbo.uaa (uaa_codigo),
    CONSTRAINT FK_pri_dbo_cargo_lider FOREIGN KEY (pri_car_codigo_lider) REFERENCES dbo.cargo (car_codigo)
);

-- 1.5 [pru] Tabla Puente N:M Proceso SGC <-> Unidades Académico-Administrativas ([dbo].[uaa])
CREATE TABLE sgspi.proceso_uaa (
    pru_codigo                      INT IDENTITY(1,1) NOT NULL,
    pri_codigo                      INT NOT NULL,
    uaa_codigo                      INT NOT NULL, -- FK a [dbo].[uaa]([uaa_codigo])
    pru_es_responsable_principal    BIT NOT NULL DEFAULT 0,
    CONSTRAINT PK_pru_proceso_uaa PRIMARY KEY CLUSTERED (pru_codigo),
    CONSTRAINT UQ_pru_proceso_uaa UNIQUE (pri_codigo, uaa_codigo),
    CONSTRAINT FK_pru_proceso_institucional FOREIGN KEY (pri_codigo) REFERENCES sgspi.proceso_institucional (pri_codigo) ON DELETE CASCADE,
    CONSTRAINT FK_pru_dbo_uaa FOREIGN KEY (uaa_codigo) REFERENCES dbo.uaa (uaa_codigo)
);

-- 2.1 [fec] Catálogo de Factores de Entorno
CREATE TABLE sgspi.factor_entorno_catalogo (
    fec_codigo              SMALLINT IDENTITY(1,1) NOT NULL,
    fec_nombre_factor       NVARCHAR(100) NOT NULL,
    fec_ambito_entorno      NVARCHAR(15) NOT NULL,
    fec_descripcion         NVARCHAR(255) NULL,
    CONSTRAINT PK_fec_factor_entorno_catalogo PRIMARY KEY CLUSTERED (fec_codigo),
    CONSTRAINT UQ_fec_nombre_ambito UNIQUE (fec_nombre_factor, fec_ambito_entorno),
    CONSTRAINT CK_fec_ambito_entorno CHECK (fec_ambito_entorno IN (N'INTERNO', N'EXTERNO'))
);

-- 2.2 [acf] Análisis de Factores de Contexto por Proceso (DOFA por Proceso y Consolidado)
CREATE TABLE sgspi.analisis_contexto_factor (
    acf_codigo                  INT IDENTITY(1,1) NOT NULL,
    pev_codigo                  SMALLINT NOT NULL,
    pri_codigo                  INT NOT NULL,
    fec_codigo                  SMALLINT NOT NULL,
    acf_ambito_entorno          NVARCHAR(15) NOT NULL,
    acf_naturaleza_factor       NVARCHAR(15) NOT NULL,
    acf_descripcion_situacion   NVARCHAR(MAX) NOT NULL,
    acf_nivel_prioridad         NVARCHAR(10) NOT NULL,
    acf_impacto_sistema_gestion NVARCHAR(MAX) NULL,
    acf_accion_propuesta        NVARCHAR(MAX) NULL,
    acf_estado_registro         NVARCHAR(30) NOT NULL DEFAULT N'BORRADOR',
    acf_per_codigo_creador      INT NOT NULL, -- FK a [dbo].[persona]([per_codigo])
    acf_per_codigo_aprobador    INT NULL,     -- FK a [dbo].[persona]([per_codigo])
    acf_fecha_creacion          DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
    acf_fecha_actualizacion     DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_acf_analisis_contexto_factor PRIMARY KEY CLUSTERED (acf_codigo),
    CONSTRAINT FK_acf_periodo_vigencia FOREIGN KEY (pev_codigo) REFERENCES sgspi.periodo_vigencia (pev_codigo),
    CONSTRAINT FK_acf_proceso_institucional FOREIGN KEY (pri_codigo) REFERENCES sgspi.proceso_institucional (pri_codigo),
    CONSTRAINT FK_acf_factor_entorno FOREIGN KEY (fec_codigo) REFERENCES sgspi.factor_entorno_catalogo (fec_codigo),
    CONSTRAINT FK_acf_dbo_persona_creador FOREIGN KEY (acf_per_codigo_creador) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT FK_acf_dbo_persona_aprobador FOREIGN KEY (acf_per_codigo_aprobador) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT CK_acf_ambito_naturaleza CHECK (
        (acf_ambito_entorno = N'INTERNO' AND acf_naturaleza_factor IN (N'DEBILIDAD', N'FORTALEZA')) OR
        (acf_ambito_entorno = N'EXTERNO' AND acf_naturaleza_factor IN (N'AMENAZA', N'OPORTUNIDAD'))
    ),
    CONSTRAINT CK_acf_nivel_prioridad CHECK (acf_nivel_prioridad IN (N'Alta', N'Media', N'Baja')),
    CONSTRAINT CK_acf_prioridad_alta_campos CHECK (
        acf_estado_registro = N'BORRADOR' OR acf_nivel_prioridad <> N'Alta' OR
        (LEN(TRIM(ISNULL(acf_impacto_sistema_gestion, N''))) > 0 AND LEN(TRIM(ISNULL(acf_accion_propuesta, N''))) > 0)
    )
);

-- 3.1 [pai] y 3.2 [rpi] / 3.3 [rpa] Partes Interesadas y sus Requisitos
CREATE TABLE sgspi.parte_interesada (
    pai_codigo                  INT IDENTITY(1,1) NOT NULL,
    pai_nombre                  NVARCHAR(150) NOT NULL,
    pai_origen                  NVARCHAR(15) NOT NULL,
    pai_descripcion_rol         NVARCHAR(255) NULL,
    pai_esta_activa             BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_pai_parte_interesada PRIMARY KEY CLUSTERED (pai_codigo),
    CONSTRAINT UQ_pai_nombre UNIQUE (pai_nombre),
    CONSTRAINT CK_pai_origen CHECK (pai_origen IN (N'Interna', N'Externa'))
);

CREATE TABLE sgspi.requisito_parte_interesada (
    rpi_codigo                  INT IDENTITY(1,1) NOT NULL,
    pev_codigo                  SMALLINT NOT NULL,
    pai_codigo                  INT NOT NULL,
    rpi_referencia_cuestionario NVARCHAR(30) NULL,
    rpi_necesidad_expectativa   NVARCHAR(MAX) NOT NULL,
    rpi_nivel_poder             NVARCHAR(10) NOT NULL,
    rpi_nivel_interes           NVARCHAR(10) NOT NULL,
    rpi_clasificacion_impacto AS (
        CASE
            WHEN rpi_nivel_poder = N'Alto' AND rpi_nivel_interes IN (N'Alto', N'Medio')
                THEN N'CUIDADO "Tratar como requisito legal y otros requisitos"'
            WHEN (rpi_nivel_poder = N'Alto' AND rpi_nivel_interes = N'Bajo')
              OR (rpi_nivel_poder = N'Medio' AND rpi_nivel_interes IN (N'Alto', N'Medio'))
                THEN N'ATENCIÓN "Mantener Satisfecho"'
            WHEN (rpi_nivel_poder = N'Medio' AND rpi_nivel_interes = N'Bajo')
              OR (rpi_nivel_poder = N'Bajo' AND rpi_nivel_interes = N'Alto')
                THEN N'MITIGANTE "Mantener Informado"'
            ELSE N'SIN PROBLEMA "Monitorear por si cambia de categoria"'
        END
    ),
    rpi_nivel_cumplimiento      NVARCHAR(10) NULL,
    rpi_prioridad_accion AS (
        CASE rpi_nivel_cumplimiento
            WHEN N'Alto'  THEN N'Prioridad alta'
            WHEN N'Medio' THEN N'Prioridad media'
            WHEN N'Bajo'  THEN N'Prioridad baja'
            ELSE NULL
        END
    ),
    rpi_mecanismo_seguimiento   NVARCHAR(255) NULL,
    rpi_estado_registro         NVARCHAR(30) NOT NULL DEFAULT N'VIGENTE',
    rpi_fecha_creacion          DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_rpi_requisito_parte_interesada PRIMARY KEY CLUSTERED (rpi_codigo),
    CONSTRAINT FK_rpi_periodo_vigencia FOREIGN KEY (pev_codigo) REFERENCES sgspi.periodo_vigencia (pev_codigo),
    CONSTRAINT FK_rpi_parte_interesada FOREIGN KEY (pai_codigo) REFERENCES sgspi.parte_interesada (pai_codigo)
);

CREATE TABLE sgspi.requisito_proceso_afectado (
    rpa_codigo                  INT IDENTITY(1,1) NOT NULL,
    rpi_codigo                  INT NOT NULL,
    pri_codigo                  INT NOT NULL,
    rpa_fecha_registro          DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_rpa_requisito_proceso_afectado PRIMARY KEY CLUSTERED (rpa_codigo),
    CONSTRAINT UQ_rpa_requisito_proceso UNIQUE (rpi_codigo, pri_codigo),
    CONSTRAINT FK_rpa_requisito_parte_interesada FOREIGN KEY (rpi_codigo) REFERENCES sgspi.requisito_parte_interesada (rpi_codigo) ON DELETE CASCADE,
    CONSTRAINT FK_rpa_proceso_institucional FOREIGN KEY (pri_codigo) REFERENCES sgspi.proceso_institucional (pri_codigo)
);

-- 4.1 [tac], 4.2 [cet], 4.3 [aci], 4.4 [acp]/[acs]/[acr], 4.5 [sif]/[msi] Inventario de Activos
CREATE TABLE sgspi.tipo_activo_catalogo (
    tac_codigo                  SMALLINT IDENTITY(1,1) NOT NULL,
    tac_categoria_iso27005      NVARCHAR(20) NOT NULL,
    tac_tipo_activo             NVARCHAR(80) NOT NULL,
    tac_subtipo_activo          NVARCHAR(120) NOT NULL,
    tac_ejemplos_referencia     NVARCHAR(255) NULL,
    CONSTRAINT PK_tac_tipo_activo_catalogo PRIMARY KEY CLUSTERED (tac_codigo),
    CONSTRAINT UQ_tac_jerarquia UNIQUE (tac_categoria_iso27005, tac_tipo_activo, tac_subtipo_activo)
);

CREATE TABLE sgspi.causal_excepcion_transparencia (
    cet_codigo                  SMALLINT IDENTITY(1,1) NOT NULL,
    cet_nivel_reserva_aplicable NVARCHAR(20) NOT NULL,
    cet_numeral_causal          NVARCHAR(10) NOT NULL,
    cet_descripcion_causal      NVARCHAR(500) NOT NULL,
    cet_norma_referencia        NVARCHAR(100) NOT NULL DEFAULT N'Ley 1712 de 2014',
    CONSTRAINT PK_cet_causal_excepcion_transparencia PRIMARY KEY CLUSTERED (cet_codigo)
);

CREATE TABLE sgspi.activo_informacion (
    aci_codigo                          INT IDENTITY(1,1) NOT NULL,
    aci_codigo_inventario               NVARCHAR(30) NOT NULL,
    aci_nombre_activo                   NVARCHAR(255) NOT NULL,
    aci_descripcion_detallada           NVARCHAR(MAX) NULL,
    tac_codigo                          SMALLINT NOT NULL,
    uaa_codigo                          INT NULL, -- FK a [dbo].[uaa]([uaa_codigo])
    esp_codigo                          INT NULL, -- FK a [dbo].[espacio]([esp_codigo])
    aci_es_transversal_sedes            BIT NOT NULL DEFAULT 0,
    aci_cantidad_unidades               INT NOT NULL DEFAULT 1,
    aci_clasificacion_transparencia     NVARCHAR(20) NOT NULL,
    cet_codigo                          SMALLINT NULL,
    aci_alcance_excepcion               NVARCHAR(15) NOT NULL DEFAULT N'No aplica',
    aci_contiene_datos_personales       BIT NOT NULL DEFAULT 0,
    aci_contiene_datos_menores          BIT NULL,
    aci_categoria_dato_personal         NVARCHAR(20) NULL,
    aci_valor_confidencialidad          TINYINT NOT NULL,
    aci_valor_integridad                TINYINT NOT NULL,
    aci_valor_disponibilidad            TINYINT NOT NULL,
    aci_nivel_confidencialidad AS (CASE aci_valor_confidencialidad WHEN 3 THEN N'Alta' WHEN 2 THEN N'Media' ELSE N'Baja' END),
    aci_nivel_integridad       AS (CASE aci_valor_integridad       WHEN 3 THEN N'Alta' WHEN 2 THEN N'Media' ELSE N'Baja' END),
    aci_nivel_disponibilidad   AS (CASE aci_valor_disponibilidad   WHEN 3 THEN N'Alta' WHEN 2 THEN N'Media' ELSE N'Baja' END),
    aci_puntaje_criticidad     AS (CAST(aci_valor_confidencialidad + aci_valor_integridad + aci_valor_disponibilidad AS TINYINT)) PERSISTED,
    aci_nivel_criticidad       AS (
        CASE
            WHEN (aci_valor_confidencialidad + aci_valor_integridad + aci_valor_disponibilidad) >= 7 THEN N'Alta'
            WHEN (aci_valor_confidencialidad + aci_valor_integridad + aci_valor_disponibilidad) >= 5 THEN N'Media'
            ELSE N'Baja'
        END
    ) PERSISTED,
    aci_supera_umbral_social_icc        BIT NOT NULL DEFAULT 0,
    aci_supera_umbral_economico_icc     BIT NOT NULL DEFAULT 0,
    aci_supera_umbral_ambiental_icc     BIT NOT NULL DEFAULT 0,
    aci_es_infraestructura_critica_icc  AS (
        CASE
            WHEN aci_supera_umbral_social_icc = 1 OR aci_supera_umbral_economico_icc = 1 OR aci_supera_umbral_ambiental_icc = 1
                THEN CAST(1 AS BIT)
            ELSE CAST(0 AS BIT)
        END
    ),
    aci_estado_registro                 NVARCHAR(30) NOT NULL DEFAULT N'VIGENTE',
    aci_per_codigo_creador              INT NOT NULL, -- FK a [dbo].[persona]([per_codigo])
    aci_per_codigo_aprobador            INT NULL,     -- FK a [dbo].[persona]([per_codigo])
    aci_fecha_creacion                  DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
    aci_fecha_actualizacion             DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_aci_activo_informacion PRIMARY KEY CLUSTERED (aci_codigo),
    CONSTRAINT UQ_aci_codigo_inventario UNIQUE (aci_codigo_inventario),
    CONSTRAINT FK_aci_tipo_activo FOREIGN KEY (tac_codigo) REFERENCES sgspi.tipo_activo_catalogo (tac_codigo),
    CONSTRAINT FK_aci_dbo_uaa FOREIGN KEY (uaa_codigo) REFERENCES dbo.uaa (uaa_codigo),
    CONSTRAINT FK_aci_dbo_espacio FOREIGN KEY (esp_codigo) REFERENCES dbo.espacio (esp_codigo),
    CONSTRAINT FK_aci_causal_excepcion FOREIGN KEY (cet_codigo) REFERENCES sgspi.causal_excepcion_transparencia (cet_codigo),
    CONSTRAINT FK_aci_dbo_persona_creador FOREIGN KEY (aci_per_codigo_creador) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT FK_aci_dbo_persona_aprobador FOREIGN KEY (aci_per_codigo_aprobador) REFERENCES dbo.persona (per_codigo)
);

CREATE TABLE sgspi.activo_proceso (
    acp_codigo              INT IDENTITY(1,1) NOT NULL,
    aci_codigo              INT NOT NULL,
    pri_codigo              INT NOT NULL,
    CONSTRAINT PK_acp_activo_proceso PRIMARY KEY CLUSTERED (acp_codigo),
    CONSTRAINT UQ_acp_activo_proceso UNIQUE (aci_codigo, pri_codigo),
    CONSTRAINT FK_acp_activo_informacion FOREIGN KEY (aci_codigo) REFERENCES sgspi.activo_informacion (aci_codigo) ON DELETE CASCADE,
    CONSTRAINT FK_acp_proceso_institucional FOREIGN KEY (pri_codigo) REFERENCES sgspi.proceso_institucional (pri_codigo)
);

CREATE TABLE sgspi.activo_sede (
    acs_codigo              INT IDENTITY(1,1) NOT NULL,
    aci_codigo              INT NOT NULL,
    sed_codigo              INT NOT NULL, -- FK a [dbo].[sede]([sed_codigo])
    sus_codigo              INT NULL,     -- FK a [dbo].[sub_sede]([sus_codigo])
    CONSTRAINT PK_acs_activo_sede PRIMARY KEY CLUSTERED (acs_codigo),
    CONSTRAINT UQ_acs_activo_sede_subsede UNIQUE (aci_codigo, sed_codigo, sus_codigo),
    CONSTRAINT FK_acs_activo_informacion FOREIGN KEY (aci_codigo) REFERENCES sgspi.activo_informacion (aci_codigo) ON DELETE CASCADE,
    CONSTRAINT FK_acs_dbo_sede FOREIGN KEY (sed_codigo) REFERENCES dbo.sede (sed_codigo),
    CONSTRAINT FK_acs_dbo_sub_sede FOREIGN KEY (sus_codigo) REFERENCES dbo.sub_sede (sus_codigo)
);

CREATE TABLE sgspi.activo_responsable (
    acr_codigo                  INT IDENTITY(1,1) NOT NULL,
    aci_codigo                  INT NOT NULL,
    car_codigo                  INT NOT NULL, -- FK a [dbo].[cargo]([car_codigo])
    uaa_codigo                  INT NULL,     -- FK a [dbo].[uaa]([uaa_codigo])
    acr_tipo_responsabilidad    NVARCHAR(20) NOT NULL,
    CONSTRAINT PK_acr_activo_responsable PRIMARY KEY CLUSTERED (acr_codigo),
    CONSTRAINT UQ_acr_activo_cargo_tipo UNIQUE (aci_codigo, car_codigo, acr_tipo_responsabilidad),
    CONSTRAINT FK_acr_activo_informacion FOREIGN KEY (aci_codigo) REFERENCES sgspi.activo_informacion (aci_codigo) ON DELETE CASCADE,
    CONSTRAINT FK_acr_dbo_cargo FOREIGN KEY (car_codigo) REFERENCES dbo.cargo (car_codigo),
    CONSTRAINT FK_acr_dbo_uaa FOREIGN KEY (uaa_codigo) REFERENCES dbo.uaa (uaa_codigo)
);

CREATE TABLE sgspi.sistema_informacion_ficha (
    sif_codigo                  INT IDENTITY(1,1) NOT NULL,
    aci_codigo                  INT NULL,
    sif_nombre_sistema          NVARCHAR(150) NOT NULL,
    sif_modalidad_desarrollo    NVARCHAR(50) NOT NULL,
    sif_fabricante_proveedor    NVARCHAR(150) NULL,
    sif_descripcion_general     NVARCHAR(MAX) NOT NULL,
    CONSTRAINT PK_sif_sistema_informacion_ficha PRIMARY KEY CLUSTERED (sif_codigo),
    CONSTRAINT FK_sif_activo_informacion FOREIGN KEY (aci_codigo) REFERENCES sgspi.activo_informacion (aci_codigo)
);

CREATE TABLE sgspi.modulo_sistema_informacion (
    msi_codigo                  INT IDENTITY(1,1) NOT NULL,
    sif_codigo                  INT NOT NULL,
    msi_nombre_modulo           NVARCHAR(200) NOT NULL,
    msi_usuarios_objetivo       NVARCHAR(150) NULL,
    CONSTRAINT PK_msi_modulo_sistema_informacion PRIMARY KEY CLUSTERED (msi_codigo),
    CONSTRAINT FK_msi_sistema_informacion FOREIGN KEY (sif_codigo) REFERENCES sgspi.sistema_informacion_ficha (sif_codigo) ON DELETE CASCADE
);

-- 5.1 [epr]/[eim]/[mvr], 5.2 [eia], 5.3 [plt], 5.4 [act]/[sga], 5.5 [crn], 5.6 [ptc], 5.7 [eac], 5.8 [bas]
CREATE TABLE sgspi.escala_probabilidad (
    epr_codigo                  TINYINT NOT NULL,
    epr_codigo_letra            CHAR(1) NOT NULL,
    epr_nombre_nivel            NVARCHAR(30) NOT NULL,
    epr_descripcion_criterio    NVARCHAR(255) NOT NULL,
    epr_frecuencia_referencia   NVARCHAR(100) NOT NULL,
    CONSTRAINT PK_epr_escala_probabilidad PRIMARY KEY CLUSTERED (epr_codigo),
    CONSTRAINT UQ_epr_codigo_letra UNIQUE (epr_codigo_letra)
);

CREATE TABLE sgspi.escala_impacto (
    eim_codigo                      TINYINT NOT NULL,
    eim_nombre_impacto_negativo     NVARCHAR(30) NOT NULL,
    eim_nombre_impacto_positivo     NVARCHAR(40) NOT NULL,
    eim_descripcion_organizacional  NVARCHAR(MAX) NOT NULL,
    eim_descripcion_operativa       NVARCHAR(MAX) NULL,
    CONSTRAINT PK_eim_escala_impacto PRIMARY KEY CLUSTERED (eim_codigo)
);

CREATE TABLE sgspi.matriz_valoracion_riesgo (
    epr_codigo                          TINYINT NOT NULL,
    eim_codigo                          TINYINT NOT NULL,
    mvr_codigo_posicion                 CHAR(2) NOT NULL,
    mvr_codigo_zona                     CHAR(1) NOT NULL,
    mvr_nivel_valoracion                NVARCHAR(30) NOT NULL,
    mvr_directriz_tratamiento_riesgo      NVARCHAR(255) NOT NULL,
    mvr_directriz_tratamiento_oportunidad NVARCHAR(255) NOT NULL,
    mvr_requiere_aprobacion_comite      BIT NOT NULL DEFAULT 0,
    CONSTRAINT PK_mvr_matriz_valoracion_riesgo PRIMARY KEY CLUSTERED (epr_codigo, eim_codigo),
    CONSTRAINT UQ_mvr_codigo_posicion UNIQUE (mvr_codigo_posicion),
    CONSTRAINT FK_mvr_escala_probabilidad FOREIGN KEY (epr_codigo) REFERENCES sgspi.escala_probabilidad (epr_codigo),
    CONSTRAINT FK_mvr_escala_impacto FOREIGN KEY (eim_codigo) REFERENCES sgspi.escala_impacto (eim_codigo)
);

CREATE TABLE sgspi.evento_incertidumbre_activo (
    eia_codigo                      INT IDENTITY(1,1) NOT NULL,
    pev_codigo                      SMALLINT NOT NULL,
    eia_identificador_evento        NVARCHAR(15) NOT NULL,
    eia_naturaleza_evento           NVARCHAR(15) NOT NULL,
    pri_codigo                      INT NOT NULL,
    eia_aci_codigo_primario         INT NOT NULL,
    eia_aci_codigo_soporte          INT NOT NULL,
    eia_tipo_componente_afectado    NVARCHAR(50) NOT NULL,
    eia_fuente_generadora           NVARCHAR(255) NOT NULL,
    eia_controles_existentes        NVARCHAR(MAX) NULL,
    eia_condicion_vulnerabilidad    NVARCHAR(MAX) NOT NULL,
    eia_efecto_consecuencia         NVARCHAR(MAX) NOT NULL,
    eia_escenario_operacional       NVARCHAR(255) NOT NULL,
    eia_epr_codigo_inherente        TINYINT NOT NULL,
    eia_eim_codigo_inherente        TINYINT NOT NULL,
    eia_estado_registro             NVARCHAR(30) NOT NULL DEFAULT N'BORRADOR',
    eia_per_codigo_creador          INT NOT NULL, -- FK a [dbo].[persona]([per_codigo])
    eia_per_codigo_validador_lider  INT NULL,     -- FK a [dbo].[persona]([per_codigo])
    eia_per_codigo_revisor_sgspi    INT NULL,     -- FK a [dbo].[persona]([per_codigo])
    eia_per_codigo_aprobador_comite INT NULL,     -- FK a [dbo].[persona]([per_codigo])
    eia_fecha_creacion              DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
    eia_fecha_actualizacion         DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_eia_evento_incertidumbre_activo PRIMARY KEY CLUSTERED (eia_codigo),
    CONSTRAINT UQ_eia_vigencia_identificador UNIQUE (pev_codigo, eia_identificador_evento),
    CONSTRAINT FK_eia_periodo_vigencia FOREIGN KEY (pev_codigo) REFERENCES sgspi.periodo_vigencia (pev_codigo),
    CONSTRAINT FK_eia_proceso_institucional FOREIGN KEY (pri_codigo) REFERENCES sgspi.proceso_institucional (pri_codigo),
    CONSTRAINT FK_eia_activo_primario FOREIGN KEY (eia_aci_codigo_primario) REFERENCES sgspi.activo_informacion (aci_codigo),
    CONSTRAINT FK_eia_activo_soporte FOREIGN KEY (eia_aci_codigo_soporte) REFERENCES sgspi.activo_informacion (aci_codigo),
    CONSTRAINT FK_eia_valoracion_inherente FOREIGN KEY (eia_epr_codigo_inherente, eia_eim_codigo_inherente)
        REFERENCES sgspi.matriz_valoracion_riesgo (epr_codigo, eim_codigo),
    CONSTRAINT FK_eia_dbo_persona_creador FOREIGN KEY (eia_per_codigo_creador) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT FK_eia_dbo_persona_validador FOREIGN KEY (eia_per_codigo_validador_lider) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT FK_eia_dbo_persona_revisor FOREIGN KEY (eia_per_codigo_revisor_sgspi) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT FK_eia_dbo_persona_comite FOREIGN KEY (eia_per_codigo_aprobador_comite) REFERENCES dbo.persona (per_codigo)
);

CREATE TABLE sgspi.plan_tratamiento (
    plt_codigo                      INT IDENTITY(1,1) NOT NULL,
    eia_codigo                      INT NOT NULL,
    plt_estrategia_tratamiento      NVARCHAR(80) NOT NULL,
    plt_justificacion_estrategia    NVARCHAR(MAX) NOT NULL,
    plt_epr_codigo_residual_meta    TINYINT NOT NULL,
    plt_eim_codigo_residual_meta    TINYINT NOT NULL,
    plt_fecha_inicio                DATE NOT NULL,
    plt_fecha_fin                   DATE NOT NULL,
    plt_recursos_humanos_tecnicos   NVARCHAR(MAX) NOT NULL,
    plt_recursos_economicos_desc    NVARCHAR(500) NOT NULL,
    plt_presupuesto_estimado_cop    DECIMAL(18,2) NULL,
    plt_restricciones_limitaciones  NVARCHAR(MAX) NULL,
    plt_nombre_indicador_kpi        NVARCHAR(255) NOT NULL,
    plt_meta_indicador_kpi          NVARCHAR(100) NULL,
    plt_valor_alcanzado_kpi         NVARCHAR(100) NULL,
    plt_es_tratamiento_eficaz       BIT NULL,
    plt_dictamen_eficacia           NVARCHAR(MAX) NULL,
    plt_per_codigo_evaluador        INT NULL, -- FK a [dbo].[persona]([per_codigo])
    plt_fecha_evaluacion_eficacia   DATETIME2(0) NULL,
    CONSTRAINT PK_plt_plan_tratamiento PRIMARY KEY CLUSTERED (plt_codigo),
    CONSTRAINT UQ_plt_evento UNIQUE (eia_codigo),
    CONSTRAINT FK_plt_evento_incertidumbre FOREIGN KEY (eia_codigo) REFERENCES sgspi.evento_incertidumbre_activo (eia_codigo) ON DELETE CASCADE,
    CONSTRAINT FK_plt_valoracion_meta FOREIGN KEY (plt_epr_codigo_residual_meta, plt_eim_codigo_residual_meta)
        REFERENCES sgspi.matriz_valoracion_riesgo (epr_codigo, eim_codigo),
    CONSTRAINT FK_plt_dbo_persona_evaluador FOREIGN KEY (plt_per_codigo_evaluador) REFERENCES dbo.persona (per_codigo)
);

CREATE TABLE sgspi.actividad_tratamiento (
    act_codigo                  INT IDENTITY(1,1) NOT NULL,
    plt_codigo                  INT NOT NULL,
    act_numero_orden            SMALLINT NOT NULL DEFAULT 1,
    act_descripcion_actividad   NVARCHAR(500) NOT NULL,
    car_codigo                  INT NULL, -- FK a [dbo].[cargo]([car_codigo])
    uaa_codigo                  INT NULL, -- FK a [dbo].[uaa]([uaa_codigo])
    act_fecha_compromiso        DATE NOT NULL,
    act_porcentaje_avance       TINYINT NOT NULL DEFAULT 0,
    act_estado_actividad        NVARCHAR(20) NOT NULL DEFAULT N'PENDIENTE',
    CONSTRAINT PK_act_actividad_tratamiento PRIMARY KEY CLUSTERED (act_codigo),
    CONSTRAINT FK_act_plan_tratamiento FOREIGN KEY (plt_codigo) REFERENCES sgspi.plan_tratamiento (plt_codigo) ON DELETE CASCADE,
    CONSTRAINT FK_act_dbo_cargo FOREIGN KEY (car_codigo) REFERENCES dbo.cargo (car_codigo),
    CONSTRAINT FK_act_dbo_uaa FOREIGN KEY (uaa_codigo) REFERENCES dbo.uaa (uaa_codigo)
);

CREATE TABLE sgspi.seguimiento_actividad (
    sga_codigo                          INT IDENTITY(1,1) NOT NULL,
    act_codigo                          INT NOT NULL,
    per_codigo                          INT NOT NULL, -- FK a [dbo].[persona]([per_codigo])
    sga_fecha_registro                  DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
    sga_porcentaje_reportado            TINYINT NOT NULL,
    sga_descripcion_avance              NVARCHAR(MAX) NOT NULL,
    sga_nombre_archivo_evidencia        NVARCHAR(255) NULL,
    sga_uri_almacenamiento_evidencia    NVARCHAR(500) NULL,
    sga_hash_sha256_evidencia           CHAR(64) NULL,
    CONSTRAINT PK_sga_seguimiento_actividad PRIMARY KEY CLUSTERED (sga_codigo),
    CONSTRAINT FK_sga_actividad_tratamiento FOREIGN KEY (act_codigo) REFERENCES sgspi.actividad_tratamiento (act_codigo) ON DELETE CASCADE,
    CONSTRAINT FK_sga_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo)
);

CREATE TABLE sgspi.control_referencia_normativa (
    crn_codigo                  SMALLINT IDENTITY(1,1) NOT NULL,
    crn_estandar_normativo      NVARCHAR(30) NOT NULL,
    crn_rol_privacidad_pii      NVARCHAR(20) NOT NULL DEFAULT N'NO_APLICA',
    crn_identificador_control   NVARCHAR(20) NOT NULL,
    crn_nombre_control          NVARCHAR(200) NOT NULL,
    crn_objetivo_requisito      NVARCHAR(MAX) NOT NULL,
    crn_tipo_control            NVARCHAR(50) NULL,
    crn_propiedades_seguridad   NVARCHAR(100) NULL,
    crn_concepto_ciberseguridad NVARCHAR(100) NULL,
    crn_capacidad_operacional   NVARCHAR(150) NULL,
    crn_dominio_seguridad       NVARCHAR(100) NULL,
    CONSTRAINT PK_crn_control_referencia_normativa PRIMARY KEY CLUSTERED (crn_codigo),
    CONSTRAINT UQ_crn_estandar_identificador UNIQUE (crn_estandar_normativo, crn_identificador_control)
);

CREATE TABLE sgspi.plan_tratamiento_control (
    ptc_codigo              INT IDENTITY(1,1) NOT NULL,
    plt_codigo              INT NOT NULL,
    crn_codigo              SMALLINT NOT NULL,
    CONSTRAINT PK_ptc_plan_tratamiento_control PRIMARY KEY CLUSTERED (ptc_codigo),
    CONSTRAINT UQ_ptc_plan_control UNIQUE (plt_codigo, crn_codigo),
    CONSTRAINT FK_ptc_plan_tratamiento FOREIGN KEY (plt_codigo) REFERENCES sgspi.plan_tratamiento (plt_codigo) ON DELETE CASCADE,
    CONSTRAINT FK_ptc_control_referencia FOREIGN KEY (crn_codigo) REFERENCES sgspi.control_referencia_normativa (crn_codigo)
);

CREATE TABLE sgspi.evaluacion_aplicabilidad_control (
    eac_codigo                      INT IDENTITY(1,1) NOT NULL,
    pev_codigo                      SMALLINT NOT NULL,
    crn_codigo                      SMALLINT NOT NULL,
    eac_es_aplicable                BIT NOT NULL DEFAULT 1,
    eac_justificacion_aplicabilidad NVARCHAR(MAX) NULL,
    eac_documento_soporte_normativo NVARCHAR(500) NULL,
    car_codigo                      INT NULL, -- FK a [dbo].[cargo]([car_codigo])
    eac_frecuencia_revision         NVARCHAR(100) NOT NULL DEFAULT N'Anual y cuando se presenten cambios',
    eac_evidencia_objetiva_esperada NVARCHAR(500) NULL,
    eac_estado_implementacion       NVARCHAR(20) NOT NULL DEFAULT N'NO_CUMPLE',
    eac_observaciones_auditoria     NVARCHAR(MAX) NULL,
    eac_fecha_actualizacion         DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_eac_evaluacion_aplicabilidad_control PRIMARY KEY CLUSTERED (eac_codigo),
    CONSTRAINT UQ_eac_vigencia_control UNIQUE (pev_codigo, crn_codigo),
    CONSTRAINT FK_eac_periodo_vigencia FOREIGN KEY (pev_codigo) REFERENCES sgspi.periodo_vigencia (pev_codigo),
    CONSTRAINT FK_eac_control_referencia FOREIGN KEY (crn_codigo) REFERENCES sgspi.control_referencia_normativa (crn_codigo),
    CONSTRAINT FK_eac_dbo_cargo FOREIGN KEY (car_codigo) REFERENCES dbo.cargo (car_codigo)
);

CREATE TABLE sgspi.bitacora_auditoria_sistema (
    bas_codigo                  BIGINT IDENTITY(1,1) NOT NULL,
    bas_fecha_evento_utc        DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
    per_codigo                  INT NOT NULL, -- FK a [dbo].[persona]([per_codigo])
    gru_codigo                  INT NULL,     -- FK a [dbo].[grupo]([gru_codigo])
    usg_codigo                  INT NULL,     -- FK a [dbo].[usuario_grupo]([usg_codigo])
    bas_direccion_ip            VARCHAR(45) NULL,
    bas_entidad_afectada        NVARCHAR(80) NOT NULL,
    bas_registro_afectado_codigo NVARCHAR(50) NOT NULL,
    bas_accion_ejecutada        NVARCHAR(30) NOT NULL,
    bas_estado_anterior         NVARCHAR(30) NULL,
    bas_estado_nuevo            NVARCHAR(30) NULL,
    bas_valores_anteriores_json NVARCHAR(MAX) NULL,
    bas_valores_nuevos_json     NVARCHAR(MAX) NULL,
    bas_motivo_observacion      NVARCHAR(500) NULL,
    CONSTRAINT PK_bas_bitacora_auditoria_sistema PRIMARY KEY CLUSTERED (bas_codigo),
    CONSTRAINT FK_bas_dbo_persona FOREIGN KEY (per_codigo) REFERENCES dbo.persona (per_codigo),
    CONSTRAINT FK_bas_dbo_grupo FOREIGN KEY (gru_codigo) REFERENCES dbo.grupo (gru_codigo),
    CONSTRAINT FK_bas_dbo_usuario_grupo FOREIGN KEY (usg_codigo) REFERENCES dbo.usuario_grupo (usg_codigo)
);
GO
```
