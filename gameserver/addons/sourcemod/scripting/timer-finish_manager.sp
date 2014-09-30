#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <timer>
#include <timer-mapzones>

new Handle:cvarModePrimary = INVALID_HANDLE;
new Handle:cvarModePrimaryBonus = INVALID_HANDLE;
new Handle:cvarModeSecondary = INVALID_HANDLE;

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
	cvarModePrimary = CreateConVar("timer_finish_mode_primary", "0", "0:Disable 1:Slay player 2:slay all other players 3:Slay all players 4:Teleport to bonusstart zone");
	cvarModePrimaryBonus = CreateConVar("timer_finish_mode_primary_bonus", "0", "0:Disable 1:Slay player 2:slay all other players 3:Slay all players");
	cvarModeSecondary = CreateConVar("timer_finish_mode_secondary", "0", "If primary mode is impossible do this 0:Disable 1:Slay player");
	AutoExecConfig(true, "timer/finish_manager.cfg");
}

public OnClientStartTouchZoneType(client, MapZoneType:type)
{
    if(type == ZtEnd) //Player is touching end zone, wait a bit to allow triggering
        CreateTimer(0.1, Timer_EndAction, client, TIMER_FLAG_NO_MAPCHANGE);
    else if(type == ZtBonusEnd) //Player is touching end zone, wait a bit to allow triggering
        CreateTimer(0.1, Timer_BonusEndAction, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_EndAction(Handle:timer, any:client)
{
	new modePrimary = GetConVarInt(cvarModePrimary);
	
	switch(modePrimary)
	{
		case 1:
		{
			if(IsClientInGame(client) && IsPlayerAlive(client))
				ForcePlayerSuicide(client);
		}
		case 2:
		{
			new count;
			for(new i=1;i<=MaxClients;i++)
			{
				if(IsClientInGame(i) && IsPlayerAlive(i) && i != client)
				{
					ForcePlayerSuicide(i);
					count++;
				}
			}
			
			if(count == 0 && IsClientInGame(client) && IsPlayerAlive(client))
				SecondaryAction(client);
		}
		case 3:
		{
			for(new i=1;i<=MaxClients;i++)
			{
				if(IsClientInGame(i) && IsPlayerAlive(i))
					ForcePlayerSuicide(client);
			}
		}
		case 4:
		{
			if(IsClientInGame(client) && IsPlayerAlive(client))
			{
				if(Timer_GetMapzoneCount(ZtBonusStart))
					Timer_ClientTeleportLevel(client, 1001);
				else SecondaryAction(client);
			}
		}
	}
}

public Action:Timer_BonusEndAction(Handle:timer, any:client)
{
	new modePrimary = GetConVarInt(cvarModePrimaryBonus);
	
	switch(modePrimary)
	{
		case 1:
		{
			if(IsClientInGame(client) && IsPlayerAlive(client))
				ForcePlayerSuicide(client);
		}
		case 2:
		{
			new count;
			for(new i=1;i<=MaxClients;i++)
			{
				if(IsClientInGame(i) && IsPlayerAlive(i) && i != client)
				{
					ForcePlayerSuicide(i);
					count++;
				}
			}
			
			if(count == 0 && IsClientInGame(client) && IsPlayerAlive(client))
				SecondaryAction(client);
		}
		case 3:
		{
			for(new i=1;i<=MaxClients;i++)
			{
				if(IsClientInGame(i) && IsPlayerAlive(i))
					ForcePlayerSuicide(client);
			}
		}
	}
}

SecondaryAction(client)
{
	new modeSecondary = GetConVarInt(cvarModeSecondary);
	
	switch(modeSecondary)
	{
		case 1:
		{
			ForcePlayerSuicide(client);
		}
	}
}