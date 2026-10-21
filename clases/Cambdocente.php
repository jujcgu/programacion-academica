<?php
header('Content-Type: text/html; charset=utf-8');
require_once(dirname(__FILE__) . '/servicios/FechaSqlServer.php');
require_once(dirname(__FILE__) . '/servicios/ValidarCargaDocenteService.php');

class Cambdocente
{

    private $cnx = null;
    private $tipoSolicitudCambioDocente = 4;

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

    private function consultarContextoCursoApertura($CurCodigo)
    {
        $sql = "SELECT TOP 1
                cur.cur_codigo CurCodigo,
                cur.cal_codigo CalCodigo,
                cal.per_codigo PerCodigo,
                (
                    SELECT TOP 1 eso.uaa_codigo
                    FROM espacio_ocupacion eso
                    WHERE eso.eso_actividad = cur.cur_codigo
                ) UaaProgramada
            FROM curso cur
            INNER JOIN calendario cal ON cal.cal_codigo = cur.cal_codigo
            WHERE cur.cur_codigo = {$CurCodigo}";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar el contexto de apertura del curso {$CurCodigo}.";
            return $this->errorConsultarBd;
        }

        if (count($this->cnx->json) <= 0) {
            return array(
                "resultado" => false,
                "mensaje" => "No se encontró el curso seleccionado.",
                "consola" => "No existe curso con código {$CurCodigo}."
            );
        }

        if ($this->cnx->json[0]["UaaProgramada"] == '') {
            return array(
                "resultado" => false,
                "mensaje" => "El curso seleccionado no tiene unidad programada en horario.",
                "consola" => "No se encontró uaa_codigo en espacio_ocupacion para el curso {$CurCodigo}."
            );
        }

