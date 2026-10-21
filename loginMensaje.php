<!DOCTYPE html>
<html lang="en">

<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Programación Académica</title>
  <link rel="shortcut icon" type="image/x-icon" href="dist/img/favicon.ico">

  <!-- Google Font: Source Sans Pro -->
  <link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Source+Sans+Pro:300,400,400i,700&display=fallback">
  <!-- Font Awesome -->
  <link rel="stylesheet" href="plugins/fontawesome-free/css/all.min.css">
  <!-- icheck bootstrap -->
  <link rel="stylesheet" href="plugins/icheck-bootstrap/icheck-bootstrap.min.css">
  <!-- Theme style -->
  <link rel="stylesheet" href="dist/css/adminlte.css">
</head>

<body class="hold-transition login-page skin-red">
  <div class="login-box">
    <!-- /.login-logo -->
    <div class="card card-outline card-danger">
      <div class="card-header text-center">
        <img src="dist/img/universidad-surcolombiana.png" width="100%" alt="">
      </div>
      <div class="card-body">
        <h4>
          <p class="login-box-msg text-danger"><b>Módulo de Programación Académica</b></p>
        </h4>

        <form id="frmMensaje" action="login1.php" method="POST">
          <div class="row">
            <div class="col-md-12">
              <div class="alert alert-danger alert-dismissible text-justify">
                <button type="button" class="close" data-dismiss="alert" aria-hidden="true">×</button>
                <h5><i class="icon fas fa-ban"></i> Error</h5>
                <?php echo utf8_decode($_GET["mensaje"]); ?>
              </div>
            </div>
          </div>
          <br>
          <div class="row justify-content-center align-items-center">
            <div class="col-4">
              <button type="submit" class="btn btn-danger btn-block">Regresar</button>
            </div>
            <!-- /.col -->
          </div>
          <br>
          <div class="row">
            <div class="col-md-12 text-center text-justify">
              <small><b>¿Necesita ayuda?</b>
                Aquí encontrará algunos videotutoriales sobre el manejo del sistema. Para visualizarlos se debe iniciar
                sesión con el correo institucional.
                <br>
                <b>
                  <a class="text-danger" href="https://drive.google.com/drive/u/1/folders/1Eb5_83HbP9-a7p5_qHK7E8LCvgL8P3wp?usp=sharing" target="_blank">ver videotutoriales</a>
                </b>
              </small>
            </div>
          </div>
        </form>
      </div>
      <!-- /.card-body -->
    </div>
    <!-- /.card -->
  </div>
  <!-- /.login-box -->

  <!-- jQuery -->
  <script src="plugins/jquery/jquery.min.js"></script>
  <!-- Bootstrap 4 -->
  <script src="plugins/bootstrap/js/bootstrap.bundle.min.js"></script>
  <!-- AdminLTE App -->
  <script src="dist/js/adminlte.min.js"></script>
</body>

</html>