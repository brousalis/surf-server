#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <timer>
#include <timer-mapzones>

new Handle:cvarMode = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "[Timer] Finish Manager",
	author = "Zipcore",
	description = "[Timer] Takes action if a player on start touching end zone",
	version = PL_VERSION,
	url = "forums.alliedmods.net/showthread.php?p=2074699"
}

public OnPluginStart()
{
	cvarMode = CreateConVar("timer_finish_mode", "0", "0:Disable 1:Slay player 2:slay all other players 3:Slay all players 4:Teleport to bonusstart zone");
}

public OnClientStartTouchZoneType(client, MapZoneType:type)
{
    if(type == ZtEnd) //Player is touching end zone, wait a bit to allow triggering
        CreateTimer(0.1, Timer_Action, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_Action(Handle:timer, any:client)
{
	new mode = GetConVarInt(cvarMode);
	
	switch(mode)
	{
		case 1:
		{
			if(IsClientInGame(client) && IsPlayerAlive(client)) ForcePlayerSuicide(client);
		}
		case 2:
		{
			for(new i=1;i<=MaxClients;i++)
			{
				if(IsClientInGame(i) && IsPlayerAlive(i) && i != client)
				{
					ForcePlayerSuicide(client);
				}
			}
		}
		case 3:
		{
			for(new i=1;i<=MaxClients;i++)
			{
				if(IsClientInGame(i) && IsPlayerAlive(i))
				{
					ForcePlayerSuicide(client);
				}
			}
		}
		case 4:
		{
			if(IsClientInGame(client) && IsPlayerAlive(client)) Timer_ClientTeleportLevel(client, 1001);
		}
	}
} 