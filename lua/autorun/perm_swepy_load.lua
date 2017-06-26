if SERVER then
	AddCSLuaFile("perm_swepy/cl_perm_sweps.lua")
	include("perm_swepy/sv_perm_sweps.lua")
else
	include("perm_swepy/cl_perm_sweps.lua")
end