#pragma semicolon 1
 
#include <sourcemod>
#include <sdktools>
#include <timer>
#include <timer-stocks>
#include <timer-mapzones>
 
public Plugin:myinfo =
{
	name        = "[Timer] Start zone no jump",
	author      = "Zipcore, Rop",
	description = "Prevents prespeed jumping inside start zones.",
	version     = PL_VERSION,
	url         = "forums.alliedmods.net/showthread.php?p=2074699"
};

public OnPluginStart()
{
	HookEvent("player_jump", Event_PlayerJump);
}

public Action:Event_PlayerJump(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(Timer_IsPlayerTouchingZoneType(client, ZtStart) || Timer_IsPlayerTouchingZoneType(client, ZtBonusStart))
	{
		CreateTimer(0.05, DelayedSlowDown, client);
	}

	return Plugin_Continue;
}

public Action:DelayedSlowDown(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		CheckVelocity(client, 1, 120.0);
	}
}

public OnClientEndTouchZoneType(client, MapZoneType:type)
{
	if(type == ZtStart || type == ZtBonusStart)
	{
		new bool:onground = bool:(GetEntityFlags(client) & FL_ONGROUND);
		
		if(!onground)
		{
			CheckVelocity(client, 1, 120.0);
		}
	}
}
