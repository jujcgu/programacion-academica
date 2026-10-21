(function () {
    angular
        .module('sipa')
        .controller('SoldocController', SoldocController);

    function SoldocController($http) {
        var vm = this;
        //Visualizacion
        vm.seccionListaSolicitudes = 0;
        vm.seccionFormularioCreacionSolicitud = 0;
        vm.seccionFormularioEdicionSolicitud = 0;
        vm.tipoUnidadesBuscadas = 0;
        vm.menu = 0;

        //Variables
        vm.periodoActual = '';
        vm.periodosActivos = [];
        vm.periodoBuscado = '';
        vm.moduloDisponibilidadMensaje = 'Consultando disponibilidad del módulo...';
        vm.moduloDisponibilidadHabilitado = false;
        vm.moduloDisponibilidadFechaFin = '';
        vm.moduloDisponibilidadCantidadProgramas = 0;
        vm.listaPeriodos = [];
        vm.listaCalendarios = [];
        vm.listaSolicitudesPeriodo = [];
        vm.listaUnidades = [];
        vm.periodoSeleccionado = "";
        vm.calendarioSeleccionado = "";
        vm.creacionSolicitud = {};
        vm.edicionSolicitud = {};
        vm.creacionHorarioSolicitud = [];
        vm.filtroAsignatura = '';
        vm.listaAsignaturas = [];
        vm.listaDias = [];
        vm.listaHoras = [];
        vm.horarioSeleccionado = {};
        vm.diaSeleccionado = "";
        vm.horaSeleccionada = "";
        vm.solicitudSeleccionada = [];
        vm.listaHorario = [];
        vm.mensajeComentario = "";
        vm.listaDocentes = [];
        vm.asignacionDocente = {};
        vm.tipoAsignacionDocente = "";
        vm.listaSedes = [];
        vm.listaHorarioPersona = [];
        vm.tipoFormulario = "creacion";
        vm.listaSolicitudesProgramadas = [];
        vm.listaSolicitudesEliminadas = [];
        vm.tituloSolicitudesProgramadas = "";
        vm.validarUnidadSeleccionada = false;

        //Filtros
        vm.filter = {
            SolicitudCodigo: '',
            SolicitudesDirigidas: '',
            SolicitudesRealizadas: '',
            SolicitudesEliminadas: '',
            AsignaturaEstado: '',
            Unidad: '',
            Docente: '',
            ReporteAprobadasProgramadas: '',
        };

        //Funciones Declaración
        vm.consultarPeriodos = consultarPeriodos;
        vm.consultarSolicitudesPeriodo = consultarSolicitudesPeriodo;
        vm.formularioCrearSolicitud = formularioCrearSolicitud;
        vm.cancelarCrearSolicitud = cancelarCrearSolicitud;
        vm.buscarAsignatura = buscarAsignatura;
        vm.seleccionarAsignatura = seleccionarAsignatura;
        vm.consultarUnidades = consultarUnidades;
        vm.seleccionarUnidadDirigida = seleccionarUnidadDirigida;
        vm.crearSolicitud = crearSolicitud;
        vm.consultarDias = consultarDias;
        vm.consultarHoras = consultarHoras;
        vm.agregarHorario = agregarHorario;
        vm.seleccionarDia = seleccionarDia;
        vm.seleccionarHora = seleccionarHora;
        vm.quitarHorario = quitarHorario;
        vm.consultaHorarioSolicitud = consultaHorarioSolicitud;
        vm.consultaComentariosSolicitud = consultaComentariosSolicitud;
        vm.agregarComentario = agregarComentario;
        vm.getUserInitials = getUserInitials;
        vm.modalAsignarDocente = modalAsignarDocente;
        vm.seleccionarDocente = seleccionarDocente;
        vm.asignarDocente = asignarDocente;
        vm.eliminarHorarioSeleccionado = eliminarHorarioSeleccionado;
        vm.modalRechazarSolicitud = modalRechazarSolicitud;
        vm.rechazarSolicitud = rechazarSolicitud;
        vm.eliminarSolicitud = eliminarSolicitud;
        vm.fomularioEditarSolicitud = fomularioEditarSolicitud;
        vm.agregarHorarioSolicitud = agregarHorarioSolicitud;
        vm.cancelarEditarSolicitud = cancelarEditarSolicitud;
        vm.reEnviarSolicitud = reEnviarSolicitud;
        vm.consultarSedes = consultarSedes;
        vm.validarUnidadSeleccionadaHorasSede = validarHorasSede;
        vm.abrirFormulario = abrirFormulario;
        vm.consultarSolicitudesEliminadas = consultarSolicitudesEliminadas;
        vm.periodoHabilitado = periodoHabilitado;
        vm.mensajeDisponibilidadPeriodo = mensajeDisponibilidadPeriodo;
        vm.cantidadProgramasPeriodo = cantidadProgramasPeriodo;


        //Funciones ejecutadas al inicio
        consultarPeriodos();
        consultarHoras();
        consultarDias();
        consultarPeriodoHabilitado();

        function consultarPeriodoHabilitado(){
            vm.objeto = {
                accion: 16,
                PtsCodigo: 3
            }
            $http({
                url: "logica/solcambh.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                var salida = response.data;
                if (salida["resultado"] == false) {
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                }
                else {
                    vm.periodoActual = salida.data;
                    vm.periodosActivos = salida.periodosActivos || [];
                    vm.moduloDisponibilidadHabilitado = salida.habilitado === true;
                    vm.moduloDisponibilidadFechaFin = salida.fechaFin || '';
                    vm.moduloDisponibilidadCantidadProgramas = salida.cantidadProgramasActivos || 0;
                    vm.moduloDisponibilidadMensaje = salida.mensajeDisponibilidad || 'El módulo no está habilitado para crear nuevas solicitudes.';
                }

            }, function myError(response) {
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function buscarDisponibilidadPeriodo(periodoCodigo) {
            if (!periodoCodigo || !Array.isArray(vm.periodosActivos)) {
                return null;
            }

            return vm.periodosActivos.find(function (periodo) {
                return parseInt(periodo.PeriodoActivo) === parseInt(periodoCodigo);
            }) || null;
        }

        function periodoHabilitado(periodoCodigo) {
            return buscarDisponibilidadPeriodo(periodoCodigo) !== null;
        }

        function mensajeDisponibilidadPeriodo(periodoCodigo) {
            var periodo = buscarDisponibilidadPeriodo(periodoCodigo);
            if (periodo !== null) {
                return periodo.mensajeDisponibilidad;
            }
            return 'El periodo consultado no estÃ¡ habilitado para crear nuevas solicitudes.';
        }

        function cantidadProgramasPeriodo(periodoCodigo) {
            var periodo = buscarDisponibilidadPeriodo(periodoCodigo);
            if (periodo !== null) {
                return periodo.cantidadProgramasActivos || 0;
            }
            return 0;
        }

        function consultarSolicitudesEliminadas() {
            vm.listaSolicitudesEliminadas = [];
            vm.objeto = {
                accion: 18,
                PerCodigo: vm.periodoSeleccionado
            };
            mostrarSweetAlertCargando();

            $http({
                url: "logica/soldoc.php",
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
                    vm.listaSolicitudesEliminadas = salida.data;
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultarSolicitudesProgramadas(Tipo) {
            vm.listaSolicitudesProgramadas = [];
            vm.objeto = {
                accion: 17,
                tipoSolicitud: Tipo,
                PerCodigo: vm.periodoSeleccionado
            };
            mostrarSweetAlertCargando();

            $http({
                url: "logica/soldoc.php",
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
                    vm.listaSolicitudesProgramadas = salida.data;
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function abrirFormulario(tipoFormulario) {
            vm.seccionFormularioCreacionSolicitud = 0;
            vm.seccionFormularioEdicionSolicitud = 0;
            vm.seccionListaSolicitudes = tipoFormulario ? tipoFormulario : 0;

            // 3. Es la seccion de solicitudes aprobadas realizadas y si tienen programado cursos
            if (vm.seccionListaSolicitudes == 3) { 
                vm.tituloSolicitudesProgramadas = "Solicitudes Realizadas Programadas";
                consultarSolicitudesProgramadas("Realizada");
            }

            // 5. Es la seccion de solicitudes aprobadas recibidas y si tienen programado cursos
            if (vm.seccionListaSolicitudes == 5) { 
                vm.tituloSolicitudesProgramadas = "Solicitudes Recibidas Programadas";
                consultarSolicitudesProgramadas("Recibida");
            }

            // 4. Es la seccion de solicitudes eliminadas
            if (vm.seccionListaSolicitudes == 4) { 
                consultarSolicitudesEliminadas();
            }
        }

        function validarHorasSede() {
            if ((vm.asignacionDocente.VinCodigo == 14 || vm.asignacionDocente.VinCodigo == 24) && vm.asignacionDocente.DedCodigo == 6) {
                const cantHorasHorarioPersona = vm.listaHorarioPersona ? vm.listaHorarioPersona.length : 0;
                if (vm.asignacionDocente.SedCodigo == 1) {
                    if (cantHorasHorarioPersona + vm.listaHorario.length > 16) {
                        return true;
                    }
                }

                if (vm.asignacionDocente.SedCodigo != 1) {
                    if (cantHorasHorarioPersona + vm.listaHorario.length > 19) {
                        return true;
                    }
                }
            }
            return false;
        }

        function consultarSedes() {
            vm.listaSedes = [];
            vm.objeto = {
                accion: 15
            };

            $http({
                url: "logica/soldoc.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                var salida = response.data;
                if (salida["resultado"] == false) {
                    swal.closeModal();
                    console.error(salida["consola"]);
                }
                else {
                    vm.listaSedes = salida.data;
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function reEnviarSolicitud() {
            if (vm.edicionSolicitud.SpdCodigo == '' || vm.edicionSolicitud.SpdCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar una solicitud.");
                return false;
            }
            if (vm.listaHorario === '' || vm.listaHorario === undefined || vm.listaHorario === null) {
                mostrarSweetAlertWarning("Debe agregar por lo menos un horario.");
                return false;
            }
            vm.objeto = {
                accion: 14,
                SpdCodigo: vm.edicionSolicitud.SpdCodigo,
                AsiCodigo: vm.edicionSolicitud.AsiCodigo,
                UaaDirigidaCodigo: vm.edicionSolicitud.UaaDirigidaCodigo,
                SedCodigo: vm.edicionSolicitud.SedCodigo,
            };

            mostrarSweetAlertCargando();

            $http({
                url: "logica/soldoc.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                var salida = response.data;
                if (salida["resultado"] == false) {
                    swal.closeModal();
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                }
                if (salida["resultado"] == true) {
                    swal.closeModal();
                    vm.edicionSolicitud = {};
                    vm.seccionFormularioCreacionSolicitud = 0;
                    vm.seccionFormularioEdicionSolicitud = 0;
                    vm.tipoUnidadesBuscadas = 0;
                    consultarSolicitudesPeriodo(false);
                    vm.seccionListaSolicitudes = 2;
                    mostrarSweetAlertSuccess(salida["mensaje"]);
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function cancelarEditarSolicitud() {
            vm.edicionSolicitud = {};
            vm.solicitudSeleccionada = [];
            vm.seccionFormularioEdicionSolicitud = 0;
            vm.seccionListaSolicitudes = 2;
            vm.listaHorario = [];
            vm.validarUnidadSeleccionada = false;
        }

        function agregarHorarioSolicitud() {
            if (vm.edicionSolicitud.SpdCodigo == '' || vm.edicionSolicitud.SpdCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar una solicitud.");
                return false;
            }
            if (vm.edicionSolicitud.DiaSeleccionado == '' || vm.edicionSolicitud.DiaSeleccionado === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar un dia.");
                return false;
            }
            if (vm.edicionSolicitud.HorasSeleccionadas == '' || vm.edicionSolicitud.HorasSeleccionadas === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar por lo menos una hora.");
                return false;
            }

            vm.objeto = {
                accion: 13,
                SpdCodigo: vm.solicitudSeleccionada.SpdCodigo,
                DiaCodigo: vm.solicitudSeleccionada.DiaSeleccionado,
                HorasSeleccionadas: vm.solicitudSeleccionada.HorasSeleccionadas
            };

            mostrarSweetAlertCargando();

            $http({
                url: "logica/soldoc.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                var salida = response.data;
                if (salida["resultado"] == false) {
                    swal.closeModal();
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                }
                if (salida["resultado"] == true) {
                    swal.closeModal();
                    consultaHorarioSolicitud('', 1);
                    mostrarSweetAlertSuccess(salida["mensaje"]);
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });

        }

        function fomularioEditarSolicitud(solicitud) {
            vm.edicionSolicitud = {};
            vm.solicitudSeleccionada = [];
            vm.solicitudSeleccionada = solicitud;
            if (vm.solicitudSeleccionada.SpdCodigo == '' || vm.solicitudSeleccionada.SpdCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar una solicitud.");
                return false;
            }
            vm.edicionSolicitud = solicitud;
            vm.edicionSolicitud.PeriodoCodigo = vm.periodoSeleccionado;
            consultarSedes();
            consultaHorarioSolicitud('', 1);
            vm.seccionListaSolicitudes = 0;
            vm.seccionFormularioCreacionSolicitud = 0;
            vm.seccionFormularioEdicionSolicitud = 1;
            vm.tipoFormulario = "edicion";
            vm.validarUnidadSeleccionada = true;
        }

        function eliminarSolicitud(solicitud) {
            vm.solicitudSeleccionada = [];
            vm.solicitudSeleccionada = solicitud;

            if (vm.solicitudSeleccionada.SpdCodigo == '' || vm.solicitudSeleccionada.SpdCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar una solicitud.");
                return false;
            }

            vm.objeto = {
                accion: 12,
                SpdCodigo: vm.solicitudSeleccionada.SpdCodigo
            };

            mostrarSweetAlertCargando();

            $http({
                url: "logica/soldoc.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                var salida = response.data;
                if (salida["resultado"] == false) {
                    swal.closeModal();
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                }
                if (salida["resultado"] == true) {
                    swal.closeModal();
                    consultarSolicitudesPeriodo(false);
                    vm.seccionListaSolicitudes = 2;
                    mostrarSweetAlertSuccess(salida["mensaje"]);
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function rechazarSolicitud() {
            if (vm.solicitudSeleccionada.SpdCodigo == '' || vm.solicitudSeleccionada.SpdCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar una solicitud.");
                return false;
            }
            if (vm.mensajeComentario == '' || vm.mensajeComentario === undefined) {
                mostrarSweetAlertWarning("Debe ingresar la justificacion.");
                return false;
            }
            if (vm.mensajeComentario.length <= 5) {
                mostrarSweetAlertWarning("Debe ingresar una justificacion con mas contenido.");
                return false;
            }
            vm.objeto = {
                accion: 11,
                SpdCodigo: vm.solicitudSeleccionada.SpdCodigo,
                UaaSolicitaCodigo: vm.solicitudSeleccionada.UaaSolicitaCodigo,
                PeriodoCodigo: vm.solicitudSeleccionada.PeriodoCodigo,
                mensajeComentario: vm.mensajeComentario
            };

            mostrarSweetAlertCargando();

            $http({
                url: "logica/soldoc.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                var salida = response.data;
                if (salida["resultado"] == false) {
                    swal.closeModal();
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                }
                if (salida["resultado"] == true) {
                    vm.mensajeComentario = "";
                    vm.solicitudSeleccionada = [];
                    swal.closeModal();
                    cerrarModal('modalRechazarSolicitud');
                    consultarSolicitudesPeriodo(false);
                    mostrarSweetAlertSuccess(salida["mensaje"]);
                    vm.seccionListaSolicitudes = 1;
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function modalRechazarSolicitud(solicitud) {
            vm.mensajeComentario = "";
            vm.solicitudSeleccionada = [];
            vm.solicitudSeleccionada = solicitud;
            abrirModal('modalRechazarSolicitud');
        }

        function eliminarHorarioSeleccionado(horario) {
            if (horario.SpdhCodigo == '' || horario.SpdhCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar un horario asignado.");
                return false;
            }

            if (vm.solicitudSeleccionada.SpdCodigo == '' || vm.solicitudSeleccionada.SpdCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar una solicitud.");
                return false;
            }

            vm.objeto = {
                accion: 10,
                SpdhCodigo: horario.SpdhCodigo,
                SpdCodigo: vm.solicitudSeleccionada.SpdCodigo
            };

            // mostrarSweetAlertCargando();

            $http({
                url: "logica/soldoc.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                var salida = response.data;
                if (salida["resultado"] == false) {
                    swal.closeModal();
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                }
                if (salida["resultado"] == true) {
                    swal.closeModal();
                    consultaHorarioSolicitud("", 1);
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function asignarDocente() {
            if (vm.asignacionDocente.PerCodigo == '' || vm.asignacionDocente.PerCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar un docente.");
                return false;
            }
            if (vm.solicitudSeleccionada.PeriodoCodigo == '' || vm.solicitudSeleccionada.PeriodoCodigo === undefined) {
                mostrarSweetAlertWarning("No se encontro el periodo de la solicitud seleccionada.");
                return false;
            }
            if (vm.asignacionDocente.VinCodigo == '' || vm.asignacionDocente.VinCodigo === undefined) {
                mostrarSweetAlertWarning("No se encontro la vinculacion previa del docente seleccionado.");
                return false;
            }
            if (vm.asignacionDocente.DedCodigo == '' || vm.asignacionDocente.DedCodigo === undefined) {
                mostrarSweetAlertWarning("No se encontro la dedicacion previa del docente seleccionado.");
                return false;
            }
            if (vm.asignacionDocente.Mensaje == '' || vm.asignacionDocente.Mensaje === undefined) {
                mostrarSweetAlertWarning("Debe ingresar la justificacion.");
                return false;
            }
            if (vm.asignacionDocente.Mensaje.length <= 5) {
                mostrarSweetAlertWarning("Debe ingresar una justificacion con mas contenido.");
                return false;
            }

            vm.objeto = {
                accion: 9,
                SpdCodigo: vm.solicitudSeleccionada.SpdCodigo,
                PeriodoCodigo: vm.solicitudSeleccionada.PeriodoCodigo,
                PerCodigo: vm.asignacionDocente.PerCodigo,
                VinCodigo: vm.asignacionDocente.VinCodigo,
                DedCodigo: vm.asignacionDocente.DedCodigo,
                Tipo: vm.tipoAsignacionDocente,
                mensajeComentario: vm.asignacionDocente.Mensaje
            };

            mostrarSweetAlertCargando();

            $http({
                url: "logica/soldoc.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                var salida = response.data;
                if (salida["resultado"] == false) {
                    swal.closeModal();
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                }
                if (salida["resultado"] == true) {
                    vm.asignacionDocente = {};
                    vm.solicitudSeleccionada = [];
                    swal.closeModal();
                    consultarSolicitudesPeriodo(false);
                    cerrarModal('modalDocenteSolicitud');
                    mostrarSweetAlertSuccess(salida["mensaje"]);
                    vm.seccionListaSolicitudes = 1;
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function seleccionarDocente(docente) {
            if (docente.PerCodigo == '' || docente.PerCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar un docente.");
                return false;
            }
            vm.asignacionDocente.PerCodigo = docente.PerCodigo;
            vm.asignacionDocente.PerNombreApellido = docente.PerNombreApellido;
            vm.asignacionDocente.PerIdentificacion = docente.PerIdentificacion;
            vm.asignacionDocente.SedCodigo = docente.SedCodigo;
            vm.asignacionDocente.SedNombre = docente.SedNombre;
            vm.asignacionDocente.VinCodigo = docente.VinCodigo;
            vm.asignacionDocente.VinNombre = docente.VinNombre;
            vm.asignacionDocente.DedCodigo = docente.DedCodigo;
            vm.asignacionDocente.DedNombre = docente.DedNombre;

            vm.listaHorarioPersona = [];

            vm.objeto = {
                accion: 16,
                PersonaCodigo: vm.asignacionDocente.PerCodigo,
                PeriodoCodigo: vm.solicitudSeleccionada.PeriodoCodigo
            };

            $http({
                url: "logica/soldoc.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                var salida = response.data;
                if (salida["resultado"] == false) {
                    console.error(salida["consola"]);
                }
                if (salida["resultado"] == true) {
                    vm.listaHorarioPersona = salida.data;
                }
            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function modalAsignarDocente(solicitud, tipo) {
            vm.mensajeComentario = "";
            vm.asignacionDocente = {};
            vm.solicitudSeleccionada = [];
            vm.solicitudSeleccionada = solicitud;
            vm.tipoAsignacionDocente = tipo;

            vm.listaDocentes = [];

            vm.objeto = {
                accion: 8,
                SedCodigo: vm.solicitudSeleccionada.SedCodigo
            };

            $http({
                url: "logica/soldoc.php",
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
                    consultaHorarioSolicitud("", 0)
                    abrirModal('modalDocenteSolicitud');
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function getUserInitials(name) {
            var words = name.split(' ');
            var initials = '';
            for (var i = 0; i < words.length; i++) {
                if (initials.length < 2) { // verifica que solo se agreguen las primeras dos iniciales
                    initials += words[i].charAt(0);
                } else {
                    break; // sale del bucle si ya se han agregado dos iniciales
                }
            }
            return initials;
        };

        function agregarComentario() {
            if (vm.mensajeComentario == '' || vm.mensajeComentario === undefined) {
                mostrarSweetAlertWarning("Debe ingresar el comentario.");
                return false;
            }
            if (vm.mensajeComentario.length <= 5) {
                mostrarSweetAlertWarning("Debe ingresar un comentario con mas contenido.");
                return false;
            }
            vm.objeto = {
                accion: 7,
                SpdCodigo: vm.solicitudSeleccionada.SpdCodigo,
                mensajeComentario: vm.mensajeComentario
            };

            mostrarSweetAlertCargando();

            $http({
                url: "logica/soldoc.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                var salida = response.data;
                if (salida["resultado"] == false) {
                    swal.closeModal();
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                }
                if (salida["resultado"] == true) {
                    vm.mensajeComentario = "";
                    swal.closeModal();
                    consultaComentariosSolicitud();
                    // mostrarSweetAlertSuccess(salida["mensaje"]);
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultaComentariosSolicitud(solicitud = "") {
            if (solicitud != "") {
                vm.solicitudSeleccionada = [];
                vm.solicitudSeleccionada = solicitud;
            }

            if (vm.solicitudSeleccionada.SpdCodigo == '' || vm.solicitudSeleccionada.SpdCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar una solicitud.");
                return false;
            }

            vm.objeto = {
                accion: 6,
                SpdCodigo: vm.solicitudSeleccionada.SpdCodigo
            };

            if (solicitud != "") { mostrarSweetAlertCargando(); vm.listaComentarios = []; }

            $http({
                url: "logica/soldoc.php",
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
                    if (solicitud != "") { swal.closeModal(); }
                    vm.listaComentarios = salida.data;
                    if (solicitud != "") { abrirModal('modalComentariosSolicitud'); }
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultaHorarioSolicitud(solicitud = "", tipo) {
            if (solicitud != "") {
                vm.solicitudSeleccionada = [];
                vm.solicitudSeleccionada = solicitud;
            }
            vm.solicitudSeleccionada.Tipo = tipo;
            if (vm.solicitudSeleccionada.SpdCodigo == '' || vm.solicitudSeleccionada.SpdCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar una solicitud.");
                return false;
            }

            vm.listaHorario = [];

            vm.objeto = {
                accion: 5,
                SpdCodigo: vm.solicitudSeleccionada.SpdCodigo
            };

            if (solicitud != "") { mostrarSweetAlertCargando(); }

            $http({
                url: "logica/soldoc.php",
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
                    vm.listaHorario = salida.data;
                    if (solicitud != "") {
                        swal.closeModal();
                        abrirModal('modalHorarioSolicitud');
                    }
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function quitarHorario(horario) {
            vm.creacionHorarioSolicitud = vm.creacionHorarioSolicitud.filter(obj => obj.DiaCodigo !== horario.DiaCodigo || obj.HraCodigo !== horario.HraCodigo);
        }

        function seleccionarDia() {
            if (vm.diaSeleccionado != "") {
                const datosDia = vm.diaSeleccionado.split("$").map(dato => dato.trim());
                vm.horarioSeleccionado.DiaCodigo = datosDia[0];
                vm.horarioSeleccionado.DiaNombre = datosDia[1];
            }
        }

        function seleccionarHora() {
            if (vm.diaSeleccionado != "") {
                const datosHora = vm.horaSeleccionada.split("$").map(dato => dato.trim());
                vm.horarioSeleccionado.HraCodigo = datosHora[0];
                vm.horarioSeleccionado.HraInicio = datosHora[1];
                vm.horarioSeleccionado.HraFin = datosHora[2];
            }
        }

        function agregarHorario() {
            if (vm.horarioSeleccionado.DiaCodigo == '' || vm.horarioSeleccionado.DiaCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar un dia.");
                return false;
            }
            if (vm.horaSeleccionada == '' || vm.horaSeleccionada === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar por lo menos una hora.");
                return false;
            }
            vm.horaSeleccionada.forEach(element => {
                const datosHora = element.split("$").map(dato => dato.trim());
                let horarioEncontrado = vm.creacionHorarioSolicitud.find(
                    objeto =>
                        objeto.DiaCodigo == vm.horarioSeleccionado.DiaCodigo
                        && objeto.HraCodigo == datosHora[0]
                );
                if (horarioEncontrado === undefined) {
                    vm.horarioSeleccionado.HraCodigo = datosHora[0];
                    vm.horarioSeleccionado.HraInicio = datosHora[1];
                    vm.horarioSeleccionado.HraFin = datosHora[2];
                    vm.creacionHorarioSolicitud.push({ ...vm.horarioSeleccionado });
                }
            });
        }

        function consultarDias() {
            vm.listaDias = [];

            vm.objeto = {
                accion: 4
            };

            $http({
                url: "logica/soldoc.php",
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
                    vm.listaDias = salida.data;
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultarHoras() {
            vm.listaHoras = [];

            vm.objeto = {
                accion: 1
            };

            $http({
                url: "logica/crucehorario.php",
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
                    vm.listaHoras = salida.data;
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function validarCreacionSolicitud() {
            if (vm.creacionSolicitud.PeriodoCodigo == '' || vm.creacionSolicitud.PeriodoCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar un periodo.");
                return false;
            }
            if (vm.creacionSolicitud.AsiCodigo == '' || vm.creacionSolicitud.AsiCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar una asignatura.");
                return false;
            }
            if (vm.creacionSolicitud.UaaCodigoDirigida == '' || vm.creacionSolicitud.UaaCodigoDirigida === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar el departamento donde desea solicitar un docente.");
                return false;
            }
            if (vm.creacionSolicitud.UaaCodigoSolicitada == '' || vm.creacionSolicitud.UaaCodigoSolicitada === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar la unidad que solicita el docente.");
                return false;
            }
            if (vm.creacionHorarioSolicitud == '' || vm.creacionHorarioSolicitud.length == 0 || vm.creacionHorarioSolicitud === undefined) {
                mostrarSweetAlertWarning("Debe agregar un horario como minimo.");
                return false;
            }
            return true;
        }

        function crearSolicitud() {
            if (!validarCreacionSolicitud()) {
                return false;
            }
            vm.objeto = {
                accion: 3,
                PeriodoCodigo: vm.creacionSolicitud.PeriodoCodigo,
                AsiCodigo: vm.creacionSolicitud.AsiCodigo,
                UaaCodigoDirigida: vm.creacionSolicitud.UaaCodigoDirigida,
                UaaCodigoSolicitada: vm.creacionSolicitud.UaaCodigoSolicitada,
                SedCodigo: vm.creacionSolicitud.SedCodigo,
                HorarioSeleccionado: vm.creacionHorarioSolicitud
            };

            mostrarSweetAlertCargando();

            $http({
                url: "logica/soldoc.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                var salida = response.data;
                if (salida["resultado"] == false) {
                    swal.closeModal();
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                }
                if (salida["resultado"] == true) {
                    // vm.creacionSolicitud = {};
                    vm.creacionHorarioSolicitud = [];
                    vm.seccionFormularioCreacionSolicitud = 0;
                    vm.tipoUnidadesBuscadas = 0;
                    consultarSolicitudesPeriodo(false);
                    vm.seccionListaSolicitudes = 2;
                    mostrarSweetAlertSuccess(salida["mensaje"]);
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function seleccionarUnidadDirigida(unidad) {
            if (vm.tipoUnidadesBuscadas == 1) {
                //Dirigida
                if (vm.tipoFormulario == "creacion") {
                    vm.creacionSolicitud.UaaNombreCortoDirigida = unidad.UaaNombreCorto;
                    vm.creacionSolicitud.UaaCodigoDirigida = unidad.UaaCodigo;
                }

                if (vm.tipoFormulario == "edicion") {
                    vm.edicionSolicitud.UaaDirigidaNombre = unidad.UaaNombreCorto;
                    vm.edicionSolicitud.UaaDirigidaCodigo = unidad.UaaCodigo;
                }

            }
            if (vm.tipoUnidadesBuscadas == 2) {
                //Solicitada
                vm.validarUnidadSeleccionada = true;
                vm.creacionSolicitud.UaaNombreCortoSolicitada = unidad.UaaNombreCorto;
                vm.creacionSolicitud.UaaCodigoSolicitada = unidad.UaaCodigo;
                vm.creacionSolicitud.SedCodigo = unidad.SedCodigo;
                vm.creacionSolicitud.SedNombre = unidad.SedNombre;

                if (vm.tipoFormulario == "creacion") {
                    vm.creacionSolicitud.UaaNombreCortoDirigida = '';
                    vm.creacionSolicitud.UaaCodigoDirigida = '';
                }

            }
            cerrarModal('modalUnidades');
        }

        function consultarUnidades(tipo) {
            vm.filter.Unidad = "";
            if (tipo == 'Dirigida') {
                if (vm.validarUnidadSeleccionada == true){
                    vm.listaUnidades = [];

                    switch (vm.tipoFormulario) {
                        case "creacion":
                            vm.objeto = {
                                accion: 2,
                                UaaCodigoSolicitada: vm.creacionSolicitud.UaaCodigoSolicitada,
                                SedCodigo: vm.creacionSolicitud.SedCodigo
                            };
                            break;
                        case "edicion":
                            vm.objeto = {
                                accion: 2,
                                UaaCodigoSolicitada: vm.edicionSolicitud.UaaSolicitaCodigo,
                                SedCodigo: vm.edicionSolicitud.SedCodigo
                            };
                            break;
                        default:
                            mostrarSweetAlertError("Error, no se selecciono un tipo de formulario.");
                            break;
                    }

                    mostrarSweetAlertCargando();

                    $http({
                        url: "logica/soldoc.php",
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
                            vm.listaUnidades = salida.data;
                            swal.closeModal();
                            abrirModal('modalUnidades');
                            vm.tipoUnidadesBuscadas = 1;
                        }

                    }, function myError(response) {
                        swal.closeModal();
                        mostrarSweetAlertError("Error del servidor, favor recargar la página");
                        console.error(response.data);
                    });
                }
                else{
                    mostrarSweetAlertWarning("Debe seleccionar una unidad solicitante antes de elegir la unidad dirigida.");} 
            }

            if (tipo == 'Solicita') {
                vm.listaUnidades = [];
                vm.objeto = {
                    accion: 4
                };
                mostrarSweetAlertCargando();

                $http({
                    url: "logica/curcrea.php",
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
                        vm.listaUnidades = salida.data;
                        swal.closeModal();
                        abrirModal('modalUnidades');
                        vm.tipoUnidadesBuscadas = 2;
                    }

                }, function myError(response) {
                    swal.closeModal();
                    mostrarSweetAlertError("Error del servidor, favor recargar la página");
                    console.error(response.data);
                });
            }

        }

        function seleccionarAsignatura(asignatura) {
            if (vm.tipoFormulario == "creacion") {
                vm.creacionSolicitud.AsiNombreCorto = asignatura.AsiNombreCorto;
                vm.creacionSolicitud.AsiNombre = asignatura.AsiNombre;
                vm.creacionSolicitud.AsiCodigo = asignatura.AsiCodigo;
            }

            if (vm.tipoFormulario == "edicion") {
                vm.edicionSolicitud.AsiNombreCorto = asignatura.AsiNombreCorto;
                vm.edicionSolicitud.AsiNombre = asignatura.AsiNombre;
                vm.edicionSolicitud.AsiCodigo = asignatura.AsiCodigo;
            }
            cerrarModal('modalBusquedaAsignatura');
        }

        function buscarAsignatura() {
            if (vm.filtroAsignatura == '' || vm.filtroAsignatura == undefined) {
                mostrarSweetAlertWarning("Debe ingresar el nombre o el código alfanumerico de la asignatura.");
                return false;
            }

            mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 14,
                excluirNucleo: 1,
                filtroAsignatura: vm.filtroAsignatura
            };
            $http({
                url: "logica/buscurso.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                // swal.closeModal();
                var salida = response.data;

                if (salida["resultado"] == false) {
                    swal.closeModal();
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                }
                if (salida["resultado"] == true) {
                    vm.listaAsignaturas = salida.data;
                    swal.closeModal();
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function cancelarCrearSolicitud() {
            vm.creacionSolicitud = {};
            vm.seccionFormularioCreacionSolicitud = 0;
            vm.seccionFormularioEdicionSolicitud = 0;
            vm.seccionListaSolicitudes = 2;
        }

        function formularioCrearSolicitud() {
            // vm.creacionSolicitud = {};
            vm.creacionSolicitud.PeriodoCodigo = vm.periodoSeleccionado;
            vm.seccionListaSolicitudes = 0;
            vm.seccionFormularioCreacionSolicitud = 1;
            consultarSedes();
            vm.tipoFormulario = "creacion";
        }

        function consultarSolicitudesPeriodo(cargando = true) {
            vm.listaSolicitudesPeriodo = [];
            vm.seccionListaSolicitudes = 0;
            vm.seccionFormularioCreacionSolicitud = 0;
            vm.periodoBuscado = vm.periodoSeleccionado;

            vm.objeto = {
                accion: 1,
                PerCodigo: vm.periodoSeleccionado
            };
            if (cargando) { mostrarSweetAlertCargando(); }
            $http({
                url: "logica/soldoc.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                var salida = response.data;
                if (salida["resultado"] == false) {
                    if (cargando) { swal.closeModal(); }
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                }
                else {
                    if (cargando) { swal.closeModal(); }
                    vm.listaSolicitudesPeriodo.realizadas = salida.realizadas;
                    vm.listaSolicitudesPeriodo.dirigidas = salida.dirigidas;
                    vm.menu = 1;
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultarPeriodos() {
            vm.seccionListaSolicitudes = 0;
            vm.listaPeriodos = [];
            vm.periodoSeleccionado = "";

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
            if (accion == 'eliminar_solicitud') {
                mje = "¿Desea eliminar la solicitud seleccionado?";
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
                    if (accion == 'eliminar_solicitud') {
                        eliminarSolicitud(parametros);
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
