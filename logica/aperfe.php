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

require_once('../clases/Aperfe.php');

switch ($obj->accion) {

    //Consulta unidades unificadas
    case 1:
        $ad = new Aperfe();
        $salida = $ad->consultarUaaUnificada();
        echo json_encode($salida);
    break;

    //Consulta calendarios
    case 2:
        $ad = new Aperfe();
        $salida = $ad->consultarCalendarios();
        echo json_encode($salida);
    break;

    //Guarda la apertura de programacion academica
    case 3:
        $ad = new Aperfe();
        $salida = $ad->guardarAperturaProaca($obj);
        echo json_encode($salida);
    break;

    //Consulta procesos
    case 4:
        $ad = new Aperfe();
        $salida = $ad->consultarProcesos();
        echo json_encode($salida);
    break;

    //Consulta aperturas activas
    case 5:
        $ad = new Aperfe();
        $salida = $ad->consultarAperturaProgramacion($obj);
        echo json_encode($salida);
    break;

    //Eliminar apertura de programacion academica
    case 6:
        $ad = new Aperfe();
        $salida = $ad->eliminarAperturaProgramacion($obj);
        echo json_encode($salida);
    break;

    //Consultar usuarios por unidad academica
    case 7:
        $ad = new Aperfe();
        $salida = $ad->consultarUsuariosUaa($obj);
        echo json_encode($salida);
    break;

    //Guarda la apertura de gestion
    case 8:
        $ad = new Aperfe();
        $salida = $ad->guardarAperturaGestion($obj);
        echo json_encode($salida);
    break;

    //Consulta aperturas activas
    case 9:
        $ad = new Aperfe();
        $salida = $ad->consultarAperturaGestion($obj);
        echo json_encode($salida);
    break;

    //Eliminar apertura de gestion
    case 10:
        $ad = new Aperfe();
        $salida = $ad->eliminarAperturaGestion($obj);
        echo json_encode($salida);
    break;

    //Consultar grupos de unidades
    case 11:
        $ad = new Aperfe();
        $salida = $ad->consultarGruposUnidades();
        echo json_encode($salida);
    break;
    
    //Consultar unidades de un grupo
    case 12:
        $ad = new Aperfe();
        $salida = $ad->consultarItemsGrupo($obj);
        echo json_encode($salida);
    break;

    //Elimina unidad especifica de un grupo.
    case 13:
        $ad = new Aperfe();
        $salida = $ad->eliminarItemGrupo($obj);
        echo json_encode($salida);
    break;

    //Agrega unidades a un grupo especifico.
    case 14:
        $ad = new Aperfe();
        $salida = $ad->asignarItemGrupo($obj);
        echo json_encode($salida);
    break;

    //Guarda un nuevo grupo
    case 15:
        $ad = new Aperfe();
        $salida = $ad->guardarGrupo($obj);
        echo json_encode($salida);
    break;

    //Elimina un grupo especifico
    case 16:
        $ad = new Aperfe();
        $salida = $ad->eliminarGrupo($obj);
        echo json_encode($salida);
    break;


    //Modificar periodo activo modulo solicitudes (TODO: Eliminar cuando se complete la migración)
    case 17:
        $ad = new Aperfe();
        $salida = $ad->modificarPeriodoActivo($obj);
        echo json_encode($salida);
    break;

    // Consultar tipos de solicitud
    case 18:
        $ad = new Aperfe();
        $salida = $ad->consultarTiposSolicitud();
        echo json_encode($salida);
    break;

    // Guardar apertura de solicitudes
    case 19:
        $ad = new Aperfe();
        $salida = $ad->guardarAperturaSolicitudes($obj);
        echo json_encode($salida);
    break;

    // Consultar aperturas de solicitudes
    case 20:
        $ad = new Aperfe();
        $salida = $ad->consultarAperturaSolicitudes($obj);
        echo json_encode($salida);
    break;

    // Eliminar apertura de solicitudes
    case 21:
        $ad = new Aperfe();
        $salida = $ad->eliminarAperturaSolicitudes($obj);
        echo json_encode($salida);
    break;

    // Consultar apertura activa de solicitudes (para validación backend)
    case 22:
        $ad = new Aperfe();
        $salida = $ad->consultarAperturaSolicitudActiva($obj);
        echo json_encode($salida);
    break;

    // Consultar historial consolidado por periodo
    case 23:
        $ad = new Aperfe();
        $salida = $ad->consultarHistorialPeriodo($obj);
        echo json_encode($salida);
    break;

    
}//fin switch
