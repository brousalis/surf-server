#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <timer>
#include <timer-mysql>
#include <timer-config_loader.sp>
#include <timer-stocks>
#include <timer-logging>

new Handle:g_hSQL;

new String:g_Version[] = PL_VERSION;
new String:g_DB_Version[32];

new g_reconnectCounter = 0;

new bool:g_DatabaseReady = false;

new Handle:g_timerOnTimerSqlConnected;
new Handle:g_timerOnTimerSqlStop;

public Plugin:myinfo =
{
    name        = "[Timer] MySQL Manager",
    author      = "Zipcore",
    description = "MySQL manager component for [Timer]",
    version     = PL_VERSION,
    url         = "zipcore#googlemail.com"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RegPluginLibrary("timer-mysql");
	
	CreateNative("Timer_SqlGetConnection", Native_SqlGetConnection);

	return APLRes_Success;
}

public OnPluginStart()
{
	g_timerOnTimerSqlConnected = CreateGlobalForward("OnTimerSqlConnected", ET_Event, Param_Cell);
	g_timerOnTimerSqlStop = CreateGlobalForward("OnTimerSqlStop", ET_Event);
	
	ConnectSQL();
}

public OnPluginEnd()
{
	g_DatabaseReady = false;
	Call_StartForward(g_timerOnTimerSqlStop);
	Call_Finish();
}

ConnectSQL()
{
	g_DatabaseReady = false;
	
	if(g_hSQL != INVALID_HANDLE)
	{
		Call_StartForward(g_timerOnTimerSqlStop);
		Call_Finish();
		
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

public Action:Timer_ReConnect(Handle:timer, any:data)
{
	ConnectSQL();
	return Plugin_Stop;
}

public ConnectSQLCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		g_reconnectCounter++;
		
		Timer_LogError("[timer-mysql.smx] Connection to SQL database has failed, Try %d, Reason: %s", g_reconnectCounter, error);
		
		if(g_reconnectCounter >= 100) 
		{
			Call_StartForward(g_timerOnTimerSqlStop);
			Call_Finish();
			Timer_LogError("[timer-mysql.smx] +++ To much errors. Restart your server for a new try. +++");
		}
		else if(g_reconnectCounter > 5) 
			CreateTimer(30.0, Timer_ReConnect);
		else if(g_reconnectCounter > 3)
			CreateTimer(5.0, Timer_ReConnect);
		else CreateTimer(1.0, Timer_ReConnect);
		
		return;
	}

	decl String:driver[16];
	SQL_GetDriverIdent(owner, driver, sizeof(driver));

	g_hSQL = CloneHandle(hndl);
	
	if (StrEqual(driver, "mysql", false))
	{
		SQL_TQuery(g_hSQL, CreateSQLTableCallback, "CREATE TABLE IF NOT EXISTS `data` (`key` varchar(32) NOT NULL, `setting` varchar(256) NOT NULL, PRIMARY KEY (`key`));");
	}
	else if (StrEqual(driver, "sqlite", false))
	{
		Call_StartForward(g_timerOnTimerSqlStop);
		Call_Finish();
		Timer_LogError("##### Timer ERROR: SqLite is not supported, please check you databases.cfg and use MySQL driver #####");
	}
	
	g_reconnectCounter = 1;
}

public CreateSQLTableCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (owner == INVALID_HANDLE)
	{
		Timer_LogError("[timer-mysql.smx] Failed to create table: %s",error);
		g_reconnectCounter++;
		ConnectSQL();

		return;
	}
	
	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("[timer-mysql.smx] SQL Error on CreateSQLTableCallback: %s", error);
		ConnectSQL();
		return;
	}
	
	SQL_TQuery(g_hSQL, GetDBVersionCallback, "SELECT `setting` FROM `data` WHERE `key` = db_version;");
}

public GetDBVersionCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (owner == INVALID_HANDLE)
	{
		Timer_LogError("[timer-mysql.smx] Failed to get database version: %s", error);
		ConnectSQL();
		return;
	}
	
	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("[timer-mysql.smx] SQL Error on GetDBVersionCallback: %s", error);
		ConnectSQL();
		return;
	}
	
	// Existing database
	if(SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, g_DB_Version, sizeof(g_DB_Version));
		
		// Database up to date
		if(StrEqual(g_DB_Version, g_Version, true))
		{
			Timer_LogInfo("[timer-mysql.smx] MySQL connection passed version check.");
			g_DatabaseReady = true;
		}
		
		/// Database outdated
		else if(CheckVersionOutdated(g_DB_Version, g_Version))
		{
			Timer_LogError("[timer-mysql.smx] ############################################################");
			Timer_LogError("[timer-mysql.smx] MySQL v%s is outdated or no valid.", g_DB_Version);
			
			CheckForUpdates();
			
			Timer_LogError("[timer-mysql.smx] MySQL v%s version ready to use.", g_Version);
			Timer_LogError("[timer-mysql.smx] ############################################################");
			decl String:query[512];
			Format(query, sizeof(query), "UPDATE `data` SET `setting` = %s WHERE `key` = db_version;", g_Version);
			SQL_TQuery(g_hSQL, UpdateDBVersionCallback, query, _, DBPrio_High);
			g_DatabaseReady = true;
		}
	}
	
	// Install new database
	else
	{
		g_DatabaseReady = true;
		decl String:query[512];
		Format(query, sizeof(query), "INSERT INTO `data`(`key`, `setting`) VALUES (db_version,%s);", g_Version);
		SQL_TQuery(g_hSQL, UpdateDBVersionCallback, query, _, DBPrio_High);
		Timer_LogInfo("[timer-mysql.smx] MySQL connection installed with version %s.", g_Version);
	}
	
	if(g_DatabaseReady)
	{
		Call_StartForward(g_timerOnTimerSqlConnected);
		Call_PushCell(_:g_hSQL);
		Call_Finish();
		
		CreateTimer(1.0, Timer_HeartBeat, _, TIMER_REPEAT);
	}
}

stock CheckVersionOutdated(String:version_old[], String:version_new[])
{
	decl String:versions_old[5][32];
	ExplodeString(version_old, ".", versions_old, 5, 32);
	
	decl String:versions_new[5][32];
	ExplodeString(version_new, ".", versions_new, 5, 32);
	
	if(StringToInt(version_old[0]) < StringToInt(version_new[0]))
		return true;
	if(StringToInt(version_old[1]) < StringToInt(version_new[1]))
		return true;
	if(StringToInt(version_old[2]) < StringToInt(version_new[2]))
		return true;
	if(StringToInt(version_old[3]) < StringToInt(version_new[3]))
		return true;
	if(StringToInt(version_old[4]) < StringToInt(version_new[4]))
		return true;
	
	return false;
}

public UpdateDBVersionCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (owner == INVALID_HANDLE)
	{
		Timer_LogError("[timer-mysql.smx] Failed to get database version: %s",error);
		ConnectSQL();
		return;
	}
	
	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("SQL Error on UpdateDBVersionCallback: %s", error);
		ConnectSQL();
		return;
	}
}

public EmptyCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (owner == INVALID_HANDLE)
	{
		Timer_LogError("[timer-mysql.smx] EmptyCallback: %s",error);
		ConnectSQL();
		return;
	}
	
	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("SQL Error on EmptyCallback: %s", error);
		ConnectSQL();
		return;
	}
}

public Action:Timer_HeartBeat(Handle:timer, any:data)
{
	if(g_hSQL == INVALID_HANDLE)
	{
		g_DatabaseReady = false;
		Call_StartForward(g_timerOnTimerSqlStop);
		Call_Finish();
	}
	
	return Plugin_Continue;
}

public Native_SqlGetConnection(Handle:plugin, numParams)
{
	if(g_DatabaseReady)
		return _:g_hSQL;
	else return _:INVALID_HANDLE;
}

stock CheckForUpdates()
{
	// Write missing values into levelprocess
	// Change wrong level id for bonus start
	if(CheckVersionOutdated(g_DB_Version, "2.1.4.7"))
	{
		Timer_LogError("[timer-mysql.smx] Executing fixes for v2.1.4.7.");
		
		decl String:query[512];
		Format(query, sizeof(query), "UPDATE `round` SET `levelprocess` = 999 WHERE `bonus` = 0 AND `levelprocess` < 1;");
		Timer_LogError("[timer-mysql.smx] Query: %s", query);
		SQL_TQuery(g_hSQL, EmptyCallback, query, _, DBPrio_High);
		Format(query, sizeof(query), "UPDATE `round` SET `levelprocess` = 1999 WHERE `bonus` = 1 AND `levelprocess` < 1;");
		Timer_LogError("[timer-mysql.smx] Query: %s", query);
		SQL_TQuery(g_hSQL, EmptyCallback, query, _, DBPrio_High);
		Format(query, sizeof(query), "UPDATE `round` SET `levelprocess` = 500 WHERE `bonus` = 2 AND `levelprocess` < 1;");
		Timer_LogError("[timer-mysql.smx] Query: %s", query);
		SQL_TQuery(g_hSQL, EmptyCallback, query, _, DBPrio_High);
		
		Format(query, sizeof(query), "UPDATE mapzone SET level_id = 1001 WHERE level_id = 1000");
		Timer_LogError("[timer-mysql.smx] Query: %s", query);
		SQL_TQuery(g_hSQL, EmptyCallback, query, _, DBPrio_High);
	}
}