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
#include <timer-maptier>

new bool:g_timerPhysics = false;
new bool:g_timerStrafes = false;
new bool:g_timerWorldRecord = false;

public Plugin:myinfo = 
{
	name = "[Timer] Custom Finish Message",
	author = "Zipcore",
	description = "[Timer] Custom Finish Message",
	version = PL_VERSION,
	url = "forums.alliedmods.net/showthread.php?p=2074699"
};

public OnPluginStart()
{
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
	// Prepare
	
	new enabled, jumps, fpsmax;
	Timer_GetClientTimer(client, enabled, time, jumps, fpsmax);
	
	new Float:wrtime, wrid, ranktotal;
	Timer_GetStyleRecordWRStats(style, track, wrid, wrtime, ranktotal);
	
	// What kind of record is this?
	
	new bool:ranked, bool:first_world_record, bool:world_record_self, bool:world_record, bool:top_record, bool:first_record, bool:rank_improved, bool:time_improved;
	
	// Is style ranked
	if(g_timerPhysics) ranked = bool:Timer_IsStyleRanked(style);
		
	// First record on this map
	if(wrtime == 0.0)
		first_world_record = true;
	
	// World record
	if(newrank == 1)
		world_record = true;
	
	// Worldrecord but beaten themself
	if(currentrank == 1 && newrank == 1)
		world_record_self = true;
	
	// Top10 record
	if(newrank <= 10)
		top_record = true;
	
	// First player record
	if(currentrank == 0)
		first_record = true;
	
	// Rank improved
	if(currentrank > 0 && currentrank > newrank)
		rank_improved = true;
	
	// Time improved
	if(time < lasttime)
		rank_improved = true;
	
	// Get Static Names
	
	static String:sStaticPerc[] = "⁰⁄₀";
	decl String:sStaticTrackNormal[32], String:sStaticTrackBonus[32], String:sStaticTrackShort[32];
	
	// Get Player Names
	
	decl String:sName[32],				String:sBeatenName[32],				String:sNextName[32],				String:sWrName[32];
	
	GetClientName(client, sName, sizeof(sName));
	if(g_timerWorldRecord)
	{
		if(!world_record) Timer_GetRecordHolderName(style, track, newrank+1, sNextName, 32);
		if(!first_world_record) Timer_GetRecordHolderName(style, track, newrank, sBeatenName, 32);
		if(!first_world_record) Timer_GetRecordHolderName(style, track, 1, sWrName, 32);
	}
	
	// Get Basic Info
	
	decl String:sStyleName[32], String:sStyleID[8], String:sStyleShortName[32], String:sStylePointsMul[16], String:sStageCount[8], String:sTrack[8];
	
	Format(sStyleName, sizeof(sStyleName), "%s", g_Physics[style][StyleName]);
	Format(sStyleID, sizeof(sStyleID), "%d", style);
	Format(sStyleShortName, sizeof(sStyleShortName), "%s", g_Physics[style][StyleTagShortName]);
	Format(sStylePointsMul, sizeof(sStylePointsMul), "%.2f", g_Physics[style][StylePointsMulti]);
	Format(sStageCount, sizeof(sStageCount), "%d", Timer_GetStageCount(track));
	Format(sTrack, sizeof(sTrack), "%d", Timer_GetTrack(track));
	//decl String:sChatrank[32];
	
	// Get Tier Info
	
	decl  String:sTier[8], String:sTierPointsMul[16];
	
	new tier = Timer_GetTier(track);
	if(track == TRACK_BONUS) tier = 1;
	Format(sTier, sizeof(sTier), "%d", tier);
	new Float:tier_scale;
	if(tier == 1)
		tier_scale = g_Settings[Tier1Scale];
	else if(tier == 2)
		tier_scale = g_Settings[Tier2Scale];
	else if(tier == 3)
		tier_scale = g_Settings[Tier3Scale];
	else if(tier == 4)
		tier_scale = g_Settings[Tier4Scale];
	else if(tier == 5)
		tier_scale = g_Settings[Tier5Scale];
	else if(tier == 6)
		tier_scale = g_Settings[Tier6Scale];
	else if(tier == 7)
		tier_scale = g_Settings[Tier7Scale];
	else if(tier == 8)
		tier_scale = g_Settings[Tier8Scale];
	else if(tier == 9)
		tier_scale = g_Settings[Tier9Scale];
	else if(tier == 10)
		tier_scale = g_Settings[Tier10Scale];
	Format(sTierPointsMul, sizeof(sTierPointsMul), "%.2f", tier_scale);
	
	// Ranks Info
	
	decl String:sOldRank[32],			String:sNewRank[32],			String:sTotalRank[32];
	decl String:sOldRankDiff[32],		String:sRankWrDiff[32];
	
	// Record Info
	
	decl String:sTime[32],				String:sNextTime[32],			String:sWrTime[32],					String:sOldTime[32];
	decl String:sJumps[32],				String:sNextJumps[32],			String:sWrJumps[32],				String:sOldJumps[32];
	decl String:sStrafes[32],			String:sNextStrafes[32],		String:sWrStrafes[32],				String:sOldStrafes[32];
	decl String:sTimeNextDiff[32],		String:sTimeWRDiff[32],			String:sTimeOldDiff[32];
	
	/*
	if(g_timerPhysics) Timer_GetJumpAccuracy(client, jumpacc);
	if(g_timerStrafes) strafes = Timer_GetStrafeCount(client);
	
	
	
	new strafes;
	if(g_timerStrafes)  strafes = Timer_GetStrafeCount(client);

	
	
	if(g_timerWorldRecord) 
	{
		//Get Personal Record
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
	
	if(g_timerWorldRecord) 
	{
		Timer_GetRecordTimeInfo(style, track, newrank, wrtime, WrTime, 32);
		Timer_GetRecordHolderName(style, track, newrank, WrName, 32);
		
		//Get World Record
		Timer_GetStyleRecordWRStats(style, track, RecordId, RecordTime, RankTotal);
	}
	
	//Detect Record Type
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
		FormatEx(RankString, sizeof(RankString), "{lightred}NEW WORLD RECORD");
		
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
	*/
	
	new maxmsg = 32;
	new buffersize = 512;
	decl String:Msg[maxmsg][buffersize];
	
	//Load preset config
	if(first_world_record)
	{
		
	}
	else if(world_record_self)
	{
		
	}
	else if(world_record)
	{
		
	}
	else if(top_record)
	{
		
	}
	else if(first_record)
	{
		
	}
	else if(rank_improved)
	{
		
	}
	else if(time_improved)
	{
		
	}
	else
	{
		
	}
	
	for (new i = 0; i < maxmsg; i++)
	{
		if(StrEqual(Msg[i], "", true))
			continue;
		
		// Replace placeholders
		ReplaceString(Msg[i], buffersize, "{STYLE}", sStyleName, true);
		ReplaceString(Msg[i], buffersize, "{STYLE_SHORT}", sStyleShortName, true);
		ReplaceString(Msg[i], buffersize, "{STYLE_ID}", sStyleID, true);
		ReplaceString(Msg[i], buffersize, "{STYLE_POINTS_MUL}", sStylePointsMul, true);
		
		ReplaceString(Msg[i], buffersize, "{TRACK}", sTrack, true);
		ReplaceString(Msg[i], buffersize, "{TIER}", sTier, true);
		ReplaceString(Msg[i], buffersize, "{TIER_POINTS_MUL}", sTierPointsMul, true);
		
		ReplaceString(Msg[i], buffersize, "{NAME}", sName, true);
		ReplaceString(Msg[i], buffersize, "{NAME_NEXT}", sNextName, true);
		ReplaceString(Msg[i], buffersize, "{NAME_WR}", sWrName, true);
		
		//ReplaceString(Msg[i], buffersize, "{CHATRANK}", sChatrank, true);
		
		ReplaceString(Msg[i], buffersize, "{TIME}", sTime, true);
		ReplaceString(Msg[i], buffersize, "{TIME_NEXT}", sNextTime, true);
		ReplaceString(Msg[i], buffersize, "{TIME_WR}", sWrTime, true);
		ReplaceString(Msg[i], buffersize, "{TIME_OLD}", sOldTime, true);
		
		ReplaceString(Msg[i], buffersize, "{STRAFES}", sStrafes, true);
		ReplaceString(Msg[i], buffersize, "{STRAFES_NEXT}", sNextStrafes, true);
		ReplaceString(Msg[i], buffersize, "{STRAFES_WR}", sWrStrafes, true);
		ReplaceString(Msg[i], buffersize, "{STRAFES_OLD}", sOldStrafes, true);
		
		ReplaceString(Msg[i], buffersize, "{JUMPS}", sJumps, true);
		ReplaceString(Msg[i], buffersize, "{JUMPS_NEXT}", sNextJumps, true);
		ReplaceString(Msg[i], buffersize, "{JUMPS_WR}", sWrJumps, true);
		ReplaceString(Msg[i], buffersize, "{JUMPS_OLD}", sOldJumps, true);
		
		ReplaceString(Msg[i], buffersize, "{TIME_DIFF_NEXT}", sTimeNextDiff, true);
		ReplaceString(Msg[i], buffersize, "{TIME_DIFF_WR}", sTimeWRDiff, true);
		ReplaceString(Msg[i], buffersize, "{TIME_DIFF_OLD}", sTimeOldDiff, true);
		
		ReplaceString(Msg[i], buffersize, "{OLDRANK}", sNewRank, true);
		ReplaceString(Msg[i], buffersize, "{NEWRANK}", sOldRank, true);
		ReplaceString(Msg[i], buffersize, "{TOTALRANK}", sTotalRank, true);
		
		ReplaceString(Msg[i], buffersize, "{RANK_DIFF_OLD}", sOldRankDiff, true);
		ReplaceString(Msg[i], buffersize, "{RANK_WR_DIFF}", sRankWrDiff, true);
		
		ReplaceString(Msg[i], buffersize, "{STAGECOUNT}", sStageCount, true);
		
		// Send messages
		if(ReplaceString(Msg[i], buffersize, "{ALL}", "", true) > 0 || ranked)
			CPrintToChatAll(Msg[i]);
		else CPrintToChat(client, Msg[i]);
		
		Format(Msg[i], buffersize, "");
	}
}