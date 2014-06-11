#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <timer>
#include <timer-logging>
#include <timer-config_loader.sp>
#include <timer-stocks>

#undef REQUIRE_PLUGIN
#include <timer-mapzones>
#include <timer-teams>
#include <timer-physics>
#include <timer-strafes>
#include <timer-worldrecord>
#include <timer-scripter_db>

#define MAX_FILE_LEN 128

new bool:g_timerPhysics = false;
new bool:g_timerStrafes = false;
new bool:g_timerScripterDB = false;
new bool:g_timerTeams = false;
new bool:g_timerWorldRecord = false;

/** 
 * Global Enums
 */
 
enum Timer
{
	Enabled,
	Float:StartTime,
	Float:EndTime,
	Jumps,
	bool:IsPaused,
	Float:PauseStartTime,
	Float:PauseLastOrigin[3],
	Float:PauseLastVelocity[3],
	Float:PauseLastAngles[3],
	Float:PauseTotalTime,
	CurrentStyle,
	FpsMax,
	Track,
	FinishCount,
	BonusFinishCount,
	ShortFinishCount,
	bool:ShortEndReached
}

enum BestTimeCacheEntity
{
	IsCached,
	Jumps,
	Float:Time
}

/**
 * Global Variables
 */
new Handle:g_hSQL;

new String:g_currentMap[64];
new g_reconnectCounter = 0;

new g_GetPauseLevel[MAXPLAYERS+1];

new g_timers[MAXPLAYERS+1][Timer];
new g_bestTimeCache[MAXPLAYERS+1][BestTimeCacheEntity];

new Handle:g_timerStartedForward;
new Handle:g_timerStoppedForward;
new Handle:g_timerRestartForward;
new Handle:g_timerPausedForward;
new Handle:g_timerResumedForward;

new Handle:g_timerWorldRecordForward;
new Handle:g_timerPersonalRecordForward;
new Handle:g_timerTop10RecordForward;
new Handle:g_timerFirstRecordForward;
new Handle:g_timerRecordForward;

new g_iVelocity;
new GameMod:mod;

public Plugin:myinfo =
{
    name        = "[Timer] Core",
    author      = "Zipcore, Credits: Alongub",
    description = "Core component for [Timer]",
    version     = PL_VERSION,
    url         = "zipcore#googlemail.com"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RegPluginLibrary("timer");
	
	CreateNative("Timer_Reset", Native_Reset);
	CreateNative("Timer_Start", Native_Start);
	CreateNative("Timer_Stop", Native_Stop);
	CreateNative("Timer_Pause", Native_Pause);
	CreateNative("Timer_Resume", Native_Resume);
	CreateNative("Timer_Restart", Native_Restart);
	CreateNative("Timer_FinishRound", Native_FinishRound);
	
	CreateNative("Timer_GetClientTimer", Native_GetClientTimer);
	CreateNative("Timer_GetStatus", Native_GetStatus);
	CreateNative("Timer_GetPauseStatus", Native_GetPauseStatus);
	
	CreateNative("Timer_SetStyle", Native_SetStyle);
	CreateNative("Timer_GetStyle", Native_GetStyle);
	CreateNative("Timer_IsStyleRanked", Native_IsStyleRanked);
	
	CreateNative("Timer_GetTrack", Native_GetTrack);
	CreateNative("Timer_SetTrack", Native_SetTrack);
	
	CreateNative("Timer_GetMapFinishCount", Native_GetMapFinishCount);
	CreateNative("Timer_GetMapFinishBonusCount", Native_GetMapFinishBonusCount);
	CreateNative("Timer_ForceClearCacheBest", Native_ForceClearCacheBest);
	
	CreateNative("Timer_AddPenaltyTime", Native_AddPenaltyTime);

	return APLRes_Success;
}

