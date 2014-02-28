#include <sourcemod>
#include <timer>
#include <timer-stocks>
#include <timer-config_loader.sp>

new Handle:g_hSQL = INVALID_HANDLE;
new g_iSQLReconnectCounter;

enum eMain
{
    Handle:eMain_Pack,
    Handle:eMain_Menu
}

enum eMain2
{
    Handle:eMain2_Pack,
    Handle:eMain2_Menu
}

new String:g_MapName[32];
new g_RowCount[MAXPLAYERS+1];
new g_PointRowCount[MAXPLAYERS+1];
new g_MainMenu[MAXPLAYERS+1][eMain];
new g_MainMapMenu[MAXPLAYERS+1][eMain2];
new String:g_sTargetPlayerName[MAXPLAYERS+1][256];
new g_iTargetStyle[MAXPLAYERS+1];
new Handle:g_hTargetData[MAXPLAYERS+1];

new g_iMapCount[2];
new g_iMapCountComplete[MAXPLAYERS+1];
new Handle:g_hMaps[2] = {INVALID_HANDLE, ...};

new g_MenuPos[MAXPLAYERS+1];

new String:sql_QueryPlayerName[] = "SELECT name, auth FROM round WHERE name LIKE \"%%%s%%\" ORDER BY `round`.`name` ASC, `round`.`auth` ASC;";
new String:sql_selectSingleRecord[] = "SELECT auth, name, jumps, time, date, rank, finishcount, avgspeed, maxspeed, finishspeed FROM round WHERE auth LIKE '%s' AND map = '%s' AND bonus = '0' AND `physicsdifficulty` = '%d';";
new String:sql_selectPlayerRowCount[] = "SELECT name FROM round WHERE time <= (SELECT time FROM round WHERE auth = '%s' AND map = '%s' AND bonus = '%i') AND map = '%s' AND bonus = '%i' ORDER BY time; AND `physicsdifficulty` = '%d'";
new String:sql_selectPlayer_Points[] = "SELECT auth, lastname, points FROM ranks WHERE auth LIKE '%s' AND points NOT LIKE '0';";
new String:sql_selectPlayerPRowCount[] = "SELECT lastname FROM ranks WHERE points >= (SELECT points FROM ranks WHERE auth = '%s' AND points NOT LIKE '0') AND points NOT LIKE '0' ORDER BY points;";

new String:sql_selectPlayerMaps[] = "SELECT time, map, auth FROM round WHERE auth LIKE '%s' AND bonus = '0' AND `physicsdifficulty` = '%d' ORDER BY map ASC;";
new String:sql_selectPlayerMapsBonus[] = "SELECT time, map, auth FROM round WHERE auth LIKE '%s' AND bonus = '1' AND `physicsdifficulty` = '%d' ORDER BY map ASC;";

new String:sql_selectMaps[] = "SELECT map FROM mapzone WHERE type = 0 GROUP BY map ORDER BY map;";
new String:sql_selectMapsBonus[] = "SELECT map FROM mapzone WHERE type = 7 GROUP BY map ORDER BY map;";

new String:sql_selectPlayerWRs[] = "SELECT * FROM (SELECT * FROM (SELECT `time`,`map`,`auth` FROM `round` WHERE `bonus` = '0' AND `physicsdifficulty` = '%d' GROUP BY `round`.`map`, `round`.`time`) AS temp GROUP BY LOWER(`map`)) AS temp2 WHERE `auth` = '%s';";
new String:sql_selectPlayerWRsBonus[] = "SELECT * FROM (SELECT * FROM (SELECT `time`,`map`,`auth` FROM `round` WHERE `bonus` = '1' AND `physicsdifficulty` = '%d' GROUP BY `round`.`map`, `round`.`time`) AS temp GROUP BY LOWER(`map`)) AS temp2 WHERE `auth` = '%s';";
new String:sql_selectPlayerMapRecord[] = "SELECT auth, name, jumps, time, date, rank, finishcount, avgspeed, maxspeed, finishspeed FROM round WHERE auth LIKE '%s' AND map = '%s' AND bonus = '%i' AND `physicsdifficulty` = '%d';";

public Plugin:myinfo = 
{
	name = "[Timer] Worldrecord - PlayerInfo",
	author = "Zipcore, Credits: Das D",
	description = "[Timer] Shows advanced stats for a player.",
	version = "1.0",
	url = "forums.alliedmods.net/showthread.php?p=2074699"
};

