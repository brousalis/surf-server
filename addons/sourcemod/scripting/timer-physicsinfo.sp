#pragma semicolon 1

#include <sourcemod>
#include <adminmenu>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
#include <timer>
#include <timer-logging>
#include <timer-config_loader.sp>

public Plugin:myinfo =
{
    name        = "[Timer] Physicsinfo",
    author      = "Zipcore",
    description = "Physicsinfo component for [Timer]",
    version     = PL_VERSION,
    url         = "zipcore#googlemail.com"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RegPluginLibrary("timer-physicsinfo");

	return APLRes_Success;
}

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
	if(0 < client < GetMaxClients())
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
	if(0 < client < GetMaxClients())
	{
		new Handle:menu = CreateMenu(MenuHandler_InfoDetail);

		SetMenuTitle(menu, "Settings for %s", g_Physics[mode][ModeName]);
		
		SetMenuExitButton(menu, true);

		new String:buffer[8];
		new String:bigbuffer[64];
		IntToString(mode, buffer, sizeof(buffer));
		
		if(g_Physics[mode][ModeIsDefault]) 
		{
			Format(bigbuffer, sizeof(bigbuffer), "Default Mode");
			AddMenuItem(menu, buffer, bigbuffer);
		}
		
		//Format(bigbuffer, sizeof(bigbuffer), "TagName: %s", g_Physics[mode][ModeTagName]);
		//AddMenuItem(menu, buffer, bigbuffer);
		
		//Format(bigbuffer, sizeof(bigbuffer), "TagShortName: %s", g_Physics[mode][ModeTagShortName]);
		//AddMenuItem(menu, buffer, bigbuffer);
		
		Format(bigbuffer, sizeof(bigbuffer), "ChatCommand: %s", g_Physics[mode][ModeQuickCommand]);
		AddMenuItem(menu, buffer, bigbuffer);
		
		if(g_Physics[mode][ModeCategory] == MCategory_Fun) Format(bigbuffer, sizeof(bigbuffer), "Category: Fun");
		else if(g_Physics[mode][ModeCategory] == MCategory_Ranked) Format(bigbuffer, sizeof(bigbuffer), "Category: Ranked");
		else if(g_Physics[mode][ModeCategory] == MCategory_Practise) Format(bigbuffer, sizeof(bigbuffer), "Category: Practise");
		else Format(bigbuffer, sizeof(bigbuffer), "Category: Unknown");
		AddMenuItem(menu, buffer, bigbuffer);
		
		Format(bigbuffer, sizeof(bigbuffer), "Boost: %.1f", g_Physics[mode][ModeBoost]);
		AddMenuItem(menu, buffer, bigbuffer);
		
		if(g_Physics[mode][ModeAuto]) Format(bigbuffer, sizeof(bigbuffer), "Auto: Enabled");
		else Format(bigbuffer, sizeof(bigbuffer), "Auto: Disabled");
		AddMenuItem(menu, buffer, bigbuffer);
		
		Format(bigbuffer, sizeof(bigbuffer), "Stamina: %.1f", g_Physics[mode][ModeStamina]);
		AddMenuItem(menu, buffer, bigbuffer);
		
		Format(bigbuffer, sizeof(bigbuffer), "Gravity: x%.1f", g_Physics[mode][ModeGravity]);
		AddMenuItem(menu, buffer, bigbuffer);
		
		if(g_Physics[mode][ModeBlockPreSpeeding] > 0.0) Format(bigbuffer, sizeof(bigbuffer), "PrespeedMax: %.1f", g_Physics[mode][ModeBlockPreSpeeding]);
		else Format(bigbuffer, sizeof(bigbuffer), "PrespeedMax: Unlimited");
		AddMenuItem(menu, buffer, bigbuffer);
		
		if(g_Physics[mode][ModeMultiBhop] == 0) Format(bigbuffer, sizeof(bigbuffer), "Multimode: Map Default");
		else if(g_Physics[mode][ModeMultiBhop] == 1) Format(bigbuffer, sizeof(bigbuffer), "Multimode: Multihop");
		else if(g_Physics[mode][ModeMultiBhop] == 2) Format(bigbuffer, sizeof(bigbuffer), "Multimode: Nohop");
		else Format(bigbuffer, sizeof(bigbuffer), "Multimode: Unknown");
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