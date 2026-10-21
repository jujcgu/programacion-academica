<?php
date_default_timezone_set('America/Bogota');

class Csv
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

    //Permite consultar las modalidades de los cursos.
    public function consultarTipoCurso()
    {
        $sql = "SELECT 
                tic.tic_codigo TicCodigo,
                tic.tic_nombre TicNombre
            FROM 
                tipo_curso tic
        ";

        //Se verifica que se ejecute la consulta
        if (!$this->cnx->Consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error en consultar las modalidades de cursos.";
            return $this->errorConsultarBd;
        }

        return array(
            "resultado" => true,
            "mensaje" => "Modalidades consultadas correctamente.",
            "data" => $this->cnx->json,
        );
    }

    public function consultaCursosVirtuales($obj)
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
                cur.cur_codigo CurCodigo,
                cur.cur_semanas CurSemanas,
                eso.eso_subgrupo EsoSubgrupo,
                asi.asi_nombre_corto AsiNombreCorto,
                asi.asi_nombre AsiNombre,
                cur.cur_cupo CurCupo,
                tic.tic_nombre TicNombre,
                sed.sed_codigo SedCodigo,
                sed.sed_nombre SedNombre,
                uaa.uaa_codigo UaaCodigo,
                uaa.uaa_nombre_corto UaaNombreCorto,
                convert(varchar, uaa.uaa_codigo) + ' ' + uaa.uaa_nombre_corto UaaCodigoNombre,
                (SELECT COUNT(*) FROM matricula_curso mac WHERE mac.cur_codigo = cur.cur_codigo AND mac.maa_codigo IN (1,2)) TotalMatriculados,
                eso.dia_codigo DiaCodigo,
                dia.dia_nombre DiaNombre,
                eso.hra_codigo HraCodigo,
                hora.hra_inicio HraInicio,
                hora.hra_fin HraFin,
                per.per_nombre + ' ' + per.per_apellido PerNombreApellido,
                per.per_identificacion PerIdentificacion,
                vin.vin_nombre VinNombre,
                ded.ded_nombre DedNombre
            FROM curso cur 
            INNER JOIN asignatura asi ON asi.asi_codigo = cur.asi_codigo
            INNER JOIN uaa ON uaa.uaa_codigo = asi.uaa_codigo
            INNER JOIN tipo_curso tic ON tic.tic_codigo = cur.tic_codigo
            INNER JOIN espacio_ocupacion eso ON eso.eso_actividad = cur.cur_codigo
            INNER JOIN dia ON dia.dia_codigo = eso.dia_codigo
            INNER JOIN hora ON hora.hra_codigo = eso.hra_codigo
            INNER JOIN sede sed ON sed.sed_codigo = cur.sed_codigo 
            INNER JOIN uaa_personal uap ON uap.uap_codigo = eso.uap_codigo
            INNER JOIN persona per ON per.per_codigo = uap.per_codigo
            INNER JOIN vinculacion vin ON vin.vin_codigo = uap.vin_codigo
            INNER JOIN dedicacion ded ON ded.ded_codigo = uap.ded_codigo
            WHERE 
            cur.cal_codigo in ({$CalCodigo})
            AND cur.cur_estado = 1
            GROUP BY
                cur.cur_codigo,
                cur.cur_semanas,
                eso.eso_subgrupo,
                asi.asi_nombre_corto,
                asi.asi_nombre,
                cur.cur_cupo,
                tic.tic_nombre,
                sed.sed_codigo,
                sed.sed_nombre,
                uaa.uaa_codigo,
                uaa.uaa_nombre_corto,
                eso.dia_codigo,
                dia.dia_nombre,
                eso.hra_codigo,
                hora.hra_inicio,
                hora.hra_fin,
                per.per_nombre + ' ' + per.per_apellido,
                per.per_identificacion,
                vin.vin_nombre,
                ded.ded_nombre
        ";

        //Se verifica que se ejecute la consulta
        if (!$this->cnx->Consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error en consultar los cursos activos sin horario";
            return $this->errorConsultarBd;
        }

        //Se almacenan los registros
        $array_cursos = array();
        foreach ($this->cnx->json as $curso) {
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
