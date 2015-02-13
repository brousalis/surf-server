#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <basecomm>
#include <timer>
#include <timer-logging>
#include <timer-rankings>
#include <clientprefs>
#include <timer-config_loader.sp>
#include <autoexecconfig>	//https://github.com/Impact123/AutoExecConfig

#undef REQUIRE_PLUGIN
#include <timer-maptier>
#include <timer-physics>
#include <timer-worldrecord>

new String:g_sCurrentMap[PLATFORM_MAX_PATH];

public Plugin:myinfo =
{
	name        = "[Timer] Rankings - Points Lite",
	author      = "Zipcore",
	description = "[Timer] Lite version of points generation on map finish",
	version     = PL_VERSION,
	url         = "forums.alliedmods.net/showthread.php?p=2074699"
};

public OnPluginStart()
{
	LoadPhysics();
	LoadTimerSettings();
	
	LoadTranslations("common.phrases");
	LoadTranslations("timer-rankings.phrases");
	
	RegConsoleCmd("sm_points", Command_PointsInfo);
}

public OnMapStart()
{
	LoadPhysics();
	LoadTimerSettings();
	
	GetCurrentMap(g_sCurrentMap, sizeof(g_sCurrentMap));
}

public OnTimerRecord(client, track, style, Float:time, Float:lasttime, currentrank, newrank)
{
	if(IsFakeClient(client))
		return;
	
	new tier;
	if(track == TRACK_SHORT) 
		tier = 1;
	else tier = Timer_GetTier(track);
	
	if(Timer_IsStyleRanked(style))
	{
		new total = Timer_GetStyleTotalRank(style, track);
		new finishcount = Timer_GetFinishCount(style, track, currentrank);
		
		new points = GetRecordPoints(lasttime > time, track, style, tier, finishcount, total, currentrank, newrank);
		
		if(points > 0)
		{
			Timer_AddPoints(client, points);
			Timer_SavePoints(client);
			CPrintToChat(client, PLUGIN_PREFIX, "Phrase_Complete_Round_Points", points, g_sCurrentMap);
		}
	}
}

public Action:Command_PointsInfo(client, args)
{
	if(Timer_IsStyleRanked(Timer_GetStyle(client)))
		CPrintToChat(client, "%s You could earn between %d and %d points.", PLUGIN_PREFIX2, GetMinRecordPoints(client), GetMaxRecordPoints(client));

	return Plugin_Handled;
}

stock GetMaxRecordPoints(client)
{
	new track = Timer_GetTrack(client);
	new tier = Timer_GetTier(track);
	new style = Timer_GetStyle(client);
	new total = Timer_GetStyleTotalRank(style, track);
	new currentrank = Timer_GetStyleRank(client, track, style);	
	new finishcount = Timer_GetFinishCount(style, track, currentrank);
	
	return GetRecordPoints(true, track, style, tier, finishcount, total, currentrank, 1);
}

stock GetMinRecordPoints(client)
{
	new track = Timer_GetTrack(client);
	new tier = Timer_GetTier(track);
	new style = Timer_GetStyle(client);
	new total = Timer_GetStyleTotalRank(style, track);
	new currentrank = Timer_GetStyleRank(client, track, style);	
	new finishcount = Timer_GetFinishCount(style, track, currentrank);
	
	new badrank;
	
	if(currentrank == 0)
	{
		badrank = total;
		finishcount = 0;
	}
	else badrank = currentrank;
	
	return GetRecordPoints(false, track, style, tier, finishcount, total, currentrank, badrank);
}

