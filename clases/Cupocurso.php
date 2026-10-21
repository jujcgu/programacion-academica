<?php
date_default_timezone_set('America/Bogota');
require_once(dirname(__FILE__) . '/servicios/PermisoCurso.php');
class Cupocurso
{
    // Gabela sobre el aforo del salón para Cupo Total + Reserva (cur_cupo + cur_ampliacion_cupo).
    // Único lugar donde se define este valor: para cambiarlo, solo se debe modificar esta constante.
    const GABELA_CUPO_AFORO = 5;

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

    // Función que expone la gabela de aforo para que otras clases (Curcrea, Curhorario)
    // y, vía logica/cupocurso.php, el frontend, la consulten en lugar de duplicar el valor.
    public static function obtenerGabelaCupoAforo()
    {
        return self::GABELA_CUPO_AFORO;
    }

    public static function calcularLimiteConGabela($aforoMaximo)
    {
        return $aforoMaximo !== null ? intval($aforoMaximo) + self::obtenerGabelaCupoAforo() : null;
    }

    // Consulta expuesta al frontend (logica/cupocurso.php) para obtener la gabela vigente
    // sin duplicar el número en JavaScript.
    public function consultarGabelaCupoAforo($obj)
    {
        return array(
            "resultado" => true,
            "data" => self::obtenerGabelaCupoAforo()
        );
    }

    private function consultarAforoMaximoSubgrupo($curCodigo, $subGrupo)
    {
        $espaciosSinRestriccionAforo = "1310,1311,1312";

        $sql = "SELECT TOP 1 1 Existe
            FROM espacio_ocupacion eo
            WHERE
                eo.eso_actividad = {$curCodigo}
                AND eo.eso_subgrupo = '{$subGrupo}'
                AND eo.esp_codigo IN ({$espaciosSinRestriccionAforo})";

        if (!$this->cnx->consultar($sql)) {
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
                AND ISNULL(esp.esp_capacidad, 0) > 0
        ) aforo";

        if (!$this->cnx->consultar($sql)) {
            return array(
                "resultado" => false,
                "mensaje" => "Error al consultar el aforo máximo del subgrupo.",
                "consola" => "No fue posible consultar el aforo del curso {$curCodigo} subgrupo {$subGrupo}."
            );
        }

        $resultado = $this->cnx->json;
        $aforoMaximo = null;

        if (count($resultado) > 0 && $resultado[0]['AforoMaximo'] !== null) {
            $aforoMaximo = intval($resultado[0]['AforoMaximo']);
            if ($aforoMaximo <= 0) {
                $aforoMaximo = null;
            }
        }

        return array(
            "resultado" => true,
            "aforoMaximo" => $aforoMaximo,
            "restriccionAforo" => true
        );
    }


    //Inicio la actualizacion del cupo y/o ampliacion de un curso.
    //Se usa para actualizar el cupo y/o la ampliacion de un curso especifico
    //Parametros: se recibe un objeto que debe contener el codigo del curso, el cupo y la ampliacion.
    //Codigo del curso: $obj->CurCodigo
    //Cupo del curso: $obj->CurCupo
    //Ampliacion del curso:  $obj->CurAmpliacion
    //Retorna un objeto con respuesta true o false, mensaje de error y mensaje de consola.
    public function actualizarCupoCurso($obj)
    {
        // Validamos las variables recibidas que exista y que sea numerico
        if (!isset($obj->CurCodigo) || !is_numeric($obj->CurCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo del curso",
                "consola" => "El codigo del curso no viene o no es numerico, " . $obj->CurCodigo,
            );
        }

        if (!isset($obj->CurCupo) || !is_numeric($obj->CurCupo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el cupo del curso",
                "consola" => "El cupo del curso no viene o no es numerico, " . $obj->CurCupo,
            );
        }
        if (intval($obj->CurCupo) < 0) {
            return array(
                "resultado" => false,
                "mensaje" => ("El cupo debe ser un número mayor o igual a 0."),
            );
        }

        if (!isset($obj->CurAmpliacion) || !is_numeric($obj->CurAmpliacion)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el cupo del curso",
                "consola" => "El cupo del curso no viene o no es numerico, " . $obj->CurAmpliacion,
            );
        }
        if (intval($obj->CurAmpliacion) < 0) {
            return array(
                "resultado" => false,
                "mensaje" => ("El cupo debe ser un número mayor o igual a 0."),
            );
        }

