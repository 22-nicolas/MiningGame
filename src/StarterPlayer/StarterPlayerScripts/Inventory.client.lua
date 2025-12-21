local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

--Remote Events
local bagUpdate = ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("bagUpdate")
local invUpdate = ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("invUpdate")
local equipmentUpdate = ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("equipmentUpdate")
local lootNotification = ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("lootNotification")
local dropItem = ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("dropItem")

--Instance playerUI
local InventoryUIHandler = require(game.ReplicatedStorage:WaitForChild("PlayerUI"):WaitForChild("InventoryUIHandler"))

local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local playerUI = InventoryUIHandler.initPlayerUI(player, mouse)

bagUpdate.OnClientEvent:Connect(function(bagData)
	playerUI.Bag:update(bagData)
end)

invUpdate.OnClientEvent:Connect(function(inventory)
	playerUI.ItemsInv:update(inventory)
end)

equipmentUpdate.OnClientEvent:Connect(function(equipmentData)
	playerUI.Equipment:update(equipmentData)
end)

lootNotification.OnClientEvent:Connect(function(item, deltaAmount)
	print(item)
	playerUI.lootNotifications:addNotification(item, deltaAmount)
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
			if gui:IsDescendantOf(playerUI.InventoryFrame) then
				clickedInventory = true
				break
			end
		end

		if not clickedInventory and playerUI.cursorItem.itemData then
			dropItem:FireServer(playerUI.cursorItem.itemData, playerUI.cursorItem.itemData.amount)
		end
	end
end)
