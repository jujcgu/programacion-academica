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
    $salida =  array("success" => false, "message" => "No se han enviado datos", "console" => "No hay datos en la peticion");
    echo json_encode($salida);
    die;
}

require_once('../clases/Rcurhi.php');

switch ($obj->accion) {
    // Consulta cursos con horario incompleto.
    case 1:
        $ad = new Rcurhi();
        $salida = $ad->consultarCursosHorarioIncompleto($obj);
        echo json_encode($salida);
        break;

    // Consulta si el usuario autenticado es administrador.
    case 2:
        $ad = new Rcurhi();
        $salida = $ad->consultarAdministrador();
        echo json_encode($salida);
        break;
}
