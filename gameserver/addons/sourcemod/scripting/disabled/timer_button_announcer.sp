#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <morecolors>
#include <timer>

public OnPluginStart()
{
	HookEntityOutput( "func_button", "OnPressed", pressed);
	HookEntityOutput( "func_button", "OnDamaged", damaged);
}

public OnMapStart()
{
	HookEntityOutput( "func_button", "OnPressed", pressed);
	HookEntityOutput( "func_button", "OnDamaged", damaged);
}

public OnMapEnd()
{
	UnhookEntityOutput( "func_button", "OnPressed", pressed);
	UnhookEntityOutput( "func_button", "OnDamaged", damaged);
}


public damaged(const String:output[], caller, attacker, Float:Any)
{
	if(Client_IsValid(attacker, true)) CPrintToChat(attacker, "%s {yellow}You have shot a button.", PLUGIN_PREFIX2);
}

public pressed(const String:output[], caller, attacker, Float:Any)
{
	if(Client_IsValid(attacker, true) && Client_HasButtons(attacker, IN_USE)) CPrintToChat(attacker, "%s {yellow}You have pressed a button.", PLUGIN_PREFIX2);
}