#pragma semicolon 1

#include <sourcemod>
#include <clientprefs>
#include <sdktools>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
#include <timer>
#include <timer-logging>
#include <timer-stocks>
#include <timer-physics>
#include <timer-config_loader.sp>

#undef REQUIRE_PLUGIN
#include <js_ljstats>
#include <timer-rankings>
#include <timer-mapzones>

enum UserJumps
{
	Float:LastJumpTimes[3],
}

new bool:g_timerMapzones = false;
new bool:g_timerLjStats = false;
new bool:g_timerRankings = false;

new g_userJumps[MAXPLAYERS][UserJumps];

new Handle:g_OnClientMaxJumpHeight;

new iPrevButtons[MAXPLAYERS+1];
new Float:fCheckTime[MAXPLAYERS+1];

//Plugin Flags
new bool:g_bLateLoaded = false;

new Handle:g_hPlattformColor = INVALID_HANDLE;
new g_PlattformColor[4] = { 0, 255, 0, 255 };

new g_PlattformColorPlayer[MAXPLAYERS+1][4];
new g_PlattformColorAvoid[4];
new g_PlattformColorCollect[4];
new g_colourme[MAXPLAYERS+1];

new Float:g_fCord_Old[MAXPLAYERS+1][3];
new Float:g_fCord_New[MAXPLAYERS+1][3];
new Float:g_fJumpLastCord[MAXPLAYERS+1][3];

//Player Physicsss
new Float:g_fStamina[MAXPLAYERS+1];
new Float:g_fLastJump[MAXPLAYERS+1] = {0.0, ...};
new Float:g_fSpeedCurrent[MAXPLAYERS+1] = {0.0,...};
new Float:g_fSpeedMax[MAXPLAYERS+1] = {0.0,...};
new Float:g_fSpeedTotal[MAXPLAYERS+1] = {0.0,...};
new g_iCommandCount[MAXPLAYERS+1] = {0, ...};
new g_iFullJumpCount[MAXPLAYERS+1] = {0, ...};
new Float:g_fFullJumpTimeAmount[MAXPLAYERS+1] = {0.0, ...};
new Float:g_fLandedTime[MAXPLAYERS+1] = {0.0, ...};
new Float:g_fJumpAccuracy[MAXPLAYERS+1] = {0.0, ...};
new bool:g_bStayOnGround[MAXPLAYERS+1] = {false, ...};

//Half Sideways Globals
new g_iMoveCount[MAXPLAYERS+1] = 0;
new g_iFORWARD_hits[MAXPLAYERS+1] = 0;
new g_iBACK_hits[MAXPLAYERS+1] = 0;
new g_iMOVELEFT_hits[MAXPLAYERS+1] = 0;
new g_iMOVERIGHT_hits[MAXPLAYERS+1] = 0;
new g_iKey_hits[MAXPLAYERS+1] = 0;
new g_iKey_hits_reset[MAXPLAYERS+1] = 0;
new Float:g_fCount_FORWARD[MAXPLAYERS+1] = 0.0;
new Float:g_fCount_BACK[MAXPLAYERS+1] = 0.0;
new Float:g_fCount_MOVELEFT[MAXPLAYERS+1] = 0.0;
new Float:g_fCount_MOVERIGHT[MAXPLAYERS+1] = 0.0;
new Float:g_fCount_Keys[MAXPLAYERS+1] = 0.0;

//Player Flags
new bool:g_bPushWait[MAXPLAYERS+1] = {false, ...};

new bool:g_bAutoDisable[MAXPLAYERS+1] = {false, ...};
new bool:g_bAuto[MAXPLAYERS+1] = {false, ...};
new Float:g_fBoost[MAXPLAYERS+1] = {0.0, ...};

new bool:g_bPickedStyle[MAXPLAYERS+1] = {false, ...};

new bool:g_bCustomAuto[MAXPLAYERS+1] = {false, ...};
new bool:g_bCustomBoost[MAXPLAYERS+1] = {false, ...};
new bool:g_bCustomFullStamina[MAXPLAYERS+1] = {false, ...};
new bool:g_bCustomLowGravity[MAXPLAYERS+1] = {false, ...};


//Func_Door list
new g_iBhopDoorList[MAX_BHOPBLOCKS];
new g_iBhopDoorTeleList[MAX_BHOPBLOCKS];
new g_iBhopDoorCount;

//Func_Button list
new g_iBhopButtonList[MAX_BHOPBLOCKS];
new g_iBhopButtonTeleList[MAX_BHOPBLOCKS];
new g_iBhopButtonCount;

//Vegas
new g_iVegasWinCount;
new bool:g_bBhopDoorAvoid[MAX_BHOPBLOCKS];
new bool:g_bBhopDoorCollect[MAX_BHOPBLOCKS];
new bool:g_bBhopDoorClientAvoid[MAX_BHOPBLOCKS][MAXPLAYERS+1];
new bool:g_bBhopDoorClientCollect[MAX_BHOPBLOCKS][MAXPLAYERS+1];
new bool:g_bBhopButtonAvoid[MAX_BHOPBLOCKS];
new bool:g_bBhopButtonCollect[MAX_BHOPBLOCKS];
new bool:g_bBhopButtonClientAvoid[MAX_BHOPBLOCKS][MAXPLAYERS+1];
new bool:g_bBhopButtonClientCollect[MAX_BHOPBLOCKS][MAXPLAYERS+1];
new g_iBhopClientAvoid[MAXPLAYERS+1];
new g_iBhopAvoidMax;
new g_iBhopClientCollect[MAXPLAYERS+1];
new g_iBhopCollectMax;

//Min-/MaxVec Offsets
new g_iOffs_clrRender = -1;
new g_iOffs_vecOrigin = -1;
new g_iOffs_vecMins = -1;
new g_iOffs_vecMaxs = -1;
new g_iOffs_Velocity		= -1;

//Func_Door Offsets
new g_iDoorOffs_vecPosition1 = -1;
new g_iDoorOffs_vecPosition2 = -1;
new g_iDoorOffs_flSpeed = -1;
new g_iDoorOffs_spawnflags = -1;
new g_iDoorOffs_NoiseMoving = -1;
new g_iDoorOffs_sLockedSound = -1;
new g_iDoorOffs_bLocked = -1;

//Func_Button Offsets
new g_iButtonOffs_vecPosition1 = -1;
new g_iButtonOffs_vecPosition2 = -1;
new g_iButtonOffs_flSpeed = -1;
new g_iButtonOffs_spawnflags = -1;

//SDK Stuff
new Handle:g_hSDK_Touch = INVALID_HANDLE;

public Plugin:myinfo =
{
    name        = "[Timer] Physics",
    author      = "Zipcore, Alongub",
    description = "[Timer] Dynamic style/physic system",
    version     = PL_VERSION,
    url         = "forums.alliedmods.net/showthread.php?p=2074699"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RegPluginLibrary("timer-physics");
	
	CreateNative("Timer_GetForceStyle", Native_GetForceStyle);
	CreateNative("Timer_GetPickedStyle", Native_GetPickedStyle);
	CreateNative("Timer_ApplyPhysics", Native_ApplyPhysics);
	CreateNative("Timer_GetJumpAccuracy", Native_GetJumpAccuracy);
	CreateNative("Timer_GetCurrentSpeed", Native_GetCurrentSpeed);
	CreateNative("Timer_GetMaxSpeed", Native_GetMaxSpeed);
	CreateNative("Timer_GetAvgSpeed", Native_GetAvgSpeed);
	CreateNative("Timer_ResetAccuracy", Native_ResetAccuracy);

	g_bLateLoaded = late;
	
	return APLRes_Success;
}

