(function () {
    angular
        .module('sipa')
        .controller('ObscursoController', ObscursoController);

    function ObscursoController($http, $rootScope) {
        var vm = this;
        //Visualizacion
        vm.informacionCurso = 0;
        vm.cargandoHorario = 0;

        //Variables
        vm.CurCodigo = '';
        vm.cursoSeleccionado = {};
        vm.creadorCurso = "";
        vm.listaHorarioCurso = [];
        vm.listaMatriculados = [];
        vm.coordinadorSeleccionado = [];
        vm.busquedaDocente = '';
        vm.listaDocentes = [];
        vm.listaCoincidenciaDocente = 0;
        vm.seccionVinculaciones = 0;
        vm.listaVinculaciones = [];
        vm.vinculacionSeleccionada = [];
        vm.docenteSeleccionado = [];

        //Funciones
        vm.consultarCurso = consultarCurso;
        vm.consultarCreadorCurso = consultarCreadorCurso;
        vm.consultarHorarioCurso = consultarHorarioCurso;
        vm.consultarMatriculadosCurso = consultarMatriculadosCurso;
        vm.actualizarObservacion = actualizarObservacion;
        vm.buscarDocente = buscarDocente;
        vm.consultarVinculacionDocente = consultarVinculacionDocente;
        vm.seleccionarVinculacion = seleccionarVinculacion;
        vm.actualizarCoordinador = actualizarCoordinador;

        function actualizarCoordinador() {
            if (vm.coordinadorSeleccionado.UapCodigo == '') {
                mostrarSweetAlertWarning("Debe seleccionar un docente coordinador.");
                return false;
            }

            mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 2,
                CurCodigo: vm.cursoSeleccionado[0].CurCodigo,
                UapCodigo: vm.coordinadorSeleccionado.UapCodigo
            };

            $http({
                url: "logica/obscurso.php",
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
                    consultarCurso("recargar");
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function seleccionarVinculacion(vinculacion) {
            vm.coordinadorSeleccionado.UapCodigo = vinculacion.UapCodigo;
            vm.coordinadorSeleccionado.PerNombreApellido = vm.docenteSeleccionado.PerNombreApellido;
            vm.coordinadorSeleccionado.VinNombre = vinculacion.VinNombre;
            vm.coordinadorSeleccionado.DedNombre = vinculacion.DedNombre;
            cerrarModal('ModalCoordinador');
        }

        function consultarVinculacionDocente(docente) {
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
            if (vm.busquedaDocente == '') {
                mostrarSweetAlertWarning("Debe ingresar el número del curso.");
                return false;
            }

            vm.listaDocentes = [];
            vm.listaCoincidenciaDocente = 0;
            vm.seccionVinculaciones = 0;
            vm.listaVinculaciones = [];
            vm.vinculacionSeleccionada = [];

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

        function actualizarObservacion() {

            if (vm.cursoSeleccionado[0].CurCodigo.length < 4) {
                mostrarSweetAlertWarning("Debe ingresar el número del curso.");
                return false;
            }
            if (!esEntero(vm.cursoSeleccionado[0].CurCodigo)) {
                mostrarSweetAlertWarning("El curso no debe contener letras ni espacios en blanco.");
                return false;
            }

            mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 1,
                CurCodigo: vm.cursoSeleccionado[0].CurCodigo,
                CurObservaciones: vm.cursoSeleccionado[0].CurObservaciones
            };

            $http({
                url: "logica/obscurso.php",
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
                    consultarCurso("recargar");
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function obtenerCoordiandor() {
            vm.coordinadorSeleccionado = [];
            vm.coordinadorSeleccionado.UapCodigo = vm.cursoSeleccionado[0].UapCodigo;
            vm.coordinadorSeleccionado.VinCodigo = vm.cursoSeleccionado[0].VinCodigo;
            vm.coordinadorSeleccionado.VinNombre = vm.cursoSeleccionado[0].VinNombre;
            vm.coordinadorSeleccionado.DedCodigo = vm.cursoSeleccionado[0].DedCodigo;
            vm.coordinadorSeleccionado.DedNombre = vm.cursoSeleccionado[0].DedNombre;
            vm.coordinadorSeleccionado.PerNombreApellido = vm.cursoSeleccionado[0].PerNombreApellido;
            vm.coordinadorSeleccionado.PerCodigo = vm.cursoSeleccionado[0].PerCodigo;
        }

        function consultarMatriculadosCurso(subgrupo = '00') {
            if (vm.cursoSeleccionado[0].CurCodigo.length < 4) {
                mostrarSweetAlertWarning("Debe ingresar el número del curso.");
                return false;
            }
            if (!esEntero(vm.cursoSeleccionado[0].CurCodigo)) {
                mostrarSweetAlertWarning("El curso no debe contener letras ni espacios en blanco.");
                return false;
            }

            mostrarSweetAlertCargando();
            vm.listaMatriculados = [];

            vm.objeto = {
                accion: 4,
                CurCodigo: vm.cursoSeleccionado[0].CurCodigo,
                SubGrupo: subgrupo
            };

            $http({
                url: "logica/cupocurso.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                swal.closeModal();
                var salida = response.data;
                if (salida["resultado"] == false) {
                    swal.closeModal();
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                }
                else {
                    vm.listaMatriculados = salida.data;
                    swal.closeModal();
                    abrirModal('ModalEstudiantesMatriculados');
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultarHorarioCurso() {
            if (vm.cursoSeleccionado[0].CurCodigo.length < 4) {
                mostrarSweetAlertWarning("Debe ingresar el número del curso.");
                return false;
            }
            if (!esEntero(vm.cursoSeleccionado[0].CurCodigo)) {
                mostrarSweetAlertWarning("El curso no debe contener letras ni espacios en blanco.");
                return false;
            }

            vm.cargandoHorario = 1;
            vm.listaHorarioCurso = [];

            vm.objeto = {
                accion: 1,
                CurCodigo: vm.cursoSeleccionado[0].CurCodigo
            };
            $http({
                url: "logica/curhorario.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                var salida = response.data;
                if (salida["resultado"] == false) {
                    swal.closeModal();
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                    vm.cargandoHorario = 0;
                }
                else {
                    vm.listaHorarioCurso = salida.data;
                    vm.cargandoHorario = 0;
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultarCreadorCurso() {
            if (vm.cursoSeleccionado[0].CurCodigo.length < 4) {
                mostrarSweetAlertWarning("Debe ingresar el número del curso.");
                return false;
            }
            if (!esEntero(vm.cursoSeleccionado[0].CurCodigo)) {
                mostrarSweetAlertWarning("El curso no debe contener letras ni espacios en blanco.");
                return false;
            }

            vm.creadorCurso = "";

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

        function consultarCurso(tipo = "") {
            vm.cursoSeleccionado = {};
            vm.informacionCurso = 0;

            if (vm.CurCodigo.length < 4) {
                mostrarSweetAlertWarning("Debe ingresar el número del curso.");
                return false;
            }
            if (!esEntero(vm.CurCodigo)) {
                mostrarSweetAlertWarning("El curso no debe contener letras ni espacios en blanco.");
                return false;
            }

            if (tipo == "") {
                mostrarSweetAlertCargando();
            }

            vm.objeto = {
                accion: 4,
                CurCodigo: vm.CurCodigo
            };

            $http({
                url: "logica/buscurso.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                if (tipo == "") {
                    swal.closeModal();
                }
                var salida = response.data;
                if (salida["resultado"] == false) {
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                }
                else {
                    if (salida.data[0].CurCodigo === undefined) {
                        mostrarSweetAlertError("No se ha encontrado el curso " + vm.CurCodigo + ". ");
                        return false;
                    }
                    vm.cursoSeleccionado = salida.data;
                    vm.informacionCurso = 1;
                    consultarCreadorCurso();
                    consultarHorarioCurso();
                    obtenerCoordiandor();
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }


        //Funciones de alerta
        vm.mostrarSweetAlertDisabled = mostrarSweetAlertDisabled;
        vm.cerrarModal = cerrarModal;
        vm.abrirModal = abrirModal;

        function abrirModal(modal) {
            $("#" + modal).modal('show');

            // if(modal == 'modalUnidades'){
            //     $()
            // }
        }

        function mostrarSweetAlertDisabled(accion) {
            let mje = "";
            let textBtn = "";
            if (accion == 'actualizar_observacion') {
                mje = "¿Desea actualizar la observación del curso " + vm.cursoSeleccionado[0].CurCodigo + "?";
                textBtn = "Actualizar";
            }

            if (accion == 'actualizar_coordinador') {
                mje = "¿Desea actualizar el coordinador del curso " + vm.cursoSeleccionado[0].CurCodigo + "?";
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
                    if (accion == 'actualizar_observacion') {
                        actualizarObservacion();
                    }
                    if (accion == 'actualizar_coordinador') {
                        actualizarCoordinador();
                    }
                }
            });
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
