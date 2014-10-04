#if defined _timer_physics_included
 #endinput
#endif
#define _timer_physics_included


/* Forwards */

/**
 * Called when the sql connection handle will be announced
 *
 * @param sql The database handle.
 * @noreturn
 */
forward OnTimerSqlUpdate(Handle:sql);

/**
 * Called when the sql connection handle will be closed
 *
 * @noreturn
 */
forward OnTimerSqlStop();

public __pl_timer_mysql_SetNTVOptional() 
{
	//
}