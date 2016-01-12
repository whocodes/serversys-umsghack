#include <sourcemod>
#include <protobuf>
#include <serversys>

#pragma semicolon 1

public Plugin:myinfo = {
	name = "[Server-Sys] UMsg-Hack",
	author = "whocodes, twistedpanda",
	description = "whocodes.pw",
	version = "1.0",
	url = "whocodes.pw"
}

int g_iTotalHiddenPhrases;
ArrayList g_hArray_HiddenPhrase = view_as<ArrayList>(INVALID_HANDLE);

bool g_bEnabled = true;
bool g_bDebug = false;

public void OnPluginStart(){
	HookUserMessage(GetUserMessageId("TextMsg"), UserMessageHook_Text, true);

	if(!LoadConfig()){
		SetFailState("[server-sys] umsghack :: Unable to load.");
	}
}

public Action UserMessageHook_Text(UserMsg msg_id, Protobuf msg, const int[] players, int playersNum, bool reliable, bool init){
	if(!g_bEnabled)
		return Plugin_Continue;

	char sBuffer[64]; char sResult[64];

	int iRepeat = PbGetRepeatedFieldCount(msg, "params");
	for(int i = 0; i < iRepeat; i++){
		PbReadString(msg, "params", sBuffer, sizeof(sBuffer), i);
		if(StrEqual(sBuffer, ""))
			continue;

		if(g_bDebug){
			PrintToServer("UserMessage Debug :: %s", sBuffer);
		}

		if(g_hArray_HiddenPhrase != INVALID_HANDLE){
			for(int j = 0; j < g_iTotalHiddenPhrases; j++){
				g_hArray_HiddenPhrase.GetString(j, sResult, sizeof(sResult));
				if(StrContains(sBuffer, sResult) != -1)
					return Plugin_Handled;
			}
		}
	}

	return Plugin_Continue;
}

bool LoadConfig(){
	if(g_hArray_HiddenPhrase == INVALID_HANDLE)
		g_hArray_HiddenPhrase = CreateArray(16);
	else
		g_hArray_HiddenPhrase.Clear();

	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/serversys/umsghack.cfg");

	if(!FileExists(path)){
		LogError("[server-sys] umsghack :: Can't find config file: %s", path);
		return false;
	}

	KeyValues kv = CreateKeyValues("UMsg-Hack");
	kv.SetEscapeSequences(true);

	if(kv.ImportFromFile(path)){
		g_bEnabled = view_as<bool>(kv.GetNum("enabled", 1));
		g_bDebug = view_as<bool>(kv.GetNum("debug", 0));

		if(kv.JumpToKey("Phrases")){
			char result[64];
			g_iTotalHiddenPhrases = 0;
			kv.GotoFirstSubKey(false);

			while(kv.GotoNextKey(false)){
				kv.GetSectionName(result, sizeof(result));

				g_hArray_HiddenPhrase.PushString(result);
				g_iTotalHiddenPhrases++;
			}
		}
		delete kv;
		return true;
	}

	delete kv;
	return false;
}