public OnPluginStart()
{
	LoadPhysics();
	LoadTimerSettings();
	
	new Handle:hGameConf = INVALID_HANDLE;
	hGameConf = LoadGameConfigFile("sdkhooks.games");
	if(hGameConf == INVALID_HANDLE) 
	{
		SetFailState("GameConfigFile sdkhooks.games was not found");
		return;
	}
	
	LoadTranslations("timer.phrases");
	
	HookEvent("round_start",Event_RoundStart,EventHookMode_PostNoCopy);
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_jump", Event_PlayerJump);
	
	RegAdminCmd("sm_timer_reload_config", Command_ReloadConfig, ADMFLAG_CONVARS, "Reload timer settings");
	if(g_Settings[MultimodeEnable]) RegConsoleCmd("sm_style", Command_Difficulty);
	if(g_Settings[NoclipEnable]) RegConsoleCmd("sm_nc", Command_NoclipMe);
	if(g_Settings[NoclipEnable]) RegConsoleCmd("sm_noclipme", Command_NoclipMe);
	if(g_Settings[BhopEnable]) RegConsoleCmd("sm_tauto", Command_ToggleAuto);
	if(g_Settings[BhopEnable]) RegConsoleCmd("sm_autobhop", Command_ToggleAuto);
	if(g_Settings[BhopEnable]) RegConsoleCmd("sm_autojump", Command_ToggleAuto);
	RegAdminCmd("sm_colour", Command_Colour, ADMFLAG_RESERVATION);
	
	g_hPlattformColor = CreateConVar("timer_plattform_color", "0 255 0 255", "The color of detected plattforms.");
	
	HookConVarChange(g_hPlattformColor, Action_OnSettingsChange);
	
	AutoExecConfig(true, "timer/timer-physics");
	
	new String:buffer[32];
	GetConVarString(g_hPlattformColor, buffer, sizeof(buffer));
	ParseColor(buffer, g_PlattformColor);
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameConf,SDKConf_Virtual,"Touch");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity,SDKPass_Pointer);
	g_hSDK_Touch = EndPrepSDKCall();
	CloseHandle(hGameConf);

	if(g_hSDK_Touch == INVALID_HANDLE) 
	{
		SetFailState("Unable to prepare virtual function CBaseEntity::Touch");
		return;
	}

	g_iOffs_clrRender = FindSendPropInfo("CBaseEntity","m_clrRender");
	g_iOffs_vecOrigin = FindSendPropInfo("CBaseEntity","m_vecOrigin");
	g_iOffs_vecMins = FindSendPropInfo("CBaseEntity","m_vecMins");
	g_iOffs_vecMaxs = FindSendPropInfo("CBaseEntity","m_vecMaxs");
	g_iOffs_Velocity = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]");
	
	g_timerMapzones = LibraryExists("timer-mapzones");
	g_timerLjStats = LibraryExists("timer-ljstats");
	g_timerRankings = LibraryExists("timer-rankings");

	
	g_OnClientMaxJumpHeight = CreateGlobalForward("OnClientMaxJumpHeight", ET_Event, Param_Cell,Param_Cell);
	
	if(g_bLateLoaded) 
	{
		OnPluginPauseChange(false);
	}
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "timer-mapzones"))
	{
		g_timerMapzones = true;
	}		
	else if (StrEqual(name, "timer-ljstats"))
	{
		g_timerLjStats = true;
	}	
	else if (StrEqual(name, "timer-rankings"))
	{
		g_timerRankings = true;
	}		
}

public OnLibraryRemoved(const String:name[])
{	
	if (StrEqual(name, "timer-mapzones"))
	{
		g_timerMapzones = false;
	}		
	else if (StrEqual(name, "timer-ljstats"))
	{
		g_timerLjStats = false;
	}		
	else if (StrEqual(name, "timer-rankings"))
	{
		g_timerRankings = false;
	}		
}

public Action_OnSettingsChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if (cvar == g_hPlattformColor)
		ParseColor(newvalue, g_PlattformColor);
}

public OnPluginPauseChange(bool:pause) 
{
	if(pause) 
	{
		OnPluginEnd();
	}
	else
	{
		ResetMultiBhop();
	}
}

stock ResetMultiBhop()
{
	g_iBhopDoorCount = 0;
	g_iBhopButtonCount = 0;

	FindBhopBlocks();
	
	AlterBhopBlocks(true);

	g_iBhopDoorCount = 0;
	g_iBhopButtonCount = 0;
	FindBhopBlocks();
}

public Event_RoundStart(Handle:event,const String:name[],bool:dontBroadcast) 
{
	OnPluginPauseChange(false);
}

public OnPluginEnd() 
{
	AlterBhopBlocks(true);

	g_iBhopDoorCount = 0;
	g_iBhopButtonCount = 0;
}

public OnClientPutInServer(client)
{
	g_PlattformColorPlayer[client][0] = GetRandomInt(10, 245);
	g_PlattformColorPlayer[client][1] = GetRandomInt(10, 245);
	g_PlattformColorPlayer[client][2] = GetRandomInt(10, 245);
	g_PlattformColorPlayer[client][3] = 255;
	g_colourme[client] = 0;
	g_fBoost[client] = 0.0;
	
	ResetBhopAvoid(client);
	ResetBhopCollect(client);
}

public OnClientEndTouchZoneType(client, MapZoneType:zonetype)
{
	if(zonetype == ZtStart)
	{
		ResetStats(client);
	}
}

stock ResetStats(client)
{
	g_PlattformColorPlayer[client][0] = GetRandomInt(10, 245);
	g_PlattformColorPlayer[client][1] = GetRandomInt(10, 245);
	g_PlattformColorPlayer[client][2] = GetRandomInt(10, 245);
	g_PlattformColorPlayer[client][3] = 255;
	
	g_fSpeedCurrent[client] = 0.0;
	g_fSpeedMax[client] = 0.0;
	g_fSpeedTotal[client] = 0.0;
	g_iCommandCount[client] = 0;
}

Teleport(client, bhop, style)
{
	
	decl i;
	new tele = -1, ent = bhop;

	//search door trigger list
	for (i = 0; i < g_iBhopDoorCount; i++) 
	{
		if(ent == g_iBhopDoorList[i]) 
		{
			tele = g_iBhopDoorTeleList[i];
			break;
		}
	}

	//no destination? search button trigger list
	if(tele == -1) 
	{
		for (i = 0; i < g_iBhopButtonCount; i++) 
		{
			if(ent == g_iBhopButtonList[i]) 
			{
				tele = g_iBhopButtonTeleList[i];
				break;
			}
		}
	}

	//set teleport destination
	if(tele != -1 && IsValidEntity(tele) && g_Physics[style][StyleMultiBhop] != 2) 
	{
		SDKCall(g_hSDK_Touch,tele,client);
	}
}

