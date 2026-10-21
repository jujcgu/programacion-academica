(function () {
    angular
        .module('sipa')
        .controller('BuscursoController', BuscursoController);

    function BuscursoController($http, $rootScope) {
        var vm = this;
        //Visualizacion
        vm.informacionCursos = 0;
        vm.listadoCursos = 0;
        vm.formularioEdicionCursos = 0;
        vm.formularioCreacionCursos = 0;
        vm.creacionHorario = 0;
        vm.tipoOperacion = '';

        //Variables
        vm.mensajeVerificarHorasCaracter = "Validando...";
        vm.administrador = 0;
        vm.cursoSeleccionado = {};
        vm.cursoDetalle = {};
        vm.cursoHorario = {};
        vm.periodoSeleccionado = "";
        vm.calendarioSeleccionado = "";
        vm.listaPeriodos = {};
        vm.listaCalendarios = {};
        vm.listaCursos = {};
        vm.listaPlanExclusivo = [];
        vm.eliminarHorario = [];
        vm.crearHorario = [];
        vm.listaHoras = [];
        vm.listaUnidades = {};
        vm.agendaDocente = [];
        vm.cargaDocente = {};
        vm.agendaDocenteFechas = {
            inicio: '',
            fin: ''
        };
        vm.vinculacionDocenteFechas = {
            inicio: '',
            fin: ''
        };
        vm.listaDocentes = [];
        vm.listaDocentesPrestados = [];
        vm.listaEspacios = [];
        vm.listaEspaciosVirtuales = [];
        vm.tipoListaEspacios = '';
        vm.filtroDisponibilidadEspacios = 'todos';
        vm.resumenEspacios = {
            disponibles: 0,
            sinDisponibilidad: 0,
            sinConsultar: 0
        };
        vm.CursoActualizar = [];
        vm.CursoCrear = [];
        vm.listaSedes = [];
        vm.listaTipoCurso = [];
        vm.listaPlanesAcademicos = [];
        vm.planAcademicoSeleccionado = '';
        vm.asignaturasPlan = [];
        vm.listaAsignaturas = [];
        vm.unidadSeleccionada = '';
        vm.listaHorarioSeleccionado = [];
        vm.filtroAsignatura = "";
        vm.busquedaAsignatura = [];

        //Filtros
        vm.filter = {
            Curso: '',
            Horario: '',
            Horario2: '',
            Estado: '',
            Espacios: '',
            PlanAcademico: '',
            Asignatura: '',
            Docentes: '',
            Unidad: '',
            AsignaturaEstado: ''
        }

        //Funciones
        vm.consultarAdministrador = consultarAdministrador;
        vm.consultarPeriodos = consultarPeriodos;
        vm.consultarCalendarios = consultarCalendarios;
        vm.consultarCursos = consultarCursos;
        vm.consultarDetalleCurso = consultarDetalleCurso;
        vm.mostrarInformacion = mostrarInformacion;
        vm.consultarPlanExclusivo = consultarPlanExclusivo;
        vm.consultarAgendaDocente = consultarAgendaDocente;
        vm.consultarHorarioCurso = consultarHorarioCurso;
        vm.eliminarHorario = eliminarHorario;
        vm.mostrarFormularioCrearHorario = mostrarFormularioCrearHorario;
        vm.consultarUnidades = consultarUnidades;
        vm.calcularFechaFinal = calcularFechaFinal;
        vm.cambiosFormularioHorario = cambiosFormularioHorario;
        vm.consultarAgendaDocenteHorario = consultarAgendaDocenteHorario;
        vm.consultarDocentes = consultarDocentes;
        vm.consultarDocentesPrestados = consultarDocentesPrestados;
        vm.seleccionarDocente = seleccionarDocente;
        vm.consultarEspaciosAsignados = consultarEspaciosAsignados;
        vm.consultarDisponibilidadEspacio = consultarDisponibilidadEspacio;
        vm.consultarDisponibilidadTodosEspacios = consultarDisponibilidadTodosEspacios;
        vm.consultarEspaciosVirtuales = consultarEspaciosVirtuales;
        vm.seleccionarEspacio = seleccionarEspacio;
        vm.formularioEditarCurso = formularioEditarCurso;
        vm.cancelarEditarCurso = cancelarEditarCurso;
        vm.consultarPlanesAcademicos = consultarPlanesAcademicos;
        vm.consultarAsignaturasPlan = consultarAsignaturasPlan;
        vm.actualizarAsignaturaPlan = actualizarAsignaturaPlan;
        vm.consultarPropietarioAsignatura = consultarPropietarioAsignatura;
        vm.modalAsignaturasEquivalentes = modalAsignaturasEquivalentes;
        vm.consultarAsignaturasEquivalentes = consultarAsignaturasEquivalentes;
        vm.actualizarAsignatura = actualizarAsignatura;
        vm.consultarPlanExclusivoCurso = consultarPlanExclusivoCurso;
        vm.quitarExclusividad = quitarExclusividad;
        vm.ponerComoExclusivo = ponerComoExclusivo;
        vm.formularioCrearCurso = formularioCrearCurso;
        vm.cancelarCrearCurso = cancelarCrearCurso;
        vm.consultarPlanExclusivoCreacion = consultarPlanExclusivoCreacion;
        vm.seleccionarPlanAcademico = seleccionarPlanAcademico;
        vm.deseleccionarPlanAcademico = deseleccionarPlanAcademico;
        vm.seleccionarHorario = seleccionarHorario;
        vm.eliminarHorarioGrupo = eliminarHorarioGrupo;
        vm.buscarAsignatura = buscarAsignatura;
        vm.verificarHorasCaracter = verificarHorasCaracter;
        vm.actualizarAgenda = actualizarAgenda;
        vm.obtenerCursosFiltrados = obtenerCursosFiltrados;
        vm.esHorarioIncompleto = esHorarioIncompleto;
        vm.tieneHorarioProgramado = tieneHorarioProgramado;
        vm.filtrarEspacioPorDisponibilidad = filtrarEspacioPorDisponibilidad;
        vm.cambiarFiltroDisponibilidadEspacios = cambiarFiltroDisponibilidadEspacios;
        vm.alternarDetalleEspacio = alternarDetalleEspacio;

        //Funciones iniciales.
        consultarAdministrador(); //Se debe ejecutar al inicio para verificar si es un administrador.
        consultarSedes(); //Se debe ejecutar al inicio para cargar las sedes disponibles
        consultaTipoCurso(); //Se debe ejecutar al inicio para cargar los tipos de cursos disponibles.

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

        function verificarHorasSemanales(CarCodigo, SubGrupoNuevo) {

            if ([
                vm.cursoDetalle[0].AsiHorasSemanalesTeorico,
                vm.cursoDetalle[0].AsiHorasSemanalesPractica,
                vm.cursoDetalle[0].AsiHorasSemanalesTeoricoPractico
            ].every(v => v === null || v === undefined || v === '' || v == '0')) {
                console.log("No tiene horas semanales asignadas, no se realiza validacion.");
                return true;
            }
            if (CarCodigo !== undefined || CarCodigo !== '') {
                console.log("cursoHorario", vm.cursoHorario);
                const totalHorasProgramadas = Array.isArray(vm.cursoHorario) ? vm.cursoHorario.length : 0;
                const horasNuevas = vm.crearHorario.HorasSeleccionadas.length;
                console.log("TotalHoras", totalHorasProgramadas, horasNuevas);
                
                if (CarCodigo.trim() == 'T') {
                    const totalHoras = totalHorasProgramadas + horasNuevas;
                    console.log("TotalHoras T", totalHoras);
                    if (vm.cursoDetalle[0].AsiHorasSemanalesTeorico != '' && totalHoras > vm.cursoDetalle[0].AsiHorasSemanalesTeorico) {
                        const mensajeError = "<b>Importante: </b> La asignatura de caracter <b>T</b> cuenta con un máximo de <b class='text-white bg-green px-1'>" + vm.cursoDetalle[0].AsiHorasSemanalesTeorico + "</b> hora(s) semanal(es) de Teoria y se detecto que el curso contaria con <b class='text-white bg-red px-1'>" + totalHoras + "</b> hora(s) semanal(es) superando el máximo permitido, por favor verificar.";
                        mostrarSweetAlertWarning(mensajeError);
                        return false;
                    }
                }

                if (CarCodigo.trim() == 'TP') {
                    let mensajeError = `<b>Importante: </b> La asignatura de caracter <b>TP</b> cuenta con un máximo de <b class='text-white bg-green px-1'> ${vm.cursoDetalle[0].AsiHorasSemanalesTeorico} </b> hora(s) semanal(es) de Teoria y <b class='text-white bg-green px-1'> ${vm.cursoDetalle[0].AsiHorasSemanalesPractica}</b> hora(s) semanal(es) de de Practica.`;
                    let contadorFaltas = 0;
                    let contadorSubgrupos = {};

                    // Contamos las horas por subgrupo
                    if (Array.isArray(vm.cursoHorario)) {
                        vm.cursoHorario.forEach(function (elemento) {
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

                    console.table(contadorSubgrupos);

                    subGrupos.forEach(function (grupo) {
                        // console.log("Evaluando grupo: ", grupo);

                        // Evaluamos los casos en los que es TP pero solo programan 00
                        // En caso de ser solamente 00 se debe sumar las horas maximas teoricas con las de practicas
                        const totalHorasTP = vm.cursoDetalle[0].AsiHorasSemanalesTeoricoPractico;
                        const topeMayorSolo00 = totalHorasTP > vm.cursoDetalle[0].AsiHorasSemanalesTeorico ? totalHorasTP : vm.cursoDetalle[0].AsiHorasSemanalesTeorico;
                        const gastoTodasHorasEn00 = contadorSubgrupos['00'] == totalHorasTP ? true : false; // Verificamos si las horas del 00 es igual al total de creditos TP

                        // Validamos si es 00, si tiene subgrupos 01 y si ya gasto todas las horas en el 00
                        if (!solo00 && grupo == '00' && gastoTodasHorasEn00) {
                            // console.log("gastoTodasHorasEn 00 y excede las horas totales de TP", vm.cursoDetalle[0].AsiHorasSemanalesPractica, grupo, contadorSubgrupos[grupo] );
                            mensajeError += `<br> Solo se encontro el subgrupo 00 y cuenta con <b class='text-white bg-red px-1'>${contadorSubgrupos[grupo]} </b> hora(s) semanal(es), deben programar un máximo de <b class='text-white bg-warning px-1'> ${totalHorasTP} </b> hora(s) <b>TP</b> semanal(es) si solo se programará 00 o un maximo de <b class='text-white bg-warning px-1'> ${vm.cursoDetalle[0].AsiHorasSemanalesTeorico} </b> horas(s) <b>T</b> semanal(es) si va a incluir subgrupos.`;
                            contadorFaltas++;
                        }

                        // Validamos si es solo 00, obtenemos cual tope de horas toma, si T o TP total, y si es mayor a ese tope
                        if (solo00 && grupo == "00" && topeMayorSolo00 != '' && contadorSubgrupos[grupo] > topeMayorSolo00) {
                            // console.log("Solo 00 y excede las horas totales de TP", topeMayorSolo00, grupo, contadorSubgrupos[grupo] );
                            mensajeError += `<br> <b>Importante: </b> La asignatura de caracter <b>${CarCodigo}</b> solo tiene el subgrupo 00, puede programar un máximo de <b class='text-white bg-warning px-1'> ${totalHorasTP} </b> hora(s) <b>TP</b> semanal(es) o un maximo de <b class='text-white bg-warning px-1'> ${vm.cursoDetalle[0].AsiHorasSemanalesTeorico} </b> horas(s) <b>T</b> semanal(es), se detecto que el curso contaria con`;
                            mensajeError += `<br> <b class='text-white bg-red px-1'>${contadorSubgrupos[grupo]} </b> hora(s) semanal(es) en el subgrupo <b>${grupo}</b> superando los máximos permitidos`;
                            contadorFaltas++;
                        }

                        // Evaluamos las horas del subgrupo de teoria 00 sea menor que la cantidad de creditos de teoria
                        if (!solo00 && grupo == "00" && !gastoTodasHorasEn00 && vm.cursoDetalle[0].AsiHorasSemanalesTeorico != '' && contadorSubgrupos[grupo] > vm.cursoDetalle[0].AsiHorasSemanalesTeorico) {
                            console.log("Es 00 y excede las horas totales de T", vm.cursoDetalle[0].AsiHorasSemanalesTeorico, grupo, contadorSubgrupos[grupo]);
                            mensajeError += `<br> Se encontraron <b class='text-white bg-red px-1'>${contadorSubgrupos[grupo]} </b> hora(s) semanal(es) en el subgrupo <b>${grupo}</b> y deben ser máximo <b class='text-white bg-green px-1'>${vm.cursoDetalle[0].AsiHorasSemanalesTeorico}</b> hora(s) teorico semanal(es)`;
                            contadorFaltas++;
                        }

                        // Evaluamos si el subgrupo tiene menos horas que la cantidad de creditos de practica
                        console.log("Diferente 00 y excede las horas totales de P", vm.cursoDetalle[0].AsiHorasSemanalesPractica, grupo, contadorSubgrupos[grupo]);
                        if (grupo != "00" && !gastoTodasHorasEn00 && vm.cursoDetalle[0].AsiHorasSemanalesPractica != '' && contadorSubgrupos[grupo] > vm.cursoDetalle[0].AsiHorasSemanalesPractica) {
                            console.log("Diferente 00 y excede las horas totales de P", vm.cursoDetalle[0].AsiHorasSemanalesPractica, grupo, contadorSubgrupos[grupo]);
                            mensajeError += `<br> Se encontraron <b class='text-white bg-red px-1'>${contadorSubgrupos[grupo]} </b> hora(s) semanal(es) en el subgrupo <b>${grupo}</b> y deben ser máximo <b class='text-white bg-green px-1'>${vm.cursoDetalle[0].AsiHorasSemanalesPractica}</b> hora(s) practica semanal(es)`;
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
                    if (Array.isArray(vm.cursoHorario)) {
                        vm.cursoHorario.forEach(function (elemento) {
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

                    if (vm.cursoDetalle[0].AsiHorasSemanalesPractica != '' && totalHoras > vm.cursoDetalle[0].AsiHorasSemanalesPractica) {
                        const mensajeError = "<b>Importante: </b> La asignatura de caracter <b>" + CarCodigo.trim() + "</b> cuenta con un máximo de <b class='text-white bg-green px-1'>" + vm.cursoDetalle[0].AsiHorasSemanalesPractica + "</b> hora(s) semanal(es) de Practica y se detecto que el <b>subgrupo " + SubGrupoNuevo + "</b> cuenta con <b class='text-white bg-red px-1'>" + totalHoras + "</b> hora(s) semanal(es), por favor verificar.";
                        mostrarSweetAlertWarning(mensajeError);
                        return false;
                    }
                }
            }
            return true;
        }

        function verificarHorasCaracter(CarCodigo) {

            if (CarCodigo !== undefined && CarCodigo !== '' && vm.cursoDetalle && vm.cursoDetalle[0]) {
                
                let AsiCreditos = vm.cursoDetalle[0].AsiCreditos || 0;
                let AsiCreditosTeoria = vm.cursoDetalle[0].AsiCreditosTeoria || 0;
                let AsiCreditosPractica = vm.cursoDetalle[0].AsiCreditosPractica || 0;
         

                if (CarCodigo == 'T' && vm.cursoHorario.length < AsiCreditosTeoria) {
                    vm.mensajeVerificarHorasCaracter = "<b>Importante: </b> La asignatura de caracter <b>T</b> cuenta con <b>" + AsiCreditosTeoria + "</b> credito(s) de Teoria y se detecto que el curso cuenta con " + vm.cursoHorario.length + " hora(s) semanal(es), deberia tener mínimo <b>" + AsiCreditosTeoria + "</b> hora(s) semanal(es), por favor verificar.";
                    return true;
                }

                if (CarCodigo == 'TP') {
                    vm.mensajeVerificarHorasCaracter = `<b>Importante: </b> La asignatura de caracter <b>${CarCodigo}</b> cuenta con ${AsiCreditosTeoria} credito(s) de Teoria y ${AsiCreditosPractica} credito(s) de Practica y se detecto que el curso cuenta con`;
                    let contadorFaltas = 0;
                    let contadorSubgrupos = {};

                    vm.cursoHorario.forEach(function (elemento) {
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
                        if (solo00 && grupo == "00" && contadorSubgrupos[grupo] < AsiCreditos) {
                            vm.mensajeVerificarHorasCaracter = `<b>Importante: </b> La asignatura de caracter <b>${CarCodigo}</b> solo tiene el subgrupo 00, tiene ${AsiCreditos} credito(s) total(es), se detecto que el curso cuenta con`;
                            vm.mensajeVerificarHorasCaracter += ` <b>${contadorSubgrupos[grupo]} </b> hora(s) semanal(es) en el subgrupo <b>${grupo}</b> y deberian ser mínimo <b>${AsiCreditos}</b> hora(s) semanal(es)`;
                            contadorFaltas++;
                        }

                        // Evaluamos las horas del subgrupo de teoria 00 sea menor que la cantidad de creditos de teoria
                        if (!solo00 && grupo == "00" && contadorSubgrupos[grupo] < AsiCreditosTeoria) {
                            vm.mensajeVerificarHorasCaracter += ` <b>${contadorSubgrupos[grupo]} </b> hora(s) semanal(es) en el subgrupo <b>${grupo}</b> y deberian ser mínimo <b>${AsiCreditosTeoria}</b> hora(s) semanal(es)`;
                            contadorFaltas++;
                        }

                        // Evaluamos si el subgrupo tiene menos horas que la cantidad de creditos de practica
                        if (!solo00 && grupo != "00" && contadorSubgrupos[grupo] < AsiCreditosPractica) {
                            vm.mensajeVerificarHorasCaracter += `, <b>${contadorSubgrupos[grupo]} </b> hora(s) semanal(es) en el subgrupo <b>${grupo}</b> y deberian ser mínimo <b>${AsiCreditosPractica}</b> hora(s) semanal(es)`;
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

        function buscarAsignatura() {
            if (vm.filtroAsignatura == '' || vm.filtroAsignatura == undefined) {
                mostrarSweetAlertWarning("Debe ingresar el nombre o el código alfanumerico de la asignatura.");
                return false;
            }

            mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 14,
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
                    vm.busquedaAsignatura = salida.data;
                    swal.closeModal();
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
                CurCodigo: vm.cursoSeleccionado.CurCodigo,
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

        function validarCreacionCurso() {
            if (vm.CursoCrear.CalCodigo == '' || vm.CursoCrear.CalCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar una calendario.");
                return false;
            }
            if (vm.CursoCrear.SedCodigo == '' || vm.CursoCrear.SedCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar una sede.");
                return false;
            }
            if (vm.CursoCrear.CurNotaParcial == '' || vm.CursoCrear.CurNotaParcial === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar una nota parcial.");
                return false;
            }
            if (vm.CursoCrear.TicCodigo == '' || vm.CursoCrear.TicCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar una modalidad.");
                return false;
            }
            if (vm.CursoCrear.CutCodigo == '' || vm.CursoCrear.CutCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar un tipo de curso.");
                return false;
            }
            if (vm.CursoCrear.TesCodigo == '' || vm.CursoCrear.TesCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar el tipo de calificación.");
                return false;
            }
            if (vm.CursoCrear.AsiCodigo == '' || vm.CursoCrear.AsiCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar una asignatura.");
                return false;
            }
            if (vm.CursoCrear.CurCupo == '' || vm.CursoCrear.CurCupo === undefined) {
                mostrarSweetAlertWarning("Debe ingresar el cupo.");
                return false;
            }
            if (!esEntero(vm.CursoCrear.CurCupo)) {
                mostrarSweetAlertWarning("El cupo debe ser numérico.");
                return false;
            }
            if (vm.CursoCrear.CurAmpliacionCupo == '' || vm.CursoCrear.CurAmpliacionCupo === undefined) {
                mostrarSweetAlertWarning("Debe ingresar el cupo reservado.");
                return false;
            }
            if (!esEntero(vm.CursoCrear.CurAmpliacionCupo)) {
                mostrarSweetAlertWarning("El cupo reservado del curso debe ser númerico.");
                return false;
            }
            if (parseInt(vm.CursoCrear.CurAmpliacionCupo) < 0 || vm.CursoCrear.CurAmpliacionCupo > vm.CursoCrear.CurCupo) {
                mostrarSweetAlertWarning("La reserva de cupo debe ser mayor a 1 y menor al cupo total: " + vm.CursoCrear.CurCupo + ".");
                return false;
            }
            if (vm.CursoCrear.CurSemanas == '' || vm.CursoCrear.CurSemanas === undefined) {
                mostrarSweetAlertWarning("Debe ingresar la cantidad de semanas.");
                return false;
            }
            if (vm.CursoCrear.CurSemanas < 1 || vm.CursoCrear.CurSemanas > 18) {
                mostrarSweetAlertWarning("Las semanas del curso no pueden ser menor de 1 o mayor a 18.");
                return false;
            }
            if (vm.CursoCrear.CurExclusivo == '' || vm.CursoCrear.CurExclusivo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar la exclusividad.");
                return false;
            }
            if (vm.CursoCrear.UapCodigo == '' || vm.CursoCrear.UapCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar un docente coordinador.");
                return false;
            }
            return true;
        }

        function crearCurso() {
            if (!validarCreacionCurso()) {
                return false;
            }

            mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 19,
                UaaCodigo: vm.CursoCrear.UaaCodigo,
                CalCodigo: vm.CursoCrear.CalCodigo,
                SedCodigo: vm.CursoCrear.SedCodigo,
                CurNotaParcial: vm.CursoCrear.CurNotaParcial,
                TicCodigo: vm.CursoCrear.TicCodigo,
                CutCodigo: vm.CursoCrear.CutCodigo,
                TesCodigo: vm.CursoCrear.TesCodigo,
                AsiCodigo: vm.CursoCrear.AsiCodigo,
                PlaCodigo: vm.CursoCrear.PlaCodigo,
                CurCupo: vm.CursoCrear.CurCupo,
                CurAmpliacionCupo: vm.CursoCrear.CurAmpliacionCupo,
                CurSemanas: vm.CursoCrear.CurSemanas,
                CurExclusivo: vm.CursoCrear.CurExclusivo,
                UapCodigo: vm.CursoCrear.UapCodigo,
                VinNombre: vm.CursoCrear.VinNombre,
                CurUrl: vm.CursoCrear.CurUrl,
                CurObservaciones: vm.CursoCrear.CurObservaciones,
                PlanesExclusivos: vm.CursoCrear.PlanesExclusivos
            };

            $http({
                url: "logica/curcrea.php",
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
                    vm.Curso = salida.data;
                    vm.formularioEdicionCursos = 0;
                    vm.formularioCreacionCursos = 0;
                    vm.informacionCursos = 1;
                    // consultarCurso('Creacion');
                    let curso = {
                        CurCodigo: salida["CurCodigo"]
                    };
                    consultarDetalleCurso(curso, 'creacion');
                    swal.closeModal();
                    mostrarSweetAlertSuccess(salida["mensaje"]);
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function deseleccionarPlanAcademico(plan_codigo) {
            vm.CursoCrear.PlanesExclusivos = vm.CursoCrear.PlanesExclusivos.filter(
                item => item != plan_codigo
            );
        }

        function seleccionarPlanAcademico(plan_codigo) {
            if (!vm.CursoCrear.PlanesExclusivos) {
                vm.CursoCrear.PlanesExclusivos = [];
            }
            if (!vm.CursoCrear.PlanesExclusivos.includes(plan_codigo)) {
                vm.CursoCrear.PlanesExclusivos.push(plan_codigo);
            }
        }

        function consultarPlanExclusivoCreacion() {
            vm.listaPlanExclusivo = [];
            vm.objeto = {
                accion: 18
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
                    vm.listaPlanExclusivo = salida.data;
                    // vm.CursoCrear.PlanesExclusivos = [];
                    swal.closeModal();
                    abrirModal("modalPlanExclusivoCrear");
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function cancelarCrearCurso() {
            vm.informacionCursos = 0;
            vm.formularioEdicionCursos = 0;
            vm.formularioCreacionCursos = 0;
            vm.formularioCrearHorario = 0;
            vm.tipoOperacion = ''; //creacion, edicion
            vm.CursoCrear = [];
        }

        function formularioCrearCurso() {
            vm.informacionCursos = 0;
            vm.formularioEdicionCursos = 0;
            vm.formularioCreacionCursos = 1;
            vm.tipoOperacion = 'creacion'; //creacion, edicion
            vm.cursoDetalle = {};
            vm.cursoSeleccionado = {};
            vm.crearHorario = [];
            vm.creacionHorario = 0;
            vm.CursoCrear = {
                CurNotaParcial: 'S',
                TicCodigo: '1',
                CutCodigo: '1',
                TesCodigo: '1'
            };
        }

        function actualizarCurso() {
            if (!validarActualizacionCurso()) {
                return false;
            }

            mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 15,
                CurCodigo: vm.CursoActualizar.CurCodigo,
                CalCodigo: vm.CursoActualizar.CalCodigo,
                SedCodigo: vm.CursoActualizar.SedCodigo,
                PlaCodigo: vm.CursoActualizar.PlaCodigo,
                TicCodigo: vm.CursoActualizar.TicCodigo,
                CurNotaParcial: vm.CursoActualizar.CurNotaParcial,
                TesCodigo: vm.CursoActualizar.TesCodigo,
                CurEstado: vm.CursoActualizar.CurEstado,
                AsiCodigo: vm.CursoActualizar.AsiCodigo,
                CurCupo: vm.CursoActualizar.CurCupo,
                CurAmpliacionCupo: vm.CursoActualizar.CurAmpliacionCupo,
                CurSemanas: vm.CursoActualizar.CurSemanas,
                CurExclusivo: vm.CursoActualizar.CurExclusivo,
                UapCodigo: vm.CursoActualizar.UapCodigo,
                CurUrl: vm.CursoActualizar.CurUrl,
                CurObservaciones: vm.CursoActualizar.CurObservaciones,
                CurGrupo: vm.CursoActualizar.CurGrupo,
                CutCodigo: vm.CursoActualizar.CutCodigo
            };

            $http({
                url: "logica/curcrea.php",
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
                    consultarDetalleCurso(vm.cursoSeleccionado);
                    // consultarCursos('Consulta');
                    mostrarSweetAlertSuccess(salida["mensaje"]);
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });

        }

        function validarActualizacionCurso() {
            if (tieneHorarioProgramado() && vm.cursoDetalle && vm.cursoDetalle[0] && vm.CursoActualizar.TicCodigo != vm.cursoDetalle[0].TicCodigo) {
                mostrarSweetAlertWarning("No se puede cambiar la modalidad porque el curso ya tiene horario programado.");
                return false;
            }
            if (vm.CursoActualizar.SedCodigo == '' || vm.CursoActualizar.SedCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar una sede.");
                return false;
            }
            if (vm.CursoActualizar.TicCodigo == '' || vm.CursoActualizar.TicCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar una modalidad.");
                return false;
            }
            if (vm.CursoActualizar.CurNotaParcial == '' || vm.CursoActualizar.CurNotaParcial === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar una nota parcial.");
                return false;
            }
            if (vm.CursoActualizar.TesCodigo == '' || vm.CursoActualizar.TesCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar el tipo de calificación.");
                return false;
            }
            if (vm.CursoActualizar.CurEstado == '' || vm.CursoActualizar.CurEstado === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar un estado.");
                return false;
            }
            if (vm.CursoActualizar.AsiCodigo == '' || vm.CursoActualizar.AsiCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar una asignatura.");
                return false;
            }
            if (vm.CursoActualizar.CurCupo == '' || vm.CursoActualizar.CurCupo === undefined) {
                mostrarSweetAlertWarning("Debe ingresar el cupo.");
                return false;
            }
            if (vm.CursoActualizar.CurCupo < 0 || vm.CursoActualizar.CurCupo > 100) {
                mostrarSweetAlertWarning("El cupo debe ser numérico.");
                return false;
            }
            if (vm.CursoActualizar.CurAmpliacionCupo == '' || vm.CursoActualizar.CurAmpliacionCupo === undefined) {
                mostrarSweetAlertWarning("Debe ingresar el cupo reservado.");
                return false;
            }
            if (vm.CursoActualizar.CurAmpliacionCupo < 0) {
                mostrarSweetAlertWarning("La reserva de cupo debe ser mayor que 0");
                return false;
            }
            if (parseInt(vm.CursoActualizar.CurAmpliacionCupo) > parseInt(vm.CursoActualizar.CurCupo)) {
                mostrarSweetAlertWarning("La reserva de cupo: " + vm.CursoActualizar.CurAmpliacionCupo + " debe menor al cupo total: " + vm.CursoActualizar.CurCupo + ".");
                return false;
            }
            if (vm.CursoActualizar.CurSemanas == '' || vm.CursoActualizar.CurSemanas === undefined) {
                mostrarSweetAlertWarning("Debe ingresar la cantidad de semanas.");
                return false;
            }
            if (vm.CursoActualizar.CurSemanas < 1 || vm.CursoActualizar.CurSemanas > 18) {
                mostrarSweetAlertWarning("Las semanas del curso no pueden ser menor de 1 o mayor a 18.");
                return false;
            }
            if (vm.CursoActualizar.CurExclusivo == '' || vm.CursoActualizar.CurExclusivo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar la exclusividad.");
                return false;
            }
            if (vm.CursoActualizar.UapCodigo == '' || vm.CursoActualizar.UapCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar un docente coordinador.");
                return false;
            }
            return true;
        }

        function ponerComoExclusivo(PlaCodigo) {
            if (PlaCodigo == '' || PlaCodigo === undefined) {
                mostrarSweetAlertWarning("No se encontro el codigo del plan académico");
                return false;
            }

            if (vm.cursoDetalle[0].CurCodigo == '' || vm.cursoDetalle[0].CurCodigo === undefined) {
                mostrarSweetAlertWarning("No se encontro el codigo del curso seleccionado.");
                return false;
            }

            vm.objeto = {
                accion: 13,
                PlaCodigo: PlaCodigo,
                CurCodigo: vm.cursoDetalle[0].CurCodigo
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
                    consultarPlanExclusivoCurso();
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function quitarExclusividad(CupCodigo) {
            if (CupCodigo == '' || CupCodigo === undefined) {
                mostrarSweetAlertWarning("No se encontro el codigo de la exclusividad.");
                return false;
            }

            vm.objeto = {
                accion: 12,
                CupCodigo: CupCodigo
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
                    consultarPlanExclusivoCurso();
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultarPlanExclusivoCurso() {
            if (vm.cursoDetalle[0].CurCodigo == '' || vm.cursoDetalle[0].CurCodigo === undefined) {
                mostrarSweetAlertWarning("No se encontro el codigo del curso seleccionado.");
                return false;
            }

            vm.listaPlanExclusivo = [];

            vm.objeto = {
                accion: 11,
                CurCodigo: vm.cursoDetalle[0].CurCodigo
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
                    vm.listaPlanExclusivo = salida.data;
                    swal.closeModal();
                    abrirModal("modalPlanExclusivoEditar");
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function actualizarAsignatura(asignatura) {
            if (vm.tipoOperacion == 'edicion') {
                vm.CursoActualizar.AsiNombreCorto = asignatura.AsiNombreCorto;
                vm.CursoActualizar.AsiCodigo = asignatura.AsiCodigo;
                vm.CursoActualizar.AsiNombre = asignatura.AsiNombre;
                vm.CursoActualizar.CarCodigo = asignatura.CarCodigo;
                vm.CursoActualizar.CarNombre = asignatura.CarNombre;
                vm.CursoActualizar.AsiCreditos = asignatura.AsiCreditos;
                vm.CursoActualizar.AsiCreditosTeoria = asignatura.AsiCreditosTeoria;
                vm.CursoActualizar.AsiCreditosPractica = asignatura.AsiCreditosPractica;
                vm.CursoActualizar.PlaNombre = '';
                vm.CursoActualizar.PlaCodigo = '';
            }

            if (vm.tipoOperacion == 'creacion') {
                vm.CursoCrear.AsiNombreCorto = asignatura.AsiNombreCorto;
                vm.CursoCrear.AsiCodigo = asignatura.AsiCodigo;
                vm.CursoCrear.AsiNombre = asignatura.AsiNombre;
                vm.CursoCrear.CarCodigo = asignatura.CarCodigo;
                vm.CursoCrear.CarNombre = asignatura.CarNombre;
                vm.CursoCrear.AsiCreditos = asignatura.AsiCreditos;
                vm.CursoCrear.AsiCreditosTeoria = asignatura.AsiCreditosTeoria;
                vm.CursoCrear.AsiCreditosPractica = asignatura.AsiCreditosPractica;
                vm.CursoActualizar.PlaNombre = '';
                vm.CursoActualizar.PlaCodigo = '';
            }

            consultarPropietarioAsignatura(asignatura.AsiCodigo);
        }

        function consultarAsignaturasEquivalentes() {
            vm.listaAsignaturas = [];

            if (vm.unidadSeleccionada == '' || vm.unidadSeleccionada === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar una unidad.");
                return false;
            }

            mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 12,
                UaaCodigo: vm.unidadSeleccionada,
                // CalCodigo: vm.cursoDetalle[0].CalCodigo
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
                    swal.closeModal();
                    vm.listaAsignaturas = salida.data;
                    abrirModal("modalAsignaturas");
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function modalAsignaturasEquivalentes() {

            if (vm.tipoOperacion == 'creacion') {
                if (vm.CursoCrear.CalCodigo == '' || vm.CursoCrear.CalCodigo === undefined) {
                    mostrarSweetAlertWarning("El curso no tiene un calendario establecido.");
                    return false;
                }
            }

            vm.listaUnidades = [];

            mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 4,
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
                    vm.listaUnidades = salida.data;
                    swal.closeModal();
                    abrirModal("modalAsignaturas");
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultarPropietarioAsignatura(AsiCodigo) {
            if (AsiCodigo == '' || AsiCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar una asignatura.");
                return false;
            }
            let CalCodigo = '';
            if (vm.tipoOperacion == 'creacion') {
                if (vm.CursoCrear.CalCodigo == '' || vm.CursoCrear.CalCodigo === undefined) {
                    mostrarSweetAlertWarning("El curso no tiene un calendario establecido.");
                    return false;
                }
                CalCodigo = vm.CursoCrear.CalCodigo;
            } else {
                if (vm.cursoDetalle[0].CalCodigo == '' || vm.cursoDetalle[0].CalCodigo === undefined) {
                    mostrarSweetAlertWarning("El curso no tiene un calendario establecido.");
                    return false;
                }
                CalCodigo = vm.cursoDetalle[0].CalCodigo;
            }

            vm.objeto = {
                accion: 10,
                AsiCodigo: AsiCodigo,
                CalCodigo: CalCodigo
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
                    if (vm.tipoOperacion == 'edicion') {
                        vm.CursoActualizar.UaaCodigo = salida.data[0].UaaCodigo;
                        vm.CursoActualizar.UaaNombreCorto = salida.data[0].UaaNombreCorto;
                        vm.CursoActualizar.CurGrupo = salida.data[0].CurGrupo;
                    }
                    if (vm.tipoOperacion == 'creacion') {
                        vm.CursoCrear.UaaCodigo = salida.data[0].UaaCodigo;
                        vm.CursoCrear.UaaNombreCorto = salida.data[0].UaaNombreCorto;
                        vm.CursoCrear.CurGrupo = salida.data[0].CurGrupo;
                    }
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function actualizarAsignaturaPlan(asignatura) {
            if (vm.tipoOperacion == 'edicion') {
                vm.CursoActualizar.AsiNombreCorto = asignatura.AsiNombreCorto;
                vm.CursoActualizar.AsiCodigo = asignatura.AsiCodigo;
                vm.CursoActualizar.AsiNombre = asignatura.AsiNombre;
                vm.CursoActualizar.CarCodigo = asignatura.CarCodigo;
                vm.CursoActualizar.CarNombre = asignatura.CarNombre;
                vm.CursoActualizar.AsiCreditos = asignatura.AsiCreditos;
                vm.CursoActualizar.AsiCreditosTeoria = asignatura.AsiCreditosTeoria;
                vm.CursoActualizar.AsiCreditosPractica = asignatura.AsiCreditosPractica;
                vm.CursoActualizar.PlaNombre = asignatura.PlaNombre;
                vm.CursoActualizar.PlaCodigo = asignatura.PlaCodigo;
            }

            if (vm.tipoOperacion == 'creacion') {
                vm.CursoCrear.AsiNombreCorto = asignatura.AsiNombreCorto;
                vm.CursoCrear.AsiCodigo = asignatura.AsiCodigo;
                vm.CursoCrear.AsiNombre = asignatura.AsiNombre;
                vm.CursoCrear.CarCodigo = asignatura.CarCodigo;
                vm.CursoCrear.CarNombre = asignatura.CarNombre;
                vm.CursoCrear.AsiCreditos = asignatura.AsiCreditos;
                vm.CursoCrear.AsiCreditosTeoria = asignatura.AsiCreditosTeoria;
                vm.CursoCrear.AsiCreditosPractica = asignatura.AsiCreditosPractica;
                vm.CursoCrear.PlaNombre = asignatura.PlaNombre;
                vm.CursoCrear.PlaCodigo = asignatura.PlaCodigo;
            }

            consultarPropietarioAsignatura(asignatura.AsiCodigo);
        }

        function consultarAsignaturasPlan() {
            if (vm.planAcademicoSeleccionado == '' || vm.planAcademicoSeleccionado === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar un plan académico.");
                return false;
            }

            vm.asignaturasPlan = [];

            mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 11,
                PlaCodigo: vm.planAcademicoSeleccionado
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
                    vm.asignaturasPlan = salida.data;
                    swal.closeModal();
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultarPlanesAcademicos() {

            if (vm.tipoOperacion == 'creacion') {
                if (vm.CursoCrear.CalCodigo == '' || vm.CursoCrear.CalCodigo === undefined) {
                    mostrarSweetAlertWarning("El curso no tiene un calendario establecido.");
                    return false;
                }
            }

            vm.listaPlanesAcademicos = [];

            mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 10,
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
                    vm.listaPlanesAcademicos = salida.data;
                    swal.closeModal();
                    abrirModal("modalPlanAcademico");
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function cancelarEditarCurso() {
            vm.informacionCursos = 1;
            vm.formularioEdicionCursos = 0;
            vm.formularioCreacionCursos = 0;
            vm.tipoOperacion = ''; //creacion, edicion
            vm.CursoActualizar = {};
        }

        function consultaTipoCurso() {
            vm.listaTipoCurso = [];
            vm.objeto = {
                accion: 16
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
                    vm.listaTipoCurso = salida.data;
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

        function formularioEditarCurso(curso) {
            vm.informacionCursos = 0;
            vm.formularioEdicionCursos = 1;
            vm.formularioCreacionCursos = 0;
            vm.tipoOperacion = 'edicion'; //creacion, edicion
            vm.crearHorario = [];
            vm.creacionHorario = 0;

            vm.CursoActualizar.CurCodigo = curso.CurCodigo;
            vm.CursoActualizar.UapCodigo = curso.UapCodigo;
            vm.CursoActualizar.AsiCodigo = curso.AsiCodigo;
            vm.CursoActualizar.SedCodigo = curso.SedCodigo;
            vm.CursoActualizar.CalCodigo = curso.CalCodigo;
            vm.CursoActualizar.CalNombre = curso.CalNombre;
            vm.CursoActualizar.CurGrupo = curso.CurGrupo;
            vm.CursoActualizar.CurCupo = curso.CurCupo;
            vm.CursoActualizar.CurEstado = curso.CurEstado;
            vm.CursoActualizar.PlaCodigo = curso.PlaCodigo;
            vm.CursoActualizar.PlaNombre = curso.PlaNombre;
            vm.CursoActualizar.CutCodigo = curso.CutCodigo;
            vm.CursoActualizar.CutNombre = curso.CutNombre;
            vm.CursoActualizar.CurExclusivo = curso.CurExclusivo;
            vm.CursoActualizar.SedNombre = curso.SedNombre;
            vm.CursoActualizar.AsiNombreCorto = curso.AsiNombreCorto;
            vm.CursoActualizar.AsiNombre = curso.AsiNombre;
            vm.CursoActualizar.AsiCreditos = curso.AsiCreditos;
            vm.CursoActualizar.AsiCreditosTeoria = curso.AsiCreditosTeoria;
            vm.CursoActualizar.AsiCreditosPractica = curso.AsiCreditosPractica;
            vm.CursoActualizar.PerNombreApellido = curso.PerNombreApellido;
            vm.CursoActualizar.VinNombre = curso.VinNombre;
            vm.CursoActualizar.CdpCodigo = curso.CdpCodigo;
            vm.CursoActualizar.CurSemanas = curso.CurSemanas;
            vm.CursoActualizar.CarCodigo = curso.CarCodigo;
            vm.CursoActualizar.CarNombre = curso.CarNombre;
            vm.CursoActualizar.TicCodigo = curso.TicCodigo;
            vm.CursoActualizar.CurObservaciones = curso.CurObservaciones;
            vm.CursoActualizar.CurAmpliacionCupo = curso.CurAmpliacionCupo;
            vm.CursoActualizar.CurNotaParcial = curso.CurNotaParcial;
            vm.CursoActualizar.TesCodigo = curso.TesCodigo;
            vm.CursoActualizar.UaaNombreCorto = curso.UaaNombreCorto;
            vm.CursoActualizar.UaaCodigo = curso.UaaCodigo;
            vm.CursoActualizar.CurUrl = curso.CurUrl;
            vm.CursoActualizar.UaaHorario = curso.UaaHorario;
            vm.CursoActualizar.TotalMatriculados = curso.TotalMatriculados;
        }

        function tieneHorarioProgramado() {
            if (vm.cursoDetalle && vm.cursoDetalle[0]) {
                if (vm.cursoDetalle[0].UaaHorario !== undefined && vm.cursoDetalle[0].UaaHorario !== null && vm.cursoDetalle[0].UaaHorario !== '') {
                    return true;
                }
            }

            return Array.isArray(vm.cursoHorario) && vm.cursoHorario.length > 0;
        }

        function programarHorario() {
            if (vm.crearHorario.UapCodigo == '' || vm.crearHorario.UapCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar un docente.");
                return false;
            }
            if (vm.crearHorario.FechaInicio == '' || vm.crearHorario.FechaInicio === undefined) {
                mostrarSweetAlertWarning("Debe ingresar la fecha de inicio.");
                return false;
            }
            if (vm.crearHorario.FechaFin == '' || vm.crearHorario.FechaFin === undefined) {
                mostrarSweetAlertWarning("Debe ingresar la fecha de fin.");
                return false;
            }
            if (vm.crearHorario.SubGrupo == '' || vm.crearHorario.SubGrupo === undefined) {
                mostrarSweetAlertWarning("Debe ingresar el subgrupo.");
                return false;
            }
            if (!esEntero(vm.crearHorario.SubGrupo) || vm.crearHorario.SubGrupo < 0) {
                mostrarSweetAlertWarning("El subgrupo solo puede ser numérico y mayor a cero. Ej 00, 01, 02...");
                return false;
            } else {
                vm.crearHorario.SubGrupo = ("0" + vm.crearHorario.SubGrupo).slice(-2);
            }

            if (vm.cursoDetalle[0].CarCodigo.trim() == 'T') {
                if (vm.crearHorario.SubGrupo != '00') {
                    mostrarSweetAlertWarning("El curso Teorico solo puede tener subgrupo 00.");
                    return false;
                }
            }

            if (vm.cursoDetalle[0].CarCodigo.trim() == 'P' || vm.cursoDetalle[0].CarCodigo.trim() == 'PP' || vm.cursoDetalle[0].CarCodigo.trim() == 'PF') {
                if (vm.crearHorario.SubGrupo == '00') {
                    mostrarSweetAlertWarning("El curso Practico no puede tener subgrupo 00.");
                    return false;
                }
            }

            if (vm.cursoDetalle[0].CarCodigo.trim() == 'TP') {
                let existeSubgrupoTeoria = false;
                if (vm.cursoHorario !== null) {
                    for (let objeto of vm.cursoHorario) {
                        if (objeto.EsoSubGrupo === '00') {
                            existeSubgrupoTeoria = true;
                        }
                    }
                }
                if (!existeSubgrupoTeoria && vm.crearHorario.SubGrupo != '00') {
                    mostrarSweetAlertWarning("El curso Teorico Practico debe ingresar primero el subgrupo 00.");
                    return false;
                }
            }

            if (vm.crearHorario.SubGrupo != '' && esEntero(vm.crearHorario.SubGrupo) && vm.crearHorario.SubGrupo != '00') {
                if (vm.crearHorario.CupoSubgrupo == '' || vm.crearHorario.CupoSubgrupo === undefined) {
                    mostrarSweetAlertWarning("Debe ingresar el cupo del subgrupo si el subgrupo es diferentes de 00.");
                    return false;
                }

                if (!esEntero(vm.crearHorario.CupoSubgrupo) || vm.crearHorario.CupoSubgrupo < 0) {
                    mostrarSweetAlertWarning("El cupo del subgrupo debe ser mayor a 0.");
                    return false;
                }
            }
            if (vm.crearHorario.EspCodigo == '' || vm.crearHorario.EspCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar el espacio.");
                return false;
            }

            if (vm.crearHorario.DiaCodigo == '' || vm.crearHorario.DiaCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar el día.");
                return false;
            }

            if (vm.crearHorario.HorasSeleccionadas == '' || vm.crearHorario.HorasSeleccionadas === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar al menos una hora.");
                return false;
            }

            if (vm.cursoDetalle[0].CalCodigo == '' || vm.cursoDetalle[0].CalCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar un calendario.");
                return false;
            }

            if (vm.crearHorario.Uaa.UaaCodigo == '' || vm.crearHorario.Uaa.UaaCodigo === undefined) {
                mostrarSweetAlertWarning("No se encontro el codigo de la unidad seleccionado.");
                return false;
            }

            if (vm.crearHorario.TipoDocente == 'Prestado') {
                var horasPermitidasPrestamo = Array.isArray(vm.crearHorario.HorarioPermitido)
                    ? vm.crearHorario.HorarioPermitido.filter(function (horario) {
                        return String(horario.DiaCodigo) === String(vm.crearHorario.DiaCodigo);
                    }).map(function (horario) {
                        return String(horario.HraCodigo);
                    })
                    : [];
                var todasLasHorasPermitidas = vm.crearHorario.HorasSeleccionadas.every(function (hora) {
                    return horasPermitidasPrestamo.indexOf(String(hora)) !== -1;
                });

                if (!todasLasHorasPermitidas) {
                    mostrarSweetAlertWarning("Las horas seleccionadas no coinciden con el horario permitido en la solicitud de préstamo docente.");
                    return false;
                }
            }

            //Si es presencial (1) y subgrupo 00, no puede ser en un aula virtual
            if (vm.cursoDetalle[0].CalTipo == 'A') {
                if (vm.crearHorario.SubGrupo == '00' && vm.cursoDetalle[0].TicCodigo == 1) {
                    if (vm.crearHorario.EspTipo == 'V') {
                        let mensaje = "Los cursos teoricos o teorico practicos creados con modalidad presencial no pueden ser programados en un espacio virtual.";
                        mostrarSweetAlertWarning(mensaje);
                        return false;
                    }
                }
            }

            //Si es virtual y subgrupo 00 no puede ser en un aula fisica
            if (vm.cursoDetalle[0].CalTipo == 'A') {
                if (vm.crearHorario.SubGrupo == '00' && vm.cursoDetalle[0].TicCodigo == 2) {
                    if (vm.crearHorario.EspTipo == 'F') {
                        let mensaje = "Los cursos virtuales no pueden seleccionar espacios físicos.";
                        mostrarSweetAlertWarning(mensaje);
                        return false;
                    }
                }
            }

            // Validar tope de horas maximas permitidas
            if (!verificarHorasSemanales(vm.cursoDetalle[0].CarCodigo, vm.crearHorario.SubGrupo)) {
                return false;
            }

            vm.objeto = {
                accion: 9,
                TicCodigo: vm.cursoDetalle[0].TicCodigo,
                UapCodigo: vm.crearHorario.UapCodigo,
                UapSedCodigo: vm.crearHorario.UapSedCodigo,
                UaaCodigo: vm.crearHorario.Uaa.UaaCodigo,
                DedCodigo: vm.crearHorario.DedCodigo,
                VinCodigo: vm.crearHorario.VinCodigo,
                FechaInicio: vm.crearHorario.FechaInicio,
                FechaFin: vm.crearHorario.FechaFin,
                SubGrupo: vm.crearHorario.SubGrupo,
                CupoSubgrupo: vm.crearHorario.CupoSubgrupo,
                EspCodigo: vm.crearHorario.EspCodigo,
                CurCodigo: vm.crearHorario.CurCodigo,
                DiaCodigo: vm.crearHorario.DiaCodigo,
                HorasSeleccionadas: vm.crearHorario.HorasSeleccionadas,
                CalCodigo: vm.cursoDetalle[0].CalCodigo,
                CalNombre: vm.cursoDetalle[0].CalNombre,
                EspTipo: vm.crearHorario.EspTipo,
                PerCodigo: vm.cursoDetalle[0].PeriodoCodigo,
                UapPerCodigo: vm.crearHorario.UapPerCodigo,
                PerNN: vm.crearHorario.PerNN,
                CarCodigo: vm.cursoDetalle[0].CarCodigo,
                AsiCreditos: vm.cursoDetalle[0].AsiCreditos,
                AsiCreditosTeoria: vm.cursoDetalle[0].AsiCreditosTeoria,
                AsiCreditosPractica: vm.cursoDetalle[0].AsiCreditosPractica,
                CurSemanas: vm.cursoDetalle[0].CurSemanas,
                UaaDependencia: vm.crearHorario.Uaa.UaaDependencia,
                CalTipo: vm.cursoDetalle[0].CalTipo,
                AsiCodigo: vm.cursoDetalle[0].AsiCodigo,
                TipoDocente: vm.crearHorario.TipoDocente,
                SpdCodigo: vm.crearHorario.SpdCodigo,
            };

            mostrarSweetAlertCargando();

            $http({
                url: "logica/buscurso.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                var salida = response.data;

                if (salida && salida["resultado"] === false) {
                    swal.closeModal();
                    mostrarErrorProgramacionHorario(salida);
                    console.error(salida["consola"]);
                } else if (salida && salida["resultado"] === true) {
                    consultarHorarioCurso('Consulta');
                    mostrarSweetAlertSuccess(salida["mensaje"]);
                } else {
                    swal.closeModal();
                    mostrarErrorProgramacionHorario(salida);
                    console.error("Respuesta inesperada al programar el horario:", salida);
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarErrorProgramacionHorario(response.data, response.status);
                console.error(response.data);
            });

        }

        function consultarHoras() {
            if (vm.crearHorario.DiaCodigo == '' || vm.crearHorario.DiaCodigo === undefined) {
                mostrarSweetAlertWarning("Debe de seleccionar el dia.");
                return false;
            }
            vm.listaHoras = [];
            vm.objeto = {
                accion: 7,
                UapCodigo: vm.crearHorario.UapCodigo,
                UaaCodigo: vm.crearHorario.Uaa.UaaCodigo,
                FechaInicio: vm.crearHorario.FechaInicio,
                FechaFin: vm.crearHorario.FechaFin,
                CurCodigo: vm.crearHorario.CurCodigo,
                EspCodigo: vm.crearHorario.EspCodigo,
                DiaCodigo: vm.crearHorario.DiaCodigo,
                CalCodigo: vm.cursoDetalle[0].CalCodigo,
                EspTipo: vm.crearHorario.EspTipo
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
                    mostrarSweetAlertSuccess(salida["mensaje"]);
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultarDia() {
            if (vm.crearHorario.FechaInicio == '' || vm.crearHorario.FechaInicio === undefined) {
                mostrarSweetAlertWarning("Debe ingresar la fecha de inicio.");
                return false;
            }
            // vm.listaDias = [];
            vm.objeto = {
                accion: 6,
                FechaInicio: vm.crearHorario.FechaInicio,
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
                    vm.crearHorario.DiaCodigo = salida.data[0].DiaCodigo;
                    vm.crearHorario.DiaNombre = salida.data[0].DiaNombre;
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
            vm.crearHorario.EspNombre = c_espacio.EspNombre;
            vm.crearHorario.EspNombreCorto = c_espacio.EspNombreCorto;
            vm.crearHorario.EspCodigo = c_espacio.EspCodigo;
            vm.crearHorario.EspTipo = c_espacio.EspTipo;

            if (c_espacio.HorasDisponibles !== undefined) {
                var dia = obtenerDiaFecha(vm.crearHorario.FechaInicio);
                vm.crearHorario.DiaCodigo = dia.codigo;
                vm.crearHorario.DiaNombre = dia.nombre;
                vm.listaHoras = c_espacio.HorasDisponibles;
                return true;
            }

            consultarDia();
        }

        function consultarEspaciosVirtuales() {
            vm.listaEspacios = [];
            vm.listaEspaciosVirtuales = [];
            vm.tipoListaEspacios = 'virtuales';

            if (vm.cursoDetalle[0].CalCodigo == '' || vm.cursoDetalle[0].CalCodigo === undefined) {
                mostrarSweetAlertWarning("No se encontro el codigo del calendario seleccionado.");
                return false;
            }
            if (vm.crearHorario.Uaa.UaaCodigo == '' || vm.crearHorario.Uaa.UaaCodigo === undefined) {
                mostrarSweetAlertWarning("No se encontro el codigo de la unidad seleccionado.");
                return false;
            }
            if (vm.crearHorario.UapCodigo == '' || vm.crearHorario.UapCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar un docente antes de buscar un espacio virtual.");
                return false;
            }
            if (vm.crearHorario.FechaInicio == '' || vm.crearHorario.FechaInicio === undefined) {
                mostrarSweetAlertWarning("Debe ingresar la fecha de inicio.");
                return false;
            }
            if (vm.crearHorario.FechaFin == '' || vm.crearHorario.FechaFin === undefined) {
                mostrarSweetAlertWarning("Debe ingresar la fecha de fin.");
                return false;
            }

            if (vm.crearHorario.SubGrupo == "" || vm.crearHorario.SubGrupo === undefined) {
                let mensaje = "Debe ingresar el subgrupo antes de poder buscar un espacio virtual.";
                mostrarSweetAlertWarning(mensaje);
                return false;
            }

            //Si es presencial (1) y subgrupo 00, no puede ser en un aula virtual
            if (vm.cursoDetalle[0].CalTipo == 'A') {
                if (vm.crearHorario.SubGrupo == '00' && vm.cursoDetalle[0].TicCodigo == 1 && (vm.cursoDetalle[0].CarCodigo.trim() == "T" || vm.cursoDetalle[0].CarCodigo.trim() == "TP")) {
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
                FechaInicio: vm.crearHorario.FechaInicio,
                FechaFin: vm.crearHorario.FechaFin,
                CalCodigo: vm.cursoDetalle[0].CalCodigo,
                UapCodigo: vm.crearHorario.UapCodigo,
                CurCodigo: vm.crearHorario.CurCodigo,
                UaaCodigo: vm.crearHorario.Uaa.UaaCodigo,
                UaaDependencia: vm.crearHorario.Uaa.UaaDependencia,
                SedNombre: vm.crearHorario.Uaa.SedNombre,
                SedCodigo: vm.crearHorario.Uaa.SedCodigo,
                SedCodigoCurso: vm.cursoDetalle[0].SedCodigo,
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
            if (vm.cursoDetalle[0].CalCodigo == '' || vm.cursoDetalle[0].CalCodigo === undefined) {
                mostrarSweetAlertWarning("No se encontro el codigo del calendario seleccionado.");
                return false;
            }
            if (vm.crearHorario.Uaa.UaaCodigo == '' || vm.crearHorario.Uaa.UaaCodigo === undefined) {
                mostrarSweetAlertWarning("No se encontro el codigo de la unidad seleccionado.");
                return false;
            }
            if (vm.crearHorario.UapCodigo == '' || vm.crearHorario.UapCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar un docente antes de buscar un espacio.");
                return false;
            }
            if (vm.crearHorario.FechaInicio == '' || vm.crearHorario.FechaInicio === undefined) {
                mostrarSweetAlertWarning("Debe ingresar la fecha de inicio.");
                return false;
            }
            if (vm.crearHorario.FechaFin == '' || vm.crearHorario.FechaFin === undefined) {
                mostrarSweetAlertWarning("Debe ingresar la fecha de fin.");
                return false;
            }

            if (vm.crearHorario.SubGrupo == "" || vm.crearHorario.SubGrupo === undefined) {
                let mensaje = "Debe ingresar el subgrupo antes de poder buscar un espacio.";
                mostrarSweetAlertWarning(mensaje);
                return false;
            }

            //Si es virtual (2) y subgrupo 00, no puede ser en un aula virtual
            if (vm.cursoDetalle[0].CalTipo == 'A') {
                if (vm.crearHorario.SubGrupo == '00' && vm.cursoDetalle[0].TicCodigo == 2) {
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

            vm.objeto = crearObjetoConsultaEspacios(17);

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
            vm.objeto = crearObjetoConsultaEspacios(16);
            vm.objeto.EspCodigo = espacio.EspCodigo;

            $http({
                url: "logica/buscurso.php",
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
                mostrarSweetAlertError("Error del servidor, favor recargar la pÃ¡gina");
                console.error(response.data);
            });
        }

        function consultarDisponibilidadTodosEspacios() {
            if (!validarDatosConsultaEspacios()) {
                return false;
            }

            vm.objeto = crearObjetoConsultaEspacios(16);
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
                    swal.closeModal();
                    vm.listaEspacios = salida.data;
                    actualizarResumenEspacios();
                    vm.filtroDisponibilidadEspacios = vm.resumenEspacios.disponibles > 0 ? 'disponibles' : 'todos';
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la pÃ¡gina");
                console.error(response.data);
            });
        }

        function seleccionarDocente(docente, tipo = "Propio") {
            if (vm.tipoOperacion == '') {
                cambiosFormularioHorario();
                vm.crearHorario.PerNombreApellido = docente.PerNombre + ' ' + docente.PerApellido;
                vm.crearHorario.PerCodigo = docente.PerCodigo;
                vm.crearHorario.UapCodigo = docente.UapCodigo;
                vm.crearHorario.VinNombre = docente.VinNombre;
                vm.crearHorario.DedCodigo = docente.DedCodigo;
                vm.crearHorario.VinCodigo = docente.VinCodigo;
                vm.crearHorario.PerNN = docente.PerNN;
                vm.crearHorario.UapSedCodigo = docente.SedCodigo;
                vm.crearHorario.UapPerCodigo = docente.PerCodigo;
                vm.crearHorario.TipoDocente = tipo;
                if (tipo == "Prestado") {
                    vm.crearHorario.SpdCodigo = docente.SpdCodigo;
                    vm.crearHorario.HorarioPermitido = docente.Horario;
                } else {
                    delete vm.crearHorario.SpdCodigo;
                    delete vm.crearHorario.HorarioPermitido;
                }
            }

            if (vm.tipoOperacion == 'edicion') {
                vm.CursoActualizar.PerNombreApellido = docente.PerNombre + ' ' + docente.PerApellido;
                vm.CursoActualizar.PerCodigo = docente.PerCodigo;
                vm.CursoActualizar.UapCodigo = docente.UapCodigo;
                vm.CursoActualizar.VinNombre = docente.VinNombre;
                vm.CursoActualizar.DedCodigo = docente.DedCodigo;
                vm.CursoActualizar.VinCodigo = docente.VinCodigo;
                vm.CursoActualizar.PerNN = docente.PerNN;
                vm.CursoActualizar.UapSedCodigo = docente.SedCodigo;
                vm.CursoActualizar.UapPerCodigo = docente.PerCodigo;
            }
            if (vm.tipoOperacion == 'creacion') {
                vm.CursoCrear.PerNombreApellido = docente.PerNombre + ' ' + docente.PerApellido;
                vm.CursoCrear.PerCodigo = docente.PerCodigo;
                vm.CursoCrear.UapCodigo = docente.UapCodigo;
                vm.CursoCrear.VinNombre = docente.VinNombre;
                vm.CursoCrear.DedCodigo = docente.DedCodigo;
                vm.CursoCrear.VinCodigo = docente.VinCodigo;
                vm.CursoCrear.PerNN = docente.PerNN;
                vm.CursoCrear.UapSedCodigo = docente.SedCodigo;
                vm.CursoCrear.UapPerCodigo = docente.PerCodigo;
            }
        }

        function consultarDocentes() {

            let UaaCodigo = '';
            let CalCodigo = '';

            if (vm.tipoOperacion == '') {
                if (vm.cursoDetalle[0].CalCodigo == '' || vm.cursoDetalle[0].CalCodigo === undefined) {
                    mostrarSweetAlertWarning("No se ha seleccionado un calendario.");
                    return false;
                }
                if (vm.crearHorario.Uaa.UaaCodigo == '' || vm.crearHorario.Uaa.UaaCodigo === undefined) {
                    mostrarSweetAlertWarning("No se ha seleccionado una unidad a programar.");
                    return false;
                }
                UaaCodigo = vm.crearHorario.Uaa.UaaCodigo;
                CalCodigo = vm.cursoDetalle[0].CalCodigo;
            }

            if (vm.tipoOperacion == 'edicion') {
                if (vm.cursoDetalle[0].CalCodigo == '' || vm.cursoDetalle[0].CalCodigo === undefined) {
                    mostrarSweetAlertWarning("No se ha seleccionado un calendario.");
                    return false;
                }
                if (vm.CursoActualizar.UaaCodigo == '' || vm.CursoActualizar.UaaCodigo === undefined) {
                    mostrarSweetAlertWarning("No se ha seleccionado una unidad a programar.");
                    return false;
                }

                UaaCodigo = vm.CursoActualizar.UaaCodigo;
                CalCodigo = vm.cursoDetalle[0].CalCodigo;
            }
            if (vm.tipoOperacion == 'creacion') {
                if (vm.CursoCrear.CalCodigo == '' || vm.CursoCrear.CalCodigo === undefined) {
                    mostrarSweetAlertWarning("No se ha seleccionado un calendario.");
                    return false;
                }
                if (vm.CursoCrear.UaaCodigo == '' || vm.CursoCrear.UaaCodigo === undefined) {
                    mostrarSweetAlertWarning("No se ha seleccionado una asignatura a programar.");
                    return false;
                }

                UaaCodigo = vm.CursoCrear.UaaCodigo;
                CalCodigo = vm.CursoCrear.CalCodigo;
            }


            vm.listaDocentes = [];
            vm.vinculacionDocenteFechas = {
                inicio: '',
                fin: ''
            };

            vm.objeto = {
                accion: 7,
                UaaCodigo: UaaCodigo,
                CalCodigo: CalCodigo
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

        function consultarDocentesPrestados() {
            if (!vm.crearHorario.Uaa || !vm.crearHorario.Uaa.UaaCodigo) {
                mostrarSweetAlertWarning("No se ha seleccionado una unidad a programar.");
                return false;
            }
            if (!vm.crearHorario.FechaInicio || !vm.crearHorario.FechaFin) {
                mostrarSweetAlertWarning("Debe seleccionar las fechas del horario antes de consultar los docentes asignados.");
                return false;
            }

            vm.listaDocentesPrestados = [];
            vm.objeto = {
                accion: 20,
                UaaCodigo: vm.crearHorario.Uaa.UaaCodigo,
                PerCodigo: vm.cursoDetalle[0].PeriodoCodigo,
                PerFechaInicio: vm.crearHorario.FechaInicio,
                PerFechaFin: vm.crearHorario.FechaFin,
                PeriodoPersonalizado: ''
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
                } else {
                    vm.listaDocentesPrestados = salida.data;
                    swal.closeModal();
                    abrirModal("modalDocentesPrestados");
                }
            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la pagina");
                console.error(response.data);
            });
        }

        function consultarAgendaDocenteHorario() {
            vm.agendaDocenteFechas = {
                inicio: '',
                fin: ''
            };
            vm.cargaDocente = {};

            if (vm.cursoDetalle[0].CalCodigo == '' || vm.cursoDetalle[0].CalCodigo === undefined) {
                mostrarSweetAlertWarning("No se ha seleccionado un calendario.");
                return false;
            }
            if (vm.crearHorario.Uaa.UaaCodigo == '' || vm.crearHorario.Uaa.UaaCodigo === undefined) {
                mostrarSweetAlertWarning("No se ha seleccionado una unidad a programar.");
                return false;
            }

            vm.agendaDocente = [];

            vm.objeto = {
                accion: 6,
                UapCodigo: vm.crearHorario.UapCodigo,
                CalCodigo: vm.cursoDetalle[0].CalCodigo,
                UaaCodigo: vm.crearHorario.Uaa.UaaCodigo,
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
                    vm.agendaDocente = salida.data;
                    vm.agendaDocenteFechas.inicio = salida.fecha_inicial;
                    vm.agendaDocenteFechas.fin = salida.fecha_final;
                    vm.objeto = {
                        accion: 15,
                        UapCodigo: vm.crearHorario.UapCodigo,
                        CalCodigo: vm.cursoDetalle[0].CalCodigo,
                        FacultadCodigo: (vm.crearHorario.Uaa && vm.crearHorario.Uaa.UaaDependencia) ? vm.crearHorario.Uaa.UaaDependencia : (vm.crearHorario.Uaa ? vm.crearHorario.Uaa.UaaCodigo : 0)
                    };

                    $http({
                        url: "logica/buscurso.php",
                        method: "POST",
                        data: vm.objeto
                    }).then(function (response) {
                        var salidaCarga = response.data;
                        if (salidaCarga["resultado"] == false) {
                            swal.closeModal();
                            mostrarSweetAlertError(salidaCarga["mensaje"]);
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

        function cambiosFormularioHorario() {
            vm.crearHorario.EspNombre = '';
            vm.crearHorario.EspNombreCorto = '';
            vm.crearHorario.EspCodigo = '';
            vm.crearHorario.EspTipo = '';

            vm.crearHorario.DiaCodigo = '';
            vm.crearHorario.DiaNombre = '';
            vm.listaHoras = [];
            vm.crearHorario.HorasSeleccionadas = '';
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
            var nombres = {
                1: 'Lunes',
                2: 'Martes',
                3: 'Miercoles',
                4: 'Jueves',
                5: 'Viernes',
                6: 'Sabado',
                7: 'Domingo'
            };
            var partes = fecha.split('-');
            var fechaLocal = new Date(partes[0], partes[1] - 1, partes[2]);
            var codigo = fechaLocal.getDay();
            codigo = codigo == 0 ? 7 : codigo;

            return {
                codigo: codigo,
                nombre: nombres[codigo]
            };
        }

        function calcularFechaFinal() {
            cambiosFormularioHorario();
            let semanas = vm.cursoDetalle[0].CurSemanas;
            let fecha = new Date(vm.crearHorario.FechaInicio);
            fecha.setDate(fecha.getDate() + (semanas * 7) - 6);
            vm.crearHorario.FechaFin = fecha.getFullYear() + '-' + (("0" + (fecha.getMonth() + 1)).slice(-2)) + '-' + ("0" + fecha.getDate()).slice(-2);
        }

        function consultarUnidades() {

            if (vm.calendarioSeleccionado == '' || vm.calendarioSeleccionado === undefined) {
                mostrarSweetAlertWarning("No se ha seleccionado un calendario.");
                return false;
            }

            vm.listaUnidades = {};

            vm.objeto = {
                accion: 4,
                CalCodigo: vm.calendarioSeleccionado
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
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function mostrarFormularioCrearHorario() {
            vm.crearHorario = [];
            vm.crearHorario = {
                PerNombreApellido: vm.cursoDetalle[0].PerNombreApellido,
                UapPerCodigo: vm.cursoDetalle[0].PerCodigo,
                VinNombre: vm.cursoDetalle[0].VinNombre,
                UapCodigo: vm.cursoDetalle[0].UapCodigo,
                CurCodigo: vm.cursoDetalle[0].CurCodigo,
                VinCodigo: vm.cursoDetalle[0].VinCodigo,
                DedCodigo: vm.cursoDetalle[0].DedCodigo,
                UapSedCodigo: vm.cursoDetalle[0].UapSedCodigo,
                PerCodigo: vm.cursoDetalle[0].PerCodigo,
                TipoDocente: 'Propio',
                Uaa: {}
            };
            vm.creacionHorario = 1;
        }

        function eliminarHorario(horario) {
            vm.eliminarHorario = [];
            vm.eliminarHorario = horario;
            mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 2,
                CurCodigo: vm.eliminarHorario.CurCodigo,
                EspCodigo: vm.eliminarHorario.EspCodigo,
                DiaCodigo: vm.eliminarHorario.DiaCodigo,
                HraCodigo: vm.eliminarHorario.HraCodigo,
                EsoFechaInicio: vm.eliminarHorario.EsoFechaInicio,
                EsoFechaFin: vm.eliminarHorario.EsoFechaFin,
                EsoSubGrupo: vm.eliminarHorario.EsoSubGrupo,
                UapCodigo: vm.eliminarHorario.UapCodigo
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

        function consultarAdministrador() {
            vm.administrador = 0;
            vm.objeto = {
                accion: 5,
            };
            // mostrarSweetAlertCargando();

            $http({
                url: "logica/buscurso.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                var salida = response.data;
                vm.administrador = salida;
                if (vm.administrador == 1) {
                    consultarPeriodos();
                }
            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultarHorarioCurso(tipo = '') {
            vm.creacionHorario = 0;
            vm.cursoHorario = {};
            if (tipo == '') {
                if (vm.cursoDetalle[0].CurCodigo == '' || vm.cursoDetalle[0].CurCodigo === undefined) {
                    mostrarSweetAlertWarning("Debe seleccionar un curso.");
                    return false;
                }

                vm.objeto = {
                    accion: 1,
                    CurCodigo: vm.cursoDetalle[0].CurCodigo
                };
                mostrarSweetAlertCargando();
            } else {
                vm.objeto = {
                    accion: 1,
                    CurCodigo: vm.cursoDetalle[0].CurCodigo
                };
            }


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
                    vm.cursoHorario = salida.data;
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

        function consultarAgendaDocente() {
            vm.cargaDocente = {};

            if (vm.tipoOperacion == 'edicion') {
                if (vm.cursoDetalle[0].CalCodigo == '' || vm.cursoDetalle[0].CalCodigo === undefined) {
                    mostrarSweetAlertWarning("No se ha seleccionado un calendario.");
                    return false;
                }
                if (vm.CursoActualizar.UaaCodigo == '' || vm.CursoActualizar.UaaCodigo === undefined) {
                    mostrarSweetAlertWarning("No se ha seleccionado una unidad a programar.");
                    return false;
                }
                if (vm.CursoActualizar.UapCodigo == '' || vm.CursoActualizar.UapCodigo === undefined) {
                    mostrarSweetAlertWarning("No se encontro el codigo de vinculacion del docente coordinador.");
                    return false;
                }
                vm.agendaDocente = [];
                vm.objeto = {
                    accion: 6,
                    UapCodigo: vm.CursoActualizar.UapCodigo,
                    CalCodigo: vm.cursoDetalle[0].CalCodigo,
                    UaaCodigo: vm.CursoActualizar.UaaCodigo,
                };
            }

            if (vm.tipoOperacion == 'creacion') {
                if (vm.CursoCrear.CalCodigo == '' || vm.CursoCrear.CalCodigo === undefined) {
                    mostrarSweetAlertWarning("No se ha seleccionado un calendario.");
                    return false;
                }
                if (vm.CursoCrear.UaaCodigo == '' || vm.CursoCrear.UaaCodigo === undefined) {
                    mostrarSweetAlertWarning("No se ha seleccionado una asignatura a programar.");
                    return false;
                }
                if (vm.CursoCrear.UapCodigo == '' || vm.CursoCrear.UapCodigo === undefined) {
                    mostrarSweetAlertWarning("No se encontro el codigo de vinculacion del docente coordinador.");
                    return false;
                }
                vm.agendaDocente = [];
                vm.objeto = {
                    accion: 6,
                    UapCodigo: vm.CursoCrear.UapCodigo,
                    CalCodigo: vm.CursoCrear.CalCodigo,
                    UaaCodigo: vm.CursoCrear.UaaCodigo,
                };
            }

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
                    var facultadCodigo = 0;
                    var uapCodigo = 0;
                    var calCodigo = 0;

                    if (vm.tipoOperacion == 'edicion') {
                        uapCodigo = vm.CursoActualizar.UapCodigo;
                        calCodigo = vm.cursoDetalle[0].CalCodigo;
                        facultadCodigo = vm.CursoActualizar.UaaCodigo;
                    }

                    if (vm.tipoOperacion == 'creacion') {
                        uapCodigo = vm.CursoCrear.UapCodigo;
                        calCodigo = vm.CursoCrear.CalCodigo;
                        facultadCodigo = vm.CursoCrear.UaaCodigo;
                    }

                    vm.objeto = {
                        accion: 15,
                        UapCodigo: uapCodigo,
                        CalCodigo: calCodigo,
                        FacultadCodigo: facultadCodigo
                    };

                    $http({
                        url: "logica/buscurso.php",
                        method: "POST",
                        data: vm.objeto
                    }).then(function (response) {
                        var salidaCarga = response.data;
                        if (salidaCarga["resultado"] == false) {
                            swal.closeModal();
                            mostrarSweetAlertError(salidaCarga["mensaje"]);
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

        function consultarPlanExclusivo() {
            if (vm.cursoDetalle[0].CurCodigo == '' || vm.cursoDetalle[0].CurCodigo === undefined) {
                mostrarSweetAlertWarning("No se encontro el codigo del curso seleccionado.");
                return false;
            }
            vm.listaPlanExclusivo = [];
            vm.objeto = {
                accion: 8,
                CurCodigo: vm.cursoDetalle[0].CurCodigo,
                // PlaCodigo: vm.cursoDetalle[0].PlaCodigo
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
                    swal.closeModal();
                    vm.listaPlanExclusivo = salida.data;
                    abrirModal("modalPlanExclusivo");
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

        function consultarDetalleCurso(curso, tipo = '') {
            // let curso_seleccionado = ''; 
            // curso_seleccionado = curso;            
            vm.cursoDetalle = {};
            vm.cursoSeleccionado = {};
            vm.crearHorario = [];
            vm.creacionHorario = 0;

            vm.cursoSeleccionado = curso;

            if (vm.cursoSeleccionado.CurCodigo == '' || vm.cursoSeleccionado.CurCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar un curso.");
                return false;
            }

            vm.objeto = {
                accion: 4,
                CurCodigo: vm.cursoSeleccionado.CurCodigo
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
                    vm.cursoDetalle = salida.data;
                    vm.formularioEdicionCursos = 0;
                    vm.formularioCreacionCursos = 0;
                    vm.informacionCursos = 1;
                    consultarHorarioCurso(tipo);
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });

        }

        function consultarPeriodos() {
            vm.listaPeriodos = {};
            vm.listaCalendarios = {};
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

        function consultarCalendarios() {
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

        function consultarCursos(curso = '') {
            vm.listadoCursos = 0;
            vm.formularioEdicionCursos = 0;
            vm.formularioCreacionCursos = 0;
            vm.informacionCursos = 0;
            vm.creacionHorario = 0;

            vm.listaCursos = {};
            vm.cursoDetalle = {};

            if (vm.periodoSeleccionado == '') {
                mostrarSweetAlertWarning("Debe seleccionar un periodo.");
                return false;
            }

            if (vm.calendarioSeleccionado == '') {
                mostrarSweetAlertWarning("Debe seleccionar un calendario.");
                return false;
            }


            if (curso == '') {
                vm.cursoSeleccionado = {};
                mostrarSweetAlertCargando();
            }

            vm.objeto = {
                accion: 3,
                CalCodigo: vm.calendarioSeleccionado
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
                    vm.listaCursos = salida.data;
                    vm.listadoCursos = 1;
                    swal.closeModal();
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function esHorarioIncompleto(curso) {
            if (!curso) {
                return false;
            }

            var totalHorario = parseInt(curso.TotalHorario, 10) || 0;
            var totalHorasProgramadas = parseInt(curso.TotalHorasProgramadas, 10) || 0;
            var caracter = ((curso.CarCodigo || '') + '').trim();
            var creditosTotales = parseFloat(curso.AsiCreditos) || 0;
            var creditosTeoria = parseFloat(curso.AsiCreditosTeoria) || 0;
            var creditosPractica = parseFloat(curso.AsiCreditosPractica) || 0;

            var creditosObjetivo = creditosTotales;
            if (caracter === 'T' && creditosTeoria > 0) {
                creditosObjetivo = creditosTeoria;
            }
            if ((caracter === 'P' || caracter === 'PP' || caracter === 'PF') && creditosPractica > 0) {
                creditosObjetivo = creditosPractica;
            }

            if (totalHorario === 0 || creditosObjetivo <= 0) {
                return false;
            }

            return totalHorasProgramadas < creditosObjetivo;
        }

        function obtenerCursosFiltrados() {
            if (!vm.listaCursos) {
                return [];
            }

            var cursos = Array.isArray(vm.listaCursos)
                ? vm.listaCursos
                : Object.keys(vm.listaCursos).map(function (key) { return vm.listaCursos[key]; });

            var filtroCurso = (vm.filter.Curso || '').toString().toLowerCase().trim();
            var filtroEstado = (vm.filter.Estado || '').toString();
            var filtroHorario = (vm.filter.Horario || '').toString();

            return cursos.filter(function (curso) {
                var textoCurso = angular.toJson(curso || {}).toLowerCase();
                var cumpleCurso = !filtroCurso || textoCurso.indexOf(filtroCurso) !== -1;
                var cumpleEstado = !filtroEstado || String(curso.CurEstado) === filtroEstado;

                var totalHorario = parseInt(curso.TotalHorario, 10) || 0;
                var incompleto = esHorarioIncompleto(curso);
                var cumpleHorario = true;

                if (filtroHorario === '1') {
                    cumpleHorario = totalHorario === 1;
                } else if (filtroHorario === '0') {
                    cumpleHorario = totalHorario === 0;
                } else if (filtroHorario === '2') {
                    cumpleHorario = incompleto;
                }

                return cumpleCurso && cumpleEstado && cumpleHorario;
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

        function mostrarErrorProgramacionHorario(salida, estadoHttp) {
            salida = salida && typeof salida === 'object' ? salida : {};
            var titulo = salida.titulo || "No fue posible programar el horario";
            var mensaje = salida.mensaje || "No se recibió información suficiente sobre el error.";

            if (estadoHttp) {
                mensaje += "<br><small>Intente nuevamente. Si el problema continúa, contacte al soporte indicando que ocurrió al programar el horario.</small>";
            }

            Swal.fire({
                title: titulo,
                html: mensaje,
                icon: 'error',
                allowOutsideClick: true,
                allowEscapeKey: true,
                confirmButtonText: 'Cerrar',
                confirmButtonColor: '#8F141B',
                buttonsStyling: true
            }).catch(swal.noop);
        }

        function mostrarSweetAlertDisabled(accion, parametros = '') {
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
            if (accion == 'crear_curso') {
                mje = "¿Desea crear el curso?";
                textBtn = "Crear";
            }
            if (accion == 'actualizar_curso') {
                mje = "¿Desea actualizar el curso " + parametros + "?";
                textBtn = "Actualizar";
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
                    if (accion == 'crear_curso') {
                        crearCurso();
                    }
                    if (accion == 'actualizar_curso') {
                        actualizarCurso();
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
