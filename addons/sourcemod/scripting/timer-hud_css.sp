#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <clientprefs>
#include <smlib>
#include <timer>
#include <timer-logging>
#include <timer-stocks>
#include <timer-config_loader.sp>

#undef REQUIRE_PLUGIN
#include <timer-mapzones>
#include <timer-teams>
#include <timer-maptier>
#include <timer-rankings>
#include <timer-worldrecord>
#include <timer-physics>
#include <js_ljstats>

#define THINK_INTERVAL 			1.0

enum Hud
{
	Master,
	Main,
	Time,
	Jumps,
	Speed,
	SpeedMax,
	JumpAcc,
	Side,
	Map,
	Mode,
	WR,
	Rank,
	PB,
	TTWR,
	Keys,
	Spec,
	Steam,
	Level,
	Timeleft,
	Points
}

/**
 * Global Variables
 */
new String:g_currentMap[64];

new Handle:g_cvarTimeLimit	= INVALID_HANDLE;

//module check
new bool:g_timerPhysics = false;
new bool:g_timerMapzones = false;
new bool:g_timerLjStats = false;
new bool:g_timerMapTier = false;
new bool:g_timerRankings = false;
new bool:g_timerWorldRecord = false;

new bool:spec[MAXPLAYERS+1];
new bool:hidemyass[MAXPLAYERS+1];

new g_iButtonsPressed[MAXPLAYERS+1] = {0,...};
new g_iJumps[MAXPLAYERS+1] = {0,...};
new Handle:g_hDelayJump[MAXPLAYERS+1] = {INVALID_HANDLE,...};

new Handle:g_hThink_Map = INVALID_HANDLE;
new g_iMap_TimeLeft = 1200;

new Handle:cookieHudPref;
new Handle:cookieHudMainPref;
new Handle:cookieHudMainTimePref;
new Handle:cookieHudMainJumpsPref;
new Handle:cookieHudMainSpeedPref;
new Handle:cookieHudMainJumpsAccPref;
new Handle:cookieHudMainSpeedMaxPref;
new Handle:cookieHudSidePref;
new Handle:cookieHudSideMapPref;
new Handle:cookieHudSideModePref;
new Handle:cookieHudSideWRPref;
new Handle:cookieHudSideRankPref;
new Handle:cookieHudSidePBPref;
new Handle:cookieHudSideTTWRPref;
new Handle:cookieHudSideKeysPref;
new Handle:cookieHudSideSpecPref;
new Handle:cookieHudSideSteamPref;
new Handle:cookieHudSideLevelPref;
new Handle:cookieHudSideTimeleftPref;
new Handle:cookieHudSidePointsPref;

new hudSettings[Hud][MAXPLAYERS+1];

public Plugin:myinfo =
{
    name        = "[Timer] HUD",
    author      = "Zipcore, Alongub",
    description = "[Timer] Player HUD with optional details to show and cookie support",
    version     = PL_VERSION,
    url         = "forums.alliedmods.net/showthread.php?p=2074699"
};

public OnPluginStart()
{
	g_timerPhysics = LibraryExists("timer-physics");
	g_timerMapzones = LibraryExists("timer-mapzones");
	g_timerLjStats = LibraryExists("timer-ljstats");
	g_timerMapTier = LibraryExists("timer-maptier");
	g_timerRankings = LibraryExists("timer-rankings");
	g_timerWorldRecord = LibraryExists("timer-worldrecord");
	
	LoadPhysics();
	LoadTimerSettings();
	
	LoadTranslations("timer.phrases");
	
	if(g_Settings[HUDMasterEnable]) 
	{
		HookEvent("player_jump", Event_PlayerJump);
		
		HookEvent("player_death", Event_Reset);
		HookEvent("player_team", Event_Reset);
		HookEvent("player_spawn", Event_Reset);
		HookEvent("player_disconnect", Event_Reset);
		
		RegConsoleCmd("sm_hidemyass", Cmd_HideMyAss);
		RegConsoleCmd("sm_hud", MenuHud);
		RegConsoleCmd("sm_hudmenu", MenuHud);
		RegConsoleCmd("sm_hudstyle", MenuHud);
		RegConsoleCmd("sm_specinfo", Cmd_SpecInfo);
		
		g_cvarTimeLimit = FindConVar("mp_timelimit");
		
		AutoExecConfig(true, "timer/timer-hud");
		
		//cookies yummy :)
		cookieHudPref = RegClientCookie("timer_hud_master", "Turn on or off all hud components", CookieAccess_Private);
		cookieHudMainPref = RegClientCookie("timer_hud_main", "Turn on or off main hud components", CookieAccess_Private);
		cookieHudMainTimePref = RegClientCookie("timer_hud_main_time", "Turn on or off time component", CookieAccess_Private);
		cookieHudMainJumpsPref = RegClientCookie("timer_hud_jumps", "Turn on or off jumps component", CookieAccess_Private);
		cookieHudMainJumpsAccPref = RegClientCookie("timer_hud_jump_acc", "Turn on or off jumps accuracy component", CookieAccess_Private);
		cookieHudMainSpeedPref = RegClientCookie("timer_hud_speed", "Turn on or off speed component", CookieAccess_Private);
		cookieHudMainSpeedMaxPref = RegClientCookie("timer_hud_speed_max", "Turn on or off max speed component", CookieAccess_Private);
		cookieHudSidePref = RegClientCookie("timer_hud_side", "Turn on or off side hud component", CookieAccess_Private);
		cookieHudSideMapPref = RegClientCookie("timer_hud_side_map", "Turn on or off map component", CookieAccess_Private);
		cookieHudSideModePref = RegClientCookie("timer_hud_side_mode", "Turn on or off mode component", CookieAccess_Private);
		cookieHudSideWRPref = RegClientCookie("timer_hud_side_wr", "Turn on or off wr component", CookieAccess_Private);
		cookieHudSideRankPref = RegClientCookie("timer_hud_side_rank", "Turn on or off rank component", CookieAccess_Private);
		cookieHudSidePBPref = RegClientCookie("timer_hud_side_pb", "Turn on or off pb component", CookieAccess_Private);
		cookieHudSideTTWRPref = RegClientCookie("timer_hud_side_ttwr", "Turn on or off ttwr component", CookieAccess_Private);
		cookieHudSideKeysPref = RegClientCookie("timer_hud_side_keys", "Turn on or off keys component", CookieAccess_Private);
		cookieHudSideSpecPref = RegClientCookie("timer_hud_side_spec", "Turn on or off speclist component", CookieAccess_Private);
		cookieHudSideSteamPref = RegClientCookie("timer_hud_side_steam", "Turn on or off steam component", CookieAccess_Private);
		cookieHudSideLevelPref = RegClientCookie("timer_hud_side_level", "Turn on or off level component", CookieAccess_Private);
		cookieHudSideTimeleftPref = RegClientCookie("timer_hud_side_timeleft", "Turn on or off timeleft component", CookieAccess_Private);
		cookieHudSidePointsPref = RegClientCookie("timer_hud_side_points", "Turn on or off points component", CookieAccess_Private);
	}
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "timer-physics"))
	{
		g_timerPhysics = true;
	}	
	else if (StrEqual(name, "timer-mapzones"))
	{
		g_timerMapzones = true;
	}		
	else if (StrEqual(name, "timer-ljstats"))
	{
		g_timerLjStats = true;
	}	
	else if (StrEqual(name, "timer-maptier"))
	{
		g_timerMapTier = true;
	}	
	else if (StrEqual(name, "timer-rankings"))
	{
		g_timerRankings = true;
	}		
	else if (StrEqual(name, "timer-worldrecord"))
	{
		g_timerWorldRecord = true;
	}
}

