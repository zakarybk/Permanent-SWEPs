PermSWEPsCFG = PermSWEPsCFG or {}

PermSWEPsCFG.HiddenSWEPs = { -- Ones which don't appear in weapons.GetList - If some SWEPs aren't listed and you don't want to add to this then run "perm_sweps_wepCheckVar 0" in console
	-- HL2
	{ClassName = "weapon_357", PrintName = "357"},
	{ClassName = "weapon_ar2", PrintName = "AR2"},
	{ClassName = "weapon_bugbait", PrintName = "BugBait"},
	{ClassName = "weapon_crossbow", PrintName = "Crossbow"},
	{ClassName = "weapon_crowbar", PrintName = "Crowbar"},
	{ClassName = "weapon_frag", PrintName = "Frag Grenade"},
	{ClassName = "weapon_physcannon", PrintName = "Gravity Gun"},
	{ClassName = "weapon_physgun", PrintName = "Physics Gun"},
	{ClassName = "weapon_pistol", PrintName = "Pistol"},
	{ClassName = "weapon_rpg", PrintName = "RPG Launcher"},
	{ClassName = "weapon_shotgun", PrintName = "Shotgun"},
	{ClassName = "weapon_slam", PrintName = "SLAM"},
	{ClassName = "weapon_smg1", PrintName = "SMG"},
	{ClassName = "weapon_stunstick", PrintName = "Stunstick"}
}

PermSWEPsCFG.CanEdit = function(ply)
	return ply:IsSuperAdmin()
end

PermSWEPsCFG.SWEPProviders = {}

-- Adding/removing weapons from console
--[[
	I don't know the limit but more than one swep can be added or removed at once using the sweps class separated by a space
	Make sure the STEAMID is in quotes or stuff won't work!

	perm_sweps_add "STEAMID" swep_class1 swep_class2 swep_class3 etc etc
	perm_sweps_remove "STEAMID" swep_class1 swep_class2 swep_class3 etc etc

	Examples:
		perm_sweps_add "STEAM_0:1:50714411" weapon_357
		perm_sweps_add "STEAM_0:1:50714411" weapon_ar2 weapon_bugbait weapon_crossbow

		perm_sweps_remove "STEAM_0:1:50714411" weapon_357
		perm_sweps_remove "STEAM_0:1:50714411" weapon_ar2 weapon_bugbait weapon_crossbow
]]--
