#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#include <timer>
#include <timer-logging>
#include <timer-config_loader.sp>

public Plugin:myinfo =
{
	name		= "[Timer] macrodox",
	author		= "Jason Bourne, Credit:aspi",
	description	= "macrodox component for [Timer]",
	version		= PL_VERSION,
	url			= "http://SourceGN.com"
};


//General variables
new aiJumps[MAXPLAYERS+1] = {0, ...};
new Float:afAvgJumps[MAXPLAYERS+1] = {1.0, ...};
new Float:afAvgSpeed[MAXPLAYERS+1] = {250.0, ...};
new Float:avVEL[MAXPLAYERS+1][3];
new aiPattern[MAXPLAYERS+1] = {0, ...};
new aiPatternhits[MAXPLAYERS+1] = {0, ...};
new Float:avLastPos[MAXPLAYERS+1][3];
new aiAutojumps[MAXPLAYERS+1] = {0, ...};
new aaiLastJumps[MAXPLAYERS+1][30];
new Float:afAvgPerfJumps[MAXPLAYERS+1] = {0.3333, ...};
new iTickCount = 1;
new aiIgnoreCount[MAXPLAYERS+1];
new bool:bBanFlagged[MAXPLAYERS+1];
new bool:bSurfCheck[MAXPLAYERS+1];
new aiLastPos[MAXPLAYERS+1] = {0, ...};

public OnPluginStart()
{	
	HookEvent("player_jump", Event_PlayerJump, EventHookMode_Post);  
	LoadPhysics();
	LoadTimerSettings();
}

public OnMapStart()
{
	LoadPhysics();
	LoadTimerSettings();
}

public Event_PlayerJump(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	afAvgJumps[client] = ( afAvgJumps[client] * 9.0 + float(aiJumps[client]) ) / 10.0;

	new mode = Timer_GetMode(client);
	
	decl Float:vec_vel[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vec_vel);
	vec_vel[2] = 0.0;
	new Float:speed = GetVectorLength(vec_vel);
	afAvgSpeed[client] = (afAvgSpeed[client] * 9.0 + speed) / 10.0;

	aaiLastJumps[client][aiLastPos[client]] = aiJumps[client];
	aiLastPos[client]++;
	
	if (aiLastPos[client] == 30)
	{
		aiLastPos[client] = 0;
	}

	if (afAvgJumps[client] > 15.0)
	{
		if ((aiPatternhits[client] > 0) && (aiJumps[client] == aiPattern[client]))
		{
			aiPatternhits[client]++;
			if ((aiPatternhits[client] > 15) && (!bBanFlagged[client]))
			{
				if(Timer_IsModeRanked(mode) && !Timer_IsPlayerTouchingZoneType(client, ZtAuto) && !g_Physics[mode][ModeAuto])
				{
					AddScripter(client, "pat1");
					bBanFlagged[client] = true;
				}
			}
		}
		else if ((aiPatternhits[client] > 0) && (aiJumps[client] != aiPattern[client]))
		{
			aiPatternhits[client] -= 2;
		}
		else
		{
			aiPattern[client] = aiJumps[client];
			aiPatternhits[client] = 2;
		}
	}
	else if(aiJumps[client] > 1)
	{
		aiAutojumps[client] = 0;
	}
	else if((afAvgJumps[client] <1.1) && (!bBanFlagged[client]))
	{	
		bSurfCheck[client] = true;
		if (aiIgnoreCount[client])
		{
			aiIgnoreCount[client]--;
		}
		if (speed > 350 && aiIgnoreCount[client] == 0)
		{
			aiAutojumps[client]++;
			
			if (aiAutojumps[client] >= 20)
			{
				if(Timer_IsModeRanked(mode) && !g_Physics[mode][ModeAuto] && !Timer_IsPlayerTouchingZoneType(client, ZtAuto)) 
				{
					AddScripter(client, "hax1");
				}
			}
		}
		else if (aiAutojumps[client])
		{
			aiAutojumps[client]--;
		}
	} 

	aiJumps[client] = 0;
	new Float:tempvec[3];
	tempvec = avLastPos[client];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", avLastPos[client]);

	new Float:len = GetVectorDistance(avLastPos[client], tempvec, true);
	if (len < 30.0)
	{	
		aiIgnoreCount[client] = 2;
	}

	if (afAvgPerfJumps[client] >= 0.94 && !bBanFlagged[client])
	{
		if(Timer_IsModeRanked(mode) && !g_Physics[mode][ModeAuto] && !Timer_IsPlayerTouchingZoneType(client, ZtAuto))
		{
			AddScripter(client, "hax2");
		}
	}
}

