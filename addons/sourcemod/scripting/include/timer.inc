#if defined _timer_included
 #endinput
#endif
#define _timer_included

#pragma semicolon 1

#define PL_VERSION		"2.1.1"

/*** SETTINGS ***/

//Uncomment this to use colors.inc and disable morecolors.inc
//#define LEGACY_COLORS "CS:GO Color Support"

//Max number of styles (default 32 ID:0-31)
#define MAX_MODES	32

//Max. number of door/button based bhop blocks handled in a map
#define MAX_BHOPBLOCKS	1024

/*** DON'T CHANGE ***/

#define TRACK_NORMAL 				0
#define TRACK_BONUS 				1
#define TRACK_SHORT 				2

//Team modes
#define TEAMMODE_NONE					0
#define TEAMMODE_CHALLENGE				1
#define TEAMMODE_COOP					2
#define TEAMMODE_RACE					3
#define TEAMMODE_TRIKZ					4

//Colors Includes
#if defined LEGACY_COLORS
#include <colors>			//https://forums.alliedmods.net/showpost.php?p=1883578&postcount=311
#define PLUGIN_PREFIX " {lightred}[{green}Timer{lightred}] %t"
#define PLUGIN_PREFIX2 " {lightred}[{green}Timer{lightred}]"
#else
#include <morecolors>		//https://www.doctormckay.com/download/scripting/include/morecolors.inc
#define PLUGIN_PREFIX "{green}[Timer] %t"
#define PLUGIN_PREFIX2 "{green}[Timer]"
#endif

//Max-Length
#define PLUGIN_NAME_RESERVED_LENGTH 33
#define CONVAR_MAX_LEN 512

//Cstrike
#define CS_TEAMS_NUM 4
#define CS_SLOT_KNIFE 2
#define ITEMS_TYPES_NUM 10
#define ITEMS_STR_LEN 32
#define MAX_CASH 16000

//Specmodes
#define SPECMODE_NONE 					0
#define SPECMODE_FIRSTPERSON 			4
#define SPECMODE_3RDPERSON 				5
#define SPECMODE_FREELOOK	 			6

//Start commands
#define SCMD_START						0
#define SCMD_RESTART					1
#define SCMD_BONUSSTART					2

//Func_ Flags
#define SF_BUTTON_DONTMOVE				(1<<0)		//dont move when fired (func_button)
#define SF_BUTTON_TOUCH_ACTIVATES		(1<<8)		//button fires when touched (func_button)
#define SF_DOOR_PTOUCH					(1<<10)		//player touch opens (func_door)

//Jump Stamina, can reduce landing speed loss and increase max jump high to engine limit
#define STAMINA_DISABLED				-1.0
#define STAMINA_FULL					0.0

#define MAX_FILE_LEN 128

#define	DAMAGE_NO						0
#define DAMAGE_EVENTS_ONLY				1				// Call damage functions, but don't modify health
#define	DAMAGE_YES						2
#define	DAMAGE_AIM						3

#define COLLISION_GROUP_DEBRIS_TRIGGER	2		//Noblock
#define COLLISION_GROUP_PLAYER			5		//Block
#define COLLISION_GROUP_PUSHAWAY		17		//Push away collision

enum FX
{
	FxNone = 0,
	FxPulseFast,
	FxPulseSlowWide,
	FxPulseFastWide,
	FxFadeSlow,
	FxFadeFast,
	FxSolidSlow,
	FxSolidFast,
	FxStrobeSlow,
	FxStrobeFast,
	FxStrobeFaster,
	FxFlickerSlow,
	FxFlickerFast,
	FxNoDissipation,
	FxDistort,					// Distort/scale/translate flicker
	FxHologram,					// kRenderFxDistort + distance fade
	FxExplode,					// Scale up really big!
	FxGlowShell,				// Glowing Shell
	FxClampMinScale,			// Keep this sprite from getting very small (SPRITES only!)
	FxEnvRain,					// for environmental rendermode, make rain
	FxEnvSnow,					// for environmental rendermode, make snow
	FxSpotlight,
	FxRagdoll,
	FxPulseFastWider,
}

