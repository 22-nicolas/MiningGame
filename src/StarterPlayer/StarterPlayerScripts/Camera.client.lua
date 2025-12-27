local UserInputService = game:GetService("UserInputService")
local InventoryUIHandler = require(game.ReplicatedStorage:WaitForChild("PlayerUI"):WaitForChild("InventoryUIHandler"))
local player = game.Players.LocalPlayer
local PlayerUI = InventoryUIHandler.getPlayerUI(player.UserId)

PlayerUI:ConnectToInventoryEnabledChanged(function(enabled)
    print(enabled)
    if enabled then
        UserInputService.MouseIcon = ""
    else
        if player.CameraMaxZoomDistance > 0 then
            UserInputService.MouseIcon = "http://www.roblox.com/asset/?id=68308747"
        else
            UserInputService.MouseIcon = ""
        end
    end
end)

function setThirdPersonPerson()
    player.CameraMaxZoomDistance = 10
    player.CameraMinZoomDistance = 10
    UserInputService.MouseIcon = ""
end

function setFirstPersonPerson()
    player.CameraMaxZoomDistance = 0
    player.CameraMinZoomDistance = 0
    if PlayerUI.InventoryGui.Enabled then
        UserInputService.MouseIcon = ""
    else
        UserInputService.MouseIcon = "http://www.roblox.com/asset/?id=68308747"
    end
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