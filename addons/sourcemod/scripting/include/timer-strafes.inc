#if defined _timer_strafes_included
 #endinput
#endif
#define _timer_strafes_included

/* Natives */
native Timer_GetStrafeCount(client);
native Timer_GetBoostedStrafeCount(client);
	
public SharedPlugin:__pl_timer_strafes = 
{
	name = "timer-strafes",
	file = "timer-strafes.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

public __pl_timer_strafes_SetNTVOptional() 
{
	MarkNativeAsOptional("Timer_GetStrafeCount");
	MarkNativeAsOptional("Timer_GetBoostedStrafeCount");
}