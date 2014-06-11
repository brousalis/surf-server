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
    description = "[Timer] Change style with quick commands without style selection",
    version     = PL_VERSION,
    url         = "forums.alliedmods.net/showthread.php?p=2074699"
};

public OnPluginStart()
{
	LoadPhysics();
	LoadTimerSettings();

	for(new i = 0; i < MAX_STYLES-1; i++) 
	{
		if(StrEqual(g_Physics[i][StyleQuickCommand], ""))
			continue;
		
		RegConsoleCmd(g_Physics[i][StyleQuickCommand], Callback_Empty);
		AddCommandListener(Hook_Command, g_Physics[i][StyleQuickCommand]);
	}
}

public OnMapStart()
{
	LoadPhysics();
	LoadTimerSettings();
}

public Action:Callback_Empty(client, args)
{
	return Plugin_Handled;
}

public Action:Hook_Command(client, const String:sCommand[], argc)
{
	if (!IsValidClient(client))
	{
		return Plugin_Continue;
	}
	for(new i = 0; i < MAX_STYLES-1; i++) 
	{
		if(!g_Physics[i][StyleEnable])
			continue;
		if(StrEqual(g_Physics[i][StyleQuickCommand], ""))
			continue;
		if(StrEqual(g_Physics[i][StyleQuickCommand], sCommand))
		{
			Timer_SetStyle(client, i);
			
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}