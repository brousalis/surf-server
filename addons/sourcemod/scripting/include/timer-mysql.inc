#if defined _timer_mysql_included
 #endinput
#endif
#define _timer_mysql_included


/* Forwards */

/**
 * Called when the sql connection handle will be announced
 *
 * @param sql The database handle.
 * @noreturn
 */
forward OnTimerSqlConnected(Handle:sql);

/**
 * Called when the sql connection handle will be closed
 *
 * @noreturn
 */
forward OnTimerSqlStop();

/**
 * Get MySQL database connection Handle
 * 
 * return The database connection handle
 */
native Timer_SqlGetConnection();

public __pl_timer_mysql_SetNTVOptional() 
{
	MarkNativeAsOptional("Timer_SqlGetConnection");
}