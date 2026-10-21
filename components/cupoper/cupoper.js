(function () {
    angular
        .module('sipa')
        .controller('CupoperController', CupoperController);

    function CupoperController($http, $rootScope) {
        var vm = this;
        //Visualizacion
        //Variables
        vm.curCodigo = '';
        vm.estCodigo = '';
        vm.cupoObservacion = '';
        vm.cupoSubgrupo = '';

        vm.cursoSeleccionado = [];
        vm.creadorCurso = '';
        vm.estudianteSeleccionado = [];
        vm.PermitidoEditar = false;
        vm.listadoEstudiantesCupoPersonalizados = [];
        vm.listadoSubgrupos = [];
        //Filtros
        vm.filterEstudiante = '';
        //Funciones Declaración
        vm.consultarCurso = consultarCurso;
        vm.buscarCreadorCurso = buscarCreadorCurso;
        vm.eliminarCupoPersonalizado = eliminarCupoPersonalizado;
        vm.validarCodigoEstudiante = validarCodigoEstudiante;
        vm.validarAsignacionCupoPersonalizado = validarAsignacionCupoPersonalizado;
        vm.asignarCupoPersonalizado = asignarCupoPersonalizado;
        //Funcionaes Modals

        function limpiarCampos() {
            vm.estCodigo = '';
            vm.cupoObservacion = '';
            vm.cupoSubgrupo = '';
            vm.estudianteSeleccionado = [];
            vm.PermitidoEditar = false;
            vm.listadoSubgrupos = [];
        }

        function asignarCupoPersonalizado() {
            mostrarSweetAlertCargando();
            vm.objeto = {
                accion: 5,
                CurCodigo: vm.cursoSeleccionado[0].CurCodigo,
                EstCodigo: vm.estudianteSeleccionado.datosEstudiante.EstCodigo,
                CurSubgrupo: vm.cupoSubgrupo,
                Observacion: vm.cupoObservacion
            };

            $http({
                url: "logica/cupoper.php",
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
                    limpiarCampos();
                    consultarEstudiantesCupoPersonalizado();
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function validarAsignacionCupoPersonalizado() {
            if (vm.cursoSeleccionado[0].CurCodigo.length < 3) {
                mostrarSweetAlertWarning("No ha seleccionado el curso.");
                return false;
            }
            if (vm.estudianteSeleccionado.datosEstudiante.EstCodigo.length < 3) {
                mostrarSweetAlertWarning("No ha seleccionado el estudiante.");
                return false;
            }
            if (vm.cupoObservacion == undefined || vm.cupoObservacion == "") {
                mostrarSweetAlertWarning("No ha ingresado la observación.");
                return false;
            }
            if (vm.cupoSubgrupo == undefined || vm.cupoSubgrupo.length != 2) {
                mostrarSweetAlertWarning("No ha seleccionado el subgrupo.");
                return false;
            }

            mostrarSweetAlertDisabled('crear_cupo_personalizado', null);
        }

        function validarCodigoEstudiante() {

            if (vm.cursoSeleccionado[0].CurCodigo.length < 4) {
                mostrarSweetAlertWarning("Debe ingresar el número del curso.");
                return false;
            }
            if (!esEntero(vm.cursoSeleccionado[0].CurCodigo)) {
                mostrarSweetAlertWarning("El curso no debe contener letras ni espacios en blanco.");
                return false;
            }

            if (vm.estCodigo == '') {
                mostrarSweetAlertWarning("Debe ingresar el código del estudiante.");
                return false;
            }

            if (!esEntero(vm.estCodigo)) {
                mostrarSweetAlertWarning("El código del estudiante no puede contener letras ni espacios en blanco.");
                return false;
            }

            mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 3,
                CurCodigo: vm.cursoSeleccionado[0].CurCodigo,
                EstCodigo: vm.estCodigo
            };

            $http({
                url: "logica/cupoper.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                swal.closeModal();
                var salida = response.data;

                if (salida["resultado"] == false) {
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                }
                if (salida["resultado"] == true) {
                    vm.estudianteSeleccionado = response.data;
                    consultaSubGrupoCurso();
                    mostrarSweetAlertSuccess(salida["mensaje"]);
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });

        }

        function consultaSubGrupoCurso() {
            vm.cupoObservacion = '';
            vm.cupoSubgrupo = '';
            vm.listadoSubgrupos = [];

            vm.objeto = {
                accion: 4,
                CurCodigo: vm.cursoSeleccionado[0].CurCodigo
            };
            $http({
                url: "logica/cupoper.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                var salida = response.data;
                if (salida["resultado"] == false) {
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                }
                else {
                    vm.listadoSubgrupos = response.data;
                }
            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function eliminarCupoPersonalizado(est) {
            vm.estudianteSeleccionado = est;
            mostrarSweetAlertCargando();
            vm.objeto = {
                accion: 2,
                CuaCodigo: vm.estudianteSeleccionado.CuaCodigo,
                CurCodigo: vm.estudianteSeleccionado.CuaCurso,
                EstCodigo: vm.estudianteSeleccionado.CuaEstudiante
            };

            $http({
                url: "logica/cupoper.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                swal.closeModal();
                var salida = response.data;
                vm.estudianteSeleccionado = [];

                if (salida["resultado"] == false) {
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                }
                if (salida["resultado"] == true) {
                    consultarEstudiantesCupoPersonalizado();
                    mostrarSweetAlertSuccess(salida["mensaje"]);
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

        function consultarCurso() {
            vm.cursoSeleccionado = [];
            limpiarCampos();
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
                    consultarEstudiantesCupoPersonalizado();
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });

        }

        function consultarEstudiantesCupoPersonalizado() {
            vm.listadoEstudiantesCupoPersonalizados = [];
            let CurCodigo = vm.cursoSeleccionado[0].CurCodigo;
            if (!esEntero(CurCodigo)) {
                mostrarSweetAlertWarning("El curso no debe contener letras ni espacios en blanco.");
                return false;
            }
            if (CurCodigo == '') {
                mostrarSweetAlertWarning("Debe ingresar el codigo del curso.");
                return false;
            }
            if (CurCodigo.length < 4) {
                mostrarSweetAlertWarning("Codigo del curso no valido.");
                return false;
            }

            vm.objeto = {
                accion: 1,
                CurCodigo: CurCodigo
            };
            $http({
                url: "logica/cupoper.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                // swal.closeModal();
                var salida = response.data;
                if (salida["resultado"] == false) {
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                }
                else {
                    vm.listadoEstudiantesCupoPersonalizados = salida.data;
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
            if (accion == 'eliminar_cupo_personalizado') {
                mje = "¿Desea eliminar el cupo personalizado para el estudiante " + parametros.PerNombreApellido + " del curso " + vm.cursoSeleccionado[0].CurCodigo + "?";
                textBtn = "Eliminar";
            }

            if (accion == 'crear_cupo_personalizado') {
                mje = "¿Desea asignar el cupo personalizado para el estudiante " + vm.estudianteSeleccionado.datosEstudiante.PerNombreApellido + " del curso " + vm.cursoSeleccionado[0].CurCodigo + " subgrupo " + vm.cupoSubgrupo + "?";
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
                    if (accion == 'eliminar_cupo_personalizado') {
                        eliminarCupoPersonalizado(parametros)
                    }
                    if (accion == 'crear_cupo_personalizado') {
                        asignarCupoPersonalizado();
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
