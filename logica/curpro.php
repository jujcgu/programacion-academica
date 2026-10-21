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

require_once('../clases/Curpro.php');

switch ($obj->accion) {

        //Consulta los calendarios activos
    case 1:
        $ad = new Curpro();
        $salida = $ad->consultarCalendario();
        echo json_encode($salida);
        break;

        //Consulta cursos programados simple
    case 2:
        $ad = new Curpro();
        $salida = $ad->consultarCursosProgramadosSimple($obj);
        echo json_encode($salida);
        break;

        //Consulta cursos programados con cupo y matriculados
    case 3:
        $ad = new Curpro();
        $salida = $ad->consultarCursosProgramadosMatriculados($obj);
        echo json_encode($salida);
        break;

        //Consulta cursos programados para primiparos
    case 4:
        $ad = new Curpro();
        $salida = $ad->consultarCursosProgramadosPrimiparos($obj);
        echo json_encode($salida);
        break;

        //Consulta eidy
    case 5:
        $ad = new Curpro();
        $salida = $ad->consultaEidy();
        echo json_encode($salida);
        break;
}//fin switch