public OnMapStart()
{
	LoadPhysics();
	LoadTimerSettings();
	
	if(!g_Settings[NoGravityUpdate]) CreateTimer(1.0, Timer_UpdateGravity, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	CreateTimer(0.1, Timer_CheckNoClip, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	
	g_iVegasWinCount = 0;
	
	ResetMultiBhop();
}

public OnMapEnd()
{
	AlterBhopBlocks(true);

	g_iBhopDoorCount = 0;
	g_iBhopButtonCount = 0;
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(0 < client <= MaxClients)
	{
		if(IsFakeClient(client))
			return;
		
		if(GetClientTeam(client) < 2)
			return;
		
		g_bPickedStyle[client] = false;
		
		if(g_StyleDefault == -1) Timer_LogError("PhysicsCFG: No default style found");
		else Timer_SetStyle(client, g_StyleDefault);	
		
		ApplyDifficulty(client);
		
		Timer_SetTrack(client, TRACK_NORMAL);

		if (g_Settings[StyleMenuOnSpawn])
		{
			FakeClientCommand(client, "sm_style");
		}
		
		if(g_Settings[TeleportOnSpawn])
		{
			FakeClientCommand(client, "sm_restart");
		}
	}
}

public Action:Event_PlayerJump(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	new Float:time = GetGameTime();
	
	new style = Timer_GetStyle(client);
	
	g_fLastJump[client] = time;
	
	GetClientAbsOrigin(client, g_fJumpLastCord[client]);
	
	if(g_fStamina[client] != -1.0)
	{
		SetEntPropFloat(client, Prop_Send, "m_flStamina", g_fStamina[client]);
	}
	
	if(g_Physics[style][StyleBoostForward] != 1.0)
		CreateTimer(0.0, Timer_Boost, client, TIMER_FLAG_NO_MAPCHANGE);
	
	if(g_Physics[style][StyleMaxSpeed] != 0.0)
	{
		CreateTimer(0.05, DelayedSlowDown, client);
	}
	
	if(g_Physics[style][StyleAntiBhop])
	{
		new Float:timediff = time - g_userJumps[client][LastJumpTimes][2];
		g_userJumps[client][LastJumpTimes][2] = g_userJumps[client][LastJumpTimes][1];
		g_userJumps[client][LastJumpTimes][1] = g_userJumps[client][LastJumpTimes][0];
		g_userJumps[client][LastJumpTimes][0] = time;
		
		if (timediff <= 3.0)
		{
			g_userJumps[client][LastJumpTimes][2] = 0.0;
			g_userJumps[client][LastJumpTimes][1] = 0.0;
			g_userJumps[client][LastJumpTimes][0] = 0.0;
			CreateTimer(0.05, DelayedSlowDownDefault, client);
		}
	}
	
	return Plugin_Continue;
}

public Action:DelayedSlowDown(Handle:timer, any:client)
{
	new style = Timer_GetStyle(client);
	CheckVelocity(client, 1, g_Physics[style][StyleMaxSpeed]);
}

public Action:DelayedSlowDownDefault(Handle:timer, any:client)
{
	CheckVelocity(client, 1, 1.0);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon, &subtype, &cmdnum, &tickcount, &seed, mouse[2])
{
	new iInitialButtons = buttons;
	
	if(!IsPlayerAlive(client))
		return Plugin_Continue;
	
	new style = Timer_GetStyle(client);
	new Float:fGameTime = GetGameTime();
	new bool:abuse = false;
	new bool:oldgroundstatus = g_bStayOnGround[client];
	new bool:onground = bool:(GetEntityFlags(client) & FL_ONGROUND);
	
	new Float:vecVelocity[3];
	GetEntDataVector(client, g_iOffs_Velocity, vecVelocity);
	
	new bool:GainHeight = false;
	
	if(g_fCord_Old[client][2] < g_fCord_New[client][2])
	{
		GainHeight = true;
	}
	
	decl Float:fVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity); //velocity
	new Float:currentspeed = SquareRoot(Pow(fVelocity[0],2.0)+Pow(fVelocity[1],2.0)); //player speed (units per secound)
	
	g_fSpeedTotal[client] += currentspeed;
	g_iCommandCount[client] ++;
	g_fSpeedCurrent[client] = currentspeed;
	
	if(currentspeed > g_fSpeedMax[client])
	{
		g_fSpeedMax[client] = currentspeed;
	}

	g_fCord_Old[client][0] = g_fCord_New[client][0];
	g_fCord_Old[client][1] = g_fCord_New[client][1];
	g_fCord_Old[client][2] = g_fCord_New[client][2];
	
	GetClientAbsOrigin(client, g_fCord_New[client]);
	
	if(g_fCord_Old[client][2] > g_fCord_New[client][2] && GainHeight)
	{
		Call_StartForward(g_OnClientMaxJumpHeight);
		Call_PushCell(client);
		Call_PushCell(g_fCord_Old[client][2]-g_fJumpLastCord[client][2]);
		Call_Finish();
	}
		
	if(!onground && !Client_IsOnLadder(client))
	{
		if(!Timer_IsPlayerTouchingZoneType(client, ZtFreeStyle))
		{
			if(g_Physics[style][StyleForceHalfSideways])
			{
				g_iMoveCount[client] = 0;
				
				new Float:fCheck_KeyCounts = 0.25;													//time after 2 buttons have to be pressed in seconds
				new Float:fReset_KeyHits = 3.00;													//time after keyhits are resetted in seconds
				new iCheck_Key_hits = 5;															//max keyhits allowed within "fCheck_KeyCounts" time
				
				
				new Float:fTickrate = 1.0 / GetTickInterval();										//get server tickrate
				new Float:fCheck_KeyCounts_ticks = fCheck_KeyCounts*fTickrate;						//calculate how many ticks has to be ticked to match "fCheck_KeyCounts" time
				
				if(buttons & IN_FORWARD)
				{
					g_iMoveCount[client]++;															//count how many keys are pressed
					g_fCount_FORWARD[client]++;														//counts up as long as the button is pressed
				}
				else
				{
					if(g_fCount_FORWARD[client] > 1.0 && g_fCount_FORWARD[client] < fCheck_KeyCounts_ticks)
					{
						g_iFORWARD_hits[client]++;													//counts up if key is pressed for a short time (on purpose)
					}
					g_fCount_FORWARD[client] = 0.0;													//reset count after key is released
				}
				
				if(buttons & IN_BACK)
				{
					g_iMoveCount[client]++;															//count how many keys are pressed
					g_fCount_BACK[client]++;														//counts up as long as the button is pressed
				}
				else
				{
					if(g_fCount_BACK[client] > 1.0 && g_fCount_BACK[client] < fCheck_KeyCounts_ticks)
					{
						g_iBACK_hits[client]++;														//counts up if key is pressed for a short time (on purpose)
					}
					g_fCount_BACK[client] = 0.0;													//reset count after key is released
				}
				
				if(buttons & IN_MOVELEFT)
				{
					g_iMoveCount[client]++;															//count how many keys are pressed
					g_fCount_MOVELEFT[client]++;													//counts up as long as the button is pressed
				}
				else
				{
					if(g_fCount_MOVELEFT[client] > 1.0 && g_fCount_MOVELEFT[client] < fCheck_KeyCounts_ticks)
					{
						g_iMOVELEFT_hits[client]++;													//counts up if key is pressed for a short time (on purpose)
					}
					g_fCount_MOVELEFT[client] = 0.0;												//reset count after key is released
				}
				
				if(buttons & IN_MOVERIGHT)
				{
					g_iMoveCount[client]++;															//count how many keys are pressed
					g_fCount_MOVERIGHT[client]++;													//counts up as long as the button is pressed
				}
				else
				{
					if(g_fCount_MOVERIGHT[client] > 1.0 && g_fCount_MOVERIGHT[client] < fCheck_KeyCounts_ticks)
					{
						g_iMOVERIGHT_hits[client]++;												//counts up if key is pressed for a short time (on purpose)
					}
					g_fCount_MOVERIGHT[client] = 0.0;												//reset count after key is released
				}
				
				g_fCount_Keys[client] = g_fCount_FORWARD[client]+g_fCount_BACK[client]+g_fCount_MOVELEFT[client]+g_fCount_MOVERIGHT[client];			//calculate time between button presses
				
				g_iKey_hits[client] = g_iFORWARD_hits[client]+g_iBACK_hits[client]+g_iMOVELEFT_hits[client]+g_iMOVERIGHT_hits[client];					//calculate all key hits
				
				if ((g_iMoveCount[client] == 1 && (g_fCount_Keys[client] >= fCheck_KeyCounts_ticks)) || (g_iKey_hits[client] >= iCheck_Key_hits))		//punish the client and reset keyhits/keycounts
				{
					abuse = true;
					g_fCount_FORWARD[client] = 0.0;
					g_fCount_BACK[client] = 0.0;
					g_fCount_MOVELEFT[client] = 0.0;
					g_fCount_MOVERIGHT[client] = 0.0;
					g_iFORWARD_hits[client] = 0;
					g_iBACK_hits[client] = 0;
					g_iMOVELEFT_hits[client] = 0;
					g_iMOVERIGHT_hits[client] = 0;
				}
				
				if (g_iMoveCount[client] == 2)														// reset keyhits/keycounts if 2 buttons are pressed
				{
					g_fCount_FORWARD[client] = 0.0;
					g_fCount_BACK[client] = 0.0;
					g_fCount_MOVELEFT[client] = 0.0;
					g_fCount_MOVERIGHT[client] = 0.0;
					g_iFORWARD_hits[client] = 0;
					g_iBACK_hits[client] = 0;
					g_iMOVELEFT_hits[client] = 0;
					g_iMOVERIGHT_hits[client] = 0;
				}
				
				g_iKey_hits_reset[client]++;
				if(g_iKey_hits_reset[client] > (fReset_KeyHits*fTickrate))									// reset keyhits
				{
					g_iFORWARD_hits[client] = 0;
					g_iBACK_hits[client] = 0;
					g_iMOVELEFT_hits[client] = 0;
					g_iMOVERIGHT_hits[client] = 0;
					g_iKey_hits_reset[client] = 0;
				}
			}
			
			if(g_Physics[style][StylePreventMoveleft])
			{
				if (buttons & IN_MOVELEFT || vel[1] < 0)
				{
					abuse = true;
				}
			}
			
			if(g_Physics[style][StylePreventMoveright])
			{
				if (buttons & IN_MOVERIGHT || vel[1] > 0)
				{
					abuse = true;
				}
			}
			
			if(g_Physics[style][StylePreventPlusleft])
			{
				if (buttons & IN_LEFT) //Can't disable
				{
					if(Timer_GetStatus(client) > 0)
					{
						abuse = true;
					}
				}
			}
			
			if(g_Physics[style][StylePreventPlusright])
			{
				if (buttons & IN_RIGHT) //Can't disable 
				{
					if(Timer_GetStatus(client) > 0)
					{
						abuse = true;
					}
				}
			}
			
			if(g_Physics[style][StylePreventMoveforward])
			{
				if (buttons & IN_FORWARD || vel[0] > 0)
				{
					abuse = true;
				}
			}
			
			if(g_Physics[style][StylePreventMoveback])
			{
				if (buttons & IN_BACK || vel[0] < 0)
				{
					abuse = true;
				}
			}
			
			if(g_Physics[style][StyleBlockMovementDirection] != 0)
			{
				//backwards
				if(g_Physics[style][StyleBlockMovementDirection] == 1)
				{
					if (GetClientMovingDirection(client) > 0.45)
					{
						abuse = true;
					}
				}
				//forward
				else if(g_Physics[style][StyleBlockMovementDirection] == 2)
				{
					if (GetClientMovingDirection(client) < -0.45)
					{
						abuse = true;
					}
				}
			}
		}
		
		if(g_Physics[style][StylePreventPlusleft])
		{
			if(buttons & IN_LEFT)
			{
				abuse = true;
			}
		}
		
		if(g_Physics[style][StylePreventPlusright])
		{
			if(buttons & IN_RIGHT)
			{
				abuse = true;
			}
		}
		
		if(g_Physics[style][StyleHoverScale] != 0.0)
		{
			if(fVelocity[2] < 0.0)
			{
				if((mouse[0] || mouse[1]))
				{
					Client_Push(client, Float:{-90.0,0.0,0.0}, g_Physics[style][StyleHoverScale], VelocityOverride:{VelocityOvr_None,VelocityOvr_None,VelocityOvr_None});
				}
			}
		}
	}
	
	if(abuse)
	{
		PunishAbuse(client);
	}
	else if(g_timerMapzones) 
	{
		if(!Timer_IsPlayerTouchingZoneType(client, ZtPushEast)
			&& !Timer_IsPlayerTouchingZoneType(client, ZtPushWest)
			&& !Timer_IsPlayerTouchingZoneType(client, ZtPushNorth)
			&& !Timer_IsPlayerTouchingZoneType(client, ZtPushSouth))
		{
			Block_MovementControl(client, true);
		}
	}
	else 
	{
		Block_MovementControl(client, true);
	}
	
	if (buttons & IN_JUMP)
	{
		new bool:boost = false;
		
		if(g_timerMapzones)
		{
			if(!Timer_IsPlayerTouchingZoneType(client, ZtNoBoost))
			{
				boost = true;
			}
		}
		else boost = true;
		
		if(boost && onground && g_fBoost[client] > 0.0)
		{
			g_bPushWait[client] = true;
			CreateTimer(0.0, Timer_Push, client, TIMER_FLAG_NO_MAPCHANGE);
		}
		
		if(!onground)
		{
			new auto = false;
			
			if(g_timerMapzones)
			{
				//Settings/Zone check
				if((g_bAuto[client] || Timer_IsPlayerTouchingZoneType(client, ZtAuto)) && !g_bAutoDisable[client] && !Timer_IsPlayerTouchingZoneType(client, ZtNoAuto))
				{
					auto = true;
				}
			}
			else auto = true;
			
			if(auto)
			{
				//Ladder check
				if (!Client_IsOnLadder(client))
				{
					//Wather check
					if (GetEntProp(client, Prop_Data, "m_nWaterLevel") <= 1)
					{
						buttons &= ~IN_JUMP;
					}
				}
			}
		}
	}

	// Player didn't jump immediately after the last jump.
	if (!(buttons & IN_JUMP) && onground && fCheckTime[client] > 0.0)
	{
		fCheckTime[client] = 0.0;
	}

	new oldjumps = g_iFullJumpCount[client];
	new bool:perfect = false;
		
	// Ignore this jump if the player is in a tight space or stuck in the ground.
	if ((buttons & IN_JUMP) && !abuse)
	{
		if(!(iPrevButtons[client] & IN_JUMP))
		{
			// Player is on the ground and about to trigger a jump.
			if (onground)
			{
				// Player jumped on the exact frame that allowed it.
				if (fCheckTime[client] > 0.0 && fGameTime >= fCheckTime[client])
				{
					perfect = true;
					g_iFullJumpCount[client]++;
					g_fJumpAccuracy[client] = 100-((100/g_Settings[MultiBhopDelay])*g_fFullJumpTimeAmount[client])/g_iFullJumpCount[client];
				}
				else
				{
					fCheckTime[client] = fGameTime + g_Settings[MultiBhopJumpTime];
				}	
			}
			else if(fCheckTime[client] != 0.0)
			{
				fCheckTime[client] = 0.0;
			}
		}
	}
	
	if(!abuse && !perfect)
	{
		//Save new on ground status
		if(onground) 
		{
			if(!g_bStayOnGround[client] && g_fBoost[client] > 0.0) 
			{
				//PrintToChat(client, "Ready to boost");
				g_bPushWait[client] = false;
			}
			
			g_bStayOnGround[client] = true;
		}
		else
		{
			g_bStayOnGround[client] = false;
		}
		
		//Player landed
		if(g_bStayOnGround[client] && g_bStayOnGround[client] != oldgroundstatus)
		{
			g_fLandedTime[client] = fGameTime;
		}
		
		//Player jumped
		if(!g_bStayOnGround[client] && g_bStayOnGround[client] != oldgroundstatus)
		{
			if(fGameTime-g_fLandedTime[client] < g_Settings[MultiBhopJumpTime])
			{
				g_iFullJumpCount[client]++;
			}
		}
		
		//Player has jumped? How good was his jump?
		if(oldjumps < g_iFullJumpCount[client]) //don't count first jump
		{
			if(fGameTime-g_fLandedTime[client] > g_Settings[MultiBhopDelay]) 
			{
				g_fFullJumpTimeAmount[client] += g_Settings[MultiBhopDelay];
			}
			else if(fGameTime-g_fLandedTime[client] > 0.0)
			{
				g_fFullJumpTimeAmount[client] += fGameTime-g_fLandedTime[client];
			}
			
			//update jump accuracy
			g_fJumpAccuracy[client] = 100-((100/g_Settings[MultiBhopDelay])*g_fFullJumpTimeAmount[client])/g_iFullJumpCount[client];
		}
	}
	
	iPrevButtons[client] = buttons;
	
	if(iInitialButtons != buttons)
		return Plugin_Changed;
    
	return Plugin_Continue;
}

public Action:Command_Difficulty(client, args)
{
	CreateDifficultyMenu(client);

	return Plugin_Handled;
}

CreatePhysicsMenu(client, MCategory:category)
{
	if(0 < client < MaxClients && g_Settings[MultimodeEnable])
	{
		new Handle:menu = CreateMenu(MenuHandler_Physics);

		if(category == MCategory_Ranked) SetMenuTitle(menu, "Ranked Styles", client);
		else if(category == MCategory_Fun) SetMenuTitle(menu, "Fun Styles", client);
		else if(category == MCategory_Practise) SetMenuTitle(menu, "Practise Styles", client);
		
		SetMenuExitBackButton(menu, true);
		SetMenuExitButton(menu, true);
		
		new count = 0;
		new found = 0;
		
		new maxorder[3] = {0, ...};

		for (new i = 0; i < MAX_STYLES-1; i++) 
		{
			if(!g_Physics[i][StyleEnable])
				continue;
			if(g_Physics[i][StyleCategory] != category)
				continue;
			
			if(g_Physics[i][StyleOrder] > maxorder[category])
				maxorder[category] = g_Physics[i][StyleOrder];
			
			count++;
		}
		
		for (new order = 0; order <= maxorder[category]; order++) 
		{
			for (new i = 0; i < MAX_STYLES-1; i++) 
			{
				if(!g_Physics[i][StyleEnable])
					continue;
				if(g_Physics[i][StyleCategory] != category)
					continue;
				if(g_Physics[i][StyleOrder] != order)
					continue;
				
				found++;
				
				new String:buffer[8];
				IntToString(i, buffer, sizeof(buffer));
				
				AddMenuItem(menu, buffer, g_Physics[i][StyleName]);
			}
			
			if(found == count)
				break;
		}

		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

public MenuHandler_Physics(Handle:menu, MenuAction:action, client, itemNum)
{
	if (action == MenuAction_End) 
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel) 
	{
		if (itemNum == MenuCancel_ExitBack) 
		{
			if(IsClientInGame(client)) FakeClientCommand(client, "sm_style");
		}
	} 
	else if ( action == MenuAction_Select )
	{
		decl String:info[100], String:info2[100];
		new bool:found = GetMenuItem(menu, itemNum, info, sizeof(info), _, info2, sizeof(info2));
		if(found)
		{
			new style = StringToInt(info);
			
			if(0 <= style < MAX_STYLES-1 && g_Physics[style][StyleEnable])
			{
				if((g_iBhopButtonCount == 0 && g_iBhopDoorCount == 0) && g_Physics[style][StyleMultiBhop] > 0)
				{
					CPrintToChat(client, "%s Multihop and Nohop are not available on this map.", PLUGIN_PREFIX2);
					if(IsClientInGame(client)) FakeClientCommand(client, "sm_style");
				}
				else
				{
					g_bPickedStyle[client] = true;
					Timer_SetStyle(client, style);
					
					if(g_Physics[style][StyleCustom])
					{
						CreateCustomMenu(client);
					}
				}
			}
			else
			{
				if(IsClientInGame(client)) FakeClientCommand(client, "sm_style");
			}
		}
	}
}

CreateDifficultyMenu(client)
{
	if(0 < client < MaxClients && g_Settings[MultimodeEnable])
	{
		if(g_StyleCountEnabled > 0)
		{
			if(g_StyleCountRankedEnabled > 0 && g_StyleCountFunEnabled <= 0 && g_StyleCountPractiseEnabled <= 0)
			{
				//Skip category menu if there are only ranked styles available
				CreatePhysicsMenu(client, MCategory_Ranked);
			}
			else
			{
				new Handle:menu = CreateMenu(MenuHandler_Difficulty);

				SetMenuTitle(menu, "Styles", client);
				SetMenuExitButton(menu, true);
				
				if(g_StyleCountRankedEnabled > 0)
				{
					AddMenuItem(menu, "timed", "Ranked Styles");
				}
				if(g_StyleCountFunEnabled > 0)
				{
					AddMenuItem(menu, "fun", "Fun Styles");
				}
				if(g_StyleCountPractiseEnabled > 0)
				{
					AddMenuItem(menu, "practise", "Practise Styles");
				}
				
				AddMenuItem(menu, "main", "Back");
				
				DisplayMenu(menu, client, MENU_TIME_FOREVER);
			}
		}
		else CPrintToChatAll("%s No styles enabled.", PLUGIN_PREFIX2);
	}
}

public MenuHandler_Difficulty(Handle:menu, MenuAction:action, client, itemNum)
{
	if (action == MenuAction_End) 
	{
		CloseHandle(menu);
	}
	else if ( action == MenuAction_Select )
	{
		decl String:info[100], String:info2[100];
		new bool:found = GetMenuItem(menu, itemNum, info, sizeof(info), _, info2, sizeof(info2));
		if(found)
		{
			if(StrEqual(info, "timed"))
			{
				CreatePhysicsMenu(client, MCategory:MCategory_Ranked);
			}
			else if(StrEqual(info, "fun"))
			{
				CreatePhysicsMenu(client, MCategory:MCategory_Fun);
			}
			else if(StrEqual(info, "practise"))
			{
				CreatePhysicsMenu(client, MCategory:MCategory_Practise);
			}
			else if(StrEqual(info, "custom"))
			{
				CreateCustomMenu(client);
			}
			else if(StrEqual(info, "settings"))
			{
				CreateSettingsMenu(client);
			}
			else if(StrEqual(info, "main"))
			{
				if(IsClientInGame(client)) FakeClientCommand(client, "sm_menu");
			}
			else
			{
				if(IsClientInGame(client)) FakeClientCommand(client, "sm_style");
			}
		}
	}
}

CreateSettingsMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_Settings);

	SetMenuTitle(menu, "Timer Settings");
	SetMenuExitButton(menu, true);

	if(!g_bCustomAuto[client]) AddMenuItem(menu, "enable_autojump", "Enable Auto-Jump");
	else  AddMenuItem(menu, "disable_autojump", "Disable Auto-Jump");

	if(!g_bCustomAuto[client]) AddMenuItem(menu, "enable_autobhop", "Enable Auto-Bhop");
	else  AddMenuItem(menu, "disable_autobhop", "Disable Auto-Bhop");

	if(!g_bCustomAuto[client]) AddMenuItem(menu, "enable_autorestart", "Enable Auto-Restart");
	else  AddMenuItem(menu, "disable_autorestart", "Disable Auto-Restart");

	if(!g_bCustomAuto[client]) AddMenuItem(menu, "enable_autohide", "Enable Auto-Hide");
	else  AddMenuItem(menu, "disable_autohide", "Disable Auto-Hide");

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

//ASDFASFWDGEWRG
public MenuHandler_Settings(Handle:menu, MenuAction:action, client, itemNum)
{
	if(0 < client < MaxClients)
	{
		if (action == MenuAction_End) 
		{
			if(IsClientConnected(client)) FakeClientCommand(client, "sm_style");
		}
		else if ( action == MenuAction_Select )
		{
			if(GetClientTeam(client) < 2)
			{
				
			}
			else
			{
				decl String:info[100], String:info2[100];
				new bool:found = GetMenuItem(menu, itemNum, info, sizeof(info), _, info2, sizeof(info2));
				if(found)
				{
					if(StrEqual(info, "enable_auto"))
					{
						g_bCustomAuto[client] = true;
					}
					else if(StrEqual(info, "disable_auto"))
					{
						g_bCustomAuto[client] = false;
					}
					else if(StrEqual(info, "enable_boost"))
					{
						g_bCustomBoost[client] = true;
					}
					else if(StrEqual(info, "disable_boost"))
					{
						g_bCustomBoost[client] = false;
					}
					else if(StrEqual(info, "enable_stamina"))
					{
						g_bCustomFullStamina[client] = true;
					}
					else if(StrEqual(info, "disable_stamina"))
					{
						g_bCustomFullStamina[client] = false;
					}
					else if(StrEqual(info, "enable_lowgravity"))
					{
						g_bCustomLowGravity[client] = true;
					}
					else if(StrEqual(info, "disable_lowgravity"))
					{
						g_bCustomLowGravity[client] = false;
					}
					
					CreateSettingsMenu(client);
					
					ApplyDifficulty(client);
				}
			}
		}
		else
		{
			if(IsClientConnected(client)) FakeClientCommand(client, "sm_style");
		}
	}
}

CreateCustomMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_Custom);

	SetMenuTitle(menu, "Custom Settings");
	SetMenuExitButton(menu, true);

	if(!g_bCustomAuto[client]) AddMenuItem(menu, "enable_auto", "Enable Auto-Mode");
	else  AddMenuItem(menu, "disable_auto", "Disable Auto-Mode");
	
	if(!g_bCustomBoost[client]) AddMenuItem(menu, "enable_boost", "Enable Jump Height Boost");
	else  AddMenuItem(menu, "disable_boost", "Disable Jump Height Boost");
	
	if(!g_bCustomFullStamina[client]) AddMenuItem(menu, "enable_stamina", "Enable Speed Loss (Stamina)");
	else  AddMenuItem(menu, "disable_stamina", "Disable Speed Loss (Stamina)");
	
	if(!g_bCustomLowGravity[client]) AddMenuItem(menu, "enable_lowgravity", "Enable Low Gravity");
	else  AddMenuItem(menu, "disable_lowgravity", "Disable Low Gravity");

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_Custom(Handle:menu, MenuAction:action, client, itemNum)
{
	if(0 < client < MaxClients)
	{
		if (action == MenuAction_End) 
		{
			if(IsClientConnected(client)) FakeClientCommand(client, "sm_bhop");
		}
		else if ( action == MenuAction_Select )
		{
			if(GetClientTeam(client) < 2)
			{
				
			}
			else
			{
				decl String:info[100], String:info2[100];
				new bool:found = GetMenuItem(menu, itemNum, info, sizeof(info), _, info2, sizeof(info2));
				if(found)
				{
					if(StrEqual(info, "enable_auto"))
					{
						g_bCustomAuto[client] = true;
					}
					else if(StrEqual(info, "disable_auto"))
					{
						g_bCustomAuto[client] = false;
					}
					else if(StrEqual(info, "enable_boost"))
					{
						g_bCustomBoost[client] = true;
					}
					else if(StrEqual(info, "disable_boost"))
					{
						g_bCustomBoost[client] = false;
					}
					else if(StrEqual(info, "enable_stamina"))
					{
						g_bCustomFullStamina[client] = true;
					}
					else if(StrEqual(info, "disable_stamina"))
					{
						g_bCustomFullStamina[client] = false;
					}
					else if(StrEqual(info, "enable_lowgravity"))
					{
						g_bCustomLowGravity[client] = true;
					}
					else if(StrEqual(info, "disable_lowgravity"))
					{
						g_bCustomLowGravity[client] = false;
					}
					
					CreateCustomMenu(client);
					
					ApplyDifficulty(client);
				}
			}
		}
		else
		{
			if(IsClientConnected(client)) FakeClientCommand(client, "sm_bhop");
		}
	}
}

