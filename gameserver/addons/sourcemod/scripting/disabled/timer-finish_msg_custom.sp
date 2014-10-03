#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <timer>
#include <timer-stocks>
#include <timer-config_loader.sp>

#undef REQUIRE_PLUGIN
#include <timer-physics>
#include <timer-mapzones>
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
	// Load msg preset
	
	new maxmsg = 256;
	new buffersize = 1024;
	decl String:Msg[maxmsg][buffersize];
	new msgcount = 0;
	
	decl String:file[256];
	
	BuildPath(Path_SM, file, 256, "configs/timer/finish_msg.cfg"); 
	new Handle:fileh = OpenFile(file, "r");
	
	if (fileh == INVALID_HANDLE)
		
	while (ReadFileLine(fileh, Msg[msgcount], buffersize)) 
		msgcount++;
		
	CloseHandle(fileh);
	
	// Prepare
	new enabled, jumps, fpsmax;
	Timer_GetClientTimer(client, enabled, time, jumps, fpsmax);
	
	new Float:wrtime, wrid, ranktotal;
	if(g_timerWorldRecord) Timer_GetStyleRecordWRStats(style, track, wrid, wrtime, ranktotal);
	
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
	decl String:sStaticTrackNormal[] = "Normal", String:sStaticTrackBonus[] = "Bonus", String:sStaticTrackShort[] = "Short";
	
	decl String:sTrack[32];
	
	if(track == TRACK_NORMAL) Format(sTrack, sizeof(sTrack), "%s", sStaticTrackNormal);
	else if(track == TRACK_BONUS) Format(sTrack, sizeof(sTrack), "%s", sStaticTrackBonus);
	else if(track == TRACK_SHORT) Format(sTrack, sizeof(sTrack), "%s", sStaticTrackShort);
	
	// Get Player Names
	
	decl String:sName[32], String:sBeatenName[32], String:sNextName[32], String:sWrName[32];
	
	GetClientName(client, sName, sizeof(sName));
	if(g_timerWorldRecord)
	{
		if(!world_record) Timer_GetRecordHolderName(style, track, newrank+1, sNextName, 32);
		if(!first_world_record) Timer_GetRecordHolderName(style, track, newrank, sBeatenName, 32);
		if(!first_world_record) Timer_GetRecordHolderName(style, track, 1, sWrName, 32);
	}
	
	// Get Basic Info
	
	decl String:sStyleName[32], String:sStyleID[8], String:sStyleShortName[32], String:sStylePointsMul[16], String:sStageCount[8];
	
	Format(sStyleName, sizeof(sStyleName), "%s", g_Physics[style][StyleName]);
	Format(sStyleID, sizeof(sStyleID), "%d", style);
	Format(sStyleShortName, sizeof(sStyleShortName), "%s", g_Physics[style][StyleTagShortName]);
	Format(sStylePointsMul, sizeof(sStylePointsMul), "%.2f", g_Physics[style][StylePointsMulti]);
	
	if(track == TRACK_BONUS) 
		Format(sStageCount, sizeof(sStageCount), "%d", Timer_GetMapzoneCount(ZtBonusLevel)+1);
	else Format(sStageCount, sizeof(sStageCount), "%d", Timer_GetMapzoneCount(ZtLevel)+1);
	
	decl String:sChatrank[32];
	
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
	
	decl String:sOldRank[8], String:sNewRank[8], String:sTotalRank[16];
	Format(sOldRank, sizeof(sOldRank), "%d", currentrank);
	Format(sNewRank, sizeof(sNewRank), "%d", newrank);
	Format(sTotalRank, sizeof(sTotalRank), "%d", ranktotal);
	
	decl String:sOldRankDiff[32],		String:sRankWrDiff[32];
	
	// Record Info
	
	decl String:sTime[32],				String:sBeatenTime[32],			String:sNextTime[32],				String:sWrTime[32],					String:sOldTime[32];
	decl String:sJumps[32],				String:sBeatenJumps[32],		String:sNextJumps[32],				String:sWrJumps[32],				String:sOldJumps[32];
	decl String:sTimeBeatenDiff[32],	String:sTimeNextDiff[32],		String:sTimeWRDiff[32],				String:sTimeOldDiff[32];
	//Timer_SecondsToTime(time, TimeString, sizeof(TimeString), 2);
	
	// Jump Accuracy
	
	decl String:sJumpAcc[16]; new Float:jumpacc;
	if(g_timerPhysics)
	{
		Format(sJumpAcc, sizeof(sJumpAcc), "%.2f", jumpacc);
		Timer_GetJumpAccuracy(client, jumpacc);
	}
	
	// Strafes
	
	new strafes, beatenstrafes, nextstrafes, wrstrafes, oldstrafes;
	if(g_timerStrafes)  strafes = Timer_GetStrafeCount(client);
	
	decl String:sStrafes[8], String:sBeatenStrafes[8], String:sNextStrafes[8], String:sWrStrafes[8], String:sOldStrafes[8];
	
	Format(sStrafes, sizeof(sStrafes), "%d", strafes);
	Format(sBeatenStrafes, sizeof(sBeatenStrafes), "%d", beatenstrafes);
	Format(sNextStrafes, sizeof(sNextStrafes), "%d", nextstrafes);
	Format(sWrStrafes, sizeof(sWrStrafes), "%d", wrstrafes);
	Format(sOldStrafes, sizeof(sOldStrafes), "%d", oldstrafes);
	
	//Replace msg lines
	
	for (new i = 0; i < msgcount; i++)
	{
		//load msg buffer here
		
		if(StrEqual(Msg[i], "", true))
			continue;
		
		// Filter msg lines
		
		if(ReplaceString(Msg[i], buffersize, "{CHANNEL_RANKED}", "", true) && !ranked)
			continue;
		if(ReplaceString(Msg[i], buffersize, "{CHANNEL_UNRANKED}", "", true) && ranked)
			continue;
		if(ReplaceString(Msg[i], buffersize, "{CHANNEL_FIRSTWR}", "", true) && !first_world_record)
			continue;
		if(ReplaceString(Msg[i], buffersize, "{CHANNEL_WR_SELF}", "", true) && !world_record_self)
			continue;
		if(ReplaceString(Msg[i], buffersize, "{CHANNEL_TOP}", "", true) && !top_record)
			continue;
		if(ReplaceString(Msg[i], buffersize, "{CHANNEL_TIME}", "", true) && !time_improved)
			continue;
		if(ReplaceString(Msg[i], buffersize, "{CHANNEL_FIRST}", "", true) && !first_record)
			continue;
		if(ReplaceString(Msg[i], buffersize, "{CHANNEL_RANK}", "", true) && !rank_improved)
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
		ReplaceString(Msg[i], buffersize, "{NAME_BEATEN}", sBeatenName, true);
		ReplaceString(Msg[i], buffersize, "{NAME_NEXT}", sNextName, true);
		ReplaceString(Msg[i], buffersize, "{NAME_WR}", sWrName, true);
		
		ReplaceString(Msg[i], buffersize, "{CHATRANK}", sChatrank, true);
		
		ReplaceString(Msg[i], buffersize, "{TIME}", sTime, true);
		ReplaceString(Msg[i], buffersize, "{TIME_BEATEN}", sBeatenTime, true);
		ReplaceString(Msg[i], buffersize, "{TIME_NEXT}", sNextTime, true);
		ReplaceString(Msg[i], buffersize, "{TIME_WR}", sWrTime, true);
		ReplaceString(Msg[i], buffersize, "{TIME_OLD}", sOldTime, true);
		
		ReplaceString(Msg[i], buffersize, "{STRAFES}", sStrafes, true);
		ReplaceString(Msg[i], buffersize, "{STRAFES_BEATEN}", sBeatenStrafes, true);
		ReplaceString(Msg[i], buffersize, "{STRAFES_NEXT}", sNextStrafes, true);
		ReplaceString(Msg[i], buffersize, "{STRAFES_WR}", sWrStrafes, true);
		ReplaceString(Msg[i], buffersize, "{STRAFES_OLD}", sOldStrafes, true);
		
		ReplaceString(Msg[i], buffersize, "{JUMPS}", sJumps, true);
		ReplaceString(Msg[i], buffersize, "{JUMPS_BEATEN}", sBeatenJumps, true);
		ReplaceString(Msg[i], buffersize, "{JUMPS_NEXT}", sNextJumps, true);
		ReplaceString(Msg[i], buffersize, "{JUMPS_WR}", sWrJumps, true);
		ReplaceString(Msg[i], buffersize, "{JUMPS_OLD}", sOldJumps, true);
		
		ReplaceString(Msg[i], buffersize, "{TIME_DIFF_BEATEN}", sTimeBeatenDiff, true);
		ReplaceString(Msg[i], buffersize, "{TIME_DIFF_NEXT}", sTimeNextDiff, true);
		ReplaceString(Msg[i], buffersize, "{TIME_DIFF_WR}", sTimeWRDiff, true);
		ReplaceString(Msg[i], buffersize, "{TIME_DIFF_OLD}", sTimeOldDiff, true);
		
		ReplaceString(Msg[i], buffersize, "{OLDRANK}", sOldRank, true);
		ReplaceString(Msg[i], buffersize, "{NEWRANK}", sNewRank, true);
		ReplaceString(Msg[i], buffersize, "{TOTALRANK}", sTotalRank, true);
		
		ReplaceString(Msg[i], buffersize, "{RANK_DIFF_OLD}", sOldRankDiff, true);
		ReplaceString(Msg[i], buffersize, "{RANK_WR_DIFF}", sRankWrDiff, true);
		
		ReplaceString(Msg[i], buffersize, "{STAGECOUNT}", sStageCount, true);
		
		ReplaceString(Msg[i], buffersize, "{PERC}", sStaticPerc, true);
		
		// Send messages
		
		if(ReplaceString(Msg[i], buffersize, "{ALL}", "", true) > 0 || ranked)
			CPrintToChatAll(Msg[i]);
		else CPrintToChat(client, Msg[i]);
		
		Format(Msg[i], buffersize, "");
	}
}