public OnPluginStart()
{
	ConnectSQL();
	LoadPhysics();
	LoadTimerSettings();
	
	CreateConVar("timer_version", PL_VERSION, "Timer Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	RegConsoleCmd("sm_credits", Command_Credits);
	mod = GetGameMod();
	
	g_timerStartedForward = CreateGlobalForward("OnTimerStarted", ET_Event, Param_Cell);
	g_timerStoppedForward = CreateGlobalForward("OnTimerStopped", ET_Event, Param_Cell);
	g_timerRestartForward = CreateGlobalForward("OnTimerRestart", ET_Event, Param_Cell);
	g_timerPausedForward = CreateGlobalForward("OnTimerPaused", ET_Event, Param_Cell);
	g_timerResumedForward = CreateGlobalForward("OnTimerResumed", ET_Event, Param_Cell);
	
	g_timerWorldRecordForward = CreateGlobalForward("OnTimerWorldRecord", ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	g_timerPersonalRecordForward = CreateGlobalForward("OnTimerPersonalRecord", ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	g_timerTop10RecordForward = CreateGlobalForward("OnTimerTop10Record", ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	g_timerFirstRecordForward = CreateGlobalForward("OnTimerFirstRecord", ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	g_timerRecordForward = CreateGlobalForward("OnTimerRecord", ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	
	g_iVelocity = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");
	
	LoadTranslations("timer.phrases");
	
	//RegConsoleCmd("sm_stop", Command_Stop);
	if(g_Settings[PauseEnable])
	{ 
		RegConsoleCmd("sm_pause", Command_Pause);
		RegConsoleCmd("sm_resume", Command_Resume);
	}

	RegAdminCmd("sm_droptable", Command_DropTable, ADMFLAG_ROOT);
	
	HookEvent("player_jump", Event_PlayerJump);
	HookEvent("player_death", Event_StopTimer);
	HookEvent("player_team", Event_StopTimerPaused);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_disconnect", Event_StopTimer);
	
	AutoExecConfig(true, "timer/timer-core");
	

	g_timerPhysics = LibraryExists("timer-physics");
	g_timerStrafes = LibraryExists("timer-strafes");
	g_timerScripterDB = LibraryExists("timer-scripter_db");
	g_timerTeams = LibraryExists("timer-teams");
	g_timerWorldRecord = LibraryExists("timer-worldrecord");
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "timer-physics"))
	{
		g_timerPhysics = true;
	}
	else if (StrEqual(name, "timer-strafes"))
	{
		g_timerStrafes = true;
	}
	else if (StrEqual(name, "timer-scripter_db"))
	{
		g_timerScripterDB = true;
	}
	else if (StrEqual(name, "timer-teams"))
	{
		g_timerTeams = true;
	}
	else if (StrEqual(name, "timer-worldrecord"))
	{
		g_timerWorldRecord = true;
	}
}

public OnLibraryRemoved(const String:name[])
{	
	if (StrEqual(name, "timer-physics"))
	{
		g_timerPhysics = false;
	}
	else if (StrEqual(name, "timer-strafes"))
	{
		g_timerStrafes = false;
	}
	else if (StrEqual(name, "timer-scripter_db"))
	{
		g_timerScripterDB = false;
	}
	else if (StrEqual(name, "timer-teams"))
	{
		g_timerTeams = false;
	}
	else if (StrEqual(name, "timer-worldrecord"))
	{
		g_timerWorldRecord = false;
	}
}

public OnClientAuthorized(client, const String:auth[])
{
	if (g_hSQL == INVALID_HANDLE)
	{
		ConnectSQL();
	}
	else
	{
		if(StrContains(auth, "STEAM", true) > -1)
		{
			if(Client_IsValid(client) && !IsFakeClient(client))
			{
				decl String:name[MAX_NAME_LENGTH];
				GetClientName(client, name, sizeof(name));
			
				decl String:safeName[2 * strlen(name) + 1];
				SQL_EscapeString(g_hSQL, name, safeName, 2 * strlen(name) + 1);
			
				decl String:query[256];
				FormatEx(query, sizeof(query), "UPDATE `round` SET name = '%s' WHERE auth = '%s'", safeName, auth);

				SQL_TQuery(g_hSQL, UpdateNameCallback, query, _, DBPrio_Normal);
			}
		}
		else if(!IsFakeClient(client) && IsClientSourceTV(client)) KickClient(client, "NO VALID STEAM ID");
	}
}

public PrepareSound(String: sound[MAX_FILE_LEN])
{
	decl String:fileSound[MAX_FILE_LEN];

	FormatEx(fileSound, MAX_FILE_LEN, "sound/%s", sound);

	if (FileExists(fileSound))
	{
		PrecacheSound(sound, true);
		AddFileToDownloadsTable(fileSound);
	}
	else
	{
		PrintToServer("[Timer] ERROR: File '%s' not found!", fileSound);
	}
}

public OnMapStart()
{	
	GetCurrentMap(g_currentMap, sizeof(g_currentMap));
	ClearCache();
	ClearFinishCounts();
	
	LoadPhysics();
	LoadTimerSettings();
}

ClearFinishCounts()
{
	for(new i=1;i<=MaxClients;i++)
	{
		g_timers[i][FinishCount] = 0;	
		g_timers[i][BonusFinishCount] = 0;
		g_timers[i][ShortFinishCount] = 0;
		g_timers[i][Track] = 0;
	}
}

/**
 * Events
 */
public Action:Event_PlayerJump(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (g_timers[client][Enabled] && !g_timers[client][IsPaused])
		g_timers[client][Jumps]++;
	
	return Plugin_Continue;
}

public Action:Event_StopTimer(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(0 < client <= MaxClients) if (IsClientInGame(client)) StopTimer(client, false);
	return Plugin_Continue;
}

public Action:Event_StopTimerPaused(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(0 < client <= MaxClients) if (IsClientInGame(client)) StopTimer(client);
	return Plugin_Continue;
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(0 < client <= MaxClients)
	{
		if(IsClientInGame(client))
			StopTimer(client);
	}
}

public Action:Command_Stop(client, args)
{
	if (IsPlayerAlive(client))
		StopTimer(client, false);
		
	return Plugin_Handled;
}

public Action:Command_Pause(client, args)
{
	if (g_Settings[PauseEnable] && IsPlayerAlive(client))
		PauseTimer(client);
		
	return Plugin_Handled;
}

public Action:Command_Resume(client, args)
{
	if (g_Settings[PauseEnable] && IsPlayerAlive(client))
		ResumeTimer(client);
		
	return Plugin_Handled;
}

public Action:Command_DropTable(client, args)
{	
	decl String:query[64];
	FormatEx(query, sizeof(query), "DROP TABLE round");

	SQL_TQuery(g_hSQL, DropTable, query, _, DBPrio_Normal);
	
	return Plugin_Handled;
}

public DropTable(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("SQL Error on DropTable: %s", error);
	}
}

public FpsMaxCallback(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
	g_timers[client][FpsMax] = StringToInt(cvarValue);
}

/**
 * Core Functionality
 */

bool:ResetTimer(client)
{
	//Forward Timer_Stopped(client)
	Call_StartForward(g_timerStoppedForward);
	Call_PushCell(client);
	Call_Finish();
	
	//Stop mate
	if (g_timerTeams)
	{
		new mate = Timer_GetClientTeammate(client);
		if(0 < mate)
		{
			StopTimer(mate, false);
			Call_StartForward(g_timerStoppedForward);
			Call_PushCell(mate);
			Call_Finish();
		}
	}
	
	g_timers[client][Enabled] = false;
	g_timers[client][StartTime] = GetGameTime();
	g_timers[client][EndTime] = -1.0;
	g_timers[client][Jumps] = 0;
	g_timers[client][IsPaused] = false;
	g_timers[client][PauseStartTime] = 0.0;
	g_timers[client][PauseTotalTime] = 0.0;
	g_timers[client][ShortEndReached] = false;
	if(g_timerPhysics) Timer_ResetAccuracy(client);
	
	return true;
}

bool:TimerPenalty(client, Float:penaltytime)
{
	g_timers[client][StartTime] -= penaltytime;
	
	return true;
}
 
bool:StartTimer(client)
{
	if(!IsValidClient(client))
		return false;
	if (g_timers[client][Enabled])
		return false;
	
	g_timers[client][Enabled] = true;
	g_timers[client][ShortEndReached] = false;
	g_timers[client][StartTime] = GetGameTime();
	g_timers[client][EndTime] = -1.0;
	g_timers[client][Jumps] = 0;
	g_timers[client][IsPaused] = false;
	g_timers[client][PauseStartTime] = 0.0;
	g_timers[client][PauseTotalTime] = 0.0;
	if(g_timerPhysics) Timer_ResetAccuracy(client);
	
	//Check for custom settings
	QueryClientConVar(client, "fps_max", FpsMaxCallback, client);

	//Push Forward Timer_Started(client)
	Call_StartForward(g_timerStartedForward);
	Call_PushCell(client);
	Call_Finish();
	return true;
}

bool:StopTimer(client, bool:stopPaused = true)
{
	if(!IsValidClient(client))
		return false;
	if (!g_timers[client][Enabled])
		return false;
	
	//Already paused?
	if (!stopPaused && g_timers[client][IsPaused])
		return false;
	
	//EmitSoundToClient(client, SND_TIMER_STOP);
	
	//Get time
	g_timers[client][Enabled] = false;
	g_timers[client][ShortEndReached] = true;
	g_timers[client][EndTime] = GetGameTime();
	
	//Prevent Resume
	if (!stopPaused) g_timers[client][IsPaused] = false;
	
	//Forward Timer_Stopped(client)
	Call_StartForward(g_timerStoppedForward);
	Call_PushCell(client);
	Call_Finish();
	
	//Stop mate
	if (g_timerTeams)
	{
		new mate = Timer_GetClientTeammate(client);
		if(0 < mate)
		{
			StopTimer(mate, false);
			Call_StartForward(g_timerStoppedForward);
			Call_PushCell(mate);
			Call_Finish();
		}
	}
		
	return true;
}

bool:RestartTimer(client)
{
	if(!IsValidClient(client))
		return false;
	
	StopTimer(client, false);
	
	//Forward Timer_Restarted(client)
	Call_StartForward(g_timerRestartForward);
	Call_PushCell(client);
	Call_Finish();

	if (g_timerTeams)
	{
		new mate = Timer_GetClientTeammate(client);
		if(mate != 0) 
		{	
			StopTimer(mate, false);

			Call_StartForward(g_timerRestartForward);
			Call_PushCell(mate);
			Call_Finish();

			return StartTimer(client) && StartTimer(mate);
		}
	}

	return StartTimer(client);
}

bool:PauseTimer(client)
{
	if(!IsValidClient(client))
		return false;
	if (!g_timers[client][Enabled] || g_timers[client][IsPaused])
		return false;
	
	g_timers[client][IsPaused] = true;
	g_timers[client][PauseStartTime] = GetGameTime();
	g_GetPauseLevel[client] = Timer_GetClientLevel(client);
	
	CreateTimer(0.0, Timer_ValidatePause, client, TIMER_FLAG_NO_MAPCHANGE);
	
	CPrintToChat(client, PLUGIN_PREFIX, "Pause Info");

	new Float:origin[3];
	GetClientAbsOrigin(client, origin);
	Array_Copy(origin, g_timers[client][PauseLastOrigin], 3);

	new Float:angles[3];
	GetClientAbsAngles(client, angles);
	Array_Copy(angles, g_timers[client][PauseLastAngles], 3);

	new Float:velocity[3];
	GetClientAbsVelocity(client, velocity);
	Array_Copy(velocity, g_timers[client][PauseLastVelocity], 3);

	Call_StartForward(g_timerPausedForward);
	Call_PushCell(client);
	Call_Finish();
	
	if(g_timerTeams) 
	{
		new mate = Timer_GetClientTeammate(client);
		if(0 < mate)
		{
			g_timers[mate][IsPaused] = true;
			g_timers[mate][PauseStartTime] = GetGameTime();
		
			CreateTimer(0.0, Timer_ValidatePause, mate, TIMER_FLAG_NO_MAPCHANGE);
		
			CPrintToChat(mate, PLUGIN_PREFIX, "Pause Info");
		
			new Float:origin2[3];
			GetClientAbsOrigin(mate, origin2);
			Array_Copy(origin2, g_timers[mate][PauseLastOrigin], 3);

			new Float:angles2[3];
			GetClientAbsAngles(mate, angles2);
			Array_Copy(angles2, g_timers[mate][PauseLastAngles], 3);

			new Float:velocity2[3];
			GetClientAbsVelocity(mate, velocity2);
			Array_Copy(velocity2, g_timers[mate][PauseLastVelocity], 3);

			Call_StartForward(g_timerPausedForward);
			Call_PushCell(mate);
			Call_Finish();
		}
	}

	return true;
}

public Action:Timer_ValidatePause(Handle:timer, any:client)
{
	if(CalculateTime(client) < 1.0)
	{
		ResetTimer(client);
	}
	
	return Plugin_Stop;
}

bool:ResumeTimer(client)
{
	if(!IsValidClient(client))
		return false;
	if (!g_timers[client][Enabled] || !g_timers[client][IsPaused])
		return false;

	new Float:origin[3];
	Array_Copy(g_timers[client][PauseLastOrigin], origin, 3);

	new Float:angles[3];
	Array_Copy(g_timers[client][PauseLastAngles], angles, 3);

	new Float:velocity[3];
	Array_Copy(g_timers[client][PauseLastVelocity], velocity, 3);

	TeleportEntity(client, origin, angles, velocity);
	
	g_timers[client][IsPaused] = false;
	g_timers[client][PauseTotalTime] += GetGameTime() - g_timers[client][PauseStartTime];
	
	Timer_SetClientLevel(client, g_GetPauseLevel[client]);

	Call_StartForward(g_timerResumedForward);
	Call_PushCell(client);
	Call_Finish();

	if(g_timerTeams)
	{
		new mate = Timer_GetClientTeammate(client);
		if(0 < mate)
		{
			new Float:origin2[3];
			Array_Copy(g_timers[mate][PauseLastOrigin], origin2, 3);

			new Float:angles2[3];
			Array_Copy(g_timers[mate][PauseLastAngles], angles2, 3);

			new Float:velocity2[3];
			Array_Copy(g_timers[mate][PauseLastVelocity], velocity2, 3);

			TeleportEntity(mate, origin2, angles2, velocity2);

			g_timers[mate][IsPaused] = false;
			g_timers[mate][PauseTotalTime] += GetGameTime() - g_timers[mate][PauseStartTime];

			Call_StartForward(g_timerResumedForward);
			Call_PushCell(mate);
			Call_Finish();
		}
	}
	
	return true;
}

ClearCache()
{
	for (new client = 1; client <= MaxClients; client++)
		ClearClientCache(client);
}

ClearClientCache(client)
{
	g_bestTimeCache[client][IsCached] = false;
	g_bestTimeCache[client][Jumps] = 0;
	g_bestTimeCache[client][Time] = 0.0;	
}

FinishRound(client, const String:map[], Float:time, jumps, style, fpsmax, track)
{
	if (!IsClientInGame(client))
		return;
	if (IsFakeClient(client))
		return;
	
	decl String:auth[32];
	GetClientAuthString(client, auth, sizeof(auth));
	
	//ignore unranked
	if(g_timerPhysics) 
		if (g_Physics[style][StyleCategory] != MCategory_Ranked || !(bool:Timer_IsStyleRanked(style)))
			return;
	
	//short end already triggered
	if (g_timers[client][ShortEndReached] && track == 2)
		return;
	
	if (time < 1.0)
	{
		Timer_Log(Timer_LogLevelWarning, "Detected illegal record by %N on %s [time:%.2f|style:%d|track:%d|jumps:%d] SteamID: %s", client, g_currentMap, time, style, track, jumps, auth);
		return;
	}
	
	if(g_timerScripterDB)
	{
		if (Timer_IsScripter(client))
		{
			Timer_Log(Timer_LogLevelWarning, "Detected scripter record by %N on %s [time:%.2f|style:%d|track:%d|jumps:%d] SteamID: %s", client, g_currentMap, time, style, track, jumps, auth);
			return;
		}
	}
	
	if(track == TRACK_SHORT) g_timers[client][ShortEndReached] = true;
	
	//Record Info
	new RecordId;
	new Float:RecordTime;
	new RankTotal;
	
	//Personal Record
	new currentrank, newrank;	
	if(g_timerWorldRecord) 
	{
		currentrank = Timer_GetStyleRank(client, track, style);	
		newrank = Timer_GetNewPossibleRank(style, track, time);
	}
	
	new Float:LastTime;
	new Float:LastTimeStatic;
	new LastJumps;
	decl String:TimeDiff[32];
	decl String:buffer[32];
	
	new bool:NewPersonalRecord = false;
	new bool:NewWorldRecord = false;
	new bool:FirstRecord = false;
	
	new Float:jumpacc;
	if(g_timerPhysics) Timer_GetJumpAccuracy(client, jumpacc);
	
	new strafes, strafes_boosted, Float:strafeacc;
	if(g_timerStrafes) 
	{
		strafes = Timer_GetStrafeCount(client);
		strafes_boosted = Timer_GetBoostedStrafeCount(client);
	
		if(strafes < 1)
		{
			strafes = 1;
		}
	
		strafeacc = 100.0-(100.0*(float(strafes_boosted)/float(strafes)));
	}	
	
	//get speed
	new Float:maxspeed, Float:currentspeed, Float:avgspeed;
	if(g_timerPhysics) 
	{	
		Timer_GetMaxSpeed(client, maxspeed);
		Timer_GetCurrentSpeed(client, currentspeed);
		Timer_GetAvgSpeed(client, avgspeed);
	}

	//Player Info

	decl String:name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));

	decl String:safeName[2 * strlen(name) + 1];
	SQL_EscapeString(g_hSQL, name, safeName, 2 * strlen(name) + 1);
	
	/* Get Personal Record */
	if(g_timerWorldRecord && Timer_GetBestRound(client, style, track, LastTime, LastJumps))
	{
		LastTimeStatic = LastTime;
		LastTime -= time;			
		if(LastTime < 0.0)
		{
			LastTime *= -1.0;
			Timer_SecondsToTime(LastTime, buffer, sizeof(buffer), 3);
			FormatEx(TimeDiff, sizeof(TimeDiff), "+%s", buffer);
		}
		else if(LastTime > 0.0)
		{
			Timer_SecondsToTime(LastTime, buffer, sizeof(buffer), 3);
			FormatEx(TimeDiff, sizeof(TimeDiff), "-%s", buffer);
		}
		else if(LastTime == 0.0)
		{
			Timer_SecondsToTime(LastTime, buffer, sizeof(buffer), 3);
			FormatEx(TimeDiff, sizeof(TimeDiff), "%s", buffer);
		}
	}
	else
	{
		//No personal record, this is his first record
		FirstRecord = true;
		LastTime = 0.0;
		Timer_SecondsToTime(LastTime, buffer, sizeof(buffer), 3);
		FormatEx(TimeDiff, sizeof(TimeDiff), "%s", buffer);
		RankTotal++;
	}

	/* Get World Record */
	if(g_timerWorldRecord) Timer_GetStyleRecordTime(style, track, RecordId, RecordTime, RankTotal);
	
	/* Detect Record Type */
	if(RecordTime == 0.0 || time < RecordTime)
	{
		NewWorldRecord = true;
	}
	
	if(LastTimeStatic == 0.0 || time < LastTimeStatic)
	{
		NewPersonalRecord = true;
	}
	
	if(FirstRecord || NewPersonalRecord)
	{
		//CPrintToChat(client, "%s{blue} Your record has been saved.", PLUGIN_PREFIX2);
		
		//Save record
		decl String:query[2048];
		FormatEx(query, sizeof(query), "INSERT INTO round (map, auth, time, jumps, physicsdifficulty, name, fpsmax, bonus, rank, jumpacc, maxspeed, avgspeed, finishspeed, finishcount, strafes, strafeacc) VALUES ('%s', '%s', %f, %d, %d, '%s', %d, %d, %d, %f, %f, %f, %f, 1, %d, %f) ON DUPLICATE KEY UPDATE time = '%f', jumps = '%d', name = '%s', fpsmax = '%d', rank = '%d', jumpacc = '%f', maxspeed = '%f', avgspeed = '%f', finishspeed = '%f', finishcount = finishcount + 1, strafes = '%d', strafeacc = '%f', date = CURRENT_TIMESTAMP();", map, auth, time, jumps, style, safeName, fpsmax, track, newrank, jumpacc, maxspeed, avgspeed, currentspeed, strafes, strafeacc, time, jumps, safeName, fpsmax, newrank, jumpacc, maxspeed, avgspeed, currentspeed, strafes, strafeacc);
			
		SQL_TQuery(g_hSQL, FinishRoundCallback, query, client, DBPrio_High);
	}
	else
	{
		decl String:query[512];
		FormatEx(query, sizeof(query), "INSERT INTO round (map, auth, time, jumps, physicsdifficulty, name, fpsmax, bonus, rank, jumpacc, maxspeed, avgspeed, finishspeed, finishcount, strafes, strafeacc) VALUES ('%s', '%s', %f, %d, %d, '%s', %d, %d, %d, %f, %f, %f, %f, 1, %d, %f) ON DUPLICATE KEY UPDATE name = '%s', finishcount = finishcount + 1;", map, auth, time, jumps, style, safeName, fpsmax, track, newrank, jumpacc, maxspeed, avgspeed, currentspeed, strafes, strafeacc, safeName);
		SQL_TQuery(g_hSQL, FinishRoundCallback, query, client, DBPrio_High);
	}
	
	/* Forwards */
	Call_StartForward(g_timerRecordForward);
	Call_PushCell(client);
	Call_PushCell(track);
	Call_PushCell(style);
	Call_PushCell(time);
	Call_PushCell(LastTimeStatic);
	Call_PushCell(currentrank);
	Call_PushCell(newrank);
	Call_Finish();
	
	if(NewWorldRecord)
	{
		Call_StartForward(g_timerWorldRecordForward);
		Call_PushCell(client);
		Call_PushCell(track);
		Call_PushCell(style);
		Call_PushCell(time);
		Call_PushCell(LastTimeStatic);
		Call_PushCell(currentrank);
		Call_PushCell(newrank);
		Call_Finish();
	}
	
	if(NewPersonalRecord)
	{
		Call_StartForward(g_timerPersonalRecordForward);
		Call_PushCell(client);
		Call_PushCell(track);
		Call_PushCell(style);
		Call_PushCell(time);
		Call_PushCell(LastTimeStatic);
		Call_PushCell(currentrank);
		Call_PushCell(newrank);
		Call_Finish();
	}
	
	if(newrank <= 10)
	{
		Call_StartForward(g_timerTop10RecordForward);
		Call_PushCell(client);
		Call_PushCell(track);
		Call_PushCell(style);
		Call_PushCell(time);
		Call_PushCell(LastTimeStatic);
		Call_PushCell(currentrank);
		Call_PushCell(newrank);
		Call_Finish();
	}
	
	if(FirstRecord)
	{
		Call_StartForward(g_timerFirstRecordForward);
		Call_PushCell(client);
		Call_PushCell(track);
		Call_PushCell(style);
		Call_PushCell(time);
		Call_PushCell(LastTimeStatic);
		Call_PushCell(currentrank);
		Call_PushCell(newrank);
		Call_Finish();
	}
}

public UpdateNameCallback(Handle:owner, Handle:hndl, const String:error[], any:param1)
{
	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("SQL Error on UpdateName: %s", error);
		return;
	}

	if (g_timerWorldRecord) 
	{
		Timer_ForceReloadCache();
	}
}

