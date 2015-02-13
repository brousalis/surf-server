#if defined _timer_maptier_included
 #endinput
#endif
#define _timer_maptier_included

/* Forwards */

/**
 * Called when all tiers are loaded from the database.
 *
 * @noreturn
 */
forward OnMapTiersLoaded();

/* Natives */
native Timer_GetTier(track);
native Timer_SetTier(track, tier);
native Timer_GetMapTier(String:map[], track);
native Timer_GetStageCount(track);
native Timer_GetMapStageCount(String:map[], track);
native Timer_UpdateStageCount(track);
	
public SharedPlugin:__pl_timer_maptier = 
{
	name = "timer-maptier",
	file = "timer-maptier.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

public __pl_timer_maptier_SetNTVOptional() 
{
	MarkNativeAsOptional("Timer_GetTier");
	MarkNativeAsOptional("Timer_SetTier");
	MarkNativeAsOptional("Timer_GetStageCount");
	MarkNativeAsOptional("Timer_UpdateStageCount");
}