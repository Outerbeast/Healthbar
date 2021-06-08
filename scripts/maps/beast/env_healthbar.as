/* env_healthbar
Custom entity to draw a health bar above a target entity
by Outerbeast

Register - HEALTHBAR::RegisterHealthBarEntity(); - Call in MapInit

Keys:
* "target"          - target entity to show a healthbar for. Can be a player, npc or breakable item ( with hud info enabled )
* "sprite"          - path to a custom sprite if desired. Otherwise uses default
* "offset" "x y z"  - adds an offset for the health bar origin
* "scale" "0.0"     - resize the health bar, this is 0.3 by default
* "distance" "0.0"  - the distance you have to be to be able to see the health bar
* "spawnflags" "1"  - forces the healthbar to stay on for the entity

TO DO:
- Render the healthbars individually for each player
- Deal with monster_repel entities
*/
namespace HEALTHBAR
{

const string ENTITY_CLASSNAME = "env_healthbar";
const string strDefaultSpriteName = "sprites/misc/healthbar.spr";

bool blHealthBarEntityRegistered = false;

enum healthbarsettings
{
    PLAYERS     = 1 << 0,
    MONSTERS    = 1 << 1,
    BREAKABLES  = 1 << 2
};

const array<string> STR_EXCLUDED_NPCS = 
{
    "monster_generic",
    "monster_gman",
    "monster_furniture",
    "monster_snark",
    "monster_sqknest",
    "monster_rat",
    "monster_cockroach",
    "monster_leech",
    "monster_handgrenade",
    "monster_satchel",
    "monster_tripmine"
};

void RegisterHealthBarEntity()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "HEALTHBAR::env_healthbar", ENTITY_CLASSNAME );
    blHealthBarEntityRegistered = g_CustomEntityFuncs.IsCustomEntity( ENTITY_CLASSNAME );

    g_Game.PrecacheModel( strDefaultSpriteName );
    g_Game.PrecacheGeneric( strDefaultSpriteName );
}

void StartHealthBarMode(const uint iHealthBarSettings, const Vector vOriginOffset, const float flScale, const float flDrawDistance, const uint iSpawnFlags)
{
    if( !blHealthBarEntityRegistered )
        return;

    if( FlagSet( iHealthBarSettings, PLAYERS ) )
        g_Hooks.RegisterHook( Hooks::Player::PlayerSpawn, @PlayerSpawned );

    CBaseEntity@ pExistingHealthBar, pMonsterEntity, pBreakableEntity;

    while( ( @pExistingHealthBar = g_EntityFuncs.FindEntityByClassname( pExistingHealthBar, ENTITY_CLASSNAME ) ) !is null )
        g_EntityFuncs.Remove( pExistingHealthBar );

    if( FlagSet( iHealthBarSettings, MONSTERS ) )
    {
        while( ( @pMonsterEntity = g_EntityFuncs.FindEntityByClassname( pMonsterEntity, "monster_*" ) ) !is null )
        {   
            if( pMonsterEntity is null || !pMonsterEntity.IsMonster() )
                continue;

            if( STR_EXCLUDED_NPCS.find( pMonsterEntity.GetClassname() ) >= 0 )
                continue;
    
            SpawnEnvHealthBar( @pMonsterEntity, vOriginOffset, flScale, flDrawDistance, iSpawnFlags );
        }

        g_Hooks.RegisterHook( Hooks::Game::EntityCreated, @EntityCreated ); // Accounting for npcs spawning in later during the level
    }

    if( FlagSet( iHealthBarSettings, BREAKABLES ) )
    {   
        while( ( @pBreakableEntity = g_EntityFuncs.FindEntityByClassname( pBreakableEntity, "func_*" ) ) !is null )
        {
            if( !pBreakableEntity.IsBreakable() )
                continue;

            if( !pBreakableEntity.pev.SpawnFlagBitSet( 32 ) || pBreakableEntity.pev.SpawnFlagBitSet( 1 ) )
                continue;

            SpawnEnvHealthBar( @pBreakableEntity, vOriginOffset, flScale, flDrawDistance, iSpawnFlags );
        }
    }
}

HookReturnCode EntityCreated(CBaseEntity@ pEntity)
{
    if( pEntity !is null && pEntity.IsMonster() )
        g_Scheduler.SetTimeout( Schedulers(), "EntitySpawned", 0.05f, EHandle( @pEntity ) );

    return HOOK_CONTINUE;
}
// workaround...
final class Schedulers
{
    private void EntitySpawned(EHandle hEntity)
    {
        NpcSpawned( null, hEntity.GetEntity() );
    }
}

void NpcSpawned(CBaseMonster@ pSquadmaker, CBaseEntity@ pMonster) // Trigger this from a squadmaker via "function_name"
{
    if( blHealthBarEntityRegistered && pMonster !is null )
        SpawnEnvHealthBar( @pMonster, Vector( 0, 0, 0 ), 0.0f, 0.0f, 0 );
}

