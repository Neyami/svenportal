//---------------------------------------------------------
// Caches off a shot direction and allows you to perform
// various operations on it without having to recalculate
// vecRight and vecUp each time. 
//---------------------------------------------------------
class CShotManipulator
{
	CShotManipulator( const Vector &in vecForward )
	{
		SetShootDir( vecForward );
	};

	void SetShootDir( const Vector &in vecForward )
	{
		m_vecShotDirection = vecForward;
		VectorVectors( m_vecShotDirection, m_vecRight, m_vecUp );
	}

	const Vector GetShotDirection()	{ return m_vecShotDirection; } //&
	const Vector GetResult()			{ return m_vecResult; } //&
	const Vector GetRightVector()		{ return m_vecRight; } //&
	const Vector GetUpVector()			{ return m_vecUp;} //&

	private Vector m_vecShotDirection;
	private Vector m_vecRight;
	private Vector m_vecUp;
	private Vector m_vecResult;

	void VectorVectors( const Vector &in forward, Vector &out right, Vector &out up )
	{
		//Assert( s_bMathlibInitialized );
		Vector tmp;

		if( forward[0] == 0 and forward[1] == 0 )
		{
			// pitch 90 degrees up/down from identity
			right[0] = 0;	
			right[1] = -1; 
			right[2] = 0;
			up[0] = -forward[2]; 
			up[1] = 0; 
			up[2] = 0;
		}
		else
		{
			tmp[0] = 0; tmp[1] = 0; tmp[2] = 1.0;
			right = CrossProduct( forward, tmp ); //CrossProduct( forward, tmp, right );
			right = right.Normalize(); //VectorNormalize
			up = CrossProduct( right, forward ); //CrossProduct( right, forward, up );
			up = up.Normalize(); //VectorNormalize
		}
	}

	//---------------------------------------------------------
	// Take a vector (direction) and another vector (spread) 
	// and modify the direction to point somewhere within the 
	// spread. This used to live inside FireBullets.
	//---------------------------------------------------------
	const Vector ApplySpread( const Vector &in vecSpread, float bias = 1.0/*, IUniformRandomStream* pCustomRandom /*= NULL*/ ) //inline	//&
	{
		// get circular gaussian spread
		float x, y, z;

		if( bias > 1.0 )
			bias = 1.0;
		else if( bias < 0.0 )
			bias = 0.0;

		float shotBiasMin = -1.0; //ai_shot_bias_min.GetFloat();
		float shotBiasMax = 1.0; //ai_shot_bias_max.GetFloat();

		// 1.0 gaussian, 0.0 is flat, -1.0 is inverse gaussian
		float shotBias = ( ( shotBiasMax - shotBiasMin ) * bias ) + shotBiasMin;

		float flatness = ( abs(shotBias) * 0.5 ); //fabsf

		do
		{
			//IUniformRandomStream* pRandom = pCustomRandom ? pCustomRandom : random;
			x = Math.RandomFloat(-1,1) * flatness + Math.RandomFloat(-1,1) * (1 - flatness);
			y = Math.RandomFloat(-1,1) * flatness + Math.RandomFloat(-1,1) * (1 - flatness);
			if( shotBias < 0 )
			{
				x = ( x >= 0 ) ? 1.0 - x : -1.0 - x;
				y = ( y >= 0 ) ? 1.0 - y : -1.0 - y;
			}
			z = x*x+y*y;
		} while( z > 1 );

		m_vecResult = m_vecShotDirection + x * vecSpread.x * m_vecRight + y * vecSpread.y * m_vecUp;

		return m_vecResult;
	}
}