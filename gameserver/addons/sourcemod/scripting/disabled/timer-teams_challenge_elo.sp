#include <sourcemod>
#include <timer>
#include <timer-logging>
#include <timer-physics>
#include <timer-teams>
#include <timer-rankings>
#include <timer-config_loader.sp>

new Handle:g_hSQL = INVALID_HANDLE;
new g_iSQLReconnectCounter;

new g_iBet[MAXPLAYERS+1];
new g_iRankTotal;
new g_iELO[MAXPLAYERS+1];
new g_iELOmax[MAXPLAYERS+1];
new g_iELOmin[MAXPLAYERS+1];
new g_iRank[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "[Timer] Challenge ELO",
	author = "Zipcore",
	description = "[Timer] ELO ranking for challenge [PvP Stats]",
    version     = PL_VERSION,
    url         = "zipcore#googlemail.com"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_pvp", Cmd_PvPStats);
	
	ConnectSQL();
	
	LoadPhysics();
	LoadTimerSettings();
}

public OnMapStart()
{
	if (g_hSQL == INVALID_HANDLE)
	{
		ConnectSQL();
	}
	
	LoadPhysics();
	LoadTimerSettings();
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

	decl String:driver[16];
	SQL_GetDriverIdent(owner, driver, sizeof(driver));

	g_hSQL = CloneHandle(hndl);
	
	if (StrEqual(driver, "mysql", false))
	{
		SQL_SetCharset(g_hSQL, "utf8");
		SQL_TQuery(g_hSQL, CreateSQLTableCallback, "CREATE TABLE IF NOT EXISTS `pvp_challenge` (`id` int(11) NOT NULL AUTO_INCREMENT PRIMARY KEY, `map` varchar(32) NOT NULL, `style` int(8) NOT NULL, `bonus` int(8) NOT NULL, `auth_winner` varchar(32) NOT NULL,`name_winner` varchar(64) NOT NULL,`auth_loser` varchar(32) NOT NULL,`name_loser` varchar(64) NOT NULL,`diff` int(8) NOT NULL,`count` int(8) NOT NULL, date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, UNIQUE KEY `single_auth` (`map`,`style`,`bonus`,`auth_winner`,`auth_loser`));");
		SQL_TQuery(g_hSQL, CreateSQLTableCallback, "CREATE TABLE IF NOT EXISTS `pvp_elo` (auth varchar(32) NOT NULL, name varchar(64) NOT NULL, rating int(8) NOT NULL, rating_max int(8) NOT NULL, rating_min int(8) NOT NULL,win int(8) NOT NULL, loose int(8) NOT NULL,UNIQUE KEY `single_auth` (`auth`));");
	}
	
	g_iSQLReconnectCounter = 1;
	
	decl String:sQuery[192];
	FormatEx(sQuery, sizeof(sQuery), "SELECT COUNT(*) FROM `pvp_elo`");
	SQL_TQuery(g_hSQL, CallBack_TotalRank, sQuery, _);
}

public CallBack_TotalRank(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	g_iRankTotal = 0;
	
	if(SQL_FetchRow(hndl))
	{
		g_iRankTotal = SQL_FetchInt(hndl, 0);
	}
}

public CreateSQLTableCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (owner == INVALID_HANDLE)
	{
		Timer_LogError(error);
		
		g_iSQLReconnectCounter++;
		ConnectSQL();

		return;
	}
	
	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("SQL Error on CreateSQLTable: %s", error);
		return;
	}
}

public OnClientPostAdminCheck(client)
{
	if(IsFakeClient(client))
		return;
	
	new String:auth[128];
	GetClientAuthString(client, auth, sizeof(auth));
	
	decl String:sQuery[192];
	FormatEx(sQuery, sizeof(sQuery), "SELECT `rating`, `rating_max`, `rating_min` FROM `pvp_elo` WHERE `auth` = '%s'", auth);
	SQL_TQuery(g_hSQL, CallBack_ClientConnect, sQuery, client, DBPrio_Low);
}

public CallBack_ClientConnect(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if(!client || !IsClientInGame(client))
		return;

	decl String:sName[MAX_NAME_LENGTH];
	
	decl String:sSafeName[((MAX_NAME_LENGTH * 2) + 1)];
	GetClientName(client, sName, sizeof(sName));
	SQL_EscapeString(g_hSQL, sName, sSafeName, sizeof(sSafeName));
	
	g_iELO[client] = 1000;
	
	decl String:sQuery[256];
	if(SQL_FetchRow(hndl))
	{
		g_iELO[client] = SQL_FetchInt(hndl, 0);
		g_iELOmax[client] = SQL_FetchInt(hndl, 1);
		g_iELOmin[client] = SQL_FetchInt(hndl, 2);
		
		FormatEx(sQuery, sizeof(sQuery), "SELECT COUNT(*) FROM `pvp_elo` WHERE `rating` >= %d ORDER BY `rating` DESC", g_iELO[client]);
		SQL_TQuery(g_hSQL, CallBack_LoadRank, sQuery, client);
	}
}

public CallBack_LoadRank(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if(!client || !IsClientInGame(client))
		return;
	
	g_iRank[client] = -1;
	
	if(SQL_FetchRow(hndl))
	{
		g_iRank[client] = SQL_FetchInt(hndl, 0);
	}
}

public Action:Cmd_PvPStats(client, args)
{
	if (client)
	{
		if(g_iRank[client] != -1)
		{
			CPrintToChatAll("%s %N Rating:%d Rank:%d/%d", PLUGIN_PREFIX2, client, g_iELO[client], g_iRank[client], g_iRankTotal);
		}
		else CPrintToChat(client, "%s You never played a match. Type !challenge to make match.", PLUGIN_PREFIX2);
	}

	return Plugin_Handled;
}

