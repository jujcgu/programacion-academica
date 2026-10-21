<?php

session_start();

function codificarMensajeUrl($mensaje) {
    return str_replace('.', '%2E', rawurlencode($mensaje));
}

if ( !isset($_POST['usuarioEncriptado']) || !isset($_POST['contrasEncriptada']) || !isset($_POST['txtUsuario']) ){ // Verificamos las variables post del formulario de inicio de sesion.
    vaciarVariablesSesion();
    $mje = "Debe ingresar el usuario y primera contraseña";
    // echo utf8_encode("<script>location.href='../loginMensaje.php?mensaje=".$mje."'</script>"); //Retornamos el mensaje de error a la pagina de errores
    echo json_encode(array(
        "respuesta" => true,
        "mensaje" => "Inicio de sesion 1 fallo...",
        "data" => "loginMensaje.php?mensaje=".codificarMensajeUrl($mje)
    ));
    die;
}

$txtUsuario = $_POST['txtUsuario'];
$usuarioEncriptado = $_POST['usuarioEncriptado'];
$contrasEncriptada = $_POST['contrasEncriptada'];

require_once '../clases/Inicio_sesion.php';
$miInicio = new Inicio_sesion();

//usuarioValido es un array
$usuarioValido = $miInicio->esUsuarioValido($usuarioEncriptado, $contrasEncriptada, $txtUsuario);

if ( $usuarioValido['valido'] == true ){
    $_SESSION['pacademica']['login1_superado'] = TRUE;
    $_SESSION['pacademica']['nombreusuario_plano'] = $_POST['txtUsuario'];
    $_SESSION['pacademica']['contrasena1_plano'] = $_POST['contrasEncriptada'];
    $_SESSION['pacademica_token']['destinatario'] = $usuarioValido['destinatario'];
    echo json_encode(array(
        "respuesta" => true,
        "mensaje" => "Inicio de sesion 1 superado con exito.",
        "data" => "loginToken.php"
    ));

}else{
    vaciarVariablesSesion();
    $mje = $usuarioValido['mensaje']; //Obtenemos el mensaje de error y lo enviamos para la pagina de mensaje.
    header('Consola: L31');
    echo json_encode(array(
        "respuesta" => false,
        "mensaje" => "Inicio de sesion 1 fallo...",
        "data" => "loginMensaje.php?mensaje=".codificarMensajeUrl($mje)
    ));

}

// funcion para vaciar las variables de sesion
function vaciarVariablesSesion() {
    unset($_SESSION['pacademica']);
    unset($_SESSION['pacademica_token']);
}