public OnPluginStart()
{
	RegConsoleCmd("sm_playerinfo", Client_PlayerInfo, "playerinfo");
	
	LoadPhysics();
	LoadTimerSettings();
	
	if (g_hSQL == INVALID_HANDLE)
	{
		ConnectSQL();
	}
}

public OnMapStart()
{
	LoadPhysics();
	LoadTimerSettings();
	
	GetCurrentMap(g_MapName, 32);
	
	if (g_hSQL == INVALID_HANDLE)
	{
		ConnectSQL();
	}
	else
	{
		countmaps();
		countbonusmaps();
	}
}

ConnectSQL()
{
	if (g_hSQL != INVALID_HANDLE)
	{
		CloseHandle(g_hSQL);
	}

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
	if (g_iSQLReconnectCounter >= 5)
	{
		PrintToServer("PLUGIN STOPPED - Reason: reconnect counter reached max - PLUGIN STOPPED");
		return;
	}
	
	if (hndl == INVALID_HANDLE)
	{
		PrintToServer("Connection to SQL database has failed, Reason: %s", error);
		g_iSQLReconnectCounter++;
		ConnectSQL();
		return;
	}
	g_hSQL = CloneHandle(hndl);
	
	g_iSQLReconnectCounter = 1;
	
	countmaps();
	countbonusmaps();
}

public countmaps()
{
	decl String:Query[255];
	Format(Query, 255, sql_selectMaps);
	SQL_TQuery(g_hSQL, SQL_CountMapCallback, Query, false);
}

public countbonusmaps()
{
	decl String:Query[255];
	Format(Query, 255, sql_selectMapsBonus);
	SQL_TQuery(g_hSQL, SQL_CountMapCallback, Query, true);
}

public SQL_CountMapCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		return;
	}
	
	if(SQL_GetRowCount(hndl))
	{
		new bonus = data;
		g_iMapCount[bonus] = 0;
		
		new String:sMap[128];
		new Handle:Kv = CreateKeyValues("data");
		
		while(SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl, 0, sMap, sizeof(sMap));
			
			KvJumpToKey(Kv, sMap, true);
			KvRewind(Kv);
			
			g_iMapCount[bonus]++;
		}
		
		g_hMaps[bonus] = CloneHandle(Kv);
	}
}

public Action:Client_PlayerInfo(client, args)
{
	if(g_hTargetData[client] != INVALID_HANDLE)
	{
		CloseHandle(g_hTargetData[client]);
		g_hTargetData[client] = INVALID_HANDLE;
	}
	
	if(args < 1)
	{
		decl String:SteamID[32];
		decl String:PlayerName[256];
		
		GetClientAuthString(client, SteamID, 32);
		GetClientName(client, PlayerName, sizeof(PlayerName));
		new Handle:pack = CreateDataPack();
		WritePackCell(pack, client);
		WritePackString(pack, SteamID);
		WritePackString(pack, PlayerName);
		g_hTargetData[client] = pack;
		
		if(g_Settings[MultimodeEnable]) StylePanel(client);
		else Menu_PlayerInfo(client, g_hTargetData[client]);
	}
	else if(args >= 1)
	{
		decl String:NameBuffer[256], String:NameClean[256];
		GetCmdArgString(NameBuffer, sizeof(NameBuffer));
		new startidx = 0;
		new len = strlen(NameBuffer);
		
		if ((NameBuffer[0] == '"') && (NameBuffer[len-1] == '"'))
		{
			startidx = 1;
			NameBuffer[len-1] = '\0';
		}
		
		Format(NameClean, sizeof(NameClean), "%s", NameBuffer[startidx]);
		Format(g_sTargetPlayerName[client], sizeof(g_sTargetPlayerName[]), NameClean);
		
		if(g_Settings[MultimodeEnable])
		{
			StylePanel(client);
		}
		else
		{
			g_iTargetStyle[client] = g_ModeDefault;
			QueryPlayerName(client, NameClean);
		}
	}
	return Plugin_Handled;
}

