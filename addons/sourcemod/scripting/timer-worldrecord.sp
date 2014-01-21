#pragma semicolon 1

#include <sourcemod>
#include <adminmenu>

#include <timer>
#include <timer-logging>
#include <timer-stocks>
#include <timer-config_loader.sp>

//Max. number of records per style to cache
#define MAX_CACHE 1000

/**
 * Global Enums
 */
enum RecordCache
{
	Id,
	String:Name[32],
	String:Auth[32],
	
	Float:Time,
	String:TimeString[16],
	String:Date[32],
	
	Style,
	Jumps,
	Float:JumpAcc,
	Strafes,
	Float:StrafeAcc,
	Float:AvgSpeed,
	Float:MaxSpeed,
	Float:FinishSpeed,
	
	Flashbangcount,
	
	LevelProcess,
	
	CurrentRank,
	//LastSeenRank,
	//BestRank,
	
	FinishCount,
	//PersonalRecordCount,
	
	String:ReplayPath[32],
	
	String:Custom1[32],
	String:Custom2[32],
	String:Custom3[32],
	
	bool:Ignored
}

enum RecordStats
{
	RecordStatsCount,
	RecordStatsID,
	Float:RecordStatsBestTime,
	String:RecordStatsBestTimeString[16],
	String:RecordStatsName[32],
}

/**
 * Global Variables
 */

new Handle:g_hSQL;

new String:g_currentMap[64];
new g_reconnectCounter = 0;

new Handle:hTopMenu = INVALID_HANDLE;
new TopMenuObject:oMapZoneMenu;

new g_cache[MAX_MODES][3][MAX_CACHE][RecordCache];
new g_cachestats[MAX_MODES][3][RecordStats];
new g_cacheCount[MAX_MODES][3];
new bool:g_cacheLoaded[MAX_MODES][3];

new g_deleteMenuSelection[MAXPLAYERS+1];
new g_wrMenuMode[MAXPLAYERS+1];

new g_iAdminSelectedMode[MAXPLAYERS+1];
new g_iAdminSelectedBonus[MAXPLAYERS+1];

new bool:g_timer = false;
new bool:g_timerPhysics = false;
//new bool:g_timerMapzones = false;
//new bool:g_timerCpMod = false;
//new bool:g_timerLjStats = false;
new bool:g_timerLogging = false;
//new bool:g_timerMapTier = false;
//new bool:g_timerRankings = false;
//new bool:g_timerRankingsTopOnly = false;
//new bool:g_timerScripterDB = false;
//new bool:g_timerStrafes = false;
//new bool:g_timerTeams = false;
//new bool:g_timerWeapons = false;

public Plugin:myinfo =
{
    name        = "[Timer] World Record",
    author      = "Zipcore, Credits: Alongub",
    description = "World Record component for [Timer]",
    version     = PL_VERSION,
    url         = "zipcore#googlemail.com"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RegPluginLibrary("timer-worldrecord");
	
	CreateNative("Timer_ForceReloadCache", Native_ForceReloadCache);
	CreateNative("Timer_GetDifficultyRecordTime", Native_GetDifficultyRecordTime);
	CreateNative("Timer_GetDifficultyRank", Native_GetDifficultyRank);
	CreateNative("Timer_GetBestRound", Native_GetBestRound);
	CreateNative("Timer_GetNewPossibleRank", Native_GetNewPossibleRank);
	CreateNative("Timer_GetRankID", Native_GetRankID);
	CreateNative("Timer_GetRecordHolderName", Native_GetRecordHolderName);
	CreateNative("Timer_GetFinishCount", Native_GetFinishCount);
	CreateNative("Timer_GetRecordDate", Native_GetRecordDate);
	CreateNative("Timer_GetRecordSpeedInfo", Native_GetRecordSpeedInfo);
	CreateNative("Timer_GetRecordStrafeJumpInfo", Native_GetRecordStrafeJumpInfo);
	CreateNative("Timer_GetRecordTimeInfo", Native_GetRecordTimeInfo);
	CreateNative("Timer_GetReplayPath", Native_GetReplayPath);
	CreateNative("Timer_GetRecordCustom1", Native_GetCustom1);
	CreateNative("Timer_GetRecordCustom2", Native_GetCustom2);
	CreateNative("Timer_GetRecordCustom3", Native_GetCustom3);

	return APLRes_Success;
}

public OnPluginStart()
{
	LoadPhysics();
	LoadTimerSettings();
	
	ConnectSQL(true);
	
	g_timer = LibraryExists("timer");
	g_timerPhysics = LibraryExists("timer-physics");
	//g_timerMapzones = LibraryExists("timer-mapzones");
	//g_timerCpMod = LibraryExists("timer-cpmod");
	//g_timerLjStats = LibraryExists("timer-ljstats");
	g_timerLogging = LibraryExists("timer-logging");
	//g_timerMapTier = LibraryExists("timer-maptier");
	//g_timerRankings = LibraryExists("timer-rankings");
	//g_timerRankingsTopOnly = LibraryExists("timer-rankings_top_only");
	//g_timerScripterDB = LibraryExists("timer-scripter_db");
	//g_timerStrafes = LibraryExists("timer-strafes");
	//g_timerTeams = LibraryExists("timer-teams");
	//g_timerWeapons = LibraryExists("timer-weapons");
	
	LoadTranslations("timer.phrases");
	
	RegConsoleCmd("sm_top", Command_WorldRecord);
	RegConsoleCmd("sm_wr", Command_WorldRecord);
	if(g_Settings[BonusWrEnable]) 
	{
		RegConsoleCmd("sm_btop", Command_BonusWorldRecord);
		RegConsoleCmd("sm_bwr", Command_BonusWorldRecord);
	}
	if(g_Settings[ShortWrEnable]) 
	{
		RegConsoleCmd("sm_stop", Command_ShortWorldRecord);
		RegConsoleCmd("sm_swr", Command_ShortWorldRecord);
	}
	RegConsoleCmd("sm_record", Command_PersonalRecord);
	RegConsoleCmd("sm_rank", Command_PersonalRecord);
	//RegConsoleCmd("sm_delete", Command_Delete);
	RegConsoleCmd("sm_reloadcache", Command_ReloadCache);
	RegAdminCmd("sm_deleterecord_all", Command_DeletePlayerRecord_All, ADMFLAG_ROOT, "sm_deleterecord_all STEAM_ID");
	RegAdminCmd("sm_deleterecord_map", Command_DeletePlayerRecord_Map, ADMFLAG_ROOT, "sm_deleterecord_map STEAM_ID");
	RegAdminCmd("sm_deleterecord", Command_DeletePlayerRecord_ID, ADMFLAG_RCON, "sm_deleterecord RECORDID");
	RegAdminCmd("sm_deletemaprecords", Command_DeleteMapRecords_All, ADMFLAG_RCON, "sm_deleterecord MAPNAME");
	
	AutoExecConfig(true, "timer/timer-worldrecord");
	
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}	
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "timer"))
	{
		g_timer = true;
	}
	else if (StrEqual(name, "timer-physics"))
	{
		g_timerPhysics = true;
	}	
	else if (StrEqual(name, "timer-mapzones"))
	{
		//g_timerMapzones = true;
	}		
	else if (StrEqual(name, "timer-cpmod"))
	{
		//g_timerCpMod = true;
	}	
	else if (StrEqual(name, "timer-ljstats"))
	{
		//g_timerLjStats = true;
	}	
	else if (StrEqual(name, "timer-logging"))
	{
		g_timerLogging = true;
	}	
	else if (StrEqual(name, "timer-maptier"))
	{
		//g_timerMapTier = true;
	}	
	else if (StrEqual(name, "timer-rankings"))
	{
		//g_timerRankings = true;
	}		
	else if (StrEqual(name, "timer-rankings_top_only"))
	{
		//g_timerRankingsTopOnly = true;
	}
	else if (StrEqual(name, "timer-scripter_db"))
	{
		//g_timerScripterDB = true;
	}
	else if (StrEqual(name, "timer-strafes"))
	{
		//g_timerStrafes = true;
	}
	else if (StrEqual(name, "timer-teams"))
	{
		//g_timerTeams = true;
	}
	else if (StrEqual(name, "timer-weapons"))
	{
		//g_timerWeapons = true;
	}
}

