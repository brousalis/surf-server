#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#include <timer>

public Plugin:myinfo ={
    name        = "[Timer] Spectate",
    author      = "Zipcore, Jason Bourne",
    description = "[Timer] Provides afk commands",
    version     = PL_VERSION,
    url         = "forums.alliedmods.net/showthread.php?p=2074699"
};

public OnPluginStart()
{
	RegConsoleCmd("sm_afk", Command_spec);
	RegConsoleCmd("sm_spectate", Command_spec);
}

public Action:Command_spec(client, args)
{
	if(!IsFakeClient(client) && IsClientInGame(client))
	{
		FakeClientCommand(client, "spectate");
	}
	
	return Plugin_Handled;
}