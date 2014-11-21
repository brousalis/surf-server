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

echo "<div class='list'>";
echo "<h1><center><p><b>Latest Records</b></center></h1>";

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

if(isset($_POST['filter_selected'])){
	$filter = intval($_POST['filter_selected']);
}
else if(isset($_GET['filter'])){
	$filter = intval($_GET['filter']);
}
else $filter = -1;

//FILTER
echo "<form name=\"params\" method=\"post\"><center><b>Filter </b><br>"
. "<select name=\"filter_selected\">";

echo "<option value=\"\">--------------------------------------------------------</option>";

if ($filter == -1)
{
	echo "<option value=-1 selected=\"111\">".$filter_world."</option>";
}
else
{
	echo "<option value=-1>".$filter_world."</option>";
}

if ($filter == 0)
{
	echo "<option value=0 selected=\"111\">".$filter_top."</option>";
}
else
{
	echo "<option value=0>".$filter_top."</option>";
}

if ($filter == 1)
{
	echo "<option value=1 selected=\"111\">".$filter_any."</option>";
}
else
{
	echo "<option value=1>".$filter_any."</option>";
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
. "<p><input type=\"submit\" name=\"sel_map\" value=\"Show Records\" /></p>"
. "</form></center>";

echo "<center><table cellpadding=\"3\" cellspacing=\"0\" border=\"1\">";
echo "<tr>";
if($filter > -1) echo "<th>#</th>";
echo "<th>Playername</th>";
echo "<th>Map</th>";
echo "<th>Time</th>";
if($style == -1 && $multi_styles == 1){
	echo "<th>Style</th>";
}
if($track == -1){
	echo "<th>Area</th>";
}

echo "</tr>";

if($filter == 1){
	$strfilter = "> 0";
}
else if($filter == 0){
	$strfilter = "<= 10";
}
else{ //-1 WORLD
	$strfilter = "= 1";
}

if($style == -1){
	if($track == -1){
		$sql = "SELECT `rank`, `map`, `auth`, `name`, `time`, `date`, `style`, `track` FROM `round` WHERE `rank` ".$strfilter." ORDER BY `date` DESC LIMIT ".$limit_latest."";
	}
	else{
		$sql = "SELECT `rank`, `map`, `auth`, `name`, `time`, `date`, `style` FROM `round` WHERE `rank` ".$strfilter." AND `track` = '".$track."' ORDER BY `date` DESC LIMIT ".$limit_latest."";
	}
}
else{
	if($track == -1){
		$sql = "SELECT `rank`, `map`, `auth`, `name`, `time`, `date`, `track` FROM `round` WHERE `rank` ".$strfilter." AND `style` = '".$style."' ORDER BY `date` DESC LIMIT ".$limit_latest."";
	}
	else{
		$sql = "SELECT `rank`, `map`, `auth`, `name`, `time`, `date` FROM `round` WHERE `rank` ".$strfilter." AND `style` = '".$style."' AND `track` = '".$track."' ORDER BY `date` DESC LIMIT ".$limit_latest."";
	}
}

$rekorde = $link->query($sql);
$count = 1;
while($array = mysqli_fetch_array($rekorde))
{ 
	//BUILD COMUNITY PROFILE LINK
	$steam64 = (int) steam2friend($array["auth"]);

	//FORMAT RUNTIME
	$runmillisecs = $array["time"] * 100 % 100;
	$runseconds = $array["time"] / 1;
	$runseconds_trim = $runseconds % 60;
	$runminutes = $array["time"] / 60;
	$zahl=$runminutes;
	$vor_komma=substr($zahl, 0, (strpos($zahl, ".")));

	echo "<tr>";
	if($filter > -1) echo "<td align=\"middle\">&nbsp;".$array["rank"]."&nbsp;</td>";
	
	echo "<td align=\"left\"><a href='player.php?searchkey=".$array["auth"]."'>&nbsp;".$array["name"]."&nbsp;</a></td>";
	
	echo "<td align=\"middle\"><a href='records.php?map=".$array["map"]."&style=-1&track=-1'>".$array["map"]."</a></td>";
	echo "<td align=\"middle\">".$vor_komma." m ".$runseconds_trim.".".$runmillisecs." s</td>";
	if($style == -1 && $multi_styles == 1){
		$istyle = 0;
		while($istyle < $array["style"]){
			$istyle ++;

		}
		echo "<td align=\"left\">&nbsp;".$astylename[$istyle]."&nbsp;</td>";
	}
	if($track == -1){
		$itrack = 0;
		while($atrackid[$itrack] < $array["track"]){
			$itrack ++;
		}
		echo "<td align=\"left\">&nbsp;".$atrackname[$itrack]."&nbsp;</td>";
	}
	echo "</tr>";
	$count ++; 
}
echo "</table></center>";
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