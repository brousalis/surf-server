#include <timer>
#include <timer-logging>

enum GameMod
{
	MOD_UNKNOWN,
	MOD_CSS,
	MOD_CSGO
}
	
enum TimerSettings
{
	//Timer
	bool:PauseEnable,
	bool:StartEnable,
	bool:RestartEnable,
	bool:TerminateRoundEnd,
	
	//Physics
	bool:MultimodeEnable,
	bool:BhopEnable,
	bool:JumpsEnable,
	bool:StrafesEnable,
	bool:NoclipEnable,
	bool:ForceStyle,
	bool:StyleMenuOnSpawn,
	bool:NoGravityUpdate,
	bool:Godmode,
	bool:PlayerTeleportEnable,
	bool:TeleportOnStyleChanged,
	bool:VegasEnable,
	VegasMinPlattfors,
	VegasMapMaxGames,
	Float:VegasAvoidChance,
	Float:VegasAvoidChanceAdd,
	Float:VegasCollectChance,
	Float:VegasCollectChanceAdd,
	
	//Multibhop
	bool:MultiBhopEnable,
	Float:MultiBhopJumpTime,
	Float:MultiBhopDelay,
	Float:MultiBhopCooldown,
	
	//Mapzones
	bool:NoblockEnable,
	bool:ZoneSprites,
	bool:ZoneSpotlights,
	bool:NPCConfirm,
	bool:LevelTeleportEnable,
	bool:TeleportOnSpawn,
	bool:TeleportOnRestart,
	bool:StuckEnable,
	Float:StuckPenaltyTime,
	bool:AllowMultipleStart,
	bool:AllowMultipleEnd,
	bool:AllowMultipleShortEnd,
	bool:AllowMultipleBonusStart,
	bool:AllowMultipleBonusEnd,
	String:NPC_Path[32],
	String:NPC_Double_Path[32],
	Float:ZoneBeamHeight,
	Float:ZoneBeamThickness,
	Float:ZoneResize,
	Float:ZoneTeleportZ,
	bool:UseZoneTeleportZ,
	bool:DisableButtonSounds,
	bool:DisableDoorSounds,
	bool:ForceMapEndEnable,
	
	//HUD
	HUDUseMVPStars,
	bool:HUDUseFragPointsRank,
	bool:HUDUseDeathRank,
	bool:HUDUseClanTag,
	bool:HUDUseClanTagStyle,
	bool:HUDUseClanTagTime,
	HUDSpeedUnit,
	
	bool:HUDMasterOnlyEnable,
	bool:HUDMasterEnable,
	bool:HUDCenterEnable,
	bool:HUDSideEnable,
	bool:HUDTimeleftEnable,
	bool:HUDJumpsEnable,
	bool:HUDJumpAccEnable,
	bool:HUDSpeedEnable,
	bool:HUDSpeedMaxEnable,
	bool:HUDStrafesEnable,
	bool:HUDMapEnable,
	bool:HUDStyleEnable,
	bool:HUDWREnable,
	bool:HUDWRHolderEnable,
	bool:HUDPBEnable,
	bool:HUDTTWREnable,
	bool:HUDKeysEnable,
	bool:HUDSpeclistEnable,
	bool:HUDSteamIDEnable,
	bool:HUDLevelEnable,
	bool:HUDRankEnable,
	bool:HUDPointsEnable,
	
	//Challenge
	bool:ChallengeEnable,
	Float:ChallengeIgnoreCooldown,
	Float:ChallengeAbortTime,
	bool:ChallengeSaveRecords,
	ChallengeBet1,
	ChallengeBet2,
	ChallengeBet3,
	ChallengeBet4,
	ChallengeBet5,
	
	//Coop
	bool:CoopEnable,
	bool:CoopOnly,
	
	//Race
	bool:RaceEnable,
	
	//Points
	bool:PointsEnable,
	PointsAnyway,
	PointsFirst,
	PointsFirst5,
	PointsFirst10,
	PointsFirst25,
	PointsFirst50,
	PointsFirst100,
	PointsFirst250,
	PointsImprovedTime,
	PointsImprovedRank,
	PointsNewWorldRecord,
	PointsNewWorldRecordSelf,
	PointsTop10Record,
	PointsTop25Record,
	PointsTop50Record,
	PointsTop100Record,
	PointsTop250Record,
	PointsTop500Record,
	PointsVegas,
	PointsVegasAdd,
	PointsTotalBonus_1_3,
	PointsTotalBonus_4_10,
	PointsTotalBonus_11_25,
	PointsTotalBonus_26_50,
	PointsTotalBonus_51_100,
	PointsTotalBonus_101_200,
	PointsTotalBonus_201_300,
	PointsTotalBonus_301_400,
	PointsTotalBonus_401_500,
	PointsTotalBonus_501_600,
	PointsTotalBonus_601_700,
	PointsTotalBonus_701_800,
	PointsTotalBonus_801_900,
	PointsTotalBonus_901_1000,
	PointsTotalBonus_1001_1250,
	PointsTotalBonus_1251_1500,
	PointsTotalBonus_1551_1750,
	PointsTotalBonus_1751_2000,
	PointsTotalBonus_2001,
	
