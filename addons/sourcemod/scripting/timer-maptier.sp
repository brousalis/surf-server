#pragma semicolon 1

#include <sourcemod>

#include <timer>
#include <timer-logging>
#include <timer-mapzones>
#include <timer-maptier>
#include <timer-stocks>

new Handle:g_hSQL;

new String:g_currentMap[32];
new g_reconnectCounter = 0;

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
	
	RegAdminCmd("sm_maptier", Command_MapTier, ADMFLAG_RCON, "sm_maptier");
	RegAdminCmd("sm_stagecount", Command_StageCount, ADMFLAG_RCON, "sm_stagecount");
	
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
		SQL_FastQuery(hndl, "SET NAMES  'utf8'");
		SQL_TQuery(g_hSQL, CreateSQLTableCallback, "CREATE TABLE IF NOT EXISTS `maptier` (`id` int(11) NOT NULL AUTO_INCREMENT, `map` varchar(32) NOT NULL, `bonus` int(11) NOT NULL, `tier` int(11) NOT NULL, `stagecount` int(11) NOT NULL, PRIMARY KEY (`id`));");
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
	
	LoadMapTier();
}

LoadMapTier()
{
	if (g_hSQL != INVALID_HANDLE)
	{
		new bonus; //0=normal
		decl String:query[128];
		Format(query, sizeof(query), "SELECT tier, stagecount FROM maptier WHERE map = '%s' AND bonus = '%d'", g_currentMap, bonus);
		SQL_TQuery(g_hSQL, LoadTierCallback, query, bonus, DBPrio_Normal);   
		
		bonus = 1; //1=bonus
		decl String:query2[128];
		Format(query2, sizeof(query2), "SELECT tier, stagecount FROM maptier WHERE map = '%s' AND bonus = '%d'", g_currentMap, bonus);
		SQL_TQuery(g_hSQL, LoadTierCallback, query, bonus, DBPrio_Normal); 
	}
}	

public LoadTierCallback(Handle:owner, Handle:hndl, const String:error[], any:bonus)
{
	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("SQL Error on LoadTier: %s", error);
		return;
	}
	
	while (SQL_FetchRow(hndl))
	{
		g_maptier[bonus] = SQL_FetchInt(hndl, 0);
		g_stagecount[bonus] = SQL_FetchInt(hndl, 1);
	}
	
	if (g_maptier[bonus] == 0 && g_stagecount[bonus] == 0)
	{
		decl String:query[128];
		Format(query, sizeof(query), "INSERT INTO maptier (map, bonus, tier, stagecount) VALUES ('%s','%d','1', '1');", g_currentMap, bonus);

		SQL_TQuery(g_hSQL, InsertTierCallback, query, bonus, DBPrio_Normal);
	}
}

public InsertTierCallback(Handle:owner, Handle:hndl, const String:error[], any:bonus)
{
	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("SQL Error on InsertTier Map:%s (%d): %s", g_currentMap, bonus, error);
		return;
	}
	
	LoadMapTier();
}

public Action:Command_MapTier(client, args)
{
	if (args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_maptier [bonus] [tier]");
		return Plugin_Handled;	
	}
	else if (args == 2)
	{
		decl String:bonus[64];
		GetCmdArg(1,bonus,sizeof(bonus));
		decl String:tier[64];
		GetCmdArg(2,tier,sizeof(tier));
		Timer_SetTier(StringToInt(bonus), StringToInt(tier));	
	}
	return Plugin_Handled;	
}

public Action:Command_StageCount(client, args)
{
	if (args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_stagecount [bonus]");
		return Plugin_Handled;	
	}
	else if(args == 2)
	{
		decl String:bonus[64];
		GetCmdArg(1,bonus,sizeof(bonus));
		ReplyToCommand(client, "Stagecount updated, old was %d new is %d", g_stagecount[StringToInt(bonus)], Timer_UpdateStageCount(StringToInt(bonus)));
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
	new bonus = GetNativeCell(1);
	new tier = GetNativeCell(2);
	decl String:query[256];
	Format(query, sizeof(query), "UPDATE maptier SET tier = '%d' WHERE map = '%s' AND bonus = '%d'", tier, g_currentMap, bonus);
	SQL_TQuery(g_hSQL, UpdateTierCallback, query, bonus, DBPrio_Normal);	
}

public Native_GetStageCount(Handle:plugin, numParams)
{
	return g_stagecount[GetNativeCell(1)];
}

public Native_UpdateStageCount(Handle:plugin, numParams)
{
	new bonus = GetNativeCell(1);
	if(bonus == 0)
		g_stagecount[bonus] = Timer_GetMapzoneCount(ZtLevel)+1;
	else if(bonus == 1)
		g_stagecount[bonus] = Timer_GetMapzoneCount(ZtBonusLevel)+1;
	
	decl String:query[256];
	Format(query, sizeof(query), "UPDATE maptier SET stagecount = '%d' WHERE map = '%s' AND bonus = '%d'", g_stagecount[bonus], g_currentMap, bonus);
	SQL_TQuery(g_hSQL, UpdateStageCountCallback, query, bonus, DBPrio_Normal);
	
	return g_stagecount[bonus];
}