HookReturnCode PlayerSpawned(CBasePlayer@ pPlayer)
{
    if( pPlayer !is null )
        SpawnEnvHealthBar( @pPlayer, Vector( 0, 0, 0 ), 0.0f, 0.0f, 0 );

    return HOOK_CONTINUE;
}
// Credit to H2 for providing this function
bool FlagSet( uint iTargetBits, uint iFlags )
{
    if( ( iTargetBits & iFlags ) != 0 )
        return true;
    else
        return false;
}

void SpawnEnvHealthBar(CBaseEntity@ pTarget, const Vector vOriginOffset, const float flScale, const float flDrawDistance, const uint iSpawnFlags)
{
    if( pTarget is null ) 
       return;

    dictionary hlth;
    if( vOriginOffset != g_vecZero ) hlth ["offset"]        = vOriginOffset.ToString();
    if( flScale > 0 )                hlth ["scale"]         = string( flScale );
    if( flDrawDistance > 0 )         hlth ["distance"]      = string( flDrawDistance );
    if( iSpawnFlags > 0 )            hlth ["spawnflags"]    = string( iSpawnFlags );

    CBaseEntity@ pEnvHealthBar = g_EntityFuncs.CreateEntity( ENTITY_CLASSNAME, hlth, false );

    if( pEnvHealthBar is null )
       return;

    @pEnvHealthBar.pev.owner = pTarget.edict();
    //g_Game.AlertMessage( at_notice, "target: " + pTarget.entindex() + "\n" );
    g_EntityFuncs.DispatchSpawn( pEnvHealthBar.edict() );
}

class env_healthbar : ScriptBaseEntity
{
    PlayerPostThinkHook@ pPlayerPostThinkFunc = null;

    private EHandle hTrackedEntity, hHealthBar;

    private string strSpriteName = strDefaultSpriteName;

    private bool m_blOnOffState;

    private float m_flStartHealth;
    private float flDrawDistance = 12048;
    
    private Vector vOffset = Vector( 0, 0, 16 );

    bool KeyValue( const string& in szKey, const string& in szValue )
    {
        if( szKey == "sprite" ) 
        {
            strSpriteName = szValue;
            return true;
        }
        else if( szKey == "offset" ) 
        {
            g_Utility.StringToVector( vOffset, szValue );
            return true;
        }
        else if( szKey == "distance" ) 
        {
            flDrawDistance = atof( szValue );
            return true;
        }
        else
            return BaseClass.KeyValue( szKey, szValue );
    }

    void Precache()
    {
        g_Game.PrecacheModel( strSpriteName );
        g_Game.PrecacheGeneric( strSpriteName );
    }

    void Spawn()
    {
        self.Precache();
        self.pev.movetype   = MOVETYPE_NONE;
        self.pev.solid      = SOLID_NOT;
        self.pev.effects    |= EF_NODRAW;

        g_EntityFuncs.SetOrigin( self, self.pev.origin );

        if( self.pev.scale <= 0.0f )
            self.pev.scale = 0.3f;

        SetUse( UseFunction( this.TrackUse ) );
        SetThink( ThinkFunction( this.TrackEntity ) );
        //  Run automatically if this has no targetname.
        if( self.GetTargetname().IsEmpty() ) self.Use( self, self, USE_ON );

        if( !self.pev.SpawnFlagBitSet( 1 ) )
        {
            @pPlayerPostThinkFunc = PlayerPostThinkHook( this.AimingPlayer );
            g_Hooks.RegisterHook( Hooks::Player::PlayerPostThink, @pPlayerPostThinkFunc );
        }
    }

    void UpdateOnRemove()
    {
        if( hHealthBar )
            g_EntityFuncs.Remove( hHealthBar.GetEntity() );
        
        BaseClass.UpdateOnRemove();

        if( pPlayerPostThinkFunc !is null )
            g_Hooks.RemoveHook( Hooks::Player::PlayerPostThink, @pPlayerPostThinkFunc );
    }

