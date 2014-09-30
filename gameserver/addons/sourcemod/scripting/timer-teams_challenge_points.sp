#include <sourcemod>
#include <timer>
#include <timer-physics>
#include <timer-teams>
#include <timer-rankings>

new g_iBet[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "[Timer] Challenge Points Lite",
	author = "Zipcore",
	description = "[Timer] Take points from looser on challenge win and give them to winner",
    version     = PL_VERSION,
    url         = "forums.alliedmods.net/showthread.php?p=2074699"
}

public OnChallengeConfirm(client, mate, bet)
{
	g_iBet[client] = bet;
	g_iBet[mate] = bet;
	CPrintToChatAll("%s %N has confirmed a challenge with %N for %d points.", PLUGIN_PREFIX2, client, mate, g_iBet[mate]);
}

public OnChallengeWin(winner, loser)
{
	Timer_AddPoints(winner, g_iBet[winner]);
	Timer_SavePoints(winner);
	Timer_RemovePoints(loser, g_iBet[winner]);
	Timer_SavePoints(loser);
	CPrintToChatAll("%s %N has beaten %N and has taken %d points.", PLUGIN_PREFIX2, winner, loser, g_iBet[winner]);
}