<?php

session_start();
header('Content-Type: application/json; charset=UTF-8');
header('Cache-Control: no-store');

if (!isset($_SESSION['pacademica']['datosVinculacionUsuario'])
    || !is_array($_SESSION['pacademica']['datosVinculacionUsuario'])) {
    http_response_code(401);
    echo json_encode(array('resultado' => false, 'mensaje' => 'La sesión ha finalizado. Ingrese nuevamente.'));
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    header('Allow: POST');
    echo json_encode(array('resultado' => false, 'mensaje' => 'Solo se permiten peticiones POST.'));
    exit;
}

$obj = json_decode(file_get_contents('php://input'));
if (!is_object($obj)) {
    http_response_code(400);
    echo json_encode(array('resultado' => false, 'mensaje' => 'Debe enviar una solicitud JSON válida.'));
    exit;
}

try {
    require_once __DIR__ . '/../clases/Ceromatriculados.php';
    $reporte = new Ceromatriculados();
    $salida = $reporte->consultarReporte($obj);
} catch (Throwable $error) {
    error_log('Error al consultar el reporte de cero matriculados: ' . $error->getMessage());
    http_response_code(500);
    $salida = array('resultado' => false, 'mensaje' => 'No se pudo consultar el reporte. Intente nuevamente.');
}

// cls_config establece encabezados propios; restablecer JSON después de la consulta.
header('Content-Type: application/json; charset=UTF-8');
echo json_encode($salida, JSON_INVALID_UTF8_SUBSTITUTE);
