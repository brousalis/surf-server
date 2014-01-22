#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <cstrike>
#include <smlib>
#include <timer>

new bool:g_timerMapzones = false;

new bool:g_bHooked;
new bool:g_bHide[MAXPLAYERS+1] = {false, ...};

public Plugin:myinfo =
{
	name        = "[Timer] Hide",
	author      = "Zipcore, Credits: Alongub",
	description = "Hide players component for [Timer]",
	version     = PL_VERSION,
	url         = "zipcore#googlemail.com"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RegPluginLibrary("timer-hide");
	g_timerMapzones = LibraryExists("timer-mapzones");
	
	CreateNative("Timer_SetClientHide", Native_SetClientHide);
	CreateNative("Timer_GetClientHide", Native_GetClientHide);
	
	return APLRes_Success;
}

public OnPluginStart()
{
	RegConsoleCmd("sm_hide", Command_Hide);
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	AddTempEntHook("Shotgun Shot", CSS_Hook_ShotgunShot);
}

public OnLibraryAdded(const String:name[])
{
	if(StrEqual(name, "timer-mapzones"))
	{
		g_timerMapzones = true;
	}
}

public OnLibraryRemoved(const String:name[])
{	
	if(StrEqual(name, "timer-mapzones"))
	{
		g_timerMapzones = false;
	}
}

public OnClientPutInServer(client)
{
	g_bHide[client] = false;
	SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
}

public OnClientDisconnect_Post(client)
{
	g_bHide[client] = false;
	CheckHooks();
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	g_bHide[client] = false;
}

public Action:Hook_NormalSound(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	// Ignore non-weapon sounds.
	if (!g_bHooked || !(strncmp(sample, "weapon", 7) == 0 || strncmp(sample[1], "weapon", 7) == 0 || strncmp(sample[1], "reload", 7) == 0))
		return Plugin_Continue;
	
	decl i, j;
	
	for (i = 0; i < numClients; i++)
	{
		// Remove the client from the array.
		for (j = i; j < numClients-1; j++)
		{
			clients[j] = clients[j+1];
		}
		
		numClients--;
		i--;
	}
	
	return (numClients > 0) ? Plugin_Changed : Plugin_Stop;
}

public Action:CSS_Hook_ShotgunShot(const String:te_name[], const Players[], numClients, Float:delay)
{
	if (!g_bHooked)
		return Plugin_Continue;
	
	// Check which clients need to be excluded.
	decl newClients[MaxClients], client, i;
	new newTotal = 0;
	
	for (i = 0; i < numClients; i++)
	{
		client = Players[i];
		
		if (!g_bHide[client])
		{
			//newClients[newTotal++] = client;
		}
	}
	
	// No clients were excluded.
	if (newTotal == numClients)
		return Plugin_Continue;
	
	// All clients were excluded and there is no need to broadcast.
	else if (newTotal == 0)
		return Plugin_Stop;
	
	// Re-broadcast to clients that still need it.
	decl Float:vTemp[3];
	TE_Start("Shotgun Shot");
	TE_ReadVector("m_vecOrigin", vTemp);
	TE_WriteVector("m_vecOrigin", vTemp);
	TE_WriteFloat("m_vecAngles[0]", TE_ReadFloat("m_vecAngles[0]"));
	TE_WriteFloat("m_vecAngles[1]", TE_ReadFloat("m_vecAngles[1]"));
	TE_WriteNum("m_iWeaponID", TE_ReadNum("m_iWeaponID"));
	TE_WriteNum("m_iMode", TE_ReadNum("m_iMode"));
	TE_WriteNum("m_iSeed", TE_ReadNum("m_iSeed"));
	TE_WriteNum("m_iPlayer", TE_ReadNum("m_iPlayer"));
	TE_WriteFloat("m_fInaccuracy", TE_ReadFloat("m_fInaccuracy"));
	TE_WriteFloat("m_fSpread", TE_ReadFloat("m_fSpread"));
	TE_Send(newClients, newTotal, delay);
	
	return Plugin_Stop;
}

public Action:Command_Hide(client, args)
{
	if(g_bHide[client])
	{
		g_bHide[client] = false;
		CPrintToChat(client, PLUGIN_PREFIX, "Hide Disabled");
	}
	else if(GetClientTeam(client) > 1)
	{
		g_bHide[client] = true;
		CPrintToChat(client, PLUGIN_PREFIX, "Hide Enabled");
	}
	
	CheckHooks();
	
	return Plugin_Handled;
}

CheckHooks()
{
	new bool:bShouldHook = false;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (g_bHide[i])
		{
			bShouldHook = true;
			break;
		}
	}
	
	// Fake (un)hook because toggling actual hooks will cause server instability.
	g_bHooked = bShouldHook;
}

public Action:Hook_SetTransmit(entity, client)
{
	if(client == entity)
		return Plugin_Continue;
	
	if(!g_bHide[client])
		return Plugin_Continue;
	
	new mate;
	if(g_timerMapzones) mate = Timer_GetClientTeammate(client);
	
	//Don't hide mates
	if(mate > 0 && mate == entity)
		return Plugin_Continue;
	
	//Hide rest
	if(0 < entity <= MaxClients)
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Native_GetClientHide(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	if(g_bHide[client]) return 1;
	else return 0;
}

public Native_SetClientHide(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new bool:hide = GetNativeCell(2);
	if(hide) g_bHide[client] = true;
	else g_bHide[client] = false;
}