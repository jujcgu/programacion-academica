<?php

// session_start();

class Inicio_sesion
{

    //--------------------------------------------------------------
    //esto se hace con el usuario del logueo
    public function esUsuarioValido($usuarioEncriptado, $contrasEncriptada, $txtUsuario)
    {
        //Encriptamos usuario y contraseña
        $usuario = "0x" . $usuarioEncriptado;
        $contra1 = "0x" . $contrasEncriptada;

        if (!is_file('../conexion/cls_config.php')) {
            return array(
                "valido" => false,
                "mensaje" => "No hay archivo de conexion"
            );
        }

        require_once '../conexion/cls_config.php';
        $cnx = new cls_config("Login.esUsuarioValido"); // Se crea objeto de conexion a la base de datos.

        //Buscar procedimiento para programacion academica para validar que exista el usuario y este activo. retorna 0 o 1;
        //Verificar con el login real.
        $sql = "select dbo.validarUsuarioProgramacion(" . $usuario . "," . $contra1 . ") as usuario_validado";

        if (!$cnx->consultar_login($sql)) {
            return array(
                "valido" => false,
                "mensaje" => "Error al consultar en la base de datos",
                "consola" => "l36 Inicio Sesion Class",
            );
        }

        $valido = $cnx->json[0]['usuario_validado']; // 0 si no esta activo, 1 si esta activo

        if (strval($valido) != "1") {
            // si no se encontro un usuario activo es por que las credenciales estan mal o por que no esta activo
            return array(
                "valido" => false,
                "mensaje" => "Credenciales incorrectas o el usuario no esta activo",
                "consola" => "l48 Inicio Sesion Class",
            );
        }

        // Inicia implementacion token contraseña 1
        $sql = "select uid from dbo.usuario_programacion_login where us = '{$txtUsuario}' "; //obtenemos uid del usuario.

        if (!$cnx->consultar_login($sql)) {
            //En caso de no poder obtener el uid del usuario
            return array(
                "valido" => false,
                "mensaje" => "Error al obtener el id del usuario {$txtUsuario}",
                "consola" => "l59 Inicio Sesion Class",
            );
        }

        $uid = $cnx->json[0]['uid']; //Almacenamos uid.

        $ip = ""; // Obtenemos la ip del usuario donde se inicio sesion.
        if (!empty($_SERVER['HTTP_CLIENT_IP'])) {
            $ip = $_SERVER['HTTP_CLIENT_IP'];
        } elseif (!empty($_SERVER['HTTP_X_FORWARDED_FOR'])) {
            $ip = $_SERVER['HTTP_X_FORWARDED_FOR'];
        } else {
            $ip = $_SERVER['REMOTE_ADDR'];
        }

        //Generamos un token para consultar el servicio.
        $modCodigo = 13; // 13 Pertenece a programacion academica
        $sql = "select token.getTokenInicioSesion('" . $modCodigo . $uid . $ip . "') as token_resultado";
        if (!$cnx->consultar_login($sql)) {
            //En caso de no poder generar el token autorizacion de la base de datos.
            return array(
                "valido" => false,
                "mensaje" => "Error al generar token.",
                "consola" => "l81 Inicio Sesion Class",
            );
        }
        $token = $cnx->json[0]['token_resultado']; //Almacenamos el token de autorizacion

        $resultPeticion = self::solicitarCodigoVerificacion($modCodigo, $uid, $ip, $token); //Llamamos la funcion para solicitar un token de seguridad.

        // Comprobamos si el resultado es falso (Error al general el token)
        if ($resultPeticion['estado'] == false) {
            return array(
                "valido" => false,
                "mensaje" => $resultPeticion["mensaje"],
                "consola" => $resultPeticion["consola"],
            );
        }

        // Return para que fuera valido.
        return array(
            "valido" => true,
            "destinatario" => $resultPeticion["mensaje"],
            "mensaje" => "La contra 1 esta bien. Es un usuario valido.",
            "consola" => $resultPeticion["consola"],
        );
    }
    //--------------------------------------------------------------

