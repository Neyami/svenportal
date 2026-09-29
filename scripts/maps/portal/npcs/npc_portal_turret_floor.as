/*
	Author: Nero

	From Portal npc_portal_turret_floor.cpp

	Yes, I know there is a ton of unnecessary stuff in here, blyat
*/

namespace npc_portal_turret_floor
{

const string FLOOR_TURRET_PORTAL_MODEL		= "models/portal/props/Turret_01.mdl";
const string FLOOR_TURRET_GLOW_SPRITE			= "sprites/glow01.spr"; //"sprites/glow1.vmt";
const string FLOOR_TURRET_LASER_SPRITE		= "sprites/laserbeam.spr";
const string FLOOR_TURRET_HALO_SPRITE			= "sprites/laserdot.spr"; //"sprites/redlaserglow.vmt"

const int PORTAL_FLOOR_TURRET_RANGE			= 1500;
const float PORTAL_FLOOR_TURRET_MAX_SHOT_DELAY	= 2.5;
const float FLOOR_TURRET_MAX_WAIT				= 5.0;
const float FLOOR_TURRET_SHORT_WAIT			= 2.0;	// Used for FAST_RETIRE spawnflag
const float FLOOR_TURRET_PING_TIME				= 1.0;	//LPB!!

const float TURRET_FLOOR_BULLET_FORCE_MULTIPLIER	= 0.4;

const string NPC_DISPLAYNAME							= "Turret";

const float NPC_HEALTH 									= 210.0;
const float DAMAGE_BULLET								= 3.0; //def.AddAmmoType("Pistol",			DMG_BULLET,					TRACER_LINE_AND_WHIZ,	"sk_plr_dmg_pistol",		"sk_npc_dmg_pistol",		"sk_max_pistol",		BULLET_IMPULSE(200, 1225), 0 );

const float PLAYER_FATAL_FALL_SPEED				= 1024.0; // approx 60 feet
const float PLAYER_MAX_SAFE_FALL_SPEED			= 580.0; // approx 20 feet
const float DAMAGE_FOR_FALL_SPEED				= 100.0 / ( PLAYER_FATAL_FALL_SPEED - PLAYER_MAX_SAFE_FALL_SPEED ); // damage per unit per second.
const float PLAYER_MIN_BOUNCE_SPEED				= 200.0;
const float PLAYER_FALL_PUNCH_THRESHHOLD	= 350.0; // won't punch player's screen/make scrape noise unless player falling at least this fast.

const Vector EYE_OFFSETS									= Vector( 14, 0, 36.5 );
const float MAX_SPRITE_SCALE							= 64.0;

const float LASER_WIDTH									= 8.0;

const int MAX_MISS_CANDIDATES						= 16;

//CLIENT
//const float FLOOR_TURRET_PORTAL_END_POINT_PULSE_SCALE	= 4.0;
const float FLOOR_TURRET_PORTAL_LASER_RANGE	= 8192.0;
//CLIENT

// useful cosines
//const float DOT_1DEGREE		= 0.9998476951564;
//const float DOT_2DEGREE		= 0.9993908270191;
//const float DOT_3DEGREE		= 0.9986295347546;
//const float DOT_4DEGREE		= 0.9975640502598;
//const float DOT_5DEGREE		= 0.9961946980917;
//const float DOT_6DEGREE		= 0.9945218953683;
//const float DOT_7DEGREE		= 0.9925461516413;
//const float DOT_8DEGREE		= 0.9902680687416;
//const float DOT_9DEGREE		= 0.9876883405951;
const float DOT_10DEGREE		= 0.9848077530122;
//const float DOT_15DEGREE		= 0.9659258262891;
//const float DOT_20DEGREE		= 0.9396926207859;
//const float DOT_25DEGREE		= 0.9063077870367;
//const float DOT_30DEGREE		= 0.866025403784;
//const float DOT_45DEGREE		= 0.707106781187;

//const Vect VECTOR_CONE_1DEGREES		= Vector( 0.00873, 0.00873, 0.00873 );
//const Vect VECTOR_CONE_2DEGREES		= Vector( 0.01745, 0.01745, 0.01745 );
//const Vect VECTOR_CONE_3DEGREES		= Vector( 0.02618, 0.02618, 0.02618 );
const Vector VECTOR_CONE_4DEGREES		= Vector( 0.03490, 0.03490, 0.03490 );
//const Vect VECTOR_CONE_5DEGREES		= Vector( 0.04362, 0.04362, 0.04362 );
//const Vect VECTOR_CONE_6DEGREES		= Vector( 0.05234, 0.05234, 0.05234 );
//const Vect VECTOR_CONE_7DEGREES		= Vector( 0.06105, 0.06105, 0.06105 );
//const Vect VECTOR_CONE_8DEGREES		= Vector( 0.06976, 0.06976, 0.06976 );
//const Vect VECTOR_CONE_9DEGREES		= Vector( 0.07846, 0.07846, 0.07846 );
//const Vect VECTOR_CONE_10DEGREES	= Vector( 0.08716, 0.08716, 0.08716 );
//const Vect VECTOR_CONE_15DEGREES	= Vector( 0.13053, 0.13053, 0.13053 );
//const Vect VECTOR_CONE_20DEGREES	= Vector( 0.17365, 0.17365, 0.17365 );

enum portalTurretState_e
{
	PORTAL_TURRET_DISABLED = TURRET_STATE_TOTAL,
	PORTAL_TURRET_COLLIDE,
	PORTAL_TURRET_PICKUP,
	PORTAL_TURRET_SHOTAT,
	PORTAL_TURRET_DISSOLVED,

	PORTAL_TURRET_STATE_TOTAL
};

enum turretState_e
{
	TURRET_SEARCHING = 0,
	TURRET_AUTO_SEARCHING,
	TURRET_ACTIVE,
	TURRET_SUPPRESSING,
	TURRET_DEPLOYING,
	TURRET_RETIRING,
	TURRET_TIPPED,
	TURRET_SELF_DESTRUCTING,

	TURRET_STATE_TOTAL
};

enum eyeState_t
{
	TURRET_EYE_SEE_TARGET = 0,			//Sees the target, bright and big
	TURRET_EYE_SEEKING_TARGET,		//Looking for a target, blinking (bright)
	TURRET_EYE_DORMANT,				//Not active
	TURRET_EYE_DEAD,				//Completely invisible
	TURRET_EYE_DISABLED,			//Turned off, must be reactivated before it'll deploy again (completely invisible)
	TURRET_EYE_ALARM				// On side, but warning player to pick it back up
};

enum WeaponProficiency_t
{
	WEAPON_PROFICIENCY_POOR = 0,
	WEAPON_PROFICIENCY_AVERAGE,
	WEAPON_PROFICIENCY_GOOD,
	WEAPON_PROFICIENCY_VERY_GOOD,
	WEAPON_PROFICIENCY_PERFECT
};

// BUG: These all stomp Base NPC spawnflags. Any Base NPC code called by this
//		this class may have undesired side effects due to these being set.
const int SF_FLOOR_TURRET_AUTOACTIVATE	= 0x00000020; //32
const int SF_FLOOR_TURRET_STARTINACTIVE	= 0x00000040; //64
const int SF_FLOOR_TURRET_FASTRETIRE		= 0x00000080; //128
const int SF_FLOOR_TURRET_OUT_OF_AMMO	= 0x00000100; //256
const int SF_FLOOR_TURRET_CITIZEN				= 0x00000200; //512 // Citizen modified turret

enum sounds_e
{
	//BASE SOUNDS
	SND_RETIRE = 0, //NPC_FloorTurret.Retire
	SND_DEPLOY, //NPC_FloorTurret.Deploy
	SND_MOVE, //NPC_FloorTurret.Move
	SND_ACTIVATE, //NPC_FloorTurret.Activate
	SND_ALERT, //NPC_FloorTurret.Alert
	SND_SHOOT1, //NPC_FloorTurret.ShotSounds
	SND_SHOOT2,
	SND_SHOOT3,
	SND_DIE, //NPC_FloorTurret.Die
	SND_ALARM, //NPC_FloorTurret.Alarm
	SND_PING, //NPC_FloorTurret.Ping
	SND_DRYFIRE, //NPC_FloorTurret.DryFire
	//SND_DESTRUCT1, //NPC_FloorTurret.Destruct
	//SND_DESTRUCT2,
	//SND_DESTRUCT3,
	//SND_DESTRUCT4,
	//SND_DESTRUCT5,
	//SND_DESTRUCT6,

	//PORTAL SOUNDS
	SND_TALK_SEARCH1, //NPC_FloorTurret.TalkSearch
	SND_TALK_SEARCH2,
	SND_TALK_SEARCH3,
	SND_TALK_AUTOSEARCH1, //NPC_FloorTurret.TalkAutosearch
	SND_TALK_AUTOSEARCH2,
	SND_TALK_AUTOSEARCH3,
	SND_TALK_AUTOSEARCH4,
	SND_TALK_AUTOSEARCH5,
	SND_TALK_ACTIVE1, //NPC_FloorTurret.TalkActive
	SND_TALK_ACTIVE2,
	SND_TALK_ACTIVE3,
	SND_TALK_ACTIVE4,
	SND_TALK_ACTIVE5,
	SND_TALK_ACTIVE6,
	SND_TALK_ACTIVE7,
	SND_TALK_DEPLOY1, //NPC_FloorTurret.TalkDeploy
	SND_TALK_DEPLOY2,
	SND_TALK_DEPLOY3,
	SND_TALK_DEPLOY4,
	SND_TALK_DEPLOY5,
	SND_TALK_RETIRE1, //NPC_FloorTurret.TalkRetire
	SND_TALK_RETIRE2,
	SND_TALK_RETIRE3,
	SND_TALK_RETIRE4,
	SND_TALK_RETIRE5,
	SND_TALK_RETIRE6,
	SND_TALK_TIPPED1, //NPC_FloorTurret.TalkTipped
	SND_TALK_TIPPED2,
	SND_TALK_TIPPED3,
	SND_TALK_TIPPED4,
	SND_TALK_DISABLED1, //NPC_FloorTurret.TalkDisabled
	SND_TALK_DISABLED2,
	SND_TALK_DISABLED3,
	SND_TALK_DISABLED4,
	SND_TALK_DISABLED5,
	SND_TALK_DISABLED6,
	SND_TALK_COLLIDE1, //NPC_FloorTurret.TalkCollide
	SND_TALK_COLLIDE2,
	SND_TALK_COLLIDE3,
	SND_TALK_COLLIDE4,
	SND_TALK_COLLIDE5,
	SND_TALK_PICKUP1, //NPC_FloorTurret.TalkPickup
	SND_TALK_PICKUP2,
	SND_TALK_PICKUP3,
	SND_TALK_PICKUP4,
	SND_TALK_PICKUP5,
	SND_TALK_PICKUP6,
	SND_TALK_PICKUP7,
	SND_TALK_SHOTAT1, //NPC_FloorTurret.TalkShotAt
	SND_TALK_SHOTAT2,
	SND_TALK_SHOTAT3,
	SND_TALK_DISSOLVED //NPC_FloorTurret.TalkDissolved
};

const array<string> arrsSounds =
{
	//BASE SOUNDS
	"hl2/npc/turret_floor/retract.wav",
	"hl2/npc/turret_floor/deploy.wav",
	"hl2/npc/turret_wall/turret_loop1.wav",
	"hl2/npc/turret_floor/active.wav",
	"hl2/npc/turret_floor/alert.wav",
	"hl2/npc/turret/turret_fire_4x_01.wav",
	"hl2/npc/turret/turret_fire_4x_02.wav",
	"hl2/npc/turret/turret_fire_4x_03.wav",
	"hl2/npc/turret_floor/die.wav",
	"hl2/npc/turret_floor/alarm.wav",
	"hl2/npc/turret_floor/ping.wav",
	"hl2/weapons/shotgun/shotgun_empty.wav",
	//"props/explosions/explo_generic_med_01.wav",
	//"props/explosions/explo_generic_med_02.wav",
	//"props/explosions/explo_generic_med_03.wav",
	//"props/explosions/explo_generic_med_04.wav",
	//"props/explosions/explo_generic_med_05.wav",
	//"props/explosions/explo_generic_med_06.wav",

	//PORTAL SOUNDS
	"portal/npc/turret_floor/turret_search_1.wav",
	"portal/npc/turret_floor/turret_search_2.wav",
	"portal/npc/turret_floor/turret_search_4.wav",
	"portal/npc/turret_floor/turret_autosearch_1.wav",
	"portal/npc/turret_floor/turret_autosearch_2.wav",
	"portal/npc/turret_floor/turret_autosearch_4.wav",
	"portal/npc/turret_floor/turret_autosearch_5.wav",
	"portal/npc/turret_floor/turret_autosearch_6.wav",
	"portal/npc/turret_floor/turret_active_1.wav",
	"portal/npc/turret_floor/turret_active_2.wav",
	"portal/npc/turret_floor/turret_active_4.wav",
	"portal/npc/turret_floor/turret_active_5.wav",
	"portal/npc/turret_floor/turret_active_6.wav",
	"portal/npc/turret_floor/turret_active_7.wav",
	"portal/npc/turret_floor/turret_active_8.wav",
	"portal/npc/turret_floor/turret_deploy_1.wav",
	"portal/npc/turret_floor/turret_deploy_2.wav",
	"portal/npc/turret_floor/turret_deploy_4.wav",
	"portal/npc/turret_floor/turret_deploy_5.wav",
	"portal/npc/turret_floor/turret_deploy_6.wav",
	"portal/npc/turret_floor/turret_retire_1.wav",
	"portal/npc/turret_floor/turret_retire_2.wav",
	"portal/npc/turret_floor/turret_retire_4.wav",
	"portal/npc/turret_floor/turret_retire_5.wav",
	"portal/npc/turret_floor/turret_retire_6.wav",
	"portal/npc/turret_floor/turret_retire_7.wav",
	"portal/npc/turret_floor/turret_tipped_2.wav",
	"portal/npc/turret_floor/turret_tipped_4.wav",
	"portal/npc/turret_floor/turret_tipped_5.wav",
	"portal/npc/turret_floor/turret_tipped_6.wav",
	"portal/npc/turret_floor/turret_disabled_2.wav",
	"portal/npc/turret_floor/turret_disabled_4.wav",
	"portal/npc/turret_floor/turret_disabled_5.wav",
	"portal/npc/turret_floor/turret_disabled_6.wav",
	"portal/npc/turret_floor/turret_disabled_7.wav",
	"portal/npc/turret_floor/turret_disabled_8.wav",
	"portal/npc/turret_floor/turret_collide_1.wav",
	"portal/npc/turret_floor/turret_collide_2.wav",
	"portal/npc/turret_floor/turret_collide_3.wav",
	"portal/npc/turret_floor/turret_collide_4.wav",
	"portal/npc/turret_floor/turret_collide_5.wav",
	"portal/npc/turret_floor/turret_pickup_1.wav",
	"portal/npc/turret_floor/turret_pickup_3.wav",
	"portal/npc/turret_floor/turret_pickup_6.wav",
	"portal/npc/turret_floor/turret_pickup_7.wav",
	"portal/npc/turret_floor/turret_pickup_8.wav",
	"portal/npc/turret_floor/turret_pickup_9.wav",
	"portal/npc/turret_floor/turret_pickup_10.wav",
	"portal/npc/turret_floor/turret_shotat_1.wav",
	"portal/npc/turret_floor/turret_shotat_2.wav",
	"portal/npc/turret_floor/turret_shotat_3.wav",
	"portal/npc/turret_floor/turret_fizzler_1.wav"
};

//NPC_FloorTurret.TalkSupress

class CNPC_Portal_FloorTurret : ScriptBaseMonsterEntity //CNPC_FloorTurret
{
	//BASECLASS
	//matrix3x4_t m_muzzleToWorld;
	//protected int		m_muzzleToWorldTick;
	protected int		m_iAmmoType;

