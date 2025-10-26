local tool = script.Parent
local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local MineRequest = game.ReplicatedStorage:WaitForChild("Mining"):WaitForChild("MineRequest")
local StopMining = game.ReplicatedStorage:WaitForChild("Mining"):WaitForChild("StopMining")
local NewTarget = game.ReplicatedStorage:WaitForChild("Mining"):WaitForChild("NewTarget")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local InventoryGui = player.PlayerGui:WaitForChild("InventoryGui")
local target
local lastTarget

local connections = {
	buttonDown = nil,
	buttonUp = nil,
	heartbeat = nil,
	newTarget = nil,
	stopMining = nil
}


--target also acts as a "isMining" bool in this script nil = false

tool.Equipped:Connect(function()
	connections.newTarget = NewTarget.OnClientEvent:Connect(function(newTarget)
		target = newTarget
	end)

	connections.stopMining = StopMining.OnClientEvent:Connect(function()
		target = nil
	end)
	
	connections.buttonDown = mouse.Button1Down:Connect(function()
		target = mouse.Target
		if not target or not target:IsDescendantOf(game.Workspace.ResourceNodes) then return end
		if target.Name == "raycastCopy" then
			target = target.Parent
		end
		MineRequest:FireServer(target, tool)
	end)
	
	connections.buttonUp = mouse.Button1Up:Connect(function()
		if not target then return end
		StopMining:FireServer(target)
	end)
	
	connections.heartbeat = RunService.Heartbeat:Connect(function()
		local buttons = UserInputService:GetMouseButtonsPressed()
		if #buttons == 0 then return end
		for _, button in pairs(buttons) do
			if button.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
			if target and target:IsDescendantOf(game.Workspace.ResourceNodes) then return end
			target = mouse.Target
			if not target or not target:IsDescendantOf(game.Workspace.ResourceNodes) then return end
			if target.Name == "raycastCopy" then
				target = target.Parent
			end
			MineRequest:FireServer(target, tool)
		end
	end)
end)

tool.Unequipped:Connect(function()
	for _, connection in pairs(connections) do
		connection:Disconnect()
	end
end)