#if defined _timer_mapzones_included
 #endinput
#endif
#define _timer_mapzones_included

// 38 zones types
enum MapZoneType
{
    ZtStart, //0
    ZtEnd, //1
    ZtStop, //2
    ZtRestart, //3
    ZtLast, //4
    ZtNext, //5
	ZtLevel, //6
    ZtBonusStart, //7
    ZtBonusEnd, //8
    ZtBonusLevel, //9
    ZtNPC_Next, //10
	ZtBlock, //11
	ZtLimitSpeed, //12
	ZtPlayerClip, //13
	ZtLongjump, //14
	ZtBooster, //15
	ZtFullBooster, //16
	ZtArena, //17
	ZtBounceBack, //18
	ZtJail, //19
	ZtPushUp, //20
	ZtBulletTime, //21
	ZtNoGravityOverwrite, //22
	ZtNPC_Next_Double, //23
	ZtNoBoost, //24
	ZtRestartNormalTimer, //25
	ZtRestartBonusTimer, //26
	ZtShortEnd, //27
	ZtPushNorth, //28
	ZtPushSouth, //29
	ZtPushWest, //30
	ZtPushEast, //31
	ZtPushDown, //32
	ZtAuto, //33
	ZtNoAuto, //34
	ZtHover, //35
	ZtReset, //36
	ZtFreeStyle //37
}

/* Forwards */
forward OnClientStartTouchZoneType(client, MapZoneType:type);
forward OnClientEndTouchZoneType(client, MapZoneType:type);

forward OnClientStartTouchLevel(client, level, lastlevel);
forward OnClientStartTouchBonusLevel(client, level, lastlevel);

/* Natives */
native Timer_IsPlayerTouchingZoneType(client, MapZoneType:type);
native Timer_GetLevelName(id, String:name[], length);

native Timer_GetClientLevel(client);
native Timer_SetClientLevel(client, level);
native Timer_GetClientLevelID(client);
native Timer_ClientTeleportLevel(client, level);

native Timer_SetIgnoreEndTouchStart(client, ignore);
native Timer_GetMapzoneCount(MapZoneType:type);
	
public SharedPlugin:__pl_timer_mapzones = 
{
	name = "timer-mapzones",
	file = "timer-mapzones.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

public __pl_timer_mapzones_SetNTVOptional() {
	MarkNativeAsOptional("Timer_GetClientLevel");
	MarkNativeAsOptional("Timer_SetClientLevel");
	MarkNativeAsOptional("Timer_GetClientLevelID");
	MarkNativeAsOptional("Timer_GetLevelName");
	MarkNativeAsOptional("Timer_ClientTeleportLevel");

	MarkNativeAsOptional("Timer_SetIgnoreEndTouchStart");
	MarkNativeAsOptional("Timer_IsPlayerTouchingZoneType");
	MarkNativeAsOptional("Timer_GetMapzoneCount");
}