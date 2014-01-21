#pragma semicolon 1

#include <sourcemod>
#include <timer>
#include <timer-config_loader.sp>

public Plugin:myinfo = 
{
	name = "Timer: Finish Exec",
	author = "Zipcore",
	description = "Execute a command on new player record",
	version = "1.0",
	url = "zipcre#googlemail.com"
}

public OnPluginStart()
{
	LoadPhysics();
	LoadTimerSettings();
}

public OnMapStart()
{
	LoadPhysics();
	LoadTimerSettings();
}

public OnTimerRecord(client, bonus, mode, Float:time, Float:lasttime, currentrank, newrank)
{
	new String:buffer[512];
	decl String:auth[32];
	GetClientAuthString(client, auth, sizeof(auth));
	decl String:name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));
	
	Format(buffer, sizeof(buffer), "%s", g_Physics[mode][ModeOnFinishExec]);
	
	ReplaceString(buffer, sizeof(buffer), "{steamid}", auth, true);
	ReplaceString(buffer, sizeof(buffer), "{playername}", name, true);
	
	ServerCommand(buffer);
}
