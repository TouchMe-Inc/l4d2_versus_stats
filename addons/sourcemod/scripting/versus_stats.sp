#pragma semicolon               1
#pragma newdecls                required

#include <sourcemod>
#include <sdktools>
#include <colors>

#undef REQUIRE_PLUGIN
#include <readyup>
#define LIB_READY              "readyup"


public Plugin myinfo = { 
	name = "VersusStats",
	author = "TouchMe",
	description = "Versus mode statistics",
	version = "1.0"
};


#define AUTO_EXEC_CONFIG        "versus_stats"
#define DATABASE                "versus_stats"
#define TRANSLATIONS            "versus_stats.phrases"

#define GAMEMODE_VERSUS         "versus"

#define TEAM_NONE               0
#define TEAM_SPECTATOR          1
#define TEAM_SURVIVOR           2
#define TEAM_INFECTED           3

#define ZC_SMOKER               1
#define ZC_BOOMER               2
#define ZC_HUNTER               3
#define ZC_SPITTER              4
#define ZC_JOCKEY               5
#define ZC_CHARGER              6
#define ZC_WITCH                7
#define ZC_TANK                 8

#define CREATE_CODE_STATS_TEMP         "code_stats_%d int(11) UNSIGNED NOT NULL DEFAULT 0,"
#define CREATE_CODE_STATS_TEMP_SIZE    53

#define UPDATE_CODE_STATS_TEMP         "`code_stats_%d`=%d,"
#define UPDATE_CODE_STATS_TEMP_SIZE    30

#define INSERT_CODE_STATS_COLUMN_TEMP  "code_stats_%d,"
#define INSERT_CODE_STATS_COLUMN_TEMP_SIZE 16

#define INSERT_CODE_STATS_VALUE_TEMP  "%d,"
#define INSERT_CODE_STATS_VALUE_TEMP_SIZE 11

#define PER_PAGE                7
#define HOUR                    3600

#define WID_PISTOL              1
#define WID_SMG                 2
#define WID_PUMP                3
#define WID_AUTO                4
#define WID_M16                 5
#define WID_HUNTING             6
#define WID_SILENCED            7
#define WID_CHROME              8
#define WID_DESERT              9
#define WID_MILITARY            10
#define WID_SPAS                11
#define WID_MOLOTOV             13
#define WID_PIPE                14
#define WID_MELEE               19
#define WID_SAW                 20
#define WID_GL                  21
#define WID_AK47                26
#define WID_MAGNUM              32
#define WID_MP5                 33
#define WID_SG552               34
#define WID_AWP                 35
#define WID_SCOUT               36
#define WID_M60                 37


// Infected Kill
#define SURVIVOR_K_CI           0  // Surivivor Killed Common Infected
#define SURVIVOR_K_SMOKER       1  // Surivivor Killed Smoker
#define SURVIVOR_K_BOOMER       2  // Surivivor Killed Boomer
#define SURVIVOR_K_HUNTER       3  // Surivivor Killed Hunter
#define SURVIVOR_K_SPITTER      4  // Surivivor Killed Spitter
#define SURVIVOR_K_JOCKEY       5  // Surivivor Killed Jockey
#define SURVIVOR_K_CHARGER      6  // Surivivor Killed Changer
#define SURVIVOR_K_WITCH        7  // Surivivor Killed Witch
#define SURVIVOR_K_TANK         8  // Surivivor Killed Tank

// Infected Kill Headshot
#define SURVIVOR_K_CI_HS        9  // Surivivor Killed Common Infected (Headshot)
#define SURVIVOR_K_SMOKER_HS    10 // Surivivor Killed Smoker (Headshot)
#define SURVIVOR_K_BOOMER_HS	11 // Surivivor Killed Boomer (Headshot)
#define SURVIVOR_K_HUNTER_HS    12 // Surivivor Killed Hunter (Headshot)
#define SURVIVOR_K_SPITTER_HS   13 // Surivivor Killed Spitter (Headshot)
#define SURVIVOR_K_JOCKEY_HS    14 // Surivivor Killed Jockey (Headshot)
#define SURVIVOR_K_CHARGER_HS   15 // Surivivor Killed Changer (Headshot)
#define SURVIVOR_K_WITCH_HS     16 // Surivivor Killed Witch (Headshot)
#define SURVIVOR_K_WITCH_OS     17 // Surivivor Killed Witch in one shot

// Gun statistic
#define SURVIVOR_K_SMG          18 // Surivivor killed CI/SI by SMG
#define SURVIVOR_K_SILENCED     19 // Surivivor killed CI/SI by SMG silenced
#define SURVIVOR_K_MP5          20 // Surivivor killed CI/SI by MP5
#define SURVIVOR_K_M16          21 // Surivivor killed CI/SI by RIFLE (M16)
#define SURVIVOR_K_DESERT       22 // Surivivor killed CI/SI by Desert
#define SURVIVOR_K_AK47         23 // Surivivor killed CI/SI by AK47
#define SURVIVOR_K_SG552        24 // Surivivor killed CI/SI by Sg552
#define SURVIVOR_K_M60          25 // Surivivor killed CI/SI by M60
#define SURVIVOR_K_HUNTING      26 // Surivivor killed CI/SI by Hunting
#define SURVIVOR_K_MILITARY     27 // Surivivor killed CI/SI by Military
#define SURVIVOR_K_AWP          28 // Surivivor killed CI/SI by Awp
#define SURVIVOR_K_SCOUT        29 // Surivivor killed CI/SI by Scout
#define SURVIVOR_K_PUMP         30 // Surivivor killed CI/SI by Pump
#define SURVIVOR_K_CHROME       31 // Surivivor killed CI/SI by CHROME
#define SURVIVOR_K_AUTO         32 // Surivivor killed CI/SI by Auto
#define SURVIVOR_K_SPAS         33 // Surivivor killed CI/SI by Spas
#define SURVIVOR_K_PISTOL       34 // Surivivor killed CI/SI by PISTOL
#define SURVIVOR_K_MAGNUM       35 // Surivivor killed CI/SI by Magnum
#define SURVIVOR_K_GL           36 // Surivivor killed CI/SI by Grenade Launcher
    
// Melee statistic
#define SURVIVOR_K_KATANA       37 // Surivivor killed CI/SI by Katana
#define SURVIVOR_K_AXE          38 // Surivivor killed CI/SI by Axe
#define SURVIVOR_K_MACHATE      39 // Surivivor killed CI/SI by Machete
#define SURVIVOR_K_KNIFE        40 // Surivivor killed CI/SI by Knife
#define SURVIVOR_K_SAW          41 // Surivivor killed CI/SI by Chainsaw
#define SURVIVOR_K_PITCHFORK    42 // Surivivor killed CI/SI by Pitchfork
#define SURVIVOR_K_SHOVEL       43 // Surivivor killed CI/SI by Shovel
#define SURVIVOR_K_GOLF         44 // Surivivor killed CI/SI by Golfclub
#define SURVIVOR_K_GUITAR       45 // Surivivor killed CI/SI by Guitar
#define SURVIVOR_K_TONFA        46 // Surivivor killed CI/SI by tonfa
#define SURVIVOR_K_BASEBALL     47 // Surivivor killed CI/SI by Baseball
#define SURVIVOR_K_CRICKET      48 // Surivivor killed CI/SI by Cricket
#define SURVIVOR_K_PAN          49 // Surivivor killed CI/SI by Pan
#define SURVIVOR_K_CROWBAR      50 // Surivivor killed CI/SI by Crowbar

