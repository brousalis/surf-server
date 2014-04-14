#include <sourcemod>
#include <timer>
#include <timer-rankings>

public Plugin:myinfo =
{
	name        = "[Timer] Session Stats",
	author      = "Zipcore",
	description = "[Timer] Provides sessions stats",
	version     = PL_VERSION,
	url         = "forums.alliedmods.net/showthread.php?p=2074699"
};

new Handle:g_hSession = INVALID_HANDLE;

new String:g_sAuth[MAXPLAYERS + 1][24];
new bool:g_bAuthed[MAXPLAYERS + 1];
new bool:g_bCheck[MAXPLAYERS + 1];

new String:g_sCurrentMap[PLATFORM_MAX_PATH];

public OnPluginStart()
{
	RegConsoleCmd("sm_session", Cmd_Session);
	g_hSession = CreateKeyValues("data");
}

public OnMapStart()
{
	GetCurrentMap(g_sCurrentMap, sizeof(g_sCurrentMap));
}

public OnClientDisconnect_Post(client)
{
	DisconnectStats(client);
	g_bAuthed[client] = false;
}

public OnClientPostAdminCheck(client)
{
	g_bAuthed[client] = false;
	if(IsFakeClient(client) || IsClientSourceTV(client))
		return;
	
	g_bAuthed[client] = GetClientAuthString(client, g_sAuth[client], sizeof(g_sAuth[]));
	g_bCheck[client] = true;
}

public OnPlayerPointsLoaded(client, points)
{
	if(g_bAuthed[client] && g_bCheck[client])
	{
		if(KvJumpToKey(g_hSession, g_sAuth[client], false))
		{
			new Float:disconnec_time = GetEngineTime()-KvGetFloat(g_hSession, "disconnec_time", 0.0);
			if(disconnec_time > 180.0)
				CreateSession(client, points, false);
		}
		else CreateSession(client, points, true);
		
		KvRewind(g_hSession);
		
		g_bCheck[client] = false;
	}
}

CreateSession(client, points, bool:create)
{
	KvJumpToKey(g_hSession, g_sAuth[client], create);
	KvSetFloat(g_hSession, "connection_time", GetEngineTime());
	KvSetFloat(g_hSession, "disconnec_time", 0.0);
	KvSetNum(g_hSession, "points", points);
	KvSetNum(g_hSession, "worldrecords", 0);
	KvSetNum(g_hSession, "toprecords", 0);
	KvSetNum(g_hSession, "records", 0);
	KvRewind(g_hSession);
	
	CPrintToChat(client, "%s Session started. Type !session to see your session stats.", PLUGIN_PREFIX2);
}

public Action:Cmd_Session(client, args)
{
	SessionStats(client);
	return Plugin_Handled;
}

SessionStats(client)
{
	if(KvJumpToKey(g_hSession, g_sAuth[client], false))
	{
		
		new points_start = KvGetNum(g_hSession, "points", 0);
		new points = Timer_GetPoints(client);
		new time_connected = RoundToFloor(GetEngineTime()-KvGetFloat(g_hSession, "connection_time", GetEngineTime()));
		
		decl String:text[256];
		new Handle:panel = CreatePanel();
		DrawPanelText(panel, "[Timer] Player Session Stats");
		DrawPanelItem(panel, "Name");
		Format(text, sizeof(text), "%N", client);
		DrawPanelText(panel, text);
		DrawPanelItem(panel, "Points");
		Format(text, sizeof(text), "%d (%s%d)", points, (points-points_start < 0 ? "" : "+"), points-points_start);
		DrawPanelText(panel, text);
		DrawPanelItem(panel, "Time played");
		Format(text, sizeof(text), "%id %ih %im %is", time_connected / 86400,(time_connected % 86400) / 3600, (time_connected % 3600) / 60, time_connected % 60);
		DrawPanelText(panel, text);
		SendPanelToClient(panel, client, SessionHandler, 10);
		CloseHandle(panel);
	}
	KvRewind(g_hSession);
}

DisconnectStats(client)
{
	if(KvJumpToKey(g_hSession, g_sAuth[client], false))
	{
		new points_start = KvGetNum(g_hSession, "points", 0);
		new points = Timer_GetPoints(client);
		KvSetFloat(g_hSession, "disconnec_time", GetEngineTime());
		
		new String:sPre[3];
		if(points-points_start >= 0)
			Format(sPre, sizeof(sPre), "+");
		
		CPrintToChatAll("%s %N disconnected with %d points (%s%d).", PLUGIN_PREFIX2, client, points, sPre, points-points_start);
	}
	KvRewind(g_hSession);
}

public SessionHandler(Handle:menu, MenuAction:action, param1, param2)
{
}