StylePanel(client)
{
	if(0 < client < MaxClients)
	{
		new Handle:menu = CreateMenu(MenuHandler_StylePanel);

		SetMenuTitle(menu, "Select Style", client);
		
		SetMenuExitButton(menu, true);

		for(new i = 0; i < MAX_MODES-1; i++) 
		{
			if(!g_Physics[i][ModeEnable])
				continue;
			if(g_Physics[i][ModeCategory] != MCategory_Ranked)
				continue;
			
			new String:buffer[8];
			IntToString(i, buffer, sizeof(buffer));
				
			AddMenuItem(menu, buffer, g_Physics[i][ModeName]);
		}
		
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

public MenuHandler_StylePanel(Handle:menu, MenuAction:action, client, itemNum)
{
	if (action == MenuAction_End) 
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select) 
	{
		decl String:info[8];		
		GetMenuItem(menu, itemNum, info, sizeof(info));
		
		g_iTargetStyle[client] = StringToInt(info);
		if(g_hTargetData[client] != INVALID_HANDLE) Menu_PlayerInfo(client, g_hTargetData[client]);
		else QueryPlayerName(client, g_sTargetPlayerName[client]);
	}
}

public QueryPlayerName(client, String:QueryPlayerName[256])
{
	decl String:Query[255];
	decl String:szName[MAX_NAME_LENGTH*2+1];
	SQL_QuoteString(g_hSQL, QueryPlayerName, szName, MAX_NAME_LENGTH*2+1);
	
	Format(Query, 255, sql_QueryPlayerName, szName);
	
	SQL_TQuery(g_hSQL, SQL_QueryPlayerNameCallback, Query, client);
}

public SQL_QueryPlayerNameCallback(Handle:owner, Handle:hndl, const String:error[], any:data){
	if(hndl == INVALID_HANDLE)
		LogError("Error loading playername (%s)", error);
		
	new client = data;
	decl String:PlayerName[256];
	decl String:SteamID[256];
	decl String:PlayerSteam[256];
	decl String:PlayerChkDup[256];
	decl String:buffer[512];
	PlayerChkDup = "zero";
	
	new Handle:menu = CreateMenu(Menu_PlayerSearch);
	SetMenuTitle(menu, "Playersearch\n ");
	
	if(SQL_HasResultSet(hndl))
	{
		new i = 0;
		while (SQL_FetchRow(hndl))
		{
			if (i <= 99)
			{
				SQL_FetchString(hndl, 0, PlayerName, 256);
				SQL_FetchString(hndl, 1, SteamID, 256);
				Format(PlayerSteam, 256, "%s - %s",PlayerName, SteamID);
				if(!StrEqual(PlayerChkDup, SteamID, false))
				{
					new Handle:pack = CreateDataPack();
					WritePackCell(pack, client);
					WritePackString(pack, SteamID);
					WritePackString(pack, PlayerName);
					Format(buffer, sizeof(buffer), "%d", pack);
					AddMenuItem(menu, buffer, PlayerSteam);
					
					Format(PlayerChkDup, 256, "%s",SteamID);
					i++;
				}
				else
				{
					Format(PlayerChkDup, 256, "%s",SteamID);
				}
			}
		}
		if((i == 0))
		{
			AddMenuItem(menu, "nope", "No Player found...", ITEMDRAW_DISABLED);
		}
		if(i > 99)
		{
			AddMenuItem(menu, "many", "More than 100 Players found.", ITEMDRAW_DISABLED);
			AddMenuItem(menu, "speci", "Please be more specific.", ITEMDRAW_DISABLED);
		}
	}
	else{
		AddMenuItem(menu, "nope", "No Player found...", ITEMDRAW_DISABLED);
	}
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public Menu_PlayerInfo(client, Handle:pack)
{
	g_MainMenu[client][eMain_Pack] = pack; 
	ResetPack(g_MainMenu[client][eMain_Pack]);
	ReadPackCell(g_MainMenu[client][eMain_Pack]);
	decl String:SteamID[256];
	ReadPackString(g_MainMenu[client][eMain_Pack], SteamID, 256);
	decl String:PlayerName[256];
	ReadPackString(g_MainMenu[client][eMain_Pack], PlayerName, 256);

	g_MainMenu[client][eMain_Menu] = CreateMenu(Menu_PlayerInfo_Handler);
	SetMenuTitle(g_MainMenu[client][eMain_Menu], "%s's Overview\n(%s)\n ", PlayerName, SteamID);
	
	decl String:data[512];
	Format(data, sizeof(data), "%d", pack);
	
	AddMenuItem(g_MainMenu[client][eMain_Menu], data, "View Record/Rank (current Map)");
	AddMenuItem(g_MainMenu[client][eMain_Menu], data, "View Points/Rank");
	AddMenuItem(g_MainMenu[client][eMain_Menu], data, "View all Records");
	AddMenuItem(g_MainMenu[client][eMain_Menu], data, "View all Records (Bonus)");
	AddMenuItem(g_MainMenu[client][eMain_Menu], data, "View all WRs");
	AddMenuItem(g_MainMenu[client][eMain_Menu], data, "View all WRs (Bonus)");
	AddMenuItem(g_MainMenu[client][eMain_Menu], data, "View Incomplete Maps");
	AddMenuItem(g_MainMenu[client][eMain_Menu], data, "View Incomplete Maps (Bonus)");
	
	decl String:buffer[512];
	Format(buffer, sizeof(buffer), "Change style [current: %s]", g_Physics[g_iTargetStyle[client]][ModeName]);
	if(g_Settings[MultimodeEnable]) AddMenuItem(g_MainMenu[client][eMain_Menu], data, buffer);
	SetMenuExitButton(g_MainMenu[client][eMain_Menu], true);
	DisplayMenu(g_MainMenu[client][eMain_Menu], client, MENU_TIME_FOREVER);
}

public SQL_ViewSingleRecordCallback(Handle:owner, Handle:hndl, const String:error[], any:data){
	if(hndl == INVALID_HANDLE)
		LogError("Error loading single record (%s)", error);
	
	new Handle:pack = data;
	ResetPack(pack);
	
	new client = ReadPackCell(pack);
	decl String:MapName[32];
	ReadPackString(pack, MapName, 32);
	
	CloseHandle(pack);
	
	new Handle:menu = CreateMenu(Menu_Stock_Handler);
	SetMenuTitle(menu, "Record Info\n ");
	
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl)){
	
		decl String:SteamId[32];
		decl String:PlayerName[MAX_NAME_LENGTH];
		decl String:Date[20];
		new rank;
		new finishcount;
		
		SQL_FetchString(hndl, 0, SteamId, 32);
		SQL_FetchString(hndl, 1, PlayerName, MAX_NAME_LENGTH);
		SQL_FetchString(hndl, 4, Date, 20);
		rank = SQL_FetchInt(hndl, 5);
		finishcount = SQL_FetchInt(hndl, 6);
		new Float:avgspeed = SQL_FetchFloat(hndl, 7);
		new Float:maxspeed = SQL_FetchFloat(hndl, 8);
		new Float:finishspeed = SQL_FetchFloat(hndl, 9);
		
		decl String:LineDate[32];
		Format(LineDate, 32, "Date: %s", Date);
		decl String:LinePLSteam[128];
		Format(LinePLSteam, 128, "Player: %s (%s)", PlayerName, SteamId);
		decl String:LineRank[128];
		Format(LineRank, 128, "Rank: #%i on %s [FR: #%i | FC: %i]", g_RowCount[client], MapName, rank, finishcount);
		decl String:LineTime[128];
		decl String:Time[32];		
		Timer_SecondsToTime(SQL_FetchFloat(hndl, 3), Time, 16, 2);
		Format(LineTime, 128, "Time: %s", Time);
		decl String:LineSpeed[128];
		Format(LineSpeed, 128, "Speed [Avg: %.2f | Max: %.2f | Fin: %.2f]", avgspeed, maxspeed, finishspeed);
		
		AddMenuItem(menu, "1", LineDate);
		AddMenuItem(menu, "2", LinePLSteam);
		AddMenuItem(menu, "3", LineRank);
		AddMenuItem(menu, "4", LineTime);
		AddMenuItem(menu, "5", LineSpeed);
		
		SetMenuExitButton(menu, true);
		SetMenuExitBackButton(menu, true);
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
	else{
		AddMenuItem(menu, "nope", "No record found...");
		SetMenuExitButton(menu, true);
		SetMenuExitBackButton(menu, true);
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

public SQL_ViewPlayerMapRecordCallback(Handle:owner, Handle:hndl, const String:error[], any:data){
	if(hndl == INVALID_HANDLE)
		LogError("Error loading single record (%s)", error);
	
	new Handle:pack = data;
	ResetPack(pack);
	
	new client = ReadPackCell(pack);
	decl String:MapName[32];
	ReadPackString(pack, MapName, 32);
	decl String:SteamID[256];
	ReadPackString(pack, SteamID, 256);
	new Bonus = ReadPackCell(pack);
	
	new Handle:menu = CreateMenu(Menu_Stock_Handler2);
	if(!Bonus)
	{
		SetMenuTitle(menu, "Record Info\n ");
	}
	else
	{
		SetMenuTitle(menu, "Bonus Record Info\n ");
	}
	
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl)){
	
		decl String:SteamId[32];
		decl String:PlayerName[MAX_NAME_LENGTH];
		decl String:Date[20];
		new rank;
		new finishcount;
		
		SQL_FetchString(hndl, 0, SteamId, 32);
		SQL_FetchString(hndl, 1, PlayerName, MAX_NAME_LENGTH);
		SQL_FetchString(hndl, 4, Date, 20);
		rank = SQL_FetchInt(hndl, 5);
		finishcount = SQL_FetchInt(hndl, 6);
		new Float:avgspeed = SQL_FetchFloat(hndl, 7);
		new Float:maxspeed = SQL_FetchFloat(hndl, 8);
		new Float:finishspeed = SQL_FetchFloat(hndl, 9);
		
		decl String:LineDate[32];
		Format(LineDate, 32, "Date: %s", Date);
		decl String:LinePLSteam[128];
		Format(LinePLSteam, 128, "Player: %s (%s)", PlayerName, SteamId);
		decl String:LineRank[128];
		Format(LineRank, 128, "Rank: #%i on %s [FR: #%i | FC: %i]", g_RowCount[client], MapName, rank, finishcount);
		decl String:LineTime[128];
		decl String:Time[32];		
		Timer_SecondsToTime(SQL_FetchFloat(hndl, 3), Time, 16, 2);
		Format(LineTime, 128, "Time: %s", Time);
		decl String:LineSpeed[128];
		Format(LineSpeed, 128, "Speed [Avg: %.2f | Max: %.2f | Fin: %.2f]", avgspeed, maxspeed, finishspeed);
		
		AddMenuItem(menu, "1", LineDate);
		AddMenuItem(menu, "2", LinePLSteam);
		AddMenuItem(menu, "3", LineRank);
		AddMenuItem(menu, "4", LineTime);
		AddMenuItem(menu, "5", LineSpeed);
		
		SetMenuExitButton(menu, true);
		SetMenuExitBackButton(menu, true);
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
	else{
		AddMenuItem(menu, "nope", "No record found...");
		SetMenuExitButton(menu, true);
		SetMenuExitBackButton(menu, true);
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

public SQL_PRowCountCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl == INVALID_HANDLE)
		LogError("Error viewing player point rowcount (%s)", error);
	
	new Handle:pack = data;
	ResetPack(pack);
	
	new client = ReadPackCell(pack);
	
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		g_PointRowCount[client] = SQL_GetRowCount(hndl);
	}
}

public SQL_GetRowCountCallback(Handle:owner, Handle:hndl, const String:error[], any:data){
	if(hndl == INVALID_HANDLE)
		LogError("Error getting rowcount (%s)", error);
		
	new Handle:pack = data;
	ResetPack(pack);
	
	new client = ReadPackCell(pack);
	
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		g_RowCount[client] = SQL_GetRowCount(hndl);
	}
}

