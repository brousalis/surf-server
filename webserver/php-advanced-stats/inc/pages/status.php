<div class="row">
	<div class="col-lg-12">
		<h1 class="page-header">Server Status</h1>
	</div>
</div>

<?php	//GET SERVERS					
	$server_names = array_keys($server_list);
	$server_ips = array_values($server_list);
	
	for ($i = 0; $i < count($server_list); $i++)
	{
		$query = $link->query("SELECT COUNT(*) FROM `online` WHERE `server` = ".$server_ids[$i].";");
		$array2 = mysqli_fetch_array($query);
		$online = $array2[0];
?>

<div class="row">
	<div class="col-lg-12">
		<h1 class="page-header"><a href='steam://connect/<?php echo $server_ips[$i] ?>'><?php echo $server_names[$i]?></a></h1>
		Players Online: <?php echo $online?>
<?php
		echo "<br>";
	}
?>