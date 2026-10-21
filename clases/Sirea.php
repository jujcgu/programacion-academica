<?php
date_default_timezone_set('America/Bogota');

class Sirea
{
    private $cnx = null;

    private $errorConectarBd = array(
        "resultado" => false,
        "mensaje" => "Error al conectar con la base de datos",
        "consola" => "Metodo conectar() en bd",
    );
    private $errorConsultarBd = array(
        "resultado" => false,
        "mensaje" => "Error al consultar la base de datos",
        "consola" => "",
    );
    private $errorSentenciaBd = array(
        "resultado" => false,
        "mensaje" => "",
        "consola" => "",
    );

    public function __construct()
    {
        //Verificamos que se encuentr el archivo de conexion a la base de datos.
        if (!file_exists("../conexion/cls_config.php")) {
            echo "Archivo de conexion no encontrado";
            die;
        }
        require_once "../conexion/cls_config.php";
        $this->cnx = new cls_config();
    }

    // Inicio funcion consultarSubGrupo
    // Permite consultar los subgrupos de un curso especifico
    public function consultarSubGrupo($obj)
    {
        // Parametros 
        $CurCodigo = $obj->CurCodigo; // Contiene el codigo del curso seleccionado

        // Validamos las variables recibidas que exista y que sea numerico
        if (!isset($obj->CurCodigo) || !is_numeric($obj->CurCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo del curso.",
                "consola" => "El codigo del curso no viene o no es numerico, " . $obj->CurCodigo,
            );
        }

        $sql = "SELECT 
            cus.cus_cod CusCodigo, 
            cus.cur_codigo CurCodigo, 
            cus.eso_subgrupo EsoSubGrupo, 
            cus.cus_cupo CusCupo, 
            mun.mun_nombre MunNombre, 
            esp.esp_nombre EspNombre, 
            dep.dep_nombre DepNombre, 
            cie.cie_codigo CieCodigo, 
            (
                SELECT 
                    COUNT(*)
                FROM 
                    matricula_curso mc
                INNER JOIN matricula ma ON mc.mat_codigo = ma.mat_codigo
                WHERE 
                    ma.mat_estado = 'A' AND 
                    mc.maa_codigo IN (1,2) AND
                    mc.cur_codigo = cus.cur_codigo AND 
                    mc.mac_subgrupo = cus.eso_subgrupo
            ) AS cant_matriculados
        FROM curso_cupo_subgrupo cus
        INNER JOIN curso cur ON cur.cur_codigo = cus.cur_codigo
        LEFT JOIN curso_institucion_ejecucion cie ON cie.cur_codigo = cur.cur_codigo AND cie.cie_subgrupo = cus.eso_subgrupo AND cie.cie_estado = 1
        LEFT JOIN espacio esp ON esp.esp_codigo = cie.esp_codigo
        LEFT JOIN municipio mun on mun.mun_codigo = esp.mun_codigo
        LEFT JOIN departamento dep ON dep.dep_codigo = mun.dep_codigo
		WHERE 
            cus.cur_codigo = {$CurCodigo} AND 
            cus.cus_estado = 1
		ORDER BY eso_subgrupo ASC
		";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["mensaje"] = "No se pudo realizar la consulta de los subgrupos del curso.";
            $this->errorConsultarBd["consola"] = "No se pudo realizar la consulta de los subgrupos del curso.";
            return $this->errorConsultarBd;
        }

