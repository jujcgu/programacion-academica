<?php

//esto va en el archivo a mostrar la foto
//echo "<img src='funcion_foto.php?img=100013' >";

//este es el codigo del archivo funcion_foto.php que se llama en la imagen
//funcion para mostrar la foto de la persona
$cod_per = $_GET['req'];
header('Content-type: image/jpg');

$opts = array(
    'http' => array(
        'method' => "GET",
        'header' => "Accept-language: en\r\n" .
            "Cookie: foo=bar\r\n" .
            "Authorization: Basic MktqaDlDNGNzbV4/a1ZaQlM0JVM6SEh3UkZjNXU2Q21TMHdtP0c2Qns=\r\n"
    )
);

$context = stream_context_create($opts);
echo file_get_contents("https://gaitana.usco.edu.co/porteria_movil/Show?image=" . $cod_per . " ", false, $context);
