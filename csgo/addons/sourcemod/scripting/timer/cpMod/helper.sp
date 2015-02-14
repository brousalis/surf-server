//---------------------------//
// setup record sound method //
//---------------------------//
public compareVersionStrings(String:szVersion1[], String:szVersion2[])
{
	//explode first version
	decl String:szCBuff1[3][6];
	ExplodeString(szVersion1, ".", szCBuff1, 3, 6);
	
	//explode second version
	decl String:szCBuff2[3][6];
	ExplodeString(szVersion2, ".", szCBuff2, 3, 6);
	
	//major version
	new res = strncmp(szCBuff1[0], szCBuff2[0], 5);
	if(res == 0){
		//minor version
		res = strncmp(szCBuff1[1], szCBuff2[1], 5);
		if(res == 0){
			//bugfix version
			res = strncmp(szCBuff1[2], szCBuff2[2], 5);
		}
	}
	
	return res;
}