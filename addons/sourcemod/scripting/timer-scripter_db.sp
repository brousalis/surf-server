#pragma semicolon 1

#include <sourcemod>
#include <adminmenu>

#include <timer>
#include <timer-logging>
#include <timer-scripter_db>
#include <timer-config_loader.sp>

#define SQLITE__ 0
#define MYSQL__ 1
#define SQLMAX__ 2

new Handle:AdminMenu;
new Handle:hTopMenu = INVALID_HANDLE;

/**
 * Global Variables
 */

public Plugin:myinfo =
{
    name        = "[Timer] Scripter-DB System",
    author      = "Zipcore, Jason Bourne",
    description = "[Timer] Scripter DB system to block auto bhop scripters for auto styles",
    version     = PL_VERSION,
    url         = "forums.alliedmods.net/showthread.php?p=2074699"
};

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))
		AdminMenu = INVALID_HANDLE;
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RegPluginLibrary("timer-scripter_db");

	CreateNative("Timer_AddScripter", Native_AddScripter);
	CreateNative("Timer_IsScripter", Native_IsScripter);
	
	return APLRes_Success;
}

new g_iDatabaseId[MAXPLAYERS+1] = { -1, ... },
	g_DatabaseType = SQLITE__;

enum EQueries
{
	E_QCreate = 0,
	E_QInsert,
	E_QConnect,
	E_QDelete,
	E_QUpdate,
	E_QMax
};

new stock const String:SQLQueries[SQLMAX__][E_QMax][] =
{
	{ // SQLite
		"CREATE TABLE IF NOT EXISTS scripters ( id INTEGER PRIMARY KEY, name VARCHAR(65), steam VARCHAR(32) UNIQUE, ban_time DATE DEFAULT (DATE('now')), admin_steam VARCHAR(32) );",
		"INSERT INTO scripters (name, steam, admin_steam) VALUES ('%s', '%s', '%s');",
		"SELECT id FROM scripters WHERE steam = '%s';",
		"DELETE FROM scripters WHERE id = '%i';",
		"UPDATE scripters SET name = '%s' WHERE id = '%i';"
	},
	{ // MySQL
		"CREATE TABLE IF NOT EXISTS scripters ( id INTEGER PRIMARY KEY NOT NULL AUTO_INCREMENT, name VARCHAR(65), steam VARCHAR(32) UNIQUE, ban_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, admin_steam VARCHAR(32));",
		"INSERT INTO scripters (name, steam, admin_steam) VALUES ('%s', '%s', '%s');",
		"SELECT id FROM scripters WHERE steam = '%s';",
		"DELETE FROM scripters WHERE id = '%i';",
		"UPDATE scripters SET name = '%s' WHERE id = '%i';"
	}
};

new Handle:g_hSQL;

new g_reconnectCounter = 0;

public OnPluginStart()
{
	CreateConVar("sm_scripterdb_version", PL_VERSION, "Version Console Variable", FCVAR_CHEAT | FCVAR_DONTRECORD | FCVAR_NOTIFY);

	RegAdminCmd("sm_scripter", Command_Scripter, ADMFLAG_KICK, "sm_scripter <player> | Bans a player from all ranked modes except AUTO.");
	RegAdminCmd("sm_scripterid", Command_ScripterID, ADMFLAG_KICK, "sm_scripter <steamid> | Bans a player from all ranked modes except AUTO.");
	RegAdminCmd("sm_scripter_unban", Command_UnbanScripter, ADMFLAG_UNBAN, "sm_scripter_unban <player> | Unbans a player from all ranked modes except AUTO.");
	RegAdminCmd("sm_scripter_reload", Command_ReloadScripters, ADMFLAG_ROOT, "sm_scripter_reload <player(s)> | Reload scripters");

	LoadTranslations("common.phrases");
	LoadTranslations("timer.phrases");
	
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}	

	ConnectSQL();
	LoadPhysics();
}

public OnMapStart()
{
	LoadPhysics();
}

