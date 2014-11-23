#include <sourcemod>
#include <smlib>
#include <timer-logging>
#include <autoexecconfig>	//https://github.com/Impact123/AutoExecConfig

new Handle:g_hSQL = INVALID_HANDLE;
new g_reconnectCounter = 0;
new String:g_sAuth[MAXPLAYERS + 1][24];
new bool:g_bAuthed[MAXPLAYERS + 1];

new Handle:g_hServerID = INVALID_HANDLE;
new g_iServerID;

public Plugin:myinfo = 
{
	name = "[Timer] Players Online DB",
	author = "Zipcore",
	description = "Save online players into database as long they are connected.",
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
	AutoExecConfig_SetFile("timer/timer-online_DB");
	g_hServerID = AutoExecConfig_CreateConVar("timer_online_db_server_id", "1", "Server ID, don't use the same ID for multiple server which are sharing all database tables.");
	HookConVarChange(g_hServerID, OnCVarChange);
	g_iServerID = GetConVarInt(g_hServerID);

	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	RegAdminCmd("sm_online_refresh", Command_RefreshTable, ADMFLAG_ROOT);
	ConnectSQL();
}

public OnPluginEnd()
{
	decl String:query[512];
	Format(query, sizeof(query), "DELETE FROM `online` WHERE `server` = %d", g_iServerID);
	SQL_TQuery(g_hSQL, DeleteCallback, query, _, DBPrio_High);
}

public OnCVarChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == g_hServerID)
	{
		g_iServerID = StringToInt(newvalue);
	}
}

public Action:Command_RefreshTable(client, args)
{
	RefreshTable()
	return Plugin_Handled;
}

RefreshTable()
{
	decl String:query[512];
	Format(query, sizeof(query), "DELETE FROM `online` WHERE `server` = %d", g_iServerID);
	SQL_TQuery(g_hSQL, DeleteCallback, query, _, DBPrio_High);
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && !IsClientSourceTV(i))
		{
			g_bAuthed[i] = GetClientAuthString(i, g_sAuth[i], sizeof(g_sAuth[]));
			if(g_bAuthed[i])
			{
				FormatEx(query, sizeof(query), "INSERT INTO `online` (auth, server) VALUES ('%s','%d') ON DUPLICATE KEY server = %d;", g_sAuth[i], g_iServerID, g_iServerID);
				SQL_TQuery(g_hSQL, InsertCallback, query, _, DBPrio_Normal);
			}
		}
	}
}

public OnClientPostAdminCheck(client)
{
	g_bAuthed[client] = false;
	if(IsFakeClient(client) || IsClientSourceTV(client))
		return;
	
	g_bAuthed[client] = GetClientAuthString(client, g_sAuth[client], sizeof(g_sAuth[]));
	
	if (g_hSQL != INVALID_HANDLE)
	{
		if(Client_IsValid(client) && !IsFakeClient(client))
		{
			decl String:query[256];
			FormatEx(query, sizeof(query), "INSERT INTO `online` (auth, server) VALUES ('%s','%d') ON DUPLICATE KEY UPDATE server = %d;", g_sAuth[client], g_iServerID, g_iServerID);
			SQL_TQuery(g_hSQL, InsertCallback, query, _, DBPrio_Normal);
		}
	}
}

public OnClientDisconnect_Post(client)
{
	if(g_bAuthed[client])
	{
		decl String:query[256];
		Format(query, sizeof(query), "DELETE FROM `online` WHERE `auth` = '%s'", g_sAuth[client]);
		SQL_TQuery(g_hSQL, InsertCallback, query, _, DBPrio_Normal);
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
		SQL_TQuery(g_hSQL, CreateSQLTableCallback, "CREATE TABLE IF NOT EXISTS `online` (`auth` varchar(24) NOT NULL, `server` int(11) NOT NULL, UNIQUE KEY `online_single` (`auth`));");
	}
	else if (StrEqual(driver, "sqlite", false))
	{
		SetFailState("Timer ERROR: SqLite is not supported, please check you databases.cfg and use MySQL driver");
	}
	
	g_reconnectCounter = 1;
	
	RefreshTable();
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

public DeleteCallback(Handle:owner, Handle:hndl, const String:error[], any:param1)
{
	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("SQL Error on DeleteCallback: %s", error);
		return;
	}
}