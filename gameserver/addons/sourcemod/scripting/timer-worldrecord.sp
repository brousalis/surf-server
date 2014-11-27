#pragma semicolon 1

#include <sourcemod>
#include <adminmenu>

#include <timer>
#include <timer-logging>
#include <timer-stocks>
#include <timer-config_loader.sp>

//Max. number of records per style to cache

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
	Stage,
	CurrentRank,
	FinishCount,
	String:ReplayFile[32],
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
 * New World Record Cache
 */
 
new Handle:g_hCache[MAX_STYLES][MAX_TRACKS];
new nCacheTemplate[RecordCache];

/**
 * Old World Record Cache
 */
 
//new g_cache[MAX_STYLES][3][MAX_CACHE][RecordCache];

/**
 * World Record Cache
 */

new g_cachestats[MAX_STYLES][MAX_TRACKS][RecordStats];
new bool:g_cacheLoaded[MAX_STYLES][MAX_TRACKS];

/**
 * Global Variables
 */

new Handle:g_hSQL;

new String:g_currentMap[64];
new g_reconnectCounter = 0;

new Handle:hTopMenu = INVALID_HANDLE;
new TopMenuObject:oMapZoneMenu;

new g_deleteMenuSelection[MAXPLAYERS+1];
new g_wrStyleMode[MAXPLAYERS+1];

new g_iAdminSelectedStyle[MAXPLAYERS+1];
new g_iAdminSelectedTrack[MAXPLAYERS+1];

new bool:g_timerPhysics = false;

new Handle:g_OnRecordCacheLoaded;

public Plugin:myinfo =
{
    name        = "[Timer] World Record",
    author      = "Zipcore, Credits: Alongub",
    description = "[Timer] Player ranking by finish time",
    version     = PL_VERSION,
    url         = "forums.alliedmods.net/showthread.php?p=2074699"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RegPluginLibrary("timer-worldrecord");
	
	CreateNative("Timer_ForceReloadCache", Native_ForceReloadCache);
	CreateNative("Timer_GetStyleRecordWRStats", Native_GetStyleRecordWRStats);
	CreateNative("Timer_GetStyleRank", Native_GetStyleRank);
	CreateNative("Timer_GetStyleTotalRank", Native_GetStyleTotalRank);
	CreateNative("Timer_GetBestRound", Native_GetBestRound);
	CreateNative("Timer_GetNewPossibleRank", Native_GetNewPossibleRank);
	CreateNative("Timer_GetRankID", Native_GetRankID);
	CreateNative("Timer_GetRecordHolderName", Native_GetRecordHolderName);
	CreateNative("Timer_GetRecordHolderAuth", Native_GetRecordHolderAuth);
	CreateNative("Timer_GetFinishCount", Native_GetFinishCount);
	CreateNative("Timer_GetRecordDate", Native_GetRecordDate);
	CreateNative("Timer_GetRecordSpeedInfo", Native_GetRecordSpeedInfo);
	CreateNative("Timer_GetRecordStrafeJumpInfo", Native_GetRecordStrafeJumpInfo);
	CreateNative("Timer_GetRecordTimeInfo", Native_GetRecordTimeInfo);
	CreateNative("Timer_GetReplayPath", Native_GetReplayPath);
	CreateNative("Timer_GetReplayFileName", Native_GetReplayFileName);
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
	
	g_timerPhysics = LibraryExists("timer-physics");
	
	LoadTranslations("timer.phrases");
	
	RegConsoleCmd("sm_top", Command_WorldRecord);
	RegConsoleCmd("sm_wr", Command_WorldRecord);
	if(g_Settings[BonusWrEnable]) 
	{
		RegConsoleCmd("sm_btop", Command_BonusWorldRecord);
		RegConsoleCmd("sm_topb", Command_BonusWorldRecord);
		RegConsoleCmd("sm_bwr", Command_BonusWorldRecord);
		RegConsoleCmd("sm_wrb", Command_BonusWorldRecord);
	}
	if(g_Settings[ShortWrEnable]) 
	{
		RegConsoleCmd("sm_stop", Command_ShortWorldRecord);
		RegConsoleCmd("sm_swr", Command_ShortWorldRecord);
	}
	RegConsoleCmd("sm_record", Command_PersonalRecord);
	RegConsoleCmd("sm_rank", Command_PersonalRecord);
	//RegConsoleCmd("sm_delete", Command_Delete);
	RegAdminCmd("sm_reloadcache", Command_ReloadCache, ADMFLAG_RCON, "refresh records cache");
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
	
	g_OnRecordCacheLoaded = CreateGlobalForward("OnRecordCacheLoaded", ET_Event, Param_Cell, Param_Cell);

	for(new i = 0; i < MAX_STYLES-1; i++) 
	{
		if(!StrEqual(g_Physics[i][StyleQuickWrCommand], ""))
		{
			RegConsoleCmd(g_Physics[i][StyleQuickWrCommand], Callback_Empty);
			AddCommandListener(Hook_WrCommands, g_Physics[i][StyleQuickWrCommand]);
		}
		if(!StrEqual(g_Physics[i][StyleQuickBonusWrCommand], ""))
		{
			RegConsoleCmd(g_Physics[i][StyleQuickBonusWrCommand], Callback_Empty);
			AddCommandListener(Hook_WrCommands, g_Physics[i][StyleQuickBonusWrCommand]);
		}
		if(!StrEqual(g_Physics[i][StyleQuickShortWrCommand], ""))
		{
			RegConsoleCmd(g_Physics[i][StyleQuickShortWrCommand], Callback_Empty);
			AddCommandListener(Hook_WrCommands, g_Physics[i][StyleQuickShortWrCommand]);
		}
	}
	
	CacheReset();
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "timer-physics"))
	{
		g_timerPhysics = true;
	}	
}

