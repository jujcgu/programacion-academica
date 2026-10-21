<?php
date_default_timezone_set('America/Bogota');
require_once(dirname(__FILE__) . '/servicios/FechaSqlServer.php');

class Aperfe
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

    private function completarEstadoApertura(&$apertura, $campoEstado, $campoFechaInicio, $campoFechaFin)
    {
        $now = time();
        $fechaInicio = strtotime($apertura[$campoFechaInicio]);
        $fechaFin = strtotime($apertura[$campoFechaFin]);
        $estado = intval($apertura[$campoEstado]);

        $apertura['Vencida'] = ($fechaFin !== false && $now > $fechaFin) ? 1 : 0;
        $apertura['Pendiente'] = ($fechaInicio !== false && $now < $fechaInicio) ? 1 : 0;
        $apertura['ActivaAhora'] = (
            $estado == 1 &&
            $apertura['Vencida'] == 0 &&
            $apertura['Pendiente'] == 0
        ) ? 1 : 0;

        if ($estado == 0) {
            $apertura['EstadoAperturaNombre'] = 'Inactivo';
        } else if ($apertura['Pendiente'] == 1) {
            $apertura['EstadoAperturaNombre'] = 'Pendiente';
        } else if ($apertura['Vencida'] == 1) {
            $apertura['EstadoAperturaNombre'] = 'Vencida';
        } else {
            $apertura['EstadoAperturaNombre'] = 'Activo';
        }
    }

    //Inicio function eliminarGrupo
    //Se usa para eliminar un grupo especifico
    public function eliminarGrupo($obj) {
        // Validaciones
        if (!isset($obj->PgrCodigo) || !is_numeric($obj->PgrCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar un grupo especifica.",
                "consola" => "El codigo del grupo no es numérico o no hay número",
            );
        }

        $PgrCodigo = $obj->PgrCodigo; //Contiene el codigo del grupo especifico

        $sql = "UPDATE 
            programacionacademica.grupo_uaa
        SET
            pgr_estado = 0
        WHERE
            pgr_codigo = {$PgrCodigo}
        ";

        // $this->cnx->Sentencia("BEGIN TRAN");

        //Se ejecuta el update y se verifica que se ejecuto correctamente.
        if (!$this->cnx->Sentencia($sql)) {
            $this->errorSentenciaBd["mensaje"] = "Error al eliminar el grupo especifica.";
            $this->errorSentenciaBd["consola"] = "No se pudo realizar el update del estado del grupo {$PgrCodigo}.";
            // $this->cnx->Sentencia("ROLLBACK TRAN"); //Se realiza un rollback si se encuentra un error
            return $this->errorSentenciaBd;
        }

        // $this->cnx->Sentencia("COMMIT TRAN");

        return array(
            "resultado" => true,
            "mensaje" => "El grupo seleccionado se elimino correctamente."
        );
    }

    //Inicio function guardarGrupo
    //Se usa para crar un grupo de unidades
    public function guardarGrupo($obj){
        // Validaciones
        if (!isset($obj->PgrNombre)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe ingresar el nombre del grupo.",
                "consola" => "El nombre del grupo no se envio correctamente",
            );
        }

        if (!isset($obj->PgrEstado) || !is_numeric($obj->PgrEstado)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio correctamente el estado",
                "consola" => "El codigo del estado no es numérico o no hay número",
            );
        }

        $PgrNombre = $obj->PgrNombre; //Contiene el nombre del grupo
        $PgrEstado = $obj->PgrEstado; //Contiene el estado del grupo (1) Activo

        $insert = "INSERT INTO programacionacademica.grupo_uaa(
            pgr_nombre,
            pgr_estado
        ) VALUES (
            '{$PgrNombre}',
            {$PgrEstado}
        )";

        //Se ejecuta el update y se verifica que se ejecuto correctamente.
        if (!$this->cnx->Sentencia($insert)) {
            $this->errorSentenciaBd["mensaje"] = "Error al crear el grupo {$PgrNombre}.";
            $this->errorSentenciaBd["consola"] = "No se pudo realizar el insert del grupo {$PgrNombre}.";
            return $this->errorSentenciaBd;
        }

        return array(
            "resultado" => true,
            "mensaje" => "El grupo fue creado correctamente."
        );
    }

    //Inicio function asignarItemGrupo
    //Se usa para asignar unidades a un grupo
    public function asignarItemGrupo($obj)
    {
        // Validaciones
        if (!isset($obj->PgrCodigo) || !is_numeric($obj->PgrCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar un grupo especifico.",
                "consola" => "El codigo del grupo no es numérico o no hay número",
            );
        }

        if (!isset($obj->UaaSeleccionada) || count($obj->UaaSeleccionada) <= 0) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar un grupo especifico.",
                "consola" => "El codigo del grupo no es numérico o no hay número",
            );
        }

        $PgrCodigo = $obj->PgrCodigo; //Codigo del grupo seleccionado
        $UaaSeleccionada = $obj->UaaSeleccionada; //Contiene un array con el codigo de las unidades seleccionadas.
        $errorCount = 0;
        $errorUaa = Array();

        foreach ($UaaSeleccionada as $uaa) {
            $sql = "SELECT 
                    gui.gui_codigo GuiCodigo
                FROM
                    programacionacademica.grupo_uaa_item gui
                WHERE
                    gui.uaa_codigo = {$uaa->UaaCodigo}
                    AND gui.pgr_codigo = {$PgrCodigo}
            ";

            //verificamos que se pueda realizar la consulta
            if (!$this->cnx->consultar($sql)) {
                $this->errorConsultarBd["consola"] = "Error en consultar las unidad {$uaa->UaaCodigo} del grupo {$PgrCodigo}.";
                return $this->errorConsultarBd;
            }

            $r_uaa_grupo = $this->cnx->json;

            if (count($r_uaa_grupo) <= 0) {
                $insert = "INSERT INTO programacionacademica.grupo_uaa_item(
                    pgr_codigo,
                    uaa_codigo,
                    gui_estado
                ) VALUES (
                    {$PgrCodigo},
                    {$uaa->UaaCodigo},
                    1
                )";

                //Se ejecuta el update y se verifica que se ejecuto correctamente.
                if (!$this->cnx->Sentencia($insert)) {
                    $errorCount++;
                    array_push($errorUaa, $uaa->UaaCodigo);
                    $this->errorSentenciaBd["mensaje"] = "Error al agregar la unidad {$uaa->UaaCodigo} en el grupo especifico.";
                    $this->errorSentenciaBd["consola"] = "No se pudo realizar el insert de la unidad {$uaa->UaaCodigo} en el grupo {$PgrCodigo}.";
                    return $this->errorSentenciaBd;
                }
            }else{
                $update = "UPDATE programacionacademica.grupo_uaa_item
                SET gui_estado = 1
                WHERE gui_codigo = {$r_uaa_grupo[0]['GuiCodigo']}
                ";

                //Se ejecuta el update y se verifica que se ejecuto correctamente.
                if (!$this->cnx->Sentencia($update)) {
                    $errorCount++;
                    array_push($errorUaa, $uaa->UaaCodigo);
                    $this->errorSentenciaBd["mensaje"] = "Error al agregar la unidad {$uaa->UaaCodigo} en el grupo especifico.";
                    $this->errorSentenciaBd["consola"] = "No se pudo realizar el update de la unidad {$uaa->UaaCodigo} en el grupo {$PgrCodigo} con codigo {$r_uaa_grupo[0]['GuiCodigo']}.";
                    return $this->errorSentenciaBd;
                }
            }
        }

        if( $errorCount == 0 ){
            return array(
                "resultado" => true,
                "mensaje" => "Las unidades se han asignado correctamente."
            );
        }else{
            return array(
                "resultado" => false,
                "mensaje" => "Algunas unidades no se han podido guardar correctamente, por favor intente nuevamente.",
                "errorUnidad" => $errorUaa
            );
        }
    }

    //Inicio function eliminarItemGrupo
    //Se usa para eliminar la unidad especifica de un grupo
    public function eliminarItemGrupo($obj)
    {
        // Validaciones
        if (!isset($obj->GuiCodigo) || !is_numeric($obj->GuiCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar una unidad especifica.",
                "consola" => "El codigo de la unidad del grupo no es numérico o no hay número",
            );
        }

        $GuiCodigo = $obj->GuiCodigo; //Contiene el codigo de la unidad especifica de un grupo.

        $sql = "UPDATE 
            programacionacademica.grupo_uaa_item
        SET
            gui_estado = 0
        WHERE
            gui_codigo = {$GuiCodigo}
        ";

        // $this->cnx->Sentencia("BEGIN TRAN");

        //Se ejecuta el update y se verifica que se ejecuto correctamente.
        if (!$this->cnx->Sentencia($sql)) {
            $this->errorSentenciaBd["mensaje"] = "Error al eliminar la unidad especifica.";
            $this->errorSentenciaBd["consola"] = "No se pudo realizar el update del estado de la unidad de grupo {$GuiCodigo}.";
            // $this->cnx->Sentencia("ROLLBACK TRAN"); //Se realiza un rollback si se encuentra un error
            return $this->errorSentenciaBd;
        }

        // $this->cnx->Sentencia("COMMIT TRAN");

        return array(
            "resultado" => true,
            "mensaje" => "La unidad seleccionada se elimino correctamente."
        );
    }

    //Inicio funcion consultarItemsGrupo
    //Se usa para consultar los grupos activos.
    public function consultarItemsGrupo($obj)
    {
        // Validaciones
        if (!isset($obj->PgrCodigo) || !is_numeric($obj->PgrCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar un grupo de unidad.",
                "consola" => "El codigo del grupo no es numérico o no hay número",
            );
        }

        $PgrCodigo = $obj->PgrCodigo; //Contiene el codigo del grupo.

        $sql = "SELECT 
                gui.gui_codigo GuiCodigo, 
                gui.uaa_codigo GuiNombre, 
                gui.gui_estado GuiEstado,
                uaa.uaa_codigo UaaCodigo,
                uaa.uaa_nombre UaaNombre,
                uaa.uaa_nombre_corto UaaNombreCorto
            FROM 
                programacionacademica.grupo_uaa_item gui
            INNER JOIN uaa ON uaa.uaa_codigo = gui.uaa_codigo
            WHERE 
                gui.pgr_codigo = {$PgrCodigo}
                AND gui.gui_estado = 1
            ORDER BY
                gui.gui_codigo DESC
        ";

        //verificamos que se pueda realizar la consulta
        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error en consultar las unidades del grupo seleccionado.";
            return $this->errorConsultarBd;
        }

        $r_unidades = $this->cnx->json;

        return array(
            "resultado" => true,
            "mensaje" => "Unidades del grupo consultadas correctamente.",
            "data" => $r_unidades
        );
    }

    //Inicio funcion consultarGruposUnidades
    //Se usa para consultar los grupos activos.
    public function consultarGruposUnidades()
    {
        $sql = "SELECT 
                pgr.pgr_codigo PgrCodigo, 
                pgr.pgr_nombre PgrNombre, 
                pgr.pgr_estado PgrEstado

            FROM 
                programacionacademica.grupo_uaa pgr
            WHERE
                pgr.pgr_estado = 1
            ORDER BY
                pgr.pgr_codigo DESC
        ";

        //verificamos que se pueda realizar la consulta
        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error en consultar los grupos de unidades.";
            return $this->errorConsultarBd;
        }

        $r_grupo = $this->cnx->json;

        return array(
            "resultado" => true,
            "mensaje" => "Grupos de unidades consultados correctamente.",
            "data" => $r_grupo
        );
    }

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

    //Inicio funcion consultarAperturaGestion
    //Se usa para consultar las aperturas activas de un programa
    public function consultarAperturaGestion($obj)
    {
        $sql = "SELECT 
                prg.prg_codigo PrgCodigo, 
                prg.prg_fecha_inicio PrgFechaInicio, 
                prg.prg_fecha_fin PrgFechaFin,
                prg.prg_estado PrgEstado,

                prg.uaa_codigo UaaCodigo,

                cal.cal_codigo CalCodigo, 
                cal.cal_nombre CalNombre,

                per.per_fecha_inicio PerFechaInicio,
                per.per_fecha_fin PerFechaFin

            FROM 
                programacionacademica.programacion_gestion  prg
            INNER JOIN calendario cal ON cal.cal_codigo = prg.cal_codigo
            INNER JOIN periodo per on cal.per_codigo = per.per_codigo

            WHERE prg.uaa_codigo = {$obj->UaaCodigo}
                AND prg.pts_codigo = 1
        ORDER BY prg.prg_fecha_inicio, prg.prg_fecha_fin DESC
        ";

        //verificamos que se pueda realizar la consulta
        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error en consultar las fechas de apertura de gestión de la unidad.";
            return $this->errorConsultarBd;
        }

        $r_apertura = $this->cnx->json;
        for ($i = 0; $i < count($r_apertura); $i++) {
            $this->completarEstadoApertura($r_apertura[$i], 'PrgEstado', 'PrgFechaInicio', 'PrgFechaFin');

            $r_apertura[$i]['PrgFechaInicio'] =  date("Y-m-d H:i", strtotime($r_apertura[$i]['PrgFechaInicio']));
            $r_apertura[$i]['PrgFechaFin'] =  date("Y-m-d H:i", strtotime($r_apertura[$i]['PrgFechaFin']));

            $r_apertura[$i]['PerFechaInicio'] =  date("Y-m-d H:i", strtotime($r_apertura[$i]['PerFechaInicio']));
            $r_apertura[$i]['PerFechaFin'] =  date("Y-m-d H:i", strtotime($r_apertura[$i]['PerFechaFin']));
        }

        return array(
            "resultado" => true,
            "mensaje" => "Aperturas de gestión consultadas correctamente.",
            "data" => $r_apertura
        );
    }

    //Inicio funcion guardarAperturaGestion
    //Se usa para guardar las aperturas para cada unidad seleccionada, para un calendario en un rango de fechas.
    public function guardarAperturaGestion($obj)
    {
        //Parametros
        //$obj->UaaSeleccionadas: Un objeto con la lista de uaa seleccionadas, contiene UaaCodigo y UaaNombre.
        //$obj->FechaInicial: contiene la fecha inicial en formato aaaa-mm-dd.
        //$obj->HoraInicial: contiene la ahora inicial en formato aaaa-mm-ddThh:mm:ss.000Z.
        //$obj->FechaFinal: contiene la fecha final en formato aaaa-mm-dd.
        //$obj->HoraFinal: contiene la hora final en formato aaaa-mm-ddThh:mm:ss.000Z.
        //$obj->CalendarioCodigo: contiene un codigo del calendario seleccionado.
        //$obj->Correo: contiene un codigo para validar si se envia correo (1) o no (0).

        $obj->HoraInicial = date("H:i:s", strtotime($obj->HoraInicial));
        $obj->HoraFinal = date("H:i:s", strtotime($obj->HoraFinal));

        $obj->FechaInicial .= "T" . $obj->HoraInicial . ".000";
        $obj->FechaFinal .= "T" . $obj->HoraFinal . ".000";
        $fechaInicialSql = FechaSqlServer::toSqlDateTime2($obj->FechaInicial, false);
        $fechaFinalSql = FechaSqlServer::toSqlDateTime2($obj->FechaFinal, false);
        if ($fechaInicialSql === false || $fechaFinalSql === false) {
            return array(
                "resultado" => false,
                "mensaje" => "Formato de fecha inválido para apertura de gestión.",
                "consola" => "No se pudieron preparar fechas SQL ({$obj->FechaInicial} - {$obj->FechaFinal}).",
            );
        }

        $this->cnx->Sentencia("BEGIN TRAN");

        //Se recorren todas las unidades seleccionadas.
        foreach ($obj->UaaSeleccionadas as $uaa) {
            // Para conservar historial completo, se desactivan las aperturas vigentes del mismo contexto
            // y se inserta una nueva fila en lugar de sobrescribir.
            $sql = "UPDATE programacionacademica.programacion_gestion
                    SET prg_estado = 0
                    WHERE
                        uaa_codigo = {$uaa->UaaCodigo}
                        AND cal_codigo = {$obj->CalendarioCodigo}
                        AND pts_codigo = 1
                        AND prg_estado = 1";

            if (!$this->cnx->Sentencia($sql)) {
                $this->errorSentenciaBd["mensaje"] = "Error al preparar el historial de apertura de gestión para {$uaa->UaaNombre}.";
                $this->errorSentenciaBd["consola"] = "No se pudieron desactivar aperturas previas para la unidad ({$uaa->UaaCodigo}) y calendario ({$obj->CalendarioCodigo}).";
                $this->cnx->Sentencia("ROLLBACK TRAN");
                return $this->errorSentenciaBd;
            }

            $sql = "INSERT INTO programacionacademica.programacion_gestion(
                    uaa_codigo,
                    pts_codigo,
                    cal_codigo,
                    prg_fecha_inicio,
                    prg_fecha_fin,
                    prg_estado
                )
                VALUES(
                    {$uaa->UaaCodigo},
                    1,
                    {$obj->CalendarioCodigo},
                    {$fechaInicialSql},
                    {$fechaFinalSql},
                    1
                )";

            if (!$this->cnx->Sentencia($sql)) {
                $this->errorSentenciaBd["mensaje"] = "Error al realizar la apertura de gestión del calendario de {$uaa->UaaNombre}.";
                $this->errorSentenciaBd["consola"] = "No se pudo realizar el insert para la unidad ({$uaa->UaaCodigo}) y 
                    calendario ({$obj->CalendarioCodigo})";
                $this->cnx->Sentencia("ROLLBACK TRAN");
                return $this->errorSentenciaBd;
            }
        }

        $this->cnx->Sentencia("COMMIT TRAN");

        if ($obj->Correo == "1") {
            $correos = $this->enviarCorreos($obj);
            if ($correos["resultado"] == false) {
                return array(
                    "resultado" => true,
                    "mensaje" => "Se guardaron las aperturas de gestión correctamente pero no se enviaron los correos correctamente."
                );
            }
            if ($correos["resultado"] == true) {
                return array(
                    "resultado" => true,
                    "mensaje" => "Se guardaron las aperturas de gestión correctamente y {$correos["mensaje"]}."
                );
            }
        }

        return array(
            "resultado" => true,
            "mensaje" => "Se guardaron las aperturas de gestión correctamente."
        );
    }

    //Inicio funcion enviarCorreos
    //Se usa para enviar correos de notificacion para la apertura de programacion academica o administrador de secretarias
    public function enviarCorreos($obj)
    {
        //Parametros
        //$obj->UaaSeleccionadas: Un objeto con la lista de uaa seleccionadas, contiene UaaCodigo y UaaNombre.
        //$obj->FechaInicial: contiene la fecha inicial en formato aaaa-mm-dd.
        //$obj->HoraInicial: contiene la ahora inicial en formato aaaa-mm-ddThh:mm:ss.000Z.
        //$obj->FechaFinal: contiene la fecha final en formato aaaa-mm-dd.
        //$obj->HoraFinal: contiene la hora final en formato aaaa-mm-ddThh:mm:ss.000Z.
        //$obj->CalendarioCodigo: contiene un codigo del calendario seleccionado.
        //$obj->Correo: contiene un codigo para validar si se envia correo (1) o no (0).
        //$obj->ProcesoSeleccionados: contiene los procesos seleccionados para programacion academica              


        $procesos = ""; //Se almacenaran los procesos en caso de tener seleccionado.
        $implode_uaa = ""; //Se almacenaran las uaa separadas por coma
        $nombres_uaa = ""; //Se almacenaran el nombre de las unidades en forma de lista
        $primer_uaa = true; //Controla si es el primer registro del foreach para separar por comas correctamente.
        $CalNombre = ""; //Contiene el nombre del calendario que se va a activar.

        $sql = "SELECT cal.cal_nombre CalNombre FROM calendario cal where cal_codigo = {$obj->CalendarioCodigo}";
        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar los detalles del calendario: {$obj->CalendarioCodigo}.";
            return $this->errorConsultarBd;
        }
        $r_calendario = $this->cnx->json;
        if (count($r_calendario) > 0) {
            $CalNombre = $r_calendario[0]["CalNombre"];
        }

        foreach ($obj->UaaSeleccionadas as $uaa) {
            $sql = "SELECT 
                uaa.uaa_codigo UaaCodigo, 
                uaa.uaa_nombre UaaNombre, 
                uaa.uaa_nombre_corto UaaNombreCorto
            FROM
                uaa
            WHERE
                uaa.uaa_codigo = {$uaa->UaaCodigo}
            ";
            if (!$this->cnx->consultar($sql)) {
                $this->errorConsultarBd["consola"] = "Error al consultar los detalles de la uaa: {$uaa->UaaCodigo}.";
                return $this->errorConsultarBd;
            }
            $r_uaa = $this->cnx->json;
            foreach ($r_uaa as $detalle_uaa) {
                $uaa_codigo = $detalle_uaa["UaaCodigo"];
                $uaa_nombre = $detalle_uaa["UaaNombreCorto"];
            }

            if ($primer_uaa == true) {
                $implode_uaa .= $uaa_codigo;
                $primer_uaa = false;
            } else {
                $implode_uaa .= "," . $uaa_codigo;
            }
            $nombres_uaa .= "- " . $uaa_codigo . ". " . $uaa_nombre . "\n";
        }

        $sql = "SELECT 
                usu_programac.usg_usuario, 
                uad.uid, per.per_email_interno,
                per.per_nombre+' '+per.per_apellido as nombre
            from (
                select distinct usg_usuario
                from usuario_grupo usg
                where usg.usg_estado = 1
                and usg.usg_grupo in (68,69)--grupos de programacion
                and usg.usg_uaa in (
                    select 
                        uaa_codigo_unificado 
                    from 
                        programa pro 
                    inner join uaa on uaa.uaa_codigo = pro.uaa_codigo and pro.uaa_codigo in ({$implode_uaa})
                )
            ) as usu_programac
            inner join (
                select up, uid from usuario_administrativo group by up, uid
                union
                select up, uid from usuario_docente group by up, uid
            ) as uad on uad.uid = usu_programac.usg_usuario
            inner join persona per on per.per_codigo=uad.up
            union
            --y ademas busca los correos de los admin para informarles
            select 
                uad.usg_usuario, 
                uad.uid, 
                per.per_email_interno,
                per.per_nombre+' '+per.per_apellido as nombre
            from usuario_administrativo uad
            inner join persona per on per.per_codigo=uad.up
            where uad.usg_estado = 1 and uad.usg_grupo = 69
            order by nombre";

        //Realizamos la consulta de verificacion.
        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar el correo interno del usuario de la uaa: {$implode_uaa}.";
            // $this->errorConsultarBd["sql"] = $sql;
            return $this->errorConsultarBd;
        }

        $r_correos = $this->cnx->json;
        $correos = array();
        foreach ($r_correos as $correo) {
            $temp = array();
            $temp['PerEmail'] = $correo['per_email_interno'];
            $temp['PerNombre'] = $correo['nombre'];
            array_push($correos, $temp);
        }

        if (count($correos) < 1) {
            return array(
                "resultado" => false,
                "mensaje" => "No se encontraron correos."
            );
        }

        if ($obj->ProcesoSeleccionados) {
            foreach ($obj->ProcesoSeleccionados as $proceso) {
                if ($proceso == "1") {
                    $procesos = $procesos . "PROG. INSTITUCIONALES, ";
                }
                if ($proceso == "2") {
                    $procesos = $procesos . "PROG. ELECTIVAS FACULTAD, ";
                }
                if ($proceso == "3") {
                    $procesos = $procesos . "PROG. ASIGNATURAS PROGRAMAS, ";
                }
                if ($proceso == "4") {
                    $procesos = $procesos . "PROG. REPESCA, ";
                }
            }
        } else {
            $procesos = "ADMINISTRADOR DE SECRETARIAS";
        }

        $parametros_correo = array(
            "listadoCorreos" => $correos,
            "procesos" => $procesos,
            "fechaInicio" => $obj->FechaInicial,
            "fechaFin" => $obj->FechaFinal,
            "textoUaasMarcadas" => $nombres_uaa,
            "CalNombre" => $CalNombre
        );

        require_once "../correos/correo_apertura.php";
        $ca = new Correo_apertura();
        $resultado = $ca->enviarCorreoAperturaProgramacion($parametros_correo);
        return $resultado;

        // return array(
        //     "resultado" => true,
        //     "correos" => $correos
        // );
    }

    //Inicio funcion consultarUsuariosUaa
    //Se usa para consultar los usuarios activos que tiene una uaa
    public function consultarUsuariosUaa($obj)
    {
        $sql = "SELECT		
                gru.gru_nombre GruNombre, 
                usg.usg_uaa UaaCodigo,			
                usg.usg_estado UsgEstado, 
                per.per_nombre PerNombre,
                per.per_apellido PerApellido,
                per.per_email_interno PerEmailInterno
            FROM		
                dbo.usuario_grupo AS usg
            INNER JOIN	dbo.grupo AS gru ON usg.usg_grupo = gru.gru_codigo 
            INNER JOIN	dbo.usuario_administrativo uad ON usg.usg_usuario = uad.uid
            INNER JOIN  dbo.persona per ON per.per_codigo = uad.up
            WHERE		
                gru.gru_codigo IN (68,69)  AND 
                usg.usg_estado = 1 AND 
                usg.usg_uaa = {$obj->UaaCodigo}

            UNION 

            SELECT		
                gru.gru_nombre GruNombre, 
                usg.usg_uaa UaaCodigo,			
                usg.usg_estado UsgEstado, 
                per.per_nombre PerNombre,
                per.per_apellido PerApellido,
                per.per_email_interno PerEmailInterno
            FROM		
                dbo.usuario_grupo as usg
            INNER JOIN	dbo.grupo as gru ON usg.usg_grupo = gru.gru_codigo 
            INNER JOIN	dbo.usuario_docente uad ON usg.usg_usuario = uad.uid
            INNER JOIN  dbo.persona per ON per.per_codigo = uad.up
            WHERE		
                gru.gru_codigo in (68,69) AND 
                usg.usg_estado = 1 AND 
                usg.usg_uaa = {$obj->UaaCodigo}
        ";

        //verificamos que se pueda realizar la consulta
        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error en consultar los usuarios vinculados a la unidad.";
            return $this->errorConsultarBd;
        }

        return array(
            "resultado" => true,
            "mensaje" => "Usuarios consultados correctamente.",
            "data" => $this->cnx->json
        );
    }

    //Inicio funcion eliminarAperturaProgramacion
    //Se usa para desactivar una apertura especifica de programacion academica
    public function eliminarAperturaProgramacion($obj)
    {
        $this->cnx->Sentencia("BEGIN TRAN");

        $sql = "UPDATE 
                programacionacademica.programacion_academica 
            SET
                pra_estado = 0
            WHERE
                pra_codigo = {$obj->PraCodigo}
        ";

        //Se ejecuta el update y se verifica que se ejecuto correctamente.
        if (!$this->cnx->Sentencia($sql)) {
            $this->errorSentenciaBd["mensaje"] = "Error al desactivar la apertura seleccionada.";
            $this->errorSentenciaBd["consola"] = "No se pudo realizar el update a la apertura: {$obj->PraCodigo}";
            $this->cnx->Sentencia("ROLLBACK TRAN"); //Se realiza un rollback si se encuentra un error
            return $this->errorSentenciaBd;
        }

        $this->cnx->Sentencia("COMMIT TRAN");

        return array(
            "resultado" => true,
            "mensaje" => "Se desactivo correctamente."
        );
    }

    //Inicio funcion eliminarAperturaGestion
    //Se usa para desactivar una apertura especifica de gestion
    public function eliminarAperturaGestion($obj)
    {
        $this->cnx->Sentencia("BEGIN TRAN");

        $sql = "UPDATE 
                programacionacademica.programacion_gestion 
            SET
                prg_estado = 0
            WHERE
                prg_codigo = {$obj->PrgCodigo}
                AND pts_codigo = 1
        ";

        //Se ejecuta el update y se verifica que se ejecuto correctamente.
        if (!$this->cnx->Sentencia($sql)) {
            $this->errorSentenciaBd["mensaje"] = "Error al desactivar la apertura seleccionada.";
            $this->errorSentenciaBd["consola"] = "No se pudo realizar el update a la apertura: {$obj->PrgCodigo}";
            $this->cnx->Sentencia("ROLLBACK TRAN"); //Se realiza un rollback si se encuentra un error
            return $this->errorSentenciaBd;
        }

        $this->cnx->Sentencia("COMMIT TRAN");

        return array(
            "resultado" => true,
            "mensaje" => "Se desactivo correctamente."
        );
    }

    //Inicio funcion consultarAperturaProgramacion
    //Se usa para consultar las aperturas activas de un programa
    public function consultarAperturaProgramacion($obj)
    {
        $sql = "SELECT 
                pra.pra_codigo PraCodigo, 
                pra.pra_fecha_inicio PraFechaInicio, 
                pra.pra_fecha_fin PraFechaFin,
                pra.pra_estado PraEstado,

                pra.uaa_codigo UaaCodigo,

                prp.prp_codigo PrpCodigo, 
                prp.prp_nombre PrpNombre, 
                prp.nuc_codigo NucCodigo,

                cal.cal_codigo CalCodigo, 
                cal.cal_nombre CalNombre,

                per.per_fecha_inicio PerFechaInicio,
                per.per_fecha_fin PerFechaFin,
                per.per_codigo PerCodigo,
                per.per_nombre PerNombre,

                (
                    SELECT 
                        convert(varchar, peu_fecha_inicio) + ' ' + convert(varchar, peu_fecha_fin) PeriodoPersonalizado
                    FROM
                        programacionacademica.periodo_unidad 
                    WHERE
                        uaa_codigo = {$obj->UaaCodigo} AND
                        per_codigo = per.per_codigo AND
                        peu_estado = 1
                ) PeriodoPersonalizado,

                convert(varchar, cal.cal_codigo) + convert(varchar,'. ') + cal.cal_nombre + ' ' + prp.prp_nombre CalCodigoNombreProceso


            FROM 
                programacionacademica.programacion_academica  pra
            INNER JOIN programacion_proceso prp ON prp.prp_codigo = pra.prp_codigo
            INNER JOIN calendario cal ON cal.cal_codigo = pra.cal_codigo
            INNER JOIN periodo per on cal.per_codigo = per.per_codigo

            WHERE pra.uaa_codigo = {$obj->UaaCodigo}
            ORDER BY 
                cal.cal_codigo DESC, prp.prp_codigo DESC
        ";

        //verificamos que se pueda realizar la consulta
        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error en consultar las fechas de apertura de la unidad.";
            return $this->errorConsultarBd;
        }

        $r_apertura = $this->cnx->json;
        for ($i = 0; $i < count($r_apertura); $i++) {
            $this->completarEstadoApertura($r_apertura[$i], 'PraEstado', 'PraFechaInicio', 'PraFechaFin');

            $r_apertura[$i]['PraFechaInicio'] =  date("Y-m-d H:i", strtotime($r_apertura[$i]['PraFechaInicio']));
            $r_apertura[$i]['PraFechaFin'] =  date("Y-m-d H:i", strtotime($r_apertura[$i]['PraFechaFin']));

            $r_apertura[$i]['PerFechaInicio'] =  date("Y-m-d H:i", strtotime($r_apertura[$i]['PerFechaInicio']));
            $r_apertura[$i]['PerFechaFin'] =  date("Y-m-d H:i", strtotime($r_apertura[$i]['PerFechaFin']));
            $r_apertura[$i]['Administrador'] = $_SESSION['pacademica']['datosVinculacionUsuario']['Administrador'];
            $r_apertura[$i]['CalTipo'] = substr($r_apertura[$i]['CalNombre'], -1); // returns "A Pregrado, C Postgrado, D Pregrado raro"
        }

        return array(
            "resultado" => true,
            "mensaje" => "Aperturas consultadas correctamente.",
            "data" => $r_apertura
        );
    }

    //Inicio funcion guardarAperturaProaca
    //Se usa para guardar las aperturas de programacion academica para cada unidad seleccionada, por cada proceso, para un calendario en un rango de fechas.
    public function guardarAperturaProaca($obj)
    {
        //Parametros
        //$obj->UaaSeleccionadas: Un objeto con la lista de uaa seleccionadas, contiene UaaCodigo y UaaNombre.
        //$obj->FechaInicial: contiene la fecha inicial en formato aaaa-mm-dd.
        //$obj->HoraInicial: contiene la ahora inicial en formato aaaa-mm-ddThh:mm:ss.000Z.
        //$obj->FechaFinal: contiene la fecha final en formato aaaa-mm-dd.
        //$obj->HoraFinal: contiene la hora final en formato aaaa-mm-ddThh:mm:ss.000Z.
        //$obj->CalendarioCodigo: contiene un codigo del calendario seleccionado.
        //$obj->ProcesoSeleccionados: contiene un objeto con la lista de procesos seleccionados.
        //$obj->Correo: contiene un codigo para validar si se envia correo (1) o no (0).

        $obj->HoraInicial = date("H:i:s", strtotime($obj->HoraInicial));
        $obj->HoraFinal = date("H:i:s", strtotime($obj->HoraFinal));

        $obj->FechaInicial .= "T" . $obj->HoraInicial . ".000";
        $obj->FechaFinal .= "T" . $obj->HoraFinal . ".000";
        $fechaInicialSql = FechaSqlServer::toSqlDateTime2($obj->FechaInicial, false);
        $fechaFinalSql = FechaSqlServer::toSqlDateTime2($obj->FechaFinal, false);
        if ($fechaInicialSql === false || $fechaFinalSql === false) {
            return array(
                "resultado" => false,
                "mensaje" => "Formato de fecha inválido para apertura de programación académica.",
                "consola" => "No se pudieron preparar fechas SQL ({$obj->FechaInicial} - {$obj->FechaFinal}).",
            );
        }

        // $this->cnx->Sentencia("BEGIN TRAN");

        //Se recorren todas las unidades seleccionadas.
        foreach ($obj->UaaSeleccionadas as $uaa) {
            //Se recorren los procesos seleccionados.
            foreach ($obj->ProcesoSeleccionados as $proceso) {
                // Para conservar historial completo, se desactivan aperturas vigentes del mismo contexto
                // y se inserta una nueva fila en lugar de sobrescribir.
                $sql = "UPDATE programacionacademica.programacion_academica
                        SET pra_estado = 0
                        WHERE
                            uaa_codigo = {$uaa->UaaCodigo}
                            AND prp_codigo = {$proceso}
                            AND cal_codigo = {$obj->CalendarioCodigo}
                            AND pra_estado = 1";

                if (!$this->cnx->Sentencia($sql)) {
                    $this->errorSentenciaBd["mensaje"] = "Error al preparar historial de apertura del calendario de {$uaa->UaaNombre}.";
                    $this->errorSentenciaBd["consola"] = "No se pudieron desactivar aperturas previas para la unidad ({$uaa->UaaCodigo}), calendario ({$obj->CalendarioCodigo}) y proceso ({$proceso}).";
                    return $this->errorSentenciaBd;
                }

                $sql = "INSERT INTO programacionacademica.programacion_academica(
                    uaa_codigo,
                    prp_codigo,
                    cal_codigo,
                    pra_fecha_inicio,
                    pra_fecha_fin,
                    pra_estado
                )
                VALUES(
                    {$uaa->UaaCodigo},
                    {$proceso},
                    {$obj->CalendarioCodigo},
                    {$fechaInicialSql},
                    {$fechaFinalSql},
                    1
                )";

                if (!$this->cnx->Sentencia($sql)) {
                    $this->errorSentenciaBd["mensaje"] = "Error al realizar la apertura del calendario de {$uaa->UaaNombre}.";
                    $this->errorSentenciaBd["consola"] = "No se ha pudo realizar el insert para la unidad ({$uaa->UaaCodigo}), 
                    calendario ({$obj->CalendarioCodigo}) y 
                    proceso ({$proceso})";
                    return $this->errorSentenciaBd;
                }
            }
        }

        // $this->cnx->Sentencia("COMMIT TRAN");

        if ($obj->Correo == "1") {
            $correos = $this->enviarCorreos($obj);
            if ($correos["resultado"] == false) {
                return array(
                    "resultado" => true,
                    "mensaje" => "Se guardaron las aperturas de acedémicas correctamente pero no se enviaron los correos correctamente."
                );
            }
            if ($correos["resultado"] == true) {
                return array(
                    "resultado" => true,
                    "mensaje" => "Se guardaron las aperturas de acedémicas correctamente y {$correos["mensaje"]}."
                );
            }
        }

        return array(
            "resultado" => true,
            "mensaje" => "Se guardaron las aperturas correctamente."
        );
    }

    //Inicio funcion consultarProcesos
    //Se usa para consultar los procesos activos.
    public function consultarProcesos()
    {
        $sql = "SELECT 
                prp.prp_codigo PrpCodigo, 
                prp.prp_nombre PrpNombre, 
                prp.prp_orden PrpOrden
            FROM programacion_proceso prp
            ORDER BY prp.prp_orden ASC
        ";

        //verificamos que se pueda realizar la consulta
        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error en consultar los procesos.";
            return $this->errorConsultarBd;
        }

        $r_procesos = $this->cnx->json; //almacenamos la respuesta

        return array(
            "resultado" => true,
            "mensaje" => "Procesos consultadas correctamente.",
            "data" => $r_procesos
        );
    }

    //Inicio funcion consultarCalendarios
    //Se usa para consultar los calendarios activos con su respectivo periodo y fechas de inicio y fin.
    public function consultarCalendarios()
    {
        // if (!$this->cnx->conectar()) {
        //     return $this->errorConectarBd;
        // }

        $sql = "SELECT 
                cal.cal_codigo CalCodigo,
                cal.per_codigo PerCodigo,
                cal.cal_nombre CalNombre,
                cal.cal_estado CalEstado,
                per.per_fecha_inicio PerFechaInicio,
                per.per_fecha_fin PerFechaFin
            FROM calendario cal
            INNER JOIN periodo per ON per.per_codigo = cal.per_codigo 
            WHERE cal.cal_estado = 1 
            ORDER BY cal.cal_nombre DESC
        ";

        //verificamos que se pueda realizar la consulta
        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error en consultar los calendarios.";
            return $this->errorConsultarBd;
        }

        $r_calendarios = $this->cnx->json; //almacenamos la respuesta

        for ($i = 0; $i < count($r_calendarios); $i++) {
            $f_inicio = explode(' ', $r_calendarios[$i]["PerFechaInicio"]);
            $f_fin = explode(' ', $r_calendarios[$i]["PerFechaFin"]);
            $r_calendarios[$i]["PerFechaInicio"] = $f_inicio[0];
            $r_calendarios[$i]["PerFechaFin"] = $f_fin[0];
        }

        return array(
            "resultado" => true,
            "mensaje" => "Calendarios consultadas correctamente.",
            "data" => $r_calendarios
        );
    }

    //Inicio funcion consultarUaaUnificada
    //Se usa para consultar las uaa iniciando por la Facultad>UaaUnificada>Programa
    public function consultarUaaUnificada()
    {
        // if (!$this->cnx->conectar()) {
        //     return $this->errorConectarBd;
        // }

        $sql = "SELECT 
                uaa_codigo UaaCodigo, uaa_nombre UaaNombre, uaa_nombre_corto UaaNombreCorto
            FROM uaa 
            WHERE uat_codigo = 1 AND
                uaa_nombre != 'desconocido'
            ORDER BY uaa.uaa_nombre_corto ASC
        ";

        //verificamos que se pueda realizar la consulta
        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error en consultar las facultades.";
            return $this->errorConsultarBd;
        }

        $r_facultades = $this->cnx->json; //almacenamos la respuesta
        $arrayFinal = array(); //array para almacenar la respuesta

        foreach ($r_facultades as $facultad) {
            $array = [ //Organizamos un array con los datos de la facultad
                "UaaCodigo" => utf8_decode($facultad['UaaCodigo']),
                "UaaNombre" => utf8_decode($facultad['UaaNombre']),
                "UaaNombreCorto" => utf8_decode($facultad['UaaNombreCorto']),
                "UaaUnificada" => []
            ];
            //Almacenamos en el array final la facultad
            $arrayFinal[$facultad['UaaCodigo']] = array_map('utf8_encode', $array);

            //Consulta para obtener las uaa unificadas de la facultad que se esta iterando.
            $sql = "SELECT 
                    uaa.uaa_codigo UaaCodigo, 
                    uaa.uaa_nombre UaaNombre, 
                    uaa.uaa_nombre_corto UaaNombreCorto
                FROM 
                    uaa
                WHERE 
                    uaa.uat_codigo = 24
                    AND uaa.uaa_estado = 1
                    AND (
                        uaa.uaa_dependencia = {$facultad['UaaCodigo']}
                        OR uaa.uaa_dependencia IN (
                            SELECT udep.uaa_codigo
                            FROM uaa udep
                            WHERE udep.uaa_dependencia = {$facultad['UaaCodigo']}
                                AND udep.uat_codigo = 3
                                AND udep.uaa_estado = 1
                        )
                    )
                ORDER BY uaa.uaa_nombre_corto ASC
            ";

            //verificamos que se pueda realizar la consulta
            if (!$this->cnx->consultar($sql)) {
                $this->errorConsultarBd["consola"] = "Error en consultar las unidades unificadas.";
                return $this->errorConsultarBd;
            }

            $r_uaa_unificada = $this->cnx->json; //almacenamos la respuesta

            foreach ($r_uaa_unificada as $uaa_unificada) {
                $array = [ //Organizamos un array con los datos de la uaa unificada
                    "UaaCodigo" => utf8_decode($uaa_unificada['UaaCodigo']),
                    "UaaNombre" => utf8_decode($uaa_unificada['UaaNombre']),
                    "UaaNombreCorto" => utf8_decode($uaa_unificada['UaaNombreCorto']),
                    "UaaPrograma" => []
                ];
                //Almacenamos la unidad unificada en la facultad correspondiente
                $arrayFinal[$facultad['UaaCodigo']]['UaaUnificada'][$uaa_unificada['UaaCodigo']] = array_map('utf8_encode', $array);

                //Consulta para obtener los programas relacionados a la uaa unificada que se esta iterando
                //12,13,14,19 Nivel academico de postgrados
                $sql = "SELECT 
                    programa.pro_codigo ProCodigo, 
                    programa.uaa_codigo UaaCodigo, 
                    uaa.uaa_nombre UaaNombre, 
                    uaa.uaa_nombre_corto UaaNombreCorto,
                    CASE WHEN nia.nia_codigo in (12,13,14,19) THEN 'Postgrado' ELSE 'Pregrado' END as Nivel
                FROM 
                    programa
                INNER JOIN uaa ON uaa.uaa_codigo = programa.uaa_codigo
                INNER JOIN nivel_academico nia ON nia.nia_codigo = programa.nia_codigo
                WHERE 
                    uaa_codigo_unificado = {$uaa_unificada['UaaCodigo']}
                ORDER BY uaa.uaa_nombre_corto ASC
                ";

                //verificamos que se pueda realizar la consulta
                if (!$this->cnx->consultar($sql)) {
                    $this->errorConsultarBd["consola"] = "Error en consultar los programas.";
                    return $this->errorConsultarBd;
                }

                $r_programa = $this->cnx->json; //almacenamos la respuesta

                foreach ($r_programa as $programa) {
                    $array = [ //Organizamos un array con los datos del programa
                        "ProCodigo" => utf8_decode($programa['ProCodigo']),
                        "UaaCodigo" => utf8_decode($programa['UaaCodigo']),
                        "UaaNombre" => utf8_decode($programa['UaaNombre']),
                        "UaaNombreCorto" => utf8_decode($programa['UaaNombreCorto']),
                        "Nivel" => utf8_decode($programa['Nivel'])
                    ];
                    //Almacenamos el programa en la unidad unificada
                    $arrayFinal[$facultad['UaaCodigo']]['UaaUnificada'][$uaa_unificada['UaaCodigo']]['UaaPrograma'][$programa['UaaCodigo']] = array_map('utf8_encode', $array);
                }
            }
        }

        $sql = "SELECT 
                uaa.uaa_codigo UaaCodigo, 
                uaa.uaa_nombre_corto UaaNombreCorto, 
                uaa.uaa_nombre UaaNombre
            FROM
                uaa
            WHERE
                uaa.uaa_codigo in (329,330,331,340,328,21,19,20,21,22,23,24,25,774)
        ";

        //verificamos que se pueda realizar la consulta
        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error en consultar uaa especiales (dptos y facultades).";
            return $this->errorConsultarBd;
        }

        $arrayEspecial = $this->cnx->json;

        return array(
            "resultado" => true,
            "mensaje" => "Unidades consultadas correctamente.",
            "data" => $arrayFinal,
            "data2" => $arrayEspecial
        );
    }

    // Consultar tipos de solicitud para aperturas de solicitudes
    public function consultarTiposSolicitud()
    {
        $sql = "SELECT 
                    pts.pts_codigo PtsCodigo,
                    pts.pts_nombre PtsNombre,
                    pts.pts_estado PtsEstado
                FROM 
                    programacionacademica.programacion_tipo_solicitudes pts
                WHERE 
                    pts.pts_estado = 1
                    AND pts.pts_codigo > 1
                ORDER BY pts.pts_codigo ASC";
        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar los tipos de solicitud.";
            return $this->errorConsultarBd;
        }
        return array(
            "resultado" => true,
            "mensaje" => "Tipos de solicitud consultados correctamente.",
            "data" => $this->cnx->json
        );
    }

    // Guardar apertura de solicitudes (por UAA, tipo, calendario y fechas)
    public function guardarAperturaSolicitudes($obj)
    {
        if (!isset($obj->UaaSeleccionadas) || count($obj->UaaSeleccionadas) <= 0) {
            return array(
                "resultado" => false,
                "mensaje" => "No se ha seleccionado ninguna unidad.",
                "consola" => "UaaSeleccionadas no se envió o viene vacío."
            );
        }

        if (!isset($obj->TiposSeleccionados) || count($obj->TiposSeleccionados) <= 0) {
            return array(
                "resultado" => false,
                "mensaje" => "No se ha seleccionado ningún tipo de solicitud.",
                "consola" => "TiposSeleccionados no se envió o viene vacío."
            );
        }

        if (!isset($obj->CalendarioCodigo) || !is_numeric($obj->CalendarioCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar un calendario válido.",
                "consola" => "CalendarioCodigo no es numérico."
            );
        }

        $obj->HoraInicial = date("H:i:s", strtotime($obj->HoraInicial));
        $obj->HoraFinal = date("H:i:s", strtotime($obj->HoraFinal));
        $obj->FechaInicial .= "T" . $obj->HoraInicial . ".000";
        $obj->FechaFinal .= "T" . $obj->HoraFinal . ".000";
        $fechaInicialSql = FechaSqlServer::toSqlDateTime2($obj->FechaInicial, false);
        $fechaFinalSql = FechaSqlServer::toSqlDateTime2($obj->FechaFinal, false);
        if ($fechaInicialSql === false || $fechaFinalSql === false) {
            return array(
                "resultado" => false,
                "mensaje" => "Formato de fecha inválido para apertura de solicitudes.",
                "consola" => "No se pudieron preparar fechas SQL ({$obj->FechaInicial} - {$obj->FechaFinal}).",
            );
        }

        $this->cnx->Sentencia("BEGIN TRAN");

        foreach ($obj->UaaSeleccionadas as $uaa) {
            foreach ($obj->TiposSeleccionados as $tipo) {
                $TipoCodigo = intval($tipo);
                // Para conservar historial completo, se desactivan aperturas vigentes del mismo contexto
                // y se inserta una nueva fila en lugar de sobrescribir.
                $sql = "UPDATE programacionacademica.programacion_gestion
                        SET prg_estado = 0
                        WHERE
                            uaa_codigo = {$uaa->UaaCodigo}
                            AND pts_codigo = {$TipoCodigo}
                            AND cal_codigo = {$obj->CalendarioCodigo}
                            AND prg_estado = 1";

                if (!$this->cnx->Sentencia($sql)) {
                    $this->errorSentenciaBd["mensaje"] = "Error al preparar historial de apertura de solicitudes de {$uaa->UaaNombre}.";
                    $this->errorSentenciaBd["consola"] = "No se pudieron desactivar aperturas previas para la unidad ({$uaa->UaaCodigo}), tipo ({$TipoCodigo}) y calendario ({$obj->CalendarioCodigo}).";
                    $this->cnx->Sentencia("ROLLBACK TRAN");
                    return $this->errorSentenciaBd;
                }

                $sql = "INSERT INTO programacionacademica.programacion_gestion (uaa_codigo, pts_codigo, cal_codigo, prg_fecha_inicio, prg_fecha_fin, prg_estado) VALUES ({$uaa->UaaCodigo}, {$TipoCodigo}, {$obj->CalendarioCodigo}, {$fechaInicialSql}, {$fechaFinalSql}, 1)";
                if (!$this->cnx->Sentencia($sql)) {
                    $this->errorSentenciaBd["mensaje"] = "Error al crear la apertura de solicitudes de {$uaa->UaaNombre}.";
                    $this->errorSentenciaBd["consola"] = "No se pudo insertar la apertura.";
                    $this->cnx->Sentencia("ROLLBACK TRAN");
                    return $this->errorSentenciaBd;
                }
            }
        }
        $this->cnx->Sentencia("COMMIT TRAN");
        if ($obj->Correo == "1") {
            $correos = $this->enviarCorreosSolicitudes($obj);
            if ($correos["resultado"] == false) {
                return array(
                    "resultado" => true,
                    "mensaje" => "Se guardaron las aperturas de solicitudes correctamente pero no se enviaron los correos correctamente."
                );
            }
            if ($correos["resultado"] == true) {
                return array(
                    "resultado" => true,
                    "mensaje" => "Se guardaron las aperturas de solicitudes correctamente y {$correos["mensaje"]}."
                );
            }
        }
        return array(
            "resultado" => true,
            "mensaje" => "Se guardaron las aperturas de solicitudes correctamente."
        );
    }

    // Consultar aperturas de solicitudes por UAA
    public function consultarAperturaSolicitudes($obj)
    {
        if (!isset($obj->UaaCodigo) || !is_numeric($obj->UaaCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar una unidad académica válida.",
                "consola" => "UaaCodigo no viene o no es numérico."
            );
        }

        $sql = "SELECT 
                    prg.prg_codigo PrsCodigo, 
                    prg.prg_fecha_inicio PrsFechaInicio, 
                    prg.prg_fecha_fin PrsFechaFin, 
                    prg.prg_estado PrsEstado, 
                    prg.uaa_codigo UaaCodigo, 
                    pts.pts_codigo PtsCodigo,
                    pts.pts_nombre PtsNombre,
                    cal.cal_codigo CalCodigo,
                    cal.cal_nombre CalNombre, 
                    per.per_fecha_inicio PerFechaInicio, 
                    per.per_fecha_fin PerFechaFin, 
                    per.per_codigo PerCodigo, 
                    per.per_nombre PerNombre 
                FROM 
                    programacionacademica.programacion_gestion prg
                INNER JOIN programacionacademica.programacion_tipo_solicitudes pts ON pts.pts_codigo = prg.pts_codigo 
                INNER JOIN calendario cal ON cal.cal_codigo = prg.cal_codigo 
                INNER JOIN periodo per ON cal.per_codigo = per.per_codigo 
                WHERE prg.uaa_codigo = {$obj->UaaCodigo}
                    AND prg.pts_codigo > 1
                ORDER BY cal.cal_codigo DESC, pts.pts_codigo ASC";
        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar las aperturas de solicitudes.";
            return $this->errorConsultarBd;
        }
        $r_apertura = $this->cnx->json;
        for ($i = 0; $i < count($r_apertura); $i++) {
            $this->completarEstadoApertura($r_apertura[$i], 'PrsEstado', 'PrsFechaInicio', 'PrsFechaFin');
            $r_apertura[$i]['PrsFechaInicio'] = date("Y-m-d H:i", strtotime($r_apertura[$i]['PrsFechaInicio']));
            $r_apertura[$i]['PrsFechaFin'] = date("Y-m-d H:i", strtotime($r_apertura[$i]['PrsFechaFin']));
            $r_apertura[$i]['PerFechaInicio'] = date("Y-m-d H:i", strtotime($r_apertura[$i]['PerFechaInicio']));
            $r_apertura[$i]['PerFechaFin'] = date("Y-m-d H:i", strtotime($r_apertura[$i]['PerFechaFin']));
        }
        return array(
            "resultado" => true,
            "mensaje" => "Aperturas de solicitudes consultadas correctamente.",
            "data" => $r_apertura
        );
    }

    // Consultar historial consolidado por periodo (programación, gestión y solicitudes)
    public function consultarHistorialPeriodo($obj)
    {
        if (!isset($obj->PerCodigo) || !is_numeric($obj->PerCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar un periodo académico válido.",
                "consola" => "PerCodigo no viene o no es numérico."
            );
        }

        $PerCodigo = intval($obj->PerCodigo);
        $whereGrupo = "";

        if (isset($obj->PgrCodigo) && is_numeric($obj->PgrCodigo) && intval($obj->PgrCodigo) > 0) {
            $PgrCodigo = intval($obj->PgrCodigo);
            $whereGrupo = " AND uaa.uaa_codigo IN (
                                SELECT gui.uaa_codigo
                                FROM programacionacademica.grupo_uaa_item gui
                                WHERE gui.pgr_codigo = {$PgrCodigo} AND gui.gui_estado = 1
                            ) ";
        }

        $sql = "SELECT * FROM (
                    SELECT 
                        'PROGRAMACION' TipoApertura,
                        pra.pra_codigo CodigoApertura,
                        pra.pra_estado EstadoApertura,
                        pra.pra_fecha_inicio FechaInicio,
                        pra.pra_fecha_fin FechaFin,
                        uaa.uaa_codigo UaaCodigo,
                        uaa.uaa_nombre UaaNombre,
                        uaa.uaa_nombre_corto UaaNombreCorto,
                        cal.cal_codigo CalCodigo,
                        cal.cal_nombre CalNombre,
                        prp.prp_nombre Detalle
                    FROM programacionacademica.programacion_academica pra
                    INNER JOIN calendario cal ON cal.cal_codigo = pra.cal_codigo
                    INNER JOIN periodo per ON per.per_codigo = cal.per_codigo
                    INNER JOIN uaa ON uaa.uaa_codigo = pra.uaa_codigo
                    INNER JOIN programacion_proceso prp ON prp.prp_codigo = pra.prp_codigo
                    WHERE per.per_codigo = {$PerCodigo}
                    {$whereGrupo}

                    UNION ALL

                    SELECT 
                        'GESTION' TipoApertura,
                        prg.prg_codigo CodigoApertura,
                        prg.prg_estado EstadoApertura,
                        prg.prg_fecha_inicio FechaInicio,
                        prg.prg_fecha_fin FechaFin,
                        uaa.uaa_codigo UaaCodigo,
                        uaa.uaa_nombre UaaNombre,
                        uaa.uaa_nombre_corto UaaNombreCorto,
                        cal.cal_codigo CalCodigo,
                        cal.cal_nombre CalNombre,
                        'ADMINISTRADOR SECRETARIAS' Detalle
                    FROM programacionacademica.programacion_gestion prg
                    INNER JOIN calendario cal ON cal.cal_codigo = prg.cal_codigo
                    INNER JOIN periodo per ON per.per_codigo = cal.per_codigo
                    INNER JOIN uaa ON uaa.uaa_codigo = prg.uaa_codigo
                    WHERE per.per_codigo = {$PerCodigo}
                    AND prg.pts_codigo = 1
                    {$whereGrupo}

                    UNION ALL

                    SELECT 
                        'SOLICITUDES' TipoApertura,
                        prg.prg_codigo CodigoApertura,
                        prg.prg_estado EstadoApertura,
                        prg.prg_fecha_inicio FechaInicio,
                        prg.prg_fecha_fin FechaFin,
                        uaa.uaa_codigo UaaCodigo,
                        uaa.uaa_nombre UaaNombre,
                        uaa.uaa_nombre_corto UaaNombreCorto,
                        cal.cal_codigo CalCodigo,
                        cal.cal_nombre CalNombre,
                        pts.pts_nombre Detalle
                    FROM programacionacademica.programacion_gestion prg
                    INNER JOIN programacionacademica.programacion_tipo_solicitudes pts ON pts.pts_codigo = prg.pts_codigo
                    INNER JOIN calendario cal ON cal.cal_codigo = prg.cal_codigo
                    INNER JOIN periodo per ON per.per_codigo = cal.per_codigo
                    INNER JOIN uaa ON uaa.uaa_codigo = prg.uaa_codigo
                    WHERE per.per_codigo = {$PerCodigo}
                    AND prg.pts_codigo > 1
                    {$whereGrupo}
                ) t
                ORDER BY t.FechaFin DESC";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar historial consolidado por periodo.";
            $this->errorConsultarBd["sql"] = $sql;
            return $this->errorConsultarBd;
        }

        $data = $this->cnx->json;
        for ($i = 0; $i < count($data); $i++) {
            $fechaInicio = $data[$i]['FechaInicio'];
            $fechaFin = $data[$i]['FechaFin'];

            $this->completarEstadoApertura($data[$i], 'EstadoApertura', 'FechaInicio', 'FechaFin');
            $data[$i]['FechaInicio'] = date("Y-m-d H:i", strtotime($fechaInicio));
            $data[$i]['FechaFin'] = date("Y-m-d H:i", strtotime($fechaFin));
        }

        usort($data, function ($a, $b) {
            if ($a['ActivaAhora'] != $b['ActivaAhora']) {
                return $b['ActivaAhora'] <=> $a['ActivaAhora'];
            }
            return strcmp($b['FechaFin'], $a['FechaFin']);
        });

        return array(
            "resultado" => true,
            "mensaje" => "Historial por periodo consultado correctamente.",
            "data" => $data
        );
    }

    // Eliminar apertura de solicitudes (soft delete)
    public function eliminarAperturaSolicitudes($obj)
    {
        if (!isset($obj->PrsCodigo) || !is_numeric($obj->PrsCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar una apertura válida.",
                "consola" => "PrsCodigo no viene o no es numérico."
            );
        }

        $this->cnx->Sentencia("BEGIN TRAN");
        $sql = "UPDATE programacionacademica.programacion_gestion SET prg_estado = 0 WHERE prg_codigo = {$obj->PrsCodigo} AND pts_codigo > 1";
        if (!$this->cnx->Sentencia($sql)) {
            $dbError = isset($this->cnx->mjeError) ? $this->cnx->mjeError : "Sin detalle en cls_config::sentencia";
            $this->errorSentenciaBd["mensaje"] = "Error al desactivar la apertura de solicitudes.";
            $this->errorSentenciaBd["consola"] = "No se pudo realizar el update a la apertura: {$obj->PrsCodigo}. Detalle BD: {$dbError}";
            $this->errorSentenciaBd["sql"] = $sql;
            $this->cnx->Sentencia("ROLLBACK TRAN");
            return $this->errorSentenciaBd;
        }
        $this->cnx->Sentencia("COMMIT TRAN");
        return array(
            "resultado" => true,
            "mensaje" => "Se desactivó correctamente."
        );
    }

    // Consultar apertura activa de solicitudes (para validación backend)
    public function consultarAperturaSolicitudActiva($obj)
    {
        if (!isset($obj->UaaCodigos) || !is_array($obj->UaaCodigos) || count($obj->UaaCodigos) <= 0) {
            return array(
                "resultado" => false,
                "mensaje" => "No se enviaron unidades para validar apertura activa.",
                "consola" => "UaaCodigos no existe o está vacío."
            );
        }

        if (!isset($obj->PtsCodigo) || !is_numeric($obj->PtsCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envió el tipo de solicitud para validar apertura activa.",
                "consola" => "PtsCodigo no existe o no es numérico."
            );
        }

        $uaas = implode(',', array_map('intval', $obj->UaaCodigos));
        $pts = intval($obj->PtsCodigo);
        $now = date('Y-m-d\TH:i:s');
        $nowSql = FechaSqlServer::toSqlDateTime2($now, false);
        if ($nowSql === false) {
            return array(
                "resultado" => false,
                "mensaje" => "Formato de fecha inválido para validar aperturas activas.",
                "consola" => "No se pudo preparar la fecha actual ({$now}) para SQL Server.",
            );
        }
        $sql = "SELECT TOP 1
                    prg.prg_codigo PrsCodigo,
                    per.per_codigo PerCodigo
                FROM programacionacademica.programacion_gestion prg
                INNER JOIN calendario cal ON cal.cal_codigo = prg.cal_codigo
                INNER JOIN periodo per ON per.per_codigo = cal.per_codigo
                WHERE 
                    prg.prg_estado = 1 
                    AND prg.pts_codigo = {$pts}
                    AND prg.uaa_codigo IN ({$uaas})
                    AND {$nowSql} BETWEEN prg.prg_fecha_inicio AND prg.prg_fecha_fin
                ORDER BY prg.prg_codigo DESC";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar apertura activa de solicitudes.";
            return $this->errorConsultarBd;
        }

        $data = $this->cnx->json;

        return array(
            "resultado" => true,
            "activa" => count($data) > 0,
            "data" => count($data) > 0 ? $data[0] : null
        );
    }

    // Enviar correos para apertura de solicitudes (adaptado de enviarCorreos)
    public function enviarCorreosSolicitudes($obj)
    {
        $implode_uaa = "";
        $nombres_uaa = "";
        $primer_uaa = true;
        $CalNombre = "";
        $sql = "SELECT cal.cal_nombre CalNombre FROM calendario cal where cal_codigo = {$obj->CalendarioCodigo}";
        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar los detalles del calendario: {$obj->CalendarioCodigo}.";
            return $this->errorConsultarBd;
        }
        $r_calendario = $this->cnx->json;
        if (count($r_calendario) > 0) {
            $CalNombre = $r_calendario[0]["CalNombre"];
        }
        foreach ($obj->UaaSeleccionadas as $uaa) {
            $sql = "SELECT uaa.uaa_codigo UaaCodigo, uaa.uaa_nombre_corto UaaNombreCorto FROM uaa WHERE uaa.uaa_codigo = {$uaa->UaaCodigo}";
            if (!$this->cnx->consultar($sql)) {
                $this->errorConsultarBd["consola"] = "Error al consultar los detalles de la uaa: {$uaa->UaaCodigo}.";
                return $this->errorConsultarBd;
            }
            $r_uaa = $this->cnx->json;
            foreach ($r_uaa as $detalle_uaa) {
                $uaa_codigo = $detalle_uaa["UaaCodigo"];
                $uaa_nombre = $detalle_uaa["UaaNombreCorto"];
            }
            if ($primer_uaa == true) {
                $implode_uaa .= $uaa_codigo;
                $primer_uaa = false;
            } else {
                $implode_uaa .= "," . $uaa_codigo;
            }
            $nombres_uaa .= "- " . $uaa_codigo . ". " . $uaa_nombre . "\n";
        }
        $sql = "SELECT usu_programac.usg_usuario, uad.uid, per.per_email_interno, per.per_nombre+' '+per.per_apellido as nombre from ( select distinct usg_usuario from usuario_grupo usg where usg.usg_estado = 1 and usg.usg_grupo in (68,69) and usg.usg_uaa in ( select uaa_codigo_unificado from programa pro inner join uaa on uaa.uaa_codigo = pro.uaa_codigo and pro.uaa_codigo in ({$implode_uaa}) ) ) as usu_programac inner join ( select up, uid from usuario_administrativo group by up, uid union select up, uid from usuario_docente group by up, uid ) as uad on uad.uid = usu_programac.usg_usuario inner join persona per on per.per_codigo=uad.up union select uad.usg_usuario, uad.uid, per.per_email_interno, per.per_nombre+' '+per.per_apellido as nombre from usuario_administrativo uad inner join persona per on per.per_codigo=uad.up where uad.usg_estado = 1 and uad.usg_grupo = 69 order by nombre";
        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar el correo interno del usuario de la uaa: {$implode_uaa}.";
            return $this->errorConsultarBd;
        }
        $r_correos = $this->cnx->json;
        $correos = array();
        foreach ($r_correos as $correo) {
            $temp = array();
            $temp['PerEmail'] = $correo['per_email_interno'];
            $temp['PerNombre'] = $correo['nombre'];
            array_push($correos, $temp);
        }
        if (count($correos) < 1) {
            return array(
                "resultado" => false,
                "mensaje" => "No se encontraron correos."
            );
        }
        // Obtener nombres de tipos seleccionados
        $tiposNombres = [];
        if ($obj->TiposSeleccionados) {
            foreach ($obj->TiposSeleccionados as $tipo) {
                $sql = "SELECT pts_nombre FROM programacionacademica.programacion_tipo_solicitudes WHERE pts_codigo = {$tipo}";
                if ($this->cnx->consultar($sql) && count($this->cnx->json)) {
                    $tiposNombres[] = $this->cnx->json[0]['pts_nombre'];
                }
            }
        }
        $procesos = implode(', ', $tiposNombres);
        $parametros_correo = array(
            "listadoCorreos" => $correos,
            "procesos" => $procesos,
            "fechaInicio" => $obj->FechaInicial,
            "fechaFin" => $obj->FechaFinal,
            "textoUaasMarcadas" => $nombres_uaa,
            "CalNombre" => $CalNombre
        );
        require_once "../correos/correo_apertura.php";
        $ca = new Correo_apertura();
        $resultado = $ca->enviarCorreoAperturaProgramacion($parametros_correo);
        return $resultado;
    }

    // Modificar periodo activo modulo solicitudes (TODO: eliminar cuando se complete migración)
    public function modificarPeriodoActivo($obj) {
        if (!isset($obj->PpeCodigo) || !is_numeric($obj->PpeCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar un periodo válido.",
                "consola" => "El código del periodo no es numérico o no se envió."
            );
        }

        $PpeCodigo = intval($obj->PpeCodigo);
        $sql = "UPDATE web_parametro
                SET  wep_valor='{$PpeCodigo}'
                WHERE wep_codigo=550";

        if (!$this->cnx->Sentencia($sql)) {
            $this->errorSentenciaBd["mensaje"] = "Error al modificar el periodo activo de solicitudes.";
            $this->errorSentenciaBd["consola"] = "No se pudo actualizar web_parametro(550) con el periodo {$PpeCodigo}.";
            return $this->errorSentenciaBd;
        }

        return array(
            "resultado" => true,
            "mensaje" => "Periodo modificado correctamente."
        );
    }
}
