local UserInputService = game:GetService("UserInputService")
local player = game.Players.LocalPlayer

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