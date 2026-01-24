local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

--Remote Events
local bagUpdate = ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("bagUpdate")
local invUpdate = ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("invUpdate")
local hotbarUpdate = ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("hotbarUpdate")
local lootNotification = ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("lootNotification")
local dropItem = ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("dropItem")
local cursorUpdate = ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("cursorUpdate")
local equipmentUpdate = ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("equipmentUpdate")

--Instance PlayerUI
local PlayerUIHandler = require(game.ReplicatedStorage:WaitForChild("PlayerUIHandler"))

local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local PlayerUI = PlayerUIHandler.new(player, mouse)
local InventoryUI = PlayerUI.InventoryUI

bagUpdate.OnClientEvent:Connect(function(bagData)
	InventoryUI.Bag:update(bagData)
end)

invUpdate.OnClientEvent:Connect(function(inventory)
	InventoryUI.ItemsInv:update(inventory)
end)

equipmentUpdate.OnClientEvent:Connect(function(item, container)
	InventoryUI.Equipment:update(item, container)
end)

hotbarUpdate.OnClientEvent:Connect(function(hotbarData)
	InventoryUI.Equipment.Hotbar:update(hotbarData)
end)

cursorUpdate.OnClientEvent:Connect(function(cursorData)
	InventoryUI.cursorItem:update(cursorData)
end)

lootNotification.OnClientEvent:Connect(function(item, deltaAmount)
	PlayerUI.lootNotifications:addNotification(item, deltaAmount)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		-- Get UI objects under mouse
		local playerGui = player:WaitForChild("PlayerGui")
		local mousePos = UserInputService:GetMouseLocation()
		local guiObjects = playerGui:GetGuiObjectsAtPosition(mousePos.X, mousePos.Y)

		local clickedInventory = false

		for _, gui in ipairs(guiObjects) do
			if gui:IsDescendantOf(InventoryUI.InventoryFrame) then
				clickedInventory = true
				break
			end
		end

		if not clickedInventory and InventoryUI.cursorItem.itemData then
			dropItem:FireServer("cursorItem", 1, InventoryUI.cursorItem.itemData.amount)
		end
	end
end)
