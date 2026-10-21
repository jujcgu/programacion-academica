(function () {
    angular
        .module('sipa')
        .controller('RcurhiController', RcurhiController);

    function RcurhiController($http) {
        var vm = this;

        vm.administrador = 0;
        vm.seccionInformacionReporte = 0;

        vm.listaPeriodos = [];
        vm.listaCalendarios = [];
        vm.listaUsuariosCreadores = [];
        vm.listaUnidadesAcademicas = [];
        vm.periodoSeleccionado = "";
        vm.calendarioSeleccionado = "";
        vm.usuarioCreadorSeleccionado = "";
        vm.unidadAcademicaSeleccionada = "";
        vm.busquedaGeneral = "";
        vm.contenidoReporte = [];
        vm.filasVisibles = [];
        vm.gruposVisibles = [];
        vm.countCursos = 0;

        vm.columnas = [
            { key: 'CurEstado', label: 'ESTADO' },
            { key: 'CurCodigo', label: 'CURSO' },
            { key: 'SubGrupo', label: 'SUBGRUPO' },
            { key: 'AsiNombreCorto', label: 'ASIGNATURA' },
            { key: 'AsiNombre', label: 'NOMBRE' },
            { key: 'CurCupo', label: 'CUPO' },
            { key: 'CurSemanas', label: 'SEMANAS' },
            { key: 'DiaNombre', label: 'DIA' },
            { key: 'Hora', label: 'HORA' },
            { key: 'TicNombre', label: 'MODALIDAD' },
            { key: 'Espacio', label: 'ESPACIO' },
            { key: 'UnidadProgramada', label: 'UNIDAD PROGRAMADA' },
            { key: 'TotalMatriculados', label: 'MATRICULADOS' },
            { key: 'CurObservaciones', label: 'OBSERVACIONES' },
            { key: 'Docente', label: 'DOCENTE' },
            { key: 'VinNombre', label: 'VINCULACIÓN' },
            { key: 'DedNombre', label: 'DEDICACIÓN' }
            , { key: 'UsuarioCreador', label: 'USUARIO CREADOR' }
        ];

        vm.consultarAdministrador = consultarAdministrador;
        vm.consultarPeriodos = consultarPeriodos;
        vm.consultarCalendarios = consultarCalendarios;
        vm.consultarReporte = consultarReporte;
        vm.actualizarVista = actualizarVista;
        vm.copiarReporte = copiarReporte;
        vm.limpiarFiltros = limpiarFiltros;
        vm.valorColumna = valorColumna;

        consultarAdministrador();

        function consultarAdministrador() {
            vm.administrador = 0;

            $http({
                url: "logica/rcurhi.php",
                method: "POST",
                data: { accion: 2 }
            }).then(function (response) {
                vm.administrador = response.data;
                if (vm.administrador == 1) {
                    consultarPeriodos();
                }
            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la pagina");
                console.error(response.data);
            });
        }

        function consultarReporte() {
            if (vm.periodoSeleccionado == '' || vm.periodoSeleccionado === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar un periodo primero.");
                return false;
            }
            if (vm.calendarioSeleccionado == '' || vm.calendarioSeleccionado === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar un calendario primero.");
                return false;
            }

            mostrarSweetAlertCargando();

            vm.seccionInformacionReporte = 0;
            vm.contenidoReporte = [];
            vm.filasVisibles = [];
            vm.gruposVisibles = [];
            vm.listaUsuariosCreadores = [];
            vm.listaUnidadesAcademicas = [];
            vm.usuarioCreadorSeleccionado = "";
            vm.unidadAcademicaSeleccionada = "";
            vm.busquedaGeneral = "";
            vm.countCursos = 0;

            vm.objeto = {
                accion: 1,
                PerCodigo: vm.periodoSeleccionado,
                CalCodigo: vm.calendarioSeleccionado
            };

            $http({
                url: "logica/rcurhi.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                var salida = response.data;
                if (salida["resultado"] == false) {
                    swal.closeModal();
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                }
                else {
                    vm.contenidoReporte = salida.data || [];
                    vm.countCursos = salida.count || vm.contenidoReporte.length;
                    construirListaUsuariosCreadores();
                    construirListaUnidadesAcademicas();
                    actualizarVista();
                    vm.seccionInformacionReporte = 1;
                    swal.closeModal();
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la pagina");
                console.error(response.data);
            });
        }

        function consultarCalendarios() {
            if (vm.periodoSeleccionado == '' || vm.periodoSeleccionado === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar un periodo primero.");
                return false;
            }

            vm.seccionInformacionReporte = 0;
            vm.listaCalendarios = {};
            vm.calendarioSeleccionado = "";
            vm.usuarioCreadorSeleccionado = "";
            vm.unidadAcademicaSeleccionada = "";
            vm.busquedaGeneral = "";
            vm.listaUsuariosCreadores = [];
            vm.listaUnidadesAcademicas = [];
            vm.contenidoReporte = [];
            vm.filasVisibles = [];
            vm.gruposVisibles = [];

            $http({
                url: "logica/buscurso.php",
                method: "POST",
                data: { accion: 2, PerCodigo: vm.periodoSeleccionado }
            }).then(function (response) {
                var salida = response.data;
                if (salida["resultado"] == false) {
                    swal.closeModal();
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                }
                else {
                    vm.listaCalendarios = salida.data;
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la pagina");
                console.error(response.data);
            });
        }

        function consultarPeriodos() {
            vm.seccionInformacionReporte = 0;
            vm.listaPeriodos = [];
            vm.listaCalendarios = [];
            vm.periodoSeleccionado = "";
            vm.calendarioSeleccionado = "";
            vm.usuarioCreadorSeleccionado = "";
            vm.unidadAcademicaSeleccionada = "";
            vm.busquedaGeneral = "";
            vm.listaUsuariosCreadores = [];
            vm.listaUnidadesAcademicas = [];

            $http({
                url: "logica/peraca.php",
                method: "POST",
                data: { accion: 1 }
            }).then(function (response) {
                var salida = response.data;
                if (salida["resultado"] == false) {
                    swal.closeModal();
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                }
                else {
                    vm.listaPeriodos = salida.data;
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la pagina");
                console.error(response.data);
            });
        }

        function construirListaUsuariosCreadores() {
            var usuarios = {};
            vm.contenidoReporte.forEach(function (curso) {
                if (curso.UsuCodigo !== undefined && curso.UsuCodigo !== null && curso.UsuCodigo !== '') {
                    usuarios[curso.UsuCodigo] = {
                        UsuCodigo: curso.UsuCodigo,
                        UsuarioCreador: curso.UsuarioCreador || curso.UsuCodigo,
                        UsuarioCreadorEmail: curso.UsuarioCreadorEmail || ''
                    };
                }
            });

            vm.listaUsuariosCreadores = Object.keys(usuarios).map(function (key) {
                return usuarios[key];
            }).sort(function (a, b) {
                return (a.UsuarioCreador || '').localeCompare(b.UsuarioCreador || '');
            });
        }

        function construirListaUnidadesAcademicas() {
            var unidades = {};
            vm.contenidoReporte.forEach(function (curso) {
                var codigo = curso.UaaCodigo || '';
                var nombre = curso.UaaCodigoNombre || 'Sin unidad';
                var llave = codigo || nombre;

                unidades[llave] = {
                    UaaCodigo: codigo,
                    UaaCodigoNombre: nombre
                };
            });

            vm.listaUnidadesAcademicas = Object.keys(unidades).map(function (key) {
                return unidades[key];
            }).sort(function (a, b) {
                return (a.UaaCodigoNombre || '').localeCompare(b.UaaCodigoNombre || '');
            });
        }

        function actualizarVista() {
            vm.filasVisibles = obtenerFilasVisibles();
            vm.gruposVisibles = obtenerGruposVisibles(vm.filasVisibles);
        }

        function obtenerFilasVisibles() {
            if (!vm.contenidoReporte) {
                return [];
            }

            return vm.contenidoReporte.filter(function (curso) {
                var cumpleUsuario = !vm.usuarioCreadorSeleccionado || String(curso.UsuCodigo) === String(vm.usuarioCreadorSeleccionado);
                var cumpleUnidad = !vm.unidadAcademicaSeleccionada || String(curso.UaaCodigo || curso.UaaCodigoNombre) === String(vm.unidadAcademicaSeleccionada);
                var busqueda = (vm.busquedaGeneral || '').toString().toLowerCase().trim();
                var cumpleBusqueda = !busqueda || vm.columnas.some(function (columna) {
                    return valorColumna(curso, columna.key).toString().toLowerCase().indexOf(busqueda) !== -1;
                });

                return cumpleUsuario && cumpleUnidad && cumpleBusqueda;
            });
        }

        function obtenerGruposVisibles(filas) {
            var grupos = [];
            var indiceGrupo = {};

            (filas || []).forEach(function (curso) {
                var unidad = curso.UaaCodigoNombre || 'Sin unidad';
                if (indiceGrupo[unidad] === undefined) {
                    indiceGrupo[unidad] = grupos.length;
                    grupos.push({
                        unidad: unidad,
                        cursos: [],
                        subtotal: 0
                    });
                }
                grupos[indiceGrupo[unidad]].cursos.push(curso);
                grupos[indiceGrupo[unidad]].subtotal++;
            });

            return grupos;
        }

        function valorColumna(curso, columna) {
            if (!curso) {
                return '';
            }
            if (columna == 'Docente') {
                var identificacion = curso.PerIdentificacion || '';
                var nombre = curso.PerNombreApellido || '';
                return (identificacion ? identificacion + ' - ' : '') + nombre;
            }
            return curso[columna] === undefined || curso[columna] === null ? '' : curso[columna];
        }

        function copiarReporte() {
            var filas = vm.filasVisibles || [];
            var encabezados = vm.columnas.map(function (columna) { return columna.label; }).join('\t');
            var contenido = filas.map(function (curso) {
                return vm.columnas.map(function (columna) {
                    return limpiarTexto(valorColumna(curso, columna.key));
                }).join('\t');
            }).join('\n');
            var texto = encabezados + (contenido ? '\n' + contenido : '');

            copiarTexto(texto);
        }

        function limpiarTexto(valor) {
            return (valor === undefined || valor === null ? '' : valor.toString())
                .replace(/\t/g, ' ')
                .replace(/\r?\n|\r/g, ' ')
                .trim();
        }

        function copiarTexto(texto) {
            if (navigator.clipboard && navigator.clipboard.writeText) {
                navigator.clipboard.writeText(texto).then(function () {
                    mostrarToast('success', 'Informacion copiada correctamente.');
                }, function () {
                    copiarTextoFallback(texto);
                });
                return;
            }

            copiarTextoFallback(texto);
        }

        function copiarTextoFallback(texto) {
            var textarea = document.createElement('textarea');
            textarea.value = texto;
            textarea.style.position = 'fixed';
            textarea.style.left = '-9999px';
            document.body.appendChild(textarea);
            textarea.focus();
            textarea.select();

            if (document.execCommand('copy')) {
                mostrarToast('success', 'Informacion copiada correctamente.');
            } else {
                mostrarToast('error', 'No se pudo copiar la informacion.');
            }

            document.body.removeChild(textarea);
        }

        function limpiarFiltros() {
            vm.usuarioCreadorSeleccionado = "";
            vm.unidadAcademicaSeleccionada = "";
            vm.busquedaGeneral = "";
            actualizarVista();
        }

        function mostrarToast(icono, mensaje) {
            var Toast = Swal.mixin({
                toast: true,
                position: 'top-end',
                showConfirmButton: false,
                timer: 3000
            });
            Toast.fire({
                icon: icono,
                title: mensaje
            });
        }

        function mostrarSweetAlertWarning(mje) {
            var alerta = Swal.fire({
                title: "Atencion",
                html: mje,
                icon: 'warning',
                allowOutsideClick: true,
                allowEscapeKey: true,
                confirmButtonText: 'Cerrar',
                confirmButtonColor: '#8F141B',
                buttonsStyling: true
            });
            if (alerta && typeof alerta.catch === 'function') {
                alerta.catch(swal.noop);
            }
        }

        function mostrarSweetAlertError(mje) {
            var alerta = Swal.fire({
                title: "Error",
                html: mje,
                icon: 'error',
                allowOutsideClick: true,
                allowEscapeKey: true,
                confirmButtonText: 'Cerrar',
                confirmButtonColor: '#8F141B',
                buttonsStyling: true
            });
            if (alerta && typeof alerta.catch === 'function') {
                alerta.catch(swal.noop);
            }
        }

        function mostrarSweetAlertCargando() {
            var alerta = Swal.fire({
                title: "Procesando",
                text: 'Por favor espere...',
                imageUrl: 'dist/img/precarga-usco.gif',
                showConfirmButton: false,
                allowOutsideClick: false,
                allowEscapeKey: false,
            });
            if (alerta && typeof alerta.catch === 'function') {
                alerta.catch(swal.noop);
            }
        }
    }
})();
