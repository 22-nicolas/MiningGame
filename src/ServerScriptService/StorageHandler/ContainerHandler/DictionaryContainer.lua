local DictionaryContainer = {}
DictionaryContainer.__index = DictionaryContainer

function DictionaryContainer.new(container: table)
    container.type = "dictionary"
    container.contents = {}

    local self = {
        container = container
    }
    return setmetatable(self, DictionaryContainer)
end

function DictionaryContainer:get(pos: number)
    return self.container.contents[tostring(pos)]
end

function DictionaryContainer:add(item: table, pos: number)
    if not pos then
        warn("[ContainerHandler] When adding to a dictionary a position (key) must be provided.", debug.traceback())
        return
    end
    self.container.contents[tostring(pos)] = item
    print("added dictionary container")
end

function DictionaryContainer:remove(item: table, amount, keys: table)
    local contents = self.container.contents
    if item.stackable then
        for i = 1, #keys, 1 do
            if amount == 0 then
                break
            end
            local k = keys[i]
            local foundItem = contents[k]
            local delta = math.max(amount - foundItem.amount, 0)
            foundItem.amount = math.max(foundItem.amount - amount, 0)
            if foundItem.amount == 0 then
                self.container.contents[k] = nil
            end
            amount = delta
        end
    else
        for i = 1, #keys, 1 do
            if amount == 0 then
                break
            end
            self.container.contents[keys[i]] = nil
            amount -= 1
        end
    end
end

function DictionaryContainer:removeAt(pos: number, amount: number)
    pos = tostring(pos)
    local item = self.container.contents[pos]
    item.amount = math.max(item.amount - amount, 0)
    if item.amount == 0 then
        self.container.contents[pos] = nil
    end
end

function DictionaryContainer:isFull(amountToBeAdded: number)
    local length = 0 + amountToBeAdded
    for k, v in pairs(self.container.contents) do
        if v then
            length += 1
        end
    end
    if length >= self.container.size then
        return true
    end
end

function DictionaryContainer:getFirstFreeSlot()
    for k, v in pairs(self.container.contents) do
        if not v then
            return k
        end
    end
end

return DictionaryContainer