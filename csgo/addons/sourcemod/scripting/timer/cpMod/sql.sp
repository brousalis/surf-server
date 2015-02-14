new String:sql_createMap[] = "CREATE TABLE IF NOT EXISTS map (mapname VARCHAR(32) PRIMARY KEY, start0 VARCHAR(38) NOT NULL DEFAULT '0:0:0', start1 VARCHAR(38) NOT NULL DEFAULT '0:0:0', end0 VARCHAR(38) NOT NULL DEFAULT '0:0:0', end1 VARCHAR(38) NOT NULL DEFAULT '0:0:0');";
new String:sql_createPlayer[] = "CREATE TABLE IF NOT EXISTS player (steamid VARCHAR(32), mapname VARCHAR(32), name VARCHAR(32), cords VARCHAR(38) NOT NULL DEFAULT '0:0:0', angle VARCHAR(38) NOT NULL DEFAULT '0:0:0', jumps INT(12) NOT NULL DEFAULT '-1', runtime INT(12) NOT NULL DEFAULT '-1', date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, PRIMARY KEY(steamid,mapname));";
new String:sql_createMeta[] = "CREATE TABLE meta (version VARCHAR(8) NOT NULL);";
new String:sql_initMeta[] = "INSERT INTO meta VALUES('2.0.8')";

new String:sql_insertMap[] = "INSERT INTO map (mapname) VALUES('%s');";
new String:sql_insertPlayer[] = "INSERT INTO player (steamid, mapname, name) VALUES('%s', '%s', '%s');";

new String:sql_updatePlayerCheckpoint[] = "UPDATE player SET name = '%s', cords = '%s', angle = '%s', date = CURRENT_TIMESTAMP WHERE steamid = '%s' AND mapname = '%s';";

new String:sql_selectCheckpoint[] = "SELECT cords, angle FROM player WHERE steamid = '%s' AND mapname = '%s';";

new String:sqlite_purgePlayers[] = "DELETE FROM players WHERE date < datetime('now', '-%d days');";
new String:sql_purgePlayers[] = "DELETE FROM players WHERE date < DATE_SUB(CURDATE(),INTERVAL %d DAY);";


new String:sqlite_dropMap[] = "DROP TABLE map; VACCUM";
new String:sql_dropMap[] = "DROP TABLE map;";
new String:sqlite_dropPlayer[] = "DROP TABLE player; VACCUM";
new String:sql_dropPlayer[] = "DROP TABLE player;";

new String:sql_resetCheckpoints[] = "UPDATE player SET cords = '0:0:0', angle = '0:0:0' WHERE name LIKE '%s' AND mapname LIKE '%s';";

//upgrade scripts
new String:sql_selectVersion[] = "SELECT version FROM meta;";
new String:sql_updateVersion[] = "UPDATE meta SET version = '%s';";
new String:sql_upgrade2_1_0[] = "UPDATE player SET runtime = runtime*10 WHERE runtime != -1";

//-------------------------//
// database initialization //
//-------------------------//
public db_setupDatabase(){
	decl String:szError[255];
	g_hDb = SQL_Connect("cpmod", false, szError, 255);
	
	//if a connection canot be made
	if(g_hDb == INVALID_HANDLE){
		LogError("[cP Mod] Unable to connect to database (%s)", szError);
		return;
	}
	
	decl String:szIdent[8];
	SQL_ReadDriver(g_hDb, szIdent, 8);
	//select the driver depending on the settings (mysql/sqlite)
	if(strcmp(szIdent, "mysql", false) == 0){
		g_DbType = MYSQL;
	}else if(strcmp(szIdent, "sqlite", false) == 0){
		g_DbType = SQLITE;
	}else{
		LogError("[cP Mod] Invalid Database-Type");
		return;
	}
	
	//create the tables
	db_createTables();
	
	//check for updates
	db_performUpdates();
}

//-----------------------//
// table creation method //
//-----------------------//
public db_createTables(){
	SQL_LockDatabase(g_hDb);
	
	SQL_FastQuery(g_hDb, sql_createMap);
	SQL_FastQuery(g_hDb, sql_createPlayer);
	SQL_FastQuery(g_hDb, sql_createMeta);
	
	SQL_UnlockDatabase(g_hDb);
}

