<?php
date_default_timezone_set('America/Bogota');

class Ceadmin
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

    //Permite consultar el historico de modificaciones de un curso especifico.
    public function consultarHistoricoCurso($obj)
    {
        // Validamos las variables recibidas que exista y que sea numerico
        if (!isset($obj->CurCodigo) || !is_numeric($obj->CurCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar un curso.",
                "consola" => "El código del curso no es numerico o no hay número",
            );
        }

        $CurCodigo = $obj->CurCodigo; // Codigo del curso a buscar.
        $EsoSubgrupo = $obj->EsoSubgrupo; // Subgrupo del curso a buscar.

        if ($EsoSubgrupo == '') {
            $sql = "SELECT
                RTRIM(cur.aud_log_type) LogType,
                cur.aud_changed FechaCambio,
                cur.cur_codigo CurCodigo,
                asi.asi_codigo AsiCodigo,
                asi.asi_nombre_corto AsiNombreCorto,
                asi.asi_nombre AsiNombre,
                car.car_nombre CarNombre,
                car.car_codigo CarCodigo,
                cur.cur_estado CurEstado,
                cur.cur_semanas CurSemanas,
                cur.cur_cupo CurCupo,
                cur.cur_observaciones CurObservaciones,
                cur.cur_ampliacion_cupo CurAmpliacion,
                nuc.nuc_nombre NucNombre,
                tic.tic_nombre TicNombre,
                sed.sed_nombre SedNombre,
                per.per_nombre + ' ' + per.per_apellido CoorPerNombreApellido,
                per.per_identificacion PerIdentificacion,
                vin.vin_nombre VinNombre,
                ded.ded_nombre DedNombre,
                convert(varchar, uaa.uaa_codigo) + '. ' + uaa.uaa_nombre_corto UaaCodigoNombre,
                usuario.PerNombreApellido
            FROM aud_curso cur
                INNER JOIN asignatura asi ON asi.asi_codigo = cur.asi_codigo
                INNER JOIN caracter car ON car.car_codigo = asi.car_codigo
                LEFT JOIN nucleo nuc ON nuc.nuc_codigo = asi.nuc_codigo
                INNER JOIN sede sed ON sed.sed_codigo = cur.sed_codigo
                INNER JOIN tipo_curso tic ON tic.tic_codigo = cur.tic_codigo
                INNER JOIN uaa ON uaa.uaa_codigo = asi.uaa_codigo
                INNER JOIN uaa_personal uap on uap.uap_codigo = cur.uap_codigo
                INNER JOIN persona per on per.per_codigo = uap.per_codigo
                INNER JOIN vinculacion vin on vin.vin_codigo = uap.vin_codigo
                INNER JOIN dedicacion ded on ded.ded_codigo = uap.ded_codigo
                CROSS APPLY dbo.personaFromSys(cur.aud_user) as usuario
            WHERE
                    cur.cur_codigo = {$CurCodigo}
            ORDER BY
                    cur.aud_changed DESC,
                    cur.aud_log_type ASC
            ";
        } else {
            $sql = "SELECT
                aud.cur_codigo CurCodigo,
                aud.cus_cupo CusCupo,
                aud.eso_subgrupo EsoSubgrupo,
                cur.cur_semanas CurSemanas,
                asi.asi_nombre_corto AsiNombreCorto,
                asi.asi_nombre AsiNombre,
                cur.cur_estado CurEstado,
                aud.cus_estado CusEstado,
                cur.cur_cupo CurCupo,
                cur.cur_ampliacion_cupo CurAmpliacion,
                cur.cur_observaciones CurObservaciones,
                cur.cur_semanas CurSemana,
                cur.asi_codigo AsiCodigo,
                car.car_nombre CarNombre,
                car.car_codigo CarCodigo,
                nuc.nuc_nombre NucNombre,
                tic.tic_nombre TicNombre,
                sed.sed_nombre SedNombre,
                per.per_nombre + ' ' + per.per_apellido CoorPerNombreApellido,
                per.per_identificacion PerIdentificacion,
                vin.vin_nombre VinNombre,
                ded.ded_nombre DedNombre,
                cur.cur_observaciones CurObservaciones,
                CONVERT(VARCHAR, uaa.uaa_codigo) + '. ' + uaa.uaa_nombre_corto UaaCodigoNombre,
                aud.aud_changed FechaCambio,
                RTRIM(aud.aud_log_type) LogType,
                usuario.PerNombreApellido
            FROM aud_curso_cupo_subgrupo aud
                INNER JOIN curso cur ON cur.cur_codigo = aud.cur_codigo
                LEFT JOIN asignatura asi ON asi.asi_codigo = cur.asi_codigo
                LEFT JOIN caracter car ON car.car_codigo = asi.car_codigo
                LEFT JOIN nucleo nuc ON nuc.nuc_codigo = asi.nuc_codigo
                LEFT JOIN tipo_curso tic ON tic.tic_codigo = cur.tic_codigo
                LEFT JOIN uaa ON uaa.uaa_codigo = asi.uaa_codigo
                LEFT JOIN sede sed ON sed.sed_codigo = cur.sed_codigo
                LEFT JOIN uaa_personal uap on uap.uap_codigo = cur.uap_codigo
                LEFT JOIN persona per on per.per_codigo = uap.per_codigo
                LEFT JOIN vinculacion vin on vin.vin_codigo = uap.vin_codigo
                LEFT JOIN dedicacion ded on ded.ded_codigo = uap.ded_codigo
                CROSS APPLY dbo.personaFromSys(aud.aud_user) as usuario
            WHERE  
                aud.cur_codigo = {$CurCodigo}
                AND aud.eso_subgrupo = {$EsoSubgrupo}
            ORDER BY aud.aud_changed, aud.cur_codigo, aud.eso_subgrupo DESC
            ";
        }

        //Se verifica que se ejecute la consulta
        if (!$this->cnx->Consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error en consultar el historial de cambios del curso {$CurCodigo}.";
            return $this->errorConsultarBd;
        }

        $r_cursos = $this->cnx->json; //Se almacenan los cursos editados por los administradores.
        $count = 1;
        foreach ($r_cursos as &$curso) {
        }

        return array(
            "resultado" => true,
            "mensaje" => "Reporte consultado correctamente.",
            "data" => $r_cursos,
            "count" => count($r_cursos)
        );
    }

    //Permite consultar los cursos en los que los administradores han realizado alguna edición
    public function consultarCursosAdmin($obj)
    {
        // Validamos las variables recibidas que exista y que sea numerico
        if (!isset($obj->CalCodigo) || !is_numeric($obj->CalCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar un calendario.",
                "consola" => "El código del calendario no es numerico o no hay número",
            );
        }

        if (!isset($obj->TipoCodigo) || !is_numeric($obj->TipoCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar un tipo de reporte.",
                "consola" => "El código del tipo de reporte no es numerico o no hay número",
            );
        }

        //Consultamos los usuarios de los administradores de programacion academica
        //Con esta query se obtiene pero la idea es no dar permisos sobre esa vista login.
        //Por ahora se dejara en una variable los dos usuarios administradores.
        //select sys from usuario_programacion_login where usg_grupo = 69

        $CalCodigo = $obj->CalCodigo; // Codigo del calendario a buscar.
        $TipoCodigo = $obj->TipoCodigo; // Codigo del tipo de reporte. 
        // 1.Cursos Creados 
        // 2. Cursos Editados 
        // 4. Cursos Eliminados
        // 3. Subgrupos Eliminados
        // 5. Horarios Creados

        // $UsuarioAdministrador = "'programacionacad','programacion_carlosalberto'";
        $UsuarioAdministrador = $_SESSION["pacademica"]["usuario_real"]; //Obtenemos el usuario real logueado.

        $queryTipoAuditoria = ""; //Valida la query si se consultan los cursos creados o los cursos editados.
        $queryEstadoCurso = ""; //Valida la query para cursos eliminados

        if ($TipoCodigo == 1 || $TipoCodigo == 2 || $TipoCodigo == 4) {
            if ($TipoCodigo == 1) { //Cuando el reporte es de cursos creados.
                $queryTipoAuditoria = "AND aud.aud_log_type LIKE '%INSERT%' "; //Solo para cursos creados.
            }
            if ($TipoCodigo == 2 || $TipoCodigo == 4) { //Cuando el reporte es de cursos editados o eliminados
                $queryTipoAuditoria = "AND aud.aud_log_type LIKE '%NUEVO%' "; //Solo para cursos editados.
            }
            if ($TipoCodigo == 4) { //Cuando el reporte es de cursos editados.
                $queryEstadoCurso = "AND aud.cur_estado = 0 "; //Solo para cursos eliminados.
            }
            $sql = "SELECT
                cur.cur_codigo CurCodigo,
                asi.asi_codigo AsiCodigo,
                asi.asi_nombre_corto AsiNombreCorto,
                asi.asi_nombre AsiNombre,
                car.car_nombre CarNombre,
                car.car_codigo CarCodigo,
                cur.cur_estado CurEstado,
                cur.cur_semanas CurSemanas,
                cur.cur_cupo CurCupo,
                cur.cur_observaciones CurObservaciones,
                nuc.nuc_nombre NucNombre,
                tic.tic_nombre TicNombre,
                sed.sed_nombre SedNombre,
                per.per_nombre + ' ' + per.per_apellido PerNombreApellido,
                per.per_identificacion PerIdentificacion,
                vin.vin_nombre VinNombre,
                ded.ded_nombre DedNombre,
                convert(varchar, uaa.uaa_codigo) + '. ' + uaa.uaa_nombre_corto UaaCodigoNombre
            FROM (
                SELECT 
                    aud.cur_codigo as cur_codigo
                FROM
                    aud_curso aud 
                WHERE 
                    aud.cal_codigo = {$CalCodigo}
                    {$queryTipoAuditoria}
                    {$queryEstadoCurso}
                    AND aud.aud_user IN ('{$UsuarioAdministrador}')
                GROUP BY
                    aud.cur_codigo
            ) aud_curso
            INNER JOIN curso cur ON cur.cur_codigo = aud_curso.cur_codigo --AND cur.cur_estado = 0
            INNER JOIN asignatura asi ON asi.asi_codigo = cur.asi_codigo
            INNER JOIN caracter car ON car.car_codigo = asi.car_codigo
            LEFT JOIN nucleo nuc ON nuc.nuc_codigo = asi.nuc_codigo
            INNER JOIN sede sed ON sed.sed_codigo = cur.sed_codigo
            INNER JOIN tipo_curso tic ON tic.tic_codigo = cur.tic_codigo
            INNER JOIN uaa ON uaa.uaa_codigo = asi.uaa_codigo
            INNER JOIN uaa_personal uap on uap.uap_codigo = cur.uap_codigo 
            INNER JOIN persona per on per.per_codigo = uap.per_codigo 
            INNER JOIN vinculacion vin on vin.vin_codigo = uap.vin_codigo 
            INNER JOIN dedicacion ded on ded.ded_codigo = uap.ded_codigo 
            ORDER BY
                cur.cur_estado ASC,
                cur.cur_codigo ASC
            ";

            //Se verifica que se ejecute la consulta
            if (!$this->cnx->Consultar($sql)) {
                $this->errorConsultarBd["consola"] = "Error en consultar los cursos editados por los administradores";
                return $this->errorConsultarBd;
            }

            $r_cursos = $this->cnx->json; //Se almacenan los cursos editados por los administradores.

            return array(
                "resultado" => true,
                "mensaje" => "Reporte consultado correctamente.",
                "data" => $r_cursos,
                "count" => count($r_cursos)
            );
        }
        if ($TipoCodigo == 3) { //Cuando el reporte es de cursos y subgrupos eliminados.

            $sql = "SELECT
                    aud.cur_codigo CurCodigo,
                    aud.eso_subgrupo EsoSubgrupo,
                    aud.cus_cupo CusCupo,
                    asi.asi_nombre_corto AsiNombreCorto,
                    asi.asi_nombre AsiNombre,
                    cur.cur_estado CurEstado,
                    cur.cur_cupo CurCupo,
                    cur.cur_semanas CurSemana,
                    cur.asi_codigo AsiCodigo,
                    car.car_nombre CarNombre,
                    car.car_codigo CarCodigo,
                    nuc.nuc_nombre NucNombre,
                    tic.tic_nombre TicNombre,
                    cur.cur_observaciones CurObservaciones,
                    CONVERT(VARCHAR, uaa.uaa_codigo) + '. ' + uaa.uaa_nombre_corto UaaCodigoNombre
                FROM aud_curso_cupo_subgrupo aud
                    INNER JOIN curso cur ON cur.cur_codigo = aud.cur_codigo AND cur.cal_codigo = {$CalCodigo}
                    LEFT JOIN asignatura asi ON asi.asi_codigo = cur.asi_codigo
                    LEFT JOIN caracter car ON car.car_codigo = asi.car_codigo
                    LEFT JOIN nucleo nuc ON nuc.nuc_codigo = asi.nuc_codigo
                    LEFT JOIN tipo_curso tic ON tic.tic_codigo = cur.tic_codigo
                    LEFT JOIN uaa ON uaa.uaa_codigo = asi.uaa_codigo
                WHERE  
                    aud.cus_estado = 0 
                    AND aud.aud_user IN ('{$UsuarioAdministrador}') 
                    AND aud.aud_log_type LIKE '%NUEVO%'
                ORDER BY aud.cur_codigo, aud.eso_subgrupo DESC";

            //Se verifica que se ejecute la consulta
            if (!$this->cnx->Consultar($sql)) {
                $this->errorConsultarBd["consola"] = "Error en consultar los subgrupos eliminados por los administradores";
                return $this->errorConsultarBd;
            }
            $r_subgrupo = $this->cnx->json; //Se almacenan los cursos eliminados por los administradores.
            return array(
                "resultado" => true,
                "mensaje" => "Reporte consultado correctamente.",
                "subgrupo" => $r_subgrupo,
                "count" => count($r_subgrupo)
            );
        }
        if ($TipoCodigo == 5) {

            $sql = "SELECT aud.eso_actividad 
            FROM (
                SELECT
                    eso.*, ROW_NUMBER() OVER (PARTITION BY eso.eso_actividad ORDER BY eso.aud_changed ASC) AS num_fila
                FROM
                    aud_espacio_ocupacion eso
                    INNER JOIN curso cur ON cur.cur_codigo = eso.eso_actividad AND cur.cal_codigo = {$CalCodigo}
                WHERE 
                    eso.aud_log_type LIKE 'INSER%'
                ) aud 
            WHERE
                aud.aud_user IN ('{$UsuarioAdministrador}') 
                AND aud.num_fila = 1";

            //Se verifica que se ejecute la consulta
            if (!$this->cnx->Consultar($sql)) {
                $this->errorConsultarBd["consola"] = "Error en consultar los cursos con horario creado por administradores.";
                return $this->errorConsultarBd;
            }

            $r_cursosConHorarioCreado = $this->cnx->json; //Se almacenan los cursos donde el administrador creo el primer horario.
            $implodeCursos = implode(',', array_column($r_cursosConHorarioCreado, 'eso_actividad')); //Del array con los cursos obtenemos solamente los codigos de los cursos y los separamos po coma para buscar la informacion de esos cursos.

            $sql = "SELECT
                cur.cur_codigo CurCodigo,
                asi.asi_codigo AsiCodigo,
                asi.asi_nombre_corto AsiNombreCorto,
                asi.asi_nombre AsiNombre,
                car.car_nombre CarNombre,
                car.car_codigo CarCodigo,
                cur.cur_estado CurEstado,
                cur.cur_semanas CurSemanas,
                cur.cur_cupo CurCupo,
                cur.cur_observaciones CurObservaciones,
                nuc.nuc_nombre NucNombre,
                tic.tic_nombre TicNombre,
                sed.sed_nombre SedNombre,
                per.per_nombre + ' ' + per.per_apellido PerNombreApellido,
                per.per_identificacion PerIdentificacion,
                vin.vin_nombre VinNombre,
                ded.ded_nombre DedNombre,
                convert(varchar, uaa.uaa_codigo) + '. ' + uaa.uaa_nombre_corto UaaCodigoNombre
            FROM curso cur
            INNER JOIN asignatura asi ON asi.asi_codigo = cur.asi_codigo
            INNER JOIN caracter car ON car.car_codigo = asi.car_codigo
            LEFT JOIN nucleo nuc ON nuc.nuc_codigo = asi.nuc_codigo
            INNER JOIN sede sed ON sed.sed_codigo = cur.sed_codigo
            INNER JOIN tipo_curso tic ON tic.tic_codigo = cur.tic_codigo
            INNER JOIN uaa ON uaa.uaa_codigo = asi.uaa_codigo
            INNER JOIN uaa_personal uap on uap.uap_codigo = cur.uap_codigo 
            INNER JOIN persona per on per.per_codigo = uap.per_codigo 
            INNER JOIN vinculacion vin on vin.vin_codigo = uap.vin_codigo 
            INNER JOIN dedicacion ded on ded.ded_codigo = uap.ded_codigo 
            WHERE   
                cur.cur_codigo IN ({$implodeCursos})
            ORDER BY
                cur.cur_estado ASC,
                cur.cur_codigo ASC
            ";
            
            //Se verifica que se ejecute la consulta
            if (!$this->cnx->Consultar($sql)) {
                $this->errorConsultarBd["consola"] = "Error en consultar los cursos con horario creado por administradores.";
                return $this->errorConsultarBd;
            }

            $r_cursosInformacion = $this->cnx->json; //Se almacenan la informacion de los cursos donde el administrador creo el primer horario

            return array(
                "resultado" => true,
                "mensaje" => "Reporte consultado correctamente.",
                "data" => $r_cursosInformacion,
                "count" => count($r_cursosInformacion)
            );
        }
    }

    public function consultarCursosEliminados()
    {
    }
}
