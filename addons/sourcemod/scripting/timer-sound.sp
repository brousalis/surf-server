#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <emitsoundany>

#include <timer>
#include <timer-logging>

#define MAX_FILE_LEN 128

new Handle:Sound_TimerFinish = INVALID_HANDLE;
new String:SND_TIMER_FINISH[MAX_FILE_LEN];

new Handle:Sound_TimerResume = INVALID_HANDLE;
new String:SND_TIMER_RESUME[MAX_FILE_LEN];

new Handle:Sound_TimerPause = INVALID_HANDLE;
new String:SND_TIMER_PAUSE[MAX_FILE_LEN];

new Handle:Sound_TimerWorldRecord = INVALID_HANDLE;
new String:SND_TIMER_WORLDRECORD[MAX_FILE_LEN];

new Handle:Sound_TimerWorldRecordAll = INVALID_HANDLE;
new String:SND_TIMER_WORLDRECORD_ALL[MAX_FILE_LEN];

new Handle:Sound_TimerPersonalBest = INVALID_HANDLE;
new String:SND_TIMER_PERSONALBEST[MAX_FILE_LEN];

public Plugin:myinfo =
{
    name        = "[Timer] Sounds",
    author      = "Zipcore, Jason Bourne",
    description = "[Timer] Sounds for timer events",
    version     = PL_VERSION,
    url         = "forums.alliedmods.net/showthread.php?p=2074699"
};

public OnPluginStart()
{
	Sound_TimerFinish = CreateConVar("timer_sound_finish", "ui/freeze_cam.wav", "");
	Sound_TimerWorldRecord = CreateConVar("timer_sound_worldrecord", "ui/freeze_cam.wav", "");
	Sound_TimerWorldRecordAll = CreateConVar("timer_sound_worldrecord_all", "ui/freeze_cam.wav", "");
	Sound_TimerPause = CreateConVar("timer_sound_pause", "ui/freeze_cam.wav", "");
	Sound_TimerResume = CreateConVar("timer_sound_resume", "ui/freeze_cam.wav", "");
	Sound_TimerPersonalBest = CreateConVar("timer_sound_personalbest", "ui/freeze_cam.wav", "");
	
	AutoExecConfig(true, "timer/timer-sounds");
}

public OnConfigsExecuted()
{
	CacheSounds();
	Timer_LogTrace("[Sound] Sounds cached OnConfigsExecuted");
}

public CacheSounds()
{
	GetConVarString(Sound_TimerFinish, SND_TIMER_FINISH, sizeof(SND_TIMER_FINISH));
	PrepareSound(SND_TIMER_FINISH);
	
	GetConVarString(Sound_TimerPause, SND_TIMER_PAUSE, sizeof(SND_TIMER_PAUSE));
	PrepareSound(SND_TIMER_PAUSE);
	
	GetConVarString(Sound_TimerResume, SND_TIMER_RESUME, sizeof(SND_TIMER_RESUME));
	PrepareSound(SND_TIMER_FINISH);
	
	GetConVarString(Sound_TimerWorldRecord, SND_TIMER_WORLDRECORD, sizeof(SND_TIMER_WORLDRECORD));
	PrepareSound(SND_TIMER_WORLDRECORD);
	
	GetConVarString(Sound_TimerWorldRecordAll, SND_TIMER_WORLDRECORD_ALL, sizeof(SND_TIMER_WORLDRECORD_ALL));
	PrepareSound(SND_TIMER_WORLDRECORD_ALL);
	
	GetConVarString(Sound_TimerPersonalBest, SND_TIMER_PERSONALBEST, sizeof(SND_TIMER_PERSONALBEST));
	PrepareSound(SND_TIMER_PERSONALBEST);
}

public PrepareSound(String: sound[MAX_FILE_LEN])
{
	decl String:fileSound[MAX_FILE_LEN];

	FormatEx(fileSound, MAX_FILE_LEN, "sound/%s", sound);

	if (FileExists(fileSound))
	{
		PrecacheSoundAny(sound, true);
		AddFileToDownloadsTable(fileSound);
		Timer_LogTrace("[Sound] File '%s' added to downloads table.", fileSound);
	}
	else
	{
		Timer_LogError("[Sound] File '%s' not found.", fileSound);
	}
}

public OnTimerPaused(client)
{
	EmitSoundToClientAny(client, SND_TIMER_PAUSE);
}

public OnTimerResumed(client)
{
	EmitSoundToClientAny(client, SND_TIMER_RESUME);
}

public OnTimerWorldRecord(client)
{
	//Stop the sound first
	EmitSoundToAllAny(SND_TIMER_WORLDRECORD_ALL, _, _, _, SND_STOPLOOPING);
	
	EmitSoundToAllAny(SND_TIMER_WORLDRECORD_ALL);
}

public OnTimerPersonalRecord(client)
{
	EmitSoundToClientAny(client, SND_TIMER_PERSONALBEST);
}

public OnTimerRecord(client)
{
	EmitSoundToClientAny(client, SND_TIMER_FINISH);
}