public OnLibraryRemoved(const String:name[])
{	
	if (StrEqual(name, "timer"))
	{
		g_timer = false;
	}
	else if (StrEqual(name, "timer-physics"))
	{
		g_timerPhysics = false;
	}	
	else if (StrEqual(name, "timer-mapzones"))
	{
		//g_timerMapzones = false;
	}		
	else if (StrEqual(name, "timer-cpmod"))
	{
		//g_timerCpMod = false;
	}	
	else if (StrEqual(name, "timer-ljstats"))
	{
		//g_timerLjStats = false;
	}	
	else if (StrEqual(name, "timer-logging"))
	{
		g_timerLogging = false;
	}	
	else if (StrEqual(name, "timer-maptier"))
	{
		//g_timerMapTier = false;
	}	
	else if (StrEqual(name, "timer-rankings"))
	{
		//g_timerRankings = false;
	}		
	else if (StrEqual(name, "timer-rankings_top_only"))
	{
		//g_timerRankingsTopOnly = false;
	}
	else if (StrEqual(name, "timer-scripter_db"))
	{
		//g_timerScripterDB = false;
	}
	else if (StrEqual(name, "timer-strafes"))
	{
		//g_timerStrafes = false;
	}
	else if (StrEqual(name, "timer-teams"))
	{
		//g_timerTeams = false;
	}
	else if (StrEqual(name, "timer-weapons"))
	{
		//g_timerWeapons = false;
	}
	else if (StrEqual(name, "adminmenu"))
	{
		hTopMenu = INVALID_HANDLE;
	}
}

public OnMapStart()
{
	GetCurrentMap(g_currentMap, sizeof(g_currentMap));
	
	LoadPhysics();
	LoadTimerSettings();
	
	ClearCache();
	RefreshCache();
}

public Action:Command_WorldRecord(client, args)
{
	if (g_timerPhysics && g_Settings[MultimodeEnable])
		CreateRankedWRMenu(client);
	else
		CreateWRMenu(client, g_ModeDefault, 0);
	
	return Plugin_Handled;
}

public Action:Command_BonusWorldRecord(client, args)
{
	if (g_timerPhysics && g_Settings[MultimodeEnable])
		CreateRankedBWRMenu(client);
	else
		CreateWRMenu(client, g_ModeDefault, 1);
	
	return Plugin_Handled;
}

public Action:Command_ShortWorldRecord(client, args)
{
	if (g_timerPhysics && g_Settings[MultimodeEnable])
		CreateRankedSWRMenu(client);
	else
		CreateWRMenu(client, g_ModeDefault, 2);
	
	return Plugin_Handled;
}

public Action:Command_Delete(client, args)
{
	CreateDeleteMenu(client, client, g_currentMap);
	return Plugin_Handled;
}

public Action:Command_PersonalRecord(client, args)
{
	new argsCount = GetCmdArgs();
	new target = -1;
	

	if (argsCount == 0)
	{
		target = client;
	}
	else if (argsCount == 1)
	{
		decl String:name[64];
		GetCmdArg(1, name, sizeof(name));
		
		new targets[2];
		decl String:targetName[32];
		new bool:ml = false;

		if (ProcessTargetString(name, 0, targets, sizeof(targets), COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_NO_MULTI, targetName, sizeof(targetName), ml) > 0)
			target = targets[0];
	}

	if (target == -1)
	{
		CPrintToChat(client, PLUGIN_PREFIX, "No target");
	}
	else
	{
		new mode;
		if(g_timer) mode = Timer_GetMode(client);
		
		new bonus;
		if(g_timer) bonus = Timer_GetBonus(client);
		
		decl String:auth[32];
		GetClientAuthString(target, auth, sizeof(auth));

		for (new t = 0; t < g_cacheCount[mode][bonus]; t++)
		{
			if (StrEqual(g_cache[mode][bonus][t][Auth], auth))
			{
				g_wrMenuMode[client] = mode;
				CreatePlayerInfoMenu(client, g_cache[mode][bonus][t][Id], bonus);
				break;
			}
		}		
	}
	
	return Plugin_Handled;
}

public Action:Command_ReloadCache(client, args)
{
	RefreshCache();
	return Plugin_Handled;
}

public Action:Command_DeletePlayerRecord_All(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: sm_deleterecord_all <steamid>");
		return Plugin_Handled;
	}

	new String:auth[32];
	GetCmdArgString(auth, sizeof(auth));

	decl String:query[512];
	Format(query, sizeof(query), "DELETE FROM round WHERE auth = '%s'", auth);

	SQL_TQuery(g_hSQL, DeleteRecordsCallback, query, _, DBPrio_Normal);
	
	return Plugin_Handled;
}

public Action:Command_DeletePlayerRecord_Map(client, args)
{	
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: sm_deleterecord_map <steamid>");
		return Plugin_Handled;
	}
	
	new String:auth[32];
	GetCmdArgString(auth, sizeof(auth));

	decl String:query[512];
	Format(query, sizeof(query), "DELETE FROM round WHERE auth = '%s' AND map = '%s'", auth, g_currentMap);

	SQL_TQuery(g_hSQL, DeleteRecordsCallback, query, _, DBPrio_Normal);
	
	return Plugin_Handled;
}

public Action:Command_DeletePlayerRecord_ID(client, args)
{	
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: sm_deleterecord <recordid>");
		return Plugin_Handled;
	}
	
	new String:id[32];
	GetCmdArgString(id, sizeof(id));

	decl String:query[512];
	Format(query, sizeof(query), "DELETE FROM round WHERE id = '%s'", id);

	SQL_TQuery(g_hSQL, DeleteRecordsCallback, query, _, DBPrio_Normal);
	
	return Plugin_Handled;
}

public Action:Command_DeleteMapRecords_All(client, args)
{	
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: sm_deleterecord <mapname>");
		return Plugin_Handled;
	}
	
	new String:mapname[32];
	GetCmdArgString(mapname, sizeof(mapname));

	decl String:query[512];
	Format(query, sizeof(query), "DELETE FROM round WHERE map = '%s'", mapname);

	SQL_TQuery(g_hSQL, DeleteRecordsCallback, query, _, DBPrio_Normal);
	
	return Plugin_Handled;
}

public DeleteRecordsCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		if(g_timerLogging) Timer_LogError("SQL Error on DeleteRecord: %s", error);
		return;
	}

	RefreshCache();
}

