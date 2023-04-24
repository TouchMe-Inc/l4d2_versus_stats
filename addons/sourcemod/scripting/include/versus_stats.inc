#if defined _versus_stats_included
 #endinput
#endif
#define _versus_stats_included


// Infected Kill
#define S_K_CI                  0  // Surivivor Killed Common Infected
#define S_K_SMOKER              1  // Surivivor Killed Smoker
#define S_K_BOOMER              2  // Surivivor Killed Boomer
#define S_K_HUNTER              3  // Surivivor Killed Hunter
#define S_K_SPITTER             4  // Surivivor Killed Spitter
#define S_K_JOCKEY              5  // Surivivor Killed Jockey
#define S_K_CHARGER             6  // Surivivor Killed Changer
#define S_K_WITCH               7  // Surivivor Killed Witch
#define S_AVG_DMG_TANK          8  // Surivivor avg Tank damage

// Infected Kill Headshot/One shot
#define S_K_CI_HS               9  // Surivivor Killed Common Infected (Headshot)
#define S_K_SI_HS               10 // Surivivor Killed Special Infected (Headshot)
#define S_K_WITCH_OS            11 // Surivivor Killed Witch in one shot

// Survivor event
#define S_SHOT                  12 // Amount of surivivor shot
#define S_HIT                   13 // Amount of surivivor hit
#define S_REVIVE                14 // Surivivor revived someone
#define S_REVIVED               15 // Surivivor is revived by someone
#define S_HURT                  16 // Amount of damage hurt by SI
#define S_DMG                   17 // Amount of damage made SI
#define S_DMG_TANK              18 // Amount of damage made tank
#define S_TEAMKILL              19 // Amount of Team kill
#define S_KILL                  20 // Amount of Killing infected (last hit)
#define S_INCAPACITATED         21 // Amount of surivivor incapacated
#define S_DEATH                 22 // Amount of death of surivivor

// Infected event
#define I_HURT                  23 // Amount of damage hurt by Survivor
#define I_DMG                   24 // Amount of damage made Survivor
#define I_KILL                  25 // Amount of Killing Surivivor
#define I_INCAPACITATE          26 // Amount of Incapacitating Surivivor
#define I_DEATH                 27 // Amount of death of infected

// Items event
#define S_PILLS                 28 // Surivivor used Pills 
#define S_ADRENALINE            29 // Surivivor used Adrenaline 
#define S_MEDKIT                30 // Surivivor used Medikit 
#define S_HEALED                31 // Surivivor is healed by someone
#define S_SELF_HEALED           32 // Surivivor is healed by himself
#define S_HEAL                  33 // Surivivor used Medikit for healing someone
#define S_DEFIBRILLATE          34 // Surivivor defibrillated someone
#define S_DEFIBRILLATED         35 // Surivivor is defibrillated by someone

// Gun statistic
#define S_K_SMG                 36 // Surivivor killed CI/SI by SMG
#define S_K_SILENCED            37 // Surivivor killed CI/SI by SMG silenced
#define S_K_MP5                 38 // Surivivor killed CI/SI by MP5
#define S_K_PUMP                39 // Surivivor killed CI/SI by Pump
#define S_K_CHROME              40 // Surivivor killed CI/SI by Chrome
#define S_K_SCOUT               41 // Surivivor killed CI/SI by Scout
#define S_K_M16                 42 // Surivivor killed CI/SI by Rifle (M16)
#define S_K_DESERT              43 // Surivivor killed CI/SI by Desert
#define S_K_AK47                44 // Surivivor killed CI/SI by AK47
#define S_K_SG552               45 // Surivivor killed CI/SI by Sg552
#define S_K_HUNTING             46 // Surivivor killed CI/SI by Hunting
#define S_K_MILITARY            47 // Surivivor killed CI/SI by Military
#define S_K_AWP                 48 // Surivivor killed CI/SI by Awp
#define S_K_AUTO                49 // Surivivor killed CI/SI by Auto
#define S_K_SPAS                50 // Surivivor killed CI/SI by Spas
#define S_K_MAGNUM              51 // Surivivor killed CI/SI by Magnum
#define S_K_PISTOL              52 // Surivivor killed CI/SI by Pistol
#define S_K_M60                 53 // Surivivor killed CI/SI by M60
#define S_K_GL                  54 // Surivivor killed CI/SI by Grenade Launcher

// Melee statistic
#define S_K_KATANA              55 // Surivivor killed CI/SI by Katana
#define S_K_AXE                 56 // Surivivor killed CI/SI by Axe
#define S_K_MACHATE             57 // Surivivor killed CI/SI by Machete
#define S_K_KNIFE               58 // Surivivor killed CI/SI by Knife
#define S_K_SAW                 59 // Surivivor killed CI/SI by Chainsaw
#define S_K_PITCHFORK           60 // Surivivor killed CI/SI by Pitchfork
#define S_K_SHOVEL              61 // Surivivor killed CI/SI by Shovel
#define S_K_GOLF                62 // Surivivor killed CI/SI by Golfclub
#define S_K_GUITAR              63 // Surivivor killed CI/SI by Guitar
#define S_K_TONFA               64 // Surivivor killed CI/SI by tonfa
#define S_K_BASEBALL            65 // Surivivor killed CI/SI by Baseball
#define S_K_CRICKET             66 // Surivivor killed CI/SI by Cricket
#define S_K_PAN                 67 // Surivivor killed CI/SI by Pan
#define S_K_CROWBAR             68 // Surivivor killed CI/SI by Crowbar

// Other statistic
#define S_K_PIPE                69 // Surivivor killed CI/SI by Pipe
#define S_K_MOLOTOV             70 // Surivivor killed CI/SI by Molotov
#define S_K_NONE                71 // Surivivor killed CI/SI by none (e.g. Throwables)

#define S_TH_MOLOTOV            72 // Surivivor throwed Molotov
#define S_TH_PIPE               73 // Surivivor throwed Pipe bomb
#define S_TH_VOMITJAR           74 // Surivivor throwed Vomitjar

#define S_MET_TANK              75 // Surivivor met Tank

#define CODE_STATS_SIZE         76 // Max array size

// Load state
#define STATE_LOADING           0
#define STATE_LOADED            1

// Other
#define HOUR                    3600


native int GetClientRank(int iClient);

native float GetClientRating(int iClient);

native int GetClientStats(int iClient, iCode);

native int GetClientPlayedTime(int iClient);

native int GetClientState(int iClient);

native float GetMinRankedHours();

native Database GetVersusStatsDatabase();

/**
 * Helper.
 */
stock float SecToHours(int seconds) {
	return float(seconds) / float(HOUR);
}

public SharedPlugin __pl_versus_stats =
{
	name = "versus_stats",
	file = "versus_stats.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_versus_stats_SetNTVOptional()
{
	MarkNativeAsOptional("GetClientRank");
	MarkNativeAsOptional("GetClientRating");
	MarkNativeAsOptional("GetClientStats");
	MarkNativeAsOptional("GetClientPlayedTime");
	MarkNativeAsOptional("GetClientState");
	MarkNativeAsOptional("GetMinRankedHours");
	MarkNativeAsOptional("GetVersusStatsDatabase");
}
#endif
