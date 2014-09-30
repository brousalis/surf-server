#include <sourcemod>
#include <timer>
#include <timer-mapzones>
#include <timer-stocks>

#define MAX_LEVEL 2000

new Float:g_MapLevelBestTime[MAX_LEVEL][MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "[Timer] MapZones - Simple Stage Timer",
	author = "Zipcore",
	description = "Shows time diff. for level zones, without saving times until mapchange.",
	version = "1.0",
	url = "https://forums.alliedmods.net/showthread.php?t=231866"
}

public OnMapStart()
{
	for (new i = 0; i < MAX_LEVEL-1; i++)
	{
		for (new client = 1; client < MAXPLAYERS; client++)
		{
			g_MapLevelBestTime[i][client] = 0.0;
		}
	}
}

public OnClientStartTouchLevel(client, level, lastlevel)
{
	PrintTimeDiff(client, level, lastlevel);
}

public OnClientStartTouchBonusLevel(client, level, lastlevel)
{
	PrintTimeDiff(client, level, lastlevel);
}

stock PrintTimeDiff(client, level, lastlevel)
{
	if(level == lastlevel+1)
	{
		new bool:enabled = false;
		new Float:time;
		new jumps;
		new fpsmax;
		new String:buffer[32];
		
		Timer_GetClientTimer(client, enabled, time, jumps, fpsmax);
		
		if(enabled)
		{
			if(g_MapLevelBestTime[level][client] == 0.0)
			{
				Timer_SecondsToTime(time, buffer, sizeof(buffer), 2);
				PrintCenterText(client, "-00:00.00");
				g_MapLevelBestTime[level][client] = time;
			}
			else if(g_MapLevelBestTime[level][client] > time)
			{
				Timer_SecondsToTime(g_MapLevelBestTime[level][client]-time, buffer, sizeof(buffer), 2);
				PrintCenterText(client, "-%s", buffer);
				g_MapLevelBestTime[level][client] = time;
			}
			else if(g_MapLevelBestTime[level][client] == time)
			{
				PrintCenterText(client, "+00:00.00");
			}
			else if(g_MapLevelBestTime[level][client] < time)
			{
				Timer_SecondsToTime(time-g_MapLevelBestTime[level][client], buffer, sizeof(buffer), 2);
				PrintCenterText(client, "+%s", buffer);
			}
		}
	}
}
