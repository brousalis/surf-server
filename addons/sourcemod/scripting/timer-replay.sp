#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <smlib>
#include <setname>
#include <timer>
#include <timer-mapzones>
#include <timer-worldrecord>
#include <timer-stocks>
#include <timer-config_loader.sp>

new Handle:g_hRecords;
new Handle:hData = INVALID_HANDLE;

new g_iPlayerRecords[MAXPLAYERS+1] = {-1,...};
new g_iRecordedTicks[MAXPLAYERS+1] = {0,...};
new g_iRecordPreviousWeapon[MAXPLAYERS+1] = {-1,...};

new g_iNextBotMimicsThis = -1;

new g_iBotMimicsRecord[MAXPLAYERS+1] = {-1,...};
new g_iBotMimicTick[MAXPLAYERS+1] = {-1,...};

public Plugin:myinfo = 
{
	name 		= "[Timer] Reply Bot",
	author 		= "Zipcore, Jason Bourne",
	description = "[Timer] Replay BOT (alpha)",
	version 	= PL_VERSION,
	url 		= "forums.alliedmods.net/showthread.php?p=2074699"
}

public OnPluginStart()
{
	g_hRecords = CreateArray();
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	HookEvent("player_death", Event_OnPlayerDeath);
	LoadPhysics();
	LoadTimerSettings();
}

public OnMapStart()
{
	// Clear record array
	new iSize = GetArraySize(g_hRecords);

	for(new i=0;i<iSize;i++)
	{
		CloseHandle(GetArrayCell(g_hRecords, i));
	}
	
	ClearArray(g_hRecords);
	
	ServerCommand("bot_quota 0");
	LoadReplays();
	LoadPhysics();
	LoadTimerSettings();
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
	if(IsFakeClient(client) && g_iNextBotMimicsThis != -1)
	{
		g_iBotMimicsRecord[client] = 0;
		g_iBotMimicTick[client] = 0;
	}
	
	return true;
}

