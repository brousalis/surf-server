#pragma semicolon 1

#define VERSION "1.2.12"

public Plugin:myinfo = {
	name = "JS_LJstats",
	author = "justshoot, zipcore",
	description = "Jump stats",
	version = VERSION,
	url = "jsbhop@gmail.com, zipcore#googlemail.com"
};

#include <sdkhooks>
#include <sdktools>
#include <js_ljstats>
#include <jsfunction>
#include <smlib>

#include <timer-logging>
#include <timer-config_loader.sp>

#undef REQUIRE_PLUGIN
#include <timer>

#define LJDELAY 1.0
#define ELSEDELAY 0.1

enum JumpType (+=1)
{
	JumpType_None = 0,
	JumpType_LongJump,
	JumpType_DropJump,
	JumpType_UpJump,
	JumpType_Ladder,
	JumpType_Wj,
	JumpType_WjDrop,
	JumpType_WjUp,
	JumpType_BhopJump,
	JumpType_BhopUpJump,
	JumpType_BlockLongJump,
	JumpType_BlockBhopJump
}
enum ReadyType
{
	ReadyType_None,
	ReadyType_LongJump,
	ReadyType_BhopJump,
	ReadyType_BhopUpJump,
	ReadyType_Wj,
	ReadyType_BlockLongJump,
	ReadyType_BlockBhopJump
}

new String:JumpName[JumpType][128] = 
{
	"None",
	"LongJump",
	"DropJump",
	"UpJump",
	"LadderStrafe",
	"WeirdJump",
	"WeirdJump-Drop",
	"WeirdJump+Up",
	"BhopJump",
	"BhopUpJump",
	"BlockLongJump",
	"BlockBhopJump"
};

/**********************
*   Player Variable   *
**********************/
new JumpType:PlayerJumpType[MAXPLAYERS + 1];
new ReadyType:PlayerReadyType[MAXPLAYERS + 1];
new bool:g_bLJmode[MAXPLAYERS + 1];
new bool:g_bValidJump[MAXPLAYERS + 1];
new Float:g_fJumpedPos[MAXPLAYERS + 1][3];
new Float:g_fOnGroundPos[MAXPLAYERS + 1][3];
new Float:PreStrafe[MAXPLAYERS + 1];
new Float:OnGroundTime[MAXPLAYERS + 1];
new bool:NoDucking[MAXPLAYERS + 1];

new g_Strafe[MAXPLAYERS + 1];
new Float:LJ_SyncRate[MAXPLAYERS + 1];
new Float:LJ_MaxSpeed[MAXPLAYERS + 1];
#define MAXSTR 20
new Float:LJ_SyncRateStrafe[MAXPLAYERS + 1][MAXSTR];
new LJ_GoodSync[MAXPLAYERS + 1][MAXSTR];
new LJ_BadSync[MAXPLAYERS + 1][MAXSTR];
new Float:LJ_Gains[MAXPLAYERS + 1][MAXSTR];
new Float:LJ_Lost[MAXPLAYERS + 1][MAXSTR];
new LJ_Frame[MAXPLAYERS + 1][MAXSTR];
new LJ_TotalFrame[MAXPLAYERS + 1];
new Float:LJ_MaxSpeedStrafe[MAXPLAYERS + 1][MAXSTR];

new bool:g_bLJpopup[MAXPLAYERS + 1];

/**************************
*       Block Jump        *
**************************/

new Handle:h_LJBlockMenu = INVALID_HANDLE;       
new bool:g_bLJBlock[MAXPLAYERS + 1];
new Float:g_fBlockHeight[MAXPLAYERS + 1];
new Float:g_EdgeVector[MAXPLAYERS + 1][3];
new Float:g_EdgePoint[MAXPLAYERS + 1][3];
new Float:g_EdgeDist[MAXPLAYERS + 1];
new Float:g_OriginBlock[MAXPLAYERS + 1][2][3];
new Float:g_DestBlock[MAXPLAYERS + 1][2][3];
new g_BlockDist[MAXPLAYERS + 1];

/*********************
*   Jump Stat Sound  *
*********************/

new bool:g_bLJplaysnd[MAXPLAYERS + 1];
new String:LJ_SOUND[5][256] = 
{
	{"misc/impressive.wav"},
	{"misc/perfect.wav"},
	{"misc/mod_wickedsick.wav"},
	{"misc/mod_godlike.wav"},
	{"misc/holyshit.wav"}
};

/*********************
*   Create Natives   *
*********************/

new Handle:g_LJMode_Forward = INVALID_HANDLE;

/********************
*      ConVar       *
********************/

new Handle:g_hCvar_Show_Message = INVALID_HANDLE;
new g_ShowMsg;

new Handle:g_hCvar_Invalid_Jump = INVALID_HANDLE;
new Float:g_InvalidUnit;

new Handle:g_hCvar_Stop_LJ = INVALID_HANDLE;
new Float:g_Stop_LJ;

new Handle:g_hCvar_Stop_BJ = INVALID_HANDLE;
new Float:g_Stop_BJ;

new Handle:g_hCvar_Stop_BUJ = INVALID_HANDLE;
new Float:g_Stop_BUJ;

new Handle:g_hCvar_Stop_Block_LJ = INVALID_HANDLE;
new Float:g_Stop_Block_LJ;

new Handle:g_hCvar_Print_LJ = INVALID_HANDLE;
new Float:g_Print_LJ;

new Handle:g_hCvar_Print_WJ = INVALID_HANDLE;
new Float:g_Print_WJ;

new Handle:g_hCvar_Print_BJ = INVALID_HANDLE;
new Float:g_Print_BJ;

new Handle:g_hCvar_Print_Block_LJ = INVALID_HANDLE;
new Float:g_Print_Block_LJ;

new Handle:g_hCvar_Print_Block_BJ = INVALID_HANDLE;
new Float:g_Print_Block_BJ;

new Handle:g_hCvar_DB_Record = INVALID_HANDLE;
new Float:g_DB_Record;

new Handle:g_hCvar_Sound[5];
new Float:g_Sound[5];

new bool:g_bLateLoaded;

/********************
*     Measuring     *
********************/
new g_Beam[2];
new Float:AimPoint_1[MAXPLAYERS + 1][3];
new Float:AimPoint_2[MAXPLAYERS + 1][3];
new bool:AimDrawing[MAXPLAYERS + 1];
new AimStatus[MAXPLAYERS + 1];
new Handle:AimHandle[MAXPLAYERS + 1];