    void TrackEntity()
    {
        CBaseEntity@ pTrackedEntity = hTrackedEntity.GetEntity();

        if( pTrackedEntity !is null && ( pTrackedEntity.IsPlayer() || pTrackedEntity.IsMonster() || pTrackedEntity.IsBreakable() ) )
        {
            if( !hHealthBar )
                CreateHealthBar();

            if( hHealthBar )
            {
                CSprite@ pHealthBar = cast<CSprite@>( hHealthBar.GetEntity() );

                if( !pTrackedEntity.IsAlive() )
                {
                    if( pTrackedEntity.IsRevivable() )
                        Hide();
                    else
                    {
                        g_EntityFuncs.Remove( self );
                        return;
                    }
                }
                else// Save more cpu speed because we only need to adjust it when it's alive.
                {
                    // 1.0 = 100%
                    float flPercentHealth   = Math.min( 1.f, GetHealth() / GetMaxHealth() );
                    float flCurrentFrame    = flPercentHealth * GetMaxFrame();
                    // Fix zero current frame if it's still alive.
                    if( floor(flCurrentFrame) <= 0 && flPercentHealth > 0 )
                        flCurrentFrame = Math.min( 1, GetMaxFrame() );
                    // This is horribly wrong.
                    // From API doc: `Advances this sprite's frame by the given amount of frames.
                    //pHealthBar.Animate(iPercentHealth);

                    //  This is correct(?).
                    pHealthBar.pev.frame = flCurrentFrame;
                    pHealthBar.SetScale( self.pev.scale );

                    if( pTrackedEntity.IsBSPModel() )
                        g_EntityFuncs.SetOrigin( pHealthBar, pTrackedEntity.pev.absmin + ( pTrackedEntity.pev.size * 0.5 ) + Vector( 0, 0, pTrackedEntity.pev.absmax.z ) );
                    else
                        g_EntityFuncs.SetOrigin( pHealthBar, pTrackedEntity.GetOrigin() + pTrackedEntity.pev.view_ofs + vOffset );
                }
            }
        }
        else
        {
            g_EntityFuncs.Remove( self );
            return;
        }

        self.pev.nextthink = g_Engine.time + 0.01f;
    }
    //  Trigger-able.
    void TrackUse(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue = 0.0f)
    {
        if( !self.ShouldToggle( useType, m_blOnOffState ) )
            return;

        m_blOnOffState = ( useType == USE_TOGGLE ? !m_blOnOffState : useType == USE_ON );

        if( !m_blOnOffState )
        {
            self.pev.nextthink = 0;
            Hide();
            return;
        }

        CBaseEntity@ pTrackedEntity;
        string strTarget = string( self.pev.target );
        strTarget.Trim();

        if( !strTarget.IsEmpty() && strTarget != self.GetTargetname() )
            @pTrackedEntity = g_EntityFuncs.FindEntityByTargetname( pTrackedEntity, strTarget );
        else
            @pTrackedEntity = g_EntityFuncs.Instance( self.pev.owner );

        if( pTrackedEntity !is null )
        {
            m_flStartHealth = pTrackedEntity.pev.health;
            hTrackedEntity = pTrackedEntity;
        }
        self.pev.nextthink = g_Engine.time + 0.01f;
    }

    void Show()
    {
        if( !hHealthBar )
            return;
        
        hHealthBar.GetEntity().pev.renderamt = 255.0f;
    }

    void Hide()
    {
        if( !hHealthBar )
            return;
        
        hHealthBar.GetEntity().pev.renderamt = 0.0f;
    }

    void CreateHealthBar()
    {
        if( !hTrackedEntity )
            return;

        CSprite@ pHealthBar = g_EntityFuncs.CreateSprite( strSpriteName, hTrackedEntity.GetEntity().GetOrigin(), false, 0.0f );
        pHealthBar.SetScale( self.pev.scale );
        pHealthBar.pev.rendermode = kRenderTransAdd;
        pHealthBar.pev.nextthink = 0;
        //  `CSprite::Frames` is broken.
        //g_Game.AlertMessage( at_notice, "pHealthBar Frames(): " + pHealthBar.Frames() + "\n" );

        //  Is this really necessary ???
        pHealthBar.pev.frame = GetMaxFrame();
        //g_Game.AlertMessage( at_notice, "env_healthbar GetMaxFrame(): " + GetMaxFrame() + "\n" );

        if( self.pev.SpawnFlagBitSet( 1 ) )
            Show();

        hHealthBar = pHealthBar;
    }

    float GetHealth()
    {
        if( hTrackedEntity ) return Math.clamp( 0, hTrackedEntity.GetEntity().pev.health, GetMaxHealth() );
            return 0;
    }

    float GetMaxHealth()
    {
        if( hTrackedEntity )
        {
            float flMaxHP = hTrackedEntity.GetEntity().pev.max_health;
            if( flMaxHP <= 0 ) flMaxHP = m_flStartHealth;
            if( flMaxHP <= 0 ) flMaxHP = 1; //  "Divided by Zero" still haunts you...
            return flMaxHP;
        }
        return 1;
    }

    int GetMaxFrame()
    {
        //  Zero is minimum.
        if( hHealthBar ) return Math.max( 0, g_EngineFuncs.ModelFrames( g_EngineFuncs.ModelIndex( hHealthBar.GetEntity().pev.model ) ) - 1 );
        return 0;
    }

    protected HookReturnCode AimingPlayer(CBasePlayer@ pPlayer)
    {
        if( pPlayer is null )
            return HOOK_CONTINUE;
        
        CBaseEntity@ pAimedEntity = g_Utility.FindEntityForward( pPlayer, flDrawDistance );

        if( hHealthBar )
        {
            if( pAimedEntity is hTrackedEntity.GetEntity() )
                Show();
            else
                Hide();
        }
        return HOOK_CONTINUE;
    }
}

}
/* Special thanks to:
- Cadaver: sprites
- Snarkeh: original concept and implementation in Command&Conquer campaign
- AnggaraNothing and H2 for scripting support 
*/