public DeletePlayersRecordCallback(Handle:owner, Handle:hndl, const String:error[], any:param1)
{
	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("SQL Error on DeletePlayerRecord: %s", error);
		return;
	}
}

public FinishRoundCallback(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("SQL Error on FinishRound: %s", error);
		return;
	}

	g_bestTimeCache[client][IsCached] = false;
	//PrintToChat(client, "Your stats have been stored into our database, thank you.");
	
	if(g_timerWorldRecord) Timer_ForceReloadCache();
}

Float:CalculateTime(client)
{
	if (g_timers[client][Enabled] && g_timers[client][IsPaused])
		return g_timers[client][PauseStartTime] - g_timers[client][StartTime] - g_timers[client][PauseTotalTime];
	else
		return (g_timers[client][Enabled] ? GetGameTime() : g_timers[client][EndTime]) - g_timers[client][StartTime] - g_timers[client][PauseTotalTime];	
}

ConnectSQL()
{
    if (g_hSQL != INVALID_HANDLE)
        CloseHandle(g_hSQL);
	
    g_hSQL = INVALID_HANDLE;

    if (SQL_CheckConfig("timer"))
	{
		SQL_TConnect(ConnectSQLCallback, "timer");
	}
    else
	{
		SetFailState("PLUGIN STOPPED - Reason: no config entry found for 'timer' in databases.cfg - PLUGIN STOPPED");
	}
}

public ConnectSQLCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (g_reconnectCounter >= 5)
	{
		SetFailState("PLUGIN STOPPED - Reason: reconnect counter reached max - PLUGIN STOPPED");
		return;
	}

	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("Connection to SQL database has failed, Reason: %s", error);
		
		g_reconnectCounter++;
		ConnectSQL();
		
		return;
	}

	decl String:driver[16];
	SQL_GetDriverIdent(owner, driver, sizeof(driver));

	g_hSQL = CloneHandle(hndl);
	
	if (StrEqual(driver, "mysql", false))
	{
		SQL_SetCharset(g_hSQL, "utf8");
		SQL_TQuery(g_hSQL, CreateSQLTableCallback, "CREATE TABLE IF NOT EXISTS `round` (`id` int(11) NOT NULL AUTO_INCREMENT, `map` varchar(32) NOT NULL, `auth` varchar(32) NOT NULL, `time` float NOT NULL, `jumps` int(11) NOT NULL, `physicsdifficulty` int(11) NOT NULL, `bonus` int(11) NOT NULL, `name` varchar(64) NOT NULL, `finishcount` int(11) NOT NULL, `levelprocess` int(11) NOT NULL, `fpsmax` int(11) NOT NULL, `jumpacc` float NOT NULL, `strafes` int(11) NOT NULL, `strafeacc` float NOT NULL, `avgspeed` float NOT NULL, `maxspeed` float NOT NULL, `finishspeed` float NOT NULL, `flashbangcount` int(11) NOT NULL, `rank` int(11) NOT NULL, `replaypath` varchar(32) NOT NULL, `custom1` varchar(32) NOT NULL, `custom2` varchar(32) NOT NULL, `custom3` varchar(32) NOT NULL, date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, PRIMARY KEY (`id`), UNIQUE KEY `single_record` (`auth`, `map`, `physicsdifficulty`, `bonus`));");
	}
	
	else if (StrEqual(driver, "sqlite", false))
	{
		SetFailState("Timer ERROR: SqLite is not supported, please check you databases.cfg and use MySQL driver");
	}
	
	g_reconnectCounter = 1;
}

public CreateSQLTableCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (owner == INVALID_HANDLE)
	{
		Timer_LogError(error);
		
		g_reconnectCounter++;
		ConnectSQL();

		return;
	}
	
	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("SQL Error on CreateSQLTable: %s", error);
		return;
	}
}

public Native_Reset(Handle:plugin, numParams)
{
	return ResetTimer(GetNativeCell(1));
}

public Native_Start(Handle:plugin, numParams)
{
	return StartTimer(GetNativeCell(1));
}

public Native_Stop(Handle:plugin, numParams)
{
	return StopTimer(GetNativeCell(1), bool:GetNativeCell(2));
}

public Native_Restart(Handle:plugin, numParams)
{
	return RestartTimer(GetNativeCell(1));
}

public Native_Resume(Handle:plugin, numParams)
{
	if(g_Settings[PauseEnable])
		return ResumeTimer(GetNativeCell(1));
	else
		return false;
}

public Native_Pause(Handle:plugin, numParams)
{
	if(g_Settings[PauseEnable])
		return PauseTimer(GetNativeCell(1));
	else
		return StopTimer(GetNativeCell(1));
}

public Native_GetClientTimer(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	SetNativeCellRef(2, g_timers[client][Enabled]);
	SetNativeCellRef(3, CalculateTime(client));
	SetNativeCellRef(4, g_timers[client][Jumps]);
	SetNativeCellRef(5, g_timers[client][FpsMax]);	

	return true;
}

