<?php
date_default_timezone_set('America/Bogota');
require_once(dirname(__FILE__) . '/servicios/FechaSqlServer.php');

class Peraca
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

    // Inicio funcion crearFechaPeriodo
    // Se usa para crear la fecha personalizada de un periodo para x numero de unidades
    public function crearFechaPeriodo($obj)
    {
        // Parametros:
        // $obj->UaaSeleccionadas: Un array que contiene las unidades seleccionadas
        // $obj->FechaInicial: Contiene la fecha de inicio en formato AAAA-MM-DD
        // $obj->FechaFinal: Contiene la fecha de fin en formato AAAA-MM-DD
        // $obj->PeriodoCodigo: Contiene el codigo del periodo seleccionado

        $fechaInicialSql = FechaSqlServer::toSqlDateTime2($obj->FechaInicial, false);
        $fechaFinalSql = FechaSqlServer::toSqlDateTime2($obj->FechaFinal, false);
        if ($fechaInicialSql === false || $fechaFinalSql === false) {
            return array(
                "resultado" => false,
                "mensaje" => "Formato de fecha inválido para periodo personalizado.",
                "consola" => "No se pudo convertir FechaInicial ({$obj->FechaInicial}) o FechaFinal ({$obj->FechaFinal}) a fecha válida."
            );
        }

        $this->cnx->Sentencia("BEGIN TRAN");

        // Recorremos todas las unidades que se seleccionaron
        foreach ($obj->UaaSeleccionadas as $uaa) {
            //Se realiza una busqueda por la unidad y el periodo, en caso de existir se realiza un update.
            //En caso de que no exista se realiza el insert.
            $sql = "SELECT peu_codigo PeuCodigo FROM programacionacademica.periodo_unidad WHERE 
                uaa_codigo = {$uaa->UaaCodigo} AND
                per_codigo = {$obj->PeriodoCodigo}
            ";

            //Realizamos la consulta de verificacion.
            if (!$this->cnx->consultar($sql)) {
                $this->errorConsultarBd["consola"] = "Error en consultar las fechas de periodos de {$uaa->UaaNombre}.";
                return $this->errorConsultarBd;
            }

            //Si encuentra registros se debe realizar un update
            if (count($this->cnx->json)) {
                $r_periodo_existente = $this->cnx->json; //almacenamos la respuecta de verificacion
                //Organizamos la sentencia de update para las fechas y activamos el estado por si es un registro que se habia desactivado
                // y no estar creando informacion duplicada sin necesidad
                $sql = "UPDATE 
                        programacionacademica.periodo_unidad 
                    SET
                        peu_fecha_inicio = {$fechaInicialSql},
                        peu_fecha_fin = {$fechaFinalSql},
                        peu_estado = 1
                    WHERE
                        peu_codigo = {$r_periodo_existente[0]['PeuCodigo']}
                ";
                //Se ejecuta el update y se verifica que se ejecuto correctamente.
                if (!$this->cnx->Sentencia($sql)) {
                    $this->errorSentenciaBd["mensaje"] = "Error al actualizar la fecha del periodo de {$uaa->UaaNombre}.";
                    $this->errorSentenciaBd["consola"] = "Se encontro una apertura ({$r_periodo_existente[0]['PeuCodigo']}) para la unidad ({$uaa->UaaCodigo}) y 
                        periodo ({$obj->PeriodoCodigo}), pero no se pudo realizar el update.";
                    $this->cnx->Sentencia("ROLLBACK TRAN"); //Se realiza un rollback si se encuentra un error
                    return $this->errorSentenciaBd;
                }
            } else {
                //En caso de no encontrar registro se debe realizar el insert
                $sql = "INSERT INTO programacionacademica.periodo_unidad(
                    uaa_codigo,
                    per_codigo,
                    peu_fecha_inicio,
                    peu_fecha_fin,
                    peu_estado
                )
                VALUES(
                    {$uaa->UaaCodigo},
                    {$obj->PeriodoCodigo},
                    {$fechaInicialSql},
                    {$fechaFinalSql},
                    1
                )";

                // Se ejecuta el insert y se vericica que se ejecuto correctamente.
                if (!$this->cnx->Sentencia($sql)) {
                    $this->errorSentenciaBd["mensaje"] = "Error al realizar la creacion de fecha del periodo de la unidad {$uaa->UaaNombre}.";
                    $this->errorSentenciaBd["consola"] = "No se ha pudo realizar el insert para la unidad ({$uaa->UaaCodigo}), 
                    periodo ({$obj->PeriodoCodigo})";
                    return $this->errorSentenciaBd;
                }
            }
        }

        //Si no se genera ningun error realizamos el commit tran para guardar todos 
        $this->cnx->Sentencia("COMMIT TRAN");

        return array(
            "resultado" => true,
            "mensaje" => "Se guardaron las fechas para el periodo correctamente."
        );
    }

    // Inicio funcion eliminarPeriodoUnidad
    // Se usa para eliminar (inactivar) la personalizacion de una fecha de un periodo para una unidad especifica.
    public function eliminarPeriodoUnidad($obj)
    {
        // Parametros:
        // $obj->PeuCodigo: Es el codigo de la tabla donde se guarda la fecha personalizada para esa unidad con ese periodo
        $this->cnx->Sentencia("BEGIN TRAN");

        $sql = "UPDATE 
                programacionacademica.periodo_unidad 
            SET
                peu_estado = 0
            WHERE
                peu_codigo = {$obj->PeuCodigo}
        ";

        //Se ejecuta el update y se verifica que se ejecuto correctamente.
        if (!$this->cnx->Sentencia($sql)) {
            $this->errorSentenciaBd["mensaje"] = "Error al desactivar el periodo {$obj->PerCodigo} de la unidad {$obj->UaaCodigo}.";
            $this->errorSentenciaBd["consola"] = "No se pudo realizar el update del periodo unidad: {$obj->PeuCodigo}";
            $this->cnx->Sentencia("ROLLBACK TRAN"); //Se realiza un rollback si se encuentra un error
            return $this->errorSentenciaBd;
        }

        $this->cnx->Sentencia("COMMIT TRAN");

        return array(
            "resultado" => true,
            'PruebaError' => "Error al desactivar el periodo {$obj->PerCodigo} de la unidad {$obj->UaaCodigo}.",
            "mensaje" => "Se desactivo correctamente."
        );
    }

    // Inicio funcion consultarPeriodosUnidad
    // Se usa para consultar las unidades que tengan fechas personalizadas para un periodo especifico.
    public function consultarPeriodosUnidad($obj)
    {
        // Parametros:
        // $obj->PerCodigo: El codigo del periodo seleccionado
        $sql = "SELECT 
                peu.peu_codigo PeuCodigo,
                
                uaa.uaa_codigo UaaCodigo,
                uaa.uaa_nombre UaaNombre,
                uaa.uaa_nombre_corto UaaNombreCorto,

                per.per_codigo PerCodigo,
                per.per_nombre PerNombre,
                per.per_fecha_inicio PerFechaInicio,
                per.per_fecha_fin PerFechaFin,
                LEFT(per.per_nombre, 4) AS PerAnio,
                per.per_periodo PerPeriodo,

                peu.peu_fecha_inicio PeuFechaInicio,
                peu.peu_fecha_fin PeuFechaFin,
                peu.peu_estado PeuEstado
            FROM
                programacionacademica.periodo_unidad peu
            INNER JOIN uaa ON uaa.uaa_codigo = peu.uaa_codigo
            INNER JOIN periodo per ON per.per_codigo = peu.per_codigo
            WHERE
                peu.per_codigo = {$obj->PerCodigo} 
                AND peu.peu_estado = 1
            ORDER BY 
                uaa.uaa_nombre_corto DESC
        ";

        //verificamos que se pueda realizar la consulta
        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error en consultar los periodos activos para una unidad.";
            return $this->errorConsultarBd;
        }

        $r_periodos = $this->cnx->json;

        for ($i = 0; $i < count($r_periodos); $i++) {
            $fecha_inicio = explode(" ", $r_periodos[$i]["PeuFechaInicio"]);
            $fecha_fin = explode(" ", $r_periodos[$i]["PeuFechaFin"]);

            $r_periodos[$i]["PeuFechaInicio"] = $fecha_inicio[0];
            $r_periodos[$i]["PeuFechaFin"] = $fecha_fin[0];
        }

        return array(
            "resultado" => true,
            "mensaje" => "Periodos por unidad consultadas correctamente.",
            "data" => $r_periodos
        );
    }

    //Inicio funcion consultarPeriodos
    //Se usa para consultar los periodos academicos activos.
    public function consultarPeriodos()
    {
        $sql = "SELECT 
                per_codigo PerCodigo,
                per_nombre PerNombre,
                per_periodo PerPeriodo,
                per_fecha_inicio PerFechaInicio,
                per_fecha_fin PerFechaFin,
                LEFT(per_nombre, 4) AS PerAnio
            FROM 
                periodo
            WHERE
                per_codigo != 76
            ORDER BY 
                per_nombre DESC
        ";

        //verificamos que se pueda realizar la consulta
        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error en consultar los periodos activos.";
            return $this->errorConsultarBd;
        }

        $r_periodos = $this->cnx->json;

        for ($i = 0; $i < count($r_periodos); $i++) {
            $fecha_inicio = explode(" ", $r_periodos[$i]["PerFechaInicio"]);
            $fecha_fin = explode(" ", $r_periodos[$i]["PerFechaFin"]);

            $r_periodos[$i]["PerFechaInicio"] = $fecha_inicio[0];
            $r_periodos[$i]["PerFechaFin"] = $fecha_fin[0];
        }

        return array(
            "resultado" => true,
            "mensaje" => "Aperturas de gestión consultadas correctamente.",
            "data" => $r_periodos
        );
    }
}
