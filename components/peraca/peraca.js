(function () {
    angular
        .module('sipa')
        .controller('PeracaController', PeracaController);

    function PeracaController($http, $rootScope) {
        var vm = this;

        //Visualizacion
        vm.ListaPeriodos = 1
        vm.CambioFechaPeriodos = 0;

        //Variables
        vm.listaPeriodos = [];
        vm.listaUnidadesPeriodo = [];
        vm.listaUnidades = {};
        vm.listaUnidadesEspeciales = {};
        vm.listaUnidadesSeleccionadas = [];
        vm.crearFechaPeriodo = {
            fechaInicial: "",
            fechaFinal: "",
            periodoCodigo: ""
        };

        //Filtros
        vm.filtroPeriodos = '';
        vm.filtroUaa = '';
        vm.filtroNivelAcademico = '';

        //Funciones Declaración
        vm.cambiarPestana = cambiarPestana;
        vm.listarPeriodosUnidad = listarPeriodosUnidad;
        vm.consultarUnidades = consultarUnidades;
        vm.seleccionarUnidad = seleccionarUnidad;
        vm.rellenarCheck = rellenarCheck;
        vm.seleccionarUnificada = seleccionarUnificada;
        vm.guardarFechasPeriodo = guardarFechasPeriodo;

        //Funciones Modals
        // vm.mdlCambiarCupoSubGrupo = mdlCambiarCupoSubGrupo;

        inicial();

        //Funciones iniciales
        function inicial() {
            consultarPeriodos();
            consultarUnidades();
        }

        function vaciarLista() {
            vm.listaUnidadesSeleccionadas = [];
            vm.crearFechaPeriodo = {
                fechaInicial: "",
                fechaFinal: "",
                periodoCodigo: ""
            };
        }

        function guardarFechasPeriodo() {
            if (vm.listaUnidadesSeleccionadas.length <= 0) {
                mostrarSweetAlertWarning("No se ha seleccionado ninguna unidad.");
                return false;
            }

            if (vm.crearFechaPeriodo.fechaInicial == '') {
                mostrarSweetAlertWarning("Debe ingresar la fecha inicial.");
                return false;
            }

            if (!validateDate(vm.crearFechaPeriodo.fechaInicial)) {
                mostrarSweetAlertWarning("La fecha inicial no tiene formato correcto YYYY-MM-DD.");
                return false;
            }

            if (vm.crearFechaPeriodo.fechaFinal == '') {
                mostrarSweetAlertWarning("Debe ingresar la fecha final.");
                return false;
            }

            if (!validateDate(vm.crearFechaPeriodo.fechaFinal)) {
                mostrarSweetAlertWarning("La fecha final no tiene formato correcto YYYY-MM-DD.");
                return false;
            }

            if (!validateDateFinal(vm.crearFechaPeriodo.fechaInicial, vm.crearFechaPeriodo.fechaFinal)) {
                mostrarSweetAlertWarning("La fecha final no puede ser menor o igual que la fecha inicial.");
                return false;
            }

            if (!esEntero(vm.crearFechaPeriodo.periodoCodigo)) {
                mostrarSweetAlertWarning("El formato del calendario no es valido, por favor recargue la pagina.");
                return false;
            }

            if (vm.crearFechaPeriodo.periodoCodigo == '') {
                mostrarSweetAlertWarning("Debe seleccionar un calendario.");
                return false;
            }

            mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 4,
                UaaSeleccionadas: vm.listaUnidadesSeleccionadas,
                FechaInicial: vm.crearFechaPeriodo.fechaInicial,
                FechaFinal: vm.crearFechaPeriodo.fechaFinal,
                PeriodoCodigo: vm.crearFechaPeriodo.periodoCodigo
            };

            $http({
                url: "logica/peraca.php",
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
                    vaciarLista();
                    mostrarSweetAlertSuccess(salida["mensaje"]);
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultarUnidades() {
            vm.listaUnidades = {};
            vm.listaUnidadesEspeciales = {};

            mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 1
            };

            $http({
                url: "logica/aperfe.php",
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
                    vm.listaUnidades = salida.data;
                    vm.listaUnidadesEspeciales = salida.data2;
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function eliminarPeriodoUnidad(obj) {
            mostrarSweetAlertCargando();
            vm.objeto = {
                accion: 3,
                PeuCodigo: obj.PeuCodigo,
                PerCodigo: obj.PerCodigo,
                UaaCodigo: obj.UaaCodigo
            };

            $http({
                url: "logica/peraca.php",
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
                    listarPeriodosUnidad(obj);
                    mostrarSweetAlertSuccess(salida["mensaje"]);
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function listarPeriodosUnidad(obj) {
            if (obj == null || obj.length == '') {
                return mostrarSweetAlertError('Error al consultar las unidades del periodo seleccionado.');
            }

            vm.listaUnidadesPeriodo = [];

            mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 2,
                PerCodigo: obj.PerCodigo
            };

            $http({
                url: "logica/peraca.php",
                method: "POST",
                data: vm.objeto
            }).then((response) => {
                swal.closeModal();
                var salida = response.data;
                if (salida["resultado"] == false) {
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                }
                else {
                    vm.listaUnidadesPeriodo = salida.data;
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });


        }

        function consultarPeriodos() {
            vm.listaPeriodos = [];

            mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 1
            };

            $http({
                url: "logica/peraca.php",
                method: "POST",
                data: vm.objeto
            }).then((response) => {
                swal.closeModal();
                var salida = response.data;
                if (salida["resultado"] == false) {
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

        function cambiarPestana(pestana) {
            vm.ListaPeriodos = 0
            vm.CambioFechaPeriodos = 0;
            vaciarLista();
            switch (pestana) {
                case 'ListaPeriodos':
                    vm.ListaPeriodos = 1;
                    break;
                case 'CambioFechaPeriodos':
                    vm.CambioFechaPeriodos = 1;
                    break;
                default:
                    console.log('Error');
                    break;
            }
        }

        function seleccionarUnidad(codigoUaa) {
            var check = $(".unidad" + codigoUaa).prop("checked");
            if (check) {
                $(".unidad" + codigoUaa).prop("checked", false);
            } else {
                $(".unidad" + codigoUaa).prop("checked", true);
            }
            recorrerUnidadesSeleccionables();
        }

        function recorrerUnidadesSeleccionables() {
            // vm.listaUnidadesSeleccionadas = [];
            $.each($("input[name='chkUnidad[]']:checked"), function () {
                let uaaCodigo = $(this).val();
                let uaaNombre = $(this).attr("checkUnidadNombre");
                let unidad = [];
                unidad = {
                    "UaaCodigo": uaaCodigo,
                    // "UaaNombre": uaaNombre
                };
                vm.listaUnidadesSeleccionadas.push(unidad);
            });

            $.each($("input[name='chkUnidad[]']:not(:checked"), function () {
                let uaaCodigo = $(this).val();
                vm.listaUnidadesSeleccionadas = vm.listaUnidadesSeleccionadas.filter(function (current) {
                    if(current.UaaCodigo == uaaCodigo){
                        return false;
                    }else{
                        return true;
                    }
                });
            });

            var hash = {};
            vm.listaUnidadesSeleccionadas = vm.listaUnidadesSeleccionadas.filter(function (current) {
                var exists = !hash[current.UaaCodigo];
                hash[current.UaaCodigo] = true;
                return exists;
            });
        }

        function rellenarCheck() {
            vm.listaUnidadesSeleccionadas.forEach(unidad => {
                $(".unidad" + unidad.UaaCodigo).prop("checked", true);
            });
        }

        function seleccionarUnificada(codigoUnificada) {
            $.each($(".unificada" + codigoUnificada), function () {
                var check = $(this).prop("checked");
                if (check) {
                    $(this).prop("checked", false);
                } else {
                    $(this).prop("checked", true);
                }
            });
            recorrerUnidadesSeleccionables();
        }

        function validateDateFinal(date1, date2) {
            try {
                let dateIni = new Date(date1).toISOString();
                let dateEnd = new Date(date2).toISOString();
                if (dateEnd <= dateIni) {
                    return false;
                } else {
                    return true;
                }
            } catch (e) {
                return false;
            }
        }

        function validateDate(date) {
            try {
                new Date(date).toISOString();
                return true;
            } catch (e) {
                return false;
            }
        }



        //Funciones de modals sweet alert
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

        vm.mostrarSweetAlertDisabled = mostrarSweetAlertDisabled;

        function mostrarSweetAlertDisabled(mje, accion, parametros) {
            Swal.fire({
                title: "Aviso",
                html: mje,
                icon: 'info',
                allowOutsideClick: true,
                allowEscapeKey: true,
                confirmButtonText: 'Eliminar',
                confirmButtonColor: '#8F141B',
                showCancelButton: true,
                cancelButtonText: 'Cerrar',
                buttonsStyling: true,
            }).then((result) => {
                if (result.isConfirmed) {
                    if (accion == 'periodo_unidad') {
                        eliminarPeriodoUnidad(parametros);
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