	//Tier Scale
	Float:Tier1Scale,
	Float:Tier2Scale,
	Float:Tier3Scale,
	Float:Tier4Scale,
	Float:Tier5Scale,
	Float:Tier6Scale,
	Float:Tier7Scale,
	Float:Tier8Scale,
	Float:Tier9Scale,
	Float:Tier10Scale,
	
	//World Record
	bool:ShortWrEnable,
	bool:BonusWrEnable,
	
	//Weapons
	bool:AllowWeapons,
	bool:RemoveWeapons,
	bool:KeepMapWeapons,
	bool:BuyzoneEverywhere,
	bool:GiveScoutOnSpawn,
	bool:AllowKnifeDrop
}

enum Styles
{
	//General
	bool:StyleEnable,
	MCategory:StyleCategory,
	StyleOrder,
	bool:StyleIsDefault,
	String:StyleName[32],
	String:StyleTagName[32],
	String:StyleTagShortName[32],
	String:StyleQuickCommand[32],
	String:StyleQuickWrCommand[32],
	String:StyleQuickBonusWrCommand[32],
	String:StyleQuickShortWrCommand[32],
	String:StyleDesc[128],
	
	//HUD
	bool:StyleHUDEnable,
	
	//Buttons
	bool:StylePreventMoveleft,
	bool:StylePreventMoveright,
	bool:StylePreventPlusleft,
	bool:StylePreventPlusright,
	bool:StylePreventMoveforward,
	bool:StylePreventMoveback,
	StyleForceHalfSideways,
	
	//Movement
	StyleBlockMovementDirection,
	Float:StyleBlockPreSpeeding,
	
	//Punish
	StylePunishType,
	Float:StylePunishMovementControlCooldown,
	
	//Physics
	StyleMultiBhop,
	Float:StyleStamina,
	bool:StyleAuto,
	Float:StyleBoost,
	Float:StyleBoostForward,
	Float:StyleBoostForwardMax,
	Float:StyleGravity,
	Float:StyleTimeScale,
	StyleFOV,
	Float:StylePointsMulti,
	Float:StyleHoverScale,
	Float:StyleMaxSpeed,
	bool:StyleAntiBhop,
	
	//Damage
	bool:StylePvP,
	bool:StyleAllowWorldDamage,
	StyleSpawnHealth,
	
	//other
	bool:StyleReplay,
	bool:StyleReplayBonus,
	bool:StyleThirdPerson,
	bool:StyleLJStats,
	bool:StyleCustom,
	String:StyleOnFinishExec[128],
	StyleFPSMax,
	StyleFPSMin,
	StyleFPSRedirectStyle,
	StyleAutoStrafe,
	StyleQuakeBhop,
	StyleStrafeBoost
}

new g_Physics[MAX_STYLES][Styles];
new g_Settings[TimerSettings];

new g_StyleCount = 0;
new g_StyleCountEnabled = 0;
new g_StyleCountRanked = 0;
new g_StyleCountRankedEnabled = 0;
new g_StyleCountFun = 0;
new g_StyleCountFunEnabled = 0;
new g_StyleCountPractise = 0;
new g_StyleCountPractiseEnabled = 0;
new g_StyleDefault = -1;