	protected bool	m_bAutoStart;
	protected bool	m_bActive;		//Denotes the turret is deployed and looking for targets
	protected bool	m_bBlinkState;
	protected bool	m_bEnabled;		//Denotes whether the turret is able to deploy or not
	protected bool	m_bNoAlarmSounds;
	protected bool	m_bSelfDestructing;	// Going to blow up

	//protected float	m_flDestructStartTime;
	protected float	m_flShotTime;
	protected float	m_flLastSight;
	protected float	m_flThrashTime;
	protected float	m_flPingTime;
	protected float	m_flNextActivateSoundTime;
	protected bool	m_bCarriedByPlayer;
	/*
	protected CHandle<CBaseCombatCharacter> m_hLastNPCToKickMe;		// Stores the last NPC who tried to knock me over
	protected float	m_flKnockOverFailedTime;						// Time at which we should tell the NPC that he failed to knock me over*/

	protected Vector	m_vecGoalAngles; //QAngle

	//protected int						m_iEyeAttachment;
	protected int						m_iMuzzleAttachment;
	protected eyeState_t				m_iEyeState;
	private EHandle m_hEyeGlow; ////protected CHandle<CSprite>		m_hEyeGlow;
	private CSprite@ m_pEyeGlow
	{
		get const { return cast<CSprite@>(m_hEyeGlow.GetEntity()); }
		set { m_hEyeGlow = EHandle(@value); }
	}

	private float m_flStartScale;
	private float m_flDestScale;
	private float m_flSpriteScale;
	private float m_flScaleTime;
	private float m_flScaleTimeStart;
	private int m_nStartBrightness;
	private int m_nDestBrightness;
	private int m_nBrightness;
	private float m_flBrightnessTime;
	private float m_flBrightnessTimeStart;

	/*protected CHandle<CBeam>			m_hLaser;
	protected CHandle<CTurretTipController>	m_pMotionController;

	protected CHandle<CParticleSystem>	m_hFizzleEffect;*/
	protected Vector	m_vecEnemyLKP;
	//BASECLASS

	//CHandle<CRopeKeyframe>	m_hRopes[ PORTAL_FLOOR_TURRET_NUM_ROPES ];

	private bool m_bOutOfAmmo; //CNetworkVar
	private bool m_bLaserOn; //CNetworkVar
	//private int m_sLaserHaloSprite; //CNetworkVar

	private array<int> m_iBarrelAttachments( 4 );
	private bool m_bShootWithBottomBarrels;
	private bool m_bDamageForce;

	private float m_fSearchSpeed;
	private float m_fMovingTargetThreashold; //[sic]
	private float m_flDistToEnemy;

	private turretState_e	m_iLastState;
	private float m_fNextTalk;
	private bool m_bDelayTippedTalk;
	private bool m_bHasGreetedEnemy;

	private float m_flPitch;
	private float m_flYaw;

	private bool m_bDissolving;

	private float m_flTargetFindTime;


	//PLAYER CARRY STUFF
	protected EHandle m_hCarryingPlayer;
	protected CBasePlayer@ m_pCarryingPlayer
	{
		get const { return cast<CBasePlayer@>(m_hCarryingPlayer.GetEntity()); } 
		set { m_hCarryingPlayer = EHandle(@value); }
	}

	float m_flDropDelay;
	float m_flHoldDistance = 96.0;
	float m_flStiffness = 16.0; //spring strength
	float m_flDamping = 0.4; //damping (VERY important)

	//bool m_bAligning;
	
	Vector m_angPreferredCarryAngles;
	//PLAYER CARRY STUFF

	//CLIENT STUFF BLYAT
	private EHandle m_hBeam;
	private CBeam@ m_pBeam
	{
		get const { return cast<CBeam@>(m_hBeam.GetEntity()); }
		set { m_hBeam = EHandle(@value); }
	}

	private EHandle m_hLaserHalo;
	private CSprite@ m_pLaserHalo
	{
		get const { return cast<CSprite@>(m_hLaserHalo.GetEntity()); }
		set { m_hLaserHalo = EHandle(@value); }
	}

	//private float m_fPulseOffset;

	private bool m_bBeamFlickerOff;
	private float m_fBeamFlickerTime;

	~CNPC_Portal_FloorTurret()
	{
		LaserOff();

		if( m_pBeam !is null )
			g_EntityFuncs.Remove( m_pBeam ); //m_pBeam.SUB_Remove();

		if( m_pLaserHalo !is null )
			g_EntityFuncs.Remove( m_pLaserHalo );

		if( m_pEyeGlow !is null )
			g_EntityFuncs.Remove( m_pEyeGlow );
	}
	//CLIENT STUFF BLYAT

	void Spawn()
	{
		Precache();

		const string sModelName = GetModelName();
		SetModel( !sModelName.IsEmpty() ? sModelName : FLOOR_TURRET_PORTAL_MODEL ); //SetModel( ( pModelName and pModelName[ 0 ] != '\0' ) ? pModelName : FLOOR_TURRET_MODEL );

		//CLIENT
		@m_pBeam = null;
		//m_fPulseOffset = Math.RandomFloat( 0.0, 2.0 * Math.PI );

		m_bBeamFlickerOff = false;
		m_fBeamFlickerTime = 0.0;

		//BaseClass::Spawn();

		//SetBlocksLOS( false );

		self.m_HackedGunPos	= Vector( 0, 0, 12.75 );
		//SetViewOffset( EyeOffset( ACT_IDLE ) );
		self.m_flFieldOfView	= 0.4; // 60 degrees
		pev.takedamage	= DAMAGE_YES; //DAMAGE_EVENTS_ONLY;

		if( pev.health <= 0 )
			pev.health = pev.max_health = 100;

		//AddEFlags( EFL_NO_DISSOLVE );

		m_flYaw = 0;
		m_flPitch = 0;
		self.SetBoneController( 1, m_flYaw ); //SetPoseParameter( m_poseAim_Yaw, 0 );
		self.SetBoneController( 0, m_flPitch ); //SetPoseParameter( m_poseAim_Pitch, 0 );

		//m_iAmmoType = GetAmmoDef().Index( "PISTOL" );

		//m_iMuzzleAttachment = LookupAttachment( "eyes" );
		//m_iEyeAttachment = LookupAttachment( "light" );

		// FIXME: Do we ever need m_bAutoStart? (Sawyer)
		pev.spawnflags |= SF_FLOOR_TURRET_AUTOACTIVATE;

		//Set our autostart state
		m_bAutoStart = HasSpawnFlags( SF_FLOOR_TURRET_AUTOACTIVATE ); //!!( pev.spawnflags & SF_FLOOR_TURRET_AUTOACTIVATE );
		m_bEnabled	 = !HasSpawnFlags( SF_FLOOR_TURRET_STARTINACTIVE ); //( ( pev.spawnflags & SF_FLOOR_TURRET_STARTINACTIVE ) == false );

		//Do we start active?
		if( m_bAutoStart and m_bEnabled )
		{
			SetThink( ThinkFunction(this.AutoSearchThink) );
			SetEyeState( TURRET_EYE_DORMANT );
		}
		else
		{
			SetThink( ThinkFunction(this.DisabledThink) );
			SetEyeState( TURRET_EYE_DISABLED );
		}

		// Start 
		if( OnSide() )
		{
			SetThink( ThinkFunction(this.DisabledThink) );
			SetEyeState( TURRET_EYE_DISABLED );
		}

		//Stagger our starting times
		SetNextThink( g_Engine.time + Math.RandomFloat(0.1, 0.3) );

		//SetUse( UseFunction(this.ToggleUse) );

		// Don't allow us to skip animation setup because our attachments are critical to us!
		//SetBoneCacheFlags( BCF_NO_ANIMATION_SKIP );

		//CreateVPhysics();
		g_EntityFuncs.SetSize( self.pev, Vector(-16, -16, 0), Vector(16, 16, 56) );
		pev.solid = SOLID_SLIDEBOX;
		pev.movetype = MOVETYPE_STEP;
		self.m_bloodColor = DONT_BLEED;

		self.m_MonsterState = MONSTERSTATE_IDLE;

		if( string(self.m_FormattedName).IsEmpty() )
			self.m_FormattedName	= NPC_DISPLAYNAME;

		MyMonsterInit();

		m_iBarrelAttachments[ 0 ] = 0; //LookupAttachment( "LFT_Gun1_Muzzle" );
		m_iBarrelAttachments[ 1 ] = 2; //LookupAttachment( "RT_Gun1_Muzzle" );
		m_iBarrelAttachments[ 2 ] = 1; //LookupAttachment( "LFT_Gun2_Muzzle" );
		m_iBarrelAttachments[ 3 ] = 3; //LookupAttachment( "RT_Gun2_Muzzle" );

		m_fSearchSpeed = Math.RandomFloat( 1.0, 1.4 );
		m_fMovingTargetThreashold = 20.0;

		m_bNoAlarmSounds = true;
		m_bOutOfAmmo = HasSpawnFlags(SF_FLOOR_TURRET_OUT_OF_AMMO);
	}

	void Precache()
	{
		SetModelName( FLOOR_TURRET_PORTAL_MODEL );

		string sModelName = GetModelName();
		sModelName = !sModelName.IsEmpty() ? sModelName : FLOOR_TURRET_PORTAL_MODEL; //pModelName = ( pModelName and pModelName[ 0 ] != '\0' ) ? pModelName : FLOOR_TURRET_MODEL;
		PrecacheModel( sModelName );
		PrecacheModel( FLOOR_TURRET_GLOW_SPRITE );
		PrecacheModel( FLOOR_TURRET_LASER_SPRITE );
		PrecacheModel( FLOOR_TURRET_HALO_SPRITE );

		for( uint i = 0; i < arrsSounds.length(); ++i )
			g_SoundSystem.PrecacheSound( arrsSounds[i] );

		//Precache these for downloading - is it really necessary ??
		for( uint i = 0; i < arrsSounds.length(); ++i )
			g_Game.PrecacheGeneric( "sound/" + arrsSounds[i] );

		//m_sLaserHaloSprite = PrecacheModel( "sprites/redlaserglow.vmt" );
		//PrecacheModel("effects/redlaser1.vmt");
	}

	protected bool IsCitizenTurret() { return HasSpawnFlags(SF_FLOOR_TURRET_CITIZEN); }
	bool IsBeingCarriedByPlayer() { return m_bCarriedByPlayer; }

	void SetYawSpeed()
	{
		int ys = 360;

		pev.yaw_speed = ys;
	}

	int Classify() 
	{
		if( m_bEnabled ) 
			return self.GetClassification( CLASS_ALIEN_MILITARY ); //CLASS_COMBINE

		return CLASS_NONE;
	}

	int ObjectCaps() 
	{ 
		int caps = BaseClass.ObjectCaps();
		caps |= FCAP_IMPULSE_USE;

		return caps;
	}

	//I don't want to run everything in self.MonsterInit()
	void MyMonsterInit()
	{
		g_EntityFuncs.SetOrigin( self, pev.origin );
		pev.flags |= FL_MONSTER;
	}

	// Purpose: Causes the turret to face its desired angles
	bool UpdateFacing()
	{
		bool bMoved = false;

		// Desired world-space direction.
		Vector vecGoalDir;
		g_EngineFuncs.AngleVectors( m_vecGoalAngles, vecGoalDir, void, void );

		/*//if ( g_debug_turret.GetBool() )
		{
			Vector vecMuzzle, vecMuzzleDir;

			Vector vecBonePos;
			g_EngineFuncs.GetBonePosition( self.edict(), 4, vecBonePos, void );

			self.GetAttachment( 0, vecMuzzle, void ); //MatrixGetColumn( m_muzzleToWorld, 3, vecMuzzle );
			vecMuzzleDir = (vecMuzzle - vecBonePos).Normalize(); //MatrixGetColumn( m_muzzleToWorld, 0, vecMuzzleDir );

			NDebugOverlay::Cross3D( vecMuzzle, -Vector(2,2,2), Vector(2,2,2), 255, 255, 0, false, 1.0 ); //0.05
			NDebugOverlay::Cross3D( vecMuzzle+(vecMuzzleDir*256), -Vector(2,2,2), Vector(2,2,2), 255, 255, 0, false, 1.0 ); //0.05
			NDebugOverlay::Line( vecMuzzle, vecMuzzle+(vecMuzzleDir*256), 255, 255, 0, false, 1.0 ); //0.05
			
			NDebugOverlay::Cross3D( vecMuzzle, -Vector(2,2,2), Vector(2,2,2), 255, 0, 0, false, 1.0 ); //0.05
			NDebugOverlay::Cross3D( vecMuzzle+(vecGoalDir*256), -Vector(2,2,2), Vector(2,2,2), 255, 0, 0, false, 1.0 ); //0.05
			NDebugOverlay::Line( vecMuzzle, vecMuzzle+(vecGoalDir*256), 255, 0, 0, false, 1.0 ); //0.05
		}*/

		// Convert desired direction into turret-local space.
		// For now, use the turret's orientation as the local frame.
		Vector vecForward;
		Vector vecRight;
		Vector vecUp;

		g_EngineFuncs.AngleVectors( pev.angles, vecForward, vecRight, vecUp );

		Vector vecGoalLocalDir(
			DotProduct( vecGoalDir, vecForward ),
			DotProduct( vecGoalDir, vecRight ),
			DotProduct( vecGoalDir, vecUp )
		);

		Vector vecGoalLocalAngles = Math.VecToAngles( vecGoalLocalDir );
		vecGoalLocalAngles.y = -vecGoalLocalAngles.y;

		// Desired local pitch/yaw.
		float flGoalPitch = AngleNormalize( vecGoalLocalAngles.x );
		float flGoalYaw = AngleNormalize( vecGoalLocalAngles.y );

		// Calculate the actual difference between the current
		// bone-controller position and the desired position.
		float flPitchDifference = AngleNormalize( flGoalPitch - m_flPitch );

		float flYawDifference = AngleNormalize( flGoalYaw - m_flYaw );

		// Limit how much we can move this frame.
		float flMaxMove = 0.05 * pev.yaw_speed;

		float flPitchMove = Math.ApproachAngle( 0.0, flPitchDifference, flMaxMove );

		float flYawMove = Math.ApproachAngle( 0.0, flYawDifference, flMaxMove );

		m_flPitch = self.SetBoneController( 0, m_flPitch + flPitchMove );

		m_flYaw = self.SetBoneController( 1, m_flYaw + flYawMove );

		if( abs(flPitchMove) > 1.0 ) //if ( abs(flPitchMove) > 0.1 )
			bMoved = true;

		if( abs(flYawMove) > 1.0 ) //if ( abs(flYawMove) > 0.1 )
			bMoved = true;

		//g_Game.AlertMessage( at_notice, "UpdateFacing bMoved: %1, flPitchDifference: %2, flYawDifference: %3, m_vecGoalAngles: %4, m_flPitch: %5, m_flYaw: %6\n", bMoved, flPitchDifference, flYawDifference, m_vecGoalAngles.ToString(), m_flPitch, m_flYaw );

		return bMoved;
	}

