#include <sourcemod>
#include <sdktools>
#include <smlib/arrays>
#include <timer>

#define MAX_STRAFES 5000

enum PlayerState
{
	bool:bOn,
	bool:bLastBoosted,
	nStrafes,
	nStrafesReal,
	nStrafesBoosted,
	nStrafeDir,
}

new g_PlayerStates[MAXPLAYERS + 1][PlayerState];
new Float:vLastOrigin[MAXPLAYERS + 1][3];
new Float:vLastAngles[MAXPLAYERS + 1][3];
new Float:vLastVelocity[MAXPLAYERS + 1][3];

public Plugin:myinfo = 
{
	name = "[Timer] Strafe Stats",
	author = "Zipcore, Miu",
	description = "Collect strafe stats for [Timer]",
	version = "1.0",
	url = ""
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RegPluginLibrary("timer-strafes");
	CreateNative("Timer_GetStrafeCount", Native_GetStrafeCount);
	CreateNative("Timer_GetBoostedStrafeCount", Native_GetBoostedStrafeCount);
	
	return APLRes_Success;
}

public Native_GetStrafeCount(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	return g_PlayerStates[client][nStrafesReal];
}

public Native_GetBoostedStrafeCount(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	return g_PlayerStates[client][nStrafesBoosted];
}

public OnClientPutInServer(client)
{
	g_PlayerStates[client][bOn] = true;
}

public Native_CancelJump(Handle:plugin, numParams)
{
	g_PlayerStates[GetNativeCell(1)][bOn] = true;
}

public bool:WorldFilter(entity, mask)
{
	// world has entity id 0: if nonzero, tis thing
	if(entity)
		return false;
	
	return true;
}

#define RAYTRACE_Z_DELTA -0.1

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	new bool:ongrund = bool:(GetEntityFlags(client) & FL_ONGROUND);
	
	if(g_PlayerStates[client][bOn])
	{
		GetClientAbsOrigin(client, vLastOrigin[client]);
		GetClientAbsAngles(client, vLastAngles[client]);
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", vLastVelocity[client]);
		return;
	}
	
	if(g_PlayerStates[client][nStrafes] >= MAX_STRAFES-1)
	{
		GetClientAbsOrigin(client, vLastOrigin[client]);
		GetClientAbsAngles(client, vLastAngles[client]);
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", vLastVelocity[client]);
	}
	
	new bool:newstrafe = false;
	
	new nButtonCount;
	if(buttons & IN_MOVELEFT)
		nButtonCount++;
	if(buttons & IN_MOVERIGHT)
		nButtonCount++;
	if(buttons & IN_FORWARD)
		nButtonCount++;
	if(buttons & IN_BACK)
		nButtonCount++;
	
	if(nButtonCount == 1)
	{
		if(g_PlayerStates[client][nStrafeDir] != 1 && buttons & IN_MOVELEFT)
		{
			g_PlayerStates[client][nStrafeDir] = 1;
			newstrafe = true;
		}
		else if(g_PlayerStates[client][nStrafeDir] != 2 && buttons & IN_MOVERIGHT)
		{
			g_PlayerStates[client][nStrafeDir] = 2;
			newstrafe = true;
		}
		else if(g_PlayerStates[client][nStrafeDir] != 3 && buttons & IN_FORWARD)
		{
			g_PlayerStates[client][nStrafeDir] = 3;
			newstrafe = true;
		}
		else if(g_PlayerStates[client][nStrafeDir] != 4 && buttons & IN_BACK)
		{
			g_PlayerStates[client][nStrafeDir] = 4;
			newstrafe = true;
		}
	}
	
	if(newstrafe)
	{
		if(g_PlayerStates[client][nStrafes] >= MAX_STRAFES)
		{
			g_PlayerStates[client][nStrafesReal]++;
			g_PlayerStates[client][nStrafes] = 1;
		}
		else
		{
			g_PlayerStates[client][nStrafesReal]++;
			g_PlayerStates[client][nStrafes]++;
		}
	}
	
	if(g_PlayerStates[client][nStrafes] > 0)
	{
		new Float:fVelDelta;
		fVelDelta = GetSpeed(client) - GetVSpeed(vLastVelocity[client]);
	
		if(!ongrund)
		{
			if(GetSpeed(client) > 275.0)
			{
				if(fVelDelta > 3.0)
				{
					if(!g_PlayerStates[client][bLastBoosted])
						g_PlayerStates[client][nStrafesBoosted]++;
					
					g_PlayerStates[client][bLastBoosted] = true;
				}
			}
		}
	}
	
	GetClientAbsOrigin(client, vLastOrigin[client]);
	GetClientAbsAngles(client, vLastAngles[client]);
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vLastVelocity[client]);
}

public OnClientStartTouchZoneType(client, MapZoneType:type)
{
	if (type != ZtEnd && type != ZtBonusEnd)
		return;
	
	g_PlayerStates[client][bOn] = true;
}

public OnClientEndTouchZoneType(client, MapZoneType:type)
{
	if (type != ZtStart && type != ZtBonusStart)
		return;
	
	g_PlayerStates[client][bOn] = false;
	
	// Reset stuff
	g_PlayerStates[client][nStrafeDir] = 0;
	g_PlayerStates[client][nStrafes] = 0;
	g_PlayerStates[client][nStrafesBoosted] = 0;
	
	g_PlayerStates[client][bLastBoosted] = false;
}

Float:GetSpeed(client)
{
	new Float:vVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVelocity);
	vVelocity[2] = 0.0;
	
	return GetVectorLength(vVelocity); 
}

Float:GetVSpeed(Float:v[3])
{
	new Float:vVelocity[3];
	vVelocity = v;
	vVelocity[2] = 0.0;
	
	return GetVectorLength(vVelocity);
}