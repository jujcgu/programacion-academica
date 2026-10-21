(function () {
    angular
        .module('sipa')
        .controller('CmshController', CmshController);

    function CmshController($http) {
        var vm = this;
        //Visualizacion
        vm.seccionInformacionReporte = 0;

        //Variables
        vm.listaPeriodos = [];
        vm.listaCalendarios = [];
        vm.periodoSeleccionado = "";
        vm.calendarioSeleccionado = "";
        vm.contenidoReporte = [];
        vm.countCursos = 0;

        //Filtros
        vm.filter = {
            Curso: '',
        };

        //Funciones Declaración
        vm.consultarPeriodos = consultarPeriodos;
        vm.consultarCalendarios = consultarCalendarios;
        vm.consultarReporte = consultarReporte;

        consultarPeriodos();


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

            vm.objeto = {
                accion: 3,
                CalCodigo: vm.calendarioSeleccionado
            };

            $http({
                url: "logica/reportes.php",
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
                    vm.contenidoReporte = salida.data;
                    vm.countCursos = salida.count;
                    vm.seccionInformacionReporte = 1;
                    swal.closeModal();
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
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

            vm.objeto = {
                accion: 2,
                PerCodigo: vm.periodoSeleccionado
            };

            $http({
                url: "logica/buscurso.php",
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
                    vm.listaCalendarios = salida.data;
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultarPeriodos() {
            vm.seccionInformacionReporte = 0;
            vm.listaPeriodos = [];
            vm.listaCalendarios = [];
            vm.periodoSeleccionado = "";
            vm.calendarioSeleccionado = "";

            vm.objeto = {
                accion: 1
            };

            $http({
                url: "logica/peraca.php",
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
                text: 'Por favor espere, este reporte tarda aproximadamente 2 minutos.',
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
