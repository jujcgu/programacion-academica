<?php
session_start();

function codificarMensajeUrl($mensaje) {
  return str_replace('.', '%2E', rawurlencode($mensaje));
}

//si no ha pasado por el login1 no debe ver el loginToken
if (!isset($_SESSION['pacademica']['login1_superado']) || $_SESSION['pacademica']['login1_superado'] != true) {
  $mje = "No ha ingresado la primera contrasena";
  echo utf8_encode("<script>location.href='loginMensaje.php?mensaje=".codificarMensajeUrl($mje)."'</script>");
  die;
}

header("Cache-Control: no-store, no-cache, must-revalidate, max-age=0");
header("Cache-Control: post-check=0, pre-check=0", false);
header("Pragma: no-cache");
?>
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
  <!-- SweetAlert2 -->
  <link rel="stylesheet" href="plugins/sweetalert2-theme-bootstrap-4/bootstrap-4.min.css">
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

        <div class="row justify-content-center align-items-center">
          <div class="col-md-12 text-center">
            <p>
              A su correo electrónico <b><?php echo $_SESSION['pacademica_token']['destinatario'] ?></b>
              fue enviado un código de verificación. Favor ingrese aquí el código de verificación.
            </p>
          </div>
        </div>

        <?php if (isset($_GET["mensaje"]) && $_GET["mensaje"] != "") : ?>
          <br>
          <div class="row justify-content-center align-items-center">
            <div class="col-md-12 text-center">
              <div class="alert alert-danger alert-dismissible text-justify">
                <button type="button" class="close" data-dismiss="alert" aria-hidden="true">×</button>
                <h5><i class="icon fas fa-ban"></i> Error</h5>
                <?php echo utf8_decode($_GET["mensaje"]); ?>
              </div>
            </div>
          </div>
        <?php endif; ?>

        <br>

        <form id="frmLoginToken" action="logica/inicio_sesion_token.php" method="POST">
          <div class="input-group mb-3">
            <input type="text" class="form-control" placeholder="Usuario" name="txtUser" <?php echo "value='{$_SESSION['pacademica']['nombreusuario_plano']}'"; ?> disabled>
            <div class="input-group-append">
              <div class="input-group-text">
                <span class="fas fa-user"></span>
              </div>
            </div>
          </div>
          <div class="input-group mb-3">
            <input type="text" class="form-control" placeholder="Token de Seguridad" name="txtToken">
            <div class="input-group-append">
              <div class="input-group-text">
                <span class="fas fa-key"></span>
              </div>
            </div>
          </div>
          <div class="row justify-content-center align-items-center">
            <div class="col-4">
              <?php if (isset($_GET["mensaje"]) && ($_GET["mensaje"] == "Ha superado el mÃ¡ximo de intentos, favor generar otro cÃ³digo de verificaciÃ³n" || $_GET["mensaje"] == "No se han encontrado cÃ³digos de verificaciÃ³n asociados al usuario." || $_GET["mensaje"] == "No se encontraron cÃ³digos de verificaciÃ³n asociados al usuario. Recuerde que despuÃ©s de recibir el cÃ³digo tiene 5 min mÃ¡ximo para usarlo.")) : ?>
                <button class="btn btn-danger btn-block" onclick="location.href='login1.php'">Regresar<div class="ripple-container"></div></button>
              <?php else : ?>
                <button type="submit" class="btn btn-danger btn-block">Validar</button>
              <?php endif; ?>
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
  <!-- jquery-validation -->
  <script src="plugins/jquery-validation/jquery.validate.min.js"></script>
  <script src="plugins/jquery-validation/additional-methods.min.js"></script>
  <!-- SweetAlert2 -->
  <script src="plugins/sweetalert2/sweetalert2.min.js"></script>
  <script>
    $(function() {
      $.validator.setDefaults({
        submitHandler: function(form) {
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
          form.submit();
        }
      });

      $('#frmLoginToken').validate({
        rules: {
          txtToken: {
            required: true,
            minlength: 5
          },
        },
        messages: {
          txtToken: {
            required: "Debe ingresar el token de seguridad.",
            minlength: "El token de seguridad debe tener minimo 5 caracteres"
          },
        },
        errorElement: 'span',
        errorPlacement: function(error, element) {
          error.addClass('invalid-feedback');
          element.closest('.input-group').append(error);
        },
        highlight: function(element, errorClass, validClass) {
          $(element).addClass('is-invalid');
        },
        unhighlight: function(element, errorClass, validClass) {
          $(element).removeClass('is-invalid');
        }
      });
    });
  </script>
</body>

</html>