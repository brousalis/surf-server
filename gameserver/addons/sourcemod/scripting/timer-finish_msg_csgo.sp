#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <timer>
#include <timer-stocks>
#include <timer-config_loader.sp>

#undef REQUIRE_PLUGIN
#include <timer-physics>
#include <timer-worldrecord>
#include <timer-strafes>

new bool:g_timerPhysics = false;
new bool:g_timerStrafes = false;
new bool:g_timerWorldRecord = false;

public Plugin:myinfo = 
{
	name = "[Timer] Finish Message",
	author = "Zipcore",
	description = "[Timer] Finish message for CS:GO",
	version = PL_VERSION,
	url = "forums.alliedmods.net/showthread.php?p=2074699"
};

public OnPluginStart()
{
	if(GetEngineVersion() != Engine_CSGO)
	{
		Timer_LogError("Don't use this plugin for other games than CS:GO.");
		SetFailState("Check timer error logs.");
		return;
	}
	
	g_timerPhysics = LibraryExists("timer-physics");
	g_timerStrafes = LibraryExists("timer-strafes");
	g_timerWorldRecord = LibraryExists("timer-worldrecord");
	
	LoadPhysics();
	LoadTimerSettings();
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "timer-physics"))
	{
		g_timerPhysics = true;
	}	
	else if (StrEqual(name, "timer-strafes"))
	{
		g_timerStrafes = true;
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
	else if (StrEqual(name, "timer-strafes"))
	{
		g_timerStrafes = false;
	}
	else if (StrEqual(name, "timer-worldrecord"))
	{
		g_timerWorldRecord = false;
	}
}


public OnMapStart()
{
	LoadPhysics();
	LoadTimerSettings();
}

