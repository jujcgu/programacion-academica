<?php

class PermisoCurso
{
    // Fragmento SQL reutilizable: condicion "cur.usu_codigo = X" reconciliando
    // los 5 machetazos conocidos de propietario de curso.
    public function condicionPropietarioSql($uid)
    {
        $uid = intval($uid);
        $condicion = "cur.usu_codigo = {$uid}";

        //Machetazo para los usuarios de licenciatura en lengua castellana por que el secretario oscar creo la mayoria de cursos y renuncio
        if ($uid == 80168) {
            $condicion = "cur.usu_codigo in (80168,125412)";
        }
        //Machetazo similar para programa con nueva secretaria
        if ($uid == 98919) {
            $condicion = "cur.usu_codigo in (87086,98919)";
        }
        //Machetazo similar para convenio de artes, la nueva secretaria debe ver lo que programo la secretaria de artes
        if ($uid == 146777) {
            $condicion = "cur.usu_codigo in (26902,146777)";
        }
        //Machetazo similar para pedagogia infantil, la nueva secretaria debe ver lo que programo la anterior.
        if ($uid == 146232) {
            $condicion = "cur.usu_codigo in (146232,173857)";
        }
        if ($uid == 22735) {
            $condicion = "cur.usu_codigo in (144871,22735)";
        }

        return $condicion;
    }

    // Devuelve el SQL completo (4 ramas UNION) para validar si el usuario logueado
    // puede ver/editar un curso especifico:
    //   1. La asignatura es de una uaa curricular del perfil del usuario.
    //   2. El usuario es el propietario del curso (o cae en un machetazo).
    //   3. El curso esta programado (espacio_ocupacion) en una uaa del perfil.
    //   4. El curso lo creo una Secretaria vinculada a una uaa unificada del perfil.
    // No ejecuta la consulta -- quien la llama la corre con su propia conexion.
    public function construirSqlPermisoCurso($curCodigo, $uaasPerfil, $uid, $grupoSecretaria)
    {
        $curCodigo = intval($curCodigo);
        $grupoSecretaria = intval($grupoSecretaria);
        $condicionPropietario = $this->condicionPropietarioSql($uid);

        return "SELECT asi.asi_codigo AsiCodigo, asi.asi_nombre_corto AsiNombreCorto, cur.cal_codigo CalCodigo
			FROM asignatura asi
			INNER JOIN curso cur ON cur.asi_codigo=asi.asi_codigo
			WHERE cur.cur_codigo= {$curCodigo}
			AND asi.uaa_codigo IN ({$uaasPerfil})
			UNION
			--saca si el curso lo ha creado el usuario
			SELECT asi.asi_codigo AsiCodigo, asi.asi_nombre_corto AsiNombreCorto, cur.cal_codigo CalCodigo
			FROM asignatura asi
			INNER JOIN curso cur ON cur.asi_codigo=asi.asi_codigo
			WHERE cur.cur_codigo= {$curCodigo}
			AND {$condicionPropietario}
			UNION
			--saca si el curso esta programado (espacio_ocupacion) en una uaa del perfil del usuario.
			--UaaCodigo de la asignatura es la uaa curricular/academica y puede diferir de la uaa fisica
			--donde quedo programado el curso (UaaProgramada), por lo que un jefe de programa de la
			--uaa de programacion tambien debe poder modificar el curso aunque no sea su uaa curricular.
			SELECT asi.asi_codigo AsiCodigo, asi.asi_nombre_corto AsiNombreCorto, cur.cal_codigo CalCodigo
			FROM asignatura asi
			INNER JOIN curso cur ON cur.asi_codigo=asi.asi_codigo
			INNER JOIN espacio_ocupacion eo ON eo.eso_actividad=cur.cur_codigo
			WHERE cur.cur_codigo= {$curCodigo}
			AND eo.uaa_codigo IN ({$uaasPerfil})
			UNION
			--saca si el curso lo creo una secretaria vinculada a una uaa (unificada) del perfil del usuario.
			--Esto cubre el caso de un curso que aun no tiene horario programado (sin fila en
			--espacio_ocupacion), creado por una secretaria de una uaa que el jefe de programa supervisa.
			SELECT asi.asi_codigo AsiCodigo, asi.asi_nombre_corto AsiNombreCorto, cur.cal_codigo CalCodigo
			FROM asignatura asi
			INNER JOIN curso cur ON cur.asi_codigo=asi.asi_codigo
			WHERE cur.cur_codigo= {$curCodigo}
			AND cur.usu_codigo IN (
				SELECT DISTINCT usg.usg_usuario
				FROM usuario_grupo usg
				WHERE usg.usg_estado = 1
				AND usg.usg_grupo = {$grupoSecretaria}
				AND usg.usg_uaa IN (
					SELECT pro.uaa_codigo_unificado
					FROM programa pro
					INNER JOIN uaa ON uaa.uaa_codigo = pro.uaa_codigo
					WHERE pro.uaa_codigo IN ({$uaasPerfil})
				)
			)
			";
    }
}