public OnClientPutInServer(client)
{
	if(g_iBotMimicsRecord[client] != -1)
	{
		CreateTimer(1.0, Timer_DelayedRespawn, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public OnClientDisconnect(client)
{
	StopRecording(client);
	g_iBotMimicsRecord[client] = -1;
	g_iBotMimicTick[client] = 0;
}

public OnClientStartTouchZoneType(client, MapZoneType:type)
{
	if(client != 0)
	{
		if (type == ZtStart)
		{
			StopRecording(client);
		}
	}
}

public OnClientEndTouchZoneType(client, MapZoneType:type)
{
	if(client != 0)
	{
		if (type == ZtStart && g_iPlayerRecords[client] == -1 && g_iBotMimicsRecord[client] == -1)
		{
			StopRecording(client);
			
			new Handle:xData = CreateArray(ByteCountToCells(15));
			g_iPlayerRecords[client] = PushArrayCell(g_hRecords, xData);
		}
	}
}

public OnTimerWorldRecord(client, track, style, Float:time, Float:lasttime, currentrank, newrank)
{
	if(client != 0)
	{
		if (style == g_StyleDefault && track == 0)
		{
			CreateTimer(0.0, SaveRecording, client);
		}
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon, &subtype, &cmdnum, &tickcount, &seed, mouse[2])
{
	// He's recording his movements!
	if(g_iPlayerRecords[client] != -1)
	{
		if(!IsPlayerAlive(client) || GetClientTeam(client) < CS_TEAM_T)
		{
			StopRecording(client);
			Timer_LogError("Replay stopped something went wrong.");
			return Plugin_Continue;
		}
		
		new Handle:xData = GetArrayCell(g_hRecords, g_iPlayerRecords[client]);
		PushArrayCell(xData, buttons);
		PushArrayCell(xData, impulse);
		new Float:fVel[3];
		fVel[0] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
		fVel[1] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
		fVel[2] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]");
		PushArrayArray(xData, fVel, 3);
		PushArrayArray(xData, vel, 3);
		PushArrayArray(xData, angles, 3);
		
		// Did he change his weapon?
		if(weapon)
		{
			// Save it
			if(IsValidEntity(weapon) && IsValidEdict(weapon))
			{
				new String:sClassName[64];
				GetEdictClassname(weapon, sClassName, sizeof(sClassName));
				PushArrayString(xData, sClassName[7]);
				g_iRecordPreviousWeapon[client] = weapon;
			}
		}
		else
		{
			decl String:sClassName[64];
			new iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			
			// Save the weapon he started recording with or just picked up forcefully.
			if((g_iRecordedTicks[client] == 0 || g_iRecordPreviousWeapon[client] != iWeapon) && iWeapon != -1 && IsValidEdict(iWeapon))
			{
				GetEdictClassname(iWeapon, sClassName, sizeof(sClassName));
				PushArrayString(xData, sClassName[7]);
			}
			else
			{
				PushArrayString(xData, "\0");
			}
			
			g_iRecordPreviousWeapon[client] = iWeapon;
		}
		
		// Save the current client position intitially in the first frame once
		if(g_iRecordedTicks[client] == 0)
		{
			new Float:fOrigin[3];
			GetClientAbsOrigin(client, fOrigin);
			PushArrayArray(xData, fOrigin, 3);
		}
		
		g_iRecordedTicks[client]++;
		
		return Plugin_Continue;
	}
	// This bot is playing a record
	else if(g_iBotMimicsRecord[client] != -1)
	{
		if(!IsFakeClient(client) || !IsPlayerAlive(client) || GetClientTeam(client) < CS_TEAM_T)
			return Plugin_Continue;
				
		new iIndex = g_iBotMimicTick[client] * 6;
		if(g_iBotMimicTick[client] > 0)
			iIndex++;
		
		buttons = GetArrayCell(hData, iIndex);
		impulse = GetArrayCell(hData, ++iIndex);
		new Float:fVel[3];
		GetArrayArray(hData, ++iIndex, fVel, 3);
		GetArrayArray(hData, ++iIndex, vel, 3);
		GetArrayArray(hData, ++iIndex, angles, 3);
		
		// This is the first frame - teleport him to the correct position
		if(g_iBotMimicTick[client] == 0)
		{
			
			new String:name[128];
			Timer_GetRecordHolderName(g_StyleDefault, 0, 1, name, 128);
			
			new cacheid, total;
			new Float:time;
			new String:timestring[32];
			
			Timer_GetStyleRecordTime(g_StyleDefault, 0, cacheid, time, total);
			Timer_SecondsToTime(time, timestring, sizeof(timestring), 2);
			
			new String:buffer[128];
			Format(buffer, sizeof(buffer), "%s [%s]", name, timestring);
			
			CS_SetClientName(client, buffer);
			
			Timer_Start(client);
			new Float:fOrigin[3];
			GetArrayArray(hData, iIndex+2, fOrigin, 3);
			TeleportEntity(client, fOrigin, angles, fVel);
			
			// Strip all weapons
			new iWeapon = -1;
			for(new i=CS_SLOT_PRIMARY;i<=CS_SLOT_C4;i++)
			{
				iWeapon = GetPlayerWeaponSlot(client, i);
				if(iWeapon != -1 
				&& IsValidEntity(iWeapon) 
				&& IsValidEdict(iWeapon))
				{
					AcceptEntityInput(iWeapon, "Kill");
				}
			}
		}
		else
		{
			TeleportEntity(client, NULL_VECTOR, angles, fVel);
		}
		
		decl String:sWeapon[32];
		GetArrayString(hData, ++iIndex, sWeapon, sizeof(sWeapon));
		if(strlen(sWeapon) > 0)
		{
			// Check if he already got that weapon
			new iWeapon, bool:bGotWeapon = false;
			if(g_iBotMimicTick[client] > 0)
			{
				decl String:sClassName[32];
				for(new i=CS_SLOT_PRIMARY;i<=CS_SLOT_C4;i++)
				{
					iWeapon = GetPlayerWeaponSlot(client, i);
					if(iWeapon != -1
					&& IsValidEntity(iWeapon) 
					&& IsValidEdict(iWeapon)
					&& GetEdictClassname(iWeapon, sClassName, sizeof(sClassName))
					&& StrContains(sClassName, sWeapon, false) != -1)
					{
						bGotWeapon = true;
						// Switch to this weapon!
						FakeClientCommand(client, "use %s", sClassName);
						SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", iWeapon);
						weapon = iWeapon;
						break;
					}
				}
			}
			
			// He doesn't have this one yet. Give it to him!
			if(!bGotWeapon)
			{
				Format(sWeapon, sizeof(sWeapon), "weapon_%s", sWeapon);
				iWeapon = GivePlayerItem(client, sWeapon);
				if(iWeapon != -1 && IsValidEdict(iWeapon))
				{
					if(!StrEqual(sWeapon, "weapon_hegrenade") && !StrEqual(sWeapon, "weapon_flashbang") && !StrEqual(sWeapon, "weapon_smokegrenade"))
						EquipPlayerWeapon(client, iWeapon);
					weapon = iWeapon;
					FakeClientCommand(client, "use %s", sWeapon);
					SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", iWeapon);
				}
			}
		}
		
		g_iBotMimicTick[client]++;
		// Loop the record. Each tick has 6 values in the array + the position in the first frame!
		if((g_iBotMimicTick[client] * 6 + 1) >= GetArraySize(hData))
			g_iBotMimicTick[client] = 0;
		
		return Plugin_Changed;
	}
	else if(Timer_IsPlayerTouchingZoneType(client, ZtStart) && bool:(GetEntityFlags(client) & FL_ONGROUND) && buttons & IN_JUMP)
	{
		if(!IsPlayerAlive(client) || GetClientTeam(client) < CS_TEAM_T)
		{
			StopRecording(client);
			Timer_LogError("Replay stopped something went wrong.");
			return Plugin_Continue;
		}
		
		StopRecording(client);
		
		new Handle:xData = CreateArray(ByteCountToCells(15));
		g_iPlayerRecords[client] = PushArrayCell(g_hRecords, xData);
	}
	
	return Plugin_Continue;
}

public Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!client)
		return;
	
	if(g_iBotMimicsRecord[client] != -1)
	{
		g_iBotMimicTick[client] = 0;
	}
}

public Event_OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!client)
		return;
	
	// This one has been recording currently
	if(g_iPlayerRecords[client] != -1)
	{
		StopRecording(client);
	}
}

