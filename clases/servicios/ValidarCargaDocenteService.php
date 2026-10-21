<?php

require_once(dirname(__FILE__) . '/FechaSqlServer.php');

class ValidarCargaDocenteService
{
    private $cnx;

    public function __construct($cnx)
    {
        $this->cnx = $cnx;
    }

    /**
     * Obtiene el nombre del periodo por código.
     */
    public function obtenerPeriodoNombrePorCodigo($perCodigo)
    {
        $perCodigo = intval($perCodigo);
        if ($perCodigo <= 0) {
            return array(
                "resultado" => false,
                "mensaje" => "Parámetro inválido para consultar periodo.",
                "consola" => "perCodigo no válido en obtenerPeriodoNombrePorCodigo()."
            );
        }

        $sql = "SELECT per_nombre FROM periodo WHERE per_codigo = {$perCodigo}";
        if (!$this->cnx->consultar($sql)) {
            return array(
                "resultado" => false,
                "mensaje" => "Error al consultar el nombre del periodo.",
                "consola" => "Fallo SQL en obtenerPeriodoNombrePorCodigo()"
            );
        }

        if (count($this->cnx->json) < 1 || !isset($this->cnx->json[0]['per_nombre'])) {
            return array(
                "resultado" => false,
                "mensaje" => "No se encontró el nombre del periodo.",
                "consola" => "Sin resultados en obtenerPeriodoNombrePorCodigo()."
            );
        }

        return array(
            "resultado" => true,
            "mensaje" => "Periodo consultado correctamente.",
            "data" => array(
                "periodoNombre" => $this->cnx->json[0]['per_nombre']
            )
        );
    }

    /**
     * Obtiene total de horas de docencia (sin PP) desde espacio_ocupacion.
     */
    public function obtenerTotalHorasCatedraSinPractica($uapCodigo)
    {
        $uapCodigo = intval($uapCodigo);

        if ($uapCodigo <= 0) {
            return array(
                "resultado" => false,
                "mensaje" => "Parámetro inválido para consultar horas de cátedra.",
                "consola" => "uapCodigo no válido en obtenerTotalHorasCatedraSinPractica()."
            );
        }

        $sql = "SELECT
                COUNT(*) as totalhora
            FROM
                espacio_ocupacion eso
            INNER JOIN curso cur ON cur.cur_codigo = eso.eso_actividad
            INNER JOIN asignatura asi ON cur.asi_codigo = asi.asi_codigo AND asi.car_codigo != 'PP'
            WHERE
                eso.uap_codigo = {$uapCodigo}
        ";

        if (!$this->cnx->consultar($sql)) {
            return array(
                "resultado" => false,
                "mensaje" => "Error al consultar horas de cátedra del docente.",
                "consola" => "Fallo SQL en obtenerTotalHorasCatedraSinPractica()"
            );
        }

        $totalHoras = 0;
        if (count($this->cnx->json) > 0 && isset($this->cnx->json[0]['totalhora'])) {
            $totalHoras = floatval($this->cnx->json[0]['totalhora']);
        }

        return array(
            "resultado" => true,
            "mensaje" => "Horas de cátedra consultadas correctamente.",
            "data" => array(
                "totalHoras" => $totalHoras
            )
        );
    }

    /**
     * Obtiene horas de práctica pedagógica (semanales y totales por factor) de un docente.
     */
    public function obtenerHorasPracticaPedagogica($uapCodigo)
    {
        $uapCodigo = intval($uapCodigo);

        if ($uapCodigo <= 0) {
            return array(
                "resultado" => false,
                "mensaje" => "Parámetro inválido para consultar práctica pedagógica.",
                "consola" => "uapCodigo no válido en obtenerHorasPracticaPedagogica()."
            );
        }

        $sql = "SELECT
                ISNULL(SUM(agp.numero_total_hora/agp.semanas), 0) as hrsemanal,
                ISNULL(SUM(agp.factor), 0) as totalpp
            FROM
                agenda_periodo agp
            WHERE
                agp.uap_codigo = {$uapCodigo}
                and agp.caracter = 'PP'
        ";

        if (!$this->cnx->consultar($sql)) {
            return array(
                "resultado" => false,
                "mensaje" => "Error al consultar práctica pedagógica del docente.",
                "consola" => "Fallo SQL en obtenerHorasPracticaPedagogica()"
            );
        }

        $horasSemanal = 0;
        $totalPP = 0;
        if (count($this->cnx->json) > 0) {
            if (isset($this->cnx->json[0]['hrsemanal'])) {
                $horasSemanal = floatval($this->cnx->json[0]['hrsemanal']);
            }
            if (isset($this->cnx->json[0]['totalpp'])) {
                $totalPP = floatval($this->cnx->json[0]['totalpp']);
            }
        }

        return array(
            "resultado" => true,
            "mensaje" => "Horas de práctica pedagógica consultadas correctamente.",
            "data" => array(
                "horasSemanal" => $horasSemanal,
                "totalPP" => $totalPP
            )
        );
    }

