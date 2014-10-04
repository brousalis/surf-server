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

new g_reconnectCounter = 0;

new Handle:g_timerOnTimerSqlUpdate;
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
	
	g_timerOnTimerSqlUpdate = CreateGlobalForward("OnTimerSqlUpdate", ET_Event, Param_Cell);
	g_timerOnTimerSqlStop = CreateGlobalForward("OnTimerSqlStop", ET_Event);

	return APLRes_Success;
}

public OnPluginStart()
{
	ConnectSQL();
}

public OnPluginEnd()
{
	Call_StartForward(g_timerOnTimerSqlStop);
	Call_Finish();
}

ConnectSQL()
{
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
		Timer_LogError("Timer ERROR: SqLite is not supported, please check you databases.cfg and use MySQL driver");
	}
	
	g_reconnectCounter = 1;
}

public CreateSQLTableCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (owner == INVALID_HANDLE)
	{
		Timer_LogError("[timer-mysql.smx] +Failed to create table: %s",error);
		
		g_reconnectCounter++;
		ConnectSQL();

		return;
	}
	
	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("SQL Error on CreateSQLTable: %s", error);
		return;
	}
	
	Call_StartForward(g_timerOnTimerSqlUpdate);
	Call_PushCell(_:g_hSQL);
	Call_Finish();
	
	CreateTimer(1.0, Timer_HeartBeat, _, TIMER_REPEAT);
}

public Action:Timer_HeartBeat(Handle:timer, any:data)
{
	if(g_hSQL != INVALID_HANDLE)
	{
		Call_StartForward(g_timerOnTimerSqlUpdate);
		Call_PushCell(_:g_hSQL);
		Call_Finish();
	}
	else 
	{
		Call_StartForward(g_timerOnTimerSqlStop);
		Call_Finish();
	}
	
	return Plugin_Continue;
}
	