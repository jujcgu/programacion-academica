<?php

session_start();

function codificarMensajeUrl($mensaje) {
  return str_replace('.', '%2E', rawurlencode($mensaje));
}

//si no ha pasado por el login1 no debe ver login 2 ni login token
if (!isset($_SESSION['pacademica']['login1_superado'])) {
  header("Login2: login1_superado");
  $mje = "No ha ingresado la primera contrasena";
  echo utf8_encode("<script>location.href='loginMensaje.php?mensaje=".codificarMensajeUrl($mje)."'</script>");
  die;
}

//si no ha pasado por el login1 no debe ver login token
if (!isset($_SESSION['pacademica']['logintoken_superado'])) {
  header("Login2: logintoken_superado");
  $mje = "No ha ingresado el token de seguridad";
  echo utf8_encode("<script>location.href='loginMensaje.php?mensaje=".codificarMensajeUrl($mje)."'</script>");
  die;
}

//si no ha pasado por el login1 no debe ver login2 ni login token
if ($_SESSION['pacademica']['login1_superado'] != true) {
  header("Login2: login1_superado");
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

        <form id="frmLogin2" action="logica/inicio_sesion_2.php" method="POST">
          <div class="input-group mb-3">
            <input type="text" class="form-control" placeholder="Usuario" name="txtUsuario" id="txtUsuario" <?php echo "value='{$_SESSION['pacademica']['nombreusuario_plano']}'"; ?> disabled>
            <div class="input-group-append">
              <div class="input-group-text">
                <span class="fas fa-user"></span>
              </div>
            </div>
          </div>
          <div class="input-group mb-3">
            <input type="password" class="form-control" placeholder="Segunda Contraseña" name="txtPass" id="txtPass">
            <div class="input-group-append">
              <div class="input-group-text">
                <span class="fas fa-lock"></span>
              </div>
            </div>
          </div>
          <div class="row justify-content-center align-items-center">
            <div class="col-4">
              <button type="button" id="btnLogin2" class="btn btn-danger btn-block">Ingresar</button>
            </div>
            <!-- /.col -->
          </div>
          <br>
          <?php if (isset($_GET["mensaje"]) && $_GET["mensaje"] != '') { ?>
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
          <?php } ?>
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
  <script src="plugins/crypto-js/core.js"></script>
  <script src="plugins/crypto-js/sha1.js"></script>
  <script>
    $("#btnLogin2").click(function(event) {

      if ($("#frmLogin2").valid()) {
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

        event.preventDefault();
        var formulario = document.getElementById('frmLogin2');
        var contraInput = formulario.elements.txtPass;
        var action = "logica/inicio_sesion_2.php";
        var contrasEncriptada = CryptoJS.SHA1(contraInput.value).toString();
        var url = action;
        var data = {
          contrasEncriptada: contrasEncriptada
        };

        $.ajax({
          url: action,
          method: 'POST',
          data: data,
          dataType: 'json'
        }).done(function(response) {
          Swal.close();
          location.href = response.data
        }).fail(function(error) {
          Swal.close();
          console.error(error);
        });
      }
    });

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

      $('#frmLogin2').validate({
        rules: {
          txtPass: {
            required: true
          },
        },
        messages: {
          txtPass: {
            required: "Debe ingresar la segunda contraseña."
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