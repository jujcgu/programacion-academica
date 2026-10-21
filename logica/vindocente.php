<?php  

session_start();

if(!isset($_SESSION['pacademica'])){
    header("Location: ../login1.php");
}

if($_SERVER['REQUEST_METHOD'] != 'POST'){
    $salida =  array("success"=>false, "message"=>"Solo peticiones POST");
    echo json_encode($salida);
    die;
}

$entrada = file_get_contents('php://input');
$obj = json_decode( $entrada , false);
header("Content-Type:application/json");

if($obj==null){
    $salida =  array("success"=>false, "message"=>"No se han enviado datos", "console"=>"No hay datos en la petición");
    echo json_encode($salida);
    die;
}

require_once('../clases/Vindocente.php');

switch ($obj->accion) {

    //Consulta los estudiantes con cupo personalizado autorizado para un curso especifico.
    case 1:
        $ad = new Vindocente();
        $salida = $ad->consultarDocente($obj);
        echo json_encode($salida);
    break;

    //Consulta la vinculacion de un docente en especifico.
    case 2:
        $ad = new Vindocente();
        $salida = $ad->consultarVinculacionesDocente($obj);
        echo json_encode($salida);
    break;

    //Consulta cursos de una vinculación especifica.
    case 3:
        $ad = new Vindocente();
        $salida = $ad->consultarCursosVinculacion($obj);
        echo json_encode($salida);
    break;

    //Consulta la auditoria de una vinculacion seleccionada
    case 4:
        $ad = new Vindocente();
        $salida = $ad->consultarAuditoriaVinculacion($obj);
        echo json_encode($salida);
    break;
    
}//fin switch
