#pragma semicolon 1

#include <sourcemod>

#include <timer>
#include <timer-logging>
#include <timer-stocks>
#include <timer-config_loader.sp>

public Plugin:myinfo =
{
    name        = "[Timer] Quickstyle Commands",
    author      = "Zipcore",
    description = "Quickstyles component for [Timer]",
    version     = PL_VERSION,
    url         = "zipcore#googlemail.com"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RegPluginLibrary("timer-quickstyles");

	return APLRes_Success;
}

public OnPluginStart()
{
	LoadPhysics();

	AddCommandListener(Client_Say, "say");
	AddCommandListener(Client_Say, "say_team");
}

public OnMapStart()
{
	LoadPhysics();
}

public Action:Client_Say(client, const String:sCommand[], argc)
{
	if (argc < 1 || !IsValidClient(client))
	{
		return Plugin_Continue;
	}
	
	decl String:sFirstArg[64];
	GetCmdArg(1, sFirstArg, sizeof(sFirstArg));
	
	for(new i = 0; i < MAX_MODES-1; i++) 
	{
		if(!g_Physics[i][ModeEnable])
			continue;
		if(StrEqual(g_Physics[i][ModeQuickCommand], ""))
			continue;
		if(StrEqual(g_Physics[i][ModeQuickCommand], sFirstArg))
		{
			Timer_SetMode(client, i);
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}