<?php
date_default_timezone_set('America/Bogota');

class Exclu
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

    // Inicio funcion eliminarExclusividad
    // Permite eliminar la exclusividad de un plan academico con un curso especifico
    public function eliminarExclusividad($obj)
    {
        // Parametros:
        $CurCodigo = $obj->CurCodigo; // Contiene el codigo del curso
        $PlaCodigo = $obj->PlaCodigo; // Contiene el codigo del plan academico.
        $PlaNombre = $obj->PlaNombre; // Contiene el nombre del plan academico.

        // Iniciamos la transacción en caso de algun fallo
        $this->cnx->sentencia("BEGIN TRAN");

        // Realizamos el delete 
        $sql = "DELETE FROM
            curso_plan
        WHERE
            cur_codigo = {$CurCodigo} AND
            pla_codigo = {$PlaCodigo}
        ";

        // Ejecutamos la sentencia
        if (!$this->cnx->sentencia($sql)) {
            $this->errorSentenciaBd["mensaje"] = "Error al eliminar la exclusividad del plan academico {$PlaNombre} con el curso {$CurCodigo}.";
            $this->errorSentenciaBd["consola"] = "No se puedo realizar el delete del plan academico {$PlaCodigo}. {$PlaNombre} con el curso {$CurCodigo}.";
            $this->cnx->sentencia("ROLLBACK TRAN"); //Se realiza un rollback si se encuentra un error
            return $this->errorSentenciaBd;
        }

        $this->cnx->sentencia("COMMIT TRAN"); // De no encontrar errores guardamos el resultado

        // Consultamos si el curso tiene o no mas exclusividades para validar si se actualiza o no el curso.
        $sql = "SELECT
            cur_codigo CurCodigo
        FROM
            curso_plan
        WHERE 
            cur_codigo = {$CurCodigo}
        ";

        // Ejecutamos la consulta
        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["mensaje"] = "Fallo al consultar si el curso {$CurCodigo} aun tiene exclusividad con algun plan académico.";
            $this->errorConsultarBd["consola"] = "Fallo al consultar si el curso cuenta con mas planes academicos exclusivos.";
            return $this->errorConsultarBd;
        }

        $r_plan_exclusivos = $this->cnx->json;

        if (count($r_plan_exclusivos) <= 0) {
            // Quitamos la exclusividad del curso
            $sql = "UPDATE
                curso
            SET
                cur_exclusivo = 0,
                cur_fecha_actualizacion = GETDATE()
            WHERE
                cur_codigo = {$CurCodigo}
            ";

            // Iniciamos la transacción en caso de algun fallo
            $this->cnx->sentencia("BEGIN TRAN");

            // Ejecutamos la sentencia
            if (!$this->cnx->sentencia($sql)) {
                $this->errorSentenciaBd["mensaje"] = "Error al actualizar como no exclusivo el curso {$CurCodigo}.";
                $this->errorSentenciaBd["consola"] = "Ha fallado al actualizar el curso {$CurCodigo} como no exclusivo.";
                $this->cnx->sentencia("ROLLBACK TRAN"); //Se realiza un rollback si se encuentra un error
                return $this->errorSentenciaBd;
            }

            $this->cnx->sentencia("COMMIT TRAN"); // De no encontrar errores guardamos el resultado

            return array(
                "resultado" => true,
                "mensaje" => "Se cambio el curso {$CurCodigo} como no exclusivo y se eliminó la exclusividad del plan {$PlaNombre} con el curso {$CurCodigo}."
            );
        } else {
            return array(
                "resultado" => true,
                "mensaje" => "Se eliminó la exclusividad del plan {$PlaNombre} con el curso {$CurCodigo}."
            );
        }
    }


    // Inicio funcion agregarExclusividad
    // Permite agregar la exclusividad de un plan academico con un curso especifico
    public function agregarExclusividad($obj)
    {
        // Parametros:
        $CurCodigo = $obj->CurCodigo; // Contiene el codigo del curso
        $PlaCodigo = $obj->PlaCodigo; // Contiene el codigo del plan academico.
        $PlaNombre = $obj->PlaNombre; // Contiene el nombre del plan academico.

        // Consultamos si el curso ya esta marcado como exclusivo.
        $sql = "SELECT 
            cur_exclusivo CurExclusivo
        FROM 
            curso
        WHERE
            cur_codigo = {$CurCodigo}
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["mensaje"] = "Fallo al consultar si el curso {$CurCodigo} es exclusivo";
            $this->errorConsultarBd["consola"] = "Fallo al consultar si el curso es exclusivo";
            return $this->errorConsultarBd;
        }

        // Almacenamos la exclusividad 1: Si, 0: No
        $CurExclusivo = $this->cnx->json[0]['CurExclusivo'];

        //Validamos si es o no exclusivo
        if ($CurExclusivo == 0) {
            //En caso de no estar marcado como exclusivo realizamos el update del curso
            $sql = "UPDATE
                curso
            SET
                cur_exclusivo = 1,
                cur_fecha_actualizacion = GETDATE()
            WHERE
                cur_codigo = {$CurCodigo}
            ";

            // Iniciamos la transacción en caso de algun fallo
            $this->cnx->sentencia("BEGIN TRAN");

            // Ejecutamos la sentencia
            if (!$this->cnx->sentencia($sql)) {
                $this->errorSentenciaBd["mensaje"] = "Error al actualizar a exclusivo el curso {$CurCodigo}.";
                $this->errorSentenciaBd["consola"] = "Ha fallado al actualizar el curso {$CurCodigo} como exclusivo.";
                $this->cnx->sentencia("ROLLBACK TRAN"); //Se realiza un rollback si se encuentra un error
                return $this->errorSentenciaBd;
            }

            $this->cnx->sentencia("COMMIT TRAN"); // De no encontrar errores guardamos el resultado
        }

        // Iniciamos el proceso para guardar el plan academico con el curso

        $sql = "INSERT INTO
            curso_plan (
                cur_codigo, 
                pla_codigo
            )
            VALUES(
                {$CurCodigo},
                {$PlaCodigo}
            )
        ";

        // Iniciamos la transacción en caso de algun fallo
        $this->cnx->sentencia("BEGIN TRAN");

        // Ejecutamos la sentencia
        if (!$this->cnx->sentencia($sql)) {
            $this->errorSentenciaBd["mensaje"] = "Error al crear la exclusividad del plan {$PlaNombre} con el curso {$CurCodigo}.";
            $this->errorSentenciaBd["consola"] = "Ha fallado al realizar el insert del plan academico {$PlaCodigo}. {$PlaNombre} con el curso {$CurCodigo}.";
            $this->cnx->sentencia("ROLLBACK TRAN"); //Se realiza un rollback si se encuentra un error
            return $this->errorSentenciaBd;
        }

        $this->cnx->sentencia("COMMIT TRAN"); // De no encontrar errores guardamos el resultado

        return array(
            "resultado" => true,
            "mensaje" => "Se marco el curso {$CurCodigo} como exclusivo y se creo la exclusividad del plan {$PlaNombre} con el curso {$CurCodigo}."
        );
    }


    // Inicio funcion consultarExclusividadCurso
    // Permite consultar la exclusividad de un curso especifico con algun plan academico
    public function consultarExclusividadCurso($obj)
    {
        // Parametros: 
        $CurCodigo = $obj->CurCodigo; //Almacena el codigo del curso en especifico.

        $salida = array();

        if (!isset($CurCodigo) || strlen($CurCodigo) < 3) {
            $this->errorConsultarBd["mensaje"] = "No se ha ingresado el código del curso.";
            $this->errorConsultarBd["consola"] = "No se ha enviado el código del curso.";
            return $this->errorConsultarBd;
        }

        // En la consulta inicial, trae los planes que si tienen exclusividad en el curso
        // En la consulta siguiente, trae los planes que no tienen exclusividad en el curso
        //tiene exclusividad, 1 si esta vinculado, 2 si no esta vinculado
        $sql = "SELECT 
                pla.pla_codigo PlaCodigo, 
                pla.pla_nombre PlaNombre, 
                uaa.uaa_nombre_corto UaaNombreCorto, 
                '1' tiene_exclusividad,
                'exclusivo' PlaExclusivo
            FROM 
                plan_academico pla
            INNER JOIN programa pro ON pla.pro_codigo=pro.pro_codigo
            INNER JOIN uaa uaa ON pro.uaa_codigo=uaa.uaa_codigo
            WHERE 
                uaa.uaa_nombre_corto NOT IN('desconocido') AND
                pla.pla_codigo IN (
                    SELECT pla_codigo FROM curso_plan
                    WHERE cur_codigo= {$CurCodigo}
                )

            UNION ALL
            
            SELECT 
                pla.pla_codigo PlaCodigo, 
                pla.pla_nombre PlaNombre, 
                uaa.uaa_nombre_corto UaaNombreCorto, 
                '2' tiene_exclusividad,
                '' PlaExclusivo
            FROM 
                plan_academico pla
            INNER JOIN programa pro ON pla.pro_codigo=pro.pro_codigo
            INNER JOIN uaa uaa ON pro.uaa_codigo=uaa.uaa_codigo
            WHERE 
                uaa.uaa_nombre_corto NOT IN('desconocido') AND
                pla.pla_codigo NOT IN (
                    SELECT pla_codigo FROM curso_plan
                    WHERE cur_codigo = {$CurCodigo}
            )
            ORDER BY 
                tiene_exclusividad ASC, 
                uaa_nombre_corto ASC
            ";


        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["mensaje"] = "No se pudieron consultar los planes exclusivos del curso.";
            $this->errorConsultarBd["consola"] = "Consulta planes con exclusividad";
            return $this->errorConsultarBd;
        }

        $r_lista_planes = $this->cnx->json;

        foreach ($r_lista_planes as $fila) {
            if ($fila["tiene_exclusividad"] == "1") {
                $fila["tieneExclusividad"] = true;
            }
            if ($fila["tiene_exclusividad"] == "2") {
                $fila["tieneExclusividad"] = false;
            }
        }

        return $r_lista_planes;
    }
}