        return array(
            "resultado" => true,
            "data" => $this->cnx->json[0]
        );
    }

    private function consultarAperturaProgramacionActiva($CalCodigo, $UaaCodigo)
    {
        $fechaActual = FechaSqlServer::toSqlDateTime2(date('Y-m-d\TH:i:s'), false);
        if ($fechaActual === false) {
            return array(
                "resultado" => false,
                "mensaje" => "Formato de fecha inválido para validar apertura de programación.",
                "consola" => "No se pudo preparar la fecha actual para SQL Server."
            );
        }

        $sql = "SELECT TOP 1 pra.pra_codigo PraCodigo
            FROM programacionacademica.programacion_academica pra
            WHERE
                pra.pra_estado = 1
                AND pra.prp_codigo != 4
                AND pra.cal_codigo = {$CalCodigo}
                AND pra.uaa_codigo = {$UaaCodigo}
                AND {$fechaActual} BETWEEN pra.pra_fecha_inicio AND pra.pra_fecha_fin";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al validar apertura de programación académica para calendario {$CalCodigo} y UAA {$UaaCodigo}.";
            return $this->errorConsultarBd;
        }

        return array(
            "resultado" => true,
            "activa" => count($this->cnx->json) > 0
        );
    }

    private function consultarAperturaSolicitudCambioDocenteActiva($PerCodigo, $UaaCodigo)
    {
        $fechaActual = FechaSqlServer::toSqlDateTime2(date('Y-m-d\TH:i:s'), false);
        if ($fechaActual === false) {
            return array(
                "resultado" => false,
                "mensaje" => "Formato de fecha inválido para validar apertura de cambio docente.",
                "consola" => "No se pudo preparar la fecha actual para SQL Server."
            );
        }

        $sql = "SELECT TOP 1 prg.prg_codigo PrsCodigo
            FROM programacionacademica.programacion_gestion prg
            INNER JOIN calendario cal ON cal.cal_codigo = prg.cal_codigo
            WHERE
                prg.prg_estado = 1
                AND prg.pts_codigo = {$this->tipoSolicitudCambioDocente}
                AND prg.uaa_codigo = {$UaaCodigo}
                AND cal.per_codigo = {$PerCodigo}
                AND {$fechaActual} BETWEEN prg.prg_fecha_inicio AND prg.prg_fecha_fin";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al validar apertura de solicitud cambio docente para periodo {$PerCodigo} y UAA {$UaaCodigo}.";
            return $this->errorConsultarBd;
        }

        return array(
            "resultado" => true,
            "activa" => count($this->cnx->json) > 0
        );
    }

    private function validarAperturaCambioDocenteCurso($CurCodigo)
    {
        if ($_SESSION['pacademica']['datosVinculacionUsuario']['grupoId'] == 'PROGRAMACION_ACADEMICA_ADMINISTRADOR') {
            return array(
                "resultado" => true,
                "mensaje" => "Cambio docente habilitado para administrador.",
                "PermitidoProgramar" => true,
                "AperturaProgramacionActiva" => true,
                "AperturaCambioDocenteActiva" => true
            );
        }

        $contexto = $this->consultarContextoCursoApertura($CurCodigo);
        if (!$contexto["resultado"]) {
            return $contexto;
        }

        $CalCodigo = $contexto["data"]["CalCodigo"];
        $PerCodigo = $contexto["data"]["PerCodigo"];
        $UaaProgramada = $contexto["data"]["UaaProgramada"];

        $aperturaProgramacion = $this->consultarAperturaProgramacionActiva($CalCodigo, $UaaProgramada);
        if (!$aperturaProgramacion["resultado"]) {
            return $aperturaProgramacion;
        }

        $aperturaCambioDocente = $this->consultarAperturaSolicitudCambioDocenteActiva($PerCodigo, $UaaProgramada);
        if (!$aperturaCambioDocente["resultado"]) {
            return $aperturaCambioDocente;
        }

        $permitido = $aperturaProgramacion["activa"] || $aperturaCambioDocente["activa"];

        return array(
            "resultado" => $permitido,
            "mensaje" => $permitido ? "Cambio docente habilitado." : "El curso no tiene apertura activa de programación académica ni apertura activa de solicitud de cambio docente.",
            "consola" => $permitido ? "" : "Sin apertura activa para curso {$CurCodigo}, calendario {$CalCodigo}, periodo {$PerCodigo}, UAA {$UaaProgramada}.",
            "PermitidoProgramar" => $permitido,
            "AperturaProgramacionActiva" => $aperturaProgramacion["activa"],
            "AperturaCambioDocenteActiva" => $aperturaCambioDocente["activa"]
        );
    }

    public function consultarPermisoCambioDocente($obj)
    {
        if (!isset($obj->CurCodigo) || !is_numeric($obj->CurCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe ingresar el código del curso que desea consultar.",
                "consola" => "El codigo del curso no es numérico o no se envio correctamente.",
            );
        }

        $validacion = $this->validarAperturaCambioDocenteCurso($obj->CurCodigo);
        if (!$validacion["resultado"] && !isset($validacion["PermitidoProgramar"])) {
            return $validacion;
        }

        return array(
            "resultado" => true,
            "mensaje" => $validacion["mensaje"],
            "PermitidoProgramar" => isset($validacion["PermitidoProgramar"]) ? $validacion["PermitidoProgramar"] : false,
            "AperturaProgramacionActiva" => isset($validacion["AperturaProgramacionActiva"]) ? $validacion["AperturaProgramacionActiva"] : false,
            "AperturaCambioDocenteActiva" => isset($validacion["AperturaCambioDocenteActiva"]) ? $validacion["AperturaCambioDocenteActiva"] : false
        );
    }

    // Se habilita temporalmente a los administradores para eliminar semanas de mas.
    // Inicio funcion eliminarHorarioSeleccionado
    // Permie eliminar un horario seleccionado
    function eliminarHorarioSeleccionado($obj)
    {
        if (!isset($obj->listaHorarioSeleccionado) || count($obj->listaHorarioSeleccionado) < 1) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar el horario que desea cambiar el docente.",
                "consola" => "Los horarios para cambiar el docente no se enviaron correctamente.",
            );
        }
        if (!isset($obj->CurCodigo) || !is_numeric($obj->CurCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar un curso.",
                "consola" => "El codigo del curso no es numérico o no se envio correctamente.",
            );
        }
        $Administrador = $_SESSION["pacademica"]["datosVinculacionUsuario"]["Administrador"]; //Para saber si es un administrador.

        if ($Administrador != 1) {
            return array(
                "resultado" => false,
                "mensaje" => "La eliminacion de horas solo esta disponible para los administradores.",
                "consola" => "La eliminacion de horas solo esta disponible para los administradores."
            );
        }

        $listaHorarioSeleccionado = $obj->listaHorarioSeleccionado; // contiene un arreglo con los codigos de la tabla espacio ocupacion para cambiar el docente.
        $CurCodigo = $obj->CurCodigo; //contiene el codigo del curso que queremos cambiar.
        $implodeListaHorario = implode(",", $listaHorarioSeleccionado);

        if ($implodeListaHorario != "") {
            $sql = "DELETE FROM espacio_ocupacion WHERE eso_codigo IN ({$implodeListaHorario})";
            if (!$this->cnx->sentencia($sql)) {
                $this->errorSentenciaBd["mensaje"] = "Error al eliminar las horas seleccionadas.";
                $this->errorSentenciaBd["consola"] = "Error al eliminar las horas {$implodeListaHorario}";
                return $this->errorSentenciaBd;
            }
            return array(
                "resultado" => true,
                "mensaje" => "Se eliminaron las horas seleccionadas.",
            );
        }
        return array(
            "resultado" => false,
            "mensaje" => "No se pudo realizar la eliminacion de las horas seleccionadas.",
            "consola" => "Los horarios para cambiar el docente no se enviaron correctamente.",
        );
    }

    //Inicio funcion consultarDocentesPrestados
    //Permite consultar los docentes prestados aprobados.
    function consultarDocentesPrestados($obj)
    {
        //Validaciones
        if (!isset($obj->CurCodigo) || !is_numeric($obj->CurCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar un curso.",
                "consola" => "El codigo del curso no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->CalCodigo) || !is_numeric($obj->CalCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se encontró el código del calendario del curso seleccionado.",
                "consola" => "El codigo del calendario no es numérico o no se envio correctamente.",
            );
        }

        //Parametros
        $unidades = $_SESSION["pacademica"]["datosVinculacionUsuario"]["unidades"]; // Contiene las unidades vinculadas al usuario.
        $CalCodigo = $obj->CalCodigo; // Contiene el codigo del calendario
        $CurCodigo = $obj->CurCodigo; // Contiene el codigo del curso

        // Obtenemos la Uaa con la que se programo el curso.
        $sql = "SELECT eso.uaa_codigo UaaCodigo 
            FROM espacio_ocupacion eso 
            WHERE eso_actividad = {$CurCodigo} 
            GROUP BY eso.uaa_codigo
        ";
        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar la unidad programada del curso.";
            return $this->errorConsultarBd;
        }

        $r_uaa_programada = $this->cnx->json;

        if (count($r_uaa_programada) > 1) {
            return array(
                "resultado" => false,
                "mensaje" => "El curso {$CurCodigo} tiene horario programado con mas de una Unidad, por favor verificar en Cambio de Unidad.",
                "console" => "El curso {$CurCodigo} tiene horario programada con mas de una Unidad (" . count($r_uaa_programada) . ") .",
            );
        }

        $UaaCodigo = $r_uaa_programada[0]["UaaCodigo"]; //Contiene el codigo de la uaa que se programo.

        // Consultamos el periodo de un calendario especifico.
        $sql = "SELECT
            per.per_codigo PerCodigo,
            CONVERT(date, per.per_fecha_inicio) PerFechaInicio,
            CONVERT(date, per.per_fecha_fin) PerFechaFin
        FROM calendario cal
        INNER JOIN periodo per ON per.per_codigo = cal.per_codigo
        WHERE
            cal.cal_codigo = {$CalCodigo}
        ";
        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar el periodo del calendario {$CalCodigo}.";
            return $this->errorConsultarBd;
        }

        $r_periodo = $this->cnx->json; // Contiene el periodo y sus fechas por defecto.
        $PerCodigo = $r_periodo[0]["PerCodigo"]; //Se establece el codigo del periodo del calendario
        $PerFechaInicio = $r_periodo[0]["PerFechaInicio"]; //Se establece la fecha de inicio por defecto del periodo
        $PerFechaFin = $r_periodo[0]["PerFechaFin"]; //Se establece la fecha de fin por defecto del periodo

        //Consultamos si la uaa tiene periodo personalizado activo
        $sql = "SELECT
            peu.peu_fecha_inicio PeuFechaInicio,
            peu.peu_fecha_fin PeuFechaFin
        FROM
            programacionacademica.periodo_unidad peu
        WHERE
            peu.uaa_codigo = {$UaaCodigo}
            AND peu.per_codigo = {$PerCodigo}
            AND peu.peu_estado = 1
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar el periodo personalizado de la unidad {$UaaCodigo} en el calendario {$CalCodigo}.";
            return $this->errorConsultarBd;
        }

        $r_periodo_personalizado = $this->cnx->json; // Contiene el periodo personalizado de la unidad con el periodo

        // Verificamos si el programa tiene periodo personalizado.
        if (count($r_periodo_personalizado) > 0) {
            $PerFechaInicio = $r_periodo_personalizado[0]["PeuFechaInicio"]; //Se establece la fecha de inicio del periodo personalizado.
            $PerFechaFin = $r_periodo_personalizado[0]["PeuFechaFin"]; //Se establece la fecha de fin del periodo personalizado.
        }

        $array_final = array();

        $array_final["FechaInicio"] = $PerFechaInicio;
        $array_final["FechaFin"] = $PerFechaFin;
        $PerFechaInicioSql = FechaSqlServer::toSqlDateTime2($PerFechaInicio, false);
        $PerFechaFinFinDiaSql = FechaSqlServer::toSqlDateTime2($PerFechaFin, true);
        if ($PerFechaInicioSql === false || $PerFechaFinFinDiaSql === false) {
            return array(
                "resultado" => false,
                "mensaje" => "Formato de fecha inválido para consultar docentes prestados.",
                "consola" => "No se pudieron preparar fechas SQL de periodo ({$PerFechaInicio} - {$PerFechaFin}).",
            );
        }

        // Consultamos las solicitudes aprobadas para la unidad en la que esta programando.
        $sql = "SELECT
                uap.uap_codigo UapCodigo,
                sed.sed_codigo SedCodigo,
                sed.sed_nombre SedNombre,
                per.per_nombre PerNombre,
                per.per_apellido PerApellido,
                per.per_codigo PerCodigo,
                CONVERT(varchar, per.per_nombre) + '. ' + CONVERT(varchar, per.per_apellido) PerNombreApellido,
                per.per_identificacion PerIdentificacion,
                vin.vin_nombre VinNombre,
                vin.vin_codigo VinCodigo,
                ded.ded_codigo DedCodigo,
                ded.ded_nombre DedNombre,
                uap.uap_fecha_inicio UapFechaInicio,
                uap.uap_fecha_fin UapFechaFin,
                asi.asi_codigo AsiCodigo,
                asi.asi_nombre AsiNombre,
                asi.asi_nombre_corto AsiNombreCorto,
                spd.spd_codigo SpdCodigo,
                uaa.uaa_codigo UaaCodigo,
                uaa.uaa_nombre_corto UaaNombreCorto,
                CONVERT(varchar, uaa.uaa_codigo) + '. ' + uaa.uaa_nombre_corto UaaNombreSolicita,
                CONVERT(varchar, uaadpto.uaa_codigo) + '. ' + uaadpto.uaa_nombre_corto UaaNombreDpto,
                (   
                            SELECT count(*)
                FROM agenda_periodo agp
                WHERE agp.uap_codigo = uap.uap_codigo 
                        ) UapCarga
            FROM
                programacionacademica.solicitud_prestamo_docente spd
                INNER JOIN sede sed ON sed.sed_codigo = spd.sed_codigo
                INNER JOIN asignatura asi ON asi.asi_codigo = spd.asi_codigo
                INNER JOIN uaa ON uaa.uaa_codigo = spd.uaa_solicita
                INNER JOIN uaa_personal uap ON uap.per_codigo = spd.persona_codigo
                INNER JOIN vinculacion vin ON vin.vin_codigo = uap.vin_codigo
                INNER JOIN dedicacion ded ON ded.ded_codigo = uap.ded_codigo
                INNER JOIN uaa uaadpto ON uaadpto.uaa_codigo = uap.uaa_codigo
                INNER JOIN persona per ON per.per_codigo = uap.per_codigo
            WHERE   
                spd.periodo_codigo = {$PerCodigo}
                AND vin.vin_codigo IN (24,12,23,14,5,24,16,49)
                AND spd.uaa_solicita in ({$unidades})
                AND spd.spd_estado = 2
                AND (
                        (
                            uap.uap_fecha_inicio >= {$PerFechaInicioSql}
                            AND uap.uap_fecha_fin <= {$PerFechaFinFinDiaSql}
                            AND uap.uap_fecha_inicio != uap.uap_fecha_fin
                        )
                    OR
                        (
                            uap.uap_fecha_fin IS NULL
                        )
                    )
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar los docentes prestados aprobados con vinculación vigente.";
            $this->errorConsultarBd["sql"] = $sql;
            return $this->errorConsultarBd;
        }

        $array_final["Docentes"] = $this->cnx->json;

        foreach ($array_final["Docentes"] as $key => $docente) {
            $SpdCodigo = $docente["SpdCodigo"]; //Contiene el codigo de la solicitud especifica
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

            $array_final["Docentes"][$key]["Horario"] = $this->cnx->json;
        }

        return array(
            "resultado" => true,
            "mensaje" => "Docentes Prestados consultados correctamente.",
            "data" => $array_final
        );
    }

    //Inicia funcion validarHorarioCrear
    //Permite validar la cantidad de horas que tiene un docente asignadas y si le es permitido asignarle mas horas.
    function validarHorasDocente($obj)
    {

        //Validaciones
        if (!isset($obj->UapCodigo) || !is_numeric($obj->UapCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo de vinculación del docente.",
                "consola" => "El codigo de vinculación del docente no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->CurCodigo) || !is_numeric($obj->CurCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo del curso seleccionado.",
                "consola" => "El codigo del curso no es numérico o no se envio correctamente.",
            );
        }

        //Asignaciones
        $UapCodigo = $obj->UapCodigo; //Contiene el codigo de vinculacion del docente seleccionado
        $CurCodigo = $obj->CurCodigo; //Contiene el codigo del curso seleccionado
        $SubGrupo = $obj->SubGrupo; //Contiene el subgrupo del horario seleccionado

        //Consultamos lo relacionado al calendario, periodo, curso, asignatura
        $sql = "SELECT 
                cal.cal_codigo CalCodigo,
                per.per_codigo PeriodoCodigo,
                asi.asi_creditos_teoria AsiCreditosTeoria,
                asi.asi_creditos_practica AsiCreditosPractica,
                asi.car_codigo CarCodigo,
                cur.cur_semanas CurSemanas
            FROM curso cur 
            INNER JOIN calendario cal ON cal.cal_codigo = cur.cal_codigo
            INNER JOIN periodo per ON per.per_codigo = cal.per_codigo
            INNER JOIN asignatura asi ON asi.asi_codigo = cur.asi_codigo
            WHERE
                cur.cur_codigo = {$CurCodigo}
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar información del curso {$CurCodigo}.";
            return $this->errorConsultarBd;
        }

        $r_curso = $this->cnx->json;

        $CalCodigo = $r_curso[0]["CalCodigo"]; //Contiene el codigo del calendario en el que se va a programar
        $PerCodigo = $r_curso[0]["PeriodoCodigo"]; //Contiene el codigo del periodo.
        $CarCodigo = trim($r_curso[0]["CarCodigo"]); //Contiene el caracter de la asignatura.
        $AsiCreditosTeoria = $r_curso[0]["AsiCreditosTeoria"]; //Contiene los creditos teoricos de la asignatura.
        $AsiCreditosPractica = $r_curso[0]["AsiCreditosPractica"]; //Contiene los creditos practicos de la asignatura.
        $CurSemanas = $r_curso[0]["CurSemanas"]; //Contiene el numero total de semanas del curso seleccionado.

        //Consultamos lo relacionado a la vinculacion del docente seleccionado
        $sql = "SELECT
                uap.ded_codigo DedCodigo,
                uap.vin_codigo VinCodigo,
                uap.per_codigo PerCodigo,
                uap.sed_codigo SedCodigo
            FROM uaa_personal uap
            WHERE
                uap.uap_codigo = {$UapCodigo}
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar información de la vinculación {$UapCodigo}.";
            return $this->errorConsultarBd;
        }

        $r_vinculacion = $this->cnx->json;

        $DedCodigo = $r_vinculacion[0]["DedCodigo"]; //Contiene el codigo de la dedicación del docente.
        $VinCodigo = $r_vinculacion[0]["VinCodigo"]; //Contiene el codigo de la vinculación del docente.
        $UapPerCodigo = $r_vinculacion[0]["PerCodigo"]; //Contiene el codigo de la persona del docente.
        $UapSedCodigo = $r_vinculacion[0]["SedCodigo"]; //Contiene el codigo de la sede del docente.

        // Recorremos el horario seleccionado, necesitamos sacar el total de horas semanales
        $arrayHorasSeleccionadas = array(); //Contiene las horas nuevas que se le van a adicionar al docente.
        $arrayFechasSeleccionadas = array(); //Contiene las fechas seleccionadas
        $uaaHorasSeleccionadas = array(); //Contiene la uaa con la que se programo el curso.
        $uaaProgramada = ""; //Contiene la uaa con la que se programa.
        foreach ($obj->listaHorarioSeleccionado as $horas) {
            $arrayFechasSeleccionadas[] = $horas->EsoFecha;
            if (!in_array($horas->DiaHoraCodigo, $arrayHorasSeleccionadas)) {

                // Se busca si es una adición de semanas (Ya dicta el curso).
                $r_horario = array();
                $sql = "SELECT COUNT(*) as Cantidad
                FROM espacio_ocupacion eso 
                WHERE eso.uap_codigo = {$UapCodigo} 
                AND eso.eso_actividad = {$CurCodigo} 
                AND eso.dia_codigo = {$horas->DiaCodigo} 
                AND eso.hra_codigo = {$horas->HoraCodigo}
                AND eso.eso_subgrupo = {$SubGrupo};
                ";

                if (!$this->cnx->consultar($sql)) {
                    $this->errorConsultarBd["consola"] = "Error al consultar el horario {$horas->EsoCodigo}.";
                    return $this->errorConsultarBd;
                }

                $r_horario = $this->cnx->json;
                $existente = intval($r_horario[0]['Cantidad']);

                if ($existente == 0) {
                    // Si no se encuentra el valor en ese array y no es una adición de semanas, se almacena.
                    $arrayHorasSeleccionadas[] = $horas->DiaHoraCodigo;
                }
            }
            if (!in_array($horas->UaaCodigo, $uaaHorasSeleccionadas)) {
                // Si no se encuentra el valor en ese array se almacena.
                $uaaHorasSeleccionadas[] = $horas->UaaCodigo;
            }
        }

        // Convertir las cadenas a timestamps
        $fechas = array_map('strtotime', $arrayFechasSeleccionadas);

        // Obtener la fecha mínima y máxima
        $fechaMinima = date('Y-m-d', min($fechas));
        $fechaMaxima = date('Y-m-d', max($fechas));
        $fechaInicio = new DateTime($fechaMinima);
        $fechaFin = new DateTime($fechaMaxima);

        $intervalo = $fechaInicio->diff($fechaFin);
        $CurSemanas = floor($intervalo->days / 7) + 1;

        $cantidad_horas_nuevas = count($arrayHorasSeleccionadas); //Contamos la cantidad de horas que se programan, 1,2,10,11 (4 horas nuevas semanales)

        if (count($uaaHorasSeleccionadas) <= 1) {
            $uaaProgramada = $uaaHorasSeleccionadas[0];
        } else {
            $error = implode(', ', $uaaHorasSeleccionadas);
            return array(
                "resultado" => false,
                "mensaje" => "ERROR. el curso se ha programado con 2 unidades diferentes ({$error}), por favor corregirlo en el administrador de secretarias, cambio de unidad."
            );
        }

        //Obtenemos la dependencia de la unidad con la que se programo
        $sql = "SELECT 
            dep.uaa_codigo UaaCodigo,
            dep.uaa_nombre UaaNombre,
            dep.uaa_nombre_corto UaaNombreCorto,
            CONVERT(VARCHAR, dep.uaa_codigo) + '. ' + dep.uaa_nombre_corto UaaCodigoNombreCorto
        FROM uaa pro
        INNER JOIN uaa dep ON dep.uaa_codigo = pro.uaa_dependencia
        WHERE 
            pro.uaa_codigo = {$uaaProgramada}";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar la dependencia de la unidad {$uaaProgramada}.";
            return $this->errorConsultarBd;
        }

        if (count($this->cnx->json) < 1) {
            return array(
                "resultado" => false,
                "mensaje" => "ERROR. no se encontraron dependencias para la unidad {$uaaProgramada}."
            );
        }
        $r_dependencia = $this->cnx->json; //Contiene la informacion de la dependencia.
        $UaaDependencia = $r_dependencia[0]['UaaCodigo']; //Contiene el codigo de la dependencia de la unidad seleccionada.

        $respuesta = array(); //Se usara para almacenar la respuesta que se obtiene de la funcion guardarHorario();
        $obj->PerNN = false;


        //Evaluamos si es un NN catedra
        $sql = "SELECT per.per_codigo PerCodigo FROM persona per WHERE per.per_apellido LIKE '%CATEDRA%' AND per.per_codigo = {$UapPerCodigo}";
        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar si el docente es un NN CATEDRA.";
            return $this->errorConsultarBd;
        }
        $r_docente_nn = $this->cnx->json;
        $perNN = false; //Contiene si (true) el docente es NN catedra o no (false)
        if (count($r_docente_nn) > 0) {
            $perNN = true; //En caso de ser docente NN catedra true.
        }

        $obj->PerNN = $perNN; //Almacenamos al array que enviaremos para programacion si el docente es un NN.

        $servicioCargaDocente = new ValidarCargaDocenteService($this->cnx);

        $control_tope_horas = 0; //Se usa para controlar el tope permitido de horas.
        $total_horas = 0; //total de horas docente consultadas desde espacio_ocupacion.
        $total_horas_pp = 0; //total de horas practica pedagogica docente consultadas desde agenda_periodo.
        $total_horas_pp_sem = 0; //total de horas semanales practica pedagogica docente consultadas desde agenda_periodo.
        $total_horas_inv_tesis = 0; //total de horas proyecto de investigacion o direccion de tesis
        $total_horas_descarga = 0; //total de horas descarga academica
        $cantidad_horas_nuevas_total = 0; //total de horas nuevas, se usa para calcular.
        $total_horas_novedad = 0; //total de horas de novedad se usa solo para de planta  o nombramiento ocacional
        $total_horas_factor = 0; //total de horas de agenda periodo se usa solo para de planta  o nombramiento ocacional

        $r_total_horas = $servicioCargaDocente->obtenerTotalHorasCatedraSinPractica($UapCodigo);
        if (!$r_total_horas["resultado"]) {
            return $r_total_horas;
        }
        $control_tope_horas = 224; //Se establece el tope de horas
        $total_horas = $r_total_horas["data"]["totalHoras"];

        $r_total_horas_practica = $servicioCargaDocente->obtenerHorasPracticaPedagogica($UapCodigo);
        if (!$r_total_horas_practica["resultado"]) {
            return $r_total_horas_practica;
        }
        $control_tope_horas = 252; //Se establece el tope de horas
        $total_horas_pp = $r_total_horas_practica["data"]["totalPP"]; //Se almacena la cantidad total de horas practica pedagogica del catedratico actualmente.
        $total_horas_pp_sem = $r_total_horas_practica["data"]["horasSemanal"]; //Se almacena la cantidad de horas semanal practica pedagogica del catedratico actualmente.

        // 14	CATEDRA DOCENTE
        // 24	CATEDRA VISITANTE DOCENTE
        // 49	CATEDRA CONVENIO DOCENTE
        //  6   POR HORAS
        if (($VinCodigo == 14 or $VinCodigo == 24 or $VinCodigo == 49) &&  $DedCodigo == 6) {
            //VERIFICAR MAXIMO DE CARGAR POR SEDE CATEDRATICO
            $max_horas_catedratico_sedes = 0; //Almacenamos por defecto 0 horas del total de horas permitidas en sede.
            $max_horas_catedratico = 0; //Almacenamos por defecto 0 horas del total de horas permitidas en Neiva.
            $r_topes_catedra = $servicioCargaDocente->obtenerTopesSemanalesCatedra($UapSedCodigo);
            if (!$r_topes_catedra["resultado"]) {
                return $r_topes_catedra;
            }
            $max_horas_catedratico_sedes = $r_topes_catedra["data"]["topeSedes"];
            $max_horas_catedratico = $r_topes_catedra["data"]["topeNeiva"];

            $r_periodo_nombre = $servicioCargaDocente->obtenerPeriodoNombrePorCodigo($PerCodigo);
            if (!$r_periodo_nombre["resultado"]) {
                return $r_periodo_nombre;
            }
            $periodoNombre = $r_periodo_nombre["data"]["periodoNombre"];

            //Calcular el pico total semanal del docente (docencia + investigación + proyección + gestión)
            $r_pico_total = $servicioCargaDocente->calcularPicoTotalSemanal($UapCodigo, $periodoNombre, $UaaDependencia, $obj->listaHorarioSeleccionado);
            if (!$r_pico_total["resultado"]) {
                return $r_pico_total;
            }
            $pico_semana_catedra_actual = $r_pico_total["data"]["PicoDocenciaActual"];
            $pico_semana_catedra = $r_pico_total["data"]["PicoDocencia"];
            $pico_total_actual = $r_pico_total["data"]["PicoTotalActual"];
            $pico_total = $r_pico_total["data"]["PicoTotal"];

            // Carga complementaria semanal (proyectos + novedades) alineada con Agenda Docente.
            $cargaComplementariaSemanal = $servicioCargaDocente->obtenerCargaComplementariaSemanal($UapPerCodigo, $PerCodigo, true);
            if (!$cargaComplementariaSemanal["resultado"]) {
                return $cargaComplementariaSemanal;
            }

            $control_tope_horas = 252; //Se establece el tope de horas
            $total_horas_inv_tesis = floatval($cargaComplementariaSemanal["data"]["proyectosSemanal"]);
            $total_horas_novedad = floatval($cargaComplementariaSemanal["data"]["novedadesSemanal"]);

            //Comparamos si cuenta con horas de practica pedagogica, proyectos de investigacion o direccion de tesis.
            if ($total_horas_inv_tesis > 0 || $total_horas_pp > 0) {
                $control_tope_horas = 288;
            } else {
                $control_tope_horas = 252;
            }

            //Validacion si la dependencia de la unidad es la facultad de salud con codigo 23
            if ($UaaDependencia == 23) {
                $control_tope_horas = 288;
            }

            $cantidad_horas_nuevas_total = $cantidad_horas_nuevas * $CurSemanas; //Se calcula para trazabilidad.
            $total_horas_descarga = $pico_total; //Se calcula la carga semanal proyectada con pico total real (docencia + complementarias).
            $topeSemanalCatedra = $UapSedCodigo != 1 ? floatval($max_horas_catedratico_sedes) : floatval($max_horas_catedratico);

            // Regla reforzada: si ya está en el tope y la nueva selección incrementa el pico real, se bloquea.
            if ($perNN == false && $pico_total_actual >= $topeSemanalCatedra && $pico_total > $pico_total_actual) {
                return array(
                    "resultado" => false,
                    "mensaje" => "No se pueden adicionar horas: el docente ya se encuentra en el tope semanal ({$topeSemanalCatedra}), la nueva carga supera su máximo ({$pico_total_actual} -> {$pico_total}).",
                    "line" => __LINE__
                );
            }

            //Se verifica que el total de horas de descarga no super el tome establecido
            // if ($control_tope_horas >= $total_horas_descarga) {
            //     // Se procede a realizar la programacion
            //     $respuesta = array(
            //         "resultado" => true,
            //         "mensaje" => "Se procede a realizar la programación, control_tope_horas >= total_horas_descarga ($control_tope_horas >= $total_horas_descarga). ",
            //         "line" => __LINE__
            //     );
            // } else {
            // }
            if ($perNN == true) { //En caso de pasar el tope se pregunta si es un docente NN
                //Se procede a realizar la programacion y se avisa que es un docente NN.
                $respuesta = array(
                    "resultado" => true,
                    "mensaje" => "Se procede a realizar la programación, pero es un docente NN. Carga semanal proyectada: {$total_horas_descarga}.",
                    "line" => __LINE__
                );
            } else {
                //En caso de superar las horas de descarga al tope
                if ($UapSedCodigo != 1) { //Validamos si es de sede diferente a neiva
                    // $cantidad_horas_nuevas_total = $cantidad_horas_nuevas + $horas_semanal_catedratico_sede; //Se calcula el total de horas nuevas en la semana por el total de semanas del curso.
                    if ($total_horas_descarga > $topeSemanalCatedra) { //En caso de que el total de horas de descarga sea mayor que el maximo permitido para catedraticos en sede
                        $respuesta = array(
                            "resultado" => false,
                            "mensaje" => "ERROR. No se pueden adicionar las horas porque supera el límite de horas semanales, límite horas semanal en sedes: {$topeSemanalCatedra}, horas que tendría el docente: {$total_horas_descarga} (pico total semanal).",
                            "line" => __LINE__
                        );
                    } else {
                        //Se procede a realizar la programacion.
                        $respuesta = array(
                            "resultado" => true,
                            "mensaje" => "Se procede a realizar la programación, es docente de una sede y no supera el tope semanal ({$total_horas_descarga} <= {$topeSemanalCatedra}), pico semanal docencia: {$pico_semana_catedra}.",
                            "line" => __LINE__
                        );
                    }
                } else {
                    // $cantidad_horas_nuevas_total = $cantidad_horas_nuevas + $horas_semanal_catedratico; //Se calcula el total de horas nuevas en la semana por el total de semanas del curso.
                    if ($total_horas_descarga > $topeSemanalCatedra) { //En caso de que el total de horas de descarga sea mayor que el maximo permitido para catedraticos en neiva que son 16, esto esta en el acuerdo 048 de 2018 usco
                        $respuesta = array(
                            "resultado" => false,
                            "mensaje" => "ERROR. No se pueden adicionar las horas porque supera el límite de horas semanales, límite horas semanal en Neiva: {$topeSemanalCatedra}, horas que tendría el docente: {$total_horas_descarga} (pico total semanal).",
                            "line" => __LINE__
                        );
                    } else {
                        //Se procede a realizar la programacion.
                        $respuesta = array(
                            "resultado" => true,
                            "mensaje" => "Se procede a realizar la programación, es docente de neiva y no supera el tope semanal ({$total_horas_descarga} <= {$topeSemanalCatedra}), pico semanal docencia: {$pico_semana_catedra}.",
                            "line" => __LINE__
                        );
                    }
                }
            }
        }

        // 25	CATEDRA ADICIONAL DOCENTE
        // 17	CATEDRA POSTGRADOS  DOCENTE
        // 16	AD HONOREM                    
        if ($VinCodigo == 25 or $VinCodigo == 17 or $VinCodigo == 16) {
            $control_tope_horas = 224;
            $cantidad_horas_nuevas_total = $cantidad_horas_nuevas * $CurSemanas; //Cantidad de horas nuevas a la semana * la cantidad de semanas.
            $total_horas_descarga = $total_horas_descarga + $cantidad_horas_nuevas_total + $total_horas + $total_horas_pp;

            if ($control_tope_horas >= $total_horas_descarga) {
                // Se procede a realizar la programacion
                $respuesta = array(
                    "resultado" => true,
                    "mensaje" => "Se procede a realizar la programación, control_tope_horas >= total_horas_descarga ($control_tope_horas >= $total_horas_descarga). ",
                    "line" => __LINE__
                );
            } else {
                if ($perNN == true) { //En caso de pasar el tope se pregunta si es un docente NN
                    //Se procede a realizar la programacion y se avisa que es un docente NN.
                    $respuesta = array(
                        "resultado" => true,
                        "mensaje" => "Se procede a realizar la programación, pero es un docente NN. ",
                        "line" => __LINE__
                    );
                } else {
                    //En caso de superar las horas de descarga al tope
                    return array(
                        "resultado" => false,
                        "mensaje" => "ERROR. No se pueden adicionar las horas porque supera el límite de horas semanales (14 horas semanales), límite horas: {$control_tope_horas}, total horas que tendría el docente: {$total_horas_descarga}",
                        "line" => __LINE__
                    );
                }
            }
        }

        // 12	DE PLANTA DOCENTE
        // 23	NOMBRAMIENTO OCASIONAL DOCENTE
        //  5	TIEMPO COMPLETO
        //  4	MEDIO TIEMPO
        if ($VinCodigo == 12 or $VinCodigo == 23 or (($VinCodigo == 14 or $VinCodigo == 24 or $VinCodigo == 49) && ($DedCodigo == 4 or $DedCodigo == 5))) {
            // Carga complementaria semestral (proyectos + novedades).
            $cargaComplementariaSemestral = $servicioCargaDocente->obtenerCargaComplementariaSemestral($UapPerCodigo, $PerCodigo, true);
            if (!$cargaComplementariaSemestral["resultado"]) {
                return $cargaComplementariaSemestral;
            }
            $total_horas_inv_tesis = $cargaComplementariaSemestral["data"]["proyectosSemestral"];
            $total_horas_novedad = $cargaComplementariaSemestral["data"]["novedadesSemestral"];

            //Para consultar el total de horas que tiene el docente, primero eliminamos de agenda docente el calculo de horas para este curso dado que se debe recalcular, una vez se inserten nuevamente.
            $sql = "DELETE FROM agenda_periodo WHERE uap_codigo = {$UapCodigo} and cur_codigo = {$CurCodigo}";
            if (!$this->cnx->sentencia($sql)) {
                $this->errorSentenciaBd["mensaje"] = "Error al eliminar la agenda del curso: {$CurCodigo} y vinculacion docente: {$UapCodigo}.";
                $this->errorSentenciaBd["consola"] = "Ha fallado el delete de la agenda del curso: {$CurCodigo} y vinculacion docente: {$UapCodigo}.";
                return $this->errorSentenciaBd;
            }

            $r_periodo_nombre = $servicioCargaDocente->obtenerPeriodoNombrePorCodigo($PerCodigo);
            if (!$r_periodo_nombre["resultado"]) {
                return $r_periodo_nombre;
            }
            $periodoNombre = $r_periodo_nombre["data"]["periodoNombre"];
            $cargaDetalle = $servicioCargaDocente->obtenerCargaDetalladaDocente($UapCodigo, $periodoNombre, $UaaDependencia);
            if (!$cargaDetalle["resultado"]) {
                return $cargaDetalle;
            }
            $total_horas_descarga = $cargaDetalle["data"]["totalSemestre"];

            $total_factor = $servicioCargaDocente->calcularFactorCarga($UaaDependencia, $CarCodigo, $SubGrupo, $cantidad_horas_nuevas, $CurSemanas, $AsiCreditosTeoria, $AsiCreditosPractica, $uaaProgramada);

            $total_horas_descarga = $total_horas_descarga + $total_factor; // se le adicionan a la descarga total el factor calculado segun la dependencia y el caracter
            

            //5	TIEMPO COMPLETO
            if ($DedCodigo == 5) {
                if ($total_horas_descarga <= 880) {
                    // Se procede a realizar la programacion.
                    $respuesta = array(
                        "resultado" => true,
                        "mensaje" => "Se procede a realizar la programación, total_horas_descarga <= 880 ($total_horas_descarga). ",
                        "line" => __LINE__
                    );
                } else {
                    if ($perNN == true) {
                        // Se procede a realizar la programacion pero es un NN.
                        $respuesta = array(
                            "resultado" => true,
                            "mensaje" => "Se procede a realizar la programación, Pero es un docente NN. ",
                            "line" => __LINE__
                        );
                    } else {
                        return array(
                            "resultado" => false,
                            "mensaje" => "ERROR. La vinculación seleccionada es de TIEMPO COMPLETO por lo tanto no debe pasar las 880 horas.",
                            "line" => __LINE__
                        );
                    }
                }
            }

            //4	MEDIO TIEMPO
            if ($DedCodigo == 4) {
                if ($total_horas_descarga <= 440) {
                    // Se procede a realizar la programacion.
                    $respuesta = array(
                        "resultado" => true,
                        "mensaje" => "Se procede a realizar la programación, total_horas_descarga <= 440 ($total_horas_descarga).",
                        "line" => __LINE__
                    );
                } else {
                    if ($perNN == true) {
                        // Se procede a realizar la programacion pero es un NN.
                        $respuesta = array(
                            "resultado" => true,
                            "mensaje" => "Se procede a realizar la programación, Pero es un docente NN.",
                            "line" => __LINE__
                        );
                    } else {
                        return array(
                            "resultado" => false,
                            "mensaje" => "ERROR. La vinculación seleccionada es de MEDIO TIEMPO por lo tanto no debe pasar las 440 horas.",
                            "line" => __LINE__
                        );
                    }
                }
            }
        }

        return $respuesta;
    }

    //Inicio funcion cambiarDocente
    //Permite cambiar un horario de un curso por un docente especifico.
    function cambiarDocente($obj)
    {
        //Validaciones
        if (!isset($obj->CambioCoordinador) || !is_numeric($obj->CambioCoordinador)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar si desea cambiar el coordinador del curso.",
                "consola" => "El codigo para cambiar el coordinador del curso no se envio correctamente o no es numérico.",
            );
        }
        if (!isset($obj->listaHorarioSeleccionado) || count($obj->listaHorarioSeleccionado) < 1) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar el horario que desea cambiar el docente.",
                "consola" => "Los horarios para cambiar el docente no se enviaron correctamente.",
            );
        }
        if (!isset($obj->UapCodigo) || !is_numeric($obj->UapCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar la vinculación vigente del docente que desea cambiar.",
                "consola" => "El codigo de la vinculación del docente no se envio correctamente o no es numérica",
            );
        }
        if (!isset($obj->PerCodigo) || !is_numeric($obj->PerCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se encontró el codigo de la persona seleccionada.",
                "consola" => "El codigo de la persona no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->CurCodigo) || !is_numeric($obj->CurCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe ingresar el código del curso que desea cambiar.",
                "consola" => "El codigo del curso no es numérico o no se envio correctamente.",
            );
        }
        if ($obj->TipoDocente != 'Prestado' && $obj->TipoDocente != 'Propio') {
            return array(
                "resultado" => false,
                "mensaje" => "No se pudo definir si el docente es Propio o Prestado.",
                "consola" => "El tipo de docente no se envio correctamente. {$obj->TipoDocente}",
            );
        }

        //Asignaciones
        $CambioCoordinador = $obj->CambioCoordinador; // contiene la bandera 1 para cambiar el coordinador y 0 para no cambiarlo
        $listaHorarioSeleccionado = $obj->listaHorarioSeleccionado; // contiene un arreglo con los codigos de la tabla espacio ocupacion para cambiar el docente.
        $UapCodigo = $obj->UapCodigo; //contiene la vinculacion del docente que queremos asignar.
        $CurCodigo = $obj->CurCodigo; //contiene el codigo del curso que queremos cambiar.
        $CurGrupo = $obj->CurGrupo; //contiene el codigo del grupo del curso.
        $CalCodigo = $obj->CalCodigo; //contiene el codigo del calendario.
        $VinNombre = $obj->VinNombre; //contiene el nombre de la vinculacion.
        $SubGrupo = $obj->SubGrupo; //contiene el subgrupo seleccionado
        $HorarioDocentePrestado = isset($obj->HorarioDocentePrestado) && count($obj->HorarioDocentePrestado) > 0 ? $obj->HorarioDocentePrestado : false; //
        $TipoDocente = $obj->TipoDocente; //Contiene si es Prestado o Propio
        $PerCodigo = $obj->PerCodigo; // Contiene el per_codigo del docente seleccionado

        $validacionApertura = $this->validarAperturaCambioDocenteCurso($CurCodigo);
        if (!$validacionApertura["resultado"]) {
            return $validacionApertura;
        }

        // Filtrar para obtener las columnas DiaCodigo y HraCodigo de las horas seleccionadas para cambiar
        $filtroHorarioSeleccionado = array_map(function ($item) {
            return array(
                "HraCodigo" => $item->HoraCodigo,
                "DiaCodigo" => $item->DiaCodigo
            );
        }, $listaHorarioSeleccionado);

        // Filtrar los valores únicos y eliminar duplicados
        $unicoHorarioSeleccionado = array_values(array_filter($filtroHorarioSeleccionado, function ($value, $key) use ($filtroHorarioSeleccionado) {
            return array_search($value, $filtroHorarioSeleccionado) === $key;
        }, ARRAY_FILTER_USE_BOTH));

        // Validara el numero de coincidencias entre el horario seleccionado y el horario permitido por el docente.
        $coincidencias = 0;

        if ($TipoDocente == 'Prestado') {
            // Verificar si hay coincidencias entre los dos arrays
            foreach ($unicoHorarioSeleccionado as $horarioSeleccionado) {
                foreach ($HorarioDocentePrestado as $horarioPrestado) {
                    if ($horarioSeleccionado['DiaCodigo'] == $horarioPrestado->DiaCodigo  && $horarioSeleccionado['HraCodigo'] == $horarioPrestado->HraCodigo) {
                        $coincidencias++;
                    }
                }
            }

            if (count($unicoHorarioSeleccionado) != $coincidencias) {
                return array(
                    "resultado" => false,
                    "mensaje" => "Las horas seleccionadas para cambio docente son diferentes a las aprobadas para el docente seleccionado.",
                    "consola" => "El codigo del curso no es numérico o no se envio correctamente.",
                );
            }
        }

        if ($TipoDocente == 'Propio') {
            // En caso de ser propio, validamos que el docente no este prestado para el periodo en el horario seleccionado.
            $sql = "SELECT spdh.dia_codigo DiaCodigo, spdh.hra_codigo HraCodigo, dia.dia_nombre DiaNombre, hra.hra_inicio HraInicio, hra.hra_fin HraFin
                FROM programacionacademica.solicitud_prestamo_docente spd
                    INNER JOIN programacionacademica.solicitud_prestamo_docente_horario spdh ON spd.spd_codigo = spdh.spd_codigo AND spdh.spdh_estado = 1
                    INNER JOIN dia ON dia.dia_codigo = spdh.dia_codigo
                    INNER JOIN hora hra ON hra.hra_codigo = spdh.hra_codigo
                    INNER JOIN periodo per ON per.per_codigo = spd.periodo_codigo
                    INNER JOIN calendario cal ON cal.per_codigo = per.per_codigo
                WHERE spd.spd_estado = 2
                    AND spd.persona_codigo = {$PerCodigo}
                    AND cal.cal_codigo = {$CalCodigo}
                GROUP BY
                spdh.dia_codigo, spdh.hra_codigo, dia.dia_nombre, hra.hra_inicio, hra.hra_fin    
            ";

            if (!$this->cnx->consultar($sql)) {
                $this->errorConsultarBd["consola"] = "Error al consultar si el docente tiene solicitudes de prestamo aprobadas: {$UapCodigo}.";
                return $this->errorConsultarBd;
            }

            $r_solicitudes = $this->cnx->json;

            // En caso de si encontrar resultado, se debe verificar que el horario aprobado en la solicitud no sea el mismo que el seleccionado
            if (count($r_solicitudes) > 0) {
                // Verificar si hay coincidencias entre los dos arrays
                foreach ($unicoHorarioSeleccionado as $horarioSeleccionado) {
                    foreach ($r_solicitudes as $horarioPrestado) {
                        if ($horarioSeleccionado['DiaCodigo'] == $horarioPrestado['DiaCodigo']  && $horarioSeleccionado['HraCodigo'] == $horarioPrestado['HraCodigo']) {
                            $coincidencias++;
                        }
                    }
                }

                if ($coincidencias > 0) {
                    return array(
                        "resultado" => false,
                        "mensaje" => "El docente tiene una solicitud de prestamo aprobada en los horarios seleccionados.",
                        "consola" => "El docente se encuentra prestado en el horario seleccionado."
                    );
                }
            }
        }

        $validarHoras = $this->validarHorasDocente($obj);

        if (!$validarHoras["resultado"]) {
            return array(
                "resultado" => false,
                "mensaje" => $validarHoras["mensaje"],
                "line" => __LINE__
            );
        }

        if (trim($VinNombre) != "DE PLANTA DOCENTE") {
            $sql = "SELECT 
                (SELECT TOP 1 per_codigo FROM calendario WHERE cal_codigo= {$CalCodigo} ) as periodo_seleccionado,
                cur.cur_codigo CurCodigo, 
                cal.per_codigo PerCodigo
            FROM uaa_personal uap
            INNER JOIN agenda_periodo agp ON uap.uap_codigo = agp.uap_codigo
            INNER JOIN curso cur ON cur.cur_codigo = agp.cur_codigo
            INNER JOIN calendario cal ON cal.cal_codigo = cur.cal_codigo
            WHERE 
                uap.uap_codigo = {$UapCodigo} 
            ";

            if (!$this->cnx->consultar($sql)) {
                $this->errorConsultarBd["consola"] = "Error al validar la carga academica entre periodos de la vinculación: {$UapCodigo}.";
                return $this->errorConsultarBd;
            }

            $r_cruce_calendario = $this->cnx->json;
            $tieneCursosDeOtroPeriodo = false;

            for ($i = 0; $i < count($r_cruce_calendario); $i++) {
                $periodo_curso = $r_cruce_calendario[$i]["PerCodigo"];
                $periodo_seleccionado = $r_cruce_calendario[$i]["periodo_seleccionado"];

                if ($periodo_seleccionado != $periodo_curso) {
                    $tieneCursosDeOtroPeriodo = true;
                }
            }

            if ($tieneCursosDeOtroPeriodo) {
                $this->errorSentenciaBd["mensaje"] = "La vinculación ({$UapCodigo}) del docente ya tiene cargado cursos de otro periodo. Asegurese que el docente tenga vinculación para el periodo seleccionado.";
                $this->errorSentenciaBd["consola"] = "Error la vinculacion ({$UapCodigo}) tiene cursos en otro periodo.";
                return $this->errorSentenciaBd;
            }
        }

        if ($CambioCoordinador == 1) { //Evalua si se seleccino que se va a cambiar el coordiandor del curso (1).
            $sql = "UPDATE curso
            SET
                uap_codigo = {$UapCodigo},
                cur_fecha_actualizacion = GETDATE()
            WHERE
                cur_codigo = {$CurCodigo}
            ";

            if (!$this->cnx->sentencia($sql)) {
                $this->errorSentenciaBd["mensaje"] = "Error al cambiar el coordiandor del curso. Recargue la página e intente de nuevo.";
                $this->errorSentenciaBd["consola"] = "Ha fallado actualizar el coordinador : {$UapCodigo} en el curso: {$CurCodigo}.";
                return $this->errorSentenciaBd;
            }
        }
        $arrayFechasSeleccionadas = array();
        //Evaluamos que el docente no este ocupado en las horas seleccionadas.
        foreach ($listaHorarioSeleccionado as $horario) {
            $tabla = 'espacio_ocupacion';
            $tipo = $horario->TipoEspacio; //contiene el nombre de la tabla del origen de la hora Actual o Historico
            if ($tipo == 'Historico') {
                $tabla = 'espacio_ocupacion_historico';
            }

            $sql = "SELECT 
                    eso.eso_fecha EsoFecha, 
                    eso.hra_codigo EsoHora,
                    dia.dia_nombre DiaNombre,
                    hora.hra_inicio HoraInicio,
                    hora.hra_fin HoraFin
                FROM 
                    {$tabla} eso 
                INNER JOIN dia ON dia.dia_codigo = eso.dia_codigo
                INNER JOIN hora ON hora.hra_codigo = eso.hra_codigo
                WHERE 
                    eso.eso_codigo = {$horario->EsoCodigo}
            ";

            //Se verifica que se ejecute la consulta
            if (!$this->cnx->consultar($sql)) {
                $this->errorConsultarBd["consola"] = "Error en consultar la hora y dia del horario seleccionado: {$horario->EsoCodigo}";
                // $this->errorConsultarBd["sql"] = $sql;
                return $this->errorConsultarBd;
            }

            $r_horario = $this->cnx->json;

            $explode_fecha = explode(" ", $r_horario[0]['EsoFecha']);
            $r_horario[0]['EsoFecha'] = $explode_fecha[0] . "T" . $explode_fecha[1];
            $esoFechaSql = FechaSqlServer::toSqlDateTime2($r_horario[0]['EsoFecha'], false);
            if ($esoFechaSql === false) {
                return array(
                    "resultado" => false,
                    "mensaje" => "Formato de fecha inválido al validar ocupación docente.",
                    "consola" => "No se pudo preparar la fecha SQL {$r_horario[0]['EsoFecha']}.",
                );
            }
            $arrayFechasSeleccionadas[] = $explode_fecha[0];

            //Verificamos si el docente seleccionado tiene ocupado el dia y hora seleccionada.
            $sql = "SELECT count(eso.eso_codigo) Cant
                FROM espacio_ocupacion eso
                WHERE
                    eso.eso_fecha = {$esoFechaSql}
                    AND eso.hra_codigo = {$r_horario[0]['EsoHora']}
                    AND eso.uap_codigo = {$UapCodigo}
                    AND eso.eso_actividad != ''
            ";

            //Se verifica que se ejecute la consulta
            if (!$this->cnx->consultar($sql)) {
                $this->errorConsultarBd["consola"] = "Error en consultar la ocupacion del docente: {$UapCodigo}, fecha: {$r_horario[0]['EsoFecha']}, 
                    dia: {$r_horario[0]['DiaNombre']} y hora: {$r_horario[0]['EsoHora']}. {$r_horario[0]['HoraInicio']} {$r_horario[0]['HoraFin']}";
                // $this->errorConsultarBd["sql"] = $sql;
                return $this->errorConsultarBd;
            }

            $r_ocupacion_docente = $this->cnx->json;

            if ($r_ocupacion_docente[0]["Cant"] > 0) {
                return array(
                    "resultado" => false,
                    "mensaje" => "El docente se encuentra con la agenda ocupada el dia: {$r_horario[0]['DiaNombre']} y hora: {$r_horario[0]['EsoHora']}. {$r_horario[0]['HoraInicio']} {$r_horario[0]['HoraFin']}",
                    "sql" => $sql,
                    "count" => count($r_ocupacion_docente[0]["Cant"]),
                    "data" => $r_ocupacion_docente,
                    "consola" => "El docente se encuentra con la agenda ocupada el dia: {$r_horario[0]['DiaNombre']} y hora: {$r_horario[0]['EsoHora']}. {$r_horario[0]['HoraInicio']} {$r_horario[0]['HoraFin']}",
                );
            }
        }

        $semanas = array(); // Crear arreglo para almacenar las semanas
        array_unique($arrayFechasSeleccionadas); // Limpiamos el array de fechas para que elimine las repetidas

        foreach ($arrayFechasSeleccionadas as $fecha) {
            $semana = date('W', strtotime($fecha)); // Obtener las semanas en las que se encuentran las fechas
            if (!in_array($semana, $semanas)) { // Verificamos si se encuentra la semana de la fecha seleccionada en el array de semanas
                $semanas[] = $semana; // En caso de no encontrar la semana la agregamos al array.
            }
        }

        // Obtenemos la cantidad de semanas
        $cantidadSemanas = count($semanas);

        // Si no se encuentra ninguna hora ocupada se procede a actualizar el horario con la nueva vinculacion
        

        foreach ($listaHorarioSeleccionado as $horario) {
            $tabla = 'espacio_ocupacion';
            $tipo = $horario->TipoEspacio; //contiene el nombre de la tabla del origen de la hora Actual o Historico
            if ($tipo == 'Historico') {
                $tabla = 'espacio_ocupacion_historico';
            }
            $sql = "UPDATE {$tabla}
                SET uap_codigo = {$UapCodigo}
                WHERE eso_codigo = {$horario->EsoCodigo}
            ";

            if (!$this->cnx->sentencia($sql)) {
                $this->errorSentenciaBd["mensaje"] = "Error al cambiar el docente en el horario. Recargue la página e intente de nuevo.";
                $this->errorSentenciaBd["consola"] = "Ha fallado actualizar el coordinador : {$UapCodigo} en el curso: {$CurCodigo}.";
                return $this->errorSentenciaBd;
            }
        }

        require_once(dirname(__FILE__) . "/Curhorario.php");

        $CurHorario = new CurHorario();
        $r_actualizacion_agenda = $CurHorario->actualizarAgenda($CurCodigo, $cantidadSemanas);
        

        $mensaje = "El docente se cambio correctamente en los horarios seleccionados";
        if (!$r_actualizacion_agenda) {
            $mensaje .= ", " . $r_actualizacion_agenda["mensaje"] . ".";
        } else {
            $mensaje .= ", la agenda se actualizo correctamente";
        }

        return array(
            "resultado" => true,
            "mensaje" => "{$mensaje}.",
        );
    }

    //Inicio consultarDocente
    //Se usa para consultar la vinculacion de un docente por cedula que se encuentre activa entre las fechas del periodo seleccionado
    public function consultarDocente($obj)
    {


        // $PersonaBusqueda = $obj->PersonaBusqueda; //Contiene el criterio de busqueda.
        $CalCodigo = $obj->CalCodigo; //Contiene el codigo del calendario en el que fue creado el curso.
        $UaaCodigo = $obj->UaaCodigo; //Contiene el codigo de la uaa (asignatura).
        $CurCodigo = isset($obj->CurCodigo) && is_numeric($obj->CurCodigo) ? $obj->CurCodigo : 0; //Contiene el codigo del curso seleccionado.
        $PerFechaInicio = ""; //Almacenara la fecha de inicio del periodo seleccionado
        $PerFechaFin = ""; //Almacenara la fecha de fin del periodo seleccionado
        $Administrador = $_SESSION["pacademica"]["datosVinculacionUsuario"]["Administrador"]; //Para saber si es un administrador.
        $unidades = $_SESSION["pacademica"]["datosVinculacionUsuario"]["unidades"]; //Almacenamos las unidades que tiene permitida el usuario

        $sql = "SELECT 
            per.per_codigo PerCodigo,
            per.per_fecha_inicio PerFechaInicio,
            per.per_fecha_fin PerFechaFin,
            peu.peu_fecha_inicio PeuFechaInicio,
            peu.peu_fecha_fin PeuFechaFin
        FROM 
            periodo per
        LEFT JOIN programacionacademica.periodo_unidad peu ON per.per_codigo = peu.per_codigo AND peu.uaa_codigo IN ({$UaaCodigo}) AND peu.peu_estado = 1
        WHERE 
            per.per_codigo IN (
                SELECT cal.per_codigo PerCodigo
            FROM 
                calendario cal
            WHERE  
                cal.cal_codigo = {$CalCodigo}
        )
        ";

        //Se verifica que se ejecute la consulta
        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error en consultar el periodo del calendario: {$CalCodigo} y unidad: {$UaaCodigo}";
            // $this->errorConsultarBd["sql"] = $sql;
            return $this->errorConsultarBd;
        }

        //Se almacenan los registros
        $r_periodo = $this->cnx->json;

        if (count($r_periodo) < 1) {
            return array(
                "resultado" => false,
                "mensaje" => "No se encontraron fechas de inicio y fin en el periodo del curso seleccionado.",
                "consola" => "No se encontraron fechas en el periodo del calendario: {$CalCodigo} y unidad: {$UaaCodigo}"
            );
        }

        $PerFechaInicio = $r_periodo[0]["PerFechaInicio"]; //Contiene la fecha de inicio del periodo academico seleccionado
        $PerFechaFin = $r_periodo[0]["PerFechaFin"]; //Contiene la fecha de fin del periodo academico seleccionado
        $PerCodigo = $r_periodo[0]["PerCodigo"]; //Contiene el codigo del periodo del calendario

        // Se encontraban comentadas no se por que pero esto evitaba que consultara vinculaciones en el periodo personalizado si lo tenia establecido.
        if ($r_periodo[0]["PeuFechaInicio"] != '') {
            $PerFechaInicio = $r_periodo[0]["PeuFechaInicio"]; //Contiene la fecha de inicio del periodo personalizado academico seleccionado
        }
        if ($r_periodo[0]["PeuFechaFin"] != '') {
            $PerFechaFin = $r_periodo[0]["PeuFechaFin"]; //Contiene la fecha de fin del periodo personalizado academico seleccionado
        }

        $PerFechaInicioSql = FechaSqlServer::toSqlDateTime2($PerFechaInicio, false);
        $PerFechaFinFinDiaSql = FechaSqlServer::toSqlDateTime2($PerFechaFin, true);
        if ($PerFechaInicioSql === false || $PerFechaFinFinDiaSql === false) {
            return array(
                "resultado" => false,
                "mensaje" => "Formato de fecha inválido para consultar docentes.",
                "consola" => "No se pudieron preparar fechas SQL ({$PerFechaInicio} - {$PerFechaFin}).",
            );
        }
        $wherePorFechas = "AND uap.uap_fecha_inicio >= {$PerFechaInicioSql} AND uap.uap_fecha_fin <= {$PerFechaFinFinDiaSql}"; //En caso de no ser un administrador se deben incluir las fechas de inicio y fin.
        $whereUnidades = "AND uap.uaa_codigo IN ({$unidades})";

        if ($Administrador == 1) {
            $whereUnidades = ""; //En caso de ser un administrador se busca por cualquier unidad.
            $wherePorFechas = "AND (
                (
                    uap.uap_fecha_inicio >= {$PerFechaInicioSql}
                    AND uap.uap_fecha_fin <= {$PerFechaFinFinDiaSql}
                )
                OR EXISTS (
                    SELECT 1
                    FROM programacionacademica.periodo_unidad peu_admin
                    WHERE
                        peu_admin.per_codigo = {$PerCodigo}
                        AND peu_admin.peu_estado = 1
                        AND uap.uap_fecha_inicio >= CONVERT(date, peu_admin.peu_fecha_inicio)
                        AND uap.uap_fecha_fin < DATEADD(DAY, 1, CONVERT(date, peu_admin.peu_fecha_fin))
                )
            )";
        }

        //Consultamos si existe un periodo personalizado (periodo_unidad) para la unidad del programa
        //asociado al curso seleccionado. Se busca el periodo_unidad cuya UAA pertenezca a la misma
        //facultad (uaa_dependencia) del coordinador y a la misma sede (sed_codigo) del curso.
        //Cadena: curso → coordinador (uaa_dependencia) + curso (sed_codigo) → periodo_unidad
        $tienePeriodoPersonalizado = false;
        $wherePorFechasPeu = "";

        if ($CurCodigo > 0) {
            $sqlPeu = "SELECT TOP 1
                peu.peu_fecha_inicio PeuFechaInicio,
                peu.peu_fecha_fin PeuFechaFin
            FROM curso cur
            INNER JOIN uaa_personal coord ON coord.uap_codigo = cur.uap_codigo
            INNER JOIN uaa coord_uaa ON coord_uaa.uaa_codigo = coord.uaa_codigo
            INNER JOIN programacionacademica.periodo_unidad peu ON peu.peu_estado = 1
            INNER JOIN uaa peu_uaa ON peu_uaa.uaa_codigo = peu.uaa_codigo 
                AND peu_uaa.uaa_dependencia = coord_uaa.uaa_dependencia 
                AND peu_uaa.sed_codigo = cur.sed_codigo
            INNER JOIN calendario cal ON peu.per_codigo = cal.per_codigo
            WHERE 
                cur.cur_codigo = {$CurCodigo}
                AND cal.cal_codigo = {$CalCodigo}
            ";

            if ($this->cnx->consultar($sqlPeu)) {
                $r_peu = $this->cnx->json;

                if (count($r_peu) > 0) {
                    $tienePeriodoPersonalizado = true;
                    $peuFechaInicio = $r_peu[0]['PeuFechaInicio'];
                    $peuFechaFin = $r_peu[0]['PeuFechaFin'];
                    $peuFechaInicioSql = FechaSqlServer::toSqlDateTime2($peuFechaInicio, false);
                    $peuFechaFinFinDiaSql = FechaSqlServer::toSqlDateTime2($peuFechaFin, true);
                    if ($peuFechaInicioSql !== false && $peuFechaFinFinDiaSql !== false) {
                        $wherePorFechasPeu = "AND uap.uap_fecha_inicio >= {$peuFechaInicioSql} AND uap.uap_fecha_fin <= {$peuFechaFinFinDiaSql}";
                    }
                }
            }
        }

        //LISTAR SOLO PERSONAS VINCULADAS ACTIVAS
        $dePlantaDocente = 12; //Carlos arbey salamanca 362 Docente de planta
        $catedraDocente = 14; //Luis fernando salamanca Catedra docente
        $catedraPosgradosDocente = 17; //emilio polo ledesma Catedra posgrado docente
        $nombramOcasionalDocente = 23; //Alexander nossa o alexandra uribe Nombramiento ocacional
        $catedraVisitanteDocente = 24; //Carlos hernando trujillo Catedra visitante
        $catedraConvenioDocente = 49; //

        $sql = "SELECT
            uap.uap_codigo UapCodigo, 
            uap.uap_fecha_inicio UapFechaInicio, 
            uap.uap_fecha_fin UapFechaFin,
            per.per_identificacion PerIdentificacion, 
            per.per_nombre + ' ' + per.per_apellido PerNombreApellido,
            per.per_codigo PerCodigo,
            vin.vin_nombre VinNombre,
            sed.sed_codigo SedCodigo,
            sed.sed_nombre SedNombre,
            uaa.uaa_codigo UaaCodigo, 
            uaa.uaa_nombre_corto UaaNombreCorto, 
            ded.ded_nombre DedNombre,
            CONVERT(varchar, uaa.uaa_codigo) + '. ' + uaa.uaa_nombre_corto UaaCodigoNombre,
            (
                SELECT count(*) 
                FROM agenda_periodo agp 
                INNER JOIN curso cur on cur.cur_codigo = agp.cur_codigo AND cur.cal_codigo = {$CalCodigo} 
                WHERE agp.uap_codigo = uap.uap_codigo 
            ) UapCarga
        FROM uaa_personal AS uap
        INNER JOIN persona AS per ON per.per_codigo = uap.per_codigo
        INNER JOIN vinculacion AS vin ON vin.vin_codigo = uap.vin_codigo
        INNER JOIN sede AS sed ON sed.sed_codigo = uap.sed_codigo
        INNER JOIN uaa AS uaa ON uaa.uaa_codigo=uap.uaa_codigo
        INNER JOIN dedicacion AS ded ON ded.ded_codigo=uap.ded_codigo
        WHERE 
            uap.uap_fecha_fin IS NULL
            AND uap.vin_codigo = {$dePlantaDocente}
            {$whereUnidades}
        UNION ALL

        SELECT
            uap.uap_codigo UapCodigo, 
            uap.uap_fecha_inicio UapFechaInicio, 
            uap.uap_fecha_fin UapFechaFin,
            per.per_identificacion PerIdentificacion, 
            per.per_nombre + ' ' + per.per_apellido PerNombreApellido, 
            per.per_codigo PerCodigo,
            vin.vin_nombre VinNombre,
            sed.sed_codigo SedCodigo,
            sed.sed_nombre SedNombre,
            uaa.uaa_codigo UaaCodigo, 
            uaa.uaa_nombre_corto UaaNombreCorto, 
            ded.ded_nombre DedNombre,
            CONVERT(varchar, uaa.uaa_codigo) + '. ' + uaa.uaa_nombre_corto UaaCodigoNombre,
            (
                SELECT count(*) 
                FROM agenda_periodo agp 
                WHERE 
                    agp.uap_codigo = uap.uap_codigo 
            ) UapCarga
        FROM uaa_personal AS uap
        INNER JOIN persona AS per ON per.per_codigo = uap.per_codigo
        INNER JOIN vinculacion AS vin ON vin.vin_codigo = uap.vin_codigo
        INNER JOIN sede AS sed ON sed.sed_codigo = uap.sed_codigo
        INNER JOIN uaa AS uaa ON uaa.uaa_codigo=uap.uaa_codigo
        INNER JOIN dedicacion AS ded ON ded.ded_codigo=uap.ded_codigo
        WHERE 
            uap.vin_codigo IN ({$catedraDocente}, {$catedraPosgradosDocente}, {$nombramOcasionalDocente}, {$catedraVisitanteDocente}, {$catedraConvenioDocente})
            AND uap.uap_fecha_inicio != uap.uap_fecha_fin
            {$wherePorFechas}
            {$whereUnidades}
        ";

        //Si existen periodos personalizados, se agrega un tercer bloque UNION ALL para buscar docentes
        //cuya vinculación esté dentro de las fechas del periodo_unidad (útil para postgrados u otras unidades con fechas distintas al periodo genérico).
        if ($tienePeriodoPersonalizado && $Administrador != 1) {
            $sql .= "
        UNION ALL

        SELECT
            uap.uap_codigo UapCodigo, 
            uap.uap_fecha_inicio UapFechaInicio, 
            uap.uap_fecha_fin UapFechaFin,
            per.per_identificacion PerIdentificacion, 
            per.per_nombre + ' ' + per.per_apellido PerNombreApellido, 
            per.per_codigo PerCodigo,
            vin.vin_nombre VinNombre,
            sed.sed_codigo SedCodigo,
            sed.sed_nombre SedNombre,
            uaa.uaa_codigo UaaCodigo, 
            uaa.uaa_nombre_corto UaaNombreCorto, 
            ded.ded_nombre DedNombre,
            CONVERT(varchar, uaa.uaa_codigo) + '. ' + uaa.uaa_nombre_corto UaaCodigoNombre,
            (
                SELECT count(*) 
                FROM agenda_periodo agp 
                WHERE 
                    agp.uap_codigo = uap.uap_codigo 
            ) UapCarga
        FROM uaa_personal AS uap
        INNER JOIN persona AS per ON per.per_codigo = uap.per_codigo
        INNER JOIN vinculacion AS vin ON vin.vin_codigo = uap.vin_codigo
        INNER JOIN sede AS sed ON sed.sed_codigo = uap.sed_codigo
        INNER JOIN uaa AS uaa ON uaa.uaa_codigo=uap.uaa_codigo
        INNER JOIN dedicacion AS ded ON ded.ded_codigo=uap.ded_codigo
        WHERE 
            uap.vin_codigo IN ({$catedraDocente}, {$catedraPosgradosDocente}, {$nombramOcasionalDocente}, {$catedraVisitanteDocente}, {$catedraConvenioDocente})
            AND uap.uap_fecha_inicio != uap.uap_fecha_fin
            {$wherePorFechasPeu}
            {$whereUnidades}
            ";
        }

        $sql .= "
        GROUP BY uap.uap_codigo, uap.uap_fecha_inicio , uap.uap_fecha_fin ,
        per.per_identificacion, per.per_nombre + ' ' + per.per_apellido, per.per_codigo, vin.vin_nombre,
        sed.sed_codigo, sed.sed_nombre,
        uaa.uaa_codigo, uaa.uaa_nombre_corto, ded.ded_nombre
        ORDER BY  per.per_nombre + ' ' + per.per_apellido ASC, vin.vin_nombre ASC
        ";

        //Se verifica que se ejecute la consulta
        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error en consultar los docentes vinculados entre la fecha inicio: {$PerFechaInicio} y fecha fin: {$PerFechaFin}";
            return $this->errorConsultarBd;
        }

        $r_vinculacion = $this->cnx->json;

        if (count($r_vinculacion) < 1) {
            return array(
                "resultado" => false,
                "mensaje" => "No se encontraron vinculaciones del docente entre las fechas {$PerFechaInicio} y {$PerFechaFin}.",
            );
        } else {
            return array(
                "resultado" => true,
                "mensaje" => "Vinculaciones consultadas correctamente.",
                "data" => $r_vinculacion,
                "count" => count($r_vinculacion),
            );
        }
    }

    //Inicio consultarHorario
    //Se usa para consultar el horario de un curso, subgrupo y docente especifico.
    public function consultarHorario($obj)
    {
        // Validamos las variables recibidas que exista y que sea numerico
        if (!isset($obj->CurCodigo) || !is_numeric($obj->CurCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe ingresar el número del curso",
                "consola" => "El codigo del curso no es numerico o no hay número",
            );
        }
        if (!isset($obj->UapCodigo) || !is_numeric($obj->UapCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe ingresar el número de la vinculación.",
                "consola" => "El codigo de la vinculación no es numerico o no hay número",
            );
        }
        if (!isset($obj->EsoSubGrupo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe ingresar el subgrupo del curso.",
                "consola" => "El subgrupo de la vinculación no se envio correctamente.",
            );
        }
        $CurCodigo = $obj->CurCodigo; //se almacena el codigo del curso
        $UapCodigo = $obj->UapCodigo; //se almacena el codigo de la vinculacion
        $EsoSubGrupo = $obj->EsoSubGrupo; //se almacena el subgrupo del curso

        $sql = "SELECT 
            eso.eso_subgrupo EsoSubGrupo,
            CONVERT(VARCHAR, eso.eso_fecha, 111) AS EsoFecha,
            eso.hra_codigo HoraCodigo,
		    per.per_identificacion PerIdentificacion,
            per.per_apellido PerApellido,
            per.per_nombre PerNombre,
		    uap.uap_codigo UapCodigo,
            eso.eso_codigo EsoCodigo,
            dia.dia_codigo DiaCodigo,
            dia.dia_nombre DiaNombre,
            vin.vin_nombre VinNombre, 
            uaa.uaa_codigo UaaCodigo,
            CONVERT(varchar, uaa.uaa_codigo) + '. ' + uaa.uaa_nombre_corto UaaCodigoNombre,
            (
                SELECT count(*) 
                FROM agenda_periodo agp 
                INNER JOIN curso cur2 ON cur2.cur_codigo = agp.cur_codigo AND cur2.cal_codigo = cur.cal_codigo
                WHERE agp.uap_codigo = uap.uap_codigo 
            ) Carga,
            'Actual' TipoEspacio
		FROM 
            espacio_ocupacion eso
        INNER JOIN curso cur ON eso.eso_actividad = cur.cur_codigo  
		INNER JOIN uaa_personal uap ON uap.uap_codigo = eso.uap_codigo
        INNER JOIN persona per ON per.per_codigo = uap.per_codigo 
        INNER JOIN dia ON dia.dia_codigo = eso.dia_codigo
        INNER JOIN vinculacion vin ON vin.vin_codigo = uap.vin_codigo
        INNER JOIN uaa ON uaa.uaa_codigo = eso.uaa_codigo
		WHERE 
            eso.eso_actividad={$CurCodigo}
            and eso.eso_subgrupo = '{$EsoSubGrupo}' 
            and eso.uap_codigo= {$UapCodigo}

        UNION ALL

        SELECT 
            eso.eso_subgrupo EsoSubGrupo,
            CONVERT(VARCHAR, eso.eso_fecha, 111) AS EsoFecha,
            eso.hra_codigo HoraCodigo,
		    per.per_identificacion PerIdentificacion,
            per.per_apellido PerApellido,
            per.per_nombre PerNombre,
		    uap.uap_codigo UapCodigo,
            eso.eso_codigo EsoCodigo,
            dia.dia_codigo DiaCodigo,
            dia.dia_nombre DiaNombre,
            vin.vin_nombre VinNombre, 
            uaa.uaa_codigo UaaCodigo,
            CONVERT(varchar, uaa.uaa_codigo) + '. ' + uaa.uaa_nombre_corto UaaCodigoNombre,
            (
                SELECT count(*) 
                FROM agenda_periodo agp 
                INNER JOIN curso cur2 ON cur2.cur_codigo = agp.cur_codigo AND cur2.cal_codigo = cur.cal_codigo
                WHERE agp.uap_codigo = uap.uap_codigo 
            ) Carga,
            'Historico' TipoEspacio
		FROM 
            espacio_ocupacion_historico eso
        INNER JOIN curso cur ON eso.eso_actividad = cur.cur_codigo  
		INNER JOIN uaa_personal uap ON uap.uap_codigo = eso.uap_codigo
        INNER JOIN persona per ON per.per_codigo = uap.per_codigo 
        INNER JOIN dia ON dia.dia_codigo = eso.dia_codigo
        INNER JOIN vinculacion vin ON vin.vin_codigo = uap.vin_codigo
        INNER JOIN uaa ON uaa.uaa_codigo = eso.uaa_codigo
		WHERE 
            eso.eso_actividad={$CurCodigo}
            and eso.eso_subgrupo = '{$EsoSubGrupo}' 
            and eso.uap_codigo= {$UapCodigo}
        ORDER BY 
            CONVERT(VARCHAR, eso.eso_fecha, 111) ASC
        ";

        //Se verifica que se ejecute la consulta
        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error en consultar el horario curso: {$CurCodigo} Subgrupo: {$EsoSubGrupo} Vinculacion: {$UapCodigo}";
            // $this->errorConsultarBd["sql"] = $sql;
            return $this->errorConsultarBd;
        }

        //Se almacenan los registros
        $result = $this->cnx->json;
        $arraySemanas = []; // Se crea un array para acumular el horario por semana
        $semanaFinal = -1;
        $semanaInicio = 0;
        foreach ($result as $horario) {
            $numeroSemana = date('W', strtotime($horario["EsoFecha"]));
            if ($semanaInicio != $numeroSemana) {
                $semanaInicio = $numeroSemana;
                $semanaFinal ++;
            }
            $arraySemanas[$semanaFinal][] = $horario;
        }

        return array(
            "resultado" => true,
            "mensaje" => "Horario consultado correctamente.",
            "count" => count($arraySemanas),
            "data" => $arraySemanas
        );
    }

    //Inicio consultarSubgrupoCurso
    //Se usa para consultar los docentes de un curso con su grupo y subgrupo.
    public function consultarSubgrupoCurso($obj)
    {
        // Validamos las variables recibidas que exista y que sea numerico
        if (!isset($obj->CurCodigo) || !is_numeric($obj->CurCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe ingresar el número del curso",
                "consola" => "No es numerico o no hay número",
            );
        }

        $CurCodigo = $obj->CurCodigo; //obtenemos el codigo del curso

        $sql = "SELECT 
            cur.cur_grupo CurGrupo,
            eso.eso_subgrupo EsoSubGrupo,
            per.per_identificacion PerIdentificacion,
            per.per_apellido PerApellido,
            per.per_nombre PerNombre,
            uap.uap_codigo UapCodigo, 
            vin.vin_nombre VinNombre,  
            eso.eso_actividad EsoActividad, 
            ded.ded_nombre DedNombre,
            uap.uap_fecha_inicio UapFechaInicio, 
            uap.uap_fecha_fin UapFechaFin, 
            (
                SELECT count(*) FROM agenda_periodo agp 
                INNER JOIN curso cur2 ON cur2.cur_codigo = agp.cur_codigo AND cur2.cal_codigo = cur.cal_codigo
                WHERE agp.uap_codigo = uap.uap_codigo 
            ) Carga,
            (
                SELECT count(*) mac_codigo 
                FROM matricula_curso mac 
                WHERE 
                    mac.cur_codigo = eso.eso_actividad 
                    AND mac.mac_subgrupo = eso.eso_subgrupo 
                    AND mac.maa_codigo IN (1,2)
            ) TotalMatriculados,
            CEILING((DATEDIFF(DAY, CAST(MIN(eso.eso_fecha) AS DATE), CAST(MAX(eso.eso_fecha) AS DATE)) + 1) / 7.0) AS SemanasProgramadas
        FROM espacio_ocupacion eso
        INNER JOIN curso cur ON (cur.cur_codigo=eso.eso_actividad)
        INNER JOIN uaa_personal uap ON (uap.uap_codigo=eso.uap_codigo)
        INNER JOIN persona per ON (per.per_codigo=uap.per_codigo)
        INNER JOIN vinculacion vin ON vin.vin_codigo=uap.vin_codigo
        INNER JOIN dedicacion ded ON uap.ded_codigo=ded.ded_codigo
        WHERE eso.eso_actividad = {$CurCodigo}
        GROUP BY cur.cur_grupo,eso.eso_subgrupo,per.per_identificacion, eso.eso_actividad, cur.cal_codigo,
        per.per_apellido,per.per_nombre,uap.uap_codigo, vin.vin_nombre, ded.ded_nombre, uap.uap_fecha_inicio, uap.uap_fecha_fin
		";

        //Se verifica que se ejecute la consulta
        if (!$this->cnx->Consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error en consulta buscar sub grupo del curso";
            return $this->errorConsultarBd;
        }

        //Se almacenan los registros
        $result = $this->cnx->json;

        for ($i = 0; $i < count($result); $i++) {
            $result[$i]["PerApellido"] = utf8_encode($result[$i]["PerApellido"]);
            $result[$i]["PerNombre"] = utf8_encode($result[$i]["PerNombre"]);
        }

        return array(
            "resultado" => true,
            "mensaje" => "Sub grupos consultados correctamente.",
            "count" => count($result),
            "data" => $result
        );
    }
    /**
     * Consulta la carga detallada del docente seleccionado.
     */
    public function consultarCargaDocente($obj)
    {
        if (!isset($obj->UapCodigo) || !is_numeric($obj->UapCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Código de vinculación inválido.",
                "consola" => "UapCodigo no numérico en consultarCargaDocente()."
            );
        }
        if (!isset($obj->CalCodigo) || !is_numeric($obj->CalCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Código de calendario inválido.",
                "consola" => "CalCodigo no numérico en consultarCargaDocente()."
            );
        }

        // Obtener el nombre del periodo a partir del CalCodigo
        $sqlPer = "SELECT per.per_nombre FROM calendario cal INNER JOIN periodo per ON per.per_codigo = cal.per_codigo WHERE cal.cal_codigo = {$obj->CalCodigo}";
        if (!$this->cnx->consultar($sqlPer)) {
            return array(
                "resultado" => false,
                "mensaje" => "Error al consultar el periodo del curso.",
                "consola" => "Fallo SQL al obtener periodo para CalCodigo {$obj->CalCodigo}"
            );
        }
        
        $periodoNombre = $this->cnx->json[0]['per_nombre'];
        $servicio = new ValidarCargaDocenteService($this->cnx);
        $facultadCodigo = isset($obj->FacultadCodigo) ? intval($obj->FacultadCodigo) : 0;

        $sqlInfo = "SELECT
                uap.vin_codigo VinCodigo,
                uap.ded_codigo DedCodigo,
                uap.sed_codigo SedCodigo,
                sed.sed_nombre SedNombre
            FROM uaa_personal uap
            INNER JOIN sede sed ON sed.sed_codigo = uap.sed_codigo
            WHERE uap.uap_codigo = {$obj->UapCodigo}";

        if (!$this->cnx->consultar($sqlInfo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Error al consultar la sede del docente.",
                "consola" => "Fallo SQL al obtener sede para UapCodigo {$obj->UapCodigo}"
            );
        }

        $vinCodigo = intval($this->cnx->json[0]['VinCodigo']);
        $dedCodigo = intval($this->cnx->json[0]['DedCodigo']);
        $sedCodigo = intval($this->cnx->json[0]['SedCodigo']);
        $sedNombre = $this->cnx->json[0]['SedNombre'];

        $topeSemanal = null;
        $topeSemestral = null;

        if (in_array($vinCodigo, array(14, 24, 49)) && $dedCodigo == 6) {
            $topes = $servicio->obtenerTopesSemanalesCatedra($sedCodigo);
            if (!$topes["resultado"]) {
                return $topes;
            }
            $topeSemanal = $sedCodigo != 1 ? floatval($topes["data"]["topeSedes"]) : floatval($topes["data"]["topeNeiva"]);
        } elseif ($vinCodigo == 12 || $vinCodigo == 23 || ($dedCodigo == 4 || $dedCodigo == 5)) {
            if ($dedCodigo == 5) {
                $topeSemestral = 880;
            }
            if ($dedCodigo == 4) {
                $topeSemestral = 440;
            }
        }
        
        $r = $servicio->obtenerCargaDetalladaDocente($obj->UapCodigo, $periodoNombre, $facultadCodigo);

        if ($r["resultado"]) {
            $r["data"]["topeSemanal"] = $topeSemanal;
            $r["data"]["topeSemestral"] = $topeSemestral;
            $r["data"]["sedCodigo"] = $sedCodigo;
            $r["data"]["sedNombre"] = $sedNombre;
        }

        return $r;
    }
}
