# About versus_stats
This plugin will add statistics of player actions in versus mode.

## Commands
`!rank` - Show your rank

`!stats` - Show your stats

`!stats <name|#userid>` - Show stats player

`!top` - Show Top Players

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

## Support
[ReadyUp](https://github.com/SirPlease/L4D2-Competitive-Rework/blob/master/addons/sourcemod/scripting/readyup.sp)
