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

switch ($obj->accion) {
        //Consulta cursos que no tienen horario.
    case 1:
        require_once('../clases/Csh.php');
        $ad = new Csh();
        $salida = $ad->consultarCursosSinHorario($obj);
        echo json_encode($salida);
        break;

        //Consulta cursos eliminados pero que aun tienen horario.
    case 2:
        require_once('../clases/Cech.php');
        $ad = new Cech();
        $salida = $ad->consultarCursosEliminadosConHorario($obj);
        echo json_encode($salida);
        break;

        //Consulta cursos sin matriculados pero que el curso tiene horario.
    case 3:
        require_once('../clases/Cmsh.php');
        $ad = new Cmsh();
        $salida = $ad->consultarCursosSinMatriculadosConHorarios($obj);
        echo json_encode($salida);
        break;

        //Consulta cursos virtuales de un calendario seleccionado
    case 4:
        require_once('../clases/Csv.php');
        $ad = new Csv();
        $salida = $ad->consultaCursosVirtuales($obj);
        echo json_encode($salida);
        break;

        //Consulta las modalidades de cursos
    case 5:
        require_once('../clases/Csv.php');
        $ad = new Csv();
        $salida = $ad->consultarTipoCurso();
        echo json_encode($salida);
        break;

        //Consulta los nucleos de asignaturas
    case 6:
        require_once('../clases/Cpn.php');
        $ad = new Cpn();
        $salida = $ad->consultarNucleos();
        echo json_encode($salida);
        break;

        //Consulta asignaturas por nucleos
    case 7:
        require_once('../clases/Cpn.php');
        $ad = new Cpn();
        $salida = $ad->consultarCursosNucleo($obj);
        echo json_encode($salida);
        break;

    case 8:
        require_once('../clases/Ceadmin.php');
        $ad = new Ceadmin();
        $salida = $ad->consultarCursosAdmin($obj);
        echo json_encode($salida);
        break;

    case 9:
        require_once('../clases/Ceadmin.php');
        $ad = new Ceadmin();
        $salida = $ad->consultarHistoricoCurso($obj);
        echo json_encode($salida);
        break;
    
    case 10:
        require_once('../clases/Ccuser.php');
        $ad = new Ccuser();
        $salida = $ad->consultarCursosporUsuario($obj);
        echo json_encode($salida);
        break;

    case 11:
        require_once('../clases/Ccuser.php');
        $ad = new Ccuser();
        $salida = $ad->consultarDetalleCursosSinHorarioUsuario($obj);
        echo json_encode($salida);
        break;
        
}//fin switch
