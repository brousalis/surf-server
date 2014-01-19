public SharedPlugin:__pl_jsljstats = 
{
	name = "timer-ljstats",
	file = "timer-ljstats.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};
 
public __pl_jsljstats_SetNTVOptional()
{
	MarkNativeAsOptional("IsClientInLJMode");
	MarkNativeAsOptional("SetLJMode");
	MarkNativeAsOptional("HookClientLJMode");
	MarkNativeAsOptional("SetInValidJump");
}
/**
 * client is in long jump mode?
 *
 * @param client		index of client.
 * @return bool		true on ljmode
 */
native bool:IsClientInLJMode(client);

/**
 * set client jump stat as a invalid.(when used checkpoint function, etc.)
 *
 * @param client		index of client.
 * @noreturn
 */
native SetInValidJump(client);

/**
 * client is in long jump mode?
 *
 * @param client		index of client.
 * @param bool		if true, ljmode on.
 * @noreturn
 */
native SetLJMode(client, bool:on);

forward Action:OnClientLJModeChanged(client, bool:on);
// functag OnClientLJModeChangedFunc Action:public(client, bool:on);

// /**
// * Calls the target function when a client changed ljmode.
// *
// * @param func    OnClientLJModeChangedFunc function.
// * @noreturn
// */
// native HookClientLJMode(OnClientLJModeChangedFunc:func);
