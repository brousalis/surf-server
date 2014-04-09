#if defined _timer_included
 #endinput
#endif
#define _timer_included

#pragma semicolon 1

#define PL_VERSION		"2.1.3"

/*** SETTINGS ***/

//MAX RECORDS TO CACHE
#define MAX_CACHE 1000

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
#define PLUGIN_PREFIX " {lightred}[{green}Timer{lightred}]{green} %t"
#define PLUGIN_PREFIX2 " {lightred}[{green}Timer{lightred}]{green}"
#else
#include <morecolors>		//https://www.doctormckay.com/download/scripting/include/morecolors.inc
#define PLUGIN_PREFIX "{yellow}[Timer] {green}%t"
#define PLUGIN_PREFIX2 "{yellow}[Timer]{green}"
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

native Timer_GetStatus(client);
native Timer_GetPauseStatus(client);
native Timer_GetBonus(client);
native Timer_GetMapFinishCount(client);
native Timer_GetMapFinishBonusCount(client);
native Timer_SetBonus(client, newmode);
native Timer_GetMode(client);
native Timer_IsModeRanked(mode);
native Timer_SetMode(client, newmode);

public SharedPlugin:__pl_timer = 
{
	name = "timer",
	file = "timer-core.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

public __pl_timer_SetNTVOpt()
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

	MarkNativeAsOptional("Timer_GetStatus");
	MarkNativeAsOptional("Timer_GetBonus");
	MarkNativeAsOptional("Timer_GetMapFinishCount");
	MarkNativeAsOptional("Timer_GetMapFinishBonusCount");
	MarkNativeAsOptional("Timer_SetBonus");
	MarkNativeAsOptional("Timer_GetMode");
	MarkNativeAsOptional("Timer_IsModeRanked");
	MarkNativeAsOptional("Timer_SetMode");	
}