public SQL_PlayerPointsCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl == INVALID_HANDLE)
		LogError("Error loading player points (%s)", error);
	
	new Handle:pack = data;
	ResetPack(pack);
	
	new client = ReadPackCell(pack);
	
	CloseHandle(pack);
	
	new Handle:menu = CreateMenu(Menu_Stock_Handler);
	SetMenuTitle(menu, "Points Info\n ");
	
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		decl String:SteamId[32];
		decl String:Name[128];
		decl String:Points[64];
		new points;
		
		SQL_FetchString(hndl, 0, SteamId, 32);
		SQL_FetchString(hndl, 1, Name, 128);
		SQL_FetchString(hndl, 2, Points, 64);
		points = SQL_FetchInt(hndl, 2);
		
		decl String:LineName[128];
		decl String:LinePoints[64];
		decl String:LinePointRank[64];
		Format(LineName, 128, "Player: %s (%s)", Name, SteamId);
		Format(LinePoints, 64, "Points: %i", points);
		Format(LinePointRank, 64, "Rank: #%i", g_PointRowCount[client]);
		
		AddMenuItem(menu, "1", LineName);
		AddMenuItem(menu, "2", LinePoints);
		AddMenuItem(menu, "3", LinePointRank);
		SetMenuExitButton(menu, true);
		SetMenuExitBackButton(menu, true);
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}