    /**
     * Obtiene horas semanales de agenda por vinculación.
     */
    public function obtenerHorasSemanalesAgendaPorVinculacion($uapCodigo, $vinCodigo)
    {
        $uapCodigo = intval($uapCodigo);
        $vinCodigo = intval($vinCodigo);

        if ($uapCodigo <= 0 || $vinCodigo <= 0) {
            return array(
                "resultado" => false,
                "mensaje" => "Parámetros inválidos para consultar horas de agenda por vinculación.",
                "consola" => "uapCodigo/vinCodigo no válidos en obtenerHorasSemanalesAgendaPorVinculacion()."
            );
        }

        $sql = "SELECT
                ISNULL(SUM(agp.numero_total_hora/agp.semanas), 0) as hrsemanal
            FROM
                agenda_periodo agp
            WHERE
                agp.uap_codigo = {$uapCodigo}
                and agp.vinculacion = {$vinCodigo}
        ";

        if (!$this->cnx->consultar($sql)) {
            return array(
                "resultado" => false,
                "mensaje" => "Error al consultar horas semanales de agenda por vinculación.",
                "consola" => "Fallo SQL en obtenerHorasSemanalesAgendaPorVinculacion()"
            );
        }

        $horasSemanal = 0;
        if (count($this->cnx->json) > 0 && isset($this->cnx->json[0]['hrsemanal'])) {
            $horasSemanal = floatval($this->cnx->json[0]['hrsemanal']);
        }

        return array(
            "resultado" => true,
            "mensaje" => "Horas semanales de agenda consultadas correctamente.",
            "data" => array(
                "horasSemanal" => $horasSemanal
            )
        );
    }

    /**
     * Obtiene topes semanales de cátedra por sede y el tope aplicable.
     */
    public function obtenerTopesSemanalesCatedra($uapSedCodigo)
    {
        $uapSedCodigo = intval($uapSedCodigo);

        if ($uapSedCodigo <= 0) {
            return array(
                "resultado" => false,
                "mensaje" => "Parámetro inválido para consultar topes de cátedra.",
                "consola" => "uapSedCodigo no válido en obtenerTopesSemanalesCatedra()."
            );
        }

        $sql = "SELECT
                MAX(CASE WHEN wep.wep_codigo = 210 THEN wep.wep_valor END) as topeSedes,
                MAX(CASE WHEN wep.wep_codigo = 485 THEN wep.wep_valor END) as topeNeiva
            FROM web_parametro wep
            WHERE wep.wep_codigo IN (210, 485)
        ";

        if (!$this->cnx->consultar($sql)) {
            return array(
                "resultado" => false,
                "mensaje" => "Error al consultar topes semanales de cátedra.",
                "consola" => "Fallo SQL en obtenerTopesSemanalesCatedra()"
            );
        }

        $topeSedes = 0;
        $topeNeiva = 0;
        if (count($this->cnx->json) > 0) {
            if (isset($this->cnx->json[0]['topeSedes'])) {
                $topeSedes = floatval($this->cnx->json[0]['topeSedes']);
            }
            if (isset($this->cnx->json[0]['topeNeiva'])) {
                $topeNeiva = floatval($this->cnx->json[0]['topeNeiva']);
            }
        }

        return array(
            "resultado" => true,
            "mensaje" => "Topes semanales de cátedra consultados correctamente.",
            "data" => array(
                "topeSedes" => $topeSedes,
                "topeNeiva" => $topeNeiva,
                "topeAplicado" => $uapSedCodigo != 1 ? $topeSedes : $topeNeiva
            )
        );
    }

