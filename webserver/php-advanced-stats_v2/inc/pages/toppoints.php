<div class="row">
	<div class="col-lg-12">
		<h1 class="page-header">Top Points</h1>
	</div>
</div>
<div class="row">
	<div class="col-lg-12">
		<div class="panel panel-default">
			<div class="panel-heading">Top Players by Points</div>
			<div class="panel-body">
				<div class="table-responsive">
					<table class="table table-striped table-bordered table-hover" id="dataTables-example">
						<thead>
							<tr>
								<th>Rank</th>
								<th>Player</th>
								<th>Chatrank</th>
								<th>Points</th>
								<th>Avg. Rank</th>
								<th>WRs</th>
								<th>Records</th>
								<th>Total FC</th>
								<th>Last Seen</th>
							</tr>
						</thead>
						<tbody>
						<?php
						$sql = "SELECT `points`, `lastname`, `auth`, `lastplay` FROM `ranks` ORDER BY `points` DESC LIMIT 25";
						$players = $link->query($sql);
						
						
						$rank = 0;
						while($array = mysqli_fetch_array($players))
						{
							$rank++;
							$lastplay = $array["lastplay"];
							$timestamp = gmdate("Y-m-d\ H:i:s", $lastplay);
							
							$steamfix = $array[2];
							
							if($steamfix[6] == '0'){
								$steamfix[6] = '1';
							}
							else{
								$steamfix[6] = '0';
							}
						   
							$query = $link->query("SELECT AVG(`rank`) FROM `round` WHERE `auth` = \"".$steamfix."\"");
							$array2 = mysqli_fetch_array($query);
							$count_avgrank = unitFormat($array2[0]);
						   
							$query = $link->query("SELECT COUNT(*) FROM `round` WHERE `rank` = 1 AND `auth` = \"".$steamfix."\"");
							$array2 = mysqli_fetch_array($query);
							$count_wrs = $array2[0];
						   
							$query = $link->query("SELECT COUNT(*) FROM `round` WHERE `auth` = \"".$steamfix."\"");
							$array2 = mysqli_fetch_array($query);
							$count_records = $array2[0];
						   
							$query = $link->query("SELECT SUM(`finishcount`) FROM `round` WHERE `auth` = \"".$steamfix."\"");
							$array2 = mysqli_fetch_array($query);
							$count_finishcount = $array2[0];
						   
							echo "<tr class=\"odd gradeX\">
								<td>".$rank."</td>
								<td><a href='index.php?site=player&auth=".$array[2]."'>".$array[1]."</a></td>
								<td>".getChatRank($rank, $chattag_list)."</td>
								<td>".$array[0]."</td>
								<td>".$count_avgrank."</td>
								<td>".$count_wrs."</td>
								<td>".$count_records."</td>
								<td>".$count_finishcount."</td>
								<td>".$timestamp."</td>
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