<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
<head>
<title>Timer Stats by Zipcore</title>
<meta http-equiv="Content-Type" content="text/html;charset=UTF-8">
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

$valid = false;
if (isset($_POST['player_selected']))
{
	$searchkey = $_POST['player_selected'];
	$validkey = '/^STEAM_[01]:[01]:\d+$/';

	if(preg_match($validkey, $searchkey)){
		$valid = true;
	}
	else {
		$valid = false;
	}
}
else if (isset($_GET['player_selected']))
{
	$searchkey = $_GET['player_selected'];
	$validkey = '/^STEAM_[01]:[01]:\d+$/';

	if(preg_match($validkey, $searchkey)){
		$valid = true;
	}
	else {
		$valid = false;
	}
}
else if (isset($_POST['searchkey']))
{
	$searchkey = $_GET['searchkey'];
	$validkey = '/^STEAM_[01]:[01]:\d+$/';

	if(preg_match($validkey, $searchkey)){
		$valid = true;
	}
	else {
		$valid = false;
	}
}
else if (isset($_GET['searchkey']))
{
	$searchkey = $_GET['searchkey'];
	$validkey = '/^STEAM_[01]:[01]:\d+$/';

	if(preg_match($validkey, $searchkey)){
		$valid = true;
	}
	else {
		$valid = false;
	}
}
else{
	$searchkey = "SteamID or Name";
	$valid = false;
}

$searchkey = $link->real_escape_string($searchkey);

echo "<div class='serverinfo'>";

echo "<center>";
echo "<form>";
if($valid === false){
	//LIST PLAYERS
	
	if(mb_strlen($searchkey) < 3 && $searchkey != "SteamID or Name"){
		$short = true;
		echo "<b>Min 3 letters</b><br>";
	}
	
	$searchcount = 0;
	if($valid === false && $searchkey != "SteamID or Name" && !isset($short))
	{
		$sql = "SELECT `auth`, `name` FROM `round` WHERE `name` LIKE '%%".$searchkey."%%' GROUP BY `auth`";
		$rekorde = $link->query($sql);
		
		while($array = mysqli_fetch_array($rekorde))
		{
			$searchcount ++;
			if($searchcount == 1)
			{
				echo "<center><select style=\"background-color:transparent; color:#FFF\" name=\"player_selected\"></center>";
			}
			echo "<option value='".$array["auth"]."'>".$array["name"]."</option>";
		}
		
		if($searchcount > 0) echo "</select></center>";
	}
	
	if($searchkey != "SteamID or Name"){
	
		if($searchcount == 0 && $searchkey != "SteamID or Name" && !isset($short)) echo "<b>No player(s) found...</b><br>";
		else if(!isset($short)) echo "<b>".$searchcount." player(s) found</b><br>";
	}

	//SEARCH
	if($searchcount == 0) echo "<input type='text' name='searchkey' value='".$searchkey."'>";
	echo "<br>";

	if($searchcount == 0) echo "<input type='submit' name='submit' value='Search'>";
	else  echo "<input type='submit' name='submit' value='Select Player'>";
}
echo "</form>";
echo "</center>";
echo "</div>";

