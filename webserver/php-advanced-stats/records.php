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

$is_map = false;

//PARAMETERS
if(isset($_POST['map_selected'])){
	$map = $_POST['map_selected'];
	$is_map = true;
}
else if(isset($_GET['map'])){
	$map = $_GET['map'];
	$is_map = true;
}

if (isset($map)) {
	
		$map = $link->real_escape_string($map);
}

if(isset($_POST['style_selected'])){
	$style = intval($_POST['style_selected']);
}
else if(isset($_GET['style'])){
	$style = intval($_GET['style']);
}
else $style = -1;

if(isset($_POST['track_selected'])){
	$track = intval($_POST['track_selected']);
}
else if(isset($_GET['track'])){
	$track = intval($_GET['track']);
}
else $track = -1;

$query = $link->query("SELECT COUNT(*) FROM `round`");
$array2 = mysqli_fetch_array($query);
$total_records = $array2[0];

$query = $link->query("SELECT COUNT(*) FROM `ranks`");
$array2 = mysqli_fetch_array($query);
$total_players = $array2[0];

echo "<div class='serverinfo'>";
echo "<center>";
echo "Total Records: <b>".$total_records."</b> Total Players: <b>".$total_players."</b>";
echo "</center>";
echo "</div>"; //serverinfo

//MAPS
echo "<div class='list'>";
echo "<h1><center><p><b>Map Records</b></center></h1>";
echo "<form name=\"params\" method=\"post\"><center><b>Map </b><br>"
. "<select  name=\"map_selected\">";
echo "<option value=\"\">--------------------------------------------------------</option>";

$result = $link->query("SELECT `map` FROM `mapzone` WHERE `type` = 0 ORDER BY `map` ASC");
while ($row = mysqli_fetch_object($result)){
	if(!$is_map){
		echo "<option value=\"".$row->map."\" selected=\"111\">".$row->map."</option>";
		$map = $row->map;
		$is_map = true;
	}
	else if($row->map == $map){
		echo "<option value=\"".$row->map."\" selected=\"111\">".$row->map."</option>";
	}
	else{
		echo "<option value=\"".$row->map."\">".$row->map."</option>";
	}
}
echo "</select>"
. "</center>";

//STYLES
if($multi_styles == 1)
{
	echo "<form name=\"params\" method=\"post\"><center><b>Style </b><br>"
	. "<select name=\"style_selected\">";

	echo "<option value=\"\">--------------------------------------------------------</option>";

	if ($style == -1)
	{
		echo "<option value=-1 selected=\"111\">".$any_style_name."</option>";
	}
	else
	{
		echo "<option value=-1>".$any_style_name."</option>";
	}
	for ($i = 0; $i < count($astyleid); $i++) {
		if($astyleid[$i] == $style){
			echo "<option value=".$astyleid[$i]." selected=\"111\">".$astylename[$i]."</option>";
		}
		else{
			echo "<option value=".$astyleid[$i].">".$astylename[$i]."</option>";
		}
	}
	echo "</select>"
	. "</center>";
}

//track

echo "<center><b>Area </b><br>"
. "<select name=\"track_selected\">";

echo "<option value=\"\">--------------------------------------------------------</option>";

for ($i = 0; $i < count($atrackid); $i++) {
	if($atrackid[$i] == $track){
		echo "<option value=".$atrackid[$i]." selected=\"111\">".$atrackname[$i]."</option>";
	}
	else{
		echo "<option value=".$atrackid[$i].">".$atrackname[$i]."</option>";
	}
}
echo "</select>"
. "<p><input type=\"submit\" name=\"map\" value=\"Show Records\" /></p>"
. "</form></center>";

