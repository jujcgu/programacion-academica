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

require_once('../clases/Curesp.php');

switch ($obj->accion) {

        //Consulta los tipos de cursos que hay disponibles
    case 1:
        $ad = new Curesp();
        $salida = $ad->consultarTipoCurso();
        echo json_encode($salida);
        break;

        //Consulta el tipo actual del curso
    case 2:
        $ad = new Curesp();
        $salida = $ad->consultarTipoCursoActual($obj);
        echo json_encode($salida);
        break;

        //Guarda el tipo de curso actual
    case 3:
        $ad = new Curesp();
        $salida = $ad->guardarTipoCursoActual($obj);
        echo json_encode($salida);
        break;
}//fin switch
