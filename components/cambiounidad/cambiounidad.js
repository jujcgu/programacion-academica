(function () {
    angular
        .module('sipa')
        .controller('CambiounidadController', CambiounidadController);

    function CambiounidadController($http, $rootScope) {
        var vm = this;
        //Visualizacion
        vm.sinCalendario = 0;
        //Variables
        vm.CurCodigo = '';
        vm.UaaCodigo = '';
        vm.UaaCodigoNombre = '';
        vm.CursoSeleccionado = {};
        vm.listaHorario = {};
        vm.listaUnidades = {};
        vm.listaHorarioSeleccionado = [];
        vm.PermitidoEditar = false;
        vm.PermitidoProgramar = false;
        vm.creadorCurso = '';

        //Filtro
        vm.UaaFilter = "";


        //Funciones
        vm.consultarCurso = consultarCurso;
        vm.consultarCreadorCurso = consultarCreadorCurso;
        vm.consultarHorario = consultarHorario;
        vm.consultarUnidades = consultarUnidades;
        vm.actualizarAgenda = actualizarAgenda;

        function actualizarAgenda(){
            if (vm.cursoSeleccionado[0].CurCodigo == '' || vm.cursoSeleccionado[0].CurCodigo === undefined) {
                mostrarSweetAlertWarning("No se encontro el codigo del curso seleccionado.");
                return false;
            }

            vm.objeto = {
                accion: 9,
                CurCodigo: vm.cursoSeleccionado[0].CurCodigo
            };

            mostrarSweetAlertCargando();

            $http({
                url: "logica/curhorario.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                // swal.closeModal();
                var salida = response.data;

                if (salida == "true") {
                    swal.closeModal();
                    mostrarSweetAlertSuccess("Agenda actualizada correctamente.");
                }

                if (salida["resultado"] == false) {
                    swal.closeModal();
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function cambiarUnidad(){
            if (vm.cursoSeleccionado[0].CurCodigo == '' || vm.cursoSeleccionado[0].CurCodigo === undefined) {
                mostrarSweetAlertWarning("Debe ingresar el codigo de un curso.");
                return false;
            }
            if (vm.UaaCodigo == '' || vm.UaaCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar una unidad.");
                return false;
            }

            vm.objeto = {
                accion: 1,
                CurCodigo : vm.cursoSeleccionado[0].CurCodigo,
                UaaCodigo : vm.UaaCodigo,
            };

            mostrarSweetAlertCargando();

            $http({
                url: "logica/cambiounidad.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                // swal.closeModal();
                var salida = response.data;

                if (salida["resultado"] == false) {
                    swal.closeModal();
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                }
                if (salida["resultado"] == true) {
                    swal.closeModal();
                    mostrarSweetAlertSuccess(salida["mensaje"]);
                    consultarHorario();
                    actualizarAgenda();
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });            
        }

        function consultarUnidades(){
            vm.listaUnidades = {};

            vm.objeto = {
                accion: 4,
            };

            $http({
                url: "logica/curcrea.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                var salida = response.data;
                if (salida["resultado"] == false) {
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                }
                else {
                    vm.listaUnidades = salida.data;
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultarHorario() {
            vm.listaHorario = {};
            if (vm.CurCodigo.length < 4) {
                mostrarSweetAlertWarning("Debe ingresar el número del curso.");
                return false;
            }
            if (!esEntero(vm.CurCodigo)) {
                mostrarSweetAlertWarning("El curso no debe contener letras ni espacios en blanco.");
                return false;
            }

            vm.objeto = {
                accion: 1,
                CurCodigo: vm.CurCodigo
            };

            $http({
                url: "logica/curhorario.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                var salida = response.data;
                if (salida["resultado"] == false) {
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                }
                else {
                    vm.listaHorario = salida.data;
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultarCreadorCurso() {
            if (vm.CurCodigo.length < 4) {
                mostrarSweetAlertWarning("Debe ingresar el número del curso.");
                return false;
            }
            if (!esEntero(vm.CurCodigo)) {
                mostrarSweetAlertWarning("El curso no debe contener letras ni espacios en blanco.");
                return false;
            }

            vm.objeto = {
                accion: 5,
                curCodigo: vm.CurCodigo
            };

            $http({
                url: "logica/cupocurso.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {

                var salida = response.data;
                if (salida["resultado"] == false) {
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                }
                else {
                    vm.creadorCurso = salida.data;
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultarCurso() {
            if (vm.CurCodigo.length < 4) {
                mostrarSweetAlertWarning("Debe ingresar el número del curso.");
                return false;
            }
            if (!esEntero(vm.CurCodigo)) {
                mostrarSweetAlertWarning("El curso no debe contener letras ni espacios en blanco.");
                return false;
            }

            vm.cursoSeleccionado = {};
            vm.listaHorario = {};
            vm.listaHorarioSeleccionado = [];

            // mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 1,
                curCodigo: vm.CurCodigo
            };

            $http({
                url: "logica/cupocurso.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                swal.closeModal();
                var salida = response.data;
                if (salida["resultado"] == false) {
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                }
                else {
                    vm.cursoSeleccionado = salida.data;
                    vm.PermitidoEditar = salida.PermitidoEditar;
                    vm.PermitidoProgramar = salida.PermitidoProgramar;
                    consultarCreadorCurso();
                    consultarHorario();
                    consultarUnidades();
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }






        //Funciones de modals sweet alert
        vm.mostrarSweetAlertDisabled = mostrarSweetAlertDisabled;
        vm.mostrarSweetAlertCargando = mostrarSweetAlertCargando;
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
            if (accion == 'cambiar_unidad') {
                mje = "¿Desea cambiar el horario por la unidad seleccionada?";
                textBtn = "Actualizar";
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
                    if (accion == 'cambiar_unidad') {
                        cambiarUnidad();
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
