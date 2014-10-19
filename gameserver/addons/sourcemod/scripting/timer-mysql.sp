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
	
	RegAdminCmd("timer_sql_force_update", Command_ForceUpdate, ADMFLAG_RCON, "timer_sql_force_update <version>");
	
	ConnectSQL();
}

public Action:Command_ForceUpdate(client, args)
{
	if(args == 1)
	{
		decl String:version[32];
		GetCmdArg(1, version,sizeof(version));
		strcopy(g_DB_Version, sizeof(g_DB_Version), version);
		InstallUpdates();
	}
	else strcopy(g_DB_Version, sizeof(g_DB_Version), "2.1.3");
	
	return Plugin_Handled;	
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
			CreateTimer(5.0, Timer_ReConnect);
		else if(g_reconnectCounter > 3)
			CreateTimer(3.0, Timer_ReConnect);
		else CreateTimer(1.0, Timer_ReConnect);
		
		return;
	}

	decl String:driver[16];
	SQL_GetDriverIdent(owner, driver, sizeof(driver));

	g_hSQL = CloneHandle(hndl);
	
	if (StrEqual(driver, "mysql", false))
	{
		SQL_TQuery(g_hSQL, CreateSQLTableCallback, "CREATE TABLE IF NOT EXISTS `settings` (`key` varchar(32) NOT NULL, `setting` varchar(256) NOT NULL, PRIMARY KEY (`key`));");
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
	
	SQL_TQuery(g_hSQL, GetDBVersionCallback, "SELECT `setting` FROM `settings` WHERE `key` = \"db_version\";");
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
			g_DatabaseReady = true;
		}
		
		/// Database outdated
		else if(CheckVersionOutdated(g_DB_Version, g_Version))
			InstallUpdates();
		
		// Plugin outdated
		else Timer_LogError("[timer-mysql.smx] Database v%s is newer then Plugin v%s", g_DB_Version, g_Version);
	}
	// Install new database
	else InstallNew();
	
	if(g_DatabaseReady)
	{
		Timer_LogInfo("[timer-mysql.smx] MySQL v%s connection established and ready.", g_DB_Version);
		Call_StartForward(g_timerOnTimerSqlConnected);
		Call_PushCell(_:g_hSQL);
		Call_Finish();
		
		CreateTimer(1.0, Timer_HeartBeat, _, TIMER_REPEAT);
	}
}

