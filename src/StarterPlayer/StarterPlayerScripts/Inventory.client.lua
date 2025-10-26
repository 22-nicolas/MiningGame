local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HTTPService = game:GetService("HttpService")

--Remote Events
local bagUpdate = ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("bagUpdate")
local invUpdate = ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("invUpdate")
local equipmentUpdate = ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("equipmentUpdate")
local lootNotification = ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("lootNotification")

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
	print(equipmentData)
	playerUI.Equipment:update(equipmentData)
end)


lootNotification.OnClientEvent:Connect(function(id, item, deltaAmount)
	playerUI.lootNotifications:addNotification(id, item, deltaAmount)
end)

