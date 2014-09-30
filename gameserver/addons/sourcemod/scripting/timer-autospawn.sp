#include <sourcemod>
#include <cstrike>
#include <timer>

new Handle:Spawn_Timer[MAXPLAYERS+1];
new Handle:Check_Timer[MAXPLAYERS+1];

new g_SpawnBlocked;

public Plugin:myinfo = 
{

	name = "[Timer] Autospawn",
	author = "Zipcore, Credits: Das D",
	version = PL_VERSION,
	description = "",
	url = "forums.alliedmods.net/showthread.php?p=2074699"
};

public OnPluginStart() 
{
	HookEvent("player_team", Event_ChangeTeam, EventHookMode_Post);
	RegConsoleCmd("joinclass", Command_JoinClass);
}

public Action:Event_ChangeTeam(Handle:event,const String:name[],bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client != 0){
		Check_Timer[client] = CreateTimer( 1.0, TeamAlive_Check, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:TeamAlive_Check(Handle:timer, any:client){
	if(IsClientInGame(client) && !IsPlayerAlive(client) && (GetClientTeam(client) == 2 || GetClientTeam(client) == 3)){
		Check_Timer[client] = INVALID_HANDLE;
		g_SpawnBlocked = 0;
		Spawn_Timer[client] = CreateTimer( 1.0, Do_Spawn, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	else{
		Check_Timer[client] = INVALID_HANDLE;
		g_SpawnBlocked = 0;
	}
}

public Action:Do_Spawn(Handle:timer, any:client){
	if(client != 0 && IsClientInGame(client) && !IsPlayerAlive(client) && (GetClientTeam(client) == 2 || GetClientTeam(client) == 3)){
		g_SpawnBlocked = 1;
		CS_RespawnPlayer(client);
		Spawn_Timer[client] = INVALID_HANDLE;
	}
	else{
		Spawn_Timer[client] = INVALID_HANDLE;
	}
}

public Action:Command_JoinClass(client, args)
{
	if(g_SpawnBlocked == 1)
	{
		FakeClientCommandEx(client, "spec_mode");
		return Plugin_Handled;
	}
	else
	{
		return Plugin_Continue;
	}
}

public OnClientDisconnect(client)
{
	if(Spawn_Timer[client] != INVALID_HANDLE){
		CloseHandle(Spawn_Timer[client]);
		Spawn_Timer[client] = INVALID_HANDLE;
	}
	if(Check_Timer[client] != INVALID_HANDLE){
		CloseHandle(Check_Timer[client]);
		Check_Timer[client] = INVALID_HANDLE;
	}
}

public Action:Command_Say(client, args) {
	if(client == 0 && !IsDedicatedServer())
		client = 1;
	
	if(client < 1)
		return Plugin_Continue;
		
	decl String:command[32], String:value[32];
	
	GetCmdArg(0, command, sizeof(command));
	GetCmdArg(1, value, sizeof(value));
	
	if(StrEqual(value, "spawn") || StrEqual(value, "respawn") || StrEqual(value, "redie") || StrEqual(value, "!spawn") || StrEqual(value, "!respawn") || StrEqual(value, "!redie")) {
		new team = GetClientTeam(client);
		
		if(team != CS_TEAM_CT && team != CS_TEAM_T) {
			PrintToChat(client, "\x04This command is not available to spectators.");
			return Plugin_Handled;
		}
		
		if(IsPlayerAlive(client)) {
			PrintToChat(client, "\x04You are alive, dont bug me!!!");
			return Plugin_Handled;
		}
		
		CS_RespawnPlayer(client);
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public OnPluginEnd()
{
	UnhookEvent("player_team", Event_ChangeTeam);
}
