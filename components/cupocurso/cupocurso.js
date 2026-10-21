(function () {
    angular
        .module('sipa')
        .controller('CupocursoController', CupocursoController);

    function CupocursoController($http, $rootScope) {
        var vm = this;
        //Visualizacion
        //Variables
        vm.curCodigo = ''; //Curso Codigo: 164862
        vm.creadorCurso = '';
        vm.cursoSeleccionado = {};
        vm.subGrupoSeleccionado = {};
        vm.listaSubgrupo = {};
        vm.listadoEstudiantesMatriculados = {};
        vm.PermitidoEditar = false;
        vm.gabelaCupoAforo = null; //Se obtiene del backend (Cupocurso::obtenerGabelaCupoAforo)

        //Filtros
        vm.filtroEstudiantes = '';

        //Funciones Declaración
        vm.cerrarModal = cerrarModal;
        vm.consultarCurso = consultarCurso;
        vm.consultarCreadorCurso = consultarCreadorCurso;
        vm.consultarSubgrupoCurso = consultarSubgrupoCurso;
        vm.consultarGabelaCupoAforo = consultarGabelaCupoAforo;
        vm.actualizarCupoSubgrupo = actualizarCupoSubgrupo;
        vm.actualizarCupoCurso = actualizarCupoCurso;
        vm.enteroSeguro = enteroSeguro;
        vm.tieneRestriccionAforoTeoria = tieneRestriccionAforoTeoria;
        vm.obtenerAforoBaseTeoria = obtenerAforoBaseTeoria;
        vm.obtenerLimiteTotalTeoria = obtenerLimiteTotalTeoria;
        vm.obtenerTotalConfigurado = obtenerTotalConfigurado;
        vm.obtenerMaximoCupoRegular = obtenerMaximoCupoRegular;
        vm.obtenerMaximoReserva = obtenerMaximoReserva;
        vm.obtenerDisponibleCupoRegular = obtenerDisponibleCupoRegular;
        vm.obtenerDisponibleReserva = obtenerDisponibleReserva;
        vm.obtenerDisponibleTotal = obtenerDisponibleTotal;

        //Funcionaes Modals
        vm.mdlCambiarCupoSubGrupo = mdlCambiarCupoSubGrupo;
        vm.mdlMatriculadosSubgrupo = mdlMatriculadosSubgrupo;
        vm.mdlMatriculadosCurso = mdlMatriculadosCurso;

        consultarGabelaCupoAforo();

        function consultarGabelaCupoAforo() {
            $http({
                url: "logica/cupocurso.php",
                method: "POST",
                data: { accion: 7 }
            }).then(function (response) {
                var salida = response.data;
                if (salida["resultado"] == true) {
                    vm.gabelaCupoAforo = enteroSeguro(salida.data);
                }
            }, function myError(response) {
                console.error(response.data);
            });
        }

        function enteroSeguro(valor) {
            let numero = parseInt(valor);
            return isNaN(numero) ? 0 : numero;
        }

        function tieneRestriccionAforoTeoria() {
            return vm.cursoSeleccionado && vm.cursoSeleccionado[0] &&
                vm.cursoSeleccionado[0].AforoMaximoTeoria !== null &&
                vm.cursoSeleccionado[0].AforoMaximoTeoria !== undefined &&
                vm.cursoSeleccionado[0].AforoMaximoTeoria !== '';
        }

        function obtenerAforoBaseTeoria() {
            if (!tieneRestriccionAforoTeoria()) {
                return null;
            }
            return enteroSeguro(vm.cursoSeleccionado[0].AforoMaximoTeoria);
        }

        function obtenerLimiteTotalTeoria() {
            if (!tieneRestriccionAforoTeoria()) {
                return null;
            }
            return obtenerAforoBaseTeoria() + vm.gabelaCupoAforo;
        }

        function obtenerTotalConfigurado() {
            if (!vm.cursoSeleccionado || !vm.cursoSeleccionado[0]) {
                return 0;
            }
            return enteroSeguro(vm.cursoSeleccionado[0].CurCupo) + enteroSeguro(vm.cursoSeleccionado[0].CurAmpliacion);
        }

        function obtenerMaximoCupoRegular() {
            if (!tieneRestriccionAforoTeoria()) {
                return null;
            }
            let aforoBase = obtenerAforoBaseTeoria();
            let limiteTotal = obtenerLimiteTotalTeoria();
            let reservaActual = enteroSeguro(vm.cursoSeleccionado[0].CurAmpliacion);
            return Math.max(0, Math.min(aforoBase, limiteTotal - reservaActual));
        }

        function obtenerMaximoReserva() {
            if (!tieneRestriccionAforoTeoria()) {
                return null;
            }
            let limiteTotal = obtenerLimiteTotalTeoria();
            let cupoRegularActual = enteroSeguro(vm.cursoSeleccionado[0].CurCupo);
            return Math.max(0, limiteTotal - cupoRegularActual);
        }

        function obtenerDisponibleCupoRegular() {
            let maximo = obtenerMaximoCupoRegular();
            if (maximo === null) {
                return null;
            }
            return Math.max(0, maximo - enteroSeguro(vm.cursoSeleccionado[0].CurCupo));
        }

        function obtenerDisponibleReserva() {
            let maximo = obtenerMaximoReserva();
            if (maximo === null) {
                return null;
            }
            return Math.max(0, maximo - enteroSeguro(vm.cursoSeleccionado[0].CurAmpliacion));
        }

        function obtenerDisponibleTotal() {
            let limite = obtenerLimiteTotalTeoria();
            if (limite === null) {
                return null;
            }
            return Math.max(0, limite - obtenerTotalConfigurado());
        }

        function actualizarCupoCurso() {
            if (vm.cursoSeleccionado[0].CurCupo.length < 0) {
                mostrarSweetAlertWarning("El cupo total no puede ser menor a 0.");
                return false;
            }
            if (vm.cursoSeleccionado[0].CurAmpliacion.length < 0) {
                mostrarSweetAlertWarning("La reserva no puede ser menor a 0.");
                return false;
            }

            if (!esEntero(vm.cursoSeleccionado[0].CurCupo)) {
                mostrarSweetAlertWarning("El cupo total debe ser un número entero.");
                return false;
            }
            if (!esEntero(vm.cursoSeleccionado[0].CurAmpliacion)) {
                mostrarSweetAlertWarning("La reserva debe ser un número entero.");
                return false;
            }

            if (vm.cursoSeleccionado[0].CurCupo == '') {
                mostrarSweetAlertWarning("Ingresa el cupo total del curso.");
                return false;
            }
            if (vm.cursoSeleccionado[0].CurAmpliacion == '') {
                mostrarSweetAlertWarning("Ingresa la reserva de cupo.");
                return false;
            }

            if (
                vm.cursoSeleccionado[0].AforoMaximoTeoria !== null &&
                vm.cursoSeleccionado[0].AforoMaximoTeoria !== undefined &&
                vm.cursoSeleccionado[0].AforoMaximoTeoria !== ''
            ) {
                let aforoMaximoTeoria = parseInt(vm.cursoSeleccionado[0].AforoMaximoTeoria);
                let limiteConGabela = aforoMaximoTeoria + vm.gabelaCupoAforo;
                let cupoTotal = parseInt(vm.cursoSeleccionado[0].CurCupo);
                let reservaCupo = parseInt(vm.cursoSeleccionado[0].CurAmpliacion);
                let sumaCupos = cupoTotal + reservaCupo;

                if (cupoTotal > aforoMaximoTeoria) {
                    mostrarSweetAlertWarning("El cupo de matrículas regulares no puede superar la capacidad del salón. Capacidad del salón: " + aforoMaximoTeoria + ".");
                    return false;
                }

                if (sumaCupos > limiteConGabela) {
                    mostrarSweetAlertWarning("No se puede guardar el cambio porque el total de cupos supera la capacidad permitida del salón. Capacidad: " + aforoMaximoTeoria + ", máximo permitido con flexibilidad: " + limiteConGabela + ", total ingresado: " + sumaCupos + ".");
                    return false;
                }
            }

            mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 6,
                CurCupo: vm.cursoSeleccionado[0].CurCupo,
                CurAmpliacion: vm.cursoSeleccionado[0].CurAmpliacion,
                CurCodigo: vm.cursoSeleccionado[0].CurCodigo
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
                if (salida["resultado"] == true) {
                    if (salida["CurCupoAplicado"] !== undefined) {
                        vm.cursoSeleccionado[0].CurCupo = salida["CurCupoAplicado"];
                    }
                    if (salida["CurAmpliacionAplicado"] !== undefined) {
                        vm.cursoSeleccionado[0].CurAmpliacion = salida["CurAmpliacionAplicado"];
                    }
                    mostrarSweetAlertSuccess(salida["mensaje"]);
                    consultarCurso(true);
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function mdlMatriculadosCurso() {
            buscarEstudiantesMatriculados();
        }

        function mdlMatriculadosSubgrupo(subgrupo) {
            vm.subGrupoSeleccionado = {};
            vm.filterEstudiantes = '';
            vm.subGrupoSeleccionado = {
                CantMatriculados: subgrupo.CantMatriculados,
                CurCodigo: subgrupo.CurCodigo,
                CusCodigo: subgrupo.CusCodigo,
                CusCupo: subgrupo.CusCupo,
                SubGrupo: subgrupo.SubGrupo,
                AforoMaximoSubgrupo: subgrupo.AforoMaximoSubgrupo
            };
            buscarEstudiantesMatriculados(vm.subGrupoSeleccionado.SubGrupo);
        }

        function buscarEstudiantesMatriculados(subgrupo = '00') {
            mostrarSweetAlertCargando();
            vm.listadoEstudiantesMatriculados = {};
            vm.objeto = {
                accion: 4,
                CurCodigo: vm.cursoSeleccionado[0].CurCodigo,
                SubGrupo: subgrupo,
            };
            $http({
                url: "logica/cupocurso.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                swal.closeModal();
                var salida = response.data;
                if (salida["resultado"] == false) {
                    mostrarSweetAlertWarning(salida["mensaje"]);
                    console.error(salida["consola"]);
                }
                else {
                    vm.listadoEstudiantesMatriculados = salida.data;
                    vm.filtroEstudiantes = '';
                    $("#ModalEstudiantesMatriculados").modal('show');
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultarSubgrupoCurso() {
            vm.listaSubgrupo = {};
            if (vm.curCodigo.length < 4) {
                mostrarSweetAlertWarning("Debe ingresar el número del curso.");
                return false;
            }
            if (!esEntero(vm.curCodigo)) {
                mostrarSweetAlertWarning("El curso no debe contener letras ni espacios en blanco.");
                return false;
            }

            vm.objeto = {
                accion: 3,
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
                    vm.listaSubgrupo = salida.data;
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultarCurso(sinAlertaCarga = false) {
            vm.cursoSeleccionado = {};
            if (vm.curCodigo.length < 4) {
                mostrarSweetAlertWarning("Debe ingresar el número del curso.");
                return false;
            }
            if (!esEntero(vm.curCodigo)) {
                mostrarSweetAlertWarning("El curso no debe contener letras ni espacios en blanco.");
                return false;
            }

            if (!sinAlertaCarga) {
                mostrarSweetAlertCargando();
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
                if (!sinAlertaCarga) {
                    swal.closeModal();
                }
                var salida = response.data;
                if (salida["resultado"] == false) {
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                }
                else {
                    vm.cursoSeleccionado = salida.data;
                    vm.PermitidoEditar = salida.PermitidoEditar
                    consultarCreadorCurso();
                    consultarSubgrupoCurso();
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultarCreadorCurso() {
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

        function mdlCambiarCupoSubGrupo(subgrupo) {
            vm.subGrupoSeleccionado = {};
            vm.subGrupoSeleccionado = {
                CantMatriculados: subgrupo.CantMatriculados,
                CurCodigo: subgrupo.CurCodigo,
                CusCodigo: subgrupo.CusCodigo,
                CusCupo: subgrupo.CusCupo,
                SubGrupo: subgrupo.SubGrupo,
                AforoMaximoSubgrupo: subgrupo.AforoMaximoSubgrupo
            };
            $("#ModalModificarCupoSubgrupo").modal('show');
        }

        function actualizarCupoSubgrupo() {
            if (vm.subGrupoSeleccionado.CusCupo.length < 0) {
                mostrarSweetAlertWarning("El cupo no puede ser menor a 0.");
                return false;
            }
            if (!esEntero(vm.subGrupoSeleccionado.CusCupo)) {
                mostrarSweetAlertWarning("El cupo solo se permiten números.");
                return false;
            }
            if (vm.subGrupoSeleccionado.CusCupo == '') {
                mostrarSweetAlertWarning("Debe ingresar el cupo del subgrupo.");
                return false;
            }

            let aforoMaximoSubgrupo = parseInt(vm.subGrupoSeleccionado.AforoMaximoSubgrupo);
            if (!isNaN(aforoMaximoSubgrupo) && aforoMaximoSubgrupo > 0) {
                if (parseInt(vm.subGrupoSeleccionado.CusCupo) > aforoMaximoSubgrupo) {
                    vm.subGrupoSeleccionado.CusCupo = aforoMaximoSubgrupo;
                    mostrarSweetAlertWarning("Aforo máximo permitido para el subgrupo " + vm.subGrupoSeleccionado.SubGrupo + ": " + aforoMaximoSubgrupo + ". Se ajustó automáticamente el cupo.");
                } else {
                    mostrarSweetAlertWarning("Aforo máximo permitido para el subgrupo " + vm.subGrupoSeleccionado.SubGrupo + ": " + aforoMaximoSubgrupo + ".");
                }
            } else {
                mostrarSweetAlertWarning("No hay espacios con aforo configurado para el subgrupo " + vm.subGrupoSeleccionado.SubGrupo + ".");
            }


            $("#ModalModificarCupoSubgrupo").modal('hide');
            mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 2,
                CusCodigo: vm.subGrupoSeleccionado.CusCodigo,
                CusCupo: vm.subGrupoSeleccionado.CusCupo,
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
                    vm.cursoSeleccionado = {};
                }
                if (salida["resultado"] == true) {
                    if (salida["CusCupoAplicado"] !== undefined) {
                        vm.subGrupoSeleccionado.CusCupo = salida["CusCupoAplicado"];
                    }
                    consultarSubgrupoCurso();
                    mostrarSweetAlertSuccess(salida["mensaje"]);
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }











        //Funciones de alerta
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