public OnLibraryRemoved(const String:name[])
{	
	if (StrEqual(name, "timer-physics"))
	{
		g_timerPhysics = false;
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
	
	CacheReset();
	RefreshCache();
}

public OnMapEnd()
{
	UpdateRanks();
}

UpdateRanks()
{
	if (g_hSQL == INVALID_HANDLE)
		return;
	
	for(new track = 0; track < TRACK_SHORT; track++) 
	{
		for(new style = 0; style < g_StyleCount; style++) 
		{
			if(!g_Physics[style][StyleEnable])
				continue;
			
			if(g_Physics[style][StyleCategory] == MCategory_Ranked)
			{
				decl String:query[2048];
				FormatEx(query, sizeof(query), "SET @r=0;");
				SQL_TQuery(g_hSQL, UpdateRanksCallback, query, _, DBPrio_High);
				FormatEx(query, sizeof(query), "UPDATE `round` SET `rank` = @r:= (@r+1) WHERE `map` = '%s' AND `style` = %d AND `track` = %d  ORDER BY `time` ASC;", g_currentMap, style, track);
				SQL_TQuery(g_hSQL, UpdateRanksCallback, query, _, DBPrio_High);
			}
		}
	}
}

public UpdateRanksCallback(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("SQL Error on UpdateRanks: %s", error);
		return;
	}
}

public Action:Command_WorldRecord(client, args)
{
	if (g_timerPhysics && g_Settings[MultimodeEnable])
		CreateRankedWRMenu(client);
	else
		CreateWRMenu(client, g_StyleDefault, TRACK_NORMAL);
	
	return Plugin_Handled;
}

public Action:Command_BonusWorldRecord(client, args)
{
	if (g_timerPhysics && g_Settings[MultimodeEnable])
		CreateRankedBWRMenu(client);
	else
		CreateWRMenu(client, g_StyleDefault, TRACK_BONUS);
	
	return Plugin_Handled;
}

public Action:Command_ShortWorldRecord(client, args)
{
	if (g_timerPhysics && g_Settings[MultimodeEnable])
		CreateRankedSWRMenu(client);
	else
		CreateWRMenu(client, g_StyleDefault, TRACK_SHORT);
	
	return Plugin_Handled;
}

