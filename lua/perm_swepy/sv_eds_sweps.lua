local provider = {}
local SWEPs = {}			// groupid: sweps
local combinedSWEPs = {}	// groupid + all before: sweps
local saveLocation = "perm_sweps_eds.txt"
local loadedSWEPs = false

provider.id = "eds" // ply, grp, eds

local function table_AddWithoutDuplicates(target, source)
	for i, val in pairs(source) do
		if not table.HasValue(target, val) then
			table.insert(target, val)
		end
	end
end

--[[ Combining like this doesn't work with the design
local function combineSWEPsThroughRanks()
	local combined = {}
	local previousSWEPs = {}

	for i=1, 100 do
		istr = tostring(i)
		combined[istr] = {}
		table_AddWithoutDuplicates(combined[istr], previousSWEPs)

		if SWEPs[istr] then
			table_AddWithoutDuplicates(combined[istr], SWEPs[istr])
		end

		table_AddWithoutDuplicates(previousSWEPs, combined[istr])
	end

	return combined
end
]]--

local function loadSWEPs()
	local saved = file.Read(saveLocation, "DATA")
	return saved and util.JSONToTable(saved) or {}
end

provider.convertPlyToFuncArg = function(ply)
	if EDSCFG then
		return tostring(util.GetPData(ply:SteamID(), "EDSCFG.Ranks", 0))
	end
	return "0"
end

provider.onInitalSpawnLoad = function(groupid)
	if not loadedSWEPs then
		loadedSWEPs = true
		SWEPs = loadSWEPs()
		--combinedSWEPs = combineSWEPsThroughRanks()
	end
end

provider.plyLeft = function(groupid)
	
end

provider.onLoadoutSWEPs = function(groupid)
	return SWEPs[groupid] or {}
end

provider.setOnLoadoutSWEPs = function(groupid, sweps)
	if 0 <= tonumber(groupid) and tonumber(groupid) <= 100 then
		SWEPs[groupid] = sweps
		--combinedSWEPs = combineSWEPsThroughRanks()
		file.Write(saveLocation, util.TableToJSON(SWEPs))
		PermSWEPs.MakeEveryoneDirty()
	end
end

PermSWEPs.AddSWEPProvider(provider)