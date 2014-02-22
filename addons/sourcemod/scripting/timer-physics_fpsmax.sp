#pragma semicolon 1

#include <sourcemod>
#include <timer>
#include <timer-config_loader.sp>

new Handle:g_hFPSMaxDisable = INVALID_HANDLE;
new bool:g_bFPSMaxDisable = false;

public Plugin:myinfo =
{
    name        = "[Timer] FPSCheck",
    author      = "Zipcore, 0wn3r",
    description = "[Timer] Checks fps_max violation for styles",
    version     = PL_VERSION,
    url         = "forums.alliedmods.net/showthread.php?p=2074699"
};

public OnPluginStart()
{
	g_hFPSMaxDisable = CreateConVar("timer_fpsmax_violation_disable", "0", "Don't switch to FPSMAX style.");
	HookConVarChange(g_hFPSMaxDisable, Action_OnSettingsChange);
	g_bFPSMaxDisable = GetConVarBool(g_hFPSMaxDisable);
	LoadPhysics();
	LoadTimerSettings();
	CreateTimer(5.0, TriggerFPSCheck, _, TIMER_REPEAT);
}

public OnMapStart()
{
	LoadPhysics();
	LoadTimerSettings();
}

public Action_OnSettingsChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if (cvar == g_hFPSMaxDisable)
		g_bFPSMaxDisable = bool:StringToInt(newvalue);	
}

public Action:TriggerFPSCheck(Handle:timer)
{
	if (!g_bFPSMaxDisable)
	{
		return Plugin_Continue;
	}

	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && !IsClientObserver(client) && !IsFakeClient(client))
		{
			QueryClientConVar(client, "fps_max", ConVarQueryFinished:FPSCheck, client);
		}
	}
	
	return Plugin_Continue;	
}

public FPSCheck(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
	if (!IsClientConnected(client))
	{
		return;
	}
		
	new bool:enabled, jumps, Float:time, fpsmax;
	Timer_GetClientTimer(client, enabled, time, jumps, fpsmax);

	if (enabled)
	{
		fpsmax = StringToInt(cvarValue);
		new mode = Timer_GetMode(client);

		if (g_Physics[mode][ModeFPSMin] == g_Physics[mode][ModeFPSMax] && g_Physics[mode][ModeFPSMin] > 0)
		{
			if (fpsmax != g_Physics[mode][ModeFPSMin])
			{
				if (g_Physics[mode][ModeFPSRedirectStyle] != -1)
				{
					Timer_SetMode(client, g_Physics[mode][ModeFPSRedirectStyle]);
				}
				else if (g_ModeDefault != -1)
				{
					Timer_SetMode(client, g_ModeDefault);
				}

				Timer_Restart(client);

				CPrintToChat(client, "%s {default}You have been switched to FPSMAX mode, if you like to play in NORMAL set fps_max to %d.", PLUGIN_PREFIX2, g_Physics[mode][ModeFPSMax]);
			}
		}
		else
		{
			if (g_Physics[mode][ModeFPSMin] > 0)
			{
				if(fpsmax < g_Physics[mode][ModeFPSMin] && fpsmax != 0)
				{
					if (g_Physics[mode][ModeFPSRedirectStyle] != -1)
					{
						Timer_SetMode(client, g_Physics[mode][ModeFPSRedirectStyle]);
					}
					else if (g_ModeDefault != -1)
					{
						Timer_SetMode(client, g_ModeDefault);
					}

					Timer_Restart(client);

					CPrintToChat(client, "%s {default}You have been switched to FPSMAX mode, if you like to play in NORMAL set fps_max higher than %d.", PLUGIN_PREFIX2, g_Physics[mode][ModeFPSMin]);
				}
			}
			
			if (g_Physics[mode][ModeFPSMax] > 0)
			{
				if(fpsmax > g_Physics[mode][ModeFPSMax])
				{
					if (g_Physics[mode][ModeFPSRedirectStyle] != -1)
					{
						Timer_SetMode(client, g_Physics[mode][ModeFPSRedirectStyle]);
					}
					else if (g_ModeDefault != -1)
					{
						Timer_SetMode(client, g_ModeDefault);
					}

					Timer_Restart(client);

					CPrintToChat(client, "%s {default}You have been switched to FPSMAX mode, if you like to play in NORMAL set fps_max lower than %d.", PLUGIN_PREFIX2, g_Physics[mode][ModeFPSMax]);
				}
			}
		}
	}
}