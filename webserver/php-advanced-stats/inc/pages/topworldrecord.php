<div class="row">
	<div class="col-lg-12">
		<h1 class="page-header">Top World Records</h1>
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
								<th>Rank</th>
								<th>Player</th>
								<th>WRs</th>
							</tr>
						</thead>
						<tbody>
						<?php
						$sql = "SELECT COUNT(*), `name`, `auth` FROM (SELECT * FROM `round` WHERE `rank` = 1) AS s GROUP BY `auth` ORDER BY 1 DESC LIMIT 25";
						$players = $link->query($sql);
						$rank = 0;
						while($array = mysqli_fetch_array($players))
						{
						   $rank++;
						   echo "<tr class=\"odd gradeX\"><td>".$rank."</td><td><a href='index.php?site=player&auth=".$array[2]."'>".$array[1]."</a></td><td>".$array[0]."</td></tr>";
						}
						?>
						</tbody>
					</table>
				</div>
			</div>
		</div>
	</div>
	<div class="col-lg-9">
		<div class="panel panel-default">
			<div class="panel-heading">Latest World Records</div>
			<div class="panel-body">
				<div class="table-responsive">
					<table class="sortable table table-striped table-bordered table-hover" id="dataTables-example">
						<thead>
							<tr>
								<th>Player</th>
								<th>Map</th>
								<th>Time</th>
								<th>Style</th>
								<th>Track</th>
								<th>Date</th>
							</tr>
						</thead>
						<tbody>
						<?php
						$sql = "SELECT `rank`, `map`, `auth`, `name`, `time`, `date`, `style`, `track` FROM `round` WHERE `rank` = 1 ORDER BY `date` DESC LIMIT 25";
						$players = $link->query($sql);
						while($array = mysqli_fetch_array($players))
						{
						   echo "<tr class=\"odd gradeX\">
						   <td><a href='index.php?site=player&auth=".$array[2]."'>".$array[3]."</a></td>
						   <td>".$array[1]."</td>
						   <td>".timeFormat($array[4])."</td>
						   <td>".getKeyByArrayValue($array[6], $style_list)."</td>
						   <td>".getKeyByArrayValue($array[7], $track_list)."</td>
						   <td>".$array[5]."</td>
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