    /**
     * Obtiene carga complementaria SEMANAL (proyectos + novedades) de un docente para un periodo.
     */
    public function obtenerCargaComplementariaSemanal($personaCodigo, $periodoCodigo, $soloNovedadesActivas = true)
    {
        $personaCodigo = intval($personaCodigo);
        $periodoCodigo = intval($periodoCodigo);

        if ($personaCodigo <= 0 || $periodoCodigo <= 0) {
            return array(
                "resultado" => false,
                "mensaje" => "Parámetros inválidos para calcular carga semanal complementaria.",
                "consola" => "personaCodigo/peridoCodigo no válidos en obtenerCargaComplementariaSemanal()."
            );
        }

        $sqlProyectos = "SELECT
                ISNULL(SUM(CAST(pep.pep_hora_semana AS FLOAT)), 0) total
            FROM
                proyecto pro
            INNER JOIN proyecto_tipo prt ON prt.prt_codigo = pro.prt_codigo
            INNER JOIN persona_proyecto pep ON pro.pry_codigo = pep.pry_codigo
            INNER JOIN periodo per ON per.per_codigo = pep.per_codigo
            WHERE
                pep.pep_persona = {$personaCodigo}
                AND per.per_codigo = {$periodoCodigo}
        ";

        if (!$this->cnx->consultar($sqlProyectos)) {
            return array(
                "resultado" => false,
                "mensaje" => "Error al consultar horas semanales de proyectos del docente.",
                "consola" => "Fallo SQL en obtenerCargaComplementariaSemanal() -> proyectos"
            );
        }

        $proyectosSemanal = 0;
        $rProyectos = $this->cnx->json;
        if (count($rProyectos) > 0 && isset($rProyectos[0]['total'])) {
            $proyectosSemanal = floatval($rProyectos[0]['total']);
        }

        $whereNovedadEstado = $soloNovedadesActivas ? "AND pen.pen_estado = 1" : "";
        $sqlNovedades = "SELECT
                ISNULL(SUM(CAST(pen.pen_descarga_semanal AS FLOAT)), 0) total
            FROM
                persona_novedad pen
            INNER JOIN novedad nov ON pen.nov_codigo = nov.nov_codigo
            INNER JOIN periodo per ON per.per_codigo = pen.per_codigo
            WHERE
                pen.pen_persona = {$personaCodigo}
                AND per.per_codigo = {$periodoCodigo}
                {$whereNovedadEstado}
        ";

        if (!$this->cnx->consultar($sqlNovedades)) {
            return array(
                "resultado" => false,
                "mensaje" => "Error al consultar horas semanales de novedades del docente.",
                "consola" => "Fallo SQL en obtenerCargaComplementariaSemanal() -> novedades"
            );
        }

        $novedadesSemanal = 0;
        $rNovedades = $this->cnx->json;
        if (count($rNovedades) > 0 && isset($rNovedades[0]['total'])) {
            $novedadesSemanal = floatval($rNovedades[0]['total']);
        }

        return array(
            "resultado" => true,
            "mensaje" => "Carga semanal complementaria consultada correctamente.",
            "data" => array(
                "proyectosSemanal" => $proyectosSemanal,
                "novedadesSemanal" => $novedadesSemanal,
                "totalSemanal" => $proyectosSemanal + $novedadesSemanal
            )
        );
    }

    /**
     * Obtiene carga complementaria SEMESTRAL (proyectos + novedades) de un docente para un periodo.
     */
    public function obtenerCargaComplementariaSemestral($personaCodigo, $periodoCodigo, $soloNovedadesActivas = true)
    {
        $personaCodigo = intval($personaCodigo);
        $periodoCodigo = intval($periodoCodigo);

        if ($personaCodigo <= 0 || $periodoCodigo <= 0) {
            return array(
                "resultado" => false,
                "mensaje" => "Parámetros inválidos para calcular carga semestral complementaria.",
                "consola" => "personaCodigo/peridoCodigo no válidos en obtenerCargaComplementariaSemestral()."
            );
        }

        $sqlProyectos = "SELECT
                ISNULL(SUM(CAST(pep.pep_hora_semana * pep.pep_semanas AS FLOAT)), 0) total
            FROM
                proyecto pro
            INNER JOIN proyecto_tipo prt ON prt.prt_codigo = pro.prt_codigo
            INNER JOIN persona_proyecto pep ON pro.pry_codigo = pep.pry_codigo
            INNER JOIN periodo per ON per.per_codigo = pep.per_codigo
            WHERE
                pep.pep_persona = {$personaCodigo}
                AND per.per_codigo = {$periodoCodigo}
        ";

        if (!$this->cnx->consultar($sqlProyectos)) {
            return array(
                "resultado" => false,
                "mensaje" => "Error al consultar horas semestrales de proyectos del docente.",
                "consola" => "Fallo SQL en obtenerCargaComplementariaSemestral() -> proyectos"
            );
        }

        $proyectosSemestral = 0;
        $rProyectos = $this->cnx->json;
        if (count($rProyectos) > 0 && isset($rProyectos[0]['total'])) {
            $proyectosSemestral = floatval($rProyectos[0]['total']);
        }

        $whereNovedadEstado = $soloNovedadesActivas ? "AND pen.pen_estado = 1" : "";
        $sqlNovedades = "SELECT
                ISNULL(SUM(CAST(pen.pen_descarga_semestral AS FLOAT)), 0) total
            FROM
                persona_novedad pen
            INNER JOIN novedad nov ON pen.nov_codigo = nov.nov_codigo
            INNER JOIN periodo per ON per.per_codigo = pen.per_codigo
            WHERE
                pen.pen_persona = {$personaCodigo}
                AND per.per_codigo = {$periodoCodigo}
                {$whereNovedadEstado}
        ";

        if (!$this->cnx->consultar($sqlNovedades)) {
            return array(
                "resultado" => false,
                "mensaje" => "Error al consultar horas semestrales de novedades del docente.",
                "consola" => "Fallo SQL en obtenerCargaComplementariaSemestral() -> novedades"
            );
        }

        $novedadesSemestral = 0;
        $rNovedades = $this->cnx->json;
        if (count($rNovedades) > 0 && isset($rNovedades[0]['total'])) {
            $novedadesSemestral = floatval($rNovedades[0]['total']);
        }

        return array(
            "resultado" => true,
            "mensaje" => "Carga semestral complementaria consultada correctamente.",
            "data" => array(
                "proyectosSemestral" => $proyectosSemestral,
                "novedadesSemestral" => $novedadesSemestral,
                "totalSemestral" => $proyectosSemestral + $novedadesSemestral
            )
        );
    }

