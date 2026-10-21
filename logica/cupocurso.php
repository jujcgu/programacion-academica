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

require_once('../clases/Cupocurso.php');

switch ($obj->accion) {

    //Consulta general de un curso por su codigo cur_codigo
    case 1:
        $ad = new Cupocurso();
        $salida = $ad->consultarCurso($obj);
        echo json_encode($salida);
    break;

    //Actualiza el cupo de un subgrupo de un curso
    case 2:
        $ad = new Cupocurso();
        $salida = $ad->actualizarCupoSubgrupo($obj);
        echo json_encode($salida);
    break;

    //Consulta el sub grupo de un curso determinado
    case 3:
        $ad = new Cupocurso();
        $salida = $ad->consultarSubgrupoCurso($obj);
        echo json_encode($salida);
    break;

    //Consulta los matriculados de un subgrupo
    case 4:
        $ad = new Cupocurso();
        $salida = $ad->consultarEstudiantesMatriculados($obj);
        echo json_encode($salida);
    break;

    //Consulta el creador del curso
    case 5:
        $ad = new Cupocurso();
        $salida = $ad->consultarCreadorCurso($obj);
        echo json_encode($salida);
    break;

    //Actualiza el cupo y/o ampliacion de un curso.
    case 6:
        $ad = new Cupocurso();
        $salida = $ad->actualizarCupoCurso($obj);
        echo json_encode($salida);
    break;

    //Consulta la gabela de aforo vigente (Cupo Total + Reserva <= Aforo + gabela)
    case 7:
        $ad = new Cupocurso();
        $salida = $ad->consultarGabelaCupoAforo($obj);
        echo json_encode($salida);
    break;


}//fin switch
