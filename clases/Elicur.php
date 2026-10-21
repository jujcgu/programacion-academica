<?php
date_default_timezone_set('America/Bogota');
require_once "Curhorario.php";
require_once "Cupocurso.php";

class Elicur
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
        "mensaje" => "Error al realizar la acción en la base de datos",
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

    public function consultarPermisosEliminacion($obj){
        // Validamos las variables recibidas que exista y que sea numerico
        if (!isset($obj->CurCodigo) || !is_numeric($obj->CurCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe ingresar el número del curso",
                "consola" => "No es numerico o no hay número",
            );
        }
        if (!isset($obj->CalCodigo) || !is_numeric($obj->CalCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se encontró el número del calendario",
                "consola" => "No es numerico o no hay número",
            );
        }
        if (!isset($obj->UsuCodigo) || !is_numeric($obj->UsuCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se encontró el número del usuario",
                "consola" => "No es numerico o no hay número",
            );
        }
        if (!isset($obj->UaaCodigo) || !is_numeric($obj->UaaCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se encontró el número de la unidad",
                "consola" => "No es numerico o no hay número",
            );
        }

        $CurCodigo = $obj->CurCodigo;
        $CalCodigo = $obj->CalCodigo;
        $UsuCodigo = $obj->UsuCodigo;
        $UaaCodigo = $obj->UaaCodigo;
        
        $uaasPerfil = $_SESSION['pacademica']['datosVinculacionUsuario']['unidades']; //obtenemos las uaas del perfil
        $uid = $_SESSION['pacademica']['datosVinculacionUsuario']['usuarioCodigo']; //obtenemos el id del usuario
        $apertura_programacion_permitida = false;
        
        $objclass = new Cupocurso();
        $calendariosArrayProgramacion = $objclass->consultarCalendarioActivoProgramacion(); //consultamos los calendarios activos para programacion academica

        //Verificamos que el curso este en un calendario abierto para la programacion academica
        foreach ($calendariosArrayProgramacion as $calendario) {
            if ($calendario['CalCodigo'] == $CalCodigo && $calendario['UaaCodigo'] == $UaaCodigo) {
                $apertura_programacion_permitida = true;
            }

            if($calendario['CalCodigo'] == $CalCodigo && $UsuCodigo == $uid){
                $apertura_programacion_permitida = true;
            }
        }

        // if($apertura_programacion_permitida == true AND $UsuCodigo != $uid){
        //     $apertura_programacion_permitida = false;
        // }


        if ($_SESSION['pacademica']['datosVinculacionUsuario']['grupoId'] == 'PROGRAMACION_ACADEMICA_ADMINISTRADOR') {
            $apertura_programacion_permitida = true;
        }

        return array(
            "resultado" => true,
            "PermiteEditar" => $apertura_programacion_permitida,
            // "PermiteEditar" => false,
        );

    }

    //Permite eliminar el curso y/o subgrupo especifico.
    //Si elimina el curso elimina todos los subgrupos tambien
    //Si elimina un subgrupo solo elimina ese.
    public function eliminarCursoSubgrupo($obj)
    {

        // Validamos las variables recibidas que exista y que sea numerico
        if (!isset($obj->Tipo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio correctamente el tipo de eliminación, curso o subgrupo.",
                "consola" => "No es numerico o no hay número",
            );
        }

        // Validamos las variables recibidas que exista y que sea numerico
        if (!isset($obj->CurCodigo) || !is_numeric($obj->CurCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe ingresar el número del curso",
                "consola" => "No es numerico o no hay número",
            );
        }

        if ($obj->Tipo == "Curso") {
            // Validamos las variables recibidas que exista y que sea numerico
            if (!isset($obj->CurObservacion)) {
                return array(
                    "resultado" => false,
                    "mensaje" => "No se envio correctamente la justificación de eliminación del curso.",
                    "consola" => "No se envio la justificación",
                );
            }
        }

        if ($obj->Tipo == "Subgrupo") {
            // Validamos las variables recibidas que exista y que sea numerico
            if (!isset($obj->CusCodigo) || !is_numeric($obj->CusCodigo)) {
                return array(
                    "resultado" => false,
                    "mensaje" => "No se envio correctamente el código del subgrupo",
                    "consola" => "No es numerico o no hay número",
                );
            }

            // Validamos las variables recibidas que exista y que sea numerico
            if (!isset($obj->EsoSubgrupo)) {
                return array(
                    "resultado" => false,
                    "mensaje" => "No se envio correctamente el nombre del subgrupo.",
                    "consola" => "No es numerico o no hay número",
                );
            }
        }

        $CurCodigo = $obj->CurCodigo; //Codigo del curso 
        $EsoSubgrupo = $obj->EsoSubgrupo; //Nombre del subgrupo
        $CusCodigo = $obj->CusCodigo; //Codigo del subgrupo en la tabla cupo_curso_subgrupo
        $CurObservacion = utf8_decode($obj->CurObservacion); //Contiene la observación si lo que se va a eliminar es un curso
        $Tipo = $obj->Tipo; //Contiene el tipo de operación Curso: Elimina todo el curso con subgrupos, Subgrupo: Solo lo relacionado a ese subgrupo.

        //Obtenemos una vinculacion de un docente NN para cargarle la agenda temporalmente
        $sql = "SELECT top 1 
            uap.uap_codigo UapCodigo
        FROM 
            persona per
        INNER JOIN uaa_personal uap on uap.per_codigo = per.per_codigo
        WHERE 
            per_apellido LIKE 'NN CATEDR%'
        ORDER BY uap_fecha_inicio ASC";

        //Se verifica que se ejecute la consulta
        if (!$this->cnx->Consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error en consultar la vinculación de un docente NN";
            return $this->errorConsultarBd;
        }

        //Se almacenan los registros
        $r_docente_nn = $this->cnx->json; //$r_docente_nn[0]["UapCodigo]


        if ($Tipo == "Curso") {
            // Se elimina el curso y todo lo demas

            //Se inactiva el curso con observación obligatoria
            $sql = "UPDATE
                    curso
                SET
                    cur_estado = 0,
                    cur_observaciones = '{$CurObservacion}',
                    uap_codigo = {$r_docente_nn[0]['UapCodigo']},
                    cur_fecha_actualizacion = GETDATE()
                WHERE
                    cur_codigo = {$CurCodigo}
            ";

            if (!$this->cnx->sentencia($sql)) {
                $this->errorSentenciaBd["mensaje"] = "Error al actualizar el estado del curso. 
                    Recargue la página e intente de nuevo.";
                $this->errorSentenciaBd["consola"] = "Ha fallado la actualización del curso. L:" . __LINE__;
                return $this->errorSentenciaBd;
            }

            // Se inactiva todos los subgrupo del curso
            $sql = "UPDATE 
                    curso_cupo_subgrupo 
                SET 
                    cus_estado = 0 
                WHERE 
                    cur_codigo = {$CurCodigo}
            ";

            if (!$this->cnx->sentencia($sql)) {
                $this->errorSentenciaBd["mensaje"] = "Error al actualizar el estado de los subgrupos del curso. 
                    Recargue la página e intente de nuevo.";
                $this->errorSentenciaBd["consola"] = "Ha fallado la actualización de los subgrupos del curso. L:" . __LINE__;
                return $this->errorSentenciaBd;
            }

            //Elimina todo el horario del curso
            $sql = "UPDATE 
                    espacio_ocupacion 
			    SET 
                    eso_actividad = null, 
                    uap_codigo = null, 
                    eso_subgrupo = null
			    WHERE 
                    eso_actividad = {$CurCodigo}
            ";

            if (!$this->cnx->sentencia($sql)) {
                $this->errorSentenciaBd["mensaje"] = "Error al actualizar el horario del curso. 
                    Recargue la página e intente de nuevo.";
                $this->errorSentenciaBd["consola"] = "Ha fallado la actualización del horario del curso. L:" . __LINE__;
                return $this->errorSentenciaBd;
            }
        }

        if ($Tipo == "Subgrupo") {
            // Se elimina lo relacionado al subgrupo solamente

            // Se inactiva el subgrupo seleccionado del curso
            $sql = "UPDATE 
                    curso_cupo_subgrupo 
                SET 
                    cus_estado = 0 
                WHERE 
                    cus_cod = {$CusCodigo}
            ";

            if (!$this->cnx->sentencia($sql)) {
                $this->errorSentenciaBd["mensaje"] = "Error al actualizar el estado del subgrupo del curso. 
                    Recargue la página e intente de nuevo.";
                $this->errorSentenciaBd["consola"] = "Ha fallado la actualización del subgrupo del curso. L:" . __LINE__;
                return $this->errorSentenciaBd;
            }

            //Elimina todo el horario del curso
            $sql = "UPDATE 
                    espacio_ocupacion 
                SET 
                    eso_actividad = null, 
                    uap_codigo = null, 
                    eso_subgrupo = null
                WHERE 
                    eso_actividad = {$CurCodigo}
                    AND eso_subgrupo = {$EsoSubgrupo}
            ";

            if (!$this->cnx->sentencia($sql)) {
                $this->errorSentenciaBd["mensaje"] = "Error al actualizar el horario del curso. 
                    Recargue la página e intente de nuevo.";
                $this->errorSentenciaBd["consola"] = "Ha fallado la actualización del horario del curso. L:" . __LINE__;
                return $this->errorSentenciaBd;
            }
        }

        //Creamos un objeto para llamar el metodo actualizarAgenda de la clase Curhorario
        $objclass = new Curhorario();
        if (!$objclass->actualizarAgenda($CurCodigo)) {
            return array(
                "resultado" => true,
                "mensaje" => "{$Tipo} eliminado correctamente,la agenda no se actualizo correctamente.",
            );
        } else {
            return array(
                "resultado" => true,
                "mensaje" => "{$Tipo} eliminado correctamente,la agenda se actualizo correctamente.",
            );
        }
    }

    //Permite consultar los subgrupos de un curso especifico
    public function consultarSubgrupoCurso($obj)
    {

        // Validamos las variables recibidas que exista y que sea numerico
        if (!isset($obj->curCodigo) || !is_numeric($obj->curCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe ingresar el número del curso",
                "consola" => "No es numerico o no hay número",
            );
        }

        $CurCodigo = $obj->curCodigo; //obtenemos el codigo del curso

        $sql = "SELECT 
            cus.cus_cod CusCodigo, 
            cus.cur_codigo CurCodigo, 
            cus.eso_subgrupo EsoSubgrupo, 
            cus.cus_cupo CusCupo, 
            cus.cus_estado CusEstado,  
            (
                select count(*)
                from matricula_curso mc
                inner join matricula ma on (mc.mat_codigo=ma.mat_codigo)
                where ma.mat_estado='A' and mc.maa_codigo in (1,2)
                and mc.cur_codigo=cus.cur_codigo and mc.mac_subgrupo =cus.eso_subgrupo
            ) as TotalMatriculados,
		    (
                select top 1 per_nombre + ' ' + per_apellido docenteNombre
                from espacio_ocupacion eso 
                inner join uaa_personal uap on uap.uap_codigo = eso.uap_codigo
                inner join persona per on per.per_codigo = uap.per_codigo
                where eso.eso_actividad = {$CurCodigo} and eso_subgrupo = cus.eso_subgrupo
                
            ) as PerNombreApellido
		from curso_cupo_subgrupo cus
		inner join curso cur on (cur.cur_codigo=cus.cur_codigo)
		where cus.cur_codigo = {$CurCodigo} --and cus.cus_estado = 1
		order by eso_subgrupo asc";

        // --union all
        // --select null as cus_cod, {$CurCodigo} as cur_codigo, '00' as eso_subgrupo,";


        //Se verifica que se ejecute la consulta
        if (!$this->cnx->Consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error en consulta buscar sub grupo del curso";
            return $this->errorConsultarBd;
        }

        //Se almacenan los registros
        $result = $this->cnx->json;

        return array(
            "resultado" => true,
            "mensaje" => "Sub grupos consultados correctamente.",
            "count" => count($result),
            "data" => $result
        );
    } //fin consultarSubgrupoCurso

    //Permite consultar una lista de docentes NN
    public function consultarDocentesNN()
    {

        $sql = "SELECT 
            per.per_codigo PerCodigo, 
            per.per_nombre + ' ' + per.per_apellido PerNombreApellido, 
            per.per_identificacion PerIdentificacion
		from persona per
		inner join uaa_personal uap on uap.per_codigo=per.per_codigo
		where per.per_apellido like 'NN CATEDRA%'
		--que sea un nn que haya tenido vinculacion minimo 9 meses atras
		and uap.uap_fecha_inicio between convert( date, dateadd(month,-9,getdate()) ) and convert(date,getdate())
		group by per.per_codigo, per.per_nombre, per.per_apellido, per.per_identificacion
		order by per.per_nombre
        ";

        //Se verifica que se ejecute la consulta
        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar docentes NN.";
            return $this->errorConsultarBd;
        }
        $r_contenido = $this->cnx->json;
        return array(
            "resultado" => true,
            "mensaje" => "Docentes NN consultados correctamente.",
            "date" => date("Ymd"),
            "data" => $r_contenido,
        );
    }
}
