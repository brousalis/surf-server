Timer
=====

[CS:S/CS:GO] Timer for surf, bhop, climb, deathrun, minigame and more

Support: https://forums.alliedmods.net/showthread.php?t=231866

*** HISTORY ***

This timer was private until poppin leaked it, this timer is a heavy modified version of Timer by Alongub (https://github.com/alongubkin/timer),
with many new components and annexed plugins by various authors.

*** INSTALL INSTRUCTIONS ***

Please read descriptions of modules you like to install first, they can contain additional install instructions!

1.) Download plugin here: https://github.com/Zipcore/Timer

2.) Skip this part if you a running a CS:S server, for CS:GO you have to follow step 2 first!

2a) open scripting/incudes/timer.inc with a text editor (like Notepad++)

replace
- //#define LEGACY_COLORS "CS:GO Color Support"

with
- #define LEGACY_COLORS "CS:GO Color Support"

3.) recompile all needed .sp files (some modules have different files for CS:GO)

4.) Insert "timer" keyvalue into configs/databases.cfg (no sqlite support)
PHP Code:
"Databases"
{
	"timer"
	{
		"driver"		"mysql"
		"host"			"123.123.123.123"
		"database"		"db-name"
		"user"			"user-name"
		"pass"			"12345"
		"timeout"		"120"
		"port"			"3306"
	}
} 


5.) Change configs/timer/settings.cfg to your needs

6.) Add new styles to configs/timer/physics.cfg (example for bhop, bhopfun, surf & climb included)

7.) Upload all files to your webserver

8.) Restart your server and have fun creating zones
(It's possible to import your old Timer 1.0.x Zones)

*** UPDATE INSTRUCTIONS ***

Update 2.0.x to 2.1.x:
1.) Make a backup of your mapzone, round and maptier table.
2.) Delete mapzone, round and maptier table
3.) Delte "create table" lines of you backup files (Notepad++)
4.) Import modified backups

*** COMPABILITY CHECKS ***

- Noblock (Included into Mapzone module)
- MultiPlayer Bunny Hops (Included into Physics module)
- Autobhop (Included into Physics module)
- Godmode (Build-in godmode into Physics module, with PvP Arena zone)
- SMAC autotrigger (Included into Scripter-SMAC module)
- Macrodox - Bhop cheat detection (Included into Scripter-Macrodox module)

*** USEFULL CVAR LIST ***

sv_accelerate "10" //Ground control
sv_wateraccelerate "150" //Water control
sv_airaccelerate "150" //Air control
sv_enablebunnyhopping "1" //Disable speed limit
sv_maxvelocity "9999" //Increase max. possible speed
mp_falldamage "0" //Disable fall damage  