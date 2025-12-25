local UserInputService = game:GetService("UserInputService")
local InventoryUIHandler = require(game.ReplicatedStorage:WaitForChild("PlayerUI"):WaitForChild("InventoryUIHandler"))

local Player = game.Players.LocalPlayer
local PlayerUI = InventoryUIHandler.getPlayerUI(Player.UserId)
if not PlayerUI then
    return
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == Enum.KeyCode.One then
            PlayerUI.Equipment:equipHotbarSlot(1)
        end
        if input.KeyCode == Enum.KeyCode.Two then
            PlayerUI.Equipment:equipHotbarSlot(2)
        end
        if input.KeyCode == Enum.KeyCode.Three then
            PlayerUI.Equipment:equipHotbarSlot(3)
        end
        if input.KeyCode == Enum.KeyCode.Four then
            PlayerUI.Equipment:equipHotbarSlot(4)
        end
    end
end)