<?php
date_default_timezone_set('America/Bogota');
require_once(dirname(__FILE__) . '/servicios/FechaSqlServer.php');
require_once(dirname(__FILE__) . '/servicios/ValidarCargaDocenteService.php');

class Solcambh
{
    // Estados de solicitud_cambio_horario que se consideran "en tramite" y por lo tanto bloquean
    // la creacion de otra solicitud sobre el mismo horario:
    // 1 Solicitado Planta Fisica, 2 Aprobado Planta Fisica (pendiente Vicerrectoria), 7 Solicitado Jefe Programa.
    // Se excluyen las rechazadas (3, 5, 8), las ya ejecutadas (4, 6) y las eliminadas (0).
    const ESTADOS_SOLICITUD_EN_TRAMITE = array(1, 2, 7);

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
            'Solicitado Jefe Programa' => 7,
            'Rechazado Jefe Programa' => 8,
            'Aprobado Planta Fisica' => 2,
            'Rechazado Planta Fisica' => 3,
            'Aprobado Vicerrectoria Académica' => 4,
            'Rechazado Vicerrectoria Académica' => 5,
            'Aprobado Curso Virtual' => 6,
        ];
    }

    private function consultarPeriodoCurso($CurCodigo)
    {
        $sql = "SELECT TOP 1
                    cal.per_codigo PeriodoCodigo
                FROM curso cur
                INNER JOIN calendario cal ON cal.cal_codigo = cur.cal_codigo
                WHERE cur.cur_codigo = {$CurCodigo}";

        if (!$this->cnx->consultar($sql)) {
            return array(
                "resultado" => false,
                "mensaje" => "Error al validar el periodo del curso.",
                "consola" => "No se pudo consultar el periodo del curso {$CurCodigo}.",
            );
        }

        if (count($this->cnx->json) <= 0) {
            return array(
                "resultado" => false,
                "mensaje" => "No se encontrÃ³ el periodo asociado al curso seleccionado.",
                "consola" => "No se encontro calendario/periodo para el curso {$CurCodigo}.",
            );
        }

        return array(
            "resultado" => true,
            "PeriodoCodigo" => intval($this->cnx->json[0]["PeriodoCodigo"]),
        );
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
            $mensaje = "La apertura de {$nombreModulo} para el periodo y unidad seleccionados estÃ¡ inactiva.";
        } else if ($now < strtotime($apertura["FechaInicio"])) {
            $mensaje = "La apertura de {$nombreModulo} estÃ¡ pendiente. EstarÃ¡ habilitada desde {$fechaInicio} hasta {$fechaFin}.";
        } else if ($now > strtotime($apertura["FechaFin"])) {
            $mensaje = "La apertura de {$nombreModulo} estÃ¡ vencida. Estuvo habilitada desde {$fechaInicio} hasta {$fechaFin}.";
        } else {
            $mensaje = "No hay apertura activa para {$nombreModulo} en el periodo y unidad seleccionados.";
        }

        return array(
            "resultado" => false,
            "mensaje" => $mensaje,
            "consola" => "Apertura no vigente para UAA {$UaaCodigo}, tipo {$PtsCodigo}, periodo {$PeriodoCodigo}.",
        );
    }

    // Inicio aprobarSolicitudJefePrograma
    // Permite aprobar una solicitud por parte del jefe de programa.
    function aprobarSolicitudJefePrograma($obj)
    {
        //Validaciones
        if (!isset($obj->SchCodigo) || !is_numeric($obj->SchCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar una solicitud.",
                "consola" => "El codigo de la solicitud no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->SchEstado) || !is_numeric($obj->SchEstado)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el estado de la solicitud.",
                "consola" => "El codigo del estado de la solicitud no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->mensajeComentario) || strlen($obj->mensajeComentario) < 5) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe ingresar el mensaje del comentario.",
                "consola" => "El comentario de la solicitud tiene menos de 5 letras o no se envio correctamente.",
            );
        }
        $SchCodigo = $obj->SchCodigo; // Contiene el codigo de la solicitud de cambio de horario.
        $SchEstado = $obj->SchEstado; // Contiene el codigo de rechazo de la solicitud.

        $this->cnx->Sentencia("BEGIN TRAN");

        $guardarJustificacion = self::guardarComentarios($obj, 'Sin notificacion'); // Guardamos la justificacion del rechazos
        // Verificamos si se guardo correctamente
        if (!$guardarJustificacion["resultado"]) {
            return array(
                "resultado" => false,
                "mensaje" => $guardarJustificacion["mensaje"],
                "consola" => "La justificacion de la aprobación de la solicitud del jefe de programa no se guardo correctamente.",
            );
        }

        $sql = "UPDATE programacionacademica.solicitud_cambio_horario
            SET sch_estado = {$SchEstado}
            WHERE sch_codigo = {$SchCodigo}
        ";

        if (!$this->cnx->sentencia($sql)) {
            $this->errorSentenciaBd["mensaje"] = "Error al aprobar la solicitud por parte del jefe de programa {$SchCodigo}. 
                Recargue la página e intente de nuevo.";
            $this->errorSentenciaBd["consola"] = "Ha fallado el update del estado en la solicitud " . __LINE__ . ".";
            $this->cnx->Sentencia("ROLLBACK TRAN");
            return $this->errorSentenciaBd;
        }

        $this->cnx->Sentencia("COMMIT TRAN");

        $envioCorreo = self::enviarNotificacion($obj, 'AprobadoJefePrograma');

        return array(
            "resultado" => true,
            "mensaje" => "La solicitud se aprobó correctamente.",
            "email" => $envioCorreo
        );
    }

    function obtener_fechas_dia_semana($fecha_inicio, $codigo_dia_semana, $semanas)
    {
        $fechas_dia_semana = array();
        $fecha = strtotime($fecha_inicio);
        $dia_semana_inicio = date('N', $fecha);
        $dias_hasta_dia_semana = ($codigo_dia_semana - $dia_semana_inicio + 7) % 7;
        $fecha += 86400 * $dias_hasta_dia_semana;
        for ($i = 0; $i < $semanas; $i++) {
            $fechas_dia_semana[] = date('Y-m-d', $fecha);
            // Se agrega 7 dias en segundos (60 segundos * 60 minutos * 24 horas * 7 días) para la siguiente fecha
            $fecha += 604800;
        }
        return $fechas_dia_semana;
    }

    // Inicio enviarNotificacion
    // Permite enviar notificaciones a la persona a cargo de una unidad 
    public function enviarNotificacion($obj, $tipo = '')
    {
        if (!isset($obj->SchCodigo) || !is_numeric($obj->SchCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar una solicitud.",
                "obj" => $obj,
                "consola" => "El codigo de la solicitud no es numérico o no se envio correctamente.",
            );
        }

        if ($tipo != 'Creacion' && $tipo != 'AprobadoPlanta' && $tipo != 'RechazadoPlanta' && $tipo != 'AprobadoVice' && $tipo != 'RechazadoVice' && $tipo != 'ReActivacion' && $tipo != 'Comentario' && $tipo != 'SolicitadoJefePrograma' && $tipo != 'AprobadoJefePrograma' && $tipo != 'RechazadoJefePrograma') {
            return array(
                "resultado" => false,
                "mensaje" => "El tipo de notificacion no se envio correctamente.",
                "consola" => "El tipo de la notificacion es vacio o no se envio correctamente.",
            );
        }

        $SchCodigo = $obj->SchCodigo; // Contiene el codigo de la solicitud
        // $tipo esta vacio por defecto pero puede ser:
        // Creacion
        // AprobadoPlanta
        // RechazadoPlanta
        // AprobadoVice
        // RechazadoVice
        // ReActivacion
        // Comentario
        // AprobadoVirtual
        // SolicitadoJefePrograma
        // AprobadoJefePrograma

        //Query para obtener la informacion de la solicitud y su horario.
        $sql = "SELECT
                sch.sch_codigo SchCodigo,
                sch.sch_estado SchEstado,
                sch.usu_codigo UsuCodigo,
                sch.sch_fecha_creacion SchFechaCreacion,
                sch.sch_espacio_deportivo EspDeportivo,
                sch.sch_cambio_docente CambioDocente,
                sch.sch_cambio_semanas CambioSemanas,
                cur.cur_codigo CurCodigo,
                cur.cur_semanas CurSemanas,
                asi.asi_codigo AsiCodigo,
                asi.asi_nombre AsiNombre,
                asi.asi_nombre_corto AsiNombreCorto,
                uaa.uaa_codigo UaaCodigo,
                uaa.uaa_nombre_corto UaaNombreCorto,
                per.per_nombre + ' ' + per.per_apellido UsuNombreApellido,
                cal.cal_nombre CalNombre
            FROM programacionacademica.solicitud_cambio_horario sch
                INNER JOIN curso cur ON cur.cur_codigo = sch.cur_codigo
                INNER JOIN calendario cal ON cal.cal_codigo = cur.cal_codigo
                INNER JOIN asignatura asi ON asi.asi_codigo = cur.asi_codigo
                INNER JOIN uaa ON uaa.uaa_codigo = sch.uaa_codigo
                INNER JOIN usuario_general usu ON usu.uid = sch.usu_codigo 
                INNER JOIN persona per ON per.per_codigo = usu.up
            WHERE
                sch.sch_codigo = {$SchCodigo}
            ORDER BY sch.sch_codigo DESC, sch.sch_estado ASC
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["mensaje"] = "No se pudo realizar la consulta de la informacion de la solicitud seleccionada.";
            $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
            return $this->errorConsultarBd;
        }

        $info_solicitud = $this->cnx->json; // Contiene la informacion de la solicitud.
        $info_solicitud[0]["Horario"] = $this->consultaHorarioSolicitud($obj)["data"]; //Almacenamos el contenido de la peticion.
        $info_solicitud[0]["Justificacion"] = $obj->mensajeComentario; //Almacenamos la justificacion si existe

        // Obtenemos los correos de los administradores y del usuario que lo creo.
        $ListaEmail = array();
        $ListaUsuarios = array();

        if ($tipo == 'Comentario' || $tipo == 'RechazadoVice' || $tipo == 'AprobadoVice' || $tipo == 'AprobadoVirtual' || $tipo == 'SolicitadoJefePrograma') {
            $ListaUsuarios[] = $info_solicitud[0]["UsuCodigo"];
            if ($obj->UsuCodigo) {
                $ListaUsuarios[] = $obj->UsuCodigo;
            }
            $sqlJefedePrograma = "";
            if ($tipo == 'SolicitadoJefePrograma') {
                $sqlJefedePrograma = "OR (usu.usg_grupo = 34 AND usu.usg_uaa IN ({$info_solicitud[0]["UaaCodigo"]})) -- Llama a los jefes de programa de la unidad en la que se programo el curso.";
            }

            $sql = "SELECT 
                    per.per_identificacion PerIdentificacion, per.per_email_interno PerEmailInterno
                FROM usuario_programacion usu 
                INNER JOIN persona per ON per.per_codigo = usu.up
                WHERE usu.usg_usuario in (" . implode(",", $ListaUsuarios) . ") 
                OR usu.usg_grupo = 69 -- GruCodigo: Administrador de Programacion academica.
                {$sqlJefedePrograma}
                GROUP BY per.per_identificacion, per.per_email_interno
            ";

            if (!$this->cnx->consultar($sql)) {
                $this->errorConsultarBd["mensaje"] = "No se pudieron consultar los correos del creador de la solicitud y los administradores del sistema.";
                $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
                return $this->errorConsultarBd;
            }
            $ListaEmail = $this->cnx->json; // Contiene el uaa unificado de la unidad solicita.
        }

        if ($tipo == 'Creacion' || $tipo == 'ReActivacion' || $tipo == 'AprobadoJefePrograma' || $tipo == 'RechazadoJefePrograma') {
            // 140486 = Eidy Tatiana TODO: Verificar
            // 154381 = Yener Francisco
            $UsuCodigo = 140486;
            if ($info_solicitud[0]["EspDeportivo"] == 1) {
                $UsuCodigo = 154381;
            }
            // $ListaUsuarios[] = $info_solicitud[0]["UsuCodigo"];

            $sqlUsuarioCreador = "";
            if ($tipo == 'AprobadoJefePrograma' || $tipo == 'RechazadoJefePrograma') {
                $sqlUsuarioCreador = "OR usu.usg_grupo = {$info_solicitud[0]["UsuCodigo"]}";
            }

            $sql = "SELECT 
                    per.per_identificacion PerIdentificacion, per.per_email_interno PerEmailInterno
                FROM usuario_programacion usu 
                INNER JOIN persona per ON per.per_codigo = usu.up
                WHERE usu.usg_grupo = 69 -- GruCodigo: Administrador de Programacion academica.
                {$sqlUsuarioCreador}
                GROUP BY per.per_identificacion, per.per_email_interno

                UNION ALL

                SELECT 
                    per.per_identificacion PerIdentificacion, per.per_email_interno PerEmailInterno
                FROM usuario_planta_fisica usu 
                INNER JOIN persona per ON per.per_codigo = usu.up
                WHERE usu.usg_codigo = {$UsuCodigo}
                GROUP BY per.per_identificacion, per.per_email_interno
            ";

            if (!$this->cnx->consultar($sql)) {
                $this->errorConsultarBd["mensaje"] = "No se pudieron consultar los correos del creador de la solicitud y los administradores del sistema.";
                $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
                return $this->errorConsultarBd;
            }
            $ListaEmail = $this->cnx->json; // Contiene el uaa unificado de la unidad solicita.
        }

        if (empty($ListaEmail)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se encontraron correos asociados al usuario creador de la solicitud o los administradores.",
                "consola" => "La lista de correos esta vacio." . __LINE__ . ".",
            );
        }
        $info_solicitud[0]["Correos"] = $ListaEmail; //Agregamos a la informacion de la solicitud los correos a los que debera enviar la notificacion
        require_once "../correos/correo_solicitud_horario.php";
        $ca = new Correo_solicitud_horario();
        $resultado = $ca->enviarCorreoSolicitudHorario($info_solicitud, $tipo);
        return $resultado;
    }

    // Inicio funcion aprobarSolicitud
    // Permite aprobar una solicitud
    public function aprobarSolicitud($obj)
    {
        //Validaciones
        if (!isset($obj->SchCodigo) || !is_numeric($obj->SchCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar una solicitud.",
                "consola" => "El codigo de la solicitud no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->UaaCodigo) || !is_numeric($obj->UaaCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se encontro la unidad con la que se programo el curso.",
                "consola" => "El codigo de la uaa no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->CurCodigo) || !is_numeric($obj->CurCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se encontro el codigo del curso.",
                "consola" => "El codigo del curso no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->TicCodigo) || !is_numeric($obj->TicCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se encontro el codigo de modalidad del curso.",
                "consola" => "El codigo de la modalidad del curso no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->CurSemanas) || !is_numeric($obj->CurSemanas)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se encontro la cantidad de semanas con la que se programo el curso.",
                "consola" => "La cantidad de semanas del curso no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->SchEstado) || !is_numeric($obj->SchEstado)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el estado de la solicitud.",
                "consola" => "El codigo del estado de la solicitud no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->mensajeComentario) || strlen($obj->mensajeComentario) < 5) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe ingresar el mensaje del comentario.",
                "consola" => "El comentario de la solicitud tiene menos de 5 letras o no se envio correctamente.",
            );
        }
        if (!isset($obj->Horario) || count($obj->Horario) <= 0) {
            return array(
                "resultado" => false,
                "mensaje" => "No se encontro el nuevo horario solicitado.",
                "consola" => "No se encontraron horarios solicitados en la solicitud.",
            );
        }
        if (!isset($obj->CambioDocente) || !is_numeric($obj->CambioDocente)) {
            return array(
                "resultado" => false,
                "mensaje" => "Error en el cambio de docente.",
                "consola" => "El cambio de docente no se envio correctamente.",
            );
        }

        $CambioDocente = $obj->CambioDocente; // Contiene el boolean del cambio de docente.
        $SchCodigo = $obj->SchCodigo; // Contiene el codigo de la solicitud de cambio de horario.
        $SchEstado = $obj->SchEstado; // Contiene el codigo de rechazo de la solicitud.
        $UaaCodigo = $obj->UaaCodigo; // Contiene el codigo de la uaa del horario.
        $CurCodigo = $obj->CurCodigo; // Contiene el codigo del curso.
        $TicCodigo = $obj->TicCodigo; // Contiene el codigo del curso.
        $CurSemanas = $obj->CurSemanas; // Contiene la cantidad de semanas del curso.
        $Horario = $obj->Horario; // Contiene las nuevas horas de la solicitud.
        $UsuCodigo = $_SESSION['pacademica']['datosVinculacionUsuario']['usuarioCodigo'];

        $response = array();
        $ocupado = false; // significa que una parte o todo el horario asignado lo ocuparon con un curso
        $esoCodigos = array(); // contiene los codigos de espacios ocupacion que va a actualizar con la informacion del curso.

        $consultaHorario = self::consultaHorarioSolicitud($obj);
        if (!$consultaHorario["resultado"]) {
            return array(
                "resultado" => false,
                "mensaje" => $consultaHorario["mensaje"],
                "consola" => $consultaHorario["consola"]
            );
        }

        $this->cnx->Sentencia("BEGIN TRAN");

        // Iteramos sobre cada registro en consultaHorario["data"]
        foreach ($consultaHorario["data"] as $cHorario) {
            
            $UapCodigo = $cHorario["UapNuevoCodigo"];
            $EspNuevoCodigo = $cHorario["EspNuevoCodigo"];
            $diaNuevoNombre = $cHorario["DiaNuevoNombre"];
            $horaNuevoInicio = $cHorario["HraNuevoInicio"];
            
            if (!isset($cHorario["UapNuevoCodigo"]) || !is_numeric($cHorario["UapNuevoCodigo"])) {
                $UapCodigo = $cHorario["UapAntCodigo"];
            }

            $ch = array(
                "SchCodigo" => $SchCodigo,
                "CurCodigo" => $CurCodigo,
                "EsoSubGrupo" => $cHorario["SchhSubgrupo"],
                "diaAnterior" => $cHorario["DiaAntCodigo"],
                "horaAnterior" => $cHorario["HraAntCodigo"],
                "diaNuevo" => $cHorario["DiaNuevoCodigo"],
                "horaNuevo" => $cHorario["HraNuevoCodigo"],
                "CurSemanas" => $CurSemanas,
                "fechaInicial" => $cHorario["FechaInicio"],
                "fechaFinal" => $cHorario["FechaFin"],
                "UapCodigo" => $UapCodigo,
                "cruceEstudiantes" => true,
                "cruceDocente" => true,
                "PeriodoCodigo" => $cHorario["PeriodoCodigo"],
                "cambioDocente" => $CambioDocente
            );
            
            $chObj = (object)$ch;

            $verificarCruceHorario = self::verificarHorarioNuevo($chObj);

            if (!$verificarCruceHorario["resultado"]) {
                return array(
                    "resultado" => false,
                    "mensaje" => "No ha sido posible consultar el cruce de horario.",
                    "consola" => "No ha sido posible consultar el cruce de horario. Linea " . __LINE__ . "."
                );
            }

            // Verificamos si hay cruce de docente
            if ($verificarCruceHorario["cruceDocente"]) {
                return array(
                    "resultado" => false,
                    "mensaje" => $verificarCruceHorario["mensajeCruceDocente"],
                    "consola" => "El docente ya tiene un horario asignado en la fecha y hora seleccionada. Linea " . __LINE__ . "."
                );
            }

            // Verificamos si hay cruce de estudiantes
            if ($verificarCruceHorario["cruceEstudiantes"]) {
                return array(
                    "resultado" => false,
                    "mensaje" => $verificarCruceHorario["mensajeCruceEstudiante"],
                    "consola" => "Los estudiantes ya tienen un horario asignado en la fecha y hora seleccionada. Linea " . __LINE__ . "."
                );
            }

            if($TicCodigo != 2){ // Validamos el espacio disponible unicamente cuando no es virtual.

                // Las AULA EXTERNA son espacios ficticios (eti_codigo 6 = AE - AULAEXTERNA, 22 = ESPACIOS EXTERNOS)
                // y no representan una ocupación física real, por lo que no aplica la validación de disponibilidad del espacio.
                $sqlTipoEspacio = "SELECT eti_codigo EtiCodigo FROM espacio WHERE esp_codigo = {$EspNuevoCodigo}";
                if (!$this->cnx->Consultar($sqlTipoEspacio)) {
                    $this->errorConsultarBd["mensaje"] = "No se pudo consultar el tipo del espacio seleccionado.";
                    $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
                    return $this->errorConsultarBd;
                }
                $tipoEspacio = $this->cnx->json;
                $esAulaExterna = count($tipoEspacio) > 0 && in_array(intval($tipoEspacio[0]['EtiCodigo']), array(6, 22), true);

                if (!$esAulaExterna) {
                    $fechaInicialSql = FechaSqlServer::toSqlDateTime2($chObj->fechaInicial, false);
                    $fechaFinalFinDiaSql = FechaSqlServer::toSqlDateTime2($chObj->fechaFinal, true);
                    if ($fechaInicialSql === false || $fechaFinalFinDiaSql === false) {
                        return array(
                            "resultado" => false,
                            "mensaje" => "Formato de fecha inválido al validar disponibilidad del espacio.",
                            "consola" => "No se pudieron preparar fechas SQL para rango {$chObj->fechaInicial} - {$chObj->fechaFinal}."
                        );
                    }

                    $sql = "SELECT eso_actividad EsoActividad FROM espacio_ocupacion WHERE esp_codigo = {$EspNuevoCodigo}
                            AND dia_codigo = {$chObj->diaNuevo}
                            AND hra_codigo = {$chObj->horaNuevo}
                        AND eso_fecha BETWEEN {$fechaInicialSql} AND {$fechaFinalFinDiaSql} AND eso_actividad IS NOT NULL
                            GROUP BY
                            eso_actividad
                    ";

                    if (!$this->cnx->Consultar($sql)) {
                        $this->errorConsultarBd["mensaje"] = "No se pudo realizar la consulta de la asignación del espacio.";
                        $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
                        return $this->errorConsultarBd;
                    }

                    $response = $this->cnx->json;

                    //Verificamos que el espacio esté disponible
                    if (count($response) > 0) {
                        return array(
                            "resultado" => false,
                            "mensaje" => "El espacio seleccionado cuenta con un curso programado {$response[0]['EsoActividad']} el día {$diaNuevoNombre} a las {$horaNuevoInicio}, por favor verificar.",
                            "consola" => "El espacio seleccionado cuenta con un curso programado {$response[0]['EsoActividad']} el día {$diaNuevoNombre} a las {$horaNuevoInicio}, por favor verificar. Linea " . __LINE__ . "."
                        );
                    }
                }
            }
        }

        // Validamos que el horario anterior de CADA hora de la solicitud siga existiendo tal cual antes de
        // tocar ninguna. Si esto se validara horario por horario dentro del mismo loop que borra y crea,
        // una solicitud con varias horas podria quedar con las primeras ya aplicadas y las ultimas rechazadas,
        // dejando la solicitud a medio aplicar y sin forma de reintentarla (el ROLLBACK TRAN de este archivo
        // no revierte nada real porque cada sentencia abre su propia conexion nueva, ver conexion/cls_config.php).
        // Validar todo antes de aplicar nada evita ese escenario.
        foreach ($Horario as $horarioNuevo) {
            $whereHorarioAnteriorExacto = "
                    eso_actividad = {$CurCodigo}
                    AND esp_codigo = {$horarioNuevo->EspAntCodigo}
                    AND uaa_codigo = {$UaaCodigo}
                    AND eso_subgrupo = '{$horarioNuevo->SchhSubgrupo}'
                    AND dia_codigo = {$horarioNuevo->DiaAntCodigo}
                    AND hra_codigo = {$horarioNuevo->HraAntCodigo}
                    AND uap_codigo = {$horarioNuevo->UapAntCodigo}
            ";
            $whereHorarioAnteriorCurso = "
                    eso_actividad = {$CurCodigo}
                    AND uaa_codigo = {$UaaCodigo}
                    AND eso_subgrupo = '{$horarioNuevo->SchhSubgrupo}'
                    AND dia_codigo = {$horarioNuevo->DiaAntCodigo}
                    AND hra_codigo = {$horarioNuevo->HraAntCodigo}
            ";

            $sqlVerificarAnteriorExacto = "SELECT COUNT(*) Total FROM espacio_ocupacion WHERE {$whereHorarioAnteriorExacto}";
            if (!$this->cnx->consultar($sqlVerificarAnteriorExacto)) {
                $this->errorConsultarBd["mensaje"] = "No se pudo verificar el horario anterior de la solicitud {$SchCodigo}.";
                $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
                return $this->errorConsultarBd;
            }
            $totalExacto = intval($this->cnx->json[0]['Total']);

            $sqlVerificarAnteriorCurso = "SELECT COUNT(*) Total FROM espacio_ocupacion WHERE {$whereHorarioAnteriorCurso}";
            if (!$this->cnx->consultar($sqlVerificarAnteriorCurso)) {
                $this->errorConsultarBd["mensaje"] = "No se pudo verificar el horario anterior de la solicitud {$SchCodigo}.";
                $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
                return $this->errorConsultarBd;
            }
            $totalCurso = intval($this->cnx->json[0]['Total']);

            // Solo es valido si TODAS las filas del curso/subgrupo/dia/hora tienen exactamente el espacio y
            // docente anterior registrados en la solicitud (ninguna quedo con un valor distinto por un cambio
            // parcial de otro modulo, ej. Cambdocente actualizando algunas semanas si y otras no).
            $totalParaValidar = ($totalExacto > 0 && $totalExacto === $totalCurso) ? $totalExacto : 0;

            $consistenciaPrevia = self::evaluarConsistenciaHorarioAnterior($horarioNuevo, $totalParaValidar, 'antes_de_eliminar');
            if (!$consistenciaPrevia["resultado"]) {
                $this->cnx->Sentencia("ROLLBACK TRAN");
                return $consistenciaPrevia;
            }
        }

        foreach ($Horario as $horarioNuevo) {

            // Validamos si se solicitó un cambio de docente para asignarlo
            if($CambioDocente && $horarioNuevo->UapNuevoCodigo != ''){
                $Docente = $horarioNuevo->UapNuevoCodigo;
            }else{
                $Docente = $horarioNuevo->UapAntCodigo;
            }

            // Verificamos que el horario si se encuentre asignado y no se ocupara despues
            if ($TicCodigo != 2) {
                $fechaInicioSql = FechaSqlServer::toSqlDateTime2($horarioNuevo->FechaInicio, false);
                $fechaFinFinDiaSql = FechaSqlServer::toSqlDateTime2($horarioNuevo->FechaFin, true);
                if ($fechaInicioSql === false || $fechaFinFinDiaSql === false) {
                    return array(
                        "resultado" => false,
                        "mensaje" => "Formato de fecha inválido al consultar horario de solicitud.",
                        "consola" => "No se pudieron preparar fechas SQL para rango {$horarioNuevo->FechaInicio} - {$horarioNuevo->FechaFin}."
                    );
                }
                $sql = "SELECT 
                        eso_codigo EsoCodigo, 
                        eso_fecha EsoFecha, 
                        eso_actividad EsoActividad 
                    FROM 
                        espacio_ocupacion eso 
                    WHERE 
                        esp_codigo = {$horarioNuevo->EspNuevoCodigo}
                        AND uaa_codigo = {$UaaCodigo}
                        AND dia_codigo = {$horarioNuevo->DiaNuevoCodigo}
                        AND hra_codigo = {$horarioNuevo->HraNuevoCodigo}
                        AND eso_estado = '9'
                        AND eso_fecha BETWEEN {$fechaInicioSql} AND {$fechaFinFinDiaSql}
                ";
                if (!$this->cnx->consultar($sql)) {
                    $this->errorConsultarBd["mensaje"] = "No se pudo realizar la consulta del horario de la solicitude {$SchCodigo}.";
                    $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
                    return $this->errorConsultarBd;
                }
                $espacioAsignado = $this->cnx->json;
                $esoCodigos = [];
                foreach ($espacioAsignado as $asignacion) {
                    if ($asignacion["EsoActividad"] != '') {
                        $ocupado = true;
                    }
                    if ($ocupado == true) {
                        return array(
                            "resultado" => false,
                            "mensaje" => "El espacio asignado para la fecha {$asignacion->EsoFecha}, el dia {$horarioNuevo->DiaNuevoCodigo} y la hora {$horarioNuevo->HraNuevoCodigo}, se encuentra ocupado con el curso {$asignacion->EsoActividad}",
                            "data" => $response,
                        );
                    }
                    $esoCodigos[] = $asignacion["EsoCodigo"];
                }
            }

            // Se elimina el horario anterior que concuerde con, curso, subgrupo, espacio anterior, hora anterior, dia anterior.
            // Ya validamos arriba (antes de este loop) que este horario anterior existe tal cual para TODAS
            // las horas de la solicitud, asi que aqui solo construimos el WHERE para el DELETE.
            $whereHorarioAnterior = "
                    esp_codigo = {$horarioNuevo->EspAntCodigo}
                    AND uaa_codigo = {$UaaCodigo}
                    AND eso_subgrupo = '{$horarioNuevo->SchhSubgrupo}'
                    AND dia_codigo = {$horarioNuevo->DiaAntCodigo}
                    AND hra_codigo = {$horarioNuevo->HraAntCodigo}
                    AND uap_codigo = {$horarioNuevo->UapAntCodigo}
            ";

            $sql = "DELETE FROM espacio_ocupacion WHERE {$whereHorarioAnterior}";

            if (!$this->cnx->sentencia($sql)) {
                $this->errorSentenciaBd["mensaje"] = "Error al eliminar el horario anterior de la solicitud {$SchCodigo}.
                    Recargue la página e intente de nuevo.";
                $this->errorSentenciaBd["consola"] = "Ha fallado el delete del horario anterior de la solicitud " . __LINE__ . ".";
                $this->cnx->Sentencia("ROLLBACK TRAN");
                return $this->errorSentenciaBd;
            }

            // Verificamos que el DELETE realmente haya eliminado el horario anterior esperado antes de
            // crear/activar el horario nuevo. Si no eliminó nada (condición de carrera con otro módulo),
            // revertimos toda la transacción para no dejar el curso con horas duplicadas.
            $consistenciaPosterior = self::evaluarConsistenciaHorarioAnterior($horarioNuevo, $this->cnx->cantRegistros, 'despues_de_eliminar');
            if (!$consistenciaPosterior["resultado"]) {
                $this->cnx->Sentencia("ROLLBACK TRAN");
                return $consistenciaPosterior;
            }

            if ($TicCodigo != 2) {
                // Se actualiza el horario asignado con la informacion necesaria, espacio nuevo, hora nueva, dia nuevo, subgrupo, actividad, docente, estado = G, usuario
                if (count($esoCodigos) > 0) {
                    $implodeEsoCodigos = implode(",", $esoCodigos);
                    // TODO: Se deben verificar permisos de updated en la tabla espacio_ocupacion en los campos eso_estado y usu_codigo para el grupo programacionacademica__admon
                    $sql = "UPDATE espacio_ocupacion
                        SET
                            eso_actividad = {$CurCodigo},                        
                            eso_subgrupo = '{$horarioNuevo->SchhSubgrupo}',
                            uap_codigo = {$Docente},
                            eso_estado = 'G',
                            usu_codigo = {$UsuCodigo}
                        WHERE
                            eso_codigo IN ($implodeEsoCodigos)
                    ";

                    if (!$this->cnx->sentencia($sql)) {
                        $this->errorSentenciaBd["mensaje"] = "Error al actualizar el horario nuevo de la solicitud {$SchCodigo}. 
                            Recargue la página e intente de nuevo.";
                        $this->errorSentenciaBd["consola"] = "Ha fallado el update del horario nuevo de la solicitud " . __LINE__ . ".";
                        $this->errorSentenciaBd["sql"] = $sql;
                        $this->cnx->Sentencia("ROLLBACK TRAN");
                        return $this->errorSentenciaBd;
                    }
                }
            } else {
                // Insertamos nuevo horario con el nuevo espacio.
                $sqlArrayValues = array();
                $fechasParaAsignar = self::obtener_fechas_dia_semana($horarioNuevo->FechaInicio, $horarioNuevo->DiaNuevoCodigo, $CurSemanas);

                // 3. Insertamos la nueva asignacion con las fechas obtenidas
                $sql = "INSERT INTO espacio_ocupacion (
                eso_actividad, 
                eso_subgrupo, 
                esp_codigo, 
                uaa_codigo, 
                eso_fecha,
                dia_codigo, 
                hra_codigo, 
                eso_estado, 
                uap_codigo, 
                usu_codigo) VALUES ";
                foreach ($fechasParaAsignar as $fecha) {    
                    $fechaSql = FechaSqlServer::toSqlDateTime2($fecha, false);
                    if ($fechaSql === false) {
                        return array(
                            "resultado" => false,
                            "mensaje" => "Formato de fecha inválido al asignar nuevo espacio.",
                            "consola" => "No se pudo preparar fecha SQL para {$fecha}."
                        );
                    }
                    $sqlArrayValues[] = "
                    ({$CurCodigo}, 
                    '{$horarioNuevo->SchhSubgrupo}', 
                    {$horarioNuevo->EspNuevoCodigo}, 
                    {$UaaCodigo}, 
                    {$fechaSql}, 
                    {$horarioNuevo->DiaNuevoCodigo}, 
                    {$horarioNuevo->HraNuevoCodigo}, 
                    '9', 
                    {$Docente}, 
                    {$UsuCodigo})";
                }
                $sql .= implode(',', $sqlArrayValues);
                if (!$this->cnx->sentencia($sql)) {
                    $this->errorSentenciaBd["mensaje"] = "Error al asignar el nuevo espacio, {$SchCodigo}. 
                        Recargue la página e intente de nuevo.";
                    $this->errorSentenciaBd["consola"] = "Ha fallado el insert de la asignacion nueva " . __LINE__ . ".";
                    $this->cnx->Sentencia("ROLLBACK TRAN");
                    return $this->errorSentenciaBd;
                }
            }
        }

        $guardarJustificacion = self::guardarComentarios($obj, 'Sin notificacion'); // Guardamos la justificacion del rechazos
        // Verificamos si se guardo correctamente
        if (!$guardarJustificacion["resultado"]) {
            return array(
                "resultado" => false,
                "mensaje" => $guardarJustificacion["mensaje"],
                "consola" => "La justificacion de la aprobación de la solicitud no se guardo correctamente.",
            );
        }

        $sql = "UPDATE programacionacademica.solicitud_cambio_horario
            SET sch_estado = {$SchEstado}
            WHERE sch_codigo = {$SchCodigo}
        ";

        if (!$this->cnx->sentencia($sql)) {
            $this->errorSentenciaBd["mensaje"] = "Error al aprobar la solicitud {$SchCodigo}. 
                Recargue la página e intente de nuevo.";
            $this->errorSentenciaBd["consola"] = "Ha fallado el update del estado en la solicitud " . __LINE__ . ".";
            $this->cnx->Sentencia("ROLLBACK TRAN");
            return $this->errorSentenciaBd;
        }

        $this->cnx->Sentencia("COMMIT TRAN");

        $mensaje = "La solicitud ha sido aprobada con éxito, se verificó el cruce de horario y la asginación de espacios";
        if($CambioDocente){
            $mensaje .= ", el docente se cambio en los horarios seleccionados";
        }

        require_once(dirname(__FILE__) . "/Curhorario.php");
        $CurHorario = new CurHorario();
        $r_actualizacion_agenda = $CurHorario->actualizarAgenda($CurCodigo, $CurSemanas);
        if (!$r_actualizacion_agenda) {
            $mensaje .= ", " . $r_actualizacion_agenda["mensaje"] . ".";
        } else {
            $mensaje .= ", la agenda se actualizó correctamente.";
        }

        $envioCorreo = self::enviarNotificacion($obj, 'AprobadoVice');

        return array(
            "resultado" => true,
            "mensaje" => $mensaje,
            "email" => $envioCorreo
        );
    }

    // Inicio evaluarConsistenciaHorarioAnterior
    // Decide si aprobarSolicitud puede continuar dado cuantos registros del horario anterior
    // de la solicitud coinciden con espacio_ocupacion, antes y despues de intentar eliminarlos.
    public function evaluarConsistenciaHorarioAnterior($horarioNuevo, $totalRegistrosEncontrados, $etapa)
    {
        if (intval($totalRegistrosEncontrados) > 0) {
            return array("resultado" => true);
        }

        $detalle = "subgrupo {$horarioNuevo->SchhSubgrupo}, espacio {$horarioNuevo->EspAntCodigo}, "
            . "día {$horarioNuevo->DiaAntCodigo}, hora {$horarioNuevo->HraAntCodigo}, docente {$horarioNuevo->UapAntCodigo}";

        if ($etapa === 'antes_de_eliminar') {
            return array(
                "resultado" => false,
                "mensaje" => "El horario anterior de la solicitud ya no coincide con la programación actual del curso ({$detalle}). "
                    . "Es posible que otro módulo haya modificado el docente o el espacio del curso. Rechace o actualice la solicitud antes de aprobarla.",
                "consola" => "No se encontró el horario anterior esperado en espacio_ocupacion antes de eliminar ({$detalle})."
            );
        }

        return array(
            "resultado" => false,
            "mensaje" => "No fue posible confirmar la eliminación del horario anterior de la solicitud ({$detalle}). "
                . "El proceso se detuvo, pero el horario del curso pudo haber quedado parcialmente modificado. "
                . "No reintente la aprobación: contacte a soporte técnico para verificar y corregir el horario del curso antes de continuar.",
            "consola" => "El DELETE del horario anterior no afectó ningún registro pese a la verificación previa ({$detalle})."
        );
    }
    // Fin evaluarConsistenciaHorarioAnterior

    // Inicio construirSqlSolicitudDocenteEnHorarioNuevo
    // Arma la consulta que cuenta las solicitudes EN TRAMITE del periodo que ya dejan al docente
    // en el horario destino seleccionado, sin importar el curso (dos solicitudes distintas no pueden
    // llevar al mismo docente al mismo dia y hora del mismo periodo).
    // El docente que queda ocupando el horario nuevo de una solicitud guardada es el docente nuevo
    // cuando hubo cambio de docente y el anterior cuando no lo hubo, por eso el ISNULL.
    // SchCodigo es la solicitud que se esta editando: se excluye para que no se bloquee a si misma
    // con los horarios que ella misma ya tiene guardados. En creacion llega null y no se excluye nada.
    public function construirSqlSolicitudDocenteEnHorarioNuevo($UapCodigo, $diaNuevo, $horaNuevo, $PeriodoCodigo, $SchCodigo = null)
    {
        $estadosEnTramite = implode(", ", self::ESTADOS_SOLICITUD_EN_TRAMITE);
        $queryExcluirSolicitudPropia = "";
        if (is_numeric($SchCodigo)) {
            $queryExcluirSolicitudPropia = "AND sch.sch_codigo <> {$SchCodigo}";
        }

        return "SELECT COUNT(*) ExistenHoras
            FROM programacionacademica.solicitud_cambio_horario_horario schh
            INNER JOIN programacionacademica.solicitud_cambio_horario sch ON sch.sch_codigo = schh.sch_codigo
            INNER JOIN curso cur ON cur.cur_codigo = sch.cur_codigo
            INNER JOIN calendario cal ON cal.cal_codigo = cur.cal_codigo AND cal.per_codigo = {$PeriodoCodigo}
            WHERE
                schh.schh_estado IN (1)
                AND sch.sch_estado IN ({$estadosEnTramite})
                AND ISNULL(schh.schh_uap_codigo_nuevo, schh.schh_uap_codigo_anterior) = {$UapCodigo}
                AND schh.schh_dia_codigo_nuevo = {$diaNuevo}
                AND schh.schh_hra_codigo_nuevo = {$horaNuevo}
                {$queryExcluirSolicitudPropia}
        ";
    }
    // Fin construirSqlSolicitudDocenteEnHorarioNuevo

    // Inicio construirSqlSolicitudDuplicadaCurso
    // Arma la consulta que cuenta las solicitudes EN TRAMITE del periodo que ya piden mover
    // exactamente el mismo horario de origen del mismo curso y subgrupo (solicitud duplicada).
    public function construirSqlSolicitudDuplicadaCurso($CurCodigo, $EsoSubGrupo, $diaAnterior, $horaAnterior, $PeriodoCodigo)
    {
        $estadosEnTramite = implode(", ", self::ESTADOS_SOLICITUD_EN_TRAMITE);

        return "SELECT COUNT(*) ExistenHoras
            FROM programacionacademica.solicitud_cambio_horario_horario schh
            INNER JOIN programacionacademica.solicitud_cambio_horario sch ON sch.sch_codigo = schh.sch_codigo
            INNER JOIN curso cur ON cur.cur_codigo = sch.cur_codigo
            INNER JOIN calendario cal ON cal.cal_codigo = cur.cal_codigo AND cal.per_codigo = {$PeriodoCodigo}
            WHERE
                schh.schh_estado IN (1)
                AND sch.sch_estado IN ({$estadosEnTramite})
                AND sch.cur_codigo = {$CurCodigo}
                AND schh.schh_subgrupo = '{$EsoSubGrupo}'
                AND schh.schh_dia_codigo_anterior = {$diaAnterior}
                AND schh.schh_hra_codigo_anterior = {$horaAnterior}
        ";
    }
    // Fin construirSqlSolicitudDuplicadaCurso

    // Inicio eliminarSolicitud
    // Permite rechazar una solicitud
    public function eliminarSolicitud($obj)
    {
        if (!isset($obj->SchCodigo) || !is_numeric($obj->SchCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo de la solicitud.",
                "consola" => "El codigo de la solicitud no viene o no es numerico, " . $obj->SchCodigo,
            );
        }

        $SchCodigo = $obj->SchCodigo; // Contiene el codigo de la solicitud de cambio de horario

        $sql = "UPDATE programacionacademica.solicitud_cambio_horario
            SET sch_estado = 0
            WHERE sch_codigo = {$SchCodigo}
        ";

        if (!$this->cnx->sentencia($sql)) {
            $this->errorSentenciaBd["mensaje"] = "Error al eliminar la solicitud {$SchCodigo}. 
                Recargue la página e intente de nuevo.";
            $this->errorSentenciaBd["consola"] = "Ha fallado el update del estado en la solicitud " . __LINE__ . ".";
            return $this->errorSentenciaBd;
        }

        return array(
            "resultado" => true,
            "mensaje" => "La solicitud se ha eliminado correctamente."
        );
    }

    // Inicio rechazarSolicitud
    // Permite rechazar una solicitud
    public function rechazarSolicitud($obj)
    {
        //Validaciones
        if (!isset($obj->SchCodigo) || !is_numeric($obj->SchCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar una solicitud.",
                "consola" => "El codigo de la solicitud no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->SchEstado) || !is_numeric($obj->SchEstado)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el estado de la solicitud.",
                "consola" => "El codigo del estado de la solicitud no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->mensajeComentario) || strlen($obj->mensajeComentario) < 5) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe ingresar el mensaje del comentario.",
                "consola" => "El comentario de la solicitud tiene menos de 5 letras o no se envio correctamente.",
            );
        }

        $SchCodigo = $obj->SchCodigo; // Contiene el codigo de la solicitud de cambio de horario
        $SchEstado = $obj->SchEstado; // Contiene el codigo de rechazo de la solicitud

        $guardarJustificacion = self::guardarComentarios($obj, "Sin Notificacion"); // Guardamos la justificacion del rechazos
        // Verificamos si se guardo correctamente
        if (!$guardarJustificacion["resultado"]) {
            return array(
                "resultado" => false,
                "mensaje" => $guardarJustificacion["mensaje"],
                "consola" => "La justificacion del rechazo de la solicitud no se guardo correctamente.",
            );
        }

        $sql = "UPDATE programacionacademica.solicitud_cambio_horario
            SET sch_estado = {$SchEstado}
            WHERE sch_codigo = {$SchCodigo}
        ";

        if (!$this->cnx->sentencia($sql)) {
            $this->errorSentenciaBd["mensaje"] = "Error al rechazar la solicitud {$SchCodigo}. 
                Recargue la página e intente de nuevo.";
            $this->errorSentenciaBd["consola"] = "Ha fallado el update del estado en la solicitud " . __LINE__ . ".";
            return $this->errorSentenciaBd;
        }

        $envioCorreo = self::enviarNotificacion($obj, 'RechazadoVice');

        return array(
            "resultado" => true,
            "mensaje" => "La solicitud se rechazo correctamente.",
            "email" => $envioCorreo
        );
    }

    // Inicio rechazarSolicitudJefePrograma
    // Permie rechazar una solicitud por el jefe de programa
    public function rechazarSolicitudJefePrograma($obj){
        //Validaciones
        if (!isset($obj->SchCodigo) || !is_numeric($obj->SchCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar una solicitud.",
                "consola" => "El codigo de la solicitud no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->SchEstado) || !is_numeric($obj->SchEstado)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el estado de la solicitud.",
                "consola" => "El codigo del estado de la solicitud no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->mensajeComentario) || strlen($obj->mensajeComentario) < 5) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe ingresar el mensaje del comentario.",
                "consola" => "El comentario de la solicitud tiene menos de 5 letras o no se envio correctamente.",
            );
        }

        $SchCodigo = $obj->SchCodigo; // Contiene el codigo de la solicitud de cambio de horario
        $SchEstado = $obj->SchEstado; // Contiene el codigo de rechazo de la solicitud

        $guardarJustificacion = self::guardarComentarios($obj, "Sin Notificacion"); // Guardamos la justificacion del rechazos
        // Verificamos si se guardo correctamente
        if (!$guardarJustificacion["resultado"]) {
            return array(
                "resultado" => false,
                "mensaje" => $guardarJustificacion["mensaje"],
                "consola" => "La justificacion del rechazo de la solicitud no se guardo correctamente.",
            );
        }

        $sql = "UPDATE programacionacademica.solicitud_cambio_horario
            SET sch_estado = {$SchEstado}
            WHERE sch_codigo = {$SchCodigo}
        ";

        if (!$this->cnx->sentencia($sql)) {
            $this->errorSentenciaBd["mensaje"] = "Error al rechazar la solicitud {$SchCodigo}. 
                Recargue la página e intente de nuevo.";
            $this->errorSentenciaBd["consola"] = "Ha fallado el update del estado en la solicitud " . __LINE__ . ".";
            return $this->errorSentenciaBd;
        }

        $envioCorreo = self::enviarNotificacion($obj, 'RechazadoJefePrograma');

        return array(
            "resultado" => true,
            "mensaje" => "La solicitud se rechazo correctamente.",
            "email" => $envioCorreo
        );
    }

    // Inicio reActivarSolicitud
    // Permite re activar una soliciud previamene rechazada.
    public function reActivarSolicitud($obj)
    {
        if (!isset($obj->SchCodigo) || !is_numeric($obj->SchCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo de la solicitud.",
                "consola" => "El codigo de la solicitud no viene o no es numerico, " . $obj->SchCodigo,
            );
        }
        if (!isset($obj->TicCodigo) || !is_numeric($obj->TicCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo de la modalidad del curso.",
                "consola" => "El codigo de la modalidad del curso no viene o no es numerico, " . $obj->TicCodigo,
            );
        }

        $SchCodigo = $obj->SchCodigo; // Contiene el codigo de la solicitud de cambio de horario
        $TicCodigo = $obj->TicCodigo; // Contiene el codigo del tipo de curso, virtual, presencial, mixto
        $GruCodigo = $_SESSION["pacademica"]["datosVinculacionUsuario"]["grupoCodigo"];

        if ($GruCodigo == $_SESSION['pacademica']['ROLES']['SECRETARIA']) { // Si el usuario es secretario de programa debe solicitar primero aprobacion del jefe de programa.
            $EstadoInicial = $this->estadosSolicitud['Solicitado Jefe Programa'];
        }
        if ($GruCodigo != $_SESSION['pacademica']['ROLES']['SECRETARIA']) { // Si el usuario es jefe de programa si se envia inmediatamente
            $EstadoInicial = $TicCodigo != 2 ? $this->estadosSolicitud['Solicitado'] : $this->estadosSolicitud['Aprobado Curso Virtual'];
        }

        if ($EstadoInicial == "") {
            return array(
                "resultado" => false,
                "mensaje" => "No se logro asignar un estado inicial de la solicitud.",
                "consola" => "No se logro asignar un estado inicial de la solicitud = {$EstadoInicial}"
            );
        }

        $queryDocente = "";
        if($obj->CambioDocente == 1){
            $queryDocente = ", sch_cambio_docente = {$obj->CambioDocente}";
        }

        $sql = "UPDATE programacionacademica.solicitud_cambio_horario
            SET 
                sch_estado = {$EstadoInicial},
                sch_espacio_deportivo = {$obj->EspDeportivo}
                {$queryDocente}
            WHERE sch_codigo = {$SchCodigo}
        ";

        if (!$this->cnx->sentencia($sql)) {
            $this->errorSentenciaBd["mensaje"] = "Error al re activar la solicitud {$SchCodigo}. 
                Recargue la página e intente de nuevo.";
            $this->errorSentenciaBd["consola"] = "Ha fallado el update del estado en la solicitud " . __LINE__ . ".";
            return $this->errorSentenciaBd;
        }
        error_log("enviarNotificacion ReActivacion");
        $envioCorreo = self::enviarNotificacion($obj, 'ReActivacion');

        return array(
            "resultado" => true,
            "mensaje" => "La solicitud se re activo correctamente.",
            "email" => $envioCorreo
        );
    }

    // Inicio guardarHorarioSolicitud
    // Permite agregar un horario especifico a una solicitud.
    public function guardarHorarioSolicitud($obj)
    {
        // Validacion
        if (!isset($obj->NuevoHorario) || count($obj->NuevoHorario) <= 0) {
            return array(
                "resultado" => false,
                "mensaje" => "No se encontro cambios de horario.",
                "consola" => "No se encontraron cambios de horario para ese curso.",
            );
        }
        if (!isset($obj->SchCodigo) || !is_numeric($obj->SchCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo de la solicitud.",
                "consola" => "El codigo de la solicitud no viene o no es numerico, " . $obj->SchCodigo,
            );
        }

        $NuevoHorario = $obj->NuevoHorario; // Contiene arreglo con la informacion del nuevo horario.
        $SchCodigo = $obj->SchCodigo; // Contiene codigo de la solicitud
        $CambioDocente = $obj->CambioDocente; // Contiene si se va a realizar el cambio de docente.
        $CurCodigo = $obj->CurCodigo; // Contiene si se va a realizar el cambio de docente.
        $TicCodigo = $obj->TicCodigo; // Contiene el codigo de la modalidad del curso (2 = Virtual)
        $UaaCodigo = $NuevoHorario->UaaCodigo;

        // Verificacion de se le pueden agregar horas en caso de ser docente nuevo
        $queryCampoNuevoDocente = "";
        $queryValorNuevoDocente = "";

        if ($CambioDocente == "1") {
            $cantidadNuevasHoras = count($NuevoHorario); // Cantidad de horas nuevas.
            $infoHoras = array(
                "UapCodigo" => $NuevoHorario->VinculacionNuevoDocente->UapCodigo,
                "CurCodigo" => $CurCodigo,
                "SubGrupo" => $NuevoHorario->EsoSubGrupo,
                "CantidadHorasNuevas" => $cantidadNuevasHoras,
                "UaaCodigo" => $UaaCodigo
            );
            $infoHorasObj = (object) $infoHoras;
            $validacionAgendaDocente = self::validarHorasDocente($infoHorasObj);
            if (!isset($validacionAgendaDocente["resultado"]) || !$validacionAgendaDocente["resultado"]) {
                return array(
                    "resultado" => false,
                    "mensaje" => "No se le es permitido adicionar ({$cantidadNuevasHoras}), por favor verificar la agenda."
                );
            }
            if (isset($NuevoHorario->VinculacionNuevoDocente)) {
                $queryCampoNuevoDocente = "schh_uap_codigo_nuevo,";
                $queryValorNuevoDocente = $NuevoHorario->VinculacionNuevoDocente->UapCodigo . ",";
            }
        }

        // Verificamos si existe una solicitud activa con un horario que no este eliminada
        $sql = "SELECT COUNT(*) ExisteSolicitud
            FROM programacionacademica.solicitud_cambio_horario_horario schh
            INNER JOIN programacionacademica.solicitud_cambio_horario sch ON sch.sch_codigo = schh.sch_codigo AND sch.sch_estado != 0 AND sch.cur_codigo = {$CurCodigo}
            WHERE
                schh.schh_estado = 1
                AND schh.schh_dia_codigo_anterior = {$NuevoHorario->DiaCodigo}
                AND schh.schh_hra_codigo_anterior = {$NuevoHorario->HraCodigo}
                AND schh.schh_subgrupo = '{$NuevoHorario->EsoSubGrupo}'
        ";
        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["mensaje"] = "No se pudo realizar la consulta si existen solicitudes del mismo curso {$CurCodigo} y horario seleccionado. {$SchCodigo}.";
            $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
            return $this->errorConsultarBd;
        }
        $horario = $this->cnx->json;
        if (count($horario) > 0 && $horario[0]['ExisteSolicitud'] > 0){
            return array(
                "resultado" => false,
                "mensaje" => "Existe una solicitud vigente del mismo curso {$CurCodigo} y horario seleccionado, por favor las solicitudes existentes."
            );
        }


        /* ANTERIOR
        $sql = "INSERT INTO programacionacademica.solicitud_cambio_horario_horario (
            sch_codigo,
            schh_estado,
            schh_subgrupo,
            schh_dia_codigo_anterior,
            schh_hra_codigo_anterior,
            schh_esp_codigo_anterior,
            schh_uap_codigo_anterior,
            schh_dia_codigo_nuevo,
            schh_hra_codigo_nuevo,
            {$queryCampoNuevoDocente}
            schh_fecha_inicio,
            schh_fecha_fin
        ) VALUES (
            {$SchCodigo},
            1,
            '{$NuevoHorario->EsoSubGrupo}',
            {$NuevoHorario->DiaCodigo},
            {$NuevoHorario->HraCodigo},
            {$NuevoHorario->EspCodigo},
            {$NuevoHorario->UapCodigo},
            {$NuevoHorario->diaNuevo->DiaCodigo},
            {$NuevoHorario->horaNuevo->HraCodigo},
            {$queryValorNuevoDocente}
            '{$NuevoHorario->fechaInicial}',
            '{$NuevoHorario->fechaFinal}'
        )
        "; */

        if ($TicCodigo != 2) {
            $sql = "INSERT INTO programacionacademica.solicitud_cambio_horario_horario (
                    sch_codigo,
                    schh_estado,
                    schh_subgrupo,
                    schh_dia_codigo_anterior,
                    schh_hra_codigo_anterior,
                    schh_esp_codigo_anterior,
                    schh_uap_codigo_anterior,
                    schh_dia_codigo_nuevo,
                    schh_hra_codigo_nuevo,
                    {$queryCampoNuevoDocente}
                    schh_fecha_inicio,
                    schh_fecha_fin
                ) VALUES (
                    {$SchCodigo},
                    1,
                    '{$NuevoHorario->EsoSubGrupo}',
                    {$NuevoHorario->DiaCodigo},
                    {$NuevoHorario->HraCodigo},
                    {$NuevoHorario->EspCodigo},
                    {$NuevoHorario->UapCodigo},
                    {$NuevoHorario->diaNuevo->DiaCodigo},
                    {$NuevoHorario->horaNuevo->HraCodigo},
                    {$queryValorNuevoDocente}
                    '{$NuevoHorario->fechaInicial}',
                    '{$NuevoHorario->fechaFinal}'
                )
            ";
        } else {
            $sql = "INSERT INTO programacionacademica.solicitud_cambio_horario_horario (
                    sch_codigo,
                    schh_estado,
                    schh_subgrupo,
                    schh_dia_codigo_anterior,
                    schh_hra_codigo_anterior,
                    schh_esp_codigo_anterior,
                    schh_uap_codigo_anterior,
                    schh_dia_codigo_nuevo,
                    schh_hra_codigo_nuevo,
                    {$queryCampoNuevoDocente}
                    schh_esp_codigo_nuevo,
                    schh_fecha_inicio,
                    schh_fecha_fin
                ) VALUES (
                    {$SchCodigo},
                    1,
                    '{$NuevoHorario->EsoSubGrupo}',
                    {$NuevoHorario->DiaCodigo},
                    {$NuevoHorario->HraCodigo},
                    {$NuevoHorario->EspCodigo},
                    {$NuevoHorario->UapCodigo},
                    {$NuevoHorario->diaNuevo->DiaCodigo},
                    {$NuevoHorario->horaNuevo->HraCodigo},
                    {$queryValorNuevoDocente}
                    {$NuevoHorario->EspCodigo},
                    '{$NuevoHorario->fechaInicial}',
                    '{$NuevoHorario->fechaFinal}'
                )
            ";
        }
        // Verificamos que se guardara correctamente
        if (!$this->cnx->sentencia($sql)) {
            $this->errorSentenciaBd["mensaje"] = "Error al guardar el nuevo horario en la solicitud de cambio de horario: {$SchCodigo}.";
            $this->errorSentenciaBd["consola"] = "Ha fallado la creacion del nuevo horario de la solicitud: {$SchCodigo}. Linea : " . __LINE__ . ".";
            return $this->errorSentenciaBd;
        }

        return array(
            "resultado" => true,
            "mensaje" => "El horario se agrego correctamente.",
        );
    }

    // Inicio consultaHorarioSolicitud
    // Permite consultar el horario de una solicitud
    public function consultaHorarioSolicitud($obj)
    {
        //Validaciones
        if (!isset($obj->SchCodigo) || !is_numeric($obj->SchCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar una solicitud.",
                "consola" => "El codigo de la solicitud no es numérico o no se envio correctamente.",
            );
        }

        $SchCodigo = $obj->SchCodigo; // Contiene codigo de la solicitud

        $sql = "SELECT
                    schh.schh_codigo SchhCodigo,
                    schh.sch_codigo SchCodigo,
                    schh.schh_estado SchhEstado,
                    schh.schh_subgrupo SchhSubgrupo,
                    schh.schh_fecha_inicio FechaInicio,
                    schh.schh_fecha_fin FechaFin,
                    cal.per_codigo PeriodoCodigo,
                    ----------------------------------------------------------------
                    schh.schh_esp_codigo_anterior EspAnteriorCodigo,
                    espAnt.esp_nombre EspNombreAnterior,
                    espAnt.esp_nombre_corto EspNombreCortoAnterior,
                    espAnt.esp_descripcion EspDescripcionAnterior,
                    
                    diaAnt.dia_codigo DiaAntCodigo,
                    diaAnt.dia_nombre DiaAntNombre,

                    hraAnt.hra_codigo HraAntCodigo,
                    hraAnt.hra_inicio HraAntInicio,
                    hraAnt.hra_fin HraAntFin,

                    uapAnterior.uap_codigo UapAntCodigo,
                    perAnterior.per_nombre PerAntNombre,
                    perAnterior.per_apellido PerAntApellido,
                    ----------------------------------------------------------------
                    schh.schh_esp_codigo_nuevo EspNuevoCodigo,
                    espNuevo.esp_nombre EspNombreNuevo,
                    espNuevo.esp_nombre_corto EspNombreCortoNuevo,
                    espNuevo.esp_descripcion EspDescripcionNuevo,

                    diaNuevo.dia_codigo DiaNuevoCodigo,
                    diaNuevo.dia_nombre DiaNuevoNombre,

                    hraNuevo.hra_codigo HraNuevoCodigo,
                    hraNuevo.hra_inicio HraNuevoInicio,
                    hraNuevo.hra_fin HraNuevoFin,

                    uapNuevo.uap_codigo UapNuevoCodigo,
                    perNuevo.per_nombre PerNuevoNombre,
                    perNuevo.per_apellido PerNuevoApellido,

                    CONVERT(varchar, schh.schh_subgrupo) +  CONVERT(varchar, diaAnt.dia_codigo) +  CONVERT(varchar, hraAnt.hra_codigo) +  CONVERT(varchar, uapAnterior.uap_codigo) id

                FROM
                    programacionacademica.solicitud_cambio_horario_horario schh

                INNER JOIN dia diaAnt ON diaAnt.dia_codigo = schh.schh_dia_codigo_anterior
                INNER JOIN hora hraAnt ON hraAnt.hra_codigo = schh.schh_hra_codigo_anterior
                INNER JOIN uaa_personal uapAnterior ON uapAnterior.uap_codigo = schh.schh_uap_codigo_anterior
                INNER JOIN persona perAnterior ON perAnterior.per_codigo = uapAnterior.per_codigo

                INNER JOIN dia diaNuevo ON diaNuevo.dia_codigo = schh.schh_dia_codigo_nuevo
                INNER JOIN hora hraNuevo ON hraNuevo.hra_codigo = schh.schh_hra_codigo_nuevo

                INNER JOIN espacio espAnt ON espAnt.esp_codigo = schh.schh_esp_codigo_anterior
                LEFT JOIN espacio espNuevo ON espNuevo.esp_codigo = schh.schh_esp_codigo_nuevo

                LEFT JOIN uaa_personal uapNuevo ON uapNuevo.uap_codigo = schh.schh_uap_codigo_nuevo
                LEFT JOIN persona perNuevo ON perNuevo.per_codigo = uapNuevo.per_codigo

                INNER JOIN programacionacademica.solicitud_cambio_horario sch ON sch.sch_codigo = schh.sch_codigo
                INNER JOIN curso cur ON cur.cur_codigo = sch.cur_codigo
                INNER JOIN calendario cal ON cal.cal_codigo = cur.cal_codigo

                WHERE
                    schh.sch_codigo = {$SchCodigo}
                    AND schh.schh_estado != 0
                ORDER BY schh.schh_subgrupo, schh.schh_dia_codigo_anterior, schh.schh_hra_codigo_anterior ASC
            ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["mensaje"] = "No se pudo realizar la consulta del horario de la solicitude {$SchCodigo}.";
            $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
            return $this->errorConsultarBd;
        }

        $horario = $this->cnx->json;

        return array(
            "resultado" => true,
            "mensaje" => "Horario de la solicitud consultado correctamente.",
            "data" => $horario,
            "count" => count($this->cnx->json)
        );
    }

    // Inicio eliminarHorarioSolicitud
    // Permite eliminar un horario especifico de una solicitud
    public function eliminarHorarioSolicitud($obj)
    {
        //Validaciones
        if (!isset($obj->SchCodigo) || !is_numeric($obj->SchCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar una solicitud.",
                "consola" => "El codigo de la solicitud no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->SchhCodigo) || !is_numeric($obj->SchhCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar un horario de una solicitud.",
                "consola" => "El codigo del horario de la solicitud no es numérico o no se envio correctamente.",
            );
        }

        $SchCodigo = $obj->SchCodigo; // Contiene codigo de la solicitud
        $SchhCodigo = $obj->SchhCodigo; // Contiene codigo del horario de la solicitud

        $sql = "UPDATE programacionacademica.solicitud_cambio_horario_horario
            SET schh_estado = 0
            WHERE schh_codigo = {$SchhCodigo}
        ";

        if (!$this->cnx->sentencia($sql)) {
            $this->errorSentenciaBd["mensaje"] = "Error al eliminar el horario especifico de la solicitud {$SchCodigo}. 
                Recargue la página e intente de nuevo.";
            $this->errorSentenciaBd["consola"] = "Ha fallado el update del estado en el horario de la solicitud " . __LINE__ . ".";
            return $this->errorSentenciaBd;
        }

        return array(
            "resultado" => true,
            "mensaje" => "El horario se elimino correctamente."
        );
    }

    // Inicio guardarComentarios
    // Permite guardar comentarios a una solicitud
    public function guardarComentarios($obj, $tipo = "")
    {
        //Validaciones
        if (!isset($obj->SchCodigo) || !is_numeric($obj->SchCodigo)) {
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

        $SchCodigo = $obj->SchCodigo; //Contiene el codigo de la solicitud
        $mensajeComentario = $obj->mensajeComentario; //Contiene el mensaje del comentario
        $UsuCodigo = $_SESSION['pacademica']['datosVinculacionUsuario']['usuarioCodigo']; //Contiene el codigo de usuario
        $obj->UsuCodigo = $UsuCodigo; //
        $FechaCreacion = FechaSqlServer::nowIso8601();

        $sql = "INSERT INTO programacionacademica.solicitud_cambio_horario_comentario(
            sch_codigo,
            schc_comentario,
            usu_codigo,
            schc_fecha_creacion
        )
        VALUES(
            {$SchCodigo},
            '{$mensajeComentario}',
            {$UsuCodigo},
            '{$FechaCreacion}'
        )";

        if (!$this->cnx->sentencia($sql)) {
            $this->errorSentenciaBd["mensaje"] = "Error al agregar el comentario a la solicitud. 
                Recargue la página e intente de nuevo.";
            $this->errorSentenciaBd["consola"] = "Ha fallado el insert del comentario a la solicitud " . __LINE__ . ".";
            $this->errorSentenciaBd["sql"] = $sql;
            return $this->errorSentenciaBd;
        }

        if ($tipo == "") {
            $envioCorreo = self::enviarNotificacion($obj, 'Comentario');
        }

        return array(
            "resultado" => true,
            "mensaje" => "El comentario se agrego correctamente.",
            "email" => $envioCorreo
        );
    }

    // Inicio consultarComentarios
    // Permite consultar los comentarios de una solicitud
    public function consultarComentarios($obj)
    {
        // Validamos las variables recibidas que exista y que sea numerico
        if (!isset($obj->SchCodigo) || !is_numeric($obj->SchCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo de la solicitud.",
                "consola" => "El codigo de la solicitud no viene o no es numerico, " . $obj->SchCodigo,
            );
        }

        $SchCodigo = $obj->SchCodigo; // Contiene el codigo de la solicitud

        $sql = "SELECT 
                per.per_nombre + ' ' + per.per_apellido PerNombreApellido,
                schc.schc_comentario SchcComentario,
                CONVERT(varchar(19), schc.schc_fecha_creacion, 120) SchcFechaCreacion
            FROM
                programacionacademica.solicitud_cambio_horario_comentario schc
            INNER JOIN usuario_general usu ON usu.uid = schc.usu_codigo 
            INNER JOIN persona per ON per.per_codigo = usu.up
            WHERE 
                schc.sch_codigo = {$SchCodigo}
            ORDER BY schc.schc_fecha_creacion DESC
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

    // Inicio consularSolicitudes
    // Permite consultar las solicitudes de un periodo seleccionado
    public function consularSolicitudes($obj)
    {
        // Validamos las variables recibidas que exista y que sea numerico
        if (!isset($obj->PerCodigo) || !is_numeric($obj->PerCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo del periodo.",
                "consola" => "El codigo del periodo no viene o no es numerico, " . $obj->PerCodigo,
            );
        }

        $PerCodigo = $obj->PerCodigo; //Contiene el codigo del periodo
        $UsuCodigo = $_SESSION["pacademica"]["datosVinculacionUsuario"]["usuarioCodigo"]; // Contiene el codigo del usuario logueado
        $administrador = $_SESSION["pacademica"]["datosVinculacionUsuario"]["Administrador"]; // Contiene si es administrador
        $usuariosVinculados = array();
        if (isset($_SESSION["pacademica"]["datosVinculacionUsuario"]["usuariosVinculados"])) {
            $usuarios = $_SESSION["pacademica"]["datosVinculacionUsuario"]["usuariosVinculados"]; // Contiene los usuarios vinculados
            foreach ($usuarios as $usuario) {
                $usuariosVinculados[] = $usuario["UsuCodigo"];
            }
        }
        $usuariosVinculados[] = $UsuCodigo; // Agregamos el usuario actual a la lista de usuarios vinculados
        $queryUsuarios = "";
        if (!$administrador) {
            $queryUsuarios = "WHERE sch.usu_codigo IN (" . implode(",", $usuariosVinculados) . ")";
        }

        $sql = "SELECT
                sch.sch_codigo SchCodigo,
                sch.sch_estado SchEstado,
                sch.sch_fecha_creacion SchFechaCreacion,
                sch.sch_espacio_deportivo EspDeportivo,
                sch.sch_cambio_docente CambioDocente,
                sch.sch_cambio_semanas CambioSemanas,
                sed.sed_codigo SedCodigo,
                sed.sed_nombre SedNombre,
                cur.cur_codigo CurCodigo,
                cur.cur_cupo CurCupo,
                cur.tic_codigo TicCodigo,
                cur.cur_semanas CurSemanas,
                asi.asi_codigo AsiCodigo,
                asi.asi_nombre AsiNombre,
                asi.asi_nombre_corto AsiNombreCorto,
                uaa.uaa_codigo UaaCodigo,
                uaa.uaa_nombre_corto UaaNombreCorto,
                per.per_nombre + ' ' + per.per_apellido UsuNombreApellido,
                cal.cal_nombre CalNombre,
                (
                    SELECT COUNT(mac.mac_codigo) total FROM matricula_curso mac WHERE mac.cur_codigo = cur.cur_codigo AND mac.maa_codigo IN (1,2)
                ) TotalMatriculados

            FROM programacionacademica.solicitud_cambio_horario sch
            INNER JOIN curso cur ON cur.cur_codigo = sch.cur_codigo
            INNER JOIN sede sed ON sed.sed_codigo = cur.sed_codigo
            INNER JOIN calendario cal ON cal.cal_codigo = cur.cal_codigo AND cal.per_codigo = {$PerCodigo}
            INNER JOIN asignatura asi ON asi.asi_codigo = cur.asi_codigo
            INNER JOIN uaa ON uaa.uaa_codigo = sch.uaa_codigo
            INNER JOIN usuario_general usu ON usu.uid = sch.usu_codigo 
            INNER JOIN persona per ON per.per_codigo = usu.up
                {$queryUsuarios}
            ORDER BY sch.sch_codigo DESC, sch.sch_estado ASC
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["mensaje"] = "No se pudo realizar la consulta de las solicitudes de cambio de horario.";
            $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
            return $this->errorConsultarBd;
        }

        $solicitudes = $this->cnx->json;

        // Consultamos el horario nuevo de cada solicitud
        foreach ($solicitudes as &$solicitud) {

            $sql = "SELECT
                    schh.schh_codigo SchhCodigo,
                    schh.sch_codigo SchCodigo,
                    schh.schh_estado SchhEstado,
                    schh.schh_subgrupo SchhSubgrupo,
                    schh.schh_fecha_inicio FechaInicio,
                    schh.schh_fecha_fin FechaFin,
                    ----------------------------------------------------------------
                    schh.schh_esp_codigo_anterior EspAntCodigo,
                    espant.esp_nombre EspAntNombre,
                    espant.esp_nombre_corto EspAntNombreCorto,
                    espant.esp_descripcion EspAntDescripcion,
                    diaAnt.dia_codigo DiaAntCodigo,
                    diaAnt.dia_nombre DiaAntNombre,
                    hraAnt.hra_codigo HraAntCodigo,
                    hraAnt.hra_inicio HraAntInicio,
                    hraAnt.hra_fin HraAntFin,
                    uapAnterior.uap_codigo UapAntCodigo,
                    perAnterior.per_nombre PerAntNombre,
                    perAnterior.per_apellido PerAntApellido,
                    ---------------------------------------------------------------- 
                    schh.schh_esp_codigo_nuevo EspNuevoCodigo,
                    esp.esp_nombre EspNombre,
                    esp.esp_nombre_corto EspNombreCorto,
                    esp.esp_descripcion EspDescripcion,
                    diaNuevo.dia_codigo DiaNuevoCodigo,
                    diaNuevo.dia_nombre DiaNuevoNombre,
                    hraNuevo.hra_codigo HraNuevoCodigo,
                    hraNuevo.hra_inicio HraNuevoInicio,
                    hraNuevo.hra_fin HraNuevoFin,
                    uapNuevo.uap_codigo UapNuevoCodigo,
                    perNuevo.per_nombre PerNuevoNombre,
                    perNuevo.per_apellido PerNuevoApellido,
                    CONVERT(varchar, schh.schh_subgrupo) +  CONVERT(varchar, diaAnt.dia_codigo) +  CONVERT(varchar, hraAnt.hra_codigo) +  CONVERT(varchar, uapAnterior.uap_codigo) id

                FROM
                    programacionacademica.solicitud_cambio_horario_horario schh

                INNER JOIN dia diaAnt ON diaAnt.dia_codigo = schh.schh_dia_codigo_anterior
                INNER JOIN hora hraAnt ON hraAnt.hra_codigo = schh.schh_hra_codigo_anterior
                INNER JOIN uaa_personal uapAnterior ON uapAnterior.uap_codigo = schh.schh_uap_codigo_anterior
                INNER JOIN persona perAnterior ON perAnterior.per_codigo = uapAnterior.per_codigo
                
                LEFT JOIN uaa_personal uapNuevo ON uapNuevo.uap_codigo = schh.schh_uap_codigo_nuevo
                LEFT JOIN persona perNuevo ON perNuevo.per_codigo = uapNuevo.per_codigo

                INNER JOIN dia diaNuevo ON diaNuevo.dia_codigo = schh.schh_dia_codigo_nuevo
                INNER JOIN hora hraNuevo ON hraNuevo.hra_codigo = schh.schh_hra_codigo_nuevo
                LEFT JOIN espacio espant ON espant.esp_codigo = schh.schh_esp_codigo_anterior 

                LEFT JOIN espacio esp ON esp.esp_codigo = schh.schh_esp_codigo_nuevo

                WHERE
                    schh.sch_codigo = {$solicitud['SchCodigo']}
                    AND schh.schh_estado != 0
                ORDER BY schh.schh_subgrupo, schh.schh_dia_codigo_anterior, schh.schh_hra_codigo_anterior ASC
            ";

            if (!$this->cnx->consultar($sql)) {
                $this->errorConsultarBd["mensaje"] = "No se pudo realizar la consulta de las solicitudes de cambio de horario.";
                $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
                return $this->errorConsultarBd;
            }
            $horario = $this->cnx->json;
            $solicitud["Horario"] = $horario; // Asignamos al obj el horario de la solicitud
        }

        return array(
            "resultado" => true,
            "mensaje" => "Solicitudes de cambio de horario consultadas correctamente.",
            "data" => $solicitudes
        );
    }

    // Inicio crearSolicitud
    // Permite crear una soliciud de cambio de horario.
    public function crearSolicitud($obj)
    {
        if (!isset($obj->CurCodigo) || !is_numeric($obj->CurCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el código del curso.",
                "consola" => "El código del curso no viene o no es numerico, " . $obj->CurCodigo,
            );
        }
        if (!isset($obj->TicCodigo) || !is_numeric($obj->TicCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio la modalidad del curso.",
                "consola" => "El código de la modalidad del curso no viene o no es numerico, " . $obj->CurCodigo,
            );
        }
        if (!isset($obj->EspDeportivo) || !is_numeric($obj->EspDeportivo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se ha seleccionado si se solicita un espacio deportivo.",
                "consola" => "El código boolean de espacio deportivo no viene o no es numerico, " . $obj->EspDeportivo,
            );
        }
        if (!isset($obj->NuevoHorario) || count($obj->NuevoHorario) <= 0) {
            return array(
                "resultado" => false,
                "mensaje" => "No se encontro cambios de horario.",
                "consola" => "No se encontraron cambios de horario para ese curso.",
            );
        }

        $CurCodigo = $obj->CurCodigo; // Contiene el codigo del curso
        $TicCodigo = $obj->TicCodigo; // Contiene el codigo de la modalidad del curso (2 = Virtual)
        $EspDeportivo = intval($obj->EspDeportivo); // Contiene si es espacio deportivo (1) o no (0).
        $NuevoHorario = $obj->NuevoHorario; // Contiene los cambios de horario.
        if (!isset($NuevoHorario[0]->UaaCodigo) || !is_numeric($NuevoHorario[0]->UaaCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se encontrÃ³ la unidad acadÃ©mica del horario seleccionado.",
                "consola" => "El horario nuevo no contiene una UAA valida.",
            );
        }
        $UaaCodigo = $NuevoHorario[0]->UaaCodigo; // Contiene la primera unidad del horario.
        $CambioDocente = $NuevoHorario[0]->NuevoDocente; // Contiene la opcion si es nuevo docente
        $UsuCodigo = $_SESSION["pacademica"]["datosVinculacionUsuario"]["usuarioCodigo"]; // Contiene el codigo del usuario logueado
        $GruCodigo = $_SESSION["pacademica"]["datosVinculacionUsuario"]["grupoCodigo"]; // Contiene el codigo del grupo del usuario logueado
        $Administrador = intval($_SESSION["pacademica"]["datosVinculacionUsuario"]["Administrador"]); // Contiene si es administrador (1) o no (0)
        $FechaHoraActual = FechaSqlServer::nowIso8601(); // Contiene la fecha y hora actual.
        $FechaHoraActualSql = FechaSqlServer::toSqlDateTime2($FechaHoraActual, false);
        if ($FechaHoraActualSql === false) {
            return array(
                "resultado" => false,
                "mensaje" => "Formato de fecha inválido para crear solicitud.",
                "consola" => "No se pudo preparar la fecha actual ({$FechaHoraActual}) para SQL Server.",
            );
        }
        $EstadoInicial = ''; // Estado inicial vacio para error

        if ($Administrador != 1) {
            $periodoCurso = $this->consultarPeriodoCurso($CurCodigo);
            if (!$periodoCurso["resultado"]) {
                return $periodoCurso;
            }

            $validacionApertura = $this->validarAperturaActivaSolicitud(
                2,
                intval($UaaCodigo),
                $periodoCurso["PeriodoCodigo"],
                $FechaHoraActualSql,
                "CAMBIO DE HORARIO"
            );

            if (!$validacionApertura["resultado"]) {
                return $validacionApertura;
            }
        }
        // Verificacion de se le pueden agregar horas en caso de ser docente nuevo
        if ($CambioDocente == "1") {
            $cantidadNuevasHoras = count($NuevoHorario); // Cantidad de horas nuevas.
            $infoHoras = array(
                "UapCodigo" => $NuevoHorario[0]->VinculacionNuevoDocente->UapCodigo,
                "CurCodigo" => $CurCodigo,
                "SubGrupo" => $NuevoHorario[0]->EsoSubGrupo,
                "CantidadHorasNuevas" => $cantidadNuevasHoras,
                "UaaCodigo" => $UaaCodigo
            );
            $infoHorasObj = (object) $infoHoras;
            $validacionAgendaDocente = self::validarHorasDocente($infoHorasObj);
            if (!isset($validacionAgendaDocente["resultado"]) || !$validacionAgendaDocente["resultado"]) {
                return array(
                    "resultado" => false,
                    "mensaje" => "No se le es permitido adicionar {$cantidadNuevasHoras} horas semanales, por favor verificar la agenda."
                );
            }
        } else {
            $CambioDocente = 0;
        }

        // TODO: Check horario por semanas
        $CambioPorSemanas = 0;
        // El estado inicial es solicitado pero si es virtual debe aprobarse de una vez por planta
        if ($GruCodigo == $_SESSION['pacademica']['ROLES']['SECRETARIA']) { // Si el usuario es secretario de programa debe solicitar primero aprobacion del jefe de programa.
            $EstadoInicial = $this->estadosSolicitud['Solicitado Jefe Programa'];
        }
        if ($GruCodigo == $_SESSION['pacademica']['ROLES']['JEFE_PROGRAMA'] || $GruCodigo == $_SESSION['pacademica']['ROLES']['ADMINISTRADOR']) { // Si el usuario es jefe de programa o administrador si se envia inmediatamente
            $EstadoInicial = $TicCodigo != 2 ? $this->estadosSolicitud['Solicitado'] : $this->estadosSolicitud['Aprobado Curso Virtual'];
        }

        if ($EstadoInicial == "") {
            return array(
                "resultado" => false,
                "mensaje" => "No se logro asignar un estado inicial de la solicitud.",
                "consola" => "No se logro asignar un estado inicial de la solicitud = {$EstadoInicial}"
            );
        }


        $this->cnx->Sentencia("BEGIN TRAN");

        $sql = "INSERT INTO programacionacademica.solicitud_cambio_horario (
                cur_codigo,
                usu_codigo,
                uaa_codigo,
                sch_espacio_deportivo,
                sch_cambio_docente,
                sch_cambio_semanas,
                sch_estado,
                sch_fecha_creacion
            ) VALUES (
                {$CurCodigo},
                {$UsuCodigo},
                {$UaaCodigo},
                {$EspDeportivo},
                {$CambioDocente},
                {$CambioPorSemanas},
                {$EstadoInicial},
                {$FechaHoraActualSql}
            )
        ";

        // ESTE ERROR PUEDE SER POR FALTA DE PERMISOS DEL USUARIO QUE ESTÁ GENERANDO LA SOLICITUD EN LA BASE DE DATOS (GRUPO)
        // SqlSrvManag -> BD-> Security 
        if (!$this->cnx->sentencia($sql)) {
            $cnxVars = get_object_vars($this->cnx);
            $dbError = isset($cnxVars['mjeError']) ? $cnxVars['mjeError'] : "Sin detalle en cls_config::sentencia";
            $this->errorSentenciaBd["mensaje"] = "Error al crear la solicitud de cambio de horario.";
            $this->errorSentenciaBd["consola"] = "Ha fallado la creacion de la solicitud " . __LINE__ . ". Error: {$dbError}";
            $this->errorSentenciaBd["sql"] = $sql;
            $this->cnx->Sentencia("ROLLBACK TRAN"); //Se realiza un rollback si se encuentra un error
            return $this->errorSentenciaBd;
        }

        // Obtenemos la ultima solicitud creada por el usuario
        $sql = "SELECT TOP 1
                sch.sch_codigo SchCodigo 
            FROM 
                programacionacademica.solicitud_cambio_horario sch
            WHERE 
                sch.usu_codigo = {$UsuCodigo}
            ORDER BY
                sch.sch_codigo DESC
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["mensaje"] = "No se pudo realizar la consulta de de la solicitud creada.";
            $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
            $this->cnx->Sentencia("ROLLBACK TRAN"); //Se realiza un rollback si se encuentra un error
            return $this->errorConsultarBd;
        }

        $SchCodigo = $this->cnx->json; // Contiene el codigo del la ultima solicitud creada.

        // Recorremos el horario nuevo.

        foreach ($NuevoHorario as $horario) {
            // Verificamos si viene un docente nuevo
            $queryCampoNuevoDocente = "";
            $queryValorNuevoDocente = "";
            if (isset($horario->VinculacionNuevoDocente) && !empty((array)$horario->VinculacionNuevoDocente) ) {
                $queryCampoNuevoDocente = "schh_uap_codigo_nuevo,";
                $queryValorNuevoDocente = $horario->VinculacionNuevoDocente->UapCodigo . ",";
            }

            // Guardamos el nuevo horario en la solicitud creada.
            if ($TicCodigo != 2) {
                $sql = "INSERT INTO programacionacademica.solicitud_cambio_horario_horario (
                        sch_codigo,
                        schh_estado,
                        schh_subgrupo,
                        schh_dia_codigo_anterior,
                        schh_hra_codigo_anterior,
                        schh_esp_codigo_anterior,
                        schh_uap_codigo_anterior,
                        schh_dia_codigo_nuevo,
                        schh_hra_codigo_nuevo,
                        {$queryCampoNuevoDocente}
                        schh_fecha_inicio,
                        schh_fecha_fin
                    ) VALUES (
                        {$SchCodigo[0]['SchCodigo']},
                        1,
                        '{$horario->EsoSubGrupo}',
                        {$horario->DiaCodigo},
                        {$horario->HraCodigo},
                        {$horario->EspCodigo},
                        {$horario->UapCodigo},
                        {$horario->diaNuevo->DiaCodigo},
                        {$horario->horaNuevo->HraCodigo},
                        {$queryValorNuevoDocente}
                        '{$horario->fechaInicial}',
                        '{$horario->fechaFinal}'
                    )
                ";
            } else {
                $sql = "INSERT INTO programacionacademica.solicitud_cambio_horario_horario (
                        sch_codigo,
                        schh_estado,
                        schh_subgrupo,
                        schh_dia_codigo_anterior,
                        schh_hra_codigo_anterior,
                        schh_esp_codigo_anterior,
                        schh_uap_codigo_anterior,
                        schh_dia_codigo_nuevo,
                        schh_hra_codigo_nuevo,
                        schh_esp_codigo_nuevo,
                        schh_fecha_inicio,
                        schh_fecha_fin
                    ) VALUES (
                        {$SchCodigo[0]['SchCodigo']},
                        1,
                        '{$horario->EsoSubGrupo}',
                        {$horario->DiaCodigo},
                        {$horario->HraCodigo},
                        {$horario->EspCodigo},
                        {$horario->UapCodigo},
                        {$horario->diaNuevo->DiaCodigo},
                        {$horario->horaNuevo->HraCodigo},
                        {$horario->EspCodigo},
                        '{$horario->fechaInicial}',
                        '{$horario->fechaFinal}'
                    )
                ";
            }
            // Verificamos que se guardara correctamente
            if (!$this->cnx->sentencia($sql)) {
                $this->errorSentenciaBd["mensaje"] = "Error al guardar el nuevo horario en la solicitud de cambio de horario: {$SchCodigo[0]['SchCodigo']}.";
                $this->errorSentenciaBd["consola"] = "Ha fallado la creacion del nuevo horario de la solicitud: {$SchCodigo[0]['SchCodigo']} " . __LINE__ . ".";
                $this->cnx->Sentencia("ROLLBACK TRAN"); //Se realiza un rollback si se encuentra un error
                return $this->errorSentenciaBd;
            }
        }

        $this->cnx->Sentencia("COMMIT TRAN");
        $obj->SchCodigo = $SchCodigo[0]['SchCodigo'];
        // El estado inicial es solicitado pero si es virtual debe aprobarse de una vez por planta
        if ($GruCodigo == 68) { // Si el usuario es secretario de programa debe solicitar primero aprobacion del jefe de programa.
            $envioCorreo = self::enviarNotificacion($obj, 'SolicitadoJefePrograma');
        } else {
            $envioCorreo = self::enviarNotificacion($obj, $TicCodigo != 2 ? 'Creacion' : 'AprobadoVirtual');
        }

        return array(
            "resultado" => true,
            "mensaje" => "La solicitud de cambio de horario se creo correctamente.",
            "email" => $envioCorreo,
        );
    }

    // Inicio function consultarHorarioNuevo
    // Permite verificar si el docente y los estudiantes presentan cruce con el nuevo horario.
    public function verificarHorarioNuevo($obj)
    {

        if (!isset($obj->CurCodigo) || !is_numeric($obj->CurCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el código del curso.",
                "consola" => "El código del curso no viene o no es numerico, " . $obj->CurCodigo,
            );
        }
        if (!isset($obj->EsoSubGrupo) || !is_numeric($obj->EsoSubGrupo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el código del subgrupo.",
                "consola" => "El código del subgrupo no viene o no es numerico, " . $obj->EsoSubGrupo,
            );
        }
        if (!isset($obj->CurSemanas) || !is_numeric($obj->CurSemanas)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se enviaron las semanas del curso.",
                "consola" => "La cantidad de semana no viene o no es numerico, " . $obj->CurSemanas,
            );
        }
        if (!isset($obj->UapCodigo) || !is_numeric($obj->UapCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el código de vinculacion del docente.",
                "consola" => "El código de vinculacion del docente no viene o no es numerico, " . $obj->UapCodigo,
            );
        }
        if (!isset($obj->PeriodoCodigo) || !is_numeric($obj->PeriodoCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el código del periodo.",
                "consola" => "El código del periodo no viene o no es numerico, " . $obj->PeriodoCodigo,
            );
        }
        if (!isset($obj->diaAnterior) || !is_numeric($obj->diaAnterior)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el dia del horario actual.",
                "consola" => "El código del dia anterior no viene o no es numerico, " . $obj->diaAnterior,
            );
        }
        if (!isset($obj->horaAnterior) || !is_numeric($obj->horaAnterior)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio la hora del horario actual.",
                "consola" => "El código de la hora anterior no viene o no es numerico, " . $obj->horaAnterior,
            );
        }
        // SchCodigo solo llega desde el formulario de edicion. En creacion la solicitud aun no existe.
        if (isset($obj->SchCodigo) && $obj->SchCodigo !== "" && !is_numeric($obj->SchCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "El código de la solicitud que se esta editando no es valido.",
                "consola" => "El código de la solicitud no es numerico, " . $obj->SchCodigo,
            );
        }
        if (!isset($obj->diaNuevo) || count($obj->diaNuevo) <= 0) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el dia del nuevo Horario.",
                "consola" => "El array del dia del nuevo horario no viene o no es un array, ",
            );
        }
        if (!isset($obj->horaNuevo) || count($obj->horaNuevo) <= 0) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio la hora del nuevo Horario.",
                "consola" => "El array de la hora del nuevo horario no viene o no es un array, ",
            );
        }

        // No se usa cambioDocente: el frontend ya envia en UapCodigo la vinculacion del docente que
        // quedaria en el horario nuevo (el docente nuevo si hubo cambio, el actual si no).
        $CurCodigo = $obj->CurCodigo;   // CurCodigo: "182723",
        $EsoSubGrupo = $obj->EsoSubGrupo;   // EsoSubGrupo: "00",
        $CurSemanas = $obj->CurSemanas; // CurSemanas: "16",
        $UapCodigo = $obj->UapCodigo;   // UapCodigo: "13257",
        $diaAnterior = $obj->diaAnterior;
        $horaAnterior = $obj->horaAnterior;
        $diaNuevo = $obj->diaNuevo->DiaCodigo;   // diaNuevo: {0: "3", 1: "Miercoles ", DiaCodigo: "3", DiaNombre: "Miercoles "}
        $horaNuevo = $obj->horaNuevo->HraCodigo;   // horaNuevo: {0: "3", 1: "03", 2: " 8:00AM", 3: " 8:45AM ", HraCodigo: "3", HraNombre: "03", HraInicio: " 8:00AM",…}
        $PeriodoCodigo = $obj->PeriodoCodigo; // PeriodoCodigo: "126"
        $SchCodigo = isset($obj->SchCodigo) && is_numeric($obj->SchCodigo) ? $obj->SchCodigo : null; // Solo en edicion
        $cruceDocente = $obj->cruceDocente;   // cruceDocente: true,
        $cruceEstudiantes = $obj->cruceEstudiantes;   // cruceEstudiantes: true,
        $solicitudExistente = false; // Agrupa las dos validaciones siguientes para el mensaje unico del frontend.
        $mensajeSolicitudExistente = "";
        $solicitudDocenteHorario = false; // El docente ya tiene una solicitud en tramite hacia el horario destino en el periodo.
        $mensajeSolicitudDocenteHorario = "";
        $solicitudDuplicada = false; // Ya existe una solicitud en tramite para el mismo curso, subgrupo y horario de origen.
        $mensajeSolicitudDuplicada = "";
        $mensajeCruceDocente = "";
        $mensajeCruceEstudiante = "";
        $estudiantesCruce = array();
        $cursosCruceDocente = array();

        //Asigna los datos no vengan dentro de un array en el objeto
        if (!isset($obj->diaNuevo->DiaCodigo)){
            $diaNuevo = $obj->diaNuevo;
        }
        if (!isset($obj->horaNuevo->HraCodigo)){
            $horaNuevo = $obj->horaNuevo;
        }

        // Validacion 1: el docente no puede tener otra solicitud en tramite del MISMO PERIODO que ya lo
        // deje en el horario destino seleccionado, asi sea para un curso distinto (se cruzarian entre si).
        // En edicion se excluye la propia solicitud para que no se bloquee con sus horarios ya guardados.
        $sql = self::construirSqlSolicitudDocenteEnHorarioNuevo($UapCodigo, $diaNuevo, $horaNuevo, $PeriodoCodigo, $SchCodigo);

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["mensaje"] = "No se pudo realizar la consulta de solicitudes en tramite con el mismo horario y docente.";
            $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
            return $this->errorConsultarBd;
        }

        $verificarHorarioActivo = $this->cnx->json;

        if (count($verificarHorarioActivo) > 0 && $verificarHorarioActivo[0]['ExistenHoras'] > 0) {
            $solicitudDocenteHorario = true;
            $mensajeSolicitudDocenteHorario = "El docente ya tiene una solicitud de cambio de horario en tramite en el periodo que lo ubica en el horario seleccionado, por favor verificar.";
        }

        // Validacion 2: no puede existir otra solicitud en tramite del mismo periodo que ya pida mover
        // exactamente el mismo horario de origen del mismo curso y subgrupo (duplicado).
        $sql = self::construirSqlSolicitudDuplicadaCurso($CurCodigo, $EsoSubGrupo, $diaAnterior, $horaAnterior, $PeriodoCodigo);

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["mensaje"] = "No se pudo realizar la consulta de solicitudes duplicadas del curso {$CurCodigo}.";
            $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
            return $this->errorConsultarBd;
        }

        $verificarSolicitudDuplicada = $this->cnx->json;

        if (count($verificarSolicitudDuplicada) > 0 && $verificarSolicitudDuplicada[0]['ExistenHoras'] > 0) {
            $solicitudDuplicada = true;
            $mensajeSolicitudDuplicada = "Ya existe una solicitud de cambio de horario en tramite para el curso {$CurCodigo}, subgrupo {$EsoSubGrupo} y el horario que intenta cambiar, por favor verificar.";
        }

        // solicitudExistente agrupa ambas validaciones para el frontend, que muestra un unico mensaje.
        $solicitudExistente = $solicitudDocenteHorario || $solicitudDuplicada;
        $mensajeSolicitudExistente = trim($mensajeSolicitudDuplicada . " " . $mensajeSolicitudDocenteHorario);

        // Verificamos si el docente presenta cruce en el nuevo horario
        $sql = "SELECT 
                eso.eso_actividad CurCodigo,
                asi.asi_codigo AsiCodigo,
                asi.asi_nombre_corto AsiNombreCorto,
                asi.asi_nombre AsiNombre,
                esp.esp_codigo EspCodigo,
                esp.esp_nombre EspNombre,
                esp.esp_nombre_corto EspNombreCorto
            from espacio_ocupacion eso
            inner join curso cur on cur.cur_codigo = eso.eso_actividad
            inner join asignatura asi on asi.asi_codigo = cur.asi_codigo
            inner join espacio esp on esp.esp_codigo = eso.esp_codigo
            inner join calendario cal on cal.cal_codigo = cur.cal_codigo and cal.per_codigo = {$PeriodoCodigo}
            where eso.uap_codigo = {$UapCodigo} and eso.dia_codigo = {$diaNuevo} and eso.hra_codigo = {$horaNuevo}
            and cur.cur_estado = 1 -- espacio_ocupacion conserva los cursos eliminados y reportarian un cruce inexistente
            group by eso.dia_codigo, eso.hra_codigo, eso.eso_actividad, asi.asi_codigo, asi.asi_nombre_corto, asi.asi_nombre, esp.esp_codigo, esp.esp_nombre, esp.esp_nombre_corto
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["mensaje"] = "No se pudo realizar la consulta de cruce de horario del docente.";
            $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
            return $this->errorConsultarBd;
        }

        $verificacionCruceDocente = $this->cnx->json;

        if (count($verificacionCruceDocente) > 0) { // Se verifica que tenga cursos con cruce de horario
            // Se acumulan todos los cursos en cruce: antes el mensaje se sobrescribia en cada vuelta
            // y con varios cursos solo se alcanzaba a reportar el ultimo.
            foreach ($verificacionCruceDocente as $cursoCruce) {
                $cursosCruceDocente[] = "{$cursoCruce['CurCodigo']} - {$cursoCruce['AsiCodigo']}. {$cursoCruce['AsiNombreCorto']} - {$cursoCruce['AsiNombre']}";
            }
            $mensajeCruceDocente = count($cursosCruceDocente) == 1
                ? "El nuevo horario seleccionado presenta cruce de horario con el siguiente curso: "
                : "El nuevo horario seleccionado presenta cruce de horario con los siguientes cursos: ";
            $mensajeCruceDocente .= implode(", ", $cursosCruceDocente);
        } else {
            // En caso de no encontrar registros de cruce cambiamos la variable a false y estatblecemos mensaje de estado ok.
            $cruceDocente = false;
            $mensajeCruceDocente = "No se encontro cruce de horario en el periodo para la vinculacion del docente.";
        }

        // Verificacion de cruce con estudiantes matriculados en el curso
        // 1. Obtener los estudiantes matriculados de un curso
        // El cruce del estudiante puede estar en CUALQUIER subgrupo del curso ajeno.
        // Solo acotamos los estudiantes AFECTADOS del curso que se cambia:
        // para teoria (00) aplican todos; para practica (01,02,...) solo ese subgrupo.
        $sqlSubgrupoEstudiantes = "";
        if (trim($EsoSubGrupo) != "00") {
            $sqlSubgrupoEstudiantes = "AND maci.mac_subgrupo = '{$EsoSubGrupo}'";
        }
        $sql = "SELECT
                mac.cur_codigo CurCodigo, 
                mac.mac_subgrupo MacSubgrupo, 
                asi.asi_codigo AsiCodigo, 
                asi.asi_nombre AsiNombre, 
                asi.asi_nombre_corto AsiNombreCorto
            from matricula_curso mac
            inner join espacio_ocupacion_total eso on eso.eso_actividad = mac.cur_codigo and eso.eso_subgrupo = mac.mac_subgrupo
            inner join curso cur on cur.cur_codigo = eso.eso_actividad
            inner join asignatura asi on asi.asi_codigo = cur.asi_codigo
            where
            eso.dia_codigo = {$diaNuevo}
            and eso.hra_codigo = {$horaNuevo}
            and mac.maa_codigo in (1,2)
            and mac.cur_codigo <> {$CurCodigo}
            and cur.cur_estado = 1 -- espacio_ocupacion_total conserva los cursos eliminados
            and mac.mat_codigo in (
                select maci.mat_codigo MatCodigo
                from matricula_curso maci
                where maci.cur_codigo = {$CurCodigo} and maci.maa_codigo in (1,2)
                {$sqlSubgrupoEstudiantes}
                group by maci.mat_codigo
            )
            group by mac.cur_codigo, mac.mac_subgrupo, eso.dia_codigo, eso.hra_codigo, asi.asi_codigo, asi.asi_nombre, asi.asi_nombre_corto
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["mensaje"] = "No se pudo realizar la consulta de cruce de horario de los estudiantes del curso {$CurCodigo}.";
            $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
            return $this->errorConsultarBd;
        }

        $verificacionCruceEstudiantes = $this->cnx->json;

        if (count($verificacionCruceEstudiantes) > 0) {
            error_log($verificacionCruceEstudiantes);
            foreach ($verificacionCruceEstudiantes as $cursoCruce) {
                $estudiantesCruce[] = "{$cursoCruce['CurCodigo']} ({$cursoCruce['MacSubgrupo']}) - {$cursoCruce['AsiCodigo']}. {$cursoCruce['AsiNombreCorto']} - {$cursoCruce['AsiNombre']}";
            }
            $mensajeCruceEstudiante = "Se encontro cruce de horario de estudiantes en los siguientes cursos: ";
            $mensajeCruceEstudiante .= implode(",", $estudiantesCruce);
            $cruceEstudiantes = true;
        } else {
            $cruceEstudiantes = false;
            $estudiantesCruce = [];
            $mensajeCruceEstudiante = "No se encontro cruce de horario en el periodo para los estudiantes del curso {$CurCodigo}.";
        }

        return  array(
            "resultado" => true,
            "cruceDocente" => $cruceDocente,
            "cruceEstudiantes" => $cruceEstudiantes,
            "mensajeCruceDocente" => $mensajeCruceDocente,
            "mensajeCruceEstudiante" => $mensajeCruceEstudiante,
            "estudiantesCruce" => $estudiantesCruce,
            "solicitudExistente" => $solicitudExistente,
            "mensajeSolicitudExistente" => $mensajeSolicitudExistente,
            "solicitudDocenteHorario" => $solicitudDocenteHorario,
            "mensajeSolicitudDocenteHorario" => $mensajeSolicitudDocenteHorario,
            "solicitudDuplicada" => $solicitudDuplicada,
            "mensajeSolicitudDuplicada" => $mensajeSolicitudDuplicada,
        );
    }

    // Inicio funcion consultarCursosProgramados
    // consulta los cursos programados por usuarios y periodo especifico.
    public function consultarCursosProgramados($obj)
    {

        // Validamos las variables recibidas que exista y que sea numerico
        if (!isset($obj->CurCodigo) || !is_numeric($obj->CurCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el código del curso.",
                "consola" => "El código del curso no viene o no es numerico, " . $obj->PerCodigo,
            );
        }
        if (!isset($obj->PerCodigo) || !is_numeric($obj->PerCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el código del periodo.",
                "consola" => "El código del periodo no viene o no es numerico, " . $obj->PerCodigo,
            );
        }

        // Parametros 
        $CurCodigo = $obj->CurCodigo; // Contiene el codigo del curso seleccionado
        $PerCodigo = $obj->PerCodigo; // Contiene el codigo del periodo seleccionado
        $administrador = $_SESSION["pacademica"]["datosVinculacionUsuario"]["Administrador"];
        $queryUsuariosVinculados = "";
        if ($administrador != "1") {
            $implodeUsuariosVinculados = implode(',', array_column($_SESSION['pacademica']['datosVinculacionUsuario']['usuariosVinculados'], 'UsuCodigo')); //Contiene el uid del usuario vinculados a las uaa unificadas.
            $queryUsuariosVinculados = "AND cur.usu_codigo IN ({$implodeUsuariosVinculados})";
        }

        // Obtenemos los cursos que tengan programacion academica
        $sql = "SELECT 
                cur.cur_codigo CurCodigo, 
                cur.uap_codigo UapCodigo, --Codigo de vinculacion uaa_persona.uap_codigo del coordinador del curso
                cur.asi_codigo AsiCodigo, 
                cur.sed_codigo SedCodigo, 
                cur.cal_codigo CalCodigo,
                cal.cal_nombre CalNombre, --Calendario al que se programa el curso
                cal.per_codigo PeriodoCodigo,
                cur.cur_grupo CurGrupo, 
                cur.cur_cupo CurCupo, --Cupo total del curso
                cur.cur_estado CurEstado, --1. activo, 0. eliminado
                cur.pla_codigo PlaCodigo, --Codigo del plan academico del curso.
                pla.pla_nombre PlaNombre, --Nombre del plan academico del curso.
                cut.cut_codigo CutCodigo, --Codigo del tipo curso. De momento solo se programa con 1. Normal
                cut.cut_nombre CutNombre, --Nombre del tipo curso.
                cur.cur_exclusivo CurExclusivo, --Define si un curso es exclusivo o no para su plan academico.
                sed.sed_nombre SedNombre, --Sede donde queda disponible el curso
                nuc.nuc_codigo NucCodigo,
                nuc.nuc_nombre NucNombre,
                asi.asi_nombre_corto AsiNombreCorto, 
                asi.asi_nombre AsiNombre, 
                asi.asi_creditos AsiCreditos, 
                asi.asi_creditos_teoria AsiCreditosTeoria, 
                asi.asi_creditos_practica AsiCreditosPractica, 
                per.per_nombre + ' ' + per.per_apellido as PerNombreApellido, --Docente coordinador
                per.per_codigo PerCodigo, --codigo de la persona del docente coordinador
                vin.vin_nombre VinNombre, --Vinculacion del docente coordinador
                vin.vin_codigo VinCodigo, --Codigo de vinculacion del docente coordinador
                uap.ded_codigo DedCodigo, --Codigo de dedicacion del docente
                uap.sed_codigo UapSedCodigo, --Codigo de  la sede de la vinculación del docente
                cur.cdp_codigo CdpCodigo, --?? Preguntar si se sigue usando o que mierdas
                cur.cur_semanas CurSemanas, --Duracion de semanas para el curso
                asi.car_codigo CarCodigo, --Codigo del caracter
                car.car_nombre CarNombre, --Nombre del caracter.
                tic.tic_codigo TicCodigo, --Modalidad 1. Presencial, 2. Apoyo virtual (b-Learning), 3. Mixto
                tic.tic_nombre TicNombre, --Modalidad 1. Presencial, 2. Apoyo virtual (b-Learning), 3. Mixto
                cur.cur_observaciones CurObservaciones,
                cur.cur_ampliacion_cupo CurAmpliacionCupo, --La ampliacion reserva cupo del cupo total, no amplia.
                cur.cur_notaparcial CurNotaParcial,
                tes.tes_codigo TesCodigo, --Calificacion
                tes.tes_nombre TesNombre, --Calificacion
                uaa.uaa_nombre_corto UaaNombreCorto, --Unidad dueña de la asignatura.
                uaa.uaa_codigo UaaCodigo, 
                cur.cur_url CurUrl, --Link de meet para clases virtuales
                cur.usu_codigo UsuCodigo,
                (
                    SELECT 
                        count(*) 
                    FROM 
                        matricula_curso mac with (nolock)
                    WHERE 
                        mac.cur_codigo = cur.cur_codigo AND 
                        mac.maa_codigo IN (1,2) --matricula_autorizacion 1. Adicion, 2.Normal (Solo cuenta las matriculas 'activas').
                ) TotalMatriculados
            FROM 
                curso cur with (nolock)
            INNER JOIN asignatura asi with (nolock) ON asi.asi_codigo = cur.asi_codigo
            INNER JOIN sede sed with (nolock) ON sed.sed_codigo = cur.sed_codigo
            LEFT JOIN nucleo nuc with (nolock) ON nuc.nuc_codigo = asi.nuc_codigo
            LEFT JOIN caracter car with (nolock) ON car.car_codigo = asi.car_codigo
            LEFT JOIN curso_tipo cut with (nolock) ON cut.cut_codigo = cur.cut_codigo
            LEFT JOIN plan_academico pla with (nolock) ON pla.pla_codigo = cur.pla_codigo
            LEFT JOIN uaa with (nolock) ON uaa.uaa_codigo = asi.uaa_codigo
            LEFT JOIN tipo_curso tic with (nolock) ON tic.tic_codigo = cur.tic_codigo
            LEFT JOIN tipo_escala tes with (nolock) ON tes.tes_codigo = cur.tes_codigo
            INNER JOIN uaa_personal uap with (nolock) ON uap.uap_codigo = cur.uap_codigo
            INNER JOIN vinculacion vin with (nolock) ON vin.vin_codigo = uap.vin_codigo
            INNER JOIN persona per with (nolock) ON per.per_codigo = uap.per_codigo
            INNER JOIN calendario cal with (nolock) ON cal.cal_codigo = cur.cal_codigo
            INNER JOIN periodo with (nolock) ON periodo.per_codigo = cal.per_codigo AND periodo.per_codigo = {$PerCodigo}
            WHERE 
                cur.cur_codigo = {$CurCodigo}
                {$queryUsuariosVinculados}
                AND cur.cur_estado = 1
            ORDER BY 
                cur.cur_codigo ASC,
                cur.cur_estado DESC
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["mensaje"] = "No se pudo realizar la consulta de cursos programados con horario.";
            $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
            return $this->errorConsultarBd;
        }

        $cursoDetalle = $this->cnx->json;

        if (count($cursoDetalle) <= 0) {
            return array(
                "resultado" => false,
                "mensaje" => "Curso no encontrado."
            );
        }

        $sql = "SELECT 
                        eso.eso_actividad CurCodigo,
                        eso.uaa_codigo UaaCodigo,
                        eso.esp_codigo EspCodigo, 
                        eso.uap_codigo UapCodigo,
                        eso.dia_codigo DiaCodigo, 
                        eso.hra_codigo HraCodigo,
                        eso.eso_subgrupo EsoSubGrupo,
                        per.per_nombre + ' ' + per.per_apellido NombreApellidoDocente,
                        CONVERT(char(10),min(eso.eso_fecha),23) EsoFechaInicio,
                        CONVERT(char(10),max(eso.eso_fecha),23) EsoFechaFin,  
                        (datediff(ww,min(eso.eso_fecha),max(eso.eso_fecha))+1) EsoSemanas,
                        dia.dia_nombre DiaNombre, 
                        hora.hra_nombre + '. ' + hora.hra_inicio + ' - ' + hora.hra_fin EsoHora,
                        esp.esp_nombre_corto  EspNombreCorto,
                        blo.blo_nombre BloNombre,
                        sus.sus_nombre SusNombre,
                        sed.sed_nombre SedNombre,
                        vin.vin_nombre VinNombre, 
                        ded.ded_nombre DedNombre,
                        ccs.cus_cupo CupoSubgrupo
                    from 
                        espacio_ocupacion eso with (nolock)
                    inner join uaa_personal uap with (nolock) on uap.uap_codigo = eso.uap_codigo
                    inner join persona per with (nolock) on per.per_codigo = uap.per_codigo
                    inner join dia with (nolock) on dia.dia_codigo = eso.dia_codigo 
                    inner join hora with (nolock) on hora.hra_codigo = eso.hra_codigo

                    inner join espacio esp with (nolock) on esp.esp_codigo = eso.esp_codigo
                    left join bloque blo with (nolock) on blo.blo_codigo = esp.blo_codigo
                    left join sub_sede sus with (nolock) on sus.sus_codigo = blo.sus_codigo
                    left join sede sed with (nolock) on sed.sed_codigo = sus.sed_codigo
                    
                    inner join vinculacion vin with (nolock) on vin.vin_codigo = uap.vin_codigo 
                    inner join dedicacion ded with (nolock) on ded.ded_codigo = uap.ded_codigo
                    left join curso_cupo_subgrupo ccs with (nolock) on eso.eso_actividad = ccs.cur_codigo and ccs.eso_subgrupo = eso.eso_subgrupo and ccs.cus_estado = 1
                    where 
                        eso.eso_actividad = {$cursoDetalle[0]['CurCodigo']}
                    group by 
                        eso.eso_actividad,
                        eso.uaa_codigo,
                        eso.esp_codigo, 
                        eso.uap_codigo, 
                        eso.dia_codigo,
                        eso.hra_codigo,
                        eso.eso_subgrupo,
                        per_nombre + ' ' + per_apellido,
                        dia.dia_nombre, 
                        hora.hra_nombre + '. ' + hora.hra_inicio + ' - ' + hora.hra_fin, 
                        esp.esp_nombre_corto,
                        vin.vin_nombre, 
                        ded.ded_nombre,
                        ccs.cus_cupo,
                        blo.blo_nombre,
                        sus.sus_nombre,
                        sed.sed_nombre
                    order by eso.eso_subgrupo, per.per_nombre + ' ' + per.per_apellido, eso.dia_codigo, eso.hra_codigo ASC
                ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["mensaje"] = "No se pudo consultar el horario del curso {$cursoDetalle[0]['CurCodigo']}.";
            $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
            return $this->errorConsultarBd;
        }

        $horarioCurso = $this->cnx->json;
        $cursoDetalle[0]['Horario'] = [];

        if (count($horarioCurso) > 0) {
            $cursoDetalle[0]['Horario'] = $horarioCurso;
        }

        return array(
            "resultado" => true,
            "mensaje" => "Cursos consultadas correctamente.",
            "data" => $cursoDetalle[0]
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
        $cantidad_horas_nuevas = $obj->CantidadHorasNuevas; //Contiene Cantidad de horas.
        $uaaProgramada = $obj->UaaCodigo; //Contiene Cantidad de horas.

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
        $total_horas_inv_tesis = 0; //total de horas proyecto de investigacion o direccion de tesis
        $total_horas_descarga = 0; //total de horas descarga academica
        $cantidad_horas_nuevas_total = 0; //total de horas nuevas, se usa para calcular.
        $total_horas_novedad = 0; //total de horas de novedad se usa solo para de planta  o nombramiento ocacional
        $total_horas_factor = 0; //total de horas de agenda periodo se usa solo para de planta  o nombramiento ocacional

        //Se consulta el total de horas que tiene un docente catedratico
        $sql = "SELECT 
                COUNT(*) as totalhora  
            FROM 
                espacio_ocupacion eso 
            INNER JOIN curso cur ON cur.cur_codigo = eso.eso_actividad  
            INNER JOIN asignatura asi ON cur.asi_codigo = asi.asi_codigo AND asi.car_codigo != 'PP' 
            WHERE 
                eso.uap_codigo = {$UapCodigo} 
            ";
        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar el total de horas para un catedratico.";
            return $this->errorConsultarBd;
        }
        $r_total_horas = $this->cnx->json; //Almacenamos el total de horas del catedratico.
        foreach ($r_total_horas as $fe_horas) {
            $control_tope_horas = 224; //Se establece el tope de horas
            $total_horas = $fe_horas['totalhora']; //Se almacena la cantidad total de horas del catedratico actualmente.
        }

        $r_total_horas_servicio = $servicioCargaDocente->obtenerTotalHorasCatedraSinPractica($UapCodigo);
        if (!$r_total_horas_servicio["resultado"]) {
            return $r_total_horas_servicio;
        }
        $total_horas = $r_total_horas_servicio["data"]["totalHoras"];

        //Se consulta el total de horas practica pedagogica que tiene un docente catedratico
        $sql = "SELECT 
                SUM(factor) as totalpp 
            FROM 
                agenda_periodo agp 
            WHERE 
                agp.uap_codigo = {$UapCodigo} 
                and agp.caracter = 'PP'
            ";
        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar el total de horas practica pedagogica para un catedratico.";
            return $this->errorConsultarBd;
        }
        $r_total_horas_practica = $this->cnx->json; //Almacenamos el total de horas practica pedagogica del catedratico.
        foreach ($r_total_horas_practica as $fe_horas) {
            $control_tope_horas = 252; //Se establece el tope de horas
            $total_horas_pp = $fe_horas['totalpp']; //Se almacena la cantidad total de horas practica pedagogica del catedratico actualmente.
        }

        $r_total_horas_practica_servicio = $servicioCargaDocente->obtenerHorasPracticaPedagogica($UapCodigo);
        if (!$r_total_horas_practica_servicio["resultado"]) {
            return $r_total_horas_practica_servicio;
        }
        $total_horas_pp = $r_total_horas_practica_servicio["data"]["totalPP"];

        // 14	CATEDRA DOCENTE
        // 24	CATEDRA VISITANTE DOCENTE
        // 49	CATEDRA CONVENIO DOCENTE
        //  6   POR HORAS
        if (($VinCodigo == 14 or $VinCodigo == 24 or $VinCodigo == 49) &&  $DedCodigo == 6) {
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
                pep.pep_persona = {$UapPerCodigo} 
                and per.per_codigo = {$PerCodigo}
            ";
            if (!$this->cnx->consultar($sql)) {
                $this->errorConsultarBd["consola"] = "Error al consultar el total de horas proyecto de investigación y direccion de tesis para un catedratico.";
                return $this->errorConsultarBd;
            }

            $r_total_horas_inv_tesis = $this->cnx->json; //Almacenamos el total de horas proyectos de investigacion y direccion de tesis del catedratico.
            foreach ($r_total_horas_inv_tesis as $fe_horas) {
                $control_tope_horas = 252; //Se establece el tope de horas
                $total_horas_inv_tesis = $fe_horas['total']; //Se almacena la cantidad total de horas proyecto de investigacion y direccion de tesis del catedratico actualmente.
            }

            $cargaComplementariaSemanal = $servicioCargaDocente->obtenerCargaComplementariaSemanal($UapPerCodigo, $PerCodigo, true);
            if (!$cargaComplementariaSemanal["resultado"]) {
                return $cargaComplementariaSemanal;
            }
            $total_horas_inv_tesis = $cargaComplementariaSemanal["data"]["proyectosSemanal"];

            //Comparamos si cuenta con horas de practica pedagogica, proyectos de investigacion o direccion de tesis.
            if ($total_horas_inv_tesis > 0 || $total_horas_pp > 0) {
                $control_tope_horas = 288;
            } else {
                $control_tope_horas = 252;
            }

            //Validacion si la dependencia de la unidad es la facultad de salud con codigo 23
            if ($UaaDependencia == 23) {
                $control_tope_horas == 288;
            }

            $cantidad_horas_nuevas_total = $cantidad_horas_nuevas * $CurSemanas; //Se calcula el total de horas nuevas en la semana por el total de semanas del curso.
            $total_horas_descarga = $total_horas_descarga + $cantidad_horas_nuevas_total + $total_horas_inv_tesis + $total_horas + $total_horas_pp; //Se suman todas las horas para sacar el total de descarga

            //Se verifica que el total de horas de descarga no super el tome establecido
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
                    if ($UapSedCodigo != 1) { //Validamos si es de sede diferente a neiva
                        $cantidad_horas_nuevas_total = $cantidad_horas_nuevas + $horas_semanal_catedratico_sede; //Se calcula el total de horas nuevas en la semana por el total de semanas del curso.
                        if ($cantidad_horas_nuevas_total > $max_horas_catedratico_sedes) { //En caso de que el total de horas de descarga sea mayor que el maximo permitido para catedraticos en sede
                            $respuesta = array(
                                "resultado" => false,
                                "mensaje" => "ERROR. No se pueden adicionar las horas porque supera el límite de horas semanales, límite horas semanal en sedes: {$max_horas_catedratico_sedes}, horas que tendría el docente: {$cantidad_horas_nuevas_total}",
                                "line" => __LINE__
                            );
                        } else {
                            //Se procede a realizar la programacion.
                            $respuesta = array(
                                "resultado" => true,
                                "mensaje" => "Se procede a realizar la programación, es docente de una sede y no supera los topes cantidad_horas_nuevas_total > max_horas_catedratico_sedes ($cantidad_horas_nuevas_total > $max_horas_catedratico_sedes). ",
                                "line" => __LINE__
                            );
                        }
                    } else {
                        $cantidad_horas_nuevas_total = $cantidad_horas_nuevas + $horas_semanal_catedratico; //Se calcula el total de horas nuevas en la semana por el total de semanas del curso.
                        if ($cantidad_horas_nuevas_total > $max_horas_catedratico) { //En caso de que el total de horas de descarga sea mayor que el maximo permitido para catedraticos en neiva que son 16, esto esta en el acuerdo 048 de 2018 usco
                            $respuesta = array(
                                "resultado" => false,
                                "mensaje" => "ERROR. No se pueden adicionar las horas porque supera el límite de horas semanales, límite horas semanal en Neiva: {$max_horas_catedratico}, horas que tendría el docente: {$cantidad_horas_nuevas_total}",
                                "line" => __LINE__
                            );
                        } else {
                            //Se procede a realizar la programacion.
                            $respuesta = array(
                                "resultado" => true,
                                "mensaje" => "Se procede a realizar la programación, es docente de neiva y no supera los topes cantidad_horas_nuevas_total > max_horas_catedratico ($cantidad_horas_nuevas_total > $max_horas_catedratico). ",
                                "line" => __LINE__
                            );
                        }
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
            //Consulta las horas de investigacion y direccion de tesis
            $sql = "SELECT 
                sum(pep_hora_semana*pep_semanas) as total 
            FROM 
                proyecto pro
            INNER JOIN proyecto_tipo prt ON prt.prt_codigo = pro.prt_codigo 
            INNER JOIN persona_proyecto pep ON pro.pry_codigo = pep.pry_codigo 
            INNER JOIN periodo per ON per.per_codigo = pep.per_codigo 
			WHERE 
                pep.pep_persona = {$UapPerCodigo} 
                and per.per_codigo = {$PerCodigo}
            ";
            if (!$this->cnx->consultar($sql)) {
                $this->errorConsultarBd["consola"] = "Error al consultar el total de horas proyecto de investigación y direccion de tesis para un catedratico.";
                return $this->errorConsultarBd;
            }
            $r_total_horas_inv_tesis = $this->cnx->json; //Almacenamos el total de horas proyectos de investigacion y direccion de tesis del catedratico.
            foreach ($r_total_horas_inv_tesis as $fe_horas) {
                $total_horas_inv_tesis = $fe_horas['total']; //Se almacena la cantidad total de horas proyecto de investigacion y direccion de tesis del catedratico actualmente.
            }

            //Consulta las horas de novedades docentes
            $sql = "SELECT 
                SUM(pen_descarga_semestral) as total
            FROM 
                persona_novedad pen
            INNER JOIN novedad nov ON pen.nov_codigo = nov.nov_codigo 
            INNER JOIN periodo per ON per.per_codigo = pen.per_codigo 
            WHERE 
                pen.pen_persona = {$UapPerCodigo} 
                AND per.per_codigo = {$PerCodigo}
                AND pen.pen_estado = 1
            ";

            if (!$this->cnx->consultar($sql)) {
                $this->errorConsultarBd["consola"] = "Error al consultar el total de novedades para un catedratico.";
                return $this->errorConsultarBd;
            }
            $r_total_horas_novedad = $this->cnx->json; //Almacenamos el total de horas proyectos de investigacion y direccion de tesis del catedratico.
            foreach ($r_total_horas_novedad as $fe_horas) {
                $total_horas_novedad = $fe_horas['total']; //Se almacena la cantidad total de horas de novedades del catedratico actualmente.
            }

            //Para consultar el total de horas que tiene el docente, primero eliminamos de agenda docente el calculo de horas para este curso dado que se debe recalcular, una vez se inserten nuevamente.
            $sql = "DELETE FROM agenda_periodo WHERE uap_codigo = {$UapCodigo} and cur_codigo = {$CurCodigo}";
            if (!$this->cnx->sentencia($sql)) {
                $this->errorSentenciaBd["mensaje"] = "Error al eliminar la agenda del curso: {$CurCodigo} y vinculacion docente: {$UapCodigo}.";
                $this->errorSentenciaBd["consola"] = "Ha fallado el delete de la agenda del curso: {$CurCodigo} y vinculacion docente: {$UapCodigo}.";
                return $this->errorSentenciaBd;
            }

            $sql = "SELECT 
                SUM(ag.factor) as total 
            FROM 
                curso cur 
            INNER JOIN agenda_periodo ag ON cur.cur_codigo = ag.cur_codigo and ag.vinculacion in (12) and ag.per_codigo = {$UapPerCodigo}
            INNER JOIN calendario cal ON cal.cal_codigo = cur.cal_codigo and cal.cal_codigo = {$CalCodigo}
            INNER JOIN periodo per ON cal.per_codigo = per.per_codigo
            ";

            if (!$this->cnx->consultar($sql)) {
                $this->errorConsultarBd["consola"] = "Error al consultar el total de novedades para un catedratico.";
                return $this->errorConsultarBd;
            }
            $r_total_horas_factor = $this->cnx->json; //Almacenamos el total de horas en agenda_periodo del docente.
            foreach ($r_total_horas_factor as $fe_horas) {
                $total_horas_factor = $fe_horas['total']; //Se almacena la cantidad total de horas de agenda periodo .
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

            // Verificamos si es la facultad de ingenieria (21)
            if ($UaaDependencia == 21) {
                $total_factor = $CurSemanas;
                if ($CarCodigo == "T") { //En caso de ser teorico.
                    $total_factor = ($AsiCreditosTeoria * 3) * $CurSemanas;
                }
                if ($CarCodigo == "TP") { //En caso de ser teorico practico
                    if ($SubGrupo == "00") { //En caso de ser el subgrupo 00 que es teoria
                        $total_factor = ($AsiCreditosTeoria * 3) * $CurSemanas;
                    } else { //En caso de ser subgrupo 01,02,03...etc que son las practicas
                        $total_factor = ($AsiCreditosPractica * 3) * $CurSemanas;
                    }
                }
            }

            // Verificamos si es para las facultades: 
            // 19	FACULTAD ECONOMIA Y ADMINISTRACION
            // 20	FACULTAD DE EDUCACION
            // 22	FACULTAD CIENCIAS EXACTAS Y NATURALES
            // 24	FACULTAD CIENCIAS SOCIALES Y HUMANAS
            if ($UaaDependencia == 19 || $UaaDependencia == 20 || $UaaDependencia == 22 || $UaaDependencia == 24) {
                $total_factor = $CurSemanas * 1.5;
                if ($CarCodigo == "T") { //En caso de ser teorico.
                    $total_factor = ($AsiCreditosTeoria * 3) * $CurSemanas;
                }
                if ($CarCodigo == "TP") { //En caso de ser teorico practico
                    if ($SubGrupo == "00") { //En caso de ser el subgrupo 00 que es teoria
                        $total_factor = ($AsiCreditosTeoria * 3) * $CurSemanas;
                    } else { //En caso de ser subgrupo 01,02,03...etc que son las practicas
                        $total_factor = ($AsiCreditosPractica * 3) * $CurSemanas;
                    }
                }
            }

            // Verificamos si es la facultad de salud (23)
            // 715. DPTO O PROGRAMA DE LICENCIATURA EN CIENCIAS NATURALES Y EDUCACION AMBIENTAL
            // 706	3	LICENCIATURA EN CIENCIAS NATURALES Y EDUCACION AMBIENTAL
            if ($UaaDependencia == 23 or $uaaProgramada == 715 or $uaaProgramada == 706) {
                $total_factor = $cantidad_horas_nuevas * 1;
                if ($CarCodigo == "T") { // En caso de ser teorico
                    $total_factor = ($cantidad_horas_nuevas * 2) + 1 * $CurSemanas;
                }
                if ($CarCodigo == "TP") { // En caso de ser teorico practico, no discrimina subgrupo.
                    $total_factor = ($cantidad_horas_nuevas * 1.5) + 1 * $CurSemanas;
                }
            }

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
                            "mensaje" => "ERROR. La vinculación seleccionada es de TIEMPO COMPLETO por lo tanto no debe pasar las 880 horas, el total de horas actual es de {$total_horas_descarga}.",
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
                            "mensaje" => "ERROR. La vinculación seleccionada es de MEDIO TIEMPO por lo tanto no debe pasar las 440 horas, el total de horas actual es de {$total_horas_descarga}.",
                            "line" => __LINE__
                        );
                    }
                }
            }
        }

        return $respuesta;
    }

    // Inicia funcion ConsultarPeriodoHabilitado
    // Funcion que valida cual es el periodo activo para visualizar el botón de crear solicitud, se ejecuta al inicio.
    function consultarPeriodoHabilitado($obj)
    {
        $unidades = $_SESSION['pacademica']['datosVinculacionUsuario']['unidades'];
        $unidades = is_array($unidades) ? implode(",", $unidades) : $unidades;
        $PtsCodigo = 2;

        if (isset($obj->PtsCodigo) && is_numeric($obj->PtsCodigo)) {
            $PtsCodigo = intval($obj->PtsCodigo);
        }

        $now = FechaSqlServer::nowIso8601();
        $nowSql = FechaSqlServer::toSqlDateTime2($now, false);
        if ($nowSql === false) {
            $this->errorConsultarBd["consola"] = "No se pudo preparar la fecha actual ({$now}) para SQL Server.";
            $this->errorConsultarBd["mensaje"] = "Formato de fecha inválido para consultar información del periodo activo.";
            return $this->errorConsultarBd;
        }
        $sql = "SELECT
                    per.per_codigo PeriodoActivo,
                    MIN(prg.prg_fecha_inicio) FechaInicio,
                    MAX(prg.prg_fecha_fin) FechaFin,
                    COUNT(DISTINCT prg.uaa_codigo) CantidadProgramas,
                    MAX(pts.pts_nombre) TipoSolicitud
                FROM 
                    programacionacademica.programacion_gestion prg
                INNER JOIN programacionacademica.programacion_tipo_solicitudes pts ON pts.pts_codigo = prg.pts_codigo
                INNER JOIN calendario cal ON cal.cal_codigo = prg.cal_codigo
                INNER JOIN periodo per ON per.per_codigo = cal.per_codigo
                WHERE
                    prg.prg_estado = 1
                    AND prg.pts_codigo = {$PtsCodigo}
                    AND prg.uaa_codigo IN ({$unidades})
                    AND {$nowSql} BETWEEN prg.prg_fecha_inicio AND prg.prg_fecha_fin
                GROUP BY per.per_codigo
                ORDER BY MAX(prg.prg_fecha_fin) DESC, per.per_codigo DESC";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar información del periodo activo";
            $this->errorConsultarBd["sql"] = $sql;
            $this->errorConsultarBd["mensaje"] = "Error al consultar información del periodo activo.";
            return $this->errorConsultarBd;
        }

        $periodoActivo = 0;
        $fechaInicio = "";
        $fechaFin = "";
        $habilitado = false;
        $cantidadProgramasActivos = 0;
        $periodosActivos = array();
        $mensajeDisponibilidad = "El módulo no está habilitado para crear nuevas solicitudes.";

        if (count($this->cnx->json) > 0) {
            $respuesta = $this->cnx->json[0];
            $periodoActivo = $respuesta["PeriodoActivo"];
            $fechaInicio = date("Y-m-d H:i", strtotime($respuesta["FechaInicio"]));
            $fechaFin = date("Y-m-d H:i", strtotime($respuesta["FechaFin"]));
            $habilitado = true;

            foreach ($this->cnx->json as $periodo) {
                $periodoFechaInicio = date("Y-m-d H:i", strtotime($periodo["FechaInicio"]));
                $periodoFechaFin = date("Y-m-d H:i", strtotime($periodo["FechaFin"]));
                $periodoCantidad = intval($periodo["CantidadProgramas"]);
                $periodosActivos[] = array(
                    "PeriodoActivo" => intval($periodo["PeriodoActivo"]),
                    "fechaInicio" => $periodoFechaInicio,
                    "fechaFin" => $periodoFechaFin,
                    "cantidadProgramasActivos" => $periodoCantidad,
                    "mensajeDisponibilidad" => "Periodo habilitado desde {$periodoFechaInicio} hasta {$periodoFechaFin}.",
                );
            }

            $sql = "SELECT COUNT(DISTINCT prg.uaa_codigo) Cantidad
                    FROM 
                        programacionacademica.programacion_gestion prg
                    WHERE
                        prg.prg_estado = 1
                        AND prg.pts_codigo = {$PtsCodigo}
                        AND prg.uaa_codigo IN ({$unidades})
                        AND {$nowSql} BETWEEN prg.prg_fecha_inicio AND prg.prg_fecha_fin";

            $cantidadProgramas = 0;
            if ($this->cnx->consultar($sql) && count($this->cnx->json) > 0) {
                $cantidadProgramas = intval($this->cnx->json[0]["Cantidad"]);
            }
            $cantidadProgramasActivos = $cantidadProgramas;

            $mensajeDisponibilidad = count($periodosActivos) == 1
                ? $periodosActivos[0]["mensajeDisponibilidad"]
                : "Hay " . count($periodosActivos) . " periodos habilitados para crear nuevas solicitudes.";
        }

        return array(
            "resultado" => true,
            "data" => $periodoActivo,
            "habilitado" => $habilitado,
            "fechaInicio" => $fechaInicio,
            "fechaFin" => $fechaFin,
            "cantidadProgramasActivos" => $cantidadProgramasActivos,
            "periodosActivos" => $periodosActivos,
            "mensajeDisponibilidad" => $mensajeDisponibilidad
        );
    }
}
