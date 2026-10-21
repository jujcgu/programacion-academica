(function () {
    angular
        .module('sipa')
        .controller('SireaController', SireaController);

    function SireaController($http, $rootScope) {
        var vm = this;
        //Visualizacion
        vm.cargaPlanAcademico = 0;
        //Variables
        vm.curCodigo = '';
        vm.espCodigo = '';
        vm.cursoSeleccionado = [];
        vm.listaSubGrupos = [];
        vm.sitioRealizacion = [];
        vm.sitiosExternos = [];
        vm.subgrupoSeleccionado = [];
        vm.creadorCurso = '';
        vm.PermitidoEditar = false;
        //Filtros

        //Funciones Declaración
        vm.consultarCurso = consultarCurso;
        vm.consultarSitioRealizacion = consultarSitioRealizacion;
        vm.guardarSitioRealizacion = guardarSitioRealizacion;
        vm.eliminarSitioRealizacion = eliminarSitioRealizacion;
        vm.modalAgregarSitioSubGrupo = modalAgregarSitioSubGrupo;
        vm.guardarSitioSubgrupo = guardarSitioSubgrupo;

        function guardarSitioSubgrupo() {
            if (vm.subgrupoSeleccionado.EspCodigo == '' || vm.subgrupoSeleccionado.EspCodigo == null) {
                mostrarSweetAlertWarning("Debe seleccionar un sitio de realización.");
                return false;
            }

            vm.objeto = {
                accion: 3,
                CurCodigo: vm.subgrupoSeleccionado.CurCodigo,
                EspCodigo: vm.subgrupoSeleccionado.EspCodigo,
                SubGrupo: vm.subgrupoSeleccionado.EsoSubGrupo
            };

            $http({
                url: "logica/sirea.php",
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
                    consultarSubGrupo();
                    $("#ModalAgregarSitioSubGrupo").modal('hide');
                    mostrarSweetAlertSuccess(salida["mensaje"]);
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });

        }

        function modalAgregarSitioSubGrupo(subgrupo) {
            vm.subgrupoSeleccionado = [];
            vm.subgrupoSeleccionado = subgrupo;
            $("#ModalAgregarSitioSubGrupo").modal('show');
        }

        function consultarSubGrupo() {
            if (vm.cursoSeleccionado[0].CurCodigo == '' || vm.cursoSeleccionado[0].CurCodigo == null) {
                mostrarSweetAlertWarning("Debe realizar la busqueda de un curso.");
                return false;
            }

            vm.objeto = {
                accion: 5,
                CurCodigo: vm.cursoSeleccionado[0].CurCodigo
            };

            $http({
                url: "logica/sirea.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                var salida = response.data;
                if (salida["resultado"] == false) {
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                }
                else {
                    vm.listaSubGrupos = salida.data;
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });

        }

        function eliminarSitioRealizacion(Grupo, CodigoSitio) {
            mostrarSweetAlertCargando();
            if (CodigoSitio == '' || CodigoSitio == null) {
                mostrarSweetAlertWarning("Debe existir un sitio de realización ya guardado.");
                return false;
            }

            if (vm.cursoSeleccionado[0].CurCodigo == '' || vm.cursoSeleccionado[0].CurCodigo == null) {
                mostrarSweetAlertWarning("Debe realizar la busqueda de un curso.");
                return false;
            }

            if (Grupo == '' || Grupo == null) {
                mostrarSweetAlertWarning("No se ha cargado el subgrupo del curso correctamente.");
                return false;
            }

            vm.objeto = {
                accion: 4,
                CurCodigo: vm.cursoSeleccionado[0].CurCodigo,
                SubGrupo: Grupo,
                CieCodigo: CodigoSitio
            };

            $http({
                url: "logica/sirea.php",
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
                    consultarSitioRealizacion();
                    consultarSubGrupo();
                    mostrarSweetAlertSuccess(salida["mensaje"]);
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function guardarSitioRealizacion(Grupo) {
            mostrarSweetAlertCargando();
            if (vm.espCodigo == '' || vm.espCodigo == null) {
                mostrarSweetAlertWarning("Debe seleccionar un sitio externo de realización.");
                return false;
            }

            if (vm.cursoSeleccionado[0].CurCodigo == '' || vm.cursoSeleccionado[0].CurCodigo == null) {
                mostrarSweetAlertWarning("Debe realizar la busqueda de un curso.");
                return false;
            }

            if (Grupo == '' || Grupo == null) {
                mostrarSweetAlertWarning("No se ha cargado el subgrupo del curso correctamente.");
                return false;
            }

            vm.objeto = {
                accion: 3,
                CurCodigo: vm.cursoSeleccionado[0].CurCodigo,
                EspCodigo: vm.espCodigo,
                SubGrupo: Grupo
            };

            $http({
                url: "logica/sirea.php",
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
                    consultarSitioRealizacion();
                    mostrarSweetAlertSuccess(salida["mensaje"]);
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultarSitiosExternos() {
            vm.sitiosExternos = [];
            vm.objeto = {
                accion: 2
            };
            $http({
                url: "logica/sirea.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                var salida = response.data;
                if (salida["resultado"] == false) {
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                }
                else {
                    vm.sitiosExternos = salida.data;
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultarSitioRealizacion() {
            vm.sitioRealizacion = [];
            if (!esEntero(vm.cursoSeleccionado[0].CurCodigo)) {
                mostrarSweetAlertWarning("El curso no debe contener letras ni espacios en blanco.");
                return false;
            }
            if (vm.cursoSeleccionado[0].CurCodigo == '') {
                mostrarSweetAlertWarning("Debe ingresar el codigo del curso.");
                return false;
            }
            if (vm.cursoSeleccionado[0].CurCodigo.length < 4) {
                mostrarSweetAlertWarning("Codigo del curso no valido.");
                return false;
            }

            vm.objeto = {
                accion: 1,
                CurCodigo: vm.cursoSeleccionado[0].CurCodigo
            };
            $http({
                url: "logica/sirea.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                var salida = response.data;
                if (salida["resultado"] == false) {
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                }
                else {
                    vm.sitioRealizacion = salida.data;
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultarCurso() {
            vm.cursoSeleccionado = [];
            vm.sitioRealizacion = [];
            // limpiarCampos();
            mostrarSweetAlertCargando();
            if (!esEntero(vm.curCodigo)) {
                mostrarSweetAlertWarning("El curso no debe contener letras ni espacios en blanco.");
                return false;
            }
            if (vm.curCodigo == '') {
                mostrarSweetAlertWarning("Debe ingresar el codigo del curso.");
                return false;
            }
            if (vm.curCodigo.length < 4) {
                mostrarSweetAlertWarning("Codigo del curso no valido.");
                return false;
            }

            vm.objeto = {
                accion: 1,
                curCodigo: vm.curCodigo
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
                    buscarCreadorCurso();
                    consultarSitiosExternos();
                    consultarSitioRealizacion();
                    consultarSubGrupo();
                    swal.closeModal();
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function buscarCreadorCurso() {
            if (vm.cursoSeleccionado[0].CurCodigo.length < 4) {
                mostrarSweetAlertWarning("Debe ingresar el número del curso.");
                return false;
            }
            if (!esEntero(vm.cursoSeleccionado[0].CurCodigo)) {
                mostrarSweetAlertWarning("El curso no debe contener letras ni espacios en blanco.");
                return false;
            }

            vm.objeto = {
                accion: 5,
                curCodigo: vm.cursoSeleccionado[0].CurCodigo
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

        function mostrarSweetAlertDisabled(accion, grupo, codigo_sitio) {
            let mje = "";
            let textBtn = "";
            if (accion == 'eliminar_sitio') {
                mje = "¿Desea eliminar el sitio de realización del curso <b>" + vm.cursoSeleccionado[0].CurCodigo + "</b> subgrupo <b>" + grupo + "</b>?";
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
                    if (accion == 'eliminar_sitio') {
                        eliminarSitioRealizacion(grupo, codigo_sitio);
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
