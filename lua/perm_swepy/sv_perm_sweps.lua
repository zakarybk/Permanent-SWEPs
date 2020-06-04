--[[
	Perma SWEP system by Zak STEAM_0:1:50714411

	add in new cache
]]--

util.AddNetworkString("PermSweps_GetInventoryFromServer")
util.AddNetworkString("PermSweps_SendInventoryToClient")
util.AddNetworkString("PermSweps_SendInventoryToServer")

-- Dirty cache
local setDirty = {}		// ply: true/false (is dirty?)
local dirtySWEPs = {}	// ply: sweps{} or false/nil

local OtherSweps = PermSWEPsCFG.HiddenSWEPs or {}
local swepsList = false

PermSWEPsCFG.MakeEveryoneDirty = function()
	for k, ply in pairs(player.GetAll()) do
		setDirty[ply] = true
	end
end

PermSWEPsCFG.MakeSteamIDDirty = function(steamid)
	local ply = player.GetBySteamID(steamid)
	if ply then
		setDirty[ply] = true
	end
end

-- Force SWEP check
CreateConVar("perm_sweps_forceswepcheck",
	1,
	{FCVAR_ARCHIVE, FCVAR_NOTIFY},
	"If SWEPs aren't being added then set this to 0"
)
local checkSWEPValidity = GetConVar("perm_sweps_forceswepcheck"):GetInt()
cvars.AddChangeCallback("perm_sweps_forceswepcheck", function(convar, oldValue, newValue)
	checkSWEPValidity = tonumber(newValue) 
end, "perm_sweps")


local function getValidSWEPs()
	if !swepsList then
		swepsList = table.Add(weapons.GetList(), OtherSweps)
	end
	return swepsList
end

-- table add
local function differentTableAdd(t1, t2)
	for k, v in ipairs(t2) do
		if !table.HasValue(t1, v) then
			table.insert(t1, v)
		end
	end
	return t1
end

local function providerFromID(id)
	local provider = false

	for i, prov in pairs(PermSWEPsCFG.SWEPProviders) do
		if prov.id == id then
			provider = prov
		end
		break
	end

	return provider
end

--[[
	Provider (SWEP providers) hooking 
]]--

local function table_AddWithoutDuplicates(target, source)
	for i, val in pairs(source) do
		if not table.HasValue(target, val) then
			table.insert(target, val)
		end
	end
end

local function buildLoadout(ply)
	local sweps = {}
	for i, provider in pairs(PermSWEPsCFG.SWEPProviders) do
		local special = provider.convertPlyToFuncArg(ply)
		table_AddWithoutDuplicates(sweps, provider.onLoadoutSWEPs(special))
	end
	return sweps
end

-- Player connect
hook.Add("PlayerInitialSpawn", "PermSwepLoad", function(ply)
	setDirty[ply] = true

	for i, provider in pairs(PermSWEPsCFG.SWEPProviders) do
		local special = provider.convertPlyToFuncArg(ply)
		provider.onInitalSpawnLoad(special)
	end
end)

-- Player disconnect
hook.Add("PlayerDisconnected", "PermSwepUnLoad", function(ply)
	dirtySWEPs[ply] = nil
	setDirty[ply] = nil

	for i, provider in pairs(PermSWEPsCFG.SWEPProviders) do
		local special = provider.convertPlyToFuncArg(ply)
		provider.plyLeft(special)
	end
end)

-- Loadout
hook.Add("PlayerLoadout", "GivePermSweps", function(ply)
	-- Update cache
	if setDirty[ply] then
		setDirty[ply] = false
		local sweps = buildLoadout(ply)
		if #sweps > 0 then
			dirtySWEPs[ply] = sweps
		else
			dirtySWEPs[ply] = false
		end
	end
	-- Give SWEPs
	if dirtySWEPs[ply] then
		for i, swep in ipairs(dirtySWEPs[ply]) do
			ply:Give(swep)
		end
	end
end)

-- Dropping
hook.Add("canDropWeapon", "StopPermSWEPDrop", function(ply, swep)
	if dirtySWEPs[ply] and IsValid(swep) then
		if table.HasValue(dirtySWEPs[ply], swep:GetClass()) then
			return false
		end
	end
end)

--[[
	other 
]]--

-- Chat command
hook.Add( "PlayerSay", "PermSwepMenu", function( ply, text, public )
	if string.lower( text ) == "!pss" then
		ply:ConCommand("perm_swep_menu")
		return ""
	end
end )


-- See if weapon exists
local function getValidSWEPS(weps)
	local weps2 = {}
	local wepsT = getValidSWEPs()
	for _, v in ipairs(wepsT) do
		for _, wep in ipairs(weps) do
			if v.ClassName == wep then
				table.insert(weps2, v.ClassName)
			end
		end
	end
	return weps2
end

-- Update inventory
net.Receive("PermSweps_SendInventoryToServer", function(len, ply)
	if !PermSWEPsCFG.CanEdit(ply) then return end
	
	local provider = net.ReadString()
	local target = net.ReadString()
	local sweps = net.ReadString()

	sweps = util.JSONToTable(sweps)

	-- Validate
	local validSWEPs = checkSWEPValidity and getValidSWEPS(sweps) or sweps
	local provider = providerFromID(provider)

	-- Update -- todo error func
	if provider then
		provider.setOnLoadoutSWEPs(target, sweps)
	end
end)

-- Add to
concommand.Add("perm_sweps_add", function(ply, cmd, args, argStr) -- use "" around steamid
	if !IsValid(ply) or PermSWEPsCFG.CanEdit(ply) then
		if args[1] != nil and args[2] != nil then
			local target = args[1]
			if string.Left(target, 5) == "STEAM" then
				table.remove(args, 1)
				local weps = checkSWEPValidity and getValidSWEPS(args) or args

				local provider = providerFromID("ply")
				if provider then
					local oldweps = provider.onLoadoutSWEPs(target)

					table_AddWithoutDuplicates(weps, oldweps)
					provider.setOnLoadoutSWEPs(target, weps)
				end
			end
		end
	end
end)

-- Remove from
concommand.Add("perm_sweps_remove", function(ply, cmd, args, argStr)
	if !IsValid(ply) or PermSWEPsCFG.CanEdit(ply) then
		if args[1] != nil and args[2] != nil then
			local target = args[1]
			if string.Left(target, 5) == "STEAM" then
				table.remove(args, 1)
				local weps = checkSWEPValidity and getValidSWEPS(args) or args

				local provider = providerFromID("ply")
				if provider then
					local oldweps = provider.onLoadoutSWEPs(target)

					local newweps = {}
					for k, v in ipairs(util.JSONToTable(oldweps)) do
						if !table.HasValue(weps, v) then
							table.insert(newweps, v)
						end
					end
					
					provider.setOnLoadoutSWEPs(target, newweps)
				end
			end
		end
	end
end)

-- Get inventory
net.Receive("PermSweps_GetInventoryFromServer", function(len, ply)
	if !PermSWEPsCFG.CanEdit(ply) then return end

	local provider = net.ReadString()
	local target = net.ReadString()

	net.Start("PermSweps_SendInventoryToClient")
		net.WriteString(provider)
		net.WriteString(target)
		net.WriteString(provider.onLoadoutSWEPs(target))
	net.Send(ply)
end)

--[[
	Autorefresh
]]--
for i, ply in pairs(player.GetAll()) do
	if IsValid(ply) then
		setDirty[ply] = true
	end
end