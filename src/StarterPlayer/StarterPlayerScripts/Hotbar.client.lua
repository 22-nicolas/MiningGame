local UserInputService = game:GetService("UserInputService")
local PlayerUIHandler = require(game.ReplicatedStorage:WaitForChild("PlayerUIHandler"))

local Player = game.Players.LocalPlayer
local PlayerUI = PlayerUIHandler.getPlayerUI(Player.UserId)
if not PlayerUI then
	return
end
local Equipment = PlayerUI.InventoryUI.Equipment

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.UserInputType == Enum.UserInputType.Keyboard then
		if input.KeyCode == Enum.KeyCode.One then
			Equipment.Hotbar:equipHotbarSlot(1)
		end
		if input.KeyCode == Enum.KeyCode.Two then
			Equipment.Hotbar:equipHotbarSlot(2)
		end
		if input.KeyCode == Enum.KeyCode.Three then
			Equipment.Hotbar:equipHotbarSlot(3)
		end
		if input.KeyCode == Enum.KeyCode.Four then
			Equipment.Hotbar:equipHotbarSlot(4)
		end
		if input.KeyCode == Enum.KeyCode.Five then
			Equipment.Hotbar:equipHotbarSlot(5)
		end
		if input.KeyCode == Enum.KeyCode.Six then
			Equipment.Hotbar:equipHotbarSlot(6)
		end
	end
end)
