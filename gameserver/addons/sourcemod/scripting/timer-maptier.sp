#pragma semicolon 1

#include <sourcemod>

#include <timer>
#include <timer-logging>
#include <timer-mysql>
#include <timer-mapzones>
#include <timer-maptier>
#include <timer-stocks>

new Handle:g_hSQL;

new String:g_currentMap[32];

new g_maptier[2];
new g_stagecount[2];

public Plugin:myinfo =
{
    name        = "[Timer] Map Tier System",
    author      = "Zipcore",
    description = "[Timer] Map tier system",
    version     = PL_VERSION,
    url         = "forums.alliedmods.net/showthread.php?p=2074699"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RegPluginLibrary("timer-maptier");
	
	CreateNative("Timer_GetTier", Native_GetMapTier);
	CreateNative("Timer_SetTier", Native_SetMapTier);
	
	CreateNative("Timer_GetStageCount", Native_GetStageCount);
	CreateNative("Timer_UpdateStageCount", Native_UpdateStageCount);

	return APLRes_Success;
}

public OnPluginStart()
{
	ConnectSQL();
	
	LoadTranslations("timer.phrases");
	
	RegAdminCmd("sm_maptier", Command_MapTier, ADMFLAG_RCON, "sm_maptier [bonus] [tier]");
	RegAdminCmd("sm_stagecount", Command_StageCount, ADMFLAG_RCON, "sm_stagecount [bonus]");
	
	AutoExecConfig(true, "timer-maptier");
}

public OnMapStart()
{
	ConnectSQL();
	GetCurrentMap(g_currentMap, sizeof(g_currentMap));
	
	g_maptier[0] = 0;
	g_maptier[1] = 0;
	g_stagecount[0] = 0;
	g_stagecount[1] = 0;
	
	if (g_hSQL != INVALID_HANDLE) LoadMapTier();
}

public OnTimerSqlConnected(Handle:sql)
{
	g_hSQL = sql;
	g_hSQL = INVALID_HANDLE;
	CreateTimer(0.1, Timer_SQLReconnect, _ , TIMER_FLAG_NO_MAPCHANGE);
}

public OnTimerSqlStop()
{
	g_hSQL = INVALID_HANDLE;
	CreateTimer(0.1, Timer_SQLReconnect, _ , TIMER_FLAG_NO_MAPCHANGE);
}

ConnectSQL()
{
	g_hSQL = Handle:Timer_SqlGetConnection();
	
	if (g_hSQL == INVALID_HANDLE)
		CreateTimer(0.1, Timer_SQLReconnect, _ , TIMER_FLAG_NO_MAPCHANGE);
	else LoadMapTier();
}

public Action:Timer_SQLReconnect(Handle:timer, any:data)
{
	ConnectSQL();
	return Plugin_Stop;
}

LoadMapTier()
{
	if (g_hSQL == INVALID_HANDLE)
		ConnectSQL();
	
	if (g_hSQL != INVALID_HANDLE)
	{
		decl String:query[128];
		FormatEx(query, sizeof(query), "SELECT tier, stagecount FROM maptier WHERE map = '%s' AND track = 0", g_currentMap);
		SQL_TQuery(g_hSQL, LoadTierCallback, query, 0, DBPrio_Normal);
		
		decl String:query2[128];
		FormatEx(query2, sizeof(query2), "SELECT tier, stagecount FROM maptier WHERE map = '%s' AND track = 1", g_currentMap);
		SQL_TQuery(g_hSQL, LoadTierCallback, query2, 1, DBPrio_Normal); 
	}
}

public LoadTierCallback(Handle:owner, Handle:hndl, const String:error[], any:track)
{
	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("SQL Error on LoadTier: %s", error);
		return;
	}
	
	while (SQL_FetchRow(hndl))
	{
		g_maptier[track] = SQL_FetchInt(hndl, 0);
		g_stagecount[track] = SQL_FetchInt(hndl, 1);
	}
	
	if (g_maptier[track] == 0)
	{
		decl String:query[128];
		FormatEx(query, sizeof(query), "INSERT INTO maptier (map, track, tier, stagecount) VALUES ('%s','%d','1', '0');", g_currentMap, track);

		if (g_hSQL == INVALID_HANDLE)
			ConnectSQL();
		
		if (g_hSQL != INVALID_HANDLE)
		{
			SQL_TQuery(g_hSQL, InsertTierCallback, query, track, DBPrio_Normal);
		}
	}
}

public InsertTierCallback(Handle:owner, Handle:hndl, const String:error[], any:track)
{
	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("SQL Error on InsertTier Map:%s (%d): %s", g_currentMap, track, error);
		return;
	}
	
	LoadMapTier();
}

public Action:Command_MapTier(client, args)
{
	if (args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_maptier [track] [tier]");
		return Plugin_Handled;	
	}
	else if (args == 2)
	{
		decl String:track[64];
		GetCmdArg(1,track,sizeof(track));
		decl String:tier[64];
		GetCmdArg(2,tier,sizeof(tier));
		Timer_SetTier(StringToInt(track), StringToInt(tier));	
	}
	return Plugin_Handled;	
}

public Action:Command_StageCount(client, args)
{
	if (args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_stagecount [track]");
		return Plugin_Handled;	
	}
	else if(args == 2)
	{
		decl String:track[64];
		GetCmdArg(1,track,sizeof(track));
		ReplyToCommand(client, "Stagecount updated, old was %d new is %d", g_stagecount[StringToInt(track)], Timer_UpdateStageCount(StringToInt(track)));
	}
	return Plugin_Handled;	
}

public UpdateTierCallback(Handle:owner, Handle:hndl, const String:error[], any:tier)
{
	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("SQL Error on UpdateTier: %s", error);
		return;
	}
	
	LoadMapTier();
}

public UpdateStageCountCallback(Handle:owner, Handle:hndl, const String:error[], any:tier)
{
	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("SQL Error on UpdateStageCount: %s", error);
		return;
	}
	
	LoadMapTier();
}

public Native_GetMapTier(Handle:plugin, numParams)
{
	return g_maptier[GetNativeCell(1)];
}

public Native_SetMapTier(Handle:plugin, numParams)
{
	new track = GetNativeCell(1);
	new tier = GetNativeCell(2);
	decl String:query[256];
	FormatEx(query, sizeof(query), "UPDATE maptier SET tier = '%d' WHERE map = '%s' AND track = '%d'", tier, g_currentMap, track);
	
	if (g_hSQL == INVALID_HANDLE)
		ConnectSQL();
	
	if (g_hSQL != INVALID_HANDLE)
		SQL_TQuery(g_hSQL, UpdateTierCallback, query, track, DBPrio_Normal);	
}

public Native_GetStageCount(Handle:plugin, numParams)
{
	return g_stagecount[GetNativeCell(1)];
}

public Native_UpdateStageCount(Handle:plugin, numParams)
{
	new track = GetNativeCell(1);
	if(track == 0)
		g_stagecount[track] = Timer_GetMapzoneCount(ZtLevel)+1;
	else if(track == 1)
		g_stagecount[track] = Timer_GetMapzoneCount(ZtBonusLevel)+1;
	
	decl String:query[256];
	FormatEx(query, sizeof(query), "UPDATE maptier SET stagecount = '%d' WHERE map = '%s' AND track = '%d'", g_stagecount[track], g_currentMap, track);
	SQL_TQuery(g_hSQL, UpdateStageCountCallback, query, track, DBPrio_Normal);
	
	return g_stagecount[track];
}