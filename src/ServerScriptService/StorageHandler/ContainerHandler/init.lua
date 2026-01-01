local Utils = require(game.ReplicatedStorage:WaitForChild("Utils"))
local Items = require(game.ReplicatedStorage:WaitForChild("Items"))
local MonoContainer = require(script:WaitForChild("MonoContainer"))
local ArrayContainer = require(script:WaitForChild("ArrayContainer"))
local DictionaryContainer = require(script:WaitForChild("DictionaryContainer"))

local ContainerHandler = {
    ContainerTypes = {
        mono = "mono",
        dictionary = "dictionary",
        array = "array",
    },
    Response = {
        error = 0,
        success = 1,
        full = 2,
        notEnough = 3,
    }
}

local Container = {}
Container.__index = Container

--setmetatable(MonoContainer, {__index = Container})
--setmetatable(DictionaryContainer, {__index = Container})
--setmetatable(ArrayContainer, {__index = Container})

--- Creates new container and returns it.
--- @overload fun(id: string, size: number)
--- @overload fun(id: string, size: number, Storage: table)
--- @overload fun(id: string, size: number, type: string)
--- @note If size is 1, do not provide a type.
function ContainerHandler.new(id: string, size: number, type: string, Storage: table)
    if not Utils.checkValue(id, "string", "[ContainerHandler]") then
        return
    end

    if not Utils.checkValue(size, "number", "[ContainerHandler]") then
        return
    end

    -- if size is 1 then type will be "mono".
    if size == 1 then
        Storage = type
        type = ContainerHandler.ContainerTypes.mono
    end
    
    local self = {}
    setmetatable(self, Container)

    self.id = id
    self.size = size

    if type == ContainerHandler.ContainerTypes.mono then
        self._impl = MonoContainer.new(self)
    elseif type == ContainerHandler.ContainerTypes.array then
        self._impl = ArrayContainer.new(self)
    elseif type == ContainerHandler.ContainerTypes.dictionary then
        self._impl = DictionaryContainer.new(self)
    end

    if Storage then
        Storage[id] = self
    end

    return self
end

--- Gets item from container.
function Container:get(pos: number)
    return  self._impl:get(pos)
end

--- Adds item to container.
--- @overload fun(itemId: string)
--- @overload fun(itemId: string, amount: number)
--- @overload fun(item: table)
--- @overload fun(itemId: string, pos: number)
--- @overload fun(item: table, pos: number)
--- @note If the container's type is "dictionary" then pos is required.
function Container:addItem(item: table, amount: number, pos: number)
    --set up variables
    if typeof(item) == "string" then
        item = Items.getItemById(item)
    end

    --check if container full
    local isFull = self:isFull()

    if isFull and not item.stackable then
        return ContainerHandler.Response.full
    end

    if self.type == ContainerHandler.ContainerTypes.dictionary then
        if not pos then
            pos = amount
            amount = 1
        end
        if amount > 1 and not item.stackable then
            warn("[ContainerHandler] Dictionaries can't add more then one unstackable item per call.", debug.traceback())
            return ContainerHandler.Response.error
        end
        --[[
        if not pos then
            pos = self._impl:getFirstFreeSlot()
            if not pos then
                for k, v in pairs(self.contents) do
                    if v.id == item.id then
                        pos = k
                        break
                    end
                end
            end
        end]]
        if not Utils.checkValue(pos, "number", "[ContainerHandler]") then
            warn("[ContainerHandler] When adding to a dictionary a position (key) must be provided.", debug.traceback())
            return ContainerHandler.Response.error
        end
    end
    if amount then
        item.amount = amount
    end

    --stackable items
    if item.stackable then
        --check if item is already in container
        local found = self:containsItem(item)
        if not found and isFull then
            return ContainerHandler.Response.full
        end

        --if item is contained up the amount
        if found then
            local keys = found.keys
            local foundItem = self.contents[keys[1]] --use first found key to up amount
            foundItem.amount = foundItem.amount + item.amount
        else
            --if not set/add item
            self._impl:add(item, pos)
        end
    else
        -- non-stackable items
        if item.amount == 1 then
            self._impl:add(item, pos)
        elseif self:isFull(item.amount) then
            return ContainerHandler.Response.full
        else
            for i = 1, item.amount do
                local singleItem = item
                singleItem.amount = 1
                self._impl:add(singleItem, pos)
            end
        end

    end

    return ContainerHandler.Response.success
end

--- Removes item from container.
--- @overload fun(itemId: string)
--- @overload fun(itemId: string, amount: number)
--- @overload fun(item: table)
--- @overload fun(itemId: string, force: boolean)
--- @overload fun(item: table, force: boolean)
--- @note Force set to true, will remove the item wether the amount required is present or not.
function Container:removeItem(item: table, amount: number, force: boolean)
    if typeof(item) == "string" then
        item = Items.getItemById(item)
    end

    if typeof(amount) == "boolean" then
        force = amount
        amount = nil
    end

    if force == nil then
        force = false
    end

    if not amount then
        amount = 1
    end

    local found  = self:containsItem(item)
    if not found then
        warn("[ContainerHandler] Tried removing inexisting item from container: "..self.id, debug.traceback())
        return ContainerHandler.Response.error
    end

    local keys = found.keys
    local foundAmount = found.amount
    
    if not force and amount > foundAmount then
        --Before removing an item for things like crafting ect. 
        --the aviability of the required amount might have been already checked.
        --Therefore, this early return might represent in some cases a bug/error.
        return ContainerHandler.Response.notEnough
    end

    self._impl:remove(item, amount, keys)

    return ContainerHandler.Response.success
end

--- Removes the item at the position pos.
--- @overload fun(pos: number)
--- @overload fun(amount: number)
--- @note Don't provide a position for mono containers.
function Container:removeItemAt(pos: number, amount: number)
    if self.type == ContainerHandler.ContainerTypes.mono then
        amount = pos
        pos = 1
    end

    if not Utils.checkValue(pos, "number", "[ContainerHandler]") then
        return ContainerHandler.Response.error
    end

    local itemToBeRemoved = self._impl:get(pos)
    
    if not itemToBeRemoved then
        warn("[ContainerHandler] No item present in container "..self.id.." at position "..tostring(pos), debug.traceback())
        return ContainerHandler.Response.error
    end

    if not amount then
        amount = itemToBeRemoved.amount
    end

    self._impl:removeAt(pos, amount)
end

--- Finds passed item and returns its index.
--- @overload fun(itemId: string)
function Container:containsItem(item: table)
    if not self.contents then
        print(self.type)
        return nil
    end
    if typeof(item) == "string" then
        item = Items.getItemById(item)
    end

    if self.type == ContainerHandler.ContainerTypes.mono then
        if self.contents.id == item.id then
            return {keys = {1}, amount = self.contents.amount}
        end
    end

    local amount = 0
    local keys = {}
    for k, v in pairs(self.contents) do
		if v.id == item.id then
			table.insert(keys, k)
            amount += v.amount
		end
	end

    if amount == 0 then
        return nil
    end
    return {keys = keys, amount = amount}
end

--- Returns true if all slots in a container are ocupied. Note that container might be still able to add stackable items.
--- @overload fun()
function Container:isFull(amountToBeAdded: number)
    if not amountToBeAdded then
        amountToBeAdded = 0
    end

    return self._impl:isFull(amountToBeAdded)
end

return ContainerHandler