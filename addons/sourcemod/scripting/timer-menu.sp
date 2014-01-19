#include <sourcemod>
#include <timer>
#include <timer-config_loader.sp>

public Plugin:myinfo =
{
    name        = "[Timer] Main Menu",
    author      = "Zipcore",
    description = "Main menu component for [Timer]",
    version     = PL_VERSION,
    url         = "zipcore#googlemail.com"
};

new GameMod:mod;
new String:g_sCurrentMap[PLATFORM_MAX_PATH];

public OnPluginStart()
{
	LoadPhysics();
	LoadTimerSettings();
	
	RegConsoleCmd("sm_menu", Command_Menu);	
	RegConsoleCmd("sm_timer", Command_Timer);
	RegConsoleCmd("sm_mapinfo", Command_MapInfo);
	
	mod = GetGameMod();
}

public OnMapStart()
{
	LoadPhysics();
	LoadTimerSettings();
	
	GetCurrentMap(g_sCurrentMap, sizeof(g_sCurrentMap));
}

public Action:Command_Menu(client, args)
{
	Menu(client);
	
	return Plugin_Handled;
}

public Action:Command_Timer(client, args)
{
	HelpPanel(client);
	
	return Plugin_Handled;
}

// ----------- Page 1 -------------------------------------------
public HelpPanel(client)
{
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, "- DMT|Timer by Zipcore -");
	
	if(mod == MOD_CSGO) SetPanelCurrentKey(panel, 8);
	else SetPanelCurrentKey(panel, 9);
	
	DrawPanelText(panel, "         -- Page 1/4 --");
	DrawPanelText(panel, " ");
	DrawPanelText(panel, "!timer - Displays this menu");
	DrawPanelText(panel, "!menu - Displays a main menu");
	DrawPanelText(panel, " ");
	DrawPanelText(panel, "!start - Teleport to startzone (or !r)");
	DrawPanelText(panel, "!bonusstart - Teleport to bonus startzone (or !b)");
	if(g_Settings[PauseEnable])
	{
		DrawPanelText(panel, "!pause - Pause the timer");
		DrawPanelText(panel, "!resume - Resume the timer");
	}
	else
	{
		DrawPanelText(panel, " ");
		DrawPanelText(panel, " ");
	}
	DrawPanelText(panel, " ");
	if(g_Settings[BhopEnable])
		DrawPanelText(panel, "!tauto - Toggle auto bhop");
	else 
		DrawPanelText(panel, " ");
	DrawPanelItem(panel, "- Next -");
	DrawPanelItem(panel, "- Exit -");
	SendPanelToClient(panel, client, PanelHandler1, MENU_TIME_FOREVER);

	CloseHandle(panel);
}
public PanelHandler1 (Handle:menu, MenuAction:action,param1, param2)
{
    if ( action == MenuAction_Select )
    {
		if(mod == MOD_CSGO) 
		{
			switch (param2)
			{
				case 8:
				{
					HelpPanel2(param1);
				}
			}
		}
		else
		{
			switch (param2)
			{
				case 9:
				{
					HelpPanel2(param1);
				}
			}
		}
    }
}

// ---------------------------------- Page 2 -------------------------------

public HelpPanel2(client)
{
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, "- DMT|Timer by Zipcore -");
	
	if(mod == MOD_CSGO) SetPanelCurrentKey(panel, 7);
	else SetPanelCurrentKey(panel, 8);
	
	DrawPanelText(panel, "         -- Page 2/4 --");
	DrawPanelText(panel, " ");
	DrawPanelText(panel, "!spectate - Go to spectators");
	DrawPanelText(panel, "!stage - Teleport to any Stage");
	DrawPanelText(panel, "!stage <number> - Teleport to a stage (not finished)");
	DrawPanelText(panel, "!tpto - Teleport to another player");
	DrawPanelText(panel, "!hide - Hide other players");
	DrawPanelText(panel, "!noclipme - Turn On/Off noclip mode");
	DrawPanelText(panel, "!hud - Customize your HUD");
	DrawPanelText(panel, " ");
	DrawPanelItem(panel, "- Back -");
	DrawPanelItem(panel, "- Next -");
	DrawPanelItem(panel, "- Exit -");
	SendPanelToClient(panel, client, PanelHandler2, MENU_TIME_FOREVER);

	CloseHandle(panel);
}

