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

require_once('../clases/Soldoc.php');

switch ($obj->accion) {

    //Consulta las solicitudes dirigidas que tienen las unidades del usuario.
    case 1:
        $ad = new Soldoc();
        $salida = $ad->consultarPeticionesPeriodo($obj);
        echo json_encode($salida);
    break;
    //Consulta los departamentos activos
    case 2:
        $ad = new Soldoc();
        $salida = $ad->consultarUaaDepartamentos($obj);
        echo json_encode($salida);
    break;
    //Crear una solicitud
    case 3:
        $ad = new Soldoc();
        $salida = $ad->crearSolicitud($obj);
        echo json_encode($salida);
    break;
    //Consultar dias
    case 4:
        $ad = new Soldoc();
        $salida = $ad->consultarDias();
        echo json_encode($salida);
    break;
    //Consultar el horario de una solicitud
    case 5:
        $ad = new Soldoc();
        $salida = $ad->consultarHorarioSolicitud($obj);
        echo json_encode($salida);
    break;

    //Consultar los comentarios de una solicitud.
    case 6:
        $ad = new Soldoc();
        $salida = $ad->consultaComentariosSolicitud($obj);
        echo json_encode($salida);
    break;

    //Agrega un comentario a una solicitud.
    case 7:
        $ad = new Soldoc();
        $salida = $ad->agregarComentariosSolicitud($obj);
        echo json_encode($salida);
    break;

    //Consulta los docentes permitidos
    case 8:
        $ad = new Soldoc();
        $salida = $ad->consultarDocentesVinculacionPrevia($obj);
        echo json_encode($salida);
    break;

    //Asigna un docente a una solicitud y anexa un comentario
    case 9:
        $ad = new Soldoc();
        $salida = $ad->asignarDocente($obj);
        echo json_encode($salida);
    break;

    //Elimina un horario asignado de una solicitud en estado 1
    case 10:
        $ad = new Soldoc();
        $salida = $ad->eliminaHorarioAsignado($obj);
        echo json_encode($salida);
    break;

    //Rechaza una solicitud
    case 11:
        $ad = new Soldoc();
        $salida = $ad->rechazoSolicitud($obj);
        echo json_encode($salida);
    break;

    //Elimina una solicitud
    case 12:
        $ad = new Soldoc();
        $salida = $ad->eliminarSolicitud($obj);
        echo json_encode($salida);
    break;

    //Agrega horas a una solicitud seleccionada
    case 13:
        $ad = new Soldoc();
        $salida = $ad->agregarHorario($obj);
        echo json_encode($salida);
    break;

    //Re activa una solicitud y se envia de nuevo el correo de notificacion
    case 14:
        $ad = new Soldoc();
        $salida = $ad->reActivarSolicitud($obj);
        echo json_encode($salida);
    break;

    //Re activa una solicitud y se envia de nuevo el correo de notificacion
    case 15:
        $ad = new Soldoc();
        $salida = $ad->consultarSedes($obj);
        echo json_encode($salida);
    break;

    //Consulta el horario de un docente aprobado
    case 16:
        $ad = new Soldoc();
        $salida = $ad->consultarHorarioDocenteAprobado($obj);
        echo json_encode($salida);
    break;

    //Consulta solicitudes programadas
    case 17:
        $ad = new Soldoc();
        $salida = $ad->consultarSolicitudesProgramadas($obj);
        echo json_encode($salida);
    break;

    //Consulta solicitudes programadas
    case 18:
        $ad = new Soldoc();
        $salida = $ad->consultaSolicitudesEliminadas($obj);
        echo json_encode($salida);
    break;

}//fin switch
