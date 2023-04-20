#pragma semicolon               1
#pragma newdecls                required

#include <sourcemod>
#include <sdktools>
#include <colors>

#undef REQUIRE_PLUGIN
#include <readyup>
#define REQUIRE_PLUGIN

#include "include/versus_stats.inc"


public Plugin myinfo = { 
	name = "VersusStats",
	author = "TouchMe",
	description = "Versus mode statistics",
	version = "build_0002",
	url = "https://github.com/TouchMe-Inc/l4d2_versus_stats"
};


// Libs
#define LIB_READY               "readyup"

// Gamemode
#define GAMEMODE_VERSUS         "versus"
#define GAMEMODE_VERSUS_REALISM "mutation12"

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
#define CODE_ZERO               "code_0"
#define CREATE_CODE             "code_%d int(11) UNSIGNED NOT NULL DEFAULT 0,"
#define CREATE_CODE_LENGTH      48
#define UPDATE_CODE             "`code_%d`=%d,"
#define UPDATE_CODE_LENGTH      32
#define INSERT_CODE_COLUMN      "code_%d,"
#define INSERT_CODE_COLUMN_LENGTH 12
#define INSERT_CODE_VALUE       "%d,"
#define INSERT_CODE_VALUE_LENGTH 16

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
#define DATABASE                "versus_stats"

// Macros
#define IS_VALID_CLIENT(%1)     (%1 > 0 && %1 <= MaxClients)
#define IS_REAL_CLIENT(%1)      (IsClientInGame(%1) && !IsFakeClient(%1))
#define IS_VALID_INGAME(%1)     (IS_VALID_CLIENT(%1) && IsClientInGame(%1))

#define IS_SPECTATOR(%1)        (GetClientTeam(%1) == TEAM_SPECTATOR)
#define IS_SURVIVOR(%1)         (GetClientTeam(%1) == TEAM_SURVIVOR)
#define IS_INFECTED(%1)         (GetClientTeam(%1) == TEAM_INFECTED)

#define IS_VALID_SURVIVOR(%1)   (IS_VALID_CLIENT(%1) && IS_SURVIVOR(%1))
#define IS_VALID_INFECTED(%1)   (IS_VALID_CLIENT(%1) && IS_INFECTED(%1))

#define TEAM_SIZE               GetConVarInt(g_cvSurvivorLimit)
#define MAX_LAST_VISIT          GetConVarInt(g_cvMaxLastVisit)
#define MIN_RANKED_HOURS        GetConVarFloat(g_cvMinRankedHours)
#define MIN_RANKED_SEC          RoundFloat(HOUR * MIN_RANKED_HOURS)

#define COST_I_INCAPACITATE     GetConVarFloat(g_cvInfectedIncapacitateCost)
#define COST_I_KILL             GetConVarFloat(g_cvInfectedKillCost)
#define COST_S_KILL             GetConVarFloat(g_cvSurvivorKillCost)
#define COST_S_KILL_CI          GetConVarFloat(g_cvSurvivorKillCICost)
#define COST_S_DEATH            GetConVarFloat(g_cvSurvivorDeathCost)
#define COST_S_INCAPACITATED    GetConVarFloat(g_cvSurvivorIncapacitatedCost)
#define COST_S_TEAMKILL         GetConVarFloat(g_cvSurvivorTeamkillCost)


enum struct Player
{
	int id;
	char lastName[65];
	int playedTime;
	int rank;
	int state;
	int stats[CODE_STATS_SIZE];
}

Player
	g_tPlayers[MAXPLAYERS + 1];

bool
	g_bLate = false,
	g_bGamemodeAvailable = false,
	g_bReadyUpAvailable = false,
	g_bRoundIsLive = false,
	g_bFullTeam = false;

ConVar
	g_cvGameMode = null,
	g_cvSurvivorLimit = null,
	g_cvMaxLastVisit = null,
	g_cvMinRankedHours = null,
	g_cvSurvivorKillCost = null,
	g_cvSurvivorKillCICost = null,
	g_cvSurvivorDeathCost = null,
	g_cvSurvivorIncapacitatedCost = null,
	g_cvSurvivorTeamkillCost = null,
	g_cvInfectedIncapacitateCost = null,
	g_cvInfectedKillCost = null;

int
	g_iPlayedTimeStartAt[MAXPLAYERS + 1] = {0, ...};

StringMap
	g_tWeaponNames = null;


/**
  * Global event. Called when all plugins loaded.
  */
public void OnAllPluginsLoaded() {
	g_bReadyUpAvailable = LibraryExists(LIB_READY);
}

/**
  * Global event. Called when a library is removed.
  *
  * @param sName     Library name
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

	CreateNative("GetClientRank", Native_GetClientRank);
	CreateNative("GetClientRating", Native_GetClientRating);
	CreateNative("GetClientStats", Native_GetClientStats);
	CreateNative("GetClientPlayedTime", Native_GetClientPlayedTime);
	CreateNative("GetClientState", Native_GetClientState);
	CreateNative("GetMinRankedHours", Native_GetMinRankedHours);
	CreateNative("GetVersusStatsDatabase", Native_GetVersusStatsDatabase);
	RegPluginLibrary("versus_stats");

	return APLRes_Success;
}

/**
 * Player rank in statistics.
 * 
 * @param hPlugin       Handle to the plugin
 * @param iParams       Number of parameters
 * @return              Return rank
 */
