#pragma semicolon 1
#include <sourcemod>
#include <timer>
#include <timer-config_loader.sp>

public Plugin:myinfo =
{
	name = "[Timer] ThirdPerson",
	author = "SeriTools",
	description = "[Timer] Third-person style",
	version = PL_VERSION,
	url = "forums.alliedmods.net/showthread.php?p=2074699"
};

public OnPluginStart()
{
	LoadPhysics();
	LoadTimerSettings();
	
	new Handle:m_hAllowTP = FindConVar("sv_allow_thirdperson");
	if(m_hAllowTP != INVALID_HANDLE)
	{
		SetConVarInt(m_hAllowTP, 1);
	}
	CreateTimer(1.0, TriggerThirdPersonCheck, _, TIMER_REPEAT);
}

public OnMapStart()
{
	LoadPhysics();
	LoadTimerSettings();
}

public Action:TriggerThirdPersonCheck(Handle:timer)
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && !IsClientObserver(client) && !IsFakeClient(client))
		{
			new style = Timer_GetStyle(client);
			if (g_Physics[style][StyleThirdPerson])
			{
				ClientCommand(client, "thirdperson");
			}
			else
			{
				ClientCommand(client, "firstperson");
			}
		}
	}
	return Plugin_Continue;	
}