ApplyDifficulty(client)
{
	if (IsClientInGame(client) && IsClientConnected(client) && !IsClientSourceTV(client))
	{
		new style = Timer_GetStyle(client);
		
		if(g_Physics[style][StyleCustom])
		{
			if(g_bCustomFullStamina[client]) g_fStamina[client] = STAMINA_FULL;
			else  g_fStamina[client] = STAMINA_DISABLED;
			
			if(g_bCustomBoost[client]) g_fBoost[client] = g_Physics[style][StyleBoost];
			else  g_fBoost[client] = 0.0;
			
			g_bAuto[client] = g_bCustomAuto[client];
		}
		else
		{
			g_fStamina[client] = g_Physics[style][StyleStamina];
			g_bAuto[client] = g_Physics[style][StyleAuto];
			g_fBoost[client] = g_Physics[style][StyleBoost];
		}
		
		//only allow on normal
		if(!g_Physics[style][StyleLJStats] && g_timerLjStats)
		{
			SetLJMode(client, false);
		}
		
		//stop timer
		Timer_Stop(client);
		
		SetEntityGravity(client, g_Physics[style][StyleGravity]);
		
		//stop him
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, Float:{0.0,0.0,-100.0});
		
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", g_Physics[style][StyleTimeScale]);
		
		SetEntProp(client, Prop_Send, "m_iFOV", g_Physics[style][StyleFOV]);
		SetEntProp(client, Prop_Send, "m_iDefaultFOV", g_Physics[style][StyleFOV]);
		
		decl String:auth[32];
		GetClientAuthString(client, auth, sizeof(auth));
		
		if(StrEqual(g_Physics[style][StyleDesc], ""))
		{
			
		}
		else
		{
			CPrintToChat(client, "%s %s", PLUGIN_PREFIX2, g_Physics[style][StyleDesc]);
		}
		
		if(g_Settings[TeleportOnStyleChanged])
		{
			if(Timer_GetTrack(client) == TRACK_BONUS)
				FakeClientCommand(client, "sm_b");
			else FakeClientCommand(client, "sm_start");
		}
	}
}

