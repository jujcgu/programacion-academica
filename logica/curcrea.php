<?php

session_start();

if (!isset($_SESSION['pacademica'])) {
    header("Location: ../login1.php");
}

if ($_SERVER['REQUEST_METHOD'] != 'POST') {
    $salida =  array("success" => false, "message" => "Solo peticiones POST");
    echo json_encode($salida);
    die;
}

$entrada = file_get_contents('php://input');
$obj = json_decode($entrada, false);
header("Content-Type:application/json");

if ($obj == null) {
    $salida =  array("success" => false, "message" => "No se han enviado datos", "console" => "No hay datos en la petición");
    echo json_encode($salida);
    die;
}

require_once('../clases/Curcrea.php');

switch ($obj->accion) {

        //Consulta consulta las sedes de la universidad.
    case 1:
        $ad = new Curcrea();
        $salida = $ad->consultarSedes();
        echo json_encode($salida);
        break;

        //Consulta consulta las facultades de la universidad.
    case 2:
        $ad = new Curcrea();
        $salida = $ad->consultarFacultades();
        echo json_encode($salida);
        break;

        //Consulta las unidades vinculadas al usuario
    case 4:
        $ad = new Curcrea();
        $salida = $ad->consultarUnidadesUnificadas();
        echo json_encode($salida);
        break;

        //Consulta los cursos vinculados al usuario de un calendario.
        //Si es administrador le muestra todos los cursos de ese calendario.
    case 5:
        $ad = new Curcrea();
        $salida = $ad->consultarCursos($obj);
        echo json_encode($salida);
        break;

        //Consulta la informacion detallada de un curso en especifico
    case 6:
        $ad = new Curcrea();
        $salida = $ad->consultarDetalleCurso($obj);
        echo json_encode($salida);
        break;

        //Consulta la agenda de un docente
    case 7:
        $ad = new Curcrea();
        $salida = $ad->consultarAgendaDocente($obj);
        echo json_encode($salida);
        break;

        //Consulta la exclusividad de un curso en especifico.
    case 8:
        $ad = new Curcrea();
        $salida = $ad->consultarPlanExclusivo($obj);
        echo json_encode($salida);
        break;

        //Consulta la lista de asignaturas disponibles para una unidad, nucleo.
    case 9:
        $ad = new Curcrea();
        $salida = $ad->consultarAsignaturas($obj);
        echo json_encode($salida);
        break;

        //Consulta el propietario de una asignatura en especifico
    case 10:
        $ad = new Curcrea();
        $salida = $ad->consultarPropietarioAsignatura($obj);
        echo json_encode($salida);
        break;

        //Consulta exclusividad y totalidad de planes academicos de un curso.
    case 11:
        $ad = new Curcrea();
        $salida = $ad->consultarPlanExclusivoCurso($obj);
        echo json_encode($salida);
        break;

        //Elimina la exclusividad de un curso con un plan academico especifico.
    case 12:
        $ad = new Curcrea();
        $salida = $ad->quitarExclusividad($obj);
        echo json_encode($salida);
        break;

        //Agregar la exclusividad de un curso con un plan academico especifico.
    case 13:
        $ad = new Curcrea();
        $salida = $ad->ponerComoExclusivo($obj);
        echo json_encode($salida);
        break;

        //Consulta los docentes disponibles.
    case 14:
        $ad = new Curcrea();
        $salida = $ad->consultarDocentes($obj);
        echo json_encode($salida);
        break;

        //Actualiza un curso en especifico
    case 15:
        $ad = new Curcrea();
        $salida = $ad->actualizarCurso($obj);
        echo json_encode($salida);
        break;

        //Consulta el tipo del curso
    case 16:
        $ad = new Curcrea();
        $salida = $ad->consultarTipoCurso($obj);
        echo json_encode($salida);
        break;

        //Consulta los planes academicos con sus respectivas asignaturas
    case 17:
        $ad = new Curcrea();
        $salida = $ad->consultarPlanesAcademicos($obj);
        echo json_encode($salida);
        break;

        //Consulta los planes academicos para exclusividad
    case 18:
        $ad = new Curcrea();
        $salida = $ad->consultarPlanExclusivoCreacion($obj);
        echo json_encode($salida);
        break;

        //Crea un curso en especifico
    case 19:
        $ad = new Curcrea();
        $salida = $ad->crearCurso($obj);
        echo json_encode($salida);
        break;

        //Consulta los docentes con solicitudes de prestamo aprobadas.
    case 20:
        $ad = new Curcrea();
        $salida = $ad->consultarDocentesPrestados($obj);
        echo json_encode($salida);
        break;
}//fin switch
