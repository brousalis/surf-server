<?php

	require_once("inc/functions.inc.php");
	if($debug){include("inc/debug.php"); Debug::register();}
?>

<!DOCTYPE html>
<html lang="en">
<head>

    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="description" content="">
    <meta name="author" content="">
	
    <title><?php echo $name ?> - Timer Stats</title>

    <?php  getPartial("headLib"); ?>

</head>

<body>

    <div id="wrapper">
	
		<!-- MAIN -->

        <?php getPartial("menu"); ?>

        <div id="page-wrapper">
            <?php 
                if(!isset($_GET["site"])){
                    $site = "dashboard";
                } else{
                    $site = $_GET["site"];
                }
                $invalide = array('\\','/','/\/',':','.');
                $site = str_replace($invalide,' ',$site);
                if(!file_exists("inc/pages/".$site.".php")) $site = "404";
                include("inc/pages/".$site.".php");
            ?>
            
            <?php getPartial("footer"); ?>
        </div>
    </div>
    <!-- /#wrapper -->


    <?php  getPartial("footerLib"); ?>

</body>

</html>