public Native_GetPickedStyle(Handle:plugin, numParams)
{
	return g_bPickedStyle[GetNativeCell(1)];
}

public Native_GetJumpAccuracy(Handle:plugin, numParams)
{
	SetNativeCellRef(2, g_fJumpAccuracy[GetNativeCell(1)]);
}

public Native_GetCurrentSpeed(Handle:plugin, numParams)
{
	SetNativeCellRef(2, g_fSpeedCurrent[GetNativeCell(1)]);
}

public Native_GetMaxSpeed(Handle:plugin, numParams)
{
	SetNativeCellRef(2, g_fSpeedMax[GetNativeCell(1)]);
}

public Native_GetAvgSpeed(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	if(g_iCommandCount[client] <= 0)
		return false;
	
	SetNativeCellRef(2, g_fSpeedTotal[client]/g_iCommandCount[client]);
	return true;
}

public Native_GetForceStyle(Handle:plugin, numParams)
{
	return g_Settings[ForceStyle];
}

public Native_ApplyPhysics(Handle:plugin, numParams)
{
	ApplyDifficulty(GetNativeCell(1));
}

public Native_ResetAccuracy(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	g_fFullJumpTimeAmount[client] = 0.0;
	g_iFullJumpCount[client] = 0;
}

stock SetThirdPersonView(client, bool:third)
{
	if(third)
	{
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", 0); 
		SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
	}
	else if(!third)
	{
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", -1);
		SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
	}
}

