local Utils = {}

--BASIC LOGIC FUNCTIONS
--[[function Utils.toboolean(v)
	return v ~= nil and v ~= false
end
]]
function Utils.xor(a, b)
	return a ~= b
end

function Utils.tableLength(tbl)
	local count = 0
	for _ in pairs(tbl) do
		count = count + 1
	end
	return count
end

function Utils.isArray(tbl)
	if type(tbl) ~= "table" then
		return false
	end

	local max = 0
	local count = 0

	for k, _ in pairs(tbl) do
		if type(k) ~= "number" or k % 1 ~= 0 or k < 1 then
			-- found a non-positive-integer key or non-number key -> not a pure array
			return false
		end
		if k > max then
			max = k
		end
		count = count + 1
	end

	-- For a contiguous 1..n array we must have exactly `count == max`
	return count == max
end

function Utils.matchTables(a, b)
	if typeof(a) ~= "table" or typeof(b) ~= "table" then
		return false
	end
	local isArrayA = Utils.isArray(a)
	if isArrayA ~= Utils.isArray(b) then
		return false
	end

	if isArrayA then
		return Utils.matchArrays(a, b)
	else
		return Utils.matchDictionaries(a, b)
	end
end

function Utils.matchDictionaries(a, b)
	if Utils.tableLength(a) ~= Utils.tableLength(b) then
		return false
	end
	for key, value in pairs(a) do
		if not b[key] then
			return false
		end
		if typeof(value) == "table" and typeof(b[key]) == "table" then
			if not Utils.matchTables(value, b[key]) then
				return false
			end
		elseif value ~= b[key] then
			return false
		end
	end
	return true
end

function Utils.matchArrays(a, b)
	if #a ~= #b then
		return false
	end
	for i = 1, #a do
		if typeof(a[i]) == "table" and typeof(b[i]) == "table" then
			if not Utils.matchTables(a[i], b[i]) then
				return false
			end
		elseif a[i] ~= b[i] then
			return false
		end
	end
	return true
end

function Utils.findValueInNestedTable(tbl: table, value: any)
	for k, v in pairs(tbl) do
		-- Direct match
		if v == value then
			return k, tbl
		end

		-- Table-to-table match
		if typeof(value) == "table" and typeof(v) == "table" then
			if Utils.matchTables(v, value) then
				return k, tbl
			end
		end

		-- Recurse into nested tables
		if typeof(v) == "table" then
			local foundKey, foundTable = Utils.findValueInNestedTable(v, value)
			if foundKey ~= nil then
				return foundKey, foundTable
			end
		end
	end

	return nil
end

--- Finds and returns a table/instance with that key/name and returns it.
--- @overload fun(folder: Instance, key: string)
function Utils.findKeyInNestedTable(tbl: table, key: string)
	-- Table case
	if typeof(tbl) == "table" then
		for k, v in pairs(tbl) do
			-- Direct match
			if k == key then
				return v
			end

			-- Recurse into nested tables
			if typeof(v) == "table" then
				local foundTable = Utils.findKeyInNestedTable(v, key)
				if foundTable ~= nil then
					return foundTable
				end
			end
		end

	-- Instance / Folder case
	elseif typeof(tbl) == "Instance" then
		for _, child in ipairs(tbl:GetChildren()) do
			if child.Name == key then
				return child
			end

			local found = Utils.findKeyInNestedTable(child, key)
			if found ~= nil then
				return found
			end
		end
	end
end

function Utils.isWhole(num: number)
	if num ~= math.floor(num) then
		return false
	else
		return true
	end
end

function Utils.weightedRndPick(tbl: table)
	if not Utils.checkValue(tbl, "table", "[Utils]") then
		return
	end

	local total = 0
	for _, weight in pairs(tbl) do
		total = total + weight
	end
	local r = math.random() * total
	for item, weight in pairs(tbl) do
		r = r - weight
		if r <= 0 then
			return item
		end
	end
end

--ERROR CATHING/HANDLING
function Utils.getPath(instance)
	local path = instance.Name
	local current = instance

	while current.Parent do
		current = current.Parent
		path = current.Name .. "." .. path
	end

	return "game." .. path
end

local lastWarnTimes = {}
function Utils.throttledWarn(message: string, key: string, cooldown: number)
	key = key or message
	cooldown = cooldown or 4 -- default to 2 seconds if not specified
	local now = tick()
	local lastTime = lastWarnTimes[key] or 0

	if now - lastTime >= cooldown then
		warn(message)
		lastWarnTimes[key] = now
	end
end

function Utils.checkValue(value, expectedType, tag, printPath, lvl)
	if not expectedType then
		warn("[Utils] " .. "Arguments missing.")
	end

	if not printPath then
		printPath = false
	end

	if not lvl then
		lvl = 2
	end

	if not tag then
		tag = "[Utils]"
	end

	local nilMessage = tag .. " Arguments missing."
	local invalidMessage

	local isInstance = typeof(value) == "Instance"
	if isInstance then
		invalidMessage = tag
			.. " "
			.. value.ClassName
			.. " is not a valid class. Expected class: "
			.. tostring(expectedType)

		if printPath then
			invalidMessage = invalidMessage .. ". Instance Path: " .. Utils.getPath(value)
		end
	else
		invalidMessage = tag .. " " .. typeof(value) .. " is not a valid class. Expected class: " .. expectedType
	end

	if not value then
		warn(nilMessage, debug.traceback("", lvl))
		return false
	end

	if isInstance then
		if value.ClassName ~= expectedType then
			warn(invalidMessage, debug.traceback("", lvl))
			return false
		end
	else
		if typeof(value) ~= expectedType then
			warn(invalidMessage, debug.traceback("", lvl))
			return false
		end
	end

	return true
end

return Utils
