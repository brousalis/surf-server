#include <timer>
#include <timer-logging>

static Handle:g_log_file = INVALID_HANDLE;
static const String:g_log_level_names[][] = { "     ", "ERROR", "WARN ", "INFO ", "DEBUG", "TRACE" };
static Timer_LogLevel:g_log_level = Timer_LogLevelNone;
static Timer_LogLevel:g_log_flush_level = Timer_LogLevelNone;
static bool:g_log_errors_to_SM = false;
static String:g_current_date[20];

public Plugin:myinfo =
{
    name        = "[Timer] Logging",
    author      = "Zipcore, Credits: Alongub",
    description = "Logging component for [Timer]",
    version     = PL_VERSION,
    url         = "zipcore#googlemail.com"
};

public OnPluginStart() 
{
	LoadConfig();
	
	FormatTime(g_current_date, sizeof(g_current_date), "%Y-%m-%d", GetTime());
	CreateTimer(1.0, OnCheckDate, INVALID_HANDLE, TIMER_REPEAT);
	
	if (g_log_level > Timer_LogLevelNone)
		CreateLogFileOrTurnOffLogging();		
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) 
{
	RegPluginLibrary("timer-logging");
	
	CreateNative("Timer_GetLogLevel", Timer_GetLogLevel_);
	CreateNative("Timer_Log",         Timer_Log_);
	CreateNative("Timer_LogError",    Timer_LogError_);
	CreateNative("Timer_LogWarning",  Timer_LogWarning_);
	CreateNative("Timer_LogInfo",     Timer_LogInfo_);
	CreateNative("Timer_LogDebug",    Timer_LogDebug_);
	CreateNative("Timer_LogTrace",    Timer_LogTrace_);
    
	return APLRes_Success;
}

LoadConfig() 
{
	new Handle:kv = CreateKeyValues("root");
    
	decl String:path[100];
	BuildPath(Path_SM, path, sizeof(path), "configs/timer/logging.cfg");
    
	if (!FileToKeyValues(kv, path))
    {
		CloseHandle(kv);
		SetFailState("Can't read config file %s", path);
	}

	g_log_level = Timer_LogLevel:KvGetNum(kv, "log_level", 2);
	g_log_flush_level = Timer_LogLevel:KvGetNum(kv, "log_flush_level", 2);
	g_log_errors_to_SM = (KvGetNum(kv, "log_errors_to_SM", 1) > 0);

	CloseHandle(kv);
}

public OnPluginEnd() 
{
	if (g_log_file != INVALID_HANDLE)
		CloseLogFile();
}

public Action:OnCheckDate(Handle:timer)
{
	decl String:new_date[20];
	FormatTime(new_date, sizeof(new_date), "%Y-%m-%d", GetTime());
    
	if (g_log_level > Timer_LogLevelNone && !StrEqual(new_date, g_current_date)) 
    {
		strcopy(g_current_date, sizeof(g_current_date), new_date);
        
		if (g_log_file != INVALID_HANDLE) 
        {
			WriteMessageToLog(INVALID_HANDLE, Timer_LogLevelInfo, "Date changed; switching log file", true);
			CloseLogFile();
		}
        
		CreateLogFileOrTurnOffLogging();
	}
}

CloseLogFile() 
{
	WriteMessageToLog(INVALID_HANDLE, Timer_LogLevelInfo, "Logging stopped");
	FlushFile(g_log_file);
	CloseHandle(g_log_file);
	g_log_file = INVALID_HANDLE;
}

bool:CreateLogFileOrTurnOffLogging()
{
	decl String:filename[128];
	new pos = BuildPath(Path_SM, filename, sizeof(filename), "logs/");
	FormatTime(filename[pos], sizeof(filename)-pos, "timer_%Y-%m-%d.log", GetTime());
    
	if ((g_log_file = OpenFile(filename, "a")) == INVALID_HANDLE) 
    {
		g_log_level = Timer_LogLevelNone;
		LogError("Can't create timer log file");
		return false;
	}
	else 
    {
		WriteMessageToLog(INVALID_HANDLE, Timer_LogLevelInfo, "Logging started", true);
		return true;
	}
}

public Timer_GetLogLevel_(Handle:plugin, num_params) 
{
	return _:g_log_level;
}