public PanelHandler2 (Handle:menu, MenuAction:action,param1, param2)
{
    if ( action == MenuAction_Select )
    {
		if(mod == MOD_CSGO) 
		{
			switch (param2)
			{
				case 7:
				{
					HelpPanel(param1);
				}
				case 8:
				{
					HelpPanel3(param1);
				}
			}
		}
		else
		{
			switch (param2)
			{
				case 8:
				{
					HelpPanel(param1);
				}
				case 9:
				{
					HelpPanel3(param1);
				}
			}
		}
    }
}

//------------------------- Page 3 -----------------------------------------
public HelpPanel3(client)
{
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, "- DMT|Timer by Zipcore -");
	
	if(mod == MOD_CSGO) SetPanelCurrentKey(panel, 7);
	else SetPanelCurrentKey(panel, 8);
	
	DrawPanelText(panel, "         -- Page 3/4 --");
	DrawPanelText(panel, " ");
	DrawPanelText(panel, "!challenge - Challenge another player [Steal points] (not finished)");
	DrawPanelText(panel, "!coop - Do it together [Extra points] (not finished)");
	DrawPanelText(panel, "!race - Displays race manager [Extra points] (not finished)");
	DrawPanelText(panel, "!rank - Displays your rank");
	DrawPanelText(panel, "!top - Displays top10 of this map");
	DrawPanelText(panel, "!mtop <mapname> - Displays a maps top10 (not finished)");
	DrawPanelText(panel, "!btop - Displays bonus top10 of this map");
	DrawPanelText(panel, "!mbtop <mapname> - Displays a maps bonus top10 (not finished)");
	DrawPanelText(panel, " ");
	DrawPanelItem(panel, "- Back -");
	DrawPanelItem(panel, "- Next -");
	DrawPanelItem(panel, "- Exit -");
	SendPanelToClient(panel, client, PanelHandler3, MENU_TIME_FOREVER);

	CloseHandle(panel);
}
public PanelHandler3 (Handle:menu, MenuAction:action,param1, param2)
{
    if ( action == MenuAction_Select )
    {
		if(mod == MOD_CSGO) 
		{
			switch (param2)
			{
				case 7:
				{
					HelpPanel2(param1);
				}
				case 8:
				{
					HelpPanel4(param1);
				}
			}
		}
		else
		{
			switch (param2)
			{
				case 8:
				{
					HelpPanel2(param1);
				}
				case 9:
				{
					HelpPanel4(param1);
				}
			}
		}
    }
}

//------------------------- Page 4 -----------------------------------------
public HelpPanel4(client)
{
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, "- DMT|Timer by Zipcore -");
	
	if(mod == MOD_CSGO) SetPanelCurrentKey(panel, 7);
	else SetPanelCurrentKey(panel, 8);
	
	DrawPanelText(panel, "         -- Page 4/4 --");
	DrawPanelText(panel, " ");
	DrawPanelText(panel, "!prank - Displays your point rank");
	DrawPanelText(panel, "!ptop - Displays top10 by pointrank");
	DrawPanelText(panel, "!mapinfo - Displays Mapinfo (not finished) (not finished)");
	DrawPanelText(panel, "!viewranks - View all ranks (not finished)");
	DrawPanelText(panel, "!viewrecords - View all records (not finished)");
	DrawPanelText(panel, "!playerinfo <partial playername> - Displays Playerinfos [WEB] (not finished)");
	DrawPanelText(panel, "!styleinfo - Displays Styleinfo");
	DrawPanelText(panel, "!credits - Displays Credits (not finished)");
	DrawPanelText(panel, " ");
	DrawPanelItem(panel, "- Back -");
	DrawPanelItem(panel, "- Next -", ITEMDRAW_SPACER);
	DrawPanelItem(panel, "- Exit -");
	SendPanelToClient(panel, client, PanelHandler4, MENU_TIME_FOREVER);

	CloseHandle(panel);
}
public PanelHandler4 (Handle:menu, MenuAction:action,param1, param2)
{
    if ( action == MenuAction_Select )
    {
		if(mod == MOD_CSGO) 
		{
			switch (param2)
			{
				case 7:
				{
					HelpPanel3(param1);
				}
			}
		}
		else
		{
			switch (param2)
			{
				case 8:
				{
					HelpPanel3(param1);
				}
			}
		}
    }
}