//------------------------//
// perform updates method //
//------------------------//
public db_performUpdates(){
	SQL_TQuery(g_hDb, SQL_CheckUpdateCallback, sql_selectVersion);
}
//----------//
// callback //
//----------//
public SQL_CheckUpdateCallback(Handle:owner, Handle:hndl, const String:error[], any:data){
	//if there is a result
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl)){
		decl String:szVersion[8];
		
		//get the result
		SQL_FetchString(hndl, 0, szVersion, 8);
		
		//check for 2.1.0 update
		new comparison = compareVersionStrings(szVersion, "2.1.0");
		if(comparison < 0){
			LogMessage("Performing 2.1.0 database update...");
			
			//perform 2.1.0 update
			SQL_TQuery(g_hDb, SQL_CheckCallback, sql_upgrade2_1_0);
			
			//update version in database
			db_updateVersion("2.1.0");
		}
	}else{ //init data
		SQL_TQuery(g_hDb, SQL_InitMetaCallback, sql_initMeta);
	}
}
//----------//
// callback //
//----------//
public SQL_InitMetaCallback(Handle:owner, Handle:hndl, const String:error[], any:data){
	//simply try the update again
	db_performUpdates();
}

//------------------------------//
// update version method //
//------------------------------//
public db_updateVersion(String:szVersion[]){
	decl String:szQuery[255];
	Format(szQuery, 255, sql_updateVersion, szVersion);
	
	SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery);
}


//-------------------//
// insert map method //
//-------------------//
public db_insertMap(){
	decl String:szQuery[255];
	Format(szQuery, 255, sql_insertMap, g_szMapName);
		
	SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery);
}

//----------------------//
// insert player method //
//----------------------//
public db_insertPlayer(client){
	decl String:szQuery[255];
	decl String:szSteamId[32];
	decl String:szUName[MAX_NAME_LENGTH];
	//get some playerinformation
	GetClientAuthString(client, szSteamId, 32);
	GetClientName(client, szUName, MAX_NAME_LENGTH);
	
	decl String:szName[MAX_NAME_LENGTH*2+1];
	//escape some quote characters that could mess up the szQuery
	SQL_QuoteString(g_hDb, szUName, szName, MAX_NAME_LENGTH*2+1);
	
	Format(szQuery, 255, sql_insertPlayer, szSteamId, g_szMapName, szName);
	
	SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery);
}

//---------------------------------//
// update player checkpoint method //
//---------------------------------//
public db_updatePlayerCheckpoint(client, current){
	decl String:szQuery[255];
	decl String:szUName[MAX_NAME_LENGTH];
	decl String:szSteamId[32];
	//get some playerinformation
	GetClientName(client, szUName, MAX_NAME_LENGTH);
	GetClientAuthString(client, szSteamId, 32);
	
	decl String:szName[MAX_NAME_LENGTH*2+1];
	//escape some quote characters that could mess up the szQuery
	SQL_QuoteString(g_hDb, szUName, szName, MAX_NAME_LENGTH*2+1);
	
	Format(szQuery, 255, sql_insertPlayer, szSteamId, g_szMapName, szName);
	
	//write the coordinates in a string buffer
	decl String:szCords[38];
	Format(szCords, 38, "%f:%f:%f",g_fPlayerCords[client][current][0],g_fPlayerCords[client][current][1],g_fPlayerCords[client][current][2]);
	decl String:szAngles[255];
	Format(szAngles, 38, "%f:%f:%f",g_fPlayerAngles[client][current][0],g_fPlayerAngles[client][current][1],g_fPlayerAngles[client][current][2]);
	
	Format(szQuery, 255, sql_updatePlayerCheckpoint, szName, szCords, szAngles, szSteamId, g_szMapName);
	
	SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery);
}
//----------//
// callback //
//----------//
public SQL_SelectPlayerCallback(Handle:owner, Handle:hndl, const String:error[], any:data){
	if(hndl == INVALID_HANDLE)
		LogError("[cP Mod] Error loading player (%s)", error);
	
	new client = data;
	//if there is a player entry
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl) && IsClientInGame(client)){
		//do nothing
	}else
		db_insertPlayer(client);
}