// Other statistic
#define SURVIVOR_K_PIPE         51 // Surivivor killed CI/SI by Pipe
#define SURVIVOR_K_MOLOTOV      52 // Surivivor killed CI/SI by Molotov
#define SURVIVOR_K_NONE         53 // Surivivor killed CI/SI by none (e.g. Throwables)

#define SURVIVOR_PILLS          54 // Surivivor used Pills 
#define SURVIVOR_ADRENALINE     55 // Surivivor used Adrenaline 
#define SURVIVOR_MEDKIT         56 // Surivivor used Medikit 
#define SURVIVOR_HEALED         57 // Surivivor is healed by someone
#define SURVIVOR_SELF_HEALED    58 // Surivivor is healed by himself
#define SURVIVOR_HEAL           59 // Surivivor used Medikit for healing someone
#define SURVIVOR_DEFIBRILLATE   60 // Surivivor defibrillated someone
#define SURVIVOR_DEFIBRILLATED  61 // Surivivor is defibrillated by someone

#define SURVIVOR_TH_MOLOTOV     62 // Surivivor throwed Molotov
#define SURVIVOR_TH_PIPE        63 // Surivivor throwed Pipe bomb
#define SURVIVOR_TH_VOMITJAR    64 // Surivivor throwed Vomitjar

// Survivor event
#define SURVIVOR_SHOT           65 // Amount of surivivor shot
#define SURVIVOR_HIT            66 // Amount of surivivor hit
#define SURVIVOR_REVIVE         67 // Surivivor revived someone
#define SURVIVOR_REVIVED        68 // Surivivor is revived by someone
#define SURVIVOR_HURT           69 // Amount of damage hurt
#define SURVIVOR_DMG            70 // Amount of damage made
#define SURVIVOR_TEAMKILL       71 // Amount of Team kill
#define SURVIVOR_KILL           72 // Amount of Killing infected (last hit)
#define SURVIVOR_INCAPACITATED  73 // Amount of surivivor incapacated
#define SURVIVOR_DEATH          74 // Amount of death of surivivor
    
// Infected event
#define INFECTED_HURT           75 // Amount of damage hurt
#define INFECTED_DMG            76 // Amount of damage made
#define INFECTED_KILL           77 // Amount of Killing Surivivor
#define INFECTED_INCAPACITATE   78 // Amount of Incapacitating Surivivor
#define INFECTED_DEATH          79 // Amount of death of infected

#define CODE_STATS_SIZE         80


#define STATE_LOADING           0
#define STATE_LOADED            1


#define IS_VALID_CLIENT(%1)     (%1 > 0 && %1 <= MaxClients)
#define IS_REAL_CLIENT(%1)      (IsClientInGame(%1) && !IsFakeClient(%1))
#define IS_VALID_INGAME(%1)     (IS_VALID_CLIENT(%1) && IsClientInGame(%1))

#define IS_SPECTATOR(%1)        (GetClientTeam(%1) == TEAM_SPECTATOR)
#define IS_SURVIVOR(%1)         (GetClientTeam(%1) == TEAM_SURVIVOR)
#define IS_INFECTED(%1)         (GetClientTeam(%1) == TEAM_INFECTED)

#define IS_VALID_SURVIVOR(%1)   (IS_VALID_CLIENT(%1) && IS_SURVIVOR(%1))
#define IS_VALID_INFECTED(%1)   (IS_VALID_CLIENT(%1) && IS_INFECTED(%1))


enum struct Player
{
	int id;
	char lastName[65];
	int playedTime;
	int rank;
	int stats[CODE_STATS_SIZE];
	int STATE;

	void AddStats(int iCode, int iValue)
	{
		this.stats[iCode] += iValue;
	}

	void AddPlayedTime(int iValue)
	{
		this.playedTime += iValue;
	}

	bool IsNew() {
		return this.id == 0;
	}

	void Clear()
	{
		this.id = 0;
		this.lastName[0] = '\0';
		this.playedTime = 0;
		this.rank = 0;
		this.STATE = STATE_LOADING;

		for (int iCode = 0; iCode < CODE_STATS_SIZE; iCode ++) 
		{
			this.stats[iCode] = 0;
		}
	}
}


Player
	g_pPlayers[MAXPLAYERS + 1],
	g_pClientViewPlayer[MAXPLAYERS + 1],
	g_pTopPlayers[6];

bool
	g_bLate = false,
	g_bReadyUpAvailable = false,
	g_bRoundIsLive = false,
	g_bFullTeam = false;

ConVar
	g_hGameMode = null,
	g_hSurvivorLimit = null,
	g_hMaxLastVisit,
	g_hMinRankedHours;

int
	g_iTop = 0,
	g_iSurvivorLimit = 0,
	g_iMinRankedHours = 0,
	g_iPlayedTimeStartAt[MAXPLAYERS + 1] = {0, ...},
	g_iClientPage[MAXPLAYERS + 1] = {0, ...};

StringMap
	g_tWeaponNames = null;


/**
  * Global event. Called when all plugins loaded.
  *
  * @noreturn
  */
public void OnAllPluginsLoaded() {
	g_bReadyUpAvailable = LibraryExists(LIB_READY);
}

/**
  * Global event. Called when a library is removed.
  *
  * @param sName     Library name
  *
  * @noreturn
  */
public void OnLibraryRemoved(const char[] sName) 
{
	if (StrEqual(sName, LIB_READY)) {
		g_bReadyUpAvailable = false;
	}
}

/**
  * Global event. Called when a library is added.
  *
  * @param sName     Library name
  *
  * @noreturn
  */
public void OnLibraryAdded(const char[] sName)
{
	if (StrEqual(sName, LIB_READY)) {
		g_bReadyUpAvailable = true;
	}
}

/**
  * @requared readyup
  * Global event. Called when all players are ready.
  *
  * @noreturn
  */
public void OnRoundIsLive() 
{
	g_bRoundIsLive = true;

	if (g_bFullTeam) {
		RunPlayedTime();
	}
}

/**
 * Called before OnPluginStart.
 * 
 * @param myself      Handle to the plugin
 * @param bLate       Whether or not the plugin was loaded "late" (after map load)
 * @param sErr        Error message buffer in case load failed
 * @param iErrLen     Maximum number of characters for error message buffer
 * @return            APLRes_Success | APLRes_SilentFailure 
 */
public APLRes AskPluginLoad2(Handle myself, bool bLate, char[] sErr, int iErrLen)
{
	g_bLate = bLate;

	EngineVersion engine = GetEngineVersion();

	if (engine != Engine_Left4Dead2) {
		strcopy(sErr, iErrLen, "Plugin only supports Left 4 Dead 2");
		return APLRes_SilentFailure;
	}


	return APLRes_Success;
}

/**
 * Called when the plugin is fully initialized and all known external references are resolved.
 * 
 * @noreturn
 */
public void OnPluginStart()
{
	InitTranslations();
	InitWeaponNamesTrie();
	InitEvents();
	InitCvars();
	InitDatabase();
	InitCmds();

	if (g_bLate) 
	{
		for (int iClient = 1; iClient <= MaxClients; iClient++) 
		{
			OnClientPostAdminCheck(iClient);
		}
	}
}

/**
 * Called when the plugin is about to be unloaded.
 * 
 * @noreturn
 */
public void OnPluginEnd()
{
	if (g_tWeaponNames != null) {
		delete g_tWeaponNames;
	}
}

