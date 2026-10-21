<?php


class Cambiounidad
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

    public function cambiarUnidad($obj)
    {

        //Validacion
        if (!isset($obj->CurCodigo) || !is_numeric($obj->CurCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo del curso.",
                "consola" => "El codigo del curso no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->UaaCodigo) || !is_numeric($obj->UaaCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo de la unidad del docente.",
                "consola" => "El codigo de la unidad no es numérico o no se envio correctamente.",
            );
        }

        //Asignaciones
        $CurCodigo = $obj->CurCodigo; //Contiene el codigo del curso a cambiar
        $UaaCodigo = $obj->UaaCodigo; //Contiene la nueva unidad a cambiar

        $sql = "UPDATE
                espacio_ocupacion
            SET
                uaa_codigo = {$UaaCodigo}
            WHERE
                eso_actividad = {$CurCodigo}
            ";

        if (!$this->cnx->sentencia($sql)) {
            $this->errorSentenciaBd["mensaje"] = "Error al cambiar la unidad del curso seleccionado.";
            $this->errorSentenciaBd["consola"] = "Ha fallado la actualizacion de la unidad {$UaaCodigo} en el curso {$CurCodigo}.";
            return $this->errorSentenciaBd;
        }

        return array(
            "resultado" => true,
            "mensaje" => "Unidad actualizada correctamente."
        );
    }
}