//---------------------------------//
// select player checkpoint method //
//---------------------------------//
public db_selectPlayerCheckpoint(client){
	decl String:szQuery[255];
	decl String:szSteamId[32];
	GetClientAuthString(client, szSteamId, 32);
	
	Format(szQuery, 255, sql_selectCheckpoint, szSteamId, g_szMapName);
	
	SQL_TQuery(g_hDb, SQL_SelectCheckpointCallback, szQuery, client);
}
//----------//
// callback //
//----------//
public SQL_SelectCheckpointCallback(Handle:owner, Handle:hndl, const String:error[], any:data){
	if(hndl == INVALID_HANDLE)
		LogError("[cP Mod] Error loading checkpoint (%s)", error);
	
	new client = data;
	//if there is a checkpoint entry
	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl) && IsClientInGame(client)){
		decl String:szCords[38];
		decl String:szAngles[38];
		
		//fetch the results
		SQL_FetchString(hndl, 0, szCords, 38);
		SQL_FetchString(hndl, 1, szAngles, 38);
		
		//if checkpoint not valid
		if(StrEqual(szCords, "0:0:0") || StrEqual(szCords, "0.000000:0.000000:0.000000") || StrEqual(szAngles, "0:0:0") || StrEqual(szAngles, "0.000000:0.000000:0.000000")){
			g_CurrentCp[client] = -1;
			g_WholeCp[client] = 0;
		}else{ //valid
			//parse the result into string buffers
			decl String:szCBuff[3][38];
			ExplodeString(szCords, ":", szCBuff, 3, 38);
			g_fPlayerCords[client][0][0] = StringToFloat(szCBuff[0]);
			g_fPlayerCords[client][0][1] = StringToFloat(szCBuff[1]);
			g_fPlayerCords[client][0][2] = StringToFloat(szCBuff[2]);
			
			ExplodeString(szAngles, ":", szCBuff, 3, 38);
			g_fPlayerAngles[client][0][0] = StringToFloat(szCBuff[0]);
			g_fPlayerAngles[client][0][1] = StringToFloat(szCBuff[1]);
			g_fPlayerAngles[client][0][2] = StringToFloat(szCBuff[2]);
			//add a checkpoint
			g_WholeCp[client] = 1;
			//set the current checkpoint to the first
			g_CurrentCp[client] = 0;
			
			PrintToChat(client, "%t", "CheckpointRestored", YELLOW,LIGHTGREEN,YELLOW,GREEN,YELLOW);
		}
	}
}


//---------------------//
// purge player method //
//---------------------//
public db_purgePlayer(client, String:szdays[]){
	decl String:szQuery[255];
	new days = StringToInt(szdays);
	
	if(g_DbType == MYSQL)
		Format(szQuery, 255, sql_purgePlayers, days);
	else
		Format(szQuery, 255, sqlite_purgePlayers, days);
	
	SQL_LockDatabase(g_hDb);
	SQL_FastQuery(g_hDb, szQuery);
	SQL_UnlockDatabase(g_hDb);
	
	PrintToConsole(client, "PlayerDatabase purged.");
	LogMessage("PlayerDatabase purged.");
}

//-----------------//
// drop map method //
//------------------//
public db_dropMap(client){
	SQL_LockDatabase(g_hDb);
	
	if(g_DbType == MYSQL)
		SQL_FastQuery(g_hDb, sql_dropMap);
	else
		SQL_FastQuery(g_hDb, sqlite_dropMap);
	
	SQL_UnlockDatabase(g_hDb);
	
	PrintToConsole(client, "MapTable dropped. Please restart the server!");
	LogMessage("MapTable dropped.");
}
//--------------------//
// drop player method //
//--------------------//
public db_dropPlayer(client){
	SQL_LockDatabase(g_hDb);
	
	if(g_DbType == MYSQL)
		SQL_FastQuery(g_hDb, sql_dropPlayer);
	else
		SQL_FastQuery(g_hDb, sqlite_dropPlayer);
	
	SQL_UnlockDatabase(g_hDb);
	
	PrintToConsole(client, "PlayerTable dropped. Please restart the server!");
	LogMessage("PlayerTable dropped.");
}

//---------------------------------//
// reset player checkpoints method //
//---------------------------------//
public db_resetPlayerCheckpoints(client, String:szPlayerName[MAX_NAME_LENGTH], String:szMapName[MAX_MAP_LENGTH]){
	decl String:szQuery[255];
	
	//escape some quote characters that could mess up the szQuery
	decl String:szName[MAX_NAME_LENGTH*2+1];
	SQL_QuoteString(g_hDb, szPlayerName, szName, MAX_NAME_LENGTH*2+1);
	
	Format(szQuery, 255, sql_resetCheckpoints, szName, szMapName);
	
	SQL_LockDatabase(g_hDb);
	SQL_FastQuery(g_hDb, szQuery);
	SQL_UnlockDatabase(g_hDb);
	
	PrintToConsole(client, "PlayerCheckpointsTable cleared (%s on %s).",szPlayerName, szMapName);
	LogMessage("PlayerCheckpointsTable cleared (%s on %s).", szPlayerName, szMapName);
}

//-----------------//
// global callback //
//-----------------//
public SQL_CheckCallback(Handle:owner, Handle:hndl, const String:error[], any:data){
	if(hndl == INVALID_HANDLE)
		LogError("[cP Mod] Error inserting into database (%s).", error);
}