if($is_map){

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
	
	if($track == -1 && $style == -1){
		echo "<div class='maininfo'>";
		echo "<center>";
		echo "Map-Tier: <b>".$maptier." </b>";
		if($maptier2 > 0) echo "Bonus-Tier: <b>".$maptier2." </b>";
		echo "<br>";
		if($current_records > 0) echo "Records: <b>".$current_records."</b>";
		if($current_records_short > 0) echo " Short: <b>".$current_records_short."</b>";
		if($current_records_track > 0) echo " track: <b>".$current_records_track."</b>";
		echo "</center><br>";
		echo "</div>";
	}

	//NAVIGATION
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
	$nav = new PageNavigation($totalplayers, $limit_view);

	$nav->url = "?map=".$map."&style=".$style."&track=".$track."&%p";

	if($style == -1){
		if($track == -1){
			$sql = "SELECT `map`, `rank`, `name`, `time`, `date`, `auth`, `style`, `track` FROM `round` WHERE `map` LIKE '".$map."' ORDER BY `time` ASC LIMIT ".$nav->sql_limit."";
		}
		else{
			$sql = "SELECT `map`, `rank`, `name`, `time`, `date`, `auth`, `style` FROM `round` WHERE `map` LIKE '".$map."' AND `track` = '".$track."' ORDER BY `time` ASC LIMIT ".$nav->sql_limit."";
		}
	}
	else{
		if($track == -1){
			$sql = "SELECT `map`, `rank`, `name`, `time`, `date`, `auth`, `track` FROM `round` WHERE `map` LIKE '".$map."' AND `style` = '".$style."' ORDER BY `time` ASC LIMIT ".$nav->sql_limit."";
		}
		else{
			$sql = "SELECT `map`, `rank`, `name`, `time`, `date`, `auth` FROM `round` WHERE `map` LIKE '".$map."' AND `track` = '".$track."' AND `style` = '".$style."' ORDER BY `time` ASC LIMIT ".$nav->sql_limit."";
		}
	}

	$rekorde = $link->query($sql);
	$count = $nav->first_item_id;

	echo "<center><table cellpadding=\"3\" cellspacing=\"0\" border=\"1\">";

	echo $nav->createPageBar('pagebar-top');
	echo $nav->createPageSelBox();

	echo "<tr>";
	echo "<th>Rank</th>";
	echo "<th>Playername</th>";
	echo "<th>Time</th>";
	if($style == -1 && $multi_styles == 1){
		echo "<th>Style</th>";
	}
	if($track == -1){
		echo "<th>Track</th>";
	}
	echo "<th>Date</th>";
	//usw.
	echo "</tr>";
	while($array = mysqli_fetch_array($rekorde))
	{ 
		//FORMAT RUNTIME
		$runmillisecs = $array["time"] * 100 % 100;
		$runseconds = $array["time"] / 1;
		$runseconds_trim = $runseconds % 60;
		$runminutes = $array["time"] / 60;
		$zahl=$runminutes;
		$vor_komma=substr($zahl, 0, (strpos($zahl, ".")));

		//BUILD COMUNITY PROFILE LINK
		$steam64 = (int) steam2friend($array["auth"]);

		//FILL TABLE
		echo "<tr>";
		
		if($style >= 0 && $track >= 0) echo "<td align=\"middle\">".$count."</td>";
		else echo "<td align=\"middle\">&nbsp;".$array["rank"]."&nbsp;</td>";
		echo "<td align=\"left\"><a href='player.php?searchkey=".$array["auth"]."'>&nbsp;".$array["name"]."&nbsp;</a></td>";
		echo "<td align=\"middle\">".$vor_komma." m ".$runseconds_trim.".".$runmillisecs." s</td>";
		
		//Style
		if($style == -1 && $multi_styles == 1)
		{
			if($style == -1){
				$istyle = 0;
				while($astyleid[$istyle] < $array["style"]){
					$istyle ++;
				}
				echo "<td align=\"left\">&nbsp;".$astylename[$istyle]."&nbsp;</td>";
			}
		}
		//Track
		if($track == -1){
			$itrack = 0;
			while($atrackid[$itrack] < $array["track"]){
				$itrack ++;
			}
			echo "<td align=\"left\">&nbsp;".$atrackname[$itrack]."&nbsp;</td>";
		}
		echo "<td align=\"middle\">".$array["date"]."</td>";
			
		echo "</tr>";

		//TABLE ROW END

		$count ++; 
	}
	echo "</table>";
	echo $nav->createPageBar('pagebar-bottom');
	echo "</center>";
}
echo "</div>";
echo "</div>";

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