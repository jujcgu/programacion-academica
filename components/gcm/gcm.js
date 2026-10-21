(function () {
    angular
        .module('sipa')
        .controller('GcmController', GcmController);

    function GcmController($http, $timeout) {
        var vm = this;
        //Visualizacion
        vm.seccionInformacionReporte = 0;
        vm.seccionInformacionVerificarCurso = 0;

        //Variables
        vm.listaPeriodos = [];
        vm.listaCalendarios = [];
        vm.calendarioSeleccionado = "";
        vm.listaReporte = [];
        vm.listaEstudiantesMatriculados = [];
        vm.cursoSeleccionado = [];
        vm.nuevaObservacion = "";
        vm.cursoAprobado = null;


        //Filtros
        vm.filter = {
            Curso: '',
        };

        //Funciones Declaración
        vm.consultarPeriodos = consultarPeriodos;
        vm.consultarCalendarios = consultarCalendarios;
        vm.consultarReporte = consultarReporte;
        vm.consultarEstudiantesMatriculados = consultarEstudiantesMatriculados;
        vm.verificarCursos = verificarCursos;
        vm.actualizarObservacion = actualizarObservacion;
        vm.checkLastItem = checkLastItem;

        //Funciones iniciales
        consultarPeriodos();

        //Funciones

        function checkLastItem(isLast) {
            if (isLast) { 
                setTimeout(function() {
                    window.scrollTo({ top: 0, behavior: 'smooth' });
                }, 1000);
            }
        }

        function actualizarObservacion() {
            vm.cursoSeleccionado.nuevaObservacion = vm.nuevaObservacion;
            vm.objeto = {
                accion: 4,
                CursoInfo: vm.cursoSeleccionado,
            };

            mostrarSweetAlertCargando();

            $http({
                url: "logica/mmatriculados.php",
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
                    vm.consultarReporte(salida["mensaje"]);
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function verificarCursos() {
            if (vm.cursoSeleccionado.CurCodigo == '' || vm.cursoSeleccionado.CurCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar un curso especifico para verificar.");
                return false;
            }
            if (vm.listaEstudiantesMatriculados == '' || vm.listaEstudiantesMatriculados === undefined || vm.listaEstudiantesMatriculados.length == 0) {
                mostrarSweetAlertWarning("El curso no cuenta con estudiantes matriculados.");
                return false;
            }

            vm.cursoAprobado = null;

            vm.objeto = {
                accion: 3,
                CursoInfo: vm.cursoSeleccionado,
                EstudiantesInfo: vm.listaEstudiantesMatriculados
            };

            mostrarSweetAlertCargando();

            $http({
                url: "logica/mmatriculados.php",
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
                    vm.listaEstudiantesMatriculados = salida.data;
                    if (salida.CursoAprobado === true) {
                        vm.cursoAprobado = true;
                    } else {
                        vm.cursoAprobado = false;
                    }
                    swal.closeModal();
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultarEstudiantesMatriculados(curso) {
            if (curso == '' || curso === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar un curso especifico para verificar.");
                return false;
            }

            vm.cursoSeleccionado = curso;
            vm.nuevaObservacion = vm.cursoSeleccionado.CurObservaciones
            // vm.seccionInformacionReporte = 0;
            // vm.seccionInformacionVerificarCurso = 0;
            vm.listaEstudiantesMatriculados = [];
            vm.cursoAprobado = null;

            vm.objeto = {
                accion: 2,
                CurCodigo: vm.cursoSeleccionado.CurCodigo
            };

            mostrarSweetAlertCargando();

            $http({
                url: "logica/mmatriculados.php",
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
                    vm.listaEstudiantesMatriculados = salida.data;
                    vm.seccionInformacionReporte = 1;
                    vm.seccionInformacionVerificarCurso = 1;
                    swal.closeModal();
                }
            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultarReporte(mensaje = false) {
            if (vm.calendarioSeleccionado == '' || vm.calendarioSeleccionado === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar un calendario primero.");
                return false;
            }

            vm.seccionInformacionReporte = 0;
            vm.seccionInformacionVerificarCurso = 0;
            vm.listaReporte = [];
            vm.cursoSeleccionado = [];
            vm.cursoAprobado = null;

            vm.objeto = {
                accion: 1,
                CalCodigo: vm.calendarioSeleccionado
            };

            mostrarSweetAlertCargando();

            $http({
                url: "logica/mmatriculados.php",
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
                    vm.listaReporte = salida.data;
                    vm.seccionInformacionReporte = 1;
                    swal.closeModal();
                    if (mensaje !== false) {
                        mostrarSweetAlertSuccess(mensaje);
                    }
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
            if (accion == 'eliminar_horario') {
                mje = "¿Desea eliminar el horario seleccionado?";
                textBtn = "Eliminar";
            }
            if (accion == 'crear_horario') {
                mje = "¿Desea programar el horario seleccionado?";
                textBtn = "Programar";
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
                    if (accion == 'eliminar_horario') {
                        eliminarHorario(parametros);
                    }
                    if (accion == 'crear_horario') {
                        programarHorario(parametros);
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