public OnAdminMenuReady(Handle:topmenu)
{
	// Block this from being called twice
	if (topmenu == hTopMenu) {
		return;
	}
 
	// Save the Handle
	hTopMenu = topmenu;
		
	if ((oMapZoneMenu = FindTopMenuCategory(topmenu, "Timer Management")) == INVALID_TOPMENUOBJECT)
	{
		oMapZoneMenu = AddToTopMenu(hTopMenu,
			"Timer Management",
			TopMenuObject_Category,
			AdminMenu_CategoryHandler,
			INVALID_TOPMENUOBJECT);
	}
		
	AddToTopMenu(hTopMenu, 
		"timer_delete",
		TopMenuObject_Item,
		AdminMenu_DeleteRecord,
		oMapZoneMenu,
		"timer_delete",
		ADMFLAG_RCON);
		
	AddToTopMenu(hTopMenu, 
		"timer_deletemaprecords",
		TopMenuObject_Item,
		AdminMenu_DeleteMapRecords,
		oMapZoneMenu,
		"timer_deletemaprecords",
		ADMFLAG_RCON);		
}

public AdminMenu_CategoryHandler(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayTitle) {
		Format(buffer, maxlength, "%t", "Timer Management");
	} else if (action == TopMenuAction_DisplayOption) {
		Format(buffer, maxlength, "%t", "Timer Management");
	}
}

public AdminMenu_DeleteMapRecords(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption) {
		Format(buffer, maxlength, "%t", "Delete Map Records");
	} else if (action == TopMenuAction_SelectOption) {
		decl String:map[32];
		GetCurrentMap(map, sizeof(map));
		
		if(param == 0) DeleteMapRecords(map);
		else DeleteMapRecordsMenu(param);
	}
}

DeleteMapRecordsMenu(client)
{
	if (0 < client < MaxClients)
	{
		new Handle:menu = CreateMenu(Handle_DeleteMapRecordsMenu);
				
		SetMenuTitle(menu, "Are you sure!");
		
		AddMenuItem(menu, "no", "Oh no");		
		AddMenuItem(menu, "no", "Oh no");
		AddMenuItem(menu, "no", "Oh no");
		AddMenuItem(menu, "yes", "!!! YES DELETE ALL RECORDS !!!");		
		AddMenuItem(menu, "no", "Oh no");
		AddMenuItem(menu, "no", "Oh no");
		AddMenuItem(menu, "no", "Oh no");
		
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}
	
public Handle_DeleteMapRecordsMenu(Handle:menu, MenuAction:action, client, itemNum)
{
	if ( action == MenuAction_Select )
	{
		decl String:info[100], String:info2[100];
		new bool:found = GetMenuItem(menu, itemNum, info, sizeof(info), _, info2, sizeof(info2));
		if(found)
		{
			if(StrEqual(info, "yes"))
			{
				decl String:map[32];
				GetCurrentMap(map, sizeof(map));
				DeleteMapRecords(map);
			}
		}
	}
}

public AdminMenu_DeleteRecord(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			client,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption) 
	{
		Format(buffer, maxlength, "%t", "Delete Player Record");
	} else if (action == TopMenuAction_SelectOption) 
	{
		if(g_Settings[MultimodeEnable]) CreateAdminModeSelection(client);
		else CreateAdminBonusSelection(client);
	}
}

CreateAdminModeSelection(client)
{
	new Handle:menu = CreateMenu(MenuHandler_AdminModeSelection);

	SetMenuTitle(menu, "Select Mode");
	SetMenuExitButton(menu, true);
	
	new items = 0;
	
	for(new i = 0; i < MAX_MODES-1; i++) 
	{
		if(!g_Physics[i][ModeEnable])
			continue;
		
		decl String:text[92];
		Format(text, sizeof(text), "%s", g_Physics[i][ModeName]);
		
		decl String:text2[32];
		Format(text2, sizeof(text2), "%d", i);
		
		AddMenuItem(menu, text2, text);
		items++;
	}
	
	if(items > 0) DisplayMenu(menu, client, MENU_TIME_FOREVER);
	else CloseHandle(menu);
}

public MenuHandler_AdminModeSelection(Handle:menu, MenuAction:action, client, itemNum)
{
	if (action == MenuAction_End) 
	{
		RefreshCache();
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select) 
	{
		decl String:info[32];		
		GetMenuItem(menu, itemNum, info, sizeof(info));
		g_iAdminSelectedMode[client] = StringToInt(info);
		CreateAdminBonusSelection(client);
	}
}

CreateAdminBonusSelection(client)
{
	new Handle:menu = CreateMenu(MenuHandler_AdminBonusSelection);

	SetMenuTitle(menu, "Select Mode");
	SetMenuExitButton(menu, true);
	
	AddMenuItem(menu, "0", "Normal");
	if(g_Settings[BonusWrEnable]) 
		AddMenuItem(menu, "1", "Bonus");
	if(g_Settings[ShortWrEnable]) 
		AddMenuItem(menu, "2", "Short");
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_AdminBonusSelection(Handle:menu, MenuAction:action, client, itemNum)
{
	if (action == MenuAction_End) 
	{
		RefreshCache();
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select) 
	{
		decl String:info[32];		
		GetMenuItem(menu, itemNum, info, sizeof(info));
		g_iAdminSelectedBonus[client] = StringToInt(info);
		CreateAdminRecordSelection(client, g_iAdminSelectedMode[client], g_iAdminSelectedBonus[client]);
	}
}

CreateAdminRecordSelection(client, mode, bonus)
{
	new Handle:menu = CreateMenu(MenuHandler_SelectPlayer);

	SetMenuTitle(menu, "Select Record");
	SetMenuExitButton(menu, true);
	
	new items = 0; 
	
	for (new cache = 0; cache < g_cacheCount[mode][bonus]; cache++)
	{
		if (g_cache[mode][bonus][cache][Ignored])
			continue;
		
		decl String:text[92];
		Format(text, sizeof(text), "%s - %s", g_cache[mode][bonus][cache][TimeString], g_cache[mode][bonus][cache][Name]);
		
		if (g_Settings[JumpsEnable])
			Format(text, sizeof(text), "%s (%d %T)", text, g_cache[mode][bonus][cache][Jumps], "Jumps", client);

		decl String:text2[32];
		Format(text2, sizeof(text2), "%d", g_cache[mode][bonus][cache][Id]);
		AddMenuItem(menu, text2, text);
		items++;
	}

	if (items == 0)
	{
		CloseHandle(menu);
		return;
	}

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_SelectPlayer(Handle:menu, MenuAction:action, client, itemNum)
{
	if (action == MenuAction_End) 
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select) 
	{
		decl String:info[32];		
		GetMenuItem(menu, itemNum, info, sizeof(info));
		
		decl String:query[512];
		Format(query, sizeof(query), "DELETE FROM `round` WHERE id = '%s'", info);

		SQL_TQuery(g_hSQL, DeletePlayersRecordCallback, query, client, DBPrio_Normal);
		
		RefreshCache();
	}
}

public DeletePlayersRecordCallback(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl == INVALID_HANDLE)
	{
		if(g_timerLogging) Timer_LogError("SQL Error on DeletePlayerRecord: %s", error);
		return;
	}
	
	CreateAdminModeSelection(client);
}


DeleteMapRecords(const String:map[]) 
{
	decl String:query[512];
	Format(query, sizeof(query), "DELETE FROM `round` WHERE map = '%s'", map);	

	SQL_TQuery(g_hSQL, DeleteRecordsCallback, query, _, DBPrio_Normal);
}

