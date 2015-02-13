#if defined _timer_scripter_db_included
 #endinput
#endif
#define _timer_scripter_db_included

/* Natives */
native Timer_AddScripter(client);
native Timer_IsScripter(client);
	
public SharedPlugin:__pl_timer_scripter_db = 
{
	name = "timer-scripter_db",
	file = "timer-scripter_db.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

public __pl_timer_scripter_db_SetNTVOptional() 
{
	MarkNativeAsOptional("Timer_AddScripter");
	MarkNativeAsOptional("Timer_IsScripter");
}