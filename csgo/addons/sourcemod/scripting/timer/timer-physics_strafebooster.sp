#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
#include <timer-physics>
#include <timer-config_loader.sp>

#define STRAFE_A 1
#define STRAFE_D 2
#define STRAFE_W 3
#define STRAFE_S 4

new bool:bStrafeBoostDisabled[MAXPLAYERS + 1];
new nStrafeDir[MAXPLAYERS + 1];
new bool:bStrafeAngleGain[MAXPLAYERS + 1];
new Float:vLastAngles[MAXPLAYERS + 1][3];

new Float:fLanded[MAXPLAYERS + 1];
new bool:bOnGround[MAXPLAYERS + 1];
new bool:bFirstJump[MAXPLAYERS + 1];

public Plugin:myinfo = 
{
	name = "Strafe Booster",
	author = "Zipcore",
	description = "",
	version = "1.0",
	url = "zipcore#googlemail.com"
}

public OnPluginStart()
{
	LoadPhysics();
	LoadTimerSettings();
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	HookEntityOutput("trigger_push", "OnStartTouch", StartTouchTrigger);
	HookEntityOutput("trigger_push", "OnEndTouch", EndTouchTrigger);
}

public OnMapStart()
{
	LoadPhysics();
	LoadTimerSettings();
	
	HookEntityOutput("trigger_push", "OnStartTouch", StartTouchTrigger);
	HookEntityOutput("trigger_push", "OnEndTouch", EndTouchTrigger);
	
	HookTouch();
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	bStrafeBoostDisabled[client] = false;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon, &subtype, &cmdnum, &tickcount, &seed, mouse[2])
{
	new bool:onground;
	if(GetEntityFlags(client) & FL_ONGROUND || Client_IsOnLadder(client))
	{
		onground = true;
		bFirstJump[client] = false;
	}
	else onground = false;
	
	if(!bOnGround[client] && onground)
	{
		fLanded[client] = GetGameTime();
	}
	
	// Player jumped first time since a while
	if(bOnGround[client] && !onground && GetGameTime() - fLanded[client] > 1.0)
	{
		bFirstJump[client] = true;
	}
	
	bOnGround[client] = onground;
	
	/* Prepare angle */
	new Float:vAngles[3];
	vAngles[1] = angles[1];
	vAngles[1] += 360;
	
	/* Angle direction */
	new bool:angle_gain;
	if (vLastAngles[client][1] < angles[1])
		angle_gain = true;
	else
		angle_gain = false;
	
	/* Angle changed direction */
	if (bStrafeAngleGain[client] != angle_gain)
	{
		bStrafeAngleGain[client] = angle_gain;
	}
	
	/* Validate strafe */
	new nButtonCount;
	if(buttons & IN_MOVELEFT)
		nButtonCount++;
	if(buttons & IN_MOVERIGHT)
		nButtonCount++;
	if(buttons & IN_FORWARD)
		nButtonCount++;
	if(buttons & IN_BACK)
		nButtonCount++;
	
	/* Get strafe phase */
	if(nButtonCount == 1)
	{
		/* Start new strafe */
		if(nStrafeDir[client] != STRAFE_A && (buttons & IN_MOVELEFT))
		{
			nStrafeDir[client] = STRAFE_A;
		}
		else if(nStrafeDir[client] != STRAFE_D && (buttons & IN_MOVERIGHT))
		{
			nStrafeDir[client] = STRAFE_D;
		}
		else if(nStrafeDir[client] != STRAFE_W && (buttons & IN_FORWARD ))
		{
			nStrafeDir[client] = STRAFE_W;
		}
		else if(nStrafeDir[client] != STRAFE_S && (buttons & IN_BACK))
		{
			nStrafeDir[client] = STRAFE_S;
		}
		
		else if(nStrafeDir[client] != STRAFE_A && (vel[1] < 0))
		{
			nStrafeDir[client] = STRAFE_A;
		}
		else if(nStrafeDir[client] != STRAFE_D && (vel[1] > 0))
		{
			nStrafeDir[client] = STRAFE_D;
		}
		else if(nStrafeDir[client] != STRAFE_W && (vel[0] > 0))
		{
			nStrafeDir[client] = STRAFE_W;
		}
		else if(nStrafeDir[client] != STRAFE_S && (vel[0] < 0))
		{
			nStrafeDir[client] = STRAFE_S;
		}
		
		/* Continue strafe */
		
		else if(nStrafeDir[client] == STRAFE_A && (buttons & IN_MOVELEFT) && mouse[0] != 0)
		{
			StrafeBooster(client);
		}
		else if(nStrafeDir[client] == STRAFE_D && (buttons & IN_MOVERIGHT) && mouse[0] != 0)
		{
			StrafeBooster(client);
		}
		else if(nStrafeDir[client] == STRAFE_W && (buttons & IN_FORWARD) && mouse[0] != 0)
		{
			StrafeBooster(client);
		}
		else if(nStrafeDir[client] == STRAFE_S && (buttons & IN_BACK) && mouse[0] != 0)
		{
			StrafeBooster(client);
		}
		
		else if(nStrafeDir[client] == STRAFE_A && (vel[1] < 0) && mouse[0] != 0)
		{
			StrafeBooster(client);
		}
		else if(nStrafeDir[client] == STRAFE_D && (vel[1] > 0) && mouse[0] != 0)
		{
			StrafeBooster(client);
		}
		else if(nStrafeDir[client] == STRAFE_W && (vel[0] > 0) && mouse[0] != 0)
		{
			StrafeBooster(client);
		}
		else if(nStrafeDir[client] == STRAFE_S && (vel[0] < 0) && mouse[0] != 0)
		{
			StrafeBooster(client);
		}
	}
	
	/* Save last player status */
	GetClientAbsAngles(client, vLastAngles[client]);
}

