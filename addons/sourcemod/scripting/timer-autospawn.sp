#include <sourcemod>
#include <cstrike>
#include <timer>

public Plugin:myinfo = 
{

	name = "",
	author = "Zipcore",
	version = PL_VERSION,
	description = "",
	url = ""
};

public OnPluginStart() 
{

	CreateTimer(1.0, LateSpawnClient, _, TIMER_REPEAT);
}

public Action:LateSpawnClient(Handle:timer, any:data)
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		if (IsPlayerAlive(client))
			continue;
		
		new team = GetClientTeam(client);
		
		if(team == CS_TEAM_CT || team == CS_TEAM_T)
			CS_RespawnPlayer(client);
	}
	
	return Plugin_Continue;
}