public Action:Timer_DelayedRespawn(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(!client)
		return Plugin_Stop;
	
	if(g_iBotMimicsRecord[client] != -1 && IsClientInGame(client) && !IsPlayerAlive(client) && IsFakeClient(client) && GetClientTeam(client) >= CS_TEAM_T)
		CS_RespawnPlayer(client);
	
	return Plugin_Stop;
}

public Action:SaveRecording(Handle:timer, any:client)
{
	if(g_iPlayerRecords[client] != -1)
	{
		new Handle:xData = GetArrayCell(g_hRecords, g_iPlayerRecords[client]);
		new iSize = GetArraySize(xData);
			
		decl String:sMapName[64];
		GetCurrentMap(sMapName, sizeof(sMapName));
		decl String:sPath[PLATFORM_MAX_PATH];
			
		// Stop recording
		g_iPlayerRecords[client] = -1;
		g_iRecordedTicks[client] = 0;
			
		// Save to file
		new String:sData[512], String:sBuffer[15];
		new Handle:hFile;
		new Float:fBuffer[3];
		
		BuildPath(Path_SM, sPath, sizeof(sPath), "data/replay/%s.txt", sMapName);

		hFile = OpenFile(sPath, "w");
		if(hFile == INVALID_HANDLE)
		{
			Timer_LogError("[Replay] cant open file (%s) for recording.",sPath);
		}
		
		// We always have 6 values each frame:
		// 0: buttons
		// 1: impulse
		// 2: real velocity vector
		// 3: fictional velocity vector
		// 4: eye angles
		// 5: weapon name
		// They are repeated all over again to save handles (imagine we'd create an own adt_array for each frame O_o)
		new iState = 0;
		for(new i=0;i<iSize;i++)
		{
			// Read the array correctly and add the value to the line
			switch(iState)
			{
				case 0, 1:
				{
					Format(sData, sizeof(sData), "%s%d|", sData, GetArrayCell(xData, i));
				}
				case 2, 3:
				{
					GetArrayArray(xData, i, fBuffer, 3);
					Format(sData, sizeof(sData), "%s%f|%f|%f|", sData, fBuffer[0], fBuffer[1], fBuffer[2]);
				}
				case 4:
				{
					GetArrayArray(xData, i, fBuffer, 3);
					// ignore roll in angles
					Format(sData, sizeof(sData), "%s%f|%f|", sData, fBuffer[0], fBuffer[1]);
				}
				case 5:
				{
					GetArrayString(xData, i, sBuffer, sizeof(sBuffer));
					Format(sData, sizeof(sData), "%s%s|", sData, sBuffer);
				}
			}
			
			// The player origin in first frame.
			if(i == 6)
			{
				GetArrayArray(xData, i, fBuffer, 3);
				Format(sData, sizeof(sData), "%s%f|%f|%f|", sData, fBuffer[0], fBuffer[1], fBuffer[2]);
			}
			
			// Write the line to the file
			iState++;
			if(i > 5 && iState > 5)
			{
				WriteFileLine(hFile, sData);
				Format(sData, sizeof(sData), "");
				iState = 0;
			}
		}
		CloseHandle(hFile);
		
		LoadReplays();
	}
	
	return Plugin_Stop;
}

StopRecording(client)
{
	if(g_iPlayerRecords[client] == -1)
		return;
	
	// Stop recording
	g_iPlayerRecords[client] = -1;
	g_iRecordedTicks[client] = 0;
}

