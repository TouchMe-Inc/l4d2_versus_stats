#pragma semicolon               1
#pragma newdecls                required

#include <sourcemod>
#include <sdktools>
#include <colors>

#undef REQUIRE_PLUGIN
#include <readyup>
#define LIB_READY               "readyup"

#include "include/versus_stats.inc"


public Plugin myinfo = { 
	name = "VersusStats",
	author = "TouchMe",
	description = "Versus mode statistics",
	version = VERSUS_STATS_VERSION
};


// Team
#define TEAM_NONE               0
#define TEAM_SPECTATOR          1
#define TEAM_SURVIVOR           2
#define TEAM_INFECTED           3

// Zombie class
#define ZC_SMOKER               1
#define ZC_BOOMER               2
#define ZC_HUNTER               3
#define ZC_SPITTER              4
#define ZC_JOCKEY               5
#define ZC_CHARGER              6
#define ZC_WITCH                7
#define ZC_TANK                 8

// SQL Fragment
#define CREATE_CODE_STATS_TEMP         "code_stats_%d int(11) UNSIGNED NOT NULL DEFAULT 0,"
#define CREATE_CODE_STATS_TEMP_SIZE    53
#define UPDATE_CODE_STATS_TEMP         "`code_stats_%d`=%d,"
#define UPDATE_CODE_STATS_TEMP_SIZE    30
#define INSERT_CODE_STATS_COLUMN_TEMP  "code_stats_%d,"
#define INSERT_CODE_STATS_COLUMN_TEMP_SIZE 16
#define INSERT_CODE_STATS_VALUE_TEMP   "%d,"
#define INSERT_CODE_STATS_VALUE_TEMP_SIZE 12

// Weapon id
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

// Other
#define HOUR                    3600
#define LIB_VERSUS_STATS        "versus_stats"

// Macros
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
}


Player
	g_pPlayers[MAXPLAYERS + 1];

bool
	g_bLate = false,
	g_bReadyUpAvailable = false,
	g_bRoundIsLive = false,
	g_bFullTeam = false;

ConVar
	g_hGameMode = null,
	g_hSurvivorLimit = null,
	g_hMaxLastVisit = null,
	g_hMinRankedHours = null;

int
	g_iSurvivorLimit = 4,
	g_iPlayedTimeStartAt[MAXPLAYERS + 1] = {0, ...};

float
	g_fMinRankedHours = 0.0;

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
	EngineVersion engine = GetEngineVersion();

	if (engine != Engine_Left4Dead2) {
		strcopy(sErr, iErrLen, "Plugin only supports Left 4 Dead 2");
		return APLRes_SilentFailure;
	}

	g_bLate = bLate;

	InitNatives();
	RegPluginLibrary(LIB_VERSUS_STATS);

	return APLRes_Success;
}

void InitNatives()
{
	CreateNative("GetClientRank", Native_GetClientRank);
	CreateNative("GetClientRating", Native_GetClientRating);
	CreateNative("GetClientStats", Native_GetClientStats);
	CreateNative("GetClientPlayedTime", Native_GetClientPlayedTime);
	CreateNative("GetClientState", Native_GetClientState);
	CreateNative("GetMinRankedHours", Native_GetMinRankedHours);
}

int Native_GetClientRank(Handle plugin, int numParams)
{
	int iClient = GetNativeCell(1);
	return g_pPlayers[iClient].rank;
}

any Native_GetClientRating(Handle plugin, int numParams)
{
	int iClient = GetNativeCell(1);
	return CalculateRating(g_pPlayers[iClient]);
}

int Native_GetClientStats(Handle plugin, int numParams)
{
	int iClient = GetNativeCell(1), iCode = GetNativeCell(2);
	return g_pPlayers[iClient].stats[iCode];
}

int Native_GetClientPlayedTime(Handle plugin, int numParams)
{
	int iClient = GetNativeCell(1);
	return g_pPlayers[iClient].playedTime;
}

int Native_GetClientState(Handle plugin, int numParams)
{
	int iClient = GetNativeCell(1);
	return g_pPlayers[iClient].STATE;
}

any Native_GetMinRankedHours(Handle plugin, int numParams)
{
	return g_fMinRankedHours;
}

