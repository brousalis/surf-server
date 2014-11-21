<?php
/*
 *      Copyright 2010 Rob McFadzean <rob.mcfadzean@gmail.com>
 *      
 *      Permission is hereby granted, free of charge, to any person obtaining a copy
 *      of this software and associated documentation files (the "Software"), to deal
 *      in the Software without restriction, including without limitation the rights
 *      to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *      copies of the Software, and to permit persons to whom the Software is
 *      furnished to do so, subject to the following conditions:
 *      
 *      The above copyright notice and this permission notice shall be included in
 *      all copies or substantial portions of the Software.
 *      
 *      THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *      IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *      FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *      AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *      LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *      OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 *      THE SOFTWARE.
 *      
 */

class SteamAPIException extends Exception { }
class SteamAPI {
	
	private $customURL;
	private $steamID64;
	private $gameList;
	
	function version() {
		return (float) '0.1';
	}
	
	/**
	 *  Sets the $steamID64 or CustomURL then retrieves the profile.
	 * @param int $id
	 * */
	function __construct($id) {
		if(is_numeric($id)) {
			$this->steamID64 = $id;
		} else {
			$this->customURL = strtolower($id);
		}
		
		$this->retrieveProfile();
	}

	/**
	 *  Creates and then returns the url to the profiles.
	 *  @return string
	 * */
	function baseUrl() {
		if(empty($this->customURL)) {
			return "http://steamcommunity.com/profiles/{$this->steamID64}";
		}
		else {
			return "http://steamcommunity.com/id/{$this->customURL}";
		}
	}
	
	/**
	 *  Retrieves all of the games owned by the user
	 * */
	function retrieveGames() {
		$url = $this->baseUrl() . "/games?xml=1";
		$gameData = new SimpleXMLElement(file_get_contents($url));
		$this->gamesList = array();
		if(!empty($gameData->error)) {
			#throw new SteamAPIException((string) $gameData->error);
		}
		
		foreach($gameData->games->game as $game) {
			$g['appID'] = (string) $game->appID;
			$g['name']  = (string) $game->name;
			$g['logo'] = (string) $game->logo;
			$g['storeLink'] = (string) $game->storeLink;
			$g['hoursOnRecord'] = (float) $game->hoursOnRecord;
			$g['hoursLast2Weeks'] = (float) $game->hoursLast2Weeks;
			$this->gameList[] = $g;
			#print_r($this->gameList);
		}
	}

	/**
	 *  Retrieves all of the information found on the profile.
	 * */
	function retrieveProfile() {
		$url = $this->baseUrl() . "/?xml=1";
		$profileData = new SimpleXMLElement(file_get_contents($url));
		
		if(!empty($profileData->error)) {
			#throw new SteamAPIException((string) $profileData->error);
		}
		
		$this->steamID64= (string) $profileData->steamID64;
		$this->friendlyName  = (string) $profileData->steamID;
	
		$this->onlineState = (string) $profileData->onlineState;
		$this->stateMessage = (string) $profileData->stateMessage;
		
		$this->privacyState = (string) $profileData->privacyState;
		$this->visibilityState = (int) $profileData->visibilityState;
		
		$this->avatarIcon = (string) $profileData->avatarIcon;
		$this->avatarMedium = (string) $profileData->avatarMedium;
		$this->avatarFull = (string) $profileData->avatarFull;
		
		$this->vacBanned = (bool) $profileData->vacBanned;
	

		if($this->privacyState == "public") {
			$this->customUrl = strtolower((string) $profileData->customURL);
			
			$this->memberSince = (string) $profileData->memberSince;
			$this->steamRating = (float) $profileData->steamRating;
			$this->location = (string) $profileData->location;
			$this->realName = (string) $profileData->realname;
			
			$this->hoursPlayed2Wk = (float) $profileData->hoursPlayed2Wk;
			
			$this->favoriteGame = (string) $profileData->favoriteGame->name;
			$this->favoriteGameHoursPlayed2Wk = (string) $profileData->favoriteGame->hoursPlayed2wk;
			
			$this->headLine = (string) $profileData->headline;
			$this->summary = (string) $profileData->summary;
		}
		
		if(!empty($profileData->weblinks)) {
            foreach($profileData->weblinks->weblink as $link) {
                $this->weblinks[(string) $link->title] = (string) $link->link;
            }
        }
	}
	
	/**
	 *  If there are no games in the variable it calls the retrieveGames() function, upon completion returns an array of all of the owned games and related information
	 *  @return array
	 * */
	function getGames() {
		if(empty($this->gameList)) {
			$this->retrieveGames();
		}
		return $this->gameList;
	}
	
	/**
	 *  Returns the friendly name of the user. The one seen by all friends & visitors.
	 *  @return string
	 * */
	function getFriendlyName() {
		return $this->friendlyName;
	}
	
	/**
	 *  Returns the users current state. (online,offline)
	 *  @return string
	 * */
	function onlineState() {
        return $this->onlineState;
    }
    
    /**
	 *  Returns the state message of the user (EG: "Last Online: 2 hrs, 24 mins ago", "In Game <br /> Team Fortress 2")
	 *  @return string
	 * */
    function getStateMessage() {
		return $this->stateMessage;
	}
    
    /**
	 *  Returns the users Vac status. 0 = Clear, 1 = Banned
	 *  @return boolean
	 * */
    function isBanned() {
        return $this->vacBanned;
    }
    
    /**
	 *  Returns a link to the small sized avatar of the user (32x32)
	 *  @return string
	 * */
    function getAvatarSmall() {
		return $this->avatarIcon;
	}
	
	/**
	 *  Returns a link to the medium sized avatar of the user (64x64)
	 *  @return string
	 * */
	function getAvatarMedium() {
		return $this->avatarMedium;
	}
	
	/**
	 *  Returns a link to the full sized avatar of the user
	 *  @return string
	 * */
	function getAvatarFull() {
		return $this->avatarLarge;
	}
	
	/**
	 *  Returns the Steam ID of the user
	 *  @return int
	 * */
	function getSteamID64() {
		return $this->steamID64;
	}
	
	/**
	 *  Returns the total amount of games owned by the user
	 *  @return int
	 * */
	function getTotalGames() {
		return sizeof($this->gameList);
	}
}

?>
