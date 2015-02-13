#if defined _timer_physics_included
 #endinput
#endif
#define _timer_physics_included


/* Forwards */

/**
 * Called when a client reached max jump height
 *
 * @param client The client who jumped.
 * @param type MapZoneType
 * @noreturn
 */
forward OnClientMaxJumpHeight(client, Float:height);

/**
 * Called when style setting apply on a client.
 *
 * @param client The client.
 * @param style The styleID
 * @noreturn
 */
forward OnClientApplyDifficulty(client, style);

/**
 * Called before style setting apply on a client.
 *
 * @param client The client.
 * @param style The styleID
 * @noreturn
 */
forward OnClientApplyDifficultyPre(client, style);

/* Natives */
native Timer_GetPickedStyle(client);
native Timer_GetForceStyle();
native Timer_ApplyPhysics(client);
native Timer_GetJumpAccuracy(client, &Float:percent);
native Timer_GetCurrentSpeed(client, &Float:speed);
native Timer_GetMaxSpeed(client, &Float:maxspeed);
native Timer_GetAvgSpeed(client, &Float:avgspeed);
native Timer_ResetAccuracy(client);
	
public SharedPlugin:__pl_timer_physics = 
{
	name = "timer-physics",
	file = "timer-physics.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

public __pl_timer_physics_SetNTVOptional() 
{
	MarkNativeAsOptional("Timer_GetPickedStyle");
	MarkNativeAsOptional("Timer_GetForceStyle");
	MarkNativeAsOptional("Timer_ApplyPhysics");
	MarkNativeAsOptional("Timer_GetJumpAccuracy");
	MarkNativeAsOptional("Timer_GetCurrentSpeed");
	MarkNativeAsOptional("Timer_GetMaxSpeed");
	MarkNativeAsOptional("Timer_GetAvgSpeed");
	MarkNativeAsOptional("Timer_ResetAccuracy");
}