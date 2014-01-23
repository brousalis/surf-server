#if defined _timer_hide_included
 #endinput
#endif
#define _timer_hide_included

/* Natives */
native Timer_GetClientHide(client);
native Timer_SetClientHide(client, hide);
	
public SharedPlugin:__pl_timer_hide = 
{
	name = "timer-hide",
	file = "timer-hide.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

public __pl_timer_hide_SetNTVOptional() 
{
	MarkNativeAsOptional("Timer_GetClientHide");
	MarkNativeAsOptional("Timer_SetClientHide");
}