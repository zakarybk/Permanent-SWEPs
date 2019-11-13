/*
	Perma SWEP system by Hackcraft STEAM_0:1:50714411

	PermSweps = {
		ply = {swep1, swep2},
		Group = {
			superadmin = {swep1, swep2}
		}
		EDS = {
			5 = {swep1, swep2}
		}
	}
*/

// Players
util.AddNetworkString("PermSweps_GetInventoryFromServer")
util.AddNetworkString("PermSweps_SendInventoryToClient")
util.AddNetworkString("PermSweps_SendInventoryToServer")

// Groups
util.AddNetworkString("PermSweps_GetGroupInventoryFromServer")
util.AddNetworkString("PermSweps_SendGroupInventoryToClient")
util.AddNetworkString("PermSweps_SendGroupInventoryToServer")

// EDS
util.AddNetworkString("PermSweps_GetEDSInventoryFromServer")
util.AddNetworkString("PermSweps_SendEDSInventoryToClient")
util.AddNetworkString("PermSweps_SendEDSInventoryToServer")

CreateConVar( "perm_sweps_forceswepcheck", 1, {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "If SWEPs aren't being added then set this to 0" )
local forceswepcheck = GetConVar("perm_sweps_forceswepcheck"):GetInt()

cvars.AddChangeCallback( "perm_sweps_forceswepcheck", function(convar, oldValue, newValue)
	forceswepcheck = tonumber(newValue)
end, "perm_sweps" )

local PermSweps = PermSweps or {}
local OtherSweps = PermSWEPsCFG.HiddenSWEPs or {}
local swepsList = false
local EDSSWEPcache = {}

local function getweaponsList()
	if !swepsList then
		swepsList = table.Add(weapons.GetList(), OtherSweps)
	end
	return swepsList
end

// table add
local function differentTableAdd(t1, t2)
	for k, v in ipairs(t2) do
		if !table.HasValue(t1, v) then
			table.insert(t1, v)
		end
	end
	return t1
end

// Rebuild EDS weapon cache
local function ReBuildEDSSWEPcache()
	local new = {}
	local builder = {}
	for i=1, 100 do
		builder = differentTableAdd(builder, PermSweps.EDS[i] or {})
		new[i] = builder
	end
	EDSSWEPcache = new
//	PrintTable(EDSSWEPcache)
end

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

// Load group sweps
local function LoadGroupSWEPS()
	PermSweps.Group = {}
	local saved = file.Read("perm_sweps_groups.txt", "DATA")
	if saved then
		PermSweps.Group = util.JSONToTable(saved) or {}
	end
end
LoadGroupSWEPS()

// Save groups sweps
local function SaveGroupSWEPS(s)
	file.Write("perm_sweps_groups.txt", util.TableToJSON(s))
end

// Load eds sweps
local function LoadEDSSWEPS()
	PermSweps.EDS = {}
	local saved = file.Read("perm_sweps_eds.txt", "DATA")
	if saved then
		PermSweps.EDS = util.JSONToTable(saved) or {}
	end
end
LoadEDSSWEPS()

// Save eds sweps
local function SaveEDSSWEPS(s)
	file.Write("perm_sweps_eds.txt", util.TableToJSON(s))
	ReBuildEDSSWEPcache()
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
	if PermSweps.Group[ply:GetUserGroup()] then
		local sweps = PermSweps.Group[ply:GetUserGroup()]
		for k, v in ipairs(sweps) do
			ply:Give(v)
		end
	end
	if EDSCFG and EDSCFG.Players[ply] != nil then
		local sweps = EDSSWEPcache[EDSCFG.RankPower[EDSCFG.Players[ply]]] or {}
		for k, v in ipairs(sweps) do
			ply:Give(v)
		end
	end
end)

// Dropping
hook.Add("canDropWeapon", "StopPermSWEPDrop", function(ply, swep)
	if PermSweps[ply] and IsValid(swep) then
		if table.HasValue(PermSweps[ply], swep:GetClass()) then
			return false
		end
	end
end)

// See if weapon exists
local function getValidSWEPS(weps)
	local weps2 = {}
	local wepsT = getweaponsList()
	for _, v in ipairs(wepsT) do
		for _, wep in ipairs(weps) do
			if v.ClassName == wep then
				table.insert(weps2, v.ClassName)
			end
		end
	end
	return weps2
end

