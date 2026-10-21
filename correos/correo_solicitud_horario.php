<?php
use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

class Correo_solicitud_horario
{
	function enviarCorreoSolicitudHorario($obj, $tipo)
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
		// estadosSolicitud = [
        //     'Eliminado' => 0,
        //     'Solicitado' => 1,
        //     'Aprobado Planta Fisica' => 2,
        //     'Rechazado Planta Fisica' => 3,
        //     'Aprobado Vicerrectoria Académica' => 4,
        //     'Rechazado Vicerrectoria Académica' => 5,
        //     'Aprobado curso Virtual' => 6,
        //     'Solicitado Jefe Programa' => 7,
        //     'Rechazado Jefe Programa' => 8,
        // ];
		$Estado = "NA";
		if ($obj[0]['SchEstado'] == 0) { $Estado = "<span style='color: red'>Eliminado</span>";}
		if ($obj[0]['SchEstado'] == 1) { $Estado = "<span style='color: #97971c'>Solicitado</span>";}
		if ($obj[0]['SchEstado'] == 2) { $Estado = "<span style='color: green'>Aprobado Planta Fisica</span>";}
		if ($obj[0]['SchEstado'] == 3) { $Estado = "<span style='color: red'>Rechazado Planta Fisica</span>";}
		if ($obj[0]['SchEstado'] == 4) { $Estado = "<span style='color: green'>Aprobado Vicerrectoria Académica</span>";}
		if ($obj[0]['SchEstado'] == 5) { $Estado = "<span style='color: red'>Rechazado Vicerrectoria Académica</span>";}
		if ($obj[0]['SchEstado'] == 6) { $Estado = "<span style='color: green'>Aprobado Curso Virtual</span>";}
		if ($obj[0]['SchEstado'] == 7) { $Estado = "<span style='color: #97971c'>Solicitado al Jefe de Programa</span>";}
		if ($obj[0]['SchEstado'] == 8) { $Estado = "<span style='color: red'>Rechazado por Jefe de Programa</span>";}
		$correo = "prog.academica@usco.edu.co";
		$clave = "oxlw vygk rgav ocfx ";
		//$clave = "oigres,1513";
		$fecha = date('Y-m-d');
		$justificacion = $obj[0]['Justificacion'] ? " {$obj[0]['Justificacion']}. " : "";
		$mensaje = "";
		$horario = "";
		// error_log("Se inicia a recorrer el horario");
		foreach ($obj[0]['Horario'] as $item) {
			$espNuevo = $item['EspNuevoCodigo'] ? "{$item['EspNuevoCodigo']}. {$item['EspNombreCortoNuevo']}" : "";
			$horario .= "{$item['SchhSubgrupo']} {$item['DiaAntCodigo']}. {$item['DiaAntNombre']}  {$item['HraAntCodigo']}. {$item['HraAntInicio']} - {$item['HraAntFin']} {$item['EspAnteriorCodigo']}. {$item['EspNombreCortoAnterior']} <b> -> </b> {$item['DiaNuevoCodigo']}. {$item['DiaNuevoNombre']}  {$item['HraNuevoCodigo']}. {$item['HraNuevoInicio']} - {$item['HraNuevoFin']} {$espNuevo} <br>";
		}
		// error_log("Se inicia a elegir el tipo de mensaje");
		// $tipo esta vacio por defecto pero puede ser:
        // Comentario x
        // Creacion x
        // AprobadoPlanta
        // RechazadoPlanta
        // AprobadoVice x
        // RechazadoVice x
        // ReActivacion
		if ($tipo == "Comentario"){
			$Asunto = "[Comentario] ";
			$mensaje = "El sistema de programacion academica se permite informar que a su solicitud de cambio de horario <br><br>
				<b>Codigo Solicitud:</b> {$obj[0]['SchCodigo']} <br>
				<b>Estado:</b> {$Estado} <br>
				<b>Curso:</b> {$obj[0]['CurCodigo']} - {$obj[0]['CalNombre']} <br>
				<b>Asignatura:</b> {$obj[0]['AsiNombreCorto']} - {$obj[0]['AsiNombre']} <br>
				<b>Unidad:</b> {$obj[0]['UaaCodigo']}. {$obj[0]['UaaNombreCorto']} <br>
				<b>Fecha Creación:</b> {$obj[0]['SchFechaCreacion']}<br>
				<b>Horario: </b><br>
				{$horario}
				<br><br>
				Se ha agregado un comentario: {$justificacion}
			";
		}
		if ($tipo == "Creacion"){
			$Asunto = "[Creacion] ";
			$mensaje = "El sistema de programacion academica se permite informar que se ha creado una solicitud de cambio de horario <br><br>
				<b>Codigo Solicitud:</b> {$obj[0]['SchCodigo']} <br>
				<b>Estado:</b> {$Estado} <br>
				<b>Curso:</b> {$obj[0]['CurCodigo']} - {$obj[0]['CalNombre']} <br>
				<b>Asignatura:</b> {$obj[0]['AsiNombreCorto']} - {$obj[0]['AsiNombre']} <br>
				<b>Unidad:</b> {$obj[0]['UaaCodigo']}. {$obj[0]['UaaNombreCorto']} <br>
				<b>Fecha Creación:</b> {$obj[0]['SchFechaCreacion']}<br>
				<b>Horario: </b><br>
				{$horario}
				<br><br>
			";
		}
		if ($tipo == "SolicitadoJefePrograma"){
			$Asunto = "[Creacion] ";
			$mensaje = "El sistema de programacion academica se permite informar que se ha creado una solicitud de cambio de horario al jefe de programa<br><br>
				<b>Codigo Solicitud:</b> {$obj[0]['SchCodigo']} <br>
				<b>Estado:</b> {$Estado} <br>
				<b>Curso:</b> {$obj[0]['CurCodigo']} - {$obj[0]['CalNombre']} <br>
				<b>Asignatura:</b> {$obj[0]['AsiNombreCorto']} - {$obj[0]['AsiNombre']} <br>
				<b>Unidad:</b> {$obj[0]['UaaCodigo']}. {$obj[0]['UaaNombreCorto']} <br>
				<b>Fecha Creación:</b> {$obj[0]['SchFechaCreacion']}<br>
				<b>Horario: </b><br>
				{$horario}
				<br><br>
			";
		}
		if ($tipo == "AprobadoJefePrograma"){
			$Asunto = "[Aprobado Jefe Programa] ";
			$mensaje = "El sistema de programacion academica se permite informar que el jefe de programa ha aprobado su solicitud de cambio de horario.<br><br>
				<b>Codigo Solicitud:</b> {$obj[0]['SchCodigo']} <br>
				<b>Estado:</b> {$Estado} <br>
				<b>Curso:</b> {$obj[0]['CurCodigo']} - {$obj[0]['CalNombre']} <br>
				<b>Asignatura:</b> {$obj[0]['AsiNombreCorto']} - {$obj[0]['AsiNombre']} <br>
				<b>Unidad:</b> {$obj[0]['UaaCodigo']}. {$obj[0]['UaaNombreCorto']} <br>
				<b>Fecha Creación:</b> {$obj[0]['SchFechaCreacion']}<br>
				<b>Horario: </b><br>
				{$horario}
				<br><br>
				Se ha agregado un justificacion: {$justificacion}
			";
		}
		if ($tipo == "RechazadoJefePrograma"){
			$Asunto = "[Rechazo Jefe Programa] ";
			$mensaje = "El sistema de programacion academica se permite informar que el jefe de programa ha rechazado su solicitud de cambio de horario.<br><br>
				<b>Codigo Solicitud:</b> {$obj[0]['SchCodigo']} <br>
				<b>Estado:</b> {$Estado} <br>
				<b>Curso:</b> {$obj[0]['CurCodigo']} - {$obj[0]['CalNombre']} <br>
				<b>Asignatura:</b> {$obj[0]['AsiNombreCorto']} - {$obj[0]['AsiNombre']} <br>
				<b>Unidad:</b> {$obj[0]['UaaCodigo']}. {$obj[0]['UaaNombreCorto']} <br>
				<b>Fecha Creación:</b> {$obj[0]['SchFechaCreacion']}<br>
				<b>Horario: </b><br>
				{$horario}
				<br><br>
				Se ha agregado un justificacion: {$justificacion}
			";
		}
		if ($tipo == "AprobadoVirtual"){
			$Asunto = "[Aprobado Curso Virtual] ";
			$mensaje = "El sistema de programacion academica se permite informar que se ha creado una solicitud de cambio de horario y no necesita la aprobacion de Planta Fisica, Solamente Vice Academica.<br><br>
				<b>Codigo Solicitud:</b> {$obj[0]['SchCodigo']} <br>
				<b>Estado:</b> {$Estado} <br>
				<b>Curso:</b> {$obj[0]['CurCodigo']} - {$obj[0]['CalNombre']} <br>
				<b>Asignatura:</b> {$obj[0]['AsiNombreCorto']} - {$obj[0]['AsiNombre']} <br>
				<b>Unidad:</b> {$obj[0]['UaaCodigo']}. {$obj[0]['UaaNombreCorto']} <br>
				<b>Fecha Creación:</b> {$obj[0]['SchFechaCreacion']}<br>
				<b>Horario: </b><br>
				{$horario}
				<br><br>
			";
		}
		if ($tipo == "ReActivacion"){
			$Asunto = "[ReActivacion] ";
			$mensaje = "El sistema de programacion academica se permite informar que se ha re activado una solicitud de cambio de horario debido a una modificación en la solicitud.<br><br>
				<b>Codigo Solicitud:</b> {$obj[0]['SchCodigo']} <br>
				<b>Estado:</b> {$Estado} <br>
				<b>Curso:</b> {$obj[0]['CurCodigo']} - {$obj[0]['CalNombre']} <br>
				<b>Asignatura:</b> {$obj[0]['AsiNombreCorto']} - {$obj[0]['AsiNombre']} <br>
				<b>Unidad:</b> {$obj[0]['UaaCodigo']}. {$obj[0]['UaaNombreCorto']} <br>
				<b>Fecha Creación:</b> {$obj[0]['SchFechaCreacion']}<br>
				<b>Horario: </b><br>
				{$horario}
				<br><br>
			";
		}
		if ($tipo == "RechazadoVice"){
			$Asunto = "[Rechazo ViceAcademica] ";
			$mensaje = "El sistema de programacion academica se permite informar que se ha rechazado una solicitud de cambio de horario.<br><br>
				<b>Codigo Solicitud:</b> {$obj[0]['SchCodigo']} <br>
				<b>Estado:</b> {$Estado} <br>
				<b>Curso:</b> {$obj[0]['CurCodigo']} - {$obj[0]['CalNombre']} <br>
				<b>Asignatura:</b> {$obj[0]['AsiNombreCorto']} - {$obj[0]['AsiNombre']} <br>
				<b>Unidad:</b> {$obj[0]['UaaCodigo']}. {$obj[0]['UaaNombreCorto']} <br>
				<b>Fecha Creación:</b> {$obj[0]['SchFechaCreacion']}<br>
				<b>Horario: </b><br>
				{$horario}
				<br><br>
				Se ha agregado un justificacion: {$justificacion}
			";
		}
		if ($tipo == "AprobadoVice"){
			$Asunto = "[Aprobado ViceAcademica] ";
			$mensaje = "El sistema de programacion academica se permite informar que se ha aprobado una solicitud de cambio de horario.<br><br>
				<b>Codigo Solicitud:</b> {$obj[0]['SchCodigo']} <br>
				<b>Estado:</b> {$Estado} <br>
				<b>Curso:</b> {$obj[0]['CurCodigo']} - {$obj[0]['CalNombre']} <br>
				<b>Asignatura:</b> {$obj[0]['AsiNombreCorto']} - {$obj[0]['AsiNombre']} <br>
				<b>Unidad:</b> {$obj[0]['UaaCodigo']}. {$obj[0]['UaaNombreCorto']} <br>
				<b>Fecha Creación:</b> {$obj[0]['SchFechaCreacion']}<br>
				<b>Horario: </b><br>
				{$horario}
				<br><br>
				Se ha agregado una justificacion: {$justificacion}
			";
		}