        $CurCodigo = $obj->CurCodigo; //Almacenamos el codigo del curso
        $CurCupo = $obj->CurCupo; //Almacenamos el cupo del curso
        $CurAmpliacion = $obj->CurAmpliacion; //Almacenamos el la ampliacion del curso

        $aforoSubgrupoTeoria = $this->consultarAforoMaximoSubgrupo($CurCodigo, '00');
        if (!$aforoSubgrupoTeoria['resultado']) {
            return $aforoSubgrupoTeoria;
        }

        $aforoMaximo = $aforoSubgrupoTeoria['aforoMaximo'];
        $sumaCupoYReserva = intval($CurCupo) + intval($CurAmpliacion);
        $limiteConGabela = self::calcularLimiteConGabela($aforoMaximo);

        if ($limiteConGabela !== null && $sumaCupoYReserva > $limiteConGabela) {
            return array(
                "resultado" => false,
                "mensaje" => "No se puede guardar el cambio porque el total de cupos supera la capacidad permitida del salón.",
                "consola" => "Validación de aforo no superada. Curso {$CurCodigo}, cupo {$CurCupo}, reserva {$CurAmpliacion}, suma {$sumaCupoYReserva}, aforo {$aforoMaximo}, limite {$limiteConGabela}.",
                "AforoMaximo" => $aforoMaximo,
                "LimiteConGabela" => $limiteConGabela,
                "SumaCupoReserva" => $sumaCupoYReserva
            );
        }



        $sql = "UPDATE
            curso
        SET
            cur_cupo = {$CurCupo},
            cur_ampliacion_cupo = {$CurAmpliacion},
            cur_fecha_actualizacion = GETDATE()
        where
            cur_codigo = {$CurCodigo} ";

        if (!$this->cnx->sentencia($sql)) {
            $this->errorSentenciaBd["mensaje"] = "Error al modificar cupo y/o ampliación del curso.
				Consulte de nuevo.";
            $this->errorSentenciaBd["consola"] = "Ha fallado update en cupo y/o ampliación del curso.";
            // $this->errorSentenciaBd["sql"] = $sql;
            return $this->errorSentenciaBd;
        }

        $salida = array(
            "resultado" => true,
            "mensaje" => "Los cupos del curso se actualizaron correctamente",
            "consola" => "",
            "AforoMaximo" => $aforoMaximo,
            "LimiteConGabela" => $limiteConGabela,
            "CurCupoAplicado" => intval($CurCupo),
            "CurAmpliacionAplicado" => intval($CurAmpliacion),
            "SumaCupoReserva" => intval($CurCupo) + intval($CurAmpliacion),
        );

        if ($limiteConGabela !== null) {
            $salida['mensaje'] .= ". Capacidad del salón: {$aforoMaximo}.";
            $salida['mensaje'] .= " Máximo permitido en total (incluyendo reserva): {$limiteConGabela}.";
        } else {
            $salida['mensaje'] .= ". Este curso está en aula externa (o en un espacio sin capacidad), por eso no se aplica límite por aforo en esta validación.";
        }

