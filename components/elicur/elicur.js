(function () {
    angular
        .module('sipa')
        .controller('ElicurController', ElicurController);

    function ElicurController($http) {
        var vm = this;
        //Visualizacion
        vm.seccionInformacionCurso = 0;
        vm.seccionEliminacionCurso = 0;
        vm.PermiteEditar = 0;
        vm.Administrador = 0;

        //Variables
        vm.busquedaCurso = '';
        vm.cursoSeleccionado = [];
        vm.listaSubgrupo = {};
        vm.creadorCurso = '';
        vm.listaMatriculados = [];
        vm.listaHorarioCurso = [];
        vm.listaDocentes = [];
        vm.cursoEliminar = [
            Justificacion = ''
        ]

        //Filtros
        vm.filter = {
            Matriculados: '',
            Horario: '',
            Subgrupo: '',
        };

        //Funciones Declaración
        vm.consultarCurso = consultarCurso;
        vm.consultarMatriculadosCurso = consultarMatriculadosCurso;
        vm.eliminarCursoSubgrupo = eliminarCursoSubgrupo;

        function consultarPermisosEliminacion(){
            if (vm.cursoSeleccionado[0].CurCodigo == '' || vm.cursoSeleccionado[0].CurCodigo === undefined) {
                mostrarSweetAlertWarning("Debe ingresar el código del curso.");
                return false;
            }
            vm.objeto = {
                accion: 4,
                CurCodigo: vm.cursoSeleccionado[0].CurCodigo,
                CalCodigo: vm.cursoSeleccionado[0].CalCodigo,
                UsuCodigo: vm.cursoSeleccionado[0].UsuCodigo,
                UaaCodigo: vm.cursoSeleccionado[0].UaaCodigo
            };
            $http({
                url: "logica/elicur.php",
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
                    vm.PermiteEditar = salida["PermiteEditar"];
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function eliminarCursoSubgrupo(subgrupo = '', Tipo) {
            if (Tipo == 'Curso') {
                if (vm.cursoSeleccionado[0].CurCodigo == '' || vm.cursoSeleccionado[0].CurCodigo === undefined) {
                    mostrarSweetAlertWarning("Debe ingresar el código del curso.");
                    return false;
                }
                if (vm.cursoEliminar.Justificacion == '' || vm.cursoEliminar.Justificacion === undefined) {
                    mostrarSweetAlertWarning("Debe ingresar la justificación para eliminar el curso.");
                    return false;
                }
                vm.objeto = {
                    accion: 3,
                    CurCodigo: vm.cursoSeleccionado[0].CurCodigo,
                    CurObservacion: vm.cursoEliminar.Justificacion,
                    Tipo: Tipo
                };
            } 
            
            if (Tipo == 'Subgrupo') {
                if (subgrupo.CurCodigo == '' || subgrupo.CurCodigo === undefined) {
                    mostrarSweetAlertWarning("Debe seleccionar el código del curso del subgrupo.");
                    return false;
                }
                if (subgrupo.EsoSubgrupo == '' || subgrupo.EsoSubgrupo === undefined) {
                    mostrarSweetAlertWarning("Debe seleccionar el subgrupo.");
                    return false;
                }
                if (subgrupo.CusCodigo == '' || subgrupo.CusCodigo === undefined) {
                    mostrarSweetAlertWarning("Debe seleccionar el código del subgrupo.");
                    return false;
                }
                vm.objeto = {
                    accion: 3,
                    CurCodigo: subgrupo.CurCodigo,
                    EsoSubgrupo: subgrupo.EsoSubgrupo,
                    CusCodigo: subgrupo.CusCodigo,
                    Tipo: Tipo
                };
            }

            mostrarSweetAlertCargando();

            $http({
                url: "logica/elicur.php",
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
                    
                    vm.cursoEliminar = [
                        Justificacion = ''
                    ]

                    if (Tipo == "Subgrupo") {
                        consultarSubgrupoCurso();
                    }
                    if (Tipo == "Curso") {
                        consultarCurso("Eliminacion");
                    }
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

        function consultarSubgrupoCurso() {
            if (vm.busquedaCurso.length < 4) {
                mostrarSweetAlertWarning("Debe ingresar el número del curso.");
                return false;
            }
            if (!esEntero(vm.busquedaCurso)) {
                mostrarSweetAlertWarning("El curso no debe contener letras ni espacios en blanco.");
                return false;
            }
            if (vm.busquedaCurso == '' || vm.busquedaCurso === undefined) {
                mostrarSweetAlertWarning("Debe ingresar el código del curso.");
                return false;
            }

            vm.listaSubgrupo = {};

            vm.objeto = {
                accion: 2,
                curCodigo: vm.busquedaCurso
            };

            $http({
                url: "logica/elicur.php",
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

        function consultarCreadorCurso() {
            if (vm.busquedaCurso.length < 4) {
                mostrarSweetAlertWarning("Debe ingresar el número del curso.");
                return false;
            }
            if (!esEntero(vm.busquedaCurso)) {
                mostrarSweetAlertWarning("El curso no debe contener letras ni espacios en blanco.");
                return false;
            }
            if (vm.busquedaCurso == '' || vm.busquedaCurso === undefined) {
                mostrarSweetAlertWarning("Debe ingresar el código del curso.");
                return false;
            }

            vm.objeto = {
                accion: 5,
                curCodigo: vm.busquedaCurso
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
            if (vm.busquedaCurso.length < 4) {
                mostrarSweetAlertWarning("Debe ingresar el número del curso.");
                return false;
            }
            if (!esEntero(vm.busquedaCurso)) {
                mostrarSweetAlertWarning("El curso no debe contener letras ni espacios en blanco.");
                return false;
            }
            if (vm.busquedaCurso == '' || vm.busquedaCurso === undefined) {
                mostrarSweetAlertWarning("Debe ingresar el código del curso.");
                return false;
            }

            vm.seccionInformacionCurso = 0;
            vm.seccionEliminacionCurso = 0;
            vm.cursoSeleccionado = [];

            if (tipo == "") {
                mostrarSweetAlertCargando();
            }

            vm.objeto = {
                accion: 4,
                CurCodigo: vm.busquedaCurso
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
                    vm.cursoSeleccionado = salida.data;
                    if(vm.cursoSeleccionado[0].CalTipo != ''){
                        vm.seccionInformacionCurso = 1;
                        consultarPermisosEliminacion();
                        consultarCreadorCurso();
                        consultarSubgrupoCurso();
                        consultarHorarioCurso();
                        if (tipo == "") {
                            swal.closeModal();
                        }   
                    }else{
                        mostrarSweetAlertWarning("No se encontro el curso.");
                    }
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