public OnClientDisconnect(client)
{
	aiJumps[client] = 0;
	afAvgJumps[client] = 5.0;
	afAvgSpeed[client] = 250.0;
	afAvgPerfJumps[client] = 0.3333;
	aiPattern[client] = 0;
	aiPatternhits[client] = 0;
	aiAutojumps[client] = 0;
	aiIgnoreCount[client] = 0;
	bBanFlagged[client] = false;
	avVEL[client][2] = 0.0;
	new i;
	
	while (i < 30)
	{
		aaiLastJumps[client][i] = 0;
		i++;
	}
}

public OnGameFrame()
{
	if (iTickCount > 1*MaxClients)
	{
		iTickCount = 1;
	}
	else
	{
		if (iTickCount % 1 == 0)
		{
			new index = iTickCount / 1;
			if (bSurfCheck[index] && IsClientInGame(index) && IsPlayerAlive(index))
			{	
				GetEntPropVector(index, Prop_Data, "m_vecVelocity", avVEL[index]);
				if (avVEL[index][2] < -290)
				{
					aiIgnoreCount[index] = 2;
				}
			}
		}
		iTickCount++;
	}
}

AddScripter(client, const String:type[])
{
	new mode = Timer_GetMode(client);
	if(Timer_IsModeRanked(mode) && !g_Physics[mode][ModeAuto]) 
	{
		new String:banstats[256];
		GetClientStats(client, banstats, sizeof(banstats));
		new String:auth[64];
		GetClientAuthString(client, auth, strlen(auth));

		Timer_LogInfo("[scripter_macrodox] %N [%s] banned by macrodox module (code: %s). %s", client, auth, type, banstats);
		Timer_AddScripter(client);
		bBanFlagged[client] = true;
	}
}

GetClientStats(client, String:string[], length)
{
	new Float:origin[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", origin);
	new String:map[128];
	GetCurrentMap(map, 128);
	Format(string, length, "%L Avg: %f/%f Perf: %f %s %f %f %f Last: %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i",
	client,
	afAvgJumps[client],
	afAvgSpeed[client],
	afAvgPerfJumps[client],
	map,
	origin[0],
	origin[1],
	origin[2],
	aaiLastJumps[client][0],
	aaiLastJumps[client][1],
	aaiLastJumps[client][2],
	aaiLastJumps[client][3],
	aaiLastJumps[client][4],
	aaiLastJumps[client][5],
	aaiLastJumps[client][6],
	aaiLastJumps[client][7],
	aaiLastJumps[client][8],
	aaiLastJumps[client][9],
	aaiLastJumps[client][10],
	aaiLastJumps[client][11],
	aaiLastJumps[client][12],
	aaiLastJumps[client][13],
	aaiLastJumps[client][14],
	aaiLastJumps[client][15],
	aaiLastJumps[client][16],
	aaiLastJumps[client][17],
	aaiLastJumps[client][18],
	aaiLastJumps[client][19],
	aaiLastJumps[client][20],
	aaiLastJumps[client][21],
	aaiLastJumps[client][22],
	aaiLastJumps[client][23],
	aaiLastJumps[client][24],
	aaiLastJumps[client][25],
	aaiLastJumps[client][26],
	aaiLastJumps[client][27],
	aaiLastJumps[client][28],
	aaiLastJumps[client][29]);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	new mode = Timer_GetMode(client);
	if(Timer_IsModeRanked(mode) && !g_Physics[mode][ModeAuto]) 
	{
		if(IsPlayerAlive(client))
		{
			static bool:bHoldingJump[MAXPLAYERS + 1];
			static bLastOnGround[MAXPLAYERS + 1];
			if(buttons & IN_JUMP)
			{
				if(!bHoldingJump[client])
				{
					bHoldingJump[client] = true;//started pressing +jump
					aiJumps[client]++;
					if (bLastOnGround[client] && (GetEntityFlags(client) & FL_ONGROUND))
					{
						afAvgPerfJumps[client] = ( afAvgPerfJumps[client] * 9.0 + 0 ) / 10.0;
						
					}
					else if (!bLastOnGround[client] && (GetEntityFlags(client) & FL_ONGROUND))
					{
						afAvgPerfJumps[client] = ( afAvgPerfJumps[client] * 9.0 + 1 ) / 10.0;
					}
				}
			}
			else if(bHoldingJump[client]) 
			{
				bHoldingJump[client] = false;//released (-jump)
				
			}
			bLastOnGround[client] = GetEntityFlags(client) & FL_ONGROUND;	  
		}
	}
	 
	return Plugin_Continue;
}