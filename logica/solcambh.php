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

require_once('../clases/Solcambh.php');

switch ($obj->accion) {

    //Consulta las solicitudes dirigidas que tienen las unidades del usuario.
    case 1:
        $ad = new Solcambh();
        $salida = $ad->consultarCursosProgramados($obj);
        echo json_encode($salida);
    break;

    //Verifica cruce de horario para un docente y los matriculados del curso.
    case 2:
        $ad = new Solcambh();
        $salida = $ad->verificarHorarioNuevo($obj);
        echo json_encode($salida);
    break;

    //Crea solicitud de cambio de horario
    case 3:
        $ad = new Solcambh();
        $salida = $ad->crearSolicitud($obj);
        echo json_encode($salida);
    break;

    //Crea solicitud de cambio de horario
    case 4:
        $ad = new Solcambh();
        $salida = $ad->consularSolicitudes($obj);
        echo json_encode($salida);
    break;
    
    //Lista de comentarios
    case 5:
        $ad = new Solcambh();
        $salida = $ad->consultarComentarios($obj);
        echo json_encode($salida);
    break;

    //Guardar comentario
    case 6:
        $ad = new Solcambh();
        $salida = $ad->guardarComentarios($obj);
        echo json_encode($salida);
    break;

    //Eliminar horario solicitud
    case 7:
        $ad = new Solcambh();
        $salida = $ad->eliminarHorarioSolicitud($obj);
        echo json_encode($salida);
    break;

    //Eliminar horario solicitud
    case 8:
        $ad = new Solcambh();
        $salida = $ad->consultaHorarioSolicitud($obj);
        echo json_encode($salida);
    break;
    
    //Guardar horario solicitud
    case 9:
        $ad = new Solcambh();
        $salida = $ad->guardarHorarioSolicitud($obj);
        echo json_encode($salida);
    break;

    //Re activar solicitud
    case 10:
        $ad = new Solcambh();
        $salida = $ad->reActivarSolicitud($obj);
        echo json_encode($salida);
    break;

    //Rechazar solicitud
    case 11:
        $ad = new Solcambh();
        $salida = $ad->rechazarSolicitud($obj);
        echo json_encode($salida);
    break;
    
    //Eliminar solicitud
    case 12:
        $ad = new Solcambh();
        $salida = $ad->eliminarSolicitud($obj);
        echo json_encode($salida);
    break;

    //Aprobar solicitud
    case 13:
        $ad = new Solcambh();
        $salida = $ad->aprobarSolicitud($obj);
        echo json_encode($salida);
    break;

    //Aprobar solicitud Jefe de programa
    case 14:
        $ad = new Solcambh();
        $salida = $ad->aprobarSolicitudJefePrograma($obj);
        echo json_encode($salida);
    break;

    //Rechazar solicitud Jefe de programa
    case 15:
        $ad = new Solcambh();
        $salida = $ad->rechazarSolicitudJefePrograma($obj);
        echo json_encode($salida);
    break;

    //Consulta periodo habilitado para módulo de solicitudes (según apertura activa)
    case 16:
        $ad = new Solcambh();
        $salida = $ad->consultarPeriodoHabilitado($obj);
        echo json_encode($salida);
    break;


}//fin switch
