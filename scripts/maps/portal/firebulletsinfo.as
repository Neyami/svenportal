class FireBulletsInfo_t //struct
{
	FireBulletsInfo_t()
	{
		m_iShots = 1;
		m_vecSpread = g_vecZero; //m_vecSpread.Init( 0, 0, 0 );
		m_flDistance = 8192;
		m_iTracerFreq = 4;
		m_flDamage = 0;
		m_iPlayerDamage = 0;
		m_pAttacker = null;
		m_nFlags = 0;
		m_pAdditionalIgnoreEnt = null;
		m_flDamageForceScale = 1.0;

/*#ifdef _DEBUG
		m_iAmmoType = -1;
		m_vecSrc.Init( VEC_T_NAN, VEC_T_NAN, VEC_T_NAN );
		m_vecDirShooting.Init( VEC_T_NAN, VEC_T_NAN, VEC_T_NAN );
#endif*/
		m_bPrimaryAttack = true;
		m_bUseServerRandomSeed = false;
	}

	FireBulletsInfo_t( int nShots, const Vector &in vecSrc, const Vector &in vecDir, const Vector &in vecSpread, float flDistance, int nAmmoType, bool bPrimaryAttack = true )
	{
		m_iShots = nShots;
		m_vecSrc = vecSrc;
		m_vecDirShooting = vecDir;
		m_vecSpread = vecSpread;
		m_flDistance = flDistance;
		m_iAmmoType = nAmmoType;
		m_iTracerFreq = 4;
		m_flDamage = 0;
		m_iPlayerDamage = 0;
		m_pAttacker = null;
		m_nFlags = 0;
		m_pAdditionalIgnoreEnt = null;
		m_flDamageForceScale = 1.0;
		m_bPrimaryAttack = bPrimaryAttack;
		m_bUseServerRandomSeed = false;
	}

	int m_iShots;
	Vector m_vecSrc;
	Vector m_vecDirShooting;
	Vector m_vecSpread;
	float m_flDistance;
	int m_iAmmoType;
	int m_iTracerFreq;
	float m_flDamage;
	int m_iPlayerDamage;	// Damage to be used instead of m_flDamage if we hit a player
	int m_nFlags;			// See FireBulletsFlags_t
	float m_flDamageForceScale;
	EHandle m_pAttacker; //CBaseEntity
	EHandle m_pAdditionalIgnoreEnt; //CBaseEntity
	bool m_bPrimaryAttack;
	bool m_bUseServerRandomSeed;
};