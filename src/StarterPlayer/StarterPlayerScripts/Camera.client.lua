local UserInputService = game:GetService("UserInputService")
local InventoryUIHandler = require(game.ReplicatedStorage:WaitForChild("PlayerUI"):WaitForChild("InventoryUIHandler"))
local player = game.Players.LocalPlayer
local PlayerUI = InventoryUIHandler.getPlayerUI(player.UserId)

PlayerUI:ConnectToInventoryEnabledChanged(function(enabled)
    if enabled then
        UserInputService.MouseIconEnabled = true
    else
        UserInputService.MouseIconEnabled = player.CameraMaxZoomDistance > 0
    end
end)

function setThirdPersonPerson()
    player.CameraMaxZoomDistance = 10
    player.CameraMinZoomDistance = 10
    UserInputService.MouseIconEnabled = true
end

function setFirstPersonPerson()
    player.CameraMaxZoomDistance = 0
    player.CameraMinZoomDistance = 0
    UserInputService.MouseIconEnabled = false
end

setThirdPersonPerson()

UserInputService.InputChanged:Connect(function(input, gameProcessed)
    if gameProcessed then
        return
    end

	if input.UserInputType == Enum.UserInputType.MouseWheel then
        if input.Position.Z > 0 then
            setFirstPersonPerson()
        else
            setThirdPersonPerson()
        end
    end
end)