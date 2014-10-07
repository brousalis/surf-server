#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <timer>
#include <timer-mysql>

new Handle:g_hSQL = INVALID_HANDLE;

public OnTimerSqlConnected(Handle:sql)
{
	g_hSQL = sql;
	
	LogMessage("sql update");
}

public OnTimerSqlStop()
{
	g_hSQL =  INVALID_HANDLE;
	
	LogMessage("sql stopped");
}