    public static function solicitarCodigoVerificacion($modCodigo, $uid, $ip, $token)
    {
        require_once '../conexion/cls_config.php';
        $cnx = new cls_config("Login.validarCodigoVerificacion");
        $sql = "SELECT 
            wep_valor WepValor 
        FROM 
            web_parametro 
        WHERE 
            wep_nombre LIKE 'TOKEN_URL_AUTENTICACION'";

        if (!$cnx->consultar_login($sql)) {
            return array(
                "valido" => false,
                "mensaje" => "Error al consultar la ruta del servicio token.",
            );
        }

        $rutaServicio = $cnx->json[0]['WepValor'] . 'api/generarCodigo';

        //definimos cada uno de los parametros del cuerpo de la peticion
        $bodyPeticion = http_build_query(
            array(
                "aplicativo" => base64_encode($modCodigo),
                "usuario" => base64_encode($uid),
                "ip" => base64_encode($ip),
            )
        );

        //definimos cada uno de los parametros de la cabecera de la peticion
        $headerPeticion = array(
            "Authorization: " . base64_encode($token) . " ",
            "Content-Type: application/x-www-form-urlencoded ",
        );

        //abrimos la sesión cURL
        $ch = curl_init();

        // definimos la URL a la que hacemos la petición
        curl_setopt($ch, CURLOPT_URL, $rutaServicio);
        // indicamos el tipo de petición: POST
        curl_setopt($ch, CURLOPT_POST, true);
        // definimos cada uno de los parámetros del cuerpo
        curl_setopt($ch, CURLOPT_POSTFIELDS, $bodyPeticion);

        curl_setopt($ch, CURLOPT_HTTPHEADER, $headerPeticion);

        //indicamos que debe recibir el mensaje de retorno
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

        //permite enviar peticiones sin ssl
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);

        //guardamos el mensaje que retornó el servidor remoto
        $respuestaServer = curl_exec($ch);

        if ($respuestaServer === false) {
            return array(
                "estado" => false,
                "mensaje" => "Hay error al solicitar un código de verificación.",
                "consola" => curl_error($ch),
            );
        }

        // cerramos la sesión cURL
        curl_close($ch);

