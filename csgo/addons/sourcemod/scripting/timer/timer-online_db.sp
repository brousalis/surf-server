#include <sourcemod>
#include <smlib>
#include <timer-logging>
#include <timer-mysql>

new Handle:g_hSQL = INVALID_HANDLE;
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
	g_hServerID = CreateConVar("timer_online_db_server_id", "1", "Server ID, don't use the same ID for multiple server which are sharing all database tables.");
	g_iServerID = GetConVarInt(g_hServerID);
	HookConVarChange(g_hServerID, OnCVarChange);

	AutoExecConfig(true, "timer/timer-online_DB");
	
	RegAdminCmd("sm_online_refresh", Command_RefreshTable, ADMFLAG_ROOT);
	
	if (g_hSQL == INVALID_HANDLE)
	{
		ConnectSQL();
	}
}

public OnPluginEnd()
{
	decl String:query[512];
	Format(query, sizeof(query), "DELETE FROM `online` WHERE `server` = %d", g_iServerID);
	SQL_TQuery(g_hSQL, DeleteCallback, query, _, DBPrio_High);
}

public OnMapStart()
{
	if (g_hSQL == INVALID_HANDLE)
	{
		ConnectSQL();
	}
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
	RefreshTable();
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
	g_hSQL = Handle:Timer_SqlGetConnection();
	
	if (g_hSQL == INVALID_HANDLE)
		CreateTimer(0.1, Timer_SQLReconnect, _ , TIMER_FLAG_NO_MAPCHANGE);
	else 
	{
		SQL_TQuery(g_hSQL, CreateSQLTableCallback, "CREATE TABLE IF NOT EXISTS `online` (`auth` varchar(24) NOT NULL, `server` int(11) NOT NULL, UNIQUE KEY `online_single` (`auth`));");
		RefreshTable();
	}
}

public CreateSQLTableCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (owner == INVALID_HANDLE)
	{
		Timer_LogError(error);
		
		ConnectSQL();
		return;
	}
	
	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("SQL Error on CreateSQLTable: %s", error);
		return;
	}
	
	RefreshTable();
}

public Action:Timer_SQLReconnect(Handle:timer, any:data)
{
	ConnectSQL();
	return Plugin_Stop;
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