    /**
     * Calcula el pico de horas semanales reales del docente por fechas y horas programadas.
     */
    public function calcularPicoSemanalCatedra($uapCodigo, $listaHorarioSeleccionado = array())
    {
        $uapCodigo = intval($uapCodigo);
        if ($uapCodigo <= 0) {
            return array(
                "resultado" => false,
                "mensaje" => "Parámetro inválido para calcular pico semanal.",
                "consola" => "uapCodigo no válido en calcularPicoSemanalCatedra()."
            );
        }

        $normalizarFecha = function ($valorFecha) {
            $iso = FechaSqlServer::normalizarIso8601($valorFecha, false);
            if ($iso === false) {
                return "";
            }

            return substr($iso, 0, 10);
        };

        $sql = "SELECT
                CONVERT(date, eso.eso_fecha) EsoFecha,
                eso.hra_codigo HoraCodigo
            FROM espacio_ocupacion eso
            WHERE
                eso.uap_codigo = {$uapCodigo}
                AND eso.eso_actividad != ''
        ";

        if (!$this->cnx->consultar($sql)) {
            return array(
                "resultado" => false,
                "mensaje" => "Error al calcular el pico semanal del docente.",
                "consola" => "No fue posible consultar el horario actual del docente {$uapCodigo}."
            );
        }

        $horasPorSemanaActual = array();
        $horasPorSemana = array();
        $horasUnicas = array();
        $horasNuevasAgregadas = 0;

        foreach ($this->cnx->json as $horario) {
            $fecha = isset($horario["EsoFecha"]) ? $normalizarFecha($horario["EsoFecha"]) : "";
            $horaCodigo = isset($horario["HoraCodigo"]) ? trim($horario["HoraCodigo"]) : "";

            if ($fecha == "" || $horaCodigo == "") {
                continue;
            }

            $llaveHora = $fecha . "|" . $horaCodigo;
            if (isset($horasUnicas[$llaveHora])) {
                continue;
            }

            $date = DateTime::createFromFormat('Y-m-d', $fecha);
            if (!$date) {
                continue;
            }

            $semana = $date->format('o-W');
            if (!isset($horasPorSemanaActual[$semana])) {
                $horasPorSemanaActual[$semana] = 0;
            }
            $horasPorSemanaActual[$semana]++;

            if (!isset($horasPorSemana[$semana])) {
                $horasPorSemana[$semana] = 0;
            }
            $horasPorSemana[$semana]++;
            $horasUnicas[$llaveHora] = true;
        }

        foreach ($listaHorarioSeleccionado as $horarioNuevo) {
            $fechaHora = isset($horarioNuevo->EsoFecha) ? trim($horarioNuevo->EsoFecha) : "";
            $horaCodigo = isset($horarioNuevo->HoraCodigo) ? trim($horarioNuevo->HoraCodigo) : "";
            if ($horaCodigo == "" && isset($horarioNuevo->HraCodigo)) {
                $horaCodigo = trim($horarioNuevo->HraCodigo);
            }

            $fecha = $normalizarFecha($fechaHora);
            if ($fecha == "" || $horaCodigo == "") {
                continue;
            }

            $llaveHora = $fecha . "|" . $horaCodigo;
            if (isset($horasUnicas[$llaveHora])) {
                continue;
            }

            $date = DateTime::createFromFormat('Y-m-d', $fecha);
            if (!$date) {
                continue;
            }

            $semana = $date->format('o-W');
            if (!isset($horasPorSemana[$semana])) {
                $horasPorSemana[$semana] = 0;
            }
            $horasPorSemana[$semana]++;
            $horasUnicas[$llaveHora] = true;
            $horasNuevasAgregadas++;
        }

        $picoSemanalActual = 0;
        foreach ($horasPorSemanaActual as $totalSemana) {
            if ($totalSemana > $picoSemanalActual) {
                $picoSemanalActual = $totalSemana;
            }
        }

        $picoSemanal = 0;
        foreach ($horasPorSemana as $totalSemana) {
            if ($totalSemana > $picoSemanal) {
                $picoSemanal = $totalSemana;
            }
        }

        return array(
            "resultado" => true,
            "mensaje" => "Pico semanal calculado correctamente.",
            "data" => array(
                "PicoSemanalActual" => $picoSemanalActual,
                "PicoSemanal" => $picoSemanal,
                "HorasNuevasAgregadas" => $horasNuevasAgregadas,
            )
        );
    }

