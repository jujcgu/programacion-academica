<?php
date_default_timezone_set('America/Bogota');

class Confgen
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

    // Inicio funcion consultarTopeHorasCatedraticos
    // Se usa para consultar los topes de horas de la tabla web parametro
    public function consultarTopeHorasCatedraticos()
    {
        // Tope catedratico sedes
        $sql = "SELECT wep.wep_valor WepValor FROM web_parametro wep WHERE wep.wep_codigo = 210 ";
        //verificamos que se pueda realizar la consulta
        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error en consultar el tope de horas para catedraticos en sede.";
            return $this->errorConsultarBd;
        }
        $r_horasCatedraticosSede = $this->cnx->json;

        // Tope catedratico neiva
        $sql = "SELECT wep.wep_valor WepValor FROM web_parametro wep WHERE wep.wep_codigo = 485 ";

        //verificamos que se pueda realizar la consulta
        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error en consultar el tope de horas para catedraticos en neiva.";
            return $this->errorConsultarBd;
        }

        $r_horasCatedraticosNeiva = $this->cnx->json;
        

        return array(
            "resultado" => true,
            "mensaje" => "Calendarios consultadas correctamente.",
            "horasCatedraticoSede" => (int)$r_horasCatedraticosSede[0]["WepValor"],
            "horasCatedraticoNeiva" => (int)$r_horasCatedraticosNeiva[0]["WepValor"],
        );
    }

    // Inicio funcion actualizarTopeHorasCatedraticos
    // Se usa para actualizar los topes de horas de la tabla web parametro
    public function actualizarTopeHorasCatedraticos($obj)
    {
        if (!isset($obj->horasCatedraticoSede) || !is_numeric($obj->horasCatedraticoSede) || $obj->horasCatedraticoSede < 0) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe ingresar el tope de horas para catedraticos en las sedes.",
                "consola" => "Debe ingresar el tope de horas para catedraticos en las sedes.",
            );
        }

        if (!isset($obj->horasCatedraticoNeiva) || !is_numeric($obj->horasCatedraticoNeiva) || $obj->horasCatedraticoSede < 0) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe ingresar el tope de horas para catedraticos en Neiva.",
                "consola" => "Debe ingresar el tope de horas para catedraticos en Neiva.",
            );
        }

        // Tope catedratico sedes
        $sql = "UPDATE web_parametro SET wep_valor = {$obj->horasCatedraticoSede} WHERE wep_codigo = 210 ";
        if (!$this->cnx->sentencia($sql)) {
            $this->errorSentenciaBd["mensaje"] = "Error al actualizar el tope de horas para catedraticos en las sedes.";
            $this->errorSentenciaBd["consola"] = "Ha fallado la actualizacion de tope de horas para catedraticos en las sedes {$obj->horasCatedraticoSede}.";
            return $this->errorSentenciaBd;
        }
        
        // Tope catedratico neiva
        $sql = "UPDATE web_parametro SET wep_valor = {$obj->horasCatedraticoNeiva} WHERE wep_codigo = 485 ";
        if (!$this->cnx->sentencia($sql)) {
            $this->errorSentenciaBd["mensaje"] = "Error al actualizar el tope de horas para catedraticos en Neiva.";
            $this->errorSentenciaBd["consola"] = "Ha fallado la actualizacion de tope de horas para catedraticos en Neiva {$obj->horasCatedraticoNeiva}.";
            return $this->errorSentenciaBd;
        }

        return array(
            "resultado" => true,
            "mensaje" => "Tope de horas para catedraticos actualizada correctamente."
        );
    }

}
