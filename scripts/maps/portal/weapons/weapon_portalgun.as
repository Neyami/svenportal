/*
	Author: Nero

	From Portal weapon_portalgun.cpp
*/

namespace weapon_portalgun
{

const string PW_NAME							= "weapon_portalgun";
const string PW_ANIMEXT						= "egon";

const int PW_SLOT									= 1;
const int PW_POSITION							= 17;
const int PW_WEIGHT								= 100;


const float PW_TIME_DRAW					= 1.23;
const float PW_TIME_IDLE						= 1.23;

const string MODEL_VIEW						= "models/portal/weapons/v_portalgun.mdl";
const string MODEL_PLAYER					= "models/portal/weapons/w_portalgun.mdl"; //TEMP
const string MODEL_WORLD					= "models/portal/weapons/w_portalgun.mdl";

enum pw_e
{
	ANIM_IDLE = 0,
	ANIM_FIRE,
	ANIM_FIZZLE,
	ANIM_DRAW,
	ANIM_HOLSTER,
	ANIM_IDLETOLOW,
	ANIM_LOWTOIDLE,
	ANIM_LOWIDLE,
	ANIM_DRYFIRE,
	ANIM_IDLE_LAYER,
	ANIM_IDLE_TO_CARRYING,
	ANIM_IDLE_CARRYING,
	ANIM_CARRYING_TO_IDLE
};

enum pwsounds_e
{
	SND_DRYFIRE = 0
};

const array<string> arrsSounds =
{
	"hl2/weapons/pistol/pistol_empty.wav"
};

class CWeaponPortalgun : ScriptBasePlayerWeaponEntity
{
	protected CBasePlayer@ m_pPlayer
	{
		get const { return cast<CBasePlayer@>(self.m_hPlayer.GetEntity()); }
		set { self.m_hPlayer = EHandle(@value); }
	}

	private bool m_bActive;

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, self.GetW_Model(MODEL_WORLD) );
		self.m_iClip = WEAPON_NOCLIP;
		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();

		g_Game.PrecacheModel( MODEL_VIEW );
		g_Game.PrecacheModel( MODEL_PLAYER );
		g_Game.PrecacheModel( MODEL_WORLD );

		for( uint i = 0; i < arrsSounds.length(); ++i )
			g_SoundSystem.PrecacheSound( arrsSounds[i] );

		//Precache these for downloading
		for( uint i = 0; i < arrsSounds.length(); ++i )
			g_Game.PrecacheGeneric( "sound/" + arrsSounds[i] );

		g_Game.PrecacheGeneric( "sprites/portal/weapons/" + PW_NAME + ".txt" );
		//g_Game.PrecacheGeneric( "sprites/portal/weapons/w_icons1b.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= -1;
		info.iMaxClip			= -1;
		info.iSlot				= PW_SLOT-1;
		info.iPosition			= PW_POSITION-1;
		info.iFlags				= 0;
		info.iWeight			= PW_WEIGHT;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( BaseClass.AddToPlayer(pPlayer) )
		{
			@m_pPlayer = pPlayer;

			NetworkMessage m( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
				m.WriteLong( g_ItemRegistry.GetIdForName(PW_NAME) ); 
			m.End();

			return true;
		}

		return false;
	}

	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model(MODEL_VIEW), self.GetP_Model(MODEL_PLAYER), ANIM_DRAW, PW_ANIMEXT );
			g_EngineFuncs.ClientPrintf( m_pPlayer, print_center, "--> COMPILE SUCCESSFUL <--\n" );
			self.m_flNextPrimaryAttack = g_Engine.time + PW_TIME_DRAW;
			self.m_flTimeWeaponIdle = g_Engine.time + (PW_TIME_DRAW + Math.RandomFloat(0.5, (PW_TIME_DRAW*2)));

			return bResult;
		}
	}

	void WeaponIdle()
	{
		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		if( m_bActive )
		{
			//Shake when holding an item
			self.SendWeaponAnim( ANIM_IDLE_CARRYING );
			self.m_flTimeWeaponIdle = g_Engine.time + PW_TIME_IDLE;
		}
		else
		{
			//Otherwise idle simply
			self.SendWeaponAnim( ANIM_IDLE );
			self.m_flTimeWeaponIdle = g_Engine.time + PW_TIME_IDLE + Math.RandomFloat(0, (PW_TIME_IDLE*2));
		}
	}

	void Pickup()
	{
		self.SendWeaponAnim( ANIM_IDLE_TO_CARRYING );
		self.m_flTimeWeaponIdle = g_Engine.time + PW_TIME_IDLE;
		m_bActive = true;
	}

	void Drop()
	{
		self.SendWeaponAnim( ANIM_CARRYING_TO_IDLE );
		self.m_flTimeWeaponIdle = g_Engine.time + PW_TIME_IDLE;
		m_bActive = false;
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_portalgun::CWeaponPortalgun", PW_NAME );
	g_ItemRegistry.RegisterWeapon( PW_NAME, "portal/weapons" );

	g_Game.PrecacheOther( PW_NAME );
}

} //namespace weapon_portalgun END