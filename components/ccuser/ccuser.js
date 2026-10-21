(function () {
    angular
        .module('sipa')
        .controller('CcuserController', CcuserController);

    function CcuserController($http) {
        var vm = this;
        //Visualizacion
        vm.seccionInformacionReporte = 0;

        //Variables
        vm.listaPeriodos = [];
        vm.listaCalendarios = [];
        vm.periodoSeleccionado = "";
        vm.calendarioSeleccionado = "";
        vm.tipoSeleccionado = "";
        vm.contenidoReporte = [];
        vm.contenidoReporte2 = [];
        vm.countCursos = 0;
        vm.historialCurso = [];
        vm.cursosSinHorarioUsuario = [];
        vm.usuarioSeleccionado = {};

        //Filtros
        vm.filter = {
            Busqueda: '',
        };
        vm.total = {
            TotalCursosCreados: 0,
            TotalCursosEliminados: 0,
            TotalCursosActivos: 0,
            TotalCursosProgramados: 0,
            FaltanPorProgramar: 0,
        };

        //Funciones Declaración
        vm.consultarPeriodos = consultarPeriodos;
        vm.consultarCalendarios = consultarCalendarios;
        vm.consultarReporte = consultarReporte;
        vm.consultarCursosSinHorarioUsuario = consultarCursosSinHorarioUsuario;

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
                accion: 10,
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
                    vm.total.TotalCursosCreados = salida.TotalCursosCreados;
                    vm.total.TotalCursosEliminados = salida.TotalCursosEliminados;
                    vm.total.TotalCursosActivos = salida.TotalCursosActivos;
                    vm.total.TotalCursosProgramados = salida.TotalCursosProgramados;
                    vm.total.FaltanPorProgramar = salida.FaltanPorProgramar;
                    vm.seccionInformacionReporte = 1;
                    swal.closeModal();
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });

        }

        function consultarCursosSinHorarioUsuario(reporte) {
            if (!reporte || reporte.UsuCodigo === '' || reporte.UsuCodigo === undefined) {
                mostrarSweetAlertWarning("No se encontró el usuario del registro.");
                return false;
            }

            if (vm.calendarioSeleccionado == '' || vm.calendarioSeleccionado === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar un calendario primero.");
                return false;
            }

            mostrarSweetAlertCargando();

            vm.cursosSinHorarioUsuario = [];
            vm.usuarioSeleccionado = {
                PerNombre: reporte.PerNombre,
                PerApellido: reporte.PerApellido,
                PerEmail: reporte.PerEmail,
                UsuCodigo: reporte.UsuCodigo
            };

            vm.objeto = {
                accion: 11,
                CalCodigo: vm.calendarioSeleccionado,
                UsuCodigo: reporte.UsuCodigo
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
                    vm.cursosSinHorarioUsuario = salida.data;
                    swal.closeModal();
                    abrirModal('modalCursosSinHorarioUsuario');
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
                text: 'Por favor espere.',
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