	void Shoot( const Vector &in vecSrc, const Vector &in vecDirToEnemy, bool bStrict = false )
	{
		//g_Game.AlertMessage( at_notice, "Shoot called\n" );
		FireBulletsInfo_t info;

		// if ( !bStrict and GetEnemy() == UTIL_PlayerByIndex( 1 ) )
		CBaseEntity@ pEnemy = GetEnemy();
		if( !bStrict and (pEnemy !is null and pEnemy.IsPlayer()) )
		{
			Vector vecDir = GetActualShootTrajectory( vecSrc );

			info.m_vecSrc = vecSrc;
			info.m_vecDirShooting = vecDir;
			info.m_iTracerFreq = 1;
			info.m_iShots = 1;
			info.m_pAttacker = self;
			info.m_vecSpread = GetAttackSpread( GetEnemy() ); //GetAttackSpread( NULL, GetEnemy() )
			info.m_flDistance = 16384; //MAX_COORD_RANGE
			info.m_iAmmoType = m_iAmmoType;
			info.m_flDamage = DAMAGE_BULLET;
		}
		else
		{
			// Just shoot where you're facing!
			Vector vecMuzzle, vecMuzzleDir;

			self.GetAttachment( m_iMuzzleAttachment, vecMuzzle, vecMuzzleDir );

			info.m_vecSrc = vecSrc;
			info.m_vecDirShooting = vecMuzzleDir;
			info.m_iTracerFreq = 1;
			info.m_iShots = 1;
			info.m_pAttacker = self;
			info.m_vecSpread = GetAttackSpread( GetEnemy() ); //GetAttackSpread( NULL, GetEnemy() )
			info.m_flDistance = 16384; //MAX_COORD_RANGE
			info.m_iAmmoType = m_iAmmoType;
			info.m_flDamage = DAMAGE_BULLET;
		}

		info.m_flDamageForceScale = ( !m_bDamageForce ? 0.0 : TURRET_FLOOR_BULLET_FORCE_MULTIPLIER );

		int iBarrelIndex = m_bShootWithBottomBarrels ? 2 : 0;
		Vector angBarrelDir; //QAngle

		// Shoot out of the left barrel if there's nothing solid between the turret's center and the muzzle
		TraceResult tr;
		self.GetAttachment( m_iBarrelAttachments[iBarrelIndex], info.m_vecSrc, angBarrelDir );
		Vector vecCenter = self.GetOrigin(); //GetAbsOrigin();
		g_Utility.TraceLine( vecCenter, info.m_vecSrc, dont_ignore_monsters, self.edict(), tr ); //UTIL_TraceLine( vecCenter, info.m_vecSrc, MASK_SHOT, this, COLLISION_GROUP_NONE, &tr );
		//if( tr.pHit is null or tr.pHit.vars.classname != "worldspawn" ) //if( !tr.m_pEnt or !tr.m_pEnt.IsWorld() )
		{
			FireBullets( info );
		}

		// Shoot out of the right barrel if there's nothing solid between the turret's center and the muzzle
		self.GetAttachment( m_iBarrelAttachments[ iBarrelIndex + 1 ], info.m_vecSrc, angBarrelDir );
		vecCenter = self.GetOrigin(); //GetAbsOrigin();
		g_Utility.TraceLine( vecCenter, info.m_vecSrc, dont_ignore_monsters, self.edict(), tr ); //UTIL_TraceLine( vecCenter, info.m_vecSrc, MASK_SHOT, this, COLLISION_GROUP_NONE, &tr );
		//if( tr.pHit is null or tr.pHit.vars.classname != "worldspawn" ) //if( !tr.m_pEnt or !tr.m_pEnt.IsWorld() )
		{
			FireBullets( info );
		}

		// Flip shooting from the top or bottom
		m_bShootWithBottomBarrels = !m_bShootWithBottomBarrels;

		g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsSounds[Math.RandomLong(SND_SHOOT1, SND_SHOOT3)], VOL_NORM, ATTN_NORM ); //SNDLVL_GUNFIRE //EmitSound( "NPC_FloorTurret.ShotSounds" );
		/*DoMuzzleFlash();

		// Make ropes shake if they exist
		for ( int iRope = 0; iRope < PORTAL_FLOOR_TURRET_NUM_ROPES; ++iRope )
		{
			if ( m_hRopes[ iRope ] )
			{
				m_hRopes[ iRope ].ShakeRopes( vecSrc, 32.0f, 5.0f );
			}
		}

		// If a turret is partially tipped the recoil with each shot so that it can knock itself over
		Vector	up;
		GetVectors( NULL, NULL, &up );

		if ( up.z < 0.9f )
		{
			m_pMotionController.Suspend( 2.0f );

			IPhysicsObject *pTurretPhys = VPhysicsGetObject();
			Vector vVelocityImpulse = info.m_vecDirShooting * -35.0f;
			pTurretPhys.AddVelocity( &vVelocityImpulse, &vVelocityImpulse );
		}*/

