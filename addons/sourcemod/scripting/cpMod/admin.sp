//-----------------------//
// admin cp command hook //
//-----------------------//
public Action:Admin_CpPanel(client, args)
{
	PrintToChat(client, "%t", "CpPanelInAccess", YELLOW,LIGHTGREEN,YELLOW);
	return Plugin_Handled;
}

//--------------------------//
// admin purge players hook //
//--------------------------//
public Action:Admin_PurgePlayer(client, args){
	//if not correct arguments
	if(args != 1){
		ReplyToCommand(client, "[SM] Usage: sm_purgeplayer <days>");
		return Plugin_Handled;
	}
	
	//create the database query
	decl String:szDays[8];
	GetCmdArg(1, szDays, 8);
	db_purgePlayer(client, szDays);
	return Plugin_Handled;
}

//----------------------//
// admin drop maps hook //
//----------------------//
public Action:Admin_DropMap(client, args){
	db_dropMap(client);
	return Plugin_Handled;
}

//-------------------------//
// admin drop players hook //
//-------------------------//
public Action:Admin_DropPlayer(client, args){
	db_dropPlayer(client);
	return Plugin_Handled;
}

//-------------------------------------//
// admin reset player checkpoints hook //
//-------------------------------------//
public Action:Admin_ResetCheckpoints(client, args){
	//if not enough arguments
	if(args < 1){
		ReplyToCommand(client, "[SM] Usage: sm_resetplayercheckpoints <playername> [<mapname>]");
		return Plugin_Handled;
	}else if(args == 1){
		decl String:szPlayerName[MAX_NAME_LENGTH];
		GetCmdArg(1, szPlayerName, MAX_NAME_LENGTH);
		
		db_resetPlayerCheckpoints(client, szPlayerName, g_szMapName);
	}else if(args == 2){
		decl String:szPlayerName[MAX_NAME_LENGTH];
		decl String:szMapName[MAX_MAP_LENGTH];
		GetCmdArg(1, szPlayerName, MAX_NAME_LENGTH);
		GetCmdArg(2, szMapName, MAX_NAME_LENGTH);
		
		db_resetPlayerCheckpoints(client, szPlayerName, szMapName);
	}
	return Plugin_Handled;
}