/**
 * Loads dictionary files. On failure, stops the plugin execution.
 * 
 * @noreturn
 */
void InitTranslations()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, "translations/" ... TRANSLATIONS ... ".txt");

	if (FileExists(sPath)) {
		LoadTranslations(TRANSLATIONS);
	} 
	
	else {
		SetFailState("Path %s not found", sPath);
	}
}

void InitWeaponNamesTrie()
{
	char sWeaponNames[][] =
	{
		"", "pistol", "smg",
		"pumpshotgun", "autoshotgun", "rifle",
		"hunting_rifle", "smg_silenced", "shotgun_chrome",
		"rifle_desert", "sniper_military", "shotgun_spas",
		"", "", "",
		"", "", "",
		"", "melee", "chainsaw",
		"grenade_launcher", "", "",
		"", "", "rifle_ak47",
		"", "", "",
		"", "", "pistol_magnum",
		"smg_mp5", "rifle_sg552", "sniper_awp",
		"sniper_scout", "rifle_m60"
	};

	g_tWeaponNames = CreateTrie();

	for (int i = 0; i < sizeof(sWeaponNames); i++)
	{
		if (sWeaponNames[i][0] != '\0') {
			SetTrieValue(g_tWeaponNames, sWeaponNames[i], i);
		}
	}
}

/**
 * Fragment.
 * 
 * @noreturn
 */
void InitEvents() 
{
	HookEvent("versus_round_start",		Event_RoundStart);
	HookEvent("round_end",			Event_RoundEnd);
	HookEvent("player_changename",		Event_ChangeName, EventHookMode_Post);
	HookEvent("player_team",		Event_PlayerTeam, EventHookMode_Post);

	HookEvent("player_incapacitated",	Event_PlayerIncapacitated);
	HookEvent("pills_used",			Event_PillsUsed);
	HookEvent("adrenaline_used",		Event_AdrenalineUsed);
	HookEvent("heal_success",		Event_HealSuccess);
	HookEvent("defibrillator_used",		Event_DefibrillatorUsed);
	HookEvent("revive_success",		Event_ReviveSuccess);
	HookEvent("weapon_fire",		Event_WeaponFire, EventHookMode_Post);
	HookEvent("infected_death",		Event_InfectedDeath);
	HookEvent("witch_killed",		Event_WitchKilled);
	HookEvent("player_death",		Event_PlayerDeath);
	HookEvent("player_hurt",		Event_PlayerHurt);
}

/**
  * Round start event.
  *
  * @params  				see events.inc > HookEvent.
  *
  * @noreturn
  */
public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast) 
{
	if (!g_bReadyUpAvailable)
	{
		g_bRoundIsLive = true;

		if (g_bFullTeam) {
			RunPlayedTime();
		}
	}

	for (int iClient = 1; iClient <= MaxClients; iClient++) 
	{
		if (!IS_REAL_CLIENT(iClient)) {
			continue;
		}

		// Update rank (async)
		UpdatePlayerRank(iClient);
	}

	// Update top (sync)
	Database db = ConnectDatabase();
	LoadTopPlayers(db);
	delete db;

	return Plugin_Continue;
}

/**
 * Round end event.
 */
public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) 
{
	if (g_bRoundIsLive)
	{
		g_bRoundIsLive = false;

		StopPlayedTime();

		for (int iClient = 1; iClient <= MaxClients; iClient++) 
		{
			if (!IS_REAL_CLIENT(iClient)) {
				continue;
			}

			SavePlayerData(iClient);
		}
	}
	

	return Plugin_Continue;
}

/**
 * Player change his name.
 */
public Action Event_ChangeName(Event event, char[] event_name, bool dontBroadcast)
{
	int iClient = GetClientOfUserId(event.GetInt("userid"));

	if (!IS_VALID_CLIENT(iClient) || !IS_REAL_CLIENT(iClient)) {
		return Plugin_Continue;
	}

	char sNewName[32];
	event.GetString("newname", sNewName, sizeof(sNewName));

	Database db = ConnectDatabase();
	SQL_EscapeString(db, sNewName, g_pPlayers[iClient].lastName,  sizeof(g_pPlayers[].lastName));
	delete db;

	return Plugin_Continue;
}

/**
 * Player change his team.
 */
public Action Event_PlayerTeam(Event event, char[] event_name, bool dontBroadcast)
{
	int iClient = GetClientOfUserId(event.GetInt("userid"));

	if (IS_REAL_CLIENT(iClient))
	{
		int iOldTeam = event.GetInt("oldteam");
		int iNewTeam = event.GetInt("team");

		if (iOldTeam == TEAM_NONE && iNewTeam == TEAM_SPECTATOR) {
			return Plugin_Continue;
		}

		CreateTimer(0.1, Timer_PlayerTeam, .flags = TIMER_FLAG_NO_MAPCHANGE);
	}

	return Plugin_Continue;
}

public Action Timer_PlayerTeam(Handle hTimer)
{
	bool bFullTeamBeforeCheck = g_bFullTeam;
	g_bFullTeam = (g_iSurvivorLimit * 2) == GetPlayerCount();

	if (g_bRoundIsLive)
	{
		if (bFullTeamBeforeCheck == false && g_bFullTeam == true) {
			RunPlayedTime();
		}

		else if (bFullTeamBeforeCheck == true && g_bFullTeam == false) {
			StopPlayedTime();
		}
	}

	return Plugin_Stop;
}

/**
 * Survivor shoots.
 */
public Action Event_WeaponFire(Event event, char[] event_name, bool dontBroadcast)
{
	if (CanRecordStats() == false) {
		return Plugin_Continue;
	}

	int iClient = GetClientOfUserId(event.GetInt("userid"));

	char sWeaponName[32];
	event.GetString("weapon", sWeaponName, sizeof(sWeaponName));
	
	if (StrEqual(sWeaponName, "molotov", false)) {
		g_pPlayers[iClient].AddStats(SURVIVOR_TH_MOLOTOV, 1);
	}

	else if (StrEqual(sWeaponName, "pipe_bomb", false)) {
		g_pPlayers[iClient].AddStats(SURVIVOR_TH_PIPE, 1);
	}

	else if (StrEqual(sWeaponName, "vomitjar", false)) {
		g_pPlayers[iClient].AddStats(SURVIVOR_TH_VOMITJAR, 1);
	}

	if (g_tWeaponNames.ContainsKey(sWeaponName)) {
		g_pPlayers[iClient].AddStats(SURVIVOR_SHOT, 1);
	}

	return Plugin_Continue;
}

/**
 * The survivor has become incapacitated.
 */
public Action Event_PlayerIncapacitated(Event event, char[] event_name, bool dontBroadcast)
{
	if (CanRecordStats() == false) {
		return Plugin_Continue;
	}

	int iVictim = GetClientOfUserId(event.GetInt("userid"));
	int iAttacker = GetClientOfUserId(event.GetInt("attacker"));

	g_pPlayers[iVictim].AddStats(SURVIVOR_INCAPACITATED, 1);
	g_pPlayers[iAttacker].AddStats(INFECTED_INCAPACITATE, 1);

	return Plugin_Continue;
}

/**
 * Surivivor used Pills.
 */
public Action Event_PillsUsed(Event event, char[] event_name, bool dontBroadcast)
{
	if (CanRecordStats() == false) {
		return Plugin_Continue;
	}

	int iClient = GetClientOfUserId(event.GetInt("userid"));

	g_pPlayers[iClient].AddStats(SURVIVOR_PILLS, 1);

	return Plugin_Continue;
}


