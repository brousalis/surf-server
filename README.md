### Structure:
1. General Info
2. History
3. INSTALL INSTRUCTIONS
4. Update Instructions (2.0.x to 2.1.x)
5. Compability Info
6. List of Main Modules
7. List of Recommend Modules
8. List of Recommend Bhop Modules
9. List of Recommend Surf Modules
10. List of Recommend Climb Modules
11. List of Recommend Minigames Modules
12. List of Other Modules Modules
13. Usefull CVAR list

### 1) General Info

	[CS:S/CS:GO] Timer for surf, bhop, climb, deathrun, minigame and more...
	Support: https://forums.alliedmods.net/showthread.php?t=231866

### 2) History

	This timer was private until poppin leaked it, this timer is a heavy modified version of Timer by Alongub (https://github.com/alongubkin/timer),
	with many new components and annexed plugins by various authors.

### 3) INSTALL INSTRUCTIONS

	##1.) Download the plugin at https://github.com/Zipcore/Timer
	
	##2.) CS:GO color support: 
		Continue with 3.) and skip this part if you are running a CS:S server. 
		For CS:GO you have to follow step 2 first!
		
		2.1) Open scripting/include/timer.inc with a text editor (like Notepad++)
		2.2) Find the following line - //#define LEGACY_COLORS "CS:GO Color Support"
		2.3) Remove // in front of #define and close it

	##3.) Compiling
		3.1) Download the latest Sourcemod & Metamod Snapshots (Stable Branch): http://www.sourcemod.net/snapshots.php & http://www.sourcemm.net/snapshots
		3.2) Goto addons/sourcemod/scripting/include and fill it with all files this timer provides from same folder.
		3.3) Drag and drop needed SP files onto spcomp.exe inside addons/sourcemod/scripting to compile them it should create all needed SMX files.
		
	##4.) Upload all SMX files, configs, sounds and materials onto your server.
	
	##5.) Insert "timer" keyvalue into configs/databases.cfg (no sqlite support).
		5.1) When using the timer-cpmod module, insert a "cpmod" keyvalue into configs/databases.cfg
		5.2) When using the timer-ranking_toponly module, insert a "timer_toponly" keyvalue into configs/databases.cfg
	
	##6.) Change configs/timer/settings.cfg to your needs
	
	##7.) Change configs/timer/physics.cfg to your needs (the folder contains some example files for bhop, surf, etc.)
	
	##7.) Skip this part if you don't like to run Chatranks/Points ranking/Skillrank
		Depending on if you run a CS:GO or CS:S server, rename csgo-rankings.cfg/css-rankings.cfg to rankings.cfg (addons/sourcemod/configs/timer) to enable the ranking module.
		6.1) Compile simple-chatprocessor.sp  and upload it to your server to enable chatranks.
	
	##8.) Restart your server.
	
	##9.) Start creating zones or use included mappacks inside addons/sourcemod/gamedata/MySQL

### 4) Update Instructions (2.0.x to 2.1.x

	Update 2.0.x to 2.1.x:
	1.) Make a backup of your mapzone, round and maptier table.
	2.) Delete mapzone, round and maptier table.
	3.) Delete "create table" lines of you backup files (Notepad++).
	4.) Import modified backups.

### 5) Compability Info

	- Noblock (Included into Mapzone module)
	- MultiPlayer Bunny Hops (Included into Physics module)
	- Autobhop (Included into Physics module)
	- Godmode (Build-in godmode into Physics module, with PvP Arena zone)
	- SMAC autotrigger (Included into Scripter-SMAC module)
	- Macrodox - Bhop cheat detection (Included into Scripter-Macrodox module)

### 6) List of Main Modules
	Timer-Core [LINK](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-core.txt)
	Timer-Logging [LINK](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-logging.txt)
	Timer-Physics [LINK](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-physics.txt)
	Timer-Mapzones [LINK](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-mapzones.txt)
	Timer-Maptier [LINK](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-maptier.txt)
	Timer-Teams [LINK](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-teams.txt)
	Timer-Worldrecord [LINK](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-worldrecord.txt)
    