/*****************
*  Top LJ Sqlite *
******************/
new Handle:maindb = INVALID_HANDLE;
new Handle:g_hCvar_DB = INVALID_HANDLE;
new Handle:h_TopMenu = INVALID_HANDLE;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RegPluginLibrary("timer-ljstats");
	CreateNative("IsClientInLJMode", Native_IsClientInLJMode);
	CreateNative("SetLJMode", Native_SetLJMode);
	CreateNative("SetInValidJump", Native_SetInValidJump);
	g_LJMode_Forward = CreateGlobalForward("OnClientLJModeChanged", ET_Hook, Param_Cell, Param_Cell);
	g_bLateLoaded = late;
	return APLRes_Success;
}
public Native_IsClientInLJMode(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	return g_bLJmode[client];
}
public Native_SetLJMode(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new bool:on = GetNativeCell(2);
	
	if(on && !g_Physics[Timer_GetMode(client)][ModeLJStats])
	{
		//Don't allow wrong modes
	}
	else g_bLJmode[client] = on;
}
public Native_SetInValidJump(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	g_bValidJump[client] = false;
}
public OnPluginStart()
{
	CreateConVar("ljstats_version",VERSION,"Long Jump Stats - justshoot", FCVAR_PLUGIN|FCVAR_NOTIFY);
	RegAdminCmd("sm_ljadm", Command_ljadm, ADMFLAG_ROOT, "Delete Record");
	RegConsoleCmd("sm_lj", Command_ljmode, "Record Jump Stats");
	RegConsoleCmd("sm_ljblock", Command_ljblock, "Register Destination");
	RegConsoleCmd("sm_ljsound", Command_ljsound, "ljstats quake sound");
	RegConsoleCmd("sm_ljpopup", Command_ljpopup, "Show/hide stats popup.");
	RegConsoleCmd("sm_gap", Command_measure, "Measure units between 2 points");
	RegConsoleCmd("sm_ljtop", Command_ljtop, "show ljstats top ranks");
	HookEvent("player_jump", event_jump); //When players jumped
	HookEvent("player_team", event_team);
	HookEvent("round_start", event_roundstart);
	g_hCvar_Show_Message = CreateConVar("ljstats_show_msg", "0", "0:All, 1:only for lj", FCVAR_PLUGIN);
	g_hCvar_DB = CreateConVar("ljstats_db_name", "ljstats", "Database name, sqlite", FCVAR_PLUGIN);
	g_hCvar_Invalid_Jump = CreateConVar("ljstats_invalid_lj", "280.0", "Cancel Jump if PRESTRAFE and DISTANCE is over this value.", FCVAR_PLUGIN);
	g_hCvar_Stop_LJ = CreateConVar("ljstats_print_lj", "240.0", "Long Jump minimum units to show result to player.", FCVAR_PLUGIN);
	g_hCvar_Stop_BJ = CreateConVar("ljstats_print_bj", "270.0", "Bhop Jump minimum units to show result to player.", FCVAR_PLUGIN);
	g_hCvar_Stop_BUJ = CreateConVar("ljstats_print_buj", "250.0", "Bhop Up Jump minimum units to show result to player.", FCVAR_PLUGIN);
	g_hCvar_Stop_Block_LJ = CreateConVar("ljstats_register_block_lj", "235.0", "Minimum units to register Block Long Jump.", FCVAR_PLUGIN);
	g_hCvar_Print_LJ = CreateConVar("ljstats_show_lj", "260.0", "Print long jump result over this value.", FCVAR_PLUGIN);
	g_hCvar_Print_WJ = CreateConVar("ljstats_show_wj", "270.0", "Print weird jump result over this value.", FCVAR_PLUGIN);
	g_hCvar_Print_BJ = CreateConVar("ljstats_show_bj", "270.0", "Print bhop Jump result over this value.", FCVAR_PLUGIN);
	g_hCvar_Print_Block_LJ = CreateConVar("ljstats_show_block_lj", "255.0", "Print Block Long Jump result over this value.", FCVAR_PLUGIN);
	g_hCvar_Print_Block_BJ = CreateConVar("ljstats_show_block_bj", "275.0", "Print Block Bhop Jump result over this value.", FCVAR_PLUGIN);
	g_hCvar_DB_Record = CreateConVar("ljstats_db_record", "260.0", "Record result into database over this value.", FCVAR_PLUGIN);
	g_hCvar_Sound[0] = CreateConVar("ljstats_snd_impressive", "255.0", "Play Sound - impressive.", FCVAR_PLUGIN);
	g_hCvar_Sound[1] = CreateConVar("ljstats_snd_perfect", "260.0", "Play Sound - perfect.", FCVAR_PLUGIN);
	g_hCvar_Sound[2] = CreateConVar("ljstats_snd_wickedsick", "265.0", "Play Sound - wickedsick.", FCVAR_PLUGIN);
	g_hCvar_Sound[3] = CreateConVar("ljstats_snd_godlick", "268.0", "Play Sound - godlike.", FCVAR_PLUGIN);
	g_hCvar_Sound[4] = CreateConVar("ljstats_snd_holyshit", "270.0", "Play Sound - holyshit.", FCVAR_PLUGIN);
	HookConVarChange(g_hCvar_Show_Message, ConVarChanged);
	HookConVarChange(g_hCvar_DB, ConVarChanged);
	HookConVarChange(g_hCvar_Invalid_Jump, ConVarChanged);
	HookConVarChange(g_hCvar_Stop_LJ, ConVarChanged);
	HookConVarChange(g_hCvar_Stop_BJ, ConVarChanged);
	HookConVarChange(g_hCvar_Stop_BUJ, ConVarChanged);
	HookConVarChange(g_hCvar_Stop_Block_LJ, ConVarChanged);
	HookConVarChange(g_hCvar_Print_LJ, ConVarChanged);
	HookConVarChange(g_hCvar_Print_WJ, ConVarChanged);
	HookConVarChange(g_hCvar_Print_BJ, ConVarChanged);
	HookConVarChange(g_hCvar_Print_Block_LJ, ConVarChanged);
	HookConVarChange(g_hCvar_Print_Block_BJ, ConVarChanged);
	HookConVarChange(g_hCvar_DB_Record, ConVarChanged);
	for(new i = 0; i < sizeof(g_Sound); i++)
	{
		HookConVarChange(g_hCvar_Sound[i], ConVarChanged);
	}
	AutoExecConfig(true, "timer/timer-ljstats");
	CreateTopMenu();
	if(g_bLateLoaded)
	{
		OnAutoConfigsBuffered();
		FindNHookWalls();
		HookTrigger();
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				OnClientPutInServer(i);
			}
		}
	}
	
	LoadPhysics();
	LoadTimerSettings();
}
public OnPluginEnd()
{
	for(new i = 1; i<= MaxClients; i++)
	{
		OnClientDisconnect(i);
	}
}
public OnAutoConfigsBuffered()
{
	g_ShowMsg = GetConVarInt(g_hCvar_Show_Message);
	g_InvalidUnit = GetConVarFloat(g_hCvar_Invalid_Jump);
	g_Stop_LJ = GetConVarFloat(g_hCvar_Stop_LJ);
	g_Stop_BJ = GetConVarFloat(g_hCvar_Stop_BJ);
	g_Stop_BUJ = GetConVarFloat(g_hCvar_Stop_BUJ);
	g_Stop_Block_LJ = GetConVarFloat(g_hCvar_Stop_Block_LJ);
	g_Print_LJ = GetConVarFloat(g_hCvar_Print_LJ);
	g_Print_WJ = GetConVarFloat(g_hCvar_Print_WJ);
	g_Print_BJ = GetConVarFloat(g_hCvar_Print_BJ);
	g_Print_Block_LJ = GetConVarFloat(g_hCvar_Print_Block_LJ);
	g_Print_Block_BJ = GetConVarFloat(g_hCvar_Print_Block_BJ);
	g_DB_Record = GetConVarFloat(g_hCvar_DB_Record);
	for(new i = 0; i < sizeof(g_Sound); i++)
	{
		g_Sound[i] = GetConVarFloat(g_hCvar_Sound[i]);
	}
	ConnectToDB();
}
public ConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == g_hCvar_Show_Message)
	{
		g_ShowMsg = GetConVarInt(g_hCvar_Show_Message);
	}
	else if(convar == g_hCvar_Invalid_Jump)
	{
		g_InvalidUnit = GetConVarFloat(g_hCvar_Invalid_Jump);
	}
	else if(convar == g_hCvar_Stop_LJ)
	{
		g_Stop_LJ = GetConVarFloat(g_hCvar_Stop_LJ);
	}
	else if(convar == g_hCvar_Stop_BJ)
	{
		g_Stop_BJ = GetConVarFloat(g_hCvar_Stop_BJ);
	}
	else if(convar == g_hCvar_Stop_BUJ)
	{
		g_Stop_BUJ = GetConVarFloat(g_hCvar_Stop_BUJ);
	}
	else if(convar == g_hCvar_Stop_Block_LJ)
	{
		g_Stop_Block_LJ = GetConVarFloat(g_hCvar_Stop_Block_LJ);
	}
	else if(convar == g_hCvar_Print_LJ)
	{
		g_Print_LJ = GetConVarFloat(g_hCvar_Print_LJ);
	}
	else if(convar == g_hCvar_Print_WJ)
	{
		g_Print_WJ = GetConVarFloat(g_hCvar_Print_WJ);
	}
	else if(convar == g_hCvar_Print_BJ)
	{
		g_Print_BJ = GetConVarFloat(g_hCvar_Print_BJ);
	}
	else if(convar == g_hCvar_Print_Block_LJ)
	{
		g_Print_Block_LJ = GetConVarFloat(g_hCvar_Print_Block_LJ);
	}
	else if(convar == g_hCvar_Print_Block_BJ)
	{
		g_Print_Block_BJ = GetConVarFloat(g_hCvar_Print_Block_BJ);
	}
	else if(convar == g_hCvar_DB)
	{
		ConnectToDB();
	}
	for(new i = 0; i < sizeof(g_Sound); i++)
	{
		if(convar == g_hCvar_Sound[i])
		{
			g_Sound[i] = GetConVarFloat(g_hCvar_Sound[i]);
		}
	}
}
public OnMapStart()
{
	decl String:txt[256];
	for(new i = 0; i < 5; i++)
	{
		Format(txt, 256, "sound/%s", LJ_SOUND[i]);
		AddFileToDownloadsTable(txt);
		PrecacheSound(LJ_SOUND[i], true);
	}
	g_Beam[0] = PrecacheModel("materials/sprites/laser.vmt");
	g_Beam[1] = PrecacheModel("materials/sprites/halo01.vmt");
	
	LoadPhysics();
	LoadTimerSettings();
}

