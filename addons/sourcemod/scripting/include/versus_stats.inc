#if defined _versus_stats_included
 #endinput
#endif
#define _versus_stats_included

#define VERSUS_STATS_VERSION "2.0"
#define VERSUS_STATS_V_MAJOR 2
#define VERSUS_STATS_V_MINOR 0

// Infected Kill
#define SURVIVOR_K_CI           0  // Surivivor Killed Common Infected
#define SURVIVOR_K_SMOKER       1  // Surivivor Killed Smoker
#define SURVIVOR_K_BOOMER       2  // Surivivor Killed Boomer
#define SURVIVOR_K_HUNTER       3  // Surivivor Killed Hunter
#define SURVIVOR_K_SPITTER      4  // Surivivor Killed Spitter
#define SURVIVOR_K_JOCKEY       5  // Surivivor Killed Jockey
#define SURVIVOR_K_CHARGER      6  // Surivivor Killed Changer
#define SURVIVOR_K_WITCH        7  // Surivivor Killed Witch
#define SURVIVOR_AVG_DMG_TANK   8  // Surivivor avg Tank damage

// Infected Kill Headshot/One shot
#define SURVIVOR_K_CI_HS        9  // Surivivor Killed Common Infected (Headshot)
#define SURVIVOR_K_SI_HS        10 // Surivivor Killed Special Infected (Headshot)
#define SURVIVOR_K_WITCH_OS     11 // Surivivor Killed Witch in one shot

// Survivor event
#define SURVIVOR_SHOT           12 // Amount of surivivor shot
#define SURVIVOR_HIT            13 // Amount of surivivor hit
#define SURVIVOR_REVIVE         14 // Surivivor revived someone
#define SURVIVOR_REVIVED        15 // Surivivor is revived by someone
#define SURVIVOR_HURT           16 // Amount of damage hurt by SI
#define SURVIVOR_DMG            17 // Amount of damage made SI
#define SURVIVOR_DMG_TANK       18 // Amount of damage made tank
#define SURVIVOR_TEAMKILL       19 // Amount of Team kill
#define SURVIVOR_KILL           20 // Amount of Killing infected (last hit)
#define SURVIVOR_INCAPACITATED  21 // Amount of surivivor incapacated
#define SURVIVOR_DEATH          22 // Amount of death of surivivor

// Infected event
#define INFECTED_HURT           23 // Amount of damage hurt by Survivor
#define INFECTED_DMG            24 // Amount of damage made Survivor
#define INFECTED_KILL           25 // Amount of Killing Surivivor
#define INFECTED_INCAPACITATE   26 // Amount of Incapacitating Surivivor
#define INFECTED_DEATH          27 // Amount of death of infected

// Items event
#define SURVIVOR_PILLS          28 // Surivivor used Pills 
#define SURVIVOR_ADRENALINE     29 // Surivivor used Adrenaline 
#define SURVIVOR_MEDKIT         30 // Surivivor used Medikit 
#define SURVIVOR_HEALED         31 // Surivivor is healed by someone
#define SURVIVOR_SELF_HEALED    32 // Surivivor is healed by himself
#define SURVIVOR_HEAL           33 // Surivivor used Medikit for healing someone
#define SURVIVOR_DEFIBRILLATE   34 // Surivivor defibrillated someone
#define SURVIVOR_DEFIBRILLATED  35 // Surivivor is defibrillated by someone

// Gun statistic
#define SURVIVOR_K_SMG          36 // Surivivor killed CI/SI by SMG
#define SURVIVOR_K_SILENCED     37 // Surivivor killed CI/SI by SMG silenced
#define SURVIVOR_K_MP5          38 // Surivivor killed CI/SI by MP5
#define SURVIVOR_K_PUMP         39 // Surivivor killed CI/SI by Pump
#define SURVIVOR_K_CHROME       40 // Surivivor killed CI/SI by Chrome
#define SURVIVOR_K_SCOUT        41 // Surivivor killed CI/SI by Scout
#define SURVIVOR_K_M16          42 // Surivivor killed CI/SI by Rifle (M16)
#define SURVIVOR_K_DESERT       43 // Surivivor killed CI/SI by Desert
#define SURVIVOR_K_AK47         44 // Surivivor killed CI/SI by AK47
#define SURVIVOR_K_SG552        45 // Surivivor killed CI/SI by Sg552
#define SURVIVOR_K_HUNTING      46 // Surivivor killed CI/SI by Hunting
#define SURVIVOR_K_MILITARY     47 // Surivivor killed CI/SI by Military
#define SURVIVOR_K_AWP          48 // Surivivor killed CI/SI by Awp
#define SURVIVOR_K_AUTO         49 // Surivivor killed CI/SI by Auto
#define SURVIVOR_K_SPAS         50 // Surivivor killed CI/SI by Spas
#define SURVIVOR_K_MAGNUM       51 // Surivivor killed CI/SI by Magnum
#define SURVIVOR_K_PISTOL       52 // Surivivor killed CI/SI by Pistol
#define SURVIVOR_K_M60          53 // Surivivor killed CI/SI by M60
#define SURVIVOR_K_GL           54 // Surivivor killed CI/SI by Grenade Launcher

// Melee statistic
#define SURVIVOR_K_KATANA       55 // Surivivor killed CI/SI by Katana
#define SURVIVOR_K_AXE          56 // Surivivor killed CI/SI by Axe
#define SURVIVOR_K_MACHATE      57 // Surivivor killed CI/SI by Machete
#define SURVIVOR_K_KNIFE        58 // Surivivor killed CI/SI by Knife
#define SURVIVOR_K_SAW          59 // Surivivor killed CI/SI by Chainsaw
#define SURVIVOR_K_PITCHFORK    60 // Surivivor killed CI/SI by Pitchfork
#define SURVIVOR_K_SHOVEL       61 // Surivivor killed CI/SI by Shovel
#define SURVIVOR_K_GOLF         62 // Surivivor killed CI/SI by Golfclub
#define SURVIVOR_K_GUITAR       63 // Surivivor killed CI/SI by Guitar
#define SURVIVOR_K_TONFA        64 // Surivivor killed CI/SI by tonfa
#define SURVIVOR_K_BASEBALL     65 // Surivivor killed CI/SI by Baseball
#define SURVIVOR_K_CRICKET      66 // Surivivor killed CI/SI by Cricket
#define SURVIVOR_K_PAN          67 // Surivivor killed CI/SI by Pan
#define SURVIVOR_K_CROWBAR      68 // Surivivor killed CI/SI by Crowbar

// Other statistic
#define SURVIVOR_K_PIPE         69 // Surivivor killed CI/SI by Pipe
#define SURVIVOR_K_MOLOTOV      70 // Surivivor killed CI/SI by Molotov
#define SURVIVOR_K_NONE         71 // Surivivor killed CI/SI by none (e.g. Throwables)

#define SURVIVOR_TH_MOLOTOV     72 // Surivivor throwed Molotov
#define SURVIVOR_TH_PIPE        73 // Surivivor throwed Pipe bomb
#define SURVIVOR_TH_VOMITJAR    74 // Surivivor throwed Vomitjar

#define SURVIVOR_MET_TANK       75 // Surivivor met Tank

#define CODE_STATS_SIZE         76 // Max array size

// Load state
#define STATE_LOADING           0
#define STATE_LOADED            1

#define DATABASE                "versus_stats"


native int GetClientRank(int iClient);

native float GetClientRating(int iClient);

native int GetClientStats(int iClient, iCode);

native int GetClientPlayedTime(int iClient);

native int GetClientState(int iClient);

native float GetMinRankedHours();


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
}
#endif
