#include <sourcemod>
#include <sdkhooks>
#include <timer>
#include <timer-mapzones>
#include <timer-config_loader.sp>

new Handle:g_hFF;

new bool:g_bHeadshot[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name        = "[Timer] MapZones - Damage Controller",
	author      = "Zipcore, Credits: Alongub",
	description = "[Timer] Damage controller with pvp zones",
	version     = PL_VERSION,
	url         = "forums.alliedmods.net/showthread.php?p=2074699"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RegPluginLibrary("timer-mapzones_damage_controller");
	
	return APLRes_Success;
}

public OnPluginStart()
{
	LoadTimerSettings();
	LoadPhysics();
	
	g_hFF = FindConVar("mp_friendlyfire");
	
	HookEvent("player_death", Event_Player_Death, EventHookMode_Pre);
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public OnMapStart()
{
	LoadTimerSettings();
	LoadPhysics();	
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
	SDKHook(client, SDKHook_TraceAttack, Hook_OnTraceAttack);
}


public Action:Hook_OnTraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	if(victim && victim <= MaxClients)
		g_bHeadshot[victim] = (hitgroup == 1) ? true : false;
	
	return Plugin_Continue;
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	g_bHeadshot[client] = false;
}

public Action:Event_Player_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if(!attacker || attacker == client)
		return Plugin_Changed;

	if (g_bHeadshot[client])
	{
		decl String:weapon[64];
		GetEventString(event, "weapon", weapon, sizeof(weapon));
		
		new Handle:new_event = CreateEvent("player_death");
		if (new_event == INVALID_HANDLE)
		{
			return Plugin_Continue;
		}
		
		SetEventInt(new_event, "userid", GetClientUserId(client));
		SetEventInt(new_event, "attacker", GetClientUserId(attacker));
		SetEventString(new_event, "weapon", weapon);
		SetEventBool(new_event, "headshot", true);
		g_bHeadshot[client] = false;
		FireEvent(new_event);
		return Plugin_Changed;
	}

	return Plugin_Continue;
} 

public Action:Hook_OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	new bool:ff = GetConVarBool(g_hFF); 

	if (g_Settings[Godmode])
	{
		if (attacker == 0 || attacker >= MaxClients)
		{
			new mode = Timer_GetMode(victim);
			if(g_Physics[mode][ModeAllowWorldDamage])
			{
				return Plugin_Continue;
			}
		
			RemovePunchAngle(victim);
			return Plugin_Handled;
		}
	
		//PvP Zone
		if(Timer_IsPlayerTouchingZoneType(victim, ZtArena) && Timer_IsPlayerTouchingZoneType(attacker, ZtArena))
		{
			return Plugin_Continue;
		}
		
		RemovePunchAngle(victim);
		return Plugin_Handled;
	}
	
	if (attacker == 0 || attacker >= MaxClients)
	{
		new mode = Timer_GetMode(victim);
		if(g_Physics[mode][ModeAllowWorldDamage])
		{
			return Plugin_Continue;
		}
	}
	else if(GetClientTeam(victim) == GetClientTeam(attacker))
	{
		if(ff)
		{
			return Plugin_Continue;
		}
		
		RemovePunchAngle(victim);
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

stock RemovePunchAngle(client)
{
	if(GetGameMod() == MOD_CSS)
	{
		SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", NULL_VECTOR);
		SetEntPropVector(client, Prop_Send, "m_vecPunchAngleVel", NULL_VECTOR);
	}
}
