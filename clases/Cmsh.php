<?php
date_default_timezone_set('America/Bogota');

class Cmsh
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

    public function consultarCursosSinMatriculadosConHorarios($obj)
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
                temp.eso_actividad EsoActividad,
                temp.eso_subgrupo EsoSubgrupo,
                case when temp.cur_estado = 0 then 'ELIMINADO' else 'ACTIVO' end CurEstado,
                temp.cur_cupo CurCupo,
                temp.cur_semanas CurSemanas,
                temp.tic_nombre TicNombre,
                temp.vin_nombre VinNombre,
                temp.ded_nombre DedNombre,
                temp.cur_observaciones CurObservaciones,
                temp.TotalMatriculados,
                temp.pernombreapellido PerNombreApellido,
                temp.per_identificacion PerIdentificacion,
                temp.asi_nombre_corto AsiNombreCorto,
                temp.asi_nombre AsiNombre,
                temp.dia_nombre DiaNombre,
                temp.hra_codigo HraCodigo,
                temp.hra_inicio HraInicio,
                temp.hra_fin HraFin,
                temp.esp_codigo EspCodigo,
                temp.esp_nombre EspNombre,
                temp.esp_nombre_corto EspNombreCorto,
                temp.sed_nombre SedNombre,
                temp.uaacodigonombre UaaCodigoNombre
            from (
                SELECT 
                    eso.eso_actividad,
                    eso.eso_subgrupo,
                    cur.cur_estado, 
                    cur.cur_cupo,
                    cur.cur_semanas,
                    cur.cur_observaciones,
                    tic.tic_nombre,
                    (
                        SELECT count(*) FROM
                        matricula_curso mac WHERE mac.cur_codigo = eso.eso_actividad and mac.maa_codigo in (1,2)
                    ) TotalMatriculados,
                    per.per_nombre + ' ' + per.per_apellido pernombreapellido,
                    per.per_identificacion,
                    vin.vin_nombre,
                    ded.ded_nombre,
                    asi.asi_nombre_corto,
                    asi.asi_nombre,
                    dia.dia_nombre,
                    hra.hra_codigo,
                    hra.hra_inicio,
                    hra.hra_fin,
                    esp.esp_codigo,
                    esp.esp_nombre,
                    esp.esp_nombre_corto,
                    sed.sed_nombre,
                    CONVERT(varchar, uaa.uaa_codigo) + '. ' + uaa.uaa_nombre_corto uaacodigonombre
                FROM
                    curso cur
                INNER JOIN tipo_curso tic ON tic.tic_codigo = cur.tic_codigo
                INNER JOIN espacio_ocupacion eso on cur.cur_codigo = eso.eso_actividad and cur.cal_codigo = {$CalCodigo}
                INNER JOIN asignatura asi on asi.asi_codigo = cur.asi_codigo
                INNER JOIN espacio esp on esp.esp_codigo = eso.esp_codigo
                INNER JOIN dia on dia.dia_codigo = eso.dia_codigo 
                INNER JOIN hora hra on hra.hra_codigo = eso.hra_codigo
                INNER JOIN uaa on uaa.uaa_codigo = eso.uaa_codigo
                INNER JOIN uaa_personal uap on uap.uap_codigo = eso.uap_codigo 
                INNER JOIN persona per on per.per_codigo = uap.per_codigo 
                INNER JOIN vinculacion vin on vin.vin_codigo = uap.vin_codigo 
                INNER JOIN dedicacion ded on ded.ded_codigo = uap.ded_codigo 
                INNER JOIN sede sed on sed.sed_codigo = cur.sed_codigo 
                GROUP BY 
                    eso.eso_actividad,
                    eso.eso_subgrupo,
                    cur.cur_estado, 
                    cur.cur_cupo,
                    cur.cur_semanas,
                    cur.cur_observaciones,
                    tic.tic_nombre,
                    per.per_nombre + ' ' + per.per_apellido,
                    per.per_identificacion,
                    vin.vin_nombre,
                    ded.ded_nombre,
                    asi.asi_nombre_corto,
                    asi.asi_nombre,
                    dia.dia_nombre,
                    hra.hra_codigo,
                    hra.hra_inicio,
                    hra.hra_fin,
                    esp.esp_codigo,
                    esp.esp_nombre,
                    esp.esp_nombre_corto,
                    sed.sed_nombre,
                    uaa.uaa_codigo,
                    uaa.uaa_nombre_corto
                ) as temp
            WHERE temp.TotalMatriculados = 0
            ORDER BY
                temp.cur_estado DESC,
                temp.eso_actividad ASC,
                temp.dia_nombre ASC,
                temp.hra_codigo ASC
        ";

        //Se verifica que se ejecute la consulta
        if (!$this->cnx->Consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error en consultar los cursos sin matriculados con horario";
            return $this->errorConsultarBd;
        }

        //Se almacenan los registros
        $array_cursos = array();
        foreach ($this->cnx->json as $curso){
            array_push($array_cursos, $curso["EsoActividad"]);
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
