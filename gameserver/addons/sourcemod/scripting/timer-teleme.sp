#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <timer>
#include <timer-config_loader.sp>

#undef REQUIRE_PLUGIN
#include <timer-mapzones>

new bool:g_timerMapzones = false;

public Plugin:myinfo =
{
	name        = "[Timer] TeleMe",
	author      = "Zipcore",
	description = "[Timer] Player 2 player teleporting",
	version     = PL_VERSION,
	url         = "forums.alliedmods.net/showthread.php?p=2074699"
};

public OnPluginStart()
{
	LoadPhysics();
	LoadTimerSettings();
	
	g_timerMapzones = LibraryExists("timer-mapzones");
	
	RegConsoleCmd("sm_teleme", Command_TeleMe);
	RegConsoleCmd("sm_tpto", Command_TeleMe);
	RegConsoleCmd("sm_teleport", Command_TeleMe);
	RegConsoleCmd("sm_teleportto", Command_TeleMe);
	RegConsoleCmd("sm_teleportme", Command_TeleMe);
}

public OnLibraryAdded(const String:name[])
{
	if(StrEqual(name, "timer-mapzones"))
	{
		g_timerMapzones = true;
	}
}

public OnLibraryRemoved(const String:name[])
{	
	if(StrEqual(name, "timer-mapzones"))
	{
		g_timerMapzones = false;
	}
}

public OnMapStart()
{
	LoadPhysics();
	LoadTimerSettings();
}

public Action:Command_TeleMe(client, args)
{
	if(IsPlayerAlive(client) && g_Settings[PlayerTeleportEnable])
	{
		if(!g_Settings[PlayerTeleportEnable]) 
		{
			ReplyToCommand(client, "Teleport disabled by server.");
			return Plugin_Handled;
		}
		
		new Handle:menu = CreateMenu(MenuHandlerTeleMe);
		SetMenuTitle(menu, "Teleport to selected player");
		//new bool:isadmin = Client_IsAdmin(client);
		
		new iCount = 0;
		
		//show rest
		for (new i = 1; i <= MaxClients; i++)
		{
			if(client == i || !IsClientInGame(i) || IsFakeClient(i) || !IsPlayerAlive(i))
			{
				continue;
			}
			
			decl String:name2[32];
			if(g_timerMapzones) 
				FormatEx(name2, sizeof(name2), "%N Stage: %d", i, Timer_GetClientLevel(i));
			else 
				FormatEx(name2, sizeof(name2), "%N", i);
				
			decl String:zone2[32];
			FormatEx(zone2,sizeof(zone2),"%d", i);
			AddMenuItem(menu, zone2, name2);
			iCount++;
		}
		
		if(iCount > 0)
		{
			SetMenuExitButton(menu, true);
			DisplayMenu(menu, client, 20);
		}
		else CPrintToChat(client, "%s No target found", PLUGIN_PREFIX2);
	}
	else
	{
		CPrintToChat(client, "%s You have to be alive", PLUGIN_PREFIX2);
	}
	
	return Plugin_Handled;
}

public MenuHandlerTeleMe(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:info[100], String:info2[100];
		new bool:found = GetMenuItem(menu, param2, info, sizeof(info), _, info2, sizeof(info2));
		new target = StringToInt(info);
		if(found)
		{
			if(IsPlayerAlive(client) && IsPlayerAlive(target))
			{
				new Float:origin[3], Float:angles[3];
				GetClientAbsOrigin(target, origin);
				GetClientAbsAngles(target, angles);
				
				//Do not reset his pretty timer if it can be paused
				if (g_Settings[PauseEnable])
				{
					FakeClientCommand(client, "sm_pause");
				}
				else
				{
					Timer_Reset(client);
				}		
				
				TeleportEntity(client, origin, angles, NULL_VECTOR);
			}
		}
	}
}
