#if defined _timer_rankings_included
 #endinput
#endif
#define _timer_rankings_included

/* Forwards */

/**
 * Called when a player receives points.
 * @param client
 * @param points
 * @param added
 *
 * @noreturn
 */
forward OnPlayerGainPoints(client, points, added);  

/**
 * Called when a player loses points.
 * @param client
 * @param points
 * @param removed
 *
 * @noreturn
 */
forward OnPlayerLostPoints(client, points, removed);  

/**
 * Called when an admin sets a player's points.
 * @param client
 * @param points
 * @param removed
 *
 * @noreturn
 */
forward OnPlayerSetPoints(client, points, old);  

/**
 * Called when a player's points are loaded from the database.
 * @param client
 * @param points
 * @param removed
 *
 * @noreturn
 */
forward OnPlayerPointsLoaded(client, points);  

/**
 * Called when a player's rank are loaded from the database.
 * @param client
 * @param points
 * @param removed
 *
 * @noreturn
 */
forward OnPlayerRankLoaded(client, rank);  

/* Natives */

/**
 * Returns the player's current points.
 * @param client
 *
 * @return Points
 */
native Timer_GetPoints(client);

/**
 * Returns the player's current rank in the server.
 * @param client
 *
 * @return rank
 */
native Timer_GetPointRank(client);

/**
 * Stores the player's tag in the buffer provided.
 * @param buffer
 * @param maxlen
 * @param client
 *
 * @noreturn
 */
native Timer_GetTag(String:tag[], size, client);

/**
 * Stores the player's tag including the defined chat colors in the buffer provided.
 * @param buffer
 * @param maxlen
 * @param client
 *
 * @noreturn
 */
native Timer_GetChatTag(String:tag[], size, client);

/**
 * Sets the player's points to the number defined.
 * @param client
 * @param points
 *
 * @noreturn
 */
native Timer_SetPoints(client, points);

/**
 * Adds the number defined to the player's total points.
 * @param client
 * @param points
 *
 * @noreturn
 */
native Timer_AddPoints(client, points);

/**
 * Decreases a player's points by the number defined.
 * @param client
 * @param points
 *
 * @noreturn
 */
native Timer_RemovePoints(client, points);

/**
 * Saves the player's points in the database.
 * @param client
 *
 * @noreturn
 */
native Timer_SavePoints(client);

/**
 * Refreshes a player's points from the database.
 * @param client
 *
 * @noreturn
 */
native Timer_RefreshPoints(client);

/**
 * Refreshes all players' points from the database.
 *
 * @noreturn
 */
native Timer_RefreshPointsAll();
	
public SharedPlugin:__pl_timer_rankings = 
{
	name = "timer-rankings",
	file = "timer-rankings.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

public __pl_timer_rankings_SetNTVOptional() 
{
	MarkNativeAsOptional("Timer_GetPoints");
	MarkNativeAsOptional("Timer_GetPointRank");
	MarkNativeAsOptional("Timer_GetTag");
	MarkNativeAsOptional("Timer_GetChatTag");
	MarkNativeAsOptional("Timer_SavePoints");
	MarkNativeAsOptional("Timer_AddPoints");
	MarkNativeAsOptional("Timer_SetPoints");
	MarkNativeAsOptional("Timer_RemovePoints");
	MarkNativeAsOptional("Timer_RefreshPoints");
	MarkNativeAsOptional("Timer_RefreshPointsAll");
}