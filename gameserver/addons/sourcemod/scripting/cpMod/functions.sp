stock FormatTime_Record(Float:time, String:strTime[], iSize)
{
	new Float:second, minute, hour;
	decl String:st_sec[128], String:st_min[128], String:st_hr[128];
	new newTime = RoundToZero(time);
	if (newTime >= 3600)
	{
		hour = newTime / 3600;
		minute = (newTime - hour*3600) / 60 ;
		second = time - (hour*3600 + minute*60);
	}
	else if(3600 > newTime >= 60)
	{
		hour = 0;
		minute = newTime / 60;
		second = time - (minute*60);
	}
	else
	{
		hour = 0;
		minute = 0;
		second = time;
	}
	if (hour < 1)
	{
		Format(st_hr, 128, "");
		if(minute >= 1)
			Format(st_min, 128, "%d:", minute);
		else if(minute < 1)
			Format(st_min, 128, "0:");
		if (second < 10.000)
			Format(st_sec, 128, "0%.2f", second);
		else
			Format(st_sec, 128, "%.2f", second);
	}
	else
	{
		Format(st_hr, 128, "%d:", hour);
		if(minute >= 10)
			Format(st_min, 128, "%d:", minute);
		else if(minute < 10)
			Format(st_min, 128, "0%d:", minute);
		else if(minute < 1)
			Format(st_min, 128, "00:");
		if (second < 10.000)
			Format(st_sec, 128, "0%.2f", second);
		else
			Format(st_sec, 128, "%.2f", second);
	}
	Format(strTime, iSize, "%s%s%s", st_hr, st_min, st_sec);
}
stock PrintHint2Spec(target, const String:msg[])
{
	for(new i = 1; i<= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if(IsClientObserver(i))
			{
				new obTarget = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget");
				if((obTarget > 0)&&(obTarget==target))
				{
					PrintHintText(i, msg);
				}
			}
		}
	}
}
stock PrintKeyHint(client, const String:msg[])
{
	new Handle:hBuffer = StartMessageOne("KeyHintText", client);
	BfWriteByte(hBuffer, 1);
	BfWriteString(hBuffer, msg);
	EndMessage();
}
stock PrintKeyHint2Spec(target, const String:msg[])
{
	for(new i = 1; i <= MaxClients;i++)
	{
		if(IsClientInGame(i))
		{
			if(IsClientObserver(i))
			{
				new obTarget = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget");
				if((obTarget > 0)&&(obTarget==target))
				{
					PrintKeyHint(i, msg);
				}
			}
		}
	}
}
KickLowFPSPlayers()
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if(g_PlayerFPS[i] < 300.0)
			{
				KickClient(i, "Set fps_max 300 in console");
			}
			else
			{
				FakeClientCommandEx(i, "say /normal");
			}
		}
	}
}
DefineBhopType(client, &buttons)
{
	if(g_bSideWayFailed[client])
		return;
	if((buttons & IN_MOVERIGHT)||(buttons & IN_MOVELEFT))
	{
		g_PlayerLevel[client] = BhopLevel_Normal;
		g_bSideWayFailed[client] = true;
	}
	if((buttons & IN_FORWARD)||(buttons & IN_BACK))
	{
		if(g_PlayerLevel[client] == BhopLevel_Normal&&!g_bSideWayFailed[client])
		{
			g_PlayerLevel[client] = BhopLevel_SideWays;
		}
	}
}