public Timer_Log_(Handle:plugin, num_params) 
{
	new Timer_LogLevel:log_level = Timer_LogLevel:GetNativeCell(1);
	if (g_log_level >= log_level) 
    {
		decl String:message[10000], written;
		FormatNativeString(0, 2, 3, sizeof(message), written, message);
        
		if (g_log_file != INVALID_HANDLE)
			WriteMessageToLog(plugin, log_level, message);
            
		if (log_level == Timer_LogLevelError && g_log_errors_to_SM) 
        {
			ReplaceString(message, sizeof(message), "%", "%%");
			LogError(message);
		}
	}
}

public Timer_LogError_(Handle:plugin, num_params) 
{
	if (g_log_level >= Timer_LogLevelError) 
    {
		decl String:message[10000], written;
		FormatNativeString(0, 1, 2, sizeof(message), written, message);
        
		if (g_log_file != INVALID_HANDLE)
        {
			WriteMessageToLog(plugin, Timer_LogLevelError, message);
        }
         
		if (g_log_errors_to_SM) 
        {
			ReplaceString(message, sizeof(message), "%", "%%");
			LogError(message);
		}
	}
}

public Timer_LogWarning_(Handle:plugin, num_params) 
{
	if (g_log_level >= Timer_LogLevelWarning && g_log_file != INVALID_HANDLE) 
    {
		decl String:message[10000], written;
		FormatNativeString(0, 1, 2, sizeof(message), written, message);
		WriteMessageToLog(plugin, Timer_LogLevelWarning, message);
	}
}

public Timer_LogInfo_(Handle:plugin, num_params) 
{
	if (g_log_level >= Timer_LogLevelInfo && g_log_file != INVALID_HANDLE) 
    {
		decl String:message[10000], written;
		FormatNativeString(0, 1, 2, sizeof(message), written, message);
		WriteMessageToLog(plugin, Timer_LogLevelInfo, message);
	}
}

public Timer_LogDebug_(Handle:plugin, num_params) 
{
	if (g_log_level >= Timer_LogLevelDebug && g_log_file != INVALID_HANDLE) 
    {
		decl String:message[10000], written;
		FormatNativeString(0, 1, 2, sizeof(message), written, message);
		WriteMessageToLog(plugin, Timer_LogLevelDebug, message);
	}
}

public Timer_LogTrace_(Handle:plugin, num_params) 
{
	if (g_log_level >= Timer_LogLevelTrace && g_log_file != INVALID_HANDLE) 
    {
		decl String:message[10000], written;
		FormatNativeString(0, 1, 2, sizeof(message), written, message);
		WriteMessageToLog(plugin, Timer_LogLevelTrace, message);
	}
}

WriteMessageToLog(Handle:plugin, Timer_LogLevel:log_level, const String:message[], bool:force_flush=false) 
{
	decl String:log_line[10000];
	PrepareLogLine(plugin, log_level, message, log_line);
	WriteFileString(g_log_file, log_line, false);
    
	if (log_level <= g_log_flush_level || force_flush)
		FlushFile(g_log_file);
}

PrepareLogLine(Handle:plugin, Timer_LogLevel:log_level, const String:message[], String:log_line[10000]) 
{
	decl String:plugin_name[100];
	GetPluginFilename(plugin, plugin_name, sizeof(plugin_name)-1);
	// Make windows consistent with unix
	ReplaceString(plugin_name, sizeof(plugin_name), "\\", "/");
	new name_end = strlen(plugin_name);
	plugin_name[name_end++] = ']';
	for (new end=PLUGIN_NAME_RESERVED_LENGTH-1; name_end<end; ++name_end)
		plugin_name[name_end] = ' ';
	plugin_name[name_end++] = 0;
	FormatTime(log_line, sizeof(log_line), "%Y-%m-%d %H:%M:%S [", GetTime());
	new pos = strlen(log_line);
	pos += strcopy(log_line[pos], sizeof(log_line)-pos, plugin_name);
	log_line[pos++] = ' ';
	pos += strcopy(log_line[pos], sizeof(log_line)-pos-5, g_log_level_names[log_level]);
	log_line[pos++] = ' ';
	log_line[pos++] = '|';
	log_line[pos++] = ' ';
	pos += strcopy(log_line[pos], sizeof(log_line)-pos-2, message);
	log_line[pos++] = '\n';
	log_line[pos++] = 0;
}