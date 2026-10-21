(function () {
    angular
        .module('sipa')
        .controller('CurespController', CurespController);

    function CurespController($http, $rootScope) {
        var vm = this;
        //Visualizacion
        vm.PermitidoEditar = false;
        //Variables
        vm.CurCodigo = '';
        vm.cursoSeleccionado = [];
        vm.listaTipoCurso = [];
        vm.tipoCursoActual = [];
        vm.tipoCursoSeleccionado = '';

        //Filtros

        //Funciones Declaración
        vm.consultarCurso = consultarCurso;
        // vm.guardarTipoCurso = guardarTipoCurso;

        function guardarTipoCurso() {
            //validamos este seleccionado un curso
            if (vm.cursoSeleccionado[0].CurCodigo == '' || vm.cursoSeleccionado[0].CurCodigo == null) {
                mostrarSweetAlertWarning("Debe realizar la busqueda de un curso.");
                return false;
            }

            if (vm.tipoCursoSeleccionado == '' || vm.tipoCursoSeleccionado == null) {
                mostrarSweetAlertWarning("Debe seleccionar un tipo de curso.");
                return false;
            }

            mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 3,
                CurCodigo: vm.cursoSeleccionado[0].CurCodigo,
                CutCodigo: vm.tipoCursoSeleccionado
            };

            $http({
                url: "logica/curesp.php",
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
                    consultarTipoCursoActual();
                    mostrarSweetAlertSuccess(salida["mensaje"]);
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });

        }

        function consultarTipoCursoActual() {
            vm.tipoCursoActual = [];
            vm.tipoCursoSeleccionado = '';

            vm.objeto = {
                accion: 2,
                CurCodigo: vm.cursoSeleccionado[0].CurCodigo
            };
            $http({
                url: "logica/curesp.php",
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
                    vm.tipoCursoActual = salida.data;
                    vm.tipoCursoSeleccionado = vm.tipoCursoActual[0].CutCodigo;

                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultarTipoCurso() {
            vm.listaTipoCurso = [];
            vm.objeto = {
                accion: 1
            };
            $http({
                url: "logica/curesp.php",
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
                    vm.listaTipoCurso = salida.data;
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultarCurso() {
            vm.cursoSeleccionado = [];
            // limpiarCampos();
            mostrarSweetAlertCargando();
            if (!esEntero(vm.CurCodigo)) {
                mostrarSweetAlertWarning("El curso no debe contener letras ni espacios en blanco.");
                return false;
            }
            if (vm.CurCodigo == '') {
                mostrarSweetAlertWarning("Debe ingresar el codigo del curso.");
                return false;
            }
            if (vm.CurCodigo.length < 4) {
                mostrarSweetAlertWarning("Codigo del curso no valido.");
                return false;
            }

            vm.objeto = {
                accion: 1,
                curCodigo: vm.CurCodigo
            };
            $http({
                url: "logica/cupocurso.php",
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
                    vm.cursoSeleccionado = salida.data;
                    vm.PermitidoEditar = salida.PermitidoEditar
                    consultarTipoCurso();
                    consultarTipoCursoActual();
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