public Native_FinishRound(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);

	decl String:map[32];
	GetNativeString(2, map, sizeof(map));
	
	new Float:time = GetNativeCell(3);
	new jumps = GetNativeCell(4);
	new style = GetNativeCell(5);
	new fpsmax = GetNativeCell(6);
	new track = GetNativeCell(7);
	
	FinishRound(client, map, time, jumps, style, fpsmax, track);
}

public Native_ForceClearCacheBest(Handle:plugin, numParams)
{
	ClearCache();
}

public Native_SetTrack(Handle:plugin, numParams)
{
	g_timers[GetNativeCell(1)][Track] = GetNativeCell(2);
}

public Native_GetTrack(Handle:plugin, numParams)
{
	return g_timers[GetNativeCell(1)][Track];
}

public Native_GetMapFinishCount(Handle:plugin, numParams)
{
	return g_timers[GetNativeCell(1)][FinishCount];
}

public Native_GetMapFinishBonusCount(Handle:plugin, numParams)
{
	return g_timers[GetNativeCell(1)][BonusFinishCount];
}

public Native_SetStyle(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	g_timers[client][CurrentStyle] = GetNativeCell(2);
	if(g_timerPhysics) Timer_ApplyPhysics(client);
}

public Native_AddPenaltyTime(Handle:plugin, numParams)
{
	new Float:penaltytime = GetNativeCell(2);
	return TimerPenalty(GetNativeCell(1), penaltytime);
}