stock GetRecordPoints(bool:timeimproved, track, style, tier, finishcount, total, currentrank, newrank)
{
	new Float:points = 0.0;
	new totalbonus = GetTotalBonus(total);
	new Float:style_scale = g_Physics[style][StylePointsMulti];
	new Float:tier_scale = 1.0;
	
	if(tier == 1)
		tier_scale = g_Settings[Tier1Scale];
	else if(tier == 2)
		tier_scale = g_Settings[Tier2Scale];
	else if(tier == 3)
		tier_scale = g_Settings[Tier3Scale];
	else if(tier == 4)
		tier_scale = g_Settings[Tier4Scale];
	else if(tier == 5)
		tier_scale = g_Settings[Tier5Scale];
	else if(tier == 6)
		tier_scale = g_Settings[Tier6Scale];
	else if(tier == 7)
		tier_scale = g_Settings[Tier7Scale];
	else if(tier == 8)
		tier_scale = g_Settings[Tier8Scale];
	else if(tier == 9)
		tier_scale = g_Settings[Tier9Scale];
	else if(tier == 10)
		tier_scale = g_Settings[Tier10Scale];

	/* Anyway */
	points += g_Settings[PointsAnyway]*tier_scale*style_scale;
	
	/* First Record */
	if(finishcount == 0)
	{
		points += g_Settings[PointsFirst]*tier_scale*style_scale;
	}
	
	/* First 5 */
	if(finishcount < 5)
	{
		points += g_Settings[PointsFirst5]*tier_scale*style_scale;
	}
	
	/* First 10 */
	if(finishcount < 10)
	{
		points += g_Settings[PointsFirst10]*tier_scale*style_scale;
	}
	
	/* First 25 */
	if(finishcount < 25)
	{
		points += g_Settings[PointsFirst25]*tier_scale*style_scale;
	}
	
	/* First 50 */
	if(finishcount < 50)
	{
		points += g_Settings[PointsFirst50]*tier_scale*style_scale;
	}
	
	/* First 100 */
	if(finishcount < 100)
	{
		points += g_Settings[PointsFirst100]*tier_scale*style_scale;
	}
	
	/* First 250 */
	if(finishcount < 250)
	{
		points += g_Settings[PointsFirst250]*tier_scale*style_scale;
	}
	
	/* Improved Time */
	if(timeimproved)
	{
		points += g_Settings[PointsImprovedTime]*tier_scale*style_scale;
	}
	
	/* Improved Rank */
	if(currentrank > newrank)
	{
		points += g_Settings[PointsImprovedRank]*tier_scale*style_scale;
	}
	
	/* Break World-Record Self */
	if(newrank == 1 && total > 10 && currentrank == newrank)
	{
		points += g_Settings[PointsNewWorldRecordSelf]*tier_scale*style_scale;
		points += totalbonus;
	}
	else if(currentrank > newrank)
	{
		/* Break World-Record */
		if(newrank == 1 && total > 10 && finishcount == 0)
		{
			points += g_Settings[PointsNewWorldRecord]*tier_scale*style_scale;
			points += totalbonus;
		} 
		
		/* Top 10 */
		if(newrank <= 10 && total > 25 && (currentrank > 10 || finishcount == 0))
		{
			points += g_Settings[PointsTop10Record]*tier_scale*style_scale;
			points += totalbonus;
		}
		
		/* Top 25 */
		if(newrank <= 25 && total > 50 && (currentrank > 25 || finishcount == 0))
		{
			points += g_Settings[PointsTop25Record]*tier_scale*style_scale;
			points += totalbonus;
		}
		
		/* Top 50 */
		if(newrank <= 50 && total > 100 && (currentrank > 50 || finishcount == 0))
		{
			points += g_Settings[PointsTop50Record]*tier_scale*style_scale;
			points += totalbonus;
		}
		
		/* Top 100 */
		if(newrank <= 100 && total > 200 && (currentrank > 100 || finishcount == 0))
		{
			points += g_Settings[PointsTop100Record]*tier_scale*style_scale;
			points += totalbonus;
		}
		
		/* Top 250 */
		if(newrank <= 250 && total > 500 && (currentrank > 250 || finishcount == 0))
		{
			points += g_Settings[PointsTop250Record]*tier_scale*style_scale;
			points += totalbonus;
		}
		
		/* Top 500 */
		if(newrank <= 500 && total > 750 && (currentrank > 500 || finishcount == 0))
		{
			points += g_Settings[PointsTop500Record]*tier_scale*style_scale;
			points += totalbonus;
		}
	}
	
	return RoundToFloor(points);
}

stock GetTotalBonus(total)
{
	if(total != 0)
	{
		if(total >= 1 && total <= 3)
		{
			return 3;
		}
		else if(total >= 4 && total <= 10)
		{
			return 5;
		}
		else if(total >= 11 && total <= 25)
		{
			return 10;
		}
		else if(total >= 26 && total <= 50)
		{
			return 20;
		}
		else if(total >= 51 && total <= 100)
		{
			return 30;
		}
		else if(total >= 101 && total <= 200)
		{
			return 40;
		}
		else if(total >= 201)
		{
			return 50;
		}
	}
	
	return 0;
}
