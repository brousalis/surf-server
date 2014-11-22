<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
<head>
<title>Timer Stats by Zipcore</title>
<meta http-equiv="Content-Type" content="text/html;charset=utf-8">
<link href="inc/style.css" rel="stylesheet" type="text/css" />
</head>
<body>

<?php
$time = microtime();
$time = explode(' ', $time);
$time = $time[1] + $time[0];
$start = $time;

require_once("inc/config.inc.php");
require_once("inc/functions.inc.php");
require_once("inc/pagenavigation.class.php");

$astylename = array_keys($styles);
$astyleid = array_values($styles);

$atrackname = array_keys($track_list);
$atrackid = array_values($track_list);

$aranks = array_keys($chat_ranks);
$arank = array_values($chat_ranks);

echo "<div id='container'>
<div id='logo'>
  <center><h1>".$name." - Timer Stats</h1></center>
</div>";

if($menu_enable == 1)
{
	echo "<div id='menu'>";
	echo "<center>";
	echo "<ul>";
	if($home_button == 1) echo "<li><b><a href='".$path_home."'><home><span>Forum</span></home></a></b></li>";
	echo "<li><b><a href='index.php'><server><span>Server Info</span></server></a></b></li>";
	echo "<li><b><a href='mapinfo.php'><mapinfo><span>Map Info</span></mapinfo></a></b></li>";
	echo "<li><b><a href='points.php'><points><span>Points Ranking</span></points></a></b></li>";
	echo "<li><b><a href='records.php'><records><span>Map Records</span></records></a></b></li>";
	echo "<li><b><a href='latest.php'><latest><span>Latest Records</span></latest></a></b></li>";
	echo "<li><b><a href='ranks.php'><ranks><span>Chatranks</span></ranks></a></b></li>";
	echo "<li><b><a href='player.php'><player><span>Player Search</span></player></a></b></li>";
	if($join_button == 1) echo "<li class='last'><b><a href='steam://connect/".$gameserverip.":".$serverport."'><join><span>Join Server</span></join></a></b></li>";
	echo "</ul>";
	echo "</center>";
	echo "</div>";
	echo "<div id='logo'>";
	echo "<h1></h1>";
	echo "</div>";
}

$query = $link->query("SELECT COUNT(*) FROM `round`");
$array2 = mysqli_fetch_array($query);
$total_records = $array2[0];
$total_records = number_format($total_records, 0, ',', ' ');

$query = $link->query("SELECT COUNT(*) FROM `ranks`");
$array2 = mysqli_fetch_array($query);
$total_players = $array2[0];
$total_players = number_format($total_players, 0, ',', ' ');

$query = $link->query("SELECT COUNT(*) FROM `mapzone` WHERE `type` = 0");
$array2 = mysqli_fetch_array($query);
$total_maps = $array2[0];

$query = $link->query("SELECT COUNT(*) FROM `mapzone` WHERE `type` = 7");
$array2 = mysqli_fetch_array($query);
$total_trackmaps = $array2[0];

$query = $link->query("SELECT SUM(`points`) FROM `ranks` WHERE `points` > 0");
$array2 = mysqli_fetch_array($query);
$total_points = $array2[0];
$total_points = number_format($total_points, 0, ',', ' ');

$query = $link->query("SELECT AVG(`points`) FROM `ranks` WHERE `points` > 0");
$array2 = mysqli_fetch_array($query);
$avg_points = $array2[0];
$avg_points = number_format($avg_points, 0, ',', ' ');

$query = $link->query("SELECT COUNT(*) FROM `online`");
$array2 = mysqli_fetch_array($query);
$players = $array2[0];

