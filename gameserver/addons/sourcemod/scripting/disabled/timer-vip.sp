#include <sourcemod>
#include <cstrike>
#include <timer>
#include <timer-stocks>
#include <timer-config_loader.sp>

public Plugin:myinfo = 
{
	name = "[Timer] Top 10 VIP",
	author = "Zipcore",
	description = "",
	version = "1.0",
	url = "zipcore#googlemail.com"
};

new bool:g_bVIP[MAXPLAYERS+1];

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

public OnClientRankLoaded(client, rank)
{
	if(0 < rank <= 10)
		g_bVIP[client] = true;
	else g_bVIP[client] = false;
}