public Native_GetStyle(Handle:plugin, numParams)
{
	return g_timers[GetNativeCell(1)][CurrentStyle];
}

public Native_GetStatus(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	return (g_timers[client][Enabled] && !g_timers[client][IsPaused]);
}

public Native_GetPauseStatus(Handle:plugin, numParams)
{
	return (g_timers[GetNativeCell(1)][IsPaused]);
}

public Native_IsStyleRanked(Handle:plugin, numParams)
{
	return (g_Physics[GetNativeCell(1)][StyleCategory] == MCategory_Ranked);
}

/**
 * Utils methods
 */
stock GetClientAbsVelocity(client, Float:vecVelocity[3])
{
	for (new x = 0; x < 3; x++)
	{
		vecVelocity[x] = GetEntDataFloat(client, g_iVelocity + (x*4));
	}
}

// CREDITS
public Action:Command_Credits(client, args)
{
	CreditsPanel(client);
	
	return Plugin_Handled;
}

public CreditsPanel(client)
{
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, "- Timer Credits -");
	
	if(mod == MOD_CSGO) SetPanelCurrentKey(panel, 8);
	else SetPanelCurrentKey(panel, 9);
	
	DrawPanelText(panel, "     -- Page 1/4 --");
	DrawPanelText(panel, " ");
	DrawPanelText(panel, "Zipcore - Creator and Main Coder of plugin");
	DrawPanelText(panel, " ");
	DrawPanelText(panel, "Alongub - Old Timer Core");
	DrawPanelText(panel, "Shavit - Added new features and supported plugin");
	DrawPanelText(panel, "Paduh - Rankings system");
	DrawPanelText(panel, "Das D - Chatrank, Player Info, Timer Info, Chatextension");
	DrawPanelText(panel, "DaFox - MultiPlayer Bunny Hops");
	DrawPanelText(panel, "Peace-Maker - Bot Mimic 2, Backwards and more");
	DrawPanelText(panel, " ");
	DrawPanelItem(panel, "- Next -");
	DrawPanelItem(panel, "- Exit -");
	SendPanelToClient(panel, client, CreditsHandler1, MENU_TIME_FOREVER);

	CloseHandle(panel);
}

public CreditsHandler1 (Handle:menu, MenuAction:action,param1, param2)
{
    if ( action == MenuAction_Select )
    {
		if(mod == MOD_CSGO) 
		{
			switch (param2)
			{
				case 8:
				{
					CreditsPanel2(param1);
				}
			}
		}
		else
		{
			switch (param2)
			{
				case 9:
				{
					CreditsPanel2(param1);
				}
			}
		}
    }
}

