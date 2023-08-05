# About versus_stats
This plugin will add statistics of player actions in versus mode.

All players are ranked according to the level of individual skills.

Web version [here](https://github.com/TouchMe-Inc/web_versus_stats).

## Install
Add new connection data to the `databases.cfg` file:
```
  ...
	"versus_stats"
	{
		"driver"			"mysql"
		"host"				"<your host>"
		"database"			"<your db>"
		"user"				"<your user>"
		"pass"				"<your pass>"
	}
  ...
```

## ConVars
| ConVar               | Value         | Description                                                                        |
| -------------------- | ------------- | ---------------------------------------------------------------------------------- |
| vs_max_last_visit    | 2592000       | The maximum time since the last visit that a record will be found in the database. |
| vs_min_ranked_hours  | 12.0          | Minimum number of hours to display player statistics.                              |
| vs_s_kill_cost       | 1.0           | (positive)                                                                         |
| vs_s_kill_ci_cost    | 0.02          | (positive) Cost of killing common infected                                         |
| vs_s_death_cost      | 4.0           | (negative) Death cost per survivor team                                            |
| vs_s_incapacitated_cost| 2.0         | (negative) Cost of incapacitation per team survivors                               |
| vs_s_teamkill_cost   | 16.0          | (negative) Cost of killing your teammate                                           |
| vs_i_incapacitate_cost | 2.0         | (positive) Incapacitation cost per Infected team                                   |
| vs_i_kill_cost       | 1.0           | (positive)                                                                         |


## About vs_rankstats
The plugin adds the ability to view the rank and statistics of the player.

### Commands
`!rank` - Show your rank

`!rankstats` - Show your stats

`!rankstats <name|#userid>` - Show stats player

### What statistics will be displayed?
`configs/vs_rankstats.ini` contains the [codestats](https://github.com/TouchMe-Inc/l4d2_versus_stats/blob/main/addons/sourcemod/scripting/include/versus_stats.inc) of all items that will be displayed.

## About vs_top
The plugin adds the ability to view the best players.

### Commands
`!top` - Show top players

`!top <offset>` - Show top players with offset

## Support
[ReadyUp](https://github.com/SirPlease/L4D2-Competitive-Rework/blob/master/addons/sourcemod/scripting/readyup.sp)

