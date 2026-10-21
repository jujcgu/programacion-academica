<?php
date_default_timezone_set('America/Bogota');

class Mmatriculados
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

    // Inicio actualizarObservacion
    // Permite actualizar la observacion de un curso especifico.
    public function actualizarObservacion($obj)
    {
        //Validaciones
        if (!isset($obj->CursoInfo) || $obj->CursoInfo == '') {
            return array(
                "resultado" => false,
                "mensaje" => "No se selecciono un curso especifico.",
                "consola" => "No se ha enviado correctamente la informacion del curso. " . __LINE__
            );
        }

        $CursoInfo = $obj->CursoInfo; //Contiene la informacion del curso, codigo, asignatura, observacion, etc.

        $sql = "UPDATE curso SET cur_observaciones = '{$CursoInfo->nuevaObservacion}', cur_fecha_actualizacion = GETDATE() WHERE cur_codigo = {$CursoInfo->CurCodigo} ";

        if (!$this->cnx->sentencia($sql)) {
            $this->errorSentenciaBd["mensaje"] = "Error al actualizar la observacion del curso seleccionado.";
            $this->errorSentenciaBd["consola"] = "Ha fallado la actualizacion de la observacion en el curso {$CursoInfo->CurCodigo}.";
            return $this->errorSentenciaBd;
        }

        return array(
            "resultado" => true,
            "mensaje" => "Observacion del curso {$CursoInfo->CurCodigo} actualizada correctamente."
        );
    }

    // Inicio verificarCurso
    // Permite verificar si un curso se debe aprobar o no.
    public function verificarCurso($obj)
    {
        //Validaciones
        if (!isset($obj->CursoInfo) || $obj->CursoInfo == '') {
            return array(
                "resultado" => false,
                "mensaje" => "No se selecciono un curso especifico.",
                "consola" => "No se ha enviado correctamente la informacion del curso. " . __LINE__
            );
        }
        if (!isset($obj->EstudiantesInfo) || $obj->EstudiantesInfo == '' || count($obj->EstudiantesInfo) <= 0) {
            return array(
                "resultado" => false,
                "mensaje" => "No se selecciono un curso especifico.",
                "consola" => "No se ha enviado correctamente la informacion del curso. " . __LINE__
            );
        }

        $CursoAprobado = false;

        foreach ($obj->EstudiantesInfo as &$estudiante) {

            $justificado = false; // Evita que una validacion posterior sobreescriba una justificacion ya encontrada.

            // 1.
            // Verificar si el estudiante la perdio previsamente.
            $r_perdidaPrevia = $this->validarAsignaturaPerdidaPreviamente($estudiante->EstCodigo, $estudiante->PaaCodigo);
            // Se verifica que se realizara correctamente y que tenga mas de 1 vez perdida.
            if ($r_perdidaPrevia["resultado"] == true && $r_perdidaPrevia["vecesPerdidas"] > 0) {
                $estudiante->Justificacion = "El estudiante ha perdido esta asignatura previamente."; // Se asigna la justificacion
                $CursoAprobado = true;
                $justificado = true;
            }

            // 2.
            //Obtenemos el plan academico completo del estudiante
            $planCompleto = $this->obtenerPlanAcademico($estudiante->EstCodigo);
            $planAcademico = "";
            // Verificamos que la respuesta sea correcta.
            if ($planCompleto["resultado"] == true && count($planCompleto["data"]) > 0) {
                $planAcademico = $planCompleto["data"]; //Almacenamos los registros del plan academico.
            }

            // 3.
            // Verificamos si con ese PAA se nivela o des nivela
            if (!$justificado) {
                $r_estudianteNivelado = $this->validarEstudianteNivelado($estudiante->EstCodigo, $estudiante->MatCodigo, $estudiante->PaaCodigo, $planAcademico);
                // Se verifica que se realizara correctamente y que tenga mas de 1 vez perdida.
                if ($r_estudianteNivelado["resultado"] == true) {
                    $estudiante->Justificacion = "El estudiante se encuentra nivelado con este curso."; // Se asigna la justificacion
                    $estudiante->semestresNivelados = $r_estudianteNivelado["semestresNivelados"];
                    $estudiante->CountIntersect = $r_estudianteNivelado["CountIntersect"];
                    $estudiante->CountDebeVer = $r_estudianteNivelado["CountDebeVer"];
                    $estudiante->CountMatriculado = $r_estudianteNivelado["CountMatriculado"];
                    $CursoAprobado = true;
                    $justificado = true;
                }
            }
        
            // 4.
            // Verificar si el estudiante con esta asignatura completa el plan academico
            if (!$justificado) {
                $r_completaPlanAcademico = $this->validarCompletaPlanAcademico($estudiante->EstCodigo, $estudiante->MatCodigo, $planAcademico);
                // Se verifica que se realizara correctamente y que tenga mas de 1 vez perdida.
                if ($r_completaPlanAcademico["resultado"] == true && $r_completaPlanAcademico["terminaPlan"]) {
                    $estudiante->Justificacion = "El estudiante completa plan académico con esta asignatura."; // Se asigna la justificacion
                    $CursoAprobado = true;
                    $justificado = true;
                }
            }
        }


        return array(
            "resultado" => true,
            "mensaje" => "Curso verificado correctamente.",
            "CursoAprobado" => $CursoAprobado,
            "data" => $obj->EstudiantesInfo
        );
    }

    // Inicio validarEstudianteNivelado
    // Permite verificar si un estudiante se nivela con esta asignatura
    private function validarEstudianteNivelado($EstCodigo, $MatCodigo, $PaaCodigo, $planAcademicoCompleto)
    {
        //Validaciones
        if (!isset($EstCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envió el codigo del estudiante.",
                "consola" => "El codigo del estudiante no se envió correctamente. {$EstCodigo}. " . __LINE__,
            );
        }
        if (!isset($MatCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envió el codigo de la matricula.",
                "consola" => "El codigo de la matricula no se envió correctamente. {$MatCodigo}. " . __LINE__,
            );
        }
        if (!isset($PaaCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envió el codigo de la asignatura del plan académico paa.",
                "consola" => "El codigo del paa no se envió correctamente. {$PaaCodigo}. " . __LINE__,
            );
        }
        if (!is_array($planAcademicoCompleto)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envió el plan academico completo.",
                "consola" => "El plan academico no se envió correctamente. " . __LINE__,
            );
        }

        // Filtrar el array para obtener las asignaturas con BE y BF que no tienen nota
        $asignaturasBEBFSinNota = array_filter($planAcademicoCompleto, function ($registro) {
            $nombreCorto = substr($registro['AsiNombreCorto'], 0, 2);
            return ($registro["nota"] === null || $registro["nota"] === "") && ($nombreCorto === "BF" || $nombreCorto === "BE");
        });
        // Organizamos el array de tal manera que la posicion sea el semestre y los items sean las asignaturas que deba ver ese semestre.
        $asignaturasBEBFSinNotaPorSemestre = array();
        foreach ($asignaturasBEBFSinNota as $registro) {
            $asignaturasBEBFSinNotaPorSemestre[$registro["PaaSemestre"]][] = $registro;
        }

        // Obtenemos la informacion del estudiante, la informacion de la asignatura por la cual queda en 6 semestre y el plan academico de lo que debe ver
        $infoValidar = array();
        foreach ($asignaturasBEBFSinNota as $asignatura) {
            if ($asignatura['nota'] === null || $asignatura['nota'] === "") { // La primera asignatura sin nota es el semestre en el que va
                $infoValidar["EstCodigo"] = $EstCodigo; // Codigo del estudiante
                $infoValidar["PaaSemestre"] = $asignatura['PaaSemestre']; // Semestre actual
                break;
            }
        }

        $infoValidar["PlanAcademicoBEBFLista"] = $asignaturasBEBFSinNota; // Plan academico de lo que falta por ver que son BE y BF
        $infoValidar["PlanAcademicoBEBFPorSemestre"] = $asignaturasBEBFSinNotaPorSemestre; // Plan academico de lo que falta por ver que son BE y BF pero organizado por semestre

        // Obtenemos lo que falta por ver en el semestre donde se encuentra el estudiante actualmente
        $asignaturasDebeVerSemestreActual = array_filter($asignaturasBEBFSinNota, function ($registro) use ($infoValidar) {
            return $registro['PaaSemestre'] === $infoValidar["PaaSemestre"] && ($registro['nota'] === null || $registro['nota'] === "");
        });

        // Obtenemos las materias matriculadas de una matricula de un estudiante especifico.
        $sql = "SELECT mac.paa_codigo PaaCodigo, mac.sippa_cursemestre PaaSemestre, asi.asi_nombre_corto AsiNombreCorto, asi.asi_nombre AsiNombre 
            FROM matricula_curso mac WITH (NOLOCK)
            INNER JOIN asignatura asi on asi.asi_codigo = mac.sippa_asicodigo WITH (NOLOCK)
            WHERE mac.mat_codigo = {$MatCodigo} AND mac.maa_codigo IN (1,2) AND mac.mac_definitiva IS NULL ORDER BY mac.sippa_cursemestre ASC";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["mensaje"] = "No se pudo consultar los cursos matriculados de la matricula {$MatCodigo}.";
            $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
            return $this->errorConsultarBd;
        }
        $matriculadasPorEstudiante = $this->cnx->json;

        // Filtrar el array para obtener las asignaturas con BE y BF que son las unicas que cuentan para verificar si un estudiante se nivela o se des nivela.
        $matriculadasPorEstudianteBEBF = array_filter($matriculadasPorEstudiante, function ($registro) {
            $nombreCorto = substr($registro['AsiNombreCorto'], 0, 2);
            return $nombreCorto === "BF" || $nombreCorto === "BE";
        });

        // Organizamos el array de tal manera que la posicion sea el semestre y los items sean las asignaturas que tiene matriculadas.
        $matriculadasPorEstudianteBEBFPorSemestre = array();
        foreach ($matriculadasPorEstudianteBEBF as $registro) {
            $matriculadasPorEstudianteBEBFPorSemestre[$registro["PaaSemestre"]][] = $registro;
        }

        // Consultamos el semestre del paa especifico.
        $sql = "SELECT paa.paa_codigo PaaCodigo, paa.paa_semestre PaaSemestre FROM plan_academico_asignatura paa WITH (NOLOCK) WHERE paa.paa_codigo = {$PaaCodigo}";
        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["mensaje"] = "No se pudo consultar la información del paa {$PaaCodigo}.";
            $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
            return $this->errorConsultarBd;
        }

        $paaInformacion = $this->cnx->json;

        $infoValidar["asignaturaEvaluar"] = $paaInformacion;
        $infoValidar["asignaturasDebeVerSemestreActual"] = $asignaturasDebeVerSemestreActual;
        $infoValidar["matriculadasPorEstudianteBEBF"] = $matriculadasPorEstudianteBEBF;
        $infoValidar["matriculadasPorEstudiantePorSemestre"] = $matriculadasPorEstudianteBEBFPorSemestre;

        // Obtenemos los semestres que ha matriculado el estudiante.
        $semestresMatriculados = array_unique(array_column($matriculadasPorEstudianteBEBF, 'PaaSemestre'));
        // Iniciamos las verificaciones

        // Verificamos si la asignatura que se evalua, la debe ver y la tiene matriculada
        // $paaDebeVer = array_search($infoValidar["asignaturaEvaluar"][0]["PaaCodigo"], array_column($infoValidar["asignaturasDebeVerSemestreActual"], "PaaCodigo")) !== false ? true : false;
        // $paaEstaMatriculado = array_search($infoValidar["asignaturaEvaluar"][0]["PaaCodigo"], array_column($infoValidar["matriculadasPorEstudianteBEBF"], "PaaCodigo")) !== false ? true : false;
        foreach ($semestresMatriculados as $semestre) {
            $intersect = array_intersect(array_column($infoValidar["PlanAcademicoBEBFPorSemestre"][$semestre], "PaaCodigo"), array_column($infoValidar["matriculadasPorEstudiantePorSemestre"][$semestre], "PaaCodigo"));
            $infoValidar["CountIntersect"][$semestre] = count($intersect);
            $infoValidar["CountDebeVer"][$semestre] = count($infoValidar["PlanAcademicoBEBFPorSemestre"][$semestre]);
            $infoValidar["CountMatriculado"][$semestre] = count($infoValidar["matriculadasPorEstudiantePorSemestre"][$semestre]);
            $infoValidar["Validacion"][$semestre]["DebeVer"] = $infoValidar["PlanAcademicoBEBFPorSemestre"][$semestre];
            $infoValidar["Validacion"][$semestre]["Matriculado"] = $infoValidar["matriculadasPorEstudiantePorSemestre"][$semestre];
        }
        $todoNivelado = false;
        $semestresNivelados = 0;
        if (count($infoValidar["CountIntersect"]) == count($infoValidar["CountDebeVer"]) && count($infoValidar["CountDebeVer"]) == count($infoValidar["CountMatriculado"])) {
            foreach ($infoValidar["CountDebeVer"] as $sem => $val) {
                if ($infoValidar["CountIntersect"][$sem] == $infoValidar["CountDebeVer"][$sem] && $infoValidar["CountDebeVer"][$sem] == $infoValidar["CountMatriculado"][$sem]) {
                    $semestresNivelados++;
                }
            }
        }

        $todoNivelado = $semestresNivelados == count($infoValidar["CountIntersect"]) ? true : false;

        return array(
            "resultado" => $todoNivelado,
            "Estudiante" => $EstCodigo,
            "semestresNivelados" => $semestresNivelados,
            "CountIntersect" => $infoValidar["CountIntersect"],
            "CountDebeVer" => $infoValidar["CountDebeVer"],
            "CountMatriculado" => $infoValidar["CountMatriculado"],
        );
    }

    // Inicio consultarCursosMenos10Matriculados
    // Permite consultar los cursos con menos de 10 matriculados de un calendario especifico
    public function consultarCursosMenos10Matriculados($obj)
    {
        //Validaciones
        if (!isset($obj->CalCodigo) || !is_numeric($obj->CalCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar un calendario.",
                "consola" => "El codigo del calendario no es numérico o no se envio correctamente.",
            );
        }

        $codigosUsuarios = array();
        $codigosUsuarios[] = $_SESSION['pacademica']['datosVinculacionUsuario']['usuarioCodigo'];

        $CalCodigo = $obj->CalCodigo; //Contiene el codigo del calendario especifico
        $QueryUsuarioCreado = ''; // Contiene la query para consultar todas las unidades o las especificas del usuario.
        if ($_SESSION['pacademica']['datosVinculacionUsuario']['grupoId'] != 'PROGRAMACION_ACADEMICA_ADMINISTRADOR' && $_SESSION['pacademica']['datosVinculacionUsuario']['grupoId'] != 'PROGRAMACION_ACADEMICA_SUBADMINISTRADOR') {

            // Se valida si el usuario tiene usuarios vinculados para tambien consultar los cursos de ellos
            if (isset($_SESSION['pacademica']['datosVinculacionUsuario']['usuariosVinculados']) && $_SESSION['pacademica']['datosVinculacionUsuario']['usuariosVinculados'] != '') {
                foreach ($_SESSION['pacademica']['datosVinculacionUsuario']['usuariosVinculados'] as $usuario) {
                    if (isset($usuario["UsuCodigo"])) {
                        $codigosUsuarios[] = $usuario["UsuCodigo"];
                    }
                }
            }
            $implodeCodigoUsuarios = implode(',', $codigosUsuarios); // Convertimos los codigos encontrados a cadena separa por coma ,
            $QueryUsuarioCreado = "AND cur.usu_codigo IN ({$implodeCodigoUsuarios})"; //almacenamos el id del usuario para que solo muestre los cursos que ha creado.
        }

        // Consultamos el horario de la solicitud actual y el periodo
        $sql = "SELECT 
                uaa.uaa_codigo UaaCodigo,
                uaa.uaa_nombre_corto UaaNombreCorto,
                cur.cur_codigo CurCodigo,
                cal.cal_codigo CalCodigo,
                cal.cal_nombre CalNombre,
                sed.sed_codigo SedCodigo,
                sed.sed_nombre SedNombre,
                asi.asi_codigo AsiCodigo,
                asi.asi_nombre AsiNombre,
                asi.asi_nombre_corto AsiNombreCorto,
                nuc.nuc_nombre NucNombre,
                nuc.nuc_codigo NucCodigo,
                car.car_nombre CarNombre,
                car.car_codigo CarCodigo,
                cur.cur_cupo CurCupo,
                COUNT(mac.cur_codigo) TotalMatriculados,
                cur.cur_observaciones CurObservaciones
            FROM curso cur
            INNER JOIN asignatura asi ON asi.asi_codigo = cur.asi_codigo
            INNER JOIN uaa ON uaa.uaa_codigo = asi.uaa_codigo
            INNER JOIN calendario cal ON cal.cal_codigo = cur.cal_codigo
            INNER JOIN sede sed ON sed.sed_codigo = cur.sed_codigo
            LEFT JOIN nucleo nuc ON nuc.nuc_codigo = asi.nuc_codigo
            LEFT JOIN caracter car ON car.car_codigo = asi.car_codigo
            LEFT JOIN matricula_curso mac ON mac.cur_codigo = cur.cur_codigo AND mac.maa_codigo IN (1,2)
            WHERE cur.cal_codigo = {$CalCodigo}
            AND cur.cur_estado = 1
            {$QueryUsuarioCreado}
            GROUP BY
                cur.cur_codigo,
                asi.asi_codigo,
                asi.asi_nombre,
                asi.asi_nombre_corto,
                nuc.nuc_nombre,
                nuc.nuc_codigo,
                car.car_nombre,
                car.car_codigo,
                cur.cur_cupo,
                uaa.uaa_codigo,
                uaa.uaa_nombre_corto,
                cur.cur_observaciones,
                cal.cal_codigo,
                cal.cal_nombre,
                sed.sed_codigo,
                sed.sed_nombre
            HAVING COUNT(mac.cur_codigo) < 10 
                AND (
                    SELECT COUNT(eso.eso_actividad) Total FROM espacio_ocupacion_total eso WHERE eso.eso_actividad = cur.cur_codigo
                ) > 1
            ORDER BY uaa.uaa_nombre_corto, asi.asi_nombre ASC
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["mensaje"] = "No se pudo consultar el reporte de cursos con menos de 10 matriculados.";
            $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
            return $this->errorConsultarBd;
        }

        $response = $this->cnx->json;

        return array(
            "resultado" => true,
            "mensaje" => "El reporte se ha consultado correctamente.",
            "total" => COUNT($response),
            "data" => $response
        );
    }

    // Inicio obtenerEstudiantesCursos
    // Permite obtener los estudiantes matriculados de un curso especifico.
    public function obtenerEstudiantesCurso($obj)
    {

        //Validaciones
        if (!isset($obj->CurCodigo) || !is_numeric($obj->CurCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envió el codigo del curso.",
                "consola" => "El codigo del curso no se envió correctamenteo no es numerico. {$obj->CurCodigo}. " . __LINE__,
            );
        }

        $sql = "SELECT
                mac.mat_codigo MatCodigo,
                mac.paa_codigo PaaCodigo,
                mac.sippa_calcodigo CalCodigo,
                mac.sippa_plancodigo PlanCodigo,
                pla.pla_nombre PlaNombre,
                mat.est_codigo EstCodigo,
                per.per_nombre + ' ' + per.per_apellido PerNombreApellido,
                uaa.uaa_codigo UaaCodigo,
                uaa.uaa_nombre_corto UaaNombreCorto
            FROM
                matricula_curso mac
                INNER JOIN matricula mat ON mat.mat_codigo = mac.mat_codigo
                INNER JOIN estudiante est ON est.est_codigo = mat.est_codigo
                INNER JOIN persona per ON per.per_codigo = est.per_codigo
                INNER JOIN plan_academico pla ON pla.pla_codigo = mac.sippa_plancodigo
                INNER JOIN programa pro ON pro.pro_codigo = est.pro_codigo
                INNER JOIN uaa ON pro.uaa_codigo = uaa.uaa_codigo
            WHERE 
                mac.cur_codigo = {$obj->CurCodigo}
                AND mac.maa_codigo IN (1,2)
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["mensaje"] = "No se pudo consultar los estudiantes matriculados del curso {$obj->CurCodigo}.";
            $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
            return $this->errorConsultarBd;
        }

        $response = $this->cnx->json;

        if (count($response) > 0) {
            return array(
                "resultado" => true,
                "mensaje" => "Estudiantes matriculados en el curso {$obj->CurCodigo} consultados correctamente.",
                "total" => COUNT($response),
                "data" => $response
            );
        } else {
            return array(
                "resultado" => true,
                "mensaje" => "No se encontraron estudiantes matriculados en el curso {$obj->CurCodigo}."
            );
        }
    }

    // Inicio asignaturaPerdidaPreviamente
    // Permite validar si es una asignatura que el estudiante perdio previamente.
    private function obtenerPlanAcademico($EstCodigo)
    {
        //Validaciones
        if (!isset($EstCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envió el codigo del estudiante.",
                "consola" => "El codigo del estudiante no se envió correctamente. {$EstCodigo}. " . __LINE__,
            );
        }

        $sql = "SELECT 
                asi.asi_codigo AsiCodigo, 
                asi.asi_nombre AsiNombre, 
                asi.asi_nombre_corto AsiNombreCorto, 
                paa.paa_semestre PaaSemestre,
                paa.paa_codigo PaaCodigo,
                (SELECT MAX(CASE WHEN nt.mac_definitiva IS NULL THEN nt.esc_nombre ELSE CONVERT(VARCHAR, nt.mac_definitiva) END)
                FROM notas_total nt WITH (NOLOCK)
                WHERE (nt.mac_definitiva >= paa.paa_nota_minima OR nt.esc_codigo IN(2,6))
                    AND nt.maa_codigo IN(1,2)
                    AND nt.paa_codigo = paa.paa_codigo
                    AND nt.est_codigo = '{$EstCodigo}' 
                ) AS nota
            FROM asignatura asi WITH (NOLOCK)
                INNER JOIN plan_academico_asignatura paa WITH (NOLOCK) ON asi.asi_codigo = paa.asi_codigo
                LEFT JOIN nucleo nuc WITH (NOLOCK) ON asi.nuc_codigo = nuc.nuc_codigo
                LEFT JOIN uaa uaa WITH (NOLOCK) ON asi.uaa_codigo = uaa.uaa_codigo
            WHERE paa.pla_codigo IN (
                    SELECT ple.pla_codigo
                FROM plan_estudiante ple WITH(NOLOCK)
                WHERE ple.est_codigo = '{$EstCodigo}' AND ple.ple_estado = 1) and paa_plan_academico = 0 and paa.paa_estado=1
            ORDER BY paa.paa_semestre
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["mensaje"] = "No se pudo consultar el plan academico del estudiante {$EstCodigo}.";
            $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
            return $this->errorConsultarBd;
        }

        $response = $this->cnx->json;

        if (count($response) > 0) {
            return array(
                "resultado" => true,
                "mensaje" => "Plan academico del estudiante {$EstCodigo} consultado correctamente",
                "total" => COUNT($response),
                "data" => $response
            );
        } else {
            return array(
                "resultado" => false,
                "mensaje" => "No se encontraron estudiantes matriculados en el curso {$EstCodigo}."
            );
        }
    }

    // Inicio obtenerPaaMatriculadas
    // Permite consultar las asignaturas actualmente matriculadas (sin nota definitiva, es decir del periodo en curso) de un estudiante en una matricula especifica
    private function obtenerPaaMatriculadas($MatCodigo)
    {
        if (!isset($MatCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envió el codigo de la matricula.",
                "consola" => "El codigo de la matricula no se envió correctamente. {$MatCodigo}. " . __LINE__,
            );
        }
        $sql = "SELECT mac.paa_codigo PaaCodigo
            FROM matricula_curso mac WITH (NOLOCK)
            WHERE
                mac.mat_codigo = {$MatCodigo}
                AND mac.maa_codigo IN (1,2)
                AND mac.mac_definitiva IS NULL
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["mensaje"] = "No se pudo consultar los cursos matriculados de la matricula {$MatCodigo}.";
            $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
            return $this->errorConsultarBd;
        }

        $response = $this->cnx->json;

        if (count($response) > 0) {
            return array(
                "resultado" => true,
                "mensaje" => "Cursos de la matricula {$MatCodigo} consultado correctamente",
                "total" => COUNT($response),
                "data" => $response
            );
        } else {
            return array(
                "resultado" => false,
                "mensaje" => "No se encontraron cursos matriculados en la matricula {$MatCodigo}."
            );
        }
    }

    // Inicio asignaturaPerdidaPreviamente
    // Permite validar si un estudiante ya vio previamente una asignatura y la perdio.
    private function validarAsignaturaPerdidaPreviamente($EstCodigo, $PaaCodigo)
    {
        //Validaciones
        if (!isset($EstCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envió el codigo del estudiante.",
                "consola" => "El codigo del estudiante no se envió correctamente. {$EstCodigo}. " . __LINE__,
            );
        }
        if (!isset($PaaCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envió el paa del curso.",
                "consola" => "El codigo del paa no se envió correctamente. {$PaaCodigo}. " . __LINE__,
            );
        }
        // Verificamos si el estudiante ya vio un paa previamente y lo perdio.
        $sql = "SELECT COUNT(*) VecesPerdida
            FROM matricula_curso WITH (NOLOCK)
            WHERE 
                mat_codigo IN (
                    SELECT mat_codigo 
                    FROM matricula WITH (NOLOCK)
                    WHERE est_codigo = '{$EstCodigo}'
                ) 
                AND paa_codigo = {$PaaCodigo} 
                AND mac_definitiva < 3
                AND maa_codigo IN (1,2)
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["mensaje"] = "No se pudo consultar si el estudiante {$EstCodigo} perdio previamente el curso con PaaCodigo {$PaaCodigo}.";
            $this->errorConsultarBd["consola"] = $this->errorConsultarBd["mensaje"];
            return $this->errorConsultarBd;
        }

        $response = $this->cnx->json;

        if (count($response) > 0) {
            return array(
                "resultado" => true,
                "vecesPerdidas" => $response[0]['VecesPerdida'],
                "mensaje" => "{$EstCodigo} y {$PaaCodigo} consultado correctamente.",
            );
        } else {
            return array(
                "resultado" => false,
                "mensaje" => "No se encontraron cursos matriculados del estudiante {$EstCodigo} y PaaCodigo {$PaaCodigo}."
            );
        }
    }

    // Inicio validarCompletaPlanAcademico
    // Permite validar si un estudiante completa el plan academico con lo que tiene matriculado actualmente
    private function validarCompletaPlanAcademico($EstCodigo, $MatCodigo, $PlanAcademicoCompleto)
    {
        //Validaciones
        if (!isset($EstCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envió el codigo del estudiante.",
                "consola" => "El codigo del estudiante no se envió correctamente. {$EstCodigo}. " . __LINE__,
            );
        }
        if (!isset($MatCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envió el codigo de la matricula.",
                "consola" => "El codigo de la matricula no se envió correctamente. {$MatCodigo}. " . __LINE__,
            );
        }
        if (!is_array($PlanAcademicoCompleto)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envió el plan academico completo.",
                "consola" => "El plan academico no se envió correctamente. " . __LINE__,
            );
        }

        // Filtrar el array para obtener solamente las null
        $planAcademicoNotasNull = array_filter($PlanAcademicoCompleto, function ($registro) {
            return $registro["nota"] === null || $registro["nota"] === "";
        });

        // Obtenemos los cursos matriculados por el estudiante en la matricula especifica.
        $r_paaMatriculadas = $this->obtenerPaaMatriculadas($MatCodigo);
        $paaMatriculadas = ""; //Contiene la lista de PAA matriculadas
        // Verificamos que la respuesta sea correcta.
        if ($r_paaMatriculadas["resultado"] == true && count($r_paaMatriculadas["data"]) > 0) {
            $paaMatriculadas = $r_paaMatriculadas["data"];
        }

        // Verificamos que las materias pendientes (sin nota) esten efectivamente matriculadas,
        // no solo que las cantidades coincidan.
        $paaCodigosPendientes = array_column($planAcademicoNotasNull, 'PaaCodigo');
        $paaCodigosMatriculados = array_column($paaMatriculadas ?: [], 'PaaCodigo');
        $pendientesCubiertos = array_intersect($paaCodigosPendientes, $paaCodigosMatriculados);

        if (count($paaCodigosPendientes) > 0 && count($pendientesCubiertos) == count($paaCodigosPendientes)) {
            return array(
                "resultado" => true,
                "terminaPlan" => true,
                "mensaje" => "{$EstCodigo} termina plan académico.",
            );
        } else {
            return array(
                "resultado" => false,
                "mensaje" => "No se pudo validar los cursos matriculados con los que falta por ver del plan académico."
            );
        }
    }
}