    /**
     * Calcula el pico total semanal (pico real docencia + investigación + proyección + gestión).
     */
    public function calcularPicoTotalSemanal($uapCodigo, $periodoNombre, $facultadCodigo, $listaHorarioSeleccionado = array())
    {
        $rPico = $this->calcularPicoSemanalCatedra($uapCodigo, $listaHorarioSeleccionado);
        if (!$rPico["resultado"]) {
            return $rPico;
        }

        $rDetalle = $this->obtenerCargaDetalladaDocente($uapCodigo, $periodoNombre, $facultadCodigo);
        if (!$rDetalle["resultado"]) {
            return $rDetalle;
        }

        $complementoSemanal = floatval($rDetalle["data"]["horasInvestigacionSemanal"]) +
            floatval($rDetalle["data"]["horasProyeccionSemanal"]) +
            floatval($rDetalle["data"]["horasGestionSemanal"]);

        $picoDocenciaActual = floatval($rPico["data"]["PicoSemanalActual"]);
        $picoDocencia = floatval($rPico["data"]["PicoSemanal"]);

        return array(
            "resultado" => true,
            "mensaje" => "Pico total semanal calculado correctamente.",
            "data" => array(
                "PicoDocenciaActual" => $picoDocenciaActual,
                "PicoDocencia" => $picoDocencia,
                "ComplementoSemanal" => $complementoSemanal,
                "PicoTotalActual" => $picoDocenciaActual + $complementoSemanal,
                "PicoTotal" => $picoDocencia + $complementoSemanal
            )
        );
    }

    /**
     * Calcula el factor de carga académica según la facultad y características del curso.
     * Centraliza las reglas de negocio de Ingeniería, Salud, y Facultades de Humanidades/Educación/Admin.
     */
    public function calcularFactorCarga($uaaDependencia, $carCodigo, $subGrupo, $horasSemanales, $semanas, $asiCreditosTeoria, $asiCreditosPractica, $uaaProgramada = null)
    {
        $factor = 0;
        $uaaDependencia = intval($uaaDependencia);
        $carCodigo = trim($carCodigo);

        // Facultad de INGENIERÍA (21)
        if ($uaaDependencia == 21) {
            if ($carCodigo == "T") {
                $factor = ($asiCreditosTeoria * 3) * $semanas;
            } else if ($carCodigo == "TP") {
                if ($subGrupo == "00") {
                    $factor = ($asiCreditosTeoria * 3) * $semanas;
                } else {
                    $factor = ($asiCreditosPractica * 3) * $semanas;
                }
            } else if (in_array($carCodigo, ["P", "PP", "PF"])) {
                $factor = $horasSemanales * 1;
            } else {
                $factor = $semanas; // Por defecto
            }
        }
        // Facultades: ECONOMIA (19), EDUCACION (20), CIENCIAS EXACTAS (22), SOCIALES (24)
        else if (in_array($uaaDependencia, [19, 20, 22, 24])) {
            if ($carCodigo == "T") {
                $factor = ($asiCreditosTeoria * 3) * $semanas;
            } else if ($carCodigo == "TP") {
                if ($subGrupo == "00") {
                    $factor = ($asiCreditosTeoria * 3) * $semanas;
                } else {
                    $factor = ($asiCreditosPractica * 3) * $semanas;
                }
            } else {
                $factor = $semanas * 1.5;
            }
        }
        // Facultad de SALUD (23) o programas específicos
        else if ($uaaDependencia == 23 || $uaaProgramada == 715 || $uaaProgramada == 706) {
            if ($carCodigo == "T") {
                $factor = ($horasSemanales * 2) + 1 * $semanas;
            } else if ($carCodigo == "TP") {
                $factor = ($horasSemanales * 1.5) + 1 * $semanas;
            } else {
                $factor = $horasSemanales * 1;
            }
        } else {
            // Regla por defecto si no coincide con ninguna específica
            $factor = $horasSemanales * 1;
        }

        return $factor;
    }

