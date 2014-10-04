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

#define MAX_RECORD_MESSAGES 256
#define MESSAGE_BUFFERSIZE 1024

new String:g_Msg[MAX_RECORD_MESSAGES][MESSAGE_BUFFERSIZE];
new String:Msg[MAX_RECORD_MESSAGES][MESSAGE_BUFFERSIZE];
new g_MessageCount = 0;

new bool:g_timerPhysics = false;
new bool:g_timerRankings = false;
new bool:g_timerStrafes = false;
new bool:g_timerWorldRecord = false;

public Plugin:myinfo = 
{
	name = "[Timer] Custom Finish Message",
	author = "Zipcore, SeriTools",
	description = "[Timer] Custom Finish Message",
	version = PL_VERSION,
	url = "forums.alliedmods.net/showthread.php?p=2074699"
};

public OnPluginStart()
{
	g_timerPhysics = LibraryExists("timer-physics");
	g_timerRankings = LibraryExists("timer-rankings");
	g_timerStrafes = LibraryExists("timer-strafes");
	g_timerWorldRecord = LibraryExists("timer-worldrecord");
	
	LoadPhysics();
	LoadTimerSettings();

	// Load msg preset
	
	decl String:file[256];
	
	BuildPath(Path_SM, file, 256, "configs/timer/finish_msg.cfg"); 
	new Handle:fileh = OpenFile(file, "r");
	
	if (fileh == INVALID_HANDLE)
	{
		Timer_LogError("Could not read configs/timer/finish_msg.cfg.");
		SetFailState("Check timer error logs.");
	}
		
	while (ReadFileLine(fileh, g_Msg[g_MessageCount], MESSAGE_BUFFERSIZE))
	{
		g_MessageCount++;
	}
		
	CloseHandle(fileh);
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "timer-physics"))
	{
		g_timerPhysics = true;
	}	
	else if (StrEqual(name, "timer-rankings"))
	{
		g_timerRankings = true;
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
	else if (StrEqual(name, "timer-rankings"))
	{
		g_timerRankings = false;
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
	
	new Float:timewr, wrid, ranktotal;
	if(g_timerWorldRecord) Timer_GetStyleRecordWRStats(style, track, wrid, timewr, ranktotal);
	
	// What kind of record is this?
	
	new bool:ranked, bool:first_world_record, bool:world_record_self, bool:world_record, bool:top_record, bool:first_record, bool:rank_improved, bool:time_improved;
	
	// Is style ranked
	if(g_timerPhysics) ranked = bool:Timer_IsStyleRanked(style);
		
	// First record on this map
	if(timewr == 0.0)
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
	
	decl String:sTrack[32];
	
	if(track == TRACK_NORMAL) sTrack = "Normal";
	else if(track == TRACK_BONUS) sTrack = "Bonus";
	else if(track == TRACK_SHORT) sTrack = "Short";
	
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
	
	strcopy(sStyleName, sizeof(sStyleName), g_Physics[style][StyleName]);
	IntToString(style, sStyleID, sizeof(sStyleID));
	strcopy(sStyleShortName, sizeof(sStyleShortName), g_Physics[style][StyleTagShortName]);
	Format(sStylePointsMul, sizeof(sStylePointsMul), "%.2f", g_Physics[style][StylePointsMulti]);
	
	if(track == TRACK_BONUS)
	{
		IntToString(Timer_GetMapzoneCount(ZtBonusLevel)+1, sStageCount, sizeof(sStageCount));
	} 
	else
	{
		IntToString(Timer_GetMapzoneCount(ZtLevel)+1, sStageCount, sizeof(sStageCount));
	} 
	
	decl String:sChatrank[32];

	sChatrank = "--- TODO ---";
	
	// Get Tier Info
	
	decl String:sTier[8];
	
	new tier = Timer_GetTier(track);
	if(track == TRACK_BONUS) tier = 1;
	IntToString(tier, sTier, sizeof(sTier));

	// Get Tier Multiplier
	
	new Float:tier_scale;
	switch(tier)
	{
		case 1:
			tier_scale = g_Settings[Tier1Scale];
		case 2:
			tier_scale = g_Settings[Tier2Scale];
		case 3:
			tier_scale = g_Settings[Tier3Scale];
		case 4:
			tier_scale = g_Settings[Tier4Scale];
		case 5:
			tier_scale = g_Settings[Tier5Scale];
		case 6:
			tier_scale = g_Settings[Tier6Scale];
		case 7:
			tier_scale = g_Settings[Tier7Scale];
		case 8:
			tier_scale = g_Settings[Tier8Scale];
		case 9:
			tier_scale = g_Settings[Tier9Scale];
		case 10:
			tier_scale = g_Settings[Tier10Scale];
	}
	
	decl String:sTierPointsMul[16];
	Format(sTierPointsMul, sizeof(sTierPointsMul), "%.2f", tier_scale);
	
	// Ranks Info
	
	decl String:sOldRank[8], String:sNewRank[8], String:sTotalRank[16];
	IntToString(currentrank, sOldRank, sizeof(sOldRank));
	IntToString(newrank, sNewRank, sizeof(sNewRank));
	IntToString(ranktotal, sTotalRank, sizeof(sTotalRank));
	
	// Ranks Improved
	
	decl String:sRanksImproved[32];
	IntToString(currentrank-newrank, sRanksImproved, sizeof(sRanksImproved));
	
	// Record Info
	
	decl String:sTime[32], String:sBeatenTime[32], String:sNextTime[32], String:sWrTime[32], String:sOldTime[32];
	new Float:timebeaten,  Float:timenext,  Float:timeold;
	Timer_SecondsToTime(time, sTime, sizeof(sTime), 2);
	Timer_GetRecordTimeInfo(style, track, newrank, timebeaten, sBeatenTime, sizeof(sBeatenTime));
	Timer_GetRecordTimeInfo(style, track, currentrank, timeold, sOldTime, sizeof(sOldTime));
	Timer_GetRecordTimeInfo(style, track, 1, timewr, sWrTime, sizeof(sWrTime));
	if(!world_record) Timer_GetRecordTimeInfo(style, track, newrank-1, timenext, sNextTime, sizeof(sNextTime));
	
	// Jumps / Strafes
	
	new jumpsbeaten, jumpsnext, jumpswr, jumpsold;
	new Float:jumpsaccbeaten, Float:jumpsaccnext, Float:jumpsaccwr, Float:jumpsaccold;
	new strafes, strafesbeaten, strafesnext, strafeswr, strafesold;
	new Float:strafesaccbeaten, Float:strafesaccnext, Float:strafesaccwr, Float:strafesaccold;
	
	decl String:sJumps[32], String:sBeatenJumps[32], String:sNextJumps[32], String:sWrJumps[32], String:sOldJumps[32];
	decl String:sStrafes[32], String:sBeatenStrafes[32], String:sNextStrafes[32], String:sWrStrafes[32], String:sOldStrafes[32];
	
	decl String:sJumpsAcc[32], String:sBeatenJumpsAcc[32], String:sNextJumpsAcc[32], String:sWrJumpsAcc[32], String:sOldJumpsAcc[32];
	decl String:sStrafesAcc[32], String:sBeatenStrafesAcc[32], String:sNextStrafesAcc[32], String:sWrStrafesAcc[32], String:sOldStrafesAcc[32];
	
	if(g_timerStrafes) strafes = Timer_GetStrafeCount(client);
	
	if(g_timerWorldRecord)
	{
		Timer_GetRecordStrafeJumpInfo(style, track, newrank, strafesbeaten, strafesaccbeaten, jumpsbeaten, jumpsaccbeaten);
		if(!world_record) Timer_GetRecordStrafeJumpInfo(style, track, newrank+1, strafesnext, strafesaccnext, jumpsnext, jumpsaccnext);
		Timer_GetRecordStrafeJumpInfo(style, track, 1, strafeswr, strafesaccwr, jumpswr, jumpsaccwr);
		Timer_GetRecordStrafeJumpInfo(style, track, currentrank, strafesold, strafesaccold, jumpsold, jumpsaccold);
	}
	
	IntToString(jumps, sJumps, sizeof(sJumps));
	IntToString(jumpsbeaten, sBeatenJumps, sizeof(sBeatenJumps));
	IntToString(jumpsnext, sNextJumps, sizeof(sNextJumps));
	IntToString(jumpswr, sWrJumps, sizeof(sWrJumps));
	IntToString(jumpsold, sOldJumps, sizeof(sOldJumps));
	
	IntToString(strafes, sStrafes, sizeof(sStrafes));
	IntToString(strafesbeaten, sBeatenStrafes, sizeof(sBeatenStrafes));
	IntToString(strafesnext, sNextStrafes, sizeof(sNextStrafes));
	IntToString(strafeswr, sWrStrafes, sizeof(sWrStrafes));
	IntToString(strafesold, sOldStrafes, sizeof(sOldStrafes));
	
	new Float:jumpsacc;
	Timer_GetJumpAccuracy(client, jumpsacc);
	FloatToString(jumpsacc, sJumps, sizeof(sJumpsAcc));
	FloatToString(jumpsaccbeaten, sBeatenJumps, sizeof(sBeatenJumpsAcc));
	FloatToString(jumpsaccnext, sNextJumps, sizeof(sNextJumpsAcc));
	FloatToString(jumpsaccwr, sWrJumps, sizeof(sWrJumpsAcc));
	FloatToString(jumpsaccold, sOldJumps, sizeof(sOldJumpsAcc));
	
	//FloatToString(strafesacc, sStrafesAcc, sizeof(sStrafesAcc));
	FloatToString(strafesaccbeaten, sBeatenStrafesAcc, sizeof(sBeatenStrafesAcc));
	FloatToString(strafesaccnext, sNextStrafesAcc, sizeof(sNextStrafesAcc));
	FloatToString(strafesaccwr, sWrStrafesAcc, sizeof(sWrStrafesAcc));
	FloatToString(strafesaccold, sOldStrafesAcc, sizeof(sOldStrafesAcc));
	
	
	decl String:sTimeBeatenDiff[32],	String:sTimeNextDiff[32],		String:sTimeWRDiff[32],				String:sTimeDiff[32];
	//Timer_SecondsToTime(time, TimeString, sizeof(TimeString), 2);
	
	sTimeDiff = "--- TODO ---";
	sTimeBeatenDiff = "--- TODO ---";
	sTimeNextDiff = "--- TODO ---";
	sTimeWRDiff = "--- TODO ---";
	
	//Replace msg lines
	
	for (new i = 0; i < g_MessageCount; i++)
	{
		//load msg buffer here
		
		if(StrEqual(g_Msg[i], "", true))
			continue;

		strcopy(Msg[i], sizeof(Msg[]), g_Msg[i]);
		
		// Filter msg lines
		
		if(ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{FILTER_RANKED}", "", true) && !ranked)
			continue;
		if(ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{FILTER_UNRANKED}", "", true) && ranked)
			continue;
		if(ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{FILTER_FIRSTWR}", "", true) && !first_world_record)
			continue;
		if(ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{FILTER_WR_SELF}", "", true) && !world_record_self)
			continue;
		if(ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{FILTER_TOP}", "", true) && !top_record)
			continue;
		if(ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{FILTER_TIME}", "", true) && !time_improved)
			continue;
		if(ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{FILTER_FIRST}", "", true) && !first_record)
			continue;
		if(ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{FILTER_RANK}", "", true) && !rank_improved)
			continue;
		
		// Replace placeholders
		ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{STYLE}", sStyleName, true);
		ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{STYLE_SHORT}", sStyleShortName, true);
		ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{STYLE_ID}", sStyleID, true);
		ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{STYLE_POINTS_MUL}", sStylePointsMul, true);
		
		ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{TRACK}", sTrack, true);
		ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{TIER}", sTier, true);
		ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{TIER_POINTS_MUL}", sTierPointsMul, true);
		
		ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{NAME}", sName, true);
		ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{NAME_BEATEN}", sBeatenName, true);
		ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{NAME_NEXT}", sNextName, true);
		ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{NAME_WR}", sWrName, true);
		
		ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{CHATRANK}", sChatrank, true);
		
		ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{TIME}", sTime, true);
		ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{TIME_BEATEN}", sBeatenTime, true);
		ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{TIME_NEXT}", sNextTime, true);
		ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{TIME_WR}", sWrTime, true);
		ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{TIME_OLD}", sOldTime, true);
		
		ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{JUMPS}", sJumps, true);
		ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{JUMPS_BEATEN}", sBeatenJumps, true);
		ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{JUMPS_NEXT}", sNextJumps, true);
		ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{JUMPS_WR}", sWrJumps, true);
		ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{JUMPS_OLD}", sOldJumps, true);
		
		ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{STRAFES}", sStrafes, true);
		ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{STRAFES_BEATEN}", sBeatenStrafes, true);
		ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{STRAFES_NEXT}", sNextStrafes, true);
		ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{STRAFES_WR}", sWrStrafes, true);
		ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{STRAFES_OLD}", sOldStrafes, true);

		ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{JUMP_ACC}", sJumpsAcc, true);
		ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{JUMP_ACC_BEATEN}", sBeatenJumpsAcc, true);
		ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{JUMP_ACC_NEXT}", sNextJumpsAcc, true);
		ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{JUMP_ACC_WR}", sWrJumpsAcc, true);
		ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{JUMP_ACC_OLD}", sOldJumpsAcc, true);
		
		ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{STRAFE_ACC}", sStrafesAcc, true);
		ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{STRAFE_ACC_BEATEN}", sBeatenStrafesAcc, true);
		ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{STRAFE_ACC_NEXT}", sNextStrafesAcc, true);
		ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{STRAFE_ACC_WR}", sWrStrafesAcc, true);
		ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{STRAFE_ACC_OLD}", sOldStrafesAcc, true);
		
		ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{TIME_DIFF_BEATEN}", sTimeBeatenDiff, true);
		ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{TIME_DIFF_NEXT}", sTimeNextDiff, true);
		ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{TIME_DIFF_WR}", sTimeWRDiff, true);
		ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{TIME_DIFF}", sTimeDiff, true);
		
		ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{OLDRANK}", sOldRank, true);
		ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{NEWRANK}", sNewRank, true);
		ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{TOTALRANK}", sTotalRank, true);
		
		ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{RANKS_IMPROVED}", sRanksImproved, true);
		
		ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{STAGECOUNT}", sStageCount, true);
		
		// fix to show '%' chars in messages
		ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "%", "%%", true);
		
		// Get message type
		new bool:chat = ( ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{OUTPUT_CHAT}", "", true) > 0 );
		new bool:chat_all = ( ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{OUTPUT_CHAT_ALL}", "", true) > 0 );
		new bool:center = ( ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{OUTPUT_CENTER}", "", true) > 0 );
		new bool:center_all = ( ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{OUTPUT_CENTER_ALL}", "", true) > 0 );
		new bool:console = ( ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{OUTPUT_CONSOLE}", "", true) > 0 );
		new bool:server = ( ReplaceString(Msg[i], MESSAGE_BUFFERSIZE, "{OUTPUT_SERVER}", "", true) > 0 );
		
		// Chat
		if(chat_all) CPrintToChatAll(Msg[i]);
		else if(chat) CPrintToChat(client, Msg[i]);
		
		// Remove Tags
		CRemoveTags(Msg[i], sizeof(Msg[]));
		
		// Center Text
		if(center_all) PrintCenterTextAll(Msg[i]);
		else if(center) PrintCenterText(client, Msg[i]);
		
		// Console
		if(console) PrintToConsole(client, Msg[i]);	// Player console
		if(server) PrintToServer(Msg[i]); // Server console
	}
}