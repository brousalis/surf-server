#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <timer>
#include <timer-mysql>
#include <timer-stocks>
#include <timer-config_loader.sp>

#define RECORD_ANY 0
#define RECORD_TOP 1
#define RECORD_WORLD 2

#define LATEST_LIMIT 100

enum Record
{
	String:RecordMap[64],
	RecordTrack,
	RecordStyle,
	String:RecordAuth[32],
	String:RecordName[64],
	Float:RecordTime,
	RecordRank,
	String:RecordDate[32],
}

new Handle:g_hSQL = INVALID_HANDLE;

new g_latestRecords[3][LATEST_LIMIT][Record];
new g_RecordCount[3];

public Plugin:myinfo = 
{
	name = "[Timer] Worldrecord - Latest WRs",
	author = "Zipcore",
	description = "[Timer] Show latest records done.",
	version = "1.0",
	url = "forums.alliedmods.net/showthread.php?p=2074699"
};

public OnPluginStart()
{
	RegConsoleCmd("sm_latest", Cmd_LatestChoose);
	RegConsoleCmd("sm_rr", Cmd_LatestChoose);
	RegConsoleCmd("sm_recent", Cmd_LatestChoose);
	
	if (g_hSQL == INVALID_HANDLE)
	{
		ConnectSQL();
	}
	
	LoadPhysics();
	LoadTimerSettings();
}

public OnMapStart()
{
	if (g_hSQL == INVALID_HANDLE)
	{
		ConnectSQL();
	}
	else LoadLatestRecords();
	
	LoadPhysics();
	LoadTimerSettings();
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
	else LoadLatestRecords();
}

public Action:Timer_SQLReconnect(Handle:timer, any:data)
{
	ConnectSQL();
	return Plugin_Stop;
}

public OnTimerRecord(client, track, mode, Float:time, Float:lasttime, currentrank, newrank)
{
	if(lasttime == 0.0 || time < lasttime) LoadLatestRecords();
}

LoadLatestRecords()
{
	decl String:sQuery[1024];
	
	FormatEx(sQuery, sizeof(sQuery), "SELECT `map`, `track`, `style`, `auth`, `name`, `time`, `rank`, `date` FROM `round` ORDER BY `date` DESC LIMIT %d", LATEST_LIMIT);
	SQL_TQuery(g_hSQL, LoadLatestRecordsCallback, sQuery, RECORD_ANY, DBPrio_Low);
	
	FormatEx(sQuery, sizeof(sQuery), "SELECT `map`, `track`, `style`, `auth`, `name`, `time`, `rank`, `date` FROM `round` WHERE `rank` <= 10 ORDER BY `date` DESC LIMIT %d", LATEST_LIMIT);
	SQL_TQuery(g_hSQL, LoadLatestRecordsCallback, sQuery, RECORD_TOP, DBPrio_Low);
	
	FormatEx(sQuery, sizeof(sQuery), "SELECT `map`, `track`, `style`, `auth`, `name`, `time`, `rank`, `date` FROM `round` WHERE `rank` = 1 ORDER BY `date` DESC LIMIT %d", LATEST_LIMIT);
	SQL_TQuery(g_hSQL, LoadLatestRecordsCallback, sQuery, RECORD_WORLD, DBPrio_Low);
}

public LoadLatestRecordsCallback(Handle:owner, Handle:hndl, const String:error[], any:recordtype)
{
	if (hndl == INVALID_HANDLE)
	{
		PrintToServer("SQL Error on LoadMap: %s", error);
		return;
	}

	new recordCounter = 0;
	while (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, g_latestRecords[recordtype][recordCounter][RecordMap], 64);
		g_latestRecords[recordtype][recordCounter][RecordTrack] = SQL_FetchInt(hndl, 1);
		g_latestRecords[recordtype][recordCounter][RecordStyle] = SQL_FetchInt(hndl, 2);
		SQL_FetchString(hndl, 3, g_latestRecords[recordtype][recordCounter][RecordAuth], 32);
		SQL_FetchString(hndl, 4, g_latestRecords[recordtype][recordCounter][RecordName], 64);
		g_latestRecords[recordtype][recordCounter][RecordTime] = SQL_FetchFloat(hndl, 5);
		g_latestRecords[recordtype][recordCounter][RecordRank] = SQL_FetchInt(hndl, 6);
		SQL_FetchString(hndl, 7, g_latestRecords[recordtype][recordCounter][RecordDate], 32);
		
		recordCounter++;
		if (recordCounter == LATEST_LIMIT)
		{
			break;
		}
	}
	
	g_RecordCount[recordtype] = recordCounter;
}