public Action:Hook_WrCommands(client, const String:sCommand[], argc)
{
	if (!IsValidClient(client))
	{
		return Plugin_Continue;
	}
	for(new i = 0; i < MAX_STYLES-1; i++) 
	{
		if(!g_Physics[i][StyleEnable])
			continue;
		
		if(g_Physics[i][StyleCategory] != MCategory_Ranked)
			continue;
		
		if(!StrEqual(g_Physics[i][StyleQuickWrCommand], ""))
		if(StrEqual(g_Physics[i][StyleQuickWrCommand], sCommand))
		{
			CreateWRMenu(client, i, TRACK_NORMAL);
			return Plugin_Handled;
		}
		
		if(!StrEqual(g_Physics[i][StyleQuickBonusWrCommand], ""))
		if(StrEqual(g_Physics[i][StyleQuickBonusWrCommand], sCommand))
		{
			CreateWRMenu(client, i, TRACK_BONUS);
			return Plugin_Handled;
		}
		
		if(!StrEqual(g_Physics[i][StyleQuickShortWrCommand], ""))
		if(StrEqual(g_Physics[i][StyleQuickShortWrCommand], sCommand))
		{
			CreateWRMenu(client, i, TRACK_SHORT);
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

public Action:Callback_Empty(client, args)
{
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
		new style = Timer_GetStyle(client);
		
		new track = Timer_GetTrack(client);
		
		decl String:auth[32];
		GetClientAuthString(target, auth, sizeof(auth));
		
		for (new i = 0; i < GetArraySize(g_hCache[style][track]); i++)
		{
			new nCache[RecordCache];
			GetArrayArray(g_hCache[style][track], i, nCache[0]);
			
			if (StrEqual(nCache[Auth], auth))
			{
				g_wrStyleMode[client] = style;
				CreatePlayerInfoMenu(client, nCache[Id], track);
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
	FormatEx(query, sizeof(query), "DELETE FROM round WHERE auth = '%s'", auth);

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
	FormatEx(query, sizeof(query), "DELETE FROM round WHERE auth = '%s' AND map = '%s'", auth, g_currentMap);

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
	FormatEx(query, sizeof(query), "DELETE FROM round WHERE id = '%s'", id);

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
	FormatEx(query, sizeof(query), "DELETE FROM round WHERE map = '%s'", mapname);

	SQL_TQuery(g_hSQL, DeleteRecordsCallback, query, _, DBPrio_Normal);
	
	return Plugin_Handled;
}

public DeleteRecordsCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("SQL Error on DeleteRecord: %s", error);
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
	
	if ((oMapZoneMenu = FindTopMenuCategory(topmenu, "Timer Records")) == INVALID_TOPMENUOBJECT)
	{
		oMapZoneMenu = AddToTopMenu(hTopMenu,"Timer Records",TopMenuObject_Category,AdminMenu_CategoryHandler,INVALID_TOPMENUOBJECT);
	}
		
	AddToTopMenu(hTopMenu, "timer_delete",TopMenuObject_Item,AdminMenu_DeleteRecord,
	oMapZoneMenu,"timer_delete",ADMFLAG_RCON);
		
	AddToTopMenu(hTopMenu, "timer_deletemaprecords",TopMenuObject_Item,AdminMenu_DeleteMapRecords,
	oMapZoneMenu,"timer_deletemaprecords",ADMFLAG_RCON);
	
	AddToTopMenu(hTopMenu, "sm_reloadcache", TopMenuObject_Item,AdminMenu_ReloadCache, 
	oMapZoneMenu, "sm_reloadcache",ADMFLAG_CHANGEMAP);
}

public AdminMenu_CategoryHandler(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayTitle) {
		FormatEx(buffer, maxlength, "Timer Records");
	} else if (action == TopMenuAction_DisplayOption) {
		FormatEx(buffer, maxlength, "Timer Records");
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
		FormatEx(buffer, maxlength, "Delete Records");
	} else if (action == TopMenuAction_SelectOption) {
		decl String:map[32];
		GetCurrentMap(map, sizeof(map));
		
		if(param == 0) DeleteMapRecords(map);
		else DeleteMapRecordsMenu(param);
	}
}

public AdminMenu_ReloadCache(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			client,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption) 
	{
		FormatEx(buffer, maxlength, "Refresh Cache");
	} else if (action == TopMenuAction_SelectOption) 
	{
		CPrintToChatAll(PLUGIN_PREFIX, "Word Record Cache Loaded");
		RefreshCache();
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
		FormatEx(buffer, maxlength, "Delete Single Record");
	} else if (action == TopMenuAction_SelectOption) 
	{
		if(g_Settings[MultimodeEnable]) CreateAdminModeSelection(client);
		else CreateAdminTrackSelection(client);
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

CreateAdminModeSelection(client)
{
	new Handle:menu = CreateMenu(MenuHandler_AdminModeSelection);

	SetMenuTitle(menu, "Select Style");
	SetMenuExitButton(menu, true);
	
	new items = 0;
	
	for(new i = 0; i < MAX_STYLES-1; i++) 
	{
		if(!g_Physics[i][StyleEnable])
			continue;
		
		decl String:text[92];
		FormatEx(text, sizeof(text), "%s", g_Physics[i][StyleName]);
		
		decl String:text2[32];
		FormatEx(text2, sizeof(text2), "%d", i);
		
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
		g_iAdminSelectedStyle[client] = StringToInt(info);
		CreateAdminTrackSelection(client);
	}
}

CreateAdminTrackSelection(client)
{
	new Handle:menu = CreateMenu(MenuHandler_AdminTrackSelection);

	SetMenuTitle(menu, "Select Style");
	SetMenuExitButton(menu, true);
	
	AddMenuItem(menu, "0", "Normal");
	if(g_Settings[BonusWrEnable]) 
		AddMenuItem(menu, "1", "Bonus");
	if(g_Settings[ShortWrEnable]) 
		AddMenuItem(menu, "2", "Short");
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_AdminTrackSelection(Handle:menu, MenuAction:action, client, itemNum)
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
		g_iAdminSelectedTrack[client] = StringToInt(info);
		CreateAdminRecordSelection(client, g_iAdminSelectedStyle[client], g_iAdminSelectedTrack[client]);
	}
}

CreateAdminRecordSelection(client, style, track)
{
	new Handle:menu = CreateMenu(MenuHandler_SelectPlayer);

	SetMenuTitle(menu, "Select Record");
	SetMenuExitButton(menu, true);
	
	new items = 0; 
	
	
	for (new i = 0; i < GetArraySize(g_hCache[style][track]); i++)
	{
		new nCache[RecordCache];
		GetArrayArray(g_hCache[style][track], i, nCache[0]);
		
		if (nCache[Ignored])
			continue;
		
		decl String:text[92];
		FormatEx(text, sizeof(text), "%s - %s", nCache[TimeString], nCache[Name]);
		
		if (g_Settings[JumpsEnable])
			Format(text, sizeof(text), "%s (%d %T)", text, nCache[Jumps], "Jumps", client);

		decl String:text2[32];
		FormatEx(text2, sizeof(text2), "%d", nCache[Id]);
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
		FormatEx(query, sizeof(query), "DELETE FROM `round` WHERE id = '%s'", info);

		SQL_TQuery(g_hSQL, DeletePlayersRecordCallback, query, client, DBPrio_Normal);
		
		RefreshCache();
	}
}

public DeletePlayersRecordCallback(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("SQL Error on DeletePlayerRecord: %s", error);
		return;
	}
	
	CreateAdminModeSelection(client);
}


DeleteMapRecords(const String:map[]) 
{
	decl String:query[128];
	FormatEx(query, sizeof(query), "DELETE FROM `round` WHERE map = '%s'", map);	

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
		for (new style = 0; style < MAX_STYLES-1; style++)
		{
			if(!g_Physics[style][StyleEnable])
				continue;
			if(g_Physics[style][StyleCategory] != MCategory_Ranked)
				continue;
			
			g_cacheLoaded[style][0] = false;
			g_cacheLoaded[style][1] = false;
			g_cacheLoaded[style][2] = false;
			
			decl String:query[512];
			FormatEx(query, sizeof(query), "SELECT id, auth, time, jumps, style, name, date, finishcount, stage, rank, jumpacc, finishspeed, maxspeed, avgspeed, strafes, strafeacc, replaypath, custom1, custom2, custom3 FROM round WHERE map = '%s' AND style = %d AND track = %d ORDER BY time ASC;", g_currentMap, style, TRACK_NORMAL);	
			
			SQL_TQuery(g_hSQL, RefreshCacheCallback, query, style, DBPrio_Low);
			
			if(g_Settings[BonusWrEnable])
			{
				FormatEx(query, sizeof(query), "SELECT id, auth, time, jumps, style, name, date, finishcount, stage, rank, jumpacc, finishspeed, maxspeed, avgspeed, strafes, strafeacc, replaypath, custom1, custom2, custom3 FROM round WHERE map = '%s' AND style = %d AND track = %d ORDER BY time ASC;", g_currentMap, style, TRACK_BONUS);	
				
				SQL_TQuery(g_hSQL, RefreshBonusCacheCallback, query, style, DBPrio_Low);
			}
			
			if(g_Settings[ShortWrEnable])
			{
				FormatEx(query, sizeof(query), "SELECT id, auth, time, jumps, style, name, date, finishcount, stage, rank, jumpacc, finishspeed, maxspeed, avgspeed, strafes, strafeacc, replaypath, custom1, custom2, custom3 FROM round WHERE map = '%s' AND style = %d AND track = %d ORDER BY time ASC;", g_currentMap, style, TRACK_SHORT);	
				
				SQL_TQuery(g_hSQL, RefreshShortCacheCallback, query, style, DBPrio_Low);
			}
		}
	}
}

CollectCache(track, style, Handle:hndl)
{
	CacheResetSingle(track, style);
	
	while (SQL_FetchRow(hndl))
	{
		new nNewCache[RecordCache];
		
		nNewCache[Id] = SQL_FetchInt(hndl, 0);
		SQL_FetchString(hndl, 1, nNewCache[Auth], 32);
		nNewCache[Time] = SQL_FetchFloat(hndl, 2);
		Timer_SecondsToTime(SQL_FetchFloat(hndl, 2), nNewCache[TimeString], 16, 2);
		nNewCache[Jumps] = SQL_FetchInt(hndl, 3);
		nNewCache[Style] = SQL_FetchInt(hndl, 4);
		SQL_FetchString(hndl, 5, nNewCache[Name], 32);
		SQL_FetchString(hndl, 6, nNewCache[Date], 32);
		nNewCache[FinishCount] = SQL_FetchInt(hndl, 7);
		nNewCache[Stage] = SQL_FetchInt(hndl, 8);
		nNewCache[CurrentRank] = SQL_FetchInt(hndl, 9);
		nNewCache[JumpAcc] = SQL_FetchFloat(hndl, 10);
		
		nNewCache[FinishSpeed] = SQL_FetchFloat(hndl, 11);
		nNewCache[MaxSpeed] = SQL_FetchFloat(hndl, 12);
		nNewCache[AvgSpeed] = SQL_FetchFloat(hndl, 13);
		nNewCache[Strafes] = SQL_FetchInt(hndl, 14);
		nNewCache[StrafeAcc] = SQL_FetchFloat(hndl, 15);
		SQL_FetchString(hndl, 16, nNewCache[ReplayFile], 32);
		SQL_FetchString(hndl, 17, nNewCache[Custom1], 32);
		SQL_FetchString(hndl, 18, nNewCache[Custom2], 32);
		SQL_FetchString(hndl, 19, nNewCache[Custom3], 32);
		
		nNewCache[Ignored] = false;
		
		PushArrayArray(g_hCache[style][track], nNewCache[0]);
	}
		
	g_cacheLoaded[style][track] = true;
	
	/* Forwards */
	Call_StartForward(g_OnRecordCacheLoaded);
	Call_PushCell(style);
	Call_PushCell(track);
	Call_Finish();

	CollectBestCache(track, style);
}

public RefreshCacheCallback(Handle:owner, Handle:hndl, const String:error[], any:style)
{
	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("SQL Error on RefreshCache: %s", error);
		return;
	}
	
	CollectCache(TRACK_NORMAL, style, hndl);
}

