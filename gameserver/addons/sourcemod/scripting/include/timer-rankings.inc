#if defined _timer_rankings_included
 #endinput
#endif
#define _timer_rankings_included

/* Forwards */

forward OnPlayerGainPoints(client, points, added);  
forward OnPlayerLostPoints(client, points, removed);  
forward OnPlayerSetPoints(client, points, old);  
forward OnPlayerPointsLoaded(client, points);  
forward OnPlayerRankLoaded(client, rank);  

/* Natives */
native Timer_GetPoints(client);
native Timer_GetPointRank(client);
native Timer_GetTag(String:tag[], size, client);
native Timer_GetChatTag(String:tag[], size, client);
native Timer_SetPoints(client, points);
native Timer_AddPoints(client, points);
native Timer_RemovePoints(client, points);
native Timer_SavePoints(client);
native Timer_RefreshPoints(client);
native Timer_RefreshPointsAll();
	
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
	MarkNativeAsOptional("Timer_GetPointRank");
	MarkNativeAsOptional("Timer_GetTag");
	MarkNativeAsOptional("Timer_GetChatTag");
	MarkNativeAsOptional("Timer_GetPointRank");
	MarkNativeAsOptional("Timer_SavePoints");
	MarkNativeAsOptional("Timer_AddPoints");
	MarkNativeAsOptional("Timer_SetPoints");
	MarkNativeAsOptional("Timer_RemovePoints");
	MarkNativeAsOptional("Timer_RefreshPoints");
	MarkNativeAsOptional("Timer_RefreshPointsAll");
}