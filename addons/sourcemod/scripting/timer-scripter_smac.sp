#pragma semicolon 1

#include <sourcemod>

#include <timer>
#include <timer-mapzones>
#include <timer-logging>
#include <timer-config_loader.sp>

#define TRIGGER_DETECTIONS 12
#define MIN_JUMP_TIME 0.5
new g_iDetections[MAXPLAYERS+1];

public Plugin:myinfo =
{
name        = "[Timer] AutoTrigger Detection",
author      = "Zipcore, Jason Bourne",
description = "[Timer] AutoTrigger detection (SMAC)",
version     = PL_VERSION,
url         = "forums.alliedmods.net/showthread.php?p=2074699"
};

public OnPluginStart()
{
	LoadPhysics();
	LoadTimerSettings();
	CreateTimer(4.0, Timer_DecreaseCount, _, TIMER_REPEAT);
}

public OnMapStart()
{
	LoadPhysics();
	LoadTimerSettings();
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	new mode = Timer_GetMode(client);
	if(Timer_IsModeRanked(mode) && !g_Physics[mode][ModeAuto] && !Timer_IsPlayerTouchingZoneType(client, ZtAuto)) 
	{
		static iPrevButtons[MAXPLAYERS+1];

			/* BunnyHop */
		static Float:fCheckTime[MAXPLAYERS+1];

			// Player didn't jump immediately after the last jump.
		if (!(buttons & IN_JUMP) && (GetEntityFlags(client) & FL_ONGROUND) && fCheckTime[client] > 0.0)
		{
			fCheckTime[client] = 0.0;
		}

		// Ignore this jump if the player is in a tight space or stuck in the ground.
		if ((buttons & IN_JUMP) && !(iPrevButtons[client] & IN_JUMP))
		{
			// Player is on the ground and about to trigger a jump.
			if (GetEntityFlags(client) & FL_ONGROUND)
			{
				new Float:fGameTime = GetGameTime();

				// Player jumped on the exact frame that allowed it.
				if (fCheckTime[client] > 0.0 && fGameTime > fCheckTime[client])
				{
					AutoTrigger_Detected(client);
				}
				else
				{
					fCheckTime[client] = fGameTime + MIN_JUMP_TIME;
				}
			}
			else
			{
				fCheckTime[client] = 0.0;
			}
		}

		iPrevButtons[client] = buttons;
	}
	else g_iDetections[client] = 0;

	return Plugin_Continue;
}

AutoTrigger_Detected(client)
{
	g_iDetections[client]++;

	if (!IsFakeClient(client) && IsPlayerAlive(client) && g_iDetections[client] >= TRIGGER_DETECTIONS)
	{
		new String:auth[64];
		GetClientAuthString(client, auth, strlen(auth));
		Timer_LogInfo("[scripter_smac] %N [%s] banned by smac-autotrigger module after %d perfect jumps", client, auth, g_iDetections[client]);
		Timer_AddScripter(client);

		g_iDetections[client] = 0;
	}
}

public OnClientDisconnect_Post(client)
{
	g_iDetections[client] = 0;
}

public Action:Timer_DecreaseCount(Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (g_iDetections[i])
		{
			g_iDetections[i]--;
		}
	}

	return Plugin_Continue;
}