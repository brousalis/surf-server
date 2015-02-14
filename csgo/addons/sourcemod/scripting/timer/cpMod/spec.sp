CreateHudHintTimer(client)
{
 HudHintTimers[client] = CreateTimer(0.4, Timer_UpdateHudHint, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_UpdateHudHint(Handle:timer, any:client)
{

if(client != 0 && IsClientInGame(client) && !IsFakeClient(client) && IsClientConnected(client))  
{

	
	new iSpecModeUser = GetEntProp(client, Prop_Send, "m_iObserverMode");
	new iSpecMode, iTarget;
		
	decl String:szText[254];
	szText[0] = '\0';
	if (!IsClientObserver(client) && IsClientInGame(client)){
		if(g_bRacing[client] == false){	
		decl Float:fVelocity[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);
		new speed = RoundToFloor(SquareRoot(Pow(fVelocity[0],2.0)+Pow(fVelocity[1],2.0)+Pow(fVelocity[2],2.0)));
		
		if (speed<10){
			PrintHintText(client,"Speed:     %i",speed);
		}
		if (speed>10 && speed<100){
			PrintHintText(client,"Speed:   %i",speed);
		}
		if (speed>100){
			PrintHintText(client,"Speed: %i",speed);
		}
		
		}
	}
	
	if (iSpecModeUser == SPECMODE_FIRSTPERSON || iSpecModeUser == SPECMODE_3RDPERSON)
	{
		decl String:szTime[16];
		decl String:szJumps[16];
		decl String:szlead[16];
		decl String:szttwr[16];	
		
		
		if (!IsClientInGame(client) || !IsClientObserver(client)){
			return Plugin_Continue;
		}
			
		
		iSpecMode = GetEntProp(client, Prop_Send, "m_iObserverMode");
		
		// The client isn't spectating any one person, so ignore them.
		if (iSpecMode != SPECMODE_FIRSTPERSON && iSpecMode != SPECMODE_3RDPERSON){
			return Plugin_Continue;
		}
		// Find out who the client is spectating.
		
		iTarget = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
		if(iTarget != 0 && iTarget != -1 && IsClientInGame(iTarget) && !IsFakeClient(iTarget) && IsClientConnected(iTarget))  
		{
		// Are they spectating the same player as User?
		if(g_bRacing[iTarget] == false){	
			decl Float:fVelocity[3];
			GetEntPropVector(iTarget, Prop_Data, "m_vecVelocity", fVelocity);
			new speed = RoundToFloor(SquareRoot(Pow(fVelocity[0],2.0)+Pow(fVelocity[1],2.0)+Pow(fVelocity[2],2.0)));
			
			if (speed<10){
				PrintHintText(client,"Speed:     %i",speed);
			}
			if (speed>10 && speed<100){
				PrintHintText(client,"Speed:   %i",speed);
			}
			if (speed>100){
				PrintHintText(client,"Speed: %i",speed);
			}
		}
		
		if(g_bRacing[iTarget] == true){	
			decl Float:fVelocity[3];
			GetEntPropVector(iTarget, Prop_Data, "m_vecVelocity", fVelocity);
			new speed = RoundToFloor(SquareRoot(Pow(fVelocity[0],2.0)+Pow(fVelocity[1],2.0)+Pow(fVelocity[2],2.0)));
			
			new minttwr = g_TimeToLeader[iTarget]/60;
			new secttwr = g_TimeToLeader[iTarget]%60;
			new minlead = g_RecordTime/60;
			new seclead = g_RecordTime%60;
			//calculate time, jumps and speed
			new minutes = g_RunTime[iTarget]/60;
			new seconds = g_RunTime[iTarget]%60;
			if (seconds<10){
			Format(szTime, 16, "%i:0%i", minutes, seconds);
			}
			else{
			Format(szTime, 16, "%i:%i", minutes, seconds);
			}
			if (seclead<10){
			Format(szlead, 16, "%i:0%i", minlead, seclead);
			}
			else{
			Format(szlead, 16, "%i:%i", minlead, seclead);
			}
			if (secttwr<10){
			Format(szttwr, 16, "%i:0%i", minttwr, secttwr);
			}
			else{
			Format(szttwr, 16, "%i:%i", minttwr, secttwr);
			}
			
			Format(szJumps, 16, "%i", g_RunJumps[iTarget]);
			
			if (minlead==16666){
			szlead="No wr!";
			szttwr="No wr!";
			}
			if (postime[iTarget]==0){
				if (speed<10){
					PrintHintText(client,"Time: %s\nJumps: %s\nSpeed:     %i\nwr: %s\nttwr: -%s",szTime,szJumps,speed,szlead,szttwr);
				}
				if (speed>10 && speed<100){
					PrintHintText(client,"Time: %s\nJumps: %s\nSpeed:   %i\nwr: %s\nttwr: -%s",szTime,szJumps,speed,szlead,szttwr);
				}
				if (speed>100){
					PrintHintText(client,"Time: %s\nJumps: %s\nSpeed: %i\nwr: %s\nttwr: -%s",szTime,szJumps,speed,szlead,szttwr);
				}
			}
			else{
			if (speed<10){
					PrintHintText(client,"Time: %s\nJumps: %s\nSpeed:     %i\nwr: %s\nttwr: +%s",szTime,szJumps,speed,szlead,szttwr);
			}
			if (speed>10 && speed<100){
					PrintHintText(client,"Time: %s\nJumps: %s\nSpeed:   %i\nwr: %s\nttwr: +%s",szTime,szJumps,speed,szlead,szttwr);
			}
			if (speed>100){
					PrintHintText(client,"Time: %s\nJumps: %s\nSpeed: %i\nwr: %s\nttwr: +%s",szTime,szJumps,speed,szlead,szttwr);
			}
			
			}
		}
		}
	}

	return Plugin_Continue;
}
return Plugin_Continue;
}