<?php
	include "config.inc.php";
	
	$link = mysqli_connect($serverip, $dbusername, $dbpassword, $dbname) or die("Couldn't make connection.");
	
	mysqli_set_charset($link, "utf8");

	function steam2friend($steam_id)
	{
		$steam_id=strtolower($steam_id);
		if(substr($steam_id,0,7)=='steam_0'){
			$tmp=explode(':',$steam_id);
			if((count($tmp)==3) && is_numeric($tmp[1]) && is_numeric($tmp[2])){
				return bcadd((($tmp[2]*2)+$tmp[1]),'76561197960265728');
			} else {
				return false;
			}
		} else {
			return false;
		}
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
		{
			$decimals = 2;
		}

		// Format output
		return sprintf('%.' . $decimals . 'f'.$unit, $value);
	}
?>