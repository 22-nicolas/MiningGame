local MonoContainer = {}
MonoContainer.__index = MonoContainer

function MonoContainer.new(container: table)
	container.type = "mono"
	container.contents = nil

	local self = {
		container = container,
	}
	return setmetatable(self, MonoContainer)
end

function MonoContainer:get()
	return self.container.contents
end

function MonoContainer:add(item: table)
	self.container.contents = item
end

function MonoContainer:remove(item: table, amount: number)
	local contents = self.container.contents
	if contents.stackable then
		contents.amount = math.max(contents.amount - amount, 0)
		if contents.amount == 0 then
			self.container.contents = nil
		end
	else
		self.container.contents = nil
	end
end

function MonoContainer:removeAt(pos: number, amount: number)
	local contents = self.container.contents
	contents.amount = math.max(contents.amount - amount, 0)
	if contents.amount == 0 then
		self.container.contents = nil
	end
end

function MonoContainer:isFull()
	if self.container.contents then
		return true
	end
	return false
end

return MonoContainer