public OnClientPutInServer(client)
{
	g_bLJmode[client] = false;
	g_bLJBlock[client] = false;
	g_bLJpopup[client] = true;
	g_bLJplaysnd[client] = true;
}
public OnClientDisconnect(client)
{
	g_bLJmode[client] = false;
	if(AimHandle[client]!=INVALID_HANDLE)
	{
		KillTimer(AimHandle[client]);
		AimHandle[client] = INVALID_HANDLE;
	}
}
public Action:Touch_Wall(ent,client)
{
	if(0 < client <= MaxClients)
	{
		if(PlayerReadyType[client] == ReadyType_Wj)
		{
			PlayerReadyType[client] = ReadyType_None;
		}
		if(g_bValidJump[client]&&!(GetEntityFlags(client)&FL_ONGROUND))
		{
			new Float:origin[3], Float:temp[3];
			GetGroundOrigin(client, origin);
			GetClientAbsOrigin(client, temp);
			// PrintToChat(client, "\x03Client height : %f, \x04Ground height : %f", temp[2], origin[2]);
			if(temp[2] - origin[2] <= 0.2)//means slope not just a wall.
			{
				PrintToChat(client, "\x01[\x05LJstats\x01]\x03Jump canceled \x01: Possible surfing.");
				g_bValidJump[client] = false;
				PlayerReadyType[client] = ReadyType_None;
			}
		}
	}
	return Plugin_Continue;
}
public Action:event_jump(Handle:Event, const String:Name[], bool:Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(Event, "userid"));
	if(g_bLJmode[client])
	{
		if(PlayerReadyType[client] != ReadyType_None)
		{
			decl Float:temp[3], Float:origin[3];
			GetEntPropVector(client, Prop_Data, "m_vecVelocity", temp);
			temp[2] = 0.0;
			new Float:newvelo = GetVectorLength(temp);
			GetGroundOrigin(client, origin);
			if(g_bLJBlock[client])
			{
				GetEdgeOrigin(client, origin, temp);
				g_EdgeDist[client] = GetVectorDistance(temp, origin);
			}
			// PrintToChat(client, "\x03Jumped : %f", origin[2]);
			new JumpType:type;
			if(PlayerReadyType[client] == ReadyType_LongJump)
			{
				type = JumpType_LongJump;
			}
			else if(PlayerReadyType[client] == ReadyType_BhopJump)
			{
				type = JumpType_BhopJump;
			}
			else if(PlayerReadyType[client] == ReadyType_BhopUpJump)
			{
				type = JumpType_BhopUpJump;
			}
			else if(PlayerReadyType[client] == ReadyType_Wj)
			{
				type = JumpType_Wj;
			}
			else if(PlayerReadyType[client] == ReadyType_BlockLongJump)
			{
				type = JumpType_BlockLongJump;
			}
			else if(PlayerReadyType[client] == ReadyType_BlockBhopJump)
			{
				type = JumpType_BlockBhopJump;
			}
			StartJumpStats(client, type, origin, newvelo);
		}
	}
}
public Action:event_team(Handle:Event, const String:Name[], bool:Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(Event, "userid"));
	if(client != 0)
	{
		if(IsClientInGame(client))
		{
			if(GetEventInt(Event, "team")==1)
			{
				g_bLJmode[client] = false;
			}
		}
	}
}
public Action:event_roundstart(Handle:Event, const String:Name[], bool:Broadcast)
{
	FindNHookWalls();//i don't know why. but better hook after level completely loaded.
	HookTrigger();
}
FindNHookWalls()
{/**Hook wall-like entities to prevent surfing. add more entity class if missing.
	also it may work just with StartTouch not Touch(haven't tried)**/
	SDKHook(0,SDKHook_Touch,Touch_Wall);//World entity
	new ent = -1;
	while((ent = FindEntityByClassname(ent,"func_breakable")) != -1) 
	{
		SDKHook(ent,SDKHook_Touch,Touch_Wall);
	}
	ent = -1;
	while((ent = FindEntityByClassname(ent,"func_illusionary")) != -1) 
	{
		SDKHook(ent,SDKHook_Touch,Touch_Wall);
	}
	ent = -1;
	while((ent = FindEntityByClassname(ent,"func_wall")) != -1) 
	{
		SDKHook(ent,SDKHook_Touch,Touch_Wall);
	}
}
HookTrigger()
{
	new ent = -1;
	while((ent = FindEntityByClassname(ent, "trigger_push")) != -1)
	{
		SDKHook(ent,SDKHook_Touch,Push_Touch);
	}
}
public Action:Push_Touch(ent,client)
{
	if(0 < client <= MaxClients)
	{
		if(g_bLJmode[client])
		{
			g_bLJmode[client] = false;
			PrintToChat(client, "\x01[\x05LJstats\x01]\x03You touched Booster. LJmode disabled");
		}
	}
	return Plugin_Continue;
}
public Action:Command_ljmode(client, args)
{
	if(0< client<= MaxClients)
	{
		if(g_bLJmode[client])
		{
			new Action:result = Action:API_OnLJChanged(client, false);
			if(result != Plugin_Handled&&result != Plugin_Stop)
			{
				g_bLJmode[client] = false;
				PrintToChat(client, "\x01[\x05LJstats\x01]\x03LJ\x01 is now turned off.");
			}
		}
		else if(!g_bLJmode[client])
		{
			new	Action:result = Action:API_OnLJChanged(client, true);
			if(result != Plugin_Handled&&result != Plugin_Stop)
			{
				new Float:gravity = GetEntityGravity(client);
				if(gravity != 0.0&&gravity!=1.0)
				{
					PrintToChat(client, "\x01[\x05LJstats\x01]\x03Can't turn LJmode on while this gravity.");
				}
				else if(!g_Physics[Timer_GetMode(client)][ModeLJStats])
				{
					PrintToChat(client, "\x01[\x05LJstats\x01]\x03Can't turn LJmode on while on this mode.");
				}
				else
				{
					g_bLJmode[client] = true;
					g_bLJBlock[client] = false;
					PrintToChat(client, "\x01[\x05LJstats\x01]\x03LJ\x01 is now turned on.");
				}
			}
		}
	}
	return Plugin_Handled;
}
public Action:Command_ljblock(client, args)
{
	if(0 < client <= MaxClients)
	{
		if(g_bLJmode[client])
		{
			LJBlockMenu(client);
		}
		else
		{
			PrintToChat(client, "\x01[\x05LJstats\x01]\x03Turn on LongJumpStats first\x01 !lj");
		}
	}
	return Plugin_Handled;
}
Function_BlockJump(client)
{
	decl Float:pos[3], Float:origin[3];
	GetAimOrigin(client, pos);
	// GetClientAbsOrigin(client, temp);
	TraceClientGroundOrigin(client, origin, 100.0);
	// GetGroundOrigin(client, origin);
	if(FloatAbs(pos[2] - origin[2]) <= 0.002)
	{
		CalculateBlockGap(client, origin, pos);
		GetBoxFromPoint(origin, g_OriginBlock[client]);
		GetBoxFromPoint(pos, g_DestBlock[client]);
		// CalculateBlockGap2(client, g_OriginBlock[client], g_DestBlock[client]);
		g_fBlockHeight[client] = pos[2];
	}
	else
	{
		// GetBoxFromPoint(origin, g_OriginBlock[client]);
		// GetBoxFromPoint(pos, g_DestBlock[client]);
		// g_bLJBlock[client] = true;
		// CalculateBlockGap2(client, g_OriginBlock[client], g_DestBlock[client]);
		PrintToChat(client, "\x01[\x05LJstats\x01]\x03Only allowed for valid long jump for now.");
	}
}
public LJBlockHandler(Handle:menu, MenuAction:action, client, select)
{
	if(action == MenuAction_Select)
	{
		if(select == 0)
		{
			Function_BlockJump(client);
			LJBlockMenu(client);
		}
		else if(select == 1)
		{
			g_bLJBlock[client] = false;
			LJBlockMenu(client);
		}
	}
	else if(action == MenuAction_Cancel)
	{
		if(select == MenuCancel_Exit)
		{
		}
	}
	else if(action == MenuAction_End)
	{
	}
}
CalculateBlockGap(client, Float:origin[3], Float:target[3])
{
	new Float:distance = GetVectorDistance(origin, target);
	new Float:rad = DegToRad(15.0);
	new Float:newdistance = FloatDiv(distance, Cosine(rad));
	decl Float:eye[3], Float:eyeangle[2][3];
	new Float:temp = 0.0;
	GetClientEyePosition(client, eye);
	GetClientEyeAngles(client, eyeangle[0]);
	eyeangle[0][0] = 0.0;
	eyeangle[1] = eyeangle[0];
	eyeangle[0][1] += 10.0;
	eyeangle[1][1] -= 10.0;
	decl Float:position[3], Float:ground[3], Float:Last[2], Float:Edge[2][3];
	new bool:edgefound[2];
	while(temp < newdistance)
	{
		temp += 10.0;
		for(new i = 0; i < 2 ; i++)
		{
			if(edgefound[i])
				continue;
			GetBeamEndOrigin(eye, eyeangle[i], temp, position);
			TraceGroundOrigin(position, ground);
			if(temp == 10.0)
			{
				Last[i] = ground[2];
			}
			else
			{
				if((Last[i] != ground[2])&&(Last[i] > ground[2]))
				{
					Edge[i] = ground;
					edgefound[i] = true;
				}
				Last[i] = ground[2];
			}
		}
	}
	decl Float:temp2[2][3];
	if(edgefound[0] && edgefound[1])
	{
		for(new i = 0; i < 2 ; i++)
		{
			temp2[i] = Edge[i];
			temp2[i][2] = origin[2] - 1.0;
			if(eyeangle[i][1] > 0)
			{
				eyeangle[i][1] -= 180.0;
			}
			else
			{
				eyeangle[i][1] += 180.0;
			}
			GetBeamHitOrigin(temp2[i], eyeangle[i], Edge[i]);
		}
	}
	else
	{
		PrintToChat(client, "\x01[\x05LJstats\x01]\x03Invalid Block");
		return;
	}
	g_EdgePoint[client] = Edge[0];
	TE_SetupBeamPoints(Edge[0], Edge[1], g_Beam[0], 0, 0, 0, 10.0, 1.0, 1.0, 10, 0.0, {0,255,255,212}, 0);
	TE_SendToAll();
	MakeVectorFromPoints(Edge[0], Edge[1], position);
	g_EdgeVector[client] = position;
	NormalizeVector(g_EdgeVector[client], g_EdgeVector[client]);
	CorrectEdgePoint(client);
	GetVectorAngles(position, position);
	position[1] += 90.0;
	GetBeamHitOrigin(Edge[0], position, Edge[1]);
	TE_SetupBeamPoints(Edge[0], Edge[1], g_Beam[0], 0, 0, 0, 10.0, 1.0, 1.0, 10, 0.0, {0,255,255,212}, 0);
	TE_SendToAll();	
	distance = GetVectorDistance(Edge[0], Edge[1]);
	g_BlockDist[client] = RoundToNearest(distance);
	if(g_BlockDist[client] >= g_Stop_Block_LJ)
	{
		PrintToChat(client, "\x01[\x05LJstats\x01]\x03%d Unit Block registered (\x01ß\x03)", g_BlockDist[client]);
		g_bLJBlock[client] = true;
	}
	else
	{
		PrintToChat(client, "\x01[\x05LJstats\x01]\x03You can regiter block more than %.0f units.", g_Stop_Block_LJ);
	}
}
stock CalculateBlockGap2(client, Float:origin[2][3], Float:target[2][3])
{
	decl Float:temp[2][3];
	decl Float:edge[2][3], Float:result[3];
	if(origin[1][0] > target[0][0])
	{
		if(origin[0][1] < target[1][0])
		{
			PrintToChat(client, "1-a");
			temp[0] = origin[1];
			temp[0][1] = origin[0][1];
			temp[1] = target[0];
			temp[1][0] = target[1][0];
			g_BlockDist[client] = RoundToNearest(GetVectorDistance(temp[0], temp[1]));
		}
		else if(origin[1][1] > target[0][1])
		{
			PrintToChat(client, "1-b");
			temp[0] = origin[1];
			temp[1] = target[0];
			g_BlockDist[client] = RoundToNearest(GetVectorDistance(temp[0], temp[1]));
		}
		else
		{
			PrintToChat(client, "1-e");
			edge[0] = origin[1];
			edge[0][1] = origin[0][1];
			edge[1] = origin[1];
			GetGapVector(edge, result, -90.0);
			PrintToChat(client, "%f %f %f", result[0], result[1], result[2]);
		}
	}
	else if(origin[0][0] < target[1][0])
	{
		if(origin[0][1] < target[1][1])
		{
			PrintToChat(client, "1-c");
			temp[0] = origin[0];
			temp[1] = target[1];
			g_BlockDist[client] = RoundToNearest(GetVectorDistance(temp[0], temp[1]));
		}
		else if(origin[1][1] > target[0][1])
		{
			PrintToChat(client, "1-d");
			temp[0] = origin[0];
			temp[0][1] = origin[1][1];
			temp[1] = target[1];
			temp[1][1] = target[0][1];
			g_BlockDist[client] = RoundToNearest(GetVectorDistance(temp[0], temp[1]));
		}
		else
		{
			PrintToChat(client, "1-f");
			edge[0] = origin[1];
			edge[0][1] = origin[0][1];
			edge[1] = origin[1];
			GetGapVector(edge, result, 90.0);
			PrintToChat(client, "%f %f %f", result[0], result[1], result[2]);
		}
	}
	else
	{
		if(origin[1][1] > target[0][1])
		{
			PrintToChat(client, "1-g");
			edge[0] = origin[0];
			edge[1] = origin[0];
			edge[1][0] = origin[1][0];
			GetGapVector(edge, result, 90.0);
			PrintToChat(client, "%f %f %f", result[0], result[1], result[2]);
		}
		else if(origin[0][1] < target[1][1])
		{
			PrintToChat(client, "1-h");
			edge[0] = origin[0];
			edge[1] = origin[0];
			edge[1][0] = origin[1][0];
			GetGapVector(edge, result, -90.0);
			GetBoxGap
			if(target[1][0] <= origin[1][0] <= target[0][0])
			{
				temp[0][0] = GetRandomFloat(origin[1][0], target[0][0]);
			}
			else if(target[1][0] <= origin[0][0] <= target[0][0])
			{
				temp[0][0] = GetRandomFloat(target[1][0], origin[0][0]);
			}
			else
			{
				PrintToChat(client, "??");
			}
			temp[0] = origin[0];
			temp[0][2] -= 1.0;
			PrintToChat(client, "%f %f %f", temp[0][0], temp[0][1], temp[0][2]);
			PrintToChat(client, "%f %f %f", result[0], result[1], result[2]);
			GetBeamHitOrigin(temp[0], result, temp[1]);
			PrintToChat(client, "%f %f %f", temp[0][0], temp[0][1], temp[0][2]);
			PrintToChat(client, "%f %f %f", temp[1][0], temp[1][1], temp[1][2]);
			g_BlockDist[client] = RoundToNearest(GetVectorDistance(temp[0], temp[1]));
		}
	}
	
	if(g_BlockDist[client] >= g_Stop_Block_LJ)
	{
		PrintToChat(client, "\x01[\x05LJstats\x01]\x03%d Unit Block registered (\x01ß\x03)", g_BlockDist[client]);
		g_bLJBlock[client] = true;
	}
	else
	{
		PrintToChat(client, "\x01[\x05LJstats\x01]\x03You can regiter block more than %.0f units. (\x01ß\x03)", g_Stop_Block_LJ);
	}
	TE_SetupBeamPoints(origin[0], origin[1], g_Beam[0], 0, 0, 0, 10.0, 1.0, 1.0, 10, 0.0, {0,255,255,212}, 0);
	TE_SendToAll();
	TE_SetupBeamPoints(target[0], target[1], g_Beam[0], 0, 0, 0, 10.0, 1.0, 1.0, 10, 0.0, {0,255,255,212}, 0);
	TE_SendToAll();
	TE_SetupBeamPoints(temp[0], temp[1], g_Beam[0], 0, 0, 0, 10.0, 1.0, 1.0, 10, 0.0, {0,255,255,212}, 0);
	TE_SendToAll();
}
GetEdgeOrigin(client, Float:ground[3], Float:result[3])
{
	result[0] = FloatDiv(g_EdgeVector[client][0]*ground[0] + g_EdgeVector[client][1]*g_EdgePoint[client][0], g_EdgeVector[client][0]+g_EdgeVector[client][1]);
	result[1] = FloatDiv(g_EdgeVector[client][1]*ground[1] - g_EdgeVector[client][0]*g_EdgePoint[client][1], g_EdgeVector[client][1]-g_EdgeVector[client][0]);
	result[2] = ground[2];
}
CorrectEdgePoint(client)
{
	decl Float:vec[3];
	vec[0] = 0.0 - g_EdgeVector[client][1];
	vec[1] = g_EdgeVector[client][0];
	vec[2] = 0.0;
	ScaleVector(vec, 16.0);
	AddVectors(g_EdgePoint[client], vec, g_EdgePoint[client]);
}
API_OnLJChanged(client, bool:on)
{
	decl Action:result;
	Call_StartForward(g_LJMode_Forward);
	Call_PushCell(client);
	Call_PushCell(on);
	Call_Finish(_:result);
	return _:result;
}
public Action:Command_ljsound(client, args)
{
	if(0 < client <= MaxClients)
	{
		if(g_bLJplaysnd[client])
		{
			g_bLJplaysnd[client] = false;
			PrintToChat(client, "\x01[\x05LJstats\x01]\x03Sound \x01off.");
		}
		else
		{
			g_bLJplaysnd[client] = true;
			PrintToChat(client, "\x01[\x05LJstats\x01]\x03Sound \x01on.");
		}
	}
	return Plugin_Handled;
}
public Action:Command_ljpopup(client, args)
{
	if(0 < client <= MaxClients)
	{
		if(g_bLJpopup[client])
		{
			g_bLJpopup[client] = false;
			PrintToChat(client, "\x01[\x05LJstats\x01]\x03Popup \x01off.");
		}
		else
		{
			g_bLJpopup[client] = true;
			PrintToChat(client, "\x01[\x05LJstats\x01]\x03Popup \x01on.");
		}
	}
	return Plugin_Handled;
}
public Action:Command_measure(client, args)
{
	if(0 < client <= MaxClients)
	{
		for(new i = 0; i < 3; i++)
		{
			AimPoint_1[client][i] = 0.0;
			AimPoint_2[client][i] = 0.0;
		}
		AimStatus[client] = 0;
		AimMenu(client);
	}
	return Plugin_Handled;
}
AimMenu(client)
{
	new Handle:menu = CreateMenu(AimMenu_Handler);
	SetMenuTitle(menu, "Measure");
	if(AimStatus[client] == 0)
		AddMenuItem(menu, "0", "Select 1st point");
	else if(AimStatus[client] == 1)
		AddMenuItem(menu, "0", "Select 2nd point");
	else
		AddMenuItem(menu, "0", "measure it!");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public AimMenu_Handler(Handle:menu, MenuAction:click, client, select)
{
	if(click == MenuAction_Select)
	{
		if(AimStatus[client] == 0)
		{
			GetAimOrigin(client, AimPoint_1[client]);
			AimDrawing[client] = true;
			AimStatus[client] = 1;
			if(AimHandle[client]!=INVALID_HANDLE)
			{
				KillTimer(AimHandle[client]);
				AimHandle[client] = INVALID_HANDLE;
			}
			AimHandle[client] = CreateTimer(0.1, Draw_Aim, client, TIMER_REPEAT);
		}
		else if(AimStatus[client] == 1)
		{
			GetAimOrigin(client, AimPoint_2[client]);
			AimDrawing[client] = true;
			AimStatus[client] = 2;
		}
		else
		{
			AimStatus[client] = 0;
			MeasurePoint(client, AimPoint_1[client], AimPoint_2[client]);
		}
		AimMenu(client);
	}
	else if(click == MenuAction_Cancel)
	{
		if(select == MenuCancel_ExitBack)
		{
		}
		if(select == MenuCancel_Exit)
		{
		}
	}
	else if(click == MenuAction_End)
	{
		CloseHandle(menu);
	}
}
stock MeasurePoint(client, const Float:pos1[3], const Float:pos2[3])
{
	decl Float:height, Float:width, Float:length;
	height = FloatAbs(pos1[2] - pos2[2]);
	width = SquareRoot((pos2[0] - pos1[0])*(pos2[0] - pos1[0]) + (pos2[1] - pos1[1])*(pos2[1] - pos1[1]));
	length = GetVectorDistance(pos1, pos2);
	PrintToChat(client, "\x01[\x05LJstats\x01]\x03%.2f units, width : %.2f units, height : %.2f units", length, width, height);
	CreateTimer(2.0, Reset_Drawing_Aim, client);
}
public Action:Draw_Aim(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		new Float:origin1[3], Float:origin2[3];
		if(AimStatus[client] == 1)
		{
			origin1 = AimPoint_1[client];
			GetAimOrigin(client, origin2);
		}
		else
		{
			origin1 = AimPoint_1[client];
			origin2 = AimPoint_2[client];
		}
		TE_SetupBeamPoints(origin1, origin2, g_Beam[0], 0, 0, 0, 0.1, 3.0, 3.0, 10, 0.0, {125,125,125,255}, 0);
		TE_SendToClient(client);
		return Plugin_Continue;
	}
	else
	{
		return Plugin_Stop;
	}
}	
public Action:Reset_Drawing_Aim(Handle:timer, any:client)
{
	if(AimHandle[client]!=INVALID_HANDLE)
	{
		KillTimer(AimHandle[client]);
		AimHandle[client] = INVALID_HANDLE;
	}
}
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	static bool:OnLastGround[MAXPLAYERS + 1], Float:HintTimer[MAXPLAYERS + 1], Float:LastPosition[MAXPLAYERS + 1][3], Float:LastVelocity[MAXPLAYERS + 1], LastButton[MAXPLAYERS + 1], LastStrafe[MAXPLAYERS + 1], Float:LastAngle[MAXPLAYERS + 1], bool:MovingLeft[MAXPLAYERS + 1], bool:MovingRight[MAXPLAYERS + 1], MoveType:LastMoveType[MAXPLAYERS + 1];
	if(IsClientInGameAlive(client))
	{
		if(g_bLJmode[client])
		{
			new Float:temp[3], Float:origin[3];
			GetEntPropVector(client, Prop_Data, "m_vecVelocity", temp);
			temp[2] = 0.0;
			new Float:newvelo = GetVectorLength(temp);
			GetClientAbsOrigin(client, origin);
			new MoveType:movetype = GetEntityMoveType(client);
			new Float:ang[3];
			GetClientEyeAngles(client, ang);
			if(ang[1] < 0)
			{
				ang[1] += 360.0;
			}
			if(GetEntityFlags(client)&FL_ONGROUND)
			{//?????
				if(!OnLastGround[client])
				{//?? ????.
					OnGroundTime[client] = GetGameTime();
					if(g_bValidJump[client])
					{//?????.
						GetGroundOrigin(client, g_fOnGroundPos[client]);
						if(GetEntityFlags(client)&FL_DUCKING)
						{
							NoDucking[client] = false;
							// g_fOnGroundPos[client][2] += 0.68;
						}
						else
						{
							NoDucking[client] = true;
						}
						LJStats(client, false);
						g_bValidJump[client] = false;
					}
				}
				else
				{

					if(GetGameTime() >= OnGroundTime[client] + LJDELAY)
					{
						if(PlayerReadyType[client] != ReadyType_LongJump && PlayerReadyType[client] != ReadyType_BlockLongJump)
						{
							PlayerReadyType[client] = ReadyType_LongJump;
						}
					}
					else if(GetGameTime() >= OnGroundTime[client] + ELSEDELAY)
					{
						PlayerReadyType[client] = ReadyType_None;
					}
				}
				if(GetGameTime() >= HintTimer[client])
				{
					if(PlayerReadyType[client] == ReadyType_LongJump||PlayerReadyType[client] == ReadyType_BlockLongJump)
					{
						HintTimer[client] = GetGameTime() + 0.1;
						decl Float:edge[3], Float:dist, Float:ground[3], String:edgeinfo[64];
						edgeinfo[0] = '\0';
						if(g_bLJBlock[client])
						{
							GetGroundOrigin(client, ground);
							GetEdgeOrigin(client, ground, edge);
							dist = GetVectorDistance(edge, ground);
							Format(edgeinfo, sizeof(edgeinfo), "\nEdge : %.3f", dist);
							TE_SendBlockPoint(client, g_DestBlock[client][0], g_DestBlock[client][1], g_Beam[0]);
							TE_SendBlockPoint(client, g_OriginBlock[client][0], g_OriginBlock[client][1], g_Beam[0]);
							// TE_SetupBeamPoints(ground, trueground, g_Beam[0], 0, 0, 0, 0.13, 5.0, 2.0, 10, 0.0, {255, 254, 125, 255}, 0);
							// TE_SendToClient(client);
							if(!IsCoordInBlockPoint(ground, g_OriginBlock[client]))
							{
								Format(edgeinfo, sizeof(edgeinfo), "");
							}
							else
							{
								PlayerReadyType[client] = ReadyType_BlockLongJump;
							}
						}
						
						Client_PrintHintText(client, "Prestrafe\n%.2f%s", newvelo, edgeinfo);
						for (new i = 1; i <= MaxClients; i++)
						{
							if (IsClientInGame(i))
							{
								if(!IsPlayerAlive(i) || IsClientObserver(i))
								{
									new iObserverMode = GetEntProp(i, Prop_Send, "m_iObserverMode");
									if(iObserverMode == SPECMODE_FIRSTPERSON || iObserverMode == SPECMODE_3RDPERSON)
									{
										new target = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget");
										
										if(target != client || target == i)
											continue;
										
										if(target <= 0 || target > MaxClients)
											continue;
										
										Client_PrintHintText(i, "Prestrafe\n%.2f%s", newvelo, edgeinfo);
									}
									else
									{
										continue;
									}
								}
							}
						}
					}
				}
				LastStrafe[client] = 0;
				OnLastGround[client] = true;
			}
			else
			{//?? ???
				if(movetype == MOVETYPE_WALK)
				{
					if(LastMoveType[client] == MOVETYPE_LADDER)
					{
						StartJumpStats(client, JumpType_Ladder, LastPosition[client], LastVelocity[client]);
					}
					else
					{
						if(!g_bValidJump[client])
						{
							if(OnLastGround[client])
							{//?? ?? ?????.
								if(!(LastButton[client]&IN_JUMP))
								{
									PlayerReadyType[client] = ReadyType_Wj;
								}
							}
						}
						else
						{//??? ?????.
							if(GetEntityFlags(client)&FL_INWATER)
							{
								g_bValidJump[client] = false;
								PrintToChat(client, "\x01[\x05LJstats\x01]\x03Jump canceled \x01: Swimming.");
							}
							new Float:pos[3];
							GetGroundOrigin2(client, pos);
							if(ang[1] > LastAngle[client])
							{
								MovingLeft[client] = true;
								MovingRight[client] = false;
							}
							else if(ang[1] < LastAngle[client])
							{
								MovingLeft[client] = false;
								MovingRight[client] = true;
							}
							else
							{
								MovingLeft[client] = false;
								MovingRight[client] = false;
							}
							if(newvelo > LJ_MaxSpeed[client])
							{
								LJ_MaxSpeed[client] = newvelo;
							}
							if((buttons & IN_MOVELEFT)&&(!(buttons & IN_MOVERIGHT))&&!(LastStrafe[client]&IN_MOVELEFT))
							{
								g_Strafe[client]++;
								LastStrafe[client] = IN_MOVELEFT;
							}
							else if((buttons & IN_MOVERIGHT)&&(!(buttons&IN_MOVELEFT))&&!(LastStrafe[client]&IN_MOVERIGHT))
							{
								g_Strafe[client]++;
								LastStrafe[client] = IN_MOVERIGHT;
							}
							if(MAXSTR > g_Strafe[client] > 0)
							{
								if(newvelo > LJ_MaxSpeedStrafe[client][g_Strafe[client]-1])
									LJ_MaxSpeedStrafe[client][g_Strafe[client]-1] = newvelo;
								if(MovingLeft[client]||MovingRight[client])
								{
									if(LastVelocity[client] < newvelo)
									{
										LJ_GoodSync[client][g_Strafe[client]-1]++;
										LJ_Gains[client][g_Strafe[client]-1] += (newvelo - LastVelocity[client]);
									}
									else
									{
										LJ_Lost[client][g_Strafe[client]-1] += (LastVelocity[client] - newvelo);
									}
								}
								LJ_Frame[client][g_Strafe[client]-1]++;
							}
							LJ_TotalFrame[client]++;
							if(g_bLJBlock[client])
							{
								if(origin[2] <= g_fBlockHeight[client])
								{
									// GetClientAbsOrigin(client, g_fOnGroundPos[client]);
									g_fOnGroundPos[client] = origin;
									g_fOnGroundPos[client][2] = g_fBlockHeight[client];
									LJStats(client, true);
									g_bValidJump[client] = false;
								}
							}
						}
					}
				}
				OnLastGround[client] = false;
			}
			new Float:distance = GetVectorDistance(LastPosition[client], origin);
			if(distance > 25.0)
			{
				if(g_bValidJump[client])
				{
					g_bValidJump[client] = false;
				}
			}
			LastAngle[client] = ang[1];
			LastMoveType[client] = movetype;
			LastVelocity[client] = newvelo;
			LastPosition[client] = origin;
			LastButton[client] = buttons;
		}
	}
}
ResetLJStats(client)
{
	g_Strafe[client] = 0;
	LJ_MaxSpeed[client] = 0.0;
	LJ_TotalFrame[client] = 0;
	for(new i = 0; i < MAXSTR; i++)
	{
		LJ_Gains[client][i] = 0.0;
		LJ_Lost[client][i] = 0.0;
		LJ_Frame[client][i] = 0;
		LJ_GoodSync[client][i] = 0;
		LJ_BadSync[client][i] = 0;
		LJ_SyncRateStrafe[client][i] = 0.0;
		LJ_MaxSpeedStrafe[client][i] = 0.0;
	}
}
StartJumpStats(client, JumpType:type, Float:pos[3], Float:vel)
{
	decl String:weapon_name[64];
	GetClientWeapon(client, weapon_name, sizeof(weapon_name));
	if(StrEqual(weapon_name, "weapon_scout")||strlen(weapon_name)==0)
	{
		PrintToChat(client, "\x01[\x05LJstats\x01]\x03Wrong : \x01Check your weapon.");
		return;
	}
	new Float:gravity = GetEntityGravity(client);
	if(gravity != 0.0&&gravity!=1.0)
	{
		g_bLJmode[client] = false;
		PrintToChat(client, "\x01[\x05LJstats\x01]\x03LJmode disabled : \x01Check Gravity.");
	}
	ResetLJStats(client);
	g_fJumpedPos[client] = pos;
	PreStrafe[client] = vel;
	g_bValidJump[client] = true;
	PlayerJumpType[client] = type;
	PlayerReadyType[client] = ReadyType_None;
	decl String:msg[512];
	Format(msg, 512, "Prestrafe\n%.2f", PreStrafe[client]);
	if(g_bLJBlock[client])
	{
		if(!IsCoordInBlockPoint(pos, g_OriginBlock[client]))
		{
			g_bValidJump[client] = false;
			return;
		}
		Format(msg, 512, "%s\nEdge : %f", msg, g_EdgeDist[client]);
	}

	Client_PrintHintText(client, msg);
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if(!IsPlayerAlive(i) || IsClientObserver(i))
			{
				new iObserverMode = GetEntProp(i, Prop_Send, "m_iObserverMode");
				if(iObserverMode == SPECMODE_FIRSTPERSON || iObserverMode == SPECMODE_3RDPERSON)
				{
					new target = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget");
					
					if(target != client || target == i)
						continue;
					
					if(target <= 0 || target > MaxClients)
						continue;
					
					Client_PrintHintText(i, msg);
				}
				else
				{
					continue;
				}
			}
		}
	}
}
public Action:LJStats(client, bool:fail)
{
	decl Float:LJ_FrameRate[MAXSTR];
	for(new i = 0; i < g_Strafe[client]; i++)
	{
		if(i < MAXSTR)
		{
			LJ_SyncRateStrafe[client][i] = (LJ_GoodSync[client][i]*100.0/LJ_Frame[client][i]);
			LJ_FrameRate[i] = LJ_Frame[client][i]*100.0/LJ_TotalFrame[client];
		}
	}
	new JumpType:J_type = PlayerJumpType[client];
	new Float:temp1[3], Float:temp2[3];
	temp1 = g_fJumpedPos[client];
	temp2 = g_fOnGroundPos[client];
	if(fail)
	{
		temp2[2] = g_fJumpedPos[client][2];
	}
	// PrintToChat(client, "\x04landed : %f", temp2[2]);
	// temp1[2] = 0.0;
	// temp2[2] = 0.0;
	new Float:distance, Float:blockdistance;
	if(fail)
	{
		distance = GetVectorDistance(temp1, temp2) + 32.0 - g_EdgeDist[client];
	}
	else
	{
		distance = GetVectorDistance(temp1, temp2) + 32.0;
	}
	LJ_SyncRate[client] = 0.0;
	new good, total;
	for(new i = 0; i <= g_Strafe[client]; i++)
	{
		if(i < MAXSTR)
		{
			good += LJ_GoodSync[client][i];
			total += LJ_Frame[client][i];
		}
	}
	LJ_SyncRate[client] = good*100.0/total;
	if(J_type != JumpType_Ladder)
	{/**Compare jumped and landed heights. although tried to get correct z-coord by custom function. still has an error.
		0.002 value determined with no reason.**/
		if((temp1[2] - temp2[2]) > 0.002)
		{
			if(J_type == JumpType_Wj)
			{
				J_type = JumpType_WjDrop;
			}
			else
			{
				if(J_type!=JumpType_BhopJump&&J_type!=JumpType_BhopUpJump)
				{
					J_type = JumpType_DropJump;
				}
				else
				{
					return Plugin_Handled;
				}
			}
		}
		else if((temp2[2] - temp1[2]) > 0.002)
		{
			if(J_type == JumpType_Wj)
			{
				J_type = JumpType_WjUp;
			}
			else
			{
				if(J_type != JumpType_WjUp && J_type != JumpType_BhopUpJump)
				{
					J_type = JumpType_UpJump;
					PlayerReadyType[client] = ReadyType_BhopUpJump;
				}
				else
				{
					return Plugin_Handled;
				}
			}
		}
		else
		{
			if(J_type == JumpType_LongJump)
			{
				PlayerReadyType[client] = ReadyType_BhopJump;
				if(PreStrafe[client] >= g_InvalidUnit||distance >= g_InvalidUnit)
				{
					PrintToChat(client, "\x01[\x05LJstats\x01]\x03Wrong jump.");
					return Plugin_Handled;
				}
				if(distance <= g_Stop_LJ && !fail)
				{
					return Plugin_Handled;
				}
			}
			else if(J_type == JumpType_BlockLongJump&&!fail)
			{
				if(!IsCoordInBlockPoint(temp2, g_DestBlock[client]))
				{
					if(IsCoordInBlockPoint(temp2, g_OriginBlock[client]))
					{
						PlayerReadyType[client] = ReadyType_BlockBhopJump;
					}
					return Plugin_Handled;
				}
				else
				{
					blockdistance = float(g_BlockDist[client]);
				}
			}
			else if(J_type == JumpType_BlockBhopJump&&!fail)
			{
				if(!IsCoordInBlockPoint(temp2, g_DestBlock[client]))
				{
					return Plugin_Handled;
				}
				else
				{
					blockdistance = float(g_BlockDist[client]);
				}
			}
			else if(J_type == JumpType_BhopJump)
			{
				if(distance < g_Stop_BJ)
				{
					return Plugin_Handled;
				}
			}
			else if(J_type == JumpType_BhopUpJump)
			{
				if(distance < g_Stop_BUJ)
				{
					return Plugin_Handled;
				}
			}
		}
	}
	if(distance < 200.0)
	{
		return Plugin_Handled;
	}
	new Handle:menu = CreateMenu(emptyhandler);
	decl String:desc[1024], String:postfix[15], String:hint[255], String:num[5], String:max[50], String:gain[50], String:lose[50], String:sync[50], String:framerate[50], String:cns[1024], String:edge[40], Float:width, Float:height;
	edge[0] = '\0';
	Format(desc, 1024, "%s", JumpName[J_type]);
	postfix[0] = '\0';
	if(fail)
	{
		Format(desc, 1024, "%s (Failed)", desc);
		Format(postfix, sizeof(postfix), "(Failed)");
		Format(edge, sizeof(edge), ", Edge : %.3f", g_EdgeDist[client]);
	}
	else
	{
		if(g_bLJBlock[client])
		{
			Format(edge, sizeof(edge), ", Edge : %.3f", g_EdgeDist[client]);
			g_bLJBlock[client] = false;
		}
	}
	Format(desc, sizeof(desc), "%s%s", desc, edge);
	if(J_type == JumpType_Ladder)
	{
		width = SquareRoot((temp2[0] - temp1[0])*(temp2[0] - temp1[0]) + (temp2[1] - temp1[1])*(temp2[1] - temp1[1]))+32.0;
		height = FloatAbs(temp1[2] - temp2[2]);
	}
	SetMenuTitle(menu, "Stats-%N", client);
	if(J_type == JumpType_Ladder)
	{
		Format(hint, 255, "%s%s\n [Distance] %.2f\n [Height] %.2f\n [PreStrafe] %.2f\n [Strafe] %d\n [MaxSpeed] %.2f\n%.2f",JumpName[J_type], postfix, width, height, PreStrafe[client], g_Strafe[client], LJ_MaxSpeed[client], LJ_SyncRate[client]);
		Format(cns, 255, "%s%s Distance : %.2f, Height : %.2f, PreStrafe : %.2f, Strafe : %d, MaxSpeed : %.2f, Sync : %.2f%s",JumpName[J_type], postfix, width, height, PreStrafe[client], g_Strafe[client], LJ_MaxSpeed[client], LJ_SyncRate[client], edge);
	}
	else
	{
		Format(hint, 255, "%s%s\n [Distance] %.2f\n [PreStrafe] %.2f\n [Strafe] %d\n [MaxSpeed] %.2f\n%.2f",JumpName[J_type], postfix, distance, PreStrafe[client], g_Strafe[client], LJ_MaxSpeed[client], LJ_SyncRate[client]);
		Format(cns, 1024, "%s%s Distance : %.2f, PreStrafe : %.2f Strafe : %d, MaxSpeed : %.2f, Sync : %.2f%s",JumpName[J_type], postfix, distance, PreStrafe[client], g_Strafe[client], LJ_MaxSpeed[client], LJ_SyncRate[client], edge);
	}
	
	Client_PrintKeyHintText(client, hint);
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if(!IsPlayerAlive(i) || IsClientObserver(i))
			{
				new iObserverMode = GetEntProp(i, Prop_Send, "m_iObserverMode");
				if(iObserverMode == SPECMODE_FIRSTPERSON || iObserverMode == SPECMODE_3RDPERSON)
				{
					new target = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget");
					
					if(target != client || target == i)
						continue;
					
					if(target <= 0 || target > MaxClients)
						continue;
					
					Client_PrintKeyHintText(i, hint);
				}
				else
				{
					continue;
				}
			}
		}
	}

	Format(cns, 1024,"%s\n#Strafe  MaxSpeed  Gains  Loses   Time  Sync",cns);
	for(new i = 0; i < g_Strafe[client]; i++)
	{
		if(i < 12)
		{
			Format_Num(i+1, num, 5, true);
			FormatTime_LJ(LJ_MaxSpeedStrafe[client][i], max, 50, true);
			FormatTime_LJ(LJ_Gains[client][i], gain, 50, true);
			FormatTime_LJ(LJ_Lost[client][i], lose, 50, true);
			FormatTime_LJ(LJ_SyncRateStrafe[client][i], sync, 50, true);
			FormatTime_LJ(LJ_FrameRate[i], framerate, 50, true);
			Format(desc, 1024, "%s\n %s %s %s %s %s %s", desc, num, max, gain, lose, framerate, sync);
		}
	}
	for(new i = 0; i < g_Strafe[client]; i++)
	{
		if(i < MAXSTR)
		{
			Format_Num(i+1, num, 5, false);
			FormatTime_LJ(LJ_MaxSpeedStrafe[client][i], max, 50, false);
			FormatTime_LJ(LJ_Gains[client][i], gain, 50, false);
			FormatTime_LJ(LJ_Lost[client][i], lose, 50, false);
			FormatTime_LJ(LJ_SyncRateStrafe[client][i], sync, 50, false);
			FormatTime_LJ(LJ_FrameRate[i], framerate, 50, false);
			Format(cns, 1024, "%s\n   %s     %s  %s %s %s %s", cns, num, max, gain, lose, framerate, sync);	
		}
	}
	if(NoDucking[client])
	{
		Format(desc, 1024, "%s\n   %.2f%%  +No Duck", desc, LJ_SyncRate[client]);
		Format(cns, 1024, "%s\n   +No Duck", cns);
		NoDucking[client] = false;
	}
	else
		Format(desc, 1024, "%s\n   %.2f%%", desc, LJ_SyncRate[client]);
	PrintToConsole(client, cns);
	PrintToConsole(client, "     ");
	AddMenuItem(menu, "0", desc);
	SetMenuExitButton(menu, false);
	if(g_bLJpopup[client])
	{
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
	for(new g = 1; g <= MaxClients; g++)
	{
		if(IsClientInGame(g))
		{
			if(IsClientObserver(g))
			{
				new obTarget = GetEntPropEnt(g, Prop_Send, "m_hObserverTarget");
				if((obTarget > 0)&&(obTarget==client))
				{
					DisplayMenu(menu, g, MENU_TIME_FOREVER);
					
					Client_PrintKeyHintText(g, hint);
					
					PrintToConsole(g, cns);
					PrintToConsole(g, "     ");
				}
			}
		}
	}
	if(fail)
	{
		return Plugin_Handled;
	}
	if(J_type == JumpType_Wj||J_type == JumpType_WjUp)
	{
		if(distance >= g_Print_WJ)
		{
			PrintToChatLJ("\x04[\x01%s\x04]\x03%N - \x01%.3f\x04units!",JumpName[J_type],client,distance);
		}
	}
	else if(J_type == JumpType_LongJump)
	{
		if(distance >= g_Print_LJ)
		{
			PrintToChatLJ("\x04[\x01%s\x04]\x03%N - \x01%.3f\x04units!",JumpName[J_type],client,distance);
			PlayLJSound(client, distance);
		}
	}
	else if(J_type == JumpType_BlockLongJump)
	{
		if(blockdistance >= g_Print_Block_LJ)
		{
			PrintToChatLJ("\x04[\x01%s\x04]\x03%N - \x01%.0f\x04units!\n (actual : %.3f, Edge : %.3f)",JumpName[J_type],client,blockdistance, distance, g_EdgeDist[client]);
			PlayLJSound(client, distance);
		}
	}
	else if(J_type == JumpType_BlockBhopJump)
	{
		if(blockdistance >= g_Print_Block_BJ)
		{
			PrintToChatLJ("\x04[\x01%s\x04]\x03%N - \x01%.0f\x04units!\n (actual : %.3f, Edge : %.3f)",JumpName[J_type],client,blockdistance, distance, g_EdgeDist[client]);
		}
	}
	else if(J_type == JumpType_BhopJump||J_type == JumpType_BhopUpJump)
	{
		if(distance >= g_Print_BJ)
		{
			PrintToChatLJ("\x04[\x05%s\x04]\x03%N - \x01%.3f\x04units!",JumpName[J_type],client,distance);
		}
	}
	
	if(distance >= g_DB_Record)
	{
		new mode = Timer_GetMode(client);
		
		if(g_Physics[mode][ModeLJStats])
		{
			if(IsValidType(J_type))
			{
				RecordQuery(client, J_type, distance, PreStrafe[client], g_Strafe[client]);
			}
			if(IsBlockJumpType(J_type))
			{
				if(J_type == JumpType_BlockLongJump)
				{
					RecordQuery(client, JumpType_LongJump, distance, PreStrafe[client], g_Strafe[client]);
					RecordQuery(client, J_type, blockdistance, PreStrafe[client], g_Strafe[client]);
				}
				else if(J_type == JumpType_BlockBhopJump)
				{
					RecordQuery(client, JumpType_BhopJump, distance, PreStrafe[client], g_Strafe[client]);
					RecordQuery(client, J_type, blockdistance, PreStrafe[client], g_Strafe[client]);
				}
			}
		}
	}
	
	return Plugin_Continue;
}
public emptyhandler(Handle:menu, MenuAction:action, client, select)
{
	if(action == MenuAction_Select)
	{

	}
	else if(action == MenuAction_Cancel)
	{
		if(select == MenuCancel_ExitBack)
		{

		}
		else if(select == MenuCancel_Exit)
		{
		}
	}
	else if(action == MenuAction_End)
	{
	}
}
stock Format_Num(const num, String:txt[], iSize, bool:popup)
{
	if(popup)
	{
		if(num<10)
			Format(txt, iSize, "  %d",num);
		else
			Format(txt, iSize, "%d", num);
	}
	else
	{
		if(num<10)
			Format(txt, iSize, " %d",num);
		else
			Format(txt, iSize, "%d", num);
	}
}
stock FormatTime_LJ(const Float:time, String:txt[], iSize, bool:popup)
{
	if(popup)
	{
		if(time >= 100.0)
			Format(txt, iSize, "%.2f", time);
		else if(10.0 < time < 100.0)
			Format(txt, iSize, " %.2f ", time);
		else if(time < 10.0)
			Format(txt, iSize, "  %.2f  ", time);
	}
	else
	{
		if(time >= 100.0)
			Format(txt, iSize, "%.2f", time);
		else if(10.0 < time < 100.0)
			Format(txt, iSize, " %.2f", time);
		else if(time < 10.0)
			Format(txt, iSize, "  %.2f", time);
	}
}
stock PrintToChatLJ(const String:msg[], any:...)
{
	decl String:buffer[512];
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if(g_ShowMsg == 0)
			{
				SetGlobalTransTarget(i);
				VFormat(buffer, sizeof(buffer), msg, 2);
				PrintToChat(i, buffer);
			}
			else
			{
				if(g_bLJmode[i])
				{
					SetGlobalTransTarget(i);
					VFormat(buffer, sizeof(buffer), msg, 2);
					PrintToChat(i, buffer);
				}
			}
		}
	}
}
PlayLJSound(client, Float:distance)
{
	new playsound = -1;
	if(distance < g_Sound[0])
		return;
	if(g_Sound[0] <= distance < g_Sound[1])
		playsound = 0;
	else if(distance < g_Sound[2])
		playsound = 1;
	else if(distance < g_Sound[3])
		playsound = 2;
	else if(distance < g_Sound[4])
		playsound = 3;
	else if(g_Sound[4] <= distance)
		playsound = 4;
	if(playsound != -1)
	{
		if(g_bLJplaysnd[client])
		{
			EmitSoundToClient(client, LJ_SOUND[playsound]);
		}
	}
}
/*********************************
*******************QUERY*********/
ConnectToDB()
{
	decl String:dbname[128];
	GetConVarString(g_hCvar_DB, dbname, sizeof(dbname));
	if(strlen(dbname) > 0)
	{
		SQL_TConnect(getmaindb, dbname);
	}
}
public getmaindb(Handle:owner, Handle:dbhandle, const String:error[], any:data)
{//check current connection. and data tables
	if(dbhandle == INVALID_HANDLE)
	{
		PrintToChatAll("Ljstats DB connection Failed : %s", error);
	}
	else
	{
		maindb = dbhandle;
		SQL_TQuery(maindb, empty_query, "create table if not exists `ljstats` (`id` INTEGER PRIMARY KEY, `steamid` varchar(64) NOT NULL,`name` varchar(64) NOT NULL, `type` int(11) NOT NULL, `distance` float NOT NULL,`pre` float NOT NULL,`strafe` int(11) NOT NULL);", DBPrio_High);
	}
}
public empty_query(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if(hndl == INVALID_HANDLE)
	{
		PrintToChatAll("error %s", error);
	}
}

