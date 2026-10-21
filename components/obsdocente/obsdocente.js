(function () {
    angular
        .module('sipa')
        .controller('ObsdocenteController', ObsdocenteController);

    function ObsdocenteController($http, $rootScope) {
        var vm = this;
        //Visualizacion
        vm.sinCalendario = 0;
        vm.informacionDocentes = 0;
        vm.observacionesDocentes = 0;

        //Variables
        vm.periodoSeleccionado = '';
        vm.busquedaDocente = '';
        vm.listaPeriodos = [];
        vm.listaDocentes = [];
        vm.docenteSeleccionado = [];
        vm.observacionDocente = '';

        //Filtros

        //Funciones Declaración
        vm.consultarPeriodos = consultarPeriodos;
        vm.consultarDocentes = consultarDocentes;
        vm.seleccionarDocente = seleccionarDocente;
        vm.actualizarObservacion = actualizarObservacion;

        //Funciones Iniciales
        initial();

        function initial() {
            mostrarSweetAlertCargando();
            consultarPeriodos();
            swal.closeModal();
        }

        function actualizarObservacion() {
            if (!vm.docenteSeleccionado || vm.docenteSeleccionado.UapCodigo == '' || vm.docenteSeleccionado.UapCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar una vinculación del docente.");
                return false;
            }

            mostrarSweetAlertCargando();
            vm.objeto = {
                accion: 4,
                Observacion: vm.observacionDocente,
                PersonaCodigo: vm.docenteSeleccionado.PerCodigo,
                UapCodigo: vm.docenteSeleccionado.UapCodigo,
                PeriodoCodigo: vm.periodoSeleccionado,
            };

            $http({
                url: "logica/obsdocente.php",
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
                    vm.observacionesDocentes = 0;
                    vm.docenteSeleccionado = [];
                    vm.observacionDocente = '';
                    swal.closeModal();
                    mostrarSweetAlertSuccess(salida["mensaje"]);
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function seleccionarDocente(docente) {
            vm.docenteSeleccionado = [];
            vm.docenteSeleccionado = docente;
            vm.observacionDocente = '';
            vm.observacionesDocentes = 0;

            vm.objeto = {
                accion: 3,
                PersonaCodigo: vm.docenteSeleccionado.PerCodigo,
                UapCodigo: vm.docenteSeleccionado.UapCodigo,
                PeriodoCodigo: vm.periodoSeleccionado,
            };

            $http({
                url: "logica/obsdocente.php",
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
                    vm.observacionesDocentes = 1;
                    vm.observacionDocente = salida.data;
                    swal.closeModal();
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultarDocentes() {
            if (vm.periodoSeleccionado == '' || vm.periodoSeleccionado === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar un periodo académico.");
                return false;
            }
            if (vm.busquedaDocente == '' || vm.busquedaDocente === undefined) {
                mostrarSweetAlertWarning("Debe ingresar la cedula, nombre o apellido del docente.");
                return false;
            }

            vm.informacionDocentes = 0;
            vm.observacionesDocentes = 0;
            vm.listaDocentes = [];
            vm.docenteSeleccionado = [];
            vm.observacionDocente = '';

            mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 2,
                PerCodigo: vm.periodoSeleccionado,
                Busqueda: vm.busquedaDocente
            };

            $http({
                url: "logica/obsdocente.php",
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
                    vm.informacionDocentes = 1;
                    vm.listaDocentes = salida.data;
                    swal.closeModal();
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });

        }

        function consultarPeriodos() {
            vm.listaPeriodos = [];
            vm.periodoSeleccionado = '';
            vm.informacionDocentes = 0;
            vm.observacionesDocentes = 0;

            vm.objeto = {
                accion: 1
            };

            $http({
                url: "logica/obsdocente.php",
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
                    vm.listaPeriodos = salida.data;
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }





        //Funciones de modals sweet alert
        vm.mostrarSweetAlertDisabled = mostrarSweetAlertDisabled;
        vm.cerrarModal = cerrarModal;
        vm.abrirModal = abrirModal;

        function abrirModal(modal) {
            $("#" + modal).modal('show');

            // if(modal == 'modalUnidades'){
            //     $()
            // }
        }

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
            if (accion == 'eliminar_horario') {
                mje = "¿Desea eliminar el horario seleccionado?";
                textBtn = "Eliminar";
            }
            if (accion == 'crear_horario') {
                mje = "¿Desea programar el horario seleccionado?";
                textBtn = "Programar";
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
                    if (accion == 'eliminar_horario') {
                        eliminarHorario(parametros);
                    }
                    if (accion == 'crear_horario') {
                        programarHorario(parametros);
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
            numero = parseInt(numero);
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
