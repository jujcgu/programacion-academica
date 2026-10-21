(function () {
    angular
        .module('sipa')
        .controller('SolcambhController', SolcambhController);

    function SolcambhController($http) {
        var vm = this;

        // FILTRO TABLA PRINCIPAL
        vm.estadoOrder = {
            '0': 1,
            '1': 2,
            '2': 3,
            '3': 4,
            '4': 5,
            '5': 6,
            '6': 7,
            '7': 8,
            '8': 9
        };

        //Visualizacion
        vm.secciones = {
            listaSolicitudesGeneral: 0,
            formularioCreacion: 0,
            formularioEdicion: 0,
            formularioCreacionCurso: 0,
            formularioCreacionHorario: 0,
            formularioEdicionHorario: 0
        };
        // vm.seccionListaSolicitudes = 0;

        //Variables
        vm.estadosSolicitud = {
            0: 'Eliminado',
            1: 'Solicitado Planta Fisica',
            2: 'Aprobado Planta Fisica',
            3: 'Rechazado Planta Fisica',
            4: 'Aprobado Vicerrectoria Académica',
            5: 'Rechazado Vicerrectoria Académica',
            6: 'Aprobado Curso Virtual',
            7: 'Solicitado Jefe Programa',
            8: 'Rechazado Jefe Programa',
        };

        vm.listaPeriodos = [];
        vm.listaDias = [];
        vm.listaHoras = [];
        vm.listaCursosProgramados = [];
        vm.listaSolicitudesPeriodo = [];
        vm.creacionSolicitud = {};
        vm.cursoSeleccionado = "";
        vm.horarioSeleccionado = [];
        vm.solicitudSeleccionada = {};
        vm.listaComentarios = [];
        vm.mensajeComentario = '';
        vm.edicionSolicitud = {};
        vm.listaDocentes = [];
        vm.listaDocentesPrestados = [];
        vm.agendaDocente = [];
        vm.vinculacionDocenteFechas = {
            inicio: '',
            fin: ''
        };
        vm.agendaDocenteFechas = {
            inicio: '',
            fin: ''
        };
        vm.periodoActual = '';
        vm.periodosActivos = [];
        vm.periodoBuscado = '';
        vm.moduloDisponibilidadMensaje = 'Consultando disponibilidad del módulo...';
        vm.moduloDisponibilidadHabilitado = false;
        vm.moduloDisponibilidadFechaFin = '';
        vm.moduloDisponibilidadCantidadProgramas = 0;

        //Filtros
        vm.filter = {
            Solicitudes: '',
            Cursos: '',
            Docentes: ''
        };

        //Funciones Declaración
        vm.consultarPeriodos = consultarPeriodos;
        vm.consultarSolicitudesPeriodo = consultarSolicitudesPeriodo;
        vm.consultarCursoDetalle = consultarCursoDetalle;
        vm.formularioCrearSolicitud = formularioCrearSolicitud;
        vm.cancelarCrearSolicitud = cancelarCrearSolicitud;
        vm.seleccionarHorario = seleccionarHorario;
        vm.calcularFechaFin = calcularFechaFin
        vm.agregarHorarioSolicitud = agregarHorarioSolicitud;
        vm.eliminarHorarioTemporal = eliminarHorarioTemporal;
        vm.verificarHorarioSolicitud = verificarHorarioSolicitud;
        vm.crearSolicitud = crearSolicitud;
        vm.consultarComentarios = consultarComentarios;
        vm.agregarComentario = agregarComentario;
        vm.getUserInitials = getUserInitials;
        vm.formularioEditarSolicitud = formularioEditarSolicitud;
        vm.cancelarEdicionSolicitud = cancelarEdicionSolicitud;
        vm.eliminarHorarioSolicitud = eliminarHorarioSolicitud;
        vm.consultaHorarioSolicitud = consultaHorarioSolicitud;
        vm.guardarHorarioSolicitud = guardarHorarioSolicitud;
        vm.reActivarSolicitud = reActivarSolicitud;
        vm.rechazarSolicitud = rechazarSolicitud;
        vm.modalRechazoSolicitud = modalRechazoSolicitud;
        vm.eliminarSolicitud = eliminarSolicitud;
        vm.modalAprobarSolicitud = modalAprobarSolicitud;
        vm.aprobarSolicitud = aprobarSolicitud;
        vm.reiniciarSeleccionado = reiniciarSeleccionado;
        vm.consultarDocentes = consultarDocentes;
        vm.seleccionarDocente = seleccionarDocente;
        vm.refrescarDocente = refrescarDocente;
        vm.consultarAgendaDocente = consultarAgendaDocente;
        vm.consultarDocentesPrestados = consultarDocentesPrestados;
        vm.isHorarioSeleccionado = isHorarioSeleccionado;
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
                PtsCodigo: 2
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

        function consultarDocentesPrestados() {
            if (vm.edicionSolicitud.CursoSeleccionado) {
                if (!vm.edicionSolicitud.CursoSeleccionado.CurCodigo || vm.edicionSolicitud.CursoSeleccionado.CurCodigo == "") {
                    mostrarSweetAlertWarning("No se encontro el curso seleccionado.");
                    return false;
                }
                if (!vm.edicionSolicitud.CursoSeleccionado.CalCodigo || vm.edicionSolicitud.CursoSeleccionado.CalCodigo == "") {
                    mostrarSweetAlertWarning("No se encontro el calendario del curso seleccionado.");
                    return false;
                }
                vm.objeto = {
                    accion: 5,
                    CalCodigo: vm.edicionSolicitud.CursoSeleccionado.CalCodigo,
                    CurCodigo: vm.edicionSolicitud.CursoSeleccionado.CurCodigo,
                };
            }

            if (vm.creacionSolicitud.CursoSeleccionado) {
                if (!vm.creacionSolicitud.CursoSeleccionado.CurCodigo || vm.creacionSolicitud.CursoSeleccionado.CurCodigo == "") {
                    mostrarSweetAlertWarning("No se encontro el curso seleccionado.");
                    return false;
                }
                if (!vm.creacionSolicitud.CursoSeleccionado.CalCodigo || vm.creacionSolicitud.CursoSeleccionado.CalCodigo == "") {
                    mostrarSweetAlertWarning("No se encontro el calendario del curso seleccionado.");
                    return false;
                }
                vm.objeto = {
                    accion: 5,
                    CalCodigo: vm.creacionSolicitud.CursoSeleccionado.CalCodigo,
                    CurCodigo: vm.creacionSolicitud.CursoSeleccionado.CurCodigo,
                };
            }

            vm.listaDocentesPrestados = [];

            mostrarSweetAlertCargando();

            $http({
                url: "logica/cambdocente.php",
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
                    vm.listaDocentesPrestados = salida.data;
                    swal.closeModal();
                    abrirModal("modalDocentesPrestados");
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultarAgendaDocente() {

            if (vm.edicionSolicitud.CursoSeleccionado) {
                if (!vm.edicionSolicitud.CursoSeleccionado.UaaCodigo || vm.edicionSolicitud.CursoSeleccionado.UaaCodigo == "") {
                    mostrarSweetAlertWarning("No se encontro la unidad del curso seleccionado.");
                    return false;
                }
                if (!vm.edicionSolicitud.CursoSeleccionado.CalCodigo || vm.edicionSolicitud.CursoSeleccionado.CalCodigo == "") {
                    mostrarSweetAlertWarning("No se encontro el calendario del curso seleccionado.");
                    return false;
                }
                vm.objeto = {
                    accion: 6,
                    UapCodigo: vm.horarioSeleccionado.VinculacionNuevoDocente.UapCodigo,
                    CalCodigo: vm.edicionSolicitud.CursoSeleccionado.CalCodigo,
                    UaaCodigo: vm.edicionSolicitud.CursoSeleccionado.UaaCodigo,
                };
            }
            if (vm.creacionSolicitud.CursoSeleccionado) {
                if (!vm.creacionSolicitud.CursoSeleccionado.UaaCodigo || vm.creacionSolicitud.CursoSeleccionado.UaaCodigo == "") {
                    mostrarSweetAlertWarning("No se encontro la unidad del curso seleccionado.");
                    return false;
                }
                if (!vm.creacionSolicitud.CursoSeleccionado.CalCodigo || vm.creacionSolicitud.CursoSeleccionado.CalCodigo == "") {
                    mostrarSweetAlertWarning("No se encontro el calendario del curso seleccionado.");
                    return false;
                }
                vm.objeto = {
                    accion: 6,
                    UapCodigo: vm.horarioSeleccionado.VinculacionNuevoDocente.UapCodigo,
                    CalCodigo: vm.creacionSolicitud.CursoSeleccionado.CalCodigo,
                    UaaCodigo: vm.creacionSolicitud.CursoSeleccionado.UaaCodigo,
                };
            }


            if (!vm.horarioSeleccionado.VinculacionNuevoDocente || vm.horarioSeleccionado.VinculacionNuevoDocente.UapCodigo == '' || vm.horarioSeleccionado.VinculacionNuevoDocente.UapCodigo === undefined) {
                mostrarSweetAlertWarning("No se encontro el codigo de vinculacion del docente.");
                return false;
            }

            vm.agendaDocente = [];

            vm.agendaDocenteFechas = {
                inicio: '',
                fin: ''
            };

            mostrarSweetAlertCargando();

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
                    vm.agendaDocente = salida.data;
                    vm.agendaDocenteFechas.inicio = salida.fecha_inicial;
                    vm.agendaDocenteFechas.fin = salida.fecha_final;
                    swal.closeModal();
                    abrirModal("modalAgendaDocente");
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });

        }

        function refrescarDocente() {
            if (vm.horarioSeleccionado.NuevoDocente == "") {
                vm.horarioSeleccionado.VinculacionNuevoDocente = {};
            }
        }

        function seleccionarDocente(docente, tipo = 'Propio') {
            vm.horarioSeleccionado.VinculacionNuevoDocente = {};
            vm.horarioSeleccionado.VinculacionNuevoDocente = docente;
            vm.horarioSeleccionado.VinculacionNuevoDocente.Tipo = tipo;
        }

        function consultarDocentes() {

            if (vm.edicionSolicitud.CursoSeleccionado) {
                if (!vm.edicionSolicitud.CursoSeleccionado.UaaCodigo || vm.edicionSolicitud.CursoSeleccionado.UaaCodigo == "") {
                    mostrarSweetAlertWarning("No se encontro la unidad del curso seleccionado.");
                    return false;
                }

                if (!vm.edicionSolicitud.CursoSeleccionado.CalCodigo || vm.edicionSolicitud.CursoSeleccionado.CalCodigo == "") {
                    mostrarSweetAlertWarning("No se encontro el calendario del curso seleccionado.");
                    return false;
                }

                vm.objeto = {
                    accion: 7,
                    UaaCodigo: vm.edicionSolicitud.CursoSeleccionado.UaaCodigo,
                    CalCodigo: vm.edicionSolicitud.CursoSeleccionado.CalCodigo
                };
            }

            if (vm.creacionSolicitud.CursoSeleccionado) {
                if (!vm.creacionSolicitud.CursoSeleccionado.UaaCodigo || vm.creacionSolicitud.CursoSeleccionado.UaaCodigo == "") {
                    mostrarSweetAlertWarning("No se encontro la unidad del curso seleccionado.");
                    return false;
                }

                if (!vm.creacionSolicitud.CursoSeleccionado.CalCodigo || vm.creacionSolicitud.CursoSeleccionado.CalCodigo == "") {
                    mostrarSweetAlertWarning("No se encontro el calendario del curso seleccionado.");
                    return false;
                }

                vm.objeto = {
                    accion: 7,
                    UaaCodigo: vm.creacionSolicitud.CursoSeleccionado.UaaCodigo,
                    CalCodigo: vm.creacionSolicitud.CursoSeleccionado.CalCodigo
                };
            }

            vm.listaDocentes = [];
            vm.vinculacionDocenteFechas = {
                inicio: '',
                fin: ''
            };

            mostrarSweetAlertCargando();

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
                    vm.listaDocentes = salida.data;
                    vm.vinculacionDocenteFechas.inicio = salida.fecha_inicial;
                    vm.vinculacionDocenteFechas.fin = salida.fecha_final;
                    swal.closeModal();
                    abrirModal("modalDocentes");
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function reiniciarSeleccionado() {
            vm.horarioSeleccionado.yaSeleccionado = true;
        }

        function aprobarSolicitud() {
            if (vm.mensajeComentario == '' || vm.mensajeComentario === undefined) {
                mostrarSweetAlertWarning("Debe ingresar el comentario.");
                return false;
            }
            if (vm.mensajeComentario.length <= 5) {
                mostrarSweetAlertWarning("Debe ingresar un comentario con mas contenido.");
                return false;
            }

            var estado = 4;
            vm.objeto = {
                accion: 13,
                SchCodigo: vm.solicitudSeleccionada.SchCodigo,
                UaaCodigo: vm.solicitudSeleccionada.UaaCodigo,
                CurCodigo: vm.solicitudSeleccionada.CurCodigo,
                TicCodigo: vm.solicitudSeleccionada.TicCodigo,
                CurSemanas: vm.solicitudSeleccionada.CurSemanas,
                CambioDocente: vm.solicitudSeleccionada.CambioDocente,
                Horario: vm.solicitudSeleccionada.Horario,
                SchEstado: estado,
                mensajeComentario: vm.mensajeComentario
            };

            // Si el estado es 7 pendiente de aprobacion por jefe de programa
            if (vm.solicitudSeleccionada.SchEstado == 7) {

                // Si el tipo de solicitud es virtual NO pasa a planta fisica.
                if (vm.solicitudSeleccionada.TicCodigo == 2){estado = 6;} else {estado = 1;}

                vm.objeto = {
                    accion: 14,
                    SchCodigo: vm.solicitudSeleccionada.SchCodigo,
                    SchEstado: estado,
                    mensajeComentario: vm.mensajeComentario
                };
            }

            mostrarSweetAlertCargando();

            $http({
                url: "logica/solcambh.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                var salida = response.data;
                if (salida["resultado"] == false) {
                    swal.closeModal();
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                    return false;
                }
                swal.closeModal();
                vm.solicitudSeleccionada = {};
                mostrarSweetAlertSuccess(salida["mensaje"]);
                cerrarModal('modalAprobarSolicitud');
                consultarSolicitudesPeriodo(false);
            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function modalAprobarSolicitud(solicitud) {
            vm.solicitudSeleccionada = {};
            vm.solicitudSeleccionada = solicitud;
            vm.mensajeComentario = '';
            abrirModal('modalAprobarSolicitud');
        }

        function eliminarSolicitud(solicitud) {
            vm.solicitudSeleccionada = {};
            vm.solicitudSeleccionada = solicitud;

            if (!vm.solicitudSeleccionada.SchCodigo || vm.solicitudSeleccionada.SchCodigo == "" || vm.solicitudSeleccionada.SchCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar un solicitud.");
                return false;
            }

            mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 12,
                SchCodigo: vm.solicitudSeleccionada.SchCodigo,
            };

            $http({
                url: "logica/solcambh.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                var salida = response.data;
                if (salida["resultado"] == false) {
                    swal.closeModal();
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                    return false;
                }
                vm.solicitudSeleccionada = {};
                swal.closeModal();
                mostrarSweetAlertSuccess(salida["mensaje"]);
                consultarSolicitudesPeriodo(false);

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function rechazarSolicitud() {
            if (vm.mensajeComentario == '' || vm.mensajeComentario === undefined) {
                mostrarSweetAlertWarning("Debe ingresar el comentario.");
                return false;
            }
            if (vm.mensajeComentario.length <= 5) {
                mostrarSweetAlertWarning("Debe ingresar un comentario con mas contenido.");
                return false;
            }
            vm.objeto = {
                accion: 11,
                SchCodigo: vm.solicitudSeleccionada.SchCodigo,
                SchEstado: 5,
                mensajeComentario: vm.mensajeComentario
            };

            // Si el estado es 7 pendiente de aprobacion por jefe de programa
            if (vm.solicitudSeleccionada.SchEstado == 7) {
                estado = 8; // Rechazado jefe de programa para posteriormente editarla.
                vm.objeto = {
                    accion: 15,
                    SchCodigo: vm.solicitudSeleccionada.SchCodigo,
                    SchEstado: estado,
                    mensajeComentario: vm.mensajeComentario
                };
            }

            mostrarSweetAlertCargando();

            $http({
                url: "logica/solcambh.php",
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
                    vm.solicitudSeleccionada = {};
                    swal.closeModal();
                    cerrarModal('modalRechazoSolicitud');
                    mostrarSweetAlertSuccess(salida["mensaje"]);
                    consultarSolicitudesPeriodo(false);
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function modalRechazoSolicitud(solicitud) {
            vm.solicitudSeleccionada = {};
            vm.solicitudSeleccionada = solicitud;
            vm.mensajeComentario = '';
            abrirModal('modalRechazoSolicitud');
        }

        function reActivarSolicitud() {
            if (!vm.edicionSolicitud.SchCodigo || vm.edicionSolicitud.SchCodigo == "" || vm.edicionSolicitud.SchCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar un solicitud.");
                return false;
            }

            mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 10,
                SchCodigo: vm.edicionSolicitud.SchCodigo,
                TicCodigo: vm.edicionSolicitud.TicCodigo,
                EspDeportivo: vm.edicionSolicitud.EspDeportivo,
                CambioDocente: vm.horarioSeleccionado.NuevoDocente,
            };

            $http({
                url: "logica/solcambh.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                var salida = response.data;
                if (salida["resultado"] == false) {
                    swal.closeModal();
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                    return false;
                }
                vm.creacionSolicitud = {};
                vm.horarioSeleccionado = [];
                swal.closeModal();
                mostrarSweetAlertSuccess(salida["mensaje"]);
                consultarSolicitudesPeriodo(false);

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function guardarHorarioSolicitud() {
            if (!vm.edicionSolicitud.SchCodigo || vm.edicionSolicitud.SchCodigo == "" || vm.edicionSolicitud.SchCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar un solicitud.");
                return false;
            }
            if (!vm.horarioSeleccionado.EsoSubGrupo || vm.horarioSeleccionado.EsoSubGrupo == "" || vm.horarioSeleccionado.EsoSubGrupo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar un horario valido para cambiar.");
                return false;
            }

            mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 9,
                SchCodigo: vm.edicionSolicitud.SchCodigo,
                CambioDocente: vm.horarioSeleccionado.NuevoDocente,
                CurCodigo: vm.edicionSolicitud.CursoSeleccionado.CurCodigo,
                NuevoHorario: vm.horarioSeleccionado,
                TicCodigo: vm.edicionSolicitud.TicCodigo
            };

            $http({
                url: "logica/solcambh.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                var salida = response.data;
                if (salida["resultado"] == false) {
                    swal.closeModal();
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                    return false;
                }
                vm.horarioSeleccionado.fechaInicial = "";
                vm.horarioSeleccionado.fechaFinal = "";
                vm.horarioSeleccionado.diaNuevo = "";
                vm.horarioSeleccionado.horaNuevo = "";
                vm.horarioSeleccionado.cruceEstudiantes = true;
                vm.horarioSeleccionado.cruceDocente = true;
                swal.closeModal();
                mostrarSweetAlertSuccess(salida["mensaje"]);
                consultaHorarioSolicitud(vm.edicionSolicitud.SchCodigo);

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function eliminarHorarioSolicitud(Horario) {
            if (Horario.SchCodigo == '' || Horario.SchCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar una solicitud valida.");
                return false;
            }
            if (Horario.SchhCodigo == '' || Horario.SchhCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar un horario de solicitud valido.");
                return false;
            }

            vm.objeto = {
                accion: 7,
                SchCodigo: Horario.SchCodigo,
                SchhCodigo: Horario.SchhCodigo
            };

            mostrarSweetAlertCargando();

            $http({
                url: "logica/solcambh.php",
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
                    mostrarSweetAlertSuccess(salida["mensaje"]);
                    consultaHorarioSolicitud(Horario.SchCodigo);
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultaHorarioSolicitud(SchCodigo) {
            if (SchCodigo == '' || SchCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar una solicitud valida.");
                return false;
            }

            vm.objeto = {
                accion: 8,
                SchCodigo: SchCodigo
            };

            $http({
                url: "logica/solcambh.php",
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
                    vm.edicionSolicitud.Horario = salida["data"];
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function cancelarEdicionSolicitud() {
            vm.secciones.listaSolicitudesGeneral = 1;
            vm.secciones.formularioCreacion = 0;
            vm.secciones.formularioEdicion = 0;

            vm.secciones.formularioCreacionCurso = 0;
            vm.secciones.formularioCreacionHorario = 0;
            vm.secciones.formularioEdicionHorario = 0;

            vm.edicionSolicitud = {};
            vm.horarioSeleccionado = [];
            vm.cursoSeleccionado = "";
        }

        function formularioEditarSolicitud(solicitud) {
            vm.edicionSolicitud = {};
            vm.edicionSolicitud = solicitud;
            vm.secciones.listaSolicitudesGeneral = 0;
            vm.secciones.formularioCreacion = 0;
            vm.secciones.formularioEdicionHorario = 0;
            vm.secciones.formularioEdicion = 1;
            consultarCursoDetalle("Edicion");
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
                accion: 6,
                SchCodigo: vm.solicitudSeleccionada.SchCodigo,
                mensajeComentario: vm.mensajeComentario
            };

            mostrarSweetAlertCargando();

            $http({
                url: "logica/solcambh.php",
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
                    mostrarSweetAlertSuccess(salida["mensaje"]);
                    consultarComentarios(vm.solicitudSeleccionada, false);
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultarComentarios(solicitud, cargar = true) {
            vm.listaComentarios = [];
            vm.solicitudSeleccionada = solicitud;

            vm.objeto = {
                accion: 5,
                SchCodigo: vm.solicitudSeleccionada.SchCodigo
            };
            if (cargar) { mostrarSweetAlertCargando(); };
            $http({
                url: "logica/solcambh.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                var salida = response.data;
                if (salida["resultado"] == false) {
                    if (cargar) { swal.closeModal(); };
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                }
                else {
                    if (cargar) { swal.closeModal(); };
                    vm.listaComentarios = salida.data;
                    abrirModal('modalComentariosSolicitud');
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function cancelarCrearSolicitud() {
            vm.secciones.listaSolicitudesGeneral = 1;
            vm.secciones.formularioCreacion = 0;
            vm.secciones.formularioEdicion = 0;

            vm.secciones.formularioCreacionCurso = 0;
            vm.secciones.formularioCreacionHorario = 0;
            vm.secciones.formularioEdicionHorario = 0;

            vm.creacionSolicitud = {};
            vm.horarioSeleccionado = [];
            vm.cursoSeleccionado = "";
        }

        function crearSolicitud() {
            if (vm.creacionSolicitud.NuevoHorario === undefined || vm.creacionSolicitud.NuevoHorario.length <= 0) {
                mostrarSweetAlertWarning("No se ha agregado un horario nuevo a la solicitud.");
                return false;
            }

            if (!vm.creacionSolicitud.CursoSeleccionado.CurCodigo || vm.creacionSolicitud.CursoSeleccionado.CurCodigo == "") {
                mostrarSweetAlertWarning("No se encontro el codigo del curso.");
                return false;
            }

            if (!vm.creacionSolicitud.CursoSeleccionado.TicCodigo || vm.creacionSolicitud.CursoSeleccionado.TicCodigo == "") {
                mostrarSweetAlertWarning("No se encontro el codigo del curso.");
                return false;
            }

            if (!vm.creacionSolicitud.EspDeportivo || vm.creacionSolicitud.EspDeportivo == "") {
                mostrarSweetAlertWarning("Debe seleccionar si va a solicitar cambio a un espacio deportivo.");
                return false;
            }

            if (!vm.horarioSeleccionado.EsoSubGrupo || vm.horarioSeleccionado.EsoSubGrupo == "" || vm.horarioSeleccionado.EsoSubGrupo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar un horario antiguo para cambiar.");
                return false;
            }

            mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 3,
                CurCodigo: vm.creacionSolicitud.CursoSeleccionado.CurCodigo,
                TicCodigo: vm.creacionSolicitud.CursoSeleccionado.TicCodigo,
                EspDeportivo: vm.creacionSolicitud.EspDeportivo,
                NuevoHorario: vm.creacionSolicitud.NuevoHorario
            };

            $http({
                url: "logica/solcambh.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                var salida = response.data;
                if (salida["resultado"] == false) {
                    swal.closeModal();
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                    return false;
                }
                vm.creacionSolicitud = {};
                vm.horarioSeleccionado = [];
                swal.closeModal();
                mostrarSweetAlertSuccess(salida["mensaje"]);
                consultarSolicitudesPeriodo();

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function verificarHorarioSolicitud(Tipo = "Creacion") {
            vm.horarioSeleccionado.yaSeleccionado = false;
            if (Tipo == "Creacion") {
                if (!vm.creacionSolicitud.CursoSeleccionado || vm.creacionSolicitud.CursoSeleccionado == "") {
                    mostrarSweetAlertWarning("No se ha seleccionado ningun curso.");
                    return false;
                }
                if (!vm.creacionSolicitud.CursoSeleccionado.CurCodigo || vm.creacionSolicitud.CursoSeleccionado.CurCodigo == "") {
                    mostrarSweetAlertWarning("No se encontro el codigo del curso.");
                    return false;
                }
                if (!vm.creacionSolicitud.CursoSeleccionado.CurSemanas || vm.creacionSolicitud.CursoSeleccionado.CurSemanas == "") {
                    mostrarSweetAlertWarning("No se encontro la cantidad de semanas.");
                    return false;
                }

                if (!vm.horarioSeleccionado.horaNuevo || vm.horarioSeleccionado.horaNuevo == "") {
                    mostrarSweetAlertWarning("Debe seleccionar una hora valida.");
                    return false;
                }

                if (vm.creacionSolicitud.NuevoHorario && vm.creacionSolicitud.NuevoHorario.length > 0) {
                    var yaSeleccionado = vm.creacionSolicitud.NuevoHorario.find(
                        objeto => objeto.diaNuevo.DiaCodigo == vm.horarioSeleccionado.diaNuevo.DiaCodigo && objeto.horaNuevo.HraCodigo == vm.horarioSeleccionado.horaNuevo.HraCodigo
                    );
                    if (yaSeleccionado !== undefined) {
                        mostrarSweetAlertWarning("Este horario ya ha sido seleccionado previamente.");
                        vm.horarioSeleccionado.yaSeleccionado = true;
                        return false;
                    }
                }
            }

            if (Tipo == "Edicion") {
                if (!vm.edicionSolicitud.CursoSeleccionado || vm.edicionSolicitud.CursoSeleccionado == "") {
                    mostrarSweetAlertWarning("No se ha seleccionado ningun curso.");
                    return false;
                }
                if (!vm.edicionSolicitud.CursoSeleccionado.CurCodigo || vm.edicionSolicitud.CursoSeleccionado.CurCodigo == "") {
                    mostrarSweetAlertWarning("No se encontro el codigo del curso.");
                    return false;
                }
                if (!vm.edicionSolicitud.CursoSeleccionado.CurSemanas || vm.edicionSolicitud.CursoSeleccionado.CurSemanas == "") {
                    mostrarSweetAlertWarning("No se encontro la cantidad de semanas.");
                    return false;
                }
                if (!vm.horarioSeleccionado.horaNuevo || vm.horarioSeleccionado.horaNuevo == "") {
                    mostrarSweetAlertWarning("Debe seleccionar una hora valida.");
                    return false;
                }

                if (vm.edicionSolicitud.Horario && vm.edicionSolicitud.Horario.length > 0) {
                    var yaSeleccionado = vm.edicionSolicitud.Horario.find(
                        objeto => objeto.DiaNuevoCodigo == vm.horarioSeleccionado.diaNuevo.DiaCodigo && objeto.HraNuevoCodigo == vm.horarioSeleccionado.horaNuevo.HraCodigo
                    );
                    if (yaSeleccionado !== undefined) {
                        mostrarSweetAlertWarning("Este horario ya ha sido seleccionado previamente.");
                        vm.horarioSeleccionado.yaSeleccionado = true;
                        return false;
                    }
                }
            }

            if (!vm.horarioSeleccionado.EsoSubGrupo || vm.horarioSeleccionado.EsoSubGrupo == "" || vm.horarioSeleccionado.EsoSubGrupo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar un horario antiguo para cambiar.");
                return false;
            }

            if (!vm.horarioSeleccionado.fechaInicial || vm.horarioSeleccionado.fechaInicial == "" || vm.horarioSeleccionado.fechaInicial === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar una fecha de inicio.");
                return false;
            }

            if (!vm.horarioSeleccionado.fechaFinal || vm.horarioSeleccionado.fechaFinal == "" || vm.horarioSeleccionado.fechaFinal === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar una fecha de fin.");
                return false;
            }

            if (!vm.horarioSeleccionado.diaNuevo || vm.horarioSeleccionado.diaNuevo === undefined || vm.horarioSeleccionado.diaNuevo == "") {
                mostrarSweetAlertWarning("Debe seleccionar un dia nuevo.");
                return false;
            }

            if (!vm.horarioSeleccionado.horaNuevo || vm.horarioSeleccionado.horaNuevo === undefined || vm.horarioSeleccionado.horaNuevo == "") {
                mostrarSweetAlertWarning("Debe seleccionar una hora nueva.");
                return false;
            }

            vm.horarioSeleccionado.cruceEstudiantes = true;
            vm.horarioSeleccionado.cruceDocente = true;

            mostrarSweetAlertCargando();

            if (vm.horarioSeleccionado.VinculacionNuevoDocente && vm.horarioSeleccionado.VinculacionNuevoDocente.Tipo == 'Prestado') {
                if (vm.horarioSeleccionado.VinculacionNuevoDocente.Horario.length <= 0) {
                    mostrarSweetAlertWarning("El docente prestado no cuenta con horario permitido.");
                    return false;
                }
                var hayCombinacion = false;
                vm.horarioSeleccionado.VinculacionNuevoDocente.Horario.forEach(element => {
                    var existeCombinacion = element.DiaCodigo === vm.horarioSeleccionado.diaNuevo.DiaCodigo && element.HraCodigo === vm.horarioSeleccionado.horaNuevo.HraCodigo
                    if (!hayCombinacion && existeCombinacion) {
                        hayCombinacion = true;
                    }
                });
                if (!hayCombinacion) {
                    mostrarSweetAlertWarning("Horario seleccionado no disponible para el docente aprobado.");
                    return false;
                }
            }

            var UapCodigo = vm.horarioSeleccionado.UapCodigo;
            var cambioDocente = 0;
            if (vm.horarioSeleccionado.VinculacionNuevoDocente && vm.horarioSeleccionado.VinculacionNuevoDocente.UapCodigo) {
                UapCodigo = vm.horarioSeleccionado.VinculacionNuevoDocente.UapCodigo;
                cambioDocente = 1;
            }

            if (
                vm.horarioSeleccionado.VinculacionNuevoDocente &&
                vm.horarioSeleccionado.VinculacionNuevoDocente.UapCodigo === vm.horarioSeleccionado.UapCodigo
            ) {
                mostrarSweetAlertWarning("El docente que intenta asignar es el mismo que ya está actualmente asignado.");
                return false;
            }

            if (Tipo == "Creacion") {
                vm.objeto = {
                    accion: 2,
                    CurCodigo: vm.creacionSolicitud.CursoSeleccionado.CurCodigo,
                    EsoSubGrupo: vm.horarioSeleccionado.EsoSubGrupo,
                    diaAnterior: vm.horarioSeleccionado.DiaCodigo,
                    horaAnterior: vm.horarioSeleccionado.HraCodigo,
                    diaNuevo: vm.horarioSeleccionado.diaNuevo,
                    horaNuevo: vm.horarioSeleccionado.horaNuevo,
                    CurSemanas: vm.creacionSolicitud.CursoSeleccionado.CurSemanas,
                    fechaInicial: vm.creacionSolicitud.fechaInicial,
                    fechaFinal: vm.creacionSolicitud.fechaFinal,
                    UapCodigo: UapCodigo,
                    cruceEstudiantes: vm.horarioSeleccionado.cruceEstudiantes,
                    cruceDocente: vm.horarioSeleccionado.cruceDocente,
                    PeriodoCodigo: vm.creacionSolicitud.CursoSeleccionado.PeriodoCodigo,
                    cambioDocente: cambioDocente
                };
            }

            if (Tipo == "Edicion") {
                vm.objeto = {
                    accion: 2,
                    // Se envia para que la validacion de solicitud existente no cuente los horarios
                    // que esta misma solicitud ya tiene guardados.
                    SchCodigo: vm.edicionSolicitud.SchCodigo,
                    CurCodigo: vm.edicionSolicitud.CursoSeleccionado.CurCodigo,
                    EsoSubGrupo: vm.horarioSeleccionado.EsoSubGrupo,
                    diaAnterior: vm.horarioSeleccionado.DiaCodigo,
                    horaAnterior: vm.horarioSeleccionado.HraCodigo,
                    diaNuevo: vm.horarioSeleccionado.diaNuevo,
                    horaNuevo: vm.horarioSeleccionado.horaNuevo,
                    CurSemanas: vm.edicionSolicitud.CursoSeleccionado.CurSemanas,
                    fechaInicial: vm.edicionSolicitud.fechaInicial,
                    fechaFinal: vm.edicionSolicitud.fechaFinal,
                    UapCodigo: UapCodigo,
                    cruceEstudiantes: vm.horarioSeleccionado.cruceEstudiantes,
                    cruceDocente: vm.horarioSeleccionado.cruceDocente,
                    PeriodoCodigo: vm.edicionSolicitud.CursoSeleccionado.PeriodoCodigo,
                    cambioDocente: cambioDocente,
                };
            }


            $http({
                url: "logica/solcambh.php",
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
                    if (salida["cruceDocente"]) {
                        mostrarSweetAlertError(salida["mensajeCruceDocente"]);
                        return false;
                    }
                    if (salida["cruceEstudiantes"]) {
                        mostrarSweetAlertError(salida["mensajeCruceEstudiante"]);
                        return false;
                    }
                    if (salida["solicitudExistente"]) {
                        mostrarSweetAlertError(salida["mensajeSolicitudExistente"]);
                        return false;
                    }
                    mostrarSweetAlertSuccess(salida["mensajeCruceDocente"] + " " + salida["mensajeCruceEstudiante"]);
                    vm.horarioSeleccionado.cruceEstudiantes = salida["cruceEstudiantes"];
                    vm.horarioSeleccionado.cruceDocente = salida["cruceDocente"];
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function eliminarHorarioTemporal(horarioNuevo) {
            if (vm.creacionSolicitud && vm.creacionSolicitud.NuevoHorario && Array.isArray(vm.creacionSolicitud.NuevoHorario)) {
                vm.creacionSolicitud.NuevoHorario = vm.creacionSolicitud.NuevoHorario.filter(obj => obj.id !== horarioNuevo.id);
            } else {
            }
        }

        function agregarHorarioSolicitud(Tipo = "Creacion") {

            if (Tipo == "Creacion") {
                if (!vm.creacionSolicitud.CursoSeleccionado.CurSemanas || vm.creacionSolicitud.CursoSeleccionado.CurSemanas == "") {
                    mostrarSweetAlertWarning("No se encontro la cantidad de semanas.");
                    return false;
                }
            }
        
            if (Tipo == "Edicion") {
                if (!vm.edicionSolicitud.CursoSeleccionado.CurSemanas || vm.edicionSolicitud.CursoSeleccionado.CurSemanas == "") {
                    mostrarSweetAlertWarning("No se encontro la cantidad de semanas.");
                    return false;
                }
            }
        
            if (!vm.horarioSeleccionado.EsoSubGrupo || vm.horarioSeleccionado.EsoSubGrupo == "" || vm.horarioSeleccionado.EsoSubGrupo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar un horario antiguo para cambiar.");
                return false;
            }
        
            if (!vm.horarioSeleccionado.fechaInicial || vm.horarioSeleccionado.fechaInicial == "" || vm.horarioSeleccionado.fechaInicial === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar una fecha de inicio.");
                return false;
            }
        
            if (!vm.horarioSeleccionado.fechaFinal || vm.horarioSeleccionado.fechaFinal == "" || vm.horarioSeleccionado.fechaFinal === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar una fecha de fin.");
                return false;
            }
        
            if (!vm.horarioSeleccionado.diaNuevo || vm.horarioSeleccionado.diaNuevo === undefined || vm.horarioSeleccionado.diaNuevo == "") {
                mostrarSweetAlertWarning("Debe seleccionar un dia nuevo.");
                return false;
            }
        
            if (!vm.horarioSeleccionado.horaNuevo || vm.horarioSeleccionado.horaNuevo === undefined || vm.horarioSeleccionado.horaNuevo == "") {
                mostrarSweetAlertWarning("Debe seleccionar una hora nueva.");
                return false;
            }
        
            vm.horarioSeleccionado.cruceEstudiantes = true;
            vm.horarioSeleccionado.cruceDocente = true;
            var { id, EsoSubGrupo, DiaCodigo, HraCodigo, UapCodigo, diaNuevo, horaNuevo } = vm.horarioSeleccionado;
        
            if (Tipo == "Creacion") {
                if (vm.creacionSolicitud.NuevoHorario && vm.creacionSolicitud.NuevoHorario.length > 0) {
                    var horarioEncontrado = vm.creacionSolicitud.NuevoHorario.find(
                        objeto => objeto.id == id
                    );
                    if (horarioEncontrado === undefined) {
                        // Se agrega el horario y lo marca como "Seleccionado"
                        vm.creacionSolicitud.NuevoHorario.push({ ...vm.horarioSeleccionado, seleccionado: true });
                    } else {
                        mostrarSweetAlertWarning("Este horario ya tiene asignado un horario nuevo, por favor eliminelo si desea cambiarlo.");
                        return false;
                    }
                } else {
                    // Se agrega el horario y lo marca como "Seleccionado"
                    vm.creacionSolicitud.NuevoHorario.push({ ...vm.horarioSeleccionado, seleccionado: true });
                }
            }
        
            if (Tipo == "Edicion") {
                if (vm.edicionSolicitud.Horario && vm.edicionSolicitud.Horario.length > 0) {
                    var horarioEncontrado = vm.edicionSolicitud.Horario.find(
                        objeto => objeto.id == id
                    );
                    if (horarioEncontrado === undefined) {
                        guardarHorarioSolicitud();
                    } else {
                        mostrarSweetAlertWarning("Este horario ya tiene asignado un horario nuevo, por favor eliminelo si desea cambiarlo.");
                        return false;
                    }
                } else {
                    guardarHorarioSolicitud();
                }
            }
        }

        function calcularFechaFin(Semana) {
            if (!Semana || Semana == "") {
                mostrarSweetAlertWarning("No se encontro la cantidad de semanas.");
                return false;
            }

            let semanas = Semana;
            let fecha = new Date(vm.horarioSeleccionado.fechaInicial);
            fecha.setDate(fecha.getDate() + (semanas * 7) - 6);
            vm.horarioSeleccionado.fechaFinal = fecha.getFullYear() + '-' + (("0" + (fecha.getMonth() + 1)).slice(-2)) + '-' + ("0" + fecha.getDate()).slice(-2);


            var diaSemana = fecha.getDay();
            var DiaCodigo = (diaSemana === 0) ? 7 : diaSemana;
            var arregloDia = vm.listaDias.find(function (dia) {
                return dia.DiaCodigo == DiaCodigo;
            });

            if (arregloDia === undefined) {
                mostrarSweetAlertWarning("No se encontro el dia para la fecha " + fecha + ".");
            }
            vm.horarioSeleccionado.diaNuevo = arregloDia;
        }

        function seleccionarHorario(Horario) {

            // Verificar si ya existe un horario agregado a la solicitud y si es del mismo subgrupo, si no no lo permite.
            // La idea es que solo se permita un subgrupo por solicitud.
            if (vm.creacionSolicitud.length > 0) {
                if (vm.creacionSolicitud.NuevoHorario & vm.creacionSolicitud.NuevoHorario.length > 0) {
                    if (vm.creacionSolicitud?.NuevoHorario.some(objeto => objeto.EsoSubGrupo !== Horario.EsoSubGrupo)) {
                        alert("Solo se permite un subgrupo por cada solicitud, para solicitar el cambio de horario de un subgrupo diferente debe crear una nueva solicitud.");
                        return false;
                    }
                }
            }
            if (vm.edicionSolicitud.CurCodigo != "") {
                if (vm.edicionSolicitud.Horario && vm.edicionSolicitud.Horario.length > 0) {
                    if (vm.edicionSolicitud?.Horario.some(objeto => objeto.SchhSubgrupo !== Horario.EsoSubGrupo)) {
                        alert("Solo se permite un subgrupo por cada solicitud, para solicitar el cambio de horario de un subgrupo diferente debe crear una nueva solicitud.");
                        return false;
                    }
                }
            }
            mostrarSweetAlertCargando();
            vm.horarioSeleccionado = [];
            vm.horarioSeleccionado = Horario;
            vm.horarioSeleccionado.id = Horario.EsoSubGrupo + Horario.DiaCodigo + Horario.HraCodigo + Horario.UapCodigo;
            vm.horarioSeleccionado.fechaInicial = vm.horarioSeleccionado.EsoFechaInicio;
            vm.horarioSeleccionado.cruceEstudiantes = true;
            vm.horarioSeleccionado.cruceDocente = true;
            swal.closeModal();
            vm.secciones.formularioCreacionHorario = 1;
            vm.secciones.formularioEdicionHorario = 1;

            if (vm.creacionSolicitud.CursoSeleccionado) {
                calcularFechaFin(vm.creacionSolicitud.CursoSeleccionado.CurSemanas);
            }
            if (vm.edicionSolicitud.CursoSeleccionado) {
                calcularFechaFin(vm.edicionSolicitud.CursoSeleccionado.CurSemanas);
            }
        }

        function consultarCursoDetalle(tipo = "Creacion") {
            var CurCodigo = ""
            vm.horarioSeleccionado = [];
            if (tipo == "Creacion") {
                if (!vm.cursoSeleccionado || vm.cursoSeleccionado == "" || !esEntero(vm.cursoSeleccionado)) {
                    mostrarSweetAlertWarning("El código del curso no debe contener letras ni espacios en blanco y solo debe ser numérico.");
                }

                vm.creacionSolicitud.CursoSeleccionado = [];
                vm.creacionSolicitud.NuevoHorario = [];
                vm.creacionSolicitud.CursoSeleccionado.CurCodigo = vm.cursoSeleccionado;
                vm.creacionSolicitud.EspDeportivo = "0";
                vm.secciones.listaSolicitudesGeneral = 0;
                vm.secciones.formularioCreacionCurso = 0;
                vm.secciones.formularioCreacionHorario = 0;
                CurCodigo = vm.creacionSolicitud.CursoSeleccionado.CurCodigo;
            }

            if (tipo == "Edicion") {
                vm.edicionSolicitud.CursoSeleccionado = [];
                // vm.edicionSolicitud.Horario = [];
                CurCodigo = vm.edicionSolicitud.CurCodigo;

            }

            vm.objeto = {
                accion: 1,
                CurCodigo: CurCodigo,
                PerCodigo: vm.periodoSeleccionado
            };
            mostrarSweetAlertCargando();
            $http({
                url: "logica/solcambh.php",
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
                    if (tipo == "Creacion") {
                        vm.creacionSolicitud.CursoSeleccionado = salida.data;
                        vm.secciones.formularioCreacionCurso = 1;
                    }

                    if (tipo == "Edicion") {
                        vm.edicionSolicitud.CursoSeleccionado = salida.data;
                    }
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultarSolicitudesPeriodo(cargando = true) {
            vm.secciones.listaSolicitudesGeneral = 0;
            vm.secciones.formularioCreacion = 0;
            vm.secciones.formularioEdicion = 0;
            vm.secciones.formularioCreacionCurso = 0;
            vm.secciones.formularioCreacionHorario = 0;
            vm.listaSolicitudesPeriodo = [];
            vm.periodoBuscado = vm.periodoSeleccionado;

            vm.objeto = {
                accion: 4,
                PerCodigo: vm.periodoSeleccionado
            };
            if (cargando) { mostrarSweetAlertCargando(); }
            $http({
                url: "logica/solcambh.php",
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
                    vm.secciones.listaSolicitudesGeneral = 1;
                    vm.listaSolicitudesPeriodo = salida.data;
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function formularioCrearSolicitud() {

            var periodo = vm.listaPeriodos.find(function (elemento) {
                return elemento.PerCodigo === vm.periodoSeleccionado;
            });

            vm.creacionSolicitud.PeriodoCodigo = periodo.PerCodigo;
            vm.creacionSolicitud.PeriodoAnio = periodo.PerAnio;
            vm.creacionSolicitud.PeriodoPeriodo = periodo.PerPeriodo;

            vm.secciones.listaSolicitudesGeneral = 0;
            vm.secciones.formularioEdicion = 0;
            vm.secciones.formularioCreacion = 1;
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

        function consultarPeriodos() {
            // vm.seccionListaSolicitudes = 0;
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
            if (accion == 'crear_solicitud') {
                mje = "¿Desea crear la solicitud de cambio de horario?";
                textBtn = "Crear";
            }
            if (accion == 'reactivar_solicitud') {
                mje = "¿Desea re activar la solicitud de cambio de horario?";
                textBtn = "Re activar";
            }
            if (accion == 'rechazar_solicitud') {
                mje = "¿Desea rechazar la solicitud de cambio de horario?";
                textBtn = "Rechazar";
            }
            if (accion == 'eliminar_solicitud') {
                mje = "¿Desea eliminar la solicitud de cambio de horario?";
                textBtn = "Eliminar";
            }
            if (accion == 'aprobar_solicitud') {
                mje = "¿Desea aprobar la solicitud de cambio de horario?";
                textBtn = "Aprobar";
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
                    if (accion == 'crear_solicitud') {
                        vm.crearSolicitud();
                    }
                    if (accion == 'reactivar_solicitud') {
                        vm.reActivarSolicitud();
                    }
                    if (accion == 'rechazar_solicitud') {
                        vm.rechazarSolicitud();
                    }
                    if (accion == 'eliminar_solicitud') {
                        vm.eliminarSolicitud(parametros);
                    }
                    if (accion == 'aprobar_solicitud') {
                        vm.aprobarSolicitud();
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

        function isHorarioSeleccionado(horario) {
            return vm.creacionSolicitud.NuevoHorario.some(
                objeto => objeto.id === (horario.EsoSubGrupo + horario.DiaCodigo + horario.HraCodigo + horario.UapCodigo) && objeto.seleccionado === true
            );
        }

    }

})();
