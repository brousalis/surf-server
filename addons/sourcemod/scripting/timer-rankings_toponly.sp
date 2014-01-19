#pragma semicolon 1
#define LEGACY_COLORS "CS:GO Color Support"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <basecomm>
#include <timer>
#include <timer-logging>
#include <dbi>
#include <clientprefs>
#include <timer-config_loader.sp>
#include <autoexecconfig>	//https://github.com/Impact123/AutoExecConfig

//* * * * * * * * * * * * * * * * * * * * * * * * * *
//Defines
//* * * * * * * * * * * * * * * * * * * * * * * * * *
//- States for plugin commands.
#define cChatCookie			0
#define cChatTop			1
#define cChatRank			2
#define cChatView			3
#define cChatNext			5
//- States for displaying data.
#define cDisplayNone		0
#define cDisplayScoreTag	1
#define cDisplayChatTag		2
#define cDisplayChatColor	4
#define cDisplayScoreStars	8
//- Cooldown for global messages.
#define cGlobalCooldown		60
//- States for debugging mode.
#define cPrintRanks			1
#define cPrintMaps			2
#define cPrintPlayers		4
//* * * * * * * * * * * * * * * * * * * * * * * * * *
//Handles
//* * * * * * * * * * * * * * * * * * * * * * * * * *
new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hDatabase = INVALID_HANDLE;
new Handle:g_hTrie_CfgCommands = INVALID_HANDLE;
new Handle:g_hCfgArray_DisplayTag = INVALID_HANDLE;
new Handle:g_hCfgArray_DisplayInfo = INVALID_HANDLE;
new Handle:g_hCfgArray_DisplayStars = INVALID_HANDLE;
new Handle:g_hCfgArray_DisplayChat = INVALID_HANDLE;
new Handle:g_hCfgArray_DisplayColor = INVALID_HANDLE;
new Handle:g_hArray_CfgPoints = INVALID_HANDLE;
new Handle:g_hArray_CfgRanks = INVALID_HANDLE;
new Handle:g_hArray_Positions = INVALID_HANDLE;
new Handle:g_hConnectTopOnly = INVALID_HANDLE;
new Handle:g_hKickMsg = INVALID_HANDLE;
new Handle:g_hKickDelay = INVALID_HANDLE;
//* * * * * * * * * * * * * * * * * * * * * * * * * *
//Variables
//* * * * * * * * * * * * * * * * * * * * * * * * * *
new bool:g_bLateLoad;
new bool:g_bInitalizing;
new g_iConnectTopOnly;
new g_iEnabled;
new g_iTotalRanks;
new g_iHighestRank;
new String:g_sLoadingScoreTag[64];
new String:g_sLoadingChatTag[64];
new String:g_sLoadingChatColor[64];
new String:g_sCurrentMap[PLATFORM_MAX_PATH];
new String:g_sPluginLog[PLATFORM_MAX_PATH];
new String:g_sDumpLog[PLATFORM_MAX_PATH];
new String:g_sKickMsg[512];
new Float:g_fKickDelay;
//* * * * * * * * * * * * * * * * * * * * * * * * * *
//Client Data
//* * * * * * * * * * * * * * * * * * * * * * * * * *
new g_iCompletions[MAXPLAYERS + 1];
new g_iCurrentPoints[MAXPLAYERS + 1];
new g_iNextIndex[MAXPLAYERS + 1] = { -1, ... };
new g_iCurrentIndex[MAXPLAYERS + 1] = { -1, ... };
new g_iCurrentRank[MAXPLAYERS + 1] = { -1, ... };
new g_iLastGlobalMessage[MAXPLAYERS + 1];
new String:g_sAuth[MAXPLAYERS + 1][24];
new bool:g_bLoadedSQL[MAXPLAYERS + 1];
new bool:g_bAuthed[MAXPLAYERS + 1];
new g_iClientDisplay[MAXPLAYERS + 1];
new bool:g_bLoadedCookies[MAXPLAYERS + 1];
new Float:g_fKickTime[MAXPLAYERS + 1];

