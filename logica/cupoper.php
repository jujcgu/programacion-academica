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

require_once('../clases/Cupoper.php');

switch ($obj->accion) {

    //Consulta los estudiantes con cupo personalizado autorizado para un curso especifico.
    case 1:
        $ad = new Cupoper();
        $salida = $ad->consultarCuposPersonalizadosCurso($obj);
        echo json_encode($salida);
    break;

    //Elimina el cupo personalizado de un estudiante seleccionado
    case 2:
        $ad = new Cupoper();
        $salida = $ad->eliminarCupoPersonalizado($obj);
        echo json_encode($salida);
    break;

    //Realiza las validaciones para comprobar si un estudiante se le puede asignar cupo personalizado.
    case 3:
        $ad = new Cupoper();
        $salida = $ad->validarEstudianteCurso($obj);
        echo json_encode($salida);
    break;

    //Consulta los subgrupos de un curso especifico
    case 4:
        $ad = new Cupoper();
        $salida = $ad->consultarSubgrupo($obj);
        echo json_encode($salida);
    break;

    //Asigna cupo personalizado a un estudiante para un curso y subgrupo
    case 5:
        $ad = new Cupoper();
        $salida = $ad->asignarCupoPersonalizado($obj);
        echo json_encode($salida);
    break;
    
}//fin switch
