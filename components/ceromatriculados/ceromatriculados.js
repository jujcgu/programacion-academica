(function () {
    'use strict';

    angular.module('sipa').controller('CeromatriculadosController', CeromatriculadosController);
    CeromatriculadosController.$inject = ['$http', '$filter', '$rootScope', '$window', '$document'];

    function CeromatriculadosController($http, $filter, $rootScope, $window, $document) {
        var vm = this;
        var version = 0;
        var alertaCarga = null;
        vm.listaPeriodos = [];
        vm.listaCalendarios = [];
        vm.periodoSeleccionado = '';
        vm.calendarioSeleccionado = '';
        vm.cargando = '';
        vm.exportando = false;
        vm.columnas = [
            { campo: 'NUMERO', titulo: '#' },
            { campo: 'TIPO', titulo: 'Tipo' },
            { campo: 'UNIDAD', titulo: 'Unidad académica', ancho: '14rem' },
            { campo: 'CURSO', titulo: 'Curso' },
            //{ campo: 'GRUPO', titulo: 'Grupo' },
            { campo: 'ASIGNATURA', titulo: 'Asignatura', ancho: '18rem' },
            { campo: 'SUBGRUPO', titulo: 'Subgrupo' },
            { campo: 'SEMANAS', titulo: 'Semanas' },
            { campo: 'DOCENTES', titulo: 'Docente(s) del curso/subgrupo', ancho: '20rem' },
            { campo: 'SEDE', titulo: 'Sede' },
            { campo: 'NUCLEO', titulo: 'Núcleo', ancho: '10rem' },
            { campo: 'CARACTER', titulo: 'Carácter', ancho: '10rem' },
            { campo: 'CUPO_CURSO', titulo: 'Cupo curso' },
            { campo: 'CUPO_SUBGRUPO', titulo: 'Cupo subgrupo' },
            { campo: 'MATRICULADOS_SUBGRUPO', titulo: 'Matriculados subgrupo' },
            { campo: 'MATRICULADOS_CURSO', titulo: 'Matriculados curso' },
            //{ campo: 'BLOQUES_HORARIO_CURSO', titulo: 'Bloques horario curso' },
            //{ campo: 'BLOQUES_HORARIO_SUBGRUPO', titulo: 'Bloques horario subgrupo' },
            { campo: 'OBSERVACIONES', titulo: 'Observaciones', ancho: '18rem' },
            { campo: 'USUARIO_CREADOR', titulo: 'Usuario creador', ancho: '18rem' },
        ];
        vm.consultarPeriodos = consultarPeriodos;
        vm.consultarCalendarios = consultarCalendarios;
        vm.consultarReporte = consultarReporte;
        vm.limpiarReporte = limpiarReporte;
        vm.filtrar = filtrar;
        vm.copiarTabla = copiarTabla;
        vm.exportarExcel = exportarExcel;
        // ngNewRouter instancia el controlador antes de crear el scope de la vista.
        vm.deactivate = function () { version++; cerrarCarga(); };
        limpiarReporte();
        consultarPeriodos();

        function limpiarReporte() {
            version++;
            cerrarCarga();
            vm.cargando = '';
            vm.listaReporte = [];
            vm.filasVisibles = [];
            vm.cursosVisibles = 0;
            vm.consultado = false;
            vm.busqueda = '';
            vm.tipo = '';
            vm.error = '';
            vm.aviso = '';
            vm.mensaje = '';
            vm.alcance = '';
        }

        function solicitar(url, datos, carga, completar) {
            var actual = ++version;
            vm.cargando = carga;
            vm.error = '';
            cerrarCarga();
            alertaCarga = $window.Swal.fire({
                title: 'Procesando',
                text: 'Por favor espere...',
                imageUrl: 'dist/img/precarga-usco.gif',
                allowOutsideClick: false,
                allowEscapeKey: false,
                showConfirmButton: false,
                didOpen: function () { $window.Swal.hideLoading(); }
            });
            $http({ url: url, method: 'POST', data: datos }).then(function (response) {
                if (actual !== version) { return; }
                cerrarCarga();
                vm.cargando = '';
                var salida = response.data;
                if (!salida || salida.resultado !== true) {
                    vm.error = (salida && salida.mensaje) || 'No se pudo completar la consulta. Intente nuevamente.';
                    notificar('error', 'No se pudo consultar', vm.error);
                    return;
                }
                completar(salida);
            }, function (response) {
                if (actual !== version) { return; }
                cerrarCarga();
                vm.cargando = '';
                vm.error = response.status === 401
                    ? 'La sesión ha finalizado. Ingrese nuevamente.'
                    : 'No se pudo conectar con el servidor. Intente nuevamente.';
                notificar('error', 'No se pudo consultar', vm.error);
            });
        }

        function consultarPeriodos() {
            limpiarReporte();
            vm.listaPeriodos = [];
            vm.listaCalendarios = [];
            vm.periodoSeleccionado = '';
            vm.calendarioSeleccionado = '';
            solicitar('logica/peraca.php', { accion: 1 }, 'periodos', function (salida) {
                vm.listaPeriodos = Array.isArray(salida.data) ? salida.data : [];
            });
        }

        function consultarCalendarios() {
            limpiarReporte();
            vm.listaCalendarios = [];
            vm.calendarioSeleccionado = '';
            if (!vm.periodoSeleccionado) { return; }
            solicitar('logica/buscurso.php', { accion: 2, PerCodigo: vm.periodoSeleccionado }, 'calendarios', function (salida) {
                vm.listaCalendarios = Array.isArray(salida.data) ? salida.data : [];
            });
        }

        function consultarReporte() {
            limpiarReporte();
            if (!vm.calendarioSeleccionado) {
                vm.error = 'Debe seleccionar un calendario primero.';
                notificar('warning', 'Seleccione un calendario', vm.error);
                return;
            }
            solicitar('logica/ceromatriculados.php', { CalCodigo: vm.calendarioSeleccionado }, 'reporte', function (salida) {
                vm.listaReporte = Array.isArray(salida.data) ? salida.data : [];
                vm.alcance = salida.alcance;
                vm.mensaje = salida.mensaje;
                vm.consultado = true;
                filtrar();
                if (!vm.listaReporte.length) {
                    notificar('info', 'Sin resultados', vm.mensaje === 'Su perfil no tiene UAA asignadas.'
                        ? vm.mensaje : 'No se encontraron cursos ni subgrupos con cero matriculados para esta consulta.');
                }
            });
        }

        function filtrar() {
            vm.aviso = '';
            var filas = vm.listaReporte.filter(function (fila) { return !vm.tipo || fila.TIPO === vm.tipo; });
            vm.filasVisibles = $filter('filter')(filas, vm.busqueda).map(function (fila, indice) {
                // Numerar después de filtrar sin alterar los datos originales del buscador.
                return Object.assign({}, fila, { NUMERO: indice + 1 });
            });
            var cursos = {};
            vm.filasVisibles.forEach(function (fila) { cursos[fila.CURSO] = true; });
            vm.cursosVisibles = Object.keys(cursos).length;
        }

        function copiarTabla() {
            if (!vm.filasVisibles.length) { return; }
            var actual = version;
            var filas = [vm.columnas.map(function (columna) { return columna.titulo; }).join('\t')];
            vm.filasVisibles.forEach(function (fila) {
                filas.push(vm.columnas.map(function (columna) {
                    var valor = fila[columna.campo];
                    return valor === null || valor === undefined ? '' : String(valor).replace(/[\t\r\n]+/g, ' ');
                }).join('\t'));
            });
            var texto = filas.join('\n');
            if ($window.navigator.clipboard && $window.navigator.clipboard.writeText) {
                $window.navigator.clipboard.writeText(texto).then(function () {
                    $rootScope.$evalAsync(function () { if (actual === version) { informarCopia(true); } });
                }, function () {
                    $rootScope.$evalAsync(function () { if (actual === version) { copiarAlternativa(texto); } });
                });
            } else {
                copiarAlternativa(texto);
            }
        }

        function exportarExcel() {
            if (!vm.filasVisibles.length || vm.exportando) { return; }
            vm.exportando = true;
            var ns = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main';
            var relaciones = 'http://schemas.openxmlformats.org/package/2006/relationships';
            var office = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships';
            var numericos = ['NUMERO', 'SEMANAS', 'CUPO_CURSO', 'CUPO_SUBGRUPO', 'MATRICULADOS_SUBGRUPO', 'MATRICULADOS_CURSO'];
            var nombre = 'cero_matriculados_' + vm.calendarioSeleccionado + '.xlsx';

            function xml(valor) {
                return String(valor).replace(/[\x00-\x08\x0B\x0C\x0E-\x1F]/g, '')
                    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
                    .replace(/"/g, '&quot;').replace(/'/g, '&apos;');
            }
            function celda(valor, numerico) {
                if (numerico && valor !== null && valor !== undefined && String(valor).trim() !== '' && isFinite(Number(valor))) {
                    return '<c><v>' + Number(valor) + '</v></c>';
                }
                // inlineStr conserva 00 y evita interpretar el texto como fórmulas.
                return '<c t="inlineStr"><is><t xml:space="preserve">' + xml(valor == null ? '—' : valor) + '</t></is></c>';
            }
            function terminar() {
                $rootScope.$evalAsync(function () { vm.exportando = false; });
            }
            function fallar() {
                terminar();
                notificar('error', 'No se pudo exportar', 'Intente exportar el reporte nuevamente.');
            }
            try {
                var filas = '<row r="1">' + vm.columnas.map(function (columna) {
                    return celda(columna.titulo, false);
                }).join('') + '</row>';
                vm.filasVisibles.forEach(function (fila, indice) {
                    filas += '<row r="' + (indice + 2) + '">' + vm.columnas.map(function (columna) {
                        return celda(fila[columna.campo], numericos.indexOf(columna.campo) !== -1);
                    }).join('') + '</row>';
                });
                var zip = new $window.JSZip();
                zip.file('[Content_Types].xml', '<?xml version="1.0" encoding="UTF-8"?>'
                    + '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
                    + '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
                    + '<Default Extension="xml" ContentType="application/xml"/>'
                    + '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
                    + '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/></Types>');
                zip.file('_rels/.rels', '<Relationships xmlns="' + relaciones + '"><Relationship Id="rId1" Type="' + office + '/officeDocument" Target="xl/workbook.xml"/></Relationships>');
                zip.file('xl/workbook.xml', '<workbook xmlns="' + ns + '" xmlns:r="' + office + '"><sheets><sheet name="Cero matriculados" sheetId="1" r:id="rId1"/></sheets></workbook>');
                zip.file('xl/_rels/workbook.xml.rels', '<Relationships xmlns="' + relaciones + '"><Relationship Id="rId1" Type="' + office + '/worksheet" Target="worksheets/sheet1.xml"/></Relationships>');
                zip.file('xl/worksheets/sheet1.xml', '<worksheet xmlns="' + ns + '"><sheetData>' + filas + '</sheetData></worksheet>');
                return zip.generateAsync({ type: 'blob', mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', compression: 'DEFLATE' }).then(function (blob) {
                    var doc = $document[0];
                    var enlace = doc.createElement('a');
                    var url = $window.URL.createObjectURL(blob);
                    enlace.href = url;
                    enlace.download = nombre;
                    doc.body.appendChild(enlace);
                    try {
                        enlace.click();
                    } finally {
                        doc.body.removeChild(enlace);
                        $window.setTimeout(function () { $window.URL.revokeObjectURL(url); }, 1000);
                    }
                    terminar();
                }).catch(fallar);
            } catch (error) {
                fallar();
            }
        }

        function copiarAlternativa(texto) {
            var doc = $document[0];
            var previo = doc.activeElement;
            var campo = doc.createElement('textarea');
            campo.value = texto;
            campo.setAttribute('readonly', '');
            campo.style.position = 'fixed';
            campo.style.opacity = '0';
            doc.body.appendChild(campo);
            var copiado = false;
            try {
                campo.select();
                copiado = doc.execCommand('copy');
            } catch (error) {
                copiado = false;
            } finally {
                doc.body.removeChild(campo);
                if (previo && previo.focus) { previo.focus(); }
            }
            informarCopia(copiado);
        }

        function cerrarCarga() {
            if (alertaCarga) {
                alertaCarga.close();
                alertaCarga = null;
            }
        }

        function notificar(icono, titulo, mensaje) {
            $window.Swal.fire({
                icon: icono, title: titulo, text: mensaje,
                confirmButtonText: 'Cerrar', confirmButtonColor: '#8F141B'
            });
        }

        function informarCopia(copiado) {
            vm.aviso = copiado ? 'Resultados visibles copiados.' : 'No se pudo copiar. Seleccione y copie la tabla manualmente.';
            if (copiado) {
                $window.Swal.fire({
                    icon: 'success', title: vm.aviso, toast: true, position: 'top-end',
                    showConfirmButton: false, timer: 2500, timerProgressBar: true
                });
            } else {
                notificar('error', 'No se pudo copiar', vm.aviso);
            }
        }
    }
})();
