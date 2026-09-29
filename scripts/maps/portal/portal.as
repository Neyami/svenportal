#include "debugoverlay_shared"
#include "firebulletsinfo"
#include "shot_manipulator"
#include "weapon_proficiency"

#include "weapons/weapon_portalgun"

#include "npcs/npc_portal_turret_floor"

void MapInit()
{
	weapon_portalgun::Register();

	npc_portal_turret_floor::Register();
}

namespace portal
{

} //namespace portal END