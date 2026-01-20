local ContainerHandler = require(script:WaitForChild("ContainerHandler"))
local Utils = require(game.ReplicatedStorage:WaitForChild("Utils"))
local Items = require(game.ReplicatedStorage:WaitForChild("Items"))

local StorageHandler = {
	ContainerTypes = ContainerHandler.ContainerTypes,
}

local Storage = {}
Storage.__index = Storage

--- Creates new storage.
function StorageHandler.new()
	local self = {}
	setmetatable(self, Storage)

	self.connectedFuncs = {}

	return self
end

--- Connects a function to the changed event.
--- @param func function
function Storage:connectToChanged(func)
	if not Utils.checkValue(func, "function", "[StorageHandler]") then
		return
	end

	table.insert(self.connectedFuncs, func)
end

--- Disconnects a function from the changed event.
--- @param func function
function Storage:disconnectFromChanged(func)
	if not Utils.checkValue(func, "function", "[StorageHandler]") then
		return
	end

	local index = table.find(self.connectedFuncs, func)
	if index then
		return
	end

	table.remove(self.connectedFuncs, index)
end

--- Fires the changed event.
function Storage:fireChanged(changedContainer: table)
	for _, func in pairs(self.connectedFuncs) do
		func(changedContainer)
	end
end

--- Assigns container to storage.
function Storage:addContainer(container: table)
	if not Utils.checkValue(container, "table", "[StorageHandler]") then
		return
	end

	container:connectToChanged(function()
		self:fireChanged(container)
	end)

	self[container.id] = container
end

--- Creates new container.
function Storage:newContainer(id: string, size: number, type: string)
	local container = ContainerHandler.new(id, size, type, self)

	container:connectToChanged(function()
		self:fireChanged(container)
	end)

	self[id] = container
end

--- Removes item from storage.
--- @overload fun(item: table)
--- @overload fun(itemId: string)
--- @overload fun(item: table, force: boolean)
--- @overload fun(itemId: string, force: boolean)
function Storage:removeItem(itemId: string, amount: number, force: boolean)
	if typeof(amount) == "boolean" then
		force = amount
		amount = nil
	end

	local item
	if typeof(itemId) == "string" then
		item = Items.getItemById(itemId)
		if not item then
			warn("[StorageHandler] No item found with id: " .. tostring(itemId), debug.traceback())
		end
		if amount then
			item.amount = amount
		end
	else
		item = itemId
	end

	if not item then
		warn("[StorageHandler] Item can't be nil", debug.traceback())
	end

	local found = self:containsItem(item)
	local foundKeys = found.keys
	local foundAmount = found.amount

	if not force and amount > foundAmount then
		--Before removing an item for things like crafting ect.
		--the aviability of the required amount might have been already checked.
		--Therefore, this early return might represent in some cases a bug/error.
		return
	end

	for containerKey, foundKeysInContainer in pairs(foundKeys) do
		for _, key in pairs(foundKeysInContainer) do
			local amountInThisSlot = self[containerKey]:get(key).amount
			local amountToBeRemoved = math.min(amount, amountInThisSlot)
			self[containerKey]:removeItemAt(key, amount)
			amount -= amountToBeRemoved
			if amount == 0 then
				break
			end
		end
		if amount == 0 then
			break
		end
	end
end

--- Transfers item from one container to another.
---@overload fun(prevContainer: table, prevPos: number, nextContainer: table, nextPos: number)
function StorageHandler.transferItem(
	prevContainer: table,
	prevPos: number,
	nextContainer: table,
	nextPos: number,
	amount: number
)
	if
		not Utils.checkValue(prevContainer, "table", "[StorageHandler]")
		or not Utils.checkValue(nextContainer, "table", "[StorageHandler]")
		or not Utils.checkValue(prevPos, "number", "[StorageHandler]")
		or not Utils.checkValue(nextPos, "number", "[StorageHandler]")
	then
		return
	end

	local item = prevContainer:get(prevPos)
	if not amount then
		amount = item.amount
	end

	local itemToTransfer = table.clone(item)
	itemToTransfer.amount = amount

	local response = nextContainer:addItem(itemToTransfer, amount, nextPos)

	if not response == ContainerHandler.Response.success then
		return response
	end

	prevContainer:removeItemAt(prevPos, amount)
end

function StorageHandler.swapItems(container1: table, pos1: number, container2: table, pos2: number)
	if
		not Utils.checkValue(container1, "table", "[StorageHandler]")
		or not Utils.checkValue(container2, "table", "[StorageHandler]")
		or not Utils.checkValue(pos1, "number", "[StorageHandler]")
		or not Utils.checkValue(pos2, "number", "[StorageHandler]")
	then
		return
	end

	local item1 = table.clone(container1:get(pos1))
	local item2 = table.clone(container2:get(pos2))

	container1:removeItemAt(pos1)
	container2:removeItemAt(pos2)

	--only provide pos if its a dictionary because else it will be taken as the amount
	if container1.type == ContainerHandler.ContainerTypes.dictionary then
		container1:addItem(item2, pos1)
	else
		container1:addItem(item2)
	end
	if container2.type == ContainerHandler.ContainerTypes.dictionary then
		container2:addItem(item1, pos2)
	else
		container2:addItem(item1)
	end
end

--- Finds passed item and returns its indecices and amount.
--- @overload fun(itemId: string)
function Storage:containsItem(item: table)
	if typeof(item) == "string" then
		item = Items.getItemById(item)
	end

	local foundAmount = 0
	local foundKeys = {}

	for containerKey, container in pairs(self) do
		if containerKey == "connectedFuncs" then
			continue
		end

		local found = container:containsItem(item)

		if found then
			foundAmount += found.amount
			foundKeys[containerKey] = found.keys
		end
	end

	return {
		amount = foundAmount,
		keys = foundKeys,
	}
end

function test()
	local TestStorage = StorageHandler.new()
	local mono = ContainerHandler.new("mono", 1, TestStorage)
	local array = ContainerHandler.new("array", 20, ContainerHandler.ContainerTypes.array, TestStorage)
	local dictionary = ContainerHandler.new("dictionary", 10, ContainerHandler.ContainerTypes.dictionary, TestStorage)

	dictionary:addItem("stackableTestItem", 10, 1)

	TestStorage:addContainer(mono)
	TestStorage:addContainer(array)
	TestStorage:addContainer(dictionary)

	StorageHandler.transferItem(dictionary, 1, mono, 1)

	print(TestStorage)
end

--test()

return StorageHandler
