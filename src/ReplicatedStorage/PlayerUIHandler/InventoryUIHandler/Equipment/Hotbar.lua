local Hotbar = {
	equipedHotbarSlotScale = 1.2,
}

local SlotsHandler = require(
	game.ReplicatedStorage
		:WaitForChild("PlayerUIHandler")
		:WaitForChild("InventoryUIHandler")
		:WaitForChild("SlotsHandler")
)
local equipHotbarSlot = game.ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("equipHotbarSlot")

Hotbar.__index = Hotbar
--- Initiate Hotbar.
function Hotbar.initHotbar(InventoryUI: table, Equipment: table)
	local self = {}
	setmetatable(self, Hotbar)

	self.InventoryUI = InventoryUI
	self.HotbarFrame = InventoryUI.HotbarFrame
	self.EquipmentHotbarFrame = Equipment.Instance:WaitForChild("hotbar")
	self.hotbarCache = nil

	self.EquipmentHotbarSlots = {}
	for i = 1, SlotsHandler.HotbarSize, 1 do
		local slotOptions = {
			type = SlotsHandler.hotbarSlotTypes.EquipmentHotbarSlot,
			layoutOrderIndex = i,
			rowSize = SlotsHandler.HotbarSize,
		}
		local slot = SlotsHandler.newSlot(self.InventoryUI, self.EquipmentHotbarFrame, slotOptions)
		table.insert(self.EquipmentHotbarSlots, slot)
	end

	-- hotbar slots displayed at the bottom of the screen
	self.HotbarSlots = {}
	for i = 1, SlotsHandler.HotbarSize, 1 do
		local slotOptions = {
			type = SlotsHandler.hotbarSlotTypes.HotbarSlot,
			layoutOrderIndex = i,
			rowSize = SlotsHandler.HotbarSize,
			locked = true,
		}
		local slot = SlotsHandler.newSlot(self.InventoryUI, self.HotbarFrame, slotOptions)
		table.insert(self.HotbarSlots, slot)
	end

	return self
end

--- Update Hotbar.
--- @param hotbarData? table
function Hotbar:update(hotbarData: table)
	if not hotbarData and not self.hotbarCache then
		return
	end

	--if func gets called from client it will not provide hotbarData => proceed with last data
	if not hotbarData then
		hotbarData = self.hotbarCache
	else
		self.hotbarCache = hotbarData
	end

	-- update hotbar
	for i = 1, #self.HotbarSlots do
		local itemData = hotbarData[tostring(i)]

		self.EquipmentHotbarSlots[i]:setItem(itemData)
		self.HotbarSlots[i]:setItem(itemData)
	end
end

--- Equip hotbar slot.
function Hotbar:equipHotbarSlot(slotNum: number)
	equipHotbarSlot:FireServer(slotNum)

	for i, slot in pairs(self.HotbarSlots) do
		if i == slotNum then
			slot.Instance.UIScale.Scale = Hotbar.equipedHotbarSlotScale
		else
			slot.Instance.UIScale.Scale = 1
		end
	end
end

return Hotbar
