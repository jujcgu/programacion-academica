<?php

session_start();

if (!isset($_SESSION['pacademica'])) {
    header("Location: ../login1.php");
}

if ($_SERVER['REQUEST_METHOD'] != 'POST') {
    $salida =  array("success" => false, "message" => "Solo peticiones POST");
    echo json_encode($salida);
    die;
}

$entrada = file_get_contents('php://input');
$obj = json_decode($entrada, false);
header("Content-Type:application/json");

if ($obj == null) {
    $salida =  array("success" => false, "message" => "No se han enviado datos", "console" => "No hay datos en la petición");
    echo json_encode($salida);
    die;
}

require_once('../clases/Curhorario.php');

switch ($obj->accion) {

        //Consulta horario de un curso especifico
    case 1:
        $ad = new Curhorario();
        $salida = $ad->consultarHorario($obj);
        echo json_encode($salida);
        break;

        //Elimina un horario especifico de un curso especifico
    case 2:
        $ad = new Curhorario();
        $salida = $ad->eliminarHorario($obj);
        echo json_encode($salida);
        break;

        //Consulta los espacios disponibles para una unidad
    case 3:
        $ad = new Curhorario();
        $salida = $ad->consultarEspaciosAsignados($obj);
        echo json_encode($salida);
        break;

        //Consulta los espacios virtuales disponibles
    case 4:
        $ad = new Curhorario();
        $salida = $ad->consultarEspeciosVirtuales();
        echo json_encode($salida);
        break;

        //Guarda la programacion academica de un curso especifico.
    case 5:
        $ad = new Curhorario();
        $salida = $ad->validarHorarioCrear($obj);
        echo json_encode($salida);
        break;

        //Consulta el dia de una fecha
    case 6:
        $ad = new Curhorario();
        $salida = $ad->consultarDia($obj);
        echo json_encode($salida);
        break;

        //Consulta las horas disponibles para un docente, espacio, fecha y dia.
    case 7:
        $ad = new Curhorario();
        $salida = $ad->consultarHora($obj);
        echo json_encode($salida);
        break;

        //Consulta los espacios asignados a la unidad seleccionada con su agenda respectiva.
    case 8:
        $ad = new Curhorario();
        $salida = $ad->consultarEspaciosAsignadosTotal($obj);
        echo json_encode($salida);
        break;

        //Consulta los espacios asignados a la unidad seleccionada con su agenda respectiva.
    case 9:
        $ad = new Curhorario();
        $salida = $ad->actualizarAgenda($obj->CurCodigo);
        echo json_encode($salida);
        break;

        //Consulta carga detallada del docente.
    case 10:
        $ad = new Curhorario();
        $salida = $ad->consultarCargaDocente($obj);
        echo json_encode($salida);
        break;

        //Consulta espacios asignados con horas disponibles.
    case 11:
        $ad = new Curhorario();
        $salida = $ad->consultarEspaciosFisicosConDisponibilidad($obj);
        echo json_encode($salida);
        break;

        //Consulta disponibilidad de un espacio asignado especifico.
    case 12:
        $ad = new Curhorario();
        $salida = $ad->consultarEspaciosFisicosConDisponibilidad($obj);
        echo json_encode($salida);
        break;
}//fin switch