public Native_AddScripter(Handle:plugin, numParams)
{	
	
	new client = GetNativeCell(1);
	if (IsClientInGame(client))
	{
		if( ! Timer_IsScripter(client) && ! IsFakeClient(client))
		{

			ShowActivity2(client, "[ScripterDB]", " SERVER banned %N from ranked modes except AUTO [Reason: Scripter].", client);
				
			decl String:player_authid[32];
			GetClientAuthString(client, player_authid, sizeof(player_authid));
			decl String:admin_authid[32];
			strcopy(admin_authid, sizeof(admin_authid), "SERVER");
	
			decl String:query[255],
			String:name[MAX_NAME_LENGTH],
			String:name2[2*(MAX_NAME_LENGTH)+1];
			GetClientName(client, name, sizeof(name));
			SQL_EscapeString(g_hSQL, name, name2, sizeof(name2));
			Format(query, sizeof(query), SQLQueries[g_DatabaseType][E_QInsert], name2, player_authid, admin_authid);

			SQL_TQuery(g_hSQL, T_Insert, query, GetClientUserId(client), DBPrio_High);
		}
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
	db_createTables(driver);
	
	g_reconnectCounter = 1;
}

public db_createTables(String:driver[16])
{
	SQL_LockDatabase(g_hSQL);

	if (StrEqual(driver, "mysql", false))
	{
		SQL_TQuery(g_hSQL, CreateSQLTableCallback, SQLQueries[MYSQL__][E_QCreate]);
		
		SQL_FastQuery(g_hSQL, "SET NAMES  'utf8'");

	}
	else if (StrEqual(driver, "sqlite", false))
	{
		SQL_TQuery(g_hSQL, CreateSQLTableCallback, SQLQueries[SQLITE__][E_QCreate]);
	}

	SQL_UnlockDatabase(g_hSQL);
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

public OnClientAuthorized(client, const String:auth[])
{
	g_iDatabaseId[client] = -1;

	if (IsFakeClient(client))
	{
		return;
	}
	
	if (g_hSQL != INVALID_HANDLE)
	{
		decl String:query[255];
		Format(query, sizeof(query), SQLQueries[g_DatabaseType][E_QConnect], auth);
		SQL_TQuery(g_hSQL, T_ClientConnected, query, GetClientUserId(client));
	}
}

public T_ClientConnected(Handle:owner, Handle:hndl, const String:error[], any:uid_client)
{
	new client = GetClientOfUserId(uid_client);

	if (!client || !IsClientConnected(client))
	{
		return;
	}

	if (hndl == INVALID_HANDLE)
	{
		SetFailState(error);
	}
	else if (SQL_FetchRow(hndl))
	{
		g_iDatabaseId[client] = SQL_FetchInt(hndl, 0);
	}
}

public Action:Command_Scripter(client, argc)
{
	if (argc != 1)
	{
		ReplyToCommand(client, "[ScripterDB] sm_scripter <player> | Bans a player from all ranked modes except AUTO.");
	}
	else
	{
		decl String:arg[128];
		GetCmdArg(1, arg, sizeof(arg));

		decl reason, targets[1], String:target_name[1], bool:tn_is_ml;
		if ((reason = ProcessTargetString(arg, client, targets, sizeof(targets),
			COMMAND_FILTER_NO_MULTI | COMMAND_FILTER_NO_BOTS,
			target_name, sizeof(target_name), tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, reason);

			return Plugin_Handled;
		}

		if (reason != 1)
		{
			return Plugin_Handled;
		}

		if (Timer_IsScripter(targets[0]))
		{
			Timer_AddScripter(targets[0]);
		}
		else
		{
			ReplyToCommand(client, "[ScripterDB] %N was already banned.", targets[0]);
		}
	}

	return Plugin_Handled;
}

public T_Insert(Handle:owner, Handle:hndl, const String:error[], any:uid_client)
{
	new client = GetClientOfUserId(uid_client);

	if (!IsClientConnected(client))
	{
		return;
	}

	if (hndl == INVALID_HANDLE)
	{
		SetFailState(error);
	}
	else
	{
		decl String:query[255], String:authid[32];
		GetClientAuthString(client, authid, sizeof(authid));

		Format(query, sizeof(query), SQLQueries[g_DatabaseType][E_QConnect], authid);
		SQL_TQuery(g_hSQL, T_ClientConnected, query, GetClientUserId(client), DBPrio_High);
	}
}

public Action:Command_ScripterID(client, argc)
{
	if (argc != 1)
	{
		ReplyToCommand(client, "[ScripterDB] sm_scripterid <steamid> | Bans a player from all ranked modes except AUTO.");
	}
	else
	{
		decl String:arg[128];
		GetCmdArg(1, arg, sizeof(arg));

		if(client == 0) ShowActivity2(client, "[ScripterDB]", "SERVER banned %s from ranked modes except AUTO [Reason: Scripter].", arg);
			else ShowActivity2(client, "[ScripterDB]", "%N banned %s from ranked modes except AUTO [Reason: Scripter].", client, arg);
		
		decl String:admin_authid[32];
		if (client != 0)
		{
			GetClientAuthString(client, admin_authid, sizeof(admin_authid));
		}
		else
		{
			strcopy(admin_authid, sizeof(admin_authid), "SERVER");
		}

		decl String:query[255];
		Format(query, sizeof(query), SQLQueries[g_DatabaseType][E_QInsert], "unconnected", arg, admin_authid);
		SQL_TQuery(g_hSQL, T_InsertID, query, _, DBPrio_High);
	}

	return Plugin_Handled;
}

public T_InsertID(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		SetFailState(error);
	}
}

public Action:Command_UnbanScripter(client, argc)
{
	if (argc != 1)
	{
		ReplyToCommand(client, "[ScripterDB] sm_scripter_unban <player> | Unbans a player.");
	}
	else
	{
		decl String:arg[128];
		GetCmdArg(1, arg, sizeof(arg));

		decl reason, targets[1], String:target_name[1], bool:tn_is_ml;
		if ((reason = ProcessTargetString(arg, client, targets, sizeof(targets),
			COMMAND_FILTER_NO_MULTI | COMMAND_FILTER_NO_BOTS,
			target_name, sizeof(target_name), tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, reason);

			return Plugin_Handled;
		}

		if (reason != 1)
		{
			return Plugin_Handled;
		}

		if (g_iDatabaseId[targets[0]] != -1)
		{
			ShowActivity2(client, "[ScripterDB]", "%N unbanned %N from ranked modes.", client, targets[0]);

			decl String:query[255];
			Format(query, sizeof(query), SQLQueries[g_DatabaseType][E_QDelete], g_iDatabaseId[targets[0]]);

			SQL_TQuery(g_hSQL, T_NoAction, query);

			g_iDatabaseId[targets[0]] = -1;
		}
		else
		{
			ReplyToCommand(client, "[ScripterDB] %N wasn't banned.", targets[0]);
		}
	}

	return Plugin_Handled;
}

public OnClientDisconnect(client)
{
	if (g_iDatabaseId[client] != -1 && IsClientConnected(client))
	{
		decl String:query[255],
			String:name[MAX_NAME_LENGTH],
			String:name2[2*(MAX_NAME_LENGTH)+1];
		GetClientName(client, name, sizeof(name));
		SQL_EscapeString(g_hSQL, name, name2, sizeof(name2));

		Format(query, sizeof(query), SQLQueries[g_DatabaseType][E_QUpdate], name2, g_iDatabaseId[client], DBPrio_Low);
		SQL_TQuery(g_hSQL, T_NoAction, query);
	}

	g_iDatabaseId[client] = -1;
}

public T_NoAction(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		SetFailState(error);
	}
}

public Action:Command_ReloadScripters(client, argc)
{
	if (argc != 1)
	{
		ReplyToCommand(client, "[ScripterDB] sm_scripter_reload <player(s)> | Reload scripters");

		return Plugin_Handled;
	}

	new cClients = MaxClients;

	decl String:arg[32],
		cTargets,
		targets[cClients],
		String:target_name[1],
		bool:tn_is_ml;

	GetCmdArg(1, arg, sizeof(arg));
	if ((cTargets = ProcessTargetString(arg, client, targets, cClients,
		COMMAND_FILTER_NO_IMMUNITY | COMMAND_FILTER_NO_BOTS,
		target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, cTargets);

		return Plugin_Handled;
	}

	decl String:authid[32];
	for (new i = 0; i < cTargets; i++)
	{
		GetClientAuthString(targets[i], authid, sizeof(authid));
		OnClientAuthorized(targets[i], authid);
	}

	ReplyToCommand(client, "[ScripterDB] Reloading scripter(s)");

	return Plugin_Handled;
}

 public OnTimerStarted(client)
 {
	new mode = Timer_GetMode(client);
	if (!g_Physics[mode][ModeAuto] && Timer_IsModeRanked(mode))
	{
		if (Timer_IsScripter(client))
		{
			Timer_SetMode(client, g_ModeDefault);
			PrintToChat(client, "[ScripterDB] You are not allowed to play ranked modes except AUTO! Visit our forums to request an unban.");
		}
	}	
 }
 
public Native_IsScripter(Handle:plugin, numParams)
 {
	new client = GetNativeCell(1);
	return (g_iDatabaseId[client] != -1);
 }
 
 
public OnAdminMenuReady(Handle:topmenu)
{
	// Block this from being called twice
	if (topmenu == hTopMenu) {
		return;
	}
 
	// Save the Handle
	hTopMenu = topmenu;
	
	if ((FindTopMenuCategory(topmenu, "Timer Management")) == INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(hTopMenu,
			"Timer Management",
			TopMenuObject_Category,
			AdminMenu_CategoryHandler,
			INVALID_TOPMENUOBJECT);
	}

	AdminMenu = topmenu;
	new TopMenuObject:TimerAdminMenu = FindTopMenuCategory(topmenu, "Timer Management");
	AddToTopMenu(AdminMenu, "timer_scripter_add", TopMenuObject_Item, TopMenuHandler, TimerAdminMenu, "timer_scripter_add", ADMFLAG_RCON);
}

public TopMenuHandler(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "Add Scripter");

	else if (action == TopMenuAction_SelectOption)
		ShowScripterMenu(param);
}

ShowScripterMenu(client)
{
	new Handle:menu = CreateMenu(ScripterMenuHandler);
	SetMenuTitle(menu, "Add Scripter");
	AddTargetsToMenu(menu, client, true, true);
	SetMenuExitBackButton(menu, true);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public ScripterMenuHandler(Handle:menu, MenuAction:action, client, selection)
{
	if (action == MenuAction_Select)
	{
		decl String:info[32];
		GetMenuItem(menu, selection, info, sizeof(info));
		new tuserid = StringToInt(info);
		new target = GetClientOfUserId(tuserid);
		
		if (Timer_IsScripter(client))
		{
			PrintToChat(client, "[Scripter-DB] %N is already in the scripter db", target);
		}
		else
		{
			new String:clientauth[64];
			GetClientAuthString(client, clientauth, sizeof(clientauth));
			new String:targetauth[64];
			GetClientAuthString(target, targetauth, sizeof(targetauth));
			
			PrintToChat(client, "[[Scripter-DB] %N(%s) was added manually to the scripter DB", target,targetauth);
			Timer_LogInfo("[Scripter-DB] %N(%s) was added manually to the scripter DB by %N(%s)", target, targetauth, client, clientauth);
			Timer_AddScripter(target);
		}
		
		/* Re-draw the menu if they're still valid */
		if (IsClientInGame(client) && !IsClientInKickQueue(client))
		{
			ShowScripterMenu(client);
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (selection == MenuCancel_ExitBack && AdminMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(AdminMenu, client, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public AdminMenu_CategoryHandler(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayTitle) {
		Format(buffer, maxlength, "%t", "Timer Management");
	} else if (action == TopMenuAction_DisplayOption) {
		Format(buffer, maxlength, "%t", "Timer Management");
	}
}