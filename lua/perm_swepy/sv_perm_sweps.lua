--[[
	Perma SWEP system by Zak STEAM_0:1:50714411
]]--

util.AddNetworkString("PermSweps_GetInventoryFromServer")
util.AddNetworkString("PermSweps_SendInventoryToClient")
util.AddNetworkString("PermSweps_SendInventoryToServer")

util.AddNetworkString("PermSweps_FetchPlayers")

--[[
	Dirty cache
]]--

local setDirty = {}		// ply: true/false (is dirty?)
local dirtySWEPs = {}	// ply: sweps{} or false/nil

local OtherSweps = PermSWEPs.HiddenSWEPs or {}
local swepsList = false

PermSWEPs.MakeEveryoneDirty = function()
	for k, ply in pairs(player.GetAll()) do
		setDirty[ply] = true
	end
end

PermSWEPs.MakeSteamIDDirty = function(steamid)
	local ply = player.GetBySteamID(steamid)
	if ply then
		setDirty[ply] = true
	end
end

--[[
	Set SWEP validity checks
]]--

-- Force SWEP check
CreateConVar("perm_sweps_forceswepcheck",
	1,
	{FCVAR_ARCHIVE, FCVAR_NOTIFY},
	"If SWEPs aren't being added then set this to 0"
)
local checkSWEPValidity = GetConVar("perm_sweps_forceswepcheck"):GetInt()
cvars.AddChangeCallback("perm_sweps_forceswepcheck", function(convar, oldValue, newValue)
	checkSWEPValidity = tonumber(newValue) >= 1
end, "perm_sweps")

-- Ignore dirty cache
CreateConVar("perm_sweps_dirtycache",
	1,
	{FCVAR_ARCHIVE, FCVAR_NOTIFY},
	"When enabled, SWEP lists are cached, so only changes/updates when a hook triggers" ..
	"or settings are changed. Disable if SWEPs aren't being spawned on loadout."
)
local useDirtyCache = GetConVar("perm_sweps_forceswepcheck"):GetInt()
cvars.AddChangeCallback("perm_sweps_dirtycache", function(convar, oldValue, newValue)
	useDirtyCache = tonumber(newValue) >= 1
end, "perm_sweps")

--[[
	Helpers
]]--

local function getweaponsList()
	if !swepsList then
		swepsList = table.Add(weapons.GetList(), OtherSweps)
	end
	return swepsList
end

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

local function providerFromID(id)
	local provider = false

	for i, prov in pairs(PermSWEPs.SWEPProviders) do
		if prov.id == id then
			provider = prov
			break
		end
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
	for i, provider in pairs(PermSWEPs.SWEPProviders) do
		local special = provider.convertPlyToFuncArg(ply)
		local weps = provider.onLoadoutSWEPs(special)
		table_AddWithoutDuplicates(sweps, weps)
	end
	return sweps
end

hook.Add("PlayerInitialSpawn", "PermSwepLoad", function(ply)
	setDirty[ply] = true

	for i, provider in pairs(PermSWEPs.SWEPProviders) do
		local special = provider.convertPlyToFuncArg(ply)
		provider.onInitalSpawnLoad(special)
	end
end)

hook.Add("PlayerDisconnected", "PermSwepUnLoad", function(ply)
	dirtySWEPs[ply] = nil
	setDirty[ply] = nil

	for i, provider in pairs(PermSWEPs.SWEPProviders) do
		local special = provider.convertPlyToFuncArg(ply)
		provider.plyLeft(special)
	end
end)

hook.Add("PlayerLoadout", "GivePermSweps", function(ply)
	-- Update cache
	if not useDirtyCache or setDirty[ply] then
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

hook.Add("CAMI.PlayerUsergroupChanged", "PermSWEPMakeDirty", function(ply, oldGroup, newGroup)
	if IsValid(ply) then
		setDirty[ply] = true
	end
end)

hook.Add("EDSCFG.RankSet", "PermSWEPMakeDirty", function(admin, ply, rank)
	if IsValid(ply) then
		setDirty[ply] = true
	end
end)

--[[
	Other hooks
]]--

-- Dropping
hook.Add("canDropWeapon", "StopPermSWEPDrop", function(ply, swep)
	if dirtySWEPs[ply] and IsValid(swep) then
		if table.HasValue(dirtySWEPs[ply], swep:GetClass()) then
			return false
		end
	end
end)

-- Chat command
hook.Add( "PlayerSay", "PermSwepMenu", function( ply, text, public )
	if string.lower( text ) == "!pss" then
		ply:ConCommand("perm_swep_menu")
		return ""
	end
end )

--[[
	Update SWEPs for players from console
]]--

-- Add to
concommand.Add("perm_sweps_add", function(ply, cmd, args, argStr) -- use "" around steamid
	if !IsValid(ply) or PermSWEPs.CanEdit(ply) then
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
	if !IsValid(ply) or PermSWEPs.CanEdit(ply) then
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

--[[
	Send and receive SWEPs
]]--

-- Update inventory
net.Receive("PermSweps_SendInventoryToServer", function(len, ply)
	if !PermSWEPs.CanEdit(ply) then return end

	local providerID = net.ReadString()
	local provider = providerFromID(providerID)
	local target = net.ReadString()
	local sweps = net.ReadString()

	sweps = util.JSONToTable(sweps)

	-- Validate
	local validSWEPs = checkSWEPValidity and getValidSWEPS(sweps) or sweps

	-- Update -- todo error func
	if provider and istable(sweps) then
		provider.setOnLoadoutSWEPs(target, sweps)
	else
		ply:ChatPrint("[PermSWEP]: '" .. providerID .. "' not found! Did you use auto-refresh?")
	end
end)

-- Get inventory
net.Receive("PermSweps_GetInventoryFromServer", function(len, ply)
	if !PermSWEPs.CanEdit(ply) then return end

	local providerID = net.ReadString()
	local provider = providerFromID(providerID)
	local target = net.ReadString()

	if provider then
		net.Start("PermSweps_SendInventoryToClient")
			net.WriteString(providerID)
			net.WriteString(target)
			net.WriteString(util.TableToJSON(provider.onLoadoutSWEPs(target)))
		net.Send(ply)
	else
		ply:ChatPrint("[PermSWEP]: '" .. providerID .. "' not found! Did you use auto-refresh?")
	end
end)

net.Receive("PermSweps_FetchPlayers", function(len, ply)
	if !PermSWEPs.CanEdit(ply) then return end

	sql.Query("string query")
end)

--[[
	Autorefresh -- the providers may not be added unless all files are reloaded
]]--
for i, ply in pairs(player.GetAll()) do
	if IsValid(ply) then
		setDirty[ply] = true
	end
end