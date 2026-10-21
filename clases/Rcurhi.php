<?php
date_default_timezone_set('America/Bogota');

class Rcurhi
{

    private $cnx = null;

    private $errorConectarBd = array(
        "resultado" => false,
        "mensaje" => "Error al conectar con la base de datos",
        "consola" => "Metodo conectar() en bd",
        "data" => array(),
        "count" => 0
    );
    private $errorConsultarBd = array(
        "resultado" => false,
        "mensaje" => "Error al consultar la base de datos",
        "consola" => "",
        "data" => array(),
        "count" => 0
    );

    public function __construct()
    {
        if (!file_exists("../conexion/cls_config.php")) {
            echo "Archivo de conexion no encontrado";
            die;
        }
        require_once "../conexion/cls_config.php";
        $this->cnx = new cls_config();
    }

    public function consultarAdministrador()
    {
        if (!isset($_SESSION["pacademica"]["datosVinculacionUsuario"]["Administrador"])) {
            return 0;
        }

        return $_SESSION["pacademica"]["datosVinculacionUsuario"]["Administrador"];
    }

    public function consultarCursosHorarioIncompleto($obj)
    {
        if ($this->consultarAdministrador() != 1) {
            return array(
                "resultado" => false,
                "mensaje" => "Esta seccion solo es permitida para los administradores.",
                "consola" => "Usuario sin perfil administrador intento consultar cursos con horario incompleto.",
                "data" => array(),
                "count" => 0
            );
        }

        if (!isset($obj->PerCodigo) || !is_numeric($obj->PerCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar un periodo.",
                "consola" => "El codigo del periodo no es numerico o no se envio correctamente.",
                "data" => array(),
                "count" => 0
            );
        }

        if (!isset($obj->CalCodigo) || !is_numeric($obj->CalCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar un calendario.",
                "consola" => "El codigo del calendario no es numerico o no se envio correctamente.",
                "data" => array(),
                "count" => 0
            );
        }

        $PerCodigo = intval($obj->PerCodigo);
        $CalCodigo = intval($obj->CalCodigo);

        $sql = "WITH horario_curso AS (
                SELECT
                    eso.eso_actividad CurCodigo,
                    COUNT(*) TotalRegistrosHorario,
                    COUNT(DISTINCT CONVERT(VARCHAR(10), eso.dia_codigo) + '-' + CONVERT(VARCHAR(10), eso.hra_codigo) + '-' + ISNULL(CONVERT(VARCHAR(20), eso.eso_subgrupo), '')) TotalHorasProgramadas,
                    STUFF((
                        SELECT DISTINCT ', ' + ISNULL(CONVERT(VARCHAR(20), eo2.eso_subgrupo), '00')
                        FROM espacio_ocupacion eo2
                        WHERE eo2.eso_actividad = eso.eso_actividad
                        FOR XML PATH(''), TYPE
                    ).value('.', 'NVARCHAR(MAX)'), 1, 2, '') SubGrupo,
                    STUFF((
                        SELECT DISTINCT ', ' + dia2.dia_nombre
                        FROM espacio_ocupacion eo2
                        INNER JOIN dia dia2 ON dia2.dia_codigo = eo2.dia_codigo
                        WHERE eo2.eso_actividad = eso.eso_actividad
                        FOR XML PATH(''), TYPE
                    ).value('.', 'NVARCHAR(MAX)'), 1, 2, '') DiaNombre,
                    STUFF((
                        SELECT DISTINCT ', ' + CONVERT(VARCHAR(5), hra2.hra_inicio, 108) + '-' + CONVERT(VARCHAR(5), hra2.hra_fin, 108)
                        FROM espacio_ocupacion eo2
                        INNER JOIN hora hra2 ON hra2.hra_codigo = eo2.hra_codigo
                        WHERE eo2.eso_actividad = eso.eso_actividad
                        FOR XML PATH(''), TYPE
                    ).value('.', 'NVARCHAR(MAX)'), 1, 2, '') Hora,
                    STUFF((
                        SELECT DISTINCT ', ' + ISNULL(esp2.esp_nombre_corto, esp2.esp_nombre)
                        FROM espacio_ocupacion eo2
                        INNER JOIN espacio esp2 ON esp2.esp_codigo = eo2.esp_codigo
                        WHERE eo2.eso_actividad = eso.eso_actividad
                        FOR XML PATH(''), TYPE
                    ).value('.', 'NVARCHAR(MAX)'), 1, 2, '') Espacio,
                    STUFF((
                        SELECT DISTINCT ', ' + CONVERT(VARCHAR(20), uaa2.uaa_codigo) + '. ' + uaa2.uaa_nombre_corto
                        FROM espacio_ocupacion eo2
                        INNER JOIN uaa uaa2 ON uaa2.uaa_codigo = eo2.uaa_codigo
                        WHERE eo2.eso_actividad = eso.eso_actividad
                        FOR XML PATH(''), TYPE
                    ).value('.', 'NVARCHAR(MAX)'), 1, 2, '') UnidadProgramada
                FROM espacio_ocupacion eso
                WHERE eso.eso_actividad IS NOT NULL AND eso.eso_actividad <> ''
                GROUP BY eso.eso_actividad
            ),
            cursos AS (
                SELECT
                    CASE WHEN cur.cur_estado = 1 THEN 'ACTIVO' ELSE 'ELIMINADO' END CurEstado,
                    cur.cur_codigo CurCodigo,
                    ISNULL(hor.SubGrupo, '') SubGrupo,
                    asi.asi_nombre_corto AsiNombreCorto,
                    asi.asi_nombre AsiNombre,
                    cur.cur_cupo CurCupo,
                    cur.cur_semanas CurSemanas,
                    ISNULL(hor.DiaNombre, '') DiaNombre,
                    ISNULL(hor.Hora, '') Hora,
                    tic.tic_nombre TicNombre,
                    ISNULL(hor.Espacio, '') Espacio,
                    ISNULL(hor.UnidadProgramada, '') UnidadProgramada,
                    (
                        SELECT COUNT(*)
                        FROM matricula_curso mac
                        WHERE mac.cur_codigo = cur.cur_codigo
                            AND mac.maa_codigo IN (1,2)
                    ) TotalMatriculados,
                    cur.cur_observaciones CurObservaciones,
                    per.per_identificacion PerIdentificacion,
                    per.per_nombre + ' ' + per.per_apellido PerNombreApellido,
                    vin.vin_nombre VinNombre,
                    ded.ded_nombre DedNombre,
                    uaa.uaa_codigo UaaCodigo,
                    CONVERT(VARCHAR(20), uaa.uaa_codigo) + '. ' + uaa.uaa_nombre_corto UaaCodigoNombre,
                    uaa.uaa_nombre_corto UaaNombreCorto,
                    cur.usu_codigo UsuCodigo,
                    ISNULL(perusu.per_nombre + ' ' + perusu.per_apellido, CONVERT(VARCHAR(20), cur.usu_codigo)) UsuarioCreador,
                    ISNULL(perusu.per_email_interno, '') UsuarioCreadorEmail,
                    asi.car_codigo CarCodigo,
                    asi.asi_creditos AsiCreditos,
                    asi.asi_creditos_teoria AsiCreditosTeoria,
                    asi.asi_creditos_practica AsiCreditosPractica,
                    hor.TotalRegistrosHorario TotalHorario,
                    hor.TotalHorasProgramadas TotalHorasProgramadas,
                    CASE
                        WHEN LTRIM(RTRIM(asi.car_codigo)) = 'T' AND ISNULL(asi.asi_creditos_teoria, 0) > 0 THEN asi.asi_creditos_teoria
                        WHEN LTRIM(RTRIM(asi.car_codigo)) IN ('P', 'PP', 'PF') AND ISNULL(asi.asi_creditos_practica, 0) > 0 THEN asi.asi_creditos_practica
                        ELSE asi.asi_creditos
                    END CreditosObjetivo
                FROM curso cur
                INNER JOIN calendario cal ON cal.cal_codigo = cur.cal_codigo
                INNER JOIN asignatura asi ON asi.asi_codigo = cur.asi_codigo
                INNER JOIN tipo_curso tic ON tic.tic_codigo = cur.tic_codigo
                INNER JOIN uaa uaa ON uaa.uaa_codigo = asi.uaa_codigo
                INNER JOIN uaa_personal uap ON uap.uap_codigo = cur.uap_codigo
                INNER JOIN persona per ON per.per_codigo = uap.per_codigo
                INNER JOIN vinculacion vin ON vin.vin_codigo = uap.vin_codigo
                INNER JOIN dedicacion ded ON ded.ded_codigo = uap.ded_codigo
                INNER JOIN horario_curso hor ON hor.CurCodigo = cur.cur_codigo
                LEFT JOIN usuario_general usg ON usg.uid = cur.usu_codigo
                LEFT JOIN persona perusu ON perusu.per_codigo = usg.up
                WHERE
                    cur.cal_codigo = {$CalCodigo}
                    AND cal.per_codigo = {$PerCodigo}
            )
            SELECT
                CurEstado,
                CurCodigo,
                SubGrupo,
                AsiNombreCorto,
                AsiNombre,
                CurCupo,
                CurSemanas,
                DiaNombre,
                Hora,
                TicNombre,
                Espacio,
                UnidadProgramada,
                TotalMatriculados,
                CurObservaciones,
                PerIdentificacion,
                PerNombreApellido,
                VinNombre,
                DedNombre,
                UaaCodigo,
                UaaCodigoNombre,
                UaaNombreCorto,
                UsuCodigo,
                UsuarioCreador,
                UsuarioCreadorEmail,
                TotalHorario,
                TotalHorasProgramadas,
                CreditosObjetivo,
                CarCodigo,
                AsiCreditos,
                AsiCreditosTeoria,
                AsiCreditosPractica
            FROM cursos
            WHERE
                TotalHorario > 0
                AND ISNULL(CreditosObjetivo, 0) > 0
                AND TotalHorasProgramadas < CreditosObjetivo
            ORDER BY
                UaaNombreCorto ASC,
                CurCodigo ASC";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar el reporte de cursos con horario incompleto.";
            $this->errorConsultarBd["sql"] = $sql;
            return $this->errorConsultarBd;
        }

        $data = is_array($this->cnx->json) ? $this->cnx->json : array();

        return array(
            "resultado" => true,
            "mensaje" => "Reporte consultado correctamente.",
            "data" => $data,
            "count" => count($data)
        );
    }
}