echo "<div class='serverinfo'>";
echo "<center>";
echo "<h1>Server Stats</h1><br>";
echo "<br>";
echo "This server provides ";
if($multi_styles == 1) echo "<b>".count($astyleid)."</b> ranked styles on ";
echo "<b>".$total_maps."</b> maps with <b>".$total_trackmaps."</b> bonus levels. <br>";
echo "Starring <b>".$total_players."</b> players and their <b>".$total_records."</b> records ";
echo "with <b>".$total_points."</b> points and an average of <b>".$avg_points."</b> points per player.";

echo "</center>";
echo "</div>";

echo "<div class='onlinelist'>";
echo "<center><p>Players Online: <b>".$players."</b>";
echo "<table width='33%' border='1' cellpadding='5' cellspacing='0'>";
echo "<tr>";
echo "<th align=middle>Chatrank</th>";
echo "<th align=middle>Name</th>";
echo "<th align=middle>Points</th>";
echo "<th align=middle>Rank</th>";
echo "</tr>";

$sql = "SELECT `auth` FROM `online`";
$rekorde = $link->query($sql);
while($array = mysqli_fetch_array($rekorde))
{
	$steamfix = $array["auth"];
	$steamfix[6] = '0';
		
	$ex = '"';
	$q = "SELECT `lastname` FROM `ranks` WHERE `auth` = ".$ex.$steamfix.$ex."";
	$query = $link->query($q);
	$array2 = mysqli_fetch_array($query);
	$name = $array2[0];
	
	$q = "SELECT `points` FROM `ranks` WHERE `auth` = ".$ex.$steamfix.$ex."";
	$query = $link->query($q);
	$array2 = mysqli_fetch_array($query);
	$points = $array2[0];

	$query = $link->query("SELECT COUNT(*) FROM `ranks` WHERE `points` >= '".$points."'");
	$array2 = mysqli_fetch_array($query);
	$rank = $array2[0];
	
	//CHATRANK
	$chatrank = $unranked;
	for ($i = 0; $i < count($arank); $i++) {
		if($arank[$i] >= $rank){
			$chatrank = $aranks[$i];
			break;
		}
	}

	//FILL TABLE
	echo "<tr>";

	echo "<td align=middle>".$chatrank."</td>";
	echo "<td align=middle><a href='player.php?searchkey=".$array["auth"]."'>".$name."</a></td>";
	echo "<td align=middle>".$points."</td>";
	echo "<td align=middle>".$rank."</td>";

	//TABLE ROW END
	echo "</tr>";
}

echo "</table></center>";
echo "</div>";



/*
//GEO RANKING
if($geo_enable == 1)
{
	echo "<center><h1 align=right><p><b>Top Countrys</b></h1></center>";
	echo "<center><table width='100%' border='0' cellpadding='5' cellspacing='0'>";
	echo "<tr>";
	echo "<th align=right>Country</th>";
	echo "<th align=middle>Points</th>";

	echo "</tr>";

	$sql = "SELECT `points`, `country` FROM `ranks_geo` WHERE `points` >= ".$points_geo_min." AND `country` != 'Unknown' ORDER BY `points` DESC";
	$rekorde = $link->query($sql);
	$count = 1;
	while($array = mysqli_fetch_array($rekorde))
	{
		echo "<tr>";
		echo "<td align=right>".$array["country"]."</td>";
		echo "<td align=middle>".$array["points"]."</td>";
		echo "</tr>";
		$count ++; 
	}
}
*/

//MOST WRs
echo "<div class='top'>";
echo "<h1 align=left>Most World Records</h1>";
echo "<table width='100%' border='1' cellpadding='5' cellspacing='0';>";
echo "<tr>";
echo "<th align=left>Name</th>";
echo "<th align=middle>WRs</th>";
echo "</tr>";
$sql = "SELECT COUNT(*), `name`, `auth` FROM (SELECT * FROM `round` WHERE `rank` = 1) AS s GROUP BY `auth` ORDER BY 1 DESC LIMIT 10";
$players = $link->query($sql);
while($array = mysqli_fetch_array($players))
{
	echo "<tr>";
	echo "<td align=left><a href='player.php?searchkey=".$array["auth"]."'>".$array["name"]."</a></td>";
	echo "<td align=middle>".$array[0]."</td>";
	echo "</tr>";
}
echo "</table>";
echo "</div>";

