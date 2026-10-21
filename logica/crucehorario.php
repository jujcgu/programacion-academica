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

require_once('../clases/Crucehorario.php');

switch ($obj->accion) {

    //Consulta las horas activas
    case 1:
        $ad = new Crucehorario();
        $salida = $ad->consultarHoras();
        echo json_encode($salida);
    break;

    //Consulta si tiene cruce de horario 
    case 2:
        $ad = new Crucehorario();
        $salida = $ad->consultarCruceHorario($obj);
        echo json_encode($salida);
    break;
    
}//fin switch