public Action:Cmd_LatestChoose(client, args)
{
	if (client)
	{
		new Handle:menu = CreateMenu(Handle_LatestChoose);
			
		SetMenuTitle(menu, "Select filter for latest records");
			
		AddMenuItem(menu, "any", "Any");
		AddMenuItem(menu, "top", "Top10");
		AddMenuItem(menu, "world", "World");
			
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}

	return Plugin_Handled;
}

public Handle_LatestChoose(Handle:menu, MenuAction:action, client, itemNum)
{
	if (action == MenuAction_Select)
	{
		decl String:info[100], String:info2[100];
		new bool:found = GetMenuItem(menu, itemNum, info, sizeof(info), _, info2, sizeof(info2));
		if(found)
		{
			if(StrEqual(info, "any"))
			{
				Menu_Latest(client, RECORD_ANY);
			}
			else if(StrEqual(info, "top"))
			{
				Menu_Latest(client, RECORD_TOP);
			}
			else if(StrEqual(info, "world"))
			{
				Menu_Latest(client, RECORD_WORLD);
			}
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

Menu_Latest(client, type)
{
	new Handle:menu = INVALID_HANDLE;
	
	if(type == RECORD_TOP)
	{
		menu = CreateMenu(Handle_LatestTop);
		SetMenuTitle(menu, "Latest Top 10 Records");
	}
	else if(type == RECORD_WORLD)
	{
		menu = CreateMenu(Handle_LatestWorld);
		SetMenuTitle(menu, "Latest World Records");
	}
	else if(type == RECORD_ANY)
	{
		menu = CreateMenu(Handle_Latest);
		SetMenuTitle(menu, "Latest Records");
	}

	if(menu != INVALID_HANDLE)
	{
		for (new i = 0; i < g_RecordCount[type]; i++)
		{
			decl String:sTime[128];
			Timer_SecondsToTime(g_latestRecords[type][i][RecordTime], sTime, sizeof(sTime), 2);

			decl String:buffer[512];
			Format(buffer, sizeof(buffer), "[#%d] %s", i+1, sTime);
			
			if(g_latestRecords[type][i][RecordTrack] == TRACK_BONUS)
				Format(buffer, sizeof(buffer), "%s [B]", buffer);
			else if(g_latestRecords[type][i][RecordTrack] == TRACK_SHORT)
				Format(buffer, sizeof(buffer), "%s [S]", buffer);
			
			Format(buffer, sizeof(buffer), "%s - %s", buffer, g_latestRecords[type][i][RecordName]);
			
			decl String:sInfo[3];
			Format(sInfo, sizeof(sInfo), "%d", i);
			AddMenuItem(menu, sInfo, buffer);
		}
		
		if (g_RecordCount[type] == 0)
		{
			decl String:buffer[512];
			Format(buffer, sizeof(buffer), "No records available!");
			AddMenuItem(menu, "", buffer, ITEMDRAW_DISABLED);
		}
		
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, 20);
	}
}

public Handle_Latest(Handle:menu, MenuAction:action, client, itemNum)
{
	if (action == MenuAction_Select)
	{
		decl String:info[100], String:info2[100];
		new bool:found = GetMenuItem(menu, itemNum, info, sizeof(info), _, info2, sizeof(info2));
		new id = StringToInt(info);
		if(found)
		{
			new Handle:menu2 = CreateMenu(Handle_LatestChoose);
			
			SetMenuTitle(menu2, "Details");
			
			new String:buffer[512];
			
			Format(buffer, sizeof(buffer), "Map: %s", g_latestRecords[RECORD_ANY][id][RecordMap]);
			if(g_latestRecords[RECORD_ANY][id][RecordTrack] == TRACK_BONUS) Format(buffer, sizeof(buffer), "%s [Bonus]", buffer);
			AddMenuItem(menu2, "any", buffer);
			
			if(g_Settings[MultimodeEnable])
			{
				Format(buffer, sizeof(buffer), "Style: %s", g_Physics[g_latestRecords[RECORD_ANY][id][RecordStyle]][StyleName]);
				AddMenuItem(menu2, "any", buffer);
			}
			
			Format(buffer, sizeof(buffer), "Name: %s [%s]", g_latestRecords[RECORD_ANY][id][RecordName], g_latestRecords[RECORD_ANY][id][RecordAuth]);
			AddMenuItem(menu2, "any", buffer);
			
			decl String:sTime[128];
			Timer_SecondsToTime(g_latestRecords[RECORD_ANY][id][RecordTime], sTime, sizeof(sTime), 2);
			Format(buffer, sizeof(buffer), "Time: %s (#%d)", sTime, g_latestRecords[RECORD_ANY][id][RecordRank]);
			AddMenuItem(menu2, "any", buffer);
			
			Format(buffer, sizeof(buffer), "Date: %s", g_latestRecords[RECORD_ANY][id][RecordDate]);
			AddMenuItem(menu2, "any", buffer);
			
			DisplayMenu(menu2, client, MENU_TIME_FOREVER);
		}
	}
}

public Handle_LatestTop(Handle:menu, MenuAction:action, client, itemNum)
{
	if (action == MenuAction_Select)
	{
		decl String:info[100], String:info2[100];
		new bool:found = GetMenuItem(menu, itemNum, info, sizeof(info), _, info2, sizeof(info2));
		new id = StringToInt(info);
		if(found)
		{
			new Handle:menu2 = CreateMenu(Handle_LatestChoose);
			
			SetMenuTitle(menu2, "Details");
			
			new String:buffer[512];
			
			Format(buffer, sizeof(buffer), "Map: %s", g_latestRecords[RECORD_TOP][id][RecordMap]);
			if(g_latestRecords[RECORD_TOP][id][RecordTrack] == TRACK_BONUS) Format(buffer, sizeof(buffer), "%s [Bonus]", buffer);
			AddMenuItem(menu2, "top", buffer);
			
			if(g_Settings[MultimodeEnable])
			{
				Format(buffer, sizeof(buffer), "Style: %s", g_Physics[g_latestRecords[RECORD_TOP][id][RecordStyle]][StyleName]);
				AddMenuItem(menu2, "top", buffer);
			}
			
			Format(buffer, sizeof(buffer), "Name: %s [%s]", g_latestRecords[RECORD_TOP][id][RecordName], g_latestRecords[RECORD_TOP][id][RecordAuth]);
			AddMenuItem(menu2, "top", buffer);
			
			decl String:sTime[128];
			Timer_SecondsToTime(g_latestRecords[RECORD_TOP][id][RecordTime], sTime, sizeof(sTime), 2);
			Format(buffer, sizeof(buffer), "Time: %s (#%d)", sTime, g_latestRecords[RECORD_TOP][id][RecordRank]);
			AddMenuItem(menu2, "top", buffer);
			
			Format(buffer, sizeof(buffer), "Date: %s", g_latestRecords[RECORD_TOP][id][RecordDate]);
			AddMenuItem(menu2, "top", buffer);
			
			DisplayMenu(menu2, client, MENU_TIME_FOREVER);
		}
	}
}

public Handle_LatestWorld(Handle:menu, MenuAction:action, client, itemNum)
{
	if (action == MenuAction_Select)
	{
		decl String:info[100], String:info2[100];
		new bool:found = GetMenuItem(menu, itemNum, info, sizeof(info), _, info2, sizeof(info2));
		new id = StringToInt(info);
		if(found)
		{
			new Handle:menu2 = CreateMenu(Handle_LatestChoose);
			
			SetMenuTitle(menu2, "Details");
			
			new String:buffer[512];
			
			Format(buffer, sizeof(buffer), "Map: %s", g_latestRecords[RECORD_WORLD][id][RecordMap]);
			if(g_latestRecords[RECORD_WORLD][id][RecordTrack] == TRACK_BONUS) Format(buffer, sizeof(buffer), "%s [Bonus]", buffer);
			AddMenuItem(menu2, "world", buffer);
			
			if(g_Settings[MultimodeEnable])
			{
				Format(buffer, sizeof(buffer), "Style: %s", g_Physics[g_latestRecords[RECORD_WORLD][id][RecordStyle]][StyleName]);
				AddMenuItem(menu2, "world", buffer);
			}
			
			Format(buffer, sizeof(buffer), "Name: %s [%s]", g_latestRecords[RECORD_WORLD][id][RecordName], g_latestRecords[RECORD_WORLD][id][RecordAuth]);
			AddMenuItem(menu2, "world", buffer);
			
			decl String:sTime[128];
			Timer_SecondsToTime(g_latestRecords[RECORD_ANY][id][RecordTime], sTime, sizeof(sTime), 2);
			Format(buffer, sizeof(buffer), "Time: %s", sTime, g_latestRecords[RECORD_WORLD][id][RecordRank]);
			AddMenuItem(menu2, "world", buffer);
			
			Format(buffer, sizeof(buffer), "Date: %s", g_latestRecords[RECORD_WORLD][id][RecordDate]);
			AddMenuItem(menu2, "world", buffer);
			
			DisplayMenu(menu2, client, MENU_TIME_FOREVER);
		}
	}
}