public RefreshBonusCacheCallback(Handle:owner, Handle:hndl, const String:error[], any:style)
{
	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("SQL Error on RefreshBonusCache: %s", error);
		return;
	}
	
	CollectCache(TRACK_BONUS, style, hndl);
}

public RefreshShortCacheCallback(Handle:owner, Handle:hndl, const String:error[], any:style)
{
	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("SQL Error on RefreshShortCache: %s", error);
		return;
	}
	
	CollectCache(TRACK_SHORT, style, hndl);
}

CollectBestCache(track, any:style)
{
	g_cachestats[style][track][RecordStatsCount] = 0;
	g_cachestats[style][track][RecordStatsID] = 0;
	g_cachestats[style][track][RecordStatsBestTime] = 0.0;
	FormatEx(g_cachestats[style][track][RecordStatsName], 32, "");
	FormatEx(g_cachestats[style][track][RecordStatsBestTimeString], 32, "");
	
	for (new i = 0; i < GetArraySize(g_hCache[style][track]); i++)
	{
		new nCache[RecordCache];
		GetArrayArray(g_hCache[style][track], i, nCache[0]);
		
		if(nCache[Time] <= 0.0)
			continue;
		
		g_cachestats[style][track][RecordStatsCount]++;
		
		if(g_cachestats[style][track][RecordStatsBestTime] == 0.0 || g_cachestats[style][track][RecordStatsBestTime] > nCache[Time])
		{
			g_cachestats[style][track][RecordStatsID] = nCache[Id];
			g_cachestats[style][track][RecordStatsBestTime] = nCache[Time];
			FormatEx(g_cachestats[style][track][RecordStatsBestTimeString], 32, "%s", nCache[TimeString]);
			FormatEx(g_cachestats[style][track][RecordStatsName], 32, "%s", nCache[Name]);
		}
	}
}

