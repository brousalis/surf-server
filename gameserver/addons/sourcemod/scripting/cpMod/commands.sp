/**
 *
 * =============================================================================
 *
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative 1works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt,
 * or <http://www.sourcemod.net/license.php>.
 *
 *
 */

//----------------------//
// some client commands //
//----------------------//

public Action:Client_Next(client, args)
{
	TeleClient(client,1);
	return Plugin_Handled;
}

public Action:Client_Prev(client, args)
{
	TeleClient(client,-1);
	return Plugin_Handled;
}

public Action:Client_Save(client, args)
{
	SaveClientLocation(client);
	return Plugin_Handled;
}

public Action:Client_Tele(client, args)
{
	TeleClient(client,0);
	return Plugin_Handled;
}

public Action:Client_Cp(client, args)
{
	TeleMenu(client);
	return Plugin_Handled;
}

public Action:Client_Clear(client, args)
{
	ClearClient(client);
	return Plugin_Handled;
}

public Action:Client_Help(client, args)
{
	HelpPanel(client);
	return Plugin_Handled;
}

//-----------------------------//
// save player location method //
//-----------------------------//
public SaveClientLocation(client)
{
	//if no valid player
	if(!IsPlayerAlive(client) || GetClientTeam(client) == 1)
		return;
	
	//if plugin is enabled
	if(g_bEnabled)
	{
		//if player on ground
		if(GetEntDataEnt2(client, FindSendPropOffs("CBasePlayer", "m_hGroundEntity")) != -1 || g_bAir)
		{
			new whole = g_WholeCp[client];
			
			//if player has less than limit checkpoints
			if(whole < CPLIMIT)
			{
				//save some data
				GetClientAbsOrigin(client, g_fPlayerCords[client][whole]);
				GetClientAbsAngles(client, g_fPlayerAngles[client][whole]);
				GetEntPropVector(client, Prop_Data, "m_vecVelocity", g_fPlayerVelocity[client][whole]);
				
				g_iPlayerLevel[client][whole] = Timer_GetClientLevel(client);
				
				//increase counters
				g_CurrentCp[client] = g_WholeCp[client];
				g_WholeCp[client]++;
				
				PrintToChat(client, "%t", "CpSaved", YELLOW,LIGHTGREEN,YELLOW,GREEN,whole+1,whole+1,YELLOW);
				
				if(g_bEffects) 
				{
					EmitSoundToClient(client,"buttons/blip1.wav",client);
					TE_SetupBeamRingPoint(g_fPlayerCords[client][whole],10.0,200.0,g_BeamSpriteRing1,0,0,10,1.0,50.0,0.0,{255,255,255,255},0,0);
					TE_SendToClient(client);
				}
			}
			else if(whole == CPLIMIT)
			{ //cp rotation enabled
				new current = g_CurrentCp[client];
				
				//if last slot reached
				if(current+1 == CPLIMIT)
				{
					//reset to first slot
					g_CurrentCp[client] = 0;
					current = 0;
				}
				else
				{
					g_CurrentCp[client]++;
					current++;
				}
				
				//save some data
				GetClientAbsOrigin(client,g_fPlayerCords[client][current]);
				GetClientAbsAngles(client,g_fPlayerAngles[client][current]);
				GetEntPropVector(client, Prop_Data, "m_vecVelocity", g_fPlayerVelocity[client][current]);
				
				g_iPlayerLevel[client][current] = Timer_GetClientLevel(client);
				PrintToChat(client, "%t", "CpSaved", YELLOW,LIGHTGREEN,YELLOW,GREEN,current+1,whole,YELLOW);
				
				if(g_bEffects) 
				{
					EmitSoundToClient(client,"buttons/blip1.wav",client);
					TE_SetupBeamRingPoint(g_fPlayerCords[client][current],10.0,200.0,g_BeamSpriteRing1,0,0,10,1.0,50.0,0.0,{255,255,255,255},0,0);
					TE_SendToClient(client);
				}
			}
			else //checkpoint limit
				PrintToChat(client, "%t", "CpLimit", YELLOW,LIGHTGREEN,YELLOW,GREEN,YELLOW);
		}
		else //not on ground
			PrintToChat(client, "%t", "NotOnGround", YELLOW,LIGHTGREEN,YELLOW);
	}
	else //disabled
		PrintToChat(client, "%t", "PluginDisabled", YELLOW,LIGHTGREEN,YELLOW);
}

