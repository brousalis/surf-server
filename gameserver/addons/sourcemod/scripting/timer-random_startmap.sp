#include <sourcemod>

new Handle:g_hSQL = INVALID_HANDLE;
new g_iSQLReconnectCounter;

new String:sql_selectMaps[] = "SELECT map FROM mapzone WHERE type = 0 GROUP BY map ORDER BY map LIMIT 100;";

public Plugin:myinfo = 
{
	name = "[Timer] Random Startmap",
	author = "Zipcore",
	description = "[Timer] Forces server to change to a random map on startup",
	version = "1.0",
	url = "forums.alliedmods.net/showthread.php?p=2074699"
}

public OnPluginStart()
{
	if (g_hSQL == INVALID_HANDLE)
	{
		ConnectSQL();
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
	
	decl String:Query[255];
	Format(Query, 255, sql_selectMaps);
	SQL_TQuery(g_hSQL, SQL_GetMapsCallback, Query, false);
}

public SQL_GetMapsCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		return;
	}
	
	if(SQL_GetRowCount(hndl))
	{
		new iCount = 0;
		decl String:sMap[100][128];
		
		while(SQL_FetchRow(hndl))
		{
			iCount++;
			SQL_FetchString(hndl, 0, sMap[iCount-1], sizeof(sMap[]));
		}
		
		if(iCount > 0)
		{
			new random = GetRandomInt(1, iCount)-1;
			ForceChangeLevel(sMap[random], "Random startmap");
		}
	}
	
	if (g_hSQL != INVALID_HANDLE)
	{
		CloseHandle(g_hSQL);
	}
}