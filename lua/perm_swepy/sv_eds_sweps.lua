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

local function combineSWEPsThroughRanks()
	local combined = {}
	local previousSWEPs = {}

	for i=1, 100 do
		table_AddWithoutDuplicates(combined, previousSWEPs)

		if SWEPs[i] then
			table_AddWithoutDuplicates(combined, previousSWEPs)
		end
	end

	return combined
end

local function loadSWEPs()
	local saved = file.Read(saveLocation, "DATA")
	return saved and util.TableToJSON(saved) or {}
end

provider.convertPlyToFuncArg = function(ply)
	if EDSCFG then
		return util.GetPData(steamid, "EDSCFG.Ranks", 0)
	end
	return 0
end

provider.onInitalSpawnLoad = function(groupid)
	if not loadedSWEPs then
		loadedSWEPs = true
		SWEPs = loadSWEPs()
		combinedSWEPs = combineSWEPsThroughRanks()
	end
end

provider.plyLeft = function(groupid)
	
end

provider.onLoadoutSWEPs = function(groupid)
	return combinedSWEPs[groupid] or {}
end

provider.setOnLoadoutSWEPs = function(groupid, sweps)
	SWEPs[groupid] = sweps
	file.Write(saveLocation, util.TableToJSON(SWEPs))
	PermSWEPsCFG.MakeEveryoneDirty()
end

table.Add(PermSWEPsCFG.SWEPProviders, provider)