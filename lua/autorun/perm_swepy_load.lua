if SERVER then
	AddCSLuaFile("perm_swepy/shared_perm_sweps.lua")
	AddCSLuaFile("perm_swepy/cl_perm_sweps.lua")
	include("perm_swepy/shared_perm_sweps.lua")
	include("perm_swepy/sv_perm_sweps.lua")
	
	include("perm_swepy/sv_player_sweps.lua")
	include("perm_swepy/sv_group_sweps.lua")
	include("perm_swepy/sv_eds_sweps.lua")
else
	include("perm_swepy/shared_perm_sweps.lua")
	include("perm_swepy/cl_perm_sweps.lua")
end
