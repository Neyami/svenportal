namespace NDebugOverlay
{

// Purpose: Draw a colored 3D cross of the given hull size at the given position
void Cross3D( const Vector &in position, const Vector &in mins, const Vector &in maxs, int r, int g, int b, bool noDepthTest, float fDuration )
{
	Vector start = mins + position;
	Vector end   = maxs + position;
	Line( start, end, r, g, b, noDepthTest, fDuration );

	start.x += ( maxs.x - mins.x );
	end.x	-= ( maxs.x - mins.x );
	Line( start, end, r, g, b, noDepthTest, fDuration );

	start.y += ( maxs.y - mins.y );
	end.y	-= ( maxs.y - mins.y );
	Line( start, end, r, g, b, noDepthTest, fDuration );

	start.x -= ( maxs.x - mins.x );
	end.x	+= ( maxs.x - mins.x );
	Line( start, end, r, g, b, noDepthTest, fDuration );
}

const int MAX_OVERLAY_DIST_SQR = 90000000;

// Purpose: Draws a line from one position to another
void Line( const Vector &in origin, const Vector &in target, int r, int g, int b, bool noDepthTest, float duration )
{
	// --------------------------------------------------------------
	// Clip the line before sending so we 
	// don't overflow the client message buffer
	// --------------------------------------------------------------
	CBasePlayer@ player = GetLocalPlayer();

	if( player is null )
		return;

	// Clip line that is far away
	float flOriginLengthSqr = ( player.GetOrigin() - origin ).Length() * ( player.GetOrigin() - origin ).Length();
	float flTargetLengthSqr = ( player.GetOrigin() - target ).Length() * ( player.GetOrigin() - target ).Length();

	//if( flOriginLengthSqr > MAX_OVERLAY_DIST_SQR and flTargetLengthSqr > MAX_OVERLAY_DIST_SQR )
		//return;

	// Clip line that is behind the client 
	Vector clientForward;
	clientForward = player.pev.v_angle; //player->EyeVectors( &clientForward );

	Vector toOrigin = origin - player.GetOrigin();
	Vector toTarget = target - player.GetOrigin();
 	float dotOrigin = DotProduct( clientForward, toOrigin );
 	float dotTarget = DotProduct( clientForward, toTarget );

	//if( dotOrigin < 0 and dotTarget < 0 )
		//return;

	NetworkMessage m1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
		m1.WriteByte( TE_BEAMPOINTS );
		m1.WriteCoord( origin.x );
		m1.WriteCoord( origin.y );
		m1.WriteCoord( origin.z );
		m1.WriteCoord( target.x );
		m1.WriteCoord( target.y );
		m1.WriteCoord( target.z );
		m1.WriteShort( g_EngineFuncs.ModelIndex("sprites/laserbeam.spr") );
		m1.WriteByte( 0 ); //starting frame
		m1.WriteByte( 0 ); //frame rate in 0.1's
		m1.WriteByte( int(duration) ); //life in 0.1's
		m1.WriteByte( 2 ); //line width in 0.1's
		m1.WriteByte( 0 ); //noise amplitude in 0.1's
		m1.WriteByte( r ); //rgb
		m1.WriteByte( g );
		m1.WriteByte( b );
		m1.WriteByte( 255 ); //brightness
		m1.WriteByte( 0 ); //scroll speed in 0.1's
	m1.End();

	/*if ( debugoverlay )
	{
		debugoverlay->AddLineOverlay( origin, target, r, g, b, noDepthTest, duration );
	}*/
}

CBasePlayer@ GetLocalPlayer()
{
	return g_PlayerFuncs.FindPlayerByIndex( 1 );
}

} //end of namespace NDebugOverlay