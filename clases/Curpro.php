<?php

require_once(dirname(__FILE__) . '/servicios/PermisoCurso.php');

class Curpro
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

    //Inicio funcion consultaEidy
    //Permite consultar la agenda ocupada y libre por cada espacio
    function consultaEidy()
    {
        //Parametros
        $date_ini = '2021-10-25T00:00:00.000'; // Fecha inicial periodo
        $date_fin = '2022-03-10T00:00:00.000'; // Fecha final periodo

        $r_final = array();

        //Sql de los dias
        $sql = "SELECT dia_nombre DiaNombre, dia_codigo DiaCodigo FROM dia WHERE dia_codigo IN (1,2,3,4,5,6,7)";
        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar los dias.";
            return $this->errorConsultarBd;
        }
        $r_dia = $this->cnx->json; //Almacenamos la consulta de los dias.

        //Sql de las horas
        $sql = "SELECT hra_codigo HraCodigo, hra_inicio HraInicio, hra_fin HraFin FROM hora";
        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar las horas.";
            return $this->errorConsultarBd;
        }
        $r_hora = $this->cnx->json; //Almacenamos la consulta de las horas.

        //Sql de espacios activos
        $sql = "SELECT 
            sed.sed_nombre SedNombre,
            sus.sus_nombre SusNombre,
            blo.blo_nombre BloNombre,
            esp.esp_codigo EspCodigo, 
            esp.esp_nombre_corto EspNombre
        FROM 
            espacio esp
        INNER JOIN bloque blo on blo.blo_codigo = esp.blo_codigo and blo.blo_codigo = 3
        INNER JOIN sub_sede sus on sus.sus_codigo = blo.sus_codigo
        INNER JOIN sede sed on sed.sed_codigo = sus.sed_codigo and sed.sed_estado = 1 and sed.sed_codigo = 1
        WHERE
            esp.eti_codigo in (5)
            and esp.esp_estado = 1
        ORDER BY
            sed.sed_nombre,
            sus.sus_nombre,
            blo.blo_nombre
        ";
        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar los espacios.";
            return $this->errorConsultarBd;
        }
        $r_espacio = $this->cnx->json; //Almacenamos la consulta de los espacios.

        for ($esp = 0; $esp < count($r_espacio); $esp++) {
            $array = [
                "SedNombre" => $r_espacio[$esp]['SedNombre'],
                "SusNombre" => $r_espacio[$esp]['SusNombre'],
                "BloNombre" => $r_espacio[$esp]['BloNombre'],
                "EspCodigo" => $r_espacio[$esp]['EspCodigo'],
                "EspNombre" => $r_espacio[$esp]['EspNombre'],
                "DiaCodigo" => array()
            ];
            $r_final[$esp] = array_map('utf8_encode', $array); //Se asigna al array final
            for ($dia = 0; $dia < count($r_dia); $dia++) {
                $array = [
                    "DiaNombre" => $r_dia[$dia]['DiaNombre'],
                    "DiaCodigo" => $r_dia[$dia]['DiaCodigo'],
                    "HraCodigo" => array()
                ];
                $r_final[$esp]['DiaCodigo'][$dia] = array_map('utf8_encode', $array); //Se asigna al array final
                for ($hora = 0; $hora < count($r_hora); $hora++) {
                    $array = [
                        "HraCodigo" => $r_hora[$hora]['HraCodigo'],
                        "HraInicio" => $r_hora[$hora]['HraInicio'],
                        "HraFin" => $r_hora[$hora]['HraFin'],
                        "Ocupacion" => ''
                    ];
                    $r_final[$esp]['DiaCodigo'][$dia]['HraCodigo'][$hora] = array_map('utf8_encode', $array); //Se asigna al array final

                    //Consultamos la ocupacion en un rango de fechas del espacio por el dia y por la hora.
                    $sql = "SELECT 
                        eso.eso_actividad 
                    FROM 
                        espacio_ocupacion eso
                    WHERE 
                        esp_codigo = {$r_espacio[$esp]['EspCodigo']}
                        AND (
                                eso_fecha BETWEEN 
                                    '2021-10-25T00:00:00.000' and 
                                    '2022-03-10T00:00:00.000'
                            )
                        AND dia_codigo = {$r_dia[$dia]['DiaCodigo']} 
                        AND hra_codigo = {$r_hora[$hora]['HraCodigo']}
                        AND eso_actividad != ''
                    ORDER BY 
                        dia_codigo, hra_codigo ASC
                    ";

                    if (!$this->cnx->consultar($sql)) {
                        $this->errorConsultarBd["consola"] = "Error al consultar la ocupacion del espacio {$r_espacio[$esp]['EspCodigo']} 
                        dia {$r_dia[$dia]['DiaCodigo']} 
                        hora {$r_hora[$hora]['HraCodigo']}.";
                        return $this->errorConsultarBd;
                    }
                    $r_horario = $this->cnx->json; //Almacenamos la consulta de los horarios.
                    $ocupacion = 0; //Ocupacion inicia libre
                    if (count($r_horario) > 0) { //Se compara si se encontraron registros
                        for ($horario = 0; $horario < count($r_horario); $horario++) { //Se recorre la consulta en busca de que tiene programado o si esta libre(solo asignado)
                            if ($r_horario[$horario]["eso_actividad"] != '') { //Se valida si en algun "dia" en cualquier "hora" se encuentra algun curso
                                $ocupacion = 1; //En caso de encontrar algun curso se toma por ocupado.
                            }
                        }
                    }
                    $r_final[$esp]['DiaCodigo'][$dia]['HraCodigo'][$hora]['Ocupacion'] = $ocupacion; //Almacenamos la ocupacion en el espacio, dia y hora.
                }
            }
        }

        return array(
            "resultado" => true,
            "mensaje" => "Cursos para estudiantes de primer semestre consultados correctamente.",
            "count" => count($r_final),
            "data" => $r_final
        );
    }

    //Inicio funcion consultarCursosProgramadosPrimiparos
    //Permite consultar los cursos designados para estudiantes de primer semestre
    function consultarCursosProgramadosPrimiparos($obj)
    {
        //Parametros
        $CalCodigo = $obj->CalCodigo; //Contiene el codigo del calendario especifico a consultar

        if (!isset($obj->CalCodigo) || !is_numeric($obj->CalCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo del calendario.",
                "consola" => "El codigo del calendario no viene o no es numerico, " . $obj->CalCodigo,
            );
        }

        $sql = "SELECT 
            cur.cur_codigo CurCodigo,
            cur.cur_estado CurEstado,
            asi.asi_nombre AsiNombre,
            asi.asi_nombre_corto AsiNombreCorto,
            cal.cal_nombre CalNombre,
            pla.pla_nombre PlaNombre,
            uaa.uaa_nombre_corto UaaNombrePropietario,
            uaa2.uaa_nombre_corto UaaNombreExclusivo
        FROM 
            curso cur
        INNER JOIN asignatura asi ON cur.asi_codigo = asi.asi_codigo
        INNER JOIN calendario cal ON cal.cal_codigo = cur.cal_codigo
        INNER JOIN uaa uaa ON uaa.uaa_codigo = asi.uaa_codigo
        INNER JOIN matricula_configuracion_detalle mcd ON mcd.cur_codigo = cur.cur_codigo
        INNER JOIN matricula_configuracion mco ON mco.mco_codigo = mcd.mco_codigo
        LEFT JOIN plan_academico pla ON pla.pla_codigo = mco.pla_codigo
        LEFT JOIN programa pro ON pro.pro_codigo = pla.pro_codigo
        INNER JOIN uaa uaa2 ON uaa2.uaa_codigo = pro.uaa_codigo
        WHERE 
            cal.cal_codigo = {$CalCodigo}
        ORDER BY 
            asi.asi_nombre 
        ASC
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar los cursos programados para estudiantes de primer semestre.";
            return $this->errorConsultarBd;
        }

        return array(
            "resultado" => true,
            "mensaje" => "Cursos para estudiantes de primer semestre consultados correctamente.",
            "count" => count($this->cnx->json),
            "data" => $this->cnx->json
        );
    }

    //Inicio funcion consultarCursosProgramadosMatriculados
    //Permite consultar la lista de cursos con cantidad de matriculados por subgrupo y cupo
    function consultarCursosProgramadosMatriculados($obj)
    {
        //Parametros
        $CalCodigo = $obj->CalCodigo; //Contiene el codigo del calendario especifico a consultar
        $Unidades = $_SESSION["pacademica"]["datosVinculacionUsuario"]["unidades"]; //Contiene las unidades separadas por comas (,) que tiene el usuario logeado
        $admin = $_SESSION["pacademica"]["datosVinculacionUsuario"]["Administrador"]; //Contiene si es admin (1) o no (0)

        if (!isset($obj->CalCodigo) || !is_numeric($obj->CalCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo del calendario.",
                "consola" => "El codigo del calendario no viene o no es numerico, " . $obj->CalCodigo,
            );
        }

        $sql_unidades = "";
        //Validamos que si no es administrador solo liste los cursos de las unidades vinculadas
        if ($admin == 0) {
            $sql_unidades = "AND pro.uaa_codigo in ({$Unidades})";
        }

        //Consultamos los datos basicos de los cursos
        $sql = "SELECT 
            cur.cur_codigo CurCodigo, 
            cur.cur_grupo CurGrupo, 
            cur.cur_estado CurEstado,
            cur.cur_cupo CurCupo, 
            asi.car_codigo CarCodigo, 
            asi.asi_codigo AsiCodigo, 
            asi.asi_nombre AsiNombre, 
            asi.asi_nombre_corto AsiNombreCorto, 
            uaa.uaa_codigo UaaCodigo,
            uaa.uaa_nombre_corto UaaNombreCorto,
            per.per_nombre+' '+per.per_apellido PerNombreCoordinador, 
            sed.sed_nombre SedNombre
        FROM 
            curso cur WITH (NOLOCK)
        LEFT JOIN plan_academico pla WITH (NOLOCK) ON pla.pla_codigo = cur.pla_codigo
        LEFT JOIN programa pro WITH (NOLOCK) ON pro.pro_codigo = pla.pro_codigo
        INNER JOIN asignatura asi WITH (NOLOCK) ON asi.asi_codigo = cur.asi_codigo
        INNER JOIN uaa uaa WITH (NOLOCK) ON uaa.uaa_codigo = asi.uaa_codigo
        INNER JOIN uaa_personal uap WITH (NOLOCK) ON uap.uap_codigo = cur.uap_codigo
        INNER JOIN persona per WITH (NOLOCK) ON per.per_codigo = uap.per_codigo
        INNER JOIN sede sed WITH (NOLOCK) ON sed.sed_codigo = cur.sed_codigo
        WHERE 
            cur.cal_codigo = {$CalCodigo}
            {$sql_unidades}
        ORDER BY 
            asi.asi_nombre
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar los cursos programados matriculados";
            return $this->errorConsultarBd;
        }

        //Almacenamos la respuesta de los cursos
        $r_cursos = $this->cnx->json;

        //Recorremos los cursos para buscar los subgrupos de cada uno.
        for ($i = 0; $i < count($r_cursos); $i++) {
            //consulta los subgrupos de cada curso iniciando con el 00 y luego los diferentes al 00
            $sql = "SELECT DISTINCT 
                eso.eso_subgrupo EsoSubgrupo, 
                null as CusCupo,
                per.per_identificacion PerIdentificacion, 
                per.per_apellido PerApellido, 
                per.per_nombre PerNombre
            FROM 
                espacio_ocupacion eso WITH (NOLOCK)
            INNER JOIN uaa_personal uap WITH (NOLOCK) ON eso.uap_codigo = uap.uap_codigo 
            INNER JOIN persona per WITH (NOLOCK) ON  uap.per_codigo = per.per_codigo
            WHERE  
                eso.eso_actividad = {$r_cursos[$i]['CurCodigo']} AND 
                eso.eso_subgrupo = '00'
            UNION ALL
            SELECT DISTINCT 
                eso.eso_subgrupo EsoSubgrupo, 
                ccs.cus_cupo CusCupo,
                per.per_identificacion PerIdentificacion, 
                per.per_apellido PerApellido, 
                per.per_nombre PerNombre
            FROM 
                espacio_ocupacion eso
            INNER JOIN uaa_personal uap ON eso.uap_codigo = uap.uap_codigo 
            INNER JOIN persona per ON  uap.per_codigo = per.per_codigo
            INNER JOIN curso_cupo_subgrupo ccs ON ccs.cur_codigo = eso.eso_actividad AND eso.eso_subgrupo = ccs.eso_subgrupo
            WHERE 
                eso.eso_actividad = {$r_cursos[$i]['CurCodigo']} AND 
                ccs.cus_estado = 1
            ";

            if (!$this->cnx->consultar($sql)) {
                $this->errorConsultarBd["consola"] = "Error al consultar los subgrupos del curso {$r_cursos[$i]['CurCodigo']} programado con matriculados";
                return $this->errorConsultarBd;
            }

            //Almacenamos la respuesta de los subgrupos.
            $r_subgrupo = $this->cnx->json;

            //Recorremos cada subgrupo para buscar la cantidad de matriculados de cada uno
            for ($j = 0; $j < count($r_subgrupo); $j++) {

                $sql_subgrupo = "";

                //Validamos si es el subgrupo 00 o diferente
                if ($r_subgrupo[$j]['EsoSubgrupo'] != "00") {
                    $sql_subgrupo = "mc.mac_subgrupo = {$r_subgrupo[$j]['EsoSubgrupo']} AND";
                }

                $sql = "SELECT 
                    count(*) TotalMatriculados 
                FROM 
                    matricula_curso mc
                INNER JOIN matricula ma ON mc.mat_codigo = ma.mat_codigo AND ma.mat_estado = 'A'
                WHERE 
                    mc.cur_codigo = {$r_cursos[$i]['CurCodigo']} AND 
                    {$sql_subgrupo}
                    mc.maa_codigo IN (1,2)
                ";

                if (!$this->cnx->consultar($sql)) {
                    $this->errorConsultarBd["consola"] = "Error al consultar los matriculados del curso {$r_cursos[$i]['CurCodigo']} subgrupo {$r_subgrupo[$j]['EsoSubgrupo']} programado con matriculados";
                    return $this->errorConsultarBd;
                }

                //Almacenamos la respuesta de la cantidad de matriculados.
                $r_matriculados = $this->cnx->json;

                for ($e = 0; $e < count($r_matriculados); $e++) {
                    //Almacenamos los datos del subgrupo y la cantidad de matriculados en un array

                    $array = [
                        "EsoSubgrupo" => $r_subgrupo[$j]['EsoSubgrupo'],
                        "CusCupo" => $r_subgrupo[$j]['CusCupo'],
                        "PerNombre" => $r_subgrupo[$j]['PerNombre'] . ' ' . $r_subgrupo[$j]['PerApellido'],
                        "TotalMatriculados" => $r_matriculados[$e]['TotalMatriculados']
                    ];
                    $r_cursos[$i]["listaSubgrupos"][$j] = array_map('utf8_encode', $array); //Se asigna al array final
                }
            }
        }

        //Se retorna el array final con todos los cursos con subgrupo y cantidad de matriculados
        return array(
            "resultado" => true,
            "mensaje" => "Subgrupos de curso consultados correctamente.",
            "count" => count($r_cursos),
            "data" => $r_cursos
        );
    }

    //Inicia funcion consultarCursosProgramadosSimple
    //Permite consultar la lista simple de cursos programados para un calendario especifico.
    function consultarCursosProgramadosSimple($obj)
    {
        //Parametros
        $CalCodigo = $obj->CalCodigo; //Contiene el codigo del calendario especifico a consultar
        $Unidades = $_SESSION["pacademica"]["datosVinculacionUsuario"]["unidades"]; //Contiene las unidades separadas por comas (,) que tiene el usuario logeado
        $admin = $_SESSION["pacademica"]["datosVinculacionUsuario"]["Administrador"]; //Contiene si es admin (1) o no (0)
        $usuario = $_SESSION["pacademica"]["datosVinculacionUsuario"]["usuarioCodigo"]; //Almacenamos el codigo del usuario

        if (!isset($obj->CalCodigo) || !is_numeric($obj->CalCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo del calendario.",
                "consola" => "El codigo del calendario no viene o no es numerico, " . $obj->CalCodigo,
            );
        }

        $sql_unidades = "";
        if ($admin == 0) {
            $permisoCurso = new PermisoCurso();
            $sql_unidades = "AND " . $permisoCurso->condicionPropietarioSql($usuario);
        }

        $sql = "SELECT 
            cur.cur_codigo CurCodigo, 
            cur.cur_grupo CurGrupo, 
            cur.cur_estado CurEstado,
            cur.cur_cupo CurCupo, 
            asi.car_codigo CarCodigo, 
            asi.asi_codigo AsiCodigo, 
            asi.asi_nombre AsiNombre, 
            asi.asi_nombre_corto AsiNombreCorto, 
            uaa.uaa_codigo UaaCodigo,
            uaa.uaa_nombre_corto UaaNombreCorto,
            per.per_nombre+' '+per.per_apellido PerNombreCoordinador, 
            sed.sed_nombre SedNombre,
            tic.tic_nombre TicNombre,
            (SELECT COUNT(*)
             FROM matricula_curso mc2
             INNER JOIN matricula ma2 ON mc2.mat_codigo = ma2.mat_codigo AND ma2.mat_estado = 'A'
             WHERE mc2.cur_codigo = cur.cur_codigo AND mc2.maa_codigo IN (1,2)
            ) AS TotalMatriculados
        FROM
            curso cur
        LEFT JOIN plan_academico pla ON pla.pla_codigo = cur.pla_codigo
        LEFT JOIN programa pro ON pro.pro_codigo = pla.pro_codigo
        INNER JOIN asignatura asi ON asi.asi_codigo = cur.asi_codigo
        INNER JOIN uaa uaa ON uaa.uaa_codigo = asi.uaa_codigo
        INNER JOIN uaa_personal uap ON uap.uap_codigo = cur.uap_codigo
        INNER JOIN persona per ON per.per_codigo = uap.per_codigo
        INNER JOIN sede sed ON sed.sed_codigo = cur.sed_codigo
        LEFT JOIN tipo_curso tic ON tic.tic_codigo = cur.tic_codigo
        WHERE 
            cur.cal_codigo = {$CalCodigo}
            {$sql_unidades}
        ORDER BY 
            asi.asi_nombre
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar los cursos programados simple";
            return $this->errorConsultarBd;
        }

        return array(
            "resultado" => true,
            "mensaje" => "Tipos de curso consultados correctamente.",
            "count" => count($this->cnx->json),
            "data" => $this->cnx->json
        );
    }

    //Inicio funcion consultarCalendario
    //Permite listar los calendarios activos
    function consultarCalendario()
    {
        $sql = "SELECT 
            TOP 15 
            cal_codigo CalCodigo, 
            cal_nombre CalNombre
        FROM 
            calendario 
        WHERE
            cal_nombre != 'desconocido'
        ORDER BY 
            cal_nombre
        DESC
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar los calendarios.";
            return $this->errorConsultarBd;
        }

        return array(
            "resultado" => true,
            "mensaje" => "Calendarios consultados correctamente.",
            "data" => $this->cnx->json
        );
    }
}