RecordQuery(client, JumpType:type, Float:distance, Float:pre, strafe)
{
	if(maindb != INVALID_HANDLE)
	{
		decl String:query[512], String:steamid[64], String:temp[64], String:name[64];
		GetClientName(client, temp, sizeof(temp));
		SQL_EscapeString(maindb, temp, name, sizeof(name));
		GetClientAuthString(client, steamid, sizeof(steamid));
		Format(query, sizeof(query), "select distance from 'ljstats' where steamid = '%s' and type = %d", steamid, type);
		new Handle:datapack = CreateDataPack();
		WritePackString(datapack, steamid);
		WritePackString(datapack, name);
		WritePackCell(datapack, _:type);
		WritePackFloat(datapack, distance);
		WritePackFloat(datapack, pre);
		WritePackCell(datapack, strafe);
		SQL_TQuery(maindb, SelectRecord, query, datapack);
	}
}

public SelectRecord(Handle:owner, Handle:hndl, const String:error[], any:datapack)
{
	ResetPack(datapack);
	decl String:steamid[64], String:name[64];
	ReadPackString(datapack, steamid, sizeof(steamid));
	ReadPackString(datapack, name, sizeof(name));
	new type = ReadPackCell(datapack);
	new Float:distance = ReadPackFloat(datapack);
	new Float:pre = ReadPackFloat(datapack);
	new strafe = ReadPackCell(datapack);
	CloseHandle(datapack);
	if(hndl == INVALID_HANDLE)
	{
		LogError("error %s", error);
	}
	else
	{
		new DBResult:result;
		decl String:query[512];
		if(SQL_GetRowCount(hndl) != 0)
		{
			while(SQL_FetchRow(hndl))
			{
				new Float:temp = SQL_FetchFloat(hndl, 0, result);
				if(distance > temp)
				{
					Format(query, sizeof(query), "update 'ljstats' set name = '%s', distance = %f, pre = %f, strafe = %d where steamid = '%s' and type = %d", name, distance, pre, strafe, steamid, type);
					SQL_TQuery(maindb, empty_query, query, 0);
				}
			}
		}
		else
		{
			Format(query, sizeof(query), "insert into 'ljstats' (steamid, name, type, distance, pre, strafe) values('%s', '%s', %d, %f, %f, %d)", steamid, name, type, distance, pre, strafe);
			SQL_TQuery(maindb, empty_query, query, 0);
		}
	}
}
public Action:Command_ljadm(client, args)
{
	if(client != 0)
	{
		AdmTopMenu(client);
	}
	return Plugin_Handled;
}

