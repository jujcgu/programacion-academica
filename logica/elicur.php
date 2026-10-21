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

require_once('../clases/Elicur.php');

switch ($obj->accion) {

    //Consulta los docentes NN
    case 1:
        $ad = new Elicur();
        $salida = $ad->consultarDocentesNN();
        echo json_encode($salida);
    break;

    //Consulta los subgrupos de un curso
    case 2:
        $ad = new Elicur();
        $salida = $ad->consultarSubgrupoCurso($obj);
        echo json_encode($salida);
    break;
    

    //Elimina el curso y/o subgrupo seleccionado
    case 3:
        $ad = new Elicur();
        $salida = $ad->eliminarCursoSubgrupo($obj);
        echo json_encode($salida);
    break;

    //Consulta si el curso seleccionado, usuario, unidad tiene permisos para eliminar
    case 4:
        $ad = new Elicur();
        $salida = $ad->consultarPermisosEliminacion($obj);
        echo json_encode($salida);
    break;
    
}//fin switch
