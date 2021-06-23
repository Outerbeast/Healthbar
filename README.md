# Healthbar
Draws a custom Healthbar for Npcs, Players or Breakables

Server plugin installation:- 
- Download the pack from the releases section ->
- Extract to svencoop_addon
- Edit your `default_plugins.txt` file and add the following code

"plugin"

{

	"name" "HealthBar"
	"script" "HealthBar"

}
	

- Add your cvars to your (listen)server.cfg file - see cvars below:

CVars (self explanatory, will default values provided if not set):

* `as_command healthbar_players 0`
* `as_command healthbar_npcs 1`
* `as_command healthbar_breakables 0`
* `as_command healthbar_size 0.5`


Map script Installation:-

Simply call RegisterHealthBarEntity(); in the MapInit function of your map script. Example

```
#include "beast/env_healthbar"

void MapInit()
{
	HEALTHBAR::RegisterHealthBarEntity();
}
```
For more information on how to set up your map scripts, visit the Sven Co-op AngelScript Wiki:
https://github.com/baso88/SC_AngelScript/wiki/Map-Scripts

Once registered, you can load the fgd into the map editor of your choice and set up the entity.

Keys for configuring the entity:
* `"target"`          	- target entity to show a healthbar for. Can be a player, npc or breakable item. This is required
* `"sprite"`      	- path to a custom sprite if desired. Otherwise uses default
* `"offset" "x y z"`  	- adds an offset for the health bar origin
* `"scale" "0.3"`     	- resize the health bar, this is 0.3 by default
* `"distance" "0.0"`  	- the distance you have to be to be able to see the health bar
* `"spawnflags" "1"`  	- forces the healthbar to stay on for the entity
