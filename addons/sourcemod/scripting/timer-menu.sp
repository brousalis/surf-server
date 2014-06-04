#pragma semicolon 1

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
	RegConsoleCmd("sm_timer", Command_HelpMenu);
	RegConsoleCmd("sm_help", Command_HelpMenu);
	
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

enum eCommand
{
    String:eCommand_Info[512],
    String:eCommand_Plugin[512],
}

new commandsperpage = 5;
new g_iCmdCount = 0;
new g_Commands[512][eCommand];
new g_iCurrentPage[MAXPLAYERS+1];
new maxpage;

public Action:Command_HelpMenu(client, args)
{
	//HelpPanel(client);
	Init_Commands();
	g_iCurrentPage[client] = 1;
	CommandPanel(client);
	
	return Plugin_Handled;
}

public Init_Commands()
{
	g_iCmdCount = 0;
	
	Add_Command("!timer - Displays this menu", "timer-core.smx");
	Add_Command("!menu - Displays a main menu", "timer-menu.smx");
	Add_Command("!style - Displays style selection menu", "timer-physics.smx");
	Add_Command("!start - Teleport to startzone (or !s)", "timer-mapzones.smx");
	Add_Command("!restart - Teleport to startzone (or !r)", "timer-mapzones.smx");
	Add_Command("!bonusstart - Teleport to bonus startzone (or !b)", "timer-mapzones.smx");
	Add_Command("!pause - Pause the timer", "timer-core.smx", g_Settings[PauseEnable]);
	Add_Command("!resume - Resume the timer", "timer-core.smx", g_Settings[PauseEnable]);
	Add_Command("!tauto - Toggle auto bhop", "timer-physics");
	Add_Command("!stage - Teleport to any Stage", "timer-core.smx", g_Settings[LevelTeleportEnable]);
	Add_Command("!tpto - Teleport to another player", "timer-teleme.smx", g_Settings[PlayerTeleportEnable]);
	Add_Command("!stuck - Teleport last stage (penalty time)", "timer-mapzones.smx", g_Settings[PlayerTeleportEnable]);
	Add_Command("!hide - Hide other players", "timer-hide.smx");
	Add_Command("!nc - Turn On/Off noclip mode", "timer-mapzones.smx", g_Settings[NoclipEnable]);
	Add_Command("!hud - Customize your HUD", "timer-hud.smx");
	Add_Command("!challenge - Challenge another player [Steal points]", "timer-teams.smx", g_Settings[ChallengeEnable]);
	Add_Command("!coop - Do it together ", "timer-teams.smx", g_Settings[CoopEnable]);
	Add_Command("!race - Displays race manager", "timer-teams.smx", g_Settings[RaceEnable]);
	Add_Command("!rank - Displays your rank", "timer-worldrecord.smx");
	Add_Command("!top - Displays top10 of this map (or !wr)", "timer-worldrecord.smx");
	Add_Command("!btop - Displays bonus top10 of this map (or !bwr)", "timer-worldrecord.smx");
	Add_Command("!stop - Displays short top10 of this map (or !swr)", "timer-worldrecord.smx");
	Add_Command("!mtop <mapname> - Displays a maps top10", "timer-worldrecord_maptop.smx");
	Add_Command("!mbtop <mapname> - Displays a maps bonus top10", "timer-worldrecord_maptop.smx");
	Add_Command("!ranks - Displays available chatranks", "timer-rankings.smx");
	Add_Command("!next - Displays next players", "timer-rankings.smx");
	Add_Command("!prank - Displays your point rank", "timer-rankings.smx");
	Add_Command("!ptop - Displays top10 by pointrank", "timer-rankings.smx");
	Add_Command("!points - Displays how much points you can get", "timer-rankings.smx");
	Add_Command("!latest - Displays latest records", "timer-worldrecord_latest.smx");
	Add_Command("!playerinfo - Displays ALL your stats", "timer-worldrecord_playerinfo.smx");
	Add_Command("!playerinfo <partial playername> - Displays ALL stats for a player", "timer-worldrecord_playerinfo.smx");
	Add_Command("!styleinfo - Displays Styleinfo", "timer-physics_info.smx");
	Add_Command("!mapinfo - Displays info about current map", "timer-mapinfo.smx");
	Add_Command("!spec - Switch to spectators", "timer-spec.smx");
	Add_Command("!specfar - Spectate player with highest level process", "timer-spec.smx");
	Add_Command("!specmost - Spectate player with most spectators", "timer-spec.smx");
	Add_Command("!speclist - List players spactating you", "timer-spec.smx");
	Add_Command("!georank - Displays Top countrys", "timer-rankings_georank.smx");
	Add_Command("!lj - Toogle Long Jump Stats", "timer-ljstats.smx");
	Add_Command("!ljtop - Displays Top Long Jumps", "timer-ljstats.smx");
	Add_Command("!ljsound - Toogle Long Jump Sounds", "timer-ljstats.smx");
	Add_Command("!ljpopup - Toogle Long Jump Stats Popup", "timer-ljstats.smx");
	Add_Command("!ljblock - Register Long Jump Destination", "timer-ljstats.smx");
	Add_Command("!gap - Measure units between 2 point", "timer-ljstats.smx");
	
	Add_Command("!credits - Displays Credits", "timer-core.smx");
}

