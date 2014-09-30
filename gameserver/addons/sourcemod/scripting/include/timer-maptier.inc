#if defined _timer_maptier_included
 #endinput
#endif
#define _timer_maptier_included

/* Natives */
native Timer_GetTier(bonus);
native Timer_SetTier(bonus, tier);
native Timer_GetStageCount(bonus);
native Timer_UpdateStageCount(bonus);
	
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