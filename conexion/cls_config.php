<?php
header("Content-Type:application/json");
header('Content-type: text/html; charset=UTF-8');
header('Content-type: text/html; charset=ISO-8859-1');

class cls_config
{

    //Variables que vienen de usuario
    public $usuario_bd_consulta; //Usuario BD
    public $clave_bd_consulta; //Clave BD

    public $usuario_bd_login; //Usuario BD
    public $clave_bd_login; //Clave BD

    public $usuario_bd_real; //Usuario BD
    public $clave_bd_real; //Clave BD


    public $acceso_datos; //Nombre conexion
    public $base_datos;
    public $host;
    public $port;
    public $nombre_funcion; //Nombre de función

    //Variables locales
    public $conexion; //Conexión de BD
    public $jsonData = array();
    public $json;
    public $resultado; //Resultado de consulta
    public $registros; //Cantidad de registros encontrados en consulta
    public $id; //Último id agregado a la tabla
    public $count;
    public $mjeError; //Mensaje de error
    public $cantRegistros; //Cantidad de registros afectados por una sentencia

    //Cargamos las variables globales de la función
    public function cls_config($funcion = "")
    {
        error_reporting(E_ALL & ~E_WARNING & ~E_NOTICE);

        $props_file = "props/pacademica.ini"; //Buscamos el archivo props del modulo
        if (file_exists("../" . $props_file)) {
            $props = parse_ini_file("../" . $props_file);
        } elseif (file_exists("../../" . $props_file)) {
            $props = parse_ini_file("../../" . $props_file);
        } elseif (file_exists("../../../" . $props_file)) {
            $props = parse_ini_file("../../../" . $props_file);
        }

        $this->nombre_funcion = $funcion; //Si trae nombre la funcion la guardamos
        $this->acceso_datos = $props['acceso_datos']; //Cargamos la direccion a la base de datos que va a apuntar.
        $this->host = $props['host'];
        $this->base_datos = $props['base_datos'];
        $this->port = $props['port'];

        // Credenciales Usuario Real
        $this->usuario_bd_real = $_SESSION['pacademica']['usuario_real'];
        $this->clave_bd_real = $_SESSION['pacademica']["clave_real"];

        // Credenciales usuario login
        $this->usuario_bd_login = $props['usuario_login'];
        $this->clave_bd_login = $props['contra_login'];

        // Credenciales usuario consultas
        $this->usuario_bd_consulta = $props['usuario_consulta'];
        $this->clave_bd_consulta = $props['contra_consulta'];
    } //fin constructor

    //metodo para crear una conexion a la bd
    function conectar($usuario, $contra)
    {
        try {
            error_reporting(E_ALL & ~E_WARNING & ~E_NOTICE);
            // $x = "odbc:" . $this->acceso_datos . ""; // Se establece a donde se dirije la conexion
            // $this->conexion = new PDO($x, $usuario, $contra);
            $dsn = "sqlsrv:Server=$this->host,$this->port;Database=$this->base_datos;TrustServerCertificate=true";
            $options = [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::SQLSRV_ATTR_ENCODING => PDO::SQLSRV_ENCODING_UTF8,
            ];

            $this->conexion = new PDO($dsn, $usuario, $contra, $options);
            return true;
        } catch (\Exception $e) {
            error_log($e->getMessage());
            $this->mjeError = $e->getMessage();
            return false;
        }
    }

    function consultar_login($sql)
    {
        if (!cls_config::conectar($this->usuario_bd_login, $this->clave_bd_login)) {
            return false;
        }
        error_reporting(E_ALL & ~E_WARNING & ~E_NOTICE);

        try {

            $this->conexion->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            $this->conexion->setAttribute(PDO::ATTR_EMULATE_PREPARES, false);
            $resultado = $this->conexion->prepare($sql);

            $i = 0;
            $resultado->execute();
            while ($registros = $resultado->fetch()) {
                $arregloTemporal[$i] = array_map('utf8_encode', $registros);
                $i++;
            }
            $this->json = $arregloTemporal;
            return true;
        } catch (Exception $e) {
            error_log($e->getMessage());
            $this->mjeError = $e->getMessage();
            return false;
        }
    }

    function consultar_login_real($sql)
    {
        if (!cls_config::conectar($this->usuario_bd_real, $this->clave_bd_real)) {
            return false;
        }
        error_reporting(E_ALL & ~E_WARNING & ~E_NOTICE);
        try {
            $this->conexion->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            $this->conexion->setAttribute(PDO::ATTR_EMULATE_PREPARES, false);
            $resultado = $this->conexion->prepare($sql);

            $i = 0;
            $resultado->execute();
            while ($registros = $resultado->fetch()) {
                $arregloTemporal[$i] = array_map('utf8_encode', $registros);
                $i++;
            }
            $this->json = $arregloTemporal;
            return true;
        } catch (Exception $e) {
            error_log($e->getMessage());
            $this->mjeError = $e->getMessage();
            return false;
        }
    }

    //metodo para ejecutar una consulta (select) en la bd
    function consultar($sql)
    {
        if (!cls_config::conectar($this->usuario_bd_consulta, $this->clave_bd_consulta)) {
            return false;
        }
        error_reporting(E_ALL & ~E_WARNING & ~E_NOTICE);

        try {

            $this->conexion->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            $this->conexion->setAttribute(PDO::ATTR_EMULATE_PREPARES, false);
            $resultado = $this->conexion->prepare($sql);

            $i = 0;
            $resultado->execute();
            while ($registros = $resultado->fetch()) {
                //$arregloTemporal[$i] = array_map('utf8_encode', $registros);
                $arregloTemporal[$i] = $registros;
                $i++;
            }
            $this->json = $arregloTemporal;
            return true;
        } catch (Exception $e) {
            error_log($e->getMessage());
            $this->mjeError = $e->getMessage();
            return false;
        }
    }

    //metodo para ejecutar un query (insert, update, delete)
    function sentencia($sql)
    {
        if (!cls_config::conectar($this->usuario_bd_real, $this->clave_bd_real)) {
            return false;
        }
        error_reporting(E_ALL & ~E_WARNING & ~E_NOTICE);

        try {
            $this->conexion->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            $this->conexion->setAttribute(PDO::ATTR_EMULATE_PREPARES, false);

            $this->resultado = $this->conexion->prepare($sql);
            $this->resultado->execute();
            $this->cantRegistros = $this->resultado->rowCount();
            return true;
        } catch (Exception $e) {
            $this->cantRegistros = 0;
            error_log("Error sentencia SQL: " . $e->getMessage() . " | SQL: " . substr($sql, 0, 500));
            $this->mjeError = $e->getMessage();
            return false;
        }
    }

    //cerrar conexión a BD
    function desconectar()
    {
        error_reporting(E_ALL & ~E_WARNING & ~E_NOTICE);
        $this->conexion = null;
    }
}
