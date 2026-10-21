<?php
    session_start();
    header('Content-Type: text/html; charset=UTF-8');
    $cosa= print_r( $_SESSION, true );
    echo "<div style='text-align : justify; white-space: pre-wrap;'>".$cosa."</div>";
