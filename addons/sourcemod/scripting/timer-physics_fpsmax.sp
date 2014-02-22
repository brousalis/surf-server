#pragma semicolon 1

#include <sourcemod>

#include <timer>
#include <timer-config_loader.sp>

new Handle:g_hFPSMaxDisable = INVALID_HANDLE;
new bool:g_bFPSMaxDisable = false;

public Plugin:myinfo =
{
    name        = "[Timer] FPSCheck",
    author      = "Zipcore",
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

public OnTimerStarted(client)
{
	new mode = Timer_GetMode(client);
	
	//Check for wrong mode
	if(g_Physics[mode][ModeFPSMax] != 0 || g_Physics[mode][ModeFPSMax] != 0)
	{
		CreateTimer(1.0, FPSCheck, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:FPSCheck(Handle:timer, any:client)
{
	if(g_bFPSMaxDisable) 
		return Plugin_Stop;

	if(IsFakeClient(client))
		return Plugin_Stop;

	new bool:enabled, jumps, Float:time, fpsmax;
	
	new mode = Timer_GetMode(client);
	new bool:valid = false;

	if (Timer_GetClientTimer(client, enabled, time, jumps, fpsmax))
	{
		//Check min fpsmax
		if(g_Physics[mode][ModeFPSMin] > 0)
		{
			if(fpsmax == 0)
			{
				//valid
			}
			else if(fpsmax >= g_Physics[mode][ModeFPSMin])
			{
				valid = true;
			}
		}
		
		if(g_Physics[mode][ModeFPSMax] > 0)
		{
			//Check max fpsmax
			if(fpsmax == 0)
			{
				valid = false;
			}
			if(fpsmax <= g_Physics[mode][ModeFPSMin])
			{
				valid = true;
			}
			else valid = false;
		}
		
		if(!valid && g_ModeDefault != -1)
		{
			//change mode
			Timer_SetMode(client, g_ModeDefault);
			Timer_Restart(client);
			
			decl String:warnstr[128];
			FormatEx(warnstr, sizeof(warnstr), "%T", "Custom FPS", client);
			PrintToChat(client, PLUGIN_PREFIX, "Custom FPS");
		}
	}
	return Plugin_Stop;
}