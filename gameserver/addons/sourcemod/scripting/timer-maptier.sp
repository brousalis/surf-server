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

new Handle:g_OnMapTiersLoaded;

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
	
	CreateNative("Timer_GetTier", Native_GetTier);
	CreateNative("Timer_SetTier", Native_SetTier);
	CreateNative("Timer_GetMapTier", Native_GetMapTier);
	
	CreateNative("Timer_GetStageCount", Native_GetStageCount);
	CreateNative("Timer_GetMapStageCount", Native_GetMapStageCount);
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
	
	g_OnMapTiersLoaded = CreateGlobalForward("OnMapTiersLoaded", ET_Event);
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
		
		FormatEx(query, sizeof(query), "SELECT tier, stagecount FROM maptier WHERE map = '%s' AND track = 1", g_currentMap);
		SQL_TQuery(g_hSQL, LoadTierCallback, query, 1, DBPrio_Normal); 
		
		Format(query, sizeof(query), "SELECT map, track, tier, stagecount FROM maptier");
		SQL_TQuery(g_hSQL, LoadTierAllCallback, query, _, DBPrio_Normal);
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

new Handle:g_hMaps = INVALID_HANDLE;

public LoadTierAllCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("SQL Error on LoadTier: %s", error);
		return;
	}
	
	if(g_hMaps != INVALID_HANDLE)
	{
		CloseHandle(g_hMaps);
		g_hMaps = INVALID_HANDLE;
	}
	
	g_hMaps = CreateKeyValues("data");
	
	while (SQL_FetchRow(hndl))
	{
		decl String:map[32];
		SQL_FetchString(hndl, 0, map, sizeof(map));
		new tier = SQL_FetchInt(hndl, 1);
		new track = SQL_FetchInt(hndl, 2);
		new stagecount = SQL_FetchInt(hndl, 3);
		
		KvJumpToKey(g_hMaps, map, true);
		
		if(track == TRACK_NORMAL)
		{
			KvSetNum(g_hMaps, "tier", tier);
			KvSetNum(g_hMaps, "stagecount", stagecount);
		}
		else if(track == TRACK_BONUS)
		{
			KvSetNum(g_hMaps, "tier_bonus", tier);
			KvSetNum(g_hMaps, "stagecount_bonus", stagecount);
		}
		
		KvRewind(g_hMaps);
	}
	
	Call_StartForward(g_OnMapTiersLoaded);
	Call_Finish();
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

public Native_GetTier(Handle:plugin, numParams)
{
	return g_maptier[GetNativeCell(1)];
}

public Native_SetTier(Handle:plugin, numParams)
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

public Native_GetMapTier(Handle:plugin, numParams)
{
	decl String:map[32];
	GetNativeString(1, map, sizeof(map));
	new track = GetNativeCell(2);
	new tier = 1;
	
	if(g_hMaps == INVALID_HANDLE)
		return -1;
	
	new Handle:hMaps = CloneHandle(g_hMaps);
	
	if(KvJumpToKey(hMaps, map, false))
	{
		if(track == TRACK_NORMAL)
		{
			tier = KvGetNum(hMaps, "tier");
		}
		else if(track == TRACK_BONUS)
		{
			tier = KvGetNum(hMaps, "tier_bonus");
		}
	}
	CloseHandle(hMaps);
	
	return tier;
}

public Native_GetStageCount(Handle:plugin, numParams)
{
	return g_stagecount[GetNativeCell(1)];
}

public Native_GetMapStageCount(Handle:plugin, numParams)
{
	decl String:map[32];
	GetNativeString(1, map, sizeof(map));
	new track = GetNativeCell(2);
	new stagecount = 1;
	
	if(g_hMaps == INVALID_HANDLE)
		return -1;
	
	new Handle:hMaps = CloneHandle(g_hMaps);
	if(KvJumpToKey(hMaps, map, false))
	{
		if(track == TRACK_NORMAL)
		{
			stagecount = KvGetNum(hMaps, "stagecount");
		}
		else if(track == TRACK_BONUS)
		{
			stagecount = KvGetNum(hMaps, "stagecount_bonus");
		}
	}
	CloseHandle(hMaps);
	
	return stagecount;
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