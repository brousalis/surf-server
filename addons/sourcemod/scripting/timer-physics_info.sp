#pragma semicolon 1

#include <sourcemod>
#include <timer>
#include <timer-config_loader.sp>

public Plugin:myinfo =
{
    name        = "[Timer] Physicsinfo",
    author      = "Zipcore",
    description = "[Timer] Show details for all styles",
    version     = PL_VERSION,
    url         = "forums.alliedmods.net/showthread.php?p=2074699"
};

public OnPluginStart()
{
	RegConsoleCmd("sm_styleinfo", Command_Info);
	
	LoadPhysics();
}

public OnMapStart()
{
	LoadPhysics();
}

public Action:Command_Info(client, args) 
{
	if(IsClientConnected(client) && IsClientInGame(client))
	{
		CreateInfoMenu(client);
	}
	return Plugin_Handled;
}

CreateInfoMenu(client)
{
	if(0 < client < MaxClients)
	{
		new Handle:menu = CreateMenu(MenuHandler_Info);

		SetMenuTitle(menu, "Style Info", client);
		
		SetMenuExitButton(menu, true);

		for(new i = 0; i < MAX_MODES-1; i++) 
		{
			if(!g_Physics[i][ModeEnable])
				continue;
			
			new String:buffer[8];
			IntToString(i, buffer, sizeof(buffer));
				
			AddMenuItem(menu, buffer, g_Physics[i][ModeName]);
		}	

		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

public MenuHandler_Info(Handle:menu, MenuAction:action, client, itemNum)
{
	if (action == MenuAction_End) 
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select) 
	{
		decl String:info[8];		
		GetMenuItem(menu, itemNum, info, sizeof(info));
		
		CreateInfoDetailMenu(client, StringToInt(info));
	}
}

CreateInfoDetailMenu(client, mode)
{
	if(0 < client < MaxClients)
	{
		new Handle:menu = CreateMenu(MenuHandler_InfoDetail);

		SetMenuTitle(menu, "Settings for %s", g_Physics[mode][ModeName]);
		
		SetMenuExitButton(menu, true);

		new String:buffer[8];
		new String:bigbuffer[64];
		IntToString(mode, buffer, sizeof(buffer));
		
		if(g_Physics[mode][ModeIsDefault]) 
		{
			FormatEx(bigbuffer, sizeof(bigbuffer), "Default Mode");
			AddMenuItem(menu, buffer, bigbuffer);
		}
		
		//Format(bigbuffer, sizeof(bigbuffer), "TagName: %s", g_Physics[mode][ModeTagName]);
		//AddMenuItem(menu, buffer, bigbuffer);
		
		//Format(bigbuffer, sizeof(bigbuffer), "TagShortName: %s", g_Physics[mode][ModeTagShortName]);
		//AddMenuItem(menu, buffer, bigbuffer);
		
		FormatEx(bigbuffer, sizeof(bigbuffer), "ChatCommand: %s", g_Physics[mode][ModeQuickCommand]);
		AddMenuItem(menu, buffer, bigbuffer);
		
		if(g_Physics[mode][ModeCategory] == MCategory_Fun) FormatEx(bigbuffer, sizeof(bigbuffer), "Category: Fun");
		else if(g_Physics[mode][ModeCategory] == MCategory_Ranked) FormatEx(bigbuffer, sizeof(bigbuffer), "Category: Ranked");
		else if(g_Physics[mode][ModeCategory] == MCategory_Practise) FormatEx(bigbuffer, sizeof(bigbuffer), "Category: Practise");
		else FormatEx(bigbuffer, sizeof(bigbuffer), "Category: Unknown");
		AddMenuItem(menu, buffer, bigbuffer);
		
		FormatEx(bigbuffer, sizeof(bigbuffer), "Boost: %.1f", g_Physics[mode][ModeBoost]);
		AddMenuItem(menu, buffer, bigbuffer);
		
		if(g_Physics[mode][ModeAuto]) FormatEx(bigbuffer, sizeof(bigbuffer), "Auto: Enabled");
		else FormatEx(bigbuffer, sizeof(bigbuffer), "Auto: Disabled");
		AddMenuItem(menu, buffer, bigbuffer);
		
		FormatEx(bigbuffer, sizeof(bigbuffer), "Stamina: %.1f", g_Physics[mode][ModeStamina]);
		AddMenuItem(menu, buffer, bigbuffer);
		
		FormatEx(bigbuffer, sizeof(bigbuffer), "Gravity: x%.1f", g_Physics[mode][ModeGravity]);
		AddMenuItem(menu, buffer, bigbuffer);
		
		if(g_Physics[mode][ModeBlockPreSpeeding] > 0.0) FormatEx(bigbuffer, sizeof(bigbuffer), "PrespeedMax: %.1f", g_Physics[mode][ModeBlockPreSpeeding]);
		else FormatEx(bigbuffer, sizeof(bigbuffer), "PrespeedMax: Unlimited");
		AddMenuItem(menu, buffer, bigbuffer);
		
		if(g_Physics[mode][ModeMultiBhop] == 0) FormatEx(bigbuffer, sizeof(bigbuffer), "Multimode: Map Default");
		else if(g_Physics[mode][ModeMultiBhop] == 1) FormatEx(bigbuffer, sizeof(bigbuffer), "Multimode: Multihop");
		else if(g_Physics[mode][ModeMultiBhop] == 2) FormatEx(bigbuffer, sizeof(bigbuffer), "Multimode: Nohop");
		else FormatEx(bigbuffer, sizeof(bigbuffer), "Multimode: Unknown");
		AddMenuItem(menu, buffer, bigbuffer);

		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

public MenuHandler_InfoDetail(Handle:menu, MenuAction:action, client, itemNum)
{
	if (action == MenuAction_End) 
	{
		CloseHandle(menu);
		CreateInfoMenu(client);
	}
	else if (action == MenuAction_Select) 
	{
		decl String:info[8];		
		GetMenuItem(menu, itemNum, info, sizeof(info));
		
		CreateInfoDetailMenu(client, StringToInt(info));
	}
}