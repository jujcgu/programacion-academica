<?php

class Curesp
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

    private $calendarioActual = ""; //Almacena el parametro del calendario actual.

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

    //Inicio funcion consultarTipoCurso
    //Permite listar los tipos de curso disponible
    function consultarTipoCurso()
    {
        $sql = "SELECT 
            cut_codigo CutCodigo,
            cut_nombre CutNombre 
        FROM 
            curso_tipo 
        ORDER BY 
            cut_codigo";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar los tipos de curso.";
            return $this->errorConsultarBd;
        }
        $r_curso_tipo = $this->cnx->json;

        foreach($r_curso_tipo as $tipo){
            $tipo->CutNombre = utf8_encode($tipo->CutNombre);
        }

        return array(
            "resultado" => true,
            "mensaje" => "Tipos de curso consultados correctamente.",
            "data" => $this->cnx->json
        );
    }

    //Inicio funcion consultarTipoCursoActual
    //Permite consultar el tipo actual de un curso especifico
    function consultarTipoCursoActual($obj)
    {
        //Parametros
        $CurCodigo = $obj->CurCodigo; //Contiene el codigo del curso especifico.

        // Validamos las variables recibidas que exista y que sea numerico
        if (!isset($obj->CurCodigo) || !is_numeric($obj->CurCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo del curso.",
                "consola" => "El codigo del curso no viene o no es numerico, " . $obj->CurCodigo,
            );
        }

        $sql = "SELECT 
            cut.cut_codigo CutCodigo,
            cut.cut_nombre CutNombre
        FROM 
            curso cur
        INNER JOIN 
            curso_tipo cut ON cut.cut_codigo = cur.cut_codigo
        WHERE 
            cur.cur_codigo = {$CurCodigo} 
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar el tipo de curso actual.";
            return $this->errorConsultarBd;
        }

        return array(
            "resultado" => true,
            "mensaje" => "Tipo de curso actual consultados correctamente.",
            "data" => $this->cnx->json
        );
    }

    //Inicio funcion guardarTipoCursoActual
    //Permite actualizar el tipo de un curso especifico.
    function guardarTipoCursoActual($obj)
    {
        //Parametros
        $CurCodigo = $obj->CurCodigo; //Contiene el codigo del curso especifico.
        $CutCodigo = $obj->CutCodigo; //Contiene el codigo del tipo de curso seleccionado.

        // Validamos las variables recibidas que exista y que sea numerico
        if (!isset($CurCodigo) || !is_numeric($CurCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo del curso.",
                "consola" => "El codigo del curso no viene o no es numerico, " . $CurCodigo,
            );
        }

        if (!isset($CutCodigo) || !is_numeric($CutCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo del tipo de curso.",
                "consola" => "El codigo del tipo curso no viene o no es numerico, " . $CutCodigo,
            );
        }

        // Iniciamos la transacción en caso de algun fallo
        $this->cnx->sentencia("BEGIN TRAN");

        $sql = "UPDATE
            curso
        SET
            cut_codigo = {$CutCodigo},
            cur_fecha_actualizacion = GETDATE()
        WHERE
            cur_codigo = {$CurCodigo}
        ";

        // Ejecutamos la sentencia
        if (!$this->cnx->sentencia($sql)) {
            $this->errorSentenciaBd["mensaje"] = "Error al guardar el tipo de curso del curso {$CurCodigo}.";
            $this->errorSentenciaBd["consola"] = "No se puedo realizar la actualización del del tipo de curso del curso {$CurCodigo} tipo curso {$CutCodigo}.";
            $this->cnx->sentencia("ROLLBACK TRAN"); //Se realiza un rollback si se encuentra un error
            return $this->errorSentenciaBd;
        }

        $this->cnx->sentencia("COMMIT TRAN"); // De no encontrar errores guardamos el resultado

        return array(
            "resultado" => true,
            "mensaje" => "Se guardo correctamente el el tipo de curso del curso {$CurCodigo}."
        );
    }
}
