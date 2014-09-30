#include <sourcemod>
#include <cstrike>
#include <smlib>

public Plugin:myinfo = 
{
	name = "Give Glock",
	author = "Zipcore",
	description = " Give a player a glock when they write !glock into chat",
	version = "1.0",
	url = "zipcore#googlemail.com"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_glock", Command_Glock, "Give player a glock");
}

public Action:Command_Glock(client, args) 
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		RemovePlayerSecondary(client);
		Client_GiveWeapon(client, "weapon_glock", true);
	}
	return Plugin_Handled;
}

stock RemovePlayerSecondary(client)
{
	new iWeapon = -1;
	while((iWeapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY)) != -1)
	{
		if(iWeapon > 0)
		{
			RemovePlayerItem(client, iWeapon);
			AcceptEntityInput(iWeapon, "kill");
		}
	}
}