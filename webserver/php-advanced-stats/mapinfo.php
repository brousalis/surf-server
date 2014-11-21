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

$query = $link->query("SELECT COUNT(*) FROM `mapzone` WHERE `type` = 0");
$array2 = mysqli_fetch_array($query);
$total_maps = $array2[0];

$query = $link->query("SELECT COUNT(*) FROM `mapzone` WHERE `type` = 7");
$array2 = mysqli_fetch_array($query);
$total_trackmaps = $array2[0];

$query = $link->query("SELECT COUNT(*) FROM `mapzone`");
$array2 = mysqli_fetch_array($query);
$total_zones = $array2[0];

echo "<div class='serverinfo'>";

echo "<center>";
echo "Maps: <b>".$total_maps."</b> track: <b>".$total_trackmaps."</b> Zones: <b>".$total_zones."</b>";
echo "</center>";

echo "</div>"; //serverinfo

echo "<div class='list'>";
echo "<center><h1>Map Info</h1>";
echo "<table cellpadding=\"3\" cellspacing=\"0\" border=\"1\">";
echo "<tr>";
echo "<th>Map</th>";
echo "<th>Stages</th>";
echo "<th>Tier</th>";
echo "<th>Records</th>";
echo "<th>Zones</th>";
echo "</tr>";

$sql = "SELECT `map`, SUM(`type`) FROM `mapzone` WHERE `type` = 0 OR `type` = 7 GROUP BY `map` ORDER BY `map`";
//$rekorde = $link->query($sql);
$rekorde = $link->query($sql);
$count = 1;
while($array = mysqli_fetch_array($rekorde))
{
	//FILL TABLE
	echo "<tr>";
	
	$query = $link->query("SELECT `tier` FROM `maptier` WHERE `track` = 0 AND `map` = '".$array["map"]."'");
	$array2 = mysqli_fetch_array($query);
	$maptier = $array2[0];
	
	$query = $link->query("SELECT `tier` FROM `maptier` WHERE `track` = 1 AND `map` = '".$array["map"]."'");
	$array2 = mysqli_fetch_array($query);
	$maptier2 = $array2[0];
	
	$query = $link->query("SELECT `stagecount` FROM `maptier` WHERE `track` = 0 AND `map` = '".$array["map"]."'");
	$array2 = mysqli_fetch_array($query);
	$stagecount = $array2[0];
	
	$query = $link->query("SELECT `stagecount` FROM `maptier` WHERE `track` = 1 AND `map` = '".$array["map"]."'");
	$array2 = mysqli_fetch_array($query);
	$stagecount2 = $array2[0];
	
	$query = $link->query("SELECT COUNT(*) FROM `mapzone` WHERE `map` = '".$array["map"]."'");
	$array2 = mysqli_fetch_array($query);
	$zonecount = $array2[0];
	
	$query = $link->query("SELECT COUNT(*) FROM `round` WHERE `map` = '".$array["map"]."'");
	$array2 = mysqli_fetch_array($query);
	$maprecords = $array2[0];
	
	//<a href='steam://connect/".$gameserverip.":".$serverport."'><span>Join Server</span></a>

	echo "<td align=\"middle\"><a href='records.php?map=".$array["map"]."&style=-1&track=-1'>".$array["map"]."</a></td>";
	
	if($array["SUM(`type`)"] == 7){
		$istrack = true;
	}
	else{
		$istrack = false;
	}
	
	if($istrack)
	{
		echo "<td align=\"middle\">".$stagecount." & ".$stagecount2."</td>";
		echo "<td align=\"middle\">".$maptier." & ".$maptier2."</td>";
	}
	else{
		echo "<td align=\"middle\">".$stagecount."</td>";
		echo "<td align=\"middle\">".$maptier."</td>";
	}
	
	echo "<td align=\"middle\">".$maprecords."</td>";
	echo "<td align=\"middle\">".$zonecount."</td>";

	//TABLE ROW END
	echo "</tr>";
	$count ++; 
}

echo "</table>";
echo "</center></div>";

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