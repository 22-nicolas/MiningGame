local MouseRayRequest = game.ReplicatedStorage:WaitForChild("MouseRayRequest")
local RunService = game:GetService("RunService")
local player = game.Players.LocalPlayer
local mouse = player:GetMouse()

RunService.Heartbeat:Connect(function()
	MouseRayRequest:FireServer(mouse.UnitRay)
end)

