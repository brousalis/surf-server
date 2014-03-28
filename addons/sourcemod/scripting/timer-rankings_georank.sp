#include <sourcemod>
#include <sdktools>
#include <geoip> 
#include <timer>
#include <timer-logging>
#include <timer-rankings>

//Handles
new Handle:g_hDatabase = INVALID_HANDLE;
//Variables
new bool:g_bSql;

public Plugin:myinfo =
{
	name        = "[Timer] Rankings - Geo-ranking",
	author      = "Zipcore",
	description = "[Timer] Country ranking",
	version     = PL_VERSION,
	url         = "forums.alliedmods.net/showthread.php?p=2074699"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RegPluginLibrary("timer-rankings_georank");

	return APLRes_Success;
}

public OnPluginStart()
{
	RegConsoleCmd("sm_georank", Command_GeoRank);
	
	if(g_hDatabase == INVALID_HANDLE)
		SQL_TConnect(SQL_Connect_Database, "timer");
}

public OnMapStart()
{
	if(g_hDatabase == INVALID_HANDLE)
		SQL_TConnect(SQL_Connect_Database, "timer");
}

public SQL_Connect_Database(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	ErrorCheck(owner, error, "SQL_Connect_Database.Owner");
	ErrorCheck(hndl, error, "SQL_Connect_Database.Handle");

	g_hDatabase = hndl;
	decl String:sDriver[16];
	SQL_GetDriverIdent(owner, sDriver, sizeof(sDriver));

	g_bSql = StrEqual(sDriver, "mysql", false);
	if(g_bSql)
	{
		SQL_TQuery(g_hDatabase, CallBack_Names, "SET NAMES  'utf8'", _, DBPrio_High);
		SQL_TQuery(g_hDatabase, CallBack_Creation, "CREATE TABLE IF NOT EXISTS `ranks_geo` (`id` int(11) NOT NULL AUTO_INCREMENT, `country` varchar(65) NOT NULL, `points` int(11) NOT NULL default 0, PRIMARY KEY (`id`), UNIQUE KEY (country));");

	}
}

public CallBack_Names(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	ErrorCheck(hndl, error, "CallBack_Names");
}

public CallBack_Creation(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	ErrorCheck(hndl, error, "CallBack_Creation");
}

ErrorCheck(Handle:owner, const String:error[], const String:callback[] = "")
{
	if(owner == INVALID_HANDLE)
	{
		Timer_LogError("Rankings-Geo: Fatal error occured in `%s`", callback);
		Timer_LogError("> `%s`", error);

		SetFailState("FATAL SQL ERROR in `%s`; View logs!", callback);
	}
	else if(!StrEqual(error, ""))
	{
		Timer_LogError("Rankings-Geo: Error occured in `%s`", callback);
		Timer_LogError("> `%s`", error);
	}
}

public OnPlayerGainPoints(client, points)
{
	new String:sCountry[64]; 
	GetClientIP(client, sCountry, 64);
	
	if(!GeoipCountry(sCountry, sCountry, 64))
		Format(sCountry, 64, "Unknown");
	
	decl String:query[2048];
	FormatEx(query, sizeof(query), "INSERT INTO ranks_geo (country, points) VALUES ('%s', '%d') ON DUPLICATE KEY UPDATE points = points+%d;", sCountry, points, points);
		
	SQL_TQuery(g_hDatabase, UpdatePointsCallback, query, client, DBPrio_High);
}

public UpdatePointsCallback(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("SQL Error on UpdatePointsCallback: %s", error);
		return;
	}
}

public Action:Command_GeoRank(client, args)
{
	GetGeoTop(client);
		
	return Plugin_Handled;
}

public GetGeoTop(client)
{
	decl String:query[2048];
	FormatEx(query, sizeof(query), "SELECT `country`,`points` FROM `ranks_geo` WHERE `points` > 0 ORDER BY `points` DESC");
	SQL_TQuery(g_hDatabase, GetGeoTopCallback, query, client, DBPrio_High);
}

public GetGeoTopCallback(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("SQL Error on GetGeoTopCallback: %s", error);
		return;
	}
	
	new iIndex, iPoints;
	decl String:sCountry[32];
	if(SQL_GetRowCount(hndl))
	{
		new Handle:hPack = CreateDataPack();
		WritePackCell(hPack, iIndex);
		while(SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl, 0, sCountry, sizeof(sCountry));
			iPoints = SQL_FetchInt(hndl, 1);

			WritePackString(hPack, sCountry);
			WritePackCell(hPack, iPoints);

			iIndex++;
		}

		SetPackPosition(hPack, 0);
		WritePackCell(hPack, iIndex);
		CreateTopMenu(client, hPack);
	}
}

CreateTopMenu(client, Handle:pack)
{
	decl String:sBuffer[128], String:sCountry[32];
	new Handle:hMenu = CreateMenu(MenuHandler_MenuTopPlayers);

	SetMenuTitle(hMenu, "Geo Ranking");
	SetMenuExitButton(hMenu, true);
	SetMenuExitBackButton(hMenu, false);

	ResetPack(pack);
	new iCount = ReadPackCell(pack);
	for(new i = 0; i < iCount; i++)
	{
		ReadPackString(pack, sCountry, sizeof(sCountry));
		new iPoints = ReadPackCell(pack);

		FormatEx(sBuffer, sizeof(sBuffer), "%s: %d points", sCountry, iPoints, i + 1);
		AddMenuItem(hMenu, "", sBuffer, ITEMDRAW_DISABLED);
	}
	CloseHandle(pack);
	DisplayMenu(hMenu, client, 30);
}

public MenuHandler_MenuTopPlayers(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
	}
}