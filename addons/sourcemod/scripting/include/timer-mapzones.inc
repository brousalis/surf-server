#if defined _timer_mapzones_included
 #endinput
#endif
#define _timer_mapzones_included

enum MapZoneType
{
    ZtStart,
    ZtEnd,
    ZtStop,
    ZtRestart,
    ZtLast,
    ZtNext,
	ZtLevel,
    ZtBonusStart,
    ZtBonusEnd,
    ZtBonusLevel,
    ZtNPC_Next,
	ZtBlock,
	ZtLimitSpeed,
	ZtPlayerClip, //buggy
	ZtLongjump,
	ZtBooster,
	ZtFullBooster,
	ZtArena,
	ZtBounceBack, //buggy
	ZtJail,
	ZtPushUp,
	ZtBulletTime,
	ZtNoGravityOverwrite,
	ZtNPC_Next_Double,
	ZtNoBoost,
	ZtRestartNormalTimer,
	ZtRestartBonusTimer,
	ZtShortEnd,
	ZtPushNorth,
	ZtPushSouth,
	ZtPushWest,
	ZtPushEast,
	ZtPushDown,
	ZtAuto,
	ZtNoAuto,
	ZtHover,
	ZtReset,
	ZtFreeStyle
}

/* Forwards */
forward OnClientStartTouchZoneType(client, MapZoneType:type);
forward OnClientEndTouchZoneType(client, MapZoneType:type);

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