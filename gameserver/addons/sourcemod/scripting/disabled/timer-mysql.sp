#pragma semicolon 1
#include <timer-logging>

#undef REQUIRE_PLUGIN
#include <timer>

public Plugin:myinfo =
{
    name        = "[Timer] MySQL Manager",
    author      = "Zipcore",
    description = "MySQL manager component for [Timer]",
    version     = PL_VERSION,
    url         = "zipcore#googlemail.com"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RegPluginLibrary("timer-mysql");
	
	//CreateNative("Timer_MysqlGetHandle", Native_MysqlGetHandle);
	//CreateNative("Timer_MysqlGetStatus", Native_MysqlGetStatus);

	return APLRes_Success;
}
	