public SQL_ViewPlayerMapsCallback(Handle:owner, Handle:hndl, const String:error[], any:data){
	if(hndl == INVALID_HANDLE)
		LogError("[Timer] Error loading playerinfo (%s)", error);
	
	new Handle:pack = data;
	ResetPack(pack);
	
	new client = ReadPackCell(pack);
	new bonus = ReadPackCell(pack);
	
	CloseHandle(pack);

	decl String:szValue[64];
	decl String:szMapName[32];
	decl String:szVrTime[16];
	decl String:SteamID[256];
	decl String:buffer[512];
	
	// Begin Menu
	g_MainMapMenu[client][eMain2_Menu] = CreateMenu(MapMenu_Stock_Handler);
	
	new mapscomplete = 0;
	if(SQL_HasResultSet(hndl))
	{
		mapscomplete = SQL_GetRowCount(hndl);
	}
	/// Calc Percent
	new Float: mapcom_fl = float(mapscomplete);
	new Float: mapcou_fl;
	if(!bonus)
	{
		mapcou_fl = float(g_iMapCount[0]);
	}
	else
	{
		mapcou_fl = float(g_iMapCount[1]);
	}
	new Float: Com_Per_fl = (mapcom_fl/mapcou_fl)*100;
	
	if(!bonus)
	{
		SetMenuTitle(g_MainMapMenu[client][eMain2_Menu], "%i of %i (%.2f%%) Maps completed\nRecords:\n ", mapscomplete, g_iMapCount[0], Com_Per_fl);
	}
	else
	{
		SetMenuTitle(g_MainMapMenu[client][eMain2_Menu], "%i of %i (%.2f%%) Bonuses completed\nRecords:\n ", mapscomplete, g_iMapCount[1], Com_Per_fl);
	}
	
	if(SQL_HasResultSet(hndl))
	{
		new i = 1;
		// Loop over
		while (SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl, 1, szMapName, 32);
			SQL_FetchString(hndl, 2, SteamID, 256);
			Timer_SecondsToTime(SQL_FetchFloat(hndl, 0), szVrTime, 16, 2);
			Format(szValue, 64, "%s - %s",szMapName, szVrTime);
			
			new Handle:pack2 = CreateDataPack();
			WritePackCell(pack2, client);
			WritePackString(pack2, szMapName);
			WritePackString(pack2, SteamID);
			WritePackCell(pack2, bonus);
			Format(buffer, sizeof(buffer), "%d", pack2);
			
			AddMenuItem(g_MainMapMenu[client][eMain2_Menu], buffer, szValue);
			i++;
		}
		if(i == 1)
		{
			AddMenuItem(g_MainMapMenu[client][eMain2_Menu], "nope", "No Record found...");
		}
	}
	
	SetMenuExitBackButton(g_MainMapMenu[client][eMain2_Menu], true);
	DisplayMenu(g_MainMapMenu[client][eMain2_Menu], client, MENU_TIME_FOREVER);
}