enum Render
{
	Normal = 0, 				// src
	TransColor, 				// c*a+dest*(1-a)
	TransTexture,				// src*a+dest*(1-a)
	Glow,						// src*a+dest -- No Z buffer checks -- Fixed size in screen space
	TransAlpha,					// src*srca+dest*(1-srca)
	TransAdd,					// src*a+dest
	Environmental,				// not drawn, used for environmental effects
	TransAddFrameBlend,			// use a fractional frame value to blend between animation frames
	TransAlphaAdd,				// src + dest*(1-a)
	WorldGlow,					// Same as kRenderGlow but not fixed size in screen space
	None,						// Don't render.
}

enum VelocityOverride {
	
	VelocityOvr_None = 0,
	VelocityOvr_Velocity,
	VelocityOvr_OnlyWhenNegative,
	VelocityOvr_InvertReuseVelocity
}

enum MCategory {
	
	MCategory_Ranked = 0,
	MCategory_Fun,
	MCategory_Practise
}

enum MapZoneType
{
    ZtStart,
    ZtEnd,
    ZtStop,
    ZtRestart,
    ZtLast,
    ZtNext,
	ZtLevel,
    ZtBonusStart,
    ZtBonusEnd,
    ZtBonusLevel,
    ZtNPC_Next,
	ZtBlock,
	ZtLimitSpeed,
	ZtPlayerClip, //buggy
	ZtLongjump,
	ZtBooster,
	ZtFullBooster,
	ZtArena,
	ZtBounceBack, //buggy
	ZtJail,
	ZtPushUp,
	ZtBulletTime,
	ZtNoGravityOverwrite,
	ZtNPC_Next_Double,
	ZtNoBoost,
	ZtRestartNormalTimer,
	ZtRestartBonusTimer,
	ZtShortEnd,
	ZtPushNorth,
	ZtPushSouth,
	ZtPushWest,
	ZtPushEast,
	ZtPushDown,
	ZtAuto,
	ZtNoAuto,
	ZtHover,
	ZtReset,
	ZtFreeStyle
}

enum MapZone
{
    Id,
    MapZoneType:Type,
    String:Map[32],
    Float:Point1[3],
    Float:Point2[3],
    Level_Id,
	String:zName[32],
	NPC
}

enum
{
	MODE_NORMAL = 0,
	MODE_SIDEWAYS,
	MODE_EASY,
	MODE_AUTO,
	MODE_ONLYW,
	MODE_BACKWARDS,
	MODE_AUTO_NOBOOST,
	MODE_THIRDPERSON,
	MODE_FPSMAX,
	MODE_LOWGRAV,
	MODE_SKITTLES,
	MODE_MULTIHOP,
	MODE_NOHOP,
	MODE_CUSTOM
}

forward OnTimerStarted(client);
forward OnTimerStopped(client);
forward OnTimerReseted(client);
forward OnTimerRestart(client);
forward OnTimerPaused(client);
forward OnTimerResumed(client);

forward OnTimerWorldRecord(client, bonus, mode, Float:time, Float:lasttime, currentrank, newrank);
forward OnTimerPersonalRecord(client, bonus, mode, Float:time, Float:lasttime, currentrank, newrank);
forward OnTimerTop10Record(client, bonus, mode, Float:time, Float:lasttime, currentrank, newrank);
forward OnTimerFirstRecord(client, bonus, mode, Float:time, Float:lasttime, currentrank, newrank);
forward OnTimerRecord(client, bonus, mode, Float:time, Float:lasttime, currentrank, newrank);

forward OnClientStartTouchZoneType(client, MapZoneType:type);
forward OnClientEndTouchZoneType(client, MapZoneType:type);

forward OnClientMaxJumpHeight(client, Float:height);

forward OnCoopStart(player1,player2);
forward OnCoopConfirm(player1,player2);
forward OnCoopWin(player1,player2);
forward OnCoopForceEnd(player1,player2);

forward OnChallengeStart(client,mate);
forward OnChallengeConfirm(client,mate);
forward OnChallengeWin(winner,loser);
forward OnChallengeForceEnd(winner,loser);

native bool:Timer_Reset(client);
native bool:Timer_Start(client);
native bool:Timer_Stop(client, bool:stopPaused = true);
native bool:Timer_Resume(client);
native bool:Timer_Pause(client);
native bool:Timer_Restart(client);
native bool:Timer_AddPenaltyTime(client, Float:penaltytime);

native bool:Timer_GetBestRound(client, mode, bonus, &Float:time, &jumps);
native bool:Timer_GetClientTimer(client, &enabled, &Float:time, &jumps, &fpsmax);