public Plugin:myinfo =
{
	name        = "[Timer] Rankings Top Only",
	author      = "Zipcore",
	description = "Checks another servers points DB to kick low ranked players.",
	version     = PL_VERSION,
	url         = "zipcore#googlemail.com"
};

public OnPluginStart()
{
	AutoExecConfig_SetFile("timer-rankings_top_only");

	LoadPhysics();
	LoadTimerSettings();
	
	LoadTranslations("common.phrases");
	LoadTranslations("timer-rankings.phrases");
	AutoExecConfig_CreateConVar("timer_ranks_top_only_version", PL_VERSION, "[Timer] Rankings Top Only: Version", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hEnabled = AutoExecConfig_CreateConVar("timer_ranks_top_only_enabled", "2", "Determines operating mode of the plugin. (0 = Disabled, 1 = Enabled, 2 = Debug)", FCVAR_NONE, true, 0.0, true, 2.0);
	HookConVarChange(g_hEnabled, OnCVarChange);
	g_iEnabled = GetConVarInt(g_hEnabled);

	g_hConnectTopOnly = AutoExecConfig_CreateConVar("timer_ranks_top_only_connect_top_only", "1", "If enabled, the plugin will only allow top X players to connect, others will be kicked.", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hConnectTopOnly, OnCVarChange);
	g_iConnectTopOnly = GetConVarInt(g_hConnectTopOnly);

	g_hKickDelay = AutoExecConfig_CreateConVar("timer_ranks_top_only_kick_delay", "0.0", "Time to wait before player will be kicked.", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hKickDelay, OnCVarChange);
	g_fKickDelay = GetConVarFloat(g_hKickDelay);

	g_hKickMsg = AutoExecConfig_CreateConVar("timer_ranks_top_only_kick_msg", "Sry, you have to be at least rank {rank} on our other server to play on this server!", "Message to display before player will be kicked. Use {rank} to display needed rank.", FCVAR_NONE);
	HookConVarChange(g_hKickMsg, OnCVarChange);
	GetConVarString(g_hKickMsg, g_sKickMsg, sizeof(g_sKickMsg));

	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();

	if(!SQL_CheckConfig("timer_toponly"))
	{
		SetFailState("[Timer] Ranking Top Only Stopped - There is no 'timer_toponly' entry within databases.cfg!");
	}

	BuildPath(Path_SM, g_sPluginLog, sizeof(g_sPluginLog), "logs/timer-rankings_toponly.debug.log");
	BuildPath(Path_SM, g_sDumpLog, sizeof(g_sDumpLog), "logs/timer-rankings_toponly.dump.log");
}

public OnCVarChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == g_hEnabled)
	{
		g_iEnabled = StringToInt(newvalue);
	}
	else if(cvar == g_hConnectTopOnly)
	{
		g_iConnectTopOnly = StringToInt(newvalue);
	}
	else if(cvar == g_hKickDelay)
	{
		g_fKickDelay = StringToFloat(newvalue);
	}
	else if(cvar == g_hKickMsg)
	{
		Format(g_sKickMsg, sizeof(g_sKickMsg), "%s", newvalue);
	}
}

public OnConfigsExecuted()
{
	if(!g_iEnabled)
		return;

	Parse_Points();

	if(g_bLateLoad)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i))
			{
				g_bAuthed[i] = GetClientAuthString(i, g_sAuth[i], sizeof(g_sAuth[]));
				if(!g_bAuthed[i])
					CreateTimer(2.0, Timer_AuthClient, GetClientUserId(i), TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
				else
				{
					g_sAuth[i][6] = '0';
				}
			}
		}

		GetCurrentMap(g_sCurrentMap, sizeof(g_sCurrentMap));
		g_bLateLoad = false;
	}

	if(g_hDatabase == INVALID_HANDLE)
		SQL_TConnect(SQL_Connect_Database, "timer_toponly");
}