//---------------------//
// tele player method //
//--------------------//
public TeleClient(client,pos)
{
	//if no valid player
	if(!IsPlayerAlive(client) || GetClientTeam(client) == 1)
		return;
	
	if(g_timerTeams)
	{
		if(Timer_GetCoopStatus(client) == 0 && Timer_GetChallengeStatus(client) == 0)
			Client_TelePos(client, pos);
		else ConfirmAbortMenu(client, pos);
	}
	else Client_TelePos(client, pos);
}

public Client_TelePos(client, pos)
{
	//if no valid player
	if(!IsPlayerAlive(client) || GetClientTeam(client) == 1)
		return;
	
	//if plugin is enabled
	if(g_bEnabled)
	{
		if(g_timer) Timer_Reset(client);
		
		new current = g_CurrentCp[client];
		new whole = g_WholeCp[client];
		
		//if on last slot and next
		if(current == whole-1 && pos == 1)
		{
			//reset to first
			g_CurrentCp[client] = -1;
			current = -1;
		}
		//if on first slot and previous
		if(current == 0  && pos == -1)
		{
			//reset to last
			g_CurrentCp[client] = whole;
			current = whole;
		}
		
		new actual = current+pos;
		
		//if not valid checkpoint
		//if(actual < 0 || actual > whole || (g_fPlayerCords[client][actual][0] == 0.0 && g_fPlayerCords[client][actual][1] == 0.0 && g_fPlayerCords[client][actual][2] == 0.0)){
		if(actual < 0 || actual > whole)
		{
			PrintToChat(client, "%t", "CpNotFound", YELLOW,LIGHTGREEN,YELLOW);
		}
		else
		{ 
			if(g_timerMapzones)
			{
				if(Timer_IsPlayerTouchingZoneType(client, ZtStart) || Timer_IsPlayerTouchingZoneType(client, ZtBonusStart)) 
					Timer_SetIgnoreEndTouchStart(client, 1);
			}
			
			if(g_bVelocity)
				TeleportEntity(client, g_fPlayerCords[client][actual], g_fPlayerAngles[client][actual], g_fPlayerVelocity[client][actual]);
			else TeleportEntity(client, g_fPlayerCords[client][actual], g_fPlayerAngles[client][actual], Float:{0.0,0.0,-100.0});//stop him
			PrintToChat(client, "%t", "CpTeleported", YELLOW,LIGHTGREEN,YELLOW,GREEN,actual+1,whole,YELLOW);
			g_CurrentCp[client] += pos;
			
			if(g_bEffects) 
			{
				EmitSoundToClient(client,"buttons/blip1.wav",client);
				TE_SetupBeamRingPoint(g_fPlayerCords[client][actual],10.0,200.0,g_BeamSpriteRing2,0,0,10,1.0,50.0,0.0,{255,255,255,255},0,0);
				TE_SendToClient(client);
			}
			
			Timer_SetClientLevel(client, g_iPlayerLevel[client][actual]);
		}
	}
	else //plugin disabled
		PrintToChat(client, "%t", "PluginDisabled", YELLOW,LIGHTGREEN,YELLOW);
}

