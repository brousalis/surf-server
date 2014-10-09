#include <sourcemod>
#include <sdktools>
#include <cstrike>

#include <store>
#include <timer>
#include <timer-worldrecord>
#include <timer-config_loader.sp>

#pragma semicolon 1

new Handle:gH_Enabled = INVALID_HANDLE;
new bool:gB_Enabled;

new Handle:gH_PTG = INVALID_HANDLE;
new gI_PTG;

new bool:Physics;

public Plugin:myinfo = 
{
	name = "[Timer] Store Credits Giver",
	author = "TimeBomb/x69 ml & Zipcore",
	description = "Gives \"Store\" money when you finish a map, followed by an algorithm.",
	version = PL_VERSION,
	url = "forums.alliedmods.net/showthread.php?p=2074699"
}

public OnPluginStart()
{
	CreateConVar("sm_smadder_version", PL_VERSION, "Version", FCVAR_PLUGIN|FCVAR_DONTRECORD|FCVAR_NOTIFY);
	
	gH_Enabled = CreateConVar("sm_smadder_enabled", "1", "Store money adder is enabled?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gB_Enabled = true;
	
	gH_PTG = CreateConVar("sm_smadder_ptg", "25", "Default base money to pay and start the billing algorithm calculation with.\nAlgorithm - CVAR / 4.1 / jumps * 5.4 * fps_max value * difficulty index / 75.4.", FCVAR_PLUGIN, true, 1.0);
	gI_PTG = GetConVarInt(gH_PTG);
	
	Physics = LibraryExists("timer-physics");
	
	HookConVarChange(gH_Enabled, oncvarchanged);
	HookConVarChange(gH_PTG, oncvarchanged);
	
	AutoExecConfig(true, "storemoneyadder");
	
	LoadPhysics();
	LoadTimerSettings();
}

public OnMapStart()
{
	LoadPhysics();
	LoadTimerSettings();
}

public OnLibraryAdded(const String:name[])
{
	Physics = LibraryExists("timer-physics");
}

public OnLibraryRemoved(const String:name[])
{
	Physics = LibraryExists("timer-physics");
}

public oncvarchanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if(cvar == gH_Enabled)
	{
		gB_Enabled = bool:StringToInt(newVal);
	}
	
	else if(cvar == gH_PTG)
	{
		gI_PTG = StringToInt(newVal);
	}
}

public OnTimerRecord(client, track, style, Float:time, Float:lasttime, currentrank, newrank)
{
	if(!gB_Enabled || !IsValidClient(client))
	{
		return;
	}
	
	new fpsmax, jumps, bool:enabled;
	Timer_GetClientTimer(client, enabled, time, jumps, fpsmax);
	
	if(fpsmax == 0 || fpsmax > 300)
	{
		fpsmax = 300;
	}
	
	if(jumps <= 0)
	{
		jumps = 1;
	}
	
	new totalrank = Timer_GetStyleTotalRank(style, track);
	
	new bool:worldrecord1 = totalrank == 1? true:false;
	new bool:worldrecord2 = newrank == 1? true:false;
	
	if(!Physics)
	{
		style = 1;
	}
	
	new Float:PTG = float(gI_PTG)/4.1/float(jumps)*4.5*float(fpsmax)*g_Physics[style][StylePointsMulti]/75.4;
	
	if(currentrank > 0)
	{
		if(worldrecord1)
		{
			PTG *= 1.1;
		}
		
		if(worldrecord2)
		{
			PTG *= 1.27;
		}
	}
	
	new iPTG = RoundToCeil(PTG);
	
	if(iPTG > 0)
	{
		new accid = Store_GetClientAccountID(client);
		
		new Handle:pack = CreateDataPack();
		WritePackCell(pack, client);
		WritePackCell(pack, iPTG);
		
		Store_GiveCredits(accid, iPTG, CreditsCallback, pack);
	}
}

public CreditsCallback(accountId, any:pack)
{
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new iPTG = ReadPackCell(pack);
	CloseHandle(pack);
	
	PrintToChat(client, "\x04[Store]\x01 You have successfully earned %d cash for finishing this map.", iPTG);
}

stock bool:IsValidClient(client, bool:bAlive = false)
{
	if(client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && (bAlive == false || IsPlayerAlive(client)))
	{
		return true;
	}
	
	return false;
}