        //agarra la respuesta (que es un string json) y lo convierte
        //en array para manejarlo con php
        $arrayRespuesta = json_decode($respuestaServer, true);
        return $arrayRespuesta;
    }

    //--------------------------------------------------------------
    //esto se hace con el usuario del logueo
    public function obtenerSysUsuarioReal($txtUsuario)
    {

        require_once '../conexion/cls_config.php';
        $cnx = new cls_config("Login.obtenerSysUsuarioReal");

        $sql = "select sys, us, up, gru_codigo  from usuario_programacion_login where us='" . $txtUsuario . "' ";
        if (!$cnx->consultar_login($sql)) {
            header('Consola: '.__LINE__.'. no se pudo obtener el sys real.');
            return array(
                "resultado" => false,
                "mensaje" => "Error al consultar el usuario real en la base de datos"
            );
        }

        $usuarioReal = ($cnx->json[0]['sys']);

        if (!isset($usuarioReal) || $usuarioReal == null || $usuarioReal == "") {
            header('Consola: '.__LINE__.'. no cuenta con segunda contraseña.');
            return array("resultado" => false, "mensaje" => "El usuario no tiene segunda contrasena. Debe solicitarla a CITCD");
        } else {
            return array("resultado" => true, "usuarioReal" => strval($usuarioReal));
        }
    }

    //--------------------------------------------------------------
    //esto se hace con el usuario del logueo
    public function encriptarClaveReal($txtUsuario, $txtContra1, $txtContra2)
    {

        $usuario = "0x" . sha1($txtUsuario);
        $contra1 = "0x" . $txtContra1;
        $contra2 = "0x" . $txtContra2;

        require_once '../conexion/cls_config.php';
        $cnx = new cls_config("Login.encriptarClaveReal");

        $sql = "select dbo.getClaveRealProgramacion(" . $usuario . "," . $contra1 . ", " . $contra2 . ") as clave_real";

        if (!$cnx->consultar_login($sql)) {
            header('Consola: '.__LINE__.'. no se pudo obtener la clave real.');
            return array(
                "resultado" => false,
                "mensaje" => "Error al consultar clave real en la base de datos"
            );
        }

        $clave = $cnx->json[0]['clave_real'];

        return array("resultado" => true, "claveReal" => strval($clave));
    }

    //--------------------------------------------------------------
    //esto se hace con usuario y contra real
    public function probarCredencialesReales($usuarioPlano)
    {

        require_once '../conexion/cls_config.php';
        $cnx = new cls_config("Login.probarCredencialesReales");

        $sql = "select us from usuario_programacion WHERE us = '" . $usuarioPlano . "' ";

        if (!$cnx->consultar_login_real($sql)) {
            header('Consola: '.__LINE__.'. no se validar las credenciales reales.');
            return array(
                "resultado" => false,
                "mensaje" => "La segunda contraseña es incorrecta."
            );
        }

        $us = $cnx->json[0]['us'];

        if (!isset($us) || $us == null || $us == "") {
            header("Consola: ".__LINE__.". no se pudieron validar correctamente las credenciales.");
            return array("resultado" => false, "mensaje" => "La segunda contraseña es incorrecta.");
        } else {
            header("Consola: ".__LINE__.". se valido correctamente las credenciales reales.");
            return array("resultado" => true, "mensaje" => " ");
        }
    }

    //----------------------------------------------------------------------------

    public function consultarVinculacionActual($usuarioPlano = "")
    {

        require_once '../conexion/cls_config.php';
        $cnx = new cls_config("Login.consultarVinculacionActual");

        // Asigna los roles del sistema a las variables de sesión
        $roles = self::obtenerRolesSistema();
        if ($roles['estado'] == false) {
            return array(
                "resultado" => false,
                "mensaje" => $resultPeticion["mensaje"]
            );
        }
        $grupos = $roles['valor']; // Define el GruCodigo de los roles del sistema

        $sql = "SELECT DISTINCT 
                    per.per_identificacion, 
                    per.per_codigo, 
                    per.per_nombre,
                    per.per_apellido, 
                    u.us, 
                    u.uid, 
                    u.sys, 
                    uaa.uaa_codigo,
                    up.uap_codigo, 
                    up.uap_fecha_inicio, 
                    up.uap_fecha_fin, 
                    uaa.uat_codigo,
                    CONVERT(date, up.uap_fecha_fin) AS uap_fecha_fin,  
                    CONVERT(date, up.uap_fecha_inicio) AS uap_fecha_inicio,
                    uaa.uaa_nombre_corto, 
                    g.gru_codigo, 
                    g.gru_nombre, 
                    g.gru_id,
                    CASE 
                        WHEN up.uap_cargo <> 0 THEN 
                            (SELECT c.car_nombre FROM cargo c WHERE c.car_codigo = up.uap_cargo)
                        ELSE 
                            (SELECT c.car_nombre 
                            FROM uaa_cargo uc 
                            INNER JOIN cargo AS c ON c.car_codigo = uc.uac_cargo
                            WHERE uc.uac_codigo = up.uac_codigo)
                    END AS car_nombre,
                    uaa.uaa_dependencia,
                    CASE g.gru_codigo --Agregamos la prioridad de los roles para casos de usuarios que tengan más de un rol. 
                        WHEN 69 THEN 1 -- 69 -> Administrador
                        WHEN 318 THEN 2 -- 318 -> SubAdministrador
                        WHEN 34 THEN 2 -- 34 -> Jefe Programa
                        WHEN 14 THEN 3 -- 14 -> Jefe Dpto.
                        WHEN 68 THEN 4 -- 68 -> Secretaria.
                        ELSE 5
                    END AS prioridad_rol
                FROM persona per
                INNER JOIN usuario_programacion_login u ON u.up = per.per_codigo
                INNER JOIN uaa_personal up ON up.per_codigo = per.per_codigo
                INNER JOIN usuario_grupo ON u.uid = usuario_grupo.usg_usuario
                INNER JOIN grupo g ON usuario_grupo.usg_grupo = g.gru_codigo
                INNER JOIN uaa ON usuario_grupo.usg_uaa = uaa.uaa_codigo
                WHERE u.us = '{$usuarioPlano}'
                AND usuario_grupo.usg_grupo IN ({$grupos}) 
                AND usuario_grupo.usg_estado = 1
                AND (
                        (
                            (CAST(GETDATE() AS DATE) BETWEEN CAST(up.uap_fecha_inicio AS DATE) AND CAST(up.uap_fecha_fin AS DATE))
                            AND (CAST(GETDATE() AS DATE) BETWEEN CAST(up.uap_fecha_inicio AS DATE) AND CAST(up.uap_fecha_fin AS DATE))
                        )
                        OR (
                            (CAST(up.uap_fecha_inicio AS DATE) <= CAST(GETDATE() AS DATE) AND up.uap_fecha_fin IS NULL)
                        )
                    )
                AND (up.uap_uacocupado = 1 OR up.uap_uacocupado IS NULL)
                ORDER BY 
                    up.uap_fecha_inicio DESC, -- Ordena los roles por fecha de inicio de manera descendente
                    prioridad_rol ASC --Si tienen la misma fecha, ordena por prioridad de roles";

        if (!$cnx->consultar_login($sql)) {
            header('Consola: '.__LINE__.'. no se pudo consultar la vinculacion actual.');
            return array(
                "resultado" => false,
                "mensaje" => "Error al consultar las vinculaciones."
            );
        }

        $vinculaciones = $cnx->json;

        if (count($vinculaciones) < 1) {
            header('Consola: '.__LINE__.'. no tiene vinculaciones vigentes.');
            return array(
                "resultado" => false,
                "mensaje" => "La dos contraseñas son correctas pero el usuario no tiene vinculación"
            );
        } else {

            //Declaracion de variables
            //$unidades array para almacenar respuesta de unidades
            //$unidades_unificadas array para almacenar respuesta de las unidades unificadas vinculadas al usuario.
            //$mis_unidades las unidades que tiene en formato cadena de texto separados por coma

            $mis_unidades = array();
            $usuarios_vinculados = array();
            $mis_unidades_especiales = array(); //se usa para traer las dependencias y departamentos.
            $unidades = array(); // almacenamos las unidades que tiene el usuario
            $unidades_unificadas = array(); // almacenamos las unidades unificadas que tiene el usuario
            for ($i = 0; $i < count($vinculaciones); $i++) {
                $unidades_unificadas[$i] = $vinculaciones[$i]["uaa_codigo"];
                $mis_unidades_especiales[$i] = $vinculaciones[$i]["uaa_dependencia"];
            }

            $unidades_unificadas = array_unique($unidades_unificadas); //Eliminamos unidades unificadas repetidas.
            $mis_unidades_especiales = array_unique($mis_unidades_especiales); //Eliminamos unidades especiales repetidas.
            
            //Recorremos las unidades unificadas y obtenemos las uaas que tienen como hijo.
            $count = 0;
            foreach ($unidades_unificadas as $uaa) {
                $sql = "SELECT programa.uaa_codigo UaaCodigo, uaa_nombre UaaNombre, uaa_nombre_corto UaaNombreCorto, uaa_dependencia UaaDependencia
                from programa
                inner join uaa on uaa.uaa_codigo = programa.uaa_codigo and uaa_estado = 1
                where uaa_codigo_unificado = {$uaa}";

                if (!$cnx->consultar_login($sql)) {
                    header('Consola: '.__LINE__.'. no se puden obtener las uaa vinculadas a la unificada.');
                    return array(
                        "resultado" => false,
                        "mensaje" => "Error al consultar uaa vinculadas a la unificada."
                    );
                }
                //Verificamos que si tenga uaa vinculada, en caso de que no por ahora damos error, pero en teoria deberia tener vinculadas cuando se implemente este modulo.
                if (count($cnx->json) > 0) {
                    $resultado = $cnx->json;
                    for ($f = 0; $f < count($resultado); $f++) {
                        $mis_unidades[$count] = $resultado[$f]["UaaCodigo"];
                        $mis_unidades_especiales[$count] = $resultado[$f]["UaaDependencia"];
                        // if($resultado[$f]["UaaDependencia"] == "21"){ //Aplicaba solo para la facultad de ingenieria pero ya se aplica para todos!!!!!!!!! :(
                        // }
                        $count++;
                    }
                } else {
                    header('Consola: '.__LINE__.'. no se encontraron las uaa vinculadas a la unificada.');
                    //en caso de ser administrador no tiene uaa unificadas por lo tanto paila, sale error.
                    // return array("resultado" => false,
                    //     "mensaje" => "Error no se encontraron uaa vinculadas a la unificada.");

                }
                $count++;
            }

            // ASIGNA LOS VALORES DEL WEBPARAMETRO A LAS CONSTANTES DE ROLES DENTRO DE LA VARIABLE DE SESION
            $rolCodigo = explode(',', $grupos);
            $rolesNombres = [
                'ADMINISTRADOR',
                'SUB_ADMINISTRADOR',
                'JEFE_PROGRAMA',
                'JEFE_DEPARTAMENTO',
                'SECRETARIA'
            ];

            $_SESSION['pacademica']['ROLES'] = array_combine($rolesNombres, $rolCodigo);

            //Query para saber si el usuario es un administrador
            $sql = "SELECT DISTINCT usg.usg_grupo
            FROM usuario_programacion_login upr
            INNER JOIN usuario_grupo usg ON usg.usg_usuario = upr.uid
            WHERE
            upr.us = '{$usuarioPlano}'
            and usg.usg_grupo in ( 69 )";

            if (!$cnx->consultar_login($sql)) {
                header('Consola: '.__LINE__.'. no se pudo validar si es administrador.');
                return array(
                    "resultado" => false,
                    "mensaje" => "Error al consultar si es administrador."
                );
            }

            $administrador = $cnx->json;

            if (count($administrador) > 0) {
                //Si es administrador se consultan todas las uaa.
                $sql = "SELECT u.uaa_codigo
                FROM uaa u
                WHERE 
                    u.uat_codigo in(1,2,3) 
                    AND u.uaa_estado = 1
                GROUP BY u.uaa_codigo";

                if (!$cnx->consultar_login($sql)) { //Comprobamos que se pueda realizar la consultas
                    header('Consola: '.__LINE__.'. no se pudo consultar las uaa del administrador.');
                    return array(
                        "resultado" => false,
                        "mensaje" => "Error al consultar unidades de administrador."
                    );
                }

                $adm_uaa = $cnx->json; //Almacenamos la consulta de uaa.

                array_push($mis_unidades_especiales, "328", "340");

                if (count($adm_uaa) > 0) { //Consultamos que la consulta tiene registros.
                    $unidades = array(); // Sirve para almacenar todas las unidades en caso de ser administrador
                    for ($i = 0; $i < count($adm_uaa); $i++) {
                        $unidades[$i] = $adm_uaa[$i]["uaa_codigo"];
                    }
                    // $mis_unidades = array_merge($mis_unidades, $unidades_unificadas); //Mezcla las unidades con la unidad unificada o la unidad que tenga en el perfil
                    // $mis_unidades = array_merge($mis_unidades, $mis_unidades_especiales); //Mezcla las unidades con la unidad unificada o la unidad especial como facultades o dptos
                    // $mis_unidades = array_unique($mis_unidades); //Eliminamos unidades repetidas.
                    $mis_unidades = implode(",", $unidades);

                    $salida = array(
                        "personaIdentificacion" => $vinculaciones[0]["per_identificacion"],
                        "personaCodigo" => $vinculaciones[0]["per_codigo"],
                        "personaNombre" => $vinculaciones[0]["per_nombre"],
                        "personaApellido" => $vinculaciones[0]["per_apellido"],
                        "usuarioNombre" => $vinculaciones[0]["us"],
                        "usuarioCodigo" => $vinculaciones[0]["uid"],
                        "uaaCodigo" => $vinculaciones[0]["uaa_codigo"],
                        "uaaNombreCorto" => $vinculaciones[0]["uaa_nombre_corto"],
                        "vinculacionCodigo" => $vinculaciones[0]["uap_codigo"],
                        "cargoNombre" => $vinculaciones[0]["car_nombre"],
                        "grupoCodigo" => $vinculaciones[0]["gru_codigo"],
                        "grupoNombre" => $vinculaciones[0]["gru_nombre"],
                        "grupoId" => $vinculaciones[0]["gru_id"],
                        "Administrador" => 1,
                        "unidades" => $mis_unidades,
                    );

                    return $salida;
                }
            } else {
                $mis_unidades = array_merge($mis_unidades, $unidades_unificadas); //Mezcla las unidades con la unidad unificada o la unidad que tenga en el perfil
                $mis_unidades = array_merge($mis_unidades, $mis_unidades_especiales); //Mezcla las unidades con la unidad unificada o la unidad especial como facultades o dptos
                $mis_unidades = array_unique($mis_unidades); //Eliminamos unidades repetidas.
                $mis_unidades_implode = implode(",", $mis_unidades);
                $contieneDptoEspecial = false;
                foreach($mis_unidades as $uaa){
                    if($uaa == 328){
                        $contieneDptoEspecial = true;
                        break; // opcional: salir del bucle si se encuentra una coincidencia
                    }
                }
                
                if (!$contieneDptoEspecial){
                    $sql = "SELECT 
                            uaa.uaa_codigo_departamento UaaCodigoDepartamento 
                        FROM 
                            departamentos_programas_unificados uaa 
                        WHERE 
                            uaa_codigo_programa IN ({$mis_unidades_implode}) 
                            AND uaa_codigo_departamento NOT IN (328,345,363)";

                    if (!$cnx->consultar_login($sql)) { //Comprobamos que se pueda realizar la consultas
                        header("Consola: ".__LINE__.". no se pudo consultar los departamentos de las unidades ({$mis_unidades_implode}).");
                        return array(
                            "resultado" => false,
                            "mensaje" => "Error al consultar los departamentos de las unidades."
                        );
                    }
                    $uaa_dpts = $cnx->json;
                    $uaa_dpts_array = array();
                    foreach ($uaa_dpts as $uaa) {
                        $uaa_dpts_array[] = $uaa["UaaCodigoDepartamento"];
                    }
                    $mis_unidades = array_merge($mis_unidades, $uaa_dpts_array);
                    $mis_unidades = array_unique($mis_unidades);
                }
                $mis_unidades = implode(",", $mis_unidades);

                if ($mis_unidades == "") {
                    return array(
                        "resultado" => false,
                        "mensaje" => "El usuario no tiene unidades vinculadas."
                    );
                }

                // Obtenemos los UID de los usuarios que han tenido vinculados en las unidades.
                $sql = "SELECT		
                        uad.uid UsuCodigo,
                        per.per_identificacion PerIdentificacion,
                        per.per_nombre PerNombre,
                        per.per_apellido PerApellido,
                        gru.gru_codigo Cargo
                    FROM		
                        dbo.usuario_grupo as usg
                    INNER JOIN dbo.grupo as gru ON usg.usg_grupo = gru.gru_codigo 
                    INNER JOIN dbo.usuario_general uad ON usg.usg_usuario = uad.uid
                    INNER JOIN dbo.persona per ON per.per_codigo = uad.up
                    INNER JOIN dbo.uaa ON uaa.uaa_codigo = usg.usg_uaa
                    WHERE		
                        gru.gru_codigo in ({$grupos})
                        AND usg.usg_uaa in ({$mis_unidades})
                    GROUP BY uad.uid,
                        per.per_identificacion,
                        per.per_nombre,
                        per.per_apellido,
                        gru.gru_codigo";
                
                if (!$cnx->consultar_login($sql)) {
                    header('Consola: '.__LINE__.'. No se pudieron obtener los usuarios de las unidades.');
                    return array(
                        "resultado" => false,
                        "mensaje" => "Error al consultar los usuarios de las unidades."
                    );
                }

                $usuarios_vinculados = $cnx->json;
            }

            
            $GruCodigo = $vinculaciones[0]["gru_codigo"]; // Se define el grupo con la vinculación actual.

            // Asigna el rol de Jefe de Programa a los jefes de departamento que NO tengan un jefe de programa vinculado a su dependencia.
            if($GruCodigo == $_SESSION['pacademica']['ROLES']['JEFE_DEPARTAMENTO']){

                // Verifica el cargo de los usuarios vinculados a la dependencia
                $tieneJefePrograma = false;
                foreach ($usuarios_vinculados as $usuarioV){
                    if ($usuarioV["Cargo"] == $_SESSION['pacademica']['ROLES']['JEFE_PROGRAMA']){ // Evalúa si es un Jefe de Programa.
                        $tieneJefePrograma = true;
                    }
                }

                if($tieneJefePrograma){ 
                    $GruCodigo = $_SESSION['pacademica']['ROLES']['SECRETARIA'];
                }else{
                    $GruCodigo = $_SESSION['pacademica']['ROLES']['JEFE_PROGRAMA'];
                }
            }

            $administrador = 0;

            $salida = array(
                "personaIdentificacion" => $vinculaciones[0]["per_identificacion"],
                "personaCodigo" => $vinculaciones[0]["per_codigo"],
                "personaNombre" => $vinculaciones[0]["per_nombre"],
                "personaApellido" => $vinculaciones[0]["per_apellido"],
                "usuarioNombre" => $vinculaciones[0]["us"],
                "usuarioCodigo" => $vinculaciones[0]["uid"],
                "uaaCodigo" => $vinculaciones[0]["uaa_codigo"],
                "uaaNombreCorto" => $vinculaciones[0]["uaa_nombre_corto"],
                "vinculacionCodigo" => $vinculaciones[0]["uap_codigo"],
                "cargoNombre" => $vinculaciones[0]["car_nombre"],
                "grupoCodigo" => $GruCodigo,
                "grupoNombre" => $vinculaciones[0]["gru_nombre"],
                "grupoId" => $vinculaciones[0]["gru_id"],
                "Administrador" => $administrador,
                "unidades" => $mis_unidades,
                "usuariosVinculados" => $usuarios_vinculados,
            );

            return $salida;
        } //fin else

    } //fin consultarVinculacionActual

    // Función para consultar y parametrizar los roles que se utilizan dentro del aplicativo
    public function obtenerRolesSistema(){

        require_once '../conexion/cls_config.php';
        $cnx = new cls_config("Login.obtenerRolesSistema");
        
        $sql = "SELECT wep_valor as Roles FROM dbo.web_parametro WHERE wep_codigo = 547 AND wep_estado = 1";
        if (!$cnx->consultar_login($sql)) {
            return array(
                "estado" => false,
                "mensaje" => "Error al consultar los roles.",
                "consola" => "Fallo en el query a web_parametro ".__LINE__.""
            );
        }

        $roles = $cnx->json[0]['Roles'];

        return array(
            "estado" => true,
            "mensaje" => "Roles consultados correctamente.",
            "valor" => $roles,
        );
    }

    // Inicio funcion para validar token
    public function validarToken($usuario, $codigo)
    {

        if (!is_file('../conexion/cls_config.php')) {
            return array(
                "valido" => false,
                "mensaje" => "No hay archivo de conexion"
            );
        }

        require_once '../conexion/cls_config.php';
        $cnx = new cls_config("Login.validarToken");
        // Inicia implementacion token contraseña 1
        $sql = "select uid from dbo.usuario_programacion where us = '{$usuario}' "; //obtenemos uid del usuario.
        if (!$cnx->consultar_login($sql)) {
            return array(
                "valido" => false,
                "mensaje" => "Error al uid de usuario {$usuario}",
            );
        }
        $uid = $cnx->json[0]['uid'];

        $ip = ""; // Obtenemos la ip del usuario donde se inicio sesion.
        if (!empty($_SERVER['HTTP_CLIENT_IP'])) {
            $ip = $_SERVER['HTTP_CLIENT_IP'];
        } elseif (!empty($_SERVER['HTTP_X_FORWARDED_FOR'])) {
            $ip = $_SERVER['HTTP_X_FORWARDED_FOR'];
        } else {
            $ip = $_SERVER['REMOTE_ADDR'];
        }
        $modCodigo = 13; // 13 es el codigo de programacion academica

        //generar un token para consultar al servicio
        $sql = "select token.getTokenInicioSesion('" . $modCodigo . $uid . $ip . "') as token_resultado";
        if (!$cnx->consultar_login($sql)) {
            return array(
                "valido" => false,
                "mensaje" => "Error al generar token.",
            );
        }
        $token = $cnx->json[0]['token_resultado'];

        $resultPeticion = self::validarCodigoVerificacion($modCodigo, $uid, $ip, $token, $codigo);

        // Comprobamos si el resultado es falso (Error al verificar el token)
        if ($resultPeticion['estado'] == false) {
            return array(
                "valido" => false,
                "mensaje" => $resultPeticion["mensaje"],
                "consola" => $resultPeticion["consola"],
            );
        }

        // Return para que fuera valido.
        return array(
            "valido" => true,
            "codigo" => $codigo,
            "mensaje" => "El token esta bien y se encuentra vigente.",
        );
    }

    //funcion para enviar una peticion al sistema de generacion de
    //codigos de verificacion para validar un codigo que introdujo el usuario
    //para ver si es correcto. Devulve un array
    public static function validarCodigoVerificacion($modCodigo, $uid, $ip, $token, $codigoVerificacion)
    {

        if (!is_file('../conexion/cls_config.php')) {
            return array(
                "valido" => false,
                "mensaje" => "No hay archivo de conexion"
            );
        }

        require_once '../conexion/cls_config.php';
        $cnx = new cls_config("Login.validarCodigoVerificacion");
        $sql = "SELECT 
            wep_valor WepValor 
        FROM 
            web_parametro 
        WHERE 
            wep_nombre LIKE 'TOKEN_URL_AUTENTICACION'";

        if (!$cnx->consultar_login($sql)) {
            return array(
                "valido" => false,
                "mensaje" => "Error al consultar la ruta del servicio token.",
            );
        }

        $rutaServicio = $cnx->json[0]['WepValor'] . 'api/validarCodigo';

        //definimos cada uno de los parametros del cuerpo de la peticion
        $bodyPeticion = http_build_query(
            array(
                "aplicativo" => base64_encode($modCodigo),
                "usuario" => base64_encode($uid),
                "ip" => base64_encode($ip),
                "codigoVerificacion" => base64_encode($codigoVerificacion),
            )
        );

        //definimos cada uno de los parametros de la cabecera de la peticion
        $headerPeticion = array(
            "Authorization: " . base64_encode($token) . " ",
            "Content-Type: application/x-www-form-urlencoded ",
        );

        //abrimos la sesión cURL
        $ch = curl_init();

        // definimos la URL a la que hacemos la petición
        curl_setopt($ch, CURLOPT_URL, $rutaServicio);
        // indicamos el tipo de petición: POST
        curl_setopt($ch, CURLOPT_POST, true);
        // definimos cada uno de los parámetros del cuerpo
        curl_setopt($ch, CURLOPT_POSTFIELDS, $bodyPeticion);

        curl_setopt($ch, CURLOPT_HTTPHEADER, $headerPeticion);

        //indicamos que debe recibir el mensaje de retorno
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);

        //guardamos el mensaje que retornó el servidor remoto
        $respuestaServer = curl_exec($ch);

        if ($respuestaServer === false) {
            return array(
                "estado" => false,
                "mensaje" => "Hay error al solicitar un código de verificación.",
                "consola" => curl_error($ch),
            );
        }
        // Codigo permitido. ( [estado] => 1 [mensaje] => El cÃ³digo de verificaciÃ³n es correcto [consola] => Se permite el ingreso )
        // Ya se uso. ( [estado] => [mensaje] => El cÃ³digo de verificaciÃ³n ya fue usado o estÃ¡ inactivo [consola] => El cÃ³digo de verificaciÃ³n ya fue usado o estÃ¡ inactivo )
        // Codigo erroneo. ( [estado] => [mensaje] => El cÃ³digo de verificaciÃ³n es incorrecto [consola] => El cÃ³digo de verificaciÃ³n que se ha enviado es diferente al que esta guardado )
        // No se ha generado codigo. ( [estado] => [mensaje] => No se han encontrado cÃ³digos de verificaciÃ³n asociados al usuario. [consola] => No se encontraron registros al consultar la bd )

        // cerramos la sesión cURL
        curl_close($ch);

        //agarra la respuesta (que es un string json) y lo convierte
        //en array para manejarlo con php
        $arrayRespuesta = json_decode($respuestaServer, true);

        return $arrayRespuesta;
    }
} //FIn Clase
