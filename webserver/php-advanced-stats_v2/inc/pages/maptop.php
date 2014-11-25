<div class="row">
	<div class="col-lg-12">
		<h1 class="page-header">Map Top</h1>
	</div>
</div>





<?php
	$astylename = array_keys($style_list);
	$astyleid = array_values($style_list);

	$atrackname = array_keys($track_list);
	$atrackid = array_values($track_list);

	$is_map = false;

	//PARAMETERS
	if(isset($_POST['Map'])){
		$map = $_POST['Map'];
		$is_map = true;
	}
	else if(isset($_GET['map'])){
		$map = $_GET['map'];
		$is_map = true;
	}

	if (isset($map)) {
		
			$map = $link->real_escape_string($map);
	}

	if(isset($_POST['Style'])){
		$style = intval($_POST['Style']);
	}
	else if(isset($_GET['style'])){
		$style = intval($_GET['style']);
	}
	else $style = -1;

	if(isset($_POST['Track'])){
		$track = intval($_POST['Track']);
	}
	else if(isset($_GET['track'])){
		$track = intval($_GET['track']);
	}
	else $track = -1;
?>

<form action="<?php echo $_SERVER["PHP_SELF"]; ?>?site=maptop" method="post">
	<div class="row">
		<div class="col-lg-6">
			<b>Map</b>
			<select class="form-control" name="Map">
				<?php
					$result = $link->query("SELECT `map` FROM `mapzone` WHERE `type` = 0 ORDER BY `map` ASC");
					while ($row = mysqli_fetch_object($result))
					{
						if(!$is_map){
							echo "<option value=\"".$row->map."\" selected=\"selected\">".$row->map."</option>";
							$map = $row->map;
							$is_map = true;
						}
						else if($row->map == $map){
							echo "<option value=\"".$row->map."\" selected=\"selected\">".$row->map."</option>";
						}
						else{
							echo "<option value=\"".$row->map."\" >".$row->map."</option>";
						}
					}
				?>
			</select>
			<br>
		</div>
		<div class="col-lg-6">
			<b>Style</b>
			<select class="form-control" name="Style">
				<?php
					if ($style == -1)
						echo "<option value=-1 selected=\"selected\">".$style_any."</option>";
					else
						echo "<option value=-1>".$style_any."</option>";
						
					for ($i = 0; $i < count($style_list); $i++) {
						if($astyleid[$i] == $style){
							echo "<option value=".$astyleid[$i]." selected=\"selected\">".$astylename[$i]."</option>";
						}
						else{
							echo "<option value=".$astyleid[$i].">".$astylename[$i]."</option>";
						}
					}
				?>
			</select>
			<br>
		</div>
	</div>
	<div class="row">
		<div class="col-lg-6">
			<b>Track</b>
			<select class="form-control" name="Track">
				<?php
					if ($track == -1)
						echo "<option value=-1 selected=\"selected\">".$track_any."</option>";
					else
						echo "<option value=-1>".$track_any."</option>";
						
					for ($i = 0; $i < count($track_list); $i++) {
						if($atrackid[$i] == $track){
							echo "<option value=".$atrackid[$i]." selected=\"selected\">".$atrackname[$i]."</option>";
						}
						else{
							echo "<option value=".$atrackid[$i].">".$atrackname[$i]."</option>";
						}
					}
				?>
			</select>
			<br>
		</div>
		<div class="col-lg-6">
			<br>
			<button type="submit" class="btn btn-success" name="viewmap" value="View Records">View Records</button>
		</div>
	</div>