/**
 * Surivivor used Adrenaline.
 */
public Action Event_AdrenalineUsed(Event event, char[] event_name, bool dontBroadcast)
{
	if (CanRecordStats() == false) {
		return Plugin_Continue;
	}

	int iClient = GetClientOfUserId(event.GetInt("userid"));

	g_pPlayers[iClient].AddStats(SURVIVOR_ADRENALINE, 1);

	return Plugin_Continue;
}

/**
 * Survivor has been cured.
 */
public Action Event_HealSuccess(Event event, char[] event_name, bool dontBroadcast)
{
	if (CanRecordStats() == false) {
		return Plugin_Continue;
	}

	int iClient = GetClientOfUserId(event.GetInt("userid"));
	int iTarget = GetClientOfUserId(event.GetInt("subject"));

	g_pPlayers[iClient].AddStats(SURVIVOR_MEDKIT, 1);

	if (iClient != iTarget) {
		g_pPlayers[iClient].AddStats(SURVIVOR_HEAL, 1);
		g_pPlayers[iTarget].AddStats(SURVIVOR_HEALED, 1);
	} else {
		g_pPlayers[iClient].AddStats(SURVIVOR_SELF_HEALED, 1);
	}

	return Plugin_Continue;
}

/**
 * Surivivor used Defibrillator.
 */
public Action Event_DefibrillatorUsed(Event event, char[] event_name, bool dontBroadcast)
{
	if (CanRecordStats() == false) {
		return Plugin_Continue;
	}

	int iClient = GetClientOfUserId(event.GetInt("userid"));
	int iTarget = GetClientOfUserId(event.GetInt("subject"));

	g_pPlayers[iClient].AddStats(SURVIVOR_DEFIBRILLATE, 1);
	g_pPlayers[iTarget].AddStats(SURVIVOR_DEFIBRILLATED, 1);

	return Plugin_Continue;
}

/**
 * Survivor has been revived.
 */
public Action Event_ReviveSuccess(Event event, char[] event_name, bool dontBroadcast)
{
	if (CanRecordStats() == false) {
		return Plugin_Continue;
	}

	int iClient = GetClientOfUserId(event.GetInt("userid"));
	int iTarget = GetClientOfUserId(event.GetInt("subject"));

	g_pPlayers[iClient].AddStats(SURVIVOR_REVIVE, 1);
	g_pPlayers[iTarget].AddStats(SURVIVOR_REVIVED, 1);

	return Plugin_Continue;
}

/**
 * Surivivor Killed Common Infected.
 */
public Action Event_InfectedDeath(Event event, char[] event_name, bool dontBroadcast)
{
	if (CanRecordStats() == false) {
		return Plugin_Continue;
	}

	int iKiller = GetClientOfUserId(event.GetInt("attacker"));

	if (!IS_VALID_SURVIVOR(iKiller)) {
		return Plugin_Continue;
	}

	int iWeaponId = event.GetInt("weapon_id");

	AddWeaponKill(iKiller, iWeaponId);

	bool bHeadShot = event.GetBool("headshot");

	g_pPlayers[iKiller].AddStats(bHeadShot ? SURVIVOR_K_CI_HS : SURVIVOR_K_CI, 1);

	return Plugin_Continue;
}

/**
 * Surivivor Killed Witch in one shot.
 */
public Action Event_WitchKilled(Event event, char[] event_name, bool dontBroadcast)
{
	if (CanRecordStats() == false) {
		return Plugin_Continue;
	}

	int iKiller = GetClientOfUserId(event.GetInt("attacker"));

	if (!IS_VALID_SURVIVOR(iKiller)) {
		return Plugin_Continue;
	}

	bool bOneShot = event.GetBool("oneshot");

	if (bOneShot) {
		g_pPlayers[iKiller].AddStats(SURVIVOR_K_WITCH_OS, 1);
	}
	
	return Plugin_Continue;
}

/**
 * Registers murder/death. Support all playable classes (Hunter, Smoker, Boomer, Tank, Survivors).
 */
public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) 
{
	if (CanRecordStats() == false) {
		return Plugin_Continue;
	}

	int iVictim = GetClientOfUserId(event.GetInt("userid"));
	int iKiller = GetClientOfUserId(event.GetInt("attacker"));

	if (IS_VALID_INFECTED(iVictim)) {
		g_pPlayers[iVictim].AddStats(INFECTED_DEATH, 1);
	}
	
	else if (IS_VALID_SURVIVOR(iVictim)) {
		g_pPlayers[iVictim].AddStats(SURVIVOR_DEATH, 1);
	}

	if (IS_VALID_SURVIVOR(iVictim) && IS_VALID_SURVIVOR(iKiller)) {
		g_pPlayers[iVictim].AddStats(SURVIVOR_TEAMKILL, 1);
	}

	else if (IS_VALID_SURVIVOR(iKiller) && IS_VALID_INFECTED(iVictim))
	{
		char sWeaponName[32];
		event.GetString("weapon", sWeaponName, sizeof(sWeaponName));
		
		int iWeaponId;
		g_tWeaponNames.GetValue(sWeaponName, iWeaponId);

		AddWeaponKill(iKiller, iWeaponId);
		
		bool bHeadShot = event.GetBool("headshot");
		int zClass = GetEntProp(iVictim, Prop_Send, "m_zombieClass");

		g_pPlayers[iKiller].AddStats(GetKillCodeByZC(zClass, bHeadShot), 1);
		
		g_pPlayers[iKiller].AddStats(SURVIVOR_KILL, 1);
	}

	else if(IS_VALID_INFECTED(iKiller) && IS_VALID_SURVIVOR(iVictim))
	{
		g_pPlayers[iVictim].AddStats(INFECTED_KILL, 1);
	}

	return Plugin_Continue;
}

/**
 * Registers existing/caused damage.
 */
public Action Event_PlayerHurt(Event event, char[] event_name, bool dontBroadcast)
{
	if (CanRecordStats() == false) {
		return Plugin_Continue;
	}

	int iVictim = GetClientOfUserId(event.GetInt("userid"));
	int iAttacker = GetClientOfUserId(event.GetInt("attacker"));
	int iDamage = event.GetInt("dmg_health");
	
	if (IS_VALID_SURVIVOR(iVictim) && IS_VALID_INFECTED(iAttacker)) 
	{
		g_pPlayers[iAttacker].AddStats(INFECTED_DMG, iDamage);
		g_pPlayers[iVictim].AddStats(SURVIVOR_HURT, iDamage);
	}

	else if (IS_VALID_SURVIVOR(iAttacker) && IS_VALID_INFECTED(iVictim))
	{
		g_pPlayers[iAttacker].AddStats(SURVIVOR_HIT, 1);

		g_pPlayers[iVictim].AddStats(INFECTED_HURT, iDamage);
 
		if (iDamage < 5000) { // hack
			g_pPlayers[iAttacker].AddStats(SURVIVOR_DMG, iDamage);
		}
	}

	return Plugin_Continue;
}

/**
 * Fragment
 * 
 * @noreturn
 */
