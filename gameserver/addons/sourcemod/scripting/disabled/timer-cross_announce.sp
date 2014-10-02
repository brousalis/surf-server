#include <sourcemod>
#include <smlib>
#include <timer-logging>
#include <timer>
#include <timer-stocks>
#include <timer-config_loader.sp>
#include <autoexecconfig>	//https://github.com/Impact123/AutoExecConfig

#undef REQUIRE_PLUGIN
#include <timer-physics>
#include <timer-worldrecord>
#include <timer-strafes>

new Handle:g_hSQL = INVALID_HANDLE;
new g_reconnectCounter = 0;

new Handle:g_hServerID = INVALID_HANDLE;
new g_iServerID;
new g_iLastID;

new String:g_sCurrentMap[PLATFORM_MAX_PATH];

new bool:g_timerPhysics = false;

public Plugin:myinfo = 
{
	name = "[Timer] Cross Announce",
	author = "Zipcore",
	description = "World record announce cross server.",
	version = "1.0",
	url = "zipcore#googlemail.com"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RegPluginLibrary("timer-online_db");

	return APLRes_Success;
}

public OnPluginStart()
{
	g_timerPhysics = LibraryExists("timer-physics");
	
	LoadPhysics();
	LoadTimerSettings();
	
	AutoExecConfig_SetFile("timer/timer-cross_announce");
	g_hServerID = AutoExecConfig_CreateConVar("timer_cross_server_id", "1", "Server ID");
	HookConVarChange(g_hServerID, OnCVarChange);
	g_iServerID = GetConVarInt(g_hServerID);

	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	ConnectSQL();
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
}

public OnMapStart()
{
	GetCurrentMap(g_sCurrentMap, sizeof(g_sCurrentMap));
	LoadPhysics();
	LoadTimerSettings();
}

public OnCVarChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == g_hServerID)
	{
		g_iServerID = StringToInt(newvalue);
	}
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
		SQL_SetCharset(g_hSQL, "utf8");
		SQL_TQuery(g_hSQL, CreateSQLTableCallback, "CREATE TABLE IF NOT EXISTS `cross` (`id` int(11) NOT NULL AUTO_INCREMENT, `server` int(11) NOT NULL, `text` varchar(2048) NOT NULL, PRIMARY KEY (`id`));");
	}
	else if (StrEqual(driver, "sqlite", false))
	{
		SetFailState("Timer ERROR: SqLite is not supported, please check you databases.cfg and use MySQL driver");
	}
	
	g_reconnectCounter = 1;
	
	new String:query[512];
	FormatEx(query, sizeof(query), "SELECT `id`, `text` FROM `cross` ORDER BY `id` DESC LIMIT 1;", -1);
	
	SQL_TQuery(g_hSQL, SelectStartCallback, query, _, DBPrio_Normal);
	
	CreateTimer(10.0, Timer_CheckCross, _, TIMER_REPEAT);
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
}

public InsertCallback(Handle:owner, Handle:hndl, const String:error[], any:param1)
{
	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("SQL Error on InsertCallback: %s", error);
		return;
	}
}

public OnTimerWorldRecord(client, bonus, mode, Float:time, Float:lasttime, currentrank, newrank)
{
	decl String:Buffer[2048];
	
	
	decl String:name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));
	SQL_EscapeString(g_hSQL, name, name, sizeof(name));
	
	new bool:ranked, Float:jumpacc;
	
	if(g_timerPhysics) 
	{
		ranked = bool:Timer_IsStyleRanked(mode);
		Timer_GetJumpAccuracy(client, jumpacc);
	}
	
	new bool:enabled = false;
	new jumps = 0;
	new fpsmax;

	Timer_GetClientTimer(client, enabled, time, jumps, fpsmax);
	
	decl String:TimeString[32];
	Timer_SecondsToTime(time, TimeString, sizeof(TimeString), 2);
	
	new String:BonusString[32];
	
	if(bonus == 1)
	{
		FormatEx(BonusString, sizeof(BonusString), " bonus");
	}
	else if(bonus == 2)
	{
		FormatEx(BonusString, sizeof(BonusString), " short");
	}
	
	new String:StyleString[128];
	if(g_Settings[MultimodeEnable]) 
		FormatEx(StyleString, sizeof(StyleString), " on %s", g_Physics[mode][StyleName]);
	
	if(ranked)
	{
		
		#if defined LEGACY_COLORS
		Format(Buffer, sizeof(Buffer), "{lightred}[CROSS-SERVER] {olive}New WR by {lightred}%s{olive} Map: %s%s%s. Time: {lightred}[%ss]", name, g_sCurrentMap, BonusString, StyleString, TimeString);
		#else
		Format(Buffer, sizeof(Buffer), "{red}[CROSS-SERVER] {lightblue}New WR by {red}%s{lightblue} Map: %s%s%s. Time: {yellow}[%ss]", name, g_sCurrentMap, BonusString, StyleString, TimeString);
		#endif
	}
	
	new String:query[2048];
	FormatEx(query, sizeof(query), "INSERT INTO `cross` (text, server) VALUES ('%s','%d');", Buffer, g_iServerID);
	SQL_TQuery(g_hSQL, InsertCallback, query, _, DBPrio_Normal);
}

public Action:Timer_CheckCross(Handle:timer, any:data)
{
	new String:query[512];
	FormatEx(query, sizeof(query), "SELECT `id`, `text` FROM `cross` WHERE `server` != %d AND `id` > '%d';", g_iServerID, g_iLastID);
	SQL_TQuery(g_hSQL, SelectCallback, query, _, DBPrio_Normal);
	
	return Plugin_Continue;
}

public SelectCallback(Handle:owner, Handle:hndl, const String:error[], any:pack)
{
	if (hndl == INVALID_HANDLE)
	{
		return;
	}
	
	new id;
	new String:text[2048];
	while (SQL_FetchRow(hndl))
	{
		id = SQL_FetchInt(hndl, 0);
		SQL_FetchString(hndl, 1, text, sizeof(text));
		g_iLastID = id;
		
		CPrintToChatAll(text);
	}
}

public SelectStartCallback(Handle:owner, Handle:hndl, const String:error[], any:pack)
{
	if (hndl == INVALID_HANDLE)
	{
		return;
	}
	
	while (SQL_FetchRow(hndl))
	{
		g_iLastID = SQL_FetchInt(hndl, 0);
	}
}