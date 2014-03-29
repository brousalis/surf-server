#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <cstrike>
#include <smlib>
#include <timer>
#include <timer-hide>

#undef REQUIRE_PLUGIN
#include <timer-teams>

new bool:g_timerTeams = false;

new bool:g_bHooked;
new bool:g_bHide[MAXPLAYERS+1] = {false, ...};
new g_iWeaponOwner[2048];
new g_bLateLoad;

public Plugin:myinfo =
{
	name        = "[Timer] Hide",
	author      = "Zipcore, exvel",
	description = "Hide players component for [Timer]",
	version     = PL_VERSION,
	url         = "forums.alliedmods.net/showthread.php?p=2074699"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RegPluginLibrary("timer-hide");
	g_timerTeams = LibraryExists("timer-teams");
	g_bLateLoad = late;

	CreateNative("Timer_SetClientHide", Native_SetClientHide);
	CreateNative("Timer_GetClientHide", Native_GetClientHide);

	return APLRes_Success;
}

public OnPluginStart()
{
	LoadTranslations("timer.phrases");
	RegConsoleCmd("sm_hide", Command_Hide);
	
	AddTempEntHook("Shotgun Shot", CSS_Hook_ShotgunShot);

	if (g_bLateLoad)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i))
			{
				OnClientPutInServer(i);
			}
		}
	}
}

public OnLibraryAdded(const String:name[])
{
	if(StrEqual(name, "timer-teams"))
	{
		g_timerTeams = true;
	}
}

public OnLibraryRemoved(const String:name[])
{	
	if(StrEqual(name, "timer-teams"))
	{
		g_timerTeams = false;
	}
}

public OnClientPutInServer(client)
{
	g_bHide[client] = false;
	SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
	SDKHook(client, SDKHook_WeaponEquip, Hook_WeaponEquip);
	SDKHook(client, SDKHook_WeaponDrop, Hook_WeaponDrop);
	CheckHooks();
}

public OnClientDisconnect_Post(client)
{
	g_bHide[client] = false;
	SDKUnhook(client, SDKHook_SetTransmit, Hook_SetTransmit);
	SDKUnhook(client, SDKHook_WeaponEquip, Hook_WeaponEquip);
	SDKUnhook(client, SDKHook_WeaponDrop, Hook_WeaponDrop);
	CheckHooks();
}

public OnEntityCreated(entity, const String:classname[])
{
	if (entity > MaxClients && entity < 2048)
	{
		g_iWeaponOwner[entity] = 0;
	}
}

public OnEntityDestroyed(entity)
{
	if (entity > MaxClients && entity < 2048)
	{
		g_iWeaponOwner[entity] = 0;
	}
}

public Hook_WeaponEquip(client, weapon)
{
	if (weapon > MaxClients && weapon < 2048)
	{
		g_iWeaponOwner[weapon] = client;
		SDKHook(weapon, SDKHook_SetTransmit, Hook_SetTransmitWeapon);
	}
}

public Hook_WeaponDrop(client, weapon)
{
	if (weapon > MaxClients && weapon < 2048)
	{
		g_iWeaponOwner[weapon] = 0;
		SDKUnhook(weapon, SDKHook_SetTransmit, Hook_SetTransmitWeapon);
	}
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
	else
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
	new mate;
	if(g_timerTeams) 
	{	
		mate = Timer_GetClientTeammate(client);
	}
	return (g_bHide[client] && IsPlayerAlive(client) && client != entity && mate != entity && (0 < entity <= MaxClients)) ? Plugin_Handled : Plugin_Continue;
}

public Action:Hook_SetTransmitWeapon(entity, client) 
{
	new mate;
	if(g_timerTeams) 
	{	
		mate = Timer_GetClientTeammate(client);
	} 
	return (g_bHide[client] && IsPlayerAlive(client) && g_iWeaponOwner[entity] && g_iWeaponOwner[entity] != client && g_iWeaponOwner[entity] != mate) ? Plugin_Handled : Plugin_Continue;
}

public Native_GetClientHide(Handle:plugin, numParams)
{
	return g_bHide[GetNativeCell(1)];
}

public Native_SetClientHide(Handle:plugin, numParams)
{
	g_bHide[GetNativeCell(1)] = bool:GetNativeCell(2);
}