void InitCvars()
{
	g_hGameMode = FindConVar("mp_gamemode");
	g_hGameMode.AddChangeHook(OnGamemodeChanged);

	g_hSurvivorLimit = FindConVar("survivor_limit");
	g_hSurvivorLimit.AddChangeHook(OnSurvivorLimitChanged);
	g_iSurvivorLimit = g_hSurvivorLimit.IntValue;

	g_hMaxLastVisit = CreateConVar("vs_max_last_visit", "2592000", "The maximum time since the last visit that a record will be found in the database", FCVAR_NOTIFY);

	g_hMinRankedHours = CreateConVar("vs_min_ranked_hours", "1", "Minimum number of hours to display player statistics", FCVAR_NOTIFY);
	g_hMinRankedHours.AddChangeHook(OnMinRankedHoursChanged);
	g_iMinRankedHours = g_hMinRankedHours.IntValue;

	AutoExecConfig(true, AUTO_EXEC_CONFIG);
}

/**
 * Called when a console variable value is changed.
 * 
 * @param convar       Handle to the convar that was changed
 * @param sOldGameMode String containing the value of the convar before it was changed
 * @param sNewGameMode String containing the new value of the convar
 * @noreturn
 */
public void OnGamemodeChanged(ConVar convar, const char[] sOldGameMode, const char[] sNewGameMode) {
	CheckGameMode(sNewGameMode);
}

/**
 * @param hConVar      Handle to the convar that was changed
 * @param sOldLimit    String containing the value of the convar before it was changed
 * @param sNewLimit    String containing the new value of the convar
 * @noreturn
 */
public void OnSurvivorLimitChanged(ConVar hConVar, const char[] sOldLimit, const char[] sNewLimit) {
	g_iSurvivorLimit = hConVar.IntValue;
}

/**
 * @param hConVar      Handle to the convar that was changed
 * @param sOldLimit    String containing the value of the convar before it was changed
 * @param sNewLimit    String containing the new value of the convar
 * @noreturn
 */
public void OnMinRankedHoursChanged(ConVar hConVar, const char[] sOldValue, const char[] sNewValue) {
	g_iMinRankedHours = hConVar.IntValue;
}

/**
 * Called when the map has loaded, servercfgfile (server.cfg) has been executed, and all plugin configs are done executing.
 * This will always be called once and only once per map. It will be called after OnMapStart().
 * 
 * @noreturn
*/
public void OnConfigsExecuted() 
{
	char sGameMode[16];
	GetConVarString(g_hGameMode, sGameMode, sizeof(sGameMode));
	CheckGameMode(sGameMode);
}

/**
 * Fragment.
 * 
 * @noreturn
 */
void CheckGameMode(const char[] sGameMode)
{
	if (StrContains(sGameMode, GAMEMODE_VERSUS, false) == -1) {
		SetFailState("Unsupported mode %s.", sGameMode);
	}
}

/**
 * Fragment.
 * 
 * @noreturn
 */
void InitDatabase()
{
	Database db = ConnectDatabase();

	if (CheckDatabaseDriver(db) == false) {
		SetFailState("Unsupported database driver.");
	}

	if (CreateTable(db) == false) {
		SetFailState("Create tables failure.");
	}

	LoadTopPlayers(db);

	ClearDatabase(db);

	delete db;
}

/**
 * Called once a client is authorized and fully in-game, and after all post-connection authorizations have been performed.
 * 
 * @noreturn
*/
public void OnClientPostAdminCheck(int iClient) 
{
	if (IS_REAL_CLIENT(iClient)) 
	{
		g_pPlayers[iClient].Clear();
		LoadPlayerData(iClient);
	}
}

/**
 * Called before client disconnected.
 * 
 * @param iClient     Client index
 * @noreturn
 */
public void OnClientDisconnect(int iClient)
{
	if (IS_REAL_CLIENT(iClient))
	{
		BreakPlayedTime(iClient, GetTime());
		SavePlayerData(iClient);
	}
}

/**
 * Fragment.
 * 
 * @noreturn
 */
void InitCmds()
{
	RegConsoleCmd("sm_top",		Cmd_ShowTop);
	RegConsoleCmd("sm_rank",	Cmd_ShowRank);
	RegConsoleCmd("sm_rankstats",	Cmd_ShowRankStats);
}

public Action Cmd_ShowTop(int iClient, int iArgs)
{
	if (IS_VALID_CLIENT(iClient)) {
		Top(iClient);
	}

	return Plugin_Handled;
}

public Action Cmd_ShowRank(int iClient, int iArgs)
{
	if (IS_VALID_CLIENT(iClient))
	{
		if (g_pPlayers[iClient].rank > 0) {
			CPrintToChat(iClient, "%T", "RANK", iClient, g_pPlayers[iClient].rank);
		}

		else {
			CPrintToChat(iClient, "%T", "WITHOUT_RANK", iClient, (float(g_iMinRankedHours) - SecToHours(g_pPlayers[iClient].playedTime)));
		}
	}

	return Plugin_Handled;
}

public Action Cmd_ShowRankStats(int iClient, int iArgs)
{
	if (IS_VALID_CLIENT(iClient))
	{
		int iTarget = iClient;

		if (iArgs > 0)
		{
			char sArg[32];
			GetCmdArg(1, sArg, sizeof(sArg));

			iTarget = FindOneTarget(iClient, sArg);

			if (iTarget == -1)
			{
				CPrintToChat(iClient, "%T", "RANKSTATS_BAD_ARG", iClient, sArg);
				return Plugin_Handled;
			}
		}

		g_pClientViewPlayer[iClient] = g_pPlayers[iTarget];
		RankStats(iClient, g_pClientViewPlayer[iClient], g_iClientPage[iClient] = 0);
	}

	return Plugin_Handled;
}

void Top(int iClient) 
{
	Panel hPanel = new Panel();

	char sTemp[128];

	if (g_iTop) 
	{
		Format(sTemp, sizeof(sTemp), "%T", "TOP_TITLE", iClient, g_iTop);
		hPanel.SetTitle(sTemp);
		hPanel.DrawText(" ");

		for (int i = 0; i < g_iTop; i++)
		{
			hPanel.DrawItem(g_pTopPlayers[i].lastName);

			Format(sTemp, sizeof(sTemp), "%T", "TOP_ITEM", iClient, SecToHours(g_pTopPlayers[i].playedTime), CalculateEfficiency(g_pTopPlayers[i]));
			hPanel.DrawText(sTemp);
		}
	}

	else 
	{
		Format(sTemp, sizeof(sTemp), "%T", "NOT_FOUND", iClient);
		hPanel.DrawText(sTemp);
	}

	hPanel.DrawText(" ");

	Format(sTemp, sizeof(sTemp), "%T", "CLOSE", iClient);
	hPanel.DrawItem(sTemp, ITEMDRAW_CONTROL);

	hPanel.Send(iClient, HandleTop, MENU_TIME_FOREVER);

	delete hPanel;
}

public int HandleTop(Menu hMenu, MenuAction action, int iClient, int iSelectedIndex)
{
	if (action == MenuAction_Select && iSelectedIndex <= g_iTop)
	{
		g_pClientViewPlayer[iClient] = g_pTopPlayers[-- iSelectedIndex];
		RankStats(iClient, g_pClientViewPlayer[iClient], g_iClientPage[iClient] = 0);
	}

	return 0;
}