RefreshCache()
{
	if (g_hSQL == INVALID_HANDLE)
	{
		ConnectSQL(true);
	}
	else
	{	
		for (new mode = 0; mode < MAX_MODES-1; mode++)
		{
			if(!g_Physics[mode][ModeEnable])
				continue;
			if(g_Physics[mode][ModeCategory] != MCategory_Ranked)
				continue;
			
			new bonus;
			
			g_cacheLoaded[mode][0] = false;
			decl String:query[2048];
			Format(query, sizeof(query), "SELECT m.id, m.auth, m.time, MAX(m.jumps) jumps, m.physicsdifficulty, m.name, m.date, m.finishcount, m.levelprocess, m.rank, m.jumpacc, m.finishspeed, m.maxspeed, m.avgspeed, m.strafes, m.strafeacc, m.replaypath, m.custom1, m.custom2, m.custom3 FROM round AS m INNER JOIN (SELECT MIN(n.time) time, n.auth FROM round n WHERE n.map = '%s' AND n.physicsdifficulty = %d AND n.bonus = '%d' GROUP BY n.auth) AS j ON (j.time = m.time AND j.auth = m.auth) WHERE m.map = '%s' AND m.physicsdifficulty = %d GROUP BY m.auth ORDER BY m.time ASC LIMIT 0, %d", g_currentMap, bonus, mode, g_currentMap, mode, MAX_CACHE);	
			
			SQL_TQuery(g_hSQL, RefreshCacheCallback, query, mode, DBPrio_Low);
			
			if(g_Settings[BonusWrEnable])
			{
				bonus = 1;
				g_cacheLoaded[mode][1] = false;
				decl String:queryb[2048];
				Format(query, sizeof(query), "SELECT m.id, m.auth, m.time, MAX(m.jumps) jumps, m.physicsdifficulty, m.name, m.date, m.finishcount, m.levelprocess, m.rank, m.jumpacc, m.finishspeed, m.maxspeed, m.avgspeed, m.strafes, m.strafeacc, m.replaypath, m.custom1, m.custom2, m.custom3 FROM round AS m INNER JOIN (SELECT MIN(n.time) time, n.auth FROM round n WHERE n.map = '%s' AND n.physicsdifficulty = %d AND n.bonus = '%d' GROUP BY n.auth) AS j ON (j.time = m.time AND j.auth = m.auth) WHERE m.map = '%s' AND m.physicsdifficulty = %d GROUP BY m.auth ORDER BY m.time ASC LIMIT 0, %d", g_currentMap, bonus, mode, g_currentMap, mode, MAX_CACHE);	
				
				SQL_TQuery(g_hSQL, RefreshBonusCacheCallback, queryb, mode, DBPrio_Low);
			}
			
			if(g_Settings[ShortWrEnable])
			{
				bonus = 2;
				g_cacheLoaded[mode][2] = false;
				decl String:queryc[2048];
				Format(query, sizeof(query), "SELECT m.id, m.auth, m.time, MAX(m.jumps) jumps, m.physicsdifficulty, m.name, m.date, m.finishcount, m.levelprocess, m.rank, m.jumpacc, m.finishspeed, m.maxspeed, m.avgspeed, m.strafes, m.strafeacc, m.replaypath, m.custom1, m.custom2, m.custom3 FROM round AS m INNER JOIN (SELECT MIN(n.time) time, n.auth FROM round n WHERE n.map = '%s' AND n.physicsdifficulty = %d AND n.bonus = '%d' GROUP BY n.auth) AS j ON (j.time = m.time AND j.auth = m.auth) WHERE m.map = '%s' AND m.physicsdifficulty = %d GROUP BY m.auth ORDER BY m.time ASC LIMIT 0, %d", g_currentMap, bonus, mode, g_currentMap, mode, MAX_CACHE);		
				
				SQL_TQuery(g_hSQL, RefreshShortCacheCallback, queryc, mode, DBPrio_Low);
			}
		}
	}
}

ClearCache()
{
	for (new bonus = 0; bonus < 3; bonus++)
	{
		//PrintToChatAll("Clear part %d/3", bonus+1);
		new count = 0;
		
		for (new mode = 0; mode < MAX_MODES; mode++)
		{
			for (new cache = 0; cache < MAX_CACHE; cache++)
			{
				if(!g_cache[mode][bonus][cache][Ignored])
					count++;
				
				g_cache[mode][bonus][cache][Ignored] = true;
				
				Format(g_cache[mode][bonus][cache][Name], 32, "");
				Format(g_cache[mode][bonus][cache][TimeString], 16, "");
				Format(g_cache[mode][bonus][cache][Date], 32, "");
				Format(g_cache[mode][bonus][cache][Auth], 32, "");
				
				g_cache[mode][bonus][cache][Time] = 0.0;
				g_cache[mode][bonus][cache][FinishCount] = 0;
				g_cache[mode][bonus][cache][Style] = 0;
				g_cache[mode][bonus][cache][CurrentRank] = 0;
				g_cache[mode][bonus][cache][Jumps] = 0;
				g_cache[mode][bonus][cache][JumpAcc] = 0.0;
				g_cache[mode][bonus][cache][Strafes] = 0;
				g_cache[mode][bonus][cache][StrafeAcc] = 0.0;
				g_cache[mode][bonus][cache][AvgSpeed] = 0.0;
				g_cache[mode][bonus][cache][MaxSpeed] = 0.0;
				g_cache[mode][bonus][cache][FinishSpeed] = 0.0;
				g_cache[mode][bonus][cache][Flashbangcount] = 0;
			}
		}
	}
}

CollectCache(bonus, any:mode, Handle:hndl)
{
	g_cacheCount[mode][bonus] = 0;
		
	while (SQL_FetchRow(hndl))
	{
		g_cache[mode][bonus][g_cacheCount[mode][bonus]][Id] = SQL_FetchInt(hndl, 0);
		SQL_FetchString(hndl, 1, g_cache[mode][bonus][g_cacheCount[mode][bonus]][Auth], 32);
		g_cache[mode][bonus][g_cacheCount[mode][bonus]][Time] = SQL_FetchFloat(hndl, 2);
		Timer_SecondsToTime(SQL_FetchFloat(hndl, 2), g_cache[mode][bonus][g_cacheCount[mode][bonus]][TimeString], 16, 2);
		g_cache[mode][bonus][g_cacheCount[mode][bonus]][Jumps] = SQL_FetchInt(hndl, 3);
		g_cache[mode][bonus][g_cacheCount[mode][bonus]][Style] = SQL_FetchInt(hndl, 4);
		SQL_FetchString(hndl, 5, g_cache[mode][bonus][g_cacheCount[mode][bonus]][Name], 32);
		SQL_FetchString(hndl, 6, g_cache[mode][bonus][g_cacheCount[mode][bonus]][Date], 32);
		g_cache[mode][bonus][g_cacheCount[mode][bonus]][FinishCount] = SQL_FetchInt(hndl, 7);
		g_cache[mode][bonus][g_cacheCount[mode][bonus]][CurrentRank] = SQL_FetchInt(hndl, 8);
		g_cache[mode][bonus][g_cacheCount[mode][bonus]][JumpAcc] = SQL_FetchFloat(hndl, 9);
		
		g_cache[mode][bonus][g_cacheCount[mode][bonus]][FinishSpeed] = SQL_FetchFloat(hndl, 10);
		g_cache[mode][bonus][g_cacheCount[mode][bonus]][MaxSpeed] = SQL_FetchFloat(hndl, 11);
		g_cache[mode][bonus][g_cacheCount[mode][bonus]][AvgSpeed] = SQL_FetchFloat(hndl, 12);
		g_cache[mode][bonus][g_cacheCount[mode][bonus]][Strafes] = SQL_FetchInt(hndl, 13);
		g_cache[mode][bonus][g_cacheCount[mode][bonus]][StrafeAcc] = SQL_FetchFloat(hndl, 14);
		SQL_FetchString(hndl, 15, g_cache[mode][bonus][g_cacheCount[mode][bonus]][ReplayPath], 32);
		SQL_FetchString(hndl, 16, g_cache[mode][bonus][g_cacheCount[mode][bonus]][Custom1], 32);
		SQL_FetchString(hndl, 17, g_cache[mode][bonus][g_cacheCount[mode][bonus]][Custom2], 32);
		SQL_FetchString(hndl, 18, g_cache[mode][bonus][g_cacheCount[mode][bonus]][Custom3], 32);
		
		g_cache[mode][bonus][g_cacheCount[mode][bonus]][Ignored] = false;
		
		g_cacheCount[mode][bonus]++;
	}
		
	g_cacheLoaded[mode][bonus] = true;
}