// Update inventory
net.Receive("PermSweps_SendInventoryToServer", function(len, ply)
	if !ply:IsSuperAdmin() then return end
	
	local target = net.ReadString()
	local sweps = net.ReadString()

	// Validate all sweps
	local weps = util.TableToJSON( forceswepcheck and getValidSWEPS(util.JSONToTable(sweps)) or util.JSONToTable(sweps) )

//	print("PermSweps_SendInventoryToServer")
//	print(target)
//	print(sweps)

	if string.Left(target, 5) == "STEAM" then
		util.SetPData(target, "PermSweps", weps)
		local real = player.GetBySteamID(target)
		if real then
			PermSweps[real] = util.JSONToTable(weps)
		end
	end
end)

// Send Group inventory to server
net.Receive("PermSweps_SendGroupInventoryToServer", function(len, ply)
	if !ply:IsSuperAdmin() then return end
	
	local target = net.ReadString()
	local sweps = net.ReadString()

	// Validate all sweps
	local weps = util.TableToJSON( forceswepcheck and getValidSWEPS(util.JSONToTable(sweps)) or util.JSONToTable(sweps) )

	PermSweps.Group[target] = util.JSONToTable(weps)
	SaveGroupSWEPS(PermSweps.Group)
end)

// Send EDS inventory to server
net.Receive("PermSweps_SendEDSInventoryToServer", function(len, ply)
	if !ply:IsSuperAdmin() then return end
	
	local target = net.ReadInt(16)
	local sweps = net.ReadString()

	// Validate all sweps
	local weps = util.TableToJSON( forceswepcheck and getValidSWEPS(util.JSONToTable(sweps)) or util.JSONToTable(sweps) )

//	print(target, weps)
	PermSweps.EDS[target] = util.JSONToTable(weps)
	SaveEDSSWEPS(PermSweps.EDS)
//	print("---")
//	print(weps)
//	print("---")
end)

// Table add
local function tableAdd(t1, t2)
	local new = {}
	for k, v in ipairs(t1) do
		if !table.HasValue(new, v) then
			table.insert(new, v)
		end
	end
	for k, v in ipairs(t2) do
		if !table.HasValue(new, v) then
			table.insert(new, v)
		end
	end
	return new
end

// Add to
concommand.Add("perm_sweps_add", function(ply, cmd, args, argStr) // use "" around steamid
	if !IsValid(ply) or ply:IsSuperAdmin() then
		if args[1] != nil and args[2] != nil then
			local target = args[1]
			if string.Left(target, 5) == "STEAM" then
				table.remove(args, 1)
				local weps = forceswepcheck and getValidSWEPS(args) or args
				local oldweps = util.GetPData(target, "PermSweps", false)
				if oldweps then
//					print(oldweps)
					weps = tableAdd(weps, util.JSONToTable(oldweps))
				end
				if #weps >= 1 then
					util.SetPData(target, "PermSweps", util.TableToJSON(weps))
					local real = player.GetBySteamID(target)
					if real then
						PermSweps[real] = weps
					end
				end
			end
		end
	end
end)

// Remove from
concommand.Add("perm_sweps_remove", function(ply, cmd, args, argStr)
	if !IsValid(ply) or ply:IsSuperAdmin() then
		if args[1] != nil and args[2] != nil then
			local target = args[1]
			if string.Left(target, 5) == "STEAM" then
				table.remove(args, 1)
				local weps = forceswepcheck and getValidSWEPS(args) or args
				local oldweps = util.GetPData(target, "PermSweps", false)
				if !oldweps then return end
				if #weps >= 1 then
					local newweps = {}
					for k, v in ipairs(util.JSONToTable(oldweps)) do
						if !table.HasValue(weps, v) then
							table.insert(newweps, v)
						end
					end
					util.SetPData(target, "PermSweps", util.TableToJSON(newweps))
					local real = player.GetBySteamID(target)
					if real then
						PermSweps[real] = newweps
					end
				end
			end
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

// Get Group inventory
net.Receive("PermSweps_GetGroupInventoryFromServer", function(len, ply)
	if !ply:IsSuperAdmin() then return end

	local target = net.ReadString()

	net.Start("PermSweps_SendGroupInventoryToClient")
	if PermSweps.Group[target] then
		net.WriteString(util.TableToJSON(PermSweps.Group[target]))
	else
		net.WriteString(util.TableToJSON({}))
	end
	net.Send(ply)
end)

// Get EDS inventory
net.Receive("PermSweps_GetEDSInventoryFromServer", function(len, ply)
	if !ply:IsSuperAdmin() then return end

	local target = net.ReadInt(16)

	net.Start("PermSweps_SendEDSInventoryToClient")
	if PermSweps.EDS[target] then
		net.WriteString(util.TableToJSON(PermSweps.EDS[target]))
	else
		net.WriteString(util.TableToJSON({}))
	end
	net.Send(ply)
end)
