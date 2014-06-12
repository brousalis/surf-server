#if defined _timer_teams_included
 #endinput
#endif
#define _timer_teams_included

//Team modes
#define TEAMMODE_NONE					0
#define TEAMMODE_CHALLENGE				1
#define TEAMMODE_COOP					2

/* Forwards */
forward OnCoopStart(player1,player2);
forward OnCoopConfirm(player1,player2);
forward OnCoopWin(player1,player2);
forward OnCoopForceEnd(player1,player2);

forward OnChallengeStart(client, mate);
forward OnChallengeConfirm(client, mate, bet);
forward OnChallengeWin(winner,loser);
forward OnChallengeForceEnd(winner,loser);

/* Natives */
native Timer_GetClientTeammate(client);
native Timer_SetClientTeammate(client, mate, teleport);

native Timer_GetCoopStatus(client);
native Timer_GetChallengeStatus(client);
	
public SharedPlugin:__pl_timer_teams = 
{
	name = "timer-teams",
	file = "timer-teams.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

public __pl_timer_teams_SetNTVOptional() 
{
	MarkNativeAsOptional("Timer_GetClientTeammate");
	MarkNativeAsOptional("Timer_SetClientTeammate");
	MarkNativeAsOptional("Timer_GetCoopStatus");
	MarkNativeAsOptional("Timer_GetChallengeStatus");
}