stock LoadTimerSettings()
{
	decl String:sPath[PLATFORM_MAX_PATH];
	decl String:currentMap[64];
	GetCurrentMap(currentMap, 64);
	
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/timer/settings_%s.cfg", currentMap);

	if(!FileExists(sPath))
		BuildPath(Path_SM, sPath, sizeof(sPath), "configs/timer/settings.cfg");
	
	new Handle:hKv = CreateKeyValues("Settings");
	if (!FileToKeyValues(hKv, sPath))
	{
		CloseHandle(hKv);
		return;
	}

	if (!KvGotoFirstSubKey(hKv))
	{
		CloseHandle(hKv);
		return;
	}
	
	do 
	{
		decl String:sSectionName[32];
		KvGetSectionName(hKv, sSectionName, sizeof(sSectionName));
		
		if(StrEqual(sSectionName, "Timer"))
		{
			g_Settings[PauseEnable] = bool:KvGetNum(hKv, "pause_enable", 1);
			g_Settings[StartEnable] = bool:KvGetNum(hKv, "start_enable", 1);
			g_Settings[RestartEnable] = bool:KvGetNum(hKv, "restart_enable", 1);
			g_Settings[TerminateRoundEnd] = bool:KvGetNum(hKv, "terminate_round", 1);
		}
		else if(StrEqual(sSectionName, "Physics"))
		{
			g_Settings[MultimodeEnable] = bool:KvGetNum(hKv, "multimode_enable", 1);
			g_Settings[BhopEnable] = bool:KvGetNum(hKv, "bhop_enable", 1);
			g_Settings[JumpsEnable] = bool:KvGetNum(hKv, "jumps_enable", 1);
			g_Settings[StrafesEnable] = bool:KvGetNum(hKv, "strafes_enable", 1);
			g_Settings[NoclipEnable] = bool:KvGetNum(hKv, "noclip_enable", 1);
			g_Settings[ForceStyle] = bool:KvGetNum(hKv, "force_style", 1);
			g_Settings[StyleMenuOnSpawn] = bool:KvGetNum(hKv, "style_menu_on_spawn", 1);
			g_Settings[NoGravityUpdate] = bool:KvGetNum(hKv, "style_no_gravity_update", 0);
			g_Settings[Godmode] = bool:KvGetNum(hKv, "godmode", 1);
			g_Settings[PlayerTeleportEnable] = bool:KvGetNum(hKv, "teleport_player2player", 1);
			g_Settings[TeleportOnStyleChanged] = bool:KvGetNum(hKv, "teleport_on_style_changed", 1);
			g_Settings[VegasEnable] = bool:KvGetNum(hKv, "vegas_enable", 0);
			g_Settings[VegasMinPlattfors] = KvGetNum(hKv, "vegas_min_platforms", 100);
			g_Settings[VegasMapMaxGames] = KvGetNum(hKv, "vegas_map_max_games", 5);
			g_Settings[VegasAvoidChance] = KvGetFloat(hKv, "vegas_avoid_chance", 5.0);
			g_Settings[VegasAvoidChanceAdd] = KvGetFloat(hKv, "vegas_avoid_chance_add", 2.0);
			g_Settings[VegasCollectChance] = KvGetFloat(hKv, "vegas_collect_chance", 20.0);
			g_Settings[VegasCollectChanceAdd] = KvGetFloat(hKv, "vegas_collect_chance_add", 3.0);
		}
		else if(StrEqual(sSectionName, "Multibhop"))
		{
			g_Settings[MultiBhopEnable] = bool:KvGetNum(hKv, "multibhop_enable", 1);
			g_Settings[MultiBhopJumpTime] = KvGetFloat(hKv, "multibhop_jump_time", 0.5);
			g_Settings[MultiBhopDelay] = KvGetFloat(hKv, "multibhop_delay", 0.15);
			g_Settings[MultiBhopCooldown] = KvGetFloat(hKv, "multibhop_cooldown", 1.0);
		}
		else if(StrEqual(sSectionName, "Mapzone"))
		{
			g_Settings[ZoneSprites] = bool:KvGetNum(hKv, "zone_sprites_enable", 1);
			g_Settings[ZoneSpotlights] = bool:KvGetNum(hKv, "zone_spotlights_enable", 1);
			g_Settings[NoblockEnable] = bool:KvGetNum(hKv, "noblock_enable", 1);
			g_Settings[NPCConfirm] = bool:KvGetNum(hKv, "npc_confirm", 1);
			g_Settings[TeleportOnSpawn] = bool:KvGetNum(hKv, "teleport_onspawn", 0);
			g_Settings[TeleportOnRestart] = bool:KvGetNum(hKv, "teleport_onrestart", 0);
			g_Settings[LevelTeleportEnable] = bool:KvGetNum(hKv, "level_teleport_enable", 1);
			g_Settings[StuckEnable] = bool:KvGetNum(hKv, "stuck_enable", 1);
			g_Settings[StuckPenaltyTime] = KvGetFloat(hKv, "stuck_penalty_time", 10.0);
			g_Settings[AllowMultipleStart] = bool:KvGetNum(hKv, "allow_multiple_start", 0);
			g_Settings[AllowMultipleEnd] = bool:KvGetNum(hKv, "allow_multiple_end", 0);
			g_Settings[AllowMultipleShortEnd] = bool:KvGetNum(hKv, "allow_multiple_shortend", 0);
			g_Settings[AllowMultipleBonusStart] = bool:KvGetNum(hKv, "allow_multiple_bonusstart", 0);
			g_Settings[AllowMultipleBonusEnd] = bool:KvGetNum(hKv, "allow_multiple_bonusend", 0);
			g_Settings[ZoneResize] = KvGetFloat(hKv, "trigger_resize", 16.0);
			g_Settings[ZoneTeleportZ] = KvGetFloat(hKv, "teleport_z", 10.0);
			g_Settings[UseZoneTeleportZ] = bool:KvGetNum(hKv, "use_teleport_z", 1);
			g_Settings[ZoneBeamHeight] = KvGetFloat(hKv, "beam_height", 0.0);
			g_Settings[ZoneBeamThickness] = KvGetFloat(hKv, "beam_thickness", 1.0);
			KvGetString(hKv, "npc_model", g_Settings[NPC_Path], 32);
			KvGetString(hKv, "npc_double_model", g_Settings[NPC_Double_Path], 32);
			g_Settings[DisableButtonSounds] = bool:KvGetNum(hKv, "disable_button_sounds", 1);
			g_Settings[DisableDoorSounds] = bool:KvGetNum(hKv, "disable_door_sounds", 1);
			g_Settings[ForceMapEndEnable] = bool:KvGetNum(hKv, "force_map_end", 1);
		}
		else if(StrEqual(sSectionName, "Hud"))
		{
			g_Settings[HUDUseDeathRank] = bool:KvGetNum(hKv, "hud_use_death_rank", 1);
			g_Settings[HUDUseClanTag] = bool:KvGetNum(hKv, "hud_use_clan_tag", 1);
			g_Settings[HUDUseClanTagStyle] = bool:KvGetNum(hKv, "hud_use_clan_tag_style", 1);
			g_Settings[HUDUseClanTagTime] = bool:KvGetNum(hKv, "hud_use_clan_tag_time", 1);
			g_Settings[HUDUseFragPointsRank] = bool:KvGetNum(hKv, "hud_use_frag_points_rank", 1);
			g_Settings[HUDUseMVPStars] = KvGetNum(hKv, "hud_use_mvp_stars", 100);
			g_Settings[HUDSpeedUnit] = KvGetNum(hKv, "hud_speed_unit", 0);
			g_Settings[HUDMasterEnable] = bool:KvGetNum(hKv, "hud_master_enable", 1);
			g_Settings[HUDMasterOnlyEnable] = bool:KvGetNum(hKv, "hud_master_only_enable", 0);
			g_Settings[HUDCenterEnable] = bool:KvGetNum(hKv, "hud_center_enable", 1);
			g_Settings[HUDSideEnable] = bool:KvGetNum(hKv, "hud_side_enable", 1);
			g_Settings[HUDTimeleftEnable] = bool:KvGetNum(hKv, "hud_show_timeleft", 1);
			g_Settings[HUDJumpsEnable] = bool:KvGetNum(hKv, "hud_show_jumps", 1);
			g_Settings[HUDJumpAccEnable] = bool:KvGetNum(hKv, "hud_show_jumpacc", 1);
			g_Settings[HUDMapEnable] = bool:KvGetNum(hKv, "hud_show_mapname", 1);
			g_Settings[HUDStyleEnable] = bool:KvGetNum(hKv, "hud_show_style", 1);
			g_Settings[HUDWREnable] = bool:KvGetNum(hKv, "hud_show_wr", 1);
			g_Settings[HUDWRHolderEnable] = bool:KvGetNum(hKv, "hud_show_wr_holder", 1);
			g_Settings[HUDPBEnable] = bool:KvGetNum(hKv, "hud_show_pb", 1);
			g_Settings[HUDTTWREnable] = bool:KvGetNum(hKv, "hud_show_wwtr", 1);
			g_Settings[HUDKeysEnable] = bool:KvGetNum(hKv, "hud_show_keys", 1);
			g_Settings[HUDSpeclistEnable] = bool:KvGetNum(hKv, "hud_show_speclist", 1);
			g_Settings[HUDSteamIDEnable] = bool:KvGetNum(hKv, "hud_show_steamid", 1);
			g_Settings[HUDLevelEnable] = bool:KvGetNum(hKv, "hud_show_level", 1);
			g_Settings[HUDRankEnable] = bool:KvGetNum(hKv, "hud_show_rank", 1);
			g_Settings[HUDPointsEnable] = bool:KvGetNum(hKv, "hud_show_points", 1);
			g_Settings[HUDSpeedEnable] = bool:KvGetNum(hKv, "hud_show_speed", 1);
			g_Settings[HUDSpeedMaxEnable] = bool:KvGetNum(hKv, "hud_show_speedmax", 1);
			g_Settings[HUDStrafesEnable] = bool:KvGetNum(hKv, "hud_show_strafes", 1);
		}
		else if(StrEqual(sSectionName, "Teams"))
		{
			g_Settings[ChallengeEnable] = bool:KvGetNum(hKv, "challenge_enable", 0);
			g_Settings[ChallengeIgnoreCooldown] = KvGetFloat(hKv, "challenge_ignore_cooldown", 60.0);
			g_Settings[ChallengeAbortTime] = KvGetFloat(hKv, "challenge_abort_time", 10.0);
			g_Settings[ChallengeSaveRecords] = bool:KvGetNum(hKv, "challenge_save_records", 1);
			g_Settings[ChallengeBet1] = KvGetNum(hKv, "challenge_bet_option_1", 25);
			g_Settings[ChallengeBet2] = KvGetNum(hKv, "challenge_bet_option_2", 50);
			g_Settings[ChallengeBet3] = KvGetNum(hKv, "challenge_bet_option_3", 75);
			g_Settings[ChallengeBet4] = KvGetNum(hKv, "challenge_bet_option_4", 100);
			g_Settings[ChallengeBet5] = KvGetNum(hKv, "challenge_bet_option_5", 150);
			
			g_Settings[CoopEnable] = bool:KvGetNum(hKv, "coop_enable", 0);
			g_Settings[CoopOnly] = bool:KvGetNum(hKv, "coop_only", 0);
			
			g_Settings[RaceEnable] = bool:KvGetNum(hKv, "race_enable", 0);
		}
		else if(StrEqual(sSectionName, "Points"))
		{
			g_Settings[PointsEnable] = bool:KvGetNum(hKv, "points_enable", 1);
			g_Settings[PointsAnyway] = KvGetNum(hKv, "points_anyway", 1);
			g_Settings[PointsFirst] = KvGetNum(hKv, "points_first", 20);
			g_Settings[PointsFirst5] = KvGetNum(hKv, "points_first5", 3);
			g_Settings[PointsFirst10] = KvGetNum(hKv, "points_first10", 2);
			g_Settings[PointsFirst25] = KvGetNum(hKv, "points_first25", 1);
			g_Settings[PointsFirst50] = KvGetNum(hKv, "points_first50", 1);
			g_Settings[PointsFirst100] = KvGetNum(hKv, "points_first100", 1);
			g_Settings[PointsFirst250] = KvGetNum(hKv, "points_first250", 1);
			g_Settings[PointsImprovedTime] = KvGetNum(hKv, "points_improved_time", 2);
			g_Settings[PointsImprovedRank] = KvGetNum(hKv, "points_improved_rank", 3);
			g_Settings[PointsNewWorldRecord] = KvGetNum(hKv, "points_new_wr", 10);
			g_Settings[PointsNewWorldRecordSelf] = KvGetNum(hKv, "points_new_wr_self", 2);
			g_Settings[PointsTop10Record] = KvGetNum(hKv, "points_top10", 6);
			g_Settings[PointsTop25Record] = KvGetNum(hKv, "points_top25", 5);
			g_Settings[PointsTop50Record] = KvGetNum(hKv, "points_top50", 4);
			g_Settings[PointsTop100Record] = KvGetNum(hKv, "points_top100", 3);
			g_Settings[PointsTop250Record] = KvGetNum(hKv, "points_top250", 2);
			g_Settings[PointsTop500Record] = KvGetNum(hKv, "points_top500", 1);
			g_Settings[PointsVegas] = KvGetNum(hKv, "points_vegas", 10);
			g_Settings[PointsVegasAdd] = KvGetNum(hKv, "points_vegas_add", 2);
			g_Settings[PointsTotalBonus_1_3] = KvGetNum(hKv, "points_total_bonus_1_3", 3);
			g_Settings[PointsTotalBonus_4_10] = KvGetNum(hKv, "points_total_bonus_4_10", 5);
			g_Settings[PointsTotalBonus_11_25] = KvGetNum(hKv, "points_total_bonus_11_25", 10);
			g_Settings[PointsTotalBonus_26_50] = KvGetNum(hKv, "points_total_bonus_26_50", 20);
			g_Settings[PointsTotalBonus_51_100] = KvGetNum(hKv, "points_total_bonus_51_100", 30);
			g_Settings[PointsTotalBonus_101_200] = KvGetNum(hKv, "points_total_bonus_101_200", 40);
			g_Settings[PointsTotalBonus_201_300] = KvGetNum(hKv, "points_total_bonus_201_300", 50);
			g_Settings[PointsTotalBonus_301_400] = KvGetNum(hKv, "points_total_bonus_301_400", 60);
			g_Settings[PointsTotalBonus_401_500] = KvGetNum(hKv, "points_total_bonus_401_500", 70);
			g_Settings[PointsTotalBonus_501_600] = KvGetNum(hKv, "points_total_bonus_501_600", 80);
			g_Settings[PointsTotalBonus_601_700] = KvGetNum(hKv, "points_total_bonus_601_700", 90);
			g_Settings[PointsTotalBonus_801_900] = KvGetNum(hKv, "points_total_bonus_701_900", 100);
			g_Settings[PointsTotalBonus_901_1000] = KvGetNum(hKv, "points_total_bonus_901_1000", 110);
			g_Settings[PointsTotalBonus_1001_1250] = KvGetNum(hKv, "points_total_bonus_1001_1250", 120);
			g_Settings[PointsTotalBonus_1251_1500] = KvGetNum(hKv, "points_total_bonus_1251_1500", 130);
			g_Settings[PointsTotalBonus_1551_1750] = KvGetNum(hKv, "points_total_bonus_1551_1750", 140);
			g_Settings[PointsTotalBonus_1751_2000] = KvGetNum(hKv, "points_total_bonus_1751_2000", 150);
			g_Settings[PointsTotalBonus_2001] = KvGetNum(hKv, "points_total_bonus_2001", 200);
			
		}
		else if(StrEqual(sSectionName, "Tierscale"))
		{
			g_Settings[Tier1Scale] = KvGetFloat(hKv, "points_tier1", 1.0);
			g_Settings[Tier2Scale] = KvGetFloat(hKv, "points_tier2", 2.0);
			g_Settings[Tier3Scale] = KvGetFloat(hKv, "points_tier3", 3.0);
			g_Settings[Tier4Scale] = KvGetFloat(hKv, "points_tier4", 4.0);
			g_Settings[Tier5Scale] = KvGetFloat(hKv, "points_tier5", 5.0);
			g_Settings[Tier6Scale] = KvGetFloat(hKv, "points_tier6", 6.0);
			g_Settings[Tier7Scale] = KvGetFloat(hKv, "points_tier7", 7.0);
			g_Settings[Tier8Scale] = KvGetFloat(hKv, "points_tier8", 8.0);
			g_Settings[Tier9Scale] = KvGetFloat(hKv, "points_tier9", 9.0);
			g_Settings[Tier10Scale] = KvGetFloat(hKv, "points_tier10", 10.0);
		}
		else if(StrEqual(sSectionName, "Worldrecord"))
		{
			g_Settings[ShortWrEnable] = bool:KvGetNum(hKv, "worldrecord_shortwr_enable", 1);
			g_Settings[BonusWrEnable] = bool:KvGetNum(hKv, "worldrecord_bonuswr_enable", 1);
		}
		else if(StrEqual(sSectionName, "Weapons"))
		{
			g_Settings[AllowWeapons] = bool:KvGetNum(hKv, "weapons_allow", 0);
			g_Settings[RemoveWeapons] = bool:KvGetNum(hKv, "weapons_remove", 1);
			g_Settings[KeepMapWeapons] = bool:KvGetNum(hKv, "weapons_keep_map", 1);
			g_Settings[BuyzoneEverywhere] = bool:KvGetNum(hKv, "weapons_buyzone", 0);
			g_Settings[GiveScoutOnSpawn] = bool:KvGetNum(hKv, "weapons_give_scout", 0);
			g_Settings[AllowKnifeDrop] = bool:KvGetNum(hKv, "weapons_knifedrop_enable", 0);
		}
	} while (KvGotoNextKey(hKv));
		
	CloseHandle(hKv);
}

