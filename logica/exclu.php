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

require_once('../clases/Exclu.php');

switch ($obj->accion) {

    //Consulta los planes academicos con exclusividad y sin exclusividad de un curso
    case 1:
        $ad = new Exclu();
        $salida = $ad->consultarExclusividadCurso($obj);
        echo json_encode($salida);
    break;
    
    //Asigna exclusivdad de un curso con un plan academico
    case 2:
        $ad = new Exclu();
        $salida = $ad->agregarExclusividad($obj);
        echo json_encode($salida);
    break;

    //Elimina exclusivdad de un curso con un plan academico
    case 3:
        $ad = new Exclu();
        $salida = $ad->eliminarExclusividad($obj);
        echo json_encode($salida);
    break;

}//fin switch
