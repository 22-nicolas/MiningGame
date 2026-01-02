local ContainerHandler = require(script:WaitForChild("ContainerHandler"))
local Utils = require(game.ReplicatedStorage:WaitForChild("Utils"))

local StorageHandler = {
    ContainerTypes = ContainerHandler.ContainerTypes
}

local Storage = {}
Storage.__index = Storage

--- Creates new storage.
function StorageHandler.new()
    local self = {}
    setmetatable(self, Storage)

    return self
end

--- Assigns container to storage.
function Storage:addContainer(container: table)
    if not Utils.checkValue(container, "table", "[StorageHandler]") then
        return
    end

    self[container.id] = container
end

--- Creates new container.
function Storage:newContainer(id: string, size: number, type: string)
    self[id] = ContainerHandler.new(id, size, type, self)
end

--- Transfers item from one container to another.
function StorageHandler.transferItem(prevContainer: table, prevPos: number, nextContainer: table, nextPos: number, amount: number)
    local item = prevContainer:get(prevPos)
    if not amount then
        amount = item.amount
    end
    prevContainer:removeItemAt(prevPos, amount)
    nextContainer:addItem(item, amount, nextPos)
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