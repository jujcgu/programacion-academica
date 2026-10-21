(function () {
    angular
        .module('sipa')
        .controller('CurproController', CurproController);

    function CurproController($http, $rootScope, $filter) {
        var vm = this;
        //Visualizacion
        vm.contenidoSimple = 0;
        vm.contenidoMatriculados = 0;
        vm.contenidoPrimiparos = 0;
        vm.contenidoPestanas = 0;

        //Variables
        vm.listaCalendario = [];
        vm.listaCursosProgramadosSimple = [];
        vm.listaCursosProgramadosMatriculados = [];
        vm.listaCursosProgramadosPrimiparos = [];
        vm.calendarioSeleccionado = '';
        vm.totalCursos = 0;
        vm.totalMostrado = 0;
        vm.textoBotonSeleccionarTodos = 'Seleccionar todos';

        //Filtros
        vm.filterListaSimple = '';
        vm.filterListaMatriculados = '';
        vm.filterListaPrimiparos = '';

        //Funciones Declaración
        vm.consultarCursosProgramadosSimple = consultarCursosProgramadosSimple;
        vm.consultarCursosProgramadosMatriculados = consultarCursosProgramadosMatriculados;
        vm.consultarCursosProgramadosPrimiparos = consultarCursosProgramadosPrimiparos;
        vm.consultarCursosProgramados = consultarCursosProgramados;
        vm.cambiarPestana = cambiarPestana;
        vm.actualizarEstadoSeleccion = actualizarEstadoSeleccion;
        vm.toggleSeleccionarTodos = toggleSeleccionarTodos;

        //Funciones Iniciales
        consultarCalendario();

        function consultarCursosProgramadosPrimiparos() {
            if (vm.calendarioSeleccionado == '') {
                mostrarSweetAlertWarning("Debe seleccionar un calendario.");
                return false;
            }

            mostrarSweetAlertCargando();
            vm.listaCursosProgramadosPrimiparos = [];
            vm.totalCursos = 0;

            vm.objeto = {
                accion: 4,
                CalCodigo: vm.calendarioSeleccionado
            };

            $http({
                url: "logica/curpro.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                vm.cargaPlanAcademico = 1;
                var salida = response.data;
                if (salida["resultado"] == false) {
                    swal.closeModal();
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                }
                else {
                    vm.contenidoPestanas = 1;
                    vm.listaCursosProgramadosPrimiparos = salida.data;
                    vm.totalCursos = salida.count;
                    swal.closeModal();
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultarCursosProgramadosMatriculados() {
            if (vm.calendarioSeleccionado == '') {
                mostrarSweetAlertWarning("Debe seleccionar un calendario.");
                return false;
            }

            mostrarSweetAlertCargando();
            vm.listaCursosProgramadosMatriculados = [];
            vm.totalCursos = 0;

            vm.objeto = {
                accion: 3,
                CalCodigo: vm.calendarioSeleccionado
            };

            $http({
                url: "logica/curpro.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                vm.cargaPlanAcademico = 1;
                var salida = response.data;
                if (salida["resultado"] == false) {
                    swal.closeModal();
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                }
                else {
                    vm.contenidoPestanas = 1;
                    vm.listaCursosProgramadosMatriculados = salida.data;
                    vm.totalCursos = salida.count;
                    swal.closeModal();
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultarCursosProgramadosSimple() {
            if (vm.calendarioSeleccionado == '') {
                mostrarSweetAlertWarning("Debe seleccionar un calendario.");
                return false;
            }

            mostrarSweetAlertCargando();
            vm.listaCursosProgramadosSimple = [];

            vm.objeto = {
                accion: 2,
                CalCodigo: vm.calendarioSeleccionado
            };

            $http({
                url: "logica/curpro.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                vm.cargaPlanAcademico = 1;
                var salida = response.data;
                if (salida["resultado"] == false) {
                    swal.closeModal();
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                }
                else {
                    vm.contenidoPestanas = 1;
                    vm.listaCursosProgramadosSimple = salida.data || [];
                    vm.totalCursos = salida.count;
                    actualizarEstadoSeleccion();
                    swal.closeModal();
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function actualizarEstadoSeleccion() {
            var lista = vm.listaCursosProgramadosSimple || [];
            var seleccionados = $filter('filter')(lista, { seleccionado: true });
            var visibles = $filter('filter')(lista, vm.filterListaSimple);

            vm.totalMostrado = seleccionados.length > 0 ? seleccionados.length : visibles.length;

            var todasVisiblesSeleccionadas = visibles.length > 0 && visibles.every(function (curso) {
                return curso.seleccionado === true;
            });
            vm.textoBotonSeleccionarTodos = todasVisiblesSeleccionadas ? 'Deseleccionar todos' : 'Seleccionar todos';
        }

        function toggleSeleccionarTodos() {
            var lista = vm.listaCursosProgramadosSimple || [];
            var visibles = $filter('filter')(lista, vm.filterListaSimple);
            var todasSeleccionadas = visibles.length > 0 && visibles.every(function (curso) {
                return curso.seleccionado === true;
            });

            visibles.forEach(function (curso) {
                curso.seleccionado = !todasSeleccionadas;
            });

            actualizarEstadoSeleccion();
        }

        // function consultarCursosProgramadosSimple() {
        //     if (vm.calendarioSeleccionado == '') {
        //         mostrarSweetAlertWarning("Debe seleccionar un calendario.");
        //         return false;
        //     }

        //     mostrarSweetAlertCargando();
        //     vm.listaCursosProgramadosSimple = [];
        //     vm.totalCursos = 0;

        //     vm.objeto = {
        //         accion: 2,
        //         CalCodigo: vm.calendarioSeleccionado
        //     };

        //     $http({
        //         url: "logica/curpro.php",
        //         method: "POST",
        //         data: vm.objeto
        //     }).then(function (response) {
        //         vm.cargaPlanAcademico = 1;
        //         var salida = response.data;
        //         if (salida["resultado"] == false) {
        //             swal.closeModal();
        //             mostrarSweetAlertError(salida["mensaje"]);
        //             console.error(salida["consola"]);
        //         }
        //         else {
        //             vm.contenidoPestanas = 1;
        //             vm.listaCursosProgramadosSimple = salida.data;
        //             vm.totalCursos = salida.count;
        //             swal.closeModal();
        //         }

        //     }, function myError(response) {
        //         swal.closeModal();
        //         mostrarSweetAlertError("Error del servidor, favor recargar la página");
        //         console.error(response.data);
        //     });
        // }

        function consultarCursosProgramados() {
            if (vm.calendarioSeleccionado == '') {
                mostrarSweetAlertWarning("Debe seleccionar un calendario.");
                return false;
            }
            consultarCursosProgramadosSimple();
            vm.contenidoPestanas = 1;
            vm.contenidoSimple = 1;
        }

        function consultarCalendario() {
            vm.listaCalendario = [];
            vm.objeto = {
                accion: 1
            };
            $http({
                url: "logica/curpro.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                vm.cargaPlanAcademico = 1;
                var salida = response.data;
                if (salida["resultado"] == false) {
                    swal.closeModal();
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                }
                else {
                    vm.listaCalendario = salida.data;
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function cambiarPestana(pestana) {
            vm.contenidoSimple = 0;
            vm.contenidoMatriculados = 0;
            vm.contenidoPrimiparos = 0;

            switch (pestana) {
                case 'simple':
                    consultarCursosProgramadosSimple();
                    vm.contenidoSimple = 1;
                    break;
                case 'matriculados':
                    consultarCursosProgramadosMatriculados();
                    vm.contenidoMatriculados = 1;
                    break;
                case 'primiparos':
                    consultarCursosProgramadosPrimiparos();
                    vm.contenidoPrimiparos = 1;
                    break;
                default:
                    console.log('Error');
                    break;
            }
        }

        //Funciones de modals sweet alert
        vm.mostrarSweetAlertDisabled = mostrarSweetAlertDisabled;
        vm.cerrarModal = cerrarModal;

        function mostrarSweetAlertWarning(mje) {
            Swal.fire({
                title: "Atención",
                html: mje,
                icon: 'warning',
                allowOutsideClick: true,
                allowEscapeKey: true,
                confirmButtonText: 'Cerrar',
                confirmButtonColor: '#8F141B',
                buttonsStyling: true
            }).then((result) => {
                if (result.value) {
                    //si se pulsa el boton
                }
            }).catch(swal.noop);
        }

        function mostrarSweetAlertSuccess(mje) {

            Swal.fire({
                title: "Bien",
                html: mje,
                icon: 'success',
                allowOutsideClick: false,
                allowEscapeKey: false,
                confirmButtonText: 'OK',
                confirmButtonColor: '#8F141B',
                buttonsStyling: true
            }).then((result) => {
                if (result.value) {
                    //si se pulsa el boton
                }
            }).catch(swal.noop);
        }

        function mostrarSweetAlertError(mje) {
            Swal.fire({
                title: "Error",
                html: mje,
                icon: 'error',
                allowOutsideClick: true,
                allowEscapeKey: true,
                confirmButtonText: 'Cerrar',
                confirmButtonColor: '#8F141B',
                buttonsStyling: true
            }).then((result) => {
                if (result.value) {
                    //si se pulsa el boton
                }
            }).catch(swal.noop);


        }

        function mostrarSweetAlertDisabled(accion, parametros) {
            let mje = "";
            let textBtn = "";
            if (accion == 'guardar_tipo_curso') {
                mje = "¿Desea guardar el tipo de curso?";
                textBtn = "Guardar";
            }

            Swal.fire({
                title: "Aviso",
                html: mje,
                icon: 'info',
                allowOutsideClick: true,
                allowEscapeKey: true,
                confirmButtonText: textBtn,
                confirmButtonColor: '#8F141B',
                showCancelButton: true,
                cancelButtonText: 'Cerrar',
                buttonsStyling: true,
            }).then((result) => {
                if (result.isConfirmed) {
                    if (accion == 'guardar_tipo_curso') {
                        guardarTipoCurso();
                    }

                }
            });
        }

        function mostrarSweetAlertCargando() {
            Swal.fire({
                title: "Procesando",
                text: 'Por favor espere...',
                imageUrl: 'dist/img/precarga-usco.gif',
                allowOutsideClick: false,
                allowEscapeKey: false,
                showConfirmButton: false,
                didOpen: () => {
                    Swal.hideLoading();
                }
            });
        }

        function esEntero(numero) {
            if (numero % 1 == 0) {
                return true;
            } else {
                return false;
            }
        }

        function cerrarModal(idModal) {
            $("#" + idModal).modal('hide');
        }

    }

})();