public Entity_Touch(bhop,client) 
{
	new doorID = GetBhopDoorID(bhop);
	new buttonID = GetBhopButtonID(bhop);
	
	//bhop = entity
	if(0 < client <= MaxClients) 
	{
		new style = Timer_GetStyle(client);
		
		if(g_Settings[VegasEnable])
		{
			new bool:avoid;
			
			if(doorID != -1 && g_bBhopDoorAvoid[doorID])
			{
				if(!g_bBhopDoorClientAvoid[doorID][client])
				{
					g_bBhopDoorClientAvoid[doorID][client] = true;
					avoid = true;
					if(g_iBhopClientAvoid[client] == 1) 
						CPrintToChat(client, "%s You failed vegas mission. You need to restart to collect all vegas plattforms.", PLUGIN_PREFIX2);
				}
			}
			else if(buttonID != -1  && g_bBhopButtonAvoid[buttonID])
			{
				if(!g_bBhopButtonClientAvoid[buttonID][client])
				{
					g_bBhopButtonClientAvoid[buttonID][client] = true;
					avoid = true;
					if(g_iBhopClientAvoid[client] == 1) 
						CPrintToChat(client, "%s You failed vegas mission. You need to restart to collect all vegas plattforms.", PLUGIN_PREFIX2);
				}
			}
			
			if(avoid)
			{
				g_iBhopClientAvoid[client]++;
				
				ResetBhopCollect(client);
			}
			
			new bool:collect;
			
			if(doorID != -1  && g_bBhopDoorCollect[doorID])
			{
				if(!g_bBhopDoorClientCollect[doorID][client])
				{
					g_bBhopDoorClientCollect[doorID][client] = true;
					collect = true;
				}
			}
			else if(buttonID != -1 && g_bBhopButtonCollect[buttonID])
			{
				if(!g_bBhopButtonClientCollect[buttonID][client])
				{
					g_bBhopButtonClientCollect[buttonID][client] = true;
					collect = true;
				}
			}
			
			if(collect)
			{
				g_iBhopClientCollect[client]++;
				
				if(GetBhopCollectComplete(client))
				{
					g_iVegasWinCount++;
					
					if(g_timerRankings)
					{
						Timer_AddPoints(client, g_Settings[PointsVegas]+(g_Settings[PointsVegasAdd]*g_iVegasWinCount));
						Timer_SavePoints(client);
						CPrintToChatAll("%s %N Collected all vegas plattforms and got %d points for completing vegas mission.", PLUGIN_PREFIX2, client, g_Settings[PointsVegasAdd]*g_iVegasWinCount);
						AlterBhopBlocks(true);
						AlterBhopBlocks(false);
					}
				
					if(g_iVegasWinCount >= g_Settings[VegasMapMaxGames])
					{
						CPrintToChatAll("%s This was the last vegas mission until mapchange!", PLUGIN_PREFIX2);
					}
				}
				else
				{
					PrintCenterText(client, "%d/%d", g_iBhopClientCollect[client], g_iBhopCollectMax);
				}
			}
		}
		
		static Float:flPunishTime[MAXPLAYERS + 1], iLastBlock[MAXPLAYERS + 1] = { -1,... };
		
		new Float:time = GetGameTime();
		
		new Float:diff = time - flPunishTime[client];
		
		if ((GetUserFlagBits(client) & ADMFLAG_RESERVATION) && g_colourme[client])
		{
			SetEntDataArray(bhop, g_iOffs_clrRender , g_PlattformColorPlayer[client], 4, 1, true);
			CreateTimer(0.5, RemoveColouredBlocks,bhop);
		}
		
		if(iLastBlock[client] != bhop || diff > g_Settings[MultiBhopCooldown]) 
		{
			//reset cooldown
			iLastBlock[client] = bhop;
			flPunishTime[client] = time + g_Settings[MultiBhopDelay];
			
		}
		else if(diff > g_Settings[MultiBhopDelay]) 
		{
			if(g_Physics[style][StyleMultiBhop] == 1 && time - g_fLastJump[client] > (g_Settings[MultiBhopCooldown] + g_Settings[MultiBhopDelay]))
			{
				Teleport(client, iLastBlock[client], style);
				iLastBlock[client] = -1;
			}
			else if(g_Physics[style][StyleMultiBhop] != 1)
			{
				Teleport(client, iLastBlock[client], style);
				iLastBlock[client] = -1;
			}
		}
	}
}

public Action:RemoveColouredBlocks(Handle:timer, any:bhop)
{
	new colour[4] = {255,255,255,255};
	SetEntDataArray(bhop, g_iOffs_clrRender , colour, 4, 1, true);
}

FindBhopBlocks() 
{
	if(g_Settings[MultiBhopEnable])
	{
		decl Float:startpos[3], Float:endpos[3], Float:mins[3], Float:maxs[3], tele;
		new ent = -1;

		while((ent = FindEntityByClassname(ent,"func_door")) != -1) 
		{
			if(g_iDoorOffs_vecPosition1 == -1) 
			{
				g_iDoorOffs_vecPosition1 = FindDataMapOffs(ent,"m_vecPosition1");
				g_iDoorOffs_vecPosition2 = FindDataMapOffs(ent,"m_vecPosition2");
				g_iDoorOffs_flSpeed = FindDataMapOffs(ent,"m_flSpeed");
				g_iDoorOffs_spawnflags = FindDataMapOffs(ent,"m_spawnflags");
				g_iDoorOffs_NoiseMoving = FindDataMapOffs(ent,"m_NoiseMoving");
				g_iDoorOffs_sLockedSound = FindDataMapOffs(ent,"m_ls.sLockedSound");
				g_iDoorOffs_bLocked = FindDataMapOffs(ent,"m_bLocked");
			}

			GetEntDataVector(ent,g_iDoorOffs_vecPosition1,startpos);
			GetEntDataVector(ent,g_iDoorOffs_vecPosition2,endpos);

			if(startpos[2] > endpos[2]) 
			{
				GetEntDataVector(ent,g_iOffs_vecMins,mins);
				GetEntDataVector(ent,g_iOffs_vecMaxs,maxs);

				startpos[0] += (mins[0] + maxs[0]) * 0.5;
				startpos[1] += (mins[1] + maxs[1]) * 0.5;
				startpos[2] += maxs[2];

				if((tele = CustomTraceForTeleports(startpos,endpos[2] + maxs[2])) != -1) 
				{
					g_iBhopDoorList[g_iBhopDoorCount] = ent;
					g_iBhopDoorTeleList[g_iBhopDoorCount] = tele;

					if(++g_iBhopDoorCount == sizeof g_iBhopDoorList) 
					{
						break;
					}
				}
			}
		}

		ent = -1;

		while((ent = FindEntityByClassname(ent,"func_button")) != -1) 
		{
			if(g_iButtonOffs_vecPosition1 == -1) 
			{
				g_iButtonOffs_vecPosition1 = FindDataMapOffs(ent,"m_vecPosition1");
				g_iButtonOffs_vecPosition2 = FindDataMapOffs(ent,"m_vecPosition2");
				g_iButtonOffs_flSpeed = FindDataMapOffs(ent,"m_flSpeed");
				g_iButtonOffs_spawnflags = FindDataMapOffs(ent,"m_spawnflags");
			}

			GetEntDataVector(ent,g_iButtonOffs_vecPosition1,startpos);
			GetEntDataVector(ent,g_iButtonOffs_vecPosition2,endpos);

			if(startpos[2] > endpos[2] && (GetEntData(ent,g_iButtonOffs_spawnflags,4) & SF_BUTTON_TOUCH_ACTIVATES)) 
			{
				GetEntDataVector(ent,g_iOffs_vecMins,mins);
				GetEntDataVector(ent,g_iOffs_vecMaxs,maxs);

				startpos[0] += (mins[0] + maxs[0]) * 0.5;
				startpos[1] += (mins[1] + maxs[1]) * 0.5;
				startpos[2] += maxs[2];

				if((tele = CustomTraceForTeleports(startpos,endpos[2] + maxs[2])) != -1) 
				{
					g_iBhopButtonList[g_iBhopButtonCount] = ent;
					g_iBhopButtonTeleList[g_iBhopButtonCount] = tele;

					if(++g_iBhopButtonCount == sizeof g_iBhopButtonList) 
					{
						break;
					}
				}
			}
		}
		AlterBhopBlocks(false);
	}
}

stock GetBhopDoorID(entity)
{
	for (new i = 0; i < g_iBhopDoorCount; i++) 
	{
		if(entity == g_iBhopDoorList[i])
			return i;
	}
	
	return -1;
}

stock GetBhopButtonID(entity)
{
	for (new i = 0; i < g_iBhopButtonCount; i++) 
	{
		if(entity == g_iBhopButtonList[i])
			return i;
	}
	
	return -1;
}