public Action:Command_ljtop(client, args)
{
	if(client != 0)
	{
		TopMenu(client);
	}
	return Plugin_Handled;
}

TopMenu(client)
{
	if(h_TopMenu!=INVALID_HANDLE)
	{
		DisplayMenu(h_TopMenu, client, MENU_TIME_FOREVER);
	}
}

LJBlockMenu(client)
{
	if(h_LJBlockMenu != INVALID_HANDLE)
	{
		DisplayMenu(h_LJBlockMenu, client, MENU_TIME_FOREVER);
	}
}

CreateTopMenu()
{
	h_TopMenu = CreateMenu(TopListHandler);
	SetMenuTitle(h_TopMenu, "LongJump Stats Top\n Bug Report : jsbhop@gmail.com\n Weird jump records will be reset soon.");
	decl String:info[10];
	for(new JumpType:i = JumpType_None ; i < JumpType; i++)
	{
		if(IsDBType(i))
		{
			Format(info, sizeof(info), "%d", i);
			AddMenuItem(h_TopMenu, info, JumpName[i]);
		}
	}
	h_LJBlockMenu = CreateMenu(LJBlockHandler);
	SetMenuTitle(h_LJBlockMenu, "Block Jump Menu");
	AddMenuItem(h_LJBlockMenu, "0", "Select Destination");
	AddMenuItem(h_LJBlockMenu, "0", "Reset Destination");
}
AdmTopMenu(client)
{
	new Handle:menu = CreateMenu(AdmTopMenu_Handler);
	SetMenuTitle(menu, "Select JumpType of record to fix");
	decl String:info[10];
	for(new JumpType:i = JumpType_None ; i < JumpType; i++)
	{
		if(IsDBType(i))
		{
			Format(info, sizeof(info), "%d", i);
			AddMenuItem(menu, info, JumpName[i]);
		}
	}
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public AdmTopMenu_Handler(Handle:menu, MenuAction:action, client, select)
{
	if(action == MenuAction_Select)
	{
		decl String:info[10];
		GetMenuItem(menu, select, info, sizeof(info));
		Query_GetTop(client, JumpType:StringToInt(info), true);
	}
	else if(action == MenuAction_Cancel)
	{
		if(select == MenuCancel_Exit)
		{
		}
	}
	else if(action == MenuAction_End)
	{
	}
}
public TopListHandler(Handle:menu, MenuAction:action, client, select)
{
	if(action == MenuAction_Select)
	{
		decl String:info[10];
		GetMenuItem(menu, select, info, sizeof(info));
		Query_GetTop(client, JumpType:StringToInt(info), false);
	}
	else if(action == MenuAction_Cancel)
	{
		if(select == MenuCancel_Exit)
		{
		}
	}
	else if(action == MenuAction_End)
	{
	}
}
Query_GetTop(client, JumpType:type, bool:adm)
{
	if(maindb != INVALID_HANDLE)
	{
		new userid = GetClientUserId(client);
		decl String:query[512];
		new Handle:datapack = CreateDataPack();
		WritePackCell(datapack, userid);
		WritePackCell(datapack, _:type);
		Format(query, sizeof(query), "select id, name, distance, pre, strafe from 'ljstats' where type = %d order by distance desc limit 10", type);
		if(!adm)
		{			
			SQL_TQuery(maindb, query_toplist_menu, query, datapack);
		}
		else
		{
			SQL_TQuery(maindb, query_toplist_menu_adm, query, datapack);
		}
	}
}
public query_toplist_menu(Handle:owner, Handle:hndl, const String:error[], any:datapack)
{
	ResetPack(datapack);
	new userid = ReadPackCell(datapack);
	new JumpType:type = JumpType:ReadPackCell(datapack);
	CloseHandle(datapack);
	new client = GetClientOfUserId(userid);
	if (hndl == INVALID_HANDLE)
	{
		LogError("toplist_menu %s", error);
	}
	else
	{
		new Handle:panel = CreatePanel(INVALID_HANDLE);
		decl String:text[256], String:name[64], Float:distance, Float:pre, strafe, DBResult:result;
		Format(text, sizeof(text), "LongJump Stats Top - %s", JumpName[type]);
		SetPanelTitle(panel, text);
		if(SQL_GetRowCount(hndl) != 0)
		{
			new count;
			while(SQL_FetchRow(hndl))
			{
				SQL_FetchString(hndl, 1, name, sizeof(name), result);
				distance = SQL_FetchFloat(hndl, 2, result);
				pre = SQL_FetchFloat(hndl, 3, result);
				strafe = SQL_FetchInt(hndl, 4, result);
				Format(text, sizeof(text), "%s - %.3f (%.2f, %d stf)", name, distance, pre, strafe);
				DrawPanelItem(panel, text);
				count++;
			}
		}
		else
		{
			DrawPanelText(panel, "     No Records     ");
		}
		DrawPanelText(panel, "<9>. Go Back");
		DrawPanelText(panel, "<0>. Exit");
		SetPanelKeys(panel, (1<<8)|(1<<9));
		SendPanelToClient(panel, client, toplist_handler, MENU_TIME_FOREVER);
		CloseHandle(panel);
	}
}
public toplist_handler(Handle:menu, MenuAction:action, client, select)
{
	if (action == MenuAction_Select)
	{
		if(select == 9)
		{
			TopMenu(client);
		}
	}
	else if (action == MenuAction_Cancel)
	{
	}
}
public query_toplist_menu_adm(Handle:owner, Handle:hndl, const String:error[], any:datapack)
{
	ResetPack(datapack);
	new userid = ReadPackCell(datapack);
	new JumpType:type = JumpType:ReadPackCell(datapack);
	CloseHandle(datapack);
	new client = GetClientOfUserId(userid);
	if (hndl == INVALID_HANDLE)
	{
		LogError("toplist_menu %s", error);
	}
	else
	{
		new Handle:menu = CreateMenu(AdmMenu_Handler);
		decl String:text[256], String:info[20], String:name[64], Float:distance, DBResult:result, id;
		Format(text, sizeof(text), "Select To Delete - %s", JumpName[type]);
		SetMenuTitle(menu, text);
		if(SQL_GetRowCount(hndl) != 0)
		{
			while(SQL_FetchRow(hndl))
			{
				id = SQL_FetchInt(hndl, 0, result);
				SQL_FetchString(hndl, 1, name, sizeof(name), result);
				distance = SQL_FetchFloat(hndl, 2, result);
				Format(info, sizeof(info), "%d", id);
				Format(text, sizeof(text), "%s - %.2f Units", name, distance);
				AddMenuItem(menu, info, text);
			}
		}
		else
		{
			AddMenuItem(menu, info, "no record", ITEMDRAW_DISABLED);
		}
		SetMenuExitBackButton(menu, true);
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}
public AdmMenu_Handler(Handle:menu, MenuAction:action, client, select)
{
	if (action == MenuAction_Select)
	{
		decl String:info[10], String:query[512];
		GetMenuItem(menu, select, info, sizeof(info));
		Format(query, sizeof(query), "delete from 'ljstats' where id = %d", StringToInt(info));
		SQL_TQuery(maindb, empty_query, query, 0);
		RemoveMenuItem(menu, select);
		DisplayMenuAtItem(menu, client, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_Cancel)
	{
		if(select == MenuCancel_ExitBack)
		{
			AdmTopMenu(client);
		}
	}
}
bool:IsDBType(JumpType:type)
{
	if(IsValidType(type)||IsBlockJumpType(type))
	{
		return true;
	}
	return false;
}
bool:IsValidType(JumpType:type)
{
	if(type == JumpType_LongJump || type == JumpType_BhopJump || type == JumpType_Wj)
	{
		return true;
	}
	return false;
}

bool:IsBlockJumpType(JumpType:type)
{
	if(type == JumpType_BlockLongJump || type == JumpType_BlockBhopJump)
		return true;
	return false;
}