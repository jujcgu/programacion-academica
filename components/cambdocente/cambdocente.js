(function () {
    angular
        .module('sipa')
        .controller('CambdocenteController', CambdocenteController);

    function CambdocenteController($http, $rootScope) {
        var vm = this;
        //Visualizacion
        vm.sinCalendario = 0;
        //Variables
        vm.cursoSeleccionado = {};
        vm.listaSubgrupo = {};
        vm.listaHorario = {};
        vm.listaHorarioSeleccionado = [];
        vm.creadorCurso = '';
        vm.codigo_curso = '';
        vm.PermitidoEditar = false;
        vm.PermitidoProgramar = false;
        vm.AperturaProgramacionActiva = false;
        vm.AperturaCambioDocenteActiva = false;
        vm.seleccionar_todos = false;
        vm.busquedaDocente = '';
        vm.docenteSeleccionado = {};
        vm.vinculacionesDocente = {};
        vm.subgrupoSeleccionado = '';
        vm.agendaDocente = [];
        vm.fechasAgendaDocente = {
            fechaInicio: '',
            fechaFin: ''
        };

        //Nuevas variables para docentes prestados.
        vm.listaDocentes = [];
        vm.listaDocentesPrestados = [];
        vm.filter = {
            Docentes: '',
        }

        //Funciones
        vm.consultarCurso = consultarCurso;
        vm.consultarCreadorCurso = consultarCreadorCurso;
        vm.consultarSubgrupoCurso = consultarSubgrupoCurso;
        vm.consultarHorario = consultarHorario;
        vm.seleccionarHorario = seleccionarHorario;
        vm.seleccionarTodos = seleccionarTodos;
        vm.consultarDocente = consultarDocente;
        vm.seleccionarDocente = seleccionarDocente;
        vm.cambiarHorasDocente = cambiarHorasDocente;
        vm.consultarAgendaDocente = consultarAgendaDocente;
        vm.consultarDocentesPrestados = consultarDocentesPrestados;
        vm.seleccionarTodasSemanas = seleccionarTodasSemanas;
        vm.cargaDocente = {};
        // vm.eliminarHorasDocente = eliminarHorasDocente;

        function consultarPermisoCambioDocente(cargando) {
            vm.objeto = {
                accion: 8,
                CurCodigo: vm.codigo_curso
            };

            $http({
                url: "logica/cambdocente.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                var salida = response.data;
                if (salida["resultado"] == false) {
                    vm.PermitidoProgramar = false;
                    vm.AperturaProgramacionActiva = false;
                    vm.AperturaCambioDocenteActiva = false;
                    if (cargando == '') {
                        swal.closeModal();
                    }
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                }
                else {
                    vm.PermitidoProgramar = salida.PermitidoProgramar;
                    vm.AperturaProgramacionActiva = salida.AperturaProgramacionActiva;
                    vm.AperturaCambioDocenteActiva = salida.AperturaCambioDocenteActiva;
                    if (cargando == '') {
                        consultarCreadorCurso();
                        consultarSubgrupoCurso();
                    }
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function actualizarAgenda(CurCodigo) {
            if (CurCodigo == '' || CurCodigo === undefined) {
                console.error("No se encontro el codigo del curso seleccionado.");
                mostrarSweetAlertWarning("No se encontro el codigo del curso seleccionado.");
                return false;
            }

            vm.objeto = {
                accion: 9,
                CurCodigo: CurCodigo
            };

            $http({
                url: "logica/curhorario.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                // swal.closeModal();
                var salida = response.data;

                if (salida["resultado"] == false) {
                    console.error(salida["consola"]);
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });

        }

        function eliminarHorasDocente() {
            if (vm.listaHorarioSeleccionado == '' || vm.listaHorarioSeleccionado == undefined || vm.listaHorarioSeleccionado.length == 0) {
                mostrarSweetAlertWarning("Debe seleccionar una fecha de la lista de horario del curso.");
                return false;
            }
            if (vm.cursoSeleccionado[0].CurCodigo == '' || vm.cursoSeleccionado[0].CurCodigo == undefined) {
                mostrarSweetAlertWarning("No se ha encontrado un curso seleccionado.");
                return false;
            }

            const listaHorarioSeleccionado = vm.listaHorarioSeleccionado.map(item => item.EsoCodigo);
            const CurCodigo = vm.cursoSeleccionado[0].CurCodigo;

            mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 6,
                listaHorarioSeleccionado: listaHorarioSeleccionado,
                UapCodigo: vm.docenteSeleccionado.UapCodigo,
                CurCodigo: vm.cursoSeleccionado[0].CurCodigo,
            };

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
                if (salida["resultado"] == true) {
                    swal.closeModal();
                    mostrarSweetAlertSuccess(salida["mensaje"]);
                    actualizarAgenda(CurCodigo);
                    consultarCurso('Cargando');
                    consultarSubgrupoCurso('Cargando');
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultarDocentesPrestados() {
            vm.listaDocentesPrestados = [];
            vm.objeto = {
                accion: 5,
                CalCodigo: vm.cursoSeleccionado[0].CalCodigo,
                CurCodigo: vm.cursoSeleccionado[0].CurCodigo,
            };

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
            if (vm.cursoSeleccionado[0].CalCodigo == '' || vm.cursoSeleccionado[0].CalCodigo === undefined) {
                mostrarSweetAlertWarning("No se encontro el codigo del calendario seleccionado.");
                return false;
            }
            if (vm.docenteSeleccionado.UapCodigo == '' || vm.docenteSeleccionado.UapCodigo === undefined) {
                mostrarSweetAlertWarning("No se encontro el codigo de la vinculación del docente seleccionado.");
                return false;
            }
            if (vm.listaHorario[0][0].UaaCodigo == '' || vm.listaHorario[0][0].UaaCodigo === undefined) {
                mostrarSweetAlertWarning("No se encontro el codigo de la unidad programada del horario seleccionado.");
                return false;
            }

            mostrarSweetAlertCargando();

            vm.agendaDocente = [];
            vm.cargaDocente = {};
            vm.fechasAgendaDocente = {
                fechaInicio: '',
                fechaFin: ''
            }

            vm.objeto = {
                accion: 6,
                UapCodigo: vm.docenteSeleccionado.UapCodigo,
                CalCodigo: vm.cursoSeleccionado[0].CalCodigo,
                UaaCodigo: vm.listaHorario[0][0].UaaCodigo
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
                    vm.fechasAgendaDocente.fechaInicio = salida.fecha_inicial;
                    vm.fechasAgendaDocente.fechaFin = salida.fecha_final;
                    vm.objeto = {
                        accion: 7,
                        UapCodigo: vm.docenteSeleccionado.UapCodigo,
                        CalCodigo: vm.cursoSeleccionado[0].CalCodigo,
                        FacultadCodigo: vm.cursoSeleccionado[0].UaaCodigo
                    };

                    $http({
                        url: "logica/cambdocente.php",
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

        function validarHorasDocente() {
            if (vm.docenteSeleccionado.PerIdentificacion == '' || vm.docenteSeleccionado.PerIdentificacion == undefined) {
                mostrarSweetAlertWarning("Debe seleccionar un docente valido.");
                return false;
            }
            if (vm.docenteSeleccionado.CambioCoordinador == '' || vm.docenteSeleccionado.CambioCoordinador == undefined) {
                mostrarSweetAlertWarning("Debe seleccionar si desea cambiar el coordinador del curso.");
                return false;
            }
            if (vm.listaHorarioSeleccionado == '' || vm.listaHorarioSeleccionado == undefined || vm.listaHorarioSeleccionado.length == 0) {
                mostrarSweetAlertWarning("Debe seleccionar una fecha de la lista de horario del curso.");
                return false;
            }
            return true;
        }

        function cambiarHorasDocente() {

            if (!validarHorasDocente()) {
                return false;
            }

            mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 4,
                CambioCoordinador: vm.docenteSeleccionado.CambioCoordinador,
                listaHorarioSeleccionado: vm.listaHorarioSeleccionado,
                UapCodigo: vm.docenteSeleccionado.UapCodigo,
                PerCodigo: vm.docenteSeleccionado.PerCodigo,
                CurCodigo: vm.cursoSeleccionado[0].CurCodigo,
                CurGrupo: vm.cursoSeleccionado[0].CurGrupo,
                CalCodigo: vm.cursoSeleccionado[0].CalCodigo,
                VinNombre: vm.docenteSeleccionado.VinNombre,
                TipoDocente: vm.docenteSeleccionado.TipoDocente,
                HorarioDocentePrestado: vm.docenteSeleccionado.Horario,
                SubGrupo: vm.subgrupoSeleccionado
            };

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
                if (salida["resultado"] == true) {
                    swal.closeModal();
                    mostrarSweetAlertSuccess(salida["mensaje"]);
                    consultarCurso('Cargando');
                    consultarSubgrupoCurso('Cargando');
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });

        }

        function seleccionarDocente(docente, tipo) {
            vm.docenteSeleccionado = {};
            vm.docenteSeleccionado = docente;
            vm.docenteSeleccionado.TipoDocente = tipo;
            cerrarModal("modalVinculacionesDocente");
        }

        function consultarDocente() {
            // if (vm.busquedaDocente == '') {
            //     mostrarSweetAlertWarning("Debe ingresar un criterio de busqueda como identificación, nombre o apellido.");
            //     return false;
            // }

            vm.docenteSeleccionado = {};
            vm.vinculacionesDocente = {};

            mostrarSweetAlertCargando();
            vm.objeto = {
                accion: 3,
                // PersonaBusqueda: vm.busquedaDocente,
                UaaCodigo: vm.cursoSeleccionado[0].UaaCodigo,
                CalCodigo: vm.cursoSeleccionado[0].CalCodigo,
                CurCodigo: vm.cursoSeleccionado[0].CurCodigo,
            };

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
                    swal.closeModal();
                    vm.vinculacionesDocente = salida.data;
                    abrirModal("modalVinculacionesDocente");
                    // mostrarSweetAlertSuccess(salida["mensaje"]);
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function limpiarSelect(tipo = "") {
            if (tipo == "semana") {
                document.querySelectorAll(".grupo")
                    .forEach(function (otherCheck) {
                        otherCheck.checked = false;
                    });
            }
            if (tipo == "grupo") {
                document.querySelectorAll(".individual")
                    .forEach(function (otherCheck) {
                        otherCheck.checked = false;
                    });
                document.querySelectorAll(".semana")
                    .forEach(function (otherCheck) {
                        otherCheck.checked = false;
                    });
            }
        }

        function seleccionarTodasSemanas(event) {
            limpiarSelect("semana");
            limpiarSelect("grupo");
            var isChecked = event.target.checked;
            if (isChecked == true) {
                $.each($("input[name='chkHorario[]'].individual, .semana"), function () {
                    $(this).prop("checked", true);
                });
            } else {
                $.each($("input[name='chkHorario[]'].individual, .semana"), function () {
                    $(this).prop("checked", false);
                });
            }
            recorrerUnidadesSeleccionables();
        }

        function seleccionarTodos(semana = "", event) {
            var sem = "semana" + semana;
            var isChecked = event.target.checked;
            limpiarSelect("semana");
            if (isChecked == true) {
                $.each($("input[name='chkHorario[]'].individual." + sem), function () {
                    $(this).prop("checked", true);
                });
            } else {
                $.each($("input[name='chkHorario[]'].individual." + sem), function () {
                    $(this).prop("checked", false);
                });
            }
            recorrerUnidadesSeleccionables();
        }

        function recorrerUnidadesSeleccionables() {
            vm.listaHorarioSeleccionado = [];
            $(".trCheck").removeClass("table-success");
            $.each($("input[name='chkHorario[]']:checked"), function () {
                let EsoCodigo = $(this).val();
                let TipoEspacio = $(this).attr("TipoEspacio");
                let EsoFecha = $(this).attr("EsoFecha");
                let HoraCodigo = $(this).attr("HoraCodigo");
                let DiaCodigo = $(this).attr("DiaCodigo");
                let UaaCodigo = $(this).attr("UaaCodigo");
                $(".fila" + EsoCodigo).addClass("table-success");
                let horario = [];
                horario = {
                    "EsoCodigo": EsoCodigo,
                    "EsoFecha": EsoFecha,
                    "TipoEspacio": TipoEspacio,
                    "HoraCodigo": HoraCodigo,
                    "DiaCodigo": DiaCodigo,
                    "UaaCodigo": UaaCodigo,
                    "DiaHoraCodigo": DiaCodigo + HoraCodigo
                };

                let existe = vm.listaHorarioSeleccionado.find(function (item) {
                    return item.EsoCodigo === horario.EsoCodigo &&
                        item.DiaCodigo === horario.DiaCodigo &&
                        item.HoraCodigo === horario.HoraCodigo;
                });

                if (!existe) {
                    vm.listaHorarioSeleccionado.push(horario);
                }
            });
        }

        function seleccionarHorario(EsoCodigo, event, tipo) {
            var check = event.target;
            var diacodigo = check.getAttribute('diacodigo');
            var horacodigo = check.getAttribute('horacodigo');

            // limpiarSelect();

            if (tipo == "grupo") {
                // Evita la propagación del evento hacia el tr cuando haces clic en el checkbox
                event.stopPropagation();
            }

            if (tipo == "individual" || tipo == "fila") {
                if (tipo == "fila") {
                    check = $(event.currentTarget).find('.individual')[0];
                }
                if (check.checked) {
                    $(".horario" + EsoCodigo + '.individual').prop("checked", false);
                } else {
                    $(".horario" + EsoCodigo + '.individual').prop("checked", true);
                }
            }

            if (tipo == "grupo" && tipo != "fila") {
                limpiarSelect("grupo");
                if (check.checked) {
                    document.querySelectorAll(".grupo")
                        .forEach(function (otherCheck) {
                            if (otherCheck.getAttribute('diacodigo') === diacodigo && otherCheck.getAttribute('horacodigo') === horacodigo) {
                                otherCheck.checked = true;
                            }
                        });
                } else {
                    document.querySelectorAll(".grupo")
                        .forEach(function (otherCheck) {
                            if (otherCheck.getAttribute('diacodigo') === diacodigo && otherCheck.getAttribute('horacodigo') === horacodigo) {
                                otherCheck.checked = false;
                            }
                        });
                    $(".horario" + EsoCodigo + '.individual').prop("checked", false);
                }
            }

            recorrerUnidadesSeleccionables();
        }

        function consultarHorario(uap, subgrupo, cargando = '') {
            vm.listaHorario = {};
            vm.subgrupoSeleccionado = '';
            vm.seleccionar_todos = 0;

            let UapCodigo = uap;
            let EsoSubGrupo = subgrupo;
            vm.subgrupoSeleccionado = subgrupo;

            if (!esEntero(UapCodigo)) {
                mostrarSweetAlertWarning("El docente seleccionado no es valido.");
                return false;
            }

            if (EsoSubGrupo == '') {
                mostrarSweetAlertWarning("El subgrupo seleccionado no es valido.");
                return false;
            }

            if (cargando == '') {
                mostrarSweetAlertCargando();
            }

            vm.objeto = {
                accion: 2,
                CurCodigo: vm.codigo_curso,
                UapCodigo: UapCodigo,
                EsoSubGrupo: EsoSubGrupo,
            };

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
                    vm.listaHorario = salida.data;
                    if (cargando == '') {
                        swal.closeModal();
                    }
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultarCreadorCurso() {
            vm.creadorCurso = '';
            if (vm.codigo_curso.length < 4) {
                mostrarSweetAlertWarning("Debe ingresar el número del curso.");
                return false;
            }
            if (!esEntero(vm.codigo_curso)) {
                mostrarSweetAlertWarning("El curso no debe contener letras ni espacios en blanco.");
                return false;
            }

            vm.objeto = {
                accion: 5,
                curCodigo: vm.codigo_curso
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

        function consultarSubgrupoCurso(cargando = '') {
            vm.listaSubgrupo = {};
            if (vm.codigo_curso.length < 4) {
                mostrarSweetAlertWarning("Debe ingresar el número del curso.");
                return false;
            }
            if (!esEntero(vm.codigo_curso)) {
                mostrarSweetAlertWarning("El curso no debe contener letras ni espacios en blanco.");
                return false;
            }

            if (cargando == '') {
                mostrarSweetAlertCargando();
            }

            vm.objeto = {
                accion: 1,
                CurCodigo: vm.codigo_curso
            };

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
                    vm.listaSubgrupo = salida.data;
                    if (cargando == '') {
                        swal.closeModal();
                    }
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultarCurso(cargando = '') {
            if (vm.codigo_curso.length < 4) {
                mostrarSweetAlertWarning("Debe ingresar el número del curso.");
                return false;
            }
            if (!esEntero(vm.codigo_curso)) {
                mostrarSweetAlertWarning("El curso no debe contener letras ni espacios en blanco.");
                return false;
            }

            vm.cursoSeleccionado = {};
            vm.listaHorario = {};
            vm.listaHorarioSeleccionado = [];
            vm.docenteSeleccionado = {};
            vm.vinculacionesDocente = {};

            if (cargando == '') {
                mostrarSweetAlertCargando();
            }

            vm.objeto = {
                accion: 1,
                curCodigo: vm.codigo_curso
            };

            $http({
                url: "logica/cupocurso.php",
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
                    vm.PermitidoEditar = salida.PermitidoEditar;
                    vm.PermitidoProgramar = false;
                    vm.AperturaProgramacionActiva = false;
                    vm.AperturaCambioDocenteActiva = false;
                    consultarPermisoCambioDocente(cargando);
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
                        eliminarHorasDocente();
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
