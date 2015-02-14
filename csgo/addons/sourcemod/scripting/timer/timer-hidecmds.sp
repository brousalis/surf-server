#include <sourcemod>
#include <timer>
 
public Plugin:myinfo =
{
	name = "[Timer] Hide Commands",
	author = "Rop",
	description = "hides chat commands",
	version = PL_VERSION,
	url = "https://github.com/Zipcore/Timer"
}
 
public OnPluginStart()
{
	AddCommandListener(HideCommands,"say");
	AddCommandListener(HideCommands,"say_team");
}
 
public Action:HideCommands(client, const String:command[], argc)
{
	if(IsChatTrigger())
		return Plugin_Handled;
   
	return Plugin_Continue;
}