local CursorItem = {}

CursorItem.__index = CursorItem
function CursorItem.new(playerUI)
	
	local self = {}
	setmetatable(self, CursorItem)
	
	self.Instance = playerUI.InventoryFrame:WaitForChild("CursorItem")
	self.itemData = nil
	self.heldItemOrigin = nil
	self.callback = nil
	self.playerUI = playerUI
	
	return self
end


function CursorItem:setItem(slot, callback)
	local item = slot:getItem()

	--execute callback
	if self.callback then
		self.callback(slot, self.itemData)
		self.callback = nil
	end
	
	--data
	self.callback = callback
	self.itemData = item
	self.heldItemOrigin = slot.type
	
	--UI
	if item then
		self.Instance.Image = item.img
		self.playerUI.ItemsInv.tooltip:hide()
	else
		self.Instance.Image = self.playerUI.ItemsInv.SlotsHandler.clearImg
	end

	--Update Inv
	self.playerUI.ItemsInv:update()
	self.playerUI.Equipment:update()
end

function CursorItem:cancel()
	self.callback = nil
	self.itemData = nil
	self.heldItemOrigin = nil
	self.Instance.Image = self.playerUI.ItemsInv.SlotsHandler.clearImg
	
	self.playerUI.ItemsInv:update()
	self.playerUI.Equipment:update()
end

return CursorItem