### 7) List of Recommend Modules

	Timer-Autospawn [LINK](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-autospawn.txt)
	Timer-HUD [LINK](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-hud.txt)
	Timer-Rankings [LINK](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-rankings.txt)
	Timer-Rankings Points Lite [LINK](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-rankings_points_lite.txt)
	Timer-Physics Quick Cmds [LINK](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-physics_quickcmds.txt)
	Timer-Finish Message [LINK](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-finish_msg.txt)
	Timer-TeleMe [LINK](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-teleme.txt)
	Timer-Hide(Players) [LINK](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-hide.txt)
	Timer-Hide CMDs [LINK](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-hidecmds.txt)
	Timer-Mapinfo [LINK](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-mapinfo.txt)
	Timer-Maplist helper (CS:Source only) [LINK](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-maplist-helper.txt)
	Timer-Mapzones Simple Stage Timer [LINK](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-mapzones_simple_stage_timer.txt)
	Timer-Mapzones Damage Controller [LINK](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-mapzones_damage_controller.txt)
	Timer-Menu [LINK](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-menu.txt)
	Timer-Random Startmap [LINK](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-random_startmap.txt
	Timer-Spec [LINK](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-spec.txt)
	Timer-Worldrecord Lastest [LINK](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-worldrecord_latest.txt)
	Timer-Worldrecord Maptop [LINK](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-worldrecord_maptop.txt)
	Timer-Worldrecord Playerinfo [LINK](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-worldrecord_playerinfo.txt)
	Timer-Unlimited Spawnpoints [LINK](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-unlimited-spawnpoints.txt)
	
### 8) List of Recommend Bhop Modules
	
	Timer-LJ Stats (Long Jump Stats) [LINK](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-ljstats.txt)
	Timer-Strafes (count strafes) [LINK](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-strafes.txt)
	Timer-Weapons (CS:Source only) [LINK](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-weapons.txt)
	
### 9) List of Recommend Surf Modules
	
	Timer-NoJail [LINK](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-nojail.txt)
	
### 10) List of Recommend Climb Modules
	
	Timer-CP Mod (Checkpoints) [LINK](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-cpmod.txt)
	
### 11) List of Recommend Minigames Modules
	
	Timer-Finish Manager [LINK](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-finish_manager.txt)
	
### 12) List of Other Modules
	
	Timer-Finish Exec [LINK](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-finish_exec.txt)
	Timer-Physics Autostrafe [LINK](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-physics_autostrafe.txt)
	Timer-Physics FPS Max [LINK](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-physics_fpsmax.txt)
	Timer-Physics Info [LINK](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-physics_info.txt)
	Timer-Physics Quake Bhop [LINK](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-physics_quakehop.txt)
	Timer-Physics Strafe Booster [LINK](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-physics_strafebooster.txt)
	Timer-Rankings Georank [LINK](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-rankings_georank.txt)
	Timer-Rankings Top Extend [LINK](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-rankings_top_extend.txt)
	Timer-Rankings Top Only [LINK](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-rankings_toponly.txt)
	Timer-Replay (Not supported) [LINK](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-replay.txt)
	Timer-Scripter DB [LINK](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-scripter_db.txt)
	Timer-Scripter Macrodox [LINK](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-scripter_macrodox.txt)
	Timer-Scripter SMAC [LINK](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-scripter_smac.txt)
	Timer-Sound (CS:Source only) [LINK](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-sound.txt)
	timer-Teams Challenge Points [LINK](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-teams_challenge_points.txt)
	
### 13) Usefull CVAR list

	- sv_accelerate "10" (Ground control)
	- sv_wateraccelerate "150" (Water control)
	- sv_airaccelerate "150" (Air control)
	- sv_enablebunnyhopping "1" (Disable speed limit)
	- sv_maxvelocity "9999" (Increase max. possible speed)
	- mp_falldamage "0" (Disable fall damage)
	- sv_hudhint_sound 0