public Menu_PlayerSearch(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new first_item = GetMenuSelectionPosition();
		DisplayMenuAtItem(menu, param1, first_item, MENU_TIME_FOREVER); 

		decl String:data[512];
		GetMenuItem(menu, param2, data, sizeof(data));

		Menu_PlayerInfo(param1, Handle:StringToInt(data));
	}
}

public Menu_PlayerInfo_Handler(Handle:menu, MenuAction:action, client, param2)
{
	if ( action == MenuAction_Select )
	{
		new first_item = GetMenuSelectionPosition();
		DisplayMenuAtItem(menu, client, first_item, MENU_TIME_FOREVER); 
		
		decl String:data[512];
		GetMenuItem(menu, param2, data, sizeof(data));
		g_MainMenu[client][eMain_Pack] = Handle:StringToInt(data); 
		ResetPack(g_MainMenu[client][eMain_Pack]);
		ReadPackCell(g_MainMenu[client][eMain_Pack]);
		decl String:SteamID[64];
		ReadPackString(g_MainMenu[client][eMain_Pack], SteamID, sizeof(SteamID));
		decl String:PlayerName[256];
		ReadPackString(g_MainMenu[client][eMain_Pack], PlayerName, 256);

		switch (param2)
		{
			case 0:
			{
				decl String:Query[255];
				Format(Query, 255, sql_selectSingleRecord, SteamID, g_MapName, g_iTargetStyle[client]);
				decl String:Query2[255];
				Format(Query2, 255, sql_selectPlayerRowCount, SteamID, g_MapName, 0, g_MapName, 0, g_iTargetStyle[client]);
				
				new Handle:pack2 = CreateDataPack();
				WritePackCell(pack2, client);
				WritePackString(pack2, g_MapName);
				
				SQL_TQuery(g_hSQL, SQL_GetRowCountCallback, Query2, pack2);
				SQL_TQuery(g_hSQL, SQL_ViewSingleRecordCallback, Query, pack2);
			}
			case 1:
			{
				decl String:szQuery[255];
				Format(szQuery, 255, sql_selectPlayer_Points, SteamID);
				decl String:Query2[255];
				Format(Query2, 255, sql_selectPlayerPRowCount, SteamID);

				new Handle:pack3 = CreateDataPack();
				WritePackCell(pack3, client);

				SQL_TQuery(g_hSQL, SQL_PRowCountCallback, Query2, pack3);
				SQL_TQuery(g_hSQL, SQL_PlayerPointsCallback, szQuery, pack3);
			}
			case 2:
			{
				new bool: bonus = false;
				new Handle:pack4 = CreateDataPack();
				WritePackCell(pack4, client);
				WritePackCell(pack4, bonus);
				
				
				decl String:szQuery[255];
				Format(szQuery, 255, sql_selectPlayerMaps, SteamID, g_iTargetStyle[client]);
				SQL_TQuery(g_hSQL, SQL_ViewPlayerMapsCallback, szQuery, pack4);
			}
			case 3:
			{
				new bool: bonus = true;
				new Handle:pack5 = CreateDataPack();
				WritePackCell(pack5, client);
				WritePackCell(pack5, bonus);
				
				decl String:szQuery[255];
				Format(szQuery, 255, sql_selectPlayerMapsBonus, SteamID, g_iTargetStyle[client]);
				SQL_TQuery(g_hSQL, SQL_ViewPlayerMapsCallback, szQuery, pack5);
			}
			case 4:
			{
				new bool: bonus = false;
				new Handle:pack5 = CreateDataPack();
				WritePackCell(pack5, client);
				WritePackCell(pack5, bonus);
				
				decl String:szQuery[255];
				Format(szQuery, 255, sql_selectPlayerWRs, g_iTargetStyle[client], SteamID);
				SQL_TQuery(g_hSQL, SQL_ViewPlayerMapsCallback, szQuery, pack5);
			}
			case 5:
			{
				new bool: bonus = true;
				new Handle:pack5 = CreateDataPack();
				WritePackCell(pack5, client);
				WritePackCell(pack5, bonus);
				
				decl String:szQuery[255];
				Format(szQuery, 255, sql_selectPlayerWRsBonus, g_iTargetStyle[client], SteamID);
				SQL_TQuery(g_hSQL, SQL_ViewPlayerMapsCallback, szQuery, pack5);
			}
			case 6:
			{
				GetIncompleteMaps(client, SteamID, 0, g_iTargetStyle[client]);
			}
			case 7:
			{
				GetIncompleteMaps(client, SteamID, 1, g_iTargetStyle[client]);
			}
			case 8:
			{
				StylePanel(client);
			}
		}
	}
}

