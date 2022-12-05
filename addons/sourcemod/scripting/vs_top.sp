#pragma semicolon               1
#pragma newdecls                required

#include <sourcemod>
#include <sdktools>
#include <colors>

#undef REQUIRE_PLUGIN
#include <versus_stats>
#define LIB_VERSUS_STATS        "versus_stats"


public Plugin myinfo = { 
	name = "VersusStatsTop",
	author = "TouchMe",
	description = "Versus mode statistics",
	version = "1.0 (versus_stats v" ... VERSUS_STATS_VERSION ... ")"
};


// Other
#define TOP_LIMIT               50
#define PER_PAGE                5
#define HOUR                    3600
#define TRANSLATIONS            "vs_top.phrases"


enum struct Player
{
	int rank;
	char lastName[65];
	int playedTime;
	float rating;
}

Player 
	g_iTopList[TOP_LIMIT + 1];

bool
	g_bVersusStatsAvailable = false;

int
	g_iTopSize = 0,
	g_iClientPage[MAXPLAYERS + 1] = {0, ...};


/**
  * Global event. Called when all plugins loaded.
  *
  * @noreturn
  */
public void OnAllPluginsLoaded()
{
	g_bVersusStatsAvailable = LibraryExists(LIB_VERSUS_STATS);

	if (g_bVersusStatsAvailable) {
		Database db = ConnectDatabase();
		LoadTopPlayers(db);
		delete db;
	}
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
	if (StrEqual(sName, LIB_VERSUS_STATS)) {
		g_bVersusStatsAvailable = false;
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
	if (StrEqual(sName, LIB_VERSUS_STATS)) {
		g_bVersusStatsAvailable = true;
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
	InitCmds();
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

/**
 * Fragment.
 * 
 * @noreturn
 */
void InitCmds()
{
	RegConsoleCmd("sm_top",	Cmd_ShowTop);
}

public Action Cmd_ShowTop(int iClient, int iArgs)
{
	if (!g_bVersusStatsAvailable) {
		return Plugin_Continue;
	}

	if (IS_VALID_CLIENT(iClient))
	{
		if (g_iTopSize == 0) {
			CPrintToChat(iClient, "%T", "TOP_EMPTY", iClient);
			return Plugin_Handled;
		}

		g_iClientPage[iClient] = 0;

		if (iArgs > 0)
		{
			char sArg[32];
			GetCmdArg(1, sArg, sizeof(sArg));
			
			int iOffset = StringToInt(sArg); 
			
			if (iOffset % PER_PAGE == 0) {
				g_iClientPage[iClient] = (iOffset / PER_PAGE);
			}
			
			else
			{
				CPrintToChat(iClient, "%T", "TOP_BAD_ARG", iClient, sArg);
				return Plugin_Handled;
			}
		}

		if (g_iClientPage[iClient] > GetMaxPage()) {
			g_iClientPage[iClient] = GetMaxPage();
		}

		Top(iClient, g_iClientPage[iClient]);
	}

	return Plugin_Handled;
}

void Top(int iClient, int iPage) 
{
	Panel hPanel = new Panel();

	char sTemp[128];

	Format(sTemp, sizeof(sTemp), "%T", "TOP_TITLE", iClient);
	hPanel.SetTitle(sTemp);
	hPanel.DrawText(" ");

	int iStart = iPage * PER_PAGE;
	int iEnd = (iPage + 1) * PER_PAGE;
	int iSpace = 0;
	int iSize = g_iTopSize;

	if (iEnd > iSize)
	{
		iSpace = iEnd - iSize;
		iEnd = iSize;
	}

	for (int iItem = iStart; iItem < iEnd; iItem++)
	{
		Format(sTemp, sizeof(sTemp), "%T", "TOP_ITEM", iClient, g_iTopList[iItem].rank, g_iTopList[iItem].lastName, SecToHours(g_iTopList[iItem].playedTime), g_iTopList[iItem].rating);
		hPanel.DrawText(sTemp);
	}

	for (int i = 0; i < iSpace; i++)
	{
		hPanel.DrawText(" ");
	}

	hPanel.DrawText(" ");

	Format(sTemp, sizeof(sTemp), "%T", "NEXT", iClient);
	hPanel.DrawItem(sTemp, iEnd < iSize ? ITEMDRAW_CONTROL : ITEMDRAW_DISABLED);

	if (iPage == 0) {
		Format(sTemp, sizeof(sTemp), "%T", "CLOSE", iClient);
		hPanel.DrawItem(sTemp, ITEMDRAW_CONTROL);
	} else {
		Format(sTemp, sizeof(sTemp), "%T", "BACK", iClient);
		hPanel.DrawItem(sTemp, ITEMDRAW_CONTROL);
	}

	hPanel.Send(iClient, HandleTop, MENU_TIME_FOREVER);

	delete hPanel;
}

public int HandleTop(Menu hMenu, MenuAction action, int iClient, int iSelectedIndex)
{
	if (action == MenuAction_Select)
	{
		switch (iSelectedIndex) 
		{
			case 1: {
				if (++ g_iClientPage[iClient] * PER_PAGE < g_iTopSize) {
					Top(iClient, g_iClientPage[iClient]);
				}
			}

			case 2: {
				if (-- g_iClientPage[iClient] >= 0) {
					Top(iClient, g_iClientPage[iClient]);
				}
			}
		}
	}

	return 0;
}

float SecToHours(int seconds)
{
	return float(seconds) / float(HOUR);
}

int GetMaxPage() {
	return RoundToFloor(float(g_iTopSize) / float(PER_PAGE));
}

void LoadTopPlayers(Database db)
{
	char sQuery[160];
	Format(sQuery, sizeof(sQuery), "SELECT `last_name`, `played_time`, `rating` FROM vs_players WHERE `played_time`>%d AND `rating`>0 ORDER BY `rating` DESC LIMIT %d;", RoundFloat(HOUR * GetMinRankedHours()), TOP_LIMIT);

	SQL_LockDatabase(db);

	DBResultSet dbResult = SQL_Query(db, sQuery, sizeof(sQuery));

	if (dbResult != null)
	{
		int iPos = 0;
		int iColumnNum;

		while (SQL_FetchRow(dbResult))
		{
			if (SQL_FieldNameToNum(dbResult, "last_name", iColumnNum)) {
				SQL_FetchString(dbResult, iColumnNum, g_iTopList[iPos].lastName, sizeof(g_iTopList[].lastName));	
			}

			if (SQL_FieldNameToNum(dbResult, "played_time", iColumnNum)) {
				g_iTopList[iPos].playedTime = SQL_FetchInt(dbResult, iColumnNum);
			}

			if (SQL_FieldNameToNum(dbResult, "rating", iColumnNum)) {
				g_iTopList[iPos].rating = SQL_FetchFloat(dbResult, iColumnNum);
			}
			
			g_iTopList[iPos].rank = ++ iPos;
		}

		g_iTopSize = iPos;

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