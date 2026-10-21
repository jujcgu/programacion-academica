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

require_once('../clases/Obsdocente.php');

switch ($obj->accion) {

    //Consulta general los ultimos 10 periodos
    case 1:
        $ad = new Obsdocente();
        $salida = $ad->consultarPeriodos();
        echo json_encode($salida);
    break;
    
    //Consulta los docentes de un periodo especifico.
    case 2:
        $ad = new Obsdocente();
        $salida = $ad->consultarDocentes($obj);
        echo json_encode($salida);
    break;

    //Consulta las observaciones de un docente en especifico en un periodo.
    case 3:
        $ad = new Obsdocente();
        $salida = $ad->consultarObservaciones($obj);
        echo json_encode($salida);
    break;

    //Inserta la observacion del docente seleccionado en el periodo seleccionado
    case 4:
        $ad = new Obsdocente();
        $salida = $ad->insertarObservaciones($obj);
        echo json_encode($salida);
    break;
    
}//fin switch
