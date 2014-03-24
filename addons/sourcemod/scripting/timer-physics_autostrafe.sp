#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
#include <timer>
#include <timer-physics>
#include <timer-config_loader.sp>
 
new bool:RIGHT[MAXPLAYERS+1] = {false,...};
new bool:LEFT[MAXPLAYERS+1] = {false,...};
new Float:Second[MAXPLAYERS+1][3];
new Float:AngDiff[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "[Timer] Autostrafe",
	author = "Zipcore, Credits: CloudRick",
	description = "Strafehack for styles",
	version = "1.0",
	url = "https://forums.alliedmods.net/showthread.php?p=2074699"
}

public OnPluginStart()
{
	LoadPhysics();
	LoadTimerSettings();
}

public OnMapStart()
{
	LoadPhysics();
	LoadTimerSettings();
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon, &subtype, &cmdnum, &tickcount, &seed, mouse[2])
{
	if(!IsClientInGame(client))
		return Plugin_Continue;
	
	if(!IsPlayerAlive(client))
		return Plugin_Continue;
	
	if(g_Physics[Timer_GetMode(client)][ModeAutoStrafe] != 1)
		return Plugin_Continue;
	
	if(GetEntityFlags(client) & FL_ONGROUND)
		return Plugin_Continue;
	
	if(GetEntityMoveType(client) & MOVETYPE_LADDER)
		return Plugin_Continue;
	
	if(buttons & IN_MOVELEFT)
	{
		RIGHT[client] = false;
		LEFT[client] = false;
		return Plugin_Continue;
	}
	
	if(buttons & IN_MOVERIGHT)
	{
		RIGHT[client] = false;
		LEFT[client] = false;
		return Plugin_Continue;
	}
	
	if(buttons & IN_FORWARD)
	{
		RIGHT[client] = false;
		LEFT[client] = false;
		return Plugin_Continue;
	}
	
	if(buttons & IN_BACK)
	{
		RIGHT[client] = false;
		LEFT[client] = false;
		return Plugin_Continue;
	}
	
	AngDiff[client] = Second[client][1]-angles[1];
	Second[client] = angles;
	if (AngDiff[client] > 180)
		AngDiff[client] -= 360;
	if (AngDiff[client] < -180)
		AngDiff[client] += 360;
   
	if(AngDiff[client] < 0 || LEFT[client])
	{
		vel[1] = -400.0;
		LEFT[client] = true;
		RIGHT[client] = false;
	}
	
	if(AngDiff[client] > 0 || RIGHT[client])
	{
		vel[1] = 400.0;
		RIGHT[client] = true;
		LEFT[client] = false;
	}
	
	return Plugin_Continue;
}