ConnectSQL(bool:refreshCache)
{
	if (g_hSQL != INVALID_HANDLE)
	{
		CloseHandle(g_hSQL);
	}
	
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
	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("Connection to SQL database has failed, Reason: %s", error);
		
		g_reconnectCounter++;
		if (g_reconnectCounter >= 5)
		{
			Timer_LogError("!! [timer-worldrecord.smx] Failed to connect to the database !!");
			//SetFailState("PLUGIN STOPPED - Reason: reconnect counter reached max - PLUGIN STOPPED");
			//return;
		}
		
		ConnectSQL(data);
		return;
	}

	g_hSQL = CloneHandle(hndl);
	
	decl String:driver[16];
	SQL_GetDriverIdent(owner, driver, sizeof(driver));
	
	if (StrEqual(driver, "mysql", false))
		SQL_SetCharset(g_hSQL, "utf8");

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

		SetMenuTitle(menu, "%t", "World Record Menu Title", client);
		
		SetMenuExitBackButton(menu, true);
		SetMenuExitButton(menu, true);
		
		new count = 0;
		new found = 0;
		
		new maxorder[3] = {0, ...};

		for(new i = 0; i < MAX_STYLES-1; i++) 
		{
			if(!g_Physics[i][StyleEnable])
				continue;
			if(g_Physics[i][StyleCategory] != MCategory_Ranked)
				continue;
			
			if(g_Physics[i][StyleOrder] > maxorder[MCategory_Ranked])
				maxorder[MCategory_Ranked] = g_Physics[i][StyleOrder];
			
			count++;
		}
		
		for(new order = 0; order <= maxorder[MCategory_Ranked]; order++) 
		{
			for(new i = 0; i < MAX_STYLES-1; i++) 
			{
				if(!g_Physics[i][StyleEnable])
					continue;
				if(g_Physics[i][StyleCategory] != MCategory_Ranked)
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

		SetMenuTitle(menu, "%t", "Bonus World Record Menu Title", client);
		
		SetMenuExitBackButton(menu, true);
		SetMenuExitButton(menu, true);
		
		new count = 0;
		new found = 0;
		
		new maxorder[3] = {0, ...};

		for(new i = 0; i < MAX_STYLES-1; i++) 
		{
			if(!g_Physics[i][StyleEnable])
				continue;
			if(g_Physics[i][StyleCategory] != MCategory_Ranked)
				continue;
			
			if(g_Physics[i][StyleOrder] > maxorder[MCategory_Ranked])
				maxorder[MCategory_Ranked] = g_Physics[i][StyleOrder];
			
			count++;
		}
		
		for(new order = 0; order <= maxorder[MCategory_Ranked]; order++) 
		{
			for(new i = 0; i < MAX_STYLES-1; i++) 
			{
				if(!g_Physics[i][StyleEnable])
					continue;
				if(g_Physics[i][StyleCategory] != MCategory_Ranked)
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

		SetMenuTitle(menu, "%t", "Short World Record Menu Title", client);
		
		SetMenuExitBackButton(menu, true);
		SetMenuExitButton(menu, true);
		
		new count = 0;
		new found = 0;
		
		new maxorder[3] = {0, ...};

		for(new i = 0; i < MAX_STYLES-1; i++) 
		{
			if(!g_Physics[i][StyleEnable])
				continue;
			if(g_Physics[i][StyleCategory] != MCategory_Ranked)
				continue;
			
			if(g_Physics[i][StyleOrder] > maxorder[MCategory_Ranked])
				maxorder[MCategory_Ranked] = g_Physics[i][StyleOrder];
			
			count++;
		}
		
		for(new order = 0; order <= maxorder[MCategory_Ranked]; order++) 
		{
			for(new i = 0; i < MAX_STYLES-1; i++) 
			{
				if(!g_Physics[i][StyleEnable])
					continue;
				if(g_Physics[i][StyleCategory] != MCategory_Ranked)
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

CreateWRMenu(client, style, track)
{
	new Handle:menu;

	new total = GetArraySize(g_hCache[style][track]);
	
	if(track == TRACK_NORMAL)
	{
		menu = CreateMenu(MenuHandler_WR);
		SetMenuTitle(menu, "Top players on %s [%d total]", g_currentMap, total);
	}
	else if (track == TRACK_BONUS) 
	{
		menu = CreateMenu(MenuHandler_BonusWR);
		SetMenuTitle(menu, "Bonus-Top players on %s [%d total]", g_currentMap, total);
	}
	else if (track == TRACK_SHORT) 
	{
		menu = CreateMenu(MenuHandler_ShortWR);
		SetMenuTitle(menu, "Short-Top players on %s [%d total]", g_currentMap, total);
	}
	
	if (g_timerPhysics && g_Settings[MultimodeEnable])
		SetMenuExitBackButton(menu, true);
	else
		SetMenuExitButton(menu, true);
		
	new items = 0;
	
	for (new i = 0; i < GetArraySize(g_hCache[style][track]); i++)
	{
		new nCache[RecordCache];
		GetArrayArray(g_hCache[style][track], i, nCache[0]);
		
		decl String:id[64];
		IntToString(nCache[Id], id, sizeof(id));
		
		decl String:text[92];
		FormatEx(text, sizeof(text), "#%d | %s - %s", i+1, nCache[Name], nCache[TimeString]);
		
		if (g_Settings[JumpsEnable])
			Format(text, sizeof(text), "%s (%d jumps)", text, nCache[Jumps]);
		
		AddMenuItem(menu, id, text);
		items++;
	}

	if (items == 0)
	{
		CloseHandle(menu);
		
		if (style == -1)
			CPrintToChat(client, PLUGIN_PREFIX, "No Records");	
		else
		{
			CPrintToChat(client, PLUGIN_PREFIX, "No Difficulty Records");
			
			if(g_Settings[MultimodeEnable])
			{
				if(track == TRACK_BONUS) CreateRankedBWRMenu(client);
				else if(track == TRACK_SHORT) CreateRankedSWRMenu(client);
				else CreateRankedWRMenu(client);
			}
		}
	}
	else
	{
		g_wrStyleMode[client] = style;
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

CreatePlayerInfoMenu(client, id, track)
{
	new Handle:menu;

	if(track == TRACK_NORMAL)
	{
		menu = CreateMenu(MenuHandler_RankedWR);
	}
	else if(track == TRACK_BONUS)
	{
		menu = CreateMenu(MenuHandler_RankedBWR);
	}
	else if(track == TRACK_SHORT)
	{
		menu = CreateMenu(MenuHandler_RankedSWR);
	}
	
	new style = g_wrStyleMode[client];

	SetMenuExitButton(menu, true);

	for (new i = 0; i < GetArraySize(g_hCache[style][track]); i++)
	{
		new nCache[RecordCache];
		GetArrayArray(g_hCache[style][track], i, nCache[0]);
		
		if (nCache[Id] == id)
		{
			decl String:sStyle[5];
			IntToString(style, sStyle, sizeof(sStyle));
			
			decl String:text[92];
			
			SetMenuTitle(menu, "Record Info [ID: %d]\n \n", id);
			
			FormatEx(text, sizeof(text), "Date: %s", nCache[Date]);
			AddMenuItem(menu, sStyle, text);
			
			FormatEx(text, sizeof(text), "Player: %s (%s)", nCache[Name], nCache[Auth]);
			AddMenuItem(menu, sStyle, text);
			
			FormatEx(text, sizeof(text), "Rank: #%d (#%d) [FC: %d]", i+1, nCache[CurrentRank], nCache[FinishCount]);
			AddMenuItem(menu, sStyle, text);
			
			FormatEx(text, sizeof(text), "Time: %s", nCache[TimeString]);
			AddMenuItem(menu, sStyle, text);
			
			FormatEx(text, sizeof(text), "Speed [Avg: %.2f | Max: %.2f | Fin: %.2f]", nCache[AvgSpeed], nCache[MaxSpeed], nCache[FinishSpeed]);
			AddMenuItem(menu, sStyle, text);
			
			if (g_Settings[JumpsEnable])
			{
				FormatEx(text, sizeof(text), "Jumps: %d", nCache[Jumps]);
				Format(text, sizeof(text), "%s [%.2f ⁰⁄₀]", text, nCache[JumpAcc]);
				AddMenuItem(menu, sStyle, text);
			}
			
			if (g_Settings[StrafesEnable])
			{
				FormatEx(text, sizeof(text), "Strafes: %d", nCache[Strafes]);
				Format(text, sizeof(text), "%s [%.2f ⁰⁄₀]", text, nCache[StrafeAcc]);
				AddMenuItem(menu, sStyle, text);
			}
			
			if (g_Settings[MultimodeEnable])
			{
				FormatEx(text, sizeof(text), "%Style: %s", g_Physics[style][StyleName]);
				AddMenuItem(menu, sStyle, text);
			}			
			break;
		}
	}

	DisplayMenu(menu, client, MENU_TIME_FOREVER);	
}

CreateDeleteMenu(client, target, String:targetmap[64], ignored = -1)
{	
	decl String:buffer[128];
	if(ignored != -1) 
		FormatEx(buffer, sizeof(buffer), " AND NOT id = '%d'", ignored);
	
	if (g_hSQL == INVALID_HANDLE)
	{
		ConnectSQL(false);
	}
	else if(StrEqual(targetmap, g_currentMap))
	{
		decl String:auth[32];
		GetClientAuthString(target, auth, sizeof(auth));
			
		decl String:query[512];
		FormatEx(query, sizeof(query), "SELECT id, time, jumps, style, auth FROM `round` WHERE map = '%s' AND auth = '%s'%s ORDER BY style, time, jumps", targetmap, auth, buffer);	
		
		g_deleteMenuSelection[client] = target;
		SQL_TQuery(g_hSQL, CreateDeleteMenuCallback, query, client, DBPrio_Normal);
	}	
	else
	{
		decl String:auth[32];
		GetClientAuthString(target, auth, sizeof(auth));
		
		decl String:query[512];
		FormatEx(query, sizeof(query), "SELECT id, time, jumps, style, auth FROM `round` WHERE map = '%s' AND auth = '%s'%s ORDER BY style, time, jumps", targetmap, auth, buffer);	
		
		g_deleteMenuSelection[client] = target;
		SQL_TQuery(g_hSQL, CreateDeleteMenuCallback, query, client, DBPrio_Normal);
	}
}

public CreateDeleteMenuCallback(Handle:owner, Handle:hndl, const String:error[], any:client)
{	
	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("SQL Error on CreateDeleteMenu: %s", error);
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
		FormatEx(value, sizeof(value), "%s %s", time, g_Physics[SQL_FetchInt(hndl, 3)][StyleName]);
		
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
		FormatEx(query, sizeof(query), "DELETE FROM `round` WHERE id = %s", info);	

		SQL_TQuery(g_hSQL, DeleteRecordCallback, query, client, DBPrio_Normal);
	}
}

public DeleteRecordCallback(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("SQL Error on DeleteRecord: %s", error);
		return;
	}
}

public Native_ForceReloadCache(Handle:plugin, numParams)
{
	RefreshCache();
}

public Native_GetStyleRank(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new track = GetNativeCell(2);
	new style = GetNativeCell(3);
	
	decl String:auth[32];
	GetClientAuthString(client, auth, sizeof(auth));
	
	for (new i = 0; i < GetArraySize(g_hCache[style][track]); i++)
	{
		new nCache[RecordCache];
		GetArrayArray(g_hCache[style][track], i, nCache[0]);
		
		if (StrEqual(nCache[Auth], auth))
			return i+1;
	}
	
	return 0;
}

public Native_GetStyleTotalRank(Handle:plugin, numParams)
{
	return GetArraySize(g_hCache[GetNativeCell(1)][GetNativeCell(2)]);
}

public Native_GetStyleRecordWRStats(Handle:plugin, numParams)
{
	new style = GetNativeCell(1);
	new track = GetNativeCell(2);
	
	SetNativeCellRef(3, g_cachestats[style][track][RecordStatsID]);
	SetNativeCellRef(4, g_cachestats[style][track][RecordStatsBestTime]);
	SetNativeCellRef(5, g_cachestats[style][track][RecordStatsCount]);
	
	return true;
}

public Native_GetBestRound(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new style = GetNativeCell(2);
	new track = GetNativeCell(3);
	
	decl String:auth[32];
	GetClientAuthString(client, auth, sizeof(auth));
	
	if(GetArraySize(g_hCache[style][track]) <= 0)
		return false;
	
	for (new i = 0; i < GetArraySize(g_hCache[style][track]); i++)
	{
		new nCache[RecordCache];
		GetArrayArray(g_hCache[style][track], i, nCache[0]);
		
		if (StrEqual(nCache[Auth], auth))
		{
			SetNativeCellRef(4, nCache[Time]);
			SetNativeCellRef(5, nCache[Jumps]);
			return true;
		}
	}
	
	return false;
}

public Native_GetNewPossibleRank(Handle:plugin, numParams)
{
	new style = GetNativeCell(1);
	new track = GetNativeCell(2);
	new Float:time = GetNativeCell(3);
	
	if(time == 0.0)
		return 0;
	
	if(GetArraySize(g_hCache[style][track]) <= 0)
		return 1;
	
	new i = 0;
	for (i = 0; i < GetArraySize(g_hCache[style][track]); i++)
	{
		new nCache[RecordCache];
		GetArrayArray(g_hCache[style][track], i, nCache[0]);
		
		if (nCache[Time] > time)
			return i+1;
	}
	
	return GetArraySize(g_hCache[style][track])+1;
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
	
	FormatEx(g_currentMap, sizeof(g_currentMap), "%s", buffer);
	
	RefreshCache();
	
	return true;
}

public Native_GetRankID(Handle:plugin, numParams)
{
	new style = GetNativeCell(1);
	new track = GetNativeCell(2);
	new rank = GetNativeCell(3);
	
	if(rank < 1)
		return false;
	
	if(GetArraySize(g_hCache[style][track]) < rank)
		return false;
	
	new nCache[RecordCache];
	GetArrayArray(g_hCache[style][track], rank-1, nCache[0]);
	
	return nCache[Id];
}

public Native_GetRecordHolderName(Handle:plugin, numParams)
{
	new style = GetNativeCell(1);
	new track = GetNativeCell(2);
	new rank = GetNativeCell(3);
	new nlen = GetNativeCell(5);
	
	if (nlen <= 0)
		return false;
	
	if(rank < 1)
		return false;
	
	if(GetArraySize(g_hCache[style][track]) < rank)
		return false;
	
	new nCache[RecordCache];
	GetArrayArray(g_hCache[style][track], rank-1, nCache[0]);
	
	decl String:buffer[nlen];
	FormatEx(buffer, nlen, "%s", nCache[Name]);
	if (SetNativeString(4, buffer, nlen, true) == SP_ERROR_NONE)
		return true;
	
	return false;
}

public Native_GetRecordHolderAuth(Handle:plugin, numParams)
{
	new style = GetNativeCell(1);
	new track = GetNativeCell(2);
	new rank = GetNativeCell(3);
	new nlen = GetNativeCell(5);
	
	if (nlen <= 0)
		return false;
	
	if(rank < 1)
		return false;
	
	if(GetArraySize(g_hCache[style][track]) < rank)
		return false;
	
	new nCache[RecordCache];
	GetArrayArray(g_hCache[style][track], rank-1, nCache[0]);
	
	decl String:buffer[nlen];
	FormatEx(buffer, nlen, "%s", nCache[Auth]);
	if (SetNativeString(4, buffer, nlen, true) == SP_ERROR_NONE)
		return true;
	
	return false;
}

public Native_GetRecordDate(Handle:plugin, numParams)
{
	new style = GetNativeCell(1);
	new track = GetNativeCell(2);
	new rank = GetNativeCell(3);
	new nlen = GetNativeCell(5);
	
	if (nlen <= 0)
		return false;
	
	if(rank < 1)
		return false;
	
	if(GetArraySize(g_hCache[style][track]) < rank)
		return false;
	
	new nCache[RecordCache];
	GetArrayArray(g_hCache[style][track], rank-1, nCache[0]);
	
	decl String:buffer[nlen];
	FormatEx(buffer, nlen, "%s", nCache[Date]);
	if (SetNativeString(4, buffer, nlen, true) == SP_ERROR_NONE)
		return true;
	
	return false;
}

public Native_GetFinishCount(Handle:plugin, numParams)
{
	new style = GetNativeCell(1);
	new track = GetNativeCell(2);
	new rank = GetNativeCell(3);
	
	if(rank < 1)
		return false;
	
	if(GetArraySize(g_hCache[style][track]) < rank)
		return false;
	
	new nCache[RecordCache];
	GetArrayArray(g_hCache[style][track], rank-1, nCache[0]);
	
	return nCache[FinishCount];
}

public Native_GetRecordTimeInfo(Handle:plugin, numParams)
{
	new style = GetNativeCell(1);
	new track = GetNativeCell(2);
	new rank = GetNativeCell(3);
	new nlen = GetNativeCell(6);
	
	if (nlen <= 0)
		return false;
	
	if(rank < 1)
		return false;
	
	if(GetArraySize(g_hCache[style][track]) < rank)
		return false;
	
	new nCache[RecordCache];
	GetArrayArray(g_hCache[style][track], rank-1, nCache[0]);
	
	SetNativeCellRef(4, nCache[Time]);
	
	decl String:buffer[nlen];
	FormatEx(buffer, nlen, "%s", nCache[TimeString]);
	
	if (SetNativeString(5, buffer, nlen, true) == SP_ERROR_NONE)
		return true;
	
	return false;
}

public Native_GetRecordSpeedInfo(Handle:plugin, numParams)
{
	new style = GetNativeCell(1);
	new track = GetNativeCell(2);
	new rank = GetNativeCell(3);
	
	if(rank < 1)
		return false;
	
	if(GetArraySize(g_hCache[style][track]) < rank)
		return false;
	
	new nCache[RecordCache];
	GetArrayArray(g_hCache[style][track], rank-1, nCache[0]);
	
	SetNativeCellRef(4, nCache[AvgSpeed]);
	SetNativeCellRef(5, nCache[MaxSpeed]);
	SetNativeCellRef(6, nCache[FinishSpeed]);

	return true;
}

public Native_GetRecordStrafeJumpInfo(Handle:plugin, numParams)
{
	new style = GetNativeCell(1);
	new track = GetNativeCell(2);
	new rank = GetNativeCell(3);
	
	if(rank < 1)
		return false;
	
	if(GetArraySize(g_hCache[style][track]) < rank)
		return false;
	
	new nCache[RecordCache];
	GetArrayArray(g_hCache[style][track], rank-1, nCache[0]);
	
	SetNativeCellRef(4, nCache[Strafes]);
	SetNativeCellRef(5, nCache[StrafeAcc]);
	SetNativeCellRef(6, nCache[Jumps]);
	SetNativeCellRef(7, nCache[JumpAcc]);

	return true;
}

public Native_GetReplayFileName(Handle:plugin, numParams)
{
	new style = GetNativeCell(1);
	new track = GetNativeCell(2);
	new rank = GetNativeCell(3);
	new nlen = GetNativeCell(5); 
	
	if (nlen <= 0)
		return false;
	
	if(rank < 1)
		return false;
	
	if(GetArraySize(g_hCache[style][track]) < rank)
		return false;
	
	new nCache[RecordCache];
	GetArrayArray(g_hCache[style][track], rank-1, nCache[0]);
	
	decl String:buffer[nlen];
	FormatEx(buffer, nlen, "%s", nCache[ReplayFile]);
	if (SetNativeString(4, buffer, nlen, true) == SP_ERROR_NONE)
		return true;
	
	return false;
}

public Native_GetReplayPath(Handle:plugin, numParams)
{
	new style = GetNativeCell(1);
	new track = GetNativeCell(2);
	new rank = GetNativeCell(3);
	new nlen = GetNativeCell(5); 
	
	if (nlen <= 0)
		return false;
	
	if(rank < 1)
		return false;
	
	if(GetArraySize(g_hCache[style][track]) < rank)
		return false;
	
	new nCache[RecordCache];
	GetArrayArray(g_hCache[style][track], rank-1, nCache[0]);
	
	if(nCache[Time] <= 0.0)
		return false;
	
	decl String:path[256];
	Format(path, sizeof(path), "addons/sourcemod/data/botmimic/%d_%d/%s/%s/%s.rec", style, track, g_currentMap, nCache[Auth], nCache[ReplayFile]);
	ReplaceString(path, sizeof(path), ":", "_", true);
	
	decl String:buffer[nlen];
	FormatEx(buffer, nlen, "%s", path);
	if (SetNativeString(4, buffer, nlen, true) == SP_ERROR_NONE)
		return true;
	
	return false;
}


public Native_GetCustom1(Handle:plugin, numParams)
{
	new style = GetNativeCell(1);
	new track = GetNativeCell(2);
	new rank = GetNativeCell(3);
	new nlen = GetNativeCell(5);
	
	if (nlen <= 0)
		return false;
	
	if(rank < 1)
		return false;
	
	if(GetArraySize(g_hCache[style][track]) < rank)
		return false;
	
	new nCache[RecordCache];
	GetArrayArray(g_hCache[style][track], rank-1, nCache[0]);
	
	decl String:buffer[nlen];
	FormatEx(buffer, nlen, "%s", nCache[Custom1]);
	if (SetNativeString(4, buffer, nlen, true) == SP_ERROR_NONE)
		return true;
	
	return false;
}

public Native_GetCustom2(Handle:plugin, numParams)
{
	new style = GetNativeCell(1);
	new track = GetNativeCell(2);
	new rank = GetNativeCell(3);
	new nlen = GetNativeCell(5);
	
	if (nlen <= 0)
		return false;
	
	if(rank < 1)
		return false;
	
	if(GetArraySize(g_hCache[style][track]) < rank)
		return false;
	
	new nCache[RecordCache];
	GetArrayArray(g_hCache[style][track], rank-1, nCache[0]);
	
	decl String:buffer[nlen];
	FormatEx(buffer, nlen, "%s", nCache[Custom2]);
	if (SetNativeString(4, buffer, nlen, true) == SP_ERROR_NONE)
		return true;
	
	return false;
}


public Native_GetCustom3(Handle:plugin, numParams)
{
	new style = GetNativeCell(1);
	new track = GetNativeCell(2);
	new rank = GetNativeCell(3);
	new nlen = GetNativeCell(5);
	
	if (nlen <= 0)
		return false;
	
	if(rank < 1)
		return false;
	
	if(GetArraySize(g_hCache[style][track]) < rank)
		return false;
	
	new nCache[RecordCache];
	GetArrayArray(g_hCache[style][track], rank-1, nCache[0]);
	
	decl String:buffer[nlen];
	FormatEx(buffer, nlen, "%s", nCache[Custom3]);
	if (SetNativeString(4, buffer, nlen, true) == SP_ERROR_NONE)
		return true;
	
	return false;
}

CacheReset()
{
	nCacheTemplate[Ignored] = false; //Just to get rid of a warning, it's just a template
	
	// Init world record cache
	for (new style = 0; style < MAX_STYLES; style++)
	{
		for (new track = 0; track < MAX_TRACKS; track++)
		{
			if(g_hCache[style][track] != INVALID_HANDLE)
				ClearArray(g_hCache[style][track]);
			else g_hCache[style][track] = CreateArray(sizeof(nCacheTemplate));
			
			g_cacheLoaded[style][track] = false;
		}
	}
}

CacheResetSingle(track, style)
{
	if(g_hCache[style][track] != INVALID_HANDLE)
		ClearArray(g_hCache[style][track]);
	else g_hCache[style][track] = CreateArray(sizeof(nCacheTemplate));
	
	g_cacheLoaded[style][track] = false;
}