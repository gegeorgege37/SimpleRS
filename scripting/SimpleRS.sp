//░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//░░░░░░░░░░░▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄░░░░░░░░░░
//░░░░░░░░░▄▀░░░░░░░░░░░░░░░░░░░░▀▄░░░░░░░░
//░░░░░░░░░█░░▄░░░░▄░░░░░░░░░▀░░░░█░░░░░░░░
//░░░░░░░░░█░░░░░░░░░░░░▄█▄▄░░░▄░░█░▄▄▄░░░░
//░░▄▄▄▄▄░░█░░░░░░▀░░░░▀█░░▀▄░░░░░█▀▀░██░░░
//░░██▄▀██▄█░░░▄░░░░░░░██░░░░▀▀▀▀▀░░░░██░░░
//░░░▀██▄▀██░░░░░░░░▀░██▀░░░░░░░░░░░░░▀██░░
//░░░░░▀████░▀░░░░▄░░░██░░░▄█░░░░░░▄█░░██░░
//░░░░░░░░▀█░░░░▄░░░░░██░░░░▄░░░▄░░▄░░░██░░
//░░░░░░░░▄█▄░░░░░░░░░░░▀▄░░▀▀▀▀▀▀▀▀░░▄▀░░░
//░░░░░░░█▀▀█████████▀▀▀▀████████████▀░░░░░
//░░░░░░░▀███▀░░███▀░░░░░░▀███░░▀██▀░░░░░░░
//░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

#include <sourcemod>
#include <cstrike>

new Handle:Cooldown;
new PassedRounds[MAXPLAYERS+1];
bool:CanResetScore[MAXPLAYERS+1];

public Plugin myinfo = {
	name = "Simple Reset Score",
	author = "GeoDanny",
	description = "Simple reset score with configurable Cooldown",
	version = "1.0",
	url = "http://steamcommunity.com/id/playwithdanny"
};

public OnPluginStart() {
	RegConsoleCmd("sm_resetscore", SimpleRS);
	Cooldown = CreateConVar("simplers_cooldown", "1");
	RegConsoleCmd("sm_rs", SimpleRS);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
}

public OnClientPutInServer(client) {
	if(!IsFakeClient(client) && GetConVarInt(Cooldown) > 0) {
		CanResetScore[client] = false;
		PassedRounds[client] = 0;
	}
}

public OnClientDisconnect(client) {
	if(!IsFakeClient(client) && GetConVarInt(Cooldown) > 0) {
		CanResetScore[client] = false;
		PassedRounds[client] = 0;
	}
}

public void Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
	for(new i = 1; i <= MaxClients; i++) { 
		if(IsClientInGame(i) && !IsFakeClient(i)) { 
			if(!CanResetScore[i] && GetConVarInt(Cooldown) > 0) {
				PassedRounds[i] ++;
				if(PassedRounds[i] >= GetConVarInt(Cooldown)) {
					CanResetScore[i] = true;
					PassedRounds[i] = 0;
				}
			}
		}
	}
}

public void Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast) {
	for(new i = 1; i <= MaxClients; i++) { 
		if(IsClientInGame(i) && !IsFakeClient(i) && !CanResetScore[i] && GetConVarInt(Cooldown) > 0 && PassedRounds[i] >= GetConVarInt(Cooldown)) { 
			CanResetScore[i] = true;
			PassedRounds[i] = 0;
		}
	}
}

public Action SimpleRS(int client, int Args) {
	if(client == 0) {
		PrintToServer("[SimpleRS] You can use this command in-game only!");
		return Plugin_Handled;
	}
	if(!CanResetScore[client] && GetConVarInt(Cooldown) > 0) {
		if(GetConVarInt(Cooldown) > 1) {
			PrintToChat(client, " \x01\x0B\x04[SimpleRS]\x01 Your score are already reset, wait\x03 %d\x01 rounds.", GetConVarInt(Cooldown));
		}
		else if(GetConVarInt(Cooldown) == 1) {
			PrintToChat(client, " \x01\x0B\x04[SimpleRS]\x01 Your score are already reset, wait\x03 %d\x01 round.", GetConVarInt(Cooldown));
		}
		return Plugin_Handled;
	}
	if(GetConVarInt(Cooldown) > 0) {
		CanResetScore[client] = false;
	}
	SetEntProp(client, Prop_Data, "m_iFrags", 0);
	SetEntProp(client, Prop_Data, "m_iDeaths", 0);
	CS_SetMVPCount(client, 0);
	CS_SetClientAssists(client, 0);
	CS_SetClientContributionScore(client, 0);
	new String:pName[32];
	GetClientName(client, pName, sizeof(pName));
	PrintToChatAll(" \x01\x0B\x04[SimpleRS]\x01 Player\x03 %s\x01 has just reset his score.", pName);
	return Plugin_Handled;
}