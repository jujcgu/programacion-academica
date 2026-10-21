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

require_once('../clases/Peraca.php');

switch ($obj->accion) {

    //Consulta periodos academicos
    case 1:
        $ad = new Peraca();
        $salida = $ad->consultarPeriodos();
        echo json_encode($salida);
    break;

    //Consulta periodos por unidad
    case 2:
        $ad = new Peraca();
        $salida = $ad->consultarPeriodosUnidad($obj);
        echo json_encode($salida);
    break;

    //Quitar periodo unidad
    case 3:
        $ad = new Peraca();
        $salida = $ad->eliminarPeriodoUnidad($obj);
        echo json_encode($salida);
    break;

    //Crear/Actualizar Fecha de periodo academico
    case 4:
        $ad = new Peraca();
        $salida = $ad->crearFechaPeriodo($obj);
        echo json_encode($salida);
    break;
    

    
}//fin switch
