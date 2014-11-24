<div class="row">
	<div class="col-lg-3">
		<h1 class="page-header">Dashboard</h1>
	</div>
	<div class="col-lg-9">
		<?php if($wrticker){ ?>
			<br>
			<b>World Record Ticker</b><br><br>
			<div class="marquee" id="mycrawler">
			<?php
				$sql = "SELECT `rank`, `map`, `auth`, `name`, `time`, `date`, `style`, `track` FROM `round` WHERE `rank` = 1 ORDER BY `date` DESC LIMIT 5";
				$rekorde = $link->query($sql);
				$count = 1;
				while($array = mysqli_fetch_array($rekorde))
				{
					echo "▲▲▲ <a href='index.php?site=maptop&map=".$array[1]."&style=".$array[6]."&track=".$array[7]."'>".$array[3]." «» ".$array[1]."</a> ";
				}
			?>
			</div>
			<script type="text/javascript">
			marqueeInit({
				uniqueid: 'mycrawler',
				style: {
					'background': '#ffffff',
					'border': '0px solid #CC3300'
				},
				inc: 5,
				mouse: 'cursor driven',
				moveatleast: 1,
				neutral: 150,
				persist: false,
				savedirection: true
			});
			</script>
		<?php } ?>
	</div>
</div>
			
<div class="row">
	<div class="col-lg-3 col-md-6">
		<div class="panel panel-red">
		
			<?php
				$query = $link->query("SELECT COUNT(*) FROM `round`");
				$array2 = mysqli_fetch_array($query);
				$total_records = $array2[0];
				$total_records = unitFormat($total_records, $decimals = 2);

				$query = $link->query("SELECT COUNT(*) FROM `ranks`");
				$array2 = mysqli_fetch_array($query);
				$total_players = $array2[0];
				$total_players = unitFormat($total_players, $decimals = 2);
			?>
			<div class="panel-heading">
				<div class="row">
					<div class="col-xs-12 text-center">
						<div class="huge">Players</div>
					</div>
					<div class="col-xs-6 text-left">
						<div class="huge"><?php echo $total_players ?></div>
					</div>
					<div class="col-xs-6 text-right">
						<div class="huge"><?php echo $total_records ?></div>
					</div>
					<div class="col-xs-6 text-left">
						<div>Total</div>
					</div>
					<div class="col-xs-6 text-right">
						 <div>Records</div>
					</div>
				</div>
			</div>
			<a href="index.php?site=topworldrecord">
				<div class="panel-footer">
					<span class="pull-left">View details</span>
					<span class="pull-right"><i class="fa fa-arrow-circle-right"></i></span>
					<div class="clearfix"></div>
				</div>
			</a>
		</div>
	</div>
	<div class="col-lg-3 col-md-6">
		<div class="panel panel-yellow">
		
			<?php
				$query = $link->query("SELECT SUM(`points`) FROM `ranks` WHERE `points` > 0");
				$array2 = mysqli_fetch_array($query);
				$total_points = $array2[0];
				$total_points = unitFormat($total_points, $decimals = 2);
				
				$query = $link->query("SELECT AVG(`points`) FROM `ranks` WHERE `points` > 100");
				$array2 = mysqli_fetch_array($query);
				$avg_points = $array2[0];
				$avg_points = unitFormat($avg_points, $decimals = 0);
			?>
		
			<div class="panel-heading">
				<div class="row">
					<div class="col-xs-12 text-center">
						<div class="huge">Points</div>
					</div>
					<div class="col-xs-6 text-left">
						<div class="huge"><?php echo $total_points ?></div>
					</div>
					<div class="col-xs-6 text-right">
						<div class="huge">~<?php echo $avg_points ?></div>
					</div>
					<div class="col-xs-6 text-left">
						<div>Total</div>
					</div>
					<div class="col-xs-6 text-right">
						 <div>Average</div>
					</div>
				</div>
			</div>
			<a href="index.php?site=points">
				<div class="panel-footer">
					<span class="pull-left">View details</span>
					<span class="pull-right"><i class="fa fa-arrow-circle-right"></i></span>
					<div class="clearfix"></div>
				</div>
			</a>
		</div>
	</div>
	<div class="col-lg-3 col-md-6">
		<div class="panel panel-green">
		
			<?php
				$query = $link->query("SELECT COUNT(*) FROM `mapzone` WHERE `type` = 0");
				$array2 = mysqli_fetch_array($query);
				$total_maps = $array2[0];

				$query = $link->query("SELECT COUNT(*) FROM `mapzone` WHERE `type` = 7");
				$array2 = mysqli_fetch_array($query);
				$total_bonusmaps = $array2[0];
			?>
			
			<div class="panel-heading">
				<div class="row">
					<div class="col-xs-12 text-center">
						<div class="huge">Maps</div>
					</div>
					<div class="col-xs-6 text-left">
						<div class="huge"><?php echo $total_maps ?></div>
					</div>
					<div class="col-xs-6 text-right">
						<div class="huge"><?php echo $total_bonusmaps ?></div>
					</div>
					<div class="col-xs-6 text-left">
						<div>Normal</div>
					</div>
					<div class="col-xs-6 text-right">
						 <div>Bonus</div>
					</div>
				</div>
			</div>
			<a href="index.php?site=maptop">
				<div class="panel-footer">
					<span class="pull-left">View details</span>
					<span class="pull-right"><i class="fa fa-arrow-circle-right"></i></span>
					<div class="clearfix"></div>
				</div>
			</a>
		</div>
	</div>
	<div class="col-lg-3 col-md-6">
		<div class="panel panel-primary">
		
			<?php
				$query = $link->query("SELECT COUNT(*) FROM `online`");
				$array2 = mysqli_fetch_array($query);
				$online = $array2[0];
			?>
			<div class="panel-heading">
				<div class="row">
					<?php	//GET SERVERS					
						$server_names = array_keys($server_list);
						$server_ips = array_values($server_list);
					?>
					<div class="col-xs-12 text-center">
						<div class="huge">Status</div>
					</div>
					<div class="col-xs-6 text-left">
						<div class="huge"><?php echo $online ?></div>
					</div>
					<div class="col-xs-6 text-right">
						<div class="huge"><?php echo count($server_ips) ?></div>
					</div>
					<div class="col-xs-6 text-left">
						<div>Players online</div>
					</div>
					<div class="col-xs-6 text-right">
						 <div>Server connected</div>
					</div>
				</div>
			</div>
			<a href="index.php?site=status">
				<div class="panel-footer">
					<span class="pull-left">View details</span>
					<span class="pull-right"><i class="fa fa-arrow-circle-right"></i></span>
					<div class="clearfix"></div>
				</div>
			</a>
		</div>
	</div>
