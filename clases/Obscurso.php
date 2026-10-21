<?php
date_default_timezone_set('America/Bogota');
class Obscurso
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

    public function actualizarCoordinador($obj)
    {
        //Validaciones
        if (!isset($obj->CurCodigo) || !is_numeric($obj->CurCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo del curso.",
                "consola" => "El codigo del curso no viene o no es numerico, " . $obj->CurCodigo,
            );
        }

        if (!isset($obj->UapCodigo) || !is_numeric($obj->UapCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo de la vinculación del docente.",
                "consola" => "El codigo de la vinculación no viene o no es numerico, " . $obj->UapCodigo,
            );
        }

        //Asignaciones
        $CurCodigo = $obj->CurCodigo; // Contiene el codigo del curso seleccionado.
        $UapCodigo = $obj->UapCodigo; // Contiene el codigo de la vinculacion del docente seleccionado. 

        $sql = "UPDATE
                curso
            SET
                uap_codigo = {$UapCodigo},
                cur_fecha_actualizacion = GETDATE()
            WHERE
                cur_codigo = {$CurCodigo}
        ";

        if (!$this->cnx->sentencia($sql)) {
            $this->errorSentenciaBd["mensaje"] = "Error al actualizar el coordinador. Recargue la página e intente de nuevo.";
            $this->errorSentenciaBd["consola"] = "Ha fallado la actualización del coordinador {$UapCodigo} del curso {$CurCodigo}.";
            return $this->errorSentenciaBd;
        }

        return array(
            "resultado" => true,
            "mensaje" => "Coordinador actualizado correctamente."
        );

    }

    public function actualizarObservacion($obj)
    {
        //Validaciones
        if (!isset($obj->CurCodigo) || !is_numeric($obj->CurCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo del curso.",
                "consola" => "El codigo del curso no viene o no es numerico, " . $obj->CurCodigo,
            );
        }

        if (!isset($obj->CurObservaciones)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el la observación del curso."
            );
        }

        //Asignaciones
        $CurCodigo = $obj->CurCodigo; // Contiene el codigo del curso seleccionado.
        $CurObservaciones = trim($obj->CurObservaciones); // Contiene la observación del curso. 

        $sql = "UPDATE
                curso
            SET
                cur_observaciones = '{$CurObservaciones}',
                cur_fecha_actualizacion = GETDATE()
            WHERE
                cur_codigo = {$CurCodigo}
        ";

        if (!$this->cnx->sentencia($sql)) {
            $this->errorSentenciaBd["mensaje"] = "Error al actualizar la observación. Recargue la página e intente de nuevo.";
            $this->errorSentenciaBd["consola"] = "Ha fallado la actualización de la observación del curso seleccionado.";
            return $this->errorSentenciaBd;
        }

        return array(
            "resultado" => true,
            "mensaje" => "Observación actualizada correctamente."
        );
    }
}