</form>
<?php
	$query = $link->query("SELECT `tier` FROM `maptier` WHERE `track` = 0 AND `map` = '".$map."'");
	$array2 = mysqli_fetch_array($query);
	$maptier = $array2[0];
	
	$query = $link->query("SELECT `tier` FROM `maptier` WHERE `track` = 1 AND `map` = '".$map."'");
	$array2 = mysqli_fetch_array($query);
	$maptier2 = $array2[0];
	
	$query = $link->query("SELECT COUNT(*) FROM `round` WHERE `map` LIKE '".$map."' AND `track` = 0");
	$array2 = mysqli_fetch_array($query);
	$current_records = $array2[0];
	
	$query = $link->query("SELECT COUNT(*) FROM `round` WHERE `map` LIKE '".$map."' AND `track` = 1");
	$array2 = mysqli_fetch_array($query);
	$current_records_track = $array2[0];
	
	$query = $link->query("SELECT COUNT(*) FROM `round` WHERE `map` LIKE '".$map."' AND `track` = 2");
	$array2 = mysqli_fetch_array($query);
	$current_records_short = $array2[0];
?>
<div class="row">
	<div class="col-lg-12">
		<div class="panel panel-default">
			<div class="panel-heading">Top Records for <b><?php echo $map; ?></b></div>
			<div class="panel-body">
				<div class="table-responsive">
					<table class="sortable table table-striped table-bordered table-hover" id="dataTables-example">
						<thead>
							<tr>
								<th>Rank</th>
								<th>Name</th>
								<th>Time</th>
								<th>Style</th>
								<th>Track</th>
								<th>Date</th>
							</tr>
						</thead>
						<tbody>
						<?php
							if($style == -1){
								if($track == -1){
									$query = $link->query("SELECT COUNT(*) FROM `round` WHERE `map` LIKE '".$map."'");
								}
								else{
									$query = $link->query("SELECT COUNT(*) FROM `round` WHERE `map` LIKE '".$map."' AND `track` = '".$track."'");
								}
							}
							else{
								if($track == -1){
									$query = $link->query("SELECT COUNT(*) FROM `round` WHERE `map` LIKE '".$map."' AND `style` = '".$style."'");
								}
								else{
									$query = $link->query("SELECT COUNT(*) FROM `round` WHERE `map` LIKE '".$map."' AND `track` = '".$track."' AND `style` = '".$style."'");
								}
							}
							$array2 = mysqli_fetch_array($query);
							$totalplayers = $array2[0];

							if($style == -1){
								if($track == -1){
									$sql = "SELECT `rank`, `name`, `auth`, `time`, `style`, `track`, `date` FROM `round` WHERE `map` LIKE '".$map."' ORDER BY `time` ASC LIMIT 25";
								}
								else{
									$sql = "SELECT `rank`, `name`, `auth`, `time`, `style`, `track`, `date` FROM `round` WHERE `map` LIKE '".$map."' AND `track` = '".$track."' ORDER BY `time` ASC LIMIT 25";
								}
							}
							else{
								if($track == -1){
									$sql = "SELECT `rank`, `name`, `auth`, `time`, ``style`, `track`, `date` FROM `round` WHERE `map` LIKE '".$map."' AND `style` = '".$style."' ORDER BY `time` ASC LIMIT 25";
								}
								else{
									$sql = "SELECT `rank`, `name`, `auth`, `time`, `style`, `track`, `date` FROM `round` WHERE `map` LIKE '".$map."' AND `track` = '".$track."' AND `style` = '".$style."' ORDER BY `time` ASC LIMIT 25";
								}
							}

							$players = $link->query($sql);
							while($array = mysqli_fetch_array($players))
							{
							   echo "<tr class=\"odd gradeX\">
								<td>".$array[0]."</td>
								<td><a href='index.php?site=player&auth=".$array[2]."'>".$array[1]."</a></td>
								<td>".timeFormat($array[3])."</td>
								<td>".getKeyByArrayValue($array[4], $style_list)."</td>
								<td>".getKeyByArrayValue($array[5], $track_list)."</td>
								<td>".$array[6]."</td>
								</tr>";
							}
						?>
						</tbody>
					</table>
				</div>
			</div>
		</div>
	</div>
</div>