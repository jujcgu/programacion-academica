(function () {
    angular
        .module('sipa')
        .controller('CrucehorarioController', CrucehorarioController);

    function CrucehorarioController($http, $rootScope) {
        var vm = this;
        //Visualizacion
        vm.informacionCurso = 0;
        vm.cargandoHorario = 0;
        vm.cargandoSubgrupo = 0;

        //Variables
        vm.CurCodigo = '';
        vm.cursoSeleccionado = {};
        vm.listaMatriculados = [];
        vm.listaHorarioCurso = [];
        vm.listaHoras = [];
        vm.listaSubgrupo = {};
        vm.creadorCurso = "";
        vm.nuevoHorario = [];
        vm.listaEstudiantesCruce = [];

        //Filtros
        vm.filter = {
            Horario: '',
            Matriculados: ''
        };

        //Funciones Declaración
        vm.consultarCurso = consultarCurso;
        vm.consultarMatriculadosCurso = consultarMatriculadosCurso;
        vm.calcularFechaFinal = calcularFechaFinal;
        vm.consultarHoras = consultarHoras;
        vm.validarFormularioCruce = validarFormularioCruce;

        function consultarDiaSemana(fechaComoCadena) {
            
        }

        function consultarCruceHorario() {
            if (vm.cursoSeleccionado[0].CurCodigo == '' || !esEntero(vm.cursoSeleccionado[0].CurCodigo)) {
                mostrarSweetAlertWarning("Debe seleccionar un curso.");
                return false;
            }
            if (vm.nuevoHorario.CurSemanas == '' || !esEntero(vm.nuevoHorario.CurSemanas)) {
                mostrarSweetAlertWarning("Debe ingresar el número de semanas.");
                return false;
            }
            if (vm.nuevoHorario.CurSubgrupo == '' || vm.nuevoHorario.CurSubgrupo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar el subgrupo.");
                return false;
            }
            if (vm.nuevoHorario.FechaInicio == '' || vm.nuevoHorario.FechaInicio === undefined) {
                mostrarSweetAlertWarning("Debe la fecha inicial.");
                return false;
            }
            if (vm.nuevoHorario.FechaFin == '' || vm.nuevoHorario.FechaFin === undefined) {
                mostrarSweetAlertWarning("La fecha final no se calculo correctamente.");
                return false;
            }
            if (vm.nuevoHorario.HorasSeleccionadas == '' || vm.nuevoHorario.HorasSeleccionadas === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar al menos una hora.");
                return false;
            }

            vm.listaEstudiantesCruce = [];

            mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 2,
                CurCodigo: vm.cursoSeleccionado[0].CurCodigo,
                CurSemanas: vm.nuevoHorario.CurSemanas,
                CurSubgrupo: vm.nuevoHorario.CurSubgrupo,
                FechaInicio: vm.nuevoHorario.FechaInicio,
                FechaFin: vm.nuevoHorario.FechaFin,
                HorasSeleccionadas: vm.nuevoHorario.HorasSeleccionadas
            };

            $http({
                url: "logica/crucehorario.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                swal.closeModal();
                var salida = response.data;
                if (salida["resultado"] == false) {
                    vm.listaEstudiantesCruce = salida.data;
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                }
                else {
                    mostrarSweetAlertSuccess(salida["mensaje"]);
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });

        }

        function validarFormularioCruce() {
            if (vm.nuevoHorario.CurSemanas == '' || !esEntero(vm.nuevoHorario.CurSemanas)) {
                mostrarSweetAlertWarning("Debe ingresar el número de semanas.");
                return false;
            }
            if (vm.nuevoHorario.CurSubgrupo == '' || vm.nuevoHorario.CurSubgrupo === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar el subgrupo.");
                return false;
            }
            if (vm.nuevoHorario.FechaInicio == '' || vm.nuevoHorario.FechaInicio === undefined) {
                mostrarSweetAlertWarning("Debe la fecha inicial.");
                return false;
            }
            if (vm.nuevoHorario.FechaFin == '' || vm.nuevoHorario.FechaFin === undefined) {
                mostrarSweetAlertWarning("La fecha final no se calculo correctamente.");
                return false;
            }
            if (vm.nuevoHorario.HorasSeleccionadas == '' || vm.nuevoHorario.HorasSeleccionadas === undefined) {
                mostrarSweetAlertWarning("Debe seleccionar al menos una hora.");
                return false;
            }
            consultarCruceHorario();
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

        function calcularFechaFinal() {
            if (vm.nuevoHorario.CurSemanas == '' || !esEntero(vm.nuevoHorario.CurSemanas)) {
                // mostrarSweetAlertWarning("Debe ingresar el número de semanas.");
                return false;
            }
            if (vm.nuevoHorario.FechaInicio == '' || vm.nuevoHorario.FechaInicio === undefined) {
                // mostrarSweetAlertWarning("Debe la fecha inicial.");
                return false;
            }

            let semanas = vm.nuevoHorario.CurSemanas;
            let fecha = new Date(vm.nuevoHorario.FechaInicio);
            fecha.setDate(fecha.getDate() + (semanas * 7) - 6);
            vm.nuevoHorario.FechaFin = fecha.getFullYear() + '-' + (("0" + (fecha.getMonth() + 1)).slice(-2)) + '-' + ("0" + fecha.getDate()).slice(-2);

            const dias = [
                '1. Lunes',
                '2. Martes',
                '3. Miércoles',
                '4. Jueves',
                '5. Viernes',
                '6. Sábado',
                '7. Domingo',
            ];
            const numeroDia = new Date(vm.nuevoHorario.FechaInicio).getDay();
            vm.nuevoHorario.DiaNombre = dias[numeroDia];
        }

        function consultarHorarioCurso() {
            if (vm.cursoSeleccionado[0].CurCodigo.length < 4) {
                mostrarSweetAlertWarning("Debe ingresar el número del curso.");
                return false;
            }
            if (!esEntero(vm.cursoSeleccionado[0].CurCodigo)) {
                mostrarSweetAlertWarning("El curso no debe contener letras ni espacios en blanco.");
                return false;
            }
            vm.cargandoHorario = 1;
            vm.listaHorarioCurso = [];
            vm.objeto = {
                accion: 1,
                CurCodigo: vm.cursoSeleccionado[0].CurCodigo
            };
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
                    vm.cargandoHorario = 0;
                }
                else {
                    vm.listaHorarioCurso = salida.data;
                    vm.cargandoHorario = 0;
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultarSubgrupoCurso() {
            if (vm.cursoSeleccionado[0].CurCodigo.length < 4) {
                mostrarSweetAlertWarning("Debe ingresar el número del curso.");
                return false;
            }
            if (!esEntero(vm.cursoSeleccionado[0].CurCodigo)) {
                mostrarSweetAlertWarning("El curso no debe contener letras ni espacios en blanco.");
                return false;
            }
            vm.cargandoSubgrupo = 1;
            vm.objeto = {
                accion: 3,
                curCodigo: vm.cursoSeleccionado[0].CurCodigo
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
                    vm.cargandoSubgrupo = 0;
                }
                else {
                    vm.listaSubgrupo = salida.data;
                    vm.cargandoSubgrupo = 0;
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultarCreadorCurso() {
            if (vm.cursoSeleccionado[0].CurCodigo.length < 4) {
                mostrarSweetAlertWarning("Debe ingresar el número del curso.");
                return false;
            }
            if (!esEntero(vm.cursoSeleccionado[0].CurCodigo)) {
                mostrarSweetAlertWarning("El curso no debe contener letras ni espacios en blanco.");
                return false;
            }

            vm.objeto = {
                accion: 5,
                curCodigo: vm.cursoSeleccionado[0].CurCodigo
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

        function consultarCurso() {
            vm.cursoSeleccionado = {};
            vm.informacionCurso = 0;

            if (vm.CurCodigo.length < 4) {
                mostrarSweetAlertWarning("Debe ingresar el número del curso.");
                return false;
            }
            if (!esEntero(vm.CurCodigo)) {
                mostrarSweetAlertWarning("El curso no debe contener letras ni espacios en blanco.");
                return false;
            }

            mostrarSweetAlertCargando();

            vm.objeto = {
                accion: 4,
                CurCodigo: vm.CurCodigo
            };

            $http({
                url: "logica/buscurso.php",
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
                    vm.cursoSeleccionado = salida.data;
                    vm.informacionCurso = 1;
                    consultarCreadorCurso();
                    consultarSubgrupoCurso();
                    consultarHorarioCurso();
                    consultarHoras();
                }

            }, function myError(response) {
                swal.closeModal();
                mostrarSweetAlertError("Error del servidor, favor recargar la página");
                console.error(response.data);
            });
        }

        function consultarMatriculadosCurso(subgrupo = '00') {
            if (vm.cursoSeleccionado[0].CurCodigo.length < 4) {
                mostrarSweetAlertWarning("Debe ingresar el número del curso.");
                return false;
            }
            if (!esEntero(vm.cursoSeleccionado[0].CurCodigo)) {
                mostrarSweetAlertWarning("El curso no debe contener letras ni espacios en blanco.");
                return false;
            }
            mostrarSweetAlertCargando();
            vm.listaMatriculados = [];
            vm.objeto = {
                accion: 4,
                CurCodigo: vm.cursoSeleccionado[0].CurCodigo,
                SubGrupo: subgrupo
            };

            $http({
                url: "logica/cupocurso.php",
                method: "POST",
                data: vm.objeto
            }).then(function (response) {
                swal.closeModal();
                var salida = response.data;
                if (salida["resultado"] == false) {
                    swal.closeModal();
                    mostrarSweetAlertError(salida["mensaje"]);
                    console.error(salida["consola"]);
                }
                else {
                    vm.listaMatriculados = salida.data;
                    swal.closeModal();
                    abrirModal('ModalEstudiantesMatriculados');
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
