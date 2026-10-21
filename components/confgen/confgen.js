(function () {
    angular
        .module('sipa')
        .controller('ConfgenController', ConfgenController);

    function ConfgenController($http) {
        var vm = this;

        //Variables
        vm.listaTopeHoras = {};

        //Funciones Declaración
        vm.consultarTopeHoras = consultarTopeHoras;
        vm.actualizarTopeHoras = actualizarTopeHoras;

        consultarTopeHoras();

        function consultarTopeHoras() {
            vm.objeto = {
                accion: 1
            };

            $http({
                url: "logica/confgen.php",
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
                    vm.listaTopeHoras.horasCatedraticoSede = salida.horasCatedraticoSede;
                    vm.listaTopeHoras.horasCatedraticoNeiva = salida.horasCatedraticoNeiva;
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function actualizarTopeHoras() {
            if (vm.listaTopeHoras?.horasCatedraticoSede == '' || vm.listaTopeHoras?.horasCatedraticoSede === undefined) {
                mostrarSweetAlertWarning("Ingrese una cantidad valida de tope de horas para catedráticos en las sedes.");
                return false;
            }
            if (vm.listaTopeHoras?.horasCatedraticoSede < 0 || !esEntero(vm.listaTopeHoras?.horasCatedraticoSede)) {
                mostrarSweetAlertWarning("El tope de horas para catedráticos en las sedes debe ser mayor a 0");
                return false;
            }

            if (vm.listaTopeHoras?.horasCatedraticoNeiva == '' || vm.listaTopeHoras?.horasCatedraticoNeiva === undefined) {
                mostrarSweetAlertWarning("Ingrese una cantidad valida de tope de horas para catedráticos en Neiva.");
                return false;
            }
            if (vm.listaTopeHoras?.horasCatedraticoNeiva < 0 || !esEntero(vm.listaTopeHoras?.horasCatedraticoNeiva)) {
                mostrarSweetAlertWarning("El tope de horas para catedráticos en Neiva debe ser mayor a 0");
                return false;
            }

            vm.objeto = {
                accion: 2,
                horasCatedraticoSede: vm.listaTopeHoras.horasCatedraticoSede,
                horasCatedraticoNeiva: vm.listaTopeHoras.horasCatedraticoNeiva
            };

            mostrarSweetAlertCargando();

            $http({
                url: "logica/confgen.php",
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
                    swal.closeModal();
                    mostrarSweetAlertSuccess(salida["mensaje"]);
                    consultarTopeHoras();
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
            if (accion == 'eliminar_curso') {
                mje = "¿Desea eliminar el curso " + vm.cursoSeleccionado[0].CurCodigo + " con todos sus subgrupos?";
                textBtn = "Eliminar";
            }
            if (accion == 'eliminar_subgrupo') {
                mje = "¿Desea eliminar el subgrupo " + parametros.EsoSubgrupo + " del curso " + vm.cursoSeleccionado[0].CurCodigo + " ?";
                textBtn = "Eliminar";
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
                    if (accion == 'eliminar_curso') {
                        eliminarCursoSubgrupo('', 'Curso')
                    }
                    if (accion == 'eliminar_subgrupo') {
                        eliminarCursoSubgrupo(parametros, 'Subgrupo')
                    }

                }
            });
        }

        function mostrarSweetAlertCargando() {
            Swal.fire({
                title: "Procesando",
                text: 'Por favor espere.',
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
