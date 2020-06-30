include("perm_swepy/sv_swep_db.lua")

local tests = {}
tests.list = {}
tests.insert = function(test) table.insert(tests.list, test) end
tests.iterator = function(tests) -- Random order
	local remaining = table.Copy(tests)

	-- The closure function is returned
	return function()
		if #remaining > 0 then
			local index = math.random(#remaining)
			local test = remaining[index]
			table.remove(remaining, index)
			return test
		end
	end
end
tests.tableNameWithPrefix = function(name) return PermSWEPs.DataTablePrefix .. "_" .. name end

tests.setUp = function()
	local env = {}
	env.dataTable = tests.tableNameWithPrefix("test_perm")

	local query = "CREATE TABLE %s (infoid TEXT NOT NULL PRIMARY KEY, value TEXT);"
	sql.Query(string.format(query, env.dataTable))

	assert(sql.TableExists(env.dataTable, string.format("Failed to create SQL table %s", env.dataTable))

	return env
end

tests.tearDown = function(env)
	local query = "DROP TABLE %s;"
	sql.Query(string.format(query, env.dataTable))

	assert(not sql.TableExists(env.dataTable), string.format("Failed to drop SQL table %s", env.dataTable))
end

-- Given, When, Then

tests.insert({"OnLoadCreateSQLTable", function(env)

end})

local function runTests()
	for test in tests.iterator(tests.list) do
		local env = tests.setUp()
		test(env)
		tests.tearDown(env)
	end
end
runTests()