		//I can't figure out the original if-statement so
		//if( m_iLastState == TURRET_ACTIVE and g_Engine.time > m_fNextTalk )
		if( m_bHasGreetedEnemy and g_Engine.time > m_fNextTalk )
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsSounds[Math.RandomLong(SND_TALK_ACTIVE1, SND_TALK_ACTIVE7)], VOL_NORM, ATTN_NORM ); //SNDLVL_70dB //EmitSound( GetTurretTalkName( m_iLastState ) );
			m_fNextTalk = g_Engine.time + 2.5;
			m_bHasGreetedEnemy = true;
		}
	}

	//-----------------------------------------------------------------------------
	// Purpose: Sets the state of the glowing eye attached to the turret
	// Input  : state - state the eye should be in
	//-----------------------------------------------------------------------------
	void SetEyeState( eyeState_t state )
	{
		// Must have a valid eye to affect
		if( m_pEyeGlow is null )
		{
			// Create our eye sprite
			@m_pEyeGlow = g_EntityFuncs.CreateSprite( FLOOR_TURRET_GLOW_SPRITE, self.GetOrigin(), false ); //GetLocalOrigin()
			if( m_pEyeGlow is null )
				return;

			m_pEyeGlow.SetTransparency( kRenderGlow, 255, 0, 0, 128, kRenderFxNoDissipation ); //kRenderWorldGlow
			//m_pEyeGlow.SetAttachment( self.edict(), m_iEyeAttachment );

			float scale = m_flSpriteScale;

			if( scale < 0 or scale > MAX_SPRITE_SCALE )
			{
				//DevMsg( "LEVEL DESIGN ERROR: Sprite %s with bad scale %f [0..%f]\n", GetDebugName(), m_flSpriteScale.Get(), MAX_SPRITE_SCALE );

				scale = Math.clamp( 0.0, MAX_SPRITE_SCALE, m_flSpriteScale );
			}

			SetBrightness( m_pEyeGlow, 128 );
			SetScale( m_pEyeGlow, scale );

			m_flStartScale = m_flDestScale = m_flSpriteScale;
			m_nStartBrightness = m_nDestBrightness = m_nBrightness;
		}

		bool bNewState = ( m_iEyeState != state );

		m_iEyeState = state;

		//Set the state
		switch( state )
		{
			case TURRET_EYE_SEEKING_TARGET: //Ping-pongs
			{
				//Toggle our state
				m_bBlinkState = !m_bBlinkState;
				m_pEyeGlow.SetColor( 255, 0, 0 );

				if( m_bBlinkState )
				{
					//Fade up and scale up
					SetScale( m_pEyeGlow, 0.3, 0.1 );
					SetBrightness( m_pEyeGlow, 224, 0.1 );
				}
				else
				{
					//Fade down and scale down
					SetScale( m_pEyeGlow, 0.2, 0.1 );
					SetBrightness( m_pEyeGlow, 192, 0.1 );
				}

				break;
			}

			case TURRET_EYE_DORMANT: //Fade out and scale down
			{
				m_pEyeGlow.SetColor( 255, 0, 0 );
				SetScale( m_pEyeGlow, 0.2, 0.5 );
				SetBrightness( m_pEyeGlow, 192, 0.5 );
				break;
			}

			case TURRET_EYE_DEAD: //Fade out slowly
			{
				m_pEyeGlow.SetColor( 255, 0, 0 );
				SetScale( m_pEyeGlow, 0.1, 3.0 );
				SetBrightness( m_pEyeGlow, 0, 3.0 );

				if( bNewState )
					pev.skin = 1; //m_nSkin

				break;
			}

			case TURRET_EYE_DISABLED:
			{
				m_pEyeGlow.SetColor( 255, 0, 0 );
				SetScale( m_pEyeGlow, 0.1, 1.0 );
				SetBrightness( m_pEyeGlow, 0, 1.0 );
				break;
			}

			case TURRET_EYE_SEE_TARGET: //Fade in and scale up
			default:
			{
				m_pEyeGlow.SetColor( 255, 0, 0 );
				SetBrightness( m_pEyeGlow, 255, 0.1 );
				SetScale( m_pEyeGlow, 0.4, 0.1 );
				break;
			}
		}
	}

	// Purpose: Make a pinging noise so the player knows where we are
	void Ping()
	{
		//See if it's time to ping again
		if( m_flPingTime > g_Engine.time )
			return;

		//Ping!
		g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, arrsSounds[SND_PING], 0.75, ATTN_IDLE ); //SNDLVL_IDLE //EmitSound( "NPC_FloorTurret.Ping" );

		SetEyeState( TURRET_EYE_SEEKING_TARGET );

		m_flPingTime = g_Engine.time + FLOOR_TURRET_PING_TIME;
	}

	//-----------------------------------------------------------------------------
	// Purpose: Determines whether the turret is upright enough to function
	// Output : Returns true if the turret is tipped over
	//-----------------------------------------------------------------------------
	bool OnSide() //inline
	{
		if( GetWaterLevel() > 0 )
			return true;

		Vector up;
		g_EngineFuncs.AngleVectors( pev.angles, void, void, up ); //GetVectors( NULL, NULL, &up );

		return ( DotProduct(up, Vector(0, 0, 1)) < 0.5 );
	}

	//-----------------------------------------------------------------------------
	// Purpose: Allows a generic think function before the others are called
	// Input  : state - which state the turret is currently in
	//-----------------------------------------------------------------------------
	bool PreThink( turretState_e state )
	{
		// Working 2 enums into one integer
		int iNewState = state;

		// If the turret is dissolving go to a special state
		if( IsDissolving() )
			iNewState = PORTAL_TURRET_DISSOLVED;

		// Need to play these sounds immediately
		if( m_iLastState != iNewState and ( ( iNewState == TURRET_TIPPED and !m_bDelayTippedTalk ) or 
											iNewState == TURRET_RETIRING or 
											iNewState == PORTAL_TURRET_DISSOLVED or 
											iNewState == PORTAL_TURRET_PICKUP ) )
		{
			m_fNextTalk = g_Engine.time - 1.0;
		}

		// If we've changed states or are in a state with a repeating message
		if( g_Engine.time > m_fNextTalk and m_iLastState != iNewState )
		{
			m_iLastState = turretState_e( iNewState );

			//const char *pchScriptName = GetTurretTalkName( m_iLastState );

			switch ( iNewState )
			{
				case TURRET_SEARCHING:
				{
					g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsSounds[Math.RandomLong(SND_TALK_SEARCH1, SND_TALK_SEARCH3)], VOL_NORM, ATTN_NORM ); //SNDLVL_70dB //EmitSound( pchScriptName ); //NPC_FloorTurret.TalkSearch
					m_fNextTalk = g_Engine.time + 1.75;
					break;
				}

				case TURRET_AUTO_SEARCHING:
				{
					g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsSounds[Math.RandomLong(SND_TALK_AUTOSEARCH1, SND_TALK_AUTOSEARCH5)], VOL_NORM, ATTN_NORM ); //SNDLVL_70dB //EmitSound( pchScriptName ); //NPC_FloorTurret.TalkAutosearch
					m_fNextTalk = g_Engine.time + 1.75;
					break;
				}

				case TURRET_DEPLOYING:
				{
					g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsSounds[Math.RandomLong(SND_TALK_DEPLOY1, SND_TALK_DEPLOY5)], VOL_NORM, ATTN_NORM ); //SNDLVL_75dB //EmitSound( pchScriptName ); //NPC_FloorTurret.TalkDeploy
					m_fNextTalk = g_Engine.time + 1.75;
					break;
				}

				case TURRET_RETIRING:
				{
					g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsSounds[Math.RandomLong(SND_TALK_RETIRE1, SND_TALK_RETIRE6)], VOL_NORM, ATTN_NORM ); //SNDLVL_70dB //EmitSound( pchScriptName ); //NPC_FloorTurret.TalkRetire
					m_fNextTalk = g_Engine.time + 3.5;
					break;
				}

				case TURRET_TIPPED:
				{
					g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsSounds[Math.RandomLong(SND_TALK_TIPPED1, SND_TALK_TIPPED4)], VOL_NORM, ATTN_NORM ); //SNDLVL_75dB //EmitSound( pchScriptName ); //NPC_FloorTurret.TalkTipped
					m_fNextTalk = g_Engine.time + 1.15;
					break;
				}

				case PORTAL_TURRET_PICKUP:
				{
					g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsSounds[Math.RandomLong(SND_TALK_PICKUP1, SND_TALK_PICKUP7)], VOL_NORM, ATTN_NORM ); //CHAN_AUTO	//SNDLVL_70dB //EmitSound( GetTurretTalkName( PORTAL_TURRET_PICKUP ) ); //NPC_FloorTurret.TalkPickup
					m_fNextTalk = g_Engine.time + 2.25;
					break;
				}

				case PORTAL_TURRET_DISSOLVED:
				{
					g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsSounds[SND_TALK_DISSOLVED], VOL_NORM, ATTN_NORM ); //SNDLVL_75dB //EmitSound( pchScriptName ); //NPC_FloorTurret.TalkDissolved
					m_fNextTalk = g_Engine.time + 10.0;	// Never going to talk again
					break;
				}
			}
		}

		// New states are not supported by old turret code
		if( iNewState != TURRET_TIPPED and iNewState < TURRET_STATE_TOTAL )
			return BasePreThink( turretState_e(iNewState) );

		return true;
	}

	//-----------------------------------------------------------------------------
	// Purpose: Allows a generic think function before the others are called
	// Input  : state - which state the turret is currently in
	//-----------------------------------------------------------------------------
	bool BasePreThink( turretState_e state )
	{
		// Hack to disable turrets when ai is disabled
		/*if ( CAI_BaseNPC::m_nDebugBits & bits_debugDisableAI )
		{
			// Push our think out into the future
			SetNextThink( g_Engine.time + 0.1 );
			return true;
		}*/

		//CheckPVSCondition();

		//Animate
		self.StudioFrameAdvance();

		// We're gonna blow up, so don't interrupt us
		if( state == TURRET_SELF_DESTRUCTING )
			return false;

		//See if we've tipped, but only do this if we're not being carried
		if( !IsBeingCarriedByPlayer() )
		{
			if( !OnSide() )
			{
				/*// If I still haven't fallen over after an NPC has tried to knock me down, let them know
				if ( m_hLastNPCToKickMe and m_flKnockOverFailedTime < g_Engine.time )
				{
					m_hLastNPCToKickMe.DispatchInteraction( g_interactionTurretStillStanding, NULL, this );
					m_hLastNPCToKickMe = NULL;
				}

				//Debug visualization
				if ( g_debug_turret.GetBool() )
				{
					Vector	up;
					GetVectors( NULL, NULL, &up );

					NDebugOverlay::Line( GetAbsOrigin()+(up*32), GetAbsOrigin()+(up*128), 0, 255, 0, false, 2.0f );
					NDebugOverlay::Cross3D( GetAbsOrigin()+(up*32), -Vector(2,2,2), Vector(2,2,2), 0, 255, 0, false, 2.0f );
					NDebugOverlay::Cross3D( GetAbsOrigin()+(up*128), -Vector(2,2,2), Vector(2,2,2), 0, 255, 0, false, 2.0f );
				}*/
			}
			else
			{
				if( !HasSpawnFlags(SF_FLOOR_TURRET_OUT_OF_AMMO) )
				{
					//Thrash around for a bit
					m_flThrashTime = g_Engine.time + Math.RandomFloat( 2.0, 2.5 );
					SetNextThink( g_Engine.time + 0.05 );

					SetThink( ThinkFunction(this.TippedThink) );
					SetEyeState( TURRET_EYE_SEE_TARGET );

					SpinUp();

					if( !m_bNoAlarmSounds )
						g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, arrsSounds[SND_ALARM], VOL_NORM, ATTN_NORM ); //SNDLVL_TALKING //EmitSound( "NPC_FloorTurret.Alarm" );
				}
				else
				{
					// Take away the laser
					//UTIL_Remove( m_hLaser );
					//m_hLaser = NULL;

					// Become inactive
					SetThink( ThinkFunction(this.InactiveThink) );
					SetEyeState( TURRET_EYE_DEAD );
				}

				//Stop being targetted
				self.m_MonsterState = MONSTERSTATE_DEAD; //SetState( NPC_STATE_DEAD );
				pev.deadflag = DEAD_DEAD; //m_lifeState = LIFE_DEAD;

				/*//Disable the tip controller
				m_pMotionController.Enable( false );

				//Debug visualization
				if ( g_debug_turret.GetBool() )
				{
					Vector	up;
					GetVectors( NULL, NULL, &up );

					NDebugOverlay::Line( GetAbsOrigin()+(up*32), GetAbsOrigin()+(up*128), 255, 0, 0, false, 2.0f );
					NDebugOverlay::Cross3D( GetAbsOrigin()+(up*32), -Vector(2,2,2), Vector(2,2,2), 255, 0, 0, false, 2.0f );
					NDebugOverlay::Cross3D( GetAbsOrigin()+(up*128), -Vector(2,2,2), Vector(2,2,2), 255, 0, 0, false, 2.0f );
				}*/

				//Interrupt current think function
				return true;
			}
		}

		//Do not interrupt current think function
		return false;
	}

	Vector GetAttackSpread( CBaseEntity@ pTarget ) 
	{
		WeaponProficiency_t weaponProficiency = WEAPON_PROFICIENCY_AVERAGE;

		// Switch our weapon proficiency based upon our target
		if( pTarget !is null )
		{
			if( pTarget.Classify() == CLASS_PLAYER /*or pTarget.Classify() == CLASS_ANTLION or pTarget.Classify() == CLASS_ZOMBIE*/ )
			{
				// Make me much more accurate
				weaponProficiency = WEAPON_PROFICIENCY_PERFECT;
			}
			else if( pTarget.Classify() == CLASS_ALIEN_MILITARY ) //CLASS_COMBINE
			{
				// Make me more accurate
				weaponProficiency = WEAPON_PROFICIENCY_VERY_GOOD;
			}
		}

		return VECTOR_CONE_4DEGREES * GetDefaultProficiencyValues()[ weaponProficiency ].spreadscale; //CBaseHLCombatWeapon::GetDefaultProficiencyValues()
	}

	// Purpose: Retract and stop attacking
	void Retire()
	{
		AlwaysThink();

		LaserOn();

		BaseRetire();
	}

	void BaseRetire()
	{
		if( PreThink(TURRET_RETIRING) )
			return;

		//Level out the turret
		m_vecGoalAngles = GetAbsAngles();
		SetNextThink( g_Engine.time + 0.05 );

		//Set ourselves to close
		if( GetSequence() != self.LookupSequence("retract") ) //GetActivity() != ACT_FLOOR_TURRET_CLOSE
		{
			//Set our visible state to dormant
			SetEyeState( TURRET_EYE_DORMANT );

			ChangeSequence( self.LookupSequence("idlealert") ); //SetActivity( (Activity) ACT_FLOOR_TURRET_OPEN_IDLE );
			
			//If we're done moving to our desired facing, close up
			if( !UpdateFacing() )
			{
				ChangeSequence( self.LookupSequence("retract") ); //SetActivity( (Activity) ACT_FLOOR_TURRET_CLOSE );
				g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, arrsSounds[SND_RETIRE], VOL_NORM, ATTN_NORM ); //SNDLVL_70dB //EmitSound( "NPC_FloorTurret.Retire" );

				//Notify of the retraction
				//m_OnRetire.FireOutput( NULL, this );
			}
		}
		else if( self.m_fSequenceFinished ) //IsActivityFinished()
		{	
			m_bActive = false;
			m_flLastSight = 0;

			ChangeSequence( self.LookupSequence("idle") ); //SetActivity( (Activity) ACT_FLOOR_TURRET_CLOSED_IDLE );

			//Go back to auto searching
			if( m_bAutoStart )
			{
				SetThink( ThinkFunction(this.AutoSearchThink) );
				SetNextThink( g_Engine.time + 0.05 );
			}
			else
			{
				//Set our visible state to dormant
				SetEyeState( TURRET_EYE_DISABLED );
				SetThink( ThinkFunction(this.DisabledThink) );
			}
		}
	}

	void Deploy()
	{
		AlwaysThink();

		LaserOn();
		RopesOn();

		BaseDeploy();
	}

	void BaseDeploy()
	{
		if( PreThink(TURRET_DEPLOYING) )
			return;

		m_vecGoalAngles = GetAbsAngles();

		SetNextThink( g_Engine.time + 0.05 );

		//Show we've seen a target
		SetEyeState( TURRET_EYE_SEE_TARGET );

		//Open if we're not already
		if( GetSequence() != self.LookupSequence("deploy") ) //GetActivity() != ACT_FLOOR_TURRET_OPEN
		{
			m_bActive = true;
			ChangeSequence( self.LookupSequence("deploy") ); //SetActivity( (Activity) ACT_FLOOR_TURRET_OPEN );
			g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, arrsSounds[SND_DEPLOY], VOL_NORM, ATTN_NORM ); //SNDLVL_70dB //EmitSound( "NPC_FloorTurret.Deploy" );

			//Notify we're deploying
			//m_OnDeploy.FireOutput( NULL, this );
		}

		//If we're done, then start searching
		if( self.m_fSequenceFinished ) //IsActivityFinished()
		{
			ChangeSequence( self.LookupSequence("idlealert") ); //SetActivity( (Activity) ACT_FLOOR_TURRET_OPEN_IDLE );

			m_flShotTime  = g_Engine.time + 1.0;

			pev.framerate = 0; //m_flPlaybackRate
			SetThink( ThinkFunction(this.SearchThink) );

			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, arrsSounds[SND_MOVE], 0.1, ATTN_NORM ); //SNDLVL_70dB //EmitSound( "NPC_FloorTurret.Move" );
		}

		m_flLastSight = g_Engine.time + FLOOR_TURRET_MAX_WAIT;
	}

	void ActiveThink()
	{
		AlwaysThink();

		LaserOn();

		//Allow descended classes a chance to do something before the think function
		if( PreThink(TURRET_ACTIVE) )
			return;

		HackFindEnemy();

		//Update our think time
		SetNextThink( g_Engine.time + 0.1 );

		CBaseEntity@ pEnemy = GetEnemy();

		//If we've become inactive, go back to searching
		if( !m_bActive or pEnemy is null )
		{
			SetEnemy( null );
			m_flLastSight = g_Engine.time + FLOOR_TURRET_MAX_WAIT;
			SetThink( ThinkFunction(this.SearchThink) );
			m_vecGoalAngles = GetAbsAngles();
			return;
		}

		//Get our shot positions
		Vector vecMid = self.EyePosition();
		Vector vecMidEnemy = pEnemy.BodyTarget( vecMid );

		// Store off our last seen location so we can suppress it later
		m_vecEnemyLKP = vecMidEnemy;

		//Look for our current enemy
		bool bEnemyInFOV = self.FInViewCone( pEnemy );
		bool bEnemyVisible = self.FVisible( pEnemy, true) and pEnemy.IsAlive();

		//Calculate dir and dist to enemy
		Vector vecDirToEnemy = vecMidEnemy - vecMid;	
		m_flDistToEnemy = vecDirToEnemy.Normalize().Length(); //= VectorNormalize

		/*// If the enemy isn't in the normal fov, check the fov through portals
		CProp_Portal *pPortal = NULL;
		if ( pEnemy.IsAlive() )
		{
			pPortal = FInViewConeThroughPortal( pEnemy );

			if ( pPortal and FVisibleThroughPortal( pPortal, pEnemy ) )
			{
				// Translate our target across the portal
				Vector vecMidEnemyTransformed;
				UTIL_Portal_PointTransform( pPortal.m_hLinkedPortal.MatrixThisToLinked(), vecMidEnemy, vecMidEnemyTransformed );

				//Calculate dir and dist to enemy
				Vector	vecDirToEnemyTransformed = vecMidEnemyTransformed - vecMid;	
				float	flDistToEnemyTransformed = VectorNormalize( vecDirToEnemyTransformed );

				// If it's not visible through normal means or the enemy is closer through the portal, use the translated info
				if ( !bEnemyInFOV or !bEnemyVisible or flDistToEnemyTransformed < m_flDistToEnemy )
				{
					bEnemyInFOV = true;
					bEnemyVisible = true;
					vecMidEnemy = vecMidEnemyTransformed;
					vecDirToEnemy = vecDirToEnemyTransformed;
					m_flDistToEnemy = flDistToEnemyTransformed;
				}
				else
				{
					pPortal = NULL;
				}
			}
			else
			{
				pPortal = NULL;
			}
		}*/

		/*//Draw debug info
		if ( g_debug_turret.GetBool() )
		{
			NDebugOverlay::Cross3D( vecMid, -Vector(2,2,2), Vector(2,2,2), 0, 255, 0, false, 0.05 );
			NDebugOverlay::Cross3D( GetEnemy().WorldSpaceCenter(), -Vector(2,2,2), Vector(2,2,2), 0, 255, 0, false, 0.05 );
			NDebugOverlay::Line( vecMid, GetEnemy().WorldSpaceCenter(), 0, 255, 0, false, 0.05 );

			NDebugOverlay::Cross3D( vecMid, -Vector(2,2,2), Vector(2,2,2), 0, 255, 0, false, 0.05 );
			NDebugOverlay::Cross3D( vecMidEnemy, -Vector(2,2,2), Vector(2,2,2), 0, 255, 0, false, 0.05 );
			NDebugOverlay::Line( vecMid, vecMidEnemy, 0, 255, 0, false, 0.05f );
		}*/

		//See if they're past our FOV of attack
		if( !bEnemyInFOV )
		{
			// Should we look for a new target?
			//ClearEnemyMemory();
			SetEnemy( null );

			if( HasSpawnFlags(SF_FLOOR_TURRET_FASTRETIRE) )
			{
				// Retire quickly in this case. (The case where we saw the player, but he hid again).
				m_flLastSight = g_Engine.time + FLOOR_TURRET_SHORT_WAIT;
			}
			else
				m_flLastSight = g_Engine.time + FLOOR_TURRET_MAX_WAIT;

			SetThink( ThinkFunction(this.SearchThink) );
			m_vecGoalAngles = GetAbsAngles();

			SpinDown();

			return;
		}

		//Current enemy is not visible
		if( !bEnemyVisible or m_flDistToEnemy > PORTAL_FLOOR_TURRET_RANGE )
		{
			m_flLastSight = g_Engine.time + 2.0;

			//ClearEnemyMemory();
			SetEnemy( null );
			SetThink( ThinkFunction(this.SuppressThink) );

			return;
		}

		/*if ( g_debug_turret.GetBool() )
		{
			Vector vecMuzzle, vecMuzzleDir;

			UpdateMuzzleMatrix();
			MatrixGetColumn( m_muzzleToWorld, 0, vecMuzzleDir );
			MatrixGetColumn( m_muzzleToWorld, 3, vecMuzzle );

			// Visualize vertical firing ranges
			for ( int i = 0; i < 4; i++ )
			{
				QAngle angMaxDownPitch = GetAbsAngles();

				switch( i )
				{
				case 0:	angMaxDownPitch.x -= 15; break;
				case 1:	angMaxDownPitch.x += 15; break;
				case 2:	angMaxDownPitch.x -= 25; break;
				case 3:	angMaxDownPitch.x += 25; break;
				default:
					break;
				}

				Vector vecMaxDownPitch;
				AngleVectors( angMaxDownPitch, &vecMaxDownPitch );
				NDebugOverlay::Line( vecMuzzle, vecMuzzle + (vecMaxDownPitch*256), 255, 255, 255, false, 0.1 );
			}
		}*/

		if( m_flShotTime < g_Engine.time )
		{
			//g_Game.AlertMessage( at_notice, "m_flShotTime\n" );

			Vector vecMuzzle, vecMuzzleDir;

			//UpdateMuzzleMatrix();
			//MatrixGetColumn( m_muzzleToWorld, 0, vecMuzzleDir );
			//MatrixGetColumn( m_muzzleToWorld, 3, vecMuzzle );

			self.GetAttachment( 0, vecMuzzle, void );
			Vector vecBonePos;
			g_EngineFuncs.GetBonePosition( self.edict(), 4, vecBonePos, void );
			vecMuzzleDir = (vecMuzzle - vecBonePos).Normalize();

			Vector2D vecDirToEnemy2D = vecDirToEnemy.Make2D(); //AsVector2D();
			Vector2D vecMuzzleDir2D = vecMuzzleDir.Make2D(); //AsVector2D();

			bool bCanShoot = true;
			float minCos3d = DOT_10DEGREE; // 10 degrees slop

			if( m_flDistToEnemy < 60.0 )
			{
				//g_Game.AlertMessage( at_notice, "m_flDistToEnemy\n" );

				vecDirToEnemy2D = vecDirToEnemy2D.Normalize(); //NormalizeInPlace
				vecMuzzleDir2D = vecMuzzleDir2D.Normalize(); //NormalizeInPlace

				float flCanShoot = DotProduct( vecDirToEnemy2D, vecMuzzleDir2D );
				//g_Game.AlertMessage( at_notice, "flCanShoot: %1\n", flCanShoot );

				bCanShoot = ( DotProduct(vecDirToEnemy2D, vecMuzzleDir2D) >= DOT_10DEGREE ); //vecDirToEnemy2D.Dot(vecMuzzleDir2D)
				minCos3d = 0.7071; // 45 degrees
			}

			//Fire the gun
			if( bCanShoot ) // 10 degree slop XY
			{
				float dot3d = DotProduct( vecDirToEnemy, vecMuzzleDir );

				if( m_bOutOfAmmo )
					DryFire();
				else
				{
					if( dot3d >= minCos3d ) 
					{
						ChangeSequence( self.LookupSequence("idlealert") ); //SetActivity( (Activity) ACT_FLOOR_TURRET_OPEN_IDLE );
						string sSequence = m_bShootWithBottomBarrels ? "fire2" : "fire";
						ChangeSequence( self.LookupSequence(sSequence) ); //SetActivity( (Activity)( ( m_bShootWithBottomBarrels ) ? ( ACT_FLOOR_TURRET_FIRE2 ) : ( ACT_FLOOR_TURRET_FIRE ) ) );

						Shoot( vecMuzzle, vecMuzzleDir, (dot3d < DOT_10DEGREE) );
					}
				}

				//g_Game.AlertMessage( at_notice, "bCanShoot\n" );
			}
		}
		else
			ChangeSequence( self.LookupSequence("idlealert") ); //SetActivity( (Activity) ACT_FLOOR_TURRET_OPEN_IDLE );

		//If we can see our enemy, face it
		if( bEnemyVisible )
		{
			//We want to look at the enemy's eyes so we don't jitter
			Vector vEnemyWorldSpaceCenter = pEnemy.Center(); //pEnemy.WorldSpaceCenter();
			/*if( pPortal and pPortal.IsActivedAndLinked() )
			{
				// Translate our target across the portal
				UTIL_Portal_PointTransform( pPortal.m_hLinkedPortal.MatrixThisToLinked(), vEnemyWorldSpaceCenter, vEnemyWorldSpaceCenter );
			}*/

			Vector vecDirToEnemyEyes = vEnemyWorldSpaceCenter - vecMid;
			vecDirToEnemyEyes = vecDirToEnemyEyes.Normalize(); //VectorNormalize

			Vector vecAnglesToEnemy; //QAngle
			vecAnglesToEnemy = Math.VecToAngles( vecDirToEnemyEyes ); //VectorAngles( vecDirToEnemyEyes, vecAnglesToEnemy );

			m_vecGoalAngles.y = vecAnglesToEnemy.y;
			m_vecGoalAngles.x = vecAnglesToEnemy.x;
		}

		//Turn to face
		UpdateFacing();
		//g_Game.AlertMessage( at_notice, "ActiveThink\n" );
	}

	// Purpose: Target doesn't exist or has eluded us, so search for one
	void SearchThink()
	{
		AlwaysThink();

		//Allow descended classes a chance to do something before the think function
		if( PreThink(TURRET_SEARCHING) )
			return;

		SetNextThink( g_Engine.time + 0.05 );

		ChangeSequence( self.LookupSequence("idlealert") ); //SetActivity( (Activity) ACT_FLOOR_TURRET_OPEN_IDLE );

		//If our enemy has died, pick a new enemy
		if( GetEnemy() !is null and !GetEnemy().IsAlive() )
			SetEnemy( null );

		//Acquire the target
		if( GetEnemy() is null )
			HackFindEnemy();

		LaserOn();

		CBaseEntity@ pEnemy = GetEnemy();

		//If we've found a target, spin up the barrel and start to attack
		if( pEnemy !is null )
		{
			//Get our shot positions
			Vector vecMid = self.EyePosition();
			Vector vecMidEnemy = pEnemy.BodyTarget( vecMid );

			//Look for our current enemy
			bool bEnemyInFOV = self.FInViewCone( pEnemy );
			bool bEnemyVisible = self.FVisible( pEnemy, true );

			//Calculate dir and dist to enemy
			Vector vecDirToEnemy = vecMidEnemy - vecMid;	
			m_flDistToEnemy = vecDirToEnemy.Normalize().Length(); //= VectorNormalize

			/*// If the enemy isn't in the normal fov, check the fov through portals
			CProp_Portal *pPortal = NULL;
			pPortal = FInViewConeThroughPortal( pEnemy );

			if ( pPortal and FVisibleThroughPortal( pPortal, pEnemy ) )
			{
				// Translate our target across the portal
				Vector vecMidEnemyTransformed;
				UTIL_Portal_PointTransform( pPortal.m_hLinkedPortal.MatrixThisToLinked(), vecMidEnemy, vecMidEnemyTransformed );

				//Calculate dir and dist to enemy
				Vector	vecDirToEnemyTransformed = vecMidEnemyTransformed - vecMid;	
				float	flDistToEnemyTransformed = VectorNormalize( vecDirToEnemyTransformed );

				// If it's not visible through normal means or the enemy is closer through the portal, use the translated info
				if ( !bEnemyInFOV or !bEnemyVisible or flDistToEnemyTransformed < m_flDistToEnemy )
				{
					bEnemyInFOV = true;
					bEnemyVisible = true;
					vecMidEnemy = vecMidEnemyTransformed;
					vecDirToEnemy = vecDirToEnemyTransformed;
					m_flDistToEnemy = flDistToEnemyTransformed;
				}
			}*/

			// Give enemies that are farther away a longer grace period
			float fDistanceRatio = m_flDistToEnemy / PORTAL_FLOOR_TURRET_RANGE;
			m_flShotTime = g_Engine.time + fDistanceRatio * fDistanceRatio * PORTAL_FLOOR_TURRET_MAX_SHOT_DELAY;

			m_flLastSight = 0;
			SetThink( ThinkFunction(this.ActiveThink) );
			SetEyeState( TURRET_EYE_SEE_TARGET );

			SpinUp();

			if( g_Engine.time > m_flNextActivateSoundTime )
			{
				g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, arrsSounds[SND_ACTIVATE], VOL_NORM, ATTN_NORM ); //SNDLVL_IDLE //EmitSound( "NPC_FloorTurret.Activate" );
				m_flNextActivateSoundTime = g_Engine.time + 3.0;
			}

			return;
		}

		//Are we out of time and need to retract?
		if( g_Engine.time > m_flLastSight )
		{
			//Before we retrace, make sure that we are spun down.
			m_flLastSight = 0;
			SetThink( ThinkFunction(this.Retire) );

			return;
		}

		//Display that we're scanning
		m_vecGoalAngles.x = GetAbsAngles().x + ( sin( ( m_flLastSight + g_Engine.time * m_fSearchSpeed ) * 1.5 ) * 20.0 );
		m_vecGoalAngles.y = GetAbsAngles().y + ( sin( ( m_flLastSight + g_Engine.time * m_fSearchSpeed ) * 2.5 ) * 20.0 );

		//Turn and ping
		UpdateFacing();
		Ping();

		/*// Update rope positions
		for ( int iRope = 0; iRope < PORTAL_FLOOR_TURRET_NUM_ROPES; ++iRope )
		{
			if ( m_hRopes[ iRope ] )
			{
				m_hRopes[ iRope ].EndpointsChanged();
			}
		}*/

		//g_Game.AlertMessage( at_notice, "SearchThink\n" );
	}

	void AutoSearchThink()
	{
		AlwaysThink();

		LaserOn();
		RopesOff();

		BaseAutoSearchThink();
	}

	void BaseAutoSearchThink()
	{
		//Allow descended classes a chance to do something before the think function
		if( PreThink(TURRET_AUTO_SEARCHING) )
			return; 

		//Spread out our thinking
		SetNextThink( g_Engine.time + Math.RandomFloat(0.2, 0.4) );

		//If the enemy is dead, find a new one
		if( GetEnemy() !is null and !GetEnemy().IsAlive() )
			SetEnemy( null );

		//Acquire Target
		if( GetEnemy() is null )
			HackFindEnemy();

		//Deploy if we've got an active target
		if( GetEnemy() !is null )
		{
			SetThink( ThinkFunction(this.Deploy) );

			if( !m_bNoAlarmSounds )
			{
				g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, arrsSounds[SND_ALERT], VOL_NORM, ATTN_NORM ); //SNDLVL_TALKING //EmitSound( "NPC_FloorTurret.Alert" );
			}
		}
	}

	// Purpose: The turret has been tipped over and will thrash for awhile
	void TippedThink()
	{
		AlwaysThink();

		PreThink( TURRET_TIPPED );

		SetNextThink( g_Engine.time + 0.05 );
		SetEnemy( null );

		self.StudioFrameAdvance();
		// If we're not on side anymore, stop thrashing
		if( !OnSide() ) //and VPhysicsGetObject().GetContactPoint( NULL, NULL )
		{
			ReturnToLife();
			return;
		}

		LaserOn();
		RopesOn();

		//See if we should continue to thrash
		if( g_Engine.time < m_flThrashTime and !IsDissolving() )
		{
			if( m_flShotTime < g_Engine.time )
			{
				if( m_bOutOfAmmo )
				{
					ChangeSequence( self.LookupSequence("idlealert") ); //SetActivity( (Activity) ACT_FLOOR_TURRET_OPEN_IDLE );
					DryFire();
				}
				else
				{
					Vector vecMuzzle, vecMuzzleDir;
					self.GetAttachment( m_iMuzzleAttachment, vecMuzzle, vecMuzzleDir );

					ChangeSequence( self.LookupSequence("idlealert") ); //SetActivity( (Activity) ACT_FLOOR_TURRET_OPEN_IDLE );
					string sSequence = m_bShootWithBottomBarrels ? "fire2" : "fire";
					ChangeSequence( self.LookupSequence(sSequence) ); //SetActivity( (Activity)( ( m_bShootWithBottomBarrels ) ? ( ACT_FLOOR_TURRET_FIRE2 ) : ( ACT_FLOOR_TURRET_FIRE ) ) );

					Shoot( vecMuzzle, vecMuzzleDir );
				}

				m_flShotTime = g_Engine.time + 0.05;
			}

			m_vecGoalAngles.x = GetAbsAngles().x + Math.RandomFloat( -60, 60 );
			m_vecGoalAngles.y = GetAbsAngles().y + Math.RandomFloat( -60, 60 );

			UpdateFacing();
		}
		else
		{
			//Face forward
			m_vecGoalAngles = GetAbsAngles();

			//Set ourselves to close
			if( GetSequence() != self.LookupSequence("retract") ) //GetActivity() != ACT_FLOOR_TURRET_CLOSE
			{
				ChangeSequence( self.LookupSequence("idlealert") ); //SetActivity( (Activity) ACT_FLOOR_TURRET_OPEN_IDLE );

				//If we're done moving to our desired facing, close up
				if( !UpdateFacing() )
				{
					//Make any last death noises and anims
					g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, arrsSounds[SND_DIE], 0.75, ATTN_NORM ); //SNDLVL_70dB //EmitSound( "NPC_FloorTurret.Die" );
					g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsSounds[Math.RandomLong(SND_TALK_DISABLED1, SND_TALK_DISABLED6)], VOL_NORM, ATTN_NORM ); //SNDLVL_70dB //EmitSound( GetTurretTalkName( PORTAL_TURRET_DISABLED ) );
					SpinDown();

					ChangeSequence( self.LookupSequence("retract") ); //SetActivity( (Activity) ACT_FLOOR_TURRET_CLOSE );
					g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, arrsSounds[SND_RETIRE], VOL_NORM, ATTN_NORM ); //SNDLVL_70dB //EmitSound( "NPC_FloorTurret.Retire" ); //NPC_FloorTurret.Retract

					//CTakeDamageInfo	info;
					//info.SetDamage( 1 );
					//info.SetDamageType( DMG_CRUSH );
					//Event_Killed( info );
					Killed( self.pev, GIB_NEVER );
				}
			}
			else if( self.m_fSequenceFinished ) //IsActivityFinished()
			{	
				m_bActive = false;
				m_flLastSight = 0;

				ChangeSequence( self.LookupSequence("idle") ); //SetActivity( (Activity) ACT_FLOOR_TURRET_CLOSED_IDLE );

				// Don't need to store last NPC anymore, because I've been knocked over
				/*if( m_hLastNPCToKickMe )
				{
					m_hLastNPCToKickMe = null;
					m_flKnockOverFailedTime = 0;
				}*/

				//Try to look straight
				if( !UpdateFacing() )
				{
					//m_OnTipped.FireOutput( this, this );
					SetEyeState( TURRET_EYE_DEAD );
					//SetCollisionGroup( COLLISION_GROUP_DEBRIS_TRIGGER );

					// Start thinking slowly to see if we're ever set upright somehow
					SetThink( ThinkFunction(this.InactiveThink) );
					SetNextThink( g_Engine.time + 1.0 );
					RopesOff();
				}
			}
		}
	}

	void HeldThink()
	{
		AlwaysThink();

		PreThink( turretState_e(PORTAL_TURRET_PICKUP) );

		SetNextThink( g_Engine.time + 0.05 );
		SetEnemy( null );

		self.StudioFrameAdvance();

		//IPhysicsObject *pTurretPhys = VPhysicsGetObject();

		// If we're not held anymore, stop thrashing
		if( m_pCarryingPlayer is null ) //if ( !(pTurretPhys.GetGameFlags() & FVPHYSICS_PLAYER_HELD) )
		{
			m_fNextTalk = g_Engine.time + 1.25;

			if( pev.deadflag == DEAD_NO )
				SetThink( ThinkFunction(this.ActiveThink) );
			else
				SetThink( ThinkFunction(this.InactiveThink) );
		}

		LaserOn();
		RopesOn();

		//See if we should continue to thrash
		if( !IsDissolving() )
		{
			if( m_flShotTime < g_Engine.time )
			{
				ChangeSequence( self.LookupSequence("idlealert") ); //SetActivity( (Activity) ACT_FLOOR_TURRET_OPEN_IDLE );

				DryFire();

				m_flShotTime = g_Engine.time + Math.RandomFloat( 0.25, 0.75 );

				m_vecGoalAngles.x = GetAbsAngles().x + Math.RandomFloat( -15, 15 );
				m_vecGoalAngles.y = GetAbsAngles().y + Math.RandomFloat( -40, 40 );
			}

			UpdateFacing();
		}

		CarryMe();
	}

	void CarryMe()
	{
		if( m_pCarryingPlayer is null or !m_pCarryingPlayer.IsAlive() )
		{
			Drop();
			//g_Game.AlertMessage( at_notice, "%1 dropped because holder is null or dead!\n", self.GetClassname() );
			return;
		}

		//m_flHoldDistance += (m_pCarryingPlayer.pev.button & IN_FORWARD) != 0 ? 2.0 : 0.0;
		if( HasFlags(m_pCarryingPlayer.pev.button, IN_ATTACK) )
		{
			Throw();
			return;
		}

		if( HasFlags(m_pCarryingPlayer.pev.button, IN_USE) and m_flDropDelay > 0 and m_flDropDelay < g_Engine.time )
		{
			m_flDropDelay = 0.0;
			Drop( false ); //false causes you to throw the object
			return;
		}

		Move();
		UpdateRotation();

		if( (pev.origin - m_pCarryingPlayer.pev.origin).Length() > 256.0 )
		{
			Drop();
			//g_Game.AlertMessage( at_notice, "%1 dropped because holder is too far away!\n", self.GetClassname() );
		}
	}

	void Move()
	{
		Vector vecSrc = m_pCarryingPlayer.EyePosition();
		Vector vecAim = m_pCarryingPlayer.GetAutoaimVector( 0.0 );
		Vector vecTarget = vecSrc + vecAim * m_flHoldDistance;

		//Prevent going through walls, ADD func_clip_vphysics HERE ?!
		TraceResult tr;
		g_Utility.TraceLine( vecSrc, vecTarget, dont_ignore_monsters, m_pCarryingPlayer.edict(), tr );

		if( tr.flFraction < 1.0 )
		{
			if( tr.pHit !is null and tr.pHit !is self.edict() )
				vecTarget = tr.vecEndPos - vecAim * 8.0;
		}

		Vector vecDelta = vecTarget - pev.origin;

		//Jitter fix
		if( vecDelta.Length() < 2.0 )
			pev.velocity = g_vecZero;

		if( vecDelta.Length() < 1.0 )
			g_EntityFuncs.SetOrigin( self, vecTarget );

		//apply spring force
		Vector vecForce = vecDelta * m_flStiffness;

		//damp existing velocity
		pev.velocity = pev.velocity * m_flDamping + vecForce;

		//move with the player
		float flFactor; //0.25

		if( !HasFlags(m_pCarryingPlayer.pev.flags, FL_ONGROUND) )	//Don't push away from jumping/falling players unless in water
		{
			if( pev.waterlevel < WATERLEVEL_FEET )
				return;
			else 
				flFactor = 0.1;
		}
		else
			flFactor = 1;

		pev.velocity.x += m_pCarryingPlayer.pev.velocity.x * flFactor;
		pev.velocity.y += m_pCarryingPlayer.pev.velocity.y * flFactor;
	}

	void UpdateRotation()
	{
		if( m_pCarryingPlayer is null )
			return;

		Vector angTarget = Vector( 0, m_pCarryingPlayer.pev.v_angle.y, 0 );

		//shitty
		/*if( m_bAligning )
		{
			//Smoothly rotate into place using avelocity
			Vector angDelta = angTarget - pev.angles;

			for( int i = 0; i < 3; i++ )
			{
				if( angDelta[i] > 180 ) angDelta[ i ] -= 360;
				if( angDelta[i] < -180 ) angDelta[ i ] += 360;
			}

			pev.avelocity = angDelta * 6.0;

			// stop aligning when close enough
			if( angDelta.Length() < 5.0 )
			{
				m_bAligning = false;
				pev.avelocity = g_vecZero;
			}
		}
		else*/
		{
			//LOCK rotation (no physics spin)
			pev.avelocity = g_vecZero;
			pev.angles = angTarget;
		}
	}

	void Throw()
	{
		Vector vecSrc = m_pCarryingPlayer.EyePosition();
		Vector vecAim = m_pCarryingPlayer.GetAutoaimVector( 0.0 );

		// strong forward impulse
		float flForce = 600.0;

		pev.velocity = vecAim * flForce;

		pev.avelocity = Vector(
			Math.RandomFloat( -200, 200 ),
			Math.RandomFloat( -200, 200 ),
			Math.RandomFloat( -200, 200 )
		);

		Drop( false );
	}

	void InactiveThink()
	{
		AlwaysThink();

		LaserOff();
		RopesOff();

		// Update our PVS state
		//CheckPVSCondition();

		SetNextThink( g_Engine.time + 1.0 );
/*
		// Wake up if we're not on our side
		if ( !OnSide() and VPhysicsGetObject().GetContactPoint( NULL, NULL ) and m_bEnabled )
		{
			// Never return to life!
			SetCollisionGroup( COLLISION_GROUP_NONE );
			//ReturnToLife();
		}
		else
		{
			IPhysicsObject *pTurretPhys = VPhysicsGetObject();

			if ( !(pTurretPhys.GetGameFlags() & FVPHYSICS_PLAYER_HELD) and pTurretPhys.IsAsleep() )
				SetCollisionGroup( COLLISION_GROUP_DEBRIS_TRIGGER );
			else
				SetCollisionGroup( COLLISION_GROUP_NONE );
		}*/
	}

	void SuppressThink()
	{
		AlwaysThink();

		LaserOn();

		BaseSuppressThink();
	}

	// Purpose: Turret will continue to fire on a target's position when it loses sight of it
	void BaseSuppressThink()
	{
		//Allow descended classes a chance to do something before the think function
		if( PreThink(TURRET_SUPPRESSING) )
			return;

		//Update our think time
		SetNextThink( g_Engine.time + 0.1 );

		// Look for a new enemy
		HackFindEnemy();

		//If we've acquired an enemy, start firing at it
		if( GetEnemy() is null )
		{
			SetThink( ThinkFunction(this.ActiveThink) );
			return;
		}

		//See if we're done suppressing
		if( g_Engine.time > m_flLastSight )
		{
			// Should we look for a new target?
			//ClearEnemyMemory();
			SetEnemy( null );
			SetThink( ThinkFunction(this.SearchThink) );
			m_vecGoalAngles = GetAbsAngles();

			SpinDown();

			if( HasSpawnFlags(SF_FLOOR_TURRET_FASTRETIRE) )
			{
				// Retire quickly in this case. (The case where we saw the player, but he hid again).
				m_flLastSight = g_Engine.time + FLOOR_TURRET_SHORT_WAIT;
			}
			else
				m_flLastSight = g_Engine.time + FLOOR_TURRET_MAX_WAIT;

			return;
		}

		//Get our shot positions
		Vector vecMid = self.EyePosition();
		Vector vecMidEnemy = m_vecEnemyLKP;

		//Calculate dir and dist to enemy
		Vector vecDirToEnemy = vecMidEnemy - vecMid;

		//We want to look at the enemy's eyes so we don't jitter
		Vector vecDirToEnemyEyes = vecMidEnemy - vecMid;
		vecDirToEnemyEyes = vecDirToEnemyEyes.Normalize(); //VectorNormalize

		Vector vecAnglesToEnemy; //QAngle
		vecAnglesToEnemy = Math.VecToAngles( vecDirToEnemyEyes ); //VectorAngles( vecDirToEnemyEyes, vecAnglesToEnemy );

		//Draw debug info
		/*if( g_debug_turret.GetBool() )
		{
			NDebugOverlay::Cross3D( vecMid, -Vector(2,2,2), Vector(2,2,2), 0, 255, 0, false, 0.05 );
			NDebugOverlay::Cross3D( vecMidEnemy, -Vector(2,2,2), Vector(2,2,2), 0, 255, 0, false, 0.05 );
			NDebugOverlay::Line( vecMid, vecMidEnemy, 0, 255, 0, false, 0.05f );
		}*/

		if( m_flShotTime < g_Engine.time and m_vecEnemyLKP != g_vecZero ) //vec3_invalid
		{
			Vector vecMuzzle, vecMuzzleDir;
			//UpdateMuzzleMatrix();
			//MatrixGetColumn( m_muzzleToWorld, 0, vecMuzzleDir );
			//MatrixGetColumn( m_muzzleToWorld, 3, vecMuzzle );

			//Fire the gun
			if( DotProduct(vecDirToEnemy, vecMuzzleDir) >= 0.9848 ) // 10 degree slop
			{
				if( HasSpawnFlags(SF_FLOOR_TURRET_OUT_OF_AMMO) )
					DryFire();
				else
				{
					self.ResetSequenceInfo(); //ResetActivity();
					ChangeSequence( self.LookupSequence("fire") ); //SetActivity( (Activity) ACT_FLOOR_TURRET_FIRE );

					Shoot( vecMuzzle, vecMuzzleDir );
				}
			} 
		}
		else
			ChangeSequence( self.LookupSequence("idlealert") ); //SetActivity( (Activity) ACT_FLOOR_TURRET_OPEN_IDLE );

		//If we can see our enemy, face it
		m_vecGoalAngles.y = vecAnglesToEnemy.y;
		m_vecGoalAngles.x = vecAnglesToEnemy.x;

		//Turn to face
		UpdateFacing();

		g_Game.AlertMessage( at_notice, "BaseSuppressThink\n" );
	}

	void ReturnToLife()
	{
		m_flThrashTime = 0;

		// Enable the tip controller
		//m_pMotionController.Enable( true );

		// Return to life
		self.m_MonsterState = MONSTERSTATE_IDLE; //SetState( NPC_STATE_IDLE );
		pev.deadflag = DEAD_NO;
		//SetCollisionGroup( COLLISION_GROUP_NONE );

		// Become active again
		Enable();
	}

	// Purpose: The turret is not doing anything at all
	void DisabledThink()
	{
		AlwaysThink();

		LaserOff();
		RopesOff();

		SetNextThink( g_Engine.time + 0.5 );

		if( OnSide() )
		{
			//m_OnTipped.FireOutput( this, this );
			SetEyeState( TURRET_EYE_DEAD );
			//SetCollisionGroup( COLLISION_GROUP_DEBRIS_TRIGGER );
			SetThink( null );
		}
	}

	//-----------------------------------------------------------------------------
	// Purpose: The turret doesn't run base AI properly, which is a bad decision.
	//			As a result, it has to manually find enemies.
	//-----------------------------------------------------------------------------
	void HackFindEnemy()
	{
		// We have to refresh our memories before finding enemies, so
		// dead enemies are cleared out before new ones are added.
		//GetEnemies().RefreshMemories();

		self.Look( PORTAL_FLOOR_TURRET_RANGE ); //GetSenses().Look( PORTAL_FLOOR_TURRET_RANGE );
		SetEnemy( BestEnemy() );

		if( GetEnemy() is null )
		{
			CBasePlayer@ pPlayer = null;
			CBasePlayer@ pNearest = null;
			float flClosestDistSqr = PORTAL_FLOOR_TURRET_RANGE * PORTAL_FLOOR_TURRET_RANGE;

			for( int id = 1; id <= g_Engine.maxClients; ++id )
			{
				@pPlayer = g_PlayerFuncs.FindPlayerByIndex( id );

				if( pPlayer is null or !pPlayer.IsConnected() or !IsValidEnemy(pPlayer) )
					continue;

				Vector vVelocity;
				vVelocity = pPlayer.pev.velocity;

				// Ignore objects going too slowly
				float flVelocitySqr = vVelocity.Length() * vVelocity.Length();
				if( flVelocitySqr < m_fMovingTargetThreashold )
					continue;

				float flDist = (pPlayer.pev.origin - pev.origin).Length();
				float flDistSqr = flDist * flDist;
				if( flDistSqr < flClosestDistSqr )
				{
					flClosestDistSqr = flDistSqr;
					@pNearest = pPlayer;
				}
			}

			if( pNearest !is null )
			{
				//g_Game.AlertMessage( at_notice, "Enemy found with secondary method: %1\n", pNearest.GetClassname() );
				SetEnemy( pNearest );
				m_fMovingTargetThreashold += g_Engine.time * 15.0;
				if( m_fMovingTargetThreashold > 800.0 )
					m_fMovingTargetThreashold = 800.0;
			}
		}
		else
		{
			m_fMovingTargetThreashold = 20.0;
			//g_Game.AlertMessage( at_notice, "Enemy found with BestEnemy: %1\n", GetEnemy().GetClassname() );
		}
	}

	void LaserOff()
	{
		//CLIENT
		if( m_pBeam !is null )
			m_pBeam.pev.effects |= EF_NODRAW; //m_pBeam.AddEffects( EF_NODRAW );

		if( m_pLaserHalo !is null )
			m_pLaserHalo.pev.effects |= EF_NODRAW;

		//CLIENT

		m_bLaserOn = false;
	}

	void LaserOn()
	{
		//CLIENT - use NetworkMessage instead ??
		/*
		if ( !IsBoneAccessAllowed() )
		{
			LaserOff();
			return;
		}*/

		Vector vecEye = pev.origin;
		//self.GetAttachment( 1, vecEye, void ); //FLOOR_TURRET_PORTAL_LASER_ATTACHMENT

		Math.MakeVectors( pev.angles );
		vecEye = vecEye + g_Engine.v_forward * EYE_OFFSETS.x + g_Engine.v_up * EYE_OFFSETS.z;

		//Vector angEyeDir; //QAngle
		//self.GetAttachment( 0, void, angEyeDir ); //FLOOR_TURRET_PORTAL_EYE_ATTACHMENT

		Vector vecMuzzle, vecMuzzleDir;
		//g_EngineFuncs.AngleVectors( angEyeDir, vecMuzzleDir, void, void );
		self.GetAttachment( 0, vecMuzzle, void );

		Vector vecBonePos;
		g_EngineFuncs.GetBonePosition( self.edict(), 4, vecBonePos, void );

		//self.GetAttachment( 0, vecMuzzle, void );
		vecMuzzleDir = (vecMuzzle - vecBonePos).Normalize();

		if( m_pBeam is null )
		{
			@m_pBeam = g_EntityFuncs.CreateBeam( FLOOR_TURRET_LASER_SPRITE, LASER_WIDTH ); //"effects/redlaser1.vmt" 0.2
			m_pBeam.SetColor( 255, 32, 32 );
			m_pBeam.SetBrightness( 255 );
			m_pBeam.SetNoise( 0 );
			m_pBeam.SetWidth( LASER_WIDTH ); //0.75
			//m_pBeam.SetEndWidth( 0 );
			m_pBeam.SetScrollRate( 0 );
			//m_pBeam.SetFadeLength( 0 );
			//m_pBeam.SetHaloTexture( m_sLaserHaloSprite );
			//m_pBeam.SetHaloScale( 4.0 );
			//m_pBeam.SetCollisionGroup( COLLISION_GROUP_NONE );
			m_pBeam.PointsInit( vecEye + vecMuzzleDir, vecEye );
			//m_pBeam.SetBeamFlag( FBEAM_REVERSED );
			m_pBeam.SetStartEntity( self.entindex() );
			//m_pBeam.pev.spawnflags |= SF_BEAM_TEMPORARY;
			//m_pBeam.LiveForTime( 1.0 );
		}
		else
			m_pBeam.pev.effects &= ~EF_NODRAW; //m_pBeam.RemoveEffects( EF_NODRAW );

		if( m_pLaserHalo is null )
		{
			@m_pLaserHalo = g_EntityFuncs.CreateSprite( FLOOR_TURRET_HALO_SPRITE, self.GetOrigin(), false ); //GetLocalOrigin()
			if( m_pLaserHalo is null )
				return;

			m_pLaserHalo.SetTransparency( kRenderGlow, 255, 0, 0, 128, kRenderFxNoDissipation ); //kRenderWorldGlow

			float scale = LaserEndPointSize();

			if( scale < 0 or scale > MAX_SPRITE_SCALE )
			{
				//DevMsg( "LEVEL DESIGN ERROR: Sprite %s with bad scale %f [0..%f]\n", GetDebugName(), m_flSpriteScale.Get(), MAX_SPRITE_SCALE );

				scale = Math.clamp( 0.0, MAX_SPRITE_SCALE, LaserEndPointSize() );
			}

			m_pLaserHalo.SetBrightness( 255 );
			m_pLaserHalo.SetScale( scale );
		}
		else
			m_pLaserHalo.pev.effects &= ~EF_NODRAW;

		// Trace to find an endpoint
		Vector vEndPoint;
		/*float fEndFraction;
		Ray_t rayPath;
		rayPath.Init( vecEye, vecEye + vecMuzzleDir * FLOOR_TURRET_PORTAL_LASER_RANGE );

		CTraceFilterSkipClassname traceFilter( this, "prop_energy_ball", COLLISION_GROUP_NONE );

		if ( UTIL_Portal_TraceRay_Beam( rayPath, MASK_SHOT, &traceFilter, &fEndFraction ) )
			vEndPoint = vecEye + vecMuzzleDir * FLOOR_TURRET_PORTAL_LASER_RANGE;	// Trace went through portal and endpoint is unknown
		else
			vEndPoint = vecEye + vecMuzzleDir * FLOOR_TURRET_PORTAL_LASER_RANGE * fEndFraction;	// Trace hit a wall

		// The beam is backwards, sort of. The endpoint is the sniper. This is
		// so that the beam can be tapered to very thin where it emits from the turret.*/

		TraceResult tr;
		g_Utility.TraceLine( vecEye, vecEye + vecMuzzleDir * FLOOR_TURRET_PORTAL_LASER_RANGE, ignore_monsters, self.edict(), tr ); //dont_ignore_monsters ??
		vEndPoint = vecEye + vecMuzzleDir * FLOOR_TURRET_PORTAL_LASER_RANGE * tr.flFraction;

		m_pBeam.PointsInit( vEndPoint, vecEye );
		m_pLaserHalo.pev.origin = vEndPoint;

		//m_pBeam.SetHaloScale( LaserEndPointSize() );
		//CLIENT

		m_bLaserOn = true;
	}

	void RopesOn()
	{
		/*for ( int iRope = 0; iRope < PORTAL_FLOOR_TURRET_NUM_ROPES; ++iRope )
		{
			// Make a rope if it doesn't exist
			if ( !m_hRopes[ iRope ] )
			{
				CFmtStr str;

				int iStartIndex = LookupAttachment( str.sprintf( "Wire%i_start", iRope + 1 ) );
				int iEndIndex = LookupAttachment( str.sprintf( "Wire%i_end", iRope + 1 ) );

				m_hRopes[ iRope ] = CRopeKeyframe::Create( this, this, iStartIndex, iEndIndex );
				if ( m_hRopes[ iRope ] )
				{
					m_hRopes[ iRope ].m_Width = 0.7;
					m_hRopes[ iRope ].m_nSegments = ROPE_MAX_SEGMENTS;
					m_hRopes[ iRope ].EnableWind( false );
					m_hRopes[ iRope ].SetupHangDistance( 9.0f );
					m_hRopes[ iRope ].m_bConstrainBetweenEndpoints = true;;
				}
			}
		}*/
	}

	void RopesOff()
	{
		/*for ( int iRope = 0; iRope < PORTAL_FLOOR_TURRET_NUM_ROPES; ++iRope )
		{
			// Remove rope if it's alive
			if ( m_hRopes[ iRope ] )
			{
				 UTIL_Remove( m_hRopes[ iRope ] );
				 m_hRopes[ iRope ] = NULL;
			}
		}*/
	}

	void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value )
	{
		CBasePlayer@ pPlayer = cast<CBasePlayer@>( pActivator );
		if( pPlayer !is null )
		{
			if( m_pCarryingPlayer is null )
				Pickup( pPlayer );
		}

		//HackFindEnemy();
		/*switch( useType )
		{
			case USE_OFF:
				Disable();
				break;
			case USE_ON:
				Enable();
				break;
			case USE_SET:
				break;
			case USE_TOGGLE:
				Toggle();
				break;
		}*/
	}

	void Pickup( CBasePlayer@ pPlayer )
	{
		if( pev.deadflag == DEAD_NO and m_bEnabled )
		{
			m_bActive = true;
			SetThink( ThinkFunction(this.HeldThink) );

			//g_Game.AlertMessage( at_notice, "%1 new holder!\n", self.GetClassname() );

			@m_pCarryingPlayer = pPlayer;
			m_bCarriedByPlayer = true;

			//pev.velocity = (vecTarget - pev.origin) * 5.0;

			//pev.solid = SOLID_NOT; //SOLID_NOT causes it to not trigger triggers :[

			m_flDropDelay = g_Engine.time + 0.2;
			//m_bAligning = true; //start with smooth rotation

			//SetThink( ThinkFunction(this.PhysboxThink) );
			SetNextThink( g_Engine.time );

			GetPortalGun( pPlayer ).Pickup();
		}
	}

	void Drop( bool bStopVelocity = true )
	{
		if( m_pCarryingPlayer !is null )
			GetPortalGun( m_pCarryingPlayer ).Drop();

		//g_Game.AlertMessage( at_notice, "%1 Drop\n", GetDebugName() );

		//pev.solid = SOLID_SLIDEBOX;

		@m_pCarryingPlayer = null;
		m_bCarriedByPlayer = false;

		if( bStopVelocity )
		{
			pev.velocity = g_vecZero;
			pev.avelocity = g_vecZero;
		}

		//m_bAligning = false;
	}

	weapon_portalgun::CWeaponPortalgun@ GetPortalGun( CBasePlayer@ pPlayer )
	{
		if( pPlayer is null )
			return null;

		weapon_portalgun::CWeaponPortalgun@ pPortalGun = null;

		CBasePlayerWeapon@ pWeapon = cast<CBasePlayerWeapon@>( pPlayer.m_hActiveItem.GetEntity() );
		if( pWeapon !is null and pWeapon.pev.ClassNameIs("weapon_portalgun") )
			@pPortalGun = cast<weapon_portalgun::CWeaponPortalgun@>( CastToScriptClass(pWeapon) );

		return pPortalGun;
	}
			
	// Purpose: Toggle the turret's state
	void Toggle()
	{
		//This turret is on its side, it can't function
		if( OnSide() or !self.IsAlive() )
			return;

		//Toggle the state
		if( m_bEnabled )
			Disable();
		else 
			Enable();
	}

	// Purpose: Enable the turret and deploy
	void Enable()
	{
		// Don't interrupt blowing up!
		if( m_bSelfDestructing )
			return;

		// Always allow us to come back to life, even if not right now
		m_bEnabled = true;

		//This turret is on its side, it can't function
		if( OnSide() or !self.IsAlive() )
			return;

		// if the turret is flagged as an autoactivate turret, re-enable its ability open self.
		if( HasSpawnFlags(SF_FLOOR_TURRET_AUTOACTIVATE) )
			m_bAutoStart = true;

		SetThink( ThinkFunction(this.Deploy) );
		SetNextThink( g_Engine.time + 0.05 );
	}

	// Purpose: Retire the turret until enabled again
	void Disable()
	{
		//This turret is on its side, it can't function
		if( OnSide() or !self.IsAlive() or m_bSelfDestructing )
			return;

		if( m_bEnabled )
		{
			m_bEnabled = false;
			m_bAutoStart = false;

			SetEnemy( null );
			SetThink( ThinkFunction(this.Retire) );
			SetNextThink( g_Engine.time + 0.1 );
		}
		else
			SetThink( ThinkFunction(this.DisabledThink) );
	}

	void SpinUp()
	{
	}

	void SpinDown()
	{
		m_bHasGreetedEnemy = false;
	}

	void DryFire()
	{
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, arrsSounds[SND_DRYFIRE], 0.75, ATTN_NORM, 0, 100 + Math.RandomLong(-5, 0) ); //SNDLVL_70dB //EmitSound( "NPC_FloorTurret.DryFire");
		g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, arrsSounds[SND_ACTIVATE], VOL_NORM, ATTN_NORM ); //SNDLVL_IDLE //EmitSound( "NPC_FloorTurret.Activate" );

		if( Math.RandomFloat(0, 1) > 0.5 )
			m_flShotTime = g_Engine.time + Math.RandomFloat( 1.0, 2.5 );
		else
			m_flShotTime = g_Engine.time;
	}

	float GetPointsForDamage( float flDamage )
	{
		float flTemp = pev.max_health / NPC_HEALTH;
		return flDamage / pev.max_health * ( flTemp + flTemp );
	}




	void SetViewOffset( const Vector &in vecViewOfs )
	{
		pev.view_ofs = vecViewOfs;
	}

	void SetNextThink( float thinktime )
	{
		pev.nextthink = thinktime;
	}

	bool HasSpawnFlags( int iSpawnFlag )
	{
		return pev.SpawnFlagBitSet( iSpawnFlag );
	}

	bool HasFlags( int iFlagVariable, int iFlags )
	{
		return (iFlagVariable & iFlags) != 0;
	}

	int PrecacheModel( const string &in sModelName )
	{
		return g_Game.PrecacheModel( sModelName );
	}

	void SetModel( const string &in sModelName )
	{
		g_EntityFuncs.SetModel( self, sModelName );
	}

	void SetModelName( const string &in sModel )
	{
		pev.model = sModel;
	}

	const string GetModelName() const //const lmao const
	{
		return string( pev.model );
	}

	int GetWaterLevel()
	{
		return pev.waterlevel;
	}

	/*CBaseEntity@ GetEnemy()
	{
		CBaseEntity@ pEnemy = self.m_hEnemy.GetEntity();

		if( IsValidEnemy(pEnemy) )
			return pEnemy;

		self.m_hEnemy = null;

		return null;
	}*/

	CBaseEntity@ GetEnemy()
	{
		return self.m_hEnemy.GetEntity();
	}

	void SetEnemy( CBaseEntity@ pEnemy, bool bSetCondNewEnemy = true )
	{
		if( self.m_hEnemy.GetEntity() !is pEnemy )
		{
			//ClearAttackConditions();
			//VacateStrategySlot();
			//m_GiveUpOnDeadEnemyTimer.Stop();

			// If we've just found a new enemy, set the condition
			if( pEnemy !is null and bSetCondNewEnemy )
				SetCondition( bits_COND_NEW_ENEMY );
		}

		// Assert( (pEnemy == NULL) or (m_NPCState == NPC_STATE_COMBAT) );

		self.m_hEnemy = EHandle( pEnemy );
		//m_flTimeEnemyAcquired = g_Engine.time;

		//m_LastShootAccuracy = -1;
		//m_TotalShots		= 0;
		//m_TotalHits			= 0;

		if( pEnemy is null )
			ClearCondition( bits_COND_NEW_ENEMY );
	}

	void SetCondition( int iCondition )
	{
		self.SetConditions( iCondition );
	}

	void ClearCondition( int iCondition )
	{
		self.ClearConditions( iCondition );
	}

	float AngleNormalize( float angle )
	{
		angle = fmodf( angle, 360.0 );
		if( angle > 180 )
			angle -= 360;

		if( angle < -180 )
			angle += 360;

		return angle;
	}

	double trunc( double x )
	{
	  return x < 0 ? -Math.Floor( -x ) : Math.Floor( x );
	  //or return x < 0 ? Math.Ceil( x ) : Math.Floor( x );
	}

	double fmodf( double x, double y )
	{
	  return x - trunc( x / y ) * y;
	}

	//??
	Vector GetAbsAngles()
	{
		return pev.angles;
	}

	Vector GetEnemyLKP()
	{
		return m_vecEnemyLKP;
	}

	int GetSequence()
	{
		return pev.sequence;
	}

	void ChangeSequence( int iSequence )
	{
		pev.sequence = iSequence;
		pev.frame = 0;
		self.ResetSequenceInfo();
	}

	CBaseEntity@ BestEnemy()
	{
		//CBasePlayer@ pEnemy = null;
		CBaseEntity@ pEnemy = null;
		//@pEnemy = FindClosestEnemy( PORTAL_FLOOR_TURRET_RANGE );

		@pEnemy = self.BestVisibleEnemy();

		return pEnemy;
	}

	CBasePlayer@ FindClosestEnemy( float flRadius )
	{
		CBasePlayer@ pPlayer = null;
		CBasePlayer@ pEnemy = null;
		float fNearest = flRadius;

		for( int id = 1; id <= g_Engine.maxClients; ++id )
		{
			@pPlayer = g_PlayerFuncs.FindPlayerByIndex( id );
			
			if( pPlayer is null or !pPlayer.IsConnected() or !IsValidEnemy(pPlayer) )
				continue;

			float fDist = (pPlayer.pev.origin - pev.origin).Length();
			if( fDist < fNearest )
			{
				fNearest = fDist;
				@pEnemy = pPlayer;
			}
		}

		return pEnemy;
	}

	bool IsValidEnemy( CBaseEntity@ pEnemy )
	{
		if( pEnemy is null or !pEnemy.IsAlive() or pEnemy.pev.FlagBitSet(FL_NOTARGET) )
			return false;

		int relation = self.IRelationship( pEnemy );
		if( relation <= R_NO )
			return false;

		if( !self.FInViewCone(pEnemy) or !self.FVisible(pEnemy, true) )
			return false;

		return true;
	}

	void FireBullets( FireBulletsInfo_t info )
	{
		self.FireBullets(	info.m_iShots, 
											info.m_vecSrc, 
											info.m_vecDirShooting, 
											info.m_vecSpread, 
											info.m_flDistance, 
											BULLET_PLAYER_CUSTOMDAMAGE, 
											info.m_iTracerFreq, 
											int(info.m_flDamage) );
	}

	Vector GetShootEnemyDir( const Vector &in shootOrigin, bool bNoisy = false )
	{
		CBaseEntity@ pEnemy = GetEnemy();

		if( pEnemy !is null )
		{
			Vector vecEnemyLKP = GetEnemyLKP();

			Vector vecEnemyOffset = pEnemy.BodyTarget( shootOrigin ) - pEnemy.GetOrigin(); //BodyTarget( shootOrigin, bNoisy )

	/*#ifdef PORTAL
			// Translate the enemy's position across the portals if it's only seen in the portal view cone
			if ( !FInViewCone( vecEnemyLKP ) or !FVisible( vecEnemyLKP ) )
			{
				CProp_Portal *pPortal = FInViewConeThroughPortal( vecEnemyLKP );
				if ( pPortal )
				{
					UTIL_Portal_VectorTransform( pPortal.m_hLinkedPortal.MatrixThisToLinked(), vecEnemyOffset, vecEnemyOffset );
					UTIL_Portal_PointTransform( pPortal.m_hLinkedPortal.MatrixThisToLinked(), vecEnemyLKP, vecEnemyLKP );
				}
			}
	#endif*/

			Vector retval = vecEnemyOffset + vecEnemyLKP - shootOrigin;
			retval = retval.Normalize(); //VectorNormalize
			return retval;
		}
		else
		{
			Vector forward;
			g_EngineFuncs.AngleVectors( pev.angles, forward, void, void ); //GetLocalAngles()
			return forward;
		}
	}

	//-----------------------------------------------------------------------------
	// Similar to calling GetShootEnemyDir, but returns the exact trajectory to 
	// fire the bullet along, after calculating for target speed, location, 
	// concealment, etc.
	//
	// Ultimately, this code results in the shooter aiming his weapon somewhere ahead of
	// a moving target. Since bullet traces are instant, aiming ahead of a target
	// will result in more misses than hits. This is designed to provide targets with
	// a bonus when moving perpendicular to the shooter's line of sight. 
	//
	// Do not confuse this with leading a target in an effort to more easily hit it.
	// 
	// This code PENALIZES a target for moving directly along the shooter's line of sight.
	//
	// This code REWARDS a target for moving perpendicular to the shooter's line of sight.
	//-----------------------------------------------------------------------------
	Vector GetActualShootTrajectory( const Vector &in shootOrigin )
	{
		if( GetEnemy() is null )
			return GetShootEnemyDir( shootOrigin );

		// If we're above water shooting at a player underwater, bias some of the shots forward of
		// the player so that they see the cool bubble trails in the water ahead of them.
		if( GetEnemy().IsPlayer() and pev.waterlevel != 3 and GetEnemy().pev.waterlevel == 3 )
		{
			if( Math.RandomLong(0, 4) < 3 )
			{
				Vector vecEnemyForward;
				g_EngineFuncs.AngleVectors( GetEnemy().pev.angles, vecEnemyForward, void, void ); //GetEnemy().GetVectors( &vecEnemyForward, NULL, NULL );
				vecEnemyForward.z = 0;

				// Lead up to a second ahead of them unless they are moving backwards.
				Vector vecEnemyVelocity = GetEnemy().pev.velocity; //GetEnemy().GetSmoothedVelocity();
				vecEnemyVelocity = vecEnemyVelocity.Normalize(); //VectorNormalize
				float flVelocityScale = DotProduct( vecEnemyForward, vecEnemyVelocity ); //vecEnemyForward.Dot( vecEnemyVelocity );
				if( flVelocityScale < 0.0 )
					flVelocityScale = 0.0;

				Vector vecAimPos = GetEnemy().EyePosition() + ( 48.0 * vecEnemyForward ) + (flVelocityScale * GetEnemy().pev.velocity ); //GetEnemy().GetSmoothedVelocity()
				//NDebugOverlay::Cross3D(vecAimPos, Vector(-16,-16,-16), Vector(16,16,16), 255, 255, 0, true, 1.0f );
				
				//vecAimPos.z = UTIL_WaterLevel( vecAimPos, vecAimPos.z, vecAimPos.z + 400.0f );
				//NDebugOverlay::Cross3D(vecAimPos, Vector(-32,-32,-32), Vector(32,32,32), 255, 0, 0, true, 1.0f );

				Vector vecShotDir = vecAimPos - shootOrigin;
				vecShotDir = vecShotDir.Normalize(); //VectorNormalize
				return vecShotDir;
			}
		}

		Vector vecProjectedPosition = GetActualShootPosition( shootOrigin );

		Vector shotDir = vecProjectedPosition - shootOrigin;
		shotDir = shotDir.Normalize(); //VectorNormalize

		//CollectShotStats( shootOrigin, shotDir );

		// NOW we have a shoot direction. Where a 100% accurate bullet should go.
		// Modify it by weapon proficiency.
		// construct a manipulator 
		CShotManipulator manipulator( shotDir );

		// Apply appropriate accuracy.
		bool bUsePerfectAccuracy = false;
		/*if( GetEnemy() !is null and GetEnemy().pev.ClassNameIs("npc_bullseye") ) //GetEnemy().Classify() == CLASS_BULLSEYE
		{
			CNPC_Bullseye *pBullseye = dynamic_cast<CNPC_Bullseye*>(GetEnemy()); 
			if ( pBullseye and pBullseye.UsePerfectAccuracy() )
			{
				bUsePerfectAccuracy = true;
			}
		}*/

		if( !bUsePerfectAccuracy )
		{
			manipulator.ApplySpread( GetAttackSpread( GetEnemy() ), 1.0 ); //GetSpreadBias( GetActiveWeapon(), GetEnemy() )
			shotDir = manipulator.GetResult();
		}

		// Look for an opportunity to make misses hit interesting things.
		CBaseMonster@ pEnemy; //CBaseCombatCharacter

		@pEnemy = GetEnemy().MyMonsterPointer(); //MyCombatCharacterPointer

		if( pEnemy !is null and ShouldShootMissTarget() ) //pEnemy.ShouldShootMissTarget(this)
		{
			Vector vecEnd = shootOrigin + shotDir * 8192;
			TraceResult tr;

			g_Utility.TraceLine( shootOrigin, vecEnd, dont_ignore_monsters, self.edict(), tr ); //AI_TraceLine(shootOrigin, vecEnd, MASK_SHOT, this, COLLISION_GROUP_NONE, &tr);

			if( tr.flFraction != 1.0 and tr.pHit !is null and tr.pHit.vars.takedamage != DAMAGE_NO )
			{
				// Hit something we can harm. Just shoot it.
				return manipulator.GetResult();
			}

			// Find something interesting around the enemy to shoot instead of just missing.
			CBaseEntity@ pMissTarget = FindMissTarget(); //pEnemy.FindMissTarget()

			if( pMissTarget !is null )
			{
				shotDir = pMissTarget.GetOrigin() - shootOrigin; //WorldSpaceCenter
				shotDir = shotDir.Normalize(); //VectorNormalize
			}
		}

		return shotDir;
		//return GetShootEnemyDir( shootOrigin ); //TEMP
	}

	bool ShouldShootMissTarget()
	{
		if( g_Engine.time > m_flTargetFindTime )
		{
			// Put this off into the future again.
			m_flTargetFindTime = g_Engine.time + Math.RandomFloat( 3.0, 5.0 );
			return true;
		}

		return false;
	} 

	CBaseEntity@ FindMissTarget()
	{
		array<CBaseEntity@> pMissCandidates( MAX_MISS_CANDIDATES );
		int numMissCandidates = 0;

		CBasePlayer@ pPlayer = GetLocalPlayer(); //UTIL_GetLocalPlayer
		array<CBaseEntity@> pEnts( 256 );
		Vector		radius( 100, 100, 100);
		Vector		vecSource = self.GetOrigin(); //GetAbsOrigin

		int numEnts = g_EntityFuncs.EntitiesInBox( pEnts, vecSource-radius, vecSource+radius, 0 );

		for( int i = 0; i < numEnts; i++ )
		{
			if( pEnts[i] is null )
				continue;

			// New rule for this system. Don't shoot what the player won't see.
			if( pPlayer !is null and !pPlayer.FInViewCone(pEnts[i]) )
				continue;

			if( numMissCandidates >= MAX_MISS_CANDIDATES )
				break;

			//See if it's a good target candidate
			if( pEnts[i].pev.ClassNameIs("prop_dynamic") or 
				 pEnts[i].pev.ClassNameIs("prop_physics") or 
				 pEnts[i].pev.ClassNameIs("physics_prop") )
			{
				@pMissCandidates[ numMissCandidates++ ] = pEnts[i];
				continue;
			}
		}

		if( numMissCandidates == 0 )
			return null;

		return pMissCandidates[ Math.RandomLong(0, numMissCandidates - 1) ];
	}

	//-----------------------------------------------------------------------------
	// Purpose: Return the actual position the NPC wants to fire at when it's trying
	//			to hit it's current enemy.
	//-----------------------------------------------------------------------------
	Vector GetActualShootPosition( const Vector &in shootOrigin )
	{
		// Project the target's location into the future.
		Vector vecEnemyLKP = GetEnemyLKP();
		Vector vecEnemyOffset = GetEnemy().BodyTarget( shootOrigin ) - GetEnemy().GetOrigin(); //GetAbsOrigin
		Vector vecTargetPosition = vecEnemyOffset + vecEnemyLKP;

	/*#ifdef PORTAL
		// Check if it's also visible through portals
		CProp_Portal *pPortal = FInViewConeThroughPortal( vecEnemyLKP );
		if ( pPortal )
		{
			// Get the target's position through portals
			Vector vecEnemyOffsetTransformed;
			Vector vecEnemyLKPTransformed;
			UTIL_Portal_VectorTransform( pPortal.m_hLinkedPortal.MatrixThisToLinked(), vecEnemyOffset, vecEnemyOffsetTransformed );
			UTIL_Portal_PointTransform( pPortal.m_hLinkedPortal.MatrixThisToLinked(), vecEnemyLKP, vecEnemyLKPTransformed );
			Vector vecTargetPositionTransformed = vecEnemyOffsetTransformed + vecEnemyLKPTransformed;

			// Get the distance to the target with and without portals
			float fDistanceToEnemyThroughPortalSqr = GetAbsOrigin().DistToSqr( vecTargetPositionTransformed );
			float fDistanceToEnemySqr = GetAbsOrigin().DistToSqr( vecTargetPosition );

			if ( fDistanceToEnemyThroughPortalSqr < fDistanceToEnemySqr or !FInViewCone( vecEnemyLKP ) or !FVisible( vecEnemyLKP ) )
			{
				// We're better off shooting through the portals
				vecTargetPosition = vecTargetPositionTransformed;
			}
		}
	#endif*/

		//Vector vecSmoothedVelocity = GetEnemy().pev.velocity;
		//vecSmoothedVelocity = vecSmoothedVelocity * 0.9 + pev.velocity * ( 1 - 0.9 ); //GetAbsVelocity()

		// lead for some fraction of a second.
		return (vecTargetPosition + ( GetEnemy().pev.velocity * 0.0 )); //GetSmoothedVelocity		//ai_lead_time.GetFloat()
		//return (vecTargetPosition + ( vecSmoothedVelocity * 0.0 ));
	}

	void CheckFalling()
	{
		if( !pev.FlagBitSet(FL_ONGROUND) and pev.velocity.z < 0 )
			pev.flFallVelocity = abs( pev.velocity.z );

		//g_Game.AlertMessage( at_notice, "flFallVelocity: %1\n", flFallVelocity );

		if( pev.FlagBitSet(FL_ONGROUND) and pev.deadflag == DEAD_NO and pev.flFallVelocity >= PLAYER_FALL_PUNCH_THRESHHOLD )
		{
			if( pev.waterlevel > 0 )
			{
			}
			else if( pev.flFallVelocity > PLAYER_MAX_SAFE_FALL_SPEED )
			{
				pev.flFallVelocity -= PLAYER_MAX_SAFE_FALL_SPEED;
				float flFallDamage = pev.flFallVelocity * DAMAGE_FOR_FALL_SPEED; //g_pGameRules.FlPlayerFallDamage( this );

				if( flFallDamage > pev.health )
				{//splat
					// note: play on item channel because we play footstep landing on body channel
					//EMIT_SOUND(ENT(pev), CHAN_ITEM, "common/bodysplat.wav", 1, ATTN_NORM);
				}

				if( flFallDamage > 0 )
				{
					entvars_t@ pevWorld = g_EntityFuncs.Instance( 0 ).pev;
					self.TakeDamage( pevWorld, pevWorld, flFallDamage, DMG_FALL );
				}
			}

			pev.flFallVelocity = 0;
		}
	}

	void Touch( CBaseEntity@ pOther )
	{
		//worldspawn
		if( pOther !is g_EntityFuncs.Instance(0) )
		{
			//g_Game.AlertMessage( at_notice, "Toucher velocity: %1\n", pOther.pev.velocity.Length() );
			if( pOther.pev.velocity.Length() >= PLAYER_FATAL_FALL_SPEED )
				Killed( pOther.pev, GIB_NEVER );
		}

		BaseClass.Touch( pOther );
	}

 	int TakeDamage( entvars_t@ pevInflictor, entvars_t@ pevAttacker, float flDamage, int bitsDamageType ) //int OnTakeDamage( const CTakeDamageInfo &info )
	{
		//turrets don't damage eachother
		if( pev.deadflag == DEAD_NO and HasFlags(bitsDamageType, DMG_BULLET) and !pevAttacker.FlagBitSet(FL_CLIENT) ) //( info.GetDamageType() & DMG_BULLET ) and !info.GetAttacker().IsPlayer()
		{
			flDamage = 0.0;

			if( g_Engine.time > m_fNextTalk )
			{
				g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsSounds[Math.RandomLong(SND_TALK_SHOTAT1, SND_TALK_SHOTAT3)], VOL_NORM, ATTN_NORM ); //SNDLVL_80dB //EmitSound( GetTurretTalkName( PORTAL_TURRET_SHOTAT ) );
				m_fNextTalk = g_Engine.time + 3.0;
			}
		}

		//return BaseClass::OnTakeDamage( info );
		return BaseClass.TakeDamage( pevInflictor, pevAttacker, flDamage, bitsDamageType );
	}

	void Killed( entvars_t@ pevAttacker, int iGib )
	{
		//TEMP
		m_bDissolving = true;

		if( IsDissolving() and pev.deadflag != DEAD_DEAD )
		{
			Dissolve();
			pev.deadflag = DEAD_DEAD;
		}

		//BaseClass.Killed( pevAttacker, iGib );
	}

	void Dissolve()
	{
		CSprite@ pDissolve = g_EntityFuncs.CreateSprite( FLOOR_TURRET_PORTAL_MODEL, pev.origin, false, 0.0 ); //FLOOR_TURRET_PORTAL_MODEL

		pDissolve.SetTransparency( kRenderTransTexture, 0, 0, 0, 128, 0 );
		pDissolve.pev.movetype = MOVETYPE_FLY;
		pDissolve.pev.frame = pev.frame;
		pDissolve.pev.sequence = pev.sequence;
		pDissolve.pev.velocity = pev.velocity / 10;
		pDissolve.pev.velocity.z = 0;
		pDissolve.pev.velocity.z += 5;
		pDissolve.SetScale( pev.scale * 1.12 );
		pDissolve.SUB_StartFadeOut();
		pDissolve.pev.avelocity = Vector( Math.RandomFloat(-15, 15), Math.RandomFloat(-15, 15), Math.RandomFloat(-15, 15) );
		pDissolve.pev.avelocity = pDissolve.pev.avelocity * 2;
		//pDissolve.pev.effects |= EF_INVLIGHT;

		g_EntityFuncs.Remove( self );
	}

	bool IsDissolving() { return m_bDissolving; }  //{ return HasFlags( FL_DISSOLVING ); } 

	void UpdateOnRemove()
	{
		if( IsDissolving() )
			g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsSounds[SND_TALK_DISSOLVED], VOL_NORM, ATTN_NORM ); //SNDLVL_75dB //EmitSound( GetTurretTalkName( PORTAL_TURRET_DISSOLVED ) );

		LaserOff();
		RopesOff();

		BaseUpdateOnRemove();
	}

	void BaseUpdateOnRemove()
	{
		/*if ( m_pMotionController != NULL )
		{
			UTIL_Remove( m_pMotionController );
			m_pMotionController = NULL;
		}

		if ( m_hLaser != NULL )
		{
			UTIL_Remove( m_hLaser );
			m_hLaser = NULL;
		}*/

		if( m_pEyeGlow !is null )
		{
			g_EntityFuncs.Remove( m_pEyeGlow );
			@m_pEyeGlow = null;
		}

		BaseClass.UpdateOnRemove();
	}

	void AlwaysThink()
	{
		if( m_bOutOfAmmo and m_fBeamFlickerTime < g_Engine.time )
		{
			m_fBeamFlickerTime = g_Engine.time + Math.RandomFloat( 0.05, 0.3 );
			m_bBeamFlickerOff = !m_bBeamFlickerOff;
		}

		//CLIENT
		if( m_bLaserOn and !m_bBeamFlickerOff )
			LaserOn();
		else
			LaserOff();

		if( m_pEyeGlow !is null )
		{
			Vector vecEye = pev.origin;
			Math.MakeVectors( pev.angles );
			vecEye = vecEye + g_Engine.v_forward * EYE_OFFSETS.x + g_Engine.v_up * EYE_OFFSETS.z;
			m_pEyeGlow.pev.origin = vecEye;

			UpdateSprite();
		}
		//CLIENT

		if( !IsBeingCarriedByPlayer() )
			CheckFalling();
	}

	float LaserEndPointSize()
	{
		return 1.0;
		//return ( ( Math.max(0.0, sin( g_Engine.time * Math.PI + m_fPulseOffset ) ) ) * FLOOR_TURRET_PORTAL_END_POINT_PULSE_SCALE + 3.0 ) * 1.5; //sinf
	}

	//From Half-Life 2 Sprite.cpp
	void UpdateSprite()
	{
		if( m_flSpriteScale != m_flDestScale )
		{
			m_flStartScale			= m_flDestScale;
			m_flDestScale			= m_flSpriteScale;
			m_flScaleTimeStart	= g_Engine.time;
		}

		if( m_nBrightness != m_nDestBrightness )
		{
			m_nStartBrightness			= m_nDestBrightness;
			m_nDestBrightness			= m_nBrightness;
			m_flBrightnessTimeStart		= g_Engine.time;
		}

		m_pEyeGlow.SetScale( GetRenderScale() );
		m_pEyeGlow.SetBrightness( GetRenderBrightness() );
	}

	void SetBrightness( CSprite@ pSprite, int brightness, float time = 0.0 )
	{
		m_nBrightness			= brightness;	//Take our current position as our starting position
		m_flBrightnessTime	= time;
	}

	void SetSpriteScale( CSprite@ pSprite, float scale )
	{
		if( scale != m_flSpriteScale )
		{
			m_flSpriteScale = scale;	//Take our current position as our new starting position
			// The surrounding box is based on sprite scale... it changes, box is dirty
			//CollisionProp().MarkSurroundingBoundsDirty();
		}
	}

	void SetScale( CSprite@ pSprite, float scale, float time = 0.0 )
	{
		m_flScaleTime = time;
		SetSpriteScale( pSprite, scale );
	}

	float GetRenderScale()
	{
		//See if we're done scaling
		if( m_flScaleTime == 0 or (m_flScaleTimeStart + m_flScaleTime) < g_Engine.time )
			return m_flSpriteScale;

		//Get our percentage
		float timeDelta = ( g_Engine.time - m_flScaleTimeStart ) / m_flScaleTime;

		//Return the result
		return ( m_flStartScale + ( ( m_flDestScale - m_flStartScale  ) * timeDelta ) );
	}

	int GetRenderBrightness()
	{
		//See if we're done scaling
		if( m_flBrightnessTime == 0 or (m_flBrightnessTimeStart + m_flBrightnessTime) < g_Engine.time )
			return m_nBrightness;

		//Get our percentage
		float timeDelta = ( g_Engine.time - m_flBrightnessTimeStart ) / m_flBrightnessTime;

		float brightness = ( float(m_nStartBrightness) + ( float(m_nDestBrightness - m_nStartBrightness ) * timeDelta ) );

		//Return the result
		return int( brightness );
	}

	CBasePlayer@ GetLocalPlayer()
	{
		return g_PlayerFuncs.FindPlayerByIndex( 1 );
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "npc_portal_turret_floor::CNPC_Portal_FloorTurret", "npc_portal_turret_floor" );
	g_Game.PrecacheOther( "npc_portal_turret_floor" );
}

} //end of namespace npc_portal_turret_floor


/*
GetSmoothedVelocity
SMOOTHING_FACTOR = 0.9
m_vecSmoothedVelocity = m_vecSmoothedVelocity * SMOOTHING_FACTOR + GetAbsVelocity() * ( 1 - SMOOTHING_FACTOR );
*/