stock bool:GetBhopAvoidComplete(client)
{
	for (new i = 0; i < g_iBhopDoorCount; i++) 
	{
		if(!g_bBhopDoorAvoid[i])
			continue;
		
		if(g_bBhopDoorClientAvoid[i][client])
			return false;
	}
	
	for (new i = 0; i < g_iBhopButtonCount; i++) 
	{
		if(!g_bBhopButtonAvoid[i])
			continue;
		
		if(g_bBhopButtonClientAvoid[i][client])
			return false;
	}
	
	return true;
}

stock bool:GetBhopCollectComplete(client)
{
	for (new i = 0; i < g_iBhopDoorCount; i++) 
	{
		if(!g_bBhopDoorCollect[i])
			continue;
		
		if(!g_bBhopDoorClientCollect[i][client])
			return false;
	}
	
	for (new i = 0; i < g_iBhopButtonCount; i++) 
	{
		if(!g_bBhopButtonCollect[i])
			continue;
		
		if(!g_bBhopButtonClientCollect[i][client])
			return false;
	}
	
	return true;
}

stock ResetBhopAvoid(client)
{
	g_iBhopClientAvoid[client] = 0;
	
	for (new i = 0; i < g_iBhopDoorCount; i++) 
	{
		g_bBhopDoorClientAvoid[i][client] = false;
		g_bBhopButtonClientAvoid[i][client] = false;
	}
}

stock ResetBhopCollect(client)
{
	g_iBhopClientCollect[client] = 0;
	
	for (new i = 0; i < g_iBhopDoorCount; i++) 
	{
		g_bBhopDoorClientCollect[i][client] = false;
		g_bBhopButtonClientCollect[i][client] = false;
	}
}

AlterBhopBlocks(bool:bRevertChanges) 
{
	if(g_Settings[MultiBhopEnable])
	{
		static Float:vecDoorPosition2[sizeof g_iBhopDoorList][3];
		static Float:flDoorSpeed[sizeof g_iBhopDoorList];
		static iDoorSpawnflags[sizeof g_iBhopDoorList];
		static bool:bDoorLocked[sizeof g_iBhopDoorList];

		static Float:vecButtonPosition2[sizeof g_iBhopButtonList][3];
		static Float:flButtonSpeed[sizeof g_iBhopButtonList];
		static iButtonSpawnflags[sizeof g_iBhopButtonList];

		decl ent, i;

		if(bRevertChanges) 
		{
			g_iBhopCollectMax = 0;
			g_iBhopAvoidMax = 0;
			
			for (i = 0; i < g_iBhopDoorCount; i++) 
			{
				ent = g_iBhopDoorList[i];
				g_bBhopDoorAvoid[i] = false;
				g_bBhopDoorCollect[i] = false;

				for (new client = 1; client <= MaxClients; client++)
				{
					g_bBhopDoorClientAvoid[i][client] = false;
					g_bBhopDoorClientCollect[i][client] = false;
				}
				
				if(IsValidEntity(ent)) 
				{
					SetEntDataArray(ent, g_iOffs_clrRender , {255, 255, 255, 255}, 4, 1, true);
					SetEntDataVector(ent,g_iDoorOffs_vecPosition2,vecDoorPosition2[i]);
					SetEntDataFloat(ent,g_iDoorOffs_flSpeed,flDoorSpeed[i]);
					SetEntData(ent,g_iDoorOffs_spawnflags,iDoorSpawnflags[i],4);
					
					if(!bDoorLocked[i]) 
					{
						AcceptEntityInput(ent,"Unlock");
					}

					SDKUnhook(ent,SDKHook_Touch,Entity_Touch);
				}
			}

			for (i = 0; i < g_iBhopButtonCount; i++) 
			{
				ent = g_iBhopButtonList[i];
				
				g_bBhopButtonAvoid[i] = false;
				g_bBhopButtonCollect[i] = false;

				for (new client = 1; client <= MaxClients; client++)
				{
					g_bBhopButtonClientAvoid[i][client] = false;
					g_bBhopButtonClientCollect[i][client] = false;
				}
				
				if(IsValidEntity(ent)) 
				{
					SetEntDataArray(ent, g_iOffs_clrRender , {255, 255, 255, 255}, 4, 1, true);
					SetEntDataVector(ent,g_iButtonOffs_vecPosition2,vecButtonPosition2[i]);
					SetEntDataFloat(ent,g_iButtonOffs_flSpeed,flButtonSpeed[i]);
					SetEntData(ent,g_iButtonOffs_spawnflags,iButtonSpawnflags[i],4);

					SDKUnhook(ent,SDKHook_Touch,Entity_Touch);
				}
			}
		}
		else 
		{
			g_iBhopCollectMax = 0;
			g_iBhopAvoidMax = 0;
			
			g_PlattformColorAvoid[0] = 255;
			g_PlattformColorAvoid[1] = 0;
			g_PlattformColorAvoid[2] = 0;
			g_PlattformColorAvoid[3] = 255;
			
			g_PlattformColorCollect[0] = 0;
			g_PlattformColorCollect[1] = 255;
			g_PlattformColorCollect[2] = 0;
			g_PlattformColorCollect[3] = 255;
			
			new Float:random;
			
			//note: This only gets called directly after finding the blocks, so the entities are valid.
			decl Float:startpos[3];

			for (i = 0; i < g_iBhopDoorCount; i++) 
			{
				ent = g_iBhopDoorList[i];
				
				if(g_Settings[VegasEnable] && g_Settings[VegasMinPlattfors] <= g_iBhopDoorCount+g_iBhopButtonCount && (g_iVegasWinCount < g_Settings[VegasMapMaxGames] || g_Settings[VegasMapMaxGames] == 0))
				{
					for (new client = 1; client <= MaxClients; client++)
					{
						g_bBhopDoorClientAvoid[i][client] = false;
						g_bBhopDoorClientCollect[i][client] = false;
						g_iBhopClientAvoid[client] = 0;
						g_iBhopClientCollect[client] = 0;
					}

					random = GetRandomFloat(0.0, 100.0);
					
					new Float:avoidchance = g_Settings[VegasAvoidChance]+(g_Settings[VegasAvoidChanceAdd]*g_iVegasWinCount);
					
					if(random < avoidchance) 
					{
						g_bBhopDoorAvoid[i] = true;
						g_iBhopAvoidMax++;
						SetEntDataArray(ent, g_iOffs_clrRender , g_PlattformColorAvoid, 4, 1, true);
					}
					else if(random < avoidchance+g_Settings[VegasCollectChance]+(g_Settings[VegasCollectChanceAdd]*g_iVegasWinCount)) 
					{
						g_bBhopDoorCollect[i] = true;
						g_iBhopCollectMax++;
						SetEntDataArray(ent, g_iOffs_clrRender , g_PlattformColorCollect, 4, 1, true);
					}
				}
					
				GetEntDataVector(ent,g_iDoorOffs_vecPosition2,vecDoorPosition2[i]);
				flDoorSpeed[i] = GetEntDataFloat(ent,g_iDoorOffs_flSpeed);
				iDoorSpawnflags[i] = GetEntData(ent,g_iDoorOffs_spawnflags,4);
				bDoorLocked[i] = GetEntData(ent,g_iDoorOffs_bLocked,1) ? true : false;

				GetEntDataVector(ent,g_iDoorOffs_vecPosition1,startpos);
				SetEntDataVector(ent,g_iDoorOffs_vecPosition2,startpos);

				SetEntDataFloat(ent,g_iDoorOffs_flSpeed,0.0);
				SetEntData(ent,g_iDoorOffs_spawnflags,SF_DOOR_PTOUCH,4);
				AcceptEntityInput(ent,"Lock");

				SetEntData(ent,g_iDoorOffs_sLockedSound,GetEntData(ent,g_iDoorOffs_NoiseMoving,4),4);

				SDKHook(ent,SDKHook_Touch,Entity_Touch);
			}

			for (i = 0; i < g_iBhopButtonCount; i++) 
			{
				ent = g_iBhopButtonList[i];

				if(g_Settings[VegasEnable] && g_Settings[VegasMinPlattfors] <= g_iBhopDoorCount+g_iBhopButtonCount && g_iVegasWinCount < g_Settings[VegasMapMaxGames])
				{
					for (new client = 1; client <= MaxClients; client++)
					{
						g_bBhopButtonClientAvoid[i][client] = false;
						g_bBhopButtonClientCollect[i][client] = false;
						g_iBhopClientAvoid[client] = 0;
						g_iBhopClientCollect[client] = 0;
					}

					random = GetRandomFloat(0.0, 100.0);
					
					if(random < g_Settings[VegasAvoidChance]) 
					{
						SetEntDataArray(ent, g_iOffs_clrRender , g_PlattformColorAvoid, 4, 1, true);
						g_iBhopAvoidMax++;
						g_bBhopButtonAvoid[i] = true;
					}
					else if(random < g_Settings[VegasCollectChance]+g_Settings[VegasAvoidChance]) 
					{
						SetEntDataArray(ent, g_iOffs_clrRender , g_PlattformColorCollect, 4, 1, true);
						g_iBhopCollectMax++;
						g_bBhopButtonCollect[i] = true;
					}
				}

				GetEntDataVector(ent,g_iButtonOffs_vecPosition2,vecButtonPosition2[i]);
				flButtonSpeed[i] = GetEntDataFloat(ent,g_iButtonOffs_flSpeed);
				iButtonSpawnflags[i] = GetEntData(ent,g_iButtonOffs_spawnflags,4);

				GetEntDataVector(ent,g_iButtonOffs_vecPosition1,startpos);
				SetEntDataVector(ent,g_iButtonOffs_vecPosition2,startpos);

				SetEntDataFloat(ent,g_iButtonOffs_flSpeed,0.0);
				SetEntData(ent,g_iButtonOffs_spawnflags,SF_BUTTON_DONTMOVE|SF_BUTTON_TOUCH_ACTIVATES,4);

				SDKHook(ent,SDKHook_Touch,Entity_Touch);
			}
		}
	}
}