if($valid){
	echo "<div class='detail'><center>";
	
	$steamid = $searchkey;
	
	$steam64 = (int) steam2friend($steamid);
	$ex = '"';
	
	$steamfix = $steamid;
	if($steamid[6] == '0'){
		$steamfix[6] = '1';
	}
	else{
		$steamfix[6] = '0';
	}

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
	$count_trackrecords = $array2[0];
	
	$query = $link->query("SELECT COUNT(*) FROM `round` WHERE `track` = 2 AND (`auth` = ".$ex.$steamid.$ex." OR `auth` = ".$ex.$steamfix.$ex.")");
	$array2 = mysqli_fetch_array($query);
	$count_shortrecords = $array2[0];

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
	$total_trackmaps = $array2[0];

	$query = $link->query("SELECT COUNT(*) FROM `mapzone` WHERE `type` = 27");
	$array2 = mysqli_fetch_array($query);
	$total_shortmaps = $array2[0];
	
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
	
	$query = $link->query("SELECT COUNT(*) FROM (SELECT * FROM `round` WHERE (`auth` = ".$ex.$steamid.$ex." OR `auth` = ".$ex.$steamfix.$ex.") AND `track` = 0 GROUP BY `map`) AS s");
	$array2 = mysqli_fetch_array($query);
	$count_normal_records = $array2[0];
	
	$query = $link->query("SELECT COUNT(*) FROM (SELECT * FROM `round` WHERE (`auth` = ".$ex.$steamid.$ex." OR `auth` = ".$ex.$steamfix.$ex.") AND `track` = 1 GROUP BY `map`) AS s");
	$array2 = mysqli_fetch_array($query);
	$count_track_records = $array2[0];
	
	$query = $link->query("SELECT COUNT(*) FROM (SELECT * FROM `round` WHERE (`auth` = ".$ex.$steamid.$ex." OR `auth` = ".$ex.$steamfix.$ex.") AND `track` = 2 GROUP BY `map`) AS s");
	$array2 = mysqli_fetch_array($query);
	$count_short_records = $array2[0];
	
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
	
	$maxstyles = count($astyleid);
	
	//CHATRANK
	$chatrank = $unranked;
	for ($i = 0; $i < count($arank); $i++) {
		if($arank[$i] >= $rank){
			$chatrank = $aranks[$i];
			break;
		}
	}
	
	echo "<font size='3'>".$chatrank."</font> <font size='5'><b>".$name."</b></font><br>";
	echo "<a href='http://steamcommunity.com/profiles/".$steam64."'><img src='img/steam.png'></a> ";
	echo "<a href='sig.php?steamid=".$steamid."'><img src='img/sig.png'></a>";
	echo "<br>";
	echo "Points: <b>".$points."</b> (#<b>".$rank."</b>)";
	echo "<br><br>";
	
	//Depletion
	$complete = round(100*($count_normal_records+$count_track_records+$count_short_records)/($total_maps+$total_trackmaps+$total_shortmaps), 2);
	
	if ($c_1 >= $complete) $color = '1';
	if (($c_1 < $complete) and ( $c_2 >= $complete)) $color = '2';
	if (($c_2 < $complete) and ( $c_3 >= $complete)) $color = '3';
	if (($c_3 < $complete) and ( $c_4 >= $complete)) $color = '4';
	if (($c_4 < $complete) and ( $c_5 >= $complete)) $color = '5';
	if (($c_5 < $complete) and ( $c_6 >= $complete)) $color = '6';
	if ($c_6 < $complete) $color = '7';
	
	$barwitch = $px_via_percent * $complete;
	
	echo "Depletion: <img src='img/bars/".$color."_butom.gif' width='5' height='17'><img src='img/bars/".$color."_mid.gif' width='".$barwitch."' height='17'><img src='img/bars/".$color."_top.gif' width='6' height='17'>".$complete."%</td>";
	
	
	echo "<br><br>";
	if($worldrecords > 0){
		echo ">>><b>World Records: ".$worldrecords."</b><<<";
		echo "<br><br>";
	}
	if($toprecords > 0){
		echo "Top10 Records: <b>".$toprecords."</b>";
		echo "<br>";
	}
	echo "Records: <b>".$records."</b>";
	echo "<br><br>";
	
	echo "<h1>PvP-Stats</h1>";
	echo "Rating: <b>".$elo."</b> ";
	echo "Wins: <b>".$wins."</b> ";
	echo "Lose: <b>".$lose."</b>";
	echo "<br><br>";
	
	if($multi_styles == 1)
	{
		echo "<center><h1>Complete</h1>";
		echo "<table cellpadding=3 cellspacing=0 border=0>";
		//All-Styles
		$complete = round(100*($count_records+$count_trackrecords +$count_shortrecords)/(($total_maps+$total_trackmaps+$total_shortmaps)*$maxstyles), 2);
		
		if ($c_1 >= $complete) $color = '1';
		if (($c_1 < $complete) and ( $c_2 >= $complete)) $color = '2';
		if (($c_2 < $complete) and ( $c_3 >= $complete)) $color = '3';
		if (($c_3 < $complete) and ( $c_4 >= $complete)) $color = '4';
		if (($c_4 < $complete) and ( $c_5 >= $complete)) $color = '5';
		if (($c_5 < $complete) and ( $c_6 >= $complete)) $color = '6';
		if ($c_6 < $complete) $color = '7';
		
		$barwitch = $px_via_percent * $complete;
		
		echo "<tr>";
		echo "<td align=middle><b>All-Styles</b></td>";
		
		echo "<td align=left><img src='img/bars/".$color."_butom.gif' width='5' height='17'><img src='img/bars/".$color."_mid.gif' width='".$barwitch."' height='17'><img src='img/bars/".$color."_top.gif' width='6' height='17'>".$complete."%</td>";
		echo "</tr>";

		for ($i = 0; $i < count($astyleid); $i++) 
		{
			//GetFinishd Maps Count
			$query = $link->query("SELECT COUNT(*) FROM `round` WHERE (`auth` = ".$ex.$steamid.$ex." OR `auth` = ".$ex.$steamfix.$ex.") AND `style` = ".$astyleid[$i]."");
			$array2 = mysqli_fetch_array($query);
			$count_records_current_style = $array2[0];
			
			$complete = round(100*$count_records_current_style/($total_maps+$total_trackmaps+$total_shortmaps), 2);
		
			if ($c_1 >= $complete) $color = '1';
			if (($c_1 < $complete) and ( $c_2 >= $complete)) $color = '2';
			if (($c_2 < $complete) and ( $c_3 >= $complete)) $color = '3';
			if (($c_3 < $complete) and ( $c_4 >= $complete)) $color = '4';
			if (($c_4 < $complete) and ( $c_5 >= $complete)) $color = '5';
			if (($c_5 < $complete) and ( $c_6 >= $complete)) $color = '6';
			if ($c_6 < $complete) $color = '7';
			
			$barwitch = $px_via_percent * $complete;
		
			echo "<tr>";
			echo "<td align=middle>".$astylename[$i]."</td>";
			echo "<td align=left><img src='img/bars/".$color."_butom.gif' width='5' height='17'><img src='img/bars/".$color."_mid.gif' width='".$barwitch."' height='17'><img src='img/bars/".$color."_top.gif' width='6' height='17'>".$complete."%</td>";
			
			echo "</tr>";
		}
		
		echo "</table>";
		echo "</center>";
	}
	
	echo "</div>";
	
	//MAP INFO
	echo "<div class='list'>";
	echo "<center><h1>Player Records</h1><br>";
	echo "<table cellpadding=\"3\" cellspacing=\"0\" border=\"1\">";
	echo "<tr>";
	echo "<th>Map</th>";
	echo "<th>Rank</th>";
	echo "<th>Time</th>";
	if($multi_styles == 1) echo "<th>Style</th>";
	echo "<th>Area</th>";
	echo "<th>Points</th>";
	echo "</tr>";
	
	//$records
	
	$sql = "SELECT `map`, `time`, `track`, `rank`, `style` FROM `round` WHERE (`auth` = ".$ex.$steamid.$ex." OR `auth` = ".$ex.$steamfix.$ex.") ORDER BY `map`, `track`, `style`;";
	$rekorde = $link->query($sql);
	
	$rcount = 0;
	$lastmap = "";
	$firstmap = true;
	
	while($array = mysqli_fetch_array($rekorde))
	{
		$spacer = false;
	
		//MAPTIER
		$query = $link->query("SELECT `tier` FROM `maptier` WHERE `track` = '".$array["track"]."' AND `map` = '".$array["map"]."'");
		$array2 = mysqli_fetch_array($query);
		$maptier = $array2[0];
		
		//FORMAT RUNTIME
		$time = $array["time"];
		$runmillisecs = $time * 100 % 100;
		$runseconds = $time / 1;
		$runseconds_trim = $runseconds % 60;
		$runminutes = $time / 60;
		$zahl=$runminutes;
		$vor_komma=substr($zahl, 0, (strpos($zahl, ".")));
		
		echo "<tr>";
		
		if($vor_komma > 0) $stime = "".$vor_komma." m ".$runseconds_trim.".".$runmillisecs." s";
		else  $stime = "".$runseconds_trim.".".$runmillisecs." s";
		
		if($array["map"] != $lastmap && $rcount > 0){ 
			$newmap = true;
		}
		else{
			$newmap = false;
		}
		
		//FILL TABLE
		if($newmap || $firstmap){
			$firstmap = false;
			$newmap = false;
			$spacer = true;
			
			echo "<tr><td align=middle><a href='records.php?map=".$array["map"]."&style=-1&track=-1'>".$array["map"]."</a></td>";
		}
		else{
			echo "<td align=left style='border-top: solid transparent; border-bottom: solid transparent; border-left: solid transparent; border-right: solid transparent;'></td>";
		}
		
		//Rank
		echo "<td align=middle>";
		echo "".$array["rank"]."</td>";
		
		//Time
		echo "<td align=middle>";
		echo "".$stime."</td>";
		
		//Style
		if($multi_styles == 1)
		{
			$istyle = 0;

			
			while($astyleid[$istyle] < $array["style"]){
				$istyle ++;
			}
			echo "<td align=middle>";
			
			echo "&nbsp;".$astylename[$istyle]."&nbsp;</td>";
		}
		
		$itrack = 0;
		while($atrackid[$itrack] < $array["track"]){
			$itrack ++;
		}
		
		echo "<td align=middle>";
		echo "&nbsp;".$atrackname[$itrack]."&nbsp;</td>";
		
		if($array["track"] == 2)
		{
			$maptier = 1;
		}
		
		$points = round($tierpoints[$maptier]/300/($array["rank"]+25)*$styles_multi[$array["style"]]*10000+$tierpoints[$maptier]);
		
		echo "<td align=middle>";
		echo "".$points."</td>";

		//TABLE ROW END
		echo "</tr>";
		
		$lastmap = $array["map"];
		$rcount++;
	}

	echo "</table>";
	
	//INCOMPLETE MAPS
	
	$amaps = array();
	$atrack_maps = array();
	
	$sql = "SELECT `map`,`type` FROM `mapzone` WHERE `type` = 0 OR `type` = 7;";
	$result = $link->query($sql);
	
	while($array = mysqli_fetch_array($result)){
	
		if($array["type"] == 0){
			array_push($amaps,$array["map"]);
		}
		else if($array["type"] == 7){
			array_push($atrack_maps,$array["map"]);
		}
	}
	
	$sql = "SELECT `map`,`track` FROM `round` WHERE (`auth` = ".$ex.$steamid.$ex." OR `auth` = ".$ex.$steamfix.$ex.") GROUP BY `map`, `track`;";
	$result = $link->query($sql);
	
	$amaps_finished = array();
	$atrack_maps_finished = array();
	
	while($array = mysqli_fetch_array($result)){
		if($array["track"] == 0){
			array_push($amaps_finished,$array["map"]);
		}
		else if($array["track"] == 1){
			array_push($atrack_maps_finished,$array["map"]);
		}
	}
	
	echo "<div class='list'>";
	echo "<center><h1>Incomplete Maps</h1><br>";
	
	echo round(100*(count($amaps)-count($amaps_finished))/count($amaps), 2)." %<br><br>";
	
	echo "<table cellpadding=\"3\" cellspacing=\"0\" border=\"1\">";
	
	for($i = 0; $i<count($amaps); $i++)
	{
		if(in_array($amaps[$i], $amaps_finished) == false){
			echo "<tr><td align=middle><a href='records.php?map=".$amaps[$i]."&style=-1&track=-1'>".$amaps[$i]."</a></td>";
		}
	}
	
	echo "</table>";
	echo "</center>";
	echo "</div>";
	
	echo "<div class='list'>";
	echo "<center><h1>Incomplete trackMaps</h1><br>";
	
	echo round(100*(count($atrack_maps)-count($atrack_maps_finished))/count($atrack_maps), 2)." %<br><br>";
	
	echo "<table cellpadding=\"3\" cellspacing=\"0\" border=\"1\">";
	
	for($i = 0; $i<count($atrack_maps); $i++)
	{
		if(in_array($atrack_maps[$i], $atrack_maps_finished) == false){
			echo "<tr><td align=middle><a href='records.php?map=".$atrack_maps[$i]."&style=-1&track=-1'>".$atrack_maps[$i]."</a></td>";
		}
	}
	
	echo "</table>";
	echo "</center>";
	echo "</div>";
}

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