stock LoadPhysics()
{
	decl String:sPath[PLATFORM_MAX_PATH];
	decl String:currentMap[64];
	GetCurrentMap(currentMap, 64);
	
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/timer/physics_%s.cfg", currentMap);

	if(!FileExists(sPath))
		BuildPath(Path_SM, sPath, sizeof(sPath), "configs/timer/physics.cfg");

	new Handle:hKv = CreateKeyValues("Physics");
	if (!FileToKeyValues(hKv, sPath))
	{
		CloseHandle(hKv);
		return;
	}
	
	g_StyleCount = 0;
	g_StyleCountEnabled = 0;
	g_StyleCountRanked = 0;
	g_StyleCountRankedEnabled = 0;
	g_StyleDefault = -1;
	
	new StyleID = -1;

	if (!KvGotoFirstSubKey(hKv))
	{
		CloseHandle(hKv);
		return;
	}
	
	do 
	{
		decl String:sSectionName[32];
		KvGetSectionName(hKv, sSectionName, sizeof(sSectionName));

		StyleID = StringToInt(sSectionName);
		
		if(MAX_STYLES-1 > StyleID >= 0)
		{
			KvGetString(hKv, "name", g_Physics[g_StyleCount][StyleName], 32);
			
			g_Physics[g_StyleCount][StyleEnable] = bool:KvGetNum(hKv, "enable", 0);
			g_Physics[g_StyleCount][StyleOrder] = KvGetNum(hKv, "order", 0);
			
			g_Physics[g_StyleCount][StyleHUDEnable] = bool:KvGetNum(hKv, "hud_enable", 0);
			g_Physics[g_StyleCount][StyleIsDefault] = bool:KvGetNum(hKv, "default", 0);
			g_Physics[g_StyleCount][StyleCategory] = MCategory:KvGetNum(hKv, "category", 0);
			
			g_Physics[g_StyleCount][StyleStamina] = KvGetFloat(hKv, "stamina", -1.0);
			g_Physics[g_StyleCount][StyleTimeScale] = KvGetFloat(hKv, "timescale", 1.0);
			
			g_Physics[g_StyleCount][StyleBoost] = KvGetFloat(hKv, "boost", 0.0);
			g_Physics[g_StyleCount][StyleBoostForward] = KvGetFloat(hKv, "boost_forward", 1.0);
			g_Physics[g_StyleCount][StyleBoostForwardMax] = KvGetFloat(hKv, "boost_forward_max", 500.0);
			g_Physics[g_StyleCount][StyleGravity] = KvGetFloat(hKv, "gravity", 1.0);
			g_Physics[g_StyleCount][StyleAuto] = bool:KvGetNum(hKv, "auto", 0);
			g_Physics[g_StyleCount][StyleLJStats] = bool:KvGetNum(hKv, "ljstats", 0);
			g_Physics[g_StyleCount][StyleMultiBhop] = KvGetNum(hKv, "multimode", 0);
			g_Physics[g_StyleCount][StyleFOV] = KvGetNum(hKv, "fov", 90);
			g_Physics[g_StyleCount][StyleBlockMovementDirection] = KvGetNum(hKv, "block_direction", 0);
			g_Physics[g_StyleCount][StylePreventMoveleft] = bool:KvGetNum(hKv, "prevent_moveleft", 0);
			g_Physics[g_StyleCount][StylePreventMoveright] = bool:KvGetNum(hKv, "prevent_moveright", 0);
			g_Physics[g_StyleCount][StylePreventPlusleft] = bool:KvGetNum(hKv, "prevent_plusleft", 0);
			g_Physics[g_StyleCount][StylePreventPlusright] = bool:KvGetNum(hKv, "prevent_plusright", 0);
			g_Physics[g_StyleCount][StylePreventMoveback] = bool:KvGetNum(hKv, "prevent_back", 0);
			g_Physics[g_StyleCount][StylePreventMoveforward] = bool:KvGetNum(hKv, "prevent_forward", 0);
			g_Physics[g_StyleCount][StyleForceHalfSideways] = KvGetNum(hKv, "hsw", 0);
			g_Physics[g_StyleCount][StylePunishType] = KvGetNum(hKv, "punish_type", 1);
			g_Physics[g_StyleCount][StylePunishMovementControlCooldown] = KvGetFloat(hKv, "punish_movement_cooldown", 1.0);
			
			if(g_Physics[g_StyleCount][StyleForceHalfSideways] > 0)
			{
				g_Physics[g_StyleCount][StylePreventMoveleft] = false;
				g_Physics[g_StyleCount][StylePreventMoveright] = false;
				g_Physics[g_StyleCount][StylePreventMoveback] = false;
				g_Physics[g_StyleCount][StylePreventMoveforward] = false;
				
				if(g_Physics[g_StyleCount][StyleForceHalfSideways] == 2 && g_Physics[g_StyleCount][StylePunishType] == 1)
					g_Physics[g_StyleCount][StylePunishMovementControlCooldown] = 0.0;
				
				if(g_Physics[g_StyleCount][StyleForceHalfSideways] == 1 && g_Physics[g_StyleCount][StylePunishType] == 1)
					g_Physics[g_StyleCount][StyleForceHalfSideways] = 2;
			}
			
			g_Physics[g_StyleCount][StyleReplay] = bool:KvGetNum(hKv, "replay", 0);
			g_Physics[g_StyleCount][StyleReplayBonus] = bool:KvGetNum(hKv, "replay_bonus", 0);
			g_Physics[g_StyleCount][StyleThirdPerson] = bool:KvGetNum(hKv, "thirdperson", 0);
			g_Physics[g_StyleCount][StyleCustom] = bool:KvGetNum(hKv, "custom", 0);
			g_Physics[g_StyleCount][StyleFPSMax] = KvGetNum(hKv, "fps_max", 0);
			g_Physics[g_StyleCount][StyleFPSMin] = KvGetNum(hKv, "fps_min", 0);
			g_Physics[g_StyleCount][StyleFPSRedirectStyle] = KvGetNum(hKv, "fps_redirect_style", -1);
			g_Physics[g_StyleCount][StyleAllowWorldDamage] = bool:KvGetNum(hKv, "allow_world_damage", 0);
			g_Physics[g_StyleCount][StyleSpawnHealth] = KvGetNum(hKv, "spawn_health", 100);
			g_Physics[g_StyleCount][StylePvP] = bool:KvGetNum(hKv, "pvp", 0);
			g_Physics[g_StyleCount][StyleBlockPreSpeeding] = KvGetFloat(hKv, "prespeed", 0.0);
			g_Physics[g_StyleCount][StylePointsMulti] = KvGetFloat(hKv, "points_multi", 1.0);
			g_Physics[g_StyleCount][StyleHoverScale] = KvGetFloat(hKv, "hover_scale", 0.0);
			g_Physics[g_StyleCount][StyleMaxSpeed] = KvGetFloat(hKv, "max_speed", 0.0);
			g_Physics[g_StyleCount][StyleAutoStrafe] = KvGetNum(hKv, "auto_strafe", 0);
			g_Physics[g_StyleCount][StyleQuakeBhop] = KvGetNum(hKv, "quake_bhop", 0);
			g_Physics[g_StyleCount][StyleStrafeBoost] = KvGetNum(hKv, "strafe_boost", 0);
			g_Physics[g_StyleCount][StyleAntiBhop] = bool:KvGetNum(hKv, "anti_bhop", 0);
			
			KvGetString(hKv, "tag_name", g_Physics[g_StyleCount][StyleTagName], 32);
			KvGetString(hKv, "tag_shortname", g_Physics[g_StyleCount][StyleTagShortName], 32);
			KvGetString(hKv, "chat_command", g_Physics[g_StyleCount][StyleQuickCommand], 32);
			KvGetString(hKv, "chat_wr_command", g_Physics[g_StyleCount][StyleQuickWrCommand], 32);
			KvGetString(hKv, "chat_bwr_command", g_Physics[g_StyleCount][StyleQuickBonusWrCommand], 32);
			KvGetString(hKv, "chat_swr_command", g_Physics[g_StyleCount][StyleQuickShortWrCommand], 32);
			KvGetString(hKv, "exec_onfinish", g_Physics[g_StyleCount][StyleOnFinishExec], 128);
			KvGetString(hKv, "desc", g_Physics[g_StyleCount][StyleDesc], 128);
			
			if (g_Physics[g_StyleCount][StyleIsDefault] && g_StyleDefault != g_StyleCount)
			{
				if(g_StyleDefault != -1) 
					Timer_LogError("PhysicsCFG: More than one default style detected! [StyleID: %d]", g_StyleCount);
				
				g_StyleDefault = g_StyleCount;
			}
			
			if(g_Physics[g_StyleCount][StyleEnable]) g_StyleCountEnabled++;
			
			if(g_Physics[g_StyleCount][StyleCategory] == MCategory_Ranked)
			{
				g_StyleCountRanked++;
				if(g_Physics[g_StyleCount][StyleEnable]) g_StyleCountRankedEnabled++;
			}
			
			if(g_Physics[g_StyleCount][StyleCategory] == MCategory_Fun)
			{
				g_StyleCountFun++;
				if(g_Physics[g_StyleCount][StyleEnable]) g_StyleCountFunEnabled++;
			}
			
			if(g_Physics[g_StyleCount][StyleCategory] == MCategory_Practise)
			{
				g_StyleCountPractise++;
				if(g_Physics[g_StyleCount][StyleEnable]) g_StyleCountPractiseEnabled++;
			}
		}
		else Timer_LogError("PhysicsCFG: Invalid style id: %d", StyleID);
		
		g_StyleCount++;
	} while (KvGotoNextKey(hKv));
	
	CloseHandle(hKv);	
}

stock GameMod:GetGameMod()
{
	new String: game_description[64];
	GetGameDescription(game_description, 64, true);
	
	if (StrContains(game_description, "Counter-Strike: Global Offensive", false) != -1) 
	{
		return MOD_CSGO;
	}
	else if (StrContains(game_description, "Counter-Strike", false) != -1)
	{
		return MOD_CSS;
	}
	
	return MOD_UNKNOWN;
}