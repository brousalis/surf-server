#if defined _timer_rankings_included
 #endinput
#endif
#define _timer_rankings_included

/* Natives */
native Timer_GetPoints(client);
native Timer_GetPointRank(client);
native Timer_SetPoints(client, points);
native Timer_AddPoints(client, points);
native Timer_RemovePoints(client, points);
native Timer_SavePoints(client);
	
public SharedPlugin:__pl_timer_rankings = 
{
	name = "timer-rankings",
	file = "timer-rankings.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

public __pl_timer_rankings_SetNTVOptional() 
{
	MarkNativeAsOptional("Timer_GetPoints");
	MarkNativeAsOptional("Timer_GetPointsRank");
	MarkNativeAsOptional("Timer_SavePoints");
	MarkNativeAsOptional("Timer_AddPoints");
	MarkNativeAsOptional("Timer_SetPoints");
	MarkNativeAsOptional("Timer_RemovePoints");
}