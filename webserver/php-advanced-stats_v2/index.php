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

    <!-- Bootstrap Core CSS -->
    <link href="css/bootstrap.min.css" rel="stylesheet">

    <!-- MetisMenu CSS -->
    <link href="css/plugins/metisMenu/metisMenu.min.css" rel="stylesheet">

    <!-- Custom CSS -->
    <link href="css/sb-custom.css" rel="stylesheet">

    <!-- Custom Fonts -->
    <link href="font-awesome-4.1.0/css/font-awesome.min.css" rel="stylesheet" type="text/css">

    <!-- HTML5 Shim and Respond.js IE8 support of HTML5 elements and media queries -->
    <!-- WARNING: Respond.js doesn't work if you view the page via file:// -->
    <!--[if lt IE 9]>
        <script src="https://oss.maxcdn.com/libs/html5shiv/3.7.0/html5shiv.js"></script>
        <script src="https://oss.maxcdn.com/libs/respond.js/1.4.2/respond.min.js"></script>
    <![endif]-->

</head>

<body>

    <div id="wrapper">

        <!-- Navigation -->
        <nav class="navbar navbar-default navbar-static-top" role="navigation" style="margin-bottom: 0">
            <div class="navbar-header">
                <a class="navbar-brand" href="index.php"><?php echo $name ?> - Timer Stats v2</a>
            </div>
            <ul class="nav navbar-top-links navbar-right">
                <li class="dropdown">
                    <a class="dropdown-toggle" data-toggle="dropdown" href="#">
                        About <i class="fa fa-caret-down"></i>
                    </a>
                    <ul class="dropdown-menu dropdown-messages">
                        <li>
								<a href="http://github.com/Zipcore/Timer">Project Home</a>
								<a href="http://github.com/Zipcore/Timer/releases">Changelog</a>
								<a href="http://github.com/Zipcore/Timer/wiki">Wiki</a>
								<a href="http://github.com/Zipcore/Timer/issues/new">Report Bugs</a>
                        </li>
                        <li class="divider"></li>
                        <li>
								<a><img src="img/zipcore.png"> Contact Zipcore:</a>
								<a href="http://forums.alliedmods.net/member.php?u=74431"><img src="img/am.png"> AlliedMods</a>
								<a href="http://github.com/Zipcore"><img src="img/github.png"> GitHub</a>
								<a href="http://http://steamcommunity.com/profiles/76561198035410392"><img src="img/steam.png"> Steam</a>
                        </li>
                    </ul>
                    <!-- /.dropdown-messages -->
                </li>
            </ul>
            <!-- /.navbar-top-links -->

            <div class="navbar-default sidebar" role="navigation">
                <div class="sidebar-nav navbar-collapse">
                    <ul class="nav" id="side-menu">
                        <li class="sidebar-search">
                            <div class="input-group custom-search-form">
                                <input type="text" class="form-control" placeholder="Player Search...">
                                <span class="input-group-btn">
                                <button class="btn btn-default" type="button">
                                    <i class="fa fa-search"></i>
                                </button>
                            </span>
                            </div>
                        </li>
						<li>
							<a href="<?php echo $path_homepage?>"><?php echo $name_homepage?></a>
						</li>
						<li>
							<a href="index.php">Dashboard</a>
						</li>
                        <li>
                            <a href="#">Servers<span class="fa arrow"></span></a>
                            <ul class="nav nav-second-level">
							
							<?php	//GET SERVERS					
							$server_names = array_keys($server_list);
							$server_ips = array_values($server_list);
							
							for ($i = 0; $i < count($server_ips); $i++) 
							{
								echo "<li><a href=\"steam://connect/".$server_ips[$i]."\">".$server_names[$i]."</a></li>"; //
							}
							?>
							
                            </ul>
                            <!-- /.nav-second-level -->
                        </li>
						<li>
							<a href="online.php">Players Online</a>
						</li>
						
                        <li>
                            <a href="#">Top Players<span class="fa arrow"></span></a>
                            <ul class="nav nav-second-level">
								<li>
									<a href="points.php">Players by Points</a>
								</li>
								<li>
									<a href="records.php">Players by World Records</a>
								</li>
								<li>
									<a href="complete.php">Players by Completion</a>
								</li>
								<li>
									<a href="complete.php">Players by Average Rank</a>
								</li>
                            </ul>
                        </li>
						<li>
							<a href="latest.php">Latest Records</a>
						</li>
						<li>
							<a href="maprecords.php">Map Top</a>
						</li>
						<li>
							<a href="maps.php">Map List</a>
						</li>
						<li>
							<a href="ranks.php">Chatranks</a>
						</li>
                    </ul>
                </div>
            </div>
        </nav>
		
		// MAIN

        <div id="page-wrapper">
            <div class="row">
                <div class="col-lg-12">
                    <h1 class="page-header">Dashboard</h1>
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
                        <a href="complete.php">
                            <div class="panel-footer">
                                <span class="pull-left">View Details</span>
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
                        <a href="points.php">
                            <div class="panel-footer">
                                <span class="pull-left">View Details</span>
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
                        <a href="maps.php">
                            <div class="panel-footer">
                                <span class="pull-left">View Details</span>
                                <span class="pull-right"><i class="fa fa-arrow-circle-right"></i></span>
                                <div class="clearfix"></div>
                            </div>
                        </a>
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
                        <a href="online.php">
                            <div class="panel-footer">
                                <span class="pull-left">View Details</span>
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
                                       echo "<tr class=\"odd gradeX\"><td><a href='player.php?searchkey=".$array[2]."'>".$array[1]."</a></td><td>".$array[0]."</td></tr>";
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
                                       echo "<tr class=\"odd gradeX\"><td><a href='player.php?searchkey=".$array[2]."'>".$array[1]."</a></td><td>".$array[0]."</td></tr>";
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
                                       echo "<tr class=\"odd gradeX\"><td><a href='records.php?map=".$array[0]."&style=-1&track=-1'>".$array[0]."</a></td><td>".$array[1]."</td></tr>";
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
										echo "<tr class=\"odd gradeX\"><td><a href='records.php?map=".$array[0]."&style=-1&track=-1'>".$array[0]."</a></td><td>".$maprecords."</td></tr>";
									}
									?>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <div class="row">
                <div class="col-lg-12">
                    <center><a target='_blank' href='http://forums.alliedmods.net/member.php?u=74431'>Timer Stats &copy; 2014 by Zipcore</a></center>
                </div>
            </div>
        </div>

    </div>
    <!-- /#wrapper -->

    <!-- jQuery -->
    <script src="js/jquery.js"></script>

    <!-- Bootstrap Core JavaScript -->
    <script src="js/bootstrap.min.js"></script>

    <!-- Metis Menu Plugin JavaScript -->
    <script src="js/plugins/metisMenu/metisMenu.min.js"></script>

    <!-- Custom Theme JavaScript -->
    <script src="js/sb-custom.js"></script>

</body>

</html>
