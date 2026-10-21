<?php
date_default_timezone_set('America/Bogota');

class Csh
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

    public function consultarCursosSinHorario($obj)
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
                asi.asi_nombre AsiNombre,
                asi.asi_nombre_corto AsiNombreCorto,
                cur.cur_cupo CurCupo,
                cur.cur_semanas CurSemanas,
                tic.tic_nombre TicNombre,
                uaa.uaa_codigo UaaCodigo,
                CASE WHEN cur.cur_estado = 1 THEN 'ACTIVO' ELSE 'ELIMINADO' END CurEstado,
                cur.cur_observaciones CurObservaciones,
                CONVERT(varchar,uaa.uaa_codigo) + '. ' + uaa.uaa_nombre_corto UaaCodigoNombre,
                uaa.uaa_nombre_corto UaaNombreCorto,
                (
                    -- Select rows from a Table or View 'matricula_curso' in schema 'SchemaName'
                    SELECT COUNT(*) FROM dbo.matricula_curso mac
                    WHERE 	
                        mac.cur_codigo = cur.cur_codigo
                        AND mac.maa_codigo IN (1,2)
                ) TotalMatriculados,
                per.per_nombre + ' ' + per.per_apellido PerNombreApellido,
                per.per_identificacion PerIdentificacion,
                vin.vin_nombre VinNombre,
                ded.ded_nombre DedNombre
            FROM curso cur 
            INNER JOIN asignatura asi ON asi.asi_codigo = cur.asi_codigo
            INNER JOIN uaa ON uaa.uaa_codigo = asi.uaa_codigo
            INNER JOIN tipo_curso tic ON tic.tic_codigo = cur.tic_codigo
            INNER JOIN uaa_personal uap ON uap.uap_codigo = cur.uap_codigo
            INNER JOIN persona per ON per.per_codigo = uap.per_codigo
            INNER JOIN vinculacion vin ON vin.vin_codigo = uap.vin_codigo
            INNER JOIN dedicacion ded ON ded.ded_codigo = uap.ded_codigo
            WHERE cur_codigo not in (
                SELECT eso.eso_actividad 
                FROM espacio_ocupacion_total eso
                INNER JOIN curso cur2 ON cur2.cur_codigo = eso.eso_actividad 
                    AND cur2.cal_codigo IN ({$CalCodigo})
                    AND cur2.cur_estado = 1
                WHERE 
                    eso.eso_actividad != ''
                GROUP BY eso.eso_actividad
            )
            AND cur.cal_codigo IN ({$CalCodigo})
            AND cur.cur_estado = 1
            ORDER BY TotalMatriculados DESC, cur.cur_codigo DESC
        ";

        //Se verifica que se ejecute la consulta
        if (!$this->cnx->Consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error en consultar los cursos activos sin horario";
            return $this->errorConsultarBd;
        }

        //Se almacenan los registros

        return array(
            "resultado" => true,
            "mensaje" => "Reporte consultado correctamente.",
            "data" => $this->cnx->json
        );
    }
}
