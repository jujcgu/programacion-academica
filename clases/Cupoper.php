<?php

class Cupoper
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

    // Inicio funcion asignarCupoPersonalizado
    // Permite asignar cupo personalizado a un estudiante para un curso y subgrupo
    function asignarCupoPersonalizado($obj)
    {
        // Parametros: 
        // $obj->CurCodigo: Contiene el codigo del curso
        // $obj->EstCodigo: Contiene el codigo del estudiante
        // $obj->CurSubgrupo: Contiene el subgrupo del curso
        // $obj->Observacion: Contiene la observación por la que se le da cupo personalizado

        // Validacion de los parametros recibidos.
        if (!isset($obj->CurCodigo) ||  strlen($obj->CurCodigo) < 3) {
            $this->errorConsultarBd["mensaje"] = "No se ha seleccionado el curso.";
            $this->errorConsultarBd["consola"] = "No se ha enviado el código del curso.";
            return $this->errorConsultarBd;
        }
        if (!isset($obj->EstCodigo) ||  strlen($obj->EstCodigo) < 3) {
            $this->errorConsultarBd["mensaje"] = "No se ha seleccionado el estudiante.";
            $this->errorConsultarBd["consola"] = "No se ha enviado el código del estudiante.";
            return $this->errorConsultarBd;
        }
        if (!isset($obj->CurSubgrupo) ||  strlen($obj->CurSubgrupo) != 2) {
            $this->errorConsultarBd["mensaje"] = "No se ha seleccionado el subgrupo.";
            $this->errorConsultarBd["consola"] = "No se ha enviado el código del subgrupo.";
            return $this->errorConsultarBd;
        }
        if (!isset($obj->Observacion) ||  strlen(trim($obj->Observacion)) == 0) {
            $this->errorConsultarBd["mensaje"] = "No se ha ingresado la observación.";
            $this->errorConsultarBd["consola"] = "No se ha enviado la observación.";
            return $this->errorConsultarBd;
        }

        // Almacenamos el texto de la observación con formato UTF-8 para guardar los caracteress especiales.
        $obj->Observacion = utf8_decode(trim($obj->Observacion));


        // Obtenemos el calendario actual de matriculas
        $calendarioConsultado = $this->obtenerCalendarioMatriculaActual();
        if ($calendarioConsultado === false) {
            $this->errorConsultarBd["consola"] = "Falla en consulta de calendario actual.";
            return $this->errorConsultarBd;
        }

        // Obtenemos el grupo y la ampliación del curso.
        $sql = "SELECT 
            cur_grupo CurGrupo, 
            cur_ampliacion_cupo CurAmpliacion 
        FROM curso
		WHERE 
            cal_codigo IN({$this->calendarioActual}) AND 
            cur_codigo= {$obj->CurCodigo}
		";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Falla en consulta la ampliación del curso";
            return $this->errorConsultarBd;
        }

        $CurGrupo = $this->cnx->json[0]['CurGrupo']; //01 o 02
        $CurAmpliacion = $this->cnx->json[0]['CurAmpliacion'];

        // Consulta cuantos cupos personalizados se han dado al curso
        $sql = "SELECT 
            count(*) TotalCupoAutorizado
		FROM 
            cupo_autorizacion 
        WHERE 
            cua_curso = {$obj->CurCodigo}
        ";
        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["mensaje"] = "Error al consultar cuántos cupos se han dado. Contactar con CITCD.";
            $this->errorConsultarBd["consola"] = "Ha fallado consulta cuantos cupos se han dado.";
            return $this->errorConsultarBd;
        }
        $TotalCupoAutorizado = $this->cnx->json[0]['TotalCupoAutorizado'];

        //si la ampliacion es menor o igual a los cupos dados
        if ($CurAmpliacion <= $TotalCupoAutorizado) {
            $this->errorConsultarBd["mensaje"] = "Debe aumentar la ampliación del curso. Actualmente está en {$CurAmpliacion} y cuenta con {$TotalCupoAutorizado} estudiantes asignados.";
            $this->errorConsultarBd["consola"] = "La ampliacion es menor al total cupos dados. 
				ampliacionActual: {$CurAmpliacion}, totalCuposDados: {$TotalCupoAutorizado}";
            return $this->errorConsultarBd;
        }

        // Guarda el cupo personalizado 
        //////// grupo en base de datos debe tener permiso de insert (grupo_autorizacion_cupo)
        $sql = "INSERT INTO 
            cupo_autorizacion (
                cua_curso, 
                cua_grupo, 
                cua_subgrupo, 
                cua_estudiante, 
                cua_observacion
            )
            VALUES ( 
                {$obj->CurCodigo}, 
                '{$CurGrupo}', 
                '{$obj->CurSubgrupo}', 
                '{$obj->EstCodigo}',  
                '{$obj->Observacion}'
            ) 
        ";

        if (!$this->cnx->sentencia($sql)) {
            $this->errorSentenciaBd["mensaje"] = "Error guardar el cupo personalizado. 
				Recargue la página e intente de nuevo.";
            $this->errorSentenciaBd["consola"] = "Ha fallado insert en cupo personalizado.";
            return $this->errorSentenciaBd;
        } else {
            return array(
                "resultado" => true,
                "mensaje" => "Cupo personalizado guardado con éxito"
            );
        }
    }

    // Inicio funcion validarEstudianteCurso
    // Permite validar si a un estudiante especifico se le puede asignar cupo personalizado a un curso especifico.
    function validarEstudianteCurso($obj)
    {
        //Parametros:
        // $obj->CurCodigo: Contiene el código del curso.
        // $obj->EstCodigo: Contiene el código del estudiante.

        if (!isset($obj->CurCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el código del curso.",
                "consola" => "El codigo del curso cur_codigo no viene. " . $obj->CurCodigo,
            );
        }

        if (!isset($obj->EstCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el código estudiante.",
                "consola" => "El codigo del estudiante est_codigo no viene. " . $obj->EstCodigo,
            );
        }

        // Almacenamos variables y creamos 2 variables de estado
        $esParteDelPlan = false;
        $esEquivalencia = false;
        $estudiante = $obj->EstCodigo;
        $curso = $obj->CurCodigo;


        //obtiene el calendario actual
        $calendarioConsultado = $this->obtenerCalendarioMatriculaActual();
        if ($calendarioConsultado === false) {
            $this->errorConsultarBd["consola"] = "Falla en consulta de calendario actual.";
            return $this->errorConsultarBd;
        }

        //obtiene los datos basicos del estudiante
        $datosEstudiante = $this->obtenerDatosBasicosEstudiante($estudiante);
        if ($datosEstudiante === false || is_null($datosEstudiante)) {
            return array(
                "resultado" => false,
                "mensaje" => "El estudiante no está matriculado en el periodo actual. Debe tener matrícula.",
                "consola" => ""
            );
        }

        //saber si es un curso exclusivo para el plan del estudiante
        $r = $this->esCursoExclusivoParaPlanDelEstudiante($curso, $datosEstudiante['PlaCodigo']);
        if ($r["resultado"] === false) {
            $this->errorConsultarBd["consola"] = "Falla en consulta esCursoExclusivoParaPlanDelEstudiante";
            return $this->errorConsultarBd;
        } else {
            if ($r["esCursoExclusivoPlan"] === true) {
                return array(
                    "resultado" => true,
                    "mensaje" => "Es un curso exclusivo para el plan del estudiante. Se puede dar cupo personalizado.",
                    "darCupoPersonalizado" => true,
                    "datosEstudiante" => $datosEstudiante
                );
            }
        }


        //saber si una asignatura es parte del plan academico del estudiante
        $r = $this->esParteDelPlanAcademico($curso, $datosEstudiante['PlaCodigo']);

        if ($r["resultado"] === false) {
            $this->errorConsultarBd["consola"] = "Falla en consulta tiene equivalencia";
            return $this->errorConsultarBd;
        } else {
            if ($r["esParteDelPlan"] === true) {
                $esParteDelPlan = true;
            } else {
                $esParteDelPlan = false;
            }
        }


        //saber si una asignatura tiene equivalencia con el plan del estudiante
        $r = $this->tieneEquivalencia($curso, $datosEstudiante['PlaCodigo']);

        if ($r["resultado"] === false) {
            $this->errorConsultarBd["consola"] = "Falla en consulta tiene equivalencia";
            return $this->errorConsultarBd;
        } else {
            if ($r["esEquivalencia"] === true) {
                $esEquivalencia = true;
            } else {
                $esEquivalencia = false;
            }
        }

        //saber si una asignatura tiene equivalencia con otra asignatura que no es del plan del estudiante
        $r = $this->tieneEquivalenciaFueraPlan($curso, $estudiante);

        if ($r["resultado"] === false) {
            $this->errorConsultarBd["consola"] = "Falla en consulta tiene equivalencia fuera plan";
            return $this->errorConsultarBd;
        } else {
            if ($r["esEquivalencia"] === true) {
                $esEquivalencia = true;
            } else {
                $esEquivalencia = false;
            }
        }

        //si no es parte del plan ni es equivalencia
        if (!$esParteDelPlan && !$esEquivalencia) {
            return array(
                "resultado" => true,
                "mensaje" => "La asignatura no es parte del plan del estudiante. Tampoco tiene equivalencias. No se puede dar cupo personalizado.",
                "darCupoPersonalizado" => false,
                "datosEstudiante" => $datosEstudiante
            );
        }

        $mjeSalida = "";

        if ($esEquivalencia) {
            $mjeSalida = $mjeSalida . " La asignatura tiene equivalencia.";
        }
        if ($esParteDelPlan) {
            $mjeSalida = $mjeSalida . " La asignatura es parte del plan del estudiante.";
        }

        //-----consulta si tiene prerequisito-------//
        $r_paa_requisito = $this->obtenerAsignaturaPreRequisito($estudiante, $datosEstudiante['PlaCodigo'], $curso);

        if ($r_paa_requisito["resultado"] === false) { //error en el query
            $this->errorConsultarBd["consola"] = "Falla en consulta obtener asignatura prerequisito";
            return $this->errorConsultarBd;
        }

        if (is_null($r_paa_requisito["PaaCodigo"])) {
            return array(
                "resultado" => true,
                "mensaje" => "La asignatura no tiene prerequisitos. Sí se puede dar cupo personalizado.",
                "darCupoPersonalizado" => true,
                "datosEstudiante" => $datosEstudiante
            );
        }

        //-----verifica si el prerequisito esta aprobado-------
        $r_requisito_aprobado = $this->esUnaAsignaturaCursadaYAprobada($estudiante, $r_paa_requisito["PaaCodigo"]);

        if ($r_requisito_aprobado["resultado"] === false) { //error en el query
            $this->errorConsultarBd["consola"] = "Falla en consulta requisito asignatura aprobada";
            return $this->errorConsultarBd;
        }

        if ($r_requisito_aprobado["esAprobada"] === false) {
            return array(
                "resultado" => true,
                "mensaje" => "La asignatura tiene prerequisito pero aún no lo ha aprobado. No se puede dar cupo personalizado.",
                "darCupoPersonalizado" => false,
                "datosEstudiante" => $datosEstudiante
            );
        } else {
            return array(
                "resultado" => true,
                "mensaje" => " La asignatura tiene prerequisito aprobado. Sí se puede dar cupo personalizado.",
                "darCupoPersonalizado" => true,
                "datosEstudiante" => $datosEstudiante
            );
        }
    }

    // Inicio funcion consultarSubgrupo
    // Permite consultar los subgrupos de un curso especifico
    function consultarSubgrupo($obj)
    {
        // Parametros:
        // $obj->CurCodigo: Contiene el codigo del curso


        $sql = "SELECT 
            eso_subgrupo EsoSubGrupo
		FROM 
            espacio_ocupacion 
        WHERE
		    eso_actividad = {$obj->CurCodigo}
		GROUP BY 
            eso_subgrupo
		";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Falla en consulta buscar subgrupos";
            return $this->errorConsultarBd;
        }

        $r_subgrupos = $this->cnx->json;
        $subgrupos = array();

        foreach ($r_subgrupos as $fila) {
            $temp = array("SubGrupoNombre" => $fila['EsoSubGrupo']);
            array_push($subgrupos, $temp);
        }

        return $subgrupos;
    }

    // Inicio funcion esUnaAsignaturaCursadaYAprobada
    // Permite consultar si una asignatura de los prerrequisitos ya esta cursada y aprobada.
    function esUnaAsignaturaCursadaYAprobada($EstCodigo, $PaaCodigo)
    {
        //Parametros:
        //$EstCodigo: Contiene el codigo del curso.
        //$PaaCodigo: Contiene el codigo del plan academico asignatura del prerrequisito
        $sql = "SELECT  
            asi.asi_codigo AsiCodigo, 
            mac.paa_codigo PaaCodigo, 
            asi.asi_nombre_corto AsiNombreCorto, 
		    CASE WHEN 
                cur.cur_codigo IS NULL 
            THEN 
                'homologado' 
            ELSE 
                'normal' 
            END AS tipo
		FROM matricula_curso mac
		INNER JOIN matricula mat on mat.mat_codigo = mac.mat_codigo
		INNER JOIN estudiante est on est.est_codigo = mat.est_codigo
		INNER JOIN plan_academico_asignatura paa on paa.paa_codigo = mac.paa_codigo
		INNER JOIN asignatura asi on asi.asi_codigo = paa.asi_codigo
		LEFT JOIN curso cur on cur.cur_codigo = mac.cur_codigo
		WHERE 
            mat.mat_estado = 'A' AND 
            est.est_codigo = '{$EstCodigo}' AND
		    mac.maa_codigo in (1,2) AND 
            mac.paa_codigo = {$PaaCodigo} AND
		    (
                mac.mac_definitiva >= 3 OR 
                mac.esc_codigo = 2
            )
		";

        if (!$this->cnx->consultar($sql)) {
            return array(
                "resultado" => false
            );
        }

        $result = $this->cnx->json[0]['AsiCodigo'];

        if (count($result) > 0) {
            return array(
                "resultado" => true,
                "esAprobada" => true
            );
        } else {
            return array(
                "resultado" => true,
                "esAprobada" => false
            );
        }
    }

    // Inicio funcion obtenerAsignaturaPreRequisito
    // Permite consultar los prerrequisitos del curso especifico
    function obtenerAsignaturaPreRequisito($EstCodigo, $PlaCodigo, $CurCodigo)
    {
        // Parametros:
        // $EstCodigo: Contiene el codigo del estudiante.
        // $PlaCodigo: Contiene el codigo del plan academico del estudiante.
        // $CurCodigo: Contiene el codigo del curso.

        $sql = "DECLARE @asi_codigo int 
            SELECT 
                @asi_codigo = asi_codigo 
            FROM 
                curso 
            WHERE 
                cur_codigo = {$CurCodigo}

            SELECT 
                a.asi_codigo AsiCodigo, 
                a.asi_nombre AsiNombre, 
                a.asi_nombre_corto AsiNombreCorto, 
                u.uaa_codigo UaaCodigo, 
                u.uaa_nombre UaaNombre, 
                u.uaa_nombre_corto UaaNombreCorto, 
                s.sed_codigo SedCodigo, 
                s.sed_nombre SedNombre, 
                paa.paa_codigo PaaCodigo, 
                paa.paa_semestre PaaSemestre, 
                paa.paa_credito PaaCredito, 
                paa.paa_programable PaaProgramable, 
                paa.paa_multi_asignatura PaaMultiAsignatura, 
                n.nuc_codigo NucCodigo, 
                n.nuc_nombre NucNombre, 
                n.nuc_acronimo NucAcronimo 
            FROM dbo.plan_academico_asignatura paa 
            INNER JOIN dbo.plan_estudiante pe ON paa.pla_codigo = pe.pla_codigo 
            INNER JOIN dbo.asignatura a ON paa.asi_codigo = a.asi_codigo 
            INNER JOIN dbo.uaa u ON a.uaa_codigo = u.uaa_codigo 
            INNER JOIN dbo.nucleo n ON a.nuc_codigo = n.nuc_codigo 
            INNER JOIN dbo.sede s ON u.sed_codigo = s.sed_codigo 
            WHERE pe.est_codigo = '{$EstCodigo}' AND pe.pla_codigo = {$PlaCodigo}
            AND paa.asi_codigo IN ( 
                SELECT 
                    p2.asi_requisito 
                FROM dbo.prerrequisito p2 
                INNER JOIN dbo.plan_estudiante pe2 ON p2.pla_codigo = pe2.pla_codigo 
                WHERE p2.asi_requisito IS NOT NULL AND p2.asi_codigo = @asi_codigo
                AND pe2.est_codigo = pe.est_codigo   AND pe2.pla_codigo = pe.pla_codigo 
            ) ORDER BY paa.paa_semestre ASC, a.asi_nombre ASC;
		";

        if (!$this->cnx->consultar($sql)) {
            return array(
                "resultado" => false
            );
        }

        $PaaCodigo = $this->cnx->json[0]['PaaCodigo'];

        if (is_null($PaaCodigo)) {
            return array(
                "resultado" => true,
                "PaaCodigo" => NULL
            );
        } else {
            return array(
                "resultado" => true,
                "PaaCodigo" => $PaaCodigo
            );
        }
    }

    // Inicio funcion tieneEquivalenciaFueraPlan
    // Permite consultar si el curso tiene equivalencia fuera del plan del estudiante
    function tieneEquivalenciaFueraPlan($CurCodigo, $EstCodigo)
    {
        // Parametros:
        // $CurCodigo: contiene el codigo de curso.
        // $EstCodigo: contiene el codigo del estudiante.

        $sql = "SELECT 
            equ.asi_equivalencia AsiEquivalencia, 
            equ.asi_codigo AsiCodigo
		FROM equivalencia equ
		INNER JOIN (
			SELECT DISTINCT asi_codigo AsiCodigo 
            FROM plan_academico_asignatura 
			WHERE pla_codigo = (
                SELECT TOP 1 
                    pla_codigo PlaCodigo 
                FROM 
                    plan_estudiante 
                WHERE 
                    est_codigo = '{$EstCodigo}' AND ple_estado = 1
            )
		)AS asi_plan ON asi_plan.AsiCodigo = equ.asi_codigo
		WHERE equ.asi_equivalencia = (
            SELECT asi_codigo 
            FROM curso 
            WHERE cur_codigo = {$CurCodigo}
        )";

        if (!$this->cnx->consultar($sql)) {
            return array(
                "resultado" => false
            );
        }

        $result = $this->cnx->json;


        if (count($result) == 0) {
            return array(
                "resultado" => true,
                "esEquivalencia" => false
            );
        } else {
            return array(
                "resultado" => true,
                "esEquivalencia" => true
            );
        }
    }

    // Inicio funcion tieneEquivalencia
    // Permite consultar si el curso tiene equivalencia con el plan del estudiantes
    function tieneEquivalencia($CurCodigo, $PlaCodigo)
    {
        // Parametros:
        // $CurCodigo: Contiene el codigo del curso.
        // $PlaCodigo: Contiene el codigo del plan academico del estudiante.

        // $sql="
        // select a.pla_codigo as plan_estudiante, 
        // b.pla_codigo as plan_equivalencia
        //  from
        // (
        // 	--saca el plan del estudiante 
        // 	select pla_codigo 
        // 	from plan_estudiante ple
        // 	where ple.est_codigo like '".$estudiante."'
        // 	and ple.ple_estado=1
        // ) as a
        // inner join (
        // 	--saca los planes que tienen como equivalencia la asignatura dada
        // 	select equ.pla_codigo 
        // 	from curso cur
        // 	inner join asignatura asi on (cur.asi_codigo=asi.asi_codigo)
        // 	inner join equivalencia equ on (asi.asi_codigo=equ.asi_equivalencia)
        // 	where cur.cur_codigo=".$curso."
        // )as b on (a.pla_codigo=b.pla_codigo)";

        $sql = "SELECT 
            equ.pla_codigo 
        FROM 
            curso cur
        INNER JOIN asignatura asi ON cur.asi_codigo = asi.asi_codigo
        INNER JOIN equivalencia equ ON asi.asi_codigo = equ.asi_equivalencia
        WHERE 
            cur.cur_codigo = {$CurCodigo} AND
            equ.pla_codigo = {$PlaCodigo}
        ";

        if (!$this->cnx->consultar($sql)) {
            return array(
                "resultado" => false
            );
        }

        $result = $this->cnx->json;

        if (count($result) == 0) {
            return array(
                "resultado" => true,
                "esEquivalencia" => false
            );
        } else {
            return array(
                "resultado" => true,
                "esEquivalencia" => true
            );
        }
    }

    // Inicio funcion esParteDelPlanAcademico
    // Permite consultar si el curso hace parte del plan academico del estudiante
    function esParteDelPlanAcademico($CurCodigo, $PlaCodigo)
    {
        //Parametros: 
        //$CurCodigo: Contiene el codigo del curso.
        //$EstCodigo: Contiene el codigo del estudiante.

        // Query anterior.
        // SELECT 
        //     a.pla_codigo, 
        //     b.pla_codigo
        //     FROM
        // (
        //     --Saca el plan del estudiante 
        //     SELECT 
        //         pla_codigo
        //     FROM 
        //         plan_estudiante ple
        //     WHERE 
        //         ple.est_codigo like '20171157493'
        //     AND 
        //         ple.ple_estado = 1
        // ) AS a
        // INNER JOIN (
        //     --saca los planes que tienen una asignatura dada
        //     SELECT 
        //         paa.pla_codigo
        //     FROM 
        //         curso cur
        //     INNER JOIN asignatura asi ON cur.asi_codigo = asi.asi_codigo
        //     INNER JOIN plan_academico_asignatura paa ON asi.asi_codigo = paa.asi_codigo
        //     WHERE 
        //         cur.cur_codigo = 163832
        // ) AS b ON a.pla_codigo = b.pla_codigo

        //Se debe revisar esta query, se trato de optimizar.
        $sql = "SELECT 
            paa.pla_codigo PlaCodigo
        FROM 
            curso cur
        INNER JOIN asignatura asi ON cur.asi_codigo = asi.asi_codigo
        INNER JOIN plan_academico_asignatura paa ON asi.asi_codigo = paa.asi_codigo
        WHERE 
            cur.cur_codigo = {$CurCodigo} AND
            paa.pla_codigo = {$PlaCodigo}
        ";

        if (!$this->cnx->consultar($sql)) {
            return array(
                "resultado" => false
            );
        }

        $r_plan_academico = $this->cnx->json;

        if (count($r_plan_academico) == 0) {
            return array(
                "resultado" => true,
                "esParteDelPlan" => false
            );
        } else {
            return array(
                "resultado" => true,
                "esParteDelPlan" => true
            );
        }
    }

    // Inicio funcion esCursoExclusivoParaPlanDelEstudiante
    // Permite consultar si el curso tiene exclusividad con el plan academico del estudiante
    function esCursoExclusivoParaPlanDelEstudiante($CurCodigo, $PlaCodigo)
    {
        //Parametros: 
        //$CurCodigo: Contiene el codigo del curso.
        //$PlaCodigo: Contiene el codigo del plan academico del estudiante.

        $sql = "SELECT 
            cur_codigo CurCodigo, 
            pla_codigo PlaCodigo 
        FROM 
            curso_plan 
        WHERE 
            cur_codigo = {$CurCodigo}
        ";

        if (!$this->cnx->consultar($sql)) {
            return array("resultado" => false);
        }

        $planExclusivo = "";
        $planExclusivo = $this->cnx->json[0]['pla_codigo'];

        if (!isset($planExclusivo) || $planExclusivo == "") {
            return array(
                "resultado" => true,
                "esCursoExclusivoPlan" => false
            );
        } else {
            if (strval($PlaCodigo) != strval($planExclusivo)) {
                return array(
                    "resultado" => true,
                    "esCursoExclusivoPlan" => false
                );
            } else {
                return array(
                    "resultado" => true,
                    "esCursoExclusivoPlan" => true
                );
            }
        }
    }

    // Inicio funcion obtenerDatosBasicosEstudiante
    // Permite consultar los datos basicos relacionados a un estudiante especifico
    function obtenerDatosBasicosEstudiante($EstCodigo)
    {
        //Parametros: 
        //$EstCodigo: Contiene el codigo del estudiante.
        $sql = "SELECT TOP 1 
            per.per_nombre+' '+per.per_apellido AS PerNombreApellido,
		    est.est_codigo EstCodigo, 
            uaa.uaa_nombre_corto UaaNombreCorto,  
            per.per_identificacion PerIdentificacion,
		    ple.pla_codigo PlaCodigo, 
            pla.pla_nombre PlaNombre
		FROM estudiante est
		INNER JOIN matricula mat ON mat.est_codigo = est.est_codigo
		INNER JOIN programa pro ON est.pro_codigo = pro.pro_codigo
		INNER JOIN persona per ON per.per_codigo = est.per_codigo
		INNER JOIN uaa uaa ON uaa.uaa_codigo = pro.uaa_codigo
		INNER JOIN plan_estudiante ple ON ple.est_codigo = est.est_codigo
		INNER JOIN plan_academico pla ON pla.pla_codigo = ple.pla_codigo
		WHERE ple.ple_estado = 1 AND est.est_codigo LIKE '{$EstCodigo}'  
		AND mat.cal_codigo IN ({$this->calendarioActual})
		";

        if (!$this->cnx->consultar($sql)) {
            return false;
        }
        $datosEstud = $this->cnx->json[0];

        return $datosEstud;
    }

    //Inicio funcion eliminarCupoPersonalizado
    //Permite eliminar el cupo personalizado para un estudiante de un curso en concreto
    function eliminarCupoPersonalizado($obj)
    {
        //Parametros:
        //$obj->CuaCodigo: El codigo de referencia con el que se guarda el cupo personalizado
        //$obj->CurCodigo: El codigo del curso al que se le guarda el cupo
        //$obj->EstCodigo: El codigo del estudiante al que se le guarda el cupo
        //$obj->PerNombreApellido: El nombre y apellido del estudiante al que se le guardo el cupo personalizado

        //Validamos que la variable del codigo del cupo no venga vacia.
        if (!isset($obj->CuaCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el código del cupo personalizado.",
                "consola" => "El codigo del cupo cua_codigo no viene. " . $obj->CuaCodigo,
            );
        }


        $this->cnx->sentencia("BEGIN TRAN");

        $sql = "DELETE FROM 
            cupo_autorizacion
		WHERE 
            cua_codigo = {$obj->CuaCodigo}
        ";

        //Se ejecuta el dlete y se verifica que se ejecuto correctamente.
        if (!$this->cnx->sentencia($sql)) {
            $this->errorSentenciaBd["mensaje"] = "Error al eliminar el cupo personalizado del curso {$obj->CurCodigo} al estudiante {$obj->EstCodigo}.";
            $this->errorSentenciaBd["consola"] = "Error al eliminar el cupo personalizado con codigo: {$obj->CuaCodigo}";
            $this->cnx->sentencia("ROLLBACK TRAN"); //Se realiza un rollback si se encuentra un error
            return $this->errorSentenciaBd;
        }

        $this->cnx->sentencia("COMMIT TRAN");

        return array(
            "resultado" => true,
            "mensaje" => "El cupo personalizado para el estudiante {$obj->EstCodigo} del curso {$obj->CurCodigo} se elimino correctamente."
        );
    }

    //Inicio funcion obtenerCalendarioMatriculaActual
    //Permite obtener el calendario actual de matriculas.
    function obtenerCalendarioMatriculaActual()
    {

        //Calendario activos actualmente para pruebas
        // 208	120	20211A
        // 209	120	20211D

        $sql = "SELECT 
            wep_valor 
        FROM 
            web_parametro 
        WHERE 
            wep_nombre = 'MATRICULA_PREGRADO_CALENDARIO_ACTUAL' ";

        if (!$this->cnx->consultar($sql)) {
            return false;
        }

        $this->calendarioActual = $this->cnx->json[0]['wep_valor'];
    }

    //Inicio funcion consultarCuposPersonalizadosCurso
    //Permite listar los estudiantes que cuentan con cupo personalizado para un curso en concreto.
    function consultarCuposPersonalizadosCurso($obj)
    {
        //Parametros:
        //$obj->CurCodigo: Codigo del curso tipo numerico generalmente de 6 cifras.

        //Validamos que la variable no venga vacia.
        if (!isset($obj->CurCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo del curso.",
                "consola" => "El codigo del curso no viene. " . $obj->CurCodigo,
            );
        }

        //Validamos que el curso sea numerico y no traiga un formato diferente.
        if (!is_numeric($obj->CurCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "El codigo del curso no tiene un formato correcto.",
                "consola" => "El codigo del curso no es numerico, " . $obj->CurCodigo,
            );
        }

        $CurCodigo = $obj->CurCodigo;

        $sql = "SELECT 
            cua.cua_codigo CuaCodigo, 
            cua.cua_curso CuaCurso, 
            cua.cua_grupo CuaGrupo, 
            cua.cua_subgrupo CuaSubGrupo, 
            cua.cua_estudiante CuaEstudiante, 
            cua.cua_observacion CuaObservacion, 
            CONVERT(DATE,cua.cua_fecha) AS CuaFecha,
            CONVERT(TIME,cua.cua_fecha) AS CuaHora,
            per.per_nombre +' '+per.per_apellido AS PerNombreApellido, 
            per.per_identificacion PerIdentificacion,
            uaa.uaa_nombre_corto UaaNombreCorto
        FROM cupo_autorizacion cua
        INNER JOIN estudiante est ON cua.cua_estudiante = est.est_codigo
        INNER JOIN persona per ON est.per_codigo = per.per_codigo
        INNER JOIN programa pro ON pro.pro_codigo = est.pro_codigo
        INNER JOIN uaa uaa ON uaa.uaa_codigo = pro.uaa_codigo
        WHERE cua.cua_curso = {$CurCodigo}
        ORDER BY cua.cua_subgrupo, per.per_nombre";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar los cupos autorizados del curso";
            return $this->errorConsultarBd;
        }

        $r_estudiantes = $this->cnx->json;

        if (count($r_estudiantes) > 0) {
            for ($i = 0; $i < count($r_estudiantes); $i++) {
                $explode = explode(".", $r_estudiantes[$i]["CuaHora"]);
                $r_estudiantes[$i]["CuaFechaHora"] = $r_estudiantes[$i]["CuaFecha"] . " " . $explode[0];
            }
        }

        return array(
            "resultado" => true,
            "mensaje" => "Cupos personalizados autorizados consultados correctamente.",
            "data" => $r_estudiantes
        );
    }
}