native Timer_FinishRound(client, const String:map[], Float:time, jumps, physicsDifficulty, fpsmax, bonus);

native Timer_ClientTeleportLevel(client, level);
native Timer_GetClientLevel(client);
native Timer_GetClientLevelID(client);
native Timer_SetClientLevel(client, level);
native Timer_GetStatus(client);
native Timer_GetPauseStatus(client);
native Timer_GetBonus(client);
native Timer_GetMapFinishCount(client);
native Timer_GetMapFinishBonusCount(client);
native Timer_SetBonus(client, newmode);
native Timer_GetMode(client);
native Timer_IsModeRanked(mode);
native Timer_GetClientTeammate(client);
native Timer_SetClientTeammate(client, mate, teleport);
native Timer_SetMode(client, newmode);
native Timer_GetTier();
native Timer_SetTier(tier);
native Timer_GetStageCount();
native Timer_SetStageCount(stagecount);

native Timer_ForceReloadCache();
native Timer_GetCurrentRank(client, bool:update, bonus);
native Timer_GetTotalRank(bool:update, bonus);
native Timer_GetDifficultyRecordTime(mode, bonus, &cacheid, &Float:time, &total);
native Timer_GetNewPossibleRank(mode, bonus, Float:time);
native Timer_GetRankID(mode, bonus, rank);

native Timer_SetCacheMapName(String:name[], length);
native Timer_GetCacheMapName(String:name[], length);

native Timer_GetDifficultyRank(client, bonus, mode);
native Timer_GetRecordHolderName(mode, bonus, rank, String:name[], length);
native Timer_GetLevelName(id, String:name[], length);
native Timer_GetFinishCount(mode, bonus, rank);
native Timer_GetRecordDate(mode, bonus, rank, String:date[], length);
native Timer_GetRecordTimeInfo(mode, bonus, rank, &Float:time, String:timestring[], length);
native Timer_GetRecordSpeedInfo(mode, bonus, rank, &Float:avgspeed, &Float:maxspeed, &Float:finishspeed);
native Timer_GetRecordStrafeJumpInfo(mode, bonus, rank, &strafes, &Float:strafeacc, &jumps, &Float:jumpacc);
native Timer_GetReplayPath(mode, bonus, rank, String:replay_path[], length);
native Timer_GetRecordCustom1(mode, bonus, rank, String:custom1[], length);
native Timer_GetRecordCustom2(mode, bonus, rank, String:custom2[], length);
native Timer_GetRecordCustom3(mode, bonus, rank, String:custom3[], length);

native Timer_GetStrafeCount(client);
native Timer_GetBoostedStrafeCount(client);

native Timer_GetPoints(client);
native Timer_GetPointRank(client);
native Timer_SetPoints(client, points);
native Timer_AddPoints(client, points);
native Timer_RemovePoints(client, points);
native Timer_SavePoints(client);

native Ranking_GetPoints(client);
native Ranking_GetPointRank(client);
native Ranking_SetPoints(client, points);
native Ranking_AddPoints(client, points);
native Ranking_RemovePoints(client, points);
native Ranking_SavePoints(client);

native Timer_GetClientHide(client);
native Timer_SetClientHide(client, hide);
native Timer_SetIgnoreEndTouchStart(client, ignore);
native Timer_IsPlayerTouchingZoneType(client, MapZoneType:type);
native Timer_GetMapzoneCount(MapZoneType:type);

native Timer_GetScripter(client);
native Timer_GetPickedMode(client);
native Timer_GetForceMode();
native Timer_ApplyPhysics(client);
native Timer_GetJumpAccuracy(client, &Float:percent);
native Timer_GetCurrentSpeed(client, &Float:speed);
native Timer_GetMaxSpeed(client, &Float:maxspeed);
native Timer_GetAvgSpeed(client, &Float:avgspeed);
native Timer_ResetAccuracy(client);

native Timer_GetCoopStatus(client);
native Timer_GetChallengeStatus(client);

