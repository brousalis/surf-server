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
	RegConsoleCmd("sm_spec", Command_spec, "sm_spec <target> - Spectates a player.");
	RegConsoleCmd("sm_spectate", Command_spec, "sm_spectate <target> - Spectates a player.");
	LoadTranslations("common.phrases");
}

public Action:Command_spec(client, args)
{
	if (args == 0)
	{
		if (IsPlayerAlive(client) && IsClientInGame(client))
		{
			ChangeClientTeam(client, 1);
		}
	}
	if (args == 1)
	{
		if (IsPlayerAlive(client) && IsClientInGame(client))
		{
			ChangeClientTeam(client, 1);
		}
		new String:arg1[64];
		GetCmdArgString(arg1, sizeof(arg1));
		
		new target = FindTarget(client, arg1);
		if (target == -1) 
		{
			return Plugin_Handled;
		}
		if (IsClientInGame(target))
		{
			if (!IsPlayerAlive(target))
			{
				ReplyToCommand(client, "[SM] %t", "Target must be alive");
				return Plugin_Handled;
			}
			FakeClientCommand(client, "spec_player \"%N\"", target);
		}
		if (!IsClientInGame(target)) ReplyToCommand(client, "[SM] %t", "Target is not in game");
	}
	return Plugin_Handled;
}