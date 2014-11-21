<?php
// START SETTINGS

// MAIN SETTINGS
$path_stats = "http://www.test.com/stats";
$path_home = "http://www.test.com";

// GAMESERVER SETTINGS
$name = "MyCommunityName";			// Clan/Community Name
$gameserverip = "123.123.123.123"; 	// Game-server IP
$serverport = "27015"; 				// Game-server Port

// MY-SQL SETTINGS
$serverip	= "127.0.0.1"; 			// DB host-name
$dbusername	= "DB_USER";			// DB user-name
$dbpassword	= "BS_PASS";			// DB password
$dbname		= "DB_NAME";			// DB name

//GAME
$game = "csgo";						//Gametype css or csgo

// MENU
$menu_enable = "1";					// Enable menu-bar
$home_button = "1";					// Show "Home" button at main menu
$join_button = "1";					// Show "Join Server" button at main menu

// GENERAL SETTINGS
$limit_view = "25";					// How much users are listed (per page)
$limit_topmaps = "10";				// How much top maps should be listed
$limit_latest = "50";				// How much top latest records should be listed
$points_min = "0";					// Minimum points to list

// GEO RANKING
$geo_enable = "1";					// Enable geo ranking
$points_geo_min = "1"; 				// Minimum points to list (geo ranking)

//BARS
$max_width = 200;
$px_via_percent = ($max_width - 17) / 100;

$c_1 = 10;
$c_2 = 20;
$c_3 = 35;
$c_4 = 50;
$c_5 = 75;
$c_6 = 90;

// FILTER
$filter_world = "WORLD RECORD";
$filter_top = "TOP RECORD";
$filter_any = "ANY RECORD";

// track
$track_list = 
array
(
	"ALL" => "-1",
	"Normal" => "0",
	"track" => "1",
	"Short" => "2"
);

// STYLES
$multi_styles = "1"; 				// Enable style selection
$any_style_name = "ALL"; 			// Name for any style filter

$styles = 
array
(
    "Auto" => "0",
    "Normal" => "1",
    "Sideways" => "2",
    "W-Only" => "3",
    "Backwards" => "4",
    "OnlyA" => "5",
    "OnlyD" => "6",
    "asdasd" => "7"
);

//SKILLRANK

$styles_multi = 
array
(
    0 => "1.0",
    1 => "2.0",
    2 => "1.5",
    3 => "1.5",
    4 => "1.5",
    5 => "2.1",
    6 => "2.1",
    7 => "2.2"
);

$tierpoints = 
array
(
	1 => "100",
	2 => "175",
	3 => "250",
	4 => "325",
	5 => "400",
	6 => "475",
	7 => "550",
	8 => "625",
	9 => "700",
	10 => "775"
);

// CHAT RANKS
$unranked = "Unranked";

$chat_ranks = 
array
(
    "The One" => "1",
    "Pr0" => "10",
    "Good" => "100",
    "Noob" => "1000"
);

// END SETTINGS
?>