public RefreshCacheCallback(Handle:owner, Handle:hndl, const String:error[], any:mode)
{
	if (hndl == INVALID_HANDLE)
	{
		if(g_timerLogging) Timer_LogError("SQL Error on RefreshCache: %s", error);
		return;
	}
	
	CollectCache(TRACK_NORMAL, mode, hndl);
	
	CreateTimer(3.0, Timer_ReloadBestCache, mode, TIMER_FLAG_NO_MAPCHANGE);
}

public RefreshBonusCacheCallback(Handle:owner, Handle:hndl, const String:error[], any:mode)
{
	if (hndl == INVALID_HANDLE)
	{
		if(g_timerLogging) Timer_LogError("SQL Error on RefreshBonusCache: %s", error);
		return;
	}
	
	CollectCache(TRACK_SHORT, mode, hndl);
	
	CreateTimer(3.0, Timer_ReloadBestBonusCache, mode, TIMER_FLAG_NO_MAPCHANGE);
}

public RefreshShortCacheCallback(Handle:owner, Handle:hndl, const String:error[], any:mode)
{
	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("SQL Error on RefreshShortCache: %s", error);
		return;
	}
	
	CollectCache(TRACK_SHORT, mode, hndl);
	
	CreateTimer(3.0, Timer_ReloadBestShortCache, mode, TIMER_FLAG_NO_MAPCHANGE);
}

CollectBestCache(bonus, any:mode)
{
	g_cachestats[mode][bonus][RecordStatsCount] = 0;
	g_cachestats[mode][bonus][RecordStatsID] = 0;
	g_cachestats[mode][bonus][RecordStatsBestTime] = 0.0;
	Format(g_cachestats[mode][bonus][RecordStatsName], 32, "");
	Format(g_cachestats[mode][bonus][RecordStatsBestTimeString], 32, "");
	
	for (new i = 0; i < g_cacheCount[mode][bonus]; i++)
	{
		if(g_cache[mode][bonus][i][Time] <= 0.0)
			continue;
		
		g_cachestats[mode][bonus][RecordStatsCount]++;
		
		if(g_cachestats[mode][bonus][RecordStatsBestTime] == 0.0 || g_cachestats[mode][bonus][RecordStatsBestTime] > g_cache[mode][bonus][i][Time])
		{
			g_cachestats[mode][bonus][RecordStatsID] = g_cache[mode][bonus][i][Id];
			g_cachestats[mode][bonus][RecordStatsBestTime] = g_cache[mode][bonus][i][Time];
			Format(g_cachestats[mode][bonus][RecordStatsBestTimeString], 32, "%s", g_cache[mode][bonus][i][TimeString]);
			Format(g_cachestats[mode][bonus][RecordStatsName], 32, "%s", g_cache[mode][bonus][i][Name]);
		}
	}
}

public Action:Timer_ReloadBestCache(Handle:timer, Handle:mode)
{
	CollectBestCache(TRACK_NORMAL, mode);
	
	return Plugin_Stop;
}

public Action:Timer_ReloadBestBonusCache(Handle:timer, Handle:mode)
{
	CollectBestCache(TRACK_BONUS, mode);
	
	return Plugin_Stop;
}

public Action:Timer_ReloadBestShortCache(Handle:timer, Handle:mode)
{
	CollectBestCache(TRACK_SHORT, mode);
	
	return Plugin_Stop;
}

ConnectSQL(bool:refreshCache)
{
    if (g_hSQL != INVALID_HANDLE)
        CloseHandle(g_hSQL);
	
    g_hSQL = INVALID_HANDLE;

    if (SQL_CheckConfig("timer"))
	{
		SQL_TConnect(ConnectSQLCallback, "timer", refreshCache);
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
		if(g_timerLogging) Timer_LogError("Connection to SQL database has failed, Reason: %s", error);
		
		g_reconnectCounter++;
		ConnectSQL(data);
		
		return;
	}

	decl String:driver[16];
	SQL_GetDriverIdent(owner, driver, sizeof(driver));
	
	if (StrEqual(driver, "mysql", false))
		SQL_FastQuery(hndl, "SET NAMES 'utf8'");

	g_hSQL = CloneHandle(hndl);

	g_reconnectCounter = 1;

	if (data)
	{
		RefreshCache();	
	}
}

