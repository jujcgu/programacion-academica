<?php

class Ceromatriculados
{
    private $cnx;

    public function __construct($conexion = null)
    {
        $this->cnx = $conexion;
    }

    public function consultarReporte($obj)
    {
        $perfil = isset($_SESSION['pacademica']['datosVinculacionUsuario'])
            ? $_SESSION['pacademica']['datosVinculacionUsuario'] : null;
        if (!is_array($perfil)) {
            return array('resultado' => false, 'mensaje' => 'La sesión ha finalizado. Ingrese nuevamente.');
        }
        if (!isset($obj->CalCodigo) || !$this->esCodigoValido($obj->CalCodigo)) {
            return array('resultado' => false, 'mensaje' => 'Debe seleccionar un calendario válido.');
        }

        $calCodigo = (int) $obj->CalCodigo;
        $administrador = isset($perfil['Administrador'])
            && in_array($perfil['Administrador'], array(1, '1'), true);
        $alcance = $administrador ? 'todas' : 'perfil';
        $filtroUnidades = '';

        if (!$administrador) {
            $lista = isset($perfil['unidades']) ? $perfil['unidades'] : '';
            if (!is_string($lista)) {
                return array('resultado' => false, 'mensaje' => 'La lista de UAA del perfil no es válida.');
            }
            if (trim($lista) === '') {
                return array('resultado' => true, 'mensaje' => 'Su perfil no tiene UAA asignadas.', 'data' => array(), 'alcance' => $alcance);
            }
            $unidades = array();
            foreach (explode(',', $lista) as $codigo) {
                $codigo = trim($codigo);
                if (!$this->esCodigoValido($codigo)) {
                    return array('resultado' => false, 'mensaje' => 'La lista de UAA del perfil no es válida.');
                }
                $unidades[] = (int) $codigo;
            }
            // Exclusivamente enteros de la sesión: nunca usar permisos enviados por el cliente.
            $filtroUnidades = 'AND uaa.uaa_codigo IN (' . implode(',', array_unique($unidades)) . ')';
        }

        // Basado en CURSOS_Y_SUBGRUPOS_CERO_MATRICULADOS.md.
        // Se conserva la condición activa de horario propio para cada subgrupo.
        $sql = "SELECT
            CASE WHEN ISNULL(tc.TotalActivos, 0) = 0
                 THEN 'CURSO EN CERO' ELSE 'SUBGRUPO EN CERO' END AS TIPO,
            CONVERT(VARCHAR(10), uaa.uaa_codigo) + '. ' + uaa.uaa_nombre_corto AS UNIDAD,
            cur.cur_codigo AS CURSO,
            cur.cur_grupo AS GRUPO,
            ISNULL(cus.eso_subgrupo, '00') AS SUBGRUPO,
            cur.cur_semanas AS SEMANAS,
            sed.sed_nombre AS SEDE,
            LTRIM(RTRIM(asi.asi_nombre)) + ' ' + LTRIM(RTRIM(ISNULL(asi.asi_nombre_corto, ''))) AS ASIGNATURA,
            COALESCE(NULLIF(LTRIM(RTRIM(ISNULL(per_creador.per_nombre, '') + ' '
                + ISNULL(per_creador.per_apellido, ''))), ''), 'Sin registro') AS USUARIO_CREADOR,
            ISNULL(docentes.Nombres, 'Sin docente registrado en el horario') AS DOCENTES,
            LTRIM(RTRIM(ISNULL(nuc.nuc_nombre, ''))) AS NUCLEO,
            LTRIM(RTRIM(ISNULL(car.car_nombre, ''))) AS CARACTER,
            cur.cur_cupo AS CUPO_CURSO,
            cus.cus_cupo AS CUPO_SUBGRUPO,
            ISNULL(sg.TotalActivos, 0) AS MATRICULADOS_SUBGRUPO,
            ISNULL(tc.TotalActivos, 0) AS MATRICULADOS_CURSO,
            hc.Bloques AS BLOQUES_HORARIO_CURSO,
            hs.Bloques AS BLOQUES_HORARIO_SUBGRUPO,
            cur.cur_observaciones AS OBSERVACIONES
        FROM curso cur WITH (NOLOCK)
        INNER JOIN asignatura asi WITH (NOLOCK) ON asi.asi_codigo = cur.asi_codigo
        INNER JOIN uaa WITH (NOLOCK) ON uaa.uaa_codigo = asi.uaa_codigo
        INNER JOIN sede sed WITH (NOLOCK) ON sed.sed_codigo = cur.sed_codigo
        LEFT JOIN nucleo nuc WITH (NOLOCK) ON nuc.nuc_codigo = asi.nuc_codigo
        LEFT JOIN caracter car WITH (NOLOCK) ON car.car_codigo = asi.car_codigo
        LEFT JOIN curso_cupo_subgrupo cus WITH (NOLOCK)
            ON cus.cur_codigo = cur.cur_codigo AND cus.cus_estado = 1
        OUTER APPLY (
            -- Primer INSERT de auditoría, como consultarCreadorCurso en Cupocurso.
            SELECT TOP 1 aud.usu_codigo
            FROM aud_curso aud WITH (NOLOCK)
            WHERE aud.cur_codigo = cur.cur_codigo AND aud.aud_log_type = 'INSERT'
            ORDER BY aud.aud_changed ASC, aud.usu_codigo ASC
        ) creacion
        LEFT JOIN usuario_general creador WITH (NOLOCK)
            ON creador.uid = COALESCE(creacion.usu_codigo, cur.usu_codigo)
        LEFT JOIN persona per_creador WITH (NOLOCK) ON per_creador.per_codigo = creador.up
        OUTER APPLY (
            -- Agregar docentes evita una fila por bloque horario o por docente.
            SELECT STUFF((
                SELECT '; ' + personas.Nombre
                FROM (
                    SELECT DISTINCT uap_doc.uap_codigo,
                        LTRIM(RTRIM(ISNULL(per_doc.per_nombre, '') + ' ' + ISNULL(per_doc.per_apellido, ''))) AS Nombre
                    FROM espacio_ocupacion_total doc WITH (NOLOCK)
                    INNER JOIN uaa_personal uap_doc WITH (NOLOCK) ON uap_doc.uap_codigo = doc.uap_codigo
                    INNER JOIN persona per_doc WITH (NOLOCK) ON per_doc.per_codigo = uap_doc.per_codigo
                    WHERE doc.eso_actividad = cur.cur_codigo
                      AND (cus.cus_cod IS NULL OR doc.eso_subgrupo = cus.eso_subgrupo)
                ) personas
                ORDER BY personas.Nombre, personas.uap_codigo
                FOR XML PATH(''), TYPE
            ).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS Nombres
        ) docentes
        OUTER APPLY (
            SELECT SUM(CASE WHEN mat.mat_estado = 'A' THEN 1 ELSE 0 END) AS TotalActivos
            FROM matricula_curso mac WITH (NOLOCK)
            INNER JOIN matricula mat WITH (NOLOCK) ON mat.mat_codigo = mac.mat_codigo
            WHERE mac.cur_codigo = cus.cur_codigo
              AND mac.mac_subgrupo = cus.eso_subgrupo
              AND mac.maa_codigo IN (1,2)
        ) sg
        OUTER APPLY (
            SELECT SUM(CASE WHEN mat.mat_estado = 'A' THEN 1 ELSE 0 END) AS TotalActivos
            FROM matricula_curso mac WITH (NOLOCK)
            INNER JOIN matricula mat WITH (NOLOCK) ON mat.mat_codigo = mac.mat_codigo
            WHERE mac.cur_codigo = cur.cur_codigo AND mac.maa_codigo IN (1,2)
        ) tc
        OUTER APPLY (
            SELECT COUNT(*) AS Bloques
            FROM espacio_ocupacion_total eso WITH (NOLOCK)
            WHERE eso.eso_actividad = cur.cur_codigo
        ) hc
        OUTER APPLY (
            SELECT COUNT(*) AS Bloques
            FROM espacio_ocupacion_total eso WITH (NOLOCK)
            WHERE eso.eso_actividad = cus.cur_codigo AND eso.eso_subgrupo = cus.eso_subgrupo
        ) hs
        WHERE cur.cal_codigo = {$calCodigo}
          AND cur.cur_estado = 1
          AND ISNULL(hc.Bloques, 0) > 0
          {$filtroUnidades}
          AND (
              (cus.cus_cod IS NOT NULL AND ISNULL(sg.TotalActivos, 0) = 0)
              OR (cus.cus_cod IS NULL AND ISNULL(tc.TotalActivos, 0) = 0)
          )
          AND (cus.cus_cod IS NULL OR ISNULL(hs.Bloques, 0) > 0)
        ORDER BY TIPO, UNIDAD, ASIGNATURA, cur.cur_grupo, ISNULL(cus.eso_subgrupo, '-')";

        if ($this->cnx === null) {
            require_once __DIR__ . '/../conexion/cls_config.php';
            $this->cnx = new cls_config();
        }
        if (!$this->cnx->consultar($sql)) {
            return array('resultado' => false, 'mensaje' => 'No se pudo consultar el reporte. Intente nuevamente.');
        }

        return array(
            'resultado' => true,
            'mensaje' => 'Reporte consultado correctamente.',
            'data' => is_array($this->cnx->json) ? $this->cnx->json : array(),
            'alcance' => $alcance
        );
    }

    private function esCodigoValido($valor)
    {
        return (is_int($valor) || is_string($valor))
            && preg_match('/^[1-9][0-9]*$/D', (string) $valor)
            && $valor <= 2147483647;
    }
}
