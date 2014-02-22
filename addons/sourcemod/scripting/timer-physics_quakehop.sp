#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
#include <timer>
#include <timer-physics>
#include <timer-config_loader.sp>

new bool:g_bOnGround[MAXPLAYERS + 1];
new bool:g_bIsSliding[MAXPLAYERS + 1];
new Float:g_fSpeed[MAXPLAYERS + 1][3];

new basevel;

new Handle:g_cvLoss = INVALID_HANDLE;
new Handle:g_cvJumpPercent = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "[Timer] QuakeBhop",
	author = "Zipcore, Credits: Pyro",
	description = "QuakeBhop for styles",
	version = "1.0",
	url = "https://forums.alliedmods.net/showthread.php?p=2074699"
}

public OnPluginStart()
{
	HookEvent("player_jump", PlayerJump);
	basevel = FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");

	g_cvLoss = CreateConVar("sm_quake_bhop_loss", "0.03", "Percentage of speed lost per frame", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvJumpPercent = CreateConVar("sm_quake_bhop_jump_percent", "0.5", "Percent of speed used in jump", FCVAR_NOTIFY, true, 0.0);
	
	LoadPhysics();
}

public OnMapStart()
{
	LoadPhysics();
}

public Action:PlayerJump(Handle:event, const String:name[], bool:dontBroadcast) 
{   
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(g_Physics[Timer_GetMode(client)][ModeQuakeBhop] == 1 && g_bIsSliding[client] == true)
	{
		new Float:finalvec[3];
		finalvec[0]=g_fSpeed[client][0] * GetConVarFloat(g_cvJumpPercent);
		finalvec[1]=g_fSpeed[client][1] * GetConVarFloat(g_cvJumpPercent);
		finalvec[2]=0.0;
		SetEntDataVector(client,basevel,finalvec,true);
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon, &subtype, &cmdnum, &tickcount, &seed, mouse[2])
{
	if(!IsClientInGame(client))
		return Plugin_Continue;
	
	if(!IsPlayerAlive(client))
		return Plugin_Continue;
	
	if(g_Physics[Timer_GetMode(client)][ModeQuakeBhop] != 1)
		return Plugin_Continue;
	
	if(GetEntityFlags(client) & FL_ONGROUND)
	{
		if(g_bOnGround[client] != true)
		{
			OnClientLand(client);
			g_bOnGround[client] = true;
		}
	}
	else
	{
		StopSlide(client);
		if(g_bOnGround[client] != false)
		{
			g_bOnGround[client] = false;
		}
	}

	if(g_bIsSliding[client] == true)
	{
		if(GetSpeed(client) > 40.0)
		{
			g_fSpeed[client][0] *= (1.0 - GetConVarFloat(g_cvLoss));
			g_fSpeed[client][1] *= (1.0 - GetConVarFloat(g_cvLoss));
			g_fSpeed[client][2] = 0.0;
		}
		else
		{
			StopSlide(client);
		}
	}
	
	return Plugin_Continue;
}

public StopSlide(client)
{
	g_bIsSliding[client] = false;
	g_fSpeed[client][0] = 0.0;
	g_fSpeed[client][1] = 0.0;
	g_fSpeed[client][2] = 0.0;
}

public Float:GetSpeed(client)
{
	new Float:vel[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vel);
	return SquareRoot(vel[0] * vel[0] + vel[1] * vel[1] + vel[2] * vel[2]);
}

public OnClientLand(client)
{
	g_bIsSliding[client] = true;
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", g_fSpeed[client]);
}