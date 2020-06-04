local provider = {}
local plySWEPs = {}

provider.id = "ply" // ply, grp, eds

local function loadSWEPs(steamid)
	return util.GetPData(steamid, "PermSweps", false)
end

provider.convertPlyToFuncArg = function(ply)
	return ply:SteamID()
end

provider.onInitalSpawnLoad = function(steamid)
	plySWEPs[steamid] = loadSWEPs(steamid)
end

provider.plyLeft = function(steamid)
	plySWEPs[steamid] = nil
end

provider.onLoadoutSWEPs = function(steamid)
	return plySWEPs[steamid] and plySWEPs[steamid] or {}
end

provider.setOnLoadoutSWEPs = function(steamid, sweps)
	util.SetPData(steamid, "PermSweps", util.TableToJSON(sweps))
	PermSWEPsCFG.MakeSteamIDDirty(steamid)
end

table.Add(PermSWEPsCFG.SWEPProviders, provider)