</div>
<div class="row">
	<div class="col-lg-3">
		<div class="panel panel-default">
			<div class="panel-heading">Most World Records</div>
			<div class="panel-body">
				<div class="table-responsive">
					<table class="table table-striped table-bordered table-hover" id="dataTables-example">
						<thead>
							<tr>
								<th>Player</th>
								<th>WRs</th>
							</tr>
						</thead>
						<tbody>
						<?php
						$sql = "SELECT COUNT(*), `name`, `auth` FROM (SELECT * FROM `round` WHERE `rank` = 1) AS s GROUP BY `auth` ORDER BY 1 DESC LIMIT 10";
						$players = $link->query($sql);
						while($array = mysqli_fetch_array($players))
						{
						   echo "<tr class=\"odd gradeX\"><td><a href='index.php?site=player&auth=".$array[2]."'>".$array[1]."</a></td><td>".$array[0]."</td></tr>";
						}
						?>
						</tbody>
					</table>
				</div>
			</div>
		</div>
	</div>
	<div class="col-lg-3">
		<div class="panel panel-default">
			<div class="panel-heading">Most Points</div>
			<div class="panel-body">
				<div class="table-responsive">
					<table class="table table-striped table-bordered table-hover" id="dataTables-example">
						<thead>
							<tr>
								<th>Player</th>
								<th>Points</th>
							</tr>
						</thead>
						<tbody>
						<?php
						$sql = "SELECT `points`, `lastname`, `auth` FROM `ranks` ORDER BY `points` DESC LIMIT 10";
						$players = $link->query($sql);
						while($array = mysqli_fetch_array($players))
						{
						   echo "<tr class=\"odd gradeX\"><td><a href='index.php?site=player&auth=".$array[2]."'>".$array[1]."</a></td><td>".$array[0]."</td></tr>";
						}
						?>
						</tbody>
					</table>
				</div>
			</div>
		</div>
	</div>
	<div class="col-lg-3">
		<div class="panel panel-default">
			<div class="panel-heading">Top Maps</div>
			<div class="panel-body">
				<div class="table-responsive">
					<table class="table table-striped table-bordered table-hover" id="dataTables-example">
						<thead>
							<tr>
								<th>Map</th>
								<th>Records</th>
							</tr>
						</thead>
						<tbody>
						<?php
						$sql = "SELECT `map`, COUNT(*) FROM `round` GROUP BY `map` ORDER BY 2 DESC LIMIT 10";
						$players = $link->query($sql);
						while($array = mysqli_fetch_array($players))
						{
						   echo "<tr class=\"odd gradeX\"><td><a href='index.php?site=maptop&map=".$array[0]."&style=-1&track=-1'>".$array[0]."</a></td><td>".$array[1]."</td></tr>";
						}
						?>
						</tbody>
					</table>
				</div>
			</div>
		</div>
	</div>
	<div class="col-lg-3">
		<div class="panel panel-default">
			<div class="panel-heading">New Maps</div>
			<div class="panel-body">
				<div class="table-responsive">
					<table class="table table-striped table-bordered table-hover" id="dataTables-example">
						<thead>
							<tr>
								<th>Map</th>
								<th>Records</th>
							</tr>
						</thead>
						<tbody>
						<?php
						$sql = "SELECT `map`, SUM(`type`) FROM `mapzone` WHERE `type` = 0 OR `type` = 7 GROUP BY `map` ORDER BY `id` DESC LIMIT 10";
						$players = $link->query($sql);
						while($array = mysqli_fetch_array($players))
						{
							$query = $link->query("SELECT COUNT(*) FROM `round` WHERE `map` = '".$array[0]."'");
							$array2 = mysqli_fetch_array($query);
							$maprecords = $array2[0];
							echo "<tr class=\"odd gradeX\"><td><a href='index.php?site=maptop&map=".$array[0]."&style=-1&track=-1'>".$array[0]."</a></td><td>".$maprecords."</td></tr>";
						}
						?>
						</tbody>
					</table>
				</div>
			</div>
		</div>
	</div>
</div>