public Timer_SetNTVOpt()
{
	MarkNativeAsOptional("Timer_Start");
	MarkNativeAsOptional("Timer_Stop");
	MarkNativeAsOptional("Timer_Resume");
	MarkNativeAsOptional("Timer_Pause");
	MarkNativeAsOptional("Timer_Restart");
	MarkNativeAsOptional("Timer_Reset");
	MarkNativeAsOptional("Timer_AddPenaltyTime");

	MarkNativeAsOptional("Timer_GetBestRound");
	MarkNativeAsOptional("Timer_GetClientTimer");

	MarkNativeAsOptional("Timer_FinishRound");

	MarkNativeAsOptional("Timer_GetClientLevel");
	MarkNativeAsOptional("Timer_GetClientLevelID");
	MarkNativeAsOptional("Timer_SetClientLevel");
	MarkNativeAsOptional("Timer_GetStatus");
	MarkNativeAsOptional("Timer_GetBonus");
	MarkNativeAsOptional("Timer_GetMapFinishCount");
	MarkNativeAsOptional("Timer_GetMapFinishBonusCount");
	MarkNativeAsOptional("Timer_SetBonus");
	MarkNativeAsOptional("Timer_GetMode");
	MarkNativeAsOptional("Timer_IsModeRanked");
	MarkNativeAsOptional("Timer_GetClientTeammate");
	MarkNativeAsOptional("Timer_SetClientTeammate");
	MarkNativeAsOptional("Timer_SetMode");
	MarkNativeAsOptional("Timer_GetTier");
	MarkNativeAsOptional("Timer_SetTier");
	MarkNativeAsOptional("Timer_GetStageCount");
	MarkNativeAsOptional("Timer_SetStageCount");
	MarkNativeAsOptional("Timer_ForceReloadCache");
	MarkNativeAsOptional("Timer_GetCurrentRank");
	MarkNativeAsOptional("Timer_GetTotalRank");
	MarkNativeAsOptional("Timer_GetDifficultyRecordTime");
	MarkNativeAsOptional("Timer_GetNewPossibleRank");
	MarkNativeAsOptional("Timer_GetRankID");
	MarkNativeAsOptional("Timer_GetDifficultyRank");
	MarkNativeAsOptional("Timer_GetRecordHolderName");
	MarkNativeAsOptional("Timer_GetLevelName");
	MarkNativeAsOptional("Timer_GetFinishCount");
	MarkNativeAsOptional("Timer_GetRecordDate");
	MarkNativeAsOptional("Timer_GetRecordTimeInfo");
	MarkNativeAsOptional("Timer_GetRecordSpeedInfo");
	MarkNativeAsOptional("Timer_GetRecordStrafeJumpInfo");
	
	MarkNativeAsOptional("Timer_GetStrafeCount");
	MarkNativeAsOptional("Timer_GetBoostedStrafeCount");

	MarkNativeAsOptional("Timer_GetPoints");
	MarkNativeAsOptional("Timer_GetPointsRank");
	MarkNativeAsOptional("Timer_SavePoints");
	MarkNativeAsOptional("Timer_AddPoints");
	MarkNativeAsOptional("Timer_SetPoints");
	MarkNativeAsOptional("Timer_RemovePoints");

	MarkNativeAsOptional("Timer_GetPointsChallengeWin");
	MarkNativeAsOptional("Timer_GetPointsChallengeLoose");

	MarkNativeAsOptional("Timer_GetClientHide");
	MarkNativeAsOptional("Timer_SetClientHide");
	MarkNativeAsOptional("Timer_SetIgnoreEndTouchStart");
	MarkNativeAsOptional("Timer_IsPlayerTouchingZoneType");
	MarkNativeAsOptional("Timer_GetMapzoneCount");
	
	MarkNativeAsOptional("Timer_GetScripter");
	MarkNativeAsOptional("Timer_GetPickedMode");
	MarkNativeAsOptional("Timer_GetForceMode");
	MarkNativeAsOptional("Timer_ApplyPhysics");
	MarkNativeAsOptional("Timer_GetJumpAccuracy");
	MarkNativeAsOptional("Timer_GetCurrentSpeed");
	MarkNativeAsOptional("Timer_GetMaxSpeed");
	MarkNativeAsOptional("Timer_GetAvgSpeed");
	MarkNativeAsOptional("Timer_ResetAccuracy");
	
	MarkNativeAsOptional("Timer_GetCoopStatus");
	MarkNativeAsOptional("Timer_GetChallengeStatus");
	
	MarkNativeAsOptional("Ranking_GetPoints");
	MarkNativeAsOptional("Ranking_GetPointRank");
	MarkNativeAsOptional("Ranking_SetPoints");
	MarkNativeAsOptional("Ranking_AddPoints");
	MarkNativeAsOptional("Ranking_RemovePoints");
	MarkNativeAsOptional("Ranking_SavePoints");
}