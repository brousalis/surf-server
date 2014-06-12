#if defined _timer_worldrecord_included
 #endinput
#endif
#define _timer_worldrecord_included

/* Natives */
native Timer_ForceReloadCache();
native Timer_GetStyleRecordTime(style, track, &cacheid, &Float:time, &total);
native Timer_GetNewPossibleRank(style, track, Float:time);
native Timer_GetRankID(style, track, rank);

native bool:Timer_GetBestRound(client, style, track, &Float:time, &jumps);
native Timer_GetStyleTotalRank(style, track);
native Timer_GetStyleRank(client, track, style);
native Timer_GetRecordHolderName(style, track, rank, String:name[], length);
native Timer_GetFinishCount(style, track, rank);
native Timer_GetRecordDate(style, track, rank, String:date[], length);
native Timer_GetRecordTimeInfo(style, track, rank, &Float:time, String:timestring[], length);
native Timer_GetRecordSpeedInfo(style, track, rank, &Float:avgspeed, &Float:maxspeed, &Float:finishspeed);
native Timer_GetRecordStrafeJumpInfo(style, track, rank, &strafes, &Float:strafeacc, &jumps, &Float:jumpacc);
native Timer_GetReplayPath(style, track, rank, String:replay_path[], length);
native Timer_GetRecordCustom1(style, track, rank, String:custom1[], length);
native Timer_GetRecordCustom2(style, track, rank, String:custom2[], length);
native Timer_GetRecordCustom3(style, track, rank, String:custom3[], length);
	
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
	MarkNativeAsOptional("Timer_GetStyleRecordTime");
	MarkNativeAsOptional("Timer_GetNewPossibleRank");
	MarkNativeAsOptional("Timer_GetStyleRank");
	MarkNativeAsOptional("Timer_GetStyleTotalRank");
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