local UserInputService = game:GetService("UserInputService")
local InventoryUIHandler = require(game.ReplicatedStorage:WaitForChild("PlayerUI"):WaitForChild("InventoryUIHandler"))
local player = game.Players.LocalPlayer
local PlayerUI = InventoryUIHandler.getPlayerUI(player.UserId)
local cursors = {
    default = "",
    firstPerson = "http://www.roblox.com/asset/?id=68308747"
}

player.CameraMaxZoomDistance = 10
player.CameraMinZoomDistance = 10

PlayerUI:ConnectToInventoryEnabledChanged(function(enabled)
    print(enabled)
    if enabled then
        UserInputService.MouseIcon = cursors.default
    else
        if player.CameraMode == Enum.CameraMode.Classic then
            UserInputService.MouseIcon = cursors.default
        else
            UserInputService.MouseIcon = cursors.firstPerson
        end
    end
end)

function setThirdPersonPerson()
    player.CameraMode = Enum.CameraMode.Classic
    UserInputService.MouseIcon = cursors.default
end

function setFirstPersonPerson()
    player.CameraMode = Enum.CameraMode.LockFirstPerson
    if PlayerUI.InventoryGui.Enabled then
        UserInputService.MouseIcon = cursors.default
    else
        UserInputService.MouseIcon = cursors.firstPerson
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