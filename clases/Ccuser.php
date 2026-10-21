<?php
date_default_timezone_set('America/Bogota');

class Ccuser
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

    //Permite consultar el total de cursos por usuario
    public function consultarCursosporUsuario($obj)
    {
        // Validamos las variables recibidas que exista y que sea numerico
        if (!isset($obj->CalCodigo) || !is_numeric($obj->CalCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar un calendario.",
                "consola" => "El código del calendario no es numerico o no hay número",
            );
        }

        $CalCodigo = $obj->CalCodigo; // Codigo del calendario especifico

        $sql = "SELECT
            cur.usu_codigo UsuCodigo,
            per.per_codigo PerCodigo,
            per.per_nombre PerNombre,
            per.per_apellido PerApellido,
            per.per_email_interno PerEmail,
            COUNT(DISTINCT cur.cur_codigo) TotalCursosCreados,
            COUNT(DISTINCT CASE WHEN cur.cur_estado = 0 THEN cur.cur_codigo END) AS TotalCursosEliminados,
            COUNT(DISTINCT CASE WHEN cur.cur_estado = 1 THEN cur.cur_codigo END) AS TotalCursosActivos,
            COUNT(DISTINCT eso.eso_actividad) TotalCursosProgramados,
            COUNT(DISTINCT CASE WHEN cur.cur_estado = 1 THEN cur.cur_codigo END) - COUNT(DISTINCT eso.eso_actividad) FaltanPorProgramar
        FROM curso cur
            INNER JOIN usuario_general usg ON usg.uid = cur.usu_codigo
            INNER JOIN persona per ON per.per_codigo = usg.up
            LEFT JOIN espacio_ocupacion eso ON eso.eso_actividad = cur.cur_codigo
        WHERE 
            cur.cal_codigo = {$CalCodigo}
        GROUP BY
            cur.usu_codigo,
            per.per_codigo,
            per.per_nombre,
            per.per_apellido,
            per.per_email_interno
        ORDER BY
            per.per_nombre ASC
        ";

        //Se verifica que se ejecute la consulta
        if (!$this->cnx->Consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error en consultar el reporte total de cursos creados.";
            return $this->errorConsultarBd;
        }

        $r_usuario = $this->cnx->json; //Se almacenan los cursos editados por los administradores.
        $totalCursosCreados = 0;
        $totalCursosEliminados = 0;
        $totalCursosActivos = 0;
        $totalCursosProgramados = 0;
        $totalCursosFaltantes = 0;

        foreach ($r_usuario as $usuario) {
            $totalCursosCreados += $usuario['TotalCursosCreados'];
            $totalCursosEliminados += $usuario['TotalCursosEliminados'];
            $totalCursosActivos += $usuario['TotalCursosActivos'];
            $totalCursosProgramados += $usuario['TotalCursosProgramados'];
            $totalCursosFaltantes += $usuario['FaltanPorProgramar'];
        }

        return array(
            "resultado" => true,
            "mensaje" => "Reporte consultado correctamente.",
            "data" => $r_usuario,
            "TotalCursosCreados" => $totalCursosCreados,
            "TotalCursosEliminados" => $totalCursosEliminados,
            "TotalCursosActivos" => $totalCursosActivos,
            "TotalCursosProgramados" => $totalCursosProgramados,
            "FaltanPorProgramar" => $totalCursosFaltantes
        );
    }

    // Permite consultar el detalle de cursos activos sin horario por usuario.
    public function consultarDetalleCursosSinHorarioUsuario($obj)
    {
        if (!isset($obj->CalCodigo) || !is_numeric($obj->CalCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar un calendario.",
                "consola" => "El código del calendario no es numerico o no hay número",
            );
        }

        if (!isset($obj->UsuCodigo) || !is_numeric($obj->UsuCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se encontró el usuario para consultar.",
                "consola" => "El código del usuario no es numerico o no hay número",
            );
        }

        $CalCodigo = $obj->CalCodigo;
        $UsuCodigo = $obj->UsuCodigo;

        $sql = "SELECT
            cur.cur_codigo CurCodigo,
            asi.asi_nombre_corto AsiNombreCorto,
            asi.asi_nombre AsiNombre,
            cur.cur_cupo CurCupo,
            cur.cur_semanas CurSemanas,
            tic.tic_nombre TicNombre,
            CONVERT(VARCHAR, uaa.uaa_codigo) + '. ' + uaa.uaa_nombre_corto UaaCodigoNombre
        FROM curso cur
            INNER JOIN asignatura asi ON asi.asi_codigo = cur.asi_codigo
            INNER JOIN tipo_curso tic ON tic.tic_codigo = cur.tic_codigo
            INNER JOIN uaa ON uaa.uaa_codigo = asi.uaa_codigo
        WHERE
            cur.cal_codigo = {$CalCodigo}
            AND cur.usu_codigo = {$UsuCodigo}
            AND cur.cur_estado = 1
            AND NOT EXISTS (
                SELECT 1
                FROM espacio_ocupacion eo
                WHERE eo.eso_actividad = cur.cur_codigo
            )
        ORDER BY
            cur.cur_codigo ASC";

        if (!$this->cnx->Consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error en consultar cursos sin horario por usuario.";
            return $this->errorConsultarBd;
        }

        $r_cursos = $this->cnx->json;

        return array(
            "resultado" => true,
            "mensaje" => "Detalle consultado correctamente.",
            "data" => $r_cursos,
            "count" => count($r_cursos)
        );
    }

}
