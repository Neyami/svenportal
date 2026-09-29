class WeaponProficiencyInfo_t
{
	float	spreadscale;
	float	bias;

	WeaponProficiencyInfo_t( float ss, float b )
	{
		spreadscale = ss;
		bias = b;
	}
}

const array<WeaponProficiencyInfo_t@> g_BaseWeaponProficiencyTable = 
{
	WeaponProficiencyInfo_t( 2.50, 1.0	),
	WeaponProficiencyInfo_t( 2.00, 1.0	),
	WeaponProficiencyInfo_t( 1.50, 1.0	),
	WeaponProficiencyInfo_t( 1.25, 1.0 ),
	WeaponProficiencyInfo_t( 1.00, 1.0 )
};

const array<WeaponProficiencyInfo_t@>@ GetDefaultProficiencyValues() //*CBaseHLCombatWeapon::
{
	// Weapon proficiency table. Keep this in sync with WeaponProficiency_t enum in the header!!
	return @g_BaseWeaponProficiencyTable;
}