local provider = {}
local plySWEPs = {}
local loaded = false

provider.id = "ply" // ply, grp, eds
local saveTbl = "PermSWEP_" .. provider.id

local function loadSWEPs(steamid)
	local sweps = {}
	local val = sql.QueryValue("SELECT value FROM ".. saveTbl .." WHERE infoid = ".. SQLStr(steamid) .." LIMIT 1")

	if val != nil then
		sweps = util.JSONToTable(val)
	else
		-- Legacy
		local leg = util.GetPData(steamid, "PermSweps", false)

		if leg then
			sweps = util.JSONToTable(leg)
			provider.setOnLoadoutSWEPs(steamid, sweps)
			util.RemovePData(steamid, "PermSweps")
		end
	end

	return sweps
end

local function setupTable()
	if not sql.TableExists(saveTbl) then
		sql.Query("CREATE TABLE IF NOT EXISTS ".. saveTbl .." (infoid TEXT NOT NULL PRIMARY KEY, value TEXT)")
	end
end

provider.convertPlyToFuncArg = function(ply)
	return ply:SteamID()
end

provider.onInitalSpawnLoad = function(steamid)
	if not loaded then
		loaded = true
		setupTable()
	end
	plySWEPs[steamid] = loadSWEPs(steamid)
end

provider.plyLeft = function(steamid)
	plySWEPs[steamid] = nil
end

provider.onLoadoutSWEPs = function(steamid)
	return plySWEPs[steamid] or loadSWEPs(steamid)
end

provider.setOnLoadoutSWEPs = function(steamid, sweps)
	if string.Left(steamid, 5) == "STEAM" then
		plySWEPs[steamid] = sweps
		sql.Query("REPLACE INTO ".. saveTbl .." (infoid, value) VALUES (" ..
			SQLStr(steamid) .. ", " .. SQLStr(util.TableToJSON(sweps)) .. " )")
		PermSWEPs.MakeSteamIDDirty(steamid)
	end
end

provider.wipeData = function()
	sql.Query("DROP TABLE " .. saveTbl)
	setupTable()
end

PermSWEPs.AddSWEPProvider(provider)