CreateRankedWRMenu(client)
{
	if(0 < client < MaxClients)
	{
		new Handle:menu = CreateMenu(MenuHandler_RankedWR);

		SetMenuTitle(menu, "World Record", client);
		
		SetMenuExitBackButton(menu, true);
		SetMenuExitButton(menu, true);
		
		new count = 0;
		new found = 0;
		
		new maxorder[3] = {0, ...};

		for(new i = 0; i < MAX_MODES-1; i++) 
		{
			if(!g_Physics[i][ModeEnable])
				continue;
			if(g_Physics[i][ModeCategory] != MCategory_Ranked)
				continue;
			
			if(g_Physics[i][ModeOrder] > maxorder[MCategory_Ranked])
				maxorder[MCategory_Ranked] = g_Physics[i][ModeOrder];
			
			count++;
		}
		
		for(new order = 0; order <= maxorder[MCategory_Ranked]; order++) 
		{
			for(new i = 0; i < MAX_MODES-1; i++) 
			{
				if(!g_Physics[i][ModeEnable])
					continue;
				if(g_Physics[i][ModeCategory] != MCategory_Ranked)
					continue;
				if(g_Physics[i][ModeOrder] != order)
					continue;
				
				found++;
				
				new String:buffer[8];
				IntToString(i, buffer, sizeof(buffer));
				
				AddMenuItem(menu, buffer, g_Physics[i][ModeName]);
			}
			
			if(found == count)
				break;
		}

		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

public MenuHandler_RankedWR(Handle:menu, MenuAction:action, client, itemNum)
{
	if (action == MenuAction_End) 
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select) 
	{
		decl String:info[8];		
		GetMenuItem(menu, itemNum, info, sizeof(info));
		
		CreateWRMenu(client, StringToInt(info), 0);
	}
}

CreateRankedBWRMenu(client)
{
	if(0 < client < MaxClients)
	{
		new Handle:menu = CreateMenu(MenuHandler_RankedBWR);

		SetMenuTitle(menu, "Bonus World Record", client);
		
		SetMenuExitBackButton(menu, true);
		SetMenuExitButton(menu, true);
		
		new count = 0;
		new found = 0;
		
		new maxorder[3] = {0, ...};

		for(new i = 0; i < MAX_MODES-1; i++) 
		{
			if(!g_Physics[i][ModeEnable])
				continue;
			if(g_Physics[i][ModeCategory] != MCategory_Ranked)
				continue;
			
			if(g_Physics[i][ModeOrder] > maxorder[MCategory_Ranked])
				maxorder[MCategory_Ranked] = g_Physics[i][ModeOrder];
			
			count++;
		}
		
		for(new order = 0; order <= maxorder[MCategory_Ranked]; order++) 
		{
			for(new i = 0; i < MAX_MODES-1; i++) 
			{
				if(!g_Physics[i][ModeEnable])
					continue;
				if(g_Physics[i][ModeCategory] != MCategory_Ranked)
					continue;
				if(g_Physics[i][ModeOrder] != order)
					continue;
				
				found++;
				
				new String:buffer[8];
				IntToString(i, buffer, sizeof(buffer));
				
				AddMenuItem(menu, buffer, g_Physics[i][ModeName]);
			}
			
			if(found == count)
				break;
		}

		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

public MenuHandler_RankedBWR(Handle:menu, MenuAction:action, client, itemNum)
{
	if (action == MenuAction_End) 
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select) 
	{
		decl String:info[32];		
		GetMenuItem(menu, itemNum, info, sizeof(info));
		
		CreateWRMenu(client, StringToInt(info), 1);
	}
}

CreateRankedSWRMenu(client)
{
	if(0 < client < MaxClients)
	{
		new Handle:menu = CreateMenu(MenuHandler_RankedSWR);

		SetMenuTitle(menu, "Short World Record", client);
		
		SetMenuExitBackButton(menu, true);
		SetMenuExitButton(menu, true);
		
		new count = 0;
		new found = 0;
		
		new maxorder[3] = {0, ...};

		for(new i = 0; i < MAX_MODES-1; i++) 
		{
			if(!g_Physics[i][ModeEnable])
				continue;
			if(g_Physics[i][ModeCategory] != MCategory_Ranked)
				continue;
			
			if(g_Physics[i][ModeOrder] > maxorder[MCategory_Ranked])
				maxorder[MCategory_Ranked] = g_Physics[i][ModeOrder];
			
			count++;
		}
		
		for(new order = 0; order <= maxorder[MCategory_Ranked]; order++) 
		{
			for(new i = 0; i < MAX_MODES-1; i++) 
			{
				if(!g_Physics[i][ModeEnable])
					continue;
				if(g_Physics[i][ModeCategory] != MCategory_Ranked)
					continue;
				if(g_Physics[i][ModeOrder] != order)
					continue;
				
				found++;
				
				new String:buffer[8];
				IntToString(i, buffer, sizeof(buffer));
				
				AddMenuItem(menu, buffer, g_Physics[i][ModeName]);
			}
			
			if(found == count)
				break;
		}

		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

public MenuHandler_RankedSWR(Handle:menu, MenuAction:action, client, itemNum)
{
	if (action == MenuAction_End) 
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select) 
	{
		decl String:info[32];		
		GetMenuItem(menu, itemNum, info, sizeof(info));
		
		CreateWRMenu(client, StringToInt(info), 2);
	}
}

CreateWRMenu(client, mode, bonus)
{
	new Handle:menu;

	new total = g_cacheCount[mode][bonus];
	
	if(bonus == 0)
	{
		menu = CreateMenu(MenuHandler_WR);
		SetMenuTitle(menu, "Top players on %s [%d total]", g_currentMap, total);
	}
	else if (bonus == 1) 
	{
		menu = CreateMenu(MenuHandler_BonusWR);
		SetMenuTitle(menu, "Bonus-Top players on %s [%d total]", g_currentMap, total);
	}
	else if (bonus == 2) 
	{
		menu = CreateMenu(MenuHandler_ShortWR);
		SetMenuTitle(menu, "Short-Top players on %s [%d total]", g_currentMap, total);
	}
	
	if (g_timerPhysics && g_Settings[MultimodeEnable])
		SetMenuExitBackButton(menu, true);
	else
		SetMenuExitButton(menu, true);
		
	new items = 0;
		
	for (new cache = 0; cache < g_cacheCount[mode][bonus]; cache++)
	{
		if (mode != -1)
		{
			decl String:id[64];
			IntToString(g_cache[mode][bonus][cache][Id], id, sizeof(id));
			
			decl String:text[92];
			Format(text, sizeof(text), "#%d | %s - %s", cache+1, g_cache[mode][bonus][cache][Name], g_cache[mode][bonus][cache][TimeString]);
			
			if (g_Settings[JumpsEnable])
				Format(text, sizeof(text), "%s (%d jumps)", text, g_cache[mode][bonus][cache][Jumps]);
			
			AddMenuItem(menu, id, text);
			items++;
		}
	}

	if (items == 0)
	{
		CloseHandle(menu);
		
		if (mode == -1)
			CPrintToChat(client, PLUGIN_PREFIX, "No Records");	
		else
		{
			CPrintToChat(client, PLUGIN_PREFIX, "No Difficulty Records");
			
			if(g_Settings[MultimodeEnable])
			{
				if(bonus == 1) CreateRankedBWRMenu(client);
				else if(bonus == 2) CreateRankedSWRMenu(client);
				else CreateRankedWRMenu(client);
			}
		}
	}
	else
	{
		g_wrMenuMode[client] = mode;
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

public MenuHandler_WR(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End) 
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel) 
	{
		if (param2 == MenuCancel_ExitBack) 
		{
			if (g_timerPhysics)
				CreateRankedWRMenu(param1);
		}
	} 
	else if (action == MenuAction_Select) 
	{
		decl String:info[64];		
		GetMenuItem(menu, param2, info, sizeof(info));
			
		CreatePlayerInfoMenu(param1, StringToInt(info), 0);
	}
}

public MenuHandler_BonusWR(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End) 
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel) 
	{
		if (param2 == MenuCancel_ExitBack) 
		{
			if (g_timerPhysics)
				CreateRankedBWRMenu(param1);
		}
	} 
	else if (action == MenuAction_Select) 
	{
		decl String:info[64];		
		GetMenuItem(menu, param2, info, sizeof(info));
			
		CreatePlayerInfoMenu(param1, StringToInt(info), 1);
	}
}

public MenuHandler_ShortWR(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End) 
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel) 
	{
		if (param2 == MenuCancel_ExitBack) 
		{
			if (g_timerPhysics)
				CreateRankedSWRMenu(param1);
		}
	} 
	else if (action == MenuAction_Select) 
	{
		decl String:info[64];		
		GetMenuItem(menu, param2, info, sizeof(info));
			
		CreatePlayerInfoMenu(param1, StringToInt(info), 2);
	}
}

