<?php
use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

class Correo_solicitud_docente
{
	function enviarCorreoSolicitudDocente($obj, $tipo)
	{

		set_time_limit(0);
		error_log("Se inicia el envio de correo");
		// return $obj;
		//---------- validaciones --------------//
		if (empty($obj)) {
			return array("resultado" => false, "mensaje" => "No hay informacion de la solicitud.");
		}
		if (empty($obj[0]['Correos'])) {
			return array("resultado" => false, "mensaje" => "No hay listado de correos en la solicitud.");
		}
		if (empty($obj[0]['Horario'])) {
			return array("resultado" => false, "mensaje" => "No hay listado de horarios en la solicitud.");
		}
		//---------- fin validaciones --------------//

		require_once('PHPMailer.php');
		require_once('SMTP.php');
		require_once('Exception.php');
		require_once('DisclaimerCorreo.php');

		$disclaimer = new DisclaimerCorreo();
		$textoDisclaimer = $disclaimer->obtenerDisclaimer();
		$textoDisclaimer = utf8_decode($textoDisclaimer);
		$Asunto = "";

		$correo = "prog.academica@usco.edu.co";
		$clave = "oxlw vygk rgav ocfx ";
		//$clave = "oigres,1513";
		$fecha = date('Y-m-d');
		$justificacion = $obj[0]['Justificacion'] ? " {$obj[0]['Justificacion']}. " : "";
		$mensaje = "";
		$horario = "";
		error_log("Se inicia a recorrer el horario");
		foreach ($obj[0]['Horario'] as $item) {
			$horario .= "{$item['DiaCodigo']}. {$item['DiaNombre']}, {$item['HraCodigo']}. {$item['HraInicio']} - {$item['HraFin']} <br>";
		}
		error_log("Se inicia a elegir el tipo de mensaje");
		if ($tipo == "Rechazado"){
			$Asunto = "[Rechazo] ";
			$mensaje = "El sistema de programacion academica se permite informar que su solicitud de prestamo de docente <br><br>
				<b>Asignatura:</b> {$obj[0]['AsiNombreCorto']} - {$obj[0]['AsiNombre']} <br>
				<b>Unidad Dirigida:</b> {$obj[0]['UaaDirigidaCodigo']}. {$obj[0]['UaaDirigidaNombre']} <br>
				<b>Unidad Solicita:</b> {$obj[0]['UaaSolicitaCodigo']}. {$obj[0]['UaaSolicitaNombre']} <br>
				<b>Sede Curso:</b> {$obj[0]['SedCodigo']}. {$obj[0]['SedNombre']} <br>
				<b>Docente Asignado:</b> {$obj[0]['PersonaNombreApellido']}<br><br>
				<b>Horario: </b><br>
				{$horario}	
				<br><br>
				Ha sido <b>RECHAZADA</b> por el motivo: {$justificacion}
			";
		}
		if ($tipo == "Asignado"){
			$Asunto = "[Docente Asignado] ";
			$mensaje = "El sistema de programacion academica se permite informar que se ha asignado un docente a su solicitud de prestamo de docente <br><br>
				<b>Asignatura:</b> {$obj[0]['AsiNombreCorto']} - {$obj[0]['AsiNombre']} <br>
				<b>Unidad Dirigida:</b> {$obj[0]['UaaDirigidaCodigo']}. {$obj[0]['UaaDirigidaNombre']} <br>
				<b>Unidad Solicita:</b> {$obj[0]['UaaSolicitaCodigo']}. {$obj[0]['UaaSolicitaNombre']} <br>
				<b>Sede Curso:</b> {$obj[0]['SedCodigo']}. {$obj[0]['SedNombre']} <br>
				<b>Docente Asignado:</b> {$obj[0]['PersonaNombreApellido']}<br><br>
				<b>Horario: </b><br>
				{$horario}
				<br><br>
				Justificacion: {$justificacion}
			";
		}
		if ($tipo == "ReAsignado"){
			$Asunto = "[Docente ReAsignado] ";
			$mensaje = "El sistema de programacion academica se permite informar que se ha cambiado el docente a su solicitud de prestamo de docente <br><br>
				<b>Asignatura:</b> {$obj[0]['AsiNombreCorto']} - {$obj[0]['AsiNombre']} <br>
				<b>Unidad Dirigida:</b> {$obj[0]['UaaDirigidaCodigo']}. {$obj[0]['UaaDirigidaNombre']} <br>
				<b>Unidad Solicita:</b> {$obj[0]['UaaSolicitaCodigo']}. {$obj[0]['UaaSolicitaNombre']} <br>
				<b>Sede Curso:</b> {$obj[0]['SedCodigo']}. {$obj[0]['SedNombre']} <br>
				<b>Docente Asignado:</b> {$obj[0]['PersonaNombreApellido']}<br><br>
				<b>Horario: </b><br>
				{$horario}
				<br><br>
				Justificacion: {$justificacion}
			";
		}
		if ($tipo == "Comentario"){
			$Asunto = "[Comentario] ";
			$mensaje = "El sistema de programacion academica se permite informar que a su solicitud de prestamo de docente <br><br>
				<b>Asignatura:</b> {$obj[0]['AsiNombreCorto']} - {$obj[0]['AsiNombre']} <br>
				<b>Unidad Dirigida:</b> {$obj[0]['UaaDirigidaCodigo']}. {$obj[0]['UaaDirigidaNombre']} <br>
				<b>Unidad Solicita:</b> {$obj[0]['UaaSolicitaCodigo']}. {$obj[0]['UaaSolicitaNombre']} <br>
				<b>Sede Curso:</b> {$obj[0]['SedCodigo']}. {$obj[0]['SedNombre']} <br>
				<b>Docente Asignado:</b> {$obj[0]['PersonaNombreApellido']}<br><br>
				<b>Horario: </b><br>
				{$horario}
				<br><br>
				Se ha agregado un comentario: {$justificacion}
			";
		}

		if ($tipo == "Creacion"){
			$Asunto = "[Creacion] ";
			$mensaje = "El sistema de programacion academica se permite informar que se ha creado una solicitud de prestamo de docente <br><br>
				<b>Asignatura:</b> {$obj[0]['AsiNombreCorto']} - {$obj[0]['AsiNombre']} <br>
				<b>Unidad Dirigida:</b> {$obj[0]['UaaDirigidaCodigo']}. {$obj[0]['UaaDirigidaNombre']} <br>
				<b>Unidad Solicita:</b> {$obj[0]['UaaSolicitaCodigo']}. {$obj[0]['UaaSolicitaNombre']} <br>
				<b>Sede Curso:</b> {$obj[0]['SedCodigo']}. {$obj[0]['SedNombre']} <br>
				<b>Docente Asignado:</b> {$obj[0]['PersonaNombreApellido']}<br><br>
				<b>Horario: </b><br>
				{$horario}
				<br><br>
			";
		}
		
		if ($tipo == "ReActivacion"){
			$Asunto = "[ReActivacion] ";
			$mensaje = "El sistema de programacion academica se permite informar que se ha re activado una solicitud de prestamo de docente debido a una modificación en la solicitud.<br><br>
				<b>Asignatura:</b> {$obj[0]['AsiNombreCorto']} - {$obj[0]['AsiNombre']} <br>
				<b>Unidad Dirigida:</b> {$obj[0]['UaaDirigidaCodigo']}. {$obj[0]['UaaDirigidaNombre']} <br>
				<b>Unidad Solicita:</b> {$obj[0]['UaaSolicitaCodigo']}. {$obj[0]['UaaSolicitaNombre']} <br>
				<b>Sede Curso:</b> {$obj[0]['SedCodigo']}. {$obj[0]['SedNombre']} <br>
				<b>Docente Asignado:</b> {$obj[0]['PersonaNombreApellido']}<br><br>
				<b>Horario: </b><br>
				{$horario}
				<br><br>
			";
		}
		error_log("Se inicia el cuerpo del correo");
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
							<img style='float:right;max-width: 200px;margin-right: 50px;' src='https://www.usco.edu.co/resources/img/interface/icontec-sellos.svg'/>
						</div>
						<div style='padding-left:30px; padding-right:30px; padding-top:15px;'>
							<br>
							<div>
								<strong>" . $fecha . "</strong>
							</div>
							<br><br>
							<div>Universidad Surcolombiana</div>
							<br><br>
							<div style='text-align : justify'>
								Asunto: Solicitud prestamo de docente para el periodo {$obj[0]['PeriodoNombre']} a la Unidad {$obj[0]['UaaDirigidaCodigo']}. {$obj[0]['UaaDirigidaNombre']}
							</div>
							<br><br>
							<div>Cordial saludo,</div>
							<br><br>
							<div style='text-align:justify;'>
								{$mensaje}
								<br><br>
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
			try {
			error_log("Se crea la instancia de PHPMailer");
			$mail = new PHPMailer(true);
			error_log("Se inicia a agregar los correos");
			foreach ($obj[0]['Correos'] as $fila) {
				error_log("Se agrega el correo: ".$fila['PerEmailInterno']);
				$mail->AddAddress($fila['PerEmailInterno']);
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
			$mail->FromName   = "Solicitud Prestamo Docente"; //Nombre del Formulario
			$mail->Subject    = $Asunto."Solicitud Prestamo Docente {$obj[0]['PeriodoNombre']} - {$obj[0]['AsiNombreCorto']} - {$obj[0]['AsiNombre']}"; //Asunto del Correo
			$mail->AltBody    = "Para ver este mensaje correctamente use un computador"; // optional, comment out and test
			$mail->WordWrap   = 50; // set word wrap
			$mail->MsgHTML($cuerpoMensaje);
			//$mail->AddBCC("cuenta@dominio.com"); // Copia oculta
			$mail->IsHTML(true); // send as HTML, enviar en formato HTML o texto
			error_log("Se inicia el envio");
			if (!$mail->Send()) {
				// mensaje de error
				error_log("Fallo al enviar el email");
				return array(
					"resultado" => false,
					"mensaje" => "Error al enviar el correo de notificacion de apertura.",
				);
			} else {
				//mensaje envio OK
				error_log("Se envio correctamente el correo");
				return array(
					"resultado" => true,
					"mensaje" => "Se envio el correo de notificacion de apertura.",
				);
			}

			$mail->ClearAddresses();
			} catch (\Exception $e) {
				error_log("Excepcion al enviar el email: ".$e->getMessage());
				return array(
					"resultado" => false,
					"mensaje" => "Error al enviar el correo de notificacion de apertura.",
					"consola" => $e->getMessage(),
				);
			}

		return array(
			"resultado" => false,
			"mensaje" => "No se encontraron direcciones de correo electronico para notiticar.",
		);



	} //fin enviarCorreoAperturaProgramacion







}//fin class