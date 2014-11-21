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


echo "<div class='serverinfo'>";

echo "<center>";
echo "Chatranks: <b>".count($aranks)."</b>";
echo "</center>";

echo "</div>"; //serverinfo

echo "<div class='list'>";
echo "<center><h1>Chat Ranks</h1>";
echo "<table cellpadding=\"3\" cellspacing=\"0\" border=\"1\">";

echo "<tr>";
echo "<th>Ranks</th>";
echo "<th>Chatrank</th>";
echo "</tr>";

$lastrank = 1;
for ($i = 0; $i < count($arank); $i++) 
{
	if($arank[$i] - $lastrank > 1){
		$range = "".($arank[$i-1]+1)."-".$arank[$i]."";
	}
	else{
		$range = "".$arank[$i]."";
	}
	$lastrank = $arank[$i];
	
	echo "<tr>";
	echo "<td align=\"middle\">".$range."</td>";
	echo "<td align=\"middle\">".$aranks[$i]."</td>";
	echo "</tr>";
}

echo "<tr>";
echo "<td align=\"middle\">+</td>";
echo "<td align=\"middle\">".$unranked."</td>";
echo "</tr>";

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