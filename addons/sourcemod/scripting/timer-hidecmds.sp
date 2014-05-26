#include <sourcemod>
 
public Plugin:myinfo =
{
        name = "Hide Commands",
        author = "Rop",
        description = "hides chat commands",
        version = "0.1",
        url = "nope"
}
 
public OnPluginStart()
{
        AddCommandListener(HideCommands,"say")
        AddCommandListener(HideCommands,"say_team")
}
 
public Action:HideCommands(client, const String:command[], argc)
{
        if(IsChatTrigger())
                return Plugin_Handled
       
        return Plugin_Continue
}