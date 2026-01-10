local cancelCursorItem = game.ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("cancelCursorItem")
local cursorUpdate = game.ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("cursorUpdate")

local CursorItem = {}

CursorItem.__index = CursorItem
function CursorItem.new(InventoryUI)
	local self = {}
	setmetatable(self, CursorItem)

	self.Instance = InventoryUI.InventoryFrame:WaitForChild("CursorItem")
	self.itemData = nil
	self.InventoryUI = InventoryUI

	cursorUpdate.OnClientEvent:Connect(function(itemData)
		self.itemData = itemData
		if itemData then
			self.Instance.Image = itemData.img
			self.InventoryUI.ItemsInv.tooltip:hide()
		else
			self.Instance.Image = self.InventoryUI.ItemsInv.SlotsHandler.clearImg
		end
	end)

	return self
end

function CursorItem:cancel()
	self.itemData = nil
	self.heldItemOrigin = nil
	self.Instance.Image = self.InventoryUI.ItemsInv.SlotsHandler.clearImg

	cancelCursorItem:FireServer()
end

return CursorItem