    /**
     * Obtiene el total de factor acumulado en agenda_periodo para un docente y periodo.
     */
    public function obtenerTotalFactorAgenda($uapPerCodigo, $calCodigo)
    {
        $uapPerCodigo = intval($uapPerCodigo);
        $calCodigo = intval($calCodigo);

        $sql = "SELECT 
                SUM(ag.factor) as total 
            FROM 
                curso cur 
            INNER JOIN agenda_periodo ag ON cur.cur_codigo = ag.cur_codigo and ag.per_codigo = {$uapPerCodigo}
            INNER JOIN calendario cal ON cal.cal_codigo = cur.cal_codigo and cal.cal_codigo = {$calCodigo}
        ";

        if (!$this->cnx->consultar($sql)) {
            return array(
                "resultado" => false,
                "mensaje" => "Error al consultar el total de factor acumulado en agenda.",
                "consola" => "Fallo SQL en obtenerTotalFactorAgenda()"
            );
        }

        $totalFactor = 0;
        if (count($this->cnx->json) > 0 && isset($this->cnx->json[0]['total'])) {
            $totalFactor = floatval($this->cnx->json[0]['total']);
        }

        return array(
            "resultado" => true,
            "data" => array(
                "totalFactor" => $totalFactor
            )
        );
    }

