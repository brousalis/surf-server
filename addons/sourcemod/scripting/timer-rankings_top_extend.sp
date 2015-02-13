#pragma semicolon 1

#include <sourcemod>
#include <timer>
#include <timer-rankings>
#include <timer-stocks>

#define EXTEND_MAX 30
#define LIMIT_TOP 50

new Handle:g_hTimelimit = INVALID_HANDLE;

new g_iExtendedTime;

public Plugin:myinfo = 
{
	name = "[Timer] Rankings - Top10 Extend",
	author = "Zipcore",
	description = "[Timer] Allows top10 players to extend maptime.",
	version = "1.0",
	url = "forums.alliedmods.net/showthread.php?p=2074699"
};

public OnPluginStart()
{
	g_hTimelimit = FindConVar("mp_timelimit");
	RegConsoleCmd("sm_extend", Command_Extend);
}

public OnMapStart()
{
	g_iExtendedTime = 0;
}

public Action:Command_Extend(client, args)
{
	if(0 < Timer_GetPointRank(client) <= LIMIT_TOP)
		Menu_Extend(client);
	else PrintToChat(client, "[Timer] You have to be at least rank%d by points to use this command.", LIMIT_TOP);
	
	return Plugin_Handled;
}

Menu_Extend(client)
{
	if(g_iExtendedTime >= EXTEND_MAX)
	{
		PrintToChat(client, "[Timer] Max extend time reached.");
		return;
	}
	
	new extendmax = EXTEND_MAX-g_iExtendedTime;
	
	new Handle:menu = CreateMenu(MenuHandler_Extend);

	SetMenuTitle(menu, "Extend Map", client);
	
	SetMenuExitButton(menu, true);
		
	for (new i = 1; i <= extendmax; i++)
	{
		new String:buffer[8];
		IntToString(i, buffer, sizeof(buffer));
		AddMenuItem(menu, buffer, buffer);
	}
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_Extend(Handle:menu, MenuAction:action, client, itemNum)
{
	if (action == MenuAction_End) 
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select) 
	{
		decl String:info[8];		
		GetMenuItem(menu, itemNum, info, sizeof(info));
		ServerCommand("mp_timelimit %d", GetConVarInt(g_hTimelimit)+StringToInt(info));
		g_iExtendedTime += StringToInt(info);
	}
}