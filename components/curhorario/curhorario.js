(function () {
    angular
        .module('sipa')
        .controller('CurhorarioController', CurhorarioController);

    function CurhorarioController($http, $rootScope) {
        var vm = this;
        //Visualizacion
        vm.sinCalendario = 0;
        vm.btnBuscarCursos = 0;
        vm.seccionCursos = 0;
        vm.informacionCursos = 0;
        vm.informacionHorario = 0;
        vm.tipoOperacion = ''; //creacion, edicion
        vm.creacionHorario = 0;
        vm.btnEspaciosAsignados = 0;
        vm.filtroEstadoCalendario = 'PRINCIPAL';

        //Variables
        vm.mensajeVerificarHorasCaracter = "Validando...";
        vm.listaSedes = [];
        vm.listaFacultades = [];
        vm.listaCalendarios = [];
        vm.listaAsignaturas = [];
        vm.listaUnidadesUnificadas = [];
        vm.listaCursos = [];
        vm.listaDocentes = [];
        vm.listaTipoCurso = [];
        vm.listaPlanesAcademicos = [];
        vm.calendarioSeleccion = {};
        vm.agendaDocente = [];
        vm.agendaDocenteFechas = {
            inicio: '',
            fin: ''
        };
        vm.cargaDocente = {};
        vm.listaPlanExclusivo = [];
        vm.listaEspacios = [];
        vm.listaEspaciosVirtuales = [];
        vm.tipoListaEspacios = '';
        vm.resumenEspacios = {
            disponibles: 0,
            sinDisponibilidad: 0,
            sinConsultar: 0
        };
        vm.filtroDisponibilidadEspacios = 'todos';
        vm.listaDias = [];
        vm.listaHoras = [];
        vm.agendaEspacios = [];
        vm.listaHorarioSeleccionado = [];
        vm.listaDocentesPrestados = [];
        vm.uaaProgramada = "";
        vm.AsignaturasEspeciales = [
            'BEEDEA01',
            'BEEDEA02',
            'BEEDEA06',
            'BEEDEA07',
            'BEEDEA11',
            'BEEDEA15',
            'BEEDEA16',
            'BEEDAR15',
            'BEEDAR19',
            'BEEDAR24',
            'BEEDAR25',
            'BEEDAR31',
        ];

        vm.seleccion = {
            Uaa: {
                //Contiene la informacion de la unidad que seleccion para programar.
            },
            Calendario: {
                //Contiene la informacion del calendario selecionado para programar.
            },
            Curso: [
                //Contiene la informacion del curso seleccionado.
            ],
            Horario: [
                //Contiene la informacion del horario del curso especifico.
            ],
            EliminarHorario: [
                //Contiene el horario que se va a eliminar.
            ],
            CrearHorario: [
                //Contiene el horario que se va a crear.
            ]
        };


        //Filtros
        vm.filter = {
            Unidad: '',
            Calendario: '',
            Curso: '',
            Asignatura: '',
            PlanAcademico: '',
            Docentes: '',
            Espacios: '',
            AgendaEspacio: '',
            Horario: '',
        }

        //Funciones Declaración
        vm.consultarSedes = consultarSedes;
        vm.consultarFacultades = consultarFacultades;
        vm.consultarCalendarios = consultarCalendarios;
        vm.consultarUnidadesUnificadas = consultarUnidadesUnificadas;
        vm.consultarCurso = consultarCurso;
        vm.consultarDetalleCurso = consultarDetalleCurso;
        vm.consultarAgendaDocente = consultarAgendaDocente;
        vm.consultarAgendaDocenteHorario = consultarAgendaDocenteHorario;
        vm.consultarPlanExclusivo = consultarPlanExclusivo;
        vm.consultarDocentes = consultarDocentes;
        vm.seleccionarDocente = seleccionarDocente;
        vm.mostrarInformacion = mostrarInformacion;

        vm.consultarHorarioCurso = consultarHorarioCurso;
        vm.eliminarHorario = eliminarHorario;
        vm.formularioCrearCurso = formularioCrearCurso;
        vm.calcularFechaFinal = calcularFechaFinal;
        vm.consultarEspaciosAsignados = consultarEspaciosAsignados;
        vm.consultarDisponibilidadEspacio = consultarDisponibilidadEspacio;
        vm.consultarDisponibilidadTodosEspacios = consultarDisponibilidadTodosEspacios;
        vm.consultarEspaciosVirtuales = consultarEspaciosVirtuales;
        vm.seleccionarEspacio = seleccionarEspacio;
        vm.programarHorario = programarHorario;
        vm.consultarEspaciosAsignadosTotal = consultarEspaciosAsignadosTotal;
        vm.actualizarAgenda = actualizarAgenda;
        vm.eliminarHorarioGrupo = eliminarHorarioGrupo;
        vm.seleccionarHorario = seleccionarHorario;
        vm.consultarDocentesPrestados = consultarDocentesPrestados;
        vm.verificarHorasCaracter = verificarHorasCaracter;
        vm.filtrarEspacioPorDisponibilidad = filtrarEspacioPorDisponibilidad;
        vm.cambiarFiltroDisponibilidadEspacios = cambiarFiltroDisponibilidadEspacios;
        vm.alternarDetalleEspacio = alternarDetalleEspacio;
        vm.seleccionarCalendario = seleccionarCalendario;
        vm.filtroCalendarioPorEstado = filtroCalendarioPorEstado;
        vm.contarCalendariosEstado = contarCalendariosEstado;
        vm.hayCalendariosActivos = hayCalendariosActivos;
        vm.hayCalendariosPendientes = hayCalendariosPendientes;

        //Funciones Iniciales
        initial();

        function seleccionarCalendario(calendario) {
            if (esCalendarioRepesca(calendario)) {
                mostrarSweetAlertWarning("La repesca es un proceso interno y no se puede seleccionar.");
                return false;
            }

            if (!calendario || calendario.ActivaAhora != 1) {
                return false;
            }

            vm.seleccion.Calendario = calendario;
            vm.btnBuscarCursos = 1;
            vm.btnEspaciosAsignados = 0;
            return true;
        }

        function esCalendarioRepesca(calendario) {
            if (!calendario) {
                return false;
            }

            var nombreProceso = (calendario.PrpNombre || '').toString().toLowerCase();

            return calendario.PrpCodigo == 4 || nombreProceso.indexOf('repesca') >= 0;
        }

        function filtrarCalendariosSeleccionables(calendarios) {
            if (!calendarios) {
                return [];
            }

            if (Array.isArray(calendarios)) {
                return calendarios.filter(function (calendario) {
                    return !esCalendarioRepesca(calendario);
                });
            }

            return Object.keys(calendarios).map(function (key) {
                return calendarios[key];
            }).filter(function (calendario) {
                return !esCalendarioRepesca(calendario);
            });
        }

        function obtenerListaCalendarios() {
            if (!vm.listaCalendarios) {
                return [];
            }

            if (Array.isArray(vm.listaCalendarios)) {
                return vm.listaCalendarios;
            }

            return Object.keys(vm.listaCalendarios).map(function (key) {
                return vm.listaCalendarios[key];
            });
        }

        function calendarioTieneEstado(calendario, estado) {
            if (!calendario) {
                return false;
            }

            if (estado == 'ACTIVO') {
                return calendario.ActivaAhora == 1;
            }

            if (estado == 'PENDIENTE') {
                return calendario.Pendiente == 1 && calendario.PraEstado == 1;
            }

            if (estado == 'VENCIDO') {
                return calendario.Vencida == 1 && calendario.PraEstado == 1;
            }

            if (estado == 'DESACTIVADO') {
                return calendario.PraEstado == 0;
            }

            return true;
        }

        function hayCalendariosActivos() {
            return contarCalendariosEstado('ACTIVO') > 0;
        }

        function hayCalendariosPendientes() {
            return contarCalendariosEstado('PENDIENTE') > 0;
        }

        function contarCalendariosEstado(estado) {
            return obtenerListaCalendarios().filter(function (calendario) {
                return calendarioTieneEstado(calendario, estado);
            }).length;
        }

        function filtroCalendarioPorEstado(calendario) {
            if (vm.filtroEstadoCalendario == 'TODOS') {
                return true;
            }

            if (vm.filtroEstadoCalendario == 'PRINCIPAL') {
                if (hayCalendariosActivos()) {
                    return calendarioTieneEstado(calendario, 'ACTIVO');
                }

                if (hayCalendariosPendientes()) {
                    return calendarioTieneEstado(calendario, 'PENDIENTE');
                }

                return false;
            }

            return calendarioTieneEstado(calendario, vm.filtroEstadoCalendario);
        }

        function initial() {
            mostrarSweetAlertCargando();
            consultarSedes();
            consultarFacultades();
            consultarUnidadesUnificadas();
            swal.closeModal();
        }

        function verificarHorasSemanales(CarCodigo, SubGrupoNuevo) {

            if ([
                vm.seleccion.Curso[0].AsiHorasSemanalesTeorico,
                vm.seleccion.Curso[0].AsiHorasSemanalesPractica,
                vm.seleccion.Curso[0].AsiHorasSemanalesTeoricoPractico
            ].every(v => v === null || v === undefined || v === '' || v == '0')) {
                return true;
            }
            if (CarCodigo !== undefined || CarCodigo !== '') {
                const totalHorasProgramadas = Array.isArray(vm.seleccion.Horario) ? vm.seleccion.Horario.length : 0;
                const horasNuevas = vm.seleccion.CrearHorario.HorasSeleccionadas.length;

                if (CarCodigo.trim() == 'T') {
                    const totalHoras = totalHorasProgramadas + horasNuevas;
                    if (vm.seleccion.Curso[0].AsiHorasSemanalesTeorico != '' && totalHoras > vm.seleccion.Curso[0].AsiHorasSemanalesTeorico) {
                        const mensajeError = "<b>Importante: </b> La asignatura de caracter <b>T</b> cuenta con un máximo de <b class='text-white bg-green px-1'>" + vm.seleccion.Curso[0].AsiHorasSemanalesTeorico + "</b> hora(s) semanal(es) de Teoria y se detecto que el curso contaria con <b class='text-white bg-red px-1'>" + totalHoras + "</b> hora(s) semanal(es) superando el máximo permitido, por favor verificar.";
                        mostrarSweetAlertWarning(mensajeError);
                        return false;
                    }
                }

                if (CarCodigo.trim() == 'TP') {
                    let mensajeError = `<b>Importante: </b> La asignatura de caracter <b>TP</b> cuenta con un máximo de <b class='text-white bg-green px-1'> ${vm.seleccion.Curso[0].AsiHorasSemanalesTeorico} </b> hora(s) semanal(es) de Teoria y <b class='text-white bg-green px-1'> ${vm.seleccion.Curso[0].AsiHorasSemanalesPractica}</b> hora(s) semanal(es) de de Practica.`;
                    let contadorFaltas = 0;
                    let contadorSubgrupos = {};

                    // Contamos las horas por subgrupo
                    if (Array.isArray(vm.seleccion.Horario)) {
                        vm.seleccion.Horario.forEach(function (elemento) {
                            contadorSubgrupos[elemento.EsoSubGrupo] = (contadorSubgrupos[elemento.EsoSubGrupo] || 0) + 1;
                        });
                    } else {
                        // En caso de que sean las primeras horas a programacion siempre sera 00, se establece con 0 hs
                        contadorSubgrupos['00'] = 0;
                    }

                    // Sumamos las horas del subgrupo que se va a programar
                    if (SubGrupoNuevo == '00') {
                        contadorSubgrupos['00'] += horasNuevas;
                    } else {
                        contadorSubgrupos[SubGrupoNuevo] = (contadorSubgrupos[SubGrupoNuevo] || 0) + horasNuevas;
                    }

                    let subGrupos = Object.keys(contadorSubgrupos);

                    // Verificamos si tiene solamente el subgrupo 00
                    let solo00 = false;
                    if (subGrupos.length === 1 && subGrupos[0] === '00') {
                        // console.log("Solo tiene el subgrupo 00");
                        solo00 = true;
                    }

                    // console.table(contadorSubgrupos);

                    subGrupos.forEach(function (grupo) {
                        // console.log("Evaluando grupo: ", grupo);

                        // Evaluamos los casos en los que es TP pero solo programan 00
                        // En caso de ser solamente 00 se debe sumar las horas maximas teoricas con las de practicas
                        const totalHorasTP = vm.seleccion.Curso[0].AsiHorasSemanalesTeoricoPractico;
                        const topeMayorSolo00 = totalHorasTP > vm.seleccion.Curso[0].AsiHorasSemanalesTeorico ? totalHorasTP : vm.seleccion.Curso[0].AsiHorasSemanalesTeorico;
                        const gastoTodasHorasEn00 = contadorSubgrupos['00'] == totalHorasTP ? true : false; // Verificamos si las horas del 00 es igual al total de creditos TP

                        // Validamos si es 00, si tiene subgrupos 01 y si ya gasto todas las horas en el 00
                        if (!solo00 && grupo == '00' && gastoTodasHorasEn00) {
                            // console.log("gastoTodasHorasEn 00 y excede las horas totales de TP", vm.seleccion.Curso[0].AsiHorasSemanalesPractica, grupo, contadorSubgrupos[grupo] );
                            mensajeError += `<br> Solo se encontro el subgrupo 00 y cuenta con <b class='text-white bg-red px-1'>${contadorSubgrupos[grupo]} </b> hora(s) semanal(es), deben programar un máximo de <b class='text-white bg-warning px-1'> ${totalHorasTP} </b> hora(s) <b>TP</b> semanal(es) si solo se programará 00 o un maximo de <b class='text-white bg-warning px-1'> ${vm.seleccion.Curso[0].AsiHorasSemanalesTeorico} </b> horas(s) <b>T</b> semanal(es) si va a incluir subgrupos.`;
                            contadorFaltas++;
                        }

                        // Validamos si es solo 00, obtenemos cual tope de horas toma, si T o TP total, y si es mayor a ese tope
                        if (solo00 && grupo == "00" && topeMayorSolo00 != '' && contadorSubgrupos[grupo] > topeMayorSolo00) {
                            // console.log("Solo 00 y excede las horas totales de TP", topeMayorSolo00, grupo, contadorSubgrupos[grupo] );
                            mensajeError += `<br> <b>Importante: </b> La asignatura de caracter <b>${CarCodigo}</b> solo tiene el subgrupo 00, puede programar un máximo de <b class='text-white bg-warning px-1'> ${totalHorasTP} </b> hora(s) <b>TP</b> semanal(es) o un maximo de <b class='text-white bg-warning px-1'> ${vm.seleccion.Curso[0].AsiHorasSemanalesTeorico} </b> horas(s) <b>T</b> semanal(es), se detecto que el curso contaria con`;
                            mensajeError += `<br> <b class='text-white bg-red px-1'>${contadorSubgrupos[grupo]} </b> hora(s) semanal(es) en el subgrupo <b>${grupo}</b> superando los máximos permitidos`;
                            contadorFaltas++;
                        }

                        // Evaluamos las horas del subgrupo de teoria 00 sea menor que la cantidad de creditos de teoria
                        if (!solo00 && grupo == "00" && !gastoTodasHorasEn00 && vm.seleccion.Curso[0].AsiHorasSemanalesTeorico != '' && contadorSubgrupos[grupo] > vm.seleccion.Curso[0].AsiHorasSemanalesTeorico) {
                            console.log("Es 00 y excede las horas totales de T", vm.seleccion.Curso[0].AsiHorasSemanalesTeorico, grupo, contadorSubgrupos[grupo]);
                            mensajeError += `<br> Se encontraron <b class='text-white bg-red px-1'>${contadorSubgrupos[grupo]} </b> hora(s) semanal(es) en el subgrupo <b>${grupo}</b> y deben ser máximo <b class='text-white bg-green px-1'>${vm.seleccion.Curso[0].AsiHorasSemanalesTeorico}</b> hora(s) teorico semanal(es)`;
                            contadorFaltas++;
                        }

                        // Evaluamos si el subgrupo tiene menos horas que la cantidad de creditos de practica
                        console.log("Diferente 00 y excede las horas totales de P", vm.seleccion.Curso[0].AsiHorasSemanalesPractica, grupo, contadorSubgrupos[grupo]);
                        if (grupo != "00" && !gastoTodasHorasEn00 && vm.seleccion.Curso[0].AsiHorasSemanalesPractica != '' && contadorSubgrupos[grupo] > vm.seleccion.Curso[0].AsiHorasSemanalesPractica) {
                            console.log("Diferente 00 y excede las horas totales de P", vm.seleccion.Curso[0].AsiHorasSemanalesPractica, grupo, contadorSubgrupos[grupo]);
                            mensajeError += `<br> Se encontraron <b class='text-white bg-red px-1'>${contadorSubgrupos[grupo]} </b> hora(s) semanal(es) en el subgrupo <b>${grupo}</b> y deben ser máximo <b class='text-white bg-green px-1'>${vm.seleccion.Curso[0].AsiHorasSemanalesPractica}</b> hora(s) practica semanal(es)`;
                            contadorFaltas++;
                        }
                    });

                    mensajeError += ", por favor verificar.";

                    if (contadorFaltas > 0) {
                        mostrarSweetAlertWarning(mensajeError);
                        return false;
                    }
                }

                if (CarCodigo.trim() == 'P' || CarCodigo.trim() == 'PP' || CarCodigo.trim() == 'PF') {
                    let contadorSubgrupos = {};
                    // Contamos las horas por subgrupo
                    if (Array.isArray(vm.seleccion.Horario)) {
                        vm.seleccion.Horario.forEach(function (elemento) {
                            contadorSubgrupos[elemento.EsoSubGrupo] = (contadorSubgrupos[elemento.EsoSubGrupo] || 0) + 1;
                        });
                    } else {
                        // En caso de que sean las primeras horas a programacion siempre sera 00, se establece con 0 hs
                        contadorSubgrupos[SubGrupoNuevo] = 0;
                    }

                    // Si no existe el subgrupo nuevo en el arreglo anterior lo creamos y asignamos 0 horas.
                    if (contadorSubgrupos[SubGrupoNuevo] === undefined) {
                        contadorSubgrupos[SubGrupoNuevo] = 0;
                    }

                    // Al subgrupo nuevo le sumamos las horas nuevas que se van a programar
                    const totalHoras = contadorSubgrupos[SubGrupoNuevo] + horasNuevas;

                    if (vm.seleccion.Curso[0].AsiHorasSemanalesPractica != '' && totalHoras > vm.seleccion.Curso[0].AsiHorasSemanalesPractica) {
                        const mensajeError = "<b>Importante: </b> La asignatura de caracter <b>" + CarCodigo.trim() + "</b> cuenta con un máximo de <b class='text-white bg-green px-1'>" + vm.seleccion.Curso[0].AsiHorasSemanalesPractica + "</b> hora(s) semanal(es) de Practica y se detecto que el <b>subgrupo " + SubGrupoNuevo + "</b> cuenta con <b class='text-white bg-red px-1'>" + totalHoras + "</b> hora(s) semanal(es), por favor verificar.";
                        mostrarSweetAlertWarning(mensajeError);
                        return false;
                    }
                }
            }
            return true;
        }

        function verificarHorasCaracter(CarCodigo) {
            if (CarCodigo !== undefined || CarCodigo !== '') {
                if (CarCodigo == 'T' && vm.seleccion.Horario.length < vm.seleccion.Curso[0].AsiCreditosTeoria) {
                    vm.mensajeVerificarHorasCaracter = "<b>Importante: </b> La asignatura de caracter <b>T</b> cuenta con <b>" + vm.seleccion.Curso[0].AsiCreditosTeoria + "</b> credito(s) de Teoria y se detecto que el curso cuenta con " + vm.seleccion.Horario.length + " hora(s) semanal(es), deberia tener mínimo <b>" + vm.seleccion.Curso[0].AsiCreditosTeoria + "</b> hora(s) semanal(es), por favor verificar.";
                    return true;
                }

                if (CarCodigo == 'TP') {
                    vm.mensajeVerificarHorasCaracter = `<b>Importante: </b> La asignatura de caracter <b>${CarCodigo}</b> cuenta con ${vm.seleccion.Curso[0].AsiCreditosTeoria} credito(s) de Teoria y ${vm.seleccion.Curso[0].AsiCreditosPractica} credito(s) de Practica y se detecto que el curso cuenta con`;
                    let contadorFaltas = 0;
                    let contadorSubgrupos = {};

                    vm.seleccion.Horario.forEach(function (elemento) {
                        contadorSubgrupos[elemento.EsoSubGrupo] = (contadorSubgrupos[elemento.EsoSubGrupo] || 0) + 1;
                    });

                    let subGrupos = Object.keys(contadorSubgrupos);

                    // Verificamos si tiene solamente el subgrupo 00
                    let solo00 = false;
                    if (subGrupos.length === 1 && subGrupos[0] === '00') {
                        solo00 = true;
                    }

                    subGrupos.forEach(function (grupo) {

                        // Evaluamos los casos en los que es TP pero solo programan 00
                        if (solo00 && grupo == "00" && contadorSubgrupos[grupo] < vm.seleccion.Curso[0].AsiCreditos) {
                            vm.mensajeVerificarHorasCaracter = `<b>Importante: </b> La asignatura de caracter <b>${CarCodigo}</b> solo tiene el subgrupo 00, tiene ${vm.seleccion.Curso[0].AsiCreditos} credito(s) total(es), se detecto que el curso cuenta con`;
                            vm.mensajeVerificarHorasCaracter += ` <b>${contadorSubgrupos[grupo]} </b> hora(s) semanal(es) en el subgrupo <b>${grupo}</b> y deberian ser mínimo <b>${vm.seleccion.Curso[0].AsiCreditos}</b> hora(s) semanal(es)`;
                            contadorFaltas++;
                        }

                        // Evaluamos las horas del subgrupo de teoria 00 sea menor que la cantidad de creditos de teoria
                        if (!solo00 && grupo == "00" && contadorSubgrupos[grupo] < vm.seleccion.Curso[0].AsiCreditosTeoria) {
                            vm.mensajeVerificarHorasCaracter += ` <b>${contadorSubgrupos[grupo]} </b> hora(s) semanal(es) en el subgrupo <b>${grupo}</b> y deberian ser mínimo <b>${vm.seleccion.Curso[0].AsiCreditosTeoria}</b> hora(s) semanal(es)`;
                            contadorFaltas++;
                        }

                        // Evaluamos si el subgrupo tiene menos horas que la cantidad de creditos de practica
                        if (!solo00 && grupo != "00" && contadorSubgrupos[grupo] < vm.seleccion.Curso[0].AsiCreditosPractica) {
                            vm.mensajeVerificarHorasCaracter += `, <b>${contadorSubgrupos[grupo]} </b> hora(s) semanal(es) en el subgrupo <b>${grupo}</b> y deberian ser mínimo <b>${vm.seleccion.Curso[0].AsiCreditosPractica}</b> hora(s) semanal(es)`;
                            contadorFaltas++;
                        }
                    });

                    vm.mensajeVerificarHorasCaracter += ", por favor verificar.";

                    if (contadorFaltas > 0) {
                        return true;
                    }
                }

                // if (CarCodigo != 'T' && CarCodigo != 'TP') {
                //     vm.mensajeVerificarHorasCaracter = `<b>Importante: </b> La asignatura de caracter <b>${CarCodigo}</b> cuenta con ${vm.seleccion.Curso[0].AsiCreditosPractica} credito(s) de Practica y se detecto que el curso cuenta con`;
                //     let contadorFaltas = 0;
                //     let contadorSubgrupos = {};

                //     vm.seleccion.Horario.forEach(function (elemento) {
                //         contadorSubgrupos[elemento.EsoSubGrupo] = (contadorSubgrupos[elemento.EsoSubGrupo] || 0) + 1;
                //     });

                //     let subGrupos = Object.keys(contadorSubgrupos);

                //     subGrupos.forEach(function (grupo) {
                //         // Evaluamos si el subgrupo tiene menos horas que la cantidad de creditos de practica
                //         if (contadorSubgrupos[grupo] < vm.seleccion.Curso[0].AsiCreditosPractica) {
                //             vm.mensajeVerificarHorasCaracter += `, <b>${contadorSubgrupos[grupo]} </b> hora(s) semanal(es) en el subgrupo <b>${grupo}</b> y deberian ser mínimo <b>${vm.seleccion.Curso[0].AsiCreditosPractica}</b> hora(s) semanal(es)`;
                //             contadorFaltas++;
                //         }
                //     });
                //     vm.mensajeVerificarHorasCaracter += ", por favor verificar.";

                //     if (contadorFaltas > 0) {
                //         return true;
                //     }
                // }
            }
            return false;
        }

        function consultarDocentesPrestados() {
            vm.listaDocentesPrestados = [];
            vm.objeto = {
                accion: 20,
                UaaCodigo: vm.seleccion.Uaa.UaaCodigo,
                CalCodigo: vm.seleccion.Calendario.CalCodigo,
                PerCodigo: vm.seleccion.Calendario.PerCodigo,
                PerFechaInicio: vm.seleccion.Calendario.PerFechaInicio,
                PerFechaFin: vm.seleccion.Calendario.PerFechaFin,
                PeriodoPersonalizado: vm.seleccion.Calendario.PeriodoPersonalizado
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

        function eliminarHorarioGrupo() {
            if (vm.listaHorarioSeleccionado == '' || vm.listaHorarioSeleccionado == undefined || vm.listaHorarioSeleccionado.length == 0) {
                mostrarSweetAlertWarning("Debe seleccionar una fecha de la lista de horario del curso.");
                return false;
            }

            mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 13,
                CurCodigo: vm.seleccion.Curso[0].CurCodigo,
                ListaHorario: vm.listaHorarioSeleccionado
            };
            $http({
                url: "logica/buscurso.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                // swal.closeModal();
                var salida = response.data;

                if (salida["resultado"] == false) {
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                }
                if (salida["resultado"] == true) {
                    consultarHorarioCurso('Consulta');
                    mostrarSweetAlertSuccess(salida["mensaje"]);
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });

        }

        function recorrerUnidadesSeleccionables() {
            vm.listaHorarioSeleccionado = [];
            $(".trCheck").removeClass("table-danger");
            $.each($("input[name='chkHorario[]']:checked"), function () {
                let fila = $(this).val();
                $(".fila" + fila).addClass("table-danger");

                let obj = JSON.parse($(this).attr("obj"));
                let horario = [];
                horario = {
                    "EsoSubGrupo": obj.EsoSubGrupo,
                    "DiaCodigo": obj.DiaCodigo,
                    "HraCodigo": obj.HraCodigo,
                    "EspCodigo": obj.EspCodigo,
                    "UaaCodigo": obj.UaaCodigo,
                    "UapCodigo": obj.UapCodigo
                };
                vm.listaHorarioSeleccionado.push(horario);
            });
        }

        function seleccionarHorario(horario) {
            var check = $(".horario" + horario.EsoSubGrupo + horario.DiaCodigo + horario.HraCodigo + horario.EspCodigo + horario.UaaCodigo + horario.UapCodigo).prop("checked");
            if (check) {
                $(".horario" + horario.EsoSubGrupo + horario.DiaCodigo + horario.HraCodigo + horario.EspCodigo + horario.UaaCodigo + horario.UapCodigo).prop("checked", false);
            } else {
                $(".horario" + horario.EsoSubGrupo + horario.DiaCodigo + horario.HraCodigo + horario.EspCodigo + horario.UaaCodigo + horario.UapCodigo).prop("checked", true);
            }
            recorrerUnidadesSeleccionables();
        }

        function actualizarAgenda(CurCodigo) {
            if (CurCodigo == '' || CurCodigo === undefined) {
                mostrarSweetAlertWarning("No se encontro el codigo del curso seleccionado.");
                return false;
            }

            vm.objeto = {
                accion: 9,
                CurCodigo: CurCodigo
            };

            mostrarSweetAlertCargando();

            $http({
                url: "logica/curhorario.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                // swal.closeModal();
                var salida = response.data;

                if (salida == "true") {
                    swal.closeModal();
                    mostrarSweetAlertSuccess("Agenda actualizada correctamente.");
                }

                if (salida["resultado"] == false) {
                    swal.closeModal();
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });

        }

        function consultarEspaciosAsignadosTotal() {
            if (vm.seleccion.Uaa.UaaCodigo == '' || vm.seleccion.Uaa.UaaCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar una unidad.");
                return false;
            }
            if (vm.seleccion.Calendario.CalCodigo == '' || vm.seleccion.Calendario.CalCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar un calendario.");
                return false;
            }
            if (vm.seleccion.Calendario.PerCodigo == '' || vm.seleccion.Calendario.PerCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar un calendario.");
                return false;
            }
            if (vm.seleccion.Calendario.PerFechaInicio == '' || vm.seleccion.Calendario.PerFechaInicio === undefined) {
                mostrarSweetAlertWarning("El periodo seleccionado no cuenta con una fecha de inicio.");
                return false;
            }
            if (vm.seleccion.Calendario.PerFechaFin == '' || vm.seleccion.Calendario.PerFechaFin === undefined) {
                mostrarSweetAlertWarning("El periodo seleccionado no cuenta con una fecha de fin.");
                return false;
            }

            vm.objeto = {
                accion: 8,
                UaaCodigo: vm.seleccion.Uaa.UaaCodigo,
                CalCodigo: vm.seleccion.Calendario.CalCodigo,
                UaaDependencia: vm.seleccion.Uaa.UaaDependencia,
                PerCodigo: vm.seleccion.Calendario.PerCodigo,
                PerFechaInicio: vm.seleccion.Calendario.PerFechaInicio,
                PerFechaFin: vm.seleccion.Calendario.PerFechaFin,
                PeriodoPersonalizado: vm.seleccion.Calendario.PeriodoPersonalizado
            };

            vm.agendaEspacios = [];

            mostrarSweetAlertCargando();

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
                }
                else {
                    swal.closeModal();
                    vm.agendaEspacios = salida.data;
                    abrirModal("modalAgendaEspacio");
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });

        }

        function cambiosFormularioHorario() {
            vm.seleccion.CrearHorario.EspNombre = '';
            vm.seleccion.CrearHorario.EspNombreCorto = '';
            vm.seleccion.CrearHorario.EspCodigo = '';
            vm.seleccion.CrearHorario.EspTipo = '';
            vm.seleccion.CrearHorario.EspCapacidad = '';
            vm.seleccion.CrearHorario.ResaltarValidacionAforo = false;

            vm.seleccion.CrearHorario.DiaCodigo = '';
            vm.seleccion.CrearHorario.DiaNombre = '';
            vm.listaHoras = [];
            vm.seleccion.CrearHorario.HorasSeleccionadas = '';
        }

        function consultarHoras() {
            if (vm.seleccion.CrearHorario.DiaCodigo == '' || vm.seleccion.CrearHorario.DiaCodigo === undefined) {
                mostrarSweetAlertWarning("Debe de seleccionar el dia.");
                return false;
            }
            vm.listaHoras = [];
            vm.objeto = {
                accion: 7,
                UapCodigo: vm.seleccion.CrearHorario.UapCodigo,
                UaaCodigo: vm.seleccion.CrearHorario.Uaa.UaaCodigo,
                FechaInicio: vm.seleccion.CrearHorario.FechaInicio,
                FechaFin: vm.seleccion.CrearHorario.FechaFin,
                CurCodigo: vm.seleccion.CrearHorario.CurCodigo,
                EspCodigo: vm.seleccion.CrearHorario.EspCodigo,
                DiaCodigo: vm.seleccion.CrearHorario.DiaCodigo,
                CalCodigo: vm.seleccion.Calendario.CalCodigo,
                EspTipo: vm.seleccion.CrearHorario.EspTipo
            };

            mostrarSweetAlertCargando();

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
                }
                else {
                    swal.closeModal();
                    vm.listaHoras = salida.data;

                    let mensajeHoras = salida["mensaje"];
                    if (
                        vm.seleccion.CrearHorario.EspCapacidad !== '' &&
                        vm.seleccion.CrearHorario.EspCapacidad !== null &&
                        vm.seleccion.CrearHorario.EspCapacidad !== undefined &&
                        esEntero(vm.seleccion.CrearHorario.EspCapacidad) &&
                        vm.seleccion.Curso[0] &&
                        esEntero(vm.seleccion.Curso[0].CurCupo)
                    ) {
                        let aforoEspacio = parseInt(vm.seleccion.CrearHorario.EspCapacidad);
                        let cupoCurso = parseInt(vm.seleccion.Curso[0].CurCupo);
                        if (cupoCurso > aforoEspacio) {
                            mensajeHoras += "<br><b>Atención:</b> Este espacio tiene aforo (" + aforoEspacio + ") inferior al cupo total del curso (" + cupoCurso + ").";
                        }
                    }

                    mostrarSweetAlertSuccess(mensajeHoras);
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function normalizarCodigoHorario(valor) {
            if (valor === null || valor === undefined) {
                return '';
            }

            var texto = String(valor).trim();
            if (texto === '') {
                return '';
            }

            if (!isNaN(texto)) {
                return String(parseInt(texto, 10));
            }

            return texto;
        }

        function obtenerNombreDiaHorarioPrestado(diaCodigo, horarioPermitido) {
            var horarioDia = horarioPermitido.find(function (horario) {
                return normalizarCodigoHorario(horario.DiaCodigo) == diaCodigo;
            });

            if (horarioDia && horarioDia.DiaNombre) {
                return horarioDia.DiaNombre + " (" + diaCodigo + ")";
            }

            return diaCodigo;
        }

        function describirHorarioPermitidoPrestado(horarioPermitido) {
            var detalle = horarioPermitido.map(function (horario) {
                var dia = horario.DiaNombre ? horario.DiaNombre : normalizarCodigoHorario(horario.DiaCodigo);
                var hora = normalizarCodigoHorario(horario.HraCodigo);
                var rango = "";

                if (horario.HraInicio || horario.HraFin) {
                    rango = " (" + (horario.HraInicio || '') + " - " + (horario.HraFin || '') + ")";
                }

                return dia + " - hora " + hora + rango;
            });

            return detalle.length > 0 ? detalle.join("<br>") : "Sin horario aprobado.";
        }

        function programarHorario() {
            vm.seleccion.CrearHorario.ResaltarValidacionAforo = false;

            if (vm.seleccion.CrearHorario.TipoDocente == 'Prestado') {
                var horasSeleccionadas = Array.isArray(vm.seleccion.CrearHorario.HorasSeleccionadas)
                    ? vm.seleccion.CrearHorario.HorasSeleccionadas
                    : [];
                var horarioPermitido = Array.isArray(vm.seleccion.CrearHorario.HorarioPermitido)
                    ? vm.seleccion.CrearHorario.HorarioPermitido
                    : [];
                var diaSeleccionado = normalizarCodigoHorario(vm.seleccion.CrearHorario.DiaCodigo);

                if (horasSeleccionadas.length <= 0) {
                    mostrarSweetAlertWarning("Debe seleccionar al menos una hora para programar el docente prestado.");
                    return false;
                }
                if (horarioPermitido.length <= 0) {
                    mostrarSweetAlertWarning("El docente prestado no cuenta con horario permitido en la solicitud aprobada.");
                    return false;
                }

                var horasNoPermitidas = [];
                horasSeleccionadas.forEach(function (element) {
                    var horaSeleccionada = normalizarCodigoHorario(element);
                    var existeCombinacion = horarioPermitido.some(function (objeto) {
                        return normalizarCodigoHorario(objeto.DiaCodigo) == diaSeleccionado &&
                            normalizarCodigoHorario(objeto.HraCodigo) == horaSeleccionada;
                    });
                    if (!existeCombinacion) {
                        horasNoPermitidas.push(horaSeleccionada);
                    }
                });
                if (horasNoPermitidas.length > 0) {
                    mostrarSweetAlertWarning(
                        "Horario seleccionado no disponible para el docente aprobado." +
                        "<br><br><b>Día seleccionado:</b> " + obtenerNombreDiaHorarioPrestado(diaSeleccionado, horarioPermitido) +
                        "<br><b>Hora(s) no aprobada(s):</b> " + horasNoPermitidas.join(', ') +
                        "<br><b>Horario aprobado:</b><br>" + describirHorarioPermitidoPrestado(horarioPermitido)
                    );
                    return false;
                }
            }
            if (vm.seleccion.CrearHorario.UapCodigo == '' || vm.seleccion.CrearHorario.UapCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar un docente.");
                return false;
            }
            if (vm.seleccion.CrearHorario.FechaInicio == '' || vm.seleccion.CrearHorario.FechaInicio === undefined) {
                mostrarSweetAlertWarning("Debe ingresar la fecha de inicio.");
                return false;
            }
            if (vm.seleccion.CrearHorario.FechaFin == '' || vm.seleccion.CrearHorario.FechaFin === undefined) {
                mostrarSweetAlertWarning("Debe ingresar la fecha de fin.");
                return false;
            }
            if (vm.seleccion.CrearHorario.SubGrupo == '' || vm.seleccion.CrearHorario.SubGrupo === undefined) {
                mostrarSweetAlertWarning("Debe ingresar el subgrupo.");
                return false;
            }
            if (!esEntero(vm.seleccion.CrearHorario.SubGrupo) || vm.seleccion.CrearHorario.SubGrupo < 0) {
                mostrarSweetAlertWarning("El subgrupo solo puede ser numérico y mayor a cero. Ej 00, 01, 02...");
                return false;
            } else {
                vm.seleccion.CrearHorario.SubGrupo = ("0" + vm.seleccion.CrearHorario.SubGrupo).slice(-2);
            }

            if (vm.seleccion.Curso[0].CarCodigo.trim() == 'T') {
                if (vm.seleccion.CrearHorario.SubGrupo != '00') {
                    mostrarSweetAlertWarning("El curso Teorico solo puede tener subgrupo 00.");
                    return false;
                }
            }

            if (vm.seleccion.Curso[0].CarCodigo.trim() == 'P' || vm.seleccion.Curso[0].CarCodigo.trim() == 'PP' || vm.seleccion.Curso[0].CarCodigo.trim() == 'PF') {
                if (vm.seleccion.CrearHorario.SubGrupo == '00') {
                    mostrarSweetAlertWarning("El curso Practico no puede tener subgrupo 00.");
                    return false;
                }
            }

            if (vm.seleccion.Curso[0].CarCodigo.trim() == 'TP') {
                let existeSubgrupoTeoria = false;
                if (vm.seleccion.Horario !== null) {
                    for (let objeto of vm.seleccion.Horario) {
                        if (objeto.EsoSubGrupo === '00') {
                            existeSubgrupoTeoria = true;
                        }
                    }
                } else {
                    if (vm.seleccion.CrearHorario.SubGrupo == '00') {
                        existeSubgrupoTeoria = true;
                    }
                }
                if (!existeSubgrupoTeoria) {
                    mostrarSweetAlertWarning("El curso Teorico Practico debe ingresar primero el subgrupo 00.");
                    return false;
                }
            }

            if (vm.seleccion.CrearHorario.SubGrupo != '' && esEntero(vm.seleccion.CrearHorario.SubGrupo) && vm.seleccion.CrearHorario.SubGrupo != '00') {
                if (vm.seleccion.CrearHorario.CupoSubgrupo == '' || vm.seleccion.CrearHorario.CupoSubgrupo === undefined) {
                    mostrarSweetAlertWarning("Debe ingresar el cupo del subgrupo si el subgrupo es diferentes de 00.");
                    return false;
                }

                if (!esEntero(vm.seleccion.CrearHorario.CupoSubgrupo) || vm.seleccion.CrearHorario.CupoSubgrupo < 0) {
                    mostrarSweetAlertWarning("El cupo del subgrupo debe ser mayor a 0.");
                    return false;
                }
            }
            if (vm.seleccion.CrearHorario.EspCodigo == '' || vm.seleccion.CrearHorario.EspCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar el espacio.");
                return false;
            }

            if (
                vm.seleccion.CrearHorario.EspCapacidad !== '' &&
                vm.seleccion.CrearHorario.EspCapacidad !== null &&
                vm.seleccion.CrearHorario.EspCapacidad !== undefined &&
                esEntero(vm.seleccion.CrearHorario.EspCapacidad)
            ) {
                let aforoEspacio = parseInt(vm.seleccion.CrearHorario.EspCapacidad);
                if (vm.seleccion.CrearHorario.SubGrupo == '00') {
                    if (parseInt(vm.seleccion.Curso[0].CurCupo) > aforoEspacio) {
                        vm.seleccion.CrearHorario.ResaltarValidacionAforo = true;
                        mostrarSweetAlertWarning("No es posible programar con un cupo mayor al aforo del espacio. Aforo máximo para teoría (00): " + aforoEspacio + ". Ajuste el cupo antes de continuar.");
                        return false;
                    }
                } else {
                    if (parseInt(vm.seleccion.CrearHorario.CupoSubgrupo) > aforoEspacio) {
                        vm.seleccion.CrearHorario.ResaltarValidacionAforo = true;
                        mostrarSweetAlertWarning("No es posible programar con un cupo mayor al aforo del espacio. Aforo máximo del subgrupo " + vm.seleccion.CrearHorario.SubGrupo + ": " + aforoEspacio + ". Ajuste el cupo antes de continuar.");
                        return false;
                    }
                }
            }

            if (vm.seleccion.CrearHorario.DiaCodigo == '' || vm.seleccion.CrearHorario.DiaCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar el día.");
                return false;
            }

            if (vm.seleccion.CrearHorario.HorasSeleccionadas == '' || vm.seleccion.CrearHorario.HorasSeleccionadas === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar al menos una hora.");
                return false;
            }

            if (vm.seleccion.Calendario.CalCodigo == '' || vm.seleccion.Calendario.CalCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar un calendario.");
                return false;
            }

            if (vm.seleccion.CrearHorario.Uaa.UaaCodigo == '' || vm.seleccion.CrearHorario.Uaa.UaaCodigo === undefined) {
                mostrarSweetAlertWarning("No se encontro el codigo de la unidad seleccionado.");
                return false;
            }

            if (vm.uaaProgramada != "" && vm.seleccion.CrearHorario.Uaa.UaaCodigo != vm.uaaProgramada) {
                mostrarSweetAlertWarning("El codigo de la unidad seleccionada en la parte superior, es diferente a la unidad con la que se ha programado este curso.");
                return false;
            }

            //Si es presencial (1) y subgrupo 00, no puede ser en un aula virtual
            //Se agrega la validacion para que los de medicina si puedan programar la 00 con espacios externo, dado los cursos que se dan en el hospital y no en un espacio programable.
            //vm.seleccion.CrearHorario.Uaa.UaaCodigo != 44
            if (vm.seleccion.Calendario.CalTipo == 'A') {
                if (vm.seleccion.CrearHorario.SubGrupo == '00' && vm.seleccion.Curso[0].TicCodigo == 1) {
                    if (vm.seleccion.CrearHorario.EspTipo == 'V' && vm.seleccion.CrearHorario.Uaa.UaaCodigo != 44) {
                        let mensaje = "Los cursos teoricos o teorico practicos creados con modalidad presencial no pueden ser programados en un espacio virtual.";
                        mostrarSweetAlertWarning(mensaje);
                        return false;
                    }
                }
            }

            //Si es virtual y subgrupo 00 no puede ser en un aula fisica
            if (vm.seleccion.Calendario.CalTipo == 'A') {
                if (vm.seleccion.CrearHorario.SubGrupo == '00' && vm.seleccion.Curso[0].TicCodigo == 2) {
                    if (vm.seleccion.CrearHorario.EspTipo == 'F') {
                        let mensaje = "Los cursos virtuales no pueden seleccionar espacios físicos.";
                        mostrarSweetAlertWarning(mensaje);
                        return false;
                    }
                }
            }

            // Verificamos limite de horas establecido para cada asignatura
            if (!verificarHorasSemanales(vm.seleccion.Curso[0].CarCodigo, vm.seleccion.CrearHorario.SubGrupo)) {
                return false;
            }

            vm.objeto = {
                accion: 5,
                TicCodigo: vm.seleccion.Curso[0].TicCodigo,
                UapCodigo: vm.seleccion.CrearHorario.UapCodigo,
                UapSedCodigo: vm.seleccion.CrearHorario.UapSedCodigo,
                UaaCodigo: vm.seleccion.CrearHorario.Uaa.UaaCodigo,
                DedCodigo: vm.seleccion.CrearHorario.DedCodigo,
                VinCodigo: vm.seleccion.CrearHorario.VinCodigo,
                FechaInicio: vm.seleccion.CrearHorario.FechaInicio,
                FechaFin: vm.seleccion.CrearHorario.FechaFin,
                SubGrupo: vm.seleccion.CrearHorario.SubGrupo,
                CupoSubgrupo: vm.seleccion.CrearHorario.CupoSubgrupo,
                EspCodigo: vm.seleccion.CrearHorario.EspCodigo,
                CurCodigo: vm.seleccion.CrearHorario.CurCodigo,
                DiaCodigo: vm.seleccion.CrearHorario.DiaCodigo,
                HorasSeleccionadas: vm.seleccion.CrearHorario.HorasSeleccionadas,
                CalCodigo: vm.seleccion.Calendario.CalCodigo,
                CalNombre: vm.seleccion.Calendario.CalNombre,
                PraCodigo: vm.seleccion.Calendario.PraCodigo,
                EspTipo: vm.seleccion.CrearHorario.EspTipo,
                PerCodigo: vm.seleccion.Calendario.PerCodigo,
                UapPerCodigo: vm.seleccion.CrearHorario.UapPerCodigo,
                PerNN: vm.seleccion.CrearHorario.PerNN,
                CarCodigo: vm.seleccion.Curso[0].CarCodigo,
                AsiCodigo: vm.seleccion.Curso[0].AsiCodigo,
                AsiCreditos: vm.seleccion.Curso[0].AsiCreditos,
                AsiCreditosTeoria: vm.seleccion.Curso[0].AsiCreditosTeoria,
                AsiCreditosPractica: vm.seleccion.Curso[0].AsiCreditosPractica,
                CurSemanas: vm.seleccion.Curso[0].CurSemanas,
                UaaDependencia: vm.seleccion.Uaa.UaaDependencia,
                CalTipo: vm.seleccion.Calendario.CalTipo,
                TipoDocente: vm.seleccion.CrearHorario.TipoDocente,
                SpdCodigo: vm.seleccion.CrearHorario.SpdCodigo,
                HorarioDocentePrestado: vm.seleccion.CrearHorario.HorarioPermitido
            };

            mostrarSweetAlertCargando();

            $http({
                url: "logica/curhorario.php",
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
                    consultarHorarioCurso('Consulta');
                    consultarDetalleCurso(vm.seleccion.Curso[0]);
                    mostrarSweetAlertSuccess(salida["mensaje"]);
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });

        }

        function consultarDia() {
            if (vm.seleccion.CrearHorario.FechaInicio == '' || vm.seleccion.CrearHorario.FechaInicio === undefined) {
                mostrarSweetAlertWarning("Debe ingresar la fecha de inicio.");
                return false;
            }
            // vm.listaDias = [];
            vm.objeto = {
                accion: 6,
                FechaInicio: vm.seleccion.CrearHorario.FechaInicio,
            };

            mostrarSweetAlertCargando();

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
                }
                else {
                    swal.closeModal();
                    // vm.listaDias = salida.data;
                    vm.seleccion.CrearHorario.DiaCodigo = salida.data[0].DiaCodigo;
                    vm.seleccion.CrearHorario.DiaNombre = salida.data[0].DiaNombre;
                    consultarHoras();
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });

        }

        function seleccionarEspacio(espacio) {
            if (espacio.HorasDisponibles !== undefined && (!espacio.HorasDisponibles || espacio.HorasDisponibles.length == 0)) {
                mostrarSweetAlertWarning("El espacio seleccionado no tiene horas disponibles para programar en la fecha indicada.");
                return false;
            }

            cambiosFormularioHorario();
            let c_espacio = [];
            c_espacio = espacio;
            vm.seleccion.CrearHorario.EspNombre = c_espacio.EspNombre;
            vm.seleccion.CrearHorario.EspNombreCorto = c_espacio.EspNombreCorto;
            vm.seleccion.CrearHorario.EspCodigo = c_espacio.EspCodigo;
            vm.seleccion.CrearHorario.EspTipo = c_espacio.EspTipo;
            vm.seleccion.CrearHorario.EspCapacidad = c_espacio.EspCapacidad;

            if (c_espacio.HorasDisponibles !== undefined) {
                var dia = obtenerDiaFecha(vm.seleccion.CrearHorario.FechaInicio);
                vm.seleccion.CrearHorario.DiaCodigo = dia.codigo;
                vm.seleccion.CrearHorario.DiaNombre = dia.nombre;
                vm.listaHoras = c_espacio.HorasDisponibles;
                return true;
            }

            consultarDia();
        }

        function consultarEspaciosVirtuales() {
            vm.listaEspacios = [];
            vm.listaEspaciosVirtuales = [];
            vm.tipoListaEspacios = 'virtuales';

            if (vm.seleccion.Calendario.CalCodigo == '' || vm.seleccion.Calendario.CalCodigo === undefined) {
                mostrarSweetAlertWarning("No se encontro el codigo del calendario seleccionado.");
                return false;
            }
            if (vm.seleccion.Uaa.UaaCodigo == '' || vm.seleccion.Uaa.UaaCodigo === undefined) {
                mostrarSweetAlertWarning("No se encontro el codigo de la unidad seleccionado.");
                return false;
            }
            if (vm.seleccion.CrearHorario.UapCodigo == '' || vm.seleccion.CrearHorario.UapCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar un docente antes de buscar un espacio.");
                return false;
            }
            if (vm.seleccion.CrearHorario.FechaInicio == '' || vm.seleccion.CrearHorario.FechaInicio === undefined) {
                mostrarSweetAlertWarning("Debe ingresar la fecha de inicio.");
                return false;
            }
            if (vm.seleccion.CrearHorario.FechaFin == '' || vm.seleccion.CrearHorario.FechaFin === undefined) {
                mostrarSweetAlertWarning("Debe ingresar la fecha de fin.");
                return false;
            }

            if (vm.seleccion.CrearHorario.SubGrupo == "" || vm.seleccion.CrearHorario.SubGrupo === undefined) {
                let mensaje = "Debe ingresar el subgrupo antes de poder buscar un espacio.";
                mostrarSweetAlertWarning(mensaje);
                return false;
            }

            //Si es presencial (1) y subgrupo 00, no puede ser en un aula virtual
            //Se agrega la validacion para que los de medicina si puedan programar la 00 con espacios externo, dado los cursos que se dan en el hospital y no en un espacio programable.
            //vm.seleccion.CrearHorario.Uaa.UaaCodigo != 44
            if (vm.seleccion.Calendario.CalTipo == 'A') {
                if (vm.seleccion.CrearHorario.Uaa.UaaCodigo != 44 && vm.seleccion.CrearHorario.SubGrupo == '00' && vm.seleccion.Curso[0].TicCodigo == 1 && (vm.seleccion.Curso[0].CarCodigo.trim() == "T" || vm.seleccion.Curso[0].CarCodigo.trim() == "TP")) {
                    let mensaje = "Los cursos teoricos o teorico practicos creados con modalidad presencial no pueden ser programados en un espacio virtual.";
                    mostrarSweetAlertWarning(mensaje);
                    return false;
                }
            }

            vm.objeto = {
                accion: 4
            };

            mostrarSweetAlertCargando();

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
                }
                else {
                    swal.closeModal();
                    vm.listaEspaciosVirtuales = salida.data;
                    abrirModal("modalEspacios");
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function crearObjetoConsultaEspacios(accion) {
            return {
                accion: accion,
                FechaInicio: vm.seleccion.CrearHorario.FechaInicio,
                FechaFin: vm.seleccion.CrearHorario.FechaFin,
                PerFechaFin: vm.seleccion.Calendario.PerFechaFin,
                PerFechaInicio: vm.seleccion.Calendario.PerFechaInicio,
                Administrador: vm.seleccion.Calendario.Administrador,
                PeriodoPersonalizado: vm.seleccion.Calendario.PeriodoPersonalizado,
                CalCodigo: vm.seleccion.Calendario.CalCodigo,
                PraEstado: vm.seleccion.Calendario.PraEstado,
                PraFechaFin: vm.seleccion.Calendario.PraFechaFin,
                PraFechaInicio: vm.seleccion.Calendario.PraFechaInicio,
                Vencida: vm.seleccion.Calendario.Vencida,
                UaaCodigo: vm.seleccion.Uaa.UaaCodigo,
                UaaDependencia: vm.seleccion.Uaa.UaaDependencia,
                SedNombre: vm.seleccion.Uaa.SedNombre,
                SedCodigo: vm.seleccion.Uaa.SedCodigo,
                SedCodigoCurso: vm.seleccion.Curso[0].SedCodigo,
                UapCodigo: vm.seleccion.CrearHorario.UapCodigo,
                CurCodigo: vm.seleccion.CrearHorario.CurCodigo,
            };
        }

        function actualizarResumenEspacios() {
            vm.resumenEspacios = {
                disponibles: 0,
                sinDisponibilidad: 0,
                sinConsultar: 0
            };

            vm.listaEspacios.forEach(function (espacio) {
                if (espacio.TotalHorasDisponibles === undefined) {
                    vm.resumenEspacios.sinConsultar++;
                } else if (espacio.TotalHorasDisponibles > 0) {
                    vm.resumenEspacios.disponibles++;
                } else {
                    vm.resumenEspacios.sinDisponibilidad++;
                }
            });
        }

        function validarDatosConsultaEspacios() {
            if (vm.seleccion.Calendario.CalCodigo == '' || vm.seleccion.Calendario.CalCodigo === undefined) {
                mostrarSweetAlertWarning("No se encontro el codigo del calendario seleccionado.");
                return false;
            }
            if (vm.seleccion.Uaa.UaaCodigo == '' || vm.seleccion.Uaa.UaaCodigo === undefined) {
                mostrarSweetAlertWarning("No se encontro el codigo de la unidad seleccionado.");
                return false;
            }
            if (vm.seleccion.CrearHorario.UapCodigo == '' || vm.seleccion.CrearHorario.UapCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar un docente antes de buscar un espacio.");
                return false;
            }
            if (vm.seleccion.CrearHorario.FechaInicio == '' || vm.seleccion.CrearHorario.FechaInicio === undefined) {
                mostrarSweetAlertWarning("Debe ingresar la fecha de inicio.");
                return false;
            }
            if (vm.seleccion.CrearHorario.FechaFin == '' || vm.seleccion.CrearHorario.FechaFin === undefined) {
                mostrarSweetAlertWarning("Debe ingresar la fecha de fin.");
                return false;
            }

            if (vm.seleccion.CrearHorario.SubGrupo == "" || vm.seleccion.CrearHorario.SubGrupo === undefined) {
                let mensaje = "Debe ingresar el subgrupo antes de poder buscar un espacio virtual.";
                mostrarSweetAlertWarning(mensaje);
                return false;
            }

            //Si es presencial (1) y subgrupo 00, no puede ser en un aula virtual
            if (vm.seleccion.Calendario.CalTipo == 'A') {
                if (vm.seleccion.CrearHorario.SubGrupo == '00' && vm.seleccion.Curso[0].TicCodigo == 2) {
                    let mensaje = "Los cursos virtuales no pueden seleccionar espacios físicos.";
                    mostrarSweetAlertWarning(mensaje);
                    return false;
                }
            }

            return true;
        }

        function consultarEspaciosAsignados() {
            if (!validarDatosConsultaEspacios()) {
                return false;
            }

            vm.listaEspacios = [];
            vm.listaEspaciosVirtuales = [];
            vm.tipoListaEspacios = 'asignados';
            vm.resumenEspacios = {
                disponibles: 0,
                sinDisponibilidad: 0,
                sinConsultar: 0
            };

            vm.objeto = crearObjetoConsultaEspacios(3);

            mostrarSweetAlertCargando();

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
                }
                else {
                    swal.closeModal();
                    vm.listaEspacios = salida.data;
                    actualizarResumenEspacios();
                    vm.filtroDisponibilidadEspacios = 'todos';
                    abrirModal("modalEspacios");
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultarDisponibilidadEspacio(espacio) {
            if (!validarDatosConsultaEspacios()) {
                return false;
            }

            if (!espacio || !espacio.EspCodigo) {
                mostrarSweetAlertWarning("No se encontro el codigo del espacio seleccionado.");
                return false;
            }

            espacio.ConsultandoDisponibilidad = true;
            vm.objeto = crearObjetoConsultaEspacios(12);
            vm.objeto.EspCodigo = espacio.EspCodigo;

            $http({
                url: "logica/curhorario.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                var salida = response.data;
                espacio.ConsultandoDisponibilidad = false;
                if (salida["resultado"] == false) {
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                }
                else {
                    var datosEspacio = salida.data && salida.data.length > 0 ? salida.data[0] : null;
                    espacio.HorasDisponibles = datosEspacio ? datosEspacio.HorasDisponibles : [];
                    espacio.TotalHorasDisponibles = datosEspacio ? datosEspacio.TotalHorasDisponibles : 0;
                    espacio.TieneDisponibilidad = datosEspacio ? datosEspacio.TieneDisponibilidad : false;
                    espacio.DiaCodigo = datosEspacio ? datosEspacio.DiaCodigo : undefined;
                    espacio.MostrarHoras = espacio.TotalHorasDisponibles > 0;
                    actualizarResumenEspacios();
                }

            }, function myError(response) {
                espacio.ConsultandoDisponibilidad = false;
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultarDisponibilidadTodosEspacios() {
            if (!validarDatosConsultaEspacios()) {
                return false;
            }

            vm.objeto = crearObjetoConsultaEspacios(11);
            mostrarSweetAlertCargando();

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
                }
                else {
                    swal.closeModal();
                    vm.listaEspacios = salida.data;
                    actualizarResumenEspacios();
                    vm.filtroDisponibilidadEspacios = vm.resumenEspacios.disponibles > 0 ? 'disponibles' : 'todos';
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function calcularFechaFinal() {
            cambiosFormularioHorario();
            let semanas = vm.seleccion.Curso[0].CurSemanas;
            let fecha = new Date(vm.seleccion.CrearHorario.FechaInicio);
            fecha.setDate(fecha.getDate() + (semanas * 7) - 6);
            vm.seleccion.CrearHorario.FechaFin = fecha.getFullYear() + '-' + (("0" + (fecha.getMonth() + 1)).slice(-2)) + '-' + ("0" + fecha.getDate()).slice(-2);
            // academico/planta/librerias/js/javascriptlib.js
        }

        function consultarAgendaDocenteHorario() {
            vm.agendaDocenteFechas = {
                inicio: '',
                fin: ''
            };
            vm.cargaDocente = {};

            if (vm.seleccion.Calendario.CalCodigo == '' || vm.seleccion.Calendario.CalCodigo === undefined) {
                mostrarSweetAlertWarning("No se encontro el codigo del calendario seleccionado.");
                return false;
            }
            if (vm.seleccion.Uaa.UaaCodigo == '' || vm.seleccion.Uaa.UaaCodigo === undefined) {
                mostrarSweetAlertWarning("No se ha seleccionado una unidad a programar.");
                return false;
            }

            vm.agendaDocente = [];
            vm.objeto = {
                accion: 7,
                UapCodigo: vm.seleccion.CrearHorario.UapCodigo,
                CalCodigo: vm.seleccion.Calendario.CalCodigo,
                PeriodoPersonalizado: vm.seleccion.Calendario.PeriodoPersonalizado
            };

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
                    vm.agendaDocente = salida.data;
                    vm.agendaDocenteFechas.inicio = salida.fecha_inicial || vm.seleccion.Calendario.PerFechaInicio;
                    vm.agendaDocenteFechas.fin = salida.fecha_final || vm.seleccion.Calendario.PerFechaFin;

                    vm.objeto = {
                        accion: 10,
                        UapCodigo: vm.seleccion.CrearHorario.UapCodigo,
                        CalCodigo: vm.seleccion.Calendario.CalCodigo,
                        FacultadCodigo: (vm.seleccion.Uaa && vm.seleccion.Uaa.UaaDependencia) ? vm.seleccion.Uaa.UaaDependencia : (vm.seleccion.Uaa ? vm.seleccion.Uaa.UaaCodigo : 0)
                    };

                    $http({
                        url: "logica/curhorario.php",
                        method: "POST",
                        data: vm.objeto
                    }).then(function (response) {
                        var salidaCarga = response.data;
                        if (salidaCarga["resultado"] == false) {
                            swal.closeModal();
                            mostrarSweetAlertError(salidaCarga["mensaje"]);
                            console.error(salidaCarga["consola"]);
                        } else {
                            swal.closeModal();
                            vm.cargaDocente = salidaCarga.data;
                            abrirModal("modalAgendaDocente");
                        }
                    }, function myError(response) {
                        swal.closeModal();
                        mostrarSweetAlertError("Error del servidor, favor recargar la página");
                        console.error(response.data);
                    });
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function formularioCrearCurso() {
            vm.seleccion.CrearHorario = [];
            vm.seleccion.CrearHorario = {
                PerNombreApellido: vm.seleccion.Curso[0].PerNombreApellido,
                UapPerCodigo: vm.seleccion.Curso[0].PerCodigo,
                VinNombre: vm.seleccion.Curso[0].VinNombre,
                UapCodigo: vm.seleccion.Curso[0].UapCodigo,
                CurCodigo: vm.seleccion.Curso[0].CurCodigo,
                VinCodigo: vm.seleccion.Curso[0].VinCodigo,
                DedCodigo: vm.seleccion.Curso[0].DedCodigo,
                UapSedCodigo: vm.seleccion.Curso[0].UapSedCodigo,
                Uaa: vm.seleccion.Uaa,
                ResaltarValidacionAforo: false
            };
            var solicitudPrestamoCurso = null;
            if ('DocentePrestado' in vm.seleccion.Curso[0] && Array.isArray(vm.seleccion.Curso[0].DocentePrestado)) {
                solicitudPrestamoCurso = vm.seleccion.Curso[0].DocentePrestado.find(function (solicitud) {
                    return normalizarCodigoHorario(solicitud.AsiCodigo) == normalizarCodigoHorario(vm.seleccion.Curso[0].AsiCodigo);
                });
            }

            if (solicitudPrestamoCurso !== null) {
                vm.seleccion.CrearHorario.TipoDocente = "Prestado";
                vm.seleccion.CrearHorario.SpdCodigo = solicitudPrestamoCurso.SpdCodigo;
                vm.seleccion.CrearHorario.HorarioPermitido = solicitudPrestamoCurso.Horario;
            } else {
                vm.seleccion.CrearHorario.TipoDocente = "Propio";
            }
            vm.creacionHorario = 1;
        }

        function filtrarEspacioPorDisponibilidad(espacio) {
            if (vm.filtroDisponibilidadEspacios == 'disponibles') {
                return espacio.TotalHorasDisponibles > 0;
            }
            if (vm.filtroDisponibilidadEspacios == 'sin_disponibilidad') {
                return espacio.TotalHorasDisponibles !== undefined && espacio.TotalHorasDisponibles <= 0;
            }
            if (vm.filtroDisponibilidadEspacios == 'sin_consultar') {
                return espacio.TotalHorasDisponibles === undefined;
            }
            return true;
        }

        function cambiarFiltroDisponibilidadEspacios(filtro) {
            vm.filtroDisponibilidadEspacios = filtro;
        }

        function alternarDetalleEspacio(espacio) {
            espacio.MostrarHoras = !espacio.MostrarHoras;
        }

        function obtenerDiaFecha(fecha) {
            var dia = new Date(fecha + 'T00:00:00').getDay();
            if (dia == 0) {
                dia = 7;
            }
            var nombres = {
                1: 'Lunes',
                2: 'Martes',
                3: 'Miercoles',
                4: 'Jueves',
                5: 'Viernes',
                6: 'Sabado',
                7: 'Domingo'
            };
            return {
                codigo: dia,
                nombre: nombres[dia]
            };
        }

        function eliminarHorario(horario) {
            vm.seleccion.EliminarHorario = [];
            vm.seleccion.EliminarHorario = horario;
            mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 2,
                CurCodigo: vm.seleccion.EliminarHorario.CurCodigo,
                EspCodigo: vm.seleccion.EliminarHorario.EspCodigo,
                DiaCodigo: vm.seleccion.EliminarHorario.DiaCodigo,
                HraCodigo: vm.seleccion.EliminarHorario.HraCodigo,
                EsoFechaInicio: vm.seleccion.EliminarHorario.EsoFechaInicio,
                EsoFechaFin: vm.seleccion.EliminarHorario.EsoFechaFin,
                EsoSubGrupo: vm.seleccion.EliminarHorario.EsoSubGrupo,
                UapCodigo: vm.seleccion.EliminarHorario.UapCodigo
            };
            $http({
                url: "logica/curhorario.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                // swal.closeModal();
                var salida = response.data;

                if (salida["resultado"] == false) {
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                }
                if (salida["resultado"] == true) {
                    consultarHorarioCurso('Consulta');
                    mostrarSweetAlertSuccess(salida["mensaje"]);
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultarHorarioCurso(tipo = '') {
            vm.creacionHorario = 0;
            vm.uaaProgramada = "";
            if (tipo == '') {
                if (vm.seleccion.Curso.CurCodigo == '' || vm.seleccion.Curso.CurCodigo === undefined) {
                    mostrarSweetAlertWarning("Debe seleccionar un curso.");
                    return false;
                }

                vm.objeto = {
                    accion: 1,
                    CurCodigo: vm.seleccion.Curso.CurCodigo
                };
            } else {
                vm.objeto = {
                    accion: 1,
                    CurCodigo: vm.seleccion.Curso[0].CurCodigo
                };
            }

            mostrarSweetAlertCargando();

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
                }
                else {
                    vm.seleccion.Horario = salida.data;
                    vm.uaaProgramada = salida.data ? vm.seleccion.Horario[0].UaaCodigo : "";
                    vm.informacionHorario = 1;
                    if (tipo == '') {
                        swal.closeModal();
                    }
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function mostrarInformacion() {
            $(".informacion-curso").slideToggle("fast");
        }

        function seleccionarDocente(docente, tipo = "Propio") {
            cambiosFormularioHorario();
            vm.seleccion.CrearHorario.PerNombreApellido = docente.PerNombre + ' ' + docente.PerApellido;
            vm.seleccion.CrearHorario.VinNombre = docente.VinNombre;
            vm.seleccion.CrearHorario.UapCodigo = docente.UapCodigo;
            vm.seleccion.CrearHorario.DedCodigo = docente.DedCodigo;
            vm.seleccion.CrearHorario.VinCodigo = docente.VinCodigo;
            vm.seleccion.CrearHorario.PerCodigo = docente.PerCodigo;
            vm.seleccion.CrearHorario.PerNN = docente.PerNN;
            vm.seleccion.CrearHorario.UapSedCodigo = docente.SedCodigo;
            vm.seleccion.CrearHorario.UapPerCodigo = docente.PerCodigo;
            vm.seleccion.CrearHorario.TipoDocente = tipo;
            if (tipo == "Prestado") {
                vm.seleccion.CrearHorario.SpdCodigo = docente.SpdCodigo;
                vm.seleccion.CrearHorario.HorarioPermitido = docente.Horario;
            }
        }

        function consultarDocentes() {
            vm.listaDocentes = [];
            vm.objeto = {
                accion: 14,
                UaaCodigo: vm.seleccion.Uaa.UaaCodigo,
                CalCodigo: vm.seleccion.Calendario.CalCodigo,
                PerFechaInicio: vm.seleccion.Calendario.PerFechaInicio,
                PerFechaFin: vm.seleccion.Calendario.PerFechaFin,
                PeriodoPersonalizado: vm.seleccion.Calendario.PeriodoPersonalizado
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
                    vm.listaDocentes = salida.data;
                    swal.closeModal();
                    abrirModal("modalDocentes");
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultarPlanExclusivo() {
            if (vm.seleccion.Curso[0].CurCodigo == '' || vm.seleccion.Curso[0].CurCodigo === undefined) {
                mostrarSweetAlertWarning("No se encontro el codigo del curso seleccionado.");
                return false;
            }
            vm.listaPlanExclusivo = [];
            vm.objeto = {
                accion: 8,
                CurCodigo: vm.seleccion.Curso[0].CurCodigo,
                // PlaCodigo: vm.seleccion.Curso[0].PlaCodigo
            };

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
                    vm.listaPlanExclusivo = salida.data;
                    abrirModal("modalPlanExclusivo");
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultarAgendaDocente() {
            if (vm.seleccion.Calendario.CalCodigo == '' || vm.seleccion.Calendario.CalCodigo === undefined) {
                mostrarSweetAlertWarning("No se encontro el codigo del calendario seleccionado.");
                return false;
            }

            if (vm.tipoOperacion == '') {
                if (vm.seleccion.Curso[0].UapCodigo == '' || vm.seleccion.Curso[0].UapCodigo === undefined) {
                    mostrarSweetAlertWarning("No se encontro el codigo de vinculacion del docente coordinador.");
                    return false;
                }
                vm.agendaDocente = [];
                vm.objeto = {
                    accion: 7,
                    UapCodigo: vm.seleccion.Curso[0].UapCodigo,
                    CalCodigo: vm.seleccion.Calendario.CalCodigo,
                    PeriodoPersonalizado: vm.seleccion.Calendario.PeriodoPersonalizado
                };
            }
            if (vm.tipoOperacion == 'edicion') {
                if (vm.seleccion.CursoActualizar.UapCodigo == '' || vm.seleccion.CursoActualizar.UapCodigo === undefined) {
                    mostrarSweetAlertWarning("No se encontro el codigo de vinculacion del docente coordinador.");
                    return false;
                }
                vm.agendaDocente = [];
                vm.objeto = {
                    accion: 7,
                    UapCodigo: vm.seleccion.CursoActualizar.UapCodigo,
                    CalCodigo: vm.seleccion.Calendario.CalCodigo,
                    PeriodoPersonalizado: vm.seleccion.Calendario.PeriodoPersonalizado
                };
            }
            if (vm.tipoOperacion == 'creacion') {
                if (vm.seleccion.CursoCrear.UapCodigo == '' || vm.seleccion.CursoCrear.UapCodigo === undefined) {
                    mostrarSweetAlertWarning("No se encontro el codigo de vinculacion del docente coordinador.");
                    return false;
                }
                vm.agendaDocente = [];
                vm.objeto = {
                    accion: 7,
                    UapCodigo: vm.seleccion.CursoCrear.UapCodigo,
                    CalCodigo: vm.seleccion.Calendario.CalCodigo,
                    PeriodoPersonalizado: vm.seleccion.Calendario.PeriodoPersonalizado
                };
            }

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
                    vm.agendaDocente = salida.data;
                    swal.closeModal();
                    abrirModal("modalAgendaDocente");
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });

        }

        function consultarDetalleCurso(curso) {
            vm.seleccion.Curso = curso;
            vm.tipoOperacion = '';
            if (vm.seleccion.Curso.CurCodigo == '' || vm.seleccion.Curso.CurCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar un curso.");
                return false;
            }

            vm.objeto = {
                accion: 6,
                CurCodigo: vm.seleccion.Curso.CurCodigo,
                UaaCodigo: vm.seleccion.Uaa.UaaCodigo
            };

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
                    vm.seleccion.Curso = salida.data;
                    // vm.seleccion.Curso = salida.data;
                    vm.informacionCursos = 1;
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });

        }

        function consultarCurso(tipo = '') {
            if (vm.seleccion.Uaa.UaaCodigo == '' || vm.seleccion.Uaa.UaaCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar una unidad.");
                return false;
            }
            if (vm.seleccion.Calendario.CalCodigo == '' || vm.seleccion.Calendario.CalCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar una calendario de programación.");
                return false;
            }

            if (tipo != '') {
                mostrarSweetAlertCargando();
            }

            vm.listaCursos = [];
            vm.seccionCursos = 0;
            vm.creacionHorario = 0;
            vm.informacionCursos = 0;
            vm.informacionHorario = 0;
            vm.formularioEdicionCursos = 0;
            vm.formularioEdicionCursos = 0;
            vm.seleccion.Curso = {};
            vm.seleccion.Horario = {};
            vm.seleccion.EliminarHorario = {};
            vm.seleccion.CrearHorario = {};

            // mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 5,
                UaaCodigo: vm.seleccion.Uaa.UaaCodigo,
                CalCodigo: vm.seleccion.Calendario.CalCodigo,
                NucCodigo: vm.seleccion.Calendario.NucCodigo
            };

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
                    vm.listaCursos = salida.data;
                    vm.seccionCursos = 1;
                    vm.btnEspaciosAsignados = 1;
                    if (tipo == '') {
                        swal.closeModal();
                    } else {
                        swal.closeModal();
                    }
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });


        }

        function consultarUnidadesUnificadas() {
            vm.listaUnidadesUnificadas = [];
            vm.seccionCursos = 0;
            vm.informacionCursos = 0;
            vm.informacionHorario = 0;
            vm.seleccion.Curso = {};
            vm.seleccion.Horario = {};

            vm.objeto = {
                accion: 4
            };

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
                    vm.listaUnidadesUnificadas = salida.data;
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultarCalendarios() {
            if (vm.seleccion.Uaa.UaaCodigo == '' || vm.seleccion.Uaa.UaaCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar una unidad.");
                return false;
            }
            vm.sinCalendario = 0;
            vm.btnBuscarCursos = 0;
            vm.seccionCursos = 0;
            vm.btnEspaciosAsignados = 0;
            vm.informacionCursos = 0;
            vm.informacionHorario = 0;
            vm.listaCalendarios = [];
            vm.filtroEstadoCalendario = 'PRINCIPAL';
            vm.seleccion.Calendario = {};
            vm.seleccion.Curso = {};
            vm.seleccion.Horario = {};

            vm.objeto = {
                accion: 5,
                UaaCodigo: vm.seleccion.Uaa.UaaCodigo
            };

            $http({
                url: "logica/aperfe.php",
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
                    vm.listaCalendarios = filtrarCalendariosSeleccionables(salida.data);
                    if (vm.listaCalendarios.length <= 0) {
                        vm.sinCalendario = 1;
                    }
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultarFacultades() {
            vm.listaFacultades = [];
            vm.objeto = {
                accion: 2
            };

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
                    vm.listaFacultades = salida.data;
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultarSedes() {
            vm.listaSedes = [];
            vm.objeto = {
                accion: 1
            };

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
                    vm.listaSedes = salida.data;
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
            if (accion == 'eliminar_horario_grupo') {
                mje = "¿Desea eliminar las horas seleccionadas?";
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
                    if (accion == 'eliminar_horario') {
                        eliminarHorario(parametros);
                    }
                    if (accion == 'crear_horario') {
                        programarHorario(parametros);
                    }
                    if (accion == 'eliminar_horario_grupo') {
                        eliminarHorarioGrupo();
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