public OnMapStart()
{
	LoadPhysics();
	LoadTimerSettings();
	
	if(!g_iEnabled)
		return;

	GetCurrentMap(g_sCurrentMap, sizeof(g_sCurrentMap));
}

public OnMapEnd()
{
	if(!g_iEnabled)
		return;

	g_sCurrentMap[0] = '\0';
}

public OnClientPostAdminCheck(client)
{
	if(!g_iEnabled || IsFakeClient(client))
		return;

	g_bAuthed[client] = GetClientAuthString(client, g_sAuth[client], sizeof(g_sAuth[]));
	if(!g_bAuthed[client])
		CreateTimer(2.0, Timer_AuthClient, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	else if(g_hDatabase != INVALID_HANDLE && !g_bInitalizing)
	{
		g_sAuth[client][6] = '0';
		if(!g_bLoadedSQL[client])
		{
			decl String:sQuery[192];
			Format(sQuery, sizeof(sQuery), "SELECT `points` FROM `ranks` WHERE `auth` = '%s'", g_sAuth[client]);
			if(g_iEnabled == 2)
				PrintToDebug("OnClientPostAdminCheck(%N): Issuing Query `%s`", client, sQuery);
			SQL_TQuery(g_hDatabase, CallBack_ClientConnect, sQuery, GetClientUserId(client), DBPrio_Low);
		}
	}
}

public OnClientDisconnect(client)
{
	if(!g_iEnabled)
		return;

	g_sAuth[client][0] = '\0';

	g_bAuthed[client] = false;
	g_bLoadedSQL[client] = false;
	g_bLoadedCookies[client] = false;

	g_iNextIndex[client] = -1;
	g_iCurrentIndex[client] = -1;
	g_iCompletions[client] = 0;
	g_iCurrentPoints[client] = 0;
	g_iLastGlobalMessage[client] = 0;
	g_iClientDisplay[client] = 0;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

public SQL_Connect_Database(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	ErrorCheck(owner, error, "SQL_Connect_Database.Owner");
	ErrorCheck(hndl, error, "SQL_Connect_Database.Handle");

	g_hDatabase = hndl;
}

public CallBack_ClientConnect(Handle:owner, Handle:hndl, const String:error[], any:userid)
{
	ErrorCheck(owner, error, "CallBack_ClientConnect");

	new client = GetClientOfUserId(userid);
	if(!client || !IsClientInGame(client))
		return;

	decl String:sName[MAX_NAME_LENGTH];
	decl String:sSafeName[((MAX_NAME_LENGTH * 2) + 1)];
	GetClientName(client, sName, sizeof(sName));
	SQL_EscapeString(g_hDatabase, sName, sSafeName, sizeof(sSafeName));
	
	if(!SQL_GetRowCount(hndl))
	{
		ValidatePlayerSlot(client);
	}
	else if(SQL_FetchRow(hndl))
	{
		g_iCurrentPoints[client] = SQL_FetchInt(hndl, 0);
		
		CreateTimer(2.0, Timer_LoadRank, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Timer_LoadRank(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	
	if (!IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	decl String:sText[192];
	
	Format(sText, sizeof(sText), "SELECT COUNT(*) FROM `ranks` WHERE `points` >= %d ORDER BY `points` DESC", g_iCurrentPoints[client]);
	if(g_iEnabled == 2)
		PrintToDebug("Load_Rank(%N): Issuing Query `%s`", client, sText);
	SQL_TQuery(g_hDatabase, CallBack_Rank, sText, GetClientUserId(client));
	
	return Plugin_Handled;
}

public CallBack_Rank(Handle:owner, Handle:hndl, const String:error[], any:userid)
{
	ErrorCheck(hndl, error, "CallBack_Rank");
	new client = GetClientOfUserId(userid);
	if(!client || !IsClientInGame(client))
		return;
	
	if(SQL_FetchRow(hndl))
	{
		g_iCurrentRank[client] = SQL_FetchInt(hndl, 0);
	}
	
	ValidatePlayerSlot(client);
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

Parse_Points()
{
	if(g_hArray_CfgPoints == INVALID_HANDLE)
		g_hArray_CfgPoints = CreateArray();
	else
		ClearArray(g_hArray_CfgPoints);

	if(g_hArray_CfgRanks == INVALID_HANDLE)
		g_hArray_CfgRanks = CreateArray();
	else
		ClearArray(g_hArray_CfgRanks);

	if(g_hCfgArray_DisplayTag == INVALID_HANDLE)
		g_hCfgArray_DisplayTag = CreateArray(16);
	else
		ClearArray(g_hCfgArray_DisplayTag);

	if(g_hCfgArray_DisplayChat == INVALID_HANDLE)
		g_hCfgArray_DisplayChat = CreateArray(16);
	else
		ClearArray(g_hCfgArray_DisplayChat);

	if(g_hTrie_CfgCommands == INVALID_HANDLE)
		g_hTrie_CfgCommands = CreateTrie();
	else
		ClearTrie(g_hTrie_CfgCommands);

	if(g_hCfgArray_DisplayInfo == INVALID_HANDLE)
		g_hCfgArray_DisplayInfo = CreateArray(16);
	else
		ClearArray(g_hCfgArray_DisplayInfo);

	if(g_hCfgArray_DisplayStars == INVALID_HANDLE)
		g_hCfgArray_DisplayStars = CreateArray();
	else
		ClearArray(g_hCfgArray_DisplayStars);

	if(g_hCfgArray_DisplayColor == INVALID_HANDLE)
		g_hCfgArray_DisplayColor = CreateArray(16);
	else
		ClearArray(g_hCfgArray_DisplayColor);

	if(g_hArray_Positions == INVALID_HANDLE)
		g_hArray_Positions = CreateArray();
	else
		ClearArray(g_hArray_Positions);

	new Handle:hTemp[7] = { INVALID_HANDLE, ... };
	hTemp[0] = CreateArray();
	hTemp[1] = CreateArray();
	hTemp[2] = CreateArray(64);
	hTemp[3] = CreateArray(64);
	hTemp[4] = CreateArray(64);
	hTemp[5] = CreateArray(64);
	hTemp[6] = CreateArray();

	g_iTotalRanks = 0;
	decl iBuffer, String:sPath[PLATFORM_MAX_PATH], String:sBuffer[64];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/timer/rankings.cfg");

	new Handle:hKeyValues = CreateKeyValues("Timer.Rankings.Configs");
	if(FileToKeyValues(hKeyValues, sPath) && KvGotoFirstSubKey(hKeyValues))
	{
		do
		{
			KvGetSectionName(hKeyValues, sPath, sizeof(sPath));
			if(StrEqual(sPath, "Commands", false))
			{
				KvGotoFirstSubKey(hKeyValues, false);
				do
				{
					KvGetSectionName(hKeyValues, sBuffer, sizeof(sBuffer));
					iBuffer = KvGetNum(hKeyValues, NULL_STRING, 0);

					if(!StrContains(sBuffer, "sm_"))
					{
						strcopy(sPath, sizeof(sPath), sBuffer);
						ReplaceString(sPath, sizeof(sPath), "sm_", "!", false);
						SetTrieValue(g_hTrie_CfgCommands, sPath, iBuffer);

						strcopy(sPath, sizeof(sPath), sBuffer);
						ReplaceString(sPath, sizeof(sPath), "sm_", "/", false);
						SetTrieValue(g_hTrie_CfgCommands, sPath, iBuffer);
					}
					else
						SetTrieValue(g_hTrie_CfgCommands, sBuffer, iBuffer);
				}
				while (KvGotoNextKey(hKeyValues, false));

				KvGoBack(hKeyValues);
			}
			else if(StrEqual(sPath, "Loading", false))
			{
				KvGetString(hKeyValues, "tag", g_sLoadingScoreTag, sizeof(g_sLoadingScoreTag));
				KvGetString(hKeyValues, "chat", g_sLoadingChatTag, sizeof(g_sLoadingChatTag));
				KvGetString(hKeyValues, "text", g_sLoadingChatColor, sizeof(g_sLoadingChatColor));

				#if !defined LEGACY_COLORS
				ReplaceString(g_sLoadingChatTag, sizeof(g_sLoadingChatTag), "#", "\x07");
				ReplaceString(g_sLoadingChatColor, sizeof(g_sLoadingChatColor), "#", "\x07");
				#endif
			}
			else
			{
				PushArrayCell(hTemp[0], KvGetNum(hKeyValues, "points", 0));

				PushArrayCell(hTemp[1], KvGetNum(hKeyValues, "ranks", 0));

				KvGetString(hKeyValues, "tag", sPath, sizeof(sPath));
				PushArrayString(hTemp[2], sPath);

				KvGetString(hKeyValues, "chat", sBuffer, sizeof(sBuffer));
				#if !defined LEGACY_COLORS
				ReplaceString(sBuffer, sizeof(sBuffer), "#", "\x07");
				#endif
				PushArrayString(hTemp[3], sBuffer);

				KvGetString(hKeyValues, "text", sBuffer, sizeof(sBuffer));
				#if !defined LEGACY_COLORS
				ReplaceString(sBuffer, sizeof(sBuffer), "#", "\x07");
				#endif
				PushArrayString(hTemp[4], sBuffer);

				KvGetString(hKeyValues, "info", sPath, sizeof(sPath));
				PushArrayString(hTemp[5], sPath);

				PushArrayCell(hTemp[6], KvGetNum(hKeyValues, "stars", 0));

				g_iTotalRanks++;
			}
		}
		while (KvGotoNextKey(hKeyValues));

		g_iTotalRanks--;
		for(new i = g_iTotalRanks; i >= 0; i--)
		{
			new iIndex;
			new iCurrent;
			new iLowest = 2147483647;

			new iSize = GetArraySize(hTemp[1]);
			for(new j = 0; j < iSize; j++)
			{
				if((iCurrent = GetArrayCell(hTemp[1], j)) <= iLowest)
				{
					iIndex = j;
					iLowest = iCurrent;
				}
			}

			PushArrayCell(g_hArray_CfgPoints, GetArrayCell(hTemp[0], iIndex));
			PushArrayCell(g_hArray_CfgRanks, GetArrayCell(hTemp[1], iIndex));
			GetArrayString(hTemp[2], iIndex, sPath, sizeof(sPath));
			PushArrayString(g_hCfgArray_DisplayTag, sPath);
			GetArrayString(hTemp[3], iIndex, sPath, sizeof(sPath));
			PushArrayString(g_hCfgArray_DisplayChat, sPath);
			GetArrayString(hTemp[4], iIndex, sPath, sizeof(sPath));
			PushArrayString(g_hCfgArray_DisplayColor, sPath);
			GetArrayString(hTemp[5], iIndex, sPath, sizeof(sPath));
			PushArrayString(g_hCfgArray_DisplayInfo, sPath);
			PushArrayCell(g_hCfgArray_DisplayStars, GetArrayCell(hTemp[6], iIndex));

			for(new j = 0; j <= 6; j++)
				RemoveFromArray(hTemp[j], iIndex);
		}

		new iSize = GetArraySize(g_hArray_CfgRanks);
		for(new i = 0; i < iSize; i++)
		{
			g_iHighestRank = GetArrayCell(g_hArray_CfgRanks, i);

			if(FindValueInArray(g_hArray_Positions, g_iHighestRank) == -1)
				PushArrayCell(g_hArray_Positions, g_iHighestRank);
		}
	}

	CloseHandle(hKeyValues);
	for(new i = 0; i <= 6; i++)
		CloseHandle(hTemp[i]);
}

public Action:Timer_AuthClient(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(IsClientInGame(client))
	{
		g_bAuthed[client] = GetClientAuthString(client, g_sAuth[client], sizeof(g_sAuth[]));
		if(!g_bAuthed[client])
			return Plugin_Continue;
		else
		{
			if(g_hDatabase != INVALID_HANDLE && !g_bInitalizing)
				return Plugin_Continue;

			g_sAuth[client][6] = '0';
			if(!g_bLoadedSQL[client])
			{
				decl String:sQuery[192];
				Format(sQuery, sizeof(sQuery), "SELECT `points` FROM `ranks` WHERE `auth` = '%s'", g_sAuth[client]);
				SQL_TQuery(g_hDatabase, CallBack_ClientConnect, sQuery, GetClientUserId(client));
			}
		}
	}

	return Plugin_Stop;
}

stock bool:Client_HasAdminFlags(client, flags=ADMFLAG_GENERIC)
{
	new AdminId:adminId = GetUserAdmin(client);
	
	if (adminId == INVALID_ADMIN_ID) {
		return false;
	}
	
	return bool:(GetAdminFlags(adminId, Access_Effective) & flags);
}

stock PrintToDebug(const String:format[], any:...)
{
	decl String:sBuffer[1024];
	VFormat(sBuffer, sizeof(sBuffer), format, 2);

	LogToFile(g_sPluginLog, sBuffer);
}

ErrorCheck(Handle:owner, const String:error[], const String:callback[] = "")
{
	if(owner == INVALID_HANDLE)
	{
		LogError("[Timer] Rankings: Fatal error occured in `%s`", callback);
		LogError("> `%s`", error);
		if(g_iEnabled == 2)
		{
			PrintToDebug("[Timer] Rankings: Fatal error occured in `%s`", callback);
			PrintToDebug("> `%s`", error);
		}

		SetFailState("FATAL SQL ERROR in `%s`; View logs!", callback);
	}
	else if(!StrEqual(error, ""))
	{
		LogError("[Timer] Rankings: Error occured in `%s`", callback);
		LogError("> `%s`", error);
		if(g_iEnabled == 2)
		{
			PrintToDebug("[Timer] Rankings: Error occured in `%s`", callback);
			PrintToDebug("> `%s`", error);
		}
	}
}

stock ValidatePlayerSlot(client)
{
	CreateTimer(2.0, Timer_ValidatePlayerSlot, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_ValidatePlayerSlot(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	
	if (!IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	if(g_iEnabled == 2)
	{
		PrintToDebug("ValidatePlayerSlot(%N): Req:%d < CurrentRank:%d", client, g_iConnectTopOnly, g_iCurrentRank[client]);
	}
	
	if(g_iConnectTopOnly > 0 && !Client_HasAdminFlags(client, ADMFLAG_GENERIC))
	{
		if(g_iConnectTopOnly < g_iCurrentRank[client] || g_iCurrentRank[client] < 1)
		{
			g_fKickTime[client] = GetGameTime()+g_fKickDelay;
			CreateTimer(2.0, Timer_PrepareKick, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
		}
	}
	
	return Plugin_Handled;
}

public Action:Timer_PrepareKick(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	
	if (!IsClientInGame(client))
	{
		return Plugin_Stop;
	}
	
	new String:sRank[32];
	Format(sRank, sizeof(sRank), "%d", g_iConnectTopOnly);
	
	new String:buffer[512];
	Format(buffer, sizeof(buffer), "%s", g_sKickMsg);
	
	ReplaceString(buffer, sizeof(buffer), "{rank}", sRank, true);
	
	if(GetGameTime() <= g_fKickTime[client])
	{
		CPrintToChat(client, " {darkred}%s", buffer);
	}
	else
	{
		KickClient(client, "%s", buffer);
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}