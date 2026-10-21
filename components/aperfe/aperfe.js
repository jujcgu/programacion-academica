(function () {
    angular
        .module('sipa')
        .controller('AperfeController', AperfeController);

    function AperfeController($http, $rootScope, $timeout) {
        var vm = this;
        //Visualizacion
        vm.listaCalendariosActivos = 1;
        vm.listaCalendariosActivosPeriodo = 0;
        vm.listaCalendariosProgramacion = 0;
        vm.listaCalendariosGestion = 0;
        vm.listaGruposUnidad = 0;
        vm.listaModuloSolicitudes = 0;

        //Variables
        vm.listaTiposSolicitud = [];
        vm.listaAperturaSolicitudesActiva = [];
        vm.nombreUaaSolicitudesActiva = '';
        vm.listaUnidades = {};
        vm.listaUnidadesEspeciales = {};
        vm.listaUnidadesActivas = {};
        vm.listaCalendarios = {};
        vm.listaProcesos = {};
        vm.listaAperturaActiva = [];
        vm.listaAperturaGestionActiva = [];
        vm.nombreUaaAperturaActiva = '';
        vm.listaUnidadesSeleccionadas = [];
        vm.listaUsuariosUnidad = [];
        vm.listaPeriodos = [];
        vm.listaGrupos = [];
        vm.listaUnidadesGrupo = [];
        vm.historialCodigosGrupo = [];
        vm.historialResultadosPeriodo = [];
        vm.historialPeriodoAgrupado = [];
        vm.historialModoBusqueda = 'UNIDAD';
        vm.historialPeriodoSeleccionado = "";
        vm.historialGrupoSeleccionado = "";
        vm.historialTipoSeleccionado = "TODOS";
        vm.historialEstadoSeleccionado = "TODOS";
        vm.grupoSeleccionado = {};
        vm.grupoSeleccionadoApertura = "";
        vm.crearAperturaProaca = {
            fechaInicial: "",
            fechaFinal: "",
            periodoFechaInicial: "",
            periodoFechaFinal: "",
            calendario: "",
            correo: "1",
            procesos: [],
            horaInicial: null,
            horaFinal: null
        };
        vm.crearAperturaGestion = {
            fechaInicial: "",
            fechaFinal: "",
            periodoFechaInicial: "",
            periodoFechaFinal: "",
            calendario: "",
            correo: "1",
            horaInicial: null,
            horaFinal: null
        };
        vm.crearGrupo = {
            nombre: "",
            estado: 1
        };
        vm.crearAperturaSolicitudes = {
            fechaInicial: "",
            fechaFinal: "",
            calendario: "",
            correo: "1",
            tipos: [],
            horaInicial: null,
            horaFinal: null
        };

        //Filtros
        vm.filtroUaa = '';
        vm.filtroProgramacionActiva = '';
        vm.filtroGestionActiva = '';
        vm.filtroNivelAcademico = '';
        vm.filtroPeriodos = '';
        vm.filtroGrupos = '';
        vm.filtroSolicitudesActiva = '';
        vm.filtroHistorialPeriodo = '';

        //Funciones Declaración
        vm.funcionInicial = funcionInicial;
        vm.cambiarPestana = cambiarPestana;
        vm.consultarUnidades = consultarUnidades;
        vm.seleccionarUnidad = seleccionarUnidad;
        vm.seleccionarUnificada = seleccionarUnificada;
        vm.consultarCalendarios = consultarCalendarios;
        vm.rellenarCheck = rellenarCheck;
        vm.guardarApertura = guardarApertura;
        vm.consultarProcesos = consultarProcesos;
        vm.buscarCalendarioUnidad = buscarCalendarioUnidad;
        vm.desactivarProgramacionApertura = desactivarProgramacionApertura;
        vm.consultarUsuarioUnidad = consultarUsuarioUnidad;
        vm.guardarAperturaGestion = guardarAperturaGestion;
        vm.desactivarProgramacionAperturaGestion = desactivarProgramacionAperturaGestion;
        vm.consultarPeriodos = consultarPeriodos;
        vm.listarUnidadesPeriodo = listarUnidadesPeriodo;
        vm.listarGrupos = listarGrupos;
        vm.listarUnidadesGrupo = listarUnidadesGrupo;
        vm.eliminarUnidad = eliminarUnidad;
        vm.modalCrearUnidad = modalCrearUnidad;
        vm.asignarUnidad = asignarUnidad;
        vm.guardarGrupo = guardarGrupo;
        vm.modalCrearGrupo = modalCrearGrupo;
        vm.eliminarGrupo = eliminarGrupo;
        vm.consultarTiposSolicitud = consultarTiposSolicitud;
        vm.guardarAperturaSolicitudes = guardarAperturaSolicitudes;
        vm.buscarCalendarioUnidadSolicitudes = buscarCalendarioUnidadSolicitudes;
        vm.desactivarAperturaSolicitudes = desactivarAperturaSolicitudes;
        vm.cambiarModoHistorial = cambiarModoHistorial;
        vm.actualizarFiltroGrupoHistorial = actualizarFiltroGrupoHistorial;
        vm.buscarHistorialPeriodo = buscarHistorialPeriodo;
        vm.unidadVisibleHistorial = unidadVisibleHistorial;
        vm.filtroAperturaHistorial = filtroAperturaHistorial;
        vm.estadoApertura = estadoApertura;


        //Funcionaes Modals
        // vm.mdlCambiarCupoSubGrupo = mdlCambiarCupoSubGrupo;

        //Funciones iniciales
        funcionInicial();

        function funcionInicial() {
            consultarUnidades();
            consultarCalendarios();
            consultarPeriodos();
            listarGrupos("Inicio");
        }

        function modalCrearGrupo(){
            abrirModal("mdlCrearGrupo");
        }

        function eliminarGrupo(Grupo) {
            mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 16,
                PgrCodigo: Grupo.PgrCodigo
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
                    vm.grupoSeleccionado = {};
                    listarGrupos();
                    mostrarSweetAlertSuccess(salida["mensaje"]);
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function usarArrayGrupo() {
            if (vm.listaUnidadesGrupo.length > 0) {
                vm.listaUnidadesGrupo.forEach(element => {
                    let unidad = [];
                    unidad = {
                        "UaaCodigo": element.UaaCodigo,
                    };
                    vm.listaUnidadesSeleccionadas.push(unidad);
                });
            }
            rellenarCheck();

        }

        function guardarGrupo() {
            mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 15,
                PgrNombre: vm.crearGrupo.nombre,
                PgrEstado: vm.crearGrupo.estado
            };

            $http({
                url: "logica/aperfe.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                swal.closeModal();
                var salida = response.data;
                if (salida["resultado"] == false) {
                    listarGrupos();
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                }
                else {
                    listarGrupos();
                    cerrarModal("mdlCrearGrupo");
                    mostrarSweetAlertSuccess(salida["mensaje"]);
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function asignarUnidad() {

            mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 14,
                PgrCodigo: vm.grupoSeleccionado.PgrCodigo,
                UaaSeleccionada: vm.listaUnidadesSeleccionadas
            };

            $http({
                url: "logica/aperfe.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                swal.closeModal();
                var salida = response.data;
                if (salida["resultado"] == false) {
                    listarUnidadesGrupo(vm.grupoSeleccionado);
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                }
                else {
                    listarUnidadesGrupo(vm.grupoSeleccionado);
                    cerrarModal("mdlCrearUnidad");
                    mostrarSweetAlertSuccess(salida["mensaje"]);
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function modalCrearUnidad(){
            vm.listaUnidadesSeleccionadas = [];
            $.each($("input[name='chkUnidad[]']:checked"), function () {
                $(this).prop("checked", false);
            });
            abrirModal("mdlCrearUnidad");
        }

        function eliminarUnidad(Unidad){

            mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 13,
                GuiCodigo: Unidad.GuiCodigo
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
                    listarUnidadesGrupo(vm.grupoSeleccionado);
                    mostrarSweetAlertSuccess(salida["mensaje"]);
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function listarUnidadesGrupo(Grupo = "", Select = ""){
            if (Select == "select") {
                $.each($("input[name='chkUnidad[]']:checked"), function () {
                    $(this).prop("checked", false);
                });
                vm.listaUnidadesGrupo = {};
                vm.listaUnidadesSeleccionadas = [];
                if (vm.grupoSeleccionadoApertura == "") {
                    return false;
                } else {
                    vm.objeto = {
                        accion: 12,
                        PgrCodigo: vm.grupoSeleccionadoApertura
                    }; 
                }
            } 

            vm.listaUnidadesGrupo = [];

            if ( Grupo != "" ) {
                console.log(Grupo);
                vm.grupoSeleccionado = Grupo;
                vm.objeto = {
                    accion: 12,
                    PgrCodigo: vm.grupoSeleccionado.PgrCodigo
                };
                mostrarSweetAlertCargando();
            }


            $http({
                url: "logica/aperfe.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                if ( Grupo != "" ) {
                    swal.closeModal();
                }
                var salida = response.data;
                if (salida["resultado"] == false) {
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                }
                else {
                    if (salida.data != null) {
                        vm.listaUnidadesGrupo = salida.data;
                        if (Select == "select") {
                            usarArrayGrupo();
                        }
                    }
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function listarGrupos(Grupo = "") {
            vm.listaGrupos = [];
            vm.listaUnidadesGrupo = [];

            if ( Grupo != "" ) {
                mostrarSweetAlertCargando();
            }

            vm.objeto = {
                accion: 11
            };

            $http({
                url: "logica/aperfe.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                if ( Grupo != "" ) {
                    swal.closeModal();
                }
                var salida = response.data;
                if (salida["resultado"] == false) {
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                }
                else {
                    if (salida.data != null) {
                        vm.listaGrupos = salida.data;
                    }
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function listarUnidadesPeriodo(periodo) {
            vm.listaUnidadesActivas = {};
            console.log(periodo.PerCodigo);
        }

        function cambiarModoHistorial(modo) {
            vm.historialModoBusqueda = modo;
            vm.nombreUaaAperturaActiva = '';
            vm.listaAperturaActiva = [];
            vm.listaAperturaGestionActiva = [];
            vm.listaAperturaSolicitudesActiva = [];
            vm.listaUsuariosUnidad = [];
            vm.historialPeriodoAgrupado = [];
        }

        function actualizarFiltroGrupoHistorial() {
            vm.historialCodigosGrupo = [];

            if (vm.historialGrupoSeleccionado == "" || vm.historialGrupoSeleccionado == null) {
                return;
            }

            vm.objeto = {
                accion: 12,
                PgrCodigo: vm.historialGrupoSeleccionado
            };

            $http({
                url: "logica/aperfe.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                var salida = response.data;
                if (salida["resultado"] == false) {
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                } else {
                    if (salida.data != null) {
                        vm.historialCodigosGrupo = salida.data.map(item => parseInt(item.UaaCodigo));
                    }
                }
            }, function myError(response) {
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function unidadVisibleHistorial(uaaCodigo) {
            if (!vm.historialGrupoSeleccionado) {
                return true;
            }

            if (!Array.isArray(vm.historialCodigosGrupo) || vm.historialCodigosGrupo.length <= 0) {
                return false;
            }

            return vm.historialCodigosGrupo.includes(parseInt(uaaCodigo));
        }

        function filtroAperturaHistorial(apertura, tipoApertura) {
            if (vm.historialTipoSeleccionado !== 'TODOS' && vm.historialTipoSeleccionado !== tipoApertura) {
                return false;
            }

            let estado = estadoApertura(apertura);

            if (vm.historialEstadoSeleccionado !== 'TODOS' && vm.historialEstadoSeleccionado !== estado) {
                return false;
            }

            return true;
        }

        function estadoApertura(apertura) {
            let estadoNumerico = 0;
            if (apertura.PraEstado !== undefined) {
                estadoNumerico = parseInt(apertura.PraEstado);
            } else if (apertura.PrgEstado !== undefined) {
                estadoNumerico = parseInt(apertura.PrgEstado);
            } else if (apertura.PrsEstado !== undefined) {
                estadoNumerico = parseInt(apertura.PrsEstado);
            } else if (apertura.EstadoApertura !== undefined) {
                estadoNumerico = parseInt(apertura.EstadoApertura);
            }

            let estado = 'INACTIVO';
            if (estadoNumerico == 1 && apertura.Pendiente == 1) {
                estado = 'PENDIENTE';
            } else if (apertura.Vencida == 1 && estadoNumerico == 1) {
                estado = 'VENCIDO';
            } else if (estadoNumerico == 1) {
                estado = 'ACTIVO';
            }

            return estado;
        }

        function buscarHistorialPeriodo() {
            if (!vm.historialPeriodoSeleccionado || vm.historialPeriodoSeleccionado == "") {
                mostrarSweetAlertWarning("Debe seleccionar un periodo académico para la búsqueda.");
                return;
            }

            mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 23,
                PerCodigo: vm.historialPeriodoSeleccionado,
                PgrCodigo: vm.historialGrupoSeleccionado == "" ? 0 : vm.historialGrupoSeleccionado
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
                    return;
                }

                vm.historialResultadosPeriodo = salida.data || [];

                const agrupado = {};
                vm.historialResultadosPeriodo.forEach(item => {
                    const key = item.UaaCodigo;
                    if (!agrupado[key]) {
                        agrupado[key] = {
                            UaaCodigo: item.UaaCodigo,
                            UaaNombreCorto: item.UaaNombreCorto,
                            UaaNombre: item.UaaNombre,
                            Items: []
                        };
                    }
                    agrupado[key].Items.push(item);
                });

                vm.historialPeriodoAgrupado = Object.values(agrupado);
            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function desactivarProgramacionAperturaGestion(calendario) {
            mostrarSweetAlertCargando();
            vm.objeto = {
                accion: 10,
                PrgCodigo: calendario.PrgCodigo
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
                if (salida["resultado"] == true) {
                    buscarCalendarioUnidad(calendario.UaaCodigo, vm.nombreUaaAperturaActiva);
                    mostrarSweetAlertSuccess(salida["mensaje"]);
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function guardarAperturaGestion() {
            if (vm.listaUnidadesSeleccionadas.length <= 0) {
                mostrarSweetAlertWarning("No se ha seleccionado ninguna unidad.");
                return false;
            }

            if (vm.crearAperturaGestion.fechaInicial == '') {
                mostrarSweetAlertWarning("Debe ingresar la fecha inicial.");
                return false;
            }

            if (!validateDate(vm.crearAperturaGestion.fechaInicial)) {
                mostrarSweetAlertWarning("La fecha inicial no tiene formato correcto YYYY-MM-DD.");
                return false;
            }

            if (vm.crearAperturaGestion.horaInicial == '' || vm.crearAperturaGestion.horaInicial == null) {
                mostrarSweetAlertWarning("Debe ingresar la hora inicial.");
                return false;
            }

            if (vm.crearAperturaGestion.fechaFinal == '') {
                mostrarSweetAlertWarning("Debe ingresar la fecha final.");
                return false;
            }

            if (!validateDate(vm.crearAperturaGestion.fechaFinal)) {
                mostrarSweetAlertWarning("La fecha final no tiene formato correcto YYYY-MM-DD.");
                return false;
            }

            if (vm.crearAperturaGestion.horaFinal == '' || vm.crearAperturaGestion.horaFinal == null) {
                mostrarSweetAlertWarning("Debe ingresar la hora final.");
                return false;
            }

            let hora_inicial = vm.crearAperturaGestion.horaInicial.toString().split(' ');
            let hora_final = vm.crearAperturaGestion.horaFinal.toString().split(' ');

            let fecha_inicial = vm.crearAperturaGestion.fechaInicial + 'T' + hora_inicial[4];
            let fecha_final = vm.crearAperturaGestion.fechaFinal + 'T' + hora_final[4];

            if (!validateDateFinal(fecha_inicial, fecha_final)) {
                mostrarSweetAlertWarning("La fecha y hora final no puede ser menor o igual que la fecha y hora inicial.");
                return false;
            }

            if (!esEntero(vm.crearAperturaGestion.calendario)) {
                mostrarSweetAlertWarning("El formato del calendario no es valido, por favor recargue la pagina.");
                return false;
            }

            if (vm.crearAperturaGestion.calendario == '') {
                mostrarSweetAlertWarning("Debe seleccionar un calendario.");
                return false;
            }

            mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 8,
                UaaSeleccionadas: vm.listaUnidadesSeleccionadas,
                FechaInicial: vm.crearAperturaGestion.fechaInicial,
                HoraInicial: vm.crearAperturaGestion.horaInicial,
                FechaFinal: vm.crearAperturaGestion.fechaFinal,
                HoraFinal: vm.crearAperturaGestion.horaFinal,
                CalendarioCodigo: vm.crearAperturaGestion.calendario,
                Correo: vm.crearAperturaGestion.correo
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
                if (salida["resultado"] == true) {
                    vaciarcrearAperturaGestion();
                    mostrarSweetAlertSuccess(salida["mensaje"]);
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function vaciarLista() {
            vm.listaAperturaActiva = [];
            vm.nombreUaaAperturaActiva = '';
            vm.listaAperturaSolicitudesActiva = [];
            vm.nombreUaaSolicitudesActiva = '';
            vm.listaUnidadesSeleccionadas = [];
            vm.listaUsuariosUnidad = [];
        }

        function consultarUsuarioUnidad(unidad) {
            vm.listaUsuariosUnidad = [];

            mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 7,
                UaaCodigo: unidad
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
                    if (salida.data != null) {
                        vm.listaUsuariosUnidad = salida.data;
                    }
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function desactivarProgramacionApertura(calendario) {
            mostrarSweetAlertCargando();
            vm.objeto = {
                accion: 6,
                PraCodigo: calendario.PraCodigo
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
                if (salida["resultado"] == true) {
                    buscarCalendarioUnidad(calendario.UaaCodigo, vm.nombreUaaAperturaActiva);
                    mostrarSweetAlertSuccess(salida["mensaje"]);
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function buscarCalendarioUnidad(UaaCodigo, UaaNombre) {
            vm.listaAperturaActiva = [];
            vm.listaAperturaGestionActiva = [];
            vm.listaAperturaSolicitudesActiva = [];
            vm.nombreUaaAperturaActiva = UaaNombre;
            vm.nombreUaaSolicitudesActiva = UaaNombre;

            mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 5,
                UaaCodigo: UaaCodigo
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
                    if (salida.data != null) {
                        vm.listaAperturaActiva = salida.data;
                    }
                }
            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });

            vm.objeto = {
                accion: 9,
                UaaCodigo: UaaCodigo
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
                    if (salida.data != null) {
                        vm.listaAperturaGestionActiva = salida.data;
                    }
                }
            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });

            vm.objeto = {
                accion: 20,
                UaaCodigo: UaaCodigo
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
                    if (salida.data != null) {
                        vm.listaAperturaSolicitudesActiva = salida.data;
                    }
                }
            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function vaciarcrearAperturaGestion() {
            vm.listaUnidadesSeleccionadas = [];
            vm.filtroUaa = '';
            $(".unidad").prop("checked", false);
            vm.crearAperturaGestion = {
                fechaInicial: "",
                fechaFinal: "",
                periodoFechaInicial: "",
                periodoFechaFinal: "",
                calendario: "",
                correo: "1",
                horaInicial: null,
                horaFinal: null
            };
        }

        function vaciarcrearAperturaProaca() {
            vm.listaUnidadesSeleccionadas = [];
            vm.filtroUaa = '';
            $(".unidad").prop("checked", false);
            vm.crearAperturaProaca = {
                fechaInicial: "",
                fechaFinal: "",
                periodoFechaInicial: "",
                periodoFechaFinal: "",
                calendario: "",
                correo: "1",
                procesos: [],
                horaInicial: null,
                horaFinal: null
            };
        }

        function guardarApertura() {
            if (vm.listaUnidadesSeleccionadas.length <= 0) {
                mostrarSweetAlertWarning("No se ha seleccionado ninguna unidad.");
                return false;
            }

            if (vm.crearAperturaProaca.fechaInicial == '') {
                mostrarSweetAlertWarning("Debe ingresar la fecha inicial.");
                return false;
            }

            if (!validateDate(vm.crearAperturaProaca.fechaInicial)) {
                mostrarSweetAlertWarning("La fecha inicial no tiene formato correcto YYYY-MM-DD.");
                return false;
            }

            if (vm.crearAperturaProaca.horaInicial == '' || vm.crearAperturaProaca.horaInicial == null) {
                mostrarSweetAlertWarning("Debe ingresar la hora inicial.");
                return false;
            }

            if (vm.crearAperturaProaca.fechaFinal == '') {
                mostrarSweetAlertWarning("Debe ingresar la fecha final.");
                return false;
            }

            if (!validateDate(vm.crearAperturaProaca.fechaFinal)) {
                mostrarSweetAlertWarning("La fecha final no tiene formato correcto YYYY-MM-DD.");
                return false;
            }

            if (vm.crearAperturaProaca.horaFinal == '' || vm.crearAperturaProaca.horaFinal == null) {
                mostrarSweetAlertWarning("Debe ingresar la hora final.");
                return false;
            }

            let hora_inicial = vm.crearAperturaProaca.horaInicial.toString().split(' ');
            let hora_final = vm.crearAperturaProaca.horaFinal.toString().split(' ');

            let fecha_inicial = vm.crearAperturaProaca.fechaInicial + 'T' + hora_inicial[4];
            let fecha_final = vm.crearAperturaProaca.fechaFinal + 'T' + hora_final[4];

            if (!validateDateFinal(fecha_inicial, fecha_final)) {
                mostrarSweetAlertWarning("La fecha y hora final no puede ser menor o igual que la fecha y hora inicial.");
                return false;
            }

            if (!esEntero(vm.crearAperturaProaca.calendario)) {
                mostrarSweetAlertWarning("El formato del calendario no es valido, por favor recargue la pagina.");
                return false;
            }

            if (vm.crearAperturaProaca.calendario == '') {
                mostrarSweetAlertWarning("Debe seleccionar un calendario.");
                return false;
            }

            if (vm.crearAperturaProaca.procesos.length <= 0) {
                mostrarSweetAlertWarning("No se ha seleccionado ninguna proceso.");
                return false;
            }

            mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 3,
                UaaSeleccionadas: vm.listaUnidadesSeleccionadas,
                FechaInicial: vm.crearAperturaProaca.fechaInicial,
                HoraInicial: vm.crearAperturaProaca.horaInicial,
                FechaFinal: vm.crearAperturaProaca.fechaFinal,
                HoraFinal: vm.crearAperturaProaca.horaFinal,
                CalendarioCodigo: vm.crearAperturaProaca.calendario,
                ProcesoSeleccionados: vm.crearAperturaProaca.procesos,
                Correo: vm.crearAperturaProaca.correo
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
                if (salida["resultado"] == true) {
                    vaciarcrearAperturaProaca();
                    mostrarSweetAlertSuccess(salida["mensaje"]);
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultarProcesos() {
            vm.listaProcesos = {};

            mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 4
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
                    vm.listaProcesos = salida.data;
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
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

        function rellenarCheck() {
            vm.listaUnidadesSeleccionadas.forEach(unidad => {
                $(".unidad" + unidad.UaaCodigo).prop("checked", true);
            });
        }

        function consultarCalendarios() {
            vm.listaCalendarios = {};

            mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 2
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
                    vm.listaCalendarios = salida.data;
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
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
                    if (current.UaaCodigo == uaaCodigo) {
                        return false;
                    } else {
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

        function seleccionarUnidad(codigoUaa) {
            var check = $(".unidad" + codigoUaa).prop("checked");
            if (check) {
                $(".unidad" + codigoUaa).prop("checked", false);
            } else {
                $(".unidad" + codigoUaa).prop("checked", true);
            }
            recorrerUnidadesSeleccionables();
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
            vm.filtroUaa = '';
            vm.listaCalendariosActivos = 0;
            vm.listaCalendariosProgramacion = 0;
            vm.listaCalendariosGestion = 0;
            vm.listaCalendariosActivosPeriodo = 0;
            vm.listaGruposUnidad = 0;
            vm.listaModuloSolicitudes = 0;
            vm.grupoSeleccionado = {};
            vm.grupoSeleccionadoApertura = "";

            switch (pestana) {
                case 'CalendariosActivosPeriodo':
                    vaciarLista();
                    consultarPeriodos();
                    vm.listaCalendariosActivosPeriodo = 1;
                    break;
                case 'CalendariosActivos':
                    vaciarLista();
                    vm.historialPeriodoAgrupado = [];
                    vm.historialPeriodoSeleccionado = "";
                    vm.historialModoBusqueda = 'UNIDAD';
                    vm.listaCalendariosActivos = 1;
                    break;
                case 'CalendariosProgramacion':
                    vaciarcrearAperturaProaca();
                    recorrerUnidadesSeleccionables();
                    consultarProcesos();
                    vm.listaCalendariosProgramacion = 1;
                    break;
                case 'CalendariosGestion':
                    vaciarcrearAperturaGestion();
                    recorrerUnidadesSeleccionables();
                    vm.listaCalendariosGestion = 1;
                    break;
                case 'GrupoUnidades':
                    listarGrupos();
                    // recorrerUnidadesSeleccionables();
                    vm.listaGruposUnidad = 1;
                    break;
                case 'ModuloSolicitudes':
                    vaciarcrearAperturaSolicitudes();
                    recorrerUnidadesSeleccionables();
                    consultarTiposSolicitud();
                    vm.listaModuloSolicitudes = 1;
                    break;
                default:
                    console.log('Error');
                    break;
            }
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

        function consultarTiposSolicitud() {
            vm.listaTiposSolicitud = [];

            vm.objeto = {
                accion: 18
            };

            mostrarSweetAlertCargando();

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
                    vm.listaTiposSolicitud = salida.data;
                }
            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function vaciarcrearAperturaSolicitudes() {
            vm.listaAperturaSolicitudesActiva = [];
            vm.nombreUaaSolicitudesActiva = '';
            vm.listaUnidadesSeleccionadas = [];
            vm.filtroUaa = '';
            vm.filtroSolicitudesActiva = '';
            $(".unidad").prop("checked", false);
            vm.crearAperturaSolicitudes = {
                fechaInicial: "",
                fechaFinal: "",
                calendario: "",
                correo: "1",
                tipos: [],
                horaInicial: null,
                horaFinal: null
            };
        }

        function guardarAperturaSolicitudes() {
            if (vm.listaUnidadesSeleccionadas.length <= 0) {
                mostrarSweetAlertWarning("No se ha seleccionado ninguna unidad.");
                return;
            }

            if (vm.crearAperturaSolicitudes.fechaInicial == '') {
                mostrarSweetAlertWarning("Debe ingresar la fecha inicial.");
                return false;
            }

            if (!validateDate(vm.crearAperturaSolicitudes.fechaInicial)) {
                mostrarSweetAlertWarning("La fecha inicial no tiene formato correcto YYYY-MM-DD.");
                return false;
            }

            if (vm.crearAperturaSolicitudes.horaInicial == '' || vm.crearAperturaSolicitudes.horaInicial == null) {
                mostrarSweetAlertWarning("Debe ingresar la hora inicial.");
                return false;
            }

            if (vm.crearAperturaSolicitudes.fechaFinal == '') {
                mostrarSweetAlertWarning("Debe ingresar la fecha final.");
                return false;
            }

            if (!validateDate(vm.crearAperturaSolicitudes.fechaFinal)) {
                mostrarSweetAlertWarning("La fecha final no tiene formato correcto YYYY-MM-DD.");
                return false;
            }

            if (vm.crearAperturaSolicitudes.horaFinal == '' || vm.crearAperturaSolicitudes.horaFinal == null) {
                mostrarSweetAlertWarning("Debe ingresar la hora final.");
                return false;
            }

            let hora_inicial = vm.crearAperturaSolicitudes.horaInicial.toString().split(' ');
            let hora_final = vm.crearAperturaSolicitudes.horaFinal.toString().split(' ');

            let fecha_inicial = vm.crearAperturaSolicitudes.fechaInicial + 'T' + hora_inicial[4];
            let fecha_final = vm.crearAperturaSolicitudes.fechaFinal + 'T' + hora_final[4];

            if (!validateDateFinal(fecha_inicial, fecha_final)) {
                mostrarSweetAlertWarning("La fecha y hora final no puede ser menor o igual que la fecha y hora inicial.");
                return false;
            }

            if (!esEntero(vm.crearAperturaSolicitudes.calendario)) {
                mostrarSweetAlertWarning("El formato del calendario no es valido, por favor recargue la pagina.");
                return false;
            }

            if (vm.crearAperturaSolicitudes.calendario == '') {
                mostrarSweetAlertWarning("Debe seleccionar un calendario.");
                return false;
            }

            if (vm.crearAperturaSolicitudes.tipos.length <= 0) {
                mostrarSweetAlertWarning("No se ha seleccionado ningún tipo de solicitud.");
                return false;
            }

            mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 19,
                UaaSeleccionadas: vm.listaUnidadesSeleccionadas,
                FechaInicial: vm.crearAperturaSolicitudes.fechaInicial,
                HoraInicial: vm.crearAperturaSolicitudes.horaInicial,
                FechaFinal: vm.crearAperturaSolicitudes.fechaFinal,
                HoraFinal: vm.crearAperturaSolicitudes.horaFinal,
                CalendarioCodigo: vm.crearAperturaSolicitudes.calendario,
                TiposSeleccionados: vm.crearAperturaSolicitudes.tipos,
                Correo: vm.crearAperturaSolicitudes.correo
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
                if (salida["resultado"] == true) {
                    mostrarSweetAlertSuccess(salida["mensaje"]);
                    if (vm.nombreUaaSolicitudesActiva != '' && vm.listaUnidadesSeleccionadas.length > 0) {
                        let ultima = vm.listaUnidadesSeleccionadas[vm.listaUnidadesSeleccionadas.length - 1];
                        buscarCalendarioUnidadSolicitudes(ultima.UaaCodigo, vm.nombreUaaSolicitudesActiva);
                    }
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function buscarCalendarioUnidadSolicitudes(UaaCodigo, UaaNombre) {
            vm.listaAperturaSolicitudesActiva = [];
            vm.nombreUaaSolicitudesActiva = UaaNombre;

            mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 20,
                UaaCodigo: UaaCodigo
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
                    if (salida.data != null) {
                        vm.listaAperturaSolicitudesActiva = salida.data;
                    }
                }
            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function desactivarAperturaSolicitudes(apertura) {
            mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 21,
                PrsCodigo: apertura.PrsCodigo
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
                if (salida["resultado"] == true) {
                    buscarCalendarioUnidadSolicitudes(apertura.UaaCodigo, vm.nombreUaaSolicitudesActiva);
                    mostrarSweetAlertSuccess(salida["mensaje"]);
                }
            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }






        //Funciones de modals sweet alert

        vm.abrirModal = abrirModal;

        function mostrarSweetAlertConfirmacion(mje, callbackAceptar) {
            Swal.fire({
                title: '¿Está seguro?',
                html: mje,
                icon: 'question',
                showCancelButton: true,
                confirmButtonText: 'Sí, continuar',
                cancelButtonText: 'No, cancelar',
                confirmButtonColor: '#3085d6',
                cancelButtonColor: '#d33',
                buttonsStyling: true
            }).then((result) => {
                if (result.isConfirmed) {
                    callbackAceptar();
                }
            }).catch(swal.noop);
        }

        function abrirModal(modal) {
            $("#" + modal).modal('show');
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
