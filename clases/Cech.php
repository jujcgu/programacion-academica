<?php
date_default_timezone_set('America/Bogota');

class Cech
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
        "mensaje" => "Error al realizar la acción en la base de datos",
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

    public function consultarCursosEliminadosConHorario($obj)
    {
        // Validamos las variables recibidas que exista y que sea numerico
        if (!isset($obj->CalCodigo) || !is_numeric($obj->CalCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar un calendario.",
                "consola" => "El código del calendario no es numerico o no hay número",
            );
        }

        $CalCodigo = $obj->CalCodigo; // Codigo del calendario a buscar.

        $sql = "SELECT
                curso.cur_codigo CurCodigo, 
                curso.cur_cupo CurCupo,
                curso.cur_semanas CurSemanas,
                curso.cur_observaciones CurObservaciones,
                asi.asi_nombre_corto AsiNombreCorto,
                asi.asi_nombre AsiNombre,
                eso.esp_codigo EspCodigo, 
                esp.esp_nombre EspNombre, 
                esp.esp_nombre_corto EspNombreCorto, 
                eso.eso_subgrupo EsoSubgrupo, 
                eso.dia_codigo DiaCodigo, 
                dia.dia_nombre DiaNombre, 
                eso.hra_codigo HraCodigo, 
                hra.hra_inicio HraInicio, 
                hra.hra_fin HraFin,
                (SELECT COUNT(*) FROM matricula_curso mac WHERE mac.cur_codigo = curso.cur_codigo AND mac.maa_codigo IN (1,2)) TotalMatriculados,
                tic.tic_nombre TicNombre,
                uaa.uaa_codigo UaaCodigo,
                CONVERT(varchar,uaa.uaa_codigo) + '. ' + uaa.uaa_nombre_corto UaaCodigoNombre,
                uaa.uaa_nombre_corto UaaNombreCorto,
                per.per_nombre + ' ' + per.per_apellido PerNombreApellido,
                per.per_identificacion PerIdentificacion,
                vin.vin_nombre VinNombre,
                ded.ded_nombre DedNombre
            FROM curso 
            INNER JOIN espacio_ocupacion eso ON eso.eso_actividad = curso.cur_codigo
            INNER JOIN espacio esp ON esp.esp_codigo = eso.esp_codigo
            INNER JOIN asignatura asi ON asi.asi_codigo = curso.asi_codigo 
            INNER JOIN dia ON dia.dia_codigo = eso.dia_codigo
            INNER JOIN hora hra ON hra.hra_codigo = eso.hra_codigo
            INNER JOIN uaa on uaa.uaa_codigo = eso.uaa_codigo
            INNER JOIN tipo_curso tic ON tic.tic_codigo = curso.tic_codigo
            INNER JOIN uaa_personal uap ON uap.uap_codigo = eso.uap_codigo
            INNER JOIN persona per ON per.per_codigo = uap.per_codigo
            INNER JOIN vinculacion vin ON vin.vin_codigo = uap.vin_codigo
            INNER JOIN dedicacion ded ON ded.ded_codigo = uap.ded_codigo
            WHERE 
                cal_codigo = {$CalCodigo} AND cur_estado = 0
            GROUP BY
                curso.cur_codigo, 
                curso.cur_cupo,
                curso.cur_semanas,
                curso.cur_observaciones,
                asi.asi_nombre_corto,
                asi.asi_nombre,
                eso.esp_codigo, 
                esp.esp_nombre, 
                esp.esp_nombre_corto,
                eso.eso_subgrupo, 
                eso.dia_codigo, 
                dia.dia_nombre, 
                eso.hra_codigo, 
                hra.hra_inicio, 
                hra.hra_fin,
                tic.tic_nombre,
                uaa.uaa_codigo,
                CONVERT(varchar,uaa.uaa_codigo) + '. ' + uaa.uaa_nombre_corto,
                uaa.uaa_nombre_corto,
                per.per_nombre + ' ' + per.per_apellido,
                per.per_identificacion,
                vin.vin_nombre,
                ded.ded_nombre
            ORDER BY TotalMatriculados DESC, curso.cur_codigo DESC, eso.eso_subgrupo DESC
        ";

        //Se verifica que se ejecute la consulta
        if (!$this->cnx->Consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error en consultar los cursos eliminados con horario";
            return $this->errorConsultarBd;
        }

        //Se recorren los cursos para obtener l

        //Se almacenan los registros
        $array_cursos = array();
        foreach ($this->cnx->json as $curso){
            array_push($array_cursos, $curso["CurCodigo"]);
        }
        $count = count(array_unique($array_cursos));

        return array(
            "resultado" => true,
            "mensaje" => "Reporte consultado correctamente.",
            "data" => $this->cnx->json,
            "count" => $count
        );
    }
}
