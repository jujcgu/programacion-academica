<?php
date_default_timezone_set('America/Bogota');
require_once(dirname(__FILE__) . '/servicios/ValidarCargaDocenteService.php');

class Obsdocente
{

    private $cnx = null;

    private $errorConectarBd = array(
        "resultado" => false,
        "mensaje" => "Error al conectar con la base de datos",
        "consola" => "Metodo conectar() en bd",
    );
    private $errorConsultarBd = array(
        "resultado" => false,
        "mensaje" => "Error al consultar la base de datos",
        "consola" => "",
    );
    private $errorSentenciaBd = array(
        "resultado" => false,
        "mensaje" => "",
        "consola" => "",
    );

    public function __construct()
    {
        //Verificamos que se encuentr el archivo de conexion a la base de datos.
        if (!file_exists("../conexion/cls_config.php")) {
            echo "Archivo de conexion no encontrado";
            die;
        }
        require_once "../conexion/cls_config.php";
        $this->cnx = new cls_config();
    }

    private function tieneCargaDocenteMayorACero($carga)
    {
        if (!is_array($carga)) {
            return false;
        }

        foreach ($carga as $clave => $valor) {
            $claveNormalizada = strtolower($clave);
            $esCampoDeCarga = stripos($claveNormalizada, 'hora') !== false
                || stripos($claveNormalizada, 'total') !== false
                || stripos($claveNormalizada, 'carga') !== false;

            if ($esCampoDeCarga && is_numeric($valor) && floatval($valor) > 0) {
                return true;
            }
        }

        if (isset($carga["totalSemestre"]) && is_numeric($carga["totalSemestre"]) && floatval($carga["totalSemestre"]) > 0) {
            return true;
        }

        if (isset($carga["totalSemanal"]) && is_numeric($carga["totalSemanal"]) && floatval($carga["totalSemanal"]) > 0) {
            return true;
        }

        return false;
    }

    // Obtiene un ag_id estable (MIN idagenda) asociado a la vinculación y periodo.
    private function consultarAgIdPorVinculacion($PersonaCodigo, $UapCodigo, $PeriodoCodigo)
    {
        $sql = "SELECT
                MIN(agp.idagenda) AgId
            FROM agenda_periodo agp
            INNER JOIN uaa_personal uap ON uap.per_codigo = agp.per_codigo AND uap.uap_codigo = agp.uap_codigo
            INNER JOIN curso cur ON cur.cur_codigo = agp.cur_codigo
            INNER JOIN calendario cal ON cal.cal_codigo = cur.cal_codigo
            WHERE
                agp.per_codigo = {$PersonaCodigo}
                AND agp.uap_codigo = {$UapCodigo}
                AND cal.per_codigo = {$PeriodoCodigo}";

        if (!$this->cnx->consultar($sql)) {
            return array(
                "resultado" => false,
                "mensaje" => "Error al consultar la agenda de la vinculación seleccionada.",
                "consola" => "Error al consultar idagenda para persona {$PersonaCodigo}, uap {$UapCodigo}, periodo {$PeriodoCodigo}."
            );
        }

        $agId = (count($this->cnx->json) > 0 && isset($this->cnx->json[0]["AgId"]) && $this->cnx->json[0]["AgId"] !== null) ? $this->cnx->json[0]["AgId"] : "NULL";
        return array(
            "resultado" => true,
            "AgId" => $agId
        );
    }

    //Inicio funcion consultarPeriodos
    //Se usa para consultar los ultimos 10 periodos activos.
    function consultarPeriodos()
    {
        // Validaciones

        $sql = "SELECT TOP 6
            per.per_codigo PerCodigo,
            per.per_nombre PerNombre
		FROM 
            periodo per
        WHERE
            per.per_nombre != 'desconocido'
		ORDER BY per.per_nombre DESC
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error en consultar los 10 periodos mas recientes";
            return $this->errorConsultarBd;
        }