stock StrafeBooster(client)
{
	if(bStrafeBoostDisabled[client])
		return;
	
	if(bOnGround[client])
		return;
	
	new Float:fVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);
	
	if(fVelocity[0] == 0.0)
		fVelocity[0] = 0.001;
	
	if(fVelocity[1] == 0.0)
		fVelocity[1] = 0.001;
	
	if(fVelocity[2] == 0.0)
		fVelocity[2] = 0.001;
		
	new Float:currentspeed = SquareRoot(Pow(fVelocity[0],2.0)+Pow(fVelocity[1],2.0));
	
	new style = Timer_GetStyle(client);
	
	if(g_Physics[style][StyleStrafeBoost] == 0)
		return;
	
	new Float:boost = float(g_Physics[style][StyleStrafeBoost]);
	
	if(boost < 0)
	{
		if(!bFirstJump[client])
			return;
		
		boost *= -1.0;
	}
	
	new Float:Multpl = currentspeed / (currentspeed+(boost/1000000.0));	
	fVelocity[0] /= Multpl;
	fVelocity[1] /= Multpl;
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVelocity);
}

HookTouch() 
{
	new ent = -1;

	while((ent = FindEntityByClassname(ent,"func_door")) != -1) 
	{
		SDKHook(ent,SDKHook_StartTouch, Entity_Touch);
		SDKHook(ent,SDKHook_EndTouch, Entity_EndTouch);
	}

	ent = -1;

	while((ent = FindEntityByClassname(ent,"func_button")) != -1) 
	{
		SDKHook(ent,SDKHook_StartTouch, Entity_Touch);
		SDKHook(ent,SDKHook_EndTouch, Entity_EndTouch);
	}
}

public Entity_Touch(entity, client) 
{
	if (client < 1 || client > MaxClients)
	{
		return;
	}
	
	if (!IsClientInGame(client))
	{
		return;
	}
	
	if (!IsPlayerAlive(client))
	{
		return;
	}
	
	bStrafeBoostDisabled[client] = true;
}

public Entity_EndTouch(entity, client) 
{
	if (client < 1 || client > MaxClients)
	{
		return;
	}
	
	if (!IsClientInGame(client))
	{
		return;
	}
	
	if (!IsPlayerAlive(client))
	{
		return;
	}
	
	CreateTimer(0.5, Timer_BlockOff, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_BlockOff(Handle:timer, any:client)
{
	bStrafeBoostDisabled[client] = false;
	
	return Plugin_Stop;
}

public StartTouchTrigger(const String:output[], caller, activator, Float:delay)
{
	if (activator < 1 || activator > MaxClients)
	{
		return;
	}
	
	if (!IsClientInGame(activator))
	{
		return;
	}
	
	if (!IsPlayerAlive(activator))
	{
		return;
	}
	
	new client = activator;
	
	bStrafeBoostDisabled[client] = true;
}

public EndTouchTrigger(const String:output[], caller, activator, Float:delay)
{
	if (activator < 1 || activator > MaxClients)
	{
		return;
	}
	
	if (!IsClientInGame(activator))
	{
		return;
	}
	
	if (!IsPlayerAlive(activator))
	{
		return;
	}
	
	new client = activator;
	
	bStrafeBoostDisabled[client] = false;
}