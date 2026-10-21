<?php
use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

class Correo_apertura
{




	function enviarCorreoAperturaProgramacion($obj)
	{

		set_time_limit(0);
		//---------- validaciones --------------//
		if ($obj['listadoCorreos'] == '') {
			return array("resultado" => false, "mensaje" => "No hay listado de correos para enviar");
		}
		if (strlen($obj['fechaInicio']) < 6) {
			return array("resultado" => false, "mensaje" => "No se ha enviado la fecha inicio");
		}
		if (strlen($obj['fechaFin']) < 6) {
			return array("resultado" => false, "mensaje" => "No se ha enviado la fecha fin");
		}
		//---------- fin validaciones --------------//

		require_once('PHPMailer.php');
		require_once('SMTP.php');
		require_once('Exception.php');
		require_once('DisclaimerCorreo.php');

		$disclaimer = new DisclaimerCorreo();
		$textoDisclaimer = $disclaimer->obtenerDisclaimer();
		$textoDisclaimer = utf8_decode($textoDisclaimer);
		$calendario = $obj['CalNombre'];
		$mensaje_calendario = "";
		if ($calendario != "") {
			$mensaje_calendario = " Para el calendario academico <b>{$calendario}</b>, ";
		}

		$obj['fechaInicio'] = date("Y-m-d H:m", strtotime($obj['fechaInicio']));
		$obj['fechaFin'] = date("Y-m-d H:m", strtotime($obj['fechaFin']));

		$correo = "prog.academica@usco.edu.co";
		$clave = "oxlw vygk rgav ocfx ";
		//$clave = "oigres,1513";


		$fecha = date('Y-m-d');

		$errorMensajes = "";
		$errorCantidad = 0;
		$cantCorreosEnviados = 0;
		$correosPersonas = "";
		$contador = 0;

		//----pasa el array de personas a un texto----
		$textoPersonas = "";
		$arrayPersonas = array();
		foreach ($obj['listadoCorreos'] as $fila) {
			array_push($arrayPersonas, $fila['PerNombre'] . ": " . $fila['PerEmail']);
		}
		$textoPersonas = implode(", ", $arrayPersonas);
		//--------------------------------

		if (count($obj['listadoCorreos']) > 0) {

			$cuerpoMensaje = "
			<!DOCTYPE html>
				<head>
					<meta charset='UTF-8'/>
				</head>

				<body style='margin-top:25px; margin-bottom:25px;'>

					<br>

					<div style='margin:0 auto; width: 730px; height: auto; border: #DFDFDF 1px solid; border-radius: 1px;'>
						<br>
						<div style='width: 100%; height: 70px; margin-top: 20px; padding-left:30px; padding-right:30px;'>
							<img src='https://www.usco.edu.co/imagen-institucional/logo/universidad-surcolombiana-vp.png' style=''/>
							<img style='float:right;max-width: 200px;margin-right: 50px;' src='https://gaitana.usco.edu.co/sgd/images/certificaciones.png'/>
						</div>
						<div style='padding-left:30px; padding-right:30px; padding-top:15px;'>
							<br>
							<div><strong>" . $fecha . "</strong></div>
							<br>
							<br>
							<div>Universidad Surcolombiana</div>
							<br><br>
							<div style='text-align : justify'>
								Asunto: Modificaci&oacute;n fecha programaci&oacute;n acad&eacute;mica</div>
							<br><br>
							<div>Cordial saludo,</div>
							<br><br>
							<div style='text-align:justify;'>
							El sistema de programaci&oacute;n acad&eacute;mica se permite informar que estar&aacute; abierta la plataforma
							";
			if ($obj['procesos'] == 'ADMINISTRADOR DE SECRETARIAS') {
				$cuerpoMensaje .= "para realizar modificaciones en el modulo de administrador de secretarias. ";
			} else {
				$cuerpoMensaje .= "para crear cursos de su programa acad&eacute;mico. Cursos que se pueden programar: " . $obj['procesos'] . ".<br><br>";
			}
			$cuerpoMensaje .= " {$mensaje_calendario} Fecha inicio: <b>" . $obj['fechaInicio'] . "</b>. Fecha fin: <b>" . $obj['fechaFin'] . "</b>.<br>
							Las UAAs autorizadas a ingresar son:<br>
							<pre>" . $obj['textoUaasMarcadas'] . "</pre>
							<br>
							<br>
							<pre>Este correo tiene como destinatario las siguientes personas: " . $textoPersonas . "</pre>
							<br>
							</div>
							<br><br><br>
							<div><strong>Atentamente,</strong></div>
							<div>Correo autom&aacute;tico (no responder)</div>
							<div>Sistema de Programaci&oacute;n Acad&eacute;mica</div>
							<br>
							<div style='width: 100%; height: 110px; background-color: transparent; margin-bottom: 10px;'><img src='https://gaitana.usco.edu.co/sgd/images/pie.png' style='width: 400px; height: 110px; float: right;'/></div>
						</div>
					</div>
					<br>
					<br>
					<div style='font-size:xx-small'>
						" . $textoDisclaimer . "
					</div>
					<br>
					<br>
				</body>
			</html>
			";


			$correosPersonas = $correosPersonas . "";

			$mail = new PHPMailer(true);

			foreach ($obj['listadoCorreos'] as $fila) {
				$mail->AddAddress($fila['PerEmail'], $fila['PerNombre']);
			}

			//$mail->addCC('copiado@hotmail.com');

			$mail->IsSMTP();
			$mail->SMTPAuth   = true;                  // autentificación SMTP
			$mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;                 // prefijo del servidor de correo
			$mail->Host       = "smtp.gmail.com";      // dirección del servidor SMTP en este caso de Gmail
			$mail->Port       = 587;                   // Puerto del servidor SMTP de Gmail
			$mail->Username   = $correo;	// usuario de google
			$mail->Password   = $clave;		// contraseña
			$mail->From       = $correo; //
			$mail->FromName   = "Prog Academica USCO"; //Nombre del Formulario
			$mail->Subject    = "Apertura Prog Academica {$calendario} " . $obj['procesos'] . ""; //Asunto del Correo
			$mail->AltBody    = "Para ver este mensaje correctamente use un computador"; // optional, comment out and test
			$mail->WordWrap   = 50; // set word wrap
			$mail->MsgHTML($cuerpoMensaje);
			//$mail->AddBCC("cuenta@dominio.com"); // Copia oculta
			$mail->IsHTML(true); // send as HTML, enviar en formato HTML o texto

			if (!$mail->Send()) {
				// mensaje de error
				return array(
					"resultado" => false,
					"mensaje" => "Error al enviar el correo de notificacion de apertura.",
				);
			} else {
				//mensaje envio OK
				return array(
					"resultado" => true,
					"mensaje" => "Se envio el correo de notificacion de apertura.",
				);
			}

			$mail->ClearAddresses();
		} //fin if

		return array(
			"resultado" => false,
			"mensaje" => "No se encontraron direcciones de correo electronico para notiticar.",
		);



	} //fin enviarCorreoAperturaProgramacion







}//fin class
