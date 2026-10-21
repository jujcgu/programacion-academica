(function () {
    angular
        .module('sipa')
        .controller('CurcreaController', CurcreaController);

    function CurcreaController($http, $rootScope) {
        var vm = this;
        //Visualizacion
        vm.sinCalendario = 0;
        vm.btnBuscarCursos = 0;
        vm.seccionCursos = 0;
        vm.informacionCursos = 0;
        vm.formularioEdicionCursos = 0;
        vm.formularioCreacionCursos = 0;
        vm.tipoOperacion = ''; //creacion, edicion
        vm.filtroEstadoCalendario = 'PRINCIPAL';

        //Variables
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
        vm.listaPlanExclusivo = [];
        vm.listaDocentesPrestados = [];
        vm.seleccion = {
            Uaa: {
                //Contiene la informacion de la unidad que seleccion para programar
            },
            Calendario: {
                //Contiene la informacion del calendario selecionado para programar
            },
            Curso: [
                //Contiene la informacion del curso seleccionado
            ],
            CursoActualizar: [
                //Contiene la informacion del curso seleccionado para actualizar
            ],
            CursoCrear: [
                //Contiene la informacion del curso para crear
            ]
        };


        //Filtros
        vm.filter = {
            Unidad: '',
            Calendario: '',
            Curso: '',
            Asignatura: '',
            PlanAcademico: '',
            Docentes: ''
        }

        //Funciones Declaración
        vm.consultarSedes = consultarSedes;
        vm.consultarFacultades = consultarFacultades;
        vm.consultarCalendarios = consultarCalendarios;
        vm.consultarUnidadesUnificadas = consultarUnidadesUnificadas;
        vm.consultarCurso = consultarCurso;
        vm.consultarDetalleCurso = consultarDetalleCurso;
        vm.consultarAgendaDocente = consultarAgendaDocente;
        vm.consultarPlanExclusivo = consultarPlanExclusivo;
        vm.formularioEditarCurso = formularioEditarCurso;
        vm.cancelarEditarCurso = cancelarEditarCurso;
        vm.consultarAsignaturas = consultarAsignaturas;
        vm.actualizarAsignatura = actualizarAsignatura;
        vm.consultarPlanExclusivoCurso = consultarPlanExclusivoCurso;
        vm.ponerComoExclusivo = ponerComoExclusivo;
        vm.quitarExclusividad = quitarExclusividad;
        vm.consultarDocentes = consultarDocentes;
        vm.seleccionarDocente = seleccionarDocente;
        vm.actualizarCurso = actualizarCurso;
        vm.validarActualizacionCurso = validarActualizacionCurso;
        vm.consultaTipoCurso = consultaTipoCurso;
        vm.consultarPlanesAcademicos = consultarPlanesAcademicos;
        vm.actualizarAsignaturaPlan = actualizarAsignaturaPlan;
        vm.formularioCrearCurso = formularioCrearCurso;
        vm.cancelarCrearCurso = cancelarCrearCurso;
        vm.consultarPlanExclusivoCreacion = consultarPlanExclusivoCreacion;
        vm.seleccionarPlanAcademico = seleccionarPlanAcademico;
        vm.deseleccionarPlanAcademico = deseleccionarPlanAcademico;
        vm.crearCurso = crearCurso;
        vm.consultarDocentesPrestados = consultarDocentesPrestados;
        vm.seleccionarCalendario = seleccionarCalendario;
        vm.filtroCalendarioPorEstado = filtroCalendarioPorEstado;
        vm.contarCalendariosEstado = contarCalendariosEstado;
        vm.hayCalendariosActivos = hayCalendariosActivos;
        vm.hayCalendariosPendientes = hayCalendariosPendientes;
        vm.consultarGabelaCupoAforo = consultarGabelaCupoAforo;

        vm.gabelaCupoAforo = null; //Se obtiene del backend (Cupocurso::obtenerGabelaCupoAforo)

        //Funciones Iniciales
        initial();

        function consultarGabelaCupoAforo() {
            $http({
                url: "logica/cupocurso.php",
                method: "POST",
                data: { accion: 7 }
            }).then(function (response) {
                var salida = response.data;
                if (salida["resultado"] == true) {
                    vm.gabelaCupoAforo = parseInt(salida.data);
                }
            }, function myError(response) {
                console.error(response.data);
            });
        }

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
                if (!sinAlertaCarga) {
                    swal.closeModal();
                }
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function initial() {
            mostrarSweetAlertCargando();

            consultarSedes();
            consultarFacultades();
            consultarUnidadesUnificadas();
            consultaTipoCurso();
            consultarGabelaCupoAforo();
            //consultarCalendarios();
            swal.closeModal();
        }

        function validarCreacionCurso() {
            if (vm.seleccion.Calendario.CalCodigo == '' || vm.seleccion.Calendario.CalCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar una calendario.");
                return false;
            }
            if (vm.seleccion.CursoCrear.SedCodigo == '' || vm.seleccion.CursoCrear.SedCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar una sede.");
                return false;
            }
            if (vm.seleccion.CursoCrear.CurNotaParcial == '' || vm.seleccion.CursoCrear.CurNotaParcial === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar una nota parcial.");
                return false;
            }
            if (vm.seleccion.CursoCrear.TicCodigo == '' || vm.seleccion.CursoCrear.TicCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar una modalidad.");
                return false;
            }
            if (vm.seleccion.CursoCrear.CutCodigo == '' || vm.seleccion.CursoCrear.CutCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar un tipo de curso.");
                return false;
            }
            if (vm.seleccion.CursoCrear.TesCodigo == '' || vm.seleccion.CursoCrear.TesCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar el tipo de calificación.");
                return false;
            }
            if (vm.seleccion.CursoCrear.AsiCodigo == '' || vm.seleccion.CursoCrear.AsiCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar una asignatura.");
                return false;
            }
            if (vm.seleccion.CursoCrear.CurCupo == '' || vm.seleccion.CursoCrear.CurCupo === undefined) {
                mostrarSweetAlertWarning("Debe ingresar el cupo.");
                return false;
            }
            if (!esEntero(vm.seleccion.CursoCrear.CurCupo)) {
                mostrarSweetAlertWarning("El cupo debe ser numérico.");
                return false;
            }
            if (vm.seleccion.CursoCrear.CurAmpliacionCupo == '' || vm.seleccion.CursoCrear.CurAmpliacionCupo === undefined) {
                mostrarSweetAlertWarning("Debe ingresar el cupo reservado.");
                return false;
            }
            if (!esEntero(vm.seleccion.CursoCrear.CurAmpliacionCupo)) {
                mostrarSweetAlertWarning("El cupo reservado del curso debe ser númerico.");
                return false;
            }
            if (parseInt(vm.seleccion.CursoCrear.CurAmpliacionCupo) < 0 || vm.seleccion.CursoCrear.CurAmpliacionCupo > vm.seleccion.CursoCrear.CurCupo) {
                mostrarSweetAlertWarning("La reserva de cupo debe ser mayor a 1 y menor al cupo total: " + vm.seleccion.CursoCrear.CurCupo + ".");
                return false;
            }
            if (vm.seleccion.CursoCrear.CurSemanas == '' || vm.seleccion.CursoCrear.CurSemanas === undefined) {
                mostrarSweetAlertWarning("Debe ingresar la cantidad de semanas.");
                return false;
            }

            var CarCodigo = vm.seleccion.CursoCrear.CarCodigo.trim();
            if (vm.seleccion.Uaa.UaaCodigo == 998) {
                if (CarCodigo == "T" || CarCodigo == "TP") {
                    if (vm.seleccion.CursoCrear.CurSemanas < 1 || vm.seleccion.CursoCrear.CurSemanas > 16) {
                        mostrarSweetAlertWarning("Las semanas de los cursos de caracter teórico y teórico práctico no puede ser menor o mayor a 16.");
                        return false;
                    }
                } else {
                    if (vm.seleccion.CursoCrear.CurSemanas < 1 || vm.seleccion.CursoCrear.CurSemanas > 18) {
                        mostrarSweetAlertWarning("Las semanas de los cursos de caracter práctico no puede ser menor de 1 o mayor a 18.");
                        return false;
                    }
                }
            } else {
                if (vm.seleccion.Calendario.CalTipo == "A" || vm.seleccion.Calendario.CalTipo == "D") {
                    if (CarCodigo == "T" || CarCodigo == "TP") {
                        if (vm.seleccion.CursoCrear.CurSemanas < 1 || vm.seleccion.CursoCrear.CurSemanas > 18) {
                            mostrarSweetAlertWarning("Las semanas de los cursos de caracter teórico y teórico práctico no puede ser menor o mayor a 18.");
                            return false;
                        }
                    } else {
                        if (vm.seleccion.CursoCrear.CurSemanas < 1 || vm.seleccion.CursoCrear.CurSemanas > 18) {
                            mostrarSweetAlertWarning("Las semanas de los cursos de caracter práctico no puede ser menor de 1 o mayor a 18.");
                            return false;
                        }
                    }
                }
            }

            if (vm.seleccion.Calendario.CalTipo == "C") {
                if (vm.seleccion.CursoCrear.CurSemanas < 1 || vm.seleccion.CursoCrear.CurSemanas > 18) {
                    mostrarSweetAlertWarning("Las semanas del curso no pueden ser menor de 1 o mayor a 18.");
                    return false;
                }
            }

            if (vm.seleccion.CursoCrear.CurExclusivo == '' || vm.seleccion.CursoCrear.CurExclusivo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar la exclusividad.");
                return false;
            }
            if (vm.seleccion.CursoCrear.UapCodigo == '' || vm.seleccion.CursoCrear.UapCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar un docente coordinador.");
                return false;
            }
            if (vm.seleccion.CursoCrear.DocenteAsiCodigo != '' && vm.seleccion.CursoCrear.DocenteAsiCodigo !== undefined) {
                if (vm.seleccion.CursoCrear.DocenteAsiCodigo != vm.seleccion.CursoCrear.AsiCodigo) {
                    mostrarSweetAlertWarning("La asignatura del curso y la asignatura del docente prestado no son iguales, el docente prestado solo se puede usar para la asignatura especificada en la solicitud de prestamo docente (" + vm.seleccion.CursoCrear.DocenteAsiNombre + "-" + vm.seleccion.CursoCrear.DocenteAsiNombreCorto + ").");
                    return false;
                }
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
                UaaCodigo: vm.seleccion.Uaa.UaaCodigo,
                CalCodigo: vm.seleccion.Calendario.CalCodigo,
                SedCodigo: vm.seleccion.CursoCrear.SedCodigo,
                CurNotaParcial: vm.seleccion.CursoCrear.CurNotaParcial,
                TicCodigo: vm.seleccion.CursoCrear.TicCodigo,
                CutCodigo: vm.seleccion.CursoCrear.CutCodigo,
                TesCodigo: vm.seleccion.CursoCrear.TesCodigo,
                AsiCodigo: vm.seleccion.CursoCrear.AsiCodigo,
                PlaCodigo: vm.seleccion.CursoCrear.PlaCodigo,
                CurCupo: vm.seleccion.CursoCrear.CurCupo,
                CurAmpliacionCupo: vm.seleccion.CursoCrear.CurAmpliacionCupo,
                CurSemanas: vm.seleccion.CursoCrear.CurSemanas,
                CurExclusivo: vm.seleccion.CursoCrear.CurExclusivo,
                UapCodigo: vm.seleccion.CursoCrear.UapCodigo,
                VinNombre: vm.seleccion.CursoCrear.VinNombre,
                CurUrl: vm.seleccion.CursoCrear.CurUrl,
                CurObservaciones: vm.seleccion.CursoCrear.CurObservaciones,
                PlanesExclusivos: vm.seleccion.CursoCrear.PlanesExclusivos
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
                    vm.seleccion.Curso = salida.data;
                    vm.formularioEdicionCursos = 0;
                    vm.formularioCreacionCursos = 0;
                    vm.informacionCursos = 1;
                    consultarCurso('Creacion');
                    let curso = {
                        CurCodigo: salida["CurCodigo"]
                    };
                    consultarDetalleCurso(curso);
                    swal.closeModal();
                    mostrarSweetAlertSuccess(salida["mensaje"]);
                    // mostrarSweetAlertSuccess(salida["mensaje"]);
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function seleccionarPlanAcademico(plan_codigo) {
            if (!vm.seleccion.CursoCrear.PlanesExclusivos) {
                vm.seleccion.CursoCrear.PlanesExclusivos = [];
            }
            if (!vm.seleccion.CursoCrear.PlanesExclusivos.includes(plan_codigo)) {
                vm.seleccion.CursoCrear.PlanesExclusivos.push(plan_codigo);
            }
        }

        function deseleccionarPlanAcademico(plan_codigo) {
            vm.seleccion.CursoCrear.PlanesExclusivos = vm.seleccion.CursoCrear.PlanesExclusivos.filter(
                item => item != plan_codigo
            );
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
                    // vm.seleccion.CursoCrear.PlanesExclusivos = [];
                    swal.closeModal();
                    abrirModal("modalPlanExclusivoCrear");
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function formularioCrearCurso() {
            vm.informacionCursos = 0;
            vm.formularioEdicionCursos = 0;
            vm.formularioCreacionCursos = 1;
            vm.tipoOperacion = 'creacion'; //creacion, edicion
            vm.seleccion.Curso = [];
            vm.seleccion.CursoCrear = {
                SedCodigo: vm.seleccion.Uaa.SedCodigo,
                CurNotaParcial: 'S',
                TicCodigo: '1',
                CutCodigo: '1',
                TesCodigo: '1'
            };
            vm.seleccion.CursoCrear.CurSemanas = vm.seleccion.Calendario.CalTipo == "C" ? "1" : "16";
        }

        function cancelarCrearCurso() {
            vm.informacionCursos = 0;
            vm.formularioEdicionCursos = 0;
            vm.formularioCreacionCursos = 0;
            vm.tipoOperacion = ''; //creacion, edicion
            vm.seleccion.Curso = [];
            vm.seleccion.CursoCrear = {};
        }

        function actualizarAsignaturaPlan(plan, asignatura) {
            if (vm.tipoOperacion == 'edicion') {
                vm.seleccion.CursoActualizar.AsiNombreCorto = asignatura.AsiNombreCorto;
                vm.seleccion.CursoActualizar.AsiCodigo = asignatura.AsiCodigo;
                vm.seleccion.CursoActualizar.AsiNombre = asignatura.AsiNombre;
                vm.seleccion.CursoActualizar.CarCodigo = asignatura.CarCodigo;
                vm.seleccion.CursoActualizar.CarNombre = asignatura.CarNombre;
                vm.seleccion.CursoActualizar.AsiCreditos = asignatura.AsiCreditos;
                vm.seleccion.CursoActualizar.AsiCreditosTeoria = asignatura.AsiCreditosTeoria;
                vm.seleccion.CursoActualizar.AsiCreditosPractica = asignatura.AsiCreditosPractica;

                vm.seleccion.CursoActualizar.AsiHorasSemanalesTeorico = asignatura.AsiHorasSemanalesTeorico;
                vm.seleccion.CursoActualizar.AsiHorasSemanalesPractica = asignatura.AsiHorasSemanalesPractica;
                vm.seleccion.CursoActualizar.AsiHorasSemanalesTeoricoPractico = asignatura.AsiHorasSemanalesTeoricoPractico;

                vm.seleccion.CursoActualizar.PlaNombre = plan.PlaNombre;
                vm.seleccion.CursoActualizar.PlaCodigo = plan.PlaCodigo;
            }

            if (vm.tipoOperacion == 'creacion') {
                vm.seleccion.CursoCrear.AsiNombreCorto = asignatura.AsiNombreCorto;
                vm.seleccion.CursoCrear.AsiCodigo = asignatura.AsiCodigo;
                vm.seleccion.CursoCrear.AsiNombre = asignatura.AsiNombre;
                vm.seleccion.CursoCrear.CarCodigo = asignatura.CarCodigo;
                vm.seleccion.CursoCrear.CarNombre = asignatura.CarNombre;
                vm.seleccion.CursoCrear.AsiCreditos = asignatura.AsiCreditos;
                vm.seleccion.CursoCrear.AsiCreditosTeoria = asignatura.AsiCreditosTeoria;
                vm.seleccion.CursoCrear.AsiCreditosPractica = asignatura.AsiCreditosPractica;
                
                vm.seleccion.CursoCrear.AsiHorasSemanalesTeorico = asignatura.AsiHorasSemanalesTeorico;
                vm.seleccion.CursoCrear.AsiHorasSemanalesPractica = asignatura.AsiHorasSemanalesPractica;
                vm.seleccion.CursoCrear.AsiHorasSemanalesTeoricoPractico = asignatura.AsiHorasSemanalesTeoricoPractico;
                
                vm.seleccion.CursoCrear.PlaNombre = plan.PlaNombre;
                vm.seleccion.CursoCrear.PlaCodigo = plan.PlaCodigo;

                var CarCodigo = vm.seleccion.CursoCrear.CarCodigo.trim();
                if (CarCodigo == "T" || CarCodigo == "TP") {
                    vm.seleccion.CursoCrear.CurSemanas = "16";
                } else {
                    vm.seleccion.CursoCrear.CurSemanas = "18";
                }
            }

            consultarPropietarioAsignatura(asignatura.AsiCodigo);
        }

        function consultarPlanesAcademicos() {

            if (vm.seleccion.Uaa.UaaCodigo == '' || vm.seleccion.Uaa.UaaCodigo === undefined) {
                mostrarSweetAlertWarning("DeFbe seleccionar una unidad.");
                return false;
            }
            if (vm.seleccion.Uaa.SedCodigo == '' || vm.seleccion.Uaa.SedCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar una unidad.");
                return false;
            }
            if (vm.seleccion.Calendario.CalCodigo == '' || vm.seleccion.Calendario.CalCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar un calendario.");
                return false;
            }
            if (vm.seleccion.Calendario.CalNombre == '' || vm.seleccion.Calendario.CalNombre === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar un calendario.");
                return false;
            }
            if (vm.seleccion.Calendario.PrpCodigo == '' || vm.seleccion.Calendario.PrpCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar un calendario.");
                return false;
            }
            if (vm.seleccion.Calendario.NucCodigo == '' || vm.seleccion.Calendario.NucCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar un calendario.");
                return false;
            }
            vm.listaPlanesAcademicos = [];

            mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 17,
                UaaCodigo: vm.seleccion.Uaa.UaaCodigo,
                SedCodigo: vm.seleccion.Uaa.SedCodigo,
                UaaDependencia: vm.seleccion.Uaa.UaaDependencia,
                CalCodigo: vm.seleccion.Calendario.CalCodigo,
                CalNombre: vm.seleccion.Calendario.CalNombre,
                PrpCodigo: vm.seleccion.Calendario.PrpCodigo,
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

        function actualizarCurso() {
            if (!validarActualizacionCurso()) {
                return false;
            }

            mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 15,
                CurCodigo: vm.seleccion.CursoActualizar.CurCodigo,
                SedCodigo: vm.seleccion.CursoActualizar.SedCodigo,
                PlaCodigo: vm.seleccion.CursoActualizar.PlaCodigo,
                TicCodigo: vm.seleccion.CursoActualizar.TicCodigo,
                CurNotaParcial: vm.seleccion.CursoActualizar.CurNotaParcial,
                TesCodigo: vm.seleccion.CursoActualizar.TesCodigo,
                CurEstado: vm.seleccion.CursoActualizar.CurEstado,
                AsiCodigo: vm.seleccion.CursoActualizar.AsiCodigo,
                CurCupo: vm.seleccion.CursoActualizar.CurCupo,
                CurAmpliacionCupo: vm.seleccion.CursoActualizar.CurAmpliacionCupo,
                CurSemanas: vm.seleccion.CursoActualizar.CurSemanas,
                CurExclusivo: vm.seleccion.CursoActualizar.CurExclusivo,
                UapCodigo: vm.seleccion.CursoActualizar.UapCodigo,
                CurUrl: vm.seleccion.CursoActualizar.CurUrl,
                CurObservaciones: vm.seleccion.CursoActualizar.CurObservaciones,
                CurGrupo: vm.seleccion.CursoActualizar.CurGrupo,
                CutCodigo: vm.seleccion.CursoActualizar.CutCodigo
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
                    if (salida["CurCupoAplicado"] !== undefined) {
                        vm.seleccion.CursoActualizar.CurCupo = salida["CurCupoAplicado"];
                    }
                    if (salida["CurAmpliacionAplicado"] !== undefined) {
                        vm.seleccion.CursoActualizar.CurAmpliacionCupo = salida["CurAmpliacionAplicado"];
                    }
                    consultarDetalleCurso(vm.seleccion.Curso[0]);
                    consultarCurso('', true);
                    mostrarSweetAlertSuccess(salida["mensaje"]);
                    // mostrarSweetAlertSuccess(salida["mensaje"]);
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });

        }

        function validarActualizacionCurso() {
            if (vm.seleccion.CursoActualizar.SedCodigo == '' || vm.seleccion.CursoActualizar.SedCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar una sede.");
                return false;
            }
            if (vm.seleccion.CursoActualizar.TicCodigo == '' || vm.seleccion.CursoActualizar.TicCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar una modalidad.");
                return false;
            }
            if (vm.seleccion.CursoActualizar.CurNotaParcial == '' || vm.seleccion.CursoActualizar.CurNotaParcial === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar una nota parcial.");
                return false;
            }
            if (vm.seleccion.CursoActualizar.TesCodigo == '' || vm.seleccion.CursoActualizar.TesCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar el tipo de calificación.");
                return false;
            }
            if (vm.seleccion.CursoActualizar.CurEstado == '' || vm.seleccion.CursoActualizar.CurEstado === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar un estado.");
                return false;
            }
            if (vm.seleccion.CursoActualizar.AsiCodigo == '' || vm.seleccion.CursoActualizar.AsiCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar una asignatura.");
                return false;
            }
            if (vm.seleccion.CursoActualizar.CurCupo == '' || vm.seleccion.CursoActualizar.CurCupo === undefined) {
                mostrarSweetAlertWarning("Debe ingresar el cupo.");
                return false;
            }
            if (vm.seleccion.CursoActualizar.CurCupo < 0) {
                mostrarSweetAlertWarning("El cupo debe ser numérico.");
                return false;
            }

            if (!esEntero(vm.seleccion.CursoActualizar.CurCupo)) {
                mostrarSweetAlertWarning("El cupo debe ser numérico.");
                return false;
            }

            if (
                vm.seleccion.CursoActualizar.AforoMaximoTeoria !== null &&
                vm.seleccion.CursoActualizar.AforoMaximoTeoria !== undefined &&
                vm.seleccion.CursoActualizar.AforoMaximoTeoria !== '' &&
                parseInt(vm.seleccion.CursoActualizar.AforoMaximoTeoria) > 0
            ) {
                let aforoMaximoTeoria = parseInt(vm.seleccion.CursoActualizar.AforoMaximoTeoria);
                let limiteConGabela = aforoMaximoTeoria + vm.gabelaCupoAforo;
                let sumaCupos = parseInt(vm.seleccion.CursoActualizar.CurCupo) + parseInt(vm.seleccion.CursoActualizar.CurAmpliacionCupo || 0);
                if (sumaCupos > limiteConGabela) {
                    mostrarSweetAlertWarning("No es posible actualizar. Debe cumplirse: Cupo Total + Reserva <= Aforo + " + vm.gabelaCupoAforo + ". Suma actual: " + sumaCupos + ", aforo base: " + aforoMaximoTeoria + ", límite permitido: " + limiteConGabela + ".");
                    return false;
                }
            }

            if (vm.seleccion.CursoActualizar.CurAmpliacionCupo == '' || vm.seleccion.CursoActualizar.CurAmpliacionCupo === undefined) {
                mostrarSweetAlertWarning("Debe ingresar el cupo reservado.");
                return false;
            }
            if (vm.seleccion.CursoActualizar.CurAmpliacionCupo < 0) {
                mostrarSweetAlertWarning("La reserva de cupo debe ser mayor que 0");
                return false;
            }
            if (vm.seleccion.CursoActualizar.CurSemanas == '' || vm.seleccion.CursoActualizar.CurSemanas === undefined) {
                mostrarSweetAlertWarning("Debe ingresar la cantidad de semanas.");
                return false;
            }
            var CarCodigo = vm.seleccion.CursoActualizar.CarCodigo.trim();
            if (vm.seleccion.Uaa.UaaCodigo == 998) {
                if (vm.seleccion.Calendario.CalTipo == "A" || vm.seleccion.Calendario.CalTipo == "D") {
                    if (CarCodigo == "T" || CarCodigo == "TP") {
                        if (vm.seleccion.CursoActualizar.CurSemanas < 1 || vm.seleccion.CursoActualizar.CurSemanas > 16) {
                            mostrarSweetAlertWarning("Las semanas de los cursos de caracter teórico y teórico práctico no puede ser menor o mayor a 16.");
                            return false;
                        }
                    } else {
                        if (vm.seleccion.CursoActualizar.CurSemanas < 1 || vm.seleccion.CursoActualizar.CurSemanas > 18) {
                            mostrarSweetAlertWarning("Las semanas de los cursos de caracter práctico no puede ser menor de 1 o mayor a 18.");
                            return false;
                        }
                    }
                }
            } else {
                if (vm.seleccion.Calendario.CalTipo == "A" || vm.seleccion.Calendario.CalTipo == "D") {
                    if (CarCodigo == "T" || CarCodigo == "TP") {
                        if (vm.seleccion.CursoActualizar.CurSemanas < 1 || vm.seleccion.CursoActualizar.CurSemanas > 18) {
                            mostrarSweetAlertWarning("Las semanas de los cursos de caracter teórico y teórico práctico no puede ser menor o mayor a 18.");
                            return false;
                        }
                    } else {
                        if (vm.seleccion.CursoActualizar.CurSemanas < 1 || vm.seleccion.CursoActualizar.CurSemanas > 18) {
                            mostrarSweetAlertWarning("Las semanas de los cursos de caracter práctico no puede ser menor de 1 o mayor a 18.");
                            return false;
                        }
                    }
                }
            }

            if (vm.seleccion.Calendario.CalTipo == "C") {
                if (vm.seleccion.CursoActualizar.CurSemanas < 1 || vm.seleccion.CursoActualizar.CurSemanas > 18) {
                    mostrarSweetAlertWarning("Las semanas del curso no pueden ser menor de 1 o mayor a 18.");
                    return false;
                }
            }
            if (vm.seleccion.CursoActualizar.CurExclusivo == '' || vm.seleccion.CursoActualizar.CurExclusivo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar la exclusividad.");
                return false;
            }
            if (vm.seleccion.CursoActualizar.UapCodigo == '' || vm.seleccion.CursoActualizar.UapCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar un docente coordinador.");
                return false;
            }
            if (vm.seleccion.CursoActualizar.DocenteAsiCodigo != '' && vm.seleccion.CursoActualizar.DocenteAsiCodigo !== undefined) {
                if (vm.seleccion.CursoActualizar.DocenteAsiCodigo != vm.seleccion.CursoActualizar.AsiCodigo) {
                    mostrarSweetAlertWarning("La asignatura del curso y la asignatura del docente prestado no son iguales, el docente prestado solo se puede usar para la asignatura especificada en la solicitud de prestamo docente (" + vm.seleccion.CursoActualizar.DocenteAsiNombre + "-" + vm.seleccion.CursoActualizar.DocenteAsiNombreCorto + ").");
                    return false;
                }
            }
            return true;
        }

        function seleccionarDocente(docente) {
            if (vm.tipoOperacion == 'edicion') {
                vm.seleccion.CursoActualizar.PerNombreApellido = docente.PerNombre + ' ' + docente.PerApellido;
                vm.seleccion.CursoActualizar.VinNombre = docente.VinNombre;
                vm.seleccion.CursoActualizar.UapCodigo = docente.UapCodigo;
                vm.seleccion.CursoActualizar.HorarioPermitido = docente.Horario;
                vm.seleccion.CursoActualizar.DocenteAsiCodigo = docente.AsiCodigo;
                vm.seleccion.CursoActualizar.DocenteAsiNombre = docente.AsiNombre;
                vm.seleccion.CursoActualizar.DocenteAsiNombreCorto = docente.AsiNombreCorto;
            }
            if (vm.tipoOperacion == 'creacion') {
                vm.seleccion.CursoCrear.PerNombreApellido = docente.PerNombre + ' ' + docente.PerApellido;
                vm.seleccion.CursoCrear.VinNombre = docente.VinNombre;
                vm.seleccion.CursoCrear.UapCodigo = docente.UapCodigo;
                vm.seleccion.CursoCrear.HorarioPermitido = docente.Horario;
                vm.seleccion.CursoCrear.DocenteAsiCodigo = docente.AsiCodigo;
                vm.seleccion.CursoCrear.DocenteAsiNombre = docente.AsiNombre;
                vm.seleccion.CursoCrear.DocenteAsiNombreCorto = docente.AsiNombreCorto;
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

        function ponerComoExclusivo(PlaCodigo) {
            if (PlaCodigo == '' || PlaCodigo === undefined) {
                mostrarSweetAlertWarning("No se encontro el codigo del plan académico");
                return false;
            }

            if (vm.seleccion.Curso[0].CurCodigo == '' || vm.seleccion.Curso[0].CurCodigo === undefined) {
                mostrarSweetAlertWarning("No se encontro el codigo del curso seleccionado.");
                return false;
            }

            vm.objeto = {
                accion: 13,
                PlaCodigo: PlaCodigo,
                CurCodigo: vm.seleccion.Curso[0].CurCodigo
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
            if (vm.seleccion.Curso[0].CurCodigo == '' || vm.seleccion.Curso[0].CurCodigo === undefined) {
                mostrarSweetAlertWarning("No se encontro el codigo del curso seleccionado.");
                return false;
            }

            vm.listaPlanExclusivo = [];
            vm.objeto = {
                accion: 11,
                CurCodigo: vm.seleccion.Curso[0].CurCodigo
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
                vm.seleccion.CursoActualizar.AsiNombreCorto = asignatura.AsiNombreCorto;
                vm.seleccion.CursoActualizar.AsiCodigo = asignatura.AsiCodigo;
                vm.seleccion.CursoActualizar.AsiNombre = asignatura.AsiNombre;
                vm.seleccion.CursoActualizar.CarCodigo = asignatura.CarCodigo;
                vm.seleccion.CursoActualizar.CarNombre = asignatura.CarNombre;
                vm.seleccion.CursoActualizar.AsiCreditos = asignatura.AsiCreditos;
                vm.seleccion.CursoActualizar.AsiCreditosTeoria = asignatura.AsiCreditosTeoria;
                vm.seleccion.CursoActualizar.AsiCreditosPractica = asignatura.AsiCreditosPractica;
            }

            if (vm.tipoOperacion == 'creacion') {
                vm.seleccion.CursoCrear.AsiNombreCorto = asignatura.AsiNombreCorto;
                vm.seleccion.CursoCrear.AsiCodigo = asignatura.AsiCodigo;
                vm.seleccion.CursoCrear.AsiNombre = asignatura.AsiNombre;
                vm.seleccion.CursoCrear.CarCodigo = asignatura.CarCodigo;
                vm.seleccion.CursoCrear.CarNombre = asignatura.CarNombre;
                vm.seleccion.CursoCrear.AsiCreditos = asignatura.AsiCreditos;
                vm.seleccion.CursoCrear.AsiCreditosTeoria = asignatura.AsiCreditosTeoria;
                vm.seleccion.CursoCrear.AsiCreditosPractica = asignatura.AsiCreditosPractica;
            }

            consultarPropietarioAsignatura(asignatura.AsiCodigo);
        }

        function consultarPropietarioAsignatura(AsiCodigo) {
            if (AsiCodigo == '' || AsiCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar una asignatura.");
                return false;
            }

            if (vm.seleccion.Calendario.CalCodigo == '' || vm.seleccion.Calendario.CalCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar un calendario.");
                return false;
            }

            vm.objeto = {
                accion: 10,
                AsiCodigo: AsiCodigo,
                CalCodigo: vm.seleccion.Calendario.CalCodigo
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
                        vm.seleccion.CursoActualizar.UaaCodigo = salida.data[0].UaaCodigo;
                        vm.seleccion.CursoActualizar.UaaNombreCorto = salida.data[0].UaaNombreCorto;
                        vm.seleccion.CursoActualizar.CurGrupo = salida.data[0].CurGrupo;
                    }
                    if (vm.tipoOperacion == 'creacion') {
                        vm.seleccion.CursoCrear.UaaCodigo = salida.data[0].UaaCodigo;
                        vm.seleccion.CursoCrear.UaaNombreCorto = salida.data[0].UaaNombreCorto;
                        vm.seleccion.CursoCrear.CurGrupo = salida.data[0].CurGrupo;
                    }
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultarAsignaturas() {
            vm.listaAsignaturas = [];

            if (vm.seleccion.Uaa.UaaCodigo == '' || vm.seleccion.Uaa.UaaCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar una unidad.");
                return false;
            }
            if (vm.seleccion.Calendario.PrpCodigo == '' || vm.seleccion.Calendario.PrpCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar un calendario.");
                return false;
            }

            mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 9,
                UaaCodigo: vm.seleccion.Uaa.UaaCodigo,
                PrpCodigo: vm.seleccion.Calendario.PrpCodigo,
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

        function cancelarEditarCurso() {
            vm.informacionCursos = 1;
            vm.formularioEdicionCursos = 0;
            vm.formularioCreacionCursos = 0;
            vm.tipoOperacion = ''; //creacion, edicion
            // vm.seleccion.Curso = [];
            vm.seleccion.CursoActualizar = {};
        }

        function formularioEditarCurso(curso) {
            vm.informacionCursos = 0;
            vm.formularioEdicionCursos = 1;
            vm.formularioCreacionCursos = 0;
            vm.tipoOperacion = 'edicion'; //creacion, edicion

            vm.seleccion.CursoActualizar.CurCodigo = curso.CurCodigo;
            vm.seleccion.CursoActualizar.UapCodigo = curso.UapCodigo;
            vm.seleccion.CursoActualizar.AsiCodigo = curso.AsiCodigo;
            vm.seleccion.CursoActualizar.SedCodigo = curso.SedCodigo;
            vm.seleccion.CursoActualizar.CalCodigo = curso.CalCodigo;
            vm.seleccion.CursoActualizar.CalNombre = curso.CalNombre;
            vm.seleccion.CursoActualizar.CurGrupo = curso.CurGrupo;
            vm.seleccion.CursoActualizar.CurCupo = curso.CurCupo;
            vm.seleccion.CursoActualizar.CurEstado = curso.CurEstado;
            vm.seleccion.CursoActualizar.PlaCodigo = curso.PlaCodigo;
            vm.seleccion.CursoActualizar.PlaNombre = curso.PlaNombre;
            vm.seleccion.CursoActualizar.CutCodigo = curso.CutCodigo;
            vm.seleccion.CursoActualizar.CutNombre = curso.CutNombre;
            vm.seleccion.CursoActualizar.CurExclusivo = curso.CurExclusivo;
            vm.seleccion.CursoActualizar.SedNombre = curso.SedNombre;
            vm.seleccion.CursoActualizar.AsiNombreCorto = curso.AsiNombreCorto;
            vm.seleccion.CursoActualizar.AsiNombre = curso.AsiNombre;
            vm.seleccion.CursoActualizar.AsiCreditos = curso.AsiCreditos;
            vm.seleccion.CursoActualizar.AsiCreditosTeoria = curso.AsiCreditosTeoria;
            vm.seleccion.CursoActualizar.AsiCreditosPractica = curso.AsiCreditosPractica;
            vm.seleccion.CursoActualizar.PerNombreApellido = curso.PerNombreApellido;
            vm.seleccion.CursoActualizar.VinNombre = curso.VinNombre;
            vm.seleccion.CursoActualizar.CdpCodigo = curso.CdpCodigo;
            vm.seleccion.CursoActualizar.CurSemanas = curso.CurSemanas;
            vm.seleccion.CursoActualizar.CarCodigo = curso.CarCodigo;
            vm.seleccion.CursoActualizar.CarNombre = curso.CarNombre;
            vm.seleccion.CursoActualizar.TicCodigo = curso.TicCodigo;
            vm.seleccion.CursoActualizar.CurObservaciones = curso.CurObservaciones;
            vm.seleccion.CursoActualizar.CurAmpliacionCupo = curso.CurAmpliacionCupo;
            vm.seleccion.CursoActualizar.CurNotaParcial = curso.CurNotaParcial;
            vm.seleccion.CursoActualizar.TesCodigo = curso.TesCodigo;
            vm.seleccion.CursoActualizar.UaaNombreCorto = curso.UaaNombreCorto;
            vm.seleccion.CursoActualizar.UaaCodigo = curso.UaaCodigo;
            vm.seleccion.CursoActualizar.CurUrl = curso.CurUrl;
            vm.seleccion.CursoActualizar.UaaHorario = curso.UaaHorario;
            vm.seleccion.CursoActualizar.TotalHorario = parseInt(curso.TotalHorario || 0);
            vm.seleccion.CursoActualizar.TotalMatriculados = curso.TotalMatriculados;
            vm.seleccion.CursoActualizar.DocentePrestado = curso.DocentePrestado;
            vm.seleccion.CursoActualizar.AforoMaximoTeoria = curso.AforoMaximoTeoria;
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
            vm.seleccion.CursoActualizar = {};
            vm.seleccion.CursoCrear = {};
            vm.tipoOperacion = '';
            if (vm.seleccion.Curso.CurCodigo == '' || vm.seleccion.Curso.CurCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar un curso.");
                return false;
            }
            if (vm.seleccion.Uaa.UaaCodigo == '' || vm.seleccion.Uaa.UaaCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar una unidad.");
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
                    vm.formularioEdicionCursos = 0;
                    vm.formularioCreacionCursos = 0;
                    vm.informacionCursos = 1;
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });

        }

        function consultarCurso(tipo = '', sinAlertaCarga = false) {
            if (vm.seleccion.Uaa.UaaCodigo == '' || vm.seleccion.Uaa.UaaCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar una unidad.");
                return false;
            }
            if (vm.seleccion.Calendario.CalCodigo == '' || vm.seleccion.Calendario.CalCodigo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar una calendario de programación.");
                return false;
            }
            vm.listaCursos = [];
            vm.seccionCursos = 0;
            vm.informacionCursos = 0;
            vm.formularioEdicionCursos = 0;
            vm.formularioCreacionCursos = 0;
            vm.seleccion.Curso = {};
            vm.seleccion.CursoCrear = {};

            if (!sinAlertaCarga) {
                mostrarSweetAlertCargando();
            }

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
                    if (!sinAlertaCarga) {
                        swal.closeModal();
                    }
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                }
                else {
                    vm.listaCursos = salida.data;
                    vm.seccionCursos = 1;
                    if (!sinAlertaCarga && tipo == '') {
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
            vm.seleccion.Curso = {};

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
            vm.informacionCursos = 0;
            vm.listaCalendarios = [];
            vm.filtroEstadoCalendario = 'PRINCIPAL';
            vm.seleccion.Calendario = {};
            vm.seleccion.Curso = {};

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
            if (accion == 'crear_curso') {
                mje = "¿Desea crear el curso?";
                textBtn = "Crear";
            }
            if (accion == 'actualizar_curso') {
                mje = "¿Desea actualizar el curso " + parametros + "?";
                textBtn = "Actualizar";
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
                    if (accion == 'crear_curso') {
                        crearCurso();
                    }
                    if (accion == 'actualizar_curso') {
                        actualizarCurso();
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
