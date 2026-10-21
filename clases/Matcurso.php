<?php

class Matcurso
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

    //Inicio funcion consultarMatriculadosCurso
    //Se usa para consultar los matriculados de un curso.
    function consultarMatriculadosCurso($obj)
    {
        // Validaciones
        if (!isset($obj->CurCodigo) || !is_numeric($obj->CurCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo del curso",
                "consola" => "El codigo del curso no viene o no es numerico, " . $obj->CurCodigo,
            );
        }

        $CurCodigo = $obj->CurCodigo; //Contiene el codigo del curso seleccionado
        $matriculados_activos = 0; //Contiene la cantidad total de matriculados
        $matriculados_covid = 0; //Contiene la cantidad total de matriculados que perdieron por covid
        $matriculados_cancelados = 0; //Contiene la cantidad total de matriculados que cancelaron
        $matriculados_total = 0; //Contiene la sumatoria total de los matriculados que ha tenido el curso.

        $sql = "SELECT 
            count(*) as matriculados_curso
		FROM 
            matricula_curso mac
		INNER JOIN matricula mat ON mac.mat_codigo = mat.mat_codigo
		WHERE 
            mac.cur_codigo = {$CurCodigo} 
            AND mat.mat_estado = 'A' 
            AND mac.maa_codigo IN (1,2)";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error en consulta matriculados curso";
            return $this->errorConsultarBd;
        }
        $matriculados_activos = $this->cnx->json[0]['matriculados_curso'];

        $sql = "SELECT 
            count(*) AS matriculados_curso
		FROM 
            matricula_curso mac
		INNER JOIN matricula mat ON mac.mat_codigo = mat.mat_codigo
		WHERE 
            mac.cur_codigo = {$CurCodigo} 
            AND mac.maa_codigo IN (6)";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error en consulta matriculados curso covid";
            return $this->errorConsultarBd;
        }
        $matriculados_covid = $this->cnx->json[0]['matriculados_curso'];

        $sql = "SELECT 
            count(*) as matriculados_curso
		FROM matricula_curso mac
		INNER JOIN matricula mat ON mac.mat_codigo = mat.mat_codigo
		WHERE 
            mac.cur_codigo = {$CurCodigo} 
            AND mac.maa_codigo IN (4)";

        if (!$this->cnx->Consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error en consulta matriculados curso";
            return $this->errorConsultarBd;
        }
        $matriculados_cancelados = $this->cnx->json[0]['matriculados_curso'];

        $matriculados_total = $matriculados_activos + $matriculados_covid + $matriculados_cancelados;

        return array(
            "resultado" => true,
            "matriculados_total" => $matriculados_total,
            "matriculados_activos" => $matriculados_activos,
            "matriculados_covid" => $matriculados_covid,
            "matriculados_cancelados" => $matriculados_cancelados,
        );
    }
}