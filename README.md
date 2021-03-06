# Healthbar
Draws a custom Healthbar for Npcs, Players or Breakables

## Initial setup
- Download the pack from the releases section ->
- Extract to svencoop_addon

## Server plugin installation:- 
- Edit your `default_plugins.txt` file and add the following code
```
"plugin"
{
	"name" "HealthBar"
	"script" "HealthBar"
}
```

- Add your cvars to your (listen)server.cfg file - see cvars below:

CVars (self explanatory, with default values provided if not set):

* `as_command healthbar_players 0`
* `as_command healthbar_npcs 1`
* `as_command healthbar_breakables 0`
* `as_command healthbar_size 0.5`


## Map script Installation:-

Simply call `HEALTHBAR::RegisterHealthBarEntity();` in the MapInit function of your map script. Example:

```
#include "env_healthbar"

void MapInit()
{
	HEALTHBAR::RegisterHealthBarEntity();
}
```
If you haven't made a mapscript for your map copy the above code and put it into a new .as file, name it then put the script in `scripts/maps`.
Then in your map's cfg file add `map_script <name of your script here>.as` as a cvar.

For more information on how to set up your map scripts, visit the Sven Co-op AngelScript Wiki:
https://github.com/baso88/SC_AngelScript/wiki/Map-Scripts

Once registered, you can load the fgd into the map editor of your choice and set up the entity.

Keys for configuring the entity:

| Name | Key | Description |
| ----| :---: | -------- |
| Target name |`"targetname"`| Setting a targetname will make the healthbar disabled first requiring a trigger to enable it |
| Target |`"target" "entityname"`| target entity to show a healthbar for. Can be a player, npc or breakable item ( with hud info enabled ) |			
| Healthbar sprite |`"sprite" "sprites/misc/healthbar.spr`"  | path to a custom sprite if desired. Otherwise uses default "sprites/misc/healthbar.spr" |
| Follow type |`"followtype" "f"`| sets how the healthbar should follow the entity ( follow origin, attachment point or fixed in healthbar origin ) |
| Offset |`"offset" "x y z"`| adds an offset for the health bar origin |
| Color |`"rendercolor" "r g b"`| change color of the sprite |
| FX Amount |`"renderamt" "0.0"`| set max render amount when healthbar is fully visible (255 by default) |
| Scale |`"scale" "0.0"`| resize the health bar, this is 0.3 by default |
| Draw distance |`"distance" "0.0"`| the distance you have to be to be able to see the health bar (default and maximum is 12048) |
| Flags |`"spawnflags" "1"`| forces the healthbar to stay on for the entity |
