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

require_once('../clases/Sirea.php');

switch ($obj->accion) {

    //Consulta el sitio de realizacion de un curso
    case 1:
        $ad = new Sirea();
        $salida = $ad->consultarExclusividadCurso($obj);
        echo json_encode($salida);
    break;

    //Consulta el sitio de realizacion de un curso
    case 2:
        $ad = new Sirea();
        $salida = $ad->consultarSitiosExternos($obj);
        echo json_encode($salida);
    break;

    //Guarda el sitio externo de realizacion para un curso.
    case 3:
        $ad = new Sirea();
        $salida = $ad->guardarSitioRealizacion($obj);
        echo json_encode($salida);
    break;

    //Elimina el sitio externo de realizacion para un curso.
    case 4:
        $ad = new Sirea();
        $salida = $ad->eliminarSitioRealizacion($obj);
        echo json_encode($salida);
    break;

    //Consulta subgrupos de un curso
    case 5:
        $ad = new Sirea();
        $salida = $ad->consultarSubGrupo($obj);
        echo json_encode($salida);
    break;

    //Consulta subgrupos de un curso
    case 5:
        $ad = new Sirea();
        $salida = $ad->consultarSubGrupo($obj);
        echo json_encode($salida);
    break;

}//fin switch
