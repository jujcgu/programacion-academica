(function () {
    angular
        .module('sipa')
        .controller('MatcursoController', MatcursoController);

    function MatcursoController($http, $rootScope) {
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
        vm.totalMatriculados = {};

        //Filtros
        vm.filtroEstudiantes = '';

        //Funciones Declaración
        vm.cerrarModal = cerrarModal;
        vm.consultarCurso = consultarCurso;
        vm.consultarCreadorCurso = consultarCreadorCurso;
        vm.consultarSubgrupoCurso = consultarSubgrupoCurso;

        //Funcionaes Modals
        vm.mdlCambiarCupoSubGrupo = mdlCambiarCupoSubGrupo;
        vm.mdlMatriculadosSubgrupo = mdlMatriculadosSubgrupo;
        vm.mdlMatriculadosCurso = mdlMatriculadosCurso;
        vm.consultarTotalMatriculados = consultarTotalMatriculados;

        function consultarTotalMatriculados() {
            
            if (vm.curCodigo.length < 4) {
                mostrarSweetAlertWarning("Debe ingresar el número del curso.");
                return false;
            }
            if (!esEntero(vm.curCodigo)) {
                mostrarSweetAlertWarning("El curso no debe contener letras ni espacios en blanco.");
                return false;
            }

            mostrarSweetAlertCargando();

            vm.totalMatriculados = {};

            vm.objeto = {
                accion: 1,
                CurCodigo: vm.curCodigo
            };

            $http({
                url: "logica/matcurso.php",
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
                    vm.totalMatriculados = salida;
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
                SubGrupo: subgrupo.SubGrupo
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

        function consultarCurso() {
            vm.cursoSeleccionado = {};
            if (vm.curCodigo.length < 4) {
                mostrarSweetAlertWarning("Debe ingresar el número del curso.");
                return false;
            }
            if (!esEntero(vm.curCodigo)) {
                mostrarSweetAlertWarning("El curso no debe contener letras ni espacios en blanco.");
                return false;
            }

            mostrarSweetAlertCargando();

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
                    consultarCreadorCurso();
                    consultarTotalMatriculados();
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
                SubGrupo: subgrupo.SubGrupo
            };
            $("#ModalModificarCupoSubgrupo").modal('show');
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
