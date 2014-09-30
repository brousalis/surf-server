<?php
	include "config.inc.php";
	$link = mysqli_connect($serverip, $dbusername, $dbpassword, $dbname) or die("Couldn't make connection.");
	mysqli_set_charset($link, "utf8");
?>