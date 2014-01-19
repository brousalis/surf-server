#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#include <timer>

public Plugin:myinfo ={
    name        = "[Timer] Spectate",
    author      = "Jason Bourne",
    description = "afk/spec quick commands component for [Timer]",
    version     = PL_VERSION,
    url         = "http://SourceGN.com"
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