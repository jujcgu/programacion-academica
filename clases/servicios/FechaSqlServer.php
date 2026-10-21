<?php

class FechaSqlServer
{
    // Convierte fechas a ISO 8601 (estilo SQL Server 126)
    // Soporta: Y-m-d\TH:i:s, Y-m-d\TH:i:s.v, Y-m-d H:i:s, Y-m-d, d/m/Y H:i:s, d/m/Y
    // y variantes con zona horaria ISO (Z / ±HH:MM)
    public static function normalizarIso8601($fecha, $finDelDia = false)
    {
        if (!isset($fecha)) {
            return false;
        }

        $fecha = trim((string)$fecha);
        if ($fecha === "") {
            return false;
        }

        $tieneHora = preg_match('/\d{1,2}:\d{2}(:\d{2})?/', $fecha) === 1;
        $formatos = array(
            'Y-m-d\\TH:i:s.v',
            'Y-m-d\\TH:i:s.u',
            'Y-m-d\\TH:i:s.v\\Z',
            'Y-m-d\\TH:i:s.u\\Z',
            'Y-m-d\\TH:i:sP',
            'Y-m-d\\TH:i:s.vP',
            'Y-m-d\\TH:i:s.uP',
            'Y-m-d\\TH:i:s',
            'Y-m-d\\TH:i',
            'Y-m-d H:i:s.v',
            'Y-m-d H:i:s.u',
            'Y-m-d H:i:s',
            'Y-m-d H:i',
            'Y-m-d',
            'd/m/Y H:i:s',
            'd/m/Y H:i',
            'd/m/Y'
        );

        $date = false;
        foreach ($formatos as $formato) {
            $date = DateTime::createFromFormat($formato, $fecha);
            if ($date !== false) {
                $errores = DateTime::getLastErrors();
                if (is_array($errores) && ($errores['warning_count'] > 0 || $errores['error_count'] > 0)) {
                    $date = false;
                    continue;
                }
                break;
            }
        }

        // Fallback robusto para variantes ISO no cubiertas por createFromFormat
        if ($date === false) {
            try {
                $date = new DateTime($fecha);
            } catch (Exception $e) {
                $date = false;
            }
        }

        if ($date === false) {
            return false;
        }

        if (!$tieneHora) {
            if ($finDelDia) {
                $date->setTime(23, 59, 59);
            } else {
                $date->setTime(0, 0, 0);
            }
        }

        return $date->format('Y-m-d\\TH:i:s');
    }

    // Retorna expresión SQL segura para datetime2 con estilo ISO 8601 (126)
    public static function toSqlDateTime2($fecha, $finDelDia = false)
    {
        $iso = self::normalizarIso8601($fecha, $finDelDia);
        if ($iso === false) {
            return false;
        }
        return "CONVERT(datetime2, '{$iso}', 126)";
    }

    // Retorna valor listo para INSERT/UPDATE de columnas datetime
    public static function nowIso8601()
    {
        return date('Y-m-d\\TH:i:s');
    }
}
