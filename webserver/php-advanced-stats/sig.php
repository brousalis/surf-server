<?php
require_once("inc/config.inc.php");
require_once("inc/functions.inc.php");

$astylename = array_keys($styles);
$astyleid = array_values($styles);

$atrackname = array_keys($track_list);
$atrackid = array_values($track_list);

$aranks = array_keys($chat_ranks);
$arank = array_values($chat_ranks);

Header("Cache-Control: no-cache");
Header("Content-Type: image/png");

$width = 500; // Später die Breite des Rechtecks
$height = 90; // Später die Höhe des Rechtecks
//$img = ImageCreate($width, $height); # Hier wird das Bild einer Variable zu gewiesen
$img = @ImageCreateFromPNG ("img/sigbg.png");

$schwarz = ImageColorAllocate($img, 0, 0, 0);
$weiß = ImageColorAllocate($img, 255, 255, 255);
$blau = ImageColorAllocate($img, 70, 150, 255);
$rot = ImageColorAllocate($img, 220, 0, 0);
$gelb = ImageColorAllocate($img, 255, 255, 0);
// Die drei Nullen bestehen aus den RGB-Parametern. 255, 0, 0 wäre z.B. rot. ($img muss am Anfang stehen)

ImageFill($img, 0, 0, $schwarz); # Hier wird mit ImageFill() das Bild gefüllt an den Koordinaten 0 und 0 mit der Variable $schwarz

//Checke SteamID
if (isset($_GET['steamid']))
{
	$steamid = $_GET['steamid'];
	$validkey = '/^STEAM_[01]:[01]:\d+$/';

	if(preg_match($validkey, $steamid)){
		$valid = true;
	}
	else {
		$valid = false;
	}
}

//Verbindung mit Mysql Server
if($valid)
{
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
	if (strlen($name) > 20) $name = substr($name, 0, 17) . '...';

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
	
	$query = $link->query("SELECT COUNT(*) FROM (SELECT * FROM `round` WHERE (`auth` = ".$ex.$steamid.$ex." OR `auth` = ".$ex.$steamfix.$ex.") GROUP BY `map`) AS s");
	$array2 = mysqli_fetch_array($query);
	$count_map_records = $array2[0];
	
	$query = $link->query("SELECT COUNT(*) FROM (SELECT * FROM `round` WHERE (`auth` = ".$ex.$steamid.$ex." OR `auth` = ".$ex.$steamfix.$ex.") AND `track` = 0 GROUP BY `map`) AS s");
	$array2 = mysqli_fetch_array($query);
	$count_normal_records = $array2[0];
	
	$query = $link->query("SELECT COUNT(*) FROM (SELECT * FROM `round` WHERE (`auth` = ".$ex.$steamid.$ex." OR `auth` = ".$ex.$steamfix.$ex.") AND `track` = 1 GROUP BY `map`) AS s");
	$array2 = mysqli_fetch_array($query);
	$count_track_records = $array2[0];
	
	$query = $link->query("SELECT COUNT(*) FROM (SELECT * FROM `round` WHERE (`auth` = ".$ex.$steamid.$ex." OR `auth` = ".$ex.$steamfix.$ex.") AND `track` = 2 GROUP BY `map`) AS s");
	$array2 = mysqli_fetch_array($query);
	$count_short_records = $array2[0];

	$query = $link->query("SELECT COUNT(*) FROM `ranks`");
	$array2 = mysqli_fetch_array($query);
	$total_players = $array2[0];
	
	// $query = $link->query("SELECT `rating` FROM `pvp_elo` WHERE (`auth` = ".$ex.$steamid.$ex." OR `auth` = ".$ex.$steamfix.$ex.")");
	// $array2 = mysqli_fetch_array($query,MYSQLI_BOTH);
	// $elo = $array2[0];
	$elo = 1000;
	
	// $query = $link->query("SELECT `win` FROM `pvp_elo` WHERE (`auth` = ".$ex.$steamid.$ex." OR `auth` = ".$ex.$steamfix.$ex.")");
	// $array2 = mysqli_fetch_array($query,MYSQLI_ASSOC);
	// $wins = $array2[0];
	$wins = 0;
	
	// $query = $link->query("SELECT `lose` FROM `pvp_elo` WHERE (`auth` = ".$ex.$steamid.$ex." OR `auth` = ".$ex.$steamfix.$ex.")");
	// $array2 = mysqli_fetch_array($query,MYSQLI_ASSOC);
	// $lose = $array2[0];
	$lose = 0;
	
	//$complete = round(100*($count_map_records)/($total_maps));
	$complete = round(100*($count_normal_records+$count_track_records+$count_short_records)/($total_maps+$total_trackmaps+$total_shortmaps));
	
	$maxstyles = count($astyleid);
	
	//CHATRANK
	$chatrank = $unranked;
	for ($i = 0; $i < count($arank); $i++) {
		if($arank[$i] >= $rank){
			$chatrank = $aranks[$i];
			break;
		}
	}
	
	// Tabellen für die dynamischen Einträge
	
	ImageString($img, 5, 90, 12, "[".$chatrank."] ".$name."", $blau);
	
	ImageString($img, 3, 90, 40, "Rank: ".$rank."/".$total_players."", $weiß);
	ImageString($img, 3, 200, 40, "Points: ".$points."", $weiß);
	ImageString($img, 3, 90, 70, "Records: ".($count_records+$count_trackrecords+$count_shortrecords)."", $weiß);
	ImageString($img, 3, 90, 55, "WRs: ".$worldrecords."", $weiß);
	ImageString($img, 3, 200, 55, "Top10: ".$toprecords."", $weiß);
	ImageString($img, 3, 200, 70, "Complete: ".$complete."%", $weiß);
	
	ImageString($img, 3, 365, 65, "144.76.58.114:28015", $weiß);
	
	ImageString($img, 3, 365, 11, "PvP-Stats", $weiß);
	ImageString($img, 3, 365, 26, "Rating: ".$elo."", $weiß);
	ImageString($img, 3, 460, 11, "W: ".$wins."", $weiß);
	ImageString($img, 3, 460, 26, "L: ".$lose."", $weiß);
}

// Hier wird der Header gesendet, der später die Bilder "rendert" ausser png kann auch jpeg dastehen
// Legende:
# Die erste Zahl steht für die Schrifthöhe (geht nur bis zur 5).
# Die zweite Zahl bzw. 250 steht für die Position von Links.
# Die dritte Zahl steht für die Postion von Oben.
# Der Text, ist der, der später im Bild erscheinen soll.


ImagePNG($img);                    # Hier wird das Bild PNG zugewiesen
ImageDestroy($img);                # Hier wird der Speicherplatz für andere Sachen geereinigt
?> 