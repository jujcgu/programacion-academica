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

require_once('../clases/Buscurso.php');

switch ($obj->accion) {

    //Consulta información de un curso especifico
    case 1:
        $ad = new Buscurso();
        $salida = $ad->consultarCurso($obj);
        echo json_encode($salida);
    break;
    
    //Consulta los calendarios activos de un periodo.
    case 2:
        $ad = new Buscurso();
        $salida = $ad->consultarCalendarios($obj);
        echo json_encode($salida);
    break;

    //Consulta la lista de cursos del usuario.
    case 3:
        $ad = new Buscurso();
        $salida = $ad->consultarCursos($obj);
        echo json_encode($salida);
    break;

    //Consulta de la informacion detallada de un curso.
    case 4:
        $ad = new Buscurso();
        $salida = $ad->consultarDetalleCurso($obj);
        echo json_encode($salida);
    break;

    //Consulta si la persona que esta logueada es administrador
    case 5:
        $ad = new Buscurso();
        $salida = $ad->consultarAdministrador();
        echo json_encode($salida);
    break;

    //Consulta la agenda de un docente.
    case 6:
        $ad = new Buscurso();
        $salida = $ad->consultarAgendaDocente($obj);
        echo json_encode($salida);
    break;
    
    //Consulta la lista de docentes.
    case 7:
        $ad = new Buscurso();
        $salida = $ad->consultarDocentes($obj);
        echo json_encode($salida);
    break;

    //Consulta los espacios fisicos de una unidad seleccionada.
    case 8:
        $ad = new Buscurso();
        $salida = $ad->consultarEspaciosFisicos($obj);
        echo json_encode($salida);
    break;

    //Consulta los espacios fisicos de una unidad seleccionada.
    case 9:
        $ad = new Buscurso();
        $salida = $ad->validarHorarioCrear($obj);
        echo json_encode($salida);
    break;

    //Consulta los planes academicos con programa
    case 10:
        $ad = new Buscurso();
        $salida = $ad->consultarPlanesAcademicos($obj);
        echo json_encode($salida);
    break;

    //Consulta llas asignaturas de un plan academico especifico
    case 11:
        $ad = new Buscurso();
        $salida = $ad->consultarAsignaturasPlan($obj);
        echo json_encode($salida);
    break;

    //Consulta las asignaturas equivalentes de una unidad especifica.
    case 12:
        $ad = new Buscurso();
        $salida = $ad->consultarAsignaturasEquivalentes($obj);
        echo json_encode($salida);
    break;

    //Permite eliminar varios horarios seleccionados 
    case 13:
        $ad = new Buscurso();
        $salida = $ad->eliminarHorarioGrupo($obj);
        echo json_encode($salida);
    break;

    //Permite consultar la informacion de una asignatura por su nombre o codigo alfanumerico.
    case 14:
        $ad = new Buscurso();
        $salida = $ad->buscarAsignatura($obj);
        echo json_encode($salida);
    break;

    //Consulta carga detallada del docente.
    case 15:
        $ad = new Buscurso();
        $salida = $ad->consultarCargaDocente($obj);
        echo json_encode($salida);
    break;

    //Consulta los espacios fisicos con sus horas disponibles para programar.
    case 16:
        $ad = new Buscurso();
        $salida = $ad->consultarEspaciosFisicosConDisponibilidad($obj);
        echo json_encode($salida);
    break;

    //Consulta los espacios fisicos asignados sin calcular disponibilidad.
    case 17:
        $ad = new Buscurso();
        $salida = $ad->consultarEspaciosFisicos($obj);
        echo json_encode($salida);
    break;

}//fin switch