public OnChallengeConfirm(client, mate, bet)
{
	g_iBet[client] = bet;
	g_iBet[mate] = bet;
}

public OnChallengeWin(winner, loser)
{
	decl String:query[2048];
	decl String:map[128];
	decl String:auth_winner[128], String:auth_loser[128], String:name_winner[128], String:name_loser[128];
	new style, bonus;
	
	style = Timer_GetStyle(winner);
	bonus = Timer_GetTrack(winner);
	
	if(IsFakeClient(loser))
		g_iELO[loser] = 1000;
	
	new Float:prob = 1/(Pow(10.0, float((g_iELO[loser]-g_iELO[winner]))/400)+1);
	new diff = RoundToFloor(25.0*(1-prob));
	
	g_iELO[loser] -= diff;
	g_iELO[winner] += diff;
	
	if(g_iELOmax[winner] < g_iELO[winner])
		g_iELOmax[winner] = g_iELO[winner];
	
	if(g_iELOmin[loser] > g_iELO[loser])
		g_iELOmin[loser] = g_iELO[loser];

	#if defined LEGACY_COLORS
	CPrintToChatAll("%s {olive}%N {lightred}%d [+%d] {olive}has beaten %N {lightred}%d [-%d] {olive}at a challenge", PLUGIN_PREFIX2, winner, g_iELO[winner], g_iELO[winner], loser, g_iELO[loser], g_iELO[winner]);
	#else
	CPrintToChatAll("%s {lightblue}%N {yellow}%d [+%d] {lightblue}has beaten %N {yellow}%d [-%d] {lightblue}at a challenge", PLUGIN_PREFIX2, winner, g_iELO[winner], g_iELO[winner], loser, g_iELO[loser], g_iELO[winner]);
	#endif
		
	GetCurrentMap(map, sizeof(map));
	
	GetClientAuthString(winner, auth_winner, sizeof(auth_winner));
	GetClientAuthString(loser, auth_loser, sizeof(auth_loser));
	
	GetClientName(winner, name_winner, sizeof(name_winner));
	GetClientName(loser, name_loser, sizeof(name_loser));
	
	SQL_EscapeString(g_hSQL, name_winner, name_winner, sizeof(name_winner));
	SQL_EscapeString(g_hSQL, name_loser, name_loser, sizeof(name_loser));
	
	//Winner
	FormatEx(query, sizeof(query), "INSERT INTO pvp_elo (`auth`, `name`, `rating`, `rating_max`, `rating_min`, `win`) VALUES ('%s', '%s', '%d', '%d', '%d', '%d') ON DUPLICATE KEY UPDATE `name` = '%s', `win` = `win`+'1', `rating` = '%d', `rating_max` = '%d';", auth_winner, name_winner, g_iELO[winner], g_iELO[winner], 1000, 1, 0, g_iELO[winner], g_iELOmax[winner]);
	SQL_TQuery(g_hSQL, PvPChallengeCallback, query, _, DBPrio_High);
	
	if(!IsFakeClient(loser))
	{
		//Loser
		FormatEx(query, sizeof(query), "INSERT INTO pvp_elo (`auth`, `name`, `rating`, `rating_max`, `rating_min`, `lose`) VALUES ('%s', '%s', '%d', '%d', '%d', '%d') ON DUPLICATE KEY UPDATE `name` = '%s', `lose` = `lose`+'1', `rating` = '%d', `rating_min` = '%d';", auth_loser, name_loser, g_iELO[loser], g_iELO[loser], 1000, 0, 1, g_iELO[loser], g_iELOmin[loser]);
		SQL_TQuery(g_hSQL, PvPChallengeCallback, query, _, DBPrio_High);
	}
	
	//Tracker
	FormatEx(query, sizeof(query), "INSERT INTO pvp_challenge (`map`, `style`, `bonus`, `auth_winner`, `name_winner`, `auth_loser`, `name_loser`, `diff`, `count`) VALUES ('%s', '%d', '%d', '%s', '%s', '%s', '%s', '%d', '1') ON DUPLICATE KEY UPDATE `diff` = `diff` + '%d', `count` = `count` + '1', date = CURRENT_TIMESTAMP();", map, style, bonus, auth_winner, name_winner, auth_loser, name_loser, diff, diff);
	SQL_TQuery(g_hSQL, PvPChallengeCallback, query, _, DBPrio_High);
	
	//Reload Stats
	FormatEx(query, sizeof(query), "SELECT `rating`, `rating_max`, `rating_min` FROM `pvp_elo` WHERE `auth` = '%s'", auth_winner);
	SQL_TQuery(g_hSQL, CallBack_ClientConnect, query, winner, DBPrio_Low);
	
	//Reload Loser
	FormatEx(query, sizeof(query), "SELECT `rating`, `rating_max`, `rating_min` FROM `pvp_elo` WHERE `auth` = '%s'", auth_loser);
	SQL_TQuery(g_hSQL, CallBack_ClientConnect, query, loser, DBPrio_Low);
	
	//Refresh Total
	FormatEx(query, sizeof(query), "SELECT COUNT(*) FROM `pvp_elo`");
	SQL_TQuery(g_hSQL, CallBack_TotalRank, query, _);
}

public PvPChallengeCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("SQL Error on PvPChallengeCallback: %s", error);
		return;
	}
}