    /**
     * Obtiene la carga detallada del docente (Docencia, Investigación, Proyección, Gestión).
     * Réplica de la lógica de AgendocClase.php para mostrar en el modal de Cambdocente.
     */
    public function obtenerCargaDetalladaDocente($uapCodigo, $periodoNombre, $facultadCodigo)
    {
        $uapCodigo = intval($uapCodigo);
        $periodoNombre = trim($periodoNombre);
        $facultadCodigo = intval($facultadCodigo);

        if ($uapCodigo <= 0 || $periodoNombre == '') {
            return array(
                "resultado" => false,
                "mensaje" => "ParÃ¡metros invÃ¡lidos para consultar la carga detallada del docente.",
                "consola" => "uapCodigo/periodoNombre no vÃ¡lidos en obtenerCargaDetalladaDocente()."
            );
        }

        // Obtener persona_codigo desde uap_codigo
        $personaCodigo = 0;
        $sqlPer = "SELECT per_codigo FROM uaa_personal WHERE uap_codigo = {$uapCodigo}";
        if (!$this->cnx->consultar($sqlPer)) {
            return array(
                "resultado" => false,
                "mensaje" => "Error al consultar la persona asociada a la vinculaciÃ³n docente.",
                "consola" => "Fallo SQL en obtenerCargaDetalladaDocente() -> uaa_personal para uap_codigo {$uapCodigo}."
            );
        }

        if (count($this->cnx->json) < 1 || !isset($this->cnx->json[0]['per_codigo'])) {
            return array(
                "resultado" => false,
                "mensaje" => "No se encontrÃ³ la persona asociada a la vinculaciÃ³n docente.",
                "consola" => "Sin resultados en obtenerCargaDetalladaDocente() para uap_codigo {$uapCodigo}."
            );
        }
        $personaCodigo = intval($this->cnx->json[0]['per_codigo']);

        $periodosNombreArreglo = " '{$periodoNombre}' ";
        $calendarioCodigoArreglo = '';

        // Manejo de casos especiales de Salud (réplica de AgendocClase.php)
        if ($facultadCodigo == 23 || $facultadCodigo == 330 || $facultadCodigo == 329) {
            if ($periodoNombre == '20202') {
                $calendarioCodigoArreglo = '204,210';
                $periodosNombreArreglo = " '20202', '20211' ";
            } else if ($periodoNombre == '20211') {
                $calendarioCodigoArreglo = '208,211';
                $periodosNombreArreglo = " '20211', '20212' ";
            } else if ($periodoNombre == '20212') {
                $calendarioCodigoArreglo = '213,212';
                $periodosNombreArreglo = " '20212', '20221' ";
            } else if ($periodoNombre == '20221') {
                $calendarioCodigoArreglo = '216,218';
                $periodosNombreArreglo = " '20221', '20222' ";
            } else if ($periodoNombre == '20222') {
                $calendarioCodigoArreglo = '219,220';
                $periodosNombreArreglo = " '20222', '20231' ";
            } else if ($periodoNombre == '20231') {
                $calendarioCodigoArreglo = '223';
                $periodosNombreArreglo = " '20231' ";
            }
        }

        // 1. DOCENCIA (Agenda + Novedades tipo 11)
        // Nota: Se usa la misma lógica de AgendocClase (sumatoria en PHP).
        $sqlDocencia = "SELECT
                agp.factor AgpFactor,
                cal.cal_codigo CalCodigo,
                (SELECT COUNT(*) FROM espacio_ocupacion_total eso
                    WHERE eso.eso_actividad = agp.cur_codigo
                        AND eso.eso_subgrupo = agp.sub_grupo
                        AND eso.uap_codigo = agp.uap_codigo
                ) / CAST(NULLIF(agp.semanas, 0) AS FLOAT) HorasPorSemana
            FROM agenda_periodo agp
            INNER JOIN curso cur ON cur.cur_codigo = agp.cur_codigo
            INNER JOIN calendario cal ON cal.cal_codigo = cur.cal_codigo
            INNER JOIN periodo per ON per.per_codigo = cal.per_codigo
            WHERE agp.uap_codigo = {$uapCodigo}
                AND per.per_nombre IN ({$periodosNombreArreglo})
        ";

        $horasDocenciaSemestre = 0;
        $horasDocenciaSemana = 0;

        if (!$this->cnx->consultar($sqlDocencia)) {
            return array(
                "resultado" => false,
                "mensaje" => "Error al consultar horas de docencia del docente.",
                "consola" => "Fallo SQL en obtenerCargaDetalladaDocente() -> docencia"
            );
        }

        $r = $this->cnx->json;
        if (count($r) > 0) {
            foreach ($r as $row) {
                if ($calendarioCodigoArreglo != '') {
                    $calPermitidos = explode(",", $calendarioCodigoArreglo);
                    if (!in_array($row['CalCodigo'], $calPermitidos)) {
                        continue;
                    }
                }

                $horasDocenciaSemestre += floatval($row['AgpFactor']);
                $horasDocenciaSemana += floatval($row['HorasPorSemana']);
            }
        }

        $sqlNovDocencia = "SELECT 
                ISNULL(SUM(pern.pen_descarga_semestral), 0) AS semestre,
                ISNULL(SUM(pern.pen_descarga_semanal), 0) AS semanal
            FROM persona_novedad pern
            INNER JOIN novedad nov ON pern.nov_codigo = nov.nov_codigo
            INNER JOIN periodo per ON per.per_codigo = pern.per_codigo
            WHERE pern.pen_persona = {$personaCodigo}
                AND per.per_nombre = '{$periodoNombre}'
                AND pern.pen_estado = 1
                AND nov.not_codigo = 11
        ";

        if ($this->cnx->consultar($sqlNovDocencia)) {
            $r = $this->cnx->json;
            $horasDocenciaSemestre += floatval($r[0]['semestre']);
            $horasDocenciaSemana += floatval($r[0]['semanal']);
        }

        // 2. INVESTIGACIÓN (Proyectos pra=3 + Novedades tipo 7)
        $sqlProyInv = "SELECT 
                ISNULL(SUM(dxp.dpp_horas_semana * dxp.dpp_numero_semanas), 0) AS semestre,
                ISNULL(SUM(dxp.dpp_horas_semana), 0) AS semanal
            FROM proyectos.proyecto_proyeccion_social pps
            INNER JOIN proyectos.docentexproyecto_proyeccion_social dxp ON pps.pps_codigo = dxp.pps_codigo
            INNER JOIN uaa_personal uap ON uap.uap_codigo = dxp.uap_codigo
            INNER JOIN periodo per ON per.per_codigo = dxp.dpp_periodo
            WHERE uap.uap_codigo = {$uapCodigo}
                AND per.per_nombre = '{$periodoNombre}'
                AND pps.pra_codigo = 3
        ";

        $horasInvSemestre = 0;
        $horasInvSemana = 0;

        if ($this->cnx->consultar($sqlProyInv)) {
            $r = $this->cnx->json;
            $horasInvSemestre = floatval($r[0]['semestre']);
            $horasInvSemana = floatval($r[0]['semanal']);
        }

        $sqlNovInv = "SELECT 
                ISNULL(SUM(pern.pen_descarga_semestral), 0) AS semestre,
                ISNULL(SUM(pern.pen_descarga_semanal), 0) AS semanal
            FROM persona_novedad pern
            INNER JOIN novedad nov ON pern.nov_codigo = nov.nov_codigo
            INNER JOIN periodo per ON per.per_codigo = pern.per_codigo
            WHERE pern.pen_persona = {$personaCodigo}
                AND per.per_nombre = '{$periodoNombre}'
                AND pern.pen_estado = 1
                AND nov.not_codigo = 7
        ";

        if ($this->cnx->consultar($sqlNovInv)) {
            $r = $this->cnx->json;
            $horasInvSemestre += floatval($r[0]['semestre']);
            $horasInvSemana += floatval($r[0]['semanal']);
        }

        // 3. PROYECCIÓN SOCIAL (Proyectos pra=4 + Novedades tipo 8)
        $sqlProySoc = "SELECT 
                ISNULL(SUM(dxp.dpp_horas_semana * dxp.dpp_numero_semanas), 0) AS semestre,
                ISNULL(SUM(dxp.dpp_horas_semana), 0) AS semanal
            FROM proyectos.proyecto_proyeccion_social pps
            INNER JOIN proyectos.docentexproyecto_proyeccion_social dxp ON pps.pps_codigo = dxp.pps_codigo
            INNER JOIN uaa_personal uap ON uap.uap_codigo = dxp.uap_codigo
            INNER JOIN periodo per ON per.per_codigo = dxp.dpp_periodo
            WHERE uap.uap_codigo = {$uapCodigo}
                AND per.per_nombre = '{$periodoNombre}'
                AND pps.pra_codigo = 4
        ";

        $horasSocSemestre = 0;
        $horasSocSemana = 0;

        if ($this->cnx->consultar($sqlProySoc)) {
            $r = $this->cnx->json;
            $horasSocSemestre = floatval($r[0]['semestre']);
            $horasSocSemana = floatval($r[0]['semanal']);
        }

        $sqlNovSoc = "SELECT 
                ISNULL(SUM(pern.pen_descarga_semestral), 0) AS semestre,
                ISNULL(SUM(pern.pen_descarga_semanal), 0) AS semanal
            FROM persona_novedad pern
            INNER JOIN novedad nov ON pern.nov_codigo = nov.nov_codigo
            INNER JOIN periodo per ON per.per_codigo = pern.per_codigo
            WHERE pern.pen_persona = {$personaCodigo}
                AND per.per_nombre = '{$periodoNombre}'
                AND pern.pen_estado = 1
                AND nov.not_codigo = 8
        ";

        if ($this->cnx->consultar($sqlNovSoc)) {
            $r = $this->cnx->json;
            $horasSocSemestre += floatval($r[0]['semestre']);
            $horasSocSemana += floatval($r[0]['semanal']);
        }

        // 4. GESTIÓN ADMINISTRATIVA (Novedades tipo 9)
        $sqlNovGes = "SELECT 
                ISNULL(SUM(pern.pen_descarga_semestral), 0) AS semestre,
                ISNULL(SUM(pern.pen_descarga_semanal), 0) AS semanal
            FROM persona_novedad pern
            INNER JOIN novedad nov ON pern.nov_codigo = nov.nov_codigo
            INNER JOIN periodo per ON per.per_codigo = pern.per_codigo
            WHERE pern.pen_persona = {$personaCodigo}
                AND per.per_nombre = '{$periodoNombre}'
                AND pern.pen_estado = 1
                AND nov.not_codigo = 9
        ";

        $horasGesSemestre = 0;
        $horasGesSemana = 0;

        if ($this->cnx->consultar($sqlNovGes)) {
            $r = $this->cnx->json;
            $horasGesSemestre = floatval($r[0]['semestre']);
            $horasGesSemana = floatval($r[0]['semanal']);
        }

        $totalSemanal = $horasDocenciaSemana + $horasInvSemana + $horasSocSemana + $horasGesSemana;
        $totalSemestre = $horasDocenciaSemestre + $horasInvSemestre + $horasSocSemestre + $horasGesSemestre;

        return array(
            "resultado" => true,
            "data" => array(
                "horasDocencia" => $horasDocenciaSemestre,
                "horasInvestigacion" => $horasInvSemestre,
                "horasProyeccion" => $horasSocSemestre,
                "horasGestion" => $horasGesSemestre,
                "totalSemestre" => $totalSemestre,
                "horasDocenciaSemanal" => round($horasDocenciaSemana, 2),
                "horasInvestigacionSemanal" => round($horasInvSemana, 2),
                "horasProyeccionSemanal" => round($horasSocSemana, 2),
                "horasGestionSemanal" => round($horasGesSemana, 2),
                "totalSemanal" => round($totalSemanal, 2)
            )
        );
    }
}