public CreditsPanel2(client)
{
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, "- Timer Credits -");
	
	if(mod == MOD_CSGO) SetPanelCurrentKey(panel, 7);
	else SetPanelCurrentKey(panel, 8);
	
	DrawPanelText(panel, "     -- Page 2/4 --");
	DrawPanelText(panel, " ");
	DrawPanelText(panel, "0wn3r - Many small improvements");
	DrawPanelText(panel, "Justshoot - LJ Stats");
	DrawPanelText(panel, "DieterM75 - Checkpoint System");
	DrawPanelText(panel, "Skippy - Trigger Hooks");
	DrawPanelText(panel, "GoD-Tony - AutoTrigger Detection");
	DrawPanelText(panel, "Miu - Strafe Stats");
	DrawPanelText(panel, "Inami - Macrodox Detection");
	DrawPanelText(panel, " ");
	DrawPanelItem(panel, "- Back -");
	DrawPanelItem(panel, "- Next -");
	DrawPanelItem(panel, "- Exit -");
	SendPanelToClient(panel, client, CreditsHandler2, MENU_TIME_FOREVER);

	CloseHandle(panel);
}

public CreditsHandler2 (Handle:menu, MenuAction:action,param1, param2)
{
    if ( action == MenuAction_Select )
    {
		if(mod == MOD_CSGO) 
		{
			switch (param2)
			{
				case 7:
				{
					CreditsPanel(param1);
				}
				case 8:
				{
					CreditsPanel3(param1);
				}
			}
		}
		else
		{
			switch (param2)
			{
				case 8:
				{
					CreditsPanel(param1);
				}
				case 9:
				{
					CreditsPanel3(param1);
				}
			}
		}
    }
}

public CreditsPanel3(client)
{
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, "- Timer Credits -");
	
	if(mod == MOD_CSGO) SetPanelCurrentKey(panel, 7);
	else SetPanelCurrentKey(panel, 8);
	
	DrawPanelText(panel, "     -- Page 3/4 --");
	DrawPanelText(panel, " ");
	DrawPanelText(panel, "SMAC Team - Trigger Detection");
	DrawPanelText(panel, "Jason Bourne - Challenge, Custom-HUD");
	DrawPanelText(panel, "SWATr - Small fixes/changes");
	DrawPanelText(panel, "Smesh292 - No Jail and small fixes/changes");
	DrawPanelText(panel, "Dark Session - Code optimization");
	DrawPanelText(panel, "Mev - Autostrafe");
	DrawPanelText(panel, " ");
	DrawPanelText(panel, " ");
	DrawPanelItem(panel, "- Back -");
	DrawPanelItem(panel, "- Next -");
	DrawPanelItem(panel, "- Exit -");
	SendPanelToClient(panel, client, CreditsHandler3, MENU_TIME_FOREVER);

	CloseHandle(panel);
}

public CreditsHandler3 (Handle:menu, MenuAction:action,param1, param2)
{
    if ( action == MenuAction_Select )
    {
		if(mod == MOD_CSGO) 
		{
			switch (param2)
			{
				case 7:
				{
					CreditsPanel2(param1);
				}
				case 8:
				{
					CreditsPanel4(param1);
				}
			}
		}
		else
		{
			switch (param2)
			{
				case 8:
				{
					CreditsPanel2(param1);
				}
				case 9:
				{
					CreditsPanel4(param1);
				}
			}
		}
    }
}

public CreditsPanel4(client)
{
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, "- Timer Credits -");
	
	if(mod == MOD_CSGO) SetPanelCurrentKey(panel, 7);
	else SetPanelCurrentKey(panel, 8);
	
	DrawPanelText(panel, "     -- Page 4/4 --");
	DrawPanelText(panel, " ");
	DrawPanelText(panel, "   ---- Special Thanks ----");
	DrawPanelText(panel, "AlliedModders, .#IsKulT, Jacky, Shadow[DK],");
	DrawPanelText(panel, "Korki, Joy, Blackpanther, Popping-Fresh,");
	DrawPanelText(panel, "Dirthy Secret, KackEinKrug, Blackout, Cru,");
	DrawPanelText(panel, "Shadow, Schoschy, Extan, cREANy0,");
	DrawPanelText(panel, "Kolapsicle, DevilHunterMultigaming, ");
	DrawPanelText(panel, "and many others");
	DrawPanelText(panel, " ");
	DrawPanelItem(panel, "- Back -");
	DrawPanelItem(panel, "- Next -", ITEMDRAW_SPACER);
	DrawPanelItem(panel, "- Exit -");
	SendPanelToClient(panel, client, CreditsHandler4, MENU_TIME_FOREVER);

	CloseHandle(panel);
}

public CreditsHandler4 (Handle:menu, MenuAction:action,param1, param2)
{
    if ( action == MenuAction_Select )
    {
		if(mod == MOD_CSGO) 
		{
			switch (param2)
			{
				case 7:
				{
					CreditsPanel3(param1);
				}
			}
		}
		else
		{
			switch (param2)
			{
				case 8:
				{
					CreditsPanel3(param1);
				}
			}
		}
    }
}