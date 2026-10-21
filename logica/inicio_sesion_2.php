<?php

session_start();

function codificarMensajeUrl($mensaje) {
    return str_replace('.', '%2E', rawurlencode($mensaje));
}

//-------------------------------- INICIO VALIDACIONES ------------------------------//

//si no ha pasado por el login1 no debe ver login2 ni login token
if(!isset($_SESSION['pacademica']['login1_superado'])  || !isset($_SESSION['pacademica']['logintoken_superado']) || !isset($_SESSION['pacademica']['nombreusuario_plano'])  ){
    unset($_SESSION['pacademica']);
    $mje = "Debe ingresar el usuario y primera contraseña.";
    echo json_encode(array(
        "respuesta" => false,
        "mensaje" => $mje,
        "data" => "loginMensaje.php?mensaje=".codificarMensajeUrl($mje)
    ));
    die;
}

//si no ha pasado por el login1 no debe ver login2
if(  $_SESSION['pacademica']['login1_superado'] != TRUE){
    unset($_SESSION['pacademica']);
    $mje = "No ha superado la primera contraseña.";
    echo json_encode(array(
        "respuesta" => false,
        "mensaje" => $mje,
        "data" => "loginMensaje.php?mensaje=".codificarMensajeUrl($mje)
    ));
    die;
}

//si no ha pasado por el login token no debe ver login2
if(  $_SESSION['pacademica']['logintoken_superado'] != TRUE){
    unset($_SESSION['pacademica']);
    $mje = "No ha superado la validacion del token.";
    echo json_encode(array(
        "respuesta" => false,
        "mensaje" => $mje,
        "data" => "loginMensaje.php?mensaje=".codificarMensajeUrl($mje)
    ));
    die;
}

if ( !isset($_POST['contrasEncriptada']) ){
    unset($_SESSION['pacademica']);
    $mje = "No se ha enviado la segunda contraseña.";
    echo json_encode(array(
        "respuesta" => false,
        "mensaje" => $mje,
        "data" => "loginMensaje.php?mensaje=".codificarMensajeUrl($mje)
    ));
    die;
}
//-------------------------------- FIN VALIDACIONES ------------------------------//



$txtUsuario = $_SESSION['pacademica']['nombreusuario_plano'];
$txtContra1 = $_SESSION['pacademica']['contrasena1_plano'];
$txtContra2 = $_POST['contrasEncriptada'];

//limpia las var de sesion
// $_SESSION['pacademica']=NULL;

require_once '../clases/Inicio_sesion.php';
$miInicio = new Inicio_sesion();


$salidaUsuarioReal = $miInicio->obtenerSysUsuarioReal($txtUsuario); //Obtenemos el usuario real de conexion
$salidaClaveReal = $miInicio->encriptarClaveReal($txtUsuario, $txtContra1, $txtContra2); //Obtenemos la clave real encriptada


//cuando se no se pudo consultar el usuario o contrasena real
if ( $salidaUsuarioReal['resultado'] == FALSE || $salidaClaveReal['resultado'] == FALSE  ){
    unset($_SESSION['pacademica']);
    unset($_SESSION['pacademica_token']);
    $mje= "";
    $mje .= $salidaUsuarioReal['mensaje'].". ";
    $mje .= $salidaClaveReal['mensaje'];
    echo json_encode(array(
        "respuesta" => false,
        "mensaje" => $mje,
        "data" => "loginMensaje.php?mensaje=".codificarMensajeUrl($mje)
    ));
    die;
}

//las guarda en sesion para que en la clase de conexion use estas
$_SESSION['pacademica']['usuario_real'] = $salidaUsuarioReal['usuarioReal'];
$_SESSION['pacademica']['clave_real'] = $salidaClaveReal['claveReal'];


$salidaProbarCredenciales = $miInicio->probarCredencialesReales($txtUsuario);
//si la segunda contra esta mal, lo saca
if ($salidaProbarCredenciales['resultado']==FALSE){
    $mje = $salidaProbarCredenciales['mensaje'];
    echo json_encode(array(
        "respuesta" => false,
        "mensaje" => $mje,
        "data" => "login2.php?mensaje=".codificarMensajeUrl($mje)
    ));
    die;
}

$salidaVinculacion = $miInicio->consultarVinculacionActual($txtUsuario);

if ($salidaVinculacion['resultado']===FALSE){

    //las 2 contras estan bien pero el usuario no tiene vinculacion actual
    $mje = $salidaVinculacion['mensaje'];
    echo json_encode(array(
        "respuesta" => false,
        "mensaje" => $mje,
        "data" => "loginMensaje.php?mensaje=".codificarMensajeUrl($mje)
    ));
    die;

}else{
    //tiene vinculacion vigente, lo deja pasar
    // Se debe definir dependiendo del perfil que tenga, que archivo deberia abrir, admin, secretaria, usuario? no se que hace el usuario
    $_SESSION['pacademica']['datosVinculacionUsuario'] = $salidaVinculacion;
    echo json_encode(array(
        "respuesta" => true,
        "mensaje" => $mje,
        "data" => "suite_admin.php"
    ));
    die;
}