public LoadReplays()
{
	if (hData != INVALID_HANDLE)
	{
		CloseHandle(hData);
	}
	
	hData = CreateArray(ByteCountToCells(15));
	
	// Load records for this map
	decl String:sMapName[64];
	GetCurrentMap(sMapName, sizeof(sMapName));
	
	decl String:sPath[PLATFORM_MAX_PATH];
	
	// Create our record directory
	BuildPath(Path_SM, sPath, sizeof(sPath), "data/replay");
	if(!DirExists(sPath))
		CreateDirectory(sPath, 511);
	
	new Handle:hDir = OpenDirectory(sPath);
	if(hDir == INVALID_HANDLE)
		return;
	
	decl String:sData[512];
	new String:sBuffer[64];
	new  Handle:hFile = INVALID_HANDLE;
	new iLength, iPart, Float:fBuffer[3];

	BuildPath(Path_SM, sPath, sizeof(sPath), "data/replay/%s.txt", sMapName);
	hFile = OpenFile(sPath, "r");
	if(hFile != INVALID_HANDLE)
	{			
		while(!IsEndOfFile(hFile))
		{
			iPart = 0;
			ReadFileLine(hFile, sData, sizeof(sData));
			iLength = strlen(sData);
			
			if(iLength == 0)
				continue;
			
			fBuffer[0] = 0.0;
			fBuffer[1] = 0.0;
			fBuffer[2] = 0.0;
			
			for(new i=0;i<iLength;i++)
			{
				if(StrContains(sData[i], "|") == 0)
				{
					switch(iPart)
					{
						// buttons
						case 0:
						{
							PushArrayCell(hData, StringToInt(sBuffer));
						}
						// impulse
						case 1:
						{
							PushArrayCell(hData, StringToInt(sBuffer));
						}
						// real velocity[0]
						case 2:
						{
							fBuffer[0] = StringToFloat(sBuffer);
						}
						// real velocity[1]
						case 3:
						{
							fBuffer[1] = StringToFloat(sBuffer);
						}
						// real velocity[2]
						case 4:
						{
							fBuffer[2] = StringToFloat(sBuffer);
							PushArrayArray(hData, fBuffer, 3);
						}
						// velocity[0]
						case 5:
						{
							fBuffer[0] = StringToFloat(sBuffer);
						}
						// velocity[1]
						case 6:
						{
							fBuffer[1] = StringToFloat(sBuffer);
						}
						// velocity[2]
						case 7:
						{
							fBuffer[2] = StringToFloat(sBuffer);
							PushArrayArray(hData, fBuffer, 3);
						}
						// angles[0]
						case 8:
						{
							fBuffer[0] = StringToFloat(sBuffer);
						}
						// angles[1]
						case 9:
						{
							fBuffer[1] = StringToFloat(sBuffer);
							fBuffer[2] = 0.0;
							PushArrayArray(hData, fBuffer, 3);
						}
						// weapon
						case 10:
						{
							if(strlen(sBuffer) == 0)
								Format(sBuffer, sizeof(sBuffer), "\0");
							PushArrayString(hData, sBuffer);
						}
						// optional origin[0]
						case 11:
						{
							fBuffer[0] = StringToFloat(sBuffer);
						}
						// optional origin[1]
						case 12:
						{
							fBuffer[1] = StringToFloat(sBuffer);
						}
						// optional origin[2]
						case 13:
						{
							fBuffer[2] = StringToFloat(sBuffer);
							PushArrayArray(hData, fBuffer, 3);
						}
					}
					Format(sBuffer, sizeof(sBuffer), "");
					iPart++;
					continue;
				}
				Format(sBuffer, sizeof(sBuffer), "%s%c", sBuffer, sData[i]);
			}
		}
				
		CloseHandle(hFile);
		
		DodgyFix();
	}
			
	CloseHandle(hDir);
}

public Action:RefreshBot(Handle:timer)
{
	DodgyFix();
}

public DodgyFix()
{
	new iBot = -1;
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i))
			continue;
		if(!IsFakeClient(i))
			continue;
		if(!IsPlayerAlive(i))
		{
			CS_RespawnPlayer(i);
			continue;
		}
		
		iBot = i;
		break;
	}
	
	if(iBot != -1)
	{
		new String:name[32];
		Timer_GetRecordHolderName(g_StyleDefault, 0, 1, name, 32);
		
		new cacheid, total;
		new Float:time;
		new String:timestring[32];
		
		Timer_GetStyleRecordTime(g_StyleDefault, 0, cacheid, time, total);
		Timer_SecondsToTime(time, timestring, sizeof(timestring), 2);
		
		new String:buffer[64];
		Format(buffer, sizeof(buffer), "%s [%s]", name, timestring);
		
		CS_SetClientName(iBot, buffer);
		
		SetEntityRenderColor(iBot, 0, 0, 255, 50);
		g_iPlayerRecords[iBot] = -1;
		g_iBotMimicsRecord[iBot] = 0;
		g_iBotMimicTick[iBot] = 0;
		Timer_Restart(iBot);
		Timer_SetStyle(iBot, g_StyleDefault);
	
	}
	else 
	{
		ServerCommand("bot_quota 0");
		ServerCommand("bot_quota 1");
		CreateTimer(2.0, RefreshBot);
	}
}