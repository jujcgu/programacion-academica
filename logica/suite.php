<?php
session_start();
if ($_SESSION['pacademica']['datosVinculacionUsuario'] == null) {
    header("HTTP/1.0 403 Forbidden");
    echo "403";
    exit();
}

header("Content-Type:application/json");
$obj = json_decode(file_get_contents('php://input'));

$usrStr = $_SESSION['pacademica']["datosVinculacionUsuario"];
$roles = $_SESSION['pacademica']['ROLES'];

switch ($obj->accion) {
    case 1:
        $iniciales = array(
            'codigo' => $usrStr["vinculacionCodigo"], //uap_codigo
            'nombre' => $usrStr["personaNombre"],
            'apellido' => $usrStr["personaApellido"],
            'uaa' => $usrStr["uaaCodigo"],
            'cargo' => $usrStr["cargoNombre"],
            'persona' => $usrStr["personaCodigo"],
            'perfil' => $usrStr["grupoNombre"],
            'perfil_id' => $usrStr["grupoId"],
            'codPerfil' => $usrStr["grupoCodigo"],
        );
        $iniciales = json_encode($iniciales);
        echo $iniciales;
        break;

    case 2:
        $reponse = $roles;
        $reponse = json_encode($roles);
        echo $reponse;
    break;
}
