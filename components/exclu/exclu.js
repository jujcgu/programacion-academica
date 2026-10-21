(function () {
    angular
        .module('sipa')
        .controller('ExcluController', ExcluController);

    function ExcluController($http, $rootScope) {
        var vm = this;
        //Visualizacion
        vm.cargaPlanAcademico = 0;
        //Variables
        vm.curCodigo = '';
        vm.cursoSeleccionado = [];
        vm.listadoPlanes = [];
        vm.creadorCurso = '';
        vm.PermitidoEditar = false;
        //Filtros
        vm.filterPlan = '';
        //Funciones Declaración
        vm.consultarCurso = consultarCurso;
        vm.consultarExclusividadCurso = consultarExclusividadCurso;
        //Funcionaes Modals

        function agregarExclusividad(plan) {
            mostrarSweetAlertCargando();
            vm.objeto = {
                accion: 2,
                CurCodigo: vm.cursoSeleccionado[0].CurCodigo,
                PlaCodigo: plan.PlaCodigo,
                PlaNombre: plan.PlaNombre
            };

            $http({
                url: "logica/exclu.php",
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
                    mostrarSweetAlertSuccess(salida["mensaje"]);
                    consultarExclusividadCurso();
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function eliminarExclusividad(plan) {
            mostrarSweetAlertCargando();
            vm.objeto = {
                accion: 3,
                CurCodigo: vm.cursoSeleccionado[0].CurCodigo,
                PlaCodigo: plan.PlaCodigo,
                PlaNombre: plan.PlaNombre
            };

            $http({
                url: "logica/exclu.php",
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
                    mostrarSweetAlertSuccess(salida["mensaje"]);
                    consultarExclusividadCurso();
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultarExclusividadCurso() {
            vm.listadoPlanes = [];
            vm.cargaPlanAcademico = 1;

            //mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 1,
                CurCodigo: vm.cursoSeleccionado[0].CurCodigo
            };
            $http({
                url: "logica/exclu.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                vm.cargaPlanAcademico = 0;
                //swal.closeModal();
                var salida = response.data;
                if (salida["resultado"] == false) {
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                }
                else {
                    vm.listadoPlanes = response.data;

                    var cant = vm.listadoPlanes.length;
                    for (var i = 0; i < cant; i++) {
                        if (vm.listadoPlanes[i].tieneExclusividad) {
                            vm.tieneExclusividad = true;
                            break;
                        } else {
                            vm.tieneExclusividad = false;
                        }
                    }//fin for
                }
            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultarCurso() {
            vm.cursoSeleccionado = [];
            vm.listadoPlanes = [];
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
                swal.closeModal();
                var salida = response.data;
                if (salida["resultado"] == false) {
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                }
                else {
                    vm.cursoSeleccionado = salida.data;
                    vm.PermitidoEditar = salida.PermitidoEditar
                    buscarCreadorCurso();
                    consultarExclusividadCurso();
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function buscarCreadorCurso() {
            if (vm.curCodigo.length < 4) {
                mostrarSweetAlertWarning("Debe ingresar el número del curso.");
                return false;
            }
            if (!esEntero(vm.curCodigo)) {
                mostrarSweetAlertWarning("El curso no debe contener letras ni espacios en blanco.");
                return false;
            }

            vm.objeto = {
                accion: 5,
                curCodigo: vm.curCodigo
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
            if (accion == 'eliminar_exclusividad') {
                mje = "¿Desea eliminar la exclusivdad con el plan " + parametros.PlaNombre + " del curso " + vm.cursoSeleccionado[0].curCodigo + "?";
                textBtn = "Eliminar";
            }

            if (accion == 'agregar_exclusividad') {
                mje = "¿Desea asignar la exclusivdad con el plan " + parametros.PlaNombre + " del curso " + vm.cursoSeleccionado[0].curCodigo + "?";
                textBtn = "Asignar";
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
                    if (accion == 'eliminar_exclusividad') {
                        eliminarExclusividad(parametros)
                    }
                    if (accion == 'agregar_exclusividad') {
                        agregarExclusividad(parametros);
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

        function gestionarErrorSesion(respuestaHttp) {

            if (respuestaHttp == '403') {
                var mje = "Sesión Finalizada. Favor ingresar nuevamente";
                var ruta = encodeURI("index.php/paginas/mostrar_error/mostrar?mje=" + mje);
                location.href = ruta;
            } else {
                console.log('Sesion finalizada, pero no entro al 403. responde.data=');
                console.log(respuestaHttp);
            }
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