public Menu_Stock_Handler(Handle:menu, MenuAction:action, param1, param2)
{
	if ( action == MenuAction_Select )
	{
		new first_item = GetMenuSelectionPosition();
		DisplayMenuAtItem(menu, param1, first_item, MENU_TIME_FOREVER); 
	}
	else if(action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
	{
		DisplayMenu(g_MainMenu[param1][eMain_Menu], param1, MENU_TIME_FOREVER);
	}
}

public Menu_Stock_Handler2(Handle:menu, MenuAction:action, param1, param2)
{
	if ( action == MenuAction_Select )
	{
		new first_item = GetMenuSelectionPosition();
		DisplayMenuAtItem(menu, param1, first_item, MENU_TIME_FOREVER); 
	}
	else if(action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
	{
		DisplayMenuAtItem(g_MainMapMenu[param1][eMain2_Menu], param1, g_MenuPos[param1], MENU_TIME_FOREVER);
	}
}

public MapMenu_Stock_Handler(Handle:menu, MenuAction:action, client, param2)
{
	if ( action == MenuAction_Select )
	{
		g_MenuPos[client] = GetMenuSelectionPosition();
		DisplayMenuAtItem(menu, client, g_MenuPos[client], MENU_TIME_FOREVER); 
		
		decl String:data[512];
		GetMenuItem(menu, param2, data, sizeof(data));
		new Handle:pack = Handle:StringToInt(data); 
		ResetPack(pack);
		ReadPackCell(pack);
		decl String:MapName[256];
		ReadPackString(pack, MapName, 256);
		decl String:SteamID[256];
		ReadPackString(pack, SteamID, 256);
		new Bonus = ReadPackCell(pack);
		
		decl String:szQuery[255];
		Format(szQuery, 255, sql_selectPlayerMapRecord, SteamID, MapName, Bonus, g_iTargetStyle[client]);
		decl String:Query2[255];
		Format(Query2, 255, sql_selectPlayerRowCount, SteamID, MapName, Bonus, MapName, Bonus, g_iTargetStyle[client]);

		SQL_TQuery(g_hSQL, SQL_GetRowCountCallback, Query2, pack);
		SQL_TQuery(g_hSQL, SQL_ViewPlayerMapRecordCallback, szQuery, pack);
	}
	else if(action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
	{
		DisplayMenu(g_MainMenu[client][eMain_Menu], client, MENU_TIME_FOREVER);
	}
}

GetIncompleteMaps(client, String:auth[64], bonus, style)
{
	new Handle:pack = CreateDataPack();
	WritePackCell(pack, client);
	WritePackString(pack, auth);
	WritePackCell(pack, bonus);
	WritePackCell(pack, style);
	
	decl String:sQuery[255];
	if(style > -1)
		Format(sQuery, sizeof(sQuery), "SELECT DISTINCT map FROM round WHERE bonus = %d AND auth = '%s' AND physicsdifficulty = %d ORDER BY map", bonus, auth, style);
	else
		Format(sQuery, sizeof(sQuery), "SELECT DISTINCT map FROM round WHERE bonus = %d AND auth = '%s' ORDER BY map", bonus, auth);
	SQL_TQuery(g_hSQL, CallBack_IncompleteMaps, sQuery, pack, DBPrio_Low);
}

public CallBack_IncompleteMaps(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		return;
	}
	
	if(!SQL_GetRowCount(hndl))
	{
		LogError("No startzone found.");
	}
	else
	{
		new Handle:pack = data;
		
		ResetPack(pack);
		new client = ReadPackCell(pack);
		decl String:sAuth[64];
		ReadPackString(pack, sAuth, sizeof(sAuth));
		new bonus = ReadPackCell(pack);
		new style = ReadPackCell(pack);
		CloseHandle(pack);
		
		new String:sMap[128];
		new Handle:Kv = CreateKeyValues("data");
		
		while(SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl, 0, sMap, sizeof(sMap));
			
			KvJumpToKey(Kv, sMap, true);
			KvRewind(Kv);
			
			g_iMapCountComplete[client]++;
		}
		
		new iCountIncomplete;
		
		new Handle:menu = CreateMenu(MenuHandler_Empty);
		
		KvRewind(g_hMaps[bonus]);
		KvGotoFirstSubKey(g_hMaps[bonus], true);
		do
		{
			KvGetSectionName(g_hMaps[bonus], sMap, sizeof(sMap));
			if(!KvJumpToKey(Kv, sMap, false))
			{
				iCountIncomplete++;
				AddMenuItem(menu, "", sMap);
			}
			KvRewind(Kv);
        } while (KvGotoNextKey(g_hMaps[bonus], false));
		
		new String:buffer[128];
		if(bonus == TRACK_BONUS)
			Format(buffer, sizeof(buffer), "Bonus Maps Left %d/%d", iCountIncomplete, g_iMapCount[bonus]);
		else if(bonus == TRACK_NORMAL)
			Format(buffer, sizeof(buffer), "Maps Left %d/%d", iCountIncomplete, g_iMapCount[bonus]);
		
		if(style > -1)
			Format(buffer, sizeof(buffer), "%s\nStyle: %s", buffer, g_Physics[style][ModeName]);
			
		SetMenuTitle(menu, buffer);
		
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

public MenuHandler_Empty(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		if(g_hTargetData[client] != INVALID_HANDLE) Menu_PlayerInfo(client, g_hTargetData[client]);
	}
	else if (action == MenuAction_Cancel)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public OnClientDisconnect(client)
{
	if(g_MainMenu[client][eMain_Pack] != INVALID_HANDLE)
	{
		CloseHandle(g_MainMenu[client][eMain_Pack]);
		g_MainMenu[client][eMain_Pack] = INVALID_HANDLE;
	}
	
	if(g_MainMenu[client][eMain_Menu] != INVALID_HANDLE)
	{
		CloseHandle(g_MainMenu[client][eMain_Menu]);
		g_MainMenu[client][eMain_Menu] = INVALID_HANDLE;
	}
	
	if(g_MainMapMenu[client][eMain2_Pack] != INVALID_HANDLE)
	{
		CloseHandle(g_MainMapMenu[client][eMain2_Pack]);
		g_MainMapMenu[client][eMain2_Pack] = INVALID_HANDLE;
	}
	
	if(g_MainMapMenu[client][eMain2_Menu] != INVALID_HANDLE)
	{
		CloseHandle(g_MainMapMenu[client][eMain2_Menu]);
		g_MainMapMenu[client][eMain2_Menu] = INVALID_HANDLE;
	}
}