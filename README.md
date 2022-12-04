# About versus_stats
This plugin will add statistics of player actions in versus mode.

## Cvars
`vs_max_last_visit 2592000` - The maximum time since the last visit that a record will be found in the database.

`vs_min_ranked_hours 3.0` - Minimum number of hours to display player statistics.

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

## About vs_rankstats
The plugin adds the ability to view the rank and statistics of the player.

### Commands
`!rank` - Show your rank

`!rankstats` - Show your stats

`!rankstats <name|#userid>` - Show stats player

### What statistics will be displayed?
`configs/vs_rankstats.ini` contains the [codestats](https://github.com/TouchMe-Inc/l4d2_versus_stats/blob/v2/addons/sourcemod/scripting/include/versus_stats.inc) of all items that will be displayed. 

## Support
[ReadyUp](https://github.com/SirPlease/L4D2-Competitive-Rework/blob/master/addons/sourcemod/scripting/readyup.sp)

