local canceledCursorItem = game.ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("canceledCursorItem")
local cursorUpdate = game.ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("cursorUpdate")

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

	cursorUpdate.OnClientEvent:Connect(function(itemData)
		self.itemData = itemData
		if itemData then
			self.Instance.Image = itemData.img
			self.playerUI.ItemsInv.tooltip:hide()
		else
			self.Instance.Image = self.playerUI.ItemsInv.SlotsHandler.clearImg
		end
	end)

	return self
end

function CursorItem:cancel()
	self.callback = nil
	self.itemData = nil
	self.heldItemOrigin = nil
	self.Instance.Image = self.playerUI.ItemsInv.SlotsHandler.clearImg

	canceledCursorItem:FireServer()

	--self.playerUI.ItemsInv:update()
	--self.playerUI.Equipment:update()
end

return CursorItem