/**
 * Called when the plugin is fully initialized and all known external references are resolved.
 * 
 * @noreturn
 */
public void OnPluginStart()
{
	InitWeaponNamesTrie();
	InitCvars();
	InitEvents();
	InitDatabase();

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
	HookEvent("player_changename",		Event_ChangeName);
	HookEvent("player_team",		Event_PlayerTeam);

	HookEvent("player_incapacitated",	Event_PlayerIncapacitated);
	HookEvent("pills_used",			Event_PillsUsed);
	HookEvent("adrenaline_used",		Event_AdrenalineUsed);
	HookEvent("heal_success",		Event_HealSuccess);
	HookEvent("defibrillator_used",		Event_DefibrillatorUsed);
	HookEvent("revive_success",		Event_ReviveSuccess);
	HookEvent("weapon_fire",		Event_WeaponFire);
	HookEvent("infected_death",		Event_InfectedDeath);
	HookEvent("witch_killed",		Event_WitchKilled);
	HookEvent("tank_spawn",		Event_TankSpawn);
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

	if (sWeaponName[0] != 'm' && g_tWeaponNames.ContainsKey(sWeaponName)) {
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

	if (iClient != iTarget)
	{
		g_pPlayers[iClient].AddStats(SURVIVOR_HEAL, 1);
		g_pPlayers[iTarget].AddStats(SURVIVOR_HEALED, 1);
	}
	
	else {
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
	
	g_pPlayers[iKiller].AddStats(SURVIVOR_K_CI, 1);

	bool bHeadShot = event.GetBool("headshot");

	if (bHeadShot) {
		g_pPlayers[iKiller].AddStats(SURVIVOR_K_CI_HS, 1);
	}

	return Plugin_Continue;
}

/**
 * Surivivor Killed Witch.
 */
public Action Event_WitchKilled(Event event, char[] event_name, bool dontBroadcast)
{
	if (CanRecordStats() == false) {
		return Plugin_Continue;
	}

	int iKiller = GetClientOfUserId(event.GetInt("userid"));

	if (!IS_VALID_SURVIVOR(iKiller)) {
		return Plugin_Continue;
	}

	g_pPlayers[iKiller].AddStats(SURVIVOR_K_WITCH, 1);

	bool bOneShot = event.GetBool("oneshot");

	if (bOneShot) {
		g_pPlayers[iKiller].AddStats(SURVIVOR_K_WITCH_OS, 1);
	}
	
	return Plugin_Continue;
}

/**
 * Surivivor met Tank.
 */
public Action Event_TankSpawn(Event event, char[] event_name, bool dontBroadcast)
{
	if (CanRecordStats() == false) {
		return Plugin_Continue;
	}

	for (int iClient = 1; iClient <= MaxClients; iClient++) 
	{
		if (!IS_REAL_CLIENT(iClient) || !IS_SURVIVOR(iClient) || !IsPlayerAlive(iClient)) {
			continue;
		}

		g_pPlayers[iClient].AddStats(SURVIVOR_MET_TANK, 1);
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

	if (IS_VALID_SURVIVOR(iKiller) && IS_VALID_INFECTED(iVictim))
	{
		char sWeaponName[32];
		event.GetString("weapon", sWeaponName, sizeof(sWeaponName));
		
		int iWeaponId;
		g_tWeaponNames.GetValue(sWeaponName, iWeaponId);

		AddWeaponKill(iKiller, iWeaponId);
		
		int iZombieClass = GetEntProp(iVictim, Prop_Send, "m_zombieClass");

		if (iZombieClass != ZC_TANK)
		{
			int iKillCode = GetKillCodeByZombieClass(iZombieClass);

			g_pPlayers[iKiller].AddStats(iKillCode, 1);
			g_pPlayers[iKiller].AddStats(SURVIVOR_KILL, 1);

			bool bHeadShot = event.GetBool("headshot");

			if (bHeadShot) {
				g_pPlayers[iKiller].AddStats(SURVIVOR_K_SI_HS, 1);
			}
		}
	}

	else if(IS_VALID_INFECTED(iKiller) && IS_VALID_SURVIVOR(iVictim))
	{
		g_pPlayers[iKiller].AddStats(INFECTED_KILL, 1);
	}

	else if (IS_VALID_SURVIVOR(iKiller) && IS_VALID_SURVIVOR(iVictim)) {
		g_pPlayers[iKiller].AddStats(SURVIVOR_TEAMKILL, 1);
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

	int iDamage = event.GetInt("dmg_health");
	
	if (iDamage >= 5000) {
		return Plugin_Continue;
	}

	int iVictim = GetClientOfUserId(event.GetInt("userid"));
	int iAttacker = GetClientOfUserId(event.GetInt("attacker"));

	if (IS_VALID_SURVIVOR(iVictim) && IS_VALID_INFECTED(iAttacker)) 
	{
		g_pPlayers[iAttacker].AddStats(INFECTED_DMG, iDamage);
		g_pPlayers[iVictim].AddStats(SURVIVOR_HURT, iDamage);
	}

	else if (IS_VALID_SURVIVOR(iAttacker) && IS_VALID_INFECTED(iVictim))
	{
		char sWeaponName[32];
		event.GetString("weapon", sWeaponName, sizeof(sWeaponName));

		if (sWeaponName[0] != 'm' && g_tWeaponNames.ContainsKey(sWeaponName)) {
			g_pPlayers[iAttacker].AddStats(SURVIVOR_HIT, 1);
		}

		int iZombieClass = GetEntProp(iVictim, Prop_Send, "m_zombieClass");

		g_pPlayers[iAttacker].AddStats(iZombieClass == ZC_TANK ? SURVIVOR_DMG_TANK : SURVIVOR_DMG, iDamage);
		g_pPlayers[iVictim].AddStats(INFECTED_HURT, iDamage);
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

	g_hMinRankedHours = CreateConVar("vs_min_ranked_hours", "3.0", "Minimum number of hours to display player statistics", FCVAR_NOTIFY);
	g_hMinRankedHours.AddChangeHook(OnMinRankedHoursChanged);
	g_fMinRankedHours = g_hMinRankedHours.FloatValue;
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
	g_fMinRankedHours = hConVar.FloatValue;
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
	if (!StrEqual(sGameMode, "versus", false) && !StrEqual(sGameMode, "mutation12", false)) {
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
		ClearPlayerData(iClient);
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
	rating float(10,3) UNSIGNED NOT NULL,\
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
	Format(sQuery, sizeof(sQuery), "SELECT (SELECT count(1) FROM vs_players b WHERE  b.`rating` > a.`rating`)+1 as rank, a.* FROM vs_players a WHERE `steam_id`='%s' LIMIT 1;", sSteamId);

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

			if (g_pPlayers[iClient].playedTime > RoundFloat(HOUR * g_fMinRankedHours) && SQL_FieldNameToNum(hndl, "rank", iColumnNum)) {
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
	if (g_pPlayers[iClient].STATE != STATE_LOADED || g_pPlayers[iClient].playedTime == 0) {
		return;
	}

	PreparationAvg(g_pPlayers[iClient]);

	if (g_pPlayers[iClient].IsNew() == false)
	{
		char sStats[UPDATE_CODE_STATS_TEMP_SIZE];
		char sStatsList[CODE_STATS_SIZE * UPDATE_CODE_STATS_TEMP_SIZE];

		char sQuery[256 + sizeof(sStatsList)];
		Format(sQuery, sizeof(sQuery), "UPDATE `vs_players` SET `last_name`='%s',`played_time`=%d,`last_visit`=%d,__STATS__`rating`=%f WHERE `id`=%d;", g_pPlayers[iClient].lastName, g_pPlayers[iClient].playedTime, GetTime(), CalculateRating(g_pPlayers[iClient]), g_pPlayers[iClient].id);

		for (int iCode = 0; iCode < CODE_STATS_SIZE; iCode ++)
		{
			Format(sStats, sizeof(sStats), UPDATE_CODE_STATS_TEMP, iCode, g_pPlayers[iClient].stats[iCode]);
			StrCat(sStatsList, sizeof(sStatsList), sStats);
		}

		ReplaceString(sQuery, sizeof(sQuery), "__STATS__", sStatsList, false);
		SQL_TQuery(ConnectDatabase(), SavePlayerThread, sQuery, iClient);
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
		Format(sQuery, sizeof(sQuery), "INSERT INTO `vs_players` (`last_name`,`steam_id`,`played_time`,`last_visit`,__STATS_COLUMN__`rating`) VALUES ('%s','%s',%d,%d,__STATS_VALUE__%f);", g_pPlayers[iClient].lastName, sSteamId, g_pPlayers[iClient].playedTime, GetTime(), CalculateRating(g_pPlayers[iClient]));

		for (int iCode = 0; iCode < CODE_STATS_SIZE; iCode ++) 
		{
			Format(sStatsColumn, sizeof(sStatsColumn), INSERT_CODE_STATS_COLUMN_TEMP, iCode);
			StrCat(sStatsColumnList, sizeof(sStatsColumnList), sStatsColumn);

			Format(sStatsValue, sizeof(sStatsValue), INSERT_CODE_STATS_VALUE_TEMP, g_pPlayers[iClient].stats[iCode]);
			StrCat(sStatsValueList, sizeof(sStatsValueList), sStatsValue);
		}

		ReplaceString(sQuery, sizeof(sQuery), "__STATS_COLUMN__", sStatsColumnList, false);
		ReplaceString(sQuery, sizeof(sQuery), "__STATS_VALUE__", sStatsValueList, false);

		SQL_TQuery(ConnectDatabase(), SavePlayerThread, sQuery, iClient);
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
	if (g_pPlayers[iClient].STATE != STATE_LOADED || g_pPlayers[iClient].IsNew() || g_pPlayers[iClient].playedTime < RoundFloat(HOUR * g_fMinRankedHours)) {
		return;
	}

	char sQuery[192];
	Format(sQuery, sizeof(sQuery), "SELECT (SELECT count(1) FROM vs_players b WHERE b.`rating`>a.`rating`)+1 as rank FROM vs_players a WHERE `id`=%d LIMIT 1;", g_pPlayers[iClient].id);

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

/**
 * Helper.
 */
float CalculateRating(Player pTargetPlayer) 
{
	float fPlayedHours = SecToHours(pTargetPlayer.playedTime + 1);

	if (fPlayedHours < g_fMinRankedHours) {
		return 0.0;
	}

	// <> Magic number <>
	float fPositive = float(pTargetPlayer.stats[SURVIVOR_KILL] + pTargetPlayer.stats[INFECTED_INCAPACITATE] * 2 + pTargetPlayer.stats[INFECTED_KILL] * 6);
	float fNegative = float(pTargetPlayer.stats[SURVIVOR_DEATH] * 4 + pTargetPlayer.stats[SURVIVOR_INCAPACITATED] * 2 + pTargetPlayer.stats[SURVIVOR_TEAMKILL] * 16);
	float fRating = (fPositive - fNegative) / (fPlayedHours);

	return fRating > 0.0 ? fRating : 0.0;
}

void PreparationAvg(Player pTargetPlayer) 
{
	if (pTargetPlayer.stats[SURVIVOR_MET_TANK]) {
		pTargetPlayer.stats[SURVIVOR_AVG_DMG_TANK] = pTargetPlayer.stats[SURVIVOR_DMG_TANK] / pTargetPlayer.stats[SURVIVOR_MET_TANK];
	}	
}

void ClearPlayerData(int iClient) 
{
	g_pPlayers[iClient].id = 0;
	g_pPlayers[iClient].lastName[0] = '\0';
	g_pPlayers[iClient].playedTime = 0;
	g_pPlayers[iClient].rank = 0;
	g_pPlayers[iClient].STATE = STATE_LOADING;

	for (int iCodeStats = 0; iCodeStats < CODE_STATS_SIZE; iCodeStats ++)
	{
		g_pPlayers[iClient].stats[iCodeStats] = 0;
	}
}

/**
 * Helper.
 */
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
int GetKillCodeByZombieClass(int iZombieClass) 
{
	switch(iZombieClass)
	{
		case ZC_SMOKER: return SURVIVOR_K_SMOKER;
		case ZC_BOOMER: return SURVIVOR_K_BOOMER;
		case ZC_HUNTER: return SURVIVOR_K_HUNTER;
		case ZC_SPITTER: return SURVIVOR_K_SPITTER;
		case ZC_JOCKEY: return SURVIVOR_K_JOCKEY;
		case ZC_CHARGER: return SURVIVOR_K_CHARGER;
	}

	return -1;
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
