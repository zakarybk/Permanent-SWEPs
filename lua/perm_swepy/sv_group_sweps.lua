local provider = {}
local SWEPs = {}			// userGroup: sweps
local saveLocation = "perm_sweps_groups.txt"
local loadedSWEPs = false

provider.id = "grp" // ply, grp, eds

local function loadSWEPs()
	local saved = file.Read(saveLocation, "DATA")
	return saved and util.JSONToTable(saved) or {}
end

provider.convertPlyToFuncArg = function(ply)
	return ply:GetUserGroup()
end

provider.onInitalSpawnLoad = function(userGroup)
	if not loadedSWEPs then
		loadedSWEPs = true
		SWEPs = loadSWEPs()
		PrintTable(SWEPs)
	end
end

provider.plyLeft = function(userGroup)
	
end

provider.onLoadoutSWEPs = function(userGroup)
	return SWEPs[userGroup] or {}
end

provider.setOnLoadoutSWEPs = function(userGroup, sweps)
	SWEPs[userGroup] = sweps
	file.Write(saveLocation, util.TableToJSON(SWEPs))
	PermSWEPsCFG.MakeEveryoneDirty()
end

PermSWEPsCFG.AddSWEPProvider(provider)