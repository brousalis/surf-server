<?php
	if (isset($_GET['auth']))
	{
		$auth = $_GET['auth'];
		$validkey = '/^STEAM_[01]:[01]:\d+$/';

		if(preg_match($validkey, $auth))
		{
			$valid = true;
		}
		else 
		{
			$valid = false;
		}
	}
	
	if(!$valid) die();
	
	$steamid = $auth;
	
	$steam64 = (int) steam2friend($steamid);
	$ex = '"';
	
	$steamfix = $steamid;
	if($steamid[6] == '0')
	{
		$steamfix[6] = '1';
	}
	else
	{
		$steamfix[6] = '0';
	}
	
	$query = $link->query("SELECT `lastname` FROM `ranks` WHERE (`auth` = ".$ex.$steamid.$ex." OR `auth` = ".$ex.$steamfix.$ex.") GROUP BY `auth`");
	$array2 = mysqli_fetch_array($query);
	$name = $array2[0];
	
	if(!isset($name)) die();
	
	//GET TRACKS
	$track_names = array_keys($track_list);
	$track_ids = array_values($track_list);
	
	//GET CHATRANKS
	$rank_tags = array_keys($chattag_list);
	$rank_range = array_values($chattag_list);

	//GET STATS

	$query = $link->query("SELECT COUNT(*) FROM `round`");
	$array2 = mysqli_fetch_array($query);
	$total_records = $array2[0];

	$query = $link->query("SELECT COUNT(*) FROM `round` GROUP BY `auth`");
	$array2 = mysqli_fetch_array($query);
	$total_players = $array2[0];

	$query = $link->query("SELECT COUNT(*) FROM `mapzone` WHERE `type` = 0");
	$array2 = mysqli_fetch_array($query);
	$total_maps = $array2[0];

	$query = $link->query("SELECT COUNT(*) FROM `mapzone` WHERE `type` = 7");
	$array2 = mysqli_fetch_array($query);
	$total_bonusmaps = $array2[0];
	
	$query = $link->query("SELECT SUM(`points`) FROM `ranks` WHERE `points` > 0");
	$array2 = mysqli_fetch_array($query);
	$total_points = $array2[0];

	$query = $link->query("SELECT `points` FROM `ranks` WHERE (`auth` = ".$ex.$steamid.$ex." OR `auth` = ".$ex.$steamfix.$ex.")");
	$array2 = mysqli_fetch_array($query);
	$points = $array2[0];

	$query = $link->query("SELECT COUNT(*) FROM `ranks` WHERE `points` >= '".$points."'");
	$array2 = mysqli_fetch_array($query);
	$rank = $array2[0];

	$query = $link->query("SELECT COUNT(*) FROM `round` WHERE (`auth` = ".$ex.$steamid.$ex." OR `auth` = ".$ex.$steamfix.$ex.") AND `rank` = 1");
	$array2 = mysqli_fetch_array($query);
	$worldrecords = $array2[0];

	$query = $link->query("SELECT COUNT(*) FROM `round` WHERE (`auth` = ".$ex.$steamid.$ex." OR `auth` = ".$ex.$steamfix.$ex.") AND `rank` <= 10");
	$array2 = mysqli_fetch_array($query);
	$toprecords = $array2[0];

	$query = $link->query("SELECT COUNT(*) FROM `round` WHERE (`auth` = ".$ex.$steamid.$ex." OR `auth` = ".$ex.$steamfix.$ex.")");
	$array2 = mysqli_fetch_array($query);
	$records = $array2[0];
	
	$query = $link->query("SELECT COUNT(*) FROM (SELECT * FROM `round` WHERE (`auth` = ".$ex.$steamid.$ex." OR `auth` = ".$ex.$steamfix.$ex.") AND `track` = 0) AS s");
	$array2 = mysqli_fetch_array($query);
	$count_records = $array2[0];
	
	$query = $link->query("SELECT COUNT(*) FROM (SELECT * FROM `round` WHERE (`auth` = ".$ex.$steamid.$ex." OR `auth` = ".$ex.$steamfix.$ex.") AND `track` = 1) AS s");
	$array2 = mysqli_fetch_array($query);
	$count_bonus_records = $array2[0];
	
	$query = $link->query("SELECT COUNT(*) FROM (SELECT * FROM `round` WHERE (`auth` = ".$ex.$steamid.$ex." OR `auth` = ".$ex.$steamfix.$ex.") AND `track` = 0 GROUP BY `map`) AS s");
	$array2 = mysqli_fetch_array($query);
	$count_maps_finished = $array2[0];
	
	$query = $link->query("SELECT COUNT(*) FROM (SELECT * FROM `round` WHERE (`auth` = ".$ex.$steamid.$ex." OR `auth` = ".$ex.$steamfix.$ex.") AND `track` = 1 GROUP BY `map`) AS s");
	$array2 = mysqli_fetch_array($query);
	$count_bonusmaps_finished = $array2[0];
	
	// $query = $link->query("SELECT `rating` FROM `pvp_elo` WHERE (`auth` = ".$ex.$steamid.$ex." OR `auth` = ".$ex.$steamfix.$ex.")");
	// $array2 = mysqli_fetch_array($query);
	// $elo = $array2[0];

	$elo = 1000;
	
	// $query = $link->query("SELECT `win` FROM `pvp_elo` WHERE (`auth` = ".$ex.$steamid.$ex." OR `auth` = ".$ex.$steamfix.$ex.")");
	// $array2 = mysqli_fetch_array($query);
	// $wins = $array2[0];
	
	$wins = 0;
	
	// $query = $link->query("SELECT `loose` FROM `pvp_elo` WHERE (`auth` = ".$ex.$steamid.$ex." OR `auth` = ".$ex.$steamfix.$ex.")");
	// $array2 = mysqli_fetch_array($query);
	// $lose = $array2[0];
	
	$lose = 0;
	
	//CHATRANK
	$chatrank = $chattag_unranked;
	for ($i = 0; $i < count($rank_tags); $i++) {
		if($rank_range[$i] >= $rank){
			$chatrank = $rank_tags[$i];
			break;
		}
	}
	
	//Complete
	$complete = round(100*($count_maps_finished+$count_bonusmaps_finished)/($total_maps+$total_bonusmaps), 2);
