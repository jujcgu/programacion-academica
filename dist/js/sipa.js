
(function () {
  'use strict'
  var app = angular
    .module('sipa', ['ngNewRouter', 'ngResource', 'angular-toArrayFilter'])
    .directive('datepicker', [function () {
      return {
        require: 'ngModel',
        restrict: 'A',
        scope: {
          format: "=?datepicker"
        },
        link: function (scope, element, attrs, ngModel) {
          if (typeof (scope.format) == "undefined") { scope.format = "yyyy-mm-dd" }
          $(element).fdatepicker({ format: scope.format, language: "es" }).on('changeDate', function (ev) {
            scope.$apply(function () {
              ngModel.$setViewValue(ev.date);
            });
          })
        }
      };
    }]);
  app.controller('AppController', AppController);
  function AppController($rootScope, $router, $http) {
    $router.config([
      { path: '/apertura-fechas', component: 'aperfe' },
      { path: '/periodos-academicos', component: 'peraca' },
      { path: '/busqueda-cursos', component: 'buscurso' },
      { path: '/conf-general', component: 'confgen' },

      { path: '/gestion-cursos', component: 'curcrea' },
      { path: '/horario-cursos', component: 'curhorario' },
      { path: '/eliminacion-cursos', component: 'elicur' },
      { path: '/cambio-docente', component: 'cambdocente' },

      { path: '/vinculacion-docente', component: 'vindocente' },
      { path: '/cruce-horario', component: 'crucehorario' },
      { path: '/cambio-unidad', component: 'cambiounidad' },
      { path: '/observaciones-docente', component: 'obsdocente' },
      { path: '/observaciones-curso', component: 'obscurso' },
      { path: '/matriculados-curso', component: 'matcurso' },
      { path: '/cupo-curso', component: 'cupocurso' },
      { path: '/cupo-personalizado', component: 'cupoper' },
      { path: '/exclusividad', component: 'exclu' },
      { path: '/sitio-realizacion', component: 'sirea' },
      { path: '/cursos-especiales', component: 'curesp' },
      { path: '/cursos-programados', component: 'curpro' },

      { path: '/cursos-sin-horario', component: 'csh' },
      { path: '/cursos-con-horario-incompleto', component: 'rcurhi' },
      { path: '/cursos-eliminados-con-horario', component: 'cech' },
      { path: '/cursos-matriculados-sin-horario', component: 'cmsh' },
      { path: '/cursos-subgrupos-cero-matriculados', component: 'ceromatriculados' },
      { path: '/cursos-modalidad', component: 'csv' },
      { path: '/cursos-nucleo', component: 'cpn' },
      { path: '/cursos-editados-administradores', component: 'ceadmin' },
      { path: '/cursos-creados-usuarios', component: 'ccuser' },
      { path: '/cursos-10-matriculados', component: 'mmatriculados' },
      { path: '/cursos-10-matriculados-gestion', component: 'gcm' },

      { path: '/solicitud-docentes', component: 'soldoc' },
      { path: '/solicitud-cambio-horario', component: 'solcambh' },
    ]);

    $http({
      url: "logica/suite.php",
      method: "POST",
      data: { accion: 1 }
    }).then(function (response) {
      $rootScope.usuario = response.data;
    });

    $http({
      url: "logica/suite.php",
      method: "POST",
      data: { accion: 2 }
    }).then(function (response) {
      $rootScope.roles = response.data;
    });
  }

  app.filter('cortarTexto', function () {
    return function (input, limit) {
      return (input.length > limit) ? input.substr(0, limit) + '...' : input;
    };
  })

  app.filter('trustedHtml', ['$sce', function ($sce) {
    return function (html) {
      return $sce.trustAsHtml(html);
    };
  }])
})();
