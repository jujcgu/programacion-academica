<?php
date_default_timezone_set('America/Bogota');
require_once(dirname(__FILE__) . '/Curhorario.php');
require_once(dirname(__FILE__) . '/Crucehorario.php');
require_once(dirname(__FILE__) . '/servicios/FechaSqlServer.php');
require_once(dirname(__FILE__) . '/servicios/ValidarCargaDocenteService.php');

class Buscurso
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

    function buscarAsignatura($obj)
    {
        if (!isset($obj->filtroAsignatura) || $obj->filtroAsignatura == '') {
            return array(
                "resultado" => false,
                "mensaje" => "Debe ingresar el nombre o el codigo alfanumerico de la asignatura.",
                "consola" => "El codigo alfanumerico o nombre de la asignatura no se envio correctamente.",
            );
        }

        $filtroAsignatura = $obj->filtroAsignatura;

        $excluirNucleo = "";
        if (isset($obj->excluirNucleo) && $obj->excluirNucleo != '') {
            $unidades = $_SESSION["pacademica"]["datosVinculacionUsuario"]["unidades"];
            $excluirNucleo = "AND asi.nuc_codigo != {$obj->excluirNucleo} ";
            $unionInstitucionalesUnidad = "UNION ALL SELECT
                asi.asi_codigo AsiCodigo, 
                asi.asi_nombre AsiNombre, 
                asi.asi_nombre_corto AsiNombreCorto, 
                nuc.nuc_nombre NucNombre,
                asi.asi_creditos AsiCreditos, 
                asi.asi_creditos_teoria AsiCreditosTeoria, 
                asi.asi_creditos_practica AsiCreditosPractica,
                asi.car_codigo CarCodigo, --Codigo del caracter
                car.car_nombre CarNombre, --Nombre del caracter.
                uaa.uaa_codigo UaaCodigo,
                uaa.uaa_nombre_corto UaaNombreCorto,
                convert(varchar, uaa.uaa_codigo) + ' ' + uaa.uaa_nombre_corto UaaCodigoNombre,
                uaa.uaa_estado UaaEstado,
                CASE WHEN asi.asi_estado = 1 THEN 'ACTIVO' ELSE 'DESACTIVADA' END AS AsiEstado
            FROM asignatura asi
            INNER JOIN nucleo nuc ON asi.nuc_codigo = nuc.nuc_codigo
            INNER JOIN caracter car ON car.car_codigo = asi.car_codigo
            INNER JOIN uaa ON uaa.uaa_codigo = asi.uaa_codigo
            WHERE
                ISNUMERIC(asi.asi_nombre_corto) <> 1                
                AND (
                    asi.asi_nombre like '%{$filtroAsignatura}%'
                    OR asi.asi_nombre_corto like '%{$filtroAsignatura}%'
                )
                AND asi.nuc_codigo = 1
                AND asi.uaa_codigo IN ({$unidades})
            ";
        }

        $sql = "SELECT
                asi.asi_codigo AsiCodigo, 
                asi.asi_nombre AsiNombre, 
                asi.asi_nombre_corto AsiNombreCorto, 
                nuc.nuc_nombre NucNombre,
                asi.asi_creditos AsiCreditos, 
                asi.asi_creditos_teoria AsiCreditosTeoria, 
                asi.asi_creditos_practica AsiCreditosPractica,
                asi.car_codigo CarCodigo, --Codigo del caracter
                car.car_nombre CarNombre, --Nombre del caracter.
                uaa.uaa_codigo UaaCodigo,
                uaa.uaa_nombre_corto UaaNombreCorto,
                convert(varchar, uaa.uaa_codigo) + ' ' + uaa.uaa_nombre_corto UaaCodigoNombre,
                uaa.uaa_estado UaaEstado,
                CASE WHEN asi.asi_estado = 1 THEN 'ACTIVO' ELSE 'DESACTIVADA' END AS AsiEstado
            FROM asignatura asi
            INNER JOIN nucleo nuc ON asi.nuc_codigo = nuc.nuc_codigo
            INNER JOIN caracter car ON car.car_codigo = asi.car_codigo
            INNER JOIN uaa ON uaa.uaa_codigo = asi.uaa_codigo
            WHERE
                ISNUMERIC(asi.asi_nombre_corto) <> 1                
                AND (
                    asi.asi_nombre like '%{$filtroAsignatura}%'
                    OR asi.asi_nombre_corto like '%{$filtroAsignatura}%'
                )
                {$excluirNucleo}
            {$unionInstitucionalesUnidad}
            ORDER BY
                asi.asi_nombre_corto DESC
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar las asignaturas de la busqueda {$filtroAsignatura}.";
            return $this->errorConsultarBd;
        }

        $r_asignaturas = $this->cnx->json;

        return array(
            "resultado" => true,
            "mensaje" => "Asignaturas consultados correctamente.",
            "data" => $r_asignaturas,
            "count" => count($r_asignaturas)
        );
    }

    function eliminarHorarioGrupo($obj)
    {
        //Validaciones
        if (!isset($obj->CurCodigo) || !is_numeric($obj->CurCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo del curso.",
                "consola" => "El codigo del curso no es numérico o no se envio correctamente.",
            );
        }

        if (!isset($obj->ListaHorario) || count($obj->ListaHorario) < 1) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar el horario a eliminar.",
                "consola" => "Los horarios eliminar no se enviaron correctamente.",
            );
        }

        //Parametros
        $CurCodigo = $obj->CurCodigo; //Contiene el codigo del curso
        $ListaHorario = $obj->ListaHorario; //Contiene los codigos del horario seleccionado
        $mensaje = "";

        //Validamos que el curso no tenga estudiantes con notas definitivas registradas.
        $obj_curhorario = new Curhorario();
        $validacionNotas = $obj_curhorario->validarNotasRegistradas($CurCodigo);
        if ($validacionNotas !== true) {
            return $validacionNotas;
        }

        foreach ($ListaHorario as $horario) {

            $sql = "UPDATE
                    espacio_ocupacion
                SET
                    eso_actividad = NULL, 
                    uap_codigo = NULL, 
                    eso_subgrupo = NULL 
                WHERE
                    eso_actividad = {$CurCodigo}
                    and esp_codigo = {$horario->EspCodigo}
                    and uap_codigo = {$horario->UapCodigo}
                    and dia_codigo = {$horario->DiaCodigo}
                    and hra_codigo = {$horario->HraCodigo}
                    and eso_subgrupo = '{$horario->EsoSubGrupo}'
            ";

            if (!$this->cnx->sentencia($sql)) {
                $this->errorSentenciaBd["mensaje"] = "Error al eliminar el horario seleccionado.";
                $this->errorSentenciaBd["consola"] = "Ha fallado la eliminación del horario del curso: {$CurCodigo} espacio codigo {$horario->EsoCodigo}";
                return $this->errorSentenciaBd;
            }

            $sql = "UPDATE
                    espacio_ocupacion_historico
                SET
                    eso_actividad = NULL, 
                    uap_codigo = NULL, 
                    eso_subgrupo = NULL 
                WHERE
                    eso_actividad = {$CurCodigo}
                    and esp_codigo = {$horario->EspCodigo}
                    and uap_codigo = {$horario->UapCodigo}
                    and dia_codigo = {$horario->DiaCodigo}
                    and hra_codigo = {$horario->HraCodigo}
                    and eso_subgrupo = '{$horario->EsoSubGrupo}'
            ";

            if (!$this->cnx->sentencia($sql)) {
                $mensaje = "El historico no se pudo actualizar.";
                // $this->errorSentenciaBd["mensaje"] = "Error al eliminar el horario seleccionado.";
                // $this->errorSentenciaBd["consola"] = "Ha fallado la eliminación del horario historico del curso: {$CurCodigo}, 
                // espacio: {$EspCodigo}, dia: {$DiaCodigo}, hora: {$HraCodigo} y subgrupo: {$EsoSubGrupo}.";
                // return $this->errorSentenciaBd;

            }

            //Validamos si el curso tiene subgrupos y en caso tal evalua que tenga matriculados, en caso de no tener desactiva el cupo_curso_subgrupo.
            $obj_curhorario = new Curhorario();
            $eliminacionSubgrupoSinHorario = $obj_curhorario->inactivarSubgrupoSinHorario($CurCodigo);
            if (!$eliminacionSubgrupoSinHorario) {
                $this->errorSentenciaBd["mensaje"] = "Error al desactivar subgrupos del curso {$CurCodigo}.";
                $this->errorSentenciaBd["consola"] = "Ha fallado la desactivación de los subgrupos del curso: {$CurCodigo}.";
                return $this->errorSentenciaBd;
            }
        }

        //Recalculamos la agenda del curso especifico.
        $actualizarAgenda = $this->actualizarAgenda($CurCodigo);
        if (!$actualizarAgenda) {
            $this->errorSentenciaBd["mensaje"] = "Error al actualizar la agenda del curso {$CurCodigo}.";
            $this->errorSentenciaBd["consola"] = "Ha fallado la actualización de la agenda del curso: {$CurCodigo}.";
            return $this->errorSentenciaBd;
        }

        return array(
            "resultado" => true,
            "mensaje" => 'Horario eliminado correctamente, la agenda se actualizó correctamente.',
            "consola" => $mensaje,
            "CurCodigo" => $CurCodigo
        );
    }


    //Inicio funcion consultarAsignaturasEquivalentes
    //Permite consultar las asignaturas equivalentes de una unidad.
    function consultarAsignaturasEquivalentes($obj)
    {
        if (!isset($obj->UaaCodigo) || !is_numeric($obj->UaaCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar una unidad.",
                "consola" => "El codigo de la unidad no es numérico o no se envio correctamente.",
            );
        }
        // if (!isset($obj->CalCodigo) || !is_numeric($obj->CalCodigo)) {
        //     return array(
        //         "resultado" => false,
        //         "mensaje" => "Debe seleccionar un calendario.",
        //         "consola" => "El codigo del calendario no es numérico o no se envio correctamente.",
        //     );
        // }

        //Parametros:
        $UaaCodigo = $obj->UaaCodigo; //Almacena el codigo de la unidad seleccionada, de momento se usara el de todas las unidades.
        // $PrpCodigo = $obj->PrpCodigo; //Almacena el codigo del proceso del calendario seleccionado.
        // $unidades = $_SESSION["pacademica"]["datosVinculacionUsuario"]["unidades"]; //Almacenamos las unidades que tiene permitida el usuario
        // $administrador = $_SESSION["pacademica"]["datosVinculacionUsuario"]["Administrador"]; //Almacenamos si es administrador (1) o no (0)

        $sql = "SELECT DISTINCT --Obtiene las asignaturas vinculadas de una uaa
            asi.asi_codigo AsiCodigo, 
            asi.asi_nombre AsiNombre, 
            asi.asi_nombre_corto AsiNombreCorto, 
            nuc.nuc_nombre NucNombre,
            asi.asi_creditos AsiCreditos, 
            asi.asi_creditos_teoria AsiCreditosTeoria, 
            asi.asi_creditos_practica AsiCreditosPractica,
            asi.car_codigo CarCodigo, --Codigo del caracter

            '' AsiBCodigo, 
            '' AsiBNombre,
            '' AsiBNombreCorto, --, uaa_codigo, nuc_codigo 
            '' NucBNombre,
            '' AsiBCreditos, 
            '' AsiBCreditosTeoria, 
            '' AsiBCreditosPractica,
            '' CarBCodigo, --Codigo del caracter

            car.car_nombre CarNombre, --Nombre del caracter.
            uaa.uaa_codigo UaaCodigo,
            uaa.uaa_nombre_corto UaaNombreCorto,
            'PROGRAMABLES' TipoAsignatura
        FROM 
            asignatura asi
        INNER JOIN nucleo nuc ON asi.nuc_codigo = nuc.nuc_codigo --nuc.nuc_codigo IN (1,2) AND No se por que lo limita 
        INNER JOIN caracter car ON car.car_codigo = asi.car_codigo
        INNER JOIN uaa ON uaa.uaa_codigo = asi.uaa_codigo
        WHERE 
            asi.asi_estado = 1 AND 
            asi.uaa_codigo IN ({$UaaCodigo}) AND 
            ISNUMERIC(asi.asi_nombre_corto) <> 1 AND
            asi.asi_codigo IN
            (
                SELECT asi_codigo FROM plan_academico_asignatura 
                WHERE paa_estado = 1 AND (paa_programable = 's' OR paa_programable = 'S')
            )
        
        UNION
        
        SELECT DISTINCT --Al parecer consulta las equivalencias
            asi.asi_codigo AsiCodigo, 
            asi.asi_nombre AsiNombre,
            asi.asi_nombre_corto AsiNombreCorto, --, uaa_codigo, nuc_codigo 
            'Equivalencia' NucNombre,
            asi.asi_creditos AsiCreditos, 
            asi.asi_creditos_teoria AsiCreditosTeoria, 
            asi.asi_creditos_practica AsiCreditosPractica,
            asi.car_codigo CarCodigo, --Codigo del caracter
            
            asib.asi_codigo AsiBCodigo, 
            asib.asi_nombre AsiBNombre,
            asib.asi_nombre_corto AsiBNombreCorto, --, uaa_codigo, nuc_codigo 
            'Equivalencia' NucBNombre,
            asib.asi_creditos AsiBCreditos, 
            asib.asi_creditos_teoria AsiBCreditosTeoria, 
            asib.asi_creditos_practica AsiBCreditosPractica,
            asib.car_codigo CarBCodigo, --Codigo del caracter

            car.car_nombre CarNombre, --Nombre del caracter.
            uaa.uaa_codigo UaaCodigo,
            uaa.uaa_nombre_corto UaaNombreCorto,
            'EQUIVALENCIAS' TipoAsignatura
        FROM 
            asignatura asi 
        INNER JOIN equivalencia equi ON asi.asi_codigo = equi.asi_equivalencia
        INNER JOIN asignatura asib ON asib.asi_codigo = equi.asi_codigo
        INNER JOIN caracter car ON car.car_codigo = asi.car_codigo
        INNER JOIN uaa ON uaa.uaa_codigo = asi.uaa_codigo
        WHERE  
            asi.asi_estado = 1 AND 
            asi.uaa_codigo IN ({$UaaCodigo})
            AND ISNUMERIC(asi.asi_nombre_corto) <> 1
            AND ISNUMERIC(asib.asi_nombre_corto) <> 1
        
        UNION
        
        SELECT--Al parecer consulta las equivalencias de las asignaturas que estan marcadas como no programables
            asib.asi_codigo AsiCodigo,
            asib.asi_nombre AsiNombre,
            asib.asi_nombre_corto AsiNombreCorto,
            nuc.nuc_nombre NucNombre,
            asib.asi_creditos AsiCreditos, 
            asib.asi_creditos_teoria AsiCreditosTeoria, 
            asib.asi_creditos_practica AsiCreditosPractica, 
            asib.car_codigo CarCodigo, --Codigo del caracter

            asi.asi_codigo AsiBCodigo,
            asi.asi_nombre AsiBNombre,
            asi.asi_nombre_corto AsiBNombreCorto,
            nuc.nuc_nombre NucBNombre,
            asi.asi_creditos AsiBCreditos, 
            asi.asi_creditos_teoria AsiBCreditosTeoria, 
            asi.asi_creditos_practica AsiBCreditosPractica, 
            asi.car_codigo CarBCodigo, --Codigo del caracter

            car.car_nombre CarNombre, --Nombre del caracter
            uaa.uaa_codigo UaaCodigo,
            uaa.uaa_nombre_corto UaaNombreCorto,
            'NOPROGRAMABLES' TipoAsignatura
        FROM 
            asignatura asi 
        INNER JOIN plan_academico_asignatura paa ON asi.asi_codigo = paa.asi_codigo AND paa.paa_programable = 'N' AND paa.paa_estado = 1
        INNER JOIN plan_academico pla ON pla.pla_codigo = paa.pla_codigo
        INNER JOIN programa pro ON pla.pro_codigo = pro.pro_codigo AND pro.uaa_codigo in ({$UaaCodigo})
        INNER JOIN uaa ON uaa.uaa_codigo = pro.uaa_codigo
        INNER JOIN nucleo nuc ON nuc.nuc_codigo = asi.nuc_codigo
        INNER JOIN equivalencia equi ON equi.asi_codigo = asi.asi_codigo
        INNER JOIN asignatura asib ON asib.asi_codigo = equi.asi_equivalencia AND asib.nuc_codigo != ''
        INNER JOIN caracter car ON car.car_codigo = asib.car_codigo
        WHERE 
            asi.asi_estado = 1 AND
            ISNUMERIC(asi.asi_nombre_corto) <> 1 AND
            ISNUMERIC(asib.asi_nombre_corto) <> 1 AND
            asi.asi_codigo NOT IN
            (
                SELECT 
                    asi.asi_codigo AsiCodigo
                FROM 
                    asignatura asi
                INNER JOIN plan_academico_asignatura paa ON asi.asi_codigo = paa.asi_codigo AND paa.paa_programable = 'N' AND paa.paa_estado = 1
                INNER JOIN plan_academico pla ON pla.pla_codigo = paa.pla_codigo
                INNER JOIN programa pro ON pro.uaa_codigo IN ({$UaaCodigo}) AND pla.pro_codigo = pro.pro_codigo
                INNER JOIN uaa ON pro.uaa_codigo = uaa.uaa_codigo
                INNER JOIN nucleo nuc ON nuc.nuc_codigo = asi.nuc_codigo AND nuc.nuc_codigo = 1
                INNER JOIN equivalencia equi ON equi.asi_equivalencia = asi.asi_codigo
                INNER JOIN asignatura asic ON asic.asi_codigo = equi.asi_codigo AND ISNUMERIC(asic.asi_nombre_corto) <> 1
            )  
        ORDER BY AsiNombre";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar las asignaturas vinculadas a la unidad.";
            return $this->errorConsultarBd;
        }

        return array(
            "resultado" => true,
            "mensaje" => "Asignaturas consultadas correctamente.",
            "data" => $this->cnx->json
        );
    }

    //Inicio funcion consultarAsignaturasPlan
    //Permite consultar las asignaturas de un plan academico especifico.
    function consultarAsignaturasPlan($obj)
    {
        //Validaciones
        if (!isset($obj->PlaCodigo) || !is_numeric($obj->PlaCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo del plan académico seleccionado.",
                "consola" => "El codigo del plan académico no es numérico o no se envio correctamente {$obj->PlaCodigo}.",
            );
        }

        $PlaCodigo = $obj->PlaCodigo; //Contiene el codigo del plan academico seleccionado

        $sql = "SELECT 
                asi.asi_codigo AsiCodigo, 
                asi.asi_nombre AsiNombre, 
                asi.asi_nombre_corto AsiNombreCorto, 
                nuc.nuc_nombre NucNombre,
                asi.asi_creditos AsiCreditos, 
                asi.asi_creditos_teoria AsiCreditosTeoria, 
                asi.asi_creditos_practica AsiCreditosPractica,

                asi.asi_trabajo_horas_teorico AsiHorasSemanalesTeorico,
                asi.asi_trabajo_horas_practico AsiHorasSemanalesPractica,
                asi.asi_trabajo_horas_teorico_practico AsiHorasSemanalesTeoricoPractico,

                asi.car_codigo CarCodigo, --Codigo del caracter
                car.car_nombre CarNombre, --Nombre del caracter.
                uaa.uaa_codigo UaaCodigo,
                uaa.uaa_nombre_corto UaaNombreCorto,
                paa.paa_semestre PaaSemestre,
                pla.pla_codigo PlaCodigo,
                pla.pla_nombre PlaNombre
            FROM 
                asignatura asi
            INNER JOIN plan_academico_asignatura paa ON asi.asi_codigo = paa.asi_codigo 
            INNER JOIN nucleo nuc ON asi.nuc_codigo = nuc.nuc_codigo
            INNER JOIN caracter car ON car.car_codigo = asi.car_codigo
            INNER JOIN plan_academico pla ON pla.pla_codigo = paa.pla_codigo
            LEFT JOIN uaa ON uaa.uaa_codigo = asi.uaa_codigo
            WHERE 
                paa.pla_codigo = {$PlaCodigo}
                AND ISNUMERIC(asi.asi_nombre_corto) <> 1
                AND asi.asi_estado = 1
                AND paa.paa_estado = 1
                AND (
                    paa.paa_programable = 's' 
                    OR paa.paa_programable = 'S'
                )
            ORDER BY
                paa.paa_semestre ASC,
                asi.asi_nombre_corto ASC
            ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar las asignaturas del plan académico {$PlaCodigo}.";
            return $this->errorConsultarBd;
        }

        $r_asignaturas = $this->cnx->json;

        if (count($r_asignaturas) > 0) {
            return array(
                "resultado" => true,
                "mensaje" => "Asignaturas consultados correctamente.",
                "data" => $r_asignaturas
            );
        } else {
            return array(
                "resultado" => false,
                "mensaje" => "No se encontraron signaturas activas en el plan académico seleccionado.",
                "consola" => "No se encontraron signaturas activas en el plan académico seleccionado.",
            );
        }
    }

    //Inicio funcion consultarPlanesAcademicos
    //Permite consultar los planes academicos de una unidad y calendario especifico
    function consultarPlanesAcademicos()
    {

        $sql = "SELECT DISTINCT 
                pla.pla_codigo PlaCodigo, 
                pla.pla_nombre PlaNombre, 
                uaa.uaa_nombre UaaNombre, 
                uaa.uaa_nombre_corto UaaNombreCorto, 
                uaa.uaa_codigo UaaCodigo,
                CONVERT(varchar, uaa.uaa_codigo) + '. ' + uaa.uaa_nombre_corto UaaCodigoNombre,
                pro.pro_codigo ProCodigo,
                form.for_codigo ForCodigo,
                form.for_nombre ForNombre
            FROM 
                plan_academico pla
            INNER JOIN programa pro ON pla.pro_codigo = pro.pro_codigo
            INNER JOIN uaa ON uaa.uaa_codigo = pro.uaa_codigo
            INNER JOIN nivel_academico nia ON nia.nia_codigo = pro.nia_codigo
            INNER JOIN formalidad form ON form.for_codigo = nia.for_codigo
            WHERE 
                pla.pla_estado = 1
            ORDER BY
                uaa.uaa_codigo ASC, pla.pla_nombre DESC
            ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar los planes académicos.";
            return $this->errorConsultarBd;
        }

        $r_plan_aca = $this->cnx->json;

        return array(
            "resultado" => true,
            "mensaje" => "Planes académicos consultados correctamente.",
            "data" => $r_plan_aca
        );
    }

    //Inicio funcion actualizarAgenda
    //Permite recalcular la agenda de un curso especifico.
    function actualizarAgenda($CurCodigo)
    {
        //Eliminamos todo registro relacionado con el curso especifico para actualizar.
        $sql = "DELETE from 
            agenda_periodo 
        where 
            cur_codigo = {$CurCodigo} ";

        if (!$this->cnx->sentencia($sql)) {
            $this->errorSentenciaBd["mensaje"] = "Error al eliminar la agenda del curso: {$CurCodigo}.";
            $this->errorSentenciaBd["consola"] = "Ha fallado el delete de la agenda del curso: {$CurCodigo}.";
            return $this->errorSentenciaBd;
        }

        //Consultamos lo relacionado al curso e informacion de la asignatura y docente.
        $sql = "SELECT 
		    asi.asi_codigo AsiCodigo,
            asi.car_codigo CarCodigo,
		    asi.asi_creditos AsiCreditos,
            asi.asi_creditos_teoria AsiCreditosTeoria,
            asi.asi_creditos_practica AsiCreditosPractica,
            resu.semanas ResuSemanas,
            uap.vin_codigo VinCodigo,
            uap.uap_codigo UapCodigo,
            cur.cur_codigo CurCodigo,
            eso.eso_subgrupo EsoSubgrupo,
            (resu.semanas * resu.horas_sema) Cantidad,
            uaa_asig.uaa_dependencia UaaDependencia,
            uap.per_codigo PerCodigo,
            uaa_eso.uaa_codigo UaaCodigo,
            uaa_eso.uaa_nombre_corto UaaNombreCorto,
            uap.ded_codigo DedCodigo
		from 
            (
                select 
                    * 
                from 
                    espacio_ocupacion 
                union all 
                select 
                    * 
                from 
                    espacio_ocupacion_historico
            ) as eso
            inner join uaa_personal uap on (eso.uap_codigo = uap.uap_codigo)
            inner join curso cur on (eso.eso_actividad = cur.cur_codigo)
            inner join asignatura asi on (cur.asi_codigo = asi.asi_codigo)
            inner join uaa uaa_asig on (uaa_asig.uaa_codigo = asi.uaa_codigo)
            inner join uaa uaa_eso on (uaa_eso.uaa_codigo = eso.uaa_codigo)
            inner join calendario cal on (cur.cal_codigo = cal.cal_codigo)
            inner join periodo per on (per.per_codigo = cal.per_codigo)
            inner join resumen_docencia_final resu 
            on (
                resu.cur_codigo = cur.cur_codigo and 
                resu.vin_codigo = uap.vin_codigo and
                resu.eso_subgrupo = eso.eso_subgrupo and
                resu.per_codigo = uap.per_codigo and 
                resu.uap_codigo = uap.uap_codigo
            )
		where 
            cur.cur_codigo = {$CurCodigo}
		group by 
            asi.asi_codigo, 
            asi.car_codigo, 
            asi.asi_creditos, 
            asi.asi_creditos_teoria, 
            asi.asi_creditos_practica, 
            resu.semanas, 
            uap.vin_codigo, 
            uap.uap_codigo, 
            uap.ded_codigo,
            cur.cur_codigo, 
            eso.eso_subgrupo, 
            uaa_asig.uaa_dependencia, 
            uap.per_codigo, 
            uaa_eso.uaa_codigo,
            uaa_eso.uaa_nombre_corto, 
            uap.uap_codigo, 
            resu.semanas, 
            resu.horas_sema";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar la información de la agenda final del docente.";
            return $this->errorConsultarBd;
        }

        // Almacenamos los registros del curso y los subgrupos encontrados.
        $agenda_final = $this->cnx->json;

        foreach ($agenda_final as $agenda) {
            //Definimos los parametros que se van a usar.
            $AsiCodigo = $agenda['AsiCodigo']; //Codigo de la asignatura.
            $UaaDependencia = intval($agenda['UaaDependencia']); //Uaa propietaria de la asignatura.
            $PerCodigo = $agenda['PerCodigo']; //Codigo del docente.
            $EsoSubgrupo = $agenda['EsoSubgrupo']; //Subgrupo del curso especifico.
            $DedCodigo = $agenda['DedCodigo']; //Codigo de la dedicación del docente.
            $ResuSemanas = $agenda['ResuSemanas']; //Cantidad de semanas
            $FactorFormula = "0"; //Almacenamos el factor formula en 0, factor formula contendra la formula utilizada para calcular ej (3*3)+14.
            $Factor = 0; //Almacenamos el factor en 0, factor contendra el valor de la formula utilizada para calcular ej 23 
            $AsiCreditosPractica = $agenda['AsiCreditosPractica']; //Cantidad de creditos practica de la asignatura.
            $AsiCreditosTeoria = $agenda['AsiCreditosTeoria']; //Cantidad de creditos teoria de la asignatura.
            $AsiCreditos = $agenda['AsiCreditos']; //Cantidad de creditos totales de la asignatura.
            $CarCodigo = $agenda['CarCodigo']; //Caracter del curso
            $VinCodigo = $agenda['VinCodigo']; //Codigo del tipo de vinculación del docente.
            $UapCodigo = $agenda['UapCodigo']; //Codigo de la vinculación del docente.
            $UaaCodigo = $agenda['UaaCodigo']; //Codigo de la unidad donde se programo el curso especifico.
            $UaaNombreCorto = $agenda['UaaNombreCorto']; //Unidad donde se programo el curso especifico.
            $CursoTradicionalCredito = ''; //Almacenamos que es tradicional si el AsiCreditos es menor o igual a 0 o Almacenamos que es creditos si el AsiCreditos es mayor a 0.
            $HorasProgramadas = $agenda['Cantidad']; //Almacenamos las horas programadas del curso.

            if ($AsiCreditos == "0" or $AsiCreditos == "") {
                $CursoTradicionalCredito = "tr"; //Tradicional
            } else {
                $CursoTradicionalCredito = "cr"; //Credito
            }

            //UaaDependencia
            //  385: VICERRECTORIA ACADEMICA
            //  315: UNIVERSIDAD SURCOLOMBIANA
            //UaaCodigo
            //  322: DPTO O PROGRAMA DE ENFERMERIA
            //  347: DPTO O PROGRAMA DE LICENCIATURA EN MATEMATICAS
            //  331: DPTO O PROGRAMA DE MEDICINA SOCIAL Y PREVENTIVA
            //  321: DPTO O PROGRAMA DE LICENCIATURA EN LENGUAS MODERNAS
            //  329: DPTO O PROGRAMA DE MEDICINA CIENCIAS BASICAS
            //  330: DPTO O PROGRAMA DE MEDICINA CIENCIAS CLINICAS
            //  335: DPTO O PROGRAMA DE DERECHO
            if ($UaaNombreCorto == 'SURCOLOMBIANA' or $UaaNombreCorto == 'FACULTAD DE SALUD' or $UaaDependencia == '' or $UaaDependencia == 385 or $UaaDependencia == 315 or $UaaCodigo == 322 or $UaaCodigo == 347 or $UaaCodigo == 331 or $UaaCodigo == 321   or $UaaCodigo == 329 or $UaaCodigo == 330 or $UaaCodigo == 335) {
                // La siguiente linea fallo en el modulo viejo por que en el caso de ser una asignatura de un programa normal, toma la dependencia como un programa.
                // esto por que el curso se programo a un programa y no a un curso de facultad, al momento de que la dependencia es un programa no entra a evalular ningun condicional de abajo.
                // se debe revisar para la implementación de este modulo nuevo.
                // $UaaDependencia = $UaaCodigo; //En caso de ser una facultad o la universidad surcolombiana la dependencia se toma como la unidad donde se programo el curso.
                $sql = "SELECT 
                    uaa_dependencia UaaDependencia
                from 
                    uaa 
                where 
                    uaa_codigo = {$UaaCodigo}";
                if (!$this->cnx->consultar($sql)) {
                    $this->errorConsultarBd["consola"] = "Error al consultar la dependencia de la unidad: {$UaaCodigo}.";
                    return $this->errorConsultarBd;
                }
                $r_dependencia = $this->cnx->json;
                foreach ($r_dependencia as $dependencia) {
                    $UaaDependencia = $dependencia['UaaDependencia'];
                }
            }

            //En el caso de que la unidad sea una facultad el va a caer en un error al consultar 
            //la dependencia de la facultad, vuelve a ser la 385 y genera error en las agendas con carga 0

            // 19	1	FACULTAD ECONOMIA Y ADMINISTRACION
            // 20	1	FACULTAD DE EDUCACION
            // 21	1	FACULTAD DE INGENIERIA
            // 22	1	FACULTAD CIENCIAS EXACTAS Y NATURALES
            // 23	1	FACULTAD DE SALUD
            // 24	1	FACULTAD CIENCIAS SOCIALES Y HUMANAS
            // 25	1	FACULTAD DE CIENCIAS JURIDICAS Y POLITICAS

            //Para solucionarlo se comprueba que la unidad sea una facultad (uat_codigo = 1)
            //en caso de serlo se remplaza la dependencia por la unidad.

            $sql = "SELECT uat_codigo TipoUnidad FROM uaa WHERE uaa.uaa_codigo = {$UaaCodigo}";

            if (!$this->cnx->consultar($sql)) {
                $this->errorConsultarBd["consola"] = "Error al buscar si la unidad es una facultad.";
                return $this->errorConsultarBd;
            }

            $r_unidad_facultad = $this->cnx->json;

            if ($r_unidad_facultad[0]["TipoUnidad"] == "1") {
                //Si la unidad es una facultad, se le asigna a la dependencia esa unidad.
                $UaaDependencia = $UaaCodigo;
            }


            $TiempoCompleto = 0; //Se establece por defecto 0 para especificar que no es tiempo completo.
            //VinCodigo: 24	CATEDRA VISITANTE DOCENTE
            //DedCodigo: 5	TIEMPO COMPLETO
            //DedCodigo: 4	MEDIO TIEMPO
            if ($VinCodigo == 24 and $DedCodigo == 5) {
                $TiempoCompleto = 1; //Se establece como docente de tiempo completo.
            }
            if ($VinCodigo == 24 and $DedCodigo == 4) {
                $TiempoCompleto = 1; //Se establece como docente de tiempo completo.
            }

            //Si el docente es de tiempo completo o alguna de estas vinculaciones:
            //  12	DE PLANTA DOCENTE
            //  23	NOMBRAMIENTO OCASIONAL DOCENTE
            if ($VinCodigo == 12 or $VinCodigo == 23 or $TiempoCompleto == 1) {
                //si es deporte formativo para docentes de tiempo completo (55087 BIUSCO01 DEPORTE FORMATIVO)
                if ($AsiCodigo == '55087' || $AsiCodigo == 55087) {
                    //vale 1 credito, segun acuerdo 053 de 2006 por el cual se adoptan cursos institucionales
                    $CursoTradicionalCredito = "cr"; //Credito
                    $AsiCreditos = 1;
                }

                //En caso de que la asignatura sea de creditos.
                if ($CursoTradicionalCredito == "cr") {
                    //Iniicia la evaluacion para calcular el factor y otras variables dependiendo de la facultad.

                    //21. FACULTAD DE INGENIERIA
                    if ($UaaDependencia == '21') {
                        if ($CarCodigo == "T ") { // En caso de ser teorico
                            $FactorFormula = "({$AsiCreditos}*3)*{$ResuSemanas}";
                            $Factor = ($AsiCreditos * 3) * $ResuSemanas;
                        }
                        if ($CarCodigo == "TP") { // En caso de ser teorico practico.
                            if ($EsoSubgrupo != "00") { // En caso de ser directamente un subgrupo
                                $FactorFormula = "({$AsiCreditosPractica}*3)*{$ResuSemanas}";
                                $Factor = ($AsiCreditosPractica * 3) * $ResuSemanas;
                            } else { //En caso de ser un 00 busca si tiene mas subgrupos.
                                $sql = "SELECT 
                                    eso_subgrupo 
                                from espacio_ocupacion 
								where eso_actividad = {$CurCodigo}
                                group by eso_subgrupo";
                                if (!$this->cnx->consultar($sql)) {
                                    $this->errorConsultarBd["consola"] = "Error al consultar los subgrupos del curso: {$CurCodigo}.";
                                    return $this->errorConsultarBd;
                                }
                                $r_subgrupo = $this->cnx->json;
                                if (count($r_subgrupo) == 1) { //En caso de tener solamente el 00
                                    $FactorFormula = "({$AsiCreditos}*3)*{$ResuSemanas}";
                                    $Factor = ($AsiCreditos * 3) * $ResuSemanas;
                                } else { //En caso de tener mas de 00,01,02,etc
                                    $FactorFormula = "({$AsiCreditosTeoria}*3)*{$ResuSemanas}";
                                    $Factor = ($AsiCreditosTeoria * 3) * $ResuSemanas;
                                }
                            }
                        }
                        if ($CarCodigo == "P ") { // En caso de ser practica.
                            //Preguntar a doña rocio este condicional por que no se sabe bien que calcula.
                            if ($EsoSubgrupo != "00") { //En caso de ser un subgrupo,
                                $FactorFormula = "{$HorasProgramadas}*1";
                                $Factor = $HorasProgramadas * 1;
                            } else {
                                $FactorFormula = "{$HorasProgramadas}*1";
                                $Factor = $HorasProgramadas * 1;
                            }
                        }
                        if ($CarCodigo == "PP") { // En caso de ser practica pedagogica
                            if ($EsoSubgrupo != "00") { //En caso de ser un subgrupo,
                                $FactorFormula = "{$AsiCreditosPractica}*1";
                                $Factor = $HorasProgramadas * 1;
                            } else {
                                $FactorFormula = "{$HorasProgramadas}*1";
                                $Factor = $HorasProgramadas * 1;
                            }
                        }
                        if ($CarCodigo == "PF") { // En caso de ser practica profesional
                            if ($EsoSubgrupo != "00") { //En caso de ser un subgrupo,
                                $FactorFormula = "{$HorasProgramadas}";
                                $Factor = $HorasProgramadas * 1;
                            } else {
                                $FactorFormula = "{$HorasProgramadas}";
                                $Factor = $HorasProgramadas * 1;
                            }
                        }
                    }

                    //19. FACULTAD DE ADMINISTRACIÓN
                    if ($UaaDependencia == 19) {
                        if ($CarCodigo == "T ") { // En caso de ser teorico
                            $FactorFormula = "({$AsiCreditos}*3)*{$ResuSemanas}";
                            $Factor = ($AsiCreditos * 3) * $ResuSemanas;
                        }
                        if ($CarCodigo == "TP") { // En caso de ser teorico practico.
                            if ($EsoSubgrupo != "00") { // En caso de ser directamente un subgrupo
                                $FactorFormula = "({$AsiCreditosPractica}*3)*{$ResuSemanas}";
                                $Factor = ($AsiCreditosPractica * 3) * $ResuSemanas;
                            } else { //no discrimina
                                $FactorFormula = "({$AsiCreditos}*3)*{$ResuSemanas}";
                                $Factor = ($AsiCreditos * 3) * $ResuSemanas;
                            }
                        }
                        if ($CarCodigo == "P " or $CarCodigo == "PP") { // En caso de ser practica o practica pedagocica.
                            //No se discrimina si es que subgrupo es 00,01,02,03,etc.
                            $FactorFormula = "{$HorasProgramadas}*1";
                            $Factor = $HorasProgramadas * 1;
                        }
                        if ($CarCodigo == "PF") { // En caso de ser practica profesional
                            $FactorFormula = "{$HorasProgramadas}";
                            $Factor = $HorasProgramadas * 1;
                        }
                    }

                    //20. FACULTAD DE EDUCACIÓN
                    if ($UaaDependencia == 20) {
                        if ($CarCodigo == "T ") { // En caso de ser teorico
                            if ($AsiCodigo == '55087' || $AsiCodigo == 55087) {
                                //vale 1 credito, segun acuerdo 053 de 2006 por el cual se adoptan cursos institucionales
                                $AsiCreditos = 1;
                            }
                            $FactorFormula = "({$AsiCreditos}*3)*{$ResuSemanas}";
                            $Factor = ($AsiCreditos * 3) * $ResuSemanas;
                        }
                        if ($CarCodigo == "TP") { // En caso de ser teorico practico.
                            if ($EsoSubgrupo != "00") { // En caso de ser directamente un subgrupo
                                $FactorFormula = "({$AsiCreditosPractica}*3)*{$ResuSemanas}";
                                $Factor = ($AsiCreditosPractica * 3) * $ResuSemanas;
                            } else { //En caso de ser un 00 busca si tiene mas subgrupos.
                                $sql = "SELECT 
                                    eso_subgrupo 
                                from espacio_ocupacion 
								where eso_actividad = {$CurCodigo}
                                group by eso_subgrupo";
                                if (!$this->cnx->consultar($sql)) {
                                    $this->errorConsultarBd["consola"] = "Error al consultar los subgrupos del curso: {$CurCodigo}.";
                                    return $this->errorConsultarBd;
                                }
                                $r_subgrupo = $this->cnx->json;
                                if (count($r_subgrupo) == 1) { //En caso de tener solamente el 00
                                    $FactorFormula = "({$AsiCreditos}*3)*{$ResuSemanas}";
                                    $Factor = ($AsiCreditos * 3) * $ResuSemanas;
                                } else { //En caso de tener mas de 00,01,02,etc
                                    $FactorFormula = "({$AsiCreditosTeoria}*3)*{$ResuSemanas}";
                                    $Factor = ($AsiCreditosTeoria * 3) * $ResuSemanas;
                                }
                            }
                        }
                        if ($CarCodigo == "P ") { // En caso de ser practica.
                            $FactorFormula = "{$HorasProgramadas}";
                            $Factor = $HorasProgramadas;
                        }
                        if ($CarCodigo == "P") { // En caso de ser practica pero sin espacio.
                            if ($EsoSubgrupo != "00") { // En caso de ser directamente un subgrupo
                                $FactorFormula = "{$ResuSemanas}*1";
                                $Factor = $HorasProgramadas;
                            } else {
                                $FactorFormula = "{$HorasProgramadas}";
                                $Factor = $HorasProgramadas;
                            }
                        }
                        if ($CarCodigo == "PP") { // En caso de ser practica profesional
                            $FactorFormula = "{$HorasProgramadas}";
                            $Factor = $HorasProgramadas;
                        }
                        if ($CarCodigo == "PF") { // En caso de ser practica profesional
                            $FactorFormula = "{$HorasProgramadas}";
                            $Factor = $HorasProgramadas;
                        }
                    }

                    // 24. FACULTAD CIENCIAS SOCIALES Y HUMANAS
                    // 25. FACULTAD DE CIENCIAS JURIDICAS Y POLITICAS
                    if ($UaaDependencia == 24 || $UaaDependencia == 25) {
                        if ($CarCodigo == "T ") { // En caso de ser teorico
                            $FactorFormula = "({$AsiCreditos}*3)*{$ResuSemanas}";
                            $Factor = ($AsiCreditos * 3) * $ResuSemanas;
                        }
                        if ($CarCodigo == "TP") { // En caso de ser teorico practico.
                            if ($EsoSubgrupo != "00") { // En caso de ser directamente un subgrupo
                                $FactorFormula = "({$AsiCreditosPractica}*3)*{$ResuSemanas}";
                                $Factor = ($AsiCreditosPractica * 3) * $ResuSemanas;
                            } else { //En caso de ser un 00 busca si tiene mas subgrupos.
                                $sql = "SELECT 
                                    eso_subgrupo 
                                from espacio_ocupacion 
								where eso_actividad = {$CurCodigo}
                                group by eso_subgrupo";
                                if (!$this->cnx->consultar($sql)) {
                                    $this->errorConsultarBd["consola"] = "Error al consultar los subgrupos del curso: {$CurCodigo}.";
                                    return $this->errorConsultarBd;
                                }
                                $r_subgrupo = $this->cnx->json;
                                if (count($r_subgrupo) == 1) { //En caso de tener solamente el 00
                                    $FactorFormula = "({$AsiCreditos}*3)*{$ResuSemanas}";
                                    $Factor = ($AsiCreditos * 3) * $ResuSemanas;
                                } else { //En caso de tener mas de 00,01,02,etc
                                    $FactorFormula = "({$AsiCreditosTeoria}*3)*{$ResuSemanas}";
                                    $Factor = ($AsiCreditosTeoria * 3) * $ResuSemanas;
                                }
                            }
                        }
                        if ($CarCodigo == "P " or $CarCodigo == "P" or $CarCodigo == "PP" or $CarCodigo == "PF") { // En caso de ser practica.
                            $FactorFormula = "{$HorasProgramadas}*1";
                            $Factor = $HorasProgramadas * 1;
                        }
                    }

                    // 22. FACULTAD CIENCIAS EXACTAS Y NATURALES
                    if ($UaaDependencia == 22) {
                        if ($CarCodigo == "T ") { // En caso de ser teorico
                            $FactorFormula = "({$AsiCreditos}*3)*{$ResuSemanas}";
                            $Factor = ($AsiCreditos * 3) * $ResuSemanas;
                        }
                        if ($CarCodigo == "TP") { // En caso de ser teorico practico.
                            if ($EsoSubgrupo != "00") { // En caso de ser directamente un subgrupo
                                $FactorFormula = "({$AsiCreditosPractica}*3)*{$ResuSemanas}";
                                $Factor = ($AsiCreditosPractica * 3) * $ResuSemanas;
                            } else { //En caso de ser un 00 busca si tiene mas subgrupos.
                                $sql = "SELECT 
                                    eso_subgrupo 
                                from espacio_ocupacion 
								where eso_actividad = {$CurCodigo}
                                group by eso_subgrupo";
                                if (!$this->cnx->consultar($sql)) {
                                    $this->errorConsultarBd["consola"] = "Error al consultar los subgrupos del curso: {$CurCodigo}.";
                                    return $this->errorConsultarBd;
                                }
                                $r_subgrupo = $this->cnx->json;
                                if (count($r_subgrupo) == 1) { //En caso de tener solamente el 00
                                    $FactorFormula = "({$AsiCreditos}*3)*{$ResuSemanas}";
                                    $Factor = ($AsiCreditos * 3) * $ResuSemanas;
                                } else { //En caso de tener mas de 00,01,02,etc
                                    $FactorFormula = "({$AsiCreditosTeoria}*3)*{$ResuSemanas}";
                                    $Factor = ($AsiCreditosTeoria * 3) * $ResuSemanas;
                                }
                            }
                        }
                        if ($CarCodigo == "P " or $CarCodigo == "P" or $CarCodigo == "PP") { // En caso de ser practica.
                            $FactorFormula = "{$HorasProgramadas}*1";
                            $Factor = $HorasProgramadas * 1;
                        }
                        if ($CarCodigo == "PF") { // En caso de ser practica.
                            $FactorFormula = "{$HorasProgramadas}";
                            $Factor = $HorasProgramadas;
                        }
                    }

                    // 23. FACULTAD DE SALUD
                    // 715. DPTO O PROGRAMA DE LICENCIATURA EN CIENCIAS NATURALES Y EDUCACION AMBIENTAL
                    if ($UaaDependencia == 23 or $UaaCodigo == 715 or $UaaCodigo == 706) {
                        if ($CarCodigo == "T ") { // En caso de ser teorico
                            $FactorFormula = "({$HorasProgramadas}*2)+1*{$ResuSemanas}";
                            $Factor = ($HorasProgramadas * 2) + 1 * $ResuSemanas;
                        }
                        if ($CarCodigo == "TP") { // En caso de ser teorico practico.
                            $FactorFormula = "({$HorasProgramadas}*1.5)+1*{$ResuSemanas}";
                            $Factor = ($HorasProgramadas * 1.5) + 1 * $ResuSemanas;
                        }
                        if ($CarCodigo == "P " or $CarCodigo == "P" or $CarCodigo == "PP") { // En caso de ser practica, practica pedagogica.
                            $FactorFormula = "{$HorasProgramadas}*1";
                            $Factor = $HorasProgramadas * 1;
                        }

                        //Esta sentencia se debe revisar por que en la original el uaa_codigo recibe
                        //como parametro la cantidad de horas programadas.
                        //Como sugerencia deberia recibir el codigo de la uaa programada en espacio_ocupacion.
                        $sql = "SELECT * 
                            FROM uaa 
                            WHERE uaa_nombre_corto LIKE '%psico%' 
                            AND  uaa_codigo = {$HorasProgramadas}";
                        if (!$this->cnx->consultar($sql)) {
                            $this->errorConsultarBd["consola"] = "Error al consultar las unidades que tienen psico en su nombre.";
                            return $this->errorConsultarBd;
                        }
                        $r_uaa_consulta = $this->cnx->json;
                        if (count($r_uaa_consulta) == 1) { //En caso de que el curso si sea de una unidad con psico
                            if ($CarCodigo == "T ") { // En caso de ser teorico
                                $FactorFormula = "({$HorasProgramadas}*2)+1*{$ResuSemanas}";
                                $Factor = ($HorasProgramadas * 2) + 1 * 15;
                            }
                            if ($CarCodigo == "TP") { // En caso de ser teorico practico
                                $FactorFormula = "({$HorasProgramadas}*1.5)+1*{$ResuSemanas}";
                                $Factor = ($HorasProgramadas * 1.5) + 1 * 15;
                            }
                            if ($CarCodigo == "P " or $CarCodigo == "PP") { // En caso de ser practica
                                $FactorFormula = "{$HorasProgramadas}*{$ResuSemanas}";
                                $Factor = $HorasProgramadas * $ResuSemanas;
                            }
                        }
                    }
                }

                //En caso de que la asignatura sea tradicional.
                if ($CursoTradicionalCredito == "tr") {
                    // 23. FACULTAD DE SALUD
                    if ($UaaDependencia == 23) {
                        if ($CarCodigo == "T ") { // En caso de ser teorico
                            $FactorFormula = "({$HorasProgramadas}*2)+1*{$ResuSemanas}";
                            $Factor = ($HorasProgramadas * 2) + 1 * $ResuSemanas;
                        }
                        if ($CarCodigo == "TP") { // En caso de ser teorico practico.
                            $FactorFormula = "({$HorasProgramadas}*1.5)+1*{$ResuSemanas}";
                            $Factor = ($HorasProgramadas * 1.5) + 1 * $ResuSemanas;
                        }
                        //Esta sentencia se debe revisar por que en la original el uaa_codigo recibe
                        //como parametro la cantidad de horas programadas.
                        //Como sugerencia deberia recibir el codigo de la uaa programada en espacio_ocupacion.
                        $sql = "SELECT * 
                            FROM uaa 
                            WHERE uaa_nombre_corto LIKE '%psico%' 
                            AND  uaa_codigo = {$HorasProgramadas}";
                        if (!$this->cnx->consultar($sql)) {
                            $this->errorConsultarBd["consola"] = "Error al consultar las unidades que tienen psico en su nombre.";
                            return $this->errorConsultarBd;
                        }
                        $r_uaa_consulta = $this->cnx->json;
                        if (count($r_uaa_consulta) == 1) { //En caso de que el curso si sea de una unidad con psico
                            if ($CarCodigo == "T ") { // En caso de ser teorico
                                $FactorFormula = "({$HorasProgramadas}*2)+1*{$ResuSemanas}";
                                $Factor = ($HorasProgramadas * 2) + 1 * 15;
                            }
                            if ($CarCodigo == "TP") { // En caso de ser teorico practico
                                $FactorFormula = "({$HorasProgramadas}*1.5)+1*{$ResuSemanas}";
                                $Factor = ($HorasProgramadas * 1.5) + 1 * 15;
                            }
                            if ($CarCodigo == "P " or $CarCodigo == "PP") { // En caso de ser practica
                                $FactorFormula = "{$HorasProgramadas}*{$ResuSemanas}";
                                $Factor = $HorasProgramadas * $ResuSemanas;
                            }
                        }
                    }

                    // 19	FACULTAD ECONOMIA Y ADMINISTRACION
                    // 21	FACULTAD DE INGENIERIA
                    // 24	FACULTAD CIENCIAS SOCIALES Y HUMANAS
                    // 25	FACULTAD DE CIENCIAS JURIDICAS Y POLITICAS
                    // 26	ARTES
                    // 385	VICERRECTORIA ACADEMICA
                    // 388	EL APRENDIZAJE SIGNIFICATIVO PARA EL DESARROLLO DE LA COMPETENCIAS MATEMÁTICAS EN EL CONTEXTO DE LAS INSTITUCIONES EDUCATIVAS
                    // 391	MAESTRIA EN DIDACTICA DEL INGLES
                    if ($UaaDependencia == 19 or $UaaDependencia == 21 or $UaaDependencia == 24 or $UaaDependencia == 25 or $UaaDependencia == 26 or $UaaDependencia == 385 or $UaaDependencia == 388 or $UaaDependencia == 391) {
                        if ($CarCodigo == "T ") { // En caso de ser teorico
                            $FactorFormula = "({$HorasProgramadas}*2)+1*{$ResuSemanas}";
                            $Factor = ($HorasProgramadas * 2) + 1 * $ResuSemanas;
                        }
                        if ($CarCodigo == "TP") { // En caso de ser teorico practico.
                            if ($EsoSubgrupo != "00") { // En caso de ser directamente un subgrupo
                                $FactorFormula = "({$AsiCreditosPractica}*3)*{$ResuSemanas}";
                                $Factor = ($AsiCreditosPractica * 3) * $ResuSemanas;
                            } else { //En caso de ser un 00 busca si tiene mas subgrupos.
                                $FactorFormula = "({$HorasProgramadas}*2)+1*{$ResuSemanas}";
                                $Factor = ($HorasProgramadas * 2) + 1 * $ResuSemanas;
                            }
                        }
                        if ($CarCodigo == "P " or $CarCodigo == "PP") { // En caso de ser practica o practica pedagogica.
                            if ($EsoSubgrupo != "00") { // En caso de ser directamente un subgrupo
                                $calculo = $HorasProgramadas / $ResuSemanas;
                                $FactorFormula = "{$calculo}*{$ResuSemanas}";
                                $Factor = $calculo * $ResuSemanas;
                            } else { //En caso de ser un 00 busca si tiene mas subgrupos.
                                $FactorFormula = "{$HorasProgramadas}*{$ResuSemanas}";
                                $Factor = $HorasProgramadas * $ResuSemanas;
                            }
                        }
                    }
                }

                if ($AsiCreditos > 0) {
                    $HorasProgramadas = $AsiCreditos;
                }
            } else if (($VinCodigo == 14 or $VinCodigo == 25  or $VinCodigo == 24 or $VinCodigo == 17 or $VinCodigo == 49) && $TiempoCompleto == 0) {
                //Si el docente tiene una de estas vinculaciones:
                //  14	CATEDRA DOCENTE
                //  24	CATEDRA VISITANTE DOCENTE
                //  25	CATEDRA ADICIONAL DOCENTE
                //  17	CATEDRA POSTGRADOS  DOCENTE
                //  49	CATEDRA DOCENTE CONVENIO
                $FactorFormula = "{$HorasProgramadas}";
                $Factor = $HorasProgramadas;
            }

            //Inicio para insertar la agenda_periodo PP, P
            if ($CarCodigo == "PP" or $CarCodigo == "P" or $CarCodigo == "P ") {
                $sqlInsertar = "INSERT INTO  
                    agenda_periodo(
					    creditos,
                        caracter,
                        hora_teorica,
                        hora_practica,
					    tradicional_o_credito,
                        numero_total_hora,
					    factor,
                        semanas,
					    vinculacion,
                        uap_codigo,
					    cur_codigo,
                        sub_grupo,
					    total_horas,
                        per_codigo,
					    uaa_codigo,
                        factor_formula
                    )
				VALUES(
                    '{$AsiCreditos}',
                    '{$CarCodigo}',
                    '{$AsiCreditosTeoria}',
                    '{$AsiCreditosPractica}',
                    '{$CursoTradicionalCredito}',
                    '{$Factor}',
                    {$Factor},
                    '{$ResuSemanas}',
                    '{$VinCodigo}',
                    '{$UapCodigo}',
                    '{$CurCodigo}',
                    '{$EsoSubgrupo}',
                    '{$Factor}',
                    '{$PerCodigo}',
                    '{$UaaCodigo}',
                    '{$FactorFormula}'
                )";
                if (!$this->cnx->sentencia($sqlInsertar)) {
                    $this->errorSentenciaBd["mensaje"] = "Error al guardar la agenda del curso: {$CurCodigo}.";
                    $this->errorSentenciaBd["consola"] = "Ha fallado el insert p, pp de la agenda del curso: {$CurCodigo}.";
                    return $this->errorSentenciaBd;
                }
            } else {
                $sqlInsertar = "INSERT INTO  
                    agenda_periodo(
					    creditos,
                        caracter,
                        hora_teorica,
                        hora_practica,
					    tradicional_o_credito,
                        numero_total_hora,
					    factor,
                        semanas,
					    vinculacion,
                        uap_codigo,
					    cur_codigo,
                        sub_grupo,
					    total_horas,
                        per_codigo,
					    uaa_codigo,
                        factor_formula
                    )
				VALUES(
                    '{$AsiCreditos}',
                    '{$CarCodigo}',
                    '{$AsiCreditosTeoria}',
                    '{$AsiCreditosPractica}',
                    '{$CursoTradicionalCredito}',
                    '{$HorasProgramadas}',
                    {$Factor},
                    '{$ResuSemanas}',
                    '{$VinCodigo}',
                    '{$UapCodigo}',
                    '{$CurCodigo}',
                    '{$EsoSubgrupo}',
                    '{$HorasProgramadas}',
                    '{$PerCodigo}',
                    '{$UaaCodigo}',
                    '{$FactorFormula}'
                )";
                if (!$this->cnx->sentencia($sqlInsertar)) {
                    $this->errorSentenciaBd["mensaje"] = "Error al guardar la agenda del curso: {$CurCodigo}.";
                    $this->errorSentenciaBd["consola"] = "Ha fallado el insert t, tp, pf de la agenda del curso: {$CurCodigo}.";
                    return $this->errorSentenciaBd;
                }
            }
        }
        return true;
    }

    //Inicia funcion guardarHorario
    //Permite guardar el horario de un curso despues de haber validado la cantidad de horas permitidas segun el docente.
    function guardarHorario($obj)
    {
        //Se valida que exista el PerNN que significa que si el docente seleccionado es NN o Persona
        if (!isset($obj->PerNN)) {
            //En el caso de no existir en el arreglo significa que venia siendo de valor false.
            $obj->PerNN = 0;
        } else {
            //En el caso de que exista en el arreglo significa que es venia siendo true.
            $obj->PerNN = 1;
        }

        $PerCodigo = $obj->PerCodigo; //Contiene el codigo del periodo.
        $CalCodigo = $obj->CalCodigo; //Contiene el codigo del calendario.
        $CalNombre = $obj->CalNombre; //Contiene el nombre del calendario.
        $TipoCalendario = substr($CalNombre, -1); //Contiene el tipo de calendario A: Pregrado, C: Postgrados, D: Distancia
        $UaaCodigo = $obj->UaaCodigo; //Contiene el codigo de la uaa.
        $PraCodigo = $obj->PraCodigo; //Contiene el codigo de la uaa.
        $FechaInicio = $obj->FechaInicio; //Contiene la fecha de inicio que se va a programar el curso
        $FechaFin = $obj->FechaFin; //Contiene la fecha de fin que se va a programar el curso

        // Normalizamos fechas para evitar ambigüedades de formato al enviar a SQL Server.
        $FechaInicioIso = FechaSqlServer::normalizarIso8601($FechaInicio, false);
        $FechaFinIso = FechaSqlServer::normalizarIso8601($FechaFin, false);
        if ($FechaInicioIso === false || $FechaFinIso === false) {
            return array(
                "resultado" => false,
                "mensaje" => "Formato de fecha inválido para programar el curso.",
                "consola" => "No se pudo convertir FechaInicio ({$FechaInicio}) o FechaFin ({$FechaFin}) a fecha válida.",
            );
        }
        $FechaInicio = substr($FechaInicioIso, 0, 10);
        $FechaFin = substr($FechaFinIso, 0, 10);
        $FechaInicioSql = FechaSqlServer::toSqlDateTime2($FechaInicio, false);
        $FechaInicioFinDiaSql = FechaSqlServer::toSqlDateTime2($FechaInicio, true);
        $FechaFinSql = FechaSqlServer::toSqlDateTime2($FechaFin, false);
        $FechaFinFinDiaSql = FechaSqlServer::toSqlDateTime2($FechaFin, true);
        if ($FechaInicioSql === false || $FechaInicioFinDiaSql === false || $FechaFinSql === false || $FechaFinFinDiaSql === false) {
            return array(
                "resultado" => false,
                "mensaje" => "Formato de fecha inválido para programar el curso.",
                "consola" => "No se pudo preparar expresiones SQL para FechaInicio ({$FechaInicio}) o FechaFin ({$FechaFin}).",
            );
        }
        $CurCodigo = $obj->CurCodigo; //Contiene el codigo del curso seleccionado
        $HorasSeleccionadas = $obj->HorasSeleccionadas; //Contiene las horas que seleccionaron para crear el curso
        $SubGrupo = $obj->SubGrupo; //Contiene el subgrupo del curso seleccionado 00 Teoria , 01,02,03,etc Practica
        $DiaCodigo = $obj->DiaCodigo; //Contiene el codigo del dia seleccionado.
        $EspCodigo = $obj->EspCodigo; //Contiene el codigo del espacio donde se va a agendar.
        $CurSemanas = $obj->CurSemanas; //Contiene el numero de semanas del curso seleccionado.
        $CupoSubgrupo = $obj->CupoSubgrupo; //Contiene el cupo del subgrupo 01,02,03,etc. Solo aplica para difernte del 00
        $UapCodigo = $obj->UapCodigo; //Contiene el Codigo de la vinculacion del docente seleccionado.

        // $sql = "SELECT 
        //     pra.pra_codigo PraCodigo, 
        //     pra.pra_fecha_inicio PraFechaInicio, 
        //     pra.pra_fecha_fin PraFechaFin,
        //     pra.pra_estado PraEstado,

        //     pra.uaa_codigo UaaCodigo,

        //     prp.prp_codigo PrpCodigo, 
        //     prp.prp_nombre PrpNombre, 

        //     cal.cal_codigo CalCodigo, 
        //     cal.cal_nombre CalNombre,

        //     per.per_fecha_inicio PerFechaInicio,
        //     per.per_fecha_fin PerFechaFin,
        //     per.per_codigo PerCodigo,
        //     per.per_nombre PerNombre,

        //     (
        //         SELECT 
        //             convert(varchar, peu_fecha_inicio) + ' ' + convert(varchar, peu_fecha_fin) PeriodoPersonalizado
        //         FROM
        //             programacionacademica.periodo_unidad 
        //         WHERE
        //             uaa_codigo = {$UaaCodigo} AND
        //             per_codigo = per.per_codigo AND
        //             peu_estado = 1
        //     ) PeriodoPersonalizado,

        //     convert(varchar, cal.cal_codigo) + convert(varchar,'. ') + cal.cal_nombre + ' ' + prp.prp_nombre CalCodigoNombreProceso


        // FROM 
        //     programacionacademica.programacion_academica  pra
        // INNER JOIN programacion_proceso prp ON prp.prp_codigo = pra.prp_codigo
        // INNER JOIN calendario cal ON cal.cal_codigo = pra.cal_codigo and cal.cal_codigo = {$CalCodigo}
        // INNER JOIN periodo per on cal.per_codigo = per.per_codigo

        // WHERE 
        //     pra.uaa_codigo = {$UaaCodigo} 
        //     and pra.pra_codigo = {$PraCodigo} 
        //     and pra.pra_estado = 1
        // ORDER BY pra.pra_fecha_inicio, pra.pra_fecha_fin DESC";
        // header("Creacion: 331");
        // if (!$this->cnx->consultar($sql)) {
        //     $this->errorConsultarBd["consola"] = "Error al consultar la apertura .";
        //     return $this->errorConsultarBd;
        // }

        // $r_apertura = $this->cnx->json;
        // for ($i = 0; $i < count($r_apertura); $i++) {
        //     $date = date('Y-m-d');
        //     if ($date > $r_apertura[$i]['PraFechaFin']) {
        //         $r_apertura[$i]['Vencida'] = 1;
        //     } else {
        //         $r_apertura[$i]['Vencida'] = 0;
        //     }

        //     $r_apertura[$i]['PraFechaInicio'] =  date("Y-m-d", strtotime($r_apertura[$i]['PraFechaInicio']));
        //     $r_apertura[$i]['PraFechaFin'] =  date("Y-m-d", strtotime($r_apertura[$i]['PraFechaFin']));

        //     $r_apertura[$i]['PerFechaInicio'] =  date("Y-m-d", strtotime($r_apertura[$i]['PerFechaInicio']));
        //     $r_apertura[$i]['PerFechaFin'] =  date("Y-m-d", strtotime($r_apertura[$i]['PerFechaFin']));
        // }
        // $PerFechaInicio = "";
        // $PerFechaFin = "";

        // foreach ($r_apertura as $apertura) {
        //     if ($apertura->PeriodoPersonalizado == '') {
        //         $PerFechaInicio = $apertura["PerFechaInicio"];
        //         $PerFechaFin = $apertura["PerFechaFin"];
        //     } else {
        //         $fecha_personalizada = explode(" ", $apertura->PeriodoPersonalizado);
        //         $PerFechaInicio = $fecha_personalizada[0];
        //         $PerFechaFin = $fecha_personalizada[1];
        //     }
        // }

        // $validacion_entre_fechas = 0; //Contiene variable para comprobar si las fechas de inicio y fin del curso esten entre las fechas de inicio y fin del periodo. 0 si esta mal y 1 si estan en el rango correcto.
        // if (($FechaInicio >= $PerFechaInicio && $FechaInicio <= $PerFechaFin) && ($FechaFin >= $PerFechaInicio && $FechaFin <= $PerFechaFin)) {
        //     $validacion_entre_fechas = 1;
        // }

        // if ($_SESSION["pacademica"]["datosVinculacionUsuario"]["Administrador"] == 1 || $TipoCalendario == 'C') {
        //     $validacion_entre_fechas = 1;
        // }

        // if ($validacion_entre_fechas != 1 || !isset($validacion_entre_fechas)) {
        //     return array(
        //         "resultado" => false,
        //         "mensaje" => "Las fechas que ingreso del curso <b>{$CurCodigo} ({$FechaInicio} hasta {$FechaFin})</b> estan fuera del rango de las fechas del periodo <b>{$CalNombre} ({$PerFechaInicio} hasta {$PerFechaFin})</b>.",
        //         "consola" => "Las fechas se encuentran fuera del rango del periodo, fechas del curso {$CurCodigo} {$FechaInicio} hasta {$FechaFin}, fechas del periodo {$CalNombre} {$PerFechaInicio} hasta {$PerFechaFin}.",
        //     );
        // }

        $existen_horas_programadas = false; //Contiene variable para comprobar que no permita programar una misma hora de un curso con dos profesores diferentes

        //Validación que no permita programar una misma hora de un curso con dos profesores diferentes
        foreach ($HorasSeleccionadas as $Horas) {
            $sql = "SELECT 
                count(*) as CantidadHoras
            FROM espacio_ocupacion eso 
            INNER JOIN uaa_personal uap ON uap.uap_codigo = eso.uap_codigo
            INNER JOIN persona per ON per.per_codigo = uap.per_codigo
            WHERE 
                eso.eso_actividad = {$CurCodigo}
                AND eso.eso_subgrupo = '{$SubGrupo}'
                AND dia_codigo = {$DiaCodigo}
                AND hra_codigo = {$Horas}
                AND (
                    (eso_fecha BETWEEN {$FechaInicioSql} AND {$FechaInicioFinDiaSql})
                    OR (eso_fecha BETWEEN {$FechaFinSql} AND {$FechaFinFinDiaSql})
                )
		    ";
            header("Creacion: 402");
            if (!$this->cnx->consultar($sql)) {
                $this->errorConsultarBd["consola"] = "Error al validar una misma hora de un curso con dos profesores diferentes.";
                return $this->errorConsultarBd;
            }

            $r_horas_existen = $this->cnx->json;

            //Se valida que la cantidad de horas sea mayor, significa que ya esta programada esa hora del curso con el mismo u otro profesor
            if ($r_horas_existen[0]['CantidadHoras'] > 0) {
                $existen_horas_programadas = true; //En caso de ser mayor a 0 significa que tiene horas y se marca como verdadero
            }
        }

        //En caso de que existan horas programadas para el mismo curso, dia, hora y docente se retorna un mensaje de error.
        if ($existen_horas_programadas) {
            return array(
                "resultado" => false,
                "mensaje" => "La hora que intenta programar ya esta programadas. Una misma hora no puede estar repetida.",
                "consola" => "El curso: {$CurCodigo}-{$SubGrupo}, dia: {$DiaCodigo}, fechas: {$FechaInicio} hasta: {$FechaFin}"
            );
        }

        foreach ($HorasSeleccionadas as $Horas) {
            //Se busca en base a las asignaciones
            $sql = "SELECT 
                count(*) AS Cuenta, 
                esp.esp_compartido Compartido
            FROM 
                espacio esp 
            INNER JOIN espacio_ocupacion eso ON esp.esp_codigo = eso.esp_codigo
            WHERE 
                eso.eso_fecha BETWEEN {$FechaInicioSql} AND {$FechaFinFinDiaSql}
                AND eso.dia_codigo = {$DiaCodigo}
				AND eso.hra_codigo = {$Horas}
                AND eso.esp_codigo = {$EspCodigo}
				AND eso.eso_actividad IS NOT NULL
            GROUP BY esp.esp_compartido";

            if (!$this->cnx->consultar($sql)) {
                $this->errorConsultarBd["consola"] = "Error al validar si el espacio ya se encuentra asignado en ese horario.";
                return $this->errorConsultarBd;
            }
            header("Creacion: 446");
            $r_asignaciones = $this->cnx->json;

            foreach ($r_asignaciones as $asignaciones) {
                //Validamos que la cantidad de horas no sea mayor a 0, de lo contrario significa que ya tiene horas ocupadas en ese horario
                //Validamos que el espacio sea compartido S o no compartido N
                if ($asignaciones["Cuenta"] > 0 && strtoupper($asignaciones["Compartido"]) == 'N') {
                    return array(
                        "resultado" => false,
                        "mensaje" => "La hora que intenta programar ya esta programadas o el espacio no es compartido.",
                    );
                }
            }
        }

        //Validacion para ver si es un subgrupo diferente a 00 dado que solo los 01,02,03,etc se guarda el cupo del subgrupo.
        //La informacion del subgrupo 00 se guarda en la tabla curso
        //La informacion del subgrupo 01,02,03, etc se guarda en la tabla curso_cupo_subgrupo
        if ($SubGrupo != '00') {
            //Prueba CurCodigo:171756	SubGrupo:04	CupoSubgrupo:10
            $sql = "SELECT 
                ccs.cus_cod CusCodigo, 
                ccs.cur_codigo CurCodigo, 
                ccs.eso_subgrupo EsoSubgrupo, 
                ccs.cus_cupo CusCupo 
            FROM 
                curso_cupo_subgrupo ccs
			where 
                ccs.cur_codigo = {$CurCodigo} 
                and ccs.eso_subgrupo = '{$SubGrupo}'     
            ";
            header("Creacion: 478");
            if (!$this->cnx->consultar($sql)) {
                $this->errorConsultarBd["consola"] = "Error al validar si un subgrupo 01,02,03,etc esta configurado.";
                return $this->errorConsultarBd;
            }

            $r_asignaciones = $this->cnx->json;

            if (count($r_asignaciones) > 0) {
                //Se verifica si el cupo es diferente al cupo que se envia desde el formulario
                $query = '';
                if ($r_asignaciones[0]["CusCupo"] != $CupoSubgrupo) {
                    //Si es diferente se cambia el estado y el cupo.
                    //En el caso de ser iguales se cambia solamente el estado.
                    $query = ",cus_cupo = {$CupoSubgrupo}";
                }

                $sql = "UPDATE 
                    curso_cupo_subgrupo 
                SET 
                    cus_estado = 1
                    {$query} 
                WHERE cus_cod = {$r_asignaciones[0]["CusCodigo"]}
                ";
                header("Creacion: 502");
                if (!$this->cnx->sentencia($sql)) {
                    $this->errorSentenciaBd["mensaje"] = "Error al actualizar la configuracion del subgrupo.";
                    $this->errorSentenciaBd["consola"] = "Ha fallado la actualizacion de la configuracion del curso: {$CurCodigo}, 
                    subgrupo: {$CupoSubgrupo}, configuracion codigo: {$r_asignaciones[0]["CusCodigo"]}.";
                    return $this->errorSentenciaBd;
                }
            } else {
                //En caso de no encontrar registros se inserta en la tabla uno nuevo
                $sql = "INSERT INTO 
                    curso_cupo_subgrupo (
                        cur_codigo,
                        eso_subgrupo,
                        cus_cupo,
                        cus_estado,
                        cus_fecha_registro
                    )
				    VALUES( 
                        {$CurCodigo},
                        '{$SubGrupo}',
                        {$CupoSubgrupo},
                        1,
                        getdate()
                    )";
                header("Creacion: 526");
                if (!$this->cnx->sentencia($sql)) {
                    $this->errorSentenciaBd["mensaje"] = "Error al crear la configuracion del subgrupo.";
                    $this->errorSentenciaBd["consola"] = "Ha fallado la creacion de la configuracion del curso: {$CurCodigo}, 
                    subgrupo: {$CupoSubgrupo}, configuracion codigo: {$r_asignaciones[0]["CusCodigo"]}.";
                    return $this->errorSentenciaBd;
                }
            }
        }

        $fecha_programacion = $FechaInicio; //Es la fecha en la que se realizara el primer insert.
        $iteracion_inicial = true; //Se usa para controlar si es la primer iteración, en el caso de ser la primera no se suma ningun dia.
        //Se recorre la cantidad de semanas para crear en espacio ocupacion
        for ($i = 1; $i <= $CurSemanas; $i++) {
            if ($iteracion_inicial == false) {
                $fecha_programacion = date("Y-m-d", strtotime($fecha_programacion . "+ 1 week"));
            }
            $iteracion_inicial = false;
            //Una vez determinada la fecha en que se desea programar, se recorren las horas seleccionadas
            foreach ($HorasSeleccionadas as $Horas) {
                $fechaProgramacionSql = FechaSqlServer::toSqlDateTime2($fecha_programacion, false);
                if ($fechaProgramacionSql === false) {
                    return array(
                        "resultado" => false,
                        "mensaje" => "Formato de fecha inválido para programar el horario.",
                        "consola" => "No se pudo preparar la fecha de programación {$fecha_programacion}."
                    );
                }
                // $this->cnx->Sentencia("BEGIN TRAN");
                $sql = "INSERT INTO espacio_ocupacion (
                        esp_codigo, 
                        uaa_codigo, 
                        eso_fecha, 
                        dia_codigo, 
                        hra_codigo, 
                        eso_estado,
                        eso_actividad, 
                        uap_codigo,
                        eso_subgrupo,
                        usu_codigo
                    ) 
                    VALUES(
                        {$EspCodigo},
                        {$UaaCodigo},
                        {$fechaProgramacionSql}, 
                        {$DiaCodigo}, 
                        {$Horas},
                        'G',
                        {$CurCodigo},
                        {$UapCodigo},
                        '{$SubGrupo}',
                        {$_SESSION['pacademica']['datosVinculacionUsuario']['usuarioCodigo']}
                    )
                    ";
                header("Creacion: 573");
                if (!$this->cnx->Sentencia($sql)) {
                    $cnxVars = get_object_vars($this->cnx);
                    $dbError = isset($cnxVars['mjeError']) ? $cnxVars['mjeError'] : "Sin detalle en cls_config::sentencia";
                    $this->errorSentenciaBd["mensaje"] = "Error al crear en el curso {$CurCodigo}, dias: {$DiaCodigo}, hora: {$Horas}.";
                    $this->errorSentenciaBd["consola"] = "Error al insertar registro en el curso {$CurCodigo}, dias: {$DiaCodigo}, hora: {$Horas}, espacio: {$EspCodigo}, fecha: {$fecha_programacion}";
                    $this->errorSentenciaBd["sql"] = $sql;
                    $this->errorSentenciaBd["bd"] = $dbError;
                    // $this->cnx->Sentencia("ROLLBACK TRAN"); //Se realiza un rollback si se encuentra un error
                    return $this->errorSentenciaBd;
                }
                // $this->cnx->Sentencia("COMMIT TRAN"); //Se ejecutan las sentencias pendientes.
            }
        }
        $actualizacion = $this->actualizarAgenda($CurCodigo);
        if ($actualizacion) {
            header("Creacion: 584");
            return array(
                "resultado" => true,
                "mensaje" => "Curso programado correctamente, la agenda se actualizó correctamente."
            );
        } else {
            header("Creacion: 590"); //169172
            return array(
                "resultado" => true,
                "mensaje" => "Curso programado correctamente, la agenda no se actualizó correctamente."
            );
        }
    }

    public function construirRespuestaCruceEstudiantes($cruces, $curCodigo, $subGrupo)
    {
        $estudiantesUnicos = array();
        $cursosUnicos = array();

        foreach ($cruces as $cruce) {
            if (isset($cruce['EstCodigo'])) {
                $estudiantesUnicos[(string) $cruce['EstCodigo']] = true;
            }

            $cursoCodigo = isset($cruce['CurCodigo']) ? (string) $cruce['CurCodigo'] : '';
            $asignaturaNombre = isset($cruce['AsiNombre']) ? trim($cruce['AsiNombre']) : '';
            $claveCurso = $cursoCodigo . '|' . $asignaturaNombre;
            if ($cursoCodigo !== '' && !isset($cursosUnicos[$claveCurso])) {
                $cursosUnicos[$claveCurso] = array(
                    'CurCodigo' => $cursoCodigo,
                    'AsiNombre' => $asignaturaNombre
                );
            }
        }

        $cantidadEstudiantes = count($estudiantesUnicos);
        $cursos = array_values($cursosUnicos);
        $etiquetaEstudiantes = $cantidadEstudiantes === 1 ? 'estudiante' : 'estudiantes';
        $itemsCursos = '';
        foreach ($cursos as $curso) {
            $codigoSeguro = htmlspecialchars($curso['CurCodigo'], ENT_QUOTES, 'UTF-8');
            $nombreSeguro = htmlspecialchars($curso['AsiNombre'], ENT_QUOTES, 'UTF-8');
            $itemsCursos .= "<li>{$codigoSeguro} - {$nombreSeguro}</li>";
        }

        $mensaje = "<p>El horario no fue guardado porque afecta a <b>{$cantidadEstudiantes} {$etiquetaEstudiantes}</b>.</p>";
        if ($itemsCursos !== '') {
            $mensaje .= "<p class=\"text-left mb-1\"><b>Cursos involucrados:</b></p><ul class=\"text-left\">{$itemsCursos}</ul>";
        }
        $mensaje .= "<p>Modifique el día o las horas seleccionadas e intente nuevamente.</p>";

        return array(
            'resultado' => false,
            'tipo' => 'cruce_estudiantes',
            'titulo' => 'Cruce de horario detectado',
            'mensaje' => $mensaje,
            'cantidadEstudiantes' => $cantidadEstudiantes,
            'cursos' => $cursos,
            'consola' => "Cruce de estudiantes detectado para el curso {$curCodigo}, subgrupo {$subGrupo}."
        );
    }

    /**
     * Evalua si las horas seleccionadas respetan las solicitudes de prestamo aprobadas.
     */
    public function evaluarPrestamoDocente($solicitudes, $tipoDocente, $spdCodigo, $uaaCodigo, $asiCodigo, $diaCodigo, $horasSeleccionadas)
    {
        $horasSeleccionadasUnicas = array();
        foreach ($horasSeleccionadas as $horaSeleccionada) {
            $horasSeleccionadasUnicas[(string) $horaSeleccionada] = true;
        }

        $horasSolicitudActual = array();
        $coincidenciaAjena = null;

        foreach ($solicitudes as $solicitud) {
            $horaSeleccionada = isset($solicitud['HraCodigo'])
                && isset($horasSeleccionadasUnicas[(string) $solicitud['HraCodigo']]);
            $mismoDia = isset($solicitud['DiaCodigo'])
                && (string) $solicitud['DiaCodigo'] === (string) $diaCodigo;

            if (!$horaSeleccionada || !$mismoDia) {
                continue;
            }

            $mismaUnidadAsignatura = (string) $solicitud['UaaSolicita'] === (string) $uaaCodigo
                && (string) $solicitud['AsiCodigo'] === (string) $asiCodigo;
            $mismaSolicitud = $spdCodigo !== null
                && (string) $solicitud['SpdCodigo'] === (string) $spdCodigo;

            if ($mismaUnidadAsignatura && ($tipoDocente === 'Propio' || $mismaSolicitud)) {
                $horasSolicitudActual[(string) $solicitud['HraCodigo']] = true;
                continue;
            }

            if ($tipoDocente === 'Propio') {
                $coincidenciaAjena = $solicitud;
                break;
            }
        }

        if ($tipoDocente === 'Prestado') {
            if ($spdCodigo === null || count($horasSolicitudActual) !== count($horasSeleccionadasUnicas)) {
                return array(
                    'resultado' => false,
                    'mensaje' => 'Las horas seleccionadas no coinciden con las horas permitidas en la solicitud de prestamo docente.',
                    'consola' => 'Solicitud seleccionada: ' . ($spdCodigo === null ? 'sin codigo' : $spdCodigo)
                        . '. Horas seleccionadas: ' . implode(',', array_keys($horasSeleccionadasUnicas))
                        . '. Horas permitidas: ' . implode(',', array_keys($horasSolicitudActual)) . '.'
                );
            }

            return array('resultado' => true);
        }

        if ($coincidenciaAjena !== null) {
            $mensajePrestamo = "El docente se encuentra prestado en el horario seleccionado ({$coincidenciaAjena['DiaNombre']} - {$coincidenciaAjena['HraInicio']} a {$coincidenciaAjena['HraFin']}) para la solicitud {$coincidenciaAjena['SpdCodigo']}, unidad {$coincidenciaAjena['UaaSolicita']}. {$coincidenciaAjena['UaaSolicitaNombre']}, asignatura {$coincidenciaAjena['AsiCodigo']}. {$coincidenciaAjena['AsiNombreCorto']}.";
            return array(
                'resultado' => false,
                'mensaje' => trim($mensajePrestamo),
                'consola' => 'El docente tiene una solicitud aprobada de prestamo docente en el horario seleccionado.'
            );
        }

        if (count($horasSolicitudActual) > 0
            && count($horasSolicitudActual) !== count($horasSeleccionadasUnicas)) {
            return array(
                'resultado' => false,
                'mensaje' => 'El docente tiene una solicitud de prestamo aprobada para este programa y asignatura, pero no todas las horas seleccionadas estan permitidas en la solicitud.',
                'consola' => 'Horas seleccionadas: ' . implode(',', array_keys($horasSeleccionadasUnicas))
                    . '. Horas permitidas: ' . implode(',', array_keys($horasSolicitudActual)) . '.'
            );
        }

        return array('resultado' => true);
    }

    //Inicia funcion validarHorarioCrear
    //Permite validar la cantidad de horas que tiene un docente asignadas y si le es permitido asignarle mas horas.
    function validarHorarioCrear($obj)
    {
        //Validaciones
        if (!isset($obj->UapCodigo) || !is_numeric($obj->UapCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo de vinculación del docente.",
                "consola" => "El codigo de vinculación del docente no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->UaaCodigo) || !is_numeric($obj->UaaCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo de unidad seleccionada.",
                "consola" => "El codigo de la unidad no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->FechaInicio)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio la fecha inicial.",
                "consola" => "La fecha inicial del curso no se envio correctamente.",
            );
        }
        if (!isset($obj->FechaFin)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio la fecha final.",
                "consola" => "La fecha final del curso no se envio correctamente.",
            );
        }
        if (!isset($obj->CurCodigo) || !is_numeric($obj->CurCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo del curso seleccionado.",
                "consola" => "El codigo del curso no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->EspCodigo) || !is_numeric($obj->EspCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo del espacio.",
                "consola" => "El codigo del espacio no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->DiaCodigo) || !is_numeric($obj->DiaCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo del dia.",
                "consola" => "El codigo del dia no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->EspTipo) || $obj->EspTipo == '') {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el tipo de espacio.",
                "consola" => "El tipo de espacio está vacio o no se envio correctamente.",
            );
        }
        if (!isset($obj->CalCodigo) || !is_numeric($obj->CalCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo del calendario.",
                "consola" => "El codigo del calendario no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->DedCodigo) || !is_numeric($obj->DedCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo de la dedicación.",
                "consola" => "El codigo de la dedicación no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->VinCodigo) || !is_numeric($obj->VinCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo de la vinculación.",
                "consola" => "El codigo de la vinculación no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->SubGrupo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el subgrupo del curso.",
                "consola" => "El subgrupo no se envio correctamente.",
            );
        }
        if (isset($obj->SubGrupo) && $obj->SubGrupo != "00") {
            if (!isset($obj->CupoSubgrupo) || !is_numeric($obj->CupoSubgrupo)) {
                return array(
                    "resultado" => false,
                    "mensaje" => "No se envio el cupo del subgrupo {$obj->SubGrupo}.",
                    "consola" => "El codigo de la vinculación no es numérico o no se envio correctamente."
                );
            }
        }

        if ($obj->SubGrupo == "00") {
            $obj->CupoSubgrupo = ''; //Si el subgrupo es 00 se establece el cupo subgrupo en vacio
        }

        if (!isset($obj->HorasSeleccionadas) && count($obj->HorasSeleccionadas) <= 0) {
            return array(
                "resultado" => false,
                "mensaje" => "No se enviaron las horas a programar.",
                "consola" => "No se enviaron las horas horas seleccionadas para programar, arreglo vacio."
            );
        }
        if (!isset($obj->PerCodigo) || !is_numeric($obj->PerCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo del periodo.",
                "consola" => "El codigo del periodo no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->UapPerCodigo) || !is_numeric($obj->UapPerCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo de la persona.",
                "consola" => "El codigo de la persona no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->CarCodigo) || $obj->CarCodigo == '') {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el caracter de la asignatura.",
                "consola" => "El caracter de la asignatura no se envio correctamente.",
            );
        }
        if (!isset($obj->AsiCodigo) || !is_numeric($obj->AsiCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo de la asignatura.",
                "consola" => "El codigo de la asignatura no es numerico o no se envio correctamente.",
            );
        }
        if (!isset($obj->TipoDocente) || !in_array($obj->TipoDocente, array('Propio', 'Prestado'))) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el tipo de docente seleccionado.",
                "consola" => "El tipo de docente debe ser Propio o Prestado.",
            );
        }
        if ($obj->TipoDocente == 'Prestado' && (!isset($obj->SpdCodigo) || !is_numeric($obj->SpdCodigo))) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio la solicitud de prestamo docente seleccionada.",
                "consola" => "El codigo de la solicitud de prestamo no es numerico o no se envio correctamente.",
            );
        }
        if (!isset($obj->UapSedCodigo) || !is_numeric($obj->UapSedCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo de la sede del docente.",
                "consola" => "El codigo de la sede del docente no se envio correctamente.",
            );
        }
        if (!isset($obj->CurSemanas) || !is_numeric($obj->CurSemanas)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio número de semanas del curso.",
                "consola" => "El número de semanas del curso no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->AsiCreditos) || !is_numeric($obj->AsiCreditos)) {
            $obj->AsiCreditos = 0;
        }
        if (!isset($obj->AsiCreditosTeoria) || $obj->AsiCreditosTeoria == '') {
            $obj->AsiCreditosTeoria = 0;
        }
        if (!isset($obj->AsiCreditosPractica) || $obj->AsiCreditosPractica == '') {
            $obj->AsiCreditosPractica = 0;
        }

        //Si es presencial (1) y subgrupo 00, no puede ser en un aula virtual
        if ($obj->CalTipo == 'A') {
            if ($obj->SubGrupo == '00' && $obj->TicCodigo == 1 && (trim($obj->CarCodigo) == "T" || trim($obj->CarCodigo) == "TP")) {
                if ($obj->EspTipo == 'V') {
                    return array(
                        "resultado" => false,
                        "mensaje" => "Los cursos teoricos o teorico practicos creados con modalidad presencial no pueden ser programados en un espacio virtual.",
                        "consola" => "Los cursos teoricos o teorico practicos creados con modalidad presencial no pueden ser programados en un espacio virtual.",
                    );
                }
            }
        }

        if ($obj->CalTipo == 'A') {
            if ($obj->SubGrupo == '00' && $obj->TicCodigo == 2) {
                if ($obj->EspTipo == 'F') {
                    return array(
                        "resultado" => false,
                        "mensaje" => "Los cursos creados con modalidad Apoyo virtual (b-Learning) no pueden ser programados en un espacio físico.",
                        "consola" => "Los cursos creados con modalidad Apoyo virtual (b-Learning) no pueden ser programados en un espacio físico.",
                    );
                }
            }
        }

        // if (!isset($obj->PerNN) || $obj->PerNN = '') {
        //     return array(
        //         "resultado" => false,
        //         "mensaje" => "No se envio el tipo de la persona.",
        //         "consola" => "El tipo de la persona no se envio correctamente.",
        //     );
        // }


        //Asignaciones
        $UapCodigo = $obj->UapCodigo; //Contiene el codigo de vinculacion del docente seleccionado
        $UaaCodigo = $obj->UaaCodigo; //Contiene el codigo de una unidad a la que se le va a programar.
        $FechaInicio = $obj->FechaInicio; //Contiene la fecha yyyy-mm-dd inicio de la programacion del curso seleccionado.
        $FechaFin = $obj->FechaFin; //Contiene la fecha yyyy-mm-dd fin de la programacion del curso seleccionado
        $CurCodigo = $obj->CurCodigo; //Contiene el codigo del curso seleccionado
        $EspCodigo = $obj->EspCodigo; //Contiene el espacio fisico/aula externa seleccionado
        $DiaCodigo = $obj->DiaCodigo; //Contiene el dia que se va a programar.
        $EspTipo = $obj->EspTipo; //Contiene el tipo de espacio que se va a programar V (Virtual) o F (Fisico)
        $CalCodigo = $obj->CalCodigo; //Contiene el codigo del calendario en el que se va a programar
        $DedCodigo = $obj->DedCodigo; //Contiene el codigo de la dedicación del docente.
        $VinCodigo = $obj->VinCodigo; //Contiene el codigo de la vinculación del docente.
        $SubGrupo = $obj->SubGrupo; //Contiene el subgrupo del curso.
        $CupoSubgrupo = $obj->CupoSubgrupo; //Contiene el cupo del subgrupo del curso.
        $HorasSeleccionadas = $obj->HorasSeleccionadas; //Contiene los codigos de las horas seleccionadas.
        $PerCodigo = $obj->PerCodigo; //Contiene el codigo del periodo.
        $UapPerCodigo = $obj->UapPerCodigo; //Contiene el codigo de la persona del docente.
        $CarCodigo = trim($obj->CarCodigo); //Contiene el caracter de la asignatura.
        $AsiCodigo = $obj->AsiCodigo; //Contiene el codigo de la asignatura seleccionada.
        $AsiCreditos = $obj->AsiCreditos; //Contiene los creditos de la asignatura.
        $AsiCreditosTeoria = $obj->AsiCreditosTeoria; //Contiene los creditos teoricos de la asignatura.
        $AsiCreditosPractica = $obj->AsiCreditosPractica; //Contiene los creditos practicos de la asignatura.
        $UapSedCodigo = $obj->UapSedCodigo; //Contiene el codigo de la sede del docente.
        $UaaDependencia = $obj->UaaDependencia; //Contiene el codigo de la dependencia de la unidad seleccionada.
        $CurSemanas = $obj->CurSemanas; //Contiene el numero total de semanas del curso seleccionado.
        $TipoDocente = $obj->TipoDocente; //Contiene si es un docente Propio o Prestado.
        $SpdCodigo = isset($obj->SpdCodigo) && is_numeric($obj->SpdCodigo) ? intval($obj->SpdCodigo) : null;

        if (!isset($obj->listaHorarioSeleccionado) || !is_array($obj->listaHorarioSeleccionado) || count($obj->listaHorarioSeleccionado) == 0) {
            $listaHorarioSeleccionado = array();
            $fechaProgramacion = date('Y-m-d', strtotime($FechaInicio));
            $iteracionInicial = true;

            for ($i = 1; $i <= $CurSemanas; $i++) {
                if ($iteracionInicial == false) {
                    $fechaProgramacion = date("Y-m-d", strtotime($fechaProgramacion . "+ 1 week"));
                }
                $iteracionInicial = false;

                foreach ($HorasSeleccionadas as $hora) {
                    $item = new stdClass();
                    $item->EsoFecha = $fechaProgramacion;
                    $item->HraCodigo = $hora;
                    $listaHorarioSeleccionado[] = $item;
                }
            }

            $obj->listaHorarioSeleccionado = $listaHorarioSeleccionado;
        }

        $respuesta = array(); //Se usara para almacenar la respuesta que se obtiene de la funcion guardarHorario();

        $cantidad_horas_nuevas = count($HorasSeleccionadas); //Cantidad de horas nuevas por semana.

        // Validación de cruce de estudiantes reutilizando el módulo de crucehorario.
        $objCruce = new stdClass();
        $objCruce->CurCodigo = $CurCodigo;
        $objCruce->CurSemanas = $CurSemanas;
        $objCruce->CurSubgrupo = $SubGrupo;
        $objCruce->FechaInicio = $FechaInicio;
        $objCruce->FechaFin = $FechaFin;
        $objCruce->HorasSeleccionadas = $HorasSeleccionadas;

        $objCruceHorario = new Crucehorario();
        $validacionCruceEstudiantes = $objCruceHorario->consultarCruceHorario($objCruce);

        // En crucehorario, resultado=false significa que SI hay cruce de estudiantes.
        if (isset($validacionCruceEstudiantes['resultado']) && $validacionCruceEstudiantes['resultado'] === false) {
            if (isset($validacionCruceEstudiantes['data']) && count($validacionCruceEstudiantes['data']) > 0) {
                return $this->construirRespuestaCruceEstudiantes(
                    $validacionCruceEstudiantes['data'],
                    $CurCodigo,
                    $SubGrupo
                );
            }

            // Error técnico consultando crucehorario.
            return array(
                "resultado" => false,
                "mensaje" => isset($validacionCruceEstudiantes['mensaje']) ? $validacionCruceEstudiantes['mensaje'] : "No se pudo validar el cruce de horario de estudiantes.",
                "consola" => isset($validacionCruceEstudiantes['consola']) ? $validacionCruceEstudiantes['consola'] : "Error en consultarCruceHorario() para el curso {$CurCodigo}."
            );
        }

        $obj->PerNN = false;


        //Evaluamos si es un NN catedra
        $sql = "SELECT per.per_codigo PerCodigo FROM persona per WHERE per.per_apellido LIKE '%nn ca%' AND per.per_codigo = {$UapPerCodigo}";
        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar si el docente es un NN CATEDRA.";
            return $this->errorConsultarBd;
        }
        $r_docente_nn = $this->cnx->json;
        $perNN = false; //Contiene si (true) el docente es NN catedra o no (false)
        if (count($r_docente_nn) > 0) {
            $perNN = true; //En caso de ser docente NN catedra true.
        }

        $obj->PerNN = $perNN; //Almacenamos al array que enviaremos para programacion si el docente es un NN.

        // DOCENTES PRESTADOS
        // ==================
        // Se valida que el docente no tenga una solicitud de prestamo docente aprobada que
        // se cruce con el dia/horas que se estan programando, para no permitirle a otra unidad
        // programarlo en un horario en el que ya fue prestado a otra dependencia.
        $sql = "SELECT DISTINCT
                    spd.spd_codigo SpdCodigo,
                    spd.uaa_solicita UaaSolicita,
                    uaa.uaa_nombre_corto UaaSolicitaNombre,
                    spd.asi_codigo AsiCodigo,
                    asi.asi_nombre_corto AsiNombreCorto,
                    spdh.dia_codigo DiaCodigo,
                    spdh.hra_codigo HraCodigo,
                    dia.dia_nombre DiaNombre,
                    hra.hra_inicio HraInicio,
                    hra.hra_fin HraFin
                FROM programacionacademica.solicitud_prestamo_docente spd
                    INNER JOIN programacionacademica.solicitud_prestamo_docente_horario spdh ON spd.spd_codigo = spdh.spd_codigo AND spdh.spdh_estado = 1
                    INNER JOIN asignatura asi ON asi.asi_codigo = spd.asi_codigo
                    INNER JOIN uaa ON uaa.uaa_codigo = spd.uaa_solicita
                    INNER JOIN dia ON dia.dia_codigo = spdh.dia_codigo
                    INNER JOIN hora hra ON hra.hra_codigo = spdh.hra_codigo
                WHERE spd.spd_estado = 2
                    AND spd.persona_codigo = {$UapPerCodigo}
                    AND spd.periodo_codigo = {$PerCodigo}
            ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar solicitudes aprobadas de prestamo docente.";
            return $this->errorConsultarBd;
        }

        $validacionPrestamo = $this->evaluarPrestamoDocente(
            $this->cnx->json,
            $TipoDocente,
            $SpdCodigo,
            $UaaCodigo,
            $AsiCodigo,
            $DiaCodigo,
            $HorasSeleccionadas
        );
        if (!$validacionPrestamo['resultado']) {
            return $validacionPrestamo;
        }

        if (trim($VinCodigo) != 12) { //Diferente a docente de planta
            //Machetazo agregado por douglas el 2022-07-11 por los posgrados de salud en el calendario 218.	20222C
            //Aun cuando van a programar el 2022-2 le debe mostrar las vinculaciones del 2022-1 para las siguientes uaa
            // 75.NEIVA - ESPECIALIZACION EN PEDIATRIA
            // 84.NEIVA - ESPECIALIZACION GINECOLOGIA Y OBSTETRICIA
            // 85.NEIVA - ESPECIALIZACION EN MEDICINA INTERNA
            // 86.NEIVA - ESPECIALIZACION EN CIRUGIA GENERAL
            // 87.NEIVA - ESPECIALIZACION EN ANESTESIOLOGIA Y REANIMACION
            // 677.NEIVA - ESPECIALIZACION EN MEDICINA CRITICA Y CUIDADO INTENSIVO
            // 685.ESPECIALIZACION EN GINECOLOGIA Y OBSTETRICIA
            if (($CalCodigo == 218 || $CalCodigo == 220) && ($UaaCodigo == 75 || $UaaCodigo == 84 || $UaaCodigo == 85 || $UaaCodigo == 86 || $UaaCodigo == 87 || $UaaCodigo == 677 || $UaaCodigo == 685)) {
                //No hace nada por que se desea que no evalue el cruce de agendas por que siempre lo va a tener.
            } else {
                $sql = "SELECT 
                (SELECT TOP 1 per_codigo FROM calendario WHERE cal_codigo= {$CalCodigo} ) as periodo_seleccionado,
                cur.cur_codigo CurCodigo, 
                cal.per_codigo PerCodigo
                FROM uaa_personal uap
                INNER JOIN agenda_periodo agp ON uap.uap_codigo = agp.uap_codigo
                INNER JOIN curso cur ON cur.cur_codigo = agp.cur_codigo
                INNER JOIN calendario cal ON cal.cal_codigo = cur.cal_codigo
                WHERE 
                    uap.uap_codigo = {$UapCodigo} 
                ";

                if (!$this->cnx->consultar($sql)) {
                    $this->errorConsultarBd["consola"] = "Error al validar la carga academica entre periodos de la vinculación: {$UapCodigo}.";
                    return $this->errorConsultarBd;
                }

                $r_cruce_calendario = $this->cnx->json;
                $tieneCursosDeOtroPeriodo = false;

                for ($i = 0; $i < count($r_cruce_calendario); $i++) {
                    $periodo_curso = $r_cruce_calendario[$i]["PerCodigo"];
                    $periodo_seleccionado = $r_cruce_calendario[$i]["periodo_seleccionado"];

                    if ($periodo_seleccionado != $periodo_curso) {
                        $tieneCursosDeOtroPeriodo = true;
                    }
                }

                if ($tieneCursosDeOtroPeriodo) {
                    $this->errorSentenciaBd["mensaje"] = "La vinculación ({$UapCodigo}) del docente ya tiene cargado cursos de otro periodo. Asegurese que el docente tenga vinculación para el periodo seleccionado.";
                    $this->errorSentenciaBd["consola"] = "Error la vinculacion ({$UapCodigo}) tiene cursos en otro periodo.";
                    return $this->errorSentenciaBd;
                }
            }
        }

        $servicioCargaDocente = new ValidarCargaDocenteService($this->cnx);

        $control_tope_horas = 0; //Se usa para controlar el tope permitido de horas.
        $total_horas = 0; //total de horas docente consultadas desde espacio_ocupacion.
        $total_horas_pp = 0; //total de horas practica pedagogica docente consultadas desde agenda_periodo.
        $total_horas_pp_sem = 0; //total de horas semanales practica pedagogica docente consultadas desde agenda_periodo.
        $total_horas_inv_tesis = 0; //total de horas proyecto de investigacion o direccion de tesis
        $total_horas_descarga = 0; //total de horas descarga academica
        $cantidad_horas_nuevas_total = 0; //total de horas nuevas, se usa para calcular.
        $total_horas_novedad = 0; //total de horas de novedad se usa solo para de planta  o nombramiento ocacional
        $total_horas_factor = 0; //total de horas de agenda periodo se usa solo para de planta  o nombramiento ocacional

        $r_total_horas = $servicioCargaDocente->obtenerTotalHorasCatedraSinPractica($UapCodigo);
        if (!$r_total_horas["resultado"]) {
            return $r_total_horas;
        }
        $control_tope_horas = 224; //Se establece el tope de horas
        $total_horas = $r_total_horas["data"]["totalHoras"];

        $r_total_horas_practica = $servicioCargaDocente->obtenerHorasPracticaPedagogica($UapCodigo);
        if (!$r_total_horas_practica["resultado"]) {
            return $r_total_horas_practica;
        }
        $control_tope_horas = 252; //Se establece el tope de horas
        $total_horas_pp = $r_total_horas_practica["data"]["totalPP"]; //Se almacena la cantidad total de horas practica pedagogica del catedratico actualmente.
        $total_horas_pp_sem = $r_total_horas_practica["data"]["horasSemanal"]; //Se almacena la cantidad de horas semanal practica pedagogica del catedratico actualmente.

        // 14	CATEDRA DOCENTE
        // 24	CATEDRA VISITANTE DOCENTE
        // 49	CATEDRA CONVENIO DOCENTE
        //  6   POR HORAS
        if (($VinCodigo == 14 or $VinCodigo == 24 or $VinCodigo == 49) &&  $DedCodigo == 6) {
            //VERIFICAR MAXIMO DE CARGAR POR SEDE CATEDRATICO
            $max_horas_catedratico_sedes = 0; //Almacenamos por defecto 0 horas del total de horas permitidas en sede.
            $max_horas_catedratico = 0; //Almacenamos por defecto 0 horas del total de horas permitidas en Neiva.
            $r_topes_catedra = $servicioCargaDocente->obtenerTopesSemanalesCatedra($UapSedCodigo);
            if (!$r_topes_catedra["resultado"]) {
                return $r_topes_catedra;
            }
            $max_horas_catedratico_sedes = $r_topes_catedra["data"]["topeSedes"];
            $max_horas_catedratico = $r_topes_catedra["data"]["topeNeiva"];

            $r_periodo_nombre = $servicioCargaDocente->obtenerPeriodoNombrePorCodigo($PerCodigo);
            if (!$r_periodo_nombre["resultado"]) {
                $sqlPeriodo = "SELECT per.per_nombre FROM calendario cal INNER JOIN periodo per ON per.per_codigo = cal.per_codigo WHERE cal.cal_codigo = {$CalCodigo}";
                if (!$this->cnx->consultar($sqlPeriodo) || count($this->cnx->json) < 1 || !isset($this->cnx->json[0]['per_nombre'])) {
                    return $r_periodo_nombre;
                }
                $periodoNombre = $this->cnx->json[0]['per_nombre'];
            } else {
                $periodoNombre = $r_periodo_nombre["data"]["periodoNombre"];
            }

            //Calcular el pico total semanal del docente (docencia + investigación + proyección + gestión)
            $r_pico_total = $servicioCargaDocente->calcularPicoTotalSemanal($UapCodigo, $periodoNombre, $UaaDependencia, $obj->listaHorarioSeleccionado);
            if (!$r_pico_total["resultado"]) {
                return $r_pico_total;
            }
            $pico_semana_catedra_actual = $r_pico_total["data"]["PicoDocenciaActual"];
            $pico_semana_catedra = $r_pico_total["data"]["PicoDocencia"];
            $pico_total_actual = $r_pico_total["data"]["PicoTotalActual"];
            $pico_total = $r_pico_total["data"]["PicoTotal"];

            // Carga complementaria semanal (proyectos + novedades) alineada con Agenda Docente.
            $cargaComplementariaSemanal = $servicioCargaDocente->obtenerCargaComplementariaSemanal($UapPerCodigo, $PerCodigo, true);
            if (!$cargaComplementariaSemanal["resultado"]) {
                return $cargaComplementariaSemanal;
            }

            $total_horas_inv_tesis = floatval($cargaComplementariaSemanal["data"]["proyectosSemanal"]);
            $total_horas_novedad = floatval($cargaComplementariaSemanal["data"]["novedadesSemanal"]);

            //Comparamos si cuenta con horas de practica pedagogica, proyectos de investigacion o direccion de tesis.
            if ($total_horas_inv_tesis > 0 || $total_horas_pp > 0) {
                $control_tope_horas = 288;
            } else {
                $control_tope_horas = 252;
            }

            //Validacion si la dependencia de la unidad es la facultad de salud con codigo 23
            if ($UaaDependencia == 23) {
                $control_tope_horas = 288;
            }

            $total_horas_descarga = $pico_total;
            $topeSemanalCatedra = $UapSedCodigo != 1 ? floatval($max_horas_catedratico_sedes) : floatval($max_horas_catedratico);

            // Regla reforzada: si ya está en el tope y la nueva selección incrementa el pico real, se bloquea.
            if ($perNN == false && $pico_total_actual >= $topeSemanalCatedra && $pico_total > $pico_total_actual) {
                return array(
                    "resultado" => false,
                    "consola" => "El docente con vinculación {$UapCodigo} ya se encuentra en el tope semanal de horas de cátedra para su sede ({$topeSemanalCatedra} horas). La nueva carga incrementaría su pico semanal real de {$pico_total_actual} a {$pico_total}.",
                    "mensaje" => "No se pueden adicionar horas: el docente ya se encuentra en el tope semanal ({$topeSemanalCatedra}), la nueva carga supera su máximo ({$pico_total_actual} -> {$pico_total}).",
                    "line" => __LINE__
                );
            }

            if ($perNN == true) { //En caso de pasar el tope se pregunta si es un docente NN
                $respuesta = $this->guardarHorario($obj);
            } else {
                if ($total_horas_descarga > $topeSemanalCatedra) {
                    return array(
                        "resultado" => false,
                        "consola" => "ERROR. No se pueden adicionar las horas porque supera el límite de horas semanales, límite horas semanal: {$topeSemanalCatedra}, horas que tendría el docente: {$total_horas_descarga} (pico total semanal).",
                        "mensaje" => "ERROR. No se pueden adicionar las horas porque supera el límite de horas semanales, límite horas semanal: {$topeSemanalCatedra}, horas que tendría el docente: {$total_horas_descarga} (pico total semanal).",
                        "line" => __LINE__
                    );
                } else {
                    $respuesta = $this->guardarHorario($obj);
                }
            }
        }

        // 25	CATEDRA ADICIONAL DOCENTE
        // 17	CATEDRA POSTGRADOS  DOCENTE
        // 16	AD HONOREM                    
        if ($VinCodigo == 25 or $VinCodigo == 17 or $VinCodigo == 16) {
            $control_tope_horas = 224;
            $cantidad_horas_nuevas_total = $cantidad_horas_nuevas * $CurSemanas; //Cantidad de horas nuevas a la semana * la cantidad de semanas.
            $total_horas_descarga = $total_horas_descarga + $cantidad_horas_nuevas_total + $total_horas + $total_horas_pp;

            if ($control_tope_horas >= $total_horas_descarga) {
                // Se procede a realizar la programacion
                $respuesta = $this->guardarHorario($obj);
            } else {
                if ($perNN == true) { //En caso de pasar el tope se pregunta si es un docente NN
                    //Se procede a realizar la programacion y se avisa que es un docente NN.
                    $respuesta = $this->guardarHorario($obj);
                } else {
                    //En caso de superar las horas de descarga al tope
                    return array(
                        "resultado" => false,
                        "mensaje" => "ERROR. No se pueden adicionar las horas porque supera el límite de horas semanales (14 horas semanales), límite horas: {$control_tope_horas}, total horas que tendría el docente: {$total_horas_descarga}"
                    );
                }
            }
        }

        // 12	DE PLANTA DOCENTE
        // 23	NOMBRAMIENTO OCASIONAL DOCENTE
        if ($VinCodigo == 12 or $VinCodigo == 23 or (($VinCodigo == 14 or $VinCodigo == 24 or $VinCodigo == 49) && ($DedCodigo == 4 or $DedCodigo == 5))) {
            // Carga complementaria semestral (proyectos + novedades).
            $cargaComplementariaSemestral = $servicioCargaDocente->obtenerCargaComplementariaSemestral($UapPerCodigo, $PerCodigo, false);
            if (!$cargaComplementariaSemestral["resultado"]) {
                return $cargaComplementariaSemestral;
            }
            $total_horas_inv_tesis = $cargaComplementariaSemestral["data"]["proyectosSemestral"];
            $total_horas_novedad = $cargaComplementariaSemestral["data"]["novedadesSemestral"];

            //Para consultar el total de horas que tiene el docente, primero eliminamos de agenda docente el calculo de horas para este curso dado que se debe recalcular, una vez se inserten nuevamente.
            $sql = "DELETE FROM agenda_periodo WHERE uap_codigo = {$UapCodigo} and cur_codigo = {$CurCodigo}";
            if (!$this->cnx->sentencia($sql)) {
                $this->errorSentenciaBd["mensaje"] = "Error al eliminar la agenda del curso: {$CurCodigo} y vinculacion docente: {$UapCodigo}.";
                $this->errorSentenciaBd["consola"] = "Ha fallado el delete de la agenda del curso: {$CurCodigo} y vinculacion docente: {$UapCodigo}.";
                return $this->errorSentenciaBd;
            }

            $r_periodo_nombre = $servicioCargaDocente->obtenerPeriodoNombrePorCodigo($PerCodigo);
            if (!$r_periodo_nombre["resultado"]) {
                $sqlPeriodo = "SELECT per.per_nombre FROM calendario cal INNER JOIN periodo per ON per.per_codigo = cal.per_codigo WHERE cal.cal_codigo = {$CalCodigo}";
                if (!$this->cnx->consultar($sqlPeriodo) || count($this->cnx->json) < 1 || !isset($this->cnx->json[0]['per_nombre'])) {
                    return $r_periodo_nombre;
                }
                $periodoNombre = $this->cnx->json[0]['per_nombre'];
            } else {
                $periodoNombre = $r_periodo_nombre["data"]["periodoNombre"];
            }
            $cargaDetalle = $servicioCargaDocente->obtenerCargaDetalladaDocente($UapCodigo, $periodoNombre, $UaaDependencia);
            if (!$cargaDetalle["resultado"]) {
                return $cargaDetalle;
            }
            $total_horas_descarga = $cargaDetalle["data"]["totalSemestre"];

            $uaaProgramada = isset($UaaCodigo) ? $UaaCodigo : null;
            $total_factor = $servicioCargaDocente->calcularFactorCarga($UaaDependencia, $CarCodigo, $SubGrupo, $cantidad_horas_nuevas, $CurSemanas, $AsiCreditosTeoria, $AsiCreditosPractica, $uaaProgramada);

            $total_horas_descarga = $total_horas_descarga + $total_factor; // se le adicionan a la descarga total el factor calculado segun la dependencia y el caracter

            //5	TIEMPO COMPLETO
            if ($DedCodigo == 5) {
                if ($total_horas_descarga <= 880) {
                    // Se procede a realizar la programacion.
                    $respuesta = $this->guardarHorario($obj);
                } else {
                    if ($perNN == true) {
                        // Se procede a realizar la programacion pero es un NN.
                        $respuesta = $this->guardarHorario($obj);
                    } else {
                        return array(
                            "resultado" => false,
                            "mensaje" => "ERROR. La vinculación seleccionada es de TIEMPO COMPLETO por lo tanto no debe pasar las 880 horas, el total de horas actual es de {$total_horas_descarga}."
                        );
                    }
                }
            }

            //4	MEDIO TIEMPO
            if ($DedCodigo == 4) {
                if ($total_horas_descarga <= 440) {
                    // Se procede a realizar la programacion.
                    $respuesta = $this->guardarHorario($obj);
                } else {
                    if ($perNN == true) {
                        // Se procede a realizar la programacion pero es un NN.
                        $respuesta = $this->guardarHorario($obj);
                    } else {
                        return array(
                            "resultado" => false,
                            "mensaje" => "ERROR. La vinculación seleccionada es de MEDIO TIEMPO por lo tanto no debe pasar las 440 horas, el total de horas actual es de {$total_horas_descarga}."
                        );
                    }
                }
            }
        }
        return $respuesta;
    }


    //Inicio funcion consultarEspaciosFisicos
    //Permite consultar los espacios fisicos asignados para una unidad
    function consultarEspaciosFisicos($obj)
    {
        //Validaciones
        if (!isset($obj->UaaCodigo) || !is_numeric($obj->UaaCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo de la unidad.",
                "consola" => "El codigo de la unidad no es numérico o no se envio correctamente.",
            );
        }
        if (!isset($obj->FechaInicio)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio la fecha inicial.",
                "consola" => "La fecha inicial no se envio correctamente.",
            );
        }
        if (!isset($obj->FechaFin)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio la fecha final.",
                "consola" => "La fecha final no se envio correctamente.",
            );
        }

        if (!isset($obj->SedCodigoCurso) || !is_numeric($obj->SedCodigoCurso)) {
            return array(
                "resultado" => false,
                "mensaje" => "No se envio el codigo de la sede donde se programó el curso.",
                "consola" => "El codigo de la sede donde se programo el curso no es numerico o no se envio correctamente.",
            );
        }

        //Parametros
        $FechaInicio = $obj->FechaInicio; //Contiene la fecha inicial en la que se desea programar yyyy-mm-dd.
        $FechaFin = $obj->FechaFin; //Contiene la fecha final en la que se desea programar yyyy-mm-dd.
        $UaaCodigo = $obj->UaaCodigo; //Contiene el codigo de la uaa (unidad) de la que se desea programar.
        $CalCodigo = $obj->CalCodigo; //Contiene el codigo del calendario seleccionado.
        $UaaDependencia = $obj->UaaDependencia; //Contiene el codigo de la dependencia de la unidad.
        $SedCodigoCurso = $obj->SedCodigoCurso; //Contiene el codigo de la sede en la que se programo el curso.
        $filtroEspacio = "";
        if (isset($obj->EspCodigo) && is_numeric($obj->EspCodigo)) {
            $filtroEspacio = " AND esp.esp_codigo = {$obj->EspCodigo}";
        }

        $FechaInicio = date('Y-m-d', strtotime($FechaInicio));
        $FechaFin = date('Y-m-d', strtotime($FechaFin));
        $FechaInicioSql = FechaSqlServer::toSqlDateTime2($FechaInicio, false);
        $FechaFinSql = FechaSqlServer::toSqlDateTime2($FechaFin, true);
        if ($FechaInicioSql === false || $FechaFinSql === false) {
            return array(
                "resultado" => false,
                "mensaje" => "Formato de fechas inválido para consultar espacios.",
                "consola" => "No se pudieron preparar expresiones SQL para FechaInicio ({$FechaInicio}) o FechaFin ({$FechaFin})."
            );
        }

        if ($UaaDependencia != '') {
            $UaaCodigo .= ",{$UaaDependencia}";
        }

        $codigo_universidad = ",315"; //El 315 es el codigo de la universidad y todos los espacios de repesca se asignan ahi.

        $sql = "SELECT DISTINCT 
            esp.esp_codigo EspCodigo, 
            esp.esp_espacio_codigo EspEspacioCodigo, 
            esp.esp_nombre EspNombre,
            esp.esp_nombre_corto EspNombreCorto,
            sed.sed_nombre SedNombre, 
            esp.esp_capacidad EspCapacidad,
			CONVERT(date, min(eso.eso_fecha)) as FechaMin, 
            CONVERT(date, max(eso.eso_fecha)) as FechaMax,
            uaa.uaa_codigo UaaCodigo,
            uaa.uaa_nombre_corto UaaNombreCorto,
            'F' EspTipo 
		FROM 
            espacio esp
        INNER JOIN espacio_ocupacion eso ON esp.esp_codigo = eso.esp_codigo AND eso.uaa_codigo in ({$UaaCodigo}{$codigo_universidad}) AND eso.eso_fecha >= {$FechaInicioSql}
        INNER JOIN uaa ON uaa.uaa_codigo = eso.uaa_codigo
        INNER JOIN bloque blo ON esp.blo_codigo = blo.blo_codigo 
        INNER JOIN sub_sede sus ON blo.sus_codigo = sus.sus_codigo 
        INNER JOIN sede sed ON sed.sed_codigo = sus.sed_codigo AND sed.sed_codigo = {$SedCodigoCurso}
        WHERE 
            esp.eti_codigo != 6
            and (eso.eso_actividad IS NULL 
            OR esp.esp_compartido='S')
            {$filtroEspacio}
        GROUP BY 
            esp.esp_codigo, 
            esp.esp_espacio_codigo, 
            esp.esp_nombre,
            esp.esp_nombre_corto,
            sed.sed_codigo,
            sed.sed_nombre,
            esp.esp_capacidad,
            uaa.uaa_codigo,
            uaa.uaa_nombre_corto
        HAVING 
            {$FechaInicioSql} >= min(eso.eso_fecha) 
            AND {$FechaFinSql} <= max(eso.eso_fecha)
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar los espacios asignados.";
            return $this->errorConsultarBd;
        }

        return array(
            "resultado" => true,
            "mensaje" => "Espacios consultados correctamente.",
            "data" => $this->cnx->json,
            "repesca" => $codigo_universidad,
        );
    }

    //Inicio funcion consultarEspaciosFisicosConDisponibilidad
    //Permite consultar los espacios fisicos asignados y sus horas disponibles para la fecha seleccionada.
    function consultarEspaciosFisicosConDisponibilidad($obj)
    {
        $salidaEspacios = $this->consultarEspaciosFisicos($obj);
        if ($salidaEspacios["resultado"] == false) {
            return $salidaEspacios;
        }

        $espacios = $salidaEspacios["data"];
        if (count($espacios) <= 0) {
            return array(
                "resultado" => true,
                "mensaje" => "Espacios consultados correctamente.",
                "data" => array(),
                "total_disponibles" => 0,
                "total_sin_disponibilidad" => 0,
            );
        }

        if (!isset($obj->UapCodigo) || !is_numeric($obj->UapCodigo)) {
            foreach ($espacios as $key => $espacio) {
                $espacios[$key]["HorasDisponibles"] = array();
                $espacios[$key]["TotalHorasDisponibles"] = 0;
                $espacios[$key]["TieneDisponibilidad"] = false;
            }

            return array(
                "resultado" => true,
                "mensaje" => "Espacios consultados correctamente. No se pudo calcular disponibilidad porque no se envio el docente.",
                "data" => $espacios,
                "total_disponibles" => 0,
                "total_sin_disponibilidad" => count($espacios),
            );
        }

        $FechaInicio = date('Y-m-d', strtotime($obj->FechaInicio));
        $FechaFin = date('Y-m-d', strtotime($obj->FechaFin));
        $FechaInicioSql = FechaSqlServer::toSqlDateTime2($FechaInicio, false);
        $FechaFinSql = FechaSqlServer::toSqlDateTime2($FechaFin, true);
        if ($FechaInicioSql === false || $FechaFinSql === false) {
            return array(
                "resultado" => false,
                "mensaje" => "Formato de fechas inválido para consultar disponibilidad de espacios.",
                "consola" => "No se pudieron preparar expresiones SQL para FechaInicio ({$FechaInicio}) o FechaFin ({$FechaFin})."
            );
        }

        $DiaCodigo = date("w", strtotime($FechaInicio));
        if ($DiaCodigo == 0) {
            $DiaCodigo = 7;
        }

        $UapCodigo = $obj->UapCodigo;
        $unidades = $_SESSION["pacademica"]["datosVinculacionUsuario"]["unidades"];
        $codigosEspacios = array();
        foreach ($espacios as $espacio) {
            if (isset($espacio["EspCodigo"]) && is_numeric($espacio["EspCodigo"])) {
                $codigosEspacios[] = $espacio["EspCodigo"];
            }
        }

        $codigosEspacios = array_unique($codigosEspacios);
        if (count($codigosEspacios) <= 0) {
            return array(
                "resultado" => true,
                "mensaje" => "Espacios consultados correctamente.",
                "data" => $espacios,
                "total_disponibles" => 0,
                "total_sin_disponibilidad" => count($espacios),
            );
        }

        $espaciosSql = implode(",", $codigosEspacios);
        $sql = "
        DECLARE @FechaInicio DATETIME2 = '{$FechaInicio}';
        DECLARE @FechaFin DATETIME2 = '{$FechaFin}';

        SELECT
            eso.esp_codigo AS EspCodigo,
            h.hra_codigo AS HraCodigo,
            h.hra_nombre AS HraNombre,
            h.hra_inicio AS HraInicio,
            h.hra_fin AS HraFin
        FROM espacio_ocupacion eso
        INNER JOIN hora h
            ON h.hra_codigo = eso.hra_codigo
        WHERE
            eso.esp_codigo IN ({$espaciosSql})
            AND eso.uaa_codigo IN ({$unidades})
            AND eso.dia_codigo = {$DiaCodigo}
            AND eso.eso_actividad IS NULL
            AND eso.eso_fecha >= @FechaInicio
            AND eso.eso_fecha <= @FechaFin
            AND NOT EXISTS (
                SELECT 1
                FROM espacio_ocupacion d
                WHERE
                    d.uap_codigo = {$UapCodigo}
                    AND d.dia_codigo = {$DiaCodigo}
                    AND d.hra_codigo = h.hra_codigo
                    AND d.eso_fecha >= @FechaInicio
                    AND d.eso_fecha <= @FechaFin
            )
            AND NOT EXISTS (
                SELECT 1
                FROM espacio_ocupacion e
                WHERE
                    e.esp_codigo = eso.esp_codigo
                    AND e.hra_codigo = h.hra_codigo
                    AND e.dia_codigo = {$DiaCodigo}
                    AND e.eso_actividad IS NOT NULL
                    AND e.eso_fecha >= @FechaInicio
                    AND e.eso_fecha <= @FechaFin
                )
            GROUP BY
                eso.esp_codigo,
                h.hra_codigo,
                h.hra_nombre,
                h.hra_inicio,
                h.hra_fin
            ORDER BY
                eso.esp_codigo,
                h.hra_codigo;
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar la disponibilidad de los espacios asignados.";
            $this->errorConsultarBd["sql"] = $sql;
            return $this->errorConsultarBd;
        }

        $horasPorEspacio = array();
        foreach ($this->cnx->json as $hora) {
            $EspCodigo = $hora["EspCodigo"];
            if (!isset($horasPorEspacio[$EspCodigo])) {
                $horasPorEspacio[$EspCodigo] = array();
            }
            $horasPorEspacio[$EspCodigo][] = array(
                "HraCodigo" => $hora["HraCodigo"],
                "HraNombre" => $hora["HraNombre"],
                "HraInicio" => $hora["HraInicio"],
                "HraFin" => $hora["HraFin"],
            );
        }

        $totalDisponibles = 0;
        $totalSinDisponibilidad = 0;
        foreach ($espacios as $key => $espacio) {
            $EspCodigo = $espacio["EspCodigo"];
            $horas = isset($horasPorEspacio[$EspCodigo]) ? $horasPorEspacio[$EspCodigo] : array();
            $espacios[$key]["HorasDisponibles"] = $horas;
            $espacios[$key]["TotalHorasDisponibles"] = count($horas);
            $espacios[$key]["TieneDisponibilidad"] = count($horas) > 0;
            $espacios[$key]["DiaCodigo"] = $DiaCodigo;

            if (count($horas) > 0) {
                $totalDisponibles++;
            } else {
                $totalSinDisponibilidad++;
            }
        }

        usort($espacios, function ($a, $b) {
            if ($a["TotalHorasDisponibles"] == $b["TotalHorasDisponibles"]) {
                return strcmp($a["EspNombre"], $b["EspNombre"]);
            }
            return $b["TotalHorasDisponibles"] - $a["TotalHorasDisponibles"];
        });

        return array(
            "resultado" => true,
            "mensaje" => "Espacios y horas disponibles consultados correctamente.",
            "data" => $espacios,
            "total_disponibles" => $totalDisponibles,
            "total_sin_disponibilidad" => $totalSinDisponibilidad,
        );
    }

    //Inicio funcion consultarDocentes
    //Permite consultar los docentes vinculados a una unidad especifica
    function consultarDocentes($obj)
    {
        //Validaciones
        if (!isset($obj->UaaCodigo) || !is_numeric($obj->UaaCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar una unidad académica.",
                "consola" => "El codigo de la unidad académica no es numérico o no se envio correctamente.",
            );
        }

        //Parametros
        $UaaCodigo = $obj->UaaCodigo; //Contiene el codigo de la unidad academica.
        $unidades = $_SESSION["pacademica"]["datosVinculacionUsuario"]["unidades"]; //Almacenamos las unidades que tiene permitida el usuario
        $CalCodigo = $obj->CalCodigo; //Contiene el codigo del calendario a programar
        $administrador = $_SESSION["pacademica"]["datosVinculacionUsuario"]["Administrador"]; // 1 si es administrador, 0 si es cualquier otro
        $queryPrograma = ""; // Si no es administrador consulta segun las unidades
        if ($administrador != 1) {
            $queryPrograma = "AND uap.uaa_codigo IN ({$unidades})";
        }

        $dePlantaDocente = 12; //Carlos arbey salamanca 362 Docente de planta
        $catedraDocente = 14; //Luis fernando salamanca Catedra docente
        $catedraPosgradosDocente = 17; //emilio polo ledesma Catedra posgrado docente
        $nombramOcasionalDocente = 23; //Alexander nossa o alexandra uribe Nombramiento ocacional
        $catedraVisitanteDocente = 24; //Carlos hernando trujillo Catedra visitante
        $catedraConvenioDocente = 49;

        // Consultamos las fechas del periodo por defecto del calendario seleccionado
        $sql = "SELECT
            per.per_fecha_inicio PerFechaInicio,
            per.per_fecha_fin PerFechaFin
        FROM
            periodo per
            INNER JOIN calendario cal ON per.per_codigo = cal.per_codigo
        WHERE 
            cal.cal_codigo = {$CalCodigo}
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar las fechas del periodo del calendario {$CalCodigo}.";
            return $this->errorConsultarBd;
        }

        $r_periodo = $this->cnx->json;
        $PerFechaInicio = $r_periodo[0]['PerFechaInicio']; //Fecha de inicio establecida para el periodo
        $PerFechaFin = $r_periodo[0]['PerFechaFin']; //Fecha de fin establecida para el periodo

        //Consultamos que la unidad no tenga periodos personalizados para ese calendario
        $sql = "SELECT
            peu.peu_fecha_inicio PeuFechaInicio,
            peu.peu_fecha_fin PeuFechaFin
        FROM
            programacionacademica.periodo_unidad peu
            INNER JOIN calendario cal ON peu.per_codigo = cal.per_codigo
        WHERE 
            cal.cal_codigo = {$CalCodigo}
            AND peu.uaa_codigo = {$UaaCodigo}
            AND peu.peu_estado = 1;
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar las fechas del periodo personalizado del calendario {$CalCodigo}.";
            return $this->errorConsultarBd;
        }

        $r_periodo_personalizado = $this->cnx->json;
        if (count($r_periodo_personalizado) > 0) {
            $PerFechaInicio = $r_periodo_personalizado[0]['PeuFechaInicio']; //Fecha de inicio establecida para el periodo
            $PerFechaFin = $r_periodo_personalizado[0]['PeuFechaFin']; //Fecha de fin establecida para el periodo
        }

        //Machetazo agregado por douglas el 2022-07-11 por los posgrados de salud en el calendario 218.	20222C
        //Aun cuando van a programar el 2022-2 le debe mostrar las vinculaciones del 2022-1 para las siguientes uaa
        // 75.NEIVA - ESPECIALIZACION EN PEDIATRIA
        // 84.NEIVA - ESPECIALIZACION GINECOLOGIA Y OBSTETRICIA
        // 85.NEIVA - ESPECIALIZACION EN MEDICINA INTERNA
        // 86.NEIVA - ESPECIALIZACION EN CIRUGIA GENERAL
        // 87.NEIVA - ESPECIALIZACION EN ANESTESIOLOGIA Y REANIMACION
        // 677.NEIVA - ESPECIALIZACION EN MEDICINA CRITICA Y CUIDADO INTENSIVO
        // 685.ESPECIALIZACION EN GINECOLOGIA Y OBSTETRICIA
        if ($CalCodigo == 218 && ($UaaCodigo == 75 || $UaaCodigo == 84 || $UaaCodigo == 85 || $UaaCodigo == 86 || $UaaCodigo == 87 || $UaaCodigo == 677 || $UaaCodigo == 685)) {
            $PerFechaInicio = "2022-02-04";
            $PerFechaFin = "2022-08-12";
        }

        //Machetazo agregado por douglas el 2022-11-22 por los posgrados de salud en el calendario 220. 20231C
        // 220	124	20231C	NULL	NULL	NULL	2022	1
        if ($CalCodigo == 220 && ($UaaCodigo == 75 || $UaaCodigo == 84 || $UaaCodigo == 85 || $UaaCodigo == 86 || $UaaCodigo == 87 || $UaaCodigo == 677 || $UaaCodigo == 685)) {
            $PerFechaInicio = "2022-10-03";
            $PerFechaFin = "2023-03-10";
        }

        $PerFechaInicio = date('Y-m-d', strtotime($PerFechaInicio));
        $PerFechaFin = date('Y-m-d', strtotime($PerFechaFin));
        $PerFechaInicioSql = FechaSqlServer::toSqlDateTime2($PerFechaInicio, false);
        $PerFechaFinSql = FechaSqlServer::toSqlDateTime2($PerFechaFin, true);
        if ($PerFechaInicioSql === false || $PerFechaFinSql === false) {
            return array(
                "resultado" => false,
                "mensaje" => "Formato de fechas inválido para consultar docentes.",
                "consola" => "No se pudieron preparar expresiones SQL para PerFechaInicio ({$PerFechaInicio}) o PerFechaFin ({$PerFechaFin})."
            );
        }

        $array_final = array();

        $sql = "SELECT  --Consulta todos los docentes de planta.
            uap.uap_codigo UapCodigo, 
            uap.sed_codigo SedCodigo,
            per.per_nombre PerNombre,
            per.per_codigo PerCodigo,
            per.per_apellido PerApellido, 
            vin.vin_nombre VinNombre,
            vin.vin_codigo VinCodigo,
            ded.ded_codigo DedCodigo,
            ded.ded_nombre DedNombre,
            uap.uap_fecha_inicio UapFechaInicio, 
            uap.uap_fecha_fin UapFechaFin,
            uaa.uaa_nombre_corto UaaNombreCorto,
            (   
                SELECT count(*) 
                FROM agenda_periodo agp 
                WHERE agp.uap_codigo = uap.uap_codigo 
            ) UapCarga, 
        'No' PerNN
        FROM 
            uaa_personal uap 
        INNER JOIN vinculacion vin ON vin.vin_codigo = uap.vin_codigo AND vin.vin_clase = 1
        INNER JOIN persona per ON uap.per_codigo = per.per_codigo AND per.per_apellido NOT LIKE '%NN CATEDRA%'
        INNER JOIN dedicacion ded ON ded.ded_codigo = uap.ded_codigo
        INNER JOIN uaa ON uaa.uaa_codigo = uap.uaa_codigo
        WHERE 
            uap.uap_fecha_fin IS NULL
            AND uap.vin_codigo = {$dePlantaDocente} 
            {$queryPrograma}
        ORDER BY per.per_nombre, per.per_apellido ASC
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar los docentes de planta.";
            return $this->errorConsultarBd;
        }

        $array_final["DocentesPlanta"] = $this->cnx->json;

        $sql = "SELECT --No se que que docente sea pero consulta docentes de planta que si tengan una fecha fin y este dentro de las fechas del periodo seleccionado. ¿Preguntar a javier por que?
            uap.uap_codigo UapCodigo, 
            uap.sed_codigo SedCodigo,
            per.per_nombre PerNombre,
            per.per_codigo PerCodigo,
            per.per_apellido PerApellido, 
            vin.vin_nombre VinNombre,
            vin.vin_codigo VinCodigo,
            ded.ded_codigo DedCodigo,
            uap.uap_fecha_inicio UapFechaInicio, 
            uap.uap_fecha_fin UapFechaFin, 
            ded.ded_nombre DedNombre,
            uaa.uaa_nombre_corto UaaNombreCorto,
            (   
                SELECT count(*) 
                FROM agenda_periodo agp 
                WHERE agp.uap_codigo = uap.uap_codigo 
            ) UapCarga, 
            'No' PerNN
        FROM 
            uaa_personal uap
        INNER JOIN vinculacion vin ON vin.vin_codigo = uap.vin_codigo AND vin.vin_clase = 1
        INNER JOIN persona per ON uap.per_codigo = per.per_codigo AND per.per_apellido NOT LIKE '%NN CATEDRA%'
        INNER JOIN dedicacion ded ON ded.ded_codigo = uap.ded_codigo
        INNER JOIN uaa ON uaa.uaa_codigo = uap.uaa_codigo
        WHERE 
            uap.uap_fecha_fin >= {$PerFechaInicioSql}
            AND uap.uap_fecha_fin <= {$PerFechaFinSql}
            AND uap.vin_codigo = {$dePlantaDocente} 
            {$queryPrograma}
            AND uap.uap_fecha_inicio != uap.uap_fecha_fin
        ORDER BY per.per_nombre, per.per_apellido ASC
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar los docentes de planta con fecha fin de vinculación.";
            return $this->errorConsultarBd;
        }

        $array_final["DocentesPlantaFechaFin"] = $this->cnx->json;

        $sql = "SELECT --Consulta docentes de catedra con vinculacion activa segun las fechas inicio y fin del periodo seleccionado.
            uap.uap_codigo UapCodigo, 
            uap.sed_codigo SedCodigo,
            per.per_nombre PerNombre,
            per.per_codigo PerCodigo,
            per.per_apellido PerApellido, 
            vin.vin_nombre VinNombre,
            vin.vin_codigo VinCodigo,
            ded.ded_codigo DedCodigo,
            uap.uap_fecha_inicio UapFechaInicio, 
            uap.uap_fecha_fin UapFechaFin, 
            ded.ded_nombre DedNombre,
            uaa.uaa_nombre_corto UaaNombreCorto,
            (   
                SELECT count(*) 
                FROM agenda_periodo agp 
                WHERE agp.uap_codigo = uap.uap_codigo 
            ) UapCarga, 
            'No' PerNN
        FROM 
            uaa_personal uap 
        INNER JOIN vinculacion vin ON vin.vin_codigo = uap.vin_codigo AND vin_clase = 1
        INNER JOIN persona per ON uap.per_codigo = per.per_codigo AND per.per_apellido NOT LIKE '%NN CATEDRA%'
        INNER JOIN dedicacion ded ON ded.ded_codigo = uap.ded_codigo
        INNER JOIN uaa ON uaa.uaa_codigo = uap.uaa_codigo
        WHERE  
            uap.uap_fecha_inicio >= {$PerFechaInicioSql}
            AND uap.uap_fecha_fin <= {$PerFechaFinSql}
            AND uap.vin_codigo IN ({$catedraPosgradosDocente},{$catedraVisitanteDocente},{$catedraDocente}, {$catedraConvenioDocente}) 
            AND uap.uap_fecha_inicio != uap.uap_fecha_fin
            {$queryPrograma}
        ORDER BY per.per_nombre, per.per_apellido ASC
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar los docentes de catedra con vinculación vigente.";
            return $this->errorConsultarBd;
        }

        $array_final["DocentesCatedra"] = $this->cnx->json;

        $sql = "SELECT --Consulta los docentes de nombramiento ocacional con vinculacion activa entre fecha de inicio  y fin del periodo seleccionado
            uap.uap_codigo UapCodigo,
            uap.sed_codigo SedCodigo,
            per.per_nombre PerNombre,
            per.per_codigo PerCodigo,
            per.per_apellido PerApellido,
            vin.vin_nombre VinNombre,
            vin.vin_codigo VinCodigo,
            ded.ded_codigo DedCodigo,
            uap.uap_fecha_inicio UapFechaInicio,
            uap.uap_fecha_fin UapFechaFin,
            ded.ded_nombre DedNombre,
            uaa.uaa_nombre_corto UaaNombreCorto,
            (   
                SELECT count(*) 
                FROM agenda_periodo agp 
                WHERE agp.uap_codigo = uap.uap_codigo 
            ) UapCarga, 
            'No' PerNN
        FROM
            uaa_personal uap
        INNER JOIN vinculacion vin ON vin.vin_codigo = uap.vin_codigo AND vin.vin_clase = 1
        INNER JOIN persona per ON uap.per_codigo = per.per_codigo AND per.per_apellido NOT LIKE '%NN CATEDRA%'
        INNER JOIN dedicacion ded ON ded.ded_codigo = uap.ded_codigo
        INNER JOIN uaa ON uaa.uaa_codigo = uap.uaa_codigo
        WHERE 
            uap.uap_fecha_inicio >= {$PerFechaInicioSql}
            AND uap.uap_fecha_fin <= {$PerFechaFinSql}
            -- uap.uap_fecha_fin BETWEEN '{$PerFechaInicio}' AND '{$PerFechaFin}' 
            AND uap.vin_codigo IN ({$nombramOcasionalDocente})
            AND uap.uap_fecha_inicio != uap.uap_fecha_fin
            {$queryPrograma}
        ORDER BY per.per_nombre, per.per_apellido ASC
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar los docentes de nombramiento ocacional con vinculación vigente.";
            return $this->errorConsultarBd;
        }

        $array_final["DocentesNombramientoOcacional"] = $this->cnx->json;

        $sql = "SELECT --Consulta los docentes de nombramiento ocacional con vinculacion fecha fin mayor o igual a la fecha fin del periodo ¿Preguntar a javier?
            uap.uap_codigo UapCodigo,
            uap.sed_codigo SedCodigo,
            per.per_nombre PerNombre,
            per.per_codigo PerCodigo,
            per.per_apellido PerApellido,
            vin.vin_nombre VinNombre,
            vin.vin_codigo VinCodigo,
            ded.ded_codigo DedCodigo,
            uap.uap_fecha_inicio UapFechaInicio,
            uap.uap_fecha_fin UapFechaFin,
            ded.ded_nombre DedNombre,
            uaa.uaa_nombre_corto UaaNombreCorto,
            (   
                SELECT count(*) 
                FROM agenda_periodo agp 
                WHERE agp.uap_codigo = uap.uap_codigo 
            ) UapCarga, 
            'No' PerNN
        FROM 
            uaa_personal uap 
        INNER JOIN vinculacion vin ON vin.vin_codigo = uap.vin_codigo AND vin.vin_clase = 1
        INNER JOIN persona per ON uap.per_codigo = per.per_codigo AND per.per_apellido NOT LIKE 'NN CATEDRA%'
        INNER JOIN dedicacion ded ON ded.ded_codigo = uap.ded_codigo
        INNER JOIN uaa ON uaa.uaa_codigo = uap.uaa_codigo
        WHERE 
            uap.uap_fecha_fin >= {$PerFechaFinSql}
            AND uap.vin_codigo IN ({$nombramOcasionalDocente})
            AND uap.uap_fecha_inicio != uap.uap_fecha_fin
            {$queryPrograma}
        ORDER BY per.per_nombre, per.per_apellido ASC
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar los docentes de nombramiento ocacional con vinculación posterior a la fecha fin del periodo {$PerFechaFin}.";
            return $this->errorConsultarBd;
        }

        $array_final["DocentesNombramientoOcacionalPosterior"] = $this->cnx->json;

        $sql = "SELECT --Consulta docentes que no sean de planta ni de nombramiento ocacional con una vinculacion activa entre la fecha de inicio y fin del periodo seleccionado
            uap.uap_codigo UapCodigo,
            uap.sed_codigo SedCodigo,
            per.per_nombre PerNombre,
            per.per_codigo PerCodigo,
            per.per_apellido PerApellido,
            vin.vin_nombre VinNombre,
            vin.vin_codigo VinCodigo,
            ded.ded_codigo DedCodigo,
            uap.uap_fecha_inicio UapFechaInicio,
            uap.uap_fecha_fin UapFechaFin,
            ded.ded_nombre DedNombre,
            uaa.uaa_nombre_corto UaaNombreCorto,
            (   
                SELECT count(*) 
                FROM agenda_periodo agp 
                WHERE agp.uap_codigo = uap.uap_codigo 
            ) UapCarga, 
            'No' PerNN
        FROM
            uaa_personal uap
            INNER JOIN vinculacion vin ON vin.vin_codigo = uap.vin_codigo AND vin.vin_clase = 1
            INNER JOIN persona per ON uap.per_codigo = per.per_codigo AND per.per_apellido NOT LIKE '%NN CATEDRA%'
            INNER JOIN dedicacion ded ON ded.ded_codigo=uap.ded_codigo
            INNER JOIN uaa ON uaa.uaa_codigo = uap.uaa_codigo
        WHERE 
            uap.uap_fecha_inicio >= {$PerFechaInicioSql}
            AND uap.uap_fecha_fin <= {$PerFechaFinSql}
            AND uap.vin_codigo NOT IN ({$dePlantaDocente},{$nombramOcasionalDocente})
            AND uap.uap_fecha_inicio != uap.uap_fecha_fin
            {$queryPrograma}
        ORDER BY per.per_nombre, per.per_apellido ASC
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar los docentes que no sean de planta ni nombramiento ocacional con vinculación vigente.";
            return $this->errorConsultarBd;
        }

        $array_final["DocentesOtros"] = $this->cnx->json; //No se como nombrarlos

        $sql = "SELECT
            uap.uap_codigo UapCodigo,
            uap.sed_codigo SedCodigo,
            per.per_nombre PerNombre,
            per.per_codigo PerCodigo,
            per.per_apellido PerApellido,
            vin.vin_nombre VinNombre,
            vin.vin_codigo VinCodigo,
            ded.ded_codigo DedCodigo,
            uap.uap_fecha_inicio UapFechaInicio,
            uap.uap_fecha_fin UapFechaFin,
            ded.ded_nombre DedNombre,
            uaa.uaa_nombre_corto UaaNombreCorto,
            (   
                SELECT count(*) 
                FROM agenda_periodo agp 
                WHERE agp.uap_codigo = uap.uap_codigo 
            ) UapCarga, 
            'Si' PerNN
        FROM 
            uaa_personal uap
        INNER JOIN vinculacion vin ON vin.vin_codigo = uap.vin_codigo AND vin.vin_clase = 1
        INNER JOIN persona per ON uap.per_codigo = per.per_codigo AND per.per_apellido LIKE '%NN CATEDRA%'
        INNER JOIN dedicacion ded ON ded.ded_codigo = uap.ded_codigo
        INNER JOIN uaa ON uaa.uaa_codigo = uap.uaa_codigo
        WHERE 
            uap.uap_fecha_inicio >= {$PerFechaInicioSql}
            AND uap.uap_fecha_fin <= {$PerFechaFinSql}
            AND uap.vin_codigo = {$catedraDocente}
            AND uap.uap_fecha_inicio != uap.uap_fecha_fin
            {$queryPrograma}
        ORDER BY per.per_nombre, per.per_apellido ASC
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar los docentes NN con vinculación vigente.";
            return $this->errorConsultarBd;
        }

        $array_final["DocentesNN"] = $this->cnx->json;

        //Formato periodo personalizado para que solo sea año - mes - dia
        $PerFechaInicio = date('Y-m-d', strtotime($PerFechaInicio));
        $PerFechaFin = date('Y-m-d', strtotime($PerFechaFin));

        return array(
            "resultado" => true,
            "mensaje" => "Docentes consultados correctamente.",
            "data" => $array_final,
            "fecha_inicial" => $PerFechaInicio,
            "fecha_final" => $PerFechaFin
        );
    }

    //Inicio funcion consultarAgendaDocente
    //Se usa para conocer la agenda de un docente desde el administrador.
    //Se debe consultar si la uaa tiene un periodo personalizado para el calendario seleccionado
    function consultarAgendaDocente($obj)
    {
        //Parametros:
        $UapCodigo = $obj->UapCodigo; //Contiene codigo de la vinculacion del docente especifica
        $CalCodigo = $obj->CalCodigo; //Contiene codigo del calendario especifico
        $UaaCodigo = $obj->UaaCodigo; //Contiene codigo de la unidad para consultar si tiene periodo personalizado
        $periodo_inicio = ""; //La fecha de inicio de un periodo especifico
        $periodo_fin = ""; //La fecha de fin de un periodo especifico

        // Consultamos las fechas del periodo por defecto del calendario seleccionado
        $sql = "SELECT
            per.per_fecha_inicio PerFechaInicio,
            per.per_fecha_fin PerFechaFin
        FROM
            periodo per
            INNER JOIN calendario cal ON per.per_codigo = cal.per_codigo
        WHERE 
            cal.cal_codigo = {$CalCodigo}
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar las fechas del periodo del calendario {$CalCodigo}.";
            return $this->errorConsultarBd;
        }

        $r_periodo = $this->cnx->json;
        $periodo_inicio = $r_periodo[0]['PerFechaInicio']; //Fecha de inicio establecida para el periodo
        $periodo_fin = $r_periodo[0]['PerFechaFin']; //Fecha de fin establecida para el periodo

        //Consultamos que la unidad no tenga periodos personalizados para ese calendario
        $sql = "SELECT
            peu.peu_fecha_inicio PeuFechaInicio,
            peu.peu_fecha_fin PeuFechaFin
        FROM
            programacionacademica.periodo_unidad peu
            INNER JOIN calendario cal ON peu.per_codigo = cal.per_codigo
        WHERE 
            cal.cal_codigo = {$CalCodigo}
            AND peu.uaa_codigo = {$UaaCodigo}
            AND peu.peu_estado = 1;
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar las fechas del periodo personalizado del calendario {$CalCodigo}.";
            return $this->errorConsultarBd;
        }

        $r_periodo_personalizado = $this->cnx->json;
        if (count($r_periodo_personalizado) > 0) {
            $periodo_inicio = $r_periodo_personalizado[0]['PeuFechaInicio']; //Fecha de inicio establecida para el periodo
            $periodo_fin = $r_periodo_personalizado[0]['PeuFechaFin']; //Fecha de fin establecida para el periodo
        }

        $periodo_inicio = date('Y-m-d', strtotime($periodo_inicio));
        $periodo_fin = date('Y-m-d', strtotime($periodo_fin));
        $periodoInicioSql = FechaSqlServer::toSqlDateTime2($periodo_inicio, false);
        $periodoFinSql = FechaSqlServer::toSqlDateTime2($periodo_fin, true);
        if ($periodoInicioSql === false || $periodoFinSql === false) {
            return array(
                "resultado" => false,
                "mensaje" => "Formato de fechas inválido para consultar agenda.",
                "consola" => "No se pudieron preparar expresiones SQL para periodo_inicio ({$periodo_inicio}) o periodo_fin ({$periodo_fin})."
            );
        }



        $sql = "SELECT DISTINCT 
            cur.cur_codigo CurCodigo, 
            eso.eso_subgrupo EsoSubgrupo,
            asi.asi_nombre AsiNombre, 
            asi.asi_nombre_corto AsiNombreCorto, 
            cur.cur_grupo CurGrupo, 
            per.per_nombre PerNombre, 
            per.per_apellido PerApellido, 
            eso.dia_codigo DiaCodigo, 
            eso.hra_codigo HraCodigo, 
            uaa.uaa_nombre_corto UaaNombreCorto, 
            uaa.uaa_codigo UaaCodigo, 
            asi.nuc_codigo NucCodigo,
            esp.esp_codigo EspCodigo,
            esp.esp_nombre_corto EspNombreCorto,
            cal.cal_nombre CalNombre
        FROM 
            espacio_ocupacion eso 
        INNER JOIN curso cur ON cur.cur_codigo = eso.eso_actividad
        INNER JOIN asignatura asi ON asi.asi_codigo = cur.asi_codigo 
        INNER JOIN uaa ON uaa.uaa_codigo = eso.uaa_codigo 
        INNER JOIN uaa_personal uap ON eso.uap_codigo = uap.uap_codigo 
        INNER JOIN persona  per ON per.per_codigo = uap.per_codigo
        INNER JOIN espacio esp ON eso.esp_codigo = esp.esp_codigo
        INNER JOIN calendario cal ON cal.cal_codigo = cur.cal_codigo
        WHERE
            (eso_fecha BETWEEN {$periodoInicioSql} AND {$periodoFinSql}) AND 
            per.per_codigo = (SELECT per_codigo FROM uaa_personal WHERE uap_codigo={$UapCodigo})
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar la agenda del docente {$UapCodigo} en el calendario {$CalCodigo}";
            return $this->errorConsultarBd;
        }

        $r_agenda = $this->cnx->json;
        $array_final = array();
        $dias = [
            1 => "Lunes",
            2 => "Martes",
            3 => "Miercoles",
            4 => "Jueves",
            5 => "Viernes",
            6 => "Sabado",
            7 => "Domingo"
        ];
        $array = [];
        for ($h = 1; $h <= 18; $h++) {
            for ($d = 1; $d <= 8; $d++) {
                $tiene = false;
                foreach ($r_agenda as $agenda) {
                    if ($agenda["DiaCodigo"] == $d && $agenda["HraCodigo"] == $h) {
                        $tiene = true;
                        $array = [ //Organizamos un array con los datos de la facultad
                            "CurCodigo" => utf8_decode($agenda['CurCodigo']),
                            "AsiNombre" => utf8_decode($agenda['AsiNombre']),
                            "AsiNombreCorto" => utf8_decode($agenda['AsiNombreCorto']),
                            "CurGrupo" => utf8_decode($agenda['CurGrupo']),
                            "PerNombre" => utf8_decode($agenda['PerNombre']),
                            "PerApellido" => utf8_decode($agenda['PerApellido']),
                            "DiaCodigo" => utf8_decode($agenda['DiaCodigo']),
                            "HraCodigo" => utf8_decode($agenda['HraCodigo']),
                            "UaaNombreCorto" => utf8_decode($agenda['UaaNombreCorto']),
                            "UaaCodigo" => utf8_decode($agenda['UaaCodigo']),
                            "NucCodigo" => utf8_decode($agenda['NucCodigo']),
                            "EspCodigo" => utf8_decode($agenda['EspCodigo']),
                            "EspNombreCorto" => utf8_decode($agenda['EspNombreCorto']),
                            "CalNombre" => utf8_decode($agenda['CalNombre']),
                            "EsoSubgrupo" => utf8_decode($agenda['EsoSubgrupo']),
                        ];
                        break;
                    }
                }

                if ($tiene == true) {
                    $array_final[$h][$d] = array_map('utf8_encode', $array);
                } else {
                    $array_final[$h][$d] = "{$dias[$d]} - {$h}";
                }
            }
        }

        //Formato periodo personalizado para que solo sea año - mes - dia
        $periodo_inicio = date('Y-m-d', strtotime($periodo_inicio));
        $periodo_fin = date('Y-m-d', strtotime($periodo_fin));

        return array(
            "resultado" => true,
            "mensaje" => "Detalle de la agenda consultada correctamente.",
            "data" => $array_final,
            "fecha_inicial" => $periodo_inicio,
            "fecha_final" => $periodo_fin
        );
    }

    /**
     * Consulta la carga detallada del docente seleccionado.
     */
    public function consultarCargaDocente($obj)
    {
        if (!isset($obj->UapCodigo) || !is_numeric($obj->UapCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Código de vinculación inválido.",
                "consola" => "UapCodigo no numérico en consultarCargaDocente()."
            );
        }
        if (!isset($obj->CalCodigo) || !is_numeric($obj->CalCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Código de calendario inválido.",
                "consola" => "CalCodigo no numérico en consultarCargaDocente()."
            );
        }

        $sqlPer = "SELECT per.per_nombre FROM calendario cal INNER JOIN periodo per ON per.per_codigo = cal.per_codigo WHERE cal.cal_codigo = {$obj->CalCodigo}";
        if (!$this->cnx->consultar($sqlPer)) {
            return array(
                "resultado" => false,
                "mensaje" => "Error al consultar el periodo del curso.",
                "consola" => "Fallo SQL al obtener periodo para CalCodigo {$obj->CalCodigo}"
            );
        }

        $periodoNombre = $this->cnx->json[0]['per_nombre'];
        $servicio = new ValidarCargaDocenteService($this->cnx);
        $facultadCodigo = isset($obj->FacultadCodigo) ? intval($obj->FacultadCodigo) : 0;

        $sqlInfo = "SELECT
                uap.vin_codigo VinCodigo,
                uap.ded_codigo DedCodigo,
                uap.sed_codigo SedCodigo,
                sed.sed_nombre SedNombre
            FROM uaa_personal uap
            INNER JOIN sede sed ON sed.sed_codigo = uap.sed_codigo
            WHERE uap.uap_codigo = {$obj->UapCodigo}";

        if (!$this->cnx->consultar($sqlInfo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Error al consultar la sede del docente.",
                "consola" => "Fallo SQL al obtener sede para UapCodigo {$obj->UapCodigo}"
            );
        }

        $vinCodigo = intval($this->cnx->json[0]['VinCodigo']);
        $dedCodigo = intval($this->cnx->json[0]['DedCodigo']);
        $sedCodigo = intval($this->cnx->json[0]['SedCodigo']);
        $sedNombre = $this->cnx->json[0]['SedNombre'];

        $topeSemanal = null;
        $topeSemestral = null;

        if (in_array($vinCodigo, array(14, 24, 49)) && $dedCodigo == 6) {
            $topes = $servicio->obtenerTopesSemanalesCatedra($sedCodigo);
            if (!$topes["resultado"]) {
                return $topes;
            }
            $topeSemanal = $sedCodigo != 1 ? floatval($topes["data"]["topeSedes"]) : floatval($topes["data"]["topeNeiva"]);
        } elseif ($vinCodigo == 12 || $vinCodigo == 23 || ($dedCodigo == 4 || $dedCodigo == 5)) {
            if ($dedCodigo == 5) {
                $topeSemestral = 880;
            }
            if ($dedCodigo == 4) {
                $topeSemestral = 440;
            }
        }

        $r = $servicio->obtenerCargaDetalladaDocente($obj->UapCodigo, $periodoNombre, $facultadCodigo);

        if ($r["resultado"]) {
            $r["data"]["topeSemanal"] = $topeSemanal;
            $r["data"]["topeSemestral"] = $topeSemestral;
            $r["data"]["sedCodigo"] = $sedCodigo;
            $r["data"]["sedNombre"] = $sedNombre;
        }

        return $r;
    }

    //Inicio funcion consultarAdministrador
    //Se usa para saber si el usuario que esta logueado es o no administrador.
    function consultarAdministrador()
    {
        //Validaciones

        //Parametros
        $administrador = $_SESSION["pacademica"]["datosVinculacionUsuario"]["Administrador"]; //Contiene si el usuario es administrador (1) o no (0)
        return $administrador;
    }

    //Inicio funcion consultarDetalleCurso
    //Permite consultar el detalle de un curso en especifico
    function consultarDetalleCurso($obj)
    {
        if (!isset($obj->CurCodigo) || !is_numeric($obj->CurCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar un curso.",
                "consola" => "El codigo del curso no es numérico o no se envio correctamente.",
            );
        }

        $CurCodigo = $obj->CurCodigo; //Contiene el codigo del curso seleccionado
        $date = FechaSqlServer::nowIso8601(); //Contiene fecha actual para validar si se puede modificar el curso.

        $sql = "SELECT 
            cur.cur_codigo CurCodigo, 
            cur.uap_codigo UapCodigo, --Codigo de vinculacion uaa_persona.uap_codigo del coordinador del curso
            cur.asi_codigo AsiCodigo, 
            cur.sed_codigo SedCodigo, 
            cur.cal_codigo CalCodigo,
            cal.cal_nombre CalNombre, --Calendario al que se programa el curso
            cal.per_codigo PeriodoCodigo,
            cur.cur_grupo CurGrupo, 
            cur.cur_cupo CurCupo, --Cupo total del curso
            cur.cur_estado CurEstado, --1. activo, 0. eliminado
            cur.pla_codigo PlaCodigo, --Codigo del plan academico del curso.
            pla.pla_nombre PlaNombre, --Nombre del plan academico del curso.
            cut.cut_codigo CutCodigo, --Codigo del tipo curso. De momento solo se programa con 1. Normal
            cut.cut_nombre CutNombre, --Nombre del tipo curso.
            cur.cur_exclusivo CurExclusivo, --Define si un curso es exclusivo o no para su plan academico.
            sed.sed_nombre SedNombre, --Sede donde queda disponible el curso
            asi.asi_nombre_corto AsiNombreCorto, 
            asi.asi_nombre AsiNombre, 
            asi.asi_creditos AsiCreditos, 
            asi.asi_creditos_teoria AsiCreditosTeoria, 
            asi.asi_creditos_practica AsiCreditosPractica, 

            asi.asi_trabajo_horas_teorico AsiHorasSemanalesTeorico,
            asi.asi_trabajo_horas_practico AsiHorasSemanalesPractica,
            asi.asi_trabajo_horas_teorico_practico AsiHorasSemanalesTeoricoPractico,

            asi.nuc_codigo NucCodigo, 
            per.per_nombre + ' ' + per.per_apellido as PerNombreApellido, --Docente coordinador
            per.per_codigo PerCodigo, --codigo de la persona del docente coordinador
            vin.vin_nombre VinNombre, --Vinculacion del docente coordinador
            vin.vin_codigo VinCodigo, --Codigo de vinculacion del docente coordinador
            ded.ded_codigo DedCodigo, --Codigo de la dedicacion
            ded.ded_nombre DedNombre, --Nombre de la dedicacion
            uap.ded_codigo DedCodigo, --Codigo de dedicacion del docente
            uap.sed_codigo UapSedCodigo, --Codigo de  la sede de la vinculación del docente
            cur.cdp_codigo CdpCodigo, --?? Preguntar si se sigue usando o que mierdas
            cur.cur_semanas CurSemanas, --Duracion de semanas para el curso
            asi.car_codigo CarCodigo, --Codigo del caracter
            nuc.nuc_nombre NucNombre, --Nombre del Nucleo
            car.car_nombre CarNombre, --Nombre del caracter.
            cur.tic_codigo TicCodigo, --Modalidad 1. Presencial, 2. Apoyo virtual (b-Learning), 3. Mixto
            cur.cur_observaciones CurObservaciones,
            cur.cur_ampliacion_cupo CurAmpliacionCupo, --La ampliacion reserva cupo del cupo total, no amplia.
            cur.cur_notaparcial CurNotaParcial,
            cur.tes_codigo TesCodigo, --Calificacion 1. Numerico (0-5), 2. Aprobado/Reprobado, 3.Tres niveles
            uaa.uaa_nombre_corto UaaNombreCorto, --Unidad dueña de la asignatura.
            uaa.uaa_codigo UaaCodigo, 
            cur.cur_url CurUrl, --Link de meet
            cur.usu_codigo UsuCodigo,
            (
                SELECT 
                    TOP 1 uaa_codigo 
                FROM 
                    espacio_ocupacion 
                WHERE 
                    eso_actividad = cur.cur_codigo
            ) UaaHorario, --No tengo bien claro pero es la unidad que se usa en espacio ocupacion 'El programa donde se hace la programacion academica.'
            (
                SELECT 
                    count(*) 
                FROM 
                    matricula_curso mac
                WHERE 
                    mac.cur_codigo = {$CurCodigo} AND 
                    mac.maa_codigo IN (1,2) --matricula_autorizacion 1. Adicion, 2.Normal (Solo cuenta las matriculas 'activas').
            ) TotalMatriculados
        FROM 
            curso cur
        LEFT JOIN plan_academico pla ON pla.pla_codigo = cur.pla_codigo
        INNER JOIN calendario cal ON cal.cal_codigo = cur.cal_codigo
        INNER JOIN sede sed ON sed.sed_codigo = cur.sed_codigo
        INNER JOIN asignatura asi ON asi.asi_codigo = cur.asi_codigo
        INNER JOIN uaa_personal uap ON uap.uap_codigo = cur.uap_codigo
        INNER JOIN persona per ON per.per_codigo = uap.per_codigo
        INNER JOIN uaa ON uaa.uaa_codigo = asi.uaa_codigo
        INNER JOIN vinculacion vin ON vin.vin_codigo = uap.vin_codigo
        INNER JOIN dedicacion ded ON ded.ded_codigo = uap.ded_codigo
        INNER JOIN caracter car ON car.car_codigo = asi.car_codigo
        INNER JOIN nucleo nuc ON nuc.nuc_codigo = asi.nuc_codigo
        INNER JOIN curso_tipo cut ON cut.cut_codigo = cur.cut_codigo
        WHERE
            cur.cur_codigo = {$CurCodigo}
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar del detalle del curso {$CurCodigo}.";
            return $this->errorConsultarBd;
        }

        $c_curso = $this->cnx->json; //Almacenamos el contenido del curso especifico.

        //Se necesita obtener si el calendario es de pregrado A,D o postgrado C

        $c_curso[0]["CalTipo"] = substr($c_curso[0]["CalNombre"], -1);

        return array(
            "resultado" => true,
            "mensaje" => "Detalle del curso consultado correctamente.",
            "data" => $c_curso
        );
    }

    //Inicio funcion consultarCursos
    //Permite consultar los cursos creados para un calendario y unidades del usuario.
    function consultarCursos($obj)
    {
        //Validaciones
        if (!isset($obj->CalCodigo) || !is_numeric($obj->CalCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar un calendario.",
                "consola" => "El codigo del calendario no es numérico o no se envio correctamente.",
            );
        }

        //Parametros
        $CalCodigo = $obj->CalCodigo; //Contiene el codigo del calendario seleccionado.
        $unidades = $_SESSION["pacademica"]["datosVinculacionUsuario"]["unidades"]; //Almacenamos las unidades que tiene permitida el usuario
        $administrador = $_SESSION["pacademica"]["datosVinculacionUsuario"]["Administrador"]; //Almacenamos si es administrador (1) o no (0)
        $usuario = $_SESSION["pacademica"]["datosVinculacionUsuario"]["usuarioCodigo"]; //Almacenamos el codigo del usuario
        $date = FechaSqlServer::nowIso8601();

        if ($administrador == 1) {
            $sql = "SELECT 
                1 Administrador,
                1 Apertura,
                cur.cur_codigo CurCodigo, 
                cur.cur_grupo CurGrupo, 
                sed.sed_nombre SedNombre,
                asi.nuc_codigo NucCodigo, 
                nuc.nuc_nombre NucNombre, 
                asi.asi_nombre AsiNombre, 
                asi.asi_nombre_corto AsiNombreCorto, 
                asi.asi_creditos AsiCreditos,
                asi.asi_creditos_teoria AsiCreditosTeoria,
                asi.asi_creditos_practica AsiCreditosPractica,
                asi.car_codigo CarCodigo,
                cur.pla_codigo PlaCodigo, 
                cur.cur_url CurUrl, 
                cur.cur_cupo CurCupo, 
                cur.cur_estado CurEstado,
                cut.cut_nombre CutNombre,
                uaa.uaa_codigo UaaCodigo,
                uaa.uaa_nombre_corto UaaNombreCorto,
                (
                    SELECT 
                        count(*) 
                    FROM 
                        matricula_curso mac
                    WHERE 
                        mac.cur_codigo = cur.cur_codigo AND 
                        mac.maa_codigo IN (1,2) --matricula_autorizacion 1. Adicion, 2.Normal (Solo cuenta las matriculas 'activas').
                ) TotalMatriculados,
                (
                    SELECT
                        CASE COUNT(*) WHEN 0 THEN 0 ELSE 1 END
                    FROM
                        espacio_ocupacion eso
                    WHERE
                        eso.eso_actividad = cur.cur_codigo
                ) TotalHorario,
                (
                    SELECT
                        COUNT(*)
                    FROM
                        (
                            SELECT
                                eso.dia_codigo,
                                eso.hra_codigo,
                                eso.eso_subgrupo
                            FROM
                                espacio_ocupacion eso
                            WHERE
                                eso.eso_actividad = cur.cur_codigo
                            GROUP BY
                                eso.dia_codigo,
                                eso.hra_codigo,
                                eso.eso_subgrupo
                        ) horas_unicas
                ) TotalHorasProgramadas,
                tic.tic_codigo TicCodigo,
                tic.tic_nombre TicNombre
                -- ,(
                --     SELECT *
                --     FROM
                --         programacionacademica.programacion_academica pra
                --     WHERE

                -- ) PeriodoPersonalizado
            FROM 
                curso cur
            INNER JOIN asignatura asi ON asi.asi_codigo = cur.asi_codigo
            LEFT JOIN uaa ON uaa.uaa_codigo = asi.uaa_codigo
            LEFT JOIN sede sed ON sed.sed_codigo = cur.sed_codigo
            LEFT JOIN nucleo nuc ON nuc.nuc_codigo = asi.nuc_codigo
            LEFT JOIN curso_tipo cut ON cut.cut_codigo = cur.cut_codigo
            INNER JOIN tipo_curso tic on tic.tic_codigo = cur.tic_codigo
            WHERE 
                cur.cal_codigo = {$CalCodigo}
            ORDER BY 
                cur.cur_estado DESC,
                uaa.uaa_nombre_corto ASC,
                cur.cur_codigo ASC
            ";
        }

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar los cursos del calendario {$CalCodigo}.";
            $this->errorConsultarBd["sql"] = $sql;
            return $this->errorConsultarBd;
        }

        return array(
            "resultado" => true,
            "mensaje" => "Cursos consultados correctamente.",
            "data" => $this->cnx->json
        );
    }

    //Inicio function consultarPeriodos
    //Permite consultar los ultimos 10 periodos activos
    function consultarCalendarios($obj)
    {

        //Validaciones
        if (!isset($obj->PerCodigo) || !is_numeric($obj->PerCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar el periodo.",
                "consola" => "El codigo del periodo no es numérico o no se envio correctamente. {$obj->PerCodigo}",
            );
        }

        //Parametros
        $PerCodigo = $obj->PerCodigo; //Contiene el codigo especifico del periodo seleccionado.

        $sql = "SELECT TOP 15
                cal.cal_codigo CalCodigo,
                cal.cal_nombre CalNombre
            FROM calendario cal
            WHERE cal.per_codigo = {$PerCodigo} AND cal.cal_estado = 1
            ORDER BY cal.cal_nombre ASC
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar los calendarios del periodo seleccionado {$PerCodigo}.";
            return $this->errorConsultarBd;
        }

        if (count($this->cnx->json) > 0) {
            return array(
                "resultado" => true,
                "mensaje" => "Calendarios consultados correctamente.",
                "data" => $this->cnx->json
            );
        } else {
            return array(
                "resultado" => false,
                "mensaje" => "No se encontron calendarios.",
            );
        }
    }

    //Inicio funcion consultarCurso
    //Permite consultar la informacion completa de la creación de un curso especifico.
    function consultarCurso($obj)
    {
        //Validaciones
        if (!isset($obj->CurCodigo) || !is_numeric($obj->CurCodigo)) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe ingresar el código del curso.",
                "consola" => "El codigo del curso no es numérico o no se envio correctamente. {$obj->CurCodigo}",
            );
        }

        //Parametros
        $CurCodigo = $obj->CurCodigo; //Contiene el codigo del curso a buscar.

        $sql = "SELECT 
            cur.cur_codigo CurCodigo, 
            cur.uap_codigo UapCodigo, --Codigo de vinculacion uaa_persona.uap_codigo del coordinador del curso
            cur.asi_codigo AsiCodigo, 
            cur.sed_codigo SedCodigo, 
            cur.cal_codigo CalCodigo,
            cal.cal_nombre CalNombre, --Calendario al que se programa el curso
            cur.cur_grupo CurGrupo, 
            cur.cur_cupo CurCupo, --Cupo total del curso
            cur.cur_estado CurEstado, --1. activo, 0. eliminado
            cur.pla_codigo PlaCodigo, --Codigo del plan academico del curso.
            pla.pla_nombre PlaNombre, --Nombre del plan academico del curso.
            cut.cut_codigo CutCodigo, --Codigo del tipo curso. De momento solo se programa con 1. Normal
            cut.cut_nombre CutNombre, --Nombre del tipo curso.
            cur.cur_exclusivo CurExclusivo, --Define si un curso es exclusivo o no para su plan academico.
            sed.sed_nombre SedNombre, --Sede donde queda disponible el curso
            asi.asi_nombre_corto AsiNombreCorto, 
            asi.asi_nombre AsiNombre, 
            asi.asi_creditos AsiCreditos, 
            asi.asi_creditos_teoria AsiCreditosTeoria, 
            asi.asi_creditos_practica AsiCreditosPractica, 
            per.per_nombre + ' ' + per.per_apellido as PerNombreApellido, --Docente coordinador
            per.per_codigo PerCodigo, --codigo de la persona del docente coordinador
            vin.vin_nombre VinNombre, --Vinculacion del docente coordinador
            vin.vin_codigo VinCodigo, --Codigo de vinculacion del docente coordinador
            uap.ded_codigo DedCodigo, --Codigo de dedicacion del docente
            uap.sed_codigo UapSedCodigo, --Codigo de  la sede de la vinculación del docente
            cur.cdp_codigo CdpCodigo, --?? Preguntar si se sigue usando o que mierdas
            cur.cur_semanas CurSemanas, --Duracion de semanas para el curso
            asi.car_codigo CarCodigo, --Codigo del caracter
            car.car_nombre CarNombre, --Nombre del caracter.
            cur.tic_codigo TicCodigo, --Modalidad 1. Presencial, 2. Apoyo virtual (b-Learning), 3. Mixto
            cur.cur_observaciones CurObservaciones,
            cur.cur_ampliacion_cupo CurAmpliacionCupo, --La ampliacion reserva cupo del cupo total, no amplia.
            cur.cur_notaparcial CurNotaParcial,
            cur.tes_codigo TesCodigo, --Calificacion 1. Numerico (0-5), 2. Aprobado/Reprobado, 3.Tres niveles
            uaa.uaa_nombre_corto UaaNombreCorto, --Unidad dueña de la asignatura.
            uaa.uaa_codigo UaaCodigo, 
            cur.cur_url CurUrl, --Link de meet
            (
                SELECT 
                    TOP 1 uaa_codigo 
                FROM 
                    espacio_ocupacion 
                WHERE 
                    eso_actividad = cur.cur_codigo
            ) UaaHorario, --No tengo bien claro pero es la unidad que se usa en espacio ocupacion 'El programa donde se hace la programacion academica.'
            (
                SELECT 
                    count(*) 
                FROM 
                    matricula_curso mac
                WHERE 
                    mac.cur_codigo = cur.cur_codigo 
                    AND mac.maa_codigo IN (1,2) --matricula_autorizacion 1. Adicion, 2.Normal (Solo cuenta las matriculas 'activas').
            ) TotalMatriculados
        FROM 
            curso cur
        LEFT JOIN plan_academico pla ON pla.pla_codigo = cur.pla_codigo
        INNER JOIN calendario cal ON cal.cal_codigo = cur.cal_codigo
        INNER JOIN sede sed ON sed.sed_codigo = cur.sed_codigo
        INNER JOIN asignatura asi ON asi.asi_codigo = cur.asi_codigo
        INNER JOIN uaa_personal uap ON uap.uap_codigo = cur.uap_codigo
        INNER JOIN persona per ON per.per_codigo = uap.per_codigo
        INNER JOIN uaa ON uaa.uaa_codigo = asi.uaa_codigo
        INNER JOIN vinculacion vin ON vin.vin_codigo = uap.vin_codigo
        INNER JOIN caracter car ON car.car_codigo = asi.car_codigo
        INNER JOIN curso_tipo cut ON cut.cut_codigo = cur.cut_codigo
        WHERE
            cur.cur_codigo = {$CurCodigo}
        ";

        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar el curso {$CurCodigo}.";
            return $this->errorConsultarBd;
        }

        if (count($this->cnx->json) > 0) {
            return array(
                "resultado" => true,
                "mensaje" => "Curso consultado correctamente.",
                "data" => $this->cnx->json
            );
        } else {
            return array(
                "resultado" => false,
                "mensaje" => "No se encontro el curso {$CurCodigo}.",
            );
        }
    }
}