CreatePlayerInfoMenu(client, id, bonus)
{
	new Handle:menu;

	if(bonus == 0)
	{
		menu = CreateMenu(MenuHandler_RankedWR);
	}
	else if(bonus == 1)
	{
		menu = CreateMenu(MenuHandler_RankedBWR);
	}
	else if(bonus == 2)
	{
		menu = CreateMenu(MenuHandler_RankedSWR);
	}
	
	new mode = g_wrMenuMode[client];

	SetMenuExitButton(menu, true);

	for (new cache = 0; cache < g_cacheCount[mode][bonus]; cache++)
	{
		if (g_cache[mode][bonus][cache][Id] == id)
		{
			decl String:difficulty[5];
			IntToString(mode, difficulty, sizeof(difficulty));
					
			decl String:text[92];

			SetMenuTitle(menu, "Record Info [ID: %d]\n \n", id);

			Format(text, sizeof(text), "Date: %s", g_cache[mode][bonus][cache][Date]);
			AddMenuItem(menu, difficulty, text);
			
			Format(text, sizeof(text), "Player: %s (%s)", g_cache[mode][bonus][cache][Name], g_cache[mode][bonus][cache][Auth]);
			AddMenuItem(menu, difficulty, text);

			Format(text, sizeof(text), "Rank: #%d (#%d) [FC: %d]", cache + 1, g_cache[mode][bonus][cache][CurrentRank], g_cache[mode][bonus][cache][FinishCount]);
			AddMenuItem(menu, difficulty, text);

			Format(text, sizeof(text), "Time: %s", g_cache[mode][bonus][cache][TimeString]);
			AddMenuItem(menu, difficulty, text);
			
			Format(text, sizeof(text), "Speed [Avg: %.2f | Max: %.2f | Fin: %.2f]", g_cache[mode][bonus][cache][AvgSpeed], g_cache[mode][bonus][cache][MaxSpeed], g_cache[mode][bonus][cache][FinishSpeed]);
			AddMenuItem(menu, difficulty, text);
			
			if (g_Settings[JumpsEnable])
			{
				Format(text, sizeof(text), "Jumps: %d", g_cache[mode][bonus][cache][Jumps]);
				Format(text, sizeof(text), "%s [%.2f ⁰⁄₀]", text, g_cache[mode][bonus][cache][JumpAcc]);
				AddMenuItem(menu, difficulty, text);
			}
			
			if (g_Settings[StrafesEnable])
			{
				Format(text, sizeof(text), "Strafes: %d", g_cache[mode][bonus][cache][Strafes]);
				Format(text, sizeof(text), "%s [%.2f ⁰⁄₀]", text, g_cache[mode][bonus][cache][StrafeAcc]);
				AddMenuItem(menu, difficulty, text);
			}
			
			if (g_Settings[MultimodeEnable])
			{
				Format(text, sizeof(text), "%Mode: %s", g_Physics[mode][ModeName]);
				AddMenuItem(menu, difficulty, text);
			}			

			break;
		}
		
	}

	DisplayMenu(menu, client, MENU_TIME_FOREVER);	
}

//g_cache[mode][bonus][cache][Ignored]
CreateDeleteMenu(client, target, String:targetmap[64], ignored = -1)
{	
	decl String:buffer[128];
	if(ignored != -1) 
		Format(buffer, sizeof(buffer), " AND NOT id = '%d'", ignored);
	
	if (g_hSQL == INVALID_HANDLE)
	{
		ConnectSQL(false);
	}
	else if(StrEqual(targetmap, g_currentMap))
	{
		decl String:auth[32];
		GetClientAuthString(target, auth, sizeof(auth));
			
		decl String:query[512];
		Format(query, sizeof(query), "SELECT id, time, jumps, physicsdifficulty, auth FROM `round` WHERE map = '%s' AND auth = '%s'%s ORDER BY physicsdifficulty, time, jumps", targetmap, auth, buffer);	
		
		g_deleteMenuSelection[client] = target;
		SQL_TQuery(g_hSQL, CreateDeleteMenuCallback, query, client, DBPrio_Normal);
	}	
	else
	{
		decl String:auth[32];
		GetClientAuthString(target, auth, sizeof(auth));
			
		decl String:query[512];
		Format(query, sizeof(query), "SELECT id, time, jumps, physicsdifficulty, auth FROM `round` WHERE map = '%s' AND auth = '%s'%s ORDER BY physicsdifficulty, time, jumps", targetmap, auth, buffer);	
		
		g_deleteMenuSelection[client] = target;
		SQL_TQuery(g_hSQL, CreateDeleteMenuCallback, query, client, DBPrio_Normal);
	}
}

public CreateDeleteMenuCallback(Handle:owner, Handle:hndl, const String:error[], any:client)
{	
	if (hndl == INVALID_HANDLE)
	{
		if(g_timerLogging) Timer_LogError("SQL Error on CreateDeleteMenu: %s", error);
		return;
	}

	new Handle:menu = CreateMenu(MenuHandler_DeleteRecord);

	SetMenuTitle(menu, "%T", "Delete Records", client);
	SetMenuExitButton(menu, true);
	
	decl String:auth[32];
	GetClientAuthString(client, auth, sizeof(auth));
			
	while (SQL_FetchRow(hndl))
	{
		decl String:steamid[32];
		SQL_FetchString(hndl, 4, steamid, sizeof(steamid));
		
		if (!StrEqual(steamid, auth))
		{
			CloseHandle(menu);
			return;
		}
		
		decl String:id[10];
		IntToString(SQL_FetchInt(hndl, 0), id, sizeof(id));

		decl String:time[16];
		Timer_SecondsToTime(SQL_FetchFloat(hndl, 1), time, sizeof(time), 3);
		
		decl String:value[92];
		Format(value, sizeof(value), "%s %s", time, g_Physics[SQL_FetchInt(hndl, 3)][ModeName]);
		
		if (g_Settings[JumpsEnable])
			Format(value, sizeof(value), "%s %T: %d", value, "Jumps", client, SQL_FetchInt(hndl, 2));
			
		AddMenuItem(menu, id, value);
	}

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_DeleteRecord(Handle:menu, MenuAction:action, client, itemNum)
{
	if (action == MenuAction_End) 
	{
		RefreshCache();
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select) 
	{
		
		decl String:info[32];		
		GetMenuItem(menu, itemNum, info, sizeof(info));
		
		//fake refresh
		CreateDeleteMenu(client, g_deleteMenuSelection[client], g_currentMap, StringToInt(info));
		
		decl String:query[384];
		Format(query, sizeof(query), "DELETE FROM `round` WHERE id = %s", info);	

		SQL_TQuery(g_hSQL, DeleteRecordCallback, query, client, DBPrio_Normal);
	}
}

public DeleteRecordCallback(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl == INVALID_HANDLE)
	{
		if(g_timerLogging) Timer_LogError("SQL Error on DeleteRecord: %s", error);
		return;
	}
}

public Native_ForceReloadCache(Handle:plugin, numParams)
{
	RefreshCache();
}

public Native_GetDifficultyRank(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	new bonus = GetNativeCell(2);
	new mode = GetNativeCell(3);
	
	decl String:auth[32];
	GetClientAuthString(client, auth, sizeof(auth));
	
	for (new cache = 0; cache < g_cacheCount[mode][bonus]; cache++)
	{
		if (StrEqual(g_cache[mode][bonus][cache][Auth], auth))
		{
			return cache+1;
		}
		
	}
	
	return 0;
}

public Native_GetDifficultyRecordTime(Handle:plugin, numParams)
{
	new mode = GetNativeCell(1);
	new bonus = GetNativeCell(2);
	
	SetNativeCellRef(3, g_cachestats[mode][bonus][RecordStatsID]);
	SetNativeCellRef(4, g_cachestats[mode][bonus][RecordStatsBestTime]);
	SetNativeCellRef(5, g_cachestats[mode][bonus][RecordStatsCount]);
	
	return true;
}

public Native_GetBestRound(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new mode = GetNativeCell(2);
	
	new bonus = GetNativeCell(3);
	
	decl String:auth[32];
	GetClientAuthString(client, auth, sizeof(auth));
	
	for (new cache = 0; cache < g_cacheCount[mode][bonus]; cache++)
	{
		if (StrEqual(g_cache[mode][bonus][cache][Auth], auth))
		{
			SetNativeCellRef(4, g_cache[mode][bonus][cache][Time]);
			SetNativeCellRef(5, g_cache[mode][bonus][cache][Jumps]);
			return true;
		}
		
	}
	
	return false;
}

