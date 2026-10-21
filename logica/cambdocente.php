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

require_once('../clases/Cambdocente.php');

switch ($obj->accion) {

        //Consulta para obtener los docentes de un curso por subgrupo
    case 1:
        $ad = new Cambdocente();
        $salida = $ad->consultarSubgrupoCurso($obj);
        echo json_encode($salida);
        break;

        //Consulta el horario de un curso, subgrupo y docente
    case 2:
        $ad = new Cambdocente();
        $salida = $ad->consultarHorario($obj);
        echo json_encode($salida);
        break;

        //Consulta la vinculacion de los docentes vinculados para el calendario del curso
    case 3:
        $ad = new Cambdocente();
        $salida = $ad->consultarDocente($obj);
        echo json_encode($salida);
        break;

        //Realiza el cambio de docente de un curso en horarios seleccionados
    case 4:
        $ad = new Cambdocente();
        $salida = $ad->cambiarDocente($obj);
        echo json_encode($salida);
        break;

        // Consulta los docentes prestados para el periodo del curso seleccionado
    case 5:
        $ad = new Cambdocente();
        $salida = $ad->consultarDocentesPrestados($obj);
        echo json_encode($salida);
        break;

        // Consulta los docentes prestados para el periodo del curso seleccionado
    case 6:
        $ad = new Cambdocente();
        $salida = $ad->eliminarHorarioSeleccionado($obj);
        echo json_encode($salida);
        break;
        // Consulta la carga detallada del docente
    case 7:
        $ad = new Cambdocente();
        $salida = $ad->consultarCargaDocente($obj);
        echo json_encode($salida);
        break;

        // Consulta si cambio docente esta habilitado por apertura de programacion o solicitud especifica
    case 8:
        $ad = new Cambdocente();
        $salida = $ad->consultarPermisoCambioDocente($obj);
        echo json_encode($salida);
        break;
}//fin switch