CustomTraceForTeleports(const Float:startpos[3],Float:endheight,Float:step=1.0) 
{
	decl teleports[512];
	new tpcount, ent = -1;

	while((ent = FindEntityByClassname(ent,"trigger_teleport")) != -1 && tpcount != sizeof teleports) 
	{
		teleports[tpcount++] = ent;
	}

	decl Float:mins[3], Float:maxs[3], Float:origin[3], i;

	origin[0] = startpos[0];
	origin[1] = startpos[1];
	origin[2] = startpos[2];

	do {
		for (i = 0; i < tpcount; i++) 
		{
			ent = teleports[i];
			GetAbsBoundingBox(ent,mins,maxs);

			if(mins[0] <= origin[0] <= maxs[0] && mins[1] <= origin[1] <= maxs[1] && mins[2] <= origin[2] <= maxs[2]) 
			{
				return ent;
			}
		}

		origin[2] -= step;
	} while(origin[2] >= endheight);

	return -1;
}

GetAbsBoundingBox(ent,Float:mins[3],Float:maxs[3]) 
{
	decl Float:origin[3];

	GetEntDataVector(ent,g_iOffs_vecOrigin,origin);
	GetEntDataVector(ent,g_iOffs_vecMins,mins);
	GetEntDataVector(ent,g_iOffs_vecMaxs,maxs);

	mins[0] += origin[0];
	mins[1] += origin[1];
	mins[2] += origin[2];

	maxs[0] += origin[0];
	maxs[1] += origin[1];
	maxs[2] += origin[2];
}

public Action:Timer_UpdateGravity(Handle:timer)
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			if(IsClientConnected(client) && IsClientSourceTV(client))
				continue;
			
			if(g_timerMapzones)
			if(Timer_IsPlayerTouchingZoneType(client, ZtNoGravityOverwrite)) 
				continue;
			
			//gravity update
			new style = Timer_GetStyle(client);
			if(g_Physics[style][StyleCustom] && !g_bCustomLowGravity[client])
			{
				SetEntityGravity(client, 1.0);
				continue;
			}
			else if(g_Physics[style][StyleGravity] != 1.0 && g_Physics[style][StyleGravity] > 0.0)
			{
				SetEntityGravity(client, g_Physics[style][StyleGravity]);
				continue;
			}
			
			SetEntityGravity(client, 1.0);
		}
	}

	return Plugin_Continue;
}

public Action:Timer_CheckNoClip(Handle:timer)
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			if(IsClientConnected(client) && IsClientSourceTV(client))
				continue;
			//has player noclip?
			if(GetEntProp(client, Prop_Send, "movetype", 1) == 8)
			{
				Timer_Stop(client, false);
				ResetBhopAvoid(client);
				ResetBhopCollect(client);
			}
		}
	}

	return Plugin_Continue;
}

ParseColor(const String:color[], result[])
{
	decl String:buffers[4][4];
	ExplodeString(color, " ", buffers, sizeof(buffers), sizeof(buffers[]));
	
	for (new i = 0; i < sizeof(buffers); i++)
		result[i] = StringToInt(buffers[i]);
}

stock Client_Push(client, Float:clientEyeAngle[3], Float:power, VelocityOverride:override[3]=VelocityOvr_None)
{
	decl	Float:forwardVector[3],
	Float:newVel[3];
	
	GetAngleVectors(clientEyeAngle, forwardVector, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(forwardVector, forwardVector);
	ScaleVector(forwardVector, power);
	
	Entity_GetAbsVelocity(client,newVel);
	
	for (new i=0;i<3;i++){
		switch(override[i]){
			case VelocityOvr_Velocity:{
				newVel[i] = 0.0;
			}
			case VelocityOvr_OnlyWhenNegative:{				
				if(newVel[i] < 0.0){
					newVel[i] = 0.0;
				}
			}
			case VelocityOvr_InvertReuseVelocity:{				
				if(newVel[i] < 0.0){
					newVel[i] *= -1.0;
				}
			}
		}
		
		newVel[i] += forwardVector[i];
	}
	
	Entity_SetAbsVelocity(client,newVel);
}

public Action:Command_ReloadConfig(client, args)
{
	LoadPhysics();
	LoadTimerSettings();
	
	ReplyToCommand(client, "Timer: Settings reloaded.");
		
	return Plugin_Handled;
}

public Action:Command_NoclipMe(client, args)
{
	if(client<1||!IsClientInGame(client)||!IsPlayerAlive(client))
	{
		ReplyToCommand(client, "\x04[SM] \x05You need to be alive to use noclip");
		return Plugin_Handled;
	}
	
	if(g_Settings[NoclipEnable])
	{
		if (GetEntityMoveType(client) != MOVETYPE_NOCLIP)
		{
			FakeClientCommand(client, "sm_pause");
			SetEntityMoveType(client, MOVETYPE_NOCLIP);
			ReplyToCommand(client, "Noclip Enabled");
		}
		else
		{
			SetEntityMoveType(client, MOVETYPE_WALK);
			StopPlayer(client);
			ReplyToCommand(client, "Noclip Disabled");
		}
	}
	else ReplyToCommand(client, "You have not access to this command.");
	
	return Plugin_Handled;
}

public Action:Command_Colour(client, args)
{
	if(client<1||!IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	if (g_colourme[client] == 1)
	{
		g_colourme[client] = 0;
	}
	else if(g_colourme[client] == 0)
	{
		g_colourme[client] = 1;
	}
	
	return Plugin_Handled;
}

public Action:Command_ToggleAuto(client, args)
{
	if(client<1||!IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	if (g_bAutoDisable[client])
	{
		g_bAutoDisable[client] = false;
		ReplyToCommand(client, "Automode Enabled");
	}
	else
	{
		g_bAutoDisable[client] = true;
		ReplyToCommand(client, "Automode Disabled");
	}
	return Plugin_Handled;
}

public Action:Timer_Push(Handle:timer, any:client)
{
	Push_Client(client);
	
	return Plugin_Stop;
}

stock Push_Client(client)
{
	if(g_fBoost[client] > 0.0)
	{
		Client_Push(client,Float:{-90.0,0.0,0.0}, g_fBoost[client], VelocityOverride:{VelocityOvr_None,VelocityOvr_None,VelocityOvr_None});
	}
}

public Action:Timer_Boost(Handle:timer, any:client)
{
	new style = Timer_GetStyle(client);
	Client_BoostForward(client, g_Physics[style][StyleBoostForward], g_Physics[style][StyleBoostForwardMax]);
	
	return Plugin_Stop;
}

Client_BoostForward(client, Float:scale, Float:maxspeed)
{
	new Float:fVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);
	
	fVelocity[0] = fVelocity[0]*scale;
	fVelocity[1] = fVelocity[1]*scale;
	
	if(maxspeed == 0.0 || SquareRoot(Pow(fVelocity[0],2.0)+Pow(fVelocity[1],2.0)) < maxspeed)
	{
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVelocity);
	}
}

PunishAbuse(client)
{
	new style = Timer_GetStyle(client);
	
	if(g_Physics[style][StylePunishType] == 0)
		return;
	
	//Block controls
	if(g_Physics[style][StylePunishType] == 1)
	{
		Block_MovementControl(client);
	}
	//Stop movement
	else if(g_Physics[style][StylePunishType] == 2)
	{
		CheckVelocity(client, 1, 250.0);
	}
	//Reset timer
	else if(g_Physics[style][StylePunishType] == 3)
	{
		Timer_Reset(client);
	}
	//Teleport to startzone
	else if(g_Physics[style][StylePunishType] == 4)
	{
		if(Timer_GetTrack(client) == TRACK_BONUS)
			Timer_ClientTeleportLevel(client, LEVEL_BONUS_START);
		else
			Timer_ClientTeleportLevel(client, LEVEL_START);
	}
	//Suiside
	else if(g_Physics[style][StylePunishType] == 5)
	{
		ForcePlayerSuicide(client);
	}
	//Teleport to last checkpoint
	else if(g_Physics[style][StylePunishType] == 6)
	{
		new levelid = Timer_GetClientLevelID(client);
		Timer_ClientTeleportLevel(client, levelid);
	}
	else
	{
		Timer_LogError("%d is not a valid punish type", g_Physics[style][StylePunishType]);
	}
}