public OnTimerRecord(client, track, style, Float:time, Float:lasttime, currentrank, newrank)
{
	decl String:name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));
	
	//Record Info
	new RecordId;
	new Float:RecordTime;
	new RankTotal;
	new Float:LastTime;
	new Float:LastTimeStatic;
	new LastJumps;
	decl String:TimeDiff[32];
	decl String:buffer[32];
	
	new bool:NewPersonalRecord = false;
	new bool:NewWorldRecord = false;
	new bool:FirstRecord = false;
	
	new bool:ranked, Float:jumpacc;
	if(g_timerPhysics) 
	{
		ranked = bool:Timer_IsStyleRanked(style);
		Timer_GetJumpAccuracy(client, jumpacc);
	}
	
	new strafes;
	if(g_timerStrafes)  strafes = Timer_GetStrafeCount(client);

	
	new bool:enabled = false;
	new jumps = 0;
	new fpsmax;

	Timer_GetClientTimer(client, enabled, time, jumps, fpsmax);
	
	if(g_timerWorldRecord) 
	{
		/* Get Personal Record */
		if(Timer_GetBestRound(client, style, track, LastTime, LastJumps))
		{
			LastTimeStatic = LastTime;
			LastTime -= time;			
			if(LastTime < 0.0)
			{
				LastTime *= -1.0;
				Timer_SecondsToTime(LastTime, buffer, sizeof(buffer), 3);
				FormatEx(TimeDiff, sizeof(TimeDiff), "+%s", buffer);
			}
			else if(LastTime > 0.0)
			{
				Timer_SecondsToTime(LastTime, buffer, sizeof(buffer), 3);
				FormatEx(TimeDiff, sizeof(TimeDiff), "-%s", buffer);
			}
			else if(LastTime == 0.0)
			{
				Timer_SecondsToTime(LastTime, buffer, sizeof(buffer), 3);
				FormatEx(TimeDiff, sizeof(TimeDiff), "%s", buffer);
			}
		}
		else
		{
			//No personal record, this is his first record
			FirstRecord = true;
			LastTime = 0.0;
			Timer_SecondsToTime(LastTime, buffer, sizeof(buffer), 3);
			FormatEx(TimeDiff, sizeof(TimeDiff), "%s", buffer);
			RankTotal++;
		}
	}
	
	decl String:TimeString[32];
	Timer_SecondsToTime(time, TimeString, sizeof(TimeString), 2);
	
	new String:WrName[32], String:WrTime[32];
	new Float:wrtime;
	
	if(g_timerWorldRecord) 
	{
		Timer_GetRecordTimeInfo(style, track, newrank, wrtime, WrTime, 32);
		Timer_GetRecordHolderName(style, track, newrank, WrName, 32);
	
		/* Get World Record */
		Timer_GetStyleRecordWRStats(style, track, RecordId, RecordTime, RankTotal);
	}
	
	/* Detect Record Type */
	if(RecordTime == 0.0 || time < RecordTime)
	{
		NewWorldRecord = true;
	}
	
	if(LastTimeStatic == 0.0 || time < LastTimeStatic)
	{
		NewPersonalRecord = true;
	}
	
	new bool:self = false;
	
	if(currentrank == newrank)
	{
		self = true;
	}
	
	if(FirstRecord) RankTotal++;
	
	new Float:wrdiff = time-wrtime;
	
	new String:BonusString[32];
	
	if(track == TRACK_BONUS)
	{
		FormatEx(BonusString, sizeof(BonusString), " {olive}bonus");
	}
	else if(track == TRACK_SHORT)
	{
		FormatEx(BonusString, sizeof(BonusString), " {olive}short");
	}	
	
	new String:RankString[128], String:RankPwndString[128];

	new String:JumpString[128];
	new bool:bAll = false;
	
	new String:StyleString[128];
	if(g_Settings[MultimodeEnable]) 
		FormatEx(StyleString, sizeof(StyleString), " on {olive}%s", g_Physics[style][StyleName]);
	
	if(NewWorldRecord)
	{
		bAll = true;
		FormatEx(RankString, sizeof(RankString), "{purple}NEW WORLD RECORD");
		
		if(wrtime > 0.0)
		{
			if(self)
				FormatEx(RankPwndString, sizeof(RankPwndString), "{olive}Improved {lightred}%s{olive}! {lightred}[%.2fs]{olive} diff, old time was {lightred}[%s]", "himself", wrdiff, WrTime);
			else
				FormatEx(RankPwndString, sizeof(RankPwndString), "{olive}Beaten {lightred}%s{olive}! {lightred}[%.2fs]{olive} diff, old time was {lightred}[%s]", WrName, wrdiff, WrTime);
		}
	}
	else if(newrank > 5000)
	{
		FormatEx(RankString, sizeof(RankString), "{lightred}#%d+ / %d", newrank, RankTotal);
	}
	else if(NewPersonalRecord || FirstRecord)
	{
		bAll = true;
		FormatEx(RankString, sizeof(RankString), "{lightred}#%d / %d", newrank, RankTotal);
		
		if(newrank < currentrank) FormatEx(RankPwndString, sizeof(RankPwndString), "{olive}Beaten {lightred}%s{olive}! {lightred}[%.2fs]{olive} diff, old time was {lightred}[%s]", WrName, wrdiff, WrTime);
	}	
	else if(NewPersonalRecord)
	{
		FormatEx(RankString, sizeof(RankString), "{orange}#%d / %d", newrank, RankTotal);
		
		Format(RankPwndString, sizeof(RankPwndString), "You have improved {lightred}yourself! {lightred}[%.2fs]{olive} diff, old time was {lightred}[%s]", wrdiff, WrTime);
	}
	
	if(g_Settings[JumpsEnable])
	{
		FormatEx(JumpString, sizeof(JumpString), "{olive} and {lightred}%d jumps [%.2f ⁰⁄₀]", jumps, jumpacc);
	}
	
	if(g_Settings[StrafesEnable])
	{
		FormatEx(JumpString, sizeof(JumpString), "{olive} and {lightred}%d strafes", strafes);
	}
	
	if(ranked)
	{
		if(FirstRecord || NewPersonalRecord)
		{
			if(bAll)
			{
				CPrintToChatAll("%s {olive}Player {lightred}%s{olive} has finished%s{olive}%s{olive}.", PLUGIN_PREFIX2, name, BonusString, StyleString);
				CPrintToChatAll("{olive}Time: {lightred}[%ss] %s %s", TimeString, JumpString, RankString);
				CPrintToChatAll("%s", RankPwndString);
			}
			else
			{
				CPrintToChat(client, "%s {lightred}You{olive} have finished%s{olive}%s{olive}.", PLUGIN_PREFIX2, BonusString, StyleString);
				CPrintToChat(client, "{olive}Time: {lightred}[%ss] %s %s", TimeString, JumpString, RankString);
				CPrintToChat(client, "%s", RankPwndString);
			}
		}
		else
		{
			CPrintToChat(client, "%s {lightred}You{olive} have finished%s{olive}%s{olive}. Time: {lightred}[%ss] %s %s", PLUGIN_PREFIX2, BonusString, StyleString, TimeString, JumpString, RankString);
		}
	}
	else
	{
		CPrintToChat(client, "{lightred}You{olive} have finished%s{olive}%s{olive}.", PLUGIN_PREFIX2, BonusString, StyleString);
		CPrintToChat(client, "{olive}Time: {lightred}[%ss] %s", TimeString, JumpString);
	}
}