//MOST POINTS
echo "<div class='top'>";
echo "<h1 align=left>Most Points</h1>";
echo "<table width='100%' border='1' cellpadding='5' cellspacing='0';>";
echo "<tr>";
echo "<th align=left>Name</th>";
echo "<th align=middle>Points</th>";
echo "</tr>";
$sql = "SELECT `points`, `lastname`, `auth` FROM `ranks` ORDER BY `points` DESC LIMIT 10";
$players = $link->query($sql);
while($array = mysqli_fetch_array($players))
{
	echo "<tr>";
	echo "<td align=left><a href='player.php?searchkey=".$array["auth"]."'>".$array["lastname"]."</a></td>";
	echo "<td align=middle>".$array[0]."</td>";
	echo "</tr>";
}
echo "</table>";
echo "</div>";

//TOP MAPS
echo "<div class='top'>";
echo "<h1 align=left>Top Maps</h1>";
echo "<table width='100%' border='1' cellpadding='5' cellspacing='0';>";
echo "<tr>";
echo "<th align=left>Map</th>";
echo "<th align=middle>Records</th>";
//usw.
echo "</tr>";

$sql = "SELECT `map`, COUNT(*) FROM `round` GROUP BY `map` ORDER BY 2 DESC LIMIT ".$limit_topmaps."";
$rekorde = $link->query($sql);
$count = 1;
while($array = mysqli_fetch_array($rekorde))
{
	//FILL TABLE
	echo "<tr>";

	echo "<td align=left><a href='records.php?map=".$array["map"]."&style=-1&track=-1'>".$array["map"]."</a></td>";
	echo "<td align=middle>".$array[1]."</td>";

	//TABLE ROW END
	echo "</tr>";
	$count ++; 
}

echo "</table>";
echo "</div>";

//NEW MAPS
echo "<div class='top'>";
echo "<h1 align=left>New Maps</h1>";
echo "<table width='100%' border='1' cellpadding='5' cellspacing='0'>";
echo "<tr>";
echo "<th align=left>Map</th>";
echo "<th align=middle>Records</th>";
//usw.
echo "</tr>";
$sql = "SELECT `map`, SUM(`type`) FROM `mapzone` WHERE `type` = 0 OR `type` = 7 GROUP BY `map` ORDER BY `id` DESC LIMIT ".$limit_topmaps."";
$rekorde = $link->query($sql);
$count = 1;
while($array = mysqli_fetch_array($rekorde))
{
	$query = $link->query("SELECT COUNT(*) FROM `round` WHERE `map` = '".$array["map"]."'");
	$array2 = mysqli_fetch_array($query);
	$maprecords = $array2[0];
	
	//FILL TABLE
	echo "<tr>";

	echo "<td align=left><a href='records.php?map=".$array["map"]."&style=-1&track=-1'>".$array["map"]."</a></td>";
	echo "<td align=middle>".$maprecords."</td>";

	//TABLE ROW END
	echo "</tr>";
	$count ++; 
}
echo "</table>";
echo "</div>";

echo "</div>"; //container

echo "<table width='100%' border='0' cellpadding='5' cellspacing='0'>";
echo "<tr>";
echo "<td>";

$time = microtime();
$time = explode(' ', $time);
$time = $time[1] + $time[0];
$finish = $time;
$total_time = round(($finish - $start), 4);
echo "<center>Page generated in ".$total_time." seconds.</center>";
echo "<center><a target='_blank' href='http://forums.alliedmods.net/member.php?u=74431'>Timer Stats &copy; 2014 by Zipcore</a></center>";

echo "</td>";
echo "</tr>";
echo "</table>";

?>
</body>
</html>