        return $salida;
    } //fin actualizacion del cupo y/o ampliacion


    //inicio consulta estudiantes matriculados de un curso y/o subgrupo
    //Se usa para consultar los estudiantes matriculados de un curso y/o subgrupo
    //Parametros: se recibe un objeto que debe contener el codigo del curso y el subgrupo
    //Codigo del curso: $obj->CurCodigo
    //Subgrupo: $obj->SubGrupo Si no viene ningun subgrupo se inicializa con 00
    //Retorna una lista de los estudiantes mastriculados de un curso y/o subgrupo
    public function consultarEstudiantesMatriculados($obj)
    {
        if (!isset($obj->CurCodigo) || !is_numeric($obj->CurCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe elegir el número del curso",
                "consola" => "El codigo del curso no es numerico o no hay numero",
            );
        }

        if (!isset($obj->SubGrupo) || !is_numeric($obj->SubGrupo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe elegir el número del subgrupo",
                "consola" => "El subgrupo no es numerico o no hay numero",
            );
        }



        $curCodigo = $obj->CurCodigo;
        $subGrupo = $obj->SubGrupo;
        //$calendariosString = $this->consultarCalendarioActivo(); //consultamos los calendarios activos
        //Quitamos el calendario para que muestre los matriculados sin tener en cuenta el calendario activo.
        //where  mc.maa_codigo in(1,2) and m.cal_codigo in ({$calendariosString})

        if ($subGrupo == "00") {
            $sqlSubgrupo = "  ";
        }
        if ($subGrupo != "00") {
            $sqlSubgrupo = " and mc.mac_subgrupo='{$subGrupo}' ";
        }

        $sql = "SELECT e.est_codigo EstCodigo, pe.per_identificacion PerIdentificacion,
		pe.per_nombre+' '+pe.per_apellido as PerNombre,
		u.uaa_nombre_corto UaaNombreCorto,	mc.mac_subgrupo MacGrupo, maz.maa_nombre MaaNombre, maz.maa_codigo MaaCodigo,
        (
            select top 1 aud_changed from aud_matricula_curso aud where aud.mac_codigo = mc.mac_codigo and aud.maa_codigo = maz.maa_codigo order by aud_codigo_mat_curso desc
        ) MaaFecha
		from matricula m
		inner join estudiante e on (m.est_codigo=e.est_codigo)
		inner join programa p on (p.pro_codigo=e.pro_codigo)
		inner join persona pe on (pe.per_codigo=e.per_codigo)
		inner join matricula_curso mc on (m.mat_codigo=mc.mat_codigo)
        inner join matricula_autorizacion maz on maz.maa_codigo = mc.maa_codigo and maz.maa_codigo != 5
		inner join uaa u on (u.uaa_codigo=p.uaa_codigo)
		where  mc.cur_codigo={$curCodigo} 
		{$sqlSubgrupo}
		order by MaaFecha, mc.mac_subgrupo asc, pe.per_nombre asc
		";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "consultarEstudiantesMatriculados .68";
            return $this->errorConsultarBd;
        }

        $result = $this->cnx->json;

        if (count($result) == 0) {
            return array(
                "resultado" => false,
                "mensaje" => utf8_encode("No hay estudiantes matriculados."),
                "consola" => "",
            );
        }

        return array(
            "resultado" => true,
            "mensaje" => "Matriculados consultados correctamente.",
            "data" => $result
        );
    } //fin consulta estudiantes matriculados

    //inicio actualizacion cupo subgrupo
    //Se usa para actualizar el cupo de un determinado subgrupo
    //Parametros: se recibe un objeto que debe contener el codigo del subgrupo cus_codigo y el nuevo cupo del subgrupo
    //Codigo del sub grupo: $obj->CusCodigo
    //Cupo del sub grupo: $obj->CurCodigo
    //Retorna una confirmacion de proceso realizado.
    public function actualizarCupoSubgrupo($obj)
    {
        // Validamos las variables recibidas que exista y que sea numerico
        if (!isset($obj->CusCodigo) || !is_numeric($obj->CusCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo del subgrupo",
                "consola" => "El codigo del subgrupo no viene o no es numerico, " . $obj->CusCodigo,
            );
        }

        if (!isset($obj->CusCupo) || !is_numeric($obj->CusCupo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el cupo del subgrupo",
                "consola" => "El cupo del subgrupo no viene o no es numerico, " . $obj->CusCupo,
            );
        }

        if (intval($obj->CusCupo) < 0) {
            return array(
                "resultado" => false,
                "mensaje" => ("El cupo debe ser un número mayor o igual a 0."),
            );
        }

        $cusCodigo = $obj->CusCodigo; //Almacenamos el codigo del subgrupo
        $cusCupo = $obj->CusCupo; //Almacenamos el cupo del subgrupo

        $sql = "SELECT cur_codigo CurCodigo, eso_subgrupo SubGrupo
            FROM curso_cupo_subgrupo
            WHERE cus_cod = {$cusCodigo}";
        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar el curso/subgrupo del cupo a actualizar.";
            return $this->errorConsultarBd;
        }

        $r_subgrupo = $this->cnx->json;
        if (count($r_subgrupo) < 1) {
            return array(
                "resultado" => false,
                "mensaje" => "No se encontró el subgrupo a actualizar.",
                "consola" => "No existe curso_cupo_subgrupo para cus_cod {$cusCodigo}."
            );
        }

        $CurCodigo = $r_subgrupo[0]['CurCodigo'];
        $SubGrupo = $r_subgrupo[0]['SubGrupo'];

        $aforoSubgrupo = $this->consultarAforoMaximoSubgrupo($CurCodigo, $SubGrupo);
        if (!$aforoSubgrupo['resultado']) {
            return $aforoSubgrupo;
        }

        $aforoMaximo = $aforoSubgrupo['aforoMaximo'];
        $seAjustoCupo = false;

        if ($aforoMaximo !== null && intval($aforoMaximo) > 0 && intval($cusCupo) > intval($aforoMaximo)) {
            $cusCupo = $aforoMaximo;
            $seAjustoCupo = true;
        }



        $sql = "UPDATE curso_cupo_subgrupo SET
			cus_cupo = {$cusCupo}
		WHERE
			cus_cod = {$cusCodigo} ";

        if (!$this->cnx->Sentencia($sql)) {
            $this->errorSentenciaBd["mensaje"] = "Error al modificar cupo del subgrupo.
				Consulte de nuevo.";
            $this->errorSentenciaBd["consola"] = "Ha fallado update en cupo subgrupo";
            return $this->errorSentenciaBd;
        }

        $salida = array(
            "resultado" => true,
            "mensaje" => "Cupo del subgrupo modificado con éxito",
            "consola" => "",
            "AforoMaximo" => $aforoMaximo,
            "CusCupoAplicado" => intval($cusCupo),
            "CupoAjustadoAutomaticamente" => $seAjustoCupo,
        );

        if ($aforoMaximo !== null) {
            if ($seAjustoCupo) {
                $salida['mensaje'] .= ". El aforo máximo permitido para el subgrupo {$SubGrupo} es {$aforoMaximo}. Se ajustó automáticamente el cupo.";
            } else {
                $salida['mensaje'] .= ". Aforo máximo permitido para el subgrupo {$SubGrupo}: {$aforoMaximo}.";
            }
        } else {
            $salida['mensaje'] .= ". No hay espacios con aforo configurado para el subgrupo {$SubGrupo}.";
        }

        return $salida;
    } //fin actualizacion cupo subgrupo

    //inicio consulta general de calendario activo
    //Se usa para consultar el calendario activo al momento de realizar la programacion academica
    //Retorna un string con los codigos de los calendarios dividitos por ,
    public function consultarCalendarioActivoProgramacion()
    {

        $today = date("Y-m-d");
        $hora = date("H:i:s");

        //Obtenemos los calendarios activos para gestion, de las unidades del usuario logueado
        $sql = "SELECT pra.cal_codigo CalCodigo, pra.uaa_codigo UaaCodigo
        FROM programacionacademica.programacion_academica pra
        WHERE 
            pra.uaa_codigo IN ({$_SESSION['pacademica']['datosVinculacionUsuario']['unidades']}) AND
            pra.pra_estado = 1 AND pra.prp_codigo != 4 AND
            '{$today}T{$hora}' BETWEEN pra.pra_fecha_inicio AND pra.pra_fecha_fin
        ";

        // echo $sql;

        //verificamos que la se pueda realizar la consulta
        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error en consultar los calendarios activos.";
            return $this->errorConsultarBd;
        }

        $r_calendarios = $this->cnx->json; //almacenamos la respuesta
        $calendariosArray = array(); //array para almacenar la respuesta
        $i = 0;

        //Recorremos las aperturas de calendarios de gestion.
        foreach ($r_calendarios as $fila) {
            $array = [
                "CalCodigo" => $fila["CalCodigo"],
                "UaaCodigo" => $fila["UaaCodigo"]
            ];
            $calendariosArray[$i] = array_map('utf8_encode', $array);
            $i++;
        }

        return $calendariosArray;
    }

    //inicio consulta general de calendario activo
    //Se usa para consultar el calendario activo al momento de realizar la programacion academica
    //Retorna un string con los codigos de los calendarios dividitos por ,
    public function consultarCalendarioActivo()
    {

        $today = date("Y-m-d");
        $hora = date("H:i:s");

        //Obtenemos los calendarios activos para gestion, de las unidades del usuario logueado
        $sql = "SELECT prg.cal_codigo CalCodigo, prg.uaa_codigo UaaCodigo
        FROM programacionacademica.programacion_gestion prg
        WHERE 
            prg.uaa_codigo IN ({$_SESSION['pacademica']['datosVinculacionUsuario']['unidades']}) AND
            prg.pts_codigo = 1 AND
            prg.prg_estado = 1 AND
            '{$today}T{$hora}' BETWEEN prg.prg_fecha_inicio AND prg.prg_fecha_fin
        ";

        //verificamos que la se pueda realizar la consulta
        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error en consultar los calendarios activos.";
            return $this->errorConsultarBd;
        }

        $r_calendarios = $this->cnx->json; //almacenamos la respuesta
        $calendariosArray = array(); //array para almacenar la respuesta
        $i = 0;

        //Recorremos las aperturas de calendarios de gestion.
        foreach ($r_calendarios as $fila) {
            $array = [
                "CalCodigo" => $fila["CalCodigo"],
                "UaaCodigo" => $fila["UaaCodigo"]
            ];
            $calendariosArray[$i] = array_map('utf8_encode', $array);
            $i++;
        }

        return $calendariosArray;
    }
    //fin consulta general de calendario activo

    //inicio consulta gneral de curso
    //Se usa para buscar un curso por su codigo curso.cur_codigo.
    //Recibe como parametro un objeto que debe contener el codigo del curso
    //Codigo del curso: $obj->CurCodigo
    //Retorna un objeto con 3 posiciones.
    //    0. Informacion del curso.
    //    1. Informacion del creador.
    //    2. Array de los subgrupos que contiene un curso.
    public function consultarCurso($obj)
    {
        // Validamos las variables recibidas que exista y que sea numerico
        if (!isset($obj->curCodigo) || !is_numeric($obj->curCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe ingresar el número del curso",
                "consola" => "No es numerico o no hay número",
            );
        }



        $uaasPerfil = $_SESSION['pacademica']['datosVinculacionUsuario']['unidades']; //obtenemos las uaas del perfil
        $uid = $_SESSION['pacademica']['datosVinculacionUsuario']['usuarioCodigo']; //obtenemos el id del usuario
        $curso = $obj->curCodigo; //obtenemos el codigo del curso
        $calendariosArray = $this->consultarCalendarioActivo(); //consultamos los calendarios activos
        $calendariosArrayProgramacion = $this->consultarCalendarioActivoProgramacion(); //consultamos los calendarios activos para programacion academica
        $apertura_gestion_permitida = false;
        $apertura_programacion_permitida = false;

        //validamos si el usuario logueado es administrador
        if ($_SESSION['pacademica']['datosVinculacionUsuario']['grupoId'] == 'PROGRAMACION_ACADEMICA_ADMINISTRADOR') {
            //consultamos el curso directamente
            $sql = "SELECT
                asi.asi_codigo AsiNombre,
                asi.asi_nombre_corto AsiNombreCorto,
                cur.cal_codigo CalCodigo
			FROM curso cur
			INNER JOIN asignatura asi ON asi.asi_codigo=cur.asi_codigo
			WHERE cur.cur_codigo = {$curso} ";
        } else {
            //=================================================================================
            //2022-01-31 Douglas Plazas, esta query permitia editar cursos del plan academico pero se incluia los institucionales, validando con vicerectoria
            //Solo los propietarios pueden editar sus cursos.
            //saca si la asignatura es de un plan del usuario
            // SELECT asi.asi_codigo AsiCodigo, 
            // asi.asi_nombre_corto AsiNombreCorto, --saca si la asignatura es de un plan del usuario
            // cur.cal_codigo CalCodigo
            // FROM plan_academico pla
            // INNER JOIN programa pro ON pro.pro_codigo=pla.pro_codigo
            // INNER JOIN uaa uaa ON uaa.uaa_codigo=pro.uaa_codigo
            // INNER JOIN plan_academico_asignatura paa ON paa.pla_codigo=pla.pla_codigo
            // INNER JOIN asignatura asi ON asi.asi_codigo=paa.asi_codigo
            // INNER JOIN curso cur ON cur.asi_codigo=asi.asi_codigo
            // WHERE uaa.uaa_codigo in ({$uaasPerfil}) AND
            //     cur.cur_codigo = {$curso} and
            //     pla.pla_estado=1
            //=================================================================================

            $permisoCurso = new PermisoCurso();
            $sql = $permisoCurso->construirSqlPermisoCurso($curso, $uaasPerfil, $uid, $_SESSION['pacademica']['ROLES']['SECRETARIA']);
        }
        //veriricamos que la consulta del curso se pueda realizar
        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error en consulta validar permiso sobre el curso.";
            // $this->errorConsultarBd["sql"] = $sql;
            return $this->errorConsultarBd;
        }

        $r_curso = $this->cnx->json;

        //si no encuentra nada, porque no es dueno o no es permitido modificar
        if (count($r_curso) < 1) {
            //--------- buscar los datos basicos del curso ----------//
            //por si la persona que busca no tiene permiso de modificar
            //mostrarle solo el nombre, calendario y programa
            $sql = "SELECT cur.cur_codigo CurCodigo, asi.asi_nombre AsiNombre,
			uaa.uaa_nombre_corto UaaNombreCorto, cal.cal_nombre CalNombre
			from curso cur
			inner join asignatura asi on cur.asi_codigo=asi.asi_codigo
			inner join uaa uaa on asi.uaa_codigo = uaa.uaa_codigo
			inner join calendario cal on cal.cal_codigo=cur.cal_codigo
			where cur.cur_codigo={$curso} ";
            if (!$this->cnx->consultar($sql)) {
                $this->errorConsultarBd["consola"] = "Error en consulta buscar curso datos basicos para el que no es dueño";
                return $this->errorConsultarBd;
            }
            $r_curso_alt = $this->cnx->json;
            if (count($r_curso_alt) > 0) {
                $datosBasicosCurso = "" . $r_curso_alt[0]['AsiNombre'] . " - " . $r_curso_alt[0]['UaaNombreCorto'];
                $datosBasicosCurso .= " - " . $r_curso_alt[0]['CalNombre'];
                return array(
                    "resultado" => false,
                    "mensaje" => "Curso no es permitido modificarlo. " . $datosBasicosCurso,
                    "consola" => "El curso no es de la facultad del usuario " . $datosBasicosCurso
                );
            } else {
                return array(
                    "resultado" => false,
                    "mensaje" => "Curso no encontrado. ",
                    "consola" => "El curso no fue encontrado."
                );
            }
        } //---------- fin datos basicos ----------------------//

        //busca los datos completos del curso
        $sql = "SELECT cur.cur_codigo CurCodigo, cur.cal_codigo CalCodigo, cal.cal_nombre CalNombre, cur.cur_estado CurEstado, asi.asi_codigo AsiCodigo, asi.asi_nombre AsiNombre, asi.asi_nombre_corto AsiNombreCorto,
		cur.cur_grupo CurGrupo, asi.nuc_codigo NucCodigo, nuc.nuc_nombre NucNombre, nuc.nuc_acronimo NucAcronimo,
		cur.cur_cupo CurCupo, cur.cur_ampliacion_cupo CurAmpliacion,  uaa.uaa_nombre_corto UaaNombreCorto, uaa.uaa_codigo UaaCodigo,
		sed.sed_codigo SedCodigo, sed.sed_nombre SedNombre, (
            SELECT count(*) as matriculados_curso
            from matricula_curso mc
            inner join matricula ma on (mc.mat_codigo=ma.mat_codigo)
            where mc.cur_codigo={$curso} and mc.maa_codigo in (1,2)
        ) totalMatriculados,
        (
            SELECT top 1 uaa_codigo
            FROM espacio_ocupacion
            WHERE eso_actividad = {$curso}
        ) UaaProgramada,
        (
            SELECT
                CASE
                    WHEN EXISTS (
                        SELECT 1
                        FROM espacio_ocupacion eo_ext
                        WHERE
                            eo_ext.eso_actividad = cur.cur_codigo
                            AND eo_ext.eso_subgrupo = '00'
                            AND eo_ext.esp_codigo IN (1310,1311,1312)
                    ) THEN NULL
                    ELSE (
                        SELECT
                            MIN(aforo.esp_capacidad)
                        FROM (
                            SELECT DISTINCT
                                eo.esp_codigo,
                                ISNULL(esp.esp_capacidad, 0) esp_capacidad
                            FROM espacio_ocupacion eo
                            INNER JOIN espacio esp ON esp.esp_codigo = eo.esp_codigo
                            WHERE
                                eo.eso_actividad = cur.cur_codigo
                                AND eo.eso_subgrupo = '00'
                                AND eo.esp_codigo NOT IN (1310,1311,1312)
                                AND ISNULL(esp.esp_capacidad, 0) > 0
                        ) aforo
                    )
                END
        ) AforoMaximoTeoria,
        per.per_nombre + ' ' + per.per_apellido PerNombreApellido
		from curso cur
		inner join asignatura asi on (cur.asi_codigo=asi.asi_codigo)
		inner join nucleo nuc on (nuc.nuc_codigo=asi.nuc_codigo)
		inner join uaa uaa on (asi.uaa_codigo = uaa.uaa_codigo)
		inner join sede sed on (sed.sed_codigo = cur.sed_codigo)
        inner join calendario cal on cal.cal_codigo = cur.cal_codigo
        inner join uaa_personal uap on uap.uap_codigo = cur.uap_codigo
        inner join persona per on per.per_codigo = uap.per_codigo
		where cur.cur_codigo={$curso}";

        if (!$this->cnx->Consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error en consulta buscar curso";
            return $this->errorConsultarBd;
        }

        $result = $this->cnx->json;

        //Verificamos que el curso este en un calendario abierto para el programa
        //Se valida contra la UAA propia del curso (UaaCodigo) o, si ya tiene espacio
        //asignado, contra la UAA del espacio programado (UaaProgramada). UaaProgramada
        //viene null cuando el curso aun no tiene salon asignado en espacio_ocupacion,
        //y en cursos interfacultades UaaCodigo y UaaProgramada pueden ser UAAs distintas
        //que abren calendario de gestion por separado.
        foreach ($calendariosArray as $calendario) {
            if ($calendario['UaaCodigo'] == $result[0]['UaaCodigo'] || $calendario['UaaCodigo'] == $result[0]['UaaProgramada']) {
                $apertura_gestion_permitida = true;
            }
        }

        //Verificamos que el curso este en un calendario abierto para la programacion academica
        foreach ($calendariosArrayProgramacion as $calendario) {
            if ($calendario['CalCodigo'] == $result[0]['CalCodigo'] && $calendario['UaaCodigo'] == $result[0]['UaaProgramada']) {
                $apertura_programacion_permitida = true;
            }
        }

        if ($_SESSION['pacademica']['datosVinculacionUsuario']['grupoId'] == 'PROGRAMACION_ACADEMICA_ADMINISTRADOR') {
            $apertura_gestion_permitida = true;
            $apertura_programacion_permitida = true;
        }

        //Creamos un array donde vamos a organizar la respuesta dividida en 3.
        //0. Respuesta del curso
        //1. Respuesta del creador consultarCreadorCurso();
        $array_final = array();

        $array_final = $result; //Almacenamos en el array final la informacion del curso en la poscion 0

        $creador = $this->consultarCreadorCurso($obj); //Almacenamos la peticion del creador del curso, recibe como parametro un objeto que contenga la variable curCodigo
        $array = [ //Organizamos un array con el creador
            "CursoCreador" => $creador,
        ];
        $array_final[1] = array_map('utf8_encode', $array); //Almacenamos en el array final el creador en la posicion 1
        $creador = $this->consultarCreadorCurso($obj); //Almacenamos la peticion del creador del curso, recibe como parametro un objeto que contenga la variable curCodigo

        return array(
            "resultado" => true,
            "mensaje" => "Curso y creador consultado correctamente",
            "PermitidoEditar" => $apertura_gestion_permitida,
            "PermitidoProgramar" => $apertura_programacion_permitida,
            "data" => $array_final,
            "calendariosProgramacion" => $calendariosArrayProgramacion,
            "calendariosGestion" => $calendariosArray,
        );
    }
    //fin consultarCurso

    //inicio consulta subgrupos de un curso
    //Se usa para consultar los subgrupos de un curso identificado por su codigo cur_codigo
    //Recibe como parametro: un objeto que debe contener el codigo del curso y el codigo del calendario activo
    //Codigo del curso: $obj->CurCodigo
    //Codigo del calendario activo: $obj->calendariosActivos texto de codigos de calendarios dividido por ,
    //Retorna un array con los subgrupos del curso y calendario solicitado
    public function consultarSubgrupoCurso($obj)
    {



        // Validamos las variables recibidas que exista y que sea numerico
        if (!isset($obj->curCodigo) || !is_numeric($obj->curCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe ingresar el número del curso",
                "consola" => "No es numerico o no hay número",
            );
        }

        $curso = $obj->curCodigo; //obtenemos el codigo del curso
        //consultamos los calendarios activos
        //$calendariosString = $this->consultarCalendarioActivo(); 
        //and cur.cal_codigo in ({$calendariosString})

        $sql = "SELECT
			cus.cus_cod CusCodigo, cus.cur_codigo CurCodigo, cus.eso_subgrupo SubGrupo, cus.cus_cupo CusCupo,  (
			select count(*)
			from matricula_curso mc
			inner join matricula ma on (mc.mat_codigo=ma.mat_codigo)
			where ma.mat_estado='A' and mc.maa_codigo in (1,2)
			and mc.cur_codigo=cus.cur_codigo and mc.mac_subgrupo =cus.eso_subgrupo
        ) as CantMatriculados,
        (
            SELECT
                CASE
                    WHEN EXISTS (
                        SELECT 1
                        FROM espacio_ocupacion eo_ext
                        WHERE
                            eo_ext.eso_actividad = cus.cur_codigo
                            AND eo_ext.eso_subgrupo = cus.eso_subgrupo
                            AND eo_ext.esp_codigo IN (1310,1311,1312)
                    ) THEN NULL
                    ELSE (
                        SELECT
                            MIN(aforo.esp_capacidad)
                        FROM (
                            SELECT DISTINCT
                                eo.esp_codigo,
                                ISNULL(esp.esp_capacidad, 0) esp_capacidad
                            FROM espacio_ocupacion eo
                            INNER JOIN espacio esp ON esp.esp_codigo = eo.esp_codigo
                            WHERE
                                eo.eso_actividad = cus.cur_codigo
                                AND eo.eso_subgrupo = cus.eso_subgrupo
                                AND eo.esp_codigo NOT IN (1310,1311,1312)
                                AND ISNULL(esp.esp_capacidad, 0) > 0
                        ) aforo
                    )
                END
        ) AforoMaximoSubgrupo
		from curso_cupo_subgrupo cus
		inner join curso cur on (cur.cur_codigo=cus.cur_codigo)
		where cus.cur_codigo = {$curso} and cus.cus_estado = 1
		order by eso_subgrupo asc
		";

        //Se verifica que se ejecute la consulta
        if (!$this->cnx->Consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error en consulta buscar sub grupo del curso";
            return $this->errorConsultarBd;
        }

        //Se almacenan los registros
        $result = $this->cnx->json;

        return array(
            "resultado" => true,
            "mensaje" => "Sub grupos consultados correctamente.",
            "count" => count($result),
            "data" => $result
        );

        return $result;
    } //fin consultarSubgrupoCurso

    //inicio consulta creador del curso
    //Se usa para consultar el creador de un curso especifico
    //Recibe como parametro: un objeto que debe contener el codigo del curso $obj->CurCodigo
    //$obj->curCodigo
    //Retorna un string con el nombre completo de la persona creadora del curso
    public function consultarCreadorCurso($obj)
    {

        // Validamos las variables recibidas que exista y que sea numerico
        if (!isset($obj->curCodigo) || !is_numeric($obj->curCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe ingresar el número del curso",
                "consola" => "No es numerico o no hay número",
            );
        }

        $curso = $obj->curCodigo; //obtenemos el codigo del curso

        //Consultamos la persona que creo el curso, para eso se busca el primer insert de la tabla de auditoria
        $sql = "SELECT per.per_nombre+' '+per.per_apellido as persona
		from aud_curso cur
		inner join (
			select us, up, uid from usuario_administrativo
			union
			select us, up, uid from usuario_docente
		)as us on cur.usu_codigo=us.uid
		inner join persona per on us.up=per.per_codigo
		where cur.cur_codigo= {$curso} and cur.aud_log_type='INSERT' ";

        //veriricamos que la consulta del curso se pueda realizar
        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error en consulta del creador del curso.";
            return $this->errorConsultarBd;
        }

        $r_creador = $this->cnx->json; // Almacenamos en variable el resultado.

        return array(
            "resultado" => true,
            "mensaje" => "Se consulto el creador correctamente.",
            "data" => $r_creador[0]['persona'],
        );
    } //fin consultarCreadorCurso

}