		// error_log("Se inicia el cuerpo del correo");
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
								Asunto: Solicitud cambio de horario para el curso {$obj[0]['CurCodigo']}
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
			$mail->FromName   = "Solicitud Cambio de Horario"; //Nombre del Formulario
			$mail->Subject    = utf8_decode($Asunto."Solicitud Cambio de Horario {$obj[0]['CurCodigo']} - {$obj[0]['AsiNombreCorto']} - {$obj[0]['AsiNombre']}"); //Asunto del Correo
			$mail->AltBody    = "Para ver este mensaje correctamente use un computador"; // optional, comment out and test
			$mail->WordWrap   = 50; // set word wrap
			$mail->MsgHTML(utf8_decode($cuerpoMensaje));
			//$mail->AddBCC("cuenta@dominio.com"); // Copia oculta
			$mail->IsHTML(true); // send as HTML, enviar en formato HTML o texto
			error_log("Se inicia el envio");
			if (!$mail->Send()) {
				// mensaje de error
				error_log("Fallo al enviar el email");
				return array(
					"resultado" => false,
					"mensaje" => "Error al enviar el correo de notificacion.",
				);
			} else {
				//mensaje envio OK
				error_log("Se envio correctamente el correo");
				return array(
					"resultado" => true,
					"mensaje" => "Se envio el correo de notificacion.",
				);
			}

			$mail->ClearAddresses();

		return array(
			"resultado" => false,
			"mensaje" => "No se encontraron direcciones de correo electronico para notiticar.",
		);



	} //fin enviarCorreoAperturaProgramacion







}//fin class
