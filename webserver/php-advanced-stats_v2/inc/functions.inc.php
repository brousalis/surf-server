<?php
	include "config.inc.php";
	
	$link = mysqli_connect($serverip, $dbusername, $dbpassword, $dbname) or die("Couldn't make connection.");
	mysqli_set_charset($link, "utf8");

	function steam2friend($steam_id)
	{
		$steam_id=strtolower($steam_id);
		if (substr($steam_id,0,7)=='steam_0')
		{
			$tmp=explode(':',$steam_id);
			if ((count($tmp)==3) && is_numeric($tmp[1]) && is_numeric($tmp[2]))
				return bcadd((($tmp[2]*2)+$tmp[1]),'76561197960265728');
			else return false;
		}
		else return false;
	} 
	
	function unitFormat($number, $decimals = 2)
	{
		if($number > 85000000000) {$unit = 'T'; $div = 4;}
		else if($number > 85000000) {$unit = 'G'; $div = 3;}
		else if($number > 85000) {$unit = 'M'; $div = 2;}
		else if($number > 850) {$unit = 'k'; $div = 1;}
		else return floor($number);

		$value = ($number/pow(1000,floor($div)));

		// If decimals is not numeric or decimals is less than 0 
		// then set default value
		if (!is_numeric($decimals) || $decimals < 0) 
			$decimals = 2;

		// Format output
		return sprintf('%.' . $decimals . 'f'.$unit, $value);
	}
	
	function timeFormat($time)
	{
		$runmillisecs = $time * 100 % 100;
		$runseconds = $time / 1;
		$runseconds_trim = $runseconds % 60;
		$runminutes = $time / 60;
		$zahl=$runminutes;
		$vor_komma=substr($zahl, 0, (strpos($zahl, ".")));
		
		if($vor_komma > 0) $final = "".$vor_komma." m ".$runseconds_trim.".".$runmillisecs." s";
		else  $final = "".$runseconds_trim.".".$runmillisecs." s";
		
		return $final;
	}
	
	function getKeyByArrayValue($id, $array)
	{
		$keys = array_keys($array);
		$values = array_values($array);
		
		$key = "unknown";
		
		for ($i = 0; $i < count($keys); $i++) {
			if($values[$i] == $id){
				$key = $keys[$i];
				break;
			}
		}
		
		return $key;
	}
	
	function getChatRank($rank, $chatranks)
	{
		$keys = array_keys($chatranks);
		$values = array_values($chatranks);
		
		$key = "unknown";
		
		for ($i = 0; $i < count($keys); $i++) {
			if($values[$i] >= $rank){
				$key = $keys[$i];
				break;
			}
		}
		
		return $key;
	}
	
	function getPartial($site){
        $invalide = array('\\','/','/\/',':','.');
        $site = str_replace($invalide,' ',$site);
        if(file_exists("inc/partials/".$site.".php")){

        	include("inc/partials/".$site.".php");
        } 
	}
?>