        return array(
            "resultado" => true,
            "mensaje" => "Subgrupos consultados correctamente.",
            "data" => $this->cnx->json
        );
    }

    // Inicio funcion eliminarSitioRealizacion
    // Permite eliminar el sitio de realizacion de un curso y subgrupo especifico.
    public function eliminarSitioRealizacion($obj)
    {
        // Parametros
        $CurCodigo = $obj->CurCodigo; //Contiene el codigo del curso.
        $SubGrupo = $obj->SubGrupo; //Contiene el sub grupo del curso.
        $CieCodigo = $obj->CieCodigo; //Contiene el codigo primario del sitio de realizacion del curso
        $UID = $_SESSION['pacademica']['datosVinculacionUsuario']['usuarioCodigo']; //Contiene el codigo del usuario que va a eliminar el sitio

        // Validamos las variables recibidas que exista y que sea numerico
        if (!isset($obj->CurCodigo) || !is_numeric($obj->CurCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo del curso.",
                "consola" => "El codigo del curso no viene o no es numerico, " . $obj->CurCodigo,
            );
        }

        if (!isset($obj->CieCodigo) || !is_numeric($obj->CieCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo del sitio de realización.",
                "consola" => "El codigo del sitio de realización no viene o no es numerico, " . $obj->CieCodigo,
            );
        }

        if (!isset($obj->SubGrupo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el subgrupo del curso.",
                "consola" => "El subgrupo del curso no viene, " . $obj->SubGrupo,
            );
        }

        // Iniciamos la transacción en caso de algun fallo
        $this->cnx->sentencia("BEGIN TRAN");

        // Realizamos el sql para actualizar.
        $sql = "UPDATE 
                curso_institucion_ejecucion
            SET 
                cie_estado = 0, 
                cie_uid_modifica = $UID, 
                cie_fecha_modifica = getdate()
            WHERE 
                cie_codigo = {$CieCodigo} 
        ";

        // Ejecutamos la sentencia
        if (!$this->cnx->sentencia($sql)) {
            $this->errorSentenciaBd["mensaje"] = "Error al eliminar el sitio de realización del curso {$CurCodigo} subgrupo {$SubGrupo}.";
            $this->errorSentenciaBd["consola"] = "No se puedo realizar la actualización del sitio de realización del curso {$CurCodigo} subgrupo {$SubGrupo} pk sitio realización {$CieCodigo}.";
            $this->cnx->sentencia("ROLLBACK TRAN"); //Se realiza un rollback si se encuentra un error
            return $this->errorSentenciaBd;
        }

        $this->cnx->sentencia("COMMIT TRAN"); // De no encontrar errores guardamos el resultado

        return array(
            "resultado" => true,
            "mensaje" => "Se elimino correctamente el sitio de realización del curso {$CurCodigo} subgrupo {$SubGrupo}."
        );
    }

    // Inicio funcion guardarSitioRealizacion
    // Permite guardar el sitio de realización de un curso y subgrupo especifico.
    public function guardarSitioRealizacion($obj)
    {
        // Parametros
        $CurCodigo = $obj->CurCodigo; //Contiene el codigo del curso.
        $EspCodigo = $obj->EspCodigo; //Contiene el codigo del espacio seleccionado.
        $SubGrupo = $obj->SubGrupo; //Contiene el sub grupo del curso.
        $UID = $_SESSION['pacademica']['datosVinculacionUsuario']['usuarioCodigo']; //Contiene el codigo del usuario que va a guardar el sitio

        // Validamos las variables recibidas que exista y que sea numerico
        if (!isset($obj->CurCodigo) || !is_numeric($obj->CurCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo del curso.",
                "consola" => "El codigo del curso no viene o no es numerico, " . $obj->CurCodigo,
            );
        }

        if (!isset($obj->EspCodigo) || !is_numeric($obj->EspCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el cupo del espacio externo.",
                "consola" => "El codigo del espacio no viene o no es numerico, " . $obj->EspCodigo,
            );
        }

        if (!isset($obj->SubGrupo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el subgrupo del curso.",
                "consola" => "El subgrupo del curso no viene, " . $obj->SubGrupo,
            );
        }

        // Iniciamos la transacción en caso de algun fallo
        $this->cnx->sentencia("BEGIN TRAN");

        // Realizamos el sql para insertar.
        $sql = "INSERT INTO 
            curso_institucion_ejecucion ( 
                cur_codigo, 
                cie_subgrupo,
                esp_codigo, 
                cie_estado, 
                cie_uid_inserta, 
                cie_fecha_inserta, 
                cie_uid_modifica, 
                cie_fecha_modifica
            ) 
            VALUES ( 
                {$CurCodigo}, 
                '{$SubGrupo}', 
                {$EspCodigo}, 
                1, 
                {$UID}, 
                getdate(), 
                {$UID}, 
                getdate() 
            )
        ";

        // Ejecutamos la sentencia
        if (!$this->cnx->sentencia($sql)) {
            $this->errorSentenciaBd["mensaje"] = "Error al guardar el sitio de realización del curso {$CurCodigo} subgrupo {$SubGrupo}.";
            $this->errorSentenciaBd["consola"] = "No se puedo realizar el insert del sitio de realización del curso {$CurCodigo} subgrupo {$SubGrupo} espacio {$EspCodigo}.";
            $this->cnx->sentencia("ROLLBACK TRAN"); //Se realiza un rollback si se encuentra un error
            return $this->errorSentenciaBd;
        }

        $this->cnx->sentencia("COMMIT TRAN"); // De no encontrar errores guardamos el resultado

        return array(
            "resultado" => true,
            "mensaje" => "Se guardo correctamente el sitio de realización del curso {$CurCodigo} subgrupo {$SubGrupo}."
        );
    }

    // Inicio funcion consultarSitiosExternos
    // Permite consultar los espacios marcados como externos
    public function consultarSitiosExternos()
    {

        $sql = "SELECT 
            esp.esp_codigo EspCodigo, 
            esp.esp_nombre EspNombre, 
            esp.esp_nombre_corto EspNombreCorto, 
            esp.esp_descripcion EspDescripcion, 
            eti.eti_codigo EtiCodigo, 
            eti.eti_nombre EtiNombre, 
            mun.mun_nombre MunNombre, 
            dep.dep_nombre DepNombre
        FROM espacio esp
        INNER JOIN espacio_tipo eti ON esp.eti_codigo = eti.eti_codigo
        INNER JOIN municipio mun ON mun.mun_codigo = esp.mun_codigo
        INNER JOIN departamento dep ON dep.dep_codigo = mun.dep_codigo
        WHERE esp.eti_codigo = 22 AND esp.esp_estado = 1
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["mensaje"] = "No se pudo consultar los sitios externos.";
            $this->errorConsultarBd["consola"] = "No se pudo realizar la consulta de los sitios externos.";
            return $this->errorConsultarBd;
        }

        return array(
            "resultado" => true,
            "mensaje" => "Sitios externos consultados correctamente.",
            "data" => $this->cnx->json
        );
    }

    // Inicio funcion consultarExclusividadCurso
    // Permite consultar el sitio de realizacion de un curso en especifico
    public function consultarExclusividadCurso($obj)
    {
        $CurCodigo = $obj->CurCodigo; //Almacena el codigo del curso en especifico.

        if (!isset($CurCodigo) || strlen($CurCodigo) < 3) {
            $this->errorConsultarBd["mensaje"] = "No se ha ingresado el código del curso.";
            $this->errorConsultarBd["consola"] = "No se ha enviado el código del curso.";
            return $this->errorConsultarBd;
        }

        $sql = "SELECT 
            cie.cie_codigo CieCodigo, 
            cur.cur_codigo CurCodigo, 
            cie_subgrupo CieSubGrupo,
            esp.esp_nombre EspNombre, 
            esp.esp_nombre_corto EspNombreCorto, 
            mun.mun_nombre MunNombre, 
            dep.dep_nombre DepNombre
        FROM 
            curso_institucion_ejecucion cie
        INNER JOIN espacio esp ON esp.esp_codigo = cie.esp_codigo
        INNER JOIN municipio mun ON mun.mun_codigo = esp.mun_codigo
        INNER JOIN departamento dep ON dep.dep_codigo = mun.dep_codigo
        INNER JOIN curso cur ON cie.cur_codigo = cur.cur_codigo
        WHERE 
            cie.cie_estado =  1 AND 
            cur.cur_codigo = {$CurCodigo} AND
            cie.cie_subgrupo = '00' --el cero cero va quemado porque es del curso 
            ";


        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["mensaje"] = "No se pudo consultar el sitio de realizacion del curso.";
            $this->errorConsultarBd["consola"] = "No se pudo realizar la consulta del sitio de realizacion del curso: {$CurCodigo}";
            return $this->errorConsultarBd;
        }

        return array(
            "resultado" => true,
            "mensaje" => "Sitio de realización consultado correctamente.",
            "data" => $this->cnx->json
        );
    }
}
