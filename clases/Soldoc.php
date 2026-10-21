<?php
date_default_timezone_set('America/Bogota');
require_once(dirname(__FILE__) . '/servicios/FechaSqlServer.php');
require_once(dirname(__FILE__) . '/servicios/ValidarCargaDocenteService.php');

class Soldoc
{
    private $cnx = null;
    private $estadosSolicitud;

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
        $this->estadosSolicitud = [
            'Eliminado' => 0,
            'Solicitado' => 1,
            'Aprobado' => 2,
            'Rechazado' => 3,
        ];
    }

    private function validarAperturaActivaSolicitud($PtsCodigo, $UaaCodigo, $PeriodoCodigo, $FechaHoraActualSql, $nombreModulo)
    {
        $sql = "SELECT TOP 1 prg.prg_codigo PrsCodigo
                FROM programacionacademica.programacion_gestion prg
                INNER JOIN calendario cal ON cal.cal_codigo = prg.cal_codigo
                WHERE
                    prg.prg_estado = 1
                    AND prg.pts_codigo = {$PtsCodigo}
                    AND prg.uaa_codigo = {$UaaCodigo}
                    AND cal.per_codigo = {$PeriodoCodigo}
                    AND {$FechaHoraActualSql} BETWEEN prg.prg_fecha_inicio AND prg.prg_fecha_fin";

        if (!$this->cnx->consultar($sql)) {
            return array(
                "resultado" => false,
                "mensaje" => "Error al validar la apertura del mÃ³dulo de solicitudes.",
                "consola" => "No se pudo consultar programacion_gestion para UAA {$UaaCodigo}, tipo {$PtsCodigo} y periodo {$PeriodoCodigo}.",
            );
        }

        if (count($this->cnx->json) > 0) {
            return array("resultado" => true);
        }

        $sql = "SELECT TOP 1
                    prg.prg_estado PrsEstado,
                    prg.prg_fecha_inicio FechaInicio,
                    prg.prg_fecha_fin FechaFin
                FROM programacionacademica.programacion_gestion prg
                INNER JOIN calendario cal ON cal.cal_codigo = prg.cal_codigo
                WHERE
                    prg.pts_codigo = {$PtsCodigo}
                    AND prg.uaa_codigo = {$UaaCodigo}
                    AND cal.per_codigo = {$PeriodoCodigo}
                ORDER BY prg.prg_estado DESC, prg.prg_fecha_fin DESC, prg.prg_codigo DESC";

        if (!$this->cnx->consultar($sql)) {
            return array(
                "resultado" => false,
                "mensaje" => "Error al validar la apertura del mÃ³dulo de solicitudes.",
                "consola" => "No se pudo consultar el estado de apertura para UAA {$UaaCodigo}, tipo {$PtsCodigo} y periodo {$PeriodoCodigo}.",
            );
        }

        if (count($this->cnx->json) <= 0) {
            return array(
                "resultado" => false,
                "mensaje" => "No hay apertura configurada para {$nombreModulo} en el periodo y unidad seleccionados.",
                "consola" => "No existe apertura en programacion_gestion para UAA {$UaaCodigo}, tipo {$PtsCodigo} y periodo {$PeriodoCodigo}.",
            );
        }

        $apertura = $this->cnx->json[0];
        $fechaInicio = date("Y-m-d H:i", strtotime($apertura["FechaInicio"]));
        $fechaFin = date("Y-m-d H:i", strtotime($apertura["FechaFin"]));
        $now = time();

        if (intval($apertura["PrsEstado"]) == 0) {
            $mensaje = "La apertura de {$nombreModulo} para el periodo y unidad seleccionados está inactiva.";
        } else if ($now < strtotime($apertura["FechaInicio"])) {
            $mensaje = "La apertura de {$nombreModulo} está pendiente. Estará habilitada desde {$fechaInicio} hasta {$fechaFin}.";
        } else if ($now > strtotime($apertura["FechaFin"])) {
            $mensaje = "La apertura de {$nombreModulo} está vencida. Estuvo habilitada desde {$fechaInicio} hasta {$fechaFin}.";
        } else {
            $mensaje = "No hay apertura activa para {$nombreModulo} en el periodo y unidad seleccionados.";
        }

        return array(
            "resultado" => false,
            "mensaje" => $mensaje,
            "consola" => "Apertura no vigente para UAA {$UaaCodigo}, tipo {$PtsCodigo}, periodo {$PeriodoCodigo}.",
        );
    }

    // Inicia consultarCalendarioActivo
    // Permite verificar si una unidad tiene apertura para programacion academica en un periodo especifico
    private function consultarCalendarioActivo($UaaCodigo, $PeriodoCodigo)
    {
        $today = date("Y-m-d");
        $hora = date("H:i:s");

        //Obtenemos los calendarios activos para gestion, de las unidades del usuario logueado
        $sql = "SELECT pra.cal_codigo CalCodigo, pra.uaa_codigo UaaCodigo
        FROM programacionacademica.programacion_academica pra
        INNER JOIN calendario cal ON cal.cal_codigo = pra.cal_codigo AND cal.per_codigo = {$PeriodoCodigo}
        WHERE 
            pra.uaa_codigo IN ({$UaaCodigo}) AND
            pra.pra_estado = 1 AND pra.prp_codigo != 4 AND
            '{$today}T{$hora}' BETWEEN pra.pra_fecha_inicio AND pra.pra_fecha_fin
        ";

        //verificamos que la se pueda realizar la consulta
        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error en consultar los calendarios activos.";
            return $this->errorConsultarBd;
        }

        $r_calendarios = $this->cnx->json; //almacenamos la respuesta

        if (count($r_calendarios) > 0) {
            return array(
                "resultado" => true
            );
        } else {
            return array(
                "resultado" => false,
            );
        }
    }

    // Inicia consultaSolicitudProgramada()
    // Permite verificar si una solicitud puede tener un horario y un curso programado
    public function consultaSolicitudProgramada($SpdCodigo)
    {

        // Consultamos la informacion de la solicitud.
        $sql = "SELECT 
                spd.spd_codigo SpdCodigo,
                per.per_codigo PersonaCodigo,
                per.per_identificacion PersonaIdentificacion,
                per.per_nombre + ' ' + per.per_apellido PersonaNombreApellido,
                asi.asi_codigo AsiCodigo,
                asi.asi_nombre AsiNombre,
                asi.asi_nombre_corto AsiNombreCorto,
                spd_estado SpdEstado,
                uaaSolicita.uaa_codigo UaaSolicitaCodigo,
                uaaSolicita.uaa_nombre_corto UaaSolicitaNombre,
                uaaDirigida.uaa_codigo UaaDirigidaCodigo,
                uaaDirigida.uaa_nombre_corto UaaDirigidaNombre,
                periodo.per_codigo PeriodoCodigo, 
                periodo.per_nombre PeriodoNombre,
                periodo.per_periodo PeriodoPeriodo,
                sed.sed_codigo SedCodigo,
                sed.sed_nombre SedNombre
            FROM programacionacademica.solicitud_prestamo_docente spd
            LEFT JOIN persona per ON per.per_codigo = spd.persona_codigo
            INNER JOIN periodo periodo ON periodo.per_codigo = spd.periodo_codigo
            INNER JOIN asignatura asi ON asi.asi_codigo = spd.asi_codigo
            INNER JOIN uaa uaaSolicita ON uaaSolicita.uaa_codigo = spd.uaa_solicita
            INNER JOIN uaa uaaDirigida ON uaaDirigida.uaa_codigo = spd.uaa_dirigida
            INNER JOIN sede sed ON sed.sed_codigo = spd.sed_codigo
            WHERE 
                spd.spd_codigo = {$SpdCodigo}
            ORDER BY spd.spd_codigo DESC
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["mensaje"] = "No se pudo consultar las solicitudes aprobadas";
            $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
            return $this->errorConsultarBd;
        }

        $consultaSolicitudes = $this->cnx->json;
        $cursosAgrupados = []; // Contendra cada curso con su horario.

        foreach ($consultaSolicitudes as &$solicitud) {

            $objSpdCodigo = (object)['SpdCodigo' => $solicitud["SpdCodigo"]];
            $horarioSolicitud = self::consultarHorarioSolicitud($objSpdCodigo);
            if ($horarioSolicitud != "" && $horarioSolicitud["resultado"]) {
                $solicitud["Horario"] = $horarioSolicitud["data"];
            }

            // Si no se ha asignado un docente se salta el loop
            if ($solicitud['PersonaCodigo'] == "") {
                return array(
                    "resultado" => true,
                );
            }

            // Debemos buscar segun el horario de la solicitud
            // (dia_codigo = 3 and hra_codigo = 1) or (dia_codigo = 2 and hra_codigo = 1), etc
            $queryHorario = "";

            foreach ($solicitud["Horario"] as $horario) {
                if ($queryHorario != "") {
                    $queryHorario .= " OR ";
                }
                $queryHorario .= " (eso.dia_codigo = {$horario['DiaCodigo']} AND eso.hra_codigo = {$horario['HraCodigo']}) ";
            }

            $sql = "SELECT
                    eso.eso_actividad EsoActividad,
                    asi.asi_codigo AsiCodigo,
                    asi.asi_nombre AsiNombre,
                    asi.asi_nombre_corto AsiNombreCorto,
                    uaa.uaa_codigo UaaCodigo,
                    uaa.uaa_nombre_corto UaaNombreCorto,
                    eso.eso_subgrupo EsoSubgrupo,
                    dia.dia_codigo DiaCodigo,
                    dia.dia_nombre DiaNombre,
                    hra.hra_codigo HraCodigo,
                    hra.hra_inicio HraInicio,
                    hra.hra_fin HraFin
                FROM
                    espacio_ocupacion eso
                INNER JOIN uaa_personal uap ON uap.uap_codigo = eso.uap_codigo
                INNER JOIN persona per ON per.per_codigo = uap.per_codigo AND per.per_codigo = {$solicitud['PersonaCodigo']}
                INNER JOIN curso cur ON cur.cur_codigo = eso.eso_actividad AND cur.asi_codigo = {$solicitud['AsiCodigo']} 
                    AND cur.sed_codigo = {$solicitud['SedCodigo']} 
                    AND cur.cur_estado = 1
                INNER JOIN asignatura asi ON asi.asi_codigo = cur.asi_codigo
                INNER JOIN uaa ON uaa.uaa_codigo = eso.uaa_codigo
                INNER JOIN calendario cal ON cal.cal_codigo = cur.cal_codigo AND cal.per_codigo = {$solicitud['PeriodoCodigo']}
                INNER JOIN dia ON dia.dia_codigo = eso.dia_codigo
                INNER JOIN hora hra ON hra.hra_codigo = eso.hra_codigo
                WHERE
                    {$queryHorario}
                GROUP BY
                    eso.eso_actividad,
                    eso.eso_subgrupo,
                    dia.dia_codigo,
                    dia.dia_nombre,
                    hra.hra_codigo,
                    hra.hra_inicio,
                    hra.hra_fin,
                    asi.asi_codigo,
                    asi.asi_nombre,
                    asi.asi_nombre_corto,
                    uaa.uaa_codigo,
                    uaa.uaa_nombre_corto
                ORDER BY
                    eso.eso_actividad, eso.eso_subgrupo, dia.dia_codigo, hra.hra_codigo 
                ASC
            ";

            if (!$this->cnx->consultar($sql)) {
                $this->errorConsultarBd["mensaje"] = "No se pudo consultar los cursos asignados al docente {$solicitud['PersonaNombreApellido']} de la solicitud {$solicitud['SpdCodigo']}";
                $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
                return $this->errorConsultarBd;
            }

            $consultaProgramacion = $this->cnx->json;

            if (count($consultaProgramacion) > 0) {
                foreach ($consultaProgramacion as $horario) { // Recorremos el horario del docente
                    $cursosAgrupados[$horario["EsoActividad"]] = true;
                }
            }
        }

        $arrayCursosUnico = array_keys($cursosAgrupados);
        $implodeCursosUnico = implode(',', $arrayCursosUnico);

        if (count($arrayCursosUnico) > 0) {
            return array(
                "resultado" => false,
                "mensaje" => "Esta solicitud de docente cuenta con un curso ({$implodeCursosUnico}) y horario programado, por favor solicite al programa que sea eliminado antes de ser rechazado.",
            );
        } else {
            return array(
                "resultado" => true,
            );
        }
    }

    // Inicia consultaSolicitudRechazadaAsignatura()
    // Permite consultar si existe una solicitud en un periodo, asignatura y solicitada por las unidades del usuario que exista rechazada
    // La idea es que no permita crear mas solicitud para la misma asignatura si existe previamente una rechazada.
    public function consultaSolicitudRechazadaAsignatura($PeriodoCodigo, $AsiCodigo)
    {

        $unidades = $_SESSION['pacademica']['datosVinculacionUsuario']['unidades']; //Contiene las unidades activas del usuario
        $unidades = is_array($unidades) ? implode(",", $unidades) : $unidades;

        //Query para obtener las solicitudes que han dirigido a mis unidades
        $sql = "SELECT 
            spd.spd_codigo SpdCodigo,
            per.per_nombre + ' ' + per.per_apellido PersonaNombreApellido,
            asi.asi_codigo AsiCodigo,
            asi.asi_nombre AsiNombre,
            asi.asi_nombre_corto AsiNombreCorto,
            spd_estado SpdEstado,
            uaaSolicita.uaa_codigo UaaSolicitaCodigo,
            uaaSolicita.uaa_nombre_corto UaaSolicitaNombre,
            uaaDirigida.uaa_codigo UaaDirigidaCodigo,
            uaaDirigida.uaa_nombre_corto UaaDirigidaNombre,
            periodo.per_codigo PeriodoCodigo, 
            periodo.per_nombre PeriodoNombre,
            periodo.per_periodo PeriodoPeriodo,
            sed.sed_codigo SedCodigo,
            sed.sed_nombre SedNombre
        FROM programacionacademica.solicitud_prestamo_docente spd
        LEFT JOIN persona per ON per.per_codigo = spd.persona_codigo
        INNER JOIN periodo periodo ON periodo.per_codigo = spd.periodo_codigo
        INNER JOIN asignatura asi ON asi.asi_codigo = spd.asi_codigo
        INNER JOIN uaa uaaSolicita ON uaaSolicita.uaa_codigo = spd.uaa_solicita
        INNER JOIN uaa uaaDirigida ON uaaDirigida.uaa_codigo = spd.uaa_dirigida
        INNER JOIN sede sed ON sed.sed_codigo = spd.sed_codigo
		WHERE 
            spd.periodo_codigo = {$PeriodoCodigo}
            AND asi.asi_codigo = {$AsiCodigo}
            AND spd.uaa_solicita IN ({$unidades})
            AND spd.spd_estado = {$this->estadosSolicitud['Rechazado']}
		ORDER BY per.per_nombre ASC, spd.spd_codigo DESC
		";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["mensaje"] = "No se pudo realizar la consulta de las solicitudes dirigidas de docentes a las unidades del usuario.";
            $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
            return $this->errorConsultarBd;
        }

        $conSolicitudes = $this->cnx->json;

        if (count($conSolicitudes) > 0) {
            return array(
                "resultado" => false,
                "mensaje" => "Existe una solicitud rechazada previamente con la misma asignatura {$conSolicitudes[0]['AsiNombreCorto']} - {$conSolicitudes[0]['AsiNombre']}, por favor editela y re activela antes de crear una nueva.",
            );
        } else {
            return array(
                "resultado" => true,
            );
        }
    }

    // Inicia consultaSolicitudesEliminadas()
    public function consultaSolicitudesEliminadas($obj)
    {
        // Validamos las variables recibidas que exista y que sea numerico
        if (!isset($obj->PerCodigo) || !is_numeric($obj->PerCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo del periodo.",
                "consola" => "El codigo del periodo no viene o no es numerico, " . $obj->PerCodigo,
            );
        }

        // Parametros 
        $PerCodigo = $obj->PerCodigo; // Contiene el codigo del periodo seleccionado

        //Query para obtener las solicitudes que han dirigido a mis unidades
        $sql = "SELECT 
            spd.spd_codigo SpdCodigo,
            per.per_nombre + ' ' + per.per_apellido PersonaNombreApellido,
            asi.asi_codigo AsiCodigo,
            asi.asi_nombre AsiNombre,
            asi.asi_nombre_corto AsiNombreCorto,
            spd_estado SpdEstado,
            uaaSolicita.uaa_codigo UaaSolicitaCodigo,
            uaaSolicita.uaa_nombre_corto UaaSolicitaNombre,
            uaaDirigida.uaa_codigo UaaDirigidaCodigo,
            uaaDirigida.uaa_nombre_corto UaaDirigidaNombre,
            periodo.per_codigo PeriodoCodigo, 
            periodo.per_nombre PeriodoNombre,
            periodo.per_periodo PeriodoPeriodo,
            sed.sed_codigo SedCodigo,
            sed.sed_nombre SedNombre
        FROM programacionacademica.solicitud_prestamo_docente spd
        LEFT JOIN persona per ON per.per_codigo = spd.persona_codigo
        INNER JOIN periodo periodo ON periodo.per_codigo = spd.periodo_codigo
        INNER JOIN asignatura asi ON asi.asi_codigo = spd.asi_codigo
        INNER JOIN uaa uaaSolicita ON uaaSolicita.uaa_codigo = spd.uaa_solicita
        INNER JOIN uaa uaaDirigida ON uaaDirigida.uaa_codigo = spd.uaa_dirigida
        INNER JOIN sede sed ON sed.sed_codigo = spd.sed_codigo
		WHERE 
            spd.periodo_codigo = {$PerCodigo}
            AND spd.spd_estado = {$this->estadosSolicitud['Eliminado']}
		ORDER BY per.per_nombre ASC, spd.spd_codigo DESC
		";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["mensaje"] = "No se pudo realizar la consulta de las solicitudes dirigidas de docentes a las unidades del usuario.";
            $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
            return $this->errorConsultarBd;
        }

        $conSolicitudes = $this->cnx->json;

        //Obtenemos el horario de las solicitudes
        foreach ($conSolicitudes as &$solicitud) {
            $objSpdCodigo = (object)['SpdCodigo' => $solicitud["SpdCodigo"]];
            $horario = self::consultarHorarioSolicitud($objSpdCodigo);
            if ($horario != "" && $horario["resultado"]) {
                $solicitud["Horario"] = $horario["data"];
            }
        }

        return array(
            "resultado" => true,
            "mensaje" => "Solicitudes de docentes consultadas correctamente.",
            "data" => $conSolicitudes
        );
    }

    // Inicia consultarSolicitudesProgramadas
    // Permite consultar las solicitudes y visualizar si tienen cursos programados
    public function consultarSolicitudesProgramadas($obj)
    {
        // Validamos las variables recibidas que exista y que sea numerico
        if (!isset($obj->PerCodigo) || !is_numeric($obj->PerCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo del periodo.",
                "consola" => "El codigo del periodo no viene o no es numerico, " . $obj->PerCodigo,
            );
        }

        // Realizada
        // Recibida
        if (!isset($obj->tipoSolicitud)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el tipo de reporte solicitudes programadas.",
                "consola" => "El tipo de reporte de solicitudes programadas no viene o no es numerico, " . $obj->tipoSolicitud,
            );
        }

        // Parametros 
        $PerCodigo = $obj->PerCodigo; // Contiene el codigo del periodo seleccionado
        $tipoSolicitud = $obj->tipoSolicitud; // Contiene // Realizada // Recibida

        $perfil = $_SESSION['pacademica']['datosVinculacionUsuario']['Administrador']; //Contiene si el perfil es administrador
        $queryUnidades = "";
        if ($perfil != 1) {
            $unidades = $_SESSION['pacademica']['datosVinculacionUsuario']['unidades']; //Contiene las unidades activas del usuario
            $unidades = is_array($unidades) ? implode(",", $unidades) : $unidades;
            if ($tipoSolicitud == "Realizada") {
                $queryUnidades = "AND spd.uaa_solicita IN ($unidades)";
            }
            if ($tipoSolicitud == "Recibida") {
                $queryUnidades = "AND spd.uaa_dirigida IN ($unidades)";
            }
        }

        // Consultamos las solicitudes aprobadas.
        $sql = "SELECT 
                spd.spd_codigo SpdCodigo,
                per.per_codigo PersonaCodigo,
                per.per_identificacion PersonaIdentificacion,
                per.per_nombre + ' ' + per.per_apellido PersonaNombreApellido,
                asi.asi_codigo AsiCodigo,
                asi.asi_nombre AsiNombre,
                asi.asi_nombre_corto AsiNombreCorto,
                spd_estado SpdEstado,
                uaaSolicita.uaa_codigo UaaSolicitaCodigo,
                uaaSolicita.uaa_nombre_corto UaaSolicitaNombre,
                uaaDirigida.uaa_codigo UaaDirigidaCodigo,
                uaaDirigida.uaa_nombre_corto UaaDirigidaNombre,
                periodo.per_codigo PeriodoCodigo, 
                periodo.per_nombre PeriodoNombre,
                periodo.per_periodo PeriodoPeriodo,
                sed.sed_codigo SedCodigo,
                sed.sed_nombre SedNombre
            FROM programacionacademica.solicitud_prestamo_docente spd
            LEFT JOIN persona per ON per.per_codigo = spd.persona_codigo
            INNER JOIN periodo periodo ON periodo.per_codigo = spd.periodo_codigo
            INNER JOIN asignatura asi ON asi.asi_codigo = spd.asi_codigo
            INNER JOIN uaa uaaSolicita ON uaaSolicita.uaa_codigo = spd.uaa_solicita
            INNER JOIN uaa uaaDirigida ON uaaDirigida.uaa_codigo = spd.uaa_dirigida
            INNER JOIN sede sed ON sed.sed_codigo = spd.sed_codigo
            WHERE 
                spd.periodo_codigo = {$PerCodigo}
                AND spd.spd_estado = {$this->estadosSolicitud['Aprobado']}
                {$queryUnidades}
            ORDER BY spd.spd_codigo DESC
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["mensaje"] = "No se pudo consultar las solicitudes aprobadas";
            $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
            return $this->errorConsultarBd;
        }

        $consultaSolicitudes = $this->cnx->json;

        foreach ($consultaSolicitudes as &$solicitud) {

            // Consultamos las posibles vinculaiones del docente.
            $sql = "SELECT
                    uap.uap_codigo UapCodigo
                FROM
                    uaa_personal uap 
                WHERE   
                    uap.per_codigo = {$solicitud["PersonaCodigo"]}
            ";

            if (!$this->cnx->consultar($sql)) {
                $this->errorConsultarBd["consola"] = "Error al consultar la vinculación del docente asignado a la solicitud {$solicitud["SpdCodigo"]}.";
                return $this->errorConsultarBd;
            }

            $vinculacionesDocente = $this->cnx->json;

            if (count($vinculacionesDocente) > 0) {
                $solicitud["vinculacionesDocente"] = $vinculacionesDocente;
            } else {
                $solicitud["vinculacionesDocente"] = [];
            }


            // Consultamos el horario de la solicitud
            $objSpdCodigo = (object)['SpdCodigo' => $solicitud["SpdCodigo"]];
            $horarioSolicitud = self::consultarHorarioSolicitud($objSpdCodigo);
            if ($horarioSolicitud != "" && $horarioSolicitud["resultado"]) {
                $solicitud["Horario"] = $horarioSolicitud["data"];
            }

            // Debemos buscar segun el horario de la solicitud
            // (dia_codigo = 3 and hra_codigo = 1) or (dia_codigo = 2 and hra_codigo = 1), etc
            $queryHorario = "";

            foreach ($solicitud["Horario"] as &$horario) {
                $horario["Programado"] = false;
                if ($queryHorario != "") {
                    $queryHorario .= " OR ";
                }
                $queryHorario .= " (eso.dia_codigo = {$horario['DiaCodigo']} AND eso.hra_codigo = {$horario['HraCodigo']}) ";
            }

            $sql = "SELECT
                    eso.eso_actividad EsoActividad
                FROM
                    espacio_ocupacion eso
                INNER JOIN uaa_personal uap ON uap.uap_codigo = eso.uap_codigo
                INNER JOIN persona per ON per.per_codigo = uap.per_codigo AND per.per_codigo = {$solicitud['PersonaCodigo']}
                INNER JOIN curso cur ON cur.cur_codigo = eso.eso_actividad AND cur.asi_codigo = {$solicitud['AsiCodigo']} 
                    AND cur.sed_codigo = {$solicitud['SedCodigo']} 
                    AND cur.cur_estado = 1
                INNER JOIN calendario cal ON cal.cal_codigo = cur.cal_codigo AND cal.per_codigo = {$solicitud['PeriodoCodigo']}
                WHERE
                    {$queryHorario}
                GROUP BY
                    eso.eso_actividad
            ";

            if (!$this->cnx->consultar($sql)) {
                $this->errorConsultarBd["mensaje"] = "No se pudo consultar los cursos asignados al docente {$solicitud['PersonaNombreApellido']} de la solicitud {$solicitud['SpdCodigo']}";
                $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
                return $this->errorConsultarBd;
            }

            $conExisteCurso = $this->cnx->json;

            if (count($conExisteCurso) > 0) {
                $horariosAgrupados = []; // Contendra cada curso con su horario.

                foreach ($conExisteCurso as $cursoExistente) {
                    $sql = "SELECT
                            eso.eso_actividad EsoActividad,
                            uap.uap_codigo UapCodigo,
                            CONVERT(varchar, per.per_nombre) + '. ' + CONVERT(varchar, per.per_apellido) PerNombreApellido,
                            per.per_identificacion PerIdentificacion,
                            asi.asi_codigo AsiCodigo,
                            asi.asi_nombre AsiNombre,
                            asi.asi_nombre_corto AsiNombreCorto,
                            uaa.uaa_codigo UaaCodigo,
                            uaa.uaa_nombre_corto UaaNombreCorto,
                            eso.eso_subgrupo EsoSubgrupo,
                            dia.dia_codigo DiaCodigo,
                            dia.dia_nombre DiaNombre,
                            hra.hra_codigo HraCodigo,
                            hra.hra_inicio HraInicio,
                            hra.hra_fin HraFin,
                            (
                                SELECT 
                                    count(*) as CantMatriculados
                                FROM 
                                    matricula_curso mac
                                WHERE 
                                    mac.cur_codigo = eso.eso_actividad
                                    and mac.mac_subgrupo = eso.eso_subgrupo 
                                    and mac.maa_codigo in (1,2)
                            ) Matriculados,
                            'false' Programado
                        FROM
                            espacio_ocupacion eso
                        INNER JOIN uaa_personal uap ON uap.uap_codigo = eso.uap_codigo
                        INNER JOIN persona per ON per.per_codigo = uap.per_codigo
                        INNER JOIN curso cur ON cur.cur_codigo = eso.eso_actividad
                        INNER JOIN asignatura asi ON asi.asi_codigo = cur.asi_codigo
                        INNER JOIN uaa ON uaa.uaa_codigo = eso.uaa_codigo
                        INNER JOIN calendario cal ON cal.cal_codigo = cur.cal_codigo
                        INNER JOIN dia ON dia.dia_codigo = eso.dia_codigo
                        INNER JOIN hora hra ON hra.hra_codigo = eso.hra_codigo
                        WHERE
                            eso.eso_actividad = {$cursoExistente['EsoActividad']}
                        GROUP BY
                            eso.eso_actividad,
                            uap.uap_codigo,
                            per.per_nombre,
                            per.per_apellido,
                            per.per_identificacion,
                            eso.eso_subgrupo,
                            dia.dia_codigo,
                            dia.dia_nombre,
                            hra.hra_codigo,
                            hra.hra_inicio,
                            hra.hra_fin,
                            asi.asi_codigo,
                            asi.asi_nombre,
                            asi.asi_nombre_corto,
                            uaa.uaa_codigo,
                            uaa.uaa_nombre_corto
                        ORDER BY
                            eso.eso_actividad, eso.eso_subgrupo, dia.dia_codigo, hra.hra_codigo 
                        ASC
                    ";

                    if (!$this->cnx->consultar($sql)) {
                        $this->errorConsultarBd["mensaje"] = "No se pudo consultar el horario del curso {$cursoExistente['EsoActividad']}";
                        $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
                        return $this->errorConsultarBd;
                    }

                    $conHorarioCurso = $this->cnx->json;

                    foreach ($conHorarioCurso as &$horario) { // Recorremos el horario del docente
                        if (!isset($horariosAgrupados[$horario["EsoActividad"]])) { //Verificamos si ya tenemos un array con el codigo del curso
                            //Si no existe lo creamos con la informacion basica.
                            $horariosAgrupados[$horario["EsoActividad"]] = [
                                "CurCodigo" => $horario["EsoActividad"],
                                "UapCodigo" => $horario["UapCodigo"],
                                "AsiCodigo" => $horario["AsiCodigo"],
                                "AsiNombre" => $horario["AsiNombre"],
                                "AsiNombreCorto" => $horario["AsiNombreCorto"],
                                "UaaCodigo" => $horario["UaaCodigo"],
                                "UaaNombreCorto" => $horario["UaaNombreCorto"],
                                "Matriculados" => "0",
                                "Horario" => []
                            ];
                        }

                        // Debemos recorrer el horario de la solicitud y si concuerda marcarlo con true, si no false.
                        foreach ($solicitud["Horario"] as &$hraSolicitud) {
                            if ($horario["DiaCodigo"] == $hraSolicitud["DiaCodigo"] && $horario["HraCodigo"] == $hraSolicitud["HraCodigo"] && in_array($horario["UapCodigo"], array_column($solicitud["vinculacionesDocente"], 'UapCodigo'))) {
                                $hraSolicitud["Programado"] = true;
                                $horario["Programado"] = true;
                            }
                        }

                        // Agregamos la hora al array del curso en la columna Horario.
                        $horariosAgrupados[$horario["EsoActividad"]]["Horario"][] = [
                            'EsoSubgrupo' => $horario["EsoSubgrupo"],
                            'Matriculados' => $horario["Matriculados"],
                            'DiaCodigo' => $horario["DiaCodigo"],
                            'DiaNombre' => $horario["DiaNombre"],
                            'HraCodigo' => $horario["HraCodigo"],
                            'HraInicio' => $horario["HraInicio"],
                            'HraFin' => $horario["HraFin"],
                            'UapCodigo' => $horario["UapCodigo"],
                            'PerNombreApellido' => $horario["PerNombreApellido"],
                            'PerIdentificacion' => $horario["PerIdentificacion"],
                            'Programado' => $horario["Programado"]
                        ];
                    }
                    $solicitud["Programacion"] = $horariosAgrupados;
                }
            }
        }

        return array(
            "resultado" => true,
            "mensaje" => "Reporte de solicitudes aprobadas consultado correctamente.",
            "data" => $consultaSolicitudes,
        );
    }

    // Inicia consultarHorarioDocenteAprobado
    // Permite consultar el horario del docente aprobado
    public function consultarHorarioDocenteAprobado($obj)
    {
        // Validaciones 
        if (!isset($obj->PersonaCodigo) || !is_numeric($obj->PersonaCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar un docente.",
                "consola" => "El codigo del docente no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->PeriodoCodigo) || !is_numeric($obj->PeriodoCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar un periodo.",
                "consola" => "El codigo del periodo no es numérico o no se envio correctamente.",
            );
        }

        $PersonaCodigo = $obj->PersonaCodigo; // Contiene per_codigo de la persona
        $PeriodoCodigo = $obj->PeriodoCodigo; // Contiene per_codigo del periodo

        $sql = "SELECT
            dia.dia_codigo DiaCodigo,
            dia.dia_nombre DiaNombre,
            hra.hra_codigo HraCodigo,
            hra.hra_inicio HraInicio,
            hra.hra_fin HraFin
        FROM
            programacionacademica.solicitud_prestamo_docente spd
        INNER JOIN programacionacademica.solicitud_prestamo_docente_horario spdh ON spdh.spd_codigo = spd.spd_codigo
        INNER JOIN dia ON dia.dia_codigo = spdh.dia_codigo
        INNER JOIN hora hra on hra.hra_codigo = spdh.hra_codigo
        WHERE
            spd.periodo_codigo = {$PeriodoCodigo}
            AND spdh.spdh_estado = 1
            AND spd.persona_codigo = {$PersonaCodigo}
            AND spd.spd_estado = 2";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["mensaje"] = "No se pudo consultar el horario aprobado del docente.";
            $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
            return $this->errorConsultarBd;
        }

        return array(
            "resultado" => true,
            "mensaje" => "Horario docente consultado correctamente.",
            "data" => $this->cnx->json
        );
    }

    // Inicio reActivarSolicitud
    // Permite reactivar una solicitud especifica
    public function reActivarSolicitud($obj)
    {
        //Validaciones
        if (!isset($obj->SpdCodigo) || !is_numeric($obj->SpdCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar una solicitud.",
                "consola" => "El codigo de la solicitud no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->AsiCodigo) || !is_numeric($obj->AsiCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar una asignatura.",
                "consola" => "El codigo de la asignatura no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->SedCodigo) || !is_numeric($obj->SedCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar una sede.",
                "consola" => "El codigo de la sede no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->UaaDirigidaCodigo) || !is_numeric($obj->UaaDirigidaCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar una unidad dirigida.",
                "consola" => "El codigo de la unidad dirigida no es numérico o no se envio correctamente.",
            );
        }

        $SpdCodigo = $obj->SpdCodigo; // Contiene el codigo de la solicitud.
        $AsiCodigo = $obj->AsiCodigo; // Contiene el codigo de la asignatura.
        $SedCodigo = $obj->SedCodigo; // Contiene el codigo de la sede.
        $UaaDirigidaCodigo = $obj->UaaDirigidaCodigo; // Contiene el codigo de la unidad dirigida.

        $sql = "UPDATE 
                programacionacademica.solicitud_prestamo_docente
            SET
                persona_codigo = NULL,
                sed_codigo = {$SedCodigo},
                asi_codigo = {$AsiCodigo},
                uaa_dirigida = {$UaaDirigidaCodigo},
                spd_estado = 1
            WHERE
                spd_codigo = {$SpdCodigo}
        ";

        if (!$this->cnx->sentencia($sql)) {
            $this->errorSentenciaBd["mensaje"] = "Error al re activar la solicitud de prestamo docente. 
        Recargue la página e intente de nuevo.";
            $this->errorSentenciaBd["consola"] = "Ha fallado el update del estado de la solicitud " . __LINE__ . ".";
            return $this->errorSentenciaBd;
        }

        $resCorreo = $this->enviarNotificacion($obj, 'ReActivacion');

        return array(
            "resultado" => true,
            "mensaje" => "La solicitud de prestamo docente se actualizado correctamente."
        );
    }

    // Inicio agregarHorario
    // Permite agregar un array de horas a una solicitud especifica.
    public function agregarHorario($obj)
    {
        //Validaciones
        if (!isset($obj->SpdCodigo) || !is_numeric($obj->SpdCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar una solicitud.",
                "consola" => "El codigo de la solicitud no es numérico o no se envio correctamente.",
            );
        }

        if (!isset($obj->DiaCodigo) || !is_numeric($obj->DiaCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar una dia.",
                "consola" => "El codigo del dia no es numérico o no se envio correctamente.",
            );
        }

        if (!isset($obj->HorasSeleccionadas) || count($obj->HorasSeleccionadas) <= 0) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar al menos una hora.",
                "consola" => "El arreglo de horas seleccionadas no tiene items o no se envio correctamente.",
            );
        }

        $SpdCodigo = $obj->SpdCodigo; // Contiene el codigo de la solicitud
        $DiaCodigo = $obj->DiaCodigo; // Contiene el dia del nuevo horario
        $HorasSeleccionadas = $obj->HorasSeleccionadas; // Contiene las horas seleccionadas del nuevo horario.

        foreach ($HorasSeleccionadas as $hora) {
            $sql = "SELECT 
                spdh_codigo SpdhCodigo,
                -- spd_codigo SpdCodigo,
                -- dia_codigo DiaCodigo,
                -- hra_codigo HraCodigo,
                spdh_estado SpdhEstado
            FROM
                programacionacademica.solicitud_prestamo_docente_horario
            WHERE
                spd_codigo = {$SpdCodigo}
                AND dia_codigo = {$DiaCodigo}
                AND hra_codigo = {$hora}
            ";

            if (!$this->cnx->consultar($sql)) {
                $this->errorConsultarBd["mensaje"] = "No se pudo consultar la hora {$hora} para la solicitud seleccionada.";
                $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
                return $this->errorConsultarBd;
            }

            $r_horario = $this->cnx->json;

            if (count($r_horario) <= 0) {
                // Insertar
                $sql = "INSERT INTO 
                    programacionacademica.solicitud_prestamo_docente_horario 
                        (spd_codigo, dia_codigo, hra_codigo, spdh_estado)
                    VALUES 
                        ({$SpdCodigo}, {$DiaCodigo}, {$hora}, 1)
                ";
                if (!$this->cnx->sentencia($sql)) {
                    $this->errorSentenciaBd["mensaje"] = "Error al agregar la hora {$hora} a la solicitud. 
                Recargue la página e intente de nuevo.";
                    $this->errorSentenciaBd["consola"] = "Ha fallado el insert de la hora {$hora} de la solicitud" . __LINE__ . ".";
                    return $this->errorSentenciaBd;
                }
            } else {
                if ($r_horario[0]['SpdhEstado'] != 1) {
                    $sql = "UPDATE
                            programacionacademica.solicitud_prestamo_docente_horario 
                        SET
                            spdh_estado = 1
                        WHERE
                            spdh_codigo = {$r_horario[0]['SpdhCodigo']}
                    ";
                    if (!$this->cnx->sentencia($sql)) {
                        $this->errorSentenciaBd["mensaje"] = "Error al activar la hora {$hora} previamente eliminada para la solicitud. 
                    Recargue la página e intente de nuevo.";
                        $this->errorSentenciaBd["consola"] = "Ha fallado el update del estado de la hora {$hora} de la solicitud " . __LINE__ . ".";
                        return $this->errorSentenciaBd;
                    }
                }
            }
        }

        return array(
            "resultado" => true,
            "mensaje" => "La(s) hora(s) se han agregado correctamente."
        );
    }

    // Inicio validacionDocenteOcupado
    // Permite validar si un docente, en un horario, en un periodo, ya tiene una solicitud aprobada.
    private function validacionDocenteOcupado($obj)
    {
        //Validaciones
        if (!isset($obj->SpdCodigo) || !is_numeric($obj->SpdCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar una solicitud.",
                "consola" => "El codigo de la solicitud no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->PerCodigo) || !is_numeric($obj->PerCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar un docente.",
                "consola" => "El codigo del docente no es numérico o no se envio correctamente.",
            );
        }

        $SpdCodigo = $obj->SpdCodigo; //Contiene el codigo de la solicitud
        $PerCodigo = $obj->PerCodigo; //Contiene el codigo de la persona

        // Consultamos el horario de la solicitud actual y el periodo
        $sql = "SELECT
            spdh.spdh_codigo SpdhCodigo,
            dia.dia_codigo DiaCodigo,
            dia.dia_nombre DiaNombre,
            hra.hra_codigo HraCodigo,
            hra.hra_inicio HraInicio,
            hra.hra_fin HraFin, 
            spd.periodo_codigo PeriodoCodigo
        FROM
            programacionacademica.solicitud_prestamo_docente_horario spdh
        INNER JOIN programacionacademica.solicitud_prestamo_docente spd ON spd.spd_codigo = spdh.spd_codigo
        INNER JOIN dia ON dia.dia_codigo = spdh.dia_codigo
        INNER JOIN hora hra ON hra.hra_codigo = spdh.hra_codigo
        WHERE
            spdh.spdh_estado = 1
            AND spdh.spd_codigo = {$SpdCodigo}
        ORDER BY spdh.dia_codigo, spdh.hra_codigo ASC";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["mensaje"] = "No se pudo consultar el horario de la solicitud actual.";
            $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
            return $this->errorConsultarBd;
        }

        $solicitudActual = $this->cnx->json; // Almacenamos la informacion de la solicitud actual y su horario.

        if (count($solicitudActual) <= 0) {
            return array(
                "resultado" => false,
                "mensaje" => "La solicitud no tiene horario registrado, agregue el horario antes de asignar el docente.",
                "consola" => "No se encontraron horas activas en solicitud_prestamo_docente_horario para la solicitud {$SpdCodigo}.",
            );
        }

        $periodoSolicitado = $solicitudActual[0]["PeriodoCodigo"];

        // Consultamos las solicitudes aprobadas del docente actual, el periodo y el horario
        $sql = "SELECT
            spdh.spdh_codigo SpdhCodigo,
            dia.dia_codigo DiaCodigo,
            dia.dia_nombre DiaNombre,
            hra.hra_codigo HraCodigo,
            hra.hra_inicio HraInicio,
            hra.hra_fin HraFin, 
            spd.periodo_codigo PeriodoCodigo
        FROM
            programacionacademica.solicitud_prestamo_docente_horario spdh
        INNER JOIN programacionacademica.solicitud_prestamo_docente spd ON spd.spd_codigo = spdh.spd_codigo
        INNER JOIN dia ON dia.dia_codigo = spdh.dia_codigo
        INNER JOIN hora hra ON hra.hra_codigo = spdh.hra_codigo
        WHERE
            spdh.spdh_estado = 1
            AND spd.persona_codigo = {$PerCodigo}
            AND spd.spd_estado = 2 -- Solicitud aprobada
            AND spd.periodo_codigo = {$periodoSolicitado}
            -- Se excluye la propia solicitud: al reasignar el mismo docente ya esta en estado 2 y
            -- haria match consigo misma, bloqueando el cambio sin que exista un cruce real.
            AND spd.spd_codigo <> {$SpdCodigo}
        ORDER BY spdh.dia_codigo, spdh.hra_codigo ASC";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["mensaje"] = "No se pudo consultar las solicitudes y horarios aprobados del docente seleccionado.";
            $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
            return $this->errorConsultarBd;
        }

        $solicitudesAprobadasDocente = $this->cnx->json; // Almacenamos la informacion de la solicitud actual y su horario.

        $docenteOcupado = false;
        foreach ($solicitudActual as $actual) {
            foreach ($solicitudesAprobadasDocente as $agenda) {
                if (
                    $actual["DiaCodigo"] == $agenda["DiaCodigo"] &&
                    $actual["HraCodigo"] == $agenda["HraCodigo"] &&
                    $actual["PeriodoCodigo"] == $agenda["PeriodoCodigo"]
                ) {
                    $docenteOcupado = true;
                    break 2; // Salir de los dos bucles
                }
            }
        }

        if ($docenteOcupado) {
            return array(
                "resultado" => false,
                "mensaje" => "El docente ya tiene una solicitud previa aprobada con un horario similar al de esta solicitud."
            );
        }

        // El bloque anterior solo compara contra otras solicitudes de prestamo. Falta verificar la
        // programacion real del docente: los cursos que ya dicta en el periodo (espacio_ocupacion).
        $sql = "SELECT
                cur.cur_codigo CurCodigo,
                asi.asi_codigo AsiCodigo,
                asi.asi_nombre AsiNombre,
                asi.asi_nombre_corto AsiNombreCorto,
                eso.dia_codigo DiaCodigo,
                dia.dia_nombre DiaNombre,
                eso.hra_codigo HraCodigo,
                hra.hra_inicio HraInicio,
                hra.hra_fin HraFin
            FROM espacio_ocupacion eso
            INNER JOIN uaa_personal uap ON uap.uap_codigo = eso.uap_codigo AND uap.per_codigo = {$PerCodigo}
            INNER JOIN curso cur ON cur.cur_codigo = eso.eso_actividad
            INNER JOIN asignatura asi ON asi.asi_codigo = cur.asi_codigo
            INNER JOIN calendario cal ON cal.cal_codigo = cur.cal_codigo AND cal.per_codigo = {$periodoSolicitado}
            INNER JOIN dia ON dia.dia_codigo = eso.dia_codigo
            INNER JOIN hora hra ON hra.hra_codigo = eso.hra_codigo
            WHERE cur.cur_estado = 1 -- espacio_ocupacion conserva los cursos eliminados
            GROUP BY cur.cur_codigo, asi.asi_codigo, asi.asi_nombre, asi.asi_nombre_corto,
                eso.dia_codigo, dia.dia_nombre, eso.hra_codigo, hra.hra_inicio, hra.hra_fin
            ORDER BY eso.dia_codigo, eso.hra_codigo ASC";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["mensaje"] = "No se pudo consultar la programacion academica del docente seleccionado.";
            $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
            return $this->errorConsultarBd;
        }

        $programacionDocente = $this->cnx->json; // Cursos que el docente ya dicta en el periodo

        return self::evaluarCruceProgramacionDocente($solicitudActual, $programacionDocente);
    }

    // Inicio evaluarCruceProgramacionDocente
    // Cruza el horario solicitado contra la programacion real del docente en el periodo y arma el
    // mensaje indicando con que cursos se presenta el cruce. Es una funcion pura para poder probarla.
    public function evaluarCruceProgramacionDocente($horarioSolicitud, $programacionDocente)
    {
        $cruces = array();

        foreach ($horarioSolicitud as $solicitado) {
            foreach ($programacionDocente as $clase) {
                if (
                    $solicitado["DiaCodigo"] == $clase["DiaCodigo"] &&
                    $solicitado["HraCodigo"] == $clase["HraCodigo"]
                ) {
                    $cruces[] = trim($clase["DiaNombre"]) . " " . trim($clase["HraInicio"]) . " - " . trim($clase["HraFin"])
                        . ": curso {$clase['CurCodigo']} - {$clase['AsiCodigo']}. {$clase['AsiNombreCorto']}";
                }
            }
        }

        $cruces = array_values(array_unique($cruces));

        if (count($cruces) > 0) {
            return array(
                "resultado" => false,
                "mensaje" => "El docente ya tiene programacion academica en el horario solicitado: " . implode(", ", $cruces) . ".",
                "cruces" => $cruces
            );
        }

        return array(
            "resultado" => true,
            "mensaje" => "El docente no presenta cruce de horario en las solicitudes previas ni en su programacion academica."
        );
    }
    // Fin evaluarCruceProgramacionDocente

    // Inicio eliminarSolicitud
    // Permite eliminar una solicitud que se encuentre en estado 1 (Solicitada)
    public function eliminarSolicitud($obj)
    {
        //Validaciones
        if (!isset($obj->SpdCodigo) || !is_numeric($obj->SpdCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar una solicitud.",
                "consola" => "El codigo de la solicitud no es numérico o no se envio correctamente.",
            );
        }

        $SpdCodigo = $obj->SpdCodigo; //Contiene el codigo de la solicitud

        $sql = "UPDATE 
                programacionacademica.solicitud_prestamo_docente 
            SET 
                spd_estado = 0 
            WHERE spd_codigo = {$SpdCodigo}
        ";

        if (!$this->cnx->sentencia($sql)) {
            $this->errorSentenciaBd["mensaje"] = "Error al eliminar la solicitud. 
        Recargue la página e intente de nuevo.";
            $this->errorSentenciaBd["consola"] = "Ha fallado el update del estado de la solicitud " . __LINE__ . ".";
            return $this->errorSentenciaBd;
        }

        return array(
            "resultado" => true,
            "mensaje" => "La solicitud se ha eliminado correctamente."
        );
    }

    // Inicio enviarNotificacion
    // Permite enviar notificaciones a la persona a cargo de una unidad 
    public function enviarNotificacion($obj, $tipo = '')
    {
        if (!isset($obj->SpdCodigo) || !is_numeric($obj->SpdCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar una solicitud.",
                "consola" => "El codigo de la solicitud no es numérico o no se envio correctamente.",
            );
        }

        if ($tipo != 'Creacion' && $tipo != 'Asignado' && $tipo != 'ReAsignado' && $tipo != 'Rechazado' && $tipo != 'Comentario' && $tipo != 'ReActivacion') {
            return array(
                "resultado" => false,
                "mensaje" => "El tipo de notificacion no se envio correctamente.",
                "consola" => "El tipo de la notificacion es vacio o no se envio correctamente.",
            );
        }

        $SpdCodigo = $obj->SpdCodigo; // Contiene el codigo de la solicitud
        // $tipo esta vacio por defecto pero puede ser:
        // Asignado
        // Rechazado
        // Comentario
        // Creacion
        // ReActivacion

        //Query para obtener la informacion de la solicitud y su horario.
        $sql = "SELECT 
            spd.spd_codigo SpdCodigo,
            per.per_nombre + ' ' + per.per_apellido PersonaNombreApellido,
            asi.asi_codigo AsiCodigo,
            asi.asi_nombre AsiNombre,
            asi.asi_nombre_corto AsiNombreCorto,
            spd_estado SpdEstado,
            uaaSolicita.uaa_codigo UaaSolicitaCodigo,
            uaaSolicita.uaa_nombre_corto UaaSolicitaNombre,
            uaaDirigida.uaa_codigo UaaDirigidaCodigo,
            uaaDirigida.uaa_nombre_corto UaaDirigidaNombre,
            periodo.per_nombre PeriodoNombre,
            periodo.per_periodo PeriodoPeriodo,
            sed.sed_codigo SedCodigo,
            sed.sed_nombre SedNombre
        FROM programacionacademica.solicitud_prestamo_docente spd
        LEFT JOIN persona per ON per.per_codigo = spd.persona_codigo
        INNER JOIN periodo periodo ON periodo.per_codigo = spd.periodo_codigo
        INNER JOIN asignatura asi ON asi.asi_codigo = spd.asi_codigo
        INNER JOIN uaa uaaSolicita ON uaaSolicita.uaa_codigo = spd.uaa_solicita
        INNER JOIN uaa uaaDirigida ON uaaDirigida.uaa_codigo = spd.uaa_dirigida
        INNER JOIN sede sed on sed.sed_codigo = spd.sed_codigo
		WHERE 
            spd.spd_codigo = {$SpdCodigo}
		";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["mensaje"] = "No se pudo realizar la consulta de la informacion de la solicitud seleccionada.";
            $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
            return $this->errorConsultarBd;
        }
        $info_solicitud = $this->cnx->json; // Contiene la informacion de la solicitud.
        $info_solicitud[0]["Horario"] = $this->consultarHorarioSolicitud($obj)["data"]; //Almacenamos el contenido de la peticion.
        $info_solicitud[0]["Justificacion"] = isset($obj->mensajeComentario) ? $obj->mensajeComentario : ""; //Almacenamos la justificacion si existe

        $UaaDirigida = $info_solicitud[0]["UaaDirigidaCodigo"]; // Contiene el codigo de la unidad a donde se dirige la solicitud 328
        $UaaSolicita = $info_solicitud[0]["UaaSolicitaCodigo"]; // Contiene el codigo de la unidad a donde se dirige la solicitud 480

        // Para obtener los correos de los usuarios de ambas unidades debemos verificar si la uaa tiene una uaa unificada
        // En caso de tener se debe usar esa uaa para buscar en la vista usuario_programacion
        $uaaEspecialesSinUnificar = array('328', '345');

        // Query para verificar si la Uaa dirigida tiene una uaa unificada
        $UaaDirigidaUnificada = array();
        if (!in_array($UaaDirigida, $uaaEspecialesSinUnificar)) {
            $sql = "SELECT
                uaa_codigo_unificado UaaCodigo
            FROM departamentos_programas_unificados dpu
            WHERE 
                dpu.uaa_codigo_departamento IN ({$UaaDirigida})
        ";
            if (!$this->cnx->consultar($sql)) {
                $this->errorConsultarBd["mensaje"] = "No se pudo realizar la consulta de la informacion de la unidad dirigida.";
                $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
                return $this->errorConsultarBd;
            }
            $UaaDirigidaUnificada = $this->cnx->json; // Contiene el uaa unificado de la unidad dirigida.
        } else {
            // Aplica para los dptos especiales como:
            //  328	DPTO O PROGRAMA DE PSICOPEDAGOGIA
            //  345	DPTO O PROGRAMA DE MATEMATICAS Y ESTADISTICA
            $UaaDirigidaUnificada[] = [
                "UaaCodigo" => $UaaDirigida
            ];
        }
        // Query para verificar si la Uaa que solicita tiene una uaa unificada
        $UaaSolicitaUnificada = array();
        if (!in_array($UaaSolicita, $uaaEspecialesSinUnificar)) {
            $sql = "SELECT
                uaa_codigo_unificado UaaCodigo
            FROM programa pro
            INNER JOIN uaa ON uaa.uaa_codigo = pro.uaa_codigo AND pro.uaa_codigo IN ({$UaaSolicita})
        ";
            if (!$this->cnx->consultar($sql)) {
                $this->errorConsultarBd["mensaje"] = "No se pudo realizar la consulta de la informacion de la unidad solicita.";
                $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
                return $this->errorConsultarBd;
            }
            $UaaSolicitaUnificada = $this->cnx->json; // Contiene el uaa unificado de la unidad solicita.
        }

        $codigosCombinados = array();

        foreach ($UaaDirigidaUnificada as $item) {
            if (isset($item['UaaCodigo'])) {
                $codigosCombinados[] = $item['UaaCodigo'];
            }
        }

        foreach ($UaaSolicitaUnificada as $item) {
            if (isset($item['UaaCodigo'])) {
                $codigosCombinados[] = $item['UaaCodigo'];
            }
        }

        $codigosCombinados[] = $UaaDirigida;
        $codigosCombinados[] = $UaaSolicita;

        $arrayUnique = array_unique($codigosCombinados);
        $implodeUaa = implode(',', $arrayUnique);

        $sql = "SELECT per.per_identificacion PerIdentificacion, per.per_email_interno PerEmailInterno
        FROM usuario_programacion usu 
        INNER JOIN persona per ON per.per_codigo = usu.up
        WHERE usu.usg_uaa IN ({$implodeUaa})
        GROUP BY per.per_identificacion, per.per_email_interno";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["mensaje"] = "No se pudo realizar la consulta de la informacion de la unidad solicita.";
            $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
            return $this->errorConsultarBd;
        }
        $ListaEmail = $this->cnx->json; // Contiene el uaa unificado de la unidad solicita.

        if (empty($ListaEmail)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se encontraron correos asociados a las unidades.",
                "consola" => "La lista de correos de las unidades ({$implodeUaa}) esta vacia " . __LINE__ . ".",
            );
        }
        $info_solicitud[0]["Correos"] = $ListaEmail; //Agregamos a la informacion de la solicitud los correos a los que debera enviar la notificacion

        require_once "../correos/correo_solicitud_docente.php";
        $ca = new Correo_solicitud_docente();
        $resultado = $ca->enviarCorreoSolicitudDocente($info_solicitud, $tipo);
        return $resultado;
    }

    // Inicio rechazoSolicitud
    // Permite rechazar una la solicitud especifica y dejar una justificacion.
    public function rechazoSolicitud($obj)
    {
        //Validaciones
        if (!isset($obj->SpdCodigo) || !is_numeric($obj->SpdCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar una solicitud.",
                "consola" => "El codigo de la solicitud no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->UaaSolicitaCodigo) || !is_numeric($obj->UaaSolicitaCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar una solicitud.",
                "consola" => "El codigo de la unidad que solicita no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->PeriodoCodigo) || !is_numeric($obj->PeriodoCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar una solicitud.",
                "consola" => "El codigo del periodo no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->mensajeComentario) || strlen($obj->mensajeComentario) < 5) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe ingresar el mensaje del comentario.",
                "consola" => "El comentario de la solicitud tiene menos de 5 letras o no se envio correctamente.",
            );
        }

        $SpdCodigo = $obj->SpdCodigo; //Contiene el codigo de la solicitud
        $UaaSolicitaCodigo = $obj->UaaSolicitaCodigo; // Contiene el codigo de la unidad que solicita
        $PeriodoCodigo = $obj->PeriodoCodigo; // Contiene el codigo del periodo de la solicitud

        // se verifica si la unidad tiene apertura academica en un periodo especifica
        $verificacionAperturaProgramacion = self::consultarCalendarioActivo($UaaSolicitaCodigo, $PeriodoCodigo);

        if (isset($verificacionAperturaProgramacion['resultado']) && $verificacionAperturaProgramacion['resultado']) {
            // Si tiene apertura debera exigir eliminar el horario de la solicitud programada.
            // De lo contrario permitira rechazar normalmente.
            $solicitudProgramada = self::consultaSolicitudProgramada($SpdCodigo);
            if (isset($solicitudProgramada['resultado']) && !$solicitudProgramada['resultado']) {
                return array(
                    "resultado" => false,
                    "mensaje" => $solicitudProgramada['mensaje'],
                    "consola" => $solicitudProgramada['mensaje'],
                );
            }
        }

        $sql = "UPDATE 
                programacionacademica.solicitud_prestamo_docente 
            SET 
                persona_codigo = NULL,
                spd_estado = 3
            WHERE spd_codigo = {$SpdCodigo}
        ";

        if (!$this->cnx->sentencia($sql)) {
            $this->errorSentenciaBd["mensaje"] = "Error al rechazar la solicitud. 
        Recargue la página e intente de nuevo.";
            $this->errorSentenciaBd["consola"] = "Ha fallado el update del estado de la solicitud " . __LINE__ . ".";
            return $this->errorSentenciaBd;
        }

        $resComentario = $this->agregarComentariosSolicitud($obj, 'Rechazado');
        $resCorreo = $this->enviarNotificacion($obj, 'Rechazado')['resultado'];

        if ($resComentario['resultado']) {
            return array(
                "resultado" => true,
                "mensaje" => "La solicitud se ha rechazado correctamente y el comentario se agrego correctamente."
            );
        } else {
            return array(
                "resultado" => true,
                "mensaje" => "La solicitud se ha rechazado correctamente pero el comentario no se agrego correctamente."
            );
        }
    }

    // Inicio eliminaHorarioAsignado
    // Permite eliminar un horario asignado a una solicitud especifica
    public function eliminaHorarioAsignado($obj)
    {
        //Validaciones
        if (!isset($obj->SpdCodigo) || !is_numeric($obj->SpdCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar una solicitud.",
                "consola" => "El codigo de la solicitud no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->SpdhCodigo) || !is_numeric($obj->SpdhCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar un horario asignado.",
                "consola" => "El codigo del horario asignado no es numérico o no se envio correctamente.",
            );
        }

        $SpdhCodigo = $obj->SpdhCodigo;

        $sql = "UPDATE 
                programacionacademica.solicitud_prestamo_docente_horario 
            SET 
                spdh_estado = 0 
            WHERE 
                spdh_codigo = {$SpdhCodigo}
        ";

        if (!$this->cnx->sentencia($sql)) {
            $this->errorSentenciaBd["mensaje"] = "Error al eliminar el horario a la solicitud. 
        Recargue la página e intente de nuevo.";
            $this->errorSentenciaBd["consola"] = "Ha fallado el update del horario de la solicitud " . __LINE__ . ".";
            return $this->errorSentenciaBd;
        }

        return array(
            "resultado" => true,
            "mensaje" => "El horario se ha eliminado correctamente."
        );
    }

    // Inicio validacionAgendaDocente
    // Permite validar la agenda de un docente en caso que encuentre una vinculacion del docente para el periodo del curso.
    public function validacionAgendaDocente($obj) {

        if (!isset($obj->PeriodoCodigo) || !is_numeric($obj->PeriodoCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se encontro el periodo de la solicitud seleccionada.",
                "consola" => "El codigo del periodo no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->VinCodigo) || !is_numeric($obj->VinCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se encontro el periodo de la solicitud seleccionada.",
                "consola" => "El codigo del periodo no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->DedCodigo) || !is_numeric($obj->DedCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se encontro el periodo de la solicitud seleccionada.",
                "consola" => "El codigo del periodo no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->PerCodigo) || !is_numeric($obj->PerCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar un docente.",
                "consola" => "El codigo del docente no es numérico o no se envio correctamente.",
            );
        }

        $PeriodoCodigo = $obj->PeriodoCodigo; // Contiene el codigo del periodo academico de la solicitud
        $VinCodigo = $obj->VinCodigo; // Contiene la ultima vinculacion del docente seleccionado
        $DedCodigo = $obj->DedCodigo; // Contiene la dedicacion de la ultima vinculacion de docente seleccionado
        $PerCodigo = $obj->PerCodigo; // Contiene el codigo de la persona del docente seleccionado
        $SpdCodigo = $obj->SpdCodigo; // Contiene el codigo de la solicitud

        $sql = "SELECT 
                agp.uap_codigo UapCodigo,
                uap.sed_codigo UapSedCodigo
            FROM agenda_periodo agp
            INNER JOIN uaa_personal uap ON uap.uap_codigo = agp.uap_codigo
            INNER JOIN vinculacion vin ON vin.vin_codigo = uap.vin_codigo
            INNER JOIN dedicacion ded ON ded.ded_codigo = uap.ded_codigo
            INNER JOIN curso cur ON cur.cur_codigo = agp.cur_codigo
            INNER JOIN asignatura asi ON asi.asi_codigo = cur.asi_codigo
            INNER JOIN calendario cal ON cal.cal_codigo = cur.cal_codigo AND cal.per_codigo = {$PeriodoCodigo}
            WHERE
                agp.per_codigo = {$PerCodigo}
                AND agp.vinculacion = {$VinCodigo}
                AND ded.ded_codigo = {$DedCodigo}
            GROUP BY agp.uap_codigo, uap.sed_codigo
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["mensaje"] = "No se pudo realizar la consulta de la vinculacion previa del docente seleccionado.";
            $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
            return $this->errorConsultarBd;
        }

        $vinculacionesDocente = $this->cnx->json;

        if (count($vinculacionesDocente) == 0) {
            return array(
                "resultado" => true,
                "data" => count($vinculacionesDocente),
                "mensaje" => "El docente no tiene una vinculacion hasta el momento."
            );
        }

        if (count($vinculacionesDocente) > 1) {
            $uapCodigos = array_column($vinculacionesDocente, 'UapCodigo');
            return array(
                "resultado" => false,
                "data" => count($vinculacionesDocente),
                "consola" => implode(',', $uapCodigos),
                "mensaje" => "El docente tiene doble vinculacion activa para este periodo, por favor contactar con CITCD."
            );
        }

        $servicioCargaDocente = new ValidarCargaDocenteService($this->cnx);
        $UapCodigo = $vinculacionesDocente[0]["UapCodigo"]; // Obtenemos la vinculacion docente
        $UapSedCodigo = $vinculacionesDocente[0]["UapSedCodigo"]; // Obtenemos la sede de la vinculacion docente

        // VALIDAMOS SOLAMENTE LA CANTIDAD DE HORAS PARA DOCENTES ESPECIFICOS
        //
        // Con vinculacion: 
        // 14	CATEDRA DOCENTE
        // 24	CATEDRA VISITANTE DOCENTE
        // 49	CATEDRA CONVENIO DOCENTE
        //
        // Con dedicacion:
        //  6   POR HORAS

        if (($VinCodigo == 14 or $VinCodigo == 24 or $VinCodigo == 49) &&  $DedCodigo == 6) {

            // Realizamos la busqueda de la cantidad de horas nuevas que se asignaran en la solicitud
            $sql = "SELECT
                spdh.spdh_codigo SpdhCodigo,
                dia.dia_codigo DiaCodigo,
                dia.dia_nombre DiaNombre,
                hra.hra_codigo HraCodigo,
                hra.hra_inicio HraInicio,
                hra.hra_fin HraFin, 
                spd.periodo_codigo PeriodoCodigo
            FROM
                programacionacademica.solicitud_prestamo_docente_horario spdh
            INNER JOIN programacionacademica.solicitud_prestamo_docente spd ON spd.spd_codigo = spdh.spd_codigo
            INNER JOIN dia ON dia.dia_codigo = spdh.dia_codigo
            INNER JOIN hora hra ON hra.hra_codigo = spdh.hra_codigo
            WHERE
                spdh.spdh_estado = 1
                AND spdh.spd_codigo = {$SpdCodigo}
            ORDER BY spdh.dia_codigo, spdh.hra_codigo ASC";

            if (!$this->cnx->consultar($sql)) {
                $this->errorConsultarBd["mensaje"] = "No se pudo consultar el horario de la solicitud actual.";
                $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
                return $this->errorConsultarBd;
            }

            $cantidad_horas_nuevas = count($this->cnx->json); // cantidad de horas nuevas

            $total_horas_inv_tesis = 0; //total de horas proyecto de investigacion o direccion de tesis
            $total_horas_descarga = 0; //total de horas descarga academica

            //VERIFICAR MAXIMO DE CARGAR POR SEDE CATEDRATICO
            $sql = "SELECT 
                sum(agp.numero_total_hora/agp.semanas) as hrsemanal 
            FROM 
                agenda_periodo agp
            WHERE 
                agp.uap_codigo = {$UapCodigo}
                and agp.vinculacion = {$VinCodigo}
            ";
            if (!$this->cnx->consultar($sql)) {
                $this->errorConsultarBd["consola"] = "Error al consultar la agenda del catedratico de sedes.";
                return $this->errorConsultarBd;
            }
            $r_agenda_catedratico = $this->cnx->json; //Almacena el resumen de la agenda del docente para un curso y vinculacion especifica.

            $horas_semanal_catedratico_sede = 0; //Almacenamos por defecto 0 horas a la semana.
            $horas_semanal_catedratico = 0; //Almacenamos por defecto 0 horas a la semana.
            $max_horas_catedratico_sedes = 0; //Almacenamos por defecto 0 horas del total de horas permitidas en sede.
            $max_horas_catedratico = 0; //Almacenamos por defecto 0 horas del total de horas permitidas en Neiva.

            if ($UapSedCodigo != 1) { //Si es diferente de neiva
                $horas_semanal_catedratico_sede = $r_agenda_catedratico[0]['hrsemanal']; //Almacenamos el total de horas que tiene el docente en esta semana de sede.
                //Web parametro 210
                //CONTROLA EL MAXIMO DE HORAS PERMITIDA PARA UN CATEDRATICO DE LAS SEDES - PROGRAMACION ACADEMICA
                $sql = "SELECT wep.wep_valor WepValor FROM web_parametro wep WHERE wep.wep_codigo = 210 ";
                if (!$this->cnx->consultar($sql)) {
                    $this->errorConsultarBd["consola"] = "Error al consultar el maximo de horas permitidas para un catedratico de las sedes.";
                    return $this->errorConsultarBd;
                }
                $r_max_horas_cate_sedes = $this->cnx->json;
                $max_horas_catedratico_sedes = $r_max_horas_cate_sedes[0]["WepValor"]; //Contiene el numero maximo de horas permitidas para un catedratico en sedes.

            } else {
                $horas_semanal_catedratico = $r_agenda_catedratico[0]['hrsemanal']; //Almacenamos el total de horas que tiene el docente en esta semana de sede.
                $sql = "SELECT wep.wep_valor WepValor FROM web_parametro wep WHERE wep.wep_codigo = 485 ";
                if (!$this->cnx->consultar($sql)) {
                    $this->errorConsultarBd["consola"] = "Error al consultar el maximo de horas permitidas para un catedratico en neiva.";
                    return $this->errorConsultarBd;
                }
                $r_max_horas_cate_neiva = $this->cnx->json;
                $max_horas_catedratico = $r_max_horas_cate_neiva[0]["WepValor"]; //Contiene el numero maximo de horas permitidas para un catedratico en neiva.
            }

            $r_agenda_catedratico_servicio = $servicioCargaDocente->obtenerHorasSemanalesAgendaPorVinculacion($UapCodigo, $VinCodigo);
            if (!$r_agenda_catedratico_servicio["resultado"]) {
                return $r_agenda_catedratico_servicio;
            }
            $horas_semanal_catedratico_sede = $UapSedCodigo != 1 ? $r_agenda_catedratico_servicio["data"]["horasSemanal"] : 0;
            $horas_semanal_catedratico = $UapSedCodigo == 1 ? $r_agenda_catedratico_servicio["data"]["horasSemanal"] : 0;

            $r_topes_catedra = $servicioCargaDocente->obtenerTopesSemanalesCatedra($UapSedCodigo);
            if (!$r_topes_catedra["resultado"]) {
                return $r_topes_catedra;
            }
            $max_horas_catedratico_sedes = $r_topes_catedra["data"]["topeSedes"];
            $max_horas_catedratico = $r_topes_catedra["data"]["topeNeiva"];

            //Se consulta el total de horas de proyecto de investigacion o direccion de tesis que tiene el docente para el periodo actual
            $sql = "SELECT 
                sum(pep_hora_semana*pep_semanas) as total 
            FROM 
                proyecto pro
            INNER JOIN proyecto_tipo prt ON prt.prt_codigo = pro.prt_codigo 
            INNER JOIN persona_proyecto pep ON pro.pry_codigo = pep.pry_codigo 
            INNER JOIN periodo per ON per.per_codigo = pep.per_codigo 
            WHERE 
                pep.pep_persona = {$PerCodigo} 
                and per.per_codigo = {$PeriodoCodigo}
            ";
            if (!$this->cnx->consultar($sql)) {
                $this->errorConsultarBd["consola"] = "Error al consultar el total de horas proyecto de investigación y direccion de tesis para un catedratico.";
                return $this->errorConsultarBd;
            }

            $r_total_horas_inv_tesis = $this->cnx->json; //Almacenamos el total de horas proyectos de investigacion y direccion de tesis del catedratico.
            foreach ($r_total_horas_inv_tesis as $fe_horas) {
                $total_horas_inv_tesis = $fe_horas['total']; //Se almacena la cantidad total de horas proyecto de investigacion y direccion de tesis del catedratico actualmente.
            }

            $cargaComplementariaSemanal = $servicioCargaDocente->obtenerCargaComplementariaSemanal($PerCodigo, $PeriodoCodigo, true);
            if (!$cargaComplementariaSemanal["resultado"]) {
                return $cargaComplementariaSemanal;
            }
            $total_horas_inv_tesis = $cargaComplementariaSemanal["data"]["proyectosSemanal"];

            $total_horas_descarga = $total_horas_descarga + $cantidad_horas_nuevas + $total_horas_inv_tesis + $horas_semanal_catedratico_sede + $horas_semanal_catedratico; //Se suman todas las horas para sacar el total de descarga

            //En caso de superar las horas de descarga al tope
            if ($UapSedCodigo != 1) { //Validamos si es de sede diferente a neiva
                if ($total_horas_descarga > $max_horas_catedratico_sedes) { //En caso de que el total de horas de descarga sea mayor que el maximo permitido para catedraticos en sede
                    return array(
                        "resultado" => false,
                        "mensaje" => "ERROR. No se pueden adicionar las horas porque supera el límite de horas semanales, límite horas semanal en sedes: {$max_horas_catedratico_sedes}, horas que tendría el docente: {$total_horas_descarga}",
                        "consola" => "UapCodigo: {$UapCodigo}, VinCodigo: {$VinCodigo}, DedCodigo: {$DedCodigo}",
                        "line" => __LINE__
                    );
                } else {
                    return array(
                        "resultado" => true,
                        "mensaje" => "Se procede a realizar la programación, es docente de una sede y no supera los topes cantidad_horas_nuevas_total > max_horas_catedratico_sedes ($total_horas_descarga > $max_horas_catedratico_sedes). ",
                        "consola" => "UapCodigo: {$UapCodigo}, VinCodigo: {$VinCodigo}, DedCodigo: {$DedCodigo}",
                        "line" => __LINE__
                    );
                }
            } else {
                if ($total_horas_descarga > $max_horas_catedratico) { //En caso de que el total de horas de descarga sea mayor que el maximo permitido para catedraticos en neiva que son 16, esto esta en el acuerdo 048 de 2018 usco
                    return array(
                        "resultado" => false,
                        "mensaje" => "ERROR. No se pueden adicionar las horas porque supera el límite de horas semanales, límite horas semanal en Neiva: {$max_horas_catedratico}, horas que tendría el docente: {$total_horas_descarga}",
                        "consola" => "UapCodigo: {$UapCodigo}, VinCodigo: {$VinCodigo}, DedCodigo: {$DedCodigo}",
                        "line" => __LINE__
                    );
                } else {
                    return array(
                        "resultado" => true,
                        "mensaje" => "Se procede a realizar la programación, es docente de neiva y no supera los topes cantidad_horas_nuevas_total > max_horas_catedratico ($total_horas_descarga > $max_horas_catedratico). ",
                        "consola" => "UapCodigo: {$UapCodigo}, VinCodigo: {$VinCodigo}, DedCodigo: {$DedCodigo}",
                        "line" => __LINE__
                    );
                }
            }
        }

        return array(
            "resultado" => true,
            "mensaje" => "El docente tiene vinculacion y dedicacion, pero no se puede validar actualmente, por favor contactar con CITCD.",
            "consola" => "El docente tiene vinculacion {$VinCodigo} y dedicacion {$DedCodigo}, pero no se puede validar, por favor contactar con CITCD.",
        );
    }

    // Inicio asignarDocente
    // Permite asignar una persona (Docente) a una solicitud en especifico
    // Automaticamente genera un comentario con la justificacion de la asignacion del docente.
    public function asignarDocente($obj)
    {
        //Validaciones
        if (!isset($obj->SpdCodigo) || !is_numeric($obj->SpdCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar una solicitud.",
                "consola" => "El codigo de la solicitud no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->PerCodigo) || !is_numeric($obj->PerCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar un docente.",
                "consola" => "El codigo del docente no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->mensajeComentario) || strlen($obj->mensajeComentario) < 5) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe ingresar el mensaje del comentario.",
                "consola" => "El comentario de la solicitud tiene menos de 5 letras o no se envio correctamente.",
            );
        }

        if (!isset($obj->Tipo) || $obj->Tipo == '') {
            return array(
                "resultado" => false,
                "mensaje" => "El tipo de asignacion no se envio correctamente.",
                "consola" => "El tipo de asignacion del docente Asignar o ReAsignar no se envio correctamente.",
            );
        }

        $SpdCodigo = $obj->SpdCodigo; //Contiene el codigo de la solicitud
        $PerCodigo = $obj->PerCodigo; //Contiene el codigo de la persona
        $Tipo = $obj->Tipo; //Contiene el tipo de asignacion de docente, ReAsignado o Asignado

        // Se valida que el docente no se asignara en un mismo horario en otra solicitud
        $validacionHorario = $this->validacionDocenteOcupado($obj);
        if (!$validacionHorario["resultado"]) {
            return $validacionHorario;
        }

        // Se valida que el docente tenga vinculacion y si tiene que no se pueda solicitar mas horas de las permitidas en la agenda.
        $validacionHorario = $this->validacionAgendaDocente($obj);
        if (!$validacionHorario["resultado"]) {
            return $validacionHorario;
        }

        $sql = "UPDATE 
                programacionacademica.solicitud_prestamo_docente 
            SET 
                persona_codigo = {$PerCodigo}, 
                spd_estado = 2 
            WHERE spd_codigo = {$SpdCodigo}
        ";

        if (!$this->cnx->sentencia($sql)) {
            $this->errorSentenciaBd["mensaje"] = "Error al asignar el docente a la solicitud. 
        Recargue la página e intente de nuevo.";
            $this->errorSentenciaBd["consola"] = "Ha fallado el update del docente a la solicitud " . __LINE__ . ".";
            $this->errorSentenciaBd["sql"] = $sql;
            return $this->errorSentenciaBd;
        }

        $resComentario = $this->agregarComentariosSolicitud($obj, "Asignado");
        $resCorreo = $this->enviarNotificacion($obj, $Tipo)['resultado'];

        if ($resComentario['resultado']) {
            return array(
                "resultado" => true,
                "mensaje" => "El docente se ha asignado correctamente y el comentario se agrego correctamente."
            );
        } else {
            return array(
                "resultado" => true,
                "mensaje" => "El docente se ha asignado correctamente pero el comentario no se agrego correctamente."
            );
        }
    }

    // Inicio consultarDocentesVinculacionPrevia
    // Permite consultar los docentes que han tenido vinculacion de hace un año en adelante y los docentes de planta
    public function consultarDocentesVinculacionPrevia($obj)
    {

        //Validaciones
        if (!isset($obj->SedCodigo) || !is_numeric($obj->SedCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "La sede de la solicitud no se envio correctamente.",
                "consola" => "El codigo de la sede de la solicitud no es numérico o no se envio correctamente.",
            );
        }

        $unidades = $_SESSION['pacademica']['datosVinculacionUsuario']['unidades']; //Contiene las unidades activas del usuario
        $unidades = is_array($unidades) ? implode(",", $unidades) : $unidades;
        $date = date('Y-m-d\TH:i:s', strtotime('-1 year')); // resta un año a la fecha actual y obtiene la fecha resultante en formato ISO 8601
        $dateSql = FechaSqlServer::toSqlDateTime2($date, false);
        
        //TODO Se debe agregar 2 fechas, una para el periodo 1 AAAA-01-15 y otra para el periodo 2 AAAA-07-15
        $periodoUno = date('Y')."-01-01";
        $periodoDos = date('Y')."-07-01";
        if (date('n') < '7') {
            $currentDate = $periodoUno;
        } else {
            $currentDate = $periodoDos;
        }
        $currentDateSql = FechaSqlServer::toSqlDateTime2($currentDate, false);
        if ($dateSql === false || $currentDateSql === false) {
            return array(
                "resultado" => false,
                "mensaje" => "Formato de fecha inválido al consultar docentes.",
                "consola" => "No se pudieron preparar fechas SQL de consulta ({$date}, {$currentDate}).",
            );
        }
        // $currentDate = date('Y-m-d\TH:i:s'); // obtiene la fecha y hora actual en formato ISO 8601
        
        $SedCodigo = $obj->SedCodigo; // Contiene el codigo de la sede de la solicitud seleccionada.
        // Se agrega un union para mostrar los docentes nuevos apartir de la currentDate que no tienen carga academica (Nuevos)
        $sql = "SELECT 
                per.per_codigo PerCodigo,
                per.per_identificacion PerIdentificacion,
                per.per_nombre + ' ' + per.per_apellido PerNombreApellido,
                vin.vin_codigo VinCodigo,
                vin.vin_nombre VinNombre,
                ded.ded_codigo DedCodigo,
                ded.ded_nombre DedNombre,
                sed.sed_codigo SedCodigo,
                sed.sed_nombre SedNombre
            FROM persona per
            INNER JOIN uaa_personal uap ON uap.per_codigo = per.per_codigo 
                AND uap.uaa_codigo IN ({$unidades}) 
                --AND uap.sed_codigo = {$SedCodigo} 
                AND (
                    uap.uap_fecha_inicio >= {$dateSql} OR uap.uap_fecha_fin IS NULL
                )
            INNER JOIN agenda_periodo agp ON agp.uap_codigo = uap.uap_codigo --Solamente docentes que tuvieran vinculación.
            INNER JOIN sede sed ON sed.sed_codigo = uap.sed_codigo
            INNER JOIN vinculacion vin ON vin.vin_codigo = uap.vin_codigo AND vin.vin_clase = 1 AND vin.vin_codigo NOT IN (17)
            INNER JOIN dedicacion ded ON ded.ded_codigo = uap.ded_codigo
            WHERE per.per_apellido NOT LIKE '%CATEDRA%' AND per.per_nombre NOT LIKE '%CATEDRA%'
            GROUP BY
                per.per_codigo,
                per.per_identificacion,
                per.per_nombre + ' ' + per.per_apellido,
                vin.vin_codigo,
                ded.ded_codigo,
                vin.vin_nombre,
                ded.ded_nombre,
                sed.sed_codigo,
                sed.sed_nombre

            UNION

            SELECT 
                per.per_codigo PerCodigo,
                per.per_identificacion PerIdentificacion,
                per.per_nombre + ' ' + per.per_apellido PerNombreApellido,
                vin.vin_codigo VinCodigo,
                vin.vin_nombre VinNombre,
                ded.ded_codigo DedCodigo,
                ded.ded_nombre DedNombre,
                sed.sed_codigo SedCodigo,
                sed.sed_nombre SedNombre
            FROM persona per
            INNER JOIN uaa_personal uap ON uap.per_codigo = per.per_codigo 
                AND uap.uaa_codigo IN ({$unidades}) 
                --AND uap.sed_codigo = {$SedCodigo} 
                AND (
                    uap.uap_fecha_inicio >= {$currentDateSql} OR uap.uap_fecha_fin IS NULL
                )
            INNER JOIN sede sed ON sed.sed_codigo = uap.sed_codigo
            INNER JOIN vinculacion vin ON vin.vin_codigo = uap.vin_codigo AND vin.vin_clase = 1 AND vin.vin_codigo NOT IN (17)
            INNER JOIN dedicacion ded ON ded.ded_codigo = uap.ded_codigo
            WHERE per.per_apellido NOT LIKE '%CATEDRA%' AND per.per_nombre NOT LIKE '%CATEDRA%'
            GROUP BY
                per.per_codigo,
                per.per_identificacion,
                per.per_nombre + ' ' + per.per_apellido,
                vin.vin_codigo,
                ded.ded_codigo,
                vin.vin_nombre,
                ded.ded_nombre,
                sed.sed_codigo,
                sed.sed_nombre
            ORDER BY 
                per.per_nombre + ' ' + per.per_apellido ASC     
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["mensaje"] = "No se pudo realizar la consulta de los docentes disponibles.";
            $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
            return $this->errorConsultarBd;
        }

        return array(
            "resultado" => true,
            "mensaje" => "Docentes consultados correctamente.",
            "data" => $this->cnx->json,
            "count" => count($this->cnx->json)
        );
    }

    // Inicio funcion agregarComentariosSolicitud
    // Permite guardar un comentario a una solicitud.
    public function agregarComentariosSolicitud($obj, $tipo = "")
    {
        //Validaciones
        if (!isset($obj->SpdCodigo) || !is_numeric($obj->SpdCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar una solicitud.",
                "consola" => "El codigo de la solicitud no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->mensajeComentario) || strlen($obj->mensajeComentario) < 5) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe ingresar el mensaje del comentario.",
                "consola" => "El comentario de la solicitud tiene menos de 5 letras o no se envio correctamente.",
            );
        }
        $SpdCodigo = $obj->SpdCodigo; //Contiene el codigo de la solicitud
        $mensajeComentario = $obj->mensajeComentario; //Contiene el mensaje del comentario
        $UsuCodigo = $_SESSION['pacademica']['datosVinculacionUsuario']['usuarioCodigo']; //Contiene el codigo de usuario
        $FechaCreacion = FechaSqlServer::nowIso8601();

        $sql = "INSERT INTO programacionacademica.solicitud_prestamo_docente_comentario(
            spd_codigo,
            spdc_mensaje,
            spdc_estado,
            usu_codigo,
            spdc_fecha_creacion
        )
        VALUES(
            {$SpdCodigo},
            '{$mensajeComentario}',
            1,
            {$UsuCodigo},
            '{$FechaCreacion}'
        )";

        if (!$this->cnx->sentencia($sql)) {
            $this->errorSentenciaBd["mensaje"] = "Error al agregar el comentario a la solicitud. 
                Recargue la página e intente de nuevo.";
            $this->errorSentenciaBd["consola"] = "Ha fallado el insert del comentario a la solicitud " . __LINE__ . ".";
            // $this->errorSentenciaBd["query"] = $sql;
            return $this->errorSentenciaBd;
        }

        if ($tipo == '') {
            $resCorreo = $this->enviarNotificacion($obj, 'Comentario')['resultado'];
        }

        return array(
            "resultado" => true,
            "mensaje" => "El comentario se agrego correctamente."
        );
    }

    //Inicio funcion consultaComentariosSolicitud
    //Permite consultar los comentarios de una solicitud
    public function consultaComentariosSolicitud($obj)
    {
        //Validaciones
        if (!isset($obj->SpdCodigo) || !is_numeric($obj->SpdCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar una solicitud.",
                "consola" => "El codigo de la solicitud no es numérico o no se envio correctamente.",
            );
        }
        $SpdCodigo = $obj->SpdCodigo; //Contiene el codigo de la solicitud especifica

        $sql = "SELECT 
                per.per_nombre + ' ' + per.per_apellido PerNombreApellido,
                spdc.spdc_mensaje SpdcMensaje,
                CONVERT(varchar(19), spdc.spdc_fecha_creacion, 120) SpdcFechaCreacion
            FROM
                programacionacademica.solicitud_prestamo_docente_comentario spdc
            INNER JOIN usuario_general usu ON usu.uid = spdc.usu_codigo 
            INNER JOIN persona per ON per.per_codigo = usu.up
            WHERE 
                spdc.spd_codigo = {$SpdCodigo}
                AND spdc.spdc_estado = 1
            ORDER BY spdc.spdc_fecha_creacion DESC
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["mensaje"] = "No se pudo realizar la consulta de los comentarios de la solicitud seleccionada.";
            $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
            return $this->errorConsultarBd;
        }

        return array(
            "resultado" => true,
            "mensaje" => "Horario de la solicitud consultadas correctamente.",
            "data" => $this->cnx->json,
            "count" => count($this->cnx->json)
        );
    }

    // Inicio function consultarHorarioSolicitud
    // Consulta el horario de una solicitud
    public function consultarHorarioSolicitud($obj)
    {
        //Validaciones
        if (!isset($obj->SpdCodigo) || !is_numeric($obj->SpdCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar una solicitud.",
                "consola" => "El codigo de la solicitud no es numérico o no se envio correctamente.",
            );
        }
        $SpdCodigo = $obj->SpdCodigo; //Contiene el codigo de la solicitud especifica
        $sql = "SELECT
            spdh.spdh_codigo SpdhCodigo,
            dia.dia_codigo DiaCodigo,
            dia.dia_nombre DiaNombre,
            hra.hra_codigo HraCodigo,
            hra.hra_inicio HraInicio,
            hra.hra_fin HraFin
        FROM
            programacionacademica.solicitud_prestamo_docente_horario spdh
        INNER JOIN dia ON dia.dia_codigo = spdh.dia_codigo
        INNER JOIN hora hra ON hra.hra_codigo = spdh.hra_codigo
        WHERE
            spdh.spdh_estado = 1
            AND spdh.spd_codigo = {$SpdCodigo}
        ORDER BY spdh.dia_codigo, spdh.hra_codigo ASC
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["mensaje"] = "No se pudo realizar la consulta del horario de la solicitud seleccionada.";
            $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
            return $this->errorConsultarBd;
        }

        return array(
            "resultado" => true,
            "mensaje" => "Horario de la solicitud consultadas correctamente.",
            "data" => $this->cnx->json,
            "count" => count($this->cnx->json)
        );
    }

    // Inicio funcion consultarDias
    // consulta los dias disponibles
    public function consultarDias()
    {
        $sql = "SELECT 
            dia.dia_codigo DiaCodigo,
            dia.dia_nombre DiaNombre
        FROM dia
        WHERE
            dia_codigo != 8
        ORDER BY dia_codigo ASC
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["mensaje"] = "No se pudo realizar la consulta de los dias disponibles.";
            $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
            return $this->errorConsultarBd;
        }

        return array(
            "resultado" => true,
            "mensaje" => "Dias consultados correctamente.",
            "data" => $this->cnx->json,
            "count" => count($this->cnx->json)
        );
    }

    // Inicio funcion crearSolicitud
    // crea una solicitud
    public function crearSolicitud($obj)
    {

        //Validaciones
        if (!isset($obj->PeriodoCodigo) || !is_numeric($obj->PeriodoCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar un periodo.",
                "consola" => "El codigo del periodo no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->AsiCodigo) || !is_numeric($obj->AsiCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar una asignatura.",
                "consola" => "El codigo de la asignatura no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->UaaCodigoDirigida) || !is_numeric($obj->UaaCodigoDirigida)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar el departamento donde desea solicitar un docente.",
                "consola" => "El codigo del departamento no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->UaaCodigoSolicitada) || !is_numeric($obj->UaaCodigoSolicitada)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar la unidad que solicita el docente.",
                "consola" => "El codigo de la unidad no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->HorarioSeleccionado) || count($obj->HorarioSeleccionado) <= 0) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar un horario como minimo.",
                "consola" => "La lista de horario no contiene items o no se envio correctamente.",
            );
        }
        if (!isset($obj->SedCodigo) || !is_numeric($obj->SedCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar la sede del curso.",
                "consola" => "El codigo de la sede del curso no es numérico o no se envio correctamente.",
            );
        }
        $PeriodoCodigo = $obj->PeriodoCodigo; //Contiene el codigo del periodo
        $AsiCodigo = $obj->AsiCodigo; //Contiene el codigo de la asignatura
        $UaaCodigoDirigida = $obj->UaaCodigoDirigida; //Contiene el codigo de la uaa del departamento al que se dirige
        $UaaCodigoSolicitada = $obj->UaaCodigoSolicitada; //Contiene el codigo de la uaa de la unidad que solicita
        $HorarioSeleccionado = $obj->HorarioSeleccionado; //Contiene la lista del horario seleccionado
        $SedCodigo = $obj->SedCodigo; //Contiene el codigo de la sede donde se dara el curso
        $Administrador = intval($_SESSION["pacademica"]["datosVinculacionUsuario"]["Administrador"]); // Contiene si es administrador (1) o no (0)

        // Validación backend de apertura activa para módulo de solicitudes (tipo 3 = Servicio Docente)
        // Los administradores siempre pueden crear solicitudes.
        if ($Administrador != 1) {
            $now = FechaSqlServer::nowIso8601();
            $nowSql = FechaSqlServer::toSqlDateTime2($now, false);
            if ($nowSql === false) {
                return array(
                    "resultado" => false,
                    "mensaje" => "Formato de fecha inválido para validar apertura de solicitudes.",
                    "consola" => "No se pudo preparar la fecha actual ({$now}) para SQL Server.",
                );
            }
            $validacionApertura = $this->validarAperturaActivaSolicitud(
                3,
                intval($UaaCodigoSolicitada),
                intval($PeriodoCodigo),
                $nowSql,
                "SERVICIO DOCENTE"
            );

            if (!$validacionApertura["resultado"]) {
                return $validacionApertura;
            }
        }

        $existeSolicitudRechazada = self::consultaSolicitudRechazadaAsignatura($PeriodoCodigo, $AsiCodigo);

        if (isset($existeSolicitudRechazada['resultado']) && !$existeSolicitudRechazada['resultado']) {
            return array(
                "resultado" => false,
                "mensaje" => $existeSolicitudRechazada['mensaje'],
                "consola" => $existeSolicitudRechazada['mensaje'],
            );
        }

        $sql = "INSERT INTO programacionacademica.solicitud_prestamo_docente(
            periodo_codigo,
            asi_codigo,
            spd_estado,
            uaa_solicita,
            uaa_dirigida,
            sed_codigo
        )
        VALUES(
            {$PeriodoCodigo},
            {$AsiCodigo},
            1,
            {$UaaCodigoSolicitada},
            {$UaaCodigoDirigida},
            {$SedCodigo}
        )";

        if (!$this->cnx->sentencia($sql)) {
            $this->errorSentenciaBd["mensaje"] = "Error al crear la solicitud de prestamo docente. 
                Recargue la página e intente de nuevo.";
            $this->errorSentenciaBd["consola"] = "Ha fallado el insert de la solicitud " . __LINE__ . ".";
            return $this->errorSentenciaBd;
        }

        $sql = "SELECT TOP 1
                spd.spd_codigo SpdCodigo 
            FROM 
                programacionacademica.solicitud_prestamo_docente spd
            WHERE 
                spd.asi_codigo = {$AsiCodigo}
                AND spd.spd_estado = 1
                AND spd.uaa_solicita = {$UaaCodigoSolicitada}
                AND spd.uaa_dirigida = {$UaaCodigoDirigida}
            ORDER BY
                spd.spd_codigo DESC
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["mensaje"] = "No se pudo realizar la consulta de de la solicitud creada.";
            $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
            return $this->errorConsultarBd;
        }

        $SpdCodigo = $this->cnx->json;

        foreach ($HorarioSeleccionado as $horario) {
            $sql = "INSERT INTO programacionacademica.solicitud_prestamo_docente_horario(
                    spd_codigo,
                    dia_codigo,
                    hra_codigo,
                    spdh_estado
                )
                VALUES (
                    {$SpdCodigo[0]['SpdCodigo']},
                    {$horario->DiaCodigo},
                    {$horario->HraCodigo},
                    1
                )
            ";
            if (!$this->cnx->sentencia($sql)) {
                $this->errorSentenciaBd["mensaje"] = "Error al guardar el horario de la solicitud. 
                    Recargue la página e intente de nuevo.";
                $this->errorSentenciaBd["consola"] = "Ha fallado el insert del horario de la solicitud {$SpdCodigo} " . __LINE__ . ".";
                return $this->errorSentenciaBd;
            }
        }

        $obj->SpdCodigo = $SpdCodigo[0]['SpdCodigo'];
        $resCorreo = $this->enviarNotificacion($obj, 'Creacion');
        return array(
            "resultado" => true,
            "mensaje" => "La solicitud de prestamo docente se realizo correctamente.",
            "correo" => $resCorreo
        );
    }

    // Inicio funcion consultarUaaDepartamentos
    // consulta los departamentos disponibles
    public function consultarUaaDepartamentos($obj)
    {
        $UaaCodigoSolicitada = $obj->UaaCodigoSolicitada;
        $SedCodigo = $obj->SedCodigo;
        $unidadesEspeciales = "328,345,363,340";
        //$unidades = $_SESSION["pacademica"]["datosVinculacionUsuario"]["unidades"];
        $date = date('Y-m-d\TH:i:s', strtotime('-1 year')); // resta un año a la fecha actual y obtiene la fecha resultante en formato ISO 8601
        $dateSql = FechaSqlServer::toSqlDateTime2($date, false);
        if ($dateSql === false) {
            return array(
                "resultado" => false,
                "mensaje" => "Formato de fecha inválido al consultar departamentos.",
                "consola" => "No se pudo preparar la fecha SQL {$date}.",
            );
        }

        $sql = "SELECT
                    uaa.uaa_codigo_departamento UaaCodigo,
                    uaa.uaa_nombre_departamento UaaNombreCorto,
                    sed.sed_nombre SedNombre
                FROM
                    departamentos_programas_unificados uaa
                    INNER JOIN uaa_personal uap ON uap.uaa_codigo = uaa.uaa_codigo_departamento AND (uap.uap_fecha_inicio >= {$dateSql} OR uap.uap_fecha_fin IS NULL)
                    INNER JOIN agenda_periodo agp ON agp.uap_codigo = uap.uap_codigo
                    INNER JOIN programa AS pro ON uaa.pro_codigo = pro.pro_codigo
                    INNER JOIN sede AS sed ON pro.sed_codigo = sed.sed_codigo
                WHERE
                    uaa.uaa_codigo_departamento NOT IN ({$UaaCodigoSolicitada})
                    --AND sed.sed_codigo = {$SedCodigo}
                GROUP BY
                    uaa.uaa_codigo_departamento,
                    uaa.uaa_nombre_departamento,
                    sed.sed_nombre
                UNION
                SELECT 
                    uaa.uaa_codigo UaaCodigo,
                    uaa.uaa_nombre_corto UaaNombreCorto,
                    sed.sed_nombre SedNombre
                FROM 
                    uaa
                    INNER JOIN sede AS sed ON uaa.sed_codigo = sed.sed_codigo
                WHERE
                    uaa_codigo IN ({$unidadesEspeciales})
                    --AND sed.sed_codigo = {$SedCodigo}
                ORDER BY uaa.uaa_codigo_departamento ASC
                ";
                
        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["mensaje"] = "No se pudo realizar la consulta de departamentos disponibles.";
            $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
            return $this->errorConsultarBd;
        }
        return array(
            "resultado" => true,
            "mensaje" => "Departamentos consultados correctamente.",
            "data" => $this->cnx->json,
            "count" => count($this->cnx->json)
        );
    }

    // Inicio funcion consultarPeticionesPeriodo
    // consulta las peticiones de una Uaa
    public function consultarPeticionesPeriodo($obj)
    {

        // Validamos las variables recibidas que exista y que sea numerico
        if (!isset($obj->PerCodigo) || !is_numeric($obj->PerCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo del periodo.",
                "consola" => "El codigo del periodo no viene o no es numerico, " . $obj->PerCodigo,
            );
        }

        // Parametros 
        $PerCodigo = $obj->PerCodigo; // Contiene el codigo del periodo seleccionado
        $unidades = $_SESSION['pacademica']['datosVinculacionUsuario']['unidades']; //Contiene las unidades activas del usuario
        $unidades = is_array($unidades) ? implode(",", $unidades) : $unidades;

        //Query para obtener las solicitudes que han dirigido a mis unidades
        $sql = "SELECT 
            spd.spd_codigo SpdCodigo,
            per.per_nombre + ' ' + per.per_apellido PersonaNombreApellido,
            asi.asi_codigo AsiCodigo,
            asi.asi_nombre AsiNombre,
            asi.asi_nombre_corto AsiNombreCorto,
            spd_estado SpdEstado,
            uaaSolicita.uaa_codigo UaaSolicitaCodigo,
            uaaSolicita.uaa_nombre_corto UaaSolicitaNombre,
            uaaDirigida.uaa_codigo UaaDirigidaCodigo,
            uaaDirigida.uaa_nombre_corto UaaDirigidaNombre,
            periodo.per_codigo PeriodoCodigo, 
            periodo.per_nombre PeriodoNombre,
            periodo.per_periodo PeriodoPeriodo,
            sed.sed_codigo SedCodigo,
            sed.sed_nombre SedNombre
        FROM programacionacademica.solicitud_prestamo_docente spd
        LEFT JOIN persona per ON per.per_codigo = spd.persona_codigo
        INNER JOIN periodo periodo ON periodo.per_codigo = spd.periodo_codigo
        INNER JOIN asignatura asi ON asi.asi_codigo = spd.asi_codigo
        INNER JOIN uaa uaaSolicita ON uaaSolicita.uaa_codigo = spd.uaa_solicita
        INNER JOIN uaa uaaDirigida ON uaaDirigida.uaa_codigo = spd.uaa_dirigida
        INNER JOIN sede sed ON sed.sed_codigo = spd.sed_codigo
		WHERE 
            spd.uaa_dirigida IN ({$unidades})
            AND spd.periodo_codigo = {$PerCodigo}
            AND spd.spd_estado != 0
		ORDER BY per.per_nombre ASC, spd.spd_codigo DESC
		";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["mensaje"] = "No se pudo realizar la consulta de las solicitudes dirigidas de docentes a las unidades del usuario.";
            $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
            return $this->errorConsultarBd;
        }

        $solicitudesDirigidas = $this->cnx->json;

        //Query para obtener las solicitudes que he realizado
        $sql = "SELECT 
            spd.spd_codigo SpdCodigo,
            per.per_nombre + ' ' + per.per_apellido PersonaNombreApellido,
            asi.asi_codigo AsiCodigo,
            asi.asi_nombre AsiNombre,
            asi.asi_nombre_corto AsiNombreCorto,
            spd_estado SpdEstado,
            uaaSolicita.uaa_codigo UaaSolicitaCodigo,
            uaaSolicita.uaa_nombre_corto UaaSolicitaNombre,
            uaaDirigida.uaa_codigo UaaDirigidaCodigo,
            uaaDirigida.uaa_nombre_corto UaaDirigidaNombre,
            periodo.per_codigo PeriodoCodigo, 
            periodo.per_nombre PeriodoNombre,
            periodo.per_periodo PeriodoPeriodo,
            sed.sed_codigo SedCodigo,
            sed.sed_nombre SedNombre
        FROM programacionacademica.solicitud_prestamo_docente spd
        LEFT JOIN persona per ON per.per_codigo = spd.persona_codigo
        INNER JOIN periodo periodo ON periodo.per_codigo = spd.periodo_codigo
        INNER JOIN asignatura asi ON asi.asi_codigo = spd.asi_codigo
        INNER JOIN uaa uaaSolicita ON uaaSolicita.uaa_codigo = spd.uaa_solicita
        INNER JOIN uaa uaaDirigida ON uaaDirigida.uaa_codigo = spd.uaa_dirigida
        INNER JOIN sede sed ON sed.sed_codigo = spd.sed_codigo
		WHERE 
            spd.uaa_solicita IN ({$unidades})
            AND spd.periodo_codigo = {$PerCodigo}
            AND spd.spd_estado != 0
        ORDER BY per.per_nombre ASC, spd.spd_codigo DESC
		";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["mensaje"] = "No se pudo realizar la consulta de las solicitudes realizadas de docentes a las unidades del usuario.";
            $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
            return $this->errorConsultarBd;
        }

        $solicitudesRealizadas = $this->cnx->json;

        //Obtenemos el horario de las solicitudes
        foreach ($solicitudesDirigidas as &$solicitud) {
            $objSpdCodigo = (object)['SpdCodigo' => $solicitud["SpdCodigo"]];
            $horario = self::consultarHorarioSolicitud($objSpdCodigo);
            if ($horario != "" && $horario["resultado"]) {
                $solicitud["Horario"] = $horario["data"];
            }
        }

        foreach ($solicitudesRealizadas as &$solicitud) {
            $objSpdCodigo = (object)['SpdCodigo' => $solicitud["SpdCodigo"]];
            $horario = self::consultarHorarioSolicitud($objSpdCodigo);
            if ($horario != "" && $horario["resultado"]) {
                $solicitud["Horario"] = $horario["data"];
            }
        }

        return array(
            "resultado" => true,
            "mensaje" => "Solicitudes de docentes consultadas correctamente.",
            "dirigidas" => $solicitudesDirigidas,
            "countDirigidas" => count($solicitudesDirigidas),
            "realizadas" => $solicitudesRealizadas,
            "countRealizadas" => count($solicitudesRealizadas)
        );
    }

    public function consultarSedes()
    {
        //Parametros:

        $sql = "SELECT DISTINCT
            sed.sed_codigo SedCodigo,
            sed.sed_nombre SedNombre
        FROM
            sede sed
        WHERE
            sed.sed_estado = 1 AND sed.sed_codigo != 20
        ORDER BY 
            sed.sed_codigo
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar las sedes.";
            return $this->errorConsultarBd;
        }

        return array(
            "resultado" => true,
            "mensaje" => "Sedes consultadas correctamente.",
            "data" => $this->cnx->json
        );
    }
}