void RankStats(int iClient, Player pViewPlayer, int iPage) 
{
	Panel hPanel = new Panel();

	char sTemp[128];

	Format(sTemp, sizeof(sTemp), "%T", "RANKSTATS_TITLE", iClient, pViewPlayer.rank, pViewPlayer.lastName, SecToHours(pViewPlayer.playedTime), CalculateEfficiency(pViewPlayer));
	hPanel.SetTitle(sTemp);
	hPanel.DrawText(" ");

	int iStart = iPage * PER_PAGE;
	int iEnd = (iPage + 1) * PER_PAGE;
	int iSpace = 0;

	if (iEnd > CODE_STATS_SIZE)
	{
		iSpace = iEnd - CODE_STATS_SIZE;
		iEnd = CODE_STATS_SIZE;
	}

	char sPattern[16];
	for (int iStats = iStart; iStats < iEnd; iStats++)
	{
		Format(sPattern, sizeof(sPattern), "CODE_STATS_%d", iStats);
		Format(sTemp, sizeof(sTemp), "%T", sPattern, iClient, pViewPlayer.stats[iStats]);
		hPanel.DrawText(sTemp);
	}
	
	for (int i = 0; i < iSpace; i++)
	{
		hPanel.DrawText(" ");
	}

	hPanel.DrawText(" ");

	Format(sTemp, sizeof(sTemp), "%T", "NEXT", iClient);
	hPanel.DrawItem(sTemp, iEnd < CODE_STATS_SIZE ? ITEMDRAW_CONTROL : ITEMDRAW_DISABLED);

	if (iPage == 0) {
		Format(sTemp, sizeof(sTemp), "%T", "CLOSE", iClient);
		hPanel.DrawItem(sTemp, ITEMDRAW_CONTROL);
	} else {
		Format(sTemp, sizeof(sTemp), "%T", "BACK", iClient);
		hPanel.DrawItem(sTemp, ITEMDRAW_CONTROL);
	}

	hPanel.Send(iClient, HandleRankStats, MENU_TIME_FOREVER);

	delete hPanel;
}

public int HandleRankStats(Menu hMenu, MenuAction action, int iClient, int iSelectedIndex)
{
	if (action == MenuAction_Select)
	{
		switch (iSelectedIndex) 
		{
			case 1: {
				if (++ g_iClientPage[iClient] * PER_PAGE < CODE_STATS_SIZE) {
					RankStats(iClient, g_pClientViewPlayer[iClient], g_iClientPage[iClient]);
				}
			}

			case 2: {
				if (-- g_iClientPage[iClient] >= 0) {
					RankStats(iClient, g_pClientViewPlayer[iClient], g_iClientPage[iClient]);
				}
			}
		}
	}

	return 0;
}

void BreakPlayedTime(int iClient, int iBreakTime)
{
	if (g_iPlayedTimeStartAt[iClient] > 0)
	{
		g_pPlayers[iClient].AddPlayedTime(iBreakTime - g_iPlayedTimeStartAt[iClient]);
		g_iPlayedTimeStartAt[iClient] = 0;
	}
}

void RunPlayedTime()
{
	int iTime = GetTime();
	
	for (int iClient = 1; iClient <= MaxClients; iClient++) 
	{
		if (!IS_REAL_CLIENT(iClient) || IS_SPECTATOR(iClient)) {
			continue;
		}

		g_iPlayedTimeStartAt[iClient] = iTime;
	}
}

void StopPlayedTime()
{
	int iTime = GetTime();

	for (int iClient = 1; iClient <= MaxClients; iClient++) 
	{
		if (!IS_REAL_CLIENT(iClient)) {
			continue;
		}

		BreakPlayedTime(iClient, iTime);
	}
}

bool CanRecordStats() {
	return g_bRoundIsLive && g_bFullTeam;
}


Database ConnectDatabase()
{
	char error[255];
	Database db;
	
	if (SQL_CheckConfig(DATABASE)) {
		db = SQL_Connect(DATABASE, true, error, sizeof(error));
	}

	if (db == null) {
		LogError("Could not connect to database: %s", error);
	}
	
	return db;
}

bool CheckDatabaseDriver(Database db) 
{
	char ident[16];
	db.Driver.GetIdentifier(ident, sizeof(ident));

	if (StrEqual(ident, "mysql", false)) {
		return true;
	}

	return false;
}

bool CreateTable(Database db)
{
	char sStats[CREATE_CODE_STATS_TEMP_SIZE];
	char sStatsList[CODE_STATS_SIZE * CREATE_CODE_STATS_TEMP_SIZE];

	char sQuery[300 + sizeof(sStatsList)] = 
	"CREATE TABLE IF NOT EXISTS vs_players (\
	id int(10) UNSIGNED NOT NULL auto_increment,\
	last_name varchar(65) NOT NULL,\
	steam_id varchar(32) NOT NULL,\
	played_time int(10) UNSIGNED NOT NULL,\
	last_visit int(10) UNSIGNED NOT NULL,\
	efficiency float(10,3) UNSIGNED NOT NULL,\
	__STATS__ PRIMARY KEY (id));";

	for (int iCode = 0; iCode < CODE_STATS_SIZE; iCode ++) 
	{
		Format(sStats, sizeof(sStats), CREATE_CODE_STATS_TEMP, iCode);
		StrCat(sStatsList, sizeof(sStatsList), sStats);
	}

	ReplaceString(sQuery, sizeof(sQuery), "__STATS__", sStatsList, false);

	SQL_LockDatabase(db);

	if (!SQL_FastQuery(db, sQuery))
	{
		SQL_UnlockDatabase(db);
		return false;
	}

	SQL_UnlockDatabase(db);

	return true;
}

void LoadTopPlayers(Database db)
{
	char sQuery[128];
	Format(sQuery, sizeof(sQuery), "SELECT * FROM vs_players WHERE `played_time`>%d AND `efficiency`>0 ORDER BY `efficiency` DESC LIMIT 5;", HOUR * g_iMinRankedHours);

	SQL_LockDatabase(db);

	DBResultSet dbResult = SQL_Query(db, sQuery, sizeof(sQuery));

	if (dbResult != null)
	{
		int iPos = 0;
		int iColumnNum;

		while (SQL_FetchRow(dbResult))
		{
			if (SQL_FieldNameToNum(dbResult, "last_name", iColumnNum)) {
				SQL_FetchString(dbResult, iColumnNum, g_pTopPlayers[iPos].lastName, sizeof(g_pTopPlayers[].lastName));	
			}

			if (SQL_FieldNameToNum(dbResult, "played_time", iColumnNum)) {
				g_pTopPlayers[iPos].playedTime = SQL_FetchInt(dbResult, iColumnNum);
			}

			if (SQL_FieldNameToNum(dbResult, "code_stats_0", iColumnNum)) 
			{
				for (int iCode = 0; iCode < CODE_STATS_SIZE; iCode ++)
				{
					g_pTopPlayers[iPos].stats[iCode] = SQL_FetchInt(dbResult, iColumnNum + iCode);
				}
			}
			
			g_pTopPlayers[iPos].rank = ++ iPos;
		}

		g_iTop = iPos;

		delete dbResult;
	}

	else
	{
		char sError[255];
		SQL_GetError(db, sError, sizeof(sError));
		LogError("Failed to query: %s", sError);
	}

	SQL_UnlockDatabase(db);
}

void ClearDatabase(Database db)
{
	char sQuery[128];
	Format(sQuery, sizeof(sQuery), "DELETE FROM vs_players WHERE `last_visit`<%d;", (GetTime() - g_hMaxLastVisit.IntValue));

	SQL_LockDatabase(db);

	if (!SQL_FastQuery(db, sQuery))
	{
		char sError[255];
		SQL_GetError(db, sError, sizeof(sError));
		LogError("Failed to query: %s", sError);
	}

	SQL_UnlockDatabase(db);
}

