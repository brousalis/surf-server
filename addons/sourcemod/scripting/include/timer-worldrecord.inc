#if defined _timer_worldrecord_included
 #endinput
#endif
#define _timer_worldrecord_included

/* Forwards */

/**
 * Called when all records are loaded from the database.
 * @param style
 * @param track
 *
 * @noreturn
 */
forward OnRecordCacheLoaded(style, track);

/* Natives */

/**
 * Refetch the world records from the database.
 * @noreturn
 */
native Timer_ForceReloadCache();

/**
 * Returns world record stats for a given style and track.
 *
 * @param style
 * @param track
 * @param cacheid A reference to the cacheid of the world record.
 * @param time A reference to the record time of the world record.
 * @param total A reference to the total amount of record of style & track.
 *
 * @noreturn
 */
native Timer_GetStyleRecordWRStats(style, track, &cacheid, &Float:time, &total);

/**
 * Returns a possible rank for a given time
 *
 * @param style
 * @param track
 * @param time
 *
 * @return The possible rank
 */
native Timer_GetNewPossibleRank(style, track, Float:time);

/**
 * Returns a database Id for given style/track/rank
 *
 * @param style
 * @param track
 * @param rank
 *
 * @return The database ID
 */
native Timer_GetRankID(style, track, rank);

/**
 * Returns world record stats for a given style and track.
 *
 * @param client
 * @param style
 * @param track
 * @param time A reference to the record time.
 * @param jumps A reference to the total amount of jumps.
 *
 * @return True if success
 */
native bool:Timer_GetBestRound(client, style, track, &Float:time, &jumps);

/**
 * Returns a total amount of records for given style/track/rank
 *
 * @param style
 * @param track
 * @param rank
 *
 * @return The total amount of records
 */
native Timer_GetStyleTotalRank(style, track);

/**
 * Returns a record rank for a client
 *
 * @param client
 * @param style
 * @param track
 *
 * @return The current record rank (0 for no record)
 */
native Timer_GetStyleRank(client, track, style);

/**
 * Returns a record holder nickname for a given style/track/rank
 *
 * @param style
 * @param track
 * @param rank
 * @param name A reference to the record holder name.
 * @param length Name reference string length (max 32)
 *
 * @return True if success
 */
native Timer_GetRecordHolderName(style, track, rank, String:name[], length);

/**
 * Returns a record holder nickname for a given style/track/rank
 *
 * @param style
 * @param track
 * @param rank
 * @param name A reference to the record holder SteamID.
 * @param length SteamID reference string length (max 32)
 *
 * @return True if success
 */
native Timer_GetRecordHolderAuth(style, track, rank, String:name[], length);

/**
 * Returns a total amount of finishes for given style/track/rank
 *
 * @param style
 * @param track
 * @param rank
 *
 * @return The total amount of records
 */
native Timer_GetFinishCount(style, track, rank);

/**
 * Returns a record formatted data for a given style/track/rank
 *
 * @param style
 * @param track
 * @param rank
 * @param date A reference to the record date.
 * @param length Date reference string length (max 32)
 *
 * @return True if success
 */
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
	MarkNativeAsOptional("Timer_GetStyleRecordWRStats");
	MarkNativeAsOptional("Timer_GetNewPossibleRank");
	MarkNativeAsOptional("Timer_GetStyleRank");
	MarkNativeAsOptional("Timer_GetStyleTotalRank");
	MarkNativeAsOptional("Timer_GetBestRound");
	MarkNativeAsOptional("Timer_GetRankID");
	MarkNativeAsOptional("Timer_GetRecordHolderName");
	MarkNativeAsOptional("Timer_GetRecordHolderAuth");
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