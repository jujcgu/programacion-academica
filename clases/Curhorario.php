<?php
date_default_timezone_set('America/Bogota');
require_once(dirname(__FILE__) . '/servicios/FechaSqlServer.php');
require_once(dirname(__FILE__) . '/servicios/ValidarCargaDocenteService.php');
require_once(dirname(__FILE__) . '/Crucehorario.php');
require_once(dirname(__FILE__) . '/Cupocurso.php');
class Curhorario
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

    private function validarProcesoSeleccionable($PrpCodigo)
    {
        if ($PrpCodigo == 4) {
            return array(
                "resultado" => false,
                "mensaje" => "La repesca no se puede seleccionar para horarios de cursos.",
                "consola" => "Se intento usar el proceso de repesca (prp_codigo 4) en Horario Curso."
            );
        }

        return array("resultado" => true);
    }

    private function obtenerUnidadesIleusco()
    {
        return array(775);
    }

    private function esUnidadIleusco($uaaCodigo)
    {
        return in_array(intval($uaaCodigo), $this->obtenerUnidadesIleusco());
    }

    private function obtenerUnidadesBusquedaEspacios($uaaCodigo, $uaaDependencia = '', $incluirUnidadesSesion = false, $bloquearIleuscoSiNoSeleccionado = true)
    {
        $unidades = array();
        if (is_numeric($uaaCodigo)) {
            $unidades[] = intval($uaaCodigo);
        }

        if ($uaaDependencia !== '' && is_numeric($uaaDependencia)) {
            $unidades[] = intval($uaaDependencia);
        }

        if ($incluirUnidadesSesion && isset($_SESSION["pacademica"]["datosVinculacionUsuario"]["unidades"])) {
            $unidadesSesion = explode(",", $_SESSION["pacademica"]["datosVinculacionUsuario"]["unidades"]);
            foreach ($unidadesSesion as $unidadSesion) {
                if (is_numeric($unidadSesion)) {
                    $unidades[] = intval($unidadSesion);
                }
            }
        }

        if ($bloquearIleuscoSiNoSeleccionado && !$this->esUnidadIleusco($uaaCodigo)) {
            $unidades = array_diff($unidades, $this->obtenerUnidadesIleusco());
        }

        $unidades = array_values(array_unique($unidades));
        return implode(",", $unidades);
    }

    private function validarEspacioAsignadoProgramacion($obj)
    {
        $espTipo = isset($obj->EspTipo) ? trim($obj->EspTipo) : '';
        $espCodigo = isset($obj->EspCodigo) ? intval($obj->EspCodigo) : 0;
        if ($espTipo != 'F' || in_array($espCodigo, array(1310, 1311, 1312))) {
            return true;
        }

        $unidadesBusqueda = $this->obtenerUnidadesBusquedaEspacios($obj->UaaCodigo, isset($obj->UaaDependencia) ? $obj->UaaDependencia : '', true);
        if ($unidadesBusqueda == '') {
            return array(
                "resultado" => false,
                "mensaje" => "No se pudo validar la asignación del espacio porque no se definió la unidad.",
                "consola" => "UaaCodigo/UaaDependencia invalidos en validarEspacioAsignadoProgramacion()."
            );
        }

        $dateSql = FechaSqlServer::toSqlDateTime2(date("Y-m-d H:i"), false);
        if ($dateSql === false) {
            return array(
                "resultado" => false,
                "mensaje" => "Formato de fecha inválido para validar repesca del espacio.",
                "consola" => "No se pudo preparar la fecha actual para validar repesca en validarEspacioAsignadoProgramacion()."
            );
        }

        $sqlRepesca = "SELECT TOP 1 pra.cal_codigo CalCodigo
            FROM programacionacademica.programacion_academica pra
            WHERE
                pra.cal_codigo = {$obj->CalCodigo}
                AND pra.uaa_codigo = {$obj->UaaCodigo}
                AND {$dateSql} BETWEEN pra.pra_fecha_inicio AND pra.pra_fecha_fin
                AND pra.pra_estado = 1
                AND pra.prp_codigo = 4";

        if (!$this->cnx->consultar($sqlRepesca)) {
            return array(
                "resultado" => false,
                "mensaje" => "Error al validar repesca para el espacio seleccionado.",
                "consola" => "Fallo SQL validando repesca del espacio {$espCodigo}."
            );
        }

        if (count($this->cnx->json) > 0) {
            $unidadesBusqueda .= ",315";
        }

        $fechaProgramacion = date('Y-m-d', strtotime($obj->FechaInicio));
        $iteracionInicial = true;
        for ($i = 1; $i <= intval($obj->CurSemanas); $i++) {
            if ($iteracionInicial == false) {
                $fechaProgramacion = date("Y-m-d", strtotime($fechaProgramacion . "+ 1 week"));
            }
            $iteracionInicial = false;

            $fechaInicioDiaSql = FechaSqlServer::toSqlDateTime2($fechaProgramacion, false);
            $fechaFinDiaSql = FechaSqlServer::toSqlDateTime2($fechaProgramacion, true);
            if ($fechaInicioDiaSql === false || $fechaFinDiaSql === false) {
                return array(
                    "resultado" => false,
                    "mensaje" => "Formato de fecha inválido para validar asignación del espacio.",
                    "consola" => "No se pudo preparar la fecha {$fechaProgramacion} en validarEspacioAsignadoProgramacion()."
                );
            }

            foreach ($obj->HorasSeleccionadas as $hora) {
                $hora = intval($hora);
                $sql = "SELECT TOP 1
                        eso.uaa_codigo UaaCodigo,
                        uaa.uaa_nombre_corto UaaNombreCorto
                    FROM espacio_ocupacion eso
                    INNER JOIN uaa ON uaa.uaa_codigo = eso.uaa_codigo
                    WHERE
                        eso.esp_codigo = {$espCodigo}
                        AND eso.uaa_codigo IN ({$unidadesBusqueda})
                        AND eso.dia_codigo = {$obj->DiaCodigo}
                        AND eso.hra_codigo = {$hora}
                        AND eso.eso_actividad IS NULL
                        AND eso.eso_fecha BETWEEN {$fechaInicioDiaSql} AND {$fechaFinDiaSql}
                ";

                if (!$this->cnx->consultar($sql)) {
                    return array(
                        "resultado" => false,
                        "mensaje" => "Error al validar la asignación del espacio seleccionado.",
                        "consola" => "Fallo SQL validando asignación del espacio {$espCodigo}, fecha {$fechaProgramacion}, dia {$obj->DiaCodigo}, hora {$hora}."
                    );
                }

                if (count($this->cnx->json) < 1) {
                    return array(
                        "resultado" => false,
                        "mensaje" => "El espacio seleccionado no está asignado a la unidad/facultad para la fecha y hora seleccionada.",
                        "consola" => "Espacio {$espCodigo} sin asignación para unidades {$unidadesBusqueda}, fecha {$fechaProgramacion}, dia {$obj->DiaCodigo}, hora {$hora}."
                    );
                }
            }
        }

        return true;
    }

    private function consultarAforoMaximoSubgrupo($curCodigo, $subGrupo, $espCodigoAdicional = null)
    {
        $espaciosSinRestriccionAforo = "1310,1311,1312";

        $sqlEspacioEspecial = "SELECT TOP 1 1 Existe
                FROM (
                    SELECT eo.esp_codigo
                    FROM espacio_ocupacion eo
                WHERE
                    eo.eso_actividad = {$curCodigo}
                    AND eo.eso_subgrupo = '{$subGrupo}'
                " . ($espCodigoAdicional !== null && is_numeric($espCodigoAdicional) ? " UNION SELECT {$espCodigoAdicional} " : "") . "
            ) espacios
            WHERE espacios.esp_codigo IN ({$espaciosSinRestriccionAforo})";

        if (!$this->cnx->consultar($sqlEspacioEspecial)) {
            return array(
                "resultado" => false,
                "mensaje" => "Error al consultar si el subgrupo tiene espacio sin restricción de aforo.",
                "consola" => "No fue posible validar espacios especiales del curso {$curCodigo} subgrupo {$subGrupo}."
            );
        }

        if (count($this->cnx->json) > 0) {
            return array(
                "resultado" => true,
                "aforoMaximo" => null,
                "restriccionAforo" => false
            );
        }

        $unionEspacioAdicional = "";
        if ($espCodigoAdicional !== null && is_numeric($espCodigoAdicional)) {
            $unionEspacioAdicional = "
                UNION
                SELECT
                    esp.esp_codigo,
                    ISNULL(esp.esp_capacidad, 0) esp_capacidad
                FROM espacio esp
                WHERE esp.esp_codigo = {$espCodigoAdicional}
            ";
        }

        $sql = "SELECT
            MIN(aforo.esp_capacidad) AforoMaximo
        FROM (
            SELECT DISTINCT
                    eo.esp_codigo,
                    ISNULL(esp.esp_capacidad, 0) esp_capacidad
            FROM espacio_ocupacion eo
            INNER JOIN espacio esp ON esp.esp_codigo = eo.esp_codigo
            WHERE
                eo.eso_actividad = {$curCodigo}
                AND eo.eso_subgrupo = '{$subGrupo}'
                AND eo.esp_codigo NOT IN ({$espaciosSinRestriccionAforo})
            {$unionEspacioAdicional}
        ) aforo
        WHERE aforo.esp_capacidad > 0";

        if (!$this->cnx->consultar($sql)) {
            return array(
                "resultado" => false,
                "mensaje" => "Error al consultar el aforo máximo del subgrupo.",
                "consola" => "No fue posible consultar aforo del curso {$curCodigo} subgrupo {$subGrupo}."
            );
        }

        $resultado = $this->cnx->json;
        $aforoMaximo = null;
        if (count($resultado) > 0 && $resultado[0]['AforoMaximo'] !== null) {
            $aforoMaximo = intval($resultado[0]['AforoMaximo']);
        }

        return array(
            "resultado" => true,
            "aforoMaximo" => $aforoMaximo,
            "restriccionAforo" => true
        );
    }

    private function ajustarCupoSubgrupoPorAforo($curCodigo, $subGrupo)
    {
        $aforoSubgrupo = $this->consultarAforoMaximoSubgrupo($curCodigo, $subGrupo);
        if (!$aforoSubgrupo['resultado']) {
            return $aforoSubgrupo;
        }

        $aforoMaximo = $aforoSubgrupo['aforoMaximo'];
        if ($aforoMaximo === null) {
            return array(
                "resultado" => true,
                "aforoMaximo" => null,
                "cupoAjustado" => false,
                "mensajeInfo" => "No aplica restricción por aforo para el subgrupo {$subGrupo} (espacio de aula externa/sin salón/hospital o sin capacidad configurada)."
            );
        }

        if ($subGrupo == '00') {
            $sql = "SELECT cur_cupo CurCupo, cur_ampliacion_cupo CurAmpliacion
                FROM curso
                WHERE cur_codigo = {$curCodigo}";
            if (!$this->cnx->consultar($sql)) {
                return array(
                    "resultado" => false,
                    "mensaje" => "Error al consultar el cupo actual del curso.",
                    "consola" => "No fue posible consultar cupo del curso {$curCodigo}."
                );
            }

            if (count($this->cnx->json) < 1) {
                return array(
                    "resultado" => false,
                    "mensaje" => "No se encontró el curso para validar aforo.",
                    "consola" => "Curso {$curCodigo} no encontrado para ajuste por aforo."
                );
            }

            $curCupo = intval($this->cnx->json[0]['CurCupo']);
            $curAmpliacion = intval($this->cnx->json[0]['CurAmpliacion']);
            $limiteConGabela = Cupocurso::calcularLimiteConGabela($aforoMaximo);
            $sumaCupos = $curCupo + $curAmpliacion;

            if ($sumaCupos > $limiteConGabela) {
                $exceso = $sumaCupos - $limiteConGabela;
                if ($curAmpliacion >= $exceso) {
                    $curAmpliacion = $curAmpliacion - $exceso;
                } else {
                    $faltante = $exceso - $curAmpliacion;
                    $curAmpliacion = 0;
                    $curCupo = max(0, $curCupo - $faltante);
                }

                $sql = "UPDATE curso
                    SET
                        cur_cupo = {$curCupo},
                        cur_ampliacion_cupo = {$curAmpliacion},
                        cur_fecha_actualizacion = GETDATE()
                    WHERE cur_codigo = {$curCodigo}";
                if (!$this->cnx->sentencia($sql)) {
                    return array(
                        "resultado" => false,
                        "mensaje" => "Error al ajustar el cupo del curso por aforo.",
                        "consola" => "Falló el ajuste de cupo por aforo para curso {$curCodigo}."
                    );
                }

                return array(
                    "resultado" => true,
                    "aforoMaximo" => $aforoMaximo,
                    "cupoAjustado" => true,
                    "mensajeInfo" => "Aforo base teoría (00): {$limiteConGabela}. Se ajustó automáticamente para cumplir Cupo Total + Reserva <= Aforo + " . Cupocurso::obtenerGabelaCupoAforo() . "."
                );
            }

            return array(
                "resultado" => true,
                "aforoMaximo" => $aforoMaximo,
                "cupoAjustado" => false,
                "mensajeInfo" => "Aforo base teoría (00): {$limiteConGabela}."
            );
        }

        $sql = "SELECT cus_cod CusCodigo, cus_cupo CusCupo
            FROM curso_cupo_subgrupo
            WHERE
                cur_codigo = {$curCodigo}
                AND eso_subgrupo = '{$subGrupo}'
                AND cus_estado = 1";

        if (!$this->cnx->consultar($sql)) {
            return array(
                "resultado" => false,
                "mensaje" => "Error al consultar cupo del subgrupo.",
                "consola" => "No fue posible consultar cupo de subgrupo {$subGrupo} del curso {$curCodigo}."
            );
        }

        if (count($this->cnx->json) < 1) {
            return array(
                "resultado" => true,
                "aforoMaximo" => $aforoMaximo,
                "cupoAjustado" => false,
                "mensajeInfo" => "Aforo máximo permitido para el subgrupo {$subGrupo}: {$aforoMaximo}."
            );
        }

        $cusCodigo = intval($this->cnx->json[0]['CusCodigo']);
        $cusCupo = intval($this->cnx->json[0]['CusCupo']);

        if ($cusCupo > $aforoMaximo) {
            $sql = "UPDATE curso_cupo_subgrupo
                SET cus_cupo = {$aforoMaximo}
                WHERE cus_cod = {$cusCodigo}";
            if (!$this->cnx->sentencia($sql)) {
                return array(
                    "resultado" => false,
                    "mensaje" => "Error al ajustar cupo del subgrupo por aforo.",
                    "consola" => "Falló el ajuste de cupo del subgrupo {$subGrupo} del curso {$curCodigo}."
                );
            }

            return array(
                "resultado" => true,
                "aforoMaximo" => $aforoMaximo,
                "cupoAjustado" => true,
                "mensajeInfo" => "El aforo máximo permitido para el subgrupo {$subGrupo} es {$aforoMaximo}. Se ajustó automáticamente el cupo del subgrupo."
            );
        }

        return array(
            "resultado" => true,
            "aforoMaximo" => $aforoMaximo,
            "cupoAjustado" => false,
            "mensajeInfo" => "Aforo máximo permitido para el subgrupo {$subGrupo}: {$aforoMaximo}."
        );
    }

    //Inicio funcion consultarEspaciosAsignadosTotal
    //Permite consultar los espacios asignados a la unidad seleccionada y facultad
    function consultarEspaciosAsignadosTotal($obj)
    {
        //Validaciones
        if (!isset($obj->UaaCodigo) || !is_numeric($obj->UaaCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo de la unidad seleccionada.",
                "consola" => "El codigo de la unidad no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->CalCodigo) || !is_numeric($obj->CalCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo del calendario seleccionada.",
                "consola" => "El codigo del calendario no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->PerFechaInicio)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el la fecha inicial del periodo seleccionada.",
                "consola" => "La fecha inicial del periodo no se envio correctamente.",
            );
        }
        if (!isset($obj->PerFechaFin)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el la fecha inicial del periodo seleccionada.",
                "consola" => "La fecha inicial del periodo no se envio correctamente.",
            );
        }

        //Asignaciones
        $UaaCodigo = $obj->UaaCodigo; //Contiene el codigo de una unidad a la que se le va a programar.
        $UaaDependencia = $obj->UaaDependencia; //Contiene el codigo de la dependencia de la uaa seleccionada.
        $CalCodigo = $obj->CalCodigo; //Contiene el codigo del calendario seleccionado
        $explode_fecha_inicio_per = explode(" ", $obj->PerFechaInicio); //Las fechas vienen con la hora separada por espacio 2020-01-01 10:00
        $explode_fecha_fin_per = explode(" ", $obj->PerFechaFin); //Las fechas vienen con la hora separada por espacio 2020-01-01 10:00
        $PerFechaInicio = $explode_fecha_inicio_per[0]; //Contiene la fecha yyyy-mm-dd inicio del periodo seleccionado.
        $PerFechaFin = $explode_fecha_fin_per[0]; //Contiene la fecha yyyy-mm-dd fin del periodo seleccionado.
        $PeriodoPersonalizado = $obj->PeriodoPersonalizado; //Contiene si el periodo seleccionado tiene fecha personalizada.

        //Validamos que el periodo seleccionado tenga un calendario personalizado para la unidad seleccionada.
        if ($PeriodoPersonalizado != '') {
            $e_periodo_personalizado = explode(' ', $PeriodoPersonalizado);
            $PerFechaInicio = $e_periodo_personalizado[0];
            $PerFechaFin = $e_periodo_personalizado[1];
        }
        $PerFechaInicioSql = FechaSqlServer::toSqlDateTime2($PerFechaInicio, false);
        $PerFechaFinFinDiaSql = FechaSqlServer::toSqlDateTime2($PerFechaFin, true);
        if ($PerFechaInicioSql === false || $PerFechaFinFinDiaSql === false) {
            return array(
                "resultado" => false,
                "mensaje" => "Formato de fecha inválido para consultar espacios asignados.",
                "consola" => "No se pudo preparar fechas SQL del periodo ({$PerFechaInicio} - {$PerFechaFin}).",
            );
        }

        $unidades_busqueda = $this->obtenerUnidadesBusquedaEspacios($UaaCodigo, $UaaDependencia, true); //Contiene las unidades a buscar
        if ($unidades_busqueda == '') {
            return array(
                "resultado" => false,
                "mensaje" => "No se pudo definir la unidad para consultar espacios asignados.",
                "consola" => "UaaCodigo/UaaDependencia invalidos en consultarEspaciosAsignadosTotal().",
            );
        }

        //Consultamos si el programa al que vamos a programar tiene apertura de repesca activa sin vencer
        $date = date("Y-m-d H:i");
        $dateSql = FechaSqlServer::toSqlDateTime2($date, false);
        if ($dateSql === false) {
            return array(
                "resultado" => false,
                "mensaje" => "Formato de fecha inválido para validar repesca.",
                "consola" => "No se pudo preparar la fecha actual ({$date}) para SQL Server.",
            );
        }

        $sql = "SELECT
                *
            FROM programacionacademica.programacion_academica pra
            WHERE
                pra.cal_codigo = {$CalCodigo}
                AND pra.uaa_codigo = {$UaaCodigo}
                AND {$dateSql} BETWEEN pra.pra_fecha_inicio AND pra.pra_fecha_fin
                AND pra.pra_estado = 1
                AND pra.prp_codigo = 4
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar la repesca del programa. " . $this->cnx->mjeError;
            $this->errorConsultarBd["sql"] = $sql;
            return $this->errorConsultarBd;
        }

        $codigo_universidad = ""; //Tendra el codigo de la universidad en caso de tener repesca

        if (count($this->cnx->json) > 0) { //En caso de tener repesca activa se agrega el codigo de la universidad
            $codigo_universidad = ",315"; //El 315 es el codigo de la universidad y todos los espacios de repesca se asignan ahi.
        }


        $sql = "SELECT DISTINCT 
            sed.sed_nombre SedNombre, 
            sus.sus_nombre SusNombre, 
            blo.blo_nombre BloNombre, 
            esp.esp_codigo EspCodigo, 
            esp.esp_espacio_codigo EspEspCodigo, 
            esp.esp_nombre EspNombre, 
            esp.esp_nombre_corto EspNombreCorto, 
            esp.esp_compartido EspCompartido, 
            esp.esp_capacidad EspCapacidad,
            uaa.uaa_codigo UaaCodigo,
            uaa.uaa_nombre_corto UaaNombreCorto,
                min(eso.eso_fecha) AS FechaMinima, 
                max(eso.eso_fecha) AS FechaMaxima 
        FROM 
            sede sed
        INNER JOIN sub_sede sus ON sed.sed_codigo = sus.sed_codigo
        INNER JOIN bloque blo ON sus.sus_codigo = blo.sus_codigo 
        INNER JOIN espacio esp ON blo.blo_codigo = esp.blo_codigo 
        INNER JOIN espacio_ocupacion eso ON esp.esp_codigo = eso.esp_codigo 
        INNER JOIN uaa uaa on uaa.uaa_codigo = eso.uaa_codigo
        WHERE
            eso.uaa_codigo IN ({$unidades_busqueda}{$codigo_universidad}) 
                AND eso.eso_fecha BETWEEN {$PerFechaInicioSql} AND {$PerFechaFinFinDiaSql}
        GROUP BY sed.sed_nombre, 
            sus.sus_nombre, 
            blo.blo_nombre, 
            esp.esp_codigo, 
            esp.esp_espacio_codigo, 
            esp.esp_nombre, 
            esp.esp_nombre_corto, 
            esp.esp_compartido, 
            esp.esp_capacidad,
            uaa.uaa_codigo,
            uaa.uaa_nombre_corto 
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar los espacios asignados de la unidad(es): {$unidades_busqueda}{$codigo_universidad}.";
            $this->errorConsultarBd["sql"] = $sql;
            return $this->errorConsultarBd;
        }

        $r_espacios_asignados = $this->cnx->json; //Contiene los espacios asignados de la unidad.
        $arrayFinal = array(); //Contiene el arreglo final la agenda por cada espacio
        $dias = [
            1 => "Lunes",
            2 => "Martes",
            3 => "Miercoles",
            4 => "Jueves",
            5 => "Viernes",
            6 => "Sabado",
            7 => "Domingo"
        ];
        if (count($r_espacios_asignados) > 0) {
            foreach ($r_espacios_asignados as $espacios) {
                $array_espacios = [];
                $array_espacios = [ //Organizamos un array con los datos de los espacios
                    "SedNombre" => utf8_decode($espacios['SedNombre']),
                    "SusNombre" => utf8_decode($espacios['SusNombre']),
                    "BloNombre" => utf8_decode($espacios['BloNombre']),
                    "EspCodigo" => utf8_decode($espacios['EspCodigo']),
                    "EspEspCodigo" => utf8_decode($espacios['EspEspCodigo']),
                    "EspNombre" => utf8_decode($espacios['EspNombre']),
                    "EspNombreCorto" => utf8_decode($espacios['EspNombreCorto']),
                    "EspCompartido" => utf8_decode($espacios['EspCompartido']),
                    "EspCapacidad" => utf8_decode($espacios['EspCapacidad']),
                    "UaaCodigo" => utf8_decode($espacios['UaaCodigo']),
                    "UaaNombreCorto" => utf8_decode($espacios['UaaNombreCorto']),
                    "FechaMinima" => utf8_decode($espacios['FechaMinima']),
                    "FechaMaxima" => utf8_decode($espacios['FechaMaxima']),
                    "Agenda" => []
                ];

                //Agregamos los datos del espacio al array final siendo el codigo del espacio el index
                $array_espacios_codificado = [];
                foreach ($array_espacios as $campo => $valor) {
                    $array_espacios_codificado[$campo] = is_array($valor) ? $valor : utf8_encode($valor);
                }
                $array_espacios_codificado["Resumen"] = [
                    "Libres" => 0,
                    "Ocupados" => 0,
                    "NoAsignados" => 0
                ];
                $array_final[$espacios['EspCodigo']] = $array_espacios_codificado;

                //Por cada espacio buscamos la ocupacion
                // $sql = "SELECT DISTINCT 
                //     eso.dia_codigo DiaCodigo, 
                $PerFechaInicioSql = FechaSqlServer::toSqlDateTime2($PerFechaInicio, false);
                $PerFechaFinSql = FechaSqlServer::toSqlDateTime2($PerFechaFin, true);
                if ($PerFechaInicioSql === false || $PerFechaFinSql === false) {
                    return array(
                        "resultado" => false,
                        "mensaje" => "Formato de fechas inválido para consultar espacios asignados.",
                        "consola" => "No se pudieron preparar expresiones SQL para PerFechaInicio ({$PerFechaInicio}) o PerFechaFin ({$PerFechaFin})."
                    );
                }
                //     eso.hra_codigo HraCodigo, 
                //     eso.eso_actividad EsoActividad, 
                //     min(eso.eso_fecha) FechaInicial, 
                //     max(eso.eso_fecha) FechaFinal
                // FROM 
                //     espacio esp 
                $date = FechaSqlServer::nowIso8601();
                // WHERE 
                //     eso.uaa_codigo in ({$unidades_busqueda}) 
                //     AND eso.eso_fecha BETWEEN '{$PerFechaInicio}' AND '{$PerFechaFin}'
                //     AND eso.esp_codigo = {$espacios['EspCodigo']}
                // GROUP BY eso.dia_codigo, eso.hra_codigo, eso.eso_actividad";

                $sql = "SELECT
                    eso.dia_codigo DiaCodigo,
                    eso.hra_codigo HraCodigo,
                    eso.uaa_codigo UaaCodigo,
                    uaa.uaa_nombre_corto UaaNombreCorto,
                    eso.eso_actividad CurCodigo,
                    cur.cur_grupo CurGrupo,
                    asi.asi_nombre AsiNombre,
                    asi.asi_nombre_corto AsiNombreCorto,
                    asi.nuc_codigo NucCodigo,
                    per.per_nombre PerNombre,
                    per.per_apellido PerApellido,
                    esp.esp_codigo EspCodigo,
                    esp.esp_nombre_corto EspNombreCorto,
                    COUNT(*) TotalRegistros
                FROM
                    espacio_ocupacion eso
                INNER JOIN uaa ON uaa.uaa_codigo = eso.uaa_codigo
                INNER JOIN espacio esp ON eso.esp_codigo = esp.esp_codigo
                LEFT JOIN curso cur ON cur.cur_codigo = eso.eso_actividad
                LEFT JOIN asignatura asi ON asi.asi_codigo = cur.asi_codigo
                LEFT JOIN uaa_personal uap ON eso.uap_codigo = uap.uap_codigo
                LEFT JOIN persona per ON per.per_codigo = uap.per_codigo
                WHERE
                    eso.eso_fecha BETWEEN {$PerFechaInicioSql} AND {$PerFechaFinSql}
                    AND eso.esp_codigo = {$espacios['EspCodigo']}
                GROUP BY
                    eso.dia_codigo,
                    eso.hra_codigo,
                    eso.uaa_codigo,
                    uaa.uaa_nombre_corto,
                    eso.eso_actividad,
                    cur.cur_grupo,
                    asi.asi_nombre,
                    asi.asi_nombre_corto,
                    asi.nuc_codigo,
                    per.per_nombre,
                    per.per_apellido,
                    esp.esp_codigo,
                    esp.esp_nombre_corto
                ORDER BY
                    eso.dia_codigo,
                    eso.hra_codigo,
                    CASE WHEN eso.eso_actividad IS NOT NULL THEN 0 ELSE 1 END";

                if (!$this->cnx->consultar($sql)) {
                    $this->errorConsultarBd["consola"] = "Error al consultar la agenda de la unidad(es): {$unidades_busqueda}{$codigo_universidad} en el espacio: {$espacios['EspCodigo']}.";
                    return $this->errorConsultarBd;
                }

                $r_espacios_agenda = $this->cnx->json; //Contiene los espacios asignados de la unidad.
                $unidadesPermitidas = array_map('intval', explode(",", $unidades_busqueda . $codigo_universidad));

                $array_agenda = array();
                for ($h = 1; $h <= 18; $h++) {
                    for ($d = 1; $d <= 7; $d++) {
                        $registroOcupado = null;
                        $registroLibreAsignado = null;
                        $registroOtraUnidad = null;
                        foreach ($r_espacios_agenda as $agenda) {
                            if ($agenda["DiaCodigo"] == $d && $agenda["HraCodigo"] == $h) {
                                $perteneceUnidad = in_array(intval($agenda["UaaCodigo"]), $unidadesPermitidas);
                                $esIleuscoBloqueado = $this->esUnidadIleusco($agenda["UaaCodigo"]) && !$this->esUnidadIleusco($UaaCodigo);
                                if ($agenda["CurCodigo"] != '' || $esIleuscoBloqueado) {
                                    $registroOcupado = $agenda;
                                    break;
                                }

                                if ($perteneceUnidad) {
                                    $registroLibreAsignado = $agenda;
                                } elseif ($registroOtraUnidad === null) {
                                    $registroOtraUnidad = $agenda;
                                }
                            }
                        }

                        if ($registroOcupado !== null) {
                            $ocupadoPorIleusco = $registroOcupado["CurCodigo"] == '' && $this->esUnidadIleusco($registroOcupado["UaaCodigo"]) && !$this->esUnidadIleusco($UaaCodigo);
                            $array_agenda = [
                                "Estado" => "OCUPADO",
                                "EstadoNombre" => $ocupadoPorIleusco ? "Ocupado por ILEUSCO" : "Ocupado",
                                "OcupadoPorIleusco" => $ocupadoPorIleusco ? 1 : 0,
                                "CurCodigo" => utf8_decode($registroOcupado['CurCodigo']),
                                "AsiNombre" => utf8_decode($registroOcupado['AsiNombre']),
                                "AsiNombreCorto" => utf8_decode($registroOcupado['AsiNombreCorto']),
                                "CurGrupo" => utf8_decode($registroOcupado['CurGrupo']),
                                "PerNombre" => utf8_decode($registroOcupado['PerNombre']),
                                "PerApellido" => utf8_decode($registroOcupado['PerApellido']),
                                "DiaCodigo" => utf8_decode($registroOcupado['DiaCodigo']),
                                "HraCodigo" => utf8_decode($registroOcupado['HraCodigo']),
                                "UaaNombreCorto" => utf8_decode($registroOcupado['UaaNombreCorto']),
                                "UaaCodigo" => utf8_decode($registroOcupado['UaaCodigo']),
                                "NucCodigo" => utf8_decode($registroOcupado['NucCodigo']),
                                "EspCodigo" => utf8_decode($registroOcupado['EspCodigo']),
                                "EspNombreCorto" => utf8_decode($registroOcupado['EspNombreCorto']),
                            ];
                            $array_final[$espacios['EspCodigo']]['Resumen']['Ocupados']++;
                        } elseif ($registroLibreAsignado !== null) {
                            $array_agenda = [
                                "Estado" => "LIBRE",
                                "EstadoNombre" => "Libre",
                                "DiaCodigo" => utf8_decode($registroLibreAsignado['DiaCodigo']),
                                "HraCodigo" => utf8_decode($registroLibreAsignado['HraCodigo']),
                                "UaaNombreCorto" => utf8_decode($registroLibreAsignado['UaaNombreCorto']),
                                "UaaCodigo" => utf8_decode($registroLibreAsignado['UaaCodigo']),
                                "EspCodigo" => utf8_decode($registroLibreAsignado['EspCodigo']),
                                "EspNombreCorto" => utf8_decode($registroLibreAsignado['EspNombreCorto']),
                            ];
                            $array_final[$espacios['EspCodigo']]['Resumen']['Libres']++;
                        } else {
                            $array_agenda = [
                                "Estado" => "NO_ASIGNADO",
                                "EstadoNombre" => "No asignado",
                                "DiaCodigo" => $d,
                                "HraCodigo" => $h,
                                "DiaNombre" => $dias[$d],
                                "UaaNombreCorto" => $registroOtraUnidad !== null ? utf8_decode($registroOtraUnidad['UaaNombreCorto']) : '',
                                "UaaCodigo" => $registroOtraUnidad !== null ? utf8_decode($registroOtraUnidad['UaaCodigo']) : '',
                                "EspCodigo" => utf8_decode($espacios['EspCodigo']),
                                "EspNombreCorto" => utf8_decode($espacios['EspNombreCorto']),
                            ];
                            $array_final[$espacios['EspCodigo']]['Resumen']['NoAsignados']++;
                        }
                        $array_final[$espacios['EspCodigo']]['Agenda'][$h][$d] = array_map('utf8_encode', $array_agenda);
                    }
                }
            }
            return array(
                "resultado" => true,
                "mensaje" => "Espacios asignados consultados correctamente.",
                "data" => $array_final,
            );
        } else {
            return array(
                "resultado" => true,
                "mensaje" => "Esta unidad no cuenta con espacios asignados entre el {$PerFechaInicio} y {$PerFechaFin}."
            );
        }
    }

    //Inicia funcion guardarHorario
    //Permite guardar el horario de un curso despues de haber validado la cantidad de horas permitidas segun el docente.
    function guardarHorario($obj)
    {
        //Se valida que exista el PerNN que significa que si el docente seleccionado es NN o Persona
        if (!isset($obj->PerNN)) {
            //En el caso de no existir en el arreglo significa que venia siendo de valor false.
            $obj->PerNN = 0;
        } else {
            //En el caso de que exista en el arreglo significa que es venia siendo true.
            $obj->PerNN = 1;
        }

        $PerCodigo = $obj->PerCodigo; //Contiene el codigo del periodo.
        $CalCodigo = $obj->CalCodigo; //Contiene el codigo del calendario.
        $CalNombre = $obj->CalNombre; //Contiene el nombre del calendario.
        $TipoCalendario = substr($CalNombre, -1); //Contiene el tipo de calendario A: Pregrado, C: Postgrados, D: Distancia
        $UaaCodigo = $obj->UaaCodigo; //Contiene el codigo de la uaa.
        $PraCodigo = $obj->PraCodigo; //Contiene el codigo de la uaa.
        $FechaInicio = $obj->FechaInicio; //Contiene la fecha de inicio que se va a programar el curso
        $FechaFin = $obj->FechaFin; //Contiene la fecha de fin que se va a programar el curso
        $FechaInicioIso = FechaSqlServer::normalizarIso8601($FechaInicio, false);
        $FechaFinIso = FechaSqlServer::normalizarIso8601($FechaFin, false);
        if ($FechaInicioIso === false || $FechaFinIso === false) {
            return array(
                "resultado" => false,
                "mensaje" => "Formato de fecha inválido para programar el curso.",
                "consola" => "No se pudo convertir FechaInicio ({$FechaInicio}) o FechaFin ({$FechaFin}) a fecha válida.",
            );
        }
        $FechaInicio = substr($FechaInicioIso, 0, 10);
        $FechaFin = substr($FechaFinIso, 0, 10);
        $FechaInicioSql = FechaSqlServer::toSqlDateTime2($FechaInicio, false);
        $FechaInicioFinDiaSql = FechaSqlServer::toSqlDateTime2($FechaInicio, true);
        $FechaFinSql = FechaSqlServer::toSqlDateTime2($FechaFin, false);
        $FechaFinFinDiaSql = FechaSqlServer::toSqlDateTime2($FechaFin, true);
        if ($FechaInicioSql === false || $FechaInicioFinDiaSql === false || $FechaFinSql === false || $FechaFinFinDiaSql === false) {
            return array(
                "resultado" => false,
                "mensaje" => "Formato de fecha inválido para programar el curso.",
                "consola" => "No se pudo preparar expresiones SQL para FechaInicio ({$FechaInicio}) o FechaFin ({$FechaFin}).",
            );
        }
        $CurCodigo = $obj->CurCodigo; //Contiene el codigo del curso seleccionado
        $HorasSeleccionadas = $obj->HorasSeleccionadas; //Contiene las horas que seleccionaron para crear el curso
        $SubGrupo = $obj->SubGrupo; //Contiene el subgrupo del curso seleccionado 00 Teoria , 01,02,03,etc Practica
        $DiaCodigo = $obj->DiaCodigo; //Contiene el codigo del dia seleccionado.
        $EspCodigo = $obj->EspCodigo; //Contiene el codigo del espacio donde se va a agendar.
        $CurSemanas = $obj->CurSemanas; //Contiene el numero de semanas del curso seleccionado.
        $CupoSubgrupo = $obj->CupoSubgrupo; //Contiene el cupo del subgrupo 01,02,03,etc. Solo aplica para difernte del 00
        $UapCodigo = $obj->UapCodigo; //Contiene el Codigo de la vinculacion del docente seleccionado.
        $mensajeAforoPrevalidacion = "";

        if ($SubGrupo != '00') {
            $aforoConEspacio = $this->consultarAforoMaximoSubgrupo($CurCodigo, $SubGrupo, $EspCodigo);
            if (!$aforoConEspacio['resultado']) {
                return $aforoConEspacio;
            }

            if ($aforoConEspacio['aforoMaximo'] !== null) {
                $aforoMaximoSubgrupo = intval($aforoConEspacio['aforoMaximo']);
                if (intval($CupoSubgrupo) > $aforoMaximoSubgrupo) {
                    $CupoSubgrupo = $aforoMaximoSubgrupo;
                    $mensajeAforoPrevalidacion = "El aforo máximo permitido para el subgrupo {$SubGrupo} es {$aforoMaximoSubgrupo}. Se ajustó automáticamente el cupo del subgrupo.";
                } else {
                    $mensajeAforoPrevalidacion = "Aforo máximo permitido para el subgrupo {$SubGrupo}: {$aforoMaximoSubgrupo}.";
                }
            } else {
                $mensajeAforoPrevalidacion = "No hay espacios con aforo configurado para el subgrupo {$SubGrupo}.";
            }
        }

        $sql = "SELECT 
            pra.pra_codigo PraCodigo, 
            pra.pra_fecha_inicio PraFechaInicio, 
            pra.pra_fecha_fin PraFechaFin,
            pra.pra_estado PraEstado,

            pra.uaa_codigo UaaCodigo,

            prp.prp_codigo PrpCodigo, 
            prp.prp_nombre PrpNombre, 

            cal.cal_codigo CalCodigo, 
            cal.cal_nombre CalNombre,

            per.per_fecha_inicio PerFechaInicio,
            per.per_fecha_fin PerFechaFin,
            per.per_codigo PerCodigo,
            per.per_nombre PerNombre,

            (
                SELECT 
                    convert(varchar, peu_fecha_inicio) + ' ' + convert(varchar, peu_fecha_fin) PeriodoPersonalizado
                FROM
                    programacionacademica.periodo_unidad 
                WHERE
                    uaa_codigo = {$UaaCodigo} AND
                    per_codigo = per.per_codigo AND
                    peu_estado = 1
            ) PeriodoPersonalizado,

            convert(varchar, cal.cal_codigo) + convert(varchar,'. ') + cal.cal_nombre + ' ' + prp.prp_nombre CalCodigoNombreProceso


        FROM 
            programacionacademica.programacion_academica  pra
        INNER JOIN programacion_proceso prp ON prp.prp_codigo = pra.prp_codigo
        INNER JOIN calendario cal ON cal.cal_codigo = pra.cal_codigo and cal.cal_codigo = {$CalCodigo}
        INNER JOIN periodo per on cal.per_codigo = per.per_codigo

        WHERE 
            pra.uaa_codigo = {$UaaCodigo} 
            and pra.pra_codigo = {$PraCodigo} 
            and pra.pra_estado = 1
        ORDER BY pra.pra_fecha_inicio, pra.pra_fecha_fin DESC";
        header("Creacion: 331");
        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar la apertura .";
            return $this->errorConsultarBd;
        }

        $r_apertura = $this->cnx->json;
        if (count($r_apertura) > 0) {
            $validacionProceso = $this->validarProcesoSeleccionable($r_apertura[0]["PrpCodigo"]);
            if (!$validacionProceso["resultado"]) {
                return $validacionProceso;
            }
        }

        for ($i = 0; $i < count($r_apertura); $i++) {
            $date = date('Y-m-d');
            if ($date > $r_apertura[$i]['PraFechaFin']) {
                $r_apertura[$i]['Vencida'] = 1;
            } else {
                $r_apertura[$i]['Vencida'] = 0;
            }

            $r_apertura[$i]['PraFechaInicio'] =  date("Y-m-d", strtotime($r_apertura[$i]['PraFechaInicio']));
            $r_apertura[$i]['PraFechaFin'] =  date("Y-m-d", strtotime($r_apertura[$i]['PraFechaFin']));

            $r_apertura[$i]['PerFechaInicio'] =  date("Y-m-d", strtotime($r_apertura[$i]['PerFechaInicio']));
            $r_apertura[$i]['PerFechaFin'] =  date("Y-m-d", strtotime($r_apertura[$i]['PerFechaFin']));

            header("PraFechas: {$r_apertura[$i]['PraFechaInicio']} - {$r_apertura[$i]['PraFechaFin']}");
            header("PerFechas: {$r_apertura[$i]['PerFechaInicio']} - {$r_apertura[$i]['PerFechaFin']}");
            header("Personalizado1: {$r_apertura[$i]['PeriodoPersonalizado']}");
        }
        $PerFechaInicio = "";
        $PerFechaFin = "";

        foreach ($r_apertura as $apertura) {
            if ($apertura["PeriodoPersonalizado"] == '') {
                $PerFechaInicio = $apertura["PerFechaInicio"];
                $PerFechaFin = $apertura["PerFechaFin"];
                header("SinPersonalizado: {$PerFechaInicio} - {$PerFechaFin}");
            } else {
                $fecha_personalizada = explode(" ", $apertura["PeriodoPersonalizado"]);
                $PerFechaInicio = $fecha_personalizada[0];
                $PerFechaFin = $fecha_personalizada[1];
                header("ConPersonalizado: {$PerFechaInicio} - {$PerFechaFin}");
            }
        }

        $validacion_entre_fechas = 0; //Contiene variable para comprobar si las fechas de inicio y fin del curso esten entre las fechas de inicio y fin del periodo. 0 si esta mal y 1 si estan en el rango correcto.
        if (($FechaInicio >= $PerFechaInicio && $FechaInicio <= $PerFechaFin) && ($FechaFin >= $PerFechaInicio && $FechaFin <= $PerFechaFin)) {
            $validacion_entre_fechas = 1;
        }

        if ($_SESSION["pacademica"]["datosVinculacionUsuario"]["Administrador"] == 1 || $TipoCalendario == 'C') {
            $validacion_entre_fechas = 1;
        }
        header("ValidacionEntreFechas: {$validacion_entre_fechas}");
        if ($validacion_entre_fechas != 1 || !isset($validacion_entre_fechas)) {
            return array(
                "resultado" => false,
                "mensaje" => "Las fechas que ingreso del curso <b>{$CurCodigo} ({$FechaInicio} hasta {$FechaFin})</b> estan fuera del rango de las fechas del periodo <b>{$CalNombre} ({$PerFechaInicio} hasta {$PerFechaFin})</b>.",
                "consola" => "Las fechas se encuentran fuera del rango del periodo, fechas del curso {$CurCodigo} {$FechaInicio} hasta {$FechaFin}, fechas del periodo {$CalNombre} {$PerFechaInicio} hasta {$PerFechaFin}.",
            );
        }

        $validacionEspacioAsignado = $this->validarEspacioAsignadoProgramacion($obj);
        if ($validacionEspacioAsignado !== true) {
            return $validacionEspacioAsignado;
        }

        $existen_horas_programadas = false; //Contiene variable para comprobar que no permita programar una misma hora de un curso con dos profesores diferentes

        //Validación que no permita programar una misma hora de un curso con dos profesores diferentes
        foreach ($HorasSeleccionadas as $Horas) {
            $sql = "SELECT 
                count(*) as CantidadHoras
            FROM espacio_ocupacion eso 
            INNER JOIN uaa_personal uap ON uap.uap_codigo = eso.uap_codigo
            INNER JOIN persona per ON per.per_codigo = uap.per_codigo
            WHERE 
                eso.eso_actividad = {$CurCodigo}
                AND eso.eso_subgrupo = '{$SubGrupo}'
                AND dia_codigo = {$DiaCodigo}
                AND hra_codigo = {$Horas}
                AND (
                    (eso_fecha BETWEEN {$FechaInicioSql} AND {$FechaInicioFinDiaSql})
                    OR (eso_fecha BETWEEN {$FechaFinSql} AND {$FechaFinFinDiaSql})
                )
		    ";
            header("Creacion: 402");
            if (!$this->cnx->consultar($sql)) {
                $this->errorConsultarBd["consola"] = "Error al validar una misma hora de un curso con dos profesores diferentes.";
                return $this->errorConsultarBd;
            }

            $r_horas_existen = $this->cnx->json;

            //Se valida que la cantidad de horas sea mayor, significa que ya esta programada esa hora del curso con el mismo u otro profesor
            if ($r_horas_existen[0]['CantidadHoras'] > 0) {
                $existen_horas_programadas = true; //En caso de ser mayor a 0 significa que tiene horas y se marca como verdadero
            }
        }

        //En caso de que existan horas programadas para el mismo curso, dia, hora y docente se retorna un mensaje de error.
        if ($existen_horas_programadas) {
            return array(
                "resultado" => false,
                "mensaje" => "La hora que intenta programar ya esta programadas. Una misma hora no puede estar repetida.",
                "consola" => "El curso: {$CurCodigo}-{$SubGrupo}, dia: {$DiaCodigo}, fechas: {$FechaInicio} hasta: {$FechaFin}"
            );
        }

        foreach ($HorasSeleccionadas as $Horas) {
            //Se busca en base a las asignaciones
            $sql = "SELECT 
                count(*) AS Cuenta, 
                esp.esp_compartido Compartido
            FROM 
                espacio esp 
            INNER JOIN espacio_ocupacion eso ON esp.esp_codigo = eso.esp_codigo
			WHERE 
                eso.eso_fecha BETWEEN {$FechaInicioSql} AND {$FechaFinFinDiaSql}
                AND eso.dia_codigo = {$DiaCodigo}
				AND eso.hra_codigo = {$Horas}
                AND eso.esp_codigo = {$EspCodigo}
				AND eso.eso_actividad IS NOT NULL
            GROUP BY esp.esp_compartido";

            if (!$this->cnx->consultar($sql)) {
                $this->errorConsultarBd["consola"] = "Error al validar si el espacio ya se encuentra asignado en ese horario.";
                return $this->errorConsultarBd;
            }
            header("Creacion: 446");
            $r_asignaciones = $this->cnx->json;

            foreach ($r_asignaciones as $asignaciones) {
                //Validamos que la cantidad de horas no sea mayor a 0, de lo contrario significa que ya tiene horas ocupadas en ese horario
                //Validamos que el espacio sea compartido S o no compartido N
                if ($asignaciones["Cuenta"] > 0 && strtoupper($asignaciones["Compartido"]) == 'N') {
                    return array(
                        "resultado" => false,
                        "mensaje" => "La hora que intenta programar ya esta programadas o el espacio no es compartido.",
                    );
                }
            }
        }

        //Validacion para ver si es un subgrupo diferente a 00 dado que solo los 01,02,03,etc se guarda el cupo del subgrupo.
        //La informacion del subgrupo 00 se guarda en la tabla curso
        //La informacion del subgrupo 01,02,03, etc se guarda en la tabla curso_cupo_subgrupo
        if ($SubGrupo != '00') {
            //Prueba CurCodigo:171756	SubGrupo:04	CupoSubgrupo:10
            $sql = "SELECT 
                ccs.cus_cod CusCodigo, 
                ccs.cur_codigo CurCodigo, 
                ccs.eso_subgrupo EsoSubgrupo, 
                ccs.cus_cupo CusCupo 
            FROM 
                curso_cupo_subgrupo ccs
			where 
                ccs.cur_codigo = {$CurCodigo} 
                and ccs.eso_subgrupo = '{$SubGrupo}'     
            ";
            header("Creacion: 478");
            if (!$this->cnx->consultar($sql)) {
                $this->errorConsultarBd["consola"] = "Error al validar si un subgrupo 01,02,03,etc esta configurado.";
                return $this->errorConsultarBd;
            }

            $r_asignaciones = $this->cnx->json;

            if (count($r_asignaciones) > 0) {
                //Se verifica si el cupo es diferente al cupo que se envia desde el formulario
                $query = '';
                if ($r_asignaciones[0]["CusCupo"] != $CupoSubgrupo) {
                    //Si es diferente se cambia el estado y el cupo.
                    //En el caso de ser iguales se cambia solamente el estado.
                    $query = ",cus_cupo = {$CupoSubgrupo}";
                }

                $sql = "UPDATE 
                    curso_cupo_subgrupo 
                SET 
                    cus_estado = 1
                    {$query} 
                WHERE cus_cod = {$r_asignaciones[0]["CusCodigo"]}
                ";
                header("Creacion: 502");
                if (!$this->cnx->sentencia($sql)) {
                    $this->errorSentenciaBd["mensaje"] = "Error al actualizar la configuracion del subgrupo.";
                    $this->errorSentenciaBd["consola"] = "Ha fallado la actualizacion de la configuracion del curso: {$CurCodigo}, 
                    subgrupo: {$CupoSubgrupo}, configuracion codigo: {$r_asignaciones[0]["CusCodigo"]}.";
                    return $this->errorSentenciaBd;
                }
            } else {
                //En caso de no encontrar registros se inserta en la tabla uno nuevo
                $sql = "INSERT INTO 
                    curso_cupo_subgrupo (
                        cur_codigo,
                        eso_subgrupo,
                        cus_cupo,
                        cus_estado,
                        cus_fecha_registro
                    )
				    VALUES( 
                        {$CurCodigo},
                        '{$SubGrupo}',
                        {$CupoSubgrupo},
                        1,
                        getdate()
                    )";
                header("Creacion: 526");
                if (!$this->cnx->sentencia($sql)) {
                    $this->errorSentenciaBd["mensaje"] = "Error al crear la configuracion del subgrupo.";
                    $this->errorSentenciaBd["consola"] = "Ha fallado la creacion de la configuracion del curso: {$CurCodigo}, 
                    subgrupo: {$CupoSubgrupo}, configuracion codigo: {$r_asignaciones[0]["CusCodigo"]}.";
                    return $this->errorSentenciaBd;
                }
            }
        }

        $fecha_programacion = $FechaInicio; //Es la fecha en la que se realizara el primer insert.
        $iteracion_inicial = true; //Se usa para controlar si es la primer iteración, en el caso de ser la primera no se suma ningun dia.
        //Se recorre la cantidad de semanas para crear en espacio ocupacion
        for ($i = 1; $i <= $CurSemanas; $i++) {
            if ($iteracion_inicial == false) {
                $fecha_programacion = date("Y-m-d", strtotime($fecha_programacion . "+ 1 week"));
            }
            $iteracion_inicial = false;
            //Una vez determinada la fecha en que se desea programar, se recorren las horas seleccionadas
            foreach ($HorasSeleccionadas as $Horas) {
                // $this->cnx->Sentencia("BEGIN TRAN");
                $fechaProgramacionSql = FechaSqlServer::toSqlDateTime2($fecha_programacion, false);
                if ($fechaProgramacionSql === false) {
                    return array(
                        "resultado" => false,
                        "mensaje" => "Formato de fecha inválido al crear horario.",
                        "consola" => "No se pudo preparar la fecha de programación {$fecha_programacion}.",
                    );
                }
                $sql = "INSERT INTO espacio_ocupacion (
                        esp_codigo, 
                        uaa_codigo, 
                        eso_fecha, 
                        dia_codigo, 
                        hra_codigo, 
                        eso_estado,
                        eso_actividad, 
                        uap_codigo,
                        eso_subgrupo,
                        usu_codigo
                    ) 
                    VALUES(
                        {$EspCodigo},
                        {$UaaCodigo},
                        {$fechaProgramacionSql}, 
                        {$DiaCodigo}, 
                        {$Horas},
                        'G',
                        {$CurCodigo},
                        {$UapCodigo},
                        '{$SubGrupo}',
                        {$_SESSION['pacademica']['datosVinculacionUsuario']['usuarioCodigo']}
                    )
                    ";
                header("Creacion: 573");
                if (!$this->cnx->Sentencia($sql)) {
                    $this->errorSentenciaBd["mensaje"] = "Error al crear en el curso {$CurCodigo}, dias: {$DiaCodigo}, hora: {$Horas}.";
                    $this->errorSentenciaBd["consola"] = "Error al insertar registro en el curso {$CurCodigo}, dias: {$DiaCodigo}, hora: {$Horas}, espacio: {$EspCodigo}";
                    // $this->cnx->Sentencia("ROLLBACK TRAN"); //Se realiza un rollback si se encuentra un error
                    return $this->errorSentenciaBd;
                }
                // $this->cnx->Sentencia("COMMIT TRAN"); //Se ejecutan las sentencias pendientes.
            }
        }
        $actualizacion = $this->actualizarAgenda($CurCodigo);

        $ajusteAforo = $this->ajustarCupoSubgrupoPorAforo($CurCodigo, $SubGrupo);
        if (!$ajusteAforo['resultado']) {
            return $ajusteAforo;
        }

        $mensajeAforo = $ajusteAforo['mensajeInfo'];
        if ($mensajeAforoPrevalidacion != '') {
            $mensajeAforo = $mensajeAforoPrevalidacion;
        }

        if ($actualizacion) {
            header("Creacion: 584");
            return array(
                "resultado" => true,
                "mensaje" => "Curso programado correctamente, la agenda se actualizó correctamente. {$mensajeAforo}",
                "AforoMaximo" => $ajusteAforo['aforoMaximo'],
                "CupoAjustadoAutomaticamente" => $ajusteAforo['cupoAjustado']
            );
        } else {
            header("Creacion: 590"); //169172
            return array(
                "resultado" => true,
                "mensaje" => "Curso programado correctamente, la agenda no se actualizó correctamente. {$mensajeAforo}",
                "AforoMaximo" => $ajusteAforo['aforoMaximo'],
                "CupoAjustadoAutomaticamente" => $ajusteAforo['cupoAjustado']
            );
        }
    }

    //Inica funcion consultarHora
    //Permite consultar las horas libres para un determinado dia, docente, espacio y fechas de inicio -> fin
    function consultarHora($obj)
    {
        //Validaciones
        if (!isset($obj->UapCodigo) || !is_numeric($obj->UapCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo de vinculación del docente.",
                "consola" => "El codigo de vinculación del docente no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->UaaCodigo) || !is_numeric($obj->UaaCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo de unidad seleccionada.",
                "consola" => "El codigo de la unidad no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->FechaInicio)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio la fecha inicial.",
                "consola" => "La fecha inicial del curso no se envio correctamente.",
            );
        }
        if (!isset($obj->FechaFin)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio la fecha final.",
                "consola" => "La fecha final del curso no se envio correctamente.",
            );
        }
        if (!isset($obj->CurCodigo) || !is_numeric($obj->CurCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo del curso seleccionado.",
                "consola" => "El codigo del curso no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->EspCodigo) || !is_numeric($obj->EspCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo del espacio.",
                "consola" => "El codigo del espacio no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->DiaCodigo) || !is_numeric($obj->DiaCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo del dia.",
                "consola" => "El codigo del dia no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->EspTipo) || $obj->EspTipo == '') {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el tipo de espacio.",
                "consola" => "El tipo de espacio está vacio o no se envio correctamente.",
            );
        }
        if (!isset($obj->CalCodigo) || !is_numeric($obj->CalCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo del calendario.",
                "consola" => "El codigo del calendario no es numérico o no se envio correctamente.",
            );
        }

        //Asignaciones
        $UapCodigo = $obj->UapCodigo; //Contiene el codigo de vinculacion del docente seleccionado
        $UaaCodigo = $obj->UaaCodigo; //Contiene el codigo de una unidad a la que se le va a programar.
        $unidades = $_SESSION["pacademica"]["datosVinculacionUsuario"]["unidades"]; // Contiene las unidades vinculadas al usuario.
        $FechaInicio = $obj->FechaInicio; //Contiene la fecha yyyy-mm-dd inicio de la programacion del curso seleccionado.
        $FechaFin = $obj->FechaFin; //Contiene la fecha yyyy-mm-dd fin de la programacion del curso seleccionado
        $FechaInicioSql = FechaSqlServer::toSqlDateTime2($FechaInicio, false);
        $FechaFinFinDiaSql = FechaSqlServer::toSqlDateTime2($FechaFin, true);
        if ($FechaInicioSql === false || $FechaFinFinDiaSql === false) {
            return array(
                "resultado" => false,
                "mensaje" => "Formato de fecha inválido al consultar horas disponibles.",
                "consola" => "No se pudieron preparar fechas SQL de rango ({$FechaInicio} - {$FechaFin}).",
            );
        }
        $CurCodigo = $obj->CurCodigo; //Contiene el codigo del curso seleccionado
        $EspCodigo = $obj->EspCodigo; //Contiene el espacio fisico/aula externa seleccionado
        $DiaCodigo = $obj->DiaCodigo; //Contiene el dia que se va a programar.
        $EspTipo = $obj->EspTipo; //Contiene el tipo de espacio que se va a programar V (Virtual) o F (Fisico)
        $CalCodigo = $obj->CalCodigo; //Contiene el codigo del calendario en el que se va a programar
        $mensaje_horas_cruzadas = "";

        //Se comenta esta seccion por que al momento de validar los cruces de horarios de los estudiantes, demora
        //mas de 3min para cargar. Es una funcionabilidad importante y seria bueno implementarla.

        //Query para consultar si a un estudiante se le cruza las horas con algo que tenga programado.
        // $sql = "SELECT DISTINCT 
        //     hra_codigo HraCodigo
        // FROM 
        //     estudiante e, 
        //     matricula m, 
        //     matricula_curso mc, 
        //     curso c, 
        //     espacio_ocupacion eo 
        // WHERE 
        //     e.est_codigo = m.est_codigo 
        //     and m.mat_codigo = mc.mat_codigo 
        //     and c.cur_codigo = mc.cur_codigo 
        //     and c.cur_codigo = eo.eso_actividad 
        //     and mc.maa_codigo in(1,2) 
        //     and m.cal_codigo = {$CalCodigo} --Tenia el codigo del calendario quemado por defecto 120, dudo que mostrara si a un estudiante se le cruza el horario.
        //     and ( mac_subgrupo = eso_subgrupo or eso_subgrupo = '00' ) 
        //     and eo.dia_codigo = {$DiaCodigo}
        //     and e.est_codigo in (
        //         SELECT DISTINCT 
        //             e.est_codigo 
        //         FROM 
        //             estudiante e, 
        //             matricula m, 
        //             matricula_curso mc, 
        //             curso c, 
        //             espacio_ocupacion eo 
        //         WHERE 
        //             e.est_codigo = m.est_codigo 
        //             and m.mat_codigo = mc.mat_codigo 
        //             and c.cur_codigo = mc.cur_codigo 
        //             and c.cur_codigo = eo.eso_actividad 
        //             and mc.maa_codigo in(1,2) 
        //             and m.cal_codigo = {$CalCodigo} --Tenia el codigo del calendario quemado por defecto 120, dudo que mostrara si a un estudiante se le cruza el horario.
        //             and ( mac_subgrupo = eso_subgrupo or eso_subgrupo = '00' ) 
        //             and mc.cur_codigo = {$CurCodigo}
        //     ) 
        //     group by hra_codigo
        //     order by hra_codigo
        // ";

        // if (!$this->cnx->consultar($sql)) {
        //     $this->errorConsultarBd["consola"] = "Error al consultar los cruces de horas de los estudiantes.";
        //     return $this->errorConsultarBd;
        // }
        // $r_horas_cruzadas = $this->cnx->json; //Almacenamos la respuesta

        // $horas_cruzadas = array();
        // foreach ($r_horas_cruzadas as $horas) { //Recorremos las horas donde el docente esta ocupado
        //     array_push($horas_cruzadas, $horas["HraCodigo"]); //Almacenamos en el array final de las horas docente
        // }

        // $horas_cruzadas = implode(",", $horas_cruzadas); //Almacenamos todas las horas y las separamos por ,
        // $sql_horas_cruzadas = "";
        // if (count($r_horas_cruzadas) > 0) { //Verificamos si encontro alguna hora cruzada
        //     $mensaje_horas_cruzadas = ", las horas {$horas_cruzadas} se cruzan con el horario de un estudiante."; //Almacenamos las horas en un mensaje para mostrar al final
        //     $sql_horas_cruzadas = "and hora.hra_codigo not in ({$horas_cruzadas})";
        // }

        //Validamos si el espacio seleccionado es virtual
        if ($EspTipo == 'V') {
            //Consultamos las horas disponibles excepto las horas que presenten cruce de horario con estudiantes.
            $sql = "SELECT 
                hora.hra_codigo HraCodigo, 
                hora.hra_nombre HraNombre, 
                hora.hra_inicio HraInicio, 
                hora.hra_fin HraFin
            FROM hora 
            WHERE 
                (
                    hora.hra_codigo NOT IN ( 
                        SELECT 
                            hra_codigo 
                        FROM 
                            espacio_ocupacion 
                        WHERE  
                            eso_fecha BETWEEN {$FechaInicioSql} AND {$FechaFinFinDiaSql}
                            and dia_codigo = {$DiaCodigo} 
                            and uap_codigo = {$UapCodigo}  
                        GROUP BY hra_codigo
                    ) 
                    --Aqui va sql de horas cruzadas sql_horas_cruzadas
                ) 
            order by hra_codigo ASC";
            // {$sql_horas_cruzadas}

            // $consulta = "SELECT 
            //     hra_codigo, 
            //     hra_nombre, 
            //     hra_inicio, 
            //     hra_fin 
            // from hora 
            // where 
            //     (
            //         hora.hra_codigo not in( 
            //             select hra_codigo 
            //             from espacio_ocupacion 
            //             where 
            //                 eso_fecha between '" . $fecha1 . "' and '" . $fecha2 . "' 
            //                 and dia_codigo=" . $_REQUEST['dia'] . " 
            //                 and uap_codigo=" . $_REQUEST['docente'] . " 
            //             group by hra_codigo
            //         ) 
            //         and hora.hra_codigo not in (" . $horasest . ")) order by hra_codigo";

            if (!$this->cnx->consultar($sql)) {
                $this->errorConsultarBd["consola"] = "Error al consultar las horas del aula virtual.";
                return $this->errorConsultarBd;
            }

            return array(
                "resultado" => true,
                "mensaje" => "Horas disponibles consultadas correctamente{$mensaje_horas_cruzadas}",
                "data" => $this->cnx->json
            );
        }

        //Validamos si el espacio seleccionado es fisico
        if ($EspTipo == 'F') {
            $sql_horas_ocupadas = "";

            //Consultamos las horas que pueda tener ocupadas el docente en ese dia y entre las fechas.
            $sql = "SELECT 
                hra_codigo HraCodigo
            FROM 
                espacio_ocupacion 
            WHERE 
                eso_fecha BETWEEN {$FechaInicioSql} AND {$FechaFinFinDiaSql}
                and dia_codigo = {$DiaCodigo}  
                and uap_codigo = {$UapCodigo}
            GROUP BY hra_codigo
            ORDER BY hra_codigo ASC
            ";

            if (!$this->cnx->consultar($sql)) {
                $this->errorConsultarBd["consola"] = "Error al consultar las horas ocupadas del docente {$UapCodigo}, dia: {$DiaCodigo} entre '{$FechaInicio}' y '{$FechaFin}'.";
                return $this->errorConsultarBd;
            }

            $r_horas_docente = $this->cnx->json;

            //Consultamos las horas en las que ese espacio se encuentra ocupado
            $sql = "SELECT 
                hra_codigo HraCodigo
            FROM 
                espacio_ocupacion 
            WHERE 
                eso_fecha BETWEEN {$FechaInicioSql} AND {$FechaFinFinDiaSql}
                and dia_codigo = {$DiaCodigo}  
                and esp_codigo = {$EspCodigo}
                and eso_actividad is not null
            GROUP BY hra_codigo
            ORDER BY hra_codigo ASC
            ";

            if (!$this->cnx->consultar($sql)) {
                $this->errorConsultarBd["consola"] = "Error al consultar las horas ocupadas del espacio {$EspCodigo}, dia: {$DiaCodigo} entre '{$FechaInicio}' y '{$FechaFin}'.";
                return $this->errorConsultarBd;
            }

            $r_horas_espacio = $this->cnx->json;

            $horas_ocupadas = array(); //Contendra las horas ocupadas por el docente y por el espacio

            //Validamos si encontro horas donde el docente esta ocupado
            if (count($r_horas_docente) > 0) {
                foreach ($r_horas_docente as $horas) { //Recorremos las horas donde el docente esta ocupado
                    array_push($horas_ocupadas, $horas["HraCodigo"]); //Almacenamos en el array final de las horas docente
                }
            }

            //Validamos si encontro horas donde el espacio esta ocupado
            if (count($r_horas_espacio) > 0) {
                // $horas_ = array();
                foreach ($r_horas_espacio as $horas) { //Recorremos las horas donde el docente esta ocupado
                    array_push($horas_ocupadas, $horas["HraCodigo"]); //Almacenamos en el array final de las horas docente
                }
            }

            $implode_horas_ocupadas = implode(",", $horas_ocupadas); //Almacenamos todas las horas y las separamos por ,
            if ($implode_horas_ocupadas != '') {
                $sql_horas_ocupadas = "and eso.hra_codigo not in ({$implode_horas_ocupadas})";
            } else {
                $sql_horas_ocupadas = "";
            }

            //----------------------------------------------------------------
            //Existe un problema en el que si una unidad tiene el espacio asignado
            //doble, uno se ocupa y el otro queda vacio en la misma hora, dia y fecha.
            //se trata de corregir ademas de validar la ocupacion del docente, tambien
            //tambien averiguar si el espacio esta ocupado.
            //
            //En la parte superior se implementara un proceso para incluir en las horas
            //que no busca tambien las del espacio ocupado
            //----------------------------------------------------------------

            //Se buscan las horas disponibles donde el docente no este ocupado.
            $sql = "SELECT DISTINCT 
                hora.hra_codigo HraCodigo, 
                hora.hra_nombre HraNombre, 
                hora.hra_inicio HraInicio, 
                hora.hra_fin HraFin
            FROM 
                hora
            INNER JOIN espacio_ocupacion eso on hora.hra_codigo = eso.hra_codigo
			WHERE 
                eso.uaa_codigo IN ({$unidades}, 315) 
                and eso.esp_codigo = {$EspCodigo} 
                and eso.dia_codigo = {$DiaCodigo}
			    and eso.eso_actividad is NULL
			    and eso.eso_fecha BETWEEN {$FechaInicioSql} AND {$FechaFinFinDiaSql}
                {$sql_horas_ocupadas}
            
            ORDER BY hora.hra_codigo ASC
            ";
            // {$sql_horas_cruzadas}

            if (!$this->cnx->consultar($sql)) {
                $this->errorConsultarBd["consola"] = "Error al consultar las horas del aula fisica.";
                $this->errorConsultarBd["sql"] = $sql;
                return $this->errorConsultarBd;
            }

            if (count($this->cnx->json) > 0) {
                return array(
                    "resultado" => true,
                    "mensaje" => "Horas disponibles consultadas correctamente{$mensaje_horas_cruzadas}",
                    "data" => $this->cnx->json
                );
            } else {
                return array(
                    "resultado" => true,
                    "mensaje" => "Horas disponibles consultadas correctamente <b>pero no se encontraron horas disponibles</b>.",
                    "data" => $this->cnx->json
                );
            }
        }

        return array(
            "resultado" => false,
            "mensaje" => "Error al consultar las horas disponibles, no se definio si el espacio es virtual o fisico."
        );
    }

    //Inicia funcion consultarDia
    //Consulta el dia de la semana al que pertenece la fecha inicial de la programacion del curso especifico.
    function consultarDia($obj)
    {
        //Validaciones
        if (!isset($obj->FechaInicio)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio la fecha inicial.",
                "consola" => "La fecha inicial del curso no se envio correctamente.",
            );
        }
        //Parametros
        $FechaInicio = $obj->FechaInicio; //Contiene la fecha inicial del curso

        $DiaSemana = date("w", strtotime($FechaInicio)); //windows
        if ($DiaSemana == 0) {
            $DiaSemana = 7; //Cuando se selecciona domingo date da que el domingo es 0, pero en la base de datos domingo es 7.
        }

        $sql = "SELECT dia_codigo DiaCodigo, dia_nombre DiaNombre 
            FROM dia 
            WHERE 
                dia.dia_codigo = {$DiaSemana}  
            ORDER BY 
                dia_codigo";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar los dias disponibles.";
            return $this->errorConsultarBd;
        }

        return array(
            "resultado" => true,
            "mensaje" => "Dias disponibles consultados correctamente.",
            "data" => $this->cnx->json
        );
    }

    //Inicia funcion validarHorarioCrear
    //Permite validar la cantidad de horas que tiene un docente asignadas y si le es permitido asignarle mas horas.
    function validarHorarioCrear($obj)
    {
        //Validaciones
        if (!isset($obj->UapCodigo) || !is_numeric($obj->UapCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo de vinculación del docente.",
                "consola" => "El codigo de vinculación del docente no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->UaaCodigo) || !is_numeric($obj->UaaCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo de unidad seleccionada.",
                "consola" => "El codigo de la unidad no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->FechaInicio)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio la fecha inicial.",
                "consola" => "La fecha inicial del curso no se envio correctamente.",
            );
        }
        if (!isset($obj->FechaFin)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio la fecha final.",
                "consola" => "La fecha final del curso no se envio correctamente.",
            );
        }
        if (!isset($obj->CurCodigo) || !is_numeric($obj->CurCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo del curso seleccionado.",
                "consola" => "El codigo del curso no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->EspCodigo) || !is_numeric($obj->EspCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo del espacio.",
                "consola" => "El codigo del espacio no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->DiaCodigo) || !is_numeric($obj->DiaCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo del dia.",
                "consola" => "El codigo del dia no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->EspTipo) || $obj->EspTipo == '') {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el tipo de espacio.",
                "consola" => "El tipo de espacio está vacio o no se envio correctamente.",
            );
        }
        if (!isset($obj->CalCodigo) || !is_numeric($obj->CalCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo del calendario.",
                "consola" => "El codigo del calendario no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->DedCodigo) || !is_numeric($obj->DedCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo de la dedicación.",
                "consola" => "El codigo de la dedicación no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->VinCodigo) || !is_numeric($obj->VinCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo de la vinculación.",
                "consola" => "El codigo de la vinculación no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->SubGrupo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el subgrupo del curso.",
                "consola" => "El subgrupo no se envio correctamente.",
            );
        }
        if (isset($obj->SubGrupo) && $obj->SubGrupo != "00") {
            if (!isset($obj->CupoSubgrupo) || !is_numeric($obj->CupoSubgrupo)) {
                return array(
                    "resultado" => false,
                    "mensaje" => "No se envio el cupo del subgrupo {$obj->SubGrupo}.",
                    "consola" => "El codigo de la vinculación no es numérico o no se envio correctamente."
                );
            }
        }

        if ($obj->SubGrupo == "00") {
            $obj->CupoSubgrupo = ''; //Si el subgrupo es 00 se establece el cupo subgrupo en vacio
        }

        if (!isset($obj->HorasSeleccionadas) && count($obj->HorasSeleccionadas) <= 0) {
            return array(
                "resultado" => false,
                "mensaje" => "No se enviaron las horas a programar.",
                "consola" => "No se enviaron las horas horas seleccionadas para programar, arreglo vacio."
            );
        }
        if (!isset($obj->PerCodigo) || !is_numeric($obj->PerCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo del periodo.",
                "consola" => "El codigo del periodo no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->UapPerCodigo) || !is_numeric($obj->UapPerCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo de la persona.",
                "consola" => "El codigo de la persona no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->CarCodigo) || $obj->CarCodigo == '') {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el caracter de la asignatura.",
                "consola" => "El caracter de la asignatura no se envio correctamente.",
            );
        }
        if (!isset($obj->UapSedCodigo) || !is_numeric($obj->UapSedCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo de la sede del docente.",
                "consola" => "El codigo de la sede del docente no se envio correctamente.",
            );
        }
        if (!isset($obj->CurSemanas) || !is_numeric($obj->CurSemanas)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio número de semanas del curso.",
                "consola" => "El número de semanas del curso no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->AsiCreditos) || !is_numeric($obj->AsiCreditos)) {
            $obj->AsiCreditos = 0;
        }
        if (!isset($obj->AsiCreditosTeoria) || $obj->AsiCreditosTeoria == '') {
            $obj->AsiCreditosTeoria = 0;
        }
        if (!isset($obj->AsiCreditosPractica) || $obj->AsiCreditosPractica == '') {
            $obj->AsiCreditosPractica = 0;
        }

        //Si es presencial (1) y subgrupo 00, no puede ser en un aula virtual
        if ($obj->CalTipo == 'A') {
            if ($obj->SubGrupo == '00' && $obj->TicCodigo == 1 && (trim($obj->CarCodigo) == "T" || trim($obj->CarCodigo) == "TP")) {
                if ($obj->EspTipo == 'V' && $obj->UaaCodigo != 44) {
                    return array(
                        "resultado" => false,
                        "mensaje" => "Los cursos teoricos o teorico practicos creados con modalidad presencial no pueden ser programados en un espacio virtual.",
                        "consola" => "Los cursos teoricos o teorico practicos creados con modalidad presencial no pueden ser programados en un espacio virtual.",
                    );
                }
            }
        }

        if ($obj->CalTipo == 'A') {
            if ($obj->SubGrupo == '00' && $obj->TicCodigo == 2) {
                if ($obj->EspTipo == 'F') {
                    return array(
                        "resultado" => false,
                        "mensaje" => "Los cursos creados con modalidad Apoyo virtual (b-Learning) no pueden ser programados en un espacio físico.",
                        "consola" => "Los cursos creados con modalidad Apoyo virtual (b-Learning) no pueden ser programados en un espacio físico.",
                    );
                }
            }
        }

        // if (!isset($obj->PerNN) || $obj->PerNN = '') {
        //     return array(
        //         "resultado" => false,
        //         "mensaje" => "No se envio el tipo de la persona.",
        //         "consola" => "El tipo de la persona no se envio correctamente.",
        //     );
        // }


        //Asignaciones
        $unidades = $_SESSION["pacademica"]["datosVinculacionUsuario"]["unidades"]; // Contiene las unidades vinculadas al usuario.
        $UapCodigo = $obj->UapCodigo; //Contiene el codigo de vinculacion del docente seleccionado
        $UaaCodigo = $obj->UaaCodigo; //Contiene el codigo de una unidad a la que se le va a programar.
        $FechaInicio = $obj->FechaInicio; //Contiene la fecha yyyy-mm-dd inicio de la programacion del curso seleccionado.
        $FechaFin = $obj->FechaFin; //Contiene la fecha yyyy-mm-dd fin de la programacion del curso seleccionado
        $CurCodigo = $obj->CurCodigo; //Contiene el codigo del curso seleccionado
        $EspCodigo = $obj->EspCodigo; //Contiene el espacio fisico/aula externa seleccionado
        $DiaCodigo = $obj->DiaCodigo; //Contiene el dia que se va a programar.
        $EspTipo = $obj->EspTipo; //Contiene el tipo de espacio que se va a programar V (Virtual) o F (Fisico)
        $CalCodigo = $obj->CalCodigo; //Contiene el codigo del calendario en el que se va a programar
        $DedCodigo = $obj->DedCodigo; //Contiene el codigo de la dedicación del docente.
        $VinCodigo = $obj->VinCodigo; //Contiene el codigo de la vinculación del docente.
        $SubGrupo = $obj->SubGrupo; //Contiene el subgrupo del curso.
        $CupoSubgrupo = $obj->CupoSubgrupo; //Contiene el cupo del subgrupo del curso.
        $HorasSeleccionadas = $obj->HorasSeleccionadas; //Contiene los codigos de las horas seleccionadas.
        $PerCodigo = $obj->PerCodigo; //Contiene el codigo del periodo.
        $UapPerCodigo = $obj->UapPerCodigo; //Contiene el codigo de la persona del docente.
        $CarCodigo = trim($obj->CarCodigo); //Contiene el caracter de la asignatura.
        $AsiCodigo = $obj->AsiCodigo; //Contiene el codigo de la asignatura seleccionada.
        $AsiCreditos = $obj->AsiCreditos; //Contiene los creditos de la asignatura.
        $AsiCreditosTeoria = $obj->AsiCreditosTeoria; //Contiene los creditos teoricos de la asignatura.
        $AsiCreditosPractica = $obj->AsiCreditosPractica; //Contiene los creditos practicos de la asignatura.
        $UapSedCodigo = $obj->UapSedCodigo; //Contiene el codigo de la sede del docente.
        $UaaDependencia = $obj->UaaDependencia; //Contiene el codigo de la dependencia de la unidad seleccionada.
        $CurSemanas = $obj->CurSemanas; //Contiene el numero total de semanas del curso seleccionado.
        $TipoDocente = $obj->TipoDocente; //Contiene si es un docente 'Propio' o 'Prestado'
        $SpdCodigo = (isset($obj->SpdCodigo) && is_numeric($obj->SpdCodigo)) ? intval($obj->SpdCodigo) : null;

        $respuesta = array(); //Se usara para almacenar la respuesta que se obtiene de la funcion guardarHorario();
        $cantidad_horas_nuevas = count($HorasSeleccionadas); //Cantidad de horas nuevas por semana.

        if (!isset($obj->listaHorarioSeleccionado) || !is_array($obj->listaHorarioSeleccionado) || count($obj->listaHorarioSeleccionado) == 0) {
            $listaHorarioSeleccionado = array();
            $fechaProgramacion = date('Y-m-d', strtotime($FechaInicio));
            $iteracionInicial = true;

            for ($i = 1; $i <= $CurSemanas; $i++) {
                if ($iteracionInicial == false) {
                    $fechaProgramacion = date("Y-m-d", strtotime($fechaProgramacion . "+ 1 week"));
                }
                $iteracionInicial = false;

                foreach ($HorasSeleccionadas as $hora) {
                    $item = new stdClass();
                    $item->EsoFecha = $fechaProgramacion;
                    $item->HraCodigo = $hora;
                    $listaHorarioSeleccionado[] = $item;
                }
            }

            $obj->listaHorarioSeleccionado = $listaHorarioSeleccionado;
        }

        $objCruce = new stdClass();
        $objCruce->CurCodigo = $CurCodigo;
        $objCruce->CurSemanas = $CurSemanas;
        $objCruce->CurSubgrupo = $SubGrupo;
        $objCruce->FechaInicio = $FechaInicio;
        $objCruce->FechaFin = $FechaFin;
        $objCruce->HorasSeleccionadas = $HorasSeleccionadas;

        $objCruceHorario = new Crucehorario();
        $validacionCruceEstudiantes = $objCruceHorario->consultarCruceHorario($objCruce);

        if (isset($validacionCruceEstudiantes['resultado']) && $validacionCruceEstudiantes['resultado'] === false) {
            if (isset($validacionCruceEstudiantes['data']) && count($validacionCruceEstudiantes['data']) > 0) {
                $cursosCruce = array();
                $cursosCruceUnicos = array();
                foreach ($validacionCruceEstudiantes['data'] as $cursoCruce) {
                    $clave = $cursoCruce['CurCodigo'] . '|' . $cursoCruce['AsiNombre'];
                    if (!isset($cursosCruceUnicos[$clave])) {
                        $cursosCruceUnicos[$clave] = true;
                        $cursosCruce[] = $cursoCruce['CurCodigo'] . " - " . $cursoCruce['AsiNombre'];
                    }
                }
                return array(
                    "resultado" => false,
                    "mensaje" => "El horario presenta cruce con estudiantes matriculados en los siguientes cursos: " . implode(', ', $cursosCruce) . ".",
                    "consola" => "Cruce de estudiantes detectado para el curso {$CurCodigo}, subgrupo {$SubGrupo}."
                );
            }

            return array(
                "resultado" => false,
                "mensaje" => isset($validacionCruceEstudiantes['mensaje']) ? $validacionCruceEstudiantes['mensaje'] : "No se pudo validar el cruce de horario de estudiantes.",
                "consola" => isset($validacionCruceEstudiantes['consola']) ? $validacionCruceEstudiantes['consola'] : "Error en consultarCruceHorario() para el curso {$CurCodigo}."
            );
        }

        $obj->PerNN = false;

        //Evaluamos si es un NN catedra
        $sql = "SELECT per.per_codigo PerCodigo FROM persona per WHERE per.per_apellido LIKE '%nn ca%' AND per.per_codigo = {$UapPerCodigo}";
        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar si el docente es un NN CATEDRA.";
            return $this->errorConsultarBd;
        }
        $r_docente_nn = $this->cnx->json;
        $perNN = false; //Contiene si (true) el docente es NN catedra o no (false)
        if (count($r_docente_nn) > 0) {
            $perNN = true; //En caso de ser docente NN catedra true.
        }

        $obj->PerNN = $perNN; //Almacenamos al array que enviaremos para programacion si el docente es un NN.

        $servicioCargaDocente = new ValidarCargaDocenteService($this->cnx);

        // DOCENTES PRESTADOS
        // ==================
        // Se consultan todas las solicitudes aprobadas del docente en el periodo. Luego se distingue si
        // la coincidencia corresponde a la unidad/asignatura que esta programando o si pertenece a otra solicitud.
        $condicionSolicitudActual = ($TipoDocente == 'Prestado' && $SpdCodigo !== null)
            ? "spd.spd_codigo = {$SpdCodigo} AND spd.asi_codigo = {$AsiCodigo}"
            : "spd.uaa_solicita = {$UaaCodigo} AND spd.asi_codigo = {$AsiCodigo}";
        $sql = "SELECT DISTINCT
                    spd.spd_codigo SpdCodigo,
                    spd.uaa_solicita UaaSolicita,
                    uaa.uaa_nombre_corto UaaSolicitaNombre,
                    spd.asi_codigo AsiCodigo,
                    asi.asi_nombre_corto AsiNombreCorto,
                    spdh.dia_codigo DiaCodigo,
                    spdh.hra_codigo HraCodigo,
                    dia.dia_nombre DiaNombre,
                    hra.hra_inicio HraInicio,
                    hra.hra_fin HraFin,
                    CASE
                        WHEN {$condicionSolicitudActual} THEN 1
                        ELSE 0
                    END SolicitudActual
                FROM programacionacademica.solicitud_prestamo_docente spd
                    INNER JOIN programacionacademica.solicitud_prestamo_docente_horario spdh ON spd.spd_codigo = spdh.spd_codigo AND spdh.spdh_estado = 1
                    INNER JOIN asignatura asi ON asi.asi_codigo = spd.asi_codigo
                    INNER JOIN uaa ON uaa.uaa_codigo = spd.uaa_solicita
                    INNER JOIN dia ON dia.dia_codigo = spdh.dia_codigo
                    INNER JOIN hora hra ON hra.hra_codigo = spdh.hra_codigo
                WHERE spd.spd_estado = 2
                    AND spd.persona_codigo = {$UapPerCodigo}
                    AND spd.periodo_codigo = {$PerCodigo}
            ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar solicitudes aprobadas de prestamo docente.";
            return $this->errorConsultarBd;
        }
        $r_solicitud_docente = $this->cnx->json;
        $coincidencias = array(
            "resultado" => false,
            "dia" => "",
            "hora_inicio" => "",
            "hora_fin" => "",
            "solicitud" => "",
            "unidad" => "",
            "asignatura" => "",
        );
        $horasPermitidasPrestamo = array(); // Para docentes prestados, debe cubrir cada hora seleccionada.
        // Valida si el docente se encuentra prestado en algun horario que se selecciono.
        if (count($r_solicitud_docente) > 0) { // Verificamos que tenga una solicitud de prestamos aprobada para este semestre.
            foreach ($r_solicitud_docente as $item) { // Recorremos el horario de los solicitudes aprobadas encontradas.
                if ($item['DiaCodigo'] == $DiaCodigo && in_array($item['HraCodigo'], $HorasSeleccionadas)) {
                    if ($item["SolicitudActual"] == 1) {
                        $horasPermitidasPrestamo[$item['HraCodigo']] = true;
                        continue;
                    }
                    if ($TipoDocente == 'Propio') { // Si existe una coincidencia con otra solicitud aprobada, se bloquea.
                        $coincidencias["resultado"] = true;
                        $coincidencias["dia"] = trim($item["DiaNombre"]);
                        $coincidencias["hora_inicio"] = trim($item["HraInicio"]);
                        $coincidencias["hora_fin"] = trim($item["HraFin"]);
                        $coincidencias["solicitud"] = trim($item["SpdCodigo"]);
                        $coincidencias["unidad"] = trim($item["UaaSolicita"] . ". " . $item["UaaSolicitaNombre"]);
                        $coincidencias["asignatura"] = trim($item["AsiCodigo"] . ". " . $item["AsiNombreCorto"]);
                        break;
                    }
                }
            }
        } else {
            // Se verifica que el docente sea prestado y no se encontrara ninguna solicitud.
            if ($TipoDocente == 'Prestado') {
                // Significa que el docente no ha sido aprobado para este periodo, en este horario y para esta asignatura.
                return array(
                    "resultado" => false,
                    "mensaje" => trim("No se han encontrado solicitudes de préstamo docente aprobadas para este programa, para este docente, en este periodo, en este horario y para esta asignatura."),
                    "consola" => "No se han encontrado solicitudes de préstamo docente aprobadas para este programa, para este docente, en este periodo, en este horario y para esta asignatura.",
                );
            }
        }

        if ($TipoDocente == 'Propio' && count($horasPermitidasPrestamo) > 0 && count($horasPermitidasPrestamo) != count($HorasSeleccionadas)) {
            return array(
                "resultado" => false,
                "mensaje" => trim("El docente tiene una solicitud de préstamo aprobada para este programa y asignatura, pero no todas las horas seleccionadas están permitidas en la solicitud."),
                "consola" => "Horas seleccionadas: " . implode(",", $HorasSeleccionadas) . ". Horas permitidas encontradas para la solicitud actual: " . implode(",", array_keys($horasPermitidasPrestamo)) . "."
            );
        }

        // En caso de que el docente sea propio y se encuentren coincidencias entre lo prestado y lo permitido
        if ($TipoDocente == 'Propio' && $coincidencias["resultado"]) { // Verificamos si existe coincidencias (true)
            $mensajeCoincidenciaPrestamo = "El docente se encuentra prestado en un horario seleccionado ({$coincidencias["dia"]} - {$coincidencias["hora_inicio"]} a {$coincidencias["hora_fin"]}) para la solicitud {$coincidencias["solicitud"]}, unidad {$coincidencias["unidad"]}, asignatura {$coincidencias["asignatura"]}.";
            return array(
                "resultado" => false,
                "mensaje" => trim($mensajeCoincidenciaPrestamo),
                "consola" => "El docente tiene una solicitud aprobada de préstamo docente en el horario seleccionado ({$coincidencias["dia"]} - {$coincidencias["hora_inicio"]} a {$coincidencias["hora_fin"]})."
            );
        }

        // En caso de que el docente sea prestado y el numero de horas programadas no coincidan con el numero de coincidencias encontradas en el horario permitido
        if ($TipoDocente == 'Prestado' && count($horasPermitidasPrestamo) != count($HorasSeleccionadas)) {
            return array(
                "resultado" => false,
                "mensaje" => trim("Las horas seleccionadas no coinciden con las horas permitidas en la solicitud de préstamo docente."),
                "consola" => "Las horas seleccionadas no coinciden con las horas permitidas en la solicitud de préstamo docente."
            );
        }

        if (trim($VinCodigo) != 12) { //Diferente a docente de planta
            //Machetazo agregado por douglas el 2022-07-11 por los posgrados de salud en el calendario 218.	20222C
            //Aun cuando van a programar el 2022-2 le debe mostrar las vinculaciones del 2022-1 para las siguientes uaa
            // 75.NEIVA - ESPECIALIZACION EN PEDIATRIA
            // 84.NEIVA - ESPECIALIZACION GINECOLOGIA Y OBSTETRICIA
            // 85.NEIVA - ESPECIALIZACION EN MEDICINA INTERNA
            // 86.NEIVA - ESPECIALIZACION EN CIRUGIA GENERAL
            // 87.NEIVA - ESPECIALIZACION EN ANESTESIOLOGIA Y REANIMACION
            // 677.NEIVA - ESPECIALIZACION EN MEDICINA CRITICA Y CUIDADO INTENSIVO
            // 685.ESPECIALIZACION EN GINECOLOGIA Y OBSTETRICIA

            //Machetazo agregado por douglas el 2022-11-22 por los posgrados de salud en el calendario 220. 20231C
            // 220	124	20231C	NULL	NULL	NULL	2022	1
            if (($CalCodigo == 218 || $CalCodigo == 220) && ($UaaCodigo == 75 || $UaaCodigo == 84 || $UaaCodigo == 85 || $UaaCodigo == 86 || $UaaCodigo == 87 || $UaaCodigo == 677 || $UaaCodigo == 685)) {
                //No hace nada por que se desea que no evalue el cruce de agendas por que siempre lo va a tener.
            } else {
                $sql = "SELECT 
                (SELECT TOP 1 per_codigo FROM calendario WHERE cal_codigo= {$CalCodigo} ) as periodo_seleccionado,
                cur.cur_codigo CurCodigo, 
                cal.per_codigo PerCodigo
                FROM uaa_personal uap
                INNER JOIN agenda_periodo agp ON uap.uap_codigo = agp.uap_codigo
                INNER JOIN curso cur ON cur.cur_codigo = agp.cur_codigo
                INNER JOIN calendario cal ON cal.cal_codigo = cur.cal_codigo
                WHERE 
                    uap.uap_codigo = {$UapCodigo} 
                ";

                if (!$this->cnx->consultar($sql)) {
                    $this->errorConsultarBd["consola"] = "Error al validar la carga academica entre periodos de la vinculación: {$UapCodigo}.";
                    return $this->errorConsultarBd;
                }

                $r_cruce_calendario = $this->cnx->json;
                $tieneCursosDeOtroPeriodo = false;

                for ($i = 0; $i < count($r_cruce_calendario); $i++) {
                    $periodo_curso = $r_cruce_calendario[$i]["PerCodigo"];
                    $periodo_seleccionado = $r_cruce_calendario[$i]["periodo_seleccionado"];

                    if ($periodo_seleccionado != $periodo_curso) {
                        $tieneCursosDeOtroPeriodo = true;
                    }
                }

                if ($tieneCursosDeOtroPeriodo) {
                    $this->errorSentenciaBd["mensaje"] = "La vinculación ({$UapCodigo}) del docente ya tiene cargado cursos de otro periodo. Asegurese que el docente tenga vinculación para el periodo seleccionado.";
                    $this->errorSentenciaBd["consola"] = "Error la vinculacion ({$UapCodigo}) tiene cursos en otro periodo.";
                    return $this->errorSentenciaBd;
                }
            }
        }

        $control_tope_horas = 0; //Se usa para controlar el tope permitido de horas.
        $total_horas = 0; //total de horas docente consultadas desde espacio_ocupacion.
        $total_horas_pp = 0; //total de horas practica pedagogica docente consultadas desde agenda_periodo.
        $total_horas_pp_sem = 0; //total de horas semanales practica pedagogica docente consultadas desde agenda_periodo.
        $total_horas_inv_tesis = 0; //total de horas proyecto de investigacion o direccion de tesis
        $total_horas_descarga = 0; //total de horas descarga academica
        $cantidad_horas_nuevas_total = 0; //total de horas nuevas, se usa para calcular.
        $total_horas_novedad = 0; //total de horas de novedad se usa solo para de planta  o nombramiento ocacional
        $total_horas_factor = 0; //total de horas de agenda periodo se usa solo para de planta  o nombramiento ocacional

        //Se consulta el total de horas que tiene un docente catedratico
        $sql = "SELECT 
                COUNT(*) as totalhora  
            FROM 
                espacio_ocupacion eso 
            INNER JOIN curso cur ON cur.cur_codigo = eso.eso_actividad  
            INNER JOIN asignatura asi ON cur.asi_codigo = asi.asi_codigo AND asi.car_codigo != 'PP' 
            WHERE 
                eso.uap_codigo = {$UapCodigo} 
            ";
        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar el total de horas para un catedratico.";
            return $this->errorConsultarBd;
        }
        $r_total_horas = $this->cnx->json; //Almacenamos el total de horas del catedratico.
        foreach ($r_total_horas as $fe_horas) {
            $control_tope_horas = 224; //Se establece el tope de horas
            $total_horas = $fe_horas['totalhora']; //Se almacena la cantidad total de horas del catedratico actualmente.
        }

        $r_total_horas_servicio = $servicioCargaDocente->obtenerTotalHorasCatedraSinPractica($UapCodigo);
        if (!$r_total_horas_servicio["resultado"]) {
            return $r_total_horas_servicio;
        }
        $total_horas = $r_total_horas_servicio["data"]["totalHoras"];

        //Se consulta el total de horas practica pedagogica que tiene un docente catedratico
        $sql = "SELECT 
                SUM(agp.numero_total_hora/agp.semanas) as hrsemanal,
                SUM(factor) as totalpp 
            FROM 
                agenda_periodo agp 
            WHERE 
                agp.uap_codigo = {$UapCodigo} 
                and agp.caracter = 'PP'
            ";
        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar el total de horas practica pedagogica para un catedratico.";
            return $this->errorConsultarBd;
        }
        $r_total_horas_practica = $this->cnx->json; //Almacenamos el total de horas practica pedagogica del catedratico.
        foreach ($r_total_horas_practica as $fe_horas) {
            $control_tope_horas = 252; //Se establece el tope de horas
            $total_horas_pp = $fe_horas['totalpp']; //Se almacena la cantidad total de horas practica pedagogica del catedratico actualmente.
            $total_horas_pp_sem = $fe_horas['hrsemanal']; //Se almacena la cantidad de horas semanal practica pedagogica del catedratico actualmente.
        }

        $r_total_horas_practica_servicio = $servicioCargaDocente->obtenerHorasPracticaPedagogica($UapCodigo);
        if (!$r_total_horas_practica_servicio["resultado"]) {
            return $r_total_horas_practica_servicio;
        }
        $total_horas_pp = $r_total_horas_practica_servicio["data"]["totalPP"];
        $total_horas_pp_sem = $r_total_horas_practica_servicio["data"]["horasSemanal"];

        // 14	CATEDRA DOCENTE
        // 24	CATEDRA VISITANTE DOCENTE
        // 49	CATEDRA CONVENIO DOCENTE
        if (($VinCodigo == 14 or $VinCodigo == 24 or $VinCodigo == 49) &&  $DedCodigo == 6) {
            //VERIFICAR MAXIMO DE CARGAR POR SEDE CATEDRATICO
            $sql = "SELECT 
            sum(agp.numero_total_hora/agp.semanas) as hrsemanal 
            FROM 
                agenda_periodo agp
            WHERE 
                agp.uap_codigo = {$UapCodigo}
                and agp.vinculacion = {$VinCodigo}
            ";
            if (!$this->cnx->consultar($sql)) {
                $this->errorConsultarBd["consola"] = "Error al consultar la agenda del catedratico de sedes.";
                return $this->errorConsultarBd;
            }
            $r_agenda_catedratico = $this->cnx->json; //Almacena el resumen de la agenda del docente para un curso y vinculacion especifica.

            $horas_semanal_catedratico_sede = 0; //Almacenamos por defecto 0 horas a la semana.
            $horas_semanal_catedratico = 0; //Almacenamos por defecto 0 horas a la semana.
            $max_horas_catedratico_sedes = 0; //Almacenamos por defecto 0 horas del total de horas permitidas en sede.
            $max_horas_catedratico = 0; //Almacenamos por defecto 0 horas del total de horas permitidas en Neiva.

            if ($UapSedCodigo != 1) { //Si es diferente de neiva
                $horas_semanal_catedratico_sede = $r_agenda_catedratico[0]['hrsemanal']; //Almacenamos el total de horas que tiene el docente en esta semana de sede.
                //Web parametro 210
                //CONTROLA EL MAXIMO DE HORAS PERMITIDA PARA UN CATEDRATICO DE LAS SEDES - PROGRAMACION ACADEMICA
                $sql = "SELECT wep.wep_valor WepValor FROM web_parametro wep WHERE wep.wep_codigo = 210 ";
                if (!$this->cnx->consultar($sql)) {
                    $this->errorConsultarBd["consola"] = "Error al consultar el maximo de horas permitidas para un catedratico de las sedes.";
                    return $this->errorConsultarBd;
                }
                $r_max_horas_cate_sedes = $this->cnx->json;
                $max_horas_catedratico_sedes = $r_max_horas_cate_sedes[0]["WepValor"]; //Contiene el numero maximo de horas permitidas para un catedratico en sedes.

            } else {
                $horas_semanal_catedratico = $r_agenda_catedratico[0]['hrsemanal']; //Almacenamos el total de horas que tiene el docente en esta semana de sede.
                $sql = "SELECT wep.wep_valor WepValor FROM web_parametro wep WHERE wep.wep_codigo = 485 ";
                if (!$this->cnx->consultar($sql)) {
                    $this->errorConsultarBd["consola"] = "Error al consultar el maximo de horas permitidas para un catedratico en neiva.";
                    return $this->errorConsultarBd;
                }
                $r_max_horas_cate_neiva = $this->cnx->json;
                $max_horas_catedratico = $r_max_horas_cate_neiva[0]["WepValor"]; //Contiene el numero maximo de horas permitidas para un catedratico en neiva.
            }

            $r_agenda_catedratico_servicio = $servicioCargaDocente->obtenerHorasSemanalesAgendaPorVinculacion($UapCodigo, $VinCodigo);
            if (!$r_agenda_catedratico_servicio["resultado"]) {
                return $r_agenda_catedratico_servicio;
            }
            $horas_semanal_catedratico_sede = $UapSedCodigo != 1 ? $r_agenda_catedratico_servicio["data"]["horasSemanal"] : 0;
            $horas_semanal_catedratico = $UapSedCodigo == 1 ? $r_agenda_catedratico_servicio["data"]["horasSemanal"] : 0;

            $r_topes_catedra = $servicioCargaDocente->obtenerTopesSemanalesCatedra($UapSedCodigo);
            if (!$r_topes_catedra["resultado"]) {
                return $r_topes_catedra;
            }
            $max_horas_catedratico_sedes = $r_topes_catedra["data"]["topeSedes"];
            $max_horas_catedratico = $r_topes_catedra["data"]["topeNeiva"];

            $r_periodo_nombre = $servicioCargaDocente->obtenerPeriodoNombrePorCodigo($PerCodigo);
            if (!$r_periodo_nombre["resultado"]) {
                return $r_periodo_nombre;
            }
            $periodoNombre = $r_periodo_nombre["data"]["periodoNombre"];

            $r_pico_total = $servicioCargaDocente->calcularPicoTotalSemanal($UapCodigo, $periodoNombre, $UaaDependencia, $obj->listaHorarioSeleccionado);
            if (!$r_pico_total["resultado"]) {
                return $r_pico_total;
            }
            $pico_total_actual = $r_pico_total["data"]["PicoTotalActual"];
            $pico_total = $r_pico_total["data"]["PicoTotal"];

            //Se consulta el total de horas de proyecto de investigacion o direccion de tesis que tiene el docente para el periodo actual
            $sql = "SELECT 
                sum(pep_hora_semana*pep_semanas) as total 
            FROM 
                proyecto pro
            INNER JOIN proyecto_tipo prt ON prt.prt_codigo = pro.prt_codigo 
            INNER JOIN persona_proyecto pep ON pro.pry_codigo = pep.pry_codigo 
            INNER JOIN periodo per ON per.per_codigo = pep.per_codigo 
            WHERE 
                pep.pep_persona = {$UapPerCodigo} 
                and per.per_codigo = {$PerCodigo}
            ";
            if (!$this->cnx->consultar($sql)) {
                $this->errorConsultarBd["consola"] = "Error al consultar el total de horas proyecto de investigación y direccion de tesis para un catedratico.";
                return $this->errorConsultarBd;
            }

            $r_total_horas_inv_tesis = $this->cnx->json; //Almacenamos el total de horas proyectos de investigacion y direccion de tesis del catedratico.
            foreach ($r_total_horas_inv_tesis as $fe_horas) {
                $control_tope_horas = 252; //Se establece el tope de horas
                $total_horas_inv_tesis = $fe_horas['total']; //Se almacena la cantidad total de horas proyecto de investigacion y direccion de tesis del catedratico actualmente.
            }

            $cargaComplementariaSemanal = $servicioCargaDocente->obtenerCargaComplementariaSemanal($UapPerCodigo, $PerCodigo, true);
            if (!$cargaComplementariaSemanal["resultado"]) {
                return $cargaComplementariaSemanal;
            }
            $total_horas_inv_tesis = $cargaComplementariaSemanal["data"]["proyectosSemanal"];

            //Comparamos si cuenta con horas de practica pedagogica, proyectos de investigacion o direccion de tesis.
            if ($total_horas_inv_tesis > 0 || $total_horas_pp > 0) {
                $control_tope_horas = 288;
            } else {
                $control_tope_horas = 252;
            }

            //Validacion si la dependencia de la unidad es la facultad de salud con codigo 23
            if ($UaaDependencia == 23) {
                $control_tope_horas = 288;
            }

            $cantidad_horas_nuevas_total = $cantidad_horas_nuevas * $CurSemanas; //Se calcula el total de horas nuevas en la semana por el total de semanas del curso.
            $total_horas_descarga = $total_horas_descarga + $cantidad_horas_nuevas + $total_horas_inv_tesis + $horas_semanal_catedratico_sede + $horas_semanal_catedratico; //Se suman todas las horas para sacar el total de descarga
            $total_horas_descarga = $pico_total;
            $topeSemanalCatedra = $UapSedCodigo != 1 ? floatval($max_horas_catedratico_sedes) : floatval($max_horas_catedratico);

            if ($perNN == false && $pico_total_actual >= $topeSemanalCatedra && $pico_total > $pico_total_actual) {
                return array(
                    "resultado" => false,
                    "consola" => "El docente con vinculacion {$UapCodigo} ya se encuentra en el tope semanal de horas de catedra para su sede ({$topeSemanalCatedra} horas). La nueva carga incrementaria su pico semanal real de {$pico_total_actual} a {$pico_total}.",
                    "mensaje" => "No se pueden adicionar horas: el docente ya se encuentra en el tope semanal ({$topeSemanalCatedra}), la nueva carga supera su maximo ({$pico_total_actual} -> {$pico_total}).",
                    "line" => __LINE__
                );
            }

            //Se verifica que el total de horas de descarga no super el tome establecido
            // if ($control_tope_horas >= $total_horas_descarga) {
            //     // Se procede a realizar la programacion
            //     $respuesta = $this->guardarHorario($obj);
            // } else {
            // }
            if ($perNN == true) { //En caso de pasar el tope se pregunta si es un docente NN
                //Se procede a realizar la programacion y se avisa que es un docente NN.
                $respuesta = $this->guardarHorario($obj);
            } else {
                //En caso de superar las horas de descarga al tope
                if ($UapSedCodigo != 1) { //Validamos si es de sede diferente a neiva
                    // $cantidad_horas_nuevas_total = $cantidad_horas_nuevas + $horas_semanal_catedratico_sede; //Se calcula el total de horas nuevas en la semana por el total de semanas del curso.
                    if ($total_horas_descarga > $max_horas_catedratico_sedes) { //En caso de que el total de horas de descarga sea mayor que el maximo permitido para catedraticos en sede
                        return array(
                            "resultado" => false,
                            "mensaje" => "ERROR. No se pueden adicionar las horas porque supera el límite de horas semanales, límite horas semanal en sedes: {$max_horas_catedratico_sedes}, horas que tendría el docente: {$total_horas_descarga}"
                        );
                    } else {
                        //Se procede a realizar la programacion.
                        $respuesta = $this->guardarHorario($obj);
                    }
                } else {
                    // $cantidad_horas_nuevas_total = $cantidad_horas_nuevas + $horas_semanal_catedratico; //Se calcula el total de horas nuevas en la semana por el total de semanas del curso.
                    if ($total_horas_descarga > $max_horas_catedratico) { //En caso de que el total de horas de descarga sea mayor que el maximo permitido para catedraticos en neiva que son 16, esto esta en el acuerdo 048 de 2018 usco
                        return array(
                            "resultado" => false,
                            "mensaje" => "ERROR. No se pueden adicionar las horas porque supera el límite de horas semanales, límite horas semanal en Neiva: {$max_horas_catedratico}, horas que tendría el docente: {$total_horas_descarga}"
                        );
                    } else {
                        //Se procede a realizar la programacion.
                        $respuesta = $this->guardarHorario($obj);
                    }
                }
            }
        }

        // 25	CATEDRA ADICIONAL DOCENTE
        // 17	CATEDRA POSTGRADOS  DOCENTE
        // 16	AD HONOREM                    
        if ($VinCodigo == 25 or $VinCodigo == 17 or $VinCodigo == 16) {
            $control_tope_horas = 224;
            $cantidad_horas_nuevas_total = $cantidad_horas_nuevas * $CurSemanas; //Cantidad de horas nuevas a la semana * la cantidad de semanas.
            $total_horas_descarga = $total_horas_descarga + $cantidad_horas_nuevas_total + $total_horas + $total_horas_pp;

            if ($control_tope_horas >= $total_horas_descarga) {
                // Se procede a realizar la programacion
                $respuesta = $this->guardarHorario($obj);
            } else {
                if ($perNN == true) { //En caso de pasar el tope se pregunta si es un docente NN
                    //Se procede a realizar la programacion y se avisa que es un docente NN.
                    $respuesta = $this->guardarHorario($obj);
                } else {
                    //En caso de superar las horas de descarga al tope
                    return array(
                        "resultado" => false,
                        "mensaje" => "ERROR. No se pueden adicionar las horas porque supera el límite de horas semanales (14 horas semanales), límite horas: {$control_tope_horas}, total horas que tendría el docente: {$total_horas_descarga}"
                    );
                }
            }
        }

        // 12	DE PLANTA DOCENTE
        // 23	NOMBRAMIENTO OCASIONAL DOCENTE
        //  5	TIEMPO COMPLETO
        //  4	MEDIO TIEMPO
        if ($VinCodigo == 12 or $VinCodigo == 23 or (($VinCodigo == 14 or $VinCodigo == 24 or $VinCodigo == 49) && ($DedCodigo == 4 or $DedCodigo == 5))) {
            //Consulta las horas de investigacion y direccion de tesis
            $sql = "SELECT 
                sum(pep_hora_semana*pep_semanas) as total 
            FROM 
                proyecto pro
            INNER JOIN proyecto_tipo prt ON prt.prt_codigo = pro.prt_codigo 
            INNER JOIN persona_proyecto pep ON pro.pry_codigo = pep.pry_codigo 
            INNER JOIN periodo per ON per.per_codigo = pep.per_codigo 
			WHERE 
                pep.pep_persona = {$UapPerCodigo} 
                and per.per_codigo = {$PerCodigo}
            ";
            if (!$this->cnx->consultar($sql)) {
                $this->errorConsultarBd["consola"] = "Error al consultar el total de horas proyecto de investigación y direccion de tesis para un catedratico.";
                return $this->errorConsultarBd;
            }
            $r_total_horas_inv_tesis = $this->cnx->json; //Almacenamos el total de horas proyectos de investigacion y direccion de tesis del catedratico.
            foreach ($r_total_horas_inv_tesis as $fe_horas) {
                $total_horas_inv_tesis = $fe_horas['total']; //Se almacena la cantidad total de horas proyecto de investigacion y direccion de tesis del catedratico actualmente.
            }

            //Consulta las horas de novedades docentes
            $sql = "SELECT 
                SUM(pen_descarga_semestral) as total
            FROM 
                persona_novedad pen
            INNER JOIN novedad nov ON pen.nov_codigo = nov.nov_codigo 
            INNER JOIN periodo per ON per.per_codigo = pen.per_codigo 
            WHERE 
                pen.pen_persona = {$UapPerCodigo} 
                AND per.per_codigo = {$PerCodigo}
                AND pen.pen_estado = 1
            ";

            if (!$this->cnx->consultar($sql)) {
                $this->errorConsultarBd["consola"] = "Error al consultar el total de novedades para un catedratico.";
                return $this->errorConsultarBd;
            }
            $r_total_horas_novedad = $this->cnx->json; //Almacenamos el total de horas proyectos de investigacion y direccion de tesis del catedratico.
            foreach ($r_total_horas_novedad as $fe_horas) {
                $total_horas_novedad = $fe_horas['total']; //Se almacena la cantidad total de horas de novedades del catedratico actualmente.
            }

            //Para consultar el total de horas que tiene el docente, primero eliminamos de agenda docente el calculo de horas para este curso dado que se debe recalcular, una vez se inserten nuevamente.
            $sql = "DELETE FROM agenda_periodo WHERE uap_codigo = {$UapCodigo} and cur_codigo = {$CurCodigo}";
            if (!$this->cnx->sentencia($sql)) {
                $this->errorSentenciaBd["mensaje"] = "Error al eliminar la agenda del curso: {$CurCodigo} y vinculacion docente: {$UapCodigo}.";
                $this->errorSentenciaBd["consola"] = "Ha fallado el delete de la agenda del curso: {$CurCodigo} y vinculacion docente: {$UapCodigo}.";
                return $this->errorSentenciaBd;
            }

            $sql = "SELECT 
                SUM(ag.factor) as total 
            FROM 
                curso cur 
            INNER JOIN agenda_periodo ag ON cur.cur_codigo = ag.cur_codigo and ag.vinculacion in (12) and ag.per_codigo = {$UapPerCodigo}
            INNER JOIN calendario cal ON cal.cal_codigo = cur.cal_codigo and cal.cal_codigo = {$CalCodigo}
            INNER JOIN periodo per ON cal.per_codigo = per.per_codigo
            ";

            if (!$this->cnx->consultar($sql)) {
                $this->errorConsultarBd["consola"] = "Error al consultar el total de novedades para un catedratico.";
                return $this->errorConsultarBd;
            }
            $r_total_horas_factor = $this->cnx->json; //Almacenamos el total de horas en agenda_periodo del docente.
            foreach ($r_total_horas_factor as $fe_horas) {
                $total_horas_factor = $fe_horas['total']; //Se almacena la cantidad total de horas de agenda periodo .
            }

            $r_periodo_nombre = $servicioCargaDocente->obtenerPeriodoNombrePorCodigo($PerCodigo);
            if (!$r_periodo_nombre["resultado"]) {
                return $r_periodo_nombre;
            }
            $periodoNombre = $r_periodo_nombre["data"]["periodoNombre"];

            $cargaDetalle = $servicioCargaDocente->obtenerCargaDetalladaDocente($UapCodigo, $periodoNombre, $UaaDependencia);
            if (!$cargaDetalle["resultado"]) {
                return $cargaDetalle;
            }

            $total_horas_descarga = $cargaDetalle["data"]["totalSemestre"];

            // Verificamos si es la facultad de salud (23)
            if ($UaaDependencia == 23) {
                $total_factor = $cantidad_horas_nuevas * 1;
                if ($CarCodigo == "T") { // En caso de ser teorico
                    $total_factor = ($cantidad_horas_nuevas * 2) + 1 * $CurSemanas;
                }
                if ($CarCodigo == "TP") { // En caso de ser teorico practico, no discrimina subgrupo.
                    $total_factor = ($cantidad_horas_nuevas * 1.5) + 1 * $CurSemanas;
                }
            }

            // Verificamos si es la facultad de ingenieria (21)
            if ($UaaDependencia == 21) {
                $total_factor = $CurSemanas;
                if ($CarCodigo == "T") { //En caso de ser teorico.
                    $total_factor = ($AsiCreditosTeoria * 3) * $CurSemanas;
                }
                if ($CarCodigo == "TP") { //En caso de ser teorico practico
                    if ($SubGrupo == "00") { //En caso de ser el subgrupo 00 que es teoria
                        $total_factor = ($AsiCreditosTeoria * 3) * $CurSemanas;
                    } else { //En caso de ser subgrupo 01,02,03...etc que son las practicas
                        $total_factor = ($AsiCreditosPractica * 3) * $CurSemanas;
                    }
                }
            }

            // Verificamos si es para las facultades: 
            // 19	FACULTAD ECONOMIA Y ADMINISTRACION
            // 20	FACULTAD DE EDUCACION
            // 22	FACULTAD CIENCIAS EXACTAS Y NATURALES
            // 24	FACULTAD CIENCIAS SOCIALES Y HUMANAS
            if ($UaaDependencia == 19 || $UaaDependencia == 20 || $UaaDependencia == 22 || $UaaDependencia == 24) {
                $total_factor = $CurSemanas * 1.5;
                if ($CarCodigo == "T") { //En caso de ser teorico.
                    $total_factor = ($AsiCreditosTeoria * 3) * $CurSemanas;
                }
                if ($CarCodigo == "TP") { //En caso de ser teorico practico
                    if ($SubGrupo == "00") { //En caso de ser el subgrupo 00 que es teoria
                        $total_factor = ($AsiCreditosTeoria * 3) * $CurSemanas;
                    } else { //En caso de ser subgrupo 01,02,03...etc que son las practicas
                        $total_factor = ($AsiCreditosPractica * 3) * $CurSemanas;
                    }
                }
            }

            $total_factor = $servicioCargaDocente->calcularFactorCarga($UaaDependencia, $CarCodigo, $SubGrupo, $cantidad_horas_nuevas, $CurSemanas, $AsiCreditosTeoria, $AsiCreditosPractica, $UaaCodigo);
            $total_horas_descarga = $total_horas_descarga + $total_factor; // se le adicionan a la descarga total el factor calculado segun la dependencia y el caracter

            //5	TIEMPO COMPLETO
            if ($DedCodigo == 5) {
                if ($total_horas_descarga <= 880) {
                    // Se procede a realizar la programacion.
                    $respuesta = $this->guardarHorario($obj);
                } else {
                    if ($perNN == true) {
                        // Se procede a realizar la programacion pero es un NN.
                        $respuesta = $this->guardarHorario($obj);
                    } else {
                        return array(
                            "resultado" => false,
                            "mensaje" => "ERROR. La vinculación seleccionada es de TIEMPO COMPLETO por lo tanto no debe pasar las 880 horas, el total de horas actual es de {$total_horas_descarga}."
                        );
                    }
                }
            }

            //4	MEDIO TIEMPO
            if ($DedCodigo == 4) {
                if ($total_horas_descarga <= 440) {
                    // Se procede a realizar la programacion.
                    $respuesta = $this->guardarHorario($obj);
                } else {
                    if ($perNN == true) {
                        // Se procede a realizar la programacion pero es un NN.
                        $respuesta = $this->guardarHorario($obj);
                    } else {
                        return array(
                            "resultado" => false,
                            "mensaje" => "ERROR. La vinculación seleccionada es de MEDIO TIEMPO por lo tanto no debe pasar las 440 horas, el total de horas actual es de {$total_horas_descarga}."
                        );
                    }
                }
            }
        }
        return $respuesta;
    }

    //Inicio funcion consultarEspeciosVirtuales.
    //Permite consultar los especios virtuales de un web parametro
    function consultarEspeciosVirtuales()
    {
        //Consultamos los codigos de los espacios especificamente para aulas virtuales.
        $sql = "SELECT wep_valor WepValor from web_parametro where wep_nombre = 'ESPACIOS_VIRTUALES'";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar los codigos de los espacios virtuales.";
            return $this->errorConsultarBd;
        }

        $r_codigos_esp_virtuales = $this->cnx->json;

        $sql = "SELECT 
            esp.esp_codigo EspCodigo, 
            esp.esp_espacio_codigo EspEspacioCodigo, 
            esp.esp_nombre EspNombre,
            esp.esp_nombre_corto EspNombreCorto, 
            'V' EspTipo
        FROM 
            espacio esp 
        WHERE 
            esp.esp_codigo IN ({$r_codigos_esp_virtuales[0]['WepValor']})";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar los espacios virtuales.";
            return $this->errorConsultarBd;
        }

        return array(
            "resultado" => true,
            "mensaje" => "Espacios virtuales consultados correctamente.",
            "data" => $this->cnx->json
        );
    }

    //Inicio funcion consultarEspaciosAsignados
    //Permite consultar los espacios asignados para una unidad en determinadas fechas.
    function consultarEspaciosAsignados($obj)
    {
        //Validaciones
        if ($obj->PraEstado == 0) {
            return array(
                "resultado" => false,
                "mensaje" => "El calendario seleccionado se ha desactivado por el administrador.",
                "consola" => "El estado de la apertura para este calendario se encuentra desactivado por el administrador.",
            );
        }

        $date = date("Y-m-d H:i");

        if ($obj->Administrador == 0) {
            if ($date <= $obj->PraFechaInicio or $date >= $obj->PraFechaFin) {
                return array(
                    "resultado" => false,
                    "mensaje" => "La apertura para la programación académica de esta unidad y calendario está entre {$obj->PraFechaInicio} y {$obj->PraFechaFin}.",
                    "consola" => "la fecha {$date} se encuentra fuera del rango entre {$obj->PraFechaInicio} y {$obj->PraFechaFin}.",
                );
            }
        }

        if (!isset($obj->UaaCodigo) || !is_numeric($obj->UaaCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo de la unidad.",
                "consola" => "El codigo de la unidad no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->FechaInicio)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio la fecha inicial.",
                "consola" => "La fecha inicial no se envio correctamente.",
            );
        }
        if (!isset($obj->FechaFin)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio la fecha final.",
                "consola" => "La fecha final no se envio correctamente.",
            );
        }
        if (!isset($obj->PerFechaInicio)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio la fecha inicial del periodo.",
                "consola" => "La fecha inicial del periodo no se envio correctamente.",
            );
        }
        if (!isset($obj->PerFechaFin)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio la fecha final del periodo.",
                "consola" => "La fecha final del periodo no se envio correctamente.",
            );
        }

        if (!isset($obj->SedCodigoCurso) || !is_numeric($obj->SedCodigoCurso)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo de la sede donde se programó el curso.",
                "consola" => "El codigo de la sede donde se programo el curso no es numerico o no se envio correctamente.",
            );
        }

        //Parametros
        $FechaInicio = $obj->FechaInicio; //Contiene la fecha inicial en la que se desea programar yyyy-mm-dd.
        $FechaFin = $obj->FechaFin; //Contiene la fecha final en la que se desea programar yyyy-mm-dd.
        $UaaCodigo = $obj->UaaCodigo; //Contiene el codigo de la uaa (unidad) de la que se desea programar.
        $UaaCodigoSeleccionado = $UaaCodigo;
        $CalCodigo = $obj->CalCodigo; //Contiene el codigo del calendario seleccionado.
        $UaaDependencia = $obj->UaaDependencia; //Contiene el codigo de la dependencia de la unidad.
        $SedCodigo = $obj->SedCodigo; //Contiene el codigo de la sede de la unidad
        $SedCodigoCurso = $obj->SedCodigoCurso; //Contiene el codigo de la sede en la que se programo el curso.
        $filtroEspacio = "";
        if (isset($obj->EspCodigo) && is_numeric($obj->EspCodigo)) {
            $filtroEspacio = " AND esp.esp_codigo = {$obj->EspCodigo}";
        }

        if ($obj->PeriodoPersonalizado != '') { //Se evalua si el calendario seleccionado tiene un periodo con fechas personalizadas para este calendario y esta unidad.
            $periodo_personalizado = explode(" ", $obj->PeriodoPersonalizado); //Periodo personalizado trae las dos fechas juntas separadas por espacios "yyyy-mm-dd yyyy-mm-dd"
            $PerFechaInicio = $periodo_personalizado[0]; //Contiene la fecha inicial del periodo personalizado seleccionado yyyy-mm-dd.
            $PerFechaFin = $periodo_personalizado[1]; //Contiene la fecha final del periodo personalizado seleccionado yyyy-mm-dd.
        } else {
            $PerFechaInicio = $obj->PerFechaInicio; //Contiene la fecha inicial del periodo seleccionado yyyy-mm-dd.
            $PerFechaFin = $obj->PerFechaFin; //Contiene la fecha final del periodo seleccionado yyyy-mm-dd.
        }
        $PerFechaInicioSql = FechaSqlServer::toSqlDateTime2($PerFechaInicio, false);
        $PerFechaFinSql = FechaSqlServer::toSqlDateTime2($PerFechaFin, true);
        $FechaInicioSql = FechaSqlServer::toSqlDateTime2($FechaInicio, false);
        $FechaFinFinDiaSql = FechaSqlServer::toSqlDateTime2($FechaFin, true);
        if ($PerFechaInicioSql === false || $PerFechaFinSql === false || $FechaInicioSql === false || $FechaFinFinDiaSql === false) {
            return array(
                "resultado" => false,
                "mensaje" => "Formato de fecha inválido al consultar espacios asignados.",
                "consola" => "No se pudieron preparar fechas SQL ({$PerFechaInicio}, {$PerFechaFin}, {$FechaInicio}, {$FechaFin}).",
            );
        }

        $unidades_busqueda = $this->obtenerUnidadesBusquedaEspacios($UaaCodigoSeleccionado, $UaaDependencia, true);
        if ($unidades_busqueda == '') {
            return array(
                "resultado" => false,
                "mensaje" => "No se pudo definir la unidad para consultar espacios asignados.",
                "consola" => "UaaCodigo/UaaDependencia invalidos en consultarEspaciosAsignados().",
            );
        }

        //Consultamos si el programa al que vamos a programar tiene apertura de repesca activa sin vencer
        $dateSql = FechaSqlServer::toSqlDateTime2($date, false);
        if ($dateSql === false) {
            return array(
                "resultado" => false,
                "mensaje" => "Formato de fecha inválido para validar repesca.",
                "consola" => "No se pudo preparar la fecha actual ({$date}) para SQL Server.",
            );
        }
        $sql = "SELECT
                pra.cal_codigo CalCodigo
            FROM programacionacademica.programacion_academica pra
            WHERE
                pra.cal_codigo = {$CalCodigo}
                AND pra.uaa_codigo = {$UaaCodigoSeleccionado}
                AND {$dateSql} BETWEEN pra.pra_fecha_inicio AND pra.pra_fecha_fin
                AND pra.pra_estado = 1
                AND pra.prp_codigo = 4
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar la repesca del programa. " . $this->cnx->mjeError;
            $this->errorConsultarBd["sql"] = $sql;
            return $this->errorConsultarBd;
        }

        $r_repesca = $this->cnx->json;
        $codigo_universidad = ""; //Tendra el codigo de la universidad en caso de tener repesca

        if (count($r_repesca) > 0 && $r_repesca[0]["CalCodigo"] != '') { //En caso de tener repesca activa se agrega el codigo de la universidad
            $codigo_universidad = ",315"; //El 315 es el codigo de la universidad y todos los espacios de repesca se asignan ahi.
        }

        $sql = "SELECT DISTINCT 
            esp.esp_codigo EspCodigo, 
            esp.esp_espacio_codigo EspEspacioCodigo, 
            esp.esp_nombre EspNombre,
            esp.esp_nombre_corto EspNombreCorto,
            sed.sed_nombre SedNombre, 
            esp.esp_capacidad EspCapacidad,
			min(eso.eso_fecha) as FechaMin, 
            max(eso.eso_fecha) as FechaMax,
            'F' EspTipo ,
            CONVERT(VARCHAR, uaa.uaa_codigo) + ' ' + uaa.uaa_nombre_corto Unidad
		FROM 
            espacio esp
        INNER JOIN espacio_ocupacion eso ON esp.esp_codigo = eso.esp_codigo AND eso.uaa_codigo in ({$unidades_busqueda}{$codigo_universidad}) AND eso.eso_fecha BETWEEN {$PerFechaInicioSql} AND {$PerFechaFinSql}
        INNER JOIN bloque blo ON esp.blo_codigo = blo.blo_codigo 
        INNER JOIN sub_sede sus ON blo.sus_codigo = sus.sus_codigo 
        INNER JOIN sede sed ON sed.sed_codigo = sus.sed_codigo AND sed.sed_codigo = {$SedCodigoCurso}
        INNER JOIN uaa ON uaa.uaa_codigo = eso.uaa_codigo
        WHERE 
            esp.eti_codigo != 6
            {$filtroEspacio}
        GROUP BY 
            esp.esp_codigo, 
            esp.esp_espacio_codigo, 
            esp.esp_nombre,
            esp.esp_nombre_corto,
            sed.sed_codigo,
            sed.sed_nombre,
            esp.esp_capacidad,
            CONVERT(VARCHAR, uaa.uaa_codigo) + ' ' + uaa.uaa_nombre_corto
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar los espacios asignados.";
            return $this->errorConsultarBd;
        }

        return array(
            "resultado" => true,
            "mensaje" => "Espacios consultados correctamente.",
            "data" => $this->cnx->json,
            "repesca" => $codigo_universidad,
        );
    }

    //Inicio funcion consultarEspaciosFisicosConDisponibilidad
    //Permite consultar los espacios asignados y sus horas disponibles para la fecha seleccionada.
    function consultarEspaciosFisicosConDisponibilidad($obj)
    {
        $salidaEspacios = $this->consultarEspaciosAsignados($obj);
        if ($salidaEspacios["resultado"] == false) {
            return $salidaEspacios;
        }

        $espacios = $salidaEspacios["data"];
        if (count($espacios) <= 0) {
            return array(
                "resultado" => true,
                "mensaje" => "Espacios consultados correctamente.",
                "data" => array(),
                "total_disponibles" => 0,
                "total_sin_disponibilidad" => 0,
            );
        }

        if (!isset($obj->UapCodigo) || !is_numeric($obj->UapCodigo)) {
            foreach ($espacios as $key => $espacio) {
                $espacios[$key]["HorasDisponibles"] = array();
                $espacios[$key]["TotalHorasDisponibles"] = 0;
                $espacios[$key]["TieneDisponibilidad"] = false;
            }

            return array(
                "resultado" => true,
                "mensaje" => "Espacios consultados correctamente. No se pudo calcular disponibilidad porque no se envio el docente.",
                "data" => $espacios,
                "total_disponibles" => 0,
                "total_sin_disponibilidad" => count($espacios),
            );
        }

        $FechaInicio = date('Y-m-d', strtotime($obj->FechaInicio));
        $FechaFin = date('Y-m-d', strtotime($obj->FechaFin));
        $FechaInicioSql = FechaSqlServer::toSqlDateTime2($FechaInicio, false);
        $FechaFinSql = FechaSqlServer::toSqlDateTime2($FechaFin, true);
        if ($FechaInicioSql === false || $FechaFinSql === false) {
            return array(
                "resultado" => false,
                "mensaje" => "Formato de fechas invalido para consultar disponibilidad de espacios.",
                "consola" => "No se pudieron preparar expresiones SQL para FechaInicio ({$FechaInicio}) o FechaFin ({$FechaFin})."
            );
        }

        $DiaCodigo = date("w", strtotime($FechaInicio));
        if ($DiaCodigo == 0) {
            $DiaCodigo = 7;
        }

        $UapCodigo = $obj->UapCodigo;
        $unidadesDisponibilidad = $this->obtenerUnidadesBusquedaEspacios($obj->UaaCodigo, isset($obj->UaaDependencia) ? $obj->UaaDependencia : '', true);
        if ($unidadesDisponibilidad == '') {
            return array(
                "resultado" => false,
                "mensaje" => "No se pudo definir la unidad para consultar disponibilidad de espacios.",
                "consola" => "UaaCodigo/UaaDependencia invalidos en consultarEspaciosFisicosConDisponibilidad()."
            );
        }
        if (isset($salidaEspacios["repesca"]) && $salidaEspacios["repesca"] != '') {
            $unidadesDisponibilidad .= $salidaEspacios["repesca"];
        }

        $codigosEspacios = array();
        foreach ($espacios as $espacio) {
            if (isset($espacio["EspCodigo"]) && is_numeric($espacio["EspCodigo"])) {
                $codigosEspacios[] = $espacio["EspCodigo"];
            }
        }

        $codigosEspacios = array_unique($codigosEspacios);
        if (count($codigosEspacios) <= 0) {
            return array(
                "resultado" => true,
                "mensaje" => "Espacios consultados correctamente.",
                "data" => $espacios,
                "total_disponibles" => 0,
                "total_sin_disponibilidad" => count($espacios),
            );
        }

        $espaciosSql = implode(",", $codigosEspacios);
        $sql = "
        DECLARE @FechaInicio DATETIME2 = '{$FechaInicio}';
        DECLARE @FechaFin DATETIME2 = '{$FechaFin}';

        SELECT
            eso.esp_codigo AS EspCodigo,
            h.hra_codigo AS HraCodigo,
            h.hra_nombre AS HraNombre,
            h.hra_inicio AS HraInicio,
            h.hra_fin AS HraFin
        FROM espacio_ocupacion eso
        INNER JOIN hora h
            ON h.hra_codigo = eso.hra_codigo
        WHERE
            eso.esp_codigo IN ({$espaciosSql})
            AND eso.uaa_codigo IN ({$unidadesDisponibilidad})
            AND eso.dia_codigo = {$DiaCodigo}
            AND eso.eso_actividad IS NULL
            AND eso.eso_fecha >= @FechaInicio
            AND eso.eso_fecha <= @FechaFin
            AND NOT EXISTS (
                SELECT 1
                FROM espacio_ocupacion d
                WHERE
                    d.uap_codigo = {$UapCodigo}
                    AND d.dia_codigo = {$DiaCodigo}
                    AND d.hra_codigo = h.hra_codigo
                    AND d.eso_fecha >= @FechaInicio
                    AND d.eso_fecha <= @FechaFin
            )
            AND NOT EXISTS (
                SELECT 1
                FROM espacio_ocupacion e
                WHERE
                    e.esp_codigo = eso.esp_codigo
                    AND e.hra_codigo = h.hra_codigo
                    AND e.dia_codigo = {$DiaCodigo}
                    AND e.eso_actividad IS NOT NULL
                    AND e.eso_fecha >= @FechaInicio
                    AND e.eso_fecha <= @FechaFin
                )
            GROUP BY
                eso.esp_codigo,
                h.hra_codigo,
                h.hra_nombre,
                h.hra_inicio,
                h.hra_fin
            ORDER BY
                eso.esp_codigo,
                h.hra_codigo;
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar la disponibilidad de los espacios asignados.";
            $this->errorConsultarBd["sql"] = $sql;
            return $this->errorConsultarBd;
        }

        $horasPorEspacio = array();
        foreach ($this->cnx->json as $hora) {
            $EspCodigo = $hora["EspCodigo"];
            if (!isset($horasPorEspacio[$EspCodigo])) {
                $horasPorEspacio[$EspCodigo] = array();
            }
            $horasPorEspacio[$EspCodigo][] = array(
                "HraCodigo" => $hora["HraCodigo"],
                "HraNombre" => $hora["HraNombre"],
                "HraInicio" => $hora["HraInicio"],
                "HraFin" => $hora["HraFin"],
            );
        }

        $totalDisponibles = 0;
        $totalSinDisponibilidad = 0;
        foreach ($espacios as $key => $espacio) {
            $EspCodigo = $espacio["EspCodigo"];
            $horas = isset($horasPorEspacio[$EspCodigo]) ? $horasPorEspacio[$EspCodigo] : array();
            $espacios[$key]["HorasDisponibles"] = $horas;
            $espacios[$key]["TotalHorasDisponibles"] = count($horas);
            $espacios[$key]["TieneDisponibilidad"] = count($horas) > 0;
            $espacios[$key]["DiaCodigo"] = $DiaCodigo;

            if (count($horas) > 0) {
                $totalDisponibles++;
            } else {
                $totalSinDisponibilidad++;
            }
        }

        usort($espacios, function ($a, $b) {
            if ($a["TotalHorasDisponibles"] == $b["TotalHorasDisponibles"]) {
                return strcmp($a["EspNombre"], $b["EspNombre"]);
            }
            return $b["TotalHorasDisponibles"] - $a["TotalHorasDisponibles"];
        });

        return array(
            "resultado" => true,
            "mensaje" => "Espacios y horas disponibles consultados correctamente.",
            "data" => $espacios,
            "total_disponibles" => $totalDisponibles,
            "total_sin_disponibilidad" => $totalSinDisponibilidad,
        );
    }

    /**
     * Consulta la carga detallada del docente seleccionado para mostrarla en la agenda.
     */
    public function consultarCargaDocente($obj)
    {
        if (!isset($obj->UapCodigo) || !is_numeric($obj->UapCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Codigo de vinculacion invalido.",
                "consola" => "UapCodigo no numerico en consultarCargaDocente()."
            );
        }
        if (!isset($obj->CalCodigo) || !is_numeric($obj->CalCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Codigo de calendario invalido.",
                "consola" => "CalCodigo no numerico en consultarCargaDocente()."
            );
        }

        $sqlPer = "SELECT per.per_nombre FROM calendario cal INNER JOIN periodo per ON per.per_codigo = cal.per_codigo WHERE cal.cal_codigo = {$obj->CalCodigo}";
        if (!$this->cnx->consultar($sqlPer)) {
            return array(
                "resultado" => false,
                "mensaje" => "Error al consultar el periodo del curso.",
                "consola" => "Fallo SQL al obtener periodo para CalCodigo {$obj->CalCodigo}",
                "errorSql" => isset($this->cnx->mjeError) ? $this->cnx->mjeError : ""
            );
        }

        if (count($this->cnx->json) < 1 || !isset($this->cnx->json[0]['per_nombre'])) {
            return array(
                "resultado" => false,
                "mensaje" => "No se encontro el periodo asociado al calendario.",
                "consola" => "Sin resultados al obtener periodo para CalCodigo {$obj->CalCodigo}."
            );
        }

        $periodoNombre = $this->cnx->json[0]['per_nombre'];
        $servicio = new ValidarCargaDocenteService($this->cnx);
        $facultadCodigo = isset($obj->FacultadCodigo) ? intval($obj->FacultadCodigo) : 0;

        $sqlInfo = "SELECT
                uap.vin_codigo VinCodigo,
                uap.ded_codigo DedCodigo,
                uap.sed_codigo SedCodigo,
                sed.sed_nombre SedNombre
            FROM uaa_personal uap
            INNER JOIN sede sed ON sed.sed_codigo = uap.sed_codigo
            WHERE uap.uap_codigo = {$obj->UapCodigo}";

        if (!$this->cnx->consultar($sqlInfo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Error al consultar la sede del docente.",
                "consola" => "Fallo SQL al obtener sede para UapCodigo {$obj->UapCodigo}",
                "errorSql" => isset($this->cnx->mjeError) ? $this->cnx->mjeError : ""
            );
        }

        if (count($this->cnx->json) < 1 || !isset($this->cnx->json[0]['VinCodigo'])) {
            return array(
                "resultado" => false,
                "mensaje" => "No se encontro la informacion de vinculacion del docente.",
                "consola" => "Sin resultados al obtener vinculacion/sede para UapCodigo {$obj->UapCodigo}."
            );
        }

        $vinCodigo = intval($this->cnx->json[0]['VinCodigo']);
        $dedCodigo = intval($this->cnx->json[0]['DedCodigo']);
        $sedCodigo = intval($this->cnx->json[0]['SedCodigo']);
        $sedNombre = $this->cnx->json[0]['SedNombre'];

        $topeSemanal = null;
        $topeSemestral = null;

        if (in_array($vinCodigo, array(14, 24, 49)) && $dedCodigo == 6) {
            $topes = $servicio->obtenerTopesSemanalesCatedra($sedCodigo);
            if (!$topes["resultado"]) {
                return $topes;
            }
            $topeSemanal = $sedCodigo != 1 ? floatval($topes["data"]["topeSedes"]) : floatval($topes["data"]["topeNeiva"]);
        } elseif ($vinCodigo == 12 || $vinCodigo == 23 || ($dedCodigo == 4 || $dedCodigo == 5)) {
            if ($dedCodigo == 5) {
                $topeSemestral = 880;
            }
            if ($dedCodigo == 4) {
                $topeSemestral = 440;
            }
        }

        $r = $servicio->obtenerCargaDetalladaDocente($obj->UapCodigo, $periodoNombre, $facultadCodigo);

        if ($r["resultado"]) {
            $r["data"]["topeSemanal"] = $topeSemanal;
            $r["data"]["topeSemestral"] = $topeSemestral;
            $r["data"]["sedCodigo"] = $sedCodigo;
            $r["data"]["sedNombre"] = $sedNombre;
        }

        return $r;
    }

    //Inicio funcion actualizarAgenda
    //Permite recalcular la agenda de un curso especifico.
    function actualizarAgenda($CurCodigo, $cantidadSemanas = "")
    {
        //Eliminamos todo registro relacionado con el curso especifico para actualizar.
        $sql = "DELETE from 
            agenda_periodo 
        where 
            cur_codigo = {$CurCodigo} ";

        if (!$this->cnx->sentencia($sql)) {
            $this->errorSentenciaBd["mensaje"] = "Error al eliminar la agenda del curso: {$CurCodigo}.";
            $this->errorSentenciaBd["consola"] = "Ha fallado el delete de la agenda del curso: {$CurCodigo}.";
            return $this->errorSentenciaBd;
        }

        //Consultamos lo relacionado al curso e informacion de la asignatura y docente.
        $sql = "SELECT 
		    asi.asi_codigo AsiCodigo,
            asi.car_codigo CarCodigo,
		    asi.asi_creditos AsiCreditos,
            asi.asi_creditos_teoria AsiCreditosTeoria,
            asi.asi_creditos_practica AsiCreditosPractica,
            asi.asi_nombre_corto AsiNombreCorto,
            resu.semanas ResuSemanas,
            uap.vin_codigo VinCodigo,
            uap.uap_codigo UapCodigo,
            cur.cur_codigo CurCodigo,
            eso.eso_subgrupo EsoSubgrupo,
            (resu.semanas * resu.horas_sema) Cantidad,
            uaa_asig.uaa_dependencia UaaDependencia,
            uap.per_codigo PerCodigo,
            uaa_eso.uaa_codigo UaaCodigo,
            uaa_eso.uaa_nombre_corto UaaNombreCorto,
            uap.ded_codigo DedCodigo
		from 
            (
                select 
                    * 
                from 
                    espacio_ocupacion 
                union all 
                select 
                    * 
                from 
                    espacio_ocupacion_historico
            ) as eso
            inner join uaa_personal uap on (eso.uap_codigo = uap.uap_codigo)
            inner join curso cur on (eso.eso_actividad = cur.cur_codigo)
            inner join asignatura asi on (cur.asi_codigo = asi.asi_codigo)
            inner join uaa uaa_asig on (uaa_asig.uaa_codigo = asi.uaa_codigo)
            inner join uaa uaa_eso on (uaa_eso.uaa_codigo = eso.uaa_codigo)
            inner join calendario cal on (cur.cal_codigo = cal.cal_codigo)
            inner join periodo per on (per.per_codigo = cal.per_codigo)
            inner join resumen_docencia_final resu 
            on (
                resu.cur_codigo = cur.cur_codigo and 
                resu.vin_codigo = uap.vin_codigo and
                resu.eso_subgrupo = eso.eso_subgrupo and
                resu.per_codigo = uap.per_codigo and 
                resu.uap_codigo = uap.uap_codigo
            )
		where 
            cur.cur_codigo = {$CurCodigo}
		group by 
            asi.asi_codigo, 
            asi.car_codigo, 
            asi.asi_creditos, 
            asi.asi_creditos_teoria, 
            asi.asi_creditos_practica, 
            asi.asi_nombre_corto,
            resu.semanas, 
            uap.vin_codigo, 
            uap.uap_codigo, 
            uap.ded_codigo,
            cur.cur_codigo, 
            eso.eso_subgrupo, 
            uaa_asig.uaa_dependencia, 
            uap.per_codigo, 
            uaa_eso.uaa_codigo,
            uaa_eso.uaa_nombre_corto, 
            uap.uap_codigo, 
            resu.semanas, 
            resu.horas_sema";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar la información de la agenda final del docente.";
            return $this->errorConsultarBd;
        }

        // Almacenamos los registros del curso y los subgrupos encontrados.
        $agenda_final = $this->cnx->json;

        foreach ($agenda_final as $agenda) {
            //Definimos los parametros que se van a usar.
            $AsiCodigo = $agenda['AsiCodigo']; //Codigo de la asignatura.
            $AsiNombreCorto = trim($agenda['AsiNombreCorto']); //NombreCorto de la asignatura
            $UaaDependencia = intval($agenda['UaaDependencia']); //Uaa propietaria de la asignatura.
            $PerCodigo = $agenda['PerCodigo']; //Codigo del docente.
            $EsoSubgrupo = $agenda['EsoSubgrupo']; //Subgrupo del curso especifico.
            $DedCodigo = $agenda['DedCodigo']; //Codigo de la dedicación del docente.
            $ResuSemanas = $agenda['ResuSemanas']; //Cantidad de semanas
            $FactorFormula = "0"; //Almacenamos el factor formula en 0, factor formula contendra la formula utilizada para calcular ej (3*3)+14.
            $Factor = 0; //Almacenamos el factor en 0, factor contendra el valor de la formula utilizada para calcular ej 23 
            $AsiCreditosPractica = $agenda['AsiCreditosPractica']; //Cantidad de creditos practica de la asignatura.
            $AsiCreditosTeoria = $agenda['AsiCreditosTeoria']; //Cantidad de creditos teoria de la asignatura.
            $AsiCreditos = $agenda['AsiCreditos']; //Cantidad de creditos totales de la asignatura.
            $CarCodigo = $agenda['CarCodigo']; //Caracter del curso
            $VinCodigo = $agenda['VinCodigo']; //Codigo del tipo de vinculación del docente.
            $UapCodigo = $agenda['UapCodigo']; //Codigo de la vinculación del docente.
            $UaaCodigo = $agenda['UaaCodigo']; //Codigo de la unidad donde se programo el curso especifico.
            $UaaNombreCorto = $agenda['UaaNombreCorto']; //Unidad donde se programo el curso especifico.
            $CursoTradicionalCredito = ''; //Almacenamos que es tradicional si el AsiCreditos es menor o igual a 0 o Almacenamos que es creditos si el AsiCreditos es mayor a 0.
            $HorasProgramadas = $agenda['Cantidad']; //Almacenamos las horas programadas del curso.
            $asignaturaEspecialArtes = false; //Se usa como bandera para identificar si es una asignatura especial de artes

            if ($AsiCreditos == "0" or $AsiCreditos == "") {
                $CursoTradicionalCredito = "tr"; //Tradicional
            } else {
                $CursoTradicionalCredito = "cr"; //Credito
            }

            //UaaDependencia
            //  385: VICERRECTORIA ACADEMICA
            //  315: UNIVERSIDAD SURCOLOMBIANA
            //UaaCodigo
            //  322: DPTO O PROGRAMA DE ENFERMERIA
            //  347: DPTO O PROGRAMA DE LICENCIATURA EN MATEMATICAS
            //  331: DPTO O PROGRAMA DE MEDICINA SOCIAL Y PREVENTIVA
            //  321: DPTO O PROGRAMA DE LICENCIATURA EN LENGUAS MODERNAS
            //  329: DPTO O PROGRAMA DE MEDICINA CIENCIAS BASICAS
            //  330: DPTO O PROGRAMA DE MEDICINA CIENCIAS CLINICAS
            //  335: DPTO O PROGRAMA DE DERECHO
            if ($UaaNombreCorto == 'SURCOLOMBIANA' or $UaaNombreCorto == 'FACULTAD DE SALUD' or $UaaDependencia == '' or $UaaDependencia == 385 or $UaaDependencia == 315 or $UaaCodigo == 322 or $UaaCodigo == 347 or $UaaCodigo == 331 or $UaaCodigo == 321   or $UaaCodigo == 329 or $UaaCodigo == 330 or $UaaCodigo == 335) {
                // La siguiente linea fallo en el modulo viejo por que en el caso de ser una asignatura de un programa normal, toma la dependencia como un programa.
                // esto por que el curso se programo a un programa y no a un curso de facultad, al momento de que la dependencia es un programa no entra a evalular ningun condicional de abajo.
                // se debe revisar para la implementación de este modulo nuevo.
                // $UaaDependencia = $UaaCodigo; //En caso de ser una facultad o la universidad surcolombiana la dependencia se toma como la unidad donde se programo el curso.
                $sql = "SELECT 
                    uaa_dependencia UaaDependencia
                from 
                    uaa 
                where 
                    uaa_codigo = {$UaaCodigo}";
                if (!$this->cnx->consultar($sql)) {
                    $this->errorConsultarBd["consola"] = "Error al consultar la dependencia de la unidad: {$UaaCodigo}.";
                    return $this->errorConsultarBd;
                }
                $r_dependencia = $this->cnx->json;
                foreach ($r_dependencia as $dependencia) {
                    $UaaDependencia = $dependencia['UaaDependencia'];
                }
            }

            //En el caso de que la unidad sea una facultad el va a caer en un error al consultar 
            //la dependencia de la facultad, vuelve a ser la 385 y genera error en las agendas con carga 0

            // 19	1	FACULTAD ECONOMIA Y ADMINISTRACION
            // 20	1	FACULTAD DE EDUCACION
            // 21	1	FACULTAD DE INGENIERIA
            // 22	1	FACULTAD CIENCIAS EXACTAS Y NATURALES
            // 23	1	FACULTAD DE SALUD
            // 24	1	FACULTAD CIENCIAS SOCIALES Y HUMANAS
            // 25	1	FACULTAD DE CIENCIAS JURIDICAS Y POLITICAS

            //Para solucionarlo se comprueba que la unidad sea una facultad (uat_codigo = 1)
            //en caso de serlo se remplaza la dependencia por la unidad.

            $sql = "SELECT uat_codigo TipoUnidad FROM uaa WHERE uaa.uaa_codigo = {$UaaCodigo}";

            if (!$this->cnx->consultar($sql)) {
                $this->errorConsultarBd["consola"] = "Error al buscar si la unidad es una facultad.";
                return $this->errorConsultarBd;
            }

            $r_unidad_facultad = $this->cnx->json;
            if ($r_unidad_facultad[0]["TipoUnidad"] == "1") {
                //Si la unidad es una facultad, se le asigna a la dependencia esa unidad.
                $UaaDependencia = $UaaCodigo;
            }


            $TiempoCompleto = 0; //Se establece por defecto 0 para especificar que no es tiempo completo.
            //VinCodigo: 24	CATEDRA VISITANTE DOCENTE
            //DedCodigo: 5	TIEMPO COMPLETO
            //DedCodigo: 4	MEDIO TIEMPO
            //DedCodigo: 6	POR HORAS
            if ($VinCodigo == 24 and ($DedCodigo == 5 or $DedCodigo == 4)) {
                $TiempoCompleto = 1; //Se establece como docente de tiempo completo.
            }

            //Si el docente es de tiempo completo o alguna de estas vinculaciones:
            //  12	DE PLANTA DOCENTE
            //  23	NOMBRAMIENTO OCASIONAL DOCENTE
            if ($VinCodigo == 12 or $VinCodigo == 23 or $TiempoCompleto == 1) {
                //si es deporte formativo para docentes de tiempo completo (55087 BIUSCO01 DEPORTE FORMATIVO)
                if ($AsiCodigo == '55087' || $AsiCodigo == 55087) {
                    //vale 1 credito, segun acuerdo 053 de 2006 por el cual se adoptan cursos institucionales
                    $CursoTradicionalCredito = "cr"; //Credito
                    $AsiCreditos = 1;
                }

                //Validacion acuerdo No, 312 de 2022 el 15 de dicembre del 2022
                $AsignaturasEspeciales = array(
                    'BEEDEA01',
                    'BEEDEA02',
                    'BEEDEA06',
                    'BEEDEA07',
                    'BEEDEA11',
                    'BEEDEA15',
                    'BEEDEA16',
                    'BEEDAR15',
                    'BEEDAR19',
                    'BEEDAR24',
                    'BEEDAR25',
                    'BEEDAR31',
                );

                // Se evalua si la asignatura esta en la lista de asignaturas especiales, si es asi sera true.
                $asignaturaEspecialArtes = in_array($AsiNombreCorto, $AsignaturasEspeciales) ? true : false;

                //En caso de que la asignatura sea de creditos.
                if ($CursoTradicionalCredito == "cr") {
                    //Iniicia la evaluacion para calcular el factor y otras variables dependiendo de la facultad.

                    //21. FACULTAD DE INGENIERIA
                    if ($UaaDependencia == '21') {
                        if ($CarCodigo == "T ") { // En caso de ser teorico
                            $FactorFormula = "({$AsiCreditos}*3)*{$ResuSemanas}";
                            $Factor = ($AsiCreditos * 3) * $ResuSemanas;
                        }
                        if ($CarCodigo == "TP") { // En caso de ser teorico practico.
                            if ($EsoSubgrupo != "00") { // En caso de ser directamente un subgrupo
                                $FactorFormula = "({$AsiCreditosPractica}*3)*{$ResuSemanas}";
                                $Factor = ($AsiCreditosPractica * 3) * $ResuSemanas;
                            } else { //En caso de ser un 00 busca si tiene mas subgrupos.
                                $sql = "SELECT 
                                    eso_subgrupo 
                                from espacio_ocupacion 
								where eso_actividad = {$CurCodigo}
                                group by eso_subgrupo";
                                if (!$this->cnx->consultar($sql)) {
                                    $this->errorConsultarBd["consola"] = "Error al consultar los subgrupos del curso: {$CurCodigo}.";
                                    return $this->errorConsultarBd;
                                }
                                $r_subgrupo = $this->cnx->json;
                                if (count($r_subgrupo) == 1) { //En caso de tener solamente el 00
                                    $FactorFormula = "({$AsiCreditos}*3)*{$ResuSemanas}";
                                    $Factor = ($AsiCreditos * 3) * $ResuSemanas;
                                } else { //En caso de tener mas de 00,01,02,etc
                                    $FactorFormula = "({$AsiCreditosTeoria}*3)*{$ResuSemanas}";
                                    $Factor = ($AsiCreditosTeoria * 3) * $ResuSemanas;
                                }
                            }
                        }
                        if ($CarCodigo == "P ") { // En caso de ser practica.
                            //Preguntar a doña rocio este condicional por que no se sabe bien que calcula.
                            if ($EsoSubgrupo != "00") { //En caso de ser un subgrupo,
                                $FactorFormula = "{$HorasProgramadas}*1";
                                $Factor = $HorasProgramadas * 1;
                            } else {
                                $FactorFormula = "{$HorasProgramadas}*1";
                                $Factor = $HorasProgramadas * 1;
                            }
                        }
                        if ($CarCodigo == "PP") { // En caso de ser practica pedagogica
                            if ($EsoSubgrupo != "00") { //En caso de ser un subgrupo,
                                $FactorFormula = "{$AsiCreditosPractica}*1";
                                $Factor = $HorasProgramadas * 1;
                            } else {
                                $FactorFormula = "{$HorasProgramadas}*1";
                                $Factor = $HorasProgramadas * 1;
                            }
                        }
                        if ($CarCodigo == "PF") { // En caso de ser practica profesional
                            if ($EsoSubgrupo != "00") { //En caso de ser un subgrupo,
                                $FactorFormula = "{$HorasProgramadas}";
                                $Factor = $HorasProgramadas * 1;
                            } else {
                                $FactorFormula = "{$HorasProgramadas}";
                                $Factor = $HorasProgramadas * 1;
                            }
                        }
                    }

                    //19. FACULTAD DE ADMINISTRACIÓN
                    if ($UaaDependencia == 19) {
                        if ($CarCodigo == "T ") { // En caso de ser teorico
                            $FactorFormula = "({$AsiCreditos}*3)*{$ResuSemanas}";
                            $Factor = ($AsiCreditos * 3) * $ResuSemanas;
                        }
                        if ($CarCodigo == "TP") { // En caso de ser teorico practico.
                            if ($EsoSubgrupo != "00") { // En caso de ser directamente un subgrupo
                                $FactorFormula = "({$AsiCreditosPractica}*3)*{$ResuSemanas}";
                                $Factor = ($AsiCreditosPractica * 3) * $ResuSemanas;
                            } else { //no discrimina
                                $FactorFormula = "({$AsiCreditos}*3)*{$ResuSemanas}";
                                $Factor = ($AsiCreditos * 3) * $ResuSemanas;
                            }
                        }
                        if ($CarCodigo == "P " or $CarCodigo == "PP") { // En caso de ser practica o practica pedagocica.
                            //No se discrimina si es que subgrupo es 00,01,02,03,etc.
                            $FactorFormula = "{$HorasProgramadas}*1";
                            $Factor = $HorasProgramadas * 1;
                        }
                        if ($CarCodigo == "PF") { // En caso de ser practica profesional
                            $FactorFormula = "{$HorasProgramadas}";
                            $Factor = $HorasProgramadas * 1;
                        }
                    }

                    //20. FACULTAD DE EDUCACIÓN
                    if ($UaaDependencia == 20) {
                        if ($CarCodigo == "T ") { // En caso de ser teorico
                            if ($AsiCodigo == '55087' || $AsiCodigo == 55087) {
                                //vale 1 credito, segun acuerdo 053 de 2006 por el cual se adoptan cursos institucionales
                                $AsiCreditos = 1;
                            }
                            $FactorFormula = "({$AsiCreditos}*3)*{$ResuSemanas}";
                            $Factor = ($AsiCreditos * 3) * $ResuSemanas;
                        }
                        if ($CarCodigo == "TP") { // En caso de ser teorico practico.
                            if ($asignaturaEspecialArtes) {
                                if ($EsoSubgrupo == "00") {
                                    $creditosEspecial = intval($AsiCreditos) / 3; // Los creditos seran divididos entre 3 docentes siempre
                                    $FactorFormula = "({$creditosEspecial}*3)*{$ResuSemanas}";
                                    $Factor = ($creditosEspecial * 3) * $ResuSemanas;
                                }
                            } else {
                                if ($EsoSubgrupo != "00") { // En caso de ser directamente un subgrupo
                                    $FactorFormula = "({$AsiCreditosPractica}*3)*{$ResuSemanas}";
                                    $Factor = ($AsiCreditosPractica * 3) * $ResuSemanas;
                                } else { //En caso de ser un 00 busca si tiene mas subgrupos.
                                    $sql = "SELECT 
                                        eso_subgrupo 
                                    from espacio_ocupacion 
                                    where eso_actividad = {$CurCodigo}
                                    group by eso_subgrupo";
                                    if (!$this->cnx->consultar($sql)) {
                                        $this->errorConsultarBd["consola"] = "Error al consultar los subgrupos del curso: {$CurCodigo}.";
                                        return $this->errorConsultarBd;
                                    }
                                    $r_subgrupo = $this->cnx->json;
                                    if (count($r_subgrupo) == 1) { //En caso de tener solamente el 00
                                        $FactorFormula = "({$AsiCreditos}*3)*{$ResuSemanas}";
                                        $Factor = ($AsiCreditos * 3) * $ResuSemanas;
                                    } else { //En caso de tener mas de 00,01,02,etc
                                        $FactorFormula = "({$AsiCreditosTeoria}*3)*{$ResuSemanas}";
                                        $Factor = ($AsiCreditosTeoria * 3) * $ResuSemanas;
                                    }
                                }
                            }
                        }
                        if ($CarCodigo == "P ") { // En caso de ser practica.
                            $FactorFormula = "{$HorasProgramadas}";
                            $Factor = $HorasProgramadas;
                        }
                        if ($CarCodigo == "P") { // En caso de ser practica pero sin espacio.
                            if ($EsoSubgrupo != "00") { // En caso de ser directamente un subgrupo
                                $FactorFormula = "{$ResuSemanas}*1";
                                $Factor = $HorasProgramadas;
                            } else {
                                $FactorFormula = "{$HorasProgramadas}";
                                $Factor = $HorasProgramadas;
                            }
                        }
                        if ($CarCodigo == "PP") { // En caso de ser practica profesional
                            $FactorFormula = "{$HorasProgramadas}";
                            $Factor = $HorasProgramadas;
                        }
                        if ($CarCodigo == "PF") { // En caso de ser practica profesional
                            $FactorFormula = "{$HorasProgramadas}";
                            $Factor = $HorasProgramadas;
                        }
                    }

                    // 24. FACULTAD CIENCIAS SOCIALES Y HUMANAS
                    // 25. FACULTAD DE CIENCIAS JURIDICAS Y POLITICAS
                    if ($UaaDependencia == 24 || $UaaDependencia == 25) {
                        if ($CarCodigo == "T ") { // En caso de ser teorico
                            $FactorFormula = "({$AsiCreditos}*3)*{$ResuSemanas}";
                            $Factor = ($AsiCreditos * 3) * $ResuSemanas;
                        }
                        if ($CarCodigo == "TP") { // En caso de ser teorico practico.
                            if ($EsoSubgrupo != "00") { // En caso de ser directamente un subgrupo
                                $FactorFormula = "({$AsiCreditosPractica}*3)*{$ResuSemanas}";
                                $Factor = ($AsiCreditosPractica * 3) * $ResuSemanas;
                            } else { //En caso de ser un 00 busca si tiene mas subgrupos.
                                $sql = "SELECT 
                                    eso_subgrupo 
                                from espacio_ocupacion 
								where eso_actividad = {$CurCodigo}
                                group by eso_subgrupo";
                                if (!$this->cnx->consultar($sql)) {
                                    $this->errorConsultarBd["consola"] = "Error al consultar los subgrupos del curso: {$CurCodigo}.";
                                    return $this->errorConsultarBd;
                                }
                                $r_subgrupo = $this->cnx->json;
                                if (count($r_subgrupo) == 1) { //En caso de tener solamente el 00
                                    $FactorFormula = "({$AsiCreditos}*3)*{$ResuSemanas}";
                                    $Factor = ($AsiCreditos * 3) * $ResuSemanas;
                                } else { //En caso de tener mas de 00,01,02,etc
                                    $FactorFormula = "({$AsiCreditosTeoria}*3)*{$ResuSemanas}";
                                    $Factor = ($AsiCreditosTeoria * 3) * $ResuSemanas;
                                }
                            }
                        }
                        if ($CarCodigo == "P " or $CarCodigo == "P" or $CarCodigo == "PP" or $CarCodigo == "PF") { // En caso de ser practica.
                            $FactorFormula = "{$HorasProgramadas}*1";
                            $Factor = $HorasProgramadas * 1;
                        }
                    }

                    // 22. FACULTAD CIENCIAS EXACTAS Y NATURALES
                    if ($UaaDependencia == 22) {
                        if ($CarCodigo == "T ") { // En caso de ser teorico
                            $FactorFormula = "({$AsiCreditos}*3)*{$ResuSemanas}";
                            $Factor = ($AsiCreditos * 3) * $ResuSemanas;
                        }
                        if ($CarCodigo == "TP") { // En caso de ser teorico practico.
                            if ($EsoSubgrupo != "00") { // En caso de ser directamente un subgrupo
                                $FactorFormula = "({$AsiCreditosPractica}*3)*{$ResuSemanas}";
                                $Factor = ($AsiCreditosPractica * 3) * $ResuSemanas;
                            } else { //En caso de ser un 00 busca si tiene mas subgrupos.
                                $sql = "SELECT 
                                    eso_subgrupo 
                                from espacio_ocupacion 
								where eso_actividad = {$CurCodigo}
                                group by eso_subgrupo";
                                if (!$this->cnx->consultar($sql)) {
                                    $this->errorConsultarBd["consola"] = "Error al consultar los subgrupos del curso: {$CurCodigo}.";
                                    return $this->errorConsultarBd;
                                }
                                $r_subgrupo = $this->cnx->json;
                                if (count($r_subgrupo) == 1) { //En caso de tener solamente el 00
                                    $FactorFormula = "({$AsiCreditos}*3)*{$ResuSemanas}";
                                    $Factor = ($AsiCreditos * 3) * $ResuSemanas;
                                } else { //En caso de tener mas de 00,01,02,etc
                                    $FactorFormula = "({$AsiCreditosTeoria}*3)*{$ResuSemanas}";
                                    $Factor = ($AsiCreditosTeoria * 3) * $ResuSemanas;
                                }
                            }
                        }
                        if ($CarCodigo == "P " or $CarCodigo == "P" or $CarCodigo == "PP") { // En caso de ser practica.
                            $FactorFormula = "{$HorasProgramadas}*1";
                            $Factor = $HorasProgramadas * 1;
                        }
                        if ($CarCodigo == "PF") { // En caso de ser practica.
                            $FactorFormula = "{$HorasProgramadas}";
                            $Factor = $HorasProgramadas;
                        }
                    }

                    // 23. FACULTAD DE SALUD
                    // 715. DPTO O PROGRAMA DE LICENCIATURA EN CIENCIAS NATURALES Y EDUCACION AMBIENTAL
                    if ($UaaDependencia == 23 or $UaaCodigo == 715 or $UaaCodigo == 706) {
                        if ($CarCodigo == "T ") { // En caso de ser teorico
                            $FactorFormula = "({$HorasProgramadas}*2)+1*{$ResuSemanas}";
                            $Factor = ($HorasProgramadas * 2) + 1 * $ResuSemanas;
                        }
                        if ($CarCodigo == "TP") { // En caso de ser teorico practico.
                            $FactorFormula = "({$HorasProgramadas}*1.5)+1*{$ResuSemanas}";
                            $Factor = ($HorasProgramadas * 1.5) + 1 * $ResuSemanas;
                        }
                        if ($CarCodigo == "P " or $CarCodigo == "P" or $CarCodigo == "PP") { // En caso de ser practica, practica pedagogica.
                            $FactorFormula = "{$HorasProgramadas}*1";
                            $Factor = $HorasProgramadas * 1;
                        }

                        //Esta sentencia se debe revisar por que en la original el uaa_codigo recibe
                        //como parametro la cantidad de horas programadas.
                        //Como sugerencia deberia recibir el codigo de la uaa programada en espacio_ocupacion.
                        $sql = "SELECT * 
                            FROM uaa 
                            WHERE uaa_nombre_corto LIKE '%psico%' 
                            AND  uaa_codigo = {$HorasProgramadas}";
                        if (!$this->cnx->consultar($sql)) {
                            $this->errorConsultarBd["consola"] = "Error al consultar las unidades que tienen psico en su nombre.";
                            return $this->errorConsultarBd;
                        }
                        $r_uaa_consulta = $this->cnx->json;
                        if (count($r_uaa_consulta) == 1) { //En caso de que el curso si sea de una unidad con psico
                            if ($CarCodigo == "T ") { // En caso de ser teorico
                                $FactorFormula = "({$HorasProgramadas}*2)+1*{$ResuSemanas}";
                                $Factor = ($HorasProgramadas * 2) + 1 * 15;
                            }
                            if ($CarCodigo == "TP") { // En caso de ser teorico practico
                                $FactorFormula = "({$HorasProgramadas}*1.5)+1*{$ResuSemanas}";
                                $Factor = ($HorasProgramadas * 1.5) + 1 * 15;
                            }
                            if ($CarCodigo == "P " or $CarCodigo == "PP") { // En caso de ser practica
                                $FactorFormula = "{$HorasProgramadas}*{$ResuSemanas}";
                                $Factor = $HorasProgramadas * $ResuSemanas;
                            }
                        }
                    }
                }

                //En caso de que la asignatura sea tradicional.
                if ($CursoTradicionalCredito == "tr") {
                    // 23. FACULTAD DE SALUD
                    if ($UaaDependencia == 23) {
                        if ($CarCodigo == "T ") { // En caso de ser teorico
                            $FactorFormula = "({$HorasProgramadas}*2)+1*{$ResuSemanas}";
                            $Factor = ($HorasProgramadas * 2) + 1 * $ResuSemanas;
                        }
                        if ($CarCodigo == "TP") { // En caso de ser teorico practico.
                            $FactorFormula = "({$HorasProgramadas}*1.5)+1*{$ResuSemanas}";
                            $Factor = ($HorasProgramadas * 1.5) + 1 * $ResuSemanas;
                        }
                        //Esta sentencia se debe revisar por que en la original el uaa_codigo recibe
                        //como parametro la cantidad de horas programadas.
                        //Como sugerencia deberia recibir el codigo de la uaa programada en espacio_ocupacion.
                        $sql = "SELECT * 
                            FROM uaa 
                            WHERE uaa_nombre_corto LIKE '%psico%' 
                            AND  uaa_codigo = {$HorasProgramadas}";
                        if (!$this->cnx->consultar($sql)) {
                            $this->errorConsultarBd["consola"] = "Error al consultar las unidades que tienen psico en su nombre.";
                            return $this->errorConsultarBd;
                        }
                        $r_uaa_consulta = $this->cnx->json;
                        if (count($r_uaa_consulta) == 1) { //En caso de que el curso si sea de una unidad con psico
                            if ($CarCodigo == "T ") { // En caso de ser teorico
                                $FactorFormula = "({$HorasProgramadas}*2)+1*{$ResuSemanas}";
                                $Factor = ($HorasProgramadas * 2) + 1 * 15;
                            }
                            if ($CarCodigo == "TP") { // En caso de ser teorico practico
                                $FactorFormula = "({$HorasProgramadas}*1.5)+1*{$ResuSemanas}";
                                $Factor = ($HorasProgramadas * 1.5) + 1 * 15;
                            }
                            if ($CarCodigo == "P " or $CarCodigo == "PP") { // En caso de ser practica
                                $FactorFormula = "{$HorasProgramadas}*{$ResuSemanas}";
                                $Factor = $HorasProgramadas * $ResuSemanas;
                            }
                        }
                    }

                    // 19	FACULTAD ECONOMIA Y ADMINISTRACION
                    // 21	FACULTAD DE INGENIERIA
                    // 20	FACULTAD DE EDUCACION
                    // 24	FACULTAD CIENCIAS SOCIALES Y HUMANAS
                    // 25	FACULTAD DE CIENCIAS JURIDICAS Y POLITICAS
                    // 26	ARTES
                    // 385	VICERRECTORIA ACADEMICA
                    // 388	EL APRENDIZAJE SIGNIFICATIVO PARA EL DESARROLLO DE LA COMPETENCIAS MATEMÁTICAS EN EL CONTEXTO DE LAS INSTITUCIONES EDUCATIVAS
                    // 391	MAESTRIA EN DIDACTICA DEL INGLES
                    if ($UaaDependencia == 19 or $UaaDependencia == 21 or $UaaDependencia == 24 or $UaaDependencia == 25 or $UaaDependencia == 26 or $UaaDependencia == 385 or $UaaDependencia == 388 or $UaaDependencia == 391 or $UaaDependencia == 20) {
                        if ($CarCodigo == "T ") { // En caso de ser teorico
                            $FactorFormula = "({$HorasProgramadas}*2)+1*{$ResuSemanas}";
                            $Factor = ($HorasProgramadas * 2) + 1 * $ResuSemanas;
                        }
                        if ($CarCodigo == "TP") { // En caso de ser teorico practico.
                            if ($EsoSubgrupo != "00") { // En caso de ser directamente un subgrupo
                                $FactorFormula = "({$AsiCreditosPractica}*3)*{$ResuSemanas}";
                                $Factor = ($AsiCreditosPractica * 3) * $ResuSemanas;
                            } else { //En caso de ser un 00 busca si tiene mas subgrupos.
                                $FactorFormula = "({$HorasProgramadas}*2)+1*{$ResuSemanas}";
                                $Factor = ($HorasProgramadas * 2) + 1 * $ResuSemanas;
                            }
                        }
                        if ($CarCodigo == "P " or $CarCodigo == "PP") { // En caso de ser practica o practica pedagogica.
                            if ($EsoSubgrupo != "00") { // En caso de ser directamente un subgrupo
                                $calculo = $HorasProgramadas / $ResuSemanas;
                                $FactorFormula = "{$calculo}*{$ResuSemanas}";
                                $Factor = $calculo * $ResuSemanas;
                            } else { //En caso de ser un 00 busca si tiene mas subgrupos.
                                $FactorFormula = "{$HorasProgramadas}*{$ResuSemanas}";
                                $Factor = $HorasProgramadas * $ResuSemanas;
                            }
                        }
                    }
                }

                if ($AsiCreditos > 0) {
                    $HorasProgramadas = $AsiCreditos;
                }
            } else if ($VinCodigo == 14 or $VinCodigo == 25  or $VinCodigo == 24 or $VinCodigo == 17 or $VinCodigo == 16 or $VinCodigo == 49) {
                //Si el docente tiene una de estas vinculaciones:
                //  14	CATEDRA DOCENTE
                //  24	CATEDRA VISITANTE DOCENTE
                //  25	CATEDRA ADICIONAL DOCENTE
                //  17	CATEDRA POSTGRADOS  DOCENTE
                //  16	DE AD HONOREM
                //  49	CATEDRA DOCENTE CONVENIO
                $FactorFormula = "{$HorasProgramadas}";
                $Factor = $HorasProgramadas;
            }

            //Inicio para insertar la agenda_periodo PP, P
            if ($CarCodigo == "PP" or $CarCodigo == "P" or $CarCodigo == "P ") {
                $sqlInsertar = "INSERT INTO  
                    agenda_periodo(
					    creditos,
                        caracter,
                        hora_teorica,
                        hora_practica,
					    tradicional_o_credito,
                        numero_total_hora,
					    factor,
                        semanas,
					    vinculacion,
                        uap_codigo,
					    cur_codigo,
                        sub_grupo,
					    total_horas,
                        per_codigo,
					    uaa_codigo,
                        factor_formula
                    )
				VALUES(
                    '{$AsiCreditos}',
                    '{$CarCodigo}',
                    '{$AsiCreditosTeoria}',
                    '{$AsiCreditosPractica}',
                    '{$CursoTradicionalCredito}',
                    '{$Factor}',
                    {$Factor},
                    '{$ResuSemanas}',
                    '{$VinCodigo}',
                    '{$UapCodigo}',
                    '{$CurCodigo}',
                    '{$EsoSubgrupo}',
                    '{$Factor}',
                    '{$PerCodigo}',
                    '{$UaaCodigo}',
                    '{$FactorFormula}'
                )";
                if (!$this->cnx->sentencia($sqlInsertar)) {
                    $this->errorSentenciaBd["mensaje"] = "Error al guardar la agenda del curso: {$CurCodigo}.";
                    $this->errorSentenciaBd["consola"] = "Ha fallado el insert p, pp de la agenda del curso: {$CurCodigo}.";
                    return $this->errorSentenciaBd;
                }
            } else {
                $sqlInsertar = "INSERT INTO  
                    agenda_periodo(
					    creditos,
                        caracter,
                        hora_teorica,
                        hora_practica,
					    tradicional_o_credito,
                        numero_total_hora,
					    factor,
                        semanas,
					    vinculacion,
                        uap_codigo,
					    cur_codigo,
                        sub_grupo,
					    total_horas,
                        per_codigo,
					    uaa_codigo,
                        factor_formula
                    )
				VALUES(
                    '{$AsiCreditos}',
                    '{$CarCodigo}',
                    '{$AsiCreditosTeoria}',
                    '{$AsiCreditosPractica}',
                    '{$CursoTradicionalCredito}',
                    '{$HorasProgramadas}',
                    {$Factor},
                    '{$ResuSemanas}',
                    '{$VinCodigo}',
                    '{$UapCodigo}',
                    '{$CurCodigo}',
                    '{$EsoSubgrupo}',
                    '{$HorasProgramadas}',
                    '{$PerCodigo}',
                    '{$UaaCodigo}',
                    '{$FactorFormula}'
                )";
                if (!$this->cnx->sentencia($sqlInsertar)) {
                    $this->errorSentenciaBd["mensaje"] = "Error al guardar la agenda del curso: {$CurCodigo}.";
                    $this->errorSentenciaBd["consola"] = "Ha fallado el insert t, tp, pf de la agenda del curso: {$CurCodigo}.";
                    return $this->errorSentenciaBd;
                }
            }
        }
        return true;
    }

    //Inicio funcion inactivarSubgrupoSinHorario
    //Permite inactivar los subgrupos que no tienen horario de un curso al que se le elimina el horario.
    public function inactivarSubgrupoSinHorario($CurCodigo)
    {

        //Se consulta los subgrupos de la tabla curso_cupo_subgrupo de un curso para revisar si tiene horario.
        $sql = "SELECT 
            cupsubg_subgrupo, 
            cupsubg_curso, 
	        espocu_subgrupo, 
            espocu_curso
	    from (
            select 
                ccs.eso_subgrupo as cupsubg_subgrupo, 
                cur.cur_codigo as cupsubg_curso
            from 
                curso_cupo_subgrupo ccs
            inner join curso cur on ccs.cur_codigo = cur.cur_codigo
            where  
                ccs.cus_estado = 1
        ) as a
        left join (
            select 
                eso_subgrupo as espocu_subgrupo,
                eso_actividad as  espocu_curso
            from 
                espacio_ocupacion
            where 
                eso_actividad is not null
            group by 
                eso_actividad, eso_subgrupo
        ) b on (
            a.cupsubg_curso = b.espocu_curso 
            and a.cupsubg_subgrupo = b.espocu_subgrupo 
        )
        where 
            cupsubg_curso = {$CurCodigo} 
            and espocu_subgrupo is null
        ";

        if (!$this->cnx->consultar($sql)) {
            // echo $sql;
            $this->errorConsultarBd["consola"] = "Error al consultar el horario de los subgrupos del curso: {$CurCodigo}.";
            return $this->errorConsultarBd;
        }
        $r_horario_subgrupo = $this->cnx->json; // almacenamos la respuesta de si un curso tiene subgrupos
        if (count($r_horario_subgrupo) < 1) { //Validamos que existan subgrupos, en caso contrario simplemente retornamos sin problema.
            return true;
        }

        for ($i = 0; $i < count($r_horario_subgrupo); $i++) { //En caso de existir por lo menos un subgrupo se recorre cada uno
            $SubGrupo = $r_horario_subgrupo[$i]['cupsubg_subgrupo']; //Almacenamos el subgrupos
            $sql = "SELECT 
                count(*) as CantMatriculados
            from 
                matricula_curso mac
            where 
                mac.cur_codigo = {$CurCodigo}
                and mac.mac_subgrupo = '{$SubGrupo}' 
                and mac.maa_codigo in (1,2)
            ";
            if (!$this->cnx->consultar($sql)) {
                // echo $sql;
                $this->errorConsultarBd["consola"] = "Error al consultar la cantidad de matriculados del curso: {$CurCodigo} subgrupo: {$SubGrupo}.";
                return $this->errorConsultarBd;
            }

            $r_matricula_subgrupo = $this->cnx->json; // almacenamos la cantidad de matriculados de un curso y subgrupo
            if ($r_matricula_subgrupo[0]['CantMatriculados'] < 1) { //se evalua si tiene 0 matriculados
                $sql = "UPDATE 
                    curso_cupo_subgrupo 
                set 
                    cus_estado = 0 
			    where 
                    cur_codigo = {$CurCodigo} 
                    and eso_subgrupo = '{$SubGrupo}'  
                ";
                if (!$this->cnx->sentencia($sql)) {
                    // echo $sql;
                    $this->errorSentenciaBd["mensaje"] = "Error desactivar el subgrupo: {$SubGrupo} del curso: {$CurCodigo}.";
                    $this->errorSentenciaBd["consola"] = "Ha fallado el update del subgrupo: {$SubGrupo} del curso: {$CurCodigo}.";
                    $this->errorSentenciaBd["sql"] = $sql;
                    return $this->errorSentenciaBd;
                }
            }
        }
        return true;
    }

    //Inicio funcion validarNotasRegistradas
    //Permite validar si un curso tiene estudiantes con notas definitivas registradas.
    //En caso de tener notas, no se debe permitir la eliminación del horario.
    function validarNotasRegistradas($CurCodigo)
    {
        $sql = "SELECT 
                    COUNT(*) TotalConNotas
                FROM 
                    matricula_curso mac
                INNER JOIN matricula mat ON mat.mat_codigo = mac.mat_codigo AND mat.mat_estado = 'A'
                WHERE 
                    mac.cur_codigo = {$CurCodigo} 
                    AND mac.maa_codigo IN (1,2)
                    AND mac.mac_definitiva IS NOT NULL";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al validar las notas del curso {$CurCodigo}.";
            return $this->errorConsultarBd;
        }

        $resultado = $this->cnx->json;

        if (isset($resultado[0]['TotalConNotas']) && $resultado[0]['TotalConNotas'] > 0) {
            return array(
                "resultado" => false,
                "mensaje" => "No se puede eliminar el horario del curso <b>{$CurCodigo}</b> porque tiene <b>{$resultado[0]['TotalConNotas']}</b> estudiante(s) con notas definitivas registradas.",
                "consola" => "El curso {$CurCodigo} tiene {$resultado[0]['TotalConNotas']} estudiante(s) con notas definitivas, no se permite eliminar el horario.",
            );
        }

        return true;
    }

    //Inicio funcion eliminarHorario
    //Permite eliminar un horario especifico de un curso
    function eliminarHorario($obj)
    {
        //Validaciones
        if (!isset($obj->CurCodigo) || !is_numeric($obj->CurCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo del curso.",
                "consola" => "El codigo del curso no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->EspCodigo) || !is_numeric($obj->EspCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo del espacio.",
                "consola" => "El codigo del espacio no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->DiaCodigo) || !is_numeric($obj->DiaCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo del dia.",
                "consola" => "El codigo del dia no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->HraCodigo) || !is_numeric($obj->HraCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo de la hora.",
                "consola" => "El codigo de la hora no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->EsoFechaInicio)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio la fecha inicial.",
                "consola" => "La fecha inicial no se envio correctamente.",
            );
        }
        if (!isset($obj->EsoFechaFin)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio la fecha final.",
                "consola" => "La fecha final no se envio correctamente.",
            );
        }
        if (!isset($obj->EsoSubGrupo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el sub grupo.",
                "consola" => "El sub grupo no se envio correctamente.",
            );
        }
        if (!isset($obj->UapCodigo) || !is_numeric($obj->UapCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo de la vinculación del docente.",
                "consola" => "El codigo de la vinculación del docente no es numérico o no se envio correctamente.",
            );
        }

        //Parametros
        $CurCodigo = $obj->CurCodigo; //Contiene el codigo del curso
        $EspCodigo = $obj->EspCodigo; //Contiene el codigo del espacio
        $DiaCodigo = $obj->DiaCodigo; //Contiene el codigo del dia 
        $HraCodigo = $obj->HraCodigo; //Contiene el codigo de la hora
        $EsoFechaInicio = $obj->EsoFechaInicio; //Contiene la fecha inicio programada del curso
        $EsoFechaFin = $obj->EsoFechaFin; //Contiene la fecha final programada del curso
        $EsoSubGrupo = $obj->EsoSubGrupo; //Contiene el subgrupo del curso
        $UapCodigo = $obj->UapCodigo; //Contiene el codigo de la vinculación del docente de la clase
        $mensaje = ""; //Se utiliza para mostrar mensaje en caso de no poder actualizar el historico.

        //Validamos que el curso no tenga estudiantes con notas definitivas registradas.
        $validacionNotas = $this->validarNotasRegistradas($CurCodigo);
        if ($validacionNotas !== true) {
            return $validacionNotas;
        }

        //Se valida para que en caso de ser de estos espacios puntuales el horario se elimine completamente
        //En caso de no ser asi simplemente quita el campo eso_actividad (Codigo del curso) para que aun asi siga asignado al programa
        // 1310	SIN SALON
        // 1311	PRACTICAS EXTERNAS
        // 1312	PRACTICAS HOSPITAL
        if ($EspCodigo == 1310 || $EspCodigo == 1311 || $EspCodigo == 1312) {
            $sql = "DELETE FROM 
                espacio_ocupacion
            WHERE
                eso_actividad = {$CurCodigo}
				and esp_codigo = {$EspCodigo}
                and uap_codigo = {$UapCodigo}
                and dia_codigo = {$DiaCodigo}
				and hra_codigo = {$HraCodigo}
                and eso_subgrupo = '{$EsoSubGrupo}'
            ";

            if (!$this->cnx->sentencia($sql)) {
                $this->errorSentenciaBd["mensaje"] = "Error al eliminar el horario seleccionado.";
                $this->errorSentenciaBd["consola"] = "Ha fallado la eliminación del horario del curso: {$CurCodigo}, 
                espacio: {$EspCodigo}, dia: {$DiaCodigo}, hora: {$HraCodigo} y subgrupo: {$EsoSubGrupo}.";
                return $this->errorSentenciaBd;
            }

            $sql = "DELETE FROM 
                espacio_ocupacion_historico
            WHERE
                eso_actividad = {$CurCodigo}
				and esp_codigo = {$EspCodigo}
                and uap_codigo = {$UapCodigo}
                and dia_codigo = {$DiaCodigo}
				and hra_codigo = {$HraCodigo}
                and eso_subgrupo = '{$EsoSubGrupo}'
            ";

            if (!$this->cnx->sentencia($sql)) {
                $this->errorSentenciaBd["mensaje"] = "Error al eliminar el horario seleccionado.";
                $this->errorSentenciaBd["consola"] = "Ha fallado la eliminación del horario historico del curso: {$CurCodigo}, 
                espacio: {$EspCodigo}, dia: {$DiaCodigo}, hora: {$HraCodigo} y subgrupo: {$EsoSubGrupo}.";
                return $this->errorSentenciaBd;
            }
        } else {
            $sql = "UPDATE
                espacio_ocupacion
            SET
                eso_actividad = NULL, 
                uap_codigo = NULL, 
                eso_subgrupo = NULL 
            WHERE
                eso_actividad = {$CurCodigo}
				and esp_codigo = {$EspCodigo}
                and uap_codigo = {$UapCodigo}
                and dia_codigo = {$DiaCodigo}
				and hra_codigo = {$HraCodigo}
                and eso_subgrupo = '{$EsoSubGrupo}'
            ";

            if (!$this->cnx->sentencia($sql)) {
                $this->errorSentenciaBd["mensaje"] = "Error al eliminar el horario seleccionado.";
                $this->errorSentenciaBd["consola"] = "Ha fallado la eliminación del horario del curso: {$CurCodigo}, 
                espacio: {$EspCodigo}, dia: {$DiaCodigo}, hora: {$HraCodigo} y subgrupo: {$EsoSubGrupo}.";
                return $this->errorSentenciaBd;
            }

            $sql = "UPDATE
                espacio_ocupacion_historico
            SET
                eso_actividad = NULL, 
                uap_codigo = NULL, 
                eso_subgrupo = NULL 
            WHERE
                eso_actividad = {$CurCodigo}
				and esp_codigo = {$EspCodigo}
                and uap_codigo = {$UapCodigo}
                and dia_codigo = {$DiaCodigo}
				and hra_codigo = {$HraCodigo}
                and eso_subgrupo = '{$EsoSubGrupo}'
            ";

            if (!$this->cnx->sentencia($sql)) {
                $mensaje = "El historico no se pudo actualizar.";
                // $this->errorSentenciaBd["mensaje"] = "Error al eliminar el horario seleccionado.";
                // $this->errorSentenciaBd["consola"] = "Ha fallado la eliminación del horario historico del curso: {$CurCodigo}, 
                // espacio: {$EspCodigo}, dia: {$DiaCodigo}, hora: {$HraCodigo} y subgrupo: {$EsoSubGrupo}.";
                // return $this->errorSentenciaBd;

            }
        }

        //Validamos si el curso tiene subgrupos y en caso tal evalua que tenga matriculados, en caso de no tener desactiva el cupo_curso_subgrupo.
        $eliminacionSubgrupoSinHorario = $this->inactivarSubgrupoSinHorario($CurCodigo);
        if (!$eliminacionSubgrupoSinHorario) {
            $this->errorSentenciaBd["mensaje"] = "Error al desactivar subgrupos del curso {$CurCodigo}.";
            $this->errorSentenciaBd["consola"] = "Ha fallado la desactivación de los subgrupos del curso: {$CurCodigo}.";
            return $this->errorSentenciaBd;
        }

        //Recalculamos la agenda del curso especifico.
        $actualizarAgenda = $this->actualizarAgenda($CurCodigo);
        if (!$actualizarAgenda) {
            $this->errorSentenciaBd["mensaje"] = "Error al actualizar la agenda del curso {$CurCodigo}.";
            $this->errorSentenciaBd["consola"] = "Ha fallado la actualización de la agenda del curso: {$CurCodigo}.";
            return $this->errorSentenciaBd;
        }

        return array(
            "resultado" => true,
            "mensaje" => 'Horario eliminado correctamente, la agenda se actualizó correctamente.',
            "consola" => $mensaje,
            "CurCodigo" => $CurCodigo
        );
    }

    //Inicio funcion consultarHorario
    //Permite consultar el horario de un curso especifico
    function consultarHorario($obj)
    {
        //Validaciones
        if (!isset($obj->CurCodigo) || !is_numeric($obj->CurCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo del curso.",
                "consola" => "El codigo del curso no es numérico o no se envio correctamente.",
            );
        }
        //Parametros
        $CurCodigo = $obj->CurCodigo; //Contiene del curso especifico para consultar su horario.

        $sql = "SELECT 
            eso.eso_actividad CurCodigo, 
            eso.esp_codigo EspCodigo, 
            eso.uap_codigo UapCodigo,
            eso.dia_codigo DiaCodigo, 
            eso.hra_codigo HraCodigo,
            eso.eso_subgrupo EsoSubGrupo,
            uaa.uaa_codigo UaaCodigo, 
            uaa.uaa_nombre_corto UaaNombreCorto, 
            per.per_nombre + ' ' + per.per_apellido NombreApellidoDocente,
            CONVERT(char(10),min(eso.eso_fecha),23) EsoFechaInicio,
            CONVERT(char(10),max(eso.eso_fecha),23) EsoFechaFin,  
            (datediff(ww,min(eso.eso_fecha),max(eso.eso_fecha))+1) EsoSemanas,
            dia.dia_nombre DiaNombre, 
            hora.hra_nombre + '. ' + hora.hra_inicio + ' - ' + hora.hra_fin EsoHora,
            esp.esp_nombre_corto  EspNombreCorto,
            vin.vin_nombre VinNombre, 
            ded.ded_nombre DedNombre,
            ccs.cus_cupo CupoSubgrupo
        from 
            espacio_ocupacion_total eso 
        inner join uaa on uaa.uaa_codigo = eso.uaa_codigo
        inner join uaa_personal uap on uap.uap_codigo = eso.uap_codigo
        inner join persona per on per.per_codigo = uap.per_codigo
        inner join dia on dia.dia_codigo = eso.dia_codigo 
        inner join hora on hora.hra_codigo = eso.hra_codigo
        inner join espacio esp on esp.esp_codigo = eso.esp_codigo
        inner join vinculacion vin on vin.vin_codigo = uap.vin_codigo 
        inner join dedicacion ded on ded.ded_codigo = uap.ded_codigo
        left join curso_cupo_subgrupo ccs on eso.eso_actividad = ccs.cur_codigo and ccs.eso_subgrupo = eso.eso_subgrupo and ccs.cus_estado = 1
        where 
            eso.eso_actividad = {$CurCodigo}
        group by 
            eso.eso_actividad,
            eso.esp_codigo, 
            eso.uap_codigo, 
            eso.dia_codigo,
            eso.hra_codigo,
            eso.eso_subgrupo, 
            uaa.uaa_codigo, 
            uaa.uaa_nombre_corto, 
            per_nombre + ' ' + per_apellido,
            dia.dia_nombre, 
            hora.hra_nombre + '. ' + hora.hra_inicio + ' - ' + hora.hra_fin, 
            esp.esp_nombre_corto,
            vin.vin_nombre, 
            ded.ded_nombre,
            ccs.cus_cupo
        order by eso.eso_subgrupo, per.per_nombre + ' ' + per.per_apellido, eso.dia_codigo, eso.hra_codigo ASC";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar el horario del curso.";
            return $this->errorConsultarBd;
        }

        return array(
            "resultado" => true,
            "mensaje" => "Horario del curso {$CurCodigo} consultado correctamente.",
            "data" => $this->cnx->json
        );
    }
}
