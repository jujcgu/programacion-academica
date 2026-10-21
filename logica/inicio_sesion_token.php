<?php

session_start();

function codificarMensajeUrl($mensaje) {
    return str_replace('.', '%2E', rawurlencode($mensaje));
}

// funcion para vaciar las variables de sesion
function vaciarVariablesSesion() {
    unset($_SESSION['pacademica']);
    unset($_SESSION['pacademica_token']);
}

// Verificamos que la variable post traiga el token, que este superado el login1 y que exista un destinatario al cual se le envio el token
if ( !isset($_POST['txtToken']) || !isset($_SESSION['pacademica']['login1_superado']) || !isset($_SESSION['pacademica_token']['destinatario'])){
    vaciarVariablesSesion();
    $mje = "Debe ingresar el usuario y primera contraseña.";
    echo utf8_encode("<script>location.href='../loginMensaje.php?mensaje=".codificarMensajeUrl($mje)."'</script>");
    die;
}

//si no ha pasado por el login1 no debe ver loginToken
if( $_SESSION['pacademica']['login1_superado'] != TRUE){
    vaciarVariablesSesion();
    $mje = "No ha superado la primera contraseña.";
    echo utf8_encode("<script>location.href='../loginMensaje.php?mensaje=".codificarMensajeUrl($mje)."'</script>");
    die;
}

//Verificamos que exista la variable POST con el token
if ( !isset($_POST['txtToken']) ){
    vaciarVariablesSesion();
    $mje = "No se ha enviado token de seguridad.";
    echo utf8_encode("<script>location.href='../loginMensaje.php?mensaje=".codificarMensajeUrl($mje)."'</script>");
    die;
}



$token = trim($_POST['txtToken']); //Limpiamos la cadena de token.
$usuario_plano = $_SESSION['pacademica']['nombreusuario_plano']; //Obtenemos el usuario actual.

require_once '../clases/Inicio_sesion.php';
$miInicio = new Inicio_sesion(); //Creamos objeto de conexion a la base de datos

//Validamos que el usuario tenga activo el token digitado
$tokenvalidado = $miInicio->validarToken($usuario_plano, $token);

if ( $tokenvalidado['valido'] == true ){
    $_SESSION['pacademica']['logintoken_superado'] = TRUE;
    $_SESSION['pacademica_token']['token'] = $token;
    echo utf8_encode("<script>location.href='../login2.php'</script>");

}else{
    $mje = $tokenvalidado['mensaje'];
    header("consola:{$tokenvalidado['consola']}");
    echo utf8_encode("<script>location.href='../loginToken.php?mensaje=".codificarMensajeUrl($mje)."'</script>");

}