public Native_GetNewPossibleRank(Handle:plugin, numParams)
{
	new mode = GetNativeCell(1);
	new bonus = GetNativeCell(2);
	new Float:time = GetNativeCell(3);
	
	if(time == 0.0)
		return -1;
	
	if(g_cache[mode][bonus][0][Time] == 0.0)
		return 1;
	
	for (new cache = 0; cache < g_cacheCount[mode][bonus]; cache++)
	{
		if (g_cache[mode][bonus][cache][Time] > time)
		{
			return cache+1;
		}
	}
	
	return g_cacheCount[mode][bonus]+1;
}

public Native_GetCacheMapName(Handle:plugin, numParams)
{
	new nlen = GetNativeCell(2); 
	
	if (nlen <= 0)
		return false;
	
	if (SetNativeString(1, g_currentMap, nlen, true) == SP_ERROR_NONE)
		return true;
	
	return false;
}

public Native_SetCacheMapName(Handle:plugin, numParams)
{
	new nlen = GetNativeCell(2); 
	new String:buffer[nlen];
	
	GetNativeString(1, buffer, nlen);
	
	Format(g_currentMap, sizeof(g_currentMap), "%s", buffer);
	
	RefreshCache();
	
	return true;
}

public Native_GetRankID(Handle:plugin, numParams)
{
	new mode = GetNativeCell(1);
	new bonus = GetNativeCell(2);
	new rank = GetNativeCell(3);
	
	if(rank > 0)
		return g_cache[mode][bonus][rank-1][Id];
	else return -1;
}

public Native_GetRecordHolderName(Handle:plugin, numParams)
{
	new mode = GetNativeCell(1);
	new bonus = GetNativeCell(2);
	new rank = GetNativeCell(3);
	new nlen = GetNativeCell(5); 
	
	if (nlen <= 0)
		return false;

	if(rank > 0 && bonus >= 0)
	{
		new String:buffer[nlen];
		Format(buffer, nlen, "%s", g_cache[mode][bonus][rank-1][Name]);
		if (SetNativeString(4, buffer, nlen, true) == SP_ERROR_NONE)
			return true;
	}
	
	return false;
}

public Native_GetRecordDate(Handle:plugin, numParams)
{
	new mode = GetNativeCell(1);
	new bonus = GetNativeCell(2);
	new rank = GetNativeCell(3);
	new nlen = GetNativeCell(5); 
	
	if (nlen <= 0)
		return false;

	if(rank > 0 && bonus >= 0)
	{
		new String:buffer[nlen];
		Format(buffer, nlen, "%s", g_cache[mode][bonus][rank-1][Date]);
		if (SetNativeString(4, buffer, nlen, true) == SP_ERROR_NONE)
			return true;
	}
	
	return false;
}

public Native_GetFinishCount(Handle:plugin, numParams)
{
	new mode = GetNativeCell(1);
	new bonus = GetNativeCell(2);
	new rank = GetNativeCell(3);
	
	if(rank > 0)
		return g_cache[mode][bonus][rank-1][FinishCount];
		
	return 0;
}

public Native_GetRecordTimeInfo(Handle:plugin, numParams)
{
	new mode = GetNativeCell(1);
	new bonus = GetNativeCell(2);
	new rank = GetNativeCell(3);
	
	new nlen = GetNativeCell(6);
	
	if (nlen <= 0)
		return false;
	
	if(rank > 0)
	{
		SetNativeCellRef(4, g_cache[mode][bonus][rank-1][Time]);
		
		new String:buffer[nlen];
		Format(buffer, nlen, "%s", g_cache[mode][bonus][rank-1][TimeString]);
		
		if (SetNativeString(5, buffer, nlen, true) == SP_ERROR_NONE)
			return true;
	}	

	return true;
}

public Native_GetRecordSpeedInfo(Handle:plugin, numParams)
{
	new mode = GetNativeCell(1);
	new bonus = GetNativeCell(2);
	new rank = GetNativeCell(3);
	
	if(rank > 0)
	{
		SetNativeCellRef(4, g_cache[mode][bonus][rank-1][AvgSpeed]);
		SetNativeCellRef(5, g_cache[mode][bonus][rank-1][MaxSpeed]);
		SetNativeCellRef(6, g_cache[mode][bonus][rank-1][FinishSpeed]);
	}	

	return true;
}

public Native_GetRecordStrafeJumpInfo(Handle:plugin, numParams)
{
	new mode = GetNativeCell(1);
	new bonus = GetNativeCell(2);
	new rank = GetNativeCell(3);
	
	if(rank > 0)
	{
		SetNativeCellRef(4, g_cache[mode][bonus][rank-1][Strafes]);
		SetNativeCellRef(5, g_cache[mode][bonus][rank-1][StrafeAcc]);
		SetNativeCellRef(6, g_cache[mode][bonus][rank-1][Jumps]);
		SetNativeCellRef(7, g_cache[mode][bonus][rank-1][JumpAcc]);
	}	

	return true;
}

public Native_GetReplayPath(Handle:plugin, numParams)
{
	new mode = GetNativeCell(1);
	new bonus = GetNativeCell(2);
	new rank = GetNativeCell(3);
	new nlen = GetNativeCell(5); 
	
	if (nlen <= 0)
		return false;

	if(rank > 0 && bonus >= 0)
	{
		new String:buffer[nlen];
		Format(buffer, nlen, "%s", g_cache[mode][bonus][rank-1][ReplayPath]);
		if (SetNativeString(4, buffer, nlen, true) == SP_ERROR_NONE)
			return true;
	}
	
	return false;
}

public Native_GetCustom1(Handle:plugin, numParams)
{
	new mode = GetNativeCell(1);
	new bonus = GetNativeCell(2);
	new rank = GetNativeCell(3);
	new nlen = GetNativeCell(5); 
	
	if (nlen <= 0)
		return false;

	if(rank > 0 && bonus >= 0)
	{
		new String:buffer[nlen];
		Format(buffer, nlen, "%s", g_cache[mode][bonus][rank-1][Custom1]);
		if (SetNativeString(4, buffer, nlen, true) == SP_ERROR_NONE)
			return true;
	}
	
	return false;
}

public Native_GetCustom2(Handle:plugin, numParams)
{
	new mode = GetNativeCell(1);
	new bonus = GetNativeCell(2);
	new rank = GetNativeCell(3);
	new nlen = GetNativeCell(5); 
	
	if (nlen <= 0)
		return false;

	if(rank > 0 && bonus >= 0)
	{
		new String:buffer[nlen];
		Format(buffer, nlen, "%s", g_cache[mode][bonus][rank-1][Custom2]);
		if (SetNativeString(4, buffer, nlen, true) == SP_ERROR_NONE)
			return true;
	}
	
	return false;
}


public Native_GetCustom3(Handle:plugin, numParams)
{
	new mode = GetNativeCell(1);
	new bonus = GetNativeCell(2);
	new rank = GetNativeCell(3);
	new nlen = GetNativeCell(5); 
	
	if (nlen <= 0)
		return false;

	if(rank > 0 && bonus >= 0)
	{
		new String:buffer[nlen];
		Format(buffer, nlen, "%s", g_cache[mode][bonus][rank-1][Custom3]);
		if (SetNativeString(4, buffer, nlen, true) == SP_ERROR_NONE)
			return true;
	}
	
	return false;
}