Add_Command(String:info[], String:plugin[], bool:enable = true)
{
	if(enable && PluginEnabled(plugin))
	{
		Format(g_Commands[g_iCmdCount][eCommand_Info], 512, "%s", info);
		Format(g_Commands[g_iCmdCount][eCommand_Plugin], 512, "%s", plugin);
		g_iCmdCount++;
		maxpage = RoundToCeil(float(g_iCmdCount)/float(commandsperpage));
	}
}

public CommandPanel(client)
{
	new firstcomand = g_iCurrentPage[client]*commandsperpage-commandsperpage;
	
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, ">>> Timer Help Menu <<<\nby Zipcore");
	
	new String:sPage[512];
	Format(sPage, sizeof(sPage), "         -- Page %d/%d --", g_iCurrentPage[client], maxpage);
	
	DrawPanelText(panel, sPage);
	DrawPanelText(panel, " ");
	
	new String:buffer[512];
	new iCmdCount;
	for(new i=firstcomand; i < (g_iCurrentPage[client]*commandsperpage); i++)
	{
		Format(buffer, sizeof(buffer), "%s", g_Commands[i][eCommand_Info]);
		DrawPanelText(panel, buffer);
		iCmdCount++;
	}
	
	DrawPanelText(panel, " ");
	
	
	new startkey = 8;
	if(g_iCurrentPage[client] > 1)
		startkey = 7;
	
	//Fix CS:GO menu buttons
	if(mod == MOD_CSGO) SetPanelCurrentKey(panel, startkey);
	else SetPanelCurrentKey(panel, startkey+1);
	
	if(g_iCurrentPage[client] > 1) DrawPanelItem(panel, "- Back -");
	else DrawPanelText(panel, " ");
	if(g_iCurrentPage[client] < maxpage) DrawPanelItem(panel, "- Next -");
	else DrawPanelText(panel, " ");
	DrawPanelItem(panel, "- Exit -");
	
	SendPanelToClient(panel, client, CommandPanelHandler, MENU_TIME_FOREVER);

	CloseHandle(panel);
}

public CommandPanelHandler (Handle:menu, MenuAction:action,client, param2)
{
    if ( action == MenuAction_Select )
    {
		if(mod == MOD_CSGO) 
		{
			switch (param2)
			{
				case 7:
				{
					if(g_iCurrentPage[client] > 1)
						g_iCurrentPage[client]--;
					CommandPanel(client);
				}
				case 8:
				{
					if(g_iCurrentPage[client] < maxpage)
						g_iCurrentPage[client]++;
					CommandPanel(client);
				}
			}
		}
		else
		{
			switch (param2)
			{
				case 8:
				{
					if(g_iCurrentPage[client] > 1)
						g_iCurrentPage[client]--;
					CommandPanel(client);
				}
				case 9:
				{
					if(g_iCurrentPage[client] < maxpage)
						g_iCurrentPage[client]++;
					CommandPanel(client);
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
		SetMenuTitle(menu, "DMT|Timer - Main Menu \nby Zipcore");		
			
		AddMenuItem(menu, "mode", "Change Style");			
		if(PluginEnabled("timer-physicsinfo.smx"))
		{
			AddMenuItem(menu, "info", "Mode Settings Info");
		}
		if(g_Settings[ChallengeEnable])
		{
			AddMenuItem(menu, "challenge", "Challenge");
		}
		if(PluginEnabled("timer-cpmod.smx") || g_Settings[LevelTeleportEnable] || g_Settings[PlayerTeleportEnable])
		{
			AddMenuItem(menu, "tele", "Teleport Menu");
		}
		AddMenuItem(menu, "wrm", "World Record Menu");
		if(PluginEnabled("timer-hud.smx"))
		{
			AddMenuItem(menu, "hud", "Custom HUD Settings");
		}
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
				FakeClientCommand(client, "sm_credits");
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
		
		if(g_Settings[PlayerTeleportEnable])
		{
			AddMenuItem(menu, "teleme", "Teleport to Player");
		}
		if(g_Settings[LevelTeleportEnable])
		{
			AddMenuItem(menu, "levels", "Teleport to Level");
		}
		if(PluginEnabled("timer-cpmod.smx"))
		{
			AddMenuItem(menu, "checkpoint", "Teleport to Checkpoint");
		}
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

bool:PluginEnabled(const String:pluginNane[])
{
	decl String: pluginPath[PLATFORM_MAX_PATH + 1];
	BuildPath(Path_SM, pluginPath, sizeof(pluginPath), "plugins/%s", pluginNane);
	if(FileExists(pluginPath))
	{
		return true;
	}
	return false;
}