Menu(client)
{
	if (0 < client < MaxClients)
	{
		new Handle:menu = CreateMenu(Handle_Menu);
		
		SetMenuTitle(menu, "[DMT] Dynamic Mutimode Timer - Main Menu\nby Zipcore");
		
		AddMenuItem(menu, "mode", "Change Style");
		AddMenuItem(menu, "info", "Mode Settings Info");
		AddMenuItem(menu, "challenge", "Challenge");
		AddMenuItem(menu, "tele", "Teleport Menu");
		AddMenuItem(menu, "wrm", "World Record Menu");
		AddMenuItem(menu, "hud", "Custom HUD Settings");
		AddMenuItem(menu, "credits", "Credits");
		
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}
	
public Handle_Menu(Handle:menu, MenuAction:action, client, itemNum)
{
	if ( action == MenuAction_Select )
	{
		decl String:info[100], String:info2[100];
		new bool:found = GetMenuItem(menu, itemNum, info, sizeof(info), _, info2, sizeof(info2));
		if(found)
		{
			if(StrEqual(info, "mode"))
			{
				FakeClientCommand(client, "sm_style");
			}
			else if(StrEqual(info, "info"))
			{
				FakeClientCommand(client, "sm_physicinfo");
			}
			else if(StrEqual(info, "wrm"))
			{
				WorldRecordMenu(client);
			}
			else if(StrEqual(info, "tele"))
			{
				TeleportMenu(client);
			}
			else if(StrEqual(info, "challenge"))
			{
				if(IsClientInGame(client)) FakeClientCommand(client, "sm_challenge"); 
			}
			else if(StrEqual(info, "hud"))
			{
				if(IsClientInGame(client)) FakeClientCommand(client, "sm_hud"); 
			}
			else if(StrEqual(info, "credits"))
			{
				FakeClientCommand(client, "sm_menu");
				
				CPrintToChat(client, "{lightred}<-----------------{lightred}Credits:{olive}----------------->");
				CPrintToChat(client, "{olive}<------------------------------------------>");
				CPrintToChat(client, "{olive}<----->{lightred}This plugins is made by Zipcore{olive}<---->");
				CPrintToChat(client, "{olive}<------------------------------------------>");
				CPrintToChat(client, "{olive}<------------->{lightred}Special Thanks{olive}<------------->");
				CPrintToChat(client, "{lightred}Alongub: Old Timer Core");
				CPrintToChat(client, "{lightred}Justshoot: LongJump Stats");
				CPrintToChat(client, "{lightred}Peace-Maker: Backwards, Bot Mimic/Replay");
				CPrintToChat(client, "{lightred}Das D: Chatrank, Playerinfo");
				CPrintToChat(client, "{olive}<--------------{yellow}More Sourcecode{olive}------------->");
				CPrintToChat(client, "{lightred}Jason Bourne: Challenge, Custom-HUD");
				CPrintToChat(client, "{lightred}Skippy: Trigger Hooks");
				CPrintToChat(client, "{lightred}DaFox: Multi Bhop");
				CPrintToChat(client, "{lightred}DieterM75: CP-Mod");
				CPrintToChat(client, "{lightred}GoD-Tony: AutoTrigger");
				CPrintToChat(client, "{olive}<--------------{lightred}Also Thanks To:{olive}------------>");
				CPrintToChat(client, "{lightred}Also thanks to AlliedModders, Shadow, Schoschy,");
				CPrintToChat(client, "{lightred}Extan, cREANy0, Joy, Blackpanther, Popping-Fresh,");
				CPrintToChat(client, "{lightred}Kolapsicle and many others I can't list here!");
			}
		}
	}
}

WorldRecordMenu(client)
{
	if (0 < client < MaxClients)
	{
		new Handle:menu = CreateMenu(Handle_WorldRecordMenu);
				
		SetMenuTitle(menu, "World Record Menu");
		
		AddMenuItem(menu, "wr", "World Record");
		AddMenuItem(menu, "bwr", "Bonus World Record");
		AddMenuItem(menu, "swr", "Short World Record");
		AddMenuItem(menu, "main", "Back");
		
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}
	
public Handle_WorldRecordMenu(Handle:menu, MenuAction:action, client, itemNum)
{
	if ( action == MenuAction_Select )
	{
		decl String:info[100], String:info2[100];
		new bool:found = GetMenuItem(menu, itemNum, info, sizeof(info), _, info2, sizeof(info2));
		if(found)
		{
			if(StrEqual(info, "wr"))
			{
				FakeClientCommand(client, "sm_top");
			}
			else if(StrEqual(info, "bwr"))
			{
				FakeClientCommand(client, "sm_btop");
			}
			else if(StrEqual(info, "swr"))
			{
				FakeClientCommand(client, "sm_stop");
			}
			else if(StrEqual(info, "main"))
			{
				FakeClientCommand(client, "sm_menu");
			}
		}
	}
}

TeleportMenu(client)
{
	if (0 < client < MaxClients)
	{
		new Handle:menu = CreateMenu(Handle_TeleportMenu);
				
		SetMenuTitle(menu, "Teleport Menu");
		
		AddMenuItem(menu, "teleme", "Teleport to Player");
		AddMenuItem(menu, "levels", "Teleport to Level");
		AddMenuItem(menu, "checkpoint", "Teleport to Checkpoint ");
		AddMenuItem(menu, "main", "Back");
		
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}
	
public Handle_TeleportMenu(Handle:menu, MenuAction:action, client, itemNum)
{
	if ( action == MenuAction_Select )
	{
		decl String:info[100], String:info2[100];
		new bool:found = GetMenuItem(menu, itemNum, info, sizeof(info), _, info2, sizeof(info2));
		if(found)
		{
			if(StrEqual(info, "teleme"))
			{
				FakeClientCommand(client, "sm_tpto");
			}
			else if(StrEqual(info, "levels"))
			{
				FakeClientCommand(client, "sm_stage");
			}
			else if(StrEqual(info, "checkpoint"))
			{
				FakeClientCommand(client, "sm_cphelp");
			}
			else if(StrEqual(info, "main"))
			{
				FakeClientCommand(client, "sm_menu");
			}
		}
	}
}

public Action:Command_MapInfo(client, args)
{
	MapInfoMenu(client);
	
	return Plugin_Handled;
}

//Tier, stages/linear, obs bonus hat, wieviele rekorde, welche punkte du bekommen kannst, vllt den WR

MapInfoMenu(client)
{
	if (0 < client < MaxClients)
	{
		new Handle:menu = CreateMenu(Handle_MapInfoMenu);
		
		SetMenuTitle(menu, "MapInfo for %s", g_sCurrentMap);
		
		new String:buffer[128];
		
		new stages, bonusstages;
		
		stages = Timer_GetMapzoneCount(ZtLevel)+1;
		bonusstages = Timer_GetMapzoneCount(ZtBonusLevel)+1;
		
		new tier = Timer_GetTier();
		
		Format(buffer, sizeof(buffer), "Tier: %d", tier);
		AddMenuItem(menu, "tier", buffer);
		
		if(Timer_GetMapzoneCount(ZtStart) > 0)
		{
			if(stages == 1)
				Format(buffer, sizeof(buffer), "Level: Linear");
			else
				Format(buffer, sizeof(buffer), "Stages: %d", stages);
				
			AddMenuItem(menu, "stages", buffer);
		}
		
		if(Timer_GetMapzoneCount(ZtBonusStart) > 0)
		{
			if(bonusstages == 1)
				Format(buffer, sizeof(buffer), "Bonus-Level: Linear");
			else
				Format(buffer, sizeof(buffer), "Bonus-Stages: %d", stages);
			AddMenuItem(menu, "bonusstages", buffer);
		}
		
		if(Timer_GetMapzoneCount(ZtShortEnd) > 0)
		{
			Format(buffer, sizeof(buffer), "Short-End: Enabled");
			AddMenuItem(menu, "shortend", buffer);
		}
		
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}
	
public Handle_MapInfoMenu(Handle:menu, MenuAction:action, client, itemNum)
{
	if ( action == MenuAction_Select )
	{
		decl String:info[100], String:info2[100];
		new bool:found = GetMenuItem(menu, itemNum, info, sizeof(info), _, info2, sizeof(info2));
		if(found)
		{
			if(StrEqual(info, "teleme"))
			{
				FakeClientCommand(client, "sm_tpto");
			}
			else if(StrEqual(info, "levels"))
			{
				FakeClientCommand(client, "sm_stage");
			}
		}
	}
}