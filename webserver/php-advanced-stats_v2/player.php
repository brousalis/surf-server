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
							<a href="status.php">Player/Server Status</a>
						</li>
                        <li>
                            <a href="#">Top Players<span class="fa arrow"></span></a>
                            <ul class="nav nav-second-level">
								<li>
									<a href="points.php">by Points</a>
								</li>
								<li>
									<a href="records.php">by World Records</a>
								</li>
								<li>
									<a href="complete.php">by Completion</a>
								</li>
								<li>
									<a href="average.php">by Average Rank</a>
								</li>
                            </ul>
                        </li>
                        <li>
                            <a href="#">Player Records<span class="fa arrow"></span></a>
                            <ul class="nav nav-second-level">
								<li>
									<a href="latest.php">Latest Records</a>
								</li>
								<li>
									<a href="maprecords.php">Map Top</a>
								</li>
                            </ul>
                        </li>
						<li>
							<a href="maps.php">Map Info</a>
						</li>
						<li>
							<a href="ranks.php">Chatranks</a>
						</li>
                    </ul>
                </div>
            </div>
        </nav>
		
		<!-- GET PLAYER -->
		
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
			if($valid)
			{
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
				
				//GET TRACKS
				$track_names = array_keys($track_list);
				$track_ids = array_values($track_list);
				
				//GET CHATRANKS
				$rank_tags = array_keys($chattag_list);
				$rank_range = array_values($chattag_list);

				//GET STATS
				$query = $link->query("SELECT `lastname` FROM `ranks` WHERE (`auth` = ".$ex.$steamid.$ex." OR `auth` = ".$ex.$steamfix.$ex.") GROUP BY `auth`");
				$array2 = mysqli_fetch_array($query);
				$name = $array2[0];

				//GetFinishd Maps Count
				$query = $link->query("SELECT COUNT(*) FROM `round` WHERE `track` = 0 AND (`auth` = ".$ex.$steamid.$ex." OR `auth` = ".$ex.$steamfix.$ex.")");
				$array2 = mysqli_fetch_array($query);
				$count_records = $array2[0];
				
				$query = $link->query("SELECT COUNT(*) FROM `round` WHERE `track` = 1 AND (`auth` = ".$ex.$steamid.$ex." OR `auth` = ".$ex.$steamfix.$ex.")");
				$array2 = mysqli_fetch_array($query);
				$count_bonusrecords = $array2[0];

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
				$complete = round(100*($count_records+$count_bonus_records)/($total_maps+$total_bonusmaps), 2);
			}
			
			if(!$valid || !isset($name) )
				$name = ">>not found<<";
		?>
		
		<!-- MAIN -->

        <div id="page-wrapper">
            <div class="row">
                <div class="col-lg-12">
					<h1 class="page-header">Player Stats for <?php echo $name." [".$auth."]" ?></h1>
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
                                    <div>Top10 Records</div>
                                </div>
                                <div class="col-xs-4 text-right">
									 <div>Records</div>
                                </div>
                            </div>
                        </div>
                        <a href="#">
                            <div class="panel-footer">
                                <span class="pull-left">View All Records</span>
                                <span class="pull-right"><i class="fa fa-arrow-circle-right"></i></span>
                                <div class="clearfix"></div>
                            </div>
                        </a>
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
                                    <div class="huge"><?php echo $points ?></div>
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
                        <a href="#">
                            <div class="panel-footer">
                                <span class="pull-left">View Next Players</span>
                                <span class="pull-right"><i class="fa fa-arrow-circle-right"></i></span>
                                <div class="clearfix"></div>
                            </div>
                        </a>
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
                                    <div class="huge"><?php echo $records ?></div>
                                </div>
                                <div class="col-xs-4 text-center">
                                    <div>Compelte</div>
                                </div>
                                <div class="col-xs-4 text-right">
                                    <div class="huge"><?php echo $total_maps+$total_bonusmaps-$records ?></div>
                                </div>
                                <div class="col-xs-6 text-left">
                                    <div>Finished</div>
                                </div>
                                <div class="col-xs-6 text-right">
									 <div>Incomplete</div>
                                </div>
                            </div>
                        </div>
                        <a href="#">
                            <div class="panel-footer">
                                <span class="pull-left">View Incomplete Maps</span>
                                <span class="pull-right"><i class="fa fa-arrow-circle-right"></i></span>
                                <div class="clearfix"></div>
                            </div>
                        </a>
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
                        <a href="#">
                            <div class="panel-footer">
                                <span class="pull-left">View Advanced PvP Stats</span>
                                <span class="pull-right"><i class="fa fa-arrow-circle-right"></i></span>
                                <div class="clearfix"></div>
                            </div>
                        </a>
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
									   <td>".getStyle($array[3], $style_list)."</td>
									   <td>".getTrack($array[4], $track_list)."</td>
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
									   <td>".getStyle($array[3], $style_list)."</td>
									   <td>".getTrack($array[4], $track_list)."</td>
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
