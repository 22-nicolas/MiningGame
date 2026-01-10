local ItemsTooltip = require(script:WaitForChild("ItemsTooltip"))

local ItemsInv = {}

ItemsInv.__index = ItemsInv
function ItemsInv.new(PlayerUI: table, InventoryUI: table)
	local self = {}
	setmetatable(self, ItemsInv)

	self.InventoryUI = InventoryUI
	self.PlayerUI = PlayerUI
	self.Instance = self.InventoryUI.InventoryFrame:WaitForChild("Items")
	self.ItemContainer = self.Instance:WaitForChild("items")

	self.tooltip = ItemsTooltip.new(self)

	self.SlotsHandler = require(
		game.ReplicatedStorage
			:WaitForChild("PlayerUIHandler")
			:WaitForChild("InventoryUIHandler")
			:WaitForChild("SlotsHandler")
	)
	self.Slots = {}

	for i = 1, PlayerUI.stats.invSlots do
		local slot = self.SlotsHandler.newSlot(self.InventoryUI, self.ItemContainer, i, "items", 5)
		table.insert(self.Slots, slot)
	end

	--self.ItemsTooltip = self.ItemsFrame:WaitForChild("tooltip")

	return self
end

function ItemsInv:update(inventoryData)
	if not inventoryData and not self.inventoryData then
		return
	end

	--if func gets called from client it will not provide inventoryData => proceed with last data
	if not inventoryData then
		inventoryData = table.clone(self.inventoryData)
	else
		self.inventoryData = inventoryData
	end

	--[[if a item is held dont implement it into a slot
	if self.InventoryUI.cursorItem.itemData and self.InventoryUI.cursorItem.heldItemOrigin == "inv" then
		table.remove(inventoryData, table.find(inventoryData, self.InventoryUI.cursorItem.itemData))
	end]]

	--Makes sure inv is initiated before updating
	for i = 0, 5 do
		if #self.Slots == self.PlayerUI.stats.invSlots then
			break
		end

		task.wait(1)
	end
	if #self.Slots ~= self.PlayerUI.stats.invSlots then
		warn(
			"[InventoryUIHandler] Timed out while waiting for inv to be initiated. Player: "
				.. tostring(self.player.UserId)
		)
		return
	end

	for _, slot in pairs(self.Slots) do
		slot:setItem() --since parameter == nil, it will clear the slot
	end

	for i = 1, #inventoryData do
		self.Slots[i]:setItem(inventoryData[i])
	end
end

return ItemsInv
