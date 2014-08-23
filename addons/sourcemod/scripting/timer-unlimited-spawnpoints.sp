#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <timer>

new Float:LastUsed[MAXPLAYERS+1];

new Handle:cvarTeams = INVALID_HANDLE;
new Handle:cvarClassSelection = INVALID_HANDLE;
new Handle:cvarAlive = INVALID_HANDLE;

public Plugin:myinfo =
{
	name        = "[Timer] Unlimited Spawn Points",
	author      = "Zipcore, exvel",
	description = "Enforces a minimum amount of spawn points per team.",
	version     = PL_VERSION,
	url         = "forums.alliedmods.net/showthread.php?p=2074699"
};

public OnPluginStart()
{
	cvarTeams = CreateConVar("timer_spawn_team", "1", "0:Disable Plugin 1:All Teams 2:Terrorist only 3:Counter-Terrorist only");
	cvarClassSelection = CreateConVar("timer_spawn_class", "0", "0:Skip class selection 1:Allow class selection");
	cvarAlive = CreateConVar("timer_spawn_alive", "0", "0:Don't allow alive player to respawn 1:Allow");
	AutoExecConfig(true, "timer/unlimited_spawnpoints");
	
	RegConsoleCmd("jointeam", JoinTeam);
}
 
public OnClientConnected(client)
{
	new Float:curTime = GetGameTime();
	LastUsed[client] = curTime;
}
 
public Action:JoinTeam(client, args)
{
	new spawn_mode = GetConVarInt(cvarTeams);
	new bool:allow_class = GetConVarBool(cvarClassSelection);
	
	if(spawn_mode < 1)
		return Plugin_Continue;
	
	if(args < 1)
		return Plugin_Handled;
	
	if(!GetConVarBool(cvarAlive) && IsPlayerAlive(client))
		return Plugin_Handled;
	
	decl String:buffer[256];
	GetCmdArgString(buffer, sizeof(buffer));
	
	new team = StringToInt(buffer);
	
	new Float:curTime = GetGameTime();
	if (curTime - LastUsed[client] != 0)
	{
		if(team > CS_TEAM_SPECTATOR || team == 0)
		{
			if(spawn_mode == CS_TEAM_CT)
				CS_SwitchTeam(client, CS_TEAM_CT);
			if(spawn_mode == CS_TEAM_T)
				CS_SwitchTeam(client, CS_TEAM_T);
			else
				CS_SwitchTeam(client, team);
				
			CS_RespawnPlayer(client);
		}
		LastUsed[client] = curTime;
	}
	
	if(allow_class)
		return Plugin_Continue;
	
	return Plugin_Handled;
}