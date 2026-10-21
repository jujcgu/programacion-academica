<?php
date_default_timezone_set('America/Bogota');
require_once(dirname(__FILE__) . '/servicios/FechaSqlServer.php');
require_once(dirname(__FILE__) . '/servicios/PermisoCurso.php');
require_once(dirname(__FILE__) . '/Cupocurso.php');
class Curcrea
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
                "mensaje" => "La repesca no se puede seleccionar para gestion de cursos.",
                "consola" => "Se intento usar el proceso de repesca (prp_codigo 4) en Gestion Curso."
            );
        }

        return array("resultado" => true);
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
                "consola" => "No fue posible validar espacios especiales del curso {$curCodigo} para subgrupo {$subGrupo}."
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
                "mensaje" => "Error al consultar el aforo máximo del curso.",
                "consola" => "No fue posible consultar el aforo del curso {$curCodigo} para el subgrupo {$subGrupo}."
            );
        }

        $resultado = $this->cnx->json;
        $aforoMaximo = null;

        if (count($resultado) > 0 && $resultado[0]['AforoMaximo'] !== null) {
            $aforoMaximo = intval($resultado[0]['AforoMaximo']);
        }

        if ($aforoMaximo !== null && intval($aforoMaximo) <= 0) {
            $aforoMaximo = null;
        }

        return array(
            "resultado" => true,
            "aforoMaximo" => $aforoMaximo,
            "restriccionAforo" => $aforoMaximo !== null
        );
    }

    //Inicio funcion crearCurso
    //Permite crear curso especifico
    function crearCurso($obj)
    {
        //Validaciones
        if (!isset($obj->CalCodigo) || !is_numeric($obj->CalCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar un calendario.",
                "consola" => "El codigo del calendario no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->SedCodigo) || !is_numeric($obj->SedCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar una sede.",
                "consola" => "El codigo de la sede no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->CurNotaParcial)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar una nota parcial.",
                "consola" => "El codigo de la nota parcial no se envio correctamente.",
            );
        }
        if (!isset($obj->TicCodigo) || !is_numeric($obj->TicCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar una modalidad.",
                "consola" => "El codigo de la modalidad no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->CutCodigo) || !is_numeric($obj->CutCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar un tipo de cupo.",
                "consola" => "El codigo del tipo curso no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->TesCodigo) || !is_numeric($obj->TesCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar un tipo de calificación.",
                "consola" => "El codigo de la calificación no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->AsiCodigo) || !is_numeric($obj->AsiCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar una asignatura.",
                "consola" => "El codigo de la asignatura no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->PlaCodigo)) {
            $obj->PlaCodigo = 'NULL';
        }
        if (!isset($obj->CurCupo) || !is_numeric($obj->CurCupo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe ingresar un cupo.",
                "consola" => "El cupo no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->CurAmpliacionCupo) || !is_numeric($obj->CurAmpliacionCupo)) {
            $obj->CurAmpliacionCupo = 0;
        }
        if (!isset($obj->CurSemanas) || !is_numeric($obj->CurSemanas)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe ingresar el numero de semanas.",
                "consola" => "El número de semanas no es numérico o no se envio correctamente.",
            );
        }
        if ($obj->CurSemanas < 1 || $obj->CurSemanas > 18) {
            return array(
                "resultado" => false,
                "mensaje" => "El número de semanas no puede ser menor a 1 o mayor a 18."
            );
        }
        if (!isset($obj->CurExclusivo) || !is_numeric($obj->CurExclusivo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar la exclusividad del curso.",
                "consola" => "El codigo de exclusividad no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->UapCodigo) || !is_numeric($obj->UapCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar un docente coordinador.",
                "consola" => "El codigo de vinculación del docente no es numérico o no se envio correctamente.",
            );
        }

        if ($obj->CurExclusivo == 1) {
            // $array_temp = explode(',', $obj->PlanesExclusivos);
            if (count($obj->PlanesExclusivos) <= 0) {
                return array(
                    "resultado" => false,
                    "mensaje" => "Si el curso es exclusivo, debe seleccionar al menos un plan academico.",
                    "consola" => "No se encontraron planes academicos marcados como exclusividad.",
                );
            }
        }


        //Parametros
        $CalCodigo = $obj->CalCodigo; //Contiene el codigo del calendario
        $UaaCodigo = $obj->UaaCodigo; //Contiene el codigo de la uaa que va programar
        $SedCodigo = $obj->SedCodigo; //Contiene el codigo de la sede del curso
        $CurNotaParcial = trim($obj->CurNotaParcial); //Contiene el codigo de la nota parcial 'S'. Si, 'N'. No
        $TicCodigo = $obj->TicCodigo; //Contiene el codigo de la modalidad del curso 1. Pesencial, 2. Apoyo virtual (b-Learning), 3. Mixto
        $CutCodigo = utf8_decode($obj->CutCodigo); //Contiene el codigo del tipo de curso.
        $TesCodigo = $obj->TesCodigo; //Contiene el codigo del tipo de calificacion del curso 1. Numerico (0-5), 2. Aprobado/Reprobado, 3. Tres Niveles
        $CurEstado = 1; //Contiene el codigo del estado 0. Eliminado, 1. Activo
        $AsiCodigo = $obj->AsiCodigo; //Contiene el codigo de la asignatura seleccionada
        $PlaCodigo = $obj->PlaCodigo; //Contiene el plan academico de la asignatura seleccionada, puede ser vacio.
        $CurCupo = $obj->CurCupo; //Contiene el cupo del curso
        $CurAmpliacionCupo = $obj->CurAmpliacionCupo; //Contiene la ampliacion del cupo del curso, si viene vacia se establece en 0
        $CurSemanas = $obj->CurSemanas; //Contiene la cantidad de semanas del curso, debe ser entre 1 y 18, generalmente los posgrados programan 1 semana, los pregrados entre 16 y 18 semanas.
        $CurExclusivo = $obj->CurExclusivo; //Contiene si un curso es exclusivo 1. Si, 0. No.
        $PlanesExclusivos = $obj->PlanesExclusivos; //Contiene un array con los planes academicos seleccionados para exclusividad
        $UapCodigo = $obj->UapCodigo; //Contiene el codigo de vinculacion del docente coordinador.
        $VinNombre = $obj->VinNombre; //Contiene el tipo de vinculacion, se usa para hacer validacion de que la vinculacion seleccionada no tenga cursos cargados de otros calendarios.
        $CurUrl = utf8_decode(trim($obj->CurUrl)); //Contiene el link de para clases virtuales.
        $CurObservaciones = utf8_decode(trim($obj->CurObservaciones)); //Contiene observaciones del curso, generalmente se llena al momento de eliminar un curso o para reportar alguna novedad del curso.
        $CurGrupo = "01";

        //Se consulta al momento de crear el curso, el ultimo grupo creado 
        $sql = "SELECT 
            MAX(cur.cur_grupo) AS CurGrupo 
        FROM 
            curso cur 
        WHERE 
            cur.cal_codigo = {$CalCodigo} 
            AND cur.asi_codigo= {$AsiCodigo}
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consulta el grupo maximo de la asignatura {$AsiCodigo}.";
            return $this->errorConsultarBd;
        }
        //Se almacena el resultado de la consulta.
        $r_grupo = $this->cnx->json;
        //Se verifica si la asignatura tiene registros y si es diferente de vacio 
        if (count($r_grupo) > 0 && $r_grupo[0]["CurGrupo"] != '') {
            //se formatea el numero de subgrupo para que siempre tenga el formato 00 y se le sume en caso de encontrar registro. 
            $CurGrupo = sprintf("%02d", (int)$r_grupo[0]["CurGrupo"] + 1);
        }

        if (trim($VinNombre) != "DE PLANTA DOCENTE") {
            //Machetazo agregado por douglas el 2022-07-11 por los posgrados de salud en el calendario 218.	20222C
            //Aun cuando van a programar el 2022-2 le debe mostrar las vinculaciones del 2022-1 para las siguientes uaa
            // 75.NEIVA - ESPECIALIZACION EN PEDIATRIA
            // 84.NEIVA - ESPECIALIZACION GINECOLOGIA Y OBSTETRICIA
            // 85.NEIVA - ESPECIALIZACION EN MEDICINA INTERNA
            // 86.NEIVA - ESPECIALIZACION EN CIRUGIA GEN∫ERAL
            // 87.NEIVA - ESPECIALIZACION EN ANESTESIOLOGIA Y REANIMACION
            // 677.NEIVA - ESPECIALIZACION EN MEDICINA CRITICA Y CUIDADO INTENSIVO
            // 685.ESPECIALIZACION EN GINECOLOGIA Y OBSTETRICIA
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

        //$CurGrupo = '00'; //Se establece como predeterminado del grupo el 00.

        $sql = "INSERT INTO curso(
            uap_codigo, 
            asi_codigo, 
            sed_codigo, 
            cal_codigo, 
            cur_grupo, 
            cur_cupo, 
            cur_estado, 
            cut_codigo,
            pla_codigo, 
            cur_exclusivo, 
            usu_codigo, 
            cur_semanas, 
            tic_codigo, 
            cur_observaciones, 
            cur_ampliacion_cupo,
            cur_notaparcial, 
            tes_codigo, 
            cur_url
        )
        VALUES (
            {$UapCodigo},
            {$AsiCodigo},
            {$SedCodigo},
            {$CalCodigo},
            '{$CurGrupo}',
            {$CurCupo},
            {$CurEstado},
            {$CutCodigo},
            {$PlaCodigo},
            {$CurExclusivo},
            {$_SESSION['pacademica']['datosVinculacionUsuario']['usuarioCodigo']},
            {$CurSemanas},
            {$TicCodigo},
            '{$CurObservaciones}',
            {$CurAmpliacionCupo},
            '{$CurNotaParcial}',
            {$TesCodigo},
            '{$CurUrl}'
        )";

        if (!$this->cnx->sentencia($sql)) {
            $this->errorSentenciaBd["mensaje"] = "Error al crear el curso. 
                Recargue la página e intente de nuevo.";
            $this->errorSentenciaBd["consola"] = "Ha fallado la creación del curso.";
            // $this->errorSentenciaBd["sql"] = "{$sql}";
            return $this->errorSentenciaBd;
        }

        // Se consulta el cur_codigo del curso insertado, 
        $sql = "SELECT top 1 cur_codigo CurCodigo
            FROM curso
            WHERE
                uap_codigo = {$UapCodigo}  
                and asi_codigo = {$AsiCodigo}  
                and sed_codigo = {$SedCodigo}  
                and cal_codigo = {$CalCodigo}  
                and usu_codigo = {$_SESSION['pacademica']['datosVinculacionUsuario']['usuarioCodigo']} 
            ORDER BY cur_codigo DESC
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar el ultimo curso insertado.";
            return $this->errorConsultarBd;
        }

        $r_ult_curso = $this->cnx->json;

        $mensaje = "Curso {$r_ult_curso[0]['CurCodigo']} creado correctamente";

        if ($CurExclusivo == 1) {
            $error_planes = 0;
            $planes = '';
            foreach ($PlanesExclusivos as $PlanCodigo) {
                $sql = "INSERT INTO curso_plan(
                        cur_codigo,
                        pla_codigo
                    )
                    VALUES(
                        {$r_ult_curso[0]['CurCodigo']},
                        {$PlanCodigo}
                    )
                ";
                if (!$this->cnx->sentencia($sql)) {
                    $error_planes++;
                    $planes .= ",{$planes}";
                }
            }
            if ($error_planes > 0) {
                $mensaje .= ", error al asociar los planes exclusivos, intente de nuevo";
            }
        }

        // Se actualiza la agenda del docente para mantener consistencia con el proceso
        // manual de "Actualizar Agenda" en buscurso.
        require_once(dirname(__FILE__) . '/Curhorario.php');
        $curHorario = new Curhorario();
        $respuestaAgenda = $curHorario->actualizarAgenda($r_ult_curso[0]['CurCodigo']);

        if ($respuestaAgenda !== true) {
            $mensaje .= ", se creó el curso pero no se pudo actualizar la agenda automáticamente";
        }

        $mensaje .= ".";

        $respuesta = array(
            "resultado" => true,
            "mensaje" => $mensaje,
            "CurCodigo" => $r_ult_curso[0]['CurCodigo']
        );

        if ($respuestaAgenda !== true) {
            $respuesta["agendaActualizada"] = false;
            $respuesta["consolaAgenda"] = isset($respuestaAgenda["consola"]) ? $respuestaAgenda["consola"] : "Error al actualizar agenda automáticamente.";
        } else {
            $respuesta["agendaActualizada"] = true;
        }

        return $respuesta;
    }

    //Inicia funcion consultarPlanExclusivoCreacion
    //Permite consultar los planes academicos para seleccionar la exclusividad al crear un curso
    function consultarPlanExclusivoCreacion($obj)
    {
        //Validaciones

        //Parametros

        $sql = "SELECT 
            pla.pla_codigo PlaCodigo, 
            pla.pla_nombre PlaNombre,
			uaa.uaa_nombre_corto UaaNombreCorto
        FROM 
            plan_academico pla 
        INNER JOIN programa pro ON pro.pro_codigo = pla.pro_codigo
        INNER JOIN uaa ON uaa.uaa_codigo = pro.uaa_codigo AND uaa.uaa_nombre_corto NOT IN('desconocido')
        WHERE
            pla.pla_estado = 1
        ORDER BY pla_nombre ASC";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar los planes academicos.";
            return $this->errorConsultarBd;
        }

        return array(
            "resultado" => true,
            "mensaje" => "Planes academicos consultados correctamente.",
            "data" => $this->cnx->json
        );
    }

    //Inicio funcion consultarPlanesAcademicos
    //Permite consultar los planes academicos de una unidad y calendario especifico
    function consultarPlanesAcademicos($obj)
    {
        //Validaciones
        if (!isset($obj->UaaCodigo) || !is_numeric($obj->UaaCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar una unidad.",
                "consola" => "El codigo de la unidad no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->SedCodigo) || !is_numeric($obj->SedCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar una unidad.",
                "consola" => "El codigo de la sede no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->UaaDependencia) || !is_numeric($obj->UaaDependencia)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar una unidad.",
                "consola" => "El codigo de la dependencia no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->CalCodigo) || !is_numeric($obj->CalCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar un calendario.",
                "consola" => "El codigo del calendario no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->CalNombre)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar un calendario.",
                "consola" => "El nombre del calendario no se envio correctamente.",
            );
        }
        if (!isset($obj->PrpCodigo) || !is_numeric($obj->PrpCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar un calendario.",
                "consola" => "El codigo del proceso no es numérico o no se envio correctamente.",
            );
        }

        //Parametros
        $UaaCodigo = $obj->UaaCodigo; //Contiene el codigo de la unidad seleccionada
        $SedCodigo = $obj->SedCodigo; //Contiene el codigo de la sede a la unidad seleccionada
        $UaaDependencia = $obj->UaaDependencia; //Contiene el codigo de la dependencia (facultad) de la unidad seleccionada
        $CalCodigo = $obj->CalCodigo; //Contiene el codigo del calendario seleccionado
        $CalNombre = $obj->CalNombre; //Contiene el nombre del calendario seleccionado
        $PrpCodigo = $obj->PrpCodigo; //Contiene el codigo del proceso del calendario abierto
        $NucCodigo = $obj->NucCodigo; //Contiene los codigos de nucleos que tiene esa apertura para consultar.
        $validacionProceso = $this->validarProcesoSeleccionable($PrpCodigo);
        if (!$validacionProceso["resultado"]) {
            return $validacionProceso;
        }
        $tipo_calendario = substr($CalNombre, -1); //Contiene el tipo de calendario A,C,D,E
        $array_final = array(); //Contiene el diseño final del array formalidad>plan_academico>asignaturas

        $sql = "SELECT
            form.for_codigo ForCodigo,
            form.for_nombre ForNombre
        FROM
            formalidad form
        WHERE
            form.for_codigo <> 4 
        ORDER BY 
            form.for_nombre
        ASC
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar la formalidad.";
            return $this->errorConsultarBd;
        }

        $r_formalidad = $this->cnx->json;

        for ($f = 0; $f < count($r_formalidad); $f++) {
            $array_final[$f] = array(
                "ForCodigo" => $r_formalidad[$f]["ForCodigo"],
                "ForNombre" => $r_formalidad[$f]["ForNombre"],
                "PlanesAcademicos" => array()
            );

            $sql = "SELECT DISTINCT 
                pla.pla_codigo PlaCodigo, 
                pla.pla_nombre PlaNombre, 
                uaa.uaa_nombre UaaNombre, 
                pro.pro_codigo ProCodigo
            FROM 
                plan_academico pla
            INNER JOIN programa pro ON pla.pro_codigo = pro.pro_codigo AND pro.uaa_codigo = {$UaaCodigo}
            INNER JOIN uaa ON uaa.uaa_codigo = pro.uaa_codigo
            INNER JOIN nivel_academico nia ON nia.nia_codigo = pro.nia_codigo AND nia.for_codigo = {$r_formalidad[$f]["ForCodigo"]}
            WHERE 
                pla.pla_estado = 1
            ";

            if (!$this->cnx->consultar($sql)) {
                $this->errorConsultarBd["consola"] = "Error al consultar un plan académico.";
                return $this->errorConsultarBd;
            }

            $r_plan_aca = $this->cnx->json;

            for ($p = 0; $p < count($r_plan_aca); $p++) {
                $array_final[$f]["PlanesAcademicos"][$p] = array(
                    "PlaCodigo" => $r_plan_aca[$p]["PlaCodigo"],
                    "PlaNombre" => $r_plan_aca[$p]["PlaNombre"],
                    "UaaNombre" => $r_plan_aca[$p]["UaaNombre"],
                    "ProCodigo" => $r_plan_aca[$p]["ProCodigo"],
                    "Asignaturas" => array()
                );

                $sql = "SELECT 
                    asi.asi_codigo AsiCodigo, 
                    asi.asi_nombre AsiNombre, 
                    asi.asi_nombre_corto AsiNombreCorto, 
                    nuc.nuc_nombre NucNombre,
                    asi.asi_creditos AsiCreditos, 
                    asi.asi_creditos_teoria AsiCreditosTeoria, 
                    asi.asi_creditos_practica AsiCreditosPractica,

                    asi.asi_trabajo_horas_teorico AsiHorasSemanalesTeorico,
                    asi.asi_trabajo_horas_practico AsiHorasSemanalesPractica,
                    asi.asi_trabajo_horas_teorico_practico AsiHorasSemanalesTeoricoPractico,
                    
                    asi.car_codigo CarCodigo, --Codigo del caracter
                    car.car_nombre CarNombre, --Nombre del caracter.
                    uaa.uaa_codigo UaaCodigo,
                    uaa.uaa_nombre_corto UaaNombreCorto
                FROM 
                    asignatura asi
                INNER JOIN plan_academico_asignatura paa ON asi.asi_codigo = paa.asi_codigo 
                INNER JOIN nucleo nuc ON asi.nuc_codigo = nuc.nuc_codigo AND nuc.nuc_codigo IN ({$NucCodigo})
                INNER JOIN caracter car ON car.car_codigo = asi.car_codigo
                LEFT JOIN uaa ON uaa.uaa_codigo = asi.uaa_codigo
                WHERE 
                    paa.pla_codigo = {$r_plan_aca[$p]["PlaCodigo"]}
                    AND asi.asi_estado = 1
                    AND paa.paa_estado = 1
                    -- AND asi.uaa_codigo = {$UaaCodigo}
                    AND (
                        paa.paa_programable = 's' 
                        OR paa.paa_programable = 'S'
                    )
                ";

                if (!$this->cnx->consultar($sql)) {
                    $this->errorConsultarBd["consola"] = "Error al consultar las asignaturas del plan académico {$r_plan_aca[$p]["PlaNombre"]}.";
                    return $this->errorConsultarBd;
                }

                $r_asignaturas = $this->cnx->json;

                for ($a = 0; $a < count($r_asignaturas); $a++) {
                    $array_final[$f]["PlanesAcademicos"][$p]["Asignaturas"][$a] = array(
                        "AsiCodigo" => $r_asignaturas[$a]["AsiCodigo"],
                        "AsiNombre" => $r_asignaturas[$a]["AsiNombre"],
                        "AsiNombreCorto" => $r_asignaturas[$a]["AsiNombreCorto"],
                        "NucNombre" => $r_asignaturas[$a]["NucNombre"],
                        "AsiCreditos" => $r_asignaturas[$a]["AsiCreditos"],
                        "AsiCreditosTeoria" => $r_asignaturas[$a]["AsiCreditosTeoria"],
                        "AsiCreditosPractica" => $r_asignaturas[$a]["AsiCreditosPractica"],

                        "AsiHorasSemanalesTeorico" => $r_asignaturas[$a]["AsiHorasSemanalesTeorico"] == "" ? "0" : $r_asignaturas[$a]["AsiHorasSemanalesTeorico"],
                        "AsiHorasSemanalesPractica" => $r_asignaturas[$a]["AsiHorasSemanalesPractica"] == "" ? "0" : $r_asignaturas[$a]["AsiHorasSemanalesPractica"],
                        "AsiHorasSemanalesTeoricoPractico" => $r_asignaturas[$a]["AsiHorasSemanalesTeoricoPractico"] == "" ? "0" : $r_asignaturas[$a]["AsiHorasSemanalesTeoricoPractico"],

                        "CarCodigo" => $r_asignaturas[$a]["CarCodigo"],
                        "CarNombre" => $r_asignaturas[$a]["CarNombre"],
                        "UaaCodigo" => $r_asignaturas[$a]["UaaCodigo"],
                        "UaaNombreCorto" => $r_asignaturas[$a]["UaaNombreCorto"]
                    );
                }
            }
        }

        return array(
            "resultado" => true,
            "mensaje" => "Planes academicos consultados correctamente.",
            "data" => $array_final
        );
    }

    //Inicio funcion consultarTipoCurso
    //Permite listar los tipos de cursos que hay activos
    function consultarTipoCurso()
    {

        $sql = "SELECT
            cut.cut_codigo CutCodigo,
            cut.cut_nombre CutNombre,
            cut.cut_estado CutEstado
        FROM
            curso_tipo cut
        WHERE
            cut.cut_estado = 1
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar los tipos de curso.";
            return $this->errorConsultarBd;
        }

        return array(
            "resultado" => true,
            "mensaje" => "Tipos de curso consultados correctamente.",
            "data" => $this->cnx->json
        );
    }

    //Inicion funcion actualizarCurso
    //Permite actualizar un curso en especifico
    function actualizarCurso($obj)
    {
        //Validaciones
        if (!isset($obj->CurCodigo) || !is_numeric($obj->CurCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar un curso.",
                "consola" => "El codigo del curso no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->SedCodigo) || !is_numeric($obj->SedCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar una sede.",
                "consola" => "El codigo de la sede no es numérico o no se envio correctamente.",
            );
        }
        // if (!isset($obj->PlaCodigo) || !is_numeric($obj->PlaCodigo)) {
        //     return array(
        //         "resultado" => false,
        //         "mensaje" => "Debe seleccionar un plan académico.",
        //         "consola" => "El codigo del plan académico no es numérico o no se envio correctamente.",
        //     );
        // }
        if (!isset($obj->TicCodigo) || !is_numeric($obj->TicCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar una modalidad.",
                "consola" => "El codigo de la modalidad no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->CurNotaParcial)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar una nota parcial.",
                "consola" => "El codigo de la nota parcial no se envio correctamente.",
            );
        }
        if (!isset($obj->TesCodigo) || !is_numeric($obj->TesCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar un tipo de calificación.",
                "consola" => "El codigo de la calificación no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->CurEstado) || !is_numeric($obj->CurEstado)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar un estado.",
                "consola" => "El codigo del estado no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->AsiCodigo) || !is_numeric($obj->AsiCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar una asignatura.",
                "consola" => "El codigo de la asignatura no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->CurCupo) || !is_numeric($obj->CurCupo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe ingresar un cupo.",
                "consola" => "El cupo no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->CurAmpliacionCupo) || !is_numeric($obj->CurAmpliacionCupo)) {
            $obj->CurAmpliacionCupo = 0;
        }
        if (!isset($obj->CurSemanas) || !is_numeric($obj->CurSemanas)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe ingresar el numero de semanas.",
                "consola" => "El número de semanas no es numérico o no se envio correctamente.",
            );
        }
        if ($obj->CurSemanas < 1 || $obj->CurSemanas > 18) {
            return array(
                "resultado" => false,
                "mensaje" => "El número de semanas no puede ser menor a 1 o mayor a 18."
            );
        }
        if (!isset($obj->CurExclusivo) || !is_numeric($obj->CurExclusivo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar la exclusividad del curso.",
                "consola" => "El codigo de exclusividad no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->UapCodigo) || !is_numeric($obj->UapCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar un docente coordinador.",
                "consola" => "El codigo de vinculación del docente no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->CurGrupo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar una asignatura, no se encontro el grupo.",
                "consola" => "El codigo del grupo no se envio correctamente.",
            );
        }
        if (!isset($obj->CutCodigo) || !is_numeric($obj->CutCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar un tipo de curso.",
                "consola" => "El codigo del tipo de curso no es numérico o no se envio correctamente.",
            );
        }

        //Parametros
        $CurCodigo = $obj->CurCodigo; //Contiene el codigo del curso a modificar
        $SedCodigo = $obj->SedCodigo; //Contiene el codigo de la sede del curso
        $PlaCodigo = $obj->PlaCodigo; //Contiene el plan academico de la asignatura seleccionada
        if ($PlaCodigo == '') {
            $PlaCodigo = 'NULL';
        }
        $TicCodigo = $obj->TicCodigo; //Contiene el codigo de la modalidad del curso 1. Pesencial, 2. Apoyo virtual (b-Learning), 3. Mixto
        $CurNotaParcial = $obj->CurNotaParcial; //Contiene el codigo de la nota parcial 'S'. Si, 'N'. No
        $TesCodigo = $obj->TesCodigo; //Contiene el codigo del tipo de calificacion del curso 1. Numerico (0-5), 2. Aprobado/Reprobado, 3. Tres Niveles
        $CurEstado = $obj->CurEstado; //Contiene el codigo del estado 0. Eliminado, 1. Activo
        $AsiCodigo = $obj->AsiCodigo; //Contiene el codigo de la asignatura seleccionada
        $CurCupo = $obj->CurCupo; //Contiene el cupo del curso
        $CurAmpliacionCupo = $obj->CurAmpliacionCupo; //Contiene la ampliacion del cupo del curso, si viene vacia se establece en 0
        $CurSemanas = $obj->CurSemanas; //Contiene la cantidad de semanas del curso, debe ser entre 1 y 18, generalmente los posgrados programan 1 semana, los pregrados entre 16 y 18 semanas.
        $CurExclusivo = $obj->CurExclusivo; //Contiene si un curso es exclusivo 1. Si, 0. No.
        $UapCodigo = $obj->UapCodigo; //Contiene el codigo de vinculacion del docente coordinador.
        $CurUrl = utf8_decode($obj->CurUrl); //Contiene el link de para clases virtuales.
        $CurObservaciones = utf8_decode($obj->CurObservaciones); //Contiene observaciones del curso, generalmente se llena al momento de eliminar un curso o para reportar alguna novedad del curso.
        $CurGrupo = utf8_decode($obj->CurGrupo); //Contiene grupo del curso 00,01,02,03, etc.
        $CutCodigo = utf8_decode($obj->CutCodigo); //Contiene el codigo del tipo de curso.

        $sql = "SELECT
                cur.tic_codigo TicCodigoActual,
                (
                    SELECT
                        COUNT(*)
                    FROM
                        espacio_ocupacion eso
                    WHERE
                        eso.eso_actividad = cur.cur_codigo
                ) TotalHorario
            FROM
                curso cur
            WHERE
                cur.cur_codigo = {$CurCodigo}
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["mensaje"] = "Error al validar el horario del curso {$CurCodigo}.";
            $this->errorConsultarBd["consola"] = "Ha fallado la validacion del horario del curso {$CurCodigo}.";
            return $this->errorConsultarBd;
        }

        $cursoActual = $this->cnx->json;
        if (!isset($cursoActual[0])) {
            return array(
                "resultado" => false,
                "mensaje" => "No se encontro el curso {$CurCodigo}.",
                "consola" => "No se encontro informacion actual del curso {$CurCodigo}.",
            );
        }

        $TicCodigoActual = intval($cursoActual[0]["TicCodigoActual"]);
        $TotalHorarioActual = intval($cursoActual[0]["TotalHorario"]);

        if ($TicCodigoActual != intval($TicCodigo) && $TotalHorarioActual > 0) {
            return array(
                "resultado" => false,
                "mensaje" => "No es posible cambiar la modalidad del curso {$CurCodigo} porque tiene horas programadas.",
                "consola" => "Intento de cambio de modalidad bloqueado para el curso {$CurCodigo} con {$TotalHorarioActual} hora(s) programada(s).",
            );
        }

        $aforoSubgrupoTeoria = $this->consultarAforoMaximoSubgrupo($CurCodigo, '00');
        if (!$aforoSubgrupoTeoria['resultado']) {
            return $aforoSubgrupoTeoria;
        }

        $aforoMaximo = $aforoSubgrupoTeoria['aforoMaximo'];
        $limiteConGabela = Cupocurso::calcularLimiteConGabela($aforoMaximo);
        $gabela = Cupocurso::obtenerGabelaCupoAforo();
        $sumaCupoYReserva = intval($CurCupo) + intval($CurAmpliacionCupo);

        if ($limiteConGabela !== null && $sumaCupoYReserva > $limiteConGabela) {
            return array(
                "resultado" => false,
                "mensaje" => "No es posible guardar los cupos. Debe cumplirse: Cupo Total + Reserva <= Aforo + {$gabela}.",
                "consola" => "Validación de aforo no superada para curso {$CurCodigo}. cupo {$CurCupo}, reserva {$CurAmpliacionCupo}, suma {$sumaCupoYReserva}, aforo {$aforoMaximo}, límite {$limiteConGabela}.",
                "AforoMaximo" => $aforoMaximo,
                "LimiteConGabela" => $limiteConGabela,
                "SumaCupoReserva" => $sumaCupoYReserva
            );
        }

        //Se incluye el calendario para poder ser modificado por los administradores
        //Esto dado a que una maestria creo unos cursos en el calendario equivocado por que se le abrio ese calendario 
        //Error de los administradores pero es preferible dejarles la opcion solo a ellos de que se pueda cambiar

        $queryUpdateCalendario = '';
        if (isset($obj->CalCodigo) && is_numeric($obj->CalCodigo)) {
            $queryUpdateCalendario = "cal_codigo = {$obj->CalCodigo},";
        }

        $sql = "UPDATE 
            curso 
        SET 
            {$queryUpdateCalendario}
            uap_codigo = {$UapCodigo}, 
			asi_codigo = {$AsiCodigo}, 
            sed_codigo = {$SedCodigo}, 
            cur_grupo = '{$CurGrupo}', 
			cur_cupo = {$CurCupo}, 
            cur_estado = {$CurEstado}, 
			cut_codigo = {$CutCodigo}, 
            pla_codigo = {$PlaCodigo}, 
			cur_exclusivo = {$CurExclusivo}, 
            cdp_codigo = 1, --Se deja por el momento en 1. Pendiente 
			cur_semanas = {$CurSemanas}, 
			tic_codigo = {$TicCodigo}, 
            cur_observaciones = '{$CurObservaciones}', 
			cur_ampliacion_cupo = {$CurAmpliacionCupo}, 
            cur_notaparcial = '{$CurNotaParcial}', 
			tes_codigo = {$TesCodigo}, 
			cur_url = '{$CurUrl}', 
            cur_fecha_actualizacion = GETDATE() 
		WHERE 
            cur_codigo = {$CurCodigo}
        ";

        if (!$this->cnx->sentencia($sql)) {
            $this->errorSentenciaBd["mensaje"] = "Error al actualizar el curso {$CurCodigo}. 
                Recargue la página e intente de nuevo.";
            $this->errorSentenciaBd["consola"] = "Ha fallado la actualización del curso {$CurCodigo}.";
            // $this->errorSentenciaBd["sql"] = "{$sql}";
            return $this->errorSentenciaBd;
        } else {
            $mensaje = "Curso {$CurCodigo} actualizado correctamente.";
            if ($limiteConGabela !== null) {
                $mensaje .= " Aforo base para teoría (subgrupo 00): {$aforoMaximo}.";
                $mensaje .= " Límite permitido con gabela: {$limiteConGabela}.";
                $mensaje .= " Regla aplicada: Cupo Total + Reserva <= Aforo + {$gabela}.";
            } else {
                $mensaje .= " No aplica restricción por aforo para el subgrupo 00 (espacio de aula externa/sin salón/hospital o sin capacidad configurada).";
            }

            return array(
                "resultado" => true,
                "mensaje" => $mensaje,
                "AforoMaximo" => $aforoMaximo,
                "LimiteConGabela" => $limiteConGabela,
                "CurCupoAplicado" => intval($CurCupo),
                "CurAmpliacionAplicado" => intval($CurAmpliacionCupo),
                "SumaCupoReserva" => intval($CurCupo) + intval($CurAmpliacionCupo)
            );
        }
    }

    //Inicio funcion consultarDocentes
    //Permite consultar los docentes vinculados a una unidad especifica
    function consultarDocentes($obj)
    {
        //Validaciones
        if (!isset($obj->UaaCodigo) || !is_numeric($obj->UaaCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar una unidad académica.",
                "consola" => "El codigo de la unidad académica no es numérico o no se envio correctamente.",
            );
        }

        //Parametros
        $UaaCodigo = $obj->UaaCodigo; //Contiene el codigo de la unidad academica.
        $unidades = $_SESSION["pacademica"]["datosVinculacionUsuario"]["unidades"]; //Almacenamos las unidades que tiene permitida el usuario
        $CalCodigo = $obj->CalCodigo; //Contiene el codigo del calendario a programar
        $PerFechaInicio = $obj->PerFechaInicio; //Contiene la fecha de inicio del periodo normal
        $PerFechaFin = $obj->PerFechaFin; //Contiene la fecha de fin del periodo normal
        $PeriodoPersonalizado = $obj->PeriodoPersonalizado; //Contiene la fecha de inicio y fin en caso de tener periodo personalizado.
        $dePlantaDocente = 12; //Carlos arbey salamanca 362 Docente de planta
        $catedraDocente = 14; //Luis fernando salamanca Catedra docente
        $catedraPosgradosDocente = 17; //emilio polo ledesma Catedra posgrado docente
        $nombramOcasionalDocente = 23; //Alexander nossa o alexandra uribe Nombramiento ocacional
        $catedraVisitanteDocente = 24; //Carlos hernando trujillo Catedra visitante
        $catedraConvenioDocente = 49;

        if ($PeriodoPersonalizado != '') {
            $PeriodoPersonalizado = explode(' ', $PeriodoPersonalizado); //Ejemplo '2021-06-01 2021-12-31'
            $PerFechaInicio = $PeriodoPersonalizado[0]; //Cambiamos la fecha de inicio a la del periodo personalizado.
            $PerFechaFin = $PeriodoPersonalizado[1]; //Cambiamos la fecha de fin a la del periodo personalizado.
        }

        //Machetazo agregado por douglas el 2022-07-11 por los posgrados de salud en el calendario 218.	20222C
        //Aun cuando van a programar el 2022-2 le debe mostrar las vinculaciones del 2022-1 para las siguientes uaa
        // 75.NEIVA - ESPECIALIZACION EN PEDIATRIA
        // 84.NEIVA - ESPECIALIZACION GINECOLOGIA Y OBSTETRICIA
        // 85.NEIVA - ESPECIALIZACION EN MEDICINA INTERNA
        // 86.NEIVA - ESPECIALIZACION EN CIRUGIA GENERAL
        // 87.NEIVA - ESPECIALIZACION EN ANESTESIOLOGIA Y REANIMACION
        // 677.NEIVA - ESPECIALIZACION EN MEDICINA CRITICA Y CUIDADO INTENSIVO
        // 685.ESPECIALIZACION EN GINECOLOGIA Y OBSTETRICIA
        if ($CalCodigo == 218 && ($UaaCodigo == 75 || $UaaCodigo == 84 || $UaaCodigo == 85 || $UaaCodigo == 86 || $UaaCodigo == 87 || $UaaCodigo == 677 || $UaaCodigo == 685)) {
            $PerFechaInicio = "2022-02-04";
            $PerFechaFin = "2022-08-12";
        }

        //Machetazo agregado por douglas el 2022-11-22 por los posgrados de salud en el calendario 220. 20231C
        // 220	124	20231C	NULL	NULL	NULL	2022	1
        if ($CalCodigo == 220 && ($UaaCodigo == 75 || $UaaCodigo == 84 || $UaaCodigo == 85 || $UaaCodigo == 86 || $UaaCodigo == 87 || $UaaCodigo == 677 || $UaaCodigo == 685)) {
            $PerFechaInicio = "2022-10-03";
            $PerFechaFin = "2023-03-10";
        }

        $PerFechaInicio = date('Y-m-d', strtotime($PerFechaInicio));
        $PerFechaFin = date('Y-m-d', strtotime($PerFechaFin));
        $PerFechaInicioSql = FechaSqlServer::toSqlDateTime2($PerFechaInicio, false);
        $PerFechaFinFinDiaSql = FechaSqlServer::toSqlDateTime2($PerFechaFin, true);
        if ($PerFechaInicioSql === false || $PerFechaFinFinDiaSql === false) {
            return array(
                "resultado" => false,
                "mensaje" => "Formato de fecha inválido para consultar docentes.",
                "consola" => "No se pudieron preparar fechas SQL ({$PerFechaInicio} - {$PerFechaFin}).",
            );
        }

        $array_final = array();

        $array_final["FechaInicio"] = $PerFechaInicio;
        $array_final["FechaFin"] = $PerFechaFin;

        $administrador = $_SESSION["pacademica"]["datosVinculacionUsuario"]["Administrador"]; //Almacenamos si es administrador (1) o no (0)
        $queryDocentesporPrograma = $administrador == 0 ? "AND uap.uaa_codigo IN ({$unidades})" : "";

        $sql = "SELECT  --Consulta todos los docentes de planta.
            uap.uap_codigo UapCodigo, 
            uap.sed_codigo SedCodigo,
            per.per_nombre PerNombre,
            per.per_codigo PerCodigo,
            per.per_apellido PerApellido, 
            vin.vin_nombre VinNombre,
            vin.vin_codigo VinCodigo,
            ded.ded_codigo DedCodigo,
            ded.ded_nombre DedNombre,
            uap.uap_fecha_inicio UapFechaInicio, 
            uap.uap_fecha_fin UapFechaFin,
            uaa.uaa_nombre_corto UaaNombreCorto,
            (   
                SELECT count(*) 
                FROM agenda_periodo agp 
                WHERE agp.uap_codigo = uap.uap_codigo 
            ) UapCarga, 
        'No' PerNN
        FROM 
            uaa_personal uap 
        INNER JOIN vinculacion vin ON vin.vin_codigo = uap.vin_codigo AND vin.vin_clase = 1
        INNER JOIN persona per ON uap.per_codigo = per.per_codigo AND per.per_apellido NOT LIKE '%CATEDRA%'
        INNER JOIN dedicacion ded ON ded.ded_codigo = uap.ded_codigo
        INNER JOIN uaa ON uaa.uaa_codigo = uap.uaa_codigo
        WHERE 
            uap.uap_fecha_fin IS NULL
            AND uap.vin_codigo = {$dePlantaDocente} 
            {$queryDocentesporPrograma}
        ORDER BY per.per_nombre, per.per_apellido ASC
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar los docentes de planta.";
            return $this->errorConsultarBd;
        }

        $array_final["DocentesPlanta"] = $this->cnx->json;

        $sql = "SELECT --No se que que docente sea pero consulta docentes de planta que si tengan una fecha fin y este dentro de las fechas del periodo seleccionado. ¿Preguntar a javier por que?
            uap.uap_codigo UapCodigo, 
            uap.sed_codigo SedCodigo,
            per.per_nombre PerNombre,
            per.per_codigo PerCodigo,
            per.per_apellido PerApellido, 
            vin.vin_nombre VinNombre,
            vin.vin_codigo VinCodigo,
            ded.ded_codigo DedCodigo,
            uap.uap_fecha_inicio UapFechaInicio, 
            uap.uap_fecha_fin UapFechaFin, 
            ded.ded_nombre DedNombre,
            uaa.uaa_nombre_corto UaaNombreCorto,
            (   
                SELECT count(*) 
                FROM agenda_periodo agp 
                WHERE agp.uap_codigo = uap.uap_codigo 
            ) UapCarga, 
            'No' PerNN
        FROM 
            uaa_personal uap
        INNER JOIN vinculacion vin ON vin.vin_codigo = uap.vin_codigo AND vin.vin_clase = 1
        INNER JOIN persona per ON uap.per_codigo = per.per_codigo AND per.per_apellido NOT LIKE '%CATEDRA%'
        INNER JOIN dedicacion ded ON ded.ded_codigo = uap.ded_codigo
        INNER JOIN uaa ON uaa.uaa_codigo = uap.uaa_codigo
        WHERE 
            uap.uap_fecha_fin >= {$PerFechaInicioSql}
            AND uap.uap_fecha_fin <= {$PerFechaFinFinDiaSql}
            AND uap.vin_codigo = {$dePlantaDocente} 
            {$queryDocentesporPrograma}
        ORDER BY per.per_nombre, per.per_apellido ASC
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar los docentes de planta con fecha fin de vinculación.";
            return $this->errorConsultarBd;
        }

        $array_final["DocentesPlantaFechaFin"] = $this->cnx->json;

        $sql = "SELECT --Consulta docentes de catedra con vinculacion activa segun las fechas inicio y fin del periodo seleccionado.
            uap.uap_codigo UapCodigo, 
            uap.sed_codigo SedCodigo,
            per.per_nombre PerNombre,
            per.per_codigo PerCodigo,
            per.per_apellido PerApellido, 
            vin.vin_nombre VinNombre,
            vin.vin_codigo VinCodigo,
            ded.ded_codigo DedCodigo,
            uap.uap_fecha_inicio UapFechaInicio, 
            uap.uap_fecha_fin UapFechaFin, 
            ded.ded_nombre DedNombre,
            uaa.uaa_nombre_corto UaaNombreCorto,
            (   
                SELECT count(*) 
                FROM agenda_periodo agp 
                WHERE agp.uap_codigo = uap.uap_codigo 
            ) UapCarga, 
            'No' PerNN
        FROM 
            uaa_personal uap 
        INNER JOIN vinculacion vin ON vin.vin_codigo = uap.vin_codigo AND vin_clase = 1
        INNER JOIN persona per ON uap.per_codigo = per.per_codigo AND per.per_apellido NOT LIKE '%CATEDRA%'
        INNER JOIN dedicacion ded ON ded.ded_codigo = uap.ded_codigo
        INNER JOIN uaa ON uaa.uaa_codigo = uap.uaa_codigo
        WHERE  
            uap.uap_fecha_inicio >= {$PerFechaInicioSql}
            AND uap.uap_fecha_fin <= {$PerFechaFinFinDiaSql}
            AND uap.vin_codigo IN ({$catedraPosgradosDocente},{$catedraVisitanteDocente},{$catedraDocente}, {$catedraConvenioDocente}) 
            AND uap.uap_fecha_inicio != uap.uap_fecha_fin
            {$queryDocentesporPrograma}
        ORDER BY per.per_nombre, per.per_apellido ASC
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar los docentes de catedra con vinculación vigente.";
            return $this->errorConsultarBd;
        }

        $array_final["DocentesCatedra"] = $this->cnx->json;

        $sql = "SELECT --Consulta los docentes de nombramiento ocacional con vinculacion activa entre fecha de inicio  y fin del periodo seleccionado
            uap.uap_codigo UapCodigo,
            uap.sed_codigo SedCodigo,
            per.per_nombre PerNombre,
            per.per_codigo PerCodigo,
            per.per_apellido PerApellido,
            vin.vin_nombre VinNombre,
            vin.vin_codigo VinCodigo,
            ded.ded_codigo DedCodigo,
            uap.uap_fecha_inicio UapFechaInicio,
            uap.uap_fecha_fin UapFechaFin,
            ded.ded_nombre DedNombre,
            uaa.uaa_nombre_corto UaaNombreCorto,
            (   
                SELECT count(*) 
                FROM agenda_periodo agp 
                WHERE agp.uap_codigo = uap.uap_codigo 
            ) UapCarga, 
            'No' PerNN
        FROM
            uaa_personal uap
        INNER JOIN vinculacion vin ON vin.vin_codigo = uap.vin_codigo AND vin.vin_clase = 1
        INNER JOIN persona per ON uap.per_codigo = per.per_codigo AND per.per_apellido NOT LIKE '%CATEDRA%'
        INNER JOIN dedicacion ded ON ded.ded_codigo = uap.ded_codigo
        INNER JOIN uaa ON uaa.uaa_codigo = uap.uaa_codigo
        WHERE 
            uap.uap_fecha_inicio >= {$PerFechaInicioSql}
            AND uap.uap_fecha_fin <= {$PerFechaFinFinDiaSql}
            -- uap.uap_fecha_fin BETWEEN '{$PerFechaInicio}' AND '{$PerFechaFin}' 
            AND uap.vin_codigo IN ({$nombramOcasionalDocente})
            AND uap.uap_fecha_inicio != uap.uap_fecha_fin
            {$queryDocentesporPrograma}
        ORDER BY per.per_nombre, per.per_apellido ASC
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar los docentes de nombramiento ocacional con vinculación vigente.";
            return $this->errorConsultarBd;
        }

        $array_final["DocentesNombramientoOcacional"] = $this->cnx->json;

        $sql = "SELECT
            uap.uap_codigo UapCodigo,
            uap.sed_codigo SedCodigo,
            per.per_nombre PerNombre,
            per.per_codigo PerCodigo,
            per.per_apellido PerApellido,
            vin.vin_nombre VinNombre,
            vin.vin_codigo VinCodigo,
            ded.ded_codigo DedCodigo,
            uap.uap_fecha_inicio UapFechaInicio,
            uap.uap_fecha_fin UapFechaFin,
            ded.ded_nombre DedNombre,
            uaa.uaa_nombre_corto UaaNombreCorto,
            (   
                SELECT count(*) 
                FROM agenda_periodo agp 
                WHERE agp.uap_codigo = uap.uap_codigo 
            ) UapCarga, 
            'Si' PerNN
        FROM 
            uaa_personal uap
        INNER JOIN vinculacion vin ON vin.vin_codigo = uap.vin_codigo AND vin.vin_clase = 1
        INNER JOIN persona per ON uap.per_codigo = per.per_codigo AND per.per_apellido LIKE '%CATEDRA%'
        INNER JOIN dedicacion ded ON ded.ded_codigo = uap.ded_codigo
        INNER JOIN uaa ON uaa.uaa_codigo = uap.uaa_codigo
        WHERE 
            uap.uap_fecha_inicio >= {$PerFechaInicioSql}
            AND uap.uap_fecha_fin <= {$PerFechaFinFinDiaSql}
            AND uap.vin_codigo = {$catedraDocente}
            AND uap.uap_fecha_inicio != uap.uap_fecha_fin
            {$queryDocentesporPrograma}
        ORDER BY per.per_nombre, per.per_apellido ASC
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar los docentes NN con vinculación vigente.";
            return $this->errorConsultarBd;
        }

        $array_final["DocentesNN"] = $this->cnx->json;

        return array(
            "resultado" => true,
            "mensaje" => "Docentes consultados correctamente.",
            "data" => $array_final
        );
    }

    //Inicio funcion ponerComoExclusivo
    //Permite agregar exclusividad de un curso con un plan academico especifico.
    function ponerComoExclusivo($obj)
    {
        //Validaciones
        if (!isset($obj->PlaCodigo) || !is_numeric($obj->PlaCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar el plan academico para la exclusividad.",
                "consola" => "El codigo del plan académico no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->CurCodigo) || !is_numeric($obj->CurCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar el curso para la exclusividad.",
                "consola" => "El codigo del curso no es numérico o no se envio correctamente.",
            );
        }

        //Parametros
        $PlaCodigo = $obj->PlaCodigo; //Contiene el codigo del plan academico especifico
        $CurCodigo = $obj->CurCodigo; //Contiene el codigo del curso especifico

        $sql = "INSERT INTO curso_plan(
            cur_codigo,
            pla_codigo
        )
        VALUES(
            {$CurCodigo},
            {$PlaCodigo}
        )
        ";

        if (!$this->cnx->sentencia($sql)) {
            $this->errorSentenciaBd["mensaje"] = "Error al crear la exclusividad. 
                Recargue la página e intente de nuevo.";
            $this->errorSentenciaBd["consola"] = "Ha fallado insert en ponerComoExclusivo.";
            return $this->errorSentenciaBd;
        } else {
            return array(
                "resultado" => true,
                "mensaje" => "Exclusividad creada con exito."
            );
        }
    }

    //Inicio funcion quitarExclusividad
    //Permite eliminar la exclusividad de un curso con un plan academico especifico.
    function quitarExclusividad($obj)
    {
        //Validaciones
        if (!isset($obj->CupCodigo) || !is_numeric($obj->CupCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar la exclusividad a eliminar",
                "consola" => "El codigo de la exclusividad no es numérico o no se envio correctamente.",
            );
        }
        //Parametros
        $CupCodigo = $obj->CupCodigo; //Contiene el codigo del curso especifico

        $sql = "DELETE FROM
            curso_plan
        WHERE cup_codigo = {$CupCodigo}    
        ";

        if (!$this->cnx->sentencia($sql)) {
            $this->errorSentenciaBd["mensaje"] = "Error al eliminar la exclusividad. 
        Recargue la página e intente de nuevo.";
            $this->errorSentenciaBd["consola"] = "Ha fallado delete en quitarExclusividad.";
            return $this->errorSentenciaBd;
        } else {
            return array(
                "resultado" => true,
                "mensaje" => "Exclusividad eliminada con exito."
            );
        }
    }

    //Inicia funcion consultarPlanExclusivoCurso
    //Permite consultar los planes academicos con los que tiene exclusivdad el curso y los demas planes academicos activos.
    function consultarPlanExclusivoCurso($obj)
    {
        //Validaciones
        if (!isset($obj->CurCodigo) || !is_numeric($obj->CurCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar un curso.",
                "consola" => "El codigo del curso no es numérico o no se envio correctamente.",
            );
        }
        // if (!isset($obj->PlaCodigo) || !is_numeric($obj->PlaCodigo)) {
        //     return array(
        //         "resultado" => false,
        //         "mensaje" => "El plan academico del curso seleccionado no se envio correctamente.",
        //         "consola" => "El codigo del plan academico del curso no es numérico o no se envio correctamente.",
        //     );
        // }

        //Parametros
        $CurCodigo = $obj->CurCodigo; //Contiene el codigo del curso especifico
        // $PlaCodigo = $obj->PlaCodigo; //Contiene el codigo del plan academico del curso especifico

        $sql = "SELECT 
            paa.pla_codigo PlaCodigo, 
            paa.pla_nombre PlaNombre,
            uaa.uaa_nombre_corto UaaNombreCorto,
            'Exclusivo' Exclusivo,
            cpl.cup_codigo CupCodigo
        FROM 
            plan_academico paa 
        INNER JOIN programa pro ON pro.pro_codigo = paa.pro_codigo
        INNER JOIN uaa ON uaa.uaa_codigo = pro.uaa_codigo AND uaa.uaa_nombre_corto NOT IN('desconocido')
        INNER JOIN curso_plan cpl ON cpl.pla_codigo = paa.pla_codigo AND cpl.cur_codigo = {$CurCodigo} 

        UNION

        SELECT 
            pla.pla_codigo PlaCodigo, 
            pla.pla_nombre PlaNombre,
			uaa.uaa_nombre_corto UaaNombreCorto,
            'NoExclusivo' Exclusivo,
            '' CupCodigo
        FROM 
            plan_academico pla 
        INNER JOIN programa pro ON pro.pro_codigo = pla.pro_codigo
        INNER JOIN uaa ON uaa.uaa_codigo = pro.uaa_codigo AND uaa.uaa_nombre_corto NOT IN('desconocido')
        WHERE 
            pla.pla_codigo NOT IN (
                SELECT cpl.pla_codigo FROM curso_plan cpl
                WHERE cpl.cur_codigo = {$CurCodigo} 
            )

        ORDER BY Exclusivo ASC, pla_nombre ASC";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar los planes exclusivos del curso {$CurCodigo}.";
            return $this->errorConsultarBd;
        }

        return array(
            "resultado" => true,
            "mensaje" => "Planes exclusivos consultados correctamente.",
            "data" => $this->cnx->json
        );
    }

    //Inicio function colsultarPropietarioAsignatura
    //Permite consultar el propietario de una asignatura especifica.
    function consultarPropietarioAsignatura($obj)
    {
        //Validaciones
        if (!isset($obj->AsiCodigo) || !is_numeric($obj->AsiCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar una asignatura.",
                "consola" => "El codigo de la asignatura no es numérico o no se envio correctamente.",
            );
        }

        if (!isset($obj->CalCodigo) || !is_numeric($obj->CalCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar un calendario.",
                "consola" => "El codigo del calendario no es numérico o no se envio correctamente.",
            );
        }

        //Parametros
        $AsiCodigo = $obj->AsiCodigo; //Contiene el asi_codigo de una asignatura especifica.
        $CalCodigo = $obj->CalCodigo; //Contiene el cal_codigo de un calendario especifico.

        $sql = "SELECT
            uaa.uaa_codigo UaaCodigo,
            uaa.uaa_nombre_corto UaaNombreCorto
        FROM
            uaa
        INNER JOIN asignatura asi ON asi.uaa_codigo = uaa.uaa_codigo AND asi.asi_codigo = {$AsiCodigo}
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar las facultades.";
            return $this->errorConsultarBd;
        }

        $r_asignatura = $this->cnx->json; //Almacenamos el resultado de la informacion del propietario de la asignatura

        $sql = "SELECT 
            MAX(cur.cur_grupo) AS CurGrupo 
        FROM 
            curso cur 
        WHERE 
            cur.cal_codigo = {$CalCodigo} 
            AND cur.asi_codigo= {$AsiCodigo}
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consulta el grupo maximo de la asignatura {$AsiCodigo}.";
            return $this->errorConsultarBd;
        }

        $r_grupo = $this->cnx->json;
        $r_asignatura[0]["CurGrupo"] = '01';

        if (count($r_grupo) > 0 && $r_grupo[0]["CurGrupo"] != '') {
            $r_asignatura[0]["CurGrupo"] = sprintf("%02d", (int)$r_grupo[0]["CurGrupo"] + 1); //se formatea el numero de subgrupo para que siempre tenga el formato 00 
        }

        return array(
            "resultado" => true,
            "mensaje" => "Facultades consultadas correctamente.",
            "data" => $r_asignatura
        );
    }

    //Inicio funcion consultarAsignaturas
    //Permite consultar las asignaturas segun la unidad seleccionada, calendario, nucleo
    function consultarAsignaturas($obj)
    {
        if (!isset($obj->UaaCodigo) || !is_numeric($obj->UaaCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar una unidad.",
                "consola" => "El codigo de la unidad no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->PrpCodigo) || !is_numeric($obj->PrpCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar un calendario.",
                "consola" => "El codigo del proceso del calendario no es numérico o no se envio correctamente.",
            );
        }

        //Parametros:
        $UaaCodigo = $obj->UaaCodigo; //Almacena el codigo de la unidad seleccionada, de momento se usara el de todas las unidades.
        $PrpCodigo = $obj->PrpCodigo; //Almacena el codigo del proceso del calendario seleccionado.
        $NucCodigo = $obj->NucCodigo; //Almacena el codigo del nucleos del calendario seleccionado.
        $validacionProceso = $this->validarProcesoSeleccionable($PrpCodigo);
        if (!$validacionProceso["resultado"]) {
            return $validacionProceso;
        }
        $unidades = $_SESSION["pacademica"]["datosVinculacionUsuario"]["unidades"]; //Almacenamos las unidades que tiene permitida el usuario
        $administrador = $_SESSION["pacademica"]["datosVinculacionUsuario"]["Administrador"]; //Almacenamos si es administrador (1) o no (0)

        $sql = "SELECT DISTINCT --Al parecer consulta las equivalencias
            asi.asi_codigo AsiCodigo, 
            asi.asi_nombre AsiNombre,
            asi.asi_nombre_corto AsiNombreCorto, --, uaa_codigo, nuc_codigo 
            'Equivalencia' NucNombre,
            asi.asi_creditos AsiCreditos, 
            asi.asi_creditos_teoria AsiCreditosTeoria, 
            asi.asi_creditos_practica AsiCreditosPractica,
            asi.car_codigo CarCodigo, --Codigo del caracter
            
            asib.asi_codigo AsiBCodigo, 
            asib.asi_nombre AsiBNombre,
            asib.asi_nombre_corto AsiBNombreCorto, --, uaa_codigo, nuc_codigo 
            'Equivalencia' NucBNombre,
            asib.asi_creditos AsiBCreditos, 
            asib.asi_creditos_teoria AsiBCreditosTeoria, 
            asib.asi_creditos_practica AsiBCreditosPractica,
            asib.car_codigo CarBCodigo, --Codigo del caracter

            car.car_nombre CarNombre, --Nombre del caracter.
            uaa.uaa_codigo UaaCodigo,
            uaa.uaa_nombre_corto UaaNombreCorto,
            'EQUIVALENCIAS' TipoAsignatura
        FROM 
            asignatura asi 
        INNER JOIN equivalencia equi ON asi.asi_codigo = equi.asi_equivalencia
        INNER JOIN asignatura asib ON asib.asi_codigo = equi.asi_codigo
        INNER JOIN caracter car ON car.car_codigo = asi.car_codigo
        INNER JOIN uaa ON uaa.uaa_codigo = asi.uaa_codigo
        WHERE  
            asi.asi_estado = 1 AND 
            asi.uaa_codigo IN ({$unidades})
            AND asi.nuc_codigo IN ({$NucCodigo})
            AND ISNUMERIC(asi.asi_nombre_corto) <> 1
            AND ISNUMERIC(asib.asi_nombre_corto) <> 1
        
        UNION
        
        SELECT--Al parecer consulta las equivalencias de las asignaturas que estan marcadas como no programables
            asib.asi_codigo AsiCodigo,
            asib.asi_nombre AsiNombre,
            asib.asi_nombre_corto AsiNombreCorto,
            nuc.nuc_nombre NucNombre,
            asib.asi_creditos AsiCreditos, 
            asib.asi_creditos_teoria AsiCreditosTeoria, 
            asib.asi_creditos_practica AsiCreditosPractica, 
            asib.car_codigo CarCodigo, --Codigo del caracter

            asi.asi_codigo AsiBCodigo,
            asi.asi_nombre AsiBNombre,
            asi.asi_nombre_corto AsiBNombreCorto,
            nuc.nuc_nombre NucBNombre,
            asi.asi_creditos AsiBCreditos, 
            asi.asi_creditos_teoria AsiBCreditosTeoria, 
            asi.asi_creditos_practica AsiBCreditosPractica, 
            asi.car_codigo CarBCodigo, --Codigo del caracter

            car.car_nombre CarNombre, --Nombre del caracter
            uaa.uaa_codigo UaaCodigo,
            uaa.uaa_nombre_corto UaaNombreCorto,
            'NOPROGRAMABLES' TipoAsignatura
        FROM 
            asignatura asi 
        INNER JOIN plan_academico_asignatura paa ON asi.asi_codigo = paa.asi_codigo AND paa.paa_programable = 'N' AND paa.paa_estado = 1
        INNER JOIN plan_academico pla ON pla.pla_codigo = paa.pla_codigo
        INNER JOIN programa pro ON pla.pro_codigo = pro.pro_codigo AND pro.uaa_codigo in ({$UaaCodigo})
        INNER JOIN uaa ON uaa.uaa_codigo = pro.uaa_codigo
        INNER JOIN nucleo nuc ON nuc.nuc_codigo = asi.nuc_codigo
        INNER JOIN equivalencia equi ON equi.asi_codigo = asi.asi_codigo
        INNER JOIN asignatura asib ON asib.asi_codigo = equi.asi_equivalencia AND asib.nuc_codigo != ''
        INNER JOIN caracter car ON car.car_codigo = asib.car_codigo
        WHERE 
            asi.asi_estado = 1 AND
            asi.nuc_codigo IN ({$NucCodigo}) AND 
            ISNUMERIC(asi.asi_nombre_corto) <> 1 AND
            ISNUMERIC(asib.asi_nombre_corto) <> 1 AND
            asi.asi_codigo NOT IN
            (
                SELECT 
                    asi.asi_codigo AsiCodigo
                FROM 
                    asignatura asi
                INNER JOIN plan_academico_asignatura paa ON asi.asi_codigo = paa.asi_codigo AND paa.paa_programable = 'N' AND paa.paa_estado = 1
                INNER JOIN plan_academico pla ON pla.pla_codigo = paa.pla_codigo
                INNER JOIN programa pro ON pro.uaa_codigo IN ({$UaaCodigo}) AND pla.pro_codigo = pro.pro_codigo
                INNER JOIN uaa ON pro.uaa_codigo = uaa.uaa_codigo
                INNER JOIN nucleo nuc ON nuc.nuc_codigo = asi.nuc_codigo AND nuc.nuc_codigo = 1
                INNER JOIN equivalencia equi ON equi.asi_equivalencia = asi.asi_codigo
                INNER JOIN asignatura asic ON asic.asi_codigo = equi.asi_codigo AND ISNUMERIC(asic.asi_nombre_corto) <> 1
            )  
        ORDER BY AsiNombre";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar las asignaturas vinculadas a la unidad.";
            return $this->errorConsultarBd;
        }

        return array(
            "resultado" => true,
            "mensaje" => "Asignaturas consultadas correctamente.",
            "data" => $this->cnx->json
        );
    }

    //Inicio funcion consultarPlanExclusivo
    //Permite consultar los planes academicos exclusivos de un curso especifico
    function consultarPlanExclusivo($obj)
    {
        if (!isset($obj->CurCodigo) || !is_numeric($obj->CurCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar un curso.",
                "consola" => "El codigo del curso no es numérico o no se envio correctamente.",
            );
        }
        // if (!isset($obj->PlaCodigo) || !is_numeric($obj->PlaCodigo)) {
        //     return array(
        //         "resultado" => false,
        //         "mensaje" => "El plan academico del curso seleccionado no se envio correctamente.",
        //         "consola" => "El codigo del plan academico del curso no es numérico o no se envio correctamente.",
        //     );
        // }

        //Parametros:
        $CurCodigo = $obj->CurCodigo; //Almacena el codigo del curso.
        // $PlaCodigo = $obj->PlaCodigo; //Almacena el codigo del plan academico del curso.

        $sql = "SELECT 
            paa.pla_codigo PlaCodigo, 
            paa.pla_nombre PlaNombre,
            uaa.uaa_nombre_corto UaaNombreCorto
        FROM 
            plan_academico paa 
        INNER JOIN programa pro ON pro.pro_codigo = paa.pro_codigo
        INNER JOIN uaa ON uaa.uaa_codigo = pro.uaa_codigo AND uaa.uaa_nombre_corto NOT IN('desconocido')
        WHERE 
            paa.pla_codigo IN (
                SELECT cpl.pla_codigo FROM curso_plan cpl
                WHERE cpl.cur_codigo = {$CurCodigo} 
            )
        ORDER BY pla_nombre";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar los planes exclusivos del curso {$CurCodigo}.";
            return $this->errorConsultarBd;
        }

        return array(
            "resultado" => true,
            "mensaje" => "Planes exclusivos consultados correctamente.",
            "data" => $this->cnx->json
        );
    }

    //Inicio funcion consultarAgendaDocente
    //Permite consulta la agenda de una vinculacion en un calendario especifico
    function consultarAgendaDocente($obj)
    {
        //Parametros:
        $UapCodigo = $obj->UapCodigo; //Contiene codigo de la vinculacion del docente especifica
        $CalCodigo = $obj->CalCodigo; //Contiene codigo del calendario especifico
        $PeriodoPersonalizado = $obj->PeriodoPersonalizado; //Contiene si la unidad tiene fechas diferentes para ese periodo
        $periodo_inicio = ""; //La fecha de inicio de un periodo especifico
        $periodo_fin = ""; //La fecha de fin de un periodo especifico

        if ($PeriodoPersonalizado != '') {
            $PeriodoPersonalizado = explode(" ", $PeriodoPersonalizado);
            $periodo_inicio = $PeriodoPersonalizado[0];
            $periodo_fin = $PeriodoPersonalizado[1];
        } else {
            $sql = "SELECT
                per_fecha_inicio PerFechaInicio,
                per_fecha_fin PerFechaFin
            FROM
                periodo per
            INNER JOIN calendario cal ON per.per_codigo = cal.per_codigo AND cal.cal_codigo = {$CalCodigo}
            ";

            if (!$this->cnx->consultar($sql)) {
                $this->errorConsultarBd["consola"] = "Error al consultar las fechas del periodo del calendario {$CalCodigo}.";
                return $this->errorConsultarBd;
            }
            $r_periodo = $this->cnx->json;
            $periodo_inicio = $r_periodo[0]['PerFechaInicio'];
            $periodo_fin = $r_periodo[0]['PerFechaFin'];
        }
        $periodoInicioSql = FechaSqlServer::toSqlDateTime2($periodo_inicio, false);
        $periodoFinFinDiaSql = FechaSqlServer::toSqlDateTime2($periodo_fin, true);
        if ($periodoInicioSql === false || $periodoFinFinDiaSql === false) {
            return array(
                "resultado" => false,
                "mensaje" => "Formato de fecha inválido para consultar agenda docente.",
                "consola" => "No se pudieron preparar fechas SQL ({$periodo_inicio} - {$periodo_fin}).",
            );
        }

        $sql = "SELECT DISTINCT 
            cur.cur_codigo CurCodigo, 
            asi.asi_nombre AsiNombre, 
            asi.asi_nombre_corto AsiNombreCorto, 
            cur.cur_grupo CurGrupo, 
            per.per_nombre PerNombre, 
            per.per_apellido PerApellido, 
            eso.dia_codigo DiaCodigo, 
            eso.hra_codigo HraCodigo, 
            uaa.uaa_nombre_corto UaaNombreCorto, 
            uaa.uaa_codigo UaaCodigo, 
            asi.nuc_codigo NucCodigo,
            esp.esp_codigo EspCodigo,
            esp.esp_nombre_corto EspNombreCorto
        FROM 
            espacio_ocupacion eso 
        INNER JOIN curso cur ON cur.cur_codigo = eso.eso_actividad
        INNER JOIN asignatura asi ON asi.asi_codigo = cur.asi_codigo 
        INNER JOIN uaa ON uaa.uaa_codigo = eso.uaa_codigo 
        INNER JOIN uaa_personal uap ON eso.uap_codigo = uap.uap_codigo 
        INNER JOIN persona  per ON per.per_codigo = uap.per_codigo
        INNER JOIN espacio esp ON eso.esp_codigo = esp.esp_codigo
        WHERE
            (eso_fecha BETWEEN {$periodoInicioSql} AND {$periodoFinFinDiaSql}) AND 
            per.per_codigo = (SELECT per_codigo FROM uaa_personal WHERE uap_codigo={$UapCodigo})
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar la agenda del docente {$UapCodigo} en el calendario {$CalCodigo}";
            return $this->errorConsultarBd;
        }

        $r_agenda = $this->cnx->json;
        $array_final = array();
        $dias = [
            1 => "Lunes",
            2 => "Martes",
            3 => "Miercoles",
            4 => "Jueves",
            5 => "Viernes",
            6 => "Sabado",
            7 => "Domingo"
        ];
        $array = [];
        for ($h = 1; $h <= 18; $h++) {
            for ($d = 1; $d <= 8; $d++) {
                $tiene = false;
                foreach ($r_agenda as $agenda) {
                    if ($agenda["DiaCodigo"] == $d && $agenda["HraCodigo"] == $h) {
                        $tiene = true;
                        $array = [ //Organizamos un array con los datos de la facultad
                            "CurCodigo" => utf8_decode($agenda['CurCodigo']),
                            "AsiNombre" => utf8_decode($agenda['AsiNombre']),
                            "AsiNombreCorto" => utf8_decode($agenda['AsiNombreCorto']),
                            "CurGrupo" => utf8_decode($agenda['CurGrupo']),
                            "PerNombre" => utf8_decode($agenda['PerNombre']),
                            "PerApellido" => utf8_decode($agenda['PerApellido']),
                            "DiaCodigo" => utf8_decode($agenda['DiaCodigo']),
                            "HraCodigo" => utf8_decode($agenda['HraCodigo']),
                            "UaaNombreCorto" => utf8_decode($agenda['UaaNombreCorto']),
                            "UaaCodigo" => utf8_decode($agenda['UaaCodigo']),
                            "NucCodigo" => utf8_decode($agenda['NucCodigo']),
                            "EspCodigo" => utf8_decode($agenda['EspCodigo']),
                            "EspNombreCorto" => utf8_decode($agenda['EspNombreCorto']),
                        ];
                        break;
                    }
                }

                if ($tiene == true) {
                    $array_final[$h][$d] = array_map('utf8_encode', $array);
                } else {
                    $array_final[$h][$d] = "{$dias[$d]} - {$h}";
                }
            }
        }

        return array(
            "resultado" => true,
            "mensaje" => "Detalle de la agenda consultada correctamente.",
            "data" => $array_final
        );
    }

    //Inicio funcion consultarDetalleCurso
    //Permite consultar el detalle de un curso en especifico
    function consultarDetalleCurso($obj)
    {
        if (!isset($obj->CurCodigo) || !is_numeric($obj->CurCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar un curso.",
                "consola" => "El codigo del curso no es numérico o no se envio correctamente.",
            );
        }

        if (!isset($obj->UaaCodigo) || !is_numeric($obj->UaaCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar una unidad.",
                "consola" => "El codigo de la unidad no es numérico o no se envio correctamente.",
            );
        }

        $CurCodigo = $obj->CurCodigo; //Contiene el codigo del curso seleccionado
        $UaaCodigo = $obj->UaaCodigo; //Contiene el codigo de la Uaa que se selecciono

        $sql = "SELECT 
            cur.cur_codigo CurCodigo, 
            cur.uap_codigo UapCodigo, --Codigo de vinculacion uaa_persona.uap_codigo del coordinador del curso
            cur.asi_codigo AsiCodigo, 
            cur.sed_codigo SedCodigo, 
            cur.cal_codigo CalCodigo,
            cal.cal_nombre CalNombre, --Calendario al que se programa el curso
            cal.per_codigo PeriodoCodigo,
            cur.cur_grupo CurGrupo, 
            cur.cur_cupo CurCupo, --Cupo total del curso
            cur.cur_estado CurEstado, --1. activo, 0. eliminado
            cur.pla_codigo PlaCodigo, --Codigo del plan academico del curso.
            pla.pla_nombre PlaNombre, --Nombre del plan academico del curso.
            cut.cut_codigo CutCodigo, --Codigo del tipo curso. De momento solo se programa con 1. Normal
            cut.cut_nombre CutNombre, --Nombre del tipo curso.
            cur.cur_exclusivo CurExclusivo, --Define si un curso es exclusivo o no para su plan academico.
            sed.sed_nombre SedNombre, --Sede donde queda disponible el curso
            asi.asi_nombre_corto AsiNombreCorto, 
            asi.asi_nombre AsiNombre, 
            asi.asi_creditos AsiCreditos, 
            asi.asi_creditos_teoria AsiCreditosTeoria, 
            asi.asi_creditos_practica AsiCreditosPractica, 

            asi.asi_trabajo_horas_teorico AsiHorasSemanalesTeorico,
            asi.asi_trabajo_horas_practico AsiHorasSemanalesPractica,
            asi.asi_trabajo_horas_teorico_practico AsiHorasSemanalesTeoricoPractico,
            
            per.per_nombre + ' ' + per.per_apellido as PerNombreApellido, --Docente coordinador
            per.per_codigo PerCodigo, --codigo de la persona del docente coordinador
            vin.vin_nombre VinNombre, --Vinculacion del docente coordinador
            vin.vin_codigo VinCodigo, --Codigo de vinculacion del docente coordinador
            uap.ded_codigo DedCodigo, --Codigo de dedicacion del docente
            uap.sed_codigo UapSedCodigo, --Codigo de  la sede de la vinculación del docente
            cur.cdp_codigo CdpCodigo, --?? Preguntar si se sigue usando o que mierdas
            cur.cur_semanas CurSemanas, --Duracion de semanas para el curso
            asi.car_codigo CarCodigo, --Codigo del caracter
            car.car_nombre CarNombre, --Nombre del caracter.
            cur.tic_codigo TicCodigo, --Modalidad 1. Presencial, 2. Apoyo virtual (b-Learning), 3. Mixto
            cur.cur_observaciones CurObservaciones,
            cur.cur_ampliacion_cupo CurAmpliacionCupo, --La ampliacion reserva cupo del cupo total, no amplia.
            cur.cur_notaparcial CurNotaParcial,
            cur.tes_codigo TesCodigo, --Calificacion 1. Numerico (0-5), 2. Aprobado/Reprobado, 3.Tres niveles
            uaa.uaa_nombre_corto UaaNombreCorto, --Unidad dueña de la asignatura.
            uaa.uaa_codigo UaaCodigo, 
            cur.cur_url CurUrl, --Link de meet para clases virtuales
            (
                SELECT 
                    TOP 1 uaa_codigo 
                FROM 
                    espacio_ocupacion 
                WHERE 
                    eso_actividad = cur.cur_codigo
            ) UaaHorario, --No tengo bien claro pero es la unidad que se usa en espacio ocupacion 'El programa donde se hace la programacion academica.'
            (
                SELECT
                    COUNT(*)
                FROM
                    espacio_ocupacion eso
                WHERE
                    eso.eso_actividad = cur.cur_codigo
            ) TotalHorario,
            (
                SELECT 
                    count(*) 
                FROM 
                    matricula_curso mac
                WHERE 
                    mac.cur_codigo = {$CurCodigo} AND 
                    mac.maa_codigo IN (1,2) --matricula_autorizacion 1. Adicion, 2.Normal (Solo cuenta las matriculas 'activas').
            ) TotalMatriculados,
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
            ) AforoMaximoTeoria
        FROM 
            curso cur
        LEFT JOIN plan_academico pla ON pla.pla_codigo = cur.pla_codigo
        INNER JOIN calendario cal ON cal.cal_codigo = cur.cal_codigo
        INNER JOIN sede sed ON sed.sed_codigo = cur.sed_codigo
        INNER JOIN asignatura asi ON asi.asi_codigo = cur.asi_codigo
        INNER JOIN uaa_personal uap ON uap.uap_codigo = cur.uap_codigo
        INNER JOIN persona per ON per.per_codigo = uap.per_codigo
        LEFT JOIN uaa ON uaa.uaa_codigo = asi.uaa_codigo
        INNER JOIN vinculacion vin ON vin.vin_codigo = uap.vin_codigo
        INNER JOIN caracter car ON car.car_codigo = asi.car_codigo
        INNER JOIN curso_tipo cut ON cut.cut_codigo = cur.cut_codigo
        WHERE
            cur.cur_codigo = {$CurCodigo}
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar del detalle del curso {$CurCodigo}.";
            return $this->errorConsultarBd;
        }

        $resultado = $this->cnx->json; //Almacenamos la informacion del curso puntual

        //Consultamos si el docente asignado viene de alguna solicitud para el periodo especifico
        $sql = " SELECT 
                spd.spd_codigo SpdCodigo,
                spd.asi_codigo AsiCodigo,
                asi.asi_nombre AsiNombre,
                asi.asi_nombre_corto AsiNombreCorto
            FROM programacionacademica.solicitud_prestamo_docente spd
            INNER JOIN asignatura asi ON asi.asi_codigo = spd.asi_codigo
            WHERE
                spd.spd_estado = 2
                AND spd.periodo_codigo = {$resultado[0]["PeriodoCodigo"]}
                AND spd.persona_codigo = {$resultado[0]["PerCodigo"]}
                AND spd.uaa_solicita = {$UaaCodigo}
        ";
        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar del detalle del curso {$CurCodigo}.";
            return $this->errorConsultarBd;
        }

        $infoSolicitud = $this->cnx->json; //Almacenamos la informacion de la solicitud, los codigos de las asignaturas que tiene ese docente permitidas.
        $resultado[0]["DocentePrestado"] = 0; //creamos el campo para almacenar la informacion del docente prestado en caso de ser el coordinador.

        if (count($infoSolicitud) > 0) {
            foreach ($infoSolicitud as $key => $docente) {
                // Consultamos el horario de la solicitud.
                $sql = "SELECT
                        spdh.spdh_codigo SpdhCodigo,
                        dia.dia_codigo DiaCodigo,
                        dia.dia_nombre DiaNombre,
                        hra.hra_codigo HraCodigo,
                        hra.hra_inicio HraInicio,
                        hra.hra_fin HraFin
                    FROM
                        programacionacademica.solicitud_prestamo_docente_horario spdh
                    INNER JOIN dia ON dia.dia_codigo = spdh.dia_codigo
                    INNER JOIN hora hra ON hra.hra_codigo = spdh.hra_codigo
                    WHERE
                        spdh.spdh_estado = 1
                        AND spdh.spd_codigo = {$docente['SpdCodigo']}
                    ORDER BY spdh.dia_codigo, spdh.hra_codigo ASC
                ";

                if (!$this->cnx->consultar($sql)) {
                    $this->errorConsultarBd["mensaje"] = "No se pudo realizar la consulta del horario de la solicitud seleccionada.";
                    $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
                    return $this->errorConsultarBd;
                }

                $infoSolicitud[$key]["Horario"] = $this->cnx->json;
            }
        }

        $resultado[0]["DocentePrestado"] = $infoSolicitud; //Agregamos a la informacion de curso un campo con el arreglo de los codigos de las asignaturas permitidas. 

        return array(
            "resultado" => true,
            "mensaje" => "Detalle del curso consultado correctamente.",
            "data" => $resultado
        );
    }

    function consultarCursos($obj)
    {
        if (!isset($obj->UaaCodigo) || !is_numeric($obj->UaaCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar una unidad.",
                "consola" => "El codigo de la unidad no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->CalCodigo) || !is_numeric($obj->CalCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar un calendario.",
                "consola" => "El codigo del calendario no es numérico o no se envio correctamente.",
            );
        }

        $UaaCodigo = $obj->UaaCodigo; //Contiene el codigo de la unidad seleccionada.
        $CalCodigo = $obj->CalCodigo; //Contiene el codigo del calendario seleccionado.
        $NucCodigo = $obj->NucCodigo; //Contiene el codigo del proceso (nucleo).
        $unidades = $_SESSION["pacademica"]["datosVinculacionUsuario"]["unidades"]; //Almacenamos las unidades que tiene permitida el usuario
        $administrador = $_SESSION["pacademica"]["datosVinculacionUsuario"]["Administrador"]; //Almacenamos si es administrador (1) o no (0)
        $usuario = $_SESSION["pacademica"]["datosVinculacionUsuario"]["usuarioCodigo"]; //Almacenamos el codigo del usuario

        if ($administrador == 0) {
            $permisoCurso = new PermisoCurso();
            $query_usuario = $permisoCurso->condicionPropietarioSql($usuario);
            $sql = "SELECT 
                cur.cur_codigo CurCodigo, 
                cur.cur_grupo CurGrupo, 
                sed.sed_nombre SedNombre,
                asi.nuc_codigo NucCodigo, 
                nuc.nuc_nombre NucNombre, 
                asi.asi_nombre AsiNombre, 
                asi.asi_nombre_corto AsiNombreCorto, 
                cur.pla_codigo PlaCodigo, 
                cur.cur_url CurUrl, 
                cur.cur_cupo CurCupo, 
                cur.cur_estado CurEstado,
                cut.cut_nombre CutNombre,
                per.per_codigo PersonaCodigo,
                cal.per_codigo PeriodoCodigo,
                (
                    SELECT count(*)
                    FROM programacionacademica.solicitud_prestamo_docente spd
                    WHERE
                        spd.spd_estado = 2
                        AND spd.periodo_codigo = cal.per_codigo
                        AND spd.persona_codigo = per.per_codigo
                        AND spd.asi_codigo = cur.asi_codigo
                        AND spd.uaa_solicita = {$UaaCodigo}
            
                ) DocentePrestado,
                (
                    SELECT 
                        count(*) 
                    FROM 
                        matricula_curso mac
                    WHERE 
                        mac.cur_codigo = cur.cur_codigo AND 
                        mac.maa_codigo IN (1,2) --matricula_autorizacion 1. Adicion, 2.Normal (Solo cuenta las matriculas 'activas').
                ) TotalMatriculados,
                (
                    SELECT
                        COUNT(*)
                    FROM
                        espacio_ocupacion eso
                    WHERE
                        eso.eso_actividad = cur.cur_codigo
                ) TotalHorario
            FROM 
                curso cur
            INNER JOIN asignatura asi ON asi.asi_codigo = cur.asi_codigo AND asi.nuc_codigo IN ({$NucCodigo})
            INNER JOIN sede sed ON sed.sed_codigo = cur.sed_codigo
            LEFT JOIN nucleo nuc ON nuc.nuc_codigo = asi.nuc_codigo
            LEFT JOIN curso_tipo cut ON cut.cut_codigo = cur.cut_codigo
            INNER JOIN uaa_personal uap ON uap.uap_codigo = cur.uap_codigo
            INNER JOIN persona per ON per.per_codigo = uap.per_codigo
            INNER JOIN calendario cal ON cal.cal_codigo = cur.cal_codigo
            WHERE 
                cur.cal_codigo = {$CalCodigo}
                AND (
                    {$query_usuario}
                    OR asi.uaa_codigo = {$UaaCodigo}
                )
            ORDER BY 
                cur.cur_codigo ASC,
                cur.cur_estado DESC
            ";
        }

        if ($administrador == 1) {
            $sql = "SELECT 
                cur.cur_codigo CurCodigo, 
                cur.cur_grupo CurGrupo, 
                sed.sed_nombre SedNombre,
                asi.nuc_codigo NucCodigo, 
                nuc.nuc_nombre NucNombre, 
                asi.asi_nombre AsiNombre, 
                asi.asi_nombre_corto AsiNombreCorto, 
                cur.pla_codigo PlaCodigo, 
                cur.cur_url CurUrl, 
                cur.cur_cupo CurCupo, 
                cur.cur_estado CurEstado,
                cut.cut_nombre CutNombre,
                per.per_codigo PersonaCodigo,
                cal.per_codigo PeriodoCodigo,
                (
                    SELECT count(*)
                    FROM programacionacademica.solicitud_prestamo_docente spd
                    WHERE
                        spd.spd_estado = 2
                        AND spd.periodo_codigo = cal.per_codigo
                        AND spd.persona_codigo = per.per_codigo
                        AND spd.asi_codigo = cur.asi_codigo
                        AND spd.uaa_solicita = {$UaaCodigo}
            
                ) DocentePrestado,
                (
                    SELECT 
                        count(*) 
                    FROM 
                        matricula_curso mac
                    WHERE 
                        mac.cur_codigo = cur.cur_codigo AND 
                        mac.maa_codigo IN (1,2) --matricula_autorizacion 1. Adicion, 2.Normal (Solo cuenta las matriculas 'activas').
                ) TotalMatriculados,
                (
                    SELECT
                        COUNT(*)
                    FROM
                        espacio_ocupacion eso
                    WHERE
                        eso.eso_actividad = cur.cur_codigo
                ) TotalHorario
            FROM 
                curso cur
            INNER JOIN asignatura asi ON asi.asi_codigo = cur.asi_codigo AND asi.nuc_codigo IN ({$NucCodigo})
            INNER JOIN sede sed ON sed.sed_codigo = cur.sed_codigo
            LEFT JOIN nucleo nuc ON nuc.nuc_codigo = asi.nuc_codigo
            LEFT JOIN curso_tipo cut ON cut.cut_codigo = cur.cut_codigo
            INNER JOIN uaa_personal uap ON uap.uap_codigo = cur.uap_codigo
            INNER JOIN persona per ON per.per_codigo = uap.per_codigo
            INNER JOIN calendario cal ON cal.cal_codigo = cur.cal_codigo
            WHERE 
                cur.cal_codigo = {$CalCodigo}
                --AND (asi.uaa_codigo = {$UaaCodigo} OR cur.usu_codigo = {$usuario})
            ORDER BY 
                cur.cur_codigo ASC,
                cur.cur_estado DESC
            ";
        }

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar los cursos.";
            $this->errorConsultarBd["sql"] = $sql;
            $cnxVars = get_object_vars($this->cnx);
            $this->errorConsultarBd["error"] = isset($cnxVars['mjeError']) ? $cnxVars['mjeError'] : "Sin detalle en cls_config::consultar";
            return $this->errorConsultarBd;
        }

        return array(
            "resultado" => true,
            "mensaje" => "Cursos consultadas correctamente.",
            "data" => $this->cnx->json
        );
    }

    //Inifio funcion consultarUnidadesUnificadas
    //Permite consultar la lista de las unidades permitidas para el usuario.
    function consultarUnidadesUnificadas()
    {
        //Parametros:
        $unidades = $_SESSION["pacademica"]["datosVinculacionUsuario"]["unidades"]; //Almacenamos las unidades que tiene permitida el usuario

        $sql = "SELECT
            uaa.uaa_codigo UaaCodigo,
            uaa.uaa_nombre UaaNombre,
            uaa.uaa_nombre_corto UaaNombreCorto,
            convert(varchar, uaa.uaa_codigo) + convert(varchar,'. ') + uaa.uaa_nombre_corto UaaCodigoNombre,
            uaa.sed_codigo SedCodigo,
            uaa.uaa_dependencia UaaDependencia,
            sed.sed_nombre SedNombre,
            uaa.uat_codigo UatCodigo
        FROM
            uaa
        INNER JOIN sede sed on sed.sed_codigo = uaa.sed_codigo
        WHERE
            uaa.uat_codigo NOT IN (24) --Consulte las unidades que no sean unificadas (24)
            AND uaa.uaa_estado = 1
            AND uaa.uaa_codigo IN(
                {$unidades}
            )
        ORDER BY
            uaa.uaa_nombre_corto ASC
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar las unidades.";
            return $this->errorConsultarBd;
        }

        return array(
            "resultado" => true,
            "mensaje" => "Unidades consultadas correctamente.",
            "data" => $this->cnx->json
        );
    }

    //Inicio funcion consultarFacultades
    //Permite consultar las facultades 
    function consultarFacultades()
    {
        $sql = "SELECT
            uaa.uaa_codigo UaaCodigo,
            uaa.uaa_nombre UaaNombre
        FROM
            uaa
        WHERE
            uaa.uat_codigo = 1 
            AND uaa.uaa_codigo NOT IN (26,27,28)
        ORDER BY
            uaa.uaa_nombre
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar las facultades.";
            return $this->errorConsultarBd;
        }

        return array(
            "resultado" => true,
            "mensaje" => "Facultades consultadas correctamente.",
            "data" => $this->cnx->json
        );
    }

    //Inicio funcion consultarSedes
    //Permite consultar las sedes permitidas segun las unidades permitidas del usuario
    function consultarSedes()
    {
        //Parametros:
        $unidades = $_SESSION["pacademica"]["datosVinculacionUsuario"]["unidades"]; //Almacenamos las unidades que tiene permitida el usuario

        $sql = "SELECT DISTINCT
            sed.sed_codigo SedCodigo,
            sed.sed_nombre SedNombre
        FROM
            plan_academico pla
        INNER JOIN programa pro ON pro.pro_codigo = pla.pro_codigo AND pro.uaa_codigo IN ({$unidades})
        INNER JOIN uaa ON uaa.uaa_codigo = pro.uaa_codigo
        INNER JOIN sede sed ON sed.sed_codigo = uaa.sed_codigo
        INNER JOIN plan_academico_asignatura paa ON paa.pla_codigo = pla.pla_codigo
        INNEr JOIN asignatura asi ON asi.asi_codigo = paa.asi_codigo
        WHERE 
            pla.pla_estado = 1

        UNION

        SELECT DISTINCT
            sed.sed_codigo SedCodigo,
            sed.sed_nombre SedNombre
        FROM
            plan_academico pla
        INNER JOIN programa pro ON pro.pro_codigo = pla.pro_codigo
        INNER JOIN uaa ON uaa.uaa_codigo = pro.uaa_codigo
        INNER JOIN sede sed ON sed.sed_codigo = uaa.sed_codigo
        INNER JOIN plan_academico_asignatura paa ON paa.pla_codigo = pla.pla_codigo
        INNEr JOIN asignatura asi ON asi.asi_codigo = paa.asi_codigo AND asi.uaa_codigo IN ({$unidades})
        WHERE 
            pla.pla_estado = 1
        ORDER BY 
            sed.sed_codigo
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar las sedes.";
            return $this->errorConsultarBd;
        }

        return array(
            "resultado" => true,
            "mensaje" => "Sedes consultadas correctamente.",
            "data" => $this->cnx->json
        );
    }

    //Inicio funcion consultarDocentesPrestados
    //Permite consultar los docentes prestados aprobados.
    function consultarDocentesPrestados($obj)
    {
        //Validaciones
        if (!isset($obj->UaaCodigo) || !is_numeric($obj->UaaCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar una unidad académica.",
                "consola" => "El codigo de la unidad académica no es numérico o no se envio correctamente.",
            );
        }

        //Parametros
        $UaaCodigo = $obj->UaaCodigo; //Contiene el codigo de la unidad academica seleccionada.
        $administrador = isset($_SESSION["pacademica"]["datosVinculacionUsuario"]["Administrador"])
            && $_SESSION["pacademica"]["datosVinculacionUsuario"]["Administrador"] == 1;
        $unidadesSesion = isset($_SESSION["pacademica"]["datosVinculacionUsuario"]["unidades"])
            ? $_SESSION["pacademica"]["datosVinculacionUsuario"]["unidades"]
            : '';
        $unidadesPermitidas = array_values(array_filter(array_map('trim', explode(',', $unidadesSesion)), 'is_numeric'));
        if (!$administrador && !in_array((string) $UaaCodigo, $unidadesPermitidas, true)) {
            return array(
                "resultado" => false,
                "mensaje" => "No tiene permisos para consultar los docentes asignados a la unidad seleccionada.",
                "consola" => "La unidad {$UaaCodigo} no pertenece a las unidades autorizadas del usuario.",
            );
        }
        $PerCodigo = $obj->PerCodigo; //Contiene el codigo del periodo a programar
        $PerFechaInicio = $obj->PerFechaInicio; //Contiene la fecha de inicio del periodo normal
        $PerFechaFin = $obj->PerFechaFin; //Contiene la fecha de fin del periodo normal
        $PeriodoPersonalizado = $obj->PeriodoPersonalizado; //Contiene la fecha de inicio y fin en caso de tener periodo personalizado.

        if ($PeriodoPersonalizado != '') {
            $PeriodoPersonalizado = explode(' ', $PeriodoPersonalizado); //Ejemplo '2021-06-01 2021-12-31'
            $PerFechaInicio = $PeriodoPersonalizado[0]; //Cambiamos la fecha de inicio a la del periodo personalizado.
            $PerFechaFin = $PeriodoPersonalizado[1]; //Cambiamos la fecha de fin a la del periodo personalizado.
        }
        $PerFechaInicioSql = FechaSqlServer::toSqlDateTime2($PerFechaInicio, false);
        $PerFechaFinFinDiaSql = FechaSqlServer::toSqlDateTime2($PerFechaFin, true);
        if ($PerFechaInicioSql === false || $PerFechaFinFinDiaSql === false) {
            return array(
                "resultado" => false,
                "mensaje" => "Formato de fecha inválido para consultar docentes prestados.",
                "consola" => "No se pudieron preparar fechas SQL ({$PerFechaInicio} - {$PerFechaFin}).",
            );
        }

        $array_final = array();

        $array_final["FechaInicio"] = $PerFechaInicio;
        $array_final["FechaFin"] = $PerFechaFin;

        $sql = "SELECT
                spd.spd_codigo SpdCodigo,
                per.per_nombre PerNombre,
                per.per_codigo PerCodigo,
                per.per_apellido PerApellido,
                sed.sed_codigo SedCodigo,
                sed.sed_nombre SedNombre,
                asi.asi_codigo AsiCodigo,
                asi.asi_nombre AsiNombre,
                asi.asi_nombre_corto AsiNombreCorto,
                spd.uaa_solicita UaaCodigoSolicita,
                CONVERT(varchar, uaa.uaa_codigo) + '. ' + uaa.uaa_nombre_corto UaaNombreSolicita,
                CONVERT(varchar, uaadpto.uaa_codigo) + '. ' + uaadpto.uaa_nombre_corto UaaNombreDpto
            FROM
                programacionacademica.solicitud_prestamo_docente spd
                INNER JOIN sede sed ON sed.sed_codigo = spd.sed_codigo
                INNER JOIN asignatura asi ON asi.asi_codigo = spd.asi_codigo
                INNER JOIN uaa ON uaa.uaa_codigo = spd.uaa_solicita
                INNER JOIN uaa uaadpto ON uaadpto.uaa_codigo = spd.uaa_dirigida
                INNER JOIN persona per ON per.per_codigo = spd.persona_codigo
            WHERE   
                spd.periodo_codigo = {$PerCodigo}
                AND spd.uaa_solicita = {$UaaCodigo}
                AND spd.spd_estado = 2
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar las solicitudes aprobadas para el programa.";
            return $this->errorConsultarBd;
        }

        $array_final["Docentes"] = $this->cnx->json;

        foreach ($array_final["Docentes"] as &$docente) {
            $SpdCodigo = $docente["SpdCodigo"]; //Contiene el codigo de la solicitud especifica
            $PerCodigo = $docente["PerCodigo"]; //Contiene el codigo de la persona asignada

            // Consultamos si existe vinculacion del docente
            $sql = "SELECT
                    uap.uap_codigo UapCodigo,
                    uap.sed_codigo UapSedCodigo,
                    vin.vin_nombre VinNombre,
                    vin.vin_codigo VinCodigo,
                    ded.ded_codigo DedCodigo,
                    ded.ded_nombre DedNombre,
                    uap.uap_fecha_inicio UapFechaInicio,
                    uap.uap_fecha_fin UapFechaFin,
                    (   
                                SELECT count(*)
                    FROM agenda_periodo agp
                    WHERE agp.uap_codigo = uap.uap_codigo 
                            ) UapCarga
                FROM
                    programacionacademica.solicitud_prestamo_docente spd
                    LEFT JOIN uaa_personal uap ON uap.per_codigo = spd.persona_codigo
                    LEFT JOIN vinculacion vin ON vin.vin_codigo = uap.vin_codigo
                    LEFT JOIN dedicacion ded ON ded.ded_codigo = uap.ded_codigo
                WHERE   
                    spd.spd_codigo = {$SpdCodigo}
                    AND vin.vin_codigo IN (24,12,23,14,5,24,16,49)
                    AND spd.spd_estado = 2
                    AND uap.uap_fecha_inicio <= {$PerFechaFinFinDiaSql}
                    AND (
                        uap.uap_fecha_fin IS NULL
                        OR uap.uap_fecha_fin >= {$PerFechaInicioSql}
                    )
                    AND (uap.uap_fecha_fin IS NULL OR uap.uap_fecha_inicio != uap.uap_fecha_fin)
            ";

            if (!$this->cnx->consultar($sql)) {
                $this->errorConsultarBd["consola"] = "Error al consultar la vinculación del docente asignado a la solicitud {$SpdCodigo}.";
                return $this->errorConsultarBd;
            }

            $consultaVinculacionDocente = $this->cnx->json;

            if (count($consultaVinculacionDocente) > 0) {
                $docente['UapCodigo'] = $consultaVinculacionDocente[0]['UapCodigo'];
                $docente['UapSedCodigo'] = $consultaVinculacionDocente[0]['UapSedCodigo'];
                $docente['VinNombre'] = $consultaVinculacionDocente[0]['VinNombre'];
                $docente['VinCodigo'] = $consultaVinculacionDocente[0]['VinCodigo'];
                $docente['DedCodigo'] = $consultaVinculacionDocente[0]['DedCodigo'];
                $docente['DedNombre'] = $consultaVinculacionDocente[0]['DedNombre'];
                $docente['UapFechaInicio'] = $consultaVinculacionDocente[0]['UapFechaInicio'];
                $docente['UapFechaFin'] = $consultaVinculacionDocente[0]['UapFechaFin'];
                $docente['UapCarga'] = $consultaVinculacionDocente[0]['UapCarga'];
            }

            // Consultamos el horario de la solicitud
            $sql = "SELECT
                    spdh.spdh_codigo SpdhCodigo,
                    dia.dia_codigo DiaCodigo,
                    dia.dia_nombre DiaNombre,
                    hra.hra_codigo HraCodigo,
                    hra.hra_inicio HraInicio,
                    hra.hra_fin HraFin
                FROM
                    programacionacademica.solicitud_prestamo_docente_horario spdh
                INNER JOIN dia ON dia.dia_codigo = spdh.dia_codigo
                INNER JOIN hora hra ON hra.hra_codigo = spdh.hra_codigo
                WHERE
                    spdh.spdh_estado = 1
                    AND spdh.spd_codigo = {$SpdCodigo}
                ORDER BY spdh.dia_codigo, spdh.hra_codigo ASC
            ";

            if (!$this->cnx->consultar($sql)) {
                $this->errorConsultarBd["mensaje"] = "No se pudo realizar la consulta del horario de la solicitud seleccionada.";
                $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
                return $this->errorConsultarBd;
            }

            $docente["Horario"] = $this->cnx->json;
        }

        return array(
            "resultado" => true,
            "mensaje" => "Docentes Prestados consultados correctamente.",
            "data" => $array_final
        );
    }
}
