(function () {
    angular
        .module('sipa')
        .controller('VindocenteController', VindocenteController);

    function VindocenteController($http) {
        var vm = this;
        //Visualizacion
        vm.listaCoincidenciaDocente = 0;
        vm.seccionVinculaciones = 0;

        //Variables
        vm.busquedaDocente = '';
        vm.listaDocentes = [];
        vm.listaCursos = [];
        vm.listaVinculaciones = [];
        vm.listaAuditoria = [];
        vm.docenteSeleccionado = [];
        vm.vinculacionSeleccionada = [];

        //Filtros
        vm.filter = {
            Docentes: ''
        };

        //Funciones Declaración
        vm.buscarDocente = buscarDocente;
        vm.consultarVinculacionDocente = consultarVinculacionDocente;
        vm.consultarCursosVinculacion = consultarCursosVinculacion;
        vm.consultarAuditoriaVinculacion = consultarAuditoriaVinculacion;

        function consultarAuditoriaVinculacion(vinculacion){
            vm.listaAuditoria = [];
            vm.vinculacionSeleccionada = vinculacion;

            mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 4,
                UapCodigo: vm.vinculacionSeleccionada.UapCodigo
            };

            $http({
                url: "logica/vindocente.php",
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
                    vm.listaAuditoria = salida.data;
                    swal.closeModal();
                    abrirModal("modalAuditoria");
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultarCursosVinculacion(vinculacion){
            vm.listaCursos = [];
            vm.vinculacionSeleccionada = vinculacion;

            mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 3,
                UapCodigo: vm.vinculacionSeleccionada.UapCodigo
            };

            $http({
                url: "logica/vindocente.php",
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
                    vm.listaCursos = salida.data;
                    swal.closeModal();
                    abrirModal("modalCursos");
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultarVinculacionDocente(docente){
            vm.listaVinculaciones = [];
            vm.vinculacionSeleccionada = [];
            vm.seccionVinculaciones = 0;
            vm.docenteSeleccionado = docente;

            mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 2,
                PerCodigo: vm.docenteSeleccionado.PerCodigo
            };

            $http({
                url: "logica/vindocente.php",
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
                    vm.listaVinculaciones = salida.data;
                    vm.seccionVinculaciones = 1;
                    swal.closeModal();
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function buscarDocente() {
            vm.listaDocentes = [];
            vm.listaCoincidenciaDocente = 0;
            vm.seccionVinculaciones = 0;

            mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 1,
                busquedaDocente: vm.busquedaDocente
            };

            $http({
                url: "logica/vindocente.php",
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
                    vm.listaDocentes = salida.data;
                    vm.listaCoincidenciaDocente = 1;
                    swal.closeModal();
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
