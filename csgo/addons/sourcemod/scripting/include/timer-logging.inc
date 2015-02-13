#if defined _timer_logging_included
 #endinput
#endif
#define _timer_logging_included

/**
 * Logging levels
 */
enum Timer_LogLevel {
	Timer_LogLevelNone = 0,  /**< Logging disabled */
	Timer_LogLevelError,     /**< Log only errors */
	Timer_LogLevelWarning,   /**< Log errors and warnings */
	Timer_LogLevelInfo,      /**< Log errors, warnings and info messages */
	Timer_LogLevelDebug,     /**< Log errors, warnings, info and debug messages */
	Timer_LogLevelTrace      /**< Log errors, warnings, info, debug and trace messages */
};

/**
 * Returns the current logging level.
 *
 * @return              Current logging level
 */
native Timer_LogLevel:Timer_GetLogLevel();

/**
 * Logs a message to the Timer log file. Depending on the log level provided, this is equivalent
 * to calling any of the logging functions below (Timer_LogError(), Timer_LogWarning(), etc).
 *
 * @param log_level     The severity of the message being logged.
 * @param format        A format string. See http://wiki.alliedmods.net/Format_Class_Functions_(SourceMod_Scripting)
 * @param ...           Variable number of format parameters.
 * @noreturn
 */
native Timer_Log(Timer_LogLevel:log_level, const String:format[] , any:...);

/**
 * Logs an error message to the Timer log file. Error logs are either fatal unrecoverable errors
 * or notifications about major problems that significantly hinder a plugin's functionality. For
 * example, not being able to connect to the Timer service.
 *
 * @param format        A format string. See http://wiki.alliedmods.net/Format_Class_Functions_(SourceMod_Scripting)
 * @param ...           Variable number of format parameters.
 * @noreturn
 */
native Timer_LogError(const String:format[] , any:...);

/**
 * Logs a warning message to the Timer log file. Warnings should notify the server operator of
 * malfunctions that are not critical to the plugin's operation but do require attention. For
 * example, too much text disaplyed in a menu (and truncated).
 *
 * @param format        A format string. See http://wiki.alliedmods.net/Format_Class_Functions_(SourceMod_Scripting)
 * @param ...           Variable number of format parameters.
 * @noreturn
 */
native Timer_LogWarning(const String:format[] , any:...);

/**
 * Logs an info message to the Timer log file. Info messages should enable the server operator
 * to drill in and track activity that occured on his server in details. For example, client
 * dis/connections, client billing operations, awards granted to clients, etc.
 *
 * @param format        A format string. See http://wiki.alliedmods.net/Format_Class_Functions_(SourceMod_Scripting)
 * @param ...           Variable number of format parameters.
 * @noreturn
 */
native Timer_LogInfo(const String:format[] , any:...);

/**
 * Logs a debug message to the Timer log file. Debug logs are low-level messages primarily used
 * by developers to debug the execution of their plugins. Debug logs typically describe the
 * parameters and outcome of some algorithmic computation, or some event that occured. Debug logs
 * may generate large volumes of data.
 *
 * @param format        A format string. See http://wiki.alliedmods.net/Format_Class_Functions_(SourceMod_Scripting)
 * @param ...           Variable number of format parameters.
 * @noreturn
 */
native Timer_LogDebug(const String:format[] , any:...);



/**
 * Logs a particularly low-level trace message to the Timer log file. Trace logs are low-level
 * messages primarily used by developers to trace the execution of their plugins. They typically
 * describe a position in the code and the value of surrounding parameters. Trace logs WILL generate
 * large volumes of data quickly.
 *
 * @param format        A format string. See http://wiki.alliedmods.net/Format_Class_Functions_(SourceMod_Scripting)
 * @param ...           Variable number of format parameters.
 * @noreturn
 */
native Timer_LogTrace(const String:format[] , any:...);

public SharedPlugin:__pl_timer_logging = 
{
	name = "timer-logging",
	file = "timer-logging.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

public __pl_timer_logging_SetNTVOpt() 
{
	MarkNativeAsOptional("Timer_GetLogLevel");
	MarkNativeAsOptional("Timer_Log");
	MarkNativeAsOptional("Timer_LogError");
	MarkNativeAsOptional("Timer_LogWarning");
	MarkNativeAsOptional("Timer_LogInfo");
	MarkNativeAsOptional("Timer_LogDebug");
	MarkNativeAsOptional("Timer_LogDebug2");
}