void LoadPlayerData(int iClient) 
{
	char sSteamId[32];
	GetClientAuthId(iClient, AuthId_SteamID64, sSteamId, sizeof(sSteamId));

	char sQuery[256];
	Format(sQuery, sizeof(sQuery), "SELECT (SELECT count(1) FROM vs_players b WHERE  b.`efficiency` > a.`efficiency`)+1 as rank, a.* FROM vs_players a WHERE `steam_id`='%s' LIMIT 1;", sSteamId);

	Database db = ConnectDatabase();

	char sClientName[32];
	GetClientName(iClient, sClientName, sizeof(sClientName));
	SQL_EscapeString(db, sClientName, g_pPlayers[iClient].lastName,  sizeof(g_pPlayers[].lastName));

	SQL_TQuery(db, LoadPlayerThread, sQuery, iClient);
}

void LoadPlayerThread(Handle owner, Handle hndl, const char[] error, int iClient)
{
	if (hndl == null)
	{
		LogError("LoadPlayerThread failed! Reason: %s", error);
		return;
	}

	if (SQL_GetRowCount(hndl) > 0)
	{
		SQL_FetchRow(hndl);
	
		int iColumnNum;

		if (SQL_FieldNameToNum(hndl, "id", iColumnNum)) {
			g_pPlayers[iClient].id = SQL_FetchInt(hndl, iColumnNum);
		}

		if (SQL_FieldNameToNum(hndl, "played_time", iColumnNum)) 
		{
			g_pPlayers[iClient].playedTime = SQL_FetchInt(hndl, iColumnNum);

			if (g_pPlayers[iClient].playedTime > (HOUR * g_iMinRankedHours) && SQL_FieldNameToNum(hndl, "rank", iColumnNum)) {
				g_pPlayers[iClient].rank = SQL_FetchInt(hndl, iColumnNum); 
			}
		}

		if (SQL_FieldNameToNum(hndl, "code_stats_0", iColumnNum)) 
		{
			for (int iCode = 0; iCode < CODE_STATS_SIZE; iCode ++)
			{
				g_pPlayers[iClient].stats[iCode] = SQL_FetchInt(hndl, iColumnNum + iCode);
			}
		}
	}

	g_pPlayers[iClient].STATE = STATE_LOADED;
}

void SavePlayerData(int iClient) 
{
	if (g_pPlayers[iClient].STATE != STATE_LOADED) {
		return;
	}

	Database db = ConnectDatabase();

	if (g_pPlayers[iClient].IsNew() == false)
	{
		char sStats[UPDATE_CODE_STATS_TEMP_SIZE];
		char sStatsList[CODE_STATS_SIZE * UPDATE_CODE_STATS_TEMP_SIZE];

		char sQuery[256 + sizeof(sStatsList)];
		Format(sQuery, sizeof(sQuery), "UPDATE `vs_players` SET `last_name`='%s',`played_time`=%d,`last_visit`=%d,__STATS__`efficiency`=%f WHERE `id`=%d;", g_pPlayers[iClient].lastName, g_pPlayers[iClient].playedTime, GetTime(), CalculateEfficiency(g_pPlayers[iClient]), g_pPlayers[iClient].id);

		for (int iCode = 0; iCode < CODE_STATS_SIZE; iCode ++)
		{
			Format(sStats, sizeof(sStats), UPDATE_CODE_STATS_TEMP, iCode, g_pPlayers[iClient].stats[iCode]);
			StrCat(sStatsList, sizeof(sStatsList), sStats);
		}

		ReplaceString(sQuery, sizeof(sQuery), "__STATS__", sStatsList, false);
		SQL_TQuery(db, SavePlayerThread, sQuery, iClient);
	}

	else
	{
		char sSteamId[32];
		GetClientAuthId(iClient, AuthId_SteamID64, sSteamId, sizeof(sSteamId));

		char sStatsColumn[CODE_STATS_SIZE * INSERT_CODE_STATS_COLUMN_TEMP_SIZE];
		char sStatsColumnList[CODE_STATS_SIZE * INSERT_CODE_STATS_COLUMN_TEMP_SIZE];

		char sStatsValue[INSERT_CODE_STATS_VALUE_TEMP_SIZE];
		char sStatsValueList[CODE_STATS_SIZE * INSERT_CODE_STATS_VALUE_TEMP_SIZE];
 
		char sQuery[192 + sizeof(sStatsColumnList) + sizeof(sStatsValueList)];
		Format(sQuery, sizeof(sQuery), "INSERT INTO `vs_players` (`last_name`,`steam_id`,`played_time`,`last_visit`,__STATS_COLUMN__`efficiency`) VALUES ('%s','%s',%d,%d,__STATS_VALUE__%f);", g_pPlayers[iClient].lastName, sSteamId, g_pPlayers[iClient].playedTime, GetTime(), CalculateEfficiency(g_pPlayers[iClient]));

		for (int iCode = 0; iCode < CODE_STATS_SIZE; iCode ++) 
		{
			Format(sStatsColumn, sizeof(sStatsColumn), INSERT_CODE_STATS_COLUMN_TEMP, iCode);
			StrCat(sStatsColumnList, sizeof(sStatsColumnList), sStatsColumn);

			Format(sStatsValue, sizeof(sStatsValue), INSERT_CODE_STATS_VALUE_TEMP, g_pPlayers[iClient].stats[iCode]);
			StrCat(sStatsValueList, sizeof(sStatsValueList), sStatsValue);
		}

		ReplaceString(sQuery, sizeof(sQuery), "__STATS_COLUMN__", sStatsColumnList, false);
		ReplaceString(sQuery, sizeof(sQuery), "__STATS_VALUE__", sStatsValueList, false);

		SQL_TQuery(db, SavePlayerThread, sQuery, iClient);
	}
}

void SavePlayerThread(Handle owner, Handle hndl, const char[] error, int iClient)
{
	if (hndl == null) 
	{
		LogError("SavePlayerThread failed! Reason: %s", error);
		return;
	}

	if (g_pPlayers[iClient].IsNew()) {
		g_pPlayers[iClient].id = SQL_GetInsertId(hndl);
	}
}

void UpdatePlayerRank(int iClient) 
{
	if (g_pPlayers[iClient].STATE != STATE_LOADED || g_pPlayers[iClient].IsNew() || g_pPlayers[iClient].playedTime < (HOUR * g_iMinRankedHours)) {
		return;
	}

	char sQuery[192];
	Format(sQuery, sizeof(sQuery), "SELECT (SELECT count(1) FROM vs_players b WHERE b.`efficiency`>a.`efficiency`)+1 as rank FROM vs_players a WHERE `id`=%d LIMIT 1;", g_pPlayers[iClient].id);

	Database db = ConnectDatabase();

	SQL_TQuery(db, UpdatePlayerRankThread, sQuery, iClient);
}

void UpdatePlayerRankThread(Handle owner, Handle hndl, const char[] error, int iClient)
{
	if (hndl == null)
	{
		LogError("UpdatePlayerRankThread failed! Reason: %s", error);
		return;
	}

	if (SQL_GetRowCount(hndl) > 0)
	{
		SQL_FetchRow(hndl);

		g_pPlayers[iClient].rank = SQL_FetchInt(hndl, 0);
	}
}


/**
 * Helper.
 */