        return array(
            "resultado" => true,
            "mensaje" => "Periodos consultados correctamente.",
            "count" => count($this->cnx->json),
            "data" => $this->cnx->json
        );
    }

    //Inicio funcion consultarDocentes
    //Se usa para consultar los docentes de un periodo especifico.
    function consultarDocentes($obj)
    {
        //Validaciones
        if (!isset($obj->PerCodigo) || !is_numeric($obj->PerCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo del periodo.",
                "consola" => "El codigo del periodo no viene o no es numerico, " . $obj->PerCodigo,
            );
        }
        if (!isset($obj->Busqueda) || $obj->Busqueda == '') {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio la cedula, nombre o apellido del docente.",
                "consola" => "La cedula, nombre o apellido del docente no viene, " . $obj->Busqueda,
            );
        }

        $PerCodigo = $obj->PerCodigo; //Contiene el codigo del periodo a buscar.
        $Busqueda = str_replace("'", "''", trim($obj->Busqueda)); //Contiene el filtro para buscar los docentes, puede ser una cedula, nombre o apellido del docente.
        $servicioCargaDocente = new ValidarCargaDocenteService($this->cnx);
        $periodo = $servicioCargaDocente->obtenerPeriodoNombrePorCodigo($PerCodigo);
        if (!$periodo["resultado"]) {
            return $periodo;
        }
        $PeriodoNombre = $periodo["data"]["periodoNombre"];

        $sql = "SELECT 
                persona.per_codigo PerCodigo,
                persona.per_identificacion PerIdentificacion,
                persona.per_apellido PerApellido,
                persona.per_nombre PerNombre,
                persona.per_nombre + ' ' + persona.per_apellido PerNombreCompleto,
                uap.uap_codigo UapCodigo,
                vin.vin_nombre VinNombre,
                ded.ded_nombre DedNombre,
                uaa.uaa_codigo UaaCodigo,
                uaa.uaa_nombre_corto UaaNombreCorto,
                CONVERT(varchar, uap.uap_fecha_inicio, 23) UapFechaInicio,
                CONVERT(varchar, uap.uap_fecha_fin, 23) UapFechaFin
            FROM 
                uaa_personal uap 
            INNER JOIN persona ON uap.per_codigo = persona.per_codigo
            INNER JOIN vinculacion vin ON vin.vin_codigo = uap.vin_codigo
            INNER JOIN dedicacion ded ON ded.ded_codigo = uap.ded_codigo
            INNER JOIN periodo perFiltro ON perFiltro.per_codigo = {$PerCodigo}
            LEFT JOIN uaa ON uaa.uaa_codigo = uap.uaa_codigo
            WHERE
                (
                    persona.per_identificacion like '%{$Busqueda}%'
                    OR persona.per_nombre + ' ' + persona.per_apellido like '%{$Busqueda}%'
                )
                AND (
                    (
                        uap.uap_fecha_inicio <= perFiltro.per_fecha_fin
                        AND (
                            uap.uap_fecha_fin IS NULL
                            OR uap.uap_fecha_fin >= perFiltro.per_fecha_inicio
                        )
                    )
                    OR EXISTS (
                        SELECT 1
                        FROM agenda_periodo agp
                        INNER JOIN curso cur ON cur.cur_codigo = agp.cur_codigo
                        INNER JOIN calendario cal ON cal.cal_codigo = cur.cal_codigo
                        WHERE agp.uap_codigo = uap.uap_codigo
                            AND cal.per_codigo = {$PerCodigo}
                    )
                )
            GROUP BY 
                persona.per_codigo,
                persona.per_identificacion,
                persona.per_apellido,
                persona.per_nombre,
                persona.per_nombre + ' ' + persona.per_apellido,
                uap.uap_codigo,
                vin.vin_nombre,
                ded.ded_nombre,
                uaa.uaa_codigo,
                uaa.uaa_nombre_corto,
                CONVERT(varchar, uap.uap_fecha_inicio, 23),
                CONVERT(varchar, uap.uap_fecha_fin, 23)
            ORDER BY 
                persona.per_nombre + ' ' + persona.per_apellido,
                uap.uap_codigo
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error en consultar la lista de docentes.";
            $this->errorConsultarBd["errorSql"] = isset($this->cnx->mjeError) ? $this->cnx->mjeError : "";
            return $this->errorConsultarBd;
        }

        $candidatos = $this->cnx->json;
        $docentes = array();
        foreach ($candidatos as $docente) {
            $carga = $servicioCargaDocente->obtenerCargaDetalladaDocente($docente["UapCodigo"], $PeriodoNombre, 0);
            if (!$carga["resultado"]) {
                $carga["consola"] = $carga["consola"] . " UapCodigo evaluado en Obsdocente::consultarDocentes(): " . $docente["UapCodigo"] . ".";
                return $carga;
            }

            $docente["CargaDocente"] = $carga["data"];
            $docente["TieneCarga"] = $this->tieneCargaDocenteMayorACero($carga["data"]);
            $docentes[] = $docente;
        }

        return array(
            "resultado" => true,
            "mensaje" => "Docentes consultados correctamente.",
            "count" => count($docentes),
            "data" => $docentes
        );
    }

    //Inicio funcion consultarObservaciones
    //Se usa para consultar las observaciones de un docente en un periodo en especifico.
    function consultarObservaciones($obj)
    {
        //validaciones
        if (!isset($obj->PersonaCodigo) || !is_numeric($obj->PersonaCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo de la persona.",
                "consola" => "El codigo de la persona no viene o no es numerico, " . $obj->PersonaCodigo,
            );
        }
        if (!isset($obj->PeriodoCodigo) || !is_numeric($obj->PeriodoCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo del periodo.",
                "consola" => "El codigo del periodo no viene o no es numerico, " . $obj->PeriodoCodigo,
            );
        }
        if (!isset($obj->UapCodigo) || !is_numeric($obj->UapCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el código de la vinculación.",
                "consola" => "El codigo de la vinculación no viene o no es numerico, " . $obj->UapCodigo,
            );
        }

        //Asignaciones
        $PersonaCodigo = $obj->PersonaCodigo; // Contiene el codigo de la persona (docente)
        $PeriodoCodigo = $obj->PeriodoCodigo; // Contiene el codigo del periodo 
        $UapCodigo = $obj->UapCodigo; // Contiene el código de la vinculación

        $sql = "SELECT TOP 1
                x.Novedad
            FROM (
                -- 1) Registros alineados al modelo nuevo (ag_id + uap + periodo)
                -- Esto se hizo para asociar la agenda estrictamente a la vinculación, había casos de duplicidad cuando un mismo docente tenía varias vinculaciones activas (Planta + Cátedra).
                SELECT
                    apn.novedad Novedad,
                    apn.fecha Fecha,
                    apn.apn_id ApnId,
                    0 Prioridad
                FROM agenda_periodo_novedad apn
                INNER JOIN uaa_personal uap ON uap.per_codigo = apn.per_codigo
                INNER JOIN agenda_periodo agp ON agp.idagenda = apn.ag_id
                INNER JOIN curso cur ON cur.cur_codigo = agp.cur_codigo
                INNER JOIN calendario cal ON cal.cal_codigo = cur.cal_codigo
                WHERE
                    apn.periodo = {$PeriodoCodigo}
                    AND apn.per_codigo = {$PersonaCodigo}
                    AND uap.uap_codigo = {$UapCodigo}
                    AND agp.per_codigo = {$PersonaCodigo}
                    AND agp.uap_codigo = {$UapCodigo}
                    AND agp.uap_codigo = uap.uap_codigo
                    AND cal.per_codigo = {$PeriodoCodigo}

                UNION ALL

                -- 2) Fallback legacy para no perder históricos sin relación completa de agenda
                SELECT
                    apn.novedad Novedad,
                    apn.fecha Fecha,
                    apn.apn_id ApnId,
                    1 Prioridad
                FROM agenda_periodo_novedad apn
                INNER JOIN uaa_personal uap ON uap.per_codigo = apn.per_codigo
                LEFT JOIN agenda_periodo agp ON agp.idagenda = apn.ag_id
                LEFT JOIN curso cur ON cur.cur_codigo = agp.cur_codigo
                LEFT JOIN calendario cal ON cal.cal_codigo = cur.cal_codigo
                WHERE
                    apn.periodo = {$PeriodoCodigo}
                    AND apn.per_codigo = {$PersonaCodigo}
                    AND uap.uap_codigo = {$UapCodigo}
                    AND (
                        apn.ag_id IS NULL
                        OR agp.idagenda IS NULL
                        OR cur.cur_codigo IS NULL
                        OR cal.cal_codigo IS NULL
                        OR agp.uap_codigo <> uap.uap_codigo
                        OR cal.per_codigo <> apn.periodo
                    )
            ) x
            ORDER BY
                x.Prioridad ASC,
                x.Fecha DESC,
                x.ApnId DESC
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error en consultar las observaciones del docente.";
            $this->errorConsultarBd["sql"] = $sql;
            return $this->errorConsultarBd;
        }

        $novedad = "";
        if (count($this->cnx->json) > 0 && isset($this->cnx->json[0]["Novedad"])) {
            $novedad = $this->cnx->json[0]["Novedad"];
        }

        return array(
            "resultado" => true,
            "mensaje" => "Observaciones consultadas correctamente.",
            "count" => count($this->cnx->json),
            "data" => $novedad,
        );
    }

    //Inicio funcion insertarObservaciones
    //Se usa para insertar la observacion de un docente en un periodo
    function insertarObservaciones($obj)
    {
        //Validaciones
        if (!isset($obj->PersonaCodigo) || !is_numeric($obj->PersonaCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo de la persona.",
                "consola" => "El codigo de la persona no viene o no es numerico, " . $obj->PersonaCodigo,
            );
        }

        if (!isset($obj->PeriodoCodigo) || !is_numeric($obj->PeriodoCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo del periodo.",
                "consola" => "El codigo del periodo no viene o no es numerico, " . $obj->PeriodoCodigo,
            );
        }
        if (!isset($obj->UapCodigo) || !is_numeric($obj->UapCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el código de la vinculación.",
                "consola" => "El codigo de la vinculación no viene o no es numerico, " . $obj->UapCodigo,
            );
        }

        //Asignaciones
        $PersonaCodigo = $obj->PersonaCodigo; // Contiene el codigo de la persona (docente)
        $PeriodoCodigo = $obj->PeriodoCodigo; // Contiene el codigo del periodo 
        $UapCodigo = $obj->UapCodigo; // Contiene el código de la vinculación
        $Observacion = trim($obj->Observacion); // Contiene la observaciones ingresadas
        $Observacion = str_replace("'", "''", $Observacion);
        $fecha = date('Y-m-d');

        $r_agenda = $this->consultarAgIdPorVinculacion($PersonaCodigo, $UapCodigo, $PeriodoCodigo);
        if ($r_agenda["resultado"] == false) {
            return $r_agenda;
        }

        $AgId = $r_agenda["AgId"];

        $sql = "INSERT INTO 
            agenda_periodo_novedad(
                novedad,
                fecha,
                periodo,
                per_codigo,
                ag_id
            ) VALUES(
                '{$Observacion}',
                '{$fecha}',
                {$PeriodoCodigo},
                {$PersonaCodigo},
                {$AgId}
            )
        ";

        if (!$this->cnx->sentencia($sql)) {
            $this->errorSentenciaBd["mensaje"] = "Error al guardar la observación. 
                Recargue la página e intente de nuevo.";
                $this->errorSentenciaBd["consola"] = "Ha fallado insert en agenda_periodo_novedad.";
                // $this->errorSentenciaBd["sql"] = $sql;

            return $this->errorSentenciaBd;
        }

        return array(
            "resultado" => true,
            "mensaje" => "Observación guardada correctamente"
        );
    }
}
