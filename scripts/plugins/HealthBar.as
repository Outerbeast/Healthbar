/*Healthbar plugin
Draws a health bar above players, npcs or breakables
by Outerbeast
Installation:-
Add this code to your default_plugins.txt file

	"plugin"
 	{
        "name" "HealthBar"
		"script" "HealthBar"
	}
then save.

CVars (set 1 or 0 to turn on or off ):-

as_command healthbar_players 0
as_command healthbar_npcs 1
as_command healthbar_breakables 0
as_command healthbar_size 0.5

These are default values if they are not added to the cfg, set them to whichever you like
*/
#include "../maps/env_healthbar"

CCVar cvarHealthBarEnabled( "healthbar_enable", 1, "Enable healthbar mode", ConCommandFlag::AdminOnly );
CCVar cvarHealthBarPlayers( "healthbar_players", 0, "Turn on healthbar for players", ConCommandFlag::AdminOnly );
CCVar cvarHealthBarNpcs( "healthbar_npcs", 1, "Turn on healthbar for npcs", ConCommandFlag::AdminOnly );
CCVar cvarHealthBarBreakables( "healthbar_breakables", 0, "Turn on healthbar for breakables", ConCommandFlag::AdminOnly );
CCVar cvarHealthBarSize( "healthbar_size", 0.5f, "Change healthbar size", ConCommandFlag::AdminOnly );

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Outerbeast" );
	g_Module.ScriptInfo.SetContactInfo( "svencoopedia.fandom.com" );
}

void MapInit()
{
    if( cvarHealthBarEnabled.GetInt() > 0 )
        HEALTHBAR::RegisterHealthBarEntity();
}

void MapStart()
{
    uint onplayers      = cvarHealthBarPlayers.GetInt()     > 0 ? 1 : 0;
    uint onnpcs         = cvarHealthBarNpcs.GetInt()        > 0 ? 1 : 0;
    uint onbreakables   = cvarHealthBarBreakables.GetInt()  > 0 ? 1 : 0;

    HEALTHBAR::StartHealthBarMode( ( onplayers << 0 | onnpcs << 1 | onbreakables << 2 ), Vector( 0, 0, 23 ), cvarHealthBarSize.GetFloat(), 0.0f, 0 );
}
