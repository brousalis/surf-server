#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <timer>

new Handle:cvarSpawns = INVALID_HANDLE;

public Plugin:myinfo =
{
	name        = "[Timer] Unlimited Spawn Points",
	author      = "Zipcore, exvel",
	description = "Enforces a minimum amount of spawn points per team.",
	version     = PL_VERSION,
	url         = "forums.alliedmods.net/showthread.php?p=2074699"
};

public OnPluginStart()
{
	cvarSpawns = CreateConVar("timer_enforce_spawns", "32", "Amount of spawnpoints to enforce each team");
	AutoExecConfig(true, "timer/unlimited_spawnpoints.cfg");
}

public OnMapStart()
{
	new minspawns = GetConVarInt(cvarSpawns);
	
	new CTspawns = 0;
	new Tspawns = 0;
	
	new Float:fVecCt[3];
	new Float:fVecT[3];
	new Float:angVec[3];
	
	new maxEnt = GetMaxEntities();
	decl String:sClassName[64];
	for (new i = MaxClients; i < maxEnt; i++)
	{
		if (IsValidEdict(i) && IsValidEntity(i) && GetEdictClassname(i, sClassName, sizeof(sClassName)))
		{
			if (StrEqual(sClassName, "info_player_terrorist"))
			{
				Tspawns++;
				GetEntPropVector(i, Prop_Data, "m_vecOrigin", fVecT);
			}
			else if (StrEqual(sClassName, "info_player_counterterrorist"))
			{
				CTspawns++;
				GetEntPropVector(i, Prop_Data, "m_vecOrigin", fVecCt);
			}
		}
	}
	
	if(CTspawns < minspawns)
	{
		
		for(new i=CTspawns; i<=minspawns ;i++)
		{
			new entity = CreateEntityByName("info_player_counterterrorist");
			if (DispatchSpawn(entity))
			{
				TeleportEntity(entity, fVecCt, angVec, NULL_VECTOR);
			}
		}
	}
	
	if(Tspawns < minspawns)
	{
		
		for(new i=Tspawns; i<=minspawns ;i++)
		{
			new entity = CreateEntityByName("info_player_terrorist");
			if (DispatchSpawn(entity))
			{
				TeleportEntity(entity, fVecT, angVec, NULL_VECTOR);
			}
		}
	}
}
