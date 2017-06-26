/*
	Perma SWEP system by Hackcraft STEAM_0:1:50714411
*/

util.AddNetworkString("PermSweps_GetInventoryFromServer")
util.AddNetworkString("PermSweps_SendInventoryToClient")
util.AddNetworkString("PermSweps_SendInventoryToServer")

local PermSweps = PermSweps or {}

// Load sweps
local function LoadPermSwep(ply)
	local sweps = ply:GetPData("PermSweps", false)
	if sweps then
		PermSweps[ply] = util.JSONToTable(sweps)
	end
end
// Auto refresh
for k, v in ipairs(player.GetHumans()) do
	LoadPermSwep(v)
end

// Player connect
hook.Add("PlayerInitialSpawn", "PermSwepLoad", function(ply)
	LoadPermSwep(ply)
end)

// Player disconnect
hook.Add("PlayerDisconnected", "PermSwepUnLoad", function(ply)
	PermSweps[ply] = nil
end)

// Chat command
hook.Add( "PlayerSay", "PermSwepMenu", function( ply, text, public )
	if string.lower( text ) == "!pss" then
		ply:ConCommand("perm_swep_menu")
		return ""
	end
end )

// Loadout
hook.Add("PlayerLoadout", "GivePermSweps", function(ply)
	if PermSweps[ply] then
		for k, v in ipairs(PermSweps[ply]) do
			ply:Give(v)
		end
	end
end)

// Dropping
hook.Add("canDropWeapon", "StopPermSWEPDrop", function(ply, swep)
	if PermSweps[ply] then
		if table.HasValue(PermSweps[ply], swep:GetClass()) then
			return false
		end
	end
end)

// Update inventory
net.Receive("PermSweps_SendInventoryToServer", function(len, ply)
	if !ply:IsSuperAdmin() then return end
	
	local target = net.ReadString()
	local sweps = net.ReadString()

//	print("PermSweps_SendInventoryToServer")
//	print(target)
//	print(sweps)

	if string.Left(target, 5) == "STEAM" then
		util.SetPData(target, "PermSweps", sweps)
		local real = player.GetBySteamID(target)
		if real then
			PermSweps[real] = util.JSONToTable(sweps)
		end
	end
end)

// Get inventory
net.Receive("PermSweps_GetInventoryFromServer", function(len, ply)
	if !ply:IsSuperAdmin() then return end

	local target = net.ReadString()
	local real = player.GetBySteamID(target)

//	print(target)
//	PrintTable(PermSweps)

	net.Start("PermSweps_SendInventoryToClient")
	if real then
		if PermSweps[real] then
			net.WriteString(util.TableToJSON(PermSweps[real]))
		else
			net.WriteString(util.TableToJSON({}))
		end
	else
		local data = util.GetPData(target, "PermSweps", false)
		if data then
			net.WriteString(data)
		else
			net.WriteString(util.TableToJSON({}))
		end
	end
	net.Send(ply)
end)