stock CheckVersionOutdated(String:version_old[], String:version_new[])
{
	decl String:versions_old[4][32];
	ExplodeString(version_old, ".", versions_old, 4, 32);
	
	decl String:versions_new[4][32];
	ExplodeString(version_new, ".", versions_new, 4, 32);
	
	for (new i = 0; i < 4; i++)
	{
		if(StringToInt(versions_old[i]) < StringToInt(versions_new[i]))
			return true;
		else if(StringToInt(versions_old[i]) > StringToInt(versions_new[i]))
			return false;
	}
	
	return false;
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
		Timer_LogError("[timer-mysql.smx] ##### Lost connection to database. #####");
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

stock InstallNew()
{
	decl String:date[32];
	FormatTime(date, sizeof(date), "%Y-%m-%d %H:%M:%S", GetTime());
	
	Timer_LogInfo("[timer-mysql.smx] No existing settings table found.");
	Timer_LogInfo("[timer-mysql.smx] MySQL connection installed with version %s.", g_Version);
	
	decl String:query[2048];
	
	Format(query, sizeof(query), "INSERT INTO `settings`(`key`, `setting`) VALUES ('db_version', '%s');", g_Version);
	Timer_LogError("[timer-mysql.smx] Query: %s", query);
	SQL_TQuery(g_hSQL, EmptyCallback, query, _, DBPrio_High);
	
	Format(query, sizeof(query), "INSERT INTO `settings`(`key`, `setting`) VALUES ('setup', '%s');", date);
	Timer_LogError("[timer-mysql.smx] Query: %s", query);
	SQL_TQuery(g_hSQL, EmptyCallback, query, _, DBPrio_High);
	
	Format(query, sizeof(query), "INSERT INTO `settings`(`key`, `setting`) VALUES ('last_update', '%s');", date);
	Timer_LogError("[timer-mysql.smx] Query: %s", query);
	SQL_TQuery(g_hSQL, EmptyCallback, query, _, DBPrio_High);
	
	/* Create ROUND table */ 
	Format(query, sizeof(query), "CREATE TABLE IF NOT EXISTS `round` (`id` int(11) NOT NULL AUTO_INCREMENT, `map` varchar(32) NOT NULL, `auth` varchar(32) NOT NULL, `time` float NOT NULL, `jumps` int(11) NOT NULL, `style` int(11) NOT NULL, `track` int(11) NOT NULL, `name` varchar(64) NOT NULL, `finishcount` int(11) NOT NULL, `stage` int(11) NOT NULL, `fpsmax` int(11) NOT NULL, `jumpacc` float NOT NULL, `strafes` int(11) NOT NULL, `strafeacc` float NOT NULL, `avgspeed` float NOT NULL, `maxspeed` float NOT NULL, `finishspeed` float NOT NULL, `flashbangcount` int(11) NULL, `rank` int(11) NOT NULL, `replaypath` varchar(32) NOT NULL, `custom1` varchar(32) NULL, `custom2` varchar(32) NULL, `custom3` varchar(32) NULL, date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, PRIMARY KEY (`id`), UNIQUE KEY `single_record` (`auth`, `map`, `style`, `track`));");
	SQL_SetCharset(g_hSQL, "utf8");
	Timer_LogError("[timer-mysql.smx] Query: %s", query);
	SQL_TQuery(g_hSQL, EmptyCallback, query, _, DBPrio_High);
	
	/* Create MAPZONE table */ 
	Format(query, sizeof(query), "CREATE TABLE IF NOT EXISTS `mapzone` (`id` int(11) NOT NULL AUTO_INCREMENT, `type` int(11) NOT NULL, `level_id` int(11) NOT NULL, `point1_x` float NOT NULL, `point1_y` float NOT NULL, `point1_z` float NOT NULL, `point2_x` float NOT NULL, `point2_y` float NOT NULL, `point2_z` float NOT NULL, `map` varchar(64) NOT NULL, `name` varchar(32) NOT NULL, PRIMARY KEY (`id`));");
	SQL_SetCharset(g_hSQL, "utf8");
	Timer_LogError("[timer-mysql.smx] Query: %s", query);
	SQL_TQuery(g_hSQL, EmptyCallback, query, _, DBPrio_High);
	
	/* Create MAPTIER table */ 
	Format(query, sizeof(query), "CREATE TABLE IF NOT EXISTS `maptier` (`id` int(11) NOT NULL AUTO_INCREMENT, `map` varchar(32) NOT NULL, `track` int(11) NOT NULL, `tier` int(11) NOT NULL, `stagecount` int(11) NOT NULL, PRIMARY KEY (`id`), UNIQUE KEY `single_record` (`map`, `track`));");
	SQL_SetCharset(g_hSQL, "utf8");
	Timer_LogError("[timer-mysql.smx] Query: %s", query);
	SQL_TQuery(g_hSQL, EmptyCallback, query, _, DBPrio_High);
	
	/* Create RANKS table */ 
	Format(query, sizeof(query), "CREATE TABLE IF NOT EXISTS `ranks` (`auth` varchar(24) NOT NULL PRIMARY KEY, `points` int(11) NOT NULL default 0, `lastname` varchar(65) NOT NULL default '', `lastplay` int(11) NOT NULL default 0);");
	SQL_SetCharset(g_hSQL, "utf8");
	Timer_LogError("[timer-mysql.smx] Query: %s", query);
	SQL_TQuery(g_hSQL, EmptyCallback, query, _, DBPrio_High);
	
	g_DatabaseReady = true;
}

stock InstallUpdates()
{
	decl String:update_version[32];
	
	decl String:query[2048];
	
	Timer_LogError("[timer-mysql.smx] ############################################################");
	Timer_LogError("[timer-mysql.smx] MySQL v%s is outdated.", g_DB_Version);
	
	Format(update_version, sizeof(update_version), "2.1.4.7");
	if(CheckVersionOutdated(g_DB_Version, update_version))
	{
		Timer_LogError("[timer-mysql.smx] Executing updates for v%s: Levelprocess fix", update_version);
		
		Format(query, sizeof(query), "UPDATE `round` SET `levelprocess` = 999 WHERE `bonus` = 0 AND `levelprocess` < 1;");
		Timer_LogError("[timer-mysql.smx] Query: %s", query);
		SQL_TQuery(g_hSQL, EmptyCallback, query, _, DBPrio_High);
		
		Format(query, sizeof(query), "UPDATE `round` SET `levelprocess` = 1999 WHERE `bonus` = 1 AND `levelprocess` < 1;");
		Timer_LogError("[timer-mysql.smx] Query: %s", query);
		SQL_TQuery(g_hSQL, EmptyCallback, query, _, DBPrio_High);
		
		Format(query, sizeof(query), "UPDATE `round` SET `levelprocess` = 500 WHERE `bonus` = 2 AND `levelprocess` < 1;");
		Timer_LogError("[timer-mysql.smx] Query: %s", query);
		SQL_TQuery(g_hSQL, EmptyCallback, query, _, DBPrio_High);
		
		Timer_LogError("[timer-mysql.smx] Executing updates for v%s: Bonus start fix", update_version);
		
		Format(query, sizeof(query), "UPDATE mapzone SET level_id = 1001 WHERE level_id = 1000");
		Timer_LogError("[timer-mysql.smx] Query: %s", query);
		SQL_TQuery(g_hSQL, EmptyCallback, query, _, DBPrio_High);
	}
	
	Format(update_version, sizeof(update_version), "2.1.5.1");
	if(CheckVersionOutdated(g_DB_Version, update_version))
	{
		Timer_LogError("[timer-mysql.smx] Executing updates for v%s: Flashbangcount fix", update_version);
		
		// flashbangcount fix
		Format(query, sizeof(query), "ALTER TABLE `round` MODIFY `flashbangcount` DEFAULT 0;");
		Timer_LogError("[timer-mysql.smx] Query: %s", query);
		SQL_TQuery(g_hSQL, EmptyCallback, query, _, DBPrio_High);
		
		Format(query, sizeof(query), "UPDATE `round` SET `flashbangcount` = 0 WHERE `flashbangcount` < 1;");
		Timer_LogError("[timer-mysql.smx] Query: %s", query);
		SQL_TQuery(g_hSQL, EmptyCallback, query, _, DBPrio_High);
	}
	
	
	Format(update_version, sizeof(update_version), "2.2.0.0");
	if(CheckVersionOutdated(g_DB_Version, update_version))
	{
		Timer_LogError("[timer-mysql.smx] Executing updates for v%s: Major update mysql module fix", update_version);
		
		// Rename bonus to track
		Format(query, sizeof(query), "ALTER TABLE round CHANGE bonus track int(11);");
		Timer_LogError("[timer-mysql.smx] Query: %s", query);
		SQL_TQuery(g_hSQL, EmptyCallback, query, _, DBPrio_High);
		
		Format(query, sizeof(query), "ALTER TABLE maptier CHANGE bonus track int(11);");
		Timer_LogError("[timer-mysql.smx] Query: %s", query);
		SQL_TQuery(g_hSQL, EmptyCallback, query, _, DBPrio_High);
		
		// Rename physicsdifficulty to style
		Format(query, sizeof(query), "ALTER TABLE round CHANGE physicsdifficulty style int(11);");
		Timer_LogError("[timer-mysql.smx] Query: %s", query);
		SQL_TQuery(g_hSQL, EmptyCallback, query, _, DBPrio_High);
		
		// Rename levelprocess to stage
		Format(query, sizeof(query), "ALTER TABLE round CHANGE levelprocess stage int(11);");
		Timer_LogError("[timer-mysql.smx] Query: %s", query);
		SQL_TQuery(g_hSQL, EmptyCallback, query, _, DBPrio_High);
	}
	
	Format(update_version, sizeof(update_version), "2.2.1.1");
	if(CheckVersionOutdated(g_DB_Version, update_version))
	{
		Timer_LogError("[timer-mysql.smx] Executing updates for v%s: Custom field default fix", update_version);
		
		// custom field default fix
		Format(query, sizeof(query), "ALTER TABLE `round` MODIFY `custom1` DEFAULT 0;");
		Timer_LogError("[timer-mysql.smx] Query: %s", query);
		SQL_TQuery(g_hSQL, EmptyCallback, query, _, DBPrio_High);
		Format(query, sizeof(query), "ALTER TABLE `round` MODIFY `custom2` DEFAULT 0;");
		Timer_LogError("[timer-mysql.smx] Query: %s", query);
		SQL_TQuery(g_hSQL, EmptyCallback, query, _, DBPrio_High);
		Format(query, sizeof(query), "ALTER TABLE `round` MODIFY `custom3` DEFAULT 0;");
		Timer_LogError("[timer-mysql.smx] Query: %s", query);
		SQL_TQuery(g_hSQL, EmptyCallback, query, _, DBPrio_High);
	}
	
	decl String:date[32];
	FormatTime(date, sizeof(date), "%Y-%m-%d %H:%M:%S", GetTime());
	Format(query, sizeof(query), "UPDATE `settings` SET `setting` = \"%s\" WHERE `key` = \"last_update\";", date);
	SQL_TQuery(g_hSQL, EmptyCallback, query, _, DBPrio_High);
	
	Format(query, sizeof(query), "UPDATE `settings` SET `setting` = \"%s\" WHERE `key` = \"db_version\";", g_Version);
	SQL_TQuery(g_hSQL, EmptyCallback, query, _, DBPrio_High);
	Timer_LogInfo("[timer-mysql.smx] MySQL v%s version updated.", g_Version);
	Timer_LogError("[timer-mysql.smx] ############################################################");
	
	g_DatabaseReady = true;
}