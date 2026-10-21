<?php
session_start();
setcookie(session_name(), session_id(), time() + 86400); //tiempo de sesion (86400=1dia)
header("Cache-Control: no-cache, must-revalidate"); // HTTP/1.1
header("Expires: Sat, 1 Jul 2000 05:00:00 GMT"); // Fecha en el pasado
if ($_SESSION['pacademica']['datosVinculacionUsuario'] != null) {
?>
  <!DOCTYPE html>
  <html lang="en" ng-app="sipa">

  <head>
    <meta charset="utf-8">
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <meta name="google" content="notranslate" translate=NO />
    <meta http-equiv="Expires" content="0">
    <meta http-equiv="Last-Modified" content="0">
    <meta http-equiv="Cache-Control" content="no-cache, mustrevalidate">
    <meta http-equiv="Pragma" content="no-cache">

    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Programación Académica</title>
    <link rel="shortcut icon" type="image/x-icon" href="dist/img/favicon.ico">
    <!-- Google Font: Source Sans Pro -->
    <!-- <link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Source+Sans+Pro:300,400,400i,700&display=fallback"> -->
    <!-- Font Awesome -->
    <link rel="stylesheet" href="plugins/fontawesome-free/css/all.min.css">
    <!-- Ionicons -->
    <!-- <link rel="stylesheet" href="https://code.ionicframework.com/ionicons/2.0.1/css/ionicons.min.css"> -->
    <!-- Tempusdominus Bootstrap 4 -->
    <link rel="stylesheet" href="plugins/tempusdominus-bootstrap-4/css/tempusdominus-bootstrap-4.min.css">
    <!-- iCheck -->
    <link rel="stylesheet" href="plugins/icheck-bootstrap/icheck-bootstrap.min.css">
    <!-- Theme style -->
    <link rel="stylesheet" href="dist/css/adminlte.css">
    <!-- overlayScrollbars -->
    <link rel="stylesheet" href="plugins/overlayScrollbars/css/OverlayScrollbars.min.css">
    <!-- Daterange picker -->
    <link rel="stylesheet" href="plugins/daterangepicker/daterangepicker.css">
    <link rel="stylesheet" href="plugins/datepicker/stylesheets/foundation-datepicker.css">
    <!-- summernote -->
    <link rel="stylesheet" href="plugins/summernote/summernote-bs4.min.css">
    <!-- SweetAlert2 -->
    <link rel="stylesheet" href="plugins/sweetalert2-theme-bootstrap-4/bootstrap-4.min.css">

    <!-- Data tables css -->
    <link rel="stylesheet" href="plugins/datatables-bs4/css/dataTables.bootstrap4.min.css">
    <link rel="stylesheet" href="plugins/datatables-responsive/css/responsive.bootstrap4.min.css">
    <link rel="stylesheet" href="plugins/datatables-buttons/css/buttons.bootstrap4.min.css">
    
    <link rel="stylesheet" href="dist/css/usco.css">

  </head>

  <body class="hold-transition sidebar-mini layout-fixed  skin-red" data-ng-controller="AppController as app">
    <div class="wrapper">

      <!-- Navbar -->
      <nav class="main-header navbar navbar-expand navbar-danger navbar-dark navbar-fixed">
        <!-- Left navbar links -->
        <ul class="navbar-nav">
          <li class="nav-item">
            <a class="nav-link" data-widget="pushmenu" href="" role="button"><i class="fas fa-bars"></i></a>
          </li>
        </ul>

        <!-- Right navbar links -->
        <ul class="navbar-nav ml-auto">
          <li class="nav-item">
            <a class="nav-link" data-widget="fullscreen" href="" role="button">
              <i class="fas fa-expand-arrows-alt"></i>
            </a>
          </li>
        </ul>
      </nav>

      <!-- Preloader -->
      <div class="preloader flex-column justify-content-center align-items-center">
        <img class="animation__shake" src="dist/img/precarga-usco.gif">
      </div>

      <!-- Main Sidebar Container -->
      <aside class="main-sidebar sidebar-dark-secondary elevation-4">
        <!-- Sidebar -->
        <div class="sidebar">
          <!-- Sidebar user panel (optional) -->
          <div class="user-panel mt-3 pb-3 mb-3 d-flex">
            <div class="image">
              <img src="foto.php?req={{usuario.persona}}" style="width: 60px; height: 60px;" class="img-circle elevation-2" alt="User Image">
            </div>
            <br>
            <div class="info text-white text-center">
              {{usuario.nombre}} <br>
              {{usuario.apellido}}
            </div>
          </div>

          <!-- SidebarSearch Form -->
          <div class="form-inline">
            <div class="input-group" data-widget="sidebar-search">
              <input class="form-control form-control-sidebar" type="search" placeholder="Buscar" aria-label="Search">
              <div class="input-group-append">
                <button class="btn btn-sidebar">
                  <i class="fas fa-search fa-fw"></i>
                </button>
              </div>
            </div>
          </div>

          <!-- Sidebar Menu -->
          <nav class="mt-2">
            <ul class="nav nav-pills nav-sidebar flex-column" data-widget="treeview" role="menu" data-accordion="true">
              <!-- Menu para administradores -->
              <li class="nav-item" title="Administrador Programación Académica" data-ng-if="usuario.codPerfil == roles.ADMINISTRADOR">
                <a href="" class="nav-link">
                  <i class="nav-icon fas fa-user-cog"></i>
                  <p>
                    Admin. Programación
                    <i class="right fas fa-angle-left"></i>
                  </p>
                </a>
                <ul class="nav nav-treeview">
                  <li class="nav-item"><a href="#/apertura-fechas" class="nav-link">
                      <p>Apertura Fechas</p>
                    </a></li>
                  <li class="nav-item"><a href="#/periodos-academicos" class="nav-link">
                      <p>Periodos Academicos</p>
                    </a></li>
                  <li class="nav-item"><a href="#/busqueda-cursos" class="nav-link">
                      <p>Búsqueda Curso</p>
                    </a></li>
                  <li class="nav-item"><a href="#/conf-general" class="nav-link">
                      <p>Configuración General</p>
                    </a></li>
                </ul>
              </li>

              <!-- Formatos para convertir -->
              <li class="nav-item" title="Formatos digitales" data-ng-if="usuario.codPerfil == roles.ADMINISTRADOR || usuario.codPerfil == roles.SECRETARIA || usuario.codPerfil == roles.JEFE_PROGRAMA">
                <a href="" class="nav-link">
                  <i class="nav-icon fas fa-folder"></i>
                  <p>
                    Solicitudes
                    <i class="right fas fa-angle-left"></i>
                  </p>
                </a>
                <ul class="nav nav-treeview">
                  <li class="nav-item"><a href="#/solicitud-docentes" class="nav-link">
                      <p>Servicio Docente</p>
                    </a></li>
                  <li class="nav-item"><a href="#/solicitud-cambio-horario" class="nav-link">
                      <p>Cambio Horario</p>
                    </a></li>
                </ul>
              </li>

              <!-- Programacion academica -->
              <li class="nav-item" title="Programación Académica" data-ng-if="usuario.codPerfil == roles.ADMINISTRADOR || usuario.codPerfil == roles.SECRETARIA || usuario.codPerfil == roles.JEFE_PROGRAMA">
                <a href="" class="nav-link">
                  <i class="nav-icon fas fa-calendar-check"></i>
                  <p>
                    Progra. Académica
                    <i class="right fas fa-angle-left"></i>
                  </p>
                </a>
                <ul class="nav nav-treeview">
                  <li class="nav-item"><a href="#/gestion-cursos" class="nav-link">
                      <p>Gestión Curso</p>
                    </a></li>
                  <li class="nav-item"><a href="#/horario-cursos" class="nav-link">
                      <p>Horario Curso</p>
                    </a></li>
                  <li class="nav-item"><a href="#/eliminacion-cursos" class="nav-link">
                      <p>Eliminar Curso</p>
                    </a></li>
                  <li class="nav-item"><a href="#/cambio-docente" class="nav-link">
                      <p>Cambio Docente</p>
                    </a></li>
                </ul>
              </li>

              <!-- Administrador de Secretaria -->
              <li class="nav-item" title="Administrador de Secretaria" data-ng-if="usuario.codPerfil == roles.ADMINISTRADOR || usuario.codPerfil == roles.SECRETARIA|| usuario.codPerfil == roles.JEFE_PROGRAMA">
                <a href="" class="nav-link">
                  <i class="nav-icon fas fa-users-cog"></i>
                  <p>
                    Admin. Secretaria
                    <i class="right fas fa-angle-left"></i>
                  </p>
                </a>
                <ul class="nav nav-treeview">
                  <li class="nav-item"><a href="#/vinculacion-docente" class="nav-link">
                      <p>Vinculación docente</p>
                    </a></li>
                  <li class="nav-item"><a href="#/cruce-horario" class="nav-link">
                      <p>Cruce horario</p>
                    </a></li>
                  <li class="nav-item"><a href="#/cambio-unidad" class="nav-link">
                      <p>Cambio de Unidad</p>
                    </a></li>
                  <li class="nav-item"><a href="#/observaciones-docente" class="nav-link">
                      <p>Observaciones Docente</p>
                    </a></li>
                  <li class="nav-item"><a href="#/observaciones-curso" class="nav-link">
                      <p>Observaciones y Coordinador Curso</p>
                    </a></li>
                  <li class="nav-item"><a href="#/matriculados-curso" class="nav-link">
                      <p>Matriculados Curso</p>
                    </a></li>
                  <li class="nav-item"><a href="#/cupo-curso" class="nav-link">
                      <p>Cupo Curso</p>
                    </a></li>
                  <li class="nav-item"><a href="#/cupo-personalizado" class="nav-link">
                      <p>Cupo Personalizado</p>
                    </a></li>
                  <li class="nav-item"><a href="#/exclusividad" class="nav-link">
                      <p>Exclusividad</p>
                    </a></li>
                  <li class="nav-item"><a href="#/sitio-realizacion" class="nav-link">
                      <p>Sitio Realización</p>
                    </a></li>
                  <li class="nav-item"><a href="#/cursos-especiales" class="nav-link">
                      <p>Cursos Especiales</p>
                    </a></li>
                  <li class="nav-item"><a href="#/cursos-programados" class="nav-link">
                      <p>Cursos Programados</p>
                    </a></li>
                </ul>
              </li>


              <!-- Reportes -->
              <li class="nav-item" title="Programación Académica" data-ng-if="usuario.codPerfil == roles.ADMINISTRADOR || usuario.codPerfil == roles.SECRETARIA || usuario.codPerfil == roles.JEFE_PROGRAMA">
                <a href="" class="nav-link">
                  <i class="nav-icon fas fa-file-alt"></i>
                  <p>
                    Reportes
                    <i class="right fas fa-angle-left"></i>
                  </p>
                </a>
                <ul class="nav nav-treeview">
                  <li class="nav-item"><a href="#/cursos-sin-horario" class="nav-link">
                      <p>Cursos sin horario</p>
                    </a></li>
                  <li class="nav-item" data-ng-if="usuario.codPerfil == roles.ADMINISTRADOR"><a href="#/cursos-con-horario-incompleto" class="nav-link">
                      <p>Cursos horario incompleto</p>
                    </a></li>
                  <li class="nav-item"><a href="#/cursos-matriculados-sin-horario" class="nav-link">
                      <p>Cursos sin matriculados con horario</p>
                    </a></li>
                  <li class="nav-item"><a href="#/cursos-subgrupos-cero-matriculados" class="nav-link">
                      <p>Cursos y subgrupos con cero matriculados</p>
                    </a></li>
                  <li class="nav-item"><a href="#/cursos-eliminados-con-horario" class="nav-link">
                      <p>Cursos eliminados con horario</p>
                    </a></li>

                  <li class="nav-item"><a href="#/cursos-modalidad" class="nav-link">
                      <p>Cursos por modalidad</p>
                    </a></li>
                  <li class="nav-item"><a href="#/cursos-nucleo" class="nav-link">
                      <p>Cursos por nucleo</p>
                    </a></li>
                  <li class="nav-item"><a href="#/cursos-editados-administradores" class="nav-link">
                      <p>Cursos editados administradores</p>
                    </a></li>
                  <li class="nav-item"><a href="#/cursos-creados-usuarios" class="nav-link">
                      <p>Cursos creados por usuarios</p>
                    </a></li>
                  <li class="nav-item"><a href="#/cursos-10-matriculados-gestion" class="nav-link">
                      <p>Cursos menos 10 matriculados</p>
                    </a></li>
                </ul>
              </li>

              <!-- Estado Cursos -->
              <li class="nav-item" title="Cursos" data-ng-if="usuario.codPerfil == roles.ADMINISTRADOR || usuario.codPerfil == roles.SUB_ADMINISTRADOR ">
                <a href="" class="nav-link">
                  <i class="nav-icon fas fa-folder"></i>
                  <p>
                    Cursos
                    <i class="right fas fa-angle-left"></i>
                  </p>
                </a>
                <ul class="nav nav-treeview">
                  <li class="nav-item"><a href="#/cursos-10-matriculados-gestion" class="nav-link">
                      <p>Cursos menos 10 matriculados</p>
                    </a></li>
                </ul>
              </li>


              <br>
              <hr>
              <li class="nav-item">
                <a href="login1.php" class="nav-link" title="Cerrar sesion">
                  <p>
                    Cerrar Sesión
                  </p>
                </a>
              </li>

            </ul>
          </nav>
          <!-- /.sidebar-menu -->
        </div>
        <!-- /.sidebar -->
      </aside>

      <!-- Content Wrapper. Contains page content -->
      <!-- Inicio Contenido -->
      <div class="content-wrapper">
        <ng-viewport></ng-viewport>
      </div>
      <!-- Fin Contenido -->
      <!-- /.content-wrapper -->
    </div>
    <!-- ./wrapper -->

    <!-- jQuery -->
    <script src="plugins/jquery/jquery.min.js"></script>
    <!-- jQuery UI 1.11.4 -->
    <script src="plugins/jquery-ui/jquery-ui.min.js"></script>
    <!-- Resolve conflict in jQuery UI tooltip with Bootstrap tooltip -->
    <script>
      $.widget.bridge('uibutton', $.ui.button)
    </script>
    <!-- Bootstrap 4 -->
    <script src="plugins/bootstrap/js/bootstrap.bundle.min.js"></script>
    <!-- daterangepicker -->
    <script src="plugins/moment/moment.min.js"></script>
    <script src="plugins/daterangepicker/daterangepicker.js"></script>
    <!-- Tempusdominus Bootstrap 4 -->
    <script src="plugins/tempusdominus-bootstrap-4/js/tempusdominus-bootstrap-4.min.js"></script>
    <!-- Summernote -->
    <script src="plugins/summernote/summernote-bs4.min.js"></script>
    <!-- overlayScrollbars -->
    <script src="plugins/overlayScrollbars/js/jquery.overlayScrollbars.min.js"></script>
    <!-- AdminLTE App -->
    <script src="dist/js/adminlte.js"></script>
    <!-- SweetAlert2 -->
    <script src="plugins/sweetalert2/sweetalert2.min.js"></script>

    <!-- jquery-validation -->
    <script src="plugins/jquery-validation/jquery.validate.min.js"></script>
    <script src="plugins/jquery-validation/additional-methods.min.js"></script>

    <script src="dist/js/angular.min.js"></script>
    <script src="dist/js/router.es5.min.js"></script>
    <script src="dist/js/angular-resource.min.js"></script>
    <script src="dist/js/sipa.js?v=<?php echo (rand()); ?>"></script>
    <script src="dist/js/toArray.js?v=<?php echo (rand()); ?>"></script>


    <script src="components/aperfe/aperfe.js?v=<?php echo (rand()); ?>" charset="utf-8"></script>
    <script src="components/peraca/peraca.js?v=<?php echo (rand()); ?>" charset="utf-8"></script>
    <script src="components/buscurso/buscurso.js?v=<?php echo (rand()); ?>" charset="utf-8"></script>
    <script src="components/confgen/confgen.js?v=<?php echo (rand()); ?>" charset="utf-8"></script>

    <script src="components/curcrea/curcrea.js?v=<?php echo (rand()); ?>" charset="utf-8"></script>
    <script src="components/curhorario/curhorario.js?v=<?php echo (rand()); ?>" charset="utf-8"></script>
    <script src="components/elicur/elicur.js?v=<?php echo (rand()); ?>" charset="utf-8"></script>
    <script src="components/cambdocente/cambdocente.js?v=<?php echo (rand()); ?>" charset="utf-8"></script>

    <script src="components/vindocente/vindocente.js?v=<?php echo (rand()); ?>" charset="utf-8"></script>
    <script src="components/crucehorario/crucehorario.js?v=<?php echo (rand()); ?>" charset="utf-8"></script>
    <script src="components/cambiounidad/cambiounidad.js?v=<?php echo (rand()); ?>" charset="utf-8"></script>
    <script src="components/obsdocente/obsdocente.js?v=<?php echo (rand()); ?>" charset="utf-8"></script>
    <script src="components/obscurso/obscurso.js?v=<?php echo (rand()); ?>" charset="utf-8"></script>
    <script src="components/matcurso/matcurso.js?v=<?php echo (rand()); ?>" charset="utf-8"></script>
    <script src="components/cupocurso/cupocurso.js?v=<?php echo (rand()); ?>" charset="utf-8"></script>
    <script src="components/cupoper/cupoper.js?v=<?php echo (rand()); ?>" charset="utf-8"></script>
    <script src="components/exclu/exclu.js?v=<?php echo (rand()); ?>" charset="utf-8"></script>
    <script src="components/sirea/sirea.js?v=<?php echo (rand()); ?>" charset="utf-8"></script>
    <script src="components/curesp/curesp.js?v=<?php echo (rand()); ?>" charset="utf-8"></script>
    <script src="components/curpro/curpro.js?v=<?php echo (rand()); ?>" charset="utf-8"></script>

    <script src="components/csh/csh.js?v=<?php echo (rand()); ?>" charset="utf-8"></script>
    <script src="components/rcurhi/rcurhi.js?v=<?php echo (rand()); ?>" charset="utf-8"></script>
    <script src="components/cech/cech.js?v=<?php echo (rand()); ?>" charset="utf-8"></script>
    <script src="components/cmsh/cmsh.js?v=<?php echo (rand()); ?>" charset="utf-8"></script>
    <script src="plugins/jszip/jszip.min.js"></script>
    <script src="components/ceromatriculados/ceromatriculados.js?v=<?php echo (rand()); ?>" charset="utf-8"></script>
    <script src="components/csv/csv.js?v=<?php echo (rand()); ?>" charset="utf-8"></script>
    <script src="components/cpn/cpn.js?v=<?php echo (rand()); ?>" charset="utf-8"></script>
    <script src="components/ceadmin/ceadmin.js?v=<?php echo (rand()); ?>" charset="utf-8"></script>
    <script src="components/ccuser/ccuser.js?v=<?php echo (rand()); ?>" charset="utf-8"></script>
    <script src="components/mmatriculados/mmatriculados.js?v=<?php echo (rand()); ?>" charset="utf-8"></script>
    <script src="components/gcm/gcm.js?v=<?php echo (rand()); ?>" charset="utf-8"></script>

    <script src="components/soldoc/soldoc.js?v=<?php echo (rand()); ?>" charset="utf-8"></script>
    <script src="components/solcambh/solcambh.js?v=<?php echo (rand()); ?>" charset="utf-8"></script>

    <script src="plugins/datepicker/js/foundation-datepicker.js"></script>
    <script>
      $(document).ready(function() {});
    </script>

  </body>

  </html>
<?php
} else {
  header("Location: login1.php");
}
?>
