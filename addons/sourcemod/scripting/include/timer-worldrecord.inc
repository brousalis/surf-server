#if defined _timer_worldrecord_included
 #endinput
#endif
#define _timer_worldrecord_included

/* Natives */
native Timer_ForceReloadCache();
native Timer_GetDifficultyRecordTime(mode, bonus, &cacheid, &Float:time, &total);
native Timer_GetNewPossibleRank(mode, bonus, Float:time);
native Timer_GetRankID(mode, bonus, rank);

native bool:Timer_GetBestRound(client, mode, bonus, &Float:time, &jumps);
native Timer_GetDifficultyTotalRank(mode, bonus);
native Timer_GetDifficultyRank(client, bonus, mode);
native Timer_GetRecordHolderName(mode, bonus, rank, String:name[], length);
native Timer_GetFinishCount(mode, bonus, rank);
native Timer_GetRecordDate(mode, bonus, rank, String:date[], length);
native Timer_GetRecordTimeInfo(mode, bonus, rank, &Float:time, String:timestring[], length);
native Timer_GetRecordSpeedInfo(mode, bonus, rank, &Float:avgspeed, &Float:maxspeed, &Float:finishspeed);
native Timer_GetRecordStrafeJumpInfo(mode, bonus, rank, &strafes, &Float:strafeacc, &jumps, &Float:jumpacc);
native Timer_GetReplayPath(mode, bonus, rank, String:replay_path[], length);
native Timer_GetRecordCustom1(mode, bonus, rank, String:custom1[], length);
native Timer_GetRecordCustom2(mode, bonus, rank, String:custom2[], length);
native Timer_GetRecordCustom3(mode, bonus, rank, String:custom3[], length);
	
public SharedPlugin:__pl_timer_worldrecord = 
{
	name = "timer-worldrecord",
	file = "timer-worldrecord.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

public __pl_timer_worldrecord_SetNTVOptional() 
{
	MarkNativeAsOptional("Timer_ForceReloadCache");
	MarkNativeAsOptional("Timer_GetDifficultyRecordTime");
	MarkNativeAsOptional("Timer_GetNewPossibleRank");
	MarkNativeAsOptional("Timer_GetDifficultyRank");
	MarkNativeAsOptional("Timer_GetDifficultyTotalRank");
	MarkNativeAsOptional("Timer_GetBestRound");
	MarkNativeAsOptional("Timer_GetRankID");
	MarkNativeAsOptional("Timer_GetRecordHolderName");
	MarkNativeAsOptional("Timer_GetFinishCount");
	MarkNativeAsOptional("Timer_GetRecordDate");
	MarkNativeAsOptional("Timer_GetRecordTimeInfo");
	MarkNativeAsOptional("Timer_GetRecordSpeedInfo");
	MarkNativeAsOptional("Timer_GetRecordStrafeJumpInfo");
	MarkNativeAsOptional("Timer_GetReplayPath");
	MarkNativeAsOptional("Timer_GetRecordCustom1");
	MarkNativeAsOptional("Timer_GetRecordCustom2");
	MarkNativeAsOptional("Timer_GetRecordCustom3");
}