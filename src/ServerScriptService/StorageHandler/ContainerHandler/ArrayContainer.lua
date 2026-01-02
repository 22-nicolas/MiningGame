local ArrayContainer = {}
ArrayContainer.__index = ArrayContainer

function ArrayContainer.new(container: table, size: number)
    container.type = "array"
    if not size then
        container.contents = {}
    else
        container.contents = table.create(size)
    end

    local self = {
        container = container
    }
    return setmetatable(self, ArrayContainer)
end

function ArrayContainer:get(pos: number)
    return  self.container.contents[pos]
end

function ArrayContainer:add(item: table)
    table.insert(self.container.contents, item)
    print("added array container")
end

function ArrayContainer:remove(item: table, amount: number, keys: table)
    local key = keys[1]
    local contents = self.container.contents
    if contents[key].stackable then
        contents[key].amount = math.max(contents[key].amount - amount, 0)
        if contents[key].amount == 0 then
            table.remove(contents, key)
        end
    else
        for i = 1, amount, 1 do
            local found = self:containsItem(item)
            if not found then
                break
            end
            table.remove(contents, found.keys[1])
        end
    end
end

function ArrayContainer:removeAt(pos: number, amount: number)
    local item = self.container.contents[pos]
    item.amount = math.max(item.amount - amount, 0)
    if item.amount == 0 then
        table.remove(self.container.contents, pos)
    end
end

function ArrayContainer:isFull(amountToBeAdded: number)
    if self.container.size and #self.container.contents + amountToBeAdded >= self.container.size then
        return true
    end
    return false
end

return ArrayContainer