public OnLibraryRemoved(const String:name[])
{	
	if (StrEqual(name, "timer-physics"))
	{
		g_timerPhysics = false;
	}	
	else if (StrEqual(name, "timer-mapzones"))
	{
		g_timerMapzones = false;
	}		
	else if (StrEqual(name, "timer-ljstats"))
	{
		g_timerLjStats = false;
	}	
	else if (StrEqual(name, "timer-maptier"))
	{
		g_timerMapTier = false;
	}	
	else if (StrEqual(name, "timer-rankings"))
	{
		g_timerRankings = false;
	}		
	else if (StrEqual(name, "timer-worldrecord"))
	{
		g_timerWorldRecord = false;
	}
}

public OnMapStart() 
{
	for (new client = 1; client <= MaxClients; client++)
	{
		g_hDelayJump[client] = INVALID_HANDLE;
	}
	
	GetCurrentMap(g_currentMap, sizeof(g_currentMap));
	
	if(GetEngineVersion() == Engine_CSS)
	{
		CreateTimer(0.1, HUDTimer_CSS, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	}
	
	RestartMapTimer();
	
	LoadPhysics();
	LoadTimerSettings();
}

public OnMapEnd()
{
	if(g_hThink_Map != INVALID_HANDLE)
	{
		CloseHandle(g_hThink_Map);
		g_hThink_Map = INVALID_HANDLE;
	}
}

public OnClientDisconnect(client)
{
	g_iButtonsPressed[client] = 0;
	if (g_hDelayJump[client] != INVALID_HANDLE)
	{
		CloseHandle(g_hDelayJump[client]);
		g_hDelayJump[client] = INVALID_HANDLE;
	}
}

public OnClientCookiesCached(client)
{
	// Initializations and preferences loading
	if(IsClientInGame(client) && !IsFakeClient(client))
	{
		loadClientCookiesFor(client);	
	}
}

loadClientCookiesFor(client)
{
	if(cookieHudPref == INVALID_HANDLE)
		return;
	
	decl String:buffer[5];
	
	//Master HUD
	GetClientCookie(client, cookieHudPref, buffer, 5);
	if(!StrEqual(buffer, ""))
	{
		hudSettings[Master][client] = StringToInt(buffer);
	}

	//Main HUD
	GetClientCookie(client, cookieHudMainPref, buffer, 5);
	if(!StrEqual(buffer, ""))
	{
		hudSettings[Main][client] = StringToInt(buffer);
	}
	
	//Show Time?
	GetClientCookie(client, cookieHudMainTimePref, buffer, 5);
	if(!StrEqual(buffer, ""))
	{
		hudSettings[Time][client] = StringToInt(buffer);
	}
	
	//Show Jumps?
	GetClientCookie(client, cookieHudMainJumpsPref, buffer, 5);
	if(!StrEqual(buffer, ""))
	{
		hudSettings[Jumps][client] = StringToInt(buffer);
	}

	//Show Speed?
	GetClientCookie(client, cookieHudMainSpeedPref, buffer, 5);
	if(!StrEqual(buffer, ""))
	{
		hudSettings[Speed][client] = StringToInt(buffer);
	}
	
	//Show SpeedMax?
	GetClientCookie(client, cookieHudMainSpeedMaxPref, buffer, 5);
	if(!StrEqual(buffer, ""))
	{
		hudSettings[SpeedMax][client] = StringToInt(buffer);
	}
	
	//Show JumpAcc?
	GetClientCookie(client, cookieHudMainJumpsAccPref, buffer, 5);
	if(!StrEqual(buffer, ""))
	{
		hudSettings[JumpAcc][client] = StringToInt(buffer);
	}
	
	//Show SideHUD?
	GetClientCookie(client, cookieHudSidePref, buffer, 5);
	if(!StrEqual(buffer, ""))
	{
		hudSettings[Side][client] = StringToInt(buffer);
	}
	
	//Show Side Map?
	GetClientCookie(client, cookieHudSideMapPref, buffer, 5);
	if(!StrEqual(buffer, ""))
	{
		hudSettings[Map][client] = StringToInt(buffer);
	}
	
	//Show Side Mode?
	GetClientCookie(client, cookieHudSideModePref, buffer, 5);
	if(!StrEqual(buffer, ""))
	{
		hudSettings[Mode][client] = StringToInt(buffer);
	}
	
	//Show Side WR?
	GetClientCookie(client, cookieHudSideWRPref, buffer, 5);
	if(!StrEqual(buffer, ""))
	{
		hudSettings[WR][client] = StringToInt(buffer);
	}
	
	//Show Side Rank?
	GetClientCookie(client, cookieHudSideRankPref, buffer, 5);
	if(!StrEqual(buffer, ""))
	{
		hudSettings[Rank][client] = StringToInt(buffer);
	}
	
	//Show Side PB?
	GetClientCookie(client, cookieHudSidePBPref, buffer, 5);
	if(!StrEqual(buffer, ""))
	{
		hudSettings[PB][client] = StringToInt(buffer);
	}
	
	//Show Side TTWR?
	GetClientCookie(client, cookieHudSideTTWRPref, buffer, 5);
	if(!StrEqual(buffer, ""))
	{
		hudSettings[TTWR][client] = StringToInt(buffer);
	}
	
	//Show Side Keys?
	GetClientCookie(client, cookieHudSideKeysPref, buffer, 5);
	if(!StrEqual(buffer, ""))
	{
		hudSettings[Keys][client] = StringToInt(buffer);
	}
	
	//Show Side Spec?
	GetClientCookie(client, cookieHudSideSpecPref, buffer, 5);
	if(!StrEqual(buffer, ""))
	{
		hudSettings[Spec][client] = StringToInt(buffer);
	}
	
	//Show Side Steam?
	GetClientCookie(client, cookieHudSideSteamPref, buffer, 5);
	if(!StrEqual(buffer, ""))
	{
		hudSettings[Steam][client] = StringToInt(buffer);
	}
	
	//Show Side Level?
	GetClientCookie(client, cookieHudSideLevelPref, buffer, 5);
	if(!StrEqual(buffer, ""))
	{
		hudSettings[Level][client] = StringToInt(buffer);
	}
	
	//Show Side Timeleft?
	GetClientCookie(client, cookieHudSideTimeleftPref, buffer, 5);
	if(!StrEqual(buffer, ""))
	{
		hudSettings[Timeleft][client] = StringToInt(buffer);
	}
	//Show Points ?
	GetClientCookie(client, cookieHudSidePointsPref, buffer, 5);
	if(!StrEqual(buffer, ""))
	{
		hudSettings[Points][client] = StringToInt(buffer);
	}
}

//  This selects or disables the Hud
public MenuHandlerHud(Handle:menu, MenuAction:action, client, itemNum)
{
	if ( action == MenuAction_Select )
	{
		decl String:info[100], String:info2[100];
		new bool:found = GetMenuItem(menu, itemNum, info, sizeof(info), _, info2, sizeof(info2));
		if(found)
		{
			if(StrEqual(info, "master"))
			{
				if (hudSettings[Master][client] == 0)
				{
					hudSettings[Master][client] = 1;
				} 
				else if (hudSettings[Master][client] == 1) 
				{
					hudSettings[Master][client] = 0;
				}
				
				decl String:buffer[5];
				IntToString(hudSettings[Master][client], buffer, 5);
				SetClientCookie(client, cookieHudPref, buffer);		
			}
			
			if(StrEqual(info, "main"))
			{
				if (hudSettings[Main][client] == 0)
				{
					hudSettings[Main][client] = 1;
				} 
				else if (hudSettings[Main][client] == 1) 
				{
					hudSettings[Main][client] = 0;
				}
				
				decl String:buffer[5];
				IntToString(hudSettings[Main][client], buffer, 5);
				SetClientCookie(client, cookieHudMainPref, buffer);		
			}
			
			if(StrEqual(info, "time"))
			{
				if (hudSettings[Time][client] == 0)
				{
					hudSettings[Time][client] = 1;
				} 
				else if (hudSettings[Time][client] == 1) 
				{
					hudSettings[Time][client] = 0;
				}
				
				decl String:buffer[5];
				IntToString(hudSettings[Time][client], buffer, 5);
				SetClientCookie(client, cookieHudMainTimePref, buffer);		
			}
			
			if(StrEqual(info, "jumps"))
			{
				if (hudSettings[Jumps][client] == 0)
				{
					hudSettings[Jumps][client] = 1;
				} 
				else if (hudSettings[Jumps][client] == 1) 
				{
					hudSettings[Jumps][client] = 0;
				}
				
				decl String:buffer[5];
				IntToString(hudSettings[Jumps][client], buffer, 5);
				SetClientCookie(client, cookieHudMainJumpsPref, buffer);		
			}
			
			if(StrEqual(info, "speed"))
			{
				if (hudSettings[Speed][client] == 0)
				{
					hudSettings[Speed][client] = 1;
				} 
				else if (hudSettings[Speed][client] == 1) 
				{
					hudSettings[Speed][client] = 0;
				}
				
				decl String:buffer[5];
				IntToString(hudSettings[Speed][client], buffer, 5);
				SetClientCookie(client, cookieHudMainSpeedPref, buffer);		
			}
			
			if(StrEqual(info, "speedmax"))
			{
				if (hudSettings[SpeedMax][client] == 0)
				{
					hudSettings[SpeedMax][client] = 1;
				} 
				else if (hudSettings[SpeedMax][client] == 1) 
				{
					hudSettings[SpeedMax][client] = 0;
				}
				
				decl String:buffer[5];
				IntToString(hudSettings[SpeedMax][client], buffer, 5);
				SetClientCookie(client, cookieHudMainSpeedMaxPref, buffer);		
			}
			
			if(StrEqual(info, "jumpacc"))
			{
				if (hudSettings[JumpAcc][client] == 0)
				{
					hudSettings[JumpAcc][client] = 1;
				} 
				else if (hudSettings[JumpAcc][client] == 1) 
				{
					hudSettings[JumpAcc][client] = 0;
				}
				
				decl String:buffer[5];
				IntToString(hudSettings[JumpAcc][client], buffer, 5);
				SetClientCookie(client, cookieHudMainJumpsAccPref, buffer);		
			}
			
			if(StrEqual(info, "side"))
			{
				if (hudSettings[Side][client] == 0)
				{
					hudSettings[Side][client] = 1;
				} 
				else if (hudSettings[Side][client] == 1) 
				{
					hudSettings[Side][client] = 0;
				}
				
				decl String:buffer[5];
				IntToString(hudSettings[Side][client], buffer, 5);
				SetClientCookie(client, cookieHudSidePref, buffer);		
			}
			
			if(StrEqual(info, "map"))
			{
				if (hudSettings[Map][client] == 0)
				{
					hudSettings[Map][client] = 1;
				} 
				else if (hudSettings[Map][client] == 1) 
				{
					hudSettings[Map][client] = 0;
				}
				
				decl String:buffer[5];
				IntToString(hudSettings[Map][client], buffer, 5);
				SetClientCookie(client, cookieHudSideMapPref, buffer);		
			}
			
			if(StrEqual(info, "mode"))
			{
				if (hudSettings[Mode][client] == 0)
				{
					hudSettings[Mode][client] = 1;
				} 
				else if (hudSettings[Mode][client] == 1) 
				{
					hudSettings[Mode][client] = 0;
				}
				
				decl String:buffer[5];
				IntToString(hudSettings[Mode][client], buffer, 5);
				SetClientCookie(client, cookieHudSideModePref, buffer);		
			}
			
			if(StrEqual(info, "wr"))
			{
				if (hudSettings[WR][client] == 0)
				{
					hudSettings[WR][client] = 1;
				} 
				else if (hudSettings[WR][client] == 1) 
				{
					hudSettings[WR][client] = 0;
				}
				
				decl String:buffer[5];
				IntToString(hudSettings[WR][client], buffer, 5);
				SetClientCookie(client, cookieHudSideWRPref, buffer);		
			}
			
			if(StrEqual(info, "level"))
			{
				if (hudSettings[Level][client] == 0)
				{
					hudSettings[Level][client] = 1;
				} 
				else if (hudSettings[Level][client] == 1) 
				{
					hudSettings[Level][client] = 0;
				}
				
				decl String:buffer[5];
				IntToString(hudSettings[Level][client], buffer, 5);
				SetClientCookie(client, cookieHudSideLevelPref, buffer);		
			}
			
			if(StrEqual(info, "timeleft"))
			{
				if (hudSettings[Timeleft][client] == 0)
				{
					hudSettings[Timeleft][client] = 1;
				} 
				else if (hudSettings[Timeleft][client] == 1) 
				{
					hudSettings[Timeleft][client] = 0;
				}
				
				decl String:buffer[5];
				IntToString(hudSettings[Timeleft][client], buffer, 5);
				SetClientCookie(client, cookieHudSideTimeleftPref, buffer);		
			}
			
			if(StrEqual(info, "rank"))
			{
				if (hudSettings[Rank][client] == 0)
				{
					hudSettings[Rank][client] = 1;
				} 
				else if (hudSettings[Rank][client] == 1) 
				{
					hudSettings[Rank][client] = 0;
				}
				
				decl String:buffer[5];
				IntToString(hudSettings[Rank][client], buffer, 5);
				SetClientCookie(client, cookieHudSideRankPref, buffer);		
			}
			
			if(StrEqual(info, "pb"))
			{
				if (hudSettings[PB][client] == 0)
				{
					hudSettings[PB][client] = 1;
				} 
				else if (hudSettings[PB][client] == 1) 
				{
					hudSettings[PB][client] = 0;
				}
				
				decl String:buffer[5];
				IntToString(hudSettings[PB][client], buffer, 5);
				SetClientCookie(client, cookieHudSidePBPref, buffer);		
			}
			
			if(StrEqual(info, "ttwr"))
			{
				if (hudSettings[TTWR][client] == 0)
				{
					hudSettings[TTWR][client] = 1;
				} 
				else if (hudSettings[TTWR][client] == 1) 
				{
					hudSettings[TTWR][client] = 0;
				}
				
				decl String:buffer[5];
				IntToString(hudSettings[TTWR][client], buffer, 5);
				SetClientCookie(client, cookieHudSideTTWRPref, buffer);		
			}
			
			if(StrEqual(info, "keys"))
			{
				if (hudSettings[Keys][client] == 0)
				{
					hudSettings[Keys][client] = 1;
				} 
				else if (hudSettings[Keys][client] == 1) 
				{
					hudSettings[Keys][client] = 0;
				}
				
				decl String:buffer[5];
				IntToString(hudSettings[Keys][client], buffer, 5);
				SetClientCookie(client, cookieHudSideKeysPref, buffer);		
			}
			
			if(StrEqual(info, "spec"))
			{
				if (hudSettings[Spec][client] == 0)
				{
					hudSettings[Spec][client] = 1;
				} 
				else if (hudSettings[Spec][client] == 1) 
				{
					hudSettings[Spec][client] = 0;
				}
				
				decl String:buffer[5];
				IntToString(hudSettings[Spec][client], buffer, 5);
				SetClientCookie(client, cookieHudSideSpecPref, buffer);		
			}
			
			if(StrEqual(info, "steam"))
			{
				if (hudSettings[Steam][client] == 0)
				{
					hudSettings[Steam][client] = 1;
				} 
				else if (hudSettings[Steam][client] == 1) 
				{
					hudSettings[Steam][client] = 0;
				}
				
				decl String:buffer[5];
				IntToString(hudSettings[Steam][client], buffer, 5);
				SetClientCookie(client, cookieHudSideSteamPref, buffer);		
			}
			
			if(StrEqual(info, "points"))
			{
				if (hudSettings[Points][client] == 0)
				{
					hudSettings[Points][client] = 1;
				} 
				else if (hudSettings[Points][client] == 1) 
				{
					hudSettings[Points][client] = 0;
				}
				
				decl String:buffer[5];
				IntToString(hudSettings[Points][client], buffer, 5);
				SetClientCookie(client, cookieHudSidePointsPref, buffer);		
			}
		}
		if(IsClientInGame(client)) ShowHudMenu(client, GetMenuSelectionPosition());
	} 
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
		
}
 
//  This creates the Hud Menu
public Action:MenuHud(client, args)
{
	ShowHudMenu(client, 1);
	return Plugin_Handled;
}

ShowHudMenu(client, start_item)
{
	if(g_Settings[HUDMasterOnlyEnable] && g_Settings[HUDMasterEnable])
	{
		if(hudSettings[Master][client] == 1)
		{
			hudSettings[Master][client] = 0;
			CPrintToChat(client, "%s HUD disabled.", PLUGIN_PREFIX2);
		}
		else
		{
			hudSettings[Master][client] = 1;
			CPrintToChat(client, "%s HUD enabled.", PLUGIN_PREFIX2);
		}
	}
	else if(g_Settings[HUDMasterEnable])
	{
		new Handle:menu = CreateMenu(MenuHandlerHud);
		decl String:buffer[100];
		
		FormatEx(buffer, sizeof(buffer), "Custom Hud Menu");
		SetMenuTitle(menu, buffer);
		
		if(hudSettings[Master][client] == 0)
		{
			AddMenuItem(menu, "master", "Enable HUD Master Switch");	
		}
		else
		{
			AddMenuItem(menu, "master", "Disable HUD Master Switch");	
		}
		
		if(g_Settings[HUDCenterEnable])
		{
			if(hudSettings[Main][client] == 0)
			{
				AddMenuItem(menu, "main", "Enable Center HUD");	
			}
			else
			{
				AddMenuItem(menu, "main", "Disable Center HUD");	
			}
		}
		
		if(g_Settings[HUDSideEnable])
		{
			if(hudSettings[Side][client] == 0)
			{
				AddMenuItem(menu, "side", "Enable Side HUD");	
			}
			else
			{
				AddMenuItem(menu, "side", "Disable Side HUD");	
			}
		}
		
		if(hudSettings[Time][client] == 0)
		{
			AddMenuItem(menu, "time", "Enable Time");	
		}
		else
		{
			AddMenuItem(menu, "time", "Disable Time");	
		}
	
		if(g_Settings[HUDJumpsEnable])
		{
			if(hudSettings[Jumps][client] == 0)
			{
				AddMenuItem(menu, "jumps", "Enable Jumps");	
			}
			else
			{
				AddMenuItem(menu, "jumps", "Disable Jumps");	
			}
		}
	
		if(g_Settings[HUDSpeedEnable])
		{
			if(hudSettings[Speed][client] == 0)
			{
				AddMenuItem(menu, "speed", "Enable Speed");	
			}
			else
			{
				AddMenuItem(menu, "speed", "Disable Speed");	
			}
		}
		
		if(g_Settings[HUDSpeedMaxEnable])
		{
			if(hudSettings[SpeedMax][client] == 0)
			{
				AddMenuItem(menu, "speedmax", "Enable Max Speed");	
			}
			else
			{
				AddMenuItem(menu, "speedmax", "Disable Max Speed");	
			}
		}
		
		if(g_Settings[HUDJumpAccEnable])
		{
			if(hudSettings[JumpAcc][client] == 0)
			{
				AddMenuItem(menu, "jumpacc", "Enable Jump Accuracy");	
			}
			else
			{
				AddMenuItem(menu, "jumpacc", "Disable Jump Accuracy");	
			}
		}
		
		if(g_Settings[HUDSpeclistEnable])
			{
			if(hudSettings[Spec][client] == 0)
			{
				AddMenuItem(menu, "spec", "Enable Spec List[SideHUD]");	
			}
			else
			{
				AddMenuItem(menu, "spec", "Disable Spec List[SideHUD]");	
			}
		}
		
		if(g_Settings[HUDPointsEnable])
			{
			if(hudSettings[Points][client] == 0)
			{
				AddMenuItem(menu, "points", "Enable Points[SideHUD]");	
			}
			else
			{
				AddMenuItem(menu, "points", "Disable Points[SideHUD]");	
			}
		}
		
		if(g_Settings[HUDMapEnable])
		{
			if(hudSettings[Map][client] == 0)
			{
				AddMenuItem(menu, "map", "Enable Map Display [SideHUD]");	
			}
			else
			{
				AddMenuItem(menu, "map", "Disable Map Display [SideHUD]");	
			}
		}
		
		if(g_Settings[HUDStyleEnable])
		{
			if(hudSettings[Mode][client] == 0)
			{
				AddMenuItem(menu, "mode", "Enable Style Display [SideHUD]");	
			}
			else
			{
				AddMenuItem(menu, "mode", "Disable Style Display [SideHUD]");	
			}
		}
		
		if(g_Settings[HUDWREnable])
		{
			if(hudSettings[WR][client] == 0)
			{
				AddMenuItem(menu, "wr", "Enable WR Display [SideHUD]");	
			}
			else
			{
				AddMenuItem(menu, "wr", "Disable WR Display [SideHUD]");	
			}
		}
		
		if(g_Settings[HUDRankEnable])
		{
			if(hudSettings[Rank][client] == 0)
			{
				AddMenuItem(menu, "rank", "Enable Rank Display [SideHUD]");	
			}
			else
			{
				AddMenuItem(menu, "rank", "Disable Rank Display [SideHUD]");	
			}
		}
		
		if(g_Settings[HUDLevelEnable])
		{
			if(hudSettings[Level][client] == 0)
			{
				AddMenuItem(menu, "level", "Enable Level Display [SideHUD]");	
			}
			else
			{
				AddMenuItem(menu, "level", "Disable Level Display [SideHUD]");	
			}
		}
		
		if(g_Settings[HUDPBEnable])
		{
			if(hudSettings[PB][client] == 0)
			{
				AddMenuItem(menu, "pb", "Enable Personal Best [SideHUD]");	
			}
			else
			{
				AddMenuItem(menu, "pb", "Disable Personal Best [SideHUD]");	
			}
		}
		
		if(g_Settings[HUDTTWREnable])
		{
			if(hudSettings[TTWR][client] == 0)
			{
				AddMenuItem(menu, "ttwr", "Enable TTWR Display [SideHUD]");	
			}
			else
			{
				AddMenuItem(menu, "ttwr", "Disable TTWR Display [SideHUD]");	
			}
		}
	
		if(g_Settings[HUDTimeleftEnable])
		{
			if(hudSettings[Timeleft][client] == 0)
			{
				AddMenuItem(menu, "timeleft", "Enable Timeleft Display [SideHUD]");	
			}
			else
			{
				AddMenuItem(menu, "timeleft", "Disable Timeleft Display [SideHUD]");	
			}
		}
		
		if(g_Settings[HUDKeysEnable])
		{
			if(hudSettings[Keys][client] == 0)
			{
				AddMenuItem(menu, "keys", "Enable Keys Display [SideHUD/Spec only]");	
			}
			else
			{
				AddMenuItem(menu, "keys", "Disable Keys Display [SideHUD/Spec only]");	
			}
		}
		
		if(g_Settings[HUDSteamIDEnable])
		{
			if(hudSettings[Steam][client] == 0)
			{
				AddMenuItem(menu, "steam", "Enable Steam [SideHUD/Spec only]");	
			}
			else
			{
				AddMenuItem(menu, "steam", "Disable Steam [SideHUD/Spec only]");	
			}
		}
		
		SetMenuExitButton(menu, true);

		DisplayMenuAtItem(menu, client, start_item, MENU_TIME_FOREVER );
	}
}

//End Custom Cookie and Menu Stuff

public Action:Cmd_HideMyAss(client, args)
{
	if(IsClientConnected(client) && IsClientInGame(client) && Client_IsAdmin(client))
	{
		if(hidemyass[client])
		{
			hidemyass[client] = false;
			PrintToChat(client, "Hide My Ass: Disabled.");
		}
		else
		{
			hidemyass[client] = true;
			PrintToChat(client, "Hide My Ass: Enabled.");
		}
	}
	return Plugin_Handled;	
}

public OnConfigsExecuted()
{
	if(g_cvarTimeLimit != INVALID_HANDLE) HookConVarChange(g_cvarTimeLimit, ConVarChange_TimeLimit);
}

public ConVarChange_TimeLimit(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	RestartMapTimer();
}

stock RestartMapTimer()
{
	//Map Timer
	if(g_hThink_Map != INVALID_HANDLE)
	{
		CloseHandle(g_hThink_Map);
		g_hThink_Map = INVALID_HANDLE;
	}
	
	new bool:gotTimeLeft = GetMapTimeLeft(g_iMap_TimeLeft);
	
	if(gotTimeLeft && g_iMap_TimeLeft > 0)
	{
		g_hThink_Map = CreateTimer(THINK_INTERVAL, Timer_Think_Map, INVALID_HANDLE, TIMER_REPEAT);
	}
}

public Action:Timer_Think_Map(Handle:timer)
{
	g_iMap_TimeLeft--;
	return Plugin_Continue;
}

public OnClientPutInServer(client)
{
	// Initializations and preferences loading
	if(!IsFakeClient(client))
	{
		hudSettings[Master][client] = 1;
		hudSettings[Main][client] = 1;
		hudSettings[Time][client] = 1;
		hudSettings[Jumps][client] = 1;
		hudSettings[Speed][client] = 1;
		hudSettings[SpeedMax][client] = 1;
		hudSettings[JumpAcc][client] = 1;
		hudSettings[Side][client] = 1;
		hudSettings[Map][client] = 1;
		hudSettings[Mode][client] = 1;
		hudSettings[WR][client] = 1;
		hudSettings[Level][client] = 1;
		hudSettings[Rank][client] = 1;
		hudSettings[PB][client] = 1;
		hudSettings[TTWR][client] = 1;
		hudSettings[Keys][client] = 1;
		hudSettings[Spec][client] = 1;
		hudSettings[Steam][client] = 1;
		hudSettings[Points][client] = 1;
		hudSettings[Timeleft][client] = 1;
		
		if (AreClientCookiesCached(client))
		{
			loadClientCookiesFor(client);
		}
	}
	
	if(g_hThink_Map == INVALID_HANDLE && IsServerProcessing())
	{
		RestartMapTimer();
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	g_iButtonsPressed[client] = buttons;
}

public Action:Event_PlayerJump(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	g_iJumps[client]++;
	g_hDelayJump[client] = CreateTimer(0.3, Timer_DelayJumpHud, client, TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Continue;
}

//extends display time of jump keys
public Action:Timer_DelayJumpHud(Handle:timer, any:client)
{
	g_hDelayJump[client] = INVALID_HANDLE;
	return Plugin_Stop;
}

public Action:Event_Reset(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	g_iJumps[client] = 0;
	
	if (g_hDelayJump[client] != INVALID_HANDLE)
	{
		CloseHandle(g_hDelayJump[client]);
		g_hDelayJump[client] = INVALID_HANDLE;
	}
	return Plugin_Continue;
}

public Action:HUDTimer_CSS(Handle:timer)
{
	for (new client = 1; client <= MaxClients; client++)
	{
		spec[client] = false;
	}
	
	for (new client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if(hidemyass[client])
			continue;
		
		// Get target he's spectating
		if(!IsPlayerAlive(client) || IsClientObserver(client))
		{
			new iObserverMode = GetEntProp(client, Prop_Send, "m_iObserverMode");
			if(iObserverMode == SPECMODE_FIRSTPERSON || iObserverMode == SPECMODE_3RDPERSON)
			{
				new clienttoshow = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
				if(clienttoshow > 0)
				{
					spec[clienttoshow] = true;
				}
			}
		}
	}
	
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
			UpdateHUD_CSS(client);
	}

	return Plugin_Continue;
}

UpdateHUD_CSS(client)
{
	if(!IsClientInGame(client))
	{
		return;
	}
	
	if(!hudSettings[Master][client])
	{
		return;
	}
	
	if(!g_Settings[HUDMasterEnable])
	{
		return;
	}
	
	new iClientToShow, iButtons, iObserverMode;

	// Show own buttons by default
	iClientToShow = client;
	
	// Get target he's spectating
	if(!IsPlayerAlive(client) || IsClientObserver(client))
	{
		iObserverMode = GetEntProp(client, Prop_Send, "m_iObserverMode");
		if(iObserverMode == SPECMODE_FIRSTPERSON || iObserverMode == SPECMODE_3RDPERSON)
		{
			iClientToShow = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
			
			// Check client index
			if(iClientToShow <= 0 || iClientToShow > MaxClients)
				return;
		}
		else
		{
			return; // don't proceed, if in freelook..
		}
	}
	
	if(g_timerLjStats && IsClientInLJMode(iClientToShow))
	{
		return;
	}
	
	//start building HUD
	new String:hintText[512]; //HUD buffer	
	new String:centerText[512]; //HUD buffer	
	
	//collect player info
	decl String:auth[32]; //steam ID
	if(!IsFakeClient(iClientToShow)) GetClientAuthString(iClientToShow, auth, sizeof(auth));
	else FormatEx(auth, sizeof(auth), "Replay-Bot");
	
	iButtons = g_iButtonsPressed[iClientToShow]; //buttons pressed

	//collect player stats
	decl String:buffer[32]; //time format buffer
	decl String:bestbuffer[32]; //time format buffer
	new bool:enabled; //tier running
	new Float:bestTime; //best round time
	new bestJumps; //best round jumps
	new jumps; //current jump count
	new fpsmax; //fps settings
	new bool:bonus = false; //bonus timer running
	new Float:time; //current time
	new RecordId;
	new Float:RecordTime;
	new RankTotal;
	
	Timer_GetClientTimer(iClientToShow, enabled, time, jumps, fpsmax);
	
	new style, ranked;	
	if(g_timerPhysics) 
	{
		style = Timer_GetStyle(iClientToShow);	
		ranked = Timer_IsStyleRanked(style);
	}
		
	//get current player level
	new currentLevel = 0;
	if(g_timerMapzones) currentLevel = Timer_GetClientLevelID(iClientToShow);
	if(currentLevel < 1) currentLevel = 1;
	
	//bonuslevel?
	if(currentLevel > 1000) 
	{
		currentLevel -= 1000;
		bonus = true;
	}
	
	//get bhop mode
	if (g_timerPhysics) 
	{
		if(g_timerWorldRecord) Timer_GetStyleRecordWRStats(style, bonus, RecordId, RecordTime, RankTotal);
		//correct fail format
		Timer_SecondsToTime(time, buffer, sizeof(buffer), 0);
	}
	
	//get maptier
	new tier = 1;
	if(g_timerMapTier) tier = Timer_GetTier(bonus);

	//get speed
	new Float:maxspeed;
	if(g_timerPhysics) Timer_GetMaxSpeed(iClientToShow, maxspeed);
	new Float:currentspeed;
	if(g_timerPhysics) Timer_GetCurrentSpeed(iClientToShow, currentspeed);
	new Float:avgspeed;
	if(g_timerPhysics) Timer_GetAvgSpeed(iClientToShow, avgspeed);
	
	if(g_Settings[HUDSpeedUnit] == 1)
	{
		maxspeed *= 0.06858;
		currentspeed *= 0.06858;
		avgspeed *= 0.06858;
	}

	//get jump accuracy
	new Float:accuracy = 0.0;
	if(g_timerPhysics) Timer_GetJumpAccuracy(iClientToShow, accuracy);
	
	if(accuracy > 100.0) accuracy = 100.0;
	else if(accuracy < 0.0) accuracy = 0.0;
	
	if(ranked) 
	{
		if(g_timerWorldRecord) Timer_GetBestRound(iClientToShow, style, bonus, bestTime, bestJumps);
		Timer_SecondsToTime(bestTime, bestbuffer, sizeof(bestbuffer), 2);
	}
	
	//has client a mate?
	new mate = 0; //challenge mode
	if (g_timerMapzones) mate = Timer_GetClientTeammate(iClientToShow);
	
	new points;
	if(g_timerRankings) points = Timer_GetPoints(iClientToShow);
	new points100 = points;
	if(g_Settings[HUDUseMVPStars] > 0) points100 = RoundToFloor((points*1.0)/g_Settings[HUDUseMVPStars]);

	new rank;
	
	if(ranked && g_timerWorldRecord) 
	{
		//get rank
		rank = Timer_GetStyleRank(iClientToShow, bonus, style);	
	}
	
	new prank;
	if(g_timerRankings)  prank = Timer_GetPointRank(iClientToShow);
	
	if(prank > 2000 || prank < 1) prank = 2000;
	
	new nprank = (prank * -1);
	
	new String:sRankTotal[32];
	Format(sRankTotal, sizeof(sRankTotal), "%d", RankTotal);
	
	if(RankTotal >= MAX_CACHE) 
		Format(sRankTotal, sizeof(sRankTotal), "%s+", sRankTotal);
	
	if(client == iClientToShow)
	{
		if(g_Settings[HUDUseMVPStars] > 0 && points100 > 0)
		{
			CS_SetMVPCount(iClientToShow, points100);
		}
		if(g_Settings[HUDUseFragPointsRank])
		{
			SetEntProp(client, Prop_Data, "m_iFrags", nprank);
		}
		if(g_Settings[HUDUseDeathRank])
		{
			Client_SetDeaths(client, rank);
		}
		
		if(g_Settings[HUDUseClanTag] && !IsFakeClient(client))
		{
			decl String:tagbuffer[32];
			if(g_Settings[HUDUseClanTagTime])
			{
				if(enabled) FormatEx(tagbuffer, sizeof(tagbuffer), "%s", buffer);
				else if (ranked) FormatEx(tagbuffer, sizeof(tagbuffer), "%s", bestbuffer);
			}
			
			if(g_Settings[HUDUseClanTagTime] && g_Settings[MultimodeEnable] && g_Settings[HUDUseClanTagStyle])
				Format(tagbuffer, sizeof(tagbuffer), " %s", tagbuffer);
			
			if(g_Settings[MultimodeEnable] && g_Settings[HUDUseClanTagStyle])
			{
				if(!enabled && !ranked)
				{
					Format(tagbuffer, sizeof(tagbuffer), "%s%s", g_Physics[style][StyleTagName], tagbuffer);
				}
				else
				{
					Format(tagbuffer, sizeof(tagbuffer), "%s%s", g_Physics[style][StyleTagShortName], tagbuffer);
				}
			}
			
			CS_SetClientClanTag(client, tagbuffer);
		}
	}
	
	//start format center HUD
	
	new stagecount;
	
	if(g_timerMapzones)
	{
		if(bonus)
		{
			stagecount = Timer_GetMapzoneCount(ZtBonusLevel)+1;
		}
		else
		{
			stagecount = Timer_GetMapzoneCount(ZtLevel)+1;
		}
	}
	
	if (enabled)
	{
		decl String:timeString[64];
		Timer_SecondsToTime(time, timeString, sizeof(timeString), 1);
		
		if(StrEqual(timeString, "00:-0.0")) FormatEx(timeString, sizeof(timeString), "00:00.0");
		
		if (hudSettings[Time][client])
			Format(centerText, sizeof(centerText), "%sTime: %s\n", centerText, timeString);
			//Format(centerText, sizeof(centerText), "%s%t: %s\n", centerText, "Time", timeString);
		
		if ((hudSettings[Jumps][client] && g_Settings[HUDJumpsEnable]) && (hudSettings[JumpAcc][client] && g_Settings[HUDJumpAccEnable]) && !g_Physics[style][StyleAuto])
			Format(centerText, sizeof(centerText), "%s%t: %d [%.2f %%]\n", centerText, "Jumps", jumps, accuracy);
		else if (hudSettings[Jumps][client] && g_Settings[HUDJumpsEnable])
			Format(centerText, sizeof(centerText), "%s%t: %d\n", centerText, "Jumps", jumps);
	}
	
	if(!enabled)
	{
		if (hudSettings[Speed][client])
		{
			Format(centerText, sizeof(centerText), "%s%t: %d", centerText, "HUD Speed", RoundToFloor(currentspeed));
			if(g_Settings[HUDSpeedUnit] == 1)
			{
				Format(centerText, sizeof(centerText), "%s km/h", centerText);
			}
		}
	}
	else 
	{
		if (hudSettings[Speed][client] && hudSettings[SpeedMax][client])
			//Format(centerText, sizeof(centerText), "%s%t: %5.2f [max:%5.2f|avg:%5.2f]", centerText, "HUD Speed", currentspeed, maxspeed, avgspeed);
			Format(centerText, sizeof(centerText), "%s%t: %d", centerText, "HUD Speed", RoundToFloor(currentspeed));
		if (hudSettings[Speed][client] && !hudSettings[SpeedMax][client])
			Format(centerText, sizeof(centerText), "%s%t: %d", centerText, "HUD Speed", RoundToFloor(currentspeed));
	}
	
	if (g_Settings[HUDCenterEnable] && hudSettings[Main][client])
	{
		if(!IsVoteInProgress())
		{
			if(Timer_IsPlayerTouchingZoneType(client, ZtStart))
				PrintHintText(client, "In Start Zone");
			else if(Timer_IsPlayerTouchingZoneType(client, ZtBonusStart))
				PrintHintText(client, "In Bonus Start Zone");
			else PrintHintText(client, centerText);
		}
	}
	
	//PrintCenterText(client, centerText);
	
	//start format side HUD
	
	
	if (iClientToShow != client && (iObserverMode == SPECMODE_FIRSTPERSON || iObserverMode == SPECMODE_3RDPERSON))
	{
		//Format(hintText, sizeof(hintText), "%sName: %s%N\n", hintText,  client_tag, iClientToShow);
		if (hudSettings[Steam][client] && g_Settings[HUDSteamIDEnable])
			Format(hintText, sizeof(hintText), "%sSteamID: %s\n", hintText, auth);
	}
	
	if (hudSettings[Points][client] && g_Settings[HUDPointsEnable])
		Format(hintText, sizeof(hintText), "%sPoints: %d\n", hintText, points);
	
	if(0 < mate && IsClientInGame(mate))
	{
		Format(hintText, sizeof(hintText), "%sTeammate: %N\n", hintText, mate);
	}
	
	//Format(hintText, sizeof(hintText), "%s %s - %t: %d/5\n", hintText, "Tier", g_currentMap, tier);
	if (hudSettings[Map][client] && g_Settings[HUDMapEnable])
		Format(hintText, sizeof(hintText), "%s%s (Tier %d)\n", hintText, g_currentMap, tier);
	
	new String:RecordTimeString[32];
	new String:DiffTimeString[32];

	new bool:negate = false;
		
	if(ranked)
	{
		
		Timer_SecondsToTime(RecordTime, RecordTimeString, sizeof(RecordTimeString), 2);
		
		if(time-RecordTime >= 0)
		{
			Timer_SecondsToTime(time-RecordTime, DiffTimeString, sizeof(DiffTimeString), 2);
		}
		else
		{
			negate = true;
			Timer_SecondsToTime(RecordTime-time, DiffTimeString, sizeof(DiffTimeString), 2);
		}
		
		
		//correct fail format
		if(StrEqual(RecordTimeString, "00:-0.00")) FormatEx(RecordTimeString, sizeof(RecordTimeString), "00:00.00");
		if(StrEqual(RecordTimeString, "00:00.-0")) FormatEx(RecordTimeString, sizeof(RecordTimeString), "00:00.00");
	}
	
	if (g_timerPhysics && g_Settings[MultimodeEnable]) 
	{	
		if (hudSettings[Mode][client] && g_Settings[HUDStyleEnable])
			Format(hintText, sizeof(hintText), "%sStyle: %s\n", hintText, g_Physics[style][StyleName]);
	}
	
	if(ranked)
	{
		if (hudSettings[WR][client] && g_Settings[HUDWREnable])
			Format(hintText, sizeof(hintText), "%sWorld Record: %s\n", hintText, RecordTimeString);
		if (hudSettings[WR][client] || hudSettings[Mode][client] || hudSettings[Map][client])
			Format(hintText, sizeof(hintText), "%s\n", hintText);
		//Format(hintText, sizeof(hintText), "%s\n%N:\n", hintText, iClientToShow);
	}
	
	if (hudSettings[Level][client] && g_Settings[HUDLevelEnable])
	{
		if(stagecount <= 1)
		{
			if(bonus) 
			{
				Format(hintText, sizeof(hintText), "%sBonus-Stage: Linear\n", hintText);
			}
			else
			{
				Format(hintText, sizeof(hintText), "%sStage: Linear\n", hintText);
			}
		}
		else if(bonus) 
		{
			if(currentLevel == 999)
				Format(hintText, sizeof(hintText), "%sBonus-Stage: End/%d\n", hintText, stagecount);
			else
				Format(hintText, sizeof(hintText), "%sBonus-Stage: %d/%d\n", hintText, currentLevel, stagecount);
		}
		else
		{
			if(currentLevel == 999)
				Format(hintText, sizeof(hintText), "%sStage: End/%d\n", hintText, stagecount);
			else
				Format(hintText, sizeof(hintText), "%sStage: %d/%d\n", hintText, currentLevel, stagecount);
		}
	}
	
	if(ranked)
	{
		if (hudSettings[Rank][client] && g_Settings[HUDRankEnable])
		{
			if(rank < 1)
				Format(hintText, sizeof(hintText), "%sRank: -/%s\n", hintText, sRankTotal);
			else
				Format(hintText, sizeof(hintText), "%sRank: %d/%s\n", hintText, rank, sRankTotal);
		}
		
		if (hudSettings[PB][client] && g_Settings[HUDPBEnable])
			Format(hintText, sizeof(hintText), "%sBest Time: %s\n", hintText, bestbuffer, bestJumps);
		
		if (hudSettings[TTWR][client] && g_Settings[HUDTTWREnable])
		{
			if(RecordTime > 0 && time > 0)
			{
				if(!negate)
					Format(hintText, sizeof(hintText), "%sTime2WR: +%s\n", hintText, DiffTimeString);
				else
					Format(hintText, sizeof(hintText), "%sTime2WR: -%s\n", hintText, DiffTimeString);
			}
			else Format(hintText, sizeof(hintText), "%sTime2WR: 00:00.00\n", hintText);
		}
	}
	
	if(hudSettings[Timeleft][client] && g_Settings[HUDTimeleftEnable]) 
	{
		if(g_iMap_TimeLeft > 0)
		{
			Format(hintText,sizeof(hintText),"%sTimeleft: %d:%02d\n", hintText, g_iMap_TimeLeft/60, g_iMap_TimeLeft%60);
		}
		else Format(hintText,sizeof(hintText),"%sTimeleft: %d:%02d\n", hintText, (RoundToFloor(g_iMap_TimeLeft*-1.0))/60, (RoundToFloor(g_iMap_TimeLeft*-1.0))%60);
	}
	
	//speclist
	if (hudSettings[Spec][client] && g_Settings[HUDSpeclistEnable])
	{
		new iSpecCount;
		
		for(new j = 1; j <= MaxClients; j++) 
		{
			if (!IsClientInGame(j) || !IsClientObserver(j))
				continue;
			
			if (IsClientSourceTV(j))
				continue;
				
			new iSpecMode = GetEntProp(j, Prop_Send, "m_iObserverMode");
			
			// The client isn't spectating any one person, so ignore them.
			if (iSpecMode != SPECMODE_FIRSTPERSON && iSpecMode != SPECMODE_3RDPERSON)
				continue;
			
			// Find out who the client is spectating.
			new iTarget = GetEntPropEnt(j, Prop_Send, "m_hObserverTarget");
			
			// Are they spectating the same player as User?
			if (iTarget == iClientToShow && j != iClientToShow && !hidemyass[j])
				iSpecCount++;
		}
		
		if(iSpecCount > 0)
		{
			Format(hintText, sizeof(hintText), "%sSpectators: %d\n\n", hintText, iSpecCount);
		}
	}
	
	if (hudSettings[Keys][client] && g_Settings[HUDKeysEnable])
	{
		//if client is spectating show player keys
		if (iClientToShow != client && (iObserverMode == SPECMODE_FIRSTPERSON || iObserverMode == SPECMODE_3RDPERSON))
		{
			Format(hintText, sizeof(hintText), "%s_______Keys_______\n\n", hintText);
			
			//dealing with keys pressed
			
			// Is he pressing "w"?
			if(iButtons & IN_FORWARD)
				Format(hintText, sizeof(hintText), "%sW;", hintText);
			// Is he pressing "a"?
			if(iButtons & IN_MOVELEFT)
				Format(hintText, sizeof(hintText), "%sA;", hintText);
			// Is he pressing "s"?
			if(iButtons & IN_BACK)
				Format(hintText, sizeof(hintText), "%sS;", hintText);
			// Is he pressing "d"?
			if(iButtons & IN_MOVERIGHT)
				Format(hintText, sizeof(hintText), "%sD;", hintText);
			// Is he pressing "+left"?
			if(iButtons & IN_LEFT)
				Format(hintText, sizeof(hintText), "%s+L;", hintText);
			// Is he pressing "+right"?
			if(iButtons & IN_RIGHT)
				Format(hintText, sizeof(hintText), "%s+R;", hintText);
				
			// Is he pressing "space"?
			if(iButtons & IN_JUMP || g_hDelayJump[iClientToShow] != INVALID_HANDLE)
				Format(hintText, sizeof(hintText), "%sJP;", hintText);
			
			// Is he pressing "ctrl"?
			if(iButtons & IN_DUCK)
				Format(hintText, sizeof(hintText), "%sDK;", hintText);
				
			// Is he pressing "shift"?
			if(iButtons & IN_SPEED)
				Format(hintText, sizeof(hintText), "%sWALK;", hintText);
				
			// Is he pressing "e"?
			if(iButtons & IN_USE)
				Format(hintText, sizeof(hintText), "%sU;", hintText);
				
			// Is he pressing "mouse1"?
			if(iButtons & IN_ATTACK)
				Format(hintText, sizeof(hintText), "%sM1;", hintText);
			
			// Is he pressing "mouse1"?
			if(iButtons & IN_ATTACK2)
				Format(hintText, sizeof(hintText), "%sM2;", hintText);
			
			// Is he pressing "tab"?
			if(iButtons & IN_SCORE)
				Format(hintText, sizeof(hintText), "%sTAB;", hintText);
		}
	
		//if player has a mate show keys pressed by players mate
		
		if(0 < mate && IsClientInGame(mate))
		{
			new mbuttons = g_iButtonsPressed[mate];
		
			Format(hintText, sizeof(hintText), "%s\n____Keys-Mate_____\n\n", hintText);

			// Is he pressing "w"?
			if(mbuttons & IN_FORWARD)
				Format(hintText, sizeof(hintText), "%sW;", hintText);
			// Is he pressing "a"?
			if(mbuttons & IN_MOVELEFT)
				Format(hintText, sizeof(hintText), "%sA;", hintText);
			// Is he pressing "s"?
			if(mbuttons & IN_BACK)
				Format(hintText, sizeof(hintText), "%sS;", hintText);
			// Is he pressing "d"?
			if(mbuttons & IN_MOVERIGHT)
				Format(hintText, sizeof(hintText), "%sD;", hintText);
			// Is he pressing "+left"?
			if(mbuttons & IN_LEFT)
				Format(hintText, sizeof(hintText), "%s+L;", hintText);
			// Is he pressing "+right"?
			if(mbuttons & IN_RIGHT)
				Format(hintText, sizeof(hintText), "%s+R;", hintText);
				
			// Is he pressing "space"?
			if(mbuttons & IN_JUMP || g_hDelayJump[mate] != INVALID_HANDLE)
				Format(hintText, sizeof(hintText), "%sJP;", hintText);
			
			// Is he pressing "ctrl"?
			if(mbuttons & IN_DUCK)
				Format(hintText, sizeof(hintText), "%sDK;", hintText);
				
			// Is he pressing "shift"?
			if(mbuttons & IN_SPEED)
				Format(hintText, sizeof(hintText), "%sWALK;", hintText);
				
			// Is he pressing "e"?
			if(mbuttons & IN_USE)
				Format(hintText, sizeof(hintText), "%sU;", hintText);
			
			// Is he pressing "tab"?
			if(mbuttons & IN_SCORE)
				Format(hintText, sizeof(hintText), "%sTAB;", hintText);
				
			// Is he pressing "mouse1"?
			if(mbuttons & IN_ATTACK)
				Format(hintText, sizeof(hintText), "%sM1;", hintText);
			
			// Is he pressing "mouse1"?
			if(mbuttons & IN_ATTACK2)
				Format(hintText, sizeof(hintText), "%sM2;", hintText);
		}
	}
	
	//Print as his Text
	if (hudSettings[Side][client] && g_Settings[HUDSideEnable])
	{
		Client_PrintKeyHintText(client, hintText);
	}
	
	//stop confusing hint sound
	StopSound(client, SNDCHAN_STATIC, "UI/hint.wav");
}

public Action:Cmd_SpecInfo(client, args)
{
	new owner = client;
	if(!IsPlayerAlive(client) || IsClientObserver(client))
	{
		new iObserverMode = GetEntProp(client, Prop_Send, "m_iObserverMode");
		if(iObserverMode == SPECMODE_FIRSTPERSON || iObserverMode == SPECMODE_3RDPERSON)
		{
			new iTarget = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
			if(iTarget > 0)
			{
				Print_Specinfo(iTarget, owner);
			}
		}
	}
	else
	{
		Print_Specinfo(client, owner);
	}
	
	return Plugin_Handled;	
}

Print_Specinfo(client, owner)
{
	new String:buffer[1024];
	
	new spec_count = GetSpecCount(client);
	new count = 0;
	
	for(new j = 1; j <= MaxClients; j++) 
	{
		if (!IsClientInGame(j) || !IsClientObserver(j))
			continue;
		
		if (IsClientSourceTV(j))
			continue;
			
		new iSpecMode = GetEntProp(j, Prop_Send, "m_iObserverMode");
		
		// The client isn't spectating any one person, so ignore them.
		if (iSpecMode != SPECMODE_FIRSTPERSON && iSpecMode != SPECMODE_3RDPERSON)
			continue;
		
		// Find out who the client is spectating.
		new iTarget = GetEntPropEnt(j, Prop_Send, "m_hObserverTarget");
		
		// Are they spectating the same player as User?
		if (iTarget == client && j != client && !hidemyass[j])
		{
			count++;
			if(spec_count == count)
			{
				Format(buffer, sizeof(buffer), "%s %N", buffer, j);
			}
			else 
			{
				Format(buffer, sizeof(buffer), "%s %N,", buffer, j);
			}
		}
	}
	
	CPrintToChat(owner, "%s {red}%N {olive}has {red}%d {olive}spectators:{red}%s.", PLUGIN_PREFIX2, client, count, buffer);
}

stock GetSpecCount(client)
{
	new count = 0;
	
	for(new j = 1; j <= MaxClients; j++) 
	{
		if (!IsClientInGame(j) || !IsClientObserver(j))
			continue;
		
		if (IsClientSourceTV(j))
			continue;
			
		new iSpecMode = GetEntProp(j, Prop_Send, "m_iObserverMode");
		
		// The client isn't spectating any one person, so ignore them.
		if (iSpecMode != SPECMODE_FIRSTPERSON && iSpecMode != SPECMODE_3RDPERSON)
			continue;
		
		// Find out who the client is spectating.
		new iTarget = GetEntPropEnt(j, Prop_Send, "m_hObserverTarget");
		
		// Are they spectating the same player as User?
		if (iTarget == client && j != client && !hidemyass[j])
		{
			count++;
		}
	}
	
	return count;
}