ConfirmAbortMenu(client, pos)
{
	if (0 < client < MaxClients)
	{
		new Handle:menu = CreateMenu(Handle_ConfirmAbortMenu);
		
		if(Timer_GetChallengeStatus(client) == 1)
			SetMenuTitle(menu, "Are you sure to quit the Challenge?");
		else if(Timer_GetCoopStatus(client) == 1)
			SetMenuTitle(menu, "Are you sure to quit the Coop?");
		
		new String:buffer[32];
		Format(buffer, sizeof(buffer), "%d", pos);
		AddMenuItem(menu, buffer, "Yes");
		AddMenuItem(menu, "no", "No");
		
		DisplayMenu(menu, client, 5);
	}
}
	
public Handle_ConfirmAbortMenu(Handle:menu, MenuAction:action, client, itemNum)
{
	if ( action == MenuAction_Select )
	{
		decl String:info[100], String:info2[100];
		new bool:found = GetMenuItem(menu, itemNum, info, sizeof(info), _, info2, sizeof(info2));
		if(found)
		{
			if(StrEqual(info, "no"))
			{
				
			}
			else
			{
				Client_TelePos(client, StringToInt(info));
			}
		}
	}
}

//------------------//
// tele menu method //
//------------------//
public TeleMenu(client)
{
	//if no valid player
	if(!IsPlayerAlive(client) || GetClientTeam(client) == 1)
		return;
	
	//if plugin is enabled
	if(g_bEnabled){
		//create panel
		new Handle:menu = CreateMenu(TeleMenuHandler);
		SetMenuTitle(menu, "[Checkpoint System]");
		AddMenuItem(menu, "!save", "Saves a location");
		AddMenuItem(menu, "!tele", "Teleports you to last checkpoint");
		AddMenuItem(menu, "!next", "Next checkpoint");
		AddMenuItem(menu, "!prev", "Previous checkpoint");
		AddMenuItem(menu, "!clear", "Erase all checkpoints");
		SetMenuExitButton(menu, true);
		SetMenuOptionFlags(menu, MENUFLAG_BUTTON_EXIT);
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
	else //plugin disabled
		PrintToChat(client, "%t", "PluginDisabled", YELLOW,LIGHTGREEN,YELLOW);
}
//---------//
// handler //
//---------//
public TeleMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		switch(param2){
			case 0: SaveClientLocation(param1);
			case 1: TeleClient(param1,0);
			case 2: TeleClient(param1,1);
			case 3: TeleClient(param1,-1);
			case 4: ClearClient(param1);
		}
		TeleMenu(param1);
	}else if(action == MenuAction_End)
		CloseHandle(menu);
}

//---------------------//
// clear player method //
//---------------------//
public ClearClient(client)
{
	//if no valid player
	if(!IsPlayerAlive(client) || GetClientTeam(client) == 1)
		return;
	
	//if plugin is enabled
	if(g_bEnabled)
	{
		//reset counters
		g_CurrentCp[client] = -1;
		g_WholeCp[client] = 0;
		
		PrintToChat(client, "%t", "Cleared", YELLOW,LIGHTGREEN,YELLOW);
	}else //plugin disabled
		PrintToChat(client, "%t", "PluginDisabled", YELLOW,LIGHTGREEN,YELLOW);
}

//-------------------//
// help panel method //
//-------------------//
public HelpPanel(client)
{
	//create panel
	new Handle:panel = CreatePanel();
	DrawPanelText(panel, "[Checkpoint System]");
	DrawPanelText(panel, " ");
	DrawPanelText(panel, "!cphelp - Displays this menu");
	DrawPanelText(panel, "!cp - Opens teleportmenu");
	DrawPanelText(panel, " ");
	DrawPanelText(panel, "!clear - Erase all checkpoints");
	DrawPanelText(panel, "!next - Next checkpoint");
	DrawPanelText(panel, "!prev - Previous checkpoint");
	DrawPanelText(panel, "!save - Saves a checkpoint");
	DrawPanelText(panel, "!tele - Teleports you to last checkpoint");
	DrawPanelItem(panel, "exit");
	SendPanelToClient(panel, client, HelpPanelHandler, 10);
	CloseHandle(panel);
}
//---------//
// handler //
//---------//
public HelpPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
}
