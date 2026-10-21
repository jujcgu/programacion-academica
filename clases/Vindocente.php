<?php

class Vindocente
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

    private $calendarioActual = ""; //Almacena el parametro del calendario actual.

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

    // Inicio funcion consultarAuditoriaVinculacion
    // Permite consultar la auditoria de la vinculacion seleccionada.
    function consultarAuditoriaVinculacion($obj)
    {
        if (!isset($obj->UapCodigo) || $obj->UapCodigo == '' || !is_numeric($obj->UapCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "El código de la vinculación no se envio correctamente o no es numérico."
            );
        }
        $UapCodigo = $obj->UapCodigo; //Contiene el codigo de la vinculacion del docente seleccionado.€
        $sql = "SELECT 
                uap.aud_tipo AudTipo,
                convert(varchar,uaa.uaa_codigo) + '. ' + uaa.uaa_nombre_corto UaaCodigoNombre,
                vin.vin_nombre VinNombre,
                ded.ded_nombre DedNombre,
                uap.per_codigo PerCodigo,
                (SELECT 
                    TOP 1 esc.esc_nombre 
                    FROM docente_escalafon doe 
                        INNER JOIN escalafon esc on esc.esc_codigo = doe.esc_codigo
                    WHERE 
                        doe.per_codigo = uap.per_codigo
                        AND (
                            doe.doe_fecha_fin is null
                            OR doe.doe_fecha_fin = ''
                        )
                    ORDER BY 
                        doe.doe_codigo DESC
                ) EscNombre,
                CONVERT (varchar, uap.uap_fecha_inicio , 23) UapFechaInicio,
                CONVERT (varchar, uap.uap_fecha_fin , 23) UapFechaFin,
                CONVERT (varchar, uap.aud_fecha , 23) + ' ' + CONVERT (varchar, uap.aud_fecha , 108) AudFecha
            FROM 
                aud_uaa_personal uap 
            INNER JOIN vinculacion vin on vin.vin_codigo = uap.vin_codigo
            INNER JOIN dedicacion ded on ded.ded_codigo = uap.ded_codigo
            INNER JOIN uaa on uaa.uaa_codigo = uap.uaa_codigo
            
            WHERE 
                uap.uap_codigo = {$UapCodigo}
            ORDER BY
                uap.aud_fecha DESC
        ";


        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar la auditoria de la vinculacion seleccionada {$UapCodigo}.";
            return $this->errorConsultarBd;
        }

        foreach($this->cnx->json as &$row){
            $row["AudTipo"] = trim($row["AudTipo"]);
        }

        return array(
            "resultado" => true,
            "mensaje" => "Auditoria consultada correctamente.",
            "data" => $this->cnx->json
        );
    }

    // Inicio funcion consultarCursosVinculacion
    // Permite consultar los cursos de una vinculacion especifica.  
    function consultarCursosVinculacion($obj)
    {
        if (!isset($obj->UapCodigo) || $obj->UapCodigo == '' || !is_numeric($obj->UapCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "El código de la vinculación no se envio correctamente o no es numérico."
            );
        }

        $UapCodigo = $obj->UapCodigo; //Contiene el codigo de la vinculacion del docente seleccionado.

        $sql = "SELECT 
                cal.cal_nombre CalNombre,
                cur.cur_codigo CurCodigo,
                tic.tic_nombre TicNombre, 
                asi.asi_nombre_corto AsiNombreCorto, 
                asi.asi_nombre AsiNombre,
                ( 
                	SELECT SUM(TotalSemanas)
                	FROM (
                		SELECT agp2.semanas TotalSemanas
	                	FROM agenda_periodo agp2 
	                	WHERE agp2.cur_codigo = eso.eso_actividad AND agp2.uap_codigo = eso.uap_codigo and agp2.sub_grupo = eso.eso_subgrupo group by agp2.uap_codigo, agp2.sub_grupo, agp2.semanas  
                	) as TempTotalSemanas
                ) CurSemanas,
                eso.eso_subgrupo EsoSubgrupo, 
                dia.dia_codigo DiaCodigo, 
                dia.dia_nombre DiaNombre, 
                hra.hra_inicio HoraInicio,
                hra.hra_fin HoraFin,
                esp.esp_nombre + ' ' +  esp.esp_nombre_corto EspNombre,
                convert(varchar, uaa.uaa_codigo) + ' ' + uaa.uaa_nombre_corto UaaCodigoNombre,
                case when cur.cur_estado = 1 then 'Activo' else 'Eliminado' end CurEstado
            from espacio_ocupacion_total eso
            inner join curso cur on cur.cur_codigo=eso.eso_actividad
            inner join agenda_periodo agp on agp.cur_codigo = cur.cur_codigo
            inner join asignatura asi on asi.asi_codigo=cur.asi_codigo
            inner join calendario cal on cal.cal_codigo=cur.cal_codigo
            inner join dia on dia.dia_codigo=eso.dia_codigo
            inner join hora hra on hra.hra_codigo = eso.hra_codigo
            inner join tipo_curso tic on tic.tic_codigo = cur.tic_codigo
            inner join espacio esp on esp.esp_codigo = eso.esp_codigo
            inner join uaa on uaa.uaa_codigo = eso.uaa_codigo
            where eso.uap_codigo = {$UapCodigo}
            group by
                eso.eso_actividad,
                eso.uap_codigo,
                cur.cur_codigo,
                tic.tic_nombre, 
                asi.asi_nombre_corto, 
                asi.asi_nombre, 
                eso.eso_subgrupo,
                dia.dia_codigo, 
                dia.dia_nombre, 
                hra.hra_inicio,
                hra.hra_fin,
                esp.esp_nombre + ' ' +  esp.esp_nombre_corto,
                convert(varchar, uaa.uaa_codigo) + ' ' + uaa.uaa_nombre_corto,
                cur.cur_estado,
                cal.cal_nombre
            order by cal.cal_nombre desc, asi_nombre asc, cur.cur_codigo asc
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar los cursos de la vinculacion seleccionada {$UapCodigo}.";
            $this->errorConsultarBd["sql"] = $sql;
            return $this->errorConsultarBd;
        }

        return array(
            "resultado" => true,
            "mensaje" => "Cursos consultados correctamente.",
            "data" => $this->cnx->json
        );
    }

    // Inicio funcion consultarVinculacionesDocente
    // Permite consultar las vinculaciones que ha tenido un docente en especifico.
    function consultarVinculacionesDocente($obj)
    {
        if (!isset($obj->PerCodigo) || $obj->PerCodigo == '' || !is_numeric($obj->PerCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "El código del docente no se envio correctamente o no es numérico."
            );
        }
        $PerCodigo = $obj->PerCodigo; //Contiene el codigo de la persona.

        $sql = "SELECT 
            uap.uap_codigo UapCodigo, 
            uap.uap_fecha_inicio UapFechaInicio, 
            uap.uap_fecha_fin UapFechaFin,
		    vin.vin_nombre VinNombre, 
            ded.ded_nombre DedNombre, 
            sed.sed_nombre SedNombre, 
            uaa.uaa_nombre_corto UaaNombreCorto,
            convert(varchar,uaa.uaa_codigo) + '. ' + uaa.uaa_nombre_corto UaaCodigoNombre,
            (SELECT count(*) 
                FROM agenda_periodo agp
                WHERE agp.uap_codigo = uap.uap_codigo
            ) CargaAcademica
		from persona per
		inner join uaa_personal uap on uap.per_codigo=per.per_codigo
		inner join uaa on uaa.uaa_codigo=uap.uaa_codigo
		inner join vinculacion vin on vin.vin_codigo=uap.vin_codigo
		inner join dedicacion ded on ded.ded_codigo=uap.ded_codigo
		left join sede sed on sed.sed_codigo=uap.sed_codigo
		where per.per_codigo = {$PerCodigo}
		--group by uap.uap_codigo, uap.uap_fecha_inicio, uap.uap_fecha_fin,
		--vin.vin_nombre, ded.ded_nombre, sed.sed_nombre
		order by uap_codigo desc";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar las vinculaciones del docente seleccionado {$PerCodigo}.";
            return $this->errorConsultarBd;
        }

        return array(
            "resultado" => true,
            "mensaje" => "Vinculaciones consultadas correctamente.",
            "data" => $this->cnx->json
        );
    }

    //Inicio funcion consultarDocente
    //Permite consultar los docentes segun cedula, nombre y apellido
    function consultarDocente($obj)
    {

        if (!isset($obj->busquedaDocente) || $obj->busquedaDocente == '') {
            return array(
                "resultado" => false,
                "mensaje" => "Ingrese un criterio de busqueda (Identificacion, Nombre o Apellido)."
            );
        }

        //Parametros
        $CriterioBusqueda = $obj->busquedaDocente; //Contiene el criterio de busqueda, identificacion, nombre y apellido

        $sql = "SELECT 
            per.per_codigo PerCodigo,
            per.per_identificacion PerIdentificacion,
            per.per_nombre + ' ' + per.per_apellido PerNombreApellido,
            per.per_email_interno PerEmailInterno
        FROM
            persona per
        INNER JOIN uaa_personal uap ON uap.per_codigo = per.per_codigo
		INNER JOIN vinculacion vin ON vin.vin_codigo = uap.vin_codigo
		INNER JOIN dedicacion ded ON ded.ded_codigo = uap.ded_codigo
		INNER JOIN sede sed ON sed.sed_codigo = uap.sed_codigo
        WHERE
            per.per_identificacion like '%{$CriterioBusqueda}%'
            OR per.per_nombre + ' ' + per.per_apellido like '%{$CriterioBusqueda}%'
        GROUP BY 
            per.per_codigo,
            per.per_identificacion,  
            per.per_nombre + ' ' + per.per_apellido,
            per.per_email_interno
        ORDER BY
            per.per_nombre + ' ' + per.per_apellido ASC
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar los cursos programados para estudiantes de primer semestre.";
            return $this->errorConsultarBd;
        }

        return array(
            "resultado" => true,
            "mensaje" => "Docentes consultados correctamente.",
            "data" => $this->cnx->json
        );
    }
}
