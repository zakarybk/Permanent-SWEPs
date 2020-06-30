local db = {}

db.TableNameWithPrefix = function(name)
	return PermSWEPs.DataTablePrefix .. "_" .. name
end

db.SetupDataFormat = function(name, id, value)
	sql.Query(
		string.format("CREATE TABLE IF NOT EXISTS %s" ..
					" (infoid TEXT NOT NULL PRIMARY KEY, value TEXT)",
					db.TableNameWithPrefix(name)
		)
	)
end

db.ReadSWEPs = function(name, id)
	local sweps = {}
	local val = sql.QueryValue(string.format(
		"SELECT value FROM %s WHERE infoid = %s LIMIT 1",
		db.TableNameWithPrefix(name),
		id
	)

	if val != nil then
		sweps = util.JSONToTable(val)
	end

	return sweps
end

db.SaveSWEPs = function(name, id, value)
	sql.Query(string.format("REPLACE INTO %s (infoid, value) VALUES (%s, %s)",
		db.TableNameWithPrefix(name)
		SQLStr(steamid),
		SQLStr(util.TableToJSON(sweps)))
	)
end

db.ReadDataRange = function() end

db.LastDataIndex = function() end

return db