?>
<div class="row">
	<div class="col-lg-9">
		<h1 class="page-header">Player Stats for <b><?php echo $name."</b>" ?></h1>
	</div>
	<div class="col-lg-3">
		<h1 class="page-header"><?php echo $auth ?></h1>
	</div>
</div>
<div class="row">
	<div class="col-lg-3 col-md-6">
		<div class="panel panel-red">
			<div class="panel-footer">
				</center>Account Details</center>
				<div class="clearfix"></div>
			</div>
			<div class="panel-heading">
				<div class="row">
					<div class="col-xs-12 text-center">
						<div class="huge"><?php echo $name ?></div>
					</div>
					<div class="col-xs-4 text-left">
						<div class="huge"><?php echo $worldrecords ?></div>
					</div>
					<div class="col-xs-4 text-center">
						<div class="huge"><?php echo $toprecords ?></div>
					</div>
					<div class="col-xs-4 text-right">
						<div class="huge"><?php echo $records ?></div>
					</div>
					<div class="col-xs-4 text-left">
						<div>World Records</div>
					</div>
					<div class="col-xs-4 text-center">
						<div>Top Records</div>
					</div>
					<div class="col-xs-4 text-right">
						 <div>Records</div>
					</div>
				</div>
			</div>
			<div class="panel-footer">
				<li class="list-unstyled">
					<a class="dropdown-toggle" data-toggle="dropdown" href="#">
						<span class="pull-left">View All Records</span>
						<span class="pull-right"><i class="fa fa-arrow-circle-right"></i></span>
						<div class="clearfix"></div>
					</a>
					<ul class="dropdown-menu">
						<li>
							<div class="col-md-12">
								<div class="panel panel-default">
									<div class="panel-heading">Player Records</div>
									<div class="panel-body">
										<div class="table-responsive">
											<table class="sortable table table-striped table-bordered table-hover" id="dataTables-example">
												<thead>
													<tr>
														<th>Rank</th>
														<th>Map</th>
														<th>Record-Time</th>
														<th>Style</th>
														<th>Track</th>
														<th>Date</th>
														<th>FC</th>
													</tr>
												</thead>
												<tbody>
												<?php
													$sql = "SELECT `rank`, `map`, `time`, `style`, `track`, `date`, `finishcount` FROM `round` WHERE (`auth` = ".$ex.$steamid.$ex." OR `auth` = ".$ex.$steamfix.$ex.") ORDER BY `map`, `track`, `style`;";
													$players = $link->query($sql);
													while($array = mysqli_fetch_array($players))
													{
													   echo "<tr class=\"odd gradeX\">
													   <td>".$array[0]."</td>
													   <td>".$array[1]."</td>
													   <td>".timeFormat($array[2])."</td>
													   <td>".getKeyByArrayValue($array[3], $style_list)."</td>
													   <td>".getKeyByArrayValue($array[4], $track_list)."</td>
													   <td>".$array[5]."</td>
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
						</li>
					</ul>
				</li>
			</div>
		</div>
	</div>
	<div class="col-lg-3 col-md-6">
		<div class="panel panel-yellow">
			<div class="panel-footer">
				</center>Points Ranking</center>
				<div class="clearfix"></div>
			</div>
			<div class="panel-heading">
				<div class="row">
					<div class="col-xs-12 text-center">
						<div class="huge"><?php echo $chatrank ?></div>
					</div>
					<div class="col-xs-4 text-left">
						<div class="huge"><?php echo unitFormat($points) ?></div>
					</div>
					<div class="col-xs-4 text-center">
						<div>Chatrank</div>
					</div>
					<div class="col-xs-4 text-right">
						<div class="huge">#<?php echo $rank ?></div>
					</div>
					<div class="col-xs-6 text-left">
						<div>Points</div>
					</div>
					<div class="col-xs-6 text-right">
						 <div>Rank</div>
					</div>
				</div>
			</div>
			<div class="panel-footer">
				<li class="list-unstyled">
					<a class="dropdown-toggle" data-toggle="dropdown" href="#">
						<span class="pull-left">View Next Players</span>
						<span class="pull-right"><i class="fa fa-arrow-circle-right"></i></span>
						<div class="clearfix"></div>
					</a>
					<ul class="dropdown-menu dropdown-messages">
						<li>
							not done yet
						</li>
					</ul>
				</li>
			</div>
		</div>
	</div>
	<div class="col-lg-3 col-md-6">
		<div class="panel panel-green">
			<div class="panel-footer">
				</center>Map Completion</center>
				<div class="clearfix"></div>
			</div>
			<div class="panel-heading">
				<div class="row">
					<div class="col-xs-12 text-center">
						<div class="huge"><?php echo $complete ?>%</div>
					</div>
					<div class="col-xs-4 text-left">
						<div class="huge"><?php echo $count_maps_finished+$count_bonusmaps_finished ?></div>
					</div>
					<div class="col-xs-4 text-center">
						<div>Compelte</div>
					</div>
					<div class="col-xs-4 text-right">
						<div class="huge"><?php echo $total_maps+$total_bonusmaps-$count_maps_finished-$count_bonusmaps_finished ?></div>
					</div>
					<div class="col-xs-6 text-left">
						<div>Finished</div>
					</div>
					<div class="col-xs-6 text-right">
						 <div>Incomplete</div>
					</div>
				</div>
			</div>
			<div class="panel-footer">
				<li class="list-unstyled">
					<a class="dropdown-toggle" data-toggle="dropdown" href="#">
						<span class="pull-left">View Incomplete Maps</span>
						<span class="pull-right"><i class="fa fa-arrow-circle-right"></i></span>
						<div class="clearfix"></div>
					</a>
					<ul class="dropdown-menu">
						<?php
							$amaps = array();
							$abonus_maps = array();
							
							$sql = "SELECT `map`,`type` FROM `mapzone` WHERE `type` = 0 OR `type` = 7;";
							$result = $link->query($sql);
							
							while($array = mysqli_fetch_array($result)){
							
								if($array["type"] == 0){
									array_push($amaps,$array["map"]);
								}
								else if($array["type"] == 7){
									array_push($abonus_maps,$array["map"]);
								}
							}
							
							$sql = "SELECT `map`,`track` FROM `round` WHERE (`auth` = ".$ex.$steamid.$ex." OR `auth` = ".$ex.$steamfix.$ex.") GROUP BY `map`, `track`;";
							$result = $link->query($sql);
							
							$amaps_finished = array();
							$abonus_maps_finished = array();
							
							while($array = mysqli_fetch_array($result)){
								if($array[1] == 0){
									array_push($amaps_finished,$array[0]);
								}
								else if($array[1] == 1){
									array_push($abonus_maps_finished,$array[0]);
								}
							}
						?>
						<div class="col-md-12">
							<div class="panel panel-default">
								<div class="panel-heading">Incomplete Maps</div>
								<div class="panel-body">
									<div class="table-responsive">
										<table class="table table-striped table-bordered table-hover" id="dataTables-example">
											<tbody>
											<?php
												for($i = 0; $i<count($amaps); $i++)
												{
													if(in_array($amaps[$i], $amaps_finished) == false){
														echo "<tr class=\"odd gradeX\"><td><a href='index.php?site=maptop&map=".$amaps[$i]."&style=-1&track=-1'>".$amaps[$i]."</a></td>";
													}
												}
											?>
											</tbody>
										</table>
									</div>
								</div>
							</div>
						</div>
						<?php if(count($abonus_maps_finished) > 0) {?>
						<div class="col-md-12">
							<div class="panel panel-default">
								<div class="panel-heading">Incomplete Bonus Maps</div>
								<div class="panel-body">
									<div class="table-responsive">
										<table class="table table-striped table-bordered table-hover" id="dataTables-example">
											<tbody>
											<?php
												for($i = 0; $i<count($abonus_maps); $i++)
												{
													if(in_array($abonus_maps[$i], $abonus_maps_finished) == false){
														echo "<tr class=\"odd gradeX\"><td><a href='index.php?site=maptop&map=".$abonus_maps[$i]."&style=-1&track=-1'>".$abonus_maps[$i]."</a></td>";
													}
												}
											?>
											</tbody>
										</table>
									</div>
								</div>
							</div>
						</div>
						<?php } ?>
					</ul>
				</li>
			</div>
		</div>
	</div>
	<div class="col-lg-3 col-md-6">
		<div class="panel panel-primary">
			<div class="panel-footer">
				</center>Challenge PvP Stats</center>
				<div class="clearfix"></div>
			</div>
			<div class="panel-heading">
				<div class="row">
					<div class="col-xs-12 text-center">
						<div class="huge"><?php echo $elo ?></div>
					</div>
					<div class="col-xs-4 text-left">
						<div class="huge"><?php echo $wins ?></div>
					</div>
					<div class="col-xs-4 text-center">
						<div>ELO</div>
					</div>
					<div class="col-xs-4 text-right">
						<div class="huge"><?php echo $lose ?></div>
					</div>
					<div class="col-xs-6 text-left">
						<div>Wins</div>
					</div>
					<div class="col-xs-6 text-right">
						 <div>Lose</div>
					</div>
				</div>
			</div>
			<div class="panel-footer">
				<li class="list-unstyled">
					<a class="dropdown-toggle" data-toggle="dropdown" href="#">
						<span class="pull-left">View Advanced PvP Stats</span>
						<span class="pull-right"><i class="fa fa-arrow-circle-right"></i></span>
						<div class="clearfix"></div>
					</a>
					<ul class="dropdown-menu dropdown-messages">
						<li>
							not done yet
						</li>
					</ul>
				</li>
			</div>
		</div>
	</div>
</div>
	
<div class="row">
	<div class="col-lg-6">
		<div class="panel panel-default">
			<div class="panel-heading">Latest Records</div>
			<div class="panel-body">
				<div class="table-responsive">
					<table class="table table-striped table-bordered table-hover" id="dataTables-example">
						<thead>
							<tr>
								<th>Rank</th>
								<th>Map</th>
								<th>Time</th>
								<th>Style</th>
								<th>Track</th>
							</tr>
						</thead>
						<tbody>
						<?php
						$sql = "SELECT `rank`, `map`, `time`, `style`, `track` FROM `round` WHERE (`auth` = ".$ex.$steamid.$ex." OR `auth` = ".$ex.$steamfix.$ex.") ORDER BY `map`, `track`, `style` LIMIT 10;";
						$players = $link->query($sql);
						while($array = mysqli_fetch_array($players))
						{
						   echo "<tr class=\"odd gradeX\">
						   <td>".$array[0]."</td>
						   <td>".$array[1]."</td>
						   <td>".timeFormat($array[2])."</td>
						   <td>".getKeyByArrayValue($array[3], $style_list)."</td>
						   <td>".getKeyByArrayValue($array[4], $track_list)."</td>
						   </tr>";
						}
						?>
						</tbody>
					</table>
				</div>
			</div>
		</div>
	</div>
	<div class="col-lg-6">
		<div class="panel panel-default">
			<div class="panel-heading">Top Records</div>
			<div class="panel-body">
				<div class="table-responsive">
					<table class="table table-striped table-bordered table-hover" id="dataTables-example">
						<thead>
							<tr>
								<th>Rank</th>
								<th>Map</th>
								<th>Time</th>
								<th>Style</th>
								<th>Track</th>
							</tr>
						</thead>
						<tbody>
						<?php
						$sql = "SELECT `rank`, `map`, `time`, `style`, `track` FROM `round` WHERE (`auth` = ".$ex.$steamid.$ex." OR `auth` = ".$ex.$steamfix.$ex.") ORDER BY `rank`, `time`, `map` LIMIT 10;";
						$players = $link->query($sql);
						while($array = mysqli_fetch_array($players))
						{
						   echo "<tr class=\"odd gradeX\">
						   <td>".$array[0]."</td>
						   <td>".$array[1]."</td>
						   <td>".timeFormat($array[2])."</td>
						   <td>".getKeyByArrayValue($array[3], $style_list)."</td>
						   <td>".getKeyByArrayValue($array[4], $track_list)."</td>
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