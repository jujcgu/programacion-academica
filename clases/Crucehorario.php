<?php
date_default_timezone_set('America/Bogota');
require_once(dirname(__FILE__) . '/servicios/FechaSqlServer.php');
class Crucehorario
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

    public function consultarCruceHorario($obj)
    {   
        $CurCodigo = $obj->CurCodigo;
        $CurSemanas = $obj->CurSemanas;
        $CurSubgrupo = $obj->CurSubgrupo;
        $FechaInicio = $obj->FechaInicio;
        $FechaFin = $obj->FechaFin;
        $HorasSeleccionadas = is_array($obj->HorasSeleccionadas) ? $obj->HorasSeleccionadas : array();

        $HorasSeleccionadasLimpias = array_values(array_filter($HorasSeleccionadas, function ($h) {
            return is_numeric($h);
        }));

        if (count($HorasSeleccionadasLimpias) <= 0) {
            return array(
                "resultado" => false,
                "mensaje" => "Debe seleccionar horas válidas para comprobar el cruce.",
                "consola" => "HorasSeleccionadas vacío o con valores no numéricos."
            );
        }

        $sqlHorasValues = array();
        foreach ($HorasSeleccionadasLimpias as $hora) {
            $sqlHorasValues[] = "(" . intval($hora) . ")";
        }
        $sqlHorasValues = implode(",", $sqlHorasValues);
        
        // Normalizamos fechas para evitar errores por formato al ejecutar SQL Server.
        $FechaInicioIso = FechaSqlServer::normalizarIso8601($FechaInicio, false);
        $FechaFinIso = FechaSqlServer::normalizarIso8601($FechaFin, false);
        if ($FechaInicioIso === false || $FechaFinIso === false) {
            return array(
                "resultado" => false,
                "mensaje" => "Formato de fecha inválido para validar cruce de horario.",
                "consola" => "No se pudo normalizar FechaInicio ({$FechaInicio}) o FechaFin ({$FechaFin})."
            );
        }

        // SQL usa date (sin hora) para iterar semanas.
        $FechaInicioSqlDate = substr($FechaInicioIso, 0, 10);

        // Día ISO-8601: 1 (Lunes) ... 7 (Domingo).
        $DiaSemana = date("N", strtotime($FechaInicioSqlDate));
        if ($DiaSemana < 1 || $DiaSemana > 7) {
            return array(
                "resultado" => false,
                "mensaje" => "No se pudo determinar el día de la semana para validar cruce.",
                "consola" => "Día calculado inválido ({$DiaSemana}) para FechaInicio {$FechaInicioSqlDate}."
            );
        }
        $sqlSubgrupo = "";
        if(trim($CurSubgrupo)!="00" ){
            $sqlSubgrupo = "and mcu.mac_subgrupo = '{$CurSubgrupo}'";
        }
        
        
        $sql = "SET NOCOUNT ON;
        ------------------------------------
        -- /INICIO/ NUEVAS HORAS QUE SE QUIEREN PROGRAMAR

        -- guarda la fecha cada semana
        declare @fecha date = '{$FechaInicioSqlDate}';

        -- guarda la cantidad de semanas 
        declare @cant_semanas int = {$CurSemanas};

        -- guarda el dia de la semana 
        declare @dia_semana char(1) = '{$DiaSemana}';

        -- guarda un contador para el ciclo while
        declare @contador int = 0;

        -- declara una tabla para guardar las fechas en futuro
        declare @tbl_fechas_futuro table( fecha_futura date );

        insert into @tbl_fechas_futuro ( fecha_futura )
        select @fecha;

        --calcula las fechas en el futuro cada semana hasta la cantidad de semanas
        while ( @contador < (@cant_semanas-1) )
        begin
            
            select @fecha = dateadd (day , 7 ,@fecha);
            
            --calcula la fecha dentro de 7 dias
            insert into @tbl_fechas_futuro ( fecha_futura )
            select @fecha
            
            set @contador = @contador +1;
        end

        --llena una tabla con las horas seleccionadas
        declare @tbl_horas table (hora int);
        insert into @tbl_horas
        values {$sqlHorasValues};


        --llena una tabla con las horas exactas que se quieren programar
        --(ano-mes-dia--dia--hora)
        declare @tbl_fechas_exactas table (fecha_futura date, hora int, fecha_exacta varchar(20) )
        insert into @tbl_fechas_exactas (fecha_futura, hora, fecha_exacta)
        select tff.fecha_futura, tho.hora, 
        convert(varchar(30),tff.fecha_futura)+'--'+@dia_semana+'--'+convert(varchar(30),tho.hora)
        from @tbl_fechas_futuro tff
        cross join @tbl_horas tho

        -- /FIN/ NUEVAS HORAS QUE SE QUIEREN PROGRAMAR
        -----------------------------------------------


        ------------------------------------
        -- /INICIO/ HORAS QUE SE YA TIENEN PROGRAMADAS LOS ESTUDIANTES

        --obtiene los matriculados en el curso seleccionado
        declare @tbl_matriculados table ( mat_codigo varchar(100) )
        insert into @tbl_matriculados
        select mcu.mat_codigo
        from matricula_curso mcu
        inner join matricula mat on (mat.mat_codigo = mcu.mat_codigo)
        where mcu.cur_codigo = {$CurCodigo}
        {$sqlSubgrupo}
        and mcu.maa_codigo in (1,2) and mat.mat_estado='A';

        declare @tbl_horario_matriculados table(fecha varchar(30), est_codigo varchar(40) , cur_codigo int)
        insert into @tbl_horario_matriculados (fecha , est_codigo , cur_codigo )
        select eha.date, eha.est_codigo, eha.cur_codigo
        from @tbl_matriculados tbm
        inner join matricula mat on mat.mat_codigo=tbm.mat_codigo
        inner join estudiante est on est.est_codigo=mat.est_codigo
        inner join estudiante_horario_actual eha on eha.est_codigo=est.est_codigo

        -- /FIN/ HORAS QUE SE YA TIENEN PROGRAMADAS LOS ESTUDIANTES
        ------------------------------------------------

        --select tfe.fecha_futura, tfe.hora, tfe.fecha_exacta,
        --thm.fecha, thm.est_codigo, thm.cur_codigo
        select thm.est_codigo, per.per_nombre, per.per_apellido,
        thm.cur_codigo, asi.asi_nombre
        from @tbl_fechas_exactas tfe
        inner join @tbl_horario_matriculados thm on (thm.fecha=tfe.fecha_exacta)
        inner join estudiante est on thm.est_codigo=est.est_codigo
        inner join persona per on per.per_codigo=est.per_codigo
        inner join curso cur on thm.cur_codigo=cur.cur_codigo
        inner join asignatura asi on asi.asi_codigo=cur.asi_codigo
        group by thm.est_codigo, per.per_nombre, per.per_apellido,
        thm.cur_codigo, asi.asi_nombre
        ";

        //Se verifica que se ejecute la consulta
        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar el cruce de horario.";
            return $this->errorConsultarBd;
        }

        $r_contenido = $this->cnx->json;
        $array_final = array();

        foreach ($r_contenido as $cruce){
            $estudiante = array(
                "EstCodigo"=> $cruce['est_codigo'],
                "CurCodigo"=>$cruce['cur_codigo'],
                "PerNombreApellido"=> $cruce['per_nombre']." ".$cruce['per_apellido'],
                "AsiNombre"=>$cruce['asi_nombre']
            );
            array_push($array_final , $estudiante);
        }

        if(count($array_final) > 0){
            return array(
                "resultado" => false,
                "mensaje"=> "Se encontraron cruce de horarios.",
                "data" => $array_final,
            );
        }else{
            return array(
                "resultado" => true,
                "mensaje"=> "No se encontro cruce de horario."
            );
        }


    }

    public function consultarHoras()
    {
        $sql = "SELECT 
            hora.hra_codigo HraCodigo,
            hora.hra_nombre HraNombre,
            hora.hra_inicio HraInicio,
            hora.hra_fin HraFin
        FROM 
            hora
        ORDER BY 
            hra_codigo ASC
        ";

        //Se verifica que se ejecute la consulta
        if (!$this->cnx->consultar($sql)) {
            $this->errorConsultarBd["consola"] = "Error al consultar las horas.";
            return $this->errorConsultarBd;
        }

        //Se almacenan los registros
        $result = $this->cnx->json;

        return array(
            "resultado" => true,
            "mensaje" => "Horas consultado correctamente.",
            "data" => $result
        );
    }
}
