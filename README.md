### Structure:
1. General Info
2. INSTALL INSTRUCTIONS
3. Update Instructions (2.0.x to 2.1.x)
4. Compability Info
5. List of Main Modules
6. List of Recommend Modules
7. List of Recommend Bhop Modules
8. List of Recommend Surf Modules
9. List of Recommend Climb Modules
10. List of Recommend Minigames Modules
11. List of Other Modules Modules
12. Usefull CVAR list

### 1) General Info

* The plugin is based on Alongub's [Timer 1.0.7] (https://forums.alliedmods.net/showthread.php?t=189751).
* It is completely modular and extensible (private addons can be requested, just PN me).
It measures the time and jumps it takes players to finish the map.
* Players can choose their level of difficulty (style). 
* You can add up to 32 styles, and change their physical effects on the player (timer-physics) and much other stuff.
* It has an advanced world record system. There are also other stats available
* A map start and end is determined by map zones. You can add map zones in-game ([video] (http://www.youtube.com/watch?v=YAX7FAF_N8Q)). 
* There are also glitch map zones, that try to stop players from exploiting map bugs that can possibly be used to cheat the timer (~ zones types).
* It has a customizable HUD that displays players their current timer and other info (or if you're a spectator it displays the timer of the player you're spectating).
* It has a Chatrank system which is based on a points-system.
* It supports only MySQL and is almost threaded.
* It supports CS:S and CS:GO (not all features are working on CS:GO).
* PHP-Stats (Lite) to show top players/maps on your website
* You can also use custom sprites for zone beam effects ([video tutorial] (https://www.youtube.com/watch?v=uka1Iq_I6W4&feature=youtu.be)).
* There are also many other optional modules.

### 2) INSTALL INSTRUCTIONS

FAQ --> [Timer/wiki/FAQ] (https://github.com/Zipcore/Timer/wiki/FAQ)

* **Step 1** Download the plugin at [github.com/Zipcore/Timer] (https://github.com/Zipcore/Timer)
	
* **Step 2** CS:GO color support: Continue with step 3 and skip this part if you are running a CS:S server. For CS:GO you have to follow step 2 first!
 * **Step 2.1** Open scripting/include/timer.inc with a text editor (like Notepad++)
 * **Step 2.2** Find the following line - //#define LEGACY_COLORS "CS:GO Color Support"
 * **Step 2.3** Remove // in front of #define and close it

* **Step 3)** Compiling: Download the latest Sourcemod & Metamod Snapshots (Stable Branch): [DOWNLOAD] (http://www.sourcemod.net/snapshots.php)
 * **Step 3.1** Goto addons/sourcemod/scripting/include and fill it with all files this timer provides from same folder.
 * **Step 3.2** Drag and drop needed SP files onto spcomp.exe inside addons/sourcemod/scripting to compile them it should create all needed SMX files.	

* **Step 4** Upload all SMX files, configs, sounds and materials onto your server.

* **Step 5** Insert "timer" keyvalue into configs/databases.cfg (no sqlite support).
 * **Step 5.1** When using the timer-cpmod module, insert a "cpmod" keyvalue into configs/databases.cfg
 * **Step 5.2** When using the timer-ranking_toponly module, insert a "timer_toponly" keyvalue into configs/databases.cfg

* **Step 6** Change configs/timer/settings.cfg to your needs

* **Step 7** Change configs/timer/physics.cfg to your needs (the folder contains some example files for bhop, surf, etc.)

* **Step 8** Skip this part if you don't like to run Chatranks/Points ranking/Skillrank
Depending on if you run a CS:GO or CS:S server, rename csgo-rankings.cfg/css-rankings.cfg to rankings.cfg (addons/sourcemod/configs/timer) to enable the ranking module.
 * **Step 8.1** Compile simple-chatprocessor.sp  and upload it to your server to enable chatranks.

* **Step 9** Restart your server.

* **Step 10** Start creating zones or use included mappacks inside addons/sourcemod/gamedata/MySQL

### 3) Update Instructions (2.0.x to 2.1.x

	Update 2.0.x to 2.1.x:
	1.) Make a backup of your mapzone, round and maptier table.
	2.) Delete mapzone, round and maptier table.
	3.) Delete "create table" lines of you backup files (Notepad++).
	4.) Import modified backups.

### 4) Compability Info

	- Noblock (Included into Mapzone module)
	- MultiPlayer Bunny Hops (Included into Physics module)
	- Autobhop (Included into Physics module)
	- Godmode (Build-in godmode into Physics module, with PvP Arena zone)
	- SMAC autotrigger (Included into Scripter-SMAC module)
	- Macrodox - Bhop cheat detection (Included into Scripter-Macrodox module)

### 5) List of Main Modules

* Timer-Core [INFO](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-core.txt)
* Timer-Logging [INFO](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-logging.txt)
* Timer-Physics [INFO](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-physics.txt)
* Timer-Mapzones [INFO](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-mapzones.txt)
* Timer-Maptier [INFO](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-maptier.txt)
* Timer-Teams [INFO](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-teams.txt)
* Timer-Worldrecord [INFO](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-worldrecord.txt)
    
### 6) List of Recommend Modules

* Timer-Autospawn [INFO](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-autospawn.txt)
* Timer-HUD [INFO](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-hud.txt)
* Timer-Rankings [INFO](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-rankings.txt)
* Timer-Rankings Points Lite [INFO](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-rankings_points_lite.txt)
* Timer-Physics Quick Cmds [INFO](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-physics_quickcmds.txt)
* Timer-Finish Message [INFO](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-finish_msg.txt)
* Timer-TeleMe [INFO](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-teleme.txt)
* Timer-Hide(Players) [INFO](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-hide.txt)
* Timer-Hide CMDs [INFO](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-hidecmds.txt)
* Timer-Mapinfo [INFO](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-mapinfo.txt)
* Timer-Maplist helper (CS:Source only) [INFO](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-maplist-helper.txt)
* Timer-Mapzones Simple Stage Timer [INFO](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-mapzones_simple_stage_timer.txt)
* Timer-Mapzones Damage Controller [INFO](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-mapzones_damage_controller.txt)
* Timer-Menu [INFO](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-menu.txt)
* Timer-Random Startmap [INFO](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-random_startmap.txt)
* Timer-Spec [INFO](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-spec.txt)
* Timer-Worldrecord Lastest [INFO](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-worldrecord_latest.txt)
* Timer-Worldrecord Maptop [INFO](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-worldrecord_maptop.txt)
* Timer-Worldrecord Playerinfo [INFO](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-worldrecord_playerinfo.txt)
* Timer-Unlimited Spawnpoints [INFO](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-unlimited-spawnpoints.txt)

### 7) List of Recommend Bhop Modules

* Timer-LJ Stats (Long Jump Stats) [INFO](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-ljstats.txt)
* Timer-Strafes (count strafes) [INFO](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-strafes.txt)
* Timer-Weapons (CS:Source only) [INFO](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-weapons.txt)

### 8) List of Recommend Surf Modules

* Timer-NoJail [INFO](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-nojail.txt)

### 9) List of Recommend Climb Modules

* Timer-CP Mod (Checkpoints) [INFO](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-cpmod.txt)

### 10) List of Recommend Minigames Modules

* Timer-Finish Manager [INFO](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-finish_manager.txt)

### 11) List of Other Modules

* Timer-Finish Exec [INFO](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-finish_exec.txt)
* Timer-Physics Autostrafe [INFO](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-physics_autostrafe.txt)
* Timer-Physics FPS Max [INFO](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-physics_fpsmax.txt)
* Timer-Physics Info [INFO](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-physics_info.txt)
* Timer-Physics Quake Bhop [INFO](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-physics_quakehop.txt)
* Timer-Physics Strafe Booster [INFO](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-physics_strafebooster.txt)
* Timer-Rankings Georank [INFO](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-rankings_georank.txt)
* Timer-Rankings Top Extend [INFO](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-rankings_top_extend.txt)
* Timer-Rankings Top Only [INFO](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-rankings_toponly.txt)
* Timer-Replay (Not supported) [INFO](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-replay.txt)
* Timer-Scripter DB [INFO](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-scripter_db.txt)
* Timer-Scripter Macrodox [INFO](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-scripter_macrodox.txt)
* Timer-Scripter SMAC [INFO](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-scripter_smac.txt)
* Timer-Sound (CS:Source only) [INFO](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-sound.txt)
* Timer-Teams Challenge Points [INFO](https://github.com/Zipcore/Timer/blob/master/timer_info/timer-teams_challenge_points.txt)
	
### 12) Usefull CVAR list

	- sv_accelerate "10" (Ground control)
	- sv_wateraccelerate "150" (Water control)
	- sv_airaccelerate "150" (Air control)
	- sv_enablebunnyhopping "1" (Disable speed limit)
	- sv_maxvelocity "9999" (Increase max. possible speed)
	- mp_falldamage "0" (Disable fall damage)
	- sv_hudhint_sound 0