int Native_GetClientRank(Handle plugin, int numParams)
{
	int iClient = GetNativeCell(1);
	return g_tPlayers[iClient].rank;
}

/**
 * Get calculated player rating.
 * 
 * @param hPlugin       Handle to the plugin
 * @param iParams       Number of parameters
 * @return              Return rating
 */
any Native_GetClientRating(Handle plugin, int numParams)
{
	int iClient = GetNativeCell(1);
	return CalculatePlayerRating(iClient);
}

/**
 * Get the numeric value of a statistics parameter.
 * 
 * @param hPlugin       Handle to the plugin
 * @param iParams       Number of parameters
 * @return              Return stats
 */
int Native_GetClientStats(Handle plugin, int numParams)
{
	int iClient = GetNativeCell(1), iCode = GetNativeCell(2);
	return g_tPlayers[iClient].stats[iCode];
}

/**
 * Get statistics recording time.
 * 
 * @param hPlugin       Handle to the plugin
 * @param iParams       Number of parameters
 * @return              Return played time
 */
int Native_GetClientPlayedTime(Handle plugin, int numParams)
{
	int iClient = GetNativeCell(1);
	return g_tPlayers[iClient].playedTime;
}

/**
 * Getting status about loading statistics.
 * 
 * @param hPlugin       Handle to the plugin
 * @param iParams       Number of parameters
 * @return              Return player state
 */
int Native_GetClientState(Handle plugin, int numParams)
{
	int iClient = GetNativeCell(1);
	return g_tPlayers[iClient].state;
}

/**
 * Getting the minimum number of hours to start calculating rank.
 * 
 * @param hPlugin       Handle to the plugin
 * @param iParams       Number of parameters
 * @return              Return min randed hours
 */
any Native_GetMinRankedHours(Handle plugin, int numParams) {
	return MIN_RANKED_HOURS;
}

/**
 * Accessing the database to run queries.
 * 
 * @param hPlugin       Handle to the plugin
 * @param iParams       Number of parameters
 * @return              Return Database connection
 */
any Native_GetVersusStatsDatabase(Handle plugin, int numParams) {
	return ConnectDatabase();
}

/**
 * Called when the plugin is fully initialized and all known external
 * references are resolved.
 */
public void OnPluginStart()
{
	InitCvars();
	InitEvents();
	InitDatabase();
	InitWeaponNameTrie();

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
 */
public void OnPluginEnd()
{
	if (g_tWeaponNames != null)
	{
		CloseHandle(g_tWeaponNames);
		g_tWeaponNames = null;
	}
}

/**
 * Fragment.
 */
void InitEvents() 
{
	HookEvent("versus_round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("player_incapacitated", Event_PlayerIncapacitated);
	HookEvent("pills_used", Event_PillsUsed);
	HookEvent("adrenaline_used", Event_AdrenalineUsed);
	HookEvent("heal_success", Event_HealSuccess);
	HookEvent("defibrillator_used", Event_DefibrillatorUsed);
	HookEvent("revive_success", Event_ReviveSuccess);
	HookEvent("weapon_fire", Event_WeaponFire);
	HookEvent("I_death", Event_InfectedDeath);
	HookEvent("witch_killed", Event_WitchKilled);
	HookEvent("tank_spawn", Event_TankSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_hurt", Event_PlayerHurt);
}

/**
 * Round start event.
 */
public Action Event_RoundStart(Event event, const char[] name, bool bDontBroadcast) 
{
	if (!g_bGamemodeAvailable) {
		return Plugin_Continue;
	}

	if (!g_bReadyUpAvailable)
	{
		g_bRoundIsLive = true;

		if (g_bFullTeam) {
			RunPlayedTime();
		}
	}

	return Plugin_Continue;
}

/**
 * Round end event.
 */
public Action Event_RoundEnd(Event event, const char[] name, bool bDontBroadcast) 
{	
	if (!g_bGamemodeAvailable || !g_bRoundIsLive) {
		return Plugin_Continue;
	}

	g_bRoundIsLive = false;

	StopPlayedTime();

	for (int iClient = 1; iClient <= MaxClients; iClient++) 
	{
		if (!IS_REAL_CLIENT(iClient)) {
			continue;
		}

		SavePlayerData(iClient);
		UpdatePlayerRank(iClient);
	}

	return Plugin_Continue;
}

/**
 * Player change his team.
 */
public Action Event_PlayerTeam(Event event, char[] sEventName, bool bDontBroadcast)
{
	if (!g_bGamemodeAvailable) {
		return Plugin_Continue;
	}

	int iClient = GetClientOfUserId(event.GetInt("userid"));

	if (!IS_REAL_CLIENT(iClient)) {
		return Plugin_Continue;
	}

	int iOldTeam = event.GetInt("oldteam");
	int iNewTeam = event.GetInt("team");

	if (iOldTeam == TEAM_NONE && iNewTeam == TEAM_SPECTATOR) {
		return Plugin_Continue;
	}

	CreateTimer(0.1, Timer_PlayerTeam, .flags = TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Continue;
}

/**
 * Starts a timer for calculating players game statistics.
 */
public Action Timer_PlayerTeam(Handle hTimer)
{
	bool bFullTeamBeforeCheck = g_bFullTeam;
	g_bFullTeam = (TEAM_SIZE * 2) == GetPlayerCount();

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
public Action Event_WeaponFire(Event event, char[] sEventName, bool bDontBroadcast)
{
	if (CanRecordStats() == false) {
		return Plugin_Continue;
	}

	int iClient = GetClientOfUserId(event.GetInt("userid"));

	char sWeaponName[32]; event.GetString("weapon", sWeaponName, sizeof(sWeaponName));
	
	if (StrEqual(sWeaponName, "molotov", false)) {
		AddPlayerStats(iClient, S_TH_MOLOTOV, 1);
	}

	else if (StrEqual(sWeaponName, "pipe_bomb", false)) {
		AddPlayerStats(iClient, S_TH_PIPE, 1);
	}

	else if (StrEqual(sWeaponName, "vomitjar", false)) {
		AddPlayerStats(iClient, S_TH_VOMITJAR, 1);
	}

	if (sWeaponName[0] != 'm' && g_tWeaponNames.ContainsKey(sWeaponName)) {
		AddPlayerStats(iClient, S_SHOT, 1);
	}

	return Plugin_Continue;
}

/**
 * The survivor has become incapacitated.
 */
public Action Event_PlayerIncapacitated(Event event, char[] sEventName, bool bDontBroadcast)
{
	if (CanRecordStats() == false) {
		return Plugin_Continue;
	}

	int iVictim = GetClientOfUserId(event.GetInt("userid"));
	int iAttacker = GetClientOfUserId(event.GetInt("attacker"));

	AddPlayerStats(iVictim, S_INCAPACITATED, 1);
	AddPlayerStats(iAttacker, I_INCAPACITATE, 1);

	return Plugin_Continue;
}

/**
 * Surivivor used Pills.
 */
public Action Event_PillsUsed(Event event, char[] sEventName, bool bDontBroadcast)
{
	if (CanRecordStats() == false) {
		return Plugin_Continue;
	}

	int iClient = GetClientOfUserId(event.GetInt("userid"));

	AddPlayerStats(iClient, S_PILLS, 1);

	return Plugin_Continue;
}


/**
 * Surivivor used Adrenaline.
 */
public Action Event_AdrenalineUsed(Event event, char[] sEventName, bool bDontBroadcast)
{
	if (CanRecordStats() == false) {
		return Plugin_Continue;
	}

	int iClient = GetClientOfUserId(event.GetInt("userid"));

	AddPlayerStats(iClient, S_ADRENALINE, 1);

	return Plugin_Continue;
}

/**
 * Survivor has been cured.
 */
public Action Event_HealSuccess(Event event, char[] sEventName, bool bDontBroadcast)
{
	if (CanRecordStats() == false) {
		return Plugin_Continue;
	}

	int iClient = GetClientOfUserId(event.GetInt("userid"));
	int iTarget = GetClientOfUserId(event.GetInt("subject"));

	AddPlayerStats(iClient, S_MEDKIT, 1);

	if (iClient != iTarget)
	{
		AddPlayerStats(iClient, S_HEAL, 1);
		AddPlayerStats(iTarget, S_HEALED, 1);
	}

	else {
		AddPlayerStats(iClient, S_SELF_HEALED, 1);
	}

	return Plugin_Continue;
}

/**
 * Surivivor used Defibrillator.
 */
public Action Event_DefibrillatorUsed(Event event, char[] sEventName, bool bDontBroadcast)
{
	if (CanRecordStats() == false) {
		return Plugin_Continue;
	}

	int iClient = GetClientOfUserId(event.GetInt("userid"));
	int iTarget = GetClientOfUserId(event.GetInt("subject"));

	AddPlayerStats(iClient, S_DEFIBRILLATE, 1);
	AddPlayerStats(iTarget, S_DEFIBRILLATED, 1);

	return Plugin_Continue;
}

/**
 * Survivor has been revived.
 */
public Action Event_ReviveSuccess(Event event, char[] sEventName, bool bDontBroadcast)
{
	if (CanRecordStats() == false) {
		return Plugin_Continue;
	}

	int iClient = GetClientOfUserId(event.GetInt("userid"));
	int iTarget = GetClientOfUserId(event.GetInt("subject"));

	AddPlayerStats(iClient, S_REVIVE, 1);
	AddPlayerStats(iTarget, S_REVIVED, 1);

	return Plugin_Continue;
}

/**
 * Surivivor Killed Common Infected.
 */
public Action Event_InfectedDeath(Event event, char[] sEventName, bool bDontBroadcast)
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

	AddPlayerStats(iKiller, S_K_CI, 1);

	bool bHeadShot = event.GetBool("headshot");

	if (bHeadShot) {
		AddPlayerStats(iKiller, S_K_CI_HS, 1);
	}

	return Plugin_Continue;
}

/**
 * Surivivor Killed Witch.
 */
public Action Event_WitchKilled(Event event, char[] sEventName, bool bDontBroadcast)
{
	if (CanRecordStats() == false) {
		return Plugin_Continue;
	}

	int iKiller = GetClientOfUserId(event.GetInt("userid"));

	if (!IS_VALID_SURVIVOR(iKiller)) {
		return Plugin_Continue;
	}

	AddPlayerStats(iKiller, S_K_WITCH, 1);

	bool bOneShot = event.GetBool("oneshot");

	if (bOneShot) {
		AddPlayerStats(iKiller, S_K_WITCH_OS, 1);
	}
	
	return Plugin_Continue;
}

/**
 * Surivivor met Tank.
 */
public Action Event_TankSpawn(Event event, char[] sEventName, bool bDontBroadcast)
{
	if (CanRecordStats() == false) {
		return Plugin_Continue;
	}

	int iTank = GetClientOfUserId(event.GetInt("userid"));

	if (IsFakeClient(iTank)) {
		return Plugin_Continue;
	}

	for (int iClient = 1; iClient <= MaxClients; iClient++) 
	{
		if (!IS_REAL_CLIENT(iClient) || !IS_SURVIVOR(iClient) || !IsPlayerAlive(iClient)) {
			continue;
		}

		AddPlayerStats(iClient, S_MET_TANK, 1);
	}
	
	return Plugin_Continue;
}

/**
 * Registers murder/death. Support all playable classes (Hunter, Smoker, Boomer, Tank, Survivors).
 */
public Action Event_PlayerDeath(Event event, const char[] name, bool bDontBroadcast) 
{
	if (CanRecordStats() == false) {
		return Plugin_Continue;
	}

	int iVictim = GetClientOfUserId(event.GetInt("userid"));

	if (IS_VALID_INFECTED(iVictim)) {
		AddPlayerStats(iVictim, I_DEATH, 1);
	}
	
	else if (IS_VALID_SURVIVOR(iVictim)) {
		AddPlayerStats(iVictim, S_DEATH, 1);
	}

	int iKiller = GetClientOfUserId(event.GetInt("attacker"));

	if (IS_VALID_SURVIVOR(iKiller) && IS_VALID_INFECTED(iVictim))
	{
		char sWeaponName[32]; event.GetString("weapon", sWeaponName, sizeof(sWeaponName));

		int iWeaponId; g_tWeaponNames.GetValue(sWeaponName, iWeaponId);

		AddWeaponKill(iKiller, iWeaponId);
		
		int iZombieClass = GetClientZombieClass(iVictim);

		if (iZombieClass != ZC_TANK)
		{
			int iKillCode = GetKillCodeByZombieClass(iZombieClass);

			AddPlayerStats(iKiller, iKillCode, 1);
			AddPlayerStats(iKiller, S_KILL, 1);

			bool bHeadShot = event.GetBool("headshot");

			if (bHeadShot) {
				AddPlayerStats(iKiller, S_K_SI_HS, 1);
			}
		}
	}

	else if(IS_VALID_INFECTED(iKiller) && IS_VALID_SURVIVOR(iVictim))
	{
		AddPlayerStats(iKiller, I_KILL, 1);
	}

	else if (IS_VALID_SURVIVOR(iKiller) && IS_VALID_SURVIVOR(iVictim)) {
		AddPlayerStats(iKiller, S_TEAMKILL, 1);
	}

	return Plugin_Continue;
}

/**
 * Registers existing/caused damage.
 */
public Action Event_PlayerHurt(Event event, char[] sEventName, bool bDontBroadcast)
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
		AddPlayerStats(iAttacker, I_DMG, iDamage);
		AddPlayerStats(iVictim, S_HURT, iDamage);
	}

	else if (IS_VALID_SURVIVOR(iAttacker) && IS_VALID_INFECTED(iVictim))
	{
		char sWeaponName[32]; event.GetString("weapon", sWeaponName, sizeof(sWeaponName));

		if (sWeaponName[0] != 'm' && g_tWeaponNames.ContainsKey(sWeaponName)) {
			AddPlayerStats(iAttacker, S_HIT, 1);
		}

		int iZombieClass = GetClientZombieClass(iVictim);

		AddPlayerStats(iAttacker, iZombieClass == ZC_TANK ? S_DMG_TANK : S_DMG, iDamage);
		AddPlayerStats(iVictim, I_HURT, iDamage);
	}

	return Plugin_Continue;
}

/**
 * Fragment
 */
void InitCvars()
{
	(g_cvGameMode = FindConVar("mp_gamemode")).AddChangeHook(OnGamemodeChanged);

	g_cvSurvivorLimit = FindConVar("survivor_limit");
	g_cvMaxLastVisit = CreateConVar("vs_max_last_visit", "2592000", "The maximum time since the last visit that a record will be found in the database");
	g_cvMinRankedHours = CreateConVar("vs_min_ranked_hours", "12.0", "Minimum number of hours to display player statistics");

	g_cvSurvivorKillCost = CreateConVar("vs_s_kill_cost", "1.0"),
	g_cvSurvivorKillCICost = CreateConVar("vs_s_kill_ci_cost", "0.02"),
	g_cvSurvivorDeathCost = CreateConVar("vs_s_death_cost", "4.0"),
	g_cvSurvivorIncapacitatedCost = CreateConVar("vs_s_incapacitated_cost", "2.0"),
	g_cvSurvivorTeamkillCost = CreateConVar("vs_s_teamkill_cost", "16.0"),
	g_cvInfectedIncapacitateCost = CreateConVar("vs_i_incapacitate_cost", "2.0"),
	g_cvInfectedKillCost = CreateConVar("vs_i_kill_cost", "1.0");
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
	g_bGamemodeAvailable = IsVersusMode(sNewGameMode);
}

/**
 * Called when the map has loaded, servercfgfile (server.cfg) has been executed, and all plugin configs are done executing.
 * This will always be called once and only once per map. It will be called after OnMapStart().
*/
public void OnConfigsExecuted() 
{
	char sGameMode[16];
	GetConVarString(g_cvGameMode, sGameMode, sizeof(sGameMode));
	g_bGamemodeAvailable = IsVersusMode(sGameMode);
}

/**
 * Database preparation.
 */
void InitDatabase()
{
	Database db = ConnectDatabase();

	if (!AvailableDatabaseDriver(db)) {
		SetFailState("Unsupported database driver.");
	}

	if (CreateTable(db) == false) {
		SetFailState("Create tables failure.");
	} else {
		ClearTable(db);
	}

	delete db;
}

/**
 * Establishing a database connection.
 */
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

/**
 * Checking the database driver.
 */
bool AvailableDatabaseDriver(Database db) 
{
	char ident[16]; db.Driver.GetIdentifier(ident, sizeof(ident));

	if (StrEqual(ident, "mysql", false)) {
		return true;
	}

	return false;
}

/**
 * Creating a table of players.
 */
bool CreateTable(Database db)
{
	char sStats[CREATE_CODE_LENGTH];
	char sStatsList[CODE_STATS_SIZE * CREATE_CODE_LENGTH];

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
		Format(sStats, sizeof(sStats), CREATE_CODE, iCode);
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

/**
 * Removing inactive players from the table.
 */
void ClearTable(Database db)
{
	char sQuery[128];
	Format(sQuery, sizeof(sQuery), "DELETE FROM vs_players WHERE `last_visit`<%d;", (GetTime() - MAX_LAST_VISIT));

	SQL_LockDatabase(db);

	if (!SQL_FastQuery(db, sQuery))
	{
		char sError[255];
		SQL_GetError(db, sError, sizeof(sError));
		LogError("Failed to query: %s", sError);
	}

	SQL_UnlockDatabase(db);
}

/**
 * Initializing a weapon map whose key is the name of the weapon and whose 
 * value is weapon_id.
 */
void InitWeaponNameTrie()
{
	g_tWeaponNames = CreateTrie();

	SetTrieValue(g_tWeaponNames, "pistol", WID_PISTOL);
	SetTrieValue(g_tWeaponNames, "smg", WID_SMG);
	SetTrieValue(g_tWeaponNames, "pumpshotgun", WID_PUMP);
	SetTrieValue(g_tWeaponNames, "autoshotgun", WID_AUTO);
	SetTrieValue(g_tWeaponNames, "rifle", WID_M16);
	SetTrieValue(g_tWeaponNames, "hunting_rifle", WID_HUNTING);
	SetTrieValue(g_tWeaponNames, "smg_silenced", WID_SILENCED);
	SetTrieValue(g_tWeaponNames, "shotgun_chrome", WID_CHROME);
	SetTrieValue(g_tWeaponNames, "rifle_desert", WID_DESERT);
	SetTrieValue(g_tWeaponNames, "sniper_military", WID_MILITARY);
	SetTrieValue(g_tWeaponNames, "shotgun_spas", WID_SPAS);
	SetTrieValue(g_tWeaponNames, "molotov", WID_MOLOTOV);
	SetTrieValue(g_tWeaponNames, "pipe_bomb", WID_PIPE);
	SetTrieValue(g_tWeaponNames, "melee", WID_MELEE);
	SetTrieValue(g_tWeaponNames, "chainsaw", WID_SAW);
	SetTrieValue(g_tWeaponNames, "grenade_launcher", WID_GL);
	SetTrieValue(g_tWeaponNames, "rifle_ak47", WID_AK47);
	SetTrieValue(g_tWeaponNames, "pistol_magnum", WID_MAGNUM);
	SetTrieValue(g_tWeaponNames, "smg_mp5", WID_MP5);
	SetTrieValue(g_tWeaponNames, "rifle_sg552", WID_SG552);
	SetTrieValue(g_tWeaponNames, "sniper_awp", WID_AWP);
	SetTrieValue(g_tWeaponNames, "sniper_scout", WID_SCOUT);
	SetTrieValue(g_tWeaponNames, "rifle_m60", WID_M60);
}

/**
 * Loading Player Statistics.
 * Called once a client is authorized and fully in-game, and after all post-connection authorizations have been performed.
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
 * Saving player statistics.
 * Called before client disconnected.
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
	int iTimeStartAt = g_iPlayedTimeStartAt[iClient];

	if (iTimeStartAt > 0)
	{
		AddPlayerPlayedTime(iClient, iBreakTime - iTimeStartAt);
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
	return g_bRoundIsLive && g_bFullTeam && g_bGamemodeAvailable;
}

/**
 * Loading all player statistics.
 */
void LoadPlayerData(int iClient) 
{
	Database db = ConnectDatabase();

	char sSteamId[MAX_AUTHID_LENGTH]; GetClientAuthId(iClient, AuthId_SteamID64, sSteamId, sizeof(sSteamId));
	char sClientName[MAX_NAME_LENGTH]; GetClientName(iClient, sClientName, sizeof(sClientName));
	SQL_EscapeString(db, sClientName, g_tPlayers[iClient].lastName,  sizeof(g_tPlayers[].lastName));

	char sQuery[256];
	Format(sQuery, sizeof(sQuery), "SELECT (SELECT count(1) FROM vs_players b WHERE  b.`rating` > a.`rating`)+1 as rank, a.* FROM vs_players a WHERE `steam_id`='%s' LIMIT 1;", sSteamId);

	SQL_TQuery(db, LoadPlayerThread, sQuery, iClient);
}

void LoadPlayerThread(Handle owner, Handle hndl, const char[] sError, int iClient)
{
	if (hndl == null)
	{
		LogError("LoadPlayerThread failed! Reason: %s", sError);
		return;
	}

	if (SQL_GetRowCount(hndl) > 0 && SQL_FetchRow(hndl))
	{
		int iColumnNum;

		if (SQL_FieldNameToNum(hndl, "id", iColumnNum)) {
			g_tPlayers[iClient].id = SQL_FetchInt(hndl, iColumnNum);
		}

		if (SQL_FieldNameToNum(hndl, "played_time", iColumnNum)) 
		{
			g_tPlayers[iClient].playedTime = SQL_FetchInt(hndl, iColumnNum);

			if (g_tPlayers[iClient].playedTime > MIN_RANKED_SEC && SQL_FieldNameToNum(hndl, "rank", iColumnNum)) {
				g_tPlayers[iClient].rank = SQL_FetchInt(hndl, iColumnNum); 
			}
		}

		if (SQL_FieldNameToNum(hndl, CODE_ZERO, iColumnNum)) 
		{
			for (int iCode = 0; iCode < CODE_STATS_SIZE; iCode ++)
			{
				g_tPlayers[iClient].stats[iCode] = SQL_FetchInt(hndl, iColumnNum + iCode);
			}
		}

		g_tPlayers[iClient].state = STATE_LOADED;
	}
}

/**
 * Save or update all player statistics.
 */
void SavePlayerData(int iClient) 
{
	if (g_tPlayers[iClient].state != STATE_LOADED || g_tPlayers[iClient].playedTime == 0) {
		return;
	}

	PreparePlayerStatsAvg(iClient);

	if (!IsNewPlayer(iClient))
	{
		// Build Update query
		char sStats[UPDATE_CODE_LENGTH];
		char sStatsList[CODE_STATS_SIZE * UPDATE_CODE_LENGTH];

		char sQuery[384 + sizeof(sStatsList)];
		Format(sQuery, sizeof(sQuery), "UPDATE `vs_players` SET `last_name`='%s',`played_time`=%d,`last_visit`=%d,__STATS__`rating`=%f WHERE `id`=%d;", g_tPlayers[iClient].lastName, g_tPlayers[iClient].playedTime, GetTime(), CalculatePlayerRating(iClient), g_tPlayers[iClient].id);

		for (int iCode = 0; iCode < CODE_STATS_SIZE; iCode ++)
		{
			Format(sStats, sizeof(sStats), UPDATE_CODE, iCode, g_tPlayers[iClient].stats[iCode]);
			StrCat(sStatsList, sizeof(sStatsList), sStats);
		}

		ReplaceString(sQuery, sizeof(sQuery), "__STATS__", sStatsList, false);
		SQL_TQuery(ConnectDatabase(), SavePlayerThread, sQuery, iClient);
	}

	else
	{
		char sSteamId[MAX_AUTHID_LENGTH]; GetClientAuthId(iClient, AuthId_SteamID64, sSteamId, sizeof(sSteamId));

		// Build Insert query
		char sStatsColumn[CODE_STATS_SIZE * INSERT_CODE_COLUMN_LENGTH];
		char sStatsColumnList[CODE_STATS_SIZE * INSERT_CODE_COLUMN_LENGTH];

		char sStatsValue[INSERT_CODE_VALUE_LENGTH];
		char sStatsValueList[CODE_STATS_SIZE * INSERT_CODE_VALUE_LENGTH];
 
		char sQuery[256 + sizeof(sStatsColumnList) + sizeof(sStatsValueList)];
		Format(sQuery, sizeof(sQuery), "INSERT INTO `vs_players` (`last_name`,`steam_id`,`played_time`,`last_visit`,__STATS_COLUMN__`rating`) VALUES ('%s','%s',%d,%d,__STATS_VALUE__%f);", g_tPlayers[iClient].lastName, sSteamId, g_tPlayers[iClient].playedTime, GetTime(), CalculatePlayerRating(iClient));

		for (int iCode = 0; iCode < CODE_STATS_SIZE; iCode ++) 
		{
			Format(sStatsColumn, sizeof(sStatsColumn), INSERT_CODE_COLUMN, iCode);
			StrCat(sStatsColumnList, sizeof(sStatsColumnList), sStatsColumn);

			Format(sStatsValue, sizeof(sStatsValue), INSERT_CODE_VALUE, g_tPlayers[iClient].stats[iCode]);
			StrCat(sStatsValueList, sizeof(sStatsValueList), sStatsValue);
		}

		ReplaceString(sQuery, sizeof(sQuery), "__STATS_COLUMN__", sStatsColumnList, false);
		ReplaceString(sQuery, sizeof(sQuery), "__STATS_VALUE__", sStatsValueList, false);

		SQL_TQuery(ConnectDatabase(), SavePlayerThread, sQuery, iClient);
	}
}

void SavePlayerThread(Handle owner, Handle hndl, const char[] sError, int iClient)
{
	if (hndl == null)
	{
		LogError("SavePlayerThread failed! Reason: %s", sError);
		return;
	}

	if (IsNewPlayer(iClient)) {
		g_tPlayers[iClient].id = SQL_GetInsertId(hndl);
	}
}

/**
 * Reset all player statistics.
 */
void ClearPlayerData(int iClient) 
{
	g_tPlayers[iClient].id = 0;
	g_tPlayers[iClient].lastName[0] = '\0';
	g_tPlayers[iClient].playedTime = 0;
	g_tPlayers[iClient].rank = 0;
	g_tPlayers[iClient].state = STATE_LOADING;

	for (int iCodeStats = 0; iCodeStats < CODE_STATS_SIZE; iCodeStats ++)
	{
		g_tPlayers[iClient].stats[iCodeStats] = 0;
	}
}

/**
 * Update a player's rating, given that other players have played with this player.
 */
void UpdatePlayerRank(int iClient) 
{
	if (g_tPlayers[iClient].state != STATE_LOADED || IsNewPlayer(iClient) || g_tPlayers[iClient].playedTime < MIN_RANKED_SEC) {
		return;
	}

	char sQuery[192];
	Format(sQuery, sizeof(sQuery), "SELECT (SELECT count(1) FROM vs_players b WHERE b.`rating`>a.`rating`)+1 as rank FROM vs_players a WHERE `id`=%d LIMIT 1;", g_tPlayers[iClient].id);

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

	if (SQL_GetRowCount(hndl) > 0 && SQL_FetchRow(hndl)) {
		g_tPlayers[iClient].rank = SQL_FetchInt(hndl, 0);
	}
}


/**
 * Adds a kill to the player's statistics, taking into account the weapon id.
 */
void AddWeaponKill(int iClient, int iWeaponId)
{
	if (iWeaponId != WID_MELEE) {
		AddPlayerStats(iClient, GetKillCodeByWeaponId(iWeaponId), 1);
	}

	else
	{
		char sMeleeName[32]; GetClientMeleeName(iClient, sMeleeName, sizeof(sMeleeName));
		AddPlayerStats(iClient, GetKillCodeByMeleeName(sMeleeName), 1);
	}
}

/**
 * Player Pts Calculation.
 */
float CalculatePlayerRating(int iClient) 
{
	float fPlayedHours = SecToHours(g_tPlayers[iClient].playedTime);

	if (fPlayedHours < MIN_RANKED_HOURS) {
		return 0.0;
	}

	float fPositive = float(g_tPlayers[iClient].stats[S_K_CI]) * COST_S_KILL_CI
					+ float(g_tPlayers[iClient].stats[S_KILL]) * COST_S_KILL
					+ float(g_tPlayers[iClient].stats[I_INCAPACITATE]) * COST_I_INCAPACITATE
					+ float(g_tPlayers[iClient].stats[I_KILL]) * COST_I_KILL;

	float fNegative = float(g_tPlayers[iClient].stats[S_DEATH]) * COST_S_DEATH 
					+ float(g_tPlayers[iClient].stats[S_INCAPACITATED]) * COST_S_INCAPACITATED 
					+ float(g_tPlayers[iClient].stats[S_TEAMKILL]) * COST_S_TEAMKILL;

	float fRating = (fPositive - fNegative) / (fPlayedHours);

	return fRating > 0.0 ? fRating : 0.0;
}

/**
 * Calculating averages of statistics.
 */
void PreparePlayerStatsAvg(int iClient) 
{
	if (g_tPlayers[iClient].stats[S_MET_TANK] > 0) { 
		g_tPlayers[iClient].stats[S_AVG_DMG_TANK] = g_tPlayers[iClient].stats[S_DMG_TANK] / g_tPlayers[iClient].stats[S_MET_TANK];
	}	
}

void AddPlayerStats(int iClient, int iCode, int iValue) {
	g_tPlayers[iClient].stats[iCode] += iValue;
}

void AddPlayerPlayedTime(int iClient, int iValue) {
	g_tPlayers[iClient].playedTime += iValue;
}

bool IsNewPlayer(int iClient) {
	return g_tPlayers[iClient].id == 0;
}

/**
 * Returns killcode by weapon id.
 */
int GetKillCodeByWeaponId(int iWeponId)
{
	switch (iWeponId) 
	{
		case WID_PISTOL: return S_K_PISTOL;
		case WID_SMG: return S_K_SMG;
		case WID_PUMP: return S_K_PUMP;
		case WID_AUTO: return S_K_AUTO;
		case WID_M16: return S_K_M16;
		case WID_HUNTING: return S_K_HUNTING;
		case WID_SILENCED: return S_K_SILENCED;
		case WID_CHROME: return S_K_CHROME;
		case WID_DESERT: return S_K_DESERT;
		case WID_MILITARY: return S_K_MILITARY;
		case WID_SPAS: return S_K_SPAS;
		case WID_MOLOTOV: return S_K_MOLOTOV;
		case WID_PIPE: return S_K_PIPE;
		case WID_SAW: return S_K_SAW;
		case WID_GL: return S_K_GL;
		case WID_AK47: return S_K_AK47;
		case WID_MAGNUM: return S_K_MAGNUM;
		case WID_MP5: return S_K_MP5;
		case WID_SG552: return S_K_SG552;
		case WID_AWP: return S_K_AWP;
		case WID_SCOUT: return S_K_SCOUT;
		case WID_M60: return S_K_M60;
	}

	return S_K_NONE;
}

/**
 * Returns killcode by melee name.
 */
int GetKillCodeByMeleeName(const char[] sMeleeName) 
{
	if (sMeleeName[0] == 'k' && sMeleeName[1] == 'a') { /* [ka]tana */
		return S_K_KATANA;
	}

	else if (sMeleeName[0] == 'f' && sMeleeName[1] == 'i') { /* [fi]reaxe */
		return S_K_AXE;
	}
	
	else if (sMeleeName[0] == 'm') { /* [m]achete */
		return S_K_MACHATE;
	}

	else if (sMeleeName[0] == 'k') { /* [k]nife */
		return S_K_KNIFE;
	}

	else if (sMeleeName[0] == 'c' && sMeleeName[1] == 'h') { // [ch]ainsaw */
		return S_K_SAW;
	}
	
	else if (sMeleeName[0] == 'p') { /* [p]itchfork */
		return S_K_PITCHFORK;
	}
	
	else if (sMeleeName[0] == 's') { /* [s]hovel */
		return S_K_SHOVEL;
	}

	else if (sMeleeName[0] == 'g') { /* [g]olfclub */
		return S_K_GOLF;
	}

	else if (sMeleeName[0] == 'e') { /* [e]lectric_guitar */
		return S_K_GUITAR;
	}

	else if (sMeleeName[0] == 't') { /* [t]onfa */
		return S_K_TONFA;
	}

	else if (sMeleeName[0] == 'b') { /* [b]aseball_bat */
		return S_K_BASEBALL;
	}

	else if (sMeleeName[0] == 'c' && sMeleeName[2] == 'i') { // [c]r[i]cket_bat */
		return S_K_CRICKET;
	}

	else if (sMeleeName[0] == 'f') { /* [f]rying_pan */
		return S_K_PAN;
	}

	else if (sMeleeName[0] == 'c') { /* [c]rowbar */
		return S_K_CROWBAR;
	}

	return S_K_NONE;
}

/**
 * Returns killcode by zombie class.
 */
int GetKillCodeByZombieClass(int iZombieClass) 
{
	switch(iZombieClass)
	{
		case ZC_SMOKER: return S_K_SMOKER;
		case ZC_BOOMER: return S_K_BOOMER;
		case ZC_HUNTER: return S_K_HUNTER;
		case ZC_SPITTER: return S_K_SPITTER;
		case ZC_JOCKEY: return S_K_JOCKEY;
		case ZC_CHARGER: return S_K_CHARGER;
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

/**
 * Getting the player's current zombie class.
 *
 * @param iClient       Client index
 *
 * @return              Returns the code of the zombie class
 */
int GetClientZombieClass(int iClient) {
	return GetEntProp(iClient, Prop_Send, "m_zombieClass");
}

void GetClientMeleeName(int iClient, char[] sMeleeName, int iLen)
{
	GetEntPropString(
		GetPlayerWeaponSlot(iClient, 1), 
		Prop_Data, 
		"m_strMapSetScriptName", 
		sMeleeName, 
		iLen
	);
}

/**
 * Is the game mode versus.
 *
 * @param sGameMode     A string containing the name of the game mode
 *
 * @return              Returns true if verus, otherwise false
 */
bool IsVersusMode(const char[] sGameMode) {
	return (StrEqual(sGameMode, GAMEMODE_VERSUS, false) || StrEqual(sGameMode, GAMEMODE_VERSUS_REALISM, false));
}