void AddWeaponKill(int iClient, int iWeaponId)
{
	if (iWeaponId != WID_MELEE) {
		g_pPlayers[iClient].AddStats(GetKillCodeByWeaponId(iWeaponId), 1);
	}
	
	else
	{
		char sMeleeName[32];
		int entity = GetPlayerWeaponSlot(iClient, 1);
		GetEntPropString(entity, Prop_Data, "m_strMapSetScriptName", sMeleeName, sizeof(sMeleeName));

		g_pPlayers[iClient].AddStats(GetKillCodeByMeleeName(sMeleeName), 1);
	}
}

float CalculateEfficiency(Player pTargetPlayer) 
{
	float fPlayedHours = SecToHours(pTargetPlayer.playedTime);

	if (fPlayedHours < float(g_iMinRankedHours)) {
		return 0.0;
	}

	float fPositive = float(pTargetPlayer.stats[SURVIVOR_KILL] + pTargetPlayer.stats[INFECTED_INCAPACITATE] * 4 + pTargetPlayer.stats[INFECTED_KILL] * 4);
	float fNegative = float(pTargetPlayer.stats[SURVIVOR_DEATH] * 4 + pTargetPlayer.stats[SURVIVOR_INCAPACITATED] * 2 + pTargetPlayer.stats[SURVIVOR_TEAMKILL]);
	float fEfficiency = (fPositive - fNegative) / (fPlayedHours + 1);

	return fEfficiency > 0.0 ? fEfficiency : 0.0;
}

float SecToHours(int seconds)
{
	return float(seconds) / float(HOUR);
}

/**
 * Helper.
 */
int GetKillCodeByWeaponId(int iWeponId)
{
	switch (iWeponId) 
	{
		case WID_PISTOL: return SURVIVOR_K_PISTOL;
		case WID_SMG: return SURVIVOR_K_SMG;
		case WID_PUMP: return SURVIVOR_K_PUMP;
		case WID_AUTO: return SURVIVOR_K_AUTO;
		case WID_M16: return SURVIVOR_K_M16;
		case WID_HUNTING: return SURVIVOR_K_HUNTING;
		case WID_SILENCED: return SURVIVOR_K_SILENCED;
		case WID_CHROME: return SURVIVOR_K_CHROME;
		case WID_DESERT: return SURVIVOR_K_DESERT;
		case WID_MILITARY: return SURVIVOR_K_MILITARY;
		case WID_SPAS: return SURVIVOR_K_SPAS;
		case WID_MOLOTOV: return SURVIVOR_K_MOLOTOV;
		case WID_PIPE: return SURVIVOR_K_PIPE;
		case WID_SAW: return SURVIVOR_K_SAW;
		case WID_GL: return SURVIVOR_K_GL;
		case WID_AK47: return SURVIVOR_K_AK47;
		case WID_MAGNUM: return SURVIVOR_K_MAGNUM;
		case WID_MP5: return SURVIVOR_K_MP5;
		case WID_SG552: return SURVIVOR_K_SG552;
		case WID_AWP: return SURVIVOR_K_AWP;
		case WID_SCOUT: return SURVIVOR_K_SCOUT;
		case WID_M60: return SURVIVOR_K_M60;
	}

	return SURVIVOR_K_NONE;
}

/**
 * Helper.
 */
int GetKillCodeByMeleeName(const char[] sMeleeName) 
{
	if (StrEqual(sMeleeName, "katana", false)) {
		return SURVIVOR_K_KATANA;
	}

	else if (StrEqual(sMeleeName, "fireaxe", false)) {
		return SURVIVOR_K_AXE;
	}
	
	else if (StrEqual(sMeleeName, "machete", false)) {
		return SURVIVOR_K_MACHATE;
	}

	else if (StrEqual(sMeleeName, "knife", false)) {
		return SURVIVOR_K_KNIFE;
	}

	else if (StrEqual(sMeleeName, "chainsaw", false)) {
		return SURVIVOR_K_SAW;
	}
	
	else if (StrEqual(sMeleeName, "pitchfork", false)) {
		return SURVIVOR_K_PITCHFORK;
	}
	
	else if (StrEqual(sMeleeName, "shovel", false)) {
		return SURVIVOR_K_SHOVEL;
	}

	else if (StrEqual(sMeleeName, "golfclub", false)) {
		return SURVIVOR_K_GOLF;
	}

	else if (StrEqual(sMeleeName, "electric_guitar", false)) {
		return SURVIVOR_K_GUITAR;
	}

	else if (StrEqual(sMeleeName, "tonfa", false)) {
		return SURVIVOR_K_TONFA;
	}

	else if (StrEqual(sMeleeName, "baseball_bat", false)) {
		return SURVIVOR_K_BASEBALL;
	}

	else if (StrEqual(sMeleeName, "cricket_bat", false)) {
		return SURVIVOR_K_CRICKET;
	}

	else if (StrEqual(sMeleeName, "frying_pan", false)) {
		return SURVIVOR_K_PAN;
	}

	else if (StrEqual(sMeleeName, "crowbar", false)) {
		return SURVIVOR_K_CROWBAR;
	}

	return SURVIVOR_K_NONE;
}

/**
 * Helper.
 */
int GetKillCodeByZC(int iZombieClass, bool bHeadShot) 
{
	switch(iZombieClass)
	{
		case ZC_SMOKER: return bHeadShot ? SURVIVOR_K_SMOKER_HS : SURVIVOR_K_SMOKER;
		case ZC_BOOMER: return bHeadShot ? SURVIVOR_K_BOOMER_HS : SURVIVOR_K_BOOMER;
		case ZC_HUNTER: return bHeadShot ? SURVIVOR_K_HUNTER_HS : SURVIVOR_K_HUNTER;
		case ZC_SPITTER: return bHeadShot ? SURVIVOR_K_SPITTER_HS : SURVIVOR_K_SPITTER;
		case ZC_JOCKEY: return bHeadShot ? SURVIVOR_K_JOCKEY_HS : SURVIVOR_K_JOCKEY;
		case ZC_CHARGER: return bHeadShot ? SURVIVOR_K_CHARGER_HS : SURVIVOR_K_CHARGER;
		case ZC_WITCH: return bHeadShot ? SURVIVOR_K_WITCH_HS : SURVIVOR_K_WITCH;
		case ZC_TANK: return SURVIVOR_K_TANK;
	}

	return bHeadShot ? SURVIVOR_K_CI_HS : SURVIVOR_K_CI;
}

/*
 * Returns the number of players on the survivors and infected teams.
 */
int GetPlayerCount()
{
	int iCount = 0;

	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (!IS_REAL_CLIENT(iClient) || IS_SPECTATOR(iClient)) {
			continue;
		}

		iCount++;
	}

	return iCount;
}

/*
 * Returns the player that was found by the request.
 */
int FindOneTarget(int iClient, const char[] sTarget)
{
	char iTargetName[MAX_TARGET_LENGTH];
	int iTargetList[1];
	bool isMl;
	
	if (ProcessTargetString(
			sTarget,
			iClient, 
			iTargetList, 
			1, 
			COMMAND_FILTER_CONNECTED|COMMAND_FILTER_NO_IMMUNITY|COMMAND_FILTER_NO_MULTI|COMMAND_FILTER_NO_BOTS,
			iTargetName,
			sizeof(iTargetName),